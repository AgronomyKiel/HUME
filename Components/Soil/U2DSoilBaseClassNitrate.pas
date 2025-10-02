unit U2DSoilBaseClassNitrate;

 {$J+}
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid,
  UMod, UState, Diffko, SubmodRootStructureNew, URootObject, URootUptakeFunctions,
  U2DSoilBaseClasses, MathImge;

type

  /// <summary> Declaration of class TSubmodRootDiff. Class based on base class for derived diffusion models
  /// implements further details for nitrate budget but without explicit formulation for
  ///  nitrate transport which are defined in derived classes
  /// </summary>
  TBaseSubmodRootDiffNitrate = class(TBaseSubmodRootDiff)
  private

    /// <summary>Protected declarations, also accessible by derived classes</summary>
  protected

    /// <summary> Potential N uptake rate [Kg N/ha*d]</summary>
    potNUptakerate: TPar;

    /// <remarks>Mineralization model not yet available but should be implemented for both models</remarks>
    /// <summary>Mineralization rate [kg N/ha*d]</summary>
    minera: TPar;

    /// <summary>Minimum soil solution concentration [Mol/l], also needed for the numerical solution in the 1D model; note: originally in micromol/l</summary>
    Clmin: TPar;

    /// <summary>Michaelis-Menten constant [mol/cm3]</summary>
    Km: TPar;


    /// <summary>
    /// anfängliche interne Zeitschrittweite [d]
    /// </summary>
    ini_dt: TPar;

    /// <summary>
    ///   initial soil nitrate [kg N/ha]
    /// </summary>
    IniSoilNitrate: TPar;

    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>

    /// <summary>Member HUME base class TState (state variables)</summary>
    /// <summary>N amount [kg N/ha], also basis for calculating concentrations in the calculation elements; see Kage dissertation p.79 where concentrations of 10.0 micromol/l were assumed</summary>
    N_AmountSoil: TState;
    /// <summary>Cumulative amount of N taken up by the roots [kg N/ha] for the specified depth</summary>
    Sum_N_AmountRoots: TState;
    /// <summary>Member HUME base class TVar (variables)</summary>

    /// <summary>Mineralization rate [Mol/cm^3*d]</summary>
    Min_S: TVar;
    /// <summary>Initial concentration [mol/cm^3], calculated from the initial N amount; the 1D model can also calculate concentrations</summary>
    c_start: TVar;
    /// <summary>Average concentration in the soil solution [Mol/cm^3]</summary>
    cl_av: TVar;

   /// <summary>maximum influx [mol/cm*d]</summary>
   Imax: TVar;

   ActArFromConc : TVar;

   ActAr : TVar;

    /// <summary>
    /// average Concentration [mol/cm3]
    /// </summary>
    c_av: TVar;


    /// <summary>
    ///   Potential N Influx rate [mol/cm/d]
    /// </summary>
    PotentialNInfluxrate : TVar;


    /// <summary>Type of uptake calculation</summary>
    NitrateUptakeFunction: TOption;

    /// <summary>specify whether nutrient uptake of individual sinks should be written to a file</summary>
    OutputSink: TOption;

    /// <summary>specify the mode in which steady state should be calculated (with or without margins)</summary>
    CalcModeSteadyState: TOption;

    /// <summary>specify whether concentrations should be displayed or not</summary>
    ShowConc: TOption;

    /// <summary>flag whether a steady state should be generated in the 2D model or not</summary>
    SteadyState: TOption;

    /// <summary>path and name of the output file for nutrient uptake of individual sinks</summary>
    RootSinkOutpDataFile: TOption;

    // Switches to control whether the following files are written.
    writeConcField: TOption;
    writeSinkCellFile: TOption;
    ConcFieldDataFile: TOption;
    { path and name of the output file for nutrient uptake of
      individual sinks }
    SinkCellFileFile: TOption; { path and name of the output file for nutrient
      uptake of individual sinks }
    /// <summary>deletes boundary roots from PosArr</summary>
    DelMarginRoots: TOption;
    /// <summary>switch for growth in pots</summary>
    ContGrowth : TOption;

    // Helper methods
  function influx_fVar(Imax, Km, ClAv, x, Db: double): double;
  function ConvertConcToAmount(i: integer): double;
  function calcActArdt: double;
  procedure writeNitrateUptakeSinkToFile;

  public
    /// <summary>
    ///   effective Diffusion coefficient [cm2/d]
    /// </summary>
    De : TVar;

    /// <summary>
    ///   Diffusion coefficient of nitrate in water [cm2/d]
    /// </summary>
    Dl : TVar;

    procedure createAll; override;

    // procedure Init(var GlobModReferenz: TMod); override;
    procedure Init(var GlobMod: TMod); override;

  end; { Ende Deklaration TSubmodRootDiff }

implementation



