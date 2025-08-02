/// <summary>
///   Unit for calculating transpiration, evaporation, and interception using standard weather and plant data,
///   based on the Penman-Monteith approach and related literature.
/// </summary>
/// <remarks>
///   <author>
///     Henning Kage & Agronomy Group, University of Kiel
///   </author>
///   <Timestamp>
///     First edited: 6.10.89
///     Last edited: 16.1.95
///   </Timestamp>
///   <References>
///       <item>van Bavel, C.H.M. (1966). Potential evaporation: The Combination Concept and its Experimental Verification. Water Resour.Res. (1966) 2, 455-467</item>
///       <item>Duynisveld, W.H.M. (1983). Entwicklung von Simulationsmodellen fuer den Transport von geloesten Stoffen in wasserungesaettigten Boeden and Lockersedimenten. Texte Umweltbundesamt (1983) 17, 197 Seiten</item>
///       <item>Monteith, J.L. (1973). Principles of Environmental Physics. Edward Arnold, London, 1973, 241 Seiten</item>
///       <item>Groot, J.J.R. (1987). Simulation of nitrogen balance in a system of winter wheat and soil. Simulation Reports CABO-TT, Wageningen 1987</item>
///       <item>Loebmeier, F.J. (1983). Agrarmeteorologisches Model zur Berechnung der aktuellen Verdunstung (AMBAV). Beitraege zur Agrarmeteorologie Nr. 7/83</item>
///   </References>
///   <Purpose>
///     Calculation of transpiration, evaporation, and interception from standard weather and plant data.
///   </Purpose>
/// </remarks>

unit UPenMonteith;

interface

uses
  UMod, UState, classes, UAbstractPlant, Math;

const
/// <summary> latent heat for water evaporation at 10 °C in [J/Kg] </summary>
  l_h_v_water = 2.477 * 1E6;  

/// <summary> ratio of the molecular weight of water to the molecular weight of dry air </summary>
  MW_ratio = 0.622;

/// <summary> specific heat of air at constant pressure [J/kg/K] </summary>
  c_p = 1005;        

type

/// <summary> Source of extinction coefficient / rc0 </summary>
  TSource = (fromParameter, fromPlantModel);

/// <summary> Options for ra calculation </summary>
  T_ra_Funct = (PenmanMonteith, ThomOliver);


/// <summary> The class TPenMonteith implements the Penman-Monteith equation. This equation is a widely used method for estimating evapotranspiration (ET). It combines the principles of energy balance and mass transfer to calculate ET. The FAO (Food and Agriculture Organization) version of this equation is specifically designed for estimating reference evapotranspiration (ETo) from a hypothetical reference surface </summary>
  TPenMonteith = class(TPlantRelatedSubMod)
  protected

/// <summary>
/// potential evapotranspiration [mm/d]
/// </summary>
    pTI: real;

    procedure Calc_Interception;
    function Evaporation_f: real;
    function Evaporation_f_ambient: real;
    function pressure_f(Elev, Temp: real): real;
    function sat_vap_press_f(Temp: real): real;
    function delta_f(sat_vap_press, Temp: real): real;
    function ra_f(wind_speed, crop_height: real): real;
    function Penman(Temp, Sat_def, Net_beam, delta, gamma, l_h_v_water, ra,
      rc: real): real;
//    function Calc_psychro(P, Temp:real):real;
  private
/// <summary> Source of extinction coefficient </summary>
    fExkOpt: TSource;

/// <summary> Source of rc0 </summary>
    frc0Opt: TSource;
/// <summary> calculations with CO2-effect? </summary>
    fCO2effect: boolean;
/// <summary> type of ra function to be used </summary>
    f_ra_funct: T_ra_Funct;
    procedure CreateOptions;
    procedure CreatePars;
    procedure CreateVars;
    procedure CreateExterns;
    procedure Calc_rc0(Plant_rc0, CO2pp, CiThreshold, relRc0Inc_CO2:real;
                               CO2effect: boolean);
    function Calc_rc(rc0, LAI: real): real;
    function Calc_psychro(P, Temp:real): real;
    procedure Calc_ra;
    procedure Calc_potTrans;

  public
/// <summary> height above sea level [m] </summary>
    Elev: TPar; // height avove sea level [m]

/// <summary> stomata resistance at "good water supply" [s.m-1] </summary>
    rc0: TPar; // stomata resistance at "good water supply"
    
/// <summary> extinction coefficient for global radiation [-] </summary>
    exk_GlobRad: TPar; // extinction coefficient for global radiation [-]
    
/// <summary> specific interception capacity per unit leaf area index [mm/LAI] </summary>
    sic: TPar; // specific interception capazity per unit LAI [mm/LAI] }
    
