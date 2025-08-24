unit SubmodRootDiff;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid,
  UMod, UState, Diffko, SubmodRootStructureNew;

const
  /// <summary>Maximum number of roots.</summary>
  max_num_roots = 40000;

type
  (* -----------------------------------------------------------------------------
    Type declarations
    ------------------------------------------------------------------------------ *)
  { Records and sets }
  /// <summary>
  /// Mode of nitrogen uptake by the root: Michaelis-Menten (saturation kinetics),
  /// fixed_influx assumes a constant sink strength, ZeroSink represents unlimited
  /// sink strength (black hole).
  /// </summary>
  tUptake_Function = (MM, fixed_influx, ZeroSink);
  TMyFloatPoint = double;

  { -------------------------------------------------------------------------------
    Array storing TPointDoubleTypes used to read xy coordinates from a file. The
    record extends the type posi from the original model by the fields root, xi,
    yi, NInflux, WInflux and area.
    ------------------------------------------------------------------------------ }
  TPointDoubleType = record
    /// <summary>Position in Cartesian coordinate system [cm]</summary>
    x, y: double;
    /// <summary>Indices on computation grid</summary>
    xi, yi: word;
    /// <summary>Unique number for root</summary>
    root: integer;
    /// <summary>Nitrate influx [mol/cm*s]</summary>
    NInflux: real;
    /// <summary>N amount taken up in the internal time step [g]</summary>
    NAmountdt: real;
    /// <summary>Cumulative N amount taken up in the external time step [kgN/dt_ext]</summary>
    SumNMenge: real;
    /// <summary>Water influx [cm3/cm/s]</summary>
    WInflux: real;
    /// <summary>Area of Voronoi polygon [cm2]</summary>
    area: real;
  end;

  { Classes }
  TSRPLight = class(TObject)
    { Lean, memory-saving version of an SRP }
  private
    { Private declarations }
  protected
  public
    { Public declarations }
    /// <summary>Root coordinates [cm] and root length density of the SRP [cm/cm^3]</summary>
    x, y, wld: double;

    { TSRP instances of the single root model also need fields for area and the
      vertex list so that, when reading raster data, the surface area can be
      determined (using Voronoi polygons or alternatively by splitting the area of
      raster cells among the roots contained in them. Units may be an issue) }
    /// <summary>Field for the coordinates of the root [cm]</summary>
    coordRoot: TMyFloatPoint;
    /// <summary>Surface area of the single root cylinder [cm^2]</summary>
    area: double;
    /// <summary>List of polygon vertices</summary>
    vertexList: TList;
    /// <summary>Mean nitrate concentration</summary>
    Cl_mean: double;
    /// <summary>Volumetric water content in the EWZ</summary>
    theta_EWZ: double;
    /// <summary>N amount in the EWZ at the beginning</summary>
    init_NAmount: double;
  public
    { Public declarations }
    { Access to the fields: set and get methods }
  end;

  { Declaration of class TRasterData.
    This class encapsulates the raster, positions and the number of read and
    randomized data (WAP). It enables display in the tabs RasterData and
    RootDistribution. The class also handles file access }

  TRasterData = class(TObject)
    /// <summary>Description of the data set</summary>
    DescStr: string;
    /// <summary>Date [TDateTime format]</summary>
    Date: TDatetime;
    /// <summary>Number of rows</summary>
    NCols: integer;
    /// <summary>Number of columns</summary>
    NRows: integer;
    /// <summary>Number of roots</summary>
    NRoots: integer;
    /// <summary>Height of rows [cm]</summary>
    DimCols: double;
    /// <summary>Width of columns [cm]</summary>
    DimRows: double;

    { Arrays of class RasterData }

    { Root numbers in 10,000 raster (computational) cells. The array is needed for
      reading and displaying the number of roots in grid cells of dimension
      5 cm x 5 cm }
    CountArr: array of array of integer;
    { Stores information on all roots in the form of TPointDoubleType entries }
    PosArr: array [1 .. max_num_roots] of TPointDoubleType;
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    /// <summary>Reference to the diffusion submodel</summary>
    SubmodRootDiff: TSubmodel;
    /// <summary>Constructor</summary>
    constructor create(Submodel: TSubmodel);
    /// <summary>Reads aggregated raster data and generates random positions</summary>
    procedure readRasterData(fn: string; var Series: TPointSeries);
    /// <summary>Reads XY coordinates from a file</summary>
    procedure readXYfromFile(Filename: TFilename;
      var Series: TPointSeries); virtual;
    /// <summary>Saves generated root coordinates to a file</summary>
    procedure saveRootPositons(SaveDialog: TSaveDialog);
  published
    { Published declarations }
    /// <summary>Clears the Pos array members</summary>
    procedure errasePosArr;
  end; { Ende Deklaration TRasterData }

  TSubmodRootDiff = class(TSubmodel)
    { Declaration of class TSubmodRootDiff. Base class for derived diffusion models }
  private
    { Private declarations }
    { Fields }
    { Functionality of the base class: all models can read raster data, exclude
      margins from calculations and display the data in the appropriate tabs of the
      Hume form. The 1D model does not output in the 3D plot tab. }
    fMyChart: TChart;
    fMyAdvStringGrid: TAdvStringGrid;
    fMyStructModel: TSubmodRootStrucNew;
    xyFile: TextFile;
    { Methoden }
    // Helper methods
    /// <summary>Initialization method extendable for file operations that should
    /// only be executed once.</summary>
    procedure init_;
  protected
    { Protected declarations, also accessible by derived classes }
    { Object for displaying the WAP in the Hume form }
    SeriesXY: TPointSeries;
    /// <summary>Area [cm²]</summary>
    Flaeche: real;
    /// <summary>RasterData instance owned by the submodel</summary>
    RasterData: TRasterData;
    /// <summary>Indicates whether initialization has already occurred</summary>
    initialisiert: boolean;
    { * -----------------------------------------------------------------------------
      Member HUME base class TPar (parameters)
      ------------------------------------------------------------------------------* }
    dimensionX, { Width of the computational domain [cm] }
    dimensionY, { Height of the computational domain [cm] }
    gridWidth, { Width of the raster grid (aggregated data) in x-direction [cm] }
    gridHeight, { Width of the raster grid (aggregated data) in y-direction [cm] }
    Dl, { Diffusion coefficient of nitrate in free H2O [cm^2/s] }
    max_dt, { Maximum time step width [s] }
    theta, { Volumetric water content [cm3/cm3] }
    Tiefe, { Depth of the layer [cm], assumption for mineralization calculation }
    { Mineralization model not yet available but should be implemented for both models }
    minera, { Mineralization rate [kg N/ha*d] }
    Clmin, { Minimum soil solution concentration [Mol/l], also needed for the
      numerical solution in the 1D model; note: originally in micromol/l }
    { Margins are necessary so that edge effects can be excluded when the root exit
      points are hexagonally distributed }
    verticMargin, { Vertical margin [cm] }
    horizMargin, { Horizontal margin [cm] }
    depthLayer, { Depth at which evaluation should begin (in the 2D cross-section) [cm] }
    SizeLayer, { Thickness of the layer [cm] }

    // Option to read root exploration metrics as parameters
    ParMRLD, { Mean root length density [cm/ccm] }
    Rad_Wurzel { Radius of the root [cm] }
      : TPar;
    (* -----------------------------------------------------------------------------
      Member HUME base class TState (state variables
      ------------------------------------------------------------------------------ *)
    N_AmountSoil, { N amount [kg N/ha], also basis for calculating concentrations
      in the calculation elements; see Kage dissertation p.79 where concentrations of
      10.0 micromol/l were assumed }
    Sum_N_AmountRoots { Cumulative amount of N taken up by the roots [kg N/ha] for
      the specified depth }
      : TState;
    (* -----------------------------------------------------------------------------
      Member HUME base class TVar (variables)
      ------------------------------------------------------------------------------ *)
    RLD_mean, { Mean root length density in a layer [cm/cm^3] calculated without
      roots located in the margins }
    AreaMiddle, { Central area without margins [cm2] }
    num_roots, { Number of roots in center and margins [n] }
    number_consid_roots, { Number of roots not located in margins [] }
    Min_S, { Mineralization rate [Mol/cm^3*s] }
    c_start, { Initial concentration [mol/cm^3], calculated from the initial N amount;
      the 1D model can also calculate concentrations }
    cl_av, { Average concentration in the soil solution [Mol/cm^3] }
    volumen, { Volume of the soil layer including margins [cm3] }
    De, { Effective diffusion coefficient [cm^2/s] }
    errorReg { Measure of error for regular distribution = number of roots that do
      not fit into the observation window when generating the uniform distribution,
      as a percentage of all roots [%] }
      : TVar;
    (* -----------------------------------------------------------------------------
      Member HUME base class TState (state variables). Declared and created in
      derived classes.
      ------------------------------------------------------------------------------ *)
    (* -----------------------------------------------------------------------------
      Member HUME base class TOption (options)
      ------------------------------------------------------------------------------ *)
    IniMethod, { Type of initialization, e.g. file or structural model }
    uptake_function, { Type of uptake calculation }
    RootInpDataFileXY, { Path and name of the init file with XY root data }
    RootInpDataFile, { Path and name of the init file with root data as counts in a grid }
    OutputXY, { Specify whether XY data should be written to a file }
    RootXYOutpDataFile { Path and name of the output file for XY data }
      : TOption;

    { Methoden }
    // Helper methods
    { Initialization depending on whether data has already been read from a file }
    procedure init_eingelesen; virtual;
    procedure fillChartRootDistr;
    procedure fillGridRasterData;
    procedure EqualDistribution;
    procedure distributeHexagonRow;
    procedure distributeHexagonCol;
    procedure writeOutputToFile;
    procedure removeMarginRoots;
    procedure calcNumberConsRoots; { Calculates the number of roots that are within
      the observation window but not in the margins }
    // Conversions between amount and concentration
    function Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): extended;
    function Cl_func(Tiefe_cm, theta, NMenge: real): extended;
  public
    { Public-Deklarationen }
    /// <summary>Flag for one-time write access</summary>
    hasWritten: boolean;
    procedure createAll; override;
    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobModReferenz: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    // Set and get methods
    function getRasterData: TRasterData;
  published
    { Published declarations }
    // Publication of properties in the object inspector.
    property Par_theta: TPar read theta write theta;
    property Par_Tiefe: TPar read Tiefe write Tiefe;
    property Par_volumen: TVar read volumen write volumen;
    property MyChart: TChart read fMyChart write fMyChart;
    property MyAdvStringGrid: TAdvStringGrid read fMyAdvStringGrid
      write fMyAdvStringGrid;
    property MyStructModel: TSubmodRootStrucNew read fMyStructModel
      write fMyStructModel;

  end; { Ende Deklaration TSubmodRootDiff }

