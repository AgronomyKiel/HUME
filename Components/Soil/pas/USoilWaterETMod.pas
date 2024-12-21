unit USoilWaterETMod;

{Submodel TSoilWaterET verknüpft TSoilWaterMod mit Evapotranspirationsberechnung
 aus TPenMonteith}

interface
uses UMod, UState, USoilWaterMod, ULayeredSoil, UGenucht, Classes, USoilTexture;

const
  l_h_v_water = 2.477*1e6;       { latente Verdunstungsenergie von
                                 {  Wasser bei bei 10 øC in [J/Kg] }
  Psycro      = 0.000662;        { Psychrometerkonstante [1/øK]  }

type
TVGParsFromTexture = (FromPar, FromTexture);
TKsFromTexture = TVGParsFromTexture;
Tm_model = (Mualem, Burdine, Vereecken);    // type of model for calculating the parameter 'm' within the van Genuchten model
T_rc_Funct = (Kochler, Campbell, Reid, Gao,{Lohammar,} Neukam);   // Function for calculating rc from Psi_leaf
T_ra_Funct = (PenmanMonteith, ThomOliver);
T_rc_upscaling = (Stockle, BenMehrez);


TSoilWaterET = class(TLayeredSoil)
private
  FVGParsFromTexture: TVGParsFromTexture;
  FKsFromTexture: TKsFromTexture;
  FTextureClass1,         { Bodenart in Horizont 1 bei TVGParsFromTexture = FromTexture}
  FTextureClass2,
  FTextureClass3,
  FTextureClass4: TTextureClass;
  theta_neu : TSoilArray;       // neue
  MaxAktAenderWaGe,             // maximale Wassergehaltsänderung
  akt_bilanz_f,
  sum_Bilanz_f
                  : real;
  Dw_arr,                       // Diffusivitäten [cm2/d] }
  Ku_arr,                 { ungesättigte hydraulische Leitfähigkeiten [cm/d] }
  avg_Dw,                 { Mittelwert der Diffusivität zwischen 2 Kompartimenten [cm2/d] }
  avg_Ku,                 { Mittelwert der unges„ttigten hydr. Leitf„higkeit
                            zwischen 2 Kompartimenten [cm/d] }
  Dw_fact,
  Ku_fact,
  B_vektor,
  lower,
  diag,
  upper,
  last_iter_theta,       { Wassergehalte bei der letzten Iteration [cm3/cm3 }
  est_theta
                  : TSoilArray;

  CompMethod   : TCompMethod;
  fm_model : Tm_model; // type of m_model used
  f_rc_Funct: T_rc_Funct;   // Function for calculating rc from Psi_leaf
  f_ra_Funct: T_ra_Funct;   // Function for calculating ra from u and CropHeight


  Untere_Randb : TLowerBoundaryCondition;
  IniMethod    : TIniMethod;
  nFKCalcMethod : TnFKCalcMethod;
  max_aenderWG : real;  // maximale Wassergehaltsänderung pro Zeitschritt
  FHoriNdx1,
  FHoriNdx2,
  FHoriNdx3,
  FHoriNdx4 : integer;
  procedure CapWatSolut;
  procedure get_water_contents;
  Procedure Diffwater_solut;

protected
  dt_alt: real;                       // alte Zeitschrittweite [d]

  pTI : real;         // Summe von Interzeption und potentieller Transpirationsrate
  SumOfInternalTimeSteps : real;
  Max_dt   : real;
  FDebug: Boolean;
  SumSinks_int: extended;
  f_rc_upscaling: T_rc_upscaling;  // Function for calculating canopy resistance from stomatal resistance
  procedure CheckSinks;

  procedure Interzeption_p ;
  function Evaporation_f :real;
  function f_Evap: real;
  function pressure_f ( Elev, Temp : real):real;
  function sat_vap_press_f ( Temp : real):real;
  function delta_f ( sat_vap_press, Temp : real):real;
  function ra_f ( wind_speed, crop_height: real ) : real;
  function rc_f: real;
{  function evap_red_f: real;}
  function Penman(Temp,Sat_def,Net_beam,delta,gamma,l_h_v_water,ra,rc: real): real;
  function dens_air ( Temp : real ) : real;
  function r_soil_f ( lrv, a, K, dz : real):real;
  function r_interf_f( Rrr, theta, theta_s, Lrv, dz:real):real;
  function getPsiRoot: extended; virtual;
  procedure CalcWGs; virtual; //Berechnung der abgeleiteten Wassergehalte in verschiedenen Horizonten
  function rc_upscaling_f ( rs_leaf :real; upscaling_opt: T_rc_upscaling): real;

public
  Elev  : TPar;       //       Höhe über NN [m]               }
  rc0   : TPar;       // minimaler Stomatawiderstand
  exk_GlobRad : Tpar; // Exktinktionskoeffizient für Globalstrahlung [-]
  sic  : TPar;        // spezifische Interzeptionskapazit„t pro Einheit BFI [mm/BFI] }
  measure_height: TPar; { Messhöhe der Parameter [m] }

  TMPM,               // Temperatur [°C]
  GlobRad,            // Globalstrahlung [W.m-2]
  Sat_def,            // Sättigungsdefizit [mbar]
  wind_speed,         // Windgeschwindigkeit [m.s-1]
  CropHeight,         // Pflanzenhöhe [m]
  LAI,                // Blattflächenindex []
  rain                // Niederschlag [mm/d]
        : TExternV;

  aETP,               // aktuelle Evapotranspiration [mm/d]
  pETP,               // potentielle Evapotranspiration [mm.d-1]
  psi_leaf,           // Blattwasserpotential [cm]
  pot_trans,          // potentielle Transpiration [mm.d-1]
  pot_Evap,           // potentielle Evaporation
  interzeption,       // Interzeptionsverdunstung
  NetRain,            // Niederschlag-Interzeption
  netRad,             // Nettostrahlung
  ra,
  rc,
  rstom,               // stomatärer Widerstand
  gstom //dn (30.07.12)
        : TVar;

  f_rc_Option: TOption;   // Option for rc(Psi_leaf)-function
  f_ra_Option: TOption;   // Option for ra(u,CropHeight)-function
  f_rc_upscaling_Option: TOption; //Option for upscaling canopy resistance from stomatal resistance		////dn 08.05.14

  int_stor,           // Interzeptionsspeicher [mm]
  int_stor_ :TState;  // Interzeptionsspeicher [mm] für Berechnung innerhalb der Iteration

  theta_arr : TSoilvarArray;     // Wassergehaltsvektor [cm3/cm3]
  thetaadj_arr : TSoilStateArray;  // WG_scaling*Wassergehaltsvektor [cm3/cm3]
  WMenge    : TSoilStateArray;   // Wassermenge je Schicht [cm]
  psi_arr   : TSoilVarArray;     // Wasserspannungsvektor [cm]
  rs_arr, ri_arr : TSoilVarArray;
  intWflow_arr: TSoilVarArray;   // Flussvektor der Flüsse im internen Rechenschritt [cm/d]
  Wflow_arr: TSoilVarArray;      // Flussvektor der Flüsse im gesamten Zeitschritt [cm/d]
  Sink_arr  : TSoilVarArray;     // Sinkvektor [cm/d]
  SumSinks: TVar;                // Summe der Senkenterme [cm/d]
  FK_Arr    : TSoilArray;        // Feldkapazität }
  PWP_Arr   : TSoilArray;        // permanenter Welkepunkt [cm3/cm3]
  nFK_Arr   : TSoilArray;        // nutzbare Feldkapazität}
  WPar      : TSoilWaterParams;  // Van-Genuchten Parameter
  rs_voll, rs_null: TPar;         // Stomatawiderstand
  rc_par_a,
  rc_par_b,
  rc_par_c,
  rc_par_d,
  rc_par_e,
  rc_par_f,
  rc_par_h,
  rc_par_r,
  rc_par_s,
  r_fact,  //dn (30.07.12)
  g_fact   //dn (30.07.12)
  : TPar;                 // Parameter für rc-Funktion in Abhängigkeit von PsiRoot, Rn, T und VPD
  rs_Rn, rs_T, rs_VPD: TVar;
  mkf: TPar;                      // Parameter mkf für Stomatawiderstand
  p_Campbell: TPar;               // Parameter für Stomatafunktion nach Campbell
  p_Reid_int, p_Reid_slope: TPar; // Parameter für Stomatafunktion nach Reid
  {p_Lohammar_R0, p_Lohammar_gm,
    p_Lohammar_b: TPar;           // Parameter für Stomatafunktion nach Lohammar  }
  p_Gao_1,
  p_Gao_2,
  p_Gao_3,
  p_Gao_4: TPar;                  // Parameter für Stomatafunktion nach Gao et al (2002)

  Wflow_alt  : TSoilArray;       // alte Wasserflüsse [cm/d]
  theta_alt : TSoilArray;       // alte Wassergehalte

  HoriNdx1,
  HoriNdx2,
  HoriNdx3,
  HoriNdx4 : TPar;             //Index der untersten Schicht im jeweiligen Horizont

  bsat_scaling: TPar;
  alpha_scaling: TPar;
  WG_scaling: TPar;                // Scaling-Faktor für Anfangs-Wassergehalte

  FVGParsFromTextOption: TOption;
  FKsFromTextOption: TOption;
  FTextClass1Option,
  FTextClass2Option,
  FTextClass3Option,
  FTextClass4Option: TTextClassOption;

// van-Genuchten Parameter fuer Horizont 1

  b_sat1    : Tpar;                // Wassergehalt bei Sättigung [cm3/cm3] }
  b_rest1   : Tpar;                // "Restwassergehalt" [cm3/cm3] }
  alpha1    : TPar;                // Fitparameter "" [1/cm] }
  n_par1    : TPar;                // Fitparameter "n" dimensionslos }
  Ks1       : TPar;                // gesättigte Leitfähigkeit [cm.d-1]
  FK1       : TPar;                // Feldkapazität [cm3/cm3]
  PWP1      : TPar;                // permanenter Welkepunkt
  nFK1      : TPar;                // nutzbare Feldkapazität

// van-Genuchten Parameter fuer Horizont 2
  b_sat2    : Tpar;                // Wassergehalt bei Sättigung [cm3/cm3] }
  b_rest2   : Tpar;                // "Restwassergehalt" [cm3/cm3] }
  alpha2    : TPar;                // Fitparameter "" [1/cm] }
  n_par2    : TPar;                // Fitparameter "n" dimensionslos }
  Ks2       : TPar;                // gesättigte Leitfähigkeit [cm.d-1]
  FK2       : TPar;                // Feldkapazität [cm3/cm3]
  PWP2      : TPar;                // permanenter Welkepunkt
  nFK2      : TPar;                // nutzbare Feldkapazität

// van-Genuchten Parameter fuer Horizont 3
  b_sat3    : Tpar;                // Wassergehalt bei Sättigung [cm3/cm3] }
  b_rest3   : Tpar;                // "Restwassergehalt" [cm3/cm3] }
  alpha3    : TPar;                // Fitparameter "" [1/cm] }
  n_par3    : TPar;                // Fitparameter "n" dimensionslos }
  Ks3       : TPar;                // gesättigte Leitfähigkeit [cm.d-1]
  FK3       : TPar;                // Feldkapazität [cm3/cm3]
  PWP3      : TPar;                // permanenter Welkepunkt
  nFK3      : TPar;                // nutzbare Feldkapazität

// van-Genuchten Parameter fuer Horizont 4
  b_sat4    : Tpar;                // Wassergehalt bei Sättigung [cm3/cm3] }
  b_rest4   : Tpar;                // "Restwassergehalt" [cm3/cm3] }
  alpha4    : TPar;                // Fitparameter "" [1/cm] }
  n_par4    : TPar;                // Fitparameter "n" dimensionslos }
  Ks4       : TPar;                // gesättigte Leitfähigkeit [cm.d-1]
  FK4       : TPar;                // Feldkapazität [cm3/cm3]
  PWP4      : TPar;                // permanenter Welkepunkt
  nFK4      : TPar;                // nutzbare Feldkapazität

  PsiStart1 : TPar;
  psi_critEvap : TPar;             // Wasserspannung ab der Evaporation abnimmt [hPa]
  bil_nr    :  TPar;               // Index of Layer where lower boundary fluxes are calculated


  CumWaterBalance  : TState;       // kumulative Bilanz [mm] zur Kontrolle!
  CumDrainage : TState;            // kumulative Sickerwasserspende/kapillarer Aufstieg [mm]
  Act_Drainage : TVar;      // aktuelle Sickerwasserrate [mm/d]

  CumNetRain : TState;             // kumulativer Niederschlag [mm]
  red_evap : TVar;                 // Reduktionsfaktor für Evaporation
  Act_Evap : Tvar;                 // aktuelle Evaporationsrate
  CumEvap : TState;                // kumulative Evaporation
  CumInterzept: TState;            // kumulative Interzeption
  SumSoilWater,                    // sum of soil water down to boundary given by the Par "bil_nr"
  SumPAVSoilWater : TVar;          // sum of plant available soil water down to boundary given by the Par "bil_nr"
  dt       : TVar;                 // interne Zeitschrittweite des Diff. Wassertransportmodells
  n_int_timesteps: TVar;
  ActWaterBalance: TVar;

  psiRoot: TVar;   // average, weighted soil water potential within the rooting zone [pF]

  WG0_30,
  WG30_60,
  WG60_90,
  WG90_120,

  WG0_10,
  WG0_20,
  WG10_30,
  WG20_30,
  WG30_40,
  WG40_60,
  WG60_80,
  WG80_100,
  WG0_100,
  WG60_100 : TVar;
  ProzNFK0_100: TVar;

  procedure Init (var GlobMod:Tmod); override;
  procedure CalcEvap_red_f;
  procedure Integrate; override;
  procedure CalcRatesAndIntegrate; virtual;
{  constructor create(AOwner:TComponent);override;}
  procedure CalcRates; override;
  procedure CreateAll; override;
{  procedure Set_GlobMod(value:TMod);override;}
  procedure CalcSinks; virtual;
  procedure writeValues(FirstTime: boolean;s:string);virtual; {temporäre Ausgabe-Funktion, nur für Entwicklung}
  procedure writeDebug(Schicht: integer;dt,InFlow,OutFlow,Sink,Thick,WGalt,WGneu,Bil:Real);virtual;

published
  property m_model : Tm_model read fm_model write fm_model;
  property Ex_Temp    : TExternV read TMPM write TMPM;
  property Ex_GlobRad : TExternV read GlobRad write GlobRad;
  property Ex_Sat_def  : TExternV read Sat_def write Sat_def;
  property Ex_Windspeed  : TExternV read Wind_speed write Wind_speed;
  property Ex_CropHeight  : TExternV read CropHeight write CropHeight;
  Property Ex_LAI : TExternV read LAI write LAI;
  Property Ex_Rain : TExternV read Rain write Rain;
  Property Par_RC0 : Tpar read RC0 write rc0;
  Property Par_Exk_Glob:Tpar read exk_GlobRad write exk_GlobRad;
  Property Par_Elev :Tpar read Elev write Elev;
  Property Par_SIC :Tpar read SIC write SIC;

  Property Var_pETP : TVar read pETP write pETP;            // potentielle Evapotranspiration [mm.d-1]
  Property Var_PotTrans : TVar read pot_trans write Pot_trans;   // potentielle Transpiration [mm.d-1]
  Property Var_PotEvap : TVar read pot_Evap write pot_Evap;  // potentielle Evaporation}
  Property Var_interzeption : TVar read interzeption write interzeption; // Interzeptionsverdunstung
  Property Var_NetRain : TVar read NetRain write NetRain;     // Niederschlag-Interzeption}
  Property Var_ra : TVar read ra write ra;
  Property Var_NetRad : TVar read NetRad write Netrad;     // Nettostrahlung [W.m-2]

  property Opt_CompMethod   : TCompMethod read CompMethod write CompMethod;
  property Opt_maxWGchange  : real read  max_aenderWG write max_aenderWG;
  property Opt_Randbed      : TLowerBoundaryCondition read Untere_Randb write Untere_Randb;
  property Opt_IniMethod    : TIniMethod read IniMethod write IniMethod;
  property Opt_maxdt        : real read max_dt write max_dt;
  property Opt_nFKCalcMethod : TnFKCalcMethod read nFKCalcMethod write nFKCalcMethod;
  property Opt_VanGenPars_from_Texture: TVGParsFromTexture read FVGParsFromTexture write FVGParsFromTexture;
  property Opt_Ks_from_Texture: TKsFromTexture read FKsFromTexture write FKsFromTexture;
  property Opt_TextureClass1: TTextureClass read FTextureClass1 write FTextureClass1;
  property Opt_TextureClass2: TTextureClass read FTextureClass2 write FTextureClass2;
  property Opt_TextureClass3: TTextureClass read FTextureClass3 write FTextureClass3;
  property Opt_TextureClass4: TTextureClass read FTextureClass4 write FTextureClass4;

  property Par_b_sat1       : TPar read B_sat1 write b_sat1;
  property Par_b_rest1      : TPar read B_rest1 write b_rest1;
  property Par_b_KS1        : TPar read KS1 write KS1;
  property Par_n1           : TPar read n_par1 write n_par1;
  property Par_alpha1       : TPar read alpha1 write alpha1;
  property Par_FK1          : TPar read FK1 write FK1;                // Feldkapazität [cm3/cm3]
  property Par_PWP1         : TPar read PWP1 write PWP1;                // permanenter Welkepunkt
  property Par_nFK1         : TPar read nFK1;                // nutzbare Feldkapazität

  property Par_b_sat2       : TPar read B_sat2 write b_sat2;
  property Par_b_rest2      : TPar read B_rest2 write b_rest2;
  property Par_b_KS2        : TPar read KS2 write KS2;
  property Par_n2           : TPar read n_par2 write n_par2;
  property Par_alpha2       : TPar read alpha2 write alpha2;
  property Par_FK2          : TPar read FK2 write FK2;                // Feldkapazität [cm3/cm3]
  property Par_PWP2         : TPar read PWP2 write PWP2;                // permanenter Welkepunkt
  property Par_nFK2         : TPar read nFK2 ;                // nutzbare Feldkapazität

  property Par_b_sat3       : TPar read B_sat3 write b_sat3;
  property Par_b_rest3      : TPar read B_rest3 write b_rest3;
  property Par_b_KS3        : TPar read KS3 write KS3;
  property Par_n3           : TPar read n_par3 write n_par3;
  property Par_alpha3       : TPar read alpha3 write alpha3;
  property Par_FK3          : TPar read FK3 write FK3;                // Feldkapazität [cm3/cm3]
  property Par_PWP3         : TPar read PWP3 write PWP3;                // permanenter Welkepunkt
  property Par_nFK3         : TPar read nFK3;                // nutzbare Feldkapazität

  property Par_b_sat4       : TPar read B_sat4 write b_sat4;
  property Par_b_rest4      : TPar read B_rest4 write b_rest4;
  property Par_b_KS4        : TPar read KS4 write KS4;
  property Par_n4           : TPar read n_par4 write n_par4;
  property Par_alpha4       : TPar read alpha4 write alpha4;
  property Par_FK4          : TPar read FK4 write FK4;                // Feldkapazität [cm3/cm3]
  property Par_PWP4         : TPar read PWP4 write PWP4;                // permanenter Welkepunkt
  property Par_nFK4         : TPar read nFK4;                // nutzbare Feldkapazität

  property Par_PsiStart1    : TPar read PsiStart1 write PsiStart1;

  property Var_WG0_30 : TVar read WG0_30 write WG0_30;
  property Var_WG30_60 : TVar read WG30_60 write WG30_60;
  property Var_WG60_90 : TVar read WG60_90 write WG60_90;
  property Var_WG90_120 : TVar read WG90_120 write WG90_120;
  property Var_WG0_100 : TVar read WG0_100 write WG0_100;

  property Var_ActEvap : TVar read Act_Evap write Act_Evap;
  property Var_ActDrainage : TVar read Act_Drainage write Act_Drainage;

  property St_CumEvap   : TState read CumEvap write CumEvap;
  property St_CumNetRain: TState read CumNetRain write CumNetRain;

  property Par_psi_critEvap : TPar read psi_critEvap write psi_critEvap;

  property Par_Horindx1 :TPar read HoriNdx1 write HoriNdx1;
  property Par_Horindx2 :TPar read HoriNdx2 write HoriNdx2;
  property Par_Horindx3 :TPar read HoriNdx3 write HoriNdx3;
  property Par_Horindx4 :TPar read HoriNdx4 write HoriNdx4;

end;

procedure Register;

implementation

uses
  UModUtils, SysUtils, Math, Dialogs;

{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function TSoilWaterET.pressure_f ( Elev, Temp : real):real;

{ ********************************************************************** }
{ Zweck : Berechnung des Standardluftdrucks
  Parameter :
    Name             Inhalt                          Einheit      Typ

    Elev             Höhe über NN                    [m]          I
    Temp             Mittlere Tagestemperatur        [°C]         I

    pressure_f       Luftdruck                       [mbar]       O  }
{ ********************************************************************** }

begin
  pressure_f := 1013.0*exp(-0.034*Elev/(Temp+273));
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function TSoilWaterET.ra_f ( wind_speed, crop_height: real ) : real;

{ ********************************************************************** }
{ Zweck : Berechnung des aerodynamischen Widerstandes
  Parameter :
    Name             Inhalt                          Einheit      Typ

    wind_speed       Mittlere Windgeschwindigkeit    [m/s]        I
    crop_height      Pflanzenhöhe                    [m]          I

    ra_f             aerodynamischer Widerstand      [s/m]               }
{ ********************************************************************** }

const
  Karman_const     = 0.41;              { von Karman-Konstante [-] }
var
  z0 : real;
  d: real;

  function roughness_f ( crop_height : real ) : real;
  { ********************************************************************** }
  { Zweck : empirische Funktion zur Ermittlung des Rauigkeitsfaktors
            nach Monteith (1973) S.90
    Parameter :
      Name             Inhalt                          Einheit      Typ

      crop_height      Pflanzenhöhe                    [m]         I
      roughness_f      Rauhigkeitsfaktor               [m]         O }
  { ********************************************************************** }
  begin
    if crop_height<0.05 then crop_height := 0.05; // Mindesthöhe von 5 cm
    roughness_f := 0.13*crop_height;
  end;

  function displacement_height ( crop_height : real ) : real;
  begin
    if crop_height<0.05 then crop_height := 0.05; // Mindesthöhe von 5 cm
    displacement_height := 0.63 * crop_height;
  end;

begin
  If wind_speed < 0.0001 then wind_speed := 0.0001;
  z0 := roughness_f(crop_height);
  d := displacement_height(crop_height);
  case f_ra_funct of
    PenmanMonteith:   {Original-Penman-Monteith für near-neutral conditions}
        ra_f := (ln(measure_height.v/z0)*ln(measure_height.v/(0.2*z0)))/(sqr(Karman_const)*wind_speed);
    ThomOliver: {Formulierung zur Einbeziehung von Konvektion nach Thom and Oliver (1977)
                 zitiert in Jackson et al. 1988}
        ra_f := 4.72*sqr(ln((measure_height.v-d)/z0))/(1+0.54*wind_speed);

  end;
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function TSoilWaterET.dens_air ( Temp : real ) : real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Dichte trockener Luft
          Daten aus Monteith (1973)

  Parameter :
    Name             Inhalt                          Einheit      Typ

    Temp             Mittlere Tagestemperatur        [øC]         I
    dens_air         Dichte der Luft                 [Kg/m3]      O    }
{ ********************************************************************** }

begin
  dens_air := 1.2917-0.00434*Temp;
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}



{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function TSoilWaterET.Penman    ( Temp,
                                   Sat_def,
                                   Net_beam,
                                   delta,
                                   gamma,
                                   l_h_v_water,
                                   ra,
                                   rc          : real): real;

{ **********************************************************************
  **********************        Penman           ***********************
  **********************************************************************

  Erstellt von : Henning Kage

  Tag der ersten Bearbeitung  : 6.10.89
  Tag der letzten Bearbeitung : 8.10.89


  Zweck : Berechnung der potentiellen Evapotranspiration aus
          Standard-Witterungs- und Pflanzendaten

  Parameter :

    Name             Inhalt                          Einheit      Typ

    Temp             Lufttemperatur                  [øC]         I
    Sat_def          S„ttigungsdefizit der Luft      [mbar]       I
    Net_beam         Nettostrahlung                  [J/m2*s]     I
    delta            Steigung der S„ttigungs-
                     dampfdruckkurve                 [mbar/K]     I
    gamma            Psychrometerkonstante           [mbar/K]     I
    l_h_v_water      latente Verdunstungsw„rme
                     von Wasser bei 10øC             [J/Kg]       I
    ra               Grenzfl„chenwiderstand          [s/m]        I
    rc               bulk-Stomatawiderstand          [s/m]        I

    Penman           potentielle Evapotranspiration  [kg/(m2*s)]  O

  **********************************************************************
  **********************************************************************
  ********************************************************************** }

const
  cp = 1003.0;      { spezifische W„rme der Luft [J/(Kg*K)] }

var
  pETP,
  rho: real;         { Dichte der Luft [kg/m3 ]  }

begin { Penman }
  rho := dens_air ( Temp );
  pETP := (Delta*0.9*max(0,Net_beam)+rho*cp*Sat_def/ra) / (delta+gamma*(1+rc/ra));
  pETP := pETP/l_h_v_water*86400.0;
  result := max(pETP,0);
end;  { Penman }
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

procedure TSoilWaterET.Interzeption_p ;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Interzeption eines


  Parameter :
    BFI              Blattfl„chenindex                   [-]
    rain             Niederschlag                        [mm/d]
    pTI              potentielle Transpiration/Interzeption
                                                         [mm/d]
    Int_stor         Interzeptionsspeicher               [mm]



    Interzeption     Interzeptionsverdunstung des Bestandes
                                                         [mm/d]       O }
{ ********************************************************************** }


var
  max_int_cap,             { maximale Interzeptionskapazit„t [mm] }
  int_cap                  { aktuelle Interzeptionskapazit„t [mm]  }
               : real;

begin
  max_int_cap := LAI.v*sic.v;
  int_cap     := max_int_cap-int_stor.v;
  If int_cap > 0.0 then begin
    if int_cap > (rain.v) then begin
       int_stor_.v := int_stor.v + rain.v;
       NetRain.v := 0.0;
    end else begin
       int_stor_.v := max_int_cap;
       NetRain.v := rain.v - int_cap;
    end;
  end
  else NetRain.v := Rain.v;

  If NetRain.v > Rain.v then showmessage('Too much Netain !');

  If pTI > int_stor_.v then begin
   //  pTI := pTI - int_stor_.v;
     Interzeption.v := int_stor_.v;
     int_stor_.v := 0.0;
  end else begin
    Interzeption.v := pTI;
    int_stor_.v := int_stor_.v - pTI;
  end;

end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function TSoilWaterET.Evaporation_f :real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Evaporation eines
          Bodens unter einem Pflanzenbestand
          nach Duynisveld (1983) S.22

  Parameter :

    Name             Inhalt                          Einheit      Typ

    pET              potentielle Evapotranspiration  [mm/d]       I
    BFI              Blattfl„chenindex               [-]          I

    Evaporation_f    Evaporation unter einem
                     Pflanzenbestand                 [mm/d]       O }
{ ********************************************************************** }


var
  Evap : real;

begin
  Evap     := pETP.v*exp(-exk_GlobRad.v*LAI.v);
  If Evap  < 0.0 then Evap := 0.0;
  evaporation_f := evap;
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function TSoilWaterET.f_Evap: real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Evaporation eines
          Bodens unter einem Pflanzenbestand
          nach Duynisveld (1983) S.22

  Parameter :

    Name             Inhalt                          Einheit      Typ

    pET              potentielle Evapotranspiration  [mm/d]       I
    BFI              Blattfl„chenindex               [-]          I

    f_Evap           Evaporationsanteil an pET unter einem
                     Pflanzenbestand                 [mm/d]       O }
{ ********************************************************************** }


