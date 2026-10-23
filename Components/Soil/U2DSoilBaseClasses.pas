/// <summary>
///   defines some base classes for 2 dimensional water and nitrate transport equations
/// </summary>

unit U2DSoilBaseClasses;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid, MathImge,
  UMod, UState, URootObject, Diffko,
  URootUptakeFunctions, URootVoronoi;

//const
  /// <summary>Maximum number of roots.</summary>
//  max_num_roots = 40000;

type
  /// <summary>Root-file input failure with filename and row context.</summary>
  ERootInputError = class(EInOutError);

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

  /// <summary>Shared geometry of the computational grid, independent of roots and transported substances.</summary>
  TRasterData = class(TObject)
  private
    /// <summary>Vertical and horizontal margins [cm] excluded from the central area.</summary>
    fverticMargin,
    /// <summary>Vertical and horizontal margins [cm] excluded from the central area.</summary>
    fhorizMargin: real;
    /// <summary>Width and height of the computational domain [cm].</summary>
    fDimensionX,
    /// <summary>Width and height of the computational domain [cm].</summary>
    fDimensionY: real;
    /// <summary>Width and height of the central area [cm].</summary>
    fdim_xMiddle,
    /// <summary>Width and height of the central area [cm].</summary>
    fdim_yMiddle,
    /// <summary>Area of the central area [cm2].</summary>
    fAreaMiddle: real;
    /// <summary>Radius of the circular container [cm]; zero disables the circular mask.</summary>
    fContRad: real;

  protected
    /// <summary>Legacy midpoint indices of the central area, including helper slots 0 and N+1.</summary>
    ndim_xMiddle,
    /// <summary>Legacy midpoint indices of the central area, including helper slots 0 and N+1.</summary>
    ndim_yMiddle: integer;

    /// <summary>radius of the container in container mode</summary>


  public
    /// <summary>Numbers of computational columns and rows.</summary>
    NCols, NRows: integer;
    /// <summary>Cell widths in the x and y directions [cm].</summary>
    ColWidth, RowHeight: double;
    /// <summary>Centre of the circular container [cm].</summary>
    contposx, contposy: real;
    /// <summary>Legacy midpoint coordinates [cm], including helper slots 0 and N+1.</summary>
    x_arr, y_arr: array of double;
    constructor Create;
    /// <summary>Initializes geometry only; field values are initialized separately.</summary>
    procedure Init(NCols, NRows: word; ColWidth, RowWidth,
      verticMargin, horizMargin, ContRad: real);

    /// <summary>Extracts the middle region of the grid.</summary>
    procedure ExtractMiddle;

    /// <summary>Tests if a cell is on the border of the circular container.</summary>
    procedure testForContBorder(var start_, ende_: integer;
      x_ndx, y_ndx: integer; zeile: boolean);
    function calcAbsValue2D(vect: r2): double;
    function vectorSubtrakt2D(vect2, vect1: r2): r2;
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


    /// <summary>Depth of the layer [cm], assumption for mineralization calculation</summary>
    /// <remarks>Mineralization model not yet available but should be implemented for both models</remarks>
    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>
    /// <summary>Vertical margin [cm]</summary>
    Depth: TPar;

    /// <summary>Mean root length density [cm/ccm]</summary>
    ParMRLD: TPar;

    /// <summary>average Radius of the roots [cm]</summary>
    RootRadius: TPar;

    /// <summary>Radius of the container [cm].</summary>
    ContRad: TPar;

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
    ///   Amount of water in the object [cm]
    /// </summary>
    WAmount: TState;

    /// <summary>
    ///   Average distance between roots [cm]
    /// </summary>
    AvDistance: TVar;


    /// <summary> create all objects</summary>
    procedure createAll; override;
