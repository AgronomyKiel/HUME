unit SubmodRootDiff1DRapp;

{ N-Aufnahmemodell nach Rappolt }
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  UMod, U2DSoilBaseClasses, USubmodRoot2dDiffNitrate, UState, AdvGrid;

type
  // Zeigertypen
  Pdouble = ^double;
  // Arrays
  r2 = array [0 .. 1] of double; // Vektor im Punktraum

  /// <summary>
  ///  class for random points
  /// </summary>
  TRandomPoint = class(TObject)
    RandomPointPos: TRootPosition;
    shortestDist, { Kürzeste Distanz [cm] }
    shortDist_m, { Kürzeste Distanz [m] }
    quadShortDist_m, { Quadrierte kürzeste Distanz [m] }
    y { Y-Variable nach Rappolt, S.107 (dimensions-
      lose,quadratische Distanz [-] }
      : double;

    constructor create;
  end;

  TSubmodRootDiff1DRapp = class(TSubmodRoot2DDiffNitrate)
  private

    widthMiddle, heigthMiddle, RLD_m, { Wurzellängendichte [m/m^3] }
  RadWurzel_m, { Wurzelradius [m] }
  De_m { Effektiver Diffusionskoeffizient [m^2/s] }
    : double;

    { Private-Deklarationen }
    ArrayHasFilled: boolean; { Schalter erlaubt einmalige Berechnung der ein
      schlägigen Arrays }
    x1_temp, // Zwischenspeichern der Range für die Nullstellensuche
    x2_temp: double;
    RandomPointList: TList; // Liste mit zufällig verteilten Punkten
    DistFile: TextFile;
    { Arrays für absolute und relative Häufigkeiten in den Klassen, in der ersten
      Spalte stehen die Klassengrenzen, in der zweiten Spalte die absoluten bzw. rela-
      tiven Häufigkeiten. }
    absFrequencyArr, relFrequencyArr,
    { Relative Häufigkeit entspricht der Wahrscheinlichkeit
      in den einzelnen Klassen }
    // Arrays für quadratische Skala:
    quadAbsFrequencyArr, quadRelFrequencyArr: array of array of double;
    { Array mit den Nährstoffaufnahmen in den einzelnen Klassen }
    uptakeArr,
    { Array mit Wichtungsfaktoren }
    weightArr, // für lineare Skala
    quadWeightArr, // für quadratische Skala
    { aj- Werte (quadrat. Zylindergrößen) für Berechnung der N-Aufnahme in den Klassen
      nach Youngs-Gardner }
    a_j: array of double;

    { Variable für initial im Boden vorhandene N-Menge }
    nullstelle, initAmountNSoil: double;
    procedure calcN_AmountSoilEquil;
    procedure calcArr;
    procedure calcUptakeClasses;
    procedure calcUptakeClassesYoungs;
    (* -----------------------------------------------------------------------------
      Hilfsfunktionen
      ------------------------------------------------------------------------------ *)
    function vectorSubtraktR2(vector_a, vector_b: r2): r2;
    procedure CalcShortestDist;
    function CalcBorderDist(ARandomPoint: TRandomPoint;
      indexNearestPoint: integer): double;
    function calcDistance(KoordWAP, KoordRandPoint: r2): double;
    procedure writeDistances;
    procedure resetLists;
    procedure resetArrays;
    procedure calcFrequencies;
    procedure calcweightFactors;
    // Berechnungen für quad. Skala
    procedure calcFrequenciesQuad;
    procedure calcweightFactorsQuad;
    (* ------------------------------------------------------------------------------
      Hilfsfunktionen für Rappolt, Youngs and Gardner (Verwendung von Besselfunktionen
      für die Aufnahmeberechnung)
      ------------------------------------------------------------------------------- *)
    procedure calcRoot(roh: double);
    FUNCTION fx(alpha, roh: real): real; // Berechnung der Nullstellen
    PROCEDURE zbrac(VAR x1, x2: real; VAR succes: boolean; roh: double);
    function rtbis(x1, x2, xacc, roh: real): real;
    function bessj(n: integer; x: real): real;
    function bessj0(x: real): real;
    function bessj1(x: real): real;
    function bessy(n: integer; x: real): real;
    function bessy0(x: real): real;
    function bessy1(x: real): real;
  protected
    numb_classesDist: integer; { Anzahl der Klassen versch. Distanzintervalle }
    { Protected-Deklarationen }
    (* -----------------------------------------------------------------------------
      Hume-Variablen
      ------------------------------------------------------------------------------ *)
    // Zustandsvariablen
    N_MengeAnteil: TState;
    // Parameter
    numb_RandomPoints, threshold, { Für Rappolt, S.127:
      Schwellenwert, ab welcher prozentualen Änderung soll
      aufgehört werden nach Nullstellen zu suchen [%].
      Bsp: 0.1 bedeutet, wenn die Änderung im Vergleich zur
      Berechnung für letzten Alpha-i-Wert geringer als 0.1
      Prozent ist, dann wird abgebrochen. }
    { Folgende initialen x-Werte werden verwendet für Berechnung der Nullstellen,
      Das Intervall von X0 bis x1 wird verwendet um die Funktion in Bereiche zu unter-
      teilen, in denen sich genau eine Nullstelle befindet. }
    x1, x2, comp_prec { Präzision des Computers, wird verwendet, um die Toler-
      anz für das Finden der Nullstellen verwendet wird. [-] }

      : TPar;
    // Variablen
    { für alle Parameter, die in die Gleichung G(A1, A2) eingehen, vgl. Gl. 7.A3,
      werden TVar angelegt. }
    K, { Absorptionskonstante, dimensionslos [-] }
    v_s, { Volumenfraktion der Wurzel im Wurzelsystem [-] }
    tau_s, { Zeitkonstante für das Wurzelsystem [s] }
    sumWeight: TVar;
    // Optionen
    compareMode, { Schalter mit dem festgelegt wird, ob das 1D-Modell
      für den Vergleich mit dem 2D-Modell betrieben werden soll
      = Einstellung 'yes':
      Es wird lediglich die N-Menge im Boden im  GG-Zustand
      Influx=Mineralisation berechnet, Aufnahme der Wurzeln
      wird nicht berechnet (vgl. Diss Kage, Gleichung 3.6.43)
      oder nicht
      = Einstellung 'no':
      Lösung nach Tinker/Nye (Gl. 10.28; Berechnung der
      Aufnahme der Wurzeln sowie der im Boden vorhandenen
      N-Mengen aus initial vorhandener N-Menge und Aufnahme
      der Wurzeln }
    numb_classes_dist, { Anzahl der Klassen der kürzesten Distanzen }
    distanceFile, { Datei und Pfad in die die berechnetenen kürzesten Dis-
      tanzen zwischen Wurzelpunkt und zufälligem Punkt ge-
      schrieben werden sollen. }
    RootDistribution,
      Model { Schalter für die Auswahl des zu verwendenden Modells:
      Tinker-Nye, oder YoungsGardner }
      : TOption;
  public
    { Public-Deklarationen }
    procedure createAll; override;
    // procedure Init(var GlobModReferenz: TMod); override;
    procedure init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
  published
    { Published-Deklarationen }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Soil2D', [TSubmodRootDiff1DRapp]);
end;

{ TSubmodRootDiff1DRapp }

procedure TSubmodRootDiff1DRapp.CalcRates;
begin
  // inherited;
  { auskommentiert, da analytische Lösung }
end;

procedure TSubmodRootDiff1DRapp.createAll;
begin
  inherited;

  RandomPointList := TList.create;
  (* -----------------------------------------------------------------------------
    Erzeugen Hume-Parameter
    ------------------------------------------------------------------------------ *)
  // Zustandsvariablen
  StateCreate('N_MengeAnteil', '[]', 0, false, N_MengeAnteil);
  // Parameter
  ParCreate('threshold', '[%]', 0.1, threshold);
  // 0.1 Prozent Punkte per default
  ParCreate('numb_RandomPoints', '[-]', 1000, numb_RandomPoints);
  // 1000 Punkte per default
  ParCreate('x1', '[-]', 10E-6, x1);
  ParCreate('x2', '[-]', 2 * 10E-6, x2);
  ParCreate('comp_prec', '[-]', 10E-10, comp_prec); // Per default

  // Variablen

  VarCreate('v_s', '[-]', 0, false, v_s);
  VarCreate('v_s', '[-]', 0, false, v_s);
  VarCreate('tau_s', '[s]', 0, false, tau_s);
  VarCreate('K', '[-]', 0, false, K);
  VarCreate('sumWeight', '[-]', 0, false, sumWeight);
  // Optionen
  OptCreate('distanceFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\Dist.txt',
    distanceFile);
  distanceFile.OptionList.add('Q:\Kohl\DiffModell\IniFilesAusgaben\Dist.txt');
  RootXYOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\xyRapp.csv');
  OptCreate('RootDistribution', 'fromsource', RootDistribution);
  RootDistribution.OptionList.add('fromsource');
  RootDistribution.OptionList.add('regular');
  OptCreate('Model', 'tinkerNye', Model);
  Model.OptionList.add('tinkerNye');
  Model.OptionList.add('youngsGardner');
  OptCreate('numb_classes_dist', '20', numb_classes_dist);
  numb_classes_dist.OptionList.add('10');
  numb_classes_dist.OptionList.add('20');
  OptCreate('compareMode', 'no', compareMode);
  compareMode.OptionList.add('no');
  compareMode.OptionList.add('yes');

end;


procedure TSubmodRootDiff1DRapp.init(var GlobMod: TMod);
var
  i : integer;
  ARandomPoint: TRandomPoint;

begin
  inherited;
  // Festlegen Arraygrenzen
  numb_classesDist := trunc(strtoint(numb_classes_dist.Option));
//  numb_classesDist := trunc(strtoint(numb_classes_dist.Option));
  setLength(absFrequencyArr, 2, numb_classesDist);
  setLength(relFrequencyArr, 2, numb_classesDist);
  setLength(quadAbsFrequencyArr, 2, numb_classesDist);
  setLength(quadRelFrequencyArr, 2, numb_classesDist);
  setLength(weightArr, numb_classesDist);
  setLength(quadWeightArr, numb_classesDist);
  setLength(uptakeArr, numb_classesDist);
  setLength(a_j, numb_classesDist);
  ArrayHasFilled := false;
  // De und nicht Db
  De.V := Dl.V * 3.35 * sqr(theta.V);
  // zero-Sink bedeutet k=1
  if NitrateuptakeFunction.Option = 'zerosink' then
    K.V := 1;
  // Speichern der Menge N, die sich initial im Boden befindet
  initAmountNSoil := N_AmountSoil.V;
  // Ausgabedatei für Distanzen neu schreiben
  assignfile(DistFile, distanceFile.Option);
  rewrite(DistFile);
  { Neuanlage oder Ersetzen der Datei, d.h. auch die Datei wird
    bei jedem Modellauf neu geschrieben. }
  closefile(DistFile);
  { Füllen der Liste mit TRandomPoint Objekten, die Punkte werden nur in der mitt-
    leren Fläche verteilt }
  widthMiddle := dimensionX.V - 2 * verticMargin.V;
  heigthMiddle := dimensiony.V - 2 * horizMargin.V;
  AreaMiddle.V := widthMiddle * heigthMiddle;
  resetLists;
  randomize;
  for i := 0 to trunc(numb_RandomPoints.V)-1 do
  begin
    ARandomPoint := TRandomPoint.create;
    ARandomPoint.RandomPointPos.x := Random * widthMiddle + verticMargin.V;
    ARandomPoint.RandomPointPos.y := Random * heigthMiddle + horizMargin.V;
    RandomPointList.add(ARandomPoint);
  end;

 if iniMethod.Option = 'inppar' then
  begin
    { Wenn mWLD und VC als Parameter eingelesen eingelesen werden, dann müssen die
      entsprechenden Variablen gesetzt werden. VarKoeff_RLD wird je nach Verteilungs-
      funktion geg. gändert. }

    // ini-Methode inppar kann nur mit hexagonaler Verteilung verwendet werden:
    RootDistribution.Option := 'regular';
    // Gilt auch für Kennzahlen der Flächenverteilung
  end;


  // Youngs-Gardner: Transformierte Werte (andere Einheiten)
  // Skalierung auf m/m^3 es werden nur mittlere Wurzeln berücksichtigt
  RLD_m := number_consid_roots.V / AreaMiddle.V * 10000;
  RadWurzel_m := RootRadius.V / 100;
  De_m := De.V / (100 * 100);
  v_s.V := Pi * RLD_m * sqr(RadWurzel_m);
  tau_s.V := (K.V + theta.V) / (Pi * RLD_m * De_m);

end;



procedure TSubmodRootDiff1DRapp.Integrate;
var
  i: integer;
  sumUptake: double;
begin
  // inherited;
  { auskommentiert, da analytische Lösung }
  { bei dynamischer Implementierung (Strukturmodell müssen die Arrays neu berechnet
    werden, ansonsten werden sie wieder verwendet }
  if iniMethod.Option = 'submodstruct' then
  begin
    calcArr;
  end
  else
  begin
    if self.ArrayHasFilled = false then
    begin
      // einmalige Berechnung der Arrays
      calcArr;
      ArrayHasFilled := true;
    end;
  end;
  if compareMode.Option = 'yes'
  then { Im Vergleichmodus wird nur die N-Menge im Boden im
    GG-Zustant (Influx=Mineralisierung) berechnet }
  begin
    calcN_AmountSoilEquil;
  end
  else
  begin
    { Stickstoffaufnahme in den einzelnen Klassen berechnen }
    calcUptakeClasses;
    // Berechnung der Aufnahme im Gesamtsystem
    sumUptake := 0;
    for i := 0 to high(uptakeArr) do
    begin
      sumUptake := sumUptake + uptakeArr[i];
    end;
    // Berechnung der Zustandsvariablen
    If Model.Option = 'tinkernye' then
    begin
      N_MengeAnteil.V := sumUptake;
      Sum_N_AmountRoots.V := N_MengeAnteil.V * initAmountNSoil;
    end;
    if Model.Option = 'youngsgardner' then
    begin
      Sum_N_AmountRoots.V := initAmountNSoil / (1 - v_s.V);
      N_MengeAnteil.V := Sum_N_AmountRoots.V / initAmountNSoil;
    end;
  end;
  // N_AmountSoil.v:=
  if OutputXY.Option = 'yes' then
    writeOutputTofile;
end;

procedure TSubmodRootDiff1DRapp.calcUptakeClasses;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Methode berechnet die Nährstoffaufnahme in den einzelnen Klassen
  Hinweis: Wurzellängendichte wird dabei aus dem Radius des Bodenzylinders berech-
  net nach der Formel WLD=1/(Pi*r^2).
  Dabei wird schon gewichtet.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  RLD: double;
begin
  if self.Model.Option = 'tinkernye' then
  begin
    for i := 0 to numb_classesDist - 1 do
    begin
      RLD := 1 / (Pi * sqr(relFrequencyArr[0][i]));
      uptakeArr[i] := 1 - exp(2 * Pi * RLD * Globmod.time.V * De.V * 86400 /
        (ln(1.65 * RootRadius.V / relFrequencyArr[0][i])));
      // Wichtung
      uptakeArr[i] := uptakeArr[i] * weightArr[i];
    end;
  end;
  if Model.Option = 'youngsgardner' then
  begin
    calcUptakeClassesYoungs;
  end;
end;

procedure TSubmodRootDiff1DRapp.calcUptakeClassesYoungs;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: statt dem 1D-Modell von Tinker-Nye wird jetzt das Modell von
  Youngs-Gardner-Rappolt verwendet, entnommen aus Rappolt: Diffusion in aggregated
  soil, Kap. 7
  ------------------------------------------------------------------------------ *)
var
  succes: boolean;
  i, j: integer;
  increase, alpha_i, A1,
  { 1. Argument der zeitabhängigen g-Funktion aus Rappolt, Gl. 7.45 }
  A2, { 2. Argument der zeitabhängigen g-Funktion aus Rappolt, Gl. 7.45 }
  g_func, integral_g, { Integral über A2 von g(A1,A2) }
  integral_g0ld, { Alter Wert des Integrals }
  roh_j: double;
begin
  // new(alpha_i);    //Brauch ich wohl nicht
  for i := 0 to numb_classesDist - 1 do
  begin
    { Vorgehensweise: solange Aufnahmen für Nullstellen (alpha1-Werte) berechnen, bis
      sich der Zuwachs in der Aufnahme um weniger als den Threshold unterscheidet. }
    A1 := v_s.V / a_j[i];
    A2 := Globmod.time.V / (a_j[i] * tau_s.V);
    roh_j := sqrt(1 / A1);
    integral_g := 0;
    integral_g0ld := 0;
    // Bestimmen der Nullstellen (alpha-i-Werte) mit Bisection
    { temp-Variablen speichern die aktuelle 'Range' zwischen, jede Klasse hat eigene
      Nullstellen und es wird für jede Klasse erneut nahe bei alpha = 0 begonnen }
    x1_temp := x1.V;
    x2_temp := x2.V;
    while increase > threshold.V do // solange Zuwachs noch nenneswert ist.
    begin
      calcRoot(roh_j); // bestimme neue Nullstelle
      alpha_i := nullstelle;
      g_func :=
      // Gleichung 7.A3
        1 / (sqr(alpha_i) * sqr(roh_j)) * 4 * sqr(bessj1(roh_j * alpha_i)) /
        (sqr(bessj0(alpha_i)) - sqr(bessj1(roh_j * alpha_i))) *
        (1 - exp(-sqr(alpha_i) * sqr(roh_j) * A2));
      integral_g := integral_g + g_func;
      increase := abs(integral_g - integral_g0ld);
      integral_g0ld := integral_g;
    end;
    // Wichtung
    uptakeArr[i] := integral_g * quadWeightArr[i];
  end;
end;

(* ------------------------------------------------------------------------------
  Hilfsmethoden
  ------------------------------------------------------------------------------ *)
procedure TSubmodRootDiff1DRapp.CalcShortestDist;
var
  i, j, indexNearestWAP: integer;
  ARandomPoint: TRandomPoint;
  distOld, distNew, widthMiddle, heigthMiddle: double;
  WAPKoord, RandomPointKoord: r2;
begin
  widthMiddle := dimensionX.V - 2 * verticMargin.V;
  heigthMiddle := dimensiony.V - 2 * horizMargin.V;
  for i := 0 to RandomPointList.Count - 1 do
  begin
    { kürzeste Distanz entspricht zunächst der längsten Distanz, die in der Beobach-
      tungsfläche vorkommen kann: von Ecke zu Ecke }
    indexNearestWAP := 0;
    distOld := sqrt(sqr(widthMiddle) + sqr(heigthMiddle));
    ARandomPoint := RandomPointList.items[i];
    RandomPointKoord[0] := ARandomPoint.RandomPointPos.x;
    RandomPointKoord[1] := ARandomPoint.RandomPointPos.y;
    for j := 0 to RasterData.PosList.Count-1 do
    begin
      { Es werden alle Wurzeln berücksichtigt }
      WAPKoord[0] := TRootPosition(RasterData.PosList.Objects[j]).x;
      WAPKoord[1] := TRootPosition(RasterData.PosList.Objects[j]).y;
      distNew := calcDistance(WAPKoord, RandomPointKoord);
      if distNew < distOld then
      begin
        distOld := distNew;
        indexNearestWAP := j;
      end;
    end;
    ARandomPoint.shortestDist := distOld;
    { Erweiterung des Ansatzes: Es werden nur Strecken bis zu den Grenzen berücksich-
      tigt. Rand selbst gehört zur Beobachtungsfläche }
    // Wenn der Punkt in den Rändern liegt
    if (TRootPosition(RasterData.PosList.Objects[indexNearestWAP]).x < verticMargin.V) or
      (TRootPosition(RasterData.PosList.Objects[indexNearestWAP]).x > dimensionX.V - verticMargin.V) or
      (TRootPosition(RasterData.PosList.Objects[indexNearestWAP]).y < horizMargin.V) or
      (TRootPosition(RasterData.PosList.Objects[indexNearestWAP]).y < dimensiony.V - horizMargin.V) then
    begin
      ARandomPoint.shortestDist := CalcBorderDist(ARandomPoint,
        indexNearestWAP);
    end;
    { für das Rappolt-Youngs-Gardner-Modell wird eine quadratische Skalierung verwen-
      det, deshalb Berechnung folgender Werte: }
    ARandomPoint.shortDist_m := ARandomPoint.shortestDist / 100;
    ARandomPoint.quadShortDist_m := sqr(ARandomPoint.shortDist_m);
    ARandomPoint.y := Pi * RLD_mean.V * ARandomPoint.quadShortDist_m;
  end;
end;

function TSubmodRootDiff1DRapp.calcDistance(KoordWAP, KoordRandPoint
  : r2): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Function berechnet den Betrag des Vektors zwischen dem WAP und dem
  zufällig erzeugten Punkt in R2 und gibt ihn zurürck
  ------------------------------------------------------------------------------ *)
var
  distance: double;
  vectorResult: r2;
begin
  vectorResult := vectorSubtraktR2(KoordWAP, KoordRandPoint);
  distance := sqrt(sqr(vectorResult[0]) + sqr(vectorResult[1]));
  Result := distance;
end;

function TSubmodRootDiff1DRapp.vectorSubtraktR2(vector_a, vector_b: r2): r2;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Subtrahiert vector_b von vector_a in R2und gibt den resultierenden
  Vektor zurück.
  ------------------------------------------------------------------------------ *)