begin
  result := max(0, exp(-exk_GlobRad.v*LAI.v));
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


(*function TSoilWaterET.evap_red_f: real;
{ ********************************************************************** }
{ Zweck : Ermittlung eines Reduktionsfaktors der die potentielle
          Evaporation um den Einfluá einer geringen Bodenfeuchte an der
          Bodenfl„che korrigiert

  Parameter :
    Name             Inhalt                          Einheit      Typ

    Psi              Bodenwasserspannung im          [cm]         I
                     obersten Kompartimente (10 cm Tiefe)

    evap_red_f       Reduktionsfaktor der            [-]           O
                     potentiellen Evaporation
{ ********************************************************************** }

var
  red_f : real;
  pF_5  : real;

begin
  if psi_arr[1].v> 0.0 then begin
    pf_5 := log10(psi_arr[1].v);
    red_f := -1*(pf_5-4.2)/(4.2-log10(psi_critEvap.v))
//    red_f := -0.5767*log10(psi_arr[1].v)+1.78
  end
  else
    red_f := 0.0;
  If red_f > 1.0 then red_f := 1.0;
  If red_f < 0.0 then red_f := 0.0;
  result := red_f;
end;       *)


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

function TSoilWaterET.sat_vap_press_f ( Temp : real):real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung des gesättigten Wasserdampf-
          druckes
          nach Groot (1983) bzw. Goudriaan (1977)

  Parameter :

    Name             Inhalt                          Einheit      Typ

    Temp             Temperatur                      [øC]         I


    sat_vap_press_f  gesättigter Wasserdampfdruck    [mbar]       O }
{ ********************************************************************** }

