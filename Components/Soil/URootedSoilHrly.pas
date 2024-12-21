unit URootedSoilHrly; // Neue Komponente

interface

uses
  USoilWaterMod, UMod, Inifiles, UState, ULayeredSoil, UPenMonteithHrly, classes;

type
  real = double;

  TSinkTermMethod = (nFKcrit, Psicrit);


TSoilWaterModelRHrly = class(TSoilWaterMod)

private
  Sum_Sink          : real; // internal variable for summing up all sink terms
  PotTransH         : real; // internal variable for calculating pot. Trans. for actual time step
  Sum_PotTrans      : real;
  FWithRoots : boolean;
  FSinkTermMethod: TSinkTermMethod;

protected
  procedure CreateAll; override;

public
  Wld_arr : TSoilExtArray;  // Wurzellängendichten [cm.cm-3]
  WL_arr  : TSoilExtArray;  // Wurzellängen [cm.cm-2]
  WLges   : TVar;           // GesamtWurzellänge [cm]
  // w_influx : TSoilVarArray; // Wasserinfluxraten [cm3.cm-1.d-1]
  SinkRedF : TSoilArray;    // Reduktionsfaktoren bei Wasseraufnahme

  psi_2,                    // Wasserspannung ab der Wasseraufnahme beginnt abzunehmen
  psi_3,                    // Wasserspannung ab der Wasseraufnahme = 0
  CompFactor                // Konkurrenzfaktor für Wasseraufnahme der Wurzeln (i.d.R. < 1.0)
   : Tpar;

  nFKcrit: TPar;

  PotTrans : TexternV;
  ActTrans : Tvar;         // aktuelle Transpirationsrate [mm/d]
  TransRatio : TVar;       // Verhältnis aktuelle zu potentielle Transpiration
  TR_arr: THourArray;      // Stundenwerte von TransRatio
  CumTrans : TState;        // kumulative Transpiration [mm]
  potTrans_arr : THourExtArray; // Array für Stundenwerte der pot. Transpiration

  constructor create( AOwner:TComponent); override;

  procedure Init(var GlobMod: TMod); override;

  procedure Calcsink_red_f;
  procedure CalcSinks; override;
  procedure CalcRatesAndIntegrate; override;
  procedure CalcRates; override;
  procedure Integrate; override;

  procedure Set_GlobMod(value:TMod);override;

published
  property Par_Psi_2 : TPar read psi_2 write psi_2;
  property Par_psi_3 : TPar read psi_3 write psi_3;
  property Comp_fact : Tpar read CompFactor write CompFactor;
  property Par_nFKcrit: TPar read nFKcrit write nFKcrit;
  property St_CumTrans : TState read CumTrans write CumTrans;
  property Var_ActTrans : TVar read ActTrans write ActTrans;
  property Var_TransRatio : TVar read TransRatio write TransRatio;
  property Opt_WithRoots : boolean read FWithRoots write FWithRoots;
  property OptSinkTermMethod: TSinkTermMethod read FSinkTermMethod write FSinkTermMethod;
end;

procedure Register;

implementation

uses
  SysUtils, math;


procedure TSoilWaterModelRHrly.CreateAll;

var
  i : integer;

begin
  inherited CreateAll;
  ParCreate('psi_2', '[cm]', 200, psi_2);
  ParCreate('psi_3', '[cm]', 15000, psi_3);

  ParCreate('CompFactor', '[-]', 0.5, CompFactor);
  ParCreate('nFKcrit','[-]',0.5,nFKcrit);
  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans);
  VarCreate('ActTrans', '[mm.d-1]',0.0, false, ActTrans);
  VarCreate('TransRatio', '[-]',0.0, false, TransRatio);
  StateCreate('CumTrans', '[]mm', 0, true, CumTrans);

  if FWithRoots = true then begin
    for i := 1 to n_comp do begin
      ExternVCreate('effWLD_'+IntToStr(i),'[cm/cm3]',StateField, WLD_arr[i]);
      ExternVCreate('effWL_'+IntToStr(i), '[cm.cm-2]', StateField,WL_arr[i]);
      VarCreate('WAuf'+IntToStr(i), '[cm.d-1]', 0.0, false, Sink_arr[i]);
    end;
  end;

  For i := 1 to 24 do begin
    ExternVCreate('pT'+IntTostr(i), '[mm/d]',StateField, potTrans_arr[i]);
    VarCreate('TR'+IntTostr(i), '[-]',0.0, false, TR_arr[i]);
  end;

