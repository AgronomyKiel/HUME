unit UPenMonteith;

{ **********************************************************************
  ************************  Unit PenMonteith  **************************
  **********************************************************************

  Erstellt von : Henning Kage

  Literatur : van Bavel, C.H.M. (1966)
  Potential evaporation: The Combination Concept and its
  Experimental Verification
  Water Resour.Res. (1966) 2, 455-467

  Duynisveld, W.H.M. (1983)
  Entwicklung von Simulationsmodellen f�r den Transport von
  gel�sten Stoffen in wasserunges�ttigten B�den und
  Lockersedimenten
  Texte Umweltbundesamt (1983) 17, 197 Seiten

  Monteith, J.L. (1973)
  Principles of Environmental Physics
  Edward Arnold, London, 1973, 241 Seiten

  Groot, J.J.R. (1987)
  Simulation of nitrogen balance in a system of winter wheat
  and soil
  Simulation Reports CABO-TT, Wageningen 1987

  L�bmeier, F.J. (1983)
  Agrarmeteorologisches Model zur Berechnung der aktuellen
  Verdunstung (AMBAV)
  Beitr�ge zur Agrarmeteorologie Nr. 7/83

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
  l_h_v_water = 2.477 * 1E6; /// latent heat for water evaporation at 10 �C in [J/Kg] }
  Psycro = 0.000662; /// Psychrometer constant [1/°K] }

type

  TSource = (fromParameter, fromPlantModel); /// Source of extinction coefficient / rc0
  T_ra_Funct = (PenmanMonteith, ThomOliver); /// Options for ra calculation

  TPenMonteith = class(TPlantRelatedSubMod)
  protected
    pTI: real;     /// potential transpiration/interception

    // function getLAI: real; //THumeNumEntity; //override;
    // function getCropHeight: real;//THumeNumEntity; //override;

    procedure Calc_Interception;
    function Evaporation_f: real;
    function Evaporation_f_ambient: real;
    function pressure_f(Elev, Temp: real): real;
    function sat_vap_press_f(Temp: real): real;
    function delta_f(sat_vap_press, Temp: real): real;
    function ra_f(wind_speed, crop_height: real): real;
    function Penman(Temp, Sat_def, Net_beam, delta, gamma, l_h_v_water, ra,
      rc: real): real;
  private
    fExkOpt: TSource; /// Source of extinction coefficient
    frc0Opt: TSource; /// Source of rc0
    fCO2effect: boolean; /// calculations with CO2-effect?
    f_ra_funct: T_ra_Funct;
    procedure CreateOptions;
    procedure CreatePars;
    procedure CreateVars;
    procedure CreateExterns;
    procedure Calc_rc0(Plant_rc0, CO2pp, CiThreshold, relRc0Inc_CO2:real;
                               CO2effect: boolean);
    function Calc_rc(rc0, LAI: real): real;
    procedure Calc_ra;
    procedure Calc_potTrans;

  public
    Elev: TPar; /// height avove sea level [m]               }
    rc0: TPar; /// Stomatawiderstand bei "guter Wasserversorgung"
    exk_GlobRad: TPar; /// Exktinktionskoeffizient für Globalstrahlung [-]
    sic: TPar; /// spezific interzeption capazity per unit LAI [mm/LAI] }
    CiThreshold: TPar; /// Schwellwert für CO2 Partialdruck [ppm]
    relRc0Inc_CO2: TPar;  /// relative Erhöhung des rc0 durch CO2 [1/ppm]
    measure_height: TPar; /// measurement height of meteorological parameters [m]

    Temp: TExternV; /// Temperatur [°C]
    GlobRad: TExternV; /// Globalstrahlung [W.m-2]
    Sat_def: TExternV; /// S�ttigungsdefizit [mbar]
    wind_speed: TExternV; /// Windgeschwindigkeit [m.s-1]
    ExCropHeight: TExternV; /// Pflanzenh�he [m]
    ExLAI: TExternV; /// Blattfl�chenindex []
    rain: TExternV; /// Niederschlag [mm/d]
    CO2pp: TExternV; /// CO2 Partialdruck

    P: TVar; /// Standardluftdruck [mbar] berechnet aus Temperatur und H�he
    VapPress: TVar; /// Wasserdampfdruck [mbar]
    pETP: TVar; /// potentielle Evapotranspiration [mm.d-1]
    ET0: TVar; /// potential reference (FAO) evapotranspiration
    pETP_ambient: TVar; /// potentielle Evapotranspiration no CO2 effect [mm.d-1]
    pot_trans: TVar; /// potentielle Transpiration [mm.d-1]
    pot_trans_ambient: TVar; /// potentielle Transpiration [mm.d-1]
    pot_Evapo: TVar; /// potentielle Evaporation
    pot_Evapo_ambient: TVar; /// potentielle Evaporation
    interception: TVar; /// Interzeptionsverdunstung
    net_rain: TVar; /// Niederschlag-Interzeption
    netRad: TVar; /// Nettostrahlung
    k_GlobRad: TVar; /// extinction coefficient for GlobRad
    ra: TVar; /// aerodynamic resistance [s.m-1]
    rc: TVar; /// canopy resistance [s.m-1]
    rc_ambient: TVar; /// canopy resistance at abmient CO2 [s.m-1]
    rc0_Var: TVar; /// stomata resistance at good water supply with effects of co2 [s.m-1]
    rc0_ambient: TVar; /// stomata resistance at good water supply with effects of co2 [s.m-1]
    CO2TransDiff: TVar; /// difference in transpiration due to CO2 effect
    relCO2TransDiff: TVar; /// relative difference in transpiration due to CO2 effect

    f_ra_Option: TOption;   /// Option for ra(u,CropHeight)-function dn
    OptWithCO2: TOption;    /// Option for CO2 effect

    int_stor: TState; /// Interzeptionsspeicher [mm]
    procedure CalcRates; override; /// calculation of rates
    procedure CreateAll; override; /// create all variables, parameters and externals
    procedure Init(var GlobMod: Tmod); override; /// initialization of parameters and states
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override; /// set the plant model from which the LAI and CropHeight are taken

    // Property LAI : real{;THumeNumEntity} read getLAI;
    // Property CropHeight : real {THumeNumEntity} read getCropHeight;

  published
    property Ex_Temp: TExternV read Temp write Temp; /// Air eemperature [°C]
    property Ex_GlobRad: TExternV read GlobRad write GlobRad; /// Global radiation [W.m-2]
    property Ex_Sat_def: TExternV read Sat_def write Sat_def; /// saturation deficit [mbar]
    property Ex_Windspeed: TExternV read wind_speed write wind_speed; /// Wind speed [m.s-1]
    property Ex_CropHeight: TExternV read ExCropHeight write ExCropHeight; /// Plant height [m]
    Property Ex_LAI: TExternV read ExLAI write ExLAI; /// Leaf Area Index []
    Property Ex_Rain: TExternV read rain write rain; /// Precipitation [mm.d-1]
    Property Par_RC0: TPar read rc0 write rc0; /// stomata resistance at good water supply [s.m-1]
    Property Par_Exk_Glob: TPar read exk_GlobRad write exk_GlobRad; /// extinction coefficient for global radiation [-]
    Property Par_Elev: TPar read Elev write Elev; /// elevation above sea level [m]
    Property Par_SIC: TPar read sic write sic; /// specific interception capacity per unit BFI [mm/BFI]
    Property Par_measure_height: TPar read measure_height write measure_height; /// measurement height of the parameters [m]
    property Ex_CO2pp: TExternV Read CO2pp Write CO2pp; /// CO2 partial pressure [ppm]
    Property Var_pETP: TVar read pETP write pETP; /// potentielle Evapotranspiration [mm.d-1]
    Property Var_ET0: TVar read ET0 write ET0;   /// reference evapotranspiration according to FAO

    Property Var_PotTrans: TVar read pot_trans write pot_trans; /// potentielle Transpiration [mm.d-1]
    Property Var_PotEvap: TVar read pot_Evapo write pot_Evapo;   /// potentielle Evaporation
    Property Var_interzeption: TVar read interception write interception; /// Interzeptionsverdunstung
    Property Var_NetRain: TVar read net_rain write net_rain; /// Niederschlag-Interzeption
    Property Var_ra: TVar read ra write ra; /// aerodynamic resistance [s.m-1]
    Property Var_NetRad: TVar read netRad write netRad; /// net radiation [W.m-2]

    Property Opt_Exk_Glob: TSource read fExkOpt write fExkOpt;   /// Option for Source of extinction coefficient
    Property Opt_rc0: TSource read frc0Opt write frc0Opt;  /// Option for Source of extinction coefficient
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

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
/// <summary>
/// Berechnung des Standardluftdrucks
/// </summary>
/// <param name="Elev"> heigt above sea level [m]</param>
/// <param name="Temp">Mittlere Tagestemperatur [°C]</param>
/// <returns>Luftdruck [mbar]</returns>
function TPenMonteith.pressure_f(Elev, Temp: real): real;

begin
  pressure_f := 1013.0 * exp(-0.034 * Elev / (Temp + 273));
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

/// <summary>
/// Berechnung des aerodynamischen Widerstandes
/// </summary>
/// <param name="wind_speed">Mittlere Windgeschwindigkeit [m/s]</param>
/// <param name="crop_height">Plant height [m]</param>
/// <returns>aerodynamischer Widerstand [s/m]</returns>
 
function TPenMonteith.ra_f(wind_speed, crop_height: real): real;


{ ********************************************************************** }
{ Zweck : Berechnung des aerodynamischen Widerstandes
  Parameter :
  Name             Inhalt                          Einheit      Typ

  wind_speed       Mittlere Windgeschwindigkeit    [m/s]        I
  crop_height      Pflanzenh�he                    [m]          I

  ra_f             aerodynamischer Widerstand      [s/m] }
{ ********************************************************************** }

const
  Karman_const = 0.41; /// von Karman-Konstante [-] 

var
  z0: real;
  d: real;

  
  function roughness_f(crop_height: real): real;
  { ********************************************************************** }
  { Zweck : empirische Funktion zur Ermittlung des Rauigkeitsfaktors
    nach Monteith (1973) S.90
    Parameter :
    Name             Inhalt                          Einheit      Typ

    crop_height      Pflanzenh�he                    [m]         I
    roughness_f      Rauhigkeitsfaktor               [m]         O }
  { ********************************************************************** }
  begin
    if crop_height < 0.05 then
      crop_height := 0.05; // Mindesth�he von 5 cm
    roughness_f := 0.13 * crop_height;
  end;
 
 
 /// <summary>
  /// calculation of zero plane displacement height
  /// </summary>
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
    PenmanMonteith:   {Original-Penman-Monteith f�r near-neutral conditions}
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
/// <summary>
/// function for calculation of the density of dry air
/// </summary>  
/// <param name="Temp">mean daily temperature [°C]</param>
/// <returns>density of air [kg/m3]</returns> 


function dens_air(Temp: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Dichte trockener Luft
  Daten aus Monteith (1973)

  Parameter :
  Name             Inhalt                          Einheit      Typ

  Temp             Mittlere Tagestemperatur        [�C]         I
  dens_air         Dichte der Luft                 [Kg/m3]      O }
{ ********************************************************************** }

begin
  dens_air := 1.2917 - 0.00434 * Temp;
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


/// <summary>
/// function for the calculation of the penman-monteith evapotranspiration
/// </summary>  
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

  Temp             Lufttemperatur                  [�C]         I
  Sat_def          Sättigungsdefizit der Luft      [mbar]       I
  Net_beam         Nettostrahlung                  [J/m2*s]     I
  delta            Steigung der S�ttigungs-
  dampfdruckkurve                 [mbar/K]     I
  gamma            Psychrometerkonstante           [mbar/K]     I
  l_h_v_water      latente Verdunstungsw�rme
  von Wasser bei 10�C             [J/Kg]       I
  ra               Grenzfl�chenwiderstand          [s/m]        I
  rc               bulk-Stomatawiderstand          [s/m]        I

  Penman           potentielle Evapotranspiration  [kg/(m2*d)]  O

  **********************************************************************
  **********************************************************************
  ********************************************************************** }

