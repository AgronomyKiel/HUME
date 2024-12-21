unit UHumeWheatPartitioning;

(*
  Developer: A.M. Ratjen
  - Modul for carbon and nitrogen partitioning on organ level (root, stem, leaves, grains)
  see Appendix Diss. Ratjen 2012)
  - C translocation to grains according to experimental results of 103, 94 (see Appendix Diss. Ratjen 2012)
  - N concentrations in organs during vegetative growth adapted from
  TSubPartitioningVegNew (U. Böttcher, Meyer-Schatz), but modified for drought stress
  according to experimental results of 103 2010 (see Diss. Ratjen Appendix)
  - leaf N distribution is calculated for specific leaf layers at anthesis
  according to experimental results of 103 10 (Appendix Diss. Ratjen )
  - N dynamics similar to Bertheloot 2008 (see Appendix Diss. Ratjen )
  - sigmoid grain filling (Okt. 2015)
  - Partitioning of N deficit according to Ratjen & Kage 2016 (JACS)
*)

interface

uses
  Windows, USoilNitrogenUp, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls,
  vcl.Forms, vcl.Dialogs,  Development, UHumeWheatDryMatter, UHumeWheatLeafArea, USimpleRootModDM,
  UMod, UState, UAbstractPlant;

type
  TRSWT = (gf_cwt3, gf_pothi);
  TDroughtImpact = (DroughtImpact, NoDroughtImpact);
  TNImpact = (NImpact, NoNImpact);
  TPTF_version = (PTF_CERES, PTF_Kage);

  THumeWheatPartitioning = class(TAbstractPlant)

  private
    K_GF, INI_GF, r_GF, R0_GF: real; /// Parameter for logistic grain filling
    fRSWT: TRSWT;  /// Type of grain filling algorithm?
    dNSP_l: real; /// change rate of N-storage pool leaf
    dNSP_s: real; /// change rate of N-storage pool stem
    NLStruc_m2: real;  ///  structural leaf N per square meter
    PAR_arr: array [1 .. 45] of real; /// CumPAR for Q45
    MTEMP_arr: array [1 .. 45] of real; /// CumMTemp for Q45
    // ProzN, critN: real;
    Nph_c: real;
    NDeg: real;
    NSyn: real;
    Np2, nc_: real;
    Swmin: real;
    SumGRHI: real;
    SumTempHI: real;
    Ndsen: real;
    procedure CreateAllVars;
    procedure CreateAllStates;
    procedure CreateAllExternV;
    procedure CreateAllPars;
    procedure CreateAllOptions;
    procedure CalcSeedRV_Change;
    procedure Calc_Leaf_N_Change;
    procedure InitStatesAfterEmergence; /// fraction of senescent leaf N wich is caused by drought stress
    // not going into the mobile N pool;

    // procedure SetUpDateValue;
  protected
    fDroughtImpact: TDroughtImpact;
    fNImpact: TNImpact;
	fDevelopmentModel: TDevelopment;
    fDrymatterModel: THumeWheatDryMatter;
    fLeafAreaModel: THumeWheatLeafArea;
    fRootModel: TSimpleRootModDM;
    procedure setDevelopmentModel(AModel: TDevelopment);
    procedure setDrymatterModel(AModel: THumeWheatDryMatter);
    procedure setLeafAreaModel(AModel: THumeWheatLeafArea);
    procedure setRootModel(AModel: TSimpleRootModDM);
    procedure SetLai(NewLAI: THumeNumEntity); override;
    function GetLAI:THumeNumEntity; override;
    function GetWLD(Index:Integer):THumeNumEntity; override;
    function GetSumRootLength:THumeNumEntity; override;
    function GetSumRootLength_eff:THumeNumEntity; override;
    function GetCropHeight: THumeNumEntity; override;
    function GetNUptakeRate: THumeNumEntity; override;
    procedure SetCropHeight(NewCropHeight: THumeNumEntity); override;
    function getExtCoeffPAR: real; // override;

  public
    NNIcrit: TPar; /// Ratjen & Kage 2015 (2016?)
    NNIinc: TPar; /// Ratjen & Kage 2015 (2016?)
    pNdefAllo: TPar;
    maxNNI: TPar;
    QHI_INT: TPar;
    QHI_INC: TPar;
    fRootN_ini: TPar; /// initial ratio of RootN/ShootN
    fRootN_min: TPar; /// minimum ratio of RootN/ShootN
    TTfRootN: TPar; /// TSUM of min rootN
    EC_LGend: TPar; /// end EC for leaf growth
    maxNcStem: TPar;
    RND: TPar;
    k_SEEDRV: TPar; /// mobilisation constant for seed reseves
    psi_crit: TPar;
    psi_s: TPar;
    PsiSen1: TPar;
    PsiSen2: TPar;
    RNS: TPar;
    K1: TPar;
    K2: TPar;
    pHI1: TPar;
    pHI2: TPar;
    pDMTrans: TPar; /// translozierbarer Anteil der seneszenten Trockenmasse (%)
    NcStemMin: TPar; /// niedrigste Stängel N-Konzentration (%)
    NcStem_a: TPar; /// Parameter für Stängel N-Verdünnungsfunktion
    NcStem_b: TPar; /// Parameter für Stängel N-Verdünnungsfunktion
    rgr_NcLeafWinter: TPar; /// Zuwachsrate für die Blatt N-Konzentration im Winter
    rgr_NcStemWinter: TPar; /// Zuwachsrate für die Stängel N-Konzentration im Winter
    NcLeafMin: TPar; /// niedrigste Blatt N-Konzentration bis Frühjahr (%)
    ECcritNcLeaf: TPar; /// kritisches EC-Stadium bis zu dem N-Konz.= NcLeafWinter
    fFineRoot0: TPar;
    FFineRootDec: TPar;
    Plants: TPar; /// number of plants per square meter
    rgr_GrainN: TPar;
    GM4: TPar; /// fit parameter for calculation of GPSM
    GM4_2: TPar; /// fit parameter for calculation of GPSM
    Ini_SEEDRV: TPar; /// initial seed weight (g/pl)
    h: TPar; /// Proportionalitaetskonstante Blatt-Stängel-Verteilung}
    g: TPar; /// Proportionalitaetskonstante Blatt-Stängel-Verteilung}
    relLayerN_S: array [1 .. 3] of TPar;
    relLayerN_int: array [1 .. 3] of TPar;
    iniGRNWT: TPar;
    dECDP: TPar; /// duration of endosperm cell devision phase
    HImin: TPar;
    // pRGFILL:   TPar;
    NcLeafVf1: TPar; /// Steigung der Leaf N-Verdünnungsfunktion
    NcLeafVf2: TPar; /// Intercept der Leaf N-Verdünnugsfunktion
    maxNupTake: TPar;



    iniLA: TPar;
    NRoot_pl: TState;
    NSen_pl: TState; /// N in senescent leaves [g/plant]
    Senwt_pl: TState; /// Senescent leaf weight [g/plant]
    STMWT_pl: TState; /// Stem weight of an average tiller after terminal spikelet  [g]
    NGrain_pl: TState;
    NShoot_pl: TState; /// Spross N-Menge (g/Pflanze)
    CropHeight: TState; /// plant height [m]
    SEEDRV: TState; /// Reserve carbohydrates in seed for use by plant in seedling stage [g/plant]
    NcLeafWinter: TState; /// N conc. Leaf Winter (%) Strahlungsabhängig
    NcStemWinter: TState; /// N conc. Stem Winter (%) Strahlungsabhängig
    GRNWT_pl: TState; /// Weight of grains [g/plant]
    LFWT_pl: TState; /// Leaf weight of all leaves on a plant [g/plant]
    TEMPsum: TState; /// Temperature sum
    //DMFineRoot: TState; // Root weight - [g/m2]
    RTWT_pl: TState; /// Root weight - [g/plant]
    NLeaf_pl: TState; /// Blatt N-Menge (g/Pflanze)
    NStem_pl: TState; /// Stängel N-Menge (g/Pflanze)
    NStoragepool_pl: TState; /// intermediate storage pool (g N/pl)
    NUptake: TState; /// NUptake from the soil (cum. NDemand) [kg/ha]

   // NUptakeRate_pot: TVar; // potenzielle N-Aufnahmerate  g/m²*d
    PTF: TVar; /// Fraction of photosynthesis partitioned to above ground plant parts [-]
    GROSTM: TVar; /// Daily stem growth  [g/(plant.d]
    Ndef: TVar; /// pot. N-uptake - act. N-uptake
    Assiflow: TVar; /// total flux of assimliates for growth (CARBO+SEEDRV)
    NNI: TVar;
    FFineroot: TVar; /// fraction of assimilates allocated to fine roots
    NStemstruc_pl: TVar;
    NNI60: TVar;
    RSWT: TVar;
    NSP_l: TVar;
    NSP_S: TVar;
    sumNLAL: TVar;
    NStoragepool_m2: TVar; /// intermediate storage pool (g/m²)
    LFWT_m2: TVar; /// leaf weight per square meter [g/m2]
    Leaf_Stem_WT_Ratio, Stem_Leaf_WT_Ratio: TVar; ///Ratio of Leaf and Stem dry weight and inverse
    GN_NRate: TVar;
    SUMDTTGF: TVar;
    NcLeaf: TVar; /// Blatt N-Konzentration (%)
    SENL: TVar; /// Leaf senscence rate [g/(plant.d]
    NoptStem: TVar; /// optimum N concentration stem(%)
    Nc_optLeaf: TVar; /// optimum N concentration leaf(%)
    fStem: TVar; /// fraction of shoot growth into stem dry matter
    NLphot_pl: TVar;
    NcStem: TVar; /// Stängel N-Konzentration (%)
    NcShoot: TVar; /// Spross N-Konzentration (%)
    STMWT_m2: TVar; /// Stem weight per square meter [g/m2]
    SENWT_m2: TVar; /// Dead Leaf weight per square meter [g/m2]
    // Nmob_m2:   TVar;        // N available in the common pool (J. Bertheloot et al. 2008)
    TSDM_m2: TVar; /// Total Shoot drymatter (incl. Stroh)
    NStem_m2: TVar; /// Stängel N-Menge (g/m²)
    DMTrans_pl: TVar; /// translozierbare Trockenmasse (g/Pflanze)
    TOPWT_pl: TVar; /// weight of tops without grains [g/plant]
    TOPWT_m2: TVar;
    GROLF: TVar; /// Daily leaf growth [g/plant/d]
    Q45: TVar;
    NcLeaf_ECLGE: TVar; /// N concentration at the end of leaf growth
    //NUPRate: TVar;
    GPPVAR: TVar;
    maxNShoot_m2: TVar;
    relTM_L1: TVar;
    relTM_L2: TVar;
    relTM_L3: TVar;
    relTM_L4: TVar;
    relBF_L1: TVar;
    relBF_L2: TVar;
    relBF_L3: TVar;
    relBF_L4: TVar;
    GPP: TVar;
    NcStruc: TVar;
    NcStem_ECLGE: TVar;
    NHI: TVar;
    NDemand: TVar; /// nitrogen demand (kg/ha/d)
    RGFILL: TVar; /// Rate of grain fill - [mg/(Plant*day)]
    TKM: TVar;
    NLStruc_pl: TVar;
    NShoot_m2: TVar; /// Spross N-Menge (g/m²)
    NcStraw: TVar;
    NGrain_m2: TVar;
    Ncmob: TVar; /// calculated mobile N concentration
    potGrainN_pl: TState;
    potGROGRN: TVar;
    GPSM: TVar; /// Körner pro m2 [n]
    GROGRN: TVar; /// Daily growth of the grain  [g/(Plant*day)]
    GRYD: TVar; /// Ertrag [dt/ha]
    HI: TVar;
    potHI: TVar;
    NcGrain: TVar;
    pINIGN: TVar; /// initial grain N per grain
    ProtGrain: TVar;
    GRNWT_m2: TVar;
    KernelN: TVar;
    SLN: TVar;
    optSLN: TVar;
    R: TVar;
    NSEN_m2: TVar; /// N in dead leaves [g/m2]
    QHI: TVar;
    NTrans_pl: TVar; /// translozierbare N-Menge (g/Pflanze)
    NLeaf_m2: TVar; /// Blatt N-Menge (g/m²)
    NRoot_m2: TVar; /// Wurzel N-Menge (g/m²)
    NDemand_pl: TVar; /// N demand per plant [g/(pl*d)]
    ActNUptake_m2: TVar; /// limited N uptake from soil model
    Nbal: TVar;
    PlantNDemand_rate_limited_m2: Tvar; /// pot. Plant N demand limited by maxNupTake
    actPlantNupTake_m2: Tvar; /// actual N uptake rate
    LAIShoot: TVar;

    DaysEffGF:TVar; /// days from BBCH65 unitil LAI=0;
    TSUMEffGF:TVar;
    GlobRadSum:TVar;
    QEffGF:TVar; /// Photo-Thermal-Ratio during BBCH65 until LAI=0;
    NphLeaf: array [1 .. 4] of TVar; /// photosynthetic N in lamina i


    fdsen: TExternV;
    TransIntRatio: TExternV;
    TEMPM: TExternV; /// average daily air temperature
    XSTAGE: TExternV; /// Development stage according do CERES
    ISTAGE: TExternV; /// Development stage according do CERES
    DayOfYear: TExternV;
    PSIroot: TExternV;
    P5: TExternV;
    Rad_Int: TExternV;
    kPAR: TExternV;
    SumMLAL: TExternV;
    SumLAL: TExternV;
    potSLA: TExternV;
    exk_PAR: TExternV; /// extinction coefficient for photosynthetically active radiation
    LAI: TExternV; /// leaf area index
    CARBO: TExternV; /// Daily carbohydrate production (g/pl/d)

    GlobRad: TExternV;
    LAL: array [1 .. 4] of TExternV;
    NcLAL: array [1 .. 4] of TVar;
    NLeaf_struc: array [1 .. 4] of TVar;
    PARi: array [1 .. 4] of TExternV;
    MLAL: array [1 .. 4] of TExternV; /// green leaf mass of layer

    // Varianz der Einzelmesswerte LAI2000 Messwerte aus Updatemethode von TSubModel
    optRSWT: TOption;
    OptDroughtimpact: TOption;
    OptNimpact: TOption;

    avSLA: TExternV;
    EC: TExternV; /// EC-Stage

    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure CalcNNI;
    procedure CalcQ45;
    procedure CalcGPSM;
    procedure GRFILL;
    procedure CalcNRates;
    procedure setNimpact;
    procedure Allometric_Leaf_Stem_Partitioning;
    procedure calc_rootDMandN;

  published
    Property Var_NUptakeRate: TVar read PlantNDemand_rate_limited_m2 write PlantNDemand_rate_limited_m2;
    Property St_RTWT: TState read RTWT_pl write RTWT_pl;
    Property Var_GROLF: TVar read GROLF write GROLF;
    Property Var_AssiFlow: TVar read Assiflow write Assiflow;
    Property Ex_GlobRad: TExternV read GlobRad write GlobRad;
    property Ex_avSLA: TExternV Read avSLA Write avSLA;
    property Ex_PSIroot: TExternV Read PSIroot Write PSIroot;
    property Ex_SumMLAL: TExternV Read SumMLAL Write SumMLAL;
    property Ex_SumLAL: TExternV Read SumLAL Write SumLAL;
    property Ex_kPAR: TExternV Read kPAR Write kPAR;
    property Ex_Rad_Int: TExternV Read Rad_Int Write Rad_Int;
    property Ex_P5: TExternV Read P5 Write P5;
    property Ex_EC: TExternV read EC write EC;
    property Par_EC_LGend: TPar read EC_LGend write EC_LGend;
    Property Ex_ISTAGE: TExternV read ISTAGE write ISTAGE;
    Property St_LFWT: TState read LFWT_pl write LFWT_pl;
    Property Par_Plants: TPar read Plants write Plants;
    Property St_STMWT: TState read STMWT_pl write STMWT_pl;
    Property Var_GROSTM: TVar read GROSTM write GROSTM;
    property Par_FFineRoot0: TPar read fFineRoot0 write fFineRoot0;
    property Par_FFineRootDec: TPar read FFineRootDec write FFineRootDec;
    Property St_TempSum: TState read TEMPsum write TEMPsum;
    property opt_DroughtImpact
      : TDroughtImpact read fDroughtImpact write fDroughtImpact;
    property opt_NImpact: TNImpact read fNImpact write fNImpact;
    //Property St_DMFineRoot: TState read DMFineRoot write DMFineRoot;
    Property Ex_CARBO: TExternV read CARBO write CARBO;
    Property Ex_TEMPM: TExternV read TEMPM write TEMPM;
    Property Var_LFWT_m2: TVar read LFWT_m2 write LFWT_m2;
    Property Ex_exk_PAR: TExternV read exk_PAR write exk_PAR;
	Property DevelopmentModel: TDevelopment read fDevelopmentModel write setDevelopmentModel;
    Property DrymatterModel: THumeWheatDryMatter read fDrymatterModel write setDrymatterModel;
    Property LeafAreaModel: THumeWheatLeafArea read fLeafAreaModel write setLeafAreaModel;
    Property RootModel: TSimpleRootModDM read fRootModel write setRootModel;
    Property Var_LAIShoot: TVar read LAIShoot write LAIShoot;

  end;

