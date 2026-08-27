/// <summary>
/// Model description: W. Weymann (2015), dissertation, Chapter 4,
/// "Development and evaluation of a new dynamic crop growth model for
/// winter oilseed rape in temperate regions in Europe."
/// </summary>

unit OSRGrowth;

interface

uses
  Windows,
//  Messages,
   SysUtils,
    Classes,
//     vcl.Graphics,
//      vcl.Controls,
//       vcl.Forms,
//       vcl.Dialogs,
  UMod,
  UState,
  UlayeredSoil,
  USoilNitrogenUp,
  UAbstractPlant,
  UGrowthCurvePlantRoots,
  UAbstractSoilMin,
  DevelopmentOSR,
  USnowPack;

const
  MaxParDays = 10;


Type
/// <summary>Selects internally calculated or externally supplied leaf area index.</summary>
TLAIOption = (InternLAI,ExternLAI);
/// <summary>Selects internally calculated or externally supplied dry-matter growth.</summary>
TDMOption = (InternDM,ExternDM);
/// <summary>Selects dry-matter-based or LAI-based initialization.</summary>
TInitOption = (DMCritInit,LAIInit);
/// <summary>Selects N-sensitive or N-unlimited growth.</summary>
TNSensOption = (N_sensitiv,N_unlimited);
/// <summary>Selects whether drought stress affects growth.</summary>
TDroughtOption = (DroughtImpact, NoDroughtImpact);

/// <summary>
/// Simulates winter oilseed rape growth, dry-matter partitioning, senescence,
/// nitrogen dynamics, radiation interception, and yield formation.
/// </summary>
TOSRGrowth = class(TAbstractPlant)

private
  /// <summary>Indicates whether the harvest date has already been assigned.</summary>
  DateHarvestWasSet : boolean;
  /// <summary>Temporary reference used when iterating over state variables.</summary>
  StateVar : TState;
  /// <summary>Day of year at the detected start of vegetation.</summary>
  avs_day : integer;
  /// <summary>Rolling array of PAR values used by the maintenance calculation.</summary>
  Par_arr : array[1..MaxParDays] of real;

protected
  fDevelopmentModel: TDevelopmentOSR;
  fSnowModel: TSnowPack;
  procedure setDevelopmentModel(AModel: TDevelopmentOSR);
  function GetLAI:THumeNumEntity; override;
//  procedure SetLai(NewLAI:THumeNumEntity); override;
  function GetCropHeight:THumeNumEntity; override;
//  procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;
  function GetNUptakeRate:THumeNumEntity; override;
//  procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); override;
  procedure setNextCrop(NextCrop:TAbstractplant); override;
  function GetWLD(Index:Integer):THumeNumEntity; override;
  function GetSumRootLength:THumeNumEntity; override;
  function GetSumRootLength_eff:THumeNumEntity; override;
//  procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); override;
  function getExtCoeffPAR: real; override;


public
  // Variables
  /// <summary>photosynthetically active radiation.</summary>
  PARRad : TVar;
  /// <summary>temperature-derived photosynthesis response factor.</summary>
  fT : TVar;
  /// <summary>intercepted radiation.</summary>
  Q : TVar;
  /// <summary>radiation intercepted by leaves.</summary>
  QLeaf : TVar;
  /// <summary>radiation intercepted by pods.</summary>
  QGen : TVar;
  /// <summary>transmission coefficient for pod development.</summary>
  Transkoeff : TVar;
  /// <summary>fraction of intercepted radiation.</summary>
  fInt: TVar;
  /// <summary>fraction of radiation intercepted by leaves.</summary>
  fIntLeaf : TVar;
  /// <summary>fraction of radiation intercepted by pods.</summary>
  fIntGen : TVar;
  /// <summary>effective temperature.</summary>
  Teff : TVar;
  /// <summary>fraction of root growth.</summary>
  fRoot: TVar;
  /// <summary>maximum fraction of root growth.</summary>
  maxfRoot : TVar;
  /// <summary>fraction of leaf growth in shoot growth.</summary>
  fBl : TVar;
  /// <summary>fraction of leaf growth at EC 51.</summary>
  fBl_EC51 : TVar;
  /// <summary>fraction of stem growth in shoot growth.</summary>
  fSt : TVar;
  /// <summary>fraction of pod growth in shoot growth.</summary>
  fGen : TVar;
  /// <summary>fraction of pod-wall growth in pod growth.</summary>
  fPW : TVar;
  /// <summary>fraction of seed growth in pod growth.</summary>
  fSeedGen : TVar;
  /// <summary>calculated starch fraction in the seed.</summary>
  fSeedStarch : TVar;
  /// <summary>calculated oil fraction in the seed.</summary>
  fSeedOil : TVar;
  /// <summary>sum of the weighted organ-specific NNI values.</summary>
  fSum : TVar;
  /// <summary>intermediate value used to calculate leaf NNI.</summary>
  fNNILeaf : TVar;
  /// <summary>intermediate value used to calculate stem NNI.</summary>
  fNNIStem : TVar;
  /// <summary>intermediate value used to calculate generative-organ NNI.</summary>
  fNNIGen : TVar;
  /// <summary>intermediate value used to calculate root NNI.</summary>
  fNNIRoot : TVar;
  /// <summary>temperature below zero.</summary>
  Tminus : TVar;
  /// <summary>leaf N concentration.</summary>
  NcLeaf : TVar;
  /// <summary>leaf N concentration at the start of vegetation.</summary>
  NcLeaf_VA : TVar;
  /// <summary>stem N concentration.</summary>
  NcStem : TVar;
  /// <summary>stem N concentration at the start of vegetation.</summary>
  NcStem_VA : TVar;
  /// <summary>stem N concentration at EC 70.</summary>
  NcStem_EC70 : TVar;
  /// <summary>generative-organ N concentration.</summary>
  NcGen : TVar;
  /// <summary>root N concentration.</summary>
  NcRoot : TVar;
  /// <summary>root N concentration at the start of vegetation.</summary>
  NcRoot_VA : TVar;
  /// <summary>root N concentration at EC 70.</summary>
  NcRoot_EC70 : TVar;
  /// <summary>potential N uptake rate (g m-2 d-1).</summary>
  NUptakeRate_pot : TVar;
  /// <summary>Nitrogen Nutrition Index.</summary>
  NNI: TVar;
  /// <summary>crop height.</summary>
  CropHeight : TVar;
  /// <summary>LAI at EC 70.</summary>
  LAILeaf_EC70 : TVar;
  /// <summary>specific leaf area.</summary>
  actSLA : TVar;
  /// <summary>specific leaf area.</summary>
  avSLA: TVar;
  /// <summary>specific pod area.</summary>
  actSPA : TVar;
  /// <summary>specific pod area.</summary>
  avSPA : TVar;
  /// <summary>radiation-use efficiency.</summary>
  LUE : TVar;
  /// <summary>pod radiation-use efficiency.</summary>
  LUEGen : TVar;
  /// <summary>Factor used to adjust radiation-use efficiency for the CO2 effect.</summary>
  CO2_factor :TVar;
  /// <summary>slope of the allometric function.</summary>
  g : TVar;
  /// <summary>intercept of the allometric function.</summary>
  h : TVar;
  /// <summary>maximum LAI supported by the available radiation.</summary>
  LAIm : TVar;
  /// <summary>maintenance-respiration temperature factor used to calculate PARm.</summary>
  fTm : TVar;
  /// <summary>temperature factor used in senescence calculations.</summary>
  fTSen : TVar;
  /// <summary>senescence factor for shading and maintenance respiration.</summary>
  fSen_sh: TVar;
  /// <summary>time of emergence.</summary>
  Auflauf : TVar;
  /// <summary>temperature-corrected intercepted radiation.</summary>
  QT : TVar;
  /// <summary>PAR extinction coefficient: exk, or a variable value when LAI is below LAIcrit_exk.</summary>
  act_k : TVar;
  /// <summary>leaf extinction coefficient.</summary>
  act_k_Leaf : TVar;
  /// <summary>pod extinction coefficient.</summary>
  act_k_Gen : TVar;
  /// <summary>Auxiliary variable available for diagnostics.</summary>
  DummyVar : TVar;
  /// <summary>EC value when LAIShoot equals 2.0.</summary>
  EC_act : TVar;
  /// <summary>max. GAI.</summary>
  maxGAI : TVar;
  /// <summary>max. PAI.</summary>
  maxLAIGen : TVar;
  /// <summary>max. SAI.</summary>
  maxLAIStem : TVar;
  /// <summary>change in NcLeaf.</summary>
  dNcLeaf : TVar;
  /// <summary>change in NcStem.</summary>
  dNcStem : TVar;
  /// <summary>change in NcRoot.</summary>
  dNcRoot : TVar;
  /// <summary>change in NcGen.</summary>
  dNcGen : TVar;
  /// <summary>critical leaf N concentration.</summary>
  NcritLeaf : TVar;
  /// <summary>current leaf N concentration.</summary>
  NcLeaf_act : TVar;
  /// <summary>critical stem N concentration.</summary>
  NcritStem : TVar;
  /// <summary>current stem N concentration.</summary>
  NcStem_act : TVar;
  /// <summary>critical pod N concentration.</summary>
  NcritGen : TVar;
  /// <summary>current pod N concentration.</summary>
  NcGen_act : TVar;
  /// <summary>critical root N concentration.</summary>
  NcritRoot : TVar;
  /// <summary>critical root N concentration at the start of vegetation.</summary>
  NcritRoot_VA : TVar;
  /// <summary>current root N concentration.</summary>
  NcRoot_act : TVar;
  /// <summary>critical leaf N concentration at the start of vegetation.</summary>
  NcritLeaf_VA : TVar;
  /// <summary>critical stem N concentration at the start of vegetation.</summary>
  NcritStem_VA : TVar;
  /// <summary>critical stem N concentration at EC 70.</summary>
  NcritStem_EC70 : TVar;
  /// <summary>critical root N concentration at EC 70.</summary>
  NcritRoot_EC70 : TVar;
  /// <summary>leaf NNI.</summary>
  NNILeaf : TVar;
  /// <summary>stem NNI.</summary>
  NNIStem : TVar;
  /// <summary>pod NNI.</summary>
  NNIGen : TVar;
  /// <summary>root NNI.</summary>
  NNIRoot : TVar;
  /// <summary>mean PAR over five days used as the threshold for maintenance-respiration calculations.</summary>
  PARav : Tvar;
  /// <summary>pod area index.</summary>
  PAI : TVar;
  /// <summary>stem area index.</summary>
  SAI : TVar;
  /// <summary>spring SLA.</summary>
  SLAf : TVar;

  /// <summary>N demand for current growth.</summary>
  NDemandGrowth : TVar;
  /// <summary>N demand required to compensate for an existing N deficit.</summary>
  NDemandDeficit : TVar;
  /// <summary>N demand required to compensate for an existing leaf N deficit.</summary>
  NDemandDeficitLeaf : TVar;
  /// <summary>N demand required to compensate for an existing stem N deficit.</summary>
  NDemandDeficitStem : TVar;
  /// <summary>N demand required to compensate for an existing root N deficit.</summary>
  NDemandDeficitRoot : TVar;
  /// <summary>N demand required to compensate for an existing pod N deficit.</summary>
  NDemandDeficitGen : TVar;
  /// <summary>available N amount.</summary>
  NSupply : TVar;

  /// <summary>thousand-seed weight.</summary>
  TKM : TVar;
  /// <summary>number of seeds per m².</summary>
  Samenanzahl : TVar;
  /// <summary>Harvest-Index.</summary>
  HI : TVar;
  /// <summary>Nitrogen Harvest Index.</summary>
  NHI : TVar;
  /// <summary>Nitrogen Use Efficiency.</summary>
  NUE : TVar;


  /// <summary>conversion loss caused by producing oil instead of starch.</summary>
  KonversionVerlust : TVar;

  /// <summary>day of year at the start of vegetation, derived from temperature.</summary>
  avs : TVar;
  /// <summary>factor describing the influence of drought stress (Ferreyra 2013).</summary>
  fW : TVar;

  /// <summary>N-deficit factor, defined as the ratio of N demand to N uptake.</summary>
  N_Def : TVar;

  LAImarray : Array [1..10] of real;

  /// <summary>Associated root-growth model.</summary>
  fRootModel: TGrowthCurvePlantRoots{TSimpleRootModDM};

  // State variables

  /// <summary>shoot dry matter.</summary>
  DMShoot : TState;
  /// <summary>shoot dry matter before winter.</summary>
  DMShoot_vW : TState;
  /// <summary>shoot dry matter at the onset of flowering.</summary>
  DMShoot_OF : TState;
  /// <summary>shoot dry matter accumulated after flowering.</summary>
  DMShoot_nB : TState;
  /// <summary>potential shoot dry matter accumulated after flowering.</summary>
  DMShoot_nB_pot : TState;
  /// <summary>leaf dry matter.</summary>
  DMLeaf : TState;
  /// <summary>stem dry matter.</summary>
  DMStem : TState;
  /// <summary>root dry matter.</summary>
  DMRoot : TState;
  /// <summary>generative-organ dry matter.</summary>
  DMGen : TState;
  /// <summary>pod-wall dry matter.</summary>
  DMPodWall : TState;
  /// <summary>seed dry matter.</summary>
  DMSeed : TState;
  /// <summary>dry matter of the seed starch fraction.</summary>
  DMSeedStarch : TState;
  /// <summary>dry matter of the seed oil fraction.</summary>
  DMSeedOil : TState;
  /// <summary>total plant dry matter.</summary>
  DMPlant : TState;
  /// <summary>shoot area.</summary>
  LAIShoot : TState;
  /// <summary>leaf area.</summary>
  LAILeaf : TState;
  /// <summary>stem area.</summary>
  LAIStem : TState;
  /// <summary>shoot N amount.</summary>
  NShoot : TState;
  /// <summary>leaf N amount.</summary>
  NLeaf : TState;
  /// <summary>structural stem N amount.</summary>
  strNStem : TState;
  /// <summary>stem N pool.</summary>
  poolNStem : TState;
  /// <summary>stem N amount.</summary>
  NStem : TState;
  /// <summary>generative-organ N amount.</summary>
  NGen : TState;
  /// <summary>structural root N amount.</summary>
  strNRoot : TState;
  /// <summary>root N pool.</summary>
  poolNRoot : TState;
  /// <summary>root N amount.</summary>
  NRoot : TState;
  /// <summary>N amount in dead leaves [g/m²].</summary>
  NDead : TState;
  /// <summary>total plant N amount [g/m²].</summary>
  NPlant : TState;
  /// <summary>seed N amount [g/m²].</summary>
  NSeed : TState;
  /// <summary>pod-wall N amount [g/m²].</summary>
  NPodWall : TState;
  /// <summary>N amount lost through frost senescence.</summary>
  NDeadW : TState;
  /// <summary>N amount lost through shading senescence.</summary>
  NDeadSh : TState;
  /// <summary>translocatable N amount from leaves.</summary>
  NTransLeaf : TState;
  /// <summary>translocatable N amount from stems.</summary>
  NTransStem : TState;
  /// <summary>translocatable N amount from pods.</summary>
  NTransGen : TState;
  /// <summary>translocatable N amount from roots.</summary>
  NTransRoot : TState;
  /// <summary>total translocatable N amount.</summary>
  NTrans : TState;
  /// <summary>potentially translocatable N amount.</summary>
  potNTrans : TState;
  /// <summary>potential N amount in the pool.</summary>
  potNPool : TState;
  /// <summary>potential N uptake [g/m²].</summary>
  NUptake_pot : TState;
  /// <summary>actual N uptake [g/m²].</summary>
  NUptake_act : TState;
  /// <summary>temperature sum.</summary>
  TempSum : TState;
  /// <summary>temperature sum since sowing.</summary>
  TempSumAussaat : TState;
  /// <summary>temperature sum.</summary>
  TempSumMinus : TState;
  /// <summary>temperature sum since emergence (Tb = 0°C).</summary>
  TempSumAuflauf : TState;
  /// <summary>temperature sum since EC 70.</summary>
  TempSumPodGrowth : TState;
  /// <summary>temperature sum during seed maturation.</summary>
  TempSumSeed : TState;
  /// <summary>temperature sum since EC 51 used to calculate the decline in the leaf fraction of total plant growth.</summary>
  TempSumLeafLoss : TState;
  /// <summary>temperature sum between days of year 30 and 150 used to calculate fRoot.</summary>
  TempSumRoots : TState;
  /// <summary>area senesced through shading.</summary>
  LAIs : TState;
  /// <summary>senescent dry matter.</summary>
  DMDead : TState;
  /// <summary>dry matter killed by frost senescence.</summary>
  DMDeadW : TState;
  /// <summary>leaf dry matter killed by frost senescence.</summary>
  DMDeadLeafW : TState;
  /// <summary>stem dry matter killed by frost senescence.</summary>
  DMDeadStemW : TState;
  /// <summary>root dry matter lost over winter.</summary>
  DMDeadRootW : TState;
  /// <summary>leaf dry matter killed by shading senescence.</summary>
  DMDeadSh : TState;
  /// <summary>leaf dry matter killed by N deficiency.</summary>
  DMDeadN : TState;
  /// <summary>former living green dry matter of leaves killed by N deficiency.</summary>
  DM_N : TState;
  /// <summary>leaf dry matter translocated under N deficiency.</summary>
  DMNTrans : TState;
  /// <summary>potential leaf dry matter killed and translocated through shading senescence.</summary>
  DMSh : TState;
  /// <summary>leaf dry matter translocated to pods through shading senescence.</summary>
  DMShTrans : TState;
  /// <summary>translocated stem dry matter.</summary>
  DMTransStem : TState;
  /// <summary>translocated leaf dry matter.</summary>
  DMTransLeaf : TState;
  /// <summary>translocated dry matter.</summary>
  DMTrans : TState;
  /// <summary>PodAreaIndex.</summary>
  LAIGen : TState;
  /// <summary>cumulative intercepted radiation [MJ].</summary>
  sumQ : TState;
  /// <summary>cumulative temperature-corrected intercepted radiation [MJ].</summary>
  sumQT : TState;
  /// <summary>Cumulative drought- and temperature-corrected intercepted radiation [MJ].</summary>
  sumQT_TactTpot : TState;
  /// <summary>cumulative radiation intercepted by leaves.</summary>
  sumQLeaf : TState;
  /// <summary>cumulative radiation intercepted by pods.</summary>
  sumQGen : TState;
  /// <summary>radiation sum.</summary>
  RadSum : TState;

  /// <summary>C amount in shed leaves.</summary>
  C_Dead : TState;
  /// <summary>N amount in shed leaves.</summary>
  N_Dead : TState;

  /// <summary>age-related senescence after EC 80.</summary>
  DMDeadAge : TState;
  /// <summary>age-related senescence after EC 80.</summary>
  NDeadAge : TState;

  /// <summary>N pool in stems and roots for N translocated from leaves before generative organs become available as sinks.</summary>
  NPool : TState;

  /// <summary>seed yield.</summary>
  Yield : TState;
  /// <summary>oil yield.</summary>
  OilYield : TState;
  /// <summary>oil concentration.</summary>
  Oilconc : TState;
  /// <summary>protein content.</summary>
  Protein : TState;
  /// <summary>maximum yield.</summary>
  Ymax : TState;

  /// <summary>date of EC 65.</summary>
  FullFlower : TState;
  /// <summary>cumulative conversion loss during oil formation.</summary>
  SumKonversionVerlust : TState;

  /// <summary>Plant nitrogen balance.</summary>
  NBalance : TState;
  /// <summary>N uptake before winter.</summary>
  NUptake_vW : TState;
  /// <summary>N uptake after flowering.</summary>
  NUptake_aF : TState;

  // Parameters

  /// <summary>base temperature.</summary>
  Tb : TPar;
  /// <summary>slope parameter of the autumn allometric relationship.</summary>
  gh : TPar;
  /// <summary>intercept parameter of the autumn allometric relationship.</summary>
  hh : TPar;
  /// <summary>slope parameter of the spring allometric relationship.</summary>
  gf : TPar;
  /// <summary>intercept parameter of the spring allometric relationship.</summary>
  hf : TPar;
  /// <summary>parameter for dry-matter partitioning after EC 51.</summary>
  a : TPar;
  /// <summary>parameter for dry-matter partitioning after EC 51.</summary>
  b : TPar;
  /// <summary>parameter for dry-matter partitioning after EC 51.</summary>
  c : TPar;
  /// <summary>parameter for dry-matter partitioning after EC 51.</summary>
  d : TPar;
  /// <summary>parameter for dry-matter partitioning after EC 51.</summary>
  e : TPar;
  /// <summary>parameter of the exponential DMRoot function.</summary>
  root_exp : TPar;
  /// <summary>parameter of the exponential SPA function.</summary>
  SPA_exp : TPar;
  /// <summary>parameter of the yield function fPW.</summary>
  fPW_0 : TPar;
  /// <summary>parameter of the yield function fPW.</summary>
  fPW_exp : TPar;
  /// <summary>pod dilution function.</summary>
  pCnPod1 : TPar;
  /// <summary>pod dilution function.</summary>
  pCnPod2 : TPar;
  /// <summary>coefficient preceding the exponential term of the autumn stem dilution function.</summary>
  pCnstem1h : TPar;
  /// <summary>coefficient preceding the variable in the autumn stem dilution function.</summary>
  pCnstem2h : TPar;
  /// <summary>coefficient preceding the exponential term of the root dilution function.</summary>
  pCnRoot1h : TPar;
  /// <summary>coefficient preceding the variable in the root dilution function.</summary>
  pCnRoot2h : TPar;
  /// <summary>coefficient preceding the exponential term of the root dilution function.</summary>
  pCnRoot1f : TPar;
  /// <summary>coefficient preceding the variable in the root dilution function.</summary>
  pCnRoot2f : TPar;
  /// <summary>leaf N concentration.</summary>
  pCnleaf : TPar;
  /// <summary>intercept preceding DMLeaf.</summary>
  pCn1leaf : TPar;
  /// <summary>slope of the autumn leaf dilution function.</summary>
  pCn2leaf : TPar;
  /// <summary>N concentration of dead leaves.</summary>
  pCnDead: TPar;
  /// <summary>root N concentration.</summary>
  pCnRoot: TPar;
  /// <summary>seed N concentration.</summary>
  pCnSeed : TPar;
  /// <summary>fraction of N translocated from senescent leaves.</summary>
  pCnTrans : TPar;
  /// <summary>lower growth temperature.</summary>
  Ct1 : TPar;
  /// <summary>lower optimum temperature.</summary>
  Ct2 : TPar;
  /// <summary>upper optimum temperature.</summary>
  Ct3 : TPar;
  /// <summary>upper growth temperature.</summary>
  Ct4 : TPar;
  /// <summary>specific leaf area after flowering.</summary>
  SLAnB : TPar;
  /// <summary>slope parameter of autumn specific leaf area.</summary>
  SLAhst : TPar;
  /// <summary>intercept of autumn specific leaf area.</summary>
  SLAhin : TPar;
  /// <summary>minimum autumn specific leaf area.</summary>
  SLAmin : TPar;
  /// <summary>maximum autumn specific leaf area.</summary>
  SLAmax : TPar;
  /// <summary>SLA of senescent leaves [cm²/g].</summary>
  SLADead : TPar;
  /// <summary>temperature threshold for winter senescence.</summary>
  fTminus : TPar;
  /// <summary>specific stem area.</summary>
  SSA : TPar;
  /// <summary>maximum specific pod area.</summary>
  SPAmax : TPar;
  /// <summary>growth rate from EC 10 to EC 13.</summary>
  k1 : TPar;
  /// <summary>dry-matter threshold for exponential growth.</summary>
  DMcrit : TPar;
  /// <summary>intercept of the root-fraction regression.</summary>
  rooti : TPar;
  /// <summary>slope of the root-fraction regression.</summary>
  roots : TPar;
  /// <summary>extinction coefficient.</summary>
  exk : TPar;
  /// <summary>extinction coefficient at LAI 0 for the variable Exk.</summary>
  exk_0 : TPar;
  /// <summary>LAIcrit at which the extinction coefficient equals exk.</summary>
  LAIcrit_exk : TPar;
  /// <summary>radiation-use efficiency.</summary>
  LUELeaf : TPar;
  /// <summary>intercept of the pre-winter LUE equation.</summary>
  LUE0 : TPar;
  /// <summary>pod LUE.</summary>
  LUEPod : TPar;
  /// <summary>maintenance radiation required in autumn.</summary>
  PARmh : TPar;
  /// <summary>maintenance radiation required in spring.</summary>
  PARmf : TPar;
  /// <summary>optimum temperature for the Arrhenius fTm response.</summary>
  pfTm_opt: TPar;
  /// <summary>Q10 value of the Arrhenius fTm response.</summary>
  pfTm_Q10: TPar;
  /// <summary>number of days over which PARm is averaged.</summary>
  pSen_sh: TPar;
  /// <summary>exponent controlling the effect of fSen_sh.</summary>
  pSen_sh_w: TPar;
  /// <summary>relative loss rate caused by winter senescence.</summary>
  fSws : TPar;
  /// <summary>plants per m².</summary>
  Plants: TPar;
  /// <summary>LAI after emergence when InitOption is LAIInit [cm²/plant].</summary>
  pIniLAI: TPar;
  /// <summary>critical leaf dilution function before stem elongation.</summary>
  pCncritLeaf : TPar;
  /// <summary>critical leaf dilution function after stem elongation begins.</summary>
  pCncrit1Leaf : TPar;
  /// <summary>critical leaf dilution function after stem elongation begins.</summary>
  pCncrit2Leaf : TPar;
  /// <summary>critical stem dilution function before stem elongation.</summary>
  pCncritStem1h : TPar;
  /// <summary>critical stem dilution function before stem elongation.</summary>
  pCncritStem2h : TPar;
  /// <summary>critical pod dilution function.</summary>
  pCncritPod1 : TPar;
  /// <summary>critical pod dilution function.</summary>
  pCncritPod2 : TPar;
  /// <summary>critical root dilution function before stem elongation.</summary>
  pCncritRoot1h : TPar;
  /// <summary>critical root dilution function before stem elongation.</summary>
  pCncritRoot2h : TPar;
  /// <summary>critical root dilution function after stem elongation begins.</summary>
  pCncritRoot1f : TPar;
  /// <summary>critical root dilution function after stem elongation begins.</summary>
  pCncritRoot2f : TPar;
  /// <summary>stem dilution function after stem elongation begins.</summary>
  pCnStem1f : TPar;
  /// <summary>stem dilution function after stem elongation begins.</summary>
  pCnStem2f : TPar;
  /// <summary>critical stem dilution function after stem elongation begins.</summary>
  pCncritStem1f : TPar;
  /// <summary>critical stem dilution function after stem elongation begins.</summary>
  pCncritStem2f : TPar;
  /// <summary>yield-calculation parameter, currently equivalent to the harvest index.</summary>
  y1 : TPar;
  /// <summary>parameter for calculating SLA after EC 30 as a function of GAI.</summary>
  SLAspring : TPar;
  /// <summary>parameter for calculating SLA after EC 30 as a function of GAI.</summary>
  fSLAspring : TPar;
  /// <summary>parameter for calculating oil concentration from seed-maturation duration.</summary>
  Oila : TPar;
  /// <summary>parameter for calculating oil concentration from seed-maturation duration.</summary>
  Oilb : TPar;
  /// <summary>parameter for calculating oil concentration from seed N amount.</summary>
  Oilc : TPar;
  /// <summary>parameter for calculating oil concentration from seed N amount.</summary>
  Oild : TPar;
  /// <summary>Exponent controlling the nonlinear relationship between transpiration ratio and SWDF (Ferreyra 2003).</summary>
  pfW:   TPAR;
  /// <summary>Parameter for simultaneous scaling of vegetative and generative LUE.</summary>
  LUEscaling: TPAR;