/// <summary> threshold for CO2 partial pressure [ppm] </summary>
    CiThreshold: TPar; // Schwellwert for CO2 partial pressure [ppm]
    
/// <summary> relative increase of rc0 trough CO2 [1/ppm] </summary>
    relRc0Inc_CO2: TPar;  // relative increase of rc0 trough CO2 [1/ppm]
    
/// <summary> measurement height of the parameters [m] </summary>
    measure_height: TPar; // measurement height of meteorological parameters [m]

/// <summary> Temperature [°C] </summary>
    Temp: TExternV; // Temperature [°C]
    
/// <summary> Global radiation [W.m-2] </summary>
    GlobRad: TExternV; // global radiation [W.m-2]
    
/// <summary> saturation deficit [mbar] </summary>
    Sat_def: TExternV; // saturation deficit [mbar]
    
/// <summary> wind speed [m.s-1] </summary>
    wind_speed: TExternV; // wind speed [m.s-1]
    
/// <summary> plant height [m] </summary>
    ExCropHeight: TExternV; // plant height [m]
    
/// <summary> leaf area index [] </summary>
    ExLAI: TExternV; // leaf area index []
    
/// <summary> external precipitation rate [mm/d] </summary>
    rain: TExternV; // precipitation rate [mm/d]
    
/// <summary> external CO2 partial pressure [ppm] </summary>
    ExCO2pp: TExternV; // Extenal CO2 partial pressure

/// <summary> standard air pressure [mbar] calculated from air temperature and height </summary>
    P: TVar; // standard air pressure [mbar] calculated aus air temperature and height
    
/// <summary> water vapour pressure [mbar] </summary>
    VapPress: TVar; // water vapour pressure [mbar]
    
/// <summary> potential evapotranspiration [mm.d-1] </summary>
    pETP: TVar; // potential evapotranspiration [mm.d-1]

/// <summary> reference evapotranspiration according to FAO [mm.d-1] </summary>
    ET0: TVar; // potential reference (FAO) evapotranspiration
    
/// <summary> potential evapotranspiration no CO2 effect [mm.d-1] </summary>
    pETP_ambient: TVar; // potential evapotranspiration no CO2 effect [mm.d-1]
    
/// <summary> potential transpiration/interception [mm.d-1] </summary>
    pot_trans: TVar; // potential transpiration [mm.d-1]
    
/// <summary> potential transpiration/interception at ambient CO2 [mm.d-1] </summary>
    pot_trans_ambient: TVar; // potential transpiration [mm.d-1]
    
/// <summary> potential Evaporation [mm.d-1] </summary>
    pot_Evapo: TVar; // potential Evaporation
    
/// <summary> potential Evaporation  [mm.d-1] </summary>
    pot_Evapo_ambient: TVar; // potential Evaporation
    
/// <summary> interception [mm.d-1] </summary>
    interception: TVar; // interception
    
/// <summary> net precipitation rate [mm.d-1] </summary>
    net_rain: TVar; // precipitation rate-interception
    
/// <summary> net radiation [W.m-2] </summary>
    netRad: TVar; // net radiation

/// <summary> extinction coefficient for GlobRad [-] </summary>
    k_GlobRad: TVar; // extinction coefficient for GlobRad
    
/// <summary> aerodynamic resistance [s.m-1] </summary>
    ra: TVar; // aerodynamic resistance [s.m-1]
    
/// <summary> canopy resistance [s.m-1] </summary>
    rc: TVar; // canopy resistance [s.m-1]
    
/// <summary> canopy resistance at ambient CO2 [s.m-1] </summary>
    rc_ambient: TVar; // canopy resistance at abmient CO2 [s.m-1]
    
/// <summary> stomata resistance at good water supply with effects of co2 [s.m-1] </summary>
    rc0_Var: TVar; // stomata resistance at good water supply with effects of co2 [s.m-1]
    
/// <summary> stomata resistance at good water supply without effects of co2 [s.m-1] </summary>
    rc0_ambient: TVar; // stomata resistance at good water supply with effects of co2 [s.m-1]
    
/// <summary> difference in potential transpiration due to CO2 effect [mm.d-1] </summary>
    CO2TransDiff: TVar; // difference in transpiration due to CO2 effect
    
/// <summary> relative difference in potential transpiration due to CO2 effect </summary>
    relCO2TransDiff: TVar; // relative difference in transpiration due to CO2 effect
    
/// <summary> CO2 partial pressure [ppm] </summary>
    CO2pp : TVar; //

/// <summary> option for ra(u,CropHeight)-function </summary>
    f_ra_Option: TOption;   // Option for ra(u,CropHeight)-function dn
    
