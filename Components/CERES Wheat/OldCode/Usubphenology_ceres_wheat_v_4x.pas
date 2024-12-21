unit Usubphenology_ceres_wheat_v_4x;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type

Tsubphenology_ceres_wheat_v_4x = class(TSubmodel)

private

  germinated,
  emerged : boolean;

protected

public
  ASTAGE : TVar;   // Stage,start of anthesis/silk   #
  ASTAGEND : TVar;   // Stage at end of Anthesis
  DF : TVar;   // Daylength factor 0-1           #
  DU : TVar;   // Developmental units  [PVC.d]
  GESTAGE : TVar;   // Germination,emergence stage    #
  GEU : TVar;   // Germination,emergence units    #
  P1DA : TVar;   // Photoperiod coeff,age adjusted /h
  P1DAFAC : TVar;   // Photoperiod coeff,adjust fac   /lf
  PD4:  array [1..3] of TVar;   // Phase durations during stage 4
  PEGD : TVar;   // Phase duration,germ+dormancy   deg.d
  RSTAGE : TVar;   // New Developmental stages according to CERES 4.x [#]
  TempAir : TVar;   // Average Day Temperature
  tfV : TVar;   // Vernalisation rate [d]
  TNUMD : TVar;   // Tiller death rate [#/d]
  TNUMG : TVar;   // Tiller number growth [#/d]
  TNUMIFF : TVar;   // Tiller number fibonacci factor #
  TNUMLOSS : TVar;   // Tiller loss rate [#/d]
  TT : TVar;   // Thermal time [deg d]
  VF : TVar;   // vernalisation effect on development rate [0..1]
  VF0 : TVar;   // Vernalization fac,unvernalized #
  WFGE : TVar;   // Water factor,germ,emergence    #
  XStage : TVar;   // Development stages according to CERES (floating point)
  ZSTAGE : TVar;   // Zadoks stages [#]


  // Constant Variables
  PD : array[0..9] of TVar;   // Phase durations [du]


  // State Variables
  CUMDU : TState;   // Accumulated developmental units [PVCd]
  CUMGEU : TState;   // Cumulative GE units (TDD*WFGE) #
  CUMVD : TState;   // Cumulative Vernalisation sum [d]
  ISTAGE : TState;   // Integer Versiosn of Developmental stages 
  LNUMSD : TState;   // number of leaves on the mainstem
  PTH: array [0..9] of TState;   // Phase tresholds (upper limit for accumulated DU for a certain stage) [DU]
  Tempsum : TState;   // Temperature sum since sowing
  TNUM : TState;   // Tiller (incl.main stem) number #/p

             // Parameters
  P1 : TPar;   // 
  P1D : TPar;   // 
  P1D_ : TPar;   // 
  P1DPE : TPar;   // 
  P1DT : TPar;   // 
  P1V : TPar;   // 
  P1VT : TPar;   // 
  P2 : TPar;   // 
  P3 : TPar;   // 
  P4 : TPar;   // 
  P4SGE : TPar;   // 
  P5 : TPar;   // 
  PD4FR : array [1..2] of TPar;   //  Phase 4 sub-durations;1<anthesis fr
  PECM : TPar;   // 
  PEG : TPar;   // 
  PHINT : TPar;   // 
  PLMAGE : TPar;   // 
  SDEPTH : TPar;   // 
  sowingdate : TPar;   // 
  STDDAY : TPar;   // 
  Tb : TPar;   // 
  TI1LF : TPar;   //
  P9_TempSumEmergence : TPar;
  PDUR6,
   VernMinTemp,    // minimum vernalisation temperature
    VernOptTemp1,   // temperature where vernalisation is starting to be optimal
    VernOptTemp2,   // temperature where vernalisation is ending to be optimal
    VernMaxTemp     // temperature where vernalisation is getting zero


   : TPar;

             // External Variables
  DAYLP : TExternV;   // photoperiodic daylength
  Tavg : TExternV;   // average day temperature


  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override;
  procedure Integrate; override; 


published
  Property Var_ASTAGE : TVar read ASTAGE write ASTAGE;
  Property Var_ASTAGEND : TVar read ASTAGEND write ASTAGEND;
  Property Var_DF : TVar read DF write DF;
  Property Var_DU : TVar read DU write DU;
  Property Var_GESTAGE : TVar read GESTAGE write GESTAGE;
  Property Var_GEU : TVar read GEU write GEU;
  Property Var_P1DA : TVar read P1DA write P1DA;
  Property Var_P1DAFAC : TVar read P1DAFAC write P1DAFAC;
