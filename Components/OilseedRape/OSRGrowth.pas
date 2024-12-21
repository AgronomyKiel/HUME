unit OSRGrowth;
{Modellbeschreibung in: Dissertation W. Weymann 2015, Chapter 4:
 Development and evaluation of a new dynamic crop growth model for
 winter oilseed rape in temperate regions in Europe}

interface

uses
  Windows,
//  Messages,
   SysUtils,
    Classes,
//     vcl.Graphics,
//      vcl.Controls,
//       vcl.Forms,
//       vcl.Dialogs,
  UMod,
  UState,
  UlayeredSoil,
  USoilNitrogenUp,
  UAbstractPlant,
  UGrowthCurvePlantRoots,
  UAbstractSoilMin,
  DevelopmentOSR,
  USnowPack;

const
  MaxParDays = 10;


Type
TLAIOption = (InternLAI,ExternLAI);
TDMOption = (InternDM,ExternDM);
TInitOption = (DMCritInit,LAIInit);
TNSensOption = (N_sensitiv,N_unlimited);
TDroughtOption = (DroughtImpact, NoDroughtImpact);

TOSRGrowth = class(TAbstractPlant)

private
  DateHarvestWasSet : boolean;
  StateVar : TState;
  avs_day : integer;
  Par_arr : array[1..MaxParDays] of real;

protected
  fDevelopmentModel: TDevelopmentOSR;
  fSnowModel: TSnowPack;
  procedure setDevelopmentModel(AModel: TDevelopmentOSR);
  function GetLAI:THumeNumEntity; override;
//  procedure SetLai(NewLAI:THumeNumEntity); override;
  function GetCropHeight:THumeNumEntity; override;
//  procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;
  function GetNUptakeRate:THumeNumEntity; override;
//  procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); override;
  procedure setNextCrop(NextCrop:TAbstractplant); override;
  function GetWLD(Index:Integer):THumeNumEntity; override;
  function GetSumRootLength:THumeNumEntity; override;
  function GetSumRootLength_eff:THumeNumEntity; override;
//  procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); override;
  function getExtCoeffPAR: real; override;


public
  // Variables
  PARRad : TVar;     // photosynthetisch aktive Strahlungssumme [W/m²]
  fT : TVar;         // Wirkungsfaktor der Photosynthese, aus Temperatur abgeleitet
  Q : TVar;          // aufgenommene Strahlungsmenge  [MJ]
  QLeaf : TVar;      // aufgenommene Strahlungsmenge Blätter
  QGen : TVar;       // aufgenommene Strahlungsmenge Schoten
  Transkoeff : TVar; // Transmissionskoeffizient Schotenentwicklung
  fInt: TVar;        // Anteil aufgenommener Strahlung []
  fIntLeaf : TVar;   // Anteil aufgenommener Strahlung Blätter
  fIntGen : TVar;    // Anteil aufgenommener Strahlung Schoten
  Teff : TVar;       // Temperatur-BasisTemperatur [°C]
  fRoot: TVar;       // Anteil Wurzelzuwachs []
  maxfRoot : TVar;   // maximaler Anteil Wurzelzuwachs
  fBl : TVar;        // Anteil Blattzuwachs
  fBl_EC51 : TVar;   // Anteil Blattzuwachs bei EC 51
  fSt : TVar;        // Anteil Stängelzuwachs
  fGen : TVar;       // Anteil Schotenzuwachs
  fPW : TVar;        // Anteil der Schotenhülle am generativen Gesamtwachstum
  fSeedGen : TVar;   // Anteil Samenzuwachs in der Schote
  fSeedStarch : TVar;
  fSeedOil : TVar;
  fSum : TVar;
  fNNILeaf : TVar;
  fNNIStem : TVar;
  fNNIGen : TVar;
  fNNIRoot : TVar;
  Tminus : TVar;     // Temperatur unter Null [°C]
  NcLeaf : TVar;     // Blatt N-Konzentration  [%]
  NcLeaf_VA : TVar;  // Blatt N-Konzentration zu Vegetationsbeginn [%]
  NcStem : TVar;     // Stängel N-Konzentration  [%]
  NcStem_VA : TVar;
  NcStem_EC70 : TVar;// Stängel N-Konzentration bei EC 70 [%]
  NcGen : TVar;      // generative N-Konzentration [%]
  NcRoot : TVar;     // Wurzel N-Konzentration  [%]
  NcRoot_VA : TVar;
  NcRoot_EC70 : TVar;// Wurzel N-Konzentration bei EC 70 [%]
  NUptakeRate_pot : TVar;  // potenzielle N-Aufnahmerate  g/m²*d
  NNI: TVar;               // Nitrogen Nutrition Index
  CropHeight : TVar;       // Bestandeshöhe
  LAILeaf_EC70 : TVar;     // LAI zu EC 70
  actSLA : TVar;           // Spezifische Blattfläche [cm²/g]
  avSLA: TVar;
  actSPA : TVar;     // Spezifische Schotenfläche [cm²/g]
  avSPA : TVar;
  LUE : TVar;     // Lichtnutzungeffizienz gebildetet Trockenmasse pro aufgenommener Strahlungsmenge [g/MJ]
  LUEGen : TVar;  // Lichtnutzungseffizienz Schoten
  CO2_factor :TVar;  /// factor for adjusting LUE for CO2-effect
  g : TVar;       // Steigung der allometrischen Funktion
  h : TVar;       // Interzept der allometrischen Funktion
  LAIm : TVar;    // Maximaler LAI bei vorhandener Strahlung [m²/m²]
  fTm : TVar;     // Temperaturfaktor Erhaltungsatmung zur Berechnung von PARm
  fTSen : TVar;
  fSen_sh: TVar;  // Seneszenzfaktor Beschattung
  Auflauf : TVar; // Zeitpunkt des Auflaufens [Zahl]
  QT : TVar;      // Temperatur korrigierte aufgenommene Strahlungsmenge [MJ]
  act_k : TVar;   // Extinktionskoeffizient für PAR = exk bzw. variabler Wert für LAI < LAIcrit_exk
  act_k_Leaf : TVar;  // Extinkttionskoeffizient der Blätter
  act_k_Gen : TVar;   // Extinktionskoeffizient der Schoten
  DummyVar : TVar;
  EC_act : TVar;  // EC-Wert bei LAIShoot LAIShoot = 2.0
  maxGAI : TVar;      //  maximaler GAI
  maxLAIGen : TVar;   // maximaler PAI
  maxLAIStem : TVar;  // maximaler SAI
  dNcLeaf : TVar;
  dNcStem : TVar;
  dNcRoot : TVar;
  dNcGen : TVar;
  NcritLeaf : TVar;
  NcLeaf_act : TVar;
  NcritStem : TVar;
  NcStem_act : TVar;
  NcritGen : TVar;
  NcGen_act : TVar;
  NcritRoot : TVar;
  NcritRoot_VA : TVar;
  NcRoot_act : TVar;
  NcritLeaf_VA : TVar;
  NcritStem_VA : TVar;
  NcritStem_EC70 : TVar;
  NcritRoot_EC70 : TVar;
  NNILeaf : TVar;
  NNIStem : TVar;
  NNIGen : TVar;
  NNIRoot : TVar;
  PARav : Tvar;
  PAI : TVar;
  SAI : TVar;
  SLAf : TVar;

  NDemandGrowth : TVar;
  NDemandDeficit : TVar;
  NDemandDeficitLeaf : TVar;
  NDemandDeficitStem : TVar;
  NDemandDeficitRoot : TVar;
  NDemandDeficitGen : TVar;
  NSupply : TVar;

  TKM : TVar;              // Tausend-Korn-Masse
  Samenanzahl : TVar;      // Anzahl Samen pro m²
  HI : TVar;               // Harvest Index
  NHI : TVar;              // Nitrogen Harvest Index
  NUE : TVar;              // Nitrogen Use Efficiency


  KonversionVerlust : TVar;

  avs : TVar;
  fW : TVar;

  N_Def : TVar;         // N-Defizitfaktor (Verhältnis von N-Bedarf und N-Aufnahme)

  LAImarray : Array [1..10] of real;

  fRootModel: TGrowthCurvePlantRoots{TSimpleRootModDM};

  // Constant Variables

  DMShoot : TState;  // Sprosstrockenmasse [g/m²]
  DMShoot_vW : TState;  // Sprosstrockenmasse vor Winter [g/m²]
  DMShoot_OF : TState;  // shoot dm before onset flowering
  DMShoot_nB : TState;  // shoot dm accumulation since flowering
  DMShoot_nB_pot : TState;  // potentical, drought stress free shoot dm accumulation since flowering
  DMLeaf : TState;   // Blatttrockenmasse [g/m²]
  DMStem : TState;   // Stängeltrockenmasse  [g/m²]
  DMRoot : TState;   // Wurzeltrockenmasse  [g/m²]
  DMGen : TState;    // generative Biomasse [g/m²]
  DMPodWall : TState;// Schotenhüllentrockenmasse [g/m²]
  DMSeed : TState;   // Samentrockenmasse [g/m²]
  DMSeedStarch : TState;
  DMSeedOil : TState;
  DMPlant : TState;  // Gesamttrockenmasse  [g/m²]
  LAIShoot : TState; // Sprossfläche [m²/m²]
  LAILeaf : TState;  // Blattfläche [m²/m²]
  LAIStem : TState;  // Stängelfläche [m²/m²]
  NShoot : TState;   // Spross N-Menge    [g/m²]
  NLeaf : TState;    // Blatt N-Menge    [g/m²]
  strNStem : TState; // strukturelle Stängel N-Menge    [g/m²]
  poolNStem : TState; // N-Pool im Stängel
  NStem : TState;    // Gesamt-N-Menge im Stängel
  NGen : TState;     // generative N-Menge [g/m²]
  strNRoot : TState; // strukturelle Wurzel N-Menge    [g/m²]
  poolNRoot : TState; // N-Pool in den Wurzeln
  NRoot : TState;    // Gesamt-N-Menge in den Wurzeln
  NDead : TState;    // N-Menge in abgestorbenen Blättern [g/m²]
  NPlant : TState;   // N-Menge in Gesamtpflanze [g/m²]
  NSeed : TState;    // N-Menge Samen [g/m²]
  NPodWall : TState; // N-Menge Schotenwände [g/m²]
  NDeadW : TState;   // N-Menge in durch Frost abgestorbenen Blättern [g/m²]
  NDeadSh : TState;  // N-Menge in durch Beschattung abgestorbenen Blättern [g/m²]
  NTransLeaf : TState;  // aus den Blättern translozierte N-Menge [g/m²]
  NTransStem : TState;  // aus den Stängeln translozierte N-Menge [g/m²]
  NTransGen : TState;   // aus den generativen Organene translozierte N-Menge [g/m²]
  NTransRoot : TState;  // aus den Wurzeln translozierte N-Menge [g/m²]
  NTrans : TState;      // gesamte translozierte N-Menge [g/m²]
  potNTrans : TState;   // potentiell translozierbare N-Menge [g/m²]
  potNPool : TState;
  NUptake_pot : TState; // potenziell aufgenommene N-Menge [g/m²]
  NUptake_act : TState; // aktuell aufgenommene N-Menge [g/m²]
  TempSum : TState;     // Temperatursumme [°Cd]
  TempSumAussaat : TState;     // Temperatursumme ab Aussaat[°Cd]
  TempSumMinus : TState;       // Temperatursumme unter Null [°Cd]
  TempSumAuflauf : TState;     // Temperatursumme ab Auflaufen [°Cd]
  TempSumPodGrowth : TState;   // Temperatursumme ab EC70 [°Cd]
  TempSumSeed : TState;
  TempSumLeafLoss : TState;    // Temperatursumme zur Abnahme des Blattwachstums
  TempSumRoots : TState;       // Temperatursumme zur Abnahme des Wurzelanteils
  LAIs : TState;      // Schatten induzierte Seneszenzfläche [m²/m²]
  DMDead : TState;    // seneszente Spross Trockenmasse [g/m²]
  DMDeadW : TState;   // durch Frost abgestorbene Trockenmasse [g/m²]
  DMDeadLeafW : TState; // durch Frostseneszenz abgestorbene Blatttrockenmasse
  DMDeadStemW : TState; // durch Frostseneszenz abgestorbene Stängeltrockenmasse
  DMDeadRootW : TState; // über Winter abgestorbene Wurzeltrockenmasse
  DMDeadSh : TState;  // durch Beschattung abgestorbene Blatttrockenmasse [g/m²]
  DMDeadN : TState;   // durch N-Mangel abgestorbene Blatttrockenmasse [g/m²]
  DM_N : TState;      // ehemalige lebendige (grüne) Trockenmasse, der durch N-Mangel abgestorbenen Blätter
  DMNTrans : TState;  // translozierte Blatttrockenmasse aus N-Mangel
  DMSh : TState;      // ehemalige lebendige Trockenmasse, der durch Beschattung abgestorbenen Blätter [g/m²]
  DMShTrans : TState; // translozierte Blatttrockenmasse aus Beschattungsseneszenz
  DMTransStem : TState; // translozierte Stängel-Trockenmasse [g/m²]
  DMTransLeaf : TState; // translozierte Blatt-Trockenmasse [g/m²]
  DMTrans : TState;     // translozierte Trockenmasse [g/m²]
  LAIGen : TState;    // PodAreaIndex
  sumQ : TState;          // Summe aufgenommene Strahlungsmenge  [MJ]
  sumQT : TState;          // Summe tempeaturkorrigierte aufgenommene Strahlungsmenge  [MJ]
  sumQT_TactTpot : TState; // Summe Trockenstress/Temperatur korrigierte aufgenommene Strahlungsmenge  [MJ]
  sumQLeaf : TState;      // Summe aufgenommene Strahlungsmenge Blätter
  sumQGen : TState;       // Summe aufgenommene Strahlungsmenge Schoten
  RadSum : TState;    // Strahlungssumme

  C_Dead : TState;    // C-Menge der abgeworfenen Blätter [kg/ha]
  N_Dead : TState;    // N-Menge der abgeworfenen Blätter [kg/ha]

  DMDeadAge : TState;
  NDeadAge : TState;

  NPool : TState;

  Yield : TState;
  OilYield : TState;
  Oilconc : TState;
  Protein : TState;
  Ymax : TState;

  FullFlower : TState;
  SumKonversionVerlust : TState;

  NBalance : TState;
  NUptake_vW : TState;
  NUptake_aF : TState;

  // Parameters

  Tb : TPar;   // Basistemperatur 3 [°C]
  gh : TPar;   // Steigung der Allometrischen Funktion im Herbst
  hh : TPar;   // Interzept  der Allometrischen Funktion im Herbst
  gf : TPar;   // Steigung der Allometrischen Funktion im Frühjahr
  hf : TPar;   // Interzept der Allometrischen Funktion im Frühjahr
  a : TPar;    // Parameter zur DM-Fraktionierung nach EC51
  b : TPar;    // Parameter zur DM-Fraktionierung nach EC51
  c : TPar;    // Parameter zur DM-Fraktionierung nach EC51
  d : TPar;    // Parameter zur DM-Fraktionierung nach EC51
  e : TPar;    // Parameter zur DM-Fraktionierung nach EC51
  root_exp : TPar;    // Parameter für Exponentialfunktion von DMRoot
  SPA_exp : TPar;    // Parameter für Exponentialfunktion von SPA
  fPW_0 : TPar;    // Parameter für Ertragsfunktion (fPW)
  fPW_exp : TPar;    // Parameter für Ertragsfunktion (fSSt)
  pCnPod1 : TPar;
  pCnPod2 : TPar;
  pCnstem1h : TPar;   // vor Eulerschen Zahl für Stängel-Verdünnungsfunktion (Herbst)
  pCnstem2h : TPar;   // vor Variablen für Stängel-Verdünnungsfunktion (Herbst)
  pCnRoot1h : TPar;    // vor Eulerschen Zahl für Wurzel-Verdünnungsfunktion
  pCnRoot2h : TPar;    // vor Variablen für Wurzel-Verdünnungsfunktion
  pCnRoot1f : TPar;    // vor Eulerschen Zahl für Wurzel-Verdünnungsfunktion
  pCnRoot2f : TPar;    // vor Variablen für Wurzel-Verdünnungsfunktion
  pCnleaf : TPar;     // Blatt N-Konzentration [%]  (Frühjahr)
  pCn1leaf : TPar;    // Interzept der Verdünnungsfunktion Blatt (Herbst)
  pCn2leaf : TPar;    // Steigung der Verdünnungsfunktion Blatt (Herbst)
  pCnDead: TPar;      // N-Konzentration abgestorbener Blätter  [%]
  pCnRoot: TPar;      // N-Konzentration Wurzeln [%]
  pCnSeed : TPar;     // N-Konzentration Samen [%]
  pCnTrans : TPar;    // Anteil N-Menge, der aus seneszenten Blättern transloziert wird
  Ct1 : TPar;    // Kardinaltemperatur untere Wachstumsgrenze
  Ct2 : TPar;    // Kardinaltemperatur untere Optimumsgrenze
  Ct3 : TPar;    // Kardinaltemperatur obere Optimumsgrenze
  Ct4 : TPar;    // Kardinaltemperatur obere Wachstumsgrenze
  SLAnB : TPar;  // Spezifische Blattfläche nach der Blüte [cm²/g]
  SLAhst : TPar; // Spezifische Blattfläche Herbst Steigungsparameter
  SLAhin : TPar; // Spezifische Blattfläche Herbst Interzeptparameter
  SLAmin : TPar; // Minimale spezifische Blattfläche Herbst  [cm²/g]
  SLAmax : TPar; // Maximale spezifische Blattfläche Herbst  [cm²/g]
  SLADead : TPar;// SLA seneszenter Blätter [cm²/g]
  fTminus : TPar;// Temperaturschwellenwert für Seneszenz über Winter [cm²/g]
  SSA : TPar;    // Spezifische Stängelfläche [cm²/g]
  SPAmax : TPar; // Maximale spezifische Schotenfläche [cm²/g]
  k1 : TPar;     // Wachstumsrate zwischen EC10 bis DMcrit
  DMcrit : TPar; // DM-Grenzwert des exponentiellen Wachstums
  rooti : TPar;  // Interzept der Wurzelanteilregression
  roots : TPar;  // Steigung der Wurzelanteilregression
  exk : TPar;    // Lichtextinktionskoeffizient
  exk_0 : TPar;  // Extinktionskoeffizient bei LAI=0
  LAIcrit_exk : TPar; // LAIcrit, bei dem Extinktionskoeffizient = exk
  LUELeaf : TPar;         // LUE
  LUE0 : TPar;        // Interzept der LUE Gleichung VW
  LUEPod : TPar;      // LUE der Schoten
  PARmh : TPar;       // einfallende Strahlungsmenge, die zur Erhaltung von DMShoot nötig ist (bei pfTm_opt); Herbst
  PARmf : TPar;       // einfallende Strahlungsmenge, die zur Erhaltung von DMShoot nötig ist (bei pfTm_opt); Frühjahr
  pfTm_opt: TPar;     // Optimaltemperatur für fTm nach Arrhenius
  pfTm_Q10: TPar;     // Q10-Wert für fTm nach Arrhenius
  pSen_sh: TPar;      // Anzahl Tage, über die PARm gemittelt wird
  pSen_sh_w: TPar;    // Exponent für Wirkung des Faktors fSen_sh
  fSws : TPar;        // Steigung der linearen Regression von DMShoot Verlust zu MinTempSum
  Plants: TPar;       // Pflanzen pro m²
  pIniLAI: TPar;      // LAI nach Auflaufen bei InitOption LAIInit [cm²/Pflanze]
  pCncritLeaf : TPar;
  pCncrit1Leaf : TPar;
  pCncrit2Leaf : TPar;
  pCncritStem1h : TPar;
  pCncritStem2h : TPar;
  pCncritPod1 : TPar;
  pCncritPod2 : TPar;
  pCncritRoot1h : TPar;
  pCncritRoot2h : TPar;
  pCncritRoot1f : TPar;
  pCncritRoot2f : TPar;
  pCnStem1f : TPar;
  pCnStem2f : TPar;
  pCncritStem1f : TPar;
  pCncritStem2f : TPar;
  y1 : TPar;
  SLAspring : TPar;
  fSLAspring : TPar;
  Oila : TPar;
  Oilb : TPar;
  Oilc : TPar;
  Oild : TPar;
  pfW:   TPAR;
  LUEscaling: TPAR; /// Parameter for simultanous scalue of LUEveg and LUEgen []
