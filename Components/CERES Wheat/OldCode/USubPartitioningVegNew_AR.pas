unit USubPartitioningVegNew_AR;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   UMod, UState, UAbstractPlant;

Type
TDroughtImpact = (DroughtImpact, NoDroughtImpact);
TLeaf_Stem_proc = (Allometric, CERES);

TSubPartitioningVegNew = class(TAbstractPlant)

private
  fDroughtImpact : TDroughtImpact;
  fLeaf_Stem_proc : TLeaf_Stem_proc;


protected
  function GetLAI:THumeNumEntity; override;
  procedure SetLai(NewLAI:THumeNumEntity); override;
  function GetCropHeight:THumeNumEntity; override;
  procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;


public
(*  DLFWT : TVar;   //
  EXLFW : TVar;   // old leaf weight from previous day [g/plant]
  GPP : TVar;     //   Number of grains per plant  [n]
  GPPvar : TVar;   //   Number of grains per plant  [g/plant]
  GPSM : TVar;     // Grains per square meter [g/m2]
  GRNWT_m2 : TVar;   // Grain weight per square meter [g/m2]
  GROGRN : TVar;     // Daily growth of the grain - [g/(plant.d)]*)
  GROLF : TVar;      // Daily leaf growth [g/plant/d]
  GRORT : TVar;      // Daily root growth - [g/pl/d]
  GROSTM : TVar;     // Daily stem growth  [g/(plant.d]
  LFWT_m2 : TVar;    // leaf weight per square meter [g/m2]
  PTF : TVar;        // Fraction of photosynthesis partitioned to above ground plant parts [-]
//  RGFILL : TVar;     // Rate of grain fill  [mg/(plant*day)]
  RTWT_m2 : TVar;    // root weight per square meter [g/m2]
  SENL : TVar;       // Leaf senscence rate [g/(plant.d]
  SENRT_pl : TVar;   //  Senscent root mass [g/plant]
  SENSTM_pl : TVar;   // Senescent stem mass [g/plant]
  DMTrans_pl  : TVar;  // translozierbare Trockenmasse (g/Pflanze)
  STMWT_m2 : TVar;   // Stem weight per square meter [g/m2]
  SENWT_m2 : TVar;   // Dead Leaf weight per square meter [g/m2]
//  TKM : TVar;   // Thausend kernel mass [g]
  TOPWT_pl : TVar;   // weight of tops without grains [g/plant]
  TOPWT_m2 : TVar;   //
  FFineroot     : TVar;   // fraction of assimilates allocated to fine roots
  MyLAI         : TVar;   // copy of external leaf area index variable
  Assiflow : TVar; // total flux of assimliates for growth (CARBO+SEEDRV)
  fStem    : TVar; // fraction of shoot growth into stem dry matter
//  GrainSinkSize : TVar; // Potential sink strength of the grains
  NLeaf_pl     : TState;  // Blatt N-Menge (g/Pflanze)
  NStem_pl     : TState;  // Stängel N-Menge (g/Pflanze)
  NStoragepool_pl : TState; // intermediate storage pool (g N/pl)
  NStoragepool_m2 : TVar; // intermediate storage pool (g/m²)
  NShoot_pl    : TState;  // Spross N-Menge (g/Pflanze)
  NTrans_pl    : TVar;    // translozierbare N-Menge (g/Pflanze)
  NLeaf_m2     : TVar;  // Blatt N-Menge (g/m²)
  NStem_m2     : TVar;  // Stängel N-Menge (g/m²)
  NShoot_m2    : TVar;  // Spross N-Menge (g/m²)
  NDemand  : TVar; // nitrogen demand (kg/ha/d)
  NcLeaf    : Tvar;  // Blatt N-Konzentration (%)
  NcStem    : Tvar;  // Stängel N-Konzentration (%)
  NcShoot   : Tvar;  // Spross N-Konzentration (%)

  NoptStem : Tvar; // optimum N concentration stem(%)
  NoptLeaf : Tvar; // optimum N concentration leaf(%)

  // Constant Variables
//  G1 : TVar;   // Unscaled version of the Genetic specific constant related to rate of vegetative expansion growth during Stage 1
//  G2 : TVar;   // Unscaled genetic specific constant related to the number of grains produced
  G3 : TVar;   // Unscaled Genetic coefficient for determining grain fill rate [mg/day]
//  P2 : TVar;   // Thermal time between terminal spikelet and end of vegetative growth, equal to 3 phyllochron intervals [degree C days]
//  P3 : TVar;   // Thermal time from terminal spikeltt end of pre-anthesis ear elongation growth, equal to 2 phyllochron intervals - degree C days

  SowingDensity : TPar;

  CUMPH : TState;   // cumulative phyllochrons since emergence [-]
  GPPend : TState;  //  final grain number per plant
//  GRNWT : TState;   // Weight of grains [g/plant]
  NcLeafWinter : TState; // N conc. Leaf Winter (%) Strahlungsabhängig
  NcStemWinter : TState; // N conc. Stem Winter (%) Strahlungsabhängig
  LFWT_pl : TState;    // Leaf weight of all leaves on a plant [g/plant]
  RTWT_pl : TState;    //   Root weight - [g/plant]
  DMFineRoot : Tstate; //  Root weight - [g/m2]
  SEEDRV : TState;  // Reserve carbohydrates in seed for use by plant in seedling stage [g/plant]
  SENLF_pl : TState;   // Senescent leaf weight [g/plant]
  STMWT_pl : TState;   //  Stem weight of an average tiller after terminal spikelet  [g]
//  SWMIN : TState;   //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]
  TEMPsum : TState; // Temperature sum
//  ReseverePool : TState; // ReservePool for Storage of Assimilates
  PLA : TSTATE;   // leaf area per plant
  CropHeight : TState; // plant height [m]
  LAI2000 : TState; //LAI2000 Messwert aus Updatemethode von TSubModel

             // Parameters
  Plants : TPar;   // number of plants per square meter
  h        : TPar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  g        : Tpar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  STFR1    : Tpar; // Fraction of Drymatter allocated to stem at Xstage=1
  STFR2    : Tpar; // Fraction of Drymatter allocated to stem at Xstage=2
  G3_       : TPar;  // Genetic coefficient for determining grain fill rate

  pNcLeaf : TPar;  // Blatt N-Konzentration (%)
  ECcritNcLeaf : TPar; // kritisches EC-Stadium bis zu dem N-Konz.= NcLeafWinter
  rgr_NcLeafWinter : TPar; // Zuwachsrate für die Blatt N-Konzentration im Winter
  rgr_NcStemWinter : TPar; // Zuwachsrate für die Stängel N-Konzentration im Winter
  NcStem_a : TPar; // Parameter für Stängel N-Verdünnungsfunktion
  NcStem_b : TPar;  // Parameter für Stängel N-Verdünnungsfunktion
  NcLeafMin : TPar; //  niedrigste Blatt N-Konzentration bis Frühjahr (%)
  NcStemMin : TPar; //  niedrigste Stängel N-Konzentration (%)
  NcLeafVf1 : TPar; // Steigung der Leaf N-Verdünnungsfunktion
  NcLeafVf2 : TPar;  // Intercept der Leaf N-Verdünnugsfunktion
  NcTrans   : TPar;  // translozierbarer N-Anteil der seneszenten Trockenmasse (%)
  DMStemcrit :TPar;  // Stängeltrockenmasse bei der max N-Konz.erreicht (g/m²)
  DMLeafcrit :TPar;  // Blatttrockenmasse bei der max N-Konz.erreicht (g/m²)
  pDMTrans   : TPar; // translozierbarer Anteil der seneszenten Trockenmasse (%)
  EC_LGend : TPar; // end EC for leaf growth
  k_SEEDRV : TPar; // mobilisation constant for seed reseves
  INI_LFWT_pl : TPar; // initial leaf weight per plant at emergence (g/pl)
  Ini_SEEDRV : TPar; // initial seed weight (g/pl)

    fFineRoot0    : TPar;
    FFineRootDec  : TPar;



             // External Variables

  LAI : TExternV;   // leaf area index
  AWR : TExternV;   // average weight ratio i.e. specific leaf area (cm/g)

  CARBO : TExternV;    //  Daily carbohydrate production (g/pl/d)
  DTT : TExternV;      //
  ISTAGE : TExternV;   // Development stage according do CERES
  XSTAGE : TExternV; //   Development stage according do CERES
//  ndef2 : TExternV;   //
  PHINT : TExternV;   //  Phyllochron interval
//  PLA : TExternV;   //  Plant leaf area (m2/pl)
  PLAGMS : TExternV;   //  Plant leaf area on main stem (m2/pl)
  SUMDTT2 : TExternV;   // SUMDTT2 : TExternV;   // temperature sumd in ISTAGE 2
  swdf1  : TExternV;   // soil water deficit factor
  TEMPM  : TExternV;   //  average daily air temperature
  tempmn : TExternV;   // minimum daily air temperature
  tempmx : TExternV;   // maximum daily air temperature
  TI     : TExternV;   // Fraction of a phyllochron interval which occurred as a fraction of today's daily thermal time
  TILN   : TExternV;   // Time delayed reduced tiller number [n/plant]
  EC     : TExternV;   //  EC-Stage
  Transratio     : TExternV;
  DayOfYear : TExternV;
  GlobRad : TExternV;
  Leaf_Stem_proc : TOption; // Option for leaf/stem partitioning
  OptDroughtimpact : Toption;


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;

  procedure calc_rootDM; virtual;
  procedure Allometric_Leaf_Stem_Partitioning; virtual;
  procedure CERES_Leaf_Stem_Partitioning; virtual;
  procedure UpdateValues; override;



published
//  Property Var_DLFWT : TVar read DLFWT write DLFWT;
//  Property Var_EXLFW : TVar read EXLFW write EXLFW;
//  Property Var_GPP : TVar read GPP write GPP;
//  Property Var_GPPvar : TVar read GPPvar write GPPvar;
//  Property Var_GPSM : TVar read GPSM write GPSM;
//  Property Var_GRNWT_m2 : TVar read GRNWT_m2 write GRNWT_m2;
//  Property Var_GROGRN : TVar read GROGRN write GROGRN;
  Property Var_GROLF : TVar read GROLF write GROLF;
  Property Var_GRORT : TVar read GRORT write GRORT;
  Property Var_GROSTM : TVar read GROSTM write GROSTM;
  Property Var_LFWT_m2 : TVar read LFWT_m2 write LFWT_m2;
  Property Var_PTF : TVar read PTF write PTF;
//  Property Var_RGFILL : TVar read RGFILL write RGFILL;
  Property Var_RTWT_m2 : TVar read RTWT_m2 write RTWT_m2;
  Property Var_SENL : TVar read SENL write SENL;
  Property Var_SENRT : TVar read SENRT_pl write SENRT_pl;
  Property Var_SENSTM : TVar read SENSTM_pl write SENSTM_pl;
  Property Var_STMWT_m2 : TVar read STMWT_m2 write STMWT_m2;
  Property Var_SENWT_m2 : TVar read SENWT_m2 write SENWT_m2;
//  Property Var_TKM : TVar read TKM write TKM;
  Property Var_TOPWT : TVar read TOPWT_pl write TOPWT_pl;
  Property Var_TOPWT_m2 : TVar read TOPWT_m2 write TOPWT_m2;
  Property Var_AssiFlow : TVar read Assiflow write Assiflow;
  property Var_NShoot_m2 : TVar read NShoot_m2 write NShoot_m2;
  property Var_Demand : TVar read NDemand write NDemand;
//  Property Var_GrainSinksize : TVar read GrainSinkSize write GrainSinksize;

  Property St_CUMPH : TState read CUMPH write CUMPH;
//  Property St_GPPend : TState read GPPend write GPPend;
//  Property St_GRNWT : TState read GRNWT write GRNWT;
  Property St_LFWT : TState read LFWT_pl write LFWT_pl;
  Property St_RTWT : TState read RTWT_pl write RTWT_pl;
  Property St_SEEDRV : TState read SEEDRV write SEEDRV;
  Property St_SENLF : TState read SENLF_pl write SENLF_pl;
  Property St_STMWT : TState read STMWT_pl write STMWT_pl;
//  Property St_SWMIN : TState read SWMIN write SWMIN;
  Property St_TempSum : TState read TempSum write TempSum;
  Property St_DMFineRoot : TState read DMFineRoot write DMFineRoot;
  Property St_CropHeight : TState read CropHeight write CropHeight;
  Property St_LAI2000 : TState read LAI2000 write LAI2000;

         // Parameters
//  Property Par_G1_ : TPar read G1_ write G1_;
//  Property Par_G2_ : TPar read G2_ write G2_;
  Property Par_G3_ : TPar read G3_ write G3_;
  Property Par_Plants : TPar read Plants write Plants;
  property Par_h  : TPar read h write h ;   { Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_g  : Tpar read g write g;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_SowingDensity : TPar read SowingDensity write SowingDensity;
  property Par_EC_LGend : TPar read EC_LGend write EC_LGend;
  property Par_k_SEEDRV : TPar read k_SEEDRV write k_SEEDRV; // mobilisation constant for seed reseves
  property Par_INI_LFWT_pl : TPar read INI_LFWT_pl write INI_LFWT_pl; // initial leaf weight per plant at emergence (g/pl)
  property Par_Ini_SEEDRV : TPar read Ini_SEEDRV  write Ini_SEEDRV;  // initial seed weight (g/pl)
  property Par_FFineRoot0 : TPar read FFineRoot0 write FFineroot0;
  property Par_FFineRootDec : TPar read FFineRootDec write FFinerootDec;


         // Properties External Variables
  Property Ex_CARBO : TExternV read CARBO write CARBO;
  Property Ex_DTT : TExternV read DTT write DTT;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
//  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
  Property Ex_PHINT : TExternV read PHINT write PHINT;
  Property Ex_PLAGMS : TExternV read PLAGMS write PLAGMS;
//  Property Ex_SENLA : TExternV read SENLA write SENLA;
  Property Ex_SUMDTT2 : TExternV read SUMDTT2 write SUMDTT2;
  Property Ex_swdf1 : TExternV read swdf1 write swdf1;
  Property Ex_TEMPM : TExternV read TEMPM write TEMPM;
  Property Ex_tempmn : TExternV read tempmn write tempmn;
  Property Ex_tempmx : TExternV read tempmx write tempmx;
//  Property Ex_TI : TExternV read TI write TI;
//  Property Ex_TILN : TExternV read TILN write TILN;
//  Property Ex_SowingDate : TExternV read Sowingdate write Sowingdate; //

  property Var_FFineRoot : TVar read FFineRoot write FFineroot;
  property Ex_EC  : TExternv read EC write EC;
  Property Ex_LAI : TExternV read LAI write LAI;
  Property Ex_AWR : TExternV read AWR write AWR;
  Property Ex_Transratio : TExternV read Transratio write Transratio;
  Property Ex_DayOfYear : TExternV read DayOfYear write DayOfYear;
  Property Ex_GlobRad : TExternV read GlobRad write GlobRad;

  property Opt_Leaf_Stem_proc : TLeaf_Stem_proc read fLeaf_Stem_proc write fLeaf_Stem_proc;
  property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;


end;  // SubmodelName

procedure Register;

implementation

uses math;

function TSubPartitioningVegNew.GetCropHeight:THumeNumEntity;

begin
  result := CropHeight;
end;

procedure TSubPartitioningVegNew.SetCropHeight(NewCropHeight:THumeNumEntity);

begin
  p_CropHeight := NewCropHeight;
end;

function TSubPartitioningVegNew.GetLAI:THumeNumEntity;

begin
   result := MyLAI

end;

procedure TSubPartitioningVegNew.SetLai(NewLAI:THumeNumEntity);

begin
  p_LAI := NewLAI;
end;


procedure TsubpartitioningVegNew.createAll;

begin
  inherited createAll;
//  VarCreate('DLFWT', '',0, true, DLFWT);
//  VarCreate('EXLFW', '',0, true, EXLFW);
//  VarCreate('GPP', '[n]',0, true, GPP);
//  VarCreate('GPPvar', '[g/plant]',0, true, GPPvar);
//  VarCreate('GPSM', '[g/m2]',0, true, GPSM);
//  VarCreate('GRNWT_m2', '[g/m2]',0, true, GRNWT_m2);
//  VarCreate('GROGRN', '[g/(plant.d)]',0, true, GROGRN);
  VarCreate('GROLF', '[g/plant/d]',0, true, GROLF, 'growth rate of leaf dry matter');
  VarCreate('GRORT', '[g/pl/d]',0, true, GRORT);
  VarCreate('GROSTM', '[g/(plant.d]',0, true, GROSTM);
  VarCreate('LFWT_m2', '[g/m2]',0, true, LFWT_m2);
  VarCreate('PTF', '[-]',0, true, PTF);
//  VarCreate('RGFILL', '[mg/(plant*day)]',0, true, RGFILL);
  VarCreate('RTWT_m2', '[g/m2]',0, true, RTWT_m2);
  VarCreate('SENL', '[g/(plant.d]',0, true, SENL);
  VarCreate('SENRT_pl', '',0, true, SENRT_pl);
  VarCreate('SENSTM_pl', '[g/plant]',0, true, SENSTM_pl);
  VarCreate('DMTrans_pl', '[g/plant]',0, true, DMTrans_pl);
  VarCreate('STMWT_m2', '[g/m2]',0, true, STMWT_m2);
  VarCreate('SENWT_m2', '[g/m2]',0, true, SENWT_m2);
//  VarCreate('TKM', '[g]',0, true, TKM);
  VarCreate('TOPWT_pl', '[g/plant]',0, true, TOPWT_pl);
  VarCreate('TOPWT_m2', '[g/m2] ',0, true, TOPWT_m2);
  VarCreate('FFINEROOT', '[-]', 0, true, FFineRoot);
  VarCreate('Assiflow', '[g/m2/d]', 0, true, Assiflow);
  VarCreate('fStem', '[-]', 0, true, fStem);
  VarCreate('MyLAI', '', 0, true, MyLAI);
//  VarCreate('GrainSinkSize', '', 0, true, GrainSinkSize);

  VarCreate('NTrans_pl', '[g/plant]',0,true, NTrans_pl);
  VarCreate('NLeaf', '[g/m2]',0,true, NLeaf_m2);
  VarCreate('NStem', '[g/m2]',0,true,NStem_m2);
  VarCreate('NShoot_m2', '[g/m2]',0,true,NShoot_m2);
  VarCreate('NStoragepool_m2', '[g/m2]',0,true,NStoragepool_m2);
  VarCreate('NDemand', '[kg/ha/d]',0,true,NDemand);
  VarCreate('NcLeaf', '[%]', 0, true, NcLeaf);
  VarCreate('NcStem', '[%]', 0, true, NcStem);
  VarCreate('NcShoot', '[%]', 0, true, NcShoot);
  VarCreate('NoptStem', '[%]', 0, true, NoptStem);
  VarCreate('NoptLeaf', '[%]', 0, true, NoptLeaf);

  VarCreate('G3', '',0, true, G3);


  StateCreate('CUMPH', '[-]',0, true,CUMPH);
  StateCreate('GPPend', '',0, true,GPPend);
//  StateCreate('GRNWT', '[g/plant]',0, true,GRNWT);
  StateCreate('LFWT_pl', '[g/plant]',0, true,LFWT_pl);
  StateCreate('RTWT_pl', '[g/plant]',0, true,RTWT_pl);
  StateCreate('SEEDRV', '[g/plant]',0, true,SEEDRV);
  StateCreate('SENLF_pl', '[g/plant]',0, true,SENLF_pl);
  StateCreate('STMWT_pl', '[g]',0, true,STMWT_pl);
//  StateCreate('SWMIN', '[g/plant]',0, true,SWMIN);
  StateCreate('TempSum', '[g/plant]',0, true, TempSum);
  StateCreate('DMFineRoot', '[g/m2]', 0,true, DMFineRoot);
  StateCreate('PLA', '[m2/plant]', 0,true, PLA);
 StateCreate('CropHeight', '[m]', 0,true, CropHeight);

 StateCreate('NLeaf_pl', '[g/plant]',0,true, NLeaf_pl);
 StateCreate('NStem_pl', '[g/plant]',0,true,NStem_pl);
 StateCreate('NStoragepool_pl', '[g/plant]',0,true,NStoragepool_pl);
 StateCreate('NShoot_pl', '[g/plant]',0,true,NShoot_pl);
 StateCreate('NcLeafWinter', '[%]',0,true,NcLeafWinter);
 StateCreate('NcStemWinter', '[%]',0,true,NcStemWinter);
  StateCreate('LAI2000', '[%]',0,true,LAI2000);

  // Parameters
//  ParCreate('G1_', '[-]',6, G1_);
//  ParCreate('G2_', '[-]',3.3, G2_);
  ParCreate('G3_', '[mg/day]',4.5, G3_);
  ParCreate('Plants', '[plants/m2]',350, Plants);
  ParCreate('h','[-]', -0.6864, h);
  ParCreate('g','[-]', 1.3129, g);
  ParCreate('STFR1','[-]', 0.15, STFR1);
  ParCreate('STFR2','[-]', 0.51, STFR2);
  ParCreate('SowingDensity', '[1/m2]', 320, sowingdensity);
//  ParCreate('SLA', '[m2/g]', 0.02, SLA);

  ParCreate('pNcLeaf','[%]', 5.2, pNcLeaf);
  ParCreate('rgr_NcLeafWinter','[-]', 0.002, rgr_NcLeafWinter);
  ParCreate('rgr_NcStemWinter','[-]', 0.002, rgr_NcStemWinter);
  ParCreate('ECcritNcLeaf','[-]', 27, ECcritNcLeaf);
  ParCreate('NcStem_a','[-]', 0.1475, NcStem_a);
  ParCreate('NcStem_b','[-]', 0.0011, NcStem_b);
  ParCreate('NcStemMin','[%]', 4.0, NcStemMin);
  ParCreate('NcLeafMin','[%]',4.5, NcLeafMin);
  ParCreate('NcLeafVf1','[-]', -0.0058, NcLeafVf1);
  ParCreate('NcLeafVf2','[-]', 5.7825, NCLeafVf2);
  ParCreate('NcTrans','[%]', 3.0, NcTrans);
  ParCreate('DMStemcrit','[g/m2]', 30, DMStemcrit);
  ParCreate('DMLeafcrit','[g/m2]', 50, DMLeafcrit);
  ParCreate('pDMTrans','[%]', 25, pDMTrans);
  ParCreate('EC_LGend','[-]', 34, EC_LGend);
  ParCreate('k_SEEDRV','[-]', 0.15, k_SEEDRV); // mobilisation constant for seed reserves
  ParCreate('INI_LFWT_pl','[-]', 0.00034, INI_LFWT_pl);
  ParCreate('Ini_SEEDRV','[-]', 0.05, Ini_SEEDRV);
  ParCreate('fFineRoot0', '[-]', 0.616618, fFineroot0);
  ParCreate('fFineRootDec', '[-]', 0.00045067, fFinerootdec);



         // External Variable
  ExternVCreate('CARBO', '',statefield, CARBO);
  ExternVCreate('DTT', '',statefield, DTT);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('XSTAGE', '',statefield, XSTAGE);
//  ExternVCreate('ndef2', '',statefield, ndef2);
  ExternVCreate('PHINT', '',statefield, PHINT);
//  ExternVCreate('PLA', '',statefield, PLA);
  ExternVCreate('PLAGMS', '',statefield, PLAGMS);
//  ExternVCreate('SENLA', '',statefield, SENLA);
  ExternVCreate('SUMDTT2', '',statefield, SUMDTT2);
  ExternVCreate('swdf1', '',statefield, swdf1);
  ExternVCreate('TEMPM', '',statefield, TEMPM);
  ExternVCreate('tempmn', '',statefield, tempmn);
  ExternVCreate('tempmx', '',statefield, tempmx);
//  ExternVCreate('TI', '',statefield, TI);
//  ExternVCreate('TILN', '',statefield, TILN);
  ExternVCreate('EC', '', statefield, EC);
  ExternVCreate('LAI', '', statefield, LAI);
  ExternVCreate('AWR', '', statefield, AWR);
  ExternVCreate('Transratio', '', statefield, Transratio);
  ExternVCreate('GlobRad', '', statefield, Globrad);
  ExternVCreate('DayOfYear', '', statefield, DayOfYear);

  OptCreate('Leaf_Stem_proc', 'Allometric', Leaf_Stem_proc);
  Leaf_Stem_proc.OptionList.Add('Allometric');
  Leaf_Stem_proc.OptionList.Add('CERES');

  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
  optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');



end;


procedure TsubpartitioningVegNew.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
    if optDroughtimpact.option = 'droughtimpact' then begin
    fdroughtimpact := DroughtImpact;
  end;
  if optDroughtimpact.option = 'nodroughtimpact' then begin
    fdroughtimpact := noDroughtImpact;
  end;

  if Leaf_Stem_proc.Option = 'allometric' then fLeaf_Stem_proc := Allometric;
  if Leaf_Stem_proc.Option = 'ceres' then fLeaf_Stem_proc := CERES;

  NcLeafWinter.v := NcLeafMin.v+0.01;
  NcStemWinter.v := NcStemMin.v+0.01;

// G1.v :=  5.+G1_.v*5.;
//  G2.v :=  0.65+G2_.v*0.35;
  G3.v :=  -0.005+G3_.v*0.35;
//  P2.v :=  PHINT.v*3;
//  P3.v :=  PHINT.v*2;

end;

procedure TSubPartitioningVegNew.calc_rootDM;

begin
// own approach
//    PTF.v := min(1,1-(fFineRoot0.v-FFinerootDec.v*TempSum.v));      // old version

   {IF (ISTAGE.v < 9) and (ISTAGE.v>=5)
     then PTF.v := 1.0 else
   If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  PTF.v :=   0.8
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  PTF.v :=   0.75
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  PTF.v :=   0.70
   else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  PTF.v :=   0.5
   else  PTF.v :=   0.0  ; }

   IF (ISTAGE.v < 9) and (ISTAGE.v>=5)
     then PTF.v := 1.0 else
   If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  PTF.v :=   0.8
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  PTF.v :=   0.75
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  PTF.v :=   0.70
   else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  PTF.v :=   0.65
   else  PTF.v :=   0.0  ;

   If fDroughtImpact = Droughtimpact then
     PTF.v := PTF.v - 0.1*(1-Transratio.v);  // to increase root mass under drough stress


    FFineRoot.v := 1-PTF.v;

    If FFineRoot.v < 0 then
       FFineroot.v := 0.0;

    DMfineroot.C := Assiflow.v *Plants.v *FFineRoot.v; // per m2
    RTWT_pl.c :=  Assiflow.v * FFineRoot.v; // per plant
    Assiflow.v := Assiflow.v-RTWT_pl.c; // substract root growth

end;


procedure TSubPartitioningVegNew.Allometric_Leaf_Stem_Partitioning;

begin

{    If (EC.v < EC_LGend.v) and (ISTAGE.v >=1) and (STMWT_pl.v >0) then begin
      fStem.v := (1-1/(1+exp(h.v/Plants.v)*power(STMWT_pl.v, g.v - 1)*g.v));}
    If (EC.v < EC_LGend.v) and (ISTAGE.v >=1) and (LFWT_pl.v >0) then begin
      fStem.v := (1-1/(1+exp(h.v/Plants.v)*power(LFWT_pl.v, g.v - 1)*g.v));
      STMWT_pl.c :=  assiflow.v* fSTem.v;
      LFWT_pl.c :=  Assiflow.v-STMWT_pl.c;;
      GROLF.v := LFWT_pl.c;
      GROSTM.v := STMWT_pl.c;
      end
    else begin
      STMWT_pl.c := Assiflow.v;
      LFWT_pl.c := 0.0;
      GROLF.v := LFWT_pl.c;
      GROSTM.v := STMWT_pl.c;

    end;
end;


procedure TSubPartitioningVegNew.CERES_Leaf_Stem_Partitioning;

begin
{   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then
       if AWR.v > 0
     then  GROLF.v :=   min((PLAGMS.v*(0.3+0.7*TILN.v))/AWR.v, CARBO.v*0.65+SEEDRV.v)
   else  If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  GROLF.v :=   CARBO.v-GRORT.v-GROSTM.v
   else  GROLF.v :=   0  ; }

   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then  fStem.v :=  (STFR1.v+(STFR2.v-STFR1.v)*(XSTAGE.v-ISTAGE.v))
   else If  (ISTAGE.v>=2)and(ISTAGE.v<3)
     then  fStem.v :=  (STFR2.v+(1-STFR2.v)*(XSTAGE.v-ISTAGE.v))
   else  If  ISTAGE.v>=3
     then  fStem.v:=1
   else  fStem.v :=   0;
    STMWT_pl.c :=  assiflow.v* fSTem.v;
    LFWT_pl.c :=  Assiflow.v-STMWT_pl.c;;
    GROLF.v := LFWT_pl.c;
    GROSTM.v := STMWT_pl.c;

end;



procedure TSubPartitioningVegNew.CalcRates;

var
  TMPM : real;

begin

  TMPM := (TeMPMN.v + TeMPMX.v)/2;   // average day temperature
  Assiflow.v := Carbo.v+DMTrans_pl.v;

  If GlobTime.v >= SowingDate.v then begin
      If TMPM > 0.0 then
        TempSum.c := TMPM        // rate of change of temperature sum
      else TempSum.c  := 0.0;
  end;

  If  (ISTAGE.v>=1)and (ISTAGE.v<3) then
     CUMPH.c :=  dtt.v/PHINT.v       // rate of change of cumulative phyllochron
   else  CUMPH.c :=   0  ;


  If  (ISTAGE.v>=0.99)and(ISTAGE.v<2)and(SEEDRV.v>0) then
    begin
      SEEDRV.c   :=   -k_SEEDRV.v*Seedrv.v;
      Assiflow.v := Assiflow.v-SEEDRV.c;
    end
  else  SEEDRV.c :=   0;

  Calc_RootDM;


  if fLeaf_Stem_proc = Allometric then Allometric_Leaf_Stem_Partitioning
  else if fLeaf_Stem_proc = CERES then CERES_Leaf_Stem_Partitioning;

(*   // Calculation of Grain Number
   GPP.v :=   max(GPPend.v, GPPvar.v)  ;

   GPPvar.v :=  STMWT_pl.v*G1.v;

   GPSM.v :=  GPP.v*PLANTS.v;*)


   {If  (PLA.v>0)and(ISTAGE.v<6)and(ISTAGE.v>=1)
     then  SENL.v :=   LFWT_pl.v*0.000267*DTT.v*(1.-SENLA.v/PLA.v)
   else  SENL.v :=   0  ;

   SENRT_pl.v :=  0.005*RTWT_pl.v;}


{   If  -dlfwt.v>0
     then  SENLF_pl.c :=   DLFWT.v
   else  SENLF_pl.c :=   0  ;   }



   {If  (PLA.v>0)and(ISTAGE.v<6)and(ISTAGE.v>=1)
     then  LFWT_pl.c := GROLF.v-max(0,SENL.v)
   else LFWT_pl.c := 0;

    DLFWT.v := (EXLFW.v-LFWT_pl.v)*PLANTS.v; }

    //NoptLeaf.v := NcLeafVf1.v*LFWT_m2.v+NcLEafVf2.v;

    //NLeaf_pl.c  := (LFWT_pl.c*NoptLeaf.v + NcLeafVf1.v*LFWT_pl.v)/100;

  {  If LFWT_m2.v >= DMLeafcrit.v then begin
      NoptLeaf.v := NcLeafVf1.v*LFWT_m2.v+NcLEafVf2.v;
      NLeaf_pl.c  := (LFWT_pl.c*NoptLeaf.v + NcLeafVf1.v*LFWT_pl.v)/100;
    end else begin
      NoptLeaf.v := NcLeafVf1.v*DMLeafcrit.v+NcLeafVf2.v;
      NLeaf_pl.c  := (LFWT_pl.c*NoptLeaf.v + NcLeafVf1.v*LFWT_pl.v)/100;
    end;  }


    If ec.v >= ECcritNcLeaf.v then begin
      NoptLeaf.v := NcLeafVf1.v*(LFWT_m2.v{+SENWT_m2.v}) + NcLEafVf2.v;
      {NLeaf_pl.c  := LFWT_pl.c*(NoptLeaf.v + NcLeafVf1.v)/100;}
      NcLeafWinter.c := 0;
    end else begin
      If DayOfYear.v < 150 then if TEMPM.v > 0 then
         NcLeafWinter.c := (NcLeafWinter.v-NcLeafMin.v)* rgr_NcLeafWinter.v*GlobRad.v*(1-(NcLeafWinter.v-NcLeafMin.v)/(NcLeafVf1.v*LFWT_m2.v + NcLEafVf2.v-NcLeafMin.v));

      NoptLeaf.v := NcLeafWinter.v;
    end;
    NLeaf_pl.c  := LFWT_pl.c*NoptLeaf.v /100+NOptLeaf.v/100*LFWT_pl.v-NLeaf_pl.v;

    If NcStemWinter.v>=0.98*(1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v)){ec.v >= ECcritNcLeaf.v} then begin
      NoptStem.v := 1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v);
      NcStemWinter.c := 0;
    end else begin
      If DayOfYear.v < 150 then if TEMPM.v > 0 then
         NcStemWinter.c := (NcStemWinter.v-NcStemMin.v)* rgr_NcStemWinter.v*GlobRad.v*(1-(NcStemWinter.v-NcStemMin.v)/(1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v)-NcStemMin.v));

      NoptStem.v := NcStemWinter.v;
     end;
    NStem_pl.c := STMWT_pl.c*NoptStem.v/100+(NoptStem.v/100*STMWT_pl.v-NStem_pl.v);


    {If STMWT_m2.v >= DMSTEMcrit.v then NoptStem.v := 1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v)
    else NoptStem.v :=  1/(NcStem_a.v+NcStem_b.v*DMStemcrit.v);
    NStem_pl.c := STMWT_pl.c*NoptStem.v/100+(NoptStem.v/100*STMWT_pl.v-NStem_pl.v); }



    If ISTAGE.v >= 1.0 then begin
      SENLF_pl.c := SENL.v*(1-pDMTrans.v/100);    // dry matter loss is calculated from the fraction on non translocatable DM
      LFWT_pl.c := LFWT_pl.c - SENL.v;            //  net change of leaf dry matter

      DMTrans_pl.v := Senl.v*pDMTrans.v/100;      // translocatable DM  g/(pl*d)
      NTrans_pl.v  := Senl.v*NcTrans.v/100;       // translocatable N  g/(pl*d)
      If (NStem_pl.c>0) and (NTrans_pl.v+NSToragepool_pl.v>0) then
         NTrans_pl.v := NTrans_pl.v-Nstem_pl.c;
      If NTrans_pl.v+NSToragepool_pl.v<0 then
         NTrans_pl.v :=-NSToragepool_pl.v;

      If Nstem_pl.c < 0 then
         NTrans_pl.v  := NTrans_pl.v  - NStem_pl.c; // negative changes of N in stem are stored ....
      If (NLeaf_pl.c>0) and (NTrans_pl.v+NSToragepool_pl.v>0) then
         NTrans_pl.v := NTrans_pl.v-NLeaf_pl.c;
      If NTrans_pl.v+NSToragepool_pl.v<0 then
         NTrans_pl.v :=-NSToragepool_pl.v;
      NSToragepool_pl.c := NTrans_pl.v;
      NLeaf_pl.c   := NLeaf_pl.c-Senl.v*NoptLeaf.v/100;
    end;
    LAI2000.c:=0; //Damit es zw. den Messterminen nicht weiterwächst...
