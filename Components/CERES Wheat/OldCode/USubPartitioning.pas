unit USubPartitioning;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics,
   vcl.Controls, vcl.Forms, vcl.Dialogs,
   UMod, UState;

Type

Tsubpartitioning = class(TSubmodel)

private

protected

public
  DLFWT : TVar;   //
  EXLFW : TVar;   // old leaf weight from previous day [g/plant]
  GPP : TVar;     //   Number of grains per plant  [n]
  GPPvar : TVar;   //   Number of grains per plant  [g/plant]
  GPSM : TVar;     // Grains per square meter [g/m2]
  GRNWT_m2 : TVar;   // Grain weight per square meter [g/m2]
  GROGRN : TVar;     // Daily growth of the grain - [g/(plant.d)]
  GROLF : TVar;      // Daily leaf growth [g/plant/d]
  GRORT : TVar;      // Daily root growth - [g/pl/d]
  GROSTM : TVar;     // Daily stem growth  [g/(plant.d]
  LFWT_m2 : TVar;    // leaf weight per square meter [g/m2]
  PTF : TVar;        // Fraction of photosynthesis partitioned to above ground plant parts [-]
  RGFILL : TVar;     // Rate of grain fill  [mg/(plant*day)]
  RTWT_m2 : TVar;    // root weight per square meter [g/m2]
  SENL : TVar;       // Leaf senscence rate [g/(plant.d]
  SENRT : TVar;   //
  SENSTM : TVar;   // Senescent stem mass [g/plant]
  STMWT_m2 : TVar;   // Stem weight per square meter [g/m2]
  TKM : TVar;   // Thausend kernel mass [g]
  TOPWT : TVar;   // weight of tops without grains [g/plant]
  TOPWT_m2 : TVar;   //


  // Constant Variables
  G1 : TVar;   // Unscaled version of the Genetic specific constant related to rate of vegetative expansion growth during Stage 1
  G2 : TVar;   // Unscaled genetic specific constant related to the number of grains produced
  G3 : TVar;   // Unscaled Genetic coefficient for determining grain fill rate [mg/day]
  P2 : TVar;   // Thermal time between terminal spikelet and end of vegetative growth, equal to 3 phyllochron intervals [degree C days]
  P3 : TVar;   // Thermal time from terminal spikeltt end of pre-anthesis ear elongation growth, equal to 2 phyllochron intervals - degree C days

  CUMPH : TState;   // cumulative phyllochrons since emergence [-]
  GPPend : TState;   //
  GRNWT : TState;   // Weight of grains [g/plant]
  LFWT : TState;   // Leaf weight of all leaves on a plant [g/plant]
  RTWT : TState;   //   Root weight - [g/plant]
  SEEDRV : TState;   // Reserve carbohydrates in seed for use by plant in seedling stage [g/plant]
  SENLF : TState;   // Senescent leaf weight [g/plant]
  STMWT : TState;   //  Stem weight of an average tiller after terminal spikelet  [g]
  SWMIN : TState;   //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]

             // Parameters
  G1_ : TPar;   // Genetic specific constant related to rate of vegetative expansion growth during Stage 1
  G2_ : TPar;   // Genetic specific constant related to rate of vegetative expansion growth during Stage 1
  G3_ : TPar;   // Genetic coefficient for determining grain fill rate
  Plants : TPar;   //

             // External Variables
  AWR : TExternV;   //
  CARBO : TExternV;   //
  DTT : TExternV;   //
  ISTAGE : TExternV;   //
  ndef2 : TExternV;   //
  PHINT : TExternV;   // 
  PLA : TExternV;   // 
  PLAGMS : TExternV;   // 
  SENLA : TExternV;   //
  SUMDTT2 : TExternV;   //
  swdf1 : TExternV;   // 
  TEMPM : TExternV;   //
  tempmn : TExternV;   //
  tempmx : TExternV;   // 
  TI : TExternV;   //
  TILN : TExternV;   // 


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;

