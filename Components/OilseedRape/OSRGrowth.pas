/// <summary>
/// Module for growth, carbon and nitrogen partitioning of oilseed rape crop
/// Authors: Wiebke Weymann, Ulf Böttcher &amp; Agronomy Group, University of Kiel
/// <References>
/// <item> Weymann, W., Sieling, K., Kage, H., 2017. Organ-specific approaches describing crop growth of winter oilseed rape under optimal and N-limited conditions.
/// European Journal of Agronomy 82, 71–79. https://doi.org/10.1016/j.eja.2016.10.005</item>
///  <item> Böttcher, U., Weymann, W., Pullens, J.W.M., Olesen, J.E., Kage, H., 2020. Development and evaluation of HUME-OSR:
/// A dynamic crop growth model for winter oilseed rape. Field Crops Research 246, 107679. https://doi.org/10.1016/j.fcr.2019.107679 </item>
/// </References>
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

TLAIOption = (InternLAI,ExternLAI);
TDMOption = (InternDM,ExternDM);
TInitOption = (DMCritInit,LAIInit);
TNSensOption = (N_sensitiv,N_unlimited);
TDroughtOption = (DroughtImpact, NoDroughtImpact);

TOSRGrowth = class(TAbstractPlant)

private
  DateHarvestWasSet : boolean;
  StateVar : TState;
  avs_day : integer;
  Par_arr : array[1..MaxParDays] of real;
    procedure CalcTempSums;
    procedure InitAfterEmergence;
    procedure CalcRadiationUptake;
    procedure CalcLUE;
    procedure CalcRootFraction;
    procedure CalcShootRootGrowth;
    procedure CalcMaintainableLAI(var LAIm_ave: Double);
    procedure CalculateOrganNuptakerates;
    procedure CalculateNTranslocation;
    procedure CalculateNDemandNDeficiency;
    procedure CalculateIntermediateVariables;
    procedure CalcConversionLosses;
    procedure CalcDMLossFrostShading;

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
  /// <summary>Photosynthetically active radiation [W/m²]</summary>
  PARRad : TVar;
  /// <summary>Photosynthesis response factor derived from temperature</summary>
  fT : TVar;
  /// <summary>Absorbed radiation [MJ]</summary>
  Q : TVar;
  /// <summary>Radiation absorbed by leaves</summary>
  QLeaf : TVar;
  /// <summary>Radiation absorbed by pods</summary>
  QGen : TVar;
  /// <summary>Transmission coefficient during pod development</summary>
  Transkoeff : TVar;
  /// <summary>Fraction of absorbed radiation []</summary>
  fInt: TVar;
  /// <summary>Fraction of radiation absorbed by leaves</summary>
  fIntLeaf : TVar;
  /// <summary>Fraction of radiation absorbed by pods</summary>
  fIntGen : TVar;
  /// <summary>Temperature minus base temperature [°C]</summary>
  Teff : TVar;
  /// <summary>Root growth fraction []</summary>
  fRoot: TVar;
  /// <summary>Maximum root growth fraction</summary>
  maxfRoot : TVar;
  /// <summary>Leaf growth fraction</summary>
  fBl : TVar;
  /// <summary>Leaf growth fraction at BBCH 51</summary>
  fBl_EC51 : TVar;
  /// <summary>Stem growth fraction</summary>
  fSt : TVar;
  /// <summary>Pod growth fraction</summary>
  fGen : TVar;
  /// <summary>Pod-wall fraction of total generative growth</summary>
  fPW : TVar;
  /// <summary>Seed growth fraction within the pod</summary>
  fSeedGen : TVar;
  /// <summary> Seed starch fraction of total seed growth</summary>
  fSeedStarch : TVar;
  /// <summary>Seed oil fraction of total seed growth</summary>
  fSeedOil : TVar;
  fSum : TVar;

  /// <summary>fraction of NNI related to leaves</summary>
  fNNILeaf : TVar;

  /// <summary>fraction of NNI related to stems</summary>
  fNNIStem : TVar;

  /// <summary>fraction of NNI related to generative organs</summary>
  fNNIGen : TVar;

  /// <summary>fraction of NNI related to roots</summary>
  fNNIRoot : TVar;
  /// <summary>Temperature below zero [°C]</summary>
  Tminus : TVar;
  /// <summary>Leaf N concentration [%]</summary>
  NcLeaf : TVar;
  /// <summary>Leaf N concentration at the beginning of the growing season [%]</summary>
  NcLeaf_VA : TVar;

  /// <summary>Stem N concentration [%]</summary>
  NcStem : TVar;
  /// <summary>Stem N concentration at the beginning of the growing season [%]</summary>
  NcStem_VA : TVar;
  /// <summary>Stem N concentration at BBCH 70 [%]</summary>
  NcStem_EC70 : TVar;
  /// <summary>Generative-organ N concentration [%]</summary>
  NcGen : TVar;
  /// <summary>Root N concentration [%]</summary>
  NcRoot : TVar;
  /// <summary>Root N concentration at BBCH 70 [%]</summary>
  NcRoot_EC70 : TVar;
  /// <summary>Leaf N concentration at BBCH 70 [%]</summary>
  NcLeaf_EC70 : TVar;
  /// <summary>Potential N uptake rate g/m²*d</summary>
  NUptakeRate_pot : TVar;
  /// <summary>Nitrogen Nutrition Index</summary>
  NNI: TVar;
  /// <summary>Crop height</summary>
  CropHeight : TVar;
  /// <summary>LAI at BBCH 70</summary>
  LAILeaf_EC70 : TVar;
  /// <summary>Specific leaf area [cm²/g]</summary>
  actSLA : TVar;
  avSLA: TVar;
  /// <summary>Specific pod area [cm²/g]</summary>
  actSPA : TVar;

  /// <summary>Average specific pod area [cm²/g]</summary>
  avSPA : TVar;
  /// <summary>Radiation-use efficiency expressed as dry matter produced per unit of absorbed radiation [g/MJ]</summary>
  LUE : TVar;
  /// <summary>Radiation-use efficiency of pods</summary>
  LUEGen : TVar;
  /// <summary>Factor used to adjust LUE for CO2 effects</summary>
  CO2_factor :TVar;
  /// <summary>Slope of the allometric function</summary>
  g : TVar;
  /// <summary>Intercept of the allometric function</summary>
  h : TVar;
  /// <summary>Maximum maintainable LAI at the available radiation [m²/m²]</summary>
  LAIm : TVar;
  /// <summary>Temperature factor for maintenance respiration used to calculate PARm</summary>
  fTm : TVar;
  fTSen : TVar;
  /// <summary>Shading-senescence factor</summary>
  fSen_sh: TVar;
  /// <summary>Simulation time at emergence</summary>
  Auflauf : TVar;
  /// <summary>Temperature-corrected absorbed radiation [MJ]</summary>
  QT : TVar;
  /// <summary>PAR extinction coefficient: exk or a variable value when LAI is below LAIcrit_exk</summary>
  act_k : TVar;
  /// <summary>Leaf extinction coefficient</summary>
  act_k_Leaf : TVar;
  /// <summary>Pod extinction coefficient</summary>
  act_k_Gen : TVar;
  DummyVar : TVar;
  /// <summary>BBCH stage at which LAIShoot equals 2.0</summary>
  EC_act : TVar;
  /// <summary>Maximum GAI</summary>
  maxGAI : TVar;
  /// <summary>Maximum PAI</summary>
  maxLAIGen : TVar;
  /// <summary>Maximum SAI</summary>
  maxLAIStem : TVar;
  dNcLeaf : TVar;
  dNcStem : TVar;
  dNcRoot : TVar;
  dNcGen : TVar;

  /// <summary>Critical N concentration of leaves [%]</summary>
  NcritLeaf : TVar;

  /// <summary>Actual N concentration of leaves [%]</summary>
  NcLeaf_act : TVar;
  /// <summary>Critical N concentration of stems [%]</summary>
  NcritStem : TVar;
  /// <summary>Actual N concentration of stems [%]</summary>
  NcStem_act : TVar;
  /// <summary>Critical N concentration of generative organs [%]</summary>
  NcritGen : TVar;
  /// <summary>Actual N concentration of generative organs [%]</summary>
  NcGen_act : TVar;
  /// <summary>Critical N concentration of roots [%]</summary>
  NcritRoot : TVar;
  /// <summary>Critical N concentration of roots at the beginning of the growing season [%]</summary>
  NcritRoot_VA : TVar;
  /// <summary>Actual N concentration of roots [%]</summary>
  NcRoot_act : TVar;
  /// <summary>Actual N concentration of roots at the beginning of the growing season [%]</summary>
  NcRoot_VA : TVar;
  /// <summary>Critical N concentration of leaves at the beginning of the growing season [%]</summary>
  NcritLeaf_VA : TVar;
  /// <summary>Critical N concentration of stems at the beginning of the growing season [%]</summary>
  NcritStem_VA : TVar;

  /// <summary>Critical N concentration of stems at BBCH 70 [%]</summary>
  NcritStem_EC70 : TVar;
  /// <summary>Critical N concentration of generative organs at BBCH 70 [%]</summary>
  NcritRoot_EC70 : TVar;

  /// <summary>Nitrogen Nutrition Index of leaves</summary>
  NNILeaf : TVar;
  /// <summary>Nitrogen Nutrition Index of stems</summary>
  NNIStem : TVar;
  /// <summary>Nitrogen Nutrition Index of generative organs</summary>
  NNIGen : TVar;
  /// <summary>Nitrogen Nutrition Index of roots</summary>  
  NNIRoot : TVar;

  /// <summary>10 day average of incident PAR [W/m²]</summary>
  PARav : Tvar;
  /// <summary>Pod area index [m²/m²]</summary> 
  PAI : TVar;
  /// <summary>Stem area index [m²/m²]</summary>
  SAI : TVar;

  /// <summary>Specific leaf area in spring [cm²/g]</summary>
  SLAf : TVar;

  NDemandGrowth : TVar;

  /// <summary>Total N-demand deficit [gN/m²] </summary>
  NDemandDeficit : TVar;

  /// <summary>N-demand deficit of leaves [gN/m²] </summary>
  NDemandDeficitLeaf : TVar;

  /// <summary>N-demand deficit of stems [gN/m²] </summary>
  NDemandDeficitStem : TVar;

  /// <summary>N-demand deficit of root [gN/m²] </summary>
  NDemandDeficitRoot : TVar;

  /// <summary>N-demand deficit of generative organs [gN/m²] </summary>
  NDemandDeficitGen : TVar;

  /// <summary>N-supply from soil [gN/m²/d] </summary>
  NSupply : TVar;

  /// <summary>Thousand-seed mass</summary>
  TKM : TVar;
  /// <summary>Number of seeds per m²</summary>
  Samenanzahl : TVar;
  /// <summary>Harvest Index</summary>
  HI : TVar;
  /// <summary>Nitrogen Harvest Index</summary>
  NHI : TVar;
  /// <summary>Nitrogen Use Efficiency</summary>
  NUE : TVar;

  /// <summary>Conversion loss of assimilates due to conversion to oil </summary>
  ConversionLoss : TVar;
  /// <summary>Day of year at the beginning of the growing season, derived from temperature</summary>
  avs : TVar;

  /// <summary>Drought-stress response factor (Ferreya 2013)</summary>
  fW : TVar;

  /// <summary>N-deficit factor (ratio of N demand to N uptake)</summary>
  N_Def : TVar;

  LAImarray : Array [1..10] of real;

  fRootModel: TGrowthCurvePlantRoots{TSimpleRootModDM};

  // Constant Variables

  /// <summary>Shoot dry matter [g/m²]</summary>
  DMShoot : TState;
  /// <summary>Shoot dry matter before winter [g/m²]</summary>
  DMShoot_vW : TState;
  /// <summary>Shoot dry matter before flowering begins</summary>
  DMShoot_OF : TState;
  /// <summary>Shoot dry-matter accumulation since flowering</summary>
  DMShoot_nB : TState;
  /// <summary>Potential shoot dry-matter accumulation since flowering without drought stress</summary>
  DMShoot_nB_pot : TState;
  /// <summary>Leaf dry matter [g/m²]</summary>
  DMLeaf : TState;
  /// <summary>Stem dry matter [g/m²]</summary>
  DMStem : TState;
  /// <summary>Root dry matter [g/m²]</summary>
  DMRoot : TState;
  /// <summary>Generative dry matter [g/m²]</summary>
  DMGen : TState;
  /// <summary>Pod-wall dry matter [g/m²]</summary>
  DMPodWall : TState;
  /// <summary>Seed dry matter [g/m²]</summary>
  DMSeed : TState;
  DMSeedStarch : TState;
  DMSeedOil : TState;
  /// <summary>Total plant dry matter [g/m²]</summary>
  DMPlant : TState;
  /// <summary>Shoot area index [m²/m²]</summary>
  LAIShoot : TState;
  /// <summary>Leaf area index [m²/m²]</summary>
  LAILeaf : TState;
  /// <summary>Stem area index [m²/m²]</summary>
  LAIStem : TState;
  /// <summary>Shoot N amount [g/m²]</summary>
  NShoot : TState;
  /// <summary>Leaf N amount [g/m²]</summary>
  NLeaf : TState;
  /// <summary>Structural stem N amount [g/m²]</summary>
  strNStem : TState;
  /// <summary>Stem N pool</summary>
  poolNStem : TState;
  /// <summary>Total stem N amount</summary>
  NStem : TState;
  /// <summary>Generative-organ N amount [g/m²]</summary>
  NGen : TState;
  /// <summary>Structural root N amount [g/m²]</summary>
  strNRoot : TState;
  /// <summary>Root N pool</summary>
  poolNRoot : TState;
  /// <summary>Total root N amount</summary>
  NRoot : TState;
  /// <summary>N amount in dead leaves [g/m²]</summary>
  NDead : TState;
  /// <summary>Total plant N amount [g/m²]</summary>
  NPlant : TState;
  /// <summary>Seed N amount [g/m²]</summary>
  NSeed : TState;
  /// <summary>Pod-wall N amount [g/m²]</summary>
  NPodWall : TState;
  /// <summary>N amount in leaves killed by frost [g/m²]</summary>
  NDeadW : TState;
  /// <summary>N amount in leaves senesced by shading [g/m²]</summary>
  NDeadSh : TState;
  /// <summary>N amount translocated from leaves [g/m²]</summary>
  NTransLeaf : TState;
  /// <summary>N amount translocated from stems [g/m²]</summary>
  NTransStem : TState;
  /// <summary>N amount translocated from generative organs [g/m²]</summary>
  NTransGen : TState;
  /// <summary>N amount translocated from roots [g/m²]</summary>
  NTransRoot : TState;
  /// <summary>Total translocated N amount [g/m²]</summary>
  NTrans : TState;
  /// <summary>Potentially translocatable N amount [g/m²]</summary>
  potNTrans : TState;
  potNPool : TState;
  /// <summary>Potential N uptake [g/m²]</summary>
  NUptake_pot : TState;
  /// <summary>Actual N uptake [g/m²]</summary>
  NUptake_act : TState;
  /// <summary>Thermal time [°Cd]</summary>
  TempSum : TState;
  /// <summary>Thermal time since sowing[°Cd]</summary>
  TempSumAussaat : TState;
  /// <summary>Thermal time below zero [°Cd]</summary>
  TempSumMinus : TState;
  /// <summary>Thermal time since emergence [°Cd]</summary>
  TempSumAuflauf : TState;
  /// <summary>Thermal time since BBCH 70 [°Cd]</summary>
  TempSumPodGrowth : TState;
  TempSumSeed : TState;
  /// <summary>Thermal time controlling the decline in leaf growth</summary>
  TempSumLeafLoss : TState;
  /// <summary>Thermal time controlling the decline in root fraction</summary>
  TempSumRoots : TState;
  /// <summary>Area senesced by shading [m²/m²]</summary>
  LAIs : TState;
  /// <summary>Senescent shoot dry matter [g/m²]</summary>
  DMDead : TState;
  /// <summary>Dry matter killed by frost [g/m²]</summary>
  DMDeadW : TState;
  /// <summary>Leaf dry matter killed by frost senescence</summary>
  DMDeadLeafW : TState;
  /// <summary>Stem dry matter killed by frost senescence</summary>
  DMDeadStemW : TState;
  /// <summary>Root dry matter lost over winter</summary>
  DMDeadRootW : TState;
  /// <summary>Leaf dry matter senesced by shading [g/m²]</summary>
  DMDeadSh : TState;
  /// <summary>Leaf dry matter senesced by N deficiency [g/m²]</summary>
  DMDeadN : TState;
  /// <summary>Former live (green) dry matter of leaves senesced by N deficiency</summary>
  DM_N : TState;
  /// <summary>Leaf dry matter translocated following N-deficiency senescence</summary>
  DMNTrans : TState;
  /// <summary>Former live dry matter of leaves senesced by shading [g/m²]</summary>
  DMSh : TState;
  /// <summary>Leaf dry matter translocated following shading senescence</summary>
  DMShTrans : TState;
  /// <summary>Translocated stem dry matter [g/m²]</summary>
  DMTransStem : TState;
  /// <summary>Translocated leaf dry matter [g/m²]</summary>
  DMTransLeaf : TState;
  /// <summary>Translocated dry matter [g/m²]</summary>
  DMTrans : TState;
  /// <summary>Pod area index</summary>
  LAIGen : TState;
  /// <summary>Cumulative absorbed radiation [MJ]</summary>
  sumQ : TState;
  /// <summary>Cumulative temperature-corrected absorbed radiation [MJ]</summary>
  sumQT : TState;
  /// <summary>Cumulative drought- and temperature-corrected absorbed radiation [MJ]</summary>
  sumQT_TactTpot : TState;
  /// <summary>Cumulative radiation absorbed by leaves</summary>
  sumQLeaf : TState;
  /// <summary>Cumulative radiation absorbed by pods</summary>
  sumQGen : TState;
  /// <summary>Cumulative radiation</summary>
  RadSum : TState;

  /// <summary>C amount in shed leaves [kg/ha]</summary>
  C_Dead : TState;
  /// <summary>N amount in shed leaves [kg/ha]</summary>
  N_Dead : TState;

  DMDeadAge : TState;
  NDeadAge : TState;

  NPool : TState;
  /// <summary> seed yield [g/m²]</summary>
  Yield : TState;

  /// <summary>seed yield [g/m²]</summary>
  Ymax : TState;
  
  OilYield : TState;
  Oilconc : TState;
  Protein : TState;

  FullFlower : TState;
  SumConversionLoss : TState;

  NBalance : TState;
  NUptake_vW : TState;
  NUptake_aF : TState;

  // Parameters

  /// <summary>Base temperature (3 °C)</summary>
  Tb : TPar;
  /// <summary>Slope of the autumn allometric function</summary>
  gh : TPar;
  /// <summary>Intercept of the autumn allometric function</summary>
  hh : TPar;
  /// <summary>Slope of the spring allometric function</summary>
  gf : TPar;
  /// <summary>Intercept of the spring allometric function</summary>
  hf : TPar;
  /// <summary>Parameter for dry-matter partitioning after BBCH 51</summary>
  a : TPar;
  /// <summary>Parameter for dry-matter partitioning after BBCH 51</summary>
  b : TPar;
  /// <summary>Parameter for dry-matter partitioning after BBCH 51</summary>
  c : TPar;
  /// <summary>Parameter for dry-matter partitioning after BBCH 51</summary>
  d : TPar;
  /// <summary>Parameter for dry-matter partitioning after BBCH 51</summary>
  e : TPar;
  /// <summary>Parameter of the DMRoot exponential function</summary>
  root_exp : TPar;
  /// <summary>Parameter of the SPA exponential function</summary>
  SPA_exp : TPar;
  /// <summary>Parameter of the yield function (fPW)</summary>
  fPW_0 : TPar;
  /// <summary>Parameter of the yield function (fSSt)</summary>
  fPW_exp : TPar;
  pCnPod1 : TPar;
  pCnPod2 : TPar;
  /// <summary>Coefficient preceding the exponential term of the autumn stem N-dilution function</summary>
  pCnstem1h : TPar;
  /// <summary>Coefficient preceding the variable term of the autumn stem N-dilution function</summary>
  pCnstem2h : TPar;
  /// <summary>Coefficient preceding the exponential term of the root N-dilution function</summary>
  pCnRoot1h : TPar;
  /// <summary>Coefficient preceding the variable term of the root N-dilution function</summary>
  pCnRoot2h : TPar;
  /// <summary>Coefficient preceding the exponential term of the root N-dilution function</summary>
  pCnRoot1f : TPar;
  /// <summary>Coefficient preceding the variable term of the root N-dilution function</summary>
  pCnRoot2f : TPar;
  /// <summary>Leaf N concentration [%] (spring)</summary>
  pCnleaf : TPar;
  /// <summary>Intercept of the autumn leaf N-dilution function</summary>
  pCn1leaf : TPar;
  /// <summary>Slope of the autumn leaf N-dilution function</summary>
  pCn2leaf : TPar;
  /// <summary>N concentration of dead leaves [%]</summary>
  pCnDead: TPar;
  /// <summary>Root N concentration [%]</summary>
  pCnRoot: TPar;
  /// <summary>Seed N concentration [%]</summary>
  pCnSeed : TPar;
  /// <summary>Fraction of N translocated from senescent leaves</summary>
  pCnTrans : TPar;
  /// <summary>Lower cardinal temperature for growth</summary>
  Ct1 : TPar;
  /// <summary>Lower cardinal temperature of the optimum range</summary>
  Ct2 : TPar;
  /// <summary>Upper cardinal temperature of the optimum range</summary>
  Ct3 : TPar;
  /// <summary>Upper cardinal temperature for growth</summary>
  Ct4 : TPar;
  /// <summary>Specific leaf area after flowering [cm²/g]</summary>
  SLAnB : TPar;
  /// <summary>Slope parameter for autumn specific leaf area</summary>
  SLAhst : TPar;
  /// <summary>Intercept parameter for autumn specific leaf area</summary>
  SLAhin : TPar;
  /// <summary>Minimum autumn specific leaf area [cm²/g]</summary>
  SLAmin : TPar;
  /// <summary>Maximum autumn specific leaf area [cm²/g]</summary>
  SLAmax : TPar;
  /// <summary>SLA of senescent leaves [cm²/g]</summary>
  SLADead : TPar;
  /// <summary>Temperature threshold for winter senescence [cm²/g]</summary>
  fTminus : TPar;
  /// <summary>Specific stem area [cm²/g]</summary>
  SSA : TPar;
  /// <summary>Maximum specific pod area [cm²/g]</summary>
  SPAmax : TPar;
  /// <summary>Growth rate from BBCH 10 until DMcrit</summary>
  k1 : TPar;
  /// <summary>Dry-matter threshold for exponential growth</summary>
  DMcrit : TPar;
  /// <summary>Intercept of the root-fraction regression</summary>
  rooti : TPar;
  /// <summary>Slope of the root-fraction regression</summary>
  roots : TPar;
  /// <summary>Light extinction coefficient</summary>
  exk : TPar;
  /// <summary>Extinction coefficient at LAI = 0</summary>
  exk_0 : TPar;
  /// <summary>Critical LAI at which the extinction coefficient equals exk</summary>
  LAIcrit_exk : TPar;
  /// <summary>LUE</summary>
  LUELeaf : TPar;
  /// <summary>Intercept of the pre-winter LUE equation</summary>
  LUE0 : TPar;
  /// <summary>Pod radiation-use efficiency</summary>
  LUEPod : TPar;
  /// <summary>Incident radiation required to maintain DMShoot at pfTm_opt in autumn</summary>
  PARmh : TPar;
  /// <summary>Incident radiation required to maintain DMShoot at pfTm_opt in spring</summary>
  PARmf : TPar;
  /// <summary>Optimum temperature for the Arrhenius-type fTm response</summary>
  pfTm_opt: TPar;
  /// <summary>Q10 value for the Arrhenius-type fTm response</summary>
  pfTm_Q10: TPar;
  /// <summary>Number of days over which PARm is averaged</summary>
  pSen_sh: TPar;
  /// <summary>Exponent controlling the effect of fSen_sh</summary>
  pSen_sh_w: TPar;
  /// <summary>Slope of the linear relation between DMShoot loss and MinTempSum</summary>
  fSws : TPar;
  /// <summary>Plants per m²</summary>
  Plants: TPar;
  /// <summary>LAI after emergence with InitOption LAIInit [cm²/plant]</summary>
  pIniLAI: TPar;
  pCncritLeaf : TPar;
  pCncrit1Leaf : TPar;
  pCncrit2Leaf : TPar;
  pCncritStem1h : TPar;
  pCncritStem2h : TPar;
  pCncritPod1 : TPar;
  pCncritPod2 : TPar;
  pCncritRoot1h : TPar;
  pCncritRoot2h : TPar;
  pCncritRoot1f : TPar;
  pCncritRoot2f : TPar;
  pCnStem1f : TPar;
  pCnStem2f : TPar;
  pCncritStem1f : TPar;
  pCncritStem2f : TPar;
  y1 : TPar;
  SLAspring : TPar;
  fSLAspring : TPar;
  Oila : TPar;
  Oilb : TPar;
  Oilc : TPar;
  Oild : TPar;
  pfW:   TPAR;
  /// <summary>Scaling factor applied simultaneously to vegetative and generative LUE</summary>
  LUEscaling: TPAR;