procedure Register;

implementation

uses Math;

procedure THumeWheatPartitioning.setDevelopmentModel(AModel: TDevelopment);
begin
  fDevelopmentModel := AModel;
  EC.Search := false;
  EC.f_v := @DevelopmentModel.EC.fv;
  EC.Source := '['+DevelopmentModel.Name+']';
  ISTAGE.Search := false;
  ISTAGE.f_v := @DevelopmentModel.ISTAGE.fv;
  ISTAGE.Source := '['+DevelopmentModel.Name+']';
  XSTAGE.Search := false;
  XSTAGE.f_v := @DevelopmentModel.XSTAGE.fv;
  XSTAGE.Source := '['+DevelopmentModel.Name+']';
//  P5STAGE.Search := false;
//  P5STAGE.f_v := @DevelopmentModel.P5STAGE.fv;
//  P5STAGE.Source := '['+DevelopmentModel.Name+']';

  if LeafAreaModel is THumeWheatLeafArea then begin
    LeafAreaModel.EC.Search := false;
    LeafAreaModel.EC.setPointer(@DevelopmentModel.EC.fv);
    LeafAreaModel.EC.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.ISTAGE.Search := false;
    LeafAreaModel.ISTAGE.setPointer(@DevelopmentModel.ISTAGE.fv);
    LeafAreaModel.ISTAGE.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.P5.Search := false;
    LeafAreaModel.P5.setPointer(@DevelopmentModel.P5.fv);
    LeafAreaModel.P5.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.Phint.Search := false;
    LeafAreaModel.Phint.setPointer(@DevelopmentModel.Phint.fv);
    LeafAreaModel.Phint.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.TSumInc.Search := false;
    LeafAreaModel.TSumInc.setPointer(@DevelopmentModel.Teff.fv);
    LeafAreaModel.TSumInc.Source := '['+DevelopmentModel.Name+']';
  end;

end;

procedure THumeWheatPartitioning.setDrymatterModel(AModel: THumeWheatDryMatter);
begin
  fDrymatterModel := AModel;
  CARBO.Search := false;
  CARBO.f_v := @DrymatterModel.CARBO.fv;
  CARBO.Source := '['+DrymatterModel.Name+']';
  exk_PAR.Search := false;
  exk_PAR.f_v := @DrymatterModel.kPar_eff.fv;
  exk_PAR.Source := '['+DrymatterModel.Name+']';

  DrymatterModel.Plants.Search := false;
  DrymatterModel.Plants.setPointer(@Plants.fv);
  DrymatterModel.Plants.Source := '['+Name+']';
  DrymatterModel.NcLeaf.Search := false;
  DrymatterModel.NcLeaf.setPointer(@NcLeaf.fv);
  DrymatterModel.NcLeaf.Source := '['+Name+']';
  DrymatterModel.SLN.Search := false;
  DrymatterModel.SLN.setPointer(@SLN.fv);
  DrymatterModel.SLN.Source := '['+Name+']';

  if LeafAreaModel is THumeWheatLeafArea then begin
    LeafAreaModel.kPAR.Search := false;
    LeafAreaModel.kPAR.setPointer(@DrymatterModel.kPAR.fv);
    LeafAreaModel.kPAR.Source := '['+DrymatterModel.Name+']';
    LeafAreaModel.PAR.Search := false;
    LeafAreaModel.PAR.setPointer(@DrymatterModel.PAR.fv);
    LeafAreaModel.PAR.Source := '['+DrymatterModel.Name+']';
    DrymatterModel.LAI.Search := false;
    DrymatterModel.LAI.setPointer(@LeafAreaModel.LAI.fv);
    DrymatterModel.LAI.Source := '['+LeafAreaModel.Name+']';
  end;
end;

procedure THumeWheatPartitioning.setLeafAreaModel(AModel: THumeWheatLeafArea);
var
  i: integer;
