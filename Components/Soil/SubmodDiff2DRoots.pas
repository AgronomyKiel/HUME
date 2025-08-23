unit SubmodDiff2DRoots;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,
  UMod, UState, Diffko, SubmodRootStructureNew, MathImge,
  SubmodRootDiff;

const
  dim_max = 10000; { largest index, required for the vectors during the
    flux calculation }
  colorarray: array [0 .. 11] of TColor = ($00CB9F74, $00D8AD49, $00E6C986,
    $00F2E3C1, $00DAF0C4, $00A6E089, $0086D560, $0065CFB5, $008DC5FC, $0075D5FD,
    $0078E1ED, $00ACEDF4);
  levelsarray: array [0 .. 11] of MathFloat = (-4, -2.5, -2, -1.5, -1, -0.5, 0,
    0.5, 1, 1.5, 2, 2.5);

type
  (* -----------------------------------------------------------------------------
    Type declarations
    ------------------------------------------------------------------------------ *)
  { Arrays }
  { Problem: the dynamic implementation was removed again due to difficulties
    with array boundaries. }
  array_type = array [0 .. dim_max + 1] of real;

  { Klassen }
  TSubmodDiff2DRoots = class(TSubModRootDiff)
    { Declaration of class TSubmodRootDiff2D. This class performs the
      calculations for the root function model. }
  private
    { Private declarations }
    ContPosx, // Fixed position of the container center.
    ContPosy,
    { Field stores whether the output file for sink influx has been created.
      This should be done anew before each model run -> FileWasCreated is set to
      false in init. In CalcRates the file is created once and the flag is set to
      true }

    SumOfInternalTimeSteps: double;
    FileWasCreated: boolean;
    SinkCellFileWasCreated: boolean;
    fMyMathImage: TMathImage;
    ColorSurface: TColorSurface;
    TSRPLightList: TList; // List with TSRPLight instances
    (* -----------------------------------------------------------------------------
      The following fields relate to the computational elements and are accessed
      by several methods (therefore they are not local variables).
      If they should be displayed in HUME in any form, a declaration as TVar
      would be appropriate.
      Problem: units
      ------------------------------------------------------------------------------ *)
    vol_Element, { volume of a computational element [cm3] }
    wm, { water amount of a computational element [cm3] }
    min_c, { minimum concentration in the grid [mol/cm3] }
    max_c { maximum concentration in the grid }
      : double;
    (* -----------------------------------------------------------------------------
      C_xy: array for concentrations in the computational elements.
      { In x_arr and y_arr are the 'midpoint coordinates of the grid cells' }
      c_xy was declared as a dynamic array (see NG, p.65 ff) because the size of
      the array should be declared with values of dim_x and dim_y (number of
      computational elements in the x and y directions) that are assigned later.
      ------------------------------------------------------------------------------ *)
    C_xy: array of array of double;
    x_arr, y_arr: array of double;
    Diffuptake: double;
    procedure clearLists;
    procedure calcRootPosAsIndex;
    procedure updateFromStructModell;
    // Methods for flux calculation
    procedure zweid_solut(dt_globmod: real);
    // Helper methods
    procedure InitConc;
    procedure createSteadyState(DiffSteadyState: double);
    function avg_conz: double;
    function influx_fVar(Imax, Km, ClAv, x, Db: double): double;

    function calcAmountUptakeRoots: double;
    function calcActArdt: double;
    function convertConcToAmount(i: integer): double;
    procedure writeUptakeSinkToFile;
    function FileExists(FileName: string): boolean;
    // Methods for container growth:
    procedure testForContBorder(var start_, ende_: integer;
      x_ndx, y_ndx: integer; zeile: boolean);
    function calcAbsValue2D(vect: r2): double;
    function vectorSubtrakt2D(vect2, vect1: r2): r2;
  protected
    { Protected declarations, also accessible from derived classes }

    { * -----------------------------------------------------------------------------
      Member of HUME base class TPar (parameters)
      ------------------------------------------------------------------------------* }
    Ar, { uptake rate [Kg N/ha*d] }
    Km, { Michaelis-Menten constant [mol/cm3] }
    dim_x, { number of elements in X-direction }
    dim_y, { number of elements in Y-direction }
    ini_dt, { initial internal time step [s] }
    ContRad { radius of the container in container mode }
      : TPar;
    { * -----------------------------------------------------------------------------
      Member of HUME base class TVar
      ------------------------------------------------------------------------------* }
    dim_xMiddle, { number of central elements in X-direction }
    dim_yMiddle, { number of central elements in Y-direction }
    Distance, { half mean distance between roots [cm] }
    dx, { grid width in X-direction [cm] }
    dy, { grid width in Y-direction [cm] }
    int_dt, { variable for the internal time step [s] }
    Flaeche, { area of middle and margins [cm2] }
    c_av, { mean concentration [mol/cm3] }
    Imax, { maximum influx [mol/cm*s] }
    wl, { root lengths per square meter [cm/(area*depth)]
      problem: maybe TState? }
    wl_ha, { root lengths per hectare [cm/ha] problem: check unit }
    ActAr, { current uptake rate [kg N/ha/d] }
    ActArFromConc { current uptake rate [kg N/ha/d] due to concentration change }
      : TVar;
    { * -----------------------------------------------------------------------------
      Member of HUME base class TState (state variables)
      ------------------------------------------------------------------------------* }
    Bilanz_f { balance error }
      : TState;
    (* -----------------------------------------------------------------------------
      Member of HUME base class TOption (options)
      ------------------------------------------------------------------------------ *)
    OutputSink, { specify whether nutrient uptake of individual sinks
      should be written to a file }
    RootDistribution, { define the distribution of WAP, differs from
      the 1D model }
    CalcModeSteadyState, { specify the mode in which steady state
      should be calculated (with or without margins) }
    ShowConc, { specify whether concentrations should be displayed
      or not }
    SteadyState, { flag whether a steady state should be generated
      in the 2D model or not }
    RootSinkOutpDataFile, { path and name of the output file for nutrient
      uptake of individual sinks }
    // Switches to control whether the following files are written.
    writeConcField, writeSinkCellFile, ConcFieldDataFile,
    { path and name of the output file for nutrient uptake of
      individual sinks }
    SinkCellFileFile, { path and name of the output file for nutrient
      uptake of individual sinks }
    DelMarginRoots, { deletes boundary roots from PosArr }
    ContGrowth { switch for growth in pots }
      : TOption;

  public
    { Public declarations }
    procedure createAll; override;
    procedure AddDataValueToDataSeries; override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure Get_Sink(x_loc, y_loc: word; var s: real);
    procedure get_minGrid(x_loc, y_loc: word; var s: real);
    // Helper method
    procedure showActConc; { current concentrations can be output via a form }
  published
    { Published declarations }
    // Published properties
    property par_ini_dt: TPar read ini_dt write ini_dt;
    property var_dx: TVar read dx write dx; { grid width in X-direction [cm] }
    property var_dy: TVar read dy write dy; { grid width in Y-direction [cm] }
    property MyMathImage: TMathImage read fMyMathImage write fMyMathImage;
  end; { end declaration TSubmodRootDiff2D }

