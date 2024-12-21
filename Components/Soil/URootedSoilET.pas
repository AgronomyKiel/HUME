unit URootedSoilET; // Berechnung Wasserhaushalt und Evapotranspiration über
                    // Widerstandskonzept

interface

uses
  USoilWaterETMod, UMod, UState, ULayeredSoil, classes;

type
  real = double;

  TSinkTermMethod = (nFKcrit, Psicrit);
  TTransCalcMethod = (redFactor, resistances);

TSoilWaterETR = class(TSoilWaterET)
private
  Sum_Sink          : real; // internal variable for summing up all sink terms
  FWithRoots : boolean;
  FSinkTermMethod: TSinkTermMethod;
  FTransCalcMethod: TTransCalcMethod;
  FUseExternalWG: Boolean;
  procedure setWithRoots(settrue: boolean);
  procedure setUseExternalWG(settrue: boolean);
protected
  function Trans_f(psi_leaf: real): real;
  procedure CalcWGs; override; //Berechnung der abgeleiteten Wassergehalte in verschiedenen Horizonten
  function getPsiRoot: extended; override;
  procedure UpdateWGs;      // liest WG aus externen Variablen (wenn OptUseExternalWG=true)
public
  FTransCalcOption: TOption;
  FUseExternalWGOption: TOption;
  Wld_arr : TSoilExtArray;  // Wurzellängendichten [cm.cm-3]
  ExternWG_Arr: TSoilExtArray; // Wassergehalte als externe Varialen eingelesen (wenn OptUseExternalWG=true)
  WLges   : TVar;           // GesamtWurzellänge [cm]
  SinkRedF : TSoilArray;    // Reduktionsfaktoren bei Wasseraufnahme
  K_arr: TSoilVarArray;        // hydraulische Leitfähigkeit [cm/d]

  psi_2,                    // Wasserspannung ab der Wasseraufnahme beginnt abzunehmen
  psi_3,                    // Wasserspannung ab der Wasseraufnahme = 0
  CompFactor                // Konkurrenzfaktor für Wasseraufnahme der Wurzeln (i.d.R. < 1.0)
   : Tpar;

  nFKcrit: TPar;
  r_stem: TPar;             // Xylem+Mesophyllwiderstand [d]

  ActTrans : Tvar;          // aktuelle Transpirationsrate [mm]
  ActTrans_ : Tvar;         // aktuelle Transpirationsrate im internen Zeitschritt [mm]
  CumActTrans : TState;     // kumulative aktuelle Transpiration [mm]
  CumWaterUptake: TState;   // kumulierte über die Wurzeln aufgenommene Wassermenge [mm]
  PotTrans : Tvar;          // potentielle Transpirationsrate [mm]
  PotTrans_ : Tvar;         // potentielle Transpirationsrate im internen Zeitschritt [mm]
  PotEvap : Tvar;          // potentielle Evaporationsrate [mm]
  PotEvap_ : Tvar;         // potentielle Evaporationsrate im internen Zeitschritt [mm]
  ActEvap_ : Tvar;         // potentielle Evaporationsrate im internen Zeitschritt [mm]
  CumPotTrans : TState;     // kumulative potentielle Transpiration [mm]
  TransRatio : TVar;        // Verhältnis aktuelle zu potentielle Transpiration
  max_TransErr: TPar;       // maximaler Fehler der Transpiration   [cm]
  CWSI:Tvar;                //crop water stress index
  Tcrop:Tvar;                // Bestandestemperatur [°C]
  //Tcrop_dir:Tvar;         // Bestandestemperatur [°C] direkt berechnet nach Jackson et al.(1981 & 1988) Equ. (4)
  Tbase:Tvar;                //theoretische minimale Bestandestemperatur[°C]
  Tmax:Tvar;                 //theoretische maximale Bestandestemperatur[°C]
  delta_T:Tvar;            // Temperaturdifferenz Bestandestemperatur minus Lufttemperatur [°C]
  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override;

  procedure Calcsink_red_f;
  procedure CalcSinks; override;
  procedure CalcRatesAndIntegrate; override;
  procedure CalcEvapoTranspi;
  procedure CalcPotET;
  procedure CalcActET;

  procedure CalcRates; override;
  procedure Integrate; override;

  procedure writeValues(FirstTime: boolean;s:string);override; {temporäre Ausgabe-Funktion, nur für Entwicklung}
  procedure writeDebug(Schicht: integer;dt,InFlow,OutFlow,Sink,Thick,WGalt,WGneu,Bil:Real);override;

