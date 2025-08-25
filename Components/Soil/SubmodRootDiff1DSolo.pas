unit SubmodRootDiff1DSolo;

{ Solo-Variante des 1D-Diffmodells: erwartet kein Strukturmodell }
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, vcl.Dialogs,
  UMod, SubmodRootDiff, UState, Math, SubmodDiff2DRoots;

const
  { Folgendes sind die Phi(u)-Werte der Standardnormalverteilung:
    Bsp. für Lesart:
    z_5-Wert [1.64486] bezeichnet denjenigen u-Wert, der von 5% aller Werte ÜBER
    SCHRITTEN wird. d.h. 5% aller Werte weichen um mindestens 1.64486 vom Mittelwert
    ab. Aufgrund der Symmetrie der Standardnormalverteilung gilt für -z_5: 5% aller
    Werte weichen um -1.64486 vom Mittelwert ab. z_x-Werte entspreichen den Phi(u)-
    Werten.
    Problem: meines Erachtens handelt es sich hier um die Phi(u)-Werte, mit denen
    sich später die KLASSENMITTELWERTE der WLD-Dichteverteilung berechnen lassen.
    Korrekt??? (Klassengrenzen sind dann jeweils 0,1;0,2 ... 1) }
  { Ursprüngliche Werte hier auskommentiert
    z_5  = 1.64486;
    z_15 = 1.03644;
    z_25 = 0.674492;
    z_35 = 0.385322;
    z_45 = 0.125663; }
  { Mit Excel berechnete Werte: }
  z_5 = 1.6448534756699800;
  z_15 = 1.0364334736256900;
  z_25 = 0.6744895256679870;
  z_35 = 0.3853206036265890;
  z_45 = 0.1256612463220620;

  { Excel-Werte für 20 Klassen: }
  z_475 = 0.062706777943;
  z_425 = 0.189118426273;
  z_375 = 0.318639363964;
  z_325 = 0.453762190170;
  z_275 = 0.597760126042;
  z_225 = 0.755415026360;
  z_175 = 0.934589291073;
  z_125 = 1.150349380376;
  z_075 = 1.439531470938;
  z_025 = 1.959963984540;