//    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobModReferenz: TMod); override;



    /// <summary>Initializes the submodel</summary>
    procedure Init(var GlobMod: TMod); override;
    // Set and get methods

  published
    /// <summary>Published declarations</summary>
    // Publication of properties in the object inspector.

  end; { Ende Deklaration TSubmodRootDiff }


  /// <summary>Shared computational and root geometry; no transport calculation.</summary>
  TSubmodRoot2D = class(TSubmodRootBase)
  private
    /// <summary>One persistent random realization per RootDistribution selection.
    /// Normalized positions permit domain resizing without drawing a new realization.</summary>
    FRandomRootSites: TVoronoiPolygon;
    FRandomRootSeed: Integer;
    FRandomRootSeedReady: Boolean;
    FLastRootDistribution: string;
    FReadingRootInput: Boolean;
    /// <summary>Fit file roots and margins into a zero-based computational domain.</summary>
    procedure FitRootInputDomain;
    /// <summary>Place every imported root in centered regular rows inside the observation area.</summary>
    procedure ArrangeImportedRootsRegular;
  protected


   /// <summary>RasterData instance owned by the submodel</summary>
    RasterData: TRasterData;
  protected


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

    /// <summary>Legacy source alias for RootInpDataFile; not a separate option.</summary>
    RootInpDataFileXY: TOption;

    /// <summary>Root input file: .xy coordinates or .grid raster counts.</summary>
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


    /// <summary>Root input metadata and aggregated observation grid, separate from computational geometry.</summary>
    DescStr: string;
    Date: TDateTime;
    RootRasterNCols, RootRasterNRows: integer;
    RootRasterColWidth, RootRasterRowHeight: double;
    CountArr: array of array of integer;
    /// <summary>Root collection shared by the water and nitrate calculations.</summary>
    RootList: TStringList;
    NRoots: integer;
    /// <summary>Cells indexed like RootList; rectangular domain, vertices [cm].</summary>
    VoronoiCells: TVoronoiCells;
    /// <summary>Root-weighted population statistics for centres inside the observation window.</summary>
    VoronoiRadiusMean, VoronoiRadiusSD, VoronoiRadiusCV: TVar;
    /// <summary>Population CV of local RLD = 1/cell area, weighted equally per central root.</summary>
    VoronoiRLDCV: TVar;
    /// <summary>Area-weighted mean RLD [cm/cm3] and population CV [fraction], whole domain.
    /// Suitable moments for equal-volume 1-D PDF classes; mean equals N/total area.</summary>
    VoronoiAreaMeanRLD, VoronoiAreaRLDCV: TVar;
    /// <summary>Rebuild cells after changing root positions; all roots compete, margins excluded only from statistics.</summary>
    procedure CalculateRootVoronoi;

    /// <summary>Fills the chart with root distribution data</summary>
    procedure fillChartRootDistr;

    /// <summary>Fills the AdvStringGrid with aggregated raster data</summary>
    procedure fillGridRasterData;

    /// <summary>Reads raster data from a file and fills the given TPointSeries</summary>
    procedure readRasterData(fn: string; var Series: TPointSeries);

    /// <summary>Reads XY root data from a file and fills the given TPointSeries</summary>
    procedure readXYfromFile(Filename: TFilename; var Series: TPointSeries); virtual;

    /// <summary>Writes XY root data to a file</summary>
    procedure saveRootPositions(SaveDialog: TSaveDialog);

    /// <summary>Calculates the mean root length density in the central area, excluding margins</summary>
    procedure CalcEqualDistribution(RLD: real);

    /// <summary>distributes root positions in a hexagonal row</summary>
    procedure distributeHexagonRow;

    /// <summary>distributes root positions in a hexagonal column</summary>
    procedure distributeHexagonCol;

    /// <summary>Writes output to a file</summary>
    procedure WriteOutputToFile(fn: string; Time: real); virtual;
    
    /// <summary>Removes roots that are located in the margins of the computational domain</summary>
    procedure removeMarginRoots;

    /// <summary>Calculates random root positions</summary>
    procedure CalcRandomRootPositions;

    /// <summary>Calculates root positions as indices</summary>
    procedure CalcRootPosAsIndex;
    /// <summary>Updates observation-window root counts, density and length.</summary>
    procedure RefreshRootStatistics;
    destructor Destroy; override;

    /// <summary>Returns the RasterDataH2O instance</summary>


    /// <summary>Returns the RasterData instance</summary>
    function getRasterData: TRasterData;

    /// <summary> creates all objects and initializes the submodel </summary>
    procedure createAll; override;

    /// <summary>Loads simulation inputs, geometry, roots and domain quantities.</summary>
    procedure Init(var GlobMod: TMod); override;

  published

      /// <summary>Property for accessing the TChart object in the Hume form</summary>
    property MyChart: TChart read fMyChart write fMyChart;

    /// <summary>Property for accessing the TMathImage object in the Hume form</summary>
    property MyMathImage: TMathImage read fMyMathImage write fMyMathImage;
    
    /// <summary>Property for accessing the TAdvStringGrid object in the Hume form</summary>
    property MyAdvStringGrid: TAdvStringGrid read fMyAdvStringGrid
      write fMyAdvStringGrid;

    /// <summary>Property for accessing the TSubmodRootStrucNew object in the Hume form</summary>
//    property MyStructModel: TSubmodRootStrucNew read fMyStructModel
//      write fMyStructModel;

end; // TSubmodRoot2D

  /// <summary>Function for calculating mineralisation rate </summary>
  function Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): real;

  /// <summary>Function for calculating nitrate concentration </summary>
  function Cl_func(Tiefe_cm, theta, NMenge: real): real;



implementation



/// <summary>
/// Implementation of the methods of TRasterData
/// </summary>
constructor TRasterData.Create;
begin
  inherited Create;
  contposx := 50;
  contposy := 50;
end;

procedure TRasterData.Init(NCols, NRows: word; ColWidth, RowWidth,
  verticMargin, horizMargin, ContRad: real);
var
  i: integer;
begin
  self.NCols := NCols;
  self.NRows := NRows;
  self.ColWidth := ColWidth;
  self.RowHeight := RowWidth;
  fContRad := ContRad;
  fDimensionX := ColWidth * NCols;
  fDimensionY := RowWidth * NRows;
  fverticMargin := verticMargin;
  fhorizMargin := horizMargin;
  SetLength(x_arr, NCols + 2);
  SetLength(y_arr, NRows + 2);
  for i := 0 to NCols + 1 do
    x_arr[i] := (i + 0.5) * ColWidth;
  for i := 0 to NRows + 1 do
    y_arr[i] := (i + 0.5) * RowWidth;
end;

procedure TSubmodRoot2D.readRasterData(fn: string; var Series: TPointSeries);
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
  Readln(F, RootRasterNRows); { Third line: number of rows }
  Readln(F, RootRasterNCols); { Fourth line: number of columns }
  Readln(F, RootRasterRowHeight); { Fifth line: row height [cm] }
  Readln(F, RootRasterColWidth); { Sixth line: column width [cm] }

  setLength(CountArr, Integer(RootRasterNCols));
  for i := 0 to RootRasterNCols - 1 do
  begin
    setLength(CountArr[i], Integer(RootRasterNRows));
  end;

  // Repeatedly read data until end of file
  for Row := 0 to RootRasterNRows - 1 do
  begin { Read root counts into CountArr }
    for Col := 0 to RootRasterNCols - 1 do
      read(F, CountArr[Col, Row]);
    Readln(F); // New line
  end;
  closeFile(F);
  AllRoot := 0; // Start at 0 because PosArr begins at 0.
  { Randomly distribute roots in each grid cell }
  for Col := 0 to RootRasterNCols - 1 do
  begin
    for Row := 0 to RootRasterNRows - 1 do
    begin
      { Exactly as many roots are assigned to PosArr as were read into CountArr. }
      for root := 0 to CountArr[Col, Row]-1 do
      begin
        NewRoot := TRootObjectIn2D.create;
        // randomize;     // [What does Randomize do?]
        NewRoot.x := (Col) * RootRasterColWidth + Random * RootRasterColWidth;
        NewRoot.y := (Row) * RootRasterRowHeight + Random * RootRasterRowHeight;
        NewRoot.nroot := root;
