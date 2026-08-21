///<summary>
/// Module for dry matter production of silage maize.
/// Authors: Katja Holzhauser, Josephine Bukowiecki, Babette Wienforth, Henning Kage & Crop Science and Agronomy Group, Kiel University
/// Last edited: 14.08.2026
/// Parts of the module are published in:
/// References:
/// Holzhauser, K., Wienforth, B.M., Komainda, M., Herrmann, A., Zimmermann, I. & Dippold, M.A. et al. (2026) HUME-Maize: modelling silage maize yield formation across genotypes and scales. The Journal of Agricultural Science, 164, e34. Available from: https://doi.org/10.1017/S0021859626100719.
/// Holzhauser, K. (2025) Cover Crops for Sustainable Silage-Maize Production: Enhancing Resource Use Efficiency through Modelling and Remote Sensing (Doctoral dissertation). Christian-Albrechts-Universität zu Kiel: Kiel Available from: https://macau.uni-kiel.de/receive/macau_mods_00006346.
/// Wienforth, B. (2011) Cropping systems for biomethane production: a simulation based analysis of yield, yield potential and resource use efficiency (Doctoral dissertation). Christian-Albrechts-Universität zu Kiel
///</summary>

unit Usublightint_growth_Maize;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
   UMod, UState, URootedSoil,
  UAbstractPlant, USubDevelopment_Maize;
Type
TDMCalcMethod = (ExpLUE_f_Rad, ConstLue, LinLUE_f_Rad);

TDroughtImpact = (DroughtImpact, NoDroughtImpact);

Tsublightint_growth_Maize = class(TSubmodel)

private
protected
  fDMCalcMethod : TDMCalcMethod;
  fDroughtImpact : TDroughtImpact;
  fSoilWaterModel : TSoilWaterModelR;

  Procedure SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);


public
  // Variables

  fInt : TVar;   // Fraction of intercepted radiation (not used in the model)
  IntPar : TVar;   //
  LUE : TVar;   //  Light use efficiency
  LUETempfact : TVar;   // Light use efficiency corrected by temperature (without drouthstress equal to effective_LUE)
  LUETempf_SWDF : TVar;   //  Light use efficiency corrected by temperature and waterdeficied(with drouthstress equal to effective_LUE)
  TUE_vpd : TVar; // Transpiration use efficiency calculated out of the vapour pressure deficit; TUE_vpd=alpha*Sat_def^-beta,
                  // there alpha=10.3 and beta 0.42; Reference: Ahuja LR et al., 2008, "Response of Crops to limeted water: Understanding and Modelling water
                  //stress effects on Plant Growth Processes", Chapter 2, pp.39
  TotTMgRate : TVar;   // Trockenmassezuwachsrate [g/m2/d]
  TotTMgRate_TUE : TVar;
  Tempfact : TVar;   //
  SWDF: TVar;   // Soil water deficit factor
  Trans_daysGR : TVar;
  avg_pot_Trans_GlobRad : TVar;          //

  // State Variables

  Qsum : TState;   // aufsummierte aufgenommene Strahlung (nur zur externen berechnung (Excel) der LUE notwendig)
  QsumTempf_SWDF : TState; // aufsummierte aufgenommene Strahlung, unter Berücksichtigung des Temperatureffekts und des Wasserstress
                           //(nur zur externen berechnung (Excel) der LUE notwendig)
  TotDM : TState;   //
  pot_Trans_GlobRad : TState;
  Trans_days : TState;
  cumPAR_Trans_days : TState;

  // Parameters
  //exkPAR : TPar;   //
  LUE0 : TPar;   // Light use efficiency at zero radiation according to Ritchie's approach
  LUEexp : TPar;   // Exponent of light conversion equation according to Ritchie's approach
  LUEmax : TPar;   //
  LUEsteig : TPar;   //
  consLUE   : TPar;   // light use efficiency assuming constant LUE
  Ct1, Ct2, Ct3, Ct4 : TPar; // Kardinaltemperaturen
  TRcrit : TPar; // Transratio unterhalb der Trockenstress > Stomataschluss tatsächlich zu Trockenmasseeinbußen führen
  alpha_TUE : TPar; // Parameter for calculating TUE_vpd
  beta_TUE : TPar;  // Parameter for calculating TUE_vpd
  SWDF_fact : TPar; // Potenzfaktor zur nichtlinearen Beschreibung des Zusammenhangs zwischen TransRatio und SWDF

  // External Variables
  Rad_Int : TExternV;   //
  LAI : TExternV;   //
  Tbase6 : TExternV;   //
  Temp : TExternV;   //
  XStage : TExternV;   //
  IStage : TExternV;   //
  TransRatio : TExternV;   // Ratio actual to potential transpiration [-]
  Sat_def :  TExternV;
  ActTrans : TExternV;
  ExtPAR_varLAI : TExternV; // aus subpartitioning, über den LAI (LAIgreen) variabler Extinktionskoeffizient
  pot_Trans : TExternV;
  GlobRad : TExternV;
  NNI : TExternV; // Nitrogen Nutrition index

  OptDroughtimpact : Toption;
  OptDMCalcMethod  : TOption;

  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
 