const
  cp = 1005.0; { spezifische W�rme der Luft [J/(Kg*K)] }

var
  pETP, ro: real; { Dichte der Luft [kg/m3 ] }

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
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith.Calc_Interception;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung der Interzeption eines


  Parameter :
  BFI              Blattfl�chenindex                   [-]
  rain             Niederschlag                        [mm/d]
  pTI              potentielle Transpiration/Interzeption
  [mm/d]
  Int_stor         Interzeptionsspeicher               [mm]



  Interzeption     Interzeptionsverdunstung des Bestandes
  [mm/d]       O }
{ ********************************************************************** }

var
  max_int_cap, { maximale Interzeptionskapazit�t [mm] }
  int_cap { aktuelle Interzeptionskapazit�t [mm] }
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
{ Zweck : empirische Funktion zur Ermittlung der Evaporation eines
  Bodens unter einem Pflanzenbestand
  nach Duynisveld (1983) S.22

  Parameter :

  Name             Inhalt                          Einheit      Typ

  pET              potentielle Evapotranspiration  [mm/d]       I
  BFI              Blattfl�chenindex               [-]          I

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
{ Zweck : empirische Funktion zur Ermittlung der Evaporation eines
  Bodens unter einem Pflanzenbestand
  nach Duynisveld (1983) S.22

  Parameter :

  Name             Inhalt                          Einheit      Typ

  pET              potentielle Evapotranspiration  [mm/d]       I
  BFI              Blattfl�chenindex               [-]          I

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

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

/// <summary>
/// calculation of the saturated vapor pressure
/// </summary> 
/// <param name="Temp">temperature [°C]</param>
/// <returns> saturated vapor pressure [mbar] </returns>

function TPenMonteith.sat_vap_press_f(Temp: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung des gesättigten Wasserdampf-
  druckes
  nach Groot (1983) bzw. Goudriaan (1977)

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Temp             Temperatur                      [�C]         I


  sat_vap_press_f  ges�ttigter Wasserdampfdruck    [mbar]       O }
{ ********************************************************************** }

begin
  sat_vap_press_f := 6.11 * exp(17.4 * Temp / (Temp + 239.0));
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }


/// <summary>
/// calculation of the slope of the saturated vapor pressure curve
/// </summary>
/// <param name="sat_vap_press">saturated vapor pressure [mbar]</param>
/// <param name="Temp">temperature [°C]</param>
/// <returns>slope of the saturated vapor pressure curve [mbar/°K]</returns>
function TPenMonteith.delta_f(sat_vap_press, Temp: real): real;

{ ********************************************************************** }
{ Zweck : empirische Funktion zur Ermittlung Steigung der Wasserdampf-
  druckkurve in Abh�ngigkeit von gesättigtem Wasserdampfdruck
  und Temperatur
  nach Groot (1983)

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Temp             Temperatur                      [�C]         I
  sat_vap_press    ges�ttigter Wasserdampfdruck    [mbar]       I

  delta_f          Steigung der Wasserdampdruck-
  kurve                            [mbar/�K]   O }
{ ********************************************************************** }

begin
  delta_f := 239.0 * 17.4 * sat_vap_press / sqr(Temp + 239.0);
end;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }

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

  if OptWithCO2.option = 'withco2effect' then begin
     CO2pp.Search := true;
     fCO2effect := true;
  end
  else begin
    CO2pp.Search := false;
    fCO2effect := false;
  end;
