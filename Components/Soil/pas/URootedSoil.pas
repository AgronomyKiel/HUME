unit URootedSoil; // Neue Komponente

interface

uses
  USoilWaterMod, UMod, UState, ULayeredSoil, classes, UAbstractPlant;

type
  real = double;

  TSinkTermMethod = (nFK_crit, Psicrit, Feddes);
//  TAutoIrri = (no, yes); depracted is now an Option
  TAutoirriMethod = (amTransRatio, amProznFKWe);
  T_Sqrwl_Funct = (ReductionFactor, NoReductionFactor);
//  TSource = (fromParameter, fromPlantModel); // Source of Psi2 value

TSoilWaterModelR = class(TSoilWaterMod)

private
  f_Sqrwl_funct: T_Sqrwl_Funct;
  Sum_Sink        : real;    /// internal variable for summing up all sink terms
  FWithRoots      : boolean;  /// Option for calculation with/without roots
  fAutoirriMethod : TAutoirriMethod;
  fPsi2Opt : TSource;   // Source of Psi2 value
  FSinkTermMethod : TSinkTermMethod;

  procedure setWithRoots(settrue: boolean);
    procedure CreateOptionsRootedSoil;
//  function GetWLD(Index:Integer):real; virtual;


protected

  procedure SetPlantModel(NewPlantModel:TAbstractplant); override;


public
  AutoIrriOptStr : Toption;
  AutoIrriMethodOptStr : Toption;
  SinkTermMethodOptStr  : Toption;


  ExWld_arr : TSoilExtArray;  /// Wurzellängendichten [cm.cm-3]
  WLges   : TVar;           /// GesamtWurzellänge [cm]
  // w_influx : TSoilVarArray; /// Wasserinfluxraten [cm3.cm-1.d-1]
  SinkRedF : TSoilArray;    /// Reduktionsfaktoren bei Wasseraufnahme
  psiRoot: TVar; /// average, weighted soil water potential within the rooting zone [pF]
  psi_2,                    /// Wasserspannung ab der Wasseraufnahme beginnt abzunehmen
  psi_3,                    /// Wasserspannung ab der Wasseraufnahme = 0
  CompFactor,                /// Konkurrenzfaktor für Wasseraufnahme der Wurzeln (i.d.R. < 1.0)
  IrriAmount                 /// Auto BEw. Menge [mm]
   : Tpar;
  Autoirri_nFKcrit: TPar;   /// critical nFK value for triggering irrigation
  nfk_threshold: TPar;
  feddes_a:  TPar;
  feddes_b:  TPar;
  feddes_c : TPar;

  nFKcrit: TPar;

  PotTrans : TexternV;      /// External value for potential transpiration
  Interzeption: TexternV;  /// External value for Interception
  ActTrans : Tvar;         /// aktuelle Transpirationsrate [mm/d]
  TransRatio : TVar;       /// Verhältnis aktuelle zu potentielle Transpiration
  TransIntRatio : TVar;    /// Verhältnis aktuelle zu potentielle Transpiration
  Eact_ETP: TVar;          /// Ration of act. evaporation to pot. evapotranspiration
  Psi2: TVar;              /// water potential at which water uptake by the plant starts to decrease [hPa]
  act_rooted_comps : TVar;  /// actual number of rooted compartiments

  ///
  ///
  CumAutoIrrigation : TState; /// cum. Amount of  Irrigation
  CumTrans : TState;       /// kumulative Transpiration [mm]
  CumET: TState;           /// cumulative actual Evapotranspiration
  CumETpot: TState;        /// cumulative potential Evapotranspiration
  CumTranspot : TState;    /// cumulative potential Transpiration
  f_SqrWl_Option: TOption;   /// Option for sink reduction (Sqr_wl_arr calculation)
procedure CreateAll; override;

procedure Init(var GlobMod: TMod); override;

procedure Calcsink_red_f;
procedure CalcSinks; override;
procedure CalcRatesAndIntegrate; override;
procedure CalcRates; override;
//procedure Integrate; override;