type
  // Typdeklarationen
  Pdouble = ^double; // Zeigertyp auf double-Typ, für Verwendung in Listen

  // Arrays
  { Arraytyp für Statusvariablenarrays. Wird benötigt für numerische Lösung.
    Jeder SRP (bzw. eine Eigenschaft des SRP) wird hier als eine Instanz von TState
    aufgefasst. Das Array enthält Werte für sämtliche SRP der simulierten Bodenschicht.
    Problem: Musste von vornherein festgelegt werden auf die maximal erlaubte Anzahl
    von Wurzeln, da TState-Instanzen in create all erzeugt werden muessen und zu
    diesem Zeitpunkt sind noch keine Wurzeln eingelesen. Problem 2: Sinnvoller-
    weise wären dann wohl doch eher die Strategie 'nur' die aggregierten Werte (mRLD
    und VC) als TState zu deklarieren (wie bisher), da die Einzelwurzelzylinder eine
    ganze Reihe Eigenschaften haben s TSRP. }
  // TSRPStateArray  = array [0..max_num_roots-1] of TState;

  // Klassen

  TMyFloatPoint = class(TObject)
    x, y: double;
  end;

  TSubmodRootDiff1DSolo = class(TSubmodRootDiff)
  private
    { Private-Deklarationen }
    fMy2DDiffModel: TSubmodDiff2DRoots;
    // FELDER
    // a) notwendig für analytische Lösung
    WLD_Array: Array of double;
    { 1-dimensionale Arrays für die Zuordnung von Quartilen einer Normalverteilung
      bzw. Lognormalverteilung und zugehöriger ZUFALLSVARIABLEN.
      Es wurde eine Klassierung in 10 Klassen angenommen, d.h. für das Array werden
      10 Zeilen benötigt. Im ersten Feld des Arrays steht die Zufallsvariable, die zu
      -z_5 gehört, im letzten Feld die Zufallsvariable, die zu z_5 gehört. Speicherung
      der Zufallsvariablen in 'Klassenmitte' s.o. }
    // Array für Normalverteilung
    ZV_Array_normvert,
    // Array für Lognormalverteilung
    ZV_Array_lognorm,
    // Array für Standardnormalverteilung
    ZV_Array_Stdnorm,
    // Array für Wichtung (notwendig bei Berechnung aus der Verteilung der Flächen)
    weightArr: Array of real;
    // b) notwendig für numerische Lösung
    { Die folgenden Listen enthalten für jeden SRP der betrachteten Bodenschicht In-
      formationen oder bestimmte berechnete Werte. }
    { Deklaration einer Liste, das zu einen die XY-Koordinaten, zum an-
      deren die Wurzellängendichten für jede Wurzel speichert. Z.Zt. ohne Verwendung,
      deshalb auskommentiert }
    // WLD_List : TList;
    { Liste für aktuelle mittlere Nitratkonzentrationen in den SRP. Jedes
      Listenelement speichert die mittlere Nitratkonz. eines bestimmten SRP. }
    Cl_mean_List: TList;
    { Liste für (Wasser) - Volumina für alle SRP (zunächst konstant) Problem: muss bei
      Implementierung eines dynamischen Modells angepasst werden. }
    VolH20_EWZ_List: TList;
    { Liste speichert die Startwerte der NMengen in den SRP }
    Init_NAmountEWZList: TList; // brauch ich vielleicht gar nicht
    { Initiale N-Menge: }
    NAmountInit: double;
    { Array/Liste speichert die aufgenommene N-Mengen (Flüsse) in/aus den Einzel-
      wurzelzylindern im aktuellen Zeitschritt.
      Problem: Dynamisches Array oder Liste ist hier wohl nicht möglich,
      da mit TState-Instanzen gearbeitet werden soll, welche dann AUTOMATISCH durch
      die HUME-Umgebung INTEGRIERT werden können. TState müssen aber zu Beginn erzeugt
      werden. }
    // NAmount_UPEWZArray : TEWZStateArray;
    // NAmount_UPEWZList : TList;

    // METHODEN
    // a) Methoden für die Berechnung anhand der analytischen Lösung
    procedure createAnalytic;
    procedure Integrate_Analyt;
    // Hilfsmethoden
    function Kolmogorov_Smirnov: boolean;

    procedure calcRootArea;
    procedure copyPosArrFrom2DDif;
    procedure fillWLDArr;
    // b) für numerische Lösung
    procedure createNumeric;
    // Methode für die Berechnung mit Hilfe der Ratengleichung (numerische Lösung)
    procedure Calc_numeric;
    procedure transform_Clmin;
    procedure calc_Amount_H20;
    function calc_num_EWZ: real;
    function calc_num_class: real;
    // c) für beide Verfahren
    procedure init_eingelesen; override;
    { Methode für Modellvergleich: Berechnung der N-Menge im Boden bei gegebener
      Verteilung und Mineralisationsrate }
    procedure calcN_AmountSoilEquil;
  protected
    { Protected-Deklarationen }
    { Schalter für Prüfung, ob bereits eine Initialsierung vorgenommen wurde und
      anschließende Verzweigung }
    initial_1D: boolean;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TPar (Parameter)
      Problem: Zuweisung der Variablen in diese Gruppe korrekt?
      ------------------------------------------------------------------------------ *)
    number_classes, { Anzahl der zu verwendenden Klassen für Berechnung
      einer klassenspez. Aufnahme }
    Log_StdAbw_Area, { logtransformierte Standardabweichung der Fläche [cm^2] }
    Log_Area_mean, { Logtransformierte mittl. Fläche in
      einer Schicht [cm^2] }
    ParVC { Variationskoeff der mRLD [%] }
    { Hinweis: Variationskoeffizient ist nur Eingabeparameter im Voronoi-Modell, da
      nur hier DIESE aggregierten Werte (Flächen- bzw. WLD- Verteilung) verarbeitet
      werden können.
      2D-Modell ist auf XY-Koordinaten der WAP angewiesen
      Rappolt-Modell arbeitet in der vorhandenen Implementierung mit beobachteten Häufig-
      keiten und NICHT mit theoretischen Verteilungsfunktionen der kürzesten Distanzen
      (Diffusionsstrecken). }
      : TPar;

    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TVar (Variablen) Problem: Einheiten korrekt?
      ------------------------------------------------------------------------------ *)
    Area_mean, { Mittlere Fläche [cm^2] }
    VarKoeff_Area, { Variationskoeffizient der mittleren Fläche [%] }
    StdAbw_Area, { Standardabweichung der Fläche[cm^2] }
    Log_RLD_mean, { Logtransformierte mittl. Wurzellängendichte in
      einer Schicht [cm/cm^3] }
    Log_StdAbw_RLD, { logtransformierte Standardabweichung der Wurzel-
      längendichte [cm/cm^3] }
    VarKoeff_RLD, { Variationskoeffizient der mittleren RLD [%] }
    StdAbw_RLD, { Standardabweichung der Wurzellängendichte [cm/cm^3] }

    Varianz, { Varianz der mittleren Wurzellängendichte [cm/cm^3] }
    VM, { V/M-Verhältnis }
    Mittl_Flaeche, { Mittelwert der Fläche der Voronoi- Polygone [cm^2]
      Problem: wird wozu benötigt? }
    StdAbw_Flaeche, { Standardabweichung von Mittl_Flaeche [cm^2] }
    // Für numerische Lösung:
    ClminTransf, { Minimale Bodenlösungskonzentration [ kg N/cm*H20] }
    ClminTransf_ha, { Minimale Bodenlösungskonzentration [ kg N/ha] }
    Amount_H20, { Wassermenge in der betrachteten Bodenschicht [l] }
    Par_AreaMean, { Mittlere Fläche [cm^2] }
    Par_AreaVC { Variationskoeffizient mittlere Fläche [%] }
      : TVar;

    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen)
      ------------------------------------------------------------------------------ *)
    N_MengeAnteilAn, { Anteilige Stickstoffaufnahme [-] bei Verwendung
      der analyt. Lösung nach Tinker, Nye Gl.10.28 }
    N_MengeAnteilNum, { Anteilige Stickstoffaufnahme [-] bei Verwendung
      der num. Lösung }
    N_AmountSoilNum { das Solo-1D-Modell hat noch eine Zustandvariable
      für den Vergleich der Berechnung mit analyt. und
      num. Lösung }

      : TState;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen)
      ------------------------------------------------------------------------------ *)

    OperatingMode, { Art und Weise, wie das Modell laufen soll: mit oder
      ohne 2D-Modell, wichtig für Ausgabe im Formular }
    calcMethodZV, { Auswahl über Berechnungsmethode:
      a) mit gleichbleibenden Summenhäufigkeitsintervall
      b) mit gleichbleibendem Klassenintervall. }
    integrationMethod, { Auswahl von numerischer oder analyt Kalkulation }
    RootDistribution, { Festlegen der angenommenen Verteilung der WAP
      spezifisch für 1D und 2D-Modell, da bei 1D-Modell
      zusätzlich zwischen Lognormaler und normaler Vertei
      lung unterschieden wird }
    CalcMethRLD_VC, { Verschiedene Möglichkeiten der Berechnung der Kenn-
      zahlen der Wurzelverteilung }
    CalcMethQuant, { Verschiedene Methoden der Berechnung der Klassenmittel
      werte der WLD in den zugehörigen Quantilen. }
    StatN_AmountSoil, { Schalter für Berechnungen bei statischer N-Menge und
      sich dynamisch verändernder N-Menge
      Bei dynamischer Veränderung kann nur zeitschrittweise
      Berechnung eingesetzt werden. Bei der analyt. Lösung
      bedeutet das, dass eine anteilige Berechnung eigentlich
      keinen Sinn mehr macht. Lsg: Variable Time ersetzen durch
      Timestep und multiplikation der anteiligen Aufnahme im
      Zeitschritt mit der aktuell vorhandenen N-Menge. }
    compareMode { Schalter mit dem festgelegt wird, ob das 1D-Modell
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

    // Compare2DModel
    { Schalter für den Vergleich mit dem 2D-Modell: Dort wird
      für die Erzeugung des Steady-States die aufgenommene
      Menge in jedem Zeitschritt den Zellen wieder hinzugefügt.
      Bei einem Vergleich der Modelle muss das auch im 1D-
      Modell geschehen. (Braucht nur das Solo-Modell, da bei
      dem Gesamtmodell ein solcher Vergleich keine Rolle
      spielt) Schalter wird derzeit nicht verwendet, }
      : TOption;

    procedure calcVar_Analyt;
    { Hilfsmethoden für analytische Lösung zur Berechnung der Klassenmittelwerte
      der Wurzellängendichte bei Aufteilen der Normal- bzw Lognormalverteilungskurve
      in 10 Klassen, es werden also zu den fest vorgegebenen Quartilen die zugehörigen
      u-Werte bestimmt }
    procedure get_normvert_ZV;
    procedure get_lognorm_ZV;
    procedure get_lognorm_ZV_Area;
  public
    { Public-Deklarationen }
    procedure createAll; override;
    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    { Published-Deklarationen }
    property My2DDiffModel: TSubmodDiff2DRoots read fMy2DDiffModel
      write fMy2DDiffModel;
  end; // Ende Klassendeklaration TSubmodRootDiff1DSolo

procedure Register;

implementation

procedure Register;
(* -----------------------------------------------------------------------------
  Prozedur wird für Komponenten benötigt: Registrierung der Komponenten auf einer
  Palette.
  ------------------------------------------------------------------------------ *)
begin
  RegisterComponents('MichasMod', [TSubmodRootDiff1DSolo]);
end; // End procedure Register

{ TSubmodRootDiff1DSolo }

procedure TSubmodRootDiff1DSolo.createAll;
(* -----------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Erzeugen und Initialisieren von Zustandsvariablen, Variablen und
  Parametern.
  Der erste Parameter des Funktionsaufrufs übergibt einen String, der mit dem Be-
  zeichner identisch ist und nachdem gesucht werden kann.
  Der zweite Parameter enthält einen String zur Kennzeichnung der verwendeten
  Einheit ([-] für dimensionslose Paramter)
  Der dritte Parameter ist der eigentliche (Fließkomma)-Wert
  Erläuterung der Bezeichner s. Deklaration.
  ------------------------------------------------------------------------------ *)
begin
  inherited;
  // Erzeugen der Listen
  Cl_mean_List := TList.Create;
  VolH20_EWZ_List := TList.Create;
  Init_NAmountEWZList := TList.Create;
  initial_1D := false;
  // Erzeugen und initialisieren von TVar
  VarCreate('Area_mean', '[cm^2]', 0, false, Area_mean);
  VarCreate('VarKoeff_Area', '[%]', 0, false, VarKoeff_Area);
  VarCreate('StdAbw_Area', '[cm^2]', 0, false, StdAbw_Area);
  VarCreate('Log_RLD_mean', '[cm/cm^3]', 0, false, Log_RLD_mean);
  VarCreate('VarKoeff_RLD', '[%]', 0, false, VarKoeff_RLD);
  VarCreate('Log_StdAbw_RLD', '[cm/cm^3]', 0, false, Log_StdAbw_RLD);
  VarCreate('StdAbw_RLD', '[cm/cm^3]', 0, false, StdAbw_RLD);
  VarCreate('Varianz', '[%]', 0, false, Varianz);
  VarCreate('VM', '[-]', 0, false, VM);
  VarCreate('Mittl_Flaeche', '[cm^2]', 0, false, Mittl_Flaeche);
  VarCreate('Par_AreaMean', '[cm^2]', 5, false, Par_AreaMean);
  VarCreate('Par_AreaVC', '[%]', 100, false, Par_AreaVC);
  // Erzeugen und initialisieren von TPar
  ParCreate('number_classes', '[-]', 10, number_classes);
  // 10 Klassen per default
  ParCreate('Log_Area_mean', '[cm^2]', 0, Log_Area_mean);
  ParCreate('Log_StdAbw_Area', '[cm^2]', 0, Log_StdAbw_Area);
  ParCreate('ParVC', '[%]', 0, ParVC);
  // Erzeugen und initialisieren von TState
  StateCreate('N_MengeAnteilAn', '[]', 0, false, N_MengeAnteilAn);
  StateCreate('N_MengeAnteilNum', '[]', 0, false, N_MengeAnteilNum);
  StateCreate('N_AmountSoilNum', '[kg N/ha]', 0, false, N_AmountSoilNum);
  // Erzeugen und initialisieren von TOption

  OptCreate('CalcMethQuant', 'fromarea', CalcMethQuant);
  CalcMethQuant.OptionList.Add('fromarea');
  CalcMethQuant.OptionList.Add('fromRLD');
  OptCreate('StatN_AmountSoil', 'static', StatN_AmountSoil);
  StatN_AmountSoil.OptionList.Add('static');
  StatN_AmountSoil.OptionList.Add('dynamic');
  OptCreate('OperatingMode', 'without2DModel', OperatingMode);
  OperatingMode.OptionList.Add('without2DModel');
  OperatingMode.OptionList.Add('with2DModel');
  OptCreate('integrationMethod', 'analytic', integrationMethod);
  integrationMethod.OptionList.Add('analytic');
  integrationMethod.OptionList.Add('numeric');
  { Für ein Vergleich von analyt. und numerischer Lösung gibt es auch eine Option,
    die beide Berechnungen durchführt. }
  integrationMethod.OptionList.Add('both');
  { Festlegen der angenommenen Verteilung der WAP }
  OptCreate('RootDistribution', 'Random', RootDistribution);
  RootDistribution.OptionList.Add('Regular');
  RootDistribution.OptionList.Add('normal');
  { Falls der Input aus dem Strukturmodell kommt, dann wird Lognormalverteilung
    angenommen, eigentlich müsste das noch getestet werden. }
  RootDistribution.OptionList.Add('lognormal');
  { Festlegen, ob die Kennzahlen RLD und VC aus Voronoi-Polygonen oder aus der
    Belegung in  den Gitterzellen abgeleitet werden soll. }
  OptCreate('CalcMethRLD_VC', 'fromGrid', CalcMethRLD_VC);
  CalcMethRLD_VC.OptionList.Add('voronoi');
  CalcMethRLD_VC.OptionList.Add('fromGrid');

  OptCreate('compareMode', 'no', compareMode);
  compareMode.OptionList.Add('no');
  compareMode.OptionList.Add('yes');
  OptCreate('calcMethodZV', 'equalSumfreq', calcMethodZV);
  calcMethodZV.OptionList.Add('equalSumfreq');
  calcMethodZV.OptionList.Add('equalInt');

  { OptCreate('Compare2DModel', 'no', Compare2DModel);
    Compare2DModel.OptionList.Add('yes');
    Compare2DModel.OptionList.Add('no'); }
  { Problem: es sollte noch differenziert werden, welche Objekte NUR bei der
    analytischen Lösung verwendet werden sollen mit folgender Auslagerung in eine
    Prozedur, damit ein eindeutiges Umschalten zwischen den Berechnungsarten
    übersichtlicher wird. Eher kosmetisches Problem. }
  if integrationMethod.Option = 'numeric' then
  // Fallunterscheidung: Numerische Berechnung
  begin
    { }
    createNumeric;
  end
  else // analytische Lösung
  begin
    createAnalytic;
  end;
end; // SubmodRootDiff1D.createAll

procedure TSubmodRootDiff1DSolo.createAnalytic;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Methode für die Hume-Instanzen, die nur bei Verwendung der analyti-
  schen Lösung gebraucht werden, dadurch kann einfach zwischen den beiden Berech-
  nungsvarianten umgeschaltet werden.
  ------------------------------------------------------------------------------ *)
