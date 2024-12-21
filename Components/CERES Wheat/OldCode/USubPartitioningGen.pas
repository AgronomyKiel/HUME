unit USubPartitioningGen;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   UMod, UState, UAbstractPlant;

Type

TSubPartitioningGen = class(TAbstractPlant)

private

protected
  function GetLAI:THumeNumEntity; override;
//  procedure SetLai(NewLAI:THumeNumEntity); override;
  function GetCropHeight:THumeNumEntity; override;
//  procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;


public

  Assiflow : TVar;    // total flux of assimliates for growth (CARBO+SEEDRV)
//  DLFWT : TVar;   //
//  EXLFW : TVar;   // old leaf weight from previous day [g/plant]

  CARBOred  : TVar;   // Reduction factor for assimilation during ripening [0..1]
  FFineroot     : TVar;   // fraction of assimilates allocated to fine roots
  GPP : TVar;     //   Number of grains per plant  [n]
  GPPvar : TVar;   //   Number of grains per plant  [g/plant]
  GPSM : TVar;     // Grains per square meter [g/m2]
  GrainSinkSize : TVar; // Potential sink strength of the grains
  GRNWT_m2 : TVar;   // Grain weight per square meter [g/m2]
  GROGRN : TVar;     // Daily growth of the grain - [g/(plant.d)]
  GROLF : TVar;      // Daily leaf growth [g/plant/d]
  GRORT : TVar;      // Daily root growth - [g/pl/d]
  GROSTM : TVar;     // Daily stem growth  [g/(plant.d]
  LFWT_m2 : TVar;    // leaf weight per square meter [g/m2]
  MyLAI         : TVar;   // copy of external leaf area index variable
  NcLeaf    : Tvar;     // Leaf N-concentration (%)
  NcShoot   : Tvar;     // Shoot N-concentration (%)
  NcStem    : Tvar;     // Stem N-concentration (%)
  NLeaf_m2     : TVar;  // Leaf N-amount (g/m²)
  NLeaf_pl     : TState;  // Leaf N-amount (g/Pflanze)
  NoptStem : Tvar;      // optimum N concentration (%)
  NShoot_m2    : TVar;  // Shoot N-amount (g/m²)
  NShoot_pl    : TState;  // Shoot N-amount (g/Pflanze)
  NStem_m2     : TVar;  // Stem N-amount (g/m²)
  NStem_pl     : TState;  // Stem N-amount (g/Pflanze)
  PTF : TVar;        // Fraction of photosynthesis partitioned to above ground plant parts [-]
  RGFILL : TVar;     // Rate of grain fill  [mg/(plant*day)]
  RTWT_m2 : TVar;    // root weight per square meter [g/m2]
  SENL_m2 : TVar;       // senscencent Leaf  [g/(plant.m2]
  SENSTM_m2 : TVar;     // senscencent Stem  [g/(plant.m2]
  STMWT_m2 : TVar;   // Stem weight per square meter [g/m2]
  SWMIN : TVar;      //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]
  TKM : TVar;        // Thousend kernel mass [g]
  TOPWT_m2 : TVar;   // weight of tops without grains [g/m2]
  TOPWT_pl : TVar;   // weight of tops without grains [g/plant]

  // Constant Variables
  G1 : TVar;   // Unscaled version of the Genetic specific constant related to rate of vegetative expansion growth during Stage 1
  G2 : TVar;   // Unscaled genetic specific constant related to the number of grains produced
  G3 : TVar;   // Unscaled Genetic coefficient for determining grain fill rate [mg/day]
  P2 : TVar;   // Thermal time between terminal spikelet and end of vegetative growth, equal to 3 phyllochron intervals [degree C days]
  P3 : TVar;   // Thermal time from terminal spikeltt end of pre-anthesis ear elongation growth, equal to 2 phyllochron intervals - degree C days

  SowingDensity : TPar;

  CUMPH : TState;   // cumulative phyllochrons since emergence [-]
  SEEDRV : TState;  // Reserve carbohydrates in seed for use by plant in seedling stage [g/plant]
  STMWT_pl : TState;   //  Stem weight of an average tiller after terminal spikelet  [g]
  GRNWT_pl : TState;   // Weight of grains [g/plant]
  LFWT_pl : TState;    // Leaf weight of all leaves on a plant [g/plant]
  RTWT_pl : TState;    //   Root weight - [g/plant]
  SENRT_pl : TState;   //  Senscent root mass [g/plant]
  SENSTM_pl : TState;  // Senescent stem mass [g/plant]
  SENLF_pl : TState;   // Senescent leaf weight [g/plant]
  SUMDTT5  : TState; // accumulated temperature sum during stage 5

  DMFineRoot : Tstate; //  Root weight - [g/m2]
  TEMPsum : TState;     // Temperature sum
  ReservePool : TState;   // ReservePool for Storage of Assimilates
  CropHeight : TState; // plant height [m]

             // Parameters
  Plants : TPar;   // number of plants per square meter
  h        : TPar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  g        : Tpar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  G1_      : Tpar;
  G2_      : TPar;
  G3_       : TPar;  // Genetic coefficient for determining grain fill rate

  pNcLeaf : TPar;  // Blatt N-Konzentration (%)
  NcStemVf1 : TPar; // Steigung der Stängel N-Verdünnungsfunktion
  NcStemVf2 : TPar;  // Intercept der Stängel N-Verdünnugsfunktion
  DMStemcrit :TPar;  // Stängeltrockenmasse bei der max N-Konz.erreicht (g/m²)
  EC_LGend : TPar; // end EC for leaf growth
  k_SEEDRV : TPar; // mobilisation constant for seed reseves
  INI_LFWT_pl : TPar; // initial leaf weight per plant at emergence (g/pl)
  Ini_SEEDRV : TPar; // initial seed weight (g/pl)


             // External Variables
  LAI : TExternV;   // leaf area index
  AWR : TExternV;   // average weight ratio i.e. specific leaf area (cm/g)
  SENLA : TExternV; // senescent leaf area

  CARBO : TExternV;    //  Daily carbohydrate production (g/pl/d)
  DTT : TExternV;      //
  ISTAGE : TExternV;   // Development stage according do CERES