procedure Register;

implementation

{$I trdiag}

procedure Register;
(* -----------------------------------------------------------------------------
  Procedure required for components: registers the components on a palette.
  ------------------------------------------------------------------------------ *)
begin
  RegisterComponents('MichasMod', [TSubmodDiff2DRoots]);
end; // End Register

function Influx_f(Imax, Km, C: real): real;
(* ------------------------------------------------------------------------------
  DESCRIPTION: influx with Michaelis-Menten boundary condition
  ------------------------------------------------------------------------------ *)
var
  influx: real;
begin
  influx := Imax * C / (Km + C);
  If (influx <= 0.0) or (C <= 0.0) // no negative fluxes
  then
    influx := 0.0;
  Result := influx;
end;

function TSubmodDiff2DRoots.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
(* ------------------------------------------------------------------------------
  DESCRIPTION: alternative calculation of influx with Michaelis-Menten boundary
  condition assuming the quasi-stationary approach in the single root cylinder.
  Corresponds to the 2D-S approach (extended by Michaelis-Menten kinetics). The
  calculation, especially the formula for cla, needs to be checked again.
  ------------------------------------------------------------------------------ *)
var
  cla, // concentration at the root surface
  influx, // nutrient influx rate [mol cm^-1 s^-1]
  numerator // numerator in equation 3.6.33, Kage's dissertation
    : double;
begin
  numerator := Km + (sqr(x) * Imax / ((sqr(x) - sqr(Rad_Wurzel.v)) * 2 * pi *
    Db)) * ln(x / Rad_Wurzel.v) - Imax / (4 * pi * Db);
  cla := clmin.v + (-ClAv + numerator) / 2;
  cla := cla + sqrt(sqr(ClAv + numerator) / 4 + ClAv * Km);
  influx := Imax * (cla - clmin.v) / (Km + (cla - clmin.v));
  If (influx <= 0.0) or (ClAv <= 0.0) // no negative fluxes
  then
    influx := 0.0;
  Result := influx;
end;

(* -----------------------------------------------------------------------------
  Implementation of TSubmodRootDiff
  ------------------------------------------------------------------------------ *)
procedure TSubmodDiff2DRoots.createAll;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Creation and initialization of state variables, variables, and parameters.
  The first parameter of the function call provides a string identical to the
  identifier used for lookup.
  The second parameter contains a string specifying the unit used
  ([n] for dimensionless parameters, etc.).
  The third parameter is the actual floating-point value.
  See declaration for an explanation of the identifiers.
  ------------------------------------------------------------------------------ *)
begin
  inherited createAll;
  TSRPLightList := TList.Create;
  // Lognormalverteilung per default.
  // Erzeugen und initialisieren von TPar
  ParCreate('Ar', '[kg N/ha*d]', 0, Ar); { Aufnahmerate  [Kg N/ha*d] }
  ParCreate('Km', '[mikromol/l]', 0, Km);
  ParCreate('ini_dt', '[s]', 3600, ini_dt);
  ParCreate('dim_x', '[n]', 500, dim_x);
  ParCreate('dim_y', '[n]', 500, dim_y);
  ParCreate('ContRad', '[cm]', 10, ContRad);
  // Erzeugen und initialisieren von TVar
  VarCreate('Distance', '[cm]', 0, false, Distance);
  VarCreate('dx', '[cm]', 0, true, dx);
  VarCreate('dy', '[cm]', 0, true, dy);
  VarCreate('Flaeche', '[cm2]', 0, false, Flaeche);
  VarCreate('ActArFromConc', '[kg N/(ha*d)]', 0, false, ActArFromConc);
  VarCreate('int_dt', '[s]', 0, false, int_dt);
  VarCreate('c_av', '[mol/cm3]', 0, false, c_av);
  VarCreate('Imaxa', '[mol/cm/s]', 0, false, Imax);
  VarCreate('wl', '[cm/(Flaeche*Tiefe)]', 0, false, wl);
  VarCreate('wl_ha', '[cm/ha]', 0, false, wl_ha);
  VarCreate('ActAr', '[kg N/(ha*d)]', 0, false, ActAr);
  VarCreate('dim_xMiddle', '[-]', 0, false, dim_xMiddle);
  VarCreate('dim_yMiddle', '[-]', 0, false, dim_yMiddle);
  // Erzeugen und initialisieren von TState
  StateCreate('Bilanz_f', '[kg N/ha]', 0, false, Bilanz_f);
  // Erzeugen und initialisieren von TOption

  OptCreate('ContGrowth', 'no', ContGrowth);
  ContGrowth.OptionList.Add('yes');
  ContGrowth.OptionList.Add('no');

  OptCreate('ShowConc', 'True', ShowConc);
  ShowConc.OptionList.Add('true');
  ShowConc.OptionList.Add('false');

  OptCreate('CalcModeSteadyState', 'withoutMargin', CalcModeSteadyState);
  CalcModeSteadyState.OptionList.Add('withMargin');
  CalcModeSteadyState.OptionList.Add('withoutMargin');

  OptCreate('SteadyState', 'no', SteadyState);
  SteadyState.OptionList.Add('yes');
  SteadyState.OptionList.Add('no');

  OptCreate('RootDistribution', 'Random', RootDistribution);
  RootDistribution.OptionList.Add('Random');
  RootDistribution.OptionList.Add('Regular');
  // Verteilung wie in Quelle (Datei, Strukturmodell)
  RootDistribution.OptionList.Add('FromSource');

  OptCreate('DelMarginRoots', 'no', DelMarginRoots);
  DelMarginRoots.OptionList.Add('yes');
  DelMarginRoots.OptionList.Add('no');

  OptCreate('writeConcField', 'no', writeConcField);
  writeConcField.OptionList.Add('no');
  writeConcField.OptionList.Add('yes');
  OptCreate('writeSinkCellFile', 'no', writeSinkCellFile);
  writeSinkCellFile.OptionList.Add('no');
  writeSinkCellFile.OptionList.Add('yes');

  OptCreate('OutputSink', 'no', OutputSink);
  OutputSink.OptionList.Add('no');
  OutputSink.OptionList.Add('yes');

  OptCreate('ConcFieldDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv', ConcFieldDataFile);
  ConcFieldDataFile.OptionList.Add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv');
  OptCreate('SinkCellFileFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv', SinkCellFileFile);
  SinkCellFileFile.OptionList.Add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv');
  OptCreate('RootSinkOutpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat', RootSinkOutpDataFile);
  { Additional paths for Pages model 1: dynamic coupling with the 2D structural model
    Path: Q:\Kohl\DiffModell\IniFilesAusgaben }
  OptCreate('RootSinkOutpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat', RootSinkOutpDataFile);
  RootSinkOutpDataFile.OptionList.Add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat');
  OptCreate('RootXYOutpDataFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data',
    RootXYOutpDataFile);
  RootXYOutpDataFile.OptionList.Add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\xy_Data');