begin
  sat_vap_press_f := 6.11*exp(17.4*Temp/(Temp+239.0));
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

function TSoilWaterET.delta_f ( sat_vap_press, Temp : real):real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung Steigung der Wasserdampf-
          druckkurve in Abh„ngigkeit von ges„ttigtem Wasserdampfdruck
          und Temperatur
          nach Groot (1983)

  Parameter :

    Name             Inhalt                          Einheit      Typ

    Temp             Temperatur                      [øC]         I
    sat_vap_press    ges„ttigter Wasserdampfdruck    [mbar]       I

    delta_f          Steigung der Wasserdampdruck-
                     kurve                            [mbar/øK]   O     }
{ ********************************************************************** }

begin
  delta_f         := 239.0*17.4*sat_vap_press/sqr(Temp+239.0);
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

procedure  TSoilWaterET.createAll;
var
  i: integer;
begin
  inherited CreateAll;
  m_model := mualem;
  VarCreate('PotEvap', '[]', 0.0,  false, pot_Evap);    // potentielle Evaporation
  VarCreate('NetRain', '[]', 0.0,  false, NetRain);     // Niederschlag-Interzeption
  ParCreate('Elev', '[m]',50.0, Elev);     // Höhe über NN [m]
  ParCreate('rc0', '[s.m-1]', 34, rc0,'minimaler Stomatawiderstand: für pETP und rstom Berechnung');    // Stomatawiderstand bei
                                           // "guter Wasserversorgung"
  ParCreate('exk_GlobRad', '[-]', 0.5, exk_GlobRad);
  ParCreate('SIC', '[mm.m-2.m-2]', 0.15, SIC);
  ParCreate('bil_nr', '[]', 12, bil_nr);                          // Index für Bilanzierung
  ParCreate('measure_height', '[m]', 2.0, measure_height);

  ExternVCreate('TMPM', '[°C]',     StateField,     TMPM);        // Temperatur [°C]
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad);      // Nettostrahlung [W.m-2]
  ExternVCreate('Sat_def', '[hPa]',   StateField,   Sat_Def);        // Sättigungsdefizit [hPa]
  ExternVCreate('Wind', '[m.s-1]', StateField, wind_speed);       // Windgeschwindigkeit [m.s-1]
  ExternVCreate('CropHeight', '[m]', StateField,cropheight);      // Pflanzenhöhe [cm]
  ExternVCreate('LAI', '[-]',         StateField,LAI);            // Blattflächenindex []
  ExternVCreate('rain', '[mm.d-1]',   StateField,rain);      // Niederschlag [mm/d]

  VarCreate('psi_leaf', '[]', 1000.0,  false, psi_leaf);  // Blattwasserpotential [cm]
  VarCreate('aETP', '[]', 0.0,  false, aETP);            // aktuelle Evapotranspiration [mm/d]
  VarCreate('pETP', '[]', 0.0,  false, pETP);            // potentielle Evapotranspiration [mm.d-1]
  VarCreate('PotTrans', '[]', 0.0,  false, pot_trans);   // potentielle Transpiration [mm.d-1]
  VarCreate('interzeption', '[]', 0.0,  false, interzeption); // Interzeptionsverdunstung
  VarCreate('ra', '[s/m]', 0.0,  false, ra);
  VarCreate('rc', '[s/m]', 0.0,  false, rc);
  VarCreate('rstom', '[s/m]', 0.0, false, rstom, 'stomatärer Widerstand');
  VarCreate('gstom', '[cm/s]', 0.0, false, gstom, 'stomatäre Leitfähigkeit');//  dn (30.07.12)
  VarCreate('NetRad', '[W.m-2]', 0.0,false, NetRad);     // Nettostrahlung [W.m-2]
  VarCreate('SumSoilWater', '[mm]',0.0, true, SumSoilWater);
  VarCreate('SumPavSoilWater', '[mm]',0.0, true, SumPavSoilWater);
  VarCreate('n_int_timesteps', '[]',0.0, true, n_int_timesteps);
  VarCreate('SumSinks', '[cm/d]',0.0, true, SumSinks, 'Summe der Senkenterme [cm/d]');
  VarCreate('ActWaterBalance','[mm]',0.0,true,ActWaterBalance);
  VarCreate('psiRoot', '[pF]',0.0, false, psiRoot, 'average, weighted soil water potential within the rooting zone [pF]');

  StateCreate('CumWaterBalance', '[mm]', 0, true, CumWaterBalance);
  StateCreate('CumDrainage', '[mm]', 0, true, CumDrainage);
  StateCreate('int_stor', '[]', 0.0,  false, int_stor);    // Interzeptionsspeicher [mm]
  StateCreate('int_stor_', '[]', 0.0,  false, int_stor_);    // Interzeptionsspeicher [mm]
  for i := 1 to n_comp+1 do if WPar[i] = nil then Wpar[i] := TGenucht.create;

  ParCreate('rs_voll', '[s/m]', 3177.350133, rs_voll);
  ParCreate('rs_null', '[s/m]', 33.40928514, rs_null);
  ParCreate('mkf', '[s/m]', 2.24207079, mkf);
  ParCreate('p_Campbell', 'hPa', 4000.0, p_Campbell, 'Parameter für Stomatafunktion nach Campbell');
  ParCreate('p_Reid_int', '', 4.73, p_Reid_int, 'Parameter für Stomatafunktion nach Reid');
  ParCreate('p_Reid_slope', '', 0.003257, p_Reid_slope, 'Parameter für Stomatafunktion nach Reid');
  {ParCreate('p_Lohammar_R0', 'MJ/m2/d', 5.0, p_Lohammar_R0, 'Parameter für Stomatafunktion nach Lohammar'); // Parameterwerte für Weizen nach Heidmann et al. 2000
  ParCreate('p_Lohammar_gm', 'm/s', 0.0120, p_Lohammar_gm, 'Parameter für Stomatafunktion nach Lohammar');
  ParCreate('p_Lohammar_b', 'Pa', 1300, p_Lohammar_b, 'Parameter für Stomatafunktion nach Lohammar'); }
  ParCreate('p_Gao_1', 'mmol/m2/s', 250, p_Gao_1, 'Parameter für Stomatafunktion nach Gao');
  ParCreate('p_Gao_2', 'mmol/m2/s/kPa', 0.3, p_Gao_2, 'Parameter für Stomatafunktion nach Gao');
  ParCreate('p_Gao_3', '', 1.2, p_Gao_3, 'Parameter für Stomatafunktion nach Gao');
  ParCreate('p_Gao_4', '', 100, p_Gao_4, 'Parameter für Stomatafunktion nach Gao');
  ParCreate('rc_par_a', '[s.m-1.hPa]', 0.0124, rc_par_a, 'Parameter a für Stomatafunktion nach Neukam: Intercept SatDef-Einfluss auf psiRoot-Einfluss ');
  ParCreate('rc_par_b', '[s.m-1.hPa-2]', 0.00094, rc_par_b, 'Parameter b für Stomatafunktion nach Neukam: Slope SatDef-Einfluss auf psiRoot-Einfluss');
  ParCreate('rc_par_e', '[W.m-2]', 533, rc_par_e, 'Parameter e für Stomatafunktion nach Neukam: kritische Nettostrahlung');
  ParCreate('rc_par_f', '[s.m3.W-2]', 0.0005, rc_par_f, 'Parameter f für Stomatafunktion nach Neukam: Krümmung NetRad-Einfluss');
  ParCreate('rc_par_h', '[s.m-1.K-2]', 0.4275, rc_par_h, 'Parameter h für Stomatafunktion nach Neukam: Krümmung TMPM-Einfluss');
  ParCreate('rc_par_s', '[hPa]', 63, rc_par_s, 'Parameter s für Stomatafunktion nach Neukam: psiRoot bei pF=1.8');
  ParCreate('r_fact', '[]', 1, r_fact, 'scaling factor for rs');  //dn (30.07.12)
  ParCreate('g_fact', '[]', 1, g_fact, 'scaling factor for gs');
  VarCreate('rs_Rn', '[]', 1.0, false, rs_Rn);
  VarCreate('rs_T', '[]', 1.0, false, rs_T);
  VarCreate('rs_VPD', '[]', 1.0, false, rs_VPD);

  ParCreate('HoriNdx1', '[-]', 3, HoriNdx1);
  ParCreate('HoriNdx2', '[-]', 6, HoriNdx2);
  ParCreate('HoriNdx3', '[-]', 10, HoriNdx3);
  ParCreate('HoriNdx4', '[-]', 20, HoriNdx4);

  ParCreate('bsat_scaling', '[-]', 1, bsat_scaling);
  ParCreate('alpha_scaling', '[-]', 1, alpha_scaling);
  ParCreate('WG_scaling', '[-]', 1, WG_scaling);

  ParCreate('b_sat1', '[cm3.cm-3]', 0.4298, b_sat1);
  ParCreate('b_rest1','[cm3.cm-3]', 0.09, b_rest1);
  ParCreate('alpha1','[1/cm]', 0.00677, alpha1);
  ParCreate('n_par1','[-]', 1.29494, n_par1);
  ParCreate('Ks_1','[-]', 50.0, Ks1);
  ParCreate('FK_1', '[cm3/cm3]', 0.35, fk1);
  ParCreate('nFK_1', '[cm3/cm3]', 0.25, nfk1);
  ParCreate('PWP_1', '[cm3/cm3]', 0.1, PWP1);

  ParCreate('b_sat2', '[cm3.cm-3]', 0.45, b_sat2);
  ParCreate('b_rest2','[cm3.cm-3]', 0.09, b_rest2);
  ParCreate('alpha2','[1/cm]', 0.00677, alpha2);
  ParCreate('n_par2','[-]', 1.29494, n_par2);
  ParCreate('Ks_2','[-]', 50.0, Ks2);
  ParCreate('FK_2', '[cm3/cm3]', 0.35, fk2);
  ParCreate('nFK_2', '[cm3/cm3]', 0.25, nfk2);
  ParCreate('PWP_2', '[cm3/cm3]', 0.1, PWP2);

  ParCreate('b_sat3', '[cm3.cm-3]', 0.45, b_sat3);
  ParCreate('b_rest3','[cm3.cm-3]', 0.09, b_rest3);
  ParCreate('alpha3','[1/cm]', 0.00677, alpha3);
  ParCreate('n_par3','[-]', 1.29494, n_par3);
  ParCreate('Ks_3','[-]', 50.0, Ks3);
  ParCreate('FK_3', '[cm3/cm3]', 0.35, fk3);
  ParCreate('nFK_3', '[cm3/cm3]', 0.25, nfk3);
  ParCreate('PWP_3', '[cm3/cm3]', 0.1, PWP3);

  ParCreate('b_sat4', '[cm3.cm-3]', 0.45, b_sat4);
  ParCreate('b_rest4','[cm3.cm-3]', 0.09, b_rest4);
  ParCreate('alpha4','[1/cm]', 0.00677, alpha4);
  ParCreate('n_par4','[-]', 1.29494, n_par4);
  ParCreate('Ks_4','[-]', 50.0, Ks4);
  ParCreate('FK_4', '[cm3/cm3]', 0.35, fk4);
  ParCreate('nFK_4', '[cm3/cm3]', 0.25, nfk4);
  ParCreate('PWP_4', '[cm3/cm3]', 0.1, PWP4);

  ParCreate('PsiStart1', '[cm]', 500, PsiStart1);

  OptCreate('FVGParsFromTexture', 'FromPar', FVGParsFromTextOption);
  FVGParsFromTextOption.OptionList.Clear;
  FVGParsFromTextOption.OptionList.Add('FromPar');
  FVGParsFromTextOption.OptionList.Add('FromTexture');
  OptCreate('FTextureClass1','Sl3',TOption(FTextClass1Option));
  OptCreate('FTextureClass2','Sl3',TOption(FTextClass2Option));
  OptCreate('FTextureClass3','Sl3',TOption(FTextClass3Option));
  OptCreate('FTextureClass4','Sl3',TOption(FTextClass4Option));
  FTextClass1Option.AddTextureClasses;
  FTextClass2Option.AddTextureClasses;
  FTextClass3Option.AddTextureClasses;
  FTextClass4Option.AddTextureClasses;
  OptCreate('FKsFromTexture', 'FromPar', FKsFromTextOption);
  FKsFromTextOption.OptionList.Clear;
  FKsFromTextOption.OptionList.Add('FromPar');
  FKsFromTextOption.OptionList.Add('FromTexture');
  OptCreate('rc_Option', 'Kochler', f_rc_Option, 'Option for rc(Psi_leaf)-function');
  f_rc_Option.OptionList.Add('Kochler');
  f_rc_Option.OptionList.Add('Campbell');
  f_rc_Option.OptionList.Add('Reid');
  {f_rc_Option.OptionList.Add('Lohammar');}
  f_rc_Option.OptionList.Add('Gao');
  f_rc_Option.OptionList.Add('Neukam');

  OptCreate('ra_Option', 'ThomOliver', f_ra_Option, 'Option for ra(u,CropHeight)-function');
  f_ra_Option.OptionList.Add('PenmanMonteith');
  f_ra_Option.OptionList.Add('ThomOliver');
  
  OptCreate('rc_upscaling_Option','Stockle', f_rc_upscaling_Option, 'Option for upscaling canopy resistance from stomatal resistance');
  f_rc_upscaling_Option.OptionList.Add('Stockle');
  f_rc_upscaling_Option.OptionList.Add('BenMehrez');
  

  for i := 1 to round(Horindx1.v) do begin
    WPar[i].b_sat := b_sat1.v*bsat_scaling.v;
    WPar[i].b_rest := b_rest1.v;
    WPar[i].alpha := alpha1.v*alpha_scaling.v;
    Wpar[i].n_par := n_par1.v;
    Wpar[i].m_par := 1-1/n_par1.v;
    WPar[i].l_par := 0.5;
    WPar[i].Ks    := Ks1.v;
  end;

  for i := round(Horindx1.v)+1 to round(Horindx2.v) do begin
    WPar[i].b_sat := b_sat2.v*bsat_scaling.v;
    WPar[i].b_rest := b_rest2.v;
    WPar[i].alpha := alpha2.v*alpha_scaling.v;
    Wpar[i].n_par := n_par2.v;
    Wpar[i].m_par := 1-1/n_par2.v;
    WPar[i].l_par := 0.5;
    WPar[i].Ks    := Ks2.v;
  end;

  for i := round(Horindx2.v)+1 to round(Horindx3.v) do begin
    WPar[i].b_sat := b_sat3.v*bsat_scaling.v;
    WPar[i].b_rest := b_rest3.v;
    WPar[i].alpha := alpha3.v*alpha_scaling.v;
    Wpar[i].n_par := n_par3.v;
    Wpar[i].m_par := 1-1/n_par3.v;
    WPar[i].l_par := 0.5;
    WPar[i].Ks    := Ks3.v;
  end;

  for i := round(Horindx3.v)+1 to n_comp+1 do begin
    WPar[i].b_sat := b_sat4.v*bsat_scaling.v;
    WPar[i].b_rest := b_rest4.v;
    WPar[i].alpha := alpha4.v*alpha_scaling.v;
    Wpar[i].n_par := n_par4.v;
    Wpar[i].m_par := 1-1/n_par4.v;
    WPar[i].l_par := 0.5;
    WPar[i].Ks    := Ks4.v;
  end;

  ParCreate('psi_critEvap','[hPa]', 500.0, psi_critEvap);
  StateCreate('CumEvap', '[mm]', 0, true, CumEvap, 'kumulierte aktuelle Evaporation');
  StateCreate('CumInterzept', '[mm]', 0, true, CumInterzept, 'kumulierte Interzeption');
  StateCreate('CumNetRain', '[mm]', 0, true, CumNetRain);
  max_aenderWG := 0.01;   // maximale Wassergehaltsänderung pro Zeitschritt

  for i := 1 to n_comp+1 do
    begin
      Varcreate('WG'+IntTostr(i), '[cm3.cm-3]',0.3, true, theta_arr[i]);
      Theta_arr[i].readFromIniFile := true;
      StateCreate('WGadj'+IntTostr(i), '[cm3.cm-3]',0.3, true, thetaadj_arr[i]);
      thetaadj_arr[i].v := WG_scaling.v * theta_arr[i].v;
      StateCreate('WMenge'+IntTostr(i),'[cm]',thetaadj_arr[i].v*Thick[i], false, WMenge[i]);
      WMenge[i].readFromIniFile := false;
      Wmenge[i].writetoFile := false;
      VarCreate('Psi'+IntTostr(i),'[cm]' , WPar[i].psi_b_f(thetaadj_arr[i].v), true, psi_arr[i]);
      VarCreate('WFlow'+IntTostr(i),'[cm.d-1]' , 0.0, false, Wflow_arr[i]);
      Wflow_arr[i].writeToFile := true;
      VarCreate('intWFlow'+IntTostr(i),'[cm.d-1]' , 0.0, false, intWflow_arr[i]);
      intWflow_arr[i].writeToFile := false;
      VarCreate('Sink'+IntToStr(i), '[cm.d-1]', 0.0, false, Sink_arr[i]);
      VarCreate('rs_'+IntToStr(i), '[cm.d-1]', 0.0, false, rs_arr[i]);
      VarCreate('ri_'+IntToStr(i), '[cm.d-1]', 0.0, false, ri_arr[i]);
    end;
    VarCreate('red_evap', '[]', 1.0, false, red_evap);
    VarCreate('act_evap', '[mm/d]',0.0, false, act_evap);
    VarCreate('act_Drainage', '[mm/d]',0.0, false, act_drainage);
    VarCreate('dt_int', '[d]', 0.1, false, dt);
    dt_alt := dt.v;
    Untere_Randb := ConstContent;
    for i := 1 to n_comp+1  do
      theta_alt[i] := thetaadj_arr[i].v;

  for i := 1 to n_comp+1 do begin
    WMenge[i].v := thetaadj_arr[i].v*Thick[i];
    theta_alt[i] := thetaadj_arr[i].v
  end;
  VarCreate('WG0_30', '[cm3/cm3]', 0.0, false, WG0_30);
  VarCreate('WG30_60', '[cm3/cm3]', 0.0, false, WG30_60);
  VarCreate('WG60_90', '[cm3/cm3]', 0.0, false, WG60_90);
  VarCreate('WG90_120', '[cm3/cm3]', 0.0, false, WG90_120);

  VarCreate('WG0_10', '[cm3/cm3]', 0.0, false, WG0_10);
  VarCreate('WG0_20', '[cm3/cm3]', 0.0, false, WG0_20);
  VarCreate('WG10_30', '[cm3/cm3]', 0.0, false, WG10_30);
  VarCreate('WG20_30', '[cm3/cm3]', 0.0, false, WG20_30);
  VarCreate('WG30_40', '[cm3/cm3]', 0.0, false, WG30_40);
  VarCreate('WG40_60', '[cm3/cm3]', 0.0, false, WG40_60);
  VarCreate('WG60_80', '[cm3/cm3]', 0.0, false, WG60_80);
  VarCreate('WG80_100', '[cm3/cm3]', 0.0, false, WG80_100);
  VarCreate('WG0_100', '[cm3/cm3]', 0.0, false, WG0_100);
  VarCreate('WG60_100', '[cm3/cm3]', 0.0, false, WG60_100);
  VarCreate('ProzNFK0_100', '[%]', 0.0, false, ProzNFK0_100);

  red_evap.v := 1.0;
  act_evap.v := 0.0;
  Untere_Randb := ConstContent;