//property Wld_arr[Index : Integer]: real read getWLD;  /// Wurzellängendichten [cm.cm-3]


//procedure Set_GlobMod(value:TMod);override;
published
  property Ex_PotTrans : TexternV read PotTrans write PotTrans;
  property Ex_Interzeption: TexternV read Interzeption write Interzeption;
  property Par_Psi_2 : TPar read psi_2 write psi_2;
  property Par_psi_3 : TPar read psi_3 write psi_3;
  property Comp_fact : Tpar read CompFactor write CompFactor;
  property Par_nFKcrit: TPar read nFKcrit write nFKcrit;
  property St_CumTrans : TState read CumTrans write CumTrans;
  property Var_ActTrans : TVar read ActTrans write ActTrans;
  property Var_TransRatio : TVar read TransRatio write Transratio;
  property Var_TransIntRatio : TVar read TransIntRatio write TransIntratio;
  property Psi_Root : TVar read psiRoot write psiRoot;
//  property AutoIrrigate: TAutoIrri read fAutoIrrigate write fAutoIrrigate;
  property AutoirriMethod: TAutoirriMethod read fAutoirriMethod write fAutoirriMethod;
  property Opt_WithRoots : boolean read FWithRoots write setWithRoots;
  property OptSinkTermMethod: TSinkTermMethod read FSinkTermMethod write FSinkTermMethod;
  property Opt_Psi2: TSource read fPsi2Opt write fPsi2Opt; // Source of Psi2 value


end;

procedure Register;

implementation

uses
  SysUtils, math, dialogs;




procedure TSoilWaterModelR.CreateAll;

var
  i : integer;
  ndx_str : string;

begin
  inherited CreateAll;
  if DebugForm <> NIL then
    DebugForm.MyCreate;
  ParCreate('psi_2', '[cm]', 200, psi_2);
  ParCreate('psi_3', '[cm]', 15000, psi_3);
  ParCreate('feddes_a', '[hPa]', 400, feddes_a,'Enhancement of psi_2 at high pot. Transp.');
  ParCreate('feddes_b', '[mm]', 5, feddes_b,'threshold for psi_2 calculation');
  ParCreate('feddes_c', '[hPa]', 1, feddes_c,'threshold for psi_2 calculation');
  ParCreate('nfk_threshold', '[-]', 0.01, nfk_threshold,'threshold (water buffer) for sink reduction');
  ParCreate('CompFactor', '[-]', 0.5, CompFactor);
  ParCreate('nFKcrit','[-]',0.5,nFKcrit);
  ParCreate('IrriAmount','[mm]',10,IrriAmount, 'Amount of automated irrigation per irrigation');
  ParCreate('Autoirri_nFKcrit', '[%]', 60, Autoirri_nFKcrit, 'Prozent nFK ab der bewässert wird, wenn AutoirriMeth auf amProznFKWe steht');

  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans);
  ExternVcreate('Interzeption', '[mm.d-1]', stateField, Interzeption);

  VarCreate('ActTrans', '[mm.d-1]',0.0, false, ActTrans);
  VarCreate('TransRatio', '[-]',0.0, false, TransRatio);
  VarCreate('TransIntRatio', '[-]',0.0, false, TransIntRatio);
  VarCreate('Eact_ETP', '[-]',0.0, false, Eact_ETP);
  VarCreate('psiRoot', '[pF]',0.0, false, psiRoot);
  VarCreate('Psi2', 'cm', 0.0, false, psi2);
  VarCreate('act_rooted_comps', '[n]',  0, true, act_rooted_comps);

  StateCreate('CumAutoIrrigation', '[mm]', 0, true, CumAutoIrrigation);
  StateCreate('CumTrans', '[mm]', 0, true, CumTrans);
  StateCreate('CumET','[mm]',0,true,CumET);
  StateCreate('CumETpot','[mm]',0,true,CumETpot);
  StateCreate('CumTranspot', '[mm]',0,true, CumTranspot);

  if FWithRoots = true then begin
    for i := 1 to n_comp do begin
      if i < 9 then
        ndx_str := '_'+IntTostr(i)
      else
        ndx_str := IntTostr(i);

      ExternVCreate('effWLD_'+inttostr(i),'[cm/cm3]',StateField, exWLD_arr[i]);
      VarCreate('WAuf'+ndx_str, '[cm.d-1]', 0.0, false, Sink_arr[i]);
    end;
  end;
  CreateOptionsRootedSoil;

