unit USubLeafAreaGrowthNew;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type

TSubLeafAreaGrowthNew = class(TSubmodel)

private

protected

public
  AWR        : TVar;   // Assimilate area to weight ratio [square cm/g]
  EGFT       : TVar;   // Temperature factor for leaf growth [0..1]
  GPLA       : TVar;   // GPLA is the plant green leaf area (PLA - SENLA) [cm2/plant]
  LN_        : TVar;   // Leaf number of the primary tiller [n]
  PLAG       : TVar;   // The rate of expansion of leaf area on one plant [cm2/day]
  PLAGMS     : TVar;   // plant leaf area growth rate on the main stem (PLAGMS)
  PLALR      : TVar;   // Plant leaf area loss rate [cm2/(plant*d)]
  PLSCGR     : array [1..25] of TVar;   //
  V1         : TVar;   //
  V2         : TVar;   //


  // Constant Variables

  LAI         : TState;   // Leaf area index [m2/m2]
  PLA         : TState;   // Plant leaf area  [cm2/plant]
  PLSC        : array[1..25] of TState;   //
  SENLA       : TState;   //  Area of leaf that senesces from a tiller on a given day - [cm2/d]
  SUMDTT5     : TState;   // The sum of daily thermal time (DTT) for stage 5  [degree days]

             // Parameters
  AWR0        : TPar;   //
  CLG         : TPar;   //
  SLA         : TPar;   // specific leaf area

             // External Variables
  CUMPH       : TExternV;   //
  DTT         : TExternV;   //
  GROLF       : TExternV;   //
  ISTAGE      : TExternV;   //
  ndef2       : TExternV;   //
  P5          : TExternV;   //
  plants      : TExternV;   //
  SWDF1       : TExternV;   //
  TDU         : TExternV;   //
  TMPM        : TExternV;   //
  TMPMN       : TExternv;
  TMPMX       : TExternV;
  TI          : TExternV;   //
  TILN        : TExternV;   //
  TPSM        : TExternV;   //
  EC          : TExternV;


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  Property Var_AWR : TVar read AWR write AWR;
  Property Var_EGFT : TVar read EGFT write EGFT;
  Property Var_GPLA : TVar read GPLA write GPLA;
  Property Var_LN_ : TVar read LN_ write LN_;
  Property Var_PLAG : TVar read PLAG write PLAG;
  Property Var_PLAGMS : TVar read PLAGMS write PLAGMS;
  Property Var_PLALR : TVar read PLALR write PLALR;
//  Property Var_PLSCGR[1..25] : TVar read PLSCGR[1..25] write PLSCGR[1..25];
  Property Var_V1 : TVar read V1 write V1;
  Property Var_V2 : TVar read V2 write V2;

  Property St_LAI : TState read LAI write LAI;
  Property St_PLA : TState read PLA write PLA;
//  Property St_PLSC[1..25] : TState read PLSC[1..25] write PLSC[1..25];
  Property St_SENLA : TState read SENLA write SENLA;
  Property St_SUMDTT5 : TState read SUMDTT5 write SUMDTT5;


         // Parameters
  Property Par_AWR0 : TPar read AWR0 write AWR0;
  Property Par_CLG : TPar read CLG write CLG;
  Property Par_SLA : TPar read SLA write SLA;

         // Properties External Variables
  Property Ex_CUMPH : TExternV read CUMPH write CUMPH;
  Property Ex_DTT : TExternV read DTT write DTT;
  Property Ex_GROLF : TExternV read GROLF write GROLF;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
  Property Ex_P5 : TExternV read P5 write P5;
  Property Ex_plants : TExternV read plants write plants;
  Property Ex_SWDF1 : TExternV read SWDF1 write SWDF1;
  Property Ex_TDU : TExternV read TDU write TDU;
  Property Ex_TMPM : TExternV read TMPM write TMPM;
  Property Ex_TMPMN : TExternV read TMPMN write TMPMN;
  Property Ex_TMPMX : TExternV read TMPMX write TMPMX;
  Property Ex_TI : TExternV read TI write TI;
  Property Ex_TILN : TExternV read TILN write TILN;
  Property Ex_TPSM : TExternV read TPSM write TPSM;

end;  // SubmodelName

procedure Register;

implementation

uses
  Math;

procedure TSubLeafAreaGrowthNew.createAll;
var
  i : integer;