/// <summary> option for CO2 effect </summary>
    OptWithCO2: TOption;    // Option for CO2 effect
/// <summary> option for external CO2-concentration </summary>
    OptExCO2 : TOption;    // Option for external CO2-concentration

/// <summary> interception storage [mm] </summary>
    int_stor: TState; // Interzeptionsspeicher [mm]
    
/// <summary> calculation of variables </summary>
    procedure CalcVars; override; // calculation of variables
    
/// <summary> calculation of rates </summary>
    procedure CalcRates; override; // calculation of rates
    
/// <summary> create all variables, parameters and externals </summary>
    procedure CreateAll; override; // create all variables, parameters and externals
    
/// <summary> initialization of parameters and states </summary>
    procedure Init(var GlobMod: Tmod); override; // initialization of parameters and states
    
/// <summary> set the plant model from which the LAI and CropHeight are taken </summary>
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override; // set the plant model from which the LAI and CropHeight are taken


  published
/// <summary> Air temperature [°C] </summary>
    property Ex_Temp: TExternV read Temp write Temp;
/// <summary> Global radiation [W.m-2] </summary>
    property Ex_GlobRad: TExternV read GlobRad write GlobRad;
/// <summary> saturation deficit [mbar] </summary>
    property Ex_Sat_def: TExternV read Sat_def write Sat_def;
/// <summary> Wind speed [m.s-1] </summary>
    property Ex_Windspeed: TExternV read wind_speed write wind_speed;
/// <summary> Plant height [m] </summary>
    property Ex_CropHeight: TExternV read ExCropHeight write ExCropHeight;
/// <summary> Leaf Area Index [] </summary>
    Property Ex_LAI: TExternV read ExLAI write ExLAI;
/// <summary> Precipitation [mm.d-1] </summary>
    Property Ex_Rain: TExternV read rain write rain;
/// <summary> stomata resistance at good water supply [s.m-1] </summary>
    Property Par_RC0: TPar read rc0 write rc0;
/// <summary> extinction coefficient for global radiation [-] </summary>
    Property Par_Exk_Glob: TPar read exk_GlobRad write exk_GlobRad;
/// <summary> elevation above sea level [m] </summary>
    Property Par_Elev: TPar read Elev write Elev;
/// <summary> specific interception capacity per unit BFI [mm/BFI] </summary>
    Property Par_SIC: TPar read sic write sic;
/// <summary> measurement height of the parameters [m] </summary>
    Property Par_measure_height: TPar read measure_height write measure_height;
/// <summary> CO2 partial pressure [ppm] </summary>
    property Ex_CO2pp: TExternV Read ExCO2pp Write ExCO2pp;
/// <summary> potential evapotranspiration [mm.d-1] </summary>
    Property Var_pETP: TVar read pETP write pETP;
/// <summary> reference evapotranspiration according to FAO </summary>
    Property Var_ET0: TVar read ET0 write ET0;
/// <summary> potential transpiration [mm.d-1] </summary>
    Property Var_PotTrans: TVar read pot_trans write pot_trans;
/// <summary> potential Evaporation </summary>
    Property Var_PotEvap: TVar read pot_Evapo write pot_Evapo;
/// <summary> interception </summary>
    Property Var_interzeption: TVar read interception write interception;
/// <summary> precipitation rate-interception </summary>
    Property Var_NetRain: TVar read net_rain write net_rain;
/// <summary> aerodynamic resistance [s.m-1] </summary>
    Property Var_ra: TVar read ra write ra;
/// <summary> net radiation [W.m-2] </summary>
    Property Var_NetRad: TVar read netRad write netRad;
/// <summary> Option for Source of extinction coefficient </summary>
    Property Opt_Exk_Glob: TSource read fExkOpt write fExkOpt;
/// <summary> Option for Source of extinction coefficient </summary>
    Property Opt_rc0: TSource read frc0Opt write frc0Opt;
  end;

procedure Register;

implementation

uses
  UModUtils,SysUtils;

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


/// <summary> function for the calculation of the CO2 concentration in the atmosphere [ppm] </summary>
/// <param name="date">Date for the calculation</param>
/// <returns>CO2 concentration [ppm]</returns>  
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



/// <summary>
///   Calculate the solar declination, day length, and extraterrestrial radiation
///   based on latitude and day of the year.
/// </summary>
/// <param name="lat">Latitude in degrees</param>
/// <param name="day">Day of the year (1-365)</param>
/// <param name="DEC">Output: Solar declination in radians</param>
/// <param name="dayl">Output: Day length in hours</param>
/// <param name="ANGOT">Output: Daily extraterrestrial radiation in J/m²</param>
procedure CalcAngot(lat: real; day: real; var DEC: real; var dayl: real; var ANGOT: real);

