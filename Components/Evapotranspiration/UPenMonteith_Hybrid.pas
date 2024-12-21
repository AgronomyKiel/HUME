unit UPenMonteith_Hybrid;

{ **********************************************************************
  ************************  Unit PenMonteith  **************************
  **********************************************************************

  Erstellt von : Henning Kage

  Literatur : van Bavel, C.H.M. (1966)
  Potential evaporation: The Combination Concept and its
  Experimental Verification
  Water Resour.Res. (1966) 2, 455-467

  Duynisveld, W.H.M. (1983)
  Entwicklung von Simulationsmodellen fÅr den Transport von
  gelîsten Stoffen in wasserungesÑttigten Bîden und
  Lockersedimenten
  Texte Umweltbundesamt (1983) 17, 197 Seiten

  Monteith, J.L. (1973)
  Principles of Environmental Physics
  Edward Arnold, London, 1973, 241 Seiten

  Groot, J.J.R. (1987)
  Simulation of nitrogen balance in a system of winter wheat
  and soil
  Simulation Reports CABO-TT, Wageningen 1987

  Lˆbmeier, F.J. (1983)
  Agrarmeteorologisches Model zur Berechnung der aktuellen
  Verdunstung (AMBAV)
  BeitrÑge zur Agrarmeteorologie Nr. 7/83

  Tag der ersten Bearbeitung  : 6.10.89
  Tag der letzten Bearbeitung : 16.1.95

  Zweck : Berechnung der Transpiration, Evaporation, Interzeption aus
  Standard Witterungs- und Pflanzendaten

  **********************************************************************
  **********************************************************************
  ********************************************************************** }

interface

uses
  UMod, UState, classes, UAbstractPlant, Math;

const
  l_h_v_water = 2.477 * 1E6; { latente Verdunstungsenergie von
    {  Wasser bei bei 10 ¯C in [J/Kg] }
  Psycro = 0.000662; { Psychrometerkonstante [1/¯K] }

type

  TSource = (fromParameter, fromPlantModel); // Source of extinction coefficient / rc0
  T_ra_Funct = (PenmanMonteith, ThomOliver);
  T_rc_upscaling = (Stockle, BenMehrez);
  T_Opt_StomataCalc = (Neukam_default_CO2insensitive, Neukam_extended_CO2sensitive);

  TPenMonteith_Hybrid = class(TPlantRelatedSubMod)
  protected
    pTI: real;
    pTI_hour:array[1..24] of real;
    f_rc_upscaling: T_rc_upscaling;  // Function for calculating canopy resistance from stomatal resistance
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); Override;

    // function getLAI: real;//THumeNumEntity; //override;
    // function getCropHeight: real;//THumeNumEntity; //override;
    procedure Interzeption_p;
    procedure hourlyInterzeption_p;
    function Evaporation_f(pETP: real): real;
    function pressure_f(Elev, Temp: real): real;
    function sat_vap_press_f(Temp: real): real;
    function delta_f(sat_vap_press, Temp: real): real;
    function ra_f(wind_speed, crop_height: real): real;
    function Penman(Temp, Sat_def, Net_beam, delta, gamma, l_h_v_water, ra,
      rc: real): real;
    procedure rc_p;
    function r_surface_f(WG_0_1cm: real): real;
    //procedure iPAR_LeafLayerCalculation_p;
    function rc_upscaling_f ( rs_leaf :real; upscaling_opt: T_rc_upscaling): real;
    function Photosynthesis(PAR_, CO2_, SLNI, TempStress: real): real;
    function GaussianIntegration(LAIofLayer, k_, PAR_, CO2_, Nc_leaf, TempStress: real): real;
    function fT_WE(T,Tmin,Tmax,Topt: real): real;
    procedure CalcEvap_red_f;
  private
    fExkOpt: TSource; // Source of extinction coefficient
    frc0Opt: TSource; // Source of rc0
    f_ra_funct: T_ra_Funct;
    f_StomataCalculation: T_Opt_StomataCalc;

  public
    Elev: TPar; // Hˆhe ¸ber NN [m]               }
    rc0: TPar; // Stomatawiderstand bei "guter Wasserversorgung"
    rstom0_Neukam: TPar; // Stomatawiderstand bei "guter Wasserversorgung" f¸r st¸ndlichen Berechnung nach Neukam (2016)
    exk_GlobRad: TPar; // Exktinktionskoeffizient f¸r Globalstrahlung [-]
    sic: TPar; // spezifische InterzeptionskapazitÑt pro Einheit BFI [mm/BFI] }
    CiThreshold,
    relRc0Inc_CO2,
    measure_height: TPar; { Messhˆhe der Parameter [m] }

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
    g_fact,   //dn (30.07.12)  // Parameter f¸r rc-Funktion in Abh‰ngigkeit von PsiRoot, Rn, T und VPD
    Icu,          //     {nach Jackson et al. 1988, wegen erhˆhter Reflexion und Emission des fiktiv nicht transpirierenden Bestandes}
    Icl,
    Ic_allen_etal_1998_night: TPar;            {nach Jackson et al. 1988, Ber¸cksichtigung des Bodenw‰rmestroms}

    Par_Photosynthesis_Intercept,
    Par_Photosynthesis_lnPAR,
    Par_Photosynthesis_CO2,
    Par_Photosynthesis_NcLeaf,
    Par_Photosynthesis_TempStress,
    Par_Photosynthesis_lnPAR_CO2,
    Par_Photosynthesis_lnPAR_NcLeaf,
    Par_Photosynthesis_lnPAR_TempStress,
    Par_Photosynthesis_NcLeaf_TempStress,
    WangEngelTmin,
    WangEngelTmax,
    WangEngelTopt,
    Par_rs_A_intercept,
    Par_rs_A_lin,
    Par_fCO2_scale,Par_CiCompensation,Par_fCO2,
    Par_Photosynthesis_alpha,Par_Photosynthesis_beta,Par_Photosynthesis_gamma,Par_Photosynthesis_RespirationDark:TPar;
    // Par_rs_A_quad,
    // Par_rs_A_cubic,
    // Par_rs_A_RH_CO2:TPar;

    Temp, // Temperatur [∞C]
    GlobRad, // Globalstrahlung [W.m-2]
    Sat_def, // S‰ttigungsdefizit [mbar]
    wind_speed, // Windgeschwindigkeit [m.s-1]
    ExCropHeight, // Pflanzenhˆhe [m]
    ExLAI, // Blattfl‰chenindex []
    rain, // Niederschlag [mm/d]
    CO2pp, // CO2 Partialdruck
    psiRoot,
    NcLeaf,
    kPAR_eff,
    WG_1, psi_arr_1, Delta_AirTemp_Soil_1,
    Sunrise, Sunset, SLNI,
    LAI_GrowthCurvePlant: TExternV;
    TMPM_hour: array [1..24] of TExternV;
    Wind_hour: array [1..24] of TExternV;
    GlobRad_hour: array [1..24] of TExternV;
    Rad_Int_hour: array [1..24] of TExternV;
    Sat_def_hour: array [1..24] of TExternV;
    Precip_hour: array [1..24] of TExternV;
    CO2_hour: array [1..24] of TExternV;
    LF_hour: array [1..24] of TExternV;
    Cloud_fraction: array [1..24] of TExternV;
    NcLAL: array [1..4] of TExternV;
    LAL: array [1..4] of TExternV;
    PhotosynthesisRestr_LeafLayer: array [1..4] of TExternV;
    //MLAL: array [1..4] of TExternV;

    P, // Standardluftdruck [mbar] berechnet aus Temperatur und Hˆhe
    VapPress, // Wasserdampfdruck [mbar]
    pETP, // potentielle Evapotranspiration [mm.d-1]
    pETP_ambient, // potentielle Evapotranspiration no CO2 effect [mm.d-1]
    pETP_Neukam, // potentielle Evapotranspirationa aus kumulierten Stundenwerten nach Neukam
    potEactT_Neukam, // aktuelle Evapotranspirationa aus kumulierten Stundenwerten nach Neukam
    pot_trans, // potentielle Transpiration [mm.d-1]
    pot_Transpiration_Neukam, // potentielle Transpiration aus kumulierten Stundenwerten nach Neukam
    actTranspiration_Neukam, // aktuelle Transpiration aus kumulierten Stundenwerten nach Neukam
    pot_trans_ambient, // potentielle Transpiration [mm.d-1]
    pot_Evapo, // potentielle Evaporation
    pot_Evapo_ambient, // potentielle Evaporation
    interzeption, // Interzeptionsverdunstung
    net_rain, // Niederschlag-Interzeption
    netRad, // Nettostrahlung
    k_GlobRad, // extinction coefficient for GlobRad
    ra, rc, rc_ambient, rc0_Var, rc0_ambient, CO2TransDiff, relCO2TransDiff,
    LastDeltaT, red_evap_: TVar;
    r_surface, netA: TVar;
    pETP_Neukam_hour: array [1 .. 24] of TVar;
    potEactT_Neukam_hour: array [1 .. 24] of TVar;
    potEvaporation_hour: array[1..24] of TVar;
    netRad_hour: array [1 .. 24] of TVar;
    rstom: array [1 .. 24] of TVar;
    gstom: array [1 .. 24] of TVar;
    rs_Rn: array [1 .. 24] of TVar;
    rs_T: array [1 .. 24] of TVar;
    rs_VPD: array [1 .. 24] of TVar;
    rc_Neukam: array [1 .. 24] of TVar;
    PAR_hour: array [1 .. 24] of TVar;
     //rstom, gstom, rs_Rn, rs_T, rs_VPD: TVar;
    Tcrop_max: array [1 .. 24] of TVar;
    Tcrop_base: array [1 .. 24] of TVar;
    Tcrop_direct: array [1 .. 24] of TVar;
    net_rain_hour: array [1 .. 24] of TVar;
    interzeption_hour: array [1 .. 24] of TVar;
    actT_hour: array [1..24] of TVar;
    potT_hour: array [1..24] of TVar;
    A_hour: array [1..24] of TVar;
    TemperatureStress: array [1..24] of TVar;
    iPAR_LeafLayer: array [1..24,1..4] of TVar;
    grossA_LeafLayer: array [1..24,1..4] of TVar;
    netA_LeafLayer: array [1..24,1..4] of TVar;
    local_LAL: array[1..4] of TVar;
    Cum_C_Assimilation: TState;
    //NcLeafLayer: array [1..4] of TVar;
    f_ra_Option: TOption;   // Option for ra(u,CropHeight)-function dn
    f_rc_upscaling_Option: TOption; //Option for upscaling canopy resistance from stomatal resistance		////dn 08.05.14
    OptWithCO2: TOption;
    Opt_StomataCalculation: TOption;
    Opt_LAI_Source_StomataCalculation: TOption;
    Opt_SoilSurfaceHeatFlux: TOption;

    int_stor: TState; // Interzeptionsspeicher [mm]
    int_stor_hour: TState;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;

    // Property LAI : real{;THumeNumEntity} read getLAI;
    // Property CropHeight : real {THumeNumEntity} read getCropHeight;

  published
    property Ex_Temp: TExternV read Temp write Temp;
    property Ex_GlobRad: TExternV read GlobRad write GlobRad;
    property Ex_Sat_def: TExternV read Sat_def write Sat_def;
    property Ex_Windspeed: TExternV read wind_speed write wind_speed;
    property Ex_CropHeight: TExternV read ExCropHeight write ExCropHeight;
    Property Ex_LAI: TExternV read ExLAI write ExLAI;
    Property Ex_Rain: TExternV read rain write rain;
    Property Par_RC0: TPar read rc0 write rc0;
    Property Par_Exk_Glob: TPar read exk_GlobRad write exk_GlobRad;
    Property Par_Elev: TPar read Elev write Elev;
    Property Par_SIC: TPar read sic write sic;
    Property Par_measure_height: TPar read measure_height write measure_height;
    property Ex_CO2pp: TExternV Read CO2pp Write CO2pp;
    Property Var_pETP: TVar read pETP write pETP;
    // potentielle Evapotranspiration [mm.d-1]
    Property Var_PotTrans: TVar read pot_trans write pot_trans;
    // potentielle Transpiration [mm.d-1]
    Property Var_PotEvap: TVar read pot_Evapo write pot_Evapo;
    // potentielle Evaporation
    Property Var_interzeption: TVar read interzeption write interzeption;
    // Interzeptionsverdunstung
    Property Var_NetRain: TVar read net_rain write net_rain;
    // Niederschlag-Interzeption
    Property Var_ra: TVar read ra write ra;
    Property Var_NetRad: TVar read netRad write netRad;
    // Nettostrahlung [W.m-2]

    Property Opt_Exk_Glob: TSource read fExkOpt write fExkOpt;
    // Option for Source of extinction coefficient
    Property Opt_rc0: TSource read frc0Opt write frc0Opt;
    // Option for Source of extinction coefficient
  end;

