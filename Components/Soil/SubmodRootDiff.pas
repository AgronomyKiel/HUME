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

  { Klassen }
  TSRPLight = class(TObject)
    { Lean, memory-saving version of an SRP }
  private
    { Private-Deklarationen }
  protected
  public
    { Public declarations }
    /// <summary>Root coordinates [cm] and root length density of the SRP [cm/cm^3]</summary>
    x, y, wld: double;
  end;

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
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
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
    { Private-Deklarationen }
    { Felder }
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
      Member HUME-Basisklasse TPar (Parameter)
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
      Member HUME-Basisklasse TState (Zustandsvariablen
      ------------------------------------------------------------------------------ *)
    N_AmountSoil, { N amount [kg N/ha], also basis for calculating concentrations
      in the calculation elements; see Kage dissertation p.79 where concentrations of
      10.0 micromol/l were assumed }
    Sum_N_AmountRoots { Cumulative amount of N taken up by the roots [kg N/ha] for
      the specified depth }
      : TState;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TVar (Variablen)
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
      Member HUME-Basisklasse TState (Zustandsvariablen). Werden in abgeleiteten
      Klassen deklariert und erzeugt.
      ------------------------------------------------------------------------------ *)
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TOption (Optionen)
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
    // Set- und Get-Methoden
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
  F: TextFile; { Dateivariable vom Typ Textfile }
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
    Readln(F); // Neue Zeile
  end;
  closeFile(F);
  AllRoot := 1; // Start at 1 because PosArr begins at 1.
  { Randomly distribute roots in each grid cell }
  for Col := 0 to NCols - 1 do
  begin
    for Row := 0 to NRows - 1 do
    begin
      { Es werden genau soviele Wurzeln dem PosArr zugewiesen, wie als Anzahlen ins
        countArr eingelesen wurden. }
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
    // Lesen der eigentlichen Daten
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
    Reset(F); // Dateizeiger wieder auf Anfang setzen
    // Lesen des Headers. Wird verworfen
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
  { Klasse wird in den abgleiteten Komponenten überschrieben. }
end; // End TSubmodRootDiff.CalcRates

procedure TSubmodRootDiff.Integrate;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE:  TSubmodRootDiff
  BESCHREIBUNG: Methode wurde überschrieben, um die Zeitschrittweite sukzessive
  zu verändern.
  ------------------------------------------------------------------------------ *)
begin
  { inherited auskommentiert, da die Integration in den abgeleiteten Submodellen
    teilweise mit Hilfe einer analytischen Lösung ausgeführt wird. }
  // inherited;

end; // End TSubmodRootDiff.Integrate

procedure TSubmodRootDiff.fillChartRootDistr;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Beide Modelle sind in der Lage, Wurzeln in dem Reiter RootDistri-
  bution darzustellen.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  SeriesXY.Clear;
  // Füllen des series-Objekts.
  for i := 1 to high(RasterData.PosArr) do
  begin
    if (RasterData.PosArr[i].x <> 0) and (RasterData.PosArr[i].y <> 0) then
      SeriesXY.AddXY(RasterData.PosArr[i].x, RasterData.PosArr[i].y);
  end;
  MyChart.AddSeries(SeriesXY);
end;

procedure TSubmodRootDiff.fillGridRasterData;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  Beide Modelle sind in der Lage aggregierte Wurzeldaten in das Formular zu
  schreiben.
  Methode füllt die aggregierten Wurzeldaten (Anzahl Wurzeln pro Gridzelle
  in das AdvStringGrid des Hume-Formulars.
  ------------------------------------------------------------------------------ *)
var
  Row, Col, SumRow, SumCol: integer;
begin
  // Festlegen Größe des Grids
  MyAdvStringGrid.ColCount := RasterData.NCols + 4;
  MyAdvStringGrid.RowCount := RasterData.NRows + 4;
  for Row := 1 to RasterData.NRows do
  begin
    { Summe für die Zeilen berechnen }
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
  begin { Spaltenköpfe schreiben }
    MyAdvStringGrid.Cells[Col, 0] :=
      IntToStr((Col - 1) * trunc(RasterData.DimCols)) + ' - ' +
      IntToStr(Col * trunc(RasterData.DimCols));
  end;
  For Row := 1 to RasterData.NRows do
  begin { Zeilenköüfe schreiben }
    MyAdvStringGrid.Cells[0, Row] :=
      IntToStr((Row - 1) * trunc(RasterData.DimRows)) + ' - ' +
      IntToStr(Row * trunc(RasterData.DimRows));
  end;
  { Summe für die Spalten berechnen }
  for Col := 1 to RasterData.NCols do
  begin
    SumCol := 0; { Summe für die Spalten berechnen }
    for Row := 1 to RasterData.NRows do
    begin
      SumCol := SumCol + StrtoInt(MyAdvStringGrid.Cells[Col, Row]);
    end;
    MyAdvStringGrid.Cells[Col, RasterData.NRows + 1] := IntToStr(SumCol);
  end;