const
  RAD = Pi()/180;

var
  X: real;
  AOB: real;
  dsinb: real;
  sc: real;
  SINLD:real;
  COSLD:real;
  DSINBE:real;
begin
  { Deklination der Sonne als Funktion der Jahreszeit (DAY) }
  X := arcsin(SIN(23.45 * RAD) * COS(2. * PI * (DAY + 10) / 365));
  DEC := X * -1;
  { Zwischenwerte SINLD, COSLD und AOB }
  SINLD := SIN(RAD * LAT) * SIN(DEC);
  COSLD := COS(RAD * LAT) * COS(DEC);
  AOB := SINLD / COSLD;
  {Tageslaenge (DAYL) und photoperiodische Tageslaenge (DAYLP) }
  X := ARCSIN(AOB);
  DAYL := 12.0 * (1 + 2 * X / PI);
  //   X:=arcsin((-SIN(-4*RAD)+SINLD)/COSLD);
  //   DAYLP:=12.0*(1+2*X/PI);
  { Sonnenwinkel - Integration }
  DSINB := 3600 * (DAYL * SINLD + 24 * COSLD * SQRT(1 - AOB * AOB) / PI);
  DSINBE := 3600 * (DAYL * (SINLD + 0.4 * (SINLD * SINLD + COSLD * COSLD * 0.5)) + 12.0 * COSLD * (2.0 + 3.0 * 0.4 * SINLD) * SQRT(1 - AOB * AOB) / PI);
  { Solarkonstante (SC) und taegliche extraterrestrische Strahlung (ANGOT) }
  SC := 1370 * (1 + 0.033 * COS(2 * PI * DAY / 365));
  ANGOT := SC * DSINB;
end;


/// <summary> function for the calculation of the air pressure based on elevation and temperature </summary>
/// <param name="Elev">Elevation [m]</param>
/// <param name="Temp">Temperature [°C]</param>
/// <returns>Air pressure [hPa]</returns>
function TPenMonteith.pressure_f(Elev, Temp: real): real;


begin
  pressure_f := 1013.0 * exp(-0.034 * Elev / (Temp + 273));
end;

/// <summary>
/// calcuation of aerodynamisc resistance </summary>
/// <param name="wind_speed">average wind speed [m/s]</param>
/// <param name="crop_height">crop height [m]</param>
/// <returns>aerodynamic resistance [s/m]</returns>
function TPenMonteith.ra_f(wind_speed, crop_height: real): real;

const
/// <summary> von Karman-constant [-] </summary>
  Karman_const = 0.41; // von Karman-Konstante [-] 

var
  z0: real;
  d: real;

  
/// <summary> calculation of the roughness factor </summary>
/// </summary>
/// <param name="crop_height">Plant height [m]</param>
  function roughness_f(crop_height: real): real;

  begin
    if crop_height < 0.05 then
      crop_height := 0.05; // Min of the height of 5 cm
    roughness_f := 0.13 * crop_height;
  end;


/// <summary> calculation of zero plane displacement height </summary>
/// <param name="crop_height">Plant height [m]</param>
/// <returns>zero plane displacement height [m]</returns>

  function displacement_height ( crop_height : real ) : real;
  begin
    if crop_height<0.05 then crop_height := 0.05; // lowest height is 5 cm
    displacement_height := 0.63 * crop_height;
  end;

begin
  If wind_speed < 0.0001 then
    wind_speed := 0.0001;
  z0 := roughness_f(crop_height);
  d := displacement_height(crop_height);
  case f_ra_funct of
    PenmanMonteith:   {Original-Penman-Monteith for near-neutral conditions}
        ra_f := (ln(measure_height.v/z0)*ln(measure_height.v/(0.2*z0)))/(sqr(Karman_const)*wind_speed);
    ThomOliver: {Formulierung zur Einbeziehung von Konvektion nach Thom and Oliver (1977)
                 zitiert in Jackson et al. 1988}
        ra_f := 4.72*sqr(ln((measure_height.v-d)/z0))/(1+0.54*wind_speed);
  end;

end;


/// <summary> function for calculation of the density of dry air </summary>
/// <param name="Temp">mean daily temperature [°C]</param>
/// <returns>density of air [kg/m3]</returns>


function dens_air(Temp: real): real;
begin
  dens_air := 1.2917 - 0.00434 * Temp;
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