end; // End TSubmodRootDiff2D.CreateAll

procedure TSubmodDiff2DRoots.AddDataValueToDataSeries;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff
  DESCRIPTION: performs various initializations
  ------------------------------------------------------------------------------ *)
var
  fn: TFilename;
  i: integer;
  DimXMiddle, // dimension of the central area in the x-direction [cm]
  DimYMiddle // dimension of the central area in the y-direction [cm]
    : double;
begin

  ContPosx := 50;
  ContPosy := 50;
  SinkCellFileWasCreated := false;
  FileWasCreated := false;
  hasWritten := false;
  // clear lists
  clearLists;
  { No dynamic connection between the 2D diffusion model and structural model in
    the distribution variants regular or random }
  if (iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option <> 'fromsource') then
  begin
    RootDistribution.Option := 'fromsource';
    // showMessage('Strukturmodell setzt Einstellung lognormal voraus.Wurde umgestellt.');
  end;
  inherited;
  { AddDataValueToDataSeries now replaces the init method. Originally, init of
    the parent class was called with the passed global model. }
  // inherited init(GlobModReferenz);
  (* -----------------------------------------------------------------------------
    c_xy: Set the array size with SetLength. A multidimensional array is
    declared. Note: dynamic arrays always start at 0.
    ------------------------------------------------------------------------------ *)
  // operations related to computational elements
  SetLength(C_xy, trunc(dim_x.v + 2), trunc(dim_y.v + 2));
  SetLength(x_arr, trunc(dim_x.v) + 2);
  SetLength(y_arr, trunc(dim_y.v) + 2);
  dx.v := DimensionX.v / dim_x.v;
  dy.v := DimensionY.v / dim_y.v;
  DimXMiddle := DimensionX.v - 2 * verticMargin.v;
  DimYMiddle := DimensionY.v - 2 * horizMargin.v;
  // calculation of the number of central computational elements
  dim_xMiddle.v := DimXMiddle / dx.v;
  dim_yMiddle.v := DimYMiddle / dy.v;
  AreaMiddle.v := DimXMiddle * DimYMiddle;
  x_arr[0] := dx.v / 2;
  for i := 1 to trunc(dim_x.v) + 1 do
    x_arr[i] := x_arr[i - 1] + dx.v;
  y_arr[0] := dy.v / 2;
  for i := 1 to trunc(dim_y.v) + 1 do
    y_arr[i] := y_arr[i - 1] + dy.v;

  vol_Element := dx.v * dy.v; { volume of a computational element [cm3] }
  wm := theta.v * vol_Element; { water amount of a computational element
    [cm3*cm3] }
  { Calculation of the initial concentration contained in the computational
    elements from the initial amount of N in the soil. At this time all
    computational elements, whether in the middle or at the edges, have the same
    concentration. Calculation is ok. }
  InitConc;
  N_amountsoil.v := Mg_func(Tiefe.v, theta.v, c_start.v); // Debuggen
  c_av.v := avg_conz;
  // N_AmountSoil.v := mg_func(Tiefe.v, Theta.v, c_av.v);//Debuggen
  int_dt.v := ini_dt.v; // Zuweisung der Startzeitschrittweite ...
  Flaeche.v := DimensionX.v * DimensionY.v;
  { Area of the layer to be examined including margins }
  volumen.v := Flaeche.v * Tiefe.v;
  { Volume of the considered soil layer [cm3] }
  { Calculation of mineralization rate in [Mol/cm^3*s] }
  Min_S.v := minera.v / 14 * 1000 / 86400 * 1 / (Tiefe.v * 1E8);
  // initialize visualization of nutrient uptake
  If ((MyMathImage <> nil) and (ShowConc.Option = 'true')) then
  begin
    MyMathImage.d3WorldX1 := x_arr[1];
    MyMathImage.d3WorldXW := x_arr[trunc(dim_x.v)];
    MyMathImage.d3WorldY1 := y_arr[1];
    MyMathImage.d3WorldYW := y_arr[trunc(dim_y.v)];
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

  If iniMethod.Option = 'rasterdatafile' then
  begin
    RasterData.readRasterData(RootInpDataFile.Option, seriesXY);
    // output aggregated data in the RasterData tab
    fillGridRasterData;
  end;
  If iniMethod.Option = 'xyfile' then
  begin
    RasterData.readXYfromFile(RootInpDataFileXY.Option, seriesXY);
  end;
  If iniMethod.Option = 'inppar' then
  begin
    RLD_mean.v := ParMRLD.v; // Berechnete WLD in diesem Fall = Eingabeparameter
    Num_Roots.v := RLD_mean.v * Flaeche.v;
    RasterData.NRoots := trunc(Num_Roots.v);
    if RootDistribution.Option = 'fromsource' then
    begin
      // As there is no source, only the regular or random option makes sense here
      showMessage
        ('Warning: RootDistribution = FromSource. RootDistribution set to Regular.');
      RootDistribution.Option := 'regular';
    end;
  end;
  // compute a uniform or random distribution
  If RootDistribution.Option = 'random' then
  begin
    for i := 1 to trunc(Num_Roots.v) do
    begin
      RasterData.PosArr[i].x := random(trunc(dim_x.v) - 2) + 2;
      RasterData.PosArr[i].y := random(trunc(dim_y.v) - 2) + 2;
    end;
  end;
  If (RootDistribution.Option = 'regular') and (Num_Roots.v <> 0) then
  begin
    EqualDistribution;
  end;
  // calculation of indices from XY coordinates is necessary in every case
  if Num_Roots.v <> 0 then
  begin
    calcRootPosAsIndex;
  end;
  init_eingelesen;
  { Excluding margins should not be done because roots are present and should
    also take up nutrients but would not be considered }
  if DelMarginRoots.Option = 'yes' then
    removeMarginRoots;
  calcNumberConsRoots;
  { Various derived values should only consider roots that are not in the margins }
  if RootDistribution.Option = 'Regular' then
  begin
    AreaMiddle.v := 1 / RLD_mean.v * number_consid_roots.v;
  end;
  { Only in the case of the uniform distribution should the originally supplied
    RLD be used; otherwise a new RLD is considered that includes only roots not
    located in the margins. }
  if (RootDistribution.Option <> 'regular') or (iniMethod.Option = 'xyfile')
  then
  begin
    RLD_mean.v := number_consid_roots.v / AreaMiddle.v;
  end;

  { For Distance and the other derived variables only roots not located in the
    margins are considered }
  if Num_Roots.v <> 0 then
    Distance.v := 1 / sqrt(pi * RLD_mean.v);
  { Calculation of root length in [cm] relative to depth. It is assumed that the
    parallel arranged linear structures have no curvature. The number of
    considered central roots is extrapolated to the entire observation area }
  wl.v := number_consid_roots.v / AreaMiddle.v * 1E4 * Tiefe.v;
  wl_ha.v := wl.v * 1E4;
  { alternatively: consider all roots:
    wl.v:= RLD_mean.v*Flaeche.v*Tiefe.v;
    wl_ha.v:= RLD_mean.v*1e8*Tiefe.v;     { root lengths per hectare [cm/ha]
    1e8 = centimeters per ha }
  If wl_ha.v > 0.0 then
  begin
    { Calculation seems correct see manuscript hanging register compare 1D2D }
    Imax.v := Ar.v / 14 * 1000 / 86400 / wl_ha.v;
    { Calculation of influx rate [mol/(cm/s)] }
    // Imax.V := Ar.v*1000/(14*86400*WL_ha.v);  //Debuggen
  end
  else
    Imax.v := 0.0;
  // output XY coordinates in static model
  if iniMethod.Option <> 'submodstruct' then
    fillChartRootDistr;
  showActConc;
end;

procedure TSubmodDiff2DRoots.InitConc;
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of the initial concentration from the initial amount
  of N
  ------------------------------------------------------------------------------ *)
