unit UTillerdevelopment;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics,
  vcl.Controls, vcl.Forms, vcl.Dialogs, UMod, UState;

Type

TTillerdevelopment = class(TSubmodel)

private

protected

public
  DTN : TVar;   // Tiller death rate
  DTT : TVar;   // Daily thermal time [degree C days]
  RTSW : TVar;   // Weight of an average stem plus ear relative to a potential stem plus ear [-]
  sn1 : TVar;   // N deficit factor for tiller number increase
  TC1 : TVar;   // total potential rate of tiller formation [n/(pl*d)]
  TC2 : TVar;   // Rate of tiller formation based on the competition limitations of tillers per square meter
  TI : TVar;   // Fraction of a phyllochron interval which occurred as a fraction of today's daily thermal time
  TILLdeath : TVar;   //
  TILLgrowth : TVar;   // tiller number growth rate [n/(plant*d)]
  TPSM : TVar;   // number of tillers per square meter [TPSM]
  w1 : TVar;   // soil water deficit factor for tiller number increase
  TNOLD : TVar;   //


  // Constant Variables

  SENTIL : TState;   // numer of senescent tillers [n/plant]
  SUMDTT2 : TState;   // The sum of daily thermal time (DTT) for various phenological stages - degree days
  TILN : TState;   // Time delayed reduced tiller number [n/plant]
  TILSW : TState;   // weight of a single tiller [g/tiller]

             // Parameters

             // External Variables
  CUMPH : TExternV;   // 
  G3 : TExternV;   //
  GROSTM : TExternV;   //
  ISTAGE : TExternV;   //
  ndef2 : TExternV;   //
  NDEF3 : TExternV;   //
  PHINT : TExternV;   //
  PLANTS : TExternV;   //
  STMWT : TExternV;   //
  SWDF1 : TExternV;   //
  TEMPM : TExternV;   //
  TSumInc : TExternV;   //
  Tbase   : TExternV;


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  Property Var_DTN : TVar read DTN write DTN;
  Property Var_DTT : TVar read DTT write DTT;
  Property Var_RTSW : TVar read RTSW write RTSW;
  Property Var_sn1 : TVar read sn1 write sn1;
  Property Var_TC1 : TVar read TC1 write TC1;
  Property Var_TC2 : TVar read TC2 write TC2;
  Property Var_TI : TVar read TI write TI;
  Property Var_TILLdeath : TVar read TILLdeath write TILLdeath;
  Property Var_TILLgrowth : TVar read TILLgrowth write TILLgrowth;
  Property Var_TPSM : TVar read TPSM write TPSM;
  Property Var_w1 : TVar read w1 write w1;
  Property Var_TNOLD : TVar read TNOLD write TNOLD;

  Property St_SENTIL : TState read SENTIL write SENTIL;
  Property St_SUMDTT2 : TState read SUMDTT2 write SUMDTT2;
  Property St_TILN : TState read TILN write TILN;
  Property St_TILSW : TState read TILSW write TILSW;


         // Parameters

         // Properties External Variables
  Property Ex_CUMPH : TExternV read CUMPH write CUMPH;
  Property Ex_G3 : TExternV read G3 write G3;
  Property Ex_GROSTM : TExternV read GROSTM write GROSTM;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
  Property Ex_NDEF3 : TExternV read NDEF3 write NDEF3;
  Property Ex_PHINT : TExternV read PHINT write PHINT;
  Property Ex_PLANTS : TExternV read PLANTS write PLANTS;
  Property Ex_STMWT : TExternV read STMWT write STMWT;
  Property Ex_SWDF1 : TExternV read SWDF1 write SWDF1;
  Property Ex_TEMPM : TExternV read TEMPM write TEMPM;
  Property Ex_TSumInc : TExternV read TSumInc write TSumInc;


end;  // SubmodelName

procedure Register;

implementation

uses
  math;

procedure Ttillerdevelopment.createAll;