begin
  fLeafAreaModel := AModel;
  fdsen.Search := false;
  fdsen.f_v := @LeafAreaModel.fdsen.fv;
  fdsen.Source := '['+LeafAreaModel.Name+']';
  LAI.Search := false;
  LAI.f_v := @LeafAreaModel.LAI.fv;
  LAI.Source := '['+LeafAreaModel.Name+']';
  for i := 1 to 4 do begin
    LAL[i].Search := false;
    LAL[i].f_v := @LeafAreaModel.LAL[i].fv;
    LAL[i].Source := '['+LeafAreaModel.Name+']';
    MLAL[i].Search := false;
    MLAL[i].f_v := @LeafAreaModel.MLAL[i].fv;
    MLAL[i].Source := '['+LeafAreaModel.Name+']';
    PARi[i].Search := false;
    PARi[i].f_v := @LeafAreaModel.PARi[i].fv;
    PARi[i].Source := '['+LeafAreaModel.Name+']';
  end;
  potSLA.Search := false;
  potSLA.f_v := @LeafAreaModel.potSLA.fv;
  potSLA.Source := '['+LeafAreaModel.Name+']';
  SumLAL.Search := false;
  SumLAL.f_v := @LeafAreaModel.SumLAL.fv;
  SumLAL.Source := '['+LeafAreaModel.Name+']';
  SumMLAL.Search := false;
  SumMLAL.f_v := @LeafAreaModel.SumMLAL.fv;
  SumMLAL.Source := '['+LeafAreaModel.Name+']';
  LeafAreaModel.LFWT_m2.Search := false;
  LeafAreaModel.LFWT_m2.setPointer(@LFWT_m2.fv);
  LeafAreaModel.LFWT_m2.Source := '['+Name+']';
  LeafAreaModel.EC_lgend.Search := false;
  LeafAreaModel.EC_lgend.setPointer(@EC_lgend.fv);
  LeafAreaModel.EC_lgend.Source := '['+Name+']';
  LeafAreaModel.GROLF.Search := false;
  LeafAreaModel.GROLF.setPointer(@GROLF.fv);
  LeafAreaModel.GROLF.Source := '['+Name+']';
  LeafAreaModel.LFWT_pl.Search := false;
  LeafAreaModel.LFWT_pl.setPointer(@LFWT_pl.fv);
  LeafAreaModel.LFWT_pl.Source := '['+Name+']';
  for i := 1 to 4 do begin
    LeafAreaModel.NcLAL[i].Search := false;
    LeafAreaModel.NcLAL[i].setPointer(@NcLAL[i].fv);
    LeafAreaModel.NcLAL[i].Source := '['+Name+']';
  end;
  LeafAreaModel.plants.Search := false;
  LeafAreaModel.plants.setPointer(@plants.fv);
  LeafAreaModel.plants.Source := '['+Name+']';
  LeafAreaModel.SENL.Search := false;
  LeafAreaModel.SENL.setPointer(@SENL.fv);
  LeafAreaModel.SENL.Source := '['+Name+']';

  if DevelopmentModel is TDevelopment then begin
    LeafAreaModel.EC.Search := false;
    LeafAreaModel.EC.setPointer(@DevelopmentModel.EC.fv);
    LeafAreaModel.EC.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.ISTAGE.Search := false;
    LeafAreaModel.ISTAGE.setPointer(@DevelopmentModel.ISTAGE.fv);
    LeafAreaModel.ISTAGE.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.P5.Search := false;
    LeafAreaModel.P5.setPointer(@DevelopmentModel.P5.fv);
    LeafAreaModel.P5.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.Phint.Search := false;
    LeafAreaModel.Phint.setPointer(@DevelopmentModel.Phint.fv);
    LeafAreaModel.Phint.Source := '['+DevelopmentModel.Name+']';
    LeafAreaModel.TSumInc.Search := false;
    LeafAreaModel.TSumInc.setPointer(@DevelopmentModel.Teff.fv);
    LeafAreaModel.TSumInc.Source := '['+DevelopmentModel.Name+']';
  end;

  if DrymatterModel is THumeWheatDryMatter then begin
    LeafAreaModel.kPAR.Search := false;
    LeafAreaModel.kPAR.setPointer(@DrymatterModel.kPAR.fv);
    LeafAreaModel.kPAR.Source := '['+DrymatterModel.Name+']';
    LeafAreaModel.PAR.Search := false;
    LeafAreaModel.PAR.setPointer(@DrymatterModel.PAR.fv);
    LeafAreaModel.PAR.Source := '['+DrymatterModel.Name+']';
    DrymatterModel.LAI.Search := false;
    DrymatterModel.LAI.setPointer(@LeafAreaModel.LAI.fv);
    DrymatterModel.LAI.Source := '['+LeafAreaModel.Name+']';
    //DrymatterModel.SumDTT5.Search := false;
    //DrymatterModel.SumDTT5.setPointer(@LeafAreaModel.SumDTT5.fv);
    //DrymatterModel.SumDTT5.Source := '['+LeafAreaModel.Name+']';
  end;
end;

procedure THumeWheatPartitioning.setRootModel(AModel: TSimpleRootModDM);
begin
  fRootModel := AModel;
  withRoots := true;
  RootModel.DMFineRoot.Search := false;
  RootModel.DMFineRoot.setPointer(@DMFineRoot.fv);
  RootModel.DMFineRoot.Source := '['+Name+']';
  RootModel.DMroot_inc.Search := false;
  RootModel.DMroot_inc.setPointer(@DMFineRoot.c);
  RootModel.DMroot_inc.Source := '['+Name+']';
  RootModel.SowingDate := SowingDate;
end;




procedure THumeWheatPartitioning.SetLai(NewLAI: THumeNumEntity);

begin
  p_LAI := NewLAI;
end;

function THumeWheatPartitioning.GetLAI:THumeNumEntity;
begin
  result:= LAIShoot;
end;

function THumeWheatPartitioning.GetCropHeight: THumeNumEntity;

begin
  result := CropHeight;
end;

procedure THumeWheatPartitioning.SetCropHeight(NewCropHeight: THumeNumEntity);

begin
  p_CropHeight := NewCropHeight;
end;

function THumeWheatPartitioning.getExtCoeffPAR: real;
begin
  result := exk_PAR.v;
end;

procedure THumeWheatPartitioning.createAll;

begin
  inherited createAll;
  CreateAllVars;
  CreateAllStates;
  CreateAllExternV;
  CreateAllPars;
  CreateAllOptions;

end;

procedure THumeWheatPartitioning.Allometric_Leaf_Stem_Partitioning;
var
  kf_n, kf_d, fStem_: real;

begin
  if (EC.v < EC_LGend.v) and (ISTAGE.v >= 1) and (LFWT_pl.v > 0) then
  begin
    // kf discribes the influence of psi-root to stem partitioning
    if (fDroughtImpact = DroughtImpact) then
      kf_d := max(1, 1 + (PSIroot.v - psi_crit.v) * psi_s.v)
    //    kf_d := 1
    else
      kf_d := 1;
    if (fNImpact = NImpact) and (NNI.v > 0) then
      kf_n := max(1, 1 + (NNIcrit.v - NNI.v) * NNIinc.v)
    else
      kf_n := 1;

        fStem_ := (1 - 1 / (1 + exp(h.v ) * power(LFWT_m2.v, g.v - 1) * g.v));
    fStem.v := min(1, fStem_ * max(kf_d, kf_n));
    STMWT_pl.c := Assiflow.v * fStem.v;
    LFWT_pl.c := Assiflow.v - STMWT_pl.c;
  end
  else
  begin
    STMWT_pl.c := Assiflow.v;
    if (ISTAGE.v >= 1) then
      fStem.v := 1;
    LFWT_pl.c := 0.0;
  end;
  GROLF.v := LFWT_pl.c;
end;

procedure THumeWheatPartitioning.calc_rootDMandN;
begin
  PTF.v := min(1, 1 - (fFineRoot0.v - FFineRootDec.v * TEMPsum.v));
  // Kage unpublished ....Ch. 10 Habil.

  If (fDroughtImpact = DroughtImpact) and (ISTAGE.v < 5) then
    PTF.v := PTF.v - 0.1 * (1 - TransIntRatio.v);
  // to increase root mass under drough stress

  If (fNImpact = NImpact) and (ISTAGE.v < 5) then
    PTF.v := PTF.v - 0.1 * (1 - NNI.v); // to increase root mass under drough stress

  FFineroot.v := max(0, 1 - PTF.v);

  if (TEMPsum.v < TTfRootN.v) then
    NRoot_pl.c := (NShoot_pl.v * (fRootN_ini.v - (fRootN_ini.v - fRootN_min.v)
          * (TEMPsum.v / TTfRootN.v))) - NRoot_pl.v
  else
    NRoot_pl.c := 0;

  if (NRoot_pl.c < 0) then
    NStoragepool_pl.c := NStoragepool_pl.c - NRoot_pl.c;

  DMFineRoot.c := Assiflow.v * Plants.v * FFineroot.v; // per m2
  RTWT_pl.c := Assiflow.v * FFineroot.v; // per plant
  Assiflow.v := Assiflow.v - RTWT_pl.c; // substract root growth
end;

procedure THumeWheatPartitioning.InitStatesAfterEmergence;
begin
  begin
    // initialize leaf and stem weight
    LFWT_pl.v := iniLA.v / potSLA.v;
    STMWT_pl.v := exp(g.v * ln(LFWT_pl.v * plants.v) + h.v) / plants.v;
    SEEDRV.v := Ini_SEEDRV.v;
    NLeaf_pl.v := LFWT_pl.v * Nc_optLeaf.v / 100;
    NStem_pl.v := STMWT_pl.v * NoptStem.v / 100;
    NShoot_pl.v := NStoragepool_pl.v + NLeaf_pl.v + NStem_pl.v + NGrain_pl.v;
    NRoot_pl.v := NShoot_pl.v * fRootN_ini.v;
  end;
end;

procedure THumeWheatPartitioning.Calc_Leaf_N_Change;
begin
  if EC.v >= ECcritNcLeaf.v then
  begin
    Nc_optLeaf.v := NcLeafVf1.v * LFWT_m2.v + NcLeafVf2.v;
    NcLeafWinter.c := 0;
  end
  else
  begin
    if DayOfYear.v < 150 then
      if TEMPM.v > 0 then
        // transitional phase between autumn and spring
        NcLeafWinter.c := (NcLeafWinter.v - NcLeafMin.v) * rgr_NcLeafWinter.v * GlobRad.v * (1 - (NcLeafWinter.v - NcLeafMin.v) / (NcLeafVf1.v * LFWT_m2.v + NcLeafVf2.v - NcLeafMin.v));
    Nc_optLeaf.v := NcLeafWinter.v;
  end;
  NLeaf_pl.c := LFWT_pl.c * Nc_optLeaf.v / 100 + Nc_optLeaf.v / 100 * LFWT_pl.v - NLeaf_pl.v;
end;

procedure THumeWheatPartitioning.CalcSeedRV_Change;
begin
  if (ISTAGE.v >= 0.99) and (ISTAGE.v < 2) and (SEEDRV.v > 0) then
  begin
    SEEDRV.c := -k_SEEDRV.v * SEEDRV.v;
    Assiflow.v := Assiflow.v - SEEDRV.c;
  end
  else
    // addition of seed reserves to assiflow
    SEEDRV.c := 0;
end;

procedure THumeWheatPartitioning.CreateAllOptions;
begin
  OptCreate('optRSWT', 'pothi', optRSWT);
  optRSWT.OptionList.Clear;
  optRSWT.OptionList.Add('pothi');
  optRSWT.OptionList.Add('CWT3');
  OptCreate('optDroughtimpact', 'DroughtImpact', OptDroughtimpact);
  OptDroughtimpact.OptionList.Clear;
  OptDroughtimpact.OptionList.Add('DroughtImpact');
  OptDroughtimpact.OptionList.Add('NoDroughtImpact');
  OptCreate('optNimpact', 'NoNImpact', OptNimpact);
  OptNimpact.OptionList.Clear;
  OptNimpact.OptionList.Add('NImpact');
  OptNimpact.OptionList.Add('NoNImpact');