//  ndef2 : TExternV;   //
  PHINT : TExternV;   //  Phyllochron interval
  PLA : TExternV;   //  Plant leaf area (m2/pl)
  PLAGMS : TExternV;   //  Plant leaf area on main stem (m2/pl)
  SUMDTT2 : TExternV;   // SUMDTT2 : TExternV;   // temperature sumd in ISTAGE 2
  swdf1  : TExternV;   // soil water deficit factor
  TEMPM  : TExternV;   //  average daily air temperature
  tempmn : TExternV;   // minimum daily air temperature
  tempmx : TExternV;   // maximum daily air temperature
  TI     : TExternV;   // Fraction of a phyllochron interval which occurred as a fraction of today's daily thermal time
  TILN   : TExternV;   // Time delayed reduced tiller number [n/plant]
  EC     : TExternV;   //  EC-Stage
  P5     : TExternV;   // Parameter for duration of grain filling stage

  Leaf_Stem_proc : TOption; // Option for leaf/stem partitioning


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;

  procedure calc_rootDM; virtual;
  procedure Allometric_Leaf_Stem_Partitioning; virtual;
  procedure CERES_Leaf_Stem_Partitioning; virtual;




published
//  Property Var_DLFWT : TVar read DLFWT write DLFWT;
//  Property Var_EXLFW : TVar read EXLFW write EXLFW;
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
  Property Var_SENL : TVar read SENL_m2 write SENL_m2;
  Property Var_STMWT_m2 : TVar read STMWT_m2 write STMWT_m2;
  Property Var_SWMIN : TVar read SWMIN write SWMIN;

  Property Var_TKM : TVar read TKM write TKM;
  Property Var_TOPWT : TVar read TOPWT_pl write TOPWT_pl;
  Property Var_TOPWT_m2 : TVar read TOPWT_m2 write TOPWT_m2;
  Property Var_AssiFlow : TVar read Assiflow write Assiflow;
  property Var_NShoot_m2 : TVar read NShoot_m2 write NShoot_m2;
  Property Var_GrainSinksize : TVar read GrainSinkSize write GrainSinksize;

  Property St_CUMPH : TState read CUMPH write CUMPH;
  Property St_GRNWT : TState read GRNWT_pl write GRNWT_pl;
  Property St_LFWT : TState read LFWT_pl write LFWT_pl;
  Property St_RTWT : TState read RTWT_pl write RTWT_pl;
  Property St_SEEDRV : TState read SEEDRV write SEEDRV;
  Property St_SENLF : TState read SENLF_pl write SENLF_pl;
  Property St_SENRT : TState read SENRT_pl write SENRT_pl;
  Property St_SENSTM : TState read SENSTM_pl write SENSTM_pl;
  Property St_STMWT : TState read STMWT_pl write STMWT_pl;
  Property St_TempSum : TState read TempSum write TempSum;
  Property St_DMFineRoot : TState read DMFineRoot write DMFineRoot;
  Property St_CropHeight : TState read CropHeight write CropHeight;

         // Parameters
  Property Par_G1_ : TPar read G1_ write G1_;
  Property Par_G2_ : TPar read G2_ write G2_;
  Property Par_G3_ : TPar read G3_ write G3_;
  Property Par_Plants : TPar read Plants write Plants;
  property Par_h  : TPar read h write h ;   { Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_g  : Tpar read g write g;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_SowingDensity : TPar read SowingDensity write SowingDensity;
  property Par_EC_LGend : TPar read EC_LGend write EC_LGend;
  property Par_k_SEEDRV : TPar read k_SEEDRV write k_SEEDRV; // mobilisation constant for seed reseves
  property Par_INI_LFWT_pl : TPar read INI_LFWT_pl write INI_LFWT_pl; // initial leaf weight per plant at emergence (g/pl)
  property Par_Ini_SEEDRV : TPar read Ini_SEEDRV  write Ini_SEEDRV;  // initial seed weight (g/pl)


         // Properties External Variables
  Property Ex_CARBO : TExternV read CARBO write CARBO;
  Property Ex_DTT : TExternV read DTT write DTT;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
//  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
  Property Ex_PHINT : TExternV read PHINT write PHINT;
  Property Ex_PLAGMS : TExternV read PLAGMS write PLAGMS;
  Property Ex_SENLA : TExternV read SENLA write SENLA;
  Property Ex_SUMDTT2 : TExternV read SUMDTT2 write SUMDTT2;
  Property Ex_swdf1 : TExternV read swdf1 write swdf1;
  Property Ex_TEMPM : TExternV read TEMPM write TEMPM;
  Property Ex_tempmn : TExternV read tempmn write tempmn;
  Property Ex_tempmx : TExternV read tempmx write tempmx;
  Property Ex_TI : TExternV read TI write TI;
  Property Ex_TILN : TExternV read TILN write TILN;
//  Property Ex_SowingDate : TExternV read Sowingdate write Sowingdate; //

  property Var_FFineRoot : TVar read FFineRoot write FFineroot;
  property Ex_EC  : TExternv read EC write EC;
  Property Ex_LAI : TExternV read LAI write LAI;
  Property Ex_AWR : TExternV read AWR write AWR;

  property Opt_Leaf_Stem_proc : TOption read Leaf_Stem_proc write Leaf_Stem_proc;

end;  // SubmodelName

procedure Register;

implementation

uses math;

function TSubPartitioningGen.GetCropHeight:THumeNumEntity;

begin
  result := CropHeight;
end;

{procedure TSubPartitioningGen.SetCropHeight(NewCropHeight:THumeNumEntity);

begin
  p_CropHeight := NewCropHeight;
end;}

function TSubPartitioningGen.GetLAI:THumeNumEntity;

begin
   result := MyLAI

end;

{procedure TSubPartitioningGen.SetLai(NewLAI:THumeNumEntity);

begin
  p_LAI := NewLAI;
end;}


procedure TsubpartitioningGen.createAll;

begin
  inherited createAll;
//  VarCreate('DLFWT', '',0, true, DLFWT);
//  VarCreate('EXLFW', '',0, true, EXLFW);
  VarCreate('CarboRed', '[-]',0, true, CarboRed);
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
  VarCreate('SENL_m2', '[g/(plant.d]',0, true, SENL_m2);
  VarCreate('STMWT_m2', '[g/m2]',0, true, STMWT_m2);
  VarCreate('SWMIN', '[g/plant]',0, true,SWMIN);

  VarCreate('SENSTM_m2', '[g/plant]',0, true, SENSTM_m2);
  VarCreate('TKM', '[g]',0, true, TKM);
  VarCreate('TOPWT_pl', '[g/plant]',0, true, TOPWT_pl);
  VarCreate('TOPWT_m2', '[g/m2] ',0, true, TOPWT_m2);
  VarCreate('FFINEROOT', '[-]', 0, true, FFineRoot);
  VarCreate('Assiflow', '[g/m2/d]', 0, true, Assiflow);
  VarCreate('MyLAI', '', 0, true, MyLAI);
  VarCreate('GrainSinkSize', '', 0, true, GrainSinkSize);

  VarCreate('NLeaf', '[g/m2]',0,true, NLeaf_m2);
  VarCreate('NStem', '[g/m2]',0,true,NStem_m2);
  VarCreate('NShoot_m2', '[g/m2]',0,true,NShoot_m2);
  VarCreate('NcLeaf', '[%]', 0, true, NcLeaf);
  VarCreate('NcStem', '[%]', 0, true, NcStem);
  VarCreate('NcShoot', '[%]', 0, true, NcShoot);
  VarCreate('NoptStem', '[%]', 0, true, NoptStem);

  VarCreate('G1', '',0, true, G1);
  VarCreate('G2', '',0, true, G2);
  VarCreate('G3', '',0, true, G3);
  VarCreate('p2', '',0, true, P2);
  VarCreate('P3', '',0, true, P3);


  StateCreate('CUMPH', '[-]',0, true,CUMPH);
  StateCreate('GRNWT_pl', '[g/plant]',0, true,GRNWT_pl);
  StateCreate('LFWT_pl', '[g/plant]',0, true,LFWT_pl);
  StateCreate('RTWT_pl', '[g/plant]',0, true,RTWT_pl);
  StateCreate('SEEDRV', '[g/plant]',0, true,SEEDRV);
  StateCreate('SENLF_pl', '[g/plant]',0, true,SENLF_pl);
  StateCreate('SENRT_pl', '[g/plant]',0, true, SENRT_pl);
  StateCreate('SENSTM_pl', '[g/plant]',0, true, SENSTM_pl);
  StateCreate('STMWT_pl', '[g]',0, true,STMWT_pl);
  StateCreate('TempSum', '[g/plant]',0, true, TempSum);
  StateCreate('DMFineRoot', '[g/m2]', 0,true, DMFineRoot);
  StateCreate('CropHeight', '[m]', 0,true, CropHeight);
  StateCreate('SUMDTT5', '[°Cd]', 0,true, SUMDTT5);

  StateCreate('NLeaf_pl', '[g/plant]',0,true, NLeaf_pl);
  StateCreate('NStem_pl', '[g/plant]',0,true,NStem_pl);
  StateCreate('NShoot_pl', '[g/plant]',0,true,NShoot_pl);



  // Parameters
  ParCreate('G1_', '[-]',6, G1_);
  ParCreate('G2_', '[-]',3.3, G2_);
  ParCreate('G3_', '[mg/day]',4.5, G3_);
  ParCreate('Plants', '[plants/m2]',350, Plants);
  ParCreate('h','[-]', -0.6864, h);
  ParCreate('g','[-]', 1.3129, g);
  ParCreate('SowingDensity', '[1/m2]', 320, sowingdensity);

  ParCreate('pNcLeaf','[%]', 5.2, pNcLeaf);
  ParCreate('NcStemVf1','[-]', -1.2553, NcStemVf1);
  ParCreate('NcStemVf2','[-]', 9.3325, NcStemVf2);
  ParCreate('DMStemcrit','[g/m2]', 30, DMStemcrit);
  ParCreate('EC_LGend','[-]', 34, EC_LGend);
  ParCreate('k_SEEDRV','[-]', 0.15, k_SEEDRV); // mobilisation constant for seed reserves
  ParCreate('INI_LFWT_pl','[-]', 0.00034, INI_LFWT_pl);
  ParCreate('Ini_SEEDRV','[-]', 0.05, Ini_SEEDRV);

         // External Variable
  ExternVCreate('CARBO', '',statefield, CARBO);
  ExternVCreate('DTT', '',statefield, DTT);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
//  ExternVCreate('ndef2', '',statefield, ndef2);
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
  ExternVCreate('EC', '', statefield, EC);
  ExternVCreate('LAI', '', statefield, LAI);
  ExternVCreate('AWR', '', statefield, AWR);
  ExternVCreate('P5', '', statefield, P5);

  OptCreate('Leaf_Stem_proc', 'Allometric', Leaf_Stem_proc);
  Leaf_Stem_proc.OptionList.Add('Allometric');
  Leaf_Stem_proc.OptionList.Add('CERES');


end;


procedure TsubpartitioningGen.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);

  G1.v :=  5.+G1_.v*5.;
  G2.v :=  0.65+G2_.v*0.35;
  G3.v :=  -0.005+G3_.v*0.35;
  P2.v :=  PHINT.v*3;
  P3.v :=  PHINT.v*2;
  gpp.v := 1; // just one seed
  SWMIN.v:=0.0;

