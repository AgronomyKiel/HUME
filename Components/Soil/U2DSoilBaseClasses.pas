/// <summary>
///   defines some base classes for 2 dimensional water and nitrate transport equations
/// </summary>

unit U2DSoilBaseClasses;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid, MathImge,
  UMod, UState, URootObject, Diffko, SubmodRootStructureNew,
  URootUptakeFunctions;



//const
  /// <summary>Maximum number of roots.</summary>
//  max_num_roots = 40000;

type

 /// <summary>re defines a floating point type for MathImage</summary>
  MathFloat = double;
  // Type declarations
  Pdouble = ^double; // Pointer type to double, for use in lists
/// <summary>re defines a floating point type</summary>
  real = double;
  // Arrays
  r2 = array [0 .. 1] of double; // Vektor im Punktraum


const
  /// <summary>largest index, required for the vectors during the flux calculation</summary>
  dim_max = 10000;


/// <summary>Color array for concentration display</summary>
colorarray: array [0 .. 11] of TColor = ($00CB9F74, $00D8AD49, $00E6C986,
    $00F2E3C1, $00DAF0C4, $00A6E089, $0086D560, $0065CFB5, $008DC5FC, $0075D5FD,
    $0078E1ED, $00ACEDF4);

type
  /// <summary>Problem: the dynamic implementation was removed again due to difficulties with array boundaries.</summary>
  array_type = array [0 .. dim_max + 1] of real;

//  forward declaration of class TBaseSubmodRootDiff
  TSubmodRootBase2D = class;

  /// <summary>
  /// Declaration of class TRasterData. This class encapsulates the raster,
  /// positions and the number of read and randomized data (WAP). It enables
  /// display in the tabs RasterData and RootDistribution. The class also
  /// handles file access.
  /// </summary>
  TRasterData = class(TObject)
  private

  /// <summary>
  ///   private field for defining a vertical margin of the
  ///  computational grid [cm]
  /// </summary>
  fverticMargin: real;

  /// <summary>
  ///   private field for defining a horitzonal margin of the
  ///  computational grid [cm]
  /// </summary>

  fhorizMargin : real;

  fDimensionX : real;
  fDimensionY : real;
  fdim_xMiddle : real;
  fdim_yMiddle : real;
  fAreaMiddle  : real;

  /// <summary>
  ///   effective Diffusion coefficient
  /// </summary>
  fDe : real;

  /// <summary>
  ///   field for container dimension [cm]
  /// </summary>
  fContRad: real;

  fWriteSinkCells : boolean;
  fSinkCellFileName : string;


  protected
    /// <summary>Protected declarations</summary>
    ///
    ///
  ndim_xMiddle : integer;
  ndim_yMiddle : integer;

  number_consid_roots : integer;

  public
    { Public declarations }
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

    /// <summary>Height of Columns [cm]</summary>
    ColWidth: double;

    /// <summary>Width of rows [cm]</summary>
    RowHeight: double;

    /// <summary> contains the x and y coordinates of the center of the container in container mode</summary>
    contposx: real;

    contposy: real;

/// <summary>
///   In x_arr and y_arr are the 'midpoint coordinates of the grid cells'
/// </summary>
    x_arr, y_arr: array of double;


    /// <summary>
    /// Root numbers in the raster (computational) cells.
    /// There can be more than one root per cell
    /// The array is needed for
    /// reading and displaying the number of roots in grid cells
    /// </summary>
    CountArr: array of array of integer;

/// <summary> C_xy: array for concentrations/volumetric water contents in the computational elements.
/// C_xy is declared as a dynamic array because the size of
///      the array should be declared with values of dim_x and dim_y (number of
///      computational elements in the x and y directions) that are assigned later.
/// </summary>
    C_xy: array of array of double;


    /// <summary> Stores information on all roots in the form of TRootObjectIn2D entries</summary>
    RootList: TStringList;

    /// <summary> Reference to the diffusion submodel the raster data object belongs to</summary>
    SubmodRootDiff: TSubmodRootBase2D;

    /// <summary>Constructor</summary>
    constructor create(Submodel: TSubmodRootBase2D);

    procedure init(NCols, NRows:word;
                           ColWidth, RowWidth,
                           verticMargin, horizMargin, ContRad,
                           C_Start:real);

    procedure ExtractMiddle;

    /// <summary>Reads aggregated raster data and generates random positions</summary>
    procedure readRasterData(fn: string; var Series: TPointSeries);

    /// <summary>Reads exact XY coordinates from a file</summary>
    procedure readXYfromFile(Filename: TFilename;
      var Series: TPointSeries); virtual;

    /// <summary>Saves generated root coordinates to a file</summary>
    procedure saveRootPositions(SaveDialog: TSaveDialog);

    /// <summary>Distributes roots evenly across the grid</summary>
    procedure CalcEqualDistribution(RLD:real);

    /// <summary>Distributes roots in a hexagonal pattern</summary>
    procedure distributeHexagonRow;

    /// <summary>Distributes roots in a hexagonal pattern</summary>
    procedure distributeHexagonCol;

    /// <summary>Writes output to a file</summary>
    procedure WriteOutputToFile(fn:string; Time:real); virtual;

    /// <summary>Removes roots that are in the margins</summary>
    procedure removeMarginRoots;

    procedure CalcRandomRootPositions;

    /// <summary>Calculates the grid cell indices for each root position</summary>
    procedure CalcRootPosAsIndex;

    /// <summary>Tests if roots are located within the border</summary>
    procedure testForContBorder(var start_, ende_: integer;
                 x_ndx, y_ndx: integer; zeile: boolean);

      function calcAbsValue2D(vect: r2): double;
    function vectorSubtrakt2D(vect2, vect1: r2): r2;
    procedure zweid_solut(dt_globmod: real);


  published

  end; { Ende Deklaration TRasterData }


  TRasterDataH2ON = class(TRasterData)
  private


  protected
  public

  published
  end;


  TRasterDataNO3 = class(TRasterData)
  private
  protected
  public
  published
  end;



/// <summary>Declaration of class TBaseSubmodRootDiff. Base class for derived 2d and 1d diffusion models
///  applied to a soil layer with roots
/// Functionality of the base class: all models can read raster data, exclude
/// margins from calculations and display the data in the appropriate tabs of the
/// Hume form. The 1D models does not output in the 3D plot tab.
/// derived model simulate 2D water and nitrogen transport
///  or apply for comparison 1D approaches to the same problem
///  </summary>
  TSubmodRootBase = class(TSubmodel)
  private

  protected

    /// <summary>
    ///  sum of internal time steps
    /// </summary>
    SumOfInternalTimeSteps: double;

    /// <summary>Indicates whether initialization has already occurred</summary>
    initialised: boolean;
    hasWritten: boolean;

  public

    /// <summary>
    ///   initial time step [d]
    /// </summary>
    ini_dt: TPar;

    /// <summary>Maximum time step width [d]</summary>
    max_dt: TPar;

    /// <summary> Area of the whole soil section of interest [cm2]
    ///  is handled as a constant
    /// </summary>
    Area: TVar;


    /// <summary> Initial volumetric water content [cm3/cm3]</summary>
    IniTheta: TPar;

    /// <summary>radius of the container in container mode</summary>
    ContRad: TPar;

    /// <summary>Depth of the layer [cm], assumption for mineralization calculation</summary>
    /// <remarks>Mineralization model not yet available but should be implemented for both models</remarks>
    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>
    /// <summary>Vertical margin [cm]</summary>
    Depth: TPar;

    /// <summary>Mean root length density [cm/ccm]</summary>
    ParMRLD: TPar;

    /// <summary>average Radius of the roots [cm]</summary>
    RootRadius: TPar;

    /// <summary>Mean root length density in a layer [cm/cm^3] calculated without roots located in the margins</summary>
    RLD_mean: TVar;

    /// <summary>Number of roots in center and margins [n]</summary>
    num_roots: TVar;

    /// <summary>Volume of the soil layer including margins [cm3]</summary>
    Volume: TVar;

    /// <summary>actual volumetric water content [cm3/cm3]</summary>
    theta: TVar;

    /// <summary>internal time step [d]</summary>
    int_dt: TVar;

    /// <summary>
    ///   root length per hectar [cm/ha]
    /// </summary>
    wl_ha: TVar;

    /// <summary>
    ///   root length per hectar
    /// </summary>
    wl: TVar;

    /// <summary>
    ///   Amount of water in the object [cm3]
    /// </summary>
    WAmount: TState;

    /// <summary>
    ///   Average distance between roots [cm]
    /// </summary>
    AvDistance: TVar;


        /// <summary> Potential N uptake rate [Kg N/ha*d]</summary>
    NUptakeratepot: TPar;

    /// <summary>Mineralization rate [kg N/ha*d]</summary>
    NMinerRate_kgNha: TPar;

    /// <summary>Minimum soil solution concentration [g N/l], also needed for the numerical solution in the 1D model; note: originally in micromol/l</summary>
    Clmin: TPar;

    /// <summary>Michaelis-Menten constant [mol/cm3]</summary>
    Km: TPar;

    /// <summary>
    ///   initial soil nitrate [kg N/ha]
    /// </summary>
    IniSoilNitrate: TPar;

    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>

    /// <summary>Member HUME base class TState (state variables)</summary>
    /// <summary>N amount [kg N/ha], also basis for calculating concentrations in the calculation elements; see Kage dissertation p.79 where concentrations of 10.0 micromol/l were assumed</summary>
    NAmount: TState;

    /// <summary>Cumulative amount of N taken up by the roots [kg N/ha] for the specified depth</summary>
    SumNUptake: TState;

    /// <summary>Mineralization rate [Mol/cm^3*d]</summary>
    Min_S: TVar;

    /// <summary>Initial concentration [kg N/cm], calculated from the initial N amount; the 1D model can also calculate concentrations</summary>
    c_start: TVar;

    /// <summary>Average concentration in the soil solution [kg N/cm]</summary>
    cl_av: TVar;

    /// <summary>
    /// average Concentration [mol/cm3]
    /// </summary>
    c_av: TVar;

   /// <summary>maximum influx [g N/cm*d]</summary>
   Imax: TVar;

   ActArFromConc : TVar;

   ActAr : TVar;

    /// <summary>
    ///   Potential N Influx rate [mol/cm/d]
    /// </summary>
    PotentialNInfluxrate : TVar;

    /// <summary>
    ///   effective Diffusion coefficient [cm2/d]
    /// </summary>
    De : TVar;

    /// <summary>
    ///   Diffusion coefficient of nitrate in water [cm2/d]
    /// </summary>
    Dl : TVar;

    /// <summary>Type of uptake calculation</summary>
    NitrateUptakeFunction: TOption;

    /// <summary> create all objects</summary>
    procedure createAll; override;