procedure Register;

implementation

uses
  UModUtils, vcl.dialogs, SysUtils;

{ function TPenMonteith.GetLAI: real;//THumeNumEntity;

  begin
  if PlantModel <> nil then begin
  result    := Plantmodel.p_LAI.v;
  //    result := Plantmodel.p_LAI;
  exit;
  end else
  if ExLAI.f_v <> nil then
  GetLAI := ExLAI.v;

  end;

  function TPenMonteith.GetCropHeight: real;//THumeNumEntity;

  begin
  if PlantModel <> nil then  begin
  result := Plantmodel.p_CropHeight.v;
  exit;
  end else
  if ExCropHeight.f_v <> nil then
  result := ExCropHeight.v;

  end; }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
function TPenMonteith_Hybrid.pressure_f(Elev, Temp: real): real;

{ ********************************************************************** }
{ Zweck : Berechnung des Standardluftdrucks
  Parameter :
  Name             Inhalt                          Einheit      Typ

  Elev             Hˆhe ¸ber NN                    [m]          I
  Temp             Mittlere Tagestemperatur        [∞C]         I

  pressure_f       Luftdruck                       [mbar]       O }
{ ********************************************************************** }

begin
  pressure_f := 1013.0 * exp(-0.034 * Elev / (Temp + 273));
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
function TPenMonteith_Hybrid.ra_f(wind_speed, crop_height: real): real;

{ ********************************************************************** }
{ Zweck : Berechnung des aerodynamischen Widerstandes
  Parameter :
  Name             Inhalt                          Einheit      Typ

  wind_speed       Mittlere Windgeschwindigkeit    [m/s]        I
  crop_height      Pflanzenhˆhe                    [m]          I

  ra_f             aerodynamischer Widerstand      [s/m] }
{ ********************************************************************** }

const
  Karman_const = 0.41; { von Karman-Konstante [-] }
  // measure_height   = 2.0;               { Messhˆhe der Parameter [m]   }
var
  z0: real;
  d: real;

  function roughness_f(crop_height: real): real;
  { ********************************************************************** }
  { Zweck : empirische Funktion zur Ermittlung des Rauigkeitsfaktors
    nach Monteith (1973) S.90
    Parameter :
    Name             Inhalt                          Einheit      Typ

    crop_height      Pflanzenhˆhe                    [m]         I
    roughness_f      Rauhigkeitsfaktor               [m]         O }
  { ********************************************************************** }
  begin
    if crop_height < 0.05 then
      crop_height := 0.05; // Mindesthˆhe von 5 cm
    roughness_f := 0.13 * crop_height;
  end;
  function displacement_height ( crop_height : real ) : real;
  begin
    if crop_height<0.05 then crop_height := 0.05; // Mindesthˆhe von 5 cm
    displacement_height := 0.63 * crop_height;
  end;

begin
  If wind_speed < 0.0001 then
    wind_speed := 0.0001;
  z0 := roughness_f(crop_height);
  d := displacement_height(crop_height);
  case f_ra_funct of
    PenmanMonteith:   {Original-Penman-Monteith f¸r near-neutral conditions}
        ra_f := (ln(measure_height.v/z0)*ln(measure_height.v/(0.2*z0)))/(sqr(Karman_const)*wind_speed);
    ThomOliver: {Formulierung zur Einbeziehung von Konvektion nach Thom and Oliver (1977)
                 zitiert in Jackson et al. 1988}
        ra_f := 4.72*sqr(ln((measure_height.v-d)/z0))/(1+0.54*wind_speed);
  end;

end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
function dens_air(Temp: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Dichte trockener Luft
  Daten aus Monteith (1973)

  Parameter :
  Name             Inhalt                          Einheit      Typ

  Temp             Mittlere Tagestemperatur        [¯C]         I
  dens_air         Dichte der Luft                 [Kg/m3]      O }
{ ********************************************************************** }

begin
  dens_air := 1.2917 - 0.00434 * Temp;
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
function TPenMonteith_Hybrid.Penman(Temp,
                                    Sat_def,
                                    Net_beam,
                                    delta,
                                    gamma,
                                    l_h_v_water,
                                    ra,
                                    rc: real): real;

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

  Temp             Lufttemperatur                  [¯C]         I
  Sat_def          SÑttigungsdefizit der Luft      [mbar]       I
  Net_beam         Nettostrahlung                  [J/m2*s]     I
  delta            Steigung der SÑttigungs-
  dampfdruckkurve                 [mbar/K]     I
  gamma            Psychrometerkonstante           [mbar/K]     I
  l_h_v_water      latente VerdunstungswÑrme
  von Wasser bei 10¯C             [J/Kg]       I
  ra               GrenzflÑchenwiderstand          [s/m]        I
  rc               bulk-Stomatawiderstand          [s/m]        I

  Penman           potentielle Evapotranspiration  [kg/(m2*s)]  O

  **********************************************************************
  **********************************************************************
  ********************************************************************** }

const
  cp = 1005.0; { spezifische WÑrme der Luft [J/(Kg*K)] }                                    {17.01.17 AL: bei Dorothee cp =1003.0 }

var
  pETP, ro, rc_: real; { Dichte der Luft [kg/m3 ] }

begin { Penman }
  ro := dens_air(Temp);
  rc_:= r_surface.v * (exp(-0.7 * ExLAI.v)) + rc * (1 - exp(-0.7 * ExLAI.v));

  pETP := (delta * Net_beam + ro * cp * Sat_def / ra) /
    (delta + gamma * (1 + rc_ / ra));
  pETP := pETP / l_h_v_water * 86400.0;
  If pETP < 0.0 then
    Penman := 0.0
  else
    Penman := pETP;

end; { Penman }
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith_Hybrid.Interzeption_p;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Interzeption eines


  Parameter :
  BFI              BlattflÑchenindex                   [-]
  rain             Niederschlag                        [mm/d]
  pTI              potentielle Transpiration/Interzeption
  [mm/d]
  Int_stor         Interzeptionsspeicher               [mm]



  Interzeption     Interzeptionsverdunstung des Bestandes
  [mm/d]       O }
{ ********************************************************************** }

var
  max_int_cap, { maximale InterzeptionskapazitÑt [mm] }
  int_cap { aktuelle InterzeptionskapazitÑt [mm] }
  : real;

begin
  max_int_cap := ExLAI.v * sic.v;
  int_cap := max_int_cap - int_stor.v;
  If int_cap > 0.0 then
  begin
    if int_cap > (rain.v * GlobTime.c) then
    begin
      int_stor.v := int_stor.v + rain.v * GlobTime.c;
      net_rain.v := 0.0;
    end
    else
    begin
      int_stor.v := max_int_cap;
      net_rain.v := rain.v - int_cap / GlobTime.c;
    end;
  end
  else
    net_rain.v := rain.v;

  // If Net_rain.v > Rain.v then
  // showmessage('Too much Netrain !');

  If pTI * GlobTime.c > int_stor.v then
  begin
   // pTI := pTI - int_stor.v / GlobTime.c;
    interzeption.v := int_stor.v / GlobTime.c;
    int_stor.v := 0.0;
  end
  else
  begin
    interzeption.v := pTI;
    int_stor.v := int_stor.v - pTI * GlobTime.c;
  end;

end;