//  Property Var_PD4 : TVar read PD4 write PD4;
  Property Var_PEGD : TVar read PEGD write PEGD;
  Property Var_RSTAGE : TVar read RSTAGE write RSTAGE;
  Property Var_TempAir : TVar read TempAir write TempAir;
  Property Var_tfV : TVar read tfV write tfV;
  Property Var_TNUMD : TVar read TNUMD write TNUMD;
  Property Var_TNUMG : TVar read TNUMG write TNUMG;
  Property Var_TNUMIFF : TVar read TNUMIFF write TNUMIFF;
  Property Var_TNUMLOSS : TVar read TNUMLOSS write TNUMLOSS;
  Property Var_TT : TVar read TT write TT;
  Property Var_VF : TVar read VF write VF;
  Property Var_VF0 : TVar read VF0 write VF0;
  Property Var_WFGE : TVar read WFGE write WFGE;
  Property Var_XStage : TVar read XStage write XStage;
  Property Var_ZSTAGE : TVar read ZSTAGE write ZSTAGE;

  Property St_CUMDU : TState read CUMDU write CUMDU;
  Property St_CUMGEU : TState read CUMGEU write CUMGEU;
  Property St_CUMVD : TState read CUMVD write CUMVD;
  Property St_ISTAGE : TState read ISTAGE write ISTAGE;
  Property St_LNUMSD : TState read LNUMSD write LNUMSD;
//  Property St_PTH : TState read PTH write PTH;
  Property St_Tempsum : TState read Tempsum write Tempsum;
  Property St_TNUM : TState read TNUM write TNUM;


         // Parameters
  Property Par_P1 : TPar read P1 write P1;
  Property Par_P1D : TPar read P1D write P1D;
  Property Par_P1D_ : TPar read P1D_ write P1D_;
  Property Par_P1DPE : TPar read P1DPE write P1DPE;
  Property Par_P1DT : TPar read P1DT write P1DT;
  Property Par_P1V : TPar read P1V write P1V;
  Property Par_P1VT : TPar read P1VT write P1VT;
  Property Par_P2 : TPar read P2 write P2;
  Property Par_P3 : TPar read P3 write P3;
  Property Par_P4 : TPar read P4 write P4;
  Property Par_P4SGE : TPar read P4SGE write P4SGE;
  Property Par_P5 : TPar read P5 write P5;
//  Property Par_PD4FR : TPar read PD4FR write PD4FR;
  Property Par_PECM : TPar read PECM write PECM;
  Property Par_PEG : TPar read PEG write PEG;
  Property Par_PHINT : TPar read PHINT write PHINT;
  Property Par_PLMAGE : TPar read PLMAGE write PLMAGE;
  Property Par_SDEPTH : TPar read SDEPTH write SDEPTH;
  Property Par_sowingdate : TPar read sowingdate write sowingdate;
  Property Par_STDDAY : TPar read STDDAY write STDDAY;
  Property Par_Tb : TPar read Tb write Tb;
  Property Par_TI1LF : TPar read TI1LF write TI1LF;
  Property Par_P9_TempSumEmergence: TPar read P9_TempSumEmergence write P9_TempSumEmergence;
  Property Par_PDUR6: TPar read PDUR6 write PDUR6;
   property PAR_VernMinTemp: TPar read VernMinTemp write VernMinTemp;    // minimum vernalisation temperature
   property PAR_VernOptTemp1: TPar read VernOptTemp1 write VernOptTemp1;   // temperature where vernalisation is starting to be optimal
   property PAR_VernOptTemp2: TPar read VernOptTemp2 write VernOptTemp2;   // temperature where vernalisation is ending to be optimal
   property PAR_VernMaxTemp: TPar read VernMaxTemp write VernMaxTemp;     // temperature where vernalisation is getting zero



         // Properties External Variables
  Property Ex_DAYLP : TExternV read DAYLP write DAYLP;
  Property Ex_Tavg : TExternV read Tavg write Tavg;


end;  // SubmodelName

procedure Register;

implementation

uses
  math, UModUtils;

procedure Tsubphenology_ceres_wheat_v_4x.createAll;

var
  i : integer;