published
  Property Var_DLFWT : TVar read DLFWT write DLFWT;
  Property Var_EXLFW : TVar read EXLFW write EXLFW;
  Property Var_GPP : TVar read GPP write GPP;
  Property Var_GPPvar : TVar read GPPvar write GPPvar;
  Property Var_GPSM : TVar read GPSM write GPSM;
  Property Var_GRNWT_m2 : TVar read GRNWT_m2 write GRNWT_m2;
  Property Var_GROGRN : TVar read GROGRN write GROGRN;
  Property Var_GROLF : TVar read GROLF write GROLF;
  Property Var_GRORT : TVar read GRORT write GRORT;
  Property Var_GROSTM : TVar read GROSTM write GROSTM;
  Property Var_LFWT_m2 : TVar read LFWT_m2 write LFWT_m2;
  Property Var_PTF : TVar read PTF write PTF;
  Property Var_RGFILL : TVar read RGFILL write RGFILL;
  Property Var_RTWT_m2 : TVar read RTWT_m2 write RTWT_m2;
  Property Var_SENL : TVar read SENL write SENL;
  Property Var_SENRT : TVar read SENRT write SENRT;
  Property Var_SENSTM : TVar read SENSTM write SENSTM;
  Property Var_STMWT_m2 : TVar read STMWT_m2 write STMWT_m2;
  Property Var_TKM : TVar read TKM write TKM;
  Property Var_TOPWT : TVar read TOPWT write TOPWT;
  Property Var_TOPWT_m2 : TVar read TOPWT_m2 write TOPWT_m2;

  Property St_CUMPH : TState read CUMPH write CUMPH;
  Property St_GPPend : TState read GPPend write GPPend;
  Property St_GRNWT : TState read GRNWT write GRNWT;
  Property St_LFWT : TState read LFWT write LFWT;
  Property St_RTWT : TState read RTWT write RTWT;
  Property St_SEEDRV : TState read SEEDRV write SEEDRV;
  Property St_SENLF : TState read SENLF write SENLF;
  Property St_STMWT : TState read STMWT write STMWT;
  Property St_SWMIN : TState read SWMIN write SWMIN;


         // Parameters
  Property Par_G1_ : TPar read G1_ write G1_;
  Property Par_G2_ : TPar read G2_ write G2_;
  Property Par_G3_ : TPar read G3_ write G3_;
  Property Par_Plants : TPar read Plants write Plants;

         // Properties External Variables
  Property Ex_AWR : TExternV read AWR write AWR;
  Property Ex_CARBO : TExternV read CARBO write CARBO;
  Property Ex_DTT : TExternV read DTT write DTT;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
  Property Ex_PHINT : TExternV read PHINT write PHINT;
  Property Ex_PLA : TExternV read PLA write PLA;
  Property Ex_PLAGMS : TExternV read PLAGMS write PLAGMS;
  Property Ex_SENLA : TExternV read SENLA write SENLA;
  Property Ex_SUMDTT2 : TExternV read SUMDTT2 write SUMDTT2;
  Property Ex_swdf1 : TExternV read swdf1 write swdf1;
  Property Ex_TEMPM : TExternV read TEMPM write TEMPM;
  Property Ex_tempmn : TExternV read tempmn write tempmn;
  Property Ex_tempmx : TExternV read tempmx write tempmx;
  Property Ex_TI : TExternV read TI write TI;
  Property Ex_TILN : TExternV read TILN write TILN;


end;  // SubmodelName

procedure Register;

implementation

uses math;

procedure Tsubpartitioning.createAll;