end;

procedure TPenMonteith.CalcRates;
{ ----------------------------------------------------------------------- }
{ ----------------------------------------------------------------------- }
var
  gamma,
  es, // S�ttigungsdampfdruck [mbar]
  delta, 
  GlobRad_w_m2: real;


begin
  if (frc0Opt = fromPlantModel) and IsPlantModelSet then
    rc0_Var.v := Plantmodel.rc0
  else // use the external variable
    rc0_Var.v := rc0.v;
  Calc_rc0(rc0_Var.v, CO2pp.v, CiThreshold.v,  relRc0Inc_CO2.v,
            fCO2effect);
  rc.v := Calc_rc(rc0_Var.v, ExLAI.v);
  Calc_ra;
  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstahlung (W/m2)
 // GlobRad_w_m2 := GlobRad.v*1e6/86400;
//  netRad.v := max(0, 0.6494 * (GlobRad_w_m2) - 18.417);
  netRad.v := max(0, 0.6494 * (GlobRad.v) - 18.417);
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


end; { Evapo_transpi }
{ ----------------------------------------------------------------------- }

procedure TPenMonteith.SetPlantModel(NewPlantmodel: TAbstractPlant);


begin
  inherited SetPlantModel(NewPlantmodel);
  if IsPlantModelSet then begin
    Ex_LAI.Search := false;
    // If Ex_LAI.f_v = nil then
    Ex_LAI.f_v := @Plantmodel.p_LAI.fv;
    Ex_LAI.Source := Plantmodel.Name+'.'+NewPlantmodel.p_LAI.Name;
    Ex_CropHeight.Search := false;
    // if Ex_CropHeight.f_v = nil then
    Ex_CropHeight.f_v := @Plantmodel.p_CropHeight.fv;
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



