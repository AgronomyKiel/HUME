unit UCeresRootGrowth;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Const
  MaxLayers = 20;  

Type

TSubCeresRootgrowth = class(TSubmodel)

private

protected

public
  CARBOAR : TVar;   // Carbohydrate available,roots [g/p]
  CUMDEP : TVar;   // sum of depths of all layers containing roots [cm]
  GRORT : TVar;     // Root growth [g/p/d]
  RLDF: array[1..MaxLayers] of TVar;   // Root length density fac,new gr [-]
  RLV: array[1..MaxLayers] of TVar;   // Root length density [cm/cm3]
  RTDEPG : TVar;    // Root depth growth [cm/d]
  RTWT_m2 : TVar;   // Root weight [g/m2]
  RTWTG : TVar;     // Root weight growth [g/p]
  RTWTGL: array[1..MaxLayers] of TVar; // Root weight growth by layer [g/p/d]
  RTWTGS : TVar;    // Root weight growth from seed [g/p]
  RTWTSLR : array[1..MaxLayers] of TVar;   // Senescent root weight per layer [g/pl]
  TRLDF : TVar;   // Intermediate factor,new roots  #
  TRLV : TVar;   // Total root length density      cm.cm-2
  DLAYR  : array [1..MaxLayers] of TVar;   // Thickness of soil layers [cm]


  // Constant Variables

  RTDEP : TState;   // Root depth [cm]
  RTWT : TState;   // Root weight [g/p]
  RTWTL: array [1..MaxLayers] of TState;   // Root weight by layer [g/p]
  RTWTS : TState;   // Root weight senesced           g/p
  RTWTSL: array[1..MaxLayers] of TState;   // Root weight senesced by layer  g/p

             // Parameters
  RDGS1 : TPar;   // Root depth growth rate,initial
  RDGTH : TPar;   // Rooting depth growth threshold dd
  RLIGP : TPar;   // Root lignin concentration  %
  RLWR : TPar;   // Root length/weight ratio
  RSEN : TPar;   // Root senescence fraction
  RTREF : TPar;   // Root respiration fraction      [-]
  SHF : array [1..MaxLayers] of TPar;   // Soil hospitality factor      [-]
  STDDAY : TPar;   // Standard day temperature
   PLTPOP : TPar;   // plant population [1/m2]

             // External Variables

  SDEPTH     : TExternV;   // sowing depth [cm]
  Temp     : TExternV;   // Thermal time [°C]
  Carbo  : TExternV;   // Daily carbon flow per plant
  PTF    : TExternV;   // Shoot fraction of assimilates
  Tiefe  : array [1..MaxLayers] of TExternV;   // Thickness of soil layers [cm]
  SWDF   : TExternV;   // soil water deficit factor [-]


  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override; 
  procedure Integrate; override;


published
  Property Var_CARBOAR : TVar read CARBOAR write CARBOAR;
  Property Var_CUMDEP : TVar read CUMDEP write CUMDEP;
//  Property Var_DLAYR[1..MaxLayers] : TVar read DLAYR[1..MaxLayers] write DLAYR[1..MaxLayers];
  Property Var_GRORT : TVar read GRORT write GRORT;
//  Property Var_RLDF[1..MaxLayers] : TVar read RLDF[1..MaxLayers] write RLDF[1..MaxLayers];
//  Property Var_RLV[1..MaxLayers] : TVar read RLV[1..MaxLayers] write RLV[1..MaxLayers];
  Property Var_RTDEPG : TVar read RTDEPG write RTDEPG;
  Property Var_RTWT_m2 : TVar read RTWT_m2 write RTWT_m2;
  Property Var_RTWTG : TVar read RTWTG write RTWTG;
//  Property Var_RTWTGL[1..MaxLayers] : TVar read RTWTGL[1..MaxLayers] write RTWTGL[1..MaxLayers];
  Property Var_RTWTGS : TVar read RTWTGS write RTWTGS;
//  Property Var_RTWTSLR[1..MaxLayers] : TVar read RTWTSLR[1..MaxLayers] write RTWTSLR[1..MaxLayers];
  Property Var_TRLDF : TVar read TRLDF write TRLDF;
  Property Var_TRLV : TVar read TRLV write TRLV;

  Property St_RTDEP : TState read RTDEP write RTDEP;
  Property St_RTWT : TState read RTWT write RTWT;