end;

procedure TSubmodRootDiff.writeOutputToFile;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  Schreibt Koordinaten und Flächeninhalte des PosArrays in eine Datei, im Falle
  eines vorhandenen Strukturmodells bei jedem Zeitschritt, bei statischen Wurzel
  positionen nur am Beginn des Modelllaufs, für Testzwecke im statischen Fall auch
  die Positionen der Wurzeln in den Rändern
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  { Nur Senken, die nicht im Rand und im Beobachtungsfenster liegen werden ausgege-
    ben. PosArr-Middle sollte sowieso nur diese Wurzeln }
  PosArr_middle: Array of TPointDoubleType;
begin
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  { Im Falle des Strukturmodells (dynamische Änderung der Wurzeln-Pos) Ausgabe in
    jedem Zeitschritt }
  if IniMethod.Option = 'SubmodStruct' then
  begin
    j := 0;
    for i := 1 to trunc(RasterData.NRoots) do
    begin
      // Punkt nicht in den vertikalen Rändern
      if (RasterData.PosArr[i].x >= verticMargin.v) and
        (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
      // Punkt nicht in den horizontalen Rändern
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
    // Header schreiben
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
        // Punkt nicht in den vertikalen Rändern
        if (RasterData.PosArr[i].x >= verticMargin.v) and
          (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
        // Punkt nicht in den horizontalen Rändern
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
      // Header schreiben
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
      // Randständige Punkte
      write(xyFile, 'Punkte in Rändern:');
      writeln(xyFile);
      write(xyFile, 'Lfd.Nr.', ' ', 'X', ' ', 'y', ' ', 'Flaeche', ' ');
      writeln(xyFile);
      for i := 1 to trunc(RasterData.NRoots) do
      begin
        // Punkt nicht in den vertikalen Rändern
        if (RasterData.PosArr[i].x < verticMargin.v) or
          (RasterData.PosArr[i].x > dimensionX.v - verticMargin.v)
        // Punkt nicht in den horizontalen Rändern
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
  BESCHREIBUNG:
  Alle Diffusionsmodelle können ausgehend von eine geg. Verteilung eine gleichför-
  mige Verteilung berechnen.
  Methode verteilt Punkte ausgehend von einer gegebenen WLD gleichmäßig auf einer
  Fläche. Das TPointSeries-Objekt der aufrufenden Methode der HUME - GUI wird neu
  gefüllt, sodass die Darstellung angepasst werden kann. Es wurden zu diesem Zweck
  verschiedene Methoden erstellt, zwischen denen an dieser Stelle einfach umgeschal-
  tet werden kann.
  ------------------------------------------------------------------------------ *)
var
  radSRP, // Radius SRP
  AreaSRP // Fläche SRP
    : double;
begin
  { falls RLD als Paramenter eingelesen wurde, muss noch die Anzahl der Wurzeln im
    Beobachtungsfenster berechnet werden }
  if IniMethod.Option = 'inppar' then
  begin
    radSRP := 1 / sqrt(Pi * ParMRLD.v);
    AreaSRP := Pi * sqr(radSRP);
    num_roots.v := dimensionX.v * dimensionY.v / AreaSRP;
    RasterData.NRoots := trunc(num_roots.v);
  end;
  // Füllen von Reihen
  distributeHexagonRow;
  calcNumberConsRoots;
  // Füllen von Spalten
  // distributeHexagonCol;
end; // End TSubmodRootDiff.hexDistribution

procedure TSubmodRootDiff.distributeHexagonRow;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Verteilung mit Hilfe von Sechsecken. Es werden dabei nacheinander
  REIHEN gefüllt. Problem: Um eine bessere Verteilung zu erreichen, müssen die
  Punkte noch um den halben Radius des Außenkreises verschoben werden.
  ------------------------------------------------------------------------------ *)