/// <summary>Implementierung TSubmodRootDiff</summary>
/// <summary>
/// Creates and initializes state variables, variables and parameters. The first
/// parameter of the function call passes a string identical to the identifier and
/// can be searched for. The second parameter contains a string indicating the
/// unit used ([-] for dimensionless parameters, etc.). The third parameter is the
/// actual floating-point value. For an explanation of the identifiers, see the
/// declaration.
/// </summary>
procedure TBaseSubmodRootDiffNitrate.createAll;
begin
  inherited createAll;
  ParCreate('Ar', '[kg N/ha*d]', 0, potNUptakerate, 'Potential nitrate uptake rate');
  ParCreate('Minera', '[kg N/ha*d]', 0, minera, 'Mineralization rate');
  ParCreate('Clmin', '[mol/l]', 0, Clmin, 'Minimum concentration');
  ParCreate('Km', '[mikromol/l]', 0, Km, 'Half-saturation concentration');
  ParCreate('ini_dt', '[d]', 1/24, ini_dt, 'Initial internal time step');
  ParCreate('iniSoilNitrate', '[kg N/ha]', 30, iniSoilNitrate, 'Initial nitrate amount in soil');

  // Create and initialize TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 30, false, N_AmountSoil,
    'N amount in the soil');
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, Sum_N_AmountRoots,
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


  OptCreate('ContGrowth', 'no', ContGrowth, 'Switch for continuous growth of the root system');
  ContGrowth.OptionList.add('yes');
  ContGrowth.OptionList.add('no');

  OptCreate('ShowConc', 'True', ShowConc, 'Switch for showing concentration');
  ShowConc.OptionList.add('true');
  ShowConc.OptionList.add('false');

  OptCreate('CalcModeSteadyState', 'withoutMargin', CalcModeSteadyState, 'Calculation mode for steady state');
  CalcModeSteadyState.OptionList.add('withMargin');
  CalcModeSteadyState.OptionList.add('withoutMargin');

  OptCreate('SteadyState', 'no', SteadyState, 'Switch for steady state');
  SteadyState.OptionList.add('yes');
  SteadyState.OptionList.add('no');

  OptCreate('RootDistribution', 'Random', RootDistribution, 'Root distribution method');
  RootDistribution.OptionList.add('Random');
  RootDistribution.OptionList.add('Regular');
  RootDistribution.OptionList.add('FromSource');

  OptCreate('DelMarginRoots', 'no', DelMarginRoots, 'Delete margin roots');
  DelMarginRoots.OptionList.add('yes');
  DelMarginRoots.OptionList.add('no');

  OptCreate('writeConcField', 'no', writeConcField, 'Switch for writing concentration field');
  writeConcField.OptionList.add('no');
  writeConcField.OptionList.add('yes');

  OptCreate('writeSinkCellFile', 'no', writeSinkCellFile, 'Switch for writing sink cell file');
  writeSinkCellFile.OptionList.add('no');
  writeSinkCellFile.OptionList.add('yes');

  OptCreate('OutputSink', 'no', OutputSink, 'Switch for outputting sink');
  OutputSink.OptionList.add('no');
  OutputSink.OptionList.add('yes');

  OptCreate('ConcFieldDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv', ConcFieldDataFile, 'Concentration field data file name');
  ConcFieldDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv');

  OptCreate('SinkCellFileFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv', SinkCellFileFile, 'Sink cell file name');
  SinkCellFileFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv');

  OptCreate('RootSinkOutpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat', RootSinkOutpDataFile, 'Root sink output data file name');
  RootSinkOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat');

  OptCreate('OutputXY', 'no', OutputXY, 'Switch for outputting XY data');
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Paths for model comparison 1D vs 2D }
  { Paths to input and output files are identical for both submodels. Running both
    submodels simultaneously in one model run only makes sense for comparison. }

end; // End TSubmodRootDiff.CreateAll



procedure TBaseSubmodRootDiffNitrate.Init(var GlobMod: TMod);

var
  DimXMiddle, // Dimension der mittigen Fläche in x-Richtung [cm]
  DimYMiddle // Dimension der mittigen Fläche in y-Richtung [cm]
    : double;
  i: integer;