//  minNNI : TPar; /// minimum NNI Value [0..1]

  fCO2_scale     : TPar;
  fCO2           : TPar;
  fCWSI          : TPar;  /// adjusting CO2-effect for drought stress level
  CiCompensation : TPar; /// CO2-compensation Point


  // External Variables

  GRad : TExternV;         // Globalstrahlung [W/m²]
  TMPM : TExternV;         // Tagesmitteltemperatur
  EC : TExternV;           // EC-Stadium
  DVS_rate : TExternV;      // ratefield DVS
  DVS : TExternV;          // Development-Stage
  DayofYear : TExternV;    // Tag des Jahres
  LUE_LAI : TExternV;      // LAI-Daten
  DMGrowth_ex: TExternV;   // DMShoot-Zuwachs für Option ExternDM [g.m-2.d-1]
  TransRatio : TExternV;   // Wasserdefizit
  TransIntRatio : TExternV;
//  CO2pp:    TExternV;        /// external atmospheric CO2-concentration


//  TMeanEC71_79 : TExternV;
//  DauerEC71_79 : TExternV;
//  DauerEC81_89 : TExternV;
  DauerEC81_89: TState;

  //Options

  fLAIOption : TLAIOption;
  LAIOption : TOption;
  fDMGrowthOption : TDMOption;
  DMGrowthOption : TOption;
  fInitOption: TInitOption;
  InitOption: TOption;
  fNSensOption: TNSensOption;
  NSensOption: TOption;
  fDroughtOption : TDroughtOption;
  DroughtOption : TOption;
  OptWithCO2: TOption;


  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;
  procedure SetSowingDate(NewSowingDate: real);  override;


published

  // Variables

  Property Var_PARRad : TVar read PARRad write PARRad;
  Property Var_fT : TVar read fT write fT;
  Property Var_Q : TVar read Q write Q;
  Property Var_QT : TVar read QT write QT;
  Property Var_Teff : TVar read Teff write Teff;
  Property Var_fRoot : TVar read fRoot write fRoot;
  Property Var_maxfRoot : TVar read maxfRoot write maxfRoot;
  Property Var_fBl : TVar read fBl write fBl;
  Property Var_fPW : TVar read fPW write fPW;
  Property Var_Tminus : TVar read Tminus write Tminus;
  Property Var_NcLeaf : TVar read NcLeaf write NcLeaf;
  Property Var_NcStem : TVar read NcStem write NcStem;
  Property Var_NUptakeRate_pot : TVar read NUptakeRate_pot write NUptakeRate_pot;
  Property Var_CropHeight : TVar read CropHeight write CropHeight;
  Property Var_actSLA : TVar read actSLA write actSLA;
  Property Var_LUE : TVar read LUE write LUE;
  Property Var_g : TVar read g write g;
  Property Var_h : TVar read h write h;
  Property Var_LAIm : TVar read LAIm write LAIm;
  Property Var_fTm : TVar read fTm write fTm;
  Property Var_Auflauf : TVar read Auflauf write Auflauf;
  Property Var_EC_act :  TVar read EC_act write EC_act;

  // State Variables

  Property St_DMShoot : TState read DMShoot write DMShoot;
  Property St_DMLeaf : TState read DMLeaf write DMLeaf;
  Property St_DMStem : TState read DMStem write DMStem;
  Property St_DMPlant : TState read DMPlant write DMPlant;
  Property St_DMRoot : TState read DMRoot write DMRoot;
  Property St_DMGen : TState read DMGen write DMGen;
  Property St_DMPodWall : TState read DMPodWall write DMPodWall;
  Property St_DMSeed : TState read DMSeed write DMSeed;
  Property St_LAIShoot : TState read LAIShoot write LAIShoot;
  Property St_LAILeaf : TState read LAILeaf write LAILeaf;
  Property St_LAIStem : TState read LAIStem write LAIStem;
  Property St_NShoot : TState read NShoot write NShoot;
  Property St_NLeaf : TState read NLeaf write NLeaf;
  Property St_strNStem : TState read strNStem write strNStem;
  Property St_strNRoot : TState read strNRoot write strNRoot;
  Property St_NDead : TState read NDead write NDead;
  Property St_TempSum : TState read TempSum write TempSum;
  Property St_TempSumAussaat : TState read TempSumAussaat write TempSumAussaat;
  Property St_TempSumMinus : TState read TempSumMinus write TempSumMinus;
  Property St_TempSumAuflauf : TState read TempSumAuflauf write TempSumAuflauf;
  Property St_LAIs : TState read LAIs write LAIs;
  Property St_DMdead : TState read DMdead write DMdead;
  Property St_DMDeadW : TState read DMDeadW write DMDeadW;
  Property St_DMDeadSh : TState read DMDeadSh write DMDeadSh;
  Property St_DMDeadN : TState read DMDeadN write DMDeadN;
  Property St_DMSh : TState read DMSh write DMSh;
  Property St_DMShTrans : TState read DMShTrans write DMShTrans;
  Property St_LAIGen : TState read LAIGen write LAIGen;
  Property St_sumQ : TState read  sumQ write sumQ;          // Summe aufgenommene Strahlungsmenge  [MJ]
  Property St_sumQT : TState read  sumQT write sumQT;          // Summe temperaturkorrierte aufgenommene Strahlungsmenge  [MJ]
  Property St_sumQLeaf : TState read sumQLeaf write sumQLeaf;      // Summe aufgenommene Strahlungsmenge Blätter
  Property St_sumQGen : TState read sumQGen write sumQGen;       // Summe aufgenommene Strahlungsmenge Schoten
  Property St_sumQT_TactTpot : TState read sumQT_TactTpot write sumQT_TactTpot; // Summe Trockenstress/Temperatur korrigierte aufgenommene Strahlungsmenge  [MJ]


         // Parameters

  Property Par_Tb : TPar read Tb write Tb;
  Property Par_gh : TPar read gh write gh;
  Property Par_hh : TPar read hh write hh;
  Property Par_a : TPar read a write a;
  Property Par_b : TPar read b write b;
  Property Par_c : TPar read c write c;
  Property Par_d : TPar read d write d;
  Property Par_pCnstem1h : TPar read pCnstem1h write pCnstem1h;
  Property Par_pCnstem2h : TPar read pCnstem2h write pCnstem2h;
  Property Par_pCnleaf : TPar read pCnleaf write pCnleaf;
  Property Par_pCn1leaf : TPar read pCn1leaf write pCn1leaf;
  Property Par_pCn2leaf : TPar read pCn2leaf write pCn2leaf;
  Property Par_Ct1 : TPar read Ct1 write Ct1;
  Property Par_Ct2 : TPar read Ct2 write Ct2;
  Property Par_Ct3 : TPar read Ct3 write Ct3;
  Property Par_Ct4 : TPar read Ct4 write Ct4;
  Property Par_SLAhst : TPar read SLAhst write SLAhst;
  Property Par_SLAhin : TPar read SLAhin write SLAhin;
  Property Par_SLAmin : TPar read SLAmin write SLAmin;
  Property Par_SLAmax : TPar read SLAmax write SLAmax;
  Property Par_fTminus : TPar read fTminus write fTminus;
  Property Par_SSA : TPar read SSA write SSA;
  Property Par_k1 : TPar read k1 write k1;
  Property Par_DMcrit : TPar read DMcrit write DMcrit;
  Property Par_rooti : TPar read rooti write rooti;
  Property Par_roots : TPar read roots write roots;
  Property Par_exk : TPar read exk write exk;
  Property Par_LUELeaf : TPar read LUELeaf write LUELeaf;
  Property Par_LUE0 : TPar read LUE0 write LUE0;
  Property Par_PARmh : TPar read PARmh write PARmh;
  Property Par_PARmf : TPar read PARmf write PARmf;
  Property Par_fSws : TPar read fSws write fSws;

         // Properties External Variables

  Property Ex_GRad : TExternV read GRad write GRad;
  Property Ex_TMPM : TExternV read TMPM write TMPM;
  Property Ex_EC : TExternV read EC write EC;
  Property Ex_DayofYear : TExternV read DayofYear write DayofYear;
  Property Ex_ExternLAI : TExternV read LUE_LAI  write LUE_LAI ;
  Property Ex_DMGrowth : TExternV read DMGrowth_ex  write DMGrowth_ex ;
  Property Ex_TransRatio : TExternV read TransRatio write TransRatio;
//  Property Ex_CO2pp: TExternV Read CO2pp Write CO2pp;


           // Option

  Property Opt_LAI : TOption read LAIOption write LAIOption;
  Property Opt_Init: TOption read InitOption write InitOption;
  Property Opt_Drought: TOption read DroughtOption write DroughtOption;

  Property DevelopmentModel: TDevelopmentOSR read fDevelopmentModel write setDevelopmentModel;
  Property RootModel: TGrowthCurvePlantRoots{TSimpleRootModDM} read fRootModel write fRootModel;
//  Property SoilNitrogenMod: TSoilNitrogenUp read fSoilNitrogenMod write fSoilNitrogenMod;
  Property SnowModel: TSnowPack read fSnowModel write fSnowModel;
//  Property SoilMinMod : TAbstractSoilMin read fSoilMinMod write fSoilMinMod;

end;  // SubmodelName

procedure Register;

implementation
uses Math;



function CO2_ppm_f(date:TDateTime):real;
const
  int = 45549.96;//4.554996e+04;
  lin =  -47.00505;//-4.700505e+01;
  quad = 0.01220744;//1.220744e-02;
var
  year, month, day : word;
  dat : TDateTime;
begin
  SysUtils.decodedate(date, year, month, day);
  result := int + year*lin + sqr(year)*quad;
end;