/// <summary>
/// calculate the canopy resistance according to the LAI
/// </summary>
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
  ExternVCreate('CO2pp', '[ppm]', statefield, CO2pp, 'external CO2 concentration');
  ExternVCreate('TMPM', '[°C]', StateField, Temp, 'average daily temperature');
  // Temperatur [�C]
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad, 'gobal radiation in [W.m-2]');
  ExternVCreate('Sat_def', '[hPa]', StateField, Sat_def, 'S�ttigungsdefizit [hPa]');
  ExternVCreate('Wind', '[m.s-1]', StateField, wind_speed, 'wind speed');
  // Windgeschwindigkeit [m.s-1]
  ExternVCreate('CropHeight', '[m]', StateField, ExCropHeight, 'crop height');
  // Pflanzenh�he [cm]
  ExternVCreate('LAI', '[-]', StateField, ExLAI, 'leaf area index');
  // Blattfl�chenindex []
  ExternVCreate('rain', '[mm.d-1]', StateField, rain, 'rainfall rate');
end;

procedure TPenMonteith.CreateVars;
begin
  // Niederschlag [mm/d]
  VarCreate('VapPress', '[mbar]', 0, false, VapPress, 'saturated vapour pressure');
  // Wasserdampfdruck [mbar]
  VarCreate('P', '[mbar]', 0, false, P, 'air pressure');
  // Standardluftdruck [mbar] berechnet aus Temperatur und H�he
  VarCreate('pETP', '[]', 0, false, pETP, 'potential evporation');
  // potentielle Evapotranspiration [mm.d-1]
  VarCreate('ET0', '[]', 0, false, ET0, 'reference evapotranspiration short grass (FAO)');
  // potentielle Evapotranspiration [mm.d-1]
  VarCreate('pETP_ambient', '[]', 0, false, pETP_ambient, 'potentielle Evapotranspiration ohne CO2 Einfluss');
  // potentielle Evapotranspiration [mm.d-1]
  VarCreate('PotTrans', '[mm/d]', 0, false, pot_trans, 'potential plant transpiration');
  VarCreate('potTrans_ambient', '[mm/d]', 0, false, pot_trans_ambient, 'potential transpiration under ambient CO2'); // potentielle Transpiration [mm.d-1]
  VarCreate('PotEvap', '[mm/d]', 0, false, pot_Evapo, 'potential soil evaporation rate'); // potentielle Evaporation
  VarCreate('pot_Evapo_ambient', '[mm/d]', 0, false, pot_Evapo_ambient);  // potentielle Evaporation
  VarCreate('interzeption', '[mm/d]', 0, false, interception, 'daily interception rate');  // Interzeptionsverdunstung
  VarCreate('NetRain', '[mm/d]', 0, false, net_rain, 'rain - interception'); // Niederschlag-Interzeption
  VarCreate('ra', '[s/m]', 0, false, ra, 'aerodynamic resistance');
  VarCreate('rc', '[s/m]', 0, false, rc, 'canopy resistance');
  VarCreate('rc_ambient', '[s/m]', 0, false, rc_ambient, 'canopy resistance under abient CO2');
  VarCreate('NetRad', '[W.m-2]', 0, false, netRad, 'net radiation'); // Nettostrahlung [W.m-2]
  VarCreate('k_GlobRad', '[-]', 0, false, k_GlobRad, 'actual extinction coefficient for global radiation, can be from parameter or from external crop model');  // extinction coefficient for GlobRad
  VarCreate('rc0_Var', '[s.m-1]', 0, false, rc0_Var, 'rc0 value as used for calculation (from parameter or plant model)');
  VarCreate('rc0_ambient', '[s.m-1]', 0, false, rc0_ambient, 'rc0 value without CO2 effect');
  VarCreate('CO2TransDiff', '[mm/d]', 0, false, CO2TransDiff, 'CO2 induced reduction of pot_trans');
  VarCreate('relCO2TransDiff', '[-]', 0, false, relCO2TransDiff, 'rel. CO2 induced reduction of pot_trans');
end;

procedure TPenMonteith.CreatePars;
begin
  ParCreate('Elev', '[m]', 50, Elev, 'Heigt above sea level');
  ParCreate('rc0', '[s.m-1]', 50, rc0, 'canopy resistance at "good water supply"'); // Stomatawiderstand bei "guter Wasserversorgung"
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
end;

{ ----------------------------------------------------------------------- }

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TPenMonteith]);
{$ENDIF}
end;

end.