var
  { Stores the root positions read from a file. A global variable is necessary,
    because when PosArr_eingelesen is a member of an object, an unexplained crash
    occurs. }
  PosArr_eingelesen: array [1 .. max_num_roots] of TPointDoubleType;

implementation

(* -----------------------------------------------------------------------------
  Implementation of the methods of TRasterData
  ------------------------------------------------------------------------------ *)
constructor TRasterData.create(Submodel: TSubmodel);
begin
  { The RasterData instance knows its submodel }
  SubmodRootDiff := Submodel;
end; // End TRasterData.create

procedure TRasterData.errasePosArr;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS:   TRasterData
  DESCRIPTION: Clears all fields of the Pos array so it can be filled with new
  xy values.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  for i := 1 to high(PosArr) do
  begin
    PosArr[i].x := 0;
    PosArr[i].y := 0;
    PosArr[i].xi := 0;
    PosArr[i].yi := 0;
    PosArr[i].root := 0;
    PosArr[i].NInflux := 0;
    PosArr[i].WInflux := 0;
    PosArr[i].area := 0;
  end;
end; // End TRasterData.errasePosArr

procedure TRasterData.readRasterData(fn: string; var Series: TPointSeries);
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS:   TRasterData
  DESCRIPTION: Reads aggregated raster data (root counts) which are then used to
  randomly determine coordinate points. Example of functionality: readln(f, Ncols)
  assigns the value read from f to the variable Ncols.
  ------------------------------------------------------------------------------ *)