published
  //Variables

  Property Var_fInt : TVar read fInt write fInt;
  Property Var_IntPar : TVar read IntPar write IntPar;
  Property Var_LUE : TVar read LUE write LUE;
  Property Var_LUETempfact : TVar read LUETempfact write LUETempfact;
  Property Var_LUETempf_SWDF: TVar read LUETempf_SWDF write LUETempf_SWDF;
  Property Var_TotTMgRate : TVar read TotTMgRate write TotTMgRate;
  Property Var_TUE_vpd : TVar read TUE_vpd write TUE_vpd;


  // State Variables

  Property St_Qsum : TState read Qsum write Qsum;
  Property St_QsumTempf_SWDF : TState read QsumTempf_SWDF write QsumTempf_SWDF;
  Property St_TotDM : TState read TotDM write TotDM;


  //Parameters

  //Property Par_exkPAR : TPar read exkPAR write exkPAR;
  Property Par_LUE0   : TPar read LUE0 write LUE0;
  Property Par_LUEexp : TPar read LUEexp write LUEexp;
  Property Par_consLUE    : TPar read consLUE write  consLUE;
  Property Par_LUEmax : TPar read LUEmax write LUEmax;
  Property Par_LUEsteig : TPar read LUEsteig write LUEsteig;
  Property Par_TRcrit : TPar read TRcrit write TRcrit;
  Property Par_alpha_TUE : TPar read alpha_TUE write alpha_TUE;
  Property Par_beta_TUE : TPar read beta_TUE write beta_TUE;
  Property Par_SWDF_fact : TPar read SWDF_fact write SWDF_fact;


  //External Variables

  Property Ex_NNI : TExternV read NNI write NNI;
  Property Ex_Temp : TExternV read Temp write Temp;
  Property Ex_Rad_Int : TExternV read Rad_Int write Rad_Int;
  Property Ex_Sat_def : TExternV read Sat_def write Sat_def;
  Property Ex_LAI : TExternV read LAI write LAI;
  Property Ex_XStage : TExternV read XStage write XStage;
  Property Ex_IStage : TExternV read IStage write IStage;
  Property Ex_Tbase6 : TExternV read Tbase6 write Tbase6;
  Property Ex_TransRatio: TExternV read TransRatio write TransRatio;
  Property Ex_ExtPAR_varLAI: TExternV read ExtPAR_varLAI write ExtPAR_varLAI;

  property opt_DMCalcMethod : TDMCalcMethod read fDMCalcMethod write fDMCalcMethod;
  property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;
  property SoilWaterModel : TSoilWaterModelR read fSoilWaterModel write SetSoilWaterMod;
end;  // SubmodelName

procedure Register;

implementation
uses Math, Usubpartitioning_Maize;

Procedure Tsublightint_growth_Maize.SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);
begin
  fSoilWaterModel := SoilWaterMod;
end;

procedure Tsublightint_growth_Maize.createAll;
begin
  inherited createAll;