procedure TPenMonteith_Hybrid.hourlyInterzeption_p;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Interzeption eines


  Parameter :
  BFI              BlattflÑchenindex                   [-]
  rain             Niederschlag                        [mm/d]
  pTI              potentielle Transpiration/Interzeption
  [mm/d]
  Int_stor         Interzeptionsspeicher               [mm]



  Interzeption     Interzeptionsverdunstung des Bestandes
  [mm/d]       O }
{ ********************************************************************** }

var
  max_int_cap_hour, { maximale InterzeptionskapazitÑt [mm] }
  int_cap_hour { aktuelle InterzeptionskapazitÑt [mm] }
  : real;
  i: integer;
begin
  max_int_cap_hour := ExLAI.v * sic.v;
  int_cap_hour := max_int_cap_hour - int_stor_hour.v;
  If int_cap_hour > 0.0 then
  begin
    if int_cap_hour > Precip_hour[i].v  then
    begin
      int_stor_hour.v := int_stor_hour.v + Precip_hour[i].v;
      net_rain_hour[i].v := 0.0;
    end
    else
    begin
      int_stor_hour.v := max_int_cap_hour;
      net_rain_hour[i].v := Precip_hour[i].v - int_cap_hour;
    end;
  end
  else
    net_rain_hour[i].v := Precip_hour[i].v;

  // If Net_rain.v > Rain.v then
  // showmessage('Too much Netrain !');

  If pTI_hour[i]  > int_stor_hour.v then
  begin
    // pTI_hour[i] := pTI_hour[i] - int_stor_hour[i].v;
    interzeption_hour[i].v := int_stor_hour.v ;
    int_stor.v := 0.0;
  end
  else
  begin
    interzeption_hour[i].v := pTI_hour[i];
    int_stor_hour.v := int_stor_hour.v - pTI_hour[i];
  end;

end;

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
function TPenMonteith_Hybrid.Evaporation_f(pETP: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Evaporation eines
  Bodens unter einem Pflanzenbestand
  nach Duynisveld (1983) S.22

  Parameter :

  Name             Inhalt                          Einheit      Typ

  pET              potentielle Evapotranspiration  [mm/d]       I
  BFI              BlattflÑchenindex               [-]          I

  Evaporation_f    Evaporation unter einem
  Pflanzenbestand                 [mm/d]       O }
{ ********************************************************************** }

var
  Evap: real;
begin
  if (fExkOpt = fromPlantModel) and IsPlantModelSet then
    k_GlobRad.v := Plantmodel.ExtCoeffGlobRad // Extinktionskoeffizient aus verlinktem Plantmodel
  else
    k_GlobRad.v := exk_GlobRad.v; // Extinktionskoeffizient aus Parameterwert
    Evap := pETP * exp(-k_GlobRad.v * ExLAI.v);
  If Evap < 0.0 then
    Evap := 0.0;
  Evaporation_f := Evap;
end;


function TPenMonteith_Hybrid.sat_vap_press_f(Temp: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung des ges‰ttigten Wasserdampf-
  druckes
  nach Groot (1983) bzw. Goudriaan (1977)

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Temp             Temperatur                      [¯C]         I


  sat_vap_press_f  ges‰ttigter Wasserdampfdruck    [mbar]       O }
{ ********************************************************************** }

begin
  sat_vap_press_f := 6.11 * exp(17.4 * Temp / (Temp + 239.0));
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

function TPenMonteith_Hybrid.delta_f(sat_vap_press, Temp: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung Steigung der Wasserdampf-
  druckkurve in AbhÑngigkeit von gesÑttigtem Wasserdampfdruck
  und Temperatur
  nach Groot (1983)

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Temp             Temperatur                      [¯C]         I
  sat_vap_press    gesÑttigter Wasserdampfdruck    [mbar]       I

  delta_f          Steigung der Wasserdampdruck-
  kurve                            [mbar/¯K]   O }
{ ********************************************************************** }

begin
  delta_f := 239.0 * 17.4 * sat_vap_press / sqr(Temp + 239.0);
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

function TPenMonteith_Hybrid.r_surface_f(WG_0_1cm: real): real;

{ ********************************************************************** }
{  }
{ ********************************************************************** }