end;

procedure TSoilWaterModelR.setWithRoots(settrue: boolean);
var
  i: integer;
begin
  if settrue then for i := 1 to n_comp do begin
    if exWLD_arr[i] = nil then ExternVCreate('effWLD_'+IntToStr(i),'[cm/cm3]',StateField, exWLD_arr[i]);
    if Sink_arr[i] = nil then VarCreate('WAuf'+IntToStr(i), '[cm.d-1]', 0.0, false, Sink_arr[i]);
  end;
  FWithRoots := true;
end;




procedure TSoilWaterModelR.Init(var GlobMod: TMod);

var
  i :integer;
begin
  inherited Init(GlobMod);
  if uppercase(f_Sqrwl_Option.Option) = uppercase('NoReductionFactor') then
    f_Sqrwl_funct := NoReductionFactor;
  if uppercase(f_Sqrwl_Option.Option) = uppercase('ReductionFactor') then f_Sqrwl_funct := ReductionFactor;

  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Feddes') then
    OptSinkTermMethod := Feddes;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Psicrit') then
    OptSinkTermMethod := Psicrit;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('nFKcrit') then
    OptSinkTermMethod := nFK_crit;


  ActTrans.v := 0.0;
  CumTrans.v := 0.0;
  CumTrans.c := 0.0;
  CumETpot.v := 0.0;
  CumET.v := 0.0;
  CumTranspot.v := 0.0;
  transratio.v := 1.0;
  transIntratio.v := 1.0;
  if self.psi_2.v > self.psi_3.v then
    psi_3.v := psi_2.v * 1.1;

  for i := 1 to n_comp do
   Sink_arr[i].v := 0.0;
  if DebugForm <> NIL then
    DebugForm.Init;

end;

procedure TSoilWaterModelR.Calcsink_red_f;   /// Sink reduction calculation with 3 options

var
  red_f, psi2_, psi2_low, rPAW : real;
  i : integer;

begin
   if OptSinkTermMethod = Feddes then begin
	if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet
	  then Psi2.v := Plantmodel.Psi2    // Psi2 from plant model
	  else Psi2.v := Psi_2.v;           // Psi2 from parameter
	psi2_low:=psi2.v+feddes_a.v;
      if(PotTrans.v<feddes_c.v) then
       psi2_:=psi2_low else
        if(PotTrans.v>5) then
          psi2_:=psi2.v else
            psi2_:= psi2_low+(PotTrans.v-feddes_b.v)*
                ((psi2_low-psi2.v)/(feddes_c.v-feddes_b.v));
    for i := 1 to (n_comp-1) do begin
      rPAW:= ((theta_arr[i].v-pwp_arr[i]))/nFK_arr[i];
	  	If psi_arr[i].v < psi2_ then red_f := 1.0 else
			red_f := (psi_arr[i].v-psi_3.v)/(Psi2_-psi_3.v);
    // Staunässe nach Feddes
    // If psi_arr[i].v < 1 then  red_f :=max(0.1,psi_arr[i].v);
    //      rPAW:= ((theta_arr[i].v-pwp_arr[i]))/nFK_arr[i];
	    If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
			  red_f := 0.0;
			SinkRedf[i] := red_f;
	end;
  end; // Feddes end

  if OptSinkTermMethod = Psicrit then begin
    if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet
      then Psi2.v := Plantmodel.Psi2    // Psi2 from plant model
      else Psi2.v := Psi_2.v;           // Psi2 from parameter
    for i := 1 to (n_comp-1) do begin
     rPAW:= ((theta_arr[i].v-pwp_arr[i]))/nFK_arr[i];
      If psi_arr[i].v < Psi2.v then red_f := 1.0 else
        red_f := (log10(psi_arr[i].v)-log10(psi_3.v))/(log10(Psi2.v)-log10(psi_3.v));
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedf[i] := red_f;
    end;  //Psicrit end
  end;
  if OptSinkTermMethod = nFK_crit then begin
    for i := 1 to (n_comp-1) do begin
      rPAW:= ((theta_arr[i].v-pwp_arr[i]))/nFK_arr[i];
      If rPAW > nFKcrit.v then red_f := 1.0 else
        red_f := rPAW/nFKcrit.v;
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
     SinkRedf[i] := red_f;
    end;
  end; //nFKcrit end