begin
  inherited createAll;
  VarCreate('ASTAGE', '',0, true, ASTAGE, 'Stage,start of anthesis/silk   #');  
  VarCreate('ASTAGEND', '',0, true, ASTAGEND, 'Stage at end of Anthesis');  
  VarCreate('DF', '',0, true, DF, 'Daylength factor 0-1           #');  
  VarCreate('DU', '[PVC.d]',0, true, DU, 'Developmental units  [PVC.d]');  
  VarCreate('GESTAGE', '',0, true, GESTAGE, 'Germination,emergence stage    #');  
  VarCreate('GEU', '',0, true, GEU, 'Germination,emergence units    #');  
  VarCreate('P1DA', '',0, true, P1DA, 'Photoperiod coeff,age adjusted /h');  
  VarCreate('P1DAFAC', '',0, true, P1DAFAC, 'Photoperiod coeff,adjust fac   /lf');  
  for i := 1 to 3 do
    VarCreate('PD4_'+inttostr(i),'',0.0, true, PD4[i]);
  VarCreate('PEGD', '',0, true, PEGD, 'Phase duration,germ+dormancy   deg.d');  
  VarCreate('RSTAGE', '[#]',0, true, RSTAGE, 'New Developmental stages according to CERES 4.x [#]');  
  VarCreate('TempAir', '',0, true, TempAir, 'Average Day Temperature');  
  VarCreate('tfV', '[d]',0, true, tfV, 'Vernalisation rate [d]');  
  VarCreate('TNUMD', '[#/d]',0, true, TNUMD, 'Tiller death rate [#/d]');  
  VarCreate('TNUMG', '[#/d]',0, true, TNUMG, 'Tiller number growth [#/d]');  
  VarCreate('TNUMIFF', '',0, true, TNUMIFF, 'Tiller number fibonacci factor #');  
  VarCreate('TNUMLOSS', '[#/d]',0, true, TNUMLOSS, 'Tiller loss rate [#/d]');  
  VarCreate('TT', '[deg d]',0, true, TT, 'Thermal time [deg d]');  
  VarCreate('VF', '[0..1]',0, true, VF, 'vernalisation effect on development rate [0..1]');  
  VarCreate('VF0', '',0, true, VF0, 'Vernalization fac,unvernalized #');  
  VarCreate('WFGE', '',0, true, WFGE, 'Water factor,germ,emergence    #');  
  VarCreate('XStage', '',0, true, XStage, 'Development stages according to CERES (floating point)');  
  VarCreate('ZSTAGE', '[#]',0, true, ZSTAGE, 'Zadoks stages [#]');  

  for i := 0 to 9 do
    VarCreate('PD_'+inttostr(i), '',0, true, PD[i], 'Phase duration stage'+inttostr(i)+ ' [du]');

  StateCreate('CUMDU', '[PVCd]',0, true,CUMDU, 'Accumulated developmental units [PVCd]');
  StateCreate('CUMGEU', '',0, true,CUMGEU, 'Cumulative GE units (TDD*WFGE) #');
  StateCreate('CUMVD', '[d]',0, true,CUMVD, 'Cumulative Vernalisation sum [d]');
  StateCreate('ISTAGE', '',0, true,ISTAGE, 'Integer Versiosn of Developmental stages ');
  StateCreate('LNUMSD', '',0, true,LNUMSD, 'number of leaves on the mainstem');
  for i := 0 to 9 do
    StateCreate('PTH_'+inttostr(i),'[DU]',0.0, true, PTH[i]);  
  StateCreate('Tempsum', '',0, true,Tempsum, 'Temperature sum since sowing');
  StateCreate('TNUM', '',0, true,TNUM, 'Tiller (incl.main stem) number #/p');


  // Parameters
  ParCreate('P1', 'PVD',400,P1, '');
  ParCreate('P1D', '#',2.76,P1D, '');
  ParCreate('P1D_', '#',75,P1D_, '');
  ParCreate('P1DPE', '#',0,P1DPE, '');
  ParCreate('P1DT', 'h',20,P1DT, '');
  ParCreate('P1V', 'd',50,P1V, '');
  ParCreate('P1VT', 'd',50,P1VT, '');
  ParCreate('P2', 'PVD',285,P2, '');
  ParCreate('P3', 'PVD',240,P3, '');
  ParCreate('P4', 'PVD',300,P4, '');
  ParCreate('P4SGE', '#',4.45,P4SGE, '');
  ParCreate('P5', 'PVD',500,P5, '');
  ParCreate('PD4FR_1', '',0.25,PD4FR[1], '');
  ParCreate('PD4FR_2', '',0.1,PD4FR[2], '');
  ParCreate('PECM', '',20,PECM, '');
  ParCreate('PEG', '',60,PEG, '');
  ParCreate('PHINT', '°Cd',95,PHINT, '');
  ParCreate('PLMAGE', 'd',20,PLMAGE, '');
  ParCreate('SDEPTH', 'cm',3,SDEPTH, '');
  ParCreate('sowingdate', 'DOY',294,sowingdate, '');
  ParCreate('STDDAY', '°C',20,STDDAY, '');
  ParCreate('Tb', '°C',0,Tb, '');
  ParCreate('TI1LF', '#',3,TI1LF, '');
  ParCreate('P9_TempSumEmergence', '#', 100, P9_TempSumEmergence, '');
  ParCreate('PDUR6', '°Cd',100, PDUR6, '');
  ParCreate('VernMinTemp', '°C', -0.5, VernMinTemp);
  ParCreate('VernOptTemp1', '°C', 0.5, VernOptTemp1);
  ParCreate('VernOptTemp2', '°C', 6, VernOptTemp2);
  ParCreate('VernMaxTemp', '°C', 18, VernMaxTemp);


         // External Variable
  ExternVCreate('DAYLP', '',statefield, DAYLP);
  ExternVCreate('Tavg', '',statefield, Tavg);