// Variables
VarCreate('fInt', '[unitless]', 0, true, fInt, 'Fraction of intercepted photosynthetically active radiation (PAR) (not used in model)');
VarCreate('IntPar', '[MJ/m²/d]', 0, true, IntPar, 'Intercepted PAR (daily total)');
VarCreate('LUE', '[g/MJ]', 0, true, LUE, 'Light use efficiency (actual biomass production per unit intercepted PAR)');
VarCreate('LUETempfact', '[g/MJ]', 0, true, LUETempfact, 'Light use efficiency corrected for temperature (without drought stress)');
VarCreate('LUETempf_SWDF', '[g/MJ]', 0, true, LUETempf_SWDF, 'Light use efficiency corrected for temperature and water deficit (effective LUE)');
VarCreate('TUE_vpd', '[g/kg]', 0, true, TUE_vpd, 'Transpiration use efficiency based on vapor pressure deficit (TUE_vpd = alpha * Sat_def^-beta)');
VarCreate('TotTMgRate', '[g/m²/d]', 0, true, TotTMgRate, 'Total dry matter growth rate (actual)');
VarCreate('TotTMgRate_TUE', '[g/m²/d]', 0, true, TotTMgRate_TUE, 'Total dry matter growth rate calculated via TUE');
VarCreate('SWDF', '[unitless]', 0, true, SWDF, 'Soil water deficit factor (1 = no stress, 0 = severe stress)');
VarCreate('Tempfact', '[unitless]', 0, true, Tempfact, 'Temperature factor for growth (0–1, Trapezoidal function)');
VarCreate('Trans_daysGR', '', 0, true, Trans_daysGR, '-');
VarCreate('avg_pot_Trans_GlobRad', '', 0, true, avg_pot_Trans_GlobRad, '-');

// State Variables
StateCreate('Qsum', '[MJ/m²]', 0, true, Qsum, 'Cumulative intercepted PAR (used for external LUE calculation)');
StateCreate('QsumTempf_SWDF', '[MJ/m²]', 0, true, QsumTempf_SWDF, 'Cumulative intercepted PAR corrected for temperature and water stress (used for external LUE calculation)');
StateCreate('TotDM', '[g/m²]', 0, true, TotDM, 'Cumulative total dry matter accumulation');
StateCreate('pot_Trans_GlobRad', '', 0, true, pot_Trans_GlobRad, '');
StateCreate('Trans_days', '', 0, true, Trans_days, '');
StateCreate('cumPAR_Trans_days', '', 0, true, cumPAR_Trans_days, '');

// Parameters
ParCreate('LUE0', '[g/MJ]', 7.5, LUE0, 'Baseline light use efficiency at zero radiation (Ritchie approach), option: exponential LUE');
ParCreate('LUEexp', '[unitless]', 0.6, LUEexp, 'Exponent in light conversion equation (Ritchie approach), option: exponential LUE');
ParCreate('consLUE', '[g/MJ]', 3.6, consLUE, 'Constant light use efficiency (option: constant)');
ParCreate('LUEmax', '[g/MJ]', 15, LUEmax, 'Maximum potential light use efficiency (upper limit), (option: linear LUE)');
ParCreate('LUEsteig', '[unitless]', -0.312, LUEsteig, 'Slope parameter for LUE decline with increasing radiation (option: linear LUE)');
ParCreate('Ct1', '°C', 6, Ct1, 'Minimum cardinal temperature for growth (Ct1)');
ParCreate('Ct2', '°C', 18, Ct2, 'Optimum temperature for growth (Ct2)');
ParCreate('Ct3', '°C', 30, Ct3, 'Maximum temperature for growth (Ct3)');
ParCreate('Ct4', '°C', 34, Ct4, 'Upper lethal temperature (Ct4)');
ParCreate('TRcrit', '', 0.75, TRcrit, '');
ParCreate('alpha_TUE', '', 10.3, alpha_TUE, 'Parameter for TUE_vpd');
ParCreate('beta_TUE', '', 0.42, beta_TUE, 'Parameter for TUE_vpd');
ParCreate('SWDF_fact', '[unitless]', 0.42, SWDF_fact, 'Power factor for nonlinear relationship Transratio and SWDF');