//    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobModReferenz: TMod); override;



    /// <summary>Initializes the submodel</summary>
    procedure init(var GlobMod: TMod); override;
    // Set and get methods

  published
    /// <summary>Published declarations</summary>
    // Publication of properties in the object inspector.

  end; { Ende Deklaration TSubmodRootDiff }


  TSubmodRootBase2D = class(TSubmodRootBase)
  private

  protected


   /// <summary>RasterData instance owned by the submodel</summary>
    RasterData: TRasterData;

    /// <summary>Protected declarations</summary>
    /// <summary>
    ///   a private field for showing the concentration field on a TMathimage object
    /// </summary>
    fMyMathImage: TMathImage;

    /// <summary>
    /// Reference to the chart in the Hume form for displaying the root distribution
    /// </summary>
    fMyChart: TChart;

    /// <summary>
    ///   the codings for the concentration in colours
    /// </summary>
    ColorSurface: TColorSurface;

    /// <summary>Reference to the AdvStringGrid in the Hume form for displaying raster data</summary>
    fMyAdvStringGrid: TAdvStringGrid;

    /// <summary>Reference to the structural root model</summary>
    fMyStructModel: TSubmodRootStrucNew;


    /// <summary>Field stores whether the output file for sink influx per cell has been created.
    /// This should be done anew before each model run -> SinkCellFileWasCreated is set to false in init.
    /// In CalcRates the file is created once and the flag is set to true</summary>
    SinkCellFileWasCreated: boolean;

    /// <summary>Field stores whether the output file for sink influx has been created. This should be done anew before each model run -> FileWasCreated is set to false in init. In CalcRates the file is created once and the flag is set to true</summary>
    FileWasCreated: boolean;

    /// <summary>volume of a computational element [cm3]</summary>
    vol_Element,

    /// <summary>water amount of a computational element [cm3]</summary>
    wm,
    /// <summary>minimum concentration in the grid [mol/cm3]</summary>
    min_c,
    /// <summary>maximum concentration in the grid</summary>
    max_c
      : double;



    /// <summary> text file for writing xy data </summary>
    xyfile: textfile;

    /// <summary> Object for displaying the root intersection points in the Hume form TChart object </summary>
    SeriesXY: TPointSeries;


  public
    /// <summary>Public declarations</summary>


    /// <summary>Width of the computational domain [cm]</summary>
    dimensionX: TPar;
    /// <summary>Height of the computational domain [cm]</summary>
    dimensionY: TPar;

    /// <summary>Central area without margins [cm2]</summary>
    AreaMiddle: TVar;

    /// <summary>Width of the raster grid (aggregated data) in x-direction [cm]</summary>
    gridWidth: TPar;

    /// <summary>Width of the raster grid (aggregated data) in y-direction [cm]</summary>
    gridHeight: TPar;

    /// <summary>number of elements in X-direction</summary>
    dim_x: TPar;

    /// <summary>number of elements in Y-direction</summary>
    dim_y:TPar;

    /// <summary>Vertical margin [cm]</summary>
    verticMargin: TPar;

    /// <summary>Horizontal margin [cm]</summary>
    horizMargin: TPar;

    /// <summary>grid width in X-direction [cm]</summary>
    dx: TVar;

/// <summary>grid width in Y-direction [cm]</summary>
    dy: TVar;

    /// <summary>Number of roots not located in margins []</summary>
    number_consid_roots: TVar;

    /// <summary>Measure of error for regular distribution = number of roots that do not fit into the observation window when generating the uniform distribution, as a percentage of all roots [%]</summary>
    errorReg: TVar;


    /// <summary>Number of elements in the middle area in X-direction</summary>
    dim_xMiddle: TVar; { Zahl der MITTIGEN Elemente in X-Richtung }

    /// <summary>Number of elements in the middle area in Y-direction</summary>
    dim_yMiddle: TVar; { Zahl der MITTIGEN Elemente in Y-Richtung }

    /// <summary>Option for Type of initialization, e.g. file or structural model</summary>
    IniMethod: TOption;

    /// <summary>Path and name of the init file with XY root data</summary>
    RootInpDataFileXY: TOption;

    /// <summary>Path and name of the init file with root data as counts in a grid</summary>
    RootInpDataFile: TOption;

    /// <summary>Specify whether XY data should be written to a file</summary>
    OutputXY: TOption;

    /// <summary>
    ///   Option to remove root position which are too near to the border
    ///  of the calculation field in the 2D case
    /// </summary>
    WithMargins: TOption;

    /// <summary>Path and name of the output file for XY data</summary>
    RootXYOutpDataFile: TOption;

    /// <summary>Option for the type of root distribution
    /// distinct from the 1D model
    /// Options are 'Random', i.e. a random distribution of root exit points
    /// 'Regular', i.e. a regular grid distribution
    /// 'FromSource', i.e. a distribution based on source data
    /// </summary>
    RootDistribution: TOption;


    /// <summary>Fills the chart with root distribution data</summary>
    procedure fillChartRootDistr;

    /// <summary>Fills the AdvStringGrid with aggregated raster data</summary>
    procedure fillGridRasterData;


    /// <summary>Returns the RasterData instance</summary>
    function getRasterData: TRasterData;


    procedure createAll; override;

   /// <summary>Performs various initializations</summary>
   procedure init(var GlobMod: TMod); override;


  published

      /// <summary>Property for accessing the TChart object in the Hume form</summary>
    property MyChart: TChart read fMyChart write fMyChart;

    property MyMathImage: TMathImage read fMyMathImage write fMyMathImage;


    /// <summary>Property for accessing the TAdvStringGrid object in the Hume form</summary>
    property MyAdvStringGrid: TAdvStringGrid read fMyAdvStringGrid
      write fMyAdvStringGrid;

    /// <summary>Property for accessing the TSubmodRootStrucNew object in the Hume form</summary>
    property MyStructModel: TSubmodRootStrucNew read fMyStructModel
      write fMyStructModel;



end;

  /// <summary>Function for calculating mineralisation rate </summary>
  function Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): real;

  /// <summary>Function for calculating nitrate concentration </summary>
  function Cl_func(Tiefe_cm, theta, NMenge: real): real;



implementation

{$I trdiag.pas}


/// <summary>
/// Implementation of the methods of TRasterData
/// </summary>
constructor TRasterData.create(Submodel: TSubmodRootBase2D);
var
  i: integer;
begin
  { The RasterData instance knows its submodel }
  SubmodRootDiff := Submodel;
  RootList := TStringlist.create;
  contposx := 50; // not yet clear why this value has to be 50
  contposy := 50;

end;


/// <summary>
/// Initializes the raster data
/// </summary>
/// <param name="NCols">Number of columns</param>
/// <param name="NRows">Number of rows</param>
/// <param name="ColWidth">Column width [cm]</param>
/// <param name="RowWidth">Row width [cm]</param>
/// <param name="verticMargin">Vertical margin [cm]</param>
/// <param name="horizMargin">Horizontal margin [cm]</param>
/// <param name="C_Start">Initial concentration in the grid [mol/cm3]</param>
procedure TRasterData.init(NCols, NRows:word;
                           ColWidth, RowWidth,
                           verticMargin, horizMargin, ContRad,
                           C_Start:real);

var
  i, j: word;

begin
// Initialize the raster data
  self.NCols := NCols;
  self.NRows := NRows;
  self.ColWidth := ColWidth;
  self.RowHeight := RowWidth;
  self.fContRad := ContRad;

// set the dimensions of the computational domain
  setLength(x_arr, NCols);
  setLength(y_arr, NRows);
// set the dimensions of the two dimensional CountArr
  setLength(CountArr, NCols);
  for i := 0 to NCols-1 do
  begin
    setLength(CountArr[i], NRows);
  end;

// set the midpoint coordinates of the grid cells
  for i := 0 to NCols - 1 do
    x_arr[i] := (i + 0.5) * ColWidth;
  for j := 0 to NRows - 1 do
    y_arr[j] := (j + 0.5) * RowWidth;

// set the dimensions of the two dimensional C_xy array
  setLength(C_xy, NCols);
  for i := 0 to NCols - 1 do
    setLength(C_xy[i], NRows);

// initialize C_xy with the start concentration
  for i := 0 to NCols - 1 do
    for j := 0 to NRows - 1 do
      C_xy[i, j] := C_Start;

// set the dimensions of the computational domain
  fDimensionX := ColWidth*NCols;
  fDimensionY := RowHeight*NRows;
// initialize margins
  fverticMargin := verticMargin;
  fhorizMargin := horizMargin;

end;



/// <summary>
/// Reads aggregated raster data (root counts) which are then used to randomly
/// determine coordinate points. Example of functionality: readln(f, Ncols)
/// assigns the value read from f to the variable Ncols.
/// </summary>
procedure TRasterData.readRasterData(fn: string; var Series: TPointSeries);
var
  F: TextFile; { File variable for text files }
  S: string;
  i, Row, Col, root, AllRoot: integer;
  NewRoot : TRootObjectIn2D;

begin
  RootList.Clear;
  AssignFile(F, fn); { File selected }
  Reset(F);
  // Read the header
  Readln(F, S); { Read and discard first line of the file (header) }
  DescStr := S; { -> DescStr: description of the data set }
  Readln(F, S);
  Date := StrToFloat(S); { Second line: date (TDateTime format) }
  Readln(F, NRows); { Third line: number of rows }
  Readln(F, NCols); { Fourth line: number of columns }
  Readln(F, RowHeight); { Fifth line: row height [cm] }
  Readln(F, ColWidth); { Sixth line: column width [cm] }

  setLength(CountArr, Integer(NCols));
  for i := 0 to NCols - 1 do
  begin
    setLength(CountArr[i], Integer(NRows));
  end;

  // Repeatedly read data until end of file
  for Row := 0 to NRows - 1 do
  begin { Read root counts into CountArr }
    for Col := 0 to NCols - 1 do
      read(F, CountArr[Col, Row]);
    Readln(F); // New line
  end;
  closeFile(F);
  AllRoot := 0; // Start at 0 because PosArr begins at 0.
  { Randomly distribute roots in each grid cell }
  for Col := 0 to NCols - 1 do
  begin
    for Row := 0 to NRows - 1 do
    begin
      { Exactly as many roots are assigned to PosArr as were read into CountArr. }
      for root := 0 to CountArr[Col, Row]-1 do
      begin
        NewRoot := TRootObjectIn2D.create;
        // randomize;     // [What does Randomize do?]
        NewRoot.x := (Col) * ColWidth + Random * ColWidth;
        NewRoot.y := (Row) * RowHeight + Random * RowHeight;
        NewRoot.nroot := root;
//        PosArr[AllRoot].root := AllRoot;
        self.RootList.AddObject(IntToStr(AllRoot), NewRoot);
        Series.AddXY(NewRoot.x, NewRoot.y);
        Inc(AllRoot);
      end;
    end;
  end;
  { The model and the RasterData object know the total number of roots }
  TSubmodRootBase(SubmodRootDiff).num_roots.v := AllRoot;
  self.NRoots := AllRoot;

end;

/// <summary>
/// Reads XY coordinates from a file and successively fills the passed
/// (call-by-reference) PointSeries object with the XY pairs.
/// </summary>
procedure TRasterData.readXYfromFile(Filename: TFilename;
  var Series: TPointSeries);
var
  // File variable for text files
  F: TextFile;
  s_header,
  { Variable needed because some values in a text line must be skipped
    (see file format) }
  restString: String;
  { pos_delimiter stores the position of the last delimiter in the string }
  pos_delimiter: integer;
  NewRoot : TRootObjectIn2D;
  i: integer;


begin
  self.RootList.Clear;
