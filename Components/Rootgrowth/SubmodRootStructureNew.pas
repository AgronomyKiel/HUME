unit SubmodRootStructureNew;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, System.Math,
  UState, UMod, Vcl.extctrls, voro, GraphObjects, Vcl.stdctrls, UFORMMOD;

(* ------------------------------------------------------------------------------
  Allg Hinweise:
  - Originalkommentare bei Pages nicht vergessen.
  - Es gibt einige, noch nicht ausgeführte Ansätze, die m.E. zur Modellierung
  lokaler Einflüsse verwendet werden sollen (Arrays M_TSol, M_DensSol,M_HumSol)
  wurde auskommentiert
  ------------------------------------------------------------------------------ *)
const
  // Schalter für Debuggen
  debugging = false;
  debugMeris = false;
  // für das Temperaturmodell
  ncomp = 20;
  // Simulationszeit in Tagen  (Benötigt für MTSol Array -> veraltet)
  // MaxTime=62;
  // Anzahl Horizonte
  // NumberHORMAX = 5;
  // Maximale Anzahl der WS, die simuliert werden können
  maxRS = 50;
  // Anzahl berechneter Schichten
  numComp = 10;
  // Maximale Anzahl der Kompartimente (Schichten)
  max_comp = 50;
  // maximale Anzahl von Zufallszahlen, die für die PW-Meristeme reserviert werden
  maxRandomPW = 10; // 1000 pro generiertes WS
  // Maximale Anzahl der Internodien
  NumberINTMAX = 10;
  // Maximale Anzahl der Entwicklungsordnungen
  NumberORDMAX = 4;
  // Schichtdicke erstes Segment
  GaugeFirstSeg = 5;
  // Schichtdicke Normalsegment
  GaugeStandardSeg = 10;
  // Schichtdicke letztes Segment
  GaugelastSeg = 19;
  // Schichtdicke für Berechnung Verteilungs-Kennzahlen
  SizeLayer = 10;
  { In den Zeilen werden die XYZ-Koordinaten für die Ursprünge der Primordien in
    Bezug auf die  festgelegt auf die Internodien festgelegt: System von übereinander
    gelagerten Kreisen. }
  { COrigPrXZ : array [0..NumberINTMAX-1, 0..2] of double =
    ((0.0,0.0,5.0),(0.0,0.0,4.8),
    (0.0451,0.0,3.8),(0.150,0.0,3.54),(0.297,0.0,3.22),
    (0.518,0.0,2.75),(0.838,0.0,2.06),(1.05,0.0,0.86)); }
  // für NL-Versuch
  { COrigPrXZ : array [0..NumberINTMAX-1, 0..2] of double =
    ((0.0,0.0,5.0),(0.0,0.0,4.8),
    (0.0451,0.0,3.8),(0.150,0.0,3.54),(0.297,0.0,3.22),
    (0.518,0.0,2.75)); }
  { Array mit den mittleren monatlichen Luft-Temperaturen am jeweiligen Standort,
    wobei der Eintrat in Feld 0 dem Januarwert, der Eintrag im Feld 11 dem Dezember-
    wert entspricht, derzeit (23.06.2006 für Schleswig), für Berechnung der Boden-
    temperatur nach Porter oder mit 'Sinus-Modell' (wahrsch. Clausnitzer), könnte
    auch über Parameterdekl. oder Einlesen aus Wetterdatei erfolgen }
  TempArrMonth: array [0 .. 11] of double = (1.5, 1.7, 3.6, 7.4, 11.6, 14.5,
    17.0, 17.1, 13.5, 9.0, 4.7, 1.9);
  { Epsilon ist Konstante mit niedrigem Wert, wird möglw hauptsächlich dazu verwen-
    det, dass ein Fehler durch eine Teilung durch 0 bzw. 1 vermieden werden kann. }
  Epsilon: double = 1.0E-6;

var
  // Dimensionen des Weltwürfels allg. bekannt.
  dim_X, dim_Y, dim_Z: double;
  NummerSeg: integer; // Fortlaufende Nummer für die Segmente
  SegNumberFile, // Bez Datei für Segmentnummern
  PotFile, // Bez Datei für pot. Verzweigungspunkte
  MerisFile // Bez Datei für Daten der Meristeme
    : string;
  fSegNumb, fpotFile, fMerisFile: TextFile;
  // Schalter zwischen dummyGrowth und tatsächlichem Wachstum
  dummyGrowth: boolean;

type
  { Mengen }
  kindPlane = (horizontal, vertikal, saggital);
  { Arraytypen }
  r2 = array [0 .. 1] of single;
  r3 = array [0 .. 2] of single; // Array für Koord. im R3
  RandArr = array [0 .. maxRandomPW] of double;
  // Für schichtenspez. Zustandsvariablen und externe V.
  TStateArray = array [0 .. numComp + 1] of TState;
  TVarArray = array [0 .. numComp + 1] of TVar;
  TExtArray = array [0 .. numComp + 1] of TExternV;
  TParArray = array [0 .. NumberINTMAX - 1] of TPar;
  TParArray2D = array [0 .. NumberINTMAX - 1] of array
    [0 .. NumberORDMAX - 1] of TPar;
  zweiDArr_type = array of array of integer;

  { Recordtypen }
  { Record beinhaltet die für die Ebenengleichung (3-Punkte-Form) notwendigen
    (Orts-) Vektoren im R3 (jeweils Vektoren mit 3 Komponenten). Die Punkte, die die
    Ebene aufspannen, haben folgende Lage, wenn man von oben auf die Ebene schauen
    würde: unten links, oben links und unten rechts. Der Koordinatenursprung befin-
    det sich in der linken oberen Ecke des 'Welt-Würfels' }
  planeVector = record
    vectorLoc_bottomLeft, vectorLoc_upperLeft, vectorLoc_bottomRight: r3;
  end;

  // Ereignistyp
  TCanCalcVoronoi = procedure(Sender: TObject; x, y: integer) of object;

  { Klassendeklarationen }
  TMyPaintBox = class(TPaintBox)
    { Erweitert die Paintbox um eine Ereignisroutine für die Übergabe eines Punktes
      und das Anschmeißen der Voronoi-Maschine }
  private
    FCanChangeVoronoi: TCanCalcVoronoi;
  published
    property CanCalcVoronoi: TCanCalcVoronoi read FCanChangeVoronoi
      write FCanChangeVoronoi;
  end;

  TMyFloatPoint = class(TObject)
    { Klasse wird in SubmodRootDiff verwendet. }
    x, y: double;
  end;

  TR3 = class(TObject) // Klasse für 3D-Koordinat f. Listeneinträge
  public
    Koord3D: r3; // Array für Koord. im R3
    procedure assign(Source: TR3);
  end;

  TBranchDensPrim = class(TObject) { Klasse für Verzweigungsdichte der Prim-W.
      (Klasse wird derzeit noch nicht genutzt. }
    RS_ID, NumPrimAxis, // laufende Nummer für die Prim. Wurzeln
    NumSeg // Anzahl der Segmente, die diese Achse bilden.
      : integer;
    PrimRootLength // Länge der Primär-Wurzel-Achse
      : single;
  end;

  TSRP = class(TObject)
  private
    RS_ID: integer; // Einzelwurzelpolygon weiß zu welchem WS es gehört.
    NumSeg: integer; // Einzelwurzelpolygon weiß zu welchem Segment es gehört
    area: single;
    vertexList: TList; // Liste mit den Eckpunkten (TPoint) des Polygons
  public
    x, y: single;
    constructor create;
    destructor destroy; override;
  protected

  published
  end;

  TSRPLight = class(TObject)
    { abgespeckte speicherschonendere Version eines SRP }
  private
    { Private-Deklarationen }
  protected
  public
    { Public-Deklarationen }
    x, y, wld: single; // Wurzellängendichte des SRP [cm/cm^3]
  end;

  TMeristem = class(TPersistent)
  private
    num { lfd. Nr. Meristem }
    // NumSegProd            { könnte in Met. RamificationRec berechnet werden.}
      : integer;
    Order: byte; { Je nach Entwicklungsordnung verhält sich das
      Meristem unterschiedlich }
    Internode: byte; { Je nach zugehörigem Internodium verhält sich das
      Meristem unterschiedlich, Meristem weiß von welchem
      Intenodium es abstammt }
    Coord, { Lage der Wurzelspitze in 3D Koord. }
    Coordold, { Meristem kennt die Lage aus dem letzten Zeitschritt,
      notwendig für Bestimmung pot. Verzweigungspkte (
      Berücksichtigung von Nicht-Verzweigungszonen) }
    DirGrowth: r3; { Vektor in R3 für Wachstumsrichtung }
    DistBase, { Distanz zur Basis }
    DistPrimInit, { Parameter wird verwendet, um festzustellen, ob &
      wann Verzweigung erfolgen kann (erst, wenn Gesamt-
      länge > ap. und bas. NVZ }
    Age, { Biologisches Alter des Meristems [°Cd] }
    PRamif, { aktueller Ramifikationsparameter }
    PRamifold, { Ramifikationsparameter aus dem letzten Zeitschritt. }
    sumElongNew, { Summe der bisherigen Verlängerung inkl. Verl. im
      Zeitschritt }
    sumElongOld, { Summe der bisherigen Verlängerung ohne akt. Verl. }
    remainderElong, { Verlängerungsdistanz, die für Verzweigung zur Verfügung
      steht und Verlängerungsdistanz, die in den nächsten
      Zeitschritt übernommen wird. }
    remainderElongOld, { Meristem weiss auch nach der Verlängerung mit
      welchem Rest es in diesen Zeitschritt eingetreten
      ist. }
    basNVZ { Meristem kennt die basale NVZ der Ordnung }
      : single;
    { Variable speichert die Koeffizienten der Wachstumsgl. (an erster Stelle Par.A,
      an zweiter Stelle Par.B) -> im Falle monomol. Wachstums ist Par. A also die max
      Länge der ACHSE }
    PCroiss: r2;
    // PotRamListEmpty         { Flag, ob Liste mit den pot. Verzweigungspunkten
    // geleert wurde.}
    Activ, { Member für Aktivität des Meristems }
    Maturity, { Mature = geschlechtsreif, Meristem kann nur
      wachsen, wenn Maturity = true }
    ThresBranchFirst, { Schwellenwert für Verzweigung wird erstmalig über-
      schritten }
    haspotRam { Flag für neu angelegtes Segment, bleibt auf false
      bis erstmalig pot.Rampunkte bestimmt werden. }
      : boolean;
    PointsOfRam: { Meristem enthält Liste mit potentiellen
      Verzweigungspunkten }
      TList;
    Remcoord { Lage des Meristems = Wurzelspitze im letzten Zeit
      schritt, notwendig, wenn Nichtverweigungszone
      berücksichtigt werden soll. }
      : r3; { Der letzte Verzweigungspunkt wird gesondert gespeichert. }
    // LastRamPoint
    // : TR3;
    procedure writePotRam(Coord: r3);
  public
    constructor create; overload;
    destructor destroy; override;
    procedure assign(Source: TMeristem);
    procedure findFirstRamPoint;
    procedure findFirstNoBas;
    procedure findFurtherRamPoint;
    procedure findFirstRamNewDir;
    procedure updateRemcoord;
    procedure setBasNVZ(basNVZ_: single);
    function getPointsOfRam: TList;
  protected

  published
  end;

  TPotSeg = class(TObject)
    { Für Liste mit aus den potentiellen Verzweigungspunkten gebildeten Linien
      -> Nachzeichnen der Krümmung }
  private
    co, ce: r3;
  public
    function getCo: r3;
    function getCe: r3;
  protected
  published
  end;

  TSegment = class(TPersistent)
  private
    num, { Fortlaufende Nummer der Segmente }
    // Topologie
    FatherID, { ID des Segments, von dem das aktuelle Segment
      entspringt. }
    PathLengthNum, { Anzahl der Segmente zwischen diesem Segment und
      dem ersten Segment der Primärwurzel ('Emissionsseg-
      ment') }
    RS_ID, { Segmente wissen, zu welchem Wurzelsystem sie
      gehören, damit sie diese Info an die SRP's weiter-
      geben können, die in einer gemeinsamen Liste stecken. }
    PrimSegId, { Segmente wissen, von welcher Emission sie abstammen. }
    numMeris { Segment kennt die Nummer des Meristems, welches es
      bei der Anlage besaß }
      : integer;
    isPrim, { Flag zeigt an, ob das Segment höherer Ordnung
      eine bloße Anlage ist }// USL
    isCompSeg, { Flag zeigt an, ob es sich um ein zusammengesetztes
      Segment handelt. }
    isEmiss { Flag zeigt an, ob das Segment Sprossbasis oder
      vom Keimling entspringt. Wird benötigt für die
      Bildung von zusammengesetzten Segmenten. }
      : boolean;

    TotNVZ, { Summe aus apikaler und basaler Nicht-Verzweigungs-
      zone }
    SegLength, { Segmentlänge[cm] }
    DateForm { Erzeugungsdatum }
      : single;
    Meristem: TMeristem; { Segmente können Meristeme besitzen }

    Internode, { Internodium, von dem das Segment abstammt }
    Order: byte; { Entwicklungsordnung }
    co, { Anfangskoordinaten }
    ce: r3; { Endkoordinaten }
    ChildList: TList; { SegmentListe mit Nachkommen }
    function calcAbsValue(ASegment_: TSegment): double; overload;
    function calcAbsValue(co, ce: r3): double; overload;
    function vectorSubtrakt(vector_a, vector_b: r3): r3;
  public
    { Zwei Konstruktoren, der letztere, falls (z.B. für Konnektivität der Vorgänger
      wichtig wird }
    constructor create; overload;
    constructor create(RS_ID: integer); overload;
    constructor create(Father_: TSegment); overload;
    destructor destroy; override;
    procedure assign(Source: TPersistent); override;
    function calcLengthFamily(ASegment: TSegment): double;
    // Set und Get
    function getInternode: byte;
    procedure setInternode(internode_: byte);
    procedure setFatherID(Father_id: integer);
    function getCo: r3;
    function getCe: r3;
    function getMeristem: TMeristem;
    function getChildList: TList;

  protected

  published

  end;

  TRootsystem = class(TPersistent)
  private
    // Array mit Zufallszahlen
    ARandArr: RandArr;
    // Variable speichert aktuell gezogene Zahl aus ARandArr  (Index)
    aktIndRandArray: integer;
    // Gesamtwurzellänge
    TotRootLengthWS,
    // Wurzellängenzuwachs im Zeitschritt
    RootLengthdt,
    // X- und Y-Koordinate des Aussaatpunktes
    SeetPosX, SeetPosY: double;
    // Jedes WS hat eine Liste mit Zeigern auf alle Segmente
    SegListTotal, SegListTotalDisp,
    // Jedes Wurzelsystem hat eine Liste mit seinen Primärwurzeln (1. Segmente)
    SegListEO: TList;
    { für Nachzeichnen der Krümmung: aus den potentiellen Verzweigungspunkte werden
      Pseudosegmente berechnet -> für Zeichnung und korrekte Berechnung der WAP }
    PotSegListWS: TList;
    { AnglesInt speichert die Position auf dem Kreis für das 1. Primordium der
      Pirmärwurzel an einem Internodium, bzw. gibt den Bezugspunkt, von dem ausgehend
      bei Verzweigung der Ort des Primordiums bestimmt wird. }
    AnglesInt: array [0 .. NumberINTMAX - 1] of double;
    RS_ID, // Fortlaufende Nummer RS, Beginn bei 0
    NumberSegProd, // Anzahl Segmente
    NumberPrimaryRoots, // Anzahl Meristeme im WS [eigentlich unnötig]
    NumberMerisDest, // Anzahl zerstörter Meristeme [eigentlich unnötig]
    NumCurrentEmission // Nummer des Internodiums das aktuell Emission erzeugt
      : integer;
    DiffTM { Jedes WS speichert TM in Gramm, die durch
      das aktuelle WW im Zeitschritt nicht verbraucht
      oder zuviel verbraucht wurde. }
      : double;
    // Hilfsvariablen für Wurzelwachstum
    { Wahrschl. Variable, die zufällige Auswahl aus den vorhandenen Internodien
      speichert, die alle eine gleiche Wahrscheinlichkeit haben. Im ausgewählten
      Internodium findet dann Emission statt, vgl. Methode calcNumPredict }
    // NumEPredict,
    NumPrim: integer;
    procedure makeSegListTotalRekurs(ASegment: TSegment);
    procedure makeSegListTotalDisp(ASegment: TSegment);
    function makePotSegList(ASegment: TSegment): double;
    procedure joinSegments(var ASegment: TSegment);
    procedure joinSegmentsRecursive(var ASegment: TSegment;
      var AcompSeg: TSegment);
    procedure writeMerisInfo(ASegmentWithMeris: TSegment);
  public
    // Anzahl von Achsen in den EO eines WS
    numbAxisPW, numbAxisSWEO1, numbAxisSWEO2, numbAxisSWEO3: integer;
    constructor create;
    procedure init(NumberSegProd_, NumberMeris_, NumCurrentEmission_: integer;
      AnglesInt_: Array of double);
    procedure assign(Source: TPersistent); override;
    // procedure assignChildsRekurs(AElder, AChild, AChildToCopy: TSegment);
    destructor destroy; override;
    procedure clearSegListTotal;
    function getSeetPosX: double;
    function getSeetPosY: double;
    procedure setRandomArr(index: integer; value: double);
  protected

  published
  end;

  TSubmodRootStrucNew = class(TSubmodel)
  private
    // Dummy-Segmente für die allg. Verwendung
    ADummySeg, ADummyForPseudoSeg: TSegment;
    ContainerCenter: r2;
    { Vorbereitung zu einer Simulation des Einflusses der Umgebung. Arrays werden
      im folgenden nicht gefüllt. Möglw. sind M: Mittelwerte }
    { Möglicherweise Temperaturen in versch. Tiefen. In Hume wird das vom Weather-
      File erledigt. }
    // M_TSol: array[0..MaxTime-1,0..NumberHORMAX-1] of double;
    // M_DensSol: array[0..NumberHORMAX-1] of double;   // Möglw. Lagerungsdichte
    // M_HumSol: array[0..NumberHORMAX-1] of double;    // Möglw. Bodenfeuchte
    NumberTotalEmission, { Anzahl der Emissionen in allen WS = Summe der
      Primärwurzeln }
    NumEPredict, // Internodium, in dem Emission stattfinden wird.
    // Zeit in Tagen nach Startzeit
    SimTime,
    { Anzahl der im Weltwürfel produzierten Meristeme, produzierte Meristeme im
      DummyGrowth werden nicht berücksichtigt }
    numbMeris: integer;
    // Simulationszeit [d], Zeit nach Simulationsstart/Aussaat
    // Variable merkt sich, ob Modell neu gestartet wird. wahrschl. jetzt unnötig
    newStart: boolean;
    // Array mit Schichtdicken der einzelnen Segmente
    GaugeArr: array of double;
    { Array für Berechnung der aufsummierten WLD-Daten in einer Schicht, jeder Ein-
      trag steht für eine Rasterzelle. }
    arrAggrRootArrayLayer: zweiDArr_type;
    // TStateArray geht nicht unter published, da es dann Klasse sein müsste
    WLDArr, { Wurzellängendichten für jede Schicht
      Da Kommunikation mit SoilWaterModelR besteht (Externe V.
      müssen sie als effWLD_Schicht-Nr benannt werden. Es wird
      aber angenommen, dass die Wurzel über die gesamte Existenz
      aktiv bei Wasseraufnahme beteiligt ist, ausserdem über die
      gesamte Länge der Wurzel. }
    WLStateArray // Wurzellängen für jede Schicht
      : TStateArray;
    VCNumbVarArrray, PercentCellsArray
    // Prozentualer Anteil mit Wurzeln besetzter Zellen in Schicht
      : TVarArray;
    Par_EmissArr // Emissionsparameter für alle Internodien
      : TParArray;
    Par_OrigPrArr { Parameterwerte für den Radius des Ringsystems an einem
      //Internodium und für die Tiefe, in dem dieses Ringsystem
      //angelegt wird. }
      : TParArray2D;

    SoilTempArray: TExtArray;
    { Arrays und Var. aus Performancegründen angelegt,da sonst ständig auf auf das Wheaterfile
      zugegriffen werden muss. wahrschl. unötig }
    { Tempakt,
      RootDMdtakt:double;
      SoilTempArr: array of double; }
    // Art der Ebene für Schnittpunktserzeugungen
    plane: kindPlane;
    // Vektorbeschreibung der aktuellen Ebene
    aktplane: planeVector;
    depthplane: double; // Tiefe der Ebene [cm]
    // Structurmodell hat eine Liste mit Wurzelsystemen
    RSList: TList;
    // und eine Kopie
    RSListCopy: TList;
    { Submodell hat eine Liste mit Wurzelaustrittspunkten + zugehörige Einzugs-
      gebiete (Voronoi-Polygone)=Einzelwurzelpolygon SRP }
    SRPList, SRPLightList // abgespeckte Version
      : TList;
    { Submodell hat eine Liste mit Segmenten (Zeigern auf Segmente), die eine
      vorher festgelegte Ebene schneiden, Entspricht also einer Filterung der gesam-
      ten SegmentListe und sollte nur für Lesezugriffe verwendet werden }
    SegListIntersect: TList;
    PseudoSegListIntersect: TList;
    { Member und Methoden zur Berechnungen der Schnittpunkte }
    gridWidth_: double;
    // Submodell hat eine Liste mit allen Segmenten aller WS.
    SegListWS: TList;
    { Submodell hat eine Liste mit den potentiellen Verzweigungspunkten, die sich noch
      nicht realisiert haben. Enthält jeweils Einzellisten für jedes WS. }
    PotSegListTot: TList;
    { Submodell hat eine Liste mit den Verzweigungsdichten sämtlicher emittierter
      Wurzelachsen (Primärwurzeln) }
    BranchDensPrimRoots: TList;
    // Lokalisation des 'Schichtbeginns' in Relation zum Ursprung
    posRelOrigin: double;
    { für Gleichungssystem mit drei Gleichungen und 3 Unbekannten kann die Regel von
      Sarrus angewandt werden. Es werden dabei Determinanten berechnet.  Notwendig ist
      dafür eine erweiterte (3 Zeilen x 5 Spalten)  Matrix, vgl.Scholl,Drews S. 712 ff. }
    matrix: array [0 .. 4, 0 .. 2] of double;

    Par_Duration: integer; // Gesamtdauer der Simulation
    Par_Emiss: r2; // ?????????????????ß
    Par_NumberPrE: array [0 .. NumberINTMAX - 1] of integer;
    // Array mit Feldern für jedes Internodium
    { Mittelwert des Winkels (Insertionswinkel ???). }
    Par_AngIAver: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    { möglw. Standardabweichung des Winkels (Insertionswinkel ???). }
    Par_AngIDeviat: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    Par_NumberGen: array [0 .. NumberORDMAX, 0 .. NumberINTMAX] of integer;
    Par_DurDevPrim: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    { möglw. Wachstumsmittelwert }
    Par_GrowthAver: array [0 .. 2, 0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    Par_GrowthDeviat: array [0 .. 2, 0 .. NumberORDMAX - 1,
      0 .. NumberINTMAX - 1] of double;
    { möglw. Verzweigungsmittelwert }
    Par_RamifAver: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    Par_RamifDeviat: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    { möglw. Geotropismusfaktor (definiert gemäß der Lokalisierung, der
      Entwicklungsordnung und dem Internodium. vgl. Endnote Label 11, S.611 }
    Par_Geo: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1] of double;
    { möglw. Faktor für den mechanischen Wiederstand (definiert gemäß der Lokalisierung, der
      Entwicklungsordnung und dem Internodium.), vgl. Endnote Label 11, S.611 }
    Par_CMechanic: array [0 .. NumberORDMAX - 1, 0 .. NumberINTMAX - 1]
      of double;
    { Variablen für Raten von TM und WL eines WS (da aus ExternV berechnet und
      da TVar keine C-Member besitzen als normale Variablen deklariert) }
    potTM_RSdt, // Pot. Trockenmasse eines WS im Zeitschritt
    aktTM_RSdt, // Akt. Trockenmasse eines WS im Zeitschritt
    potWL_RSdt, // Pot. Wurzellänge eines WS im Zeitschritt
    aktWL_RSdt // Akt. Wurzellänge eines WS im Zeitschritt
      : double;
    // Für Voronoi

    PaintList: TList; // PunktListe für Ausgabe in PaintBox.
    fCheckBoxVor, fCheckBoxTriang: TCheckBox;
    fPaintBox: TMyPaintBox;
    fForm: TFormMod;
    function transfFloatToInteger(x, y: double): TPoint;
    // Methoden Wachstum Wurzelsystem
    procedure main(argc: integer; argv: char);
    procedure RS_Growth;
    // Vorläufiges WW zur Abschätzung des Reduktionsfaktors für WW.
    procedure RS_DummyGrowth;
    procedure calcRedFWW;

    (* ------------------------------------------------------------------------------
      Methoden des Pages-Modells
      ------------------------------------------------------------------------------ *)
    procedure Emission(internode_, NumPrim: integer;
      var ARootSystem: TRootsystem);
    procedure Growth(ASegment: TSegment);
    procedure RamificationRec(AFather: TSegment; PrimRootID: integer;
      var ARootsystem_: TRootsystem);
    procedure growthAndRamifRec(ASegment: TSegment; PrimRootID: integer;
      var ARootsystem_: TRootsystem);
    procedure delMerisNonActiv(ASegment: TSegment);
    // Hilfsmethoden Pages
    function CalcElongation(AMeristem: TMeristem): double;
    Procedure OriginOfRamif(FatherMeris: TMeristem; var OriginChild: r3);
    procedure OriginOfEmission(Internode, NumPrim: integer; var Coord: r3;
      ARootSystem: TRootsystem);
    procedure OrientationOfEmission(internode_, NumPrim: integer; DirEmiss: r3;
      ARootSystem: TRootsystem);
    procedure OrientationOfRamif(FatherMeristem: TMeristem; DirChild: r3);
    function CalcNumEPredict(TempSum: double): integer;
    function calcTempSumSoil(TimeStep: integer; depth: double): double;
    function calcTempSumAir(Time: integer): double;
    procedure CalcDirGrowth(Meris: TMeristem; var NewDir: r3;
      var Elongation: double);
    procedure DeflecMechanic(Meris: TMeristem; var DirAfterMeca: r3;
      var Elongation: double);
    procedure DeflecGeo(Meris: TMeristem; var DirAfterMeca, DirAfterGeo: r3;
      var Elongation: double);
    procedure DrawPRamif(var Meris: TMeristem; var PRamif: single);
    procedure DrawPCroiss(var Meris: TMeristem; var PCroiss: r2);
    procedure DrawPCroissMod(var Meris: TMeristem; var PCroiss: r2);
    function DrawAngIPrim(Internode: integer): double;
    function DrawAngI(FatherMeris: TMeristem): double;
    function DrawAngGen(FatherMeris: TMeristem): double;
    procedure RotZ(u: r3; var v: r3; angle: double);
    procedure RotVect(omega: double; u, x: r3; var rot_x: r3);
    procedure Norm(var u, un: r3);
    procedure ProdVect(var u, v, u_vect_v: r3);
    function FRandUnif: double;
    function IRandUnif(imax: integer): double;
    function ProdScal(u, v: r3): double;
    function calcTempDepthPorter(depth: double): double;
    function calcImpedFact(TempSoil: double): double;
    // Methoden für Modellierung eines Wachstums im Container
    function ContainerGrowth2D(var ASegment: TSegment; GrowthDir: r3): r2;
    function testBeyondContainer(var ASegment: TSegment; GrowthDir: r3)
      : boolean;
    (* ------------------------------------------------------------------------------
      Methoden des Pages-Modells Ende
      ------------------------------------------------------------------------------ *)
    // Hilfsmethoden Schnittpunktsberechnung
    procedure createPlane(depth: double);
    procedure calcIntersect; overload;
    procedure calcIntersect(ASegment_: TSegment); overload;
    { Berechnen von Schnittpunkte auf VERTIKALER Querschnittsebene aufgrund der
      berechneten Einzelreihensituation. }
    procedure singleRowToCrop;
    { Berechnen von Schnittpunkten einer ER auf HORIZONTALER Querschnittsebene aufgrund der
      berechneten Einzelreihensituation. }
    procedure extendToCrop;
    procedure extendToSinglerowLow;
    { Lösung Gleichungssystem (= Berechnung der Durchstoßpunkte mit Methoden der
      linearen Algebra }
    function solveEquationSystem(ASegment_: TSegment; orientation: kindPlane)
      : r2; overload;
    function solveEquationSystem(ASegment_: TSegment; aktPlane_: planeVector;
      orientation: kindPlane): r3; overload;
    function solveEquationSystemTang(ASegment_: TSegment;
      aktPlane_: planeVector): r3;
    { Funktion für die Subtraktion von Vektoren im R3 }
    function vectorSubtrakt(vector_a, vector_b: r3): r3;
    { Berechnung der dreireihigen Derterminante mit der Regel von Sarrus: }
    function calcDeter: double;
    function calcAbsValue(ASegment_: TSegment): double;
    // function calcAbsValue(co,ce: r3):double; overload;
    // Berechnung aggr. Daten
    procedure calcDeepestInterscection(y: double);
    procedure findDeepestPointRekursive(var ASegmentToCompare: TSegment;
      var depth: double);
    procedure calcRootDataWorldCube;
    procedure calcWL_Layer;
    procedure calcWLD;
    { Berechnung abgeleiteter Variablen, Längen bezogen auf Entwicklungsord., Verzwei
      gungszonen etc. }
    procedure calcDerivedData;
    procedure calcMeanStdDevAxis(ARootsystem_: TRootsystem);
    function calcStdDev(TotLength, SumQuad: extended; Number: integer): double;
    procedure calcBranchDens;
    // Schreiben von aggregierten Wurzeldaten in eine Datei
    procedure writeAggregatedData;
    procedure writeIntersectList;
    { Prozedur berechnet die Wurzellängendichte und den Variationskoeffizienten unter
      Verwendung von Anzahlen von Wurzeln in einem vorgegebenen Grid. Dabei kann eine
      bestimmte Tiefe vorgeg. werden }
    procedure calcWLD_VK_AggregData(var RLD_: TState; var VC_: TState;
      posRelOrigin_: double); overload;
    { Prozedur berechnet die Wurzellängendichte und den Variationskoeffizienten unter
      Verwendung von Anzahlen von Wurzeln in einem vorgegebenen Grid. Dabei kann eine
      bestimmte Tiefe vorgeg. werden }
    procedure calcWLD_VK_AggregData; overload;
    procedure updSRPList(ASegment_: TSegment; completeOut: boolean);
    function calcVK(StartIndex, LayerWidth: integer; arrAggrRoot: zweiDArr_type;
      RLDList: TList): double;
    function calcVK_withArr(StartIndex, LayerWidth: integer;
      arrAggrRoot: zweiDArr_type): double;
    { Berechnet Variationskoeffizienten der mittleren Anzahlen (gleitendes Mittel)
      für jede Spalte innerhalb einer Schicht }
    procedure calcVKNumb;
    function testForGridMember(topLeft_, bottomRight_: TPoint;
      x, y: double): boolean;

    // Hilfsmethoden für Berechnung von Wurzellängen in Schichten
    function cutSegment(ASegmentAxis_: TSegment): TSegment;
    procedure dissaggrSegmentTopDown(ASegment_: TSegment; lengthASeg: double;
      currLay: integer);
    procedure dissaggrSegmentBottomTop(ASegment_: TSegment; lengthASeg: double;
      currLay: integer);

    function createHorizontPlane(depth_: double): planeVector;
    function createVertikalPlane(depth_: double): planeVector;
    function createSaggitalPlane(depth_: double): planeVector;
    function createTangentPlan(TouchPoint, normVekt: r2): planeVector;

    { Hilfsmethoden }
    procedure assignParameter;
    procedure fillIntersectList;
    procedure findIntersectRekursive(ASegment: TSegment);
    procedure findIntersectFromPseudoseg;
    function testForIntersect(ASegment: TSegment): boolean;
    procedure deleteMultipleItems(SegList: TList);
    procedure drawSegmentPart(co, ce: r3; Internode: byte);
    // Aufräumen
    // Zurücksetzen einzelner Listen und Arrays und Dateien
    procedure resetSMLists;
    procedure destroySegmentsRekurs(ASegmentToDestroy: TSegment);
    procedure clearRSListCopy;
    procedure clearChildListsRekurs(ASegment: TSegment);
    procedure destroySRPListContent;
    procedure clearSMLists;
    procedure resetWLStateArray;
    procedure resetFiles;
    procedure resetDerivedData;
    procedure resetWLD_VK;
    procedure writeSegInfo;
    procedure writeSegInfoRekursive(AFather: TSegment);
    procedure writeRamiInfo(AFather: TSegment);

  public
    constructor create(aowner: TComponent); override;
    procedure createAll; override;
    procedure init(var GlobModReferenz: TMod); override;
    procedure AddDataValueToDataSeries; override;
    procedure CalcRates; override;
    procedure integrate; override;
    procedure copyRootSystems;
    procedure destroyRootSystems(RSList: TList);
    procedure destroyARootSystem(var ARootSystemToDestroy: TRootsystem);
    // Set und get
    // Schnittstellenvariante 1 für Kommunikation mit 2D-Diffmodell
    function getSRPList: TList;
  protected

  published
    { Published-Deklarationen }
    // Hume-Variablen

    // Zustandsvariablen

    mRLD, { mittlere Wurzellängendichte [cm/cm3] }
    VC, { Variationskoeffizient [%], nur angelegt (für
      die Berechnung wird Implementierung der Berechnung
      von Voronoi-Polygonen benötigt. }
    { Kennzahlen für 10 Schichten mit 1o cm Mächtigkeit (aus Gründen der Übersichtlichkeit
      wurde kein TStateArray verwendet }
    RLD_1, RLD_2, RLD_3, RLD_4, RLD_5, RLD_6, RLD_7, RLD_8, RLD_9, RLD_10, VC_1,
      VC_2, VC_3, VC_4, VC_5, VC_6, VC_7, VC_8, VC_9, VC_10, depth,
    { Durchwurzelungstiefe [cm] }
    DeepestIntersection, { Tiefster Schnittpunkt auf der Querschnittsebene }
    numbRoots, { Anzahl Wurzeln in der Schnttebene [-], Für die
      Berechnung von NumbRoots werden nur Schnittpunkte
      berücksichtigt, die sich in der Querschnittsebene
      befinden. }
    WL_0_30, { WL in Tiefe von 0-30 cm }
    WL_30_60, { WL in Tiefe von 30-60 cm }
    WL_60_90, { WL in Tiefe von 60-90 cm }
    WL_30_100, { WL in Tiefe von 30-100 cm }
    BranchDens, { Mittelwert der Verzweigungdichte cm^-1 }
    BranchDensStDev, { Standardabweichung der Verzweigungsdichte cm^-1,
      wird derzeit nicht berechnet, da die Verzweigungs-
      längen und die Anzahlen der Segmente derzeit für
      alle existierenden Primärwurzeln und nicht für die
      einzelnen Primärw. ermittelt werden. }
    // Für Berechnung der Verzweigungsdichte
    ZahlSegPW, { Anzahl der Segmente in den Primärwurzel im WW }
    ZahlSegE1, { Anzahl der Segmente in SW 1. Ordnung im WW }
    ZahlSegE2, { Anzahl der Segmente in SW 2. Ordnung im WW }
    ZahlSegE3 { Anzahl der Segmente in SW 3. Ordnung im WW }
      : TState;

    // Variablen
    numberEmission, { Anzahl der Emission = Primärwurzeln im Weltwürfel. }
    EmissPerPlant, { Anzahl Emissione pro Pflanze }
    numberRootSeg, { Anzahl Wurzelsegmente im Weltwürfel }
    SumWL, { Gesamtwurzellänge aller Segmente [cm] aller
      Wurzelsysteme }
    { Folgendes beiden Variablen vor allem deswegen implementiert, damit die Funktionen
      zur Berechnung der Zustandsvariablen kontrolliert werden können. }
    MeanSegLenWC, { mittlere Segmentlänge im Weltwürfel }
    StdDevSegLenWC, { StdDev Segmentlänge im Weltwürfel }
    RootDM, { TM Wurzeln im Weltwürfel [g] }
    RootDMWSdt, { Baustoff für 1 WS im Zeitschritt }

    numberPlants, // Anzahl von Pflanzen auf m^2
    Red_WL, // Reduktionsfaktor für Wurzellängenwachstum [-]
    TempSumAir,
    { Aggregierte Variablen (benötigt vor allem für Nährlösungsversuch) }
    { Mittelwerte werden berechnet aus allen Wurzeln (eines oder mehrerer WS)
      aber jeweils bezogen auf ein WS }
    // Gesamt-WL in den Ordnungen
    SumWL_PW, { Gesamtwurzellänge in Primärw. }
    SumWL_E1, { Gesamtwurzellänge in Seitenw. 1. Ordnung }
    SumWL_E2, { Gesamtwurzellänge in Seitenw. 2. Ordnung }
    SumWL_E3, { Gesamtwurzellänge in Seitenw. 3. Ordnung }
    TotSLVZPW, { Gesamtwurzellänge in VZ in PW }
    TotSLVZE1, { Gesamtwurzellänge in VZ in Seitenw. 1. Ordnung }
    TotSLVZE2, { Gesamtwurzellänge in VZ in Seitenw. 2. Ordnung }
    TotSLVZE3, { Gesamtwurzellänge in VZ in Seitenw. 2. Ordnung }

    MeanSLVZPW, { Durchschn. Segmentlänge in Primärw.
      Segmente d. Verzweigungszone }
    MeanSLVZE1, { Durchschn. Segmentlänge in Seitenw. 1. Ordnung
      Segmente d. Verzweigungszone }
    MeanSLVZE2, { Durchschn. Segmentlänge in Seitenw. 2. Ordnung
      Segmente d. Verzweigungszone }
    MeanSLVZE3, { Durchschn. Segmentlänge in Seitenw. 2. Ordnung
      Segmente d. Verzweigungszone }
    StdDSLVZPW, { Standardabw. Segmentlänge in Primärw.
      Segmente d. Verzweigungszone }
    StdDSLVZE1, { Durchschn. Segmentlänge in Seitenw. 1. Ordnung
      Segmente d. Verzweigungszone }
    StdDSLVZE2, { Durchschn. Segmentlänge in Seitenw. 2. Ordnung
      Segmente d. Verzweigungszone }
    StdDSLVZE3, { Durchschn. Segmentlänge in Seitenw. 2. Ordnung
      Segmente d. Verzweigungszone }
    { Nichtverzweigungszonen: Bei den Seitenwurzeln wird nur die apikale Nicht-
      Verzweigungszone berechnet.
      Gründe:
      - Es gibt keinen Zeiger auf das Vater-Segment
      - Berechnung der basalen Nicht-Verzweigungszone für Seitenwurzeln macht wenig
      Sinn.
      - Da bei apikalen und basalen Nichtverzweigungszonen pro Achse genau ein Segment
      auftaucht, entspricht die Berechnung sowohl der mittleren Segmentlänge als auch
      dem Mittelwert bezogen auf die Anzahl gebildeter Achsen. }
    // Gesamtlängen bez. auf WW (bei Modus SinglePlant auf ein W-System)
    TotNZ_PW, { Gesamtwurzellänge sich nicht verzw. Wurzeln in PW }
    TotApNBZ_PW, { Gesamtlänge apikale Nicht-Verzw. zone in Prim-W. }
    TotApNBZ_E1, { Gesamtlänge apikale Nicht-Verzw. zone in EO 1 }
    TotApNBZ_E2, { Gesamtlänge apikale Nicht-Verzw. zone in EO 2 }
    TotApNBZ_E3, { Gesamtlänge apikale Nicht-Verzw. zone in EO 3 }
    TotBasNBZ_PW, { Gesamtlänge basale Nicht-Verzw. zone in Prim-W. }
    MeanNZ_PW, { Durchschn. Segmentlänge in Primärw.
      Segmente, die sich nicht verzweigen }
    MeanApNBZ_PW, { MW Apikale Nicht-Verzweigungszone in Primärw. }
    MeanBasNBZ_PW, { MW Basale Nicht-Verzweigungszone in Primärw. }
    MeanBZ_PW, { MW Verzweigungszone in Primärw. bezogen auf
      Achsen }
    StdNZ_PW, { StdDev von Segmenten/Primärwurzeln, die sich
      (noch) nicht verzweigt haben. }
    StdApNBZ_PW, { StdDev Apikale Nicht-Verzweigungszone in Primärw. }
    StdBasNBZ_PW, { StdDev Basale Nicht-Verzweigungszone in Primärw. }

    MeanApNBZ_E1, { MW Apikale Nicht-Verzweigungszone in SW 1. Ord. }
    StdApNBZ_E1, { StdDev Apikale Nicht-Verzweigungszone in SW 1. Ord. }

    MeanApNBZ_E2, { MW Apikale Nicht-Verzweigungszone in SW 2. Ord. }
    StdApNBZ_E2, { StdDev Apikale Nicht-Verzweigungszone in SW 2. Ord. }

    MeanApNBZ_E3, { MW Apikale Nicht-Verzweigungszone in SW 3. Ord. }
    StdApNBZ_E3, { StdDev Apikale Nicht-Verzweigungszone in SW 3. Ord. }
    { MeanBZ_E1 ,                // MW Verzweigungszone in SW 1. Ord.
      MeanBZ_E2,                 // MW Verzweigungszone in SW 2. Ord.
      StdBZ_PW,
      StdBZ_E1,
      StdBZ_E2
      Mittelwert und StdDev der Länge der Verzweigungszone
      (bezogen auf Achse und Entwicklungsord.
      Mit derzeitiger Implementierung nicht
      möglich, da dann die Länge der Verzweigungszone
      für die einzelnen Wurzeln (als Summe aller Segmente
      dieser Zone, die zu einer Axis gehören)
      eines jeden WS bestimmt werden müssten. }
    // Achsenbezogene Werte (nur aus dem 1. WS berechnet) für Kalib NL-V
    MeanAxisPW, { Mittlere Achsenlänge in der PW [cm] }
    VCAxisPW, { Variationskoeff. Achsenlänge in der PW [cm] }
    MeanAxisE1, { Mittlere Achsenlänge in der SW 1.Ord [cm] }
    VCAxisE1, { Variationskoeff Achsenlänge in der SW 1.Ord [cm] }
    MeanAxisE2, { Mittlere Achsenlänge in der SW 2.Ord [cm] }
    VCAxisE2, { Variationskoeff Achsenlänge in der SW 2.Ord [cm] }
    MeanAxisE3, { Mittlere Achsenlänge in der SW 3.Ord [cm] }
    VCAxisE3 { Variationskoeff Achsenlänge in der SW 3.Ord [cm] }
      : TVar;
    // Parameter
    sowingDate, { ExcelDatum Aussaat }
    contRad, { Containerradius [cm] }
    NumCompToCalc, // Anzahl zu berechnender Schichten
    border1stLayer, // Unter Grenze der ersten Bodenschicht [cm]
    DimX, // Ausdehnung Weltwürfel in X-Richtung
    DimY, // Ausdehnung Weltwürfel in Y-Richtung
    DimZ, // Ausdehnung Weltwürfel in Y-Richtung
    RowSpace, // Reihenabstand [cm]
    SpaceWithinRows, // Abstand Pflanzen in der Reihe [cm]
    PosXPlant, // Aussaatpunkt 1. Pfla. X-Koordinate [cm]
    PosYPlant, // Aussaatpunkt 1. Pfla. Y-Koordinate [cm]
    SowingDepth, // Aussaattiefe Pflanzen[cm]
    { Skalierungsfaktor für Skalierung verschiedener für EO spezifischer Parameter,
      erlauben das gleichmäßige Skalieren für sämtliche EO }
    a_scaling, { Skalierungsfaktor für Skalierung des Wachstums-
      parameter a (entspricht max. Länge im monomoleku-
      laren Wachstum) in der von Pages für das Segmentwachs-
      tum verwendeten Gleichung, erlaubt gleichmäßige
      Skalierung für sämtliche EO (derzeit nur für Seiten-
      wurzeln, da Wachstumsparameter der PW anhand der
      Tiefe kalibriert werden). }
    b_scaling, { Skalierungsfaktor für Skalierung des Wachstums-
      parameter b in der von Pages für das Segmentwachs-
      tum verwendeten Gleichung, erlaubt gleichmäßige
      Skalierung für sämtliche EO (derzeit nur für Seiten-
      wurzeln, da Wachstumsparameter der PW anhand der
      Tiefe kalibriert werden). }
    ram_scaling, { Skalierungsfaktor für Verzweigungsparameter }
    geo_scaling, { Skalierungsfaktor für Geotropismus-Koeffizient }
    mech_scaling, { Skalierungsfaktor für mech. Widerstand }
    Add_Prim, { Addition zur Entwicklungsdauer für das Primordium }
    AddNumb_Gen, { Addition zum Parameter Par_numberGen }
    { Für jede Entwicklungsordnung werden eigene Parameter angelegt }
    { F. zwei Parameter bestimmen, welches Internodium Wurzeln erzeugt. }
    Par_begin, // Ursprünglicher Parameter Ordonnee (????)
    Par_disposition, // Ursprünglicher Parameter pente (????)
    // Cave: im Quelltext wird ord ab 0 gezählt
    // Entwicklungsordnung 1 (Primärwurzel)
    Par_AP_NBZ_Ord1, // Par für apikale Nichtverzweigungszone in PW
    Par_Bas_NBZ_Ord1, // Par für basale Nichtverzweigungszone in PW
    Par_numberGen_Ord1, Par_AverAngleInsert_Ord1, // Mittelwert Insertionswinkel
    Par_StdDevAngleInsert_Ord1, // Standardabweichung Insertionswinkel
    Par_developPrim_Ord1, // Entwicklungsdauer des Primordiums [°Cd]
    Par_AverGrowthA_Ord1, // Mittelwert Wachstumsparameter A
    Par_AverGrowthB_Ord1, // Mittelwert Wachstumsparameter A
    Par_StdDevGrowthA_Ord1, // Standardabweichung Wachstumsparameter A
    Par_StdDevGrowthB_Ord1, // Standardabweichung Wachstumsparameter A
    Par_ConstRatePW, // Parameter für konstante Wachstumsrate in PW
    Par_StdDevRamific_Ord1, // Standardabweichung Verzweigungsparameter
    Par_Coeff_Geo_Ord1, // Geotropismuskoeffizient
    Par_mechResist_Ord1, // Parameter des mechanischen Widerstands
    Par_AverRamific_Ord1, // Mittelwert Verzweigungsparameter

    // Entwicklungsordnung 2 (SW 1. Ordnung)
    Par_AP_NBZ_Ord2, Par_Bas_NBZ_Ord2, Par_numberGen_Ord2,
      Par_AverAngleInsert_Ord2, // Mittelwert Insertionswinkel
    Par_StdDevAngleInsert_Ord2, // Standardabweichung Insertionswinkel
    Par_developPrim_Ord2, // Entwicklungsdauer des Primordiums [°Cd]
    Par_AverGrowthA_Ord2, // Mittelwert Wachstumsparameter A
    Par_AverGrowthADist_Ord2, { Mittelwert Wachstumsparameter A
      wird verwendet bei sehr langen Entfernungen von
      der Basis }
    Par_AverGrowthB_Ord2, // Mittelwert Wachstumsparameter A
    Par_StdDevGrowthA_Ord2, // Standardabweichung Wachstumsparameter A
    Par_StdDevGrowthADist_Ord2, { Mittelwert Wachstumsparameter A
      wird verwendet bei sehr langen Entfernungen von
      der Basis }
    Par_StdDevGrowthB_Ord2, // Standardabweichung Wachstumsparameter A
    Par_AverRamific_Ord2, // Mittelwert Verzweigungsparameter
    Par_StdDevRamific_Ord2, // Standardabweichung Verzweigungsparameter
    Par_Coeff_Geo_Ord2, // Geotropismuskoeffizient
    Par_mechResist_Ord2, // Parameter des mechanischen Widerstands

    // Entwicklungsordnung 3 (SW 2. Ordnung)
    Par_AP_NBZ_Ord3, Par_Bas_NBZ_Ord3, Par_numberGen_Ord3,
      Par_AverAngleInsert_Ord3, // Mittelwert Insertionswinkel
    Par_StdDevAngleInsert_Ord3, // Standardabweichung Insertionswinkel
    Par_developPrim_Ord3, // Entwicklungsdauer des Primordiums [°Cd]
    Par_AverGrowthA_Ord3, // Mittelwert Wachstumsparameter A
    Par_AverGrowthB_Ord3, // Mittelwert Wachstumsparameter A
    Par_StdDevGrowthA_Ord3, // Standardabweichung Wachstumsparameter A
    Par_StdDevGrowthB_Ord3, // Standardabweichung Wachstumsparameter A
    Par_AverRamific_Ord3, // Mittelwert Verzweigungsparameter
    Par_StdDevRamific_Ord3, // Standardabweichung Verzweigungsparameter
    Par_Coeff_Geo_Ord3, // Geotropismuskoeffizient
    Par_mechResist_Ord3, // Parameter des mechanischen Widerstands

    // Entwicklungsordnung 4 (SW 3. Ordnung)
    Par_AP_NBZ_Ord4, Par_Bas_NBZ_Ord4, Par_numberGen_Ord4,
      Par_AverAngleInsert_Ord4, Par_StdDevAngleInsert_Ord4,
      Par_developPrim_Ord4, Par_AverGrowthA_Ord4, Par_AverGrowthB_Ord4,
      Par_StdDevGrowthA_Ord4, Par_StdDevGrowthB_Ord4, Par_AverRamific_Ord4,
      Par_StdDevRamific_Ord4, Par_Coeff_Geo_Ord4, Par_mechResist_Ord4,

    { -------------------------------------------------------------------------------
      Allg gültige Konstanten aus Quelltext, die in Parameter überführt wurden
      ------------------------------------------------------------------------------- }
    // Geotrop
    GeoMod, { Par. für Skalierung des Geotropismus-Koeffizienten
      in den obersten cm }
    GeoModRange, { Par. legt fest, bis zu welcher Tiefe Par. GeoMod
      wirksam ist. }
    DepthSubsoil, { Tiefe Pflugsohle [cm] }

    // Konst. bez. Elong A in SW 1. Ord
    ThresDistBase, { Schwellenwert, ab dem Elongationsparameter A
      der W-Segmente SW erster Ordnung alternativ
      Berechnet werden sollen. }
    ElongAStartAv_Ord2, { Startwert des Elongpar A (Mittelwert),
      der UNTERHALB des Schwellenwerts für Segmente
      SW 1. Ord verwendet werden soll. }
    ElongAStartDev_Ord2, { Startwert des Elongpar A (Standardabw.),
      der UNTERHALB des Schwellenwerts für Segmente
      SW 1. Ord verwendet werden soll. }

    // Allg. Mod des Ramifikationsparameters
    Thres_RamMod, { Legt den Schwellenwert des Elongationsparameters
      A fest, ab dem ein fest vorgegebener Verzweigungs-
      parameter verwendet werden soll. }
    Par_RamMod_Gener, { Allgemeiner Ramifikationsparameter, der bei Über-
      schreiten eines best. Wertes von Thres_RamMod ver
      wendet werden soll. }
    // Ramifikationsparameter PW
    // a: für seminales WS
    Par_RamMod_Asem, { Parameter A (Skalierung)
      für negative Expon-Gl. Berechnung
      des Ramifikationsparameters in Abhängigkeit
      des Abstandes des Meristems von der Basis }
    Par_RamMod_Bsem, { Parameter B (im Exponenten)
      für negative Expon-Gl. Berechnung
      des Ramifikationsparameters in Abhängigkeit
      des Abstandes des Meristems von der Basis }
    // b: für Kronwurzeln
    Par_RamMod_Acr, Par_RamMod_Bcr,
    { -------------------------------------------------------------------------------
      Allg gültige Konstanten aus Quelltext, die in Parameter überführt wurden - Ende
      ------------------------------------------------------------------------------- }
    dl_RedFWL, { Schrittweite mit der Reduktionsfaktor
      angepasst werden soll [%] }
    Threshold_DMRoot, { Schwellenwert ab dem die potentiell verbrauchte
      TM der aktuell gelieferten TM als gleichwertig an-
      gesehen wird }

    SpezRL, // Spezifische Wurzellänge [cm/g]
    avTempYear, { Mittelwert der monatlichen Jahrestemp [°C],
      wird benötigt für Berechnung der Bodentemp. und
      nach Porter, Klepper #79 }
    BaseTemp, { wird benötigt für Berechnung von TempSumAir
      [°C] }
    Tmin, { Minimal- und Maximaltemperatur wird benötigt für
      Berechnung des temperaturabhängigen Impedenzfak-
      tors nach Clausnitzer/Hopmans #218 }
    Tmax, theta_, { Wassergehalt }
    TetaAngl, { Winkel für Berechn. Vektor mech. Widerstand im
      Oberboden (Gradmaß) }
    minDistWall, { Mindestabstand zur containerwand. }
    NumbColVK, { Anzahl der Spalten, die für die Berechnung
      des 'gleitenden Mittelwerts' der Wurzelanzahlen
      in einer Schicht berücksichtigt werden sollen. }

    spezRL_Sand, { Spez. WL für Sandkultur }
    spezRL_NL, { Spez. WL für Nährlösungskultur }
    TransfSand_NL, { Tag, an dem die Wurzeln in die Nährlösungskultur
      überführt wurden }
    ThresholdGrowth, { Schwellenwert für Segmentzuwachs im Zeitschritt,
      beim Unterschreiten wird das Meristem inaktiv. }
    L0_MerisPW, { initiale Länge des Meristems der Primärwurzel,
      notwendig für logistischen und exponent. Wachs-
      tum }
    rgr_expo, { Relative Wachstumsrate }
    LmaxMerisPW, { maximale Länge des Meristems der Primärwurzel,
      notwendig für logistischen Wachstum }
    { Parameter für Begrenzung des Drillens auf einen Ausschnitt des Weltwürfels.
      Wird benötigt für eine rechenzeiteffiziente Implementierung der Einzelreihe
      -> Evtl. könnten auch die Dimensionen des Weltwürfels verändert werden. Da das
      aber evtl. Probleme nach sich zieht, wurde dieses Verfahren gewählt. Verfahren
      macht nur für ER Sinn und auch nur für Berechnung der Modellqualitäten middle
      und high. }
    BordLeftFront, { Begrenzung des Drillens nach vorne }
    BordRightBehind, { Begrenzung des Drillens nach vorne }
    CalibRLD { Kalibrierungsfaktor für Berechnung der
      Wurzellängendichte aus Anzahlen [-] }
      : TPar;
    // Optionen
    { Pfade für verschiedene Einlesemethoden }
    SegFile, IntersectFile, AggrRootData,
    // Schalater
    WriteSegFile, { Legt fest, ob ein Segfile geschrieben werden soll }
    WriteAggrData, { Legt fest, ob aggr. Daten geschrieben werden sollen }
    ContGrowth, { Festlegen, ob Wachstum in einem Container stattfindet }
    mode, { Simulationsmodus des Strukturmodells }
    modelQuality, { Qualität der Berechnung, entspricht Anzahl
      der tatsächlich modellierten Pflanzen }
    Type_DMRoot, gridWidth, { Gridweite für Berechnung aggregierter
      Wurzeldaten [cm] }
    RelocateSowPoints, { Schalter: wenn aktiviert, dann werden die Punkte
      im Modus Crop, die an der X-Achse verteilt werden,
      um einen zufällig gezogenen Wert zwischen 0 und
      dem halben Abstand innerhalb der Reihe verschoben. }
    SoilTempMode, { Art und Weise der Berechnung der Bodentemp. }
    stochasticGrowth, { Schalter, der es erlaubt stochastisches Wachs-l
      tum an oder auszuschalten, ist das stochastische
      Wachstum ausgeschaltet, werden (durch Belegung
      der Variable RandSeed mit 0) immer die gleichen
      Zufallszahlen gezogen. }
    RLDMode, { Erlaubt, die Auswahl, ob die Wurzellängendichten
      in den Schichten ausgehend von den berechneten
      Wurzellängen oder ausgehend von den berechneten
      Schnittpunkten mit vertikaler Querschnittsbene
      berechnet werden sollen. }
    PrecDeriveData, { legt fest, mit welche Präzision aggregierte
      Daten (z.B. mittlere Segmentlänge in den EO)
      berechnet werden soll: low: das 1. WS wird be-
      rücksichtigt, high: alle WS werden berücksichtigt. }
    unlinkRS, { das Submodel kann von den anderen Submodellen
      zur Laufzeitgetrennt werden. }
    enablePotentGrowth, { Schalter, der potentielles Wachstum des WS
      erlaubt. Ermöglicht in bestimmten Fällen das
      bessere Abschätzen der Auswirkungen eines
      Parameters, falls ansonsten die ins WS allozierte
      TM der begrenzende Faktor ist. }
    SRL_input, { erlaubt Lesen der spez. WL vom Wheatherfile,
      falls Werte nicht konstant }
    drawMode, { erlaubt die Zeichnung im Zeitschritt anhand
      des Zuwachs eines wachsenden Segments oder
      anhand der der Koordinaten aus der Segmentliste }
    RandModePRoot, { Schalter: Anlage von Array mit Reihe von
      Zufallszahlen für Wachstumsrichtung des Meristems
      der Primärwurzeln unabhängig vom Ziehen von Zufalls-
      zahlen in anderen Entwicklungsordnungen.
      Option nicht verwirklicht, da ein solches Verfahren
      eigentlich für alle Entwicklungsordnungen angewandt
      werden müsste, um die Zufallszahlen der einzelnen
      Entwicklungsordnungen voneinander zu entkoppeln }
    GrowthRatePW, GrowthRateSW, RamMode,
    { Erlaubt das Umschalten von Konstanter Zwischen-
      verzweigungslänge und einer variablen Festlegung
      der Zwischenverzweigungslänge }
    CVMode, { Schalter legt fest, ob der Variationskoeffizient
      aus den Anzahlen mit Hilfe des gleitenden Mittels
      oder ungeglättet (nur mit den Anzahlen) berechnet
      werden soll. }
    CVConsidCells, { Legt fest, ob zur Berechnung der Variations-
      koeffzizenten alle Zellen in der Schicht oder
      nur die Zellen berücksichtigt werden sollen,
      die Wurzelschnittpunkte enthalten. }
    DrawPCroissLR, { Schalter: Berechnung des Wachstumsparameters A
      nach der originalen Pages-Methode oder ein-
      faches Ziehen aus lognormaler Verteilung bzw.
      Ziehen der Parameterwerte für Seitenwurzeln nach
      dem Verfahren von Anlauf, LR für lateral Roots }
    calcDistrAxis, { Schalter: ob die Verteilungsparameter für die
      Achsenlängen in den jeweiligen EO berechnet wer-
      den sollen. }
    showGrowth { Schalter, ob Wurzelwachstum und Wurzelschnitt-
      punkte angezeigt werden sollen, oder nicht. }
      : TOption;
    // Externe Variablen
    DMRootDT, Temp, // Luftemperatur kann aus Wheaterfile eingelesen werden.
    SRL { Spez. Wurzellängen kommen aus Wheaterfile }
      : TExternV;

    // Properties
    property MyPaintBox: TMyPaintBox read fPaintBox write fPaintBox;
    property MyVorCheck: TCheckBox read fCheckBoxVor write fCheckBoxVor;
    property MyTriangCheck: TCheckBox read fCheckBoxTriang
      write fCheckBoxTriang;
    property MyForm: TFormMod read fForm write fForm;
  end;

procedure Register;
procedure writeSegnumber(Number, numberFather: integer; funktion: string);

implementation

uses
  UFormShowGrowth;

var
  // Strukturmodell bringt sein eigenes Ausgabefenster mit
  FormShowGrowth: TFormShowGrowth;

procedure Register;

begin
  RegisterComponents('MichasMod', [TSubmodRootStrucNew]);
  RegisterComponents('MichasMod', [TMyPaintBox]);
end;

{ TRootsystem }

constructor TRootsystem.create;
begin
  inherited;
  SegListTotal := TList.create;
  SegListEO := TList.create;
  SegListTotalDisp := TList.create;
  PotSegListWS := TList.create;
  NumberPrimaryRoots := 0;
end;

destructor TRootsystem.destroy;
begin
  if SegListTotal <> nil then
  begin
    SegListTotal.clear;
    SegListTotal.Free;
  end;
  if SegListEO <> nil then
  begin
    SegListEO.clear;
    SegListEO.Free;
  end;
  if SegListTotalDisp <> nil then
  begin
    SegListTotalDisp.clear;
    SegListTotalDisp.Free;
  end;
  if PotSegListWS <> nil then
  begin
    PotSegListWS.clear;
    PotSegListWS.Free;
  end;
  inherited destroy;
end;

procedure TRootsystem.assign(Source: TPersistent);
var
  AChild, AChildToCopy, ASegment, ASegmentToCopy: TSegment;
  i, j: integer;
  funktion_: string;
  APotSegToCopy, APotSeg: TPotSeg;
begin
  { Kopieren sämtlicher Member aus der Quelle, Ausnahme: SegListTotal, da diese
    bei Bedarf aus anderen Listen erzeugt wird. }
  funktion_ := 'TRootsystem.assign';
  if Source is TRootsystem then
  begin
    numbAxisPW := TRootsystem(Source).numbAxisPW;
    numbAxisSWEO1 := TRootsystem(Source).numbAxisSWEO1;
    numbAxisSWEO2 := TRootsystem(Source).numbAxisSWEO2;
    numbAxisSWEO3 := TRootsystem(Source).numbAxisSWEO3;
    SeetPosX := TRootsystem(Source).SeetPosX;
    SeetPosY := TRootsystem(Source).SeetPosY;
    aktIndRandArray := TRootsystem(Source).aktIndRandArray;
    ARandArr := TRootsystem(Source).ARandArr;
    for i := 0 to NumberINTMAX - 1 do
    begin
      AnglesInt[i] := TRootsystem(Source).AnglesInt[i];
    end;
    RS_ID := TRootsystem(Source).RS_ID;
    RootLengthdt := TRootsystem(Source).RootLengthdt;
    TotRootLengthWS := TRootsystem(Source).TotRootLengthWS;
    NumberSegProd := TRootsystem(Source).NumberSegProd;
    NumberPrimaryRoots := TRootsystem(Source).NumberPrimaryRoots;
    NumberMerisDest := TRootsystem(Source).NumberMerisDest;
    NumCurrentEmission := TRootsystem(Source).NumCurrentEmission;
    DiffTM := TRootsystem(Source).DiffTM;
    NumPrim := TRootsystem(Source).NumPrim;
    if TRootsystem(Source).PotSegListWS <> nil then
    begin
      for i := 0 to TRootsystem(Source).PotSegListWS.Count - 1 do
      begin
        APotSegToCopy := TRootsystem(Source).PotSegListWS.Items[i];
        APotSeg := TPotSeg.create;
        APotSeg.co[0] := APotSegToCopy.co[0];
        APotSeg.co[1] := APotSegToCopy.co[1];
        APotSeg.co[2] := APotSegToCopy.co[2];
        APotSeg.ce[0] := APotSegToCopy.ce[0];
        APotSeg.ce[1] := APotSegToCopy.ce[1];
        APotSeg.ce[2] := APotSegToCopy.ce[2];
        PotSegListWS.Add(APotSeg);
      end;
    end;
    if TRootsystem(Source).SegListEO <> nil then
    begin
      for i := 0 to TRootsystem(Source).SegListEO.Count - 1 do
      begin
        ASegmentToCopy := TRootsystem(Source).SegListEO.Items[i];
        ASegment := TSegment.create;
        { Folgende zwei Zeilen wurden nur für Debugging-Zwecke verwendet, um festzustellen, ob der Ko-
          piervorgang funktiniert }
        // inc(NummerSeg);
        // ASegment.num:=NummerSeg;
        // writeSegnumber(NummerSeg, -1, funktion_+inttostr(ASegmentToCopy.num));//Debuggen
        ASegment.assign(ASegmentToCopy);
        { if ASegmentToCopy.ChildList<> nil then
          begin
          for j:=0 to ASegmentToCopy.ChildList.count-1 do
          begin
          AChild:=TSegment.create;
          AChildToCopy:=ASegmentToCopy.ChildList.items[j];
          assignChildsRekurs(ASegment, AChild, AChildToCopy);
          end;
          end; }
        SegListEO.Add(ASegment);
      end;
    end;
  end
  else
    inherited assign(Source);
end;

{ procedure TRootsystem.assignChildsRekurs(AElder, AChild, AChildToCopy: TSegment);
  var
  AGrandChild,
  AGrandChildToCopy: TSegment;
  i:integer;
  begin
  AChild.assign(AChildToCopy);
  if AChildToCopy.ChildList<> nil then
  begin
  for i:=0 to AChildToCopy.ChildList.count-1 do
  begin
  AGrandChild:=TSegment.create;
  AGrandchildToCopy:=AChildToCopy.ChildList.items[i];
  assignChildsRekurs(AChild, AGrandChild, AGrandchildTocopy);
  end;
  end;
  AElder.ChildList.Add(AChild);
  end; }

procedure TRootsystem.init(NumberSegProd_, NumberMeris_, NumCurrentEmission_
  : integer; AnglesInt_: Array of double);
begin

end;

procedure TRootsystem.makeSegListTotalDisp(ASegment: TSegment);
(* ------------------------------------------------------------------------------
  Für Darstellung (z.B. der Krümmung): Liste mit allen Segmenten, auch wenn
  Primordien sich noch nicht entwickelt haben
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  PotSegLength: double;
begin
  // Berechnen der aktuellen Länge des Segments
  { Anfertigen von Listeneinträgen mit 'Teilsegmenten' aus den pot. Verzweigungen
    ist nur notwendig bei den endständigen Segmenten und nur im tatsächlichen Wachstum }
  if (ASegment.Meristem <> nil) then
  begin
    PotSegLength := makePotSegList(ASegment);
    PotSegLength := ASegment.calcAbsValue(ASegment);
    if (debugMeris = true) and (dummyGrowth = false) then
      writeMerisInfo(ASegment);
    if (ASegment.Meristem.PointsOfRam <> nil) and
      (ASegment.Meristem.PointsOfRam.Count > 1) then
    begin
      ASegment.SegLength := PotSegLength;
    end
    else
      ASegment.SegLength := ASegment.calcAbsValue(ASegment);
  end
  else
    ASegment.SegLength := ASegment.calcAbsValue(ASegment);
  TotRootLengthWS := TotRootLengthWS + ASegment.SegLength;
  SegListTotalDisp.Add(ASegment);
  if ASegment.ChildList <> nil then
  begin
    for j := 0 to ASegment.ChildList.Count - 1 do
    begin
      makeSegListTotalDisp(ASegment.ChildList.Items[j]);
    end;
  end;
end;

procedure TRootsystem.makeSegListTotalRekurs(ASegment: TSegment); // USL
(* ------------------------------------------------------------------------------
  Liste enthält Zeiger auf sämtliche Segmente des WS
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  AChildHigherOrder: TSegment;
begin
  // Berechnen der aktuellen Länge des Segments
  { ASegment.SegLength:=ASegment.calcAbsValue(ASegment);
    TotRootLengthWS:=TotRootLengthWS+ASegment.SegLength;
    SegListTotal.Add(ASegment);
    if ASegment.ChildList<>nil then
    begin
    for j:=0 to ASegment.ChildList.count-1 do
    begin
    makeSegListTotalRekurs(ASegment.ChildList.items[j]);
    end;
    end; }
  // Berechnen der aktuellen Länge des Segments
  if (ASegment.Meristem <> nil) and (ASegment.Meristem.PointsOfRam <> nil) and
    (ASegment.Meristem.PointsOfRam.Count > 1) then
  begin
    // nichts machen Länge der Krümmung vorher berechnet
  end
  else
    ASegment.SegLength := ASegment.calcAbsValue(ASegment);
  { falls verzweigt wurde oder Primordien angelegt wurden }
  if (ASegment.ChildList <> nil) and (ASegment.ChildList.Count > 0) then
  begin
    AChildHigherOrder := ASegment.ChildList.Items[1];
    if AChildHigherOrder.isPrim = true then
    { in diesem Fall hat sich das Segment verzweigt aber noch nicht verlängert,
      aktuelles Segment ist bereits Teilstück des zusammengesetzten Segments }
    begin
      joinSegments(ASegment);
    end
    else
    begin
      // ASegment ist kein zusammengesetztes Segment
      ASegment.isCompSeg := false;
      SegListTotal.Add(ASegment);
      for j := 0 to ASegment.ChildList.Count - 1 do
      begin
        makeSegListTotalRekurs(ASegment.ChildList.Items[j]);
      end;
    end;
  end;
  if ASegment.ChildList.Count = 0 then
  // Segment an der Wurzelspitze hinzuzählen
  begin
    ASegment.isCompSeg := false;
    SegListTotal.Add(ASegment);
  end;

end;

procedure TRootsystem.joinSegments(var ASegment: TSegment);
// USL komplette Methode
(* ------------------------------------------------------------------------------
  Zusammensetzen eines kombinierten Segments
  ------------------------------------------------------------------------------ *)
var
  AChildSameOrder, ACompositeSegment: TSegment;
  i: integer;
begin
  { Zusammengesetztes Segment wird angelegt und erhält zunächst die Daten des ersten
    Teilsegments }
  ACompositeSegment := TSegment.create;
  ACompositeSegment.RS_ID := ASegment.RS_ID;
  ACompositeSegment.PathLengthNum := ASegment.PathLengthNum;
  ACompositeSegment.isPrim := ASegment.isPrim;
  // Neu flag auf True
  ACompositeSegment.isCompSeg := true;
  // Zusammengesetztes Segment weiss ob es von einem 'Ursprungsseg.' ausgeht.
  ACompositeSegment.isEmiss := ASegment.isEmiss;
  ACompositeSegment.num := ASegment.num;
  ACompositeSegment.PrimSegId := ASegment.PrimSegId;
  ACompositeSegment.Internode := ASegment.Internode;
  ACompositeSegment.Order := ASegment.Order;
  ACompositeSegment.DateForm := ASegment.DateForm;
  ACompositeSegment.FatherID := ASegment.FatherID;
  ACompositeSegment.co := ASegment.co;
  ACompositeSegment.ce := ASegment.ce;
  ASegment.SegLength := ASegment.calcAbsValue(ASegment);
  ACompositeSegment.SegLength := ASegment.SegLength;
  if ASegment.ChildList <> nil then // sicherheitshalber
  begin
    AChildSameOrder := ASegment.ChildList.Items[0];
    joinSegmentsRecursive(AChildSameOrder, ACompositeSegment);
  end;
end;

procedure TRootsystem.joinSegmentsRecursive(var ASegment: TSegment;
  var AcompSeg: TSegment); // USL komplette Methode
(* ------------------------------------------------------------------------------
  Rekursives Abarbeiten und Zusammenfassen von Segmenten, die nur Primordien ange-
  legt haben, die sich nicht weiterentwickeln.
  Cave: bei der hier vorgestellten Implementierung hängen zwar die Segmente unter
  des AcompSeg in zusammenhängenden Listen, das AcompSeg selbst steht aber nicht
  in der Kinderliste des Vaters.
  ------------------------------------------------------------------------------ *)
var
  AChildHigherOrder, AChildSameOrder: TSegment;
  i: integer;
begin
  // RemLength:=RemLength+ASegment.SegLength;
  AcompSeg.SegLength := AcompSeg.SegLength + ASegment.SegLength;
  // Länge ist bekannt
  if ASegment.ChildList.Count > 0 then
  begin
    AChildHigherOrder := ASegment.ChildList.Items[1];
    if AChildHigherOrder.isPrim = true then
    begin
      AChildSameOrder := ASegment.ChildList[0];
      joinSegmentsRecursive(AChildSameOrder, AcompSeg);
    end
    else
    { Falls das Kind höherer Ordnung gewachsen = kein Prim. mehr ist,
      ist das aktuelle Segment das letzte Teilstück des zusammen-
      gesetzten Segments u. enthält demnach Endkoord und Childlist, die nun an das
      zusammengesetze Segment übergeben werden muss. }
    begin
      AcompSeg.ce := ASegment.ce; // Endpunkt des zusammengesetzten Segments
      // Zeiger auf die Kinderliste des letzten Teilstücks, Eigene Childlist wird zerstört
      AcompSeg.ChildList.Free;
      AcompSeg.ChildList := ASegment.ChildList;
      SegListTotal.Add(AcompSeg);
      for i := 0 to AcompSeg.ChildList.Count - 1 do
      begin
        // Weitermachen am Ort der nächsten tatsächlichen Verzweigungen
        makeSegListTotalRekurs(AcompSeg.ChildList.Items[i]);
      end;
    end;
  end
  else // Wurzelspitze erreicht
  begin
    AcompSeg.ce := ASegment.ce;
    SegListTotal.Add(AcompSeg);
  end;
end;

procedure TRootsystem.clearSegListTotal;
var
  ASegment: TSegment;
  i: integer;
begin
  { Da SegListTotal auch Zusammengesetzte Segmente enthält, müssen diese gefunden
    und zerstört werden }
  for i := 0 to SegListTotal.Count - 1 do
  begin
    ASegment := SegListTotal[i];
    if ASegment.isCompSeg = true then
    begin
      // Eigentlich haben zusammengesetzte Seg. keine Meristeme
      ASegment.Meristem := nil;
      if ASegment.ChildList.Count <> 0 then
        { Zusammegesetzte Segmente haben keine eigenen Kinder (Zeiger wird weggenommen.
          Childlist darf zerstört werden. }
        ASegment.ChildList := nil;
      if ASegment <> nil then
        ASegment.destroy;
    end;
  end;
  SegListTotal.clear;
  SegListTotalDisp.clear;
end;

function TRootsystem.getSeetPosX: double;
begin
  Result := self.SeetPosX;
end;

function TRootsystem.getSeetPosY: double;
begin
  Result := self.SeetPosY;
end;

function TRootsystem.makePotSegList(ASegment: TSegment): double;
var
  i: integer;
  FirstPotSeg, LastPotSeg, APotSeg: TPotSeg;
  FirstRam, APotRamOld, APotRamNew: TR3;
  LengthOfPotSegs: double;
begin
  LengthOfPotSegs := 0;
  if (ASegment.Meristem.PointsOfRam <> nil) and
    (ASegment.Meristem.PointsOfRam.Count > 1) then
  begin
    // am Anfang UrsprungSeg -> erster pot. Verzw. Punkt
    FirstPotSeg := TPotSeg.create;
    FirstPotSeg.co[0] := ASegment.co[0];
    FirstPotSeg.co[1] := ASegment.co[1];
    FirstPotSeg.co[2] := ASegment.co[2];
    FirstRam := ASegment.Meristem.PointsOfRam.Items[1];
    FirstPotSeg.ce[0] := FirstRam.Koord3D[0];
    FirstPotSeg.ce[1] := FirstRam.Koord3D[1];
    FirstPotSeg.ce[2] := FirstRam.Koord3D[2];
    LengthOfPotSegs := LengthOfPotSegs + ASegment.calcAbsValue(FirstPotSeg.co,
      FirstPotSeg.ce);
    PotSegListWS.Add(FirstPotSeg);
    // die mittleren PotSeg
    APotRamOld := FirstRam;
    // Zu Beginn Zeiger auf den ersten pot. Verzw. Punkt.
    for i := 2 to ASegment.Meristem.PointsOfRam.Count - 1 do
    begin
      APotSeg := TPotSeg.create;
      APotSeg.co[0] := APotRamOld.Koord3D[0];
      APotSeg.co[1] := APotRamOld.Koord3D[1];
      APotSeg.co[2] := APotRamOld.Koord3D[2];
      APotRamNew := ASegment.Meristem.PointsOfRam.Items[i];
      APotSeg.ce[0] := APotRamNew.Koord3D[0];
      APotSeg.ce[1] := APotRamNew.Koord3D[1];
      APotSeg.ce[2] := APotRamNew.Koord3D[2];
      LengthOfPotSegs := LengthOfPotSegs + ASegment.calcAbsValue(APotSeg.co,
        APotSeg.ce);
      PotSegListWS.Add(APotSeg);
      APotRamOld := APotRamNew;
    end;
    // das letzte Teilsegment
    LastPotSeg := TPotSeg.create;
    APotRamNew := ASegment.Meristem.PointsOfRam.Items
      [ASegment.Meristem.PointsOfRam.Count - 1];
    LastPotSeg.co[0] := APotRamNew.Koord3D[0];
    LastPotSeg.co[1] := APotRamNew.Koord3D[1];
    LastPotSeg.co[2] := APotRamNew.Koord3D[2];
    LastPotSeg.ce[0] := ASegment.ce[0];
    LastPotSeg.ce[1] := ASegment.ce[1];
    LastPotSeg.ce[2] := ASegment.ce[2];
    LengthOfPotSegs := LengthOfPotSegs + ASegment.calcAbsValue(LastPotSeg.co,
      LastPotSeg.ce);
    PotSegListWS.Add(LastPotSeg);
  end;
  Result := LengthOfPotSegs;
end;

procedure TRootsystem.setRandomArr(index: integer; value: double);
begin
  ARandArr[index] := value;

end;

{ TSegment }

constructor TSegment.create;
begin
  inherited create;
  { Bei Neuanlage hat eine Liste für die Kinder }
  ChildList := TList.create;
  SegLength := 0;
  FatherID := 0;
  isPrim := true; // USL
  isCompSeg := false;
  isEmiss := false;
  Meristem := nil;
end;

constructor TSegment.create(RS_ID: integer);
begin
  inherited create;
  { Bei Neuanlage hat eine Liste für die Kinder }
  ChildList := TList.create;
  SegLength := 0;
  FatherID := 0;
  isPrim := true; // USL
  isCompSeg := false;
  isEmiss := false;
  Meristem := nil;
end;

constructor TSegment.create(Father_: TSegment);
begin
  inherited create;
  // Bei Anlage wird die Nummer des Vatersegments gespeichert
  // FatherSeg:=Father_;
  SegLength := 0;
  FatherID := 0;
  ChildList := TList.create;
  isPrim := true; // USL
  isCompSeg := false;
  isEmiss := false;
  Meristem := nil;
end;

destructor TSegment.destroy;
begin
  if (ChildList <> nil) then
  begin
    ChildList.clear;
    ChildList.Free;
  end;
  // Zusammengesetzte Segmente haben kein Meristem
  if (self.Meristem <> Nil) and (self.isCompSeg = false) then
    Meristem.destroy;
  inherited destroy;
end;

procedure TSegment.assign(Source: TPersistent);
var
  MeristemCopy: TMeristem;
  ASegment, ASegmentToCopy: TSegment;
  i: integer;
  function_: string;
begin
  function_ := 'TSegment.assign';
  // Kopieren sämtlicher Member aus der Quelle
  if Source is TSegment then
  begin
    isPrim := TSegment(Source).isPrim;
    RS_ID := TSegment(Source).RS_ID;
    PathLengthNum := TSegment(Source).PathLengthNum;
    num := TSegment(Source).num;
    PrimSegId := TSegment(Source).PrimSegId;
    Internode := TSegment(Source).Internode;
    Order := TSegment(Source).Order;
    SegLength := TSegment(Source).SegLength;
    DateForm := TSegment(Source).DateForm;
    FatherID := TSegment(Source).FatherID;
    co := TSegment(Source).co;
    ce := TSegment(Source).ce;
    isEmiss := TSegment(Source).isEmiss;
    isCompSeg := TSegment(Source).isCompSeg;
    numMeris := TSegment(Source).numMeris;
    // Meristem erzeugen und die Eigenschaften des Meristems aus der Quelle zuweisen.
    if TSegment(Source).Meristem <> nil then
    begin
      MeristemCopy := TMeristem.create;
      MeristemCopy.assign(TSegment(Source).Meristem);
      Meristem := MeristemCopy;
    end
    else
      Meristem := nil;
    // ChildList wird gesondert zugewiesen
    // Nur, wenn Kinder vorhanden sind, dann soll kopiert werden.
    if TSegment(Source).ChildList <> nil then
    begin
      for i := 0 to TSegment(Source).ChildList.Count - 1 do
      begin
        ASegmentToCopy := TSegment(TSegment(Source).ChildList.Items[i]);
        ASegment := TSegment.create;
        { Folgende zwei Zeilen wurden benötigt, um die Kopierfunktion zu debuggen }
        // inc(NummerSeg);
        // ASegment.num:=NummerSeg;
        // writeSegnumber(NummerSeg,-1,function_+inttostr(ASegmentToCopy.num));//Debuggen
        ASegment.assign(ASegmentToCopy);
        ChildList.Add(ASegment);
      end;
    end;
  end
  else
    inherited assign(Source);
end;

function TSegment.calcLengthFamily(ASegment: TSegment): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Summiert die Wurzellängen des Segments und seiner Abkömmlinge
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  LengthSelfAndChilds: double;
  AChild: TSegment;
begin
  { Segmente außerhalb des Weltwürfels werden komplett nicht berücksichtigt,
    Problem: sollte der sich im WW befindliche Anteil berücksichtigt werden? Vgl.
    Methode cutSegment }
  if ((ASegment.co[0] < 0) or (ASegment.co[0] > dim_X) and (ASegment.co[1] < 0)
    or (ASegment.co[1] > dim_Y) and (ASegment.co[2] < 0) or
    (ASegment.co[2] > dim_Z)) and
    ((ASegment.ce[1] < 0) or (ASegment.ce[0] > dim_X) and (ASegment.ce[1] < 0)
    or (ASegment.ce[1] > dim_Y) and (ASegment.ce[2] < 0) or
    (ASegment.ce[2] > dim_Z)) then
  begin
    // nichts machen
  end
  else
  begin
    if self.ChildList <> nil then
    begin
      for i := 0 to ChildList.Count - 1 do
      begin
        AChild := ChildList.Items[i];
        LengthSelfAndChilds := AChild.calcLengthFamily(AChild);
      end;
    end;
  end;
  Result := LengthSelfAndChilds;
end;

function TSegment.calcAbsValue(ASegment_: TSegment): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Function berechnet den Betrag des Vektors zwischen Anfang und End-
  punkt des Segments in R3 und gibt ihn zurürck
  ------------------------------------------------------------------------------ *)
var
  VektSegment, VektCe, VektCo: r3;
  vektLength: double;
begin
  { Berechnung des Vektors, der das Segment beschreibt aus den Ortsvektoren von An-
    fangs- und Endpunkt }
  VektCo := ASegment_.co;
  VektCe := ASegment_.ce;
  VektSegment := vectorSubtrakt(VektCe, VektCo);
  // Berechnung des Betrags des Vektors
  vektLength := sqrt(sqr(VektSegment[0]) + sqr(VektSegment[1]) +
    sqr(VektSegment[2]));
  Result := vektLength;
end;

function TSegment.vectorSubtrakt(vector_a, vector_b: r3): r3;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Subtrahiert vector_b von vector_a und gibt den resultierenden
  Vektor zurück.
  ------------------------------------------------------------------------------ *)
var
  vector_result: r3;
begin
  vector_result[0] := vector_a[0] - vector_b[0];
  vector_result[1] := vector_a[1] - vector_b[1];
  vector_result[2] := vector_a[2] - vector_b[2];
  Result := vector_result;
end; // End TSegment.vectorSubtrakt

// Set und Get-Methoden
function TSegment.getInternode: byte;
begin
  Result := Internode;
end;

function TSegment.getCe: r3;
begin
  Result := self.ce;
end;

function TSegment.getCo: r3;
begin
  Result := self.co;
end;

procedure TSegment.setInternode(internode_: byte);
begin
  Internode := internode_;
end;

procedure TSegment.setFatherID(Father_id: integer);
begin
  self.FatherID := Father_id;
end;

function TSegment.getMeristem: TMeristem;
begin
  Result := Meristem;
end;

function TSegment.getChildList: TList;
begin
  Result := ChildList;
end;

{ TSubmodRootStrucNew }
procedure TSubmodRootStrucNew.createAll;
var
  i, j: integer;
begin
  inherited;

  // Zufallszahlengenerator initialisieren

  // Listen erstellen
  RSList := TList.create;
  RSListCopy := TList.create;
  SRPList := TList.create;
  SRPLightList := TList.create;
  SegListIntersect := TList.create;
  PseudoSegListIntersect := TList.create;
  SegListWS := TList.create;
  PotSegListTot := TList.create;
  BranchDensPrimRoots := TList.create;
  // für Voronoi
  PaintList := TList.create;
  // Erzeugen der Hume-Variablen und Parameter

  // Zustandsvariablen
  StateCreate('mRLD', '[cm/cm^3]', 0.0, false, mRLD);
  StateCreate('VC', '[%]', 0.0, false, VC);
  StateCreate('RLD_1', '[cm/cm^3]', 0.0, false, RLD_1);
  StateCreate('VC_1', '[%]', 0.0, false, VC_1);
  StateCreate('RLD_2', '[cm/cm^3]', 0.0, false, RLD_2);
  StateCreate('VC_2', '[%]', 0.0, false, VC_2);
  StateCreate('RLD_3', '[cm/cm^3]', 0.0, false, RLD_3);
  StateCreate('VC_3', '[%]', 0.0, false, VC_3);
  StateCreate('RLD_4', '[cm/cm^3]', 0.0, false, RLD_4);
  StateCreate('VC_4', '[%]', 0.0, false, VC_4);
  StateCreate('RLD_5', '[cm/cm^3]', 0.0, false, RLD_5);
  StateCreate('VC_5', '[%]', 0.0, false, VC_5);
  StateCreate('RLD_6', '[cm/cm^3]', 0.0, false, RLD_6);
  StateCreate('VC_6', '[%]', 0.0, false, VC_6);
  StateCreate('RLD_7', '[cm/cm^3]', 0.0, false, RLD_7);
  StateCreate('VC_7', '[%]', 0.0, false, VC_7);
  StateCreate('RLD_8', '[cm/cm^3]', 0.0, false, RLD_8);
  StateCreate('VC_8', '[%]', 0.0, false, VC_8);
  StateCreate('RLD_9', '[cm/cm^3]', 0.0, false, RLD_9);
  StateCreate('VC_9', '[%]', 0.0, false, VC_9);
  StateCreate('RLD_10', '[cm/cm^3]', 0.0, false, RLD_10);
  StateCreate('VC_10', '[%]', 0.0, false, VC_10);

  StateCreate('Depth', '[cm]', 0.0, false, depth);
  StateCreate('DeepestIntersection', '[cm]', 0.0, false, DeepestIntersection);
  StateCreate('numbRoots', '[-]', 0.0, false, numbRoots);
  StateCreate('WL_0_30', '[cm]', 0.0, false, WL_0_30);
  StateCreate('WL_30_60', '[cm]', 0.0, false, WL_30_60);
  StateCreate('WL_60_90', '[cm]', 0.0, false, WL_60_90);
  StateCreate('WL_30_100', '[cm]', 0.0, false, WL_30_100);
  for i := 0 to numComp + 1 do
  begin
    StateCreate('Wl_Lay' + inttostr(i), '[cm]', 0.0, false, WLStateArray[i]);
    StateCreate('effWLD_' + inttostr(i), '[cm cm-3]', 0.0, false, WLDArr[i]);
    { Da Kommunikation mit SoilWaterModelR besteht (Externe V.
      müssen sie als effWLD_Schicht-Nr benannt werden. Es wird
      aber angenommen, dass die Wurzel über die gesamte Existenz
      ativ bei Wasseraufnahme beteiligt ist, ausserdem über die
      gesamte Länge der Wurzel. }
    VarCreate('VC_No' + inttostr(i), '[%]', 0.0, false, VCNumbVarArrray[i]);
    // Array mit Variablen für jede Schicht für prozent. Anteil erschloss. Zellen
    VarCreate('ExplCells_' + inttostr(i), '[%]', 0.0, false,
      PercentCellsArray[i]);
    ExternVCreate('SoilTemp_' + inttostr(i + 1), '[°C]', StateField,
      SoilTempArray[i]);
  end;
  StateCreate('BranchDens', '[cm^-1]', 0.0, false, BranchDens);
  StateCreate('BranchDensStDev', '[cm^-1]', 0.0, false, BranchDensStDev);
  StateCreate('ZahlSegPW', '[-]', 0.0, false, ZahlSegPW);
  StateCreate('ZahlSegE1', '[-]', 0.0, false, ZahlSegE1);
  StateCreate('ZahlSegE2', '[-]', 0.0, false, ZahlSegE2);
  StateCreate('ZahlSegE3', '[-]', 0.0, false, ZahlSegE3);

  // setlength(SoilTempArr,numComp+1); //wg. Performance angedacht, wahrschl. unnötig
  // Variablen
  ParCreate('contRad', '[cm]', 10, contRad);
  VarCreate('RootDMWSdt', '[g]', 0, true, RootDMWSdt);
  VarCreate('RootDM', '[g]', 0, true, RootDM);
  VarCreate('SumWL', '[cm]', 0, true, SumWL);
  VarCreate('Red_WL', '[-]', 0, true, Red_WL);
  VarCreate('MeanSegLenWC', '[cm]', 0, true, MeanSegLenWC);
  VarCreate('StdDevSegLenWC', '[cm]', 0, true, StdDevSegLenWC);
  VarCreate('numberRootSeg', '[-]', 0, true, numberRootSeg);
  VarCreate('numberPlants', '[-]', 0, true, numberPlants);
  VarCreate('numberEmission', '[-]', 0, true, numberEmission);
  VarCreate('EmissPerPlant', '[-]', 0, true, EmissPerPlant);
  VarCreate('TempSumAir', '[-]', 0, true, TempSumAir);
  { VarCreate('potTM_RS','[g]',0, true,potTM_RS);
    VarCreate('aktTM_RS','[g]',0, true,aktTM_RS);
    VarCreate('potWL_RS','[cm]',0, true,potWL_RS);
    VarCreate('aktWL_RS','[cm]',0, true,aktWL_RS); }
  // Daten bez. auf Ent-Ordnung
  VarCreate('SumWL_PW', '[cm]', 0, true, SumWL_PW);
  VarCreate('SumWL_E1', '[cm]', 0, true, SumWL_E1);
  VarCreate('SumWL_E2', '[cm]', 0, true, SumWL_E2);
  VarCreate('SumWL_E3', '[cm]', 0, true, SumWL_E3);
  // Daten bezogen auf Verzweigungs bzw. Nichtverzweigungszonen
  VarCreate('TotSLVZPW', '[cm]', 0, true, TotSLVZPW);
  VarCreate('TotSLVZE1', '[cm]', 0, true, TotSLVZE1);
  VarCreate('TotSLVZE2', '[cm]', 0, true, TotSLVZE2);
  VarCreate('TotSLVZE3', '[cm]', 0, true, TotSLVZE3);

  VarCreate('MeanSLVZPW', '[cm]', 0, true, MeanSLVZPW);
  VarCreate('MeanSLVZE1', '[cm]', 0, true, MeanSLVZE1);
  VarCreate('MeanSLVZE2', '[cm]', 0, true, MeanSLVZE2);
  VarCreate('MeanSLVZE3', '[cm]', 0, true, MeanSLVZE3);

  VarCreate('StdDSLVZPW', '[cm]', 0, true, StdDSLVZPW);
  VarCreate('StdDSLVZE1', '[cm]', 0, true, StdDSLVZE1);
  VarCreate('StdDSLVZE2', '[cm]', 0, true, StdDSLVZE2);
  VarCreate('StdDSLVZE3', '[cm]', 0, true, StdDSLVZE3);
  // Best. Verzweigungszonen Primärwurzel
  VarCreate('TotNZ_PW', '[cm]', 0, true, TotNZ_PW);
  VarCreate('TotApNBZ_PW', '[cm]', 0, true, TotApNBZ_PW);
  VarCreate('TotBasNBZ_PW', '[cm]', 0, true, TotBasNBZ_PW);
  VarCreate('MeanNZ_PW', '[cm]', 0, true, MeanNZ_PW);
  VarCreate('MeanApNBZ_PW', '[cm]', 0, true, MeanApNBZ_PW);
  VarCreate('MeanBasNBZ_PW', '[cm]', 0, true, MeanBasNBZ_PW);
  VarCreate('MeanBZ_PW', '[cm]', 0, true, MeanBZ_PW);
  VarCreate('StdNZ_PW', '[cm]', 0, true, StdNZ_PW);
  VarCreate('StdApNBZ_PW', '[cm]', 0, true, StdApNBZ_PW);
  VarCreate('StdBasNBZ_PW', '[cm]', 0, true, StdBasNBZ_PW);
  // Best. Verweigungszonen SW 1. Ord.
  VarCreate('TotApNBZ_E1', '[cm]', 0, true, TotApNBZ_E1);
  VarCreate('MeanApNBZ_E1', '[cm]', 0, true, MeanApNBZ_E1);
  VarCreate('StdApNBZ_E1', '[cm]', 0, true, StdApNBZ_E1);
  // Best. Verweigungszonen SW 2. Ord.
  VarCreate('TotApNBZ_E2', '[cm]', 0, true, TotApNBZ_E2);
  VarCreate('MeanApNBZ_E2', '[cm]', 0, true, MeanApNBZ_E2);
  VarCreate('StdApNBZ_E2', '[cm]', 0, true, StdApNBZ_E2);
  // Best. Verweigungszonen SW 3. Ord.
  VarCreate('TotApNBZ_E3', '[cm]', 0, true, TotApNBZ_E3);
  VarCreate('MeanApNBZ_E3', '[cm]', 0, true, MeanApNBZ_E3);
  VarCreate('StdApNBZ_E3', '[cm]', 0, true, StdApNBZ_E3);
  // VarCreate('StdBZ_PW','[-]',0, true,StdBZ_PW);
  // VarCreate('StdBZ_E1','[-]',0, true,StdBZ_E1);
  // VarCreate('StdBZ_E2','[-]',0, true,StdBZ_E2);

  VarCreate('MeanAxisPW', '[cm]', 0, true, MeanAxisPW);
  VarCreate('VCAxisPW', '[cm]', 0, true, VCAxisPW);
  VarCreate('MeanAxisE1', '[cm]', 0, true, MeanAxisE1);
  VarCreate('VCAxisE1', '[cm]', 0, true, VCAxisE1);
  VarCreate('MeanAxisE2', '[cm]', 0, true, MeanAxisE2);
  VarCreate('VCAxisE2', '[cm]', 0, true, VCAxisE2);
  VarCreate('MeanAxisE3', '[cm]', 0, true, MeanAxisE3);
  VarCreate('VCAxisE3', '[cm]', 0, true, VCAxisE3);
  // Parameter
  ParCreate('border1stLayer', '[cm]', 5, border1stLayer);
  ParCreate('NumCompToCalc', '[-]', 11, NumCompToCalc);
  // Dimensionen des Weltwürfels
  ParCreate('dimX', '[cm]', 100, DimX);
  ParCreate('dimY', '[cm]', 100, DimY);
  ParCreate('dimZ', '[cm]', 100, DimZ);
  // Aussaatpunkt erste Pflanze, Standard: mittig in einer Fläche von 1 m^2
  ParCreate('PosXPlant', '[cm]', 50, PosXPlant);
  ParCreate('PosyPlant', '[cm]', 50, PosYPlant);
  ParCreate('SowingDepth', '[cm]', 0, SowingDepth);
  // Abstände
  ParCreate('rowSpace', '[cm]', 10, RowSpace);
  ParCreate('SpaceWithinRows', '[cm]', 3.03, SpaceWithinRows);
  ParCreate('SpaceWithinRows', '[cm]', 3.03, SpaceWithinRows);
  // Pages-Parameter
  // Skalierung und Additions-Parameter
  ParCreate('a_scaling', '[-]', 1, a_scaling);
  ParCreate('b_scaling', '[-]', 1, b_scaling);
  ParCreate('ram_scaling', '[-]', 1, ram_scaling);
  ParCreate('geo_scaling', '[-]', 1, geo_scaling);
  ParCreate('mech_scaling', '[-]', 1, mech_scaling);
  ParCreate('Add_Prim', '[-]', 0, Add_Prim);
  ParCreate('AddNumb_Gen', '[-]', 0, AddNumb_Gen);
  ParCreate('Par_begin', '[-]', 0, Par_begin);
  ParCreate('Par_disposition', '[-]', 0, Par_disposition);
  { der Emissionsparameter wird internodienspez. belegt (Array). Anzahl der
    entstehenden Primärwurzeln bezogen auf ein spez. Internodium }
  for i := 0 to NumberINTMAX - 1 do
  begin
    ParCreate('Par_Emission_In' + inttostr(i + 1), '[-]', 0, Par_EmissArr[i]);
  end;
  for i := 0 to NumberINTMAX - 1 do
  begin
    for j := 0 to 2 do
    begin
      ParCreate('Par_OrigPr_In' + inttostr(i + 1) + '_' + inttostr(j), '[-]', 0,
        Par_OrigPrArr[i][j]);
    end;
  end;
  // Entwicklungsordnung 1

  ParCreate('Par_Bas_NBZ_Ord1', '[cm]', 0, Par_Bas_NBZ_Ord1);
  ParCreate('Par_AP_NBZ_Ord1', '[cm]', 0, Par_AP_NBZ_Ord1);
  ParCreate('Par_numberGen_Ord1', '[-]', 0, Par_numberGen_Ord1);
  ParCreate('Par_AverAngleInsert_Ord1', '[°]', 0, Par_AverAngleInsert_Ord1);
  ParCreate('Par_StdDevAngleInsert_Ord1', '[]', 0, Par_StdDevAngleInsert_Ord1);
  ParCreate('Par_developPrim_Ord1', '[°Cd]', 0, Par_developPrim_Ord1);
  ParCreate('Par_AverGrowthA_Ord1', '[-]', 0, Par_AverGrowthA_Ord1);
  ParCreate('Par_AverGrowthB_Ord1', '[-]', 0, Par_AverGrowthB_Ord1);
  ParCreate('Par_StdDevGrowthA_Ord1', '[-]', 0, Par_StdDevGrowthA_Ord1);
  ParCreate('Par_StdDevGrowthB_Ord1', '[-]', 0, Par_StdDevGrowthB_Ord1);
  ParCreate('Par_ConstRatePW', '[cm*dt-1]', 0, Par_ConstRatePW);
  ParCreate('Par_AverRamific_Ord1', '[-]', 0, Par_AverRamific_Ord1);
  ParCreate('Par_RamMod_Bsem', '[-]', 0.01888, Par_RamMod_Bsem);
  // default Pages Org
  ParCreate('Par_RamMod_Asem', '[-]', 9.956, Par_RamMod_Asem);
  ParCreate('Par_RamMod_Bcr', '[-]', 0.0128, Par_RamMod_Bcr);
  ParCreate('Par_RamMod_Acr', '[-]', 11.51, Par_RamMod_Acr);
  ParCreate('Par_StdDevRamific_Ord1', '[]', 0, Par_StdDevRamific_Ord1);
  ParCreate('Par_Coeff_Geo_Ord1', '[-]', 0, Par_Coeff_Geo_Ord1);
  ParCreate('Par_mechResist_Ord1', '[-]', 0, Par_mechResist_Ord1);
  // Entwicklungsordnung 2
  ParCreate('Par_Bas_NBZ_Ord2', '[cm]', 0, Par_Bas_NBZ_Ord2);
  ParCreate('Par_AP_NBZ_Ord2', '[cm]', 0, Par_AP_NBZ_Ord2);
  ParCreate('Par_numberGen_Ord2', '[-]', 0, Par_numberGen_Ord2);
  ParCreate('Par_AverAngleInsert_Ord2', '[°]', 0, Par_AverAngleInsert_Ord2);
  ParCreate('Par_StdDevAngleInsert_Ord2', '[]', 0, Par_StdDevAngleInsert_Ord2);
  ParCreate('Par_developPrim_Ord2', '[°Cd]', 0, Par_developPrim_Ord2);
  ParCreate('Par_AverGrowthA_Ord2', '[-]', 0, Par_AverGrowthA_Ord2);
  ParCreate('Par_AverGrowthADist_Ord2', '[-]', 2.2, Par_AverGrowthADist_Ord2);
  // default Pages Org
  ParCreate('Par_AverGrowthB_Ord2', '[-]', 0, Par_AverGrowthB_Ord2);
  ParCreate('Par_StdDevGrowthA_Ord2', '[-]', 0, Par_StdDevGrowthA_Ord2);
  ParCreate('Par_StdDevGrowthADist_Ord2', '[-]', 0.82,
    Par_StdDevGrowthADist_Ord2); // default Pages Org
  ParCreate('Par_StdDevGrowthB_Ord2', '[-]', 0, Par_StdDevGrowthB_Ord2);
  ParCreate('Par_AverRamific_Ord2', '[-]', 0, Par_AverRamific_Ord2);
  ParCreate('Par_StdDevRamific_Ord2', '[-]', 0, Par_StdDevRamific_Ord2);
  ParCreate('Par_Coeff_Geo_Ord2', '[-]', 0, Par_Coeff_Geo_Ord2);
  ParCreate('Par_mechResist_Ord2', '[-]', 0, Par_mechResist_Ord2);
  // für alternative Berechnung des Elongationsparameters A der W-Seg in SW 1
  ParCreate('ThresDistBase', '[cm]', 40, ThresDistBase); // default Pages Org.
  ParCreate('ElongAStartAv_Ord2', '[-]', 3.0, ElongAStartAv_Ord2);
  // default Pages Org.
  ParCreate('ElongAStartDev_Ord2', '[-]', 1.0, ElongAStartDev_Ord2);
  // default Pages Org.
  // Modifikation des Geotropismus-Koeff.
  ParCreate('GeoMod', '[-]', 5, GeoMod); // Default aus Pages
  ParCreate('GeoModRange', '[-]', 3, GeoModRange); // Default aus Pages
  // Modifikation des Ramifikationsparameters
  ParCreate('Thres_RamMod', '[-]', 3.2, Thres_RamMod); // Default aus Pages
  ParCreate('Par_RamMod_Gener', '[-]', 100, Par_RamMod_Gener);
  // Default aus Pages
  // Entwicklungsordnung 3
  ParCreate('Par_Bas_NBZ_Ord3', '[cm]', 0, Par_Bas_NBZ_Ord3);
  ParCreate('Par_AP_NBZ_Ord3', '[cm]', 0, Par_AP_NBZ_Ord3);
  ParCreate('Par_numberGen_Ord3', '[-]', 0, Par_numberGen_Ord3);
  ParCreate('Par_AverAngleInsert_Ord3', '[°]', 0, Par_AverAngleInsert_Ord3);
  ParCreate('Par_StdDevAngleInsert_Ord3', '[-]', 0, Par_StdDevAngleInsert_Ord3);
  ParCreate('Par_developPrim_Ord3', '[°Cd]', 0, Par_developPrim_Ord3);
  ParCreate('Par_AverGrowthA_Ord3', '[-]', 0, Par_AverGrowthA_Ord3);
  ParCreate('Par_AverGrowthB_Ord3', '[-]', 0, Par_AverGrowthB_Ord3);
  ParCreate('Par_StdDevGrowthA_Ord3', '[-]', 0, Par_StdDevGrowthA_Ord3);
  ParCreate('Par_StdDevGrowthB_Ord3', '[-]', 0, Par_StdDevGrowthB_Ord3);
  ParCreate('Par_AverRamific_Ord3', '[-]', 0, Par_AverRamific_Ord3);
  ParCreate('Par_StdDevRamific_Ord3', '[-]', 0, Par_StdDevRamific_Ord3);
  ParCreate('Par_Coeff_Geo_Ord3', '[-]', 0, Par_Coeff_Geo_Ord3);
  ParCreate('Par_mechResist_Ord3', '[-]', 0, Par_mechResist_Ord3);

  // Entwicklungsordnung 4
  ParCreate('Par_AP_NBZ_Ord4', '[-]', 0, Par_AP_NBZ_Ord4);
  ParCreate('Par_Bas_NBZ_Ord4', '[-]', 0, Par_Bas_NBZ_Ord4);
  ParCreate('Par_numberGen_Ord4', '[-]', 0, Par_numberGen_Ord4);
  ParCreate('Par_AverAngleInsert_Ord4', '[-]', 0, Par_AverAngleInsert_Ord4);
  ParCreate('Par_StdDevAngleInsert_Ord4', '[-]', 0, Par_StdDevAngleInsert_Ord4);
  ParCreate('Par_developPrim_Ord4', '[°Cd]', 0, Par_developPrim_Ord4);
  ParCreate('Par_AverGrowthA_Ord4', '[-]', 0, Par_AverGrowthA_Ord4);
  ParCreate('Par_AverGrowthB_Ord4', '[-]', 0, Par_AverGrowthB_Ord4);
  ParCreate('Par_StdDevGrowthA_Ord4', '[-]', 0, Par_StdDevGrowthA_Ord4);
  ParCreate('Par_StdDevGrowthB_Ord4', '[-]', 0, Par_StdDevGrowthB_Ord4);
  ParCreate('Par_AverRamific_Ord4', '[-]', 0, Par_AverRamific_Ord4);
  ParCreate('Par_StdDevRamific_Ord4', '[-]', 0, Par_StdDevRamific_Ord4);
  ParCreate('Par_Coeff_Geo_Ord4', '[-]', 0, Par_Coeff_Geo_Ord4);
  ParCreate('Par_mechResist_Ord4', '[-]', 0, Par_mechResist_Ord4);

  ParCreate('SpezRL', '[cm/g]', 17000, SpezRL);
  ParCreate('dl_RedFWL', '[-]', 0.1, dl_RedFWL);
  ParCreate('Threshold_DMRoot', '[-]', 0.01, Threshold_DMRoot);
  ParCreate('avTempYear', '[°C]', 0, avTempYear);
  ParCreate('BaseTemp', '[°C]', 0, BaseTemp);
  ParCreate('Tmin', '[°C]', 0, Tmin);
  ParCreate('Tmax', '[°C]', 0, Tmax);
  ParCreate('theta_', '[cm^3/cm^3]', 0, theta_);
  ParCreate('TetaAngl', '[°]', 15, TetaAngl); // default Pages Org.
  ParCreate('DepthSubsoil', '[cm]', 30, DepthSubsoil);
  ParCreate('sowingDate', '[d]', 0, sowingDate);
  ParCreate('minDistWall', '[-]', 0.001, minDistWall);
  ParCreate('NumbColVK', '[-]', 2, NumbColVK);
  ParCreate('spezRL_Sand', '[-]', 0, spezRL_Sand);
  ParCreate('spezRL_NL', '[-]', 0, spezRL_NL);
  ParCreate('TransfSand_NL', '[-]', 0, TransfSand_NL);
  ParCreate('ThresholdGrowth', '[-]', 1.0E-1, ThresholdGrowth);
  ParCreate('L0_MerisPW', '[cm]', 1.0E-6, L0_MerisPW);
  ParCreate('rgr_expo', '[]', 0, rgr_expo);
  ParCreate('LmaxMerisPW', '[cm]', 150, LmaxMerisPW);

  ParCreate('BordLeftFront', '[cm]', 0, BordLeftFront);
  ParCreate('BordRightBehind', '[cm]', 0, BordRightBehind);
  ParCreate('CalibRLD', '[-]', 3.3639, CalibRLD); // default Skal-Fakt FV 100/04

  // Optionen

  OptCreate('SRL_input', 'Par', SRL_input);
  SRL_input.OptionList.Add('Par');
  SRL_input.OptionList.Add('from_File');
  OptCreate('drawMode', 'increment', drawMode);
  drawMode.OptionList.Add('increment'); // Zeichnen des Zuwachses
  drawMode.OptionList.Add('CoordSeg');
  // Zeichnen anhand von Koordinaten Segmentliste
  SRL_input.OptionList.Add('2_const');
  OptCreate('gridWidth', '5', gridWidth);
  OptCreate('SegFile', 'Q:\Kohl\StruktModell\IniOutxy_Data.csv', SegFile);
  OptCreate('IntersectFile', 'Q:\Kohl\StruktModell\IniOutIntersect.csv',
    IntersectFile);
  OptCreate('AggrRootData', 'Q:\Kohl\StruktModell\IniOutaggrRootData.csv',
    AggrRootData);
  OptCreate('mode', 'singleplant', mode);
  OptCreate('WriteSegFile', 'no', WriteSegFile);
  OptCreate('WriteAggrData', 'no', WriteAggrData);
  OptCreate('RelocateSowPoints', 'no', RelocateSowPoints);
  OptCreate('stochasticGrowth', 'yes', stochasticGrowth);
  stochasticGrowth.OptionList.Add('yes');
  stochasticGrowth.OptionList.Add('no');
  OptCreate('unlinkRS', 'no', unlinkRS);
  unlinkRS.OptionList.Add('yes');
  unlinkRS.OptionList.Add('no');
  RelocateSowPoints.OptionList.Add('yes');
  RelocateSowPoints.OptionList.Add('no');
  gridWidth.OptionList.Add('5');
  gridWidth.OptionList.Add('10');
  mode.OptionList.Add('singleplant');
  mode.OptionList.Add('singlerow');
  mode.OptionList.Add('crop');
  WriteSegFile.OptionList.Add('yes');
  WriteSegFile.OptionList.Add('no');
  WriteAggrData.OptionList.Add('yes');
  WriteAggrData.OptionList.Add('no');
  AggrRootData.OptionList.Add('Q:\Kohl\StruktModell\IniOut\aggrRootData.csv');
  AggrRootData.OptionList.Add('Q:\Kohl\StruktModell\IniOut\aggrRootData.csv');

  SegFile.OptionList.Add('Q:\Kohl\StruktModell\IniOutxy_Data');
  SegFile.OptionList.Add('Q:\Kohl\StruktModell\IniOut\xy_Data.csv');
  SegFile.OptionList.Add('Q:\Kohl\StruktModell\IniOutxy_Data.csv');
  SegFile.OptionList.Add('Q:\Kohl\StruktModell\IniOut\xy_Data.csv');

  IntersectFile.OptionList.Add('Q:\Kohl\StruktModell\IniOutIntersect.csv');
  IntersectFile.OptionList.Add('Q:\Kohl\StruktModell\IniOut\Intersect.csv');
  OptCreate('modelQuality', 'low', modelQuality);
  modelQuality.OptionList.Add('low');
  modelQuality.OptionList.Add('middle');
  modelQuality.OptionList.Add('high');
  OptCreate('RLD Mode', 'intersect', RLDMode);
  RLDMode.OptionList.Add('rootlength');
  RLDMode.OptionList.Add('intersect');
  RLDMode.OptionList.Add('both');
  OptCreate('RamMode', 'pagesorg', RamMode);
  // Zwischenverzweigungslänge folgt negativ expon. Kurve
  RamMode.OptionList.Add('pagesorg');
  // Zwischenverzweigungslänge ist Parameter (Konstante) für alle Entw.-Ordnungen
  RamMode.OptionList.Add('parall');
  // Zwischenverzweigungslänge ist Parameter (Konstante) nur für SW
  RamMode.OptionList.Add('parsw');
  // Zwischenverzweigungslänge ist Parameter (Konstante) nur für SW
  OptCreate('Type DMRoot', 'm^2', Type_DMRoot);
  { Legt fest, ob es sich um die Wurzel-TM einer Einzelpflanze oder eines Bestandes
    auf einem Quadratmeter handelt }
  Type_DMRoot.OptionList.Add('m^2');
  Type_DMRoot.OptionList.Add('single_Plant');
  OptCreate('SoilTempMode', 'linear', SoilTempMode);
  SoilTempMode.OptionList.Add('without');
  SoilTempMode.OptionList.Add('submodel');
  SoilTempMode.OptionList.Add('linear');
  SoilTempMode.OptionList.Add('sinus');
  OptCreate('ContGrowth', 'no', ContGrowth);
  ContGrowth.OptionList.Add('yes');
  ContGrowth.OptionList.Add('no');
  OptCreate('PrecDeriveData', 'low', PrecDeriveData);
  PrecDeriveData.OptionList.Add('low');
  PrecDeriveData.OptionList.Add('high');
  OptCreate('enablePotentGrowth', 'no', enablePotentGrowth);
  enablePotentGrowth.OptionList.Add('no');
  enablePotentGrowth.OptionList.Add('yes');
  OptCreate('RandModePRoot', 'fixedArray', RandModePRoot);
  RandModePRoot.OptionList.Add('fixedArray');
  // Array wird vor Wachstum mit Zufallsz. gefüllt
  RandModePRoot.OptionList.Add('freeDraw'); // wie bisher: Methode RandUnif
  OptCreate('GrowthRatePW', 'monomol1', GrowthRatePW);
  GrowthRatePW.OptionList.Add('monomol1');
  GrowthRatePW.OptionList.Add('monomol2');
  GrowthRatePW.OptionList.Add('const');
  GrowthRatePW.OptionList.Add('exponent');
  GrowthRatePW.OptionList.Add('logist');
  GrowthRatePW.OptionList.Add('expolin');
  OptCreate('CVMode', 'slidingav', CVMode);
  CVMode.OptionList.Add('slidingav');
  CVMode.OptionList.Add('nosmooth');
  OptCreate('CVConsidCells', 'allcells', CVConsidCells);
  CVConsidCells.OptionList.Add('allcells');
  CVConsidCells.OptionList.Add('cellswithroots');

  OptCreate('DrawPCroissLR', 'pagesorg', DrawPCroissLR);
  DrawPCroissLR.OptionList.Add('pagesorg');
  DrawPCroissLR.OptionList.Add('lognorm');
  DrawPCroissLR.OptionList.Add('loganlauf');
  { Zusätzliche Pfade für Pages Modell 1: dynamische Kopplung mit 2D Strukturmodell
    Pfad: E:\ForP\Entwürfe_Doktorarbeit\ArtikelPages\Modell_Art\IniFilesAusgaben }
  AggrRootData.OptionList.Add('Q:\Kohl\StruktModell\IniOutaggrRootData.csv');
  AggrRootData.OptionList.Add('Q:\Kohl\StruktModell\IniOut\aggrRootData.csv');
  IntersectFile.OptionList.Add('Q:\Kohl\StruktModell\IniOutIntersect.csv');
  // Erzeugen Externe Var.
  ExternVCreate('DMRootDT', '[g]', StateField, DMRootDT);
  ExternVCreate('Temp', '[°C]', StateField, Temp);
  ExternVCreate('SRL', '[cm g^-1]', StateField, SRL);

  OptCreate('calcDistrAxis', 'yes', calcDistrAxis);
  calcDistrAxis.OptionList.Add('yes');
  calcDistrAxis.OptionList.Add('no');

  OptCreate('GrowthRateSW', 'monomol1', GrowthRateSW);
  GrowthRateSW.OptionList.Add('monomol1');
  GrowthRateSW.OptionList.Add('monomol2');

  OptCreate('ShowGrowth', 'yes', showGrowth);
  showGrowth.OptionList.Add('yes');
  showGrowth.OptionList.Add('no');

end;

procedure TSubmodRootStrucNew.init(var GlobModReferenz: TMod);
begin
  inherited;
end;

procedure TSubmodRootStrucNew.AddDataValueToDataSeries;
{ -------------------------------------------------------------------------------
  Überschriebene Methode von TSubmodel: wird als Ersatz für die Abarbeitung der
  init-Methode verwendet, bietet den Vorteil, dass diese Methode nur einmal zu
  BEGINN jedes Modelllaufs betreten wird, init: mehrfaches Betreten zu Beginn und
  nach Beendigung des Modellaufs
  Methode deswegen gut für Dateizugriffe und Aufräumarbeiten geeignet,
  die zu Beginn eines Modellaufs durchzuführen sind.
  -------------------------------------------------------------------------------- }
var
  ARootSystem: TRootsystem;
  NumberGrid_x, NumberGrid_y, i, j, k, rowsRight, rowsLeft, plantsAbove,
    plantsBelow: integer;
  halfDistanceInRows, leftBorder, rightBorder, frontBorder, rearBorder: double;

begin
  inherited;
  numberEmission.v := 0;
  EmissPerPlant.v := 0;
  NumberTotalEmission := 0;
  if stochasticGrowth.Option = 'yes' then
    randomize
  else
    RandSeed := 0;
  newStart := true;
  halfDistanceInRows := SpaceWithinRows.v / 2;
  NummerSeg := 0;
  dummyGrowth := false;
  // Bekanntmachen der Dimensionen des Weltwürfels
  dim_X := DimX.v;
  dim_Y := DimY.v;
  dim_Z := DimZ.v;
  FormShowGrowth.setDimX(trunc(DimX.v));
  FormShowGrowth.setDimy(trunc(DimY.v));
  FormShowGrowth.setDimZ(trunc(DimZ.v));
  // Für Einzelreihe: Begrenzung des Drillens
  leftBorder := 0 + BordLeftFront.v;
  rightBorder := DimX.v - BordRightBehind.v;
  frontBorder := 0 + BordLeftFront.v;
  rearBorder := DimY.v - BordRightBehind.v;
  // Array mit Schichtdicken der Kompartimente initialisieren
  setLength(GaugeArr, trunc(NumCompToCalc.v + 2));
  GaugeArr[0] := border1stLayer.v;
  for i := 1 To high(GaugeArr) - 1 do
  begin
    GaugeArr[i] := GaugeStandardSeg;
  end;
  GaugeArr[high(GaugeArr)] := GaugelastSeg;
  // Evtl. vorhandene Listen und Wurzelsysteme zurücksetzen (Speicherfreigabe!!!!)
  destroyRootSystems(RSList);
  resetSMLists;
  // Dateien vor Modellauf löschen und neu anlegen
  resetFiles;
  FormShowGrowth.resetLists;
  // Beim Starten der Simulation tritt FormShowGrowth in den Vordergrund
  FormShowGrowth.show;
  // Löschen der Ausgabefenster
  FormShowGrowth.MathImageRoot.clear;
  FormShowGrowth.MathImWAP.clear;
  { Vorbereitungen der Zeichnungsfläche für die Ausgabe }
  FormShowGrowth.MathImageRoot.Pen.Color := clred;
  { Funktion zeichnet die Achsen an der Grenze der Weltbox, labelt die Achsen, legt
    die Dicke und die Position der Achsen ab. }
  FormShowGrowth.MathImageRoot.d3DrawAxes('x', 'y', 'z', 10, 10, 10, 0,
    0, 0, true);
  { Zeichnen der gesamten Weltbox als 'wire frame' }
  FormShowGrowth.MathImageRoot.d3DrawFullWorldBox;
  depthplane := FormShowGrowth.getDepthPlane;
  // Aufspannen der Ebene
  createPlane(depthplane);
  // Einstellen der Weite des Rastergitters für Berechn. aggr. Wurzeldaten
  gridWidth_ := strtoint(gridWidth.Option);
  posRelOrigin := 0;
  // Berechnen der Reihen, die sich links und rechts von der Aussaatreihe befinden:
  rowsLeft := trunc(PosXPlant.v / RowSpace.v);
  rowsRight := trunc(-(PosXPlant.v - DimX.v) / RowSpace.v);
  { Berechnen der Aussaatpos. der Pflanzen, die sich oberhalb und unterhalb von der
    mittigen Pflanze befinden: }
  plantsAbove := trunc(PosYPlant.v / SpaceWithinRows.v);
  plantsBelow := trunc(-(PosYPlant.v - DimY.v) / SpaceWithinRows.v);
  // Zuweisen von Parametern in die Pages-Arrays
  assignParameter;
  if (modelQuality.Option = 'low') then
  { einfachste Modellvariante: Berechnung von Einzelreihe und Bestand erfolgt auf-
    grund der Simulation einer Einzelpflanze }
  begin
    ARootSystem := TRootsystem.create;
    ARootSystem.RS_ID := 0;
    ARootSystem.SeetPosX := trunc(PosXPlant.v);
    ARootSystem.SeetPosY := trunc(PosYPlant.v);
    ARootSystem.aktIndRandArray := 0;
    // Füllen der Arrays mit Zufallszahlen
    if RandModePRoot.Option = 'fixedarray' then
    begin
      for k := 0 to maxRandomPW - 1 do
      begin
        ARootSystem.setRandomArr(k, FRandUnif);
      end;
    end;
    RSList.Add(ARootSystem);
  end
  else if self.modelQuality.Option = 'middle' then
  { Modellvariante: Zunächst wird eine Querreihe (Abstand der Pflanze gleich
    Reihenabstand, Aussaat in x-Richtung nach links und rechts, bis Grenzen des Be-
    obachtungsraums erreicht) modelliert. }
  begin
    ARootSystem := TRootsystem.create;
    ARootSystem.SeetPosX := trunc(PosXPlant.v);
    ARootSystem.SeetPosY := trunc(PosYPlant.v);

    RSList.Add(ARootSystem);
    ARootSystem.RS_ID := 0;
    for i := 0 to rowsRight - 1 do
    begin
      // Außerhalb des Würfels wird nicht gedrillt:
      // if PosXPlant.V+((i+1)*RowSpace.V) <= dimX.V then
      if PosXPlant.v + ((i + 1) * RowSpace.v) <= rightBorder then
      begin
        ARootSystem := TRootsystem.create;
        ARootSystem.SeetPosX := PosXPlant.v + ((i + 1) * RowSpace.v);
        if self.RelocateSowPoints.Option = 'yes' then
          ARootSystem.SeetPosY := PosYPlant.v + (random * halfDistanceInRows)
        else
        begin
          ARootSystem.SeetPosY := PosYPlant.v;
        end;
        RSList.Add(ARootSystem);
        ARootSystem.RS_ID := RSList.IndexOf(ARootSystem);
      end;
    end;
    for i := 0 to rowsLeft - 1 do
    begin
      // Außerhalb des Würfels wird nicht gedrillt, auf der Grenze schon:
      // if PosXPlant.V-((i+1)*RowSpace.V) >= 0 then
      if PosXPlant.v - ((i + 1) * RowSpace.v) >= leftBorder then
      begin
        ARootSystem := TRootsystem.create;
        ARootSystem.SeetPosX := PosXPlant.v - ((i + 1) * RowSpace.v);
        ARootSystem.SeetPosY := PosYPlant.v;
        RSList.Add(ARootSystem);
        ARootSystem.RS_ID := RSList.IndexOf(ARootSystem);
      end;
    end;
  end;
  if self.modelQuality.Option = 'high' then
  { Modellvariante: Zunächst wird eine Einzelreihe modelliert. Aussaat in y-Rich-
    tung }
  begin
    ARootSystem := TRootsystem.create;
    ARootSystem.SeetPosX := trunc(PosXPlant.v);
    ARootSystem.SeetPosY := trunc(PosYPlant.v);
    RSList.Add(ARootSystem);
    ARootSystem.RS_ID := 0;
    { Berechnen der Aussaatpos. der Pflanzen, die sich oberhalb und unterhalb von der
      mittigen Pflanze befinden: }
    for i := 0 to plantsAbove do
    begin
      // if PosYPlant.V+((i+1)*SpaceWithinRows.V)<=dimY.V then
      if PosYPlant.v + ((i + 1) * SpaceWithinRows.v) <= rearBorder then
      begin
        ARootSystem := TRootsystem.create;
        ARootSystem.SeetPosX := PosXPlant.v;
        ARootSystem.SeetPosY := PosYPlant.v + ((i + 1) * SpaceWithinRows.v);
        RSList.Add(ARootSystem);
        ARootSystem.RS_ID := RSList.IndexOf(ARootSystem);
      end;
    end;
    for i := 0 to plantsBelow do
    begin
      // if PosYPlant.V-((i+1)*SpaceWithinRows.V)>=0 then
      if PosYPlant.v - ((i + 1) * SpaceWithinRows.v) >= frontBorder then
      begin
        ARootSystem := TRootsystem.create;
        ARootSystem.SeetPosX := PosXPlant.v;
        ARootSystem.SeetPosY := PosYPlant.v - ((i + 1) * SpaceWithinRows.v);
        RSList.Add(ARootSystem);
        ARootSystem.RS_ID := RSList.IndexOf(ARootSystem);
      end;
    end;
  end;
  // Initialisierung für alle WS
  for i := 0 to RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    for j := 0 to NumberINTMAX - 1 do
    begin
      ARootSystem.AnglesInt[j] := 2 * Pi * FRandUnif();
    end;
    // Jedes WS hat eigene Zähler für Anzahl der prod. Segmente etc.
    ARootSystem.NumberSegProd := 0;
    ARootSystem.NumberPrimaryRoots := 0;
    ARootSystem.NumberMerisDest := 0;
    ARootSystem.NumCurrentEmission := -1;
  end;
  if mode.Option = 'crop' then
    numberPlants.v := (DimX.v / RowSpace.v) * (DimY.v / SpaceWithinRows.v);
  if mode.Option = 'singleplant' then
    numberPlants.v := 1;
  if mode.Option = 'singlerow' then
  begin
    // bei der Low-Variante wird angenommen, dass die Reihe parallel zur Y-Achse verläuft.
    if self.modelQuality.Option = 'low' then
      numberPlants.v := (DimY.v / SpaceWithinRows.v)
    else
      numberPlants.v := RSList.Count;
  end;
  if ContGrowth.Option = 'yes' then
  begin
    ContainerCenter[0] := PosXPlant.v;
    ContainerCenter[1] := PosYPlant.v;

  end;
  NumberGrid_x := trunc(DimX.v / gridWidth_);
  NumberGrid_y := trunc(DimY.v / gridWidth_);
  // Festlegen der Arraygrenzen für Berechnung mit aggregierten Daten
  setLength(arrAggrRootArrayLayer, NumberGrid_x, NumberGrid_y);
  numbMeris := 0;
end;

procedure TSubmodRootStrucNew.CalcRates;
var
  i: integer;
  ARootSystem: TRootsystem;
begin
  // inherited;
  // Längenzuwachs im Zeitschritt zurücksetzen
  // Wachstum erst ab Aussaat
  if Globmod.Time.v >= trunc(sowingDate.v) then
  begin
    resetWLD_VK;
    numbRoots.v := 0;
    for i := 0 to RSList.Count - 1 do
    begin
      ARootSystem := RSList.Items[i];
      ARootSystem.RootLengthdt := 0;
    end;

    // DeepestIntersection.v:=0; //Brauch ich wohl nicht, da Pkt. erhalten bleiben
    // Evtl. wg. Performance machen
    { for i:=0 to high(SoiltempArr) do
      begin
      SoiltempArr[i]:=0;             //sicherheitshalber
      SoiltempArr[i]:=SoilTempArray[i].v;
      end;
      self.Tempakt:=Temp.v;
      self.RootDMdtakt:=self.DMRootdt.v; }
  end;

end;

procedure TSubmodRootStrucNew.integrate;
type
  PPoint = ^TPoint;
var
  i, j: integer;
  ASegment: TSegment;
  currentPos: double;
  turnDirection: boolean;
  AIntersection, SRP: TSRP;
  APoint: PPoint;
  Point: TPoint;
  ARootSystem: TRootsystem;
begin
  { Bei Bedarf Festlegen einer dynamischen spez. WL }
  if SRL_input.Option = '2_const' then
  begin
    if Globmod.Time.v < TransfSand_NL.v then
    begin
      SpezRL.v := spezRL_Sand.v;
    end
    else
      SpezRL.v := spezRL_NL.v;
  end;
  if SRL_input.Option = 'from_file' then
  begin
    SpezRL.v := self.SRL.v;
  end;
  if Globmod.Time.v >= trunc(sowingDate.v) then
  begin
    try
      begin
        FormShowGrowth.show;
        FormShowGrowth.showAxes;
        // Wurzel wachsen nur, wenn Baustoffe vorhanden oder wenn pot. Wachstum eingestellt ist
        if unlinkRS.Option = 'yes' then
          DMRootDT.v := 0;
        if (DMRootDT.v > 0) or (self.enablePotentGrowth.Option = 'yes') then
        begin
          // Löschen der Listen mit Zeigern auf alle Segmente (objekte bleiben erhalten)
          for i := 0 to RSList.Count - 1 do
          begin
            ARootSystem := RSList.Items[i];
            if ARootSystem.SegListTotal.Count > 0 then
              ARootSystem.clearSegListTotal;
            // wg. Zerstören der zusammengesetzten Segmente
            // ARootSystem.SegListTotal.Clear;
            ARootSystem.SegListTotalDisp.clear;
          end;
          clearSMLists;
          // alte Einträge in der SRPList zerstören
          destroySRPListContent;
          SRPList.clear;
          ZahlSegPW.v := 0;
          ZahlSegE1.v := 0;
          ZahlSegE2.v := 0;
          ZahlSegE3.v := 0;
          potWL_RSdt := 0; // sicherheitshalber
          // In jedem Zeitschritt ist der Reduktionsfaktor für Wurzelwachstum zunächst 1
          Red_WL.v := 1;
          // Folgendes nicht in init, da veränderlich
          if Type_DMRoot.Option = 'm^2' then
          begin
            RootDMWSdt.v := DMRootDT.v / numberPlants.v;
          end
          else
            RootDMWSdt.v := DMRootDT.v;
          // iteratives Verfahren für die Ermittlung des Red-Faktors für Wurzelwachstum
          // calcRedFWW;
          { Nach dem Drücken des RunButtons ist es klar, für welche Schicht VK und WLD
            berechnet werden soll }
          turnDirection := false;
          // Start beim Ort der Aussaat
          currentPos := PosYPlant.v;
          plane := FormShowGrowth.getPlane;
          main(3, 'a');
          fillIntersectList;
          // Berechnung für Einzelpflanze findet auf jeden Fall statt
          createPlane(depthplane);
          calcIntersect;
          { Erklärung des Algorithmus für die Simulation von Bestand:
            Aus der Qualitätsstufe middle lässt sich KEINE Einzelreihe simulieren
            Zunächst wird eine Ebene durch den Aussaatpunkt gespannt (Parallel zur Vorder-
            kante des Weltwürfels. Im Falle der Qualitätsstufe middle (=Simulation von
            jeweils einer Planze pro Reihe) müssen weitere Ebenen gespannt werden, die sich
            im Abstand spaceWithinRows von der Ausgangsebene befinden. Im Falle der
            Qualitätsstufe high muss die Ebene noch im Reihenabstand nach links und rechts
            verschoben werden (entspricht verschieben der X-Werte der WAP). Für Qualitätsstufe
            low muss beides geschehen. }
          if (mode.Option <> 'singleplant') and (plane = vertikal) then
          begin
            { Berechnungen für Einzelreihen und Bestand zunächst nur für vertikale Querschnittsebene }
            { begin
              //Start beim Ort der Aussaat
              currentPos:=PosYPlant.V;
              //Dort eine Ebene legen:
              createPlane(currentPos);
              calcIntersect;
              end; }
            { Simulation eines Bestandes Verschieben der Ebenen entlang der y-Achse notwendig
              bei den Qualitätten Middle und low; Im Falle von Low hat man damit eine Einzel-
              reihe erreicht, im Falle von Middle den Bestand }
            if (mode.Option = 'crop') and (modelQuality.Option = 'low') or
              (modelQuality.Option = 'middle') then
            begin
              // Weitere Ebenen erzeugen:
              for i := 0 to RSList.Count - 1 do
              begin
                { if SegListIntersect<> nil then
                  SegListIntersect.Clear; }
                { Ebene wird stufenweise (in Schritten die dem Pflanzenabstand in der Reihe ent-
                  sprechen) in Richtung auf den Nullpunkt der y-Achse hin bewegt. }
                if (currentPos > 0) and (turnDirection = false) then
                begin
                  currentPos := PosYPlant.v - i * SpaceWithinRows.v;
                  createPlane(currentPos);
                  calcIntersect;
                end;
                if (currentPos < 0) then
                begin
                  currentPos := PosYPlant.v;
                  turnDirection := true;
                end;
                { Ebene wird stufenweise (in Schritten die dem Pflanzenabstand in der Reihe ent-
                  sprechen) in Richtung auf den Endpunkt der y-Achse hin bewegt. }
                if (currentPos < dim_Y) and (turnDirection = true) then
                begin
                  currentPos := PosYPlant.v + i * SpaceWithinRows.v;
                  createPlane(currentPos);
                  calcIntersect;
                end
              end;
            end; { End if (mode.Option='crop') and (modelQuality.Option='low')
              or (modelQuality.Option='middle') }
            { Simulation eines Bestandes:  Verschieben der Ebenen entlang der x-Achse notwendig
              bei den Qualitätten high und low; damit wird ein Bestand bei beiden Qualitäten er-
              reicht, im Falle von low stimmt das, da im Vorfeld eine Verschiebung entlang der
              y-Achse bereits erfolgte. }
            if (mode.Option = 'crop') and
              ((modelQuality.Option = 'high') or (modelQuality.Option = 'low'))
            then
            begin
              singleRowToCrop;
            end;
          end; // End if (mode.Option <> 'singleplant') and (plane = vertikal)
          // Simulation von Einzelreihe für horizontale Querschnittsebene und Quali low
          if (mode.Option = 'singlerow') and (plane = horizontal) and
            (modelQuality.Option = 'low') then
          begin
            extendToSinglerowLow;
          end;
          // Simulation von Bestand für horizontale Querschnittsebene
          if (mode.Option = 'crop') and (plane = horizontal) then
          begin
            extendToCrop;
          end;
          { -------------------------------------------------------------------------------
            Berechnung von Zustandsvariablen und Variablen
            ------------------------------------------------------------------------------- }
          // a) Berechnung von Daten für den ganzen WW
          calcRootDataWorldCube;
          // b) schichtenbezogene Daten
          if RLDMode.Option = 'intersect' then
          // Ausgehend von Wurzelschnittpunkten
          begin
            calcWLD_VK_AggregData;
          end;
          if RLDMode.Option = 'rootlength' then // Ausgehend von Segmentlängen
          begin
            calcWL_Layer;
            calcWLD;
          end;
          if RLDMode.Option = 'both' then
          begin
            calcWL_Layer;
            calcWLD_VK_AggregData;
            calcWLD;
          end;

          // c) Berechnet Mittelwerte, z.B. bezogen auf Ent-Ord.
          calcDerivedData;
          // d)Berechnen Verzweigungsdichte (auf Vorrat programmiert)
          // calcBranchDens;
          { -------------------------------------------------------------------------------
            Berechnung von Zustandsvariablen und Variablen Ende
            ------------------------------------------------------------------------------- }
          // Ausgabe der XY-Koordinatein in Datei
          writeIntersectList;
          // Übergabe der Liste mit den Schnittpunkten an das Formular
          if showGrowth.Option = 'yes' then
          begin
            FormShowGrowth.setSRPList(SRPList);
            // Zeichnen in TMathImWAP
            FormShowGrowth.showVoronoiPolygon;
          end;
          // Ausgabe der aggregierten Wurzeldaten in eine Datei
          { wird bereits ind der Methode calcWLD_VK_AggregData erledigt }
          // writeAggregatedData;

          // Berechnung aktueller WL und TM
          // Voronoi
          { Var 1: Es wird in jedem Zeitschritt auch gezeichnet. }
          // Testen Voronoi: Zeichne 5 Punkte
          { for i:=0 to 5 do
            begin
            new(APoint);
            Point.x:=5+i*trunc(random*50);
            Point.y:=5+i*i*trunc(random*50);
            self.VorTest.Add(APoint);
            fPaintBox.CanCalcVoronoi(self,Point.x,Point.y);
            end; }
          { if SRPList.count>0 then
            begin
            for i:=0 to SRPList.count do
            begin
            SRP:=SRPList.Items[i];
            //Point:=transfFloatToInteger(SRP.x,SRP.y);
            //updateVoronoi(Point.x,Point.y);

            end;
            end; }
          { Voronoi Var 2: Nur am Ende der Simulation gebt es Ausgabe: muss noch mit
            alternativer calculVoronoi realisiert werden }

        end;
        for i := 0 to SRPList.Count - 1 do
        begin
          AIntersection := SRPList.Items[i];
          if plane = vertikal then
          begin
            if (AIntersection.y >= 0) and (AIntersection.y <= DimZ.v) then
              numbRoots.v := numbRoots.v + 1;
          end;
          if plane = horizontal then
          begin
            if (AIntersection.y >= 0) and (AIntersection.y <= DimY.v) then
              numbRoots.v := numbRoots.v + 1;
          end;
        end;
        // self.calcRootingdepth; //Tiefe jetzt bei Wachstum berechnet.
        // Am Ende jedes Zeitschritts bei Bedarf Schreiben von Infos über die Segmente:
        if self.WriteSegFile.Option = 'yes' then
        begin
          // CAVE: WRITESEGINFO FUNKTIONIERT NICHT KORREKT; SEGMENTE WERDEN DOPPELT GESCHRIEBEN:
          writeSegInfo;
        end;
        // Ausgabeformular kennt die aktuellen Segemente ebenfalls
        if showGrowth.Option = 'yes' then
        begin
          FormShowGrowth.setSegListWS(SegListWS);
          FormShowGrowth.setPotSegList(PotSegListTot);
        end;
        if self.drawMode.Option = 'coordseg' then
        begin
          if showGrowth.Option = 'yes' then
            FormShowGrowth.RePaintRootSystem;
        end;
        // debuggen
        if debugging = true then
        begin
          for i := 0 to self.RSList.Count - 1 do
          begin
            ARootSystem := RSList[i];
            for j := 0 to ARootSystem.SegListTotal.Count - 1 do
            begin
              ASegment := ARootSystem.SegListTotal[j];
              showMessage('SegLength RS ' + inttostr(i) + ': ' +
                floattostr(ASegment.SegLength));
            end;
          end;
        end;
      end; // End Schutz-Block

    finally

    end;
  end;
end;

constructor TSubmodRootStrucNew.create(aowner: TComponent);
var
  f, faggr, fseg: TextFile;
  headerpot, headerMeris: string;
begin
  inherited create(aowner);
  { Erzeugen des Ausgabeformulars }
  FormShowGrowth := TFormShowGrowth.create(self);
  // Ausgabedatei für XY-Koordinaten wird erzeugt
  assignfile(f, IntersectFile.Option);
  rewrite(f);
  closefile(f);
  // Ausgabedatei für Segmente wird erzeugt
  assignfile(fseg, SegFile.Option);
  rewrite(fseg);
  closefile(fseg);
  // Ausgabedatei für aggregierte Wurzeldaten wird erzeugt
  assignfile(faggr, AggrRootData.Option);
  rewrite(faggr);
  closefile(faggr);
  // Ausgabedatei für Segmentnummern
  SegNumberFile := 'Q:\Kohl\StruktModell\IniOutSegNumb.txt';
  // Ausgabedatei für pot. Verzweigungspunkte
  PotFile := 'Q:\Kohl\StruktModell\IniOut\PotNum.csv';
  MerisFile := 'Q:\Kohl\StruktModell\IniOut\MerisInfo.csv';
  assignfile(fSegNumb, SegNumberFile);
  rewrite(fSegNumb);
  closefile(fSegNumb);
  assignfile(fpotFile, PotFile);
  rewrite(fpotFile);
  assignfile(fMerisFile, MerisFile);
  rewrite(fMerisFile);
  // Header
  headerpot := 'Seg.Nr.' + ',' + 'Co.0' + ',' + 'Co.1' + ',' + 'Co.2';
  writeln(fpotFile, headerpot);
  closefile(fpotFile);
  // Header Meris
  headerMeris := 'Meris-Nr.' + ',' + 'Order' + ',' + 'DirGr_0' + ',' + 'DirGr_1'
    + ',' + 'DirGr_2' + ',' + 'DistBase' + ',' + 'basNVZ' + ',' +
    'AktSegLength';
  writeln(fMerisFile, headerMeris);
  closefile(fMerisFile);
  NummerSeg := 0;
  // DummySegment für die allg. Verwendung
  ADummySeg := TSegment.create;
  ADummyForPseudoSeg := TSegment.create;
  // ACopyOfFirstRootSystem:=TRootsystem.create;
end;

procedure TSubmodRootStrucNew.main(argc: integer; argv: char);
{ -------------------------------------------------------------------------------
  Hauptprozedur, grundlegende Ablaufsteuerung (entspricht Main aus der Pages-Vor-
  lage), Argumente werden nicht verwendet
  ------------------------------------------------------------------------------- }
var
  NumPrim, memNummerSeg: integer;
begin
  // SimTime:=trunc(GlobMod.Time.v-Globmod.Starttime);
  SimTime := trunc(Globmod.Time.v - sowingDate.v);
  { Rapaint ist in jedem Zeitschritt notwendig, damit die Ausgabe aktualisiert wird. }
  // if showGrowth.Option='yes' then
  FormShowGrowth.Repaint;
  (* printf("Temps : %4d \n",Temps); *)
  { Die Anzahl der möglw. Emissionen oder Internodium (Problem) wird in Abhängigkeit
    von der Temperatursumme für jeden Zeitschritt berechnet. }

  // In jedem Zeitschritt wird die aktuellen Zeit in der Statuszeile ausgegeben
  FormShowGrowth.StatusBar1.Panels[0].text := 'Zeit nach Aussaat: ' +
    floattostr(SimTime);
  NumEPredict := CalcNumEPredict(calcTempSumAir(SimTime));
  (* printf("<ntrenoeud d'emission : %d\n",NumEEmissionCourante); *)
  { Ausgaben in der Statuszeile: }
  // FormShowGrowth.StatusBar1.Panels[1].text := ' entrenoeud d´emission : '+FloatToStr(NumEEmissionCourante);
  // FormShowGrowth.StatusBar1.Panels[2].text := ' Numberre d´apex :  '+FloatToStr(NumberPrimaryRoots-NumberMerisDet);
  FormShowGrowth.StatusBar1.Panels[1].text := 'Anzahl Emissionen  : ' +
    floattostr(NumberTotalEmission);
  // FormShowGrowth.StatusBar1.Panels[2].text := ' Anzahl Wurzelspitzen :  '+FloatToStr(NumberPrimaryRoots-NumberMerisDet);
  { Vgl. Endnode Label 11, S.609: Die Wurzeln werden sukzessive von der Basis zur
    Spitze 'emittiert'. An einem geg. Internodium beginnt die Neuanlage erst dann,
    wenn das vorhergehende Internodium fertiggestellt ist Solange das letzte
    Internodium nicht erreicht ist und solange die vorhergesagte Nummer des
    Internodiums größer als das vorhergesagte ( = zufällig ausgewählte) Internodium
    ist Internodium. d.h. eine Emission tritt dann auf, wenn die Nummer des
    vorhergesagten Internodiums größer als die Nummer des aktuellen Internodiums ist
    Problem: was geschieht am letzten Internodium ???? }
  { Zwischenspeichern der Anzahl der Segmente, da diese im Dummy Growth gesteigert
    werden. }
  memNummerSeg := NummerSeg;
  if self.enablePotentGrowth.Option = 'no' then
    RS_DummyGrowth;
  // Berechnen des Wachstumsfaktors (Umrechnung von m^2 auf Pflanze bereits erfolgt):
  if (RootDMWSdt.v > 0) and (potTM_RSdt > 0) then
  begin
    Red_WL.v := RootDMWSdt.v / potTM_RSdt;
  end;
  if RootDMWSdt.v >= potTM_RSdt then
    Red_WL.v := 1;
  { in Abhängigkeit vom Schalter wird das Wurzelwachstum von der vorhandenen
    allozierten Trockenmasse entkoppelt, d.h. potentielles Wachstum wird erlaubt: }
  if self.enablePotentGrowth.Option = 'yes' then
  begin
    Red_WL.v := 1;
  end;
  NummerSeg := memNummerSeg;
  RS_Growth;
end;

procedure TSubmodRootStrucNew.RS_Growth;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: zentrale Methode
  ------------------------------------------------------------------------------ *)
var
  NumPrim, i, j: integer;
  ARootSystem: TRootsystem;
  ASegment, ASegmentForTotList: TSegment;
begin
  if dummyGrowth = true then
  { Im Falle des DummyGrowth wird nicht gezeichnet und nur 1 WS berechnet }
  begin
    ARootSystem := RSList.Items[0];
    { Entwicklungsvorgang 1: Emission von Primärwurzeln, Neuanlage einer Primärwurzel
      erst, wenn die Emission am vorherigen Internodium abgeschlossen ist. Es werden
      also zuerst im Internodium 0 Primärwurzeln (=seminale Wurzeln) angelegt, dann im
      Internodium 1 und so fort, Wenn alle (NumberINTMAX) Internodien Primärwurzeln
      angelegt haben, dann ist Schluss. NumEPredit wird in Abhängigkeit von der Tem-
      peratursumme vorhergesagt }
    if self.TempSumAir.v > 0 then // ohne Temperatur kein Emission
    begin
      while ((NumEPredict > ARootSystem.NumCurrentEmission) and
        (NumEPredict < NumberINTMAX)) do
      begin
        inc(ARootSystem.NumCurrentEmission);
        // Steigerung aktuelles Internodium für Emissionen
        for NumPrim := 1 to Par_NumberPrE[ARootSystem.NumCurrentEmission] do
        begin
          // eine Emission findet statt:
          Emission(ARootSystem.NumCurrentEmission, NumPrim, ARootSystem);
        end;
      end; // End while NumEPredit>NumEEmissionCourante etc.
    end;
    { Entwicklungsvorgang 2: Wachstum von vorhandenen Achsen: Wachstum von Segmenten,
      Neuanlage und Verzweigung von Segmenten }
    for j := 0 to ARootSystem.SegListEO.Count - 1 do
    begin
      ASegment := ARootSystem.SegListEO.Items[j];
      growthAndRamifRec(ASegment, j, ARootSystem);
    end;
    { if ASegment.Meristem<>nil then
      ASegment.Meristem.updateRemcoord; }
    { Entwicklungsvorgang 3: Nicht-aktive Meristeme werden entfernt. }
    for j := 0 to ARootSystem.SegListEO.Count - 1 do
    begin
      ASegment := ARootSystem.SegListEO.Items[j];
      delMerisNonActiv(ASegment);
    end;
  end; // End if dummyGrowth=true
  if dummyGrowth = false then
  begin
    // Wachstum jedes einzelnen Wurzelsystems bei mehreren ausgesäten Pflanzen
    // Zurücksetzen WL-Zuwachs in RS mit Index 0
    ARootSystem := RSList.Items[0];
    ARootSystem.RootLengthdt := 0;
    for i := 0 to RSList.Count - 1 do
    begin
      ARootSystem := RSList.Items[i];
      { Entwicklungsvorgang 1: Emission von Primärwurzeln, Neuanlage einer Primärwurzel
        erst, wenn die Emission am vorherigen Internodium abgeschlossen ist. Es werden
        also zuerst im Internodium 0 Primärwurzeln (=seminale Wurzeln) angelegt, dann im
        Internodium 1 und so fort, Wenn alle (NumberINTMAX) Internodien Primärwurzeln
        angelegt haben, dann ist Schluss. NumEPredit wird in Abhängigkeit von der Tem-
        peratursumme vorhergesagt }
      if self.TempSumAir.v > 0 then // ohne Temperatur kein Emission
      begin
        while ((NumEPredict > ARootSystem.NumCurrentEmission) and
          (NumEPredict < NumberINTMAX)) do
        begin
          inc(ARootSystem.NumCurrentEmission);
          // Steigerung aktuelles Internodium
          for NumPrim := 1 to Par_NumberPrE[ARootSystem.NumCurrentEmission] do
          begin
            // eine Emission findet statt:
            Emission(ARootSystem.NumCurrentEmission, NumPrim, ARootSystem);
          end;
        end; // End while NumEPredit>NumEEmissionCourante etc.
      end;
      { Entwicklungsvorgang 2: Wachstum von vorhandenen Achsen: Wachstum von Segmenten,
        Neuanlage und Verzweigung von Segmenten }
      for j := 0 to ARootSystem.SegListEO.Count - 1 do
      begin
        ASegment := ARootSystem.SegListEO.Items[j];
        growthAndRamifRec(ASegment, j, ARootSystem);
      end;
      { Entwicklungsvorgang 3: Nicht-aktive Meristeme werden entfernt. }
      for j := 0 to ARootSystem.SegListEO.Count - 1 do
      begin
        ASegment := ARootSystem.SegListEO.Items[j];
        delMerisNonActiv(ASegment);
      end;
      { Zusammenstellen einer Liste mit allen Segmenten für jedes WS in jedem Zeitschritt. }
      if ARootSystem.SegListEO <> nil then
      begin

        // ARootSystem.clearSegListTotal; //alte Liste wurde zu Beginn dt gelöscht
        ARootSystem.TotRootLengthWS := 0;
        for j := 0 to ARootSystem.SegListEO.Count - 1 do
        begin
          ASegmentForTotList := ARootSystem.SegListEO.Items[j];
          // Cave: Reihenfolge wichtig
          ARootSystem.makeSegListTotalDisp(ASegmentForTotList); // alte Methode
          ARootSystem.makeSegListTotalRekurs(ASegmentForTotList);
        end;
      end;
      // SegListWS.Add(ARootSystem.SegListTotal);
      SegListWS.Add(ARootSystem.SegListTotalDisp);
      PotSegListTot.Add(ARootSystem.PotSegListWS);
    end; // End for i:=0 to RSList.Count-1 do
  end; // End else-Zweig von if dummyGrowth=false
end; // End RSGrowth

procedure TSubmodRootStrucNew.RS_DummyGrowth;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Vorläufiges Wurzelwachstum zur Abschätzung des Reduktionsfaktors.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  ACopyOfFirstRootSystem, FirstRootSystem: TRootsystem;
  ASegment, ASegmentPrimaryRooot: TSegment;
begin
  dummyGrowth := true;
  // Kopieren der ursprünglichen RSListe
  // writeSegNumber(trunc(Globtime.V), -1, 'Kopiervorgang');//Debuggen
  // copyRootSystems; //alte, auf jeden Fall funktionierende Implement.
  ACopyOfFirstRootSystem := TRootsystem.create;
  FirstRootSystem := RSList.Items[0];
  ACopyOfFirstRootSystem.assign(FirstRootSystem);
  // Wurzelwachstum mit dem ursprünglichen Wurzelsystem.
  RS_Growth;
  // Berechnen der TM in der Segmentliste
  for i := 0 to FirstRootSystem.SegListEO.Count - 1 do
  // Zusammenstellen einer eindim. Liste aller Segmente
  begin
    ASegmentPrimaryRooot := FirstRootSystem.SegListEO.Items[i];
    FirstRootSystem.makeSegListTotalDisp(ASegmentPrimaryRooot); // alte Methode
    FirstRootSystem.makeSegListTotalRekurs(ASegmentPrimaryRooot);
  end;
  // Durchlaufen der Liste
  for i := 0 to FirstRootSystem.SegListTotal.Count - 1 do
  begin
    ASegment := FirstRootSystem.SegListTotal.Items[i];
  end;
  potWL_RSdt := FirstRootSystem.RootLengthdt;
  potTM_RSdt := potWL_RSdt / self.SpezRL.v;
  // Wurzelsysteme in der  RSList zerstören und Kopie zurückspielen
  // writeSegNumber(trunc(Globtime.V), -1, 'Zerstören');//Debuggen
  { //alte Implement.
    destroyRootSystems(self.RSList);
    //Rückkopieren der zwischengespeicherten Meristeme und Segmente
    for i:=0 to RSListCopy.count-1 do
    begin
    RSList.add(RSListCopy[i]);
    end;
    RSListCopy.clear;
    //alte Implement. Ende }
  destroyARootSystem(FirstRootSystem);
  // Zeiger umbiegen
  RSList.Items[0] := ACopyOfFirstRootSystem;
  dummyGrowth := false;
end; // End RS_DummyGrowth

procedure TSubmodRootStrucNew.calcRedFWW;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet den Reduktionsfaktor für Wurzelwachstum aufgrund der
  durch den Spross gelieferten Trockenmasse
  ------------------------------------------------------------------------------ *)
var
  // WS, das in der Mitte des Weltwürfels ausgesät wurde
  FirstRootSystem: TRootsystem;
  potRootDM, // Trockenmasse, die bei pot. Wurzelwachstum verbraucht würde
  DiffPotMinAktRootDM,
  // Differenz zwischen aktueller und pot. Wurzeltrockenmasse.
  Red_WLOld { Belegung des Reduktionsfaktors aus dem vorherigen Schleifendurch-
    lauf }
    : double;
begin
  // Aus der Methode main
  SimTime := trunc(Globmod.Time.v - Globmod.Starttime);
  NumEPredict := CalcNumEPredict(calcTempSumAir(SimTime));
  // Berechnung pot. WS-TM -akt. WS-TM
  { Beim Modus Einzelpflanze gibt es nur ein WS, das für Berechnung verwendet wer-
    den kann }
  FirstRootSystem := RSList.Items[0];
  potRootDM := FirstRootSystem.TotRootLengthWS / SpezRL.v;
  DiffPotMinAktRootDM := abs(potRootDM - RootDMWSdt.v);
  { Falls die Differenz größer als festgesetzt ist und gleichzeitig die  pot. Wurz-
    masse größer als die aktuelle WM ist. }
  if (DiffPotMinAktRootDM > Threshold_DMRoot.v) and (potRootDM > RootDMWSdt.v)
  then
  // Vermindern des Reduktionsfaktors um festgesetztes Decrement
  begin
    Red_WL.v := Red_WL.v * dl_RedFWL.v;
    Red_WLOld := Red_WL.v;
  end;
  // fals die Pot Wurzel-Trockenmasse die akt. TM unterschreitet
  if (DiffPotMinAktRootDM > Threshold_DMRoot.v) and (potRootDM < RootDMWSdt.v)
  then
  begin
    { Decrement wird um Faktor 10 vermindert, alter RedFaktor wird um dieses neue
      Decrement vermindert und die vormalige DiffPotMinAktRootDM wird verwendet (keine
      Neuberechnung), damit die Schleife erneut durchlaufen wird. }
    dl_RedFWL.v := dl_RedFWL.v * 0.1;
    Red_WL.v := Red_WLOld;
    Red_WL.v := Red_WL.v * dl_RedFWL.v
  end;
  // until DiffPotMinAktRootDM<Threshold_DMRoot.V;
end;

procedure TSubmodRootStrucNew.deleteMultipleItems(SegList: TList);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Löscht doppelte Segmente aus der Liste [hier müsste noch ein rekur-
  sives Durchlaufen von Child-Listen implementiert werden. Methode auf Vorrat, wird
  nicht verwendet.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  ASegment, ASegmentToCompare: TSegment;
begin
  for i := SegList.Count - 1 downto 0 do
  begin
    ASegment := SegList.Items[i];
    { Beginne mit dem Eintrag 'über' ASegment }
    for j := i - 1 downto 0 do
    begin
      ASegmentToCompare := SegList.Items[j];
      { Wenn Anfangs und End-Koordinaten bei beiden Segmenten gleich sind (das heißt,
        wenn die Ortsvektoren der Anfangs- und Endkoordinaten übereinstimmen, dann ent-
        ferne den Eintrag, der in der Liste am weitesten unten steht. }
      if (ASegmentToCompare.co[0] = ASegment.co[0]) and
        (ASegmentToCompare.co[1] = ASegment.co[1]) and
        (ASegmentToCompare.co[2] = ASegment.co[2]) and
        (ASegmentToCompare.ce[0] = ASegment.co[0]) and
        (ASegmentToCompare.ce[1] = ASegment.co[1]) and
        (ASegmentToCompare.ce[2] = ASegment.co[2]) then
      begin
        SegList.Delete(i);
      end;
    end;
  end;
end;

(* ------------------------------------------------------------------------------
  Methoden aus Pages-Modell
  ------------------------------------------------------------------------------ *)
procedure TSubmodRootStrucNew.Emission(internode_, NumPrim: integer;
  var ARootSystem: TRootsystem);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Emission meint Emission einer Pirmärwurzel (EO: 0), Für das Modell
  bedeutet es, dass es sich um die Anlage eines Segmentes handelt welches direkt
  der Segmentliste des WS hinzugefügt wird. Einträge in der Primären Segmentliste
  des WS entsprechen den ersten Segmenten einer Primärwurzel
  DebutListe wird demnach durch primäre Segmentliste eines jeden Wurzelsystems
  ersetzt.
  ------------------------------------------------------------------------------ *)
var
  ASegmentPrimaryRoot: TSegment;
  function_: string;
begin
  function_ := 'TSubmodRootStrucNew.Emission';
  ASegmentPrimaryRoot := TSegment.create;
  inc(NummerSeg);
  // Anlage Primärwurzeln mit f. Konsequenzen
  ASegmentPrimaryRoot.num := NummerSeg;
  ASegmentPrimaryRoot.PathLengthNum := 1;
  ASegmentPrimaryRoot.FatherID := 0; // keine Eltern
  ASegmentPrimaryRoot.Order := 0; // Primärwurzel
  // writeSegnumber(NummerSeg, -1, function_);//Debuggen
  ASegmentPrimaryRoot.Internode := internode_;
  ASegmentPrimaryRoot.RS_ID := ARootSystem.RS_ID;
  ASegmentPrimaryRoot.Meristem := TMeristem.create;
  if dummyGrowth = false then
  begin
    inc(numbMeris);
    ASegmentPrimaryRoot.Meristem.num := numbMeris;
  end;
  ASegmentPrimaryRoot.Meristem.setBasNVZ(Par_Bas_NBZ_Ord1.v);
  ASegmentPrimaryRoot.Meristem.Age := 0;
  // Problem: folgendes für alle WS ???
  inc(ARootSystem.NumberPrimaryRoots);
  // Initialisieren der Meristemparameter des Segments
  OriginOfEmission(internode_, NumPrim, ASegmentPrimaryRoot.Meristem.Coord,
    ARootSystem);
  OrientationOfEmission(internode_, NumPrim,
    ASegmentPrimaryRoot.Meristem.DirGrowth, ARootSystem);
  { Koordinaten des Segments entsprechen den Koordinaten des Meristems. Bisher
    nur Anlage }
  ASegmentPrimaryRoot.co[0] := ASegmentPrimaryRoot.Meristem.Coord[0];
  ASegmentPrimaryRoot.co[1] := ASegmentPrimaryRoot.Meristem.Coord[1];
  ASegmentPrimaryRoot.co[2] := ASegmentPrimaryRoot.Meristem.Coord[2];
  ASegmentPrimaryRoot.Meristem.Remcoord[0] :=
    ASegmentPrimaryRoot.Meristem.Coord[0];
  ASegmentPrimaryRoot.Meristem.Remcoord[1] :=
    ASegmentPrimaryRoot.Meristem.Coord[1];
  ASegmentPrimaryRoot.Meristem.Remcoord[2] :=
    ASegmentPrimaryRoot.Meristem.Coord[2];
  ASegmentPrimaryRoot.ce[0] := ASegmentPrimaryRoot.Meristem.Coord[0];
  ASegmentPrimaryRoot.ce[1] := ASegmentPrimaryRoot.Meristem.Coord[1];
  ASegmentPrimaryRoot.ce[2] := ASegmentPrimaryRoot.Meristem.Coord[2];
  // ASegmentPrimaryRoot.Meristem.NumSegProd := 0;
  ASegmentPrimaryRoot.Meristem.Order := 0;
  ASegmentPrimaryRoot.Meristem.Internode := internode_;
  ASegmentPrimaryRoot.Meristem.DistPrimInit := 0.0;
  ASegmentPrimaryRoot.Meristem.DistBase := 0.0;
  ASegmentPrimaryRoot.Meristem.Age := 0.0;
  ASegmentPrimaryRoot.isEmiss := true;
  if DrawPCroissLR.Option = 'loganlauf' then
  begin
    DrawPCroissMod(ASegmentPrimaryRoot.Meristem,
      ASegmentPrimaryRoot.Meristem.PCroiss);
  end
  else
    DrawPCroiss(ASegmentPrimaryRoot.Meristem,
      ASegmentPrimaryRoot.Meristem.PCroiss);
  DrawPRamif(ASegmentPrimaryRoot.Meristem, ASegmentPrimaryRoot.Meristem.PRamif);
  ASegmentPrimaryRoot.Meristem.Activ := true;
  ASegmentPrimaryRoot.Meristem.Maturity := true;
  ASegmentPrimaryRoot.TotNVZ := Par_AP_NBZ_Ord1.v + Par_Bas_NBZ_Ord1.v;
  ASegmentPrimaryRoot.Meristem.DistPrimInit :=
    ASegmentPrimaryRoot.Meristem.DistPrimInit - ASegmentPrimaryRoot.TotNVZ;
  // Neues erstes Primärwurzelsegment wird der Segmentliste hinzugefügt
  ARootSystem.SegListEO.Add(ASegmentPrimaryRoot);
  ARootSystem.numbAxisPW := ARootSystem.numbAxisPW + 1;
  if dummyGrowth = false then
  begin
    numberEmission.v := numberEmission.v + 1;
    EmissPerPlant.v := numberEmission.v / numberPlants.v;
    NumberTotalEmission := NumberTotalEmission + 1;
  end;
end; // End Funktion Emission

procedure TSubmodRootStrucNew.OriginOfEmission(Internode, NumPrim: integer;
  var Coord: r3; ARootSystem: TRootsystem);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:  vgl. EN Label 185: horizontaler Winkel, wird in Bezug auf die
  Anzahl der Wurzeln in einem Internodium berechnet, wobei eine gleichmäßige Ver-
  teilung um die vertikale Achse (Z-Achse) herum angenommen wird (vgl. auch die
  Bildung von Seitenwurzeln, das funktioniert ähnlich.
  AnglesInt: zufällig gezogener 'Startpunkt auf einem Kreis'
  ------------------------------------------------------------------------------ *)
var
  AngRot: double;
  CoordRef: r3;
begin
  AngRot := ARootSystem.AnglesInt[Internode] +
    (2 * Pi * NumPrim / Par_NumberPrE[Internode]);
  // CoordRef[0] := COrigPrXZ[Internode,0];
  // CoordRef[1] := COrigPrXZ[Internode,1];
  // CoordRef[2] := COrigPrXZ[Internode,2];
  CoordRef[0] := Par_OrigPrArr[Internode, 0].v;
  CoordRef[1] := Par_OrigPrArr[Internode, 1].v;
  CoordRef[2] := Par_OrigPrArr[Internode, 2].v;
  RotZ(CoordRef, Coord, AngRot);
  // folgende beiden Zeilen führen zur Rotation um den Aussaatpunkt
  Coord[0] := Coord[0] + ARootSystem.SeetPosX;
  Coord[1] := Coord[1] + ARootSystem.SeetPosY;
end;

procedure TSubmodRootStrucNew.OrientationOfEmission(internode_,
  NumPrim: integer; DirEmiss: r3; ARootSystem: TRootsystem);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet für die PW den Winkel in Bezug zur Vertikalen
  ------------------------------------------------------------------------------ *)
var
  AngRot, AngI: double;
  VInit: r3;
begin
  (* Angle par rapport a la verticale, ÜS: Winkel in Bezug zur Vertikalen, vgl.
    EN Label 185, S.149, Primary Root orientation, vertikaler Winkel *)
  AngI := DrawAngIPrim(internode_);
  VInit[0] := sin(AngI);
  VInit[1] := 0.0;
  VInit[2] := cos(AngI);
  AngRot := ARootSystem.AnglesInt[internode_] +
    (2 * Pi * NumPrim / Par_NumberPrE[internode_]);
  RotZ(VInit, DirEmiss, AngRot);
end; // End OrientationOfEmission

{ Procedure TSubmodRootStrucNew.OriginOfRamif
  (FatherMeris: TMeristem; var OriginChild:r3); }
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung des Punktes, an dem eine Verzweigung stattfindet.
  Pages Original
  ------------------------------------------------------------------------------ *)
{ begin
  FatherMeris.DistPrimInit := FatherMeris.DistPrimInit-FatherMeris.PRamif;
  OriginChild[0] := FatherMeris.Coord[0]-
  (FatherMeris.DistPrimInit*FatherMeris.DirGrowth[0]);
  OriginChild[1] := FatherMeris.Coord[1]-
  (FatherMeris.DistPrimInit*FatherMeris.DirGrowth[1]);
  OriginChild[2] := FatherMeris.Coord[2]-
  (FatherMeris.DistPrimInit*FatherMeris.DirGrowth[2]);
  end; }

Procedure TSubmodRootStrucNew.OriginOfRamif(FatherMeris: TMeristem;
  var OriginChild: r3);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung des Punktes, an dem eine Verzweigung stattfindet.
  Evtl. substDistance=Par_AP_NBZ_Ord1X.v+FatherMeris.PRamif
  ------------------------------------------------------------------------------ *)
var
  modCoord: r3;
  substDistance: double;
  ApotRam: TR3;
begin
  { if FatherMeris.Order=0 then
    substDistance:=Par_AP_NBZ_Ord1.v;
    if FatherMeris.Order=1 then
    substDistance:=Par_AP_NBZ_Ord2.v;
    if FatherMeris.Order=2 then
    substDistance:=Par_AP_NBZ_Ord3.v;
    modCoord[0]:=FatherMeris.Coord[0]-(substDistance*FatherMeris.DirGrowth[0]);
    modCoord[1]:=FatherMeris.Coord[1]-(substDistance*FatherMeris.DirGrowth[1]);
    modCoord[2]:=FatherMeris.Coord[2]-(substDistance*FatherMeris.DirGrowth[2]);
    FatherMeris.DistPrimInit := FatherMeris.DistPrimInit-FatherMeris.PRamif;
    OriginChild[0] := modCoord[0]-
    (FatherMeris.DistPrimInit*FatherMeris.DirGrowth[0]);
    OriginChild[1] := modCoord[1]-
    (FatherMeris.DistPrimInit*FatherMeris.DirGrowth[1]);
    OriginChild[2] := modCoord[2]-
    (FatherMeris.DistPrimInit*FatherMeris.DirGrowth[2]); }
  if (FatherMeris.PointsOfRam <> nil) and (FatherMeris.PointsOfRam.Count > 1)
  then
    ApotRam := FatherMeris.PointsOfRam[1];
  if ApotRam <> nil then
  begin
    FatherMeris.DistPrimInit := FatherMeris.DistPrimInit - FatherMeris.PRamif;
    OriginChild[0] := ApotRam.Koord3D[0];
    OriginChild[1] := ApotRam.Koord3D[1];
    OriginChild[2] := ApotRam.Koord3D[2];
    { if FatherMeris.PointsOfRam.Count > 1 then  //Das letzte Segment wird noch benötigt
      begin
      FatherMeris.PointsOfRam.Remove(FatherMeris.PointsOfRam.first);
      APotRam.Free;
      end;
      if FatherMeris.PointsOfRam.Count = 0 then
      FatherMeris.PotRamListEmpty:=true; }
    FatherMeris.PointsOfRam.Remove(FatherMeris.PointsOfRam[1]);
    ApotRam.Free;
  end;
end;

procedure TSubmodRootStrucNew.OrientationOfRamif(FatherMeristem: TMeristem;
  DirChild: r3);
(* ------------------------------------------------------------------------------
  Ungefähre Übersetzung: Berechnung die Normierung der Projektionsrichtung auf eine
  horizontale Ebene.
  ------------------------------------------------------------------------------ *)
var
  VAxisRot, RotDirGrowth: r3;
  NorVProjHor, AngRot: double;
begin

  NorVProjHor := sqrt((FatherMeristem.DirGrowth[0] * FatherMeristem.DirGrowth[0]
    ) + (FatherMeristem.DirGrowth[1] * FatherMeristem.DirGrowth[1]));
  if (NorVProjHor < Epsilon) then
  begin
    VAxisRot[0] := 1.0; (* initialer vertikaler Vektor *)
    VAxisRot[1] := 0.0;
    VAxisRot[2] := 0.0; (* Vecteur (1,0,0) choisi pour axe de rotation *)
  end
  else
  begin
    VAxisRot[0] := FatherMeristem.DirGrowth[1] / NorVProjHor;
    VAxisRot[1] := -FatherMeristem.DirGrowth[0] / NorVProjHor;
    VAxisRot[2] := 0.0;
  end;
  { Rotiert die Wachstumsrichtung um die Achse des Insertionswinkels }
  AngRot := DrawAngI(FatherMeristem);
  RotVect(AngRot, VAxisRot, FatherMeristem.DirGrowth, RotDirGrowth);

  (* On fait tourner RotDirCroiss autour de DirCroiss d'un angle generatrice *)
  AngRot := DrawAngGen(FatherMeristem);
  RotVect(AngRot, FatherMeristem.DirGrowth, RotDirGrowth, DirChild);
end;

procedure TSubmodRootStrucNew.Growth(ASegment: TSegment);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Wachstum des übergebenen Segments wird berechnet
  (Call by reference), wenn es ein Meristem besitzt
  ------------------------------------------------------------------------------ *)
// const  //ist jetzt Parameter
// ThresholdGrowth :double= 1.0e-1;  // wahrschl. Schwellenwert für Wachstum
var
  lengthSegPart, Elongation: double;
  NewGrowthDir: r3; // Vektor für neue Wachstumsrichtung
  i: integer;
  BeginNewPart, EndNewPart, intersectCont: r3;
  ARootSystem: TRootsystem;
  TouchPoint, // Vektor vom proj. Durchstoßpunkt container zum
  normVekt, TPCenter // Vektor vom Berührpunkt zum Containermittelpunkt
    : r2;
  TangPlane: planeVector;
  isPWandLogistOrExp: boolean;
begin
  isPWandLogistOrExp := false;
  if (ASegment.Meristem.Order = 0) and ((GrowthRatePW.Option = 'exponent') or
    (GrowthRatePW.Option = 'logist') or (GrowthRatePW.Option = 'expolin')) then
  begin
    isPWandLogistOrExp := true;
  end;
  // Falls das aktuelle Meristem aktiv bzw. reif ist
  if ((ASegment.Meristem.Activ) and (ASegment.Meristem.Maturity)) then
  begin
    Elongation := CalcElongation(ASegment.Meristem);
    { Solange die Verlängerung nicht einen bestimmten Schwellenwert überschreitet,
      ist das Meristem nicht aktiv. Macht das hier Sinn? Segment kann dann im weiteren
      Verlauf nicht weiterwachsen. Im Falle von exponent. und logist Wachstum hören
      die Primärwurzeln nicht auf zu wachsen }
    ARootSystem := RSList.Items[ASegment.RS_ID];
    ARootSystem.RootLengthdt := ARootSystem.RootLengthdt + Elongation;
    if ((Elongation < ThresholdGrowth.v) and (ASegment.Meristem.Order <> 0)) or
      ((ASegment.Meristem.Order = 0) and (isPWandLogistOrExp = false)) then
    begin
      { Segmente können die Aktivität erst nach der Reife verlieren und werden auch erst
        dann zerstört. }
      ASegment.Meristem.Activ := false;
    end
    { Muss hier nicht noch die Verlängerung des Segments, das sich nicht verzweigt,
      gezeichnet werden? }
    else
    begin
      { Falls Wachstum größer als der Schwellenwert ist, sind Segmente keine Primordien
        mehr }
      ASegment.isPrim := false;
      { Festlegung der Anfangskoordinaten des neuen Teilstücks
        Diese Entsprechen den Endkoordinaten des alten Segments (=Wurzelspitze=
        Lage des Meristems) }
      BeginNewPart[0] := ASegment.Meristem.Coord[0];
      BeginNewPart[1] := ASegment.Meristem.Coord[1];
      BeginNewPart[2] := ASegment.Meristem.Coord[2];
      CalcDirGrowth(ASegment.Meristem, NewGrowthDir, Elongation);
      ASegment.Meristem.DistPrimInit := ASegment.Meristem.DistPrimInit +
        Elongation;
      ASegment.Meristem.DistBase := ASegment.Meristem.DistBase + Elongation;
      ASegment.Meristem.sumElongNew := ASegment.Meristem.sumElongNew +
        Elongation;
      ASegment.Meristem.remainderElong := ASegment.Meristem.remainderElong +
        Elongation;
      { Ursprüngl. Quellcode
        if ((ASegment.Meristem.Order=0) and (ASegment.Meristem.Internode<2)) then
        ASegment.Meristem.PRamif := 1/(9.956*exp(-0.01888*ASegment.Meristem.DistBase));
        if (ASegment.Meristem.Order=0) and (ASegment.Meristem.Internode>= 2) then
        ASegment.Meristem.PRamif := 1/(11.51*exp(-0.01280*ASegment.Meristem.DistBase)); }
      { if ((ASegment.Meristem.Order=0) and (ASegment.Meristem.Internode<2)) then            //USL
        ASegment.Meristem.PRamif := 1/(Par_RamMod_Asem.v*exp(-Par_RamMod_Bsem.v*ASegment.Meristem.DistBase));
        if (ASegment.Meristem.Order=0) and (ASegment.Meristem.Internode>= 2) then
        ASegment.Meristem.PRamif := 1/(Par_RamMod_Acr.v*exp(-Par_RamMod_Bcr.v*ASegment.Meristem.DistBase)); }
      { Da die Wachstumsrichtung mit Zufall versehen, darf das Segment nur einmal
        wachsen (kein Dummy -Growth) es könnte sonst dazu kommen, dass beim zweiten
        Mal der container nicht durchstoßen wird. }
      // Verschieben des Meristems an neue Position
      ASegment.Meristem.Coord[0] := ASegment.Meristem.Coord[0] +
        (Elongation * NewGrowthDir[0]);
      ASegment.Meristem.Coord[1] := ASegment.Meristem.Coord[1] +
        (Elongation * NewGrowthDir[1]);
      ASegment.Meristem.Coord[2] := ASegment.Meristem.Coord[2] +
        (Elongation * NewGrowthDir[2]);
      // Wenn Wachstum im Container gewünscht und Containergrenze überschritten:
      if (ContGrowth.Option = 'yes') and
        (testBeyondContainer(ASegment, NewGrowthDir)) then
      begin
        // Reflektion an Containerwand
        TouchPoint := ContainerGrowth2D(ASegment, NewGrowthDir);
        { Normalenvektor in der Ebene: Koordinaten vertauschen und Vorzeichen ändern.
          1. Vektor von ProjSSel zum Mittelpunkt des Containers: }
        TPCenter[0] := ContainerCenter[0] - TouchPoint[0];
        TPCenter[1] := ContainerCenter[1] - TouchPoint[1];
        // 2. Bestimmung des Normvektors = Richtungsvektor für Ebene
        normVekt[0] := -TPCenter[1];
        normVekt[1] := +TPCenter[0];
        TangPlane := createTangentPlan(TouchPoint, normVekt);
        ADummySeg.co := ASegment.ce;
        ADummySeg.ce[0] := ASegment.Meristem.Coord[0];
        ADummySeg.ce[1] := ASegment.Meristem.Coord[1];
        ADummySeg.ce[2] := ASegment.Meristem.Coord[2];
        intersectCont := solveEquationSystemTang(ADummySeg, TangPlane);
        { Berechnung der Länge des Teilsegments jenseits der Containerwand }
        lengthSegPart := ADummySeg.calcAbsValue(intersectCont, ADummySeg.ce);
        { Berechnung der neuen Endposition: ab Containerpunkt klappt das Segment nach
          unten: }
        { Schnittpunkt wird um den Param. minDistWall in Richtung des Mittelpunktes verschoben: }
        intersectCont[0] := TouchPoint[0] + 1 / contRad.v * minDistWall.v *
          TPCenter[0];
        intersectCont[1] := TouchPoint[1] + minDistWall.v * TPCenter[1];
        ASegment.ce[0] := intersectCont[0];
        ASegment.ce[1] := intersectCont[1];
        ASegment.ce[2] := intersectCont[2] + lengthSegPart;
        // Verschieben des Meristems und der Wurzelspitze an neue Position
        ASegment.Meristem.Coord[0] := ASegment.ce[0];
        ASegment.Meristem.Coord[1] := ASegment.ce[1];
        ASegment.Meristem.Coord[2] := ASegment.ce[2];
      end
      else
      begin
        { Endkoordinaten des Segments entsprechen Lage des Meristems, gleichzeitig auch
          den Endkoordinaten des hinzugekommenen Teilstücks }
        ASegment.ce[0] := ASegment.Meristem.Coord[0];
        ASegment.ce[1] := ASegment.Meristem.Coord[1];
        ASegment.ce[2] := ASegment.Meristem.Coord[2];
      end; // Ende else Containergrowth
      EndNewPart[0] := ASegment.ce[0];
      EndNewPart[1] := ASegment.ce[1];
      EndNewPart[2] := ASegment.ce[2];
      // Berechnen der Länge des Zuwachses im jeweiligen RS
      // ARootSystem:=RSList.Items[ASegment.RS_ID];
      // ARootSystem.RootLengthdt:=ARootSystem.RootLengthdt+ADummySeg.calcAbsValue(BeginNewPart, EndNewPart);
      { Speichern der aktuellen Wachstumsrichtung, ist im nächsten Zeitschritt die ini
        tiale Wachstumsrichtung }
      ASegment.Meristem.DirGrowth[0] := NewGrowthDir[0];
      ASegment.Meristem.DirGrowth[1] := NewGrowthDir[1];
      ASegment.Meristem.DirGrowth[2] := NewGrowthDir[2];
      // Erhöhung des Alters des Segments um biologische Zeit im Zeitschritt
      ASegment.Meristem.Age := ASegment.Meristem.Age +
        calcTempSumSoil(trunc(Globmod.TimeStep), ASegment.Meristem.Coord[2]);
      { Kein Zeichnen im dummyGrowth, ebenfalls wird das Objekt für die Verzweigungs-
        dichte nicht bearbeitet }
      if dummyGrowth = false then
      begin
        if drawMode.Option = 'increment' then
        begin
          if showGrowth.Option = 'yes' then
            drawSegmentPart(BeginNewPart, EndNewPart,
              ASegment.Meristem.Internode);
        end;
        // Verzweigungsdichte bezogen auf Bodentiefe nur für 1. WS und Primärwurzel
        if (ASegment.Order = 0) and (ASegment.RS_ID = 0) then
        begin
        end;
      end;
      // FormShowGrowth.MathImage1.Repaint;
    end;
  end;
  if (not(ASegment.Meristem.Maturity)) then
  { Bei Unreife des Meristems:  Das biologische Alter wird so lange hoch gesetzt,
    bis ein Schwellenwert erreicht ist (=Entwicklungsdauer des Primordiums). Dann
    wird der Schalter Reife auf true gesetzt. }
  begin
    ASegment.Meristem.Age := ASegment.Meristem.Age +
      calcTempSumSoil(trunc(Globmod.TimeStep), ASegment.Meristem.Coord[2]);
    if (ASegment.Meristem.Age > (Par_DurDevPrim[ASegment.Meristem.Order,
      ASegment.Meristem.Internode] + Add_Prim.v)) then
      ASegment.Meristem.Maturity := true;
  end;
  if dummyGrowth = false then
  begin
    // Berechnen der Durchwurzelungstiefe
    if ASegment.ce[2] > depth.v then
      depth.v := ASegment.ce[2];
  end;
end; // End Prozedur Growth

// procedure TSubmodRootStrucNew.Ramification(MerisPere: Meristeme); // Verzweigung
procedure TSubmodRootStrucNew.RamificationRec(AFather: TSegment;
  PrimRootID: integer; var ARootsystem_: TRootsystem);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: simuliert eine Verzweigung, das Tochtersegment höherer Ordnung kann
  im Zeitschritt noch wachsen. Verzweigen heißt Teilen, rekursiver Aufruf
  ------------------------------------------------------------------------------ *)
var
  AChildSameOrder, AChildHigherOrder: TSegment;
  i: integer;
  function_: string;
  basNVZ_: double;
begin
  function_ := 'TSubmodRootStrucNew.Ramification';
  AChildSameOrder := TSegment.create;
  inc(NummerSeg);
  AChildSameOrder.num := NummerSeg;
  // Kind kennt seinen Vater und den Urahn (erstes Segment der Primärwurzel):
  AChildSameOrder.FatherID := AFather.num;
  AChildSameOrder.PathLengthNum := AFather.PathLengthNum + 1;
  AChildSameOrder.PrimSegId := PrimRootID;
  // writeSegnumber(NummerSeg, AFather.num, function_);//Debuggen
  AChildHigherOrder := TSegment.create;
  inc(NummerSeg);
  AChildHigherOrder.num := NummerSeg;
  AChildHigherOrder.FatherID := AFather.num;
  AChildHigherOrder.PathLengthNum := AFather.PathLengthNum + 1;
  AChildHigherOrder.PrimSegId := PrimRootID;
  // writeSegnumber(NummerSeg, AFather.num, function_);//Debuggen
  AChildHigherOrder.Meristem := TMeristem.create;
  if dummyGrowth = false then
  begin
    inc(numbMeris);
    AChildHigherOrder.Meristem.num := numbMeris;
  end;
  AChildSameOrder.Internode := AFather.Internode;
  AChildHigherOrder.Internode := AFather.Internode;
  // Kinder bekommen die RS_ID des Vaters:
  AChildSameOrder.RS_ID := AFather.RS_ID;
  AChildHigherOrder.RS_ID := AFather.RS_ID;
  OriginOfRamif(AFather.Meristem, (AChildHigherOrder.Meristem).Coord);
  { Lage des Meristems des Kindersegments höherer Ordnung entspricht
    a) der Anfangskoordinate der Kinder
    b) der Endkoordinate des Elternsegments }
  AChildHigherOrder.co[0] := AChildHigherOrder.Meristem.Coord[0];
  AChildHigherOrder.co[1] := AChildHigherOrder.Meristem.Coord[1];
  AChildHigherOrder.co[2] := AChildHigherOrder.Meristem.Coord[2];
  // Neues Segment höherer Ordnung ist nur Anlage
  AChildHigherOrder.ce[0] := AChildHigherOrder.Meristem.Coord[0];
  AChildHigherOrder.ce[1] := AChildHigherOrder.Meristem.Coord[1];
  AChildHigherOrder.ce[2] := AChildHigherOrder.Meristem.Coord[2];
  AChildSameOrder.co[0] := AChildHigherOrder.Meristem.Coord[0];
  AChildSameOrder.co[1] := AChildHigherOrder.Meristem.Coord[1];
  AChildSameOrder.co[2] := AChildHigherOrder.Meristem.Coord[2];

  { Endkoordinaten des Kindes mit derselben Ordnung entsprechen den Endkoordinaten
    des Vatersegments vor der Verzweigung }
  AChildSameOrder.ce[0] := AFather.ce[0];
  AChildSameOrder.ce[1] := AFather.ce[1];
  AChildSameOrder.ce[2] := AFather.ce[2];
  AFather.ce[0] := AChildHigherOrder.Meristem.Coord[0];
  AFather.ce[1] := AChildHigherOrder.Meristem.Coord[1];
  AFather.ce[2] := AChildHigherOrder.Meristem.Coord[2];
  // Nur das Segment höherer Ordnung hat neue Wachstumsrichtung
  OrientationOfRamif(AFather.Meristem, (AChildHigherOrder.Meristem).DirGrowth);
  AChildSameOrder.Order := AFather.Order;
  AChildSameOrder.Meristem := AFather.Meristem;
  AChildSameOrder.isPrim := AFather.isPrim;
  // Kind gleicher Ordnung 'entsteht' aus gewachsenem Vater
  AFather.Meristem := nil;
  AChildHigherOrder.Order := AFather.Order + 1;
  AChildHigherOrder.Meristem.Order := AChildSameOrder.Meristem.Order + 1;
  // AChildHigherOrder.Meristem.NumSegProd := 0;
  AChildHigherOrder.Meristem.Internode := AChildSameOrder.Meristem.Internode;
  AChildHigherOrder.Meristem.DistPrimInit := 0.0;
  AChildHigherOrder.Meristem.DistBase := 0.0;
  AChildHigherOrder.Meristem.Age := 0.0;
  if AChildHigherOrder.Meristem.Order = 1 then
  begin
    AChildHigherOrder.TotNVZ := Par_AP_NBZ_Ord2.v + Par_Bas_NBZ_Ord2.v;
    basNVZ_ := Par_AP_NBZ_Ord2.v;
    ARootsystem_.numbAxisSWEO1 := ARootsystem_.numbAxisSWEO1 + 1;
  end;
  if AChildHigherOrder.Meristem.Order = 2 then
  begin
    AChildHigherOrder.TotNVZ := Par_AP_NBZ_Ord3.v + Par_Bas_NBZ_Ord3.v;
    basNVZ_ := Par_AP_NBZ_Ord3.v;
    ARootsystem_.numbAxisSWEO2 := ARootsystem_.numbAxisSWEO2 + 1;
  end;
  if AChildHigherOrder.Meristem.Order = 3 then
  begin
    AChildHigherOrder.TotNVZ := Par_AP_NBZ_Ord4.v + Par_Bas_NBZ_Ord4.v;
    basNVZ_ := Par_AP_NBZ_Ord4.v;
    ARootsystem_.numbAxisSWEO3 := ARootsystem_.numbAxisSWEO3 + 1;
  end;
  AChildHigherOrder.Meristem.setBasNVZ(basNVZ_);
  AChildHigherOrder.Meristem.DistPrimInit :=
    AChildHigherOrder.Meristem.DistPrimInit - AChildHigherOrder.TotNVZ;
  // Nur- für Tochtersegmente höherer Ordnung gilt, dass sie den Primordiumstatus annehmen
  AChildHigherOrder.isPrim := true; // USL
  if DrawPCroissLR.Option = 'loganlauf' then
  begin
    DrawPCroissMod(AChildHigherOrder.Meristem,
      AChildHigherOrder.Meristem.PCroiss);
  end
  else
    DrawPCroiss(AChildHigherOrder.Meristem, AChildHigherOrder.Meristem.PCroiss);
  DrawPRamif(AChildHigherOrder.Meristem, AChildHigherOrder.Meristem.PRamif);
  AChildHigherOrder.Meristem.Activ := true;
  AChildHigherOrder.Meristem.Maturity := false;
  AFather.ChildList.Add(AChildSameOrder);
  AFather.ChildList.Add(AChildHigherOrder);
  { alter Quelltext
    if (AChildSameOrder.Meristem.DistPrimInit>AChildSameOrder.Meristem.PRamif)
    and (AChildSameOrder.Meristem.PointsOfRam.count>0) then
    //Erneuter Aufruf der Verzweigungsmethode, da sich ein Segment mehrfach
    //im Zeitschritt verzweigen kann.
    begin
    RamificationRec(AChildSameOrder, PrimRootID, BranchDensPrimObj_);
    end; }

  if (AChildSameOrder.Meristem.DistPrimInit <= AChildSameOrder.Meristem.PRamif)
  // if (AChildSameOrder.Meristem.DistPrimInit<=AChildSameOrder.Meristem.PRamifold)
    or (AChildSameOrder.Meristem.PointsOfRam.Count = 0) then
  begin
    // nach Abschluss der Verzweigung Update des Ramifikationsparameters
    AChildSameOrder.Meristem.PRamifold := AChildSameOrder.Meristem.PRamif;

  end;
  if (AChildSameOrder.Meristem.DistPrimInit > AChildSameOrder.Meristem.PRamif)
  // if (AChildSameOrder.Meristem.DistPrimInit<=AChildSameOrder.Meristem.PRamifold)
    and (AChildSameOrder.Meristem.PointsOfRam.Count > 0) then
  begin
    RamificationRec(AChildSameOrder, PrimRootID, ARootsystem_);
  end;
end; // End Funktion RamificationRec

function TSubmodRootStrucNew.CalcElongation(AMeristem: TMeristem): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Wachtums der Meristeme (entspricht dem
  Wachstum der Achsensegmente
  - bei zunehmendem Alter des Meristems (Segments) kommt es zu geringerem
  Segmentwachstum.
  ------------------------------------------------------------------------------ *)
var
  dt, t, A, b, Elongation, TScrit, Lcrit: double;

begin
  { wg. Pages EN # 185: Konstante Wachstumsrate für Primärwurzeln und May (1965)
    Konstante Wachstumsraten bei jungen Gerstenwurzeln. }

  dt := calcTempSumSoil(trunc(Globmod.TimeStep), AMeristem.Coord[2]);
  t := AMeristem.Age - (Par_DurDevPrim[ord(AMeristem.Order),
    AMeristem.Internode] + Add_Prim.v); (* Age Meristeme vrai *)
  A := AMeristem.PCroiss[0];
  b := AMeristem.PCroiss[1];
  // Zuweiseung der Skalierungsfaktoren
  A := A * a_scaling.v;
  { Parameter b wird im expolin. Wachstum als Koeffizient für das Wachstum im
    exponentiellen Teil verwendet. Wird im Falle der Primärwurzel nicht skaliert,
    da hier gesondert kalibriert wird. }
  if AMeristem.Order > 0 then
    b := b * b_scaling.v;

  // Berechnungen für expolin. Wachstum (Methode Excel)
  if AMeristem.Order = 0 then
  begin
    Lcrit := Par_ConstRatePW.v / b;
    TScrit := (LN(Lcrit / L0_MerisPW.v)) / b;
  end;
  { Gleichung für monomolekulares Wachstum, Typ 1, z.b. in Pages EN # 495 }
  Elongation := Red_WL.v * A * b * exp(-b * t) * dt;
  { Gleichung für Wachstum aus Pages EN # 185 }
  // Elongation := Red_WL.V*A*exp(-b*t)*dt;
  // Neuberechnung, wenn alternatives Wachstum für Primärwurzel gewünscht
  if (AMeristem.Order = 0) and (GrowthRatePW.Option = 'const') then
  begin
    Elongation := Par_ConstRatePW.v * dt;
  end;
  if (AMeristem.Order = 0) and (GrowthRatePW.Option = 'expolin') then
  begin
    { -------------------------------------------------------------------------------
      Methode Excel Analyt
      -------------------------------------------------------------------------------- }
    if t < TScrit then
    begin
      Elongation := L0_MerisPW.v * exp(b * t) - AMeristem.sumElongOld;
    end
    else
    begin
      Elongation := Lcrit + Par_ConstRatePW.v * (t - TScrit) -
        AMeristem.sumElongOld;
    end;
    { -------------------------------------------------------------------------------
      Methode Excel analyt.  Ende
      -------------------------------------------------------------------------------- }
    { -------------------------------------------------------------------------------
      Numerische Lösung
      -------------------------------------------------------------------------------- }
    { if AMeristem.sumElongOld < Par_ConstRatePW.v/rgr_expo.v then
      begin
      //Sonderfall Zu Beginn braucht sumElongOld Anfangswert
      if AMeristem.sumElongOld=0 then
      begin
      AMeristem.sumElongOld:=L0_MerisPW.v;
      end;
      Elongation := rgr_expo.v*dt*AMeristem.sumElongOld  //Exponent. Wachstum
      end
      else
      // Lineares Wachstum, Wurzelalter spielt für Wachstum keine Rolle
      Elongation := Par_ConstRatePW.v*dt; }
    { -------------------------------------------------------------------------------
      Numerische Lösung   Ende
      -------------------------------------------------------------------------------- }
  end;
  if (AMeristem.Order = 0) and (GrowthRatePW.Option = 'monomol2') then
  begin
    { Gleichung für monomolekulares Wachstum, Typ 2, z.b. in Collet EN #318,
      Vercambre EN #225 }
    Elongation := Red_WL.v * b * exp(-(b / A) * t) * dt;
  end;
  if (AMeristem.Order = 0) and (GrowthRatePW.Option = 'exponent') then
  begin
    { Gleichung für exponent. Wachstum, analyt. Lsg. }
    Elongation := L0_MerisPW.v * exp(b * t) - AMeristem.sumElongOld;
  end;
  if (AMeristem.Order = 0) and (GrowthRatePW.Option = 'logist') then
  begin
    { Gleichung für logist. Wachstum, analyt. Lsg. }
    Elongation := LmaxMerisPW.v / (1 + (LmaxMerisPW.v / L0_MerisPW.v - 1) *
      exp(-t * b)) - AMeristem.sumElongOld;
  end;
  if (AMeristem.Order > 0) and (GrowthRateSW.Option = 'monomol2') then
  begin
    { analyt. Wachstum, da bei verwendeter Zeitschrittweite und hohen Werten für Par
      b deutliche Abweichungen auftreten }
    Elongation := Red_WL.v * (A - A * exp(-(b / A * t)) -
      AMeristem.sumElongOld);
  end;
  Result := Elongation;
end; // End CalcElongation

procedure TSubmodRootStrucNew.CalcDirGrowth(Meris: TMeristem; var NewDir: r3;
  var Elongation: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet die Wachstumsrichtung
  ------------------------------------------------------------------------------ *)
var
  DirMechanicGrowth: r3;
begin
  DeflecMechanic(Meris, DirMechanicGrowth, Elongation);
  DeflecGeo(Meris, DirMechanicGrowth, NewDir, Elongation);
end; // End CalcDirGrowth

procedure TSubmodRootStrucNew.DeflecMechanic(Meris: TMeristem;
  var DirAfterMeca: r3; var Elongation: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet Ablenkung aufgrund von mechanischem Widerstand.
  ------------------------------------------------------------------------------ *)
var
  VTire, VTireN, DirInt: r3;
begin
  if (Meris.Coord[2] > DepthSubsoil.v) then (* Anisotropischer Widerstand *)
  begin
    repeat
      (* Tirage vecteur dans l'angle Teta autour de G *)
      VTire[0] := (2.0 * FRandUnif - 1.0) * sin(Pi * TetaAngl.v / 180.0);
      VTire[1] := (2.0 * FRandUnif - 1.0) * sin(Pi * TetaAngl.v / 180.0);
      repeat
        VTire[2] := FRandUnif;
      until (VTire[2] < cos(Pi * TetaAngl.v / 180.0));
      Norm(VTire, VTireN);
    until (VTireN[2] < (cos(Pi * TetaAngl.v / 180.0)));

    DirInt[0] := Meris.DirGrowth[0] +
      (3 * Elongation * VTireN[0] * Par_CMechanic[Meris.Order, Meris.Internode]
      * mech_scaling.v);
    DirInt[1] := Meris.DirGrowth[1] +
      (3 * Elongation * VTireN[1] * Par_CMechanic[Meris.Order, Meris.Internode]
      * mech_scaling.v);
    DirInt[2] := Meris.DirGrowth[2] +
      (3 * Elongation * VTireN[2] * Par_CMechanic[Meris.Order, Meris.Internode]
      * mech_scaling.v);
  end
  else (* isotropischer Widerstand *)
  begin
    VTire[0] := 2.0 * FRandUnif - 1.0;
    VTire[1] := 2.0 * FRandUnif - 1.0;
    VTire[2] := 2.0 * FRandUnif - 1.0;
    Norm(VTire, VTireN);
    if (ProdScal(VTireN, Meris.DirGrowth) < 0.0) then
    begin
      VTireN[0] := -VTireN[0];
      VTireN[1] := -VTireN[1];
      VTireN[2] := -VTireN[2];
    end;
    { Wenn zufällige Abweichung nicht gewünscht: dann
      DirInt[0] := Meris.DirGrowth[0]*(1-Par_CMechanic[Meris.Order,Meris.Internode]*mech_scaling.v);
      DirInt[1] := Meris.DirGrowth[1]*(1-Par_CMechanic[Meris.Order,Meris.Internode]*mech_scaling.v);
      DirInt[2] := Meris.DirGrowth[2]*(1-Par_CMechanic[Meris.Order,Meris.Internode]*mech_scaling.v); }
    DirInt[0] := Meris.DirGrowth[0] +
      (Elongation * VTireN[0] * Par_CMechanic[Meris.Order, Meris.Internode] *
      mech_scaling.v);
    DirInt[1] := Meris.DirGrowth[1] +
      (Elongation * VTireN[1] * Par_CMechanic[Meris.Order, Meris.Internode] *
      mech_scaling.v);
    DirInt[2] := Meris.DirGrowth[2] +
      (Elongation * VTireN[2] * Par_CMechanic[Meris.Order, Meris.Internode] *
      mech_scaling.v);
  end;
  Norm(DirInt, DirAfterMeca);
end; // End DeflecMechanic

procedure TSubmodRootStrucNew.DeflecGeo(Meris: TMeristem;
  var DirAfterMeca, DirAfterGeo: r3; var Elongation: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet Ablenkung aufgrund von Geotropismus
  ------------------------------------------------------------------------------ *)
var
  DirInt, G: r3;
  // scaledGeoFactor: double;
begin
  DirInt[0] := DirAfterMeca[0];
  DirInt[1] := DirAfterMeca[1];
  DirInt[2] := DirAfterMeca[2] + (Par_Geo[ord(Meris.Order), ord(Meris.Internode)
    ] * geo_scaling.v * Elongation);

  (* Axe poussant au dessus du niveau du sol *)
  G[0] := 0.0;
  G[1] := 0.0;
  G[2] := 1.0;
  if ((Meris.Coord[2] < GeoModRange.v) and (ProdScal(G, DirInt) < 0.0)) then
    DirInt[2] := DirInt[2] / GeoMod.v;
  Norm(DirInt, DirAfterGeo);
end; // End Fonction DeflecGeo

procedure TSubmodRootStrucNew.DrawPCroiss(var Meris: TMeristem;
  var PCroiss: r2);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung und Modifikation des Elongationsparameters A, Elongations-
  parameter B bleibt ohne Beeinflussung durch Standardabweichung.
  ------------------------------------------------------------------------------ *)
var
  ord, ent: integer;
  tire1, tire2, db, moy, et: double;
begin
  ord := Meris.Order;
  ent := Meris.Internode;
  db := Meris.DistBase;
  tire1 := FRandUnif();
  tire2 := FRandUnif();
  if (ord = 0) then
  // Berechnung bezieht sich auf den Elongationsparameter A (Ziehen aus Normalverteilung)
  begin
    PCroiss[0] := Par_GrowthAver[0, ord, ent] +
      (Par_GrowthDeviat[0, ord, ent] * sqrt(-LN(tire1)) *
      cos(Pi * tire2) * 1.414);
  end
  else
  begin
    (* ------------------------------------------------------------------------------
      Originale Implementierung auskommentiert
      ------------------------------------------------------------------------------ *)
    { if (ord=1) then
      begin
      if (db>40) then
      begin
      PCroiss[0] := 0.1*exp(2.2+(0.82*sqrt(-ln(tire1))*cos(Pi*tire2)*1.414));
      end
      else
      begin
      moy := 3.0-(0.8*db/40.0);     //ist wohl Mittelwert
      et := 1.0-(0.18*db/40.0);     //soll wohl für Standardabweichung stehen
      PCroiss[0] := 0.1*exp(moy+(et*sqrt(-ln(tire1))*cos(Pi*tire2)*1.414));
      end;
      end }
    // Alternative Implementierung für EO 1(analog zur Entwicklungsordnung 2 und höher)
    if DrawPCroissLR.Option = 'pagesorg' then
    begin
      if (ord = 1) then
      // if (ord=1) or (ord=2) then
      begin
        if db > ThresDistBase.v then
        begin
          PCroiss[0] := 0.1 * exp(Par_AverGrowthADist_Ord2.v +
            (Par_StdDevGrowthADist_Ord2.v * sqrt(-LN(tire1)) * cos(Pi * tire2)
            * 1.414));
        end
        else
        begin
          moy := ElongAStartAv_Ord2.v -
            (Par_GrowthAver[0, ord, ent] * db / ThresDistBase.v);
          et := ElongAStartDev_Ord2.v -
            (Par_GrowthDeviat[0, ord, ent] * db / ThresDistBase.v);
          // Ziehen des Wachstumsparameters A aus lognormaler Verteilung
          PCroiss[0] := 0.1 *
            exp(moy + (et * sqrt(-LN(tire1)) * cos(Pi * tire2) * 1.414));
        end;
      end
      else
        // Ziehen des Wachstumsparameters A aus lognormaler Verteilung
        PCroiss[0] := 0.1 * exp(Par_GrowthAver[0, ord, ent] +
          (Par_GrowthDeviat[0, ord, ent] * sqrt(-LN(tire1)) * cos(Pi * tire2)
          * 1.414));
    end
    else // für alle Seitenwurzeln wird der Wachstumsparameter A aus lognormaler Verteilung gezogen
    begin
      PCroiss[0] := 0.1 * exp(Par_GrowthAver[0, ord, ent] +
        (Par_GrowthDeviat[0, ord, ent] * sqrt(-LN(tire1)) * cos(Pi * tire2)
        * 1.414));
    end;
  end;
  // Elongationsparameter B bleibt unverändert
  PCroiss[1] := Par_GrowthAver[1, ord, ent];
end; // End DrawPCroiss

procedure TSubmodRootStrucNew.DrawPCroissMod(var Meris: TMeristem;
  var PCroiss: r2);
(* ------------------------------------------------------------------------------
  Modifizierte Berechnung mit alternativem Ziehen aus lognormaler Verteilung
  für die SW, Wachstumsparameter B kann auch aus lognormaler Verteilung gezogen
  werden (B beeinflusst die Änderung der Wachstumsrate mit der biolog. Zeit
  des Meristems)
  Ziehen aus Lognormaler Verteilung erfolgt nach Verfahren beschrieben in Anlauf:
  Modelle für Prozesse im Boden, S. 125 f.
  ------------------------------------------------------------------------------ *)
var
  ord, ent: integer;
  tire1, tire2, mue_lnA, sigma_lnA,
  // Verteilungsparameter für log. verteilte Werte Par. A
  mue_lnB, sigma_lnB, // Verteilungsparameter für log. verteilte Werte Par. B
  DrawStdNorm, // Zufallsvariable aus Standardnormvert.
  meanStdnorm, // Mittelwert Standardnormvert.
  stdevStdnorm // Standardabweichung Standardnormvert.
    : double;
begin
  ord := Meris.Order;
  ent := Meris.Internode;
  tire1 := FRandUnif();
  tire2 := FRandUnif();
  meanStdnorm := 0;
  stdevStdnorm := 1;
  // Wachstumsparameter A
  if (ord = 0) then
  // Berechnung bezieht sich auf den Elongationsparameter A (Ziehen aus Normalverteilung)
  begin
    PCroiss[0] := Par_GrowthAver[0, ord, ent] +
      (Par_GrowthDeviat[0, ord, ent] * sqrt(-LN(tire1)) *
      cos(Pi * tire2) * 1.414);
    // Elongationsparameter B bleibt bei PW unverändert
    PCroiss[1] := Par_GrowthAver[1, ord, ent];
  end
  else
  begin
    // Verteilungsparameter A für SW 1. Ordnung und höher
    if Par_GrowthDeviat[0, ord, ent] > 0 then
    begin
      sigma_lnA :=
        sqrt(LN((sqr(Par_GrowthDeviat[0, ord, ent]) / sqr(Par_GrowthAver[0, ord,
        ent])) + 1));
      mue_lnA := LN(Par_GrowthAver[0, ord, ent]) - 0.5 * sqr(sigma_lnA);
      // Ziehen aus Lognormaler Verteilung geht zunächst vom Ziehen aus einer Standardnormalvert. aus
      DrawStdNorm := meanStdnorm + (stdevStdnorm * sqrt(-LN(tire1)) *
        cos(Pi * tire2) * sqrt(2));
      // Begrenzen des max. Längenwachstums auf 2 Standardabweichungen
      if DrawStdNorm < -2 then
        DrawStdNorm := -2;
      if DrawStdNorm > 2 then
        DrawStdNorm := 2;
      PCroiss[0] := exp(DrawStdNorm * sigma_lnA + mue_lnA);
    end
    else
      PCroiss[0] := Par_GrowthAver[0, ord, ent];
    { Verteilungsparameter B für SW 1. Ordnung und höher. Kopplung über die gezogenen
      Zufallszahlen aus Standardnormalverteilung. Es werden genau die Werte, die für
      die Berechnung der aktuellen Lmax verwendet wurden auch für die Berechnung der
      Wachstumsrate verwendet. }
    if Par_GrowthDeviat[1, ord, ent] > 0 then
    begin
      sigma_lnB :=
        sqrt(LN((sqr(Par_GrowthDeviat[1, ord, ent]) / sqr(Par_GrowthAver[1, ord,
        ent])) + 1));
      mue_lnB := LN(Par_GrowthAver[1, ord, ent]) - 0.5 * sqr(sigma_lnB);
      { Es wird für das Ziehen aus Lognormaler Verteilung davon ausgegangen, dass
        auch Wachstumsrate mit dem Maximalwert korrespondiert: Wurzeln mit hoher Lmax
        wachsen auch schneller. }
      // DrawStdNorm:= meanStdnorm+(stdevStdnorm*sqrt(-ln(tire1))*cos(Pi*tire2)*sqrt(2));
      PCroiss[1] := exp(DrawStdNorm * sigma_lnB + mue_lnB);
    end
    else
      PCroiss[1] := Par_GrowthAver[1, ord, ent];
  end;

end;

Procedure TSubmodRootStrucNew.DrawPRamif(var Meris: TMeristem;
  var PRamif: single);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Modifiziert den Ramifikationsparameter in Abhängigkeit von einem
  bestimmten Schwellenwert des Elongationsparameters A (Skalierungsparameter)
  Originalimplementierung
  if (Meris.PCroiss[0]>3.2) then
  PRamif := Par_RamifAver[Meris.Order,Meris.Internode]*ram_scaling.v
  else
  PRamif := 100.0;
  Aus der Funktion Growth:
  if ((ASegment.Meristem.Order=0) and (ASegment.Meristem.Internode<2)) then
  ASegment.Meristem.PRamif := 1/(9.956*exp(-0.01888*ASegment.Meristem.DistBase));
  if (ASegment.Meristem.Order=0) and (ASegment.Meristem.Internode>= 2) then
  ASegment.Meristem.PRamif := 1/(11.51*exp(-0.01280*ASegment.Meristem.DistBase));
  ------------------------------------------------------------------------------ *)
begin
  // USL beginn
  if Meris.Order = 0 then
  begin
    if (RamMode.Option = 'pagesorg') or (RamMode.Option = 'parsw') then
    begin
      if ((Meris.Order = 0) and (Meris.Internode < 2)) then // USL
        Meris.PRamif := 1 /
          (Par_RamMod_Asem.v * exp(-Par_RamMod_Bsem.v * Meris.DistBase));
      if (Meris.Order = 0) and (Meris.Internode >= 2) then
        Meris.PRamif := 1 /
          (Par_RamMod_Acr.v * exp(-Par_RamMod_Bcr.v * Meris.DistBase));
    end
    else
      Meris.PRamif := Par_RamifAver[Meris.Order, Meris.Internode] *
        ram_scaling.v;
  end
  // USL Ende
  else
  begin
    if RamMode.Option = 'pagesorg' then
    begin
      if Meris.Order = 1 then
      begin
        if (Meris.PCroiss[0] > Thres_RamMod.v) then
          Meris.PRamif := Par_RamifAver[Meris.Order, Meris.Internode] *
            ram_scaling.v
        else
          Meris.PRamif := Par_RamMod_Gener.v;
      end
      else
        Meris.PRamif := Par_RamifAver[Meris.Order, Meris.Internode] *
          ram_scaling.v;
    end
    else
      Meris.PRamif := Par_RamifAver[Meris.Order, Meris.Internode] *
        ram_scaling.v;
  end;
  if Meris.PRamifold = 0 then
  // Zu Beginn haben beide Ramifikationsparameter den gleichen Wert.
  begin
    Meris.PRamifold := Meris.PRamif;
  end;
end; // End DrawPRamif

function TSubmodRootStrucNew.DrawAngIPrim(Internode: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  ------------------------------------------------------------------------------ *)
var
  tire1, tire2: double;

begin
  tire1 := FRandUnif();
  tire2 := FRandUnif();
  DrawAngIPrim := Par_AngIAver[0, Internode] +
    (Par_AngIDeviat[0, Internode] * sqrt(-LN(tire1)) * cos(Pi * tire2) * 1.414);
end; // End DrawAngIPrim

function TSubmodRootStrucNew.DrawAngI(FatherMeris: TMeristem): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  ------------------------------------------------------------------------------ *)
var
  tire1, tire2: double;
  ord, ent: integer;

begin
  if FatherMeris <> nil then
  begin
    ord := FatherMeris.Order;
    ent := FatherMeris.Internode;
    tire1 := FRandUnif();
    tire2 := FRandUnif();
    DrawAngI := Par_AngIAver[ord + 1, ent] +
      (Par_AngIDeviat[ord + 1, ent] * sqrt(-LN(tire1)) *
      cos(Pi * tire2) * 1.414);
  end
  else
  begin
    showMessage('NIL MerisPere!');
    DrawAngI := 0.0
  end;
end; // End DrawAngI

function TSubmodRootStrucNew.DrawAngGen(FatherMeris: TMeristem): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: wahrscheinliich Berechnung des radialen Winkels
  (vgl. EN # 185, S.150) allerdings sollte nach dem Artikel
  NumGen ein Integer-Wert sein.
  ------------------------------------------------------------------------------ *)
var
  NumGen: double;
  NumGenAsInt: int64;
begin
  NumGen := IRandUnif(Par_NumberGen[FatherMeris.Order, FatherMeris.Internode]) +
    trunc(AddNumb_Gen.v);
  NumGenAsInt := round(NumGen);
  // Result := 2.0*Pi*NumGen/(Par_NumberGen[FatherMeris.Order,FatherMeris.Internode]);//Original
  if Par_NumberGen[FatherMeris.Order, FatherMeris.Internode] > 0 then
    Result := 2.0 * Pi * NumGenAsInt /
      (Par_NumberGen[FatherMeris.Order, FatherMeris.Internode])
end; // End DrawAngGen

function TSubmodRootStrucNew.CalcNumEPredict(TempSum: double): integer;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Vorhersagefunktion: In Abhängigkeit von der Temperatursumme wird
  die Nummer des Internodiums zurückgegeben, bei welchem eine Emission stattfinden
  kann.
  ------------------------------------------------------------------------------ *)
begin
  // Hier gab es eine Inkompatibilität die zunächst durch Round behoben wurde
  CalcNumEPredict := round(Par_Emiss[1] * TempSum + Par_Emiss[0]);
end; // End CalcNumEPredit

function TSubmodRootStrucNew.calcTempSumSoil(TimeStep: integer;
  depth: double): double;
var
  TempsumDt, TempSoil: double;
  layerIndex: integer;
begin
  (* ------------------------------------------------------------------------------
    In Abängigkeit von der aktuellen Zeitschrittweite wird die Temperatursumme
    im Zeitschritt im Boden berechnet
    a) konstante Temperatursumme
    b) in Abhängigkeit von der Position des Meristems

    ------------------------------------------------------------------------------ *)
  layerIndex := 0;
  if self.SoilTempMode.Option = 'without' then
    TempsumDt := TimeStep * 20.0;
  if self.SoilTempMode.Option = 'linear' then
  { berechnet die Temperatursumme in der Abhängigkeit von der aktuellen Zeitschritt-
    weite und der Bodentiefe mit Hilfe des Algrithmus von Porter/Klepper (EN Label # 79) }
  begin
    TempsumDt := TimeStep * calcTempDepthPorter(depth);
  end;
  if self.SoilTempMode.Option = 'sinus' then
  begin
    TempSoil := calcTempDepthPorter(depth);
    TempsumDt := TimeStep * TempSoil * calcImpedFact(TempSoil);
  end;
  if self.SoilTempMode.Option = 'submodel' then
  { berechnet die Temperatursumme in der Abhängigkeit von der aktuellen Zeitschritt-
    weite und der Bodentiefe Hilfe der Temperaturwerte die über externe Variablen
    vom Bodenmodell bereitgestellt werden. }
  begin
    // Berechnen der benötigten Bodenschicht
    if (depth > 0) and (depth < 100) then
      // Es wird hier von gleichförmiger Schichtdicke ausgegangen
      layerIndex := floor(depth / GaugeStandardSeg)
    else
      layerIndex := 1;
    TempSoil := SoilTempArray[layerIndex].v;
    // TempSoil:=SoilTempArr[layerIndex]; //Aus Performacegründen angedacht.
    TempsumDt := TimeStep * TempSoil;
  end;
  Result := TempsumDt;
end;

function TSubmodRootStrucNew.calcTempSumAir(Time: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Temperatursumme Luft
  ------------------------------------------------------------------------------ *)
var
  effTemp, TempAir, TempSoil: double;
  year, month, day: word;
  SimTime: TDateTime;
begin
  DecodeDate(Globmod.Time.v, year, month, day);
  if self.SoilTempMode.Option = 'without' then
    TempAir := Time * 20.0;
  if SoilTempMode.Option = 'submodel' then
  // in diesem Fall Wetterdaten vorhanden.
  begin
    if Temp.v > BaseTemp.v then
    begin
      effTemp := Temp.v - BaseTemp.v;
      TempSumAir.v := TempSumAir.v + effTemp;
      TempAir := TempSumAir.v;
    end;
  end;
  if (SoilTempMode.Option = 'linear') or (SoilTempMode.Option = 'sinus') then
  begin
    TempAir := Time * TempArrMonth[month];
  end;
  Result := TempAir;
end; // End calcTempSumAir

procedure TSubmodRootStrucNew.RotVect(omega: double; u, x: r3; var rot_x: r3);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: * Cette fonction calcule le vecteur rot_x dans l'espace de
  dimension 3,
  issu de la rotation du vecteur x autour d'un axe dont u est un vecteur
  unitaire. La rotation se fait d'un angle omega radians. Elle appelle
  PRODSCAL, PRODVECT. Ungefähre Übersetung: Die Funktion berechnet den Vektor
  'rot_x' in R3 entstanden aus der Rotation des Vektors x um eine Achse
  deren [möglicherweise Vektor]u ein Einheitsvektor ist.
  ------------------------------------------------------------------------------ *)
var
  uscalx: double; (* Skalarporodukt u.x *)
  uvectx: r3; (* Vektorprodukt u^x *)

begin
  uscalx := ProdScal(u, x); // Berechnung des Skalarprodukts
  ProdVect(u, x, uvectx); // Berechnung des Vektorprodukts
  rot_x[0] := ((1 - cos(omega)) * uscalx * u[0]) + (cos(omega) * x[0]) +
    (sin(omega) * uvectx[0]);
  rot_x[1] := ((1 - cos(omega)) * uscalx * u[1]) + (cos(omega) * x[1]) +
    (sin(omega) * uvectx[1]);
  rot_x[2] := ((1 - cos(omega)) * uscalx * u[2]) + (cos(omega) * x[2]) +
    (sin(omega) * uvectx[2]);
end; // End Funktion RotVect

procedure TSubmodRootStrucNew.RotZ(u: r3; var v: r3; angle: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Funktion dreht 'u' um den Winkel 'angle' um die Z-Achse herum,
  'v' ist der Vektor, der verändert wird.
  ------------------------------------------------------------------------------ *)
begin
  v[0] := (u[0] * cos(angle)) - (u[1] * sin(angle));
  v[1] := (u[0] * sin(angle)) + (u[1] * cos(angle));
  v[2] := u[2];
end; // End Funktion RotZ

procedure TSubmodRootStrucNew.ProdVect(var u, v, u_vect_v: r3);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Die Funktion berechnet das Vektorprodukt der beiden Vektoren u und
  v in R3. Der resultierende Vektor wird im u_vect_v gespeichert.
  ------------------------------------------------------------------------------ *)
begin
  u_vect_v[0] := (u[1] * v[2]) - (v[1] * u[2]);
  u_vect_v[1] := (u[2] * v[0]) - (v[2] * u[0]);
  u_vect_v[2] := (u[0] * v[1]) - (v[0] * u[1]);
end; // End  ProdVect

procedure TSubmodRootStrucNew.Norm(var u, un: r3);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Aufruf call by reference: die Übergabeparameter werden in der
  Methode direkt verändert.
  Diese Funktion normiert den Vektor u (auf den) dreidimensionalen Raum.
  Der normierte Vektor der Rückgabe ist eins. Erzeugt wohl einen Einheitsvektor.
  vgl. Drews, S.733
  Normierung erfolgt dadurch, dass man den vektor durch die Länge (berechnet als
  NormU) teilt
  ------------------------------------------------------------------------------ *)
var
  NormU: double;
begin
  NormU := sqrt((u[0] * u[0]) + (u[1] * u[1]) + (u[2] * u[2])); // Länge
  if (NormU < Epsilon) then
  begin
    // ShowMessage('Achtung: Vektor ist Null ! Sa norme vaut : '+ FloatTostr(NormU) );
    exit;
  end
  else
  begin
    un[0] := u[0] / NormU;
    un[1] := u[1] / NormU;
    un[2] := u[2] / NormU;
  end;
end; // End Norm

function TSubmodRootStrucNew.ProdScal(u, v: r3): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Die Funktion gibt das Skalarprodukt der beiden Vektoren u und v
  zurück, u und v sind Vektoren in R3, Vgl. Drews, S.731ff.
  Skalarprodukt wird verwendet für Längen und Winkel
  ------------------------------------------------------------------------------ *)
begin
  ProdScal := (u[0] * v[0]) + (u[1] * v[1]) + (u[2] * v[2]);
end; // End  ProdScal

function TSubmodRootStrucNew.FRandUnif: double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Zeit eine uniforme reelle Zahl zwischen 0 und 1.
  ------------------------------------------------------------------------------ *)
var
  tirage: double;

begin
  tirage := random;
  if (tirage >= 1) or (tirage <= 0) then
    showMessage('Error fRandUnif');
  if (tirage <= Epsilon) then
    tirage := tirage + Epsilon;
  FRandUnif := tirage;
end; // End Funktion FRandUnif

function TSubmodRootStrucNew.IRandUnif(imax: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Diese Funktion zieht eine Zufallszahl aus einer Gleichverteilung
  zwischen 0 und imax-1
  ------------------------------------------------------------------------------ *)
var
  RandomNumber: double; // Zufallszahl, die zurückgegeben wird.
  t1, t2: double;

begin
  t1 := random * imax;
  t2 := 1 + Epsilon; { Epsilon (eine sehr geringe Zahl) wird wahrschl. addiert,
    da 1 nicht erlaubt ist }
  RandomNumber := t1 / t2;
  IRandUnif := RandomNumber;
end; // End Funktion IRandUnif
(* ------------------------------------------------------------------------------
  Methoden aus Pages-Modell Ende
  ------------------------------------------------------------------------------ *)
(* ------------------------------------------------------------------------------
  Methoden für Schnittpunktsberechnung
  ------------------------------------------------------------------------------ *)

procedure TSubmodRootStrucNew.createPlane(depth: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Aufspannen der Ebene, für die Schnittpunkte gerechnet werden
  sollen
  ------------------------------------------------------------------------------ *)
begin
  { Erzeugt die Ortsvektoren der horizontalen Ebene
    vgl. auch Schulerduden 2: Die unten aufgeführten Vektoren sind Ortsvektoren zur
    Beschreibung der Punkte, mit deren Hilfe die Gerade aufgespannt wird }
  { Cave: sämtliche Komponenten des Vektors sind positiv, da alle Komponenten
    der Vektoren, die Anfangs- und Endpunkte der Segmente beschreiben ebenfalls
    positiv sind. }
  // Aufspannen einer horizontalen Ebene
  if plane = horizontal then
  begin
    aktplane.vectorLoc_bottomLeft[0] := 0;
    aktplane.vectorLoc_bottomLeft[1] := 0;
    aktplane.vectorLoc_bottomLeft[2] := depth;

    aktplane.vectorLoc_upperLeft[0] := 0;
    aktplane.vectorLoc_upperLeft[1] := DimY.v;
    aktplane.vectorLoc_upperLeft[2] := depth;

    aktplane.vectorLoc_bottomRight[0] := DimX.v;
    aktplane.vectorLoc_bottomRight[1] := 0;
    aktplane.vectorLoc_bottomRight[2] := depth;
  end;
  if plane = vertikal then
  begin
    { Hinweis: Ich habe für die vertikale Ebene die ursprünglichen Punkte um 90°
      gedreht: bottom left liegt eigentlich jetzt oben links, upperleft unten links
      bottom right oben rechts. Damit liegt der Ursprung wieder in der vorderen,
      oberen linken Ecke des Würfels }
    { Aufspannen einer vertikalen Ebene durch den Mittelpunkt des Samens entspricht
      depth=50, depth=0 ist eine vertikale Ebene bei y=0 }
    aktplane.vectorLoc_bottomLeft[0] := 0;
    aktplane.vectorLoc_bottomLeft[1] := depth;
    aktplane.vectorLoc_bottomLeft[2] := 0;

    aktplane.vectorLoc_upperLeft[0] := 0;
    aktplane.vectorLoc_upperLeft[1] := depth;
    aktplane.vectorLoc_upperLeft[2] := DimZ.v;

    aktplane.vectorLoc_bottomRight[0] := DimX.v;
    aktplane.vectorLoc_bottomRight[1] := depth;
    aktplane.vectorLoc_bottomRight[2] := 0;
  end;
end;

function TSubmodRootStrucNew.createHorizontPlane(depth_: double): planeVector;
(* ------------------------------------------------------------------------------
  Aufspannen einer horizontalen Ebene für die Berechnung der Wurzellänge von Seg-
  menten, die Schichtgrenzen schneiden.
  ------------------------------------------------------------------------------ *)
var
  plane: planeVector;
begin
  plane.vectorLoc_bottomLeft[0] := 0;
  plane.vectorLoc_bottomLeft[1] := 0;
  plane.vectorLoc_bottomLeft[2] := depth_;

  plane.vectorLoc_upperLeft[0] := 0;
  plane.vectorLoc_upperLeft[1] := DimY.v;
  plane.vectorLoc_upperLeft[2] := depth_;

  plane.vectorLoc_bottomRight[0] := DimX.v;
  plane.vectorLoc_bottomRight[1] := 0;
  plane.vectorLoc_bottomRight[2] := depth_;

  Result := plane;
end;

function TSubmodRootStrucNew.createVertikalPlane(depth_: double): planeVector;
(* ------------------------------------------------------------------------------
  Aufspannen einer vertikalen Ebene für das Abschneiden von Segmenten, die den
  Weltwürfel über eine vertikale Ebene verlassen.
  ------------------------------------------------------------------------------ *)
var
  plane: planeVector;
begin
  plane.vectorLoc_bottomLeft[0] := 0;
  plane.vectorLoc_bottomLeft[1] := depth_;
  plane.vectorLoc_bottomLeft[2] := 0;

  plane.vectorLoc_upperLeft[0] := 0;
  plane.vectorLoc_upperLeft[1] := depth_;
  plane.vectorLoc_upperLeft[2] := DimZ.v;

  plane.vectorLoc_bottomRight[0] := DimX.v;
  plane.vectorLoc_bottomRight[1] := depth_;
  plane.vectorLoc_bottomRight[2] := 0;

  Result := plane;
end;

function TSubmodRootStrucNew.createSaggitalPlane(depth_: double): planeVector;
(* ------------------------------------------------------------------------------
  Aufspannen einer saggitalen Ebene für das Abschneiden von Segmenten, die den
  Weltwürfel über eine saggitale Ebene verlassen.
  ------------------------------------------------------------------------------ *)
var
  plane: planeVector;
begin

  Result := plane;
end;

function TSubmodRootStrucNew.createTangentPlan(TouchPoint, normVekt: r2)
  : planeVector;
(* ------------------------------------------------------------------------------
  Aufspannen tangentialen Ebene zu einem Punkt, der in der horzont. Oberfläche des
  Bodenvolumens liegt, Ebene wird über die 3 Punkte-Form aufgespannt
  ------------------------------------------------------------------------------ *)
var
  plane: planeVector;
begin
  { Hinweis: Ich habe für die vertikale Ebene die ursprünglichen Punkte s. Manus-
    kript um 90°
    gedreht: bottom left liegt eigentlich jetzt oben links, upperleft unten links
    bottom right oben rechts. Damit liegt der Ursprung wieder in der vorderen,
    oberen linken Ecke des Würfels }

  plane.vectorLoc_bottomLeft[0] := TouchPoint[0];
  plane.vectorLoc_bottomLeft[1] := TouchPoint[1];
  plane.vectorLoc_bottomLeft[2] := 0;

  plane.vectorLoc_upperLeft[0] := TouchPoint[0];
  plane.vectorLoc_upperLeft[1] := TouchPoint[1];
  plane.vectorLoc_upperLeft[2] := DimZ.v;

  plane.vectorLoc_bottomRight[0] := TouchPoint[0] + normVekt[0];
  plane.vectorLoc_bottomRight[1] := TouchPoint[1] + normVekt[1];
  plane.vectorLoc_bottomRight[2] := 0;
  Result := plane;
end;

procedure TSubmodRootStrucNew.calcIntersect;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Schnittpunkte mit Querschnittsebene
  ------------------------------------------------------------------------------ *)
var
  ASRP: TSRP; // Ein SRP-Objekt
  ASegment: TSegment; // Ein Segment
  APseudoSeg: TPotSeg; // Ein Pseudosegment
  iterator: integer; // Iterator für das Durchlaufen der Liste
  XY_Array: r2; // Array mit Koordinaten eines Schnittpunktes
  dimXAequi, // Aequivalent, da bei vertikalem Schnitt Ebene gedreht.
  dimYAequi: double;
begin
  if plane = horizontal then
  begin
    dimXAequi := DimX.v;
    dimYAequi := DimY.v;
  end;
  if plane = vertikal then
  begin
    dimXAequi := DimX.v;
    dimYAequi := DimZ.v;
  end;
  try
    { Durchlaufen der Liste mit den tatsächlich vorhandenen Segmenten }
    for iterator := 0 to SegListIntersect.Count - 1 do
    begin
      ASRP := TSRP.create;
      ASegment := SegListIntersect.Items[iterator];
      XY_Array := self.solveEquationSystem(ASegment, plane);
      // Es werden nur Schnittpunkte aktzeptiert, die innerhalb der Dimensionen dimX und dimY liegen
      if (XY_Array[0] > 0) and (XY_Array[0] < dimXAequi) and (XY_Array[1] > 0)
        and (XY_Array[1] < dimYAequi) then
      begin
        ASRP.x := XY_Array[0];
        ASRP.y := XY_Array[1];
        { Sicherheitshalber Initialisieren der Felder des SRP-Records default-Werten. }
        ASRP.area := 0;
        ASRP.RS_ID := ASegment.RS_ID;
        ASRP.NumSeg := ASegment.num;
        SRPList.Add(ASRP);
      end;
    end;
    { Durchlaufen der Liste mit Pseudosegmenten }
    for iterator := 0 to PseudoSegListIntersect.Count - 1 do
    begin
      ASRP := TSRP.create;
      APseudoSeg := PseudoSegListIntersect.Items[iterator];
      ADummyForPseudoSeg.co := APseudoSeg.co;
      ADummyForPseudoSeg.ce := APseudoSeg.ce;
      XY_Array := self.solveEquationSystem(ADummyForPseudoSeg, plane);
      if (XY_Array[0] > 0) and (XY_Array[0] < dimXAequi) and (XY_Array[1] > 0)
        and (XY_Array[1] < dimYAequi) then
      begin
        ASRP.x := XY_Array[0];
        ASRP.y := XY_Array[1];
        ASRP.area := 0;
        SRPList.Add(ASRP);
      end;
    end;
  finally
  end;
end; // End TDistributionCalculator.calcIntersect

procedure TSubmodRootStrucNew.calcIntersect(ASegment_: TSegment);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung eines Schnittpunktes des übergebenen Segments mit der
  Querschnittsbene.
  ------------------------------------------------------------------------------ *)
var
  ASRP: TSRP; // Ein SRP-Objekt
  XY_Array: r2; // Array mit 3D Koordinaten eines Schnittpunktes
  dimXAequi, // Aequivalent, da bei vertikalem Schnitt Ebene gedreht.
  dimYAequi: double;
begin
  if plane = horizontal then
  begin
    dimXAequi := DimX.v;
    dimYAequi := DimY.v;
  end;
  if plane = vertikal then
  begin
    dimXAequi := DimX.v;
    dimYAequi := DimZ.v;
  end;
  // nur notwendig, wenn die Querschnittsebene tatsächlich geschnitten wird
  if testForIntersect(ASegment_) then
  begin
    if (XY_Array[0] > 0) and (XY_Array[0] < dimXAequi) and (XY_Array[1] > 0) and
      (XY_Array[1] < dimYAequi) then
    begin
      ASRP := TSRP.create;
      XY_Array := solveEquationSystem(ASegment_, plane);
      ASRP.x := XY_Array[0];
      ASRP.y := XY_Array[1];
      { Sicherheitshalber Initialisieren der Felder des SRP-Records default-Werten. }
      ASRP.area := 0;
      // Die von außen kommenden (gespiegelten Segmente) erhalten als Kennzeichen RS_ID=-9
      ASRP.RS_ID := -9;
      ASRP.NumSeg := -9;
      SRPList.Add(ASRP);
    end;
  end;
end; // End TDistributionCalculator.calcIntersect

procedure TSubmodRootStrucNew.singleRowToCrop;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet Schnittpunkte der Wurzeln der Querschnittsebene für
  Reihen, die links und rechts neben der Einzelreihe liegen.
  ------------------------------------------------------------------------------ *)
var
  ASRPold, ASRPnew: TSRP;
  i, iterator, rowsLeft, // Reihen links von der Aussaatreihe
  rowsRight // Reihen rechts von der Aussaatreihe
    : integer; // Iterator für das Durchlaufen der Liste
  newXCoord: double;
begin
  { Berechnen der Reihen, die sich links und rechts von der 1.Aussaatreihe
    befinden: }
  rowsLeft := trunc(PosXPlant.v / RowSpace.v);
  rowsRight := trunc(-(PosXPlant.v - DimX.v) / RowSpace.v);
  if SRPList.Count <> 0 then
  begin
    for iterator := SRPList.Count - 1 downto 0 do
    begin
      ASRPold := SRPList.Items[iterator];
      // Schrittweises Verschieben der Punkte um den Reihenabstand nach links
      for i := 1 to rowsLeft do
      begin
        newXCoord := ASRPold.x - i * RowSpace.v;
        if newXCoord > 0 then
        begin
          ASRPnew := TSRP.create;;
          ASRPnew.x := newXCoord;
          ASRPnew.y := ASRPold.y;
          ASRPnew.area := 0; // sicherheitshalber
          SRPList.Add(ASRPnew);
        end;
      end;
      // Schrittweises Verschieben der Punkte um den Reihenabstand nach rechts
      for i := 1 to rowsRight do
      begin
        newXCoord := ASRPold.x + i * RowSpace.v;
        if newXCoord < DimX.v then
        begin
          ASRPnew := TSRP.create;
          ASRPnew.x := newXCoord;
          ASRPnew.y := ASRPold.y;
          ASRPnew.area := 0; // sicherheitshalber
          SRPList.Add(ASRPnew);
        end;
      end;
    end;
  end;
end;

procedure TSubmodRootStrucNew.extendToCrop;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnet bei horizont. Querschnittebene einen Bestand
  Achtung: Ursprung ist unten links
  Bei modelQuality low müssen die Punkte sowohl in x- als auch in y-Richtung ver
  vielfältigt werden.
  ------------------------------------------------------------------------------ *)
var
  ASRPold, ASRPnew: TSRP;
  i, indHigh, iterator, // Iterator für das Durchlaufen der Liste
  plantsAbove, // Reihen überhalb des Aussaatpunktes
  plantsBelow, // Reihen unterhalb des Aussaatpunktes
  rowsLeft, // Reihen links von der Aussaatpunktes
  rowsRight // Reihen rechts von der Aussaatpunktes
    : integer;
  newXCoord: double;

begin
  { Berechnen der Reihen, die sich links und rechts von der 1.Aussaatreihe
    befinden: }
  rowsLeft := trunc(PosXPlant.v / RowSpace.v);
  rowsRight := trunc(-(PosXPlant.v - DimX.v) / RowSpace.v);
  plantsAbove := trunc(PosYPlant.v / SpaceWithinRows.v);
  plantsBelow := trunc(-(PosYPlant.v - DimY.v) / SpaceWithinRows.v);
  // Zwischenspeichern der ursprünglichen letzten Index der SRP-List
  if SRPList.Count <> 0 then
    indHigh := SRPList.Count - 1;
  if (mode.Option = 'crop') and (modelQuality.Option = 'high') or
    (modelQuality.Option = 'low') then
  begin
    if SRPList.Count <> 0 then
    begin
      for iterator := indHigh downto 0 do
      begin
        ASRPold := SRPList.Items[iterator];
        // Schrittweises Verschieben der Punkte um den Reihenabstand nach links
        for i := 1 to rowsLeft do
        begin
          newXCoord := ASRPold.x - i * RowSpace.v;
          if newXCoord > 0 then
          begin
            ASRPnew := TSRP.create;;
            ASRPnew.x := newXCoord;
            ASRPnew.y := ASRPold.y;
            ASRPnew.area := 0; // sicherheitshalber
            SRPList.Add(ASRPnew);
          end;
        end;
        // Schrittweises Verschieben der Punkte um den Reihenabstand nach rechts
        for i := 1 to rowsRight do
        begin
          newXCoord := ASRPold.x + i * RowSpace.v;
          if newXCoord < DimX.v then
          begin
            ASRPnew := TSRP.create;
            ASRPnew.x := newXCoord;
            ASRPnew.y := ASRPold.y;
            ASRPnew.area := 0; // sicherheitshalber
            SRPList.Add(ASRPnew);
          end;
        end;
      end;
    end;
  end;
  if (mode.Option = 'crop') and (modelQuality.Option = 'middle') then
  begin
    if SRPList.Count <> 0 then
    begin
      for iterator := indHigh downto 0 do
      begin
        ASRPold := SRPList.Items[iterator];
        // Schrittweises Verschieben der Punkte um den Reihenabstand nach unten
        for i := 1 to plantsBelow do
        begin
          newXCoord := ASRPold.y - i * SpaceWithinRows.v;
          if newXCoord > 0 then
          begin
            ASRPnew := TSRP.create;;
            ASRPnew.x := ASRPold.x;
            ASRPnew.y := newXCoord;
            ASRPnew.area := 0; // sicherheitshalber
            SRPList.Add(ASRPnew);
          end;
        end;
        // Schrittweises Verschieben der Punkte um den Reihenabstand nach unten
        for i := 1 to plantsAbove do
        begin
          newXCoord := ASRPold.y + i * SpaceWithinRows.v;
          if newXCoord < DimX.v then
          begin
            ASRPnew := TSRP.create;
            ASRPnew.x := ASRPold.x;
            ASRPnew.y := newXCoord;
            ASRPnew.area := 0; // sicherheitshalber
            SRPList.Add(ASRPnew);
          end;
        end;
      end;
    end;
  end;
  { im Falle der Qualitätsstufe low muss die erweiterte SRP-Liste verwendet werden,
    um eine Vervielfältigung der Punkte auf Bestandesniveau zu erreichen. }
  if (mode.Option = 'crop') and (modelQuality.Option = 'low') then
  begin
    if SRPList.Count <> 0 then
    begin
      for iterator := SRPList.Count - 1 downto 0 do
      begin
        ASRPold := SRPList.Items[iterator];
        // Schrittweises Verschieben der Punkte um den Reihenabstand nach unten
        for i := 1 to plantsBelow do
        begin
          newXCoord := ASRPold.y - i * SpaceWithinRows.v;
          if newXCoord > 0 then
          begin
            ASRPnew := TSRP.create;;
            ASRPnew.x := ASRPold.x;
            ASRPnew.y := newXCoord;
            ASRPnew.area := 0; // sicherheitshalber
            SRPList.Add(ASRPnew);
          end;
        end;
        // Schrittweises Verschieben der Punkte um den Reihenabstand nach unten
        for i := 1 to plantsAbove do
        begin
          newXCoord := ASRPold.y + i * SpaceWithinRows.v;
          if newXCoord < DimX.v then
          begin
            ASRPnew := TSRP.create;
            ASRPnew.x := ASRPold.x;
            ASRPnew.y := newXCoord;
            ASRPnew.area := 0; // sicherheitshalber
            SRPList.Add(ASRPnew);
          end;
        end;
      end;
    end;
  end;

end;

procedure TSubmodRootStrucNew.extendToSinglerowLow;
var
  ASRPold, ASRPnew: TSRP;
  i, indHigh, iterator, // Iterator für das Durchlaufen der Liste
  plantsAbove, // Reihen überhalb des Aussaatpunktes
  plantsBelow, // Reihen unterhalb des Aussaatpunktes
  rowsLeft, // Reihen links von der Aussaatpunktes
  rowsRight // Reihen rechts von der Aussaatpunktes
    : integer;
  newXCoord: double;
begin
  { Berechnen der Reihen, die sich links und rechts von der 1.Aussaatreihe
    befinden: }
  rowsLeft := trunc(PosXPlant.v / RowSpace.v);
  rowsRight := trunc(-(PosXPlant.v - DimX.v) / RowSpace.v);
  plantsAbove := trunc(PosYPlant.v / SpaceWithinRows.v);
  plantsBelow := trunc(-(PosYPlant.v - DimY.v) / SpaceWithinRows.v);
  // Zwischenspeichern der ursprünglichen letzten Index der SRP-List
  if SRPList.Count <> 0 then
    indHigh := SRPList.Count - 1;
  if SRPList.Count <> 0 then
  begin
    for iterator := SRPList.Count - 1 downto 0 do
    begin
      ASRPold := SRPList.Items[iterator];
      // Schrittweises Verschieben der Punkte um den Reihenabstand nach unten
      for i := 1 to plantsBelow do
      begin
        newXCoord := ASRPold.y - i * SpaceWithinRows.v;
        if newXCoord > 0 then
        begin
          ASRPnew := TSRP.create;;
          ASRPnew.x := ASRPold.x;
          ASRPnew.y := newXCoord;
          ASRPnew.area := 0; // sicherheitshalber
          SRPList.Add(ASRPnew);
        end;
      end;
      // Schrittweises Verschieben der Punkte um den Reihenabstand nach unten
      for i := 1 to plantsAbove do
      begin
        newXCoord := ASRPold.y + i * SpaceWithinRows.v;
        if newXCoord < DimX.v then
        begin
          ASRPnew := TSRP.create;
          ASRPnew.x := ASRPold.x;
          ASRPnew.y := newXCoord;
          ASRPnew.area := 0; // sicherheitshalber
          SRPList.Add(ASRPnew);
        end;
      end;
    end;
  end;
end;

function TSubmodRootStrucNew.solveEquationSystem(ASegment_: TSegment;
  orientation: kindPlane): r2;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Löst das lineare Gleichungssystem, das sich durch die Gleichsetzung
  von Ebenen- und Geradengleichung ergibt und gibt die berechneten Koordinaten
  zurück -> Ermittlung von Schnittpunkte Wurzelsegmente mit Querschnittebene
  ------------------------------------------------------------------------------ *)
var
  XY_Coord: r2;
  vector_result, // Ergebnisvektor der erweiterten Matrix
  vector_dirPlane_a, // Vektor a: Richtungsvektor der Ebenengleichung
  vector_dirPlane_b, // Vektor b: Richtungsvektor der Ebenengleichung
  vector_dirEven: r3; // Richtungsvektor der Geradengleichung
  vector_intersect: r3; // Ortsvektor des Durchstoßpunktes
  // Determinante der Koeffizientenmatrix:
  det,
  // Determinanten der Streichungsmatrizen:
  det1, det2, det3: double;
  // Lösungen des Gleichungssystems mit drei Ungekannten
  r, s, t: double;
  { Lösung der Gleichungssystems mit der Regel von Sarrus: }
begin
  vector_result := vectorSubtrakt(ASegment_.co, aktplane.vectorLoc_bottomLeft);
  // Berechnung der Richtungsvektoren aus den Ortsvektoren:
  // a) Richtungsvektoren der Ebenengleichung
  vector_dirPlane_a := vectorSubtrakt(aktplane.vectorLoc_upperLeft,
    aktplane.vectorLoc_bottomLeft);
  vector_dirPlane_b := vectorSubtrakt(aktplane.vectorLoc_bottomRight,
    aktplane.vectorLoc_bottomLeft);
  // b) Richtungsvektoren der Geradengleichung
  vector_dirEven := vectorSubtrakt(ASegment_.ce, ASegment_.co);
  // Füllen der Matrix:
  matrix[0, 0] := vector_dirPlane_a[0];
  matrix[0, 1] := vector_dirPlane_a[1];
  matrix[0, 2] := vector_dirPlane_a[2];

  matrix[1, 0] := vector_dirPlane_b[0];
  matrix[1, 1] := vector_dirPlane_b[1];
  matrix[1, 2] := vector_dirPlane_b[2];

  matrix[2, 0] := vector_dirEven[0];
  matrix[2, 1] := vector_dirEven[1];
  matrix[2, 2] := vector_dirEven[2];
  // Erweiterung der Matrix
  matrix[3, 0] := vector_dirPlane_a[0];
  matrix[3, 1] := vector_dirPlane_a[1];
  matrix[3, 2] := vector_dirPlane_a[2];

  matrix[4, 0] := vector_dirPlane_b[0];
  matrix[4, 1] := vector_dirPlane_b[1];
  matrix[4, 2] := vector_dirPlane_b[2];
  // Berechnung dreireihige Determinante der Matrix
  { Ürsprünglich sollte der Methode hier ein in der übergebenden Methde lokal er-
    zeugtes Array übergeben werden, das hat aber nicht funktioniert. }
  det := calcDeter;

  { Anpassung der Matrix an Berechnung von det 1: Spalte 1 u. 4 werden durch
    Ergebnisvektor ersetzt }
  matrix[0, 0] := vector_result[0];
  matrix[0, 1] := vector_result[1];
  matrix[0, 2] := vector_result[2];

  matrix[3, 0] := vector_result[0];
  matrix[3, 1] := vector_result[1];
  matrix[3, 2] := vector_result[2];

  det1 := calcDeter;

  { Anpassung der Matrix an Berechnung von det 2:
    1. und 4. Spalte wieder in den ursprünglichen Zustand versetzen: }

  matrix[0, 0] := vector_dirPlane_a[0];
  matrix[0, 1] := vector_dirPlane_a[1];
  matrix[0, 2] := vector_dirPlane_a[2];

  matrix[3, 0] := vector_dirPlane_a[0];
  matrix[3, 1] := vector_dirPlane_a[1];
  matrix[3, 2] := vector_dirPlane_a[2];
  { Spalte 2 und 5 werden durch den Ergebnisvektor ersetzt }
  matrix[1, 0] := vector_result[0];
  matrix[1, 1] := vector_result[1];
  matrix[1, 2] := vector_result[2];

  matrix[4, 0] := vector_result[0];
  matrix[4, 1] := vector_result[1];
  matrix[4, 2] := vector_result[2];

  det2 := calcDeter;
  { Anpassung der Matrix an Berechnung von det 3:
    2. und 5. Spalte wieder in den ursprünglichen Zustand versetzen: }

  matrix[1, 0] := vector_dirPlane_b[0];
  matrix[1, 1] := vector_dirPlane_b[1];
  matrix[1, 2] := vector_dirPlane_b[2];

  matrix[4, 0] := vector_dirPlane_b[0];
  matrix[4, 1] := vector_dirPlane_b[1];
  matrix[4, 2] := vector_dirPlane_b[2];
  { Spalte 3 wird durch den Ergebnisvektor ersetzt }
  matrix[2, 0] := vector_result[0];
  matrix[2, 1] := vector_result[1];
  matrix[2, 2] := vector_result[2];

  det3 := calcDeter;
  // Berechnung der Lösungen:
  r := det1 / det;
  s := det2 / det;
  t := -(det3 / det);
  // Berechnung X-Wert und Y-Wert (Einsetzen in Geradengleichung):
  vector_intersect[0] := ASegment_.co[0] + (t * vector_dirEven[0]);
  vector_intersect[1] := ASegment_.co[1] + (t * vector_dirEven[1]);
  vector_intersect[2] := ASegment_.co[2] + (t * vector_dirEven[2]);

  { Beim Aufspannen einer horizontalen Ebene werden X und Y- Koordinaten des
    Weltwürfels benötigt. }
  if orientation = horizontal then
  begin
    XY_Coord[0] := vector_intersect[0];
    XY_Coord[1] := vector_intersect[1];
  end;
  { Beim Aufspannen einer vertikalen Ebene werden X und Z - Koordinaten des
    Weltwürfels benötigt. }
  if orientation = vertikal then
  begin
    XY_Coord[0] := vector_intersect[0];
    { Berechnung y-Wert, da nun auf die Ebene fokussiert wird entspricht der Y-Wert
      in R2 dem Z-Wert des Punktes im R3 }
    XY_Coord[1] := vector_intersect[2];
  end;
  Result := XY_Coord;
end;

function TSubmodRootStrucNew.solveEquationSystem(ASegment_: TSegment;
  aktPlane_: planeVector; orientation: kindPlane): r3;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Variante der ursprünglichen Methode, gibt ein Array mit 3 Stellen
  zurück.
  Löst das lineare Gleichungssystem, das sich durch die Gleichsetzung
  von Ebenen- und Geradengleichung ergibt und gibt die berechneten Koordinaten
  zurück.
  ------------------------------------------------------------------------------ *)
var
  vector_result, // Ergebnisvektor der erweiterten Matrix
  vector_dirPlane_a, // Vektor a: Richtungsvektor der Ebenengleichung
  vector_dirPlane_b, // Vektor b: Richtungsvektor der Ebenengleichung
  vector_dirEven: r3; // Richtungsvektor der Geradengleichung
  vector_intersect: r3; // Ortsvektor des Durchstoßpunktes
  // Determinante der Koeffizientenmatrix:
  det,
  // Determinanten der Streichungsmatrizen:
  det1, det2, det3: double;
  // Lösungen des Gleichungssystems mit drei Ungekannten
  r, s, t: double;
  { Lösung der Gleichungssystems mit der Regel von Sarrus: }
begin
  vector_result := vectorSubtrakt(ASegment_.co, aktplane.vectorLoc_bottomLeft);
  // Berechnung der Richtungsvektoren aus den Ortsvektoren:
  // a) Richtungsvektoren der Ebenengleichung
  vector_dirPlane_a := vectorSubtrakt(aktPlane_.vectorLoc_upperLeft,
    aktPlane_.vectorLoc_bottomLeft);
  vector_dirPlane_b := vectorSubtrakt(aktPlane_.vectorLoc_bottomRight,
    aktPlane_.vectorLoc_bottomLeft);
  // b) Richtungsvektoren der Geradengleichung
  vector_dirEven := vectorSubtrakt(ASegment_.ce, ASegment_.co);
  // Füllen der Matrix:
  matrix[0, 0] := vector_dirPlane_a[0];
  matrix[0, 1] := vector_dirPlane_a[1];
  matrix[0, 2] := vector_dirPlane_a[2];

  matrix[1, 0] := vector_dirPlane_b[0];
  matrix[1, 1] := vector_dirPlane_b[1];
  matrix[1, 2] := vector_dirPlane_b[2];

  matrix[2, 0] := vector_dirEven[0];
  matrix[2, 1] := vector_dirEven[1];
  matrix[2, 2] := vector_dirEven[2];
  // Erweiterung der Matrix
  matrix[3, 0] := vector_dirPlane_a[0];
  matrix[3, 1] := vector_dirPlane_a[1];
  matrix[3, 2] := vector_dirPlane_a[2];

  matrix[4, 0] := vector_dirPlane_b[0];
  matrix[4, 1] := vector_dirPlane_b[1];
  matrix[4, 2] := vector_dirPlane_b[2];
  // Berechnung dreireihige Determinante der Matrix
  { Ürsprünglich sollte der Methode hier ein in der übergebenden Methde lokal er-
    zeugtes Array übergeben werden, das hat aber nicht funktioniert. }
  det := calcDeter;

  { Anpassung der Matrix an Berechnung von det 1: Spalte 1 u. 4 werden durch
    Ergebnisvektor ersetzt }
  matrix[0, 0] := vector_result[0];
  matrix[0, 1] := vector_result[1];
  matrix[0, 2] := vector_result[2];

  matrix[3, 0] := vector_result[0];
  matrix[3, 1] := vector_result[1];
  matrix[3, 2] := vector_result[2];

  det1 := calcDeter;

  { Anpassung der Matrix an Berechnung von det 2:
    1. und 4. Spalte wieder in den ursprünglichen Zustand versetzen: }

  matrix[0, 0] := vector_dirPlane_a[0];
  matrix[0, 1] := vector_dirPlane_a[1];
  matrix[0, 2] := vector_dirPlane_a[2];

  matrix[3, 0] := vector_dirPlane_a[0];
  matrix[3, 1] := vector_dirPlane_a[1];
  matrix[3, 2] := vector_dirPlane_a[2];
  { Spalte 2 und 5 werden durch den Ergebnisvektor ersetzt }
  matrix[1, 0] := vector_result[0];
  matrix[1, 1] := vector_result[1];
  matrix[1, 2] := vector_result[2];

  matrix[4, 0] := vector_result[0];
  matrix[4, 1] := vector_result[1];
  matrix[4, 2] := vector_result[2];

  det2 := calcDeter;
  { Anpassung der Matrix an Berechnung von det 3:
    2. und 5. Spalte wieder in den ursprünglichen Zustand versetzen: }

  matrix[1, 0] := vector_dirPlane_b[0];
  matrix[1, 1] := vector_dirPlane_b[1];
  matrix[1, 2] := vector_dirPlane_b[2];

  matrix[4, 0] := vector_dirPlane_b[0];
  matrix[4, 1] := vector_dirPlane_b[1];
  matrix[4, 2] := vector_dirPlane_b[2];
  { Spalte 3 wird durch den Ergebnisvektor ersetzt }
  matrix[2, 0] := vector_result[0];
  matrix[2, 1] := vector_result[1];
  matrix[2, 2] := vector_result[2];

  det3 := calcDeter;
  // Berechnung der Lösungen:
  r := det1 / det;
  s := det2 / det;
  t := -(det3 / det);
  // Berechnung X-Wert und Y-Wert (Einsetzen in Geradengleichung):
  vector_intersect[0] := ASegment_.co[0] + (t * vector_dirEven[0]);
  vector_intersect[1] := ASegment_.co[1] + (t * vector_dirEven[1]);
  vector_intersect[2] := ASegment_.co[2] + (t * vector_dirEven[2]);

  Result := vector_intersect;
end;

function TSubmodRootStrucNew.solveEquationSystemTang(ASegment_: TSegment;
  aktPlane_: planeVector): r3;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Für Berechnung des Schnittpunktes mit einer Tangentialebene am Zy-
  linder.
  Löst das lineare Gleichungssystem, das sich durch die Gleichsetzung
  von Ebenen- und Geradengleichung ergibt und gibt die berechneten Koordinaten
  zurück.
  ------------------------------------------------------------------------------ *)
var
  vector_result, // Ergebnisvektor der erweiterten Matrix
  vector_dirPlane_a, // Vektor a: Richtungsvektor der Ebenengleichung
  vector_dirPlane_b, // Vektor b: Richtungsvektor der Ebenengleichung
  vector_dirEven: r3; // Richtungsvektor der Geradengleichung
  vector_intersect: r3; // Ortsvektor des Durchstoßpunktes
  // Determinante der Koeffizientenmatrix:
  det,
  // Determinanten der Streichungsmatrizen:
  det1, det2, det3: double;
  // Lösungen des Gleichungssystems mit drei Ungekannten
  r, s, t: double;
  { Lösung der Gleichungssystems mit der Regel von Sarrus: }
begin
  vector_result := vectorSubtrakt(ASegment_.co, aktPlane_.vectorLoc_bottomLeft);
  // Berechnung der Richtungsvektoren aus den Ortsvektoren:
  // a) Richtungsvektoren der Ebenengleichung
  vector_dirPlane_a := vectorSubtrakt(aktPlane_.vectorLoc_upperLeft,
    aktPlane_.vectorLoc_bottomLeft);
  vector_dirPlane_b := vectorSubtrakt(aktPlane_.vectorLoc_bottomRight,
    aktPlane_.vectorLoc_bottomLeft);
  // b) Richtungsvektoren der Geradengleichung
  vector_dirEven := vectorSubtrakt(ASegment_.ce, ASegment_.co);
  // Füllen der Matrix:
  matrix[0, 0] := vector_dirPlane_a[0];
  matrix[0, 1] := vector_dirPlane_a[1];
  matrix[0, 2] := vector_dirPlane_a[2];

  matrix[1, 0] := vector_dirPlane_b[0];
  matrix[1, 1] := vector_dirPlane_b[1];
  matrix[1, 2] := vector_dirPlane_b[2];

  matrix[2, 0] := vector_dirEven[0];
  matrix[2, 1] := vector_dirEven[1];
  matrix[2, 2] := vector_dirEven[2];
  // Erweiterung der Matrix
  matrix[3, 0] := vector_dirPlane_a[0];
  matrix[3, 1] := vector_dirPlane_a[1];
  matrix[3, 2] := vector_dirPlane_a[2];

  matrix[4, 0] := vector_dirPlane_b[0];
  matrix[4, 1] := vector_dirPlane_b[1];
  matrix[4, 2] := vector_dirPlane_b[2];
  // Berechnung dreireihige Determinante der Matrix
  { Ürsprünglich sollte der Methode hier ein in der übergebenden Methde lokal er-
    zeugtes Array übergeben werden, das hat aber nicht funktioniert. }
  det := calcDeter;

  { Anpassung der Matrix an Berechnung von det 1: Spalte 1 u. 4 werden durch
    Ergebnisvektor ersetzt }
  matrix[0, 0] := vector_result[0];
  matrix[0, 1] := vector_result[1];
  matrix[0, 2] := vector_result[2];

  matrix[3, 0] := vector_result[0];
  matrix[3, 1] := vector_result[1];
  matrix[3, 2] := vector_result[2];

  det1 := calcDeter;

  { Anpassung der Matrix an Berechnung von det 2:
    1. und 4. Spalte wieder in den ursprünglichen Zustand versetzen: }

  matrix[0, 0] := vector_dirPlane_a[0];
  matrix[0, 1] := vector_dirPlane_a[1];
  matrix[0, 2] := vector_dirPlane_a[2];

  matrix[3, 0] := vector_dirPlane_a[0];
  matrix[3, 1] := vector_dirPlane_a[1];
  matrix[3, 2] := vector_dirPlane_a[2];
  { Spalte 2 und 5 werden durch den Ergebnisvektor ersetzt }
  matrix[1, 0] := vector_result[0];
  matrix[1, 1] := vector_result[1];
  matrix[1, 2] := vector_result[2];

  matrix[4, 0] := vector_result[0];
  matrix[4, 1] := vector_result[1];
  matrix[4, 2] := vector_result[2];

  det2 := calcDeter;
  { Anpassung der Matrix an Berechnung von det 3:
    2. und 5. Spalte wieder in den ursprünglichen Zustand versetzen: }

  matrix[1, 0] := vector_dirPlane_b[0];
  matrix[1, 1] := vector_dirPlane_b[1];
  matrix[1, 2] := vector_dirPlane_b[2];

  matrix[4, 0] := vector_dirPlane_b[0];
  matrix[4, 1] := vector_dirPlane_b[1];
  matrix[4, 2] := vector_dirPlane_b[2];
  { Spalte 3 wird durch den Ergebnisvektor ersetzt }
  matrix[2, 0] := vector_result[0];
  matrix[2, 1] := vector_result[1];
  matrix[2, 2] := vector_result[2];

  det3 := calcDeter;
  // Berechnung der Lösungen:
  r := det1 / det;
  s := det2 / det;
  t := -(det3 / det);
  // Berechnung X-Wert und Y-Wert (Einsetzen in Geradengleichung):
  vector_intersect[0] := ASegment_.co[0] + (t * vector_dirEven[0]);
  vector_intersect[1] := ASegment_.co[1] + (t * vector_dirEven[1]);
  vector_intersect[2] := ASegment_.co[2] + (t * vector_dirEven[2]);

  Result := vector_intersect;
end;

function TSubmodRootStrucNew.vectorSubtrakt(vector_a, vector_b: r3): r3;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TDistributionCalculator
  BESCHREIBUNG: Subtrahiert vector_b von vector_a und gibt den resultierenden
  Vektor zurück.
  ------------------------------------------------------------------------------ *)
var
  vector_result: r3;
begin
  vector_result[0] := vector_a[0] - vector_b[0];
  vector_result[1] := vector_a[1] - vector_b[1];
  vector_result[2] := vector_a[2] - vector_b[2];
  Result := vector_result;
end; // End TSubmodRootStrucNew.vectorSubtrakt

function TSubmodRootStrucNew.calcDeter: double;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TDistributionCalculator
  BESCHREIBUNG: Berechnung der Determinante aus der übergebenen Matrix
  ------------------------------------------------------------------------------ *)
var
  det: double;
begin
  det := ((matrix[0, 0] * matrix[1, 1] * matrix[2, 2]) +
    (matrix[1, 0] * matrix[2, 1] * matrix[3, 2]) + (matrix[2, 0] * matrix[3,
    1] * matrix[4, 2])) - ((matrix[4, 0] * matrix[3, 1] * matrix[2, 2]) +
    (matrix[3, 0] * matrix[2, 1] * matrix[1, 2]) + (matrix[2, 0] * matrix[1,
    1] * matrix[0, 2]));
  Result := det;
end; // End TSubmodRootStrucNew.calcDeter

procedure TSubmodRootStrucNew.calcWLD_VK_AggregData;
(* ------------------------------------------------------------------------------
  Berechnung von mWLD und VK der mittleren Wurzellängendichte für 10 cm dicke
  Schichten der Beobachtungsfläche. Mittelfristig soll
  dies unter Verwendung von Voronoi-Polygonen geschehen.
  Da bei Verwendung von Wassermodellen mit 19 Schichten gearbeitet wird, wurde
  hier die Berechnung zunächst auf 10 Schichten beschränkt (Übersicht) Alt:
  Verwendung von TStateArray und numcomp als Parameter.
  ------------------------------------------------------------------------------- *)
type
  { Ich brauch nen Zeiger auf double, da ich mit Listen arbeiten möchte. }
  Pdouble = ^double;
var
  // RLDList: TList;
  { Liste hat speichert die ermittelten
    WLD aller gefundenen Wurzeln in der
    Schicht. }
  NumberGrid_x, NumberGrid_y, // Anzahl Gridzellen in X und Y-Richtung
  GridIndexYBegin, // Beginn der Schicht in Y-Richtung
  GridIndexYEnd, // Ende der Schicht in Y-Richtung
  WidthLayerIndex, // Ausdehnung der Schicht als Anzahl Gridzellen
  i, j, k: integer;
  AIntersection: TSRP;
  topLeft, bottomRight: TPoint;
  xOfIntersection, yOfIntersection, AreaLayer: double;
  gridElement: boolean;
  AWLD: Pdouble;
  f: TextFile;
  header: string;

begin
  { CAVE: wegen Konsistenz mit den .dat- und .rat-Dateien des Submodells wird
    Globtime.v hier um 1 zurückgesetzt. }
  header := 'Aggregierte Wurzeldaten Tag ' + floattostr(GlobTime.v - 1);
  { Problematischer Punkt: Abziehen notwendig, da dies mit der Ausgabe in die
    Dat-Datei auch so geschieht. }
  NumberGrid_x := ceil(DimX.v / gridWidth_); // Anzahl Rasterzellen X-Richtung
  NumberGrid_y := ceil(DimY.v / gridWidth_); // Anzahl Rasterzellen y-Richtung
  WidthLayerIndex := trunc(DimY.v / (10 * gridWidth_));
  // try
  // RLDList:= TList.create;

  // In sämtliche Zellen des Arrays wird 0 eingetragen
  for i := 0 to NumberGrid_x - 1 do
  begin
    for j := 0 to NumberGrid_y - 1 do
    begin
      arrAggrRootArrayLayer[i, j] := 0;
    end;
  end;
  gridElement := false;
  if self.plane = horizontal then
    AreaLayer := self.DimX.v * SizeLayer;
  if plane = vertikal then
    AreaLayer := self.DimY.v * SizeLayer;
  for k := 0 to SRPList.Count - 1 do // Für alle EWZ
  begin
    AIntersection := SRPList.Items[k];
    xOfIntersection := AIntersection.x;
    yOfIntersection := AIntersection.y;
    calcDeepestInterscection(yOfIntersection);
    { MWLD für alle 10 Schichten, unterer Rand gehört zur nachfolgenden Schicht. }
    if (yOfIntersection >= 0) and (yOfIntersection < 10) then
    begin
      RLD_1.v := RLD_1.v + 1;
    end;
    if (yOfIntersection >= 10) and (yOfIntersection < 20) then
    begin
      RLD_2.v := RLD_2.v + 1;
    end;
    if (yOfIntersection >= 20) and (yOfIntersection < 30) then
    begin
      RLD_3.v := RLD_3.v + 1;
    end;
    if (yOfIntersection >= 30) and (yOfIntersection < 40) then
    begin
      RLD_4.v := RLD_4.v + 1;
    end;
    if (yOfIntersection >= 40) and (yOfIntersection < 50) then
    begin
      RLD_5.v := RLD_5.v + 1;
    end;
    if (yOfIntersection >= 50) and (yOfIntersection < 60) then
    begin
      RLD_6.v := RLD_6.v + 1;
    end;
    if (yOfIntersection >= 60) and (yOfIntersection < 70) then
    begin
      RLD_7.v := RLD_7.v + 1;
    end;
    if (yOfIntersection >= 70) and (yOfIntersection < 80) then
    begin
      RLD_8.v := RLD_8.v + 1;
    end;
    if (yOfIntersection >= 80) and (yOfIntersection < 90) then
    begin
      RLD_9.v := RLD_9.v + 1;
    end;
    if (yOfIntersection >= 90) and (yOfIntersection <= 100) then
    begin
      RLD_10.v := RLD_10.v + 1;
    end;
    // Berechnung VC
    // a) Füllen des Arrays
    for i := 0 to NumberGrid_x - 1 do // für alle Zeilen
    begin
      for j := 0 to NumberGrid_y - 1 do // für alle Spalten
      begin
        { Mit posRelOrigin_ wird festgelegt:
          bei horizont. Ebene: wie weit hinten die Schicht beginnt
          bei vert. Ebene: wie weit unten die Schicht beginnt }
        topLeft.x := j * trunc(gridWidth_);
        topLeft.y := i * trunc(gridWidth_);
        bottomRight.x := (j + 1) * trunc(gridWidth_);
        bottomRight.y := (i + 1) * trunc(gridWidth_);
        gridElement := testForGridMember(topLeft, bottomRight, xOfIntersection,
          yOfIntersection);
        if gridElement = true then
        begin
          // Hochzählen der Einträge in der Gridzelle falls Wurzel gefunden.
          { Array: erst zeilen, dann spalten }
          inc(arrAggrRootArrayLayer[i, j])
        end;
      end;
    end;
  end; // End for k:=0 to SRPList.Count-1 do
  calcVKNumb; // Berechnung der Variationskoeffizienten der Anzahlen der Wurzeln
  // für Sens-Anal
  // CalibRLD.v:=3.3639;
  // Berechnung von WLD unter Berücksichtung des Kalibrationsfaktors aus den Profilwänden
  RLD_1.v := RLD_1.v / AreaLayer * CalibRLD.v;
  RLD_2.v := RLD_2.v / AreaLayer * CalibRLD.v;
  RLD_3.v := RLD_3.v / AreaLayer * CalibRLD.v;
  RLD_4.v := RLD_4.v / AreaLayer * CalibRLD.v;
  RLD_5.v := RLD_5.v / AreaLayer * CalibRLD.v;
  RLD_6.v := RLD_6.v / AreaLayer * CalibRLD.v;
  RLD_7.v := RLD_7.v / AreaLayer * CalibRLD.v;
  RLD_8.v := RLD_8.v / AreaLayer * CalibRLD.v;
  RLD_9.v := RLD_9.v / AreaLayer * CalibRLD.v;
  RLD_10.v := RLD_10.v / AreaLayer * CalibRLD.v;
  // Ausgabe in Datei
  if WriteAggrData.Option = 'yes' then
  begin
    try
      // Ausgabe der aggregierten Daten in eine Datei
      assignfile(f, AggrRootData.Option);
      // rewrite(f);
      append(f);
      // Schreiben Header
      writeln(f, header);
      writeln(f, 'Dimension in X-Richtung:' + ',' + floattostr(DimX.v));
      writeln(f, 'Dimension in y-Richtung:' + ',' + floattostr(DimY.v));
      writeln(f, 'Gridweite:' + ',' + floattostr(gridWidth_));
      writeln(f);
      // Schreiben der Daten
      for i := 0 to NumberGrid_x - 1 do
      begin
        for j := 0 to NumberGrid_y - 1 do
        begin
          write(f, inttostr(arrAggrRootArrayLayer[i, j]) + ',');
        end;
        writeln(f);
      end;
    finally
      closefile(f);
    end;
  end;
  // Berechnung VC
  // b) Berechnen der Verteilung mit Liste
  { VC_1.v:=calcVK(WidthLayerIndex*0,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_2.v:=calcVK(WidthLayerIndex*1,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_3.v:=calcVK(WidthLayerIndex*2,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_4.v:=calcVK(WidthLayerIndex*3,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_5.v:=calcVK(WidthLayerIndex*4,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_6.v:=calcVK(WidthLayerIndex*5,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_7.v:=calcVK(WidthLayerIndex*6,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_8.v:=calcVK(WidthLayerIndex*7,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_9.v:=calcVK(WidthLayerIndex*8,WidthLayerIndex,arrAggrRootArrayLayer, RLDList);
    VC_10.v:=calcVK(WidthLayerIndex*9,WidthLayerIndex,arrAggrRootArrayLayer, RLDList); }
  // c) Berechnen der Verteilung mit Array
  // nur, wenn Punkte vorhanden
  if SRPList.Count <> 0 then
  begin
    VC_1.v := calcVK_withArr(WidthLayerIndex * 0, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_2.v := calcVK_withArr(WidthLayerIndex * 1, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_3.v := calcVK_withArr(WidthLayerIndex * 2, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_4.v := calcVK_withArr(WidthLayerIndex * 3, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_5.v := calcVK_withArr(WidthLayerIndex * 4, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_6.v := calcVK_withArr(WidthLayerIndex * 5, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_7.v := calcVK_withArr(WidthLayerIndex * 6, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_8.v := calcVK_withArr(WidthLayerIndex * 7, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_9.v := calcVK_withArr(WidthLayerIndex * 8, WidthLayerIndex,
      arrAggrRootArrayLayer);
    VC_10.v := calcVK_withArr(WidthLayerIndex * 9, WidthLayerIndex,
      arrAggrRootArrayLayer);
  end;
  // Aufräumen: Listeneinträge und Liste freigeben
  { for i := 0 to (RLDList.Count - 1) do
    begin
    AWLD := RLDList.Items[i];
    Dispose(AWLD);
    end;
    finally
    RLDList.Free;
    end; }
end;

function TSubmodRootStrucNew.calcVK(StartIndex, LayerWidth: integer;
  arrAggrRoot: zweiDArr_type; RLDList: TList): double;
type
  { Ich brauch nen Zeiger auf double, da ich mit Listen arbeiten möchte. }
  Pdouble = ^double;
var
  i, j, l, NumberGrid_x, numberRootsCell, numberRootsLayer: integer;
  areaCell, areaCurrRoot,
  // Für Kennzahlen beschr. Statistik
  mRLD, abwQuadrat, sumAbwQuadrat, stdDev, varianz, VC: double;
  AWLDcurrRoot, ARLD_Standardabweichung: Pdouble;
begin
  numberRootsLayer := 0;
  NumberGrid_x := ceil(DimX.v / gridWidth_); // Anzahl Rasterzellen X-Richtung
  areaCell := gridWidth_ * gridWidth_; // Flächeninhalt Rasterzelle
  for i := 0 to NumberGrid_x - 1 do
  begin
    for j := StartIndex to StartIndex + LayerWidth - 1 do
    begin
      // Wenn die Zelle Wurzeln enthält
      if arrAggrRoot[i, j] <> 0 then
      begin
        numberRootsCell := arrAggrRoot[i, j];
        numberRootsLayer := numberRootsLayer + numberRootsCell;
        { Fläche der einzelnen Wurzel entspricht der Fläche der Rasterzelle durch Anzahl
          der dort vorhandenen Wurzeln }
        areaCurrRoot := areaCell / numberRootsCell;
        for l := 0 to numberRootsCell - 1 do
        begin
          new(AWLDcurrRoot);
          // Berechnung der Wurzellängendichte aus der Fläche
          AWLDcurrRoot^ := 1 / (areaCurrRoot);
          RLDList.Add(AWLDcurrRoot);
        end;
      end;
    end;
  end;
  mRLD := numberRootsLayer / (LayerWidth * gridWidth_ * DimX.v);
  // b) Berechnung der Standardabweichung, Varianz und VK
  stdDev := 0;
  varianz := 0;
  abwQuadrat := 0;
  sumAbwQuadrat := 0;
  if mRLD <> 0 then
  begin
    for i := 0 to RLDList.Count - 1 do
    begin
      ARLD_Standardabweichung := RLDList.Items[i];
      // Abweichungsquadrat ist quadrierte Abweichung vom Mittelwert
      abwQuadrat := ARLD_Standardabweichung^ - mRLD;
      abwQuadrat := abwQuadrat * abwQuadrat;
      sumAbwQuadrat := sumAbwQuadrat + abwQuadrat;
    end;
    // Berechnung Varianz (Summe der Abweichungsquadrate/durch Anzahl der Prüfglieder
    if RLDList.Count - 1 <> 0 then
    begin
      varianz := sumAbwQuadrat / (RLDList.Count - 1);
    end
    else
      varianz := 0;
    // Berechnung Standardabweichung
    stdDev := sqrt(varianz);
    // Berechnung VK
    VC := stdDev / mRLD * 100;
  end;
  Result := VC;
end;

function TSubmodRootStrucNew.calcVK_withArr(StartIndex, LayerWidth: integer;
  arrAggrRoot: zweiDArr_type): double;
(* ------------------------------------------------------------------------------
  Alternative Implementierung: Verwendung von Array
  ------------------------------------------------------------------------------- *)
var
  i, j, k, NumberGrid_x, numberRootsCell, numberRootsLayer, aktArrayIndex
  // Index der Arraypos.,in die zuletzt geschrieben wurde.
    : integer;
  areaCell, areaCurrRoot,
  // Für Kennzahlen beschr. Statistik
  mArea, // Mittlere Fläche
  { abwQuadrat,
    sumAbwQuadrat,
    stdDev,
    varianz, }
  standDev, VC: extended;
  Area_Arr: array of double;
  AAreacurrRoot, AArea_Standardabweichung: double;
  sumAreaLay, // Gesamtsumme Flächeninhalt in der Fläche
  quadSumArea // Summe der quadrierten Flächeninhalten
    : extended;

begin
  numberRootsLayer := 0;
  mArea := 0;
  NumberGrid_x := ceil(DimX.v / gridWidth_); // Anzahl Rasterzellen X-Richtung
  areaCell := gridWidth_ * gridWidth_; // Flächeninhalt Rasterzelle
  sumAreaLay := 0;
  quadSumArea := 0;
  standDev := 0;
  // for i:=0 to NumberGrid_x-1 do
  for i := StartIndex to StartIndex + LayerWidth - 1 do // für alle zeilen
  begin
    for j := 0 to NumberGrid_x - 1 do // für alle Spalten
    begin
      // Wenn die Zelle Wurzeln enthält
      if arrAggrRoot[i, j] <> 0 then
      begin
        numberRootsCell := arrAggrRoot[i, j];
        sumAreaLay := sumAreaLay + areaCell;
        quadSumArea := quadSumArea +
          (sqr(areaCell / numberRootsCell) * numberRootsCell);
        numberRootsLayer := numberRootsLayer + numberRootsCell;
      end;
    end;
  end;
  if numberRootsLayer > 0 then
  begin
    mArea := sumAreaLay / numberRootsLayer;
    if numberRootsLayer > 1 then
      standDev := calcStdDev(sumAreaLay, quadSumArea, numberRootsLayer);
  end;
  if (mArea > 0) then
  begin
    VC := standDev / mArea * 100;
  end
  else
    VC := 0;
  { ------------------------------------------------------------------------------
    alt. Methode enthält noch Fehler
    ------------------------------------------------------------------------------- }

  { for i:=StartIndex to StartIndex+LayerWidth-1 do //für alle zeilen
    begin
    for j:=0 to NumberGrid_x-1 do   //für alle Spalten
    begin
    //Wenn die Zelle Wurzeln enthält
    if arrAggrRoot[i,j] <> 0 then
    begin
    numberRootsCell:=arrAggrRoot[i,j];
    numberRootsLayer := numberRootsLayer + numberRootsCell;
    end;
    end;
    end;

    setlength(Area_Arr, numberRootsLayer);
    aktArrayIndex:=0;

    { Es wird im Folgenden der Umweg über die Flächen gegangen, da aus den Einzel-
    werten der WLD nicht das aritmetische Mittel gezogen werden kann. Stattdessen wird
    der mittlere Flächeninhalt bestimmt und aus diesem der Kehrwert bestimmt, ebenso
    wird der VK der Flächenverteilung berechnet, der entspricht näherungsweise dem
    VK der RLD-Verteilung. }
  { if numberRootsLayer <> 0 then
    begin
    for i:=StartIndex to StartIndex+LayerWidth-1 do //für alle zeilen
    begin
    for j:=0 to NumberGrid_x-1 do   //für alle Spalten
    begin
    //Wenn die Zelle Wurzeln enthält
    if arrAggrRoot[i,j] <> 0 then
    begin
    numberRootsCell:=arrAggrRoot[i,j];
    //Fläche der einzelnen Wurzel entspricht der Fläche der Rasterzelle durch Anzahl
    //der dort vorhandenen Wurzeln
    areaCurrRoot:=areaCell/numberRootsCell;
    for k:=0 to numberRootsCell-1 do
    begin
    //Füllen der Liste mit Einzelflächen
    Area_Arr[aktArrayIndex+k]:=areaCurrRoot;
    end;
    aktArrayIndex:=aktArrayIndex+numberRootsCell;
    end;
    end;
    end;
    meanAndStdDev(Area_Arr,mArea,standDev); }
  { Beschr. Statistik von Hand:
    for i:=0 to high(Area_Arr) do
    begin
    mArea:=mArea+Area_Arr[i];
    end;
    mArea:=mArea/numberRootsLayer;
    //b) Berechnung der Standardabweichung, Varianz und VK
    stdDev:=0;
    varianz:=0;
    abwQuadrat:=0;
    sumAbwQuadrat:=0;
    if mArea <> 0 then
    //Für Berechnung der
    begin
    for i:=0 to high(Area_Arr) do
    begin
    AArea_Standardabweichung:=Area_Arr[i];
    if AArea_Standardabweichung<> 0 then
    begin
    //Abweichungsquadrat ist quadrierte Abweichung vom Mittelwert
    abwQuadrat:=AArea_Standardabweichung-mArea;
    abwQuadrat:=abwQuadrat*abwQuadrat;
    sumAbwQuadrat:=sumAbwQuadrat+abwQuadrat;
    end;
    end;
    //Berechnung Varianz (Summe der Abweichungsquadrate/durch Anzahl der Prüfglieder
    if high(Area_Arr)-1 <> 0 then
    begin
    varianz:=sumAbwQuadrat/numberRootsLayer;
    end
    else
    varianz:=0;
    //Berechnung Standardabweichung
    stdDev:=sqrt(varianz);
    //Berechnung VK
    VC:=stdDev/mArea*100;

    end;
    VC:=StandDev/mArea*100;
    end
    else
    VC:=0; }
  { ------------------------------------------------------------------------------
    alt. Methode   Ende
    ------------------------------------------------------------------------------- }
  Result := VC;
end;

procedure TSubmodRootStrucNew.calcVKNumb;
(* ------------------------------------------------------------------------------
  Berechnet Variationskoeffizienten der mittleren Anzahlen
  für jede Spalte innerhalb einer Schicht
  entweder als gleitendes Mittel oder als mit den ungeglätteten Anzahlen.
  Cave: Korrekte Berechnung bei Verwendung des gleitenden Mittels muss erneut
  untersucht werden.
  Zunächst nur für vertikale Schnittebenen mit variabler Schichtdicke
  Derzeit (29.04.2007) verwendete Methode, sollte aber durch Berechnung von Voro-
  noi-Polygonen ersetzt werden.
  ------------------------------------------------------------------------------- *)
var
  i, j, k, l, m, n, NumbLayer, // Anzahl der Schichten
  length, // Dimension der aufsummierten Schichten
  NumberGrid_x, // Anzahl Rasterzellen X-Richtung
  NumberCellsLayer, // Gesamtzahl der Zellen in Schicht
  NumberCellsExplored, // Gesamtzahl der Zellen in Schicht mit Wurzeln
  NumberRowsLayer, // Anzahl der Reihen Grid-Zellen in der Schicht
  RowIndexStart, // Index der Reihe, mit der die Schicht beginnt.
  NumberRoots, // Anzahl der Wurzeln Spalte und umgeb. Spalten
  NumberCols // Anzahl der Spalten, die für gleitenden Mittelwert
  // berücksichtigt wurden.

    : integer;
  NumberRootArr: array of double;

  NumbColsWithRoots
  // Anzahl von Spalten in der Schicht, die W-Schnittpkte enthalten
    : integer;
  SumR, // Gesamtzahl der W'-Schnittpunkte
  quadsumWithR,
  // Quadratsumme der Anzahlen in den einzelnen Spalten der Schicht
  mean, // Mittelwert
  stdev, // Standardabw
  VC, PercentCellsExplored // Gesamtzahl der Zellen in Schicht mit Wurzeln [%]
    : // Variationskoeffizient
    double;//extended;
begin
  length := 0;
  NumberGrid_x := ceil(DimX.v / gridWidth_);
  setLength(NumberRootArr, NumberGrid_x);
  NumbLayer := 0;
  NumberCols := trunc(NumbColVK.v) * 2 + 1;
  if plane = vertikal then // für vertikale Schnittebenen
  begin
    // Berechnet die Anzahl der Schichten im Beobachtungsfenster
    for i := 0 to high(GaugeArr) do
    begin
      length := length + trunc(GaugeArr[i]);
      if length <= DimY.v then
        inc(NumbLayer);
    end;

    for i := 0 to NumbLayer - 1 do // jede Schicht in der Beob-Fläche
    begin
      NumberCellsExplored := 0;
      PercentCellsExplored := 0;
      RowIndexStart := 0;
      for l := 0 to i do
      begin
        NumberRowsLayer := trunc(GaugeArr[i] / gridWidth_);
        RowIndexStart := RowIndexStart + (NumberRowsLayer);
      end;
      RowIndexStart := RowIndexStart - 2;
      // NumberRowsLayer:=trunc(GaugeArr[i]/gridwidth_);
      NumberCellsLayer := NumberGrid_x * NumberRowsLayer;
      for j := 0 to NumberGrid_x - 1 do // für alle Spalten
      begin
        NumberRoots := 0;
        // gleitendes Mittel
        if self.CVMode.Option = 'slidingav' then
        begin
          // für die Ränder:
          if (j * gridWidth_ - NumbColVK.v * gridWidth_) < 0 then // linker Rand
          begin
            for k := 0 to NumberRowsLayer - 1 do
            begin
              NumberRoots := NumberRoots + arrAggrRootArrayLayer
                [k + RowIndexStart, j];
              for m := 1 to trunc(NumbColVK.v) do
              begin
                { Wenn die Ränder links überschritten werden gleich weit entfernte Grid-Zellen, die
                  rechts neben der aktuellen Spalte liegen verwendet (kopiert). }
                if (j * gridWidth_ - m * gridWidth_) < 0 then
                begin
                  NumberRoots := NumberRoots + arrAggrRootArrayLayer
                    [k + RowIndexStart, j + m];
                end
                else
                  NumberRoots := NumberRoots + arrAggrRootArrayLayer
                    [k + RowIndexStart, j - m];
                // gehe nach rechts
                NumberRoots := NumberRoots + arrAggrRootArrayLayer
                  [k + RowIndexStart, j + m];
              end;
            end;
          end; // linker Rand Ende
          NumberRootArr[j] := NumberRoots;
          NumberRoots := 0;
          if ((j + 1) * gridWidth_ + NumbColVK.v * gridWidth_) >= DimX.v then
          // rechter Rand
          begin
            for k := 0 to NumberRowsLayer - 1 do
            begin
              NumberRoots := NumberRoots + arrAggrRootArrayLayer
                [k + RowIndexStart, j];
              for m := 1 to trunc(NumbColVK.v) do
              begin
                { Wenn die Ränder rechts überschritten werden gleich weit entfernte Grid-Zellen, die
                  links neben der aktuellen Spalte liegen verwendet (kopiert). }
                if ((j + 1) * gridWidth_ + m * gridWidth_) >= DimX.v then
                begin
                  NumberRoots := NumberRoots + arrAggrRootArrayLayer
                    [k + RowIndexStart, j - m];
                end
                else
                  NumberRoots := NumberRoots + arrAggrRootArrayLayer
                    [k + RowIndexStart, j + m];
                // gehe nach links
                NumberRoots := NumberRoots + arrAggrRootArrayLayer
                  [k + RowIndexStart, j - m];
              end;
            end;
          end; // rechter Rand Ende
          NumberRootArr[j] := NumberRootArr[j] + NumberRoots;
          NumberRoots := 0;
          // in der Mitte
          if ((j * gridWidth_ - NumbColVK.v * gridWidth_) >= 0) and
            (((j + 1) * gridWidth_ + NumbColVK.v * gridWidth_) <= DimX.v) then
          begin
            for k := 0 to NumberRowsLayer - 1 do
            begin
              NumberRoots := NumberRoots + arrAggrRootArrayLayer
                [k + RowIndexStart, j];
              for m := 1 to trunc(NumbColVK.v) do
              begin
                // gehe nach links
                NumberRoots := NumberRoots + arrAggrRootArrayLayer
                  [k + RowIndexStart, j - m];
                // gehe nach rechts
                NumberRoots := NumberRoots + arrAggrRootArrayLayer
                  [k + RowIndexStart, j + m];
              end;
            end;
            NumberRootArr[j] := NumberRootArr[j] + NumberRoots;
          end;
        end // CVMode.Option='slidingav'
        else
        begin // Berechnung der Verteilungsparameter mit dem Zahlen im Raster (ohne Glättung)
          NumberRoots := 0;
          for k := 0 to NumberRowsLayer - 1 do
          begin
            NumberRoots := NumberRoots + arrAggrRootArrayLayer
              [k + RowIndexStart, j];
            // Wenn in der Zelle Wurzeln vorhanden
            If arrAggrRootArrayLayer[k + RowIndexStart, j] > 0 then
              NumberCellsExplored := NumberCellsExplored + 1;
          end;
          NumberRootArr[j] := NumberRootArr[j] + NumberRoots;
        end;
      end; // End for j:=0 to NumberGrid_x-1 do //für alle Spalten der Schicht
      { for n:=0 to high(NumberRootArr) do
        begin
        NumberRootArr[n]:= NumberRootArr[n]/NumberCols;
        end; }
      // Berechnen des Anteils der besetzten Zellen [%]
      PercentCellsExplored := 100 / NumberCellsLayer * NumberCellsExplored;
      PercentCellsArray[i].v := PercentCellsExplored;
      // Berechnen von Mittelwerten und VK
      if self.CVConsidCells.Option = 'allcells' then
      begin
        System.math.meanAndStdDev(NumberRootArr, mean, stdev);
      end
      else
      begin
        NumbColsWithRoots := 0;
        SumR := 0;
        quadsumWithR := 0;
        mean := 0;
        stdev := 0;
        for k := 0 to high(NumberRootArr) do
        begin
          if NumberRootArr[k] > 0 then
          begin
            NumbColsWithRoots := NumbColsWithRoots + 1;
            SumR := SumR + NumberRootArr[k];
            quadsumWithR := quadsumWithR + sqr(NumberRootArr[k]);
          end;
          stdev := calcStdDev(SumR, quadsumWithR, NumbColsWithRoots);
          if NumbColsWithRoots > 0 then
            mean := SumR / NumbColsWithRoots
        end;
      end;
      // Leeren des NumberRootArr
      for n := 0 to high(NumberRootArr) do
      begin
        NumberRootArr[n] := 0;
      end;
      if mean <> 0 then
      begin
        VC := stdev / mean * 100;
      end
      else
      begin
        VC := 0;
      end;
      VCNumbVarArrray[i].v := VC;
    end;
  end
  else // für horizontale Schicht
  begin
    // fehlt noch
  end;
end;

procedure TSubmodRootStrucNew.calcWLD_VK_AggregData(var RLD_: TState;
  var VC_: TState; posRelOrigin_: double);
(* ------------------------------------------------------------------------------
  Berechnung von mWLD und VK der mittleren Wurzellängendichte. Mittelfristig soll
  dies unter Verwendung von Voronoi-Polygonen geschehen.
  ------------------------------------------------------------------------------- *)
type
  { Ich brauch nen Zeiger auf double, da ich mit Listen arbeiten möchte. }
  Pdouble = ^double;
var
  RLDList: TList; { Liste hat speichert die ermittelten
    WLD aller gefundenen Wurzeln in der
    Schicht. }
  i, j, k, l, numberRootsCell, numberRootsLayer, indexRLDArr: integer;
  areaCell, // Flächeninhalt der Gridzellen [cm2]
  areaCurrRoot, // Fläche Einzugsgebiet aktuelle Wurzel [cm2]
  RLDCurrRoot, // mWLD aktuelle Wurzel [cm/cm3]
  xOfIntersection, yOfIntersection: double;
  sumRow, sumCol, // Für Berechnung von Summen
  mRLD_timestep, // Mittelwert der WLD
  // Für Kennzahlen beschr. Statistik
  abwQuadrat, sumAbwQuadrat, stdDev, varianz: double;
  AWLDcurrRoot, AWLD, ARLD_Standardabweichung: Pdouble;

  topLeft, bottomRight: TPoint;
  NumberGrid_x, NumberGrid_y: integer; // Anzahl Gridzellen in X und Y-Richtung
  AIntersection: TSRP;
  gridElement: boolean;
begin
  RLDList := TList.create;
  // Erzeugen dynamischer Variablen samt Zeiger
  AIntersection := TSRP.create;
  new(AWLD);
  new(ARLD_Standardabweichung);
  numberRootsLayer := 0; // Anfangs keine Wurzeln
  NumberGrid_x := ceil(DimX.v / gridWidth_); // Anzahl Rasterzellen X-Richtung
  NumberGrid_y := ceil(DimY.v / gridWidth_); // Anzahl Rasterzellen y-Richtung
  (* Es wird davon ausgegangen, dass es sich um Zellen handelt, wobei Höhe = Breite
    und die Mächtigkeit der Schicht sich ohne Rest durch die Weite der Rasterzelle
    teilen lässt. *)
  areaCell := gridWidth_ * gridWidth_; // Flächeninhalt Rasterzelle
  // Festlegen der Arraygrenzen für Berechnung mit aggregierten Daten
  setLength(arrAggrRootArrayLayer, NumberGrid_x, NumberGrid_y);
  gridElement := false;
  try
    // In sämtliche Zellen wird 0 eingetragen
    for i := 0 to NumberGrid_x - 1 do
    begin
      for j := 0 to NumberGrid_y - 1 do
      begin
        arrAggrRootArrayLayer[i, j] := 0;
      end;
    end;
    // Füllen des Arrays.
    for k := 0 to SRPList.Count - 1 do // Für alle EWZ
    begin
      AIntersection := SRPList.Items[k];
      xOfIntersection := AIntersection.x;
      yOfIntersection := AIntersection.y;
      // Für alle Spalten und Zeilen
      for i := 0 to NumberGrid_x - 1 do
      begin
        for j := 0 to NumberGrid_y - 1 do
        begin
          { Mit posRelOrigin_ wird festgelegt:
            bei horizont. Ebene: wie weit hinten die Schicht beginnt
            bei vert. Ebene: wie weit unten die Schicht beginnt }
          topLeft.x := i * trunc(gridWidth_ + posRelOrigin_);
          topLeft.y := j * trunc(gridWidth_);
          bottomRight.x := (i + 1) * trunc(gridWidth_ + posRelOrigin_);
          bottomRight.y := (j + 1) * trunc(gridWidth_);
          gridElement := testForGridMember(topLeft, bottomRight,
            xOfIntersection, yOfIntersection);
          if gridElement = true then
          begin
            // Hochzählen der Einträge in der Gridzelle falls Wurzel gefunden.
            inc(arrAggrRootArrayLayer[i, j])
          end;
        end;
      end;
    end;
    // Berechnung: Anzahl der Gesamtanzahl Wurzeln in der Schicht
    for i := 0 to NumberGrid_x - 1 do
    begin
      for j := 0 to NumberGrid_y - 1 do
      begin
        // Wenn die Zelle Wurzeln enthält
        if arrAggrRootArrayLayer[i, j] <> 0 then
        begin
          numberRootsCell := arrAggrRootArrayLayer[i, j];
          numberRootsLayer := numberRootsLayer + numberRootsCell;
        end;
      end;
    end;
    for i := 0 to NumberGrid_x - 1 do
    begin
      for j := 0 to NumberGrid_y - 1 do
      begin
        // Wenn die Zelle Wurzeln enthält
        if arrAggrRootArrayLayer[i, j] <> 0 then
        begin
          numberRootsCell := arrAggrRootArrayLayer[i, j];
          { Fläche der einzelnen Wurzel entspricht der Fläche der Rasterzelle durch Anzahl
            der dort vorhandenen Wurzeln }
          areaCurrRoot := areaCell / numberRootsCell;
          for l := 0 to numberRootsCell - 1 do
          begin
            new(AWLDcurrRoot);
            // Berechnung der Wurzellängendichte aus der Fläche
            RLDCurrRoot := 1 / (areaCurrRoot);
            AWLDcurrRoot^ := RLDCurrRoot;
            RLDList.Add(AWLDcurrRoot);
          end;
        end;
      end;
    end;
    // Berechnung der Zustandsvariablen
    // a) Berechnung Mittelwert
    mRLD_timestep := 0; // Mittlere WLD in jedem Zeitschritt zunächst 0
    if numberRootsLayer <> 0 then
    begin
      for i := 0 to RLDList.Count - 1 do
      begin
        AWLD := RLDList.Items[i];
        // Aufsummieren der einzelnen WLD
        mRLD_timestep := mRLD_timestep + AWLD^;
      end;
      RLD_.v := mRLD_timestep / RLDList.Count;
    end;
    // b) Berechnung der Standardabweichung, Varianz und VK
    stdDev := 0;
    varianz := 0;
    abwQuadrat := 0;
    sumAbwQuadrat := 0;
    if RLD_.v <> 0 then
    begin
      for i := 0 to RLDList.Count - 1 do
      begin
        ARLD_Standardabweichung := RLDList.Items[i];
        // Abweichungsquadrat ist quadrierte Abweichung vom Mittelwert
        abwQuadrat := ARLD_Standardabweichung^ - RLD_.v;
        abwQuadrat := abwQuadrat * abwQuadrat;
        sumAbwQuadrat := sumAbwQuadrat + abwQuadrat;
      end;
      // Berechnung Varianz (Summe der Abweichungsquadrate/durch Anzahl der Prüfglieder
      if RLDList.Count - 1 <> 0 then
      begin
        varianz := sumAbwQuadrat / (RLDList.Count - 1);
      end
      else
        varianz := 0;
      // Berechnung Standardabweichung
      stdDev := sqrt(varianz);
      // Berechnung VK
      VC_.v := stdDev / RLD_.v * 100;
    end;
    // Aufräumen: Listeneinträge und Liste freigeben
    for i := 0 to (RLDList.Count - 1) do
    begin
      AWLD := RLDList.Items[i];
      Dispose(AWLD);
    end;
  finally
    RLDList.clear;
    RLDList.Free;
  end;
end; // End calcWLD_VK

procedure TSubmodRootStrucNew.fillIntersectList;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Funktion füllt Liste mit Segmenten, die die Querschnittsebene
  schneiden. Problem: Modifizieren
  ------------------------------------------------------------------------------ *)
var
  h, i: integer;
  ARootSystem: TRootsystem;
  ASegment: TSegment;
begin
  { Berechnung von Schnittpunkten mit Querschnittsebene und Ausgabe der WAP in ei-
    ner Instanz von TMathImage }
  // Es werden alle WS berücksichtigt: Durchlaufen der jeweiligen SegList:
  for h := 0 to RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[h];
    for i := 0 to ARootSystem.SegListEO.Count - 1 do
    // für alle Elemente der SegList
    begin
      ASegment := ARootSystem.SegListEO.Items[i];
      findIntersectRekursive(ASegment);
    end; // End for-Schleife
  end;
  { Liste mit sämtlichen potentiellen Verzweigungspunkten (Pseudosegmente)
    wird auf mögliche Schnittpunkte getestet. Muss noch überarbeitet werden, deshalb
    ausgeschaltet }
  findIntersectFromPseudoseg;
end;

procedure TSubmodRootStrucNew.findIntersectFromPseudoseg;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Findet Schnittpunkte auf der Grundlage der erstellten Pseudosegmente
  um eine Lageveränderung berechneter Schnittpunkte mit Querschnittsebene zu
  vermeiden.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  APseudoSeg: TPotSeg;
  ARootSystem: TRootsystem;
begin
  { Verarbeitet Pseudosegmente aller Wurzelsysteme }
  for i := 0 to self.RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    for j := 0 to ARootSystem.PotSegListWS.Count - 1 do
    begin
      APseudoSeg := ARootSystem.PotSegListWS.Items[j];
      // bei aufgespannter horizontaler Ebene:
      if plane = horizontal then
      begin
        { Hinweis: es wird davon ausgegangen, dass Wurzeln auch nach oben wachsen können. }
        // Fall 1: Wurzeln wachsen nach unten
        if ((APseudoSeg.co[2] < depthplane) and
          (APseudoSeg.ce[2] >= depthplane)) or
        // Fall 2: Wurzeln wachsen nach oben
          ((APseudoSeg.co[2] > depthplane) and (APseudoSeg.ce[2] <= depthplane))
        then
        begin
          PseudoSegListIntersect.Add(APseudoSeg);
        end;
      end; // end if distributionCalc.plane = horizontal
      if plane = vertikal then
      begin
        { Hinweis: Wurzeln könnnen von beiden Seiten in die vertikale Querschnittsebene
          einwachsen. }
        // Fall 1: Wachstum von der Vorderseite des Würfels aus
        if ((APseudoSeg.co[1] < depthplane) and
          (APseudoSeg.ce[1] >= depthplane)) or
        // Fall 2: Wachstum von der Rückseite des Würfels aus
          ((APseudoSeg.co[1] > depthplane) and (APseudoSeg.ce[1] <= depthplane))
        then
        begin
          PseudoSegListIntersect.Add(APseudoSeg);
        end;
      end; // End  if distributionCalc.plane = vertikal
    end;
  end;
end;

procedure TSubmodRootStrucNew.findIntersectRekursive(ASegment: TSegment);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: findet rekursiv Segmente, die Schnittpunkte mit aufgespannter Ebene
  haben und fügt diese der SegListIntersect hinzu. Es wird davon ausgegangen, dass
  ein Schnittpunkt schon dann vorhanden ist, wenn der Endpunkt des Segments
  relativ zum Anfangspunkt entweder auf der anderen Seite der Ebene oder gerade
  in der Schnittebne liegt. Der Anfangspunkt darf aber nicht in der Ebene liegen
  (das Segment muss also gewachsen sein).
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  AChild, AIntersectSegment: TSegment;
begin
  { Methode für die Zukunft (Abbildung der Krümmung von Segmenten):
    Verarbeitet alle Segmente mit Ausnahme von Segmenten,
    die ein Meristem besitzen und deren Liste pot. Verzweigungspunkte leer ist
    (alle anderen Segmente werden in findIntersectFromPseudoseg verarbeitet). }
  if (ASegment.Meristem = nil) or
    ((ASegment.Meristem <> nil) and (ASegment.Meristem.PointsOfRam.Count = 0))
  then
  begin
    // bei aufgespannter horizontaler Ebene:
    if plane = horizontal then
    begin
      { Hinweis: es wird davon ausgegangen, dass Wurzeln auch nach oben wachsen können. }
      // Fall 1: Wurzeln wachsen nach unten
      if ((ASegment.co[2] < depthplane) and (ASegment.ce[2] >= depthplane)) or
      // Fall 2: Wurzeln wachsen nach oben
        ((ASegment.co[2] > depthplane) and (ASegment.ce[2] <= depthplane)) then
      begin
        SegListIntersect.Add(ASegment);
      end;
      if ASegment.ChildList <> nil then
      begin
        for i := 0 to ASegment.ChildList.Count - 1 do
        begin
          AChild := ASegment.ChildList.Items[i];
          findIntersectRekursive(AChild);
        end;
      end;
    end; // end if distributionCalc.plane = horizontal
    if plane = vertikal then
    begin
      { Hinweis: Wurzeln könnnen von beiden Seiten in die vertikale Querschnittsebene
        einwachsen. }
      // Fall 1: Wachstum von der Vorderseite des Würfels aus
      if ((ASegment.co[1] < depthplane) and (ASegment.ce[1] >= depthplane)) or
      // Fall 2: Wachstum von der Rückseite des Würfels aus
        ((ASegment.co[1] > depthplane) and (ASegment.ce[1] <= depthplane)) then
      begin
        SegListIntersect.Add(ASegment);
      end;
      if ASegment.ChildList <> nil then
      begin
        for i := 0 to ASegment.ChildList.Count - 1 do
        begin
          AChild := ASegment.ChildList.Items[i];
          findIntersectRekursive(AChild);
        end;
      end;
    end; // End  if distributionCalc.plane = vertikal
  end;
end;

function TSubmodRootStrucNew.testForIntersect(ASegment: TSegment): boolean;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Testet, ob die aufgespannte Ebene geschnitten wird
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  AIntersectSegment: TSegment;
  hasCut: boolean;
begin
  hasCut := false;
  // bei aufgespannter horizontaler Ebene:
  if plane = horizontal then
  begin
    { Hinweis: es wird davon ausgegangen, dass Wurzeln auch nach oben wachsen können. }
    // Fall 1: Wurzeln wachsen nach unten
    if ((ASegment.co[2] < depthplane) and (ASegment.ce[2] >= depthplane)) or
    // Fall 2: Wurzeln wachsen nach oben
      ((ASegment.co[2] > depthplane) and (ASegment.ce[2] <= depthplane)) then
    begin
      hasCut := true;
    end;
  end;
  if plane = vertikal then
  begin
    { Hinweis: Wurzeln könnnen von beiden Seiten in die vertikale Querschnittsebene
      einwachsen. }
    // Fall 1: Wachstum von der Vorderseite des Würfels aus
    if ((ASegment.co[1] < depthplane) and (ASegment.ce[1] >= depthplane)) or
    // Fall 2: Wachstum von der Rückseite des Würfels aus
      ((ASegment.co[1] > depthplane) and (ASegment.ce[1] <= depthplane)) then
    begin
      hasCut := true;
    end;
  end;
  Result := hasCut;
end;
(* ------------------------------------------------------------------------------
  Methoden für Schnittpunktsberechnung Ende
  ------------------------------------------------------------------------------ *)

procedure TSubmodRootStrucNew.calcRootDataWorldCube;
(* ------------------------------------------------------------------------------
  Berechnung aggregierter Wurzeldaten, die auf den Weltwürfel bezogen
  - Bezug Boden
  - Skalenebene des Bestandes (Ausnahme: Simulation der Einzelpflanze
  - Hinweis: Berechnung der Durchwurzelungstiefe findet direkt bei der Simulation
  des Wurzelwachstums statt.
  ------------------------------------------------------------------------------ *)
var
  i, j, rootSystemID: integer;
  ASegment: TSegment;
  ARootSystem: TRootsystem;
begin
  { Berechnet die aktuelle Gesamtwurzellänge und die aktuelle Anzahl der Wurzeln
    für Modus SingleRoot oder Modus SingleRow }
  SumWL.v := 0; // brauch ich das?
  numberRootSeg.v := 0;
  // Brauch ich folgendes?
  for i := 0 to RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    SumWL.v := SumWL.v + ARootSystem.TotRootLengthWS;
    numberRootSeg.v := numberRootSeg.v + ARootSystem.SegListTotal.Count;
  end;
  { Hochskalieren auf Bestand wenn notwendig }
  if self.mode.Option = 'crop' then
  begin
    SumWL.v := SumWL.v / RSList.Count;
    if mode.Option = 'crop' then
    begin
      SumWL.v := SumWL.v * numberPlants.v;
    end;
  end;
  RootDM.v := SumWL.v / SpezRL.v;
end;

procedure TSubmodRootStrucNew.calcWL_Layer;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Wurzellänge in horizontalen Schichten des Beobach-
  tungswürfels, zur Zeit 10 Schichten.
  ------------------------------------------------------------------------------ *)
var
  i, j, k, l, m, n, currentLayer, blubb: integer;
  ASegment: TSegment;
  ARootSystem: TRootsystem;
  // Variablen für Strahlensatz
  A, // Länge Teilstück auf dem Strahl senkrecht in die Tiefe (= z-Vektor)
  G, // Gesamtlänge Strahl senkrecht in die Tiefe (= z-Vektor)
  actSegLength,
  // Schichten werden von oben gesehen
  upperBorder, lowerBorder, AFragment // Teilsegment
    : double;
  completeOut: boolean; // info, ob Segment komplett außerhalb liegt.
begin
  completeOut := false;
  resetWLStateArray;
  for i := 0 to RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    // for k:=0 to ARootsystem.SegListTotal.Count-1 do
    for k := 0 to ARootSystem.SegListTotalDisp.Count - 1 do
    begin
      { Segmente müssen zumindest teilweise im Weltwürfel liegen, um berücksichtigt zu
        werden: }
      // ASegment:=ARootsystem.SegListTotal.Items[k];
      ASegment := ARootSystem.SegListTotalDisp.Items[k];
      // Berechnen Gesamtlänge Segment
      actSegLength := self.calcAbsValue(ASegment);
      { if ((ASegment.co[0]<0) or (ASegment.co[0]> dimX.V) and
        (ASegment.co[1]<0) or (ASegment.co[1]> dimY.V) and
        (ASegment.co[2]<0) or (ASegment.co[2]> dimZ.V)) and
        ((ASegment.ce[1]<0) or (ASegment.ce[0]> dimX.V) and
        (ASegment.ce[1]<0) or (ASegment.ce[1]> dimY.V) and
        (ASegment.ce[2]<0) or (ASegment.ce[2]> dimZ.V)) then }
      { Segmente, die den Weltwürfel verlassen, oder die komplett außerhalb des
        Weltwürfel werden zur Reflektion übergeben. Segmente die (wieder) in den Welt-
        würfel hineinwachsen müssen nicht behandelt werden.
        Annahme: was den Weltwürfel seitlich verlässt, würde von anderen WS in den
        Weltwürfel hineinwachsen.
        -> Bestimmung von Schnittpunkten mit einer Querschnittsebene. }
      // a: Segmente, die vollständig außerhalb des Weltwürfels liegen
      if ((ASegment.co[0] < 0) and (ASegment.ce[0] < 0)) or
        ((ASegment.co[0] > DimX.v) and (ASegment.ce[0] > DimX.v)) or
        ((ASegment.co[1] < 0) and (ASegment.ce[1] < 0)) or
        ((ASegment.co[1] < DimY.v) and (ASegment.ce[1] > DimY.v)) then
      begin
        completeOut := true;
        updSRPList(ASegment, completeOut);
      end;
      // b: Segmente, die aus dem WW rauswachsen                      //Rauswachsen:
      if ((ASegment.co[0] > 0) and (ASegment.ce[0] < 0)) or // links
        ((ASegment.co[0] < DimX.v) and (ASegment.ce[0] > DimX.v)) or // rechts
        ((ASegment.co[1] > 0) and (ASegment.ce[1] < 0)) or // vorne
        ((ASegment.co[1] < DimY.v) and (ASegment.ce[1] > DimY.v)) // hinten
      then
      begin
        updSRPList(ASegment, completeOut);
      end;
      { Bestimmung der WL in einer Schicht }
      // a) Wurzellänge aller Segmente, die sich komplett in einer Schicht befinden.
      { Dazu müssen Anfang und Endpunkt im Segment liegen; Die Unterseiten
        zählen immer zu der Schicht hinzu, die Oberseiten nicht (Ausnahme Schicht 1): }
      for m := 0 to high(WLStateArray) do
      begin // unerklärlicher Fehler
        upperBorder := 0;
        lowerBorder := 0;
        for n := 0 to m do
        begin
          upperBorder := upperBorder + GaugeArr[n];
          lowerBorder := lowerBorder + GaugeArr[n];
        end;
        upperBorder := lowerBorder - GaugeArr[m];
        if (ASegment.co[2] <= lowerBorder) and (ASegment.co[2] > upperBorder)
          and (ASegment.ce[2] > upperBorder) and (ASegment.ce[2] <= lowerBorder)
        then
        begin
          WLStateArray[m].v := WLStateArray[m].v + actSegLength;
        end;
      end;
      { b) Wurzellänge aller Segmente, die Schichtgrenzen durchstoßen. Segmente
        können dabei von oben oder unten in die angrenzende Schicht wachsen. Es wird auch
        ein Durchstoßen mehrerer Schichten berücksichtigt. }
      { Fall 1: Segemente wachsen von oben durch die Schichtgrenzen: }
      for j := 0 to high(WLStateArray) do
      begin
        // jeweils neues Bestimmen der oberen und unteren Grenze
        upperBorder := 0;
        lowerBorder := 0;
        for l := 0 to j do
        begin
          upperBorder := upperBorder + GaugeArr[l];
          lowerBorder := lowerBorder + GaugeArr[l];
        end;
        upperBorder := lowerBorder - GaugeArr[j];
        currentLayer := j;
        if (ASegment.co[2] <= upperBorder) and (ASegment.ce[2] > upperBorder)
        then
        begin
          AFragment := 0; // Sicherheitshalber
          { Berechnen des Teilstücks, das oberhalb des Durchstoßpunktes liegt. Dieses
            enthält notwendigerweise den Ursprung des Segmentes }
          if currentLayer <> 0 then // Teilstücke in der Luft werden nicht ber.
          begin
            A := upperBorder - ASegment.co[2];
            G := ASegment.ce[2] - ASegment.co[2];
            // Strahlensatz
            AFragment := A / G * actSegLength;
            WLStateArray[j - 1].v := WLStateArray[j - 1].v + AFragment;
          end;
          { Fall: Segment endet in Schicht j: }
          if (ASegment.ce[2] < lowerBorder) then
          begin
            // Endständiges Teilstück wird berechnet
            AFragment := 0; // Sicherheitshalber
            { Berechnen des Teilstücks, das unterhalb des Durchstoßpunktes liegt. Dieses
              enthält notwendigerweise den Endpunkt des Segmentes }
            A := upperBorder - ASegment.co[2];
            G := ASegment.ce[2] - ASegment.co[2];
            // Strahlensatz
            AFragment := ASegment.SegLength - (A / G * actSegLength);
            WLStateArray[j].v := WLStateArray[j].v + AFragment;
          end
          { Fall: Segment durchstößt Schicht j komplett: }
          else
          begin
            dissaggrSegmentTopDown(ASegment, actSegLength, currentLayer);
          end;
        end;
      end; // End for j:=0 to high(WL_LayArr)
      { Fall 2: Segemente wachsen von unten noch oben durch die Schichtgrenzen. }
      for j := high(WLStateArray) downto 0 do
      begin
        upperBorder := 0;
        lowerBorder := 0;
        for l := 0 to j do
        begin
          upperBorder := upperBorder + GaugeArr[l];
          lowerBorder := lowerBorder + GaugeArr[l];
        end;
        upperBorder := lowerBorder - GaugeArr[j];
        currentLayer := j;
        if (ASegment.co[2] > lowerBorder) and (ASegment.ce[2] <= lowerBorder)
        then
        begin
          // Unterhalb der letzten Schicht wird nichts berücksichtigt.
          AFragment := 0; // Sicherheitshalber
          if currentLayer <> high(WLStateArray) then
          begin
            A := ASegment.co[2] - lowerBorder;
            G := ASegment.co[2] - ASegment.ce[2];
            // Strahlensatz
            AFragment := A / G * actSegLength;
            WLStateArray[j + 1].v := WLStateArray[j + 1].v + AFragment;
          end;
          { Fall: Segment endet in Schicht j: }
          if (ASegment.ce[2] > upperBorder) then
          begin
            AFragment := 0; // Sicherheitshalber
            A := ASegment.co[2] - lowerBorder;
            G := ASegment.co[2] - ASegment.ce[2];
            // Strahlensatz
            AFragment := ASegment.SegLength - (A / G * actSegLength);
            WLStateArray[j].v := WLStateArray[j].v + AFragment;
          end
          { Fall: Segment durchstößt Schicht j komplett: }
          else
          begin
            dissaggrSegmentBottomTop(ASegment, actSegLength, currentLayer);
          end;
        end;
      end; // End for j:=high(WLStateArray) downto 0
    end;
  end;
end;

procedure TSubmodRootStrucNew.findDeepestPointRekursive(var ASegmentToCompare
  : TSegment; var depth: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rekursives Durchlaufen von Segmentlisten und Updaten der Tiefe
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  AnOtherSegment: TSegment;
begin
  if ASegmentToCompare.ce[2] > depth then
    depth := ASegmentToCompare.ce[2];
  // Berücksichtigen von Kindern
  if ASegmentToCompare.ChildList <> nil then
  begin
    for i := 0 to ASegmentToCompare.ChildList.Count - 1 do
    begin
      AnOtherSegment := ASegmentToCompare.ChildList.Items[i];
      findDeepestPointRekursive(AnOtherSegment, depth);
    end;
  end;
end;

(* ------------------------------------------------------------------------------
  Hilfsmethoden Strukturmodell
  ------------------------------------------------------------------------------ *)
// Voronoi
function TSubmodRootStrucNew.transfFloatToInteger(x, y: double): TPoint;
(* ------------------------------------------------------------------------------
  Transformiert die X bzw. Y-Koordinaten aus der SRP - Liste in Pixel auf dem
  Ausgabeobjekt um
  ------------------------------------------------------------------------------ *)
var
  IntegerPoint: TPoint;
begin

  IntegerPoint.x := trunc(MyPaintBox.Width / DimX.v * x);
  IntegerPoint.y := trunc(MyPaintBox.Height / DimY.v * y);
  Result := IntegerPoint;
end;

// Ausgabe
procedure TSubmodRootStrucNew.writeIntersectList;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Ausgabe der berechneten Werte der Schnittpunkte mit Ebene in eine
  Datei. Hinweis: ASRP.numSeg wurde mit -9 belegt, für zusätzliche, gespiegelte
  Segmente
  ------------------------------------------------------------------------------ *)
var
  ASRP: TSRP;
  f: TextFile;
  i: integer;
  headerDay, header, xyCoord: string;
begin
  { CAVE: Wegen Konsistenz mit den .dat und .rat -Dateien des Submodells wird
    Globtime.v hier um 1 zurückgesetzt }
  headerDay := 'XY- Koordinaten Tag ' + ',' + floattostr(GlobTime.v - 1);
  header := 'NumSeg' + ',' + 'X-Coord' + ',' + 'Y-Coord';
  try
    assignfile(f, IntersectFile.Option);
    append(f);
    writeln(f, headerDay);
    writeln(f, header);
    for i := 0 to self.SRPList.Count - 1 do
    begin
      ASRP := SRPList.Items[i];
      xyCoord := inttostr(ASRP.NumSeg) + ',' + floattostr(ASRP.x) + ',' +
        floattostr(ASRP.y);
      writeln(f, xyCoord);
    end;
  finally
    closefile(f);
  end;
end;

procedure TSubmodRootStrucNew.writeAggregatedData;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Ausgabe der berechneten Anzahlen von Wurzelschnittpunkten in einem
  Grid, dessen Gitterweite über Parametereingabe vorgegeben werden kann.
  ------------------------------------------------------------------------------ *)
var
  { Array für Ausgabe der aufsummierten Wurzeln in einem Grid }
  arrAggrRootArrayTotal: array of array of integer;
  i, j, k: integer;
  xOfIntersection, yOfIntersection: double;
  sumRow, sumCol: double;
  topLeft, bottomRight: TPoint;
  NumberGrid_x, NumberGrid_y: integer; // Anzahl Gridzellen in X und Y-Richtung
  AIntersection: TSRP;
  gridElement: boolean;
  f: TextFile;
  header: string;
begin
  header := 'Aggregierte Wurzeldaten Tag ' + floattostr(GlobTime.v);
  // Erzeugen der Zeigervariablen
  NumberGrid_x := ceil(DimX.v / gridWidth_);
  NumberGrid_y := ceil(DimX.v / gridWidth_);
  // Text passt genau in die Gridzellen
  gridElement := false;
  // Festlegen der Arraygrenzen für Berechnung mit aggregierten Daten
  setLength(arrAggrRootArrayTotal, NumberGrid_x, NumberGrid_y);
  // In sämtliche Zellen wird 0 eingetragen
  for i := 0 to NumberGrid_x - 1 do
  begin
    for j := 0 to NumberGrid_y - 1 do
    begin
      arrAggrRootArrayTotal[i, j] := 0;
    end;
  end;
  // Füllen des Arrays
  // for k:=0 to self.SegListIntersect.Count-1 do
  for k := 0 to self.SRPList.Count - 1 do
  begin
    // AIntersection:=SegListIntersect.Items[k];
    AIntersection := SRPList.Items[k];
    xOfIntersection := AIntersection.x;
    yOfIntersection := AIntersection.y;
    for i := 0 to NumberGrid_x - 1 do
    begin
      for j := 0 to NumberGrid_y - 1 do
      begin
        topLeft.x := j * trunc(gridWidth_);
        topLeft.y := i * trunc(gridWidth_);
        bottomRight.x := (j + 1) * trunc(gridWidth_);
        bottomRight.y := (i + 1) * trunc(gridWidth_);
        gridElement := testForGridMember(topLeft, bottomRight, xOfIntersection,
          yOfIntersection);
        if gridElement = true then
        begin
          inc(arrAggrRootArrayTotal[i, j])
        end;
      end;
    end;
  end;
  try
    // Ausgabe der aggregierten Daten in eine Datei
    assignfile(f, AggrRootData.Option);
    // rewrite(f);
    append(f);
    // Schreiben Header
    writeln(f, header);
    writeln(f, 'Dimension in X-Richtung:' + ',' + floattostr(DimX.v));
    writeln(f, 'Dimension in y-Richtung:' + ',' + floattostr(DimY.v));
    writeln(f, 'Gridweite:' + ',' + floattostr(gridWidth_));
    writeln(f);
    // Schreiben der Daten
    for i := 0 to NumberGrid_x - 1 do
    begin
      for j := 0 to NumberGrid_y - 1 do
      begin
        write(f, inttostr(arrAggrRootArrayTotal[i, j]) + ',');
      end;
      writeln(f);
    end;
  finally
    closefile(f);
  end;
end;

function TSubmodRootStrucNew.testForGridMember(topLeft_, bottomRight_: TPoint;
  x, y: double): boolean;
{ -------------------------------------------------------------------------------
  Funktion prüft, ob sich der Wurzelschnittpunkt in einer bestimmten Rasterzelle
  befindet und gibt im Erfolgsfall true zurück.
  ------------------------------------------------------------------------------- }
var
  booleanResult: boolean;
begin
  booleanResult := false;
  if (x >= topLeft_.x) and (x < bottomRight_.x) and (y >= topLeft_.y) and
    (y < bottomRight_.y) then
  begin
    booleanResult := true;
  end;
  Result := booleanResult;
end;

procedure TSubmodRootStrucNew.calcMeanStdDevAxis(ARootsystem_: TRootsystem);
var
  i: integer;
  length: array [0 .. 3] of extended;
  stdDev: array [0 .. 3] of extended;
  quadsum: array [0 .. 3] of extended;
  numbAxis: array [0 .. 3] of integer;

  function calcDistAxisRec(ASegment: TSegment; isBegin: boolean): double;
  begin
    if (ASegment.ChildList.Count > 0) and (ASegment.ChildList[0] <> nil) then
      Result := ASegment.SegLength + calcDistAxisRec
        (ASegment.ChildList[0], false)
    else
      Result := ASegment.SegLength;
    if (isBegin = true) and (ASegment.SegLength > 0) then
    begin
      quadsum[ASegment.Order] := quadsum[ASegment.Order] + sqr(Result);
      numbAxis[ASegment.Order] := numbAxis[ASegment.Order] + 1;
      length[ASegment.Order] := length[ASegment.Order] + Result;
    end;
    if (ASegment.ChildList.Count > 1) and (ASegment.ChildList[1] <> nil) then
      calcDistAxisRec(ASegment.ChildList[1], true);
  end;

begin
  for i := 0 to 3 do
  begin
    length[i] := 0;
    quadsum[i] := 0;
    numbAxis[i] := 0;
  end;
  for i := 0 to ARootsystem_.SegListEO.Count - 1 do
  begin
    calcDistAxisRec(ARootsystem_.SegListEO[i], true);
  end;
  stdDev[0] := calcStdDev(length[0], quadsum[0], numbAxis[0]);
  if numbAxis[0] > 1 then
    MeanAxisPW.v := length[0] / numbAxis[0]
  else
    MeanAxisPW.v := length[0];
  stdDev[1] := calcStdDev(length[1], quadsum[1], numbAxis[1]);
  if numbAxis[1] > 1 then
    MeanAxisE1.v := length[1] / numbAxis[1]
  else
    MeanAxisE1.v := length[1];
  stdDev[2] := calcStdDev(length[2], quadsum[2], numbAxis[2]);
  if numbAxis[2] > 1 then
    MeanAxisE2.v := length[2] / numbAxis[2]
  else
    MeanAxisE2.v := length[2];
  stdDev[3] := calcStdDev(length[3], quadsum[3], numbAxis[3]);
  if numbAxis[3] > 1 then
    MeanAxisE3.v := length[3] / numbAxis[3]
  else
    MeanAxisE3.v := length[3];
  // Berechnung Variationskoeff
  if stdDev[0] > 0 then
    VCAxisPW.v := stdDev[0] / MeanAxisPW.v * 100;
  if stdDev[1] > 0 then
    VCAxisE1.v := stdDev[1] / MeanAxisE1.v * 100;
  if stdDev[2] > 0 then
    VCAxisE2.v := stdDev[2] / MeanAxisE2.v * 100;
  if stdDev[3] > 0 then
    VCAxisE3.v := stdDev[3] / MeanAxisE3.v * 100;

end;

procedure TSubmodRootStrucNew.calcDerivedData;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnete Variablen bezogen auf Entwicklungsordnungen, Verzwei-
  gungs und Nicht-Verzweigungszonen etc.
  Für Berechnung der Standardabw. vgl.
  E:\Statistik und Mathematik\Grundlagen\BerStandardabweichung.doc
  Hinweis: Wenn Standardabweichungen nicht nach der vereinfachten Methode berechnet
  werden kann, dann muss mit LISTEN gearbeitet werden. vgl. Sicherung vom 27.03.07
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  ASegment: TSegment;
  ARootSystem: TRootsystem;
  (* ------------------------------------------------------------------------------
    Notwendige Var. für Ber. Standardabweichung
    ------------------------------------------------------------------------------ *)
  // Anzahlen der Seg. in der Verzweigungszone der versch. Ordnungen
  NumbS_PW, NumbS_E1, NumbS_E2, NumbS_E3,
  // Nicht-Verzweigungszonen
  NumbS_AP_PW, // Anz. Seg. apikale Nicht-Verzweigungszone Primärw.
  NumbS_Bas_PW, // Anz. Seg. basale Nicht-Verzweigungszone Primärw.
  NumbS_AP_E1, NumbS_AP_E2, NumbS_AP_E3, NumbPrimaryRoots,
  // Anz. Primärer W-ACHSEN
  // PW: Segmente, die sich noch nicht verzweigten
  NumbS_NV_PW: integer;
  // Gesamtlänge aller Seg. in der Verzweigungszone der versch. Ordnungen
  LengthS_PW, LengthS_E1, LengthS_E2, LengthS_E3,
  // Summe der Quadrate der Seg-Länge. in der Verzweigungszone der versch. Ordnungen
  QuadSumSL_PW, QuadSumSL_E1, QuadSumSL_E2, QuadSumSL_E3,
  // Quadratsumme aller Segmente im Weltwürfel
  QuadSumSL_WC,
  // Gesamtlängen der Nicht-Verzweigungszonen in der Primärwurzel
  LengthS_AP_PW, LengthS_Bas_PW, LengthS_NV_PW, QuadSumSL_AP_PW,
    QuadSumSL_Bas_PW, QuadSumSL_NV_PW,
  // Gesamtlängen der Nicht-Verzweigungszonen in der Seitenwurzel 1. Ord.
  LengthS_AP_E1, QuadSumSL_AP_E1,
  // Gesamtlängen der Nicht-Verzweigungszonen in der Seitenwurzel 2. Ord.
  LengthS_AP_E2, QuadSumSL_AP_E2,
  // Gesamtlängen der Nicht-Verzweigungszonen in der Seitenwurzel 2. Ord.
  LengthS_AP_E3, QuadSumSL_AP_E3: extended;
begin
  try
    // Zurücksetzen der Variablen (sicherheitshalber)
    resetDerivedData;
    // auch sicherheitshalber
    NumbS_PW := 0;
    NumbS_E1 := 0;
    NumbS_E2 := 0;
    NumbS_E3 := 0;
    NumbPrimaryRoots := 0;
    LengthS_PW := 0;
    LengthS_E1 := 0;
    LengthS_E2 := 0;
    LengthS_E3 := 0;
    QuadSumSL_PW := 0;
    QuadSumSL_E1 := 0;
    QuadSumSL_E2 := 0;
    QuadSumSL_E3 := 0;
    QuadSumSL_WC := 0;
    // Primärw.
    NumbS_AP_PW := 0;
    NumbS_Bas_PW := 0;
    NumbS_NV_PW := 0;
    LengthS_AP_PW := 0;
    LengthS_Bas_PW := 0;
    LengthS_NV_PW := 0;
    QuadSumSL_AP_PW := 0;
    QuadSumSL_Bas_PW := 0;
    QuadSumSL_NV_PW := 0;
    // SW 1. Ord.
    NumbS_AP_E1 := 0;
    LengthS_AP_E1 := 0;
    QuadSumSL_AP_E1 := 0;
    // SW 2. Ord.
    NumbS_AP_E2 := 0;
    LengthS_AP_E2 := 0;
    QuadSumSL_AP_E2 := 0;
    // SW 3. Ord.
    NumbS_AP_E3 := 0;
    LengthS_AP_E3 := 0;
    QuadSumSL_AP_E3 := 0;
    { Fallunterscheidung: Die Daten können auf Grundlage eines WS oder auf Grundlage
      aller WS berechnet werden. }
    if PrecDeriveData.Option = 'low' then
    begin
      ARootSystem := RSList.Items[0]; // Verarbeiten des 1. WS
      if calcDistrAxis.Option = 'yes' then
        calcMeanStdDevAxis(ARootSystem);
      For j := 0 to ARootSystem.SegListTotal.Count - 1 do
      begin
        ASegment := ARootSystem.SegListTotal[j];
        QuadSumSL_WC := QuadSumSL_WC + sqr(ASegment.SegLength);
        if ASegment.Order = 0 then // Abfrage Segmente der Primärw.
        begin
          SumWL_PW.v := SumWL_PW.v + ASegment.SegLength;
          ZahlSegPW.v := ZahlSegPW.v + 1;
        end;
        if ASegment.Order = 1 then // Abfrage Segmente der Seitenw. 1.Ord..
        begin
          SumWL_E1.v := SumWL_E1.v + ASegment.SegLength;
          ZahlSegE1.v := ZahlSegE1.v + 1;
        end;
        if ASegment.Order = 2 then // Abfrage Segmente der Seitenw. 2.Ord..
        begin
          SumWL_E2.v := SumWL_E2.v + ASegment.SegLength;
          ZahlSegE2.v := ZahlSegE2.v + 1;
        end;
        if ASegment.Order = 3 then // Abfrage Segmente der Seitenw. 3.Ord..
        begin
          SumWL_E3.v := SumWL_E3.v + ASegment.SegLength;
          ZahlSegE3.v := ZahlSegE3.v + 1;
        end;
        if ASegment.Order > 3 then // Abfrage Segmente der Primärw.
        begin
          showMessage('Entwicklungsord.: ' + inttostr(ASegment.Order));
        end;
        { Gesamtllängen der VZ, sowie MW und StdAbw. der Segmente in der Verzweigungszone
          Segmente mit Vater und mit Kindern gehören der Verzweigungszone an. }
        if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0) // PW
          and (ASegment.Order = 0) then
        begin
          inc(NumbS_PW);
          LengthS_PW := LengthS_PW + ASegment.SegLength;
          QuadSumSL_PW := QuadSumSL_PW + sqr(ASegment.SegLength);
        end;
        if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0) // E-Ord.1
          and (ASegment.Order = 1) then
        begin
          inc(NumbS_E1);
          LengthS_E1 := LengthS_E1 + ASegment.SegLength;
          QuadSumSL_E1 := QuadSumSL_E1 + sqr(ASegment.SegLength);
        end;
        if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0) // E-Ord.2
          and (ASegment.Order = 2) then
        begin
          inc(NumbS_E2);
          LengthS_E2 := LengthS_E2 + ASegment.SegLength;
          QuadSumSL_E2 := QuadSumSL_E2 + sqr(ASegment.SegLength);
        end;
        if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0) // E-Ord.3
          and (ASegment.Order = 3) then
        begin
          inc(NumbS_E3);
          LengthS_E3 := LengthS_E3 + ASegment.SegLength;
          QuadSumSL_E3 := QuadSumSL_E3 + sqr(ASegment.SegLength);
        end;
        { Länge der Nichtverzweigungszonen in den Ordnungen }
        // I. Primärwurzel
        { a) apikale Nicht-Verzweigungszone = Wurzeln, die keine 'Kinder' haben, aber
          'Väter' haben }
        if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 0) and
          (ASegment.FatherID > 0) then
        begin
          inc(NumbS_AP_PW);
          LengthS_AP_PW := LengthS_AP_PW + ASegment.SegLength;
          QuadSumSL_AP_PW := QuadSumSL_AP_PW + sqr(ASegment.SegLength);
        end;
        { a) basale Nicht-Verzweigungszone = Wurzeln, die keinen 'Vater' haben, aber
          Kinder haben. }
        if { (ASegment.FatherID=0) and
          (ASegment.Order=0) and
          (ASegment.ChildList.Count>0) }
          (ASegment.isEmiss = true) and (ASegment.ChildList.Count > 0) then
        begin
          inc(NumbS_Bas_PW);
          LengthS_Bas_PW := LengthS_Bas_PW + ASegment.SegLength;
          QuadSumSL_Bas_PW := QuadSumSL_Bas_PW + sqr(ASegment.SegLength);
        end;
        // c) Segmente, die sich noch nicht verzweigt haben= keinen Vater, keine Kinder
        if { ((ASegment.ChildList.Count=0))and
          ( ASegment.Order=0) and
          ( ASegment.FatherID=0) then }
          (ASegment.isEmiss = true) and (ASegment.ChildList.Count = 0) then
        begin
          inc(NumbS_NV_PW);
          LengthS_NV_PW := LengthS_NV_PW + ASegment.SegLength;
          QuadSumSL_NV_PW := QuadSumSL_NV_PW + sqr(ASegment.SegLength);
        end;
        // II. Apikale Nicht-Verzweigungszonen (keine Kinder) der Seitenwurzeln
        // a. Ent-Ord. 1
        if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 1) then
        begin
          inc(NumbS_AP_E1);
          LengthS_AP_E1 := LengthS_AP_E1 + ASegment.SegLength;
          QuadSumSL_AP_E1 := QuadSumSL_AP_E1 + sqr(ASegment.SegLength);
        end;
        // a. Ent-Ord. 2
        if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 2) then
        begin
          inc(NumbS_AP_E2);
          LengthS_AP_E2 := LengthS_AP_E2 + ASegment.SegLength;
          QuadSumSL_AP_E2 := QuadSumSL_AP_E2 + sqr(ASegment.SegLength);
        end;
        // a. Ent-Ord. 3
        if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 3) then
        begin
          inc(NumbS_AP_E3);
          LengthS_AP_E3 := LengthS_AP_E3 + ASegment.SegLength;
          QuadSumSL_AP_E3 := QuadSumSL_AP_E3 + sqr(ASegment.SegLength);
        end;
      end;
      // Weltwürfelbezogene Daten
      if numberRootSeg.v > 0 then
        MeanSegLenWC.v := SumWL.v / numberRootSeg.v;
      if numberRootSeg.v > 1 then
        StdDevSegLenWC.v := calcStdDev(SumWL.v, QuadSumSL_WC,
          trunc(numberRootSeg.v));
      // Daten bezogen auf Entwicklungsordnungen
      TotSLVZPW.v := LengthS_PW;
      TotSLVZE1.v := LengthS_E1;
      TotSLVZE2.v := LengthS_E2;
      TotSLVZE3.v := LengthS_E3;
      if NumbS_PW > 0 then
        MeanSLVZPW.v := LengthS_PW / NumbS_PW;
      if NumbS_E1 > 0 then
        MeanSLVZE1.v := LengthS_E1 / NumbS_E1;
      if NumbS_E2 > 0 then
        MeanSLVZE2.v := LengthS_E2 / NumbS_E2;
      if NumbS_E3 > 0 then
        MeanSLVZE3.v := LengthS_E3 / NumbS_E3;
      if NumbS_PW > 1 then
        StdDSLVZPW.v := calcStdDev(LengthS_PW, QuadSumSL_PW, NumbS_PW);
      if NumbS_E1 > 1 then
        StdDSLVZE1.v := calcStdDev(LengthS_E1, QuadSumSL_E1, NumbS_E1);
      if NumbS_E2 > 1 then
        StdDSLVZE2.v := calcStdDev(LengthS_E2, QuadSumSL_E2, NumbS_E2);
      if NumbS_E3 > 1 then
        StdDSLVZE3.v := calcStdDev(LengthS_E3, QuadSumSL_E3, NumbS_E3);
      // Verzweigungszonen PW + Segmente, die sich nicht verzweigt haben
      TotNZ_PW.v := LengthS_NV_PW;
      if NumbS_NV_PW > 0 then
        MeanNZ_PW.v := LengthS_NV_PW / NumbS_NV_PW;
      if NumbS_NV_PW > 1 then
        StdNZ_PW.v := calcStdDev(LengthS_NV_PW, QuadSumSL_NV_PW, NumbS_NV_PW);
      TotApNBZ_PW.v := LengthS_AP_PW;
      if NumbS_AP_PW > 0 then
        MeanApNBZ_PW.v := LengthS_AP_PW / NumbS_AP_PW;
      if NumbS_AP_PW > 1 then
        StdApNBZ_PW.v := calcStdDev(LengthS_AP_PW, QuadSumSL_AP_PW,
          NumbS_AP_PW);
      TotBasNBZ_PW.v := LengthS_Bas_PW;
      if NumbS_Bas_PW > 0 then
        MeanBasNBZ_PW.v := LengthS_Bas_PW / NumbS_Bas_PW;
      if NumbS_Bas_PW > 1 then
        StdBasNBZ_PW.v := calcStdDev(LengthS_Bas_PW, QuadSumSL_Bas_PW,
          NumbS_Bas_PW);
      if ARootSystem.NumberPrimaryRoots > 0 then
      begin
        MeanBZ_PW.v := LengthS_PW / ARootSystem.NumberPrimaryRoots;
        If LengthS_PW > 0 then
          BranchDens.v := NumbS_PW / LengthS_PW;
      end;
      // apikale Verzweigungszone Seitenwurzeln
      if NumbS_AP_E1 > 0 then
      begin
        TotApNBZ_E1.v := LengthS_AP_E1;
        MeanApNBZ_E1.v := LengthS_AP_E1 / NumbS_AP_E1; // E1
      end;
      if NumbS_AP_E1 > 1 then
        StdApNBZ_E1.v := calcStdDev(LengthS_AP_E1, QuadSumSL_AP_E1,
          NumbS_AP_E1);
      if NumbS_AP_E2 > 0 then
      begin
        TotApNBZ_E2.v := LengthS_AP_E2;
        MeanApNBZ_E2.v := LengthS_AP_E2 / NumbS_AP_E2; // E2
      end;
      if NumbS_AP_E2 > 1 then
        StdApNBZ_E2.v := calcStdDev(LengthS_AP_E2, QuadSumSL_AP_E2,
          NumbS_AP_E2);
      if NumbS_AP_E3 > 0 then
      begin
        TotApNBZ_E3.v := LengthS_AP_E3;
        MeanApNBZ_E3.v := LengthS_AP_E3 / NumbS_AP_E3; // E3
      end;
      if NumbS_AP_E3 > 1 then
        StdApNBZ_E3.v := calcStdDev(LengthS_AP_E3, QuadSumSL_AP_E3,
          NumbS_AP_E3);
    end;
    if self.PrecDeriveData.Option = 'high' then
    begin
      for i := 0 to RSList.Count - 1 do
      begin
        ARootSystem := RSList.Items[i];
        NumbPrimaryRoots := NumbPrimaryRoots + ARootSystem.NumberPrimaryRoots;
        For j := 0 to ARootSystem.SegListTotal.Count - 1 do
        begin
          ASegment := ARootSystem.SegListTotal[j];
          QuadSumSL_WC := QuadSumSL_WC + sqr(ASegment.SegLength);
          if ASegment.Order = 0 then // Abfrage Segmente der Primärw.
          begin
            SumWL_PW.v := SumWL_PW.v + ASegment.SegLength;
            ZahlSegPW.v := ZahlSegPW.v + 1;
          end;
          if ASegment.Order = 1 then // Abfrage Segmente der Seitenw. 1.Ord..
          begin
            SumWL_E1.v := SumWL_E1.v + ASegment.SegLength;
            ZahlSegE1.v := ZahlSegE1.v + 1;
          end;
          if ASegment.Order = 2 then // Abfrage Segmente der Seitenw. 2.Ord..
          begin
            SumWL_E2.v := SumWL_E2.v + ASegment.SegLength;
            ZahlSegE2.v := ZahlSegE2.v + 1;
          end;
          if ASegment.Order = 3 then // Abfrage Segmente der Seitenw. 3.Ord..
          begin
            SumWL_E3.v := SumWL_E3.v + ASegment.SegLength;
            ZahlSegE3.v := ZahlSegE3.v + 1;
          end;
          if ASegment.Order > 3 then // Abfrage Segmente der Primärw.
          begin
            showMessage('Entwicklungsord.: ' + inttostr(ASegment.Order));
          end;
          // Verzweigungszonen PW
          { Gesamtllängen der VZ, sowie MW und StdAbw. der Segmente in der Verzweigungszone
            Segmente mit Vater und mit Kindern gehören der Verzweigungszone an. }
          if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0) // PW
            and (ASegment.Order = 0) then
          begin
            inc(NumbS_PW);
            LengthS_PW := LengthS_PW + ASegment.SegLength;
            QuadSumSL_PW := QuadSumSL_PW + sqr(ASegment.SegLength);
          end;
          if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0)
          // E-Ord.1
            and (ASegment.Order = 1) then
          begin
            inc(NumbS_E1);
            LengthS_E1 := LengthS_E1 + ASegment.SegLength;
            QuadSumSL_E1 := QuadSumSL_E1 + sqr(ASegment.SegLength);
          end;
          if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0)
          // E-Ord.2
            and (ASegment.Order = 2) then
          begin
            inc(NumbS_E2);
            LengthS_E2 := LengthS_E2 + ASegment.SegLength;
            QuadSumSL_E2 := QuadSumSL_E2 + sqr(ASegment.SegLength);
          end;
          if (ASegment.FatherID > 0) and (ASegment.ChildList.Count > 0)
          // E-Ord.3
            and (ASegment.Order = 3) then
          begin
            inc(NumbS_E3);
            LengthS_E3 := LengthS_E3 + ASegment.SegLength;
            QuadSumSL_E3 := QuadSumSL_E3 + sqr(ASegment.SegLength);
          end;
          { Länge der Nichtverzweigungszonen in den Ordnungen }
          // I. Primärwurzel
          { a) apikale Nicht-Verzweigungszone = Wurzeln, die keine 'Kinder' haben, aber
            'Väter' haben }
          if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 0) and
            (ASegment.FatherID > 0) then
          begin
            inc(NumbS_AP_PW);
            LengthS_AP_PW := LengthS_AP_PW + ASegment.SegLength;
            QuadSumSL_AP_PW := QuadSumSL_AP_PW + sqr(ASegment.SegLength);
          end;
          { a) basale Nicht-Verzweigungszone = Wurzeln, die keinen 'Vater' haben, aber
            Kinder haben. }
          if { (ASegment.FatherID=0) and
            (ASegment.Order=0) and
            (ASegment.ChildList.Count>0) }
            (ASegment.isEmiss = true) and (ASegment.ChildList.Count > 0) then
          begin
            inc(NumbS_Bas_PW);
            LengthS_Bas_PW := LengthS_Bas_PW + ASegment.SegLength;
            QuadSumSL_Bas_PW := QuadSumSL_Bas_PW + sqr(ASegment.SegLength);
          end;
          // c) Segmente, die sich noch nicht verzweigt haben, weder Vater noch Kinder
          if { ((ASegment.ChildList.Count=0))and
            ( ASegment.Order=0) and
            ( ASegment.FatherID=0) then }
            (ASegment.isEmiss = true) and (ASegment.ChildList.Count = 0) then
          begin
            inc(NumbS_NV_PW);
            LengthS_NV_PW := LengthS_NV_PW + ASegment.SegLength;
            QuadSumSL_NV_PW := QuadSumSL_NV_PW + sqr(ASegment.SegLength);
          end;
          // II. Apikale Nicht-Verzweigungszonen der Seitenwurzeln
          // a. Ent-Ord. 1
          if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 1) then
          begin
            inc(NumbS_AP_E1);
            LengthS_AP_E1 := LengthS_AP_E1 + ASegment.SegLength;
            QuadSumSL_AP_E1 := QuadSumSL_AP_E1 + sqr(ASegment.SegLength);
          end;
          // a. Ent-Ord. 2
          if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 2) then
          begin
            inc(NumbS_AP_E2);
            LengthS_AP_E2 := LengthS_AP_E2 + ASegment.SegLength;
            QuadSumSL_AP_E2 := QuadSumSL_AP_E2 + sqr(ASegment.SegLength);
          end;
          // a. Ent-Ord. 3
          if ((ASegment.ChildList.Count = 0)) and (ASegment.Order = 3) then
          begin
            inc(NumbS_AP_E3);
            LengthS_AP_E3 := LengthS_AP_E3 + ASegment.SegLength;
            QuadSumSL_AP_E3 := QuadSumSL_AP_E3 + sqr(ASegment.SegLength);
          end;
        end;
      end;
      // Weltwürfelbezogene Daten
      if numberRootSeg.v > 0 then
        MeanSegLenWC.v := SumWL.v / numberRootSeg.v;
      if numberRootSeg.v > 1 then
        StdDevSegLenWC.v := calcStdDev(SumWL.v, QuadSumSL_WC,
          trunc(numberRootSeg.v));
      // Daten bezogen auf Entwicklungsordnungen immmer bezogen auf 1 WS.
      { SumWL_PW.v:=SumWL_PW.v/RSList.count;
        SumWL_E1.v:=SumWL_E1.v/RSList.count;
        SumWL_E2.v:=SumWL_E2.v/RSList.count;
        SumWL_E3.v:=SumWL_E3.v/RSList.count;
        TotSLVZPW.v:=LengthS_PW/RSList.Count;
        TotSLVZE1.v:=LengthS_E1/RSList.Count;
        TotSLVZE2.v:=LengthS_E2/RSList.Count;
        TotSLVZE3.v:=LengthS_E3/RSList.Count; }
      TotSLVZPW.v := LengthS_PW;
      TotSLVZE1.v := LengthS_E1;
      TotSLVZE2.v := LengthS_E2;
      TotSLVZE3.v := LengthS_E3;
      if NumbS_PW > 0 then
        MeanSLVZPW.v := LengthS_PW / NumbS_PW;
      if NumbS_E1 > 0 then
        MeanSLVZE1.v := LengthS_E1 / NumbS_E1;
      if NumbS_E2 > 0 then
        MeanSLVZE2.v := LengthS_E2 / NumbS_E2;
      if NumbS_E3 > 0 then
        MeanSLVZE3.v := LengthS_E3 / NumbS_E3;
      if NumbS_PW > 1 then
        StdDSLVZPW.v := calcStdDev(LengthS_PW, QuadSumSL_PW, NumbS_PW);
      if NumbS_E1 > 1 then
        StdDSLVZE1.v := calcStdDev(LengthS_E1, QuadSumSL_E1, NumbS_E1);
      if NumbS_E2 > 1 then
        StdDSLVZE2.v := calcStdDev(LengthS_E2, QuadSumSL_E2, NumbS_E2);
      if NumbS_E3 > 1 then
        StdDSLVZE3.v := calcStdDev(LengthS_E3, QuadSumSL_E3, NumbS_E3);
      // Verzweigungszonen PW
      // Verzweigungszonen PW + Segmente, die sich nicht verzweigt haben
      TotNZ_PW.v := LengthS_NV_PW;
      if NumbS_NV_PW > 0 then
        MeanNZ_PW.v := LengthS_NV_PW / NumbS_NV_PW;
      if NumbS_NV_PW > 1 then
        StdNZ_PW.v := calcStdDev(LengthS_NV_PW, QuadSumSL_NV_PW, NumbS_NV_PW);
      TotApNBZ_PW.v := LengthS_AP_PW;
      if NumbS_AP_PW > 0 then
        MeanApNBZ_PW.v := LengthS_AP_PW / NumbS_AP_PW;
      if NumbS_AP_PW > 1 then
        StdApNBZ_PW.v := calcStdDev(LengthS_AP_PW, QuadSumSL_AP_PW,
          NumbS_AP_PW);
      TotBasNBZ_PW.v := LengthS_Bas_PW;
      if NumbS_Bas_PW > 0 then
        MeanBasNBZ_PW.v := LengthS_Bas_PW / NumbS_Bas_PW;
      if NumbS_Bas_PW > 1 then
        StdBasNBZ_PW.v := calcStdDev(LengthS_Bas_PW, QuadSumSL_Bas_PW,
          NumbS_Bas_PW);
      if NumbPrimaryRoots > 0 then
      begin
        MeanBZ_PW.v := LengthS_PW / NumbPrimaryRoots;
        If LengthS_PW > 0 then
          BranchDens.v := NumbS_PW / LengthS_PW;
      end;
      // apikale Verzweigungszone Seitenwurzeln
      if NumbS_AP_E1 > 0 then
      begin
        TotApNBZ_E1.v := LengthS_AP_E1;
        MeanApNBZ_E1.v := LengthS_AP_E1 / NumbS_AP_E1; // E1
      end;
      if NumbS_AP_E1 > 1 then
        StdApNBZ_E1.v := calcStdDev(LengthS_AP_E1, QuadSumSL_AP_E1,
          NumbS_AP_E1);
      if NumbS_AP_E2 > 0 then
      begin
        TotApNBZ_E2.v := LengthS_AP_E2;
        MeanApNBZ_E2.v := LengthS_AP_E2 / NumbS_AP_E2; // E2
      end;
      if NumbS_AP_E2 > 1 then
        StdApNBZ_E2.v := calcStdDev(LengthS_AP_E2, QuadSumSL_AP_E2,
          NumbS_AP_E2);
      if NumbS_AP_E3 > 0 then
      begin
        TotApNBZ_E3.v := LengthS_AP_E3;
        MeanApNBZ_E3.v := LengthS_AP_E3 / NumbS_AP_E3; // E3
      end;
      if NumbS_AP_E3 > 1 then
        StdApNBZ_E3.v := calcStdDev(LengthS_AP_E3, QuadSumSL_AP_E3,
          NumbS_AP_E3);
    end; // if self.PrecDeriveData.Option='high'
  finally
  end;
end;

procedure TSubmodRootStrucNew.resetWLStateArray;
var
  i: integer;
begin
  for i := 0 to high(WLStateArray) do
  begin
    WLStateArray[i].v := 0;
  end;
end;

procedure TSubmodRootStrucNew.dissaggrSegmentTopDown(ASegment_: TSegment;
  lengthASeg: double; currLay: integer);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Methode zerteilt ein Segment, das mehrere Schichten durchstößt, in
  seine Bestandteile, deren Länge dann den einzelnen Segmenten hinzugezählt wird.
  Es wird davon ausgegangen, das das Segment von oben nach unten wächst.
  ------------------------------------------------------------------------------ *)
var
  i, NewCurrLayer: integer;
  upperBorder, lowerBorder, upperBorderNextLay, lowerBorderNextLay,
  // für Strahlensatz
  A, G, lengthASegment, AFragment: double;
begin
  // Bestimmen der oberen und unteren Grenze
  upperBorder := 0;
  lowerBorder := 0;
  for i := 0 to currLay do
  begin
    upperBorder := upperBorder + GaugeArr[i];
    lowerBorder := lowerBorder + GaugeArr[i];
  end;
  upperBorder := lowerBorder - GaugeArr[currLay];
  { Cave: die Schichten liegen ein Stockwerk höher, Schicht high(WLStageArray)
    ist die letzte }
  if (currLay <> high(WLStateArray)) then
  begin
    lowerBorderNextLay := lowerBorder + GaugeArr[currLay + 1];
    upperBorderNextLay := lowerBorder; // wg. Konsistenz
  end;
  // Es ist bekannt, dass Schicht mit Index currLay vollständig durchstoßen wird.
  A := lowerBorder - upperBorder;
  G := ASegment_.ce[2] - ASegment_.co[2];
  AFragment := A / G * lengthASeg;
  WLStateArray[currLay].v := WLStateArray[currLay].v + AFragment;
  { Wenn das Segment in der folgenden Schicht endet -> Berechnung, falls die unters-
    te Schicht Durchstoßen wird, wird der Rest des Segments nicht berücksichtigt }
  if (currLay <> high(WLStateArray)) then
  begin
    if (ASegment_.ce[2] < lowerBorderNextLay) then
    begin
      // Endständiges Teilstück wird berechnet
      AFragment := 0; // Sicherheitshalber
      { Berechnen des Teilstücks, das unterhalb des Durchstoßpunktes liegt. Dieses
        enthält notwendigerweise den Endpunkt des Segmentes }
      A := ASegment_.ce[2] - upperBorderNextLay;
      G := ASegment_.ce[2] - ASegment_.co[2];
      // Strahlensatz
      AFragment := A / G * lengthASeg;
      WLStateArray[currLay + 1].v := WLStateArray[currLay + 1].v + AFragment;
    end
    else // rekursives Aufrufen
    begin
      dissaggrSegmentTopDown(ASegment_, lengthASeg, currLay + 1);
    end;
  end;
end;

function TSubmodRootStrucNew.cutSegment(ASegmentAxis_: TSegment): TSegment;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Schneidet Segmente, die die Seitenflächen des Weltwürfels durch-
  stoßen zu und gibt die Koordinaten des abgeschnittenen Segments zurück.
  Problem: Für das Abschneiden von Segmenten, die die Vertikalen
  ------------------------------------------------------------------------------ *)
var
  ASegment: TSegment;
  xyz: r3;
  orientation: kindPlane;
begin
  { Segmente, die in die Luft wachsen oder den Weltwürfel an der Unterseite ver-
    lassen, werden abgeschnitten. }
  // a) Verlassen der oberen Systemgrenze:
  if ASegmentAxis_.co[2] < 0 then
  begin
    orientation := horizontal;
    ASegment.co := ASegmentAxis_.co;
    ASegment.ce := ASegmentAxis_.ce;
    xyz := solveEquationSystem(ASegment, createHorizontPlane(0), orientation);
    ASegmentAxis_.co[0] := xyz[0];
    ASegmentAxis_.co[1] := xyz[1];
    ASegmentAxis_.co[2] := 0;
  end;
  if ASegmentAxis_.ce[2] < 0 then
  begin
    orientation := horizontal;
    ASegment.co := ASegmentAxis_.co;
    ASegment.ce := ASegmentAxis_.ce;
    xyz := solveEquationSystem(ASegment, createHorizontPlane(0), orientation);
    ASegmentAxis_.ce[0] := xyz[0];
    ASegmentAxis_.ce[1] := xyz[1];
    ASegmentAxis_.ce[2] := 0;
  end;
  // b) Verlassen der unteren Systemgrenze
  if ASegmentAxis_.co[2] > DimZ.v then
  begin
    orientation := horizontal;
    ASegment.co := ASegmentAxis_.co;
    ASegment.ce := ASegmentAxis_.ce;
    xyz := solveEquationSystem(ASegment, createHorizontPlane(DimZ.v),
      orientation);
    ASegmentAxis_.co[0] := xyz[0];
    ASegmentAxis_.co[1] := xyz[1];
    ASegmentAxis_.co[2] := DimZ.v;
  end;
  if ASegmentAxis_.ce[2] > DimZ.v then
  begin
    orientation := horizontal;
    ASegment.co := ASegmentAxis_.co;
    ASegment.ce := ASegmentAxis_.ce;
    xyz := solveEquationSystem(ASegment, createHorizontPlane(DimZ.v),
      orientation);
    ASegmentAxis_.ce[0] := xyz[0];
    ASegmentAxis_.ce[1] := xyz[1];
    ASegmentAxis_.ce[2] := DimZ.v;
  end;

  { // Segmente, die den Weltwürfel an der Vorder- oder Rückseite verlassen, werden
    //abgeschnitten.
    //a) Verlassen der vorderen Systemgrenze:
    if ASegmentAxis_.co[1]<0 then
    begin
    orientation:=vertikal;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createVertikalPlane(0), orientation);
    ASegmentAxis_.co[0]:=xyz[0];
    ASegmentAxis_.co[1]:=xyz[1];
    ASegmentAxis_.co[2]:=xyz[2];
    end;
    if ASegmentAxis_.ce[1]<0 then
    begin
    orientation:=vertikal;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createVertikalPlane(0), orientation);
    ASegmentAxis_.ce[0]:=xyz[0];
    ASegmentAxis_.ce[1]:=xyz[1];
    ASegmentAxis_.ce[2]:=xyz[2];
    end;
    //a) Verlassen der hinteren Systemgrenze:
    if ASegmentAxis_.co[1]>dim_y then
    begin
    orientation:=vertikal;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createVertikalPlane(dim_y), orientation);
    ASegmentAxis_.co[0]:=xyz[0];
    ASegmentAxis_.co[1]:=xyz[1];
    ASegmentAxis_.co[2]:=xyz[2];
    end;
    if ASegmentAxis_.ce[1]>dim_y then
    begin
    orientation:=vertikal;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createVertikalPlane(dim_y), orientation);
    ASegmentAxis_.ce[0]:=xyz[0];
    ASegmentAxis_.ce[1]:=xyz[1];
    ASegmentAxis_.ce[2]:=xyz[2];
    end;
    // Segmente, die den Weltwürfel an der links oder rechts verlassen, werden
    //abgeschnitten.
    //a) Verlassen der linken Systemgrenze:
    if ASegmentAxis_.co[0]<0 then
    begin
    orientation:=saggital;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createSaggitalPlane(0), orientation);
    ASegmentAxis_.co[0]:=xyz[0];
    ASegmentAxis_.co[1]:=xyz[1];
    ASegmentAxis_.co[2]:=xyz[2];
    end;
    if ASegmentAxis_.ce[0]<0 then
    begin
    orientation:=saggital;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createSaggitalPlane(0), orientation);
    ASegmentAxis_.ce[0]:=xyz[0];
    ASegmentAxis_.ce[1]:=xyz[1];
    ASegmentAxis_.ce[2]:=xyz[2];
    end;
    //a) Verlassen der rechten Systemgrenze:
    if ASegmentAxis_.co[0]>dim_x then
    begin
    orientation:=saggital;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createSaggitalPlane(dim_x), orientation);
    ASegmentAxis_.co[0]:=xyz[0];
    ASegmentAxis_.co[1]:=xyz[1];
    ASegmentAxis_.co[2]:=xyz[2];
    end;
    if ASegmentAxis_.ce[0]>dim_x then
    begin
    orientation:=saggital;
    ASegment.coordOrigin:=ASegmentAxis_.co;
    ASegment.coordEnd:=ASegmentAxis_.ce;
    xyz:=distributionCalc.solveEquationSystem(ASegment,
    createSaggitalPlane(dim_x), orientation);
    ASegmentAxis_.ce[0]:=xyz[0];
    ASegmentAxis_.ce[1]:=xyz[1];
    ASegmentAxis_.ce[2]:=xyz[2];
    end; }

  Result := ASegmentAxis_;
end;

procedure TSubmodRootStrucNew.dissaggrSegmentBottomTop(ASegment_: TSegment;
  lengthASeg: double; currLay: integer);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Methode zerteilt ein Segment, das mehrere Schichten durchstößt, in
  seine Bestandteile, deren Länge dann den einzelnen Segmenten hinzugezählt wird.
  Es wird davon ausgegangen, das das Segment von unten nach oben wächst.
  ------------------------------------------------------------------------------ *)
var
  i, NewCurrLayer: integer;
  upperBorder, lowerBorder, upperBorderNextLay, lowerBorderNextLay,
  // für Strahlensatz
  A, G, lengthASegment, AFragment: double;
begin
  // Bestimmen der oberen und unteren Grenze
  upperBorder := 0;
  lowerBorder := 0;
  for i := 0 to currLay do
  begin
    upperBorder := upperBorder + GaugeArr[i];
    lowerBorder := lowerBorder + GaugeArr[i];
  end;
  upperBorder := lowerBorder - GaugeArr[currLay];
  // Cave: die Schichten liegen ein Stockwerk höher, Schicht 0 ist die letzte
  if currLay <> 0 then
  begin
    lowerBorderNextLay := upperBorder; // wg. Konsistenz
    upperBorderNextLay := upperBorder - GaugeArr[currLay - 1];
  end;
  // Es ist bekannt, dass Schicht mit Index currLay vollständig durchstoßen wird.
  A := lowerBorder - upperBorder;
  G := ASegment_.co[2] - ASegment_.ce[2];
  AFragment := A / G * lengthASeg;
  WLStateArray[currLay].v := WLStateArray[currLay].v + AFragment;
  { Wenn das Segment in der folgenden Schicht endet -> Berechnung, falls es in die
    Luft wachsen sollte, wird es nicht berücksichtigt. }
  if currLay <> 0 then
  begin
    if (ASegment_.ce[2] > upperBorderNextLay) then
    begin
      // Endständiges Teilstück wird berechnet
      AFragment := 0; // Sicherheitshalber
      A := upperBorderNextLay - ASegment_.ce[2];
      G := ASegment_.co[2] - ASegment_.ce[2];
      // Strahlensatz
      AFragment := A / G * lengthASeg;
      WLStateArray[currLay - 1].v := WLStateArray[currLay - 1].v + AFragment;
    end
    else // rekursives Aufrufen
    begin
      dissaggrSegmentBottomTop(ASegment_, lengthASeg, currLay - 1);
    end;
  end;
end;

function TSubmodRootStrucNew.calcAbsValue(ASegment_: TSegment): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Function berechnet den Betrag des Vektors zwischen Anfang und End-
  punkt des Segments in R3 und gibt ihn zurürck
  ------------------------------------------------------------------------------ *)
var
  VektSegment, VektCe, VektCo: r3;
  vektLength: double;
begin
  { Berechnung des Vektors, der das Segment beschreibt aus den Ortsvektoren von An-
    fangs- und Endpunkt }
  VektCo := ASegment_.co;
  VektCe := ASegment_.ce;
  VektSegment := vectorSubtrakt(VektCe, VektCo);
  // Berechnung des Betrags des Vektors
  vektLength := sqrt(sqr(VektSegment[0]) + sqr(VektSegment[1]) +
    sqr(VektSegment[2]));
  Result := vektLength;
end;

function TSegment.calcAbsValue(co, ce: r3): double;
var
  VektSegment: r3;
begin
  VektSegment := vectorSubtrakt(ce, co);
  Result := sqrt(sqr(VektSegment[0]) + sqr(VektSegment[1]) +
    sqr(VektSegment[2]));
end;

// Aufräumen
procedure TSubmodRootStrucNew.destroySegmentsRekurs(ASegmentToDestroy
  : TSegment);
(* ------------------------------------------------------------------------------
  Prozedur zerstört das übergeb. Segment und alle Nachkommen und deren Nachkommen usw..
  Markierung für die Zerstörung wäre ebenfalls möglich.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  AnotherSegmentToDestroy: TSegment;
begin
  if ASegmentToDestroy.ChildList <> nil then // sicherheitshalber
  begin
    for i := 0 to ASegmentToDestroy.ChildList.Count - 1 do
    begin
      AnotherSegmentToDestroy := ASegmentToDestroy.ChildList.Items[i];
      destroySegmentsRekurs(AnotherSegmentToDestroy);
    end;
  end;
  if ASegmentToDestroy <> nil then
    ASegmentToDestroy.destroy;
end;

procedure TSubmodRootStrucNew.clearRSListCopy;
var
  i, j: integer;
  ARootSystem: TRootsystem;
  ASegment: TSegment;
begin
  for i := 0 to RSListCopy.Count - 1 do
  begin
    ARootSystem := RSListCopy.Items[i];
    for j := 0 to ARootSystem.SegListEO.Count - 1 do
    begin
      ASegment := ARootSystem.SegListEO.Items[j];
      clearChildListsRekurs(ASegment);
    end;
    ARootSystem.SegListEO.clear;
  end;
  RSListCopy.clear;
end;

procedure TSubmodRootStrucNew.clearChildListsRekurs(ASegment: TSegment);
var
  i: integer;
  AChild: TSegment;
begin
  if ASegment.ChildList <> nil then
  begin
    for i := 0 to ASegment.ChildList.Count - 1 do
    begin
      AChild := ASegment.ChildList.Items[i];
      clearChildListsRekurs(AChild);
    end;
  end;
  ASegment.ChildList.clear;
end;

procedure TSubmodRootStrucNew.destroySRPListContent;
type
  PPoint = ^TPoint;
var
  i, j: integer;
  ASRP: TSRP;
  AvertexList: TList;
  APoint: PPoint;
begin
  for i := 0 to (SRPList.Count - 1) do
  begin
    ASRP := SRPList.Items[i];
    if ASRP.vertexList <> nil then
    begin
      for j := 0 To ASRP.vertexList.Count - 1 do
      begin
        APoint := ASRP.vertexList.Items[j];
        Dispose(APoint);
      end;
    end;
    if ASRP <> nil then
      // if (ASRP<> nil) and (ASRP.RS_Id<>9999) then
      ASRP.destroy;
  end;
end;

procedure TSubmodRootStrucNew.clearSMLists;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Leeren von Listen des Strukturmodells
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  ASegList: TList;
  ABranchDensObj: TBranchDensPrim;
  APotSeg: TPotSeg;
  APotSegListWS: TList;
  ARootSystem: TRootsystem;
begin
  if SegListWS <> nil then
  begin
    for i := 0 to SegListWS.Count - 1 do
    begin
      ASegList := TList(SegListWS.Items[i]);
      ASegList.clear;
    end;
    SegListWS.clear;
  end;
  if PotSegListTot <> nil then
  begin
    for i := 0 to PotSegListTot.Count - 1 do
    begin
      APotSegListWS := PotSegListTot.Items[i];
      for j := 0 to APotSegListWS.Count - 1 do
      begin
        APotSeg := APotSegListWS.Items[j];
        APotSeg.Free;
      end;
    end;
  end;
  for i := 0 to self.RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    ARootSystem.PotSegListWS.clear;
  end;
  if BranchDensPrimRoots <> nil then
  begin
    for i := 0 to BranchDensPrimRoots.Count - 1 do
    begin
      ABranchDensObj := BranchDensPrimRoots.Items[i];
      ABranchDensObj.Free;
    end;
    BranchDensPrimRoots.clear;
  end;
  PotSegListTot.clear;
  // Löschen alter Einträge in der IntersectList und PseudoIntersectList:
  if SegListIntersect <> nil then
    SegListIntersect.clear;
  if PseudoSegListIntersect <> nil then
    PseudoSegListIntersect.clear;
end;

procedure TSubmodRootStrucNew.resetFiles;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Löschen und Neuanlage von Dateien
  ------------------------------------------------------------------------------ *)
var
  fIntFile, faggrRootData, fseg: TextFile;
  headerSeg, headerIntersect: string;
begin
  headerSeg := 'Simzeit' + ' ' + 'SegNr.' + ' ' + 'Father_ID' + ' ' + 'Ord' +
    ' ' + 'RSID' + ' ' + 'coX' + ' ' + 'coY' + ' ' + 'coZ' + ' ' + 'ceX' + ' ' +
    'ceY' + ' ' + 'ceZ' + ' ' + 'segLength' + ' ' + 'ElongA' + ' ' + 'ElongB' +
    ' ' + 'ParRam' + ' ' + 'Merisnr.' + ' ' + 'Maturity' + ' ' + 'Activity';
  headerIntersect := 'Seg-Nr.' + ',' + 'X' + ',' + 'Y';
  // intersect.csv
  assignfile(fIntFile, IntersectFile.Option);
  rewrite(fIntFile);
  writeln(fIntFile, headerIntersect);
  closefile(fIntFile);
  // aggrRootData.csv
  assignfile(faggrRootData, AggrRootData.Option);
  rewrite(faggrRootData);
  closefile(faggrRootData);
  // SegFile.csv
  assignfile(fseg, SegFile.Option);
  rewrite(fseg);
  writeln(fseg, headerSeg);
  closefile(fseg);

end;

procedure TSubmodRootStrucNew.resetSMLists;
(* ------------------------------------------------------------------------------
  Methode löscht die Inhalte sämtlicher Listen, die das Strukturmodell besitzt.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  ASRP: TSRP;
  ASRPLight: TSRPLight;
  ARootSystem: TRootsystem;
  ASegList: TList;
  ABranchDensObj: TBranchDensPrim;
begin
  { Segmente sind bereits gelöscht, es gibt nur noch die Zeiger, ebenso
    wurden mit den WS die Inhalte der SegListWS gelöscht. }
  if SegListWS <> nil then
    SegListWS.clear;
  if SegListIntersect <> nil then
  begin
    { Enthält Segmente, die wurden bereits gelöscht. }
    SegListIntersect.clear;
  end;
  if SRPList <> nil then
  begin
    for i := 0 to SRPList.Count - 1 do
    begin
      ASRP := SRPList.Items[i];
      if ASRP <> nil then
        ASRP.destroy;
    end;
    SRPList.clear;
  end;
  if RSList <> nil then
    RSList.clear;
  if RSListCopy <> nil then
    RSListCopy.clear;
  if SRPLightList <> nil then
  begin
    for i := 0 to SRPLightList.Count - 1 do
    begin
      ASRPLight := SRPLightList.Items[i];
      ASRPLight.Free;
    end;
    SRPLightList.clear;
  end;
  if PaintList <> nil then
    PaintList.clear;
  if BranchDensPrimRoots <> nil then
  begin
    for i := 0 to BranchDensPrimRoots.Count - 1 do
    begin
      ABranchDensObj := BranchDensPrimRoots.Items[i];
      ABranchDensObj.Free;
    end;
    BranchDensPrimRoots.clear
  end;
  if PotSegListTot <> nil then // Inhalte mit WS zerstört
    PotSegListTot.clear;
  { PseudoSegListIntersect: enthält TPotSeg, wurden mit WS zerstört. }
  if PseudoSegListIntersect <> nil then
    PseudoSegListIntersect.clear;
end;

procedure TSubmodRootStrucNew.copyRootSystems;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Kopiert sämtliche Wurzelsysteme und fügt diese in eine Liste ein.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  ARootSystem, ARootSystemCopy: TRootsystem;
begin
  for i := 0 to RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    ARootSystemCopy := TRootsystem.create;
    ARootSystemCopy.assign(ARootSystem);
    RSListCopy.Add(ARootSystemCopy);
  end;
end;

procedure TSubmodRootStrucNew.destroyARootSystem(var ARootSystemToDestroy
  : TRootsystem);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Methode für DummyGrowth: Zerstört das 1.WS in der RS-Liste
  ------------------------------------------------------------------------------ *)
var
  j: integer;
  ASegment: TSegment;
  APotSeg: TPotSeg;
begin
  // zuerst müssen die zusammengesetzten Segmente zerstört werden
  if ARootSystemToDestroy.SegListTotal <> nil then
    ARootSystemToDestroy.clearSegListTotal;
  for j := 0 to ARootSystemToDestroy.SegListEO.Count - 1 do
  begin
    ASegment := ARootSystemToDestroy.SegListEO[j];
    destroySegmentsRekurs(ASegment);
  end;
  if ARootSystemToDestroy.PotSegListWS <> nil then
  begin
    for j := 0 to ARootSystemToDestroy.PotSegListWS.Count - 1 do
    begin
      APotSeg := ARootSystemToDestroy.PotSegListWS[j];
      APotSeg.Free;
    end;
    ARootSystemToDestroy.PotSegListWS.clear;
  end;
  if ARootSystemToDestroy <> nil then
    ARootSystemToDestroy.destroy;
end;

procedure TSubmodRootStrucNew.destroyRootSystems(RSList: TList);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Zerstört die Wurzelsysteme, die sich in der übergebenen
  Liste befinden, und rekursiv die Inhalte
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  ARootSystem: TRootsystem;
  ASegment: TSegment;
  APotSeg: TPotSeg;
begin
  for i := 0 to RSList.Count - 1 do
  begin
    ARootSystem := RSList.Items[i];
    ARootSystem.clearSegListTotal; // Zerstören der zusammengesetzten Segmente
    for j := 0 to ARootSystem.SegListEO.Count - 1 do
    // Zerstören der Knotenstruktur
    begin
      ASegment := ARootSystem.SegListEO[j];
      destroySegmentsRekurs(ASegment);
    end;
    // destroySegmentsRekurs(ARootsystem);
    if ARootSystem.PotSegListWS <> nil then
    begin
      for j := 0 to ARootSystem.PotSegListWS.Count - 1 do
      begin
        APotSeg := ARootSystem.PotSegListWS[j];
        APotSeg.Free;
      end;
      ARootSystem.PotSegListWS.clear;
    end;
    if ARootSystem <> nil then
      ARootSystem.destroy;
  end;
  // Löschen der Listen mit pot. Segmenten (Gesamtliste des Strukturmodells)
  PotSegListTot.clear;
  RSList.clear;
end;

procedure TSubmodRootStrucNew.assignParameter;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Prozedur ersetzt die ursprüngliche Prozedur litParam, die das
  Einlesen der Parameterwerte bisher übernommen hat. Parameterwerte in die Arrays
  geschrieben, die vom Pages-Modell verwendet werden.
  Methode wurde so implementiert, dass die ursprüngliche Struktur von Pages erhalten
  wurde (Arrays mit Kombinationen Internodium und Entwicklungsordnung), allerdings
  existieren bei dieser Implementierung KEINE Unterschiede zwischen den Internodien
  im Bedarfsfall kann diese Modelleigenschaft aber einfach wieder berücksichtigt
  werden.
  ------------------------------------------------------------------------------ *)
var
  i, internod, ord: integer;
  // internod (Internodium), ord (Entwicklungsordnung)
begin
  Par_Emiss[0] := Par_begin.v;
  Par_Emiss[1] := Par_disposition.v;
  for internod := 0 to NumberINTMAX - 1 do // für alle Internodien
  begin
    // Internodienspez. Belegung des Emissionsparameters
    Par_NumberPrE[internod] := trunc(Par_EmissArr[internod].v);
    for ord := 0 to NumberORDMAX - 1 do // für alle 3 Entwicklungsordnungen
    begin
      // Unterscheidung nach Entwicklungsordnung
      if ord = 0 then
      begin
        Par_NumberGen[ord, internod] := trunc(Par_numberGen_Ord1.v);
        self.Par_AngIAver[ord, internod] := Par_AverAngleInsert_Ord1.v;
        Par_AngIDeviat[ord, internod] := Par_StdDevAngleInsert_Ord1.v;
        Par_DurDevPrim[ord, internod] := Par_developPrim_Ord1.v;
        Par_GrowthAver[0, ord, internod] := Par_AverGrowthA_Ord1.v;
        Par_GrowthAver[1, ord, internod] := Par_AverGrowthB_Ord1.v;
        Par_GrowthDeviat[0, ord, internod] := Par_StdDevGrowthA_Ord1.v;
        Par_GrowthDeviat[1, ord, internod] := Par_StdDevGrowthB_Ord1.v;
        Par_RamifAver[ord, internod] := Par_AverRamific_Ord1.v;
        Par_RamifDeviat[ord, internod] := Par_StdDevRamific_Ord1.v;
        Par_Geo[ord, internod] := Par_Coeff_Geo_Ord1.v;
        Par_CMechanic[ord, internod] := Par_mechResist_Ord1.v;
      end;
      if ord = 1 then
      begin
        Par_NumberGen[ord, internod] := trunc(Par_numberGen_Ord2.v);
        Par_AngIAver[ord, internod] := Par_AverAngleInsert_Ord2.v;
        Par_AngIDeviat[ord, internod] := Par_StdDevAngleInsert_Ord2.v;
        Par_DurDevPrim[ord, internod] := Par_developPrim_Ord2.v;
        Par_GrowthAver[0, ord, internod] := Par_AverGrowthA_Ord2.v;
        Par_GrowthAver[1, ord, internod] := Par_AverGrowthB_Ord2.v;
        Par_GrowthDeviat[0, ord, internod] := Par_StdDevGrowthA_Ord2.v;
        Par_GrowthDeviat[1, ord, internod] := Par_StdDevGrowthB_Ord2.v;
        Par_RamifAver[ord, internod] := Par_AverRamific_Ord2.v;
        Par_RamifDeviat[ord, internod] := Par_StdDevRamific_Ord2.v;
        Par_Geo[ord, internod] := Par_Coeff_Geo_Ord2.v;
        Par_CMechanic[ord, internod] := Par_mechResist_Ord2.v;
      end;
      if ord = 2 then
      begin
        Par_NumberGen[ord, internod] := trunc(Par_numberGen_Ord3.v);
        Par_AngIAver[ord, internod] := Par_AverAngleInsert_Ord3.v;
        Par_AngIDeviat[ord, internod] := Par_StdDevAngleInsert_Ord3.v;
        Par_DurDevPrim[ord, internod] := Par_developPrim_Ord3.v;
        Par_GrowthAver[0, ord, internod] := Par_AverGrowthA_Ord3.v;
        Par_GrowthAver[1, ord, internod] := Par_AverGrowthB_Ord3.v;
        Par_GrowthDeviat[0, ord, internod] := Par_StdDevGrowthA_Ord3.v;
        Par_GrowthDeviat[1, ord, internod] := Par_StdDevGrowthB_Ord3.v;
        Par_RamifAver[ord, internod] := Par_AverRamific_Ord3.v;
        Par_RamifDeviat[ord, internod] := Par_StdDevRamific_Ord3.v;
        Par_Geo[ord, internod] := Par_Coeff_Geo_Ord3.v;
        Par_CMechanic[ord, internod] := Par_mechResist_Ord3.v;
      end;
      if ord = 3 then
      begin
        Par_NumberGen[ord, internod] := trunc(Par_numberGen_Ord4.v);
        Par_AngIAver[ord, internod] := Par_AverAngleInsert_Ord4.v;
        Par_AngIDeviat[ord, internod] := Par_StdDevAngleInsert_Ord4.v;
        Par_DurDevPrim[ord, internod] := Par_developPrim_Ord4.v;
        Par_GrowthAver[0, ord, internod] := Par_AverGrowthA_Ord4.v;
        Par_GrowthAver[1, ord, internod] := Par_AverGrowthB_Ord4.v;
        Par_GrowthDeviat[0, ord, internod] := Par_StdDevGrowthA_Ord4.v;
        Par_GrowthDeviat[1, ord, internod] := Par_StdDevGrowthB_Ord4.v;
        Par_RamifAver[ord, internod] := Par_AverRamific_Ord4.v;
        Par_RamifDeviat[ord, internod] := Par_StdDevRamific_Ord4.v;
        Par_Geo[ord, internod] := Par_Coeff_Geo_Ord4.v;
        Par_CMechanic[ord, internod] := Par_mechResist_Ord4.v;
      end;
    end;
  end;
end;

// Set und Get

function TSubmodRootStrucNew.getSRPList: TList;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Schnittstelle zum 2D-Diffusionsmodell. Dabei muss Zeiger vom
  Diffusionsmodell auf das Strukturmodell gesetzt werden. Auf Anfrage wird ab-
  gespeckte Version der SRPList erstellt und übergeben
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  ASRP: TSRP;
  ASRPLight: TSRPLight;
begin
  if SRPLightList <> nil then
  begin
    SRPLightList.clear;
  end;
  for i := 0 to self.SRPList.Count - 1 do
  begin
    ASRP := SRPList.Items[i];
    ASRPLight := TSRPLight.create;
    ASRPLight.x := ASRP.x;
    ASRPLight.y := ASRP.y;
    if ASRP.area <> 0 then
      ASRPLight.wld := 1 / ASRP.area;
    SRPLightList.Add(ASRPLight);
  end;
  Result := SRPLightList;
end;

{ *------------------------------------------------------------------------------
  Hilfsmethoden Strukturmodell Ende
  ------------------------------------------------------------------------------*)

  { TMeristem }
constructor TMeristem.create;
begin
  inherited create;
  PointsOfRam := TList.create;
  ThresBranchFirst := false;
  // PotRamListEmpty:=false;
  haspotRam := false;
end;

destructor TMeristem.destroy;
var
  AKoord: TR3;
  i: integer;
begin
  if self <> nil then
  begin
    if PointsOfRam <> nil then
    begin
      for i := 0 to PointsOfRam.Count - 1 do
      begin
        AKoord := PointsOfRam[i];
        AKoord.Free;
      end;
      PointsOfRam.clear;
      PointsOfRam.Free;
    end;
  end;
  inherited destroy;
end;

procedure TMeristem.assign(Source: TMeristem);
var
  i: integer;
  ARamPoint, LastRamPoint: TR3;
begin
  // NumSegProd:=TMeristem(Source).NumSegProd;
  Order := TMeristem(Source).Order;
  num := TMeristem(Source).num;
  Internode := TMeristem(Source).Internode;
  DistBase := TMeristem(Source).DistBase;
  DistPrimInit := TMeristem(Source).DistPrimInit;
  Coord := TMeristem(Source).Coord;
  Coordold := TMeristem(Source).Coordold;
  DirGrowth := TMeristem(Source).DirGrowth;
  Age := TMeristem(Source).Age;
  PRamif := TMeristem(Source).PRamif;
  PRamifold := TMeristem(Source).PRamifold;
  PCroiss := TMeristem(Source).PCroiss;
  Activ := TMeristem(Source).Activ;
  Maturity := TMeristem(Source).Maturity;
  haspotRam := TMeristem(Source).haspotRam;
  ThresBranchFirst := TMeristem(Source).ThresBranchFirst;
  if PointsOfRam <> nil then
  begin
    for i := 0 to TMeristem(Source).PointsOfRam.Count - 1 do
    begin
      ARamPoint := TR3.create;
      ARamPoint.assign(TMeristem(Source).PointsOfRam.Items[i]);
      PointsOfRam.Add(ARamPoint);
      PointsOfRam.Pack;
      PointsOfRam.Capacity := PointsOfRam.Count;
    end;
  end;
  sumElongNew := TMeristem(Source).sumElongNew;
  sumElongOld := TMeristem(Source).sumElongOld;
  remainderElong := TMeristem(Source).remainderElong;
  basNVZ := TMeristem(Source).basNVZ;
  Remcoord := TMeristem(Source).Remcoord;
  LastRamPoint := TR3.create;
  { if TMeristem(Source).LastRamPoint <> nil then
    begin
    LastRamPoint.Koord3D[0]:=TMeristem(Source).LastRamPoint.Koord3D[0];
    LastRamPoint.Koord3D[1]:=TMeristem(Source).LastRamPoint.Koord3D[1];
    LastRamPoint.Koord3D[2]:=TMeristem(Source).LastRamPoint.Koord3D[2];
    end; }
end;

procedure TSubmodRootStrucNew.drawSegmentPart(co, ce: r3; Internode: byte);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: zeichnet das neu hinzugekomme Teilstück
  ------------------------------------------------------------------------------ *)
begin
  { Festlegen unterschiedlicher Farben für jedes Internodium }
  If Internode = 0 then
    FormShowGrowth.MathImageRoot.Canvas.Pen.Color := clblack;
  If Internode = 1 then
    FormShowGrowth.MathImageRoot.Canvas.Pen.Color := clblack;
  If Internode = 2 then
    FormShowGrowth.MathImageRoot.Canvas.Pen.Color := clblack;
  If Internode = 3 then
    FormShowGrowth.MathImageRoot.Canvas.Pen.Color := clblack;
  If Internode = 4 then
    FormShowGrowth.MathImageRoot.Canvas.Pen.Color := clblack;
  If Internode = 5 then
    FormShowGrowth.MathImageRoot.Canvas.Pen.Color := clblack;
  { Erläuterung zur Methode d3Moveto:
    Aus der Hilfe von TMathImage: Methode setzt den Grafik-cursor auf den Punkt mit
    den D3-Weltkoordinaten (x,y,z). Syntax:
    procedure TMathImage.d3Moveto( x , y , z : MathFloat)
    Zum Typ MathFloat: This type is currently set to double. Change it according to
    your needs in the WorldDrawing unit) }
  FormShowGrowth.MathImageRoot.d3Moveto(co[0], co[1], -1 * co[2]);
  { Erläuterung zur Methode d3DrawLineto:
    Aus der Hilfe von TMathImage: Zeichnet von der aktuellen Position des Grafik-
    cursors (s. d3Moveto) zum Punkt (x,y,z) in D3 Weltkoordinaten. Die Methode zeichnet
    den Endpixel nicht)
    Syntax:
    procedure TMathImage.d3DrawLineto( x , y , z : MathFloat) }
  FormShowGrowth.MathImageRoot.d3DrawLineto(ce[0], ce[1], -1 * ce[2]);
end;

procedure TSubmodRootStrucNew.growthAndRamifRec(ASegment: TSegment;
  PrimRootID: integer; var ARootsystem_: TRootsystem);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Neu hinzugefügte Methode für rekursiven Aufruf des
  Wachstumsvorgangs, Für diese Methode gibt es Manuskript für die Erläuterung der
  Methode
  ------------------------------------------------------------------------------ *)
var
  TotNVZ, ApNVZ: double;
  i: integer;
  AChild: TSegment;
  firstEntry: boolean;
  ACopyRamPoint: TR3;
begin
  // Wachstum von Segmenten [die dieses können]
  if ASegment.Meristem <> nil then
  begin
    if ASegment.Meristem <> nil then
      // ASegment.Meristem.updateRemcoord;
      // firstEntry:=true;
      Growth(ASegment);
    if (ASegment.Meristem.sumElongNew > 0) and
      (ASegment.Meristem.sumElongNew > ASegment.Meristem.basNVZ) and
      (ASegment.Meristem.PointsOfRam.Count = 0) then
      ASegment.Meristem.ThresBranchFirst := true;
    // Nach Verlängerung werden die pot. Verzweigungsstellen bestimmt
    // a) Bestimmung des 1. Punktes
    if (ASegment.Meristem.basNVZ > 0) and
      (ASegment.Meristem.ThresBranchFirst = true) then
    begin
      if (debugging = true) and (dummyGrowth = false) then
      begin
        assignfile(fpotFile, PotFile);
        append(fpotFile);
        write(fpotFile, inttostr(ASegment.num));
        closefile(fpotFile);
      end;
      ASegment.Meristem.findFirstRamPoint;
      ASegment.Meristem.ThresBranchFirst := false;
    end;
    { Sonderfall: bas. NVZ hat Länge 0. Man muss warten, bis die Gesamtlänge
      >= PRamif ist }
    if (ASegment.Meristem.basNVZ = 0) and
      (ASegment.Meristem.ThresBranchFirst = true) and
      (ASegment.Meristem.sumElongNew > ASegment.Meristem.PRamif) then
    begin
      if (debugging = true) and (dummyGrowth = false) then
      begin
        assignfile(fpotFile, PotFile);
        append(fpotFile);
        write(fpotFile, inttostr(ASegment.num));
        closefile(fpotFile);
      end;
      ASegment.Meristem.findFirstNoBas;
      ASegment.Meristem.ThresBranchFirst := false;
    end;
    // Nach Beendigung der Bestimmung des ersten Punktes kann die Länge aus dem Zeit-
    // schritt aktualisiert werden.
    ASegment.Meristem.sumElongOld := ASegment.Meristem.sumElongNew;
    ASegment.Meristem.updateRemcoord;
    { wenn der erste Verzweigungspunkt bestimmt ist, können in Abhängigkeit davon
      weitere pot. Verzweigungspunkte bestimmt werden.
      Der erste potentielle Punkt bei einer neuen Wachstumsrichtung muss dabeu ausgehend
      von dem Endpunkt des letzten Segments bestimmt werden. Dies soll aber nicht im
      Zeitschritt passieren, in dem das Meristem zum ersten Mal pot. Verzweigungspunkte
      anlegt. }
    if (ASegment.Meristem.sumElongNew > ASegment.Meristem.basNVZ) and
      (ASegment.Meristem.ThresBranchFirst = false) then
    begin
      if (ASegment.Meristem.haspotRam = true) and
        (ASegment.Meristem.remainderElong > ASegment.Meristem.PRamif) then
      begin
        ASegment.Meristem.findFirstRamNewDir;
        TR3(ASegment.Meristem.PointsOfRam[0])
          .assign(TR3(ASegment.Meristem.PointsOfRam.last));
      end;
      ASegment.Meristem.haspotRam := true;
      while ASegment.Meristem.remainderElong > ASegment.Meristem.PRamif do
      begin
        if (debugging = true) and (dummyGrowth = false) then
        begin
          assignfile(fpotFile, PotFile);
          append(fpotFile);
          write(fpotFile, inttostr(ASegment.num));
          closefile(fpotFile);
        end;
        ASegment.Meristem.findFurtherRamPoint;
        ASegment.Meristem.remainderElong := ASegment.Meristem.remainderElong -
          ASegment.Meristem.PRamif;
      end;
      TR3(ASegment.Meristem.PointsOfRam[0])
        .assign(TR3(ASegment.Meristem.PointsOfRam.last));
    end;
    // notwendige Updates
    ASegment.Meristem.Coordold := ASegment.Meristem.Coord;
    ASegment.Meristem.remainderElongOld := ASegment.Meristem.remainderElong;
    // Berechnung der tatsächlichen Verzweigung
    if ((ASegment.Meristem.DistPrimInit > 0) and (ASegment.Meristem.basNVZ > 0))
      or ((ASegment.Meristem.DistPrimInit > ASegment.Meristem.PRamif) and
      (ASegment.Meristem.basNVZ = 0)) then
    begin
      RamificationRec(ASegment, PrimRootID, ARootsystem_);
    end;
  end

  { Fall 1: Segment hat ein Meristem, dann solle es wachsen und sich verzweigen.
    Diese Abkömmlinge werden im Zeitschritt nicht weiter berücksichtigt.
    Fall 2: Segment hat Abkömmlinge, die durchlaufen werden müssen, um die Kinder
    zu finden, die Meristeme haben. }
  else
  begin
    if ASegment.ChildList <> nil then
    begin
      For i := 0 to ASegment.ChildList.Count - 1 do
      begin
        AChild := ASegment.ChildList.Items[i];
        growthAndRamifRec(AChild, PrimRootID, ARootsystem_);
      end;
    end;
  end;
end;

procedure TSubmodRootStrucNew.delMerisNonActiv(ASegment: TSegment);
(* ------------------------------------------------------------------------------
  Entfernt nicht-aktive Meristeme  USL-> Funktion checken
  ------------------------------------------------------------------------------ *)
var
  AChild: TSegment;
  i: integer;
begin
  if ASegment.Meristem <> nil then
  begin
    if ASegment.Meristem.Activ = false then
    begin
      if ASegment.Meristem <> nil then
        ASegment.Meristem.destroy;
      ASegment.Meristem := nil;
    end;
  end;
  if ASegment.ChildList <> nil then
  begin
    for i := 0 to ASegment.ChildList.Count - 1 do
    begin
      AChild := ASegment.ChildList.Items[i];
      delMerisNonActiv(AChild);
    end;
  end;
end;

function TSubmodRootStrucNew.calcTempDepthPorter(depth: double): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Bodentemp. in Abhängigkeit von der Luftemperatur,
  wobei von einem linearen Temp-Verlauf bis in die Tiefe von 1m ausgegangen wird.
  Modellannahme: In der Tiefe von 1m herrscht das ganze Jahr über eine Temp., die
  dem Jahresmittel der Lufttemperatur entspricht.
  ------------------------------------------------------------------------------ *)
var
  TempAir, TempSoil: double;
  year, month, day: word;
  SimTime: TDateTime;
begin
  DecodeDate(Globmod.Time.v, year, month, day);
  TempAir := TempArrMonth[month];
  { im Bereich von 0 bis 100cm verändert sich die Temp, in tieferen Regionen ändert
    sich die Temp. nicht mehr }
  if depth > 100 then
    depth := 100;
  TempSoil := (avTempYear.v - TempAir) / 100 * depth + TempAir;
  Result := TempSoil;
end;

function TSubmodRootStrucNew.calcImpedFact(TempSoil: double): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung des Impedenzfaktors nach Clausnitzer und Hopmans mit
  Hilfe einer Sinusfunktion der Temp., die normalisiert über Tmax-Tmin wurde,
  optimale Temperatur liegt in der Mitte
  ------------------------------------------------------------------------------ *)
var
  ImpFact, RelDegreePi: double;
begin
  RelDegreePi := Pi / (Tmax.v - Tmin.v);
  ImpFact := sin((TempSoil - Tmin.v) * RelDegreePi);
  Result := ImpFact;
end;

function TSubmodRootStrucNew.ContainerGrowth2D(var ASegment: TSegment;
  GrowthDir: r3): r2;
(* ------------------------------------------------------------------------------
  Berechnet das Wachstum von Segmenten, die an eine Container-Grenze stoßen.
  Annahmen:
  - Ablenkung der Wurzeln beim Treffen auf eine Containerwand erfolgt lotrecht nach
  unten
  - Alle Pflanzen wachsen in Containern
  - Der Ort der Aussaat befindet sich exakt in der Container-Mitte (am sinnvollsten
  wäre eine Simulation mit Einstellung Single-Plant (sonst könnte es sein, dass
  sich Containergrenzen überlappen)
  - Jeder Container enthält genau eine Pflanze
  Problem: Das neue Segment ist kürzer als das alte
  ------------------------------------------------------------------------------ *)
var
  // Projektion des Segmentbeginns auf die Ebene der Bodenoberfläche
  ProjCO,
  // Projektion der Segmentspitze auf die Ebene der Bodenoberfläche
  ProjCE,
  // Richtungsvekt Proj.
  r,
  // Projizierte Schnittpunkte
  ProjS1, ProjS2, ProjSSel, // Ausgewählter Schnittpunkt (liegt auf der Wurzel)
  // Richtungsvektor ProjSSel zum Kreismittelpunkt
  SelCenter,
  // Normalvektor zu SelCenter
  Norm,
  // Richtungsvektor Punkt ProjCe -> ProjS
  RVektCE_S: r2;
  // Komponenten der pq-Formel
  A, b, c,
  // Koeffizienten der Vektor-Geradengleichung
  s1, s2,
  // Abstände Ce zu den Schnittpunkten
  distS1, distS2: double;
begin
  // Projektion des neu hinzugekommenen Teil-Segments auf die Ebene der Bodenoberfläche
  { Bisher ist nur das Meristem an die neue Spitze versetzt worden }
  ProjCO[0] := ASegment.getCe[0];
  ProjCO[1] := ASegment.getCe[1];
  ProjCE[0] := ASegment.Meristem.Coord[0];
  ProjCE[1] := ASegment.Meristem.Coord[1];
  r[0] := ProjCE[0] - ProjCO[0];
  r[1] := ProjCE[1] - ProjCO[1];
  A := sqr(r[0]) + sqr(r[1]);
  b := 2 * (ProjCO[0] * r[0] + ProjCO[1] * r[1] - r[0] * ContainerCenter[0] -
    r[1] * ContainerCenter[1]);
  c := -(sqr(contRad.v) - sqr(ContainerCenter[0]) - sqr(ContainerCenter[1]) -
    sqr(ProjCO[0]) - sqr(ProjCO[1]) + 2 * ProjCO[0] * ContainerCenter[0] + 2 *
    ProjCO[1] * ContainerCenter[1]);
  // pq-Formel:
  s1 := (-b + sqrt(sqr(b) - 4 * A * c)) / (2 * A);
  s2 := (-b - sqrt(sqr(b) - 4 * A * c)) / (2 * A);
  // Projizierte Schnittpunkte
  ProjS1[0] := ProjCO[0] + s1 * r[0];
  ProjS1[1] := ProjCO[1] + s1 * r[1];
  ProjS2[0] := ProjCO[0] + s2 * r[0];
  ProjS2[1] := ProjCO[1] + s2 * r[1];
  { Test, ob Schnittpunkt S1 Element des Richtungsvektors ist, d.h. Abstand zum
    richtigen Punkt ist kürzer als: }
  RVektCE_S[0] := ProjCE[0] - ProjS1[0];
  RVektCE_S[1] := ProjCE[1] - ProjS1[1];
  distS1 := sqrt(sqr(RVektCE_S[0]) + sqr(RVektCE_S[1]));
  RVektCE_S[0] := ProjCE[0] - ProjS2[0];
  RVektCE_S[1] := ProjCE[1] - ProjS2[1];
  distS2 := sqrt(sqr(RVektCE_S[0]) + sqr(RVektCE_S[1]));
  if distS1 < distS2 then
  begin
    ProjSSel[0] := ProjS1[0];
    ProjSSel[1] := ProjS1[1];
  end
  else
  begin
    ProjSSel[0] := ProjS2[0];
    ProjSSel[1] := ProjS2[1];
  end;
  Result := ProjSSel;
end;

function TSubmodRootStrucNew.testBeyondContainer(var ASegment: TSegment;
  GrowthDir: r3): boolean;
var
  crossBoundary: boolean;
  AProjSegment, // Projiziertes Segment (ortsvektor Spitze)
  VectCenterProjSeg: r2;
  LengthVekt: double; // Abstand zwischen Containermitte und Ende des proj. Seg.
begin
  (* ------------------------------------------------------------------------------
    testet, ob beim Wachstum die containergrenze überschritten würde
    ------------------------------------------------------------------------------ *)
  crossBoundary := false;
  // Hinweis: zu diesem Moment hat nur das Meristem die korrekten Koordinaten
  AProjSegment[0] := ASegment.Meristem.Coord[0];
  AProjSegment[1] := ASegment.Meristem.Coord[1];
  VectCenterProjSeg[0] := AProjSegment[0] - ContainerCenter[0];
  VectCenterProjSeg[1] := AProjSegment[1] - ContainerCenter[1];
  LengthVekt := sqrt(sqr(VectCenterProjSeg[0]) + sqr(VectCenterProjSeg[1]));
  if LengthVekt >= self.contRad.v then
  begin
    crossBoundary := true;
  end;
  Result := crossBoundary;
end;

procedure TSubmodRootStrucNew.writeSegInfo;
(* ------------------------------------------------------------------------------
  Schreiben von Infos über aktuell vorhandene Segmente in jedem Zeitschritt
  CAVE: Für den Abgleich mit den von HUME produzierten Dat-Dateien muss beim
  Schreiben der Simzeit Globtime.v um 1 zurückgesetzt werden
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  fseg: TextFile;
  ARootSystem: TRootsystem;
  ASegmentEO: TSegment;
  infostring: string;
begin
  { Info:headerSeg:='Simzeit'+' '+'SegNr.'+' '+'Father_ID'+' '+'Ord'+' '+'RSID'+' '+'coX'+' '
    +'coY'+' '+'coZ'+' '+'ceX'+' '+'ceY'+' '+'ceZ'+' '+'segLength'
    +' '+'ElongA'+' '+'ElongB'+' '+'ParRam'+' '+'Merisnr.'+' '+'Maturity'+' '+'Activity'; }
  try
    // if (Globtime.v>=38631) then begin     //Debugging
    for i := 0 to RSList.Count - 1 do
    begin
      ARootSystem := RSList.Items[i];
      for j := 0 to ARootSystem.SegListEO.Count - 1 do
      begin
        ASegmentEO := ARootSystem.SegListEO.Items[j];
        if ASegmentEO.ChildList <> nil then
        begin
          writeSegInfoRekursive(ASegmentEO);
        end
        else
        begin
          assignfile(fseg, SegFile.Option);
          append(fseg);
          writeln(fseg);
          ASegmentEO := ARootSystem.SegListEO.Items[i];
          infostring := floattostr(GlobTime.v - 1) + ' ' +
            inttostr(ASegmentEO.num) + ' ' + inttostr(ASegmentEO.FatherID) + ' '
            + inttostr(ASegmentEO.Order) + ' ' + inttostr(ASegmentEO.RS_ID) +
            ' ' + floattostr(ASegmentEO.co[0]) + ' ' +
            floattostr(ASegmentEO.co[1]) + ' ' + floattostr(ASegmentEO.co[2]) +
            ' ' + floattostr(ASegmentEO.ce[0]) + ' ' +
            floattostr(ASegmentEO.ce[1]) + ' ' + floattostr(ASegmentEO.ce[2]) +
            ' ' + floattostr(ASegmentEO.SegLength);
          if ASegmentEO.Meristem <> nil then
          begin
            infostring := infostring + floattostr(ASegmentEO.Meristem.PCroiss[0]
              ) + ' ' + floattostr(ASegmentEO.Meristem.PCroiss[1]) + ' ' +
              floattostr(ASegmentEO.Meristem.PRamif) + ' ' +
              inttostr(ASegmentEO.Meristem.num);
            if ASegmentEO.Meristem.Maturity = true then
              infostring := infostring + ' ' + 'true'
            else
              infostring := infostring + ' ' + 'false';
            if ASegmentEO.Meristem.Activ = true then
              infostring := infostring + ' ' + 'true'
            else
              infostring := infostring + ' ' + 'false';

          end
          else
          begin
            infostring := infostring + 'MerisNil' + ' ' + 'MerisNil' + ' ' +
              'MerisNil' + ' ' + 'MerisNil' + ' ' + 'MerisNil';
          end;
          write(fseg, infostring);
          writeln(fseg);
          closefile(fseg);
        end;
      end;
      // end; //End if (Globtime.v>=38631)
    end;
  finally
    // closefile(fseg);
  end;
end;

procedure TSubmodRootStrucNew.writeSegInfoRekursive(AFather: TSegment);
(* ------------------------------------------------------------------------------
  Für rekursives Schreiben ohne erneutes assign und append
  ------------------------------------------------------------------------------ *)
var
  infostring: string;
  fseg: TextFile;
  AChild: TSegment;
  i: integer;
begin
  assignfile(fseg, SegFile.Option);
  append(fseg);
  infostring := floattostr(GlobTime.v - 1) + ' ' + inttostr(AFather.num) + ' ' +
    inttostr(AFather.FatherID) + ' ' + inttostr(AFather.Order) + ' ' +
    inttostr(AFather.RS_ID) + ' ' + floattostr(AFather.co[0]) + ' ' +
    floattostr(AFather.co[1]) + ' ' + floattostr(AFather.co[2]) + ' ' +
    floattostr(AFather.ce[0]) + ' ' + floattostr(AFather.ce[1]) + ' ' +
    floattostr(AFather.ce[2]) + ' ' + floattostr(AFather.SegLength) + ' ';
  if AFather.Meristem <> nil then
  begin
    infostring := infostring + floattostr(AFather.Meristem.PCroiss[0]) + ' ' +
      floattostr(AFather.Meristem.PCroiss[1]) + ' ' +
      floattostr(AFather.Meristem.PRamif) + ' ' +
      inttostr(AFather.Meristem.num);
    if AFather.Meristem.Maturity = true then
      infostring := infostring + ' ' + 'true'
    else
      infostring := infostring + ' ' + 'false';
    if AFather.Meristem.Activ = true then
      infostring := infostring + ' ' + 'true'
    else
      infostring := infostring + ' ' + 'false';

  end
  else
  begin
    infostring := infostring + 'MerisNil' + ' ' + 'MerisNil' + ' ' + 'MerisNil'
      + ' ' + 'MerisNil' + ' ' + 'MerisNil';
  end;
  write(fseg, infostring);
  writeln(fseg);
  closefile(fseg);
  if AFather.ChildList <> nil then
  begin
    for i := 0 to AFather.ChildList.Count - 1 do
    begin
      AChild := AFather.ChildList.Items[i];
      writeSegInfoRekursive(AChild);
    end;
  end;
end;

procedure TSubmodRootStrucNew.writeRamiInfo(AFather: TSegment);
(* ------------------------------------------------------------------------------
  Teilungsinfo, für Debugging
  ------------------------------------------------------------------------------ *)
var
  infostring: string;
  fseg: TextFile;
  AChild: TSegment;
  i: integer;
begin
  assignfile(fseg, SegFile.Option);
  append(fseg);
  infostring := floattostr(GlobTime.v) + ' ' + inttostr(AFather.num) + ' ' +
    inttostr(AFather.RS_ID) + ' ' + 'Vater' + ' ' + floattostr(AFather.co[0]) +
    ' ' + floattostr(AFather.co[1]) + ' ' + floattostr(AFather.co[2]) + ' ' +
    floattostr(AFather.ce[0]) + ' ' + floattostr(AFather.ce[1]) + ' ' +
    floattostr(AFather.ce[2]);
  write(fseg, infostring);
  writeln(fseg);
  closefile(fseg);
  if AFather.ChildList <> nil then
  begin
    For i := 0 to AFather.ChildList.Count - 1 do
    begin
      assignfile(fseg, SegFile.Option);
      append(fseg);
      AChild := AFather.ChildList.Items[i];
      infostring := floattostr(GlobTime.v) + ' ' + inttostr(AChild.num) + ' ' +
        inttostr(AChild.RS_ID) + ' ' + 'Kind' + inttostr(i) + ' ' +
        floattostr(AChild.co[0]) + ' ' + floattostr(AChild.co[1]) + ' ' +
        floattostr(AChild.co[2]) + ' ' + floattostr(AChild.ce[0]) + ' ' +
        floattostr(AChild.ce[1]) + ' ' + floattostr(AChild.ce[2]);
      write(fseg, infostring);
      writeln(fseg);
      closefile(fseg);
    end;
  end;
end;

procedure TSubmodRootStrucNew.resetWLD_VK;
begin
  RLD_1.v := 0;
  RLD_2.v := 0;
  RLD_3.v := 0;
  RLD_4.v := 0;
  RLD_5.v := 0;
  RLD_6.v := 0;
  RLD_7.v := 0;
  RLD_8.v := 0;
  RLD_9.v := 0;
  RLD_10.v := 0;
  VC_1.v := 0;
  VC_2.v := 0;
  VC_3.v := 0;
  VC_4.v := 0;
  VC_5.v := 0;
  VC_6.v := 0;
  VC_7.v := 0;
  VC_8.v := 0;
  VC_9.v := 0;
  VC_10.v := 0;
end;

procedure TSubmodRootStrucNew.calcDeepestInterscection(y: double);
begin
  if self.DeepestIntersection.v < y then
    DeepestIntersection.v := y;
end;

procedure TSubmodRootStrucNew.updSRPList(ASegment_: TSegment;
  completeOut: boolean);
(* ------------------------------------------------------------------------------
  Methode verwendet die Segmente, die den Weltwürfel verlassen, reflektiert das
  außen liegende Teilstück und seine Nachfolger und berechnet etwaige Schnittpunkte
  mit der Querschnittsebene.
  ------------------------------------------------------------------------------ *)
var
  ASegmentTemp: TSegment;
begin
  try
    ASegmentTemp := TSegment.create;
    // Aufspannen der Ebenen:
    if ((ASegment_.co[0] > 0) and (ASegment_.ce[0] < 0)) or
      ((ASegment_.co[0] < 0) and (ASegment_.ce[0] < 0)) then // Ebene 'links'
    begin
      // Vorzeichen der X-Koordinate umdrehen
      ASegmentTemp.co[0] := -ASegment_.co[0];
      ASegmentTemp.co[1] := ASegment_.co[1];
      ASegmentTemp.co[2] := ASegment_.co[2];
      ASegmentTemp.ce[0] := -ASegment_.ce[0];
      ASegmentTemp.ce[1] := ASegment_.ce[1];
      ASegmentTemp.ce[2] := ASegment_.ce[2];
      // Erzeugen eines TSRP-Objektes, vorher wird noch auf Schnittpunkt getestet
      calcIntersect(ASegmentTemp);
    end;

    if ((ASegment_.co[0] < DimX.v) and (ASegment_.ce[0] > DimX.v)) or
      ((ASegment_.co[0] > DimX.v) and (ASegment_.ce[0] > DimX.v)) then
    // Ebene 'rechts'
    begin
      if completeOut = true then
      begin
        ASegmentTemp.co[0] := DimX.v - (ASegment_.co[0] - DimX.v);
        ASegmentTemp.co[1] := ASegment_.co[1];
        ASegmentTemp.co[2] := ASegment_.co[2];
        ASegmentTemp.ce[0] := DimX.v - (ASegment_.ce[0] - DimX.v);
        ASegmentTemp.ce[1] := ASegment_.ce[1];
        ASegmentTemp.ce[2] := ASegment_.ce[2];
      end
      else
      begin
        ASegmentTemp.co[0] := DimX.v + (DimX.v - ASegment_.co[0]);
        ASegmentTemp.co[1] := ASegment_.co[1];
        ASegmentTemp.co[2] := ASegment_.co[2];
        ASegmentTemp.ce[0] := DimX.v - (ASegment_.ce[0] - DimX.v);
        ASegmentTemp.ce[1] := ASegment_.ce[1];
        ASegmentTemp.ce[2] := ASegment_.ce[2];
      end;
      // Erzeugen eines TSRP-Objektes, vorher wird noch auf Schnittpunkt getestet
      calcIntersect(ASegmentTemp);
    end;
    if ((ASegment_.co[1] > 0) and (ASegment_.ce[1] < 0)) or
      ((ASegment_.co[1] < 0) and (ASegment_.ce[1] < 0)) then // Ebene 'vorne'
    begin
      // Vorzeichen der Y-Koordinate umdrehen
      ASegmentTemp.co[0] := ASegment_.co[0];
      ASegmentTemp.co[1] := -ASegment_.co[1];
      ASegmentTemp.co[2] := ASegment_.co[2];
      ASegmentTemp.ce[0] := ASegment_.ce[0];
      ASegmentTemp.ce[1] := -ASegment_.ce[1];
      ASegmentTemp.ce[2] := ASegment_.ce[2];
    end;
    if ((ASegment_.co[1] < DimY.v) and (ASegment_.ce[1] > DimY.v)) or
      ((ASegment_.co[1] > DimY.v) and (ASegment_.ce[1] > DimY.v)) then
    // Ebene 'hinten'
    begin
      if completeOut = true then
      begin
        ASegmentTemp.co[0] := ASegment_.co[0];
        ASegmentTemp.co[1] := DimY.v - (ASegment_.co[1] - DimY.v);
        ASegmentTemp.co[2] := ASegment_.co[2];
        ASegmentTemp.ce[0] := ASegment_.ce[0];
        ASegmentTemp.ce[1] := DimY.v - (ASegment_.ce[1] - DimY.v);
        ASegmentTemp.ce[2] := ASegment_.ce[2];
      end
      else
      begin
        ASegmentTemp.co[0] := ASegment_.co[0];
        ASegmentTemp.co[1] := DimY.v + (DimY.v - ASegment_.co[1]);
        ASegmentTemp.co[2] := ASegment_.co[2];
        ASegmentTemp.ce[0] := ASegment_.ce[0];
        ASegmentTemp.ce[1] := DimY.v - (ASegment_.ce[1] - DimY.v);
        ASegmentTemp.ce[2] := ASegment_.ce[2];
      end;
      // Erzeugen eines TSRP-Objektes, vorher wird noch auf Schnittpunkt getestet
      calcIntersect(ASegmentTemp);
    end;
  finally // Aufräumen
    if ASegmentTemp <> nil then
      ASegmentTemp.destroy;
  end;
end;

procedure TSubmodRootStrucNew.calcBranchDens;
(* ------------------------------------------------------------------------------
  Berechnet Verzweigungsdichten
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  BranchDensArr: array of double; // Verzweigungsdichte der Prim-Wurzel
  ABranchDensPrim: TBranchDensPrim;
  meanDens, StdDevDens: double;//extended;
  ASegListTot: TList; // Segmentliste eines WS
  ASegment: TSegment;
  TotLength: double;
begin
  setLength(BranchDensArr, BranchDensPrimRoots.Count);
  TotLength := 0;
  // Var A: Mittelwert aus den Verzweigungsdichten aller Prim-Wurzeln aller WS
  for i := 0 to BranchDensPrimRoots.Count - 1 do
  begin
    // Array Füllen
    ABranchDensPrim := BranchDensPrimRoots.Items[i];
    if ABranchDensPrim.PrimRootLength <> 0 then
    begin
      TotLength := TotLength + ABranchDensPrim.PrimRootLength; // debugging
      // ZahlSegPW.v:=ZahlSegPW.v+ABranchDensPrim.NumSeg;
      BranchDensArr[i] := ABranchDensPrim.NumSeg /
        ABranchDensPrim.PrimRootLength;
    end
    else
      BranchDensArr[i] := 0;
  end;
  // Berechnen Mittelwert und Standardabw.
  if BranchDensPrimRoots.Count <> 0 then
  begin
    meanAndStdDev(BranchDensArr, meanDens, StdDevDens);
    BranchDens.v := meanDens;
    BranchDensStDev.v := StdDevDens;
  end;
  { Var B: Mittelwert aus den Verzweigungsdichten aller Prim-Wurzeln für die ein-
    zelnen WS }
  // fehlt noch
end;

procedure TSubmodRootStrucNew.calcWLD;
(* ------------------------------------------------------------------------------
  Berechnung der WLD in einer Schicht aufgrund der über die Segmentlängen berechne
  ten Wurzellängen.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  VolLayer: double;
begin
  for i := 0 to high(WLStateArray) do
  begin
    VolLayer := DimX.v * DimY.v * GaugeArr[i];
    WLDArr[i].v := WLStateArray[i].v / VolLayer;
  end;
end;

procedure TSubmodRootStrucNew.resetDerivedData;
(* ------------------------------------------------------------------------------
  Zurücksetzen abgeleiteter Variablen
  ------------------------------------------------------------------------------ *)
begin
  SumWL_PW.v := 0;
  SumWL_E1.v := 0;
  SumWL_E2.v := 0;
  SumWL_E3.v := 0;
  MeanSLVZPW.v := 0;
  MeanSLVZE1.v := 0;
  MeanSLVZE2.v := 0;
  StdDSLVZPW.v := 0;
  StdDSLVZE1.v := 0;
  StdDSLVZE2.v := 0;
  MeanApNBZ_PW.v := 0;
  MeanBasNBZ_PW.v := 0;
  MeanBZ_PW.v := 0;
  StdApNBZ_PW.v := 0;
  StdBasNBZ_PW.v := 0;
  // StdBZ_PW.v:=0;
  TotSLVZPW.v := 0;
  TotSLVZE1.v := 0;
  TotSLVZE2.v := 0;
end;

function TSubmodRootStrucNew.calcStdDev(TotLength, SumQuad: extended;
  Number: integer): double;
(* ------------------------------------------------------------------------------
  Berechnet Standardabweichung nach
  E:\Statistik und Mathematik\Grundlagen\BerStandardabweichung.doc
  ------------------------------------------------------------------------------ *)
var
  stdDev, TermUnderRoot: extended;
begin
  if Number > 1 then
  begin
    TermUnderRoot := (Number * SumQuad - sqr(TotLength)) /
      (Number * (Number - 1));
    if TermUnderRoot > 0 then
    begin
      stdDev := sqrt(TermUnderRoot);
    end
    else
      stdDev := 0;
  end
  else
    stdDev := 0;
  Result := stdDev;
end;

procedure TMeristem.writePotRam(Coord: r3);
(* ------------------------------------------------------------------------------
  Debugging-Methode: Schreibt Segment-Nummer und die angelegten potentiellen
  Verzweigungspunkte in eine Datei
  ------------------------------------------------------------------------------ *)
var
  f: TextFile;

begin
  assignfile(f, PotFile);
  append(f);
  write(f, ',');
  write(f, floattostr(Coord[0]));
  write(f, ',');
  write(f, floattostr(Coord[1]));
  write(f, ',');
  writeln(f, floattostr(Coord[2]));
  closefile(f);
end;

procedure TRootsystem.writeMerisInfo(ASegmentWithMeris: TSegment);
var
  f: TextFile;
begin
  { headerMeris:='Meris-Nr.'+','+'Order'+','+'DirGr_0'+','+'DirGr_1'+','+'DirGr_2'+','+'DistBase'
    +','+'basNVZ'+','+'AktSegLength'; }
  assignfile(f, MerisFile);
  append(f);
  write(f, inttostr(ASegmentWithMeris.Meristem.num));
  write(f, ',');
  write(f, inttostr(ASegmentWithMeris.Meristem.Order));
  write(f, ',');
  write(f, floattostr(ASegmentWithMeris.Meristem.DirGrowth[0]));
  write(f, ',');
  write(f, floattostr(ASegmentWithMeris.Meristem.DirGrowth[1]));
  write(f, ',');
  write(f, floattostr(ASegmentWithMeris.Meristem.DirGrowth[2]));
  write(f, ',');
  write(f, floattostr(ASegmentWithMeris.Meristem.DistBase));
  write(f, ',');
  write(f, floattostr(ASegmentWithMeris.Meristem.basNVZ));
  write(f, ',');
  write(f, floattostr(ASegmentWithMeris.SegLength));
  write(f, ',');
  writeln(f);
  closefile(f);
end;

{ TSRP }

constructor TSRP.create;
begin
  inherited create;
  vertexList := nil;
end;

procedure writeSegnumber(Number, numberFather: integer; funktion: string);
(* ------------------------------------------------------------------------------
  schreibt Segmentnummer in eine Datei
  ------------------------------------------------------------------------------ *)
var
  f: TextFile;

begin
  assignfile(f, SegNumberFile);
  append(f);
  write(f, ' ');
  write(f, inttostr(Number));
  write(f, ' ');
  write(f, inttostr(numberFather));
  write(f, ' ');
  write(f, funktion);
  writeln(f);
  closefile(f);
end;

procedure TMeristem.findFurtherRamPoint;
var
  OrigRam, LastRam, RamToRemove: TR3;

  i: integer;
begin
  OrigRam := TR3.create;
  if PointsOfRam.Count > 0 then
  begin
    LastRam := PointsOfRam.last;
    OrigRam.Koord3D[0] := LastRam.Koord3D[0] + PRamif * DirGrowth[0];
    OrigRam.Koord3D[1] := LastRam.Koord3D[1] + PRamif * DirGrowth[1];
    OrigRam.Koord3D[2] := LastRam.Koord3D[2] + PRamif * DirGrowth[2];
    if debugging = true then
    begin
      writePotRam(OrigRam.Koord3D);
    end;
    PointsOfRam.Add(OrigRam);
    PointsOfRam.Pack;
    PointsOfRam.Capacity := PointsOfRam.Count;
  end;
  // if PotRamListEmpty = true then
  { Wenn Liste im vorigen Zeitschritt vollständig entleert wurde, wurden die Koor-
    dinaten der letzten Verzweigung als Ausgangspunkt für die erneute Berechnung
    behalten und muss nun entfernt werden }
  { begin
    RamToRemove:=PointsOfRam.first;
    PointsOfRam.Remove(PointsOfRam.first);
    RamToRemove.Free;
    PotRamListEmpty:=false;
    end; }
end;

procedure TMeristem.findFirstRamPoint;
var
  aktPartBasNVZ { Teilstück der aktuellen Verlängerung, das noch zur bas.
    Nichtverzweigungszone gehört }
    : double;
  OrigFirstRam, FirsRamCopy: TR3;
begin
  { falls eine Nichtverzweigungszone definiert ist, kann an deren Ende direkt ver-
    zweigt werden, ansonsten wird erst in der Entfernung PRamif vom Ursprung der
    Achse verzweigt. }
  if basNVZ > 0 then
  begin
    OrigFirstRam := TR3.create;
    aktPartBasNVZ := basNVZ - sumElongOld;
    OrigFirstRam.Koord3D[0] := Remcoord[0] + aktPartBasNVZ * DirGrowth[0];
    OrigFirstRam.Koord3D[1] := Remcoord[1] + aktPartBasNVZ * DirGrowth[1];
    OrigFirstRam.Koord3D[2] := Remcoord[2] + aktPartBasNVZ * DirGrowth[2];
    if debugging = true then
    begin
      writePotRam(OrigFirstRam.Koord3D);
    end;
    PointsOfRam.Add(OrigFirstRam);
    FirsRamCopy := TR3.create;
    FirsRamCopy.assign(OrigFirstRam);
    PointsOfRam.Add(FirsRamCopy);
    PointsOfRam.Pack;
    PointsOfRam.Capacity := PointsOfRam.Count;
    remainderElong := sumElongNew - basNVZ;
  end;
end;

procedure TMeristem.updateRemcoord;
{ Erst nach der Verzweigung wird die Lage des Meristems aktualisiert. }
begin
  Remcoord[0] := Coord[0];
  Remcoord[1] := Coord[1];
  Remcoord[2] := Coord[2];
end;

procedure TMeristem.setBasNVZ(basNVZ_: single);
begin

  basNVZ := basNVZ_;
end;

destructor TSRP.destroy;
begin
  if vertexList <> nil then
  begin
    vertexList.clear;
  end;
  vertexList.Free;
  inherited destroy;
end;

{ TR3 }

procedure TR3.assign(Source: TR3);
begin
  Koord3D := TR3(Source).Koord3D;
end;

procedure TMeristem.findFirstNoBas;
var
  OrigFirstRam, FirstRamCopy: TR3;
  startPt: r3;
begin
  startPt[0] := Coord[0] - (sumElongNew * DirGrowth[0]);
  startPt[1] := Coord[1] - (sumElongNew * DirGrowth[1]);
  startPt[2] := Coord[2] - (sumElongNew * DirGrowth[2]);
  OrigFirstRam := TR3.create;
  OrigFirstRam.Koord3D[0] := startPt[0] + (PRamif * DirGrowth[0]);
  OrigFirstRam.Koord3D[1] := startPt[1] + (PRamif * DirGrowth[1]);
  OrigFirstRam.Koord3D[2] := startPt[2] + (PRamif * DirGrowth[2]);
  if debugging = true then
  begin
    writePotRam(OrigFirstRam.Koord3D);
  end;
  PointsOfRam.Add(OrigFirstRam);
  FirstRamCopy := TR3.create;
  FirstRamCopy.assign(OrigFirstRam);
  PointsOfRam.Add(FirstRamCopy);
  PointsOfRam.Pack;
  PointsOfRam.Capacity := PointsOfRam.Count;
  remainderElong := sumElongNew - PRamif;
end;

procedure TMeristem.findFirstRamNewDir;
(* ------------------------------------------------------------------------------
  findet den ersten Punkt ausgehend von der Lage des Meristems im letzten Zeit-
  schritt (wird verwendet für Bestimmung aller ersten pot. Punkte auf dem Teilstück
  mit der NEUEN Wachstumsrichtung, ist nicht notwendig im ersten Zeitschritt, bei
  dem pot. Verzweigungspunkte angelegt werden.)
  ------------------------------------------------------------------------------ *)
var
  partRam // für den ersten Punkt angepasste Zwischenverzweigungslänge
    : double;
  FirstPointNewDir: TR3;
begin
  partRam := PRamif - remainderElongOld;
  FirstPointNewDir := TR3.create;
  FirstPointNewDir.Koord3D[0] := Coordold[0] + (partRam * DirGrowth[0]);
  FirstPointNewDir.Koord3D[1] := Coordold[1] + (partRam * DirGrowth[1]);
  FirstPointNewDir.Koord3D[2] := Coordold[2] + (partRam * DirGrowth[2]);
  PointsOfRam.Add(FirstPointNewDir);
  PointsOfRam.Pack;
  PointsOfRam.Capacity := PointsOfRam.Count;
  { gesamter PRamif muss abgezogen werden, da von der Endkoordinate des Mersitems
    ausgegangen wurde }
  remainderElong := remainderElong - PRamif;
end;

{ TPotSeg }

function TPotSeg.getCe: r3;
begin
  Result := ce;
end;

function TPotSeg.getCo: r3;
begin
  Result := co;
end;

function TMeristem.getPointsOfRam: TList;
begin
  Result := self.PointsOfRam;
end;

end.

(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE:
  BESCHREIBUNG:
  ------------------------------------------------------------------------------ *)

(* ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------ *)