//  minNNI : TPar; /// minimum NNI Value [0..1]

  fCO2_scale     : TPar;
  fCO2           : TPar;
  /// <summary>Adjustment of the CO2 effect for drought stress</summary>
  fCWSI          : TPar;
  /// <summary>CO2 compensation point</summary>
  CiCompensation : TPar;


  // External Variables

  /// <summary>Global radiation [W/m²]</summary>
  GRad : TExternV;
  /// <summary>Daily mean temperature</summary>
  TMPM : TExternV;
  /// <summary>BBCH stage</summary>
  EC : TExternV;
  /// <summary>Development-stage rate field</summary>
  DVS_rate : TExternV;
  /// <summary>Development stage</summary>
  DVS : TExternV;
  /// <summary>Day of year</summary>
  DayofYear : TExternV;
  /// <summary>LAI data</summary>
  LUE_LAI : TExternV;
  /// <summary>DMShoot growth for option ExternDM [g.m-2.d-1]</summary>
  DMGrowth_ex: TExternV;
  /// <summary>Water deficit</summary>
  TransRatio : TExternV;
  TransIntRatio : TExternV;
//  CO2pp:    TExternV;        /// external atmospheric CO2-concentration


//  TMeanEC71_79 : TExternV;
//  DauerEC71_79 : TExternV;
//  DauerEC81_89 : TExternV;
  DauerEC81_89: TState;

  // Options

  fLAIOption : TLAIOption;
  LAIOption : TOption;
  fDMGrowthOption : TDMOption;
  DMGrowthOption : TOption;
  fInitOption: TInitOption;
  InitOption: TOption;
  fNSensOption: TNSensOption;
  NSensOption: TOption;
  fDroughtOption : TDroughtOption;
  DroughtOption : TOption;
  OptWithCO2: TOption;


  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;
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

  // State Variables

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
  /// <summary>Cumulative absorbed radiation [MJ]</summary>
  Property St_sumQ : TState read  sumQ write sumQ;
  /// <summary>Cumulative temperature-corrected absorbed radiation [MJ]</summary>
  Property St_sumQT : TState read  sumQT write sumQT;
  /// <summary>Cumulative radiation absorbed by leaves</summary>
  Property St_sumQLeaf : TState read sumQLeaf write sumQLeaf;
  /// <summary>Cumulative radiation absorbed by pods</summary>
  Property St_sumQGen : TState read sumQGen write sumQGen;
  /// <summary>Cumulative drought- and temperature-corrected absorbed radiation [MJ]</summary>
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

         // Properties External Variables

  Property Ex_GRad : TExternV read GRad write GRad;
  Property Ex_TMPM : TExternV read TMPM write TMPM;
  Property Ex_EC : TExternV read EC write EC;
  Property Ex_DayofYear : TExternV read DayofYear write DayofYear;
  Property Ex_ExternLAI : TExternV read LUE_LAI  write LUE_LAI ;
  Property Ex_DMGrowth : TExternV read DMGrowth_ex  write DMGrowth_ex ;
  Property Ex_TransRatio : TExternV read TransRatio write TransRatio;