var
  vector_result: r2;
begin
  vector_result[0] := vector_a[0] - vector_b[0];
  vector_result[1] := vector_a[1] - vector_b[1];
  Result := vector_result;
end;

procedure TSubmodRootDiff1DRapp.calcFrequencies;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet absolute und relative Häufigkeiten aus der Wahrschein-
  lichkeitsdichtefunktion der Distanzen.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  maxShortDistOld, maxShortDistnew: double;
  ARandomPoint: TRandomPoint;
begin
  // Berechnung der größten auftretenden kürzesten Distanz
  maxShortDistOld := 0;
  for i := 0 to RandomPointList.Count - 1 do
  begin
    ARandomPoint := RandomPointList.items[i];
    maxShortDistnew := ARandomPoint.shortestDist;
    if maxShortDistnew > maxShortDistOld then
      maxShortDistOld := maxShortDistnew;
  end;
  // Berechnen der Klassengrenzen
  for i := 0 to numb_classesDist - 1 do
  begin
    absFrequencyArr[0][i] := absFrequencyArr[0][i - 1] + maxShortDistOld /
      numb_classesDist;
  end;
  for i := 0 to numb_classesDist - 1 do
  begin
    relFrequencyArr[0][i] := relFrequencyArr[0][i - 1] + maxShortDistOld /
      numb_classesDist;
  end;
  // Berechnen absoluter Häufigkeiten
  for i := 0 to RandomPointList.Count - 1 do
  begin
    ARandomPoint := RandomPointList.items[i];
    // Test auf Zugehörigkeit zur ersten Klasse
    if (ARandomPoint.shortestDist <= absFrequencyArr[0][0]) and
      (ARandomPoint.shortestDist >= 0) then
    begin
      absFrequencyArr[1][0] := absFrequencyArr[1][0] + 1;
    end;
    // Test auf Zugehörigkeit zu den folgenden Klassen
    for j := 1 to numb_classesDist - 1 do
    begin
      // Klassengrenze gehört zur vorherigen Klasse
      if (ARandomPoint.shortestDist <= absFrequencyArr[0][j]) and
        (ARandomPoint.shortestDist > absFrequencyArr[0][j - 1]) then
      begin
        absFrequencyArr[1][j] := absFrequencyArr[1][j] + 1;
      end;
    end;
  end;
  // Berechnen relativer Häufigkeiten
  for i := 0 to numb_classesDist - 1 do
  begin
    relFrequencyArr[1][i] := absFrequencyArr[1][i] / RandomPointList.Count;
  end;
