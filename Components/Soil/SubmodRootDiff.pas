unit SubmodRootDiff;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid,
  UMod, UState, Diffko, SubmodRootStructureNew;

const
  (* -----------------------------------------------------------------------------
    Problem: sollten diese nicht eher als TOption deklariert werden?
    ------------------------------------------------------------------------------ *)
  max_num_roots = 40000; { maximale Zahl der Wurzeln }

type
  (* -----------------------------------------------------------------------------
    Typdeklaration
    ------------------------------------------------------------------------------ *)
  { Records und Mengen }
  { Art und Weise der N-Aufnahme durch die Wurzel (Michaelis-Menten (Sättigungskine-
    tik, fixed_influx meint evtl. Annahme einer festen Senkenstärke, ZeroSink un-
    begrenzte Senkenstärke (schwarzes Loch) }
  tUptake_Function = (MM, fixed_influx, ZeroSink);
  TMyFloatPoint = double;

  { -------------------------------------------------------------------------------
    Ein Array, das TPointDoubleTypes speichert, dient zum Einlesen von xy-Koordinaten
    aus einer Datei. Der Record erweitert den Typ posi aus dem ursprünglichen Modell
    um die Felder root xi, yi, NInflux ,WInflux und area
    ------------------------------------------------------------------------------ }
  TPointDoubleType = record
    x, y: double; // Position im kartesischen Koordinatensystem [cm]
    xi, yi: word; // Indizes auf Rechengrid
    root: integer; // Eindeutige Nummer für Wurzel
    NInflux: real; // Nitrate Influx [mol/cm*s]
    NAmountdt: real; // im internen Zeitschritt aufgenommene NMenge [g]
    SumNMenge: real;
    // Was hat die Wurzel kumuliert im externen Zeitschritt aufgenommen [kgN/dt_ext]
    WInflux: real; // Water influx [cm3/cm/s]
    area: real; // Fläche Voronoi-Polygon [cm2]
  end;

  { Klassen }
  TSRPLight = class(TObject)
    { abgespeckte speicherschonendere Version eines SRP }
  private
    { Private-Deklarationen }
  protected
  public
    { Public-Deklarationen }
    x, y, wld: double; // Wurzellängendichte des SRP [cm/cm^3]
  end;

  TSRP = class(TObject)
    { auf Vorrat programmiert für eine objektorientierte Implementierung des Einzel-
      wurzelzylinders (für numerische Lösung) }
  private
    { Private-Deklarationen }
    { TSRP-Instanzen des Einzelwurzelmodells brauchen auch Felder für area und
      vertex-List, damit - bei Einlesen von Rasterdaten- der Flächeninhalt bestimmt
      werden kann (mit Voronoi- Polygonen oder alternativ über Aufteilung der Fläche
      der Rasterzellen auf die darin enthaltenen Wurzeln.
      Problem: Einheiten }
    coordRoot: TMyFloatPoint; // Feld für die Koordinaten der Wurzel [cm]
    area: double; // Oberfläche des Einzelwurzelzylinders [cm^2]
    vertexList: TList; //
    Cl_mean: double; // Mittlere Nitratkonzentration
    theta_EWZ: double; // volumetrischer Wassergehalt im EWZ
    init_NAmount: double; // NMenge im EWZ zu Beginn
  public
    { Public-Deklarationen }
    { Zugriff auf die Felder: Set und Get-Methoden }
  end;

  { Deklaration Klasse TRasterData.
    Klasse kapselt das Raster und die Positionen sowie die Anzahl der eingelesenen
    und randomisierten Daten (WAP). Ermöglicht Anzeige in den 'Tabellenblättern'
    RasterData und RootDistribution. Klasse realisiert außerdem die Dateizugriffe }

  TRasterData = class(TObject)
    DescStr: string; { Beschreibung des Datensatzes }
    Date: TDatetime; { Datum [TDateTime-Format] }
    NCols: integer; { Anzahl Zeilen }
    NRows: integer; { Anzahl Spalten }
    NRoots: integer; { Anzahl Wurzeln }
    DimCols: double; { Höhe Zeilen [cm] }
    DimRows: double; { Breite Spalten [cm] }

    { Arrays Kl. RasterData }

    { Wurzelanzahlen in 10000 Raster(Rechen-)zellen. Array wird benötigt für das
      Einlesen und die Anzeige der Anzahl von Wurzeln in Gridzellen der Dimension
      5cm x 5cm }
    CountArr: array of array of integer;
    { Speichert Informationen zu sämtlichen Wurzeln im Form von TPointDoubleType-Ein-
      trägen. }
    PosArr: array [1 .. max_num_roots] of TPointDoubleType;
  private
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    SubmodRootDiff: TSubmodel; { RasterData kennt das Diffusions-Submodell. }
    // Konstruktor
    constructor create(Submodel: TSubmodel);
    // Methoden für Dateizugriffe
    procedure readRasterData(fn: string; var Series: TPointSeries);
    procedure readXYfromFile(Filename: TFilename;
      var Series: TPointSeries); virtual;
    procedure saveRootPositons(SaveDialog: TSaveDialog);
  published
    { Published-Deklarationen }
    procedure errasePosArr; { Löscht die Pos-Array-Member }
  end; { Ende Deklaration TRasterData }

  TSubmodRootDiff = class(TSubmodel)
    { Deklaration Klasse TSubmodRootDiff. Basisklasse für abgeleitete Diff-Modelle }
  private
    { Private-Deklarationen }
    { Felder }
    { Funktionalität der Basisklasse: Alle Modelle können Rasterdaten einlesen, Rän-
      der von der Berechnung ausschließen und die Daten im Hume-Formular in den
      entsprechenden Reitern darstellen. 1D-Modell macht keine Ausgabe im Reiter 3D
      Plot. }
    fMyChart: TChart;
    fMyAdvStringGrid: TAdvStringGrid;
    fMyStructModel: TSubmodRootStrucNew;
    xyFile: TextFile;
    { Methoden }
    // Hilfsmethoden
    procedure init_; { Initmethode erweiterbar für Dateizugriffe,
      die nur einmalig durchgeführt werden sollen. }
  protected
    { Protected-Deklarationen, Zugriff auch von abgeleiteten Klassen. }
    { Objekt für Darstellung der WAP im Hume-Formular }
    SeriesXY: TPointSeries;
    Flaeche: real; { Fläche [cm^2] }
    RasterData: TRasterData; { Das Submodel besitzt RasterData }
    initialisiert: boolean; { Variable speichert, ob bereits initialisiert
      wurde. }
    { * -----------------------------------------------------------------------------
      Member HUME-Basisklasse TPar (Parameter)
      ------------------------------------------------------------------------------* }
    dimensionX, { Breite des "Rechenfeldes" [cm] }
    dimensionY, { Hoehe des Rechenfeldes    [cm] }
    gridWidth, { Weite des Rastergitters (aggr. Daten) in x-Richtung [cm] }
    gridHeight, { Weite des Rastergitters (aggr. Daten) in y-Richtung [cm] }
    Dl, { Diffusionskoeffizient von Nitrat in freiem H20 [cm^2/s] }
    max_dt, { maximale Zeitschrittweite [s] }
    theta, { volumetrischer Wassergehalt [cm3/cm3] }
    Tiefe, { Tiefe der Schicht [cm],
      Annahme für Mineralisationsberechnung }
    { Mineralisationsmodell noch nicht vorhanden, wäre aber für beide Modelle zu im-
      plementieren. }
    minera, { Mineralisationsrate in [Kg N / ha*d] }
    Clmin, { Minimale Bodenlösungskonzentration
      [Mol/l], wird auch für die numerische Lösung im 1D-
      Modell benötigt, Cave: im Original stand Mikromol/l }
    { Ränder sind notwendig, damit bei hexagonaler Verteilung der Wurzelaustritts-
      punkte die Randeffekte ausgeblendet werden können. }
    verticMargin, { vertikaler Rand [cm] }
    horizMargin, { horizontaler Rand [cm] }
    depthLayer, { Tiefe der Schicht bei der Auswertung begonnen
      werden soll (im 2D-Querschnitt) [cm] }
    SizeLayer, { Mächtigkeit der Schicht [cm] }

    // Möglichkeit, die Kennzahlen Bodenerschließung durch W. auch als Par. einzulesen
    ParMRLD, { Mittlere Wurzellängendichte [cm/ccm] }
    Rad_Wurzel { Radius der Wurzel [cm] }
      : TPar;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen
      ------------------------------------------------------------------------------ *)
    N_AmountSoil, { NMenge [kg N/ha], auch Grundlage der Berechnung von
      Konzentrationen in den Rechenelementen vgl. Kage, Diss.
      S.79, dort wurden Konzentrationen 10,0 Mikromol/l
      angenommen. }
    Sum_N_AmountRoots { kumulierte N-Menge, die durch die Wurzeln aufgenommen
      wurde [kg N/ha], bezogen auf vorg. Tiefe }
      : TState;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TVar (Variablen)
      ------------------------------------------------------------------------------ *)
    RLD_mean, { Mittl. Wurzellängendichte in einer Schicht [cm/cm^3]
      berechnet ohne Wurzeln, die sich in den Rändern be-
      finden. }
    AreaMiddle, { Mittige Fläche ohne Ränder[cm2] }
    num_roots, { Anzahl der Wurzeln in Mitte und Rändern[n] }
    number_consid_roots, { Anzahl Wurzeln, die nicht in Rändern liegen [] }
    Min_S, { Mineralisationsrate [Mol/cm^3*s] }
    c_start, { Startkonzentration [mol/cm^3], wird aus der initialen N-Menge
      berechnet, 1D-Modell kann auch Konzentrationen berech-
      nen }
    cl_av, { mittlere Konzentration in der Bodenlösung [Mol/cm^3 }
    volumen, { Volumen der Bodenschicht mit Rändern [cm3] }
    De, { Effektiver Diffusionskoeffizient [cm^2/s] }
    errorReg { Maß für Fehler bei regulärer Verteilung = Anzahl der
      Wurzeln, die bei der Erzeugung der Gleichverteilung
      nicht in das Beobachtungsfenster passen in Prozent der
      gesamten vorhandenen Wurzeln.[%] }
      : TVar;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen). Werden in abgeleiteten
      Klassen deklariert und erzeugt.
      ------------------------------------------------------------------------------ *)
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TOption (Optionen)
      ------------------------------------------------------------------------------ *)
    IniMethod, { Art der Initialisierung, z.B. Datei, Strukt-Modell }
    uptake_function, { Art der Aufnahmeberechnung }
    RootInpDataFileXY, { Pfad und Name der Ini-Datei mit XY-Wurzeldaten }
    RootInpDataFile, { Pfad und Name der Ini-Datei mit Wurzeldaten
      als Anzahlen in einem Grid }
    OutputXY, { Festlegen ob XY-Daten in Datei geschrieben
      werden }
    RootXYOutpDataFile { Pfad und Name der Output-Datei für XY-Daten }
      : TOption;

    { Methoden }
    // Hilfsmethoden
    { Initialiserung in Abhängigkeit, ob bereits Daten aus Datei eingelesen wurden. }
    procedure init_eingelesen; virtual;
    procedure fillChartRootDistr;
    procedure fillGridRasterData;
    procedure EqualDistribution;
    procedure distributeHexagonRow;
    procedure distributeHexagonCol;
    procedure writeOutputToFile;
    procedure removeMarginRoots;
    procedure calcNumberConsRoots; { Berechnet die Anzahl der Wurzeln, die sich
      im Beobachtungsfenster, aber nicht in den
      Rändern befindet }
    // Umrechnungen Menge in Konz und zurück
    function Mg_func(Tiefe_cm, theta, Cli_mol_cm3: real): extended;
    function Cl_func(Tiefe_cm, theta, NMenge: real): extended;
  public
    { Public-Deklarationen }
    hasWritten: boolean; // Schalter für einmaligen Schreibzugriff
    procedure createAll; override;
    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobModReferenz: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    // Set- und Get-Methoden
    function getRasterData: TRasterData;
  published
    { Published-Deklarationen }
    // Veröffentlichung der Eigenschaften im Ojektinspektor.
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
  { speichert die aus einer Datei eingelesenen Positionen der Wurzeln. Globale
    Variable notwendig, denn wenn PosArr_eingelesen Member eines Objektes ist, kommt
    es (mir unverständlich) zum Programmabsturz. }
  PosArr_eingelesen: array [1 .. max_num_roots] of TPointDoubleType;