//  ErasePosList;
  // Issue: Is the clearing step needed (see called method)?
  // Read data from file:
  try
    AssignFile(F, Filename); // Link file variable to file
    Reset(F); // Read access
    // Read header and discard
    Readln(F, s_header);
    // Read the actual data
    i := 0; // PosArr starts at 0
    { Issue: may need to start at 1 to obtain correct root counts }
    NRoots := 0;
    { Defining bounds of PosArr; could be used if PosArr were implemented as a
      dynamic array }
    while not Eof(F) do
    begin
      Readln(F, restString);
      Inc(NRoots);
    end;
    self.SubmodRootDiff.num_roots.v := NRoots;
    self.SubmodRootDiff.RasterData.NRoots := NRoots;

    Reset(F); // Reset file pointer to beginning
    // Read the header and discard it
    Readln(F, s_header);
    NRoots := 0;
    while not Eof(F) do
    begin
      NewRoot := TRootObjectIn2D.create;
      Readln(F, NewRoot.x, NewRoot.y, NewRoot.nroot,
        restString);
      // Remove trailing whitespace:
      restString := TrimRight(restString);
      { Determine position of last delimiter in string }
      pos_delimiter := LastDelimiter(#9, restString); // #9 is tab
      // Remove leading part of string up to last delimiter:
      Delete(restString, 1, pos_delimiter);

      NewRoot.area := StrToFloat(restString);
      { As in the 2D model, all WAP must also be considered in the 1D model so that a
        suitable surface area of the Voronoi polygon can be calculated. In the 2D model
        only the uptake of sinks not located in the margins is later considered; in the
        1D model only coordinates not in the margins are used for calculating the
        parameters of the lognormal distribution function. }

      self.RootList.AddObject(intToStr(i), NewRoot);
     Series.AddXY(NewRoot.x, NewRoot.y);
      Inc(i);
      inc(NRoots);
    end;
    // Submodel knows the number of roots

    { Due to a root at 0/0. The position of this root is obviously incorrect }
    // ShowMessage(FloatToStr(RasterData.PosArr[1].x));
  except
    ShowMessage('Error accessing file');
  end;
  closeFile(F);
end;

/// <summary>
/// After reading aggregated root data, i.e. without exact coordinates, saves the generated random root
/// coordinates (considering assignment to a 5x5 cm grid cell) as floating point
/// numbers in a file.
/// </summary>
procedure TRasterData.saveRootPositions(SaveDialog: TSaveDialog);
var
  F: TextFile;
  root: integer;
  ActRoot : TRootObjectIn2D;
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
    for root := 0 to self.RootList.Count -1 do
      ActRoot := TRootObjectIn2D(self.RootList.Objects[root]);
      writeln(F, ActRoot.x, ' ', ActRoot.y, ' ', root, ' e a 0');
    closeFile(F);
  end;
end;

/// <summary>Set and get methods for TRasterData</summary>

/// <summary>TRasterData Ende</summary>

/// <summary>Implementierung TSubmodRootDiff</summary>
/// <summary>
/// Creates and initializes state variables, variables and parameters. The first
/// parameter of the function call passes a string identical to the identifier and
/// can be searched for. The second parameter contains a string indicating the
/// unit used ([-] for dimensionless parameters, etc.). The third parameter is the
/// actual floating-point value. For an explanation of the identifiers, see the
/// declaration.
/// </summary>
procedure TSubmodRootBase.createAll;
begin
  inherited createAll;
  initialised := false;
  ParCreate('Ini_dt', '[d]', 1/240, Ini_dt, 'initial time step');
  ParCreate('max_dt', '[d]', 1/240, max_dt, 'maximum time step');
  ParCreate('IniTheta', '[cm3/cm3]', 0.2, IniTheta, 'initial volumetric water content');
  ParCreate('Depth', '[cm]', 10, Depth, 'depth of the layer');
  { Note: the original value was in micromol/l }
  ParCreate('ParMRLD', '[cm/ccm]', 0, ParMRLD, 'mean root length density');
  ParCreate('RootRadius', '[cm]', 0, RootRadius, 'root radius');
  ParCreate('ContRad', '[cm]', 10, ContRad, 'radius of the container in container mode');
  // Create and initialize TState

  VarCreate('RLD_mean', '[cm/cm^3]', 0, false, RLD_mean,
    'mean root length density in a layer');
  VarCreate('num_roots', '[-]', 0, false, num_roots, 'number of roots in center and margins');
  VarCreate('theta', '[cm3/cm3]', 0, false, theta, 'actual volumetric water content');
  VarCreate('int_dt', '[d]', 0, false, int_dt, 'internal time step');
  VarCreate('wl_ha', '[cm/ha]', 0, false, wl_ha, 'root length per hectar');
  VarCreate('Wl', '[cm/ha]', 0, false, Wl, 'root length per hectar');
  VarCreate('AvDistance', 'cm', 0, false, AvDistance, 'Average distance between roots');

  StateCreate('WAmount', '[cm3]', 0, false, WAmount, 'Amount of water in soil object');

  ConstCreate('Area', '[cm²]', 0, false, Area, 'Area of the container');
  ConstCreate('Volume', '[cm/m³]', 0, false, Volume, 'Volume of the container');

    ParCreate('Ar', '[kg N/ha*d]', 0, NUptakeratepot, 'Potential nitrate uptake rate');
  ParCreate('Minera', '[kg N/ha*d]', 0, NMinerRate_kgNha, 'Mineralization rate');
  ParCreate('Clmin', '[mol/l]', 0, Clmin, 'Minimum concentration');
  ParCreate('Km', '[mikromol/l]', 0, Km, 'Half-saturation concentration');
  ParCreate('iniSoilNitrate', '[kg N/ha]', 30, iniSoilNitrate, 'Initial nitrate amount in soil');

  // Create and initialize TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 30, false, NAmount,
    'N amount in the soil');
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, SumNUptake,
    'Cumulative N amount taken up by roots');
  // Create and initialize TVar
  { Caveat: variables are always initialized to 0. If a start value other than 0 is
    needed, calculation and assignment must occur in init. It would be better not to
    declare such variables as TVar. }

  VarCreate('Min_s', '[Mol/cm^3*d]', 0, false, Min_S, 'Mineralization rate in mol/cm3*s');
  VarCreate('c_start', '[Mol/cm^3]', 1e-5, false, c_start, 'Initial concentration');
  VarCreate('cl_av', '[Mol/cm^3]', 0, false, cl_av, 'Average concentration');
  VarCreate('Imax', '[mol/cm/d]', 0, false, Imax, 'Maximum influx rate');

  VarCreate('ActArFromConc', '[mol/cm/d]', 0, false, ActArFromConc, 'Actual uptake rate calculated from concentration');
  VarCreate('ActAr', '[mol/cm/d]', 0, false, ActAr, 'Actual uptake rate');
  VarCreate('C_av', '[mol/cm3]', 0, false, C_av, 'Average concentration');
  VarCreate('De', '[cm2/d]',  D0NO3*0.2*0.2*3.35, false, De, 'effective nitrate diffusion coefficient');
  ConstCreate('Dl', '[cm2/d]',  D0NO3, false, Dl, 'nitrate diffusion coefficient in water');

  // Create and initialize TOption
  { Specify the source of the root data }
  { Define uptake function }
  OptCreate('NitrateUptake_function', 'ZeroSink', NitrateUptakeFunction,
    'Defines the nitrate uptake function');
  NitrateUptakeFunction.OptionList.add('ZeroSink');
  NitrateUptakeFunction.OptionList.add('ConstInflux');
  NitrateUptakeFunction.OptionList.add('MM');


end;


procedure TSubmodRootBase2D.createAll;

begin
  inherited createAll;
  RasterData := TRasterData.create(self);
  // Create and initialize TPar
  ParCreate('dimensionX', '[cm]', 100, dimensionX, 'width of the area in x direction');
  ParCreate('dimensionY', '[cm]', 100, dimensionY, 'height of the area in y direction');
  ParCreate('gridWidth', '[cm]', 5, gridWidth, 'width of the grid cells');
  ParCreate('gridHeight', '[cm]', 5, gridHeight, 'height of the grid cells');

  ParCreate('verticMargin', '[cm]', 0, verticMargin, 'vertical margin');
  ParCreate('horizMargin', '[cm]', 0, horizMargin, 'horizontal margin');
  ParCreate('dim_x', '[n]', 500, dim_x, 'dimension in x direction');
  ParCreate('dim_y', '[n]', 500, dim_y, 'dimension in y direction');
  ParCreate('ContRad', '[cm]', 10, ContRad, 'radius of the container in container mode');
  // Create and initialize TState

  VarCreate('dx', '[cm]', 0, false, dx, 'grid width in X-direction');
  VarCreate('dy', '[cm]', 0, false, dy, 'grid width in Y-direction');
  VarCreate('AreaMiddle', '[cm2]', 0, false, AreaMiddle, 'central area without margins');
  VarCreate('num_roots', '[-]', 0, false, num_roots, 'number of roots in center and margins');
  VarCreate('number_consid_roots', '[-]', 0, false, number_consid_roots,
    'number of considered roots, i.e. without margin roots');
  VarCreate('errorReg', '[%]', 0, false, errorReg,
    'measure of error for regular distribution');

  VarCreate('dim_xMiddle', '[d]', 0, false, dim_xMiddle, 'dimension in x direction');
  VarCreate('dim_yMiddle', '[d]', 0, false, dim_yMiddle, 'dimension in y direction');

  OptCreate('RootDistribution', 'Random', RootDistribution,
    'Type of root distribution');
  RootDistribution.OptionList.Add('Random');
  RootDistribution.OptionList.Add('Regular');
  // Verteilung wie in Quelle (Datei, Strukturmodell)
  RootDistribution.OptionList.Add('FromSource');

  OptCreate('WithMargins', 'withoutMargin', WithMargins, 'Option for removing root too near the border of the 2-Dcalculation field');
  WithMargins.OptionList.Add('withMargin');
  WithMargins.OptionList.Add('withoutMargin');

  // Create and initialize TOption
  { Specify the source of the root data }
  OptCreate('IniMethod', 'InpPar', IniMethod, 'Method for root initialization');
  IniMethod.OptionList.add('InpPar'); // RLD/VC indicators as parameters
  IniMethod.OptionList.add('XYFile');
  IniMethod.OptionList.add('RasterDataFile');
  IniMethod.OptionList.add('SubmodStruct');

  OptCreate('OutputXY', 'no', OutputXY, 'Output in XY format');
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Paths for model comparison 1D vs 2D }
  { Paths to input and output files are identical for both submodels. Running both
    submodels simultaneously in one model run only makes sense for comparison. }
  OptCreate('RootInpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\abo130782.txt', RootInpDataFile, 'file name of root input data');
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
    RootXYOutpDataFile, 'file name of root output data containing the influx rates of the roots');
  RootXYOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data');
end;


/// <summary>Performs various initializations</summary>
procedure TSubmodRootBase.init(var GlobMod: TMod);
var
  i: integer;
  // Number of grid cells in X and Y direction
  numberGridCellsX, numberGridCellsY: integer;
  ARoot: TRootObjectIn2D;
  DimXMiddle, DimYMiddle: real;

begin
  inherited;
  hasWritten := false;
  GlobMod.Time.c := self.ini_dt.v;

  { Area of the layer under investigation }
//  Volume.v := area.v * Depth.v;    // [cm3]
  theta.v := IniTheta.v;  // [cm3/cm3]

  // The amount of water is multiplied by depth and not by area
  // because implicitely this meant for an area average
  WAmount.v := theta.v*Depth.v;   //  [cm]

    // take the input parameter as mean root length density
  RLD_mean.v := ParMRLD.v;

  wl.v := RLD_mean.v * 1E4 * Depth.v;

  // root length per hectar [cm/ha]
  wl_ha.v := wl.v * 1E4;

  De.v := D0NO3*f_Tortuosity(Theta.v); // [cm2/d]

  NAmount.v := IniSoilNitrate.v; // kg N/ha

  // the amount of water is calculated in length units
  // within the macroscopic 1-D transport model the length unit for water is [cm]
  // thereby the area is neglected
  // because initial nitrate N is given in kg N/ha this ends with the units   [Kg NO3-N/ha/cm water]
  c_av.v := NAmount.v/WAmount.v; // [Kg NO3-N/cm water]
  c_start.v := c_av.v;
  // N_AmountSoil.v := mg_func(Tiefe.v, Theta.v, c_av.v);//Debuggen

  { Volumen der betrachteten Bodenschicht[cm3] }
  { Berechnung Mineralisationsrate in [Mol/cm^3*d] }

  // the input parameter minera.v for the soil N mineralisation rate is in kg N/ha/d
  Min_S.v := NMinerRate_kgNha.v;

    { Ausschluss der Ränder; sollte nicht durchgeführt werden, da die Wurzeln zwar
    vorhanden sein und auch Aufnahme durchführen sollten, aber nicht berücksichtigt
    werden sollten }

  If wl_ha.v > 0.0 then
  begin
    { Berechnung scheint korrekt s. Manuskript Hängeregister Vgl 1D2D }
    // PotNuptakerate.v is in kg N/ha/d
    // also Imax is therefore in kg N/ha/d
    // this should be considered if compared to literature data
    // from plant physiologiy where Imax is most often given in [mol N/cm/s]
    Imax.v := NUptakeratepot.v / wl_ha.v;
  end
  else
    Imax.v := 0.0;