procedure TOSRGrowth.createAll;
begin
  inherited createAll;
  VarCreate('PARRad', 'W/m²',0, true, PARRad,'photosynthetisch aktive Strahlung');
  VarCreate('fT', '',0, true, fT,'Wirkungsfaktor Photosynthese');
  VarCreate('fRoot', '',0, true, fRoot,'Anteil Wurzelzuwachs');
  VarCreate('maxfRoot','',0,true,maxfRoot,'maximaler Anteil Wurzelzuwachs');
  VarCreate('fBl','',0,true,fBl,'Anteil Blattzuwachs am Sprosszuwachs');
  VarCreate('fBl_EC51','',0,true,fBl_EC51,'Anteil Blattzuwachs EC 51');
  VarCreate('fSt','',0,true,fSt,'Anteil Stängelzuwachs am Sprosszuwachs');
  VarCreate('fGen','',0,true,fGen,'Anteil Schotenzuwachs am Sprosszuwachs');
  VarCreate('fPW','',0,true,fPW,'Anteil Schotenhüllenzuwachs am Schotenzuwachs');
  VarCreate('fSeedGen','',0,true,fSeedGen,'Anteil Samenzuwachs am Schotenzuwachs');
  VarCreate('fSeedStarch','',0,true,fSeedStarch,'Berechung Stärkeanteil im Samen');
  VarCreate('fSeedOil','',0,true,fSeedOil,'Berechnung Ölanteil im Samen');
  VarCreate('fSum','',0,true,fSum,'Summe der anteiligen organspezifischen NNI');
  VarCreate('fNNILeaf','',0,true,fNNILeaf,'Zwischenschritt zur Berechnung der NNILeaf');
  VarCreate('fNNIStem','',0,true,fNNIStem,'Zwischenschritt zur Berechnung der NNIStem');
  VarCreate('fNNIGen','',0,true,fNNIGen,'Zwischenschritt zur Berechnung der NNIGen');
  VarCreate('fNNIRoot','',0,true,fNNIRoot,'Zwischenschritt zur Berechnung der NNIRoot');
  VarCreate('Q', 'MJ',0, true, Q,'aufgenommene Strahlungsmenge');
  VarCreate('QLeaf', 'MJ',0, true, QLeaf,'aufgenommene Strahlungsmenge Blätter');
  VarCreate('QGen', 'MJ',0, true, QGen,'aufgenommene Strahlungsmenge Schoten');
  VarCreate('fInt', '',0, true, fInt,'Anteil aufgenommener Strahlung');
  VarCreate('fIntLeaf', '',0, true, fIntLeaf,'Anteil aufgenommener Strahlung Blätter');
  VarCreate('fIntGen', '',0, true, fIntGen,'Anteil aufgenommener Strahlung Schoten');
  VarCreate('act_k', '',0, true, act_k,'Extinktionskoeffizient für PAR = exk bzw. variabler Wert für LAI < LAIcrit_exk');
  VarCreate('act_k_Leaf', '',0, true, act_k_Leaf,'Extinktionskoeffizient Blätter');
  VarCreate('act_k_Gen', '',0, true, act_k_Gen,'Extinktionskoeffizient Schoten');
  VarCreate('QT', 'MJ',0, true, QT,'Temperatur korrigierte aufgenommene Strahlungsmenge');
  VarCreate('Teff', '°C',0, true, Teff,'effektive Temperatur');
  VarCreate('Tminus', '°C',0, true, Tminus,'Temperatur unter Null');
  VarCreate('NcLeaf', '%',0, true, NcLeaf,'Blatt N-Konzentration');
  VarCreate('NcLeaf_VA','%',0,true,NcLeaf_VA,'Blatt N-Konzentration zu Vegetationsbeginn');
  VarCreate('NcStem', '%',0, true, NcStem,'Stängel N-Konzentration');
  VarCreate('NcStem_VA','%',0,true,NcStem_VA,'Stängel N-Konzentration zu Vegetationsbeginn');
  VarCreate('NcStem_EC70','%',0,true,NcStem_EC70,'Stängel N-Konzentration bei EC 70');
  VarCreate('NcGen','%',0,true,NcGen,'generative N-Konzentration');
  VarCreate('NcRoot', '%',0, true, NcRoot,'Wurzel N-Konzentration');
  VarCreate('NcRoot_VA', '%',0, true, NcRoot_VA,'Wurzel N-Konzentration Vegetationsanfang');
  VarCreate('NcRoot_EC70','%',0,true,NcRoot_EC70,'Wurzel N-Konzentration bei EC 70');
  VarCreate('NUptakeRate_pot', 'g m-2 d-1',0, true, NUptakeRate_pot,'potenzielle N-Aufnahmerate (g.m-2.d-1)');
  VarCreate('NNI', '-',1, true, NNI,'Nitrogen Nutrition Index');
  VarCreate('CropHeight', 'm',0, true, CropHeight,'Bestandeshöhe');
  VarCreate('LAILeaf_EC70','m²/m²',0,true,LAILeaf_EC70, 'LAI zu EC 70');
  VarCreate('actSLA', 'cm²/g', 0 ,true, actSLA,'Spezifische Blattfläche');
  VarCreate('SLA', 'cm²/g', 0 ,true, avSLA,'Spezifische Blattfläche');
  VarCreate('actSPA','cm²/g',0,true,actSPA,'Spezifische Schotenfläche');
  VarCreate('SPA','cm²/g',0,true,avSPA,'Spezifische Schotenfläche');
  VarCreate('LUE', 'g/MJ', 0 ,true, LUE,'Lichtnutzungseffizienz');
  VarCreate('LUEGen','g/MJ',0,true,LUEGen,'Lichtnutzungseffizienz Schoten');
  VarCreate('g', '', 0 ,true, g,'Steigung der allometrischen Funktion');
  VarCreate('h', '', 0 ,true, h,'Interzept der allometrischen Funktion');
  VarCreate('LAIm', 'm²/m²',0, true,LAIm,'Maximaler LAI bei vorhandener Strahlungsmenge');
  VarCreate('fTm', '',0, true, fTm,'Temperaturfaktor Erhaltungsatmung zur Berechnung von PARm');
  VarCreate('fTSen','',0,true,fTSen,'Temperaturfaktor bei der Seneszenzberechnung');
  VarCreate('fSen_sh', '',0, true, fSen_sh,'Seneszenzfaktor Beschattung / Erhaltungsatmung');
  VarCreate('Auflauf', 'd',0, true,Auflauf,'Zeitpunkt des Auflaufens');
  VarCreate('DummyVar', '',0, true, DummyVar);
  VarCreate('EC_act','',0,true,EC_act,'EC-Wert bei LAIShoot = 2.0');
  VarCreate('Transkoeff','',0,true,Transkoeff,'Transmissionskoeffizient Schotenentwicklung');
  VarCreate('maxGAI','m²/m²',0,true,maxGAI,'max. GAI');
  VarCreate('maxLAIGen','m²/m²',0,true,maxLAIGen,'max. PAI');
  VarCreate('maxLAIStem','m²/m²',0,true,maxLAIStem,'max. SAI');
  VarCreate('dNcLeaf','',0,true,dNcLeaf,'Änderung NcLeaf');
  VarCreate('dNcStem','',0,true,dNcStem,'Änderung NcStem');
  VarCreate('dNcRoot','',0,true,dNcRoot,'Änderung NcRoot');
  VarCreate('dNcGen','',0,true,dNcGen,'Änderung NcGen');
  VarCreate('NcritLeaf','%',0,true,NcritLeaf,'kritische N-Konz Blätter');
  VarCreate('NcLeaf_act','%',0,true,NcLeaf_act,'aktuelle N-Konzentration der Blätter');
  VarCreate('NcStem_act','%',0,true,NcStem_act,'aktuelle N-Konzentration der Stängel');
  VarCreate('NcGen_act','%',0,true,NcGen_act,'aktuelle N-Konzentration der Schoten');
  VarCreate('NcRoot_act','%',0,true,NcRoot_act,'aktuelle N-Konzentration der Wurzeln');
  VarCreate('NcritStem','%',0,true,NcritStem,'kritische N-Konz Stängel');
  VarCreate('NcritGen','%',0,true,NcritGen,'kritische N-Konz Schoten');
  VarCreate('NcritRoot','%',0,true,NcritRoot,'kritische N-Konz Wurzeln');
  VarCreate('NcritRoot_VA','%',0,true,NcritRoot_VA,'kritische N-Konz Wurzeln Vegetationsanfang');
  VarCreate('NcritLeaf_VA','%',0,true,NcritLeaf_VA,'kritische N-Konz Blätter VA');
  VarCreate('NcritStem_VA','%',0,true,NcritStem_VA,'kritische N-Konz Stängel VA');
  VarCreate('NcritStem_EC70','%',0,true,NcritStem_EC70,'kritische N-Konz Stängel EC70');
  VarCreate('NcritRoot_EC70','%',0,true,NcritRoot_EC70,'kritische N-Konz Wurzeln EC70');
  VarCreate('NNILeaf','-',1,true,NNILeaf,'NNI der Blätter');
  VarCreate('NNIStem','-',1,true,NNIStem,'NNI der Stängel');
  VarCreate('NNIGen','-',1,true,NNIGen,'NNI der Schoten');
  VarCreate('NNIRoot','-',1,true,NNIRoot,'NNI der Wurzeln');
  VarCreate('PAI','',0,true,PAI,'Schotenflächenindex');
  VarCreate('SAI','',0,true,SAI,'Stängelflächeniindex');
  VarCreate('SLAf','cm²/g',0,true,SLAf,'SLA im Frühjahr');
  VarCreate('NDemandGrowth','g/m²',0,true,NDemandGrowth,'N-Bedarf für aktuelles Wachstum');
  VarCreate('NDemandDeficit','g/m²',0,true,NDemandDeficit,'N-Bedarf zum Auffüllen von bestehendem N-Mangel');
  VarCreate('NDemandDeficitLeaf','g/m²',0,true,NDemandDeficitLeaf,'N-Bedarf zum Auffüllen von bestehendem N-Mangel in den Blättern');
  VarCreate('NDemandDeficitStem','g/m²',0,true,NDemandDeficitStem,'N-Bedarf zum Auffüllen von bestehendem N-Mangel in den Stängeln');
  VarCreate('NDemandDeficitRoot','g/m²',0,true,NDemandDeficitRoot,'N-Bedarf zum Auffüllen von bestehendem N-Mangel in den Wurzeln');
  VarCreate('NDemandDeficitGen','g/m²',0,true,NDemandDeficitGen,'N-Bedarf zum Auffüllen von bestehendem N-Mangel in den Schoten');
  VarCreate('NSupply','g/m²',0,true,NSupply,'verfügbare N-Menge');

  VarCreate('TKM','g',0,true,TKM,'Tausend-Korn-Masse');
  VarCreate('Samenanzahl','m-2',0,true,Samenanzahl,'Anzahl Samen pro m²');
  VarCreate('HI','',0,true,HI,'Harvest-Index');
  VarCreate('NHI','',0,true,NHI,'Nitrogen Harvest Index');
  VarCreate('NUE','',0,true,NUE,'Nitrogen Use Efficiency');

  VarCreate('KonversionVerlust','',0,true,KonversionVerlust,'Konversionsverlust durch Bildung von Öl statt Stärke');

  VarCreate('avs','',0,true,avs,'Day of Year des Vegetationsbeginns (aus Temperaturwerten ermittelt)');
  VarCreate('Parav','[-]', 0.0, false, Parav,'mittlere Einstrahlung von PAR über 5 Tage für den Grenzwert zur Berechnung der Erhaltungsatmung');
  VarCreate('fW','',1,true,fW,'Faktor für den Einfluss von Trockenstress (Ferreya 2013)');

  VarCreate('N_Def','',0,true,N_Def,'N-Defizitfaktor (Verhältnis von N-Bedarf und N-Aufnahme)');
  VarCreate('CO2_factor', '[-]',1, true,  CO2_factor);

  StateCreate('DMShoot', 'g/m²',0.1, true,DMShoot,'Sprosstrockenmasse');
  StateCreate('DMShoot_OF','g/m²',0,true,DMShoot_OF,'Sprosstrockenmasse zum Onset of Flowering');
  StateCreate('DMShoot_nB','g/m²',0,true,DMShoot_nB,'Sprosstrockenmasse nach der Blüte');
  StateCreate('DMShoot_nB_pot','g/m²',0,true, DMShoot_nB_pot,'potentielle Sprosstrockenmasse nach der Blüte');
  StateCreate('DMShoot_vW','g/m²',0.1,true,DMShoot_vW,'Sprosstrockenmasse vor Winter');
  StateCreate('DMLeaf', 'g/m²',0, true,DMLeaf,'Blatttrockenmasse');
  StateCreate('DMStem', 'g/m²',0, true,DMStem,'Stängeltrockenmasse');
  StateCreate('DMRoot', 'g/m²',0, true,DMRoot,'Wurzeltrockenmasse');
  StateCreate('DMGen', 'g/m²',0,true,DMGen,'generative Trockenmasse');
  StateCreate('DMPodWall','g/m²',0,true,DMPodWall,'Schotenhüllentrockenmasse');
  StateCreate('DMSeed','g/m²',0,true,DMSeed,'Samentrockenmasse');
  StateCreate('DMSeedStarch','g/m²',0,true,DMSeedStarch,'Trockenmasse des Stärkeanteils im Samen');
  StateCreate('DMSeedOil','g/m²',0,true,DMSeedOil,'Trockenmasse des Ölanteils im Samen');
  StateCreate('DMPlant', 'g/m²',0, true,DMPlant,'Gesamtpflanzentrockenmasse');
  StateCreate('LAIShoot', 'm²/m²',0, true,LAIShoot,'Sprossfläche');
  StateCreate('LAILeaf', 'm²/m²',0, true,LAILeaf,'Blattfläche');
  StateCreate('LAIStem', 'm²/m²',0, true,LAIStem,'Stängelfläche');
  StateCreate('NShoot', 'g/m²',0, true,NShoot,'Spross-N-Menge');
  StateCreate('NLeaf', 'g/m²',0, true,NLeaf,'Blatt-N-Menge');
  StateCreate('strNStem', 'g/m²',0, true,strNStem,'strukturelle Stängel-N-Menge');
  StateCreate('poolNStem', 'g/m²',0, true,poolNStem,'Stängel-N-Menge (Pool)');
  StateCreate('NStem', 'g/m²',0, true,NStem,'Stängel-N-Menge');
  StateCreate('NGen','g/m²',0,true,NGen,'generative N-Menge');
  StateCreate('strNRoot', 'g/m²',0, true,strNRoot,'strukturelle Wurzel-N-Menge');
  StateCreate('poolNRoot', 'g/m²',0, true,poolNRoot,'Wurzel-N-Menge (Pool)');
  StateCreate('NRoot', 'g/m²',0, true,NRoot,'Wurzel-N-Menge');
  StateCreate('NDead', 'g/m²',0, true,NDead,'N-Menge in abgestorbenen Blättern [g/m²]');
  StateCreate('NPlant', 'g/m²',0, true,NPlant,'N-Menge in Gesamtpflanze [g/m²]');
  StateCreate('NSeed','g/m²',0,true,NSeed,'N-Menge im Samen [g/m²]');
  StateCreate('NPodWall','g/m²',0,true,NPodWall,'N-Menge in Schotenwänden [g/m²]');
  StateCreate('NDeadW','g/m²',0,true,NDeadW,'durch Frostseneszenz verlorene N-Menge');
  StateCreate('NDeadSh','g/m²',0,true,NDeadSh,'durch Beschattungsseneszenz verlorene N-Menge');
  StateCreate('NTransLeaf','g/m²',0,true,NTransLeaf,'translozierbare N-Menge aus den Blättern');
  StateCreate('NTransStem','g/m²',0,true,NTransStem,'translozierbare N-Menge aus den Stängeln');
  StateCreate('NTransGen','g/m²',0,true,NTransGen,'translozierbare N-Menge aus den Schoten');
  StateCreate('NTransRoot','g/m²',0,true,NTransRoot,'translozierbare N-Menge aus den Wurzeln');
  StateCreate('NTrans','g/m²',0,true,NTrans,'translozierbare Gesamt-N-Menge');
  StateCreate('potNTrans','g/m²',0,true,potNTrans,'potentiell translozierbare N-Menge');
  StateCreate('potNPool','g/m²',0,true,potNPool,'potentielle N-Menge im Pool');
  StateCreate('NUptake_pot', 'g/m²',0, true,NUptake_pot,'potenziell aufgenommene N-Menge [g/m²]');
  StateCreate('NUptake_act', 'g/m²',0, true,NUptake_act,'aktuell aufgenommene N-Menge [g/m²]');
  StateCreate('TempSum', '[°Cd]',0, true,TempSum,'Temperatursumme');
  StateCreate('TempSumAussaat', '[°Cd]',0, true,TempSumAussaat,'Temperatursumme ab Aussaat');
  StateCreate('TempSumMinus', '[°Cd]',0, true,TempSumMinus,'Temperatursumme');
  StateCreate('TempSumAuflauf','[°Cd]',0,true,TempSumAuflauf,'Temperatursumme ab Auflauf (Tb = 0°C)');
  StateCreate('TempSumPodGrowth','[°Cd]',0,true,TempSumPodGrowth,'Temperatursumme ab EC70');
  StateCreate('TempSumSeed','[°Cd]',0,true,TempSumSeed,'Temperatursumme während der Samenreifung');
  StateCreate('TempSumLeafLoss','[°Cd]',0,true,TempSumLeafLoss,'Temperatursumme ab EC51 zur Berechnung der Abnahme des Blattanteils am Gesamtpflanzenwachstum');
  StateCreate('TempSumRoots','[°Cd]',0,true,TempSumRoots,'Temperatursumme zwischen DoY 30 und DoY 150 zur Berechnung von fRoot');
  StateCreate('LAIs', 'm²/m²',0, true,LAIs,'Schatten induzierte Seneszenzfläche');
  StateCreate('DMdead', 'g/m²',0, true, DMdead,'seneszente Trockenmasse');
  StateCreate('DMDeadW', 'g/m²',0, true, DMDeadW,'durch Frostseneszenz abgestorbene Trockenmasse');
  StateCreate('DMDeadLeafW', 'g/m²',0, true, DMDeadLeafW,'durch Frostseneszenz abgestorbene Blatttrockenmasse');
  StateCreate('DMDeadStemW', 'g/m²',0, true, DMDeadStemW,'durch Frostseneszenz abgestorbene Stängeltrockenmasse');
  StateCreate('DMDeadRootW','g/m²',0,true,DMDeadRootW,'über Winter abgestorbene Wurzeltrockenmasse');
  StateCreate('DMDeadSh', 'g/m²',0, true, DMDeadSh,'durch Beschattungs-Seneszenz abgestorbene Blatttrockenmasse');
  StateCreate('DMDeadN', 'g/m²', 0, true, DMDeadN,'durch N-Mangel abgestorbene Blatttrockenmasse');
  StateCreate('DM_N','g/m²',0,true,DM_N,'ehemalige lebendige (grüne) Trockenmasse, der durch N-Mangel abgestorbenen Blätter');
  StateCreate('DMNTrans','g/m²',0,true,DMNTrans,'translozierte Blatttrockenmasse aus N-Mangel');
  StateCreate('DMSh','g/m²',0,true,DMSh,'potentiell durch Beschattungs-Seneszenz aus den Blättern abgestorbene und translozierte Trockenmasse');
  StateCreate('DMShTrans','g/m²',0,true,DMShTrans,'durch Beschattungs-Seneszenz translozierte Blattrockenmasse zu den Schoten');
  StateCreate('DMTransStem','g/m²',0,true,DMTransStem,'translozierte Stängel-Trockenmasse');
  StateCreate('DMTransLeaf','g/m²',0,true,DMTransLeaf,'translozierte Blatt-Trockenmasse');
  StateCreate('DMTrans','g/m²',0,true,DMTrans,'translozierte Trockenmasse');
  StateCreate('LAIGen','m²/m²',0,true,LAIGen,'PodAreaIndex');
  StateCreate('C_Dead','kg/ha',0,true,C_Dead,'C-Menge der abgeworfenen Blätter');
  StateCreate('N_Dead','kg/ha',0,true,N_Dead,'N-Menge der abgeworfenen Blätter');

  StateCreate('Yield','dt/ha',0,true,Yield,'Samenertrag');
  StateCreate('OilYield','dt/ha',0,true,OilYield,'Ölertrag');
  StateCreate('Oilconc','%',0,true,Oilconc,'Ölkonzentration');
  StateCreate('Protein','%',0,true,Protein,'Proteingehalt');
  StateCreate('Ymax','dt/ha',0,true,Ymax,'max Ertrag');

  StateCreate('NPool','g/m²',0,true,NPool,'N-Pool in Stängel und Wurzeln für die aus den Blättern translozierte N-Menge bevor die generativen Organe als Senken zur Verügung stehen');

  StateCreate('DMDeadAge', 'g/m²',0, true,DMDeadAge,'Altersseneszenz nach EC80');
  StateCreate('NDeadAge', 'g/m²',0, true,NDeadAge,'Altersseneszenz nach EC80');

  StateCreate('FullFlower','',0,true,FullFlower,'Datum EC65');
  StateCreate('SumKonversionVerlust','',0,true,SumKonversionVerlust,'Summe Konversionsverlust bei Ölbildung');
  StateCreate('sumQ', '[MJ/m2]',0,true,sumQ,'Summe aufgenommene Strahlungsmenge  [MJ]');          // Summe aufgenommene Strahlungsmenge  [MJ]
  StateCreate('sumQT', '[MJ/m2]',0,true,sumQT,'Summe temperaturkorrigierte aufgenommene Strahlungsmenge  [MJ]');          // Summe temperaturkorrigierte aufgenommene Strahlungsmenge  [MJ]
  StateCreate('sumQLeaf', '[MJ/m2]',0,true, sumQLeaf,'Summe aufgenommene Strahlungsmenge Blätter');      // Summe aufgenommene Strahlungsmenge Blätter
  StateCreate('sumQGen', '[MJ/m2]',0,true, sumQgen,'Summe aufgenommene Strahlungsmenge Schoten');       // Summe aufgenommene Strahlungsmenge Schoten
  StateCreate('RadSum','[MJ/m²]',0,true, RadSum,'Strahlungssumme');

  StateCreate('sumQT_TactTpot', '[MJ/m2]',0,true, sumQT_TactTpot,
    'Summe Trockenstress/Temperatur korrigierte aufgenommene Strahlungsmenge  [MJ]');

  StateCreate('NBalance','[g/m²]',0,true,NBalance);
  StateCreate('NUptake_vW','',0,true,NUptake_vW,'N-Aufnahme vor Winter');
  StateCreate('NUptake_aF','',0,true,NUptake_aF,'N-Aufnahme nach der Blüte');



    // Parameters
  ParCreate('pfW', '[-]', 1, pfW,
    'parameter for none linear relation between Tansratio and SWDF (Ferreyra 2003)');
  ParCreate('Tb', '°C', 3 , Tb,'Basistemperatur');
  ParCreate('gh', '', 1.2539 , gh,'Steigungsparameter Allometrie im Herbst');
  ParCreate('hh', '', -1.9765 , hh,'Interzeptparameter Allometrie im Herbst');
  ParCreate('gf','',3.56389,gf,'Steigungsparameter Allometrie im Frühjahr');
  ParCreate('hf','',-9.92018,hf,'Interzeptparameter Allometrie im Frühjahr');
  ParCreate('a','',2.7226,a,'Parameter zur DM-Fraktionierung nach EC51');
  ParCreate('b','',-4.9899,b,'Parameter zur DM-Fraktionierung nach EC51');
  ParCreate('c','',4E-12,c,'Parameter zur DM-Fraktionierung nach EC51');
  ParCreate('d','',-0.561,d,'Parameter zur DM-Fraktionierung nach EC51');
  ParCreate('e','',70,e,'Parameter zur DM-Fraktionierung nach EC51');
  ParCreate('root_exp','',-0.05,root_exp,'Parameter für Exponentialfunktion von DMRoot');
  ParCreate('SPA_Exp','',-0.05,SPA_exp,'Parameter für Exponentialfunktion von SPA');
  ParCreate('fPW_0','',100,fPW_0,'Parameter für Ertragsfunktion (fPW)');
  ParCreate('fPW_exp','',-0.008,fPW_exp,'Parameter für Ertragsfunktion (fPW)');
  ParCreate('pCnPod1','',8,pCnPod1,'Verdünnungsfuktion Schoten');
  ParCreate('pCnPod2','',-0.8,pCnPod2,'Verdünnungsfunktion Schoten');
  ParCreate('pCnstem1h', '', 0.0458 , pCnstem1h,'vor eulerscher Zahl Stängel-Verdünnung (Herbst)');
  ParCreate('pCnstem2h', '', -0.0021 , pCnstem2h,'vor Variablen Stängel-Verdünnung (Herbst)');
  ParCreate('pCnRoot1h', '',3.3127, pCnRoot1h,'vor eulerscher Zahl Wurzel-Verdünnung');
  ParCreate('pCnRoot2h', '',-0.11, pCnRoot2h,'vor Variablen Wurzel-Verdünnung');
  ParCreate('pCnRoot1f', '',3.9548, pCnRoot1f,'vor eulerscher Zahl Wurzel-Verdünnung');
  ParCreate('pCnRoot2f', '',-0.0059, pCnRoot2f,'vor Variablen Wurzel-Verdünnung');
  ParCreate('pCnleaf', '', 5.659 , pCnleaf,'Blatt N-Konzentration');
  ParCreate('pCn1leaf', '', 6.707 , pCn1leaf,'vor DMleaf');
  ParCreate('pCn2leaf', '', -0.01624 , pCn2leaf,'Steigung Verdünnung Blatt/Herbst');
  ParCreate('pCnDead', '%', 2 , pCnDead,'N-Konzentration abgestorbener Blätter');
  ParCreate('pCnRoot', '%', 4 , pCnRoot,'N-Konzentration Wurzeln');
  ParCreate('pCnSeed','%',3,pCnSeed,'N-Konzentration Samen');
  ParCreate('pCnTrans','',0.65,pCnTrans,'Anteil N-Menge, der aus seneszenten Blättern transloziert wird');
  ParCreate('Ct1', '°C', 3 , Ct1,'Wachstumsgrenze unten');
  ParCreate('Ct2', '°C', 10 , Ct2,'Optimumsgrenze unten');
  ParCreate('Ct3', '°C', 20 , Ct3,'Optimumsgrenze oben');
  ParCreate('Ct4', '°C', 35 , Ct4,'Wachstumsgrenze oben');
  ParCreate('SLAhst', '', -0.2759 , SLAhst,'Steigungsparameter spez Blattfläche Herbst');
  ParCreate('SLAhin', '', 396.52 , SLAhin,'Interzept spez. Blattfläche Herbst');
  ParCreate('SLAmin', 'cm²/g', 100 , SLAmin,'minimale spez. Blattfläche Herbst');
  ParCreate('SLAmax', 'cm²/g', 350 , SLAmax,'maximale spez. Blattfläche Herbst');
  ParCreate('SLAnB','cm²/g',275,SLAnB,'Spezifische Blattfläche nach der Blüte');
  ParCreate('SLADead', 'cm²/g', 500 , SLADead,'SLA seneszenter Blätter [cm²/g]');
  ParCreate('fTminus', '°C', 20 , fTminus,'Temperaturschwellenwert Seneszenz Winter');
  ParCreate('SSA', 'cm²/g', 20 , SSA,'Spezifische Stängelfläche');
  ParCreate('SPAmax','cm²/g',60,SPAmax,'Maximale spezifische Schotenfläche');
  ParCreate('k1', '', 0.02 , k1,'Wachstumsrate EC10-EC13');
  ParCreate('DMcrit', 'g/m²', 5 , DMcrit,'DM-Grenzwert des expo. Wachstums');
  ParCreate('rooti', '', 0.119184 , rooti,'Interzept der Wurzelanteilregression');
  ParCreate('roots', '', -0.000029 , roots,'Steigung der Wurzelanteilregression');
  ParCreate('exk', '', 0.8 , exk,'Extinktionskoeffizient');
  ParCreate('exk_0', '', 0.9 , exk_0,'Extinktionskoeffizient bei LAI=0 für variablen Exk.');
  ParCreate('LAIcrit_exk', 'm2/m2', 1.5 , LAIcrit_exk,'LAIcrit, bei dem Extinktionskoeffizient = exk');
  ParCreate('LUELeaf', 'g/MJ', 4 , LUELeaf,'Lichtnutzungseffizienz');
  ParCreate('LUE0', '', 3.196 , LUE0,'Interzept der LUE Gleichung VW');
  ParCreate('LUEPod','',4,LUEPod,'LUE Schoten');
  ParCreate('fCO2', '[-]',   0.086,  fCO2);
  ParCreate('fCO2_scale', '[-]',   0.723,  fCO2_scale);
  ParCreate('fCWSI', '[-]',   0.077,  fCWSI);
  ParCreate('CiCompensation', '[ppm]',   350,  CiCompensation);
  ParCreate('PARmh', 'W/m²', 0.03456 , PARmh,'notwendige Erhaltungsstrahlungsmenge Herbst');
  ParCreate('PARmf', 'W/m²', 0.03456 , PARmf,'notwendige Erhaltungsstrahlungsmenge Frühjahr');
  ParCreate('pfTm_opt', '°C', 20, pfTm_opt,'Optimaltemperatur für fTm nach Arrhenius');
  ParCreate('pfTm_Q10', '', 2, pfTm_Q10,'Q10-Wert für fTm nach Arrhenius');
  ParCreate('pSen_sh', '', 3, pSen_sh,'Anzahl Tage, über die PARm gemittelt wird');
  ParCreate('pSen_sh_w', '', 1, pSen_sh_w,'Exponent für Wirkung des Faktors fSen_sh');
  ParCreate('fSws', '',0.005, fSws,'relative Abnahmerate Seneszenz Winter');
  ParCreate('Plants', 'm-2',40, Plants,'Pflanzen pro m²');
  ParCreate('pIniLAI', 'cm2/plant', 1, pIniLAI,'LAI nach Auflaufen bei InitOption LAIInit [cm²/Pflanze]');
  ParCreate('pCncritLeaf','%',4.3,pCncritLeaf,'kritische Verdünnungsfunktion Blätter vor Schossbeginn');
  ParCreate('pCncrit1Leaf','',5.8664,pCncrit1Leaf,'kritische Verdünnungsfunktion Blätter ab Schossbeginn');
  ParCreate('pCncrit2Leaf','',-0.0187,pCncrit2Leaf,'kritische Verdünnungsfunktion Blätter ab Schossbeginn');
  ParCreate('pCncritStem1h','',3.2894,pCncritStem1h,'kritische Verdünnungsfunktion Stängel vor Schossbeginn');
  ParCreate('pCncritStem2h','',-0.013,pCncritStem2h,'kritische Verdünnungsfunktion Stängel vor Schossbeginn');
  ParCreate('pCncritPod1','',7.5238,pCncritPod1,'kritische Verdünnungsfunktion Schoten');
  ParCreate('pCncritPod2','',-0.872,pCncritPod2,'kritische Verdünnungsfunktion Schoten');
  ParCreate('pCncritRoot1h','',2.9569,pCncritRoot1h,'kritische Verdünnungsfunktion Wurzeln vor Schossbeginn');
  ParCreate('pCncritRoot2h','',-0.156,pCncritRoot2h,'kritische Verdünnungsfunktion Wurzeln vor Schossbeginn');
  ParCreate('pCncritRoot1f','',3.9241,pCncritRoot1f,'kritische Verdünnungsfunktion Wurzeln ab Schossbeginn');
  ParCreate('pCncritRoot2f','',-0.0097,pCncritRoot2f,'kritische Verdünnungsfunktion Wurzeln ab Schossbeginn');
  ParCreate('pCnStem1f','',7.7107,pCnStem1f,'Verdünnungsfunktion Stängel ab Schossbeginn');
  ParCreate('pCnStem2f','',-0.95,pCnStem2f,'Verdünnungsfunktion Stängel ab Schossbeginn');
  ParCreate('pCncritStem1f','',5.6311,pCncritStem1f,'kritische Verdünnungsfunktion Stängel ab Schossbeginn');
  ParCreate('pCncritStem2f','',-0.86,pCncritStem2f,'kritische Verdünnungsfunktion Stängel ab Schossbeginn');

  ParCreate('y1','[-]',0.37,y1,'Parameter zur Ertragsberechnung (z.Zt. äquivalent zum Harvest-Index)');
  ParCreate( 'LUEscaling', '[-]',1,LUEscaling,'for simulatanous scaling of LUEveg and LUEgen');