//  minNNI : TPar; /// minimum NNI Value [0..1]

  /// <summary>Scaling coefficient for the atmospheric CO2 response.</summary>
  fCO2_scale     : TPar;
  /// <summary>Coefficient of the atmospheric CO2 response.</summary>
  fCO2           : TPar;
  /// <summary>Parameter that adjusts the CO2 effect for drought stress.</summary>
  fCWSI          : TPar;
  /// <summary>Atmospheric CO2 compensation point.</summary>
  CiCompensation : TPar;


  // External Variables

  /// <summary>global radiation.</summary>
  GRad : TExternV;
  /// <summary>daily mean temperature.</summary>
  TMPM : TExternV;
  /// <summary>phenological stage.</summary>
  EC : TExternV;
  /// <summary>External DVS rate.</summary>
  DVS_rate : TExternV;
  /// <summary>Development-Stage.</summary>
  DVS : TExternV;
  /// <summary>day of year.</summary>
  DayofYear : TExternV;
  /// <summary>LAI used for LUE.</summary>
  LUE_LAI : TExternV;
  /// <summary>shoot dry-matter increment for the ExternDM option.</summary>
  DMGrowth_ex: TExternV;
  /// <summary>ratio of potential to actual transpiration.</summary>
  TransRatio : TExternV;
  /// <summary>ratio of potential to actual transpiration, including interception.</summary>
  TransIntRatio : TExternV;
//  CO2pp:    TExternV;        /// external atmospheric CO2-concentration


//  TMeanEC71_79 : TExternV;
//  DauerEC71_79 : TExternV;
//  DauerEC81_89 : TExternV;
  /// <summary>Number of days from EC 81 to EC 89.</summary>
  DauerEC81_89: TState;

  // Options

  /// <summary>Internal representation of the selected LAI option.</summary>
  fLAIOption : TLAIOption;
  /// <summary>internally calculated LAI or external variable.</summary>
  LAIOption : TOption;
  /// <summary>Internal representation of the selected dry-matter-growth option.</summary>
  fDMGrowthOption : TDMOption;
  /// <summary>internally calculated dry-matter increment or external variable.</summary>
  DMGrowthOption : TOption;
  /// <summary>Internal representation of the selected initialization option.</summary>
  fInitOption: TInitOption;
  /// <summary>initialization from exponentially growing dry matter or initial LAI.</summary>
  InitOption: TOption;
  /// <summary>Internal representation of the selected N-sensitivity option.</summary>
  fNSensOption: TNSensOption;
  /// <summary>effect of N deficiency on dry-matter growth.</summary>
  NSensOption: TOption;
  /// <summary>Internal representation of the selected drought option.</summary>
  fDroughtOption : TDroughtOption;
  /// <summary>effect of drought stress on dry-matter growth.</summary>
  DroughtOption : TOption;
  /// <summary>Selects whether atmospheric CO2 affects radiation-use efficiency.</summary>
  OptWithCO2: TOption;


  /// <summary>Creates and registers model entities and options.</summary>
  procedure CreateAll; override;
  /// <summary>Initializes crop state and resolves the selected calculation options.</summary>
  procedure Init(var GlobMod: TMod); override;
  /// <summary>Calculates daily growth, partitioning, senescence, nitrogen, and radiation rates.</summary>
  procedure CalcRates; override;
  /// <summary>Integrates crop states and updates derived yield and residue quantities.</summary>
  procedure Integrate; override;
  /// <summary>Sets the sowing date used by this crop and its development model.</summary>
  procedure SetSowingDate(NewSowingDate: real);  override;