end;

procedure TSubmodRootDiff1DRapp.calcweightFactors;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung von Wichtungsfaktoren gemäß Gl. 7.26, Rappolt: Diffusion
  in aggregated soil.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  // j ist notwendig, da Klassenindizes in der Formel mit 1 beginnen
begin
  j := 1;
  sumWeight.V := 0;
  for i := 0 to numb_classesDist - 2 do
  // von der ersten bis zur vorletzten Klasse
  begin
    weightArr[i] := j * j * (relFrequencyArr[1][i] / ((2 * j) - 1) -
      (relFrequencyArr[1][i + 1] / ((2 * j) + 1)));
    inc(j);
  end;
  // Wichtungsfaktor für die letzte Klasse:
  weightArr[numb_classesDist - 1] := sqr(numb_classesDist) /
    ((2 * numb_classesDist) - 1) * relFrequencyArr[1][numb_classesDist - 1];
  // Kontrolle
  for i := 0 to numb_classesDist - 1 do
  begin
    sumWeight.V := sumWeight.V + weightArr[i];
  end;
end;

procedure TSubmodRootDiff1DRapp.calcFrequenciesQuad;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet absolute und relative Häufigkeiten aus der Wahrschein-
  lichkeitsdichtefunktion der QUADRATISCH TRANSFORMIERTEN Distanzen.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  maxShortDistOld, maxShortDistnew: double;
  ARandomPoint: TRandomPoint;
