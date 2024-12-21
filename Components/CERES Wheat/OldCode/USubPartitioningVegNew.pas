unit USubPartitioningVegNew;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   UMod, UState, UAbstractPlant;
                               
Type
TDroughtImpact = (DroughtImpact, NoDroughtImpact);
TLeaf_Stem_proc = (Allometric, CERES);
TPTF_version = (PTF_CERES, PTF_Kage);

TSubPartitioningVegNew = class(TAbstractPlant)

private





protected
  fDroughtImpact : TDroughtImpact;
  fPTF_version: TPTF_version;
  fLeaf_Stem_proc : TLeaf_Stem_proc;
  function GetLAI:THumeNumEntity; override;
  procedure SetLai(NewLAI:THumeNumEntity); override;
  function GetCropHeight:THumeNumEntity; override;
  procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;
  function getExtCoeffPAR: real; //override;


public
(*  DLFWT : TVar;     //
  EXLFW : TVar;       // old leaf weight from previous day [g/plant]
  GPP : TVar;         //   Number of grains per plant  [n]
  GPPvar : TVar;      //   Number of grains per plant  [g/plant]
  GPSM : TVar;        // Grains per square meter [g/m2]
  GRNWT_m2 : TVar;    // Grain weight per square meter [g/m2]
  GROGRN : TVar;      // Daily growth of the grain - [g/(plant.d)]*)
  GROLF : TVar;       // Daily leaf growth [g/plant/d]
  GRORT : TVar;       // Daily root growth - [g/pl/d]
  GROSTM : TVar;      // Daily stem growth  [g/(plant.d]
  LFWT_m2 : TVar;     // leaf weight per square meter [g/m2]
  PTF : TVar;         // Fraction of photosynthesis partitioned to above ground plant parts [-]
  //PTFKage : TVar;     // Fraction of photosynthesis partitioned to above ground plant parts [-]
//  RGFILL : TVar;     // Rate of grain fill  [mg/(plant*day)]
  RTWT_m2 : TVar;     // root weight per square meter [g/m2]
  SENL : TVar;        // Leaf senscence rate [g/(plant.d]
  SENRT_pl : TVar;    //  Senscent root mass [g/plant]
  SENSTM_pl : TVar;   // Senescent stem mass [g/plant]
  DMTrans_pl  : TVar; // translozierbare Trockenmasse (g/Pflanze)
  STMWT_m2 : TVar;    // Stem weight per square meter [g/m2]
  SENWT_m2 : TVar;    // Dead Leaf weight per square meter [g/m2]
  NSEN_m2 : TVar;     // N in dead leaves [g/m2]
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
  NUptake      : TState;  // NUptake from the soil (cum. NDemand) [kg/ha]
  NStoragepool_pl : TState; // intermediate storage pool (g N/pl)
  NStoragepool_m2 : TVar; // intermediate storage pool (g/m²)
  NShoot_pl    : TState;  // Spross N-Menge (g/Pflanze)
  NcTrans      : TPAR;  // translozierbarer N-Anteil der seneszenten Trockenmasse (%)
  NTrans_pl    : TVar;    // translozierbare N-Menge (g/Pflanze)
  NLeaf_m2     : TVar;  // Blatt N-Menge (g/m²)
  NStem_m2     : TVar;  // Stängel N-Menge (g/m²)
  NShoot_m2    : TVar;  // Spross N-Menge (g/m²)
  NDemand_pl: TVar; //N demand per plant [g/(pl*d)]
  NDemand  : TVar; // nitrogen demand (kg/ha/d)
  NcLeaf    : Tvar;  // Blatt N-Konzentration (%)
  NcStem    : Tvar;  // Stängel N-Konzentration (%)
  NcShoot   : Tvar;  // Spross N-Konzentration (%)
  NoptStem : Tvar; // optimum N concentration stem(%)
  NoptLeaf : Tvar; // optimum N concentration leaf(%)
  fstem_av : Tvar; // Stängelanteil an TM
  NcLeaf_ECLGE : Tvar; // N concentration at the end of leaf growth

  // Constant Variables
//  G1 : TVar;   // Unscaled version of the Genetic specific constant related to rate of vegetative expansion growth during Stage 1
//  G2 : TVar;   // Unscaled genetic specific constant related to the number of grains produced

  SowingDensity : TPar;
  pNcMinimum_STEM : TPar;
//  GPPend : TState;  //  final grain number per plant
//  GRNWT : TState;   // Weight of grains [g/plant]
  NcLeafWinter : TState; // N conc. Leaf Winter (%) Strahlungsabhängig
  NcStemWinter : TState; // N conc. Stem Winter (%) Strahlungsabhängig
  LFWT_pl : TState;    // Leaf weight of all leaves on a plant [g/plant]
  RTWT_pl : TState;    //   Root weight - [g/plant]
  DMFineRoot : Tstate; //  Root weight - [g/m2]
  SEEDRV : TState;  // Reserve carbohydrates in seed for use by plant in seedling stage [g/plant]
  Senwt_pl : TState;   // Senescent leaf weight [g/plant]
  STMWT_pl : TState;   //  Stem weight of an average tiller after terminal spikelet  [g]
  SWMIN : TState;   //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]
  NSen_pl    : TState;    // N in senescent leaves [g/plant]
  TEMPsum : TState; // Temperature sum
//  ReseverePool : TState; // ReservePool for Storage of Assimilates
  PLA : TSTATE;   // leaf area per plant
  CropHeight : TState; // plant height [m]


             // Parameters
  Plants : TPar;   // number of plants per square meter
  h        : TPar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  g        : Tpar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  {h2        : TPar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung
  g2        : Tpar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung
  h3        : TPar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung
  g3        : Tpar;   // Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  STFR1    : Tpar; // Fraction of Drymatter allocated to stem at Xstage=1
  STFR2    : Tpar; // Fraction of Drymatter allocated to stem at Xstage=2


  ECcritNcLeaf : TPar; // kritisches EC-Stadium bis zu dem N-Konz.= NcLeafWinter
  rgr_NcLeafWinter : TPar; // Zuwachsrate für die Blatt N-Konzentration im Winter
  rgr_NcStemWinter : TPar; // Zuwachsrate für die Stängel N-Konzentration im Winter
  NcStem_a : TPar; // Parameter für Stängel N-Verdünnungsfunktion
  NcStem_b : TPar;  // Parameter für Stängel N-Verdünnungsfunktion
  //xxx Bedeutung ??? bzw. Benennung
  NcLeafMin : TPar; //  niedrigste Blatt N-Konzentration bis Frühjahr (%)
  NcStemMin : TPar; //  niedrigste Stängel N-Konzentration (%)
  NcLeafVf1 : TPar; // Steigung der Leaf N-Verdünnungsfunktion
  NcLeafVf2 : TPar;  // Intercept der Leaf N-Verdünnugsfunktion
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
{  actSLA : TExternV;   // average weight ratio i.e. specific leaf area (cm/g)}

  CARBO : TExternV;    //  Daily carbohydrate production (g/pl/d)
  ISTAGE : TExternV;   // Development stage according do CERES
  XSTAGE : TExternV; //   Development stage according do CERES
//  ndef2 : TExternV;   //
  PHINT : TExternV;   //  Phyllochron interval
  //PLA : TExternV;   //  Plant leaf area (m2/pl)
{  PLAGMS : TExternV;   //  Plant leaf area on main stem (m2/pl)}
{  swdf1  : TExternV;   // soil water deficit factor}
  TEMPM  : TExternV;   //  average daily air temperature
  tempmn : TExternV;   // minimum daily air temperature
  tempmx : TExternV;   // maximum daily air temperature
  TI     : TExternV;   // Fraction of a phyllochron interval which occurred as a fraction of today's daily thermal time
  TILN   : TExternV;   // Time delayed reduced tiller number [n/plant]
  EC     : TExternV;   //  EC-Stage
  exk_PAR: TExternV; // extinction coefficient for photosynthetically active radiation
  Transratio     : TExternV;
  DayOfYear : TExternV;
  GlobRad : TExternV;
  Leaf_Stem_proc : TOption; // Option for leaf/stem partitioning
  OptDroughtimpact : Toption;
  OptPTF: TOption;


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

//  Property St_GPPend : TState read GPPend write GPPend;
//  Property St_GRNWT : TState read GRNWT write GRNWT;
  Property St_LFWT : TState read LFWT_pl write LFWT_pl;
  Property St_RTWT : TState read RTWT_pl write RTWT_pl;
  Property St_SEEDRV : TState read SEEDRV write SEEDRV;
  Property St_SENLF : TState read Senwt_pl write Senwt_pl;
  Property St_STMWT : TState read STMWT_pl write STMWT_pl;
  Property St_SWMIN : TState read SWMIN write SWMIN;
  Property St_TempSum : TState read TempSum write TempSum;
  Property St_DMFineRoot : TState read DMFineRoot write DMFineRoot;
  Property St_CropHeight : TState read CropHeight write CropHeight;
  //Property St_LAI2000 : TState read LAI2000 write LAI2000;

         // Parameters
//  Property Par_G1_ : TPar read G1_ write G1_;
//  Property Par_G2_ : TPar read G2_ write G2_;
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
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
//  Property Ex_ndef2 : TExternV read ndef2 write ndef2;
  Property Ex_PHINT : TExternV read PHINT write PHINT;
{  Property Ex_PLAGMS : TExternV read PLAGMS write PLAGMS;}
//  Property Ex_SENLA : TExternV read SENLA write SENLA;
{  Property Ex_swdf1 : TExternV read swdf1 write swdf1;}
  Property Ex_TEMPM : TExternV read TEMPM write TEMPM;
  Property Ex_tempmn : TExternV read tempmn write tempmn;
  Property Ex_tempmx : TExternV read tempmx write tempmx;
//  Property Ex_TI : TExternV read TI write TI;
//  Property Ex_TILN : TExternV read TILN write TILN;
//  Property Ex_SowingDate : TExternV read Sowingdate write Sowingdate; //

  property Var_FFineRoot : TVar read FFineRoot write FFineroot;
  property Ex_EC  : TExternv read EC write EC;
  Property Ex_LAI : TExternV read LAI write LAI;
{  Property Ex_actSLA : TExternV read actSLA write actSLA;}
  Property Ex_Transratio : TExternV read Transratio write Transratio;
  Property Ex_DayOfYear : TExternV read DayOfYear write DayOfYear;
  Property Ex_GlobRad : TExternV read GlobRad write GlobRad;
  Property Ex_exk_PAR : TExternV read exk_PAR write exk_PAR;

  property Opt_Leaf_Stem_proc : TLeaf_Stem_proc read fLeaf_Stem_proc write fLeaf_Stem_proc;
  property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;
  property opt_PTF: TPTF_version read fPTF_version write fPTF_version;


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

function TSubPartitioningVegNew.getExtCoeffPAR: real;
begin
  result := exk_PAR.v;
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
  VarCreate('NSEN_m2', '[g/m2]',0, true, NSEN_m2);
//  VarCreate('TKM', '[g]',0, true, TKM);
  VarCreate('TOPWT_pl', '[g/plant]',0, true, TOPWT_pl);
  VarCreate('TOPWT_m2', '[g/m2] ',0, true, TOPWT_m2);
  VarCreate('FFINEROOT', '[-]', 0, true, FFineRoot);
  VarCreate('Assiflow', '[g/m2/d]', 0, true, Assiflow);
  VarCreate('fStem', '[-]', 0, true, fStem);
  VarCreate('MyLAI', '', 0, true, MyLAI);
  VarCreate('fstem_av', '', 0, true, fstem_av);
  VarCreate('NcLeaf_ECLGE', '', 0, true, NcLeaf_ECLGE, 'leaf N concentration at the end of leaf growth');
//  VarCreate('GrainSinkSize', '', 0, true, GrainSinkSize);

  VarCreate('NTrans_pl', '[g/plant]',0,true, NTrans_pl);
  VarCreate('NLeaf', '[g/m2]',0,true, NLeaf_m2);
  VarCreate('NStem', '[g/m2]',0,true,NStem_m2);
  VarCreate('NShoot_m2', '[g/m2]',0,true,NShoot_m2);
  VarCreate('NStoragepool_m2', '[g/m2]',0,true,NStoragepool_m2);
  VarCreate('NDemand', '[kg/ha/d]',0,true,NDemand);
  VarCreate('NDemand_pl', '[g/(pl*d)]',0,true,NDemand_pl);
  VarCreate('NcLeaf', '[%]', 0, true, NcLeaf);
  VarCreate('NcStem', '[%]', 0, true, NcStem);
  VarCreate('NcShoot', '[%]', 0, true, NcShoot);
  VarCreate('NoptStem', '[%]', 0, true, NoptStem);
  VarCreate('NoptLeaf', '[%]', 0, true, NoptLeaf);

  //StateCreate('GPPend', '',0, true,GPPend);
//  StateCreate('GRNWT', '[g/plant]',0, true,GRNWT);
  StateCreate('LFWT_pl', '[g/plant]',0, true,LFWT_pl);
  StateCreate('RTWT_pl', '[g/plant]',0, true,RTWT_pl);
  StateCreate('SEEDRV', '[g/plant]',0, true,SEEDRV);
  StateCreate('Senwt_pl', '[g/plant]',0, true,Senwt_pl);
  StateCreate('STMWT_pl', '[g]',0, true,STMWT_pl);
  StateCreate('SWMIN', '[g/plant]',0, true,SWMIN);
  StateCreate('NSen_pl', '[g/plant]',0,true, NSen_pl);
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
 StateCreate('NUptake', '[kg/ha]',0,true,NUptake);
//  StateCreate('LAI2000', '[%]',0,true,LAI2000);

  // Parameters
//  ParCreate('G1_', '[-]',6, G1_);
//  ParCreate('G2_', '[-]',3.3, G2_);
  ParCreate('Plants', '[plants/m2]',350, Plants);
  ParCreate('h','[-]', -2.13, h);   //Meyer-Schatz DBU Endbericht
  ParCreate('g','[-]', 1.46, g);    //Meyer-Schatz DBU Endbericht
  {ParCreate('h2','[-]', -0.6864, h2);
  ParCreate('g2','[-]', 1.3129, g2);
  ParCreate('h3','[-]', -0.6864, h3);
  ParCreate('g3','[-]', 1.3129, g3);}
  ParCreate('STFR1','[-]', 0.15, STFR1);
  ParCreate('pNcMinimum_STEM','[-]', 0.01, pNcMinimum_STEM);
  ParCreate('STFR2','[-]', 0.51, STFR2);
  ParCreate('SowingDensity', '[1/m2]', 320, sowingdensity);
//  ParCreate('SLA', '[m2/g]', 0.02, SLA);


  ParCreate('rgr_NcLeafWinter','[-]', 0.02, rgr_NcLeafWinter);
  ParCreate('rgr_NcStemWinter','[-]', 0.02, rgr_NcStemWinter);
  ParCreate('ECcritNcLeaf','[-]', 27, ECcritNcLeaf);
  ParCreate('NcStem_a','[-]', 0.1475, NcStem_a); //aus Daten 950506 N4
  ParCreate('NcStem_b','[-]', 0.0011, NcStem_b);  //aus Daten 950506 N4
  ParCreate('NcStemMin','[%]', 4.0, NcStemMin);
  ParCreate('NcLeafMin','[%]', 4.5, NcLeafMin);
  ParCreate('NcLeafVf1','[-]', -0.0061, NcLeafVf1); //aus Daten 950506 N4
  ParCreate('NcLeafVf2','[-]', 5.9543, NCLeafVf2);  //aus Daten 950506 N4
  ParCreate('NcTrans','[%]', 3.0, NcTrans);
  ParCreate('DMStemcrit','[g/m2]', 30, DMStemcrit);
  ParCreate('DMLeafcrit','[g/m2]', 50, DMLeafcrit);
  ParCreate('pDMTrans','[%]', 25, pDMTrans);
  ParCreate('EC_LGend','[-]', 39, EC_LGend);
  ParCreate('k_SEEDRV','[-]', 0.15, k_SEEDRV); // mobilisation constant for seed reserves
  ParCreate('INI_LFWT_pl','[-]', 0.00034, INI_LFWT_pl);
  ParCreate('Ini_SEEDRV','[-]', 0.05, Ini_SEEDRV);
  ParCreate('fFineRoot0', '[-]', 0.653, fFineroot0);    // Parameter aus Habil Kage Kap. 10
  ParCreate('fFineRootDec', '[-]', 0.000501, fFinerootdec); //   Parameter aus Habil Kage Kap. 10
  ParCreate('fFineRootDec', '[-]', 0.000501, fFinerootdec);


         // External Variable
  ExternVCreate('CARBO', '',statefield, CARBO);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('XSTAGE', '',statefield, XSTAGE);
//  ExternVCreate('ndef2', '',statefield, ndef2);
  ExternVCreate('PHINT', '',statefield, PHINT);
//  ExternVCreate('PLA', '',statefield, PLA);
{  ExternVCreate('PLAGMS', '',statefield, PLAGMS);}
//  ExternVCreate('SENLA', '',statefield, SENLA);
{  ExternVCreate('swdf1', '',statefield, swdf1);}
  ExternVCreate('TEMPM', '',statefield, TEMPM);
  ExternVCreate('tempmn', '',statefield, tempmn);
  ExternVCreate('tempmx', '',statefield, tempmx);
//  ExternVCreate('TI', '',statefield, TI);
//  ExternVCreate('TILN', '',statefield, TILN);
  ExternVCreate('EC', '', statefield, EC);
  ExternVCreate('LAI', '', statefield, LAI);
{  ExternVCreate('actSLA', '', statefield, actSLA);}
  ExternVCreate('Transratio', '', statefield, Transratio);
  ExternVCreate('GlobRad', '', statefield, Globrad);
  ExternVCreate('DayOfYear', '', statefield, DayOfYear);
  ExternVCreate('kpar_eff', '', statefield, exk_PAR); // extinction coefficient for photosynthetically active radiation

  OptCreate('Leaf_Stem_proc', 'Allometric', Leaf_Stem_proc);
  Leaf_Stem_proc.OptionList.Add('Allometric');
  Leaf_Stem_proc.OptionList.Add('CERES');

  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
  optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');

  OptCreate('optPTF', 'PTF_CERES', optPTF, 'Approach for Partitioning to Top fraction');
  optPTF.OptionList.Clear;
  optPTF.OptionList.Add('PTF_CERES');
  optPTF.OptionList.Add('PTF_Kage');



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

  if optPTF.Option = 'ptf_ceres' then fPTF_version := PTF_CERES
  else if optPTF.Option = 'ptf_kage' then fPTF_version := PTF_Kage;

  NcLeafWinter.v := NcLeafMin.v+0.01; // Häh??? Frau Meyer-Schatz???
  NcStemWinter.v := NcStemMin.v+0.01;

end;

procedure TSubPartitioningVegNew.calc_rootDM;



begin
  if fPTF_version = PTF_Kage then begin
// own approach
    PTF.v := min(1,1-(fFineRoot0.v-FFinerootDec.v*TempSum.v));      // old version Kage unpublished ....Ch. 10 Habil.
  end
  else if fPTF_version = PTF_CERES then begin

   {IF (ISTAGE.v < 9) and (ISTAGE.v>=5)    // CERES Version 3.x
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

    IF (ISTAGE.v < 9) and (ISTAGE.v>=5)    // Version CERES 4.x Eingefügt von ??, wann ??
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
  end;

  If fDroughtImpact = Droughtimpact then PTF.v := PTF.v - 0.1*(1-Transratio.v);  // to increase root mass under drough stress


  FFineRoot.v := max(0, 1-PTF.v);

  DMfineroot.C := Assiflow.v *Plants.v *FFineRoot.v; // per m2
  RTWT_pl.c :=  Assiflow.v * FFineRoot.v; // per plant
  Assiflow.v := Assiflow.v-RTWT_pl.c; // substract root growth
end;


procedure TSubPartitioningVegNew.Allometric_Leaf_Stem_Partitioning;

begin
  If (EC.v < EC_LGend.v) and (ISTAGE.v >= 1) and (LFWT_pl.v > 0) then begin
   //if EC.v <25 then
   fStem.v := (1-1/(1+exp(h.v/ln(1/plants.v))*power(LFWT_pl.v, g.v - 1)*g.v));
   {if (EC.v>=25) and (EC.v <30) then fStem.v := (1-1/(1+exp(h2.v/ln(1/plants.v))*power(LFWT_pl.v, g2.v - 1)*g2.v));
   if EC.v >=30 then fStem.v := (1-1/(1+exp(h3.v/ln(1/plants.v))*power(LFWT_pl.v, g3.v - 1)*g3.v));}

    STMWT_pl.c :=  assiflow.v* fSTem.v;
    LFWT_pl.c :=  Assiflow.v-STMWT_pl.c;
  end
  else begin
    STMWT_pl.c := Assiflow.v;
    LFWT_pl.c := 0.0;
  end;
  GROLF.v := LFWT_pl.c;
  GROSTM.v := STMWT_pl.c;
end;


procedure TSubPartitioningVegNew.CERES_Leaf_Stem_Partitioning;

begin
{   If  (ISTAGE.v>=1)and(ISTAGE.v<2)
     then
       if actSLA.v > 0
     then  GROLF.v :=   min((PLAGMS.v*(0.3+0.7*TILN.v))/actSLA.v, CARBO.v*0.65+SEEDRV.v)
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
   LFWT_pl.c :=  Assiflow.v-STMWT_pl.c;
   GROLF.v := LFWT_pl.c;
   GROSTM.v := STMWT_pl.c;
end;



procedure TSubPartitioningVegNew.CalcRates;


begin

  Assiflow.v := Carbo.v+DMTrans_pl.v;

  If (GlobTime.v >= SowingDate.v) and (IStage.v >= 1) then begin  // 16.02.09 Tempsum ab IStage 1 = Auflaufen
    TempSum.c := max(TEMPM.V,0);        // rate of change of temperature sum
  end;

  If  (ISTAGE.v>=0.99)and(ISTAGE.v<2)and(SEEDRV.v>0) then
    begin
      SEEDRV.c   :=   -k_SEEDRV.v*Seedrv.v;
      Assiflow.v := Assiflow.v-SEEDRV.c;       // Addition of seed reserves to assiflow
    end
  else  SEEDRV.c :=   0;

  Calc_RootDM;

  if fLeaf_Stem_proc = Allometric then Allometric_Leaf_Stem_Partitioning
  else if fLeaf_Stem_proc = CERES then CERES_Leaf_Stem_Partitioning;


  // Calculation of N concentrations

  If ec.v >= ECcritNcLeaf.v then begin
    NoptLeaf.v := NcLeafVf1.v*(LFWT_m2.v{+SENWT_m2.v}) + NcLEafVf2.v;  // without dead leaves ...
    NcLeafWinter.c := 0;
  end else begin
    If DayOfYear.v < 150 then if TEMPM.v > 0 then   // Übergang winter-Frühjahr ....  etwas besser kommentieren !!!
       NcLeafWinter.c := (NcLeafWinter.v-NcLeafMin.v)* rgr_NcLeafWinter.v*GlobRad.v*(1-(NcLeafWinter.v-NcLeafMin.v)/(NcLeafVf1.v*LFWT_m2.v + NcLEafVf2.v-NcLeafMin.v));
    NoptLeaf.v := NcLeafWinter.v;
  end;
  if NcLeaf_ECLGE.v>0 then
     NLeaf_pl.c:= LFWT_pl.v*(NcLeaf_ECLGE.v/100)-Nleaf_pl.v //constant N concentration
  else
     NLeaf_pl.c  := LFWT_pl.c*NoptLeaf.v /100+NOptLeaf.v/100*LFWT_pl.v-NLeaf_pl.v; // between end of leaf growth and grainfilling
                                                                                     // 02.03.10 Ratjen
  If NcStemWinter.v>=0.98{Wo kommt die 0.98 her ???}*(1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v)){ec.v >= ECcritNcLeaf.v} then begin
    NoptStem.v := 1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v);
    NcStemWinter.c := 0;
  end
  else begin
    If DayOfYear.v < 150 then if TEMPM.v > 0 then
       NcStemWinter.c := (NcStemWinter.v-NcStemMin.v)* rgr_NcStemWinter.v*GlobRad.v*
                      (1-(NcStemWinter.v-NcStemMin.v)/
                      (1/(NcStem_a.v+NcStem_b.v*STMWT_m2.v)-NcStemMin.v));

    NoptStem.v := NcStemWinter.v;
  end;

  if NCstem.v >= pNcMinimum_STEM.v then
    NStem_pl.c := STMWT_pl.c*NoptStem.v/100+(NoptStem.v/100*STMWT_pl.v-NStem_pl.v)
  else
    NStem_pl.c := STMWT_pl.c*pNcMinimum_STEM.v;  // pNrStem = min. N concentration of stem growth Ratjen 26.01.10


// calculation of senescence and translocation

  If ISTAGE.v >= 1.0 then begin
    LFWT_pl.c := max(-LFWT_pl.v,LFWT_pl.c - SENL.v);   //  correction of net change of leaf dry matter due to senescence
    DMTrans_pl.v := Senl.v*pDMTrans.v/100;      // translocatable fraction of DM change  g/(pl*d)
    Senwt_pl.c := SENL.v*(1-pDMTrans.v/100);    // non translocatable fraction of DM remains as dead leaves

    NLeaf_pl.c := NLeaf_pl.c-Senl.v*NcLeaf.v/100;   // correction net change of leaf N for leaf senescence

//xxx Problem der Berechnung, es sollte nur die Differenz zum strukturellen N translozierbar sein!!
    NTrans_pl.v  := Senl.v*NcTrans.v/100;           // translocatable fraction of leaf N change  g/(pl*d)

    NSen_pl.c := Senl.v*NcLeaf.v/100-NTrans_pl.v; // remaining N in dead leaves

// The N demand is calculated from the changes of the organs minus translocatable N
    NDemand_pl.v := Max(Nstem_pl.c + NLeaf_pl.c + NSen_pl.c - NTrans_pl.v - NStoragepool_pl.v,0);
                                                // N demand of the plant (uptake from soil)  g/(pl*d)

// In the next lines we are now loooking if there is some translocatable N left for the N storage pool
// first we substract N stem
    If (NStem_pl.c>0) and (NTrans_pl.v+NStoragepool_pl.v>0) then
      NTrans_pl.v := NTrans_pl.v-Nstem_pl.c;

// N translocation to stem growth
    If Nstem_pl.c < 0 then            // should normall not occure
      NTrans_pl.v := NTrans_pl.v - NStem_pl.c;
                                                // negative changes of N in stem are stored ....
// then Nleaf
    If (NLeaf_pl.c>0) and (NTrans_pl.v+NStoragepool_pl.v>0) then
      NTrans_pl.v := NTrans_pl.v-NLeaf_pl.c;
                                                // N translocation to leaf growth

// if the N demand for growth is larger than translocatable N + Storagepool
// then all of the storagepool is used
    If NTrans_pl.v+NStoragepool_pl.v<0 then
       NTrans_pl.v :=-NStoragepool_pl.v;

// if not all translocatable N is used for stem or leaf growth the remainder is stored
    NStoragepool_pl.c := NTrans_pl.v;

    NUptake.c := NDemand_pl.v*plants.v*10000/1000;
  end;
end;


procedure TSubPartitioningVegNew.Integrate;

begin
//  Exlfw.V := LFWT_pl.v;

  inherited  integrate;
  MyLAI.v := LAI.v;

// Initialise growth at emergence
 If (ISTAGE.v<5) then
  If (ISTAGE.v>=1) and (LFWT_pl.v<=0) then begin
    LFWT_pl.v   := INI_LFWT_pl.v;                      // Initialize stem weight
    STMWT_pl.v  := exp(g.v*ln(LFWT_pl.v)+h.v/ln(1/plants.v));         // Initialize stem weight
    SEEDRV.v    := Ini_SEEDRV.v;// 0.05; // 0.012;
    NLeaf_pl.v  := LFWT_pl.v * NOptLeaf.v/100;
    NStem_pl.v  := STMWT_pl.v * NOptStem.v/100;
    NShoot_pl.v := NLeaf_pl.v + NStem_pl.v;
 end;
  CropHeight.v := LAI.v/5+0.05; // first proxy for crop height

(*  If (ISTAGE.v>=4) and (SWMIN.v<=0) then SWMIN.v := STMWT_pl.v;
                                          // save value of Stemweight for labile*)

//  If (ISTAGE.v>=5) and (gppend.v<=0) then begin
//    grnwt.v  := 0.0035*gpp.v;                  // Initialize Grains
//    STMWT_pl.v := STMWT_pl.v-GRNWT.v;                //
//    If (gppend.v <=0.0) then
//      gppend.v := gpp.v;
//  end;

  TOPWT_pl.v := LFWT_pl.v+STMWT_pl.v+SEEDRV.v;    // top weight per plant


  STMWT_m2.v := STMWT_pl.v*Plants.v;
  SENWT_m2.v := Senwt_pl.v*Plants.v;
  NSEN_m2.v := NSen_pl.v*plants.v;


  LFWT_m2.v :=  LFWT_pl.v*Plants.v;

  RTWT_m2.v :=  RTWT_pl.v*plants.v;

  TOPWT_m2.v :=  {GRNWT_m2.v+}LFWT_m2.v+STMWT_m2.v;

  if LFWT_pl.v>0 then NcLeaf.v := NLeaf_pl.v/LFWT_pl.v*100 else NcLeaf.v :=0;  // aktuelle Blatt N-Konzentration
  if (EC.v>= EC_LGEnd.v) and (NcLeaf_ECLGE.v = 0) then NcLeaf_ECLGE.v:= NcLeaf.v;
  if STMWT_pl.v>0 then NcStem.v := NStem_pl.v/STMWT_pl.v*100;  // aktuelle Stängel N-Konzentration

  NLeaf_m2.v := NLeaf_pl.v*plants.v;
  NSTEM_m2.v := NStem_pl.v*plants.v;
  NStoragepool_m2.v := NStoragepool_pl.v*plants.v;
  NShoot_pl.v := NLeaf_pl.v + NStem_pl.v + NStoragepool_pl.v;
  NShoot_m2.v := NShoot_pl.v*plants.v;
  NDemand.v := NDemand_pl.v*plants.v*10000/1000;
  if TOPWT_m2.v>0 then NcShoot.v := NShoot_m2.v/TOPWT_m2.v*100 else NcShoot.v := 0;
  if TOPWT_m2.v>0 then fstem_av.v:= STMWT_m2.v/TOPWT_m2.v else fstem_av.v:=0;
end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningVegNew]);
end;

end.