end;

procedure TSoilWaterET.Init(Var GlobMod: TMod);
var
  i : integer;
  error : boolean;

begin
  Inherited Init(GlobMod);
  max_dt := min(GlobMod.TimeStep,1);
  dt.v := min(GlobMod.TimeStep,0.1);
  dt_alt := dt.v;

  if uppercase(f_rc_Option.Option) = uppercase('Kochler') then f_rc_funct := Kochler;
  if uppercase(f_rc_Option.Option) = uppercase('Campbell') then f_rc_funct := Campbell;
  if uppercase(f_rc_Option.Option) = uppercase('Reid') then f_rc_funct := Reid;
  {if uppercase(f_rc_Option.Option) = uppercase('Lohammar') then f_rc_funct := Lohammar; }
  if uppercase(f_rc_Option.Option) = uppercase('Gao') then f_rc_funct := Gao;
  if uppercase(f_rc_Option.Option) = uppercase('Neukam') then f_rc_funct := Neukam;

  if uppercase(f_ra_Option.Option) = uppercase('PenmanMonteith') then f_ra_funct := PenmanMonteith;
  if uppercase(f_ra_Option.Option) = uppercase('ThomOliver') then f_ra_funct := ThomOliver;
  
  if uppercase(f_rc_upscaling_Option.Option) = uppercase('Stockle') then f_rc_upscaling := Stockle;
  if uppercase(f_rc_upscaling_Option.Option) = uppercase('BenMehrez') then f_rc_upscaling :=BenMehrez;

  If uppercase(FVGParsFromTextOption.Option) = 'FROMPAR' then FVGParsFromTexture := FromPar;
  If uppercase(FVGParsFromTextOption.Option) = 'FROMTEXTURE' then FVGParsFromTexture := FromTexture;
  if uppercase(FKsFromTextOption.Option) = 'FROMPAR' then FKsFromTexture := FromPar;
  if uppercase(FKsFromTextOption.Option) = 'FROMTEXTURE' then FKsFromTexture := FromTexture;
  setTextClassOption(FTextureClass1, FTextClass1Option.Option);
  setTextClassOption(FTextureClass2, FTextClass2Option.Option);
  setTextClassOption(FTextureClass3, FTextClass3Option.Option);
  setTextClassOption(FTextureClass4, FTextClass4Option.Option);

  if FVGParsFromTexture = FromTexture then begin
    for i := 1 to round(Horindx1.v) do if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass1)else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass1);
    for i := round(Horindx1.v)+1 to round(Horindx2.v) do if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass2)else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass2);
    for i := round(Horindx2.v)+1 to round(Horindx3.v) do if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass3)else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass3);
    for i := round(Horindx3.v)+1 to n_comp+1 do if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass4)else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass4);
  end
  else begin   {FVGParsFromTexture = FromPar}
    for i := 1 to round(Horindx1.v) do begin
      WPar[i].b_sat := b_sat1.v*bsat_scaling.v;
      WPar[i].b_rest := b_rest1.v;
      WPar[i].alpha := alpha1.v*alpha_scaling.v;
      Wpar[i].n_par := n_par1.v;
      Wpar[i].m_par := 1-1/n_par1.v;
      WPar[i].l_par := 0.5;
      WPar[i].Ks    := Ks1.v;
    end;

    for i := round(Horindx1.v)+1 to round(Horindx2.v) do begin
      WPar[i].b_sat := b_sat2.v*bsat_scaling.v;
      WPar[i].b_rest := b_rest2.v;
      WPar[i].alpha := alpha2.v*alpha_scaling.v;
      Wpar[i].n_par := n_par2.v;
      Wpar[i].m_par := 1-1/n_par2.v;
      WPar[i].l_par := 0.5;
      WPar[i].Ks    := Ks2.v;
    end;

    for i := round(Horindx2.v)+1 to round(Horindx3.v) do begin
      WPar[i].b_sat := b_sat3.v*bsat_scaling.v;
      WPar[i].b_rest := b_rest3.v;
      WPar[i].alpha := alpha3.v*alpha_scaling.v;
      Wpar[i].n_par := n_par3.v;
      Wpar[i].m_par := 1-1/n_par3.v;
      WPar[i].l_par := 0.5;
      WPar[i].Ks    := Ks3.v;
    end;

    for i := round(Horindx3.v)+1 to n_comp+1 do begin
      WPar[i].b_sat := b_sat4.v*bsat_scaling.v;
      WPar[i].b_rest := b_rest4.v;
      WPar[i].alpha := alpha4.v*alpha_scaling.v;
      Wpar[i].n_par := n_par4.v;
      Wpar[i].m_par := 1-1/n_par4.v;
      WPar[i].l_par := 0.5;
      WPar[i].Ks    := Ks4.v;
    end;
  end;

  if FKsFromTexture = FromTexture then
  begin
    for i := 1 to round(HoriNdx1.v) do
     if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass1) else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass1);
    for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass2) else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass2);
    for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass3) else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass3);
    for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass4) else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass4);
  end;

  for i := 1 to n_comp+1 do begin
    case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine: WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken: WPar[i].m_par := 1;
      end;
  end;


  if self.Opt_IniMethod  = WaterContents then begin
    for i := 1 to n_comp+1 do begin
      thetaadj_arr[i].v := WG_scaling.v * theta_arr[i].v;
      psi_arr[i].v := WPar[i].psi_b_f(WG_scaling.v * theta_arr[i].v);
      globmod.StateIniFile.WriteFloat(self.name, psi_arr[i].name, psi_arr[i].v);
      WMenge[i].v := Thetaadj_arr[i].v*Thick[i];
      theta_alt[i] := thetaadj_arr[i].v
    end
  end else if self.Opt_IniMethod = Potentials then begin
    for i := 1 to n_comp+1 do begin
      psi_arr[i].v := globmod.StateIniFile.ReadFloat(self.name, psi_arr[i].name, 100);
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      globmod.StateIniFile.WriteFloat(name, theta_arr[i].name, theta_arr[i].v);
      WMenge[i].v := Theta_arr[i].v*Thick[i];
      theta_alt[i] := theta_arr[i].v
    end
  end else if self.Opt_IniMethod = Parameter then begin
    for i := 1 to n_comp+1 do begin
      psi_arr[i].v := PsiStart1.v;
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      globmod.StateIniFile.WriteFloat(name, theta_arr[i].name, theta_arr[i].v);
      WMenge[i].v := Theta_arr[i].v*Thick[i];
      theta_alt[i] := theta_arr[i].v
    end;
  end;

  red_evap.v := 1.0;
  act_evap.v := 0.0;
  CumEvap.v  := 0.0;
  CumInterzept.v := 0.0;
  Untere_Randb := ConstContent;

  If round(Horindx1.v) = 0 then begin
    showmessage('Warning ! No specification of Indexes for hydraulic parameters');
    showmessage('Please check !');
  end;


  If Opt_nFKCalcMethod = FromParameter then begin
{Berechnung von FK, PWP und nFK aus van-Genuchten-Parametern mit der Funktion b_psi_f (unit UGenucht)}
    Par_FK1.v := WPar[round(Horindx1.v)].b_psi_f (power(10, 1.8));
    Par_PWP1.v := WPar[round(Horindx1.v)].b_psi_f (power(10,4.2));
    Par_nFK1.v := Par_fk1.v-par_PWP1.v;

    Par_FK2.v := WPar[round(Horindx2.v)].b_psi_f (power(10, 1.8));
    Par_PWP2.v := WPar[round(Horindx2.v)].b_psi_f (power(10,4.2));
    Par_nFK2.v := Par_fk2.v-par_PWP2.v;

    Par_FK3.v := WPar[round(Horindx3.v)].b_psi_f (power(10, 1.8));
    Par_PWP3.v := WPar[round(Horindx3.v)].b_psi_f (power(10, 4.2));
    Par_nFK3.v := Par_fk3.v-par_PWP3.v;

    Par_FK4.v := WPar[round(Horindx4.v)].b_psi_f (power(10, 1.8));
    Par_PWP4.v := WPar[round(Horindx4.v)].b_psi_f (power(10, 4.2));
    Par_nFK4.v := Par_fk4.v-par_PWP4.v;
  end;