begin

end; // End TSubmodRootDiff1DSolo.createAnalytic

procedure TSubmodRootDiff1DSolo.createNumeric;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Methode für die Hume-Instanzen, die nur bei Verwendung der numeri-
  schen Lösung gebraucht werden, dadurch kann einfach zwischen den beiden Berech-
  nungsvarianten umgeschaltet werden.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  { TVar }
  VarCreate('ClminTransf', '[kg N/cm*H20]', 0, false, ClminTransf);
  VarCreate('ClminTransf_ha', '[kg N/ha]', 0, false, ClminTransf_ha);
  VarCreate('Amount_H20', '[l]', 0, false, Amount_H20);
  { Erzeugen von Zustandsvariablen für die NMengen, die sich in jedem EWZ befinden.
    Vgl. auch Anmerkungen in Methode init }
  // for i:=0 to max_num_roots-1 do
  // begin
  { Problem: Kann auf diese Weise das NAmount_UPEWZArray gefüllt werden??? }
  // StateCreate('NAmount_UPEWZ'+InttoStr(i),'[g]', 0, false, NAmount_UPEWZArray[i]);
  // end;
end;

procedure TSubmodRootDiff1DSolo.AddDataValueToDataSeries;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiffD
  BESCHREIBUNG: Durchführung diverser Initialisierungen. Cave: init wird mehrfach
  betreten, deshalb wird jetzt AddDataValueToDataSeries verwendet.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  ASRP_Light: TSRPLight; // Eine Light-version des SRP
  AVol_H20, // Ein Zeiger auf Var., die Wasservolumina im SRP speichert
  AInitNAmount, // Ein Zeiger auf Var., die init. N-Menge im SRP speichert
  AInitNConc // Ein Zeiger auf Var., die init. N-Konz im SRP speichert
    : Pdouble;
