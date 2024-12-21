unit USubLeafAreaGrowthSimple;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics,
  vcl.Controls, vcl.Forms, vcl.Dialogs, UMod, UState;

const
  MaxLeafNumber = 25;

Type

TDroughtImpact = (DroughtImpact, NoDroughtImpact);


TSubLeafAreaGrowthSimple = class(TSubmodel)

private
  p5_ : real;



protected
  fDroughtImpact : TDroughtImpact;
public
       // p5_ : real; // removed to private Ratjen 26.10.2010

  senratesLA : array[1..MaxLeafNumber] of real; // senescence rates leaf area of individual leaves
  senratesDM : array[1..MaxLeafNumber] of real; // senescence rates dry matter of individual leaves


  EGFT       : TVar;   // Temperature factor for leaf growth [0..1]
  GPLA       : TVar;   // GPLA is the plant green leaf area (PLA - SENLA) [cm2/plant]
  LN_        : TVar;   // Leaf number of the primary tiller [n]
  PLAG       : TVar;   // The rate of expansion of leaf area on one plant [cm2/day]
  PLAGMS     : TVar;   // plant leaf area growth rate on the main stem (PLAGMS)
  PLALR      : TVar;   // Plant leaf area loss rate [cm2/(plant*d)]
  PLSCGR     : array [1..MaxLeafNumber] of TVar;   //  Leaf area growth rate of single leaves
  V1         : TVar;   // source limited leaf growth rate
  V2         : TVar;   // sink limited leaf growth rate
  fSLAWR     : TVar;   // factor for correcting SLA under drought stress
  AvSLA      : TVar;   // average specific leaf area of canopy [square cm/g]
  actSLA        : TVar;  // actual specific leaf area of new grown leaves [square cm/g]
  GAI        : TVar;   // Green area index [m²/m²]
  avIcrop        : TVar; // Mittlere Einstrahlung im Bestand (I) über 10 Tage

  // Constant Variables

  LAI         : TState;   // Leaf area index [m2/m2]
  PLA         : TState;   // Plant leaf area  [cm2/plant]
  PLSC        : array[1..MaxLeafNumber] of TState;   //  Leaf area of single leaves
  PL_weight   : array[1..MaxLeafNumber] of TState;   //  Leaf weight of single leaves
  SENLA       : TState;   //  Area of leaf that senesces from a tiller on a given day - [cm2/d]
  SUMDTT5     : TState;   // The sum of daily thermal time (DTT) for stage 5  [degree days]
  LAIStem     : TState;   // Stem area index [m²/m²]
  CUMPH : TState;   // cumulative phyllochrons since emergence [-]

  // Parameters
  SLAconst        : TPar;   //  constant SLA or SLA after decay
  k_actSLA       : TPar;   // decay constant for specific leaf area during ISTAGE 1, initial SLA = SLAconst + k_actSLA
  CLG         : TPar;   //   ??
  psiWRsla    : TPar;  // critical psiWR where sla starts to increase
  fSLAmin      : TPar;  // relative, minimum SLA
  f1fslawr    : TPar;  // decrease of SLA per increase of psiWR
  SSA1         : TPar;  // specific stem area [cm²/g] before ec 30
  SSA2         : TPar;  // specific stem area [cm²/g] after ec 30
  PSENLeaf1    : TPar; // Parameter for leaf senescence
  PSENLeaf2    : TPar; // Parameter for leaf senescence
  PLAini       : TPar; // Parameter for initial plant leaf area [cm²]

  // External Variables

  GROLF       : TExternV;   //  growth rate of leaves (g/pl/d)
  GROSTM      : TExternV;   // Daily stem growth  [g/(plant.d)]
  ISTAGE      : TExternV;   //  integer growth stage according to ceres
  XSTAGE      : TExternV;