end;

procedure THumeWheatPartitioning.CreateAllPars;
var
  i: Integer;
begin
  for i := 1 to 4 do
  begin
    // Lamina N distribution according to Bertheloot 2008 observed at LAI4
    if i = 1 then
      ParCreate('relLayerN_S' + IntToStr(i), '[%]', 0.0104, relLayerN_S[i]);
    if i = 2 then
      ParCreate('relLayerN_S' + IntToStr(i), '[%]', 0.017, relLayerN_S[i]);
    if i = 3 then
      ParCreate('relLayerN_S' + IntToStr(i), '[%]', -0.0071, relLayerN_S[i]);
    if i = 1 then
      ParCreate('relLayerN_Int' + IntToStr(i), '[%]', 0.3305, relLayerN_int[i]);
    if i = 2 then
      ParCreate('relLayerN_Int' + IntToStr(i), '[%]', 0.2783, relLayerN_int[i]);
    if i = 3 then
      ParCreate('relLayerN_Int' + IntToStr(i), '[%]', 0.2292, relLayerN_int[i]);
  end;
  ParCreate('maxNNI', '[-]', 1.5, maxNNI);
  ParCreate('pNdefAllo', '[-]', 0.63, pNdefAllo, 'fraction of N defizit allocated to the stem');
  ParCreate('k_SEEDRV', '[-]', 0.15, k_SEEDRV);
  // mobilisation constant for seed reserves
  ParCreate('psi_s', '[1/pF]', 0.2956942, psi_s, 'for calculation of kf (allometric leaf/stem partitioning)');
  ParCreate('h', '[-]', -2.13, h);
  // Meyer-Schatz DBU Endbericht
  ParCreate('g', '[-]', 1.46, g);
  // Meyer-Schatz DBU Endbericht
  ParCreate('NNIcrit', '[-]', 1.377, NNIcrit);
  ParCreate('NNIinc', '[-]', 0.595, NNIinc);
  ParCreate('Ini_SEEDRV', '[-]', 0.05, Ini_SEEDRV);
  ParCreate('rgr_NcLeafWinter', '[-]', 0.02, rgr_NcLeafWinter);
  ParCreate('rgr_NcStemWinter', '[-]', 0.02, rgr_NcStemWinter);
  ParCreate('psi_crit', '[pF]', 2.24499, psi_crit, 'for calculation of kf (allometric leaf/stem partitioning)');
  ParCreate('NcLeafVf1', '[-]', -0.0061, NcLeafVf1);
  // aus Daten 950506 N4
  ParCreate('NcLeafVf2', '[-]', 5.9543, NcLeafVf2);
  // aus Daten 950506 N4
  ParCreate('rgr_GrainN', '[-]', 0.005, rgr_GrainN);
  ParCreate('dECDP', '[°cd]', 250, dECDP, 'duration of endosperm cell devision phase');
  ParCreate('RND', '[/°cd]', 0.008, RND, 'rel. rate of phot. N degradation');
  ParCreate('RNS', '[/°cd]', 0.0015, RNS, 'rel. rate of phot. N synthesis');
  ParCreate('QHI_INT', '[-]', 0.2786, QHI_INT, 'for calculation of potHI');
  ParCreate('QHI_INC', '[-]', 0.196, QHI_INC, 'for calculation of potHI');
  ParCreate('ECcritNcLeaf', '[-]', 27, ECcritNcLeaf);
  ParCreate('iniGRNWT', '[mg/grain]', 3.5, iniGRNWT, 'initial grain weight (CW 3)');
  ParCreate('iniLA', '[cm2]', 5, iniLA);
  //ParCreate('GPSM_EXP', '[-]', 2.6233, GPSM_EXP,
  //  'parameter for calculation of GPSM see Diss Ratjen');
  ParCreate('k1', '[kg/kg]', 0.0018, K1, 'Michaelis-Menten cons. to mobile N');
  ParCreate('k2', '[J/(m2*s)]', 10, K2, 'Michaelis-Menten cons. to PARi');
  ParCreate('GM4', '[-]', 144.6, GM4, 'adjustment of grain number per sqare meter');
  ParCreate('GM4_2', '[-]', 2.6233, GM4_2, 'exponential adjustment of grain number per sqare meter');
  // ParCreate('piniGN', '[mg/1K grains]', 210, piniGN,
  // 'initial grain N of a single grain at the beginning of the endosperm cell division phase');
  // ParCreate('pRGFILL', '[-]', 0.00127, pRGFILL);
  ParCreate('EC_LGend', '[-]', 39, EC_LGend);
  ParCreate('pHI1', '[-]', 0.2641838, pHI1);
  ParCreate('pHI2', '[-]', 0.0004443, pHI2);
  ParCreate('NcStemMin', '[%]', 4, NcStemMin);
  ParCreate('HImin', '[-]', 0.51, HImin);
  ParCreate('NcLeafMin', '[%]', 4.5, NcLeafMin);
  ParCreate('Plants', '[plants/m2]', 350, Plants);
  ParCreate('pDMTrans', '[%]', 25, pDMTrans);
  ParCreate('maxNcStem', '[/]', 7, maxNcStem);
  // Ratjen & Kage submitted 2015
  ParCreate('NcStem_a', '[-]', 0.1475, NcStem_a);
  // aus Daten 950506 N4
  ParCreate('NcStem_b', '[-]', 0.0011, NcStem_b);
  // aus Daten 950506 N4
  ParCreate('fFineRoot0', '[-]', 0.653, fFineRoot0);
  // Parameter aus Habil Kage Kap. 10
  ParCreate('fFineRootDec', '[-]', 0.000501, FFineRootDec);
  // Parameter aus Habil Kage Kap. 10
  ParCreate('PsiSen1', '[pF]', 3.6, PsiSen1);
  ParCreate('PsiSen12', '[1/pF]', 2.5, PsiSen2);
  ParCreate('fRootN_ini', '[]', 0.4, fRootN_ini);
  ParCreate('fRootN_min', '[]', 0.1, fRootN_min);
  ParCreate('TTfRootN', '[]', 2000, TTfRootN, 'Tsum at which fRootN_min is reached');
  ParCreate('maxNupTake', '[kgN/ha]', 6, maxNupTake, 'parameter to avoid unrealistic high N uptake if maxNupTake is faulty');
end;

procedure THumeWheatPartitioning.CreateAllExternV;
var
  i: Integer;
begin
  ExternVCreate('avSLA', '', statefield, avSLA);
  ExternVCreate('TransintRatio', '', statefield, TransIntRatio);
  ExternVCreate('GlobRad', '[W/m2]', statefield, GlobRad);
  ExternVCreate('P5', '', statefield, P5);
  ExternVCreate('SumMLAL', '', statefield, SumMLAL);
  ExternVCreate('SumLAL', '', statefield, SumLAL);
  ExternVCreate('kPAR', '', statefield, kPAR);
  ExternVCreate('fdsen', '', statefield, fdsen);
  ExternVCreate('PSIroot', '', statefield, PSIroot);
  ExternVCreate('potSLA', '[cm2/g]', statefield, potSLA);
  ExternVCreate('GlobRad', '', statefield, GlobRad);
  ExternVCreate('EC', '', statefield, EC);
  ExternVCreate('ISTAGE', '', statefield, ISTAGE);
  ExternVCreate('XSTAGE', '', statefield, XSTAGE);
  ExternVCreate('CARBO', '', statefield, CARBO);
  ExternVCreate('TEMPM', '', statefield, TEMPM);
  ExternVCreate('DayOfYear', '', statefield, DayOfYear);
  ExternVCreate('LAI', '', statefield, LAI);
  ExternVCreate('kpar_eff', '', statefield, exk_PAR);
  // extinction coefficient for photosynthetically active radiation
  for i := 1 to 4 do
  begin
    // Vier Blattetagen
    ExternVCreate('LAL_' + IntToStr(i), '[m2/m2]', statefield, LAL[i]);
  end;
  for i := 1 to 4 do
  begin
    // Vier Blattetagen
    ExternVCreate('PARi' + IntToStr(i), '[W/m2]', statefield, PARi[i]);
  end;
  for i := 1 to 4 do
  begin
    // Vier Blattetagen
    ExternVCreate('MLAL' + IntToStr(i), '[g/m2]', statefield, MLAL[i]);
  end;
end;

procedure THumeWheatPartitioning.CreateAllStates;
begin
  StateCreate('NStoragepool_pl', '[g/plant]', 0, true, NStoragepool_pl);
  StateCreate('NRoot_pl', '[g/plant/d]', 0, true, NRoot_pl);
  // StateCreate('DMFineRoot', '[g/m2]', 0, true, DMFineRoot);
  StateCreate('CropHeight', '[m]', 0, true, CropHeight);
  StateCreate('NUptake', '[kg/ha]', 0, true, NUptake);
  StateCreate('NShoot_pl', '[g/plant]', 0, true, NShoot_pl);
  StateCreate('STMWT_pl', '[g]', 0, true, STMWT_pl);
  StateCreate('NGrain_pl', '[g/plant]', 0, true, NGrain_pl);
  StateCreate('GRNWT_pl', '[g/plant]', 0, true, GRNWT_pl);
  StateCreate(' potGrainN_pl', '[g/Plant]', 0, true, potGrainN_pl);
  StateCreate('LFWT_pl', '[g/plant]', 0, true, LFWT_pl);
  StateCreate('TempSum', '[g/plant]', 0, true, TEMPsum);
  StateCreate('RTWT_pl', '[g/plant]', 0, true, RTWT_pl);
  StateCreate('SEEDRV', '[g/plant]', 0, true, SEEDRV);
  StateCreate('NcLeafWinter', '[%]', 4.51, true, NcLeafWinter);
  StateCreate('NcStemWinter', '[%]', 4.01, true, NcStemWinter);
  StateCreate('NLeaf_pl', '[g/plant]', 0, true, NLeaf_pl);
  StateCreate('NStem_pl', '[g/plant]', 0, true, NStem_pl);
  StateCreate('Senwt_pl', '[g/plant]', 0, true, Senwt_pl);
  StateCreate('NSen_pl', '[g/plant]', 0, true, NSen_pl);
end;

procedure THumeWheatPartitioning.CreateAllVars;
var
  i: Integer;
