unit UPenMonteithHrly;

interface
uses
  UMod, UState, UPenMonteith;

type

  THourArray    = array[1..24] of TVar;
  THourExtArray = array[1..24] of TExternV;


TPenMonteithH = class(TPenMonteith)
public
  pT_arr: THourArray;             // Stundenwerte der potentiellen Transpiration
  GlobRad_arr: THourExtArray;     // Stundenwerte der Globalstrahlung
  Temp_arr: THourExtArray;        // Stundenwerte der Temperatur
  u_arr: THourExtArray;           // Stundenwerte der Windgeschindigkeit
  SatDef_arr: THourExtArray;      // Stundenwerte des Sättigungsdefizits
  procedure CreateAll; override;
  procedure CalcRates; override;
end;

procedure Register;


implementation
uses
  math, SysUtils, UModUtils, dialogs, classes;

procedure TPenMonteithH.CreateAll;
var
  i : integer;
begin
  inherited CreateAll;
  for i := 1 to 24 do begin
    VarCreate('pT'+IntToStr(i), '[mm/d]', 0.0, false, pT_arr[i]);
    ExternVCreate('GR_'+IntToStr(i),'[W/m2]',StateField, GlobRad_arr[i]);
    ExternVCreate('T_'+IntToStr(i),'[°C]',StateField, Temp_arr[i]);
    ExternVCreate('u_'+IntToStr(i),'[m/s]',StateField, u_arr[i]);
    ExternVCreate('SD_'+IntToStr(i),'[mbar]',StateField, SatDef_arr[i]);
  end;
end;


procedure TPenMonteithH.CalcRates;

var
  pressure,           // Luftdruck [mbar]
  gamma,
  es,       // Sättigungsdampfdruck [mbar]
  delta
          : real;
  t_NetRad,
  t_ra,
  t_potE
          : real;
  i       : integer;

begin   { Evapo_transpi }
  inherited CalcRates;
  for i := 1 to 24 do begin
    // Berechnung der Nettostrahlung nach empirischer Funktion
    // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstahlung (W/m2)
    t_NetRad := max(0,0.6494*(GlobRad_arr[i].v) - 18.417);
    pressure      := pressure_f ( Elev.v, Temp_arr[i].v);
    gamma         := Pressure*Psycro;
    es            := sat_vap_press_f (Temp_arr[i].v);
    delta := delta_f (es, Temp_arr[i].v);
    if ExCropHeight.v <= 0.0 then t_ra := ra_f (u_arr[i].v, 0.05)
                           else t_ra := ra_f (u_arr[i].v, ExCropHeight.v);
    pETP.v := Penman (Temp_arr[i].v, SatDef_arr[i].v, t_NetRad, delta, gamma, l_h_v_water, t_ra, rc.v);
    t_potE := Evaporation_f;
    pTI := pETP.v - t_potE;

    Interzeption_p;

    If pETP.v > 0.0 then pT_Arr[i].V := (pETP.v-t_potE-Interzeption.v)
                    else pT_Arr[i].V := 0.0;

    If pT_Arr[i].V < 0.0 then pT_Arr[i].V := 0.0;
  end;
  inherited CalcRates;
end; { Evapo_transpi }



procedure Register;
begin
  RegisterComponents('Simulation', [TPenMonteithH]);
end;

end.