begin
  inherited;
  // inherited init(GlobMod);      //init jetzt nicht mehr verwendet.
  // Zwischenspeichern der Ausgangs-N-Menge
  NAmountInit := N_AmountSoil.V;
  // Initialisieren dyn. Arrays:
  // a) Längenzuweisung:
  setLength(ZV_Array_Stdnorm, trunc(number_classes.V));
  setLength(ZV_Array_normvert, trunc(number_classes.V));
  setLength(ZV_Array_lognorm, trunc(number_classes.V));
  setLength(weightArr, trunc(number_classes.V));
  { Das Array speichert die Quartile der STANDARDNORMALVERTEILUNG. Aufgrund der
    Symmetrie der Standardnormalverteilung entsprechen die Werte rechts vom Mittel
    wert den Werten links  vom Mittelwert (hier mit negativem Vorzeichen). Hinweis:
    die Werte für z_5 bis z_45 entsprechen den Werten z_55 bis z_95 im Excelmodell. }
  // wenn 10 Klassen vorhanden
  if calcMethodZV.Option = 'equalsumfreq' then
  begin
    if number_classes.V = 10 then
    begin
      ZV_Array_Stdnorm[0] := -z_5;
      ZV_Array_Stdnorm[1] := -z_15;
      ZV_Array_Stdnorm[2] := -z_25;
      ZV_Array_Stdnorm[3] := -z_35;
      ZV_Array_Stdnorm[4] := -z_45;
      ZV_Array_Stdnorm[5] := z_5;
      ZV_Array_Stdnorm[6] := z_15;
      ZV_Array_Stdnorm[7] := z_25;
      ZV_Array_Stdnorm[8] := z_35;
      ZV_Array_Stdnorm[9] := z_45;
    end;
    // wenn 20 Klassen vorhanden
    if number_classes.V = 20 then
    begin
      ZV_Array_Stdnorm[0] := -z_025;
      ZV_Array_Stdnorm[1] := -z_075;
      ZV_Array_Stdnorm[2] := -z_125;
      ZV_Array_Stdnorm[3] := -z_175;
      ZV_Array_Stdnorm[4] := -z_225;
      ZV_Array_Stdnorm[5] := -z_275;
      ZV_Array_Stdnorm[6] := -z_325;
      ZV_Array_Stdnorm[7] := -z_375;
      ZV_Array_Stdnorm[8] := -z_425;
      ZV_Array_Stdnorm[9] := -z_475;
      ZV_Array_Stdnorm[10] := z_025;
      ZV_Array_Stdnorm[11] := z_075;
      ZV_Array_Stdnorm[12] := z_125;
      ZV_Array_Stdnorm[13] := z_175;
      ZV_Array_Stdnorm[14] := z_225;
      ZV_Array_Stdnorm[15] := z_275;
      ZV_Array_Stdnorm[16] := z_325;
      ZV_Array_Stdnorm[17] := z_375;
      ZV_Array_Stdnorm[18] := z_425;
      ZV_Array_Stdnorm[19] := z_475;
    end;
  end;
  if self.calcMethodZV.Option = 'equalint' then
  begin
    // Implementierung fehlt noch.
  end;
  if iniMethod.Option = 'inppar' then
  begin
    { Wenn mWLD und VC als Parameter eingelesen eingelesen werden, dann müssen die
      entsprechenden Variablen gesetzt werden. VarKoeff_RLD wird je nach Verteilungs-
      funktion geg. gändert. }
    RLD_mean.V := ParMRLD.V;
    VarKoeff_RLD.V := ParVC.V;
    // Gilt auch für Kennzahlen der Flächenverteilung
    Area_mean.V := Par_AreaMean.V;
    VarKoeff_Area.V := Par_AreaVC.V;

    if RootDistribution.Option = 'regular' then
      VarKoeff_RLD.V := 0;
    num_Roots.V := RLD_mean.V * dimensionX.V * dimensionY.V;
  end;
  if iniMethod.Option = 'rasterdatafile' then
  begin
    RasterData.readRasterData(RootInpDataFile.Option, seriesXY);
  end;
  if iniMethod.Option = 'xyfile' then
  begin
    RasterData.readXYfromFile(RootInpDataFileXY.Option, seriesXY);
  end;
  // Initialisierungen, die unabhängig von den eingelesenen Wurzeldaten sind
  if integrationMethod.Option = 'numeric' then // nur bei numerischer Lösung
  begin
    transform_Clmin;
  end;
  // Im Falle der Gleichverteilung muss zunächst das PosArr berechnet werden.
  if RootDistribution.Option = 'regular' then
  begin
    EqualDistribution;
  end;
  if RootDistribution.Option = 'random' then
  begin
    { da die Submodelle voneinander unabhängige RasterData-Objekte haben, macht ein
      Modellvergleich nur Sinn, wenn sich das 1D-Modell das PosArr vom 2D-Modell holt }
    // Berechnen der Anzahl von Wurzeln auf Beobachtungsfläche aus der RLD
    if self.My2DDiffModel <> nil then
    begin
      copyPosArrFrom2DDif;
    end
    else
    begin
      if iniMethod.Option = 'inppar' then
        num_Roots.V := RLD_mean.V * dimensionX.V * dimensionY.V;
      for i := 1 to trunc(num_Roots.V) do
      begin
        RasterData.PosArr[i].x := random(trunc(dimensionX.V) - 2) + 2;
        RasterData.PosArr[i].y := random(trunc(dimensionY.V) - 2) + 2;
      end;
    end;
    { im Randomfall müssen Flächendaten aus den Koord. berechnet werden }
    calcRootArea;
  end;
  { Falls aus Rasterdata-File eingelesen wurde und KEINE Gleichverteilung generiert
    wurde, muss das 1D-Modell die Berechnung der Flächen des SRP selbst vornehmen.
    Im Fall Gleichverteilung wird der Flächeninhalt des SRP bei der Verteilung be-
    rechnet. }
  if (iniMethod.Option = 'rasterdatafile') and
    (RootDistribution.Option <> 'regular') then
  begin
    calcRootArea;
  end;
  { Nach Einlesen und Anpassung der Verteilung werden Wurzeln entfernt, die sich
    außerhalb des Beobachtungsfensters oder in den Rändern befinden. }
  init_eingelesen;
  // Sicherstellen, das WLD_arr gefüllt wird
  if ((iniMethod.Option = 'inppar') and (RootDistribution.Option = 'lognormal'))
    or ((iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option = 'lognormal')) then
  begin
    // nichts machen
  end
  else
    fillWLDArr;
  { Wenn Wurzeldaten eingelesen sind, werden folgenden Initialisierungen, differen-
    ziert nach numerischer und analytischer Lösung, durchgeführt. }
  // a) für die analytische Lösung
  if integrationMethod.Option = 'analytic' then
  begin
    calcVar_Analyt;
    if RootDistribution.Option <> 'normal' then
    { bei angommener Lognormalverteilung, Standardfall }
    begin
      { Berechnung der Zufallsvariablen (mittlere WLD, Klassenmittelwerte) bei
        angenommener lognormaler Verteilung }
      if CalcMethQuant.Option = 'fromrld' then
        get_lognorm_ZV
      else
      // Berechnung der Klassenmittelwerte der WLD aus der Flächenverteilung
      begin
        get_lognorm_ZV_Area;
      end;
    end; // End if Lognormalverteilung
    if RootDistribution.Option = 'regular' then
    begin
      { Gleichverteilung bedeutet, dass die halbe Abstände zwischen den Senken und
        damit die Flächeninhalte der einzelnen Senken gleich sind. Standardabweichung
        der Flächeninhalte ist demnach 0. Für die Berechnung wird allein die mittlere
        Wurzellängendichte benötigt. Hier sind keine weiteren Initialisierungen notwendig. }
      VarKoeff_RLD.V := 0;
    end; // End if Gleichverteilung
    if RootDistribution.Option = 'normal' then
    begin
      { Berechnung der Zufallsvariablen (mittlere WLD, Klassenmittelwerte) bei
        angenommener Normalverteilung }
      get_normvert_ZV;
    end; // End if Normalverteilung
  end
  else
  // b) für die numerische Lösung
  begin
    { Erzeugung von Zustandsvariablen für die N-Menge aller EWZ
      Problem: ist möglicherweise nicht durchführbar, in diesem Fall Anlage des Arrays
      mit einer festen Anzahl von TState (s. Deklaration von NAmount_UPEWZArray)
      Das Vorgehen mit dem Erzeugen der Zustandsvariablen in init ist deshalb zunächst
      auskommentiert. }
    { for i:=0 to RasterData.NRoots-1 do
      begin
      StateCreate('NMengeEWZ'+InttoStr(i),'[g]', 0, false, NMengeEWZ);
      end; }
    { Berechnung des volumetr. Wassergehalts aller EWZ (zunächst) konstant über die
      Laufzeit des Modells
      Probleme: Dynamische Modellierung (hier: Veränderung des Wassergehalts) steht
      noch aus.
      //setLength(VolH20_EWZ_Array, RasterData.NRoots-1);
      calc_Amount_H20;
      { Folgende Zeile wäre notwendig, wenn NAmount_UPEWZArray dynamisch erzeugt werden
      kann. Wahrscheinlich wäre Liste besser als Array }
    // setLength(NAmount_UPEWZArray,RasterData.NRoots-1);
    // setLength(Init_NAmountEWZArray,RasterData.NRoots-1);
    for i := 1 to RasterData.NRoots do
    begin
      new(AVol_H20);
      new(AInitNAmount);
      new(AInitNConc);
      { Berechnung der H20-Volumina der EWZ [cm3] }
      AVol_H20^ := RasterData.PosArr[i].area * theta.V * Tiefe.V;
      // Berechnung der NMengen in den EWZ zu Beginn (Startwerte)
      AInitNAmount^ := AVol_H20^ * c_start.V;
      // Einheitliche Konzentration in den EWZ zu Beginn (Startwerte)
      AInitNConc^ := c_start.V;
      VolH20_EWZ_List.Add(AVol_H20);
      Cl_mean_List.Add(AInitNConc);
      Init_NAmountEWZList.Add(AInitNAmount);
      // NAmount_UPEWZArray[i].V:=0.0; //Zu Beginn noch keine Aufnahme
    end;
  end; // End if calcAnalyt=false
  { Wenn kein 2D-Modell vorhanden, dann kümmert sich das 1D-Modell um eine Ausgabe
    in das Tabellenobjekt, das die WAP-Querschnitte darstellt, ansonsten übernimmt
    dies das 2D-Submodell (Ausnahme: falls Parameter gelesen werden und es sich nicht
    um eine zufällige oder regelmäßige Verteilung handelt, macht eine Ausgabe keinen
    Sinn, da es zu schwierig/willkürlich ist exakte Wurzelpos. zu berechnen }
  if (My2DDiffModel = nil) and (iniMethod.Option <> 'inppar') and
    (RootDistribution.Option = 'lognormal') then
  begin
    fillChartRootDistr;
  end;
  if (My2DDiffModel = nil) and (iniMethod.Option = 'rasterdatafile') then
    fillGridRasterData;
end; // End TSubmodRootDiff1DSolo.Init(var GlobMod: TMod)

procedure TSubmodRootDiff1DSolo.CalcRates;
(* -----------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: In der Methode wird die Ablaufsteuerung des Submodells zur Raten-
  berechnung aufgerufen.
  ------------------------------------------------------------------------------ *)
begin
  { Implementierung wurde ausgelagert, sodass bei Verwendung der analytischen
    Lösung die Berechnung mit Hilfe der Ratengleichung auf einfachem Wege ausgeschaltet
    werden kann (Schalter in createAll). Nur bei Verwendung der numerischen Lösung
    oder wenn bei Berechnungsarten ausgeführt werden, soll hier die Ratenberechnung
    stattfinden }
  inherited CalcRates;
  De.V := Dl.V * 3.35 * sqr(theta.V);
  if (integrationMethod.Option = 'numeric') or
    (integrationMethod.Option = 'both') then
  begin
    { Hinweis: inherited kann an verschiedenen Positionen innerhalb einer Methode
      aufgerufen werden. }
    Calc_numeric;
  end;
end; // End  TSubmodRootDiff1DSolo.CalcRates

procedure TSubmodRootDiff1DSolo.Integrate;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Lösung der Differentialgleichungen.
  ------------------------------------------------------------------------------ *)
begin
  if StatN_AmountSoil.Option = 'static' then
  begin
    if (integrationMethod.Option = 'analytic') or
      (integrationMethod.Option = 'both') then // analytische Lösung
    begin
      // Berechnung macht nur Sinn, wenn Wurzeln oder Parameterwerte vorhanden
      if (num_Roots.V <> 0) then
        // für Modellvergleich:
        if compareMode.Option = 'yes' then
        begin
          // nichts machen
        end
        else
          Integrate_Analyt;
    end
    else // numerische Lösung
    begin
      { Bei Verwendung der numerischen Lösung wird automatisch integriert (inherited) }
      inherited;
    end;
    { Berechnung der im Boden vorhandenen N-Menge aus der anteilig aufgenommenen N-
      Menge: }
    if integrationMethod.Option = 'both' then
    begin
      if compareMode.Option = 'yes' then
      begin
        calcN_AmountSoilEquil;
      end
      else
      begin
        N_AmountSoil.V := NAmountInit - (NAmountInit * N_MengeAnteilAn.V);
        N_AmountSoilNum.V := NAmountInit - (NAmountInit * N_MengeAnteilNum.V);
      end;
    end;
    if integrationMethod.Option = 'analytic' then
    begin
      if compareMode.Option = 'yes' then
        calcN_AmountSoilEquil
      else
        N_AmountSoil.V := NAmountInit - (NAmountInit * N_MengeAnteilAn.V);
    end;
    if integrationMethod.Option = 'numeric' then
    begin
      if compareMode.Option = 'yes' then
        calcN_AmountSoilEquil
      else
        N_AmountSoilNum.V := NAmountInit - (NAmountInit * N_MengeAnteilNum.V);
    end;
  end
  else // Annahme einer dynamischen Veränderung des N-Gehalts im Boden
  begin
    // Implementierung fehlt noch
  end;
  { Wenn kein 2D-Diff-Modell vorhanden, dann Ausgabe von XY-Koordinaten der gültigen
    Wurzeln (im Beobachtungsfenster, aber nicht im Rand) }
  if (My2DDiffModel = nil) and (OutputXY.Option = 'yes') then
  begin
    writeOutputToFile;
  end;
end; // End TSubmodRootDiff1DSolo.Integrate

{ Hilfsmethoden }
procedure TSubmodRootDiff1DSolo.init_eingelesen;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:
  Initialisierungen und Vorbereitungen die erst sinnvoll sind,
  wenn Benutzereingaben bzw. zur Laufzeit aus Dateien eingelesene Daten berücksich-
  tigt werden können.
  Vor allem Ausschluss von Wurzeln in den Rändern: Problem: für das
  numerische Modell sollte PosArr_middle in der Methode removeMarginRoots
  durch eine globale Liste oder ein Array ersetzt werden, welches SRP-Instanzen
  speichert, die hier dann erzeugt werden.
  ------------------------------------------------------------------------------ *)