implementation

(* -----------------------------------------------------------------------------
  Implementierung der Methoden von TRasterData
  ------------------------------------------------------------------------------ *)
constructor TRasterData.create(Submodel: TSubmodel);
begin
  { RasterData-Instanz kennt ihr Submodell }
  SubmodRootDiff := Submodel;
end; // End TRasterData.create

procedure TRasterData.errasePosArr;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE:   TRasterData
  BESCHREIBUNG: Löscht saemtliche Felder des Pos-Arrays. Anschließend können die
  Felder mit neuen xy-Werten beschrieben.
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
  ZUGEHÖRIGE KLASSE:   TRasterData
  BESCHREIBUNG:Methode zum Einlesen von AGGREGIERTEN Rasterdaten (Wurzel-ANZAHLEN),
  die dann der zufälligen Bestimmung von Koordinatenpunkten zugeführt werden.
  Info Funktionsweise: Bsp.: readln(f, Ncols) Zuweisung des aus f gelesenen Wertes
  an die Variable Ncols.
  ------------------------------------------------------------------------------ *)
var
  F: TextFile; { Dateivariable vom Typ Textfile }
  S: string;
  Row, Col, root, AllRoot: integer;
  PointDoubleType: TPointDoubleType;
begin
  AssignFile(F, fn); { Datei ausgewählt }
  Reset(F);
  // Auslesen des Headers
  Readln(F, S); { Erste Zeile der Datei (Header) lesen und
    verwerfen }
  DescStr := S; { -> DescStr: Beschreibung des Datensatzes }
  Readln(F, S);
  Date := StrToFloat(S); { Zweite Zeile: Datum (TDateTime-Format }
  Readln(F, NRows); { Dritte Zeile: Anzahl Zeilen }
  Readln(F, NCols); { Vierte Zeile: Anzahl Spalten }
  Readln(F, DimRows); { Fünfte Zeile: Höhe Zeilen [cm] }
  Readln(F, DimCols); { Sechste Zeile: Breite Spalten [cm] }
  // Wiederholtes Lesen der Daten bis zum Ende der Datei
  for Row := 0 to NRows - 1 do
  begin { Wurzelanzahlen in Count-Array einlesen }
    for Col := 0 to NCols - 1 do
      read(F, CountArr[Col, Row]);
    Readln(F); // Neue Zeile
  end;
  closeFile(F);
  AllRoot := 1; // Beginn bei 1, da PosArr bei 1 beginnt.
  { Wurzeln in jeder Rasterzelle zufällig verteilen }
  for Col := 0 to NCols - 1 do
  begin
    for Row := 0 to NRows - 1 do
    begin
      { Es werden genau soviele Wurzeln dem PosArr zugewiesen, wie als Anzahlen ins
        countArr eingelesen wurden. }
      for root := 1 to CountArr[Col, Row] do
      begin
        // randomize;     // [Was macht Randomize?]
        PosArr[AllRoot].x := (Col) * DimCols + Random * DimCols;
        PosArr[AllRoot].y := (Row) * DimRows + Random * DimRows;
        PosArr[AllRoot].root := AllRoot;
        Series.AddXY(PosArr[AllRoot].x, PosArr[AllRoot].y);
        Inc(AllRoot);
      end;
    end;
  end;
  { Anzahl Wurzeln insgesamt kennen das Modell und das RasterData-Objekt. }
  TSubmodRootDiff(SubmodRootDiff).num_roots.v := AllRoot - 1;
  self.NRoots := AllRoot - 1;
end; // End TRasterData.readRasterData

procedure TRasterData.readXYfromFile(Filename: TFilename;
  var Series: TPointSeries);
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TRasterData
  BESCHREIBUNG: Prozedur liest XY-Koordinaten aus einer Datei ein.
  Das übergebene (call-by-reference!) PointSeries-Objekt wird nach und nach mit
  den XY-Paaren gefüllt.
  ------------------------------------------------------------------------------ *)