begin
  inherited createAll;
  VarCreate('DTN', '',0, true, DTN);
  VarCreate('DTT', '[degree C days]',0, true, DTT);
  VarCreate('RTSW', '[-]',0, true, RTSW);
  VarCreate('sn1', '',0, true, sn1);
  VarCreate('TC1', '[n/(pl*d)]',0, true, TC1);
  VarCreate('TC2', '',0, true, TC2);
  VarCreate('TI', '',0, true, TI);
  VarCreate('TILLdeath', '',0, true, TILLdeath);
  VarCreate('TILLgrowth', '[n/(plant*d)]',0, true, TILLgrowth);
  VarCreate('TPSM', '[TPSM]',0, true, TPSM);
  VarCreate('w1', '',0, true, w1);
  VarCreate('TNOLD', '',0, true, TNOLD);


  StateCreate('SENTIL', '[n/plant]',0, true,SENTIL);
  StateCreate('SUMDTT2', '',0, true,SUMDTT2);
  StateCreate('TILN', '[n/plant]',0, true,TILN);
  StateCreate('TILSW', '[g/tiller]',0, true,TILSW);


  // Parameters

         // External Variable
  ExternVCreate('CUMPH', '',statefield, CUMPH);
  ExternVCreate('G3', '',statefield, G3);
  ExternVCreate('GROSTM', '',statefield, GROSTM);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('ndef2', '',statefield, ndef2);
  ExternVCreate('NDEF3', '',statefield, NDEF3);
  ExternVCreate('PHINT', '',statefield, PHINT);
  ExternVCreate('PLANTS', '',statefield, PLANTS);
  ExternVCreate('STMWT', '',statefield, STMWT);
  ExternVCreate('SWDF1', '',statefield, SWDF1);
  ExternVCreate('TEMPM', '',statefield, TEMPM);
  ExternVCreate('TSumInc', '',statefield, TSumInc);

  end;


procedure Ttillerdevelopment.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  SENTIL.v := 0;
  SUMDTT2.v := 0;
  TILN.v := 0;
  TILSW.v := 0;
end;


procedure Ttillerdevelopment.CalcRates;

begin

   DTT.v :=  TSuminc.v;
   w1.v :=  1.4*swdf1.v-0.4;
   sn1.v :=  1-0*(1.4*NDEF3.v-0.4);

   If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  SUMDTT2.c :=   DTT.v
   else  SUMDTT2.c :=   0  ;

   If  ((TNOLD.v-TILN.v)>0)and(ISTAGE.v>=1)and(ISTAGE.v<3)
     then  DTN.v :=   (TNOLD.v-TILN.v)
   else  DTN.v :=   0  ;


   If  (TILSW.v>0)and(TILN.v>0)
     then  RTSW.v :=   (STMWT.v+GROSTM.v)/TILSW.v/TILN.v
   else  RTSW.v :=   0  ;


   If  CUMPH.v>=2.5
     then  TC1.v :=   min(1, max(0, -2.5+CUMPH.v))
   else  TC1.v :=   0;

   If  TPSM.v=3000
     then  TC2.v :=   0
   else  TC2.v :=   2.5E-7*power((3000-tpsm.v),3) ;

   If  (Istage.v>=1)and(Istage.v<2)
     then  TI.v :=   TSumInc.v/(PHINT.v)
   else  TI.v :=   0  ;

   If  (ISTAGE.v>=2)and(ISTAGE.v<4)
     then  TILLdeath.v :=   -TILN.v*DTT.v*0.005*(RTSW.v-1)
   else  TILLdeath.v :=   0  ;

   If  (ISTAGE.v>=1) and (ISTAGE.v<2)
     then  TILLgrowth.v :=   TI.v*min(w1.v,sn1.v)*MIN(TC1.v,TC2.v)
   else  TILLgrowth.v :=   0  ;



   SENTIL.v :=  +DTN.v;

   TILN.c :=  TILLgrowth.v-Tilldeath.v;

   If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  TILSW.c :=   G3.v*0.0889*DTT.v*min(ndef2.v,SWDF1.v)*SUMDTT2.v/sqr(PHINT.v)
   else  If  (ISTAGE.v>=3)and(ISTAGE.v<4)
     then  TILSW.c :=   G3.v*DTT.v*0.25/PHINT.v*min(SWDF1.v,ndef2.v)
   else  TILSW.c :=   0  ;

end;


procedure Ttillerdevelopment.Integrate;

begin

  inherited  integrate;
  If (ISTAGE.v>=1) and (TILN.v<=0) then begin
    TILSW.v := 0.01;
    TILN.v  := 1.;
  end;
  TPSM.v :=  TILN.v*PLANTS.v;

end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Ttillerdevelopment]);
end;

end.

