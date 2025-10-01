/// <summary>
///   defines some base classes for 2 dimensional water and nitrate transport equations
/// </summary>

unit U2DSoilBaseClasses;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid, MathImge,
  UMod, UState, Diffko, SubmodRootStructureNew;

//const
  /// <summary>Maximum number of roots.</summary>
//  max_num_roots = 40000;

type
  MathFloat = double;

const
  /// <summary>largest index, required for the vectors during the flux calculation</summary>
  dim_max = 10000;


/// <summary>Color array for concentration display</summary>
colorarray: array [0 .. 11] of TColor = ($00CB9F74, $00D8AD49, $00E6C986,
    $00F2E3C1, $00DAF0C4, $00A6E089, $0086D560, $0065CFB5, $008DC5FC, $0075D5FD,
    $0078E1ED, $00ACEDF4);

type

/// <summary>Floating point type for coordinates</summary>
  TMyFloatPoint = double;

/// <summary>re defines a floating point type</summary>
  real = double;

  /// <summary>Problem: the dynamic implementation was removed again due to difficulties with array boundaries.</summary>
  array_type = array [0 .. dim_max + 1] of real;

  /// <summary>
  /// Mode of nitrogen uptake by the root: Michaelis-Menten (saturation kinetics),
  /// fixed_influx assumes a constant sink strength, ZeroSink represents unlimited
  /// sink strength (black hole).
  /// </summary>
  TUptake_Function = (MM, fixed_influx, ZeroSink);


  /// <summary>Lean, memory-saving version of an SRP
  ///  used in the 2d diffusion model for interface with the structural root model
  /// TSRP instances of the single root model also need fields for area and the
  /// vertex list so that, when reading raster data, the surface area can be
  /// determined (using Voronoi polygons or alternatively by splitting the area of
  /// raster cells among the roots contained in them. Units may be an issue)
  /// </summary>
  TSRPLight = class(TObject)
  private
    /// <summary>Private declarations</summary>

  protected

  public
    /// <summary>Root coordinates x [cm] and root length density of the SRP [cm/cm^3]</summary>
    x : real;

    /// <summary>Root coordinates y [cm]</summary>
    y : real;

    /// <summary>Root length density of the SRP [cm/cm^3]</summary>
    RLD : real;

    /// <summary>Surface area of the single root cylinder [cm^2]</summary>
    area: double;

    /// <summary>List of polygon vertices</summary>
    vertexList: TList;
  public
    /// <summary>Public declarations</summary>
    /// <summary>Access to the fields: set and get methods</summary>
  end;

   /// <summary>TSRPLight plus some extra fields for nitrate transport calculations </summary>
  TSRPLightNitrate = class(TSRPLight)
  private

  protected
  public
    /// <summary>Mean nitrate concentration</summary>
    Cl_mean: double;
    /// <summary>N amount in the EWZ at the beginning</summary>
    init_NAmount: double;
  public
    /// <summary>Public declarations</summary>
    /// <summary>Access to the fields: set and get methods</summary>
  end;


  /// <summary>
  ///   Defines an object for storing the information of
  ///  a single root object
  ///  x and y are the floating point type coordinate
  ///  xi and yi are the index integers for the cell of a 2-D grid object
  ///  the root object is located
  /// </summary>
  TRootPosition = class(TObject)
    x: real;
    y: real;
    xi, yi: integer;
    root: integer;

    /// <summary>
    ///  the area of the single root cylinder [cm²]
    /// </summary>
    area : real;

    /// <summary>
    /// the nitrate influx rate of that root [mol/cm/s]
    /// </summary>
    NInflux : real;

    /// <summary>
    /// the water influx rate of that root [cm3/cm/s]
    /// </summary>
    WInflux: real;

    /// <summary>
    /// the sum of nitrate nitrogen [mol]
    /// </summary>
    SumNAmount: real;

    /// <summary>
    /// the nitrate uptake rate [mol/s]
    /// </summary>
    NAmountdt : real;
  end;


/// <summary>
///  forward declaration
/// </summary>
  TBaseSubmodRootDiff = class;

  /// <summary>
  /// Declaration of class TRasterData. This class encapsulates the raster,
  /// positions and the number of read and randomized data (WAP). It enables
  /// display in the tabs RasterData and RootDistribution. The class also
  /// handles file access.
  /// </summary>
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

    /// <summary>
    /// Root numbers in the raster (computational) cells.
    /// There can be more than one root per cell
    /// The array is needed for
    /// reading and displaying the number of roots in grid cells
    /// </summary>
    CountArr: array of array of integer;

    /// <summary> Stores information on all roots in the form of TRootposition entries</summary>
    PosList: TStringList;
  private
    /// <summary>Private declarations</summary>
  protected
    /// <summary>Protected declarations</summary>
    ///
    ///
  public
    { Public declarations }
    /// <summary> Reference to the diffusion submodel the raster data object belongs to</summary>
    SubmodRootDiff: TBaseSubmodRootDiff;

    /// <summary>Constructor</summary>
    constructor create(Submodel: TBaseSubmodRootDiff);

    /// <summary>Reads aggregated raster data and generates random positions</summary>
    procedure readRasterData(fn: string; var Series: TPointSeries);

    /// <summary>Reads exact XY coordinates from a file</summary>
    procedure readXYfromFile(Filename: TFilename;
      var Series: TPointSeries); virtual;

    /// <summary>Saves generated root coordinates to a file</summary>
    procedure saveRootPositions(SaveDialog: TSaveDialog);


  published
   /// <summary>Published declarations</summary>
   /// <summary>Clears the Pos array members</summary>
   /// procedure ErasePosList;
  end; { Ende Deklaration TRasterData }