begin
  inherited createAll;
  VarCreate('AWR', '[square cm/g]',0, true, AWR);
  VarCreate('EGFT', '[0..1]',0, true, EGFT);
  VarCreate('GPLA', '[cm2/plant]',0, true, GPLA);
  VarCreate('LN_', '[n]',0, true, LN_);
  VarCreate('PLAG', '[cm2/day]',0, true, PLAG);
  VarCreate('PLAGMS', '',0, true, PLAGMS);
  VarCreate('PLALR', '[cm2/(plant*d)]',0, true, PLALR);
  for I := 1 to 25 do
    VarCreate('PLSCGR_' +inttostr(i), '[cm2/plant]',0, true, PLSCGR[i]);
  VarCreate('V1', '',0, true, V1);
  VarCreate('V2', '',0, true, V2);


  StateCreate('LAI', '[m2/m2]',0, true,LAI);
  StateCreate('PLA', '[cm2/plant]',0, true,PLA);
  for i := 1 to 25 do
    StateCreate('PLSC_'+inttostr(i),'[cm2/plant]',0, true, PLSC[i]);
  StateCreate('SENLA', '[cm2/d]',0, true,SENLA);
  StateCreate('SUMDTT5', '[degree days]',0, true,SUMDTT5);


  // Parameters
  ParCreate('AWR0', '[cm2/g]', 150 ,AWR0);
  ParCreate('CLG', '[?]', 7.50, CLG);
  ParCreate('SLA', '[cm2/g]', 115 ,SLA);

         // External Variable
  ExternVCreate('CUMPH', '',statefield, CUMPH);
  ExternVCreate('DTT', '',statefield, DTT);
  ExternVCreate('GROLF', '',statefield, GROLF);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('ndef2', '',statefield, ndef2);
  ExternVCreate('P5', '',statefield, P5);
  ExternVCreate('plants', '',statefield, plants);
  ExternVCreate('SWDF1', '',statefield, SWDF1);
  ExternVCreate('TDU', '',statefield, TDU);
  ExternVCreate('TMPM', '',statefield, TMPM);
  ExternVCreate('TI', '',statefield, TI);
  ExternVCreate('TILN', '',statefield, TILN);
  ExternVCreate('TMPMN', '',statefield, TMPMN);
  ExternVCreate('TMPMX', '',statefield, TMPMX);
  ExternVCreate('TPSM', '',statefield, TPSM);
  ExternVCreate('EC', '',statefield, EC);
end;


procedure TSubLeafAreaGrowthNew.init(var GlobMod: TMod);

var
  i : integer;

begin
  inherited init(GlobMod);
  LAI.v := 0;
  PLA.v := 0;
  for i := 1 to 25 do
    PLSC[i].v := 0;
  SENLA.v := 0;
  SUMDTT5.v := 0;


end;


procedure TSubLeafAreaGrowthNew.CalcRates;

var
  i : integer;
  p5_ : real;

begin
   p5_ := 430+P5.v*20; // unscaled value of parameter p5

   If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  SUMDTT5.c :=   0.25*TMPMN.v+0.75*TMPMX.v
   else  SUMDTT5.c :=   0  ;

   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then  AWR.v :=   AWR0.v-0.075*TDU.v
   else  AWR.v :=   AWR0.v  ;

   EGFT.v :=  max(0, min(1, 1.2-0.0042*sqr(TMPM.v-17)));


   LN_.v :=  trunc(min(25,CUMPH.v+2));

   PLAGMS.v :=  CLG.v*sqrt(CUMPH.v)*MIN(SWDF1.v, min(EGFT.v, ndef2.v))*TI.v;

   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then begin
       V1.v :=  GROLF.v*AWR.v;
       V2.v :=  PLAGMS.v*(0.3+0.7*TILN.v);
       PLAG.v :=   min(GROLF.v*AWR.v, PLAGMS.v*(0.3+0.7*TILN.v))
     end
   else  If  (TPSM.v>900)
     then  PLAG.v :=   PLAGMS.v*900./PLANTS.v
   else  PLAG.v :=   PLAGMS.v*(0.3+0.7*TILN.v)  ;


   If  (ISTAGE.v>=1) and (ISTAGE.v<2) and (CUMPH.v>4)
     then  PLALR.v :=   (PLSC[trunc(LN_.v)-4].v-PLSC[trunc(LN_.v)-5].v)*TI.v
   else  If  (ISTAGE.v>=1) and (ISTAGE.v<2) and (pla.v>0)and(SENLA.v/pla.v>0.4) AND (LAI.v<6.0)
     then  PLALR.v :=   0
   else  If  (EC.v>=35) and (ISTAGE.v<4)
     then PLALR.v :=   0.0003*DTT.v*GPLA.v
   else  If  (ISTAGE.v>=3) and (ISTAGE.v<5)
     then PLALR.v :=   0.0006*DTT.v*GPLA.v
   else  If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  PLALR.v :=   GPLA.v*2*SUMDTT5.v*DTT.v/(P5_*P5_)
   else  PLALR.v := 0;

   for i := 1 to 25 do begin
     if i = trunc(ln_.v) then
       PLSCGR[i].v :=   GROLF.v*SLA.v
     else PLSCGR[i].v := 0;
     PLSC[i].c :=   plscgr[i].v;
   end;


   //LAI.c := (PLAG.v-PLALR.v)*plants.v/1e4;
   LAI.v := (pla.v-senla.v)*plants.v*1e-4;

   PLA.c :=  GROLF.v*SLA.v;


   SENLA.c :=  PLALR.v;


end;


procedure TSubLeafAreaGrowthNew.Integrate;

begin

  inherited  integrate;
  If (ISTAGE.v>=1) and (lai.v<=0) then begin
    LAI.v:=PLANTS.v*4e-10;
    // LAI.v := 1;
    PLA.v:=0.04;
  end;

  If (ISTAGE.v>=6) and (lai.v>=0) then begin
    LAI.v:=0;
  end;

  GPLA.v :=  (PLA.v - SENLA.v);

end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubLeafAreaGrowthNew]);
end;

end.