// External Variables
ExternVCreate('Temp', '°C', statefield, Temp, 'Daily mean air temperature');
ExternVCreate('NNI', '[unitless]', statefield, NNI, 'Nitrogen Nutrition Index (NNI = Nactual / Ncritical)');
ExternVCreate('Rad_Int', 'W/m²', statefield, Rad_Int, 'Intercepted radiation (PAR)');
ExternVCreate('LAI', '[m²/m²]', statefield, LAI, 'Leaf Area Index (green, used for light interception)');
ExternVCreate('XStage', '[unitless]', statefield, XStage, 'Development stage (0–5), numeric scale');
ExternVCreate('IStage', '[unitless]', statefield, IStage, 'Integer scaled development stage');
ExternVCreate('Tbase6', '°C', statefield, Tbase6, 'Base temperature for development (Tbase6)');
ExternVCreate('TransRatio', '[unitless]', statefield, TransRatio, 'Ratio of actual to potential transpiration (0–1)');
ExternVCreate('Sat_def', '[kPa]', statefield, Sat_def, 'Saturation deficit (vapor pressure deficit)');
ExternVCreate('ActTrans', '[mm/d]', statefield, ActTrans, 'Actual transpiration rate');
ExternVCreate('ExtPAR_varLAI', '[unitless]', statefield, ExtPAR_varLAI, 'Variable extinction coefficient for PAR (based on LAIgreen)');
ExternVCreate('potTrans', '[mm/d]', statefield, pot_Trans, 'Potential transpiration rate');
ExternVCreate('GlobRad', '[W/m²]', statefield, GlobRad, 'Global radiation (incoming solar radiation)');

  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact, 'Drought impact by activating SWDF');
  optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');

  OptCreate('DMCalcMethod', 'ConstLue', optDMCalcMethod, 'ConstLUE: constant potential LUE; ExpLUE_f_Rad: exponential funciton (Ritchie approach) parameters needed: LUE0,LUEexp; LinLUE_f_R: linear decrease of LUE with increasing radiation uptake (light saturation), parameters needed: LUEmax, LUEsteig');
  optDMCalcMethod.OptionList.Clear;
  optDMCalcMethod.OptionList.Add('ConstLue');
  optDMCalcMethod.OptionList.Add('ExpLUE_f_Rad');
  optDMCalcMethod.OptionList.Add('LinLUE_f_Rad');

end;


procedure Tsublightint_growth_Maize.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  Qsum.v := 0;
  QsumTempf_SWDF.v := 0;
  TotDM.v := 0;
  pot_Trans_GlobRad.v := 0;
  Trans_days.v := 0;
  cumPAR_Trans_days.v := 0;
  //If SWDF_fact.v > 1 then
     //SWDF_fact.v := 1;

  if optDroughtimpact.option = 'droughtimpact' then begin
    fdroughtimpact := DroughtImpact;
    Transratio.Search := true;
  end;
  if optDroughtimpact.option = 'nodroughtimpact' then begin
    fdroughtimpact := noDroughtImpact;
    Transratio.Search := false;
  end;

  if optDMCalcMethod.option = 'constlue' then begin
    fDMCalcMEthod := ConstLue;
  end;
  if optDMCalcMethod.option = 'explue_f_rad' then begin
    fDMCalcMEthod := ExpLUE_f_rad;
  end;
  if optDMCalcMethod.option = 'linlue_f_rad' then begin
    fDMCalcMEthod := LinLUE_f_Rad;
  end;


end;


procedure Tsublightint_growth_Maize.CalcRates;