//        PosArr[AllRoot].root := AllRoot;
        self.RootList.AddObject(IntToStr(AllRoot), NewRoot);
        if Assigned(Series) then Series.AddXY(NewRoot.x, NewRoot.y);
        Inc(AllRoot);
      end;
    end;
  end;
  { The model and the RasterData object know the total number of roots }
  num_roots.v := AllRoot;
  self.NRoots := AllRoot;

end;

/// <summary>
/// Reads XY coordinates from a file and successively fills the passed
/// (call-by-reference) PointSeries object with the XY pairs.
/// </summary>
procedure TSubmodRoot2D.readXYfromFile(Filename: TFilename;
  var Series: TPointSeries);
var Lines, Pending: TStringList; Tokens: TArray<string>; R: TRootObjectIn2D;
  I, LineNumber: Integer; FS: TFormatSettings; AreaValue: Double;
  function Number(const Token, Field: string): Double;
  var Value: string;
  begin
    Value := Token;
    if Pos('.', Value) = 0 then Value := StringReplace(Value, ',', '.', [rfReplaceAll]);
    if not TryStrToFloat(Value, Result, FS) or IsNan(Result) or IsInfinite(Result) then
      raise ERootInputError.CreateFmt('Root XY file "%s", line %d: invalid %s "%s".',
        [Filename, LineNumber, Field, Token]);
  end;
begin
  Lines := TStringList.Create;
  Pending := TStringList.Create;
  Pending.OwnsObjects := True;
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := #0;
  try
    try
      Lines.LoadFromFile(Filename);
    except on E: Exception do
      raise ERootInputError.CreateFmt('Cannot read root XY file "%s": %s', [Filename, E.Message]);
    end;
    /// <summary>The first line is a header. Rows contain x, y, integer root ID,
    /// and area in the last column. Accept whitespace and dot/comma decimals.</summary>
    for I := 1 to Lines.Count-1 do begin
      LineNumber := I+1;
      if Trim(Lines[I]) = '' then Continue;
      Tokens := Trim(Lines[I]).Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
      if Length(Tokens) < 4 then
        raise ERootInputError.CreateFmt('Root XY file "%s", line %d: expected x y root-ID area; found %d fields.',
          [Filename, LineNumber, Length(Tokens)]);
      R := TRootObjectIn2D.Create;
      try
        R.x := Number(Tokens[0], 'x coordinate');
        R.y := Number(Tokens[1], 'y coordinate');
        if not TryStrToInt(Tokens[2], R.nroot) then
          raise ERootInputError.CreateFmt('Root XY file "%s", line %d: invalid integer root-ID "%s".',
            [Filename, LineNumber, Tokens[2]]);
        AreaValue := Number(Tokens[High(Tokens)], 'area');
        if AreaValue <= 0 then
          raise ERootInputError.CreateFmt('Root XY file "%s", line %d: area must be positive.', [Filename, LineNumber]);
        if not FReadingRootInput and
           ((R.x < 0) or (R.x > dimensionX.v) or (R.y < 0) or (R.y > dimensionY.v)) then
          raise ERootInputError.CreateFmt('Root XY file "%s", line %d: coordinates are outside the %.6g x %.6g cm domain.',
            [Filename, LineNumber, dimensionX.v, dimensionY.v]);
        R.area := AreaValue;
        Pending.AddObject(IntToStr(Pending.Count), R);
        R := nil;
      finally R.Free; end;
    end;
    if Pending.Count = 0 then
      raise ERootInputError.CreateFmt('Root XY file "%s": no root rows after the header.', [Filename]);
    /// <summary>Commit only a fully validated file; avoid partial roots/chart on failure.</summary>
    RootList.Clear;
    RootList.Assign(Pending);
    Pending.OwnsObjects := False;
    NRoots := RootList.Count;
    num_roots.v := NRoots;
    if Assigned(Series) then begin
      Series.Clear;
      for I := 0 to RootList.Count-1 do begin
        R := TRootObjectIn2D(RootList.Objects[I]);
        Series.AddXY(R.x, R.y);
      end;
    end;
  finally
    Pending.Free;
    Lines.Free;
  end;
end;
/// <summary>
/// After reading aggregated root data, i.e. without exact coordinates, saves the generated random root
/// coordinates (considering assignment to a 5x5 cm grid cell) as floating point
/// numbers in a file.
/// </summary>
procedure TSubmodRoot2D.saveRootPositions(SaveDialog: TSaveDialog);
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
  SetEntityDeclarationClass(TSubmodRootBase);
  initialised := false;
  ParCreate('Ini_dt', '[d]', 1/240, Ini_dt, 'initial time step');
  ParCreate('max_dt', '[d]', 1/240, max_dt, 'maximum time step');
  ParCreate('IniTheta', '[cm3/cm3]', 0.2, IniTheta, 'initial volumetric water content');
  ParCreate('Depth', '[cm]', 10, Depth, 'depth of the layer');
  { Note: the original value was in micromol/l }
  ParCreate('ParMRLD', '[cm/ccm]', 0.5, ParMRLD, 'mean root length density');
  ParCreate('RootRadius', '[cm]', 0.02, RootRadius, 'root radius');
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

  StateCreate('WAmount', '[cm]', 0, false, WAmount, 'water storage per unit ground area');

  ConstCreate('Area', '[cm²]', 0, false, Area, 'Area of the container');
  ConstCreate('Volume', '[cm/m³]', 0, false, Volume, 'Volume of the container');

end;

procedure TSubmodRoot2D.createAll;