//  ParCreate( 'minNNI', '[-]',0.0, minNNI,'Minimum value for NNI');

  ParCreate('SLAspring','',101.97,SLAspring,'Parameter für die SLA-Berechnung nach EC30 in Abhängigkeit vom GAI');
  ParCreate('fSLAspring','',24.121,fSLAspring,'Parameter für die SLA-Berechnung nach EC30 in Abhängigkeit vom GAI');

  ParCreate('Oila','',50,Oila,'Parameter zur Berechnung der Ölkonzentration in Abhängigkeit von der Dauer der Samenreifung');
  ParCreate('Oilb','',240,Oilb,'Parameter zur Berechnung der Ölkonzentration in Abhängigkeit von der Dauer der Samenreifung');
  ParCreate('Oilc','',-0.016,Oilc,'Parameter zur Berechnung der Ölkonzentration in Abhängigkeit von der N-Menge im Samen');
  ParCreate('Oild','',-0.0226,Oild,'Parameter zur Berechnung der Ölkonzentration in Abhängigkeit von der N-Menge im Samen');

  // External Variable

  ExternVCreate('Rad_Int', 'W/m²',statefield, GRad,'Globalstrahlung');
  ExternVCreate('TMPM', '°C',statefield, TMPM,'Tagesmitteltemperatur');
  ExternVCreate('EC', '',statefield, EC,'Phänologiestadium');
  ExternVCreate('DVS', '',ratefield, DVS_rate,'Phänologiestadium');
  ExternVCreate('DVS','',statefield, DVS,'Development-Stage');
  ExternVCreate('DayofYear', '',statefield, DayofYear,'Jahrestag');
  ExternVCreate('LAI', 'm²/m²',statefield, LUE_LAI,'LAI für LUE');
  ExternVCreate('DM', 'g.m-2.d-1',ratefield, DMGrowth_ex,'DMShoot-Zuwachs für Option ExternDM');
  ExternVCreate('TransRatio','',statefield,TransRatio,'Verhältnis zwischen potentieller und aktueller Transpiration');
  ExternVCreate('TransIntRatio','',statefield,TransIntRatio,'Verhältnis zwischen potentieller und aktueller Transpiration (berücksichtigt Interzeption)');
//  ExternVCreate('CO2pp','[ppm]',statefield, CO2pp, 'external atmospheric CO2-concentration');