begin
  inherited init_eingelesen;
  // removeMarginRoots; //gegf. randständige Wurzeln entfernen
end; // End TSubmodRootDiff1DSolo.init_eingelesen

procedure TSubmodRootDiff1DSolo.calcVar_Analyt;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE:TSubmodRootDiff1DSolo
  BESCHREIBUNG: Berecnnung (Initialisierung) von Variablen, die für die
  analytische Lösung benötigt werden (mittlere Wurzellängendichte, Varianz,
  Standardabweichung, Variationskoeffizient der Wurzellängendichten und den
  VM-Wert).
  ------------------------------------------------------------------------------ *)
begin
  { Berechnung der mittleren Wurzellängendichte (im Falle der Ini-Methodem InpPar
    oder Submodstruct wurde die Wurzellängendichte bereits eingelesen: }
  if (iniMethod.Option = 'inppar') or (iniMethod.Option = 'submodstruct') then
  begin
    // nichts machen
  end
  else
    RLD_mean.V := mean(WLD_Array);
  if RootDistribution.Option = 'regular' then
  begin
    // Bei Gleichverteilung sind Standardabweichung etc. = Null
    StdAbw_RLD.V := 0;
    // Berechnung der Varianz der mittleren WLD
    Varianz.V := 0;
    // Berechnung des Variationskoeffizienten der mittleren Wurzellängendichte
    VarKoeff_RLD.V := 0;
  end;
  // im folgenden Fällen wurde Variationskoeff als Par. eingelesen
  if ((iniMethod.Option = 'inppar') and (RootDistribution.Option = 'lognormal'))
    or ((iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option = 'lognormal')) then
  begin
    StdAbw_RLD.V := VarKoeff_RLD.V * self.RLD_mean.V / 100;
    Varianz.V := sqr(StdAbw_RLD.V);
    // auch für Flächenparameter
    StdAbw_Area.V := VarKoeff_Area.V * Area_mean.V / 100;
  end
  // in allen anderen Fällen wurde ein wlDArr erzeugt, aus dem berech. werden kann.
  else
  begin
    // nicht im Falle der Gleichverteilung
    if RootDistribution.Option <> 'regular' then
    begin
      // Berechnung der Standardabweichung der mittleren Wurzellängendichte
      StdAbw_RLD.V := StdDev(WLD_Array);
      // Berechnung der Varianz der mittleren WLD
      Varianz.V := Math.Variance(WLD_Array);
      // Berechnung des Variationskoeffizienten der mittleren Wurzellängendichte
      VarKoeff_RLD.V := StdAbw_RLD.V / self.RLD_mean.V * 100;
    end;
  end;
  // Berechnung des V/M-Wertes
  if RLD_mean.V <> 0 then
  begin
    VM.V := Varianz.V / RLD_mean.V;
    { Berechnung der Standardabweichung der logtransformierten Werte
      aus dem Mittelwert und der Standardabweichung der nicht transformierten Werte,
      Kage }
    Log_StdAbw_RLD.V :=
      sqrt(ln((StdAbw_RLD.V * StdAbw_RLD.V) / (RLD_mean.V * RLD_mean.V) + 1));
    { Berechnung des Mittelwertes der log-transformierten Werte aus dem
      Mittelwert der NICHT transformierten Werte (RLD_mean) und der Standardabweichung
      der LOG-TRANSFORMIERTEN Werte (SA_ln), Kage }
    Log_RLD_mean.V := ln(RLD_mean.V) - 0.5 *
      (Log_StdAbw_RLD.V * Log_StdAbw_RLD.V);
    { Logtransformierte Werte für die Flächenparameter, da diese aus logtransformierten
      Einzelwerten berechnet werden müssen, finden folgende zwei Zeilen im Modus inppar
      nicht statt }
    if self.iniMethod.Option <> 'inppar' then
    begin
      Log_StdAbw_Area.V :=
        sqrt(ln((StdAbw_Area.V * StdAbw_Area.V) /
        (Area_mean.V * Area_mean.V) + 1));
      Log_Area_mean.V := ln(Area_mean.V) - 0.5 *
        (Log_StdAbw_Area.V * Log_StdAbw_Area.V);
    end;
  end;
end; // End TSubmodRootDiff1DSolo.calcVar_Analyt

procedure TSubmodRootDiff1DSolo.calcRootArea;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Füllen des PosArr, Berechnen der Positionen und Flächeninhalte
  zwei Methoden: Voronoi Polygone, oder anteiliger Flächeninhalt eines Grids, in
  dem sich Wurzeln befinden.
  ------------------------------------------------------------------------------ *)