end;


/// <summary>Performs various initializations</summary>
procedure TSubmodRootBase2D.init(var GlobMod: TMod);

var
  i: integer;
  // Number of grid cells in X and Y direction
  numberGridCellsX, numberGridCellsY: integer;

begin
  inherited;

  // Rewrite output file for XY coordinates
  AssignFile(xyfile, RootXYOutpDataFile.Option);
  rewrite(xyfile);
  { Create or replace the file; it is rewritten for each model run }
  closeFile(xyfile);


  // the number of grid cells for both dimensions
  numberGridCellsX := trunc(dimensionX.v / gridWidth.v);
  numberGridCellsY := trunc(dimensionY.v / gridHeight.v);


  // set the length of the CountArr array according to the number of grid cells
  // in X and Y direction
  // in a first step only the first dimension is set
  // in a second step the second dimension is set for each element of the first dimension
  setLength(RasterData.CountArr, trunc(numberGridCellsX));
  for i := 0 to high(RasterData.CountArr) do
  begin
    setLength(RasterData.CountArr[i], trunc(numberGridCellsY));
  end;

  // Initialize TConst where appropriate at this stage
  area.v := dimensionX.v * dimensionY.v;     // [cm2]
  { Area of the layer under investigation }


  /// there are four options for defining the location and number of roots
  ///  rasterdatafile: root counts within a pre defined grid are input
  ///  xyfile: a list of defined roots with their exact position input
  ///  inppar: only the average root length density is defined, the root position
  ///  are then calculated either in a regular hexagonal grid or as
  ///  pure random positions
  ///  submodstruct: the positions are given by a root structural model
  ///
    { Keine dynamische Verbindung zwischen 2D-Diffmodell und Strukturmodell in den
    Verteilungsvarianten regular oder random }
  if (iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option <> 'fromsource') then
  begin
    RootDistribution.Option := 'fromsource';
    // showMessage('Strukturmodell setzt Einstellung lognormal voraus.Wurde umgestellt.');
  end;

  if IniMethod.Option = 'rasterdatafile' then
  begin
    RasterData.readRasterData(RootInpDataFile.Option, SeriesXY);
    fillGridRasterData;
  end;

  if IniMethod.Option = 'xyfile' then
  begin
    RasterData.readXYfromFile(RootInpDataFileXY.Option, SeriesXY);
  end;

  // if the number of roots is given by root length density
  // the distribution of the roots is always regular
  if IniMethod.Option = 'inppar' then
  begin

    // calculation of the number of roots
    num_roots.v := RLD_mean.v * area.v;

    // copy the number of roots to the RasterData object
    RasterData.NRoots := trunc(num_roots.v);

    // calculate positions of the roots according to a regular distribution
    // and create root objects for each position
    RasterData.CalcEqualDistribution(RLD_mean.v);

    // correct for wrong setting of root distribution option
    // if initMethod is inppar then from source is not a correct option
    if RootDistribution.Option = 'fromsource' then
    begin
      // Da es keine Quelle gibt macht hier nur die Option regular bzw. random Sinn
      ShowMessage
        ('Caution: RootDistribution = FromSource. RootDistribution is set to regular.');
      RootDistribution.Option := 'regular';
    end;
  end;

  // Berechnen einer gleichmäßigen bzw. zufälligen Verteilung
  If RootDistribution.Option = 'random' then
    RasterData.CalcRandomRootPositions;

  If (RootDistribution.Option = 'regular') and (num_roots.v <> 0) then
  begin
    RasterData.CalcEqualDistribution(RLD_mean.v);
  end;

  // calculation of index values for each root position
  // needed for further calculations
  if num_roots.v <> 0 then
  begin
    RasterData.CalcRootPosAsIndex;
  end;

 if WithMargins.Option = 'true' then begin
     RasterData.ExtractMiddle;
     RasterData.removeMarginRoots;
     AreaMiddle.v := RasterData.fAreaMiddle;
 end
  else begin
    //   AreaMiddle.v := (dimensionX.v-self.horizMargin.v) * (dimensionY.v-self.verticMargin.v)
    AreaMiddle.v := Area.V;
  end;


  if (RootDistribution.Option <> 'regular') or (IniMethod.Option = 'xyfile')
  then
  begin
    // RLD_mean has also to be calculated when borders are considered
    if AreaMiddle.v <> 0 then
      RLD_mean.v := RasterData.NRoots / RasterData.fAreaMiddle;
  end;

  { Für Distance und die weiteren abgeleiteten Variablen werden nur Wurzel
    berücksichtigt, die sich nicht in den Rändern befinden }
  if num_roots.v <> 0 then
    AvDistance.v := 1 / sqrt(pi * RLD_mean.v);
  { Berechnung der Wurzellänge in [cm] bezogen auf die Tiefe. Es wird davon ausge-
    gangen, dass die parallel angeordnete lineare Strukturen ohne Krümmung sind.
    Es werden dabei die Anzahl der berücksichtigten mittigen Wurzeln auf die gesamte
    Beobachtungsfläche hochgerechnet }

  // root length per quare meter [cm/m²]

  wl.v := number_consid_roots.v / AreaMiddle.v * 1E4 * Depth.v;

  // root length per hectar [cm/ha]
  wl_ha.v := wl.v * 1E4;

end;

procedure TRasterData.CalcRandomRootPositions;
var
  ARoot: TRootObjectIn2D;
  Local_i: Integer;
begin
  begin
    for Local_i := 0 to NRoots - 1 do
    begin
      ARoot := TRootObjectIn2D(RootList.Objects[Local_i]);
      ARoot.x := Random(NCols - 2) + 2;
      ARoot.y := Random(NRows - 2) + 2;
    end;
  end;
end;

procedure TRasterData.ExtractMiddle;

begin
  // if Margin roots should not be considered only the middle area is used
  // for calculation of RLD etc.
    fdim_xMiddle := fDimensionX - 2 * fhorizMargin;
    fdim_yMiddle := fDimensionY - 2 * fverticMargin;
    fAreaMiddle  := fdim_xMiddle * fdim_yMiddle;

    // Berechnung der Anzahl der mittigen Rechenelemente
    ndim_xMiddle := trunc(fdim_xMiddle / ColWidth);
    ndim_yMiddle := trunc(fdim_yMiddle / RowHeight);
end;





/// <summary>Both models can display roots in the RootDistribution tab.</summary>
procedure TSubmodRootBase2D.fillChartRootDistr;
var
  i: integer;
  ActRoot : TRootObjectIn2D;
begin
  SeriesXY.Clear;
  // Fill the series object.
  for i := 0 to self.RasterData.RootList.count-1 do
  begin
    ActRoot := TRootObjectIn2D(self.RasterData.RootList.Objects[i]);
    if (ActRoot.x <> 0) and (ActRoot.y <> 0) then
      SeriesXY.AddXY(ActRoot.x, ActRoot.y);
  end;
  MyChart.AddSeries(SeriesXY);
end;

/// <summary>
/// Both models can write aggregated root data to the form. The method fills the
/// aggregated root data (number of roots per grid cell) into the AdvStringGrid of
/// the Hume form.
/// </summary>
procedure TSubmodRootBase2D.fillGridRasterData;
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
      IntToStr((Col - 1) * trunc(RasterData.ColWidth)) + ' - ' +
      IntToStr(Col * trunc(RasterData.ColWidth));
  end;
  For Row := 1 to RasterData.NRows do
  begin { Write row headers }
    MyAdvStringGrid.Cells[0, Row] :=
      IntToStr((Row - 1) * trunc(RasterData.RowHeight)) + ' - ' +
      IntToStr(Row * trunc(RasterData.RowHeight));
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

/// <summary>
/// Writes coordinates and areas of PosArr to a file. With a structural model, output
/// occurs at each time step; with static root positions only at the start of the
/// model run. For testing in the static case, the positions of roots in the margins
/// are also written.
/// </summary>
procedure TRasterData.WriteOutputToFile( fn:string; Time: real);

var
  i, j: integer;
  { Only sinks that are not in the margin and observation window are output.
    PosArr_middle should already contain only these roots }
  PosArr_middle: Array of TRootObjectIn2D;
  ActRoot: TRootObjectIn2D;
  xyfile: textfile;

begin
  setLength(PosArr_middle, number_consid_roots);
  j := 0;
  for i := 0 to NRoots - 1 do
  begin
    // Point not in vertical margins
    ActRoot := TRootObjectIn2D(RootList.Objects[i]);
    if (ActRoot.x >= fverticMargin) and
      (ActRoot.x <= fdimensionX - fverticMargin)
    // Point not in horizontal margins
      and (ActRoot.y >= fhorizMargin) and
      (ActRoot.y <= fdimensionY - fhorizMargin) then
    begin
      PosArr_middle[j].x := ActRoot.x;
      PosArr_middle[j].y := ActRoot.y;
      PosArr_middle[j].xi := ActRoot.xi;
      PosArr_middle[j].yi := ActRoot.yi;
      // PosArr_middle[j].NInflux := ActRoot.NInflux;
      PosArr_middle[j].WInflux := ActRoot.WInflux;
      PosArr_middle[j].nroot := ActRoot.nroot;
      PosArr_middle[j].Area := ActRoot.Area;
      Inc(j);
    end;
  end;
  AssignFile(xyfile, fn);
  rewrite(xyfile);
  write(xyfile, 'Modellzeit: ', Time:6:2, ' ');
  writeln(xyfile);
  // Write header
  write(xyfile, 'Lfd.Nr.', ' ', 'X', ' ', 'y', ' ', 'Flaeche', ' ');
  writeln(xyfile);
  for i := 0 to high(PosArr_middle) do
  begin
    write(xyfile, PosArr_middle[i].nroot, ' ');
    write(xyfile, PosArr_middle[i].x, ' ');
    write(xyfile, PosArr_middle[i].y, ' ');
    write(xyfile, PosArr_middle[i].Area, ' ');
    writeln(xyfile);
  end;
  // Border points
  write(xyfile, 'Punkte in R�ndern:');
  writeln(xyfile);
  write(xyfile, 'Lfd.Nr.', ' ', 'X', ' ', 'y', ' ', 'Flaeche', ' ');
  writeln(xyfile);
  for i := 0 to NRoots - 1 do
  begin
    ActRoot := TRootObjectIn2D(RootList.Objects[i]);

    // Point not in vertical margins
    if (ActRoot.x < fverticMargin) or
      (ActRoot.x > fdimensionX - fverticMargin)
    // Point not in horizontal margins
      or (ActRoot.y < fhorizMargin) or
      (ActRoot.y > fdimensionY - fhorizMargin) then
    begin
      write(xyfile, ActRoot.nroot, ' ');
      write(xyfile, ActRoot.x, ' ');
      write(xyfile, ActRoot.y, ' ');
      write(xyfile, ActRoot.Area, ' ');
      writeln(xyfile);
    end;
  end;
  closeFile(xyfile);
end;

/// <summary>
/// All diffusion models can compute a uniform distribution from a given one. The
/// method distributes points based on a given WLD evenly over an area. The
/// TPointSeries object of the calling HUME GUI method is refilled so the display
/// can be updated. Different methods were created for this purpose and can be
/// switched here.
/// </summary>
procedure TRasterData.CalcEqualDistribution(RLD:real);
var
  radSRP, // Radius SRP
  AreaSRP // Area SRP
    : double;
begin
  { If RLD is read as a parameter, the number of roots in the observation window
    still has to be calculated }
  radSRP := 1 / sqrt(Pi * RLD);
  AreaSRP := Pi * sqr(radSRP);
  NRoots := trunc(fdimensionX * fdimensionY / AreaSRP);
  // Fill rows
  distributeHexagonRow;
  // Fill columns
  distributeHexagonCol;
end;