published

  // Variables

  Property Var_PARRad : TVar read PARRad write PARRad;
  Property Var_fT : TVar read fT write fT;
  Property Var_Q : TVar read Q write Q;
  Property Var_QT : TVar read QT write QT;
  Property Var_Teff : TVar read Teff write Teff;
  Property Var_fRoot : TVar read fRoot write fRoot;
  Property Var_maxfRoot : TVar read maxfRoot write maxfRoot;
  Property Var_fBl : TVar read fBl write fBl;
  Property Var_fPW : TVar read fPW write fPW;
  Property Var_Tminus : TVar read Tminus write Tminus;
  Property Var_NcLeaf : TVar read NcLeaf write NcLeaf;
  Property Var_NcStem : TVar read NcStem write NcStem;
  Property Var_NUptakeRate_pot : TVar read NUptakeRate_pot write NUptakeRate_pot;
  Property Var_CropHeight : TVar read CropHeight write CropHeight;
  Property Var_actSLA : TVar read actSLA write actSLA;
  Property Var_LUE : TVar read LUE write LUE;
  Property Var_g : TVar read g write g;
  Property Var_h : TVar read h write h;
  Property Var_LAIm : TVar read LAIm write LAIm;
  Property Var_fTm : TVar read fTm write fTm;
  Property Var_Auflauf : TVar read Auflauf write Auflauf;
  Property Var_EC_act :  TVar read EC_act write EC_act;

  // State-variable properties

  Property St_DMShoot : TState read DMShoot write DMShoot;
  Property St_DMLeaf : TState read DMLeaf write DMLeaf;
  Property St_DMStem : TState read DMStem write DMStem;
  Property St_DMPlant : TState read DMPlant write DMPlant;
  Property St_DMRoot : TState read DMRoot write DMRoot;
  Property St_DMGen : TState read DMGen write DMGen;
  Property St_DMPodWall : TState read DMPodWall write DMPodWall;
  Property St_DMSeed : TState read DMSeed write DMSeed;
  Property St_LAIShoot : TState read LAIShoot write LAIShoot;
  Property St_LAILeaf : TState read LAILeaf write LAILeaf;
  Property St_LAIStem : TState read LAIStem write LAIStem;
  Property St_NShoot : TState read NShoot write NShoot;
  Property St_NLeaf : TState read NLeaf write NLeaf;
  Property St_strNStem : TState read strNStem write strNStem;
  Property St_strNRoot : TState read strNRoot write strNRoot;
  Property St_NDead : TState read NDead write NDead;
  Property St_TempSum : TState read TempSum write TempSum;
  Property St_TempSumAussaat : TState read TempSumAussaat write TempSumAussaat;
  Property St_TempSumMinus : TState read TempSumMinus write TempSumMinus;
  Property St_TempSumAuflauf : TState read TempSumAuflauf write TempSumAuflauf;
  Property St_LAIs : TState read LAIs write LAIs;
  Property St_DMdead : TState read DMdead write DMdead;
  Property St_DMDeadW : TState read DMDeadW write DMDeadW;
  Property St_DMDeadSh : TState read DMDeadSh write DMDeadSh;
  Property St_DMDeadN : TState read DMDeadN write DMDeadN;
  Property St_DMSh : TState read DMSh write DMSh;
  Property St_DMShTrans : TState read DMShTrans write DMShTrans;
  Property St_LAIGen : TState read LAIGen write LAIGen;
  /// <summary>cumulative intercepted radiation [MJ].</summary>
  Property St_sumQ : TState read  sumQ write sumQ;
  /// <summary>cumulative temperature-corrected intercepted radiation [MJ].</summary>
  Property St_sumQT : TState read  sumQT write sumQT;
  /// <summary>cumulative radiation intercepted by leaves.</summary>
  Property St_sumQLeaf : TState read sumQLeaf write sumQLeaf;
  /// <summary>cumulative radiation intercepted by pods.</summary>
  Property St_sumQGen : TState read sumQGen write sumQGen;
  /// <summary>Cumulative drought- and temperature-corrected intercepted radiation [MJ].</summary>
  Property St_sumQT_TactTpot : TState read sumQT_TactTpot write sumQT_TactTpot;


         // Parameters

  Property Par_Tb : TPar read Tb write Tb;
  Property Par_gh : TPar read gh write gh;
  Property Par_hh : TPar read hh write hh;
  Property Par_a : TPar read a write a;
  Property Par_b : TPar read b write b;
  Property Par_c : TPar read c write c;
  Property Par_d : TPar read d write d;
  Property Par_pCnstem1h : TPar read pCnstem1h write pCnstem1h;
  Property Par_pCnstem2h : TPar read pCnstem2h write pCnstem2h;
  Property Par_pCnleaf : TPar read pCnleaf write pCnleaf;
  Property Par_pCn1leaf : TPar read pCn1leaf write pCn1leaf;
  Property Par_pCn2leaf : TPar read pCn2leaf write pCn2leaf;
  Property Par_Ct1 : TPar read Ct1 write Ct1;
  Property Par_Ct2 : TPar read Ct2 write Ct2;
  Property Par_Ct3 : TPar read Ct3 write Ct3;
  Property Par_Ct4 : TPar read Ct4 write Ct4;
  Property Par_SLAhst : TPar read SLAhst write SLAhst;
  Property Par_SLAhin : TPar read SLAhin write SLAhin;
  Property Par_SLAmin : TPar read SLAmin write SLAmin;
  Property Par_SLAmax : TPar read SLAmax write SLAmax;
  Property Par_fTminus : TPar read fTminus write fTminus;
  Property Par_SSA : TPar read SSA write SSA;
  Property Par_k1 : TPar read k1 write k1;
  Property Par_DMcrit : TPar read DMcrit write DMcrit;
  Property Par_rooti : TPar read rooti write rooti;
  Property Par_roots : TPar read roots write roots;
  Property Par_exk : TPar read exk write exk;
  Property Par_LUELeaf : TPar read LUELeaf write LUELeaf;
  Property Par_LUE0 : TPar read LUE0 write LUE0;
  Property Par_PARmh : TPar read PARmh write PARmh;
  Property Par_PARmf : TPar read PARmf write PARmf;
  Property Par_fSws : TPar read fSws write fSws;

         // External-variable properties

  Property Ex_GRad : TExternV read GRad write GRad;
  Property Ex_TMPM : TExternV read TMPM write TMPM;
  Property Ex_EC : TExternV read EC write EC;
  Property Ex_DayofYear : TExternV read DayofYear write DayofYear;
  Property Ex_ExternLAI : TExternV read LUE_LAI  write LUE_LAI ;
  Property Ex_DMGrowth : TExternV read DMGrowth_ex  write DMGrowth_ex ;
  Property Ex_TransRatio : TExternV read TransRatio write TransRatio;
//  Property Ex_CO2pp: TExternV Read CO2pp Write CO2pp;


           // Option properties

  Property Opt_LAI : TOption read LAIOption write LAIOption;
  Property Opt_Init: TOption read InitOption write InitOption;
  Property Opt_Drought: TOption read DroughtOption write DroughtOption;

  Property DevelopmentModel: TDevelopmentOSR read fDevelopmentModel write setDevelopmentModel;
  Property RootModel: TGrowthCurvePlantRoots{TSimpleRootModDM} read fRootModel write fRootModel;
//  Property SoilNitrogenMod: TSoilNitrogenUp read fSoilNitrogenMod write fSoilNitrogenMod;
  Property SnowModel: TSnowPack read fSnowModel write fSnowModel;
//  Property SoilMinMod : TAbstractSoilMin read fSoilMinMod write fSoilMinMod;

end;

procedure Register;

implementation
uses Math;



function CO2_ppm_f(date:TDateTime):real;
const
  int = 45549.96;//4.554996e+04;
  lin =  -47.00505;//-4.700505e+01;
  quad = 0.01220744;//1.220744e-02;
var
  year, month, day : word;
  dat : TDateTime;
begin
  SysUtils.decodedate(date, year, month, day);
  result := int + year*lin + sqr(year)*quad;
end;