begin
  // Festlegen absoluter Minimalwerte und Spannweite
  maxShortDistOld := 0;
  for i := 0 to RandomPointList.Count - 1 do
  begin
    ARandomPoint := RandomPointList.items[i];
    maxShortDistnew := ARandomPoint.quadShortDist_m;
    if maxShortDistnew > maxShortDistOld then
      maxShortDistOld := maxShortDistnew;
  end;

  // Berechnen der Klassengrenzen
  j := 1;
  for i := 0 to numb_classesDist - 1 do
  begin
    // Vgl. Gleichung 7.31 (Rappolt)
    quadAbsFrequencyArr[0][i] := j * maxShortDistOld / (numb_classesDist) * Pi *
      self.RLD_mean.V;
    // Klassengrenzen entsprechen der aj-Werten und hier gleich mit gespeichert
    self.a_j[i] := j * maxShortDistOld / (numb_classesDist) * Pi *
      self.RLD_mean.V;
    inc(j);
  end;
  j := 1;
  for i := 0 to numb_classesDist - 1 do
  begin
    quadRelFrequencyArr[0][i] := j * maxShortDistOld / (numb_classesDist) * Pi *
      self.RLD_mean.V;
  end;
  // Berechnen absoluter Häufigkeiten
  for i := 0 to RandomPointList.Count - 1 do
  begin
    ARandomPoint := RandomPointList.items[i];
    // Test auf Zugehörigkeit zur ersten Klasse
    if (ARandomPoint.y <= quadAbsFrequencyArr[0][0]) and (ARandomPoint.y >= 0)
    then
    begin
      quadAbsFrequencyArr[1][0] := quadAbsFrequencyArr[1][0] + 1;
    end;
    // Test auf Zugehörigkeit zu den folgenden Klassen
    for j := 1 to numb_classesDist - 1 do
    begin
      // Klassengrenze gehört zur untersten Klasse
      if (ARandomPoint.y <= quadAbsFrequencyArr[0][j]) and
        (ARandomPoint.y > quadAbsFrequencyArr[0][j - 1]) then
      begin
        quadAbsFrequencyArr[1][j] := quadAbsFrequencyArr[1][j] + 1;
      end;
    end;
  end;
  // Berechnen relativer Häufigkeiten
  for i := 0 to numb_classesDist - 1 do
  begin
    quadRelFrequencyArr[1][i] := quadAbsFrequencyArr[1][i] /
      RandomPointList.Count;
  end;
  // Füllen