//  Property St_RTWTL[1..MaxLayers] : TState read RTWTL[1..MaxLayers] write RTWTL[1..MaxLayers];
  Property St_RTWTS : TState read RTWTS write RTWTS;
//  Property St_RTWTSL[1..MaxLayers] : TState read RTWTSL[1..MaxLayers] write RTWTSL[1..MaxLayers];


         // Parameters
  Property Par_RDGS1 : TPar read RDGS1 write RDGS1;
  Property Par_RDGTH : TPar read RDGTH write RDGTH;
  Property Par_RLIGP : TPar read RLIGP write RLIGP;
  Property Par_RLWR : TPar read RLWR write RLWR;
  Property Par_RSEN : TPar read RSEN write RSEN;
  Property Par_RTREF : TPar read RTREF write RTREF;
//  Property Par_SHF : TPar read SHF write SHF;
  Property Par_STDDAY : TPar read STDDAY write STDDAY;
  Property Par_PLTPOP : TPar read PLTPOP write PLTPOP;



         // Properties External Variables
  Property Ex_Temp     : TExternV read Temp write Temp;
  Property Ex_Carbo  : TExternV read Carbo write Carbo;
  Property Ex_PTF    : TExternV read PTF write PTF;
//  Property Ex_DLAYR  : TExternV read DLAYR write DLAYR;
  Property Ex_SWDF   : TExternV read SWDF write SWDF;

end;  // SubmodelName

procedure Register;

implementation

uses
  math;

procedure Tsubceresrootgrowth.createAll;

var
  i : integer;

begin
  inherited createAll;
  VarCreate('CARBOAR', '',0, true, CARBOAR);
  VarCreate('CUMDEP', '',0, true, CUMDEP);  
  VarCreate('GRORT', '',0, true, GRORT);
  VarCreate('RTDEPG', '',0, true, RTDEPG);
  VarCreate('RTWT_m2', '',0, true, RTWT_m2);
  VarCreate('RTWTG', '',0, true, RTWTG);
  VarCreate('RTWTGS', '',0, true, RTWTGS);
  VarCreate('TRLDF', '',0, true, TRLDF);
  VarCreate('TRLV', '',0, true, TRLV);
  for i := 1 to MaxLayers do begin
    if i <   10 then begin
      VarCreate('RLDF__'+inttostr(i), '',0, true, RLDF[i]);
      VarCreate('RLV__'+inttostr(i), '',0, true, RLV[i]);
      VarCreate('RTWTGL__'+inttostr(i), '',0, true, RTWTGL[i]);
      VarCreate('RTWTSLR__'+inttostr(i), '',0, true, RTWTSLR[i]);
      VarCreate('DLAYR__'+inttostr(i), '', 10, true, DLAYR[i]);
    end else begin
      VarCreate('RLDF_'+inttostr(i), '',0, true, RLDF[i]);
      VarCreate('RLV_'+inttostr(i), '',0, true, RLV[i]);
      VarCreate('RTWTGL_'+inttostr(i), '',0, true, RTWTGL[i]);
      VarCreate('RTWTSLR_'+inttostr(i), '',0, true, RTWTSLR[i]);
      VarCreate('DLAYR_'+inttostr(i), '',10, true, DLAYR[i]);
    end;
  end;


  StateCreate('RTDEP', '',0, true,RTDEP);
  StateCreate('RTWT', '',0, true,RTWT);
  StateCreate('RTWTS', '',0, true,RTWTS);

  for i := 1 to MaxLayers do begin
    if i <   10 then begin
      StateCreate('RTWTSL__'+inttostr(i), '',0, true,RTWTSL[i]);
      StateCreate('RTWTL__'+inttostr(i), '',0, true,RTWTL[i]);
    end else begin
      StateCreate('RTWTSL_'+inttostr(i), '',0, true,RTWTSL[i]);
      StateCreate('RTWTL_'+inttostr(i), '',0, true,RTWTL[i]);
    end;
  end;


  // Parameters
  ParCreate('RDGS1', '[cm/d]',3,RDGS1);
  ParCreate('RDGTH', '[doy]',275,RDGTH);
  ParCreate('RLIGP', '[%]',10,RLIGP);
  ParCreate('RLWR', '[cm/g]',20000,RLWR);
  ParCreate('RSEN', '[-]',0.008,RSEN);
  ParCreate('RTREF', '[-]',0.4,RTREF);
  ParCreate('STDDAY', '[°C]',20,STDDAY);
  ParCreate('PLTPOP', '[1/m2]', 250, PLTPOP);


  for i := 1 to MaxLayers do begin
    if i <   10 then begin
      ParCreate('SHF__'+inttostr(i), '', 1, SHF[i]);
    end else begin
      ParCreate('SHF_'+inttostr(i), '', 1, SHF[i]);
    end;
  end;




         // External Variable
  ExternVCreate('SDEPTH', '[cm]', Statefield, SDEPTH);
  ExternVCreate('Temp', '[°]', Statefield, Temp);
  ExternVCreate('Carbo', '', Statefield, Carbo);
  ExternVCreate('PTF', '', Statefield, PTF);
  ExternVCreate('SWDF', '',statefield, SWDF);

  for i := 1 to MaxLayers do
    ExternVCreate('Tiefe'+inttostr(i), '[cm]',statefield, Tiefe[i]);