procedure TOSRGrowth.createAll;
begin
  inherited createAll;
  VarCreate('PARRad', 'W/m²',0, true, PARRad,'photosynthetically active radiation');
  VarCreate('fT', '',0, true, fT,'temperature-derived photosynthesis response factor');
  VarCreate('fRoot', '',0, true, fRoot,'fraction of root growth');
  VarCreate('maxfRoot','',0,true,maxfRoot,'maximum fraction of root growth');
  VarCreate('fBl','',0,true,fBl,'fraction of leaf growth in shoot growth');
  VarCreate('fBl_EC51','',0,true,fBl_EC51,'fraction of leaf growth at EC 51');
  VarCreate('fSt','',0,true,fSt,'fraction of stem growth in shoot growth');
  VarCreate('fGen','',0,true,fGen,'fraction of pod growth in shoot growth');
  VarCreate('fPW','',0,true,fPW,'fraction of pod-wall growth in pod growth');
  VarCreate('fSeedGen','',0,true,fSeedGen,'fraction of seed growth in pod growth');
  VarCreate('fSeedStarch','',0,true,fSeedStarch,'calculated starch fraction in the seed');
  VarCreate('fSeedOil','',0,true,fSeedOil,'calculated oil fraction in the seed');
  VarCreate('fSum','',0,true,fSum,'sum of the weighted organ-specific NNI values');
  VarCreate('fNNILeaf','',0,true,fNNILeaf,'intermediate value used to calculate leaf NNI');
  VarCreate('fNNIStem','',0,true,fNNIStem,'intermediate value used to calculate stem NNI');
  VarCreate('fNNIGen','',0,true,fNNIGen,'intermediate value used to calculate generative-organ NNI');
  VarCreate('fNNIRoot','',0,true,fNNIRoot,'intermediate value used to calculate root NNI');
  VarCreate('Q', 'MJ',0, true, Q,'intercepted radiation');
  VarCreate('QLeaf', 'MJ',0, true, QLeaf,'radiation intercepted by leaves');
  VarCreate('QGen', 'MJ',0, true, QGen,'radiation intercepted by pods');
  VarCreate('fInt', '',0, true, fInt,'fraction of intercepted radiation');
  VarCreate('fIntLeaf', '',0, true, fIntLeaf,'fraction of radiation intercepted by leaves');
  VarCreate('fIntGen', '',0, true, fIntGen,'fraction of radiation intercepted by pods');
  VarCreate('act_k', '',0, true, act_k,'PAR extinction coefficient: exk, or a variable value when LAI is below LAIcrit_exk');
  VarCreate('act_k_Leaf', '',0, true, act_k_Leaf,'leaf extinction coefficient');
  VarCreate('act_k_Gen', '',0, true, act_k_Gen,'pod extinction coefficient');
  VarCreate('QT', 'MJ',0, true, QT,'temperature-corrected intercepted radiation');
  VarCreate('Teff', '°C',0, true, Teff,'effective temperature');
  VarCreate('Tminus', '°C',0, true, Tminus,'temperature below zero');
  VarCreate('NcLeaf', '%',0, true, NcLeaf,'leaf N concentration');
  VarCreate('NcLeaf_VA','%',0,true,NcLeaf_VA,'leaf N concentration at the start of vegetation');
  VarCreate('NcStem', '%',0, true, NcStem,'stem N concentration');
  VarCreate('NcStem_VA','%',0,true,NcStem_VA,'stem N concentration at the start of vegetation');
  VarCreate('NcStem_EC70','%',0,true,NcStem_EC70,'stem N concentration at EC 70');
  VarCreate('NcGen','%',0,true,NcGen,'generative-organ N concentration');
  VarCreate('NcRoot', '%',0, true, NcRoot,'root N concentration');
  VarCreate('NcRoot_VA', '%',0, true, NcRoot_VA,'root N concentration at the start of vegetation');
  VarCreate('NcRoot_EC70','%',0,true,NcRoot_EC70,'root N concentration at EC 70');
  VarCreate('NUptakeRate_pot', 'g m-2 d-1',0, true, NUptakeRate_pot,'potential N uptake rate (g m-2 d-1)');
  VarCreate('NNI', '-',1, true, NNI,'Nitrogen Nutrition Index');
  VarCreate('CropHeight', 'm',0, true, CropHeight,'crop height');
  VarCreate('LAILeaf_EC70','m²/m²',0,true,LAILeaf_EC70, 'LAI at EC 70');
  VarCreate('actSLA', 'cm²/g', 0 ,true, actSLA,'specific leaf area');
  VarCreate('SLA', 'cm²/g', 0 ,true, avSLA,'specific leaf area');
  VarCreate('actSPA','cm²/g',0,true,actSPA,'specific pod area');
  VarCreate('SPA','cm²/g',0,true,avSPA,'specific pod area');
  VarCreate('LUE', 'g/MJ', 0 ,true, LUE,'radiation-use efficiency');
  VarCreate('LUEGen','g/MJ',0,true,LUEGen,'pod radiation-use efficiency');
  VarCreate('g', '', 0 ,true, g,'slope of the allometric function');
  VarCreate('h', '', 0 ,true, h,'intercept of the allometric function');
  VarCreate('LAIm', 'm²/m²',0, true,LAIm,'maximum LAI supported by the available radiation');
  VarCreate('fTm', '',0, true, fTm,'maintenance-respiration temperature factor used to calculate PARm');
  VarCreate('fTSen','',0,true,fTSen,'temperature factor used in senescence calculations');
  VarCreate('fSen_sh', '',0, true, fSen_sh,'senescence factor for shading and maintenance respiration');
  VarCreate('Auflauf', 'd',0, true,Auflauf,'time of emergence');
  VarCreate('DummyVar', '',0, true, DummyVar);
  VarCreate('EC_act','',0,true,EC_act,'EC value when LAIShoot equals 2.0');
  VarCreate('Transkoeff','',0,true,Transkoeff,'transmission coefficient for pod development');
  VarCreate('maxGAI','m²/m²',0,true,maxGAI,'max. GAI');
  VarCreate('maxLAIGen','m²/m²',0,true,maxLAIGen,'max. PAI');
  VarCreate('maxLAIStem','m²/m²',0,true,maxLAIStem,'max. SAI');
  VarCreate('dNcLeaf','',0,true,dNcLeaf,'change in NcLeaf');
  VarCreate('dNcStem','',0,true,dNcStem,'change in NcStem');
  VarCreate('dNcRoot','',0,true,dNcRoot,'change in NcRoot');
  VarCreate('dNcGen','',0,true,dNcGen,'change in NcGen');
  VarCreate('NcritLeaf','%',0,true,NcritLeaf,'critical leaf N concentration');
  VarCreate('NcLeaf_act','%',0,true,NcLeaf_act,'current leaf N concentration');
  VarCreate('NcStem_act','%',0,true,NcStem_act,'current stem N concentration');
  VarCreate('NcGen_act','%',0,true,NcGen_act,'current pod N concentration');
  VarCreate('NcRoot_act','%',0,true,NcRoot_act,'current root N concentration');
  VarCreate('NcritStem','%',0,true,NcritStem,'critical stem N concentration');
  VarCreate('NcritGen','%',0,true,NcritGen,'critical pod N concentration');
  VarCreate('NcritRoot','%',0,true,NcritRoot,'critical root N concentration');
  VarCreate('NcritRoot_VA','%',0,true,NcritRoot_VA,'critical root N concentration at the start of vegetation');
  VarCreate('NcritLeaf_VA','%',0,true,NcritLeaf_VA,'critical leaf N concentration at the start of vegetation');
  VarCreate('NcritStem_VA','%',0,true,NcritStem_VA,'critical stem N concentration at the start of vegetation');
  VarCreate('NcritStem_EC70','%',0,true,NcritStem_EC70,'critical stem N concentration at EC 70');
  VarCreate('NcritRoot_EC70','%',0,true,NcritRoot_EC70,'critical root N concentration at EC 70');
  VarCreate('NNILeaf','-',1,true,NNILeaf,'leaf NNI');
  VarCreate('NNIStem','-',1,true,NNIStem,'stem NNI');
  VarCreate('NNIGen','-',1,true,NNIGen,'pod NNI');
  VarCreate('NNIRoot','-',1,true,NNIRoot,'root NNI');
  VarCreate('PAI','',0,true,PAI,'pod area index');
  VarCreate('SAI','',0,true,SAI,'stem area index');
  VarCreate('SLAf','cm²/g',0,true,SLAf,'spring SLA');
  VarCreate('NDemandGrowth','g/m²',0,true,NDemandGrowth,'N demand for current growth');
  VarCreate('NDemandDeficit','g/m²',0,true,NDemandDeficit,'N demand required to compensate for an existing N deficit');
  VarCreate('NDemandDeficitLeaf','g/m²',0,true,NDemandDeficitLeaf,'N demand required to compensate for an existing leaf N deficit');
  VarCreate('NDemandDeficitStem','g/m²',0,true,NDemandDeficitStem,'N demand required to compensate for an existing stem N deficit');
  VarCreate('NDemandDeficitRoot','g/m²',0,true,NDemandDeficitRoot,'N demand required to compensate for an existing root N deficit');
  VarCreate('NDemandDeficitGen','g/m²',0,true,NDemandDeficitGen,'N demand required to compensate for an existing pod N deficit');
  VarCreate('NSupply','g/m²',0,true,NSupply,'available N amount');

  VarCreate('TKM','g',0,true,TKM,'thousand-seed weight');
  VarCreate('Samenanzahl','m-2',0,true,Samenanzahl,'number of seeds per m²');
  VarCreate('HI','',0,true,HI,'Harvest-Index');
  VarCreate('NHI','',0,true,NHI,'Nitrogen Harvest Index');
  VarCreate('NUE','',0,true,NUE,'Nitrogen Use Efficiency');

  VarCreate('KonversionVerlust','',0,true,KonversionVerlust,'conversion loss caused by producing oil instead of starch');

  VarCreate('avs','',0,true,avs,'day of year at the start of vegetation, derived from temperature');
  VarCreate('Parav','[-]', 0.0, false, Parav,'mean PAR over five days used as the threshold for maintenance-respiration calculations');
  VarCreate('fW','',1,true,fW,'factor describing the influence of drought stress (Ferreyra 2013)');

  VarCreate('N_Def','',0,true,N_Def,'N-deficit factor, defined as the ratio of N demand to N uptake');
  VarCreate('CO2_factor', '[-]',1, true,  CO2_factor);

  StateCreate('DMShoot', 'g/m²',0.1, true,DMShoot,'shoot dry matter');
  StateCreate('DMShoot_OF','g/m²',0,true,DMShoot_OF,'shoot dry matter at the onset of flowering');
  StateCreate('DMShoot_nB','g/m²',0,true,DMShoot_nB,'shoot dry matter accumulated after flowering');
  StateCreate('DMShoot_nB_pot','g/m²',0,true, DMShoot_nB_pot,'potential shoot dry matter accumulated after flowering');
  StateCreate('DMShoot_vW','g/m²',0.1,true,DMShoot_vW,'shoot dry matter before winter');
  StateCreate('DMLeaf', 'g/m²',0, true,DMLeaf,'leaf dry matter');
  StateCreate('DMStem', 'g/m²',0, true,DMStem,'stem dry matter');
  StateCreate('DMRoot', 'g/m²',0, true,DMRoot,'root dry matter');
  StateCreate('DMGen', 'g/m²',0,true,DMGen,'generative-organ dry matter');
  StateCreate('DMPodWall','g/m²',0,true,DMPodWall,'pod-wall dry matter');
  StateCreate('DMSeed','g/m²',0,true,DMSeed,'seed dry matter');
  StateCreate('DMSeedStarch','g/m²',0,true,DMSeedStarch,'dry matter of the seed starch fraction');
  StateCreate('DMSeedOil','g/m²',0,true,DMSeedOil,'dry matter of the seed oil fraction');
  StateCreate('DMPlant', 'g/m²',0, true,DMPlant,'total plant dry matter');
  StateCreate('LAIShoot', 'm²/m²',0, true,LAIShoot,'shoot area');
  StateCreate('LAILeaf', 'm²/m²',0, true,LAILeaf,'leaf area');
  StateCreate('LAIStem', 'm²/m²',0, true,LAIStem,'stem area');
  StateCreate('NShoot', 'g/m²',0, true,NShoot,'shoot N amount');
  StateCreate('NLeaf', 'g/m²',0, true,NLeaf,'leaf N amount');
  StateCreate('strNStem', 'g/m²',0, true,strNStem,'structural stem N amount');
  StateCreate('poolNStem', 'g/m²',0, true,poolNStem,'stem N pool');
  StateCreate('NStem', 'g/m²',0, true,NStem,'stem N amount');
  StateCreate('NGen','g/m²',0,true,NGen,'generative-organ N amount');
  StateCreate('strNRoot', 'g/m²',0, true,strNRoot,'structural root N amount');
  StateCreate('poolNRoot', 'g/m²',0, true,poolNRoot,'root N pool');
  StateCreate('NRoot', 'g/m²',0, true,NRoot,'root N amount');
  StateCreate('NDead', 'g/m²',0, true,NDead,'N amount in dead leaves [g/m²]');
  StateCreate('NPlant', 'g/m²',0, true,NPlant,'total plant N amount [g/m²]');
  StateCreate('NSeed','g/m²',0,true,NSeed,'seed N amount [g/m²]');
  StateCreate('NPodWall','g/m²',0,true,NPodWall,'pod-wall N amount [g/m²]');
  StateCreate('NDeadW','g/m²',0,true,NDeadW,'N amount lost through frost senescence');
  StateCreate('NDeadSh','g/m²',0,true,NDeadSh,'N amount lost through shading senescence');
  StateCreate('NTransLeaf','g/m²',0,true,NTransLeaf,'translocatable N amount from leaves');
  StateCreate('NTransStem','g/m²',0,true,NTransStem,'translocatable N amount from stems');
  StateCreate('NTransGen','g/m²',0,true,NTransGen,'translocatable N amount from pods');
  StateCreate('NTransRoot','g/m²',0,true,NTransRoot,'translocatable N amount from roots');
  StateCreate('NTrans','g/m²',0,true,NTrans,'total translocatable N amount');
  StateCreate('potNTrans','g/m²',0,true,potNTrans,'potentially translocatable N amount');
  StateCreate('potNPool','g/m²',0,true,potNPool,'potential N amount in the pool');
  StateCreate('NUptake_pot', 'g/m²',0, true,NUptake_pot,'potential N uptake [g/m²]');
  StateCreate('NUptake_act', 'g/m²',0, true,NUptake_act,'actual N uptake [g/m²]');
  StateCreate('TempSum', '[°Cd]',0, true,TempSum,'temperature sum');
  StateCreate('TempSumAussaat', '[°Cd]',0, true,TempSumAussaat,'temperature sum since sowing');
  StateCreate('TempSumMinus', '[°Cd]',0, true,TempSumMinus,'temperature sum');
  StateCreate('TempSumAuflauf','[°Cd]',0,true,TempSumAuflauf,'temperature sum since emergence (Tb = 0°C)');
  StateCreate('TempSumPodGrowth','[°Cd]',0,true,TempSumPodGrowth,'temperature sum since EC 70');
  StateCreate('TempSumSeed','[°Cd]',0,true,TempSumSeed,'temperature sum during seed maturation');
  StateCreate('TempSumLeafLoss','[°Cd]',0,true,TempSumLeafLoss,'temperature sum since EC 51 used to calculate the decline in the leaf fraction of total plant growth');
  StateCreate('TempSumRoots','[°Cd]',0,true,TempSumRoots,'temperature sum between days of year 30 and 150 used to calculate fRoot');
  StateCreate('LAIs', 'm²/m²',0, true,LAIs,'area senesced through shading');
  StateCreate('DMdead', 'g/m²',0, true, DMdead,'senescent dry matter');
  StateCreate('DMDeadW', 'g/m²',0, true, DMDeadW,'dry matter killed by frost senescence');
  StateCreate('DMDeadLeafW', 'g/m²',0, true, DMDeadLeafW,'leaf dry matter killed by frost senescence');
  StateCreate('DMDeadStemW', 'g/m²',0, true, DMDeadStemW,'stem dry matter killed by frost senescence');
  StateCreate('DMDeadRootW','g/m²',0,true,DMDeadRootW,'root dry matter lost over winter');
  StateCreate('DMDeadSh', 'g/m²',0, true, DMDeadSh,'leaf dry matter killed by shading senescence');
  StateCreate('DMDeadN', 'g/m²', 0, true, DMDeadN,'leaf dry matter killed by N deficiency');
  StateCreate('DM_N','g/m²',0,true,DM_N,'former living green dry matter of leaves killed by N deficiency');
  StateCreate('DMNTrans','g/m²',0,true,DMNTrans,'leaf dry matter translocated under N deficiency');
  StateCreate('DMSh','g/m²',0,true,DMSh,'potential leaf dry matter killed and translocated through shading senescence');
  StateCreate('DMShTrans','g/m²',0,true,DMShTrans,'leaf dry matter translocated to pods through shading senescence');
  StateCreate('DMTransStem','g/m²',0,true,DMTransStem,'translocated stem dry matter');
  StateCreate('DMTransLeaf','g/m²',0,true,DMTransLeaf,'translocated leaf dry matter');
  StateCreate('DMTrans','g/m²',0,true,DMTrans,'translocated dry matter');
  StateCreate('LAIGen','m²/m²',0,true,LAIGen,'PodAreaIndex');
  StateCreate('C_Dead','kg/ha',0,true,C_Dead,'C amount in shed leaves');
  StateCreate('N_Dead','kg/ha',0,true,N_Dead,'N amount in shed leaves');

  StateCreate('Yield','dt/ha',0,true,Yield,'seed yield');
  StateCreate('OilYield','dt/ha',0,true,OilYield,'oil yield');
  StateCreate('Oilconc','%',0,true,Oilconc,'oil concentration');
  StateCreate('Protein','%',0,true,Protein,'protein content');
  StateCreate('Ymax','dt/ha',0,true,Ymax,'maximum yield');

  StateCreate('NPool','g/m²',0,true,NPool,'N pool in stems and roots for N translocated from leaves before generative organs become available as sinks');

  StateCreate('DMDeadAge', 'g/m²',0, true,DMDeadAge,'age-related senescence after EC 80');
  StateCreate('NDeadAge', 'g/m²',0, true,NDeadAge,'age-related senescence after EC 80');

  StateCreate('FullFlower','',0,true,FullFlower,'date of EC 65');
  StateCreate('SumKonversionVerlust','',0,true,SumKonversionVerlust,'cumulative conversion loss during oil formation');
  StateCreate('sumQ', '[MJ/m2]',0,true,sumQ,'cumulative intercepted radiation [MJ]');
  StateCreate('sumQT', '[MJ/m2]',0,true,sumQT,'cumulative temperature-corrected intercepted radiation [MJ]');
  StateCreate('sumQLeaf', '[MJ/m2]',0,true, sumQLeaf,'cumulative radiation intercepted by leaves');
  StateCreate('sumQGen', '[MJ/m2]',0,true, sumQgen,'cumulative radiation intercepted by pods');
  StateCreate('RadSum','[MJ/m²]',0,true, RadSum,'radiation sum');

  StateCreate('sumQT_TactTpot', '[MJ/m2]',0,true, sumQT_TactTpot,
    'cumulative drought- and temperature-corrected intercepted radiation [MJ]');

  StateCreate('NBalance','[g/m²]',0,true,NBalance);
  StateCreate('NUptake_vW','',0,true,NUptake_vW,'N uptake before winter');
  StateCreate('NUptake_aF','',0,true,NUptake_aF,'N uptake after flowering');



    // Parameters
  ParCreate('pfW', '[-]', 1, pfW,
    'parameter for none linear relation between Tansratio and SWDF (Ferreyra 2003)');
  ParCreate('Tb', '°C', 3 , Tb,'base temperature');
  ParCreate('gh', '', 1.2539 , gh,'slope parameter of the autumn allometric relationship');
  ParCreate('hh', '', -1.9765 , hh,'intercept parameter of the autumn allometric relationship');
  ParCreate('gf','',3.56389,gf,'slope parameter of the spring allometric relationship');
  ParCreate('hf','',-9.92018,hf,'intercept parameter of the spring allometric relationship');
  ParCreate('a','',2.7226,a,'parameter for dry-matter partitioning after EC 51');
  ParCreate('b','',-4.9899,b,'parameter for dry-matter partitioning after EC 51');
  ParCreate('c','',4E-12,c,'parameter for dry-matter partitioning after EC 51');
  ParCreate('d','',-0.561,d,'parameter for dry-matter partitioning after EC 51');
  ParCreate('e','',70,e,'parameter for dry-matter partitioning after EC 51');
  ParCreate('root_exp','',-0.05,root_exp,'parameter of the exponential DMRoot function');
  ParCreate('SPA_Exp','',-0.05,SPA_exp,'parameter of the exponential SPA function');
  ParCreate('fPW_0','',100,fPW_0,'parameter of the yield function fPW');
  ParCreate('fPW_exp','',-0.008,fPW_exp,'parameter of the yield function fPW');
  ParCreate('pCnPod1','',8,pCnPod1,'pod dilution function');
  ParCreate('pCnPod2','',-0.8,pCnPod2,'pod dilution function');
  ParCreate('pCnstem1h', '', 0.0458 , pCnstem1h,'coefficient preceding the exponential term of the autumn stem dilution function');
  ParCreate('pCnstem2h', '', -0.0021 , pCnstem2h,'coefficient preceding the variable in the autumn stem dilution function');
  ParCreate('pCnRoot1h', '',3.3127, pCnRoot1h,'coefficient preceding the exponential term of the root dilution function');
  ParCreate('pCnRoot2h', '',-0.11, pCnRoot2h,'coefficient preceding the variable in the root dilution function');
  ParCreate('pCnRoot1f', '',3.9548, pCnRoot1f,'coefficient preceding the exponential term of the root dilution function');
  ParCreate('pCnRoot2f', '',-0.0059, pCnRoot2f,'coefficient preceding the variable in the root dilution function');
  ParCreate('pCnleaf', '', 5.659 , pCnleaf,'leaf N concentration');
  ParCreate('pCn1leaf', '', 6.707 , pCn1leaf,'intercept preceding DMLeaf');
  ParCreate('pCn2leaf', '', -0.01624 , pCn2leaf,'slope of the autumn leaf dilution function');
  ParCreate('pCnDead', '%', 2 , pCnDead,'N concentration of dead leaves');
  ParCreate('pCnRoot', '%', 4 , pCnRoot,'root N concentration');
  ParCreate('pCnSeed','%',3,pCnSeed,'seed N concentration');
  ParCreate('pCnTrans','',0.65,pCnTrans,'fraction of N translocated from senescent leaves');
  ParCreate('Ct1', '°C', 3 , Ct1,'lower growth temperature');
  ParCreate('Ct2', '°C', 10 , Ct2,'lower optimum temperature');
  ParCreate('Ct3', '°C', 20 , Ct3,'upper optimum temperature');
  ParCreate('Ct4', '°C', 35 , Ct4,'upper growth temperature');
  ParCreate('SLAhst', '', -0.2759 , SLAhst,'slope parameter of autumn specific leaf area');
  ParCreate('SLAhin', '', 396.52 , SLAhin,'intercept of autumn specific leaf area');
  ParCreate('SLAmin', 'cm²/g', 100 , SLAmin,'minimum autumn specific leaf area');
  ParCreate('SLAmax', 'cm²/g', 350 , SLAmax,'maximum autumn specific leaf area');
  ParCreate('SLAnB','cm²/g',275,SLAnB,'specific leaf area after flowering');
  ParCreate('SLADead', 'cm²/g', 500 , SLADead,'SLA of senescent leaves [cm²/g]');
  ParCreate('fTminus', '°C', 20 , fTminus,'temperature threshold for winter senescence');
  ParCreate('SSA', 'cm²/g', 20 , SSA,'specific stem area');
  ParCreate('SPAmax','cm²/g',60,SPAmax,'maximum specific pod area');
  ParCreate('k1', '', 0.02 , k1,'growth rate from EC 10 to EC 13');
  ParCreate('DMcrit', 'g/m²', 5 , DMcrit,'dry-matter threshold for exponential growth');
  ParCreate('rooti', '', 0.119184 , rooti,'intercept of the root-fraction regression');
  ParCreate('roots', '', -0.000029 , roots,'slope of the root-fraction regression');
  ParCreate('exk', '', 0.8 , exk,'extinction coefficient');
  ParCreate('exk_0', '', 0.9 , exk_0,'extinction coefficient at LAI 0 for the variable Exk');
  ParCreate('LAIcrit_exk', 'm2/m2', 1.5 , LAIcrit_exk,'LAIcrit at which the extinction coefficient equals exk');
  ParCreate('LUELeaf', 'g/MJ', 4 , LUELeaf,'radiation-use efficiency');
  ParCreate('LUE0', '', 3.196 , LUE0,'intercept of the pre-winter LUE equation');
  ParCreate('LUEPod','',4,LUEPod,'pod LUE');
  ParCreate('fCO2', '[-]',   0.086,  fCO2);
  ParCreate('fCO2_scale', '[-]',   0.723,  fCO2_scale);
  ParCreate('fCWSI', '[-]',   0.077,  fCWSI);
  ParCreate('CiCompensation', '[ppm]',   350,  CiCompensation);
  ParCreate('PARmh', 'W/m²', 0.03456 , PARmh,'maintenance radiation required in autumn');
  ParCreate('PARmf', 'W/m²', 0.03456 , PARmf,'maintenance radiation required in spring');
  ParCreate('pfTm_opt', '°C', 20, pfTm_opt,'optimum temperature for the Arrhenius fTm response');
  ParCreate('pfTm_Q10', '', 2, pfTm_Q10,'Q10 value of the Arrhenius fTm response');
  ParCreate('pSen_sh', '', 3, pSen_sh,'number of days over which PARm is averaged');
  ParCreate('pSen_sh_w', '', 1, pSen_sh_w,'exponent controlling the effect of fSen_sh');
  ParCreate('fSws', '',0.005, fSws,'relative loss rate caused by winter senescence');
  ParCreate('Plants', 'm-2',40, Plants,'plants per m²');
  ParCreate('pIniLAI', 'cm2/plant', 1, pIniLAI,'LAI after emergence when InitOption is LAIInit [cm²/plant]');
  ParCreate('pCncritLeaf','%',4.3,pCncritLeaf,'critical leaf dilution function before stem elongation');
  ParCreate('pCncrit1Leaf','',5.8664,pCncrit1Leaf,'critical leaf dilution function after stem elongation begins');
  ParCreate('pCncrit2Leaf','',-0.0187,pCncrit2Leaf,'critical leaf dilution function after stem elongation begins');
  ParCreate('pCncritStem1h','',3.2894,pCncritStem1h,'critical stem dilution function before stem elongation');
  ParCreate('pCncritStem2h','',-0.013,pCncritStem2h,'critical stem dilution function before stem elongation');
  ParCreate('pCncritPod1','',7.5238,pCncritPod1,'critical pod dilution function');
  ParCreate('pCncritPod2','',-0.872,pCncritPod2,'critical pod dilution function');
  ParCreate('pCncritRoot1h','',2.9569,pCncritRoot1h,'critical root dilution function before stem elongation');
  ParCreate('pCncritRoot2h','',-0.156,pCncritRoot2h,'critical root dilution function before stem elongation');
  ParCreate('pCncritRoot1f','',3.9241,pCncritRoot1f,'critical root dilution function after stem elongation begins');
  ParCreate('pCncritRoot2f','',-0.0097,pCncritRoot2f,'critical root dilution function after stem elongation begins');
  ParCreate('pCnStem1f','',7.7107,pCnStem1f,'stem dilution function after stem elongation begins');
  ParCreate('pCnStem2f','',-0.95,pCnStem2f,'stem dilution function after stem elongation begins');
  ParCreate('pCncritStem1f','',5.6311,pCncritStem1f,'critical stem dilution function after stem elongation begins');
  ParCreate('pCncritStem2f','',-0.86,pCncritStem2f,'critical stem dilution function after stem elongation begins');

  ParCreate('y1','[-]',0.37,y1,'yield-calculation parameter, currently equivalent to the harvest index');
  ParCreate( 'LUEscaling', '[-]',1,LUEscaling,'for simulatanous scaling of LUEveg and LUEgen');