var
  x_ndx, y_ndx: integer;
  NAmountGridzell: double;
begin
  { Calculate the amount of N in a grid cell from kg/ha to g/(dim_x*dim_y);
    the 1000 in the denominator comes from converting kg to g }

  // NAmountGridzell:=N_AmountSoil.V*1000/(dim_x.v*dim_y.v*10000*vol_Element);  //g N/cm3
  // NAmountGridzell/(theta.v*14*Tiefe.V);   //mol/cm^3
  c_start.v := self.Cl_func(Tiefe.v, theta.v, N_amountsoil.v);
  // c_start.v := NAmountGridzell/(theta.v*Tiefe.v*1e8*14)*1000; //old implementation
  For x_ndx := 0 to trunc(dim_x.v + 1) do
  begin
    for y_ndx := 0 to trunc(dim_y.v + 1) do
    begin
      // c_xy[x_ndx, y_ndx] := c_start.v*(1+x_ndx/1)*(1+y_ndx/1);
      C_xy[x_ndx, y_ndx] := c_start.v;
    end;
  end;
end;

function TSubmodDiff2DRoots.avg_conz: double;
(* ------------------------------------------------------------------------------
  DESCRIPTION:  calculation of average concentrations
  Problem: Should edge computational elements be excluded from the calculation?
  Source code for this is available in the programming diary.
  ------------------------------------------------------------------------------ *)
var
  i, j,
  { first and last computational element not in the border, in both x and y
    direction }
  numb1stElemX, numbLastElemX, numb1stElemY, numbLastElemY: integer;
  conc: double;

begin
  min_c := 1E100;
  max_c := 0.0;
  conc := 0.0;
  if CalcModeSteadyState.Option = 'withMargin' then
  begin
    { Edge rows and columns are included }
    for i := 1 to trunc(dim_x.v) - 1 do
      for j := 1 to trunc(dim_y.v) - 1 do
      begin
        // sum concentrations of all computational elements:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Average: divide by the total number of elements }
    conc := conc / (dim_x.v * dim_y.v);
  end
  else // when margins should not be considered
  begin
    numb1stElemX := trunc((dim_x.v - dim_xMiddle.v) / 2);
    numbLastElemX := trunc(dim_x.v - (dim_x.v - dim_xMiddle.v) / 2);
    numb1stElemY := trunc((dim_y.v - dim_yMiddle.v) / 2);
    numbLastElemY := trunc(dim_y.v - (dim_y.v - dim_yMiddle.v) / 2);
    for i := numb1stElemX to numbLastElemX - 1 do
      for j := numb1stElemY to numbLastElemY - 1 do
      begin
        // sum concentrations of all computational elements:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Average: divide by the total number of central elements }
  conc := conc / ((numbLastElemX - numb1stElemX) *
    (numbLastElemY - numb1stElemY));
  end;
  Result := conc;