//  Property Ex_CO2pp: TExternV Read CO2pp Write CO2pp;


           // Option

  Property Opt_LAI : TOption read LAIOption write LAIOption;
  Property Opt_Init: TOption read InitOption write InitOption;
  Property Opt_Drought: TOption read DroughtOption write DroughtOption;

  Property DevelopmentModel: TDevelopmentOSR read fDevelopmentModel write setDevelopmentModel;
  Property RootModel: TGrowthCurvePlantRoots{TSimpleRootModDM} read fRootModel write fRootModel;
//  Property SoilNitrogenMod: TSoilNitrogenUp read fSoilNitrogenMod write fSoilNitrogenMod;
  Property SnowModel: TSnowPack read fSnowModel write fSnowModel;
//  Property SoilMinMod : TAbstractSoilMin read fSoilMinMod write fSoilMinMod;

end;  // SubmodelName

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
  VarCreate('PARRad', 'W/m²',0, true, PARRad,'Photosynthetically active radiation');
  VarCreate('fT', '',0, true, fT,'Photosynthesis response factor');
  VarCreate('fRoot', '',0, true, fRoot,'Root growth fraction');
  VarCreate('maxfRoot','',0,true,maxfRoot,'Maximum root growth fraction');
  VarCreate('fBl','',0,true,fBl,'Leaf fraction of shoot growth');
  VarCreate('fBl_EC51','',0,true,fBl_EC51,'Leaf growth fraction at BBCH 51');
  VarCreate('fSt','',0,true,fSt,'Stem fraction of shoot growth');
  VarCreate('fGen','',0,true,fGen,'Pod fraction of shoot growth');
  VarCreate('fPW','',0,true,fPW,'Pod-wall growth fraction of pod growth');
  VarCreate('fSeedGen','',0,true,fSeedGen,'Seed growth fraction of pod growth');
  VarCreate('fSeedStarch','',0,true,fSeedStarch,'Seed starch fraction');
  VarCreate('fSeedOil','',0,true,fSeedOil,'Seed oil fraction');
  VarCreate('fSum','',0,true,fSum,'Sum of organ-specific NNI-weighted fractions');
  VarCreate('fNNILeaf','',0,true,fNNILeaf,'Intermediate value used to calculate NNILeaf');
  VarCreate('fNNIStem','',0,true,fNNIStem,'Intermediate value used to calculate NNIStem');
  VarCreate('fNNIGen','',0,true,fNNIGen,'Intermediate value used to calculate NNIGen');
  VarCreate('fNNIRoot','',0,true,fNNIRoot,'Intermediate value used to calculate NNIRoot');
  VarCreate('Q', 'MJ',0, true, Q,'Absorbed radiation');
  VarCreate('QLeaf', 'MJ',0, true, QLeaf,'Radiation absorbed by leaves');
  VarCreate('QGen', 'MJ',0, true, QGen,'Radiation absorbed by pods');
  VarCreate('fInt', '',0, true, fInt,'Fraction of absorbed radiation');
  VarCreate('fIntLeaf', '',0, true, fIntLeaf,'Fraction of radiation absorbed by leaves');
  VarCreate('fIntGen', '',0, true, fIntGen,'Fraction of radiation absorbed by pods');
  VarCreate('act_k', '',0, true, act_k,'PAR extinction coefficient: exk or a variable value when LAI is below LAIcrit_exk');
  VarCreate('act_k_Leaf', '',0, true, act_k_Leaf,'Leaf extinction coefficient');
  VarCreate('act_k_Gen', '',0, true, act_k_Gen,'Pod extinction coefficient');
  VarCreate('QT', 'MJ',0, true, QT,'Temperature-corrected absorbed radiation');
  VarCreate('Teff', '°C',0, true, Teff,'Effective temperature');
  VarCreate('Tminus', '°C',0, true, Tminus,'Temperature below zero');
  VarCreate('NcLeaf', '%',0, true, NcLeaf,'Leaf N concentration');
  VarCreate('NcLeaf_VA','%',0,true,NcLeaf_VA,'Leaf N concentration at the beginning of the growing season');
  VarCreate('NcStem', '%',0, true, NcStem,'Stem N concentration');
  VarCreate('NcStem_VA','%',0,true,NcStem_VA,'Stem N concentration at the beginning of the growing season');
  VarCreate('NcStem_EC70','%',0,true,NcStem_EC70,'Stem N concentration at BBCH 70');
  VarCreate('NcGen','%',0,true,NcGen,'Generative-organ N concentration');
  VarCreate('NcRoot', '%',0, true, NcRoot,'Root N concentration');
  VarCreate('NcRoot_VA', '%',0, true, NcRoot_VA,'Root N concentration at the beginning of the growing season');
  VarCreate('NcRoot_EC70','%',0,true,NcRoot_EC70,'Root N concentration at BBCH 70');
  VarCreate('NUptakeRate_pot', 'g m-2 d-1',0, true, NUptakeRate_pot,'Potential N uptake rate (g.m-2.d-1)');
  VarCreate('NNI', '-',1, true, NNI,'Nitrogen Nutrition Index');
  VarCreate('CropHeight', 'm',0, true, CropHeight,'Crop height');
  VarCreate('LAILeaf_EC70','m²/m²',0,true,LAILeaf_EC70, 'LAI at BBCH 70');
  VarCreate('actSLA', 'cm²/g', 0 ,true, actSLA,'Specific leaf area');
  VarCreate('SLA', 'cm²/g', 0 ,true, avSLA,'Specific leaf area');
  VarCreate('actSPA','cm²/g',0,true,actSPA,'Specific pod area');
  VarCreate('SPA','cm²/g',0,true,avSPA,'Specific pod area');
  VarCreate('LUE', 'g/MJ', 0 ,true, LUE,'Radiation-use efficiency');
  VarCreate('LUEGen','g/MJ',0,true,LUEGen,'Radiation-use efficiency of pods');
  VarCreate('g', '', 0 ,true, g,'Slope of the allometric function');
  VarCreate('h', '', 0 ,true, h,'Intercept of the allometric function');
  VarCreate('LAIm', 'm²/m²',0, true,LAIm,'Maximum maintainable LAI at the available radiation');
  VarCreate('fTm', '',0, true, fTm,'Temperature factor for maintenance respiration used to calculate PARm');
  VarCreate('fTSen','',0,true,fTSen,'Temperature factor used in the senescence calculation');
  VarCreate('fSen_sh', '',0, true, fSen_sh,'Shading and maintenance-respiration senescence factor');
  VarCreate('Auflauf', 'd',0, true,Auflauf,'Time of emergence');
  VarCreate('DummyVar', '',0, true, DummyVar);
  VarCreate('EC_act','',0,true,EC_act,'BBCH stage at which LAIShoot equals 2.0');
  VarCreate('Transkoeff','',0,true,Transkoeff,'Transmission coefficient during pod development');
  VarCreate('maxGAI','m²/m²',0,true,maxGAI,'max. GAI');
  VarCreate('maxLAIGen','m²/m²',0,true,maxLAIGen,'max. PAI');
  VarCreate('maxLAIStem','m²/m²',0,true,maxLAIStem,'max. SAI');
  VarCreate('dNcLeaf','',0,true,dNcLeaf,'Change in NcLeaf');
  VarCreate('dNcStem','',0,true,dNcStem,'Change in NcStem');
  VarCreate('dNcRoot','',0,true,dNcRoot,'Change in NcRoot');
  VarCreate('dNcGen','',0,true,dNcGen,'Change in NcGen');
  VarCreate('NcritLeaf','%',0,true,NcritLeaf,'Critical leaf N concentration');
  VarCreate('NcLeaf_act','%',0,true,NcLeaf_act,'Current leaf N concentration');
  VarCreate('NcStem_act','%',0,true,NcStem_act,'Current stem N concentration');
  VarCreate('NcGen_act','%',0,true,NcGen_act,'Current pod N concentration');
  VarCreate('NcRoot_act','%',0,true,NcRoot_act,'Current root N concentration');
  VarCreate('NcritStem','%',0,true,NcritStem,'Critical stem N concentration');
  VarCreate('NcritGen','%',0,true,NcritGen,'Critical pod N concentration');
  VarCreate('NcritRoot','%',0,true,NcritRoot,'Critical root N concentration');
  VarCreate('NcritRoot_VA','%',0,true,NcritRoot_VA,'Critical root N concentration at the beginning of the growing season');
  VarCreate('NcritLeaf_VA','%',0,true,NcritLeaf_VA,'Critical leaf N concentration at the beginning of the growing season');
  VarCreate('NcritStem_VA','%',0,true,NcritStem_VA,'Critical stem N concentration at the beginning of the growing season');
  VarCreate('NcritStem_EC70','%',0,true,NcritStem_EC70,'Critical stem N concentration at BBCH 70');
  VarCreate('NcritRoot_EC70','%',0,true,NcritRoot_EC70,'Critical root N concentration at BBCH 70');
  VarCreate('NNILeaf','-',1,true,NNILeaf,'Leaf NNI');
  VarCreate('NNIStem','-',1,true,NNIStem,'Stem NNI');
  VarCreate('NNIGen','-',1,true,NNIGen,'Pod NNI');
  VarCreate('NNIRoot','-',1,true,NNIRoot,'Root NNI');
  VarCreate('PAI','',0,true,PAI,'Pod area index');
  VarCreate('SAI','',0,true,SAI,'Stem area index');
  VarCreate('SLAf','cm²/g',0,true,SLAf,'SLA in spring');
  VarCreate('NDemandGrowth','g/m²',0,true,NDemandGrowth,'N demand for current growth');
  VarCreate('NDemandDeficit','g/m²',0,true,NDemandDeficit,'N demand to compensate for an existing N deficit');
  VarCreate('NDemandDeficitLeaf','g/m²',0,true,NDemandDeficitLeaf,'N demand to compensate for an existing leaf N deficit');
  VarCreate('NDemandDeficitStem','g/m²',0,true,NDemandDeficitStem,'N demand to compensate for an existing stem N deficit');
  VarCreate('NDemandDeficitRoot','g/m²',0,true,NDemandDeficitRoot,'N demand to compensate for an existing root N deficit');
  VarCreate('NDemandDeficitGen','g/m²',0,true,NDemandDeficitGen,'N demand to compensate for an existing pod N deficit');
  VarCreate('NSupply','g/m²',0,true,NSupply,'Available N amount');

  VarCreate('TKM','g',0,true,TKM,'Thousand seed mass');
  VarCreate('Samenanzahl','m-2',0,true,Samenanzahl,'Number of seeds per m²');
  VarCreate('HI','',0,true,HI,'Harvest index');
  VarCreate('NHI','',0,true,NHI,'Nitrogen Harvest Index');
  VarCreate('NUE','',0,true,NUE,'Nitrogen Use Efficiency');

  VarCreate('KonversionVerlust','',0,true,ConversionLoss,'Conversion loss caused by oil formation instead of starch formation');

  VarCreate('avs','',0,true,avs,'Day of year at the beginning of the growing season, derived from temperature');
  VarCreate('Parav','[-]', 0.0, false, Parav,'Mean PAR over five days used as the maintenance-respiration threshold');
  VarCreate('fW','',1,true,fW,'Drought-stress response factor (Ferreya 2013)');

  VarCreate('N_Def','',0,true,N_Def,'N-deficit factor (ratio of N demand to N uptake)');
  VarCreate('CO2_factor', '[-]',1, true,  CO2_factor);

  StateCreate('DMShoot', 'g/m²',0.1, true,DMShoot,'Shoot dry matter');
  StateCreate('DMShoot_OF','g/m²',0,true,DMShoot_OF,'Shoot dry matter at the onset of flowering');
  StateCreate('DMShoot_nB','g/m²',0,true,DMShoot_nB,'Shoot dry-matter accumulation since flowering');
  StateCreate('DMShoot_nB_pot','g/m²',0,true, DMShoot_nB_pot,'Potential shoot dry-matter accumulation since flowering without drought stress');
  StateCreate('DMShoot_vW','g/m²',0.1,true,DMShoot_vW,'Shoot dry matter before winter');
  StateCreate('DMLeaf', 'g/m²',0, true,DMLeaf,'Leaf dry matter');
  StateCreate('DMStem', 'g/m²',0, true,DMStem,'Stem dry matter');
  StateCreate('DMRoot', 'g/m²',0, true,DMRoot,'Root dry matter');
  StateCreate('DMGen', 'g/m²',0,true,DMGen,'Generative dry matter');
  StateCreate('DMPodWall','g/m²',0,true,DMPodWall,'Pod-wall dry matter');
  StateCreate('DMSeed','g/m²',0,true,DMSeed,'Seed dry matter');
  StateCreate('DMSeedStarch','g/m²',0,true,DMSeedStarch,'Seed starch dry matter');
  StateCreate('DMSeedOil','g/m²',0,true,DMSeedOil,'Seed oil dry matter');
  StateCreate('DMPlant', 'g/m²',0, true,DMPlant,'Total plant dry matter');
  StateCreate('LAIShoot', 'm²/m²',0, true,LAIShoot,'Shoot area index');
  StateCreate('LAILeaf', 'm²/m²',0, true,LAILeaf,'Leaf area index');
  StateCreate('LAIStem', 'm²/m²',0, true,LAIStem,'Stem area index');
  StateCreate('NShoot', 'g/m²',0, true,NShoot,'Shoot N amount');
  StateCreate('NLeaf', 'g/m²',0, true,NLeaf,'Leaf N amount');
  StateCreate('strNStem', 'g/m²',0, true,strNStem,'Structural stem N amount');
  StateCreate('poolNStem', 'g/m²',0, true,poolNStem,'Stem N pool');
  StateCreate('NStem', 'g/m²',0, true,NStem,'Total stem N amount');
  StateCreate('NGen','g/m²',0,true,NGen,'Generative-organ N amount');
  StateCreate('strNRoot', 'g/m²',0, true,strNRoot,'Structural root N amount');
  StateCreate('poolNRoot', 'g/m²',0, true,poolNRoot,'Root N pool');
  StateCreate('NRoot', 'g/m²',0, true,NRoot,'Total root N amount');
  StateCreate('NDead', 'g/m²',0, true,NDead,'N amount in dead leaves [g/m²]');
  StateCreate('NPlant', 'g/m²',0, true,NPlant,'Total plant N amount [g/m²]');
  StateCreate('NSeed','g/m²',0,true,NSeed,'Seed N amount [g/m²]');
  StateCreate('NPodWall','g/m²',0,true,NPodWall,'Pod-wall N amount [g/m²]');
  StateCreate('NDeadW','g/m²',0,true,NDeadW,'N amount lost through frost senescence');
  StateCreate('NDeadSh','g/m²',0,true,NDeadSh,'N amount lost through shading senescence');
  StateCreate('NTransLeaf','g/m²',0,true,NTransLeaf,'Translocatable N amount from leaves');
  StateCreate('NTransStem','g/m²',0,true,NTransStem,'Translocatable N amount from stems');
  StateCreate('NTransGen','g/m²',0,true,NTransGen,'Translocatable N amount from pods');
  StateCreate('NTransRoot','g/m²',0,true,NTransRoot,'Translocatable N amount from roots');
  StateCreate('NTrans','g/m²',0,true,NTrans,'Total translocatable N amount');
  StateCreate('potNTrans','g/m²',0,true,potNTrans,'Potentially translocatable N amount');
  StateCreate('potNPool','g/m²',0,true,potNPool,'Potential N-pool amount');
  StateCreate('NUptake_pot', 'g/m²',0, true,NUptake_pot,'Potential N uptake [g/m²]');
  StateCreate('NUptake_act', 'g/m²',0, true,NUptake_act,'Actual N uptake [g/m²]');
  StateCreate('TempSum', '[°Cd]',0, true,TempSum,'Thermal time');
  StateCreate('TempSumAussaat', '[°Cd]',0, true,TempSumAussaat,'Thermal time since sowing');
  StateCreate('TempSumMinus', '[°Cd]',0, true,TempSumMinus,'Thermal time');
  StateCreate('TempSumAuflauf','[°Cd]',0,true,TempSumAuflauf,'Thermal time since emergence (Tb = 0°C)');
  StateCreate('TempSumPodGrowth','[°Cd]',0,true,TempSumPodGrowth,'Thermal time since BBCH 70');
  StateCreate('TempSumSeed','[°Cd]',0,true,TempSumSeed,'Thermal time during seed maturation');
  StateCreate('TempSumLeafLoss','[°Cd]',0,true,TempSumLeafLoss,'Thermal time since BBCH 51 controlling the decline in the leaf fraction of total plant growth');
  StateCreate('TempSumRoots','[°Cd]',0,true,TempSumRoots,'Thermal time between day 30 and day 150 used to calculate fRoot');
  StateCreate('LAIs', 'm²/m²',0, true,LAIs,'Area senesced by shading');
  StateCreate('DMdead', 'g/m²',0, true, DMdead,'Senescent dry matter');
  StateCreate('DMDeadW', 'g/m²',0, true, DMDeadW,'Dry matter lost through frost senescence');
  StateCreate('DMDeadLeafW', 'g/m²',0, true, DMDeadLeafW,'Leaf dry matter killed by frost senescence');
  StateCreate('DMDeadStemW', 'g/m²',0, true, DMDeadStemW,'Stem dry matter killed by frost senescence');
  StateCreate('DMDeadRootW','g/m²',0,true,DMDeadRootW,'Root dry matter lost over winter');
  StateCreate('DMDeadSh', 'g/m²',0, true, DMDeadSh,'Leaf dry matter lost through shading senescence');
  StateCreate('DMDeadN', 'g/m²', 0, true, DMDeadN,'Leaf dry matter senesced by N deficiency');
  StateCreate('DM_N','g/m²',0,true,DM_N,'Former live (green) dry matter of leaves senesced by N deficiency');
  StateCreate('DMNTrans','g/m²',0,true,DMNTrans,'Leaf dry matter translocated following N-deficiency senescence');
  StateCreate('DMSh','g/m²',0,true,DMSh,'Potential dry matter senesced and translocated from leaves through shading');
  StateCreate('DMShTrans','g/m²',0,true,DMShTrans,'Leaf dry matter translocated to pods following shading senescence');
  StateCreate('DMTransStem','g/m²',0,true,DMTransStem,'Translocated stem dry matter');
  StateCreate('DMTransLeaf','g/m²',0,true,DMTransLeaf,'Translocated leaf dry matter');
  StateCreate('DMTrans','g/m²',0,true,DMTrans,'Translocated dry matter');
  StateCreate('LAIGen','m²/m²',0,true,LAIGen,'Pod area index');
  StateCreate('C_Dead','kg/ha',0,true,C_Dead,'C amount in shed leaves');
  StateCreate('N_Dead','kg/ha',0,true,N_Dead,'N amount in shed leaves');

  StateCreate('Yield','dt/ha',0,true,Yield,'Seed yield');
  StateCreate('OilYield','dt/ha',0,true,OilYield,'Oil yield');
  StateCreate('Oilconc','%',0,true,Oilconc,'Oil concentration');
  StateCreate('Protein','%',0,true,Protein,'Protein concentration');
  StateCreate('Ymax','dt/ha',0,true,Ymax,'Maximum yield');

  StateCreate('NPool','g/m²',0,true,NPool,'N pool in stems and roots for N translocated from leaves before generative organs act as sinks');

  StateCreate('DMDeadAge', 'g/m²',0, true,DMDeadAge,'Age-related senescence after BBCH 80');
  StateCreate('NDeadAge', 'g/m²',0, true,NDeadAge,'Age-related senescence after BBCH 80');

  StateCreate('FullFlower','',0,true,FullFlower,'Date of BBCH 65');
  StateCreate('SumKonversionVerlust','',0,true,SumConversionLoss,'Cumulative conversion loss during oil formation');
  StateCreate('sumQ', '[MJ/m2]',0,true,sumQ,'Cumulative absorbed radiation  [MJ]');          // Cumulative absorbed radiation  [MJ]
  StateCreate('sumQT', '[MJ/m2]',0,true,sumQT,'Cumulative temperature-corrected absorbed radiation  [MJ]');          // Cumulative temperature-corrected absorbed radiation  [MJ]
  StateCreate('sumQLeaf', '[MJ/m2]',0,true, sumQLeaf,'Cumulative radiation absorbed by leaves');      // Cumulative radiation absorbed by leaves
  StateCreate('sumQGen', '[MJ/m2]',0,true, sumQgen,'Cumulative radiation absorbed by pods');       // Cumulative radiation absorbed by pods
  StateCreate('RadSum','[MJ/m²]',0,true, RadSum,'Cumulative radiation');

  StateCreate('sumQT_TactTpot', '[MJ/m2]',0,true, sumQT_TactTpot,
    'Cumulative drought- and temperature-corrected absorbed radiation  [MJ]');

  StateCreate('NBalance','[g/m²]',0,true,NBalance);
  StateCreate('NUptake_vW','',0,true,NUptake_vW,'N uptake before winter');
  StateCreate('NUptake_aF','',0,true,NUptake_aF,'N uptake after flowering');



    // Parameters
  ParCreate('pfW', '[-]', 1, pfW,
    'Parameter for the nonlinear relation between TransRatio and SWDF (Ferreyra 2003)');
  ParCreate('Tb', '°C', 3 , Tb,'Base temperature');
  ParCreate('gh', '', 1.2539 , gh,'Slope parameter of the autumn allometric relation');
  ParCreate('hh', '', -1.9765 , hh,'Intercept parameter of the autumn allometric relation');
  ParCreate('gf','',3.56389,gf,'Slope parameter of the spring allometric relation');
  ParCreate('hf','',-9.92018,hf,'Intercept parameter of the spring allometric relation');
  ParCreate('a','',2.7226,a,'Parameter for dry-matter partitioning after BBCH 51');
  ParCreate('b','',-4.9899,b,'Parameter for dry-matter partitioning after BBCH 51');
  ParCreate('c','',4E-12,c,'Parameter for dry-matter partitioning after BBCH 51');
  ParCreate('d','',-0.561,d,'Parameter for dry-matter partitioning after BBCH 51');
  ParCreate('e','',70,e,'Parameter for dry-matter partitioning after BBCH 51');
  ParCreate('root_exp','',-0.05,root_exp,'Parameter of the DMRoot exponential function');
  ParCreate('SPA_Exp','',-0.05,SPA_exp,'Parameter of the SPA exponential function');
  ParCreate('fPW_0','',100,fPW_0,'Parameter of the yield function (fPW)');
  ParCreate('fPW_exp','',-0.008,fPW_exp,'Parameter of the yield function (fPW)');
  ParCreate('pCnPod1','',8,pCnPod1,'Pod N-dilution function');
  ParCreate('pCnPod2','',-0.8,pCnPod2,'Pod N-dilution function');
  ParCreate('pCnstem1h', '', 0.0458 , pCnstem1h,'Coefficient preceding the exponential term of the autumn stem N-dilution function');
  ParCreate('pCnstem2h', '', -0.0021 , pCnstem2h,'Coefficient preceding the variable term of the autumn stem N-dilution function');
  ParCreate('pCnRoot1h', '',3.3127, pCnRoot1h,'Coefficient preceding the exponential term of the root N-dilution function');
  ParCreate('pCnRoot2h', '',-0.11, pCnRoot2h,'Coefficient preceding the variable term of the root N-dilution function');
  ParCreate('pCnRoot1f', '',3.9548, pCnRoot1f,'Coefficient preceding the exponential term of the root N-dilution function');
  ParCreate('pCnRoot2f', '',-0.0059, pCnRoot2f,'Coefficient preceding the variable term of the root N-dilution function');
  ParCreate('pCnleaf', '', 5.659 , pCnleaf,'Leaf N concentration');
  ParCreate('pCn1leaf', '', 6.707 , pCn1leaf,'Coefficient applied to DMLeaf');
  ParCreate('pCn2leaf', '', -0.01624 , pCn2leaf,'Slope of the autumn leaf N-dilution function');
  ParCreate('pCnDead', '%', 2 , pCnDead,'N concentration of dead leaves');
  ParCreate('pCnRoot', '%', 4 , pCnRoot,'Root N concentration');
  ParCreate('pCnSeed','%',3,pCnSeed,'Seed N concentration');
  ParCreate('pCnTrans','',0.65,pCnTrans,'Fraction of N translocated from senescent leaves');
  ParCreate('Ct1', '°C', 3 , Ct1,'Lower cardinal temperature for growth');
  ParCreate('Ct2', '°C', 10 , Ct2,'Lower cardinal temperature of the optimum range');
  ParCreate('Ct3', '°C', 20 , Ct3,'Upper cardinal temperature of the optimum range');
  ParCreate('Ct4', '°C', 35 , Ct4,'Upper cardinal temperature for growth');
  ParCreate('SLAhst', '', -0.2759 , SLAhst,'Slope parameter for autumn specific leaf area');
  ParCreate('SLAhin', '', 396.52 , SLAhin,'Intercept parameter for autumn specific leaf area');
  ParCreate('SLAmin', 'cm²/g', 100 , SLAmin,'Minimum autumn specific leaf area');
  ParCreate('SLAmax', 'cm²/g', 350 , SLAmax,'Maximum autumn specific leaf area');
  ParCreate('SLAnB','cm²/g',275,SLAnB,'Specific leaf area after flowering');
  ParCreate('SLADead', 'cm²/g', 500 , SLADead,'SLA of senescent leaves [cm²/g]');
  ParCreate('fTminus', '°C', 20 , fTminus,'Temperature threshold for winter senescence');
  ParCreate('SSA', 'cm²/g', 20 , SSA,'Specific stem area');
  ParCreate('SPAmax','cm²/g',60,SPAmax,'Maximum specific pod area');
  ParCreate('k1', '', 0.02 , k1,'Growth rate from BBCH 10 to BBCH 13');
  ParCreate('DMcrit', 'g/m²', 5 , DMcrit,'Dry-matter threshold for exponential growth');
  ParCreate('rooti', '', 0.119184 , rooti,'Intercept of the root-fraction regression');
  ParCreate('roots', '', -0.000029 , roots,'Slope of the root-fraction regression');
  ParCreate('exk', '', 0.8 , exk,'Extinction coefficient');
  ParCreate('exk_0', '', 0.9 , exk_0,'Extinction coefficient at LAI = 0 for variable exk');
  ParCreate('LAIcrit_exk', 'm2/m2', 1.5 , LAIcrit_exk,'Critical LAI at which the extinction coefficient equals exk');
  ParCreate('LUELeaf', 'g/MJ', 4 , LUELeaf,'Radiation-use efficiency');
  ParCreate('LUE0', '', 3.196 , LUE0,'Intercept of the pre-winter LUE equation');
  ParCreate('LUEPod','',4,LUEPod,'Pod radiation-use efficiency');
  ParCreate('fCO2', '[-]',   0.086,  fCO2);
  ParCreate('fCO2_scale', '[-]',   0.723,  fCO2_scale);
  ParCreate('fCWSI', '[-]',   0.077,  fCWSI);
  ParCreate('CiCompensation', '[ppm]',   350,  CiCompensation);
  ParCreate('PARmh', 'W/m²', 0.03456 , PARmh,'Maintenance radiation required in autumn');
  ParCreate('PARmf', 'W/m²', 0.03456 , PARmf,'Maintenance radiation required in spring');
  ParCreate('pfTm_opt', '°C', 20, pfTm_opt,'Optimum temperature for the Arrhenius-type fTm response');
  ParCreate('pfTm_Q10', '', 2, pfTm_Q10,'Q10 value for the Arrhenius-type fTm response');
  ParCreate('pSen_sh', '', 3, pSen_sh,'Number of days over which PARm is averaged');
  ParCreate('pSen_sh_w', '', 1, pSen_sh_w,'Exponent controlling the effect of fSen_sh');
  ParCreate('fSws', '',0.005, fSws,'Relative winter-senescence rate');
  ParCreate('Plants', 'm-2',40, Plants,'Plants per m²');
  ParCreate('pIniLAI', 'cm2/plant', 1, pIniLAI,'LAI after emergence with InitOption LAIInit [cm²/plant]');
  ParCreate('pCncritLeaf','%',4.3,pCncritLeaf,'Critical leaf N-dilution function before stem elongation');
  ParCreate('pCncrit1Leaf','',5.8664,pCncrit1Leaf,'Critical leaf N-dilution function after the start of stem elongation');
  ParCreate('pCncrit2Leaf','',-0.0187,pCncrit2Leaf,'Critical leaf N-dilution function after the start of stem elongation');
  ParCreate('pCncritStem1h','',3.2894,pCncritStem1h,'Critical stem N-dilution function before stem elongation');
  ParCreate('pCncritStem2h','',-0.013,pCncritStem2h,'Critical stem N-dilution function before stem elongation');
  ParCreate('pCncritPod1','',7.5238,pCncritPod1,'Critical pod N-dilution function');
  ParCreate('pCncritPod2','',-0.872,pCncritPod2,'Critical pod N-dilution function');
  ParCreate('pCncritRoot1h','',2.9569,pCncritRoot1h,'Critical root N-dilution function before stem elongation');
  ParCreate('pCncritRoot2h','',-0.156,pCncritRoot2h,'Critical root N-dilution function before stem elongation');
  ParCreate('pCncritRoot1f','',3.9241,pCncritRoot1f,'Critical root N-dilution function after the start of stem elongation');
  ParCreate('pCncritRoot2f','',-0.0097,pCncritRoot2f,'Critical root N-dilution function after the start of stem elongation');
  ParCreate('pCnStem1f','',7.7107,pCnStem1f,'Stem N-dilution function after the start of stem elongation');
  ParCreate('pCnStem2f','',-0.95,pCnStem2f,'Stem N-dilution function after the start of stem elongation');
  ParCreate('pCncritStem1f','',5.6311,pCncritStem1f,'Critical stem N-dilution function after the start of stem elongation');
  ParCreate('pCncritStem2f','',-0.86,pCncritStem2f,'Critical stem N-dilution function after the start of stem elongation');

  ParCreate('y1','[-]',0.37,y1,'Parameter used to calculate yield, currently equivalent to the harvest index');
  ParCreate( 'LUEscaling', '[-]',1,LUEscaling,'Scaling factor applied simultaneously to vegetative and generative LUE');