end;

procedure TSubmodRootDiff1DRapp.calcweightFactorsQuad;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung von Wichtungsfaktoren gemäß Gl. 7.30, Rappolt: Diffusion
  in aggregated soil.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  // j ist notwendig, da Klassenindizes in der Formel mit 1 beginnen
begin
  j := 1;
  for i := 0 to numb_classesDist - 2 do
  // von der ersten bis zur vorletzten Klasse
  begin
    quadWeightArr[i] := j * (quadRelFrequencyArr[1][i] - quadRelFrequencyArr
      [1][i + 1]);
    inc(j);
  end;
  // Wichtungsfaktor für die letzte Klasse:
  quadWeightArr[numb_classesDist - 1] := numb_classesDist * quadRelFrequencyArr
    [1][numb_classesDist - 1];
end;

procedure TSubmodRootDiff1DRapp.writeDistances;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Ausgabe von zufällig erzeugten Koordinaten und Distanzen in jedem
  Zeitschritt
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  ARandomPoint: TRandomPoint;
begin
  assignfile(DistFile, distanceFile.Option);
  // Schreiben Header
  append(DistFile);
  write(DistFile, 'Modellzeit: ', Globmod.time.V:6:2, ' ');
  writeln(DistFile);
  // Header schreiben
  write(DistFile, 'X', ' ', 'Y', ' ', 'ShortestDist');
  writeln(DistFile);
  for i := 0 to RandomPointList.Count - 1 do
  begin
    ARandomPoint := RandomPointList.items[i];
    write(DistFile, ARandomPoint.RandomPointPos.x, ' ');
    write(DistFile, ARandomPoint.RandomPointPos.y, ' ');
    write(DistFile, ARandomPoint.shortestDist);
    writeln(DistFile);
    // Debuggen
  end;
  // Header schreiben
  write(DistFile, 'Kl-Grenzen_abs', ' ', 'Kl-Grenzen_rel', ' ',
    'rel_Häufigkeiten', ' ', 'Wichtungsfaktoren');
  writeln(DistFile);
  for i := 0 to high(weightArr) do
  begin
    write(DistFile, absFrequencyArr[0][i], ' ', relFrequencyArr[0][i], ' ',
      relFrequencyArr[1][i], ' ', weightArr[i]);
    writeln(DistFile);

  end;
  closefile(DistFile);
