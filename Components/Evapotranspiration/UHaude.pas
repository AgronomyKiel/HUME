unit UHaude;

interface

uses
  UMod, UState, classes, UAbstractPlant;

type
  TExkSource = (fromParameter, fromPlantModel); // Source of extinction coefficient

type
  THaude = class(TPlantRelatedSubMod)
   protected
    pTI: real;
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override;
    procedure Interzeption_p;
    function Evaporation_f: real;
    function pressure_f(Elev, Temp: real): real;
    function sat_vap_press_f(Temp: real): real;
    function ra_f(wind_speed, crop_height: real): real;
    function delta_f(sat_vap_press, Temp: real): real;

  private
    fExkOpt: TExkSource; // Source of extinction coefficient

  public
    Elev: TPar; // Höhe über NN [m]               }
    rc0: TPar; // Stomatawiderstand bei "guter Wasserversorgung"
    exk_GlobRad: Tpar; // Exktinktionskoeffizient für Globalstrahlung [-]
    sic: TPar; // spezifische Interzeptionskapazit„t pro Einheit BFI [mm/BFI] }
    measure_height: TPar; { Messhöhe der Parameter [m]   }

    temp, // Temperatur [°C]
      GlobRad, // Globalstrahlung [W.m-2]
      Sat_def, // Sättigungsdefizit [mbar]
      wind_speed, // Windgeschwindigkeit [m.s-1]
      ExCropHeight, // Pflanzenhöhe [m]
      ExLAI, // Blattflächenindex []
      rain, // Niederschlag [mm/d]
      luftfeuchtigkeit: TExternV;

    P, // Standardluftdruck [mbar] berechnet aus Temperatur und Höhe
      VapPress, // Wasserdampfdruck [mbar]
      pETP, // potentielle Evapotranspiration [mm.d-1]
      pot_trans, // potentielle Transpiration [mm.d-1]
      pot_Evapo, // potentielle Evaporation
      interzeption, // Interzeptionsverdunstung
      net_rain, // Niederschlag-Interzeption
      netRad, // Nettostrahlung
      k_GlobRad, // extinction coefficient for GlobRad
      ra,
      rc
      : TVar;

    int_stor: TState; // Interzeptionsspeicher [mm]

    procedure CalcRates; override;
    procedure CreateAll; override;


  published
    property Ex_Temp: TExternV read Temp write Temp;
    property Ex_GlobRad: TExternV read GlobRad write GlobRad;
    property Ex_Sat_def: TExternV read Sat_def write Sat_def;
    property Ex_Windspeed: TExternV read Wind_speed write Wind_speed;
    property Ex_CropHeight: TExternV read ExCropHeight write ExCropHeight;
    property Ex_LAI: TExternV read ExLAI write ExLAI;
    property Ex_Rain: TExternV read Rain write Rain;
    property Par_RC0: Tpar read RC0 write rc0;
    property Par_Exk_Glob: Tpar read exk_GlobRad write exk_GlobRad;
    property Par_Elev: Tpar read Elev write Elev;
    property Par_SIC: Tpar read SIC write SIC;
    property Par_measure_height: TPar read measure_height write measure_height;

    property Var_pETP: TVar read pETP write pETP; // potentielle Evapotranspiration [mm.d-1]
    property Var_PotTrans: TVar read pot_trans write Pot_trans; // potentielle Transpiration [mm.d-1]
    property Var_PotEvap: TVar read pot_Evapo write Pot_Evapo; // potentielle Evaporation
    property Var_interzeption: TVar read interzeption write interzeption; // Interzeptionsverdunstung
    property Var_NetRain: TVar read net_rain write Net_rain; // Niederschlag-Interzeption
    property Var_ra: TVar read ra write ra;
    property Var_NetRad: TVar read NetRad write Netrad; // Nettostrahlung [W.m-2]

    property Opt_Exk_Glob: TExkSource read fExkOpt write fExkOpt; //Option for Source of extinction coefficient
  end;

procedure Register;