/// <summary>Declaration of class TBaseSubmodRootDiff. Base class for derived 2d and 1d diffusion models
///  applied to a 2D area
/// Functionality of the base class: all models can read raster data, exclude
/// margins from calculations and display the data in the appropriate tabs of the
/// Hume form. The 1D models does not output in the 3D plot tab.
/// derived model simulate 2D water and nitrogen transport
///  or apply for comparison 1D approaches to the same problem
///  </summary>
  TBaseSubmodRootDiff = class(TSubmodel)
  private

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

    /// <summary>
    ///   a dynamic list with single root objects located on the 2-D plane of interest
    /// </summary>
    TSRPLightList: TList; // List with TSRPLight instances

    /// <summary>Reference to the AdvStringGrid in the Hume form for displaying raster data</summary>
    fMyAdvStringGrid: TAdvStringGrid;

    /// <summary>Reference to the structural root model</summary>
    fMyStructModel: TSubmodRootStrucNew;

  protected

/// <summary>Protected declarations</summary>
/// <summary> contains the x and y coordinates of the center of the container in container mode</summary>
    contposx: real;
    contposy: real;


    /// <summary>
    ///   sum of internal time steps
    /// </summary>
    SumOfInternalTimeSteps: double;

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

/// <summary> VWC_xy: array for volumetric water content in the computational elements.
/// WC_xy was declared as a dynamic array (see NG, p.65 ff) because the size of
///      the array should be declared with values of dim_x and dim_y (number of
///      computational elements in the x and y directions) that are assigned later.
/// </summary>

    VWC_xy: array of array of double;

/// <summary>
///   In x_arr and y_arr are the 'midpoint coordinates of the grid cells'
/// </summary>
    x_arr, y_arr: array of double;

    /// <summary> text file for writing xy data </summary>
    xyfile: textfile;

    /// <summary> Object for displaying the root intersection points in the Hume form TChart object </summary>
    SeriesXY: TPointSeries;

    /// <summary> Area of the whole soil section of interest [cm2]
    ///  is handled as a constant
    /// </summary>
    Area: TVar;

    /// <summary>RasterData instance owned by the submodel</summary>
    RasterData: TRasterData;

    /// <summary>Indicates whether initialization has already occurred</summary>
    initialised: boolean;

    /// <summary>Width of the computational domain [cm]</summary>
    dimensionX: TPar;
    /// <summary>Height of the computational domain [cm]</summary>
    dimensionY: TPar;

    /// <summary>Width of the raster grid (aggregated data) in x-direction [cm]</summary>
    gridWidth: TPar;

    /// <summary>Width of the raster grid (aggregated data) in y-direction [cm]</summary>
    gridHeight: TPar;

    /// <summary>number of elements in X-direction</summary>
    dim_x: TPar;

    /// <summary>number of elements in Y-direction</summary>
    dim_y:TPar;

    /// <summary>Maximum time step width [s]</summary>
    max_dt: TPar;

    /// <summary> Initial volumetric water content [cm3/cm3]</summary>
    IniTheta: TPar;

    /// <summary>radius of the container in container mode</summary>
    ContRad: TPar;

    /// <summary>Depth of the layer [cm], assumption for mineralization calculation</summary>
    /// <remarks>Mineralization model not yet available but should be implemented for both models</remarks>
    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>
    /// <summary>Vertical margin [cm]</summary>
    Depth: TPar;

    /// <summary>Vertical margin [cm]</summary>
    verticMargin: TPar;
    /// <summary>Horizontal margin [cm]</summary>
    horizMargin: TPar;

    /// <summary>Depth at which evaluation should begin (in the 2D cross-section) [cm]</summary>
    depthLayer: TPar;

    /// <summary>Thickness of the layer [cm]</summary>
    SizeLayer: TPar;

    /// <summary>Mean root length density [cm/ccm]</summary>
    ParMRLD: TPar;

    /// <summary>average Radius of the roots [cm]</summary>
    RootRadius: TPar;

/// <summary>grid width in X-direction [cm]</summary>
    dx: TVar;