/// <summary> function for the calculation of the penman-monteith evapotranspiration </summary>
/// <param name="Temp">air temperature [°C]</param>
/// <param name="Sat_def">saturation deficit of the air [mbar]</param>
/// <param name="Net_beam">net radiation [J/m2*s]</param>
/// <param name="delta">slope of the saturation vapor pressure curve [mbar/K]</param>
/// <param name="gamma">psychrometer constant [mbar/K]</param>
/// <param name="l_h_v_water">latent heat of water evaporation at 10°C [J/Kg]</param>
/// <param name="ra">aerodynamic resistance [s/m]</param>
/// <param name="rc">bulk-Stomata resistance [s/m]</param>
/// <returns>potential evapotranspiration [kg/(m2*d)]</returns>
function TPenMonteith.Penman(Temp, Sat_def, Net_beam, delta, gamma,
  l_h_v_water, ra, rc: real): real;


const
/// <summary> specific heat of air at constant pressure [J/(Kg*K)] </summary>
  cp = 1005.0; 

var
  
/// <summary> potential evapotranspiration [kg/(m2*d)] </summary>
  pETP, 
/// <summary> air density [kg/m3] </summary>
  ro
  : real; 

begin { Penman }
  ro := dens_air(Temp);

  pETP := (delta * Net_beam + ro * cp * Sat_def / ra) /
    (delta + gamma * (1 + rc / ra));
  pETP := pETP / l_h_v_water * 86400.0;
  If pETP < 0.0 then
    Penman := 0.0
  else
    Penman := pETP;

end; { Penman }


/// <summary>
///   procedure for determining interception of a canopy.
/// </summary>

procedure TPenMonteith.Calc_Interception;


var
  /// <summary>maximum interception capacity [mm]</summary>
  max_int_cap, 
  /// <summary>actual interception capacity [mm]</summary>
  act_int_cap
  : real;

begin
  max_int_cap := ExLAI.v * sic.v;
  act_int_cap := max_int_cap - int_stor.v;
  If act_int_cap > 0.0 then
  begin
    if act_int_cap > (rain.v * GlobTime.c) then
    begin
      int_stor.v := int_stor.v + rain.v * GlobTime.c;
      net_rain.v := 0.0;
    end
    else
    begin
      int_stor.v := max_int_cap;
      net_rain.v := rain.v - act_int_cap / GlobTime.c;
    end;
  end
  else
    net_rain.v := rain.v;

  // If Net_rain.v > Rain.v then
  // showmessage('Too much Netrain !');

  If pTI * GlobTime.c > int_stor.v then
  begin
    pTI := pTI - int_stor.v / GlobTime.c;
    interception.v := int_stor.v / GlobTime.c;
    int_stor.v := 0.0;
  end
  else
  begin
    interception.v := pTI;
    int_stor.v := int_stor.v - pTI * GlobTime.c;
  end;

end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
function TPenMonteith.Evaporation_f: real;