begin
  inherited createAll;
  SetEntityDeclarationClass(TSubmodRoot2D);
  RasterData := TRasterData.Create;
  RootList := TStringList.Create;
  RootList.OwnsObjects := true;
  // Create and initialize TPar
  ParCreate('dimensionX', '[cm]', 100, dimensionX, 'width of the area in x direction');
  ParCreate('dimensionY', '[cm]', 100, dimensionY, 'height of the area in y direction');
  ParCreate('gridWidth', '[cm]', 5, gridWidth, 'width of the grid cells');
  ParCreate('gridHeight', '[cm]', 5, gridHeight, 'height of the grid cells');

  ParCreate('verticMargin', '[cm]', 0, verticMargin, 'vertical margin');
  ParCreate('horizMargin', '[cm]', 0, horizMargin, 'horizontal margin');
  ParCreate('dim_x', '[n]', 500, dim_x, 'dimension in x direction');
  ParCreate('dim_y', '[n]', 500, dim_y, 'dimension in y direction');
  // Create and initialize TState

  VarCreate('VoronoiRLDCV', '[-]', 0, false, VoronoiRLDCV, 'Population CV of inverse Voronoi cell area (local RLD), central roots');
  VarCreate('VoronoiAreaMeanRLD', '[cm/cm3]', 0, false, VoronoiAreaMeanRLD, 'Area-weighted mean local RLD over all bounded cells, including margins');
  VarCreate('VoronoiAreaRLDCV', '[-]', 0, false, VoronoiAreaRLDCV, 'Area-weighted population CV of local RLD, including margins; fraction');
  VarCreate('VoronoiRadiusMean', '[cm]', 0, false, VoronoiRadiusMean, 'Mean equivalent Voronoi radius in observation window');
  VarCreate('VoronoiRadiusSD', '[cm]', 0, false, VoronoiRadiusSD, 'Population standard deviation of equivalent Voronoi radius');
  VarCreate('VoronoiRadiusCV', '[-]', 0, false, VoronoiRadiusCV, 'Population SD divided by mean equivalent Voronoi radius');
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
  IniMethod.OptionList.add('File');
  IniMethod.OptionList.add('XYFile');
  IniMethod.OptionList.add('RasterDataFile');
  IniMethod.OptionList.add('SubmodStruct');

  OptCreate('OutputXY', 'no', OutputXY, 'Output in XY format');
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Paths for model comparison 1D vs 2D }
  { Paths to input and output files are identical for both submodels. Running both
    submodels simultaneously in one model run only makes sense for comparison. }
  OptCreate('RootInpDataFile', 'Q:\Soil2D\InpData\abo130782.grid',
    RootInpDataFile, 'Root input data (.grid raster counts or .xy coordinates); used with file initialization');
  RootInpDataFile.IsFileInput := True;
  RootInpDataFile.FileFilter := 'Root input files (*.grid;*.xy)|*.grid;*.xy|Raster data (*.grid)|*.grid|XY coordinates (*.xy)|*.xy';
  /// <summary>Keep source compatibility without exposing a second filename option.</summary>
  RootInpDataFileXY := RootInpDataFile;
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\abo130782.grid');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\poly_11_1406_40_60cm_mod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_ges.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_10_30.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_20_40.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_30_50.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_40_60.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_50_70.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_60_80.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rand_dist_395.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rand_dist_755.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rand_dist_1360.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rld01_abw017.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rld01_abw17.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rld01_abw30.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rld001_abw05.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rld001_abw5.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\rld001_abw30.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_60_80ohneRand.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_oberBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_unterBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t3_3570.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t1_oberBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p2_t2_unterBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p15_t3_oberBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p15_t3_unterBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p15_t4_oberBod.xy');
  RootInpDataFile.OptionList.Add('Q:\Soil2D\InpData\p15_t4_unterBod.xy');
  OptCreate('RootXYOutpDataFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data',
    RootXYOutpDataFile, 'Root geometry snapshot filename (OutputXY); influx time series use separate output options');
  RootXYOutpDataFile.IsFileOutput := True;
  RootXYOutpDataFile.FileFilter := 'Root geometry files (*.xy)|*.xy|All files (*.*)|*.*';
  RootXYOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data');
end;


/// <summary>Performs various initializations</summary>
procedure TSubmodRootBase.Init(var GlobMod: TMod);
begin
  inherited Init(GlobMod);
  hasWritten := false;
  /// <summary>Internal solver steps must not overwrite the governing model timestep.</summary>
  int_dt.v := ini_dt.v;
  /// <summary>Shared root geometry; transport states are initialized by descendants.</summary>
  RLD_mean.v := ParMRLD.v;
  // root length in cm/m2
  wl.v := RLD_mean.v * 1E4 * Depth.v;
  // root length in cm/ha
  wl_ha.v := wl.v * 1E4;
end;


/// <summary>Translate input roots by the lower padded bounds. Preserve pairwise distances;
/// a degenerate axis receives at least one grid cell. Grid counts round upward.</summary>
procedure TSubmodRoot2D.FitRootInputDomain;
var I: Integer; R: TRootObjectIn2D;
  MinX, MaxX, MinY, MaxY, Width, Height, PaddingX, PaddingY: Double;
  NX, NY: Double;
begin
  if RootList.Count = 0 then
    raise ERootInputError.Create('Root input file contains no roots');
  R := TRootObjectIn2D(RootList.Objects[0]);
  MinX := R.x; MaxX := R.x; MinY := R.y; MaxY := R.y;
  for I := 1 to RootList.Count-1 do begin
    R := TRootObjectIn2D(RootList.Objects[I]);
    MinX := Min(MinX, R.x); MaxX := Max(MaxX, R.x);
    MinY := Min(MinY, R.y); MaxY := Max(MaxY, R.y);
  end;
  /// <summary>Vertical boundary strips pad X; horizontal boundary strips pad Y.</summary>
  Width := MaxX-MinX + 2*verticMargin.v;
  Height := MaxY-MinY + 2*horizMargin.v;
  if MaxX = MinX then Width := Max(Width, gridWidth.v + 2*verticMargin.v);
  if MaxY = MinY then Height := Max(Height, gridWidth.v + 2*horizMargin.v);
  NX := Width/gridWidth.v; NY := Height/gridWidth.v;
  if IsNan(NX) or IsInfinite(NX) or IsNan(NY) or IsInfinite(NY) or
     (NX > 65535) or (NY > 65535) then
    raise ERootInputError.Create('Root input domain exceeds the supported grid dimensions');
  PaddingX := (Width-(MaxX-MinX))/2;
  PaddingY := (Height-(MaxY-MinY))/2;
  dimensionX.v := Width; dimensionY.v := Height;
  dim_x.v := Max(1, Ceil(NX)); dim_y.v := Max(1, Ceil(NY));
  /// <summary>Use gridWidth as the requested resolution along both axes.</summary>
  gridHeight.v := gridWidth.v;
  for I := 0 to RootList.Count-1 do begin
    R := TRootObjectIn2D(RootList.Objects[I]);
    R.x := EnsureRange((R.x-MinX)+PaddingX, verticMargin.v, Width-verticMargin.v);
    R.y := EnsureRange((R.y-MinY)+PaddingY, horizMargin.v, Height-horizMargin.v);
  end;