begin
  inherited createAll;
  VarCreate('DLFWT', '',0, true, DLFWT);
  VarCreate('EXLFW', '',0, true, EXLFW);
  VarCreate('GPP', '[n]',0, true, GPP);
  VarCreate('GPPvar', '[g/plant]',0, true, GPPvar);
  VarCreate('GPSM', '[g/m2]',0, true, GPSM);
  VarCreate('GRNWT_m2', '[g/m2]',0, true, GRNWT_m2);
  VarCreate('GROGRN', '[g/(plant.d)]',0, true, GROGRN);
  VarCreate('GROLF', '[g/plant/d]',0, true, GROLF);
  VarCreate('GRORT', '[g/pl/d]',0, true, GRORT);
  VarCreate('GROSTM', '[g/(plant.d]',0, true, GROSTM);
  VarCreate('LFWT_m2', '[g/m2]',0, true, LFWT_m2);
  VarCreate('PTF', '[-]',0, true, PTF);
  VarCreate('RGFILL', '[mg/(plant*day)]',0, true, RGFILL);
  VarCreate('RTWT_m2', '[g/m2]',0, true, RTWT_m2);
  VarCreate('SENL', '[g/(plant.d]',0, true, SENL);
  VarCreate('SENRT', '',0, true, SENRT);
  VarCreate('SENSTM', '[g/plant]',0, true, SENSTM);
  VarCreate('STMWT_m2', '[g/m2]',0, true, STMWT_m2);
  VarCreate('TKM', '[g]',0, true, TKM);
  VarCreate('TOPWT', '[g/plant]',0, true, TOPWT);
  VarCreate('TOPWT_m2', '',0, true, TOPWT_m2);

  VarCreate('G1', '',0, true, G1);
  VarCreate('G2', '',0, true, G2);
  VarCreate('G3', '',0, true, G3);
  VarCreate('P2', '',0, true, P2);
  VarCreate('P3', '',0, true, P3);

  StateCreate('CUMPH', '[-]',0, true,CUMPH);
  StateCreate('GPPend', '',0, true,GPPend);
  StateCreate('GRNWT', '[g/plant]',0, true,GRNWT);
  StateCreate('LFWT', '[g/plant]',0, true,LFWT);
  StateCreate('RTWT', '[g/plant]',0, true,RTWT);
  StateCreate('SEEDRV', '[g/plant]',0, true,SEEDRV);
  StateCreate('SENLF', '[g/plant]',0, true,SENLF);
  StateCreate('STMWT', '[g]',0, true,STMWT);
  StateCreate('SWMIN', '[g/plant]',0, true,SWMIN);


  // Parameters
  ParCreate('G1_', '[-]',6, G1_);
  ParCreate('G2_', '[-]',3.3, G2_);
  ParCreate('G3_', '[mg/day]',4.5, G3_);
  ParCreate('Plants', '[plants/m2]',350, Plants);

         // External Variable
  ExternVCreate('AWR', '',statefield, AWR);
  ExternVCreate('CARBO', '',statefield, CARBO);
  ExternVCreate('DTT', '',statefield, DTT);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('ndef2', '',statefield, ndef2);
  ExternVCreate('PHINT', '',statefield, PHINT);
  ExternVCreate('PLA', '',statefield, PLA);
  ExternVCreate('PLAGMS', '',statefield, PLAGMS);
  ExternVCreate('SENLA', '',statefield, SENLA);
  ExternVCreate('SUMDTT2', '',statefield, SUMDTT2);
  ExternVCreate('swdf1', '',statefield, swdf1);
  ExternVCreate('TEMPM', '',statefield, TEMPM);
  ExternVCreate('tempmn', '',statefield, tempmn);
  ExternVCreate('tempmx', '',statefield, tempmx);
  ExternVCreate('TI', '',statefield, TI);
  ExternVCreate('TILN', '',statefield, TILN);
end;


procedure Tsubpartitioning.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  CUMPH.v := 0;
  GPPend.v := 0;
  GRNWT.v := 0;
  LFWT.v := 0;
  RTWT.v := 0;
  SEEDRV.v := 0;
  SENLF.v := 0;
  STMWT.v := 0;
  SWMIN.v := 0;

  G1.v :=  5.+G1_.v*5.;
  G2.v :=  0.65+G2_.v*0.35;
  G3.v :=  -0.005+G3_.v*0.35;
  P2.v :=  PHINT.v*3;
  P3.v :=  PHINT.v*2;

end;


procedure Tsubpartitioning.CalcRates;