/// <summary>
/// Distribution using hexagons. Rows are filled sequentially. For better
/// distribution the points still need to be shifted by half the radius of the
/// circumscribed circle.
/// </summary>
procedure TRasterData.distributeHexagonRow;
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
  angel, // 60� in radians
  stretch, // Distance (2*Rad_AK - edge)/2 (see slide on uniform distribution)
  /// <summary>Edge length of hexagon</summary>
  edgeHexagon: real;
  errorRoot, i, j, number_row: integer;
  NewRoot : TRootObjectIn2D;
  errorReg : real;

begin
  inherited;
  RootList.Clear;
  { Calculation of the area assigned to one hexagon.
    Margins are cut off only after the uniform distribution }
  AreaObservation := fdimensionX * fdimensionY;
  Area_Polygon := AreaObservation / NRoots;
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
  dimx := fdimensionX;
  dimy := fdimensionY;
  // Fill PosArr:
//  RasterData.errasePosArr; // Delete old entries. Problem: necessary???
  // number_row := 1;           // Start at row 1
  number_row := 0; // Start at row 0
  { Caveat: PosArr begins at 1 }
  j := 0;
  i := 0;
  errorRoot := 0;
  errorReg := 0;
  while i <= NRoots-1 do
  begin
    if (number_row mod 2 <> 0) then // odd rows
    begin
      // Calculation for odd rows:
      pos_x := ((j * 2 + 1) * Rad_AK + j * edgeHexagon);
      pos_y := Rad_IK * number_row;
      if (pos_x <= dimx) and (pos_y <= dimy) then
      // As long as the point remains within the calculation area
      begin
        NewRoot := TRootObjectIn2D.create;
//        NewPosition.create;
        NewRoot.x := pos_x;
        NewRoot.x := pos_y;
        NewRoot.nroot := i;
        NewRoot.area := Area_Polygon;
        RootList.AddObject(IntToStr(i), NewRoot);
 //       TRootObjectIn2D(RasterData.PosList.objects[i]).x := pos_x;
 //       TRootObjectIn2D(RasterData.PosList.objects[i]).y := pos_y;
 //       TRootObjectIn2D(RasterData.PosList.objects[i]).root := i;
        { It is assumed that the area of the hexagon corresponds to the area of the
          Voronoi polygon. Points within the polygon would then be closer to the central
          sink than to any other sink. }
        { This point is not entirely consistent since PosArr could also be used for the
          calculations. }
 //       TRootObjectIn2D(RasterData.PosList.objects[i]).area := Area_Polygon;
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
        NewRoot := TRootObjectIn2D.create;
        NewRoot.x := pos_x;
        NewRoot.x := pos_y;
        NewRoot.nroot := i;
        NewRoot.area := Area_Polygon;
        RootList.AddObject(IntToStr(i), NewRoot);
//        TRootObjectIn2D(RasterData.PosList.objects[i]).x := pos_x;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).y := pos_y;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).root := i;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).area := Area_Polygon;
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
  errorReg := errorRoot / NRoots * 100;
end;

/// <summary>
/// Distribution using hexagons. Columns are filled sequentially. The method may be
/// advantageous when nutrient uptake in layers is calculated (this still needs
/// verification). The distribution was adjusted: X-values were shifted half a Rad_AK
/// to the right and Y-values half a Rad_AK upward (see slide Filling columns 2).
/// CAVE: method not up to date and should be improved based on distributeHexagonRow
/// (e.g., calculation of ErrorReg).
/// </summary>
procedure TRasterData.distributeHexagonCol;
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
  angel, // 60� in radians
  stretch, // Distance (2xRad_AK - edge)/2 (see slide on uniform distribution)
  { Edge length of hexagon, actually equal to Rad_AK, kept for clarity }
  edgeHexagon: real;
  i, j, number_col: integer;
  NewPosition: TRootObjectIn2D;
begin
  inherited;
  RootList.Clear;
  AreaObservation := fdimensionX * fdimensionY;
  { Calculation of the area assigned to one hexagon: }
  Area_Polygon := AreaObservation / NRoots;
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
  dimx := fDimensionX;
  dimy := fDimensionY;
  // Fill PosArr:
//  RasterData.errasePosArr; // Delete old entries. Issue: necessary???
  // number_col := 1;           // Start at column 1
  number_col := 0; // Start at column 0
  j := 0;
  { Caveat: PosArr begins at 1 }
  i := 0;
  while i <= NRoots-1 do
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
        NewPosition.create;
        NewPosition.x := pos_x;
        NewPosition.x := pos_y;
        NewPosition.nroot := i;
        NewPosition.area := Area_Polygon;
        RootList.AddObject(IntToStr(i), NewPosition);

//        TRootObjectIn2D(RasterData.PosList.objects[i]).x := pos_x;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).y := pos_y;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).root := i;
        { It is assumed that the area of the hexagon corresponds to the area of the
          Voronoi polygon. Points within the polygon would then be closer to the central
          sink than to any other sink. }
//        TRootObjectIn2D(RasterData.PosList.objects[i]).area := Area_Polygon;
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
        NewPosition := TRootObjectIn2D.create;
        NewPosition.x := pos_x;
        NewPosition.x := pos_y;
        NewPosition.nroot := i;
        NewPosition.area := Area_Polygon;
        RootList.AddObject(IntToStr(i), NewPosition);
//        TRootObjectIn2D(RasterData.PosList.objects[i]).x := pos_x;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).y := pos_y;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).root := i;
//        TRootObjectIn2D(RasterData.PosList.objects[i]).area := Area_Polygon;
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


/// <summary>Removes roots located in the margins from the Pos array</summary>
procedure TRasterData.removeMarginRoots;
var
  i: integer;
  ARoot : TRootObjectIn2D;

begin
  for i := RootList.Count - 1 downto 0 do
  begin
    ARoot := TRootObjectIn2D(RootList.Objects[i]);
    // Point not in vertical margins
    if (ARoot.x <= fhorizMargin) or
      (ARoot.x >= fdimensionX - fhorizMargin)
    // Point not in horizontal margins
      or (ARoot.y <= fVerticMargin) or
      (ARoot.y >= fdimensionY - fVerticMargin) then
    begin
      ARoot.free;
      RootList.Delete(i);
    end;
  end;
  NRoots := RootList.Count;
  number_consid_roots := NRoots;
end;

function TSubmodRootBase2D.getRasterData: TRasterData;
begin
  Result := self.RasterData;
end;


/// <summary>
/// Returns the calculated N amount [kgN/ha]; converts the existing concentration
/// (aggregated values).
/// </summary>
function Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): real;
const
  kg_mol = 14 / 1000; { Molecular weight of nitrogen }
var
  volumen_cm3, { Volume of soil layer on an area of 1 ha }
  cm3_ha, n_menge: extended;
begin
  volumen_cm3 := Tiefe_cm * 1E8;
  cm3_ha := theta * volumen_cm3; { Water content on one hectare }
  n_menge := Cli_mol_cm3 * kg_mol * cm3_ha;
  Result := n_menge;
end;

/// <summary>Returns the concentration [Mol N/cm^3]</summary>
function Cl_func(Tiefe_cm, theta, NMenge: real): real;
const
  kg_mol = 14 / 1000; { Molecular weight of nitrogen }
var
  volumen_cm3, { Volume of soil layer on an area of 1 ha }
  cm3_ha, Cli_mol_cm3: extended;

begin
  volumen_cm3 :=Tiefe_cm * 1E8;
  cm3_ha := theta * volumen_cm3; { Water content on one hectare }
  Cli_mol_cm3 := NMenge / (kg_mol * cm3_ha);
  Result := Cli_mol_cm3;
end;


procedure TRasterdata.TestForContBorder(var start_, ende_: integer;
  x_ndx, y_ndx: integer; zeile: boolean);
(* ------------------------------------------------------------------------------
  Tests whether cells in a row or column are intersected by the container wall.
  x_ndx and y_ndx denote the first cell of the respective row or column.
  Return value is
  ------------------------------------------------------------------------------ *)
var
  cutContWall: boolean;
  i: integer;
  upperLeft, // Cartesian coordinates of the upper left corner of the grid cell
  bottomRight, // Cartesian coordinates of the lower left corner of the grid cell
  VektUppLeft_ContCent, VektBottRight_ContCent: r2;
  distUpperLeft, distBottomRight: double;
begin
  cutContWall := false;
  if zeile = true then // rows are scanned
  begin
    for i := 0 to NCols-1 do // determine the start cell
    begin
      upperLeft[0] := i * ColWidth;
      upperLeft[1] := y_ndx * RowHeight;
      bottomRight[0] := i * ColWidth;
      bottomRight[1] := (y_ndx) * RowHeight;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > fContRad) and (distBottomRight < fContRad) then
      begin
        start_ := i;
        cutContWall := true;
        break; // break necessary because only the first occurrence is used
      end;

    end;
    for i := trunc(self.NCols-1) downto 0 do // determine the start cell
    begin
      upperLeft[0] := (i ) * colwidth;// dx.v;
      upperLeft[1] := (y_ndx ) * rowheight;// RowHeight;
      bottomRight[0] := (i+1) * self.colwidth;//dx.v;
      bottomRight[1] := (y_ndx+1) * RowHeight;//dy.v;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > fContRad) and (distBottomRight < fContRad) then
      begin
        ende_ := i;
        break; // break necessary because only the first occurrence is used
      end;

    end;
  end
  else // columns are scanned
  begin
    for i := 0 to trunc(NRows-1) do // determine the start cell
    begin
      upperLeft[0] := (x_ndx ) * colwidth;//dx.v;
      upperLeft[1] := (i+1) * rowheight;//dy.v;
      bottomRight[0] := (x_ndx) * colwidth;//dx.v;
      bottomRight[1] := (i+1) * rowHeight;//RowHeight;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > fContRad) and (distBottomRight < fContRad) then
      begin
        start_ := i;
        cutContWall := true;
        break; // break necessary because only the first occurrence is used
      end;

    end;
    for i := trunc(NRows-1) downto 0 do // determine the start cell
    begin
      upperLeft[0] := (x_ndx -1) * colwidth;//dx.v;
      upperLeft[1] := (i ) * rowheight;//RowHeight;
      bottomRight[0] := (x_ndx ) * colwidth;//dx.v;
      bottomRight[1] := (i-1) * rowheight;//RowHeight;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > fContRad) and (distBottomRight < fContRad) then
      begin
        ende_ := i;
        break; // break necessary because only the first occurrence is used
      end;

    end;
  end;
  if (cutContWall = false) and (zeile = true) then
  begin
    start_ := 1;
    ende_ := NCols;
  end;
  if (cutContWall = false) and (zeile = true) then
  begin
    start_ := 1;
    ende_ := NRows;
  end;

end;


function TRasterData.calcAbsValue2D(vect: r2): double;
(* ------------------------------------------------------------------------------
  Calculates the magnitude = length of a vector
  ------------------------------------------------------------------------------ *)
var
  length: double;
begin
  length := sqrt(sqr(vect[0]) + sqr(vect[1]));
  Result := length;
end;

function TRasterData.vectorSubtrakt2D(vect2, vect1: r2): r2;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Subtracts vector_2 from vector_1 and returns the resulting vector
  pointing in the direction of vector 1.
  ------------------------------------------------------------------------------ *)
var
  vector_result: r2;
begin
  vector_result[0] := vect1[0] - vect2[0];
  vector_result[1] := vect1[1] - vect2[1];
  Result := vector_result;
end;


procedure TRasterData.calcRootPosAsIndex;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  Methode berechnet die Wurzelpositionen als Index (=berechnet die Rechenzelle in
  der sich die Wurzel befindet).
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  { Um die Orignalen Werte nach der Rundung wiederherzustellen, müssen sie zwischen-
    gespeichert werden }
  xTemp, yTemp: double;
  ARoot : TRootObjectIn2D;