var
  { Für die Berechnung der Verteilung werden folgende Radii benötigt. Innen- und
    Außenkreis beziehen sich auf das regelmäßige Sechseck, in dessen Zentrum sich
    die Wurzel befindet. }
  AreaObservation, // Fläche Beobachtungsfenster
  Rad_IK, // Radius Innenkreis Sechseck
  Rad_AK, // Radius Außenkreis Sechseck
  Area_Polygon, // Fläche Sechseck
  pos_x, // Position der Senke in x-Richtung
  pos_y, // Position der Senke in y-Richtung
  dimx, // Grenze der Berechnungsfläche in x-Richtung
  dimy, // Grenze der Berechnungsfläche in y-Richtung
  angel, // 60° im Bogenmaß
  stretch, // Distance (2*Rad_AK - edge)/2 (see slide on uniform distribution)
  /// <summary>Edge length of hexagon</summary>
  edgeHexagon: real;
  errorRoot, i, j, number_row: integer;

begin
  inherited;
  { Berechnung des Flächeninhalts, der einem Sechseck zugeordnet werden soll.
    Ränder werden erst nach Gleichverteilung abgeschnitten }
  AreaObservation := dimensionX.v * dimensionY.v;
  Area_Polygon := AreaObservation / num_roots.v;
  // Umrechung von Gradmaß ins Bogenmaß, vgl. Mathehandbuch S. 336
  { Winkel im Bogenmaß=Winkel im Gradmaß/360*2Pi }
  angel := 60 / 360 * (2 * Pi);
  // Vgl. Geometriehandbuch
  Rad_AK := sqrt(Area_Polygon / (3 * sin(angel)));
  // alternative Formel: Rad_AK:=sqrt(2/3*(Area_Polygon/sqrt(3)));
  // Radius Innenkreis entspricht Höhe im Teildreieck, Vgl. Geometriehandbuch
  Rad_IK := (Rad_AK / 2) * sqrt(3);
  // Kantenlänge Sechseck entspricht dem Radius des Außenkreises
  edgeHexagon := Rad_AK;
  stretch := Rad_AK / 2;
  { Man könnte auch wegen Anschaulichkeit folgendes schreiben:
    stretch:=(2*Rad_Ak-edgeHexagon)/2 }
  dimx := dimensionX.v;
  dimy := dimensionY.v;
  // Füllen des Pos_Arrays:
  RasterData.errasePosArr; // Löschen alter Einträge. Problem: notwendig???
  // number_row:=1;           //Start bei Reihe 1
  number_row := 0; // Start bei Reihe 0
  { Cave: PosArr beginnt bei 1 }
  j := 0;
  i := 1;
  errorRoot := 0;
  errorReg.v := 0;
  while i <= trunc(num_roots.v) do
  begin
    if (number_row mod 2 <> 0) then // ungerade Reihe
    begin
      // Berechnung ungerader Reihen:
      pos_x := ((j * 2 + 1) * Rad_AK + j * edgeHexagon);
      pos_y := Rad_IK * number_row;
      if (pos_x <= dimx) and (pos_y <= dimy) then
      // Solange der Punkt sich nicht außerhalb der Berechnungsfläche befindet
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        { Es wird davon ausgegangen, dass die Fläche des Sechsecks der Fläche des Voronoi-
          Polygons entspricht. Die Punkte innerhalb der Grenzen des Polygons wären dann
          die Punkte, die zur Senke im Mittelpunkt einen kleineren Abstand haben als zu
          allen anderen vorhandenen Senken. }
        { Dieser Punkt ist nicht ganz konsistent, da man auch das PosArr für die Berech-
          nungen heranziehen könnte. }
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      { Wenn Wurzeln sich nicht mehr im Beobachtungsfenster befinden, bedeutet bei
        reihenweiser Befüllung, den Fall, dass sich Pos. in y-Richtung ausserhalb der
        Beobachtungsfläche befindet }
      if (pos_y > dimy) then
      begin
        Inc(errorRoot);
      end;
      Inc(j);
      Inc(i);
      if pos_x > dimx then
      // Am Ende der Reihe: Wechsel in den Ast für gerade Reihen.
      begin
        j := 0;
        { Schritt zurück (Notwendig, da sonst die Felder einer Wurzel im PosArr beim
          Übergang in die nächste Reihe mit 0 belegt werden }
        dec(i);
        Inc(number_row);
      end;
    end;
    if (number_row mod 2 = 0) then // gerade Reihe
    // Berechnung gerader Reihen:
    begin
      pos_x := stretch + (j + 1) * edgeHexagon + (j * 2 + 1) * Rad_AK;
      // Für bessere Verteilung wird
      pos_y := (number_row) * Rad_IK;
      if (pos_x <= dimx) and (pos_y <= dimy) then
      // Solange der Punkt sich nicht außerhalb der Berechnungsfläche befindet
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      { Wenn Wurzeln sich nicht mehr im Beobachtungsfenster befinden, bedeutet bei
        reihenweiser Befüllung, den Fall, dass sich Pos. in Y-Richtung ausserhalb der
        Beobachtungsfläche befindet }
      if (pos_y > dimy) then
      begin
        Inc(errorRoot);
      end;
      Inc(j);
      Inc(i);
      if pos_x > dimx then
      // Am Ende der Reihe: Wechsel in den Ast für ungerade Reihen.
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
  BESCHREIBUNG:
  Verteilung mit Hilfe von Sechsecken. Es werden dabei nacheinander SPALTEN gefüllt.
  Die Methode könnte dann vorteilhaft sein, solange Nährstoffaufnahme in SCHICHTEN
  berechnet werden soll (dies muss aber noch verifiziert werden.
  Die Verteilung wurde angepasst: X-Werte wurden um einen halben Rad_Ak nach rechts
  und die y-Werte um einen halben Rad_Ak nach oben verschoben (vgl. Folie Füllen
  von Spalten 2
  CAVE: Methode nicht upToDate muss noch nach  Vorbild von distributeHexagonRow
  verbessert werden (z.B. Berechnung ErrorReg).
  ------------------------------------------------------------------------------ *)
var
  { Für die Berechnung der Verteilung werden folgende Radii benötigt. Innen- und
    Außenkreis beziehen sich auf das regelmäßige Sechseck, in dessen Zentrum sich
    die Wurzel befindet. }
  AreaObservation, // Fläche des Beobachtungsfensters
  Rad_IK, // Radius Innenkreis Sechseck
  Rad_AK, // Radius Außenkreis Sechseck
  Area_Polygon, // Fläche Sechseck
  pos_x, // Position der Senke in x-Richtung
  pos_y, // Position der Senke in y-Richtung
  dimx, // Grenze der Berechnungsfläche in x-Richtung
  dimy, // Grenze der Berechnungsfläche in y-Richtung
  angel, // 60° im Bogenmaß
  stretch, // Strecke mit Länge (2xRad_AK - Kante)/2 (vgl. Folie Gleichverteilung
  { Kantenlänge 6-Eck, entspricht eigentlich Rad_Ak, wurde aus Gründen der Anschau-
    lichkeit beibehalten. }
  edgeHexagon: real;
  i, j, number_col: integer;
begin
  inherited;
  AreaObservation := dimensionX.v * dimensionY.v;
  { Berechnung des Flächeninhalts, der einem Sechseck zugeordnet werden soll: }
  Area_Polygon := AreaObservation / num_roots.v;
  // Umrechung von Gradmaß ins Bogenmaß, vgl. Mathehandbuch S. 336
  { Winkel im Bogenmaß=Winkel im Gradmaß/360*2Pi }
  angel := 60 / 360 * (2 * Pi);
  // Vgl. Geometriehandbuch
  Rad_AK := sqrt(Area_Polygon / (3 * sin(angel)));
  // alternative Formel: Rad_AK:=sqrt(2/3*(Area_Polygon/sqrt(3)));
  // Radius Innenkreis entspricht Höhe im Teildreieck, Vgl. Geometriehandbuch
  Rad_IK := (Rad_AK / 2) * sqrt(3);
  // Kantenlänge Sechseck entspricht dem Radius des Außenkreises
  edgeHexagon := Rad_AK;
  stretch := Rad_AK / 2;
  { Man könnte auch wegen Anschaulichkeit folgendes schreiben:
    stretch:=(2*Rad_Ak-edgeHexagon)/2 }
  dimx := self.dimensionX.v;
  dimy := self.dimensionY.v;
  // Füllen des Pos_Arrays:
  RasterData.errasePosArr; // Löschen alter Einträge. Problem: notwendig???
  // number_col:=1;           //Start bei Spalte 1
  number_col := 0; // Start bei Spalte 0
  j := 0;
  { Cave: PosArr beginnt bei 1 }
  i := 1;
  while i <= trunc(num_roots.v) do
  begin
    if (number_col mod 2 <> 0) then // ungerade Spalten
    begin
      // Berechnung ungerader Spalten:
      pos_y := ((j * 2 + 1) * Rad_AK + j * edgeHexagon);
      pos_x := (number_col) * Rad_IK;
      // X-Werte: verschieben um Rad_Ak/2 nach rechts
      pos_x := pos_x + Rad_AK / 2;
      // y-Werte: verschieben um Rad_Ak/2 nach oben
      pos_y := pos_y - Rad_AK / 2;
      // Solange der Punkt sich nicht außerhalb der Berechnungsfläche befindet
      if (pos_x <= dimx) and (pos_y <= dimy) then
      begin
        RasterData.PosArr[i].x := pos_x;
        RasterData.PosArr[i].y := pos_y;
        RasterData.PosArr[i].root := i;
        { Es wird davon ausgegangen, dass die Fläche des Sechsecks der Fläche des Voronoi-
          Polygons entspricht. Die Punkte innerhalb der Grenzen des Polygons wären dann
          die Punkte, die zur Senke im Mittelpunkt einen kleineren Abstand haben als zu
          allen anderen vorhandenen Senken. }
        RasterData.PosArr[i].area := Area_Polygon;
      end;
      Inc(j);
      Inc(i);
      if pos_y > dimy then
      // Am Ende der Reihe: Wechsel in den Ast für gerade Spalten.
      begin
        j := 0;
        dec(i); // Schritt zurück
        Inc(number_col);
      end;
    end;
    if (number_col mod 2 = 0) then // gerade Spalten
    // Berechnung gerader Spalten:
    begin
      pos_y := stretch + (j + 1) * edgeHexagon + (j * 2 + 1) * Rad_AK;
      pos_x := Rad_IK * number_col;
      // X-Werte: verschieben um Rad_Ak/2 nach rechts
      pos_x := pos_x + Rad_AK / 2;
      // y-Werte: verschieben um Rad_Ak/2 nach oben
      pos_y := pos_y - Rad_AK / 2;
      // Solange der Punkt sich nicht außerhalb der Berechnungsfläche befindet
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
      // Am Ende der Reihe: Wechsel in den Ast für ungerade Spalten.
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
  BESCHREIBUNG:
  Berechnet die Anzahl der gültigen Wurzeln (befinden sich auf dem Beobachtungs-
  fenster, aber nicht in den Rändern)
  ------------------------------------------------------------------------------ *)
var
  rootcount, i: integer;
begin
  rootcount := 0;
  number_consid_roots.v := 0;
  // number_consid_roots.V:=RasterData.NRoots; //Zunächst alle Wurzeln akzeptiert.
  { Bestimmen der Anzahl zu berücksichtigender Wurzeln (für das Festsetzen von
    Arraygrenzen. Die eingegeb. Parameter für die Ränder sind relative Werte, die
    noch in Beziehung zum Beobachtungsfenster dimensionX, dimensionY gesetzt werden. }
  for i := 1 to RasterData.NRoots do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= dimensionY.v - horizMargin.v) then
    begin
      Inc(rootcount);
      number_consid_roots.v := rootcount;
    end;
  end;
  // Debuggen
  // showMessage(self.SubModName+': '+floatToStr(number_consid_roots.V));
end;

function TSubmodRootDiff.Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): extended;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rückgabewert ist die berechnete N-Menge [kgN/ha], die Funktion
  leistet also die Umrechnung aus der vorhandenen Konzentration (aggregierte Werte)
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000; { Molgewicht Stickstoff }
var
  volumen_cm3, { Volumen von Bodenschicht auf Fläche von 1ha }
  cm3_ha, n_menge: extended;