var
  F: TextFile; { File variable for text files }
  S: string;
  Row, Col, root, AllRoot: integer;
  PointDoubleType: TPointDoubleType;
begin
  AssignFile(F, fn); { File selected }
  Reset(F);
  // Read the header
  Readln(F, S); { Read and discard first line of the file (header) }
  DescStr := S; { -> DescStr: description of the data set }
  Readln(F, S);
  Date := StrToFloat(S); { Second line: date (TDateTime format) }
  Readln(F, NRows); { Third line: number of rows }
  Readln(F, NCols); { Fourth line: number of columns }
  Readln(F, DimRows); { Fifth line: row height [cm] }
  Readln(F, DimCols); { Sixth line: column width [cm] }
  // Repeatedly read data until end of file
  for Row := 0 to NRows - 1 do
  begin { Read root counts into CountArr }
    for Col := 0 to NCols - 1 do
      read(F, CountArr[Col, Row]);
    Readln(F); // New line
  end;
  closeFile(F);
  AllRoot := 1; // Start at 1 because PosArr begins at 1.
  { Randomly distribute roots in each grid cell }
  for Col := 0 to NCols - 1 do
  begin
    for Row := 0 to NRows - 1 do
    begin
      { Exactly as many roots are assigned to PosArr as were read into CountArr. }
      for root := 1 to CountArr[Col, Row] do
      begin
        // randomize;     // [What does Randomize do?]
        PosArr[AllRoot].x := (Col) * DimCols + Random * DimCols;
        PosArr[AllRoot].y := (Row) * DimRows + Random * DimRows;
        PosArr[AllRoot].root := AllRoot;
        Series.AddXY(PosArr[AllRoot].x, PosArr[AllRoot].y);
        Inc(AllRoot);
      end;
    end;
  end;
  { The model and the RasterData object know the total number of roots }
  TSubmodRootDiff(SubmodRootDiff).num_roots.v := AllRoot - 1;
  self.NRoots := AllRoot - 1;
end; // End TRasterData.readRasterData

procedure TRasterData.readXYfromFile(Filename: TFilename;
  var Series: TPointSeries);
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TRasterData
  DESCRIPTION: Reads XY coordinates from a file and successively fills the passed
  (call-by-reference) PointSeries object with the XY pairs.
  ------------------------------------------------------------------------------ *)
var
  // File variable for text files
  F: TextFile;
  s_header,
  { Variable needed because some values in a text line must be skipped
    (see file format) }
  restString: String;
  { pos_delimiter stores the position of the last delimiter in the string }
  pos_delimiter: integer;
  PointDoubleType: TPointDoubleType;
  i: integer;
begin
  errasePosArr;
  // Issue: Is the clearing step needed (see called method)?
  // Read data from file:
  try
    AssignFile(F, Filename); // Link file variable to file
    Reset(F); // Read access
    // Read header and discard
    Readln(F, s_header);
    // Read the actual data
    i := 1; // PosArr starts at 0
    { Issue: may need to start at 1 to obtain correct root counts }
    NRoots := 0;
    { Defining bounds of PosArr; could be used if PosArr were implemented as a
      dynamic array }
    while not Eof(F) do
    begin
      Readln(F, restString);
      Inc(NRoots);
    end;
    Reset(F); // Reset file pointer to beginning
    // Read the header and discard it
    Readln(F, s_header);
    while not Eof(F) do
    begin
      Readln(F, PointDoubleType.x, PointDoubleType.y, PointDoubleType.root,
        restString);
      // Remove trailing whitespace:
      restString := TrimRight(restString);
      { Determine position of last delimiter in string }
      pos_delimiter := LastDelimiter(#9, restString); // #9 is tab
      // Remove leading part of string up to last delimiter:
      Delete(restString, 1, pos_delimiter);
      PointDoubleType.area := StrToFloat(restString);
      { As in the 2D model, all WAP must also be considered in the 1D model so that a
        suitable surface area of the Voronoi polygon can be calculated. In the 2D model
        only the uptake of sinks not located in the margins is later considered; in the
        1D model only coordinates not in the margins are used for calculating the
        parameters of the lognormal distribution function. }
      PosArr[i].x := PointDoubleType.x;
      PosArr[i].y := PointDoubleType.y;
      PosArr[i].root := i;
      PosArr[i].area := PointDoubleType.area;
      Series.AddXY(PointDoubleType.x, PointDoubleType.y);
      Inc(i);
    end;
    // Submodel knows the number of roots
    TSubmodRootDiff(SubmodRootDiff).num_roots.v := NRoots;
    { Due to a root at 0/0. The position of this root is obviously incorrect }
    // ShowMessage(FloatToStr(RasterData.PosArr[1].x));
  except
    ShowMessage('Error accessing file');
  end;
  closeFile(F);
end; // End TRasterData.readXYfromFile

procedure TRasterData.saveRootPositons(SaveDialog: TSaveDialog);
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TRasterData
  DESCRIPTION: After reading aggregated root data, saves the generated random
  root coordinates (considering assignment to a 5x5 cm grid cell) as floating point
  numbers in a file.
  ------------------------------------------------------------------------------ *)
var
  F: TextFile;
  root: integer;
begin
  If SaveDialog.Execute then
  begin
    AssignFile(F, SaveDialog.Filename);
    rewrite(F);
    { Format needed for importing into an external program that calculates
      Voronoi polygons }
    // Write header
    writeln(F, 'X	 Y	Number	Edge	Species	Radius');
    // Write the randomly generated X and Y values
    for root := 1 to NRoots do
      writeln(F, PosArr[root].x, ' ', PosArr[root].y, ' ', root, ' e a 0');
    closeFile(F);
  end;
end; // End TRasterData.saveRootPositons

(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TRasterData
  DESCRIPTION: Set and get methods
  ------------------------------------------------------------------------------ *)

(* -----------------------------------------------------------------------------
  TRasterData Ende
  ------------------------------------------------------------------------------ *)

(* -----------------------------------------------------------------------------
  Implementierung TSubmodRootDiff
  ------------------------------------------------------------------------------ *)