//  ExternVCreate('TMeanEC71_79','°C',statefield,TMeanEC71_79,'durchschnittliche Tagesmitteltemperatur zwischen EC71 und EC79');
//  ExternVCreate('DauerEC71_79','d',statefield,DauerEC71_79,'Anzahl Tage von EC71 bis EC79');
//  ExternVCreate('DauerEC81_89','d',statefield,DauerEC81_89,'Anzahl Tage von EC81 bis EC89');
  StateCreate('DauerEC81_89', '',0, true, DauerEC81_89);

  // Options

  OptCreate ('LAIOption', 'InternLAI', LAIOption,'intern berechneter LAI oder externe Variable');
  LAIOption.Optionlist.Clear;
  LAIOption.Optionlist.add('InternLAI');
  LAIOption.Optionlist.add('ExternLAI');
  fLAIOption := InternLAI;

  OptCreate ('DMGrowthOption', 'InternDM', DMGrowthOption, 'intern berechneter DM-Zuwachs oder externe Variable');
  DMGrowthOption.Optionlist.Clear;
  DMGrowthOption.Optionlist.add('InternDM');
  DMGrowthOption.Optionlist.add('ExternDM');
  fDMGrowthOption := InternDM;

  OptCreate('InitOption', 'DMCrit', InitOption, 'Initialisierung des Modells über DM (exponentiell) oder Anfangs-LAI');
  InitOption.Optionlist.Clear;
  InitOption.Optionlist.add('DMCrit');
  InitOption.Optionlist.add('LAIInit');
  fInitOption := DMCritInit;



  OptCreate ('NSensOption', 'N_sensitiv', NSensOption, 'Wirkung von N-Mangel auf TM-Zuwachs');
  NSensOption.Optionlist.Clear;
  NSensOption.Optionlist.add('N_sensitiv');
  NSensOption.Optionlist.add('N_unlimited');
  fNSensOption := N_sensitiv;

  OptCreate ('DroughtOption', 'DroughtImpact', DroughtOption, 'Wirkung von Trockenstress auf TM-Zuwachs');
  DroughtOption.Optionlist.Clear;
  DroughtOption.Optionlist.add('DroughtImpact');
  DroughtOption.Optionlist.add('NoDroughtImpact');
  fDroughtOption := DroughtImpact;

  OptCreate('optCO2', 'NoCO2Effect', OptWithCO2);
  OptWithCO2.OptionList.Clear;
  OptWithCO2.OptionList.Add('NoCO2Effect');
  OptWithCO2.OptionList.Add('WithCO2Effect');


end;


procedure TOSRGrowth.init(var GlobMod: TMod);

var
  i : Integer;

begin
  inherited init(GlobMod);
  // Initialisierungswerte, damit nicht durch 0 geteilt wird
  if DMShoot.v <=0 then DMShoot.v := 0.1;
  if DMPlant.v =0 then DMPlant.v := 0.1;
  if DMShoot_vW.v = 0 then DMShoot_vW.v := 0.1;


  if uppercase(LAIOption.Option) = uppercase('InternLAI') then fLAIOption := InternLAI;
  if uppercase(LAIOption.Option) = uppercase('ExternLAI') then fLAIOption := ExternLAI;
  LUE_LAI.search := (fLAIOption = ExternLAI);

  if uppercase(DMGrowthOption.Option) = uppercase('InternDM') then fDMGrowthOption := InternDM;
  if uppercase(DMGrowthOption.Option) = uppercase('ExternDM') then fDMGrowthOption := ExternDM;
  DMGrowth_ex.Search := (fDMGrowthOption = ExternDM);

  if uppercase(InitOption.Option) = uppercase('DMCrit') then fInitOption := DMCritInit;
  if uppercase(InitOption.Option) = uppercase('LAIInit') then fInitOption := LAIInit;

  if uppercase(NSensOption.Option) = uppercase('N_sensitiv') then fNSensOption := N_sensitiv;
  if uppercase(NSensOption.Option) = uppercase('N_unlimited') then fNSensOption := N_unlimited;

  if uppercase(DroughtOption.Option) = uppercase('DroughtImpact') then fDroughtOption := DroughtImpact;
  if uppercase(DroughtOption.Option) = uppercase('NoDroughtImpact') then fDroughtOption := NoDroughtImpact;

  Auflauf.v := 0;
  DateHarvestWasSet := false;
  for i := 1 to MaxParDays do
    Par_arr[i] := 5.0;
  PARav.v := 0;

  for i := 1 to MAxParDays do
    Parav.v := Parav.v+par_arr[i];
  parav.v := parav.v/MaxParDays;
  CO2_factor.v := 1.0;

 // if (OptWithCO2.option = 'withco2effect') then
 //   CO2pp.Search := true;
 // else
 //   CO2pp.Search := false;


end;


procedure TOSRGrowth.CalcRates;

var
  i,j : integer; //Zählvariable für Schattenseneszenz Schleife
  LAIm_ave, // über pSen_sh Tage gemittelter LAI, für den die Strahlung zur Erhaltung ausreicht
  CWSI,  // crop water stress index
  CO2_factor_min,
  CO2_ppm, // actual CO2 concentration [ppm]
  TT: real;