begin
  inherited;
  SinkCellFileWasCreated := false;
  FileWasCreated := false;
  hasWritten := false;
  // Listen leeren

  { Keine dynamische Verbindung zwischen 2D-Diffmodell und Strukturmodell in den
    Verteilungsvarianten regular oder random }
  if (iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option <> 'fromsource') then
  begin
    RootDistribution.Option := 'fromsource';
    // showMessage('Strukturmodell setzt Einstellung lognormal voraus.Wurde umgestellt.');
  end;
  inherited;

  De.v := D0NO3*f_Tortuosity(Theta.v);

  // Berechnung der Anzahl der mittigen Rechenelemente
  dim_xMiddle.v := DimXMiddle / dx.v;
  dim_yMiddle.v := DimYMiddle / dy.v;
  AreaMiddle.v := DimXMiddle * DimYMiddle;
  N_amountsoil.v := IniSoilNitrate.v; // kg N/ha

  c_av.v := (N_amountsoil.v*1000/14)/WAmount.v;
  c_start.v := c_av.v;
  // N_AmountSoil.v := mg_func(Tiefe.v, Theta.v, c_av.v);//Debuggen
  int_dt.v := ini_dt.v; // Zuweisung der Startzeitschrittweite ...

  { Volumen der betrachteten Bodenschicht[cm3] }
  { Berechnung Mineralisationsrate in [Mol/cm^3*d] }
  Min_S.v := minera.v / 14 * 1000 / 86400 * 1 / (Depth.v * 1E8);
  // Initialisieren der Visuallisierung der Nährstoffaufnahme


    { Ausschluss der Ränder; sollte nicht durchgeführt werden, da die Wurzeln zwar
    vorhanden sein und auch Aufnahme durchführen sollten, aber nicht berücksichtigt
    werden sollten }
  if DelMarginRoots.Option = 'yes' then
    removeMarginRoots;
  calcNumberConsRoots;

  If wl_ha.v > 0.0 then
  begin
    { Berechnung scheint korrekt s. Manuskript Hängeregister Vgl 1D2D }
    Imax.v := potNUptakerate.v / 14 * 1000 / wl_ha.v;
    { Berechnung Influxrate [mol/(cm/d)] }
    // Imax.V := Ar.v*1000/(14*86400*WL_ha.v);  //Debuggen
  end
  else
    Imax.v := 0.0;
  // Ausgabe von XY-Koord. bei statischem Modell
  if iniMethod.Option <> 'submodstruct' then
    fillChartRootDistr;

end;


function TBaseSubmodRootDiffNitrate.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
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


function TBaseSubmodRootDiffNitrate.convertConcToAmount(i: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rechnet die Aufnahme [mol/cm*d] in Menge [kg/d], für übergebene
  Wurzeln.
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000;
var
  ha: integer;
  NAmountRoot: double;
  ARoot : TRootObject;
begin
  { NINflux in [mol/cm/d }
  ARoot := TRootObject(RasterData.Rootlist.objects[i]);
  ARoot.NAmount := ARoot.NInflux * kg_mol * Depth.v * int_dt.v;
end;

function TBaseSubmodRootDiffNitrate.calcActArdt: double;
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
  ARoot: TRootObject;
begin
  rootCounter := 0;
  AvNMenge := 0;
  AVInflux := 0;
  for i := 0 to trunc(RasterData.NRoots)-1 do
  begin
    ARoot := TRootObject(RasterData.Rootlist.objects[i]);
    // Punkt nicht in den vertikalen Rändern
    if (ARoot.x >= verticMargin.v) and
      (ARoot.x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (ARoot.y >= horizMargin.v) and
      (ARoot.y <= DimensionY.v - horizMargin.v) then
    begin
      AVInflux := AVInflux + ARoot.NInflux;
      AvNMenge := AvNMenge + ARoot.NAmount;
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


procedure TBaseSubmodRootDiffNitrate.writeNitrateUptakeSinkToFile;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Schreibt eine Datei mit der N-Aufnahme aller Senken (und wg. Zu-
  ordnung auch mit lf. Nr. und Koord.
  ------------------------------------------------------------------------------ *)
var
  UptakeFile: Textfile;
  i, j: integer;
  { Nur Senken, die nicht im Rand und im Beobachtungsfenster liegen werden ausgege-
    ben }
  PosArr_middle: Array of TRootObject;
  ARoot : TRootObject;

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
    ARoot := TRootObject(RasterData.Rootlist.objects[i]);
    // Punkt nicht in den vertikalen Rändern
    if (ARoot.x >= verticMargin.v) and
      (ARoot.x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (ARoot.y >= horizMargin.v) and
      (ARoot.y <= DimensionY.v - horizMargin.v) then
    begin
      PosArr_middle[j].x := ARoot.x;
      PosArr_middle[j].y := ARoot.y;
      PosArr_middle[j].xi := ARoot.xi;
      PosArr_middle[j].yi := ARoot.yi;
      PosArr_middle[j].NInflux := ARoot.NInflux;
      PosArr_middle[j].WInflux := ARoot.WInflux;
      PosArr_middle[j].nroot := ARoot.nroot;
      PosArr_middle[j].area := ARoot.area;
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
    write(UptakeFile, PosArr_middle[i].nroot, ' ');
    write(UptakeFile, PosArr_middle[i].x, ' ');
    write(UptakeFile, PosArr_middle[i].y, ' ');
    write(UptakeFile, PosArr_middle[i].area, ' ');
    write(UptakeFile, PosArr_middle[i].NInflux, ' ');
    writeln(UptakeFile);
  end;
  closefile(UptakeFile);
end;


end.