/// <summary>grid width in Y-direction [cm]</summary>
    dy: TVar;

    /// <summary>Mean root length density in a layer [cm/cm^3] calculated without roots located in the margins</summary>
    RLD_mean: TVar;

    /// <summary>Central area without margins [cm2]</summary>
    AreaMiddle: TVar;

    /// <summary>Number of roots in center and margins [n]</summary>
    num_roots: TVar;

    /// <summary>Number of roots not located in margins []</summary>
    number_consid_roots: TVar;

    /// <summary>Volume of the soil layer including margins [cm3]</summary>
    Volume: TVar;

    /// <summary>actual volumetric water content [cm3/cm3]</summary>
    theta: TVar;

    /// <summary>Measure of error for regular distribution = number of roots that do not fit into the observation window when generating the uniform distribution, as a percentage of all roots [%]</summary>
    errorReg: TVar;

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
    ///   Average distance between roots [cm]
    /// </summary>
    AvDistance: TVar;



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

    /// <summary>Distributes roots evenly across the grid</summary>
    procedure CalcEqualDistribution;

    /// <summary>Distributes roots in a hexagonal pattern</summary>
    procedure distributeHexagonRow;

    /// <summary>Distributes roots in a hexagonal pattern</summary>
    procedure distributeHexagonCol;
    /// <summary>Writes output to a file</summary>
    procedure writeOutputToFile; virtual;

    /// <summary>Removes roots that are in the margins</summary>
    procedure removeMarginRoots;

    /// <summary>Updates root data from the structural root model</summary>
    procedure updateFromStructModell; virtual;

    /// <summary>Calculates the grid cell indices for each root position</summary>
    procedure CalcRootPosAsIndex;

    /// <summary>Calculates the number of roots that are within the observation window but not in the margins</summary>
    procedure calcNumberConsRoots;

    /// <summary>Tests if roots are located within the border</summary>
    procedure testForContBorder(var start_, ende_: integer;
  x_ndx, y_ndx: integer; zeile: boolean);
      function calcAbsValue2D(vect: r2): double;
    function vectorSubtrakt2D(vect2, vect1: r2): r2;

  public

    hasWritten: boolean;

/// <summary> create all objects</summary>
    procedure createAll; override;
//    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobModReferenz: TMod); override;

    /// <summary>Calculates rates</summary>
    procedure CalcRates; override;

    /// <summary>Performs integration</summary>
    procedure Integrate; override;

    /// <summary>Initializes the submodel</summary>
    procedure init(var GlobMod: TMod); override;
    // Set and get methods

    /// <summary>Returns the RasterData instance</summary>
    function getRasterData: TRasterData;
  published
    /// <summary>Published declarations</summary>
    // Publication of properties in the object inspector.

    /// <summary>Property for accessing the TChart object in the Hume form</summary>
    property MyChart: TChart read fMyChart write fMyChart;

    /// <summary>Property for accessing the TAdvStringGrid object in the Hume form</summary>
    property MyAdvStringGrid: TAdvStringGrid read fMyAdvStringGrid
      write fMyAdvStringGrid;

    /// <summary>Property for accessing the TSubmodRootStrucNew object in the Hume form</summary>
    property MyStructModel: TSubmodRootStrucNew read fMyStructModel
      write fMyStructModel;

  end; { Ende Deklaration TSubmodRootDiff }

  /// <summary>Function for calculating mineralisation rate </summary>
  function Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): real;

  /// <summary>Function for calculating nitrate concentration </summary>
  function Cl_func(Tiefe_cm, theta, NMenge: real): real;



implementation


/// <summary>
/// Implementation of the methods of TRasterData
/// </summary>
constructor TRasterData.create(Submodel: TBaseSubmodRootDiff);
var
  i: integer;
begin
  { The RasterData instance knows its submodel }
  SubmodRootDiff := Submodel;
  PosList := TStringlist.create;
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
  NewRoot : TRootPosition;

begin
  PosList.Clear;
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

  setLength(CountArr, trunc(NCols));
  for i := 0 to NRows-1 do
  begin
    setLength(CountArr[i], trunc(NRows));
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
        NewRoot := TRootPosition.create;
        // randomize;     // [What does Randomize do?]
        NewRoot.x := (Col) * DimCols + Random * DimCols;
        NewRoot.y := (Row) * DimRows + Random * DimRows;
//        PosArr[AllRoot].root := AllRoot;
        self.PosList.AddObject(IntToStr(AllRoot), NewRoot);
        Series.AddXY(NewRoot.x, NewRoot.y);
        Inc(AllRoot);
      end;
    end;
  end;
  { The model and the RasterData object know the total number of roots }
  TBaseSubmodRootDiff(SubmodRootDiff).num_roots.v := AllRoot;
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
  NewRoot : TRootPosition;
  i: integer;