published
  property Par_Psi_2 : TPar read psi_2 write psi_2;
  property Par_psi_3 : TPar read psi_3 write psi_3;
  property Comp_fact : Tpar read CompFactor write CompFactor;
  property Par_nFKcrit: TPar read nFKcrit write nFKcrit;
  property St_CumActTrans : TState read CumActTrans write CumActTrans;
  property St_CumPotTrans : TState read CumPotTrans write CumPotTrans;
  property Var_ActTrans : TVar read ActTrans write ActTrans;
  property Var_PotTrans : TVar read PotTrans write PotTrans;
  property Var_TransRatio : TVar read TransRatio write TransRatio;
  property Var_CWSI : TVar read CWSI Write CWSI;
  property Var_Tcrop : TVar Read Tcrop write Tcrop;
  //property Var_Tcrop_dir : TVar Read Tcrop_dir write Tcrop_dir;
  property Opt_WithRoots : boolean read FWithRoots write setWithRoots;
  property OptSinkTermMethod: TSinkTermMethod read FSinkTermMethod write FSinkTermMethod;
  property OptTransCalcMethod: TTransCalcMethod read FTransCalcMethod write FTransCalcMethod;
  property OptUseExternalWG: boolean read FUseExternalWG write setUseExternalWG;

  property OptDebug: boolean read FDebug write FDebug;
end;

procedure Register;

implementation

uses
  SysUtils, math, vcl.Dialogs;


procedure TSoilWaterETR.CreateAll;

var
  i : integer;

begin
  inherited CreateAll;
  ParCreate('psi_2', '[cm]', 200, psi_2);
  ParCreate('psi_3', '[cm]', 15000, psi_3);

  ParCreate('CompFactor', '[-]', 0.5, CompFactor);
  ParCreate('nFKcrit','[-]',0.5,nFKcrit);
  ParCreate('max_TransErr','[cm]',0.00001,max_TransErr);
  ParCreate('r_stem','[d]',1000,r_stem,'Xylem+Mesophyllwiderstand');
  VarCreate('ActTrans', '[mm]',0.0, false, ActTrans);
  VarCreate('ActTrans_', '[mm]',0.0, false, ActTrans_);
  VarCreate('PotTrans', '[mm]',0.0, false, PotTrans);
  VarCreate('PotTrans_', '[mm]',0.0, false, PotTrans_);
  VarCreate('PotEvap', '[mm]',0.0, false, PotEvap);
  VarCreate('PotEvap_', '[mm]',0.0, false, PotEvap_);
  VarCreate('ActEvap_', '[mm]',0.0, false, ActEvap_);
  VarCreate('TransRatio', '[-]',0.0, false, TransRatio);
  VarCreate('CWSI', '[-]',0.0, false, CWSI);
  VarCreate ('Tcrop', '[°C]',0.0,false, Tcrop, 'Bestandestemperatur');
  //VarCreate ('Tcrop_dir', '[°C]',0.0,false, Tcrop_dir, 'Bestandestemperatur_direkt');
  VarCreate ('delta_T', '[°C]', 0.0, false, delta_T, 'Bestandestemperatur-Lufttemperatur');
  VarCreate ('Tbase', '[°C]',0.0,false, Tbase, 'theoretische min. Bestandestemperatur');
  VarCreate ('Tmax', '[°C]',0.0,false, Tmax, 'theoretische max. Bestandestemperatur');
  StateCreate('CumActTrans', '[mm]', 0, true, CumActTrans);
  StateCreate('CumPotTrans', '[mm]', 0, true, CumPotTrans);
  StateCreate('CumWaterUptake', '[mm]', 0, true, CumWaterUptake, 'kumulierte über die Wurzeln aufgenommene Wassermenge [mm]');

  OptCreate('FTransCalcMethod', 'redFactor', FTransCalcOption);
  FTransCalcOption.OptionList.Clear;
  FTransCalcOption.OptionList.Add('redFactor');
  FTransCalcOption.OptionList.Add('resistances');

  OptCreate('UseExternalWG', 'true', FUseExternalWGOption, 'If true then WGs are loaded from weatherfile each time step, else internal calculated WGs are used');
  FUseExternalWGOption.OptionList.Clear;
  FUseExternalWGOption.OptionList.Add('true');
  FUseExternalWGOption.OptionList.Add('false');

  for i := 1 to n_comp do VarCreate('K_'+IntToStr(i), '[cm/d]', 0.0, true, K_arr[i]);

  if FWithRoots then for i := 1 to n_comp do begin
    ExternVCreate('effWLD_'+IntToStr(i),'[cm/cm3]',StateField, WLD_arr[i]);
    VarCreate('WAuf'+IntToStr(i), '[cm/d]', 0.0, false, Sink_arr[i]);
    WLD_Arr[i].Opt_writetoFile := true;
  end;
  if OptUseExternalWG then for i := 1 to n_comp+1 do begin
    ExternVCreate('WG'+IntToStr(i),'[cm3/cm3]',StateField,ExternWG_Arr[i]);
    ExternWG_Arr[i].Opt_writetoFile := false;
  end
  else for i := 1 to n_comp+1 do begin
    if ExternWG_Arr[i] <> nil then begin
      ExternWG_Arr[i].Search := false;
      ExternWG_Arr[i].Opt_writetoFile := false;
    end;
  end;