begin
  inherited;

  if (Globtime.v >= SowingDate.v) and (GlobTime.v <= HarvestDate.v) then begin


  // Berechnung effektiver Temperatur und verschiedener Temperatursummen (Tb = Basistemperatur, Tb = 3°C bei Raps)
    Teff.v := max(0,TMPM.v-Tb.v);
    TempSum.c := Teff.v;

    if Globtime.v >= SowingDate.v then
      TempSumAussaat.c := Teff.v
      else TempSumAussaat.c := 0;

    if (EC.v >= 10) then
      TempSumAuflauf.c := Teff.v
    else TempSumAuflauf.c := 0;

    if (EC.v >= 70) then
      TempSumPodGrowth.c := Teff.v
    else TempSumPodGrowth.c := 0;

    if (EC.v <= 65) then
      FullFlower.v := Globtime.v;

    if (EC.v >= 80) then
      TempSumSeed.c := Teff.v
    else
      TempSumSeed.c := 0;

    if (EC.v > 51) then
      TempSumLeafLoss.c := Teff.v
    else TempSumLeafLoss.c := 0;

    if ((DayofYear.v > 30) and (DayofYear.v < 150)) then
      TempSumRoots.c := Teff.v
    else TempSumRoots.c := 0;

    // negative Temperatursumme (Frost-Seneszenz)
    if Assigned(SnowModel) then begin
      if SnowModel.Zs.v > CropHeight.v then Tminus.v := min(0, SnowModel.Tsf.v)
      else if Cropheight.v > 0
        then Tminus.v := min(0, (SnowModel.Tsf.v*SnowModel.Zs.v + TMPM.v*(CropHeight.v-SnowModel.Zs.v))/CropHeight.v)
        else Tminus.v := 0;
    end
    else Tminus.v := min(0, TMPM.v);
    if EC.v >= 10 then TempSumMinus.c := -Tminus.v;

    // Korrekturfaktor Temperatur für die Berechnung der Trockenmasseproduktion
    if TMPM.v < Ct1.v then fT.v := 0
    else If TMPM.v <= Ct2.v then fT.v := (TMPM.v-Ct1.v)/(Ct2.v-Ct1.v)
    else if TMPM.v <= Ct3.v then fT.v := 1
    else if TMPM.v <= Ct4.v then fT.v := (Ct4.v-TMPM.V)/(Ct4.v-Ct3.v)
    else fT.v := 0;

  // Berechnung des maximalen GAI, maximalen SAI und maximalen PAI (SAI und PAI steigen bis EC 80)
    maxGAI.v := max(LAILeaf.v+LAIGen.v+LAIStem.v,maxGAI.v);

    if (EC.v < 80) then
      maxLAIGen.v := LAIGen.v;

    if (EC.v < 80) then
      maxLAIStem.v := LAIStem.v;


  // Vegetationsbeginn aus Temperaturwerten ermitteln
   if ((DayofYear.v > 30) and (DayofYear.v < 90)) and  (Teff.v > 0) then
      inc(avs_day)
   else
      avs_day := 0;

   if (avs_day = 5) and (avs.v = 0) then
     avs.v := DayofYear.v;

   if (EC.v >= 81) and (EC.v <= 89) then DauerEC81_89.c := 1 else DauerEC81_89.c := 0;


  // Berechnung der photosynthetisch aktiven Strahlung und der Einstrahlungssummer
    PARRad.v :=  GRad.v*0.5;
    RadSum.c := PARRad.v;

  // Reflektion durch das Blütendach (bis zu 30% der Einstrahlung werden durch das Blütendach reflektiert bzw. absorbiert)
    if (EC.v >= 60) and (EC.v <=70) then
      if (EC.v <=65) then
        Transkoeff.v := min(1,((0.7-1)/(65-60))*(EC.v-60)+1)
      else
        Transkoeff.v := min(1,((1-0.7)/(70-65))*(EC.v-65)+0.7)
    else
      Transkoeff.v := 1;

  // Extinktionskoeffizienten von Blättern und Schoten
    If (EC.v > 51) then
      act_k_Leaf.v := 0.8
    else
      act_k_Leaf.v := ExtCoeffPAR;  // vom LAI abhängiger Extinktionskoeffizient während der vegetativen Phase (Masterarbeit von K. Krause, 2010: Teilflächenspezifische Analyse des vegetativen Wachstums von Winterraps)

    act_k_Gen.v := 0.6;             // Andersen et al. 1996: The effects of drought and nitrogen on light interception, growth and yield of winter oilseed rape. Acta Agriculturae Scandinavica Sect. B Soil and Plant Sciences 46, 55-67

  // Auflaufen und Initialisierung LAI, DM, N
    if EC.v >= 10 then begin
      if (Auflauf.v = 0) and (LAILeaf.v = 0) then begin
        Auflauf.v := Globtime.v;
        if (fInitOption = LAIInit) then begin
          LAILeaf.v := pIniLAI.v*plants.v/10000;
          LAIShoot.v := LAILeaf.v;
          DMLeaf.v := DMShoot.v;
          DMStem.v := DMShoot.v * 0.1;
          NcLeaf.v := pCn1Leaf.v;
          NLeaf.v  := DMLeaf.v * NcLeaf.v/100;
          NcStem.v := pCnStem1h.v;
          NStem.v  := DMStem.v * NcStem.v;
          NShoot.v := NLeaf.v;
        end;
      end;

  // Berechnung von fInt (für vegetative Organe und Schoten einzeln)
  // prozentualer Anteil der aufgenommenen Strahlung von der Gesamteinstrahlung (abhängig von Extinktionskoeffizienten und Flächen-Indices)
    if fLAIOption = InternLAI then begin
      fIntLeaf.v := max (0,1-exp(-act_k_Leaf.v*LAILeaf.v));
      fIntGen.v := max(0,1-exp(-act_k_Gen.v*LAIGen.v));
    end
    else
      fInt.v := max (0, 1-exp(-act_k.v*LUE_LAI.v));

  // Trockenstressfaktor (nicht-linearer Einfluss)
  // Ferreyra 2003: Nonlinear effects of water stress on peanut photosynthesis at crop and leaf scales. Ecological Modelling 168, 57-76
    if (fDroughtOption = DroughtImpact) then
    begin
      fW.v := 1 - power((1 - TransIntRatio.v), pfW.v);
    end else begin
      fW.v := 1;
      sumQT_TactTpot.c := 0.0
    end;


 if OptWithCO2.option = 'withco2effect' then begin
      CO2_ppm := CO2_ppm_f(GlobTime.v);
      TT := (163- self.Ex_TMPM.v)/(5-0.1*Ex_TMPM.v);
      CO2_factor.v := ((CO2_ppm - TT)*(350+2*TT))/
                      ((CO2_ppm+2*TT)*(350-TT));

  end;
  // Berechnung der aufgenommenen Strahlung für einzelne Organe
      QGen.v :=  (fIntGen.v * PARRAD.v*86400/1000000);
      sumQGen.c := QGen.v;
    end;

    if (QGen.v > 0) then begin
      QLeaf.v := fIntLeaf.v * (PARRAD.v*86400/1000000-QGen.v)*Transkoeff.v
    end
    else begin
      QLeaf.v := (fIntLeaf.v * PARRAD.v*86400/1000000)*Transkoeff.v;
    end;
    sumQLeaf.c := QLeaf.v;

  // Berechnung der aufgenommenen Strahlung für den Gesamtbestand
   if PARRAD.v >0.0 then
    fInt.v := max(0,min(1,(QLeaf.v+QGen.v)/(PARRAD.v*86400/1000000)))
   else fInt.v := 0.0;

    Q.v := fInt.v * (PARRAD.v * 86400/1000000);
    sumQ.c := Q.v;
    QT.v := Q.v * fT.v;
    sumQT.c := QT.v;


  // Zwischenrechnungen
  // Spross-Trockenmasse zu Blühbeginn
    if (EC.v <= 60) then
      DMShoot_OF.c := DMShoot.c
    else
      DMShoot_OF.c := 0;

  // Spross-Trockenmasse ab Blühbeginn
    if (EC.v > 60) then begin
      DMShoot_nB.c := DMShoot.c ;
      DMShoot_nB_pot.c := DMShoot.c/fW.v;
    end
    else begin
      DMShoot_nB.c := 0;
    end;

  // N-Aufnahme bis Ende des Kalenderjahres
    if (DayofYear.v >= 217) and (DayofYear.v <= 365) then
      NUptake_vW.c := NUptake_act.c
    else
      NUptake_vW.c := 0;

  // N-Aufnahme nach der Blüte
    if (EC.v >= 70) then
      NUptake_aF.c := NUptake_act.c
    else
      NUptake_aF.c := 0;


  // LUE der vegetativen und generativen Biomasse, Reduktion ab EC 70 wegen Seneszenz, Samenentwicklung und Ölbildung
     {LUE-Parameter sind entsprechend hoch, weil sie die effektive LUE repräsentieren}

    If (DayofYear.v <= 30) or ((DayofYear.v >= 217) and (EC.v < 30)) then
      LUE.v := LUELeaf.v
    else
      if (DayofYear.v > 30) and (DayofYear.v <= 60) then
        LUE.v := ((LUE0.v - LUELeaf.v)/(60-30))*(DayofYear.v - 30) + LUELeaf.v
      else
        if (EC.v > 70) then
          LUE.v := min(LUE.v,max(0.1,((0.1-LUE0.v)/20)*(EC.v-70)+LUE0.v))
        else
          LUE.v := LUE0.v;

    // LUE der generativen Biomasse
      {Leterme 1985: Modélisation de la croissance et de la production des
       siliques chez le colza d'hiver}

    if (EC.v > 70) then
      LUEGen.v := min(LUEGen.v,max(0.1,((0.1-LUEPod.v)/20)*(EC.v-70)+LUEPod.v))
    {else
      if (EC.v > 51) and (EC.v < 61)
      LUEGen.v := min(LUEPod.v, max(0.1, ((LUEPod.v - 0.1)/10)*(EC.v-51)+0.1)) }
    else
      LUEGen.v := LUEPod.v;
   // apply scaling factor
     LUE.v := LUE.v * LUEscaling.v;
     LUEGen.v := LUEGen.v * LUEscaling.v;


  // Trockenmasseproduktion
    DMShoot.c := 0;

    if {(EC.v < 30)} (DayofYear.v < 30) then
      maxfRoot.v := fRoot.v;

    // Anteil des Wurzelwachstums am Gesamtwachstum (Dissertation W. Weymann, Chapter 4, Figure 2)
    if ((DayofYear.v < 30) or (DayofYear.v > 217)) and (EC.v < 30) then
        {fRoot.v := max(0,roots.v*TempSumAuflauf.v + rooti.v)}
        fRoot.v := max(0, rooti.v * power(TempSumAuflauf.v, 2)+roots.v*TempSumAuflauf.v)
    else
      if (EC.v <= 69) then
        fRoot.v := max(0.05, ((0.05-maxfRoot.v)/(100-0))*(TempSumRoots.v)+maxfRoot.v)
        {fRoot.v := max(0.05,maxfRoot.v*exp(root_exp.v*TempSumAuflauf.v))}
      else
        fRoot.v := 0.05;

    // Trockenmassebildung in abhängigkeit von aufgenommener Strahlungsmenge, LUE,
    // N-Mangel, Wassermangel, Temperaturfaktor und Assimilat-TRanslokation
    if fDMGrowthOption = InternDM then begin
      If (fInitOption = DMCritInit) and (DMShoot.v<DMcrit.v) and (EC.v>=10) then begin  //Anfang: exponentielles Wachstum Temperaturlimitiert, ohne Strahlung
        DMShoot.c :=   k1.v*DMShoot.v*Teff.v;
        if (DMShoot.v+DMShoot.c) > DMcrit.v then DMShoot.c := DMcrit.v - DMShoot.v;
        DMRoot.c := fRoot.v*(1+fRoot.v)*DMShoot.c;
        DMPlant.c := DMShoot.c + DMRoot.c;
      end;
      If (fInitOption = LAIInit) or (DMShoot.v+DMShoot.c >= DMcrit.v) then begin   // Ab DMcrit LUE-basiertes Wachstum
        if (fInitOption = DMCritInit) and (DMShoot.v < DMcrit.v)
        then  {Trockenmasse übersteigt am aktuellen Tag DMcrit}
          DMPlant.c := DMPlant.c + (Q.v*LUE.v*fT.v* CO2_factor.v)*(1-DMShoot.c/(k1.v*DMShoot.v*Teff.v))
        else
          if (QGen.v > 0) then begin
//            LUEGen.v := LUE.v;
            if (fDroughtOption =  DroughtImpact) then
              DMPlant.c :=  (((QLeaf.v*LUE.v* CO2_factor.v*((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))
                               +QGen.v*LUEGen.v*CO2_factor.v*NNIGen.v)*fT.v )*fW.v)+ DMTrans.c
            else
              DMPlant.c :=  (((QLeaf.v*LUE.v* CO2_factor.v*((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))
                               +QGen.v*LUEGen.v*CO2_factor.v*NNIGen.v)*fT.v ))+ DMTrans.c;
            {DMRoot.c := fRoot.v *  DMPlant.c;
            DMShoot.c :=   DMPlant.c-DMRoot.c;}
            DMShoot.c := DMPlant.c * (1-fRoot.v);
          end
          else
            if (EC.v >=10) then begin
              if (fDroughtOption = DroughtImpact) then
                DMPlant.c :=  ((QLeaf.v*LUE.v* CO2_factor.v * ((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))*fT.v)*fW.v)+ DMTrans.c
              else
                DMPlant.c :=  ((QLeaf.v*LUE.v* CO2_factor.v * ((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))*fT.v))+ DMTrans.c;
              {DMRoot.c := fRoot.v *  DMPlant.c;
              DMShoot.c :=   DMPlant.c-DMRoot.c;}
              DMShoot.c := DMPlant.c * (1-fRoot.v);
          end
          else begin
            DMPlant.c := 0;
            DMShoot.c := 0;
          end;
      end;
    end
    else begin  {ExternDM}
      DMShoot.c := DMGrowth_ex.v;
      DMRoot.c := fRoot.v *  DMShoot.c / (1-fRoot.v);
      DMPlant.c := DMShoot.c+DMRoot.c;
    end;


  // Bestandeshöhenberechnung (Dissertation W. Weymann, Chapter 4, Figure 1)
    CropHeight.v := min(1.8,0.0539*exp(0.0458* EC.v));

  //Seneszenz über Winter anhand von DMshoot
    If TempSumMinus.v >= fTminus.v
    then
      DMDeadW.c := min(DMShoot.v*TempSumMinus.c*fSws.v,DMShoot.c+DMLeaf.v)
    else
      DMDeadW.c := 0;


  // Seneszenz aufgrund von Beschattung bzw. Strahlung für Erhaltungsatmung
  { B. Gabrielle, P. Denoroy, G. Gosse, E. Justes, M.N. Andersen 1989:
    A model of leaf area development and senescence for winter oilseed rape
    Field Crops Research 57, 209–222}

    if (EC.v <= 70) then
      LAILeaf_EC70.v := LAILeaf.v;

  // über zehn Tage gemittelte Strahlungswerte
    for i := MaxParDays downto 2 do
      Par_arr[i] := Par_arr[i-1];
    Par_arr[1] := PARRad.v;
    PARav.v := 0;
    for i := 1 to MAxParDays do
      Parav.v := Parav.v+par_arr[i];
    parav.v := parav.v/MaxParDays;

   // Temperaturfunktion für Erhaltungsatmung
    fTm.v := power(pfTm_Q10.v, (TMPM.v-pfTm_opt.v)/10);

    if (TMPM.v < 10) and (fT.v < fTm.v) then
      fTSen.v := fTm.v
    else
      fTSen.v := fT.v;

  // Berechnung des erhaltbaren LAI (LAIm)
    if (EC.v < 30) then
      if (PARav.v*fTSen.v >= PARmh.v*fTm.v) then
        LAIm.v := 1/act_k_Leaf.v*log10((PARav.v*fTSen.v)/(PARmh.v*fTm.v))
      else LAIm.v := 0
    else
      if (EC.v >= 60) then
        if (PARav.v*Transkoeff.v*fTSen.v >= PARmf.v*fTm.v) then
          LAIm.v := 1/act_k_Leaf.v*log10((PARav.v*Transkoeff.v*fTSen.v)/(PARmf.v*fTm.v))
        else
          LAIm.v := 0
      else
        if (PARav.v*fTSen.v >= PARmf.v*fTm.v) then
          LAIm.v := 1/act_k_Leaf.v*log10((PARav.v*fTSen.v)/(PARmf.v*fTm.v))
        else
          LAIm.v := 0;

    for i:= 9 downto 1 do LAImarray[i+1]:= LAImarray[i];
      LAImarray[1] := LAIm.v;

    LAIm_ave := 0;

  // Berechnung des Seneszenzfaktors
    fSen_sh.v := 0;
    if LAIShoot.v>0 then for i := 1 to round(pSen_sh.v) do begin
      LAIm_ave := LAImarray[1];
      for j := 1 to i-1 do LAIm_ave := max(LAIm_ave, LAImarray[j+1]);
      fSen_sh.v := fSen_sh.v + max(0,1-LAIm_ave/LAIShoot.v)/round(pSen_sh.v);
    end;

  // Berechnung der Blatt-Seneszenz
    if (EC.v <= 70) then
      if (fT.v > 0) then begin
        LAIs.c := min(LAILeaf.v, LAIShoot.v*(Power(fSen_sh.v,pSen_sh_w.v)));
        DMDeadSh.c := LAIs.c/SLADead.v*10000{cm²/m²};
      end
      else begin
        LAIs.c := 0;
        DMDeadSh.c := 0;
      end
    else  // Alterungs-Seneszenz ab EC 70, unabhängig von der Beschattung
      LAIs.c := -((((0 - LAILeaf_EC70.v)/(90-70))*(EC.v-70)+LAILeaf_EC70.v)-LAILeaf.v);

  // Change of Dead LAI
    // SLA der seneszenten Blätter = 500 cm²/g
      DMDeadSh.c := LAIs.c/SLADead.v*10000{cm²/m²};

    if (avSLA.v > 0) and (fT.v > 0) then
      DMSh.c := LAIs.c/avSLA.v*10000  // non dead leaf mass
    else
      DMSh.c := 0;

    DMShTrans.c := DMSh.c - DMDeadSh.c;  // translozierbare DM


  // Fraktionierung der Trockenmasse
    // Allometrische Funktionen
    {Dissertation W. Weymann, 2015: Organ-specific approaches describing crop development of winter oilseed rape under optimal and N-limited conditions (Chapter 3)}
    {Weymann et al. 2016: Organ-specific approaches describing crop growth of winter oilseed rape under optimal and N-limited conditions. European Journal of Agronomy)}

    if (EC.v < 51) then
      fBl_EC51.v := fBl.v;

    {if (DayofYear.v <= 60) or ((DayofYear.v >= 217) and (EC.v <30)) then begin}
    if (EC.v < 30) then begin
      fBl.v := 1/(1+exp(hh.v)*gh.v*power(max(0, DMLeaf.v), (gh.v-1)));
      fSt.v := 1-fBl.v;
      fGen.v := 0;
    end
    else
      if (EC.v < 51) then begin
        fBl.v := 1/(1+exp(hf.v)*gf.v*power(max(0, DMLeaf.v), (gf.v-1)));
        fSt.v := 1-fBl.v;
        fGen.v := 0;
      end
      else
        if (EC.v <= 70) then begin
           {fBl.v := max(0,min(fBl.v,c.v*power(EC.v,2)+d.v*EC.v+e.v));}
           {fBl.v := max(0, min(fBl.v,((0-fBl_EC51.v)/(80-70))*(EC.v - 70) + fBl_EC51.v));}
           fBl.v := max(0, min(fBl.v, c.v * TempSumLeafLoss.v + fBl_EC51.v));
           {fSt.v := (1-fBl.v)*(min(0.95, max(0, (a.v * exp(b.v*EC.v)))));
           fGen.v := (1-fBl.v)*(1-fSt.v);}
           fSt.v := (1-fBl.v)*(1/(1+exp(a.v)*b.v*power(max(0,DMStem.v),(b.v-1))));
           fGen.v := (1-fBl.v)*(1-fSt.v);
           fSeedGen.v := max(0,min(1, 1/(1+fPW_0.v*exp((EC.v-50)*fPW_exp.v))));
           fPW.v := 1-fSeedGen.v;
        end
        else
          if (EC.v > 70) and (EC.v < 80) then begin
            {fBl.v := max(0,min(fBl.v,c.v*power(EC.v,2)+d.v*EC.v+e.v));}
            fBl.v := max(0, min(fBl.v, c.v * TempSumLeafLoss.v + fBl_EC51.v));
            {fBl.v := 0;}
            fGen.v := 1-fBl.v;
            fSt.v := 0;
            fSeedGen.v := max(0, min(1, 1/(1+fPW_0.v*exp((EC.v-50)*fPW_exp.v))));
            fPW.v := 1-fSeedGen.v;
          end
          else begin
            fBl.v := 0;
            fSt.v := 0;
            fGen.v := 1;
            fPW.v := 0;
            fSeedGen.v := 1;
          end;

    fBl.v := fBl.v * (1-fRoot.v);
    fSt.v := fSt.v * (1-fRoot.v);
    fGen.v := fGen.v * (1-fRoot.v);
    fRoot.v := fRoot.v;


  //Anpassung des NNI und Reduktion des Wachstums;
   { Reduktion hängt vom N-Mangel der Organe ab (NNIi);
     der berechnete NNI entspricht nicht dem NNI von Justes et al. 1994 oder
     Colnenne et al. 1998, sondern wird aus den Verdünnungfunktionen berechnet }
    fNNILeaf.v := fBl.v * NNILeaf.v;
    fNNIStem.v := fSt.v * NNIStem.v;
    fNNIGen.v := fGen.v * NNIGen.v;

    fSum.v := fNNILeaf.v + fNNIStem.v + fNNIGen.v;

    if (fSum.v > 0) then begin
      fNNILeaf.v := NNILeaf.v / fSum.v;
      fNNIStem.v := NNIStem.v / fSum.v;
      fNNIGen.v := NNIGen.v / fSum.v;
      fBl.v := fNNILeaf.v * fBl.v;
      fSt.v := fNNIStem.v * fSt.v;
      fGen.v := fNNIGen.v * fGen.v;
    end
    else
      fGen.v := 1;


  // Trockenmasse-Berechnung
    DMLeaf.c := fBl.v *  DMShoot.c;
    DMStem.c := fSt.v *  DMShoot.c;
    DMGen.c := fGen.v *  DMShoot.c;
    DMPodWall.c := fPW.v * DMGen.c;
    DMSeed.c := fSeedGen.v * DMGen.c;

    // Konversionsverlust wegen Ölbildung
    KonversionVerlust.v := (DMSeed.c {* (Oilconc.v/100)})*0.4;   // geändert 17.01.2019 UB
    DMSeed.c := DMSeed.c - KonversionVerlust.v;
    DMGen.c := DMGen.c - KonversionVerlust.v;
    DMShoot.c := DMShoot.c - KonversionVerlust.v;
    DMPlant.c := DMPlant.c - KonversionVerlust.v;
    DMRoot.c := fRoot.v * DMPlant.c;

    SumKonversionVerlust.c := KonversionVerlust.v;

  // Trockenmassereduktion wegen Frost- und Beschattungsseneszenz
    if (DMDeadSh.c>0) then begin
      DMPlant.c := DMPlant.c - DMSh.c;
      DMShoot.c := DMShoot.c - DMSh.c;
      DMLeaf.c := max(-DMLeaf.v, DMLeaf.c - DMSh.c);
    end;

    if (DMDeadW.c>0) then begin
      {DMPlant.c := DMPlant.c - DMDeadW.c;
      DMShoot.c := DMShoot.c - ((DMDeadW.c)*(DMShoot.v/DMPlant.v));
      DMLeaf.c := DMLeaf.c - ((DMDeadW.c)*(DMLeaf.v/DMPlant.v));
      DMStem.c := DMStem.c - ((DMDeadW.c)*(DMStem.v/DMPlant.v));
      DMRoot.c := DMRoot.c - ((DMDeadW.c)*(DMRoot.v/DMPlant.v));}
      DMPlant.c := DMPlant.c - DMDeadW.c;
      DMShoot.c := DMShoot.c - DMDeadW.c;
      DMLeaf.c := DMLeaf.c - ((DMDeadW.c)*(DMLeaf.v/DMShoot.v));
      DMStem.c := DMStem.c - ((DMDeadW.c)*(DMStem.v/DMShoot.v));
    end;

    {if (DMDeadN.c > 0) then begin
      DMPlant.c := DMPlant.c - DM_N.c;
      DMShoot.c := DMShoot.c - DM_N.c;
      DMLeaf.c := max(-DMLeaf.v, DMLeaf.c - DM_N.c);
    end;}

    if (DMDeadW.c > 0) then begin
      DMDeadLeafW.c := ((DMDeadW.c)*(DMLeaf.v/DMShoot.v));
      DMDeadStemW.c := ((DMDeadW.c)*(DMStem.v/DMShoot.v));
      end
    else begin
      DMDeadLeafW.c := 0;
      DMDeadStemW.c := 0;
    end;

  // DM-Translokation auf Grund von Seneszenz durch Beschattung
    if (DMDeadSh.c > 0) then
      DMTransLeaf.c := DMShTrans.c {+ DMNTrans.c}
    else
      DMTransLeaf.c := 0;

    DMTrans.c := DMTransLeaf.c + DMTransStem.c;


    DMDead.c := DMDeadW.c + DMDeadSh.c; {+ DMDeadAge.c + DMDeadN.c} // abgestorbene Trockenmasse
    C_Dead.c := (DMDead.c * 10) * 0.45;


  // Ölkonzentration (in Abhängigkeit der Dauer der Samenreifung und der N-Menge der Samen)
    if (NSeed.v > 0) then
      Oilconc.v := (Oila.v * DauerEC81_89.v + Oilb.v) * (Oilc.v * NSeed.v + Oild.v)
    else
      Oilconc.v := 0;


  // Ertragsberechnung (mit Harvest-Index; y1.v)
{    if (EC.v >= 88) then begin
      Yield.v := (DMShoot.v / 10) * y1.v;
      Ymax.v := (DMShoot.v / 10) * y1.v;
    end
    else begin
      Yield.v := 0;
      Ymax.v := 0;
    end;}

    if (Globtime.v <= Harvestdate.v) then begin
      if DMShoot_nB_pot.v > 0 then begin
        HI.v := y1.v * (1-0.8*(1-DMShoot_nB.v/DMShoot_nB_pot.v));
        Ymax.v := (DMShoot.v / 10) *  HI.v ;
        end else begin
          HI.v := 0.0;
          Ymax.v := 0.0;
        end;
      Yield.v := DMSeed.v / 10;
 //     OilYield.v := Yield.v * Oilconc.v/100;
      OilYield.v := Ymax.v * Oilconc.v/100;
    end
    else begin
      Yield.v := 0;
      OilYield.v := 0;
    end;


  // N-Konzentration (Nc = optimum N concentration, Ncrit = critical N concentration; Dissertation W. Weymann, Chapter 4, Figure 4)
  {Dissertation W. Weymann, 2015: Organ-specific approaches describing crop development of winter oilseed rape under optimal and N-limited conditions (Chapter 3)}
  {Weymann et al. 2016: Organ-specific approaches describing crop growth of winter oilseed rape under optimal and N-limited conditions. European Journal of Agronomy)}

    // Blätter
    if DayofYear.v <= 30 then begin
      NcLeaf_VA.v := NcLeaf.v;
      NcritLeaf_VA.v := NcritLeaf.v;
    end;

    If DMLeaf.v <= 0 then begin
      NcLeaf.v := 0;
      NcritLeaf.v := 0;
    end
    else begin
      If (DayofYear.v <=221) and (DayofYear.v >=60) then begin
        if EC.v < 60 then  begin               // Frühjahr: konstante N-Konz. Blätter
          NcLeaf.v := pCnleaf.v;
          NcritLeaf.v := pCncritLeaf.v;
          dNcLeaf.v := 0;
        end
        else  begin   // after BBCH 60
          NcLeaf.v := min(NcLeaf.v, max(0,((0 - pCnLeaf.v)/(90-60))*(EC.v-60)+pCnLeaf.v));
          NcritLeaf.v := min(NcritLeaf.v, max(0,((0 - pCncritLeaf.v)/(90-60))*(EC.v-60)+pCncritLeaf.v));
          dNcLeaf.v := min(NcLeaf.v, max(0,(((0 - pCnLeaf.v)/(90-60))*((DayofYear.v + 1) - 60) + pCnLeaf.v)))-NcLeaf.v;
        end
      end
      else
        if (DayofYear.v >= 30) and (DayofYear.v <= 60) then begin
          NcLeaf.v := ((pCnLeaf.v - NcLeaf_VA.v)/(60-30))*(DayofYear.v - 30) + NcLeaf_VA.v;
          NcritLeaf.v := ((pCncritLeaf.v - NcritLeaf_VA.v)/(60-30))*(DayofYear.v - 30)+NcritLeaf_VA.v;
          dNcLeaf.v := (((pCnLeaf.v - NcLeaf_VA.v)/(60-30))*((DayofYear.v + 1) - 30) + NcLeaf_VA.v)-NcLeaf.v;
        end
        else
            if (NcLeaf.v <= 0) then begin
              NcLeaf.v := min(7,max(0,pCn2leaf.v*DMleaf.v+pCn1leaf.v+DMLeaf.v*pCn2leaf.v));      // Herbst: Verdünnungsfunktion
              NcritLeaf.v := min(7,max(0,pCncrit2Leaf.v*DMLeaf.v+pCncrit1Leaf.v+DMLeaf.v*pCncrit2Leaf.v));
              dNcLeaf.v := min(7,max(0,pCn2leaf.v*(DMleaf.v+DMLeaf.c)+pCn1leaf.v+(DMLeaf.v+DMLeaf.c)*pCn2leaf.v)-NcLeaf.v);
            end
            else begin
              NcLeaf.v := min(NcLeaf.v,max(0,pCn2leaf.v*DMleaf.v+pCn1leaf.v+DMLeaf.v*pCn2leaf.v));      // Herbst: Verdünnungsfunktion
              NcritLeaf.v := min(NcritLeaf.v,max(0,pCncrit2Leaf.v*DMLeaf.v+pCncrit1Leaf.v+DMLeaf.v*pCncrit2Leaf.v));
              dNcLeaf.v := min(NcLeaf.v,max(0,pCn2Leaf.v*(DMleaf.v+DMLeaf.c)+pCn1leaf.v+(DMLeaf.v+DMLeaf.c)*pCn2leaf.v))-NcLeaf.v;
            end
    end;

    // Stängel
    if DayofYear.v <= 30 then begin
      NcStem_VA.v := NcStem.v;
      NcritStem_VA.v := NcritStem.v;
    end;

    if EC.v <= 70 then begin
      NcStem_EC70.v := NcStem.v;
      NcritStem_EC70.v := NcritStem.v;
    end;


    if (DMStem.v > 0) then begin
      if EC.v > 70 then begin
        NcStem.v := max(0.6,((0.6-NcStem_EC70.v)/(90-70))*(EC.v-70)+NcStem_EC70.v);
        NcritStem.v := max(0.6,((0.6-NcritStem_EC70.v)/(90-70))*(EC.v-70)+NcritStem_EC70.v);
        dNcStem.v := max(0.6,(((0.6-NcStem_EC70.v)/(90-70))*(EC.v+DVS_rate.v*19-70)+NcStem_EC70.v))-NcStem.v;
      end
      else begin
        if (DayofYear.v >= 30) and (DayofYear.v <= 60) then begin
          NcStem.v := ((((pCnStem2f.v * ln(DMStem.v) + pCnStem1f.v)))-NcStem_VA.v)/(60-30)*(DayofYear.v - 30) + NcStem_VA.v;
          NcritStem.v := ((((pCncritStem2f.v * ln(DMStem.v) + pCncritStem1f.v)))-NcritStem_VA.v)/(60-30)*(DayofYear.v - 30) + NcritStem_VA.v;
          dNcStem.v := (((((pCnStem2f.v * ln(DMStem.v) + pCnStem1f.v))) - NcStem_VA.v)/(60-30)*((DayofYear.v + 1) - 30) + NcStem_VA.v) -NcStem.v;
        end
        else begin
          if (DayofYear.v <= 30) or ((DayofYear.v >= 217) and (EC.v < 30)) then begin
            NcritStem.v := min(pCncritStem1h.v, pCncritStem2h.v * ln(max(0.5, DMStem.v)) + pCncritStem1h.v);
            NcStem.v := max(0.5,max(NcritStem.v, pCnStem2h.v * ln(max(0.5, DMStem.v)) + pCnStem1h.v));
            dNcStem.v := max(0.5,min(pCncritStem1h.v,(pCnStem2h.v * ln(DMStem.v+DMStem.c) + pCnStem1h.v))-NcStem.v);
          end
          else begin
            NcStem.v := max(0.6,pCnStem2f.v * ln(DMStem.v) + pCnStem1f.v);
            NcritStem.v := max(0.6,pCncritStem2f.v * ln(DMStem.v) + pCncritStem1f.v);
            dNcStem.v := max(0.6,(pCnStem2f.v * ln(DMStem.v+DMStem.c) + pCnStem1f.v))-NcStem.v;
          end
        end;
      end;
    end
    else
      if (DMStem.c > 0) then begin
        NcStem.v := min(6,pCnStem1h.v);
        NcritStem.v := min(6,pCncritStem1h.v);
      end
      else begin
        NcStem.v := 0;
        NcritStem.v := 0;
      end;

    // Schoten
    if (DMGen.v + DMGen.c > 0) and (DMGen.v > 0) then begin
      NcGen.v := max(0,pCnPod2.v * ln(DMGen.v) + pCnPod1.v);
      NcritGen.v := max(0,pCncritPod2.v * ln(DMGen.v) + pCncritPod1.v);
      dNcGen.v   := max(0,(pCnPod2.v * ln(DMGen.v+DMGen.c) + pCnPod1.v))-NcGen.v;
    end
    else begin
      if (DMGen.c >0) then begin
        NcGen.v := pCnPod1.v;
        NcritGen.v := 0;
      end
      else begin
        NcGen.v := 0;
        NcritGen.v := 0;
        dNcGen.v := 0;
      end;
    end;

    // Wurzeln
    if DayofYear.v <= 30 then begin
      NcRoot_VA.v := NcRoot.v;
      NcritRoot_VA.v := NcritRoot.v;
    end;

    if EC.v <= 70 then begin
      NcRoot_EC70.v := NcRoot.v;
      NcritRoot_EC70.v := NcritRoot.v;
    end;

    If DMRoot.v <= 0 then begin
      if (DMRoot.c > 0) then begin
        NcRoot.v := min(5.5,pCnRoot1h.v);
        NcritRoot.v := min(5.5,pCncritRoot1h.v);
      end
      else begin
        NcRoot.v := 0;
        NcritRoot.v := 0;
      end;
    end
    else begin
      if EC.v > 70 then begin
        NcRoot.v := max(0.8,((0.8 - NcRoot_EC70.v)/(90-70)) * (EC.v - 70) + NcRoot_EC70.v);
        NcritRoot.v := max(0.8,((0.8 - NcritRoot_EC70.v)/(90-70)) * (EC.v-70) + NcritRoot_EC70.v);
        dNcRoot.v := max(0.8,(((0.8 - NcRoot_EC70.v)/(90-70)) * (EC.v+DVS_rate.v*19-70) + NcRoot_EC70.v))-NcRoot.v;
      end
      else
        if (DayofYear.v > 60) then begin
          NcRoot.v := min(NcRoot.v,max(0,pCnRoot2f.v*DMRoot.v+pCnRoot1f.v+DMRoot.v*pCnRoot2f.v));
          NcritRoot.v := min(NcritRoot.v,max(0,pCncritRoot2f.v*DMRoot.v+pCncritRoot1f.v+DMRoot.v*pCncritRoot2f.v));
          dNcRoot.v := min(NcRoot.v,max(0,pCnRoot2f.v*(DMRoot.v+DMRoot.c)+pCnRoot1f.v+(DMRoot.v+DMRoot.c)*pCnRoot2f.v))-NcRoot.v;
        end
        else
          if (DayofYear.v >= 30) and (DayofYear.v <= 60) then begin
            NcRoot.v := ((pCnRoot1f.v - NcRoot_VA.v)/(60-30))*(DayofYear.v - 30) + NcRoot_VA.v;
            NcritRoot.v := ((pCncritRoot1f.v - NcritRoot_VA.v)/(60-30))*(DayofYear.v - 30)+NcritRoot_VA.v;
            dNcRoot.v := (((pCnRoot1f.v - NcRoot_VA.v)/(60-30))*((DayofYear.v + 1) - 30) + NcRoot_VA.v)-NcRoot.v;
          end
          else begin
            NcRoot.v := max(1,pCnRoot2h.v * ln(DMRoot.v) + pCnRoot1h.v);
            NcritRoot.v := max(1,pCncritRoot2h.v * ln(DMRoot.v) + pCncritRoot1h.v);
            dNcRoot.v := max(1,pCnRoot2h.v * ln(DMRoot.v+DMRoot.c) + pCnRoot1h.v)-NcRoot.v;
          end
    end;


  // NNIi-Berechnung aus der Differenz von optimaler und kritischer N-Konzentration
    {NNIi ist nicht identisch mit dem NNI von Justes et al. 1994, beschreibt aber aus den Daten der Verdünnungsfunktionen bestmöglich den N-Status der einzelnen Organe}
    if fNSensOption = N_unlimited then begin
      NNILeaf.v := 1;
      NNIStem.v := 1;
      NNIGen.v := 1;
      NNIRoot.v := 1;
   end
    else begin
      if (NcLeaf.v <= NcritLeaf.v) and (NcLeaf.v > 0) and (NcritLeaf.v > 0) then
        NNILeaf.v := 0//minNNI.v
      else
        if (NcLeaf.v > 0) and (NcritLeaf.v > 0) then
          NNILeaf.v := max(0 {minNNI.v},min(1,(NLeaf.v-(DMLeaf.v*NcritLeaf.v/100))/((DMLeaf.v*NcLeaf.v/100)-(DMLeaf.v*NcritLeaf.v/100))))
        else
          NNILeaf.v := 1;

      if (NcStem.v <= NcritStem.v) and (NcStem.v > 0) and (NcritStem.v > 0) then
        NNIStem.v :=0 // minNNI.v
      else
        if (NcStem.v > 0) and (NcritStem.v > 0) and (NStem.v > 0) then
          NNIStem.v := max(0{minNNI.v}, min(1,(NStem.v-(DMStem.v*NcritStem.v/100))/((DMStem.v*NcStem.v/100)-(DMStem.v*NcritStem.v/100))))
        else
          NNIStem.v := 1;

      if (NcGen.v <= NcritGen.v) and (NcGen.v > 0) and (NcritGen.v > 0) then
        NNIGen.v := 0
      else
        if ((NcGen.v > 0) and (NcritGen.v > 0) and (NGen.v > 0)) and (EC.v > 70) then
          NNIGen.v := max(0{minNNI.v}, min(1,(NGen.v-(DMGen.v*NcritGen.v/100))/((DMGen.v*NcGen.v/100)-(DMGen.v*NcritGen.v/100))))
        else
          NNIGen.v := 1;

      if (NcRoot.v <= NcritRoot.v) and (NcRoot.v > 0) and (NcritRoot.v > 0) then
        NNIRoot.v := 0//minNNI.v
      else
        if (NcRoot.v > 0) and (NcritRoot.v > 0) and (NRoot.v > 0) and (DMRoot.v > 0) then
          NNIRoot.v := max(0{minNNI.v},min(1,(NRoot.v-(DMRoot.v*NcritRoot.v/100))/((DMRoot.v*NcRoot.v/100)-(DMRoot.v*NcritRoot.v/100))))
        else
          NNIRoot.v := 1;
    end;


  // Berechnung von spezifischen Flächen und Flächen-Indices

  // SLA
    {if (EC.v <= 30) then
      SLAf.v := actSLA.v;}

    if (EC.v < 30) then      // variables SLA im Herbst; lineare Abhängigkeit von der Temperatursumme nach Aussaat
      actSLA.v := max (SLAmin.v, min(SLAmax.v, SLAhst.v*TempsumAussaat.v+SLAhin.v))
    else
        if (EC.v <= 64) then // Dissertation W. Weymann, Chapter 4, Figure 3
        actSLA.v := min(500,max(actSLA.v,fSLAspring.v * LAIShoot.v + SLAspring.v))
        else
        actSLA.v := actSLA.v;

  //SPA (specific pod area)
    if (EC.v >= 51) and (EC.v <= 70) then
      if (EC.v <= 65) then
        actSPA.v := ((SPAmax.v-0)/(65-51))*(EC.v - 51) + 0
      else
        actSPA.v := max(0, SPAmax.v * exp(SPA_exp.v * EC.v))
    else
      actSPA.v := 0;

  // LAI
    if (DMLeaf.c < 0) then
      LAILeaf.c := DMLeaf.c * avSLA.v/10000
    else
      {if (EC.v < 30) then
        LAILeaf.c :=  DMLeaf.c*actSLA.v/10000
      else}
        LAILeaf.c :=  ((DMLeaf.v + DMLeaf.c) * actSLA.v/10000)-LAILeaf.v;

  // SAI (stem area index)
    if (EC.v < 80) then
      LAIStem.c :=  DMStem.c*SSA.v/10000
    else begin
      SAI.v := (((-0.01)-0)/(90-80))*(EC.v-80)+0;
      LAIStem.c := max(-LAIStem.v, (SAI.v * TempSumSeed.v + maxLAIStem.v)-LAIStem.v);
    end;

  // PAI (pod area index)
    if (EC.v < 80) then
      LAIGen.c := DMGen.c * actSPA.v / 10000
    else begin
      {LAIGen.c := max(-LAIGen.v,PAI.v * (maxLAIGen.v - (DMGen.c * actSPA.v / 10000)));}
  //    LAIGen.c := Steigung von linearer Gleichung von abfallenden LAIGen mit der Temperatursumme von maxLAIGen bis 0 !
      PAI.v := (((-0.01)-0)/(90-80))*(EC.v-80)+0;
      LAIGen.c := max(-LAIGen.v, (PAI.v * TempSumSeed.v + maxLAIGen.v)-LAIGen.v);
    end;


  // N-Mengen-Berechnung (aus Trockenmasse und N-Konzentration der einzelnen Organe)
    //Blätter
    if DMLeaf.v <= 0 then
      NLeaf.c := 0
    else
      if DMLeaf.c > 0 then
        NLeaf.c := max(0,(DMLeaf.c * (NcLeaf.v+DMLeaf.v*dNcLeaf.v/DMLeaf.c) / 100))
      else if DMLeaf.c < 0 then
        NLeaf.c := DMLeaf.c * NLeaf.v / DMLeaf.v
      else
        NLeaf.c := 0;

    // N-Verlust durch Frost- und Beschattungsseneszenz
    if DMDeadW.c > 0 then
      NDeadW.c := (DMDeadLeafW.c * NcLeaf_act.v /100) + (DMDeadStemW.c * NcStem_act.v /100) + (DMDeadRootW.c * NcRoot_act.v/100) // Verlust von N-Mengen durch Frostseneszenz
    else
      NDeadW.c := 0;

    if (NLeaf.c < 0) and (DMDeadW.c = 0) then
      NDeadSh.c := -NLeaf.c * (1-pCnTrans.v)
    else
      NDeadSh.c := 0;

    NDead.c := NDeadW.c + NDeadSh.c {+ NDeadAge.c};
    N_Dead.c := NDead.c * 10;

    //Stängel
    if DMStem.c >= 0 then
      NStem.c := (DMStem.c * NcStem.v+DMStem.v*dNcStem.v) / 100
    else
      if (DMStem.c < 0) then begin
        if DMstem.v > 0 then
        NStem.c := DMStem.c * NStem.v / DMStem.v;
      end;
    // Schoten
    if DMGen.c > 0 then begin
      NGen.c := max(0,(DMGen.c * (NcGen.v+DMGen.v*dNcGen.v/DMGen.c) / 100));
      NSeed.v := (DMSeed.v * pCnSeed.v)/100;
      NPodWall.v := max(0.2*NGen.v,NGen.v - NSeed.v);
      NSeed.v := NGen.v - NPodWall.v;
    end
    else if (DMGen.c < 0) and (DMGen.v > 0) then begin
      NGen.c := DMGen.c * NGen.v / DMGen.v;
      NSeed.v := (DMSeed.v * pCnSeed.v)/100;
      NPodWall.v := max(0.2*NGen.v,NGen.v - NSeed.v);
      NSeed.v := NGen.v - NPodWall.v;
    end
    else begin
      NGen.c := 0;
      NSeed.v := 0;
      NPodWall.v := 0;
    end;

    // Wurzeln
    if DMRoot.v <= 0 then
      NRoot.c := 0
    else
      if DMRoot.c > 0 then
        NRoot.c := (DMRoot.c * (NcRoot.v+DMRoot.v*dNcRoot.v/DMRoot.c) / 100)
      else if DMRoot.c < 0 then
        NRoot.c := DMRoot.c * NRoot.v / DMRoot.v
      else
        NRoot.c := 0;


  // N-Translokation
  // (65% des aktuell in den Blättern vorhandenen Stickstoffs werden transloziert)

     {Malagoli et al. 2005: Dynamics of Nitrogen Uptake and Mobilization in
     Field-grown Winter Oilseed Rape (Brassics napus) from Stem Extension
     to Harvest. I. Global N Flows between Vegetative and Reproductive Tissues
     in Relation to Leaf Fall and their Residual N. Annals of Botany 95, 853-861.}

    if (DMDeadW.c = 0) and (NLeaf.c < 0) then
      NTransLeaf.c := min(NLeaf.v,-NLeaf.c) * pCnTrans.v
    else
      NTransLeaf.c := 0;

    if (NStem.c < 0) and (DMDeadW.c = 0) then
      NTransStem.c := min(NStem.v, -NStem.c)
    else
      NTransStem.c := 0;

    if (NRoot.c < 0) and (DMDeadW.c = 0) then
      NTransRoot.c := min(NRoot.v,-NRoot.c)
    else
      NTransRoot.c := 0;

    potNTrans.c := NTransLeaf.c + NTransStem.c + NTransRoot.c;

   // N-Pool und N-Translokation in die Schoten
      if (NGen.c <= potNTrans.c) then
        if (EC.v < 80) then begin
          potNPool.c := potNTrans.c - NGen.c;       // Anlage eines N-Pools für N-Mengen, die vor der Entwicklung der Schoten transloziert werden --> Wo liegt dieser Pool?
          NPool.c := max(0,min((((DMStem.v*6/100)-strNStem.v)+((DMRoot.v*5.5/100)-strNRoot.v))-NPool.v,potNPool.c));
          NTrans.c := max(0,NGen.c);                  // in die Schoten translozierte N-Menge
          NDead.c := NDead.c + (potNPool.c - NPool.c);
        end
        else begin
          potNPool.c := 0;
          NPool.c := 0;
          NTrans.c := NGen.c;
          NDead.c := potNTrans.c - NTrans.c;
        end
      else begin
        potNPool.c := 0;
        NTrans.c := potNTrans.c;
        NPool.c := min(0,max(-NPool.v,-(NGen.c - NTrans.c)));   // Entleerung des N-Pools, wenn die N-Mengen in den Schoten stark zunehmen
        NTrans.c := max(0,min(NGen.c,NTrans.c - NPool.c));      // in die Schoten translozierte N-Menge
      end;

  // N-Pool in Stängeln und Wurzeln
    poolNStem.c := max(-poolNStem.v,min((DMStem.v * 6 / 100)-NStem.v, NPool.c));
    poolNRoot.c := NPool.c - poolNStem.c;

  // strkturelles N in Stängeln und Wurzeln
    strNStem.c := max(-strNStem.v,NStem.c);
    strNRoot.c := max(-strNRoot.v,NRoot.c);



  // N-Bedarf, sowie Ausgleich von N-Mangel und N-Überschuss
   { Erläuterungen: Ausgleich von N-Mangel und N-Überschuss.pdf}

  // N-Bedarf fürs Wachstum (NDemandGrowth) und die Kompensation von N-Defiziten (NDemandDeficit)
    NDemandGrowth.v := max(0,max(0,NLeaf.c) + max(0,NStem.c) + max(0,NRoot.c) + max(0,(NGen.c - NTrans.c)));
    NDemandDeficit.v := (DMLeaf.v * NcLeaf.v/100 - NLeaf.v)
                          + (DMGen.v * NcGen.v/100 - NGen.v)
                          + (DMStem.v * NcStem.v/100 - strNStem.v)
                          + (DMRoot.v * NcRoot.v/100 - strNRoot.v);

    NDemandDeficitLeaf.v := (DMLeaf.v * NcLeaf.v/100 - NLeaf.v);
    NDemandDeficitStem.v := (DMStem.v * NcStem.v/100 - strNStem.v);
    NDemandDeficitRoot.v := (DMRoot.v * NcRoot.v/100 - strNRoot.v);
    NDemandDeficitGen.v := (DMGen.v * NcGen.v/100 - NGen.v);

  // potentielle N-Aufnahme
    NUptakeRate_pot.v := max(0,NDemandGrowth.v + NDemandDeficit.v);

    NUptake_pot.c := max(0,NUptakeRate_pot.v);
  end

  else begin
    for I := 0 to StateStrList.Count - 1 do begin
      StateVar := TState(StateStrList.objects[i]);
      StateVar.c := 0.0;
    end;
  end;