end;

procedure TSubmodRootDiff1DRapp.resetLists;
begin
  RandomPointList.Clear;
end;

procedure TSubmodRootDiff1DRapp.resetArrays;
var
  i, j: integer;
begin
  // Reset der 2-dimens. Arrays
  for i := 0 to 1 do // für alle Spalten
  begin
    for j := 0 to numb_classesDist - 1 do // für alle Zeilen
    begin
      absFrequencyArr[i][j] := 0;
      relFrequencyArr[i][j] := 0;
      quadAbsFrequencyArr[i][j] := 0;
      quadRelFrequencyArr[i][j] := 0;
    end;
  end;
  // Reset der 1-dimens. Arrays
  for i := 0 to numb_classesDist - 1 do
  begin
    weightArr[i] := 0;
    quadWeightArr[i] := 0;
    uptakeArr[i] := 0;
    a_j[i] := 0;
  end;
end;

(* ------------------------------------------------------------------------------
  Bessel
  ------------------------------------------------------------------------------ *)
function TSubmodRootDiff1DRapp.fx(alpha, roh: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Vgl. Rappolt S. 127 , Gleichung, deren Nullstellen gefunden werden
  müssen
  ------------------------------------------------------------------------------ *)
begin
  Result := bessj0(alpha) * bessy1(roh * alpha) - bessy0(alpha) *
    bessj1(roh * alpha);
end;

function TSubmodRootDiff1DRapp.rtbis(x1, x2, xacc, roh: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Nullstellen finden mit Bisektion
  Using bisection, find the root of a function fx known to lie between xl and x2.
  The root, returned as rtbis, will be refined until its accuracy is ±xacc.
  ------------------------------------------------------------------------------ *)
LABEL 99;
CONST
  jmax = 40; // Maximum allowed number of bisections.
VAR
  dx, f, fmid, xmid, rtb: real;
  j: integer;
BEGIN
  fmid := fx(x2, roh);
  f := fx(x1, roh);
  IF f * fmid >= 0.0 THEN
  BEGIN
    writeln('pause in RTBIS');
    writeln('Root must be bracketed for bisection.');
    readln
  END;
  IF f < 0.0 THEN // Orient the search so that f>o lies at x+dx
  BEGIN
    rtb := x1;
    dx := x2 - x1
  END
  ELSE
  BEGIN
    rtb := x2;
    dx := x1 - x2
  end;
  FOR j := 1 TO jmax DO
  BEGIN
    dx := dx * 0.5;
    xmid := rtb + dx;
    fmid := fx(xmid, roh);
    IF fmid <= 0.0 THEN
      rtb := xmid;
    IF (abs(dx) < xacc) OR (fmid = 0.0) THEN
      GOTO 99
  END;
  writeln('pause in RTBIS - too many bisections');
  readln;
99:
  rtbis := rtb
end;

function TSubmodRootDiff1DRapp.bessj0(x: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Returns the Bessel function Jo(x) for any real x.
  ------------------------------------------------------------------------------ *)
Var
  ax, xx, z: real;
  y, ans, ans1, ans2: double;
  // We'll accumulate polynomials in double precision.
BEGIN
  IF abs(x) < 8.0 THEN
  BEGIN // Direct rational function fit.
    y := sqr(x);
    ans1 := 57568490574.0 + y *
      (-13362590354.0 + y * (651619640.7 + y * (-11214424.18 + y *
      (77392.33017 + y * (-184.9052456)))));
    ans2 := 57568490411.0 + y *
      (1029532985.0 + y * (9494680.718 + y * (59272.64853 + y * (267.8532712 + y
      * 1.0))));
    bessj0 := ans1 /
      ans2 { Cast double to real.A few compilers require a function
      sngl() }
  END
  ELSE
  BEGIN // Fitting function (6.4.9).
    ax := abs(x);
    z := 8.0 / ax;
    y := sqr(z);
    xx := ax - 0.785398164;
    ans1 := 1.0 + y * (-0.1098628627E-2 + y *
      (0.2734510407E-4 + y * (-0.2073370639E-5 + y * 0.2093887211E-6)));
    ans2 := -0.1562499995E-1 + y *
      (0.1430488765E-3 + y * (-0.6911147651E-5 + y * (0.7621095161E-6 - y *
      0.934945152E-7)));
    ans := sqrt(0.636619772 / ax) * (cos(xx) * ans1 - z * sin(xx) * ans2);
    bessj0 := ans { Cast double to real.A few compilers require a function
      sngl() }
  end
end;

function TSubmodRootDiff1DRapp.bessy0(x: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Returns the Bessel function Yo(x)for positive x.
  ------------------------------------------------------------------------------ *)
VAR
  xx, z: real;
  y, ans, ans1, ans2: double;
  // We'll accumulate polynomials in double precision.
BEGIN
  IF x < 8.0 THEN // Rational function approximation of (6.4.8).
  BEGIN
    y := sqr(x);
    ans1 := -2957821389.0 + y *
      (7062834065.0 + y * (-512359803.6 + y * (10879881.29 + y * (-86327.92757 +
      y * 228.4622733))));
    ans2 := 40076544269.0 + y *
      (745249964.8 + y * (7189466.438 + y * (47447.26470 + y * (226.1030244 + y
      * 1.0))));
    ans := (ans1 / ans2) + 0.636619772 * bessj0(x) * ln(x)
  END
  ELSE
  BEGIN // Fitting function (6.4.10).
    z := 8.0 / x;
    y := sqr(z);
    xx := x - 0.785398164;
    ans1 := 1.0 + y * (-0.1098628627E-2 + y *
      (0.2734510407E-4 + y * (-0.2073370639E-5 + y * 0.2093887211E-6)));
    ans2 := -0.1562499995E-1 + y *
      (0.1430488765E-3 + y * (-0.6911147651E-5 + y * (0.7621095161E-6 + y *
      (-0.934945152E-7))));
    ans := sin(xx) * ans1 + z * cos(xx) * ans2;
    ans := sqrt(0.636619772 / x) * ans
  END;
  bessy0 := ans { Cast double to real.A few compilers require a function
    sngl() }