//  ParCreate( 'minNNI', '[-]',0.0, minNNI,'Minimum value for NNI');

  ParCreate('SLAspring','',101.97,SLAspring,'Parameter for calculating SLA after BBCH 30 as a function of GAI');
  ParCreate('fSLAspring','',24.121,fSLAspring,'Parameter for calculating SLA after BBCH 30 as a function of GAI');

  ParCreate('Oila','',50,Oila,'Parameter for calculating oil concentration as a function of seed-maturation duration');
  ParCreate('Oilb','',240,Oilb,'Parameter for calculating oil concentration as a function of seed-maturation duration');
  ParCreate('Oilc','',-0.016,Oilc,'Parameter for calculating oil concentration as a function of seed N amount');
  ParCreate('Oild','',-0.0226,Oild,'Parameter for calculating oil concentration as a function of seed N amount');

  // External Variable

  ExternVCreate('Rad_Int', 'W/m²',statefield, GRad,'Global radiation');
  ExternVCreate('TMPM', '°C',statefield, TMPM,'Daily mean temperature');
  ExternVCreate('EC', '',statefield, EC,'Phenological stage');
  ExternVCreate('DVS', '',ratefield, DVS_rate,'Phenological stage');
  ExternVCreate('DVS','',statefield, DVS,'Development stage');
  ExternVCreate('DayofYear', '',statefield, DayofYear,'Day of year');
  ExternVCreate('LAI', 'm²/m²',statefield, LUE_LAI,'LAI used for LUE calculation');
  ExternVCreate('DM', 'g.m-2.d-1',ratefield, DMGrowth_ex,'DMShoot growth for option ExternDM');
  ExternVCreate('TransRatio','',statefield,TransRatio,'Ratio of potential to actual transpiration');
  ExternVCreate('TransIntRatio','',statefield,TransIntRatio,'Ratio of potential to actual transpiration, accounting for interception');