//  ndef2       : TExternV;   //
  P5          : TExternV;   // Parameter or length of grain filling period
  plants      : TExternV;   // number of plants (1/m2)
  SWDF1       : TExternV;   // Soil Water deficit factor (Tact/Tpot)
  TDU         : TExternV;   // termal developmental units
  TMPM        : TExternV;   // mean day temperature
  TMPMN       : TExternv;   // minimum day temperature
  TMPMX       : TExternV;   // maximum day temperature
  TI          : TExternV;   // increase of tiller number (1/d)
  TILN        : TExternV;   // tiller number per plant
  TPSM        : TExternV;   // tiller number per m2
  EC          : TExternV;   // ec stage of crop
  SENL        : TExternV;   // Senescence rate of leaf dry matter (total) (g/pl/d)
  psiroot     : TExternV;   // average soil water potential in the rooted soil
  Phint       : TExternV;   // Phyllochronintervall [°d]
  TSumInc     : TExternV;   //Tagestemperatur >=0 zur Basistemperatur
  PAR        : TExternV;
  kPAR        : TExternV; // k for PAR
  Icrop: Array [1..10] of real; //Mittlere Einstrahlung über 10 Tage
  // Options
  OptDroughtimpact : Toption;


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  Property Var_actSLA : TVar read actSLA write actSLA;
  Property Var_EGFT : TVar read EGFT write EGFT;
  Property Var_GPLA : TVar read GPLA write GPLA;
  Property Var_LN_ : TVar read LN_ write LN_;
  Property Var_PLAG : TVar read PLAG write PLAG;
  Property Var_PLAGMS : TVar read PLAGMS write PLAGMS;
  Property Var_PLALR : TVar read PLALR write PLALR;
//  Property Var_PLSCGR[1..MaxLeafNumber] : TVar read PLSCGR[1..MaxLeafNumber] write PLSCGR[1..MaxLeafNumber];
  Property Var_V1 : TVar read V1 write V1;
  Property Var_V2 : TVar read V2 write V2;

  Property St_LAI : TState read LAI write LAI;
  Property St_PLA : TState read PLA write PLA;
//  Property St_PLSC[1..MaxLeafNumber] : TState read PLSC[1..MaxLeafNumber] write PLSC[1..MaxLeafNumber];
  Property St_SENLA : TState read SENLA write SENLA;
  Property St_SUMDTT5 : TState read SUMDTT5 write SUMDTT5;
  Property St_CUMPH : TState read CUMPH write CUMPH;


         // Parameters
  Property Par_SLAconst : TPar read SLAconst write SLAconst;
  Property Par_k_actSLA : TPar read k_actSLA write k_actSLA;
  Property Par_PLAini : TPar read PLAini write PLAini;
  Property Par_CLG : TPar read CLG write CLG;
  Property Par_SSA1 : TPar read SSA1 write SSA1;
  Property Par_SSA2 : TPar read SSA2 write SSA2;

         // Properties External Variables
  Property Ex_GROLF : TExternV read GROLF write GROLF;
  Property Ex_GROSTM : TExternV read GROSTM write GROSTM;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
  Property Ex_Phint : TExternV read Phint write Phint;

//  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
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
  Property Ex_TSumInc : TExternV read TSumInc write TSumInc;

  property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;


end;  // SubmodelName

procedure Register;

implementation

uses
  Math;

procedure TSubLeafAreaGrowthSimple.createAll;
var
  i : integer;