{Berechnung der abgeleiteten Wassergehalte für verschiedene Bodenschichten}
  WG0_30.v := 0.0;
  WG30_60.v := 0.0;
  WG60_90.v := 0.0;
  WG90_120.v := 0.0;
  for i := 1 to 3 do begin
    WG0_30.v := WG0_30.v+ thetaadj_arr[i].v;
    WG30_60.v := WG30_60.v+ thetaadj_arr[3+i].v;
    WG60_90.v := WG60_90.v+ thetaadj_arr[6+i].v;
    WG90_120.v := WG90_120.v+ thetaadj_arr[9+i].v;
  end;
  WG0_30.v := WG0_30.v/3;
  WG30_60.v := WG30_60.v/3;
  WG60_90.v := WG60_90.v/3;
  WG90_120.v := WG90_120.v/3;
  WG0_10.v := thetaadj_arr[1].v;
  WG0_20.v := (thetaadj_arr[1].v + thetaadj_arr[2].v)/2;
  WG10_30.v := (thetaadj_arr[2].v + thetaadj_arr[3].v)/2;
  WG20_30.v := thetaadj_arr[3].v;
  WG30_40.v := thetaadj_arr[4].v;
  WG40_60.v := (thetaadj_arr[5].v + thetaadj_arr[6].v)/2;
  WG60_80.v := (thetaadj_arr[7].v + thetaadj_arr[8].v)/2;
  WG80_100.v := (thetaadj_arr[9].v + thetaadj_arr[10].v)/2;
  WG0_100.v := 0;
  for i := 1 to 10 do WG0_100.v := WG0_100.v + thetaadj_arr[i].v;
  WG0_100.v := WG0_100.v/10;
  WG60_100.v := 0;
  for i := 7 to 10 do WG60_100.v := WG60_100.v + thetaadj_arr[i].v;
  WG60_100.v := WG60_100.v/4;

  for i := 1 to n_comp do begin
    FK_arr[i] := WPar[i].b_psi_f (power(10, 1.8));
    PWP_arr[i] := Wpar[i].b_psi_f (power(10, 4.2));
    nFK_arr[i] := fk_arr[i]-pwp_arr[i];
  end;

  CumDrainage.c := 0;