end;


procedure Tsubphenology_ceres_wheat_v_4x.init(var GlobMod: TMod);

var
  i : integer;
begin
  inherited init(GlobMod);
  germinated := false;
  emerged := false;
  CUMDU.v := 0;
  CUMGEU.v := 0;
  CUMVD.v := 0;
  ISTAGE.v := 7;
  LNUMSD.v := 0;
  for i := 1 to 3 do
   PTH[i].v := 0;
  Tempsum.v := 0;
  TNUM.v := 0;

  PD[9].v :=  P9_TempSumEmergence.v;
  PD[1].v :=  P1.v;
  PD[2].v :=  P2.v;
  PD[3].v :=  P3.v;
  PD[4].v :=  P4.v;
  PD[5].v :=  P5.v;
  PD[6].v :=  PDUR6.v;

  PTH[0].v := PD[0].v;
  for i:=1 to 9 do
    PTH[i].v:=PTH[i-1].v + PD[i].v;

  PD4[1].v :=   PD4FR[1].v * PD[4].v;
  PD4[2].v :=   PD4FR[2].v * PD[4].v;
  PD4[3].v :=   PD[4].v -  PD4[1].v - PD4[2].v;

  ASTAGE.v :=  4.0 + PD4FR[1].v;
  ASTAGEND.v :=  4+(PD4[1].v+PD4[2].v)/PD[4].v;

end;


procedure Tsubphenology_ceres_wheat_v_4x.CalcRates;

var
  i : integer;