begin
  r_surface_f := 10 * exp(0.3563 * (15 - 100 * WG_0_1cm));
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith_Hybrid.CalcEvap_red_f;
{ ********************************************************************** }
{ Zweck : Ermittlung eines Reduktionsfaktors der die potentielle
  Evaporation um den Einflu· einer geringen Bodenfeuchte an der
  BodenflÑche korrigiert

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Psi              Bodenwasserspannung im          [cm]         I
  obersten Kompartimente (10 cm Tiefe)

  evap_red_f       Reduktionsfaktor der            [-]           O
  potentiellen Evaporation

  { ********************************************************************** }

var
  red_f: real;
  pF_5: real;

begin
  if psi_arr_1.v > 0.0 then
  begin
    pF_5 := log10(psi_arr_1.v);
 //   if fred_f = modifiedBeese then
      red_f := -1 * (pF_5 - 4.2) / (4.2 - log10(500.0));
 //   if fred_f = Beese1978 then
 //     red_f := -0.5767 * log10(psi_arr_1.v) + 1.78;
  end
  else
    red_f := 0.0;
  if red_f > 1.0 then
    red_f := 1.0;
  if red_f < 0.0 then
    red_f := 0.0;
  red_evap_.v := red_f;
end;


procedure TPenMonteith_Hybrid.rc_p;
{Estimation of stomatal conductance considering drought stress
(Neukam, D., Bˆttcher, U. & Kage, H. 2016: Modelling wheat stomatal restistance in hourly time steps
  from micrometeorological variables and soil water status; Journal of Agronomy and Crop Science; 202; 174 - 191)
}
var
  //GlobRad_hour_loc, TMPM_hour_loc, Sat_def_hour_loc: real;
  {netRad_hour,
  rs_Rn,
  rs_T,
  rs_VPD,
  gstom,
  rstom,
  rc_Neukam: real;}
  rs: real;
  gs_mumol_m2_s, factor_CondToMeter, density_: real;
  gs_LeafLayer_mumol_m2_s: array [1..4] of real;
  rs_LeafLayer_s_m: array [1..4] of real;
  rs_temp,
  DownwellingLW_Radiation, UpwellingLW_Radiation,
  emissivity_plants, EmissivityClouds, Reflection,
  StefanBoltzmannConstant, rad_, LastHourDeltaT,
  emissivity_soil, local_LAI, LastDeltaT_ToCalcWith: real;
  i,j: integer;
  Year, Month, Day: Word;
begin
  emissivity_soil   := 0.95;
  emissivity_plants := 0.97;
  Reflection := 0.21;
  StefanBoltzmannConstant := 0.0000000567;
  rad_ := pi/180;
  DecodeDate(GlobMod.Time.v, Year, Month, Day);
  if i=20 then
   DecodeDate(GlobMod.Time.v, Year, Month, Day);
//  if i>1 then
//    LastHourDeltaT := TMPM_hour[i-1].v  - Tcrop_direct[i-1].v
//  else
//    LastHourDeltaT := 0;

/// r_surface.v * (exp(-0.7 * ExLAI.v)) + rc * (1 - exp(-0.7 * ExLAI.v))

 if(GlobMod.Time.v = 38353) and (i=12) then
   DecodeDate(GlobMod.Time.v, Year, Month, Day);
  if(LastDeltaT.v > 0) then
    LastDeltaT_ToCalcWith := max(20,abs(LastDeltaT.v)) * (LastDeltaT.v/abs(LastDeltaT.v))
  else
    LastDeltaT_ToCalcWith := 0;
  UpwellingLW_Radiation := emissivity_plants * StefanBoltzmannConstant * power((273.15 + TMPM_hour[i].v + LastDeltaT_ToCalcWith), 4);//
                          //      (exp(-0.7 * ExLAI.v)) * emissivity_soil   * StefanBoltzmannConstant * power((273.15 + TMPM_hour[i].v + Delta_AirTemp_Soil_1.v), 4)
                          //+ (1 - exp(-0.7 * ExLAI.v)) * emissivity_plants * StefanBoltzmannConstant * power((273.15 + TMPM_hour[i].v + LastDeltaT.v), 4);
  EmissivityClouds      := Cloud_Fraction[i].v + (1 - Cloud_Fraction[i].v)
                                           * (1.22 + 0.06 * sin((month + 2) * pi / 6 * rad_))
                                           * power((sat_vap_press_f(TMPM_hour[i].v)) / (TMPM_hour[i].v + 273.15) , (1/7));
           {accorting to:
            Crawford, TM, and Duchon, CE (1998) An improved Parametrization for Estimating
            Effective Atmorspheric Emissivity for Use in Calculating Daytime Downwelling
            Longwave radiation; Journal of Applied Meteorology; Volume 38; p. 474}
  DownwellingLW_Radiation := EmissivityClouds * StefanBoltzmannConstant * power((273.15 + TMPM_hour[i].v), 4);
  netRad_hour[i].v:= (1 - Reflection) * Rad_Int_hour[i].v -  UpwellingLW_Radiation +  DownwellingLW_Radiation;
  {netRad_hour[i].v:= 0.6494 * (Rad_Int_hour[i].v) - 18.417;  //dn21.10.}
   if (Opt_LAI_Source_StomataCalculation.Option = 'simulated_lai_from_subleafareasimple') then
    local_LAI := ExLAI.v;
   if (Opt_LAI_Source_StomataCalculation.Option = 'simulated_lai_from_growthcurveplant') then
    local_LAI := LAI_GrowthCurvePlant.v;

 case f_StomataCalculation of

  Neukam_default_CO2insensitive: begin
   if netRad_hour[i].v < rc_par_e.v then
      rs_Rn[i].v := rc_par_f.v * sqr(netRad_hour[i].v - rc_par_e.v) + rstom0_Neukam.v
   else
      rs_Rn[i].v := rstom0_Neukam.v;
  end;

  Neukam_extended_CO2sensitive: begin
      density_ := ((101.325 * 1000) * 29) / (8.314 * (TMPM_hour[i].v + 273.15)) / 1000;
      factor_CondToMeter := (29/1000) / density_;  // from Principles of Enviromental Physics
      //gs_mumol_m2_s :=    Par_rs_A_intercept.v
      //                  + Par_rs_A_lin.v       * (A[i].v * ((LF_hour[i].v / 100) / CO2_hour[i].v));
      for j := 1 to 4 do begin
        gs_LeafLayer_mumol_m2_s[j] := Par_rs_A_intercept.v
                                    + Par_rs_A_lin.v       * (netA_LeafLayer[i,j].v * ((LF_hour[i].v / 100) / CO2_hour[i].v));
        rs_LeafLayer_s_m[j] := 1 / (gs_LeafLayer_mumol_m2_s[j] * factor_CondToMeter);
      end;
      //gs_LeafLayer_mumol_m2_s[j] :

      {gs_mumol_m2_s := Par_rs_A_intercept.v +
                       Par_rs_A_lin.v       * A[i].v  +
                       Par_rs_A_quad.v      * power(A[i].v, 2)  +
                       Par_rs_A_cubic.v     * power(A[i].v, 3)  +
                       Par_rs_A_RH_CO2.v    * ((LF_hour[i].v / 100) / CO2_hour[i].v);}
      if(local_LAI > 0) then
      rs_Rn[i].v := ((rs_LeafLayer_s_m[1] * local_LAL[1].v +
                      rs_LeafLayer_s_m[2] * local_LAL[2].v +
                      rs_LeafLayer_s_m[3] * local_LAL[3].v +
                      rs_LeafLayer_s_m[4] * local_LAL[4].v) / local_LAI) / local_LAI; //Mean(rs_LeafLayer_mumol_m2_s);
      rs_Rn[i].v := min(1500, rs_Rn[i].v);            // 186.0304
    end;
 end;

 //dn (24.07.12) andere Ans‰tze probiert Jarvis: rs_Rn.v := 1/(rc_par_e.v*rc_par_f.v*(netRad.v+100-rc_par_d.v)/(rc_par_e.v+rc_par_f.v*(netRad.v+100-rc_par_d.v)));// Irmak: rc_par_e.v*power(netRad.v+rc_par_f.v,rc_par_d.v);
 rs_T[i].v := rstom0_Neukam.v + rc_par_h.v * sqr(25 - TMPM_hour[i].v) ;
 rs_VPD[i].v := rstom0_Neukam.v - (rc_par_a.v + rc_par_b.v * Sat_def_hour[i].v) * (rc_par_s.v - power(10, psiRoot.v));
 if (Opt_StomataCalculation.Option = 'neukam_extended_co2sensitive') then
  rs := rs_VPD[i].v // max( rs_T[i].v, rs_VPD[i].v)
 else
  rs := max(rs_Rn[i].v, max(rs_T[i].v, rs_VPD[i].v));
 gstom[i].v := 100/(r_fact.v*rs) ;     //dn (30.07.12) gstom [cm/s]
 rstom[i].v := rs; //1/(g_fact.v * gstom[i].v/100) ;
 rs_temp := rc_upscaling_f(rstom[i].v, f_rc_upscaling);
 if (Opt_StomataCalculation.Option = 'neukam_extended_co2sensitive') then // and (rs_Rn[i].v > rs_temp) then//(rs_Rn[i].v > rs_T[i].v) and (rs_Rn[i].v > rs_VPD[i].v ) then
  rc_Neukam[i].v := max(rs_Rn[i].v, rs_temp)
 else
  rc_Neukam[i].v:= rs_temp;

  if(rs_Rn[i].v < rs_temp) then        //////////////////////////////////////////////////////////////
    for j := 1 to 4 do begin           ///////////////  WEITERMACHEN
      netA_LeafLayer[i,j].v := ((((1 / rs_LeafLayer_s_m[j]) / factor_CondToMeter) - Par_rs_A_intercept.v) / Par_rs_A_lin.v) *
                                  ( CO2_hour[i].v / (LF_hour[i].v / 100))
    end;
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


function TPenMonteith_Hybrid.Photosynthesis(PAR_, CO2_, SLNI, TempStress: real): real;

{ ********************************************************************** }
{  }
{ ********************************************************************** }
var
  Agross, CO2_factor: real;
begin
 if(CO2_ >  Par_CiCompensation.v) then
  CO2_factor:=max(Par_fCO2_scale.v,Par_fCO2_scale.v*power((CO2_-Par_CiCompensation.v), Par_fCO2.v))
 else
  CO2_factor:=Par_fCO2_scale.v;
 //if(PAR_>= 1) then begin
  Agross := Par_Photosynthesis_alpha.v *
            ((1- Par_Photosynthesis_beta.v * PAR_)/(1 + Par_Photosynthesis_gamma.v * PAR_) * PAR_) +
            Par_Photosynthesis_RespirationDark.v;
  {Agross :=         Par_Photosynthesis_Intercept.v +
                    Par_Photosynthesis_lnPAR.v      * ln(PAR_) +
                    Par_Photosynthesis_CO2.v        * CO2_;
                  }
                    //Par_Photosynthesis_NcLeaf.v     * Nc_Leaf +
                    //Par_Photosynthesis_TempStress.v * TempStress
                    {Par_Photosynthesis_lnPAR_CO2.v * ln(PAR_) * CO2_ +
                    Par_Photosynthesis_lnPAR_NcLeaf.v * ln(PAR_) * Nc_Leaf +
                    Par_Photosynthesis_lnPAR_TempStress.v * ln(PAR_) * TempStress +
                    Par_Photosynthesis_NcLeaf_TempStress.v * Nc_Leaf  * TempStress}
 Agross :=   Agross * CO2_factor; //* min(SLNI, TempStress);
 // end else
  // Agross := 0;

  {if(Agross < 0) then
   Photosynthesis := 0
  else}
   Photosynthesis := Agross;

end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


function TPenMonteith_Hybrid.GaussianIntegration(LAIofLayer, k_, PAR_, CO2_, Nc_leaf, TempStress: real): real;

{ ********************************************************************** }
{  }
{ ********************************************************************** }
var
  GaussianDistances: array [1..5] of real;
  GaussianWeights: array [1..5] of real;
  LAIofGaussStep, f_IntOfGaussStep, AofGaussStep,SumOfA: real;
  h:integer;
begin
  GaussianDistances[1] := 0.04691;   GaussianWeights[1] := 0.11846;
  GaussianDistances[2] := 0.23075;   GaussianWeights[2] := 0.23931;
  GaussianDistances[3] := 0.5;       GaussianWeights[3] := 0.28444;
  GaussianDistances[4] := 0.76925;   GaussianWeights[4] := 0.23931;
  GaussianDistances[5] := 0.95309;   GaussianWeights[5] := 0.11846;
  SumOfA := 0;
  for h := 1 to 5 do begin
    LAIofGaussStep   := LAIofLayer * GaussianDistances[h];
    f_IntOfGaussStep := exp(- k_ * LAIofGaussStep);
    AofGaussStep     := Photosynthesis( (PAR_ * f_IntOfGaussStep), CO2_, Nc_leaf, TempStress);
    SumOfA           := SumOfA + AofGaussStep * GaussianWeights[h];
  end;
    GaussianIntegration :=  SumOfA;

end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


function TPenMonteith_Hybrid.fT_WE(T,Tmin,Tmax,Topt: real): real;
{
 Wang-Engel	 (WE)	 temperature	 function (0-1)	 constructs	 a	 curvilinear
 response	 based	 on	 the	base,
 optimum,	and	 maximum	 temperatures	 of	 the	 simulated	 process.
}
  var
  alpha: real;
  begin
   if(T >= Tmin) and (T <= Tmax) then begin
    alpha:= Ln(2)/ln(((Tmax-Tmin)/(Topt-Tmin)));
     fT_WE:=(2*power((T-Tmin),alpha)*
      power((Topt-Tmin),alpha)-power((T-Tmin),(2*alpha)))/
          power((Topt-Tmin),(2*alpha));
    end else
     fT_WE:=0;
end;


function TPenMonteith_Hybrid.rc_upscaling_f(rs_leaf :real; upscaling_opt: T_rc_upscaling): real;
var
  local_LAI:real;
begin
  if (Opt_LAI_Source_StomataCalculation.Option = 'simulated_lai_from_subleafareasimple') then
    local_LAI := ExLAI.v;
  if (Opt_LAI_Source_StomataCalculation.Option = 'simulated_lai_from_growthcurveplant') then
    local_LAI := LAI_GrowthCurvePlant.v;

  case f_rc_upscaling of
  Stockle:
   {Berechnung des Canopy-Widerstandes aus dem Stomata-Widerstand auf Blattebene
 mit einem Ansatz von Stockle (personal communication)}
      begin
      result:= rs_leaf;
        if (local_LAI >= 1.0) and (local_LAI < 2) then result := rs_leaf/local_LAI
        else if (local_LAI >= 2.0) and (local_LAI < 6) then result := rs_leaf/2-(rs_leaf/2-rs_leaf/3)*((local_LAI-2)/4)
        else if (local_LAI >= 6) then result := rs_leaf/3;
        If result < 0.1 then result := 0.1;
      end;
  BenMehrez:
  {Berechnung des Canopy-Widerstandes aus dem Stomata-Widerstand auf Blattebene
 mit dem Shelter-Faktor-Ansatz (Ber¸cksichtigung der Beschattung der unteren Blattetagen)nach Ben Mehrez et al. (1992),  Mascart et al. 1991,
 Alfieri et al., 2008, Hatfield and Allen (1996), Amer and Hatfield  (2004)}
  begin
  if local_LAI > 0 then

        result := (0.3 *local_LAI+1.2)/local_LAI * rs_leaf
  else result := rs_leaf;
  result := min(result, rs_leaf);
  end;

  end;
 end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith_Hybrid.CreateAll;
var
  i,j:integer;
begin
  Inherited CreateAll;
  ParCreate('Elev', '[m]', 50.0, Elev); // Hˆhe ¸ber NN [m]
  ParCreate('rc0', '[s.m-1]', 50, rc0); // Stomatawiderstand bei
  // "guter Wasserversorgung"
  ParCreate('rstom0_Neukam', '[s.m-1]', 34, rstom0_Neukam,'minimal stomatal resistance under sufficient water supply from Neukam et al. 2016'); // Stomatawiderstand bei  "guter Wasserversorgung" f¸r st¸ndliche Berechnung nach Neukam 2016
  ParCreate('exk_GlobRad', '[-]', 0.5, exk_GlobRad);
  ParCreate('SIC', '[mm.m-2.m-2]', 0.15, sic);
  ParCreate('measure_height', '[m]', 2.0, measure_height);
  ParCreate('CiThreshold', '[ppm]',   380,  CiThreshold, 'threshold for CO2 impact on rc0');
  ParCreate('relRc0Inc_CO2', '[(s.m-1)/ppm]',   0.27,  relRc0Inc_CO2,'mediates the relative CO2 impact on rc0; estimated from "Elevated CO2 effects on canopy and soil water flux parameters... Burkart et al. 2010');

  ParCreate('rc_par_a', '[s.m-1.hPa]', 0.0124, rc_par_a, 'Parameter a f¸r Stomatafunktion nach Neukam: Intercept SatDef-Einfluss auf psiRoot-Einfluss ');
  ParCreate('rc_par_b', '[s.m-1.hPa-2]', 0.00094, rc_par_b, 'Parameter b f¸r Stomatafunktion nach Neukam: Slope SatDef-Einfluss auf psiRoot-Einfluss');
  ParCreate('rc_par_e', '[W.m-2]', 533, rc_par_e, 'Parameter e f¸r Stomatafunktion nach Neukam: kritische Nettostrahlung');
  ParCreate('rc_par_f', '[s.m3.W-2]', 0.0005, rc_par_f, 'Parameter f f¸r Stomatafunktion nach Neukam: Kr¸mmung NetRad-Einfluss');
  ParCreate('rc_par_h', '[s.m-1.K-2]', 0.4275, rc_par_h, 'Parameter h f¸r Stomatafunktion nach Neukam: Kr¸mmung TMPM-Einfluss');
  ParCreate('rc_par_s', '[hPa]', 63, rc_par_s, 'Parameter s f¸r Stomatafunktion nach Neukam: psiRoot bei pF=1.8');
  ParCreate('r_fact', '[]', 1, r_fact, 'scaling factor for rs');  //dn (30.07.12)
  ParCreate('g_fact', '[]', 1, g_fact, 'scaling factor for gs');
  ParCreate('Icu', '[]', 0.9, Icu, 'Jackson et al. 1988: radiation interception coefficient for upper limit(higher reflection and emissivity because of non-transpiring canopy)');
  ParCreate('Icl', '[]', 0.8, Icl, 'Jackson et al. 1988: radiation interception coefficient for lower limit(consideration of soil heat flux)');
  ParCreate('Ic_night', '[]', 0.5, Ic_allen_etal_1998_night,
  'Allen et al. 1998: radiation interception coefficient during night time(consideration of soil heat flux)');

  ParCreate('Photosynthesis_Intercept', '[]', -52.51566, Par_Photosynthesis_Intercept);
  ParCreate('Photosynthesis_lnPAR','[]',6.74408,Par_Photosynthesis_lnPAR);
  ParCreate('Photosynthesis_CO2','[]',0.01246,Par_Photosynthesis_CO2);
  ParCreate('Photosynthesis_NcLeaf','[]',2.61793,Par_Photosynthesis_NcLeaf);
  ParCreate('Photosynthesis_TempStress','[]',8.30991,Par_Photosynthesis_TempStress);
  ParCreate('Photosynthesis_alpha','[]',0.0652,Par_Photosynthesis_alpha);
  ParCreate('Photosynthesis_beta','[]',7E-5,Par_Photosynthesis_beta);
  ParCreate('Photosynthesis_gamma','[]',0.0019,Par_Photosynthesis_gamma);
  ParCreate('Photosynthesis_RespirationDark','[]',-1.26,Par_Photosynthesis_RespirationDark);
  //ParCreate('Photosynthesis_lnPAR_CO2','[]',0.010230,Par_Photosynthesis_lnPAR_CO2);
  //ParCreate('Photosynthesis_lnPAR_NcLeaf','[]',1.549367,Par_Photosynthesis_lnPAR_NcLeaf);
  //ParCreate('Photosynthesis_lnPAR_TempStress','[]',3.485549,Par_Photosynthesis_lnPAR_TempStress);
  //ParCreate('Photosynthesis_NcLeaf_TempStress','[]',-3.170152,Par_Photosynthesis_NcLeaf_TempStress);
  ParCreate('fCO2_scale','[]',0.723317226,Par_fCO2_scale);
  ParCreate('CO2_CiCompensation','[ppm]',350,Par_CiCompensation);
  ParCreate('fCO2','[]',0.08598933399681,Par_fCO2);

  ParCreate('WangEngelTmin','[∞C]',  0,WangEngelTmin);
  ParCreate('WangEngelTmax','[∞C]', 42,WangEngelTmax);
  ParCreate('WangEngelTopt','[∞C]', 28,WangEngelTopt);
  ParCreate('Par_rs_A_intercept','[]', 0.04491, Par_rs_A_intercept,'Bunce et al - citation ToBeFilled'); // 0.06246,Par_rs_A_intercept);
  ParCreate('Par_rs_A_lin','[]', 14.01642, Par_rs_A_lin,'Bunce et al - citation ToBeFilled'); // -0.02106,Par_rs_A_lin);
  //ParCreate('Par_rs_A_quad','[]', 0.002625,Par_rs_A_quad);
  //ParCreate('Par_rs_A_cubic','[]', -0.0000638,Par_rs_A_cubic);
  //ParCreate('Par_rs_A_RH_CO2','[]', 266.6,Par_rs_A_RH_CO2);

  ExternVCreate('CO2pp','[ppm]',statefield,CO2pp);
  ExternVCreate('Temp', '[∞C]', StateField, Temp); // Temperatur [∞C]
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad);
  // Nettostrahlung [W.m-2]
  ExternVCreate('Sat_def', '[hPa]', StateField, Sat_def);
  // S‰ttigungsdefizit [hPa]
  ExternVCreate('Wind', '[m.s-1]', StateField, wind_speed);
  // Windgeschwindigkeit [m.s-1]
  ExternVCreate('CropHeight', '[m]', StateField, ExCropHeight);
  // Pflanzenhˆhe [cm]
  ExternVCreate('LAI', '[-]', StateField, ExLAI); // Blattfl‰chenindex []
  ExternVCreate('rain', '[mm.d-1]', StateField, rain); // Niederschlag [mm/d]
  ExternVCreate('psiRoot', '[PF]', StateField, psiRoot);
  ExternVCreate('NcLeaf', '[%]', StateField, NcLeaf);
  ExternVCreate('kPAR_eff', '[]', StateField, kPAR_eff);  // Bei Umstellung auf Assimilation durch Photosynthese-Respirations-Ansatz noch zu ‰ndern
  ExternVCreate('WG_1', '[cm3/cm3]', StateField, WG_1);
  ExternVCreate('psi_1', '[]', StateField, psi_arr_1);
  ExternVCreate('Delta_AirTemp_Soil_1', '[∞C]', StateField, Delta_AirTemp_Soil_1);
  ExternVCreate('Sunrise', '[∞C]', StateField, Sunrise);
  ExternVCreate('Sunset', '[∞C]', StateField, Sunset);
  ExternVCreate('SLNI', '[∞C]', StateField, SLNI);
  ExternVCreate('LAI_GrowthCurvePlant', '[-]', StateField, LAI_GrowthCurvePlant);

  VarCreate('VapPress', '[mbar]', 0.0, false, VapPress);
  // Wasserdampfdruck [mbar]
  VarCreate('P', '[mbar]', 0.0, false, P); // Standardluftdruck [mbar] berechnet aus Temperatur und Hˆhe
  VarCreate('pETP', '[]', 0.0, false, pETP); // potentielle Evapotranspiration [mm.d-1]
  VarCreate('pETP_ambient', '[]', 0.0, false, pETP_ambient,'potentielle Evapotranspiration ohne CO2 Einfluss'); // potentielle Evapotranspiration [mm.d-1]
  VarCreate('pETP_Neukam', '[mm]', 0.0, false, pETP_Neukam,'potentielle Evapotranspiration aus kumulierten Stundenwerten nach Neukam');
  VarCreate('potEactT_Neukam', '[mm]', 0.0, false, potEactT_Neukam,'aktuelle Evapotranspiration aus kumulierten Stundenwerten nach Neukam');
  VarCreate('PotTrans', '[mm]', 0.0, false, pot_trans);
  VarCreate('pot_Transpiration_Neukam', '[mm]', 0.0, false, pot_Transpiration_Neukam,'potentielle Transpiration aus kumulierten Stundenwerten nach Neukam');
  VarCreate('actTranspiration_Neukam', '[mm]', 0.0, false, actTranspiration_Neukam,'aktuelle Transpiration aus kumulierten Stundenwerten nach Neukam');
  VarCreate('potTrans_ambient', '[mm]', 0.0, false, pot_trans_ambient);

  // potentielle Transpiration [mm.d-1]
  VarCreate('PotEvap', '[mm]', 0.0, false, pot_Evapo); // potentielle Evaporation
  VarCreate('pot_Evapo_ambient', '[mm]', 0.0, false, pot_Evapo_ambient); // potentielle Evaporation


  VarCreate('interzeption', '[]', 0.0, false, interzeption);
  // Interzeptionsverdunstung
  VarCreate('NetRain', '[mm]', 0.0, false, net_rain); // Niederschlag-Interzeption
  VarCreate('ra', '[]', 0.0, false, ra);
  VarCreate('rc', '[]', 0.0, false, rc);
  VarCreate('rc_ambient', '[]', 0.0, false, rc_ambient);
  VarCreate('NetRad', '[W.m-2]', 0.0, false, netRad); // Nettostrahlung [W.m-2]
  VarCreate('k_GlobRad', '[-]', 0.0, false, k_GlobRad);
  // extinction coefficient for GlobRad
  VarCreate('rc0_Var', '[s.m-1]', 0.0, false, rc0_Var,
    'rc0 value as used for calculation (from parameter or plant model)');
  VarCreate('rc0_ambient', '[s.m-1]', 0.0, false, rc0_ambient,
    'rc0 value without CO2 effect');
  VarCreate('CO2TransDiff', '[mm/d]', 0.0, false, CO2TransDiff,'CO2 induced reduction of pot_trans');
  VarCreate('relCO2TransDiff', '[-]', 0.0, false, relCO2TransDiff,'rel. CO2 induced reduction of pot_trans');
  VarCreate('r_surface', '[-]',0, false, r_surface);
  VarCreate('red_evap_', '[-]',0, false, red_evap_);
  VarCreate('LastDeltaT', '[∞C]',0, false, LastDeltaT);
  VarCreate('netAssimilation', '[gC / m2]',0, false, netA, 'daily photosynthetic carbon gain');

  StateCreate('Cum_C_Assimilation', '[g/m2]', 0, true, Cum_C_Assimilation);
  for j := 1 to 4 do begin
   ExternVCreate('PhotosynthesisRestr_LeafLayer_' + IntToStr(j), '[-]', StateField, PhotosynthesisRestr_LeafLayer[j],
                      'rel. restriction of photosynthesis due to N supply in particular leaf layer');
  end;
  for i := 1 to 24 do
  begin
      if i<=4 then begin
      ExternVCreate('NcLAL__' + IntToStr(i), '[g/m2]',  StateField, NcLAL[i],'leaf nitrogen concentration of specific leaf layer - Calculation in SubPartitioningSimple1');
      ExternVCreate('LAL_' + IntToStr(i), '[m2/m2]',  StateField, LAL[i],'leaf area of specific leaf layer - Calculation in SubLeafAreaSimple1');
      VarCreate('local_LAL_' + IntToStr(i), '[m2/m2]', 0, true, local_LAL[i]);
      //ExternVCreate('MLAL_' + IntToStr(i), '[m2/m2]',  StateField, MLAL[i],'leaf mass of specific leaf layer - Calculation in SubLeafAreaSimple1');
      end;

    if i<11 then begin
      VarCreate('netRad_0' + IntToStr(i-1) + IntToStr(30), '[MJ/m2]', 0, true, netRad_hour[i],'net radiation at particular time');
      VarCreate('rstom_0' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rstom[i],'stomatal resistance at particular time');
      VarCreate('gstom_0' + IntToStr(i-1) + IntToStr(30), '[cm/s]', 0, true, gstom[i],'stomatal conductance at particular time');
      VarCreate('rs_Rn_0' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rs_Rn[i]);
      VarCreate('rs_T_0' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rs_T[i]);
      VarCreate('rs_VPD_0' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rs_VPD[i]);
      ExternVCreate('TMPM_0' + IntToStr(i-1) + IntToStr(30), '[∞C]',  StateField, TMPM_hour[i]);
      ExternVCreate('Wind_0' + IntToStr(i-1) + IntToStr(30), '[m/s]',  StateField, Wind_hour[i]);
      ExternVCreate('GlobRad_0' + IntToStr(i-1) + IntToStr(30), '[MJ/m2]',  StateField, GlobRad_hour[i]);
      ExternVCreate('Rad_Int_0' + IntToStr(i-1) + IntToStr(30), '[W/m2]',  StateField, Rad_Int_hour[i]);
      ExternVCreate('Sat_def_0' + IntToStr(i-1) + IntToStr(30), '[mbar]',  StateField, Sat_def_hour[i]);
      ExternVCreate('Precip_0' + IntToStr(i-1) + IntToStr(30), '[mm]',  StateField, Precip_hour[i]);
      ExternVCreate('CO2_0' + IntToStr(i-1) + IntToStr(30), '[ppm]',  StateField, CO2_hour[i]);
      ExternVCreate('LF_0' + IntToStr(i-1) + IntToStr(30), '[%]',  StateField, LF_hour[i]);
      ExternVCreate('Cloud_fraction_0' + IntToStr(i-1) + IntToStr(30), '[%]',  StateField, Cloud_fraction[i]);
      VarCreate('rc_Neukam_0' + IntToStr(i-1) + IntToStr(30), '[s/m]',0, true, rc_Neukam[i]);
      VarCreate('pETP_Neukam_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, pETP_Neukam_hour[i], 'potential evapotranspiration at particular time');
      VarCreate('potEactT_Neukam_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, potEactT_Neukam_hour[i], 'sum of potential evaporation and actual transpiration and  at particular time');
      VarCreate('potEvaporation_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, potEvaporation_hour[i], 'potential evaporation at particular time');
      VarCreate('Tcrop_max_0' + IntToStr(i-1) + IntToStr(30), '[∞C]',0, true, Tcrop_max[i],'theoretical upper limit of canopy temperature at particular time according to Jackson et al. 1988');
      VarCreate('Tcrop_base_0' + IntToStr(i-1) + IntToStr(30), '[∞C]',0, true, Tcrop_base[i],'theoretical lower limit of canopy temperature at particular time according to Jackson et al. 1988');
      VarCreate('Tcrop_direct_0' + IntToStr(i-1) + IntToStr(30), '[∞C]',0, true, Tcrop_direct[i],'directly calculated canopy temperature at particular time according to Jackson et al. 1988');
      VarCreate('netRain_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, net_rain_hour[i], 'ToBeFilled');
      VarCreate('Interzeption_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, interzeption_hour[i], 'ToBeFilled');
      VarCreate('actT_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, actT_hour[i], 'ToBeFilled');
      VarCreate('potT_0' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, potT_hour[i], 'ToBeFilled');
      VarCreate('netA_0' + IntToStr(i-1) + IntToStr(30), '[gC /m2]',0, true, A_hour[i], 'Photosynthetic carbon gain during this paricular hour');
      VarCreate('TemperatureStress_0' + IntToStr(i-1) + IntToStr(30), '[-]',0, true, TemperatureStress[i], 'Temperature stress that affects photosynthetic rate of flag leaf at paricular time');
      VarCreate('PAR_0' + IntToStr(i-1) + IntToStr(30), '[µmol/mol*m2*s]',0, true, PAR_hour[i], 'ToBeFilled');

      for j := 1 to 4 do begin
        VarCreate('iPAR_LeafLayer'+ IntToStr(j) + '_0' + IntToStr(i-1) + IntToStr(30), '[µmol/m2*s]', 0, true, iPAR_LeafLayer[i,j],
                          'intercepted PAR of specific leaf layer at particular time');
        VarCreate('grossA_LeafLayer'+ IntToStr(j) + '_0' + IntToStr(i-1) + IntToStr(30), '[µmolCO2/m2LAI*s]', 0, true, grossA_LeafLayer[i,j],
                          'gross photosynthetic rate of specific leaf layer at particular time');
        VarCreate('A_LeafLayer'+ IntToStr(j) + '_0' + IntToStr(i-1) + IntToStr(30), '[µmolCO2/m2LAI*s]', 0, true, netA_LeafLayer[i,j],
                          'net photosynthetic rate of specific leaf layer at particular time');
      end;

    end else begin
      VarCreate('netRad_' + IntToStr(i-1) + IntToStr(30), '[MJ/m2]', 0, true, netRad_hour[i],'net radiation at particular time');
      VarCreate('rstom_' + IntToStr(i-1)+ IntToStr(30), '[s/m]', 0, true, rstom[i],'stomatal resistance at particular time');
      VarCreate('gstom_' + IntToStr(i-1)+ IntToStr(30), '[cm/s]', 0, true, gstom[i],'stomatal conductance at particular time');
      VarCreate('rs_Rn_' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rs_Rn[i]);
      VarCreate('rs_T_' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rs_T[i]);
      VarCreate('rs_VPD_' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rs_VPD[i]);
      ExternVCreate('TMPM_' + IntToStr(i-1) + IntToStr(30), '[∞C]', StateField, TMPM_hour[i]);
      ExternVCreate('Wind_' + IntToStr(i-1) + IntToStr(30), '[m/s]',  StateField, Wind_hour[i]);
      ExternVCreate('GlobRad_' + IntToStr(i-1) + IntToStr(30), '[MJ/m2]', StateField, GlobRad_hour[i]);
      ExternVCreate('Rad_Int_' + IntToStr(i-1) + IntToStr(30), '[W/m2]',  StateField, Rad_Int_hour[i]);
      ExternVCreate('Sat_def_' + IntToStr(i-1) + IntToStr(30), '[mbar]', StateField, Sat_def_hour[i]);
      ExternVCreate('Precip_' + IntToStr(i-1) + IntToStr(30), '[mm]',  StateField, Precip_hour[i]);
      ExternVCreate('CO2_' + IntToStr(i-1) + IntToStr(30), '[ppm]',  StateField, CO2_hour[i]);
      ExternVCreate('LF_' + IntToStr(i-1) + IntToStr(30), '[%]',  StateField, LF_hour[i]);
      ExternVCreate('Cloud_fraction_' + IntToStr(i-1) + IntToStr(30), '[%]',  StateField, Cloud_fraction[i]);
      VarCreate('rc_Neukam_' + IntToStr(i-1) + IntToStr(30), '[s/m]', 0, true, rc_Neukam[i]);
      VarCreate('pETP_Neukam_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, pETP_Neukam_hour[i], 'potential evapotranspiration at particular time');
      VarCreate('potEactT_Neukam_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, potEactT_Neukam_hour[i], 'actual evapotranspiration at particular time');
      VarCreate('potEvaporation_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, potEvaporation_hour[i], 'potential evaporation at particular time');
      VarCreate('Tcrop_max_' + IntToStr(i-1) + IntToStr(30), '[∞C]',0, true, Tcrop_max[i],'theoretical upper limit of canopy temperature at particular time according to Jackson et al. 1988');
      VarCreate('Tcrop_base_' + IntToStr(i-1) + IntToStr(30), '[∞C]',0, true, Tcrop_base[i],'theoretical lower limit of canopy temperature at particular time according to Jackson et al. 1988');
      VarCreate('Tcrop_direct_' + IntToStr(i-1) + IntToStr(30), '[∞C]',0, true, Tcrop_direct[i],'directly calculated canopy temperature at particular time according to Jackson et al. 1988');
      VarCreate('netRain_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, net_rain_hour[i], 'ToBeFilled');
      VarCreate('Interzeption_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, interzeption_hour[i], 'ToBeFilled');
      VarCreate('actT_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, actT_hour[i], 'ToBeFilled');
      VarCreate('potT_' + IntToStr(i-1) + IntToStr(30), '[mm]',0, true, potT_hour[i], 'ToBeFilled');
      VarCreate('netA_' + IntToStr(i-1) + IntToStr(30), '[gC /m2]',0, true, A_hour[i], 'Photosynthetic carbon gain during this paricular hour');
      VarCreate('TemperatureStress_' + IntToStr(i-1) + IntToStr(30), '[-]',0, true, TemperatureStress[i], 'Temperature stress that affects photosynthetic rate of flag leaf at paricular time');
      VarCreate('PAR_' + IntToStr(i-1) + IntToStr(30), '[µmol/mol*m2*s]',0, true, PAR_hour[i], 'ToBeFilled');
      for j := 1 to 4 do begin
        VarCreate('iPAR_LeafLayer'+ IntToStr(j) + '_' + IntToStr(i-1) + IntToStr(30), '[µmol/m2*s]', 0, true, iPAR_LeafLayer[i,j],
                          'intercepted PAR of specific leaf layer at particular time');
        VarCreate('grossA_LeafLayer'+ IntToStr(j) + '_' + IntToStr(i-1) + IntToStr(30), '[µmolCO2/m2LAI*s]', 0, true, grossA_LeafLayer[i,j],
                          'gross photosynthetic rate of specific leaf layer at particular time');
        VarCreate('A_LeafLayer'+ IntToStr(j) + '_' + IntToStr(i-1) + IntToStr(30), '[µmolCO2/m2LAI*s]', 0, true, netA_LeafLayer[i,j],
                          'net photosynthetic rate of specific leaf layer at particular time');
      end;

    end;
  end;

 // VarCreate('rstom', '[s/m]', 0.0, false, rstom, 'stomatal resistance');
 // VarCreate('gstom', '[cm/s]', 0.0, false, gstom, 'stomatal conductance');//  dn (30.07.12)
 // VarCreate('rs_Rn', '[]', 1.0, false, rs_Rn);
 // VarCreate('rs_T', '[]', 1.0, false, rs_T);
 // VarCreate('rs_VPD', '[]', 1.0, false, rs_VPD);

  StateCreate('int_stor', '[mm]', 0.0, false, int_stor);
  StateCreate('int_stor_hour', '[mm]', 0.0, false, int_stor_hour);
  // Interzeptionsspeicher [mm]
 OptCreate('ra_Option', 'PenmanMonteith', f_ra_Option, 'Option for ra(u,CropHeight)-function');
  f_ra_Option.OptionList.Add('PenmanMonteith');
  f_ra_Option.OptionList.Add('ThomOliver');

 OptCreate('optCO2', 'NoCO2Effect', OptWithCO2);
  OptWithCO2.OptionList.Clear;
  OptWithCO2.OptionList.Add('NoCO2Effect');
  OptWithCO2.OptionList.Add('WithCO2Effect');
  //Opt_StomataCalculation
 OptCreate('StomataCalculation','Neukam_default_CO2insensitive', Opt_StomataCalculation);
  Opt_StomataCalculation.OptionList.Add('Neukam_default_CO2insensitive');
  Opt_StomataCalculation.OptionList.Add('neukam_extended_co2sensitive');

  OptCreate('LAI_Source_StomataCalculation','simulated_lai_from_subleafareasimple', Opt_LAI_Source_StomataCalculation);
  Opt_LAI_Source_StomataCalculation.OptionList.Add('simulated_lai_from_subleafareasimple');
  Opt_LAI_Source_StomataCalculation.OptionList.Add('simulated_lai_from_growthcurveplant');

 OptCreate('SoilSurfaceHeatFlux','jackson_et_al_1988', Opt_SoilSurfaceHeatFlux);
  Opt_SoilSurfaceHeatFlux.OptionList.Add('jackson_et_al_1988');
  Opt_SoilSurfaceHeatFlux.OptionList.Add('allen_et_al_1998');

 OptCreate('rc_upscaling_Option','Stockle', f_rc_upscaling_Option, 'Option for upscaling canopy resistance from stomatal resistance');
  f_rc_upscaling_Option.OptionList.Add('Stockle');
  f_rc_upscaling_Option.OptionList.Add('BenMehrez');
  end;

procedure TpenMonteith_Hybrid.Init;
begin
  inherited;
  if uppercase(f_ra_Option.Option) = uppercase('PenmanMonteith') then f_ra_funct := PenmanMonteith;
  if uppercase(f_ra_Option.Option) = uppercase('ThomOliver') then f_ra_funct := ThomOliver;

  if uppercase(Opt_StomataCalculation.Option) = uppercase('Neukam_default_CO2insensitive') then f_StomataCalculation := Neukam_default_CO2insensitive;
  if uppercase(Opt_StomataCalculation.Option) = uppercase('neukam_extended_co2sensitive') then f_StomataCalculation := Neukam_extended_CO2sensitive;

  if OptWithCO2.option = 'withco2effect' then
     CO2pp.Search := true
  else
    CO2pp.Search := false;
end;

procedure TPenMonteith_Hybrid.CalcRates;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
var
  // pressure,           // Luftdruck [mbar]
  gamma, es, // S‰ttigungsdampfdruck [mbar]
  { ea,       // aktueller Dampfdruck [mbar] }
  delta, relDeltaCi,actTwithInterzeption,
  Icu_, Icl_: real;
  i, j:integer;
  f_int: array [1..4] of real;
  incidentPAR_, actEvaporation_temp, Tcrop_ETR:  real;
  ra_hour, rc_pot_Neukam, rho, gamma_stern, gamma_Neukam, deltaTmax, deltaTbase, LastCanopyTemp2330: real;
  //PAR_hour: array[1..24] of real;
  actTI_hour: array[1..24] of real;
  CWSI_hour: array[1..24] of real;
  netAssimilationLeafLayer1,   netAssimilationLeafLayer2,   netAssimilationLeafLayer3,   netAssimilationLeafLayer4: real;
const
  cp = 1003.0;      { spezifische WÑrme der Luft [J/(Kg*K)] }
  //Icu = 0.8;      {nach Jackson et al. 1988, wegen erhˆhter Reflexion und Emission des fiktiv nicht transpirierenden Bestandes}
  //Icl = 0.9;     {nach Jackson et al. 1988, Ber¸cksichtigung des Bodenw‰rmestroms}
begin { Evapo_transpi }

  pETP_Neukam.v := 0;
  potEactT_Neukam.v := 0;
  rc_pot_Neukam := rc_upscaling_f(rstom0_Neukam.v, f_rc_upscaling);
  actTranspiration_Neukam.v :=0;
  pot_Transpiration_Neukam.v :=0;
 // if GlobTime.v = 35198 then
 //   pot_Transpiration_Neukam.v :=0;
  r_surface.v := r_surface_f(WG_1.v);
  CalcEvap_red_f;

  if(Opt_LAI_Source_StomataCalculation.Option = 'simulated_lai_from_subleafareasimple') then begin
       local_LAL[1].v := LAL[1].v;
       local_LAL[2].v := LAL[2].v;
       local_LAL[3].v := LAL[3].v;
       local_LAL[4].v := LAL[4].v;
     end;
  if(Opt_LAI_Source_StomataCalculation.Option = 'simulated_lai_from_growthcurveplant') then begin
       local_LAL[1].v := LAI_GrowthCurvePlant.v * (0.2976 + 0.0087 * max(2,min(6,LAI_GrowthCurvePlant.v)));
       local_LAL[2].v := LAI_GrowthCurvePlant.v * (0.2562 + 0.0187 * max(2,min(6,LAI_GrowthCurvePlant.v)));;
       local_LAL[3].v := LAI_GrowthCurvePlant.v * (0.2404 - 0.0018 * max(2,min(6,LAI_GrowthCurvePlant.v)));;
       local_LAL[4].v := LAI_GrowthCurvePlant.v - local_LAL[1].v - local_LAL[2].v - local_LAL[3].v;
     end;
   netA.v:= 0;
  //LastCanopyTemp2330 := Tcrop_direct[24].v;
  for i := 1 to 24 do                                         //
 //  if i>1 then
  //  LastCanopyTemp2330 := Tcrop_direct[i - 1].v;
   begin
    PAR_hour[i].v := Rad_Int_hour[i].v * 4.6 / 2;
    TemperatureStress[i].v := fT_WE(TMPM_hour[i].v,WangEngelTmin.v,WangEngelTmax.v,WangEngelTopt.v);
     for j := 1 to 4 do begin
      if j = 1 then
        incidentPAR_ := PAR_hour[i].v
      else
        incidentPAR_ := incidentPAR_ - incidentPAR_ * (1 - EXP(- 0.7 * local_LAL[j-1].v));


      grossA_LeafLayer[i,j].v := GaussianIntegration(local_LAL[j].v, 0.7, incidentPAR_, CO2_hour[i].v, SLNI.v, TemperatureStress[i].v);
      netA_LeafLayer[i,j].v := grossA_LeafLayer[i,j].v * min(PhotosynthesisRestr_LeafLayer[j].v, TemperatureStress[i].v);

      {f_int[j]:= EXP(- 0.7 * (LAL[j].v / 2));
      iPAR_LeafLayer[i,j].v := incidentPAR_  * f_int[j];
      A_LeafLayer[i,j].v    := Photosynthesis(iPAR_LeafLayer[i,j].v, CO2_hour[i].v, NcLAL[j].v, TemperatureStress[i].v);}
    end;

     //iPAR_LeafLayerCalculation_p;

     //Photosynthesis(PAR_hour[i].v, CO2_hour[i].v, SLNI.v, TemperatureStress[i].v);
     rc_p;                                         // calculate stomatal resistance
      {  structure                 O = C = O
         molar mass         15.999  12.011  15.999        g/mol

                 for every g CO2  30/44  g CH20  are produced

                           ((30/44) * (2*15.999+12.011)) *(3600/1000000)  =  0.1080221
                }
     netAssimilationLeafLayer1:= 0.1080221 * netA_LeafLayer[i,1].v * local_LAL[1].v;// netAssimilationLeafLayer1 + //( * ((netA_LeafLayer[i,1].v * (3600/1000000)) * local_LAL[1].v));
     netAssimilationLeafLayer2:= 0.1080221 * netA_LeafLayer[i,2].v * local_LAL[2].v;// netAssimilationLeafLayer2 + //( * ((netA_LeafLayer[i,2].v * (3600/1000000)) * local_LAL[2].v));
     netAssimilationLeafLayer3:= 0.1080221 * netA_LeafLayer[i,3].v * local_LAL[3].v;// netAssimilationLeafLayer3 + //( * ((netA_LeafLayer[i,3].v * (3600/1000000)) * local_LAL[3].v));
     netAssimilationLeafLayer4:= 0.1080221 * netA_LeafLayer[i,4].v * local_LAL[4].v;// netAssimilationLeafLayer4 + //( * ((netA_LeafLayer[i,4].v * (3600/1000000)) * local_LAL[4].v));
     A_hour[i].v := netAssimilationLeafLayer1 +
                    netAssimilationLeafLayer2 +
                    netAssimilationLeafLayer3 +
                    netAssimilationLeafLayer4;

     netA.v:= netA.v + A_hour[i].v;
     if ExCropHeight.v <= 0.0 then
       ra_hour := ra_f(wind_hour[i].v, 0.05)
     else
       ra_hour := ra_f(wind_hour[i].v, ExCropHeight.v);

     rho := dens_air(TMPM_hour[i].v);
     es := sat_vap_press_f(TMPM_hour[i].v);
     delta := delta_f(es, TMPM_hour[i].v);
     P.v := pressure_f(Elev.v, TMPM_hour[i].v);
     gamma := P.v * Psycro;
     gamma_Neukam := cp * P.v/(0.622 * (2.502 * 1000000 - 2361 * TMPM_hour[i].v));
     gamma_stern := gamma_Neukam * (1 + rc_pot_Neukam / ra_hour);
     pETP_Neukam_hour[i].v := (Penman(TMPM_hour[i].v, Sat_def_hour[i].v, netRad_hour[i].v, delta, gamma_Neukam, l_h_v_water,
                                       ra_hour, rc_pot_Neukam) / 24);
     pETP_Neukam.v := pETP_Neukam.v  + pETP_Neukam_hour[i].v;
     potEactT_Neukam_hour[i].v := (Penman(TMPM_hour[i].v, Sat_def_hour[i].v, netRad_hour[i].v, delta, gamma_Neukam, l_h_v_water,
                                       ra_hour, rc_Neukam[i].v) / 24);
     potEactT_Neukam.v := potEactT_Neukam.v  + potEactT_Neukam_hour[i].v;

     potEvaporation_hour[i].v:= Evaporation_f(pETP_Neukam_hour[i].v);
     actEvaporation_temp := potEvaporation_hour[i].v * red_evap_.v;
     pTI_hour[i]:=   pETP_Neukam_hour[i].v  -  potEvaporation_hour[i].v;

     // actTI_hour[i]:= potEactT_Neukam_hour[i].v -  potEvaporation_hour[i].v;  // interzeption still included    !!!!
     // hourlyInterzeption_p;
     potT_hour[i].v := pETP_Neukam_hour[i].v -  potEvaporation_hour[i].v - interzeption_hour[i].v;
     pot_Transpiration_Neukam.v := pot_Transpiration_Neukam.v + potT_hour[i].v;

     if(ExLAI.v <= 0.5) then                //AL (9.2.2017): calibration of Neukam et al. took place on higher LAI
      actT_hour[i].v := potT_hour[i].v      //AL (9.2.2017): Assumption that there is no water stress at this early growth
     else
      actT_hour[i].v := potEactT_Neukam_hour[i].v -  potEvaporation_hour[i].v - interzeption_hour[i].v;

     actTranspiration_Neukam.v := actTranspiration_Neukam.v + actT_hour[i].v;
     CWSI_hour[i] := 0;
     if pETP_Neukam_hour[i].v >0 then
       CWSI_hour[i] := (actEvaporation_temp + actT_hour[i].v) / pETP_Neukam_hour[i].v;

     if (Opt_SoilSurfaceHeatFlux.option = 'jackson_et_al_1988') then begin
       Icu_ := Icu.v;
       Icl_ := Icl.v;
     end;

     if (Opt_SoilSurfaceHeatFlux.option = 'allen_et_al_1998') and
         (i > Round(Sunrise.v)) and
         (i < Round(Sunset.v)) then begin
       Icu_ := Icu.v;
       Icl_ := Icl.v;
     end else begin
       Icu_ := Ic_allen_etal_1998_night.v;
       Icl_ := Ic_allen_etal_1998_night.v;
     end;

     deltaTmax:=ra.v * Icu_ * netRad_hour[i].v / (cp * rho);
     deltaTbase:= ra.v * Icl_ * netRad_hour[i].v / (cp * rho) * gamma_stern / (delta + gamma_stern) - Sat_def_hour[i].v / (delta + gamma_stern);

     Tcrop_max[i].v := TMPM_hour[i].v + deltaTmax;
     Tcrop_base[i].v := TMPM_hour[i].v + deltaTbase;
     Tcrop_direct[i].v := TMPM_hour[i].v + ra_hour * Icl_ * netRad_hour[i].v / (cp * rho) * gamma_Neukam * (1 + rc_Neukam[i].v / ra_hour) / (delta + gamma_Neukam * (1 + rc_Neukam[i].v / ra_hour))- Sat_def_hour[i].v / (delta + gamma_Neukam * (1 + rc_Neukam[i].v / ra_hour));

     Tcrop_ETR := TMPM_hour[i].v + CWSI_hour[i] * (deltaTmax - deltaTbase) + deltaTbase;

     if (i > Round(Sunrise.v)) and (i < Round(Sunset.v)) then
       LastDeltaT.v:= Tcrop_ETR - TMPM_hour[i].v  // TMPM_hour[i].v - Tcrop_ETR; //
     else
       LastDeltaT.v:= 0;

   end;

   Cum_C_Assimilation.c:= netA.v;

  if (frc0Opt = fromPlantModel) and IsPlantModelSet then
    rc0_Var.v := Plantmodel.rc0
  else
    rc0_Var.v := rc0.v;
    rc0_ambient.v:=rc0_Var.v;
    if(GlobTime.v=33977) then
      rc0_ambient.v:=rc0_Var.v;

// Impact of CO2
  if OptWithCO2.option = 'withco2effect' then begin
     relDeltaCi:= (CO2pp.v- CiThreshold.v)/CiThreshold.v;
     rc0_Var.v := rc0_Var.v*(1+relDeltaCi*relRc0Inc_CO2.v);
  end;

    rc.v := rc_upscaling_f(rc0_Var.v, f_rc_upscaling);
    rc_ambient.v := rc_upscaling_f(rc0_ambient.v, f_rc_upscaling);

  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstahlung (W/m2)
  //netRad.v := max(0,mean(netRad_hour.v));
  netRad.v := max(0, 0.6494 * (GlobRad.v) - 18.417);        // ACHTUNG in Wetterdateien ist Rad_Int in [W/m2] und nicht GlobRad [MJ/m2 d]
  P.v := pressure_f(Elev.v, Temp.v);
  gamma := P.v * Psycro;
  es := sat_vap_press_f(Temp.v);
  VapPress.v := es - Sat_def.v;
  { if relFeu.v > 100.0 then
    ea            := 99.0*es/100
    else
    ea            := relFeu.v*es/100.0;
    sat_def.v     := es-ea; }

  delta := delta_f(es, Temp.v);
  if ExCropHeight.v <= 0.0 then
    ra.v := ra_f(wind_speed.v, 0.05)
  else
    ra.v := ra_f(wind_speed.v, ExCropHeight.v);

  pETP_ambient.v := Penman(Temp.v, Sat_def.v, netRad.v, delta, gamma, l_h_v_water,
    ra.v, rc_ambient.v);

  pETP.v := Penman(Temp.v, Sat_def.v, netRad.v, delta, gamma, l_h_v_water,
    ra.v, rc.v);


  pot_Evapo_ambient.v := Evaporation_f(pETP_ambient.v);
  pot_Evapo.v := Evaporation_f(pETP.v);


  pTI := pETP.v - pot_Evapo.v;

  Interzeption_p;

  If pETP.v > 0.0 then
    pot_trans.v := (pETP.v - pot_Evapo.v - interzeption.v)
  else
    pot_trans.v := 0.0;
  If pot_trans.v <= 1E-10 then
    pot_trans.v := 0.0;

{ If actTwithInterzeption > 0.0 then
    actTranspiration_Neukam.v := actTwithInterzeption - interzeption.v
  else
    actTranspiration_Neukam.v := 0.0;    }
  If actTranspiration_Neukam.v <= 1E-10 then
    actTranspiration_Neukam.v := 0.0;

  If pETP_ambient.v > 0.0 then
    pot_trans_ambient.v := (pETP_ambient.v - pot_Evapo_ambient.v - interzeption.v)
  else
    pot_trans_ambient.v := 0.0;
  If pot_trans_ambient.v <= 1E-10 then
    pot_trans_ambient.v := 0.0;

   CO2TransDiff.v:= (pot_trans.v+interzeption.v)- (pot_trans_ambient.v+interzeption.v);
   if pot_trans.v>0 then
    relCO2TransDiff.v:=CO2TransDiff.v/(pot_trans.v+interzeption.v)
    else relCO2TransDiff.v:=0;

end; { Evapo_transpi }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith_Hybrid.SetPlantModel(NewPlantmodel: TAbstractPlant);

begin
  inherited SetPlantModel(NewPlantmodel);
  if IsPlantModelSet then begin
    ExLAI.Search := false;
    // If Ex_LAI.f_v = nil then
    ExLAI.f_v := @Plantmodel.p_LAI.fv;
    ExLAI.Source := Plantmodel.Name;
    Ex_CropHeight.Search := false;
    // if Ex_CropHeight.f_v = nil then
    Ex_CropHeight.f_v := @Plantmodel.p_CropHeight.fv;
    Ex_CropHeight.Source := Plantmodel.name;
  end;
end;

{ ----------------------------------------------------------------------- }

procedure Register;
begin
  RegisterComponents('Simulation', [TPenMonteith_Hybrid]);
end;

end.