end;


Procedure TSoilWaterET.CalcSinks;
begin
  intWflow_arr[1].v := -0.1*Act_Evap.v/GlobMod.TimeStep + 0.1*NetRain.v/GlobMod.TimeStep;
  {0.1* für Umrechnung mm -> cm
   /GlobMod.TimeStep für Umrechnung mm/TimeStep -> mm/d}
  CumNetRain.c := NetRain.v/GlobMod.TimeStep;
end;

function TSoilWaterET.rc_f:real;

const
  rc_min  = 20.0;  { minimaler Stomatawiderstand [s/m] }
  stom_sw = -0.8;  { Stomataschwellenwert [MPa] }
  stom_sens = 0.6; { Stomatasensitivit„t []   }

var
  pressure : real;
  rs, //dn (30.07.12)
  gs : real;

begin
  if lai.v > 0.0 then begin
    case f_rc_funct of

      Kochler: begin
        rstom.v := rs_voll.v/(1+(rs_voll.v/rc0.v{rs_null.v}-1)*EXP(-mkf.v*psi_leaf.v/10000));  {/lai.v Kochler}
		    result:= rc_upscaling_f(rstom.v, f_rc_upscaling);
      end;

      Campbell: begin
        result := 10*(1+power((psi_leaf.v/p_Campbell.v),3))/lai.v; //{Campbell} von Ulf eingefügt
      end;

      Reid:  //Reid 1991
      begin
        result := exp(p_Reid_int.v - Sat_Def.v*psi_leaf.v*p_Reid_slope.v)/LAI.v;
      end;

      Gao: // dn (20.07.) Gao et al. 2002
      begin
        pressure      := pressure_f ( Elev.v, TMPM.v);
        gs := (p_Gao_1.v+p_Gao_2.v*power(10,psiRoot.v)+p_Gao_3.v*netRad.v)/(1+p_Gao_4.v*Sat_def.v/ pressure)  ;
        rstom.v := 1/(gs/1000*(8.314*(TMPM.v+273.15)/(pressure*100) ));
		    result:= rc_upscaling_f(rstom.v, f_rc_upscaling);
      end;

      {Lohammar:  // Lohammar et al. 1980 nach Heidmann et al. 2000
      begin
        result := 1/(GlobRad.v/(GlobRad.v+p_Lohammar_R0.v)*p_Lohammar_gm.v/(1+Sat_Def.v*100/p_Lohammar_b.v))/LAI.v;
      end;   }


      Neukam:   {dn (06.07.12) Stomatafunktion abhängig von Nettostrahlung, Lufttemperatur, Bodenwasserpotenzial im Wurzelraum, Sättigungsdefizit
                      gemeinsamer Schnittpunkt der Geraden (psiRoot bei Feldkapazität| minimaler Stomatawiderstand) }
      begin
        if netRad.v<rc_par_e.v then rs_Rn.v := rc_par_f.v*sqr(netRad.v-rc_par_e.v)+rc0.v else rs_Rn.v := rc0.v;
        //dn (24.07.12) andere Ansätze probiert Jarvis: rs_Rn.v := 1/(rc_par_e.v*rc_par_f.v*(netRad.v+100-rc_par_d.v)/(rc_par_e.v+rc_par_f.v*(netRad.v+100-rc_par_d.v)));// Irmak: rc_par_e.v*power(netRad.v+rc_par_f.v,rc_par_d.v);
        rs_T.v := rc0.v + rc_par_h.v*sqr(25-TMPM.v) ;
        rs_VPD.v := rc0.v - (rc_par_a.v+rc_par_b.v*Sat_def.v)*(rc_par_s.v-power(10,psiRoot.v));
        rs := max(max(rs_Rn.v, rs_T.v), rs_VPD.v);
        gstom.v := 100/(r_fact.v*rs) ;     //dn (30.07.12) gstom [cm/s]
        rstom.v := 1/(g_fact.v*gstom.v/100) ;
        result:= rc_upscaling_f(rstom.v, f_rc_upscaling);
        end;

   end;
  end
  else result := rc0.v{rs_null.v};
end;

function TSoilWaterET.rc_upscaling_f ( rs_leaf :real; upscaling_opt: T_rc_upscaling): real;


begin
  case f_rc_upscaling of
  Stockle:
   {Berechnung des Canopy-Widerstandes aus dem Stomata-Widerstand auf Blattebene
 mit einem Ansatz von Stockle (personal communication)}
      begin
      result:= rs_leaf;
        if (lai.v >= 1.0) and (lai.v < 2) then result := rs_leaf/lai.v
        else if (lai.v >= 2.0) and (lai.v < 6) then result := rs_leaf/2-(rs_leaf/2-rs_leaf/3)*((lai.v-2)/4)
        else if (lai.v >= 6) then result := rs_leaf/3;
        If result < 0.1 then result := 0.1;
      end;
  BenMehrez:
  {Berechnung des Canopy-Widerstandes aus dem Stomata-Widerstand auf Blattebene
 mit dem Shelter-Faktor-Ansatz (Berücksichtigung der Beschattung der unteren Blattetagen)nach Ben Mehrez et al. (1992),  Mascart et al. 1991,
 Alfieri et al., 2008, Hatfield and Allen (1996), Amer and Hatfield  (2004)}
  begin
  if LAI.v > 0 then

        result := (0.3 *lai.v+1.2)/lai.v * rs_leaf
  else result := rs_leaf;
  result := min(result, rs_leaf);
  end;

  end;
 end;

function TSoilWaterET.r_soil_f ( lrv, a, K, dz : real):real;
{ Funktion zur Berechnung des Bodenwiderstandes [d] }
{ Parameter:
  Lrv      Wurzellängendichte                  [cm/cm-3]
  a        Mittlerer Wurzeldurchmesser         [cm]
  K        hydraulische Leitfähigkeit          [cm/d]
  dz       Thick des Kompartiments             [cm]    }
var
  x : real;       { mittlerer halber Wurzelabstand [cm] }
begin
  x := 1/sqrt(pi*lrv);
  result := ln(x/(2.1*a))/(2*pi*k*lrv*dz);
end;


function TSoilWaterET.r_interf_f( Rrr, theta, theta_s, Lrv, dz:real):real;
begin
  if (theta > 0) and (lrv>0) then
    r_interf_f := Rrr*(theta_s/theta)/(lrv*dz)  {Reid and Huck 1990}
  else
    r_interf_f := 1e99;
end;