procedure TSubmodRootDiff.createAll;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff
  DESCRIPTION:
  Creates and initializes state variables, variables and parameters.
  The first parameter of the function call passes a string identical to the
  identifier and can be searched for.
  The second parameter contains a string indicating the unit used ([-] for
  dimensionless parameters, etc.).
  The third parameter is the actual floating-point value.
  For an explanation of the identifiers, see the declaration.
  ------------------------------------------------------------------------------ *)
begin
  inherited createAll;
  SeriesXY := TPointSeries.create(self);
  initialisiert := false;
  RasterData := TRasterData.create(self);
  // Create and initialize TPar
  ParCreate('dimensionX', '[cm]', 100, dimensionX);
  ParCreate('dimensionY', '[cm]', 100, dimensionY);
  ParCreate('gridWidth', '[cm]', 5, gridWidth);
  ParCreate('gridHeight', '[cm]', 5, gridHeight);
  ParCreate('max_dt', '[s]', 0, max_dt);
  ParCreate('theta', '[cm3/cm3]', 0.2, theta);
  ParCreate('Tiefe', '[cm]', 10, Tiefe);
  // [0 = no mineralization]
  ParCreate('Minera', '[kg N/ha*d]', 0, minera);
  ParCreate('Dl', '[cm^2/s]', 1.92E-5, Dl);
  ParCreate('Clmin', '[mol/l]', 0, Clmin);
  { Note: the original value was in micromol/l }
  ParCreate('verticMargin', '[cm]', 0, verticMargin);
  ParCreate('horizMargin', '[cm]', 0, horizMargin);
  ParCreate('depthLayer', '[cm]', 0, depthLayer);
  ParCreate('SizeLayer', '[cm]', 10, SizeLayer);
  ParCreate('ParMRLD', '[cm/ccm]', 0, ParMRLD);
  ParCreate('Rad_Wurzel', '[cm]', 0, Rad_Wurzel);
  // Create and initialize TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 0, false, N_AmountSoil);
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, Sum_N_AmountRoots);
  // Create and initialize TVar
  { Caveat: variables are always initialized to 0. If a start value other than 0 is
    needed, calculation and assignment must occur in init. It would be better not to
    declare such variables as TVar. }

  VarCreate('RLD_mean', '[cm/cm^3]', 0, false, RLD_mean);
  VarCreate('AreaMiddle', '[cm2]', 0, false, AreaMiddle);
  VarCreate('num_roots', '[-]', 0, false, num_roots);
  VarCreate('number_consid_roots', '[-]', 0, false, number_consid_roots);
  VarCreate('Min_s', '[Mol/cm^3*s]', 0, false, Min_S);
  VarCreate('c_start', '[Mol/cm^3]', 0, false, c_start);
  VarCreate('cl_av', '[Mol/cm^3]', 0, false, cl_av);
  VarCreate('volumen ', '[cm/m^3]', 0, false, volumen);
  VarCreate('errorReg ', '[%]', 0, false, errorReg);
  VarCreate('De ', '[cm^2/s]', 0, false, De);
  // Create and initialize TOption
  { Specify the source of the root data }
  OptCreate('IniMethod', 'InpPar', IniMethod);
  IniMethod.OptionList.add('InpPar'); // RLD/VC indicators as parameters
  IniMethod.OptionList.add('XYFile');
  IniMethod.OptionList.add('RasterDataFile');
  IniMethod.OptionList.add('SubmodStruct');
  { Define uptake function }
  OptCreate('uptake_function', 'ZeroSink', uptake_function);
  uptake_function.OptionList.add('ZeroSink');
  uptake_function.OptionList.add('ConstInflux');
  uptake_function.OptionList.add('MM');
  OptCreate('OutputXY', 'no', OutputXY);
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Paths for model comparison 1D vs 2D }
  { Paths to input and output files are identical for both submodels. Running both
    submodels simultaneously in one model run only makes sense for comparison. }
  OptCreate('RootInpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\abo130782.txt', RootInpDataFile);
  // File with root positions
  RootInpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\abo130782.txt');
  OptCreate('RootInpDataFileXY',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\poly_11_1406_40_60cm_mod.txt',
    RootInpDataFileXY); // File with root positions
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_ges.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\poly_11_1406_40_60cm_mod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_10_30.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_20_40.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_30_50.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_40_60.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_50_70.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_60_80.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rand_dist_395.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rand_dist_755.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rand_dist_1360.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\raender.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rld01_abw017.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rld01_abw17.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rld01_abw30.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rld001_abw05.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rld001_abw5.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\rld001_abw30.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_60_80ohneRand.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_oberBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_unterBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_3570.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t1_oberBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t2_oberBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t2_unterBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p15_t3_oberBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p15_t3_unterBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p15_t4_oberBod.txt');
  RootInpDataFileXY.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\p15_t4_unterBod.txt');
  OptCreate('RootXYOutpDataFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data',
    RootXYOutpDataFile);
  RootXYOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data');

end; // End TSubmodRootDiff.CreateAll

procedure TSubmodRootDiff.AddDataValueToDataSeries;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff
  DESCRIPTION: Performs various initializations
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  // Number of grid cells in X and Y direction
  numberGridCellsX, numberGridCellsY: integer;