end;


procedure TSoilWaterModelR.CalcSinks;

var
  Sqr_Wl_arr, Wl_fact  : TSoilArray;
  Sum_Sqr_wl, sum_wl  : real;
//  sum_sink    : real;
  i           : integer;

begin
  inherited CalcSinks;
  if FWithRoots = true then begin
    sum_Sqr_wl := 0.0;
    sum_wl := 0.0;
    psiRoot.v := 0.0;

  act_rooted_comps.v := 0.0;
  for i  := 1 to act_n_comp do
    if ExWLD_arr[i].v > 0.0 then
      act_rooted_comps.v := i;

  if ShowWarnings then
    if act_rooted_comps.v > self.bil_nr.v then
      showmessage('Number of rooted compartments larger than balanance index, computed balance probably not correct');

    for I := 1 to act_n_comp do begin
      case f_SqrWl_funct of
        NoReductionFactor:
          Sqr_wl_arr[i] := power(ExWLD_arr[i].v*Thick[i], CompFactor.v);
        ReductionFactor:
          Sqr_wl_arr[i] := SinkRedf[i]*power(ExWLD_arr[i].v*Thick[i], CompFactor.v);
      end;
      Sum_wl := Sum_wl+Exwld_arr[i].v*Thick[i];
      Sum_Sqr_wl := Sum_Sqr_wl+Sqr_wl_arr[i];
    end;

    for I := 1 to act_n_comp do begin
      if sum_wl>0 then
        wl_fact[i]    := Exwld_arr[i].v*Thick[i]/sum_wl
      else
        wl_fact[i]    := 0.0;
      if psi_arr[i].v > 0 then
        psiRoot.v := psiRoot.v+log10(psi_arr[i].v)*wl_fact[i];
    end;
 {   if Sum_Sqr_wl > 0 then
      psiRoot.v := psiRoot.v/Sum_Sqr_wl
    else
      psiRoot.v := 0.0; }
{    if psiRoot.v > 0 then
      psiRoot.v := log10(psiRoot.v)
    else psiroot.v := 0.0; }

    sum_sink := 0.0;
    for I := 1 to act_n_comp do begin
      if sqr_wl_arr[i]>1e-6 then
        Sink_arr[i].v := 0.1*pottrans.v * sqr_wl_arr[i]/sum_sqr_wl
      else
        sink_arr[i].v := 0.0;
      sink_arr[i].v := max(0,sink_arr[i].v * SinkRedF[i]);
      // nfk_threshold = buffer in order to avoid incoherent water flows
      if sink_arr[i].v > (((theta_arr[i].v-WPar[i].b_rest)*Thick[i])-nfk_threshold.v) then
        sink_arr[i].v := ((theta_arr[i].v-WPar[i].b_rest)*Thick[i])-nfk_threshold.v;
      sum_sink := sum_sink + sink_arr[i].v;
//      If Wl_arr[i].v > 0.0 then
//        w_influx[i].v := sink_arr[i].v/wl_arr[i].v
//      else
//        w_influx[i].v := 0.0;
    end;
  end; // withRoots
end;


procedure TSoilWaterModelR.CalcRatesAndIntegrate;

begin
  if FwithRoots = true then
    Calcsink_red_f;
