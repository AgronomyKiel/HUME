unit UEvapoTrans;

interface
uses
  UMod, UState, UPenMonteith, ULayeredSoil, UAbstractPlant, UGenucht, classes;
const
  l_h_v_water = 2.477*1e6;       { latente Verdunstungsenergie von
                                 { Wasser bei 10°C in [J/Kg] }
  Psycro      = 0.000662;        { Psychrometerkonstante [1/øK]  }

type
  TSoilWaterParams = array[1..max_comp] of TGenucht;



TEvapoTrans = class(TPenMonteith)
private
  initialisiert: boolean;
protected
  n_comp    : Integer;            { Zahl der berechneten Schichten [n]}
  function rc_f: real;
  function evap_red_f: real;
public
  psi_leaf,                       { Blattwasserpotential [cm] }
  aETP,                           { aktuelle Evapotranspiration [mm/d] }
  akt_evapo,                      { aktuelle Evaporation [mm/d] }
  akt_trans                       { potentielle Transpiration [mm/d] }
            : TVar;
  Wld_arr : TSoilExtArray;        { Wurzellängendichten [cm/cm3] }
  Sink_arr : TSoilVarArray;       { Sinkvektor [cm] }
  theta_arr : TSoilStateArray;      { Wassergehaltsvektor [cm3/cm3] }
  thetaadj_arr : TSoilStateArray;   { WG_scaling*Wassergehaltsvektor [cm3/cm3] }

  Psi_arr, rs_arr, ri_arr: TSoilVarArray;
  WPar : TSoilWaterParams;        { Van-Genuchten Parameter }
  rs_voll, rs_null: TPar;         // Stomatawiderstand
  mkf: TPar;                      // Parameter mkf für Stomatawiderstand
  HoriNdx1,
  HoriNdx2,
  HoriNdx3,
  HoriNdx4 : TPar;             //Index der untersten Schicht im jeweiligen Horizont
  bsat_scaling: TPar;
  alpha_scaling: TPar;
  WG_scaling: TPar;                // SCaling-Faktor für Anfangs-Wassergehalte
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
  psi_critEvap : TPar;             // Wasserspannung ab der Evaporation abnimmt [hPa]
  TransRatio : TVar;               // Verhältnis aktuelle zu potentielle Transpiration
  procedure CreateAll; override;
  procedure CalcRates; override;
  procedure Init (var GlobMod:Tmod); override;
  procedure Integrate; override;
  procedure CalcEvapoTranspi;
  function Trans_f(psi_leaf: real): real;
  function r_soil_f ( lrv, a, K, dz : real):real;
  function r_interf_f( Rrr, theta, theta_s, Lrv, dz:real):real;
published
  Property Var_aETP : TVar read aETP write aETP;            // aktuelle Evapotranspiration [mm/d]
  Property Var_AktTrans : TVar read akt_trans write akt_trans;   // aktuelle Transpiration [mm/d]
  property p_NComp : integer read N_Comp write N_Comp;
  property Par_psi_critEvap : TPar read psi_critEvap write psi_critEvap;
  property Var_TransRatio : TVar read TransRatio write Transratio;
end;

procedure Register;


implementation

uses
  UModUtils, Sysutils, dialogs, math;

procedure  TEvapoTrans.createAll;
var
  i : integer;
begin
  inherited createAll;
  initialisiert := false;
  n_comp := 20;
  VarCreate('psi_leaf', '[]', 1000.0,  false, psi_leaf);  // Blattwasserpotential [cm]
  VarCreate('aETP', '[]', 0.0,  false, aETP);            // aktuelle Evapotranspiration [mm/d]
  VarCreate('AktTrans', '[]', 0.0,  false, akt_trans);   // aktuelle Transpiration [mm/d]
  VarCreate('AktEvapo', '[]', 0.0,  false, akt_evapo);   // aktuelle Evaporation [mm/d]
  for i := 1 to n_comp do begin
    ExternVCreate('effWLD_'+IntToStr(i),'[cm/cm3]',StateField, WLD_arr[i]);
    VarCreate('WAuf'+IntToStr(i), '[cm.d-1]', 0.0, false, Sink_arr[i]);
    VarCreate('Psi_'+IntToStr(i), '[cm.d-1]', 0.0, false, Psi_arr[i]);
    VarCreate('rs_'+IntToStr(i), '[cm.d-1]', 0.0, false, rs_arr[i]);
    VarCreate('ri_'+IntToStr(i), '[cm.d-1]', 0.0, false, ri_arr[i]);
  end;
  for i := 1 to n_comp+1 do if WPar[i] = nil then Wpar[i] := TGenucht.create;

  ParCreate('rs_voll', '[s/m]', 3177.350133, rs_voll);
  ParCreate('rs_null', '[s/m]', 33.40928514, rs_null);
  ParCreate('mkf', '[s/m]', 2.24207079, mkf);

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

  For i := 1 to n_comp+1 do begin
    StateCreate('WG'+IntTostr(i), '[cm3.cm-3]',0.3, true, theta_arr[i]);
    Theta_arr[i].readFromFile := true;
    StateCreate('WGadj'+IntTostr(i), '[cm3.cm-3]',0.3, true, thetaadj_arr[i]);
    thetaadj_arr[i].v := WG_scaling.v * theta_arr[i].v;
    VarCreate('Psi'+IntTostr(i),'[cm]' , WPar[i].psi_b_f(thetaadj_arr[i].v), true, psi_arr[i]);
  end;

  ParCreate('psi_critEvap','[hPa]', 500.0, psi_critEvap);
  VarCreate('TransRatio', '[-]',0.0, false, TransRatio);
end;

procedure TEvapoTrans.Init(Var GlobMod: TMod);
var
  i : integer;
begin
  Inherited Init(GlobMod);
  for i := 1 to n_comp+1 do begin
    thetaadj_arr[i].v := WG_scaling.v * theta_arr[i].v;
    psi_arr[i].v := WPar[i].psi_b_f(thetaadj_arr[i].v);
    globmod.StateIniFile.WriteFloat(self.name, psi_arr[i].name, psi_arr[i].v);
  end;
  If round(Horindx1.v) = 0 then begin
    showmessage('Warning ! No specification of Indexes for hydraulic parameters');
    showmessage('Please check !');
  end;
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


function TEvapoTrans.rc_f:real;
{Funktion rc_f zur Berechnung des Canopy-Widerstandes
  empiriche Funktion nach Reid 1991
  Parameter:
  delta_e     Sättigungsdefizit der Luft              [mbar]
  psi_leaf    Blattwasserpotential                    [cm]
  lai         Blattflächenidex                        [-]     }
{ rc_f        Canopy-Widerstand                       [s/m]    }
const
  rc_min  = 20.0;  { minimaler Stomatawiderstand [s/m] }
  stom_sw = -0.8;  { Stomataschwellenwert [MPa] }
  stom_sens = 0.6; { Stomatasensitivit„t []   }

{  rs_voll = 3177.350133;
  rsnull  = 33.40928514;
  mkf     = 2.24207079;}

(*var
  oa : real;       { osmotische Anpassung }*)
var
  rc: real;


begin
  if ExLai.v > 0.0 then begin
    rc := rs_voll.v/(1+(rs_voll.v/rs_null.v-1)*EXP(-mkf.v*psi_leaf.v/10000));  {/lai.v Kochler}

    if (ExLai.v >= 1.0) and (ExLai.v < 2) then rc := rc/ExLai.v
    else if (ExLai.v >= 2.0) and (ExLai.v < 6) then rc := rc/2-(rc/2-rc/3)*((ExLai.v-2)/4)
    else if (ExLai.v >= 6) then rc := rc/3;
    If rc < 0.1 then rc := 0.1;

    {rc_f := 10*(1+potenz((psi_leaf.v/4000.0),3))/lai.v; {Campbell}
  end
  else rc := rs_null.v;
  result := rc;
end;

function TEvapoTrans.evap_red_f: real;
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
end;



function TEvapoTrans.Trans_f(psi_leaf: real):real;
const
   a   = 0.02;     { mittlerer Wurzeldurchmesser [cm] }
   Rrr = 0.25E6;   { radiale Wurzel-"resistivity"  [d/cm]
                     umgerechnet aus Reid (1991) }
   r_stem = {1000}0.0;   {Xylem+Mesophyllwiderstand [d]  }
   dicke = 10.0;   {cm Schichtdicke }


var
  sum_up,          { Summe der Wasseraufnahme [cm/d]    }
  K                { hydraulische Leitf„higkeit [cm/d]  }
   : real;

  i : integer;

begin
  sum_up := 0.0;
  for i := 1 to N_comp do begin
    if wld_arr[i].v > 0.0 then begin
      K   := WPar[i].Ku_b_f (thetaadj_arr[i].v);
      if k < 0.0000001 then k := 0.0000001;
      rs_arr[i].v := r_soil_f (wld_arr[i].v, a, K, dicke);
      ri_arr[i].v := r_interf_f (rrr, thetaadj_arr[i].v, WPar[i].b_sat, wld_arr[i].v, dicke);
      sink_arr[i].v := ((psi_leaf+ExCropheight.v)-(psi_arr[i].v+dicke*(i-0.5)))
                      /(rs_arr[i].v+ri_arr[i].v+r_stem);
      sum_up := sum_up+sink_arr[i].v;
    end else begin
      sink_arr[i].v := 0.0;
    end;
    if sink_arr[i].v < 0.0 then
      sink_arr[i].v := 0.0
    else sink_arr[i].v := abs(sink_arr[i].v);
  end;
  Trans_f := sum_up;

end;

function TEvapoTrans.r_soil_f ( lrv, a, K, dz : real):real;
{ Funktion zur Berechnung des Bodenwiderstandes [d] }
{ Parameter:
  Lrv      Wurzell„ngendichte                  [cm/cm-3]
  a        Mittlerer Wurzeldurchmesser         [cm]
  K        hydraulische Leitf„higkeit          [cm/d]
  dz       Dicke des Kompartiments             [cm]    }
var
  x,           { mittlerer halber Wurzelabstand [cm] }
  r : real;
begin
  x := 1/sqrt(pi*lrv);
  r := ln(x/(2.1*a))/(2*pi*k*lrv*dz);
  r_soil_f := r;
end;

function TEvapoTrans.r_interf_f( Rrr, theta, theta_s, Lrv, dz:real):real;
begin
  r_interf_f := Rrr*(theta_s/theta)/(lrv*dz);
end;


procedure TEvapoTrans.CalcRates;
const
  max_uperr = 0.00001;  {  maximaler Fehler der Transpiration   [cm]   }
  delta_psi = 1.;   {  Žnderung des Blattwasserpotentials     [cm]   }
var
  uptake,
  uptake2,
  f, f2,
  df
            : real;
  success
            : boolean;

begin
  if ExLai.v > 0.0 then begin
    repeat
      success := false;
      CalcEvapoTranspi;
      If wld_arr[1].v <= 0.0 then exit;
      uptake := Trans_f(psi_leaf.v);
      f := akt_trans.v/10-uptake;
      if abs(f) > max_uperr then begin
        uptake2 := Trans_f (psi_leaf.v+delta_psi);
        CalcEvapoTranspi;
        f2 := akt_trans.v/10.0-uptake2;
        df := (f-f2)/delta_psi;
        psi_leaf.v := psi_leaf.v + f/df;
      end else success := true;
    until success
  end
  else begin                {no leafs}
    CalcEvapoTranspi;
    psi_leaf.v := 0.0;
    uptake := 0.0;
  end;

  akt_evapo.v  := pot_evapo.v*evap_red_f;   { Reduktion }

(*    flow_arr[1] := -0.1*akt_evapo[.v]
                            + 0.1*eff_rain.v        { 0.1 wg. Umrechnung in [cm]}
                            {- 0.1*interz};*)

  akt_trans.v := uptake*10.0;
end;

procedure TEvapoTrans.CalcEvapoTranspi;
var
  pressure,                      { Atmosphärendruck in [mbar] }
  es,                            { Sättigungsdampfdruck [mbar] }
  gamma,                         {                     [mbar/øK] }
  delta
             : real;
begin
  pressure      := pressure_f ( Elev.v, Temp.v);
  gamma         := Pressure*Psycro;
  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstrahlung (W/m2)
  netRad.v      := max(0,0.6494*(GlobRad.v) - 18.417);
  es            := sat_vap_press_f (Temp.v);
  delta         := delta_f(es, Temp.v);
  if ExcropHeight.v <= 0.05 then ra.v := ra_f (wind_speed.v, 0.05)
                            else ra.v := ra_f (wind_speed.v, ExCropHeight.v);
  pETP.v := Penman(Temp.v, Sat_def.v, NetRad.v, delta, gamma, l_h_v_water, ra.v, rc0.v) * GlobMod.Time.c;
  if ExLai.v > 0.0 then
    aETP.v := Penman(Temp.v, Sat_def.v, NetRad.v, delta, gamma, l_h_v_water, ra.v, rc_f) * GlobMod.Time.c
    else aETP.v := 0.0;
  Pot_Evapo.v   := Evaporation_f;
  pTI           := pETP.v - pot_Evapo.v;
  Interzeption_p;
  If pETP.v > 0.0 then begin
    pot_trans.v := (pETP.v-Pot_Evapo.v-Interzeption.v);
    akt_trans.v := pot_trans.v*aETP.v/pETP.v;
  end
  else begin
     akt_trans.v := 0.0;
     pot_trans.v := 0.0;
  end;
  If akt_trans.v < 0.0 then akt_trans.v := 0.0;
end;

procedure TEvapoTrans.Integrate;
begin
  inherited integrate;
  If (Akt_Trans.v > 0.0) and (Pot_trans.v > 0) then
      TransRatio.v := max(0, min(1, Akt_Trans.v/Pot_trans.v))
  else TransRatio.v := 1.0;
end;


procedure Register;
begin
  RegisterComponents('Simulation', [TEvapoTrans]);
end;

end.