var
  F: TextFile; // Dateivariable für Textdateien
  s_header,
  { Variable wird benötigt, da es in einer Textzeile der Datei Werte gibt, die nicht
    eingelesen, sondern übersprungen werden sollen (vgl. Dateiformat). }
  restString: String;
  { pos_delimiter speichert Position des letzten Begrenzungszeichens im String }
  pos_delimiter: integer;
  PointDoubleType: TPointDoubleType;
  i: integer;
begin
  errasePosArr;
  // Problem: Brauch ich den Löschvorgang (s.aufgerufene Methode???)
  // Einlesen aus von Daten Datei:
  try
    AssignFile(F, Filename); // Verbindet Dateivariable mit Datei
    Reset(F); // Lesezugriff
    // Lesen des Headers. Wird verworfen
    Readln(F, s_header);
    // Lesen der eigentlichen Daten
    i := 1; // PosArr beginnt bei 0
    { Problem: Evtl. muss mit 1 initialisiert werden, um korrekte Anzahlen Wurzeln
      zu erhalten }
    NRoots := 0;
    { Festlegen der Grenzen von PosArr, könnte verwendet werden, wenn man PosArr als
      dyn. Array implementieren wollte }
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
      // Abschneiden der Leerzeichen am Stringende:
      restString := TrimRight(restString);
      { Bestimmung des letzten Leerzeichens im String: }
      pos_delimiter := LastDelimiter(#9, restString); // #9 ist Leerzeichen
      // Abschneiden des vorderen Anteils des Strings bis zum letzten Leerzeichen:
      Delete(restString, 1, pos_delimiter);
      PointDoubleType.area := StrToFloat(restString);
      { Wie beim 2D-Modell müssen auch beim 1D-Modell alle WAP berücksichtigt werden,
        damit ein geeigneter Flächeninhalt des Voronoi-Polygons berechnet werden kann.
        Beim 2D-Modell werden dann später lediglich die Aufnahmen der Senken berücksich-
        tigt, die sich NICHT in den Rändern befinden, beim 1D-Modell werden für die Be-
        rechnung der Kennzahlen der lognormalen Verteilungsfunktion nur Koordinaten be-
        rücksichtigt, die sich NICHT in den Rändern befinden. }
      PosArr[i].x := PointDoubleType.x;
      PosArr[i].y := PointDoubleType.y;
      PosArr[i].root := i;
      PosArr[i].area := PointDoubleType.area;
      Series.AddXY(PointDoubleType.x, PointDoubleType.y);
      Inc(i);
    end;
    // Submodell kennt die Anzahl der Wurzeln
    TSubmodRootDiff(SubmodRootDiff).num_roots.v := NRoots;
    { wg. Wurzel bei 0/0. Die Position dieser Wurzel ist offensichtlich fehlerhaft. }
    // ShowMessage(FloatToStr(RasterData.PosArr[1].x));
  except
    ShowMessage('Fehler beim Zugriff auf Datei');
  end;
  closeFile(F);
end; // End TRasterData.readXYfromFile

procedure TRasterData.saveRootPositons(SaveDialog: TSaveDialog);
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TRasterData
  BESCHREIBUNG: Bei Einlesen aus Datei mit aggr. Wurzeldaten
  Speichern der (generierten) zufällig erzeugten Wurzelkoordinaten
  (unter Berücksichtigung der Zuordnung zu einer 5X5 cm Grid-Zelle in Form von
  Gleitkommazahlen in einer Datei ab.
  ------------------------------------------------------------------------------ *)
var
  F: TextFile;
  root: integer;
begin
  If SaveDialog.Execute then
  begin
    AssignFile(F, SaveDialog.Filename);
    rewrite(F);
    { Format wird benötigt für Einlesen in ein externes Programm, dass
      Voronoi-Polygone berechnet. }
    // Schreiben des Headers
    writeln(F, 'X	 Y	Number	Edge	Species	Radius');
    // Schreiben der zufällig generierten X und Y-Werte
    for root := 1 to NRoots do
      writeln(F, PosArr[root].x, ' ', PosArr[root].y, ' ', root, ' e a 0');
    closeFile(F);
  end;
end; // End TRasterData.saveRootPositons

(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TRasterData
  BESCHREIBUNG: Set- und Get-Methoden
  ------------------------------------------------------------------------------ *)

(* -----------------------------------------------------------------------------
  TRasterData Ende
  ------------------------------------------------------------------------------ *)

(* -----------------------------------------------------------------------------
  Implementierung TSubmodRootDiff
  ------------------------------------------------------------------------------ *)
procedure TSubmodRootDiff.createAll;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff
  BESCHREIBUNG:
  Erzeugen und Initialisieren von Zustandsvariablen, Variablen und Parametern.
  Der erste Parameter des Funktionsaufrufs übergibt einen String, der mit dem Be-
  zeichner identisch ist und nachdem gesucht werden kann.
  Der zweite Paramter enthält einen String zur Kennzeichnung der verwendeten
  Einheit ([-] für dimensionslose Paramter etc.)
  Der dritte Parameter ist der eigentliche (Fließkomma)-Wert
  Erläuterung der Bezeichner s. Deklaration.
  ------------------------------------------------------------------------------ *)