begin
  inherited;
  // Rewrite output file for XY coordinates

  AssignFile(xyFile, RootXYOutpDataFile.Option);
  rewrite(xyFile); { Create or replace the file; it is rewritten for each model run }
  closeFile(xyFile);
  numberGridCellsX := trunc(dimensionX.v / gridWidth.v);
  numberGridCellsY := trunc(dimensionY.v / self.gridHeight.v);
  setLength(RasterData.CountArr, trunc(numberGridCellsX));
  for i := 0 to high(RasterData.CountArr) do
  begin
    setLength(RasterData.CountArr[i], trunc(numberGridCellsY));
  end;
  { Calculation of the diffusion coefficient of the solution in soil from the
    effective diffusion coefficient. See Kage dissertation p.43f.: for the 1D model
    (Nye/Tinker, Solute movement p.299) the effective diffusion coefficient is needed.
    It is calculated as De = Dl * f, where Dl is the diffusion coefficient in free
    water and f is the impedance factor. The relationship between theta and f is
    given by f = 3.35 * Theta^2 (Kage, p.41). }
  De.v := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  { Calculation of effective diffusion coefficient [cm2/s] for the 2D model }
  // De.v := Dbf(theta.v)/Theta.v; //alte Implementierung
  // Initialize TVar where appropriate at this stage
  Flaeche := dimensionX.v * dimensionY.v;
  { Area of the layer under investigation }
  volumen.v := Flaeche * Tiefe.v;
  { Calculation of mineralization rate in [Mol/cm3*s] }
  // Min_S.V := minera.v/14*1000/86400*1/(Tiefe.v*1e8);
  Min_S.v := minera.v * 1000 / (14 * 86400 * Tiefe.v * 1E8);
  { Calculation of the initial N amount in the soil layer from the concentration.
    Issue: Should theta be multiplied here because the concentration refers only to
    the volume of water contained in the soil? }
  // Init_NAmount_layer.V:=c_start.V*volumen.V*14/1000;
  { About the units:
    [g] = Mol/l * l * g/Mol }
  { Implementation of a check for previous initialization. This allows easy extension
    for initializations requiring file access or object instantiation. This should be
    done in the _init method. Initializations should only be performed when roots
    have already been read. The original TSubmodel method cannot be used because it
    is called multiple times. }
  if IniMethod.Option = 'rasterdatafile' then
  begin
    // init_;
    // init_eingelesen wird von den abgeleiteten Methoden mit inherited aufgerufen.
    initialisiert := true;
  end;
end; // End TSubmodRootDiff.init

procedure TSubmodRootDiff.init_;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff
  DESCRIPTION: Performs various initializations that should be executed only once
  (the global model's init procedure is called multiple times). This is relevant,
  for example, when creating objects or accessing files. Currently no such access
  occurs, but the structure is prepared for it.
  ------------------------------------------------------------------------------ *)
begin

end; // End TSubmodRootDiff.init_

procedure TSubmodRootDiff.init_eingelesen;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Calculates the number of roots that are in the observation window
  and simultaneously NOT in the margins.
  ------------------------------------------------------------------------------ *)
begin
  calcNumberConsRoots;
end; // End TSubmodRootDiff.init_eingelesen

procedure TSubmodRootDiff.CalcRates;
begin
  { Class is overridden in derived components. }
end; // End TSubmodRootDiff.CalcRates

procedure TSubmodRootDiff.Integrate;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS:  TSubmodRootDiff
  DESCRIPTION: Method overridden to successively change the time step width.
  ------------------------------------------------------------------------------ *)
begin
  { inherited is commented out because integration in the derived submodels is
    partially performed using an analytical solution. }
  // inherited;

end; // End TSubmodRootDiff.Integrate

procedure TSubmodRootDiff.fillChartRootDistr;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Both models can display roots in the RootDistribution tab.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  SeriesXY.Clear;
  // Fill the series object.
  for i := 1 to high(RasterData.PosArr) do
  begin
    if (RasterData.PosArr[i].x <> 0) and (RasterData.PosArr[i].y <> 0) then
      SeriesXY.AddXY(RasterData.PosArr[i].x, RasterData.PosArr[i].y);
  end;
  MyChart.AddSeries(SeriesXY);
end;

procedure TSubmodRootDiff.fillGridRasterData;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Both models can write aggregated root data to the form.
  The method fills the aggregated root data (number of roots per grid cell)
  into the AdvStringGrid of the Hume form.
  ------------------------------------------------------------------------------ *)
var
  Row, Col, SumRow, SumCol: integer;
begin
  // Set grid size
  MyAdvStringGrid.ColCount := RasterData.NCols + 4;
  MyAdvStringGrid.RowCount := RasterData.NRows + 4;
  for Row := 1 to RasterData.NRows do
  begin
    { Calculate row sums }
    SumRow := 0;
    for Col := 1 to RasterData.NCols do
    begin
      MyAdvStringGrid.Cells[Col, Row] :=
        IntToStr(RasterData.CountArr[Col - 1, Row - 1]);
      SumRow := SumRow + StrtoInt(MyAdvStringGrid.Cells[Col, Row]);
    end;
    MyAdvStringGrid.Cells[RasterData.NCols + 1, Row] := IntToStr(SumRow);
  end;

  For Col := 1 to RasterData.NCols do
  begin { Write column headers }
    MyAdvStringGrid.Cells[Col, 0] :=
      IntToStr((Col - 1) * trunc(RasterData.DimCols)) + ' - ' +
      IntToStr(Col * trunc(RasterData.DimCols));
  end;
  For Row := 1 to RasterData.NRows do
  begin { Write row headers }
    MyAdvStringGrid.Cells[0, Row] :=
      IntToStr((Row - 1) * trunc(RasterData.DimRows)) + ' - ' +
      IntToStr(Row * trunc(RasterData.DimRows));
  end;
  { Calculate column sums }
  for Col := 1 to RasterData.NCols do
  begin
    SumCol := 0; { Calculate column sums }
    for Row := 1 to RasterData.NRows do
    begin
      SumCol := SumCol + StrtoInt(MyAdvStringGrid.Cells[Col, Row]);
    end;
    MyAdvStringGrid.Cells[Col, RasterData.NRows + 1] := IntToStr(SumCol);
  end;
end;

procedure TSubmodRootDiff.writeOutputToFile;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Writes coordinates and areas of PosArr to a file. With a structural model,
  output occurs at each time step; with static root positions only at the start
  of the model run. For testing in the static case, the positions of roots in
  the margins are also written.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  { Only sinks that are not in the margin and observation window are output.
    PosArr_middle should already contain only these roots }
  PosArr_middle: Array of TPointDoubleType;