//  ExternVCreate('CO2pp','[ppm]',statefield, CO2pp, 'External atmospheric CO2 concentration');

//  ExternVCreate('TMeanEC71_79','°C',statefield,TMeanEC71_79,'Mean daily temperature between BBCH 71 and BBCH 79');
//  ExternVCreate('DauerEC71_79','d',statefield,DauerEC71_79,'Number of days from BBCH 71 to BBCH 79');
//  ExternVCreate('DauerEC81_89','d',statefield,DauerEC81_89,'Number of days from BBCH 81 to BBCH 89');
  StateCreate('DauerEC81_89', '',0, true, DauerEC81_89);

  // Options

  OptCreate ('LAIOption', 'InternLAI', LAIOption,'Internally calculated LAI or external variable');
  LAIOption.Optionlist.Clear;
  LAIOption.Optionlist.add('InternLAI');
  LAIOption.Optionlist.add('ExternLAI');
  fLAIOption := InternLAI;

  OptCreate ('DMGrowthOption', 'InternDM', DMGrowthOption, 'Internally calculated dry-matter growth or external variable');
  DMGrowthOption.Optionlist.Clear;
  DMGrowthOption.Optionlist.add('InternDM');
  DMGrowthOption.Optionlist.add('ExternDM');
  fDMGrowthOption := InternDM;

  OptCreate('InitOption', 'DMCrit', InitOption, 'Initialise the model from exponential dry-matter growth or initial LAI');
  InitOption.Optionlist.Clear;
  InitOption.Optionlist.add('DMCrit');
  InitOption.Optionlist.add('LAIInit');
  fInitOption := DMCritInit;



  OptCreate ('NSensOption', 'N_sensitiv', NSensOption, 'Effect of N deficiency on dry-matter growth');
  NSensOption.Optionlist.Clear;
  NSensOption.Optionlist.add('N_sensitiv');
  NSensOption.Optionlist.add('N_unlimited');
  fNSensOption := N_sensitiv;

  OptCreate ('DroughtOption', 'DroughtImpact', DroughtOption, 'Effect of drought stress on dry-matter growth');
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
  // Initial values used to prevent division by zero
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
  /// <summary>Loop counters for shading senescence</summary>
  i,j : integer;
  /// <summary>LAI maintainable by radiation, averaged over pSen_sh days</summary>
  LAIm_ave,
  /// <summary>Crop water stress index</summary>
  CWSI,
  CO2_factor_min: real;