//  ParCreate( 'minNNI', '[-]',0.0, minNNI,'Minimum value for NNI');

  ParCreate('SLAspring','',101.97,SLAspring,'parameter for calculating SLA after EC 30 as a function of GAI');
  ParCreate('fSLAspring','',24.121,fSLAspring,'parameter for calculating SLA after EC 30 as a function of GAI');

  ParCreate('Oila','',50,Oila,'parameter for calculating oil concentration from seed-maturation duration');
  ParCreate('Oilb','',240,Oilb,'parameter for calculating oil concentration from seed-maturation duration');
  ParCreate('Oilc','',-0.016,Oilc,'parameter for calculating oil concentration from seed N amount');
  ParCreate('Oild','',-0.0226,Oild,'parameter for calculating oil concentration from seed N amount');

  // External Variable

  ExternVCreate('Rad_Int', 'W/m²',statefield, GRad,'global radiation');
  ExternVCreate('TMPM', '°C',statefield, TMPM,'daily mean temperature');
  ExternVCreate('EC', '',statefield, EC,'phenological stage');
  ExternVCreate('DVS', '',ratefield, DVS_rate,'phenological stage');
  ExternVCreate('DVS','',statefield, DVS,'Development-Stage');
  ExternVCreate('DayofYear', '',statefield, DayofYear,'day of year');
  ExternVCreate('LAI', 'm²/m²',statefield, LUE_LAI,'LAI used for LUE');
  ExternVCreate('DM', 'g.m-2.d-1',ratefield, DMGrowth_ex,'shoot dry-matter increment for the ExternDM option');
  ExternVCreate('TransRatio','',statefield,TransRatio,'ratio of potential to actual transpiration');
  ExternVCreate('TransIntRatio','',statefield,TransIntRatio,'ratio of potential to actual transpiration, including interception');
//  ExternVCreate('CO2pp','[ppm]',statefield, CO2pp, 'external atmospheric CO2-concentration');

//  ExternVCreate('TMeanEC71_79','°C',statefield,TMeanEC71_79,'mean daily temperature between EC 71 and EC 79');
//  ExternVCreate('DauerEC71_79','d',statefield,DauerEC71_79,'number of days from EC 71 to EC 79');
//  ExternVCreate('DauerEC81_89','d',statefield,DauerEC81_89,'number of days from EC 81 to EC 89');
  StateCreate('DauerEC81_89', '',0, true, DauerEC81_89);

  // Options

  OptCreate ('LAIOption', 'InternLAI', LAIOption,'internally calculated LAI or external variable');
  LAIOption.Optionlist.Clear;
  LAIOption.Optionlist.add('InternLAI');
  LAIOption.Optionlist.add('ExternLAI');
  fLAIOption := InternLAI;

  OptCreate ('DMGrowthOption', 'InternDM', DMGrowthOption, 'internally calculated dry-matter increment or external variable');
  DMGrowthOption.Optionlist.Clear;
  DMGrowthOption.Optionlist.add('InternDM');
  DMGrowthOption.Optionlist.add('ExternDM');
  fDMGrowthOption := InternDM;

  OptCreate('InitOption', 'DMCrit', InitOption, 'initialization from exponentially growing dry matter or initial LAI');
  InitOption.Optionlist.Clear;
  InitOption.Optionlist.add('DMCrit');
  InitOption.Optionlist.add('LAIInit');
  fInitOption := DMCritInit;



  OptCreate ('NSensOption', 'N_sensitiv', NSensOption, 'effect of N deficiency on dry-matter growth');
  NSensOption.Optionlist.Clear;
  NSensOption.Optionlist.add('N_sensitiv');
  NSensOption.Optionlist.add('N_unlimited');
  fNSensOption := N_sensitiv;

  OptCreate ('DroughtOption', 'DroughtImpact', DroughtOption, 'effect of drought stress on dry-matter growth');
  DroughtOption.Optionlist.Clear;
  DroughtOption.Optionlist.add('DroughtImpact');
  DroughtOption.Optionlist.add('NoDroughtImpact');
  fDroughtOption := DroughtImpact;

  OptCreate('optCO2', 'NoCO2Effect', OptWithCO2);
  OptWithCO2.OptionList.Clear;
  OptWithCO2.OptionList.Add('NoCO2Effect');
  OptWithCO2.OptionList.Add('WithCO2Effect');


end;


procedure TOSRGrowth.init(var GlobMod: TMod);

var
  i : Integer;

begin
  inherited init(GlobMod);
  // Initial values that prevent division by zero
  if DMShoot.v <=0 then DMShoot.v := 0.1;
  if DMPlant.v =0 then DMPlant.v := 0.1;
  if DMShoot_vW.v = 0 then DMShoot_vW.v := 0.1;


  if uppercase(LAIOption.Option) = uppercase('InternLAI') then fLAIOption := InternLAI;
  if uppercase(LAIOption.Option) = uppercase('ExternLAI') then fLAIOption := ExternLAI;
  LUE_LAI.search := (fLAIOption = ExternLAI);

  if uppercase(DMGrowthOption.Option) = uppercase('InternDM') then fDMGrowthOption := InternDM;
  if uppercase(DMGrowthOption.Option) = uppercase('ExternDM') then fDMGrowthOption := ExternDM;
  DMGrowth_ex.Search := (fDMGrowthOption = ExternDM);

  if uppercase(InitOption.Option) = uppercase('DMCrit') then fInitOption := DMCritInit;
  if uppercase(InitOption.Option) = uppercase('LAIInit') then fInitOption := LAIInit;

  if uppercase(NSensOption.Option) = uppercase('N_sensitiv') then fNSensOption := N_sensitiv;
  if uppercase(NSensOption.Option) = uppercase('N_unlimited') then fNSensOption := N_unlimited;

  if uppercase(DroughtOption.Option) = uppercase('DroughtImpact') then fDroughtOption := DroughtImpact;
  if uppercase(DroughtOption.Option) = uppercase('NoDroughtImpact') then fDroughtOption := NoDroughtImpact;

  Auflauf.v := 0;
  DateHarvestWasSet := false;
  for i := 1 to MaxParDays do
    Par_arr[i] := 5.0;
  PARav.v := 0;

  for i := 1 to MAxParDays do
    Parav.v := Parav.v+par_arr[i];
  parav.v := parav.v/MaxParDays;
  CO2_factor.v := 1.0;

 // if (OptWithCO2.option = 'withco2effect') then
 //   CO2pp.Search := true;
 // else
 //   CO2pp.Search := false;


end;


procedure TOSRGrowth.CalcRates;

var
  i,j : integer; // Loop counter for the shading-senescence calculation
  LAIm_ave, // LAI supported by maintenance radiation, averaged over pSen_sh days
  CWSI,  // crop water stress index
  CO2_factor_min,
  CO2_ppm, // actual CO2 concentration [ppm]
  TT: real;
begin
  inherited;

  if (Globtime.v >= SowingDate.v) and (GlobTime.v <= HarvestDate.v) then begin


  // Calculate effective temperature and thermal-time sums (Tb is the base temperature; Tb = 3°C for oilseed rape)
    Teff.v := max(0,TMPM.v-Tb.v);
    TempSum.c := Teff.v;

    if Globtime.v >= SowingDate.v then
      TempSumAussaat.c := Teff.v
      else TempSumAussaat.c := 0;

    if (EC.v >= 10) then
      TempSumAuflauf.c := Teff.v
    else TempSumAuflauf.c := 0;

    if (EC.v >= 70) then
      TempSumPodGrowth.c := Teff.v
    else TempSumPodGrowth.c := 0;

    if (EC.v <= 65) then
      FullFlower.v := Globtime.v;

    if (EC.v >= 80) then
      TempSumSeed.c := Teff.v
    else
      TempSumSeed.c := 0;

    if (EC.v > 51) then
      TempSumLeafLoss.c := Teff.v
    else TempSumLeafLoss.c := 0;

    if ((DayofYear.v > 30) and (DayofYear.v < 150)) then
      TempSumRoots.c := Teff.v
    else TempSumRoots.c := 0;

    // Negative temperature sum used for frost senescence
    if Assigned(SnowModel) then begin
      if SnowModel.Zs.v > CropHeight.v then Tminus.v := min(0, SnowModel.Tsf.v)
      else if Cropheight.v > 0
        then Tminus.v := min(0, (SnowModel.Tsf.v*SnowModel.Zs.v + TMPM.v*(CropHeight.v-SnowModel.Zs.v))/CropHeight.v)
        else Tminus.v := 0;
    end
    else Tminus.v := min(0, TMPM.v);
    if EC.v >= 10 then TempSumMinus.c := -Tminus.v;

    // Temperature correction factor for dry-matter production
    if TMPM.v < Ct1.v then fT.v := 0
    else If TMPM.v <= Ct2.v then fT.v := (TMPM.v-Ct1.v)/(Ct2.v-Ct1.v)
    else if TMPM.v <= Ct3.v then fT.v := 1
    else if TMPM.v <= Ct4.v then fT.v := (Ct4.v-TMPM.V)/(Ct4.v-Ct3.v)
    else fT.v := 0;

  // Calculate maximum GAI, SAI, and PAI; SAI and PAI increase until EC 80
    maxGAI.v := max(LAILeaf.v+LAIGen.v+LAIStem.v,maxGAI.v);

    if (EC.v < 80) then
      maxLAIGen.v := LAIGen.v;

    if (EC.v < 80) then
      maxLAIStem.v := LAIStem.v;


  // Determine the start of vegetation from temperature
   if ((DayofYear.v > 30) and (DayofYear.v < 90)) and  (Teff.v > 0) then
      inc(avs_day)
   else
      avs_day := 0;

   if (avs_day = 5) and (avs.v = 0) then
     avs.v := DayofYear.v;

   if (EC.v >= 81) and (EC.v <= 89) then DauerEC81_89.c := 1 else DauerEC81_89.c := 0;


  // Calculate photosynthetically active radiation and cumulative radiation
    PARRad.v :=  GRad.v*0.5;
    RadSum.c := PARRad.v;

  // Account for reflection by the flowering canopy, which reflects or absorbs up to 30% of incoming radiation
    if (EC.v >= 60) and (EC.v <=70) then
      if (EC.v <=65) then
        Transkoeff.v := min(1,((0.7-1)/(65-60))*(EC.v-60)+1)
      else
        Transkoeff.v := min(1,((1-0.7)/(70-65))*(EC.v-65)+0.7)
    else
      Transkoeff.v := 1;

  // Extinction coefficients of leaves and pods
    If (EC.v > 51) then
      act_k_Leaf.v := 0.8
    else
      act_k_Leaf.v := ExtCoeffPAR;  // LAI-dependent extinction coefficient during the vegetative phase (K. Krause, 2010, MSc thesis: site-specific analysis of vegetative winter oilseed rape growth)

    act_k_Gen.v := 0.6;             // Andersen et al. 1996: The effects of drought and nitrogen on light interception, growth and yield of winter oilseed rape. Acta Agriculturae Scandinavica Sect. B Soil and Plant Sciences 46, 55-67

  // Emergence and initialization of LAI, dry matter, and N
    if EC.v >= 10 then begin
      if (Auflauf.v = 0) and (LAILeaf.v = 0) then begin
        Auflauf.v := Globtime.v;
        if (fInitOption = LAIInit) then begin
          LAILeaf.v := pIniLAI.v*plants.v/10000;
          LAIShoot.v := LAILeaf.v;
          DMLeaf.v := DMShoot.v;
          DMStem.v := DMShoot.v * 0.1;
          NcLeaf.v := pCn1Leaf.v;
          NLeaf.v  := DMLeaf.v * NcLeaf.v/100;
          NcStem.v := pCnStem1h.v;
          NStem.v  := DMStem.v * NcStem.v;
          NShoot.v := NLeaf.v;
        end;
      end;

  // Calculate fInt separately for vegetative organs and pods
  // Fraction of total incoming radiation intercepted as a function of extinction coefficients and area indices
    if fLAIOption = InternLAI then begin
      fIntLeaf.v := max (0,1-exp(-act_k_Leaf.v*LAILeaf.v));
      fIntGen.v := max(0,1-exp(-act_k_Gen.v*LAIGen.v));
    end
    else
      fInt.v := max (0, 1-exp(-act_k.v*LUE_LAI.v));

  // Trockenstressfaktor (nicht-linearer Einfluss)
  // Ferreyra 2003: Nonlinear effects of water stress on peanut photosynthesis at crop and leaf scales. Ecological Modelling 168, 57-76
    if (fDroughtOption = DroughtImpact) then
    begin
      fW.v := 1 - power((1 - TransIntRatio.v), pfW.v);
    end else begin
      fW.v := 1;
      sumQT_TactTpot.c := 0.0
    end;