begin
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  { In the case of the structural model (dynamic change of root positions) output
    occurs at every time step }
  if IniMethod.Option = 'SubmodStruct' then
  begin
    j := 0;
    for i := 1 to trunc(RasterData.NRoots) do
    begin
      // Point not in vertical margins
      if (RasterData.PosArr[i].x >= verticMargin.v) and
        (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
      // Point not in horizontal margins
        and (RasterData.PosArr[i].y >= horizMargin.v) and
        (RasterData.PosArr[i].y <= dimensionY.v - horizMargin.v) then
      begin
        PosArr_middle[j].x := RasterData.PosArr[i].x;
        PosArr_middle[j].y := RasterData.PosArr[i].y;
        PosArr_middle[j].xi := RasterData.PosArr[i].xi;
        PosArr_middle[j].yi := RasterData.PosArr[i].yi;
        PosArr_middle[j].NInflux := RasterData.PosArr[i].NInflux;
        PosArr_middle[j].WInflux := RasterData.PosArr[i].WInflux;
        PosArr_middle[j].root := RasterData.PosArr[i].root;
        PosArr_middle[j].area := RasterData.PosArr[i].area;
        Inc(j);
      end;
    end;
    AssignFile(xyFile, RootXYOutpDataFile.Option);
    rewrite(xyFile);
    write(xyFile, 'Modellzeit: ', GlobMod.Time.v:6:2, ' ');
    writeln(xyFile);
    // Write header
    write(xyFile, 'Lfd.Nr.', ' ', 'X', ' ', 'Y', ' ', 'Flaeche', ' ');
    writeln(xyFile);
    for i := 0 to high(PosArr_middle) do
    begin
      write(xyFile, PosArr_middle[i].root, ' ');
      write(xyFile, PosArr_middle[i].x, ' ');
      write(xyFile, PosArr_middle[i].y, ' ');
      write(xyFile, PosArr_middle[i].area, ' ');
      writeln(xyFile);
    end;
    closeFile(xyFile);
  end
  else
  begin
    while Not hasWritten do
    begin
      j := 0;
      for i := 1 to trunc(RasterData.NRoots) do
      begin
        // Point not in vertical margins
        if (RasterData.PosArr[i].x >= verticMargin.v) and
          (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
        // Point not in horizontal margins
          and (RasterData.PosArr[i].y >= horizMargin.v) and
          (RasterData.PosArr[i].y <= dimensionY.v - horizMargin.v) then
        begin
          PosArr_middle[j].x := RasterData.PosArr[i].x;
          PosArr_middle[j].y := RasterData.PosArr[i].y;
          PosArr_middle[j].xi := RasterData.PosArr[i].xi;
          PosArr_middle[j].yi := RasterData.PosArr[i].yi;
          PosArr_middle[j].NInflux := RasterData.PosArr[i].NInflux;
          PosArr_middle[j].WInflux := RasterData.PosArr[i].WInflux;
          PosArr_middle[j].root := RasterData.PosArr[i].root;
          PosArr_middle[j].area := RasterData.PosArr[i].area;
          Inc(j);
        end;
      end;
      AssignFile(xyFile, RootXYOutpDataFile.Option);
      rewrite(xyFile);
      write(xyFile, 'Modellzeit: ', GlobMod.Time.v:6:2, ' ');
      writeln(xyFile);
      // Write header
      write(xyFile, 'Lfd.Nr.', ' ', 'X', ' ', 'y', ' ', 'Flaeche', ' ');
      writeln(xyFile);
      for i := 0 to high(PosArr_middle) do
      begin
        write(xyFile, PosArr_middle[i].root, ' ');
        write(xyFile, PosArr_middle[i].x, ' ');
        write(xyFile, PosArr_middle[i].y, ' ');
        write(xyFile, PosArr_middle[i].area, ' ');
        writeln(xyFile);
      end;
      // Border points
      write(xyFile, 'Punkte in Rändern:');
      writeln(xyFile);
      write(xyFile, 'Lfd.Nr.', ' ', 'X', ' ', 'y', ' ', 'Flaeche', ' ');
      writeln(xyFile);
      for i := 1 to trunc(RasterData.NRoots) do
      begin
        // Point not in vertical margins
        if (RasterData.PosArr[i].x < verticMargin.v) or
          (RasterData.PosArr[i].x > dimensionX.v - verticMargin.v)
        // Point not in horizontal margins
          or (RasterData.PosArr[i].y < horizMargin.v) or
          (RasterData.PosArr[i].y > dimensionY.v - horizMargin.v) then
        begin
          write(xyFile, RasterData.PosArr[i].root, ' ');
          write(xyFile, RasterData.PosArr[i].x, ' ');
          write(xyFile, RasterData.PosArr[i].y, ' ');
          write(xyFile, RasterData.PosArr[i].area, ' ');
          writeln(xyFile);
        end;
      end;
      hasWritten := true;
      closeFile(xyFile);
    end;
  end;

end;

procedure TSubmodRootDiff.EqualDistribution;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  All diffusion models can compute a uniform distribution from a given one.
  The method distributes points based on a given WLD evenly over an area.
  The TPointSeries object of the calling HUME GUI method is refilled so the
  display can be updated. Different methods were created for this purpose and
  can be switched here.
  ------------------------------------------------------------------------------ *)
var
  radSRP, // Radius SRP
  AreaSRP // Fläche SRP
    : double;
begin
  { If RLD is read as a parameter, the number of roots in the observation window
    still has to be calculated }
  if IniMethod.Option = 'inppar' then
  begin
    radSRP := 1 / sqrt(Pi * ParMRLD.v);
    AreaSRP := Pi * sqr(radSRP);
    num_roots.v := dimensionX.v * dimensionY.v / AreaSRP;
    RasterData.NRoots := trunc(num_roots.v);
  end;
  // Fill rows
  distributeHexagonRow;
  calcNumberConsRoots;
  // Fill columns
  // distributeHexagonCol;
end; // End TSubmodRootDiff.hexDistribution

procedure TSubmodRootDiff.distributeHexagonRow;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Distribution using hexagons. Rows are filled sequentially.
  For better distribution the points still need to be shifted by half the
  radius of the circumscribed circle.
  ------------------------------------------------------------------------------ *)
var
  { The following radii are required to compute the distribution. The inscribed
    and circumscribed circles refer to the regular hexagon with the root at its
    center. }
  AreaObservation, // Area of observation window
  Rad_IK, // Radius of inscribed circle of hexagon
  Rad_AK, // Radius of circumscribed circle of hexagon
  Area_Polygon, // Area of hexagon
  pos_x, // Position of sink in x-direction
  pos_y, // Position of sink in y-direction
  dimx, // Boundary of calculation area in x-direction
  dimy, // Boundary of calculation area in y-direction
  angel, // 60° in radians
  stretch, // Distance (2*Rad_AK - edge)/2 (see slide on uniform distribution)
  /// <summary>Edge length of hexagon</summary>
  edgeHexagon: real;
  errorRoot, i, j, number_row: integer;