begin
  if (CalcMethRLD_VC.Option = 'voronoi') then
  // Berechnung aus Voronoi-Polygonen
  begin
  end
  else // Berechnung aus Grid-Belegung
  begin
  end;
end;

procedure TSubmodRootDiff1DSolo.copyPosArrFrom2DDif;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:Kopiert das PosArr des 2D-Modells
  ------------------------------------------------------------------------------ *)
var
  RasterData2D: TRasterData;
  i: integer;
begin
  if My2DDiffModel <> nil then // sicherheitshalber
  begin
    RasterData2D := My2DDiffModel.getRasterData;
    RasterData.NRoots := RasterData2D.NRoots;
    for i := 0 to RasterData.NRoots do
    begin
      RasterData.PosArr[i].x := RasterData2D.PosArr[i].x;
      RasterData.PosArr[i].y := RasterData2D.PosArr[i].y;
      RasterData.PosArr[i].xi := RasterData2D.PosArr[i].xi;
      RasterData.PosArr[i].yi := RasterData2D.PosArr[i].yi;
      RasterData.PosArr[i].root := RasterData2D.PosArr[i].root;
      RasterData.PosArr[i].NInflux := RasterData2D.PosArr[i].NInflux;
      RasterData.PosArr[i].SumNMenge := RasterData2D.PosArr[i].SumNMenge;
      RasterData.PosArr[i].WInflux := RasterData2D.PosArr[i].WInflux;
      RasterData.PosArr[i].area := RasterData2D.PosArr[i].area;
    end;
  end;
  num_Roots.V := RasterData.NRoots;
end;

procedure TSubmodRootDiff1DSolo.fillWLDArr;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Füllen des WLD_Arrays
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  Radius: real;
  Area_EqualDistrib: double;
begin
  setLength(WLD_Array, trunc(number_consid_roots.V));
  // Zuweisung der Arraygröße
  j := 1; // PosArr beginnt bei 1
  { Sonderfall Gleichverteilung: Fläche Einzugsgebiet ist konstant. Es kann aber sein
    dass das PosArrea Wurzeln enthält für die keine Fläche berechnet wurde, da sie
    sich in bei der Verteilung auf die Fläche ausserhalb des Beobachtungsfensters be-
    finden (TVar ErrorReg). Deshalb f. Lösung: }
  if self.RootDistribution.Option = 'regular' then
  begin
    for i := 0 to trunc(number_consid_roots.V - 1) do
    begin
      // Berechnung des EWZ-Radius aus der Fläche:
      Radius := sqrt(RasterData.PosArr[1].area / Pi);
      WLD_Array[i] := 1 / (Radius * Radius * Pi);
    end;
  end
  else
  begin
    for i := 0 to trunc(number_consid_roots.V - 1) do
    begin
      { Berechnung der Wurzellängendichte aus den Flächeninhalten der Voronoi-Polygone }
      // Berechnung des EWZ-Radius aus der Fläche:
      Radius := sqrt(RasterData.PosArr[j].area / Pi);
      WLD_Array[i] := 1 / (Radius * Radius * Pi);
      inc(j)
    end;
  end;
end;

