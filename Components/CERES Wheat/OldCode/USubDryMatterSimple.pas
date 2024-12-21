unit USubDryMatterSimple;

// simplified version of the dry matter production module for parameterisation

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls,
  vcl.Forms, vcl.Dialogs, UMod, UState,
  URootedSoil;

Type


TDMCalcMethod = (Ritchie, ConstLue, LUE_f_Rad);

TDroughtImpact = (DroughtImpact, NoDroughtImpact);

TsubdrymatterSimple = class(TSubmodel)

private
  fDMCalcMethod : TDMCalcMethod;
  fDroughtImpact : TDroughtImpact;
  fSoilWaterModel : TSoilWaterModelR;
  Procedure SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);

protected

public
  CARBO     : TVar;   // The daily biomass production [g/(plant*d)]
  CARBOred  : TVar;   // Reduction factor for assimilation during ripening [0..1]
  fINT      : TVar;   // fractional Interception of PAR
  IPAR      : TVar;   // intercepted photosynthetically active radiation [MJ/(m2*d)]
  LUE       : TVar;   // Light use efficiency [g/MJ]
  PAR       : TVar;   // Photosynthetic active radiation [MJ/(m2*d]
  PCARB     : TVar;   // Potential biomass production in [g/(m2*d)]
  PRFT      : TVar;   // Photosynthetic reduction factor for low and high temperatures [0..1]
  SWDF1     : TVar;   // Soil Water Deficit Factor [0..1]
  TempF     : TVar;   // Temperature Factor
  kPar_eff  : TVar;   // effective  Extinction coefficient


  CumCarbo : TState;
  CumPAR   : TState;     // cumulative PAR uptake [MJ/m2]
  CumPARcorr   : TState;     // cumulative PAR uptake corrected for stress (temperature, drougth) [MJ/m2]
  TSumEC50: TState;       // Temperature Sum from EC 50 [°C d]
  RSumEC50: TState;       // Glob Rad Sum from EC 50 [MJ/m2]
  RSumEC50Drought: TState; // Glob Rad Sum from EC 50 with drought stress factor [MJ/m2]

// Constant Variables

// Parameters
  kPAR : TPar;   // Extinction coefficient for PAR

  k_max : TPar;   // Extinction coefficient parameter for PAR
  k_k : TPar;   // Extinction coefficient parameter for PAR


  LUE0 : TPar;   // Light use efficiency at zero radiation according to Ritchie's approach
  LUEexp : TPar;   // Exponent of light conversion equation according to Ritchie's approach

  pLUE   : TPar;   // light use efficiency assuming constant LUE

  pLUE0_d: TPar;   // maximum light use efficiency for a LUE decreasing with incr. radiation
  pLUEdec: TPar;   // decrrease of LUE with radiation

  Tmin : TPar;    // minimum temperature for assimilation
  Topt1 : Tpar;   // temperature where optimum range for assimilation begins
  Topt2 : TPar;   // temperature where optimum range for assimilation ends
  Tmax : Tpar;    // minimum temperature for assimilation


// External Variables
  STMWT_pl : TExternV;   //  Stem weight of an average tiller after terminal spikelet  [g]
//  SWMIN: TExternV;
  XSTAGE : TExternV; //   Development stage according do CERES
  P5 : TExternV; //duration of grain filling in degree-days
//  DTT : TExternV; //daily thermal time, ratjen 06.01.09
  GlobRad : TExternV;   //   global radiation [MJ/m2/d]
  LAI     : TExternV;   //   leaf area index
  TMPMN   : TExternV;  //         Minimum air temperature [°C]
  TMPM   : TExternV;
  TMPMX   : TExternV;   //         Maximum air temperature [°C]
  Plants  : TExternV;   //        number of Plants/m2 []
  EC      : TExternV;   // ec stage of crop
  
  TransRatio : TExternV;   // Ratio actual to potential transpiration [-]

  OptDroughtimpact : Toption;
  OptDMCalcMethod  : TOption;

  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  Property Var_CARBO : TVar read CARBO write CARBO;
  Property Var_CARBOred : TVar read CARBOred write CARBOred;
  Property Var_fINT : TVar read fINT write fINT;
  Property Var_IPAR : TVar read IPAR write IPAR;
  Property Var_LUE : TVar read LUE write LUE;
  Property Var_PAR : TVar read PAR write PAR;
  Property Var_PCARB : TVar read PCARB write PCARB;
  Property Var_PRFT : TVar read PRFT write PRFT;
  Property Var_SWDF1 : TVar read SWDF1 write SWDF1;