begin
  for i := 0 to NRoots-1 do
  begin
    ARoot := TRootObjectIn2D(RootList.Objects[i]);
    xTemp := ARoot.x;
    yTemp := ARoot.y;
    ARoot.xi := min(NCOLS - 1,
      max(1, round(ARoot.x / (NCols) *
      trunc(NCOLS))));
    ARoot.yi := min(NROWS - 1,
      max(1, round(ARoot.y / NRows) * NROWS));
    // Rückspeichern
    ARoot.x := xTemp;
    ARoot.y := yTemp;
  end;
end;


procedure TRasterData.zweid_solut(dt_globmod: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: Central procedure. Calculation of nutrient transport in 2D space
  (linear algebra). Note: nested structure
  ------------------------------------------------------------------------------ *)
var
  { The following arrays are declared with a size of dim_max (largest index).
    From the fluxes, a tridiagonal matrix with main and secondary diagonals is
    formed (see Scholl/Drews: linear algebra) }
  /// <summary>solution vector</summary>
  B_vektor,
  /// <summary>lower diagonal</summary>
  lower,
  /// <summary>middle diagonal</summary>
  diag,
  /// <summary>upper diagonal</summary>
  upper,
  /// <summary>sink terms</summary>
  Sink,
  /// <summary>concentration vector below</summary>
  u_vektor,
  /// <summary>z_vektor : central vector to be calculated</summary>
  z_vektor,
  /// <summary>concentration vector above</summary>
  o_vektor: array_type;
  { Note: since array_type also starts at 0 in the original, nothing needs to be
    changed here }
  Result, i: word;

  /// <summary>
  ///   effective diffusion coeffecient
  /// </summary>
  Df: real;
  /// <summary>loop variables for grid elements</summary>
  x_ndx, y_ndx: integer;

  SinkCellFile: Textfile;
  SinkCellFileName: string;
  ARoot: TRootObjectIn2D;


  procedure CalcOneLine(o_vektor, Sink: array_type; dim_z, Start, Ende: word;
    var u_vektor, z_vektor: array_type);
  (* -----------------------------------------------------------------------------
    PARENT method: TSubModDiff2D_k.zweid_solut
    The flux calculation is performed row by row.
    ------------------------------------------------------------------------------ *)
  var
    flow_1, flow_2: real;

    { In the following procedures the fluxes over the borders are determined for
      a grid cell }
    Procedure linker_Rand(Start: integer); // or upper boundary
    (* ------------------------------------------------------------------------------
      PARENT method: (helper procedure eine_Zeile)
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      For i := 1 to Start - 1 do
      begin
        B_vektor[i] := z_vektor[i];
        diag[i] := 0; // vectors are set to zero at the borders
        upper[i] := 0;
      end;
      flow_1 := ColWidth * fDe * (u_vektor[Start] - z_vektor[Start]) / RowHeight * Df;
      // explicit calculation
      flow_2 := ColWidth * fDe * (z_vektor[Start] - o_vektor[Start]) / RowHeight * Df;

      B_vektor[Start] := z_vektor[Start] + flow_1 - flow_2 + Sink[Start] * Df;
      diag[Start] := fDe * RowHeight / ColWidth * Df + 1;
      upper[Start] := -fDe * RowHeight / ColWidth * Df;
    end; // End linker Rand

    Procedure Mittelteil(Start, Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure CalcOneLine
      DESCRIPTION: Solves the diffusion equation for two-dimensional coordinates
      (grid) using an alternating direction implicit approach?
      Boundary condition: no transport across grid boundaries (no flow)
      ------------------------------------------------------------------------------ *)
    var
      ndx: word;
    begin
      For ndx := Start + 1 to Ende - 1 do
      begin
        flow_1 := ColWidth * fDe * (u_vektor[ndx] - z_vektor[ndx]) / RowHeight * Df;
        flow_2 := ColWidth * fDe * (z_vektor[ndx] - o_vektor[ndx]) / RowHeight * Df;

        B_vektor[ndx] := z_vektor[ndx] + flow_1 - flow_2 + Sink[ndx] * Df;
        lower[ndx] := -fDe * RowHeight / ColWidth * Df;
        diag[ndx] := fDe * RowHeight / ColWidth * Df + fDe * RowHeight / ColWidth * Df + 1;
        upper[ndx] := -fDe * RowHeight / ColWidth * Df;
      end;
    end; // End Mittelteil

    Procedure RightBoundary(Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      flow_1 := ColWidth * fDe * (u_vektor[Ende] - z_vektor[Ende]) / RowHeight * Df;
      flow_2 := ColWidth * fDe * (z_vektor[Ende] - o_vektor[Ende]) / RowHeight * Df;

      B_vektor[Ende] := z_vektor[Ende] + flow_1 - flow_2 +
        Sink[NCols] * fDe;
      lower[Ende] := -fDe * RowHeight / ColWidth * Df;
      diag[Ende] := fDe * RowHeight / ColWidth * Df + 1;
      For i := Ende + 1 to trunc(NCols) do
      begin
        B_vektor[i] := z_vektor[i];
        diag[i] := 0;
        upper[i] := 0;
      end;

    end; // End rechter Rand

    procedure SolveEquationSystem;
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      DESCRIPTION: Calls the function trdiag in TRDIAG.pas. The function solves a
      tridiagonal system of equations; see matrix calculations and linear
      combinations. Further explanatory notes on the solution method are in
      tridiag.pas
      ------------------------------------------------------------------------------ *)
    var
      ndx: word;
    begin
      Result := trdiag(false, dim_z, 1, lower, diag, upper, B_vektor);
      If Result <> 0 then
      begin
        { Return value only indicates whether it worked and is used to output an
          error message. Problem: is exception handling needed? }
        showMessage('Error while solving TriDiaMatrix');
      end;
      for ndx := 1 to dim_z do
      begin
        If B_vektor[ndx] < 0.0 then
        begin
          { Negative concentrations should not occur! In this case default values
            are used }
          z_vektor[ndx] := 1E-15;
          u_vektor[ndx] := 1E-15;
        end
        else
        begin
          u_vektor[ndx] := z_vektor[ndx];
          z_vektor[ndx] := B_vektor[ndx];
        end;
      end;
    end; // End Loesung_Gleichungssysteme

  begin
    if fWriteSinkCells then
    begin
//      SinkCellFileName := SinkCellFileFile.Option;
      if fSinkCellFileWasCreated = false then
      begin
        deleteFile(fSinkCellFileName);
        assignfile(SinkCellFile, fSinkCellFileName);
        rewrite(SinkCellFile);
        // Header
        write(SinkCellFile, 'SimZeit', ' ', 'dt_akt[d]', ' ', 'sumDtInt[d]',
          ' ', 'Influx', ' ', 'Konz_Zelle');
        writeln(SinkCellFile);
        closefile(SinkCellFile);
        SinkCellFileWasCreated := true;
      end;
    end;
    linker_Rand(Start);
    Mittelteil(Start, Ende);
    RightBoundary(Ende);
    SolveEquationSystem;
  end; // End eine_Zeile (correct?)

(* -----------------------------------------------------------------------------
  End of helper methods for the central method
  ------------------------------------------------------------------------------ *)
var
  start_, ende_: integer;
begin

  /// <summary>computation factor for half time step</summary>
  Df := int_dt.v / 2 * 1 / wm;
  { Setup of the system of equations with an IMPLICIT formulation for y and
    an EXPLICIT formulation for x }
  // iterate over all computational elements (except the 1 cell wide margins)

  for y_ndx := 1 to trunc(dim_y.v) do
  begin
    For i := 1 to trunc(dim_x.v) do
    begin
      Get_Sink(i, y_ndx, Sink[i]); // calculate sink terms
      If y_ndx = 1 then
        u_vektor[i] := C_xy[i, 1];
      z_vektor[i] := C_xy[i, y_ndx];
      if y_ndx = trunc(dim_y.v) then
        o_vektor[i] := C_xy[i, trunc(dim_y.v)]
      else
        o_vektor[i] := C_xy[i, y_ndx + 1];
    end;
    if ContGrowth.Option = 'no' then
    begin
      CalcOneLine(o_vektor, Sink, trunc(dim_x.v), 1, trunc(dim_x.v), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      self.RasterData.testForContBorder(start_, ende_, i, y_ndx, true);
      CalcOneLine(o_vektor, Sink, trunc(dim_x.v), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(dim_x.v) do
      C_xy[i, y_ndx] := z_vektor[i];
  end;

  { Setup of the system of equations with an IMPLICIT formulation for x and
    an EXPLICIT formulation for y }

  for x_ndx := 1 to trunc(dim_x.v) do
  begin
    For i := 1 to trunc(dim_y.v) do
    begin
      Get_Sink(x_ndx, i, Sink[i]);
      If x_ndx = 1 then
        u_vektor[i] := C_xy[1, i];
      z_vektor[i] := C_xy[x_ndx, i];
      if x_ndx = dim_x.v then
        o_vektor[i] := C_xy[trunc(dim_x.v), i]
      else
        o_vektor[i] := C_xy[x_ndx + 1, i];
    end;
    if ContGrowth.Option = 'no' then
    begin
      CalcOneLine(o_vektor, Sink, trunc(dim_y.v), 1, trunc(dim_y.v), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      RasterData.testForContBorder(start_, ende_, x_ndx, i, true);
      CalcOneLine(o_vektor, Sink, trunc(dim_y.v), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(dim_y.v) do
      C_xy[x_ndx, i] := z_vektor[i];
  end;

  // write the influx of central sinks and concentration of the associated cell
  if self.writeSinkCellFile.Option = 'yes' then
  begin
    assignfile(SinkCellFile, SinkCellFileName);
    append(SinkCellFile);
    write(SinkCellFile, GlobMod.Time.v:6:2, ' ', int_dt.v:6:2, ' ',
      GlobMod.Time.v * 86400 + SumOfInternalTimeSteps, ' ');
    for i := 1 to RasterData.NRoots do begin
      ARoot := TRootObjectIn2D(RasterData.RootList.Objects[i]);
      if (ARoot.xi > trunc(dim_x.v / 10)) and
        (ARoot.xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (ARoot.yi > trunc(self.dim_y.v / 10)) and
        (ARoot.yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, ARoot.NInflux, ' ');
    end;
    for i := 1 to RasterData.NRoots do begin
      ARoot := TRootObjectIn2D(RasterData.RootList.Objects[i]);
      if (ARoot.xi > trunc(dim_x.v / 10)) and
        (ARoot.xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (ARoot.yi > trunc(self.dim_y.v / 10)) and
        (ARoot.yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, C_xy[ARoot.xi, ARoot.yi], ' ');
    writeln(SinkCellFile);
    closefile(SinkCellFile);
    end;
  end;
end;
(* ------------------------------------------------------------------------------
  End of central procedure
  ------------------------------------------------------------------------------ *)


procedure TSubmodRoot2DNitrate.Get_Sink(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of sink terms (uptake and mineralization)
  [mol/d-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  i, j: word;
  NUptake, Nuptake2, Nuptake3, NUptakeGrid, NAmountRootdt,
  // nitrogen uptake rate for current root [dg/dt]
  SumUptake, x, Db: real;
  De_SinkGrid: double;


begin
  get_minGrid(x_loc, y_loc, s); // calculate mineralization
  NUptake := 0.0;
  SumUptake := 0.0;
  De_SinkGrid := fDe / theta.v;
  for i := 0 to trunc(Num_Roots.v)-1 do
  begin
    // test whether a sink exists in the computational element, then calculate uptake
    if ((TRootObjectIn2D(RasterData.RootList.Objects[i]).xi = x_loc) and (TRootObjectIn2D(RasterData.RootList.Objects[i]).yi = y_loc))
    then
    begin
      // radius of a circle corresponding to the central cell
      x := sqrt(ColWidth * RowHeight / pi);

      Db := Dl.v * 3.35 * theta.v * theta.v * theta.v; //
      { Inner boundary condition: constant influx; this scenario can be controlled
        via parameter Ar; another influencing factor is the calculated wl_ha }
      If NitrateUptakeFunction.Option = lowercase('ConstInflux') then
        NUptake := Imax.v; // mol/cm*d

      // Innere Randbedingung: Zero sink
      If NitrateUptakeFunction.Option = lowercase('ZeroSink') then

        // Nuptake :=
        { The flux is calculated considering the absorbing part of the root
          surface. The concentration gradient extends from the center of the
          neighboring cell to the apex of the root surface, with the root located
          centrally in the cell. See hanging file material 2D model. Note on the
          denominator: first term is the concentration gradient, second term the
          edge or the partial absorbing root surface. }
        { fDe*C_xy[x_loc-1, y_loc]/ColWidth*RowHeight
          +fDe*C_xy[x_loc+1, y_loc]/ColWidth*RowHeight
          +fDe*C_xy[x_loc, y_loc-1]/RowHeight*ColWidth
          +fDe*C_xy[x_loc, y_loc+1]/RowHeight*ColWidth; }
        { Alternative calculation of uptake by the sink: gradient reduced by
          Rad_Wurzel.v, flux in each direction corresponds to a quarter of the
          root circumference (assuming a cylindrical root). }
        { fDe*C_xy[x_loc-1, y_loc]/(ColWidth-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +fDe*C_xy[x_loc+1, y_loc]/(ColWidth-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +fDe*C_xy[x_loc, y_loc-1]/(RowHeight-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +fDe*C_xy[x_loc, y_loc+1]/(RowHeight-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2); }

        { NUptakeGrid:= fDe*C_xy[x_loc-1, y_loc]/ColWidth*RowHeight
          +fDe*C_xy[x_loc+1, y_loc]/ColWidth*RowHeight
          +fDe*C_xy[x_loc, y_loc-1]/RowHeight*ColWidth
          +fDe*C_xy[x_loc, y_loc+1]/RowHeight*ColWidth; }
        { Alternative calculation 2: inside the absorbing computation cell an
          uptake following the 1D approach was assumed, equating the area of the
          computational element with the area of the single root cylinder (see
          calculation of x above, then flux in the element is computed for radial
          coordinates). }
        // Nuptake :=     C_xy[x_loc, y_loc]*2*pi*Db/ln(x/(1.65*Rad_wurzel.v));
        { Alternative calculation 3 (cf. Kage, thesis Eq. 3.6.29, hanging file
          reformulation to In). It assumes that Cl_min corresponds to the
          concentration at the root surface and can become zero }
        NUptake := (C_xy[x_loc, y_loc] - clmin.v) * 2 * pi * Db /
          (-1 / 2 + (sqr(x) / (sqr(x) - sqr(RootRadius.v)) *
          ln(x / RootRadius.v)));

/// <summary>Alternative calculation 4 (after Moncayo, Eq. 19 and 20):</summary>
      { Nuptake :=
        De_SinkGrid*C_xy[x_loc-1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc+1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc-1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc+1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2); }
/// <summary>Implementation with Cl_min</summary>
      { ZeroSink     : In_arr[pos] := fDe*(C_xy[x_loc-1, y_loc]-clmin.v)/
        ColWidth*RowHeight+fDe*(C_xy[x_loc+1, y_loc]-clmin.v)/ColWidth*RowHeight
        +fDe*(C_xy[x_loc, y_loc-1]-clmin.v)/RowHeight*ColWidth+fDe*
        (C_xy[x_loc,y_loc+1]-clmin.v)/RowHeight*ColWidth; }
      // Innere Randbedingung: Michaelis-Menten-Kinetik
      If NitrateUptakeFunction.Option = lowercase('MM') then
        // NUptake :=  Influx_f( Imax.v, Km.v, C_xy[x_loc, y_loc]);
        NUptake := influx_fVar(Imax.v, Km.v, C_xy[x_loc, y_loc], x, Db);
      // influx into the sink during the time step

      TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux := NUptake;
      If NitrateUptakeFunction.Option <> lowercase('ZeroSink') then
        SumUptake := SumUptake + NUptake
      else
        SumUptake := NUptake;
      // calculate cumulative N uptake for the sinks
/// <summary>Problem: there is still a conceptual error here</summary>
      NAmountRootdt := TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux * 14 / 1000 * int_dt.v;
      // NAmountRootdt:=TRootObjectIn2D(RasterData.PosList.Objects[i]).NInflux*14/1000*86400/int_dt.V;
      TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmountdt := NAmountRootdt;
      TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount := TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount +
        NAmountRootdt;
    end;
  end;
/// <summary>Mineralization</summary>
  s := s - SumUptake;
end;

procedure TSubmodRoot2DNitrate.get_minGrid(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of mineralization [mol/d-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  pos: word;
begin
  /// <summary>sink term from mineralization [mol/d]</summary>
  s := Min_S.v * vol_Element;
end;

procedure TSubmodRoot2DNitrate.CalcRates;
(* ------------------------------------------------------------------------------
  DESCRIPTION: This method invokes the control flow of the submodel for rate
  calculation.
  ------------------------------------------------------------------------------ *)
var
  ConcFieldName: string;
  ConcField, UptakeFile: Textfile;
  i, j: integer;
  last_dt,
/// <summary>difference between concBefore and conc</summary>
  concBegin, // average concentration before calculating fluxes [mol/cm^3]
  ConcAfter, { average concentration after calculating fluxes [mol/cm^3]
    and before redistributing absorbed concentrations to the computational
    elements }
  // SumOfInternalTimeSteps,
  /// <summary>N amount taken up by all valid roots in the time step</summary>
  sumNAmountRootsdt
    : real;
  TimeStepAdaption: boolean;
begin
  /// <summary>nothing happens in the base model (no inherited call)</summary>
  inherited CalcRates;
  ConcFieldName := ConcFieldDataFile.Option;
  // Communication with the structural model and display of WAP in MathImNutrUptake
  // create new file with outputs for the sinks:
  for i := 0 to RasterData.RootList.Count-1 do
  begin
    TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount := 0;
  end;
  if FileWasCreated = false then
  begin
    assignfile(UptakeFile, RootSinkOutpDataFile.Option);
    rewrite(UptakeFile);
    closefile(UptakeFile);
    FileWasCreated := true;
  end;
  if self.iniMethod.Option = 'submodstruct' then
  begin
//    updateFromStructModell;
    // as long as no roots exist, no fluxes are calculated
    if Num_Roots.v < 1 then
      exit;
    fillChartRootDistr;
  end;
  { Since theta may change in the dynamic model, De must be recalculated each
    time step }
  fDe := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  // fDe:=Dl.v*3.35*sqr(theta.v);
  TimeStepAdaption := false;
  SumOfInternalTimeSteps := 0.0;
  last_dt := 0.0;
  ActArFromConc.v := 0;
  ActAr.v := 0;
  repeat
    if int_dt.v < max_dt.v then
      int_dt.v := int_dt.v * 1.1; // increase time step
    If int_dt.v > globtime.C * 86400 then
      int_dt.v := globtime.C * 86400;
/// <summary>Has the end of the day been exceeded with the new time step?</summary>
    If SumOfInternalTimeSteps + int_dt.v > globtime.C * 86400 then
    begin
      last_dt := int_dt.v; // save old time step length
      int_dt.v := (globtime.C * 86400 - SumOfInternalTimeSteps);
      TimeStepAdaption := true;
    end;
    // calculate fluxes
    concBegin := avg_conz;
    zweid_solut(int_dt.v);
    SumOfInternalTimeSteps := SumOfInternalTimeSteps + int_dt.v;
    { In each time step the cumulative N uptakes of the individual, non-marginal
      sinks are summed. Return value is the total N amount the roots have taken
      up in a time step }
    sumNAmountRootsdt := calcAmountUptakeRoots;
    SumNUptake.v := SumNUptake.v + sumNAmountRootsdt;
    { At the end of each internal time step the absorbed influx is redistributed
      to the computational elements }
    { If a steady-state condition should be generated, the constant concentration
      is restored in every time step }
    ConcAfter := avg_conz;
    ActArFromConc.v := ActArFromConc.v + Mg_func(Depth.v, theta.v,
      concBegin - ConcAfter);
    { For the calculation of the current uptake rate only roots not in the
      margins are considered }
    ActAr.v := ActAr.v + calcActArdt;
    if SteadyState.Option = 'yes' then
      createSteadyState(concBegin - ConcAfter);
    // write the concentration field in the last internal time step
    if SumOfInternalTimeSteps >= self.globtime.C * 86400 then
    begin
      if self.writeSinkCellFile.Option = 'yes' then
      begin
        assignfile(ConcField, ConcFieldName);
        rewrite(ConcField);
        // new file; only the final concField is written
        // header
        for i := 0 to trunc(dim_x.v + 1) do
        begin
          for j := 0 to trunc(dim_y.v + 1) do
          begin
            write(ConcField, C_xy[i, j], ' ');
          end;
          writeln(ConcField);
        end;
        closefile(ConcField);
      end;
    end;
  until SumOfInternalTimeSteps >= self.globtime.C * 86400;
  // if an adaptation of the time step length is intended
  If TimeStepAdaption then
    int_dt.v := last_dt; // restore old time step length
  If int_dt.v <= 0.0 then
    showMessage('time step error');
  // output of concentration change
  showActConc;
  // write valid root data to a file
  if (OutputXY.Option = 'yes') then
  begin
    RasterData.writeOutputToFile(self.ConcFieldDataFile.Option, self.GlobTime.v);
  end;
  if (OutputSink.Option = 'yes') then
  begin
    writeNitrateUptakeSinkToFile;
  end;
end; // End TSubmodRootDiff.CalcRates



procedure TSubmodRoot2DNitrate.InitConc;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Startkonz. aus der initialen N-Menge
  ------------------------------------------------------------------------------ *)
var
  x_ndx, y_ndx: integer;
  NAmountGridzell: double;
begin
  { Berechnen der N-Menge in einer Gridzelle von kg/ha auf g/dim_x*dim_y, die 1000
    im Nenner stammen von der Umrechnung von kg auf g }

  // NAmountGridzell:=N_AmountSoil.V*1000/(dim_x.v*dim_y.v*10000*vol_Element);  //g N/cm3
  // NAmountGridzell/(theta.v*14*Tiefe.V);   //mol/cm^3
  c_start.v := Cl_func(Depth.v, theta.v, NAmount.v);
  // c_start.v := NAmountGridzell/(theta.v*Tiefe.v*1e8*14)*1000; //alte Implement.
  For x_ndx := 0 to trunc(dim_x.v + 1) do
  begin
    for y_ndx := 0 to trunc(dim_y.v + 1) do
    begin
      // c_xy[x_ndx, y_ndx] := c_start.v*(1+x_ndx/1)*(1+y_ndx/1);
      C_xy[x_ndx, y_ndx] := c_start.v;
    end;
  end;
end;


procedure TSubmodRoot2DNitrate.Init(var GlobMod: TMod);

var
  DimXMiddle, // Dimension der mittigen Fläche in x-Richtung [cm]
  DimYMiddle // Dimension der mittigen Fläche in y-Richtung [cm]
    : double;
  i: integer;

begin
  inherited;

  RasterData.ContPosx := 50;
  RasterData.ContPosy := 50;
  SinkCellFileWasCreated := false;
  FileWasCreated := false;
  hasWritten := false;
  // Listen leeren
  self.RasterData.RootList.clear;
  { Keine dynamische Verbindung zwischen 2D-Diffmodell und Strukturmodell in den
    Verteilungsvarianten regular oder random }
  if (iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option <> 'fromsource') then
  begin
    RootDistribution.Option := 'fromsource';
    // showMessage('Strukturmodell setzt Einstellung lognormal voraus.Wurde umgestellt.');
  end;
  inherited;
  { AddDataValueToDataSeries ersetzt nun die Methode init. Ursprünglich wurde Init
    der übergeordneten Klasse wird mit dem übergebenen Globalmodell aufgerufen. }
  // inherited init(GlobModReferenz);
  (* -----------------------------------------------------------------------------
    c_xy: Festlegen der Arraygröße mit SetLength. Es wird ein mehrdimensionales
    Array deklariert. Cave: Dynamische Arrays beginnen immer bei 0.
    ------------------------------------------------------------------------------ *)
  // Rechenelementebezogene Operationen
  SetLength(RasterData.C_xy, trunc(dim_x.v + 2), trunc(dim_y.v + 2));
  SetLength(RasterData.x_arr, trunc(dim_x.v) + 2);
  SetLength(RasterData.y_arr, trunc(dim_y.v) + 2);
  ColWidth := DimensionX.v / dim_x.v;
  RowHeight := DimensionY.v / dim_y.v;
  DimXMiddle := DimensionX.v - 2 * verticMargin.v;
  DimYMiddle := DimensionY.v - 2 * horizMargin.v;
  // Berechnung der Anzahl der mittigen Rechenelemente
  dim_xMiddle.v := DimXMiddle / ColWidth;
  dim_yMiddle.v := DimYMiddle / RowHeight;
  AreaMiddle.v := DimXMiddle * DimYMiddle;
  RasterData.x_arr[0] := ColWidth / 2;
  for i := 1 to trunc(dim_x.v) + 1 do
    RasterData.x_arr[i] := RasterData.x_arr[i - 1] + ColWidth;
  RasterData.y_arr[0] := RowHeight / 2;
  for i := 1 to trunc(dim_y.v) + 1 do
    RasterData.y_arr[i] := RasterData.y_arr[i - 1] + RowHeight;

  vol_Element := ColWidth * RowHeight; { Volumen eines Rechenelements [cm3] }
  wm := theta.v * vol_Element; { Wassermenge eines Rechenelements
    [cm3*cm3 }
  { Berechnung der initial in den Rechenelementen enthaltenen Konzentration aus
    der initialen N-Menge im Boden. Zu diesem Zeitpunkt haben sämtliche Rechenelemente, egal
    ob in der Mitte oder in den Rändern die gleichen Konz. Berechnung o.k. }
  InitConc;
  NAmount.v := Mg_func(Depth.v, theta.v, c_start.v); // Debuggen
  c_av.v := avg_conz;
  // N_AmountSoil.v := mg_func(Tiefe.v, Theta.v, c_av.v);//Debuggen
  int_dt.v := ini_dt.v; // Zuweisung der Startzeitschrittweite ...

  Area.v := DimensionX.v * DimensionY.v;
  { Fläche der zu untersuchenden Schicht
    mit Rändern. }
  volume.v := Area.v * Depth.v;
  { Volumen der betrachteten Bodenschicht[cm3] }
  { Berechnung Mineralisationsrate in [Mol/cm^3*d] }
  Min_S.v := NMinerRate_kgNha.v / 14 * 1000 / 86400 * 1 / (Depth.v * 1E8);
  // Initialisieren der Visuallisierung der Nährstoffaufnahme


    { Ausschluss der Ränder; sollte nicht durchgeführt werden, da die Wurzeln zwar
    vorhanden sein und auch Aufnahme durchführen sollten, aber nicht berücksichtigt
    werden sollten }
  if DelMarginRoots.Option = 'yes' then
    RasterData.removeMarginRoots;
//  RasterData.calcNumberConsRoots;


  If ((MyMathImage <> nil) and (ShowConc.Option = 'true')) then
  begin
    MyMathImage.d3WorldX1 := RasterData.x_arr[1];
    MyMathImage.d3WorldXW := RasterData.x_arr[trunc(dim_x.v)];
    MyMathImage.d3WorldY1 := RasterData.y_arr[1];
    MyMathImage.d3WorldYW := RasterData.y_arr[trunc(dim_y.v)];
    MyMathImage.d3Worldz1 := 0; // min_c;
    MyMathImage.d3WorldzW := max_c * 1.2;

    If ColorSurface = nil then
      ColorSurface := TColorSurface.Create(trunc(dim_x.v) - 1,
        trunc(dim_y.v) - 1)
    else
    begin
      ColorSurface.Free;
      ColorSurface := TColorSurface.Create(trunc(dim_x.v) - 1,
        trunc(dim_y.v) - 1)
    end;
    MyMathImage.d3DrawAxes('x', 'y', 'z', 5, 5, 5, 0, 0, 0, true);
    MyMathImage.d3drawfullworldbox;
  end;

  If wl_ha.v > 0.0 then
  begin
    { Berechnung scheint korrekt s. Manuskript Hängeregister Vgl 1D2D }
    Imax.v := NUptakeratepot.v / 14 * 1000 / wl_ha.v;
    { Berechnung Influxrate [mol/(cm/d)] }
    // Imax.V := Ar.v*1000/(14*86400*WL_ha.v);  //Debuggen
  end
  else
    Imax.v := 0.0;
  // Ausgabe von XY-Koord. bei statischem Modell
  if iniMethod.Option <> 'submodstruct' then
    fillChartRootDistr;
  showActConc;



  InitConc;

end;


procedure TSubmodRoot2DNitrate.createSteadyState(DiffSteadyState: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Erzeugt einen Steady-State-Zustand nach folgendem Verfahren
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
begin
  { die gesamte aufgenommene Menge wird gleichmäßig auf alle Rechenelemente verteilt: }
  for i := 0 to trunc(dim_x.v + 1) do
    for j := 0 to trunc(dim_y.v + 1) do
    begin
      C_xy[i, j] := C_xy[i, j] + DiffSteadyState;
    end;
end;



function TSubmodRoot2DNitrate.avg_conz: double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:  Berechnung von Durchschnittskonzentrationen
  Problem: Sollen randständige Rechenelemente von Berechnung ausgeschlossen werden?
  Quelltext hierfür in Programmiertagebuch vorhanden.
  ------------------------------------------------------------------------------ *)
var
  i, j,
  { erstes und letztes Rechenelement das nicht im Rand liegt, jeweils in x und y-
    Richtung }
  numb1stElemX, numbLastElemX, numb1stElemY, numbLastElemY: integer;
  conc: double;

begin
  min_c := 1E100;
  max_c := 0.0;
  conc := 0.0;
  if CalcModeSteadyState.Option = 'withMargin' then
  begin
    { Randständige Zeilen und Spalten werden berücksichtigt. }
    for i := 1 to trunc(dim_x.v) - 1 do
      for j := 1 to trunc(dim_y.v) - 1 do
      begin
        // Aufsummerieren der Konzentrationen sämtlicher Rechenelemente:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Mitteln: Teilen durch die Summe der Elemente }
    conc := conc / (dim_x.v * dim_y.v);
  end
  else // wenn die Ränder nicht berücksichtigt werden sollen.
  begin
    numb1stElemX := trunc((dim_x.v - dim_xMiddle.v) / 2);
    numbLastElemX := trunc(dim_x.v - (dim_x.v - dim_xMiddle.v) / 2);
    numb1stElemY := trunc((dim_y.v - dim_yMiddle.v) / 2);
    numbLastElemY := trunc(dim_y.v - (dim_y.v - dim_yMiddle.v) / 2);
    for i := numb1stElemX to numbLastElemX - 1 do
      for j := numb1stElemY to numbLastElemY - 1 do
      begin
        // Aufsummerieren der Konzentrationen sämtlicher Rechenelemente:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Mitteln: Teilen durch die Summe der mittigen Elemente }
    conc := conc / ((numbLastElemX - numb1stElemX) *
      (numbLastElemY - numb1stElemY));
  end;
  Result := conc;
end;


function TSubmodRoot2DNitrate.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: alternative Berechnung des Influx mit Michaelis-Menten-Randbedingung
  unter der Voraussetzung, dass im Einzelwurzelzylinder mit dem quasistationären
  Ansatz gearbeitet wird.
  entspricht dem 2D-S Ansatz (erweitert um Michaelis-Menten-Kinetik). Berechnung
  vor allem der Formel für cla muss noch einmal kontrolliert werden.
  ------------------------------------------------------------------------------ *)
var
  cla, // Konzentration an der Wurzeloberfläche
  influx, // Nährstoffinfluxrate [mol cm^-1 d^-1]
  numerator // Zähler in Gleichung 3.6.33, Diss. Kage
    : double;
begin
  numerator := Km + (sqr(x) * Imax / ((sqr(x) - sqr(RootRadius.v)) * 2 * pi *
    Db)) * ln(x / RootRadius.v) - Imax / (4 * pi * Db);
  cla := clmin.v + (-ClAv + numerator) / 2;
  cla := cla + sqrt(sqr(ClAv + numerator) / 4 + ClAv * Km);
  influx := Imax * (cla - clmin.v) / (Km + (cla - clmin.v));
  If (influx <= 0.0) or (ClAv <= 0.0) // Keine negativen Flüsse
  then
    influx := 0.0;
  Result := influx;
end;

function TSubmodRoot2DNitrate.calcAmountUptakeRoots: double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Summe aus den kumulierten N-Aufnahmen aller gültigen Wurzeln (im
  Beobachtungsfenster vorhanden, aber nicht in den Rändern). Eigentlich Ratenbe-
  rechnung, aber notwendig, da nicht alle Wurzeln berücksichtigt werden sollen.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  NAmountRoot: double;

begin
  NAmountRoot := 0;
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootObjectIn2D(RasterData.RootList.Objects[i]).x >= verticMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(RasterData.RootList.Objects[i]).y >= horizMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      NAmountRoot := NAmountRoot + convertConcToAmount(i);
    end;
  end;
  { Teilen durch areaMiddle -> Aufnahme bezogen auf Quadratcentimenter, Multiplika-
    tion mit 10^8 -> Aufnahmemenge bezogen auf bestimmte Tiefe und ha. }
  Result := NAmountRoot / AreaMiddle.v * 1E8; // 10 hoch 8 cm^2 pro ha
  { Warum geht das nicht:
    Sum_N_AmountRoots.V:=Sum_N_AmountRoots.V+Ar.v; }
end;

function TSubmodRoot2DNitrate.convertConcToAmount(i: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rechnet die Aufnahme [mol/cm*d] in Menge [kg/d], für übergebene
  Wurzeln.
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000;
var
  ha: integer;
  NAmountRoot: double;
begin
  { NINflux in [mol/cm/d }
  NAmountRoot := TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux * kg_mol * Depth.v * int_dt.v;
  Result := NAmountRoot;
end;

function TSubmodRoot2DNitrate.calcActArdt: double;
(* ------------------------------------------------------------------------------
  Berechnet die Aktuelle im internen Zeitschritt:
  Aufnahmerate, wobei nur Wurzeln berücksichtigt werden,
  die sich nicht in den Rändern befinden. Zur Berechnung der Einheiten: Bezug auf
  den Hektar wird geleistet, indem auf die wl_ha bezogen wird.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  AvNMenge, AVInflux: double;
  rootCounter: integer;
begin
  rootCounter := 0;
  AvNMenge := 0;
  AVInflux := 0;
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootObjectIn2D(RasterData.RootList.Objects[i]).x >= verticMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(RasterData.RootList.Objects[i]).y >= horizMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      AVInflux := AVInflux + TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux;
      AvNMenge := AvNMenge + TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount;
      inc(rootCounter);
    end;
  end;
  if number_consid_roots.v <> 0 then
  begin
    AVInflux := AVInflux / number_consid_roots.v;
    // Berücksichtigt nur den Influx aus dem letzten internen Zeitschritt:
    Result := AVInflux * 14 / 1000 * wl_ha.v * int_dt.v;
    // Result:= AvInflux*14/1000*wl_ha.v
    // AvNMenge:=AvNMenge/rootCounter;
    // ActAr.v := AvNMenge*wl_ha.v;
  end;
end;




end.