begin
  VarCreate('maxNShoot_m2', '[g/m2]', 0, true, maxNShoot_m2);
  VarCreate('GPPVAR', '[grains/plant]', 0, true, GPPVAR, 'estimation of grains per plant');
  // VarCreate('NUptakeRate_pot', 'g m-2 d-1', 0, true, NUptakeRate_pot,
  //   'pot. N-Nup rate (g.m-2.d-1)');
  VarCreate('Ndef', '[g/m2]', 0, true, Ndef);
  VarCreate('FFINEROOT', '[-]', 0, true, FFineroot);
  VarCreate('GROLF', '[g/plant/d]', 0, true, GROLF, 'growth rate of leaf dry matter');
  VarCreate('Assiflow', '[g/m2/d]', 0, true, Assiflow);
  VarCreate('NSP_l', '[kg N/ha]', 0, true, NSP_l, 'N storage pool leaf');
  VarCreate('NSP_s', '[kg N/ha]', 0, true, NSP_S);
  VarCreate('GROSTM', '[g/(plant.d]', 0, true, GROSTM);
  VarCreate('NcStraw', '[]', 0, true, NcStraw);
  VarCreate('SENL', '[g/(plant.d]', 0, true, SENL);
  VarCreate('LFWT_m2', '[g/m2]', 0, true, LFWT_m2);
  VarCreate('Leaf_Stem_WT_Ratio', '[g/m2]', 0, true, Leaf_Stem_WT_Ratio, 'Ratio of Leaf and Stem dry weight');
  VarCreate('Stem_Leaf_WT_Ratio', '[g/m2]', 0, true, Stem_Leaf_WT_Ratio, 'Ratio of Stem and Leaf dry weight');
  VarCreate('NSEN_m2', '[g/m2]', 0, true, NSEN_m2);
  VarCreate('NLeaf_m2', '[g/m2]', 0, true, NLeaf_m2);
  VarCreate('NRoot_m2', '[g/m2]', 0, true, NRoot_m2);
  VarCreate('relTM_L1', '[]', 0, true, relTM_L1);
  VarCreate('relTM_L2', '[]', 0, true, relTM_L2);
  VarCreate('relTM_L3', '[]', 0, true, relTM_L3);
  VarCreate('relTM_L4', '[]', 0, true, relTM_L4);
  VarCreate('relBF_L1', '[]', 0, true, relBF_L1);
  VarCreate('relBF_L2', '[]', 0, true, relBF_L2);
  VarCreate('relBF_L3', '[]', 0, true, relBF_L3);
  VarCreate('relBF_L4', '[]', 0, true, relBF_L4);
  VarCreate('NShoot_m2', '[g/m2]', 0, true, NShoot_m2);
  VarCreate('SLN', '[g/m2]', 0, true, SLN, 'over all specific leaf nitrogen');
  VarCreate('optSLN', '[g/m2]', 0, true, optSLN, 'SLN at Ncleaf = Nc_optLeaf');
  VarCreate('Ncmob', '[]', 0, true, Ncmob);
  VarCreate('TKM', '[g/kKernel]', 0, true, TKM);
  VarCreate('RGFILL', '[mg/(Plant*day)]', 0, true, RGFILL);
  VarCreate('R', '[-]', 0, true, R, 'Ratio mobileN /photN');
  VarCreate('potGROGRN', '[g/(Plant*day)]', 0, true, potGROGRN);
  VarCreate('RSWT', '[g/m2]', 0, true, RSWT, 'stem reserves during grain filling');
  VarCreate('Q45', '[-]', 0, true, Q45);
  VarCreate('GROGRN', '[g/(plant*d)]', 0, true, GROGRN);
  VarCreate('NcStem', '[%]', 0, true, NcStem);
  VarCreate('GRYD', '[dt/ha]', 0, true, GRYD);
  VarCreate('GPSM', '[k/m2]', 0, true, GPSM);
  VarCreate('NNI', '[-]', 0, true, NNI);
  VarCreate('NcLeaf', '[%]', 0, true, NcLeaf);
  VarCreate('NcShoot', '[%]', 0, true, NcShoot);
  VarCreate('NTrans_pl', '[g/plant]', 0, true, NTrans_pl);
  VarCreate('NcLeaf_ECLGE', '', 0, true, NcLeaf_ECLGE, 'leaf N concentration at the end of leaf growth');
  VarCreate('STMWT_m2', '[g/m2]', 0, true, STMWT_m2);
  VarCreate('SENWT_m2', '[g/m2]', 0, true, SENWT_m2);
  VarCreate('NDemand', '[kg/ha/d]', 0, true, NDemand);
  VarCreate('NStemstruc_pl', '[g/plant]', 0, true, NStemstruc_pl);
  VarCreate('NNI60', '[-]', 0, true, NNI60);
  VarCreate('TSDM_m2', '[g/m2]', 0, true, TSDM_m2);
  VarCreate('GRNWT_m2', '[g/m2]', 0, true, GRNWT_m2);
  VarCreate('HI', '[-]', 0, true, HI);
  VarCreate('potHI', '[-]', 0, true, potHI);
  VarCreate('NGrain_m2', '[g/m2]', 0, true, NGrain_m2);
  VarCreate('NcGrain', '[%]', 0, true, NcGrain);
  VarCreate('NDemand_pl', '[g/(pl*d)]', 0, true, NDemand_pl);
  VarCreate('ProtGrain', '[%]', 0, true, ProtGrain);
  VarCreate('KernelN', '[kg/ha]', 0, true, KernelN);
  VarCreate('NHI', '[-]', 0, true, NHI);
  VarCreate('NLStruc_pl', '[g/plant]', 0, true, NLStruc_pl);
  VarCreate('NcStem_ECLGE', '[g/plant]', 0, true, NcStem_ECLGE);
  //VarCreate('NupRate', '[g/m2]', 0, true, NUPRate, 'daily N-uptake rate');
  VarCreate('GN_NRate', '[g/plant]', 0, true, GN_NRate, 'linear N uptake after endosperm cell division phase');
  VarCreate('NStem_m2', '[g/m2]', 0, true, NStem_m2);
  VarCreate('NStoragepool_m2', '[g/m2]', 0, true, NStoragepool_m2);
  VarCreate('GPP', '[grains/plant]', 0, true, GPP, 'grains per plant');
  VarCreate('SUMDTTGF', '[°Cd]', 0, true, SUMDTTGF, 'sum of thermal time since start of grainfilling');
  VarCreate('fStem', '[-]', 0, true, fStem);
  VarCreate('PTF', '[-]', 0, true, PTF);
  VarCreate('Nc_optLeaf', '[%]', 0, true, Nc_optLeaf);
  VarCreate('NoptStem', '[%]', 0, true, NoptStem);
  VarCreate('TOPWT_pl', '[g/plant]', 0, true, TOPWT_pl);
  VarCreate('TOPWT_m2', '[g/m2] ', 0, true, TOPWT_m2);
  VarCreate('Nbal', '[g/plant] ', 0, true, Nbal);
  VarCreate('QHI', '[MJ/°C]', 0, true, QHI);
  VarCreate('ActNUptake_m2', '[g/m2/d]', 0, true, ActNUptake_m2);
  VarCreate('PlantNDemand_rate_limited_m2', '[g/m2/d]', 0, true, PlantNDemand_rate_limited_m2, 'pot. Plant N demand limited by maxNupTake');
  VarCreate('LAIShoot', '[m2/m2]', 0, true, LAIShoot);
  VarCreate('actPlantNupTake_m2', '[g/m2/d]', 0, true, actPlantNupTake_m2, 'actual plant N uptake rate');
  for i := 1 to 4 do
  begin
    // Vier Blattetagen
    VarCreate('NcLAL__' + IntToStr(i), '[%]', 0, true, NcLAL[i]);
  end;
  for i := 1 to 4 do
  begin
    // Vier Blattetagen
    VarCreate('NphLeaf' + IntToStr(i), '[g/m2]', 0, true, NphLeaf[i]);
  end;
  for i := 1 to 4 do
  begin
    // Vier Blattetagen
    VarCreate('NLeaf_Struc' + IntToStr(i), '[g/m2]', 0, true, NLeaf_struc[i]);
  end;
  VarCreate('NLphot_pl', '[g/plant]', 0, true, NLphot_pl);
  // ParCreate('piniGN', '[mg/1K grains]', 210, piniGN,
  VarCreate('piniGN', '[mg/1K grains]', 0, true, pINIGN);
  VarCreate('NcStruc', '[%]', 0, true, NcStruc);
  VarCreate('sumNLAL', '[g/plant]', 0, true, sumNLAL);
  VarCreate('DMTrans_pl', '[g/plant]', 0, true, DMTrans_pl);
  // no impact, just for labeling
  VarCreate('DaysEffGF', '[d]', 0, true, DaysEffGF, 'days from BBCH65 unitil LAI=0');
  VarCreate('TSUMEffGF', '[C°]', 0, true, TSUMEffGF);
  VarCreate('GlobRadSum', '[MJ]', 0, true, GlobRadSum);
  VarCreate('QEffGF', '[MJ/C°]', 0, true, QEffGF, 'Photo-Thermal-Ratio during BBCH65 until LAI=0');
end;

procedure THumeWheatPartitioning.CalcRates;

var
  NearOptNCStem : real;

begin
  LAIShoot.v := LAI.v;
  Assiflow.v := CARBO.v + DMTrans_pl.v;    // daily assimilation + translocation

  if (GlobTime.v >= SowingDate.v) and (ISTAGE.v >= 1) then
  begin
    TEMPsum.c := max(TEMPM.v, 0); // rate of change of temperature sum
  end;
  CalcSeedRV_Change;
  calc_rootDMandN;
  Allometric_Leaf_Stem_Partitioning;
  Calc_Leaf_N_Change;
  NearOptNCStem :=  0.98 * (1 / (NcStem_a.v + NcStem_b.v * STMWT_m2.v)) ;
  if NcStemWinter.v >=  NearOptNCStem then begin
    NoptStem.v := 1 / (NcStem_a.v + NcStem_b.v * STMWT_m2.v);
    NcStemWinter.c := 0;
  end else begin
    if DayOfYear.v < 150 then
      if TEMPM.v > 0 then
        NcStemWinter.c := (NcStemWinter.v - NcStemMin.v)
          * rgr_NcStemWinter.v * GlobRad.v * (1 - (NcStemWinter.v - NcStemMin.v) /
            (1 / (NcStem_a.v + NcStem_b.v * STMWT_m2.v) - NcStemMin.v));
    NoptStem.v := NcStemWinter.v;
  end;
  // structural N concentration as minimum
  NoptStem.v := max(NcStruc.v, NoptStem.v);

  NStem_pl.c := max(0, // 'dilution curve' will not reduce total N
    STMWT_pl.c * NoptStem.v / 100 + (NoptStem.v / 100 * STMWT_pl.v - NStem_pl.v));

  if ISTAGE.v >= 1.0 then
  begin
    LFWT_pl.c := max(-LFWT_pl.v, LFWT_pl.c - SENL.v);
    // correction of net change of leaf dry matter due to senescence
    DMTrans_pl.v := SENL.v * pDMTrans.v / 100;
    // translocatable fraction of DM change  g/(pl*d)
    Senwt_pl.c := SENL.v * (1 - pDMTrans.v / 100);
    // non translocatable fraction of DM remains as dead leaves
    NLeaf_pl.c := NLeaf_pl.c - SENL.v * NcLeaf.v / 100;
    // correction net change of leaf N for leaf senescence
  end;
  // calc. of translocatable carbon fraction of the stem
  if (EC.v > 50) and (EC.v < 75) then
  begin
    SumGRHI := GlobRad.v + SumGRHI;
    SumTempHI := TEMPM.v + SumTempHI;
    QHI.v := SumGRHI / SumTempHI;
  end;
  if (fRSWT = gf_pothi) and (EC.v >= 60) then
  begin
    potHI.v := QHI_INC.v * QHI.v + QHI_INT.v;
    Swmin := max(0, (STMWT_m2.v - (TSDM_m2.v * potHI.v - GRNWT_m2.v))
        / Plants.v);
    RSWT.v := STMWT_m2.v - (Swmin * Plants.v);
  end
  else if (EC.v >= 50) and (Swmin <= 0) and (fRSWT = gf_cwt3) then
    Swmin := STMWT_pl.v
  else
    Swmin := 0;

  if (GPSM.v <= 0) and (EC.v >= 40) then
    CalcGPSM;
  if (EC.v >= 40) and (EC.v < 90) then
    GRFILL
  else
  begin
    GROGRN.v := 0;
    GRNWT_pl.c := 0;
    CalcQ45;
  end;

  CalcNRates;

  if ((Ndsen > 0) and (PSIroot.v > PsiSen1.v)) then
  begin
    // reduce also stem mass if drought induced leaf senescence occurs.
    Senwt_pl.c := Senwt_pl.c + STMWT_pl.v * (Ndsen / NStem_pl.v) *
      ((PsiSen1.v - PSIroot.v) * PsiSen2.v);
    STMWT_pl.c := STMWT_pl.c - STMWT_pl.v * (Ndsen / NStem_pl.v) *
      ((PsiSen1.v - PSIroot.v) * PsiSen2.v);
  end;

  // transfer of shoot N and C to senescent pool at the end of grain filling
  if (EC.v > 90) and (STMWT_pl.v > 0) then
  begin
    Senwt_pl.c := STMWT_pl.v + LFWT_pl.v;
    LFWT_pl.c := -LFWT_pl.v;
    STMWT_pl.c := -STMWT_pl.v;
    NSen_pl.c := NStoragepool_pl.v + NStem_pl.v + NLeaf_pl.v + NRoot_pl.v;
    NStem_pl.c := -NStem_pl.v;
    NLeaf_pl.c := -NLeaf_pl.v;
    NRoot_pl.c:= -NRoot_pl.v;
    NStoragepool_pl.c := -NStoragepool_pl.v;
    NSP_l.v := 0;
    NSP_S.v := 0;
  end;
   //NUPRate.v:= PlantNDemand_rate_limited_m2.v; // interface SoilNitrogenUp