begin
  inherited;

  if (Globtime.v >= SowingDate.v) and (GlobTime.v <= HarvestDate.v) then begin

    // initialisation of several variables after emergence
    InitAfterEmergence;

    // calculation of several temperature sums governing some processes
    CalcTempSums;

  // Calculate maximum GAI, SAI and PAI (SAI and PAI increase until BBCH 80)
    maxGAI.v := max(LAILeaf.v+LAIGen.v+LAIStem.v,maxGAI.v);

    if (EC.v < 80) then
      maxLAIGen.v := LAIGen.v;

    if (EC.v < 80) then
      maxLAIStem.v := LAIStem.v;


  // Determine the start of the growing season from temperature
   if ((DayofYear.v > 30) and (DayofYear.v < 90)) and  (Teff.v > 0) then
      inc(avs_day)
   else
      avs_day := 0;

   if (avs_day = 5) and (avs.v = 0) then
     avs.v := DayofYear.v;

   if (EC.v >= 81) and (EC.v <= 89) then DauerEC81_89.c := 1 else DauerEC81_89.c := 0;

   CalcRadiationUptake;
   CalculateIntermediateVariables;
   CalcLUE;
   CalcRootFraction;
   CalcShootRootGrowth;


  // Calculate crop height (Dissertation W. Weymann, Chapter 4, Figure 1)
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

  // Radiation averaged over ten days
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

    CalcMaintainableLAI(LAIm_ave);

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
    else  // Age-related senescence from BBCH 70, independent of shading
      LAIs.c := -((((0 - LAILeaf_EC70.v)/(90-70))*(EC.v-70)+LAILeaf_EC70.v)-LAILeaf.v);

  // Change of Dead LAI
    // SLA of senescent leaves = 500 cm²/g
      DMDeadSh.c := LAIs.c/SLADead.v*10000{cm²/m²};

    if (avSLA.v > 0) and (fT.v > 0) then
      DMSh.c := LAIs.c/avSLA.v*10000  // non dead leaf mass
    else
      DMSh.c := 0;

    DMShTrans.c := DMSh.c - DMDeadSh.c;  // Translocatable dry matter


  // Dry-matter partitioning
    // Allometric functions
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
   { Reduction depends on the N deficiency of the organs (NNIi);
     the calculated NNI differs from the NNI of Justes et al. (1994) and
     Colnenne et al. (1998); it is calculated from the N-dilution functions }
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

    CalcConversionLosses;
    CalcDMLossFrostShading;



  // Oil concentration as a function of seed-maturation duration and seed N amount
    if (NSeed.v > 0) then
      Oilconc.v := (Oila.v * DauerEC81_89.v + Oilb.v) * (Oilc.v * NSeed.v + Oild.v)
    else
      Oilconc.v := 0;


  // Calculate yield using harvest index y1.v
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


  // N concentration (Nc = optimum N concentration, Ncrit = critical N concentration; Dissertation W. Weymann, Chapter 4, Figure 4)
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
              NcLeaf.v := min(7,max(0,pCn2leaf.v*DMleaf.v+pCn1leaf.v+DMLeaf.v*pCn2leaf.v));      // Autumn: N-dilution function
              NcritLeaf.v := min(7,max(0,pCncrit2Leaf.v*DMLeaf.v+pCncrit1Leaf.v+DMLeaf.v*pCncrit2Leaf.v));
              dNcLeaf.v := min(7,max(0,pCn2leaf.v*(DMleaf.v+DMLeaf.c)+pCn1leaf.v+(DMLeaf.v+DMLeaf.c)*pCn2leaf.v)-NcLeaf.v);
            end
            else begin
              NcLeaf.v := min(NcLeaf.v,max(0,pCn2leaf.v*DMleaf.v+pCn1leaf.v+DMLeaf.v*pCn2leaf.v));      // Autumn: N-dilution function
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


  // Calculate NNIi from the difference between optimal and critical N concentration
    {NNIi is not identical to the NNI of Justes et al. (1994), but uses the dilution-curve data to represent the N status of each organ as closely as possible}
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

    if (EC.v < 30) then      // Variable autumn SLA; linear dependence on thermal time since sowing
      actSLA.v := max (SLAmin.v, min(SLAmax.v, SLAhst.v*TempsumAussaat.v+SLAhin.v))
    else
        if (EC.v <= 64) then // Dissertation W. Weymann, Chapter 4, Figure 3
        actSLA.v := min(500,max(actSLA.v,fSLAspring.v * LAIShoot.v + SLAspring.v))
        else
        actSLA.v := actSLA.v;

  // SPA (specific pod area)
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
  //    LAIGen.c := Slope of the linear decline in LAIGen with thermal time from maxLAIGen to zero
      PAI.v := (((-0.01)-0)/(90-80))*(EC.v-80)+0;
      LAIGen.c := max(-LAIGen.v, (PAI.v * TempSumSeed.v + maxLAIGen.v)-LAIGen.v);
    end;

    CalculateOrganNuptakerates;
    CalculateNTranslocation;
    CalculateNDemandNDeficiency;
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
        else {The pool is required for compensation}
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


// N harvest index
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

// Calculate the N-deficit factor to identify phases of N deficiency
  if (NDemandGrowth.v > 0) then
    N_Def.v := min(1,(TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.v/10)/NDemandGrowth.v)
  else
    N_Def.v := 1;

  if Assigned(SoilMinMod) and (SoilMinMod is TAbstractSoilMin) and not harvested then TAbstractSoilMin(SoilMinMod).AddResidues(C_Dead.c,N_Dead.c);


  if (EC.v >= 90) and (DateHarvestWasSet = false) then begin
    HarvestDate.v := GlobTime.v;
    DateHarvestWasSet := true;
  end;

  //N_Residues.v := 0.21*NShoot.v;          // dneukam: commented out on 2021-10-26
  //C_Residues.v := N_Residues.v * 95;
  N_Residues.v := NRoot.v + NStem.v + NLeaf.v+NPodWall.v;   // dneukam: added on 2021-10-26
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


function TOSRGrowth.getExtCoeffPAR: real;     // Function that calculates the extinction coefficient
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

procedure TOSRGrowth.CalcDMLossFrostShading;
begin
  // Dry-matter reduction caused by frost and shading senescence
  if (DMDeadSh.c > 0) then
  begin
    DMPlant.c := DMPlant.c - DMSh.c;
    DMShoot.c := DMShoot.c - DMSh.c;
    DMLeaf.c := max(-DMLeaf.v, DMLeaf.c - DMSh.c);
  end;
  if (DMDeadW.c > 0) then
  begin
    {DMPlant.c := DMPlant.c - DMDeadW.c;
      DMShoot.c := DMShoot.c - ((DMDeadW.c)*(DMShoot.v/DMPlant.v));
      DMLeaf.c := DMLeaf.c - ((DMDeadW.c)*(DMLeaf.v/DMPlant.v));
      DMStem.c := DMStem.c - ((DMDeadW.c)*(DMStem.v/DMPlant.v));
      DMRoot.c := DMRoot.c - ((DMDeadW.c)*(DMRoot.v/DMPlant.v));}
    DMPlant.c := DMPlant.c - DMDeadW.c;
    DMShoot.c := DMShoot.c - DMDeadW.c;
    DMLeaf.c := DMLeaf.c - ((DMDeadW.c) * (DMLeaf.v / DMShoot.v));
    DMStem.c := DMStem.c - ((DMDeadW.c) * (DMStem.v / DMShoot.v));
  end;
  {if (DMDeadN.c > 0) then begin
      DMPlant.c := DMPlant.c - DM_N.c;
      DMShoot.c := DMShoot.c - DM_N.c;
      DMLeaf.c := max(-DMLeaf.v, DMLeaf.c - DM_N.c);
    end;}
  if (DMDeadW.c > 0) then
  begin
    DMDeadLeafW.c := ((DMDeadW.c) * (DMLeaf.v / DMShoot.v));
    DMDeadStemW.c := ((DMDeadW.c) * (DMStem.v / DMShoot.v));
  end
  else
  begin
    DMDeadLeafW.c := 0;
    DMDeadStemW.c := 0;
  end;
    // Dry-matter translocation caused by shading senescence
    if (DMDeadSh.c > 0) then
      DMTransLeaf.c := DMShTrans.c {+ DMNTrans.c}
    else
      DMTransLeaf.c := 0;

    DMTrans.c := DMTransLeaf.c + DMTransStem.c;


    DMDead.c := DMDeadW.c + DMDeadSh.c; {+ DMDeadAge.c + DMDeadN.c} // Dead dry matter
    C_Dead.c := (DMDead.c * 10) * 0.45;