begin
  volumen_cm3 := Tiefe.v * 1E8;
  cm3_ha := theta * volumen_cm3; { Wassergehalt in einem Hektar }
  n_menge := Cli_mol_cm3 * kg_mol * cm3_ha;
  Result := n_menge;
end;

function TSubmodRootDiff.Cl_func(Tiefe_cm, theta, NMenge: real): extended;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rückgabewert ist die Konzentration [Mol N/cm^3]
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000; { Molgewicht Stickstoff }
var
  volumen_cm3, { Volumen von Bodenschicht auf Fläche von 1ha }
  cm3_ha, Cli_mol_cm3: extended;

begin
  volumen_cm3 := Tiefe.v * 1E8;
  cm3_ha := theta * volumen_cm3; { Wassergehalt in einem Hektar }
  Cli_mol_cm3 := NMenge / (kg_mol * cm3_ha);
  Result := Cli_mol_cm3;
end;

procedure TSubmodRootDiff.removeMarginRoots;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  Entfernt randständige Wurzeln aus dem Pos-Array
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  { dynamisches Array, welches temporär die Wurzeln aufnimmt, die nicht in den
    Ränder liegen. }
  PosArr_middle: Array of TPointDoubleType;
begin
  // Rausschmiss 'ungültiger Wurzeln'
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  j := 0;
  // Füllen von PosArr_middle
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= dimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
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
  // Löschen des alten PosArr
  RasterData.errasePosArr;
  j := 1;
  // Rückschreiben der Werte aus dem temporären PosArr.
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