begin
  inherited;
  { Calculation of the area assigned to one hexagon.
    Margins are cut off only after the uniform distribution }
  AreaObservation := dimensionX.v * dimensionY.v;
  Area_Polygon := AreaObservation / num_roots.v;
  // Conversion from degrees to radians, see math handbook p.336
  { Angle in radians = angle in degrees/360*2Pi }
  angel := 60 / 360 * (2 * Pi);
  // See geometry handbook
  Rad_AK := sqrt(Area_Polygon / (3 * sin(angel)));
  // alternative formula: Rad_AK := sqrt(2/3*(Area_Polygon/sqrt(3)));
  // Radius of inscribed circle corresponds to height in subtriangle; see geometry handbook
  Rad_IK := (Rad_AK / 2) * sqrt(3);
  // Edge length of hexagon equals radius of circumscribed circle
  edgeHexagon := Rad_AK;
  stretch := Rad_AK / 2;
  { For clarity one could also write:
    stretch := (2*Rad_AK - edgeHexagon)/2 }
  dimx := dimensionX.v;
  dimy := dimensionY.v;
  // Fill PosArr:
  RasterData.errasePosArr; // Delete old entries. Problem: necessary???
  // number_row := 1;           // Start at row 1
  number_row := 0; // Start at row 0
  { Caveat: PosArr begins at 1 }
  j := 0;
  i := 1;
  errorRoot := 0;
  errorReg.v := 0;
  while i <= trunc(num_roots.v) do
  begin
    if (number_row mod 2 <> 0) then // odd rows
    begin
      // Calculation for odd rows:
      pos_x := ((j * 2 + 1) * Rad_AK + j * edgeHexagon);
      pos_y := Rad_IK * number_row;
      if (pos_x <= dimx) and (pos_y <= dimy) then
      // As long as the point remains within the calculation area
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        { It is assumed that the area of the hexagon corresponds to the area of the
          Voronoi polygon. Points within the polygon would then be closer to the central
          sink than to any other sink. }
        { This point is not entirely consistent since PosArr could also be used for the
          calculations. }
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      { If roots are no longer in the observation window, in row-wise filling this
        means the position is outside the observation area in the y-direction }
      if (pos_y > dimy) then
      begin
        Inc(errorRoot);
      end;
      Inc(j);
      Inc(i);
      if pos_x > dimx then
      // At end of row: switch to branch for even rows.
      begin
        j := 0;
        { Step back (necessary because otherwise the fields of a root in PosArr would
          be set to 0 when moving to the next row) }
        dec(i);
        Inc(number_row);
      end;
    end;
    if (number_row mod 2 = 0) then // even rows
    // Calculation for even rows:
    begin
      pos_x := stretch + (j + 1) * edgeHexagon + (j * 2 + 1) * Rad_AK;
      // For better distribution
      pos_y := (number_row) * Rad_IK;
      if (pos_x <= dimx) and (pos_y <= dimy) then
      // As long as the point remains within the calculation area
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      { If roots are no longer in the observation window, in row-wise filling this
        means the position is outside the observation area in the y-direction }
      if (pos_y > dimy) then
      begin
        Inc(errorRoot);
      end;
      Inc(j);
      Inc(i);
      if pos_x > dimx then
      // At end of row: switch to branch for odd rows.
      begin
        j := 0;
        dec(i);
        Inc(number_row);
      end;
    end;
  end;
  errorReg.v := errorRoot / num_roots.v * 100;
end; // End TSubmodRootDiff.distributeHexagonRow

procedure TSubmodRootDiff.distributeHexagonCol;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Distribution using hexagons. Columns are filled sequentially.
  The method may be advantageous when nutrient uptake in layers is calculated
  (this still needs verification). The distribution was adjusted: X-values were
  shifted half a Rad_AK to the right and Y-values half a Rad_AK upward (see
  slide Filling columns 2). CAVE: method not up to date and should be improved
  based on distributeHexagonRow (e.g., calculation of ErrorReg).
  ------------------------------------------------------------------------------ *)
var
  { The following radii are required to compute the distribution. The inscribed
    and circumscribed circles refer to the regular hexagon with the root at its
    center. }
  AreaObservation, // Area of observation window
  Rad_IK, // Radius of inscribed circle of hexagon
  Rad_AK, // Radius of circumscribed circle of hexagon
  Area_Polygon, // Area of hexagon
  pos_x, // Position of sink in x-direction
  pos_y, // Position of sink in y-direction
  dimx, // Boundary of calculation area in x-direction
  dimy, // Boundary of calculation area in y-direction
  angel, // 60° in radians
  stretch, // Distance (2xRad_AK - edge)/2 (see slide on uniform distribution)
  { Edge length of hexagon, actually equal to Rad_AK, kept for clarity }
  edgeHexagon: real;
  i, j, number_col: integer;