end;

procedure TSoilWaterETR.setWithRoots(settrue: boolean);
var
  i: integer;
begin
  if settrue then for i := 1 to n_comp do begin
    if WLD_arr[i] = nil then ExternVCreate('effWLD_'+IntToStr(i),'[cm/cm3]',StateField, WLD_arr[i]);
    if Sink_arr[i] = nil then VarCreate('WAuf'+IntToStr(i), '[cm/d]', 0.0, false, Sink_arr[i]);
    WLD_Arr[i].Opt_writetoFile := true;
  end;
  FWithRoots := true;
end;

procedure TSoilWaterETR.setUseExternalWG(settrue: boolean);
var
  i: integer;
begin
  if settrue then for i := 1 to n_comp+1 do begin
    if ExternWG_arr[i] = nil then ExternVCreate('WG'+IntToStr(i),'[cm3/cm3]',StateField, ExternWG_arr[i]);
    ExternWG_Arr[i].Search := true;
    ExternWG_Arr[i].Opt_writetoFile := false;
  end
  else for i := 1 to n_comp+1 do begin
    if ExternWG_Arr[i] <> nil then begin
      ExternWG_Arr[i].Search := false;
      ExternWG_Arr[i].Opt_writetoFile := false;
    end;
  end;
  FUseExternalWG := settrue;
end;


procedure TSoilWaterETR.Init(var GlobMod: TMod);
var
  i :integer;
begin
  inherited Init(GlobMod);
  ActTrans_.v := 0.0;
  PotTrans_.v := 0.0;
  PotEvap_.v := 0.0;
  CumActTrans.v := 0.0;
  CumActTrans.c := 0.0;
  CumPotTrans.v := 0.0;
  CumPotTrans.c := 0.0;
  for i := 1 to n_comp do Sink_arr[i].v := 0.0;
  If uppercase(FTransCalcOption.Option) = 'REDFACTOR' then FTransCalcMethod := redFactor;
  If uppercase(FTransCalcOption.Option) = 'RESISTANCES' then FTransCalcMethod := resistances;
  if FUseExternalWGOption.Option = 'true' then OptUseExternalWG := true;
  if FUseExternalWGOption.Option = 'false' then OptUseExternalWG := false;
  if FDebug then writeValues(true, 'Init');
  for i := 1 to n_comp do begin
    wld_arr[i].WriteToFile:=true;
  end;
end;

procedure TSoilWaterETR.CalcWGs;
begin
  inherited;
  If GlobTime.v > GlobMod.Starttime then begin
    CumWaterBalance.c := CumWaterBalance.c + CumActTrans.c;
    ActWaterBalance.v := CumWaterBalance.c*GlobTime.c;
  end;
end;

procedure TSoilWaterETR.UpdateWGs;
var
  i: integer;