procedure TSubmodRootDiff1DSolo.Integrate_Analyt;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Lösung der Differentialgleichungen mit einer analytischen Lösung.
  Die Gleichung liefert die anteilige N-Aufnahme zu einer bestimmten
  Simulationszeit für eine geg. Wurzellängendichte.
  Lit.: Nye, Tinker (2000)Solute movement in the rhizosphere p. 299 Gleichung 10.28
  ------------------------------------------------------------------------------ *)
var
  // Dynamisches Array für alle anteiligen Aufnahmeraten in den Klassen
  Aufnahme_arr: Array of real;
  i: integer;
  Rad_EWZ, sumUptClasses: real;
begin
  setLength(Aufnahme_arr, trunc(number_classes.V));
  sumUptClasses := 0;
  { Bei dynamischen Modell (Daten vom Strukturmodell) müssen bestimmte Variablen
    und die Zufallsvariablen in jedem Zeitschritt neu berechnet werden: }
  if iniMethod.Option = 'submodstruct' then
  begin
    calcVar_Analyt;
    if RootDistribution.Option = 'lognormal' then
    begin
      // Berechnung der Klassenmittelwerte der WLD aus den Kennzahlen der WLD -Verteilung
      if CalcMethQuant.Option = 'fromrld' then
        get_lognorm_ZV
      else
      // Berechnung der Klassenmittelwerte der WLD aus der Flächenverteilung
      begin
        get_lognorm_ZV_Area;
      end;
    end;
    if RootDistribution.Option = 'normal' then
    begin
      get_normvert_ZV;
    end;
  end;

  { folgende Fallunterscheidung ist notwendig, da (zumindest bei angenommener Nor-
    malverteilung) negative Wurzellängendichten auftreten können. }
  if RootDistribution.Option <> 'normal' then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      // Berechnung des Radius des Einzelwurzelzylinders
      Rad_EWZ := 1 / (sqrt(Pi * ZV_Array_lognorm[i]));
      if iniMethod.Option = 'SubmodStruct' then
      // Vorgehensweise bei dynam. Simulation (variable RLD/VK in jedem Zeitschritt
      begin
        Aufnahme_arr[i] := Aufnahme_arr[i] +
          (1 - exp((2 * Pi * ZV_Array_lognorm[i] * Globmod.TimeStep * De.V *
          86400) / (ln(1.65 * Rad_Wurzel.V / Rad_EWZ))));
      end
      // Vorgehensweise bei statischer Simulation
      else
        Aufnahme_arr[i] := 1 -
          exp((2 * Pi * ZV_Array_lognorm[i] * Globmod.time.V * De.V * 86400) /
          (ln(1.65 * Rad_Wurzel.V / Rad_EWZ)));
    end;
    // Bei der Berechnung der Aufnahmen auf Grundlage der Fläche
    if CalcMethQuant.Option = 'fromarea' then
    begin
      for i := 0 to trunc(number_classes.V - 1) do
      begin
        sumUptClasses := sumUptClasses + (Aufnahme_arr[i] * weightArr[i]);
      end;
      N_MengeAnteilAn.V := sumUptClasses;
    end
    { ansonsten Bilden des Mittelwerts sämtlicher anteiliger N-Aufnahmen. Problem:
      ist möglicherweise falsch, auch bei Berechnung auf Grundlage der RLD brauch ich
      wohl die Summme }
    else
      N_MengeAnteilAn.V := mean(Aufnahme_arr);
  end;
  if RootDistribution.Option = 'normal' then
  // Problem: Implementierung steht noch aus
  begin
  end;
  // auch im Falle regular wird alles von der Lognormal-Methode erledigt
  { if RootDistribution.Option = 'regular' then
    begin }
  { Sämtliche Senken mit gleichem Flächeninhalt des EWZ, Standardabweichung der
    WLD = 0 }
  // Rad_EWZ := 1/(sqrt(Pi*RLD_mean.V));
  // N_MengeAnteilAn.V:= 1-exp((2*Pi*RLD_mean.V*Globmod.time.V*
  // De.v*86400)/(ln(1.65*Rad_Wurzel.V/Rad_EWZ)));
  { 1-EXP((2*PI()*RLD(0.1867)*t*D(0.2223)/LN(1.65*RadW(0.02)/RadEWZ(1.3056)) }
  // end;
  Sum_N_AmountRoots.V := N_MengeAnteilAn.V * NAmountInit;
end;

// Hilfsmethoden für analytische Lösung
// Hilfsmethoden zur u-Wert-Bestimmung

procedure TSubmodRootDiff1DSolo.get_normvert_ZV;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Berechnet aus den in z_quartile gespeichterten u-Werten der
  Standardnormalverteilung (für die Quartile = Mittelwerte der 10 Klassen) die
  f(x)-Werte (Werte der Zufallsvariablen) der vorliegenden Normalverteilung.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  // Berechnung der Zufallsvariablen nur wenn Wurzeln vorhanden
  if RLD_mean.V <> 0 then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      ZV_Array_normvert[i] := ZV_Array_Stdnorm[i] * StdAbw_RLD.V + RLD_mean.V;
    end;
  end;
end; // End TSubmodRootDiff1DSolo.get_normvert_ZV

procedure TSubmodRootDiff1DSolo.get_lognorm_ZV;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Berechnet für die Quartile (= Mittelwerte der 10 Klassen) die
  f(x)-Werte (Werte der Zufallsvariablen) der vorliegenden Lognormalverteilung.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  // Berechnung der Zufallsvariablen nur wenn Wurzeln vorhanden
  if RLD_mean.V <> 0 then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      ZV_Array_lognorm[i] := exp(ZV_Array_Stdnorm[i] * Log_StdAbw_RLD.V +
        Log_RLD_mean.V);
    end;
  end;
end; // End TSubmodRootDiff1DSolo.get_lognorm_ZV

procedure TSubmodRootDiff1DSolo.get_lognorm_ZV_Area;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Berechnet für die Quartile (= Mittelwerte der 10 Klassen) die
  f(x)-Werte (Werte der Zufallsvariablen) der vorliegenden Lognormalverteilung aus
  der Flächenverteilung.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  sumPhiUArea // summe der Phi(u)-Werte der Flächenquantile, für Wichtung
    : double;
begin
  // Berechnung der Zufallsvariablen nur wenn Wurzeln vorhanden
  sumPhiUArea := 0;
  if RLD_mean.V <> 0 then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      ZV_Array_lognorm[i] :=
        (exp(ZV_Array_Stdnorm[i] * Log_StdAbw_Area.V + Log_Area_mean.V));
      sumPhiUArea := sumPhiUArea + ZV_Array_lognorm[i];
    end;
  end;
  // Berechnung der Wichtungsfaktoren
  for i := 0 to trunc(number_classes.V - 1) do
  begin
    weightArr[i] := ZV_Array_lognorm[i] / sumPhiUArea;
  end;
  // Berechnung der WLD aus den Phi(u)-Werten der Fläche
  for i := 0 to trunc(number_classes.V - 1) do
  begin
    ZV_Array_lognorm[i] := 1 / ZV_Array_lognorm[i];
  end;
end; // End TSubmodRootDiff1DSolo.get_lognorm_ZV_Area

function TSubmodRootDiff1DSolo.Kolmogorov_Smirnov: boolean;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Funktion ist notwendig, da Berechnung der anteiligen Aufnahme in
  Abhängigkeit von der angenommenen Verteilungsfunktion durchgeführt wird.
  In der Funktion wird der Kolmogorov Smirnov - Anpassungstest durch-
  geführt (hier als Test auf eine angenommene Lognormalverteilung)
  Rückgabewert ist true bei 'bestandenem' Test, false im Falle einer Ablehnung der
  Nullhypothese (Beobachtete W. entspricht einer Lognormalverteilung)
  Problem: Sollte eher der K-Wert (stimmt das? ) zurückgegeben werden und dann
  dieser Wert von der aufrufenden Methode weiter verarbeitet werden?
  ------------------------------------------------------------------------------ *)
begin
  // Problem: Implementierung
  Result := true;
end; // End TSubmodRootDiff1DSolo.Kolmogorov_Smirnov

// Hilfsmethoden für numerische Lösung
procedure TSubmodRootDiff1DSolo.Calc_numeric;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Methode übernimmt die Berechnung der Ratengleichung mit Hilfe der
  numerischen Lösung
  ------------------------------------------------------------------------------ *)