end;


procedure Tsubceresrootgrowth.init(var GlobMod: TMod);

var
  i : integer;

begin
  inherited init(GlobMod);
  RTDEP.v := SDEPTH.v;
end;


procedure Tsubceresrootgrowth.CalcRates;

var
  i : integer;

begin
  for i := 1 to MaxLayers do
    DLAYR[i].v := 10;//Tiefe[i].v -Tiefe[i-1].v;


//   CARBOAR.v :=  CARBO.v*(1.0-PTF.v)/PLTPOP.v;
   CARBOAR.v :=  CARBO.v*(PTF.v)/PLTPOP.v;   // PTF redefined as AssiToFineRoot
   GRORT.v :=  CARBOAR.v;


   For i := 1 to maxlayers do begin
     If ((I)*DLAYR[i-1].v>RTDEP.v) and ((I-1)*DLAYR[i].v<CUMDEP.v) then
       RLDF[i].v := {SWDF.v*}SHF[i].v*DLAYR[i].v*(1.0-(CUMDEP.v-RTDEP.v)/DLAYR[i].v)
     else  If  (i-1)*DLAYR[i].v>=CUMDEP.v then
       RLDF[i].v :=   0
     else
       RLDF[i].v :=   {SWDF.v*}SHF[i].v*DLAYR[i].v;
   end;



   TRLDF.v := 0.0;
   For i := 1 to maxlayers do begin
     TRLDF.v :=  TRLDF.v + RLDF[i].v;
   end;


   For i := 1 to maxlayers do
     RLV[i].v :=  RTWTL[i].v*RLWR.v*PLTPOP.v/DLAYR[i].v/10000;
   RTDEPG.v :=  max(0,Temp.v)*RDGS1.v/STDDAY.v;
   RTWT_m2.v :=  RTWT.v*PLTPOP.v;
   RTWTG.v :=  GRORT.v * (1.0-RTREF.v);
   For i := 1 to maxlayers do
     if TRLDF.v > 0 then
       RTWTGL[i].v :=  (RLDF[i].v/TRLDF.v)*(RTWTG.v+RTWTGS.v)
     else
       RTWTGL[i].v := 0.0;
   RTWTGS.v :=  0;
   For i := 1 to maxlayers do
     RTWTSLR[i].v :=  RTWTL[i].v*RSEN.v;

   TRLV.v  := 0.0;
   For i := 1 to maxlayers do begin
     TRLV.v :=  TRLV.v + RLV[i].v;
   end;

   RTDEP.c :=  RTDEPG.v;

   RTWT.c := 0.0;
   For i := 1 to maxlayers do
     RTWT.c :=  RTWT.c + RTWTGL[i].v-RTWTSLR[i].v;

   For i := 1 to maxlayers do
     RTWTL[i].c :=  max(-RTWTL[i].v, RTWTGL[i].v - RTWTSLR[i].v);

   RTWTS.c := 0;
   For i := 1 to maxlayers do
     RTWTS.c :=  RTWTS.c + RTWTSLR[i].v;

   For i := 1 to maxlayers do
     RTWTSL[i].c :=  RTWTSLR[i].v;

end;


procedure Tsubceresrootgrowth.integrate;

begin
  inherited integrate;
  CUMDEP.v :=  max(0, min((((trunc(RTDEP.v) div trunc(DLAYR[1].v))+1)*DLAYR[1].v), DLAYR[1].v*MaxLayers));

end;



procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Tsubceresrootgrowth]);
end;

end.