end;

/// <summary>Preserve imported root count and IDs. Balance row populations so
/// neighboring rows differ by at most one root; center roots within each row.
/// Use the observation area so subsequent margin removal retains every root.</summary>
procedure TSubmodRoot2D.ArrangeImportedRootsRegular;
var
  Rows, Row, Col, Columns, Index, Count: Integer;
  Width, Height: Double;
  R: TRootObjectIn2D;
begin
  Count := RootList.Count;
  if Count = 0 then Exit;
  Width := dimensionX.v - 2*verticMargin.v;
  Height := dimensionY.v - 2*horizMargin.v;
  Rows := Max(1, Min(Count, Round(Sqrt(Count * Height / Width))));
  Index := 0;
  for Row := 0 to Rows-1 do begin
    Columns := Count div Rows;
    if Row < Count mod Rows then Inc(Columns);
    for Col := 0 to Columns-1 do begin
      R := TRootObjectIn2D(RootList.Objects[Index]);
      R.x := verticMargin.v + (Col+0.5)*Width/Columns;
      R.y := horizMargin.v + (Row+0.5)*Height/Rows;
      R.Area := Width*Height/Count;
      Inc(Index);
    end;
  end;
end;

/// <summary>Initializes shared grid and roots after the framework loads simulation inputs.</summary>
procedure TSubmodRoot2D.Init(var GlobMod: TMod);

var
  i: integer;
  LegacyFile, FileName: string;
  // Number of grid cells in X and Y direction
  numberGridCellsX, numberGridCellsY: integer;