end;

procedure TOSRGrowth.CalcConversionLosses;
begin
  // Conversion loss caused by oil formation
  ConversionLoss.v := (DMSeed.c) * {* (Oilconc.v/100)} 0.4;
  // changed 2019-01-17 UB
  DMSeed.c := DMSeed.c - ConversionLoss.v;
  DMGen.c := DMGen.c - ConversionLoss.v;
  DMShoot.c := DMShoot.c - ConversionLoss.v;
  DMPlant.c := DMPlant.c - ConversionLoss.v;
  DMRoot.c := fRoot.v * DMPlant.c;
  SumConversionLoss.c := ConversionLoss.v;
end;

procedure TOSRGrowth.CalculateIntermediateVariables;
begin
  // Intermediate calculations
  // Shoot dry matter at the start of flowering
  if (EC.v <= 60) then
    DMShoot_OF.c := DMShoot.c
  else
    DMShoot_OF.c := 0;
  // Shoot dry-matter accumulation since the start of flowering
  if (EC.v > 60) then
  begin
    DMShoot_nB.c := DMShoot.c;
    DMShoot_nB_pot.c := DMShoot.c / fW.v;
  end
  else
  begin
    DMShoot_nB.c := 0;
  end;
  // N uptake until the end of the calendar year
  if (DayofYear.v >= 217) and (DayofYear.v <= 365) then
    NUptake_vW.c := NUptake_act.c
  else
    NUptake_vW.c := 0;
  // N uptake after flowering
  if (EC.v >= 70) then
    NUptake_aF.c := NUptake_act.c
  else
    NUptake_aF.c := 0;
end;

procedure TOSRGrowth.CalculateNDemandNDeficiency;
begin
  // N demand and compensation for N deficiency and surplus
  { See: Compensation for N deficiency and surplus.pdf}
  // N demand for growth (NDemandGrowth) and compensation for N deficits (NDemandDeficit)
  NDemandGrowth.v := max(0, max(0, NLeaf.c) + max(0, NStem.c) + max(0, NRoot.c) + max(0, (NGen.c - NTrans.c)));
  NDemandDeficit.v := (DMLeaf.v * NcLeaf.v / 100 - NLeaf.v) + (DMGen.v * NcGen.v / 100 - NGen.v) + (DMStem.v * NcStem.v / 100 - strNStem.v) + (DMRoot.v * NcRoot.v / 100 - strNRoot.v);
  NDemandDeficitLeaf.v := (DMLeaf.v * NcLeaf.v / 100 - NLeaf.v);
  NDemandDeficitStem.v := (DMStem.v * NcStem.v / 100 - strNStem.v);
  NDemandDeficitRoot.v := (DMRoot.v * NcRoot.v / 100 - strNRoot.v);
  NDemandDeficitGen.v := (DMGen.v * NcGen.v / 100 - NGen.v);
  // Potential N uptake
  NUptakeRate_pot.v := max(0, NDemandGrowth.v + NDemandDeficit.v);
  NUptake_pot.c := max(0, NUptakeRate_pot.v);
end;

procedure TOSRGrowth.CalculateNTranslocation;
begin
  // N translocation
  // (65% of the N currently present in leaves is translocated)
  {Malagoli et al. 2005: Dynamics of Nitrogen Uptake and Mobilization in
     Field-grown Winter Oilseed Rape (Brassics napus) from Stem Extension
     to Harvest. I. Global N Flows between Vegetative and Reproductive Tissues
     in Relation to Leaf Fall and their Residual N. Annals of Botany 95, 853-861.}
  if (DMDeadW.c = 0) and (NLeaf.c < 0) then
    NTransLeaf.c := min(NLeaf.v, -NLeaf.c) * pCnTrans.v
  else
    NTransLeaf.c := 0;
  if (NStem.c < 0) and (DMDeadW.c = 0) then
    NTransStem.c := min(NStem.v, -NStem.c)
  else
    NTransStem.c := 0;
  if (NRoot.c < 0) and (DMDeadW.c = 0) then
    NTransRoot.c := min(NRoot.v, -NRoot.c)
  else
    NTransRoot.c := 0;
  potNTrans.c := NTransLeaf.c + NTransStem.c + NTransRoot.c;
  // N pool and N translocation to pods
  if (NGen.c <= potNTrans.c) then
    if (EC.v < 80) then
    begin
      potNPool.c := potNTrans.c - NGen.c;
      // Create an N pool for N translocated before pod development; location of this pool remains to be clarified
      NPool.c := max(0, min((((DMStem.v * 6 / 100) - strNStem.v) + ((DMRoot.v * 5.5 / 100) - strNRoot.v)) - NPool.v, potNPool.c));
      NTrans.c := max(0, NGen.c);
      // N amount translocated to pods
      NDead.c := NDead.c + (potNPool.c - NPool.c);
    end
    else
    begin
      potNPool.c := 0;
      NPool.c := 0;
      NTrans.c := NGen.c;
      NDead.c := potNTrans.c - NTrans.c;
    end
  else
  begin
    potNPool.c := 0;
    NTrans.c := potNTrans.c;
    NPool.c := min(0, max(-NPool.v, -(NGen.c - NTrans.c)));
    // Empty the N pool when pod N increases rapidly
    NTrans.c := max(0, min(NGen.c, NTrans.c - NPool.c));
  end;
  // N pools in stems and roots
  poolNStem.c := max(-poolNStem.v, min((DMStem.v * 6 / 100) - NStem.v, NPool.c));
  poolNRoot.c := NPool.c - poolNStem.c;
  // Structural N in stems and roots
  strNStem.c := max(-strNStem.v, NStem.c);
  strNRoot.c := max(-strNRoot.v, NRoot.c);
end;

procedure TOSRGrowth.CalculateOrganNuptakerates;
begin
  // Calculate organ N amounts from dry matter and N concentration
  // Leaves
  if DMLeaf.v <= 0 then
    NLeaf.c := 0
  else if DMLeaf.c > 0 then
    NLeaf.c := max(0, (DMLeaf.c * (NcLeaf.v + DMLeaf.v * dNcLeaf.v / DMLeaf.c) / 100))
  else if DMLeaf.c < 0 then
    NLeaf.c := DMLeaf.c * NLeaf.v / DMLeaf.v
  else
    NLeaf.c := 0;
  // N loss caused by frost and shading senescence
  if DMDeadW.c > 0 then
    NDeadW.c := (DMDeadLeafW.c * NcLeaf_act.v / 100) + (DMDeadStemW.c * NcStem_act.v / 100) + (DMDeadRootW.c * NcRoot_act.v / 100)
  else
    // N loss caused by frost senescence
    NDeadW.c := 0;
  if (NLeaf.c < 0) and (DMDeadW.c = 0) then
    NDeadSh.c := -NLeaf.c * (1 - pCnTrans.v)
  else
    NDeadSh.c := 0;
  NDead.c := NDeadW.c + NDeadSh.c;
  N_Dead.c := NDead.c * 10;
  // Stems
  if DMStem.c >= 0 then
    NStem.c := (DMStem.c * NcStem.v + DMStem.v * dNcStem.v) / 100
  else if (DMStem.c < 0) then
  begin
    if DMstem.v > 0 then
      NStem.c := DMStem.c * NStem.v / DMStem.v;
  end;
  // Pods
  if DMGen.c > 0 then
  begin
    NGen.c := max(0, (DMGen.c * (NcGen.v + DMGen.v * dNcGen.v / DMGen.c) / 100));
    NSeed.v := (DMSeed.v * pCnSeed.v) / 100;
    NPodWall.v := max(0.2 * NGen.v, NGen.v - NSeed.v);
    NSeed.v := NGen.v - NPodWall.v;
  end
  else if (DMGen.c < 0) and (DMGen.v > 0) then
  begin
    NGen.c := DMGen.c * NGen.v / DMGen.v;
    NSeed.v := (DMSeed.v * pCnSeed.v) / 100;
    NPodWall.v := max(0.2 * NGen.v, NGen.v - NSeed.v);
    NSeed.v := NGen.v - NPodWall.v;
  end
  else
  begin
    NGen.c := 0;
    NSeed.v := 0;
    NPodWall.v := 0;
  end;
  // Roots
  if DMRoot.v <= 0 then
    NRoot.c := 0
  else if DMRoot.c > 0 then
    NRoot.c := (DMRoot.c * (NcRoot.v + DMRoot.v * dNcRoot.v / DMRoot.c) / 100)
  else if DMRoot.c < 0 then
    NRoot.c := DMRoot.c * NRoot.v / DMRoot.v
  else
    NRoot.c := 0;
end;

procedure TOSRGrowth.CalcMaintainableLAI(var LAIm_ave: Double);
var
  Local_i: Integer;
begin
  // Calculate maintainable LAI (LAIm)
  if (EC.v < 30) then
    if (PARav.v * fTSen.v >= PARmh.v * fTm.v) then
      LAIm.v := 1 / act_k_Leaf.v * log10((PARav.v * fTSen.v) / (PARmh.v * fTm.v))
    else
      LAIm.v := 0
  else if (EC.v >= 60) then
    if (PARav.v * Transkoeff.v * fTSen.v >= PARmf.v * fTm.v) then
      LAIm.v := 1 / act_k_Leaf.v * log10((PARav.v * Transkoeff.v * fTSen.v) / (PARmf.v * fTm.v))
    else
      LAIm.v := 0
  else if (PARav.v * fTSen.v >= PARmf.v * fTm.v) then
    LAIm.v := 1 / act_k_Leaf.v * log10((PARav.v * fTSen.v) / (PARmf.v * fTm.v))
  else
    LAIm.v := 0;
  for Local_i := 9 downto 1 do
    LAImarray[Local_i + 1] := LAImarray[Local_i];
  LAImarray[1] := LAIm.v;
  LAIm_ave := 0;
end;