begin
  inherited;
  AreaObservation := dimensionX.v * dimensionY.v;
  { Calculation of the area assigned to one hexagon: }
  Area_Polygon := AreaObservation / num_roots.v;
  // Conversion from degrees to radians, see math handbook p.336
  { Angle in radians = angle in degrees/360*2Pi }
  angel := 60 / 360 * (2 * Pi);
  // See geometry handbook
  Rad_AK := sqrt(Area_Polygon / (3 * sin(angel)));
  // alternative formula: Rad_AK := sqrt(2/3*(Area_Polygon/sqrt(3)));
  // Radius of inscribed circle corresponds to height in subtriangle; see geometry handbook
  Rad_IK := (Rad_AK / 2) * sqrt(3);
  // Edge length of hexagon equals radius of circumscribed circle
  edgeHexagon := Rad_AK;
  stretch := Rad_AK / 2;
  { For clarity one could also write:
    stretch := (2*Rad_AK - edgeHexagon)/2 }
  dimx := self.dimensionX.v;
  dimy := self.dimensionY.v;
  // Fill PosArr:
  RasterData.errasePosArr; // Delete old entries. Issue: necessary???
  // number_col := 1;           // Start at column 1
  number_col := 0; // Start at column 0
  j := 0;
  { Caveat: PosArr begins at 1 }
  i := 1;
  while i <= trunc(num_roots.v) do
  begin
    if (number_col mod 2 <> 0) then // odd columns
    begin
      // Calculation for odd columns:
      pos_y := ((j * 2 + 1) * Rad_AK + j * edgeHexagon);
      pos_x := (number_col) * Rad_IK;
      // Shift X-values by Rad_AK/2 to the right
      pos_x := pos_x + Rad_AK / 2;
      // Shift Y-values by Rad_AK/2 upward
      pos_y := pos_y - Rad_AK / 2;
      // As long as the point remains within the calculation area
      if (pos_x <= dimx) and (pos_y <= dimy) then
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        { It is assumed that the area of the hexagon corresponds to the area of the
          Voronoi polygon. Points within the polygon would then be closer to the central
          sink than to any other sink. }
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      Inc(j);
      Inc(i);
      if pos_y > dimy then
      // At end of row: switch to branch for even columns.
      begin
        j := 0;
        dec(i); // Step back
        Inc(number_col);
      end;
    end;
    if (number_col mod 2 = 0) then // even columns
    // Calculation for even columns:
    begin
      pos_y := stretch + (j + 1) * edgeHexagon + (j * 2 + 1) * Rad_AK;
      pos_x := Rad_IK * number_col;
      // Shift X-values by Rad_AK/2 to the right
      pos_x := pos_x + Rad_AK / 2;
      // Shift Y-values by Rad_AK/2 upward
      pos_y := pos_y - Rad_AK / 2;
      // As long as the point remains within the calculation area
      if (pos_x <= dimx) and (pos_y <= dimy) then
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      Inc(j);
      Inc(i);
      if pos_y > dimy then
      // At end of row: switch to branch for odd columns.
      begin
        j := 0;
        dec(i);
        Inc(number_col);
      end;
    end;
  end;
end; // End TSubmodRootDiff.distributeHexagonCol

procedure TSubmodRootDiff.calcNumberConsRoots;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Calculates the number of valid roots (located in the observation window but
  not in the margins)
  ------------------------------------------------------------------------------ *)
var
  rootcount, i: integer;
begin
  rootcount := 0;
  number_consid_roots.v := 0;
  // number_consid_roots.V := RasterData.NRoots; // initially accept all roots
  { Determine the number of roots to consider (for setting array bounds).
    The input parameters for the margins are relative values that must be
    related to the observation window dimensionX, dimensionY. }
  for i := 1 to RasterData.NRoots do
  begin
    // Point not in vertical margins
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
    // Point not in horizontal margins
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= dimensionY.v - horizMargin.v) then
    begin
      Inc(rootcount);
      number_consid_roots.v := rootcount;
    end;
  end;
  // Debugging
  // showMessage(self.SubModName+': '+floatToStr(number_consid_roots.V));
end;

function TSubmodRootDiff.Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): extended;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Returns the calculated N amount [kgN/ha]; converts the existing
  concentration (aggregated values)
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000; { Molecular weight of nitrogen }
var
  volumen_cm3, { Volume of soil layer on an area of 1 ha }
  cm3_ha, n_menge: extended;
begin
  volumen_cm3 := Tiefe.v * 1E8;
  cm3_ha := theta * volumen_cm3; { Water content on one hectare }
  n_menge := Cli_mol_cm3 * kg_mol * cm3_ha;
  Result := n_menge;
end;

function TSubmodRootDiff.Cl_func(Tiefe_cm, theta, NMenge: real): extended;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Returns the concentration [Mol N/cm^3]
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000; { Molecular weight of nitrogen }
var
  volumen_cm3, { Volume of soil layer on an area of 1 ha }
  cm3_ha, Cli_mol_cm3: extended;

begin
  volumen_cm3 := Tiefe.v * 1E8;
  cm3_ha := theta * volumen_cm3; { Water content on one hectare }
  Cli_mol_cm3 := NMenge / (kg_mol * cm3_ha);
  Result := Cli_mol_cm3;
end;

procedure TSubmodRootDiff.removeMarginRoots;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Removes roots located in the margins from the Pos array
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  { Dynamic array that temporarily stores roots not located in the margins }
  PosArr_middle: Array of TPointDoubleType;
begin
  // Remove 'invalid' roots
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  j := 0;
  // Fill PosArr_middle
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Point not in vertical margins
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
    // Point not in horizontal margins
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= dimensionY.v - horizMargin.v) then
    begin
      PosArr_middle[j].x := RasterData.PosArr[i].x;
      PosArr_middle[j].y := RasterData.PosArr[i].y;
      PosArr_middle[j].xi := RasterData.PosArr[i].xi;
      PosArr_middle[j].yi := RasterData.PosArr[i].yi;
      PosArr_middle[j].NInflux := RasterData.PosArr[i].NInflux;
      PosArr_middle[j].WInflux := RasterData.PosArr[i].WInflux;
      PosArr_middle[j].root := RasterData.PosArr[i].root;
      PosArr_middle[j].area := RasterData.PosArr[i].area;
      Inc(j);
    end;
  end;
  // Delete old PosArr
  RasterData.errasePosArr;
  j := 1;
  // Write back values from the temporary PosArr
  for i := 0 to high(PosArr_middle) do
  begin
    RasterData.PosArr[j].x := PosArr_middle[i].x;
    RasterData.PosArr[j].y := PosArr_middle[i].y;
    RasterData.PosArr[j].xi := PosArr_middle[i].xi;
    RasterData.PosArr[j].yi := PosArr_middle[i].yi;
    RasterData.PosArr[j].NInflux := PosArr_middle[i].NInflux;
    RasterData.PosArr[j].WInflux := PosArr_middle[i].WInflux;
    RasterData.PosArr[j].root := PosArr_middle[i].root;
    RasterData.PosArr[j].area := PosArr_middle[i].area;
    Inc(j);
  end;
  RasterData.NRoots := trunc(number_consid_roots.v);
end;

function TSubmodRootDiff.getRasterData: TRasterData;
begin
  Result := self.RasterData;
end;

end.