end;

procedure TSubPartitioningVegNew.UpdateValues;
begin
     inherited;
     if UpdateValue(LAI2000.Name)<>0 then begin
        LAI2000.c:= LAI2000.c + UpdateValue(LAI2000.Name)-(LAI2000.v+LAI2000.c);
        //morgen geht es weiter...


     end;
end;


procedure TSubPartitioningVegNew.Integrate;

begin
//  Exlfw.V := LFWT_pl.v;

  inherited  integrate;
  MyLAI.v := LAI.v;

  If (ISTAGE.v>=1) and (LFWT_pl.v<=0) then begin
    LFWT_pl.v   := INI_LFWT_pl.v;                      // Initialize stem weight
    STMWT_pl.v  := exp(g.v*ln(LFWT_pl.v)+h.v);         // Initialize stem weight
    SEEDRV.v    := Ini_SEEDRV.v;// 0.05; // 0.012;
    NLeaf_pl.v  := LFWT_pl.v * NOptLeaf.v/100;
    NStem_pl.v  := STMWT_pl.v * NOptStem.v/100;
    NShoot_pl.v := NLeaf_pl.v + NStem_pl.v;
  end;

  CropHeight.v := LAI.v/5+0.05; // first proxy for crop height

//  If (ISTAGE.v>=4) and (SWMIN.v<=0) then begin
//    SWMIN.v := STMWT_pl.v;                        // save value of Stemweight for labile
//  end;