//  Property Var_TestCarbo : TVar read TestCarbo write TestCarbo;
//  Property Var_TestCarbo2 : TVar read TestCarbo2 write TestCarbo2;

  property St_CumCarbo : TState read CumCarbo write CumCarbo;

         // Parameters
  Property Par_kPAR   : TPar read kPAR write kPAR;
  Property Par_k_max   : TPar read k_max write k_max;
  Property Par_k_k   : TPar read k_k write k_k;

  Property Par_LUE0   : TPar read LUE0 write LUE0;
  Property Par_LUEexp : TPar read LUEexp write LUEexp;

  Property Par_pLUE    : TPar read pLUE write  pLUE;
  Property Par_pLUE0_d   : TPar read pLUE0_d write pLUE0_d;
  Property Par_pLUEdec : TPar read pLUEdec write pLUEdec;


         // External Variable
  Property Ex_GlobRad : TExternV read GlobRad write GlobRad;
  Property Ex_LAI     : TExternV read LAI write LAI;
  Property Ex_TMPM   : TExternV read TMPM write TMPM;
  Property Ex_TMPMN   : TExternV read TMPMN write TMPMN;
  Property Ex_TMPMX   : TExternV read TMPMX write TMPMX;
  property Ex_TransRatio: TExternV read TransRatio write TransRatio;
  property Ex_STMWT_pl: TExternV read STMWT_pl write STMWT_pl;
  property Ex_Plants: TExternV read Plants write Plants;
  property opt_DMCalcMethod : TDMCalcMethod read fDMCalcMethod write fDMCalcMethod;
  property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;
  property SoilWaterModel : TSoilWaterModelR read fSoilWaterModel write SetSoilWaterMod;


end;  // SubmodelName

procedure Register;

implementation

uses math, UModUtils;

Procedure TSubDryMatterSimple.SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);

begin
  fSoilWaterModel := SoilWaterMod;

end;


procedure TSubDryMatterSimple.createAll;

begin
  inherited createAll;
  VarCreate('CARBO', '[g/(plant*d)]',0, true, CARBO);
  VarCreate('CARBOred', '[0..1]',0, true, CARBOred);
  VarCreate('fINT', '[0..1]',0, true, fINT);
  VarCreate('IPAR', '[MJ/(m2*d)]',0, true, IPAR);
  VarCreate('LUE', '[g/MJ]',0, true, LUE);
  VarCreate('PAR', '[MJ/(m2*d]',0, true, PAR);
  VarCreate('PCARB', '[g/(m2*d)]',0, true, PCARB);
  VarCreate('PRFT', '[0..1]',0, true, PRFT);
  VarCreate('Temp_f', '[0..1]',0, true, Tempf);
  VarCreate('kPar_eff', '[0..1]',0, true, kPar_eff);


//  VarCreate('TestCarbo', '',0, true, TestCarbo);
//  VarCreate('TestCarbo2', '',0, true, TestCarbo2);

  StateCreate('CumCarbo', '[g/m2]', 0, true, CumCarbo);
  StateCreate('CumPAR', '[MJ/m2]', 0, true, CumPAR);
  StateCreate('CumPARcorr', '[MJ/m2]', 0, true, CumPARcorr);
  StateCreate('TSumEC50', '[°C d]', 0, true, TSumEC50);  // Temperature Sum from EC 50 [°C d]
  StateCreate('RSumEC50', '[MJ/m2]', 0, true, RSumEC50); // Glob Rad Sum from EC 50 [MJ/m2]
  StateCreate('RSumEC50Drought', '[MJ/m2]', 0, true, RSumEC50Drought); // Glob Rad Sum from EC 50 with drought stress factor [MJ/m2]

  // Parameters
  ParCreate('kPAR', '[-]',0.7, kPAR);
  ParCreate('k_max', '[-]',6, k_max);
  ParCreate('k_k', '[-]',5, k_k);

  ParCreate('LUE0', '[g/MJ]',7.5, LUE0);
  ParCreate('LUEexp', '[-]',0.6, LUEexp);

  ParCreate('pLUE', '[g/MJ]',   3,  pLUE);
  ParCreate('pLUE0_d', '[g/MJ]', 6,  pLUE0_d);
  ParCreate('pLUEdec', '[-]',  0.3, pLUEdec);

  ParCreate('Tmin', '[°C]',  0.0, Tmin);
  ParCreate('Topt1', '[°C]',  10.0, Topt1);
  ParCreate('Topt2', '[°C]',  20.0, Topt2);
  ParCreate('Tmax', '[°C]',  35.0, Tmax);




         // External Variable
  ExternVCreate('STMWT_pl', '',statefield, STMWT_pl);
  ExternVCreate('XSTAGE', '',statefield, XSTAGE);