end;

procedure THumeWheatPartitioning.setNimpact;
(*
  distribute N defizit to organs (leaf,stem), according to Ratjen & Kage 2015
  63% of the N-defizit is allocated to the stem fraction
  *)
var
  Ndef_pl,Ndef_pl_ ,diff: real;
  NRoot_pl_c, Nleaf_pl_c, Nstem_pl_c, Ngrain_pl_c, NStoragepool_pl_c: real;
  Ndef_Stem_pl,Ndef_pl_shoot, Ndef_Leaf_pl, minNstem_pl,minNroot_pl, maxdNroot, maxdNStem: real;
  fL, fR: real;
  i: integer;
begin
  if (Ndef.v > 0) then
  begin
    Ndef_pl := Ndef.v / Plants.v;
    Ndef_pl_:= Ndef_pl;
    NRoot_pl_c := NRoot_pl.c;
    Nleaf_pl_c := NLeaf_pl.c;
    Nstem_pl_c := NStem_pl.c;
    Ngrain_pl_c := NGrain_pl.c;
    NStoragepool_pl_c := NStoragepool_pl.c;
    minNstem_pl := (STMWT_pl.v)*(NcStruc.v/100);
    minNroot_pl := Rtwt_pl.v*(NcStruc.v/100);
    maxdNroot:=max(0,Nroot_pl.v-minNroot_pl);
    maxdNStem:=max(0,NStem_pl.v-minNStem_pl);
    // first substract Ndef from N storrage pool
    NStoragepool_pl.c := max(-NStoragepool_pl.v, NStoragepool_pl.c - Ndef_pl);
    Ndef_pl := Ndef_pl - (NStoragepool_pl_c - NStoragepool_pl.c);
    // now subtract N def. of the root - (assuming proportionality to organs)
    if (NShoot_pl.v > 0) and ((STMWT_pl.v+ LFWT_pl.v)>0) then
      fR := Rtwt_pl.v / (STMWT_pl.v+ LFWT_pl.v)
    else
      fR := 0;
    NRoot_pl.c := max(-maxdNroot, NRoot_pl.c - Ndef_pl * fR);
    // substracting root def. from total def.
    Ndef_pl_shoot := Ndef_pl + (NRoot_pl.c - NRoot_pl_c);
    // NoneLeaf
    Ndef_Stem_pl:= Ndef_pl_shoot * pNdefAllo.v;
    Ndef_Leaf_pl:= Ndef_pl_shoot - Ndef_Stem_pl;
    // grains (no negative N flow)
    if (NGrain_pl.c>0) then begin
      NGrain_pl.c := min(Ngrain_pl_c, max(0,
           NGrain_pl.c - Ndef_Stem_pl * (NGrain_pl.v / (NStem_pl.v + NGrain_pl.v))));
      Ndef_Stem_pl := Ndef_Stem_pl + (NGrain_pl.c - Ngrain_pl_c);
    end;

    NStem_pl.c:= max(- maxdNStem, Nstem_pl_c - Ndef_Stem_pl);
    Ndef_Stem_pl:= Ndef_Stem_pl + (NStem_pl.c - NStem_pl_c);
    // possible difference to the leaf fraction
    Ndef_Leaf_pl:=Ndef_Leaf_pl+ Ndef_Stem_pl;
    // Leaf
    NLeaf_pl.c:= NLeaf_pl.c - Ndef_Leaf_pl;
    Ndef_Leaf_pl:= Ndef_Leaf_pl + (NLeaf_pl.c - NLeaf_pl_c);
    // rel. change rate of leaf N
    if((NLeaf_pl_c + NLeaf_pl.v)>0) then
      fL:=  (NLeaf_pl.c + NLeaf_pl.v)/(NLeaf_pl_c + NLeaf_pl.v)
      else fL:=0;

    if (GPSM.v > 0) and (fL<1) then
      for i := 1 to 4 do
      begin
        NphLeaf[i].v := NphLeaf[i].v * fL;
      end;
    Nbal.v:= (NStem_pl.c + NLeaf_pl.c + NGrain_pl.c  +
            NStoragepool_pl.c + NRoot_pl.c) -
            (NStem_pl_c + NLeaf_pl_c + NGrain_pl_c  +
             NStoragepool_pl_c + NRoot_pl_c)+Ndef_pl_ ;
    actPlantNupTake_m2.v:= max(NStem_pl.c + NLeaf_pl.c + NGrain_pl.c + NSen_pl.c +
        NStoragepool_pl.c + NRoot_pl.c, 0) * Plants.v;
    NUptake.c :=actPlantNupTake_m2.v*10;

  end
  else begin // not limited by soil
    actPlantNupTake_m2.v:=PlantNDemand_rate_limited_m2.v;
    NUptake.c := actPlantNupTake_m2.v*10;
  end;


end;

procedure THumeWheatPartitioning.CalcNRates;
(*
  N-translocation during grain filling phase:
  - leaf N fractions:
  - photosynthetic
  - structural
  - mobile
  - mobile N fraction is calculated for each individual layer
  - the amount of mobile N as well as leaf shading are controling synthesis or
  degeneration of photosynthetic leaf N (Thornley 1998, Bertheloot 2008)
  - N uptake to the grains only from mobile N pool
  - therefore a strong sink (grain N) lowers the N synthesis rate through
  - ratio of mobile to photosynthetic N pool in leaves (r) controls the N release
  of the stem
  - none structural N from senescent leaf tissue goes to the mobile N pool
  (except for N from drought accelerated leaf senescence)
  *)
var
  i: integer;
  LAI_: real;
  XSTAGE_: real;
  maxNStem: real;