end;

procedure TSubmodDiff2DRoots.createSteadyState(DiffSteadyState: double);
(* ------------------------------------------------------------------------------
  DESCRIPTION: generates a steady-state condition using the following procedure
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
begin
  { the total absorbed amount is evenly distributed across all computational elements }
  for i := 0 to trunc(dim_x.v + 1) do
    for j := 0 to trunc(dim_y.v + 1) do
    begin
      C_xy[i, j] := C_xy[i, j] + DiffSteadyState;
    end;
end;

procedure TSubmodDiff2DRoots.zweid_solut(dt_globmod: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: Central procedure. Calculation of nutrient transport in 2D space
  (linear algebra). Note: nested structure
  ------------------------------------------------------------------------------ *)
var
  { The following arrays are declared with a size of dim_max (largest index).
    From the fluxes, a tridiagonal matrix with main and secondary diagonals is
    formed (see Scholl/Drews: linear algebra) }
  B_vektor, { solution vector }
  lower, { lower diagonal }
  diag, { middle diagonal }
  upper, { upper diagonal }
  Sink, { sink terms }
  u_vektor, { concentration vector below }
  z_vektor, { z_vektor : central vector to be calculated }
  o_vektor: array_type; { concentration vector above }
  { Note: since array_type also starts at 0 in the original, nothing needs to be
    changed here }
  Result, i: word;
  Df: real;
  x_ndx, y_ndx: integer; { loop variables for grid elements }

  SinkCellFile: Textfile;
  SinkCellFileName: string;

  procedure eine_Zeile(o_vektor, Sink: array_type; dim_z, Start, Ende: word;
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
      flow_1 := dx.v * De.v * (u_vektor[Start] - z_vektor[Start]) / dy.v * Df;
      // explicit calculation
      flow_2 := dx.v * De.v * (z_vektor[Start] - o_vektor[Start]) / dy.v * Df;

      B_vektor[Start] := z_vektor[Start] + flow_1 - flow_2 + Sink[Start] * Df;
      diag[Start] := De.v * dy.v / dx.v * Df + 1;
      upper[Start] := -De.v * dy.v / dx.v * Df;
    end; // End linker Rand

    Procedure Mittelteil(Start, Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      DESCRIPTION: Solves the diffusion equation for two-dimensional coordinates
      (grid) using an alternating direction implicit approach?
      Boundary condition: no transport across grid boundaries (no flow)
      ------------------------------------------------------------------------------ *)
    var
      ndx: word;
    begin
      For ndx := Start + 1 to Ende - 1 do
      begin
        flow_1 := dx.v * De.v * (u_vektor[ndx] - z_vektor[ndx]) / dy.v * Df;
        flow_2 := dx.v * De.v * (z_vektor[ndx] - o_vektor[ndx]) / dy.v * Df;

        B_vektor[ndx] := z_vektor[ndx] + flow_1 - flow_2 + Sink[ndx] * Df;
        lower[ndx] := -De.v * dy.v / dx.v * Df;
        diag[ndx] := De.v * dy.v / dx.v * Df + De.v * dy.v / dx.v * Df + 1;
        upper[ndx] := -De.v * dy.v / dx.v * Df;
      end;
    end; // End Mittelteil

    Procedure rechter_Rand(Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      flow_1 := dx.v * De.v * (u_vektor[Ende] - z_vektor[Ende]) / dy.v * Df;
      flow_2 := dx.v * De.v * (z_vektor[Ende] - o_vektor[Ende]) / dy.v * Df;

      B_vektor[Ende] := z_vektor[Ende] + flow_1 - flow_2 +
        Sink[trunc(dim_x.v)] * Df;
      lower[Ende] := -De.v * dy.v / dx.v * Df;
      diag[Ende] := De.v * dy.v / dx.v * Df + 1;
      For i := Ende + 1 to trunc(dim_x.v) do
      begin
        B_vektor[i] := z_vektor[i];
        diag[i] := 0;
        upper[i] := 0;
      end;

    end; // End rechter Rand

    procedure Loesung_Gleichungssystem;
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
    if self.writeSinkCellFile.Option = 'yes' then
    begin
      SinkCellFileName := SinkCellFileFile.Option;
      if SinkCellFileWasCreated = false then
      begin
        deleteFile(SinkCellFileName);
        assignfile(SinkCellFile, SinkCellFileName);
        rewrite(SinkCellFile);
        // Header
        write(SinkCellFile, 'SimZeit', ' ', 'dt_akt[s]', ' ', 'sumDtInt[s]',
          ' ', 'Influx', ' ', 'Konz_Zelle');
        writeln(SinkCellFile);
        closefile(SinkCellFile);
        SinkCellFileWasCreated := true;
      end;
    end;
    linker_Rand(Start);
    Mittelteil(Start, Ende);
    rechter_Rand(Ende);
    Loesung_Gleichungssystem;
  end; // End eine_Zeile (correct?)

(* -----------------------------------------------------------------------------
  End of helper methods for the central method
  ------------------------------------------------------------------------------ *)
var
  start_, ende_: integer;
begin
  Df := int_dt.v / 2 * 1 / wm; { computation factor for half time step }
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
      eine_Zeile(o_vektor, Sink, trunc(dim_x.v), 1, trunc(dim_x.v), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      testForContBorder(start_, ende_, i, y_ndx, true);
      eine_Zeile(o_vektor, Sink, trunc(dim_x.v), start_, ende_, u_vektor,
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
      eine_Zeile(o_vektor, Sink, trunc(dim_y.v), 1, trunc(dim_y.v), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      testForContBorder(start_, ende_, x_ndx, i, true);
      eine_Zeile(o_vektor, Sink, trunc(dim_y.v), start_, ende_, u_vektor,
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
    for i := 1 to RasterData.NRoots do
      if (RasterData.PosArr[i].xi > trunc(dim_x.v / 10)) and
        (RasterData.PosArr[i].xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (RasterData.PosArr[i].yi > trunc(self.dim_y.v / 10)) and
        (RasterData.PosArr[i].yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, RasterData.PosArr[i].NInflux, ' ');
    for i := 1 to RasterData.NRoots do
      if (RasterData.PosArr[i].xi > trunc(dim_x.v / 10)) and
        (RasterData.PosArr[i].xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (RasterData.PosArr[i].yi > trunc(self.dim_y.v / 10)) and
        (RasterData.PosArr[i].yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, C_xy[RasterData.PosArr[i].xi,
          RasterData.PosArr[i].yi], ' ');
    writeln(SinkCellFile);
    closefile(SinkCellFile);
  end;
end;
(* ------------------------------------------------------------------------------
  End of central procedure
  ------------------------------------------------------------------------------ *)

procedure TSubmodDiff2DRoots.Get_Sink(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of sink terms (uptake and mineralization)
  [mol/s-1] in a computational element
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
  De_SinkGrid := De.v / theta.v;
  for i := 1 to trunc(Num_Roots.v) do
  begin
    // test whether a sink exists in the computational element, then calculate uptake
    if ((RasterData.PosArr[i].xi = x_loc) and (RasterData.PosArr[i].yi = y_loc))
    then
    begin
      x := sqrt(dx.v * dy.v / pi);
      // radius of a circle corresponding to the central cell
      Db := Dl.v * 3.35 * theta.v * theta.v * theta.v; //
      { Inner boundary condition: constant influx; this scenario can be controlled
        via parameter Ar; another influencing factor is the calculated wl_ha }
      If Uptake_function.Option = lowercase('ConstInflux') then
        NUptake := Imax.v; // mol/cm*s
      // Innere Randbedingung: Zero sink
      If Uptake_function.Option = lowercase('ZeroSink') then

        // Nuptake :=
        { The flux is calculated considering the absorbing part of the root
          surface. The concentration gradient extends from the center of the
          neighboring cell to the apex of the root surface, with the root located
          centrally in the cell. See hanging file material 2D model. Note on the
          denominator: first term is the concentration gradient, second term the
          edge or the partial absorbing root surface. }
        { De.V*C_xy[x_loc-1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc+1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc, y_loc-1]/dy.V*dx.V
          +De.V*C_xy[x_loc, y_loc+1]/dy.V*dx.V; }
        { Alternative calculation of uptake by the sink: gradient reduced by
          Rad_Wurzel.v, flux in each direction corresponds to a quarter of the
          root circumference (assuming a cylindrical root). }
        { De.V*C_xy[x_loc-1, y_loc]/(dx.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc+1, y_loc]/(dx.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc, y_loc-1]/(dy.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc, y_loc+1]/(dy.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2); }

        { NUptakeGrid:= De.V*C_xy[x_loc-1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc+1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc, y_loc-1]/dy.V*dx.V
          +De.V*C_xy[x_loc, y_loc+1]/dy.V*dx.V; }
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
          (-1 / 2 + (sqr(x) / (sqr(x) - sqr(Rad_Wurzel.v)) *
          ln(x / Rad_Wurzel.v)));

      { Alternative calculation 4 (after Moncayo, Eq. 19 and 20): }
      { Nuptake :=
        De_SinkGrid*C_xy[x_loc-1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc+1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc-1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc+1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2); }
      { Implementation with Cl_min }
      { ZeroSink     : In_arr[pos] := De.v*(C_xy[x_loc-1, y_loc]-clmin.v)/
        dx.v*dy.v+De.v*(C_xy[x_loc+1, y_loc]-clmin.v)/dx.v*dy.v
        +De.v*(C_xy[x_loc, y_loc-1]-clmin.v)/dy.v*dx.v+De.v*
        (C_xy[x_loc,y_loc+1]-clmin.v)/dy.v*dx.v; }
      // Innere Randbedingung: Michaelis-Menten-Kinetik
      If Uptake_function.Option = lowercase('MM') then
        // NUptake :=  Influx_f( Imax.v, Km.v, C_xy[x_loc, y_loc]);
        NUptake := influx_fVar(Imax.v, Km.v, C_xy[x_loc, y_loc], x, Db);
      // influx into the sink during the time step
      RasterData.PosArr[i].NInflux := NUptake;
      If Uptake_function.Option <> lowercase('ZeroSink') then
        SumUptake := SumUptake + NUptake
      else
        SumUptake := NUptake;
      // calculate cumulative N uptake for the sinks
      { Problem: there is still a conceptual error here }
      NAmountRootdt := RasterData.PosArr[i].NInflux * 14 / 1000 * int_dt.v;
      // NAmountRootdt:=RasterData.PosArr[i].NInflux*14/1000*86400/int_dt.V;
      RasterData.PosArr[i].NAmountdt := NAmountRootdt;
      RasterData.PosArr[i].SumNMenge := RasterData.PosArr[i].SumNMenge +
        NAmountRootdt;
    end;
  end;
  { Mineralization }
  s := s - SumUptake;
end;

procedure TSubmodDiff2DRoots.get_minGrid(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of mineralization [mol/s-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  pos: word;
begin
  s := Min_S.v * vol_Element; { sink term from mineralization [mol/s] }
end;

procedure TSubmodDiff2DRoots.CalcRates;
(* ------------------------------------------------------------------------------
  DESCRIPTION: This method invokes the control flow of the submodel for rate
  calculation.
  ------------------------------------------------------------------------------ *)
var
  ConcFieldName: string;
  ConcField, UptakeFile: Textfile;
  i, j: integer;
  last_dt,
  { difference between concBefore and conc }
  concBegin, // average concentration before calculating fluxes [mol/cm^3]
  ConcAfter, { average concentration after calculating fluxes [mol/cm^3]
    and before redistributing absorbed concentrations to the computational
    elements }
  // SumOfInternalTimeSteps,
  sumNAmountRootsdt { N amount taken up by all valid roots in the time step }
    : real;
  TimeStepAdaption: boolean;
begin
  inherited CalcRates; { nothing happens in the base model (no inherited call) }
  ConcFieldName := ConcFieldDataFile.Option;
  // Communication with the structural model and display of WAP in MathImNutrUptake
  // create new file with outputs for the sinks:
  for i := 1 to high(RasterData.PosArr) do
  begin
    RasterData.PosArr[i].SumNMenge := 0;
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
    updateFromStructModell;
    // as long as no roots exist, no fluxes are calculated
    if Num_Roots.v < 1 then
      exit;
    fillChartRootDistr;
  end;
  { Since theta may change in the dynamic model, De must be recalculated each
    time step }
  De.v := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  // De.v:=Dl.v*3.35*sqr(theta.v);
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
    { Has the end of the day been exceeded with the new time step? }
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
    Sum_N_AmountRoots.v := Sum_N_AmountRoots.v + sumNAmountRootsdt;
    { At the end of each internal time step the absorbed influx is redistributed
      to the computational elements }
    { If a steady-state condition should be generated, the constant concentration
      is restored in every time step }
    ConcAfter := avg_conz;
    ActArFromConc.v := ActArFromConc.v + Mg_func(Tiefe.v, theta.v,
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
    writeOutputToFile;
  end;
  if (OutputSink.Option = 'yes') then
  begin
    writeUptakeSinkToFile;
  end;
end; // End TSubmodRootDiff.CalcRates

procedure TSubmodDiff2DRoots.Integrate;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS:  TSubmodRootDiff
  DESCRIPTION: method overridden to gradually change the time step.
  ------------------------------------------------------------------------------ *)
var
  sumNAmountRoots, n_me_alt: real;
  // temporary storage for the original N amount
begin
  // as long as no roots are present, no fluxes are calculated
  if Num_Roots.v < 1 then
    exit;
  inherited Integrate;
  // nothing happens in the base class and no inherited call
  n_me_alt := N_amountsoil.v;
  c_av.v := avg_conz; // average concentration
  N_amountsoil.v := Mg_func(Tiefe.v, theta.v, c_av.v);
end; // End TSubmodRootDiff2D.Integrate

procedure TSubmodDiff2DRoots.clearLists;
(* ------------------------------------------------------------------------------
  DESCRIPTION: reset list entries
  ------------------------------------------------------------------------------ *)
begin
  TSRPLightList.Clear;
end;

procedure TSubmodDiff2DRoots.calcRootPosAsIndex;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Method calculates the root positions as indices (i.e. determines the grid cell
  in which the root is located).
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  { To restore the original values after rounding, they must be stored temporarily }
  xTemp, yTemp: double;
begin
  for i := 1 to trunc(Num_Roots.v) do
  begin
    xTemp := RasterData.PosArr[i].x;
    yTemp := RasterData.PosArr[i].y;
    RasterData.PosArr[i].xi := min(trunc(dim_x.v) - 1,
      max(1, round(RasterData.PosArr[i].x / (trunc(DimensionX.v)) *
      trunc(dim_x.v))));
    RasterData.PosArr[i].yi := min(trunc(dim_y.v) - 1,
      max(1, round(RasterData.PosArr[i].y / (trunc(DimensionY.v)) *
      trunc(dim_y.v))));
    // restore original values
    RasterData.PosArr[i].x := xTemp;
    RasterData.PosArr[i].y := yTemp;
  end;
end;

procedure TSubmodDiff2DRoots.updateFromStructModell;
(* ------------------------------------------------------------------------------
  DESCRIPTION: dynamic linkage between structure and function model,
  possibility of reading SRPs generated in the structure model.
  Because there are many instances, external variables were not used.
  ------------------------------------------------------------------------------ *)
var
  ATSRPLight: TSRPLight;
  i, j, numberRoots: integer;
begin
  // remove old entries in PosArr
  RasterData.errasePosArr;
  TSRPLightList := MyStructModel.getSRPList;
  Num_Roots.v := TSRPLightList.Count;
  // fill the Pos array with XY coordinates
  j := 1;
  for i := 0 to TSRPLightList.Count - 1 do
  begin
    ATSRPLight := TSRPLightList.Items[i];
    RasterData.PosArr[j].x := ATSRPLight.x;
    RasterData.PosArr[j].y := ATSRPLight.y;
    RasterData.PosArr[j].root := j;
    inc(j);
  end;
  // Umwandlung der XY-Koordinaten
  if Num_Roots.v <> 0 then
  begin
    calcRootPosAsIndex;
  end;
end;

procedure TSubmodDiff2DRoots.showActConc;
(* ------------------------------------------------------------------------------
  DESCRIPTION: displays the current concentration in TMathImage
  ------------------------------------------------------------------------------ *)
var
  i, j, k: integer;
  thiscolor: TColor;
begin
  If ((MyMathImage <> nil) and (ShowConc.Option = 'true')) then
  begin
    MyMathImage.Clear;
    // If max_c > MyMathImage.d3WorldZW then
    // MyMathImage.d3WorldZW := 1.2*max_c;

    for i := 0 to high(levelsarray) - 1 do
    begin
      levelsarray[i] := (max_c - min_c) / high(levelsarray) * (i + 1);
    end;
    for i := 1 to trunc(dim_x.v) do
    begin
      for j := 1 to trunc(dim_y.v) do
      begin
        thiscolor := clSilver;
        for k := 0 to High(levelsarray) - 1 do
          if levelsarray[k] <= C_xy[i, j] then
            if levelsarray[k + 1] >= C_xy[i, j] then
            begin
              thiscolor := colorarray[k];
              break;
            end;
        if C_xy[i, j] < levelsarray[0] then
          thiscolor := colorarray[0];
        if C_xy[i, j] > levelsarray[High(levelsarray)] then
          thiscolor := colorarray[High(levelsarray)];
        ColorSurface.Make(i - 1, j - 1, x_arr[i], y_arr[j], C_xy[i, j],
          thiscolor);
      end;
    end;
    MyMathImage.d3drawfullworldbox;
    MyMathImage.d3DrawAxes('x', 'y', 'z', 10, 10, 10, 0, 0, 0, true);
    MyMathImage.Pen.Color := clblue;
    MyMathImage.d3DrawSurface(ColorSurface, true, true);
    MyMathImage.RePaint;
  end;
end;

procedure TSubmodDiff2DRoots.writeUptakeSinkToFile;
(* ------------------------------------------------------------------------------
  DESCRIPTION: writes a file with the N uptake of all sinks (and for assignment
  also with serial number and coordinates)
  ------------------------------------------------------------------------------ *)
var
  UptakeFile: Textfile;
  i, j: integer;
  { Only sinks that are not at the margin and lie within the observation window
    are output }
  PosArr_middle: Array of TPointDoubleType;
begin
  { If file not yet existing, create it }
  if not FileExists(RootSinkOutpDataFile.Option) then
  begin
    assignfile(UptakeFile, RootSinkOutpDataFile.Option);
    rewrite(UptakeFile);
    closefile(UptakeFile);
  end;
  SetLength(PosArr_middle, trunc(number_consid_roots.v));
  j := 0;
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // point not in the vertical margins
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= DimensionX.v - verticMargin.v)
    // point not in the horizontal margins
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= DimensionY.v - horizMargin.v) then
    begin
      PosArr_middle[j].x := RasterData.PosArr[i].x;
      PosArr_middle[j].y := RasterData.PosArr[i].y;
      PosArr_middle[j].xi := RasterData.PosArr[i].xi;
      PosArr_middle[j].yi := RasterData.PosArr[i].yi;
      PosArr_middle[j].NInflux := RasterData.PosArr[i].NInflux;
      PosArr_middle[j].WInflux := RasterData.PosArr[i].WInflux;
      PosArr_middle[j].root := RasterData.PosArr[i].root;
      PosArr_middle[j].area := RasterData.PosArr[i].area;
      inc(j);
    end;
  end;
  assignfile(UptakeFile, RootSinkOutpDataFile.Option);
  append(UptakeFile);
  write(UptakeFile, 'Modellzeit: ', GlobMod.Time.v:6:2, ' ');
  writeln(UptakeFile);
  // write header
  write(UptakeFile, 'Lfd.Nr.', ' ', 'X', ' ', 'Y', ' ', ' ', 'Flaeche', ' ',
    'N-Aufnahme', ' ');
  writeln(UptakeFile);
  for i := 0 to high(PosArr_middle) do
  begin
    write(UptakeFile, PosArr_middle[i].root, ' ');
    write(UptakeFile, PosArr_middle[i].x, ' ');
    write(UptakeFile, PosArr_middle[i].y, ' ');
    write(UptakeFile, PosArr_middle[i].area, ' ');
    write(UptakeFile, PosArr_middle[i].NInflux, ' ');
    writeln(UptakeFile);
  end;
  closefile(UptakeFile);
end;

function TSubmodDiff2DRoots.FileExists(FileName: string): boolean;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Boolean function that returns True if the file exists, otherwise
  False. If the file already exists, it is closed.
  ------------------------------------------------------------------------------ *)
var
  F: file;
begin
{$I-}
  assignfile(F, FileName);
  FileMode := 0; { open file read-only }
  Reset(F);
  closefile(F);
{$I+}
  FileExists := (IOResult = 0) and (FileName <> '');
end; { FileExists }

function TSubmodDiff2DRoots.calcAmountUptakeRoots: double;
(* ------------------------------------------------------------------------------
  DESCRIPTION: sum of the cumulative N uptake of all valid roots (present in the
  observation window but not in the margins). Actually a rate calculation, but
  necessary since not all roots should be considered.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  NAmountRoot: double;

begin
  NAmountRoot := 0;
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // point not in the vertical margins
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= DimensionX.v - verticMargin.v)
    // point not in the horizontal margins
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= DimensionY.v - horizMargin.v) then
    begin
      NAmountRoot := NAmountRoot + convertConcToAmount(i);
    end;
  end;
  { Divide by areaMiddle -> uptake related to square centimeters, multiply by
    10^8 -> uptake amount relative to a certain depth and hectare }
  Result := NAmountRoot / AreaMiddle.v * 1E8; // 10^8 cm^2 per ha
  { Why doesn't this work:
    Sum_N_AmountRoots.v := Sum_N_AmountRoots.v + Ar.v; }
end;

function TSubmodDiff2DRoots.convertConcToAmount(i: integer): double;
(* ------------------------------------------------------------------------------
  DESCRIPTION: converts uptake [mol/cm*s] into amount [kg/d] for a given root.
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000;
var
  ha: integer;
  NAmountRoot: double;
begin
  { N influx in [mol/cm/s] }
  NAmountRoot := RasterData.PosArr[i].NInflux * kg_mol * Tiefe.v * int_dt.v;
  Result := NAmountRoot;
end;

function TSubmodDiff2DRoots.calcActArdt: double;
(* ------------------------------------------------------------------------------
  Calculates the current uptake rate in the internal time step, considering only
  roots that are not in the margins. Units are computed per hectare by
  referencing wl_ha.
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
    // point not in the vertical margins
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= DimensionX.v - verticMargin.v)
    // point not in the horizontal margins
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= DimensionY.v - horizMargin.v) then
    begin
      AVInflux := AVInflux + RasterData.PosArr[i].NInflux;
      AvNMenge := AvNMenge + RasterData.PosArr[i].SumNMenge;
      inc(rootCounter);
    end;
  end;
  if number_consid_roots.v <> 0 then
  begin
    AVInflux := AVInflux / number_consid_roots.v;
    // considers only the influx from the last internal time step:
    Result := AVInflux * 14 / 1000 * wl_ha.v * int_dt.v;
    // Result:= AvInflux*14/1000*wl_ha.v
    // AvNMenge:=AvNMenge/rootCounter;
    // ActAr.v := AvNMenge*wl_ha.v;
  end;
end;

procedure TSubmodDiff2DRoots.testForContBorder(var start_, ende_: integer;
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

function TSubmodDiff2DRoots.calcAbsValue2D(vect: r2): double;
(* ------------------------------------------------------------------------------
  Calculates the magnitude = length of a vector
  ------------------------------------------------------------------------------ *)
var
  length: double;
begin
  length := sqrt(sqr(vect[0]) + sqr(vect[1]));
  Result := length;
end;

function TSubmodDiff2DRoots.vectorSubtrakt2D(vect2, vect1: r2): r2;
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

end.