//  ExternVCreate('SWMIN', '', statefield, SWMIN);
  ExternVCreate('P5', '', statefield, P5);
  ExternVCreate('GlobRad', '', statefield, GlobRad);
  ExternVCreate('LAI',  '', statefield, LAI);
  ExternVCreate('TMPMN', '', statefield, TMPMN);
  ExternVCreate('TMPM', '', statefield, TMPM);
  ExternVCreate('TMPMX', '', statefield, TMPMX);
  ExternVCreate('Plants', '', statefield, Plants);
  ExternVCreate('EC', '',statefield, EC);
//  ExternVCreate('DTT', '',statefield, DTT);
  ExternVCreate('TransRatio', '[-]', Statefield, TransRatio);
  VarCreate('SWDF1', '[0..1]',0, true, SWDF1);
  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
  optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');

  OptCreate('DMCalcMethod', 'ConstLue', optDMCalcMethod);
  optDMCalcMethod.OptionList.Clear;
  optDMCalcMethod.OptionList.Add('ConstLue');
  optDMCalcMethod.OptionList.Add('Ritchie');
  optDMCalcMethod.OptionList.Add('LUE_f_Rad');


end;


procedure TSubDryMatterSimple.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
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
  if optDMCalcMethod.option = 'ritchie' then begin
    fDMCalcMEthod := Ritchie;
  end;
  if optDMCalcMethod.option = 'lue_f_rad' then begin
    fDMCalcMEthod := LUE_f_Rad;
  end;


end;


procedure TSubDryMatterSimple.CalcRates;

const
  PotTransOld : real = 0.0;

{var
   tmpm : real;}

begin

  // tmpm  :=  0.25*TMPMN.v+0.75*TMPMX.v;

   PAR.v :=  0.5*GlobRad.v;
   kpar_eff.v := kPAR.v; //+(k_max.v-kPAR.v)*EXP(-k_k.v*LAI.v);
   fInt.v := (1 - EXP(-kPAR_eff.v * LAI.v));

   IPAR.v :=  PAR.v*fint.v;
   CumPAR.c := IPAR.v;


   If (SoilWaterModel <> nil) and (fDroughtImpact = DroughtImpact)
    then SWDF1.v :=  TransRatio.v
    else SWDF1.v :=  1;



   If fDMCalcMethod = Ritchie then begin
     If  ipar.v>0
       then begin
          PRFT.v :=   max(0,1 - 0.0025 * sqr((0.25*TMPMN.v+0.75*TMPMX.v) - 16));    //
          PCARB.v := LUE0.v*Power(PAR.v,LUEexp.v)*fint.v*PRFT.v
        end
     else  begin
       PCARB.v := 0  ;
     end;
   end;

   If fDMCalcMethod = ConstLUE then begin
     If  ipar.v>0
       then begin
         Tempf.v := trapez_f (tmpm.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
         PCARB.v := pLUE.v*PAR.v*fint.v*TEmpf.v;

       end
     else  PCARB.v := 0  ;
   end;

   If fDMCalcMethod = LUE_f_rad then begin
     If  ipar.v>0
       then begin
        Tempf.v := trapez_f (tmpm.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
        PCARB.v := (pLUE0_d.v-pLUEdec.v*PAR.v)*PAR.v*fint.v;
       end
     else  PCARB.v := 0;
   end;

  PCARB.v := PCARB.v * SWDF1.v;  // soil water deficit factor correction

  If Plants.v > 0 then CARBO.v := PCARB.v/Plants.v;
  cumCarbo.c := PCarb.v;
  If EC.v > 50 then begin
    TSumEC50.c := tmpm.v;
    RSumEC50.C := GlobRad.V;
    RSumEC50Drought.c := GlobRad.V * TransRatio.v;
  end;
  CumPARcorr.c := IPAR.v*Tempf.v*Transratio.v;


end;


procedure TSubDryMatterSimple.Integrate;

begin
  inherited integrate;
   If  IPAR.v>0 then
     LUE.v :=   PCARB.v/IPAR.v
   else  LUE.v :=   0;

end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TsubdrymatterSimple]);
end;

end.