begin
  for i := 1 to n_comp+1 do begin
    theta_arr[i].v := ExternWG_Arr[i].v;
    thetaadj_arr[i].v := WG_scaling.v * theta_arr[i].v;
    psi_arr[i].v := WPar[i].psi_b_f(WG_scaling.v * theta_arr[i].v);
    WMenge[i].v := Thetaadj_arr[i].v*Thick[i];
    theta_alt[i] := thetaadj_arr[i].v;
  end;
end;

function TSoilWaterETR.getPsiRoot: extended;
var
  Sqr_Wl_arr, Wl_fact  : TSoilArray;
  Sum_Sqr_wl, sum_wl  : real;
  i           : integer;
begin
  if FWithRoots = true then begin
    sum_Sqr_wl := 0.0;
    sum_wl := 0.0;
    result := 0.0;
    for I := 1 to n_comp do begin
      Sqr_wl_arr[i] := power(WLD_arr[i].v*Thick[i], CompFactor.v);
      Sum_wl := Sum_wl+wld_arr[i].v*Thick[i];
      Sum_Sqr_wl := Sum_Sqr_wl+Sqr_wl_arr[i];
    end;

    for I := 1 to n_comp do begin
      if sum_wl>0 then
        wl_fact[i]    := wld_arr[i].v*Thick[i]/sum_wl
      else
        wl_fact[i]    := 0.0;
      if psi_arr[i].v > 0 then
        result := result+log10(psi_arr[i].v)*wl_fact[i];
    end;
  end else result := psi_arr[1].v;
end;

function TSoilWaterETR.Trans_f(psi_leaf: real):real; {Transpirationsrate [cm/d]}
const
   a   = 0.02;     {mittlerer Wurzeldurchmesser [cm] }
   Rrr = 0.25E6;   {radiale Wurzel-"resistivity"  [d/cm] umgerechnet aus Reid (1991) }
//   r_stem = {1000}0.0;   {Xylem+Mesophyllwiderstand [d]  }
//   Thick = 10.0;   {cm SchichtThick }
var
  sum_up: real;    {Summe der Wasseraufnahme [cm/d]}
  i : integer;
begin
  sum_up := 0.0;
  for i := 1 to N_comp do begin
    if wld_arr[i].v > 0.0 then begin
      K_arr[i].v := max(WPar[i].Ku_b_f (thetaadj_arr[i].v), 0.0000001);
      rs_arr[i].v := r_soil_f(wld_arr[i].v, a, K_arr[i].v, Thick[i]);
      ri_arr[i].v := r_interf_f (rrr, thetaadj_arr[i].v, WPar[i].b_sat, wld_arr[i].v, Thick[i]);
      sink_arr[i].v := max(((psi_leaf+cropheight.v*100)-(psi_arr[i].v+Depth[i].v-0.5*Thick[i]))
                      /(rs_arr[i].v+ri_arr[i].v+r_stem.v),0);
                    {Senkenstärke [cm/d]}
      sum_up := sum_up+sink_arr[i].v;
    end else begin
      sink_arr[i].v := 0.0;
    end;
{    if sink_arr[i].v < 0.0 then
      sink_arr[i].v := 0.0
    else sink_arr[i].v := abs(sink_arr[i].v);}
  end;
  Trans_f := sum_up;
end;


procedure TSoilWaterETR.Calcsink_red_f;

var
  red_f : real;
  i : integer;

begin
  if OptSinkTermMethod = Psicrit then begin
    for i := 1 to n_comp do begin
      If psi_arr[i].v < psi_2.v then red_f := 1.0 else
        red_f := (log10(psi_arr[i].v)-log10(psi_3.v))/(log10(psi_2.v)-log10(psi_3.v));
      if red_f < 0.0 then
         red_f := 0.0;
      SinkRedf[i] := red_f;
    end;
  end
  else begin
    for i := 1 to n_comp do begin
      If nFK_arr[i] > nFKcrit.v then red_f := 1.0 else
        red_f := 1-nFK_arr[i]/nFKcrit.v;
      if red_f < 0.0 then
         red_f := 0.0;
      SinkRedf[i] := red_f;
    end;
  end;
end;



procedure TSoilWaterETR.CalcSinks;
const
  delta_psi = 1;   {  Žnderung des Blattwasserpotentials     [cm]   }
var
  uptake,      {Wasseraufnahme im internen Zeitschritt [cm]}
  uptake2,
  f, f2,
  df
            : real;
  success   : boolean;
  Sqr_Wl_arr  : TSoilArray;
  Sum_Sqr_wl  : real;
  i           : integer;