begin
  TempAir.v :=  Tavg.v;
  TT.v :=  max(0, Tempair.v- Tb.v);

  If globtime.v>SowingDate.v then
     Tempsum.c :=   max(0,TempAir.v-Tb.v)
  else Tempsum.c :=   0  ;

  If  (trunc(ISTAGE.v)=1)and(P1D.v<0) then
     DF.v :=   MAX(0.0,MIN(1.0,1.0-(ABS(P1D.v)/1000)*(DAYLP.v-P1DT.v)))
  else   If  (trunc(ISTAGE.v)=1)and(P1D.v>0) then
     DF.v :=   MAX(0.0,MIN(1.0,1.0 - P1DA.v*sqr(P1DT.v-DAYLP.v)))
  else   If  (ISTAGE.v>1) AND (ISTAGE.v<7) then
     DF.v :=   1
  else   If  istage.v>=7 then
     DF.v :=   P1DPE.v
  else  DF.v :=   1  ;

  If  (CUMGEU.v<PEGD.v) then
     GESTAGE.v :=   MIN(1.0,CUMGEU.v/PEGD.v*0.5)
  else  GESTAGE.v :=   MIN(1.0,0.5+0.5*(CUMGEU.v-PEGD.v)/(PECM.v*SDEPTH.v))  ;
    If  globtime.v>=sowingdate.v then
     GEU.v :=   TT.v*WFGE.v
  else  GEU.v :=   0  ;

  If  ISTAGE.v>1 then
     P1DA.v :=   MAX(0.0,MIN(1.0,1.0-(ABS(P1D_.v)/1000)*(DAYLP.v-P1DT.v)))
  else   If  trunc(ISTAGE.v)=1 then
     P1DA.v :=   MAX(0.0,(P1D_.v/10000)-(P1D_.v/10000)*P1DAFAC.v*(LNUMSD.v-5))
  else  P1DA.v :=   1  ;
   P1DAFAC.v :=  1;


  If  PLMAGE.v<0.0 then
     PEGD.v := PEG.v -(PLMAGE.v*STDDAY.v)
  else  PEGD.v := PEG.v;

   VF.v :=   MAX(0.,VF0.v+(1.-VF0.v)*MAX(0.,MIN(1.,CUMVD.v/P1V.v)))  ;
   VF0.v :=  1.- P1V.v/P1VT.v;
   WFGE.v :=  1;



  If  CUMVD.v>P1VT.v then
     tfV.v := 0
  else   If  globtime.v>SowingDate.v then
     tfV.v := trapez_f (TempAir.V, VernMinTemp.v, VernOptTemp1.v, VernOptTemp1.v, VernMaxTemp.v, 0, 1)
  else  tfV.v := 0;

  If  (globtime.v>=sowingdate.v)and(geSTAGe.v<1) then
     DU.v :=   TT.v
  else  DU.v :=   TT.v*VF.v*DF.v;

  If globtime.v>=sowingdate.v then
     CUMDU.c := DU.v
  else CUMDU.c := 0;

  TNUMD.v :=  0;

  If  (LNUMSD.v>=TI1LF.v) then
     TNUMG.v :=   TT.v/PHINT.v*TNUMIFF.v
  else  TNUMG.v :=   0  ;

  If  (LNUMSD.v>=TI1LF.v) and (XSTAGE.v<2.0) and (LNUMSD.v<TI1LF.v+3) then
     TNUMIFF.v :=   1.0
  else   If  (LNUMSD.v>=TI1LF.v) and (XSTAGE.v<2.0) and (LNUMSD.v>=TI1LF.v+3) AND (LNUMSD.v<TI1LF.v+4) then
     TNUMIFF.v :=   1.5
  else   If  (LNUMSD.v>=TI1LF.v) and (XSTAGE.v<2.0) and (LNUMSD.v>=TI1LF.v+4) AND (LNUMSD.v<TI1LF.v+5) then
     TNUMIFF.v :=   3
  else   If  (LNUMSD.v>=TI1LF.v) and (XSTAGE.v<2.0) and (LNUMSD.v>=TI1LF.v+5) AND (LNUMSD.v<TI1LF.v+6) then
     TNUMIFF.v :=   4
  else   If  (LNUMSD.v>=TI1LF.v) and (XSTAGE.v<2.0) and (LNUMSD.v>=TI1LF.v+6) AND (LNUMSD.v<TI1LF.v+7) then
     TNUMIFF.v :=   6
  else  TNUMIFF.v :=   0  ;

  TNUMLOSS.v :=  0;



  CUMGEU.c :=  GEU.v;
  CUMVD.c :=  tfV.v;

  If  (GESTAGE.v>=1)and(ISTAGE.v<7) then
     ISTAGE.c :=   Trunc(RSTAGE.v)-ISTAGE.v
  else  ISTAGE.c :=   0  ;

  If  (ISTAGE.v>=1)and(ISTAGE.v<3) then
     LNUMSD.c :=   max(0, TempAir.v-Tb.v)/PHINT.v
  else  LNUMSD.c :=   0  ;

  TNUM.c :=  (TNUMG.v-TNUMD.v-TNUMLOSS.v);


end;


procedure Tsubphenology_ceres_wheat_v_4x.Integrate;

var
  i : integer;