begin
  inherited createAll;
  VarCreate('actSLA', '[square cm/g]',0, true, actSLA);
  VarCreate('EGFT', '[0..1]',0, true, EGFT);
  VarCreate('GPLA', '[cm2/plant]',0, true, GPLA);
  VarCreate('LN_', '[n]',0, true, LN_);
  VarCreate('PLAG', '[cm2/day]',0, true, PLAG);
  VarCreate('PLAGMS', '',0, true, PLAGMS);
  VarCreate('PLALR', '[cm2/(plant*d)]',0, true, PLALR);
  for I := 1 to MaxLeafNumber do
    if I < 10 then
      VarCreate('PLSCGR__' +inttostr(i), '[cm2/plant]',0, true, PLSCGR[i])
    else
      VarCreate('PLSCGR_' +inttostr(i), '[cm2/plant]',0, true, PLSCGR[i]);
  VarCreate('V1', '',0, true, V1);
  VarCreate('V2', '',0, true, V2);
  VarCreate('GAI', '[m2/m2]',0, true,GAI);
  VarCreate('fSLAWR', '',0, true, fSLAWR);
  VarCreate('AvSLA', '', 0, true, AvSLA);
  VarCreate('avIcrop', '', 0, true, avIcrop);

  StateCreate('LAI', '[m2/m2]',0, true,LAI);
  StateCreate('PLA', '[cm2/plant]',0, true,PLA);
  for i := 1 to MaxLeafNumber do begin
    if i < 10 then begin
      StateCreate('PLSC__'+inttostr(i),'[cm2/plant]',0, true, PLSC[i]);
      StateCreate('PL_weight__'+inttostr(i),'[g/plant]',0, true, PL_weight[i]);
    end
    else begin
      StateCreate('PLSC_'+inttostr(i),'[cm2/plant]',0, true, PLSC[i]);
      StateCreate('PL_weight_'+inttostr(i),'[g/plant]',0, true, PL_weight[i]);
    end;
  end;
  StateCreate('SENLA', '[cm2/d]',0, true,SENLA);
  StateCreate('SUMDTT5', '[degree days]',0, true,SUMDTT5);
  StateCreate('LAIStem', '[m2/m2]',0, true,LAIStem);
  StateCreate('CUMPH', '[-]',0, true,CUMPH);


  // Parameters
  ParCreate('SLAconst', '[cm2/g]', 180 ,SLAconst);   //geändert von 240 auf 180 //ratjen 25.11.08
  ParCreate('k_actSLA', '[cm2/g]', 178.464 , k_actSLA);
  ParCreate('CLG', '[?]', 7.50, CLG);
  ParCreate('SSA1', '[cm2/g]', 44 ,SSA1);
  ParCreate('SSA2', '[cm2/g]', 14 ,SSA2);
  ParCreate('PLAini', '[cm2]', 1.43749 ,PLAini);
  ParCreate('PSENLeaf1', '[-]',0.0003,PSENLeaf1);
  ParCreate('PSENLeaf2', '[-]',0.0006,PSENLeaf2);
  ParCreate('psiWRsla', '[pF]', 2.8 ,psiWRsla);
  ParCreate('fSLAmin', '[cm2/g]', 0.7 ,fSLAmin);
  ParCreate('f1fslawr', '[cm2/g]', 0.2, f1fslawr);
  
         // External Variable
  ExternVCreate('GROLF', '',statefield, GROLF);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('XSTAGE', '',statefield, XSTAGE);
  ExternVCreate('GROSTM', '',statefield, GROSTM);
//  ExternVCreate('ndef2', '',statefield, ndef2);
  ExternVCreate('P5', '', statefield, P5);
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
  ExternVCreate('SENL', '', ratefield, SENL);
  ExternVCreate('psiroot', '',statefield, psiroot);
  ExternVCreate('Phint', '',statefield, Phint);
  ExternVCreate('TSumInc', '',statefield, TSumInc);
  ExternVCreate('kPAR', '',statefield, kPAR);
  ExternVCreate('PAR', '',statefield, PAR);

  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
  optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');

end;


procedure TSubLeafAreaGrowthSimple.init(var GlobMod: TMod);

var
  i : integer;

begin
  inherited init(GlobMod);

  if optDroughtimpact.option = 'droughtimpact' then fdroughtimpact := DroughtImpact;
  if optDroughtimpact.option = 'nodroughtimpact' then fdroughtimpact := noDroughtImpact;
  LAI.v := 0;
  PLA.v := 0;
  for i := 1 to MaxLeafNumber do begin
    PLSC[i].v := 0;
    PL_weight[i].v := 0;
    senratesLA[i] := 0;
    senratesDM[i] := 0;
  end;
  SENLA.v := 0;
  SUMDTT5.v := 0;
  p5_ := 430+P5.v*20; // unscaled value of parameter p5