var
   k_mais:array[1..12] of double = (0.11,0.11,0.11,0.17,0.21,0.24,0.25,0.26,0.21,0.18,0.11,0.11);

 const
  l_h_v_water = 2.477 * 1E6; { latente Verdunstungsenergie von
                                 {  Wasser bei bei 10 øC in [J/Kg] }
  Psycro = 0.000662; { Psychrometerkonstante [1/øK]  }

implementation



uses
  UModUtils, vcl.dialogs, SysUtils, math;

procedure THaude.createAll;

begin
  inherited CreateAll;
  ParCreate('Elev', '[m]', 50.0, Elev, 'Höhe über NN [m]'); // Höhe über NN [m]
  ParCreate('rc0', '[s.m-1]', 50, rc0, 'Stomatawiderstand bei guter Wasserversorgung'); // Stomatawiderstand bei
                                           // "guter Wasserversorgung"
  ParCreate('exk_GlobRad', '[-]', 0.5, exk_GlobRad);
  ParCreate('SIC', '[mm.m-2.m-2]', 0.15, SIC);
  ParCreate('measure_height', '[m]', 2.0, measure_height);

  ExternVCreate('Temp', '[°C]', StateField, temp); // Temperatur [°C]
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad); // Nettostrahlung [W.m-2]
  ExternVCreate('Sat_def', '[hPa]', StateField, Sat_Def); // Sättigungsdefizit [hPa]
  ExternVCreate('Wind', '[m.s-1]', StateField, wind_speed); // Windgeschwindigkeit [m.s-1]
  ExternVCreate('CropHeight', '[m]', StateField, Excropheight); // Pflanzenhöhe [cm]
  ExternVCreate('LAI', '[-]', StateField, ExLAI); // Blattflächenindex []
  ExternVCreate('rain', '[mm.d-1]', StateField, rain); // Niederschlag [mm/d]
  ExternVCreate('LF', '[%]', StateField, luftfeuchtigkeit); // Niederschlag [mm/d]


  VarCreate('VapPress', '[mbar]', 0.0, false, VapPress); // Wasserdampfdruck [mbar]
  VarCreate('P', '[mbar]', 0.0, false, P); // Standardluftdruck [mbar] berechnet aus Temperatur und Höhe
  VarCreate('pETP', '[]', 0.0, false, pETP); // potentielle Evapotranspiration [mm.d-1]
  VarCreate('PotTrans', '[]', 0.0, false, pot_trans); // potentielle Transpiration [mm.d-1]
  VarCreate('PotEvap', '[]', 0.0, false, pot_Evapo); // potentielle Evaporation
  VarCreate('interzeption', '[]', 0.0, false, interzeption); // Interzeptionsverdunstung
  VarCreate('NetRain', '[]', 0.0, false, net_rain); // Niederschlag-Interzeption
  VarCreate('ra', '[]', 0.0, false, ra);
  VarCreate('rc', '[]', 0.0, false, rc);
  VarCreate('NetRad', '[W.m-2]', 0.0, false, NetRad); // Nettostrahlung [W.m-2]
  VarCreate('k_GlobRad', '[-]', 0.0, false, k_GlobRad); // extinction coefficient for GlobRad

  StateCreate('int_stor', '[]', 0.0, false, int_stor); // Interzeptionsspeicher [mm]
end;


procedure THaude.CalcRates;
var
  gamma, delta, e_s : real;
  year,month,day: word;
  // Haude Faktor für mais [-]


begin
    // externer Blattflächenindex erzeugt von GrowthCurvePlantRoots
  if ExLAI.v < 1.0 then rc.v := rc0.v
  else if (ExLAI.v >= 1.0) and (ExLAI.v < 2) then rc.v := rc0.v / ExLAI.v
  else if (ExLAI.v >= 2.0) and (ExLAI.v < 6) then
    rc.v := rc0.v / 2 - (rc0.v / 2 - rc0.v / 3) * ((ExLAI.v - 2) / 4) // according to Stockle (????)
  else rc.v := rc0.v / 3;
  if rc.v < 0.1 then rc.v := 0.1;

  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstahlung (W/m2)
  netRad.v := max(0, 0.6494 * (GlobRad.v) - 18.417);
  P.v := pressure_f(Elev.v, Temp.v);
  gamma := P.v * Psycro; // Psycro -  Luftfeuchtekonstante

  e_s := sat_vap_press_f(Temp.v);  //Sättigungsdampfdruck [hPa]
  VapPress.v := e_s - Sat_Def.v; // Dampfdruck = Sättigungsdampfdruck - Sättigungsdefizit
 { if relFeu.v > 100.0 then
    ea            := 99.0*es/100
  else
    ea            := relFeu.v*es/100.0;
  sat_def.v     := es-ea;}

  delta := delta_f(e_s, Temp.v);

  if ExCropHeight.v <= 0.0 then ra.v := ra_f(wind_speed.v, 0.05)

  else ra.v := ra_f(wind_speed.v, ExCropHeight.v);

  DecodeDate(GlobTime.v, year, month, day);

  pETP.v := k_mais[month] * e_s * (1 - 50 / 100);

  Pot_Evapo.v := Evaporation_f;
  pTI := pETP.v - pot_Evapo.v;

  Interzeption_p;

  if pETP.v > 0.0 then pot_trans.v := (pETP.v - Pot_Evapo.v - Interzeption.v)
  else Pot_Trans.v := 0.0;
  if pot_Trans.v < 0.0 then pot_Trans.v := 0.0;


end; { Evapo_transpi }
{-----------------------------------------------------------------------}

procedure THaude.SetPlantModel(NewPlantmodel: TAbstractPlant);