begin

  inherited  integrate;
  If (GESTAGE.v>=0.5) and (istage.v <> 9) and (germinated = false )then begin
    germinated := true;
    ISTAGE.v:=9;
  end;
  If (GESTAGE.v>=1) and (istage.v <> 1) and (emerged = false) then begin
    emerged := true;
    ISTAGE.v:=1;
  end;
  If (globtime.v>sowingdate.v) and (istage.v <=0)  then
    ISTAGE.v:=8;

  If  (CUMDU.v<=PTH[0].v) AND (PD[0].v > 0.0) then
     RSTAGE.v :=   CUMDU.v/PD[0].v
  else   If  CUMDU.v>=PTH[0].v then
     RSTAGE.v :=   1 + (CUMDU.v-PTH[0].v)/PD[1].v
  else   If  CUMDU.v>=PTH[1].v then
     RSTAGE.v :=   2 + (CUMDU.v-PTH[1].v)/PD[2].v
  else   If  CUMDU.v>=PTH[2].v then
     RSTAGE.v :=   3 + (CUMDU.v-PTH[2].v)/PD[3].v
  else   If  CUMDU.v>=PTH[3].v then
     RSTAGE.v :=   4 + (CUMDU.v-PTH[3].v)/PD[4].v
  else   If  CUMDU.v>=PTH[4].v then
     RSTAGE.v :=   5 + (CUMDU.v-PTH[4].v)/PD[5].v
  else   If  CUMDU.v>=PTH[5].v then
     RSTAGE.v :=   6 + (CUMDU.v-PTH[5].v)/PD[6].v
  else  RSTAGE.v :=   0  ;


   If  trunc(ISTAGE.v)=7 then
     XStage.v :=   8
  else   If  trunc(ISTAGE.v)=8 then
     XStage.v :=   ISTAGE.v + GESTAGE.v*2.0
  else   If  trunc(ISTAGE.v)=9 then
     XStage.v :=   ISTAGE.v + (GESTAGE.v-0.5)*2.0
  else   If  ISTAGE.v>=1 then
     XStage.v :=   MIN(6.9,RSTAGE.v)
  else  XStage.v :=   0  ;


  If  (XSTAGE.v>=8.0) AND (XSTAGE.v<=9.0) then
     ZSTAGE.v :=   ((XSTAGE.v-8.0)/2.0)*10.0
  else   If  (XSTAGE.v>9.0) then
     ZSTAGE.v :=   (0.5+((XSTAGE.v-9.0)/2.0))*10.0
  else   If  (XSTAGE.v>=0.0) AND (XSTAGE.v<=2.3) and (TNUM.v<2.0) then
     ZSTAGE.v :=   10.0 + LNUMSD.v
  else   If  (XSTAGE.v>=0.0) AND (XSTAGE.v<=2.3) and (TNUM.v>=2.0) then
     ZSTAGE.v :=   MIN(30.0,20.0 + (TNUM.v-1.0))
  else   If  (XSTAGE.v>2.3) AND (XSTAGE.v<=3.0) then
     ZSTAGE.v :=   30.0 + 10.0*(XSTAGE.v-2.3)/(1.0-0.3)
  else   If  (XSTAGE.v>3.0) AND (XSTAGE.v<=4.0) then
     ZSTAGE.v :=   40.0 + 10.0*(XSTAGE.v-3.0)
  else   If  (XSTAGE.v>4.0) AND (XSTAGE.v<=5.0) and (XSTAGE.v<ASTAGE.v) AND (XSTAGE.v<ASTAGEND.v) then
     ZSTAGE.v :=   50.0 + 10.0*((XSTAGE.v-4.0)/(ASTAGE.v-4.0))
  else   If  (XSTAGE.v>4.0) AND (XSTAGE.v<=5.0) and (XSTAGE.v>=ASTAGE.v) AND (XSTAGE.v<ASTAGEND.v) then
     ZSTAGE.v :=   60.0 + 10.0*((XSTAGE.v-ASTAGE.v)/(ASTAGEND.v-ASTAGE.v))
  else   If  (XSTAGE.v>ASTAGEND.v) AND (XSTAGE.v<=5.0) then
     ZSTAGE.v :=   70.0 + 10.0*((XSTAGE.v-ASTAGEND.v)/(5.0-ASTAGEND.v))
  else   If  (XSTAGE.v>4.0) AND (XSTAGE.v<=5.0) and (XSTAGE.v<ASTAGE.v) then
     ZSTAGE.v :=   50.0 + 10.0*((XSTAGE.v-4.0)/(ASTAGE.v-4.0))
  else   If  (XSTAGE.v>5.0) AND ( XSTAGE.v<=6.0) then
     ZSTAGE.v :=   80.0 + 10.0*(XSTAGE.v-5.0)
  else   If  (XSTAGE.v>6.0)  AND (XSTAGE.v<=7.0) then
     ZSTAGE.v :=   90.0 + 10.0*(XSTAGE.v-6.0)
  else  ZSTAGE.v :=   0  ;



end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Tsubphenology_ceres_wheat_v_4x]);
end;

end.