Procedure TSoilWaterET.CalcEvap_red_f;
{ ********************************************************************** }
{ Zweck : Ermittlung eines Reduktionsfaktors der die potentielle
          Evaporation um den Einfluá einer geringen Bodenfeuchte an der
          Bodenfläche korrigiert

  Parameter :

    Name             Inhalt                          Einheit      Typ

    Psi              Bodenwasserspannung im          [cm]         I
                     obersten Kompartimente (10 cm Tiefe)

    red_f,           Reduktionsfaktor der            [-]           O
      Red_Evap.v     potentiellen Evaporation
{ ********************************************************************** }

var
  red_f : real;
  pF_5  : real;

begin
  if psi_arr[1].v> 0.0 then begin
    pf_5 := log10(psi_arr[1].v);
    red_f := -1*(pf_5-4.2)/(4.2-log10(psi_critEvap.v))
//    red_f := -0.5767*log10(psi_arr[1].v)+1.78
  end
  else red_f := 0.0;
  If red_f > 1.0 then red_f := 1.0;
  If red_f < 0.0 then red_f := 0.0;
  Red_Evap.v := red_f;
end;


procedure TSoilWaterET.Integrate;
begin
  inherited;
end;


procedure TSoilWaterET.CalcRates;
var
  pressure,           // Luftdruck [mbar]
  gamma,
  es,       // Sättigungsdampfdruck [mbar]
  delta
          : real;
  i: integer;

const
  cp = 1003.0;      { spezifische W„rme der Luft [J/(Kg*K)] }

begin
  psiRoot.v := getPsiRoot;

  If LAI.v < 1.0 then rc.v := rc0.v
  else if (lai.v >= 1.0) and (lai.v < 2) then rc.v := rc0.v/lai.v
  else if (lai.v >= 2.0) and (lai.v < 6) then
    rc.v := rc0.v/2-(rc0.v/2-rc0.v/3)*((lai.v-2)/4)
  else rc.v := rc0.v/3;
  If rc.v < 0.1 then rc.v := 0.1;
  

  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstahlung (W/m2)
  netRad.v      := 0.6494*(GlobRad.v) - 18.417;//max(0,0.6494*(GlobRad.v) - 18.417);
  pressure      := pressure_f ( Elev.v, TMPM.v);
  gamma         := cp*pressure/(0.622*(2.502*1000000-2361*TMPM.v)); //  statt gamma := Pressure*Psycro :  (dn 10.06.14)
                                                                    //  0.622  ist Molmassenverhältnis von Wasser und Luft , Klammer im Nenner berechnet Verdunstungsenthalpue von Wasser
  es            := sat_vap_press_f ( TMPM.v);

  delta         := delta_f (es, TMPM.v );
  if cropHeight.v <= 0.0 then ra.v := ra_f (wind_speed.v, 0.05)
                         else ra.v := ra_f (wind_speed.v, CropHeight.v);
  pETP.v := Penman(TMPM.v, Sat_def.v, NetRad.v, delta, gamma, l_h_v_water, ra.v, rc.v);
  Pot_Evap.v   := Evaporation_f;
  pTI           := pETP.v - pot_Evap.v;

  Interzeption_p;

  If pETP.v > 0.0 then pot_trans.v    := (pETP.v-Pot_Evap.v-Interzeption.v)
                  else Pot_Trans.v  := 0.0;
  If pot_Trans.v < 0.0 then pot_Trans.v := 0.0;
  CumEvap.c  := Act_Evap.v/GlobMod.TimeStep;
  CumInterzept.c := Interzeption.v/GlobMod.TimeStep;
  CalcWGs;
end;


procedure TSoilWaterET.CalcRatesAndIntegrate;
var
  i : integer;
begin
//  CalcEvap_red_f;
  CalcSinks;
//  Act_Evap.V := Pot_evap.v*Red_Evap.v;
//  CumEvap.c  := Act_Evap.v/GlobMod.TimeStep;

  If CompMethod = Capacity then CapWatSolut;       // Kapazitätsbasiertes Modell
  If CompMethod = Diffusion then Diffwater_solut;  //Potentialbasiertes Modell
end;


procedure TSoilWaterET.CapWatSolut;
{const
  rep : boolean = false;}
var
  psiWP,
  psiFK   : real;
  WCap    : TSoilArray;
  i       : byte;
  rep : boolean;
begin
  if rep = false then begin
    { Berechnung der Wasserspannungen [cm] bei Feldkapazit„t bzw. beim
      permanenten Welkepunkt }
    psiWP := power(10, 4.2);
    psiFK := power(10, 1.8);

    If nFKCalcMethod = input then begin
      If HoriNdx1.v = 0 then begin
        showmessage('Warning ! No specification of Indexes for hydraulic parameters');
        showmessage('Please check !');
      end;

      for i := 1 to round(HoriNdx1.v) do begin
        FK_arr[i]  := par_FK1.v;
        PWP_Arr[i] := par_PWP1.v;
        nFK_arr[i] := par_fk1.v-par_PWP1.v;
      end;
      for i := round(HoriNdx1.v)+1 to round(HoriNdx2.v) do begin
        FK_arr[i]  := par_FK2.v;
        PWP_Arr[i] := par_PWP2.v;
        nFK_arr[i] := par_fk2.v-par_PWP2.v;
      end;
      for i := round(HoriNdx2.v)+1 to round(HoriNdx3.v) do begin
        FK_arr[i]  := par_FK3.v;
        PWP_Arr[i] := par_PWP3.v;
        nFK_arr[i] := par_fk3.v-par_PWP3.v;
      end;
      for i := round(HoriNdx3.v)+1 to n_comp+1 do begin
        FK_arr[i]  := par_FK4.v;
        PWP_Arr[i] := par_PWP4.v;
        nFK_arr[i] := par_fk4.v-par_PWP4.v;
      end;
    end
    else begin
      for i := 1 to n_comp do begin
        FK_arr[i] := WPar[i].b_psi_f (psiFK);
        PWP_arr[i] := Wpar[i].b_psi_f (psiWP);
        nFK_arr[i] := fk_arr[i]-pwp_arr[i];
        WMenge[i].v := thetaadj_arr[i].v*Thick[i];
      end;
    end;
    rep := true;
  end; { Ende Initialisierungssequenz }

  dt.v := GlobTime.c;  // bei Kapazitätswassermodell immer Zeitschritt des globalen
                       // Modells

  for i := 1 to n_comp+1 do begin
    thetaadj_arr[i].v := Wmenge[i].v/Thick[i];
    intWflow_arr[i].v := 0.0;
    theta_alt[i] := thetaadj_arr[i].v;
    Wflow_alt[i]  := intWflow_arr[i].v;
  end;

  if (Netrain.v > 0.0) then begin
    intWflow_arr[1].v := netrain.v*0.1/Globmod.TimeStep;
    for I := 1 to n_comp do begin
      WCap[i] := (FK_arr[i]-thetaadj_arr[i].v)*Thick[i];
      If (WCap[i] < intWflow_arr[i].v) then begin       // Saturation ?
        thetaadj_arr[i].v := FK_arr[i];
        intWflow_arr[i+1].v := intWflow_arr[i].v-WCap[i];
      end else begin
        thetaadj_arr[i].v := thetaadj_arr[i].v+intWflow_arr[i].v/Thick[i]*GlobTime.c;
        intWflow_arr[i+1].v := 0.0;
      end;
    end;
  end;
  // evaporation
  thetaadj_arr[1].v := thetaadj_arr[1].v - 0.1*act_evap.v/Thick[1]*GlobTime.c;

  //   water uptake of plant roots
  for i := 1 to n_comp do begin
    thetaadj_arr[i].v := thetaadj_arr[i].v - sink_arr[i].v/Thick[i]*GlobTime.c;
    psi_arr[i].v   := Wpar[i].psi_b_f(thetaadj_arr[i].v);
  end;
end;             { procedure CapWatSolut }


procedure TSoilWaterET.CalcWGs;
var
  i: integer;
  OldSumSoilwater : real;
  nFK0_100, PWP0_100: real;
begin
  WG0_30.v := 0.0;
  WG30_60.v := 0.0;
  WG60_90.v := 0.0;
  WG90_120.v := 0.0;
  for i := 1 to 3 do begin
    WG0_30.v := WG0_30.v+ thetaadj_arr[i].v;
    WG30_60.v := WG30_60.v+ thetaadj_arr[3+i].v;
    WG60_90.v := WG60_90.v+ thetaadj_arr[6+i].v;
    WG90_120.v := WG90_120.v+ thetaadj_arr[9+i].v;
  end;
  WG0_30.v := WG0_30.v/3;
  WG30_60.v := WG30_60.v/3;
  WG60_90.v := WG60_90.v/3;
  WG90_120.v := WG90_120.v/3;

  WG0_10.v := thetaadj_arr[1].v;
  WG0_20.v := (thetaadj_arr[1].v + thetaadj_arr[2].v)/2;
  WG10_30.v := (thetaadj_arr[2].v + thetaadj_arr[3].v)/2;
  WG20_30.v := thetaadj_arr[3].v;
  WG30_40.v := thetaadj_arr[4].v;
  WG40_60.v := (thetaadj_arr[5].v + thetaadj_arr[6].v)/2;
  WG60_80.v := (thetaadj_arr[7].v + thetaadj_arr[8].v)/2;
  WG80_100.v := (thetaadj_arr[9].v + thetaadj_arr[10].v)/2;
  WG0_100.v := 0;
  for i := 1 to 10 do WG0_100.v := WG0_100.v + thetaadj_arr[i].v;
  WG0_100.v := WG0_100.v/10;
  WG60_100.v := 0;
  for i := 7 to 10 do WG60_100.v := WG60_100.v + thetaadj_arr[i].v;
  WG60_100.v := WG60_100.v/4;

  nFK0_100 := 0;
  PWP0_100 := 0;
  For i := 1 to 10 do begin
    nFK0_100 := nFK0_100 + nFK_Arr[i];
    PWP0_100 := PWP0_100 + PWP_Arr[i];
  end;
  ProzNFK0_100.v := (WG0_100.v-PWP0_100/10)/nFK0_100*1000;

  OldSumSoilWater := SumSoilwater.v;
  SumSoilwater.v := 0.0;
  SumPavSoilWater.v := 0.0;
  for i := 1 to trunc(bil_nr.v) do begin
    SumSoilwater.v := SumSoilWater.v + Wmenge[i].v*10;
    SumPAVSoilWater.v := SumPAVSoilwater.v + Wmenge[i].v*10-PWP_Arr[i]*Thick[i]*10;
  end;
  If GlobTime.v > GlobMod.Starttime then begin
    CumDrainage.c := Act_Drainage.v;

    Act_Drainage.v := Wflow_arr[trunc(bil_nr.v)+1].v*10*GlobTime.c;
    CumDrainage.c := {CumDrainage.c +} Wflow_arr[trunc(bil_nr.v)+1].v*10;
    CumWaterBalance.c := (SumSoilWater.v-OldSumSoilWater)/GlobTime.c-CumNetRain.c+CumDrainage.c+CumEvap.c{+CumRunoff.c};
//    ActWaterBalance.v := (SumSoilWater.v-OldSumSoilWater) - NetRain.v - Act_Drainage.v - Act_Evap.v;
    ActWaterBalance.v := CumWaterBalance.c*GlobTime.c;
  end;
end;

procedure TSoilWaterET.get_water_contents;
var
  i : byte;
begin
  for i := 1 to n_comp+1 do begin
    thetaadj_arr[i].v := Wmenge[i].v/Thick[i];
    theta_neu[i] := thetaadj_arr[i].v;
  end;
end;

function TSoilWaterET.getPsiRoot: extended;
begin
  result := psi_arr[1].v;
end;



Procedure TSoilWaterET.Diffwater_solut;
const
  max_iter_error = 0.0001;
var
  sum_aender,
  sum_net_flow,
  delt_iter_max   : real;

  iter  : integer;
  result,
  start    : byte;
  wet,                  { S„ttigung im obersten Kompartiment ? }
  dry,                  { Wassergehalt kleiner b_rest im obersten Komp.? }
  success               { Flag-Variable fr fehlerfreie Ausfhrung }
   : boolean;


  procedure Leitfaehigkeiten;
  var
    i         : byte;
  begin
    { lineare Extrapolation der Wassergehalte bei der ersten Iteration }
    If Iter = 0 then begin
      for i := 1 to n_comp do
        est_theta[i+1] := 0.5*(1+dt.v/(2*dt_alt))*(thetaadj_arr[i].v+thetaadj_arr[i+1].v)
                         -0.25*dt.v/dt_alt*(theta_alt[i]+theta_alt[i+1]);

      For i := 2 to n_comp+1 do begin
        avg_Dw[i] := Wpar[i].Dw_f(est_theta[i]);
        avg_Ku[i] := WPar[i].Ku_b_f(est_theta[i]);
      end;

      for i := 2 to n_comp+1 do begin
        Dw_fact[i] := avg_Dw[i]*dt.v/Dist[i-1];
        Ku_fact[i] := avg_Ku[i]*dt.v;
      end;
    end
    else begin
  { Berechnung der Wasserdiffusivit„t und der unges„ttigten hydraulischen
    Leitf„higkeit fr jedes Kompartiment aus dem Mittelwert der Wassergehalte
    zu Beginn des Zeitschrittes und zum Ende des Zeitschrittes }
      For I := 1 to n_comp+1 do begin
        Dw_arr[i] := WPar[i].Dw_f((theta_neu[i]+thetaadj_arr[i].v)/2.0);
        Ku_arr[i] := WPar[i].Ku_b_f ( (theta_neu[i]+thetaadj_arr[i].v)/2.0);
      end;
  { Berechnung des Mittelwertes der Leitf„higkeit zwischen 2 Kompartimenten }
      For I := 2 to n_comp+1 do begin
        avg_Dw[i] := (Dw_arr[i-1] + Dw_arr[i] )/2.0;
        avg_Ku[i] := (Ku_arr[i-1] + Ku_arr[i] )/2.0;
      end;
      { Berechnung von Koeffizienten fr die Aufstellung des Gleichungssystems,
        Dist.vektor mit dem Index i-1, weil Distand zwischen erstem und
        zweiten Kompartiment Index 1 hat (verschobene Indizierung }
      For I := 2 to n_comp+1 do begin
        Dw_fact[i] := avg_Dw[i]*dt.v/Dist[i-1];
        Ku_fact[i] := avg_Ku[i]*dt.v;
      end;
    end;
  end;

  Procedure obere_Randbedingung;
  const
    dWg = 1e-8;
  { zur Verhinderung von ungltigen Funktionsaufrufen wird zuerst
    eine Prfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
    "Restwassergehalt b_rest" oder ein Ansteigen ber den "S„ttigungs-
    wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prfung wird
    in den Variablen "Wet", bzw. "Dry" gespeichert. }
  begin
    dry := false; wet := false; success := false;

    If (Theta_neu[1] >  Wpar[1].b_sat) and (intWflow_arr[1].v > 0.0) then
      wet := true;  success := false; { Prüfung auf Sättigung }

    If (Theta_neu[1] < WPar[1].b_rest) and (intWflow_arr[1].v < 0.0 ) then
        dry := true; success := false; { Prüfung auf PWP }

    If wet then begin
      b_vektor[1]  := WPar[1].b_sat-dWG;
      thetaadj_arr[1].v := WPar[1].b_sat-dWG;
      theta_neu[1] := WPar[1].b_sat-dWG;
      Start        := 2;
    end;

    If dry then begin
      b_vektor[1] := WPar[1].b_rest+dWG;
      thetaadj_arr[1].v:= WPar[1].b_rest+dWG;
      theta_neu[1]:= WPar[1].b_rest+dWG;
      start       := 2;
    end;

    If (not wet) and (not dry) then begin
      success := true;
      start := 1;
      B_vektor[1] := thetaadj_arr[1].v
                     + intWflow_arr[1].v*dt.v/Thick[1] - Ku_fact[2]/Thick[1]
                     - sink_arr[1].v*dt.v/Thick[1];
      Diag[1]     := Dw_fact[2]/Thick[1] + 1.0;
      Upper[1]    :=  - Dw_fact[2]/Thick[1];
    end;
  end;

  Procedure Mittelteil;
  var
    i : integer;

  begin
       For i := start+1 to n_comp-1 do begin
         B_vektor[i]  :=  thetaadj_arr[i].v
                          - ku_fact[i+1]/Thick[i]
                          + ku_fact[i]/Thick[i]
                          - sink_arr[i].v*dt.v/Thick[i];
         Lower[i] :=   - Dw_fact[i]/Thick[i];
         Diag[i]  :=     Dw_fact[i]/Thick[i] + Dw_fact[i+1]/Thick[i] + 1.0;
         Upper[i] :=   - Dw_fact[i+1]/Thick[i];
       end;
  end;

  procedure untere_Randbedingung;

  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  var
    drain_flow : real;

  begin
      If untere_Randb = ConstContent then
                           { Gehalts-Randbedingung }
        B_vektor[n_comp]  := thetaadj_arr[n_comp].v
                            + ku_fact[n_comp]/Thick[n_comp]
                            - ku_fact[n_comp+1]/Thick[n_comp+1]
                            + Dw_fact[n_comp+1]*thetaadj_arr[n_comp+1].v/Thick[n_comp+1]
                            - sink_arr[n_comp].v*dt.v/Thick[n_comp]
      else
                           { Fluß-Randbedingung }
      B_vektor[n_comp]  := thetaadj_arr[n_comp].v
                           + ku_fact[n_comp]/Thick[n_comp]
                           - intWflow_arr[n_comp+1].v/Thick[n_comp]
                           - sink_arr[n_comp].v*dt.v/Thick[n_comp];

      Lower[n_comp]     := - Dw_fact[n_comp]/Thick[n_comp];
      Diag[n_comp]      :=   Dw_fact[n_comp]/Thick[n_comp]
                             + Dw_fact[n_comp+1]/Thick[n_comp+1]
                             + 1.0;
  end;


  procedure Loesung_Gleichungssystem;

  var
    I : byte;

  begin
    result := trdiag (false, n_comp, start, lower,  diag, upper, b_vektor);
    If result <> 0 then
      ShowMessage( 'Fehler beim Lösen des Gleichungssystems');

    For I := Start to n_comp do begin
      last_iter_theta[i] := theta_neu[i];
      theta_neu[i] := b_vektor[i];
      If theta_neu[i] > Wpar[i].b_sat then theta_neu[i]  := Wpar[i].b_sat;
      If theta_neu[i] < Wpar[i].b_rest then Theta_neu[i] := Wpar[i].b_rest;
    end;
  end;


  procedure Find_flows;
  var
    i : byte;
  begin
    if FDebug then writeValues(false, 'FindFlows Anfang');
    If untere_Randb = ConstContent then begin
      For I := 2 to n_comp+1 do begin
        intWflow_arr[i].v := avg_Dw[i]*(theta_neu[i-1] - theta_neu[i])/Dist[i-1]
                       + avg_Ku[i];
        Wflow_alt[i] := avg_Dw[i]*(theta_alt[i-1] - theta_alt[i])/Dist[i-1]
                       + avg_Ku[i];
      end;
    end else begin
      For I := 2 to n_comp do begin
        intWflow_arr[i].v := avg_Dw[i]*(theta_neu[i-1] - theta_neu[i])/Dist[i-1]
                       + avg_Ku[i];
        Wflow_alt[i]   := avg_Dw[i]*(theta_alt[i-1] - theta_alt[i])/Dist[i-1]
                       + avg_Ku[i];
      end;
      {WFlow_arr[n_comp+1] := 0.0;
      flow_alt[n_comp+1] := 0.0;}
    end;

    If (dry and (intWflow_arr[1].v < intWflow_arr[2].v)) or
       (wet and (intWflow_arr[1].v > intWflow_arr[2].v)) then begin
      intWflow_arr[1].v := intWflow_arr[2].v;
      WFlow_alt[1] := WFlow_alt[2];
    end;
    if FDebug then writeValues(false, 'FindFlows Ende');
  end;



  procedure get_bilanz ;
  { ********************************************************************** }
  { Zweck : Berechnung der Massenbilanz und der maximalen Wassergehalts-
            „nderung im Simulationszeitschritt

    Parameter :

      Name             Inhalt                          Einheit      Typ
      w_rec            Record mit den Wasserdaten                    I
                       ( siehe Typdefinitionen )
      geo_rec          Record mit den Geometriedaten                 I
      comps            Zahl der Kompartimente           [-]          I

      max_d_WaGe       maximale Wassergehalts„nderung   [cm3/cm3]    O }

  { ********************************************************************** }

  var
    i : byte;

    net_flow,              { Netto-Fluss                       [cm] }
    d_WaMe,                { Änderung der Wassermenge
                             im Kompartiment                   [cm] }
    d_WaGe,                { Änderung des Wassergehaltes
                             im Kompartiment                   [cm3/cm3] }
    sum_d_WaMe,            { Summe der Wassermengenänderungen  [cm] }
    sum_sink,              { Summe der Sink-Terme              [cm] }
    max_bilanzfehler       { maximaler Bilanzfehler            [cm] }
                    : real;

    Bilanz_f_arr    : TSoilArray;

  begin
     maxAktAenderWaGe:= 0.0;
     sum_d_WaMe      := 0.0;
     sum_sink        := 0.0;
     akt_bilanz_f    := 0.0;
     For I := 1 to n_comp do begin
       net_flow        := (intWflow_arr[i].v - intWflow_arr[i+1].v)*dt.v;
       d_WaMe          := (thetaadj_arr[i].v-theta_neu[i])*Thick[i];
       d_WaGe          := thetaadj_arr[i].v-theta_neu[i];
       Bilanz_f_arr[i] := d_WaMe + net_flow - Sink_arr[i].v*dt.v;
       akt_bilanz_f    := akt_bilanz_f + Bilanz_f_arr[i];
       If abs(d_WaGe) > maxAktAenderWaGe then
              maxAktAenderWaGe := abs(d_WaGe);
       sum_d_WaMe   := sum_d_WaMe + d_WaMe;
       sum_sink     := sum_sink + sink_arr[i].v*dt.v;
       if FDebug then writeDebug(i,dt.v,intWflow_arr[i].v,intWflow_arr[i+1].v,Sink_arr[i].v,Thick[i],thetaadj_arr[i].v,theta_neu[i],Bilanz_f_arr[i]);
     end;
     sum_Bilanz_f   := sum_bilanz_f + akt_bilanz_f;
  end;


  procedure get_new_dt;
  { ********************************************************************** }
  { Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verhältnisses
             der maximal erlaubten Wassergehaltsänderung zur maximalen aktuellen
             Wassergehaltsänderung

    Parameter :

      Name             Inhalt                          Einheit      Typ

      max_aender       maximal erlaubte Žnderung       [cm3/cm3]    I
                       der Wassergehalte in einem
                       Zeitschritt

      akt_aender       maximale Änderung des Wasser-   [cm3/cm3]    I
                       gehaltes in einem Kompartiment
                       im letzten Zeitschritt

      dt               Zeitschrittweite                [d]          O
      dt_alt           letzte Zeitschrittweite         [d]          O }

  { ********************************************************************** }

  var
    dt_neu : real;

  begin
    If max(MaxaktAenderWaGe, NetRain.v *dt.v/GlobTime.c /(Thick[1]*10)) <> 0.0 then begin
      dt_alt := dt.v;              { Speicherung der alten Zeitschrittweite }

                { Verhältnis der erlaubten zur aktuellen Wassergehaltsänderung }
      dt_neu := (max_aenderWG/max(MaxaktAenderWaGe, NetRain.v*dt.v/GlobTime.c /(Thick[1]*10)))*dt.v;

      If dt_neu > max_dt then dt_neu := max_dt; { Zu großer Zeitschritt ? }
      if dt_neu > 1.5*max(dt_alt,dt.v) then dt_neu := max(dt_alt,dt.v)*1.5; { Zu großer Zeitschrittsprung ?}
      { Der folgende Algorithmus wurde eingefügt, um Diskontinuitäten bei der
        Verwendung von Eingabedaten auf täglicher Basis zu vermeiden. }
      If SumOfInternalTimeSteps+Dt_neu > GlobTime.c then begin { Ende des Tages überschritten mit neuem Zeitschritt ? }
        dt_neu := (GlobTime.c - SumOfInternalTimeSteps);
      end;
      dt_alt := dt.v;              { Speicherung der alten Zeitschrittweite }
      dt.v := dt_neu;
    end;
  end;


  procedure get_delt_iter_max;
  {Zweck : Berechnung des maximalen Wassergehaltsunterschiedes in einem
           Kompartiment von einem Iterationsschritt zum nächsten}
  var
    i : byte;
  begin
    delt_iter_max := 0.0;
    if iter > 0 then begin
      for I := start to n_comp do
        if (abs(last_iter_theta[i]-theta_neu[i]) > abs(delt_iter_max)) then
           delt_iter_max := abs(last_iter_theta[i]-theta_neu[i])
    end;
    if Delt_iter_max < 1e-5 then success := true;
  end;


  procedure set_new_state_vars;
  {Zweck : Umsetzen der errechneten Wassergehalte in die globale
           "state"-Variable, Errechnung der Wasserspannungen}
  var
    i : byte;
  begin
    for i := 1 to n_comp+1 do begin
      theta_alt[i] := thetaadj_arr[i].v;
      thetaadj_arr[i].v := theta_neu[i];
      psi_arr[i].v := WPar[i].psi_b_f(thetaadj_arr[i].v);
      Wmenge[i].v := thetaadj_arr[i].v*Thick[i];
    end;
  end;


begin  { procedure num_wat_solut }
   iter := 0;

   get_water_contents;
   get_new_dt;
   repeat
     repeat
       get_delt_iter_max;
       Leitfaehigkeiten;
       obere_Randbedingung;
       Mittelteil;
       untere_Randbedingung;
       Loesung_Gleichungssystem;
     until success;
     iter := iter + 1;
   until ((delt_iter_max < max_iter_error) and (iter > 1)) or (iter > 1000);
   Find_flows;
   get_bilanz ;
   set_new_state_vars;
end;

{--------------------------------------------------------------------------}

procedure TSoilWaterET.writeValues(FirstTime: boolean;s: string);
{temporäre Ausgabe-Funktion, nur für Entwicklung}
var
  f: TextFile;
  i: integer;
const
  fn: string = 'P:\Stunden\Debug.csv';
begin
  AssignFile(f,fn);
  if FileExists(fn) then Append(f) else Rewrite(f);
  if FirstTime then begin
    Write(f,'Time;ModelTime;dt;ActTrans;ActTrans_;PotTrans;PotTrans_');
    for i := 1 to 20 do write(f,';thetaadj_arr',i);
    for i := 1 to 20 do write(f,';WFlow_arr',i,';intWFlow_arr',i);
  end
  else begin
    Write(f,TimeToStr(Time),';',GlobTime.v,';',dt.v,';',';',';',';');
    for i := 1 to 20 do write(f,';',thetaadj_arr[i].v);
    for i := 1 to 20 do write(f,';',WFlow_arr[i].v,';',intWFlow_arr[i].v);
  end;
  writeln(f,';',s);
  CloseFile(f);
end;

procedure TSoilWaterET.writeDebug(Schicht: integer;dt,InFlow,OutFlow,Sink,Thick,WGalt,WGneu,Bil:Real);
{temporäre Ausgabe-Funktion, nur für Entwicklung}
begin
end;

procedure TSoilWaterET.CheckSinks;
var
  i: integer;
begin
  SumSinks_int := 0;
  for i := 1 to N_comp do begin
    SumSinks_int := SumSinks_int + sink_arr[i].v;
  end;
end;




procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterET]);
end;


end.