//  CalcSinks;

  inherited CalcRatesAndIntegrate;
  if Autoirrioptstr.Option = 'yes' then begin
     if AutoirriMethodoptstr.Option = 'amTransRatio' then begin
       if (self.TransRatio.v < 0.99) then begin
         WAmount[1].v := WAmount[1].v + self.IrriAmount.v/10*dt.v;
         CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v*dt.v;
       end;
       end else begin
       if self.ProzNFK0_Weff.v < Autoirri_nFKcrit.v then begin
         WAmount[1].v := WAmount[1].v + self.IrriAmount.v/10*dt.v;
         CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v*dt.v;
       end;
    end;
  end;
  ActTrans.v := ActTrans.v+sum_sink*10.0*dt.v;    //[mm]
  CumTrans.c := ActTrans.v; //cumTrans.c+sum_sink*10.0*dt.v;
end;


procedure TSoilWaterModelR.CalcRates;
begin
  if FwithRoots = true then begin
     ActTrans.v := 0.0;
     cumTrans.c := 0.0;
     cumautoirrigation.c := 0.0;
  end;
  // for debugging
  //Pottrans.v := 0.0;
  inherited CalcRates;
  if FwithRoots = true
    then ActTrans.v := ActTrans.v/GlobTime.c;
  If GlobTime.v > GlobMod.Starttime then begin  // add values to water balance
    CumWaterBalance.c := CumWaterBalance.c + CumTrans.c - CumAutoIrrigation.c;
  end;
  If (ActTrans.v > 0.0) and (Pottrans.v > 0) then begin
      TransRatio.v := max(0, min(1, ActTrans.v/Pottrans.v));
      TransIntRatio.v:= max(0, min(1, (ActTrans.v+ interzeption.v)/(Pottrans.v+interzeption.v)));  //ar
  end else begin
    TransRatio.v := 1.0;
    TransIntRatio.v := 1.0;
  end;
  if ((potTrans.v+interzeption.v+pot_Evap.v) > 0.0) then
    Eact_ETP.v:= Act_Evap.v/(potTrans.v+interzeption.v+pot_Evap.v)
    else Eact_ETP.v:=1;
  CumET.c:= CumTrans.c + Act_Evap.v;
  CumETpot.c:= potTrans.v + pot_Evap.v;
  CumTranspot.c:=potTrans.v;
  if DebugModus and (DebugForm <> NIL) then
    DebugForm.update;
end;

procedure TSoilWaterModelR.CreateOptionsRootedSoil;
begin
  //  fAutoIrrigate := no;
  OptCreate('SqrWl_Sink_ReductionFactor', 'NoReductionFactor', f_SqrWl_Option, 'Option for sink reduction (Sqr_wl_arr calculation)');
  f_SqrWl_Option.OptionList.Add('ReductionFactor');
  f_SqrWl_Option.OptionList.Add('NoReductionFactor');
  OptCreate('AutoIrri', 'no', AutoIrriOptStr);
  AutoIrriOptStr.optionlist.Clear;
  AutoIrriOptStr.optionlist.Add('no');
  AutoIrriOptStr.OptionList.Add('yes');
  OptCreate('AutoIrriMethod', 'amProznFKWe', AutoIrriMethodOptStr);
  AutoIrriMethodOptStr.optionlist.Clear;
  AutoIrriMethodOptStr.optionlist.Add('amProznFKWe');
  AutoIrriMethodOptStr.OptionList.Add('amTransRatio');
  OptCreate('SinkTermMethod', 'Feddes', SinkTermMethodOptStr);
  SinkTermMethodOptStr.optionlist.Clear;
  SinkTermMethodOptStr.optionlist.Add('Psicrit');
  SinkTermMethodOptStr.OptionList.Add('nFkcrit');
  SinkTermMethodOptStr.OptionList.Add('Feddes');
end;


procedure TSoilWaterModelR.SetPlantModel(NewPlantModel:TAbstractplant);

var
  i : integer;

begin
  inherited;
  if (plantmodel <> nil) and (Plantmodel.withroots = true) then begin
    for i := 1 to n_comp do begin
      exWLD_arr[i].search := false;
      exWLD_arr[i].f_v := @Plantmodel.p_WLD[i].fv;
      exWLD_arr[i].source := '['+NewPlantmodel.name+']';
    end;
  end;

end;


procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterModelR]);
end;

end.