end;

procedure TSubPartitioningGen.calc_rootDM;

begin
   If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  PTF.v :=   0.5
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  PTF.v :=   0.70
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  PTF.v :=   0.75
   else If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  PTF.v :=   0.8
   else IF (ISTAGE.v>=5) and (ISTAGE.v < 9) then
     if (stmwt_pl.v>0) then
       PTF.v:=min(1, SWMIN.v/STMWT_pl.v*0.35+0.65)
   else
   PTF.v :=   0.0  ;

    FFineRoot.v := 1-PTF.v;

    If FFineRoot.v < 0 then
       FFineroot.v := 0.0;
    GRORT.v    := ffineroot.v*Assiflow.v;
    SENRT_pl.c := 0.005*RTWT_pl.v;
    RTWT_pl.c  :=   0.6*GRORT.v-SENRT_pl.c  ;

    DMfineroot.C := RTWT_pl.c  *Plants.v; // per m2
    Assiflow.v := Assiflow.v-GRORT.v; // substract root growth

end;


procedure TSubPartitioningGen.Allometric_Leaf_Stem_Partitioning;

begin
    If  (PLA.v>0)and(ISTAGE.v>=1)and(ISTAGE.v<6) then begin             // calculation of leaf death rate (g/pl/d)
      SENLF_pl.c := LFWT_pl.v*0.000267*DTT.v*(1.-SENLA.v/PLA.v);
    end
    else begin
      SENLF_pl.c := 0;
    end;

   If  (ISTAGE.v>=1)and(ISTAGE.v<6)                          // calculation of stem death rate (g/pl/d)
     then  SENSTM_pl.c :=   STMWT_pl.v*0.000267*DTT.v
   else  SENSTM_pl.c :=   0  ;

    If (EC.v < EC_LGend.v) and (ISTAGE.v >=1) and (STMWT_pl.v >0) then begin
      GROSTM.v :=  assiflow.v* (1-1/(1+exp(h.v/Plants.v)*power(STMWT_pl.v, g.v - 1)*g.v));

      STMWT_pl.c :=  GROSTM.v-SENSTM_pl.c-GROGRN.v;

      GROLF.v := Assiflow.v-GROSTM.v
      end
    else begin
      STMWT_pl.c := Assiflow.v-SENSTM_pl.c-GROGRN.v;
      GROLF.v    := 0.0;
    end;

    LFWT_pl.c :=  GROLF.v-SENLF_pl.c;