end;


constructor TSoilWaterModelRHrly.create( AOwner:TComponent);

begin
  inherited create(AOwner);
  max_dt := 1/24;  
  CreateAll;

end;

procedure TSoilWaterModelRHrly.Set_GlobMod(value:TMod);
begin
  inherited set_globmod(value);
  CreateAll;
end;

procedure TSoilWaterModelRHrly.Init(var GlobMod: TMod);

var
  i :integer;
begin
inherited Init(GlobMod);
  ActTrans.v := 0.0;
  CumTrans.v := 0.0;
  CumTrans.c := 0.0;
  for i := 1 to n_comp do
   Sink_arr[i].v := 0.0;


end;

procedure TSoilWaterModelRHrly.Calcsink_red_f;

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



procedure TSoilWaterModelRHrly.CalcSinks;

var
  Sqr_Wl_arr  : TSoilArray;
  Sum_Sqr_wl  : real;
//  sum_sink    : real;
  i           : integer;

begin
  inherited CalcSinks;
  if FWithRoots = true then begin

    sum_Sqr_wl := 0.0;
    for I := 1 to n_comp do begin
      Sqr_wl_arr[i] := power(wl_arr[i].v, CompFactor.v);
      Sum_Sqr_wl := Sum_Sqr_wl+Sqr_wl_arr[i];
    end;

    sum_sink := 0.0;
    for I := 1 to n_comp do begin
      if sqr_wl_arr[i]>1e-6 then
        Sink_arr[i].v := 0.1*PotTransH * sqr_wl_arr[i]/sum_sqr_wl
      else
        sink_arr[i].v := 0.0;
      sink_arr[i].v := sink_arr[i].v * SinkRedF[i];
      sum_sink := sum_sink + sink_arr[i].v;
//      If Wl_arr[i].v > 0.0 then
//        w_influx[i].v := sink_arr[i].v/wl_arr[i].v
//      else
//        w_influx[i].v := 0.0;
    end;
  end; // withRoots
end;


procedure TSoilWaterModelRHrly.CalcRatesAndIntegrate;
var
  h,i : integer;
begin
  h := round((SumOfInternalTimeSteps+dt.v/2)*24);
  if h < 1 then h := 1;
  if h > 24 then h := 24;
  PotTransH := PotTrans_arr[h].V;
  if FwithRoots = true then Calcsink_red_f;
  inherited CalcRatesAndIntegrate;
  ActTrans.v := ActTrans.v+sum_sink*10.0*dt.v;
  CumTrans.c := ActTrans.v;
  CumTrans.v := CumTrans.V + CumTrans.c * dt.v;
  for i := 1 to 24 do
    if (SumOfInternalTimeSteps+dt.v/2 >= i/24) and (SumOfInternalTimeSteps < i/24+dt.v/2) then
      if (Sum_Sink > 0) and (PotTransH > 0) then TR_arr[i].V := max(0, min(1, sum_sink*10/PotTransH)) else TR_arr[i].V := 1;
end;

procedure TSoilWaterModelRHrly.CalcRates;

begin
  if FwithRoots = true then ActTrans.v := 0.0;
  SumOfInternalTimeSteps := 0.0;
  Sum_PotTrans := 0.0;
  dt.v := max_dt;
  repeat
    CalcRatesAndIntegrate;
    SumOfInternalTimeSteps := SumOfInternalTimeSteps+dt.v;
    Sum_PotTrans := Sum_PotTrans+PotTransH*dt.v;
  until SumOfInternalTimeSteps >= self.GlobTime.c;
  if FwithRoots = true then ActTrans.v := ActTrans.v/GlobTime.c;
end;


procedure TSoilWaterModelRHrly.Integrate;
begin
  inherited integrate;
  If (ActTrans.v > 0.0) and (Pottrans.v > 0) then
      TransRatio.v := max(0, min(1, ActTrans.v/Pottrans.v))
  else TransRatio.v := 1.0;
end;


procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterModelRHrly]);
end;

end.