begin
  CalcNNI;
  Ndsen := 0;
  XSTAGE_ := max(5, XSTAGE.v); // needed for NcStruc (refers to grain filling phase)
  // calculating fraction of structural N
  NcStruc.v := 2.97 - 0.455 * XSTAGE_; // according to Ceres Wheat
  NStemstruc_pl.v := STMWT_pl.v * NcStruc.v / 100;
  // calculation of structural N per leaf layer
  NLStruc_pl.v := 0;
  for i := 1 to 4 do
  begin
    if LFWT_pl.v + LFWT_pl.c > 0 then
    begin
      NLeaf_struc[i].v := MLAL[i].v * (NcStruc.v / 100);
      NLStruc_pl.v := NLStruc_pl.v + NLeaf_struc[i].v / Plants.v;
    end
    else
    begin
      NLeaf_struc[i].v := 0;
    end;
  end;
  NLStruc_m2 := NLStruc_pl.v * Plants.v;
  { ***calculating initial grain N***
    'piniGN' is the amount of N for a single grain at the begin of
    endosperm cell division phase (Bertheloot 2008)
    }
  if (EC.v > 50) and (potGrainN_pl.v <= 0) then
  // sliding N accumulation of initial grain N from BBHC 40 to 65
  begin
    // initial N concentration of grains is proportional to leaf N concentration
    if (pINIGN.v = 0) then
      pINIGN.v := NcLeaf.v * iniGRNWT.v * 10;
      NGrain_pl.c := pINIGN.v * (1 / 1E6) * GPPVAR.v * min(1,
      (EC.v - 50) / (65 - 50)) - NGrain_pl.v;
      NStem_pl.c := NStem_pl.c - NGrain_pl.c; // initial N comes from the stem fraction
    if GPSM.v > 0 then
      potGrainN_pl.v := NGrain_pl.v;
  end;

  if GPSM.v <= 0 then
  begin // before grain filling
    // the none structural fraction of leaf N is translocatable
    NTrans_pl.v := max(0, (SENL.v * (NcLeaf.v - NcStruc.v) / 100));
    (*
      - translocatable fraction of leaf N change  g/(pl*d)
      - in the next lines we are now loooking if there is some translocatable N
      left for the N storage pool
      first we substract N stem
      *)
    if (NStem_pl.c > 0) and (NTrans_pl.v + NStoragepool_pl.v > 0) then
      NTrans_pl.v := NTrans_pl.v - NStem_pl.c;
    // N translocation to stem growth
    if NStem_pl.c < 0 then // should normally not occure
      NTrans_pl.v := NTrans_pl.v - NStem_pl.c;
    // negative changes of N in stem is stored .... then Nleaf
    if (NLeaf_pl.c > 0) and (NTrans_pl.v + NStoragepool_pl.v > 0) then
      NTrans_pl.v := NTrans_pl.v - NLeaf_pl.c;
    // N translocation to leaf growth
    // if the N demand for growth is larger than translocatable N + Storagepool
    // then all of the storagepool is used
    if NTrans_pl.v + NStoragepool_pl.v < 0 then
      NTrans_pl.v := -NStoragepool_pl.v;
    // if not all translocatable N is used for stem or leaf growth the remainder
    // is stored
    NStoragepool_pl.c := NTrans_pl.v;
    // difine the initial amount of mobile N fraction for stem and leaf
    // (NSP_s; NSP_l) later needed for the calculation of stem N release
    // at grain filling
    if NLeaf_pl.v > 0 then
    begin
      NSP_l.v := NStoragepool_pl.v * (NLeaf_pl.v / (NStem_pl.v + NLeaf_pl.v));
      NSP_S.v := NStoragepool_pl.v - NSP_l.v;
    end
    else
    begin
      NSP_l.v := 0;
      NSP_S.v := 0;
    end;
    // leaf distrubution as a function of LAI
    LAI_ := max(2, min(6, LAI.v)); // limiting to range of measuremants at anthesis
    // rain-out-shelter exp. HS 103 2010)
    for i := 1 to 4 do
    begin
      if (MLAL[i].v > 0) and (LFWT_m2.v > 0) then
      begin
        if (i < 4) then
          NphLeaf[i].v := (relLayerN_int[i].v + relLayerN_S[i].v * LAI_) *
            (NLeaf_m2.v - (LFWT_m2.v * NcStruc.v / 100))
        else
          NphLeaf[i].v := NLeaf_m2.v - NphLeaf[1].v - NphLeaf[2].v - NphLeaf[3].v
             - NLeaf_struc[1].v - NLeaf_struc[2].v - NLeaf_struc[3].v
             - NLeaf_struc[4].v; // prevent rounding errors
      end
      else
        NphLeaf[i].v := 0;
    end;
    NLphot_pl.v := (NphLeaf[1].v + NphLeaf[2].v + NphLeaf[3].v + NphLeaf[4].v)
      / Plants.v;
  end
  else
  // ******** start of grain filling
  begin
    if GN_NRate.v = 0 then
      // intermediate value: relative N accumulation during linear phase (per 10^6 grains and °Cd)
      GN_NRate.v := pINIGN.v * power(1 + rgr_GrainN.v, dECDP.v) * rgr_GrainN.v;
    // adjustment of the leaf N for each layer by subtracting senescent leaf N
    for i := 1 to 4 do
    begin
      if (NLeaf_struc[i].v > 0) and (NcLAL[i].v > 0) then
      begin
        nc_ := (NphLeaf[i].v + NLeaf_struc[i].v) / MLAL[i].v * 100;
        // when the leaf mass of the layer is shrunken, the N concentration has changed
        if nc_ > NcLAL[i].v then
        begin
          Np2 := (MLAL[i].v * NcLAL[i].v) / 100;
          // the fraction of leaf tissue died by drought stress (fdsen= dsen/plar)
          // will not release N to the mobile N-pool
          Ndsen := ((NphLeaf[i].v - (Np2 - NLeaf_struc[i].v)) / Plants.v)
            * fdsen.v;
          NSP_l.v := NSP_l.v + ((NphLeaf[i].v - (Np2 - NLeaf_struc[i].v))
              / Plants.v) - Ndsen;
          NphLeaf[i].v := Np2 - NLeaf_struc[i].v;
        end;
      end;
    end;
    // N uptake of the grains
    if potGrainN_pl.v > 0 then
    begin
      // exponential N accumulation until liniear rate is achieved
      SUMDTTGF.v := SUMDTTGF.v + max(0, TEMPM.v);
      potGrainN_pl.c := (pINIGN.v * GPP.v * power(1 + rgr_GrainN.v,
          min(dECDP.v, SUMDTTGF.v)) * (1 / 1E6)) + // exponential uptake
        (GN_NRate.v * GPP.v * max(0, SUMDTTGF.v - dECDP.v) * (1 / 1E6)) -
      // linear uptake
        potGrainN_pl.v;
      // N accumulation during grain filling phase is limited by mobile N supply
      if EC.v < 90 then
        NGrain_pl.c := min((NSP_S.v + NSP_l.v), potGrainN_pl.c)
      else
        NGrain_pl.c := 0;
      // update of mobile N pools..
      if NGrain_pl.c > 0 then
      begin
        dNSP_s := max(-NSP_S.v, -NGrain_pl.c);
        // N translocation from stem first
        dNSP_l := max(-NSP_l.v, -(NGrain_pl.c + dNSP_s));
        NSP_l.v := max(0, NSP_l.v + dNSP_l);
        NSP_S.v := max(0, NSP_S.v + dNSP_s);
      end;
    end
    else
    begin
      potGrainN_pl.c := 0;
      NGrain_pl.c := 0;
    end;
    // calulating rate for photosynthetic N synthesis and degeneration for each leaf layer
    if (STMWT_pl.v + LFWT_pl.v) > 0 then
      Ncmob.v := (NSP_l.v + NSP_S.v) / (STMWT_pl.v + LFWT_pl.v)
    else
      Ncmob.v := 0;
    for i := 1 to 4 do // four leaf layers
    begin
      NDeg := (NphLeaf[i].v / 1000) * RND.v; // g->kg
      NSyn := RNS.v * (MLAL[i].v / 1000) * (Ncmob.v / (Ncmob.v + K1.v)) *
        (PARi[i].v / (PARi[i].v + K2.v));
      Nph_c := min(NphLeaf[i].v * 0.05, (NSyn - NDeg) * TEMPM.v * 1E3);
      if ((LFWT_pl.v + LFWT_pl.c) > 0) then
        NphLeaf[i].v := max(0,
          min(MLAL[i].v * (NcLeafVf2.v / 100) - NLeaf_struc[i].v,
            NphLeaf[i].v + Nph_c))
      else
        NphLeaf[i].v := 0;
    end;
    // updating leaf N translocation
    dNSP_l := NLphot_pl.v - (NphLeaf[1].v + NphLeaf[2].v + NphLeaf[3]
        .v + NphLeaf[4].v) / Plants.v;
    NSP_l.v := max(0, NSP_l.v + dNSP_l);
    NLphot_pl.v := (NphLeaf[1].v + NphLeaf[2].v + NphLeaf[3].v + NphLeaf[4].v)
      / Plants.v;
    NLeaf_pl.c := NLphot_pl.v + NLStruc_pl.v - NLeaf_pl.v;
    if (NLphot_pl.v > 0) and (NStem_pl.v - NStemstruc_pl.v > 0) then
      R.v := NSP_l.v / NLphot_pl.v // r= mob/ph
    else
      R.v := 0;
    // calculate the mobile fraction of stem N
    if NLphot_pl.v > 0 then
    begin
      dNSP_s := max(0, min(NStem_pl.v - NStemstruc_pl.v,
          max(0, (NStem_pl.v - NStemstruc_pl.v) * R.v - NSP_S.v)));
      NStem_pl.c := -dNSP_s;
    end
    else
    begin
      // transfer all mobile stem N to the storagepool
      // if leaves are total senescent
      dNSP_s := max(0, (NStem_pl.v - NStemstruc_pl.v));
      NStem_pl.c := -dNSP_s;
    end;
    NSP_S.v := max(0, NSP_S.v + dNSP_s);
    // updating change of mobile fraction
    NStoragepool_pl.c := max(-NStoragepool_pl.v,
      (NSP_S.v + NSP_l.v) - NStoragepool_pl.v);
  end; // ********
  // updating N concentration of the layers
  sumNLAL.v := 0;
  for i := 1 to 4 do
  begin
    if MLAL[i].v > 0 then
    begin
      NcLAL[i].v := ((NphLeaf[i].v + NLeaf_struc[i].v) / MLAL[i].v) * 100;
      sumNLAL.v := sumNLAL.v + NphLeaf[i].v + NLeaf_struc[i].v;
    end
    else
      NcLAL[i].v := 0;
  end;
  // calculation of senescent N pool (straw fraction)
  NSen_pl.c := SENL.v * (NcStruc.v / 100) + Ndsen;
  // transfer senescent stem N to the senescent pool
  if (NStem_pl.v > 0) and (STMWT_pl.v = 0) then
  begin
    NStem_pl.c := -NStem_pl.v;
    NSen_pl.c := NSen_pl.c + NStem_pl.v;
  end;
  // partitioning of luxury N uptake
  if (NShoot_m2.v < maxNShoot_m2.v) and (EC.v < EC_LGend.v) then
  begin
    maxNStem:=(STMWT_pl.v*maxNcStem.v/100);
    NStem_pl.c := NStem_pl.c + min(maxNStem-NStem_pl.v-NStem_pl.c,((maxNShoot_m2.v - NShoot_m2.v) * pNdefAllo.v)
      / Plants.v);
    NLeaf_pl.c := NLeaf_pl.c + ((maxNShoot_m2.v - (NShoot_pl.v*plants.v)) *
        (1 - pNdefAllo.v)) / Plants.v;
  end;
  if((LAI.v / 5 + 0.05) - CropHeight.v>0) then
    CropHeight.c := LAI.v / 5 + 0.05 - CropHeight.v else // first proxy for crop height
         CropHeight.c:=0;
  // N demand of the plant (net N uptake from soil)  g/(pl*d)
  NDemand_pl.v := max(NStem_pl.c + NLeaf_pl.c + NGrain_pl.c + NSen_pl.c +
      NStoragepool_pl.c + NRoot_pl.c, 0);
    // interface soil model
    // limited in order to avoid unrealistic high N-uptake rates
  PlantNDemand_rate_limited_m2.v := min(maxNupTake.v/10,  // X kgN/ha
                  NDemand_pl.v * Plants.v); // theoretical demand



end;

procedure THumeWheatPartitioning.Integrate;