end;


procedure TSubPartitioningGen.CERES_Leaf_Stem_Partitioning;

begin

   If  (PLA.v>0)and(ISTAGE.v<6)and(ISTAGE.v>=1)
     then  SENLF_pl.c :=   LFWT_pl.v*0.000267*DTT.v*(1.-SENLA.v/PLA.v)
   else  SENLF_pl.c :=   0  ;



   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then
       if AWR.v > 0
     then  GROLF.v :=   min((PLAGMS.v*(0.3+0.7*TILN.v))/AWR.v, CARBO.v*0.65+SEEDRV.v)
   else  If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  GROLF.v :=   CARBO.v-GRORT.v-GROSTM.v
   else  GROLF.v :=   0  ;

   If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  GROSTM.v :=  (0.15+0.12*SUMDTT2.v/PHINT.v)*CARBO.v*PTF.v
   else  If  (ISTAGE.v>=3)and(ISTAGE.v<5)
     then  GROSTM.v :=   CARBO.v*PTF.v
   else  If  (ISTAGE.v>=5)and(ISTAGE.v<6)
     then  GROSTM.v :=   CARBO.v*PTF.v-GROGRN.v
   else  GROSTM.v :=   0;
end;



procedure TSubPartitioningGen.CalcRates;

var
  TMPM : real;