begin
  // Berechnung
  { Hinweis: Für die Berechnung der Summe aller Ratengleichungen wurde folgender-
    maßen vorgegangen (2 Varianten):
    a) Berechnung der maximalen Nitratinfluxrate für jeden Einzelwurzelzylinder, d.h.
    es wurden die Raten sämtlicher Wurzeln berechnet. Die Einzelergebnisse wurden
    danach aufsummiert (Methode calc_num_EWZ)
    b) Berechnung mit Hilfe der durchschnittlichen WLD in den Klassen, die schon bei
    der Verwendung der analytischen Lösung benutzt wurden und Multiplikation des Er-
    gebnisses mit der Anzahl der Wurzeln in den Klassen (Methode calc_num_Class).
    Hier evtl. bessere Performance und Vergleichbarkeit mit der analytischen Lösung.
    Problem: Überlegung korrekt?
    Je nach Bedarf kann die eine oder die andere Methode auskommentiert werden.
    Möglich wäre auch weitere Option }
  { Problem: Müsste hier stehen  N_MengeAnteil.C:=NMenge.c+calc_num_EWZ; (eher nicht) }
  N_MengeAnteilNum.C := calc_num_EWZ;
  // N_MengeAnteilNum.C:=calc_num_class;
end; // End TSubmodRootDiff1DSolo.Calc_numeric

function TSubmodRootDiff1DSolo.calc_num_EWZ: real;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Berechnung der maximalen Nitratinfluxrate für jeden
  Einzelwurzelzylinder, d.h. es wurden die Raten sämtlicher Wurzeln berechnet.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  Nitrat_Flux_EWZ, // Nitratinflux in Einzelwurzelzylinder
  Sum_Nitrate_flux, // Summe der Nitratinfluxrate aller EWZ
  Db, // Produkt aus Pufferung und effektivem Diffusionskoeffizienten
  dist: real; // Radius des EWZ.
  AClmean: double; // wg. Dereferenzieren des Zeigers

begin
  { Problem: Berechnung korrekt? }
  { Diss. Kage: Db ist das Produkt aus Pufferung und Effektivem Diffusionskoeffi-
    zienten und demnach Db=De*theta, da für nicht sorbierte Ionen gilt: b=theta. }
  Db := De.V * theta.V * 86400;
  j := 1; // PosArr beginnt bei 1
  // Berechnung der aktuellen Konzentrationen für die jeweiligen EWZ
  for i := 0 to trunc(RasterData.NRoots) - 1 do
  begin
    { Konzentration in der Bodenlösung berechnet sich aus der Ausgangs-N-Menge im
      aktuellen Zeitschritt abzüglich der aufgenommenen NMenge (= Summe aller
      integrierten Flüsse im EWZ) Problem: korrekt, Kann man Konzentrationen so einfach
      voneinander abziehen, oder muss zuerst wieder in Mengen umgerechnet werden? }
    { Cl_mean_Array[i]:=Cl_mean_Array[i]-(NAmount_UPEWZArray[i].V/
      VolH20_EWZ_Array[i]); }
  end;
  // Ratenberechnung für alle Wurzeln
  for i := 0 to RasterData.NRoots - 1 do
  begin
    dist := sqrt(RasterData.PosArr[j].area / Pi);
    // Berechnung des Radius des EWZ
    AClmean := Pdouble(Cl_mean_List.items[i])^;
    Nitrat_Flux_EWZ := ((AClmean - Clmin.V) * 2 * Pi * Db) /
      (ln(dist / (1.65 * self.Rad_Wurzel.V))); // Kage Diss, S.57, Gl.3.6.30
    // NAmount_UPEWZArray[i].C:=Nitrat_Flux_EWZ;
    Sum_Nitrate_flux := Sum_Nitrate_flux + Nitrat_Flux_EWZ;
    inc(j);
  end;
  Result := Sum_Nitrate_flux;
end; // End TSubmodRootDiff1DSolo.calc_num_EWZ

function TSubmodRootDiff1DSolo.calc_num_class: real;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG:
  Berechnung der Nährstoffaufnahme rate mit Hilfe der durchschnittlichen WLD in
  den Klassen, die schon bei der Verwendung der analytischen Lösung benutzt wurden
  und Multiplikation des Ergebnisses mit der Anzahl der Wurzeln in den Klassen
  Hier evtl. bessere Performance und Vergleichbarkeit mit der analytischen Lösung.
  Problem: Implementierung
  ------------------------------------------------------------------------------ *)
begin

end; // End TSubmodRootDiff1DSolo.calc_num_class

procedure TSubmodRootDiff1DSolo.transform_Clmin;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Umrechnung der Bodenlösungskonzentration in mol/l in andere
  Einheiten. Problem: Umrechnung kontrollieren.
  ------------------------------------------------------------------------------ *)
begin
  // Umrechnung von [Mikromol/l] in [Kg/l]
  ClminTransf.V := Clmin.V * 14 / 1E-9;
  // Umrechnung in [KG/ha]
  ClminTransf_ha.V := ClminTransf.V / 1E-7;
end; // End TSubmodRootDiff1DSolo.transform_Clmin

procedure TSubmodRootDiff1DSolo.calc_Amount_H20;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE: TSubmodRootDiff1DSolo
  BESCHREIBUNG: Berechnung der Ausgangswassermenge in der betrachteten Bodenschicht
  ------------------------------------------------------------------------------ *)
begin
  { Wassermenge in der betrachteten Bodenschicht (theta wird zunächst als konstant
    angenommen) }
  Amount_H20.V := volumen.V * theta.V;
end; // End TSubmodRootDiff1DSolo.calc_Amount_H20

procedure TSubmodRootDiff1DSolo.calcN_AmountSoilEquil;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der N-Menge im Boden gemäß Gleichung 3.6.43 Diss. Kage
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  Db, cl_avClass, classBorder: double;
begin
  cl_av.V := 0;
  Db := De.V * theta.V;
  for i := 0 to trunc(number_classes.V - 1) do
  begin
    // Aus der WLD muss der Radius (Klassengrenze) berechnet werden:
    classBorder := sqrt(1 / (ZV_Array_lognorm[i] * Pi));
    cl_avClass := Clmin.V - (Min_s.V * (sqr(classBorder) - sqr(Rad_Wurzel.V)) /
      (4 * Db)) + (Min_s.V * sqr(classBorder) / (2 * Db) *
      ln(classBorder / Rad_Wurzel.V));
    // Wichtung
    cl_avClass := cl_avClass * weightArr[i];
    cl_av.V := cl_av.V + cl_avClass;
  end;
  N_AmountSoil.V := Mg_func(Tiefe.V, theta.V, cl_av.V);
end;

end.