begin
  inherited createAll;
  SeriesXY := TPointSeries.create(self);
  initialisiert := false;
  RasterData := TRasterData.create(self);
  // Erzeugen und initialisieren von TPar
  ParCreate('dimensionX', '[cm]', 100, dimensionX);
  ParCreate('dimensionY', '[cm]', 100, dimensionY);
  ParCreate('gridWidth', '[cm]', 5, gridWidth);
  ParCreate('gridHeight', '[cm]', 5, gridHeight);
  ParCreate('max_dt', '[s]', 0, max_dt);
  ParCreate('theta', '[cm3/cm3]', 0.2, theta);
  ParCreate('Tiefe', '[cm]', 10, Tiefe);
  // [0=Keine Mineralisation]
  ParCreate('Minera', '[kg N/ha*d]', 0, minera);
  ParCreate('Dl', '[cm^2/s]', 1.92E-5, Dl);
  ParCreate('Clmin', '[mol/l]', 0, Clmin);
  { Cave: im Original stand Mikromol/l }
  ParCreate('verticMargin', '[cm]', 0, verticMargin);
  ParCreate('horizMargin', '[cm]', 0, horizMargin);
  ParCreate('depthLayer', '[cm]', 0, depthLayer);
  ParCreate('SizeLayer', '[cm]', 10, SizeLayer);
  ParCreate('ParMRLD', '[cm/ccm]', 0, ParMRLD);
  ParCreate('Rad_Wurzel', '[cm]', 0, Rad_Wurzel);
  // Erzeugen und Initialisieren von TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 0, false, N_AmountSoil);
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, Sum_N_AmountRoots);
  // Erzeugen und Initialisieren von TVar
  { Problem/Cave: Variablen werden immer zunächst mit 0 initialisiert, wenn ein
    von 0 unterschiedener Startwert notwendig ist, muss Berechnung und Zuweisung
    in init geschehen. Besser wäre es solche Variablen dann aber nicht als TVar
    zu demklarieren. }

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
  // Erzeugen und initialisieren von TOption
  { Festlegen, aus welcher Quelle die Wurzeldaten stammen. }
  OptCreate('IniMethod', 'InpPar', IniMethod);
  IniMethod.OptionList.add('InpPar'); // Kennzahlen RLD/VC als Parameter
  IniMethod.OptionList.add('XYFile');
  IniMethod.OptionList.add('RasterDataFile');
  IniMethod.OptionList.add('SubmodStruct');
  { Festlegen der Aufnahmefunktion }
  OptCreate('uptake_function', 'ZeroSink', uptake_function);
  uptake_function.OptionList.add('ZeroSink');
  uptake_function.OptionList.add('ConstInflux');
  uptake_function.OptionList.add('MM');
  OptCreate('OutputXY', 'no', OutputXY);
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Pfade für Modellvergleich 1D2D }
  { Pfade zu ein und Ausgabedateien für beide Sub-Modelle identisch. Beide Sub-Modelle
    gleichzeitig in einem Modelllauf zu haben, macht nur Sinn, wenn vergleichend ge-
    arbeitet wird. }
  OptCreate('RootInpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\abo130782.txt', RootInpDataFile);
  // Datei mit den Wurzelpositionen
  RootInpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\abo130782.txt');
  OptCreate('RootInpDataFileXY',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\poly_11_1406_40_60cm_mod.txt',
    RootInpDataFileXY); // Datei mit den Wurzelpositionen
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
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff
  BESCHREIBUNG: Durchführung diverser Initialisierungen
  ------------------------------------------------------------------------------ *)