//  If (ISTAGE.v>=5) and (gppend.v<=0) then begin
//    grnwt.v  := 0.0035*gpp.v;                  // Initialize Grains
//    STMWT_pl.v := STMWT_pl.v-GRNWT.v;                //
//    If (gppend.v <=0.0) then
//      gppend.v := gpp.v;
//  end;

  TOPWT_pl.v :=  LFWT_pl.v+STMWT_pl.v+SEEDRV.v;    // top weight per plant


  STMWT_m2.v :=  STMWT_pl.v*Plants.v;
  SENWT_m2.v :=  SENLF_pl.v*Plants.v;

//  GRNWT_m2.v :=  GRNWT.v*Plants.v;

  LFWT_m2.v :=  LFWT_pl.v*Plants.v;

  RTWT_m2.v :=  RTWT_pl.v*plants.v;

  TOPWT_m2.v :=  {GRNWT_m2.v+}LFWT_m2.v+STMWT_m2.v;

(*  If  gpsm.v>0 then
     TKM.v := GRNWT_m2.v/gpsm.v*1000           // calculate thausend kernel weight
  else  TKM.v :=   0;*)

  if LFWT_pl.v>0 then NcLeaf.v := NLeaf_pl.v/LFWT_pl.v*100;  // aktuelle Blatt N-Konzentration
  if STMWT_pl.v>0 then NcStem.v := NStem_pl.v/STMWT_pl.v*100;  // aktuelle Stängel N-Konzentration

  NLeaf_m2.v := NLeaf_pl.v*plants.v;
  NSTEM_m2.v := NStem_pl.v*plants.v;
  NStoragepool_m2.v := NStoragepool_pl.v*plants.v;
  NShoot_pl.v := NLeaf_pl.v + NStem_pl.v + NStoragepool_pl.v;
  NShoot_m2.v := NShoot_pl.v*plants.v;
  if TOPWT_m2.v>0 then NcShoot.v := NShoot_pl.v/TOPWT_m2.v*100 else NcShoot.v := 0;
end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningVegNew]);
end;

end.