end;

procedure TOSRGrowth.Integrate;
var
  NDemandDeficitNeg, NDemandDeficitPos: real;
begin
  {if NUptake_act.v > NUptake_pot.v then NUptakeRate_pot.v := NUptakeRate_pot.v - (NUptake_act.v - NUptake_pot.v);}
  if (SoilNitrogenMod <> nil) and (SoilNitrogenMod is TSoilNitrogenUp)
  then begin
    NDemandDeficitNeg := max(0,NLeaf.v - DMLeaf.v * NcLeaf.v/100)+max(0,strNStem.v - DMStem.v * NcStem.v/100)
                         +max(0,strNRoot.v - DMRoot.v * NcRoot.v/100)+max(0,NGen.v - DMGen.v * NcGen.v/100);
    NDemandDeficitPos := max(0,DMLeaf.v * NcLeaf.v/100-NLeaf.v)+max(0,DMStem.v * NcStem.v/100-strNStem.v)
                         +max(0,DMRoot.v * NcRoot.v/100-strNRoot.v)+max(0,DMGen.v * NcGen.v/100-NGen.v);
    NSupply.v := TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 + NDemandDeficitNeg + NPool.v + NPool.c;
    if (NSupply.v < NDemandGrowth.v) and (fNSensOption = N_sensitiv) then begin
      if NLeaf.c >0 then NLeaf.c := NLeaf.c * NSupply.v/NDemandGrowth.v;
      if strNStem.c >0 then strNStem.c := strNStem.c * NSupply.v/NDemandGrowth.v;
      if strNRoot.c >0 then strNRoot.c := strNRoot.c * NSupply.v/NDemandGrowth.v;
      if NGen.c >0 then NGen.c := max(0,NSupply.v - (max(0,NLeaf.c)) - (max(0,strNStem.c)) - (max(0,strNRoot.c)) + NTrans.c);
      if (NDemandDeficitNeg > 0) then begin
        NLeaf.c := NLeaf.c - max(0,(NLeaf.v - DMLeaf.v * NcLeaf.v/100));
        strNStem.c := strNStem.c - max(0,(strNStem.v - DMStem.v * NcStem.v/100));
        strNRoot.c := strNRoot.c - max(0,(strNRoot.v - DMRoot.v * NcRoot.v/100));
        NGen.c := NGen.c - max(0,(NGen.v - DMGen.v * NcGen.v/100));
      end;
      NPool.c := - NPool.v;
      PoolNStem.c := -PoolNStem.v;
      PoolNRoot.c := - PoolNRoot.v;
    end
    else begin
      if ((NSupply.v-NDemandGrowth.v) > NDemandDeficit.v) then begin
        NLeaf.c := NLeaf.c + max(0,DMLeaf.v * NcLeaf.v/100 - NLeaf.v);
        strNStem.c := strNStem.c + max(0,DMStem.v * NcStem.v/100 - strNStem.v);
        strNRoot.c := strNRoot.c + max(0,DMRoot.v * NcRoot.v/100 - strNRoot.v);
        NGen.c := NGen.c + max(0,DMGen.v * NcGen.v/100 - NGen.v);
        if (NSupply.v - (NPool.v + NPool.c)-NDemandGrowth.v) > NDemandDeficit.v then begin
          if NDemandDeficitNeg > 0 then begin
            NLeaf.c := NLeaf.c + min(0,DMLeaf.v * NcLeaf.v/100 - NLeaf.v) + max(0,(NLeaf.v - DMLeaf.v * NcLeaf.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
            strNStem.c := strNStem.c + min(0,DMStem.v * NcStem.v/100 - strNStem.v) + max(0,(strNStem.v - DMStem.v * NcStem.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
            strNRoot.c := strNRoot.c + min(0,DMRoot.v * NcRoot.v/100 - strNRoot.v) + max(0,(strNRoot.v - DMRoot.v * NcRoot.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
            NGen.c := NGen.c + min(0,DMGen.v * NcGen.v/100 - NGen.v) + max(0,(NGen.v - DMGen.v * NcGen.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
          end;
        end
        else {Pool wird zum Ausgleich benötigt}
          if (PoolNStem.v+PoolNRoot.v) > 0 then begin
            NPool.c := NPool.c + TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 - NDemandGrowth.v - NDemandDeficit.v;
            PoolNStem.c := PoolNStem.c + (TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 - NDemandGrowth.v - NDemandDeficit.v)*PoolNStem.v/(PoolNStem.v+PoolNRoot.v);
            PoolNRoot.c := PoolNRoot.c + (TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 - NDemandGrowth.v - NDemandDeficit.v)*PoolNRoot.v/(PoolNStem.v+PoolNRoot.v);
          end;
      end
      else if NDemandDeficitPos > 0 then begin
        NLeaf.c := NLeaf.c - max(0,(NLeaf.v - DMLeaf.v * NcLeaf.v/100)) - min(0,NLeaf.v - DMLeaf.v * NcLeaf.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        strNStem.c := strNStem.c - max(0,(strNStem.v - DMStem.v * NcStem.v/100)) - min(0,strNStem.v - DMStem.v * NcStem.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        strNRoot.c := strNRoot.c - max(0,(strNRoot.v - DMRoot.v * NcRoot.v/100)) - min(0,strNRoot.v - DMRoot.v * NcRoot.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        NGen.c := NGen.c - max(0,(NGen.v - DMGen.v * NcGen.v/100)) - min(0,NGen.v - DMGen.v * NcGen.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        NPool.c := - NPool.v;
        PoolNStem.c := -PoolNStem.v;
        PoolNRoot.c := - PoolNRoot.v;
      end;
    end;
    NUptake_act.c := TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10;
  end
  else NUptake_act.c := NUptakeRate_pot.v;
  LAIShoot.c := LAILeaf.c + LAIStem.c + LAIGen.c;
  NStem.c := strNStem.c + poolNStem.c;
  NRoot.c := strNRoot.c + poolNRoot.c;
  if (EC.v >= 90) then begin
    NLeaf.c := 0;
    NStem.c := 0;
    NGen.c := 0;
    NRoot.c := 0;
    NShoot.c := 0;
  end;
  NShoot.c := NGen.c + NLeaf.c + NStem.c;
  NPlant.c := min(NUptake_act.c,NGen.c + NLeaf.c + NStem.c + NRoot.c);
  NBalance.c := max(0,NPlant.c + NDead.c);
  inherited;

  if (LAIShoot.v + LAIShoot.c >= 2.0) and (LAIShoot.v < 2.0) then
    EC_act.v := EC.v;
{  if (NUptake_act.v>0) then
    NNI.v := min(1,(SoilNitrogenMod.ActNUptake.v / NUptakeRate_pot.v ))
  else NNI.v := 1;
  if fNSensOption = N_unlimited then NNI.v := 1;}


  if DMLeaf.v >0 then avSLA.v := LAILeaf.v/DMLeaf.v*10000 else avSLA.v := 0;
  if DMGen.v > 0 then avSPA.v := LAIGen.v / DMGen.v * 10000 else avSPA.v := 0;


// Harvest index
 // if Yield.v > 0 then HI.v := Yield.v*10 / DMShoot.v;


// N-Harvest-Index
  if (NSeed.v > 0) then
    NHI.v := NSeed.v / NShoot.v;


// Nitrogen Use Efficiency
  if (Yield.v > 0) then begin
    if NUptake_act.v > 0 then

    NUE.v := Yield.v*10 / NUptake_act.v else
    NUE.v := 0.0;
  end;


// Berechnung der actuellen N-Konzentration
  if (DMLeaf.v > 0) then
    NcLeaf_act.v := NLeaf.v/DMLeaf.v*100
  else
    NcLeaf_act.v := 0;

  if (DMStem.v > 0) then
    NcStem_act.v := NStem.v/DMStem.v*100
  else
    NcStem_act.v := 0;

  if (DMGen.v > 0) then
    NcGen_act.v := NGen.v/DMGen.v*100
  else
    NcGen_act.v := 0;

  if (DMRoot.v > 0) then
    NcRoot_act.v := NRoot.v/DMRoot.v*100
  else
    NcRoot_act.v := 0;


  DMShoot_vW.c := DMLeaf.c + DMStem.c + DMGen.c;

// N_Defizitfaktor berechnen (um Phasen mit N-Defizit zu erkennen)
  if (NDemandGrowth.v > 0) then
    N_Def.v := min(1,(TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10)/NDemandGrowth.v)
  else
    N_Def.v := 1;

  if Assigned(SoilMinMod) and (SoilMinMod is TAbstractSoilMin) and not harvested then TAbstractSoilMin(SoilMinMod).AddResidues(C_Dead.c,N_Dead.c);


  if (EC.v >= 90) and (DateHarvestWasSet = false) then begin
    HarvestDate.v := GlobTime.v;
    DateHarvestWasSet := true;
  end;

  //N_Residues.v := 0.21*NShoot.v;          // dneukam: auskommentiert am 26.10.21
  //C_Residues.v := N_Residues.v * 95;
  N_Residues.v := NRoot.v + NStem.v + NLeaf.v+NPodWall.v;   // dneukam: ergänzt am 26.10.21
  C_Residues.v := (DMRoot.v + DMStem.v + DMLeaf.v + DMPodWall.v)*0.45 ;

end;

procedure TOSRGrowth.setDevelopmentModel(AModel: TDevelopmentOSR);
begin
  fDevelopmentModel := AModel;
  EC.Search := false;
  EC.f_v := @DevelopmentModel.EC.fv;
  EC.Source := '['+DevelopmentModel.Name+']';
  DVS.Search := false;
  DVS.f_v := @DevelopmentModel.DVS.fv;
  DVS.Source := '['+DevelopmentModel.Name+']';
  DVS_rate.Search := false;
  DVS_rate.setPointer(@DevelopmentModel.DVS.c);
  DVS_rate.Source := '['+DevelopmentModel.Name+']';
end;


function TOSRGrowth.getExtCoeffPAR: real;     // Funktion für die Berechnung des Extinktionskoeffizienten
begin
  if LAIShoot.v < LAIcrit_exk.v then
    result := exk.v + (exk_0.v-exk.v)*(LAIcrit_exk.v-LAIShoot.v)/LAIcrit_exk.v
  else
    result := exk.v;
end;

function TOSRGrowth.GetLAI:THumeNumEntity;
begin
  result := LAIShoot;
end;

function TOSRGrowth.GetCropHeight:THumeNumEntity;
begin
  result := CropHeight;
end;

{procedure TOSRGrowth.SetCropHeight(NewCropHeight:THumeNumEntity);
begin
  p_CropHeight := NewCropHeight;
end;

procedure TOSRGrowth.SetLai(NewLAI:THumeNumEntity);
begin
  p_LAI := NewLAI;
end;}

function TOSRGrowth.GetNUptakeRate:THumeNumEntity;
begin
  result := NUptakeRate_pot;
end;


function TOSRGrowth.GetWLD(Index:Integer):THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then
    result := RootModel.effWLD_Arr[Index]
  else
    result := DummyVar;
end;

function TOSRGrowth.GetSumRootLength:THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then
    result := RootModel.SRL
  else
    result := DummyVar;
end;

function TOSRGrowth.GetSumRootLength_eff:THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then
    result := RootModel.SRL_eff
  else
    result := DummyVar;
end;


procedure TOSRGrowth.SetSowingDate(NewSowingDate: real);

begin
  inherited;
end;

procedure TOSRGrowth.setNextCrop(NextCrop:TAbstractplant);
begin
  inherited;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TOSRGrowth]);
{$ENDIF}
end;

end.