begin
  If {(SoilWaterModel <> nil) and} (fDroughtImpact = DroughtImpact)
 // then SWDF.v := min(1,TransRatio.v)
     //then SWDF.v :=  min(1,TransRatio.v/TRcrit.v)
     then SWDF.v :=  min(1,1-power((1-TransRatio.v),SWDF_fact.v)) //if SWDF_fact = 1, then it equals the linear relationship SWDF.v :=  min(1,TransRatio.v/TRcrit.v) ; Reference: Ferreyra et al. 2003
     //then SWDF.v :=  min(1,1-sqr(power(TransRatio.v,SWDF_fact.v)-1))
     else SWDF.v :=  1;
     {If (SoilWaterModel <> nil) and (fDroughtImpact = DroughtImpact)
     then SWDF.v :=  min(1,1-sqr(power(TransRatio.v,SWDF_fact.v)-1))
     else SWDF.v :=  1;
     If (SoilWaterModel <> nil) and (fDroughtImpact = DroughtImpact) and (IStage.v = 3)
     then  SWDF.v :=  min(1,TransRatio.v/TRcrit.v); }

   //fInt.v :=  1-exp(-exkPAR.v*LAI.v);
   fInt.v :=  1-exp(-ExtPAR_varLAI.v*LAI.v);
   //IntPar.v :=   0.5*86400*Rad_Int.v/1000000*(1-exp(-exkPAR.v*LAI.v));
   IntPar.v :=   0.5*86400*Rad_Int.v/1000000*(1-exp(-ExtPAR_varLAI.v*LAI.v));

   If fDMCalcMethod = ExpLUE_f_Rad then LUE.v := LUE0.v*exp(0.5*86400*Rad_Int.v/1000000*LUEexp.v);
   If fDMCalcMethod = LinLUE_f_Rad then LUE.v :=  max(0,LUEsteig.v*0.5*86400*Rad_Int.v/1000000+LUEmax.v);
   If fDMCalcMethod = ConstLUE then LUE.v := consLUE.v;
   If Sat_def.v>0 then TUE_vpd.v := alpha_TUE.v*power(Sat_def.v,-beta_TUE.v)
   else TUE_vpd.v := 1000000;
   If Temp.v < Tbase6.v
      then Tempfact.v := 0
      else If temp.v <= Ct2.v
           then Tempfact.v := (temp.v-Tbase6.v)/(Ct2.v-Tbase6.v)
           else if temp.v <= Ct3.v
                then Tempfact.v := 1
                else if temp.v <= Ct4.v
                     then Tempfact.v := (Ct4.v-temp.V)/(Ct4.v-Ct3.v)
                     else Tempfact.v := 0;
   LUETempfact.v := LUE.v*Tempfact.v;
   LUETempf_SWDF.v := LUE.v*Tempfact.v*SWDF.v;
   TotTMgRate.v := IntPar.v* LUE.v*Tempfact.v* SWDF.v*NNI.v;
   TotTMgRate_TUE.v := TUE_vpd.v*ActTrans.v*NNI.v;
   //If LAI.v>1 then
   //TotTMgRate.v := min(TotTMgRate.v, TotTMgRate_TUE.v);
   //TotTMgRate.v := min(IntPar.v* LUE.v*Tempfact.v*SWDF.v,TUE_vpd.v*ActTrans.v);
   If  XStage.v>=1
       then  QsumTempf_SWDF.c := IntPar.v*Tempfact.v*SWDF.v
       else  QsumTempf_SWDF.c := 0;
   If  XStage.v>=1
       then  Qsum.c := IntPar.v
       else  Qsum.c := 0;
   TotDM.c := TotTMgRate.v;
   pot_Trans_GlobRad.c := pot_Trans.v / GlobRad.v;
   Trans_daysGR.v := 1;
   If  fInt.v >0
       then Trans_days.c := Trans_daysGR.v
       else Trans_days.c := 0;
   If  Trans_days.v>=1
       then avg_pot_Trans_GlobRad.v  := pot_Trans_GlobRad.v/Trans_days.v;
   If  fInt.v >0
       then cumPAR_Trans_days.c := GlobRad.v * 0.5
       else cumPAR_Trans_days.c := 0;

end;




procedure Register;
begin
  RegisterComponents('Maize', [Tsublightint_growth_Maize]);
end;

end.