{ ********************************************************************** }
{ purpose : empirische Funktion zur Ermittlung der Evaporation eines
  Bodens unter einem Pflanzenbestand
  nach Duynisveld (1983) S.22

  Parameter :

  Name             Inhalt                          Einheit      Typ

  pET              potential evapotranspiration  [mm/d]       I
  BFI              leaf area index               [-]          I

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
  Evap := pETP.v * exp(-k_GlobRad.v * ExLAI.v);
  If Evap < 0.0 then
    Evap := 0.0;
  Evaporation_f := Evap;
end;


function TPenMonteith.Evaporation_f_ambient: real;

{ ********************************************************************** }
{ purpose : empirische Funktion zur Ermittlung der Evaporation eines
  Bodens unter einem Pflanzenbestand
  nach Duynisveld (1983) S.22

  Parameter :

  Name             Inhalt                          Einheit      Typ

  pET              potential evapotranspiration  [mm/d]       I
  BFI              leaf area index               [-]          I

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
  Evap := pETP_ambient.v * exp(-k_GlobRad.v * ExLAI.v);
  If Evap < 0.0 then
    Evap := 0.0;
  Evaporation_f_ambient := Evap;
end;

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

/// <summary>
/// <summary> calculation of the saturated vapor pressure </summary>
/// </summary> 
/// <param name="Temp">temperature [°C]</param>
/// <returns> saturated vapor pressure [mbar] </returns>

function TPenMonteith.sat_vap_press_f(Temp: real): real;

{ ********************************************************************** }
{ purpose : empirische Funktion zur Ermittlung of gesättigten Wasserdampf-
  druckes
  nach Groot (1983) bzw. Goudriaan (1977)

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Temp             air temperature                      [°C]         I


  sat_vap_press_f  saturated water vapour pressure    [mbar]       O }
{ ********************************************************************** }

begin
  sat_vap_press_f := 6.11 * exp(17.4 * Temp / (Temp + 239.0));
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


/// <summary>
/// <summary> calculation of the slope of the saturated vapor pressure curve </summary>
/// </summary>
/// <param name="sat_vap_press">saturated vapor pressure [mbar]</param>
/// <param name="Temp">temperature [°C]</param>
/// <returns>slope of the saturated vapor pressure curve [mbar/°K]</returns>
function TPenMonteith.delta_f(sat_vap_press, Temp: real): real;

begin
  delta_f := 239.0 * 17.4 * sat_vap_press / sqr(Temp + 239.0);
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


function TPenMonteith.Calc_psychro(P, Temp:real):real;

begin
  result := (c_p * P / (L_H_V_water * MW_ratio));
end;



procedure TPenMonteith.CreateAll;

begin
  Inherited CreateAll;
  CreatePars;
  CreateExterns;
  CreateVars;
  StateCreate('int_stor', '[mm]', 0.0, false, int_stor, 'intercepted water on canopy');
  CreateOptions;
end;

procedure TPenMonteith.Init;
begin
  inherited;
  if uppercase(f_ra_Option.Option) = uppercase('PenmanMonteith') then f_ra_funct := PenmanMonteith;
  if uppercase(f_ra_Option.Option) = uppercase('ThomOliver') then f_ra_funct := ThomOliver;

  if self.OptWithCO2.Option = 'WithCO2Effect' then
     fCO2effect := true
  else
     fCO2effect := false;


  if (OptExCO2.option = 'externalCO2') then begin
     ExCO2pp.Search := true;
     fCO2effect := true;
  end
  else begin
    ExCO2pp.Search := false;
    fCO2effect := false;
  end;
end;

procedure TPenMonteith.CalcVars;

var
  gamma,
  es, // Saturation deficit [mbar]
  delta,
  GlobRad_w_m2: real;

begin
  if (fCO2effect = true) and (OptExCO2.Option = 'internalCO2') then
    CO2pp.v := CO2_ppm_f(globtime.v);


  if (frc0Opt = fromPlantModel) and IsPlantModelSet then
    rc0_Var.v := Plantmodel.rc0
  else // use the external variable
    rc0_Var.v := rc0.v;
  Calc_rc0(rc0_Var.v, CO2pp.v, CiThreshold.v,  relRc0Inc_CO2.v,
            fCO2effect);
  rc.v := Calc_rc(rc0_Var.v, ExLAI.v);
  Calc_ra;
  // calcuation of net radiation using empirical function
  // gefitted aus Tagesdaten gemessener net radiation (W/m2) zu Globalstahlung (W/m2)
 // GlobRad_w_m2 := GlobRad.v*1e6/86400;
//  netRad.v := max(0, 0.6494 * (GlobRad_w_m2) - 18.417);
  netRad.v := max(0, 0.6494 * (GlobRad.v) - 18.417);
  P.v   := pressure_f(Elev.v, Temp.v);
  gamma :=  Calc_psychro(P.v, Temp.v); //P.v * Psycro;
  es    := sat_vap_press_f(Temp.v);
  VapPress.v := es - Sat_def.v;
  { if relFeu.v > 100.0 then
    ea            := 99.0*es/100
    else
    ea            := relFeu.v*es/100.0;
    sat_def.v     := es-ea; }

  delta := delta_f(es, Temp.v);

//???
//@title: Calculation of pETPambient
//@Var: pETP_ambient
//@Description: The calculation of the pETP_ambient value is based on the canopy resistance under
//@.. non elevated CO2
//???

  pETP_ambient.v := Penman(Temp.v, Sat_def.v, netRad.v, delta, gamma, l_h_v_water,
    ra.v, rc_ambient.v);

  pETP.v := Penman(Temp.v, Sat_def.v, netRad.v, delta, gamma, l_h_v_water,
    ra.v, rc.v);

  ET0.v := Penman(Temp.v, Sat_def.v, (1-0.23)*Globrad.v, delta, gamma, l_h_v_water,
           208/max(0.1, wind_speed.v), 70);
  //pETP.v := ET0.v;

  pot_Evapo_ambient.v := Evaporation_f_ambient;
  pot_Evapo.v := Evaporation_f;
  pTI := pETP.v - pot_Evapo.v;

  Calc_Interception;
  Calc_potTrans;
end;




procedure TPenMonteith.CalcRates;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


begin

end; { Evapo_transpi }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith.SetPlantModel(NewPlantmodel: TAbstractPlant);


begin
  inherited SetPlantModel(NewPlantmodel);
  if IsPlantModelSet then begin
    Ex_LAI.Search := false;
    // If Ex_LAI.f_v = nil then
    Ex_LAI.f_v := @Plantmodel.p_LAI.fv;
//    if NewPlantmodel.p_LAI <> NIL then
      Ex_LAI.Source := Plantmodel.Name+'.'+Plantmodel.p_LAI.Name;
    Ex_CropHeight.Search := false;
    // if Ex_CropHeight.f_v = nil then
    Ex_CropHeight.f_v := @Plantmodel.p_CropHeight.fv;
    if NewPlantmodel.p_CropHeight <> NIL then
      Ex_CropHeight.Source := Plantmodel.name+'.'+NewPlantmodel.p_CropHeight.Name;
end;
end;

procedure TPenMonteith.Calc_potTrans;
begin
  if pETP.v > 0 then
    pot_trans.v := (pETP.v - pot_Evapo.v - interception.v)
  else
    pot_trans.v := 0;
  if pot_trans.v <= 1E-10 then
    pot_trans.v := 0;
  if pETP_ambient.v > 0 then
    pot_trans_ambient.v := (pETP_ambient.v - pot_Evapo_ambient.v - interception.v)
  else
    pot_trans_ambient.v := 0;
  if pot_trans_ambient.v <= 1E-10 then
    pot_trans_ambient.v := 0;
   CO2TransDiff.v:= (pot_trans.v+interception.v)- (pot_trans_ambient.v+interception.v);
   if pot_trans.v>0 then
    relCO2TransDiff.v:=CO2TransDiff.v/(pot_trans.v+interception.v)
    else relCO2TransDiff.v:=0;


end;

procedure TPenMonteith.Calc_ra;
begin
  if ExCropHeight.v <= 0 then
    ra.v := ra_f(wind_speed.v, 0.05)
  else
    ra.v := ra_f(wind_speed.v, ExCropHeight.v);
end;



/// <summary> calculate the canopy resistance according to the LAI </summary>
/// <param name="rc0">stomata resistance at good water supply [s/m]</param>
/// <param name="LAI">leaf area index</param>
/// <returns>canopy resistance [s/m]</returns>
function TPenMonteith.Calc_rc(rc0, LAI: real): real;
begin
  if LAI < 1 then
    result := rc0
  else if (LAI >= 1) and (LAI < 2) then
    result := rc0 / LAI
  else if (LAI >= 2) and (LAI < 6) then
    result := rc0 / 2 - (rc0 / 2 - rc0 / 3) * ((LAI - 2) / 4)
  else
    // according to Stockle (????)
    result := rc0 / 3;
  if result < 0.1 then
    result := 0.1;
end;


procedure TPenMonteith.Calc_rc0(Plant_rc0, CO2pp, CiThreshold, relRc0Inc_CO2:real;
                               CO2effect: boolean);

var
  relDeltaCi: real;
begin
  { Evapo_transpi }
  rc0_ambient.v := Plant_rc0;
  rc0_Var.v := rc0_ambient.v;
  // Impact of CO2
  if CO2effect then begin
     relDeltaCi := (CO2pp- CiThreshold)/CiThreshold;
     rc0_Var.v := Plant_rc0*(1+relDeltaCi*relRc0Inc_CO2);
  end;

end;

procedure TPenMonteith.CreateExterns;
begin
  ExternVCreate('TMPM', '[°C]', StateField, Temp, 'average daily temperature');
  // air temperature [°C]
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad, 'gobal radiation in [W.m-2]');
  ExternVCreate('Sat_def', '[hPa]', StateField, Sat_def, 'saturation deficit [hPa]');
  ExternVCreate('Wind', '[m.s-1]', StateField, wind_speed, 'wind speed');
  // wind speed [m.s-1]
  ExternVCreate('CropHeight', '[m]', StateField, ExCropHeight, 'crop height');
  // plant height [cm]
  ExternVCreate('LAI', '[-]', StateField, ExLAI, 'leaf area index');
  // leaf area index []
  ExternVCreate('rain', '[mm.d-1]', StateField, rain, 'rainfall rate');
  ExternVCreate('ExCO2pp', '[ppm]', StateField, ExCO2pp, 'External CO2 concentration');
end;

procedure TPenMonteith.CreateVars;
begin
  // precipitation rate [mm/d]
  VarCreate('VapPress', '[mbar]', 0, false, VapPress, 'saturated vapour pressure');
  // water vapour pressure [mbar]
  VarCreate('P', '[mbar]', 0, false, P, 'air pressure');
  // standard air pressure [mbar] calculated aus air temperature and height
  VarCreate('pETP', '[]', 0, false, pETP, 'potential evporation');
  // potential evapotranspiration [mm.d-1]
  VarCreate('ET0', '[]', 0, false, ET0, 'reference evapotranspiration short grass (FAO)');
  // potential evapotranspiration [mm.d-1]
  VarCreate('pETP_ambient', '[]', 0, false, pETP_ambient, 'potential evapotranspiration ohne CO2 Einfluss');
  // potential evapotranspiration [mm.d-1]
  VarCreate('PotTrans', '[mm/d]', 0, false, pot_trans, 'potential plant transpiration');
  VarCreate('potTrans_ambient', '[mm/d]', 0, false, pot_trans_ambient, 'potential transpiration under ambient CO2'); // potential transpiration [mm.d-1]
  VarCreate('PotEvap', '[mm/d]', 0, false, pot_Evapo, 'potential soil evaporation rate'); // potential Evaporation
  VarCreate('pot_Evapo_ambient', '[mm/d]', 0, false, pot_Evapo_ambient);  // potential Evaporation
  VarCreate('interception', '[mm/d]', 0, false, interception, 'daily interception rate');  // interception
  VarCreate('NetRain', '[mm/d]', 0, false, net_rain, 'rain - interception'); // precipitation rate-interception
  VarCreate('ra', '[s/m]', 0, false, ra, 'aerodynamic resistance');
  VarCreate('rc', '[s/m]', 0, false, rc, 'canopy resistance');
  VarCreate('rc_ambient', '[s/m]', 0, false, rc_ambient, 'canopy resistance under abient CO2');
  VarCreate('NetRad', '[W.m-2]', 0, false, netRad, 'net radiation'); // net radiation [W.m-2]
  VarCreate('k_GlobRad', '[-]', 0, false, k_GlobRad, 'actual extinction coefficient for global radiation, can be from parameter or from external crop model');  // extinction coefficient for GlobRad
  VarCreate('rc0_Var', '[s.m-1]', 0, false, rc0_Var, 'rc0 value as used for calculation (from parameter or plant model)');
  VarCreate('rc0_ambient', '[s.m-1]', 0, false, rc0_ambient, 'rc0 value without CO2 effect');
  VarCreate('CO2TransDiff', '[mm/d]', 0, false, CO2TransDiff, 'CO2 induced reduction of pot_trans');
  VarCreate('relCO2TransDiff', '[-]', 0, false, relCO2TransDiff, 'rel. CO2 induced reduction of pot_trans');
  VarCreate('CO2pp', '[ppm]', 400, false, CO2pp, 'external CO2 concentration https://agronomykiel.github.io/HUME/Components/Evapotranspiration/Documentation/TPenMonteith.html#co_2-concentration');

end;

procedure TPenMonteith.CreatePars;
begin
  ParCreate('Elev', '[m]', 50, Elev, 'Heigt above sea level');
  ParCreate('rc0', '[s.m-1]', 50, rc0, 'canopy resistance at "good water supply", note that if a plant component is coupled to TPenMonteith this value is used'); // Stomatawiderstand bei "guter Wasserversorgung"
  ParCreate('exk_GlobRad', '[-]', 0.5, exk_GlobRad, 'extinction coefficient for global radiation');
  ParCreate('SIC', '[mm.m-2.m-2]', 0.15, sic, 'specific interception capacity');
  ParCreate('measure_height', '[m]', 2, measure_height, 'Measurement height of meteorological variables [m]');
  ParCreate('CiThreshold', '[ppm]', 380, CiThreshold, 'threshold for CO2 impact on rc0');
  ParCreate('relRc0Inc_CO2', '[(s.m-1)/ppm]', 0.3878, relRc0Inc_CO2, 'mediates the relative CO2 impact on rc0 estimated from: Elevated CO2 effects on canopy and soil water flux parameters... Burkart et al. 2010');
end;

procedure TPenMonteith.CreateOptions;
begin
  // Interzeptionsspeicher [mm]
  OptCreate('ra_Option', 'PenmanMonteith', f_ra_Option, 'Option for ra(u, CropHeight)-function');
  f_ra_Option.OptionList.Add('PenmanMonteith');
  f_ra_Option.OptionList.Add('ThomOliver');
  OptCreate('optCO2', 'NoCO2Effect', OptWithCO2, 'Option for including effects of elevated CO2 in calculations');
  OptWithCO2.OptionList.Clear;
  OptWithCO2.OptionList.Add('NoCO2Effect');
  OptWithCO2.OptionList.Add('WithCO2Effect');
  OptCreate('optExCO2', 'externalCO2', OptExCO2, 'Option for using external supplied CO2 concentration in calculations');
  OptExCO2.OptionList.Clear;
  OptExCO2.OptionList.Add('externalCO2');
  OptExCO2.OptionList.Add('internalCO2');
end;

{ ----------------------------------------------------------------------- }

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TPenMonteith]);
{$ENDIF}
end;

end.