begin
  inherited CalcSinks;
  if FWithRoots = true then begin
    case FTransCalcMethod of
    resistances:
      begin
//        intWflow_arr[1].v := -0.1*ActEvap_.v/GlobMod.TimeStep + 0.1*NetRain.v/GlobMod.TimeStep;
        if LAI.v > 0.0 then begin
          psi_leaf.v := 1000;
          for i := 1 to n_comp do if wld_arr[i].v > 0 then begin
            if psi_arr[i].v > psi_leaf.v then psi_leaf.v := psi_arr[i].v;
          end;
//          int_stor_.v := int_stor.v;
          CalcActET;
          If (wld_arr[1].v <= 0.0) or (ActTrans_.v<=0.0) then begin
            for i := 1 to n_comp do sink_arr[i].v := 0;
{            intWflow_arr[1].v := -0.1*ActEvap_.v/GlobMod.TimeStep + 0.1*NetRain.v/GlobMod.TimeStep;
            CheckSinks;
            if (Interzeption.v > (aETP.v-(aETP.v*f_Evap)-ActTrans_.v)) then begin
              int_stor.v := int_stor.v + Interzeption.v - (aETP.v-(aETP.v*f_Evap)-ActTrans_.v);
              Interzeption.v := (aETP.v-(aETP.v*f_Evap)-ActTrans_.v);
            end;
            exit; {keine Iteration von PsiLeaf, wenn ActTrans_ = 0}
          end
          else begin
            psi_leaf.v := psi_leaf.v + 400;
            repeat
              success := false;
  //            int_stor_.v := int_stor.v;
              CalcActET;
              uptake := Trans_f(psi_leaf.v)*GlobMod.TimeStep;
              f := ActTrans_.v/10-uptake;
              if abs(f) > max_TransErr.v then begin
                uptake2 := Trans_f (psi_leaf.v+delta_psi)*GlobMod.TimeStep;
                f2 := ActTrans_.v/10.0-uptake2;
                df := (f-f2)/delta_psi;
                if abs(df) < 0.000000001 then begin
                  success := true;
                  break;
                end;
                while abs(df) < 0.0001 do df := df*10;
                if (psi_leaf.v = 0) and (f/df <= 0) then begin
                  success := true;
                  break;
                end;
                psi_leaf.v := psi_leaf.v + f/df;
                if Psi_leaf.v < 0 then Psi_leaf.v := 0;
              end else success := true;
            until success;
            rc.v := rc_f;
          end;
        end
        else begin                {no leafs}
//          int_stor_.v := int_stor.v;
          CalcActET;
          psi_leaf.v := 0.0;
          uptake := 0.0;
        end;

        intWflow_arr[1].v := -0.1*ActEvap_.v/GlobMod.TimeStep + 0.1*NetRain.v/GlobMod.TimeStep;
        CheckSinks;
        if (Interzeption.v > 0) and (Interzeption.v > (aETP.v-(aETP.v*f_Evap)-ActTrans_.v)) then begin
          int_stor.v := int_stor.v + Interzeption.v - (aETP.v-(aETP.v*f_Evap)-ActTrans_.v);
          Interzeption.v := (aETP.v-(aETP.v*f_Evap)-ActTrans_.v);
        end;

      end;
    redFactor:
      begin
        sum_Sqr_wl := 0.0;
        for I := 1 to n_comp do begin
          Sqr_wl_arr[i] := power(wld_arr[i].v*Thick[i], CompFactor.v);
          Sum_Sqr_wl := Sum_Sqr_wl+Sqr_wl_arr[i];
        end;
        sum_sink := 0.0;
        for I := 1 to n_comp do begin
          if sqr_wl_arr[i]>1e-6
            then Sink_arr[i].v := 0.1*pot_trans.v * sqr_wl_arr[i]/sum_sqr_wl
            else sink_arr[i].v := 0.0;
          sink_arr[i].v := sink_arr[i].v * SinkRedF[i];
          sum_sink := sum_sink + sink_arr[i].v;
        end;
        inherited CalcRates;
        CalcActET;
      end;
    end; {of case}
  end; // withRoots
end;


procedure TSoilWaterETR.CalcEvapoTranspi;
var
  pressure,                      { Atmosphärendruck in [mbar] }
  es,                            { Sättigungsdampfdruck [mbar] }
  gamma,                         {                     [mbar/øK] }
  delta
             : real;
  rc_pot: real;

const
  cp = 1003.0;      { spezifische W„rme der Luft [J/(Kg*K)] }

begin

  rc_pot        := rc_upscaling_f(rc0.v, f_rc_upscaling);
  pressure      := pressure_f ( Elev.v, TMPM.v);
  gamma         := cp*pressure/(0.622*(2.502*1000000-2361*TMPM.v));  //  statt gamma := Pressure*Psycro :  (dn 10.06.14)
                                                                     //0.622  ist Molmassenverhältnis von Wasser und Luft , Klammer im Nenner berechnet verdunstungsenthalpue von Wasser
  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstrahlung (W/m2)
  netRad.v      := max(0,0.6494*(GlobRad.v) - 18.417);
  es            := sat_vap_press_f (TMPM.v);
  delta         := delta_f(es, TMPM.v);
  if cropHeight.v <= 0.0 then ra.v := ra_f (wind_speed.v, 0.05)
                         else ra.v := ra_f (wind_speed.v, CropHeight.v);
  pETP.v := Penman(TMPM.v, Sat_def.v, NetRad.v, delta, gamma, l_h_v_water, ra.v, rc_pot) * GlobMod.Time.c;
  if LAI.v > 0.0
    then aETP.v := Penman(TMPM.v, Sat_def.v, NetRad.v, delta, gamma, l_h_v_water, ra.v, rc_f) * GlobMod.Time.c
    else aETP.v := pETP.v;
  Pot_Evap.v   := f_Evap*pETP.v;
  PotEvap_.v   := Pot_Evap.v;
  pTI           := pETP.v - pot_Evap.v;
  Interzeption_p;
  CalcEvap_red_f;
  ActEvap_.v  := pot_evap.v*Red_Evap.v;   { Reduktion }
  PotTrans_.v := pETP.v-Pot_Evap.v-Interzeption.v;
  ActTrans_.v := aETP.v-(aETP.v*f_Evap)-Interzeption.v;
  If ActTrans_.v < 0.0 then ActTrans_.v := 0.0;
  aETP.v := ActTrans_.v + ActEvap_.v + Interzeption.v;
end;

procedure TSoilWaterETR.CalcPotET;
var
  pressure,                      { Atmosphärendruck in [mbar] }
  es,                            { Sättigungsdampfdruck [mbar] }
  gamma,                         {                     [mbar/øK] }
  delta
             : real;
  rc_pot: real;

const
  cp = 1003.0;      { spezifische W„rme der Luft [J/(Kg*K)] }

begin


  rc_pot        := rc_upscaling_f(rc0.v, f_rc_upscaling);
  pressure      := pressure_f ( Elev.v, TMPM.v);
  gamma         := cp*pressure/(0.622*(2.502*1000000-2361*TMPM.v));  //  statt gamma := Pressure*Psycro :  (dn 10.06.14)
                                                                     //0.622  ist Molmassenverhältnis von Wasser und Luft , Klammer im Nenner berechnet verdunstungsenthalpue von Wasser
  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstrahlung (W/m2)
  netRad.v      := 0.6494*(GlobRad.v) - 18.417; //max(0,0.6494*(GlobRad.v) - 18.417);
  es            := sat_vap_press_f (TMPM.v);
  delta         := delta_f(es, TMPM.v);
  if cropHeight.v <= 0.0 then ra.v := ra_f (wind_speed.v, 0.05)
                         else ra.v := ra_f (wind_speed.v, CropHeight.v);
  pETP.v := Penman(TMPM.v, Sat_def.v, NetRad.v, delta, gamma, l_h_v_water, ra.v, rc_pot) * GlobMod.Time.c;
  Pot_Evap.v   := f_Evap*pETP.v;
  PotEvap_.v   := Pot_Evap.v;
  pTI           := pETP.v - pot_Evap.v;
  Interzeption_p;
  CalcEvap_red_f;
  ActEvap_.v  := pot_evap.v*Red_Evap.v;   { Reduktion }
  PotTrans_.v := pETP.v-Pot_Evap.v-Interzeption.v;
end;

procedure TSoilWaterETR.CalcActET;
var
  pressure,                      { Atmosphärendruck in [mbar] }
  es,                            { Sättigungsdampfdruck [mbar] }
  gamma,                         {                     [mbar/øK] }
  delta
             : real;
const
  cp = 1003.0;      { spezifische W„rme der Luft [J/(Kg*K)] }

begin
  pressure      := pressure_f ( Elev.v, TMPM.v);
  gamma         := cp*pressure/(0.622*(2.502*1000000-2361*TMPM.v));  //  statt gamma := Pressure*Psycro :  (dn 10.06.14)
                                                                     //0.622  ist Molmassenverhältnis von Wasser und Luft , Klammer im Nenner berechnet Verdunstungsenthalpue von Wasser
  // Berechnung der Nettostrahlung nach empirischer Funktion
  // gefitted aus Tagesdaten gemessener Nettostrahlung (W/m2) zu Globalstrahlung (W/m2)
  es            := sat_vap_press_f (TMPM.v);
  delta         := delta_f(es, TMPM.v);
  if LAI.v > 0.0
    then aETP.v := Penman(TMPM.v, Sat_def.v,  NetRad.v, delta, gamma, l_h_v_water, ra.v, rc_f) * GlobMod.Time.c
    else aETP.v := pETP.v;
  ActTrans_.v := aETP.v-(aETP.v*f_Evap)-Interzeption.v;
  If ActTrans_.v < 0.0 then begin
    ActTrans_.v := 0.0;
  end;
  aETP.v := ActTrans_.v + ActEvap_.v + Interzeption.v;
end;



procedure TSoilWaterETR.CalcRatesAndIntegrate;
begin
  if (FwithRoots = true) and (FTransCalcMethod = RedFactor) then Calcsink_red_f;
  inherited CalcRatesAndIntegrate;
  if (FTransCalcMethod = redFactor) then ActTrans.v := ActTrans.v+sum_sink*10.0*dt.v;
end;

procedure TSoilWaterETR.CalcRates;
var
  i: integer;
  deltaTmax, deltaTbase: double;
  rho: real;         { Dichte der Luft [kg/m3 ]  }
  delta,gamma, pressure, es: double;
  rc_pot: real;

const
  cp = 1003.0;      { spezifische W„rme der Luft [J/(Kg*K)] }
  Imax = 0.8;      {nach Jackson et al. 1988, wegen erhöhter Reflexion und Emission des fiktiv nicht transpirierenden Bestandes}
  Ibase = 0.9;     {nach Jackson et al. 1988, Berücksichtigung des Bodenwärmestroms}
begin
  psiRoot.v := getPsiRoot;
  SumOfInternalTimeSteps := 0.0;
  for i := 1 to n_comp+1 do Wflow_arr[i].v := 0;
  if OptUseExternalWG then
   UpdateWGs; {Zu Beginn des Zeitschritts setzen der WGs
                                       auf Werte aus Wetterdatei}
  ActTrans.v := 0;
  PotTrans.v := 0;
  PotEvap.v := 0;
  Act_Evap.v := 0;
  SumSinks.v := 0;
  n_int_timesteps.v := 0;
  dt.v := dt_alt;  {Startwert für Zeitschrittweiten-Steuerung ist der vorletzte Zeitschritt des vorherigen Tages.}
  if FDebug then writeValues(false, 'CalcRates vor Schleife');
  CalcPotET;
  int_stor.v := int_stor_.v;
  repeat
    CalcRatesAndIntegrate;
    SumOfInternalTimeSteps := SumOfInternalTimeSteps+dt.v;
    n_int_timesteps.v := n_int_timesteps.v+1;
    for i := 1 to n_comp+1 do Wflow_arr[i].v := Wflow_arr[i].v + intWflow_arr[i].v/GlobMod.Time.c*dt.v;
    ActTrans.v := ActTrans.v + ActTrans_.v/GlobMod.Time.c*dt.v;
    PotTrans.v := PotTrans.v + PotTrans_.v/GlobMod.Time.c*dt.v;
    PotEvap.v := PotEvap.v + PotEvap_.v/GlobMod.Time.c*dt.v;
    Act_Evap.v := Act_Evap.v + ActEvap_.v/GlobMod.Time.c*dt.v;
    SumSinks.v := SumSinks.v+SumSinks_int/GlobMod.Time.c*dt.v;
    if FDebug then writeValues(false, 'CalcRates in Schleife');
  until SumOfInternalTimeSteps >= self.GlobTime.c;
  CumActTrans.c := ActTrans.v/GlobMod.Time.c;
  CumPotTrans.c := PotTrans.v/GlobMod.Time.c;
  CumEvap.c  := Act_Evap.v/GlobMod.TimeStep;
  CumInterzept.c := Interzeption.v/GlobMod.TimeStep;
  CumWaterUptake.c := SumSinks.v*10;


    {Berechnung Bestandestemperatur und CWSI nach Jackson et al. 1988 }
  rho           := dens_air(TMPM.v);
  es            := sat_vap_press_f (TMPM.v);
  delta         := delta_f(es, TMPM.v);
  pressure      := pressure_f ( Elev.v, TMPM.v);
  gamma         := cp*pressure/(0.622*(2.502*1000000-2361*TMPM.v));  //  statt gamma := Pressure*Psycro :  (dn 10.06.14)
                                                                     //   0.622  ist Molmassenverhältnis von Wasser und Luft , Klammer im Nenner berechnet verdunstungsenthalpue von Wasser
  rc_pot        := rc_upscaling_f(rc0.v, f_rc_upscaling);
  gamma         :=gamma*(1+rc_pot/ra.v);

  deltaTmax:=ra.v*Imax*NetRad.v/(cp*rho);
  deltaTbase:= ra.v*Ibase*NetRad.v/(cp*rho)*gamma/(delta+gamma)-Sat_def.v/(delta+gamma);

  Tmax.v:=TMPM.v+deltaTmax;
  Tbase.v:=TMPM.v+deltaTbase;

  if (potTrans.v+pot_evap.v)<>0 then CWSI.v:= 1-(actTrans.v+act_evap.v)/(potTrans.v+pot_evap.v) else CWSI.v := 0;
  if actTrans.v = 0 then CWSI.v := 0;

  Tcrop.v:= TMPM.v + CWSI.v*(deltaTmax - deltaTbase) + deltaTbase;
  //Tcrop_dir.v:= TMPM.v +ra.v*Imax*NetRad.v/(cp*rho)*gamma*(1+rc.v/ra.v)/(delta+gamma*(1+rc.v/ra.v))-Sat_def.v/(delta+gamma*(1+rc.v/ra.v));
  delta_T.v := Tcrop.v-TMPM.v;



  {Berechnung abgeleitete Wassergehalte}
  CalcWGs;
end;

procedure TSoilWaterETR.writeValues(FirstTime: boolean;s: string);
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
    Write(f,TimeToStr(Time),';',GlobTime.v,';',dt.v,';',ActTrans.v,';',ActTrans_.v,';',PotTrans.v,';',PotTrans_.v);
    for i := 1 to 20 do write(f,';',thetaadj_arr[i].v);
    for i := 1 to 20 do write(f,';',WFlow_arr[i].v,';',intWFlow_arr[i].v);
  end;
  writeln(f,';',s);
  CloseFile(f);
end;

procedure TSoilWaterETR.writeDebug(Schicht: integer;dt,InFlow,OutFlow,Sink,Thick,WGalt,WGneu,Bil:Real);
{temporäre Ausgabe-Funktion, nur für Entwicklung}
var
  f: TextFile;
  i: integer;
const
  fn: string = 'P:\Stunden\DebugBil.csv';
begin
  AssignFile(f,fn);
  if FileExists(fn) then begin
    Append(f);
  end
  else begin
    Rewrite(f);
    Writeln(f,'Time;Schicht;dt;InFlow;OutFlow;Sink;Thick;WGalt;WGneu;Bil');
  end;
  Writeln(f,TimeToStr(Time),';',Schicht,';',dt,';',InFlow,';',OutFlow,';',Sink,';',Thick,';',WGalt,';',WGneu,';',Bil);
  CloseFile(f);
end;


procedure TSoilWaterETR.Integrate;
begin
  inherited integrate;
  If (ActTrans.v > 0) and (PotTrans.v > 0)
    then TransRatio.v := max(0, min(1, ActTrans.v/PotTrans.v))
    else TransRatio.v := 1.0;
end;


procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterETR]);
end;

end.