begin
  inherited SetPlantModel(NewPlantmodel);

  if IsPlantModelSet = true then begin
    Ex_LAI.Search := false;
//  If Ex_LAI.f_v = nil then
    Ex_LAI.f_v := @PlantModel.p_LAI.fv;
    Ex_LAI.Source := PlantModel.Name;
    Ex_CropHeight.Search := false;
//  if Ex_CropHeight.f_v = nil then
    Ex_CropHeight.f_v := @PlantModel.p_CropHeight.fv;
    Ex_CropHeight.Source := PlantModel.name;
  end;
end;

procedure THaude.Interzeption_p;

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
  max_int_cap, { maximale Interzeptionskapazit„t [mm] }
    int_cap { aktuelle Interzeptionskapazit„t [mm]  }
    : real;

begin
  max_int_cap := ExLAI.v * sic.v;
  int_cap := max_int_cap - int_stor.v;
  if int_cap > 0.0 then begin
    if int_cap > (rain.v * GlobTime.c) then begin
      int_stor.v := int_stor.v + rain.v * GlobTime.c;
      net_rain.v := 0.0;
    end else begin
      int_stor.v := max_int_cap;
      net_rain.v := rain.v - int_cap / GlobTime.c;
    end;
  end else
    Net_Rain.v := Rain.v;

//  If Net_rain.v > Rain.v then
//     showmessage('Too much Netrain !');


  if pTI * GlobTime.c > int_stor.v then begin
    pTI := pTI - int_stor.v / GlobTime.c;
    Interzeption.v := int_stor.v / GlobTime.c;
    int_stor.v := 0.0;
  end else begin
    Interzeption.v := pTI;
    int_stor.v := int_stor.v - pTI * GlobTime.c;
  end;

end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function THaude.Evaporation_f: real;

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
  Evap: real;
begin
  if (fExkOpt = fromPlantmodel) and IsPlantModelSet
    then k_GlobRad.v := Plantmodel.ExtCoeffGlobRad //Extinktionskoeffizient aus verlinktem Plantmodel
  else k_GlobRad.v := exk_GlobRad.v; //Extinktionskoeffizient aus Parameterwert
  Evap := pETP.v * exp(-k_GlobRad.v * ExLAI.v);
  if Evap < 0.0 then Evap := 0.0;
  evaporation_f := evap;
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function THaude.pressure_f(Elev, Temp: real): real;

{ ********************************************************************** }
{ Zweck : Berechnung des Standardluftdrucks
  Parameter :
    Name             Inhalt                          Einheit      Typ

    Elev             Höhe über NN                    [m]          I
    Temp             Mittlere Tagestemperatur        [°C]         I

    pressure_f       Luftdruck                       [mbar]       O  }
{ ********************************************************************** }

begin
  pressure_f := 1013.0 * exp(-0.034 * Elev / (Temp + 273));
end;

{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

function THaude.sat_vap_press_f(Temp: real): real;

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
  sat_vap_press_f := 6.11 * exp(17.4 * Temp / (Temp + 239.0));
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

function THaude.delta_f(sat_vap_press, Temp: real): real;

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
  delta_f := 239.0 * 17.4 * sat_vap_press / sqr(Temp + 239.0);
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}
function THaude.ra_f(wind_speed, crop_height: real): real;

{ ********************************************************************** }
{ Zweck : Berechnung des aerodynamischen Widerstandes
  Parameter :
    Name             Inhalt                          Einheit      Typ

    wind_speed       Mittlere Windgeschwindigkeit    [m/s]        I
    crop_height      Pflanzenhöhe                    [m]          I

    ra_f             aerodynamischer Widerstand      [s/m]               }
{ ********************************************************************** }

const
  Karman_const = 0.41; { von Karman-Konstante [-] }
//  measure_height   = 2.0;               { Messhöhe der Parameter [m]   }
var
  z0: real;

  function roughness_f(crop_height: real): real;
  { ********************************************************************** }
  { Zweck : empirische Funktion zur Ermittlung des Rauigkeitsfaktors
            nach Monteith (1973) S.90
    Parameter :
      Name             Inhalt                          Einheit      Typ

      crop_height      Pflanzenhöhe                    [m]         I
      roughness_f      Rauhigkeitsfaktor               [m]         O }
  { ********************************************************************** }
  begin
    if crop_height < 0.05 then crop_height := 0.05; // Mindesthöhe von 5 cm
    roughness_f := 0.13 * crop_height;
  end;


begin
  if wind_speed < 0.0001 then wind_speed := 0.0001;
  z0 := roughness_f(crop_height);
  ra_f := (ln(measure_height.v / z0) * ln(measure_height.v / (0.2 * z0))) / (sqr(Karman_const) * wind_speed);
end;
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}


procedure Register;
begin
  RegisterComponents('Simulation', [THaude]);
end;

end.