begin

  TMPM := (TeMPMN.v + TeMPMX.v)/2;   // average day temperature
  If (ISTAGE.v >= 5) and (ISTAGE.v < 6) then
    SUMDTT5.c := DTT.v
  else
    SUMDTT5.c := 0.0;


  If  (ISTAGE.v>=5)and(ISTAGE.v<6)and(stmwt_pl.v>0)
     then  CARBOred.v :=  max(0,(1.-(1.2-0.8*SWMIN.v/stmwt_pl.v)*(sumdtt5.v+100.0)/((430+p5.v*20)+100.0)))
  else  CARBOred.v :=   1  ;

  Assiflow.v := Carbo.v*CarboRed.v;


  If GlobTime.v >= SowingDate.v then begin
      If TMPM > 0.0 then
        TempSum.c := TMPM        // rate of change of temperature sum
      else TempSum.c  := 0.0;
  end;

  If  (ISTAGE.v>=1)and (ISTAGE.v<2) then
     CUMPH.c :=  dtt.v/PHINT.v       // rate of change of cumulative phyllochron
   else  CUMPH.c :=   0  ;


  If  (ISTAGE.v>=0.99)and(ISTAGE.v<2)and(SEEDRV.v>0) then
    begin
      SEEDRV.c   :=   -k_SEEDRV.v*Seedrv.v;
      Assiflow.v := Assiflow.v+k_SEEDRV.v*Seedrv.v;
    end
  else  SEEDRV.c :=   0;


   RGFILL.v :=  0;
   If (ISTAGE.v>=5)and(ISTAGE.v<6) then
    if (TEMPM.v<10) then
       RGFILL.v :=   0.065*TEMPM.v
    else
      RGFILL.v :=   0.65+(0.0787-0.00328*(tempmx.v-tempmn.v))*(power((tempmx.v-10.0),0.8));

   GROGRN.v := 0;
   If  (ISTAGE.v>=5)and(ISTAGE.v<6) then
      if (CARBO.v*PTF.v<RGFILL.v*GPP.v*G2.v*0.001)and(STMWT_pl.v<SWMIN.v)
        then
          GROGRN.v :=   CARBO.v*PTF.v
        else
          GROGRN.v :=   RGFILL.v*GPP.v*G2.v*0.001;


   GRNWT_pl.c :=  GROGRN.v;

  Calc_RootDM;

  // Leaf-Stem Partitioning
  Allometric_Leaf_Stem_Partitioning;
  // CERES__Leaf_Stem_Partitioning;



    If STMWT_m2.v >= DMSTEMcrit.v then begin
      NoptStem.v := (NcStemVf1.v * ln(STMWT_m2.v) + NcStemVf2.v);   // calculation of optimum N-concentration
      NStem_pl.c := STMWT_pl.c*(NoptStem.v+NcStemVf1.v)/100
    end else begin
      NoptStem.v := (NcStemVf1.v * ln(DMSTEMcrit.v) + NcStemVf2.v);
      NStem_pl.c := STMWT_pl.c*(NoptStem.v+NcStemVf1.v)/100
    end;