begin

   If  (ISTAGE.v>=1)and (ISTAGE.v<2) then
     CUMPH.c :=  dtt.v/PHINT.v
   else  CUMPH.c :=   0  ;

   DLFWT.v :=  (EXLFW.v-LFWT.v)*PLANTS.v;

   GPP.v :=   max(GPPend.v, GPPvar.v)  ;

   GPPvar.v :=  STMWT.v*G1.v;

   GPSM.v :=  GPP.v*PLANTS.v;

   If  (ISTAGE.v<6) and (ISTAGE.v>=5) and (stmwt.v>0.0)
     then  PTF.v :=   min(1,SWMIN.v/STMWT.v*0.35+0.65)
   else  If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  PTF.v :=   0.8+0.1*min(swdf1.v,ndef2.v)
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  PTF.v :=   0.75+0.1*min(swdf1.v,ndef2.v)
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  PTF.v :=   0.70+0.1*min(swdf1.v,ndef2.v)
   else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  PTF.v :=   0.5
   else  PTF.v :=   0.0  ;

   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then
       if AWR.v > 0
     then  GROLF.v :=   min((PLAGMS.v*(0.3+0.7*TILN.v))/AWR.v, CARBO.v*0.65+SEEDRV.v)
   else  If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  GROLF.v :=   CARBO.v-GRORT.v-GROSTM.v
   else  GROLF.v :=   0  ;

   If  (ISTAGE.v>=2)and(ISTAGE.v<6)
     then  GRORT.v :=   (1-PTF.v)*CARBO.v
   else  If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then  GRORT.v :=   max(CARBO.v*0.35, CARBO.v-GROLF.v)
   else  GRORT.v :=   0  ;

   If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  GROSTM.v :=  (0.15+0.12*SUMDTT2.v/PHINT.v)*CARBO.v*PTF.v
   else  If  (ISTAGE.v>=3)and(ISTAGE.v<5)
     then  GROSTM.v :=   CARBO.v*PTF.v
   else  If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  GROSTM.v :=   CARBO.v*PTF.v-GROGRN.v
   else  GROSTM.v :=   0;



   If  (PLA.v>0)and(ISTAGE.v<6)and(ISTAGE.v>=1)
     then  SENL.v :=   LFWT.v*0.000267*DTT.v*(1.-SENLA.v/PLA.v)
   else  SENL.v :=   0  ;

   SENRT.v :=  0.005*RTWT.v;

   If  (ISTAGE.v>=1)and(ISTAGE.v<6)
     then  SENSTM.v :=   STMWT.v*0.000267*DTT.v
   else  SENSTM.v :=   0  ;


   If  (ISTAGE.v>=0.99)and(ISTAGE.v<2)and(SEEDRV.v>0)
     then  SEEDRV.c :=   CARBO.v-GROLF.v-GRORT.v
   else  SEEDRV.c :=   0;

   If  -dlfwt.v>0
     then  SENLF.c :=   DLFWT.v
   else  SENLF.c :=   0  ;


   If  (TEMPM.v<10)and(ISTAGE.v>=5)and(ISTAGE.v<6)
     then  RGFILL.v :=   0.065*TEMPM.v
   else  If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  RGFILL.v :=   0.65+(0.0787-0.00328*(tempmx.v-tempmn.v))*(power((tempmx.v-10.0),0.8))
   else  RGFILL.v :=   0  ;


   If  (ISTAGE.v>=5)and(ISTAGE.v<6)and(CARBO.v*PTF.v<RGFILL.v*GPP.v*G2.v*0.001)and(STMWT.v<SWMIN.v)
     then  GROGRN.v :=   CARBO.v*PTF.v
   else  If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  GROGRN.v :=   RGFILL.v*GPP.v*G2.v*0.001
   else  GROGRN.v :=   0  ;





   STMWT.c :=  GROSTM.v-SENSTM.v;

   RTWT.c :=   0.6*GRORT.v-SENRT.v  ;

   GRNWT.c :=  GROGRN.v;

   If  (PLA.v>0)and(ISTAGE.v<6)and(ISTAGE.v>=1)
     then  LFWT.c :=   GROLF.v-SENL.v
   else  LFWT.c := 0;



end;


procedure Tsubpartitioning.Integrate;

begin
  Exlfw.V := lfwt.v;

  inherited  integrate;

  If (ISTAGE.v>=1) and (LFWT.v<=0) then begin
    LFWT.v:=0.00034;
    SEEDRV.v:=0.0012; // 0.012;
  end;

  If (ISTAGE.v>=4) and (SWMIN.v<=0) then begin
    SWMIN.v:=STMWT.v;
  end;

  If (ISTAGE.v>=5) and (gppend.v<=0) then begin
    grnwt.v  := 0.0035*gpp.v;
    STMWT.v := STMWT.v-GRNWT.v;
    If (gppend.v <=0.0) then
      gppend.v := gpp.v;
  end;

  TOPWT.v :=  LFWT.v+STMWT.v+SEEDRV.v;


  STMWT_m2.v :=  STMWT.v*Plants.v;

  GRNWT_m2.v :=  GRNWT.v*Plants.v;

  LFWT_m2.v :=  LFWT.v*Plants.v;

  RTWT_m2.v :=  RTWT.v*plants.v;

  TOPWT_m2.v :=  GRNWT_m2.v+LFWT_m2.v+STMWT_m2.v;

  If  gpsm.v>0 then
     TKM.v := GRNWT_m2.v/gpsm.v*1000
  else  TKM.v :=   0;


end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Tsubpartitioning]);
end;

end.