// see https://onlinelibrary.wiley.com/doi/full/10.1111/gcb.13600

 if OptWithCO2.option = 'withco2effect' then begin
      CO2_ppm := CO2_ppm_f(GlobTime.v);
      TT := (163- self.Ex_TMPM.v)/(5-0.1*Ex_TMPM.v);
      CO2_factor.v := ((CO2_ppm - TT)*(350+2*TT))/
                      ((CO2_ppm+2*TT)*(350-TT));

  end;
  // Calculate radiation intercepted by individual organs
      QGen.v :=  (fIntGen.v * PARRAD.v*86400/1000000);
      sumQGen.c := QGen.v;
    end;

    if (QGen.v > 0) then begin
      QLeaf.v := fIntLeaf.v * (PARRAD.v*86400/1000000-QGen.v)*Transkoeff.v
    end
    else begin
      QLeaf.v := (fIntLeaf.v * PARRAD.v*86400/1000000)*Transkoeff.v;
    end;
    sumQLeaf.c := QLeaf.v;

  // Calculate radiation intercepted by the entire crop
   if PARRAD.v >0.0 then
    fInt.v := max(0,min(1,(QLeaf.v+QGen.v)/(PARRAD.v*86400/1000000)))
   else fInt.v := 0.0;

    Q.v := fInt.v * (PARRAD.v * 86400/1000000);
    sumQ.c := Q.v;
    QT.v := Q.v * fT.v;
    sumQT.c := QT.v;


  // Zwischenrechnungen
  // Shoot dry matter at the beginning of flowering
    if (EC.v <= 60) then
      DMShoot_OF.c := DMShoot.c
    else
      DMShoot_OF.c := 0;

  // Shoot dry matter accumulated after flowering begins
    if (EC.v > 60) then begin
      DMShoot_nB.c := DMShoot.c ;
      DMShoot_nB_pot.c := DMShoot.c/fW.v;
    end
    else begin
      DMShoot_nB.c := 0;
    end;

  // N uptake through the end of the calendar year
    if (DayofYear.v >= 217) and (DayofYear.v <= 365) then
      NUptake_vW.c := NUptake_act.c
    else
      NUptake_vW.c := 0;

  // N uptake after flowering
    if (EC.v >= 70) then
      NUptake_aF.c := NUptake_act.c
    else
      NUptake_aF.c := 0;


  // LUE of vegetative and generative biomass, reduced after EC 70 by senescence, seed development, and oil formation
     {LUE parameters are correspondingly high because they represent effective LUE.}

    If (DayofYear.v <= 30) or ((DayofYear.v >= 217) and (EC.v < 30)) then
      LUE.v := LUELeaf.v
    else
      if (DayofYear.v > 30) and (DayofYear.v <= 60) then
        LUE.v := ((LUE0.v - LUELeaf.v)/(60-30))*(DayofYear.v - 30) + LUELeaf.v
      else
        if (EC.v > 70) then
          LUE.v := min(LUE.v,max(0.1,((0.1-LUE0.v)/20)*(EC.v-70)+LUE0.v))
        else
          LUE.v := LUE0.v;

    // LUE of generative biomass
      {Leterme 1985: Modélisation de la croissance et de la production des
       siliques chez le colza d'hiver}

    if (EC.v > 70) then
      LUEGen.v := min(LUEGen.v,max(0.1,((0.1-LUEPod.v)/20)*(EC.v-70)+LUEPod.v))
    {else
      if (EC.v > 51) and (EC.v < 61)
      LUEGen.v := min(LUEPod.v, max(0.1, ((LUEPod.v - 0.1)/10)*(EC.v-51)+0.1)) }
    else
      LUEGen.v := LUEPod.v;
   // apply scaling factor
     LUE.v := LUE.v * LUEscaling.v;
     LUEGen.v := LUEGen.v * LUEscaling.v;


  // Trockenmasseproduktion
    DMShoot.c := 0;

    if {(EC.v < 30)} (DayofYear.v < 30) then
      maxfRoot.v := fRoot.v;

    // Root-growth fraction of total growth (W. Weymann dissertation, Chapter 4, Figure 2)
    if ((DayofYear.v < 30) or (DayofYear.v > 217)) and (EC.v < 30) then
        {fRoot.v := max(0,roots.v*TempSumAuflauf.v + rooti.v)}
        fRoot.v := max(0, rooti.v * power(TempSumAuflauf.v, 2)+roots.v*TempSumAuflauf.v)
    else
      if (EC.v <= 69) then
        fRoot.v := max(0.05, ((0.05-maxfRoot.v)/(100-0))*(TempSumRoots.v)+maxfRoot.v)
        {fRoot.v := max(0.05,maxfRoot.v*exp(root_exp.v*TempSumAuflauf.v))}
      else
        fRoot.v := 0.05;

    // Dry-matter production as a function of intercepted radiation, LUE,
    // N deficiency, water deficit, temperature response, and assimilate translocation
    if fDMGrowthOption = InternDM then begin
      If (fInitOption = DMCritInit) and (DMShoot.v<DMcrit.v) and (EC.v>=10) then begin  // Initial phase: temperature-limited exponential growth without radiation
        DMShoot.c :=   k1.v*DMShoot.v*Teff.v;
        if (DMShoot.v+DMShoot.c) > DMcrit.v then DMShoot.c := DMcrit.v - DMShoot.v;
        DMRoot.c := fRoot.v*(1+fRoot.v)*DMShoot.c;
        DMPlant.c := DMShoot.c + DMRoot.c;
      end;
      If (fInitOption = LAIInit) or (DMShoot.v+DMShoot.c >= DMcrit.v) then begin   // LUE-based growth from DMcrit onward
        if (fInitOption = DMCritInit) and (DMShoot.v < DMcrit.v)
        then  {Dry matter exceeds DMcrit on the current day.}
          DMPlant.c := DMPlant.c + (Q.v*LUE.v*fT.v* CO2_factor.v)*(1-DMShoot.c/(k1.v*DMShoot.v*Teff.v))
        else
          if (QGen.v > 0) then begin
//            LUEGen.v := LUE.v;
            if (fDroughtOption =  DroughtImpact) then
              DMPlant.c :=  (((QLeaf.v*LUE.v* CO2_factor.v*((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))
                               +QGen.v*LUEGen.v*CO2_factor.v*NNIGen.v)*fT.v )*fW.v)+ DMTrans.c
            else
              DMPlant.c :=  (((QLeaf.v*LUE.v* CO2_factor.v*((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))
                               +QGen.v*LUEGen.v*CO2_factor.v*NNIGen.v)*fT.v ))+ DMTrans.c;
            {DMRoot.c := fRoot.v *  DMPlant.c;
            DMShoot.c :=   DMPlant.c-DMRoot.c;}
            DMShoot.c := DMPlant.c * (1-fRoot.v);
          end
          else
            if (EC.v >=10) then begin
              if (fDroughtOption = DroughtImpact) then
                DMPlant.c :=  ((QLeaf.v*LUE.v* CO2_factor.v * ((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))*fT.v)*fW.v)+ DMTrans.c
              else
                DMPlant.c :=  ((QLeaf.v*LUE.v* CO2_factor.v * ((LAILeaf.v*NNILeaf.v + LAIStem.v*NNIStem.v)/(LAILeaf.v+LAIStem.v))*fT.v))+ DMTrans.c;
              {DMRoot.c := fRoot.v *  DMPlant.c;
              DMShoot.c :=   DMPlant.c-DMRoot.c;}
              DMShoot.c := DMPlant.c * (1-fRoot.v);
          end
          else begin
            DMPlant.c := 0;
            DMShoot.c := 0;
          end;
      end;
    end
    else begin  {ExternDM}
      DMShoot.c := DMGrowth_ex.v;
      DMRoot.c := fRoot.v *  DMShoot.c / (1-fRoot.v);
      DMPlant.c := DMShoot.c+DMRoot.c;
    end;


  // Calculate crop height (W. Weymann dissertation, Chapter 4, Figure 1)
    CropHeight.v := min(1.8,0.0539*exp(0.0458* EC.v));

  // Calculate winter senescence from DMShoot
    If TempSumMinus.v >= fTminus.v
    then
      DMDeadW.c := min(DMShoot.v*TempSumMinus.c*fSws.v,DMShoot.c+DMLeaf.v)
    else
      DMDeadW.c := 0;


  // Senescence caused by shading or insufficient radiation for maintenance respiration
  { B. Gabrielle, P. Denoroy, G. Gosse, E. Justes, M.N. Andersen 1989:
    A model of leaf area development and senescence for winter oilseed rape
    Field Crops Research 57, 209–222}

    if (EC.v <= 70) then
      LAILeaf_EC70.v := LAILeaf.v;

  // Radiation values averaged over ten days
    for i := MaxParDays downto 2 do
      Par_arr[i] := Par_arr[i-1];
    Par_arr[1] := PARRad.v;
    PARav.v := 0;
    for i := 1 to MAxParDays do
      Parav.v := Parav.v+par_arr[i];
    parav.v := parav.v/MaxParDays;

   // Temperature response for maintenance respiration
    fTm.v := power(pfTm_Q10.v, (TMPM.v-pfTm_opt.v)/10);

    if (TMPM.v < 10) and (fT.v < fTm.v) then
      fTSen.v := fTm.v
    else
      fTSen.v := fT.v;

  // Calculate maintainable LAI (LAIm)
    if (EC.v < 30) then
      if (PARav.v*fTSen.v >= PARmh.v*fTm.v) then
        LAIm.v := 1/act_k_Leaf.v*log10((PARav.v*fTSen.v)/(PARmh.v*fTm.v))
      else LAIm.v := 0
    else
      if (EC.v >= 60) then
        if (PARav.v*Transkoeff.v*fTSen.v >= PARmf.v*fTm.v) then
          LAIm.v := 1/act_k_Leaf.v*log10((PARav.v*Transkoeff.v*fTSen.v)/(PARmf.v*fTm.v))
        else
          LAIm.v := 0
      else
        if (PARav.v*fTSen.v >= PARmf.v*fTm.v) then
          LAIm.v := 1/act_k_Leaf.v*log10((PARav.v*fTSen.v)/(PARmf.v*fTm.v))
        else
          LAIm.v := 0;

    for i:= 9 downto 1 do LAImarray[i+1]:= LAImarray[i];
      LAImarray[1] := LAIm.v;

    LAIm_ave := 0;

  // Calculate the senescence factor
    fSen_sh.v := 0;
    if LAIShoot.v>0 then for i := 1 to round(pSen_sh.v) do begin
      LAIm_ave := LAImarray[1];
      for j := 1 to i-1 do LAIm_ave := max(LAIm_ave, LAImarray[j+1]);
      fSen_sh.v := fSen_sh.v + max(0,1-LAIm_ave/LAIShoot.v)/round(pSen_sh.v);
    end;

  // Calculate leaf senescence
    if (EC.v <= 70) then
      if (fT.v > 0) then begin
        LAIs.c := min(LAILeaf.v, LAIShoot.v*(Power(fSen_sh.v,pSen_sh_w.v)));
        DMDeadSh.c := LAIs.c/SLADead.v*10000{cm²/m²};
      end
      else begin
        LAIs.c := 0;
        DMDeadSh.c := 0;
      end
    else  // Age-related senescence after EC 70, independent of shading
      LAIs.c := -((((0 - LAILeaf_EC70.v)/(90-70))*(EC.v-70)+LAILeaf_EC70.v)-LAILeaf.v);

  // Change of Dead LAI
    // SLA of senescent leaves = 500 cm²/g
      DMDeadSh.c := LAIs.c/SLADead.v*10000{cm²/m²};

    if (avSLA.v > 0) and (fT.v > 0) then
      DMSh.c := LAIs.c/avSLA.v*10000  // non dead leaf mass
    else
      DMSh.c := 0;

    DMShTrans.c := DMSh.c - DMDeadSh.c;  // translozierbare DM


  // Partition dry matter among organs
    // Allometrische Funktionen
    {Dissertation W. Weymann, 2015: Organ-specific approaches describing crop development of winter oilseed rape under optimal and N-limited conditions (Chapter 3)}
    {Weymann et al. 2016: Organ-specific approaches describing crop growth of winter oilseed rape under optimal and N-limited conditions. European Journal of Agronomy)}

    if (EC.v < 51) then
      fBl_EC51.v := fBl.v;

    {if (DayofYear.v <= 60) or ((DayofYear.v >= 217) and (EC.v <30)) then begin}
    if (EC.v < 30) then begin
      fBl.v := 1/(1+exp(hh.v)*gh.v*power(max(0, DMLeaf.v), (gh.v-1)));
      fSt.v := 1-fBl.v;
      fGen.v := 0;
    end
    else
      if (EC.v < 51) then begin
        fBl.v := 1/(1+exp(hf.v)*gf.v*power(max(0, DMLeaf.v), (gf.v-1)));
        fSt.v := 1-fBl.v;
        fGen.v := 0;
      end
      else
        if (EC.v <= 70) then begin
           {fBl.v := max(0,min(fBl.v,c.v*power(EC.v,2)+d.v*EC.v+e.v));}
           {fBl.v := max(0, min(fBl.v,((0-fBl_EC51.v)/(80-70))*(EC.v - 70) + fBl_EC51.v));}
           fBl.v := max(0, min(fBl.v, c.v * TempSumLeafLoss.v + fBl_EC51.v));
           {fSt.v := (1-fBl.v)*(min(0.95, max(0, (a.v * exp(b.v*EC.v)))));
           fGen.v := (1-fBl.v)*(1-fSt.v);}
           fSt.v := (1-fBl.v)*(1/(1+exp(a.v)*b.v*power(max(0,DMStem.v),(b.v-1))));
           fGen.v := (1-fBl.v)*(1-fSt.v);
           fSeedGen.v := max(0,min(1, 1/(1+fPW_0.v*exp((EC.v-50)*fPW_exp.v))));
           fPW.v := 1-fSeedGen.v;
        end
        else
          if (EC.v > 70) and (EC.v < 80) then begin
            {fBl.v := max(0,min(fBl.v,c.v*power(EC.v,2)+d.v*EC.v+e.v));}
            fBl.v := max(0, min(fBl.v, c.v * TempSumLeafLoss.v + fBl_EC51.v));
            {fBl.v := 0;}
            fGen.v := 1-fBl.v;
            fSt.v := 0;
            fSeedGen.v := max(0, min(1, 1/(1+fPW_0.v*exp((EC.v-50)*fPW_exp.v))));
            fPW.v := 1-fSeedGen.v;
          end
          else begin
            fBl.v := 0;
            fSt.v := 0;
            fGen.v := 1;
            fPW.v := 0;
            fSeedGen.v := 1;
          end;

    fBl.v := fBl.v * (1-fRoot.v);
    fSt.v := fSt.v * (1-fRoot.v);
    fGen.v := fGen.v * (1-fRoot.v);
    fRoot.v := fRoot.v;


  // Adjust NNI and reduce growth
   { Reduction depends on the N deficiency of each organ (NNIi);
     the calculated NNI differs from the NNI of Justes et al. (1994) and
     Colnenne et al. (1998) because it is derived from dilution functions. }
    fNNILeaf.v := fBl.v * NNILeaf.v;
    fNNIStem.v := fSt.v * NNIStem.v;
    fNNIGen.v := fGen.v * NNIGen.v;

    fSum.v := fNNILeaf.v + fNNIStem.v + fNNIGen.v;

    if (fSum.v > 0) then begin
      fNNILeaf.v := NNILeaf.v / fSum.v;
      fNNIStem.v := NNIStem.v / fSum.v;
      fNNIGen.v := NNIGen.v / fSum.v;
      fBl.v := fNNILeaf.v * fBl.v;
      fSt.v := fNNIStem.v * fSt.v;
      fGen.v := fNNIGen.v * fGen.v;
    end
    else
      fGen.v := 1;


  // Calculate dry matter
    DMLeaf.c := fBl.v *  DMShoot.c;
    DMStem.c := fSt.v *  DMShoot.c;
    DMGen.c := fGen.v *  DMShoot.c;
    DMPodWall.c := fPW.v * DMGen.c;
    DMSeed.c := fSeedGen.v * DMGen.c;

    // Conversion loss caused by oil formation
    KonversionVerlust.v := (DMSeed.c {* (Oilconc.v/100)})*0.4;   // changed 2019-01-17 by UB
    DMSeed.c := DMSeed.c - KonversionVerlust.v;
    DMGen.c := DMGen.c - KonversionVerlust.v;
    DMShoot.c := DMShoot.c - KonversionVerlust.v;
    DMPlant.c := DMPlant.c - KonversionVerlust.v;
    DMRoot.c := fRoot.v * DMPlant.c;

    SumKonversionVerlust.c := KonversionVerlust.v;

  // Dry-matter reduction caused by frost and shading senescence
    if (DMDeadSh.c>0) then begin
      DMPlant.c := DMPlant.c - DMSh.c;
      DMShoot.c := DMShoot.c - DMSh.c;
      DMLeaf.c := max(-DMLeaf.v, DMLeaf.c - DMSh.c);
    end;

    if (DMDeadW.c>0) then begin
      {DMPlant.c := DMPlant.c - DMDeadW.c;
      DMShoot.c := DMShoot.c - ((DMDeadW.c)*(DMShoot.v/DMPlant.v));
      DMLeaf.c := DMLeaf.c - ((DMDeadW.c)*(DMLeaf.v/DMPlant.v));
      DMStem.c := DMStem.c - ((DMDeadW.c)*(DMStem.v/DMPlant.v));
      DMRoot.c := DMRoot.c - ((DMDeadW.c)*(DMRoot.v/DMPlant.v));}
      DMPlant.c := DMPlant.c - DMDeadW.c;
      DMShoot.c := DMShoot.c - DMDeadW.c;
      DMLeaf.c := DMLeaf.c - ((DMDeadW.c)*(DMLeaf.v/DMShoot.v));
      DMStem.c := DMStem.c - ((DMDeadW.c)*(DMStem.v/DMShoot.v));
    end;

    {if (DMDeadN.c > 0) then begin
      DMPlant.c := DMPlant.c - DM_N.c;
      DMShoot.c := DMShoot.c - DM_N.c;
      DMLeaf.c := max(-DMLeaf.v, DMLeaf.c - DM_N.c);
    end;}

    if (DMDeadW.c > 0) then begin
      DMDeadLeafW.c := ((DMDeadW.c)*(DMLeaf.v/DMShoot.v));
      DMDeadStemW.c := ((DMDeadW.c)*(DMStem.v/DMShoot.v));
      end
    else begin
      DMDeadLeafW.c := 0;
      DMDeadStemW.c := 0;
    end;

  // Dry-matter translocation caused by shading senescence
    if (DMDeadSh.c > 0) then
      DMTransLeaf.c := DMShTrans.c {+ DMNTrans.c}
    else
      DMTransLeaf.c := 0;

    DMTrans.c := DMTransLeaf.c + DMTransStem.c;


    DMDead.c := DMDeadW.c + DMDeadSh.c; {+ DMDeadAge.c + DMDeadN.c} // dead dry matter
    C_Dead.c := (DMDead.c * 10) * 0.45;


  // Oil concentration as a function of seed-maturation duration and seed N amount
    if (NSeed.v > 0) then
      Oilconc.v := (Oila.v * DauerEC81_89.v + Oilb.v) * (Oilc.v * NSeed.v + Oild.v)
    else
      Oilconc.v := 0;


  // Ertragsberechnung (mit Harvest-Index; y1.v)
{    if (EC.v >= 88) then begin
      Yield.v := (DMShoot.v / 10) * y1.v;
      Ymax.v := (DMShoot.v / 10) * y1.v;
    end
    else begin
      Yield.v := 0;
      Ymax.v := 0;
    end;}

    if (Globtime.v <= Harvestdate.v) then begin
      if DMShoot_nB_pot.v > 0 then begin
        HI.v := y1.v * (1-0.8*(1-DMShoot_nB.v/DMShoot_nB_pot.v));
        Ymax.v := (DMShoot.v / 10) *  HI.v ;
        end else begin
          HI.v := 0.0;
          Ymax.v := 0.0;
        end;
      Yield.v := DMSeed.v / 10;
 //     OilYield.v := Yield.v * Oilconc.v/100;
      OilYield.v := Ymax.v * Oilconc.v/100;
    end
    else begin
      Yield.v := 0;
      OilYield.v := 0;
    end;


  // N concentration (Nc = optimum N concentration, Ncrit = critical N concentration; W. Weymann dissertation, Chapter 4, Figure 4)
  {Dissertation W. Weymann, 2015: Organ-specific approaches describing crop development of winter oilseed rape under optimal and N-limited conditions (Chapter 3)}
  {Weymann et al. 2016: Organ-specific approaches describing crop growth of winter oilseed rape under optimal and N-limited conditions. European Journal of Agronomy)}

    // Leaves
    if DayofYear.v <= 30 then begin
      NcLeaf_VA.v := NcLeaf.v;
      NcritLeaf_VA.v := NcritLeaf.v;
    end;

    If DMLeaf.v <= 0 then begin
      NcLeaf.v := 0;
      NcritLeaf.v := 0;
    end
    else begin
      If (DayofYear.v <=221) and (DayofYear.v >=60) then begin
        if EC.v < 60 then  begin               // Spring: constant leaf N concentration
          NcLeaf.v := pCnleaf.v;
          NcritLeaf.v := pCncritLeaf.v;
          dNcLeaf.v := 0;
        end
        else  begin   // after BBCH 60
          NcLeaf.v := min(NcLeaf.v, max(0,((0 - pCnLeaf.v)/(90-60))*(EC.v-60)+pCnLeaf.v));
          NcritLeaf.v := min(NcritLeaf.v, max(0,((0 - pCncritLeaf.v)/(90-60))*(EC.v-60)+pCncritLeaf.v));
          dNcLeaf.v := min(NcLeaf.v, max(0,(((0 - pCnLeaf.v)/(90-60))*((DayofYear.v + 1) - 60) + pCnLeaf.v)))-NcLeaf.v;
        end
      end
      else
        if (DayofYear.v >= 30) and (DayofYear.v <= 60) then begin
          NcLeaf.v := ((pCnLeaf.v - NcLeaf_VA.v)/(60-30))*(DayofYear.v - 30) + NcLeaf_VA.v;
          NcritLeaf.v := ((pCncritLeaf.v - NcritLeaf_VA.v)/(60-30))*(DayofYear.v - 30)+NcritLeaf_VA.v;
          dNcLeaf.v := (((pCnLeaf.v - NcLeaf_VA.v)/(60-30))*((DayofYear.v + 1) - 30) + NcLeaf_VA.v)-NcLeaf.v;
        end
        else
            if (NcLeaf.v <= 0) then begin
              NcLeaf.v := min(7,max(0,pCn2leaf.v*DMleaf.v+pCn1leaf.v+DMLeaf.v*pCn2leaf.v));      // Autumn: dilution function
              NcritLeaf.v := min(7,max(0,pCncrit2Leaf.v*DMLeaf.v+pCncrit1Leaf.v+DMLeaf.v*pCncrit2Leaf.v));
              dNcLeaf.v := min(7,max(0,pCn2leaf.v*(DMleaf.v+DMLeaf.c)+pCn1leaf.v+(DMLeaf.v+DMLeaf.c)*pCn2leaf.v)-NcLeaf.v);
            end
            else begin
              NcLeaf.v := min(NcLeaf.v,max(0,pCn2leaf.v*DMleaf.v+pCn1leaf.v+DMLeaf.v*pCn2leaf.v));      // Autumn: dilution function
              NcritLeaf.v := min(NcritLeaf.v,max(0,pCncrit2Leaf.v*DMLeaf.v+pCncrit1Leaf.v+DMLeaf.v*pCncrit2Leaf.v));
              dNcLeaf.v := min(NcLeaf.v,max(0,pCn2Leaf.v*(DMleaf.v+DMLeaf.c)+pCn1leaf.v+(DMLeaf.v+DMLeaf.c)*pCn2leaf.v))-NcLeaf.v;
            end
    end;

    // Stems
    if DayofYear.v <= 30 then begin
      NcStem_VA.v := NcStem.v;
      NcritStem_VA.v := NcritStem.v;
    end;

    if EC.v <= 70 then begin
      NcStem_EC70.v := NcStem.v;
      NcritStem_EC70.v := NcritStem.v;
    end;


    if (DMStem.v > 0) then begin
      if EC.v > 70 then begin
        NcStem.v := max(0.6,((0.6-NcStem_EC70.v)/(90-70))*(EC.v-70)+NcStem_EC70.v);
        NcritStem.v := max(0.6,((0.6-NcritStem_EC70.v)/(90-70))*(EC.v-70)+NcritStem_EC70.v);
        dNcStem.v := max(0.6,(((0.6-NcStem_EC70.v)/(90-70))*(EC.v+DVS_rate.v*19-70)+NcStem_EC70.v))-NcStem.v;
      end
      else begin
        if (DayofYear.v >= 30) and (DayofYear.v <= 60) then begin
          NcStem.v := ((((pCnStem2f.v * ln(DMStem.v) + pCnStem1f.v)))-NcStem_VA.v)/(60-30)*(DayofYear.v - 30) + NcStem_VA.v;
          NcritStem.v := ((((pCncritStem2f.v * ln(DMStem.v) + pCncritStem1f.v)))-NcritStem_VA.v)/(60-30)*(DayofYear.v - 30) + NcritStem_VA.v;
          dNcStem.v := (((((pCnStem2f.v * ln(DMStem.v) + pCnStem1f.v))) - NcStem_VA.v)/(60-30)*((DayofYear.v + 1) - 30) + NcStem_VA.v) -NcStem.v;
        end
        else begin
          if (DayofYear.v <= 30) or ((DayofYear.v >= 217) and (EC.v < 30)) then begin
            NcritStem.v := min(pCncritStem1h.v, pCncritStem2h.v * ln(max(0.5, DMStem.v)) + pCncritStem1h.v);
            NcStem.v := max(0.5,max(NcritStem.v, pCnStem2h.v * ln(max(0.5, DMStem.v)) + pCnStem1h.v));
            dNcStem.v := max(0.5,min(pCncritStem1h.v,(pCnStem2h.v * ln(DMStem.v+DMStem.c) + pCnStem1h.v))-NcStem.v);
          end
          else begin
            NcStem.v := max(0.6,pCnStem2f.v * ln(DMStem.v) + pCnStem1f.v);
            NcritStem.v := max(0.6,pCncritStem2f.v * ln(DMStem.v) + pCncritStem1f.v);
            dNcStem.v := max(0.6,(pCnStem2f.v * ln(DMStem.v+DMStem.c) + pCnStem1f.v))-NcStem.v;
          end
        end;
      end;
    end
    else
      if (DMStem.c > 0) then begin
        NcStem.v := min(6,pCnStem1h.v);
        NcritStem.v := min(6,pCncritStem1h.v);
      end
      else begin
        NcStem.v := 0;
        NcritStem.v := 0;
      end;

    // Pods
    if (DMGen.v + DMGen.c > 0) and (DMGen.v > 0) then begin
      NcGen.v := max(0,pCnPod2.v * ln(DMGen.v) + pCnPod1.v);
      NcritGen.v := max(0,pCncritPod2.v * ln(DMGen.v) + pCncritPod1.v);
      dNcGen.v   := max(0,(pCnPod2.v * ln(DMGen.v+DMGen.c) + pCnPod1.v))-NcGen.v;
    end
    else begin
      if (DMGen.c >0) then begin
        NcGen.v := pCnPod1.v;
        NcritGen.v := 0;
      end
      else begin
        NcGen.v := 0;
        NcritGen.v := 0;
        dNcGen.v := 0;
      end;
    end;

    // Roots
    if DayofYear.v <= 30 then begin
      NcRoot_VA.v := NcRoot.v;
      NcritRoot_VA.v := NcritRoot.v;
    end;

    if EC.v <= 70 then begin
      NcRoot_EC70.v := NcRoot.v;
      NcritRoot_EC70.v := NcritRoot.v;
    end;

    If DMRoot.v <= 0 then begin
      if (DMRoot.c > 0) then begin
        NcRoot.v := min(5.5,pCnRoot1h.v);
        NcritRoot.v := min(5.5,pCncritRoot1h.v);
      end
      else begin
        NcRoot.v := 0;
        NcritRoot.v := 0;
      end;
    end
    else begin
      if EC.v > 70 then begin
        NcRoot.v := max(0.8,((0.8 - NcRoot_EC70.v)/(90-70)) * (EC.v - 70) + NcRoot_EC70.v);
        NcritRoot.v := max(0.8,((0.8 - NcritRoot_EC70.v)/(90-70)) * (EC.v-70) + NcritRoot_EC70.v);
        dNcRoot.v := max(0.8,(((0.8 - NcRoot_EC70.v)/(90-70)) * (EC.v+DVS_rate.v*19-70) + NcRoot_EC70.v))-NcRoot.v;
      end
      else
        if (DayofYear.v > 60) then begin
          NcRoot.v := min(NcRoot.v,max(0,pCnRoot2f.v*DMRoot.v+pCnRoot1f.v+DMRoot.v*pCnRoot2f.v));
          NcritRoot.v := min(NcritRoot.v,max(0,pCncritRoot2f.v*DMRoot.v+pCncritRoot1f.v+DMRoot.v*pCncritRoot2f.v));
          dNcRoot.v := min(NcRoot.v,max(0,pCnRoot2f.v*(DMRoot.v+DMRoot.c)+pCnRoot1f.v+(DMRoot.v+DMRoot.c)*pCnRoot2f.v))-NcRoot.v;
        end
        else
          if (DayofYear.v >= 30) and (DayofYear.v <= 60) then begin
            NcRoot.v := ((pCnRoot1f.v - NcRoot_VA.v)/(60-30))*(DayofYear.v - 30) + NcRoot_VA.v;
            NcritRoot.v := ((pCncritRoot1f.v - NcritRoot_VA.v)/(60-30))*(DayofYear.v - 30)+NcritRoot_VA.v;
            dNcRoot.v := (((pCnRoot1f.v - NcRoot_VA.v)/(60-30))*((DayofYear.v + 1) - 30) + NcRoot_VA.v)-NcRoot.v;
          end
          else begin
            NcRoot.v := max(1,pCnRoot2h.v * ln(DMRoot.v) + pCnRoot1h.v);
            NcritRoot.v := max(1,pCncritRoot2h.v * ln(DMRoot.v) + pCncritRoot1h.v);
            dNcRoot.v := max(1,pCnRoot2h.v * ln(DMRoot.v+DMRoot.c) + pCnRoot1h.v)-NcRoot.v;
          end
    end;


  // Calculate organ-specific NNI from the difference between optimum and critical N concentration
    {NNIi differs from the NNI of Justes et al. (1994), but provides the best available description of each organ's N status from the dilution-function data.}
    if fNSensOption = N_unlimited then begin
      NNILeaf.v := 1;
      NNIStem.v := 1;
      NNIGen.v := 1;
      NNIRoot.v := 1;
   end
    else begin
      if (NcLeaf.v <= NcritLeaf.v) and (NcLeaf.v > 0) and (NcritLeaf.v > 0) then
        NNILeaf.v := 0//minNNI.v
      else
        if (NcLeaf.v > 0) and (NcritLeaf.v > 0) then
          NNILeaf.v := max(0 {minNNI.v},min(1,(NLeaf.v-(DMLeaf.v*NcritLeaf.v/100))/((DMLeaf.v*NcLeaf.v/100)-(DMLeaf.v*NcritLeaf.v/100))))
        else
          NNILeaf.v := 1;

      if (NcStem.v <= NcritStem.v) and (NcStem.v > 0) and (NcritStem.v > 0) then
        NNIStem.v :=0 // minNNI.v
      else
        if (NcStem.v > 0) and (NcritStem.v > 0) and (NStem.v > 0) then
          NNIStem.v := max(0{minNNI.v}, min(1,(NStem.v-(DMStem.v*NcritStem.v/100))/((DMStem.v*NcStem.v/100)-(DMStem.v*NcritStem.v/100))))
        else
          NNIStem.v := 1;

      if (NcGen.v <= NcritGen.v) and (NcGen.v > 0) and (NcritGen.v > 0) then
        NNIGen.v := 0
      else
        if ((NcGen.v > 0) and (NcritGen.v > 0) and (NGen.v > 0)) and (EC.v > 70) then
          NNIGen.v := max(0{minNNI.v}, min(1,(NGen.v-(DMGen.v*NcritGen.v/100))/((DMGen.v*NcGen.v/100)-(DMGen.v*NcritGen.v/100))))
        else
          NNIGen.v := 1;

      if (NcRoot.v <= NcritRoot.v) and (NcRoot.v > 0) and (NcritRoot.v > 0) then
        NNIRoot.v := 0//minNNI.v
      else
        if (NcRoot.v > 0) and (NcritRoot.v > 0) and (NRoot.v > 0) and (DMRoot.v > 0) then
          NNIRoot.v := max(0{minNNI.v},min(1,(NRoot.v-(DMRoot.v*NcritRoot.v/100))/((DMRoot.v*NcRoot.v/100)-(DMRoot.v*NcritRoot.v/100))))
        else
          NNIRoot.v := 1;
    end;


  // Calculate specific areas and area indices

  // SLA
    {if (EC.v <= 30) then
      SLAf.v := actSLA.v;}

    if (EC.v < 30) then      // Variable autumn SLA with a linear dependence on thermal time since sowing
      actSLA.v := max (SLAmin.v, min(SLAmax.v, SLAhst.v*TempsumAussaat.v+SLAhin.v))
    else
        if (EC.v <= 64) then // Dissertation W. Weymann, Chapter 4, Figure 3
        actSLA.v := min(500,max(actSLA.v,fSLAspring.v * LAIShoot.v + SLAspring.v))
        else
        actSLA.v := actSLA.v;

  //SPA (specific pod area)
    if (EC.v >= 51) and (EC.v <= 70) then
      if (EC.v <= 65) then
        actSPA.v := ((SPAmax.v-0)/(65-51))*(EC.v - 51) + 0
      else
        actSPA.v := max(0, SPAmax.v * exp(SPA_exp.v * EC.v))
    else
      actSPA.v := 0;

  // LAI
    if (DMLeaf.c < 0) then
      LAILeaf.c := DMLeaf.c * avSLA.v/10000
    else
      {if (EC.v < 30) then
        LAILeaf.c :=  DMLeaf.c*actSLA.v/10000
      else}
        LAILeaf.c :=  ((DMLeaf.v + DMLeaf.c) * actSLA.v/10000)-LAILeaf.v;

  // SAI (stem area index)
    if (EC.v < 80) then
      LAIStem.c :=  DMStem.c*SSA.v/10000
    else begin
      SAI.v := (((-0.01)-0)/(90-80))*(EC.v-80)+0;
      LAIStem.c := max(-LAIStem.v, (SAI.v * TempSumSeed.v + maxLAIStem.v)-LAIStem.v);
    end;

  // PAI (pod area index)
    if (EC.v < 80) then
      LAIGen.c := DMGen.c * actSPA.v / 10000
    else begin
      {LAIGen.c := max(-LAIGen.v,PAI.v * (maxLAIGen.v - (DMGen.c * actSPA.v / 10000)));}
  // LAIGen.c is the slope of the linear decline in LAIGen from maxLAIGen to zero as thermal time accumulates
      PAI.v := (((-0.01)-0)/(90-80))*(EC.v-80)+0;
      LAIGen.c := max(-LAIGen.v, (PAI.v * TempSumSeed.v + maxLAIGen.v)-LAIGen.v);
    end;


  // Calculate organ N amounts from organ dry matter and N concentration
    // Leaves
    if DMLeaf.v <= 0 then
      NLeaf.c := 0
    else
      if DMLeaf.c > 0 then
        NLeaf.c := max(0,(DMLeaf.c * (NcLeaf.v+DMLeaf.v*dNcLeaf.v/DMLeaf.c) / 100))
      else if DMLeaf.c < 0 then
        NLeaf.c := DMLeaf.c * NLeaf.v / DMLeaf.v
      else
        NLeaf.c := 0;

    // N loss through frost and shading senescence
    if DMDeadW.c > 0 then
      NDeadW.c := (DMDeadLeafW.c * NcLeaf_act.v /100) + (DMDeadStemW.c * NcStem_act.v /100) + (DMDeadRootW.c * NcRoot_act.v/100) // N loss through frost senescence
    else
      NDeadW.c := 0;

    if (NLeaf.c < 0) and (DMDeadW.c = 0) then
      NDeadSh.c := -NLeaf.c * (1-pCnTrans.v)
    else
      NDeadSh.c := 0;

    NDead.c := NDeadW.c + NDeadSh.c {+ NDeadAge.c};
    N_Dead.c := NDead.c * 10;

    // Stems
    if DMStem.c >= 0 then
      NStem.c := (DMStem.c * NcStem.v+DMStem.v*dNcStem.v) / 100
    else
      if (DMStem.c < 0) then begin
        if DMstem.v > 0 then
        NStem.c := DMStem.c * NStem.v / DMStem.v;
      end;
    // Pods
    if DMGen.c > 0 then begin
      NGen.c := max(0,(DMGen.c * (NcGen.v+DMGen.v*dNcGen.v/DMGen.c) / 100));
      NSeed.v := (DMSeed.v * pCnSeed.v)/100;
      NPodWall.v := max(0.2*NGen.v,NGen.v - NSeed.v);
      NSeed.v := NGen.v - NPodWall.v;
    end
    else if (DMGen.c < 0) and (DMGen.v > 0) then begin
      NGen.c := DMGen.c * NGen.v / DMGen.v;
      NSeed.v := (DMSeed.v * pCnSeed.v)/100;
      NPodWall.v := max(0.2*NGen.v,NGen.v - NSeed.v);
      NSeed.v := NGen.v - NPodWall.v;
    end
    else begin
      NGen.c := 0;
      NSeed.v := 0;
      NPodWall.v := 0;
    end;

    // Roots
    if DMRoot.v <= 0 then
      NRoot.c := 0
    else
      if DMRoot.c > 0 then
        NRoot.c := (DMRoot.c * (NcRoot.v+DMRoot.v*dNcRoot.v/DMRoot.c) / 100)
      else if DMRoot.c < 0 then
        NRoot.c := DMRoot.c * NRoot.v / DMRoot.v
      else
        NRoot.c := 0;


  // N-Translokation
  // Translocate 65% of the N currently present in leaves

     {Malagoli et al. 2005: Dynamics of Nitrogen Uptake and Mobilization in
     Field-grown Winter Oilseed Rape (Brassics napus) from Stem Extension
     to Harvest. I. Global N Flows between Vegetative and Reproductive Tissues
     in Relation to Leaf Fall and their Residual N. Annals of Botany 95, 853-861.}

    if (DMDeadW.c = 0) and (NLeaf.c < 0) then
      NTransLeaf.c := min(NLeaf.v,-NLeaf.c) * pCnTrans.v
    else
      NTransLeaf.c := 0;

    if (NStem.c < 0) and (DMDeadW.c = 0) then
      NTransStem.c := min(NStem.v, -NStem.c)
    else
      NTransStem.c := 0;

    if (NRoot.c < 0) and (DMDeadW.c = 0) then
      NTransRoot.c := min(NRoot.v,-NRoot.c)
    else
      NTransRoot.c := 0;

    potNTrans.c := NTransLeaf.c + NTransStem.c + NTransRoot.c;

   // N pool and N translocation into pods
      if (NGen.c <= potNTrans.c) then
        if (EC.v < 80) then begin
          potNPool.c := potNTrans.c - NGen.c;       // Create an N pool for N translocated before pod development; the physical location of this pool remains unspecified
          NPool.c := max(0,min((((DMStem.v*6/100)-strNStem.v)+((DMRoot.v*5.5/100)-strNRoot.v))-NPool.v,potNPool.c));
          NTrans.c := max(0,NGen.c);                  // N amount translocated into pods
          NDead.c := NDead.c + (potNPool.c - NPool.c);
        end
        else begin
          potNPool.c := 0;
          NPool.c := 0;
          NTrans.c := NGen.c;
          NDead.c := potNTrans.c - NTrans.c;
        end
      else begin
        potNPool.c := 0;
        NTrans.c := potNTrans.c;
        NPool.c := min(0,max(-NPool.v,-(NGen.c - NTrans.c)));   // Empty the N pool when pod N increases strongly
        NTrans.c := max(0,min(NGen.c,NTrans.c - NPool.c));      // N amount translocated into pods
      end;

  // N pool in stems and roots
    poolNStem.c := max(-poolNStem.v,min((DMStem.v * 6 / 100)-NStem.v, NPool.c));
    poolNRoot.c := NPool.c - poolNStem.c;

  // Structural N in stems and roots
    strNStem.c := max(-strNStem.v,NStem.c);
    strNRoot.c := max(-strNRoot.v,NRoot.c);



  // N demand and compensation for N deficits and surpluses
   { See: Compensation of N deficits and surpluses.pdf }

  // N demand for growth (NDemandGrowth) and compensation of N deficits (NDemandDeficit)
    NDemandGrowth.v := max(0,max(0,NLeaf.c) + max(0,NStem.c) + max(0,NRoot.c) + max(0,(NGen.c - NTrans.c)));
    NDemandDeficit.v := (DMLeaf.v * NcLeaf.v/100 - NLeaf.v)
                          + (DMGen.v * NcGen.v/100 - NGen.v)
                          + (DMStem.v * NcStem.v/100 - strNStem.v)
                          + (DMRoot.v * NcRoot.v/100 - strNRoot.v);

    NDemandDeficitLeaf.v := (DMLeaf.v * NcLeaf.v/100 - NLeaf.v);
    NDemandDeficitStem.v := (DMStem.v * NcStem.v/100 - strNStem.v);
    NDemandDeficitRoot.v := (DMRoot.v * NcRoot.v/100 - strNRoot.v);
    NDemandDeficitGen.v := (DMGen.v * NcGen.v/100 - NGen.v);

  // Potential N uptake
    NUptakeRate_pot.v := max(0,NDemandGrowth.v + NDemandDeficit.v);

    NUptake_pot.c := max(0,NUptakeRate_pot.v);
  end

  else begin
    for I := 0 to StateStrList.Count - 1 do begin
      StateVar := TState(StateStrList.objects[i]);
      StateVar.c := 0.0;
    end;
  end;
end;

procedure TOSRGrowth.Integrate;
var
  NDemandDeficitNeg, NDemandDeficitPos: real;
begin
  {if NUptake_act.v > NUptake_pot.v then NUptakeRate_pot.v := NUptakeRate_pot.v - (NUptake_act.v - NUptake_pot.v);}
  if (SoilNitrogenMod <> nil) and (SoilNitrogenMod is TSoilNitrogenUp)
  then begin
    NDemandDeficitNeg := max(0,NLeaf.v - DMLeaf.v * NcLeaf.v/100)+max(0,strNStem.v - DMStem.v * NcStem.v/100)
                         +max(0,strNRoot.v - DMRoot.v * NcRoot.v/100)+max(0,NGen.v - DMGen.v * NcGen.v/100);
    NDemandDeficitPos := max(0,DMLeaf.v * NcLeaf.v/100-NLeaf.v)+max(0,DMStem.v * NcStem.v/100-strNStem.v)
                         +max(0,DMRoot.v * NcRoot.v/100-strNRoot.v)+max(0,DMGen.v * NcGen.v/100-NGen.v);
    NSupply.v := TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 + NDemandDeficitNeg + NPool.v + NPool.c;
    if (NSupply.v < NDemandGrowth.v) and (fNSensOption = N_sensitiv) then begin
      if NLeaf.c >0 then NLeaf.c := NLeaf.c * NSupply.v/NDemandGrowth.v;
      if strNStem.c >0 then strNStem.c := strNStem.c * NSupply.v/NDemandGrowth.v;
      if strNRoot.c >0 then strNRoot.c := strNRoot.c * NSupply.v/NDemandGrowth.v;
      if NGen.c >0 then NGen.c := max(0,NSupply.v - (max(0,NLeaf.c)) - (max(0,strNStem.c)) - (max(0,strNRoot.c)) + NTrans.c);
      if (NDemandDeficitNeg > 0) then begin
        NLeaf.c := NLeaf.c - max(0,(NLeaf.v - DMLeaf.v * NcLeaf.v/100));
        strNStem.c := strNStem.c - max(0,(strNStem.v - DMStem.v * NcStem.v/100));
        strNRoot.c := strNRoot.c - max(0,(strNRoot.v - DMRoot.v * NcRoot.v/100));
        NGen.c := NGen.c - max(0,(NGen.v - DMGen.v * NcGen.v/100));
      end;
      NPool.c := - NPool.v;
      PoolNStem.c := -PoolNStem.v;
      PoolNRoot.c := - PoolNRoot.v;
    end
    else begin
      if ((NSupply.v-NDemandGrowth.v) > NDemandDeficit.v) then begin
        NLeaf.c := NLeaf.c + max(0,DMLeaf.v * NcLeaf.v/100 - NLeaf.v);
        strNStem.c := strNStem.c + max(0,DMStem.v * NcStem.v/100 - strNStem.v);
        strNRoot.c := strNRoot.c + max(0,DMRoot.v * NcRoot.v/100 - strNRoot.v);
        NGen.c := NGen.c + max(0,DMGen.v * NcGen.v/100 - NGen.v);
        if (NSupply.v - (NPool.v + NPool.c)-NDemandGrowth.v) > NDemandDeficit.v then begin
          if NDemandDeficitNeg > 0 then begin
            NLeaf.c := NLeaf.c + min(0,DMLeaf.v * NcLeaf.v/100 - NLeaf.v) + max(0,(NLeaf.v - DMLeaf.v * NcLeaf.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
            strNStem.c := strNStem.c + min(0,DMStem.v * NcStem.v/100 - strNStem.v) + max(0,(strNStem.v - DMStem.v * NcStem.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
            strNRoot.c := strNRoot.c + min(0,DMRoot.v * NcRoot.v/100 - strNRoot.v) + max(0,(strNRoot.v - DMRoot.v * NcRoot.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
            NGen.c := NGen.c + min(0,DMGen.v * NcGen.v/100 - NGen.v) + max(0,(NGen.v - DMGen.v * NcGen.v/100))/NDemandDeficitNeg*(NSupply.v - (NPool.v + NPool.c) - NDemandGrowth.v - NDemandDeficitPos);
          end;
        end
        else {The pool is required for compensation.}
          if (PoolNStem.v+PoolNRoot.v) > 0 then begin
            NPool.c := NPool.c + TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 - NDemandGrowth.v - NDemandDeficit.v;
            PoolNStem.c := PoolNStem.c + (TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 - NDemandGrowth.v - NDemandDeficit.v)*PoolNStem.v/(PoolNStem.v+PoolNRoot.v);
            PoolNRoot.c := PoolNRoot.c + (TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10 - NDemandGrowth.v - NDemandDeficit.v)*PoolNRoot.v/(PoolNStem.v+PoolNRoot.v);
          end;
      end
      else if NDemandDeficitPos > 0 then begin
        NLeaf.c := NLeaf.c - max(0,(NLeaf.v - DMLeaf.v * NcLeaf.v/100)) - min(0,NLeaf.v - DMLeaf.v * NcLeaf.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        strNStem.c := strNStem.c - max(0,(strNStem.v - DMStem.v * NcStem.v/100)) - min(0,strNStem.v - DMStem.v * NcStem.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        strNRoot.c := strNRoot.c - max(0,(strNRoot.v - DMRoot.v * NcRoot.v/100)) - min(0,strNRoot.v - DMRoot.v * NcRoot.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        NGen.c := NGen.c - max(0,(NGen.v - DMGen.v * NcGen.v/100)) - min(0,NGen.v - DMGen.v * NcGen.v/100)/NDemandDeficitPos*(NSupply.v-NDemandGrowth.v);
        NPool.c := - NPool.v;
        PoolNStem.c := -PoolNStem.v;
        PoolNRoot.c := - PoolNRoot.v;
      end;
    end;
    NUptake_act.c := TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10;
  end
  else NUptake_act.c := NUptakeRate_pot.v;
  LAIShoot.c := LAILeaf.c + LAIStem.c + LAIGen.c;
  NStem.c := strNStem.c + poolNStem.c;
  NRoot.c := strNRoot.c + poolNRoot.c;
  if (EC.v >= 90) then begin
    NLeaf.c := 0;
    NStem.c := 0;
    NGen.c := 0;
    NRoot.c := 0;
    NShoot.c := 0;
  end;
  NShoot.c := NGen.c + NLeaf.c + NStem.c;
  NPlant.c := min(NUptake_act.c,NGen.c + NLeaf.c + NStem.c + NRoot.c);
  NBalance.c := max(0,NPlant.c + NDead.c);
  inherited;

  if (LAIShoot.v + LAIShoot.c >= 2.0) and (LAIShoot.v < 2.0) then
    EC_act.v := EC.v;
{  if (NUptake_act.v>0) then
    NNI.v := min(1,(SoilNitrogenMod.ActNUptake.v / NUptakeRate_pot.v ))
  else NNI.v := 1;
  if fNSensOption = N_unlimited then NNI.v := 1;}


  if DMLeaf.v >0 then avSLA.v := LAILeaf.v/DMLeaf.v*10000 else avSLA.v := 0;
  if DMGen.v > 0 then avSPA.v := LAIGen.v / DMGen.v * 10000 else avSPA.v := 0;


// Harvest index
 // if Yield.v > 0 then HI.v := Yield.v*10 / DMShoot.v;


// N-Harvest-Index
  if (NSeed.v > 0) then
    NHI.v := NSeed.v / NShoot.v;


// Nitrogen Use Efficiency
  if (Yield.v > 0) then begin
    if NUptake_act.v > 0 then

    NUE.v := Yield.v*10 / NUptake_act.v else
    NUE.v := 0.0;
  end;


// Calculate current N concentration
  if (DMLeaf.v > 0) then
    NcLeaf_act.v := NLeaf.v/DMLeaf.v*100
  else
    NcLeaf_act.v := 0;

  if (DMStem.v > 0) then
    NcStem_act.v := NStem.v/DMStem.v*100
  else
    NcStem_act.v := 0;

  if (DMGen.v > 0) then
    NcGen_act.v := NGen.v/DMGen.v*100
  else
    NcGen_act.v := 0;

  if (DMRoot.v > 0) then
    NcRoot_act.v := NRoot.v/DMRoot.v*100
  else
    NcRoot_act.v := 0;


  DMShoot_vW.c := DMLeaf.c + DMStem.c + DMGen.c;

// Calculate the N-deficit factor to identify periods of N deficiency
  if (NDemandGrowth.v > 0) then
    N_Def.v := min(1,(TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10)/NDemandGrowth.v)
  else
    N_Def.v := 1;

  if Assigned(SoilMinMod) and (SoilMinMod is TAbstractSoilMin) and not harvested then TAbstractSoilMin(SoilMinMod).AddResidues(C_Dead.c,N_Dead.c);


  if (EC.v >= 90) and (DateHarvestWasSet = false) then begin
    HarvestDate.v := GlobTime.v;
    DateHarvestWasSet := true;
  end;

  //N_Residues.v := 0.21*NShoot.v;          // dneukam: auskommentiert am 26.10.21
  //C_Residues.v := N_Residues.v * 95;
  N_Residues.v := NRoot.v + NStem.v + NLeaf.v+NPodWall.v;   // added by dneukam on 2021-10-26
  C_Residues.v := (DMRoot.v + DMStem.v + DMLeaf.v + DMPodWall.v)*0.45 ;

end;

procedure TOSRGrowth.setDevelopmentModel(AModel: TDevelopmentOSR);
begin
  fDevelopmentModel := AModel;
  EC.Search := false;
  EC.f_v := @DevelopmentModel.EC.fv;
  EC.Source := '['+DevelopmentModel.Name+']';
  DVS.Search := false;
  DVS.f_v := @DevelopmentModel.DVS.fv;
  DVS.Source := '['+DevelopmentModel.Name+']';
  DVS_rate.Search := false;
  DVS_rate.setPointer(@DevelopmentModel.DVS.c);
  DVS_rate.Source := '['+DevelopmentModel.Name+']';
end;


function TOSRGrowth.getExtCoeffPAR: real;     // Function for calculating the extinction coefficient
begin
  if LAIShoot.v < LAIcrit_exk.v then
    result := exk.v + (exk_0.v-exk.v)*(LAIcrit_exk.v-LAIShoot.v)/LAIcrit_exk.v
  else
    result := exk.v;
end;

function TOSRGrowth.GetLAI:THumeNumEntity;
begin
  result := LAIShoot;
end;

function TOSRGrowth.GetCropHeight:THumeNumEntity;
begin
  result := CropHeight;
end;

{procedure TOSRGrowth.SetCropHeight(NewCropHeight:THumeNumEntity);
begin
  p_CropHeight := NewCropHeight;
end;

procedure TOSRGrowth.SetLai(NewLAI:THumeNumEntity);
begin
  p_LAI := NewLAI;
end;}

function TOSRGrowth.GetNUptakeRate:THumeNumEntity;
begin
  result := NUptakeRate_pot;
end;


function TOSRGrowth.GetWLD(Index:Integer):THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then
    result := RootModel.effWLD_Arr[Index]
  else
    result := DummyVar;
end;

function TOSRGrowth.GetSumRootLength:THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then
    result := RootModel.SRL
  else
    result := DummyVar;
end;

function TOSRGrowth.GetSumRootLength_eff:THumeNumEntity;
begin
  if withRoots and (RootModel <> nil)
  then
    result := RootModel.SRL_eff
  else
    result := DummyVar;
end;


procedure TOSRGrowth.SetSowingDate(NewSowingDate: real);

begin
  inherited;
end;

procedure TOSRGrowth.setNextCrop(NextCrop:TAbstractplant);
begin
  inherited;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TOSRGrowth]);
{$ENDIF}
end;

end.