procedure TOSRGrowth.CalcShootRootGrowth;
begin
  // Dry-matter production as a function of absorbed radiation and LUE,
  // N deficiency, water deficit, temperature response and assimilate translocation
  // Dry-matter production
  DMShoot.c := 0;
  if fDMGrowthOption = InternDM then
  begin
    if (fInitOption = DMCritInit) and (DMShoot.v < DMcrit.v) and (EC.v >= 10) then
    begin
      // Initial phase: temperature-limited exponential growth without radiation
      DMShoot.c := k1.v * DMShoot.v * Teff.v;
      if (DMShoot.v + DMShoot.c) > DMcrit.v then
        DMShoot.c := DMcrit.v - DMShoot.v;
      DMRoot.c := fRoot.v * (1 + fRoot.v) * DMShoot.c;
      DMPlant.c := DMShoot.c + DMRoot.c;
    end;
    if (fInitOption = LAIInit) or (DMShoot.v + DMShoot.c >= DMcrit.v) then
    begin
      // LUE-based growth after DMcrit
      if (fInitOption = DMCritInit) and (DMShoot.v < DMcrit.v) then
        {Dry matter exceeds DMcrit on the current day}
        DMPlant.c := DMPlant.c + (Q.v * LUE.v * fT.v * CO2_factor.v) * (1 - DMShoot.c / (k1.v * DMShoot.v * Teff.v))
      else if (QGen.v > 0) then
      begin
        //            LUEGen.v := LUE.v;
        if (fDroughtOption = DroughtImpact) then
          DMPlant.c := (((QLeaf.v * LUE.v * CO2_factor.v * ((LAILeaf.v * NNILeaf.v + LAIStem.v * NNIStem.v) / (LAILeaf.v + LAIStem.v)) + QGen.v * LUEGen.v * CO2_factor.v * NNIGen.v) * fT.v) * fW.v) + DMTrans.c
        else
          DMPlant.c := (((QLeaf.v * LUE.v * CO2_factor.v * ((LAILeaf.v * NNILeaf.v + LAIStem.v * NNIStem.v) / (LAILeaf.v + LAIStem.v)) + QGen.v * LUEGen.v * CO2_factor.v * NNIGen.v) * fT.v)) + DMTrans.c;
        {DMRoot.c := fRoot.v *  DMPlant.c;
            DMShoot.c :=   DMPlant.c-DMRoot.c;}
        DMShoot.c := DMPlant.c * (1 - fRoot.v);
      end
      else if (EC.v >= 10) then
      begin
        if (fDroughtOption = DroughtImpact) then
          DMPlant.c := ((QLeaf.v * LUE.v * CO2_factor.v * ((LAILeaf.v * NNILeaf.v + LAIStem.v * NNIStem.v) / (LAILeaf.v + LAIStem.v)) * fT.v) * fW.v) + DMTrans.c
        else
          DMPlant.c := ((QLeaf.v * LUE.v * CO2_factor.v * ((LAILeaf.v * NNILeaf.v + LAIStem.v * NNIStem.v) / (LAILeaf.v + LAIStem.v)) * fT.v)) + DMTrans.c;
        {DMRoot.c := fRoot.v *  DMPlant.c;
              DMShoot.c :=   DMPlant.c-DMRoot.c;}
        DMShoot.c := DMPlant.c * (1 - fRoot.v);
      end
      else
      begin
        DMPlant.c := 0;
        DMShoot.c := 0;
      end;
    end;
  end
  else
  begin
    {ExternDM}
    DMShoot.c := DMGrowth_ex.v;
    DMRoot.c := fRoot.v * DMShoot.c / (1 - fRoot.v);
    DMPlant.c := DMShoot.c + DMRoot.c;
  end;
end;

procedure TOSRGrowth.CalcRootFraction;
begin
  if {(EC.v < 30)} (DayofYear.v < 30) then
    maxfRoot.v := fRoot.v;
  // Root growth as a fraction of total growth (Dissertation W. Weymann, Chapter 4, Figure 2)
  if ((DayofYear.v < 30) or (DayofYear.v > 217)) and (EC.v < 30) then
    {fRoot.v := max(0,roots.v*TempSumAuflauf.v + rooti.v)}
    fRoot.v := max(0, rooti.v * power(TempSumAuflauf.v, 2) + roots.v * TempSumAuflauf.v)
  else if (EC.v <= 69) then
    fRoot.v := max(0.05, ((0.05 - maxfRoot.v) / (100 - 0)) * (TempSumRoots.v) + maxfRoot.v)
  else
    {fRoot.v := max(0.05,maxfRoot.v*exp(root_exp.v*TempSumAuflauf.v))}
    fRoot.v := 0.05;
end;

procedure TOSRGrowth.CalcLUE;
begin
  // LUE of vegetative and generative biomass; reduced after BBCH 70 because of senescence, seed development and oil formation
  {The LUE parameters are correspondingly high because they represent effective LUE}
  if (DayofYear.v <= 30) or ((DayofYear.v >= 217) and (EC.v < 30)) then
    LUE.v := LUELeaf.v
  else if (DayofYear.v > 30) and (DayofYear.v <= 60) then
    LUE.v := ((LUE0.v - LUELeaf.v) / (60 - 30)) * (DayofYear.v - 30) + LUELeaf.v
  else if (EC.v > 70) then
    LUE.v := min(LUE.v, max(0.1, ((0.1 - LUE0.v) / 20) * (EC.v - 70) + LUE0.v))
  else
    LUE.v := LUE0.v;
  // LUE of generative biomass
  {Leterme 1985: Modélisation de la croissance et de la production des
       siliques chez le colza d'hiver}
  if (EC.v > 70) then
    LUEGen.v := min(LUEGen.v, max(0.1, ((0.1 - LUEPod.v) / 20) * (EC.v - 70) + LUEPod.v))
  else
    {else
      if (EC.v > 51) and (EC.v < 61)
      LUEGen.v := min(LUEPod.v, max(0.1, ((LUEPod.v - 0.1)/10)*(EC.v-51)+0.1)) }
    LUEGen.v := LUEPod.v;
  // apply scaling factor
  LUE.v := LUE.v * LUEscaling.v;
  LUEGen.v := LUEGen.v * LUEscaling.v;
end;

procedure TOSRGrowth.CalcRadiationUptake;
begin
  // Calculate photosynthetically active radiation and cumulative incident radiation
  PARRad.v := GRad.v * 0.5;
  RadSum.c := PARRad.v;
  // Reflection by the flower layer (up to 30% of incident radiation is reflected or absorbed by the flower layer)
  if (EC.v >= 60) and (EC.v <= 70) then
    if (EC.v <= 65) then
      Transkoeff.v := min(1, ((0.7 - 1) / (65 - 60)) * (EC.v - 60) + 1)
    else
      Transkoeff.v := min(1, ((1 - 0.7) / (70 - 65)) * (EC.v - 65) + 0.7)
  else
    Transkoeff.v := 1;
  // Extinction coefficients of leaves and pods
  if (EC.v > 51) then
    act_k_Leaf.v := 0.8
  else
    act_k_Leaf.v := ExtCoeffPAR;
  // LAI-dependent extinction coefficient during the vegetative phase (master's thesis by K. Krause, 2010: Site-specific analysis of vegetative winter oilseed rape growth)
  act_k_Gen.v := 0.6;
  if (QGen.v > 0) then
  begin
    QLeaf.v := fIntLeaf.v * (PARRAD.v * 86400 / 1000000 - QGen.v) * Transkoeff.v;
  end
  else
  begin
    QLeaf.v := (fIntLeaf.v * PARRAD.v * 86400 / 1000000) * Transkoeff.v;
  end;
  sumQLeaf.c := QLeaf.v;
  // Calculate absorbed radiation for the entire canopy
  if PARRAD.v > 0.0 then
    fInt.v := max(0, min(1, (QLeaf.v + QGen.v) / (PARRAD.v * 86400 / 1000000)))
  else
    fInt.v := 0.0;
  Q.v := fInt.v * (PARRAD.v * 86400 / 1000000);
  sumQ.c := Q.v;
  QT.v := Q.v * fT.v;
  sumQT.c := QT.v;
end;

procedure TOSRGrowth.InitAfterEmergence;
var
  CO2_ppm: Double;
  TT: Double;
begin
  // Andersen et al. 1996: The effects of drought and nitrogen on light interception, growth and yield of winter oilseed rape. Acta Agriculturae Scandinavica Sect. B Soil and Plant Sciences 46, 55-67
  // Emergence and initialisation of LAI, dry matter and N
  if EC.v >= 10 then
  begin
    if (Auflauf.v = 0) and (LAILeaf.v = 0) then
    begin
      Auflauf.v := Globtime.v;
      if (fInitOption = LAIInit) then
      begin
        LAILeaf.v := pIniLAI.v * plants.v / 10000;
        LAIShoot.v := LAILeaf.v;
        DMLeaf.v := DMShoot.v;
        DMStem.v := DMShoot.v * 0.1;
        NcLeaf.v := pCn1Leaf.v;
        NLeaf.v := DMLeaf.v * NcLeaf.v / 100;
        NcStem.v := pCnStem1h.v;
        NStem.v := DMStem.v * NcStem.v;
        NShoot.v := NLeaf.v;
      end;
    end;
    // Calculate fInt separately for vegetative organs and pods
    // Fraction of total incident radiation absorbed, depending on extinction coefficients and area indices
    if fLAIOption = InternLAI then
    begin
      fIntLeaf.v := max(0, 1 - exp(-act_k_Leaf.v * LAILeaf.v));
      fIntGen.v := max(0, 1 - exp(-act_k_Gen.v * LAIGen.v));
    end
    else
      fInt.v := max(0, 1 - exp(-act_k.v * LUE_LAI.v));
    // Drought-stress factor (nonlinear response)
    // Ferreyra 2003: Nonlinear effects of water stress on peanut photosynthesis at crop and leaf scales. Ecological Modelling 168, 57-76
    if (fDroughtOption = DroughtImpact) then
    begin
      fW.v := 1 - power((1 - TransIntRatio.v), pfW.v);
    end
    else
    begin
      fW.v := 1;
      sumQT_TactTpot.c := 0.0;
    end;
    // see https://onlinelibrary.wiley.com/doi/full/10.1111/gcb.13600
    if OptWithCO2.option = 'withco2effect' then
    begin
      CO2_ppm := CO2_ppm_f(GlobTime.v);
      TT := (163 - self.Ex_TMPM.v) / (5 - 0.1 * Ex_TMPM.v);
      CO2_factor.v := ((CO2_ppm - TT) * (350 + 2 * TT)) / ((CO2_ppm + 2 * TT) * (350 - TT));
    end;
    // Calculate absorbed radiation for individual organs
    QGen.v := (fIntGen.v * PARRAD.v * 86400 / 1000000);
    sumQGen.c := QGen.v;
  end;
end;

procedure TOSRGrowth.CalcTempSums;
begin
  // Calculate effective temperature and thermal-time sums (Tb is the base temperature; Tb = 3°C for oilseed rape)
  Teff.v := max(0, TMPM.v - Tb.v);
  TempSum.c := Teff.v;
  if Globtime.v >= SowingDate.v then
    TempSumAussaat.c := Teff.v
  else
    TempSumAussaat.c := 0;
  if (EC.v >= 10) then
    TempSumAuflauf.c := Teff.v
  else
    TempSumAuflauf.c := 0;
  if (EC.v >= 70) then
    TempSumPodGrowth.c := Teff.v
  else
    TempSumPodGrowth.c := 0;
  if (EC.v <= 65) then
    FullFlower.v := Globtime.v;
  if (EC.v >= 80) then
    TempSumSeed.c := Teff.v
  else
    TempSumSeed.c := 0;
  if (EC.v > 51) then
    TempSumLeafLoss.c := Teff.v
  else
    TempSumLeafLoss.c := 0;
  if ((DayofYear.v > 30) and (DayofYear.v < 150)) then
    TempSumRoots.c := Teff.v
  else
    TempSumRoots.c := 0;
  // Negative thermal time (frost senescence)
  if Assigned(SnowModel) then
  begin
    if SnowModel.Zs.v > CropHeight.v then
      Tminus.v := min(0, SnowModel.Tsf.v)
    else if Cropheight.v > 0 then
      Tminus.v := min(0, (SnowModel.Tsf.v * SnowModel.Zs.v + TMPM.v * (CropHeight.v - SnowModel.Zs.v)) / CropHeight.v)
    else
      Tminus.v := 0;
  end
  else
    Tminus.v := min(0, TMPM.v);
  if EC.v >= 10 then
    TempSumMinus.c := -Tminus.v;
  // Temperature correction factor for dry-matter production
  if TMPM.v < Ct1.v then
    fT.v := 0
  else if TMPM.v <= Ct2.v then
    fT.v := (TMPM.v - Ct1.v) / (Ct2.v - Ct1.v)
  else if TMPM.v <= Ct3.v then
    fT.v := 1
  else if TMPM.v <= Ct4.v then
    fT.v := (Ct4.v - TMPM.V) / (Ct4.v - Ct3.v)
  else
    fT.v := 0;
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