begin
  self.PosList.Clear;
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
      NewRoot := TRootPosition.create;
      Readln(F, NewRoot.x, NewRoot.y, NewRoot.root,
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

      self.PosList.AddObject(intToStr(i), NewRoot);
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
  ActRoot : TRootPosition;
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
    for root := 0 to self.PosList.Count -1 do
      ActRoot := TRootPosition(self.PosList.Objects[root]);
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
procedure TBaseSubmodRootDiff.createAll;
begin
  inherited createAll;
  SeriesXY := TPointSeries.create(self);
  initialised := false;
  RasterData := TRasterData.create(self);
  // Create and initialize TPar
  ParCreate('dimensionX', '[cm]', 100, dimensionX, 'width of the area in x direction');
  ParCreate('dimensionY', '[cm]', 100, dimensionY, 'height of the area in y direction');
  ParCreate('gridWidth', '[cm]', 5, gridWidth, 'width of the grid cells');
  ParCreate('gridHeight', '[cm]', 5, gridHeight, 'height of the grid cells');
  ParCreate('max_dt', '[s]', 0, max_dt, 'maximum time step');
  ParCreate('IniTheta', '[cm3/cm3]', 0.2, IniTheta, 'initial volumetric water content');
  ParCreate('Tiefe', '[cm]', 10, Depth, 'depth of the layer');
  { Note: the original value was in micromol/l }
  ParCreate('verticMargin', '[cm]', 0, verticMargin, 'vertical margin');
  ParCreate('horizMargin', '[cm]', 0, horizMargin, 'horizontal margin');
  ParCreate('depthLayer', '[cm]', 0, depthLayer, 'depth of the layer');
  ParCreate('SizeLayer', '[cm]', 10, SizeLayer, 'size of the layer');
  ParCreate('ParMRLD', '[cm/ccm]', 0, ParMRLD, 'mean root length density');
  ParCreate('RootRadius', '[cm]', 0, RootRadius, 'root radius');
  ParCreate('dim_x', '[n]', 500, dim_x, 'dimension in x direction');
  ParCreate('dim_y', '[n]', 500, dim_y, 'dimension in y direction');
  ParCreate('ContRad', '[cm]', 10, ContRad, 'radius of the container in container mode');
  // Create and initialize TState

  VarCreate('dx', '[cm]', 0, false, dx, 'grid width in X-direction');
  VarCreate('dy', '[cm]', 0, false, dy, 'grid width in Y-direction');
  VarCreate('RLD_mean', '[cm/cm^3]', 0, false, RLD_mean,
    'mean root length density in a layer');
  VarCreate('AreaMiddle', '[cm2]', 0, false, AreaMiddle, 'central area without margins');
  VarCreate('num_roots', '[-]', 0, false, num_roots, 'number of roots in center and margins');
  VarCreate('number_consid_roots', '[-]', 0, false, number_consid_roots,
    'number of considered roots, i.e. without margin roots');
  VarCreate('theta', '[cm3/cm3]', 0, false, theta, 'actual volumetric water content');
  VarCreate('errorReg', '[%]', 0, false, errorReg,
    'measure of error for regular distribution');
  VarCreate('int_dt', '[d]', 0, false, int_dt, 'internal time step');
  VarCreate('wl_ha', '[cm/ha]', 0, false, wl_ha, 'root length per hectar');
  VarCreate('Wl', '[cm/ha]', 0, false, Wl, 'root length per hectar');
  VarCreate('AvDistance', 'cm', 0, false, AvDistance, 'Average distance between roots');

  VarCreate('dim_xMiddle', '[d]', 0, false, dim_xMiddle, 'dimension in x direction');
  VarCreate('dim_yMiddle', '[d]', 0, false, dim_yMiddle, 'dimension in y direction');

  ConstCreate('Area', '[cm²]', 0, false, Area, 'Area of the container');
  ConstCreate('Volume', '[cm/m³]', 0, false, Volume, 'Volume of the container');

  OptCreate('RootDistribution', 'Random', RootDistribution,
    'Type of root distribution');
  RootDistribution.OptionList.Add('Random');
  RootDistribution.OptionList.Add('Regular');
  // Verteilung wie in Quelle (Datei, Strukturmodell)
  RootDistribution.OptionList.Add('FromSource');


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
procedure TBaseSubmodRootDiff.init(var GlobMod: TMod);
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

  contposx := 50; // not yet clear why this value has to be 50
  contposy := 50;

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
  area.v := dimensionX.v * dimensionY.v;
  { Area of the layer under investigation }
  Volume.v := area.v * Depth.v;

  theta.v := IniTheta.v;
  { Implementation of a check for previous initialization. This allows easy extension
    for initializations requiring file access or object instantiation. This should be
    done in the _init method. Initializations should only be performed when roots
    have already been read. The original TSubmodel method cannot be used because it
    is called multiple times. }

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

    // take the input parameter as mean root length density
    RLD_mean.v := ParMRLD.v;
    // calculation of the number of roots
    num_roots.v := RLD_mean.v * area.v;

    // copy the number of roots to the RasterData object
    RasterData.NRoots := trunc(num_roots.v);

    // calculate positions of the roots according to a regular distribution
    CalcEqualDistribution;
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
  begin
    for i := 0 to trunc(num_roots.v) - 1 do
    begin
      TRootPosition(RasterData.PosList.Objects[i]).x :=
        Random(trunc(dim_x.v) - 2) + 2;
      TRootPosition(RasterData.PosList.Objects[i]).y :=
        Random(trunc(dim_y.v) - 2) + 2;
    end;
  end;

  If (RootDistribution.Option = 'regular') and (num_roots.v <> 0) then
  begin
    CalcEqualDistribution;
  end;

  // calculation of index values for each root position
  // needed for further calculations
  if num_roots.v <> 0 then
  begin
    CalcRootPosAsIndex;
  end;

  // roots inside the margins are removed
  calcNumberConsRoots;

  // several algorithms should only consider roots not located in the margins
  if RootDistribution.Option = 'Regular' then
  begin
    // the area has to be adapted because roots in the margins are not considered
    AreaMiddle.v := 1 / RLD_mean.v * number_consid_roots.v;
  end;
  { Nur im Fall der gleichmäßigen Verteilung soll die ursprünglich übergebene WLD
    verwendet werden, ansonsten soll eine neue RLD berücksichtigt werden, wobei nur
    Wurzeln eingehen, die nicht in den Rändern liegen. }
  if (RootDistribution.Option <> 'regular') or (IniMethod.Option = 'xyfile')
  then
  begin
    // RLD_mean has also to be calculated when borders are considered
    if AreaMiddle.v <> 0 then
      RLD_mean.v := number_consid_roots.v / AreaMiddle.v;
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
  { alternativ: alle Wurzeln werden berücksichtigt:
    wl.v:= RLD_mean.v*Flaeche.V*tiefe.v;
    wl_ha.v:= RLD_mean.v*1e8*tiefe.v;     { Wurzellängen auf einem Hektar [cm/ha]
    1e8 = Zentimeter auf ha }

end;

/// <summary> Only for further definition ..  </summary>
procedure TBaseSubmodRootDiff.CalcRates;
begin
  inherited;
  { inherited is commented out because integration in the derived submodels is
    partially performed using an analytical solution. }
  // inherited;

end;



/// <summary> Method overridden to successively change the time step width. </summary>
procedure TBaseSubmodRootDiff.Integrate;
begin
  inherited;
  { inherited is commented out because integration in the derived submodels is
    partially performed using an analytical solution. }
  // inherited;

end;

/// <summary>Both models can display roots in the RootDistribution tab.</summary>
procedure TBaseSubmodRootDiff.fillChartRootDistr;
var
  i: integer;
  ActRoot : TRootPosition;
begin
  SeriesXY.Clear;
  // Fill the series object.
  for i := 0 to self.RasterData.PosList.count-1 do
  begin
    ActRoot := TRootPosition(self.RasterData.PosList.Objects[i]);
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
procedure TBaseSubmodRootDiff.fillGridRasterData;
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

/// <summary>
/// Writes coordinates and areas of PosArr to a file. With a structural model, output
/// occurs at each time step; with static root positions only at the start of the
/// model run. For testing in the static case, the positions of roots in the margins
/// are also written.
/// </summary>
procedure TBaseSubmodRootDiff.writeOutputToFile;
var
  i, j: integer;
  { Only sinks that are not in the margin and observation window are output.
    PosArr_middle should already contain only these roots }
  PosArr_middle: Array of TRootPosition;
  ActRoot : TRootPosition;
begin
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  { In the case of the structural model (dynamic change of root positions) output
    occurs at every time step }
  if IniMethod.Option = 'SubmodStruct' then
  begin
    j := 0;
    for i := 0 to trunc(RasterData.NRoots)-1 do
      ActRoot := TRootPosition(self.RasterData.PosList.Objects[i]);
    begin
      // Point not in vertical margins
      if (ActRoot.x >= verticMargin.v) and
        (ActRoot.x <= dimensionX.v - verticMargin.v)
      // Point not in horizontal margins
        and (ActRoot.y >= horizMargin.v) and
        (ActRoot.y <= dimensionY.v - horizMargin.v) then
      begin
        PosArr_middle[j].x := ActRoot.x;
        PosArr_middle[j].y := ActRoot.y;
        PosArr_middle[j].xi := ActRoot.xi;
        PosArr_middle[j].yi := ActRoot.yi;
//        PosArr_middle[j].NInflux := ActRoot.NInflux;
        PosArr_middle[j].WInflux := ActRoot.WInflux;
        PosArr_middle[j].root := ActRoot.root;
        PosArr_middle[j].area := ActRoot.area;
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
      for i := 0 to trunc(RasterData.NRoots)-1 do
      begin
        // Point not in vertical margins
      ActRoot := TRootPosition(self.RasterData.PosList.Objects[i]);
        if (ActRoot.x >= verticMargin.v) and
          (ActRoot.x <= dimensionX.v - verticMargin.v)
        // Point not in horizontal margins
          and (ActRoot.y >= horizMargin.v) and
          (ActRoot.y <= dimensionY.v - horizMargin.v) then
        begin
          PosArr_middle[j].x := ActRoot.x;
          PosArr_middle[j].y := ActRoot.y;
          PosArr_middle[j].xi := ActRoot.xi;
          PosArr_middle[j].yi := ActRoot.yi;
//          PosArr_middle[j].NInflux := ActRoot.NInflux;
          PosArr_middle[j].WInflux := ActRoot.WInflux;
          PosArr_middle[j].root := ActRoot.root;
          PosArr_middle[j].area := ActRoot.area;
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
      write(xyFile, 'Punkte in R�ndern:');
      writeln(xyFile);
      write(xyFile, 'Lfd.Nr.', ' ', 'X', ' ', 'y', ' ', 'Flaeche', ' ');
      writeln(xyFile);
      for i := 0 to trunc(RasterData.NRoots)-1 do
      begin
        ActRoot := TRootPosition(self.RasterData.PosList.Objects[i]);

        // Point not in vertical margins
        if (ActRoot.x < verticMargin.v) or
          (ActRoot.x > dimensionX.v - verticMargin.v)
        // Point not in horizontal margins
          or (ActRoot.y < horizMargin.v) or
          (ActRoot.y > dimensionY.v - horizMargin.v) then
        begin
          write(xyFile, ActRoot.root, ' ');
          write(xyFile, ActRoot.x, ' ');
          write(xyFile, ActRoot.y, ' ');
          write(xyFile, ActRoot.area, ' ');
          writeln(xyFile);
        end;
      end;
      hasWritten := true;
      closeFile(xyFile);
    end;
  end;

end;

/// <summary>
/// All diffusion models can compute a uniform distribution from a given one. The
/// method distributes points based on a given WLD evenly over an area. The
/// TPointSeries object of the calling HUME GUI method is refilled so the display
/// can be updated. Different methods were created for this purpose and can be
/// switched here.
/// </summary>
procedure TBaseSubmodRootDiff.CalcEqualDistribution;
var
  radSRP, // Radius SRP
  AreaSRP // Fl�che SRP
    : double;
begin
  { If RLD is read as a parameter, the number of roots in the observation window
    still has to be calculated }
  radSRP := 1 / sqrt(Pi * ParMRLD.v);
  AreaSRP := Pi * sqr(radSRP);
  num_roots.v := dimensionX.v * dimensionY.v / AreaSRP;
  RasterData.NRoots := trunc(num_roots.v);
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
procedure TBaseSubmodRootDiff.distributeHexagonRow;
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
  NewPosition : TRootPosition;

begin
  inherited;
  self.RasterData.PosList.Clear;
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
//  RasterData.errasePosArr; // Delete old entries. Problem: necessary???
  // number_row := 1;           // Start at row 1
  number_row := 0; // Start at row 0
  { Caveat: PosArr begins at 1 }
  j := 0;
  i := 0;
  errorRoot := 0;
  errorReg.v := 0;
  while i <= trunc(num_roots.v)-1 do
  begin
    if (number_row mod 2 <> 0) then // odd rows
    begin
      // Calculation for odd rows:
      pos_x := ((j * 2 + 1) * Rad_AK + j * edgeHexagon);
      pos_y := Rad_IK * number_row;
      if (pos_x <= dimx) and (pos_y <= dimy) then
      // As long as the point remains within the calculation area
      begin
        NewPosition := TRootPosition.create;
//        NewPosition.create;
        NewPosition.x := pos_x;
        NewPosition.x := pos_y;
        NewPosition.root := i;
        NewPosition.area := Area_Polygon;
        RasterData.PosList.AddObject(IntToStr(i), NewPosition);
 //       TRootPosition(RasterData.PosList.objects[i]).x := pos_x;
 //       TRootPosition(RasterData.PosList.objects[i]).y := pos_y;
 //       TRootPosition(RasterData.PosList.objects[i]).root := i;
        { It is assumed that the area of the hexagon corresponds to the area of the
          Voronoi polygon. Points within the polygon would then be closer to the central
          sink than to any other sink. }
        { This point is not entirely consistent since PosArr could also be used for the
          calculations. }
 //       TRootPosition(RasterData.PosList.objects[i]).area := Area_Polygon;
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
        NewPosition := TRootPosition.create;
        NewPosition.x := pos_x;
        NewPosition.x := pos_y;
        NewPosition.root := i;
        NewPosition.area := Area_Polygon;
        RasterData.PosList.AddObject(IntToStr(i), NewPosition);
//        TRootPosition(RasterData.PosList.objects[i]).x := pos_x;
//        TRootPosition(RasterData.PosList.objects[i]).y := pos_y;
//        TRootPosition(RasterData.PosList.objects[i]).root := i;
//        TRootPosition(RasterData.PosList.objects[i]).area := Area_Polygon;
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
end;

/// <summary>
/// Distribution using hexagons. Columns are filled sequentially. The method may be
/// advantageous when nutrient uptake in layers is calculated (this still needs
/// verification). The distribution was adjusted: X-values were shifted half a Rad_AK
/// to the right and Y-values half a Rad_AK upward (see slide Filling columns 2).
/// CAVE: method not up to date and should be improved based on distributeHexagonRow
/// (e.g., calculation of ErrorReg).
/// </summary>
procedure TBaseSubmodRootDiff.distributeHexagonCol;
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
  NewPosition: TRootPosition;
begin
  inherited;
  self.RasterData.PosList.Clear;
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
//  RasterData.errasePosArr; // Delete old entries. Issue: necessary???
  // number_col := 1;           // Start at column 1
  number_col := 0; // Start at column 0
  j := 0;
  { Caveat: PosArr begins at 1 }
  i := 0;
  while i <= trunc(num_roots.v)-1 do
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
        NewPosition.root := i;
        NewPosition.area := Area_Polygon;
        RasterData.PosList.AddObject(IntToStr(i), NewPosition);

//        TRootPosition(RasterData.PosList.objects[i]).x := pos_x;
//        TRootPosition(RasterData.PosList.objects[i]).y := pos_y;
//        TRootPosition(RasterData.PosList.objects[i]).root := i;
        { It is assumed that the area of the hexagon corresponds to the area of the
          Voronoi polygon. Points within the polygon would then be closer to the central
          sink than to any other sink. }
//        TRootPosition(RasterData.PosList.objects[i]).area := Area_Polygon;
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
        NewPosition := TRootPosition.create;
        NewPosition.x := pos_x;
        NewPosition.x := pos_y;
        NewPosition.root := i;
        NewPosition.area := Area_Polygon;
        RasterData.PosList.AddObject(IntToStr(i), NewPosition);
//        TRootPosition(RasterData.PosList.objects[i]).x := pos_x;
//        TRootPosition(RasterData.PosList.objects[i]).y := pos_y;
//        TRootPosition(RasterData.PosList.objects[i]).root := i;
//        TRootPosition(RasterData.PosList.objects[i]).area := Area_Polygon;
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

/// <summary>
/// Calculates the number of valid/considered roots (located in the observation window but
/// not in the margins).
/// </summary>
procedure TBaseSubmodRootDiff.calcNumberConsRoots;
var
  rootcount, i: integer;
begin
  rootcount := 0;
  number_consid_roots.v := 0;
  // number_consid_roots.V := RasterData.NRoots; // initially accept all roots
  { Determine the number of roots to consider (for setting array bounds).
    The input parameters for the margins are relative values that must be
    related to the observation window dimensionX, dimensionY. }
  for i := 0 to RasterData.NRoots-1 do
  begin
    // Point not in vertical margins
//    if (TRootPosition(RasterData.PosList.objects[i]).x >= verticMargin.v) and
    if (TRootPosition(RasterData.PosList.Objects[i]).x >= verticMargin.v) and
//      (TRootPosition(RasterData.PosList.objects[i]).x <= dimensionX.v - verticMargin.v)
      (TRootPosition(RasterData.PosList.Objects[i]).x <= dimensionX.v - verticMargin.v)
    // Point not in horizontal margins
//      and (TRootPosition(RasterData.PosList.objects[i]).y >= horizMargin.v) and
      and (TRootPosition(RasterData.PosList.Objects[i]).y >= horizMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).y <= dimensionY.v - horizMargin.v) then
    begin
      Inc(rootcount);
      number_consid_roots.v := rootcount;
    end;
  end;
  // Debugging
  // showMessage(self.SubModName+': '+floatToStr(number_consid_roots.V));
end;


/// <summary>Removes roots located in the margins from the Pos array</summary>
procedure TBaseSubmodRootDiff.removeMarginRoots;
var
  i, j: integer;
  { Dynamic array that temporarily stores roots not located in the margins }
  PosArr_middle: Array of TRootPosition;
begin
  // Remove 'invalid' roots
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  j := 0;
  // Fill PosArr_middle
  for i := 0 to trunc(RasterData.NRoots)-1 do
  begin
    // Point not in vertical margins
    if (TRootPosition(RasterData.PosList.objects[i]).x >= verticMargin.v) and
      (TRootPosition(RasterData.PosList.objects[i]).x <= dimensionX.v - verticMargin.v)
    // Point not in horizontal margins
      and (TRootPosition(RasterData.PosList.objects[i]).y >= horizMargin.v) and
      (TRootPosition(RasterData.PosList.objects[i]).y <= dimensionY.v - horizMargin.v) then
    begin
      PosArr_middle[j].x := TRootPosition(RasterData.PosList.objects[i]).x;
      PosArr_middle[j].y := TRootPosition(RasterData.PosList.objects[i]).y;
      PosArr_middle[j].xi := TRootPosition(RasterData.PosList.objects[i]).xi;
      PosArr_middle[j].yi := TRootPosition(RasterData.PosList.objects[i]).yi;
      PosArr_middle[j].NInflux := TRootPosition(RasterData.PosList.objects[i]).NInflux;
      PosArr_middle[j].WInflux := TRootPosition(RasterData.PosList.objects[i]).WInflux;
      PosArr_middle[j].root := TRootPosition(RasterData.PosList.objects[i]).root;
      PosArr_middle[j].area := TRootPosition(RasterData.PosList.objects[i]).area;
      Inc(j);
    end;
  end;
  // Delete old PosArr
  RasterData.PosList.Clear;
  j := 1;
  // Write back values from the temporary PosArr
  for i := 0 to high(PosArr_middle) do
  begin
    TRootPosition(RasterData.PosList.objects[i]).x := PosArr_middle[i].x;
    TRootPosition(RasterData.PosList.objects[i]).y := PosArr_middle[i].y;
    TRootPosition(RasterData.PosList.objects[i]).xi := PosArr_middle[i].xi;
    TRootPosition(RasterData.PosList.objects[i]).yi := PosArr_middle[i].yi;
    TRootPosition(RasterData.PosList.objects[i]).NInflux := PosArr_middle[i].NInflux;
    TRootPosition(RasterData.PosList.objects[i]).WInflux := PosArr_middle[i].WInflux;
    TRootPosition(RasterData.PosList.objects[i]).root := PosArr_middle[i].root;
    TRootPosition(RasterData.PosList.objects[i]).area := PosArr_middle[i].area;
    Inc(j);
  end;
  RasterData.NRoots := trunc(number_consid_roots.v);
end;

function TBaseSubmodRootDiff.getRasterData: TRasterData;
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


procedure TBaseSubmodRootDiff.testForContBorder(var start_, ende_: integer;
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
    for i := 1 to trunc(dim_x.v) do // determine the start cell
    begin
      upperLeft[0] := (i - 1) * dx.v;
      upperLeft[1] := (y_ndx - 1) * dy.v;
      bottomRight[0] := (i) * dx.v;
      bottomRight[1] := (y_ndx) * dy.v;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > ContRad.v) and (distBottomRight < ContRad.v) then
      begin
        start_ := i;
        cutContWall := true;
        break; // break necessary because only the first occurrence is used
      end;

    end;
    for i := trunc(dim_x.v) downto 1 do // determine the start cell
    begin
      upperLeft[0] := (i - 1) * dx.v;
      upperLeft[1] := (y_ndx - 1) * dy.v;
      bottomRight[0] := (i) * dx.v;
      bottomRight[1] := (y_ndx) * dy.v;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > ContRad.v) and (distBottomRight < ContRad.v) then
      begin
        ende_ := i;
        break; // break necessary because only the first occurrence is used
      end;

    end;
  end
  else // columns are scanned
  begin
    for i := 1 to trunc(dim_y.v) do // determine the start cell
    begin
      upperLeft[0] := (x_ndx - 1) * dx.v;
      upperLeft[1] := (i - 1) * dy.v;
      bottomRight[0] := (x_ndx - 1) * dx.v;
      bottomRight[1] := (i) * dy.v;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > ContRad.v) and (distBottomRight < ContRad.v) then
      begin
        start_ := i;
        cutContWall := true;
        break; // break necessary because only the first occurrence is used
      end;

    end;
    for i := trunc(dim_y.v) downto 1 do // determine the start cell
    begin
      upperLeft[0] := (x_ndx - 1) * dx.v;
      upperLeft[1] := (i - 1) * dy.v;
      bottomRight[0] := (x_ndx - 1) * dx.v;
      bottomRight[1] := (i) * dy.v;
      VektUppLeft_ContCent[0] := self.ContPosx - upperLeft[0];
      VektUppLeft_ContCent[1] := self.ContPosy - upperLeft[1];
      VektBottRight_ContCent[0] := self.ContPosx - bottomRight[0];
      VektBottRight_ContCent[1] := self.ContPosy - bottomRight[1];
      distUpperLeft := calcAbsValue2D(VektUppLeft_ContCent);
      distBottomRight := calcAbsValue2D(VektBottRight_ContCent);
      if (distUpperLeft > ContRad.v) and (distBottomRight < ContRad.v) then
      begin
        ende_ := i;
        break; // break necessary because only the first occurrence is used
      end;

    end;
  end;
  if (cutContWall = false) and (zeile = true) then
  begin
    start_ := 1;
    ende_ := trunc(dim_x.v);
  end;
  if (cutContWall = false) and (zeile = true) then
  begin
    start_ := 1;
    ende_ := trunc(dim_y.v);
  end;