var
  i, numberGridCellsX, { Anzahl der Gridzellen in X- und Y-Richtung }
  numberGridCellsY: integer;
begin
  inherited;
  // Ausgabedatei für XY-Koord neu schreiben

  AssignFile(xyFile, RootXYOutpDataFile.Option);
  rewrite(xyFile); { Neuanlage oder Ersetzen der Datei, d.h. auch die Datei wird
    bei jedem Modellauf neu geschrieben. }
  closeFile(xyFile);
  numberGridCellsX := trunc(dimensionX.v / gridWidth.v);
  numberGridCellsY := trunc(dimensionY.v / self.gridHeight.v);
  setLength(RasterData.CountArr, trunc(numberGridCellsX));
  for i := 0 to high(RasterData.CountArr) do
  begin
    setLength(RasterData.CountArr[i], trunc(numberGridCellsY));
  end;
  { Berechnung des Diffusionskoeffizienten der Lösung im Boden aus dem effektiven
    Diffusionskoeffizienten. Für das Folgende vgl. Diss. Kage, S.43f.:
    für das 1D-Modell (Nye/Tinker, Solute movement S.299) wird der effektive
    Diffusionskoeffzient benötigt. Er berechnet sich nach De=Dl*f, wobei
    Dl: Diffusionskoeffizient in freiem Wassser und f der impedance-Faktor ist.
    Es gilt weiterhin folgende Beziehung zwischen theta und dem Impedenzfaktor f:
    (vgl. Kage, S.41 f=3.35*Theta^2 }
  De.v := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  { Berechnung effektiver Diffusionskoeffizient [cm2/s-1], für 2D-Modell }
  // De.v := Dbf(theta.v)/Theta.v; //alte Implementierung
  // Initialisierungen von TVar, für die das zu diesem Zeitpunkt Sinn macht:
  Flaeche := dimensionX.v * dimensionY.v;
  { Fläche der zu untersuchenden Schicht }
  volumen.v := Flaeche * Tiefe.v;
  { Berechnung Mineralisationsrate in [Mol/cm3*s] }
  // Min_S.V := minera.v/14*1000/86400*1/(Tiefe.v*1e8);
  Min_S.v := minera.v * 1000 / (14 * 86400 * Tiefe.v * 1E8);
  { Berechnung der initial in der Bodenschicht enthaltenen N-Menge aus der
    Konzentration. Problem: Muss ich hier noch mit Theta multiplizieren, weil sich
    die Konzentration nur auf das Volumen des im Boden enthaltenen Wassers bezieht? }
  // Init_NAmount_layer.V:=c_start.V*volumen.V*14/1000;
  { Zu den Einheiten:
    [g]    =         Mol/l * l        g/Mol }
  { Implementierung einer Prüfung auf bereits geschehene Initialisierung. Erlaubt
    einerseits eine einfache Erweiterung bezüglich einer Initialisierung, die
    z.B. Dateizugriffe benötigt bzw. Objkete instantiiert. Dies sollte in der Methode
    _init geschehen. Gleichzeitig sollen die Initialisierungen nur dann durchgeführt
    werden, wenn bereits Wurzeln eingelesen wurden
    Es kann dabei nicht die ursprüngliche Methode von TSubmodell genommen werden,
    da diese Methode mehrfach aufgerufen wird. }
  if IniMethod.Option = 'rasterdatafile' then
  begin
    // init_;
    // init_eingelesen wird von den abgeleiteten Methoden mit inherited aufgerufen.
    initialisiert := true;
  end;
end; // End TSubmodRootDiff.init

procedure TSubmodRootDiff.init_;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff
  BESCHREIBUNG: In der Methode werden verschiedene Initialisierungen durchgeführt,
  die nur einmalig durchgeführt werden sollen (Init-Prozedur des globalen Modells
  wird mehrfach aufgerufen). Relevant wäre das zum Beispiel beim Erzeugen von Ob-
  jekten oder bei Dateizugriffen.
  Auf Vorrat programmiert, zur Zeit finden keine solchen Zugriffe statt.
  ------------------------------------------------------------------------------ *)
begin

end; // End TSubmodRootDiff.init_

procedure TSubmodRootDiff.init_eingelesen;
(* ------------------------------------------------------------------------------
  Beschreibung:
  Berechnet die ANZAHL der Wurzeln, die im Beobachtungsfenster
  und gleichzeitig NICHT in den Rändern liegen.
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
  stretch, // Strecke mit Länge (2xRad_AK - Kante)/2 (vgl. Folie Gleichverteilung
  edgeHexagon: real; // Kantenlänge 6-Eck
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