end;


procedure TSubPartitioningGen.Integrate;

begin
//  Exlfw.V := LFWT_pl.v;

  inherited  integrate;
  MyLAI.v := LAI.v;

  If (ISTAGE.v>=1) and (LFWT_pl.v<=0) then begin
    LFWT_pl.v   := INI_LFWT_pl.v;                      // Initialize stem weight
    NLeaf_pl.v  := LFWT_pl.v*pNcLeaf.v;
    STMWT_pl.v  := exp(g.v*ln(LFWT_pl.v)+h.v);         // Initialize stem weight
    SEEDRV.v    := Ini_SEEDRV.v;// 0.05; // 0.012;
    NStem_pl.v  := STMWT_pl.v * (NcStemVf1.v * ln(DMStemcrit.v/plants.v) + NcStemVf2.v);
    NShoot_pl.v := NLeaf_pl.v + NStem_pl.v;
  end;

  CropHeight.v := LAI.v/5+0.05; // first proxy for crop height

  If (ISTAGE.v>=4) and (SWMIN.v<=0) then begin
    SWMIN.v := STMWT_pl.v;                        // save value of Stemweight for labile
  end;

  If (ISTAGE.v>=5) and (gpp.v<=1) then begin
     // Calculation of Grain Number
     GPP.v :=  STMWT_pl.v*G1.v;
     GPSM.v :=  GPP.v*PLANTS.v;
     grnwt_pl.v  := 0.0035*gpp.v;                  // Initialize Grains
     STMWT_pl.v := STMWT_pl.v-GRNWT_pl.v;                //
  end;

  TOPWT_pl.v :=  LFWT_pl.v+STMWT_pl.v+SEEDRV.v;    // top weight per plant

  STMWT_m2.v :=  STMWT_pl.v*Plants.v;
  SENSTM_m2.v := SENSTM_pl.v*Plants.v;
  GRNWT_m2.v :=  GRNWT_pl.v*Plants.v;

  LFWT_m2.v :=  LFWT_pl.v*Plants.v;

  RTWT_m2.v :=  RTWT_pl.v*plants.v;

  TOPWT_m2.v :=  GRNWT_m2.v+LFWT_m2.v+STMWT_m2.v;

  If  gpsm.v>0 then
     TKM.v := GRNWT_m2.v/gpsm.v*1000           // calculate thausend kernel weight
  else  TKM.v :=   0;

  NcLeaf.v := pNcLeaf.v;  // konstante Blatt N-Konzentration

  NLeaf_pl.v := LFWT_pl.v * NcLeaf.v/100;
  NLeaf_m2.v := LFWT_m2.v * NcLeaf.v/100;
  NSTEM_m2.v := NStem_pl.v*plants.v;

  NShoot_pl.v := NLeaf_pl.v + NStem_pl.v;
  NShoot_m2.v := NShoot_pl.v*plants.v;
  if TOPWT_m2.v>0 then NcShoot.v := NShoot_pl.v/TOPWT_m2.v*100 else NcShoot.v := 0;
end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningGen]);
end;

end.