end;

function TSubmodRootDiff1DRapp.bessj1(x: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Returns the Bessel function J1(x)for any real x.
  ------------------------------------------------------------------------------ *)
VAR
  ax, xx, z: real;
  y, ans, ans1, ans2 // we'll accumulate polynomials in double precision.
    : double;
BEGIN
  IF abs(x) < 8.0 THEN
  BEGIN // Direct rational approximation,
    y := sqr(x);
    ans1 := x * (72362614232.0 + y * (-7895059235.0 + y * (242396853.1 + y *
      (-2972611.439 + y * (15704.48260 + y * (-30.16036606))))));
    ans2 := 144725228442.0 + y *
      (2300535178.0 + y * (18583304.74 + y * (99447.43394 + y * (376.9991397 + y
      * 1.0))));
    bessj1 := ans1 / ans2 { Cast double to real.A few compilers require
      a function sngl() }
  END
  ELSE
  BEGIN // Fitting function (6.4.9).
    ax := abs(x);
    z := 8.0 / ax;
    y := sqr(z);
    xx := ax - 2.356194491;
    ans1 := 1.0 + y * (0.183105E-2 + y * (-0.3516396496E-4 + y *
      (0.2457520174E-5 + y * (-0.240337019E-6))));
    ans2 := 0.04687499995 + y *
      (-0.2002690873E-3 + y * (0.8449199096E-5 + y * (-0.88228987E-6 + y *
      0.105787412E-6)));
    ans := sqrt(0.636619772 / ax) * (cos(xx) * ans1 - z * sin(xx) * ans2);
    IF x < 0.0 THEN
      ans := -ans;
    bessj1 := ans { Cast double to real.A few compilers require a function
      sngl() }
  end
end;

function TSubmodRootDiff1DRapp.bessy1(x: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Returns the Bessel function Y1(X)for positive x
  ------------------------------------------------------------------------------ *)
VAR
  xx, z: real;
  y, ans, ans1, ans2 // we'll accumulate polynomials in double precision.
    : double;
BEGIN
  IF x < 8.0 THEN // Rational function approximation of (6.4.8).
  BEGIN
    y := sqr(x);
    ans1 := x * (-0.4900604943E13 + y * (0.1275274390E13 + y *
      (-0.5153438139E11 + y * (0.7349264551E9 + y * (-0.4237922726E7 + y *
      0.8511937935E4)))));
    ans2 := 0.2499580570E14 + y *
      (0.4244419664E12 + y * (0.3733650367E10 + y * (0.2245904002E8 + y *
      (0.1020426050E6 + y * (0.3549632885E3 + y * 1.0)))));
    ans := (ans1 / ans2) + 0.636619772 * (bessj1(x) * ln(x) - 1.0 / x)
  END
  ELSE
  BEGIN // Fitting function (6.4.10).
    z := 8.0 / x;
    y := sqr(z);
    xx := x - 2.356194491;
    ans1 := 1.0 + y * (0.183105E-2 + y * (-0.3516396496E-4 + y *
      (0.2457520174E-5 + y * (-0.240337019E-6))));
    ans2 := 0.04687499995 + y *
      (-0.2002690873E-3 + y * (0.8449199096E-5 + y * (-0.88228987E-6 + y *
      0.105787412E-6)));
    ans := sqrt(0.636619772 / x) * (sin(xx) * ans1 + z * cos(xx) * ans2)
  END;
  bessy1 := ans { Cast double to real.A few compilers require a function sngl() }
end;

function TSubmodRootDiff1DRapp.bessy(n: integer; x: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung: Returns the Bessel function Vn(x) for positive x and n >2.
  ------------------------------------------------------------------------------ *)
VAR
  by, bym, byp, tox: real;
  j: integer;
BEGIN
  IF n < 2 THEN
  BEGIN
    writeln('pause in BESSY -index n leas than 2');
    readln
  END;
  tox := 2.0 / x;
  by := bessy1(x); // Starting values for the recurrence.
  bym := bessy0(x);
  FOR j := 1 TO n - 1 DO // Recurrence (6.4.7).
  BEGIN
    byp := j * tox * by - bym;
    bym := by;
    by := byp
  END;
  bessy := by
end;

function TSubmodRootDiff1DRapp.bessj(n: integer; x: real): real;
(* ------------------------------------------------------------------------------
  Beschreibung:   Returns the Bessel function Jn(X)for any real x and n >2.
  ------------------------------------------------------------------------------ *)
CONST
  iacc = 40; // Make iacc larger to increase accuracy.
  bigno = 1.0E10;
  bigni = 1.0E-10;
VAR
  bj, bjm, bjp, sum, tox, ans: real;
  j, jsum, m: integer;
