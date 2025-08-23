unit SubmodDiff2DRoots;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,
  UMod, UState, Diffko, SubmodRootStructureNew, MathImge,
  SubmodRootDiff;

const
  dim_max = 10000; { largest index, used for the vectors
    in the calculation of fluxes }
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
  { Problem: dynamic implementation was removed again due to difficulties with
    array bounds }
  array_type = array [0 .. dim_max + 1] of real;

  { Classes }
  TSubmodDiff2DRoots = class(TSubModRootDiff)
    { Declaration of class TSubmodRootDiff2D. The class performs the calculations
      for the root function model. }
  private
    { Private declarations }
    ContPosx, // Hard-coded position of the container center
    ContPosy,
    { Array remembers whether the output file for sink influx was created. This
      should happen anew before each model run -> FileWasCreated is set to false
      in init; in CalcRates the file is created once and the flag is set to true }

    SumOfInternalTimeSteps: double;
    FileWasCreated: boolean;
    SinkCellFileWasCreated: boolean;
    fMyMathImage: TMathImage;
    ColorSurface: TColorSurface;
    TSRPLightList: TList; // List with TSRPLight instances
    (* -----------------------------------------------------------------------------
      In the following, various fields are declared that refer to the computational
      elements and need to be accessed in multiple methods (hence no local variables).
      However, if these should be displayed in HUME, a declaration as TVar would be
      advisable.
      Problem: units
      ------------------------------------------------------------------------------ *)
    vol_Element, { Volume of a computation element [cm3] }
    wm, { Water amount of a computation element [cm3] }
    min_c, { Minimum concentration in the grid [mol/cm3] }
    max_c { Maximum concentration in the grid }
      : double;
    (* -----------------------------------------------------------------------------
      C_xy: array for concentrations in the computation elements.
      { x_arr and y_arr are arrays containing the 'center coordinates of the grid
      cells' }
      c_xy is declared as a dynamic array (cf. NG, p.65ff) because the size of the
      array is declared with values of dim_x or dim_y (number of computation
      elements in the x or y direction), which are assigned later.
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
    // Methods of container growth:
    procedure testForContBorder(var start_, ende_: integer;
      x_ndx, y_ndx: integer; zeile: boolean);
    function calcAbsValue2D(vect: r2): double;
    function vectorSubtrakt2D(vect2, vect1: r2): r2;
  protected
    { Protected declarations, accessible also from derived classes }

    { * -----------------------------------------------------------------------------
      Members of HUME base class TPar (parameters)
      ------------------------------------------------------------------------------* }
    Ar, { Uptake rate [kg N/ha*d] }
    Km, { Michaelis-Menten constant [mol/cm3] }
    dim_x, { Number of elements in X direction }
    dim_y, { Number of elements in Y direction }
    ini_dt, { Initial internal time step [s] }
    ContRad { Radius of the container in container mode }
      : TPar;
    { * -----------------------------------------------------------------------------
      Members of HUME base class TVar
      ------------------------------------------------------------------------------* }
    dim_xMiddle, { Number of central elements in X direction }
    dim_yMiddle, { Number of central elements in Y direction }
    Distance, { half mean distance between roots [cm] }
    dx, { Grid spacing X direction [cm] }
    dy, { Grid spacing Y direction [cm] }
    int_dt, { Variable for the internal time step [s] }
    Flaeche, { Area center and margins [cm2] }
    c_av, { Average concentration [mol/cm3] }
    Imax, { Maximum influx [mol/cm*s] }
    wl, { Root length per square meter [cm/(area*depth)]
      Problem: maybe TState???? }
    wl_ha, { Root length per hectare [cm/ha] Problem: check unit }
    ActAr, { Current uptake rate [kg N/ha/d] }
    ActArFromConc { Current uptake rate [kg N/ha/d] due to concentration change }
      : TVar;
    { * -----------------------------------------------------------------------------
      Members of HUME base class TState (state variables)
      ------------------------------------------------------------------------------* }
    Bilanz_f { Balance error }
      : TState;
    (* -----------------------------------------------------------------------------
      Members of HUME base class TOption (options).
      ------------------------------------------------------------------------------ *)
    OutputSink, { Specifies whether nutrient uptake of individual sinks should
      be written to a file }
    RootDistribution, { Defines the distribution of the WAP, differs from the
      1D model }
    CalcModeSteadyState, { Specifies in which mode the steady state should be
      calculated (with the margins or without) }
    ShowConc, { Specifies whether concentrations should be displayed or not }
    SteadyState, { Switch whether a steady state should be generated in the 2D
      model or not }
    RootSinkOutpDataFile, { Path and name of the output file for nutrient uptake
      of individual sinks }
    // Switches for whether the following files should be written
    writeConcField, writeSinkCellFile, ConcFieldDataFile,
    { Path and name of the output file for nutrient uptake of individual sinks }
    SinkCellFileFile, { Path and name of the output file for nutrient uptake of
      individual sinks }
    DelMarginRoots, { Deletes the edge roots from the PosArr }
    ContGrowth { Switch for growth in containers }
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
    procedure showActConc; { the form allows triggering an output of the current
      concentrations }
  published
    { Published declarations }
    // Published properties
    property par_ini_dt: TPar read ini_dt write ini_dt;
    property var_dx: TVar read dx write dx; { Grid spacing X direction [cm] }
    property var_dy: TVar read dy write dy; { Grid spacing Y direction [cm] }
    property MyMathImage: TMathImage read fMyMathImage write fMyMathImage;
  end; { End of declaration TSubmodRootDiff2D }

procedure Register;

implementation

{$I trdiag}

procedure Register;
(* -----------------------------------------------------------------------------
  Procedure needed for components: registers components on a palette.
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
  If (influx <= 0.0) or (C <= 0.0) // No negative fluxes
  then
    influx := 0.0;
  Result := influx;
end;

function TSubmodDiff2DRoots.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: alternative Berechnung des Influx mit Michaelis-Menten-Randbedingung
  unter der Voraussetzung, dass im Einzelwurzelzylinder mit dem quasistationären
  Ansatz gearbeitet wird.
  entspricht dem 2D-S Ansatz (erweitert um Michaelis-Menten-Kinetik). Berechnung
  vor allem der Formel für cla muss noch einmal kontrolliert werden.
  ------------------------------------------------------------------------------ *)
var
  cla, // Konzentration an der Wurzeloberfläche
  influx, // Nährstoffinfluxrate [mol cm^-1 s^-1]
  numerator // Zähler in Gleichung 3.6.33, Diss. Kage
    : double;
begin
  numerator := Km + (sqr(x) * Imax / ((sqr(x) - sqr(Rad_Wurzel.v)) * 2 * pi *
    Db)) * ln(x / Rad_Wurzel.v) - Imax / (4 * pi * Db);
  cla := clmin.v + (-ClAv + numerator) / 2;
  cla := cla + sqrt(sqr(ClAv + numerator) / 4 + ClAv * Km);
  influx := Imax * (cla - clmin.v) / (Km + (cla - clmin.v));
  If (influx <= 0.0) or (ClAv <= 0.0) // Keine negativen Flüsse
  then
    influx := 0.0;
  Result := influx;
end;

(* -----------------------------------------------------------------------------
  Implementierung TSubmodRootDiff
  ------------------------------------------------------------------------------ *)
procedure TSubmodDiff2DRoots.createAll;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  Erzeugen und Initialisieren von Zustandsvariablen, Variablen und Parametern.
  Der erste Parameter des Funktionsaufrufs übergibt einen String, der mit dem Be-
  zeichner identisch ist und nachdem gesucht werden kann.
  Der zweite Paramter enthält einen String zur Kennzeichnung der verwendeten
  Einheit ([n] für dimensionslose Paramter etc.)
  Der dritte Parameter ist der eigentliche (Fließkomma)-Wert
  Erläuterung der Bezeichner s. Deklaration.
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
  { Zusätzliche Pfade für Pages Modell 1: dynamische Kopplung mit 2D Strukturmodell
    Pfad: Q:\Kohl\DiffModell\IniFilesAusgaben }
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
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff
  BESCHREIBUNG: Durchführung diverser Initialisierungen
  ------------------------------------------------------------------------------ *)
var
  fn: TFilename;
  i: integer;
  DimXMiddle, // Dimension der mittigen Fläche in x-Richtung [cm]
  DimYMiddle // Dimension der mittigen Fläche in y-Richtung [cm]
    : double;
begin

  ContPosx := 50;
  ContPosy := 50;
  SinkCellFileWasCreated := false;
  FileWasCreated := false;
  hasWritten := false;
  // Listen leeren
  clearLists;
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
  SetLength(C_xy, trunc(dim_x.v + 2), trunc(dim_y.v + 2));
  SetLength(x_arr, trunc(dim_x.v) + 2);
  SetLength(y_arr, trunc(dim_y.v) + 2);
  dx.v := DimensionX.v / dim_x.v;
  dy.v := DimensionY.v / dim_y.v;
  DimXMiddle := DimensionX.v - 2 * verticMargin.v;
  DimYMiddle := DimensionY.v - 2 * horizMargin.v;
  // Berechnung der Anzahl der mittigen Rechenelemente
  dim_xMiddle.v := DimXMiddle / dx.v;
  dim_yMiddle.v := DimYMiddle / dy.v;
  AreaMiddle.v := DimXMiddle * DimYMiddle;
  x_arr[0] := dx.v / 2;
  for i := 1 to trunc(dim_x.v) + 1 do
    x_arr[i] := x_arr[i - 1] + dx.v;
  y_arr[0] := dy.v / 2;
  for i := 1 to trunc(dim_y.v) + 1 do
    y_arr[i] := y_arr[i - 1] + dy.v;

  vol_Element := dx.v * dy.v; { Volumen eines Rechenelements [cm3] }
  wm := theta.v * vol_Element; { Wassermenge eines Rechenelements
    [cm3*cm3 }
  { Berechnung der initial in den Rechenelementen enthaltenen Konzentration aus
    der initialen N-Menge im Boden. Zu diesem Zeitpunkt haben sämtliche Rechenelemente, egal
    ob in der Mitte oder in den Rändern die gleichen Konz. Berechnung o.k. }
  InitConc;
  N_amountsoil.v := Mg_func(Tiefe.v, theta.v, c_start.v); // Debuggen
  c_av.v := avg_conz;
  // N_AmountSoil.v := mg_func(Tiefe.v, Theta.v, c_av.v);//Debuggen
  int_dt.v := ini_dt.v; // Zuweisung der Startzeitschrittweite ...
  Flaeche.v := DimensionX.v * DimensionY.v;
  { Fläche der zu untersuchenden Schicht
    mit Rändern. }
  volumen.v := Flaeche.v * Tiefe.v;
  { Volumen der betrachteten Bodenschicht[cm3] }
  { Berechnung Mineralisationsrate in [Mol/cm^3*s] }
  Min_S.v := minera.v / 14 * 1000 / 86400 * 1 / (Tiefe.v * 1E8);
  // Initialisieren der Visuallisierung der Nährstoffaufnahme
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
    // Ausgabe aggregierter Daten im Reiter RasterData
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
      // Da es keine Quelle gibt macht hier nur die Option regular bzw. random Sinn
      showMessage
        ('Achtung: RootDistribution = FromSource. RootDistribution wird auf Regular gesetzt.');
      RootDistribution.Option := 'regular';
    end;
  end;
  // Berechnen einer gleichmäßigen bzw. zufälligen Verteilung
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
  // Berechnung der Indizes aus XY-Koordinaten in jedem Fall notwendig
  if Num_Roots.v <> 0 then
  begin
    calcRootPosAsIndex;
  end;
  init_eingelesen;
  { Ausschluss der Ränder; sollte nicht durchgeführt werden, da die Wurzeln zwar
    vorhanden sein und auch Aufnahme durchführen sollten, aber nicht berücksichtigt
    werden sollten }
  if DelMarginRoots.Option = 'yes' then
    removeMarginRoots;
  calcNumberConsRoots;
  { Versch. abgeleitete Werte sollen nur Wurzeln berücksichtigen, die nicht in den
    Rändern sind }
  if RootDistribution.Option = 'Regular' then
  begin
    AreaMiddle.v := 1 / RLD_mean.v * number_consid_roots.v;
  end;
  { Nur im Fall der gleichmäßigen Verteilung soll die ursprünglich übergebene WLD
    verwendet werden, ansonsten soll eine neue RLD berücksichtigt werden, wobei nur
    Wurzeln eingehen, die nicht in den Rändern liegen. }
  if (RootDistribution.Option <> 'regular') or (iniMethod.Option = 'xyfile')
  then
  begin
    RLD_mean.v := number_consid_roots.v / AreaMiddle.v;
  end;

  { Für Distance und die weiteren abgeleiteten Variablen werden nur Wurzel
    berücksichtigt, die sich nicht in den Rändern befinden }
  if Num_Roots.v <> 0 then
    Distance.v := 1 / sqrt(pi * RLD_mean.v);
  { Berechnung der Wurzellänge in [cm] bezogen auf die Tiefe. Es wird davon ausge-
    gangen, dass die parallel angeordnete lineare Strukturen ohne Krümmung sind.
    Es werden dabei die Anzahl der berücksichtigten mittigen Wurzeln auf die gesamte
    Beobachtungsfläche hochgerechnet }
  wl.v := number_consid_roots.v / AreaMiddle.v * 1E4 * Tiefe.v;
  wl_ha.v := wl.v * 1E4;
  { alternativ: alle Wurzeln werden berücksichtigt:
    wl.v:= RLD_mean.v*Flaeche.V*tiefe.v;
    wl_ha.v:= RLD_mean.v*1e8*tiefe.v;     { Wurzellängen auf einem Hektar [cm/ha]
    1e8 = Zentimeter auf ha }
  If wl_ha.v > 0.0 then
  begin
    { Berechnung scheint korrekt s. Manuskript Hängeregister Vgl 1D2D }
    Imax.v := Ar.v / 14 * 1000 / 86400 / wl_ha.v;
    { Berechnung Influxrate [mol/(cm/s)] }
    // Imax.V := Ar.v*1000/(14*86400*WL_ha.v);  //Debuggen
  end
  else
    Imax.v := 0.0;
  // Ausgabe von XY-Koord. bei statischem Modell
  if iniMethod.Option <> 'submodstruct' then
    fillChartRootDistr;
  showActConc;
end;

procedure TSubmodDiff2DRoots.InitConc;
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
  c_start.v := self.Cl_func(Tiefe.v, theta.v, N_amountsoil.v);
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

function TSubmodDiff2DRoots.avg_conz: double;
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

procedure TSubmodDiff2DRoots.createSteadyState(DiffSteadyState: double);
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

procedure TSubmodDiff2DRoots.zweid_solut(dt_globmod: real);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Zentrale Prozedur. Berechnung des Nährstofftransports im 2D-Raum
  (lineare Algebra). Cave: verschachtelter Aufbau
  ------------------------------------------------------------------------------ *)
var
  { Im folgenden werden Arrays deklariert, die eine Größe von dim_max (größter
    Index haben). Vektoren: Aus den Flüssen entsteht eine tridiagonale Matrix mit
    Haupt- und Nebendiagonalen (s. Scholl/Drews: lineare Algebra) }
  B_vektor, { Lösungsvektor }
  lower, { untere Diagonale }
  diag, { mittlere Diagonale }
  upper, { obere Diagonale }
  Sink, { Senkenterme }
  u_vektor, { unterhalb gelegener Konzentrationsvektor }
  z_vektor, { z_vektor : zu berechnender, zentral gelegener vektor }
  o_vektor: array_type; { oberhalb gelegener Konzentrationsvektor }
  { Hinweis: Da array_type auch im Original bei 0 beginnt, muss hier nichts ver-
    öndert werden. }
  Result, i: word;
  Df: real;
  x_ndx, y_ndx: integer; { Schleifenvariablen für Gitterelemente }

  SinkCellFile: Textfile;
  SinkCellFileName: string;

  procedure eine_Zeile(o_vektor, Sink: array_type; dim_z, Start, Ende: word;
    var u_vektor, z_vektor: array_type);
  (* -----------------------------------------------------------------------------
    ÜBERGEORDNETE Methode: TSubModDiff2D_k.zweid_solut
    Berechnung der Flüsse erfolgt zeilenweise.
    ------------------------------------------------------------------------------ *)
  var
    flow_1, flow_2: real;

    { In den folgenden Prozeduren werden für eine Rasterzelle die Flüsse über die
      Ränder bestimmt. }
    Procedure linker_Rand(Start: integer); // oder oberer Rand
    (* ------------------------------------------------------------------------------
      ÜBERGEORDNETE Methode: (Hilfsprozedur eine_Zeile)
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      For i := 1 to Start - 1 do
      begin
        B_vektor[i] := z_vektor[i];
        diag[i] := 0; // Vektoren werden an Rändern null gesetzt.
        upper[i] := 0;
      end;
      flow_1 := dx.v * De.v * (u_vektor[Start] - z_vektor[Start]) / dy.v * Df;
      // explizite Berechnung
      flow_2 := dx.v * De.v * (z_vektor[Start] - o_vektor[Start]) / dy.v * Df;

      B_vektor[Start] := z_vektor[Start] + flow_1 - flow_2 + Sink[Start] * Df;
      diag[Start] := De.v * dy.v / dx.v * Df + 1;
      upper[Start] := -De.v * dy.v / dx.v * Df;
    end; // End linker Rand

    Procedure Mittelteil(Start, Ende: integer);
    (* ------------------------------------------------------------------------------
      ÜBERGEORDNETE Methode: Hilfsprozedur eine_Zeile
      BESCHREIBUNG: Lösung der Diffusionsgleichung für 2 dimensionale Koordinaten
      (Gitter) mit einem alternat direction implicit Ansatz?
      Randbedingung: kein Transport über die Gittergrenzen (no flow)
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
      ÜBERGEORDNETE Methode: Hilfsprozedur eine_Zeile
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
      ÜBERGEORDNETE Methode: Hilfsprozedur eine_Zeile
      BESCHREIBUNG: Aufruf der Funktion trdiag in TRDIAG.pas. Die Funktion löst ein
      tridiagonales Gleichuungssystem vgl. Matrizenrechnung, Linearkombination.
      in tridiag.pas weitere (anschauliche) Erläuterung zum Lösungsverfahren
      ------------------------------------------------------------------------------ *)
    var
      ndx: word;
    begin
      Result := trdiag(false, dim_z, 1, lower, diag, upper, B_vektor);
      If Result <> 0 then
      begin
        { Rückgabewert zeigt lediglich an, ob die Sache funktioniert hat und wird
          verwendet, um eine Fehlermeldung auszugeben. Problem: Exceptionhandling
          angesagt? }
        showMessage('Error while solving TriDiaMatrix');
      end;
      for ndx := 1 to dim_z do
      begin
        If B_vektor[ndx] < 0.0 then
        begin
          { Negative Konzentrationen sollen nicht vorkommen! In diesem Fall werden Standard
            werte verwendet. }
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
  end; // End eine_Zeile (stimmt das?)

(* -----------------------------------------------------------------------------
  Hilfsmethoden der Zentralmethode Ende
  ------------------------------------------------------------------------------ *)
var
  start_, ende_: integer;
begin
  Df := int_dt.v / 2 * 1 / wm; { Rechenfaktor für halbe Zeitschrittweite }
  { Aufstellung des Gleichungssystems mit IMPLIZITER Formulierung für y und
    EXPLIZITER Formulierung für x }
  // Durchlaufen sämtlicher Rechenelemente (bis auf die 1 Zelle breiten Ränder

  for y_ndx := 1 to trunc(dim_y.v) do
  begin
    For i := 1 to trunc(dim_x.v) do
    begin
      Get_Sink(i, y_ndx, Sink[i]); // Berechnung der Senkenterme
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
    else // Festlegen der neuen äußeren Randbedingungen
    begin
      testForContBorder(start_, ende_, i, y_ndx, true);
      eine_Zeile(o_vektor, Sink, trunc(dim_x.v), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(dim_x.v) do
      C_xy[i, y_ndx] := z_vektor[i];
  end;

  { Aufstellung des Gleichungssystems mit IMPLIZITER Formulierung für x und
    EXPLIZITER Formulierung für y }

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
    else // Festlegen der neuen äußeren Randbedingungen
    begin
      testForContBorder(start_, ende_, x_ndx, i, true);
      eine_Zeile(o_vektor, Sink, trunc(dim_y.v), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(dim_y.v) do
      C_xy[x_ndx, i] := z_vektor[i];
  end;

  // Schreiben des Influxs mittiger Senken und Konzentration der zugeh. Zelle
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
  Zentrale Prozedur Ende
  ------------------------------------------------------------------------------ *)

procedure TSubmodDiff2DRoots.Get_Sink(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Senkenterme (Aufnahme und Mineralisation)
  [mol/s-1] in Rechenelement
  Problem: Stimmen die Einheiten?
  ------------------------------------------------------------------------------ *)
var
  i, j: word;
  NUptake, Nuptake2, Nuptake3, NUptakeGrid, NAmountRootdt,
  // Stickstoffaufnahmerate für aktuelle Wurzel[dg/dt]
  SumUptake, x, Db: real;
  De_SinkGrid: double;
begin
  get_minGrid(x_loc, y_loc, s); // Berechnung Mineralisation
  NUptake := 0.0;
  SumUptake := 0.0;
  De_SinkGrid := De.v / theta.v;
  for i := 1 to trunc(Num_Roots.v) do
  begin
    // Testen, ob sich im Rechenelement eine Senke befindet, dann Aufnahme berechnen
    if ((RasterData.PosArr[i].xi = x_loc) and (RasterData.PosArr[i].yi = y_loc))
    then
    begin
      x := sqrt(dx.v * dy.v / pi);
      // Radius eines Kreises der der Mittelzelle entspricht
      Db := Dl.v * 3.35 * theta.v * theta.v * theta.v; //
      { Innere Randbedingung: Konstanter Influx, dieses Szenario lässt sich über den
        Parameter Ar steuern, weiterer Einflussfaktor ist die berechnete Wl_ha }
      If Uptake_function.Option = lowercase('ConstInflux') then
        NUptake := Imax.v; // mol/cm*s
      // Innere Randbedingung: Zero sink
      If Uptake_function.Option = lowercase('ZeroSink') then

        // Nuptake :=
        { Berechnet wird der Fluss unter Berücksichtigung des aufnehmenden Anteils der
          Wurzeloberfläche. Konzentrationsgradient reicht von der Mitte der benachbarten
          Zelle bis zum Scheitelpunkt der Wurzeloberfläche, wobei die Wurzel zentral in
          der Zelle lokalisiert ist, vgl. Hängeregister Material 2D-Modell.Hinweis zum
          Nenner: 1. Term ist der Konzentrationsgradient, 2. Term die Kante bzw. die
          anteilige aufnehmende W'Oberfläche. }
        { De.V*C_xy[x_loc-1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc+1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc, y_loc-1]/dy.V*dx.V
          +De.V*C_xy[x_loc, y_loc+1]/dy.V*dx.V; }
        { alt. Berechnung der Aufnahme durch Senke: Gradient ist um den Rad_Wurzel.V ver-
          mindert, Fluss in jeder Richtung entspricht einem Viertel des Wurzelumfangs (bei
          Annahme zylindrischer Wurzel. }
        { De.V*C_xy[x_loc-1, y_loc]/(dx.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc+1, y_loc]/(dx.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc, y_loc-1]/(dy.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc, y_loc+1]/(dy.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2); }

        { NUptakeGrid:= De.V*C_xy[x_loc-1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc+1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc, y_loc-1]/dy.V*dx.V
          +De.V*C_xy[x_loc, y_loc+1]/dy.V*dx.V; }
        { alt. Berechnung 2:im Inneren der aufnehmenden Rechnezelle wurde eine Aufnahme
          nach dem Muster des 1D - Ansatzes angenommen, wobei die Fläche des Recheelemen-
          tes mit der Fläche des EWZ gleichgesetzt wurde (s.o. Berechnung von x, dann
          wird Fluss im RE für radiale Koordinaten gerechnet. }
        // Nuptake :=     C_xy[x_loc, y_loc]*2*pi*Db/ln(x/(1.65*Rad_wurzel.v));
        { alt. Berechnung 3 (vgl. Kage, Diss. Gl. 3.6.29, Hängeregister (Umformung nach
          In). Es wird dabei davon ausgegangen, dass Cl_min der Konzentration an der Wurzel
          oberfläche entspricht und Null werden kann }
        NUptake := (C_xy[x_loc, y_loc] - clmin.v) * 2 * pi * Db /
          (-1 / 2 + (sqr(x) / (sqr(x) - sqr(Rad_Wurzel.v)) *
          ln(x / Rad_Wurzel.v)));

      { alt. Berechnung 4 (nach Moncayo, Gl. 19 und 20: }
      { Nuptake :=
        De_SinkGrid*C_xy[x_loc-1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc+1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc-1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc+1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2); }
      { Implementierung mit Cl_min }
      { ZeroSink     : In_arr[pos] := De.v*(C_xy[x_loc-1, y_loc]-clmin.v)/
        dx.v*dy.v+De.v*(C_xy[x_loc+1, y_loc]-clmin.v)/dx.v*dy.v
        +De.v*(C_xy[x_loc, y_loc-1]-clmin.v)/dy.v*dx.v+De.v*
        (C_xy[x_loc,y_loc+1]-clmin.v)/dy.v*dx.v; }
      // Innere Randbedingung: Michaelis-Menten-Kinetik
      If Uptake_function.Option = lowercase('MM') then
        // NUptake :=  Influx_f( Imax.v, Km.v, C_xy[x_loc, y_loc]);
        NUptake := influx_fVar(Imax.v, Km.v, C_xy[x_loc, y_loc], x, Db);
      // Influx in die Senke im Zeitschritt
      RasterData.PosArr[i].NInflux := NUptake;
      If Uptake_function.Option <> lowercase('ZeroSink') then
        SumUptake := SumUptake + NUptake
      else
        SumUptake := NUptake;
      // Berechnen der kumulierten aufgenommenen N-Mengen für die Senken
      { Problem: Hier sitzt noch ein Denkfehler: }
      NAmountRootdt := RasterData.PosArr[i].NInflux * 14 / 1000 * int_dt.v;
      // NAmountRootdt:=RasterData.PosArr[i].NInflux*14/1000*86400/int_dt.V;
      RasterData.PosArr[i].NAmountdt := NAmountRootdt;
      RasterData.PosArr[i].SumNMenge := RasterData.PosArr[i].SumNMenge +
        NAmountRootdt;
    end;
  end;
  { Mineralisation }
  s := s - SumUptake;
end;

procedure TSubmodDiff2DRoots.get_minGrid(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Mineralisation [mol/s-1] in Rechenelement
  Problem: Stimmen die Einheiten?
  ------------------------------------------------------------------------------ *)
var
  pos: word;
begin
  s := Min_S.v * vol_Element; { Senkenterm aus Mineralisation [mol/s] }
end;

procedure TSubmodDiff2DRoots.CalcRates;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: In der Methode wird die Ablaufsteuerung des Submodells zur Ratenbe-
  rechnung aufgerufen.
  ------------------------------------------------------------------------------ *)
var
  ConcFieldName: string;
  ConcField, UptakeFile: Textfile;
  i, j: integer;
  last_dt,
  { Differenz aus concBefore und Conc }
  concBegin, // Durchschnittskonzentration vor Berechnung Flüsse [mol/cm^3]
  ConcAfter, { Durchschnittskonzentration nach Berechnung Flüsse [mol/cm^3]
    und vor der Neuverteilung aufgenommenen Konzentrationen auf
    die Rechenelemente }
  // SumOfInternalTimeSteps,
  sumNAmountRootsdt { Aufgenommene N-Menge aller gültigen Wurzeln im Zeitschritt }
    : real;
  TimeStepAdaption: boolean;
begin
  inherited CalcRates; { Im Basismodell passiert nichts (auch kein inherited) }
  ConcFieldName := ConcFieldDataFile.Option;
  // Kommunikation mit dem Strukturmodell und Anzeigen der WAP in MathImNutrUptake
  // Datei mit den Ausgaben für die Senken wird neu angelegt:
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
    // solange keine Wurzeln vorhanden, werden auch keine Flüsse berechnet.
    if Num_Roots.v < 1 then
      exit;
    fillChartRootDistr;
  end;
  { Da sich in dynamischem Modell theta ändern könnte muss De in jedem Zeitschritt
    neu berechnet werden: }
  De.v := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  // De.v:=Dl.v*3.35*sqr(theta.v);
  TimeStepAdaption := false;
  SumOfInternalTimeSteps := 0.0;
  last_dt := 0.0;
  ActArFromConc.v := 0;
  ActAr.v := 0;
  repeat
    if int_dt.v < max_dt.v then
      int_dt.v := int_dt.v * 1.1; // Erhöhung des Zeitschrittes
    If int_dt.v > globtime.C * 86400 then
      int_dt.v := globtime.C * 86400;
    { Ende des Tages überschritten mit neuem Zeitschritt ? }
    If SumOfInternalTimeSteps + int_dt.v > globtime.C * 86400 then
    begin
      last_dt := int_dt.v; // save old timestep length
      int_dt.v := (globtime.C * 86400 - SumOfInternalTimeSteps);
      TimeStepAdaption := true;
    end;
    // Berechnung der Flüsse
    concBegin := avg_conz;
    zweid_solut(int_dt.v);
    SumOfInternalTimeSteps := SumOfInternalTimeSteps + int_dt.v;
    { In jedem Zeitschritt wird die kumulierten N-Aufnahmen der einzelnen, nicht
      randständigen Senken aufsummiert. Rückgabewert ist die summierte NMenge, die
      die Wurzeln in einem Zeitschritt aufgenommen wurde }
    sumNAmountRootsdt := calcAmountUptakeRoots;
    Sum_N_AmountRoots.v := Sum_N_AmountRoots.v + sumNAmountRootsdt;
    { Am Ende jedes internen Zeitschritts wird der aufgenommene Influx wieder an die
      Rechenelemente verteilt: }
    { Falls ein Steady-State-Zustand erzeugt werden soll, dann wird die konstante
      Konzentration in jedem Zeitschritt wieder hergestellt. }
    ConcAfter := avg_conz;
    ActArFromConc.v := ActArFromConc.v + Mg_func(Tiefe.v, theta.v,
      concBegin - ConcAfter);
    { Für die Berechnung der aktuellen Aufnahmerate werden nur Wurzeln berücksichtigt,
      die nicht in den Rändern liegen. }
    ActAr.v := ActAr.v + calcActArdt;
    if SteadyState.Option = 'yes' then
      createSteadyState(concBegin - ConcAfter);
    // Schreiben des Konzentrationsfeldes im letzten internen Zeitschritt
    if SumOfInternalTimeSteps >= self.globtime.C * 86400 then
    begin
      if self.writeSinkCellFile.Option = 'yes' then
      begin
        assignfile(ConcField, ConcFieldName);
        rewrite(ConcField);
        // Neuanlage, d.h. nur das endgültige concField wird geschrieben
        // Header
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
  // wenn eine Adaption der Zeitschrittweite vorgesehen ist
  If TimeStepAdaption then
    int_dt.v := last_dt; // restore old timestep length
  If int_dt.v <= 0.0 then
    showMessage('time step error');
  // Ausgabe der Konzentrationsänderung
  showActConc;
  // Schreiben von gültigen Wurzeldaten in eine Datei
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
  ZUGEHÖRIGE KLASSE:  TSubmodRootDiff
  BESCHREIBUNG: Methode wurde überschrieben, um die Zeitschrittweite sukzessive
  zu verändern.
  ------------------------------------------------------------------------------ *)
var
  sumNAmountRoots, n_me_alt: real;
  // Zwischenspeicher für die ursprüngliche N-Menge
begin
  // solange keine Wurzeln vorhanden, werden auch keine Flüsse berechnet.
  if Num_Roots.v < 1 then
    exit;
  inherited Integrate;
  // in der Basisklasse geschieht nichts auch kein inherited
  n_me_alt := N_amountsoil.v;
  c_av.v := avg_conz; // Durchschnittskonz.
  N_amountsoil.v := Mg_func(Tiefe.v, theta.v, c_av.v);
end; // End TSubmodRootDiff2D.Integrate

procedure TSubmodDiff2DRoots.clearLists;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Zurücksetzen von Listeneinträgen
  ------------------------------------------------------------------------------ *)
begin
  TSRPLightList.Clear;
end;

procedure TSubmodDiff2DRoots.calcRootPosAsIndex;
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
    // Rückspeichern
    RasterData.PosArr[i].x := xTemp;
    RasterData.PosArr[i].y := yTemp;
  end;
end;

procedure TSubmodDiff2DRoots.updateFromStructModell;
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
  RasterData.errasePosArr;
  TSRPLightList := MyStructModel.getSRPList;
  Num_Roots.v := TSRPLightList.Count;
  // Füllen des Pos-Arrays mit XY-Koordinaten
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
  BESCHREIBUNG: Zeigt die aktuelle Konzentration im TMathImage an
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
  BESCHREIBUNG: Schreibt eine Datei mit der N-Aufnahme aller Senken (und wg. Zu-
  ordnung auch mit lf. Nr. und Koord.
  ------------------------------------------------------------------------------ *)
var
  UptakeFile: Textfile;
  i, j: integer;
  { Nur Senken, die nicht im Rand und im Beobachtungsfenster liegen werden ausgege-
    ben }
  PosArr_middle: Array of TPointDoubleType;
begin
  { Wenn Datei noch nicht vorhanden, neu anlegen }
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
    // Punkt nicht in den vertikalen Rändern
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
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
  // Header schreiben
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
  BESCHREIBUNG: Boolesche Funktion, die True zurückliefert, wenn die Datei
  vorhanden ist, andernfalls wird False zurückgegeben. Wenn die Datei schon
  existiert, wird sie geschlossen.
  ------------------------------------------------------------------------------ *)
var
  F: file;
begin
{$I-}
  assignfile(F, FileName);
  FileMode := 0; { Datei mit Schreibschutz versehen. }
  Reset(F);
  closefile(F);
{$I+}
  FileExists := (IOResult = 0) and (FileName <> '');
end; { FileExists }

function TSubmodDiff2DRoots.calcAmountUptakeRoots: double;
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
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (RasterData.PosArr[i].y >= horizMargin.v) and
      (RasterData.PosArr[i].y <= DimensionY.v - horizMargin.v) then
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

function TSubmodDiff2DRoots.convertConcToAmount(i: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rechnet die Aufnahme [mol/cm*s] in Menge [kg/d], für übergebene
  Wurzeln.
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000;
var
  ha: integer;
  NAmountRoot: double;
begin
  { NINflux in [mol/cm/s }
  NAmountRoot := RasterData.PosArr[i].NInflux * kg_mol * Tiefe.v * int_dt.v;
  Result := NAmountRoot;
end;

function TSubmodDiff2DRoots.calcActArdt: double;
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
    if (RasterData.PosArr[i].x >= verticMargin.v) and
      (RasterData.PosArr[i].x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
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
    // Berücksichtigt nur den Influx aus dem letzten internen Zeitschritt:
    Result := AVInflux * 14 / 1000 * wl_ha.v * int_dt.v;
    // Result:= AvInflux*14/1000*wl_ha.v
    // AvNMenge:=AvNMenge/rootCounter;
    // ActAr.v := AvNMenge*wl_ha.v;
  end;
end;

procedure TSubmodDiff2DRoots.testForContBorder(var start_, ende_: integer;
  x_ndx, y_ndx: integer; zeile: boolean);
(* ------------------------------------------------------------------------------
  Testet, ob sich in Zeile oder Spalte Zellen befinden, die von der Containerwand
  geschnitten werden
  x_ndx, und y_ndx bezeichnen die erste Zelle der jeweiligen Zeile oder Spalte.
  Rückgabewert ist
  ------------------------------------------------------------------------------ *)
var
  cutContWall: boolean;
  i: integer;
  upperLeft, // Cart. Coord. der oberen linken Ecke der Gridzelle
  bottomRight, // Cart. Coord. der unteren linken Ecke der Gridzelle
  VektUppLeft_ContCent, VektBottRight_ContCent: r2;
  distUpperLeft, distBottomRight: double;
begin
  cutContWall := false;
  if zeile = true then // Zeilen werden gescannt
  begin
    for i := 1 to trunc(dim_x.v) do // Bestimmen der Startzelle
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
        break; // Abbruch nötig, da die erste Fundstelle berücksichtigt wird
      end;

    end;
    for i := trunc(dim_x.v) downto 1 do // Bestimmen der Startzelle
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
        break; // Abbruch nötig, da die erste Fundstelle berücksichtigt wird
      end;

    end;
  end
  else // Spalten werden gescannt
  begin
    for i := 1 to trunc(dim_y.v) do // Bestimmen der Startzelle
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
        break; // Abbruch nötig, da die erste Fundstelle berücksichtigt wird
      end;

    end;
    for i := trunc(dim_y.v) downto 1 do // Bestimmen der Startzelle
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
        break; // Abbruch nötig, da die erste Fundstelle berücksichtigt wird
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
  Berechnet den Betrag = Länge eines Vektors
  ------------------------------------------------------------------------------ *)
var
  length: double;
begin
  length := sqrt(sqr(vect[0]) + sqr(vect[1]));
  Result := length;
end;

function TSubmodDiff2DRoots.vectorSubtrakt2D(vect2, vect1: r2): r2;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Subtrahiert vector_2 von vector_1 und gibt den resultierenden
  Vektor zurück, der in Richtung Vektor 1 zeigt.
  ------------------------------------------------------------------------------ *)
var
  vector_result: r2;
begin
  vector_result[0] := vect1[0] - vect2[0];
  vector_result[1] := vect1[1] - vect2[1];
  Result := vector_result;
end;

end.