end;


procedure TSubLeafAreaGrowthSimple.CalcRates;

var
  i : integer;
  IPAR : real; // Einstrahlung (PAR MJ) im Bestand


begin
 //  p5_ := 430+P5.v*20; // unscaled value of parameter p5 // removed to init Ratjen 26.10.2010
   for i := 1 to MaxLeafNumber do begin
     PLSC[i].c := 0.0;
     PL_weight[i].c := 0.0;
   end;

 //  If round(ISTAGE.v)=5 then SUMDTT5.c := TMPM.v  {TempSum in iStage 5}
 If round(ISTAGE.v)=5 then SUMDTT5.c := max(0,TMPM.v)// Ratjen 26.10.2010  {TempSum in iStage 5}
                        else SUMDTT5.c := 0;

   //If xSTAGE.v<1.5
   If CUMPH.v<=4
//     then  actSLA.v :=   SLAconst.v-k_actSLA.v*TDU.v     // provisional option for decreasing SLA during early stages according to gabrielle grosub.for
     //then actSLA.v := SLAconst.v + (1.5-xstage.v)*2*k_actSLA.v
     then actSLA.v := SLAconst.v + (4-CUMPH.v)/4*k_actSLA.v
   else
     actSLA.v :=   SLAconst.v;

   EGFT.v :=  max(0, min(1, 1.2-0.0042*sqr(TMPM.v-17)));  // temperature factor

  If  (ISTAGE.v>=1)and (ISTAGE.v<3) then
     CUMPH.c :=  TSumInc.v/PHINT.v       // rate of change of cumulative phyllochron
  else  CUMPH.c :=   0  ;

   LN_.v :=  trunc(min(MaxLeafNumber,CUMPH.v+1)); // leaf number

   PLAGMS.v :=  CLG.v*sqrt(CUMPH.v)*MIN(SWDF1.v, min(EGFT.v, 1{ndef2.v}))*TI.v;