BEGIN
  IF n < 2 THEN
  BEGIN
    writeln('pause in BESSJ');
    readln
  END;
  IF x = 0.0 THEN
    ans := 0.0
  ELSE IF abs(x) > 1.0 * n THEN // Use upwards recurrence from Jo and J1.
  BEGIN
    tox := 2.0 / abs(x);
    bjm := bessj0(abs(x));
    bj := bessj1(abs(x));
    FOR j := 1 TO n - 1 DO
    BEGIN
      bjp := j * tox * bj - bjm;
      bjm := bj;
      bj := bjp
    END;
    ans := bj
  END
  ELSE
  BEGIN { Use downwards recurrence from an even value
      m here computed. }
    tox := 2.0 / abs(x);
    m := 2 * ((n + trunc(sqrt(1.0 * (iacc * n)))) DIV 2);
    ans := 0.0;
    jsum := 0; { jsum will alternate between 0 and 1;when it is
      1,we accumulate in sum the even terms
      in (5.4.6). }
    sum := 0.0;
    bjp := 0.0;
    bj := 1.0;
    FOR j := m DOWNTO 1 DO // The downward recurrence.
    BEGIN
      bjm := j * tox * bj - bjp;
      bjp := bj;
      bj := bjm;
      IF abs(bj) > bigno THEN // Renormalize to prevent overflows.
      BEGIN
        bj := bj * bigni;
        bjp := bjp * bigni;
        ans := ans * bigni;
        sum := sum * bigni
      END;
      IF jsum <> 0 THEN
        sum := sum + bj; // Accumulate the sum.
      jsum := 1 - jsum; // Change 0 to 1 or vice-versa.
      IF j = n THEN // Save the unnormalized answer.
        ans := bjp
    END;
    sum := 2.0 * sum - bj; { Compute (5.4.6) and use it to normalize
      the answer. }
    ans := ans / sum
  END;
  IF (x < 0.0) AND odd(n) THEN
    ans := -ans;
  bessj := ans
end;

(* ------------------------------------------------------------------------------
  Bessel Ende
  ------------------------------------------------------------------------------ *)
procedure TSubmodRootDiff1DRapp.calcRoot(roh: double);
(* ------------------------------------------------------------------------------
  Beschreibung: Berechnet die Nullstellen in der Gleichung von Rappolt S. 127
  ------------------------------------------------------------------------------ *)
var
  succes: boolean;
  xacc_: double;
begin
  // Toleranz vgl. Press, S.278
  xacc_ := comp_prec.V * (x1.V + x2.V) / 2;
  succes := false;
  zbrac(x1_temp, x2_temp, succes, roh);
  if succes = true then
  begin
    nullstelle := rtbis(x1_temp, x2_temp, xacc_, roh);
    x1_temp := x2_temp;
    x2_temp := x2_temp + (x1.V + x2.V);
  end
  else
    showMessage('Funktion ohne Nullstelle');
end;

procedure TSubmodRootDiff1DRapp.zbrac(var x1, x2: real; var succes: boolean;
  roh: double);
(* ------------------------------------------------------------------------------
  Beschreibung: Given a function fx and an initial guessed range xl to x2, the
  routine expands the range geometrically until a root is bracketed by the
  returned values xl and x2 (in which case succes returns as true) or until the
  range becomes unacceptably large (in which case succes returns as false).
  Success is guaranteed for a function which has opposite signs for sufficiently
  large and small arguments.
  ------------------------------------------------------------------------------ *)
LABEL 99;
CONST
  factor = 1.6;
  ntry = 50;
VAR
  j: integer;
  f2, f1: real;
BEGIN
  IF x1 = x2 THEN
  BEGIN
    writeln('pause in routine ZBRAC');
    writeln('you have to guess an initial range');
    readln
  END;
  f1 := fx(x1, roh);
  f2 := fx(x2, roh);
  succes := true;
  for j := 1 to ntry do // Schleife wird höchstens 50 mal durchlaufen
  BEGIN
    IF f1 * f2 < 0.0 THEN
      GOTO 99;
    IF abs(f1) < abs(f2) THEN
    BEGIN
      x1 := x1 + factor * (x1 - x2);
      f1 := fx(x1, roh);
    end
    ELSE
    BEGIN
      x2 := x2 + factor * (x2 - x1);
      f2 := fx(x2, roh);
    END
  END;
  succes := false;
99:
end;

procedure TSubmodRootDiff1DRapp.calcN_AmountSoilEquil;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der N-Menge im Boden gemäß Gleichung 3.6.43 Diss. Kage
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  Db, cl_avClass, classborder: double;
begin
  cl_av.V := 0;
  Db := De.V * theta.V;
  for i := 0 to numb_classesDist - 1 do
  begin
    cl_avClass := clmin.V - Min_s.V *
      (sqr(absFrequencyArr[0][i]) - sqr(RootRadius.V)) / (4 * Db) + Min_s.V *
      sqr(absFrequencyArr[0][i]) / (2 * Db) *
      ln(absFrequencyArr[0][i] / RootRadius.V);
    // Wichtung
    cl_avClass := cl_avClass * weightArr[i];
    cl_av.V := cl_av.V + cl_avClass;
  end;
  N_AmountSoil.V := Mg_func( Depth.v, theta.V, cl_av.V);
end;

procedure TSubmodRootDiff1DRapp.calcArr;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Arrays
  ------------------------------------------------------------------------------ *)
begin
  resetArrays;
  { in jedem Zeitschritt wird in der Liste mit den Zufallspunkten die kürzesten
    Distanzen neu bestimmt. }
  CalcShortestDist;
  // Ausgaben
  { in jedem Zeitschritt werden die Koordinaten der zufälligen Punkte und die zuge
    ordneten kürzesten Distanzen geschrieben. }

  if Model.Option = 'tinkernye' then
  begin
    { Relative und absolute Häufigkeiten berechnen }
    calcFrequencies;
    { Wichtungsfaktoren berechnen }
    calcweightFactors;
  end;
  if Model.Option = 'youngsgardner' then
  begin
    // Berechnungen in quadrat. Skala
    calcFrequenciesQuad;
    calcweightFactorsQuad;
  end;
  writeDistances;
end;

function TSubmodRootDiff1DRapp.CalcBorderDist(ARandomPoint: TRandomPoint;
  indexNearestPoint: integer): double;
(* ------------------------------------------------------------------------------
  Berechnung und Rückgabe der Distanz des Zufallspunktes zur Grenze, wenn der
  WAP mit der kürzesten Entfernung in den Rändern liegt.
  ------------------------------------------------------------------------------ *)
begin
  { Methode A: Bestimmung der kürzesten Distanz zur Grenze, egal wo der WAP liegt }
  { Methode B: Bestimmung des Teilabschnittes der Entfernung von Zufallspunkt zum
    WAP, der innerhalb }
end;

{ TRandomPoint }

constructor TRandomPoint.create;
begin
  inherited;
  RandomPointPos := TRootPosition.create;
end;

end.
