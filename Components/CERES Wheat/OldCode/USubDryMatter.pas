unit USubDryMatter;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls,
   vcl.Forms, vcl.Dialogs, UMod, UState;

Type

TDMCalcMethod = (Ritchie, ConstLue, LUE_f_Rad);

TDroughtImpact = (DroughtImpact, NoDroughtImpact);

Tsubdrymatter = class(TSubmodel)

private

  fDMCalcMethod : TDMCalcMethod;
  fDroughtImpact : TDroughtImpact;

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
  TestCarbo : TVar;   //
  TestCarbo2 : TVar;   //

  CumCarbo : TState;

// Constant Variables

// Parameters
  kPAR : TPar;   // Extinction coefficient for PAR
  LUE0 : TPar;   // Light use efficiency at zero radiation according to Ritchie's approach
  LUEexp : TPar;   // Exponent of light conversion equation according to Ritchie's approach

  pLUE   : TPar;   // light use efficiency assuming constant LUE

  pLUE0_d: TPar;   // maximum light use efficiency for a LUE decreasing with incr. radiation
  pLUEdec: TPar;   // decrrease of LUE with radiation


// External Variables
  GlobRad : TExternV;   //   global radiation [MJ/m2/d]
  ISTAGE  : TExternV;   //   developmental stage according to CERES
  LAI     : TExternV;   //   leaf area index
  NDEF1   : TExternV;   //   nitrogen deficit factor
  p5      : TExternV;   //
  plants  : TExternV;   //   plants/m2
  stmwt   : TExternV;   //   stem weight [g/plant]
  sumdtt5 : TExternV;   //
  SWMIN   : TExternV;   //
  TMPMN   : TExternV;   //         Minimum air temperature [°C]
  TMPMX   : TExternV;   //         Maximum air temperature [°C]
  TransRatio : TExternV;   // Ratio actual to potential transpiration [-]

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
  Property Var_TestCarbo : TVar read TestCarbo write TestCarbo;
  Property Var_TestCarbo2 : TVar read TestCarbo2 write TestCarbo2;

  property St_CumCarbo : TState read CumCarbo write CumCarbo;



         // Parameters
  Property Par_kPAR   : TPar read kPAR write kPAR;
  Property Par_LUE0   : TPar read LUE0 write LUE0;
  Property Par_LUEexp : TPar read LUEexp write LUEexp;

  Property Par_pLUE    : TPar read pLUE write  pLUE;
  Property Par_pLUE0_d   : TPar read pLUE0_d write pLUE0_d;
  Property Par_pLUEdec : TPar read pLUEdec write pLUEdec;


         // External Variable
  Property Ex_GlobRad : TExternV read GlobRad write GlobRad;
  Property Ex_ISTAGE  : TExternV read ISTAGE write ISTAGE;
  Property Ex_LAI     : TExternV read LAI write LAI;
  Property Ex_NDEF1   : TExternV read NDEF1 write NDEF1;
  Property Ex_p5      : TExternV read p5 write p5;
  Property Ex_plants  : TExternV read plants write plants;
  Property Ex_stmwt   : TExternV read stmwt write stmwt;
  Property Ex_sumdtt5 : TExternV read sumdtt5 write sumdtt5;
  Property Ex_SWMIN   : TExternV read SWMIN write SWMIN;
  Property Ex_TMPMN   : TExternV read TMPMN write TMPMN;
  Property Ex_TMPMX   : TExternV read TMPMX write TMPMX;
  property Ex_TransRatio: TExternV read TransRatio write TransRatio;
  property opt_DMCalcMethod : TDMCalcMethod read fDMCalcMethod write fDMCalcMethod;
  property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;

end;  // SubmodelName

procedure Register;

implementation

uses math;