{   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then begin
       V1.v :=  GROLF.v*AWR.v;           //  source limited leaf growth rate
       V2.v :=  PLAGMS.v*(0.3+0.7*TILN.v);   // sink limited leaf growth rate
       PLAG.v :=   min(GROLF.v*AWR.v, PLAGMS.v*(0.3+0.7*TILN.v))
     end
   else  If  (TPSM.v>900)
     then  PLAG.v :=   PLAGMS.v*900./PLANTS.v
   else
     PLAG.v :=   PLAGMS.v*(0.3+0.7*TILN.v);       // plant leaf area growth per plant (cm2/pl)}
    PLALR.v := 0;

   If (round(ISTAGE.v)>=1) and (round(ISTAGE.v)<=2) and (CUMPH.v>4) and (ec.v < 30) then begin    // senecence only until EC 30, changed ..
     If senratesLA[trunc(LN_.v)-4] = 0 then begin
       senratesLA[trunc(LN_.v)-4] := (PLSC[trunc(LN_.v)-4].v); // the fifth oldest leaf is deceasing
       senratesDM[trunc(LN_.v)-4] := (PL_weight[trunc(LN_.v)-4].v); // the fifth oldest leaf is deceasing
     end;

     PLALR.v := min(PLSC[trunc(LN_.v)-4].v/globtime.c, senratesLA[trunc(LN_.v)-4]*TSumInc.v/PhInt.v);
     SENL.v := min(PL_weight[trunc(LN_.v)-4].v/globtime.c, senratesDM[trunc(LN_.v)-4]*TSumInc.v/PhInt.v);
     PLSC[trunc(LN_.v)-4].c :=  -1*min(PLSC[trunc(LN_.v)-4].v/globtime.c, PLALR.v);
     PL_weight[trunc(LN_.v)-4].c :=  -1*min(PL_weight[trunc(LN_.v)-4].v/globtime.c, SENL.v);
     if (ln_.v>5)and (PLSC[trunc(LN_.v)-5].v > 0.0)  then begin
       PLSC[trunc(LN_.v)-5].c :=  -PLSC[trunc(LN_.v)-5].v/globtime.c;
       PLALR.v := PLALR.v - PLSC[trunc(LN_.v)-5].c;
       PL_weight[trunc(LN_.v)-5].c :=  -PL_weight[trunc(LN_.v)-5].v/globtime.c;
       SENL.v := SENL.v - PL_weight[trunc(LN_.v)-5].c;
     end;
   end

   else begin
     If (round(ISTAGE.v)=1) and (pla.v>0)and(SENLA.v/pla.v>0.4) AND (LAI.v<6.0)
       then  PLALR.v :=   0
     else If (ISTAGE.v>=2) and (ISTAGE.v<4) 
       then
          PLALR.v := PSENLeaf1.v*TSumInc.v*GPLA.v
         else If (ISTAGE.v>=4) and (ISTAGE.v<5) then
           PLALR.v :=   PSENLeaf2.v*TSumInc.v*GPLA.v
     else  If  (ISTAGE.v>=5)and(ISTAGE.v<6)
       then  PLALR.v :=   GPLA.v*2*SUMDTT5.v*TSumInc.v/(P5_*P5_)
     else  PLALR.v := 0;
     if AvSLA.v > 0 then SENL.v := PLALR.v / AvSLA.v;
   end;

   If (IStage.v >= 2) and (fDroughtImpact = droughtimpact) then
     fSLAWR.v := min(1,max(1-f1fslawr.v*(psiroot.v-psiWRsla.v), fSLAmin.v))
   else
     fSLAWR.v := 1;
   actSLA.v := actSLA.v*fSLAWR.v;

   for i := 1 to MaxLeafNumber do begin
     if i = trunc(ln_.v) then begin
       PLSCGR[i].v :=  GROLF.v*actSLA.v;   // only one leaf is actually growing
       PL_weight[i].c :=  GROLF.v;         // only one leaf is actually growing
     end
     else begin
       PLSCGR[i].v := 0;
       if i > trunc(ln_.v)-2 then PL_weight[i].c :=  0;   // only one leaf is actually growing
     end;
     PLSC[i].c := PLSC[i].c + plscgr[i].v;    // leaf area change of leaf  i  (cm2/pl)
   end;

   PLA.c :=  GROLF.v*actSLA.v;   // growth rate of leaf area per plant

   SENLA.c :=  PLALR.v;      //   rate of change of senescent leaf area per plant (cm2/pl)

   If EC.v <30 then LAIStem.c := SSA1.v*GROSTM.v*PLANTS.v/10000
   else LAIStem.c := SSA2.v*GROSTM.v*PLANTS.v/10000;
end;


procedure TSubLeafAreaGrowthSimple.Integrate;
var
  sumLA, sumDM : real;
  i : integer;
 
begin
  inherited  integrate;
  If (ISTAGE.v>=1) and (lai.v<=0) and (ISTAGE.v<3) then begin   // for initialisation
    PLA.v:=PLAini.v;   // initial plant leaf area set to parameter value
    LAI.v:=PLA.v*PLANTS.v/1e4;
  end
  else LAI.v := (pla.v-senla.v)*plants.v*1e-4;   // Leaf area index as the difference of total and senescent leaf area

  If (ISTAGE.v>=6) and (lai.v>=0) then LAI.v:=0;

  sumla := 0.0;
  sumDM := 0.0;

  for i := 1 to trunc(ln_.v) do begin
    sumLA := sumLA + plsc[i].v;
    sumDM := sumDM + pl_weight[i].v;
  end;
  if sumDM > 0 then
    avSLA.v := sumLA/sumDM
  else
    avSLA.v := 0.0;

  GPLA.v :=  (PLA.v - SENLA.v);
  GAI.v := LAI.v+LAIStem.v;
end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubLeafAreaGrowthSimple]);
end;

end.