end;


function TBaseSubmodRootDiff.calcAbsValue2D(vect: r2): double;
(* ------------------------------------------------------------------------------
  Calculates the magnitude = length of a vector
  ------------------------------------------------------------------------------ *)
var
  length: double;
begin
  length := sqrt(sqr(vect[0]) + sqr(vect[1]));
  Result := length;
end;

function TBaseSubmodRootDiff.vectorSubtrakt2D(vect2, vect1: r2): r2;
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


procedure TBaseSubmodRootDiff.updateFromStructModell;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Dynamische Verknüpfung von Struktur und Funktionsmodell,
  Möglichkeit des Einlesens von SRPs, die im Strukturmodell generiert wurden
  da es sich um sehr viele Instanzen handelt habe ich nicht den Weg über externe
  Variablen gewählt.
  ------------------------------------------------------------------------------ *)
var
  ATSRPLight: TSRPLight;
  i, j, numberRoots: integer;
begin
  // alte Einträge in PosArr löschen
  RasterData.PosList.Clear;
  TSRPLightList := MyStructModel.getSRPList;
  Num_Roots.v := TSRPLightList.Count;
  // Füllen des Pos-Arrays mit XY-Koordinaten
  j := 0;
  for i := 0 to TSRPLightList.Count - 1 do
  begin
    ATSRPLight := TSRPLightList.Items[i];
    TRootPosition(RasterData.PosList.Objects[j]).x := ATSRPLight.x;
    TRootPosition(RasterData.PosList.Objects[j]).y := ATSRPLight.y;
    TRootPosition(RasterData.PosList.Objects[j]).root := j;
    inc(j);
  end;
  // Umwandlung der XY-Koordinaten
  if Num_Roots.v <> 0 then
  begin
    calcRootPosAsIndex;
  end;
end;


procedure TBaseSubmodRootDiff.calcRootPosAsIndex;
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
begin
  for i := 0 to trunc(Num_Roots.v)-1 do
  begin
    xTemp := TRootPosition(RasterData.PosList.Objects[i]).x;
    yTemp := TRootPosition(RasterData.PosList.Objects[i]).y;
    TRootPosition(RasterData.PosList.Objects[i]).xi := min(trunc(dim_x.v) - 1,
      max(1, round(TRootPosition(RasterData.PosList.Objects[i]).x / (trunc(DimensionX.v)) *
      trunc(dim_x.v))));
    TRootPosition(RasterData.PosList.Objects[i]).yi := min(trunc(dim_y.v) - 1,
      max(1, round(TRootPosition(RasterData.PosList.Objects[i]).y / (trunc(DimensionY.v)) *
      trunc(dim_y.v))));
    // Rückspeichern
    TRootPosition(RasterData.PosList.Objects[i]).x := xTemp;
    TRootPosition(RasterData.PosList.Objects[i]).y := yTemp;
  end;
end;




end.