begin
  if (SoilNitrogenMod <> nil) and (SoilNitrogenMod is TSoilNitrogenUp) then
  begin
    ActNUptake_m2.v := TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v / 10;
    if (ActNUptake_m2.v < (NDemand_pl.v * Plants.v)) and (fNImpact = NImpact) and (Ec.v<90) then
    begin
      Ndef.v := (NDemand_pl.v * Plants.v) - ActNUptake_m2.v; // kg/ha -> g/m2
      setNimpact
    end else begin
      NUptake.c := PlantNDemand_rate_limited_m2.v * 10;// g/m2  -> kg/ha
      actPlantNupTake_m2.v:=NUptake.c/10;
      Nbal.v:=0;
    end;
  end;

  inherited Integrate;
  If (ISTAGE.v < 5) then
    If (ISTAGE.v >= 1) and (LFWT_pl.v <= 0) and (EC.v < 20) then
      InitStatesAfterEmergence;


  TOPWT_pl.v := LFWT_pl.v + STMWT_pl.v + SEEDRV.v; // top weight per plant
  STMWT_m2.v := STMWT_pl.v * Plants.v;
  SENWT_m2.v := Senwt_pl.v * Plants.v;
  NSEN_m2.v := NSen_pl.v * Plants.v;
  LFWT_m2.v := LFWT_pl.v * Plants.v;
  if(LFWT_m2.v<>0) and (STMWT_m2.v<>0) and (EC.v <= 65) then begin
    Leaf_Stem_WT_Ratio.v:=LFWT_m2.v / STMWT_m2.v;
    Stem_Leaf_WT_Ratio.v:=STMWT_m2.v / LFWT_m2.v;
  end else begin
    Leaf_Stem_WT_Ratio.v:=0;
    Stem_Leaf_WT_Ratio.v:=0;
  end;

  if LFWT_pl.v > 0 then
    NcLeaf.v := NLeaf_pl.v / LFWT_pl.v * 100
  else
    NcLeaf.v := 0; // aktuelle Blatt N-Konzentration
  if (EC.v >= EC_LGend.v) and (NcLeaf_ECLGE.v = 0) then
    NcLeaf_ECLGE.v := NcLeaf.v;
  if STMWT_pl.v > 0 then
    NcStem.v := NStem_pl.v / STMWT_pl.v * 100;
  // aktuelle Stängel N-Konzentration
  if TOPWT_m2.v > 0 then
    NcShoot.v := NShoot_m2.v / TOPWT_m2.v * 100
  else
    NcShoot.v := 0;
  if (GRNWT_m2.v > 0) then
    HI.v := GRNWT_m2.v / TSDM_m2.v;
  if GPSM.v > 0 then
  begin
    TKM.v := (GRNWT_pl.v * Plants.v) / GPSM.v * 1000;
    GRYD.v := ((GRNWT_pl.v * Plants.v) / 10) * 1.1627907; // 14% residual moisture
    NSEN_m2.v := NSen_pl.v * Plants.v;
  end;

  NShoot_pl.v := NLeaf_pl.v + NStem_pl.v + NStoragepool_pl.v + NGrain_pl.v;
  TOPWT_pl.v := LFWT_pl.v + STMWT_pl.v + SEEDRV.v + GRNWT_pl.v;
  NStoragepool_m2.v := NStoragepool_pl.v * Plants.v;
  NSEN_m2.v := NSen_pl.v * Plants.v;

  TOPWT_m2.v := TOPWT_pl.v * Plants.v;
  NShoot_m2.v := NShoot_pl.v * Plants.v;
  NLeaf_m2.v := NLeaf_pl.v * Plants.v;
  NRoot_m2.v := NRoot_pl.v * Plants.v;
  NStem_m2.v := NStem_pl.v * Plants.v;
  if LAI.v > 0 then begin
    SLN.v := NLeaf_m2.v / LAI.v;
    optSLN.v := ((Nc_optLeaf.v/100)*LFWT_m2.v) / LAI.v
  end else begin
    SLN.v := 0;
    optSLN.v :=0;
  end;
  GRNWT_m2.v := GRNWT_pl.v * Plants.v;
  NGrain_m2.v := NGrain_pl.v * Plants.v;
  if NGrain_m2.v > 0 then
    NHI.v := NGrain_m2.v / (NShoot_m2.v + NSEN_m2.v);
  TSDM_m2.v := STMWT_m2.v + LFWT_m2.v + SENWT_m2.v + GRNWT_m2.v + DMTrans_pl.v * Plants.v;
  if (SENWT_m2.v > 0) then
    NcStraw.v := (NSen_pl.v / Senwt_pl.v) * 100;
  if (GRNWT_pl.v > 0) then
  begin
    NcGrain.v := 100 * (NGrain_pl.v / GRNWT_pl.v);
    ProtGrain.v := NcGrain.v * 5.7;
    KernelN.v := NGrain_m2.v * 10; // kgN/ha
  end;
  if SumMLAL.v > 0 then
  begin
    relTM_L1.v := MLAL[1].v / SumMLAL.v;
    relTM_L2.v := MLAL[2].v / SumMLAL.v;
    relTM_L3.v := MLAL[3].v / SumMLAL.v;
    relTM_L4.v := MLAL[4].v / SumMLAL.v;
  end
  else
  begin
    relTM_L1.v := 0;
    relTM_L2.v := 0;
    relTM_L3.v := 0;
    relTM_L4.v := 0;
  end;
  if SumLAL.v > 0 then
  begin
    relBF_L1.v := LAL[1].v / SumLAL.v;
    relBF_L2.v := LAL[2].v / SumLAL.v;
    relBF_L3.v := LAL[3].v / SumLAL.v;
    relBF_L4.v := LAL[4].v / SumLAL.v;
  end
  else
  begin
    relBF_L1.v := 0;
    relBF_L2.v := 0;
    relBF_L3.v := 0;
    relBF_L4.v := 0;
  end;

  if SumMLAL.v > 0 then
    NcLeaf.v := sumNLAL.v / SumMLAL.v * 100
  else
    NcLeaf.v := 0; // act leaf N concentration
  NDemand.v := NDemand_pl.v * Plants.v * 10; // kg/ha

  if((EC.v>64) and (LAI.v>0))then begin
  // no impact, just for labeling
  DaysEffGF.v:=DaysEffGF.v+1;
  TSUMEffGF.v:=TSUMEffGF.v+ TEMPM.v;
  GlobRadSum.v:=GlobRad.v;
  QEffGF.v:=  GlobRadSum.v/TSUMEffGF.v;


  end;

  N_Residues.v := NRoot_m2.v + NStem_m2.v + NLeaf_m2.v+ NSEN_m2.v;   // dneukam: ergänzt am 26.10.21
  C_Residues.v := (DMfineroot.v + STMWT_m2.v + LFWT_m2.v + SENWT_m2.v)*0.45 ;

end;

procedure THumeWheatPartitioning.Init(var GlobMod: TMod);
var
  i: integer;
begin
  inherited Init(GlobMod);
  SumGRHI := 0;
  SumTempHI := 0;
  Swmin := 0;
  if OptDroughtimpact.option = 'droughtimpact' then
  begin
    fDroughtImpact := DroughtImpact;
  end;
  if OptDroughtimpact.option = 'nodroughtimpact' then
  begin
    fDroughtImpact := NoDroughtImpact;
  end;

  if OptNimpact.option = 'nonimpact' then
    fNImpact := NoNImpact
  else
    fNImpact := NImpact;

  if optRSWT.option = 'cwt3' then
    fRSWT := gf_cwt3
  else
    fRSWT := gf_pothi;

  dNSP_l := 0;
  dNSP_s := 0;
  NLStruc_m2 := 0;
  // ProzN := 0;
  // critN := 0;
  Nph_c := 0;
  NDeg := 0;
  NSyn := 0;
  nc_ := 0;
  Np2 := 0;
  for i := 45 downto 1 do
  begin
    PAR_arr[i] := 0;
    MTEMP_arr[i] := 0;
  end;

end;

procedure THumeWheatPartitioning.GRFILL;
var
  Xmid, Xm, HI_potHI, R0: real;

begin
  // ***calculating initial grain weight ***
  if (EC.v > 40) and (GPSM.v <= 0) then
  // sliding N and C accumulation of initial grain N & C from EC 40 to 65
  begin
    GRNWT_pl.c := (iniGRNWT.v / 1000) * GPPVAR.v * min(1,
      (EC.v - 40) / (65 - 40)) - GRNWT_pl.v;
    // initial weight comes from the stem fraction
    STMWT_pl.c := STMWT_pl.c - GRNWT_pl.c;

  end
  else
  begin
    if GPSM.v > 0 then
    begin
      // logistic grain filling; side condition: at the end of grain filling
      Xm := (P5.v + 21.5) / 0.05; // unscale P5 parameter (length of grain filling)
      Xmid := dECDP.v; // inflection point at end of endosperm phase
      // initial value for HI/potHI
      INI_GF := ((GPP.v * (iniGRNWT.v / 1000)) / TOPWT_pl.v) / potHI.v;
      r_GF := ln(1 / INI_GF - 1) / Xmid;
      K_GF := ((exp(r_GF * Xm) - 1) * INI_GF) / (exp(r_GF * Xm) * INI_GF - 1);
      R0_GF := (K_GF - INI_GF) / INI_GF;
      HI_potHI := K_GF / (1 + R0_GF * exp(-r_GF * SUMDTTGF.v));
      potGROGRN.v := (TOPWT_pl.v + Senwt_pl.v)
        * potHI.v * HI_potHI - GRNWT_pl.v;
      GROGRN.v := max(0, min(potGROGRN.v, STMWT_pl.v - Swmin));
      STMWT_pl.c := STMWT_pl.c - GROGRN.v;
      GRNWT_pl.c := GROGRN.v;
    end;
  end;
end;

procedure THumeWheatPartitioning.CalcQ45;
var
  i: integer;
  SUMPAR, SUMMTEMP: real;
begin
  if (EC.v >= 20) and (EC.v < 60) then
  begin
    for i := 44 downto 1 do
    begin
      PAR_arr[i + 1] := PAR_arr[i];
      MTEMP_arr[i + 1] := MTEMP_arr[i];
    end;
    PAR_arr[1] := GlobRad.v * 0.48;
    MTEMP_arr[1] := max(0, TEMPM.v);
    SUMPAR := 0;
    SUMMTEMP := 0;
    for i := 1 to 45 do
    begin
      SUMPAR := SUMPAR + PAR_arr[i];
      SUMMTEMP := SUMMTEMP + MTEMP_arr[i];
    end;
    if SUMMTEMP > 0 then
      Q45.v := SUMPAR / SUMMTEMP
    else
      Q45.v := 0;
  end;
end;

procedure THumeWheatPartitioning.CalcNNI;
var
  cNmax, critN, prozN: real;
begin
  if (TSDM_m2.v > 0) and ((NShoot_m2.v + NSEN_m2.v) > 0) then
  begin
    if (TSDM_m2.v / 100 < 1.55) then
      critN := 4.4
    else
      critN := 5.35 * power(TSDM_m2.v / 100, -0.442);
    prozN := ((NShoot_m2.v + NSEN_m2.v) / TSDM_m2.v) * 100;
    NNI.v := max(0, prozN / critN);
    if (EC.v >= 60) and (NNI60.v <= 0) then
      NNI60.v := NNI.v;
    cNmax := critN * maxNNI.v;
    if (EC.v < EC_LGend.v) then
      maxNShoot_m2.v := (cNmax / 100) * TSDM_m2.v;
  end;
end;

procedure THumeWheatPartitioning.CalcGPSM;
begin
  // estimation of grains per plant for calculating initial value of grain N
  if (EC.v >= 40) and (NNI60.v <= 0) then
    GPPVAR.v := (GM4.v * power(ln(TOPWT_m2.v * Q45.v), 2.6233)) / Plants.v;
  if (GPSM.v <= 0) and (EC.v >= 65) then
  begin
    // according to Ratjen et al. 2012 (Field Crops Research, 133:167-175.)
    GPSM.v := (GM4.v * power(ln(TOPWT_m2.v * min(1, NNI60.v) * Q45.v),
        GM4_2.v));
    GPP.v := GPSM.v / Plants.v;
    GPPVAR.v := GPP.v;
  end;

end;

function THumeWheatPartitioning.GetWLD(Index:Integer):THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then result := RootModel.WLD_Arr[Index];
end;

function THumeWheatPartitioning.GetSumRootLength:THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then result := RootModel.SRL;
end;

function THumeWheatPartitioning.GetSumRootLength_eff:THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then result := RootModel.SRL_eff;
end;

function THumeWheatPartitioning.GetNUptakeRate:THumeNumEntity;
begin
  result := self.PlantNDemand_rate_limited_m2;
end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [THumeWheatPartitioning]);
end;

end.