begin
  LegacyFile := '';
  if (GlobMod <> nil) and (GlobMod.OptionIniFile <> nil) then
    if not GlobMod.OptionIniFile.ValueExists(Name, 'RootInpDataFile') or
       (SameText(GlobMod.OptionIniFile.ReadString(Name, 'IniMethod', ''), 'XYFile') and
        SameText(ExtractFileExt(GlobMod.OptionIniFile.ReadString(Name,
          'RootInpDataFile', '')), '.txt')) then
      LegacyFile := GlobMod.OptionIniFile.ReadString(Name, 'RootInpDataFileXY', '');
  inherited Init(GlobMod);
  FileName := RootInpDataFile.Option;
  if LegacyFile <> '' then FileName := LegacyFile;
  /// <summary>Old built-in input paths now refer to the relocated, typed files.</summary>
  if SameText(ExtractFilePath(FileName), 'Q:\Kohl\DiffModell\IniFilesAusgaben\') and
     SameText(ExtractFileExt(FileName), '.txt') then
  begin
    if SameText(ExtractFileName(FileName), 'abo130782.txt') then
      FileName := 'Q:\Soil2D\InpData\abo130782.grid'
    else
      FileName := 'Q:\Soil2D\InpData\' + ChangeFileExt(ExtractFileName(FileName), '.xy');
  end;
  if not SameText(FileName, RootInpDataFile.Option) then
  begin
    RootInpDataFile.Option := FileName;
    if GlobMod.OptionIniFile <> nil then
      GlobMod.OptionIniFile.WriteString(Name, 'RootInpDataFile', RootInpDataFile.Option);
  end;

  /// <summary>FromSource selected from parameter input means explicit XY roots.
  /// Preserve the requested distribution instead of silently generating a lattice.</summary>
  if (RootDistribution.Option = 'fromsource') and (IniMethod.Option = 'inppar') then
    IniMethod.Option := 'xyfile';

  /// <summary>Use the filename extension for both current and legacy file modes.</summary>
  if (IniMethod.Option = 'xyfile') or (IniMethod.Option = 'rasterdatafile') or
     (IniMethod.Option = 'file') then
  begin
    if SameText(ExtractFileExt(RootInpDataFile.Option), '.grid') then
      IniMethod.Option := 'rasterdatafile'
    else if SameText(ExtractFileExt(RootInpDataFile.Option), '.xy') then
      IniMethod.Option := 'xyfile'
    else
      raise ERootInputError.CreateFmt('Root input file "%s": expected .grid or .xy.',
        [RootInpDataFile.Option]);
  end;

  if (IniMethod.Option = 'xyfile') or (IniMethod.Option = 'rasterdatafile') then
  begin
    if IsNan(gridWidth.v) or IsInfinite(gridWidth.v) or (gridWidth.v <= 0) or
       IsNan(verticMargin.v) or IsInfinite(verticMargin.v) or (verticMargin.v < 0) or
       IsNan(horizMargin.v) or IsInfinite(horizMargin.v) or (horizMargin.v < 0) then
      raise ERootInputError.Create('Root input requires a positive gridWidth and nonnegative finite margins');
    FReadingRootInput := True;
    try
      if IniMethod.Option = 'xyfile' then
        readXYfromFile(RootInpDataFile.Option, SeriesXY)
      else
        readRasterData(RootInpDataFile.Option, SeriesXY);
      FitRootInputDomain;
    finally
      FReadingRootInput := False;
    end;
    /// <summary>File input defines the domain and count; retain the selected distribution.</summary>
  end;

  if (dim_x.v < 1) or (dim_x.v > 65535) or (Frac(dim_x.v) <> 0) or
     (dim_y.v < 1) or (dim_y.v > 65535) or (Frac(dim_y.v) <> 0) or
     (dimensionX.v <= 0) or (dimensionY.v <= 0) or
     (gridWidth.v <= 0) or (gridHeight.v <= 0) or (ParMRLD.v < 0) then
    raise EArgumentException.Create('Invalid root grid dimensions or root density');
  if (verticMargin.v < 0) or (horizMargin.v < 0) or
     (2*verticMargin.v >= dimensionX.v) or (2*horizMargin.v >= dimensionY.v) then
    raise EArgumentException.Create('Margins must leave a positive observation area');
  errorReg.v := 0;
  num_roots.v := RootList.Count;
  /// <summary>Initialize the shared computational geometry before locating roots.</summary>
  RasterData.Init(trunc(dim_x.v), trunc(dim_y.v),
    dimensionX.v / dim_x.v, dimensionY.v / dim_y.v,
    verticMargin.v, horizMargin.v, ContRad.v);
  RasterData.ExtractMiddle;
  dim_xMiddle.v := RasterData.fdim_xMiddle / RasterData.ColWidth;
  dim_yMiddle.v := RasterData.fdim_yMiddle / RasterData.RowHeight;
  if IniMethod.Option = 'inppar' then RootList.Clear;
  NRoots := RootList.Count;
  if IniMethod.Option = 'xyfile' then begin
    RootRasterNCols := Trunc(dim_x.v);
    RootRasterNRows := Trunc(dim_y.v);
    RootRasterColWidth := dimensionX.v / dim_x.v;
    RootRasterRowHeight := dimensionY.v / dim_y.v;
  end else if IniMethod.Option <> 'rasterdatafile' then begin
    RootRasterNCols := Trunc(dimensionX.v / gridWidth.v);
    RootRasterNRows := Trunc(dimensionY.v / gridHeight.v);
    RootRasterColWidth := gridWidth.v;
    RootRasterRowHeight := gridHeight.v;
  end;

  // Rewrite output file for XY coordinates
  if OutputXY.Option = 'yes' then
  begin
    AssignFile(xyfile, RootXYOutpDataFile.Option);
    rewrite(xyfile);
    closeFile(xyfile);
  end;


  // the number of grid cells for both dimensions
  numberGridCellsX := trunc(dimensionX.v / gridWidth.v);
  numberGridCellsY := trunc(dimensionY.v / gridHeight.v);


  // set the length of the CountArr array according to the number of grid cells
  // in X and Y direction
  // in a first step only the first dimension is set
  // in a second step the second dimension is set for each element of the first dimension
  if IniMethod.Option <> 'rasterdatafile' then begin
    SetLength(CountArr, 0);
    SetLength(CountArr, RootRasterNCols);
    for i := 0 to High(CountArr) do
      SetLength(CountArr[i], RootRasterNRows);
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
    fillGridRasterData;

  if IniMethod.Option = 'inppar' then begin
    NRoots := Trunc(ParMRLD.v * area.v);
  end;
  /// <summary>Only a distribution change starts a new random realization.
  /// Init may reset hydraulic states repeatedly while retaining root geometry.</summary>
  if not SameText(FLastRootDistribution, RootDistribution.Option) then begin
    SetLength(FRandomRootSites, 0);
    FRandomRootSeedReady := False;
  end;
  FLastRootDistribution := RootDistribution.Option;
  if RootDistribution.Option = 'random' then CalcRandomRootPositions
  else if (RootDistribution.Option = 'regular') and (NRoots > 0) then begin
    if (IniMethod.Option = 'xyfile') or (IniMethod.Option = 'rasterdatafile') then
      ArrangeImportedRootsRegular
    else
      CalcEqualDistribution(NRoots / area.v);
  end;
  CalcRootPosAsIndex;
  if (WithMargins.Option = 'withmargin') or (WithMargins.Option = 'true') then
    removeMarginRoots;
  RefreshRootStatistics;
  /// <summary>Imported density is roots per observation area, equivalent to root length per volume.</summary>
  if (IniMethod.Option = 'xyfile') or (IniMethod.Option = 'rasterdatafile') then
    ParMRLD.v := RLD_mean.v;
  CalculateRootVoronoi;
  Volume.v := Area.v * Depth.v;
  fillChartRootDistr;
end;

/// <summary>Legacy observation-window diagnostics; margin roots may still transport water/nitrate.</summary>
procedure TSubmodRoot2D.RefreshRootStatistics;
var I: Integer; R: TRootObjectIn2D;
begin
  NRoots := RootList.Count;
  num_roots.v := NRoots;
  number_consid_roots.v := 0;
  AreaMiddle.v := RasterData.fAreaMiddle;
  for I := 0 to RootList.Count - 1 do begin
    R := TRootObjectIn2D(RootList.Objects[I]);
    if (R.x >= verticMargin.v) and (R.x <= dimensionX.v-verticMargin.v) and
       (R.y >= horizMargin.v) and (R.y <= dimensionY.v-horizMargin.v) then
      number_consid_roots.v := number_consid_roots.v + 1;
  end;
  RLD_mean.v := 0;
  wl.v := 0;
  AvDistance.v := 0;
  if AreaMiddle.v > 0 then begin
    RLD_mean.v := number_consid_roots.v / AreaMiddle.v;
    if (RootDistribution.Option = 'regular') and (IniMethod.Option = 'inppar') and
       (number_consid_roots.v > 0) then RLD_mean.v := ParMRLD.v;
    wl.v := number_consid_roots.v / AreaMiddle.v * 1E4 * Depth.v;
  end;
  wl_ha.v := wl.v * 1E4;
  if RLD_mean.v > 0 then AvDistance.v := 1 / Sqrt(Pi * RLD_mean.v);
end;

/// <summary>Rectangular bounded cells and unweighted population moments of sqrt(area/pi).
/// Statistics exclude margin centres, but their cells still participate in construction.
/// Zero roots yield zero diagnostics. Does not modify legacy root area or transport geometry.</summary>
procedure TSubmodRoot2D.CalculateRootVoronoi;
var Sites: TVoronoiPolygon; Cells: TVoronoiCells; I, Count: Integer;
  R: TRootObjectIn2D; Mean, M2, Delta, Radius, RLD, RLDMean, RLDM2, MeanRLD, AreaRLDCV: Double;
begin
  SetLength(Sites, RootList.Count);
  for I := 0 to RootList.Count-1 do begin
    R := TRootObjectIn2D(RootList.Objects[I]);
    Sites[I].X := R.x; Sites[I].Y := R.y;
  end;
  Cells := BuildRootVoronoi(Sites, dimensionX.v, dimensionY.v);
  Count := 0; Mean := 0; M2 := 0; RLDMean := 0; RLDM2 := 0;
  for I := 0 to RootList.Count-1 do begin
    R := TRootObjectIn2D(RootList.Objects[I]);
    if (R.x >= verticMargin.v) and (R.x <= dimensionX.v-verticMargin.v) and
       (R.y >= horizMargin.v) and (R.y <= dimensionY.v-horizMargin.v) then begin
      if Cells[I].Area <= 0 then
        raise EArgumentException.Create('Local Voronoi RLD requires positive cell area');
      Inc(Count); Radius := Cells[I].EquivalentRadius;
      Delta := Radius-Mean; Mean := Mean+Delta/Count;
      M2 := M2+Delta*(Radius-Mean);
      RLD := 1/Cells[I].Area;
      Delta := RLD-RLDMean; RLDMean := RLDMean+Delta/Count;
      RLDM2 := RLDM2+Delta*(RLD-RLDMean);
    end;
  end;
  VoronoiCells := Cells;
  VoronoiAreaRLDMoments(Cells, MeanRLD, AreaRLDCV);
  VoronoiAreaMeanRLD.v := MeanRLD;
  VoronoiAreaRLDCV.v := AreaRLDCV;
  VoronoiRLDCV.v := 0;
  if (Count > 0) and (RLDMean > 0) then
    VoronoiRLDCV.v := Sqrt(Max(0, RLDM2/Count))/RLDMean;
  VoronoiRadiusMean.v := Mean;
  VoronoiRadiusSD.v := 0; VoronoiRadiusCV.v := 0;
  if Count > 0 then VoronoiRadiusSD.v := Sqrt(Max(0, M2/Count));
  if Mean > 0 then VoronoiRadiusCV.v := VoronoiRadiusSD.v/Mean;
end;
procedure TSubmodRoot2D.CalcRandomRootPositions;
var I, Count, SavedSeed: Integer; R: TRootObjectIn2D;
begin
  Count := NRoots;
  if not FRandomRootSeedReady then begin
    FRandomRootSeed := Random(MaxInt);
    FRandomRootSeedReady := True;
  end;
  if Length(FRandomRootSites) < Count then begin
    /// <summary>Extend deterministically from the retained seed. Existing root
    /// positions remain the same when density changes; preserve the global RNG.</summary>
    SavedSeed := RandSeed;
    try
      RandSeed := FRandomRootSeed;
      SetLength(FRandomRootSites, Count);
      for I := 0 to Count-1 do begin
        FRandomRootSites[I].X := Random;
        FRandomRootSites[I].Y := Random;
      end;
    finally
      RandSeed := SavedSeed;
    end;
  end;
  RootList.Clear;
  for I := 0 to Count - 1 do begin
    R := TRootObjectIn2D.Create;
    R.x := FRandomRootSites[I].X * dimensionX.v;
    R.y := FRandomRootSites[I].Y * dimensionY.v;
    R.nroot := I + 1;
    R.area := area.v / Count;
    RootList.AddObject(IntToStr(I), R);
  end;
end;

procedure TRasterData.ExtractMiddle;

begin
  // if Margin roots should not be considered only the middle area is used
  // for calculation of RLD etc.
    fdim_xMiddle := fDimensionX - 2 * fverticMargin;
    fdim_yMiddle := fDimensionY - 2 * fhorizMargin;
    fAreaMiddle  := fdim_xMiddle * fdim_yMiddle;

    // Berechnung der Anzahl der mittigen Rechenelemente
    ndim_xMiddle := trunc(fdim_xMiddle / ColWidth);
    ndim_yMiddle := trunc(fdim_yMiddle / RowHeight);
end;





/// <summary>Both models can display roots in the RootDistribution tab.</summary>
procedure TSubmodRoot2D.fillChartRootDistr;
var
  i: integer;
  ActRoot : TRootObjectIn2D;
begin
  if not Assigned(SeriesXY) then Exit;
  SeriesXY.Clear;
  // Fill the series object.
  for i := 0 to self.RootList.count-1 do
  begin
    ActRoot := TRootObjectIn2D(self.RootList.Objects[i]);
    SeriesXY.AddXY(ActRoot.x, ActRoot.y);
  end;
  /// <summary>Keep an already attached series on its chart when no separate chart is supplied.</summary>
  if Assigned(MyChart) and (SeriesXY.ParentChart <> MyChart) then
    MyChart.AddSeries(SeriesXY);
end;

/// <summary>
/// Both models can write aggregated root data to the form. The method fills the
/// aggregated root data (number of roots per grid cell) into the AdvStringGrid of
/// the Hume form.
/// </summary>
procedure TSubmodRoot2D.fillGridRasterData;
var
  Row, Col, SumRow, SumCol: integer;
begin
  if not Assigned(MyAdvStringGrid) then Exit;
  // Set grid size
  MyAdvStringGrid.ColCount := RootRasterNCols + 4;
  MyAdvStringGrid.RowCount := RootRasterNRows + 4;
  for Row := 1 to RootRasterNRows do
  begin
    { Calculate row sums }
    SumRow := 0;
    for Col := 1 to RootRasterNCols do
    begin
      MyAdvStringGrid.Cells[Col, Row] :=
        IntToStr(CountArr[Col - 1, Row - 1]);
      SumRow := SumRow + StrtoInt(MyAdvStringGrid.Cells[Col, Row]);
    end;
    MyAdvStringGrid.Cells[RootRasterNCols + 1, Row] := IntToStr(SumRow);
  end;

  For Col := 1 to RootRasterNCols do
  begin { Write column headers }
    MyAdvStringGrid.Cells[Col, 0] :=
      IntToStr((Col - 1) * trunc(RootRasterColWidth)) + ' - ' +
      IntToStr(Col * trunc(RootRasterColWidth));
  end;
  For Row := 1 to RootRasterNRows do
  begin { Write row headers }
    MyAdvStringGrid.Cells[0, Row] :=
      IntToStr((Row - 1) * trunc(RootRasterRowHeight)) + ' - ' +
      IntToStr(Row * trunc(RootRasterRowHeight));
  end;
  { Calculate column sums }
  for Col := 1 to RootRasterNCols do
  begin
    SumCol := 0; { Calculate column sums }
    for Row := 1 to RootRasterNRows do
    begin
      SumCol := SumCol + StrtoInt(MyAdvStringGrid.Cells[Col, Row]);
    end;
    MyAdvStringGrid.Cells[Col, RootRasterNRows + 1] := IntToStr(SumCol);
  end;
end;

/// <summary>
/// Writes coordinates and areas of PosArr to a file. With a structural model, output
/// occurs at each time step; with static root positions only at the start of the
/// model run. For testing in the static case, the positions of roots in the margins
/// are also written.
/// </summary>
procedure TSubmodRoot2D.WriteOutputToFile( fn:string; Time: real);

var
  i, j: integer;
  { Only sinks that are not in the margin and observation window are output.
    PosArr_middle should already contain only these roots }
  PosArr_middle: Array of TRootObjectIn2D;
  ActRoot: TRootObjectIn2D;
  xyfile: textfile;

begin
  setLength(PosArr_middle, trunc(number_consid_roots.v));
  j := 0;
  for i := 0 to NRoots - 1 do
  begin
    // Point not in vertical margins
    ActRoot := TRootObjectIn2D(RootList.Objects[i]);
    if (ActRoot.x >= RasterData.fverticmargin) and
      (ActRoot.x <= RasterData.fdimensionx - RasterData.fverticmargin)
    // Point not in horizontal margins
      and (ActRoot.y >= RasterData.fhorizmargin) and
      (ActRoot.y <= RasterData.fdimensiony - RasterData.fhorizmargin) then
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
    if (ActRoot.x < RasterData.fverticmargin) or
      (ActRoot.x > RasterData.fdimensionx - RasterData.fverticmargin)
    // Point not in horizontal margins
      or (ActRoot.y < RasterData.fhorizmargin) or
      (ActRoot.y > RasterData.fdimensiony - RasterData.fhorizmargin) then
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
procedure TSubmodRoot2D.CalcEqualDistribution(RLD:real);
var
  radSRP, // Radius SRP
  AreaSRP // Area SRP
    : double;
begin
  { If RLD is read as a parameter, the number of roots in the observation window
    still has to be calculated }
  radSRP := 1 / sqrt(Pi * RLD);
  AreaSRP := Pi * sqr(radSRP);
  NRoots := trunc(RasterData.fdimensionx * RasterData.fdimensiony / AreaSRP);
  if NRoots <= 0 then begin RootList.Clear; Exit; end;
  // Fill rows
  distributeHexagonRow;
  /// <summary>The legacy initializer selects row-oriented hexagons.</summary>
end;

/// <summary>
/// Distribution using hexagons. Rows are filled sequentially. For better
/// distribution the points still need to be shifted by half the radius of the
/// circumscribed circle.
/// </summary>
procedure TSubmodRoot2D.distributeHexagonRow;
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
  RootList.Clear;
  { Calculation of the area assigned to one hexagon.
    Margins are cut off only after the uniform distribution }
  AreaObservation := RasterData.fdimensionx * RasterData.fdimensiony;
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
  dimx := RasterData.fdimensionx;
  dimy := RasterData.fdimensiony;
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
//        NewPosition := TRootObjectIn2D.Create;
        NewRoot.x := pos_x;
        NewRoot.y := pos_y;
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
        NewRoot.y := pos_y;
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
procedure TSubmodRoot2D.distributeHexagonCol;
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
  RootList.Clear;
  AreaObservation := RasterData.fdimensionx * RasterData.fdimensiony;
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
  dimx := RasterData.fdimensionx;
  dimy := RasterData.fdimensiony;
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
        NewPosition := TRootObjectIn2D.Create;
        NewPosition.x := pos_x;
        NewPosition.y := pos_y;
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
        NewPosition.y := pos_y;
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
procedure TSubmodRoot2D.removeMarginRoots;
var
  i: integer;
  ARoot : TRootObjectIn2D;

begin
  for i := RootList.Count - 1 downto 0 do
  begin
    ARoot := TRootObjectIn2D(RootList.Objects[i]);
    // Point not in vertical margins
    if (ARoot.x < RasterData.fverticmargin) or
      (ARoot.x > RasterData.fdimensionx - RasterData.fverticmargin)
    // Point not in horizontal margins
      or (ARoot.y < RasterData.fhorizmargin) or
      (ARoot.y > RasterData.fdimensiony - RasterData.fhorizmargin) then
    begin
      RootList.Delete(i);
    end;
  end;
  RefreshRootStatistics;
  CalculateRootVoronoi;
end;

destructor TSubmodRoot2D.Destroy;
begin
  RootList.Free;
  RasterData.Free;
  inherited Destroy;
end;

function TSubmodRoot2D.getRasterData: TRasterData;
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


procedure TSubmodRoot2D.calcRootPosAsIndex;
var I: Integer; R: TRootObjectIn2D;
begin
  for I := 0 to RootList.Count - 1 do begin
    R := TRootObjectIn2D(RootList.Objects[I]);
    if IsNan(R.x) or IsInfinite(R.x) or IsNan(R.y) or IsInfinite(R.y) or
       (R.x < 0) or (R.x > dimensionX.v) or (R.y < 0) or (R.y > dimensionY.v) then
      raise ERangeError.CreateFmt('Root %d is outside the computational domain', [I+1]);
    /// <summary>Active indices are 1..N; upper-edge roots belong to the last cell.</summary>
    R.xi := Min(RasterData.NCols, 1 + Floor(R.x / RasterData.ColWidth));
    R.yi := Min(RasterData.NRows, 1 + Floor(R.y / RasterData.RowHeight));
  end;
end;


end.