procedure Tsubdrymatter.createAll;

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
  VarCreate('SWDF1', '[0..1]',0, true, SWDF1);
  VarCreate('TestCarbo', '',0, true, TestCarbo);
  VarCreate('TestCarbo2', '',0, true, TestCarbo2);

  StateCreate('CumCarbo', '[g/m2]', 0, true, CumCarbo);

  // Parameters
  ParCreate('kPAR', '[-]',0.85, kPAR);
  ParCreate('LUE0', '[g/MJ]',7.5, LUE0);
  ParCreate('LUEexp', '[-]',0.6, LUEexp);

  ParCreate('pLUE', '[g/MJ]',   3,  pLUE);
  ParCreate('pLUE0_d', '[g/MJ]', 6,  pLUE0_d);
  ParCreate('pLUEdec', '[-]',  0.3, pLUEdec);


         // External Variable
  ExternVCreate('GlobRad', '', statefield, GlobRad);
  ExternVCreate('ISTAGE', '', statefield, ISTAGE);
  ExternVCreate('LAI',  '', statefield, LAI);
  ExternVCreate('NDEF1', '', statefield, NDEF1);
  ExternVCreate('p5', '', statefield, p5);
  ExternVCreate('plants', '', statefield, plants);
  ExternVCreate('stmwt', '', statefield, stmwt);
  ExternVCreate('sumdtt5', '', statefield, sumdtt5);
  ExternVCreate('SWMIN', '', statefield, SWMIN);
  ExternVCreate('TMPMN', '', statefield, TMPMN);
  ExternVCreate('TMPMX', '', statefield, TMPMX);
  ExternVCreate('TransRatio', '[mm]', Statefield, TransRatio);
end;


procedure Tsubdrymatter.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);


end;


procedure Tsubdrymatter.CalcRates;

const
  PotTransOld : real = 0.0;

var
  tmpm : real;

begin

   tmpm  :=  0.25*TMPMN.v+0.75*TMPMX.v;
   PAR.v :=  0.5*GlobRad.v;
   fInt.v := (1 - EXP(-kPAR.v * LAI.v));

   IPAR.v :=  PAR.v*fint.v;

   PRFT.v :=   max(0,1 - 0.0025 * sqr((0.25*TMPMN.v+0.75*TMPMX.v) - 16));

   If fDroughtImpact = DroughtImpact then
     SWDF1.v :=  TransRatio.v
   else
     SWDF1.v :=  1;

// The rate of photosynthesis as influenced by aging of the leaves
// and sink assimilate demand is approximated using an equation that reduces
// the original calculated value of CARBO
// CARBO = CARBO * (1 - (1.2 - 0.8 * SWMIN/STMWT)* (SUMDTT + 100)/(P5 + 100)),
// where P5 is the duration of grain filling in degree-days.
// The leaf aging affect is determined by the (SUMDTT + 100)/(P5 + 100) ratio
// in the equation and the sink demand is inferred indirectly through the SWMIN/STMWT ratio

   If  (ISTAGE.v>=5)and(ISTAGE.v<6)and(stmwt.v>0)
     then  CARBOred.v :=  1// max(0,(1.-(1.2-0.8*SWMIN.v/stmwt.v)*(sumdtt5.v+100.0)/((430+p5.v*20)+100.0)))
   else  CARBOred.v :=   1  ;

   If fDMCalcMethod = Ritchie then begin
     If  ipar.v>0
       then  PCARB.v := LUE0.v*Power(PAR.v,LUEexp.v)*fint.v
     else  PCARB.v := 0  ;
   end;

   If fDMCalcMethod = ConstLUE then begin
     If  ipar.v>0
       then  PCARB.v := pLUE.v*PAR.v*fint.v
     else  PCARB.v := 0  ;
   end;

   If fDMCalcMethod = LUE_f_rad then begin
     If  ipar.v>0
       then  PCARB.v := (pLUE0_d.v-pLUEdec.v*PAR.v)*PAR.v*fint.v
     else  PCARB.v := 0;
   end;

   If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  CARBO.v := max(0.001,CarboRed.v*PCARB.v*MIN(SWDF1.v, NDEF1.v)*prft.v)/plants.v
   else  If  (ISTAGE.v>=1)and(ISTAGE.v<5)
     then  CARBO.v := max(0.001,PCARB.v*MIN(SWDF1.v, NDEF1.v)*prft.v)/plants.v
   else  CARBO.v := 0;

   cumCarbo.c := Carbo.v*plants.v;


   If  stmwt.v>0
    then  TestCarbo.v :=   1.-(1.2-0.8*swmin.v/stmwt.v)
   else  TestCarbo.v :=   1  ;

   TestCarbo2.v :=  1-(sumdtt5.v+100.0)/((430+p5.v*20)+100.0);

end;


procedure Tsubdrymatter.Integrate;

begin
  inherited integrate;
   If  IPAR.v>0 then
     LUE.v :=   PCARB.v/IPAR.v
   else  LUE.v :=   0  ;
end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Tsubdrymatter]);
end;

end.

