/// <summary>
/// Module for leaf area development and senescence in wheat crops.
/// Authors:Arne Ratjen, Henning Kage & Agronomy Group, University of Kiel
/// First edited: x.x.2003
/// Last edited: 02.08.25
/// <References>
/// <item>Ratjen, A.M. (2012). Refined N-Fertilization of Winter Wheat: A model supported approach combining statistical and mechanistic components.
/// PhD. thesis, Univ. Kiel.  https://www.pflanzenbau.uni-kiel.de/de/publikationen/dissertationen/dissertationen-als-pdf/dissertation-ratjen-2013.pdf</item>
/// <item>Ratjen, A.M., Kage, H., 2013. Is mutual shading a decisive factor for differences in overall canopy specific leaf area of winter wheat crops?
/// Field Crop. Res. 149, 338–346. https://doi.org/10.1016/j.fcr.2013.05.015.</item>
/// <item>Ratjen, A.M., Lemaire, G., Kage, H., Plénet, D., Justes, E., 2018. Key variables for simulating leaf area and N status: Biomass based relations versus phenology driven approaches.
/// Eur. J. Agron. 100, 110–117. https://doi.org/10.1016/j.eja.2018.04.008.</item>
/// <item> Ritchie et al. : https://nowlin.css.msu.edu/wheat_book/CHAPTER2.html</item>
/// </References>
/// </summary>

unit UHumeWheatLeafArea;

interface

uses
  UMod,
  UState,
  // vcl.Dialogs,
  SysUtils,
  UHumeWheatDryMatter;

const
  MaxLeafNumber = 25;

type
  /// <summary>
  /// Type for senescence type
  /// </summary>
  TSenescence = (cwt3, concentration);

  /// <summary>
  /// Type 4 leaf layers
  /// </summary>
  TnLeafLayer = 1 .. 4;

  /// <summary>
  /// Module for leaf area development and senescence
  /// </summary>
  THumeWheatLeafArea = class(TSubmodel)
  private
    p5_: real;
    /// senescence type either cwt3 (Ceres Wheat 3) or concentration
    fSenescence: TSenescence;

    /// array for calculation of average transpiration interception ratio over 10 days
    avTransIntRatio_arr: array [1 .. 10] of real;
    /// private field for optional use of age dependent leaf senescence
    fUseAgeDependentLeafSenescence: boolean;

    /// private field for optional use of light dependent leaf senescence
    fUseLightDependentLeafSenescence: boolean;

    /// private field for optional use of drought dependent leaf senescence
    fUseDroughtDependentLeafSenescence: boolean;
    procedure SetLaiLayers;
    procedure CalcSingleLeafGrowth;
    procedure CalcLeafNumberOnMainStem;
    procedure SetSingleLeafGrowthRatesToZero;
    procedure InitializeLeafAreaOfFirstLeafAtEmergence;
    procedure SumUpSingleLeafAreas;
    procedure CalcCERESAgeDependenLeafSenescence(var PLALR_a: real);
    procedure CalcNdependentLeafSenescence(var PLALR_n: real);
    procedure CalcLightDependendLeafSenescence(var PLALR_l: real);
    procedure CalcDroughtDependentLeafSenescence(var PLALR_d: real);
    procedure Calc_rc(exLAI: real; var ro: Extended; Temp_: real;
      var rc: Extended);
    procedure Calc_pETP(ro: Extended; rc: Extended; var pETP_: Extended;
      Net_beam_: real; Sat_def_: real; ra_: real; delta_: real; gamma_: real);
    procedure CalcInterception(int_stor_: Extended; exLAI: real; PTI: Extended;
      var interception_: Extended);
    procedure CalcEvenTransIntRatio;
    procedure CalcRadiationAverage;
  protected
    // ----------------
    fDroughtImpact: TDroughtImpact;
    // ----------------
    function s_LAI(Temp_, Sat_def_, Net_beam_, delta_, gamma_, ra_, actTrans_,
      exLAI: real): real;
    function calcPotSLA(Wleaf, dWleaf, BBCH, SLA_old: real): real;
    function calcGAI(EC, LAI: real): real;
    procedure setleaf_arr(PLALR_: real);
    procedure calcSenescence;
  public

    // --------------------------------------------------------------------
    /// senescence rates leaf area of individual leaves
    senratesLA: array [1 .. MaxLeafNumber] of real;

    /// senescence rates dry matter of individual leaves
    senratesDM: array [1 .. MaxLeafNumber] of real;

    /// maximum LAI simulated
    LAImax: TVar;
    /// GPLA is the plant green leaf area (PLA - SENLA) [cm2/plant]
    GPLA: TVar;
    /// Leaf number of the primary tiller [n]
    LN_: TVar;
    /// The rate of expansion of leaf area on one plant [cm2/day]
    PLAG: TVar;
    /// plant leaf area growth rate on the main stem (PLAGMS)
    PLAGMS: TVar;
    /// Plant leaf area loss rate [cm2/(plant*d)]
    PLALR: TVar;
    /// Leaf area growth rate of single leaves
    PLSCGR: array [1 .. MaxLeafNumber] of TVar;

    /// source limited leaf growth rate
    V1: TVar;

    /// sink limited leaf growth rate
    V2: TVar;

    /// green area index
    GAI: TVar;

    /// average specific leaf area of canopy [square cm/g]
    potSLA: TVar;

    /// average specific leaf area of canopy [square cm/g]
    avSLA: TVar;

    /// ten day average irradiation (I)
    avIcrop: TVar;

    /// age induced pot. leaf senescence rate
    PLALR_a: TVar;
    /// drought induced pot. leaf senescence rate
    PLALR_d: TVar;
    /// pot. leaf senescence rate induced by N limitation (during grain filling)
    PLALR_n: TVar;
    /// low radiation induced leaf senescence
    PLALR_l: TVar;

    /// Leaf area index [m2/m2]
    LAI: TState;
    /// Plant leaf area  [cm2/plant]
    PLA: TState;
    /// Leaf area of single leaves
    PLSC: array [1 .. MaxLeafNumber] of TState;
    // ///  Leaf weight of single leaves
    // PL_weight   : array[1..MaxLeafNumber] of TState;
    /// Area of leaf that senesces from a tiller on a given day - [cm2/d]
    SENLA: TState;
    /// cumulative phyllochrons since emergence [-]
    CUMPH: TState;
    /// cumulative degree days during istage 5
    SUMDTT5: TState;

    // Parameters
    /// maximum senescence rate  [cm2/(plant*d)]
    maxPLALR: TPar;
    /// intercept specific leaf area due to shading [cm2/g]
    aSLA: TPar;
    /// slope specific leaf area due to shading [cm2/(g*LAI)]
    bSLA: TPar;
    /// initial and maximum SLA [cm2/g]
    maxSLA: TPar;
    /// Parameter for leaf senescence between ISTAGE 2 and 4
    PSENLeaf1: TPar;
    /// Parameter for leaf senescence
    PSENLeaf2: TPar;
    fGAI: TPar;

    // External Variables
    SLN: TExternV;
    /// N content of leaves per m2
    NLeaf_m2: TExternV;
    /// growth rate of leaves (g/pl/d)
    GROLF: TExternV;
    // /// Daily stem growth  [g/(plant.d)]
    // GROSTM      : TExternV;
    /// integer growth stage according to ceres
    ISTAGE: TExternV;
    /// Parameter or length of grain filling period
    P5: TExternV;
    /// number of plants (1/m2)
    plants: TExternV;
    // // Soil Water deficit factor (Tact/Tpot)
    // SWDF1       : TExternV;
    // // termal developmental units
    // TDU         : TExternV;
    /// mean day temperature
    TMPM: TExternV;
    /// minimum day temperature
    TMPMN: TExternV;
    /// maximum day temperature
    TMPMX: TExternV;
    // TI          : TExternV;   // increase of tiller number (1/d)
    // TILN        : TExternV;   // tiller number per plant
    // TPSM        : TExternV;   // tiller number per m2
    /// ec stage of crop
    EC: TExternV;
    /// Senescence rate of leaf dry matter (total) (g/pl/d)
    SENL: TExternV;
    /// Phyllochronintervall [�d]
    Phint: TExternV;
    /// Tagestemperatur >=0 zur Basistemperatur
    TSumInc: TExternV;
    PAR: TExternV;
    /// k for PAR
    kPAR: TExternV;
    /// array of average radiation for last 10 days [MJ/m²/d]
    Icrop: Array [1 .. 10] of real;
    // Options
    OptDroughtimpact: TOption;
    OptNSenescenceType: TOption;
    UseAgeDependentLeafSenescence: TOption;
    UseLightDependentLeafSenescence: TOption;
    UseDroughtDependentLeafSenescence: TOption;
    // --------------------------------------------------------------------
    /// critical radiation value for leaf area index
    Icrit: TPar;
    /// parameter for SLA calculation
    f1_SLA: TPar;
    /// parameter for SLA calculation
    f2_SLA: TPar;
    /// PAR transmission coefficient
    kTransPAR: TPar;
    // critSLN:   TPAR; // APSIM meinke 1998, 107
    /// Minium observed 95er

    critSLNtot: TPar;

    /// transpiration ratio critical
    TRcrit: TPar;
    relLayerM_Int: array [1 .. 3] of TPar;
    relLayerA_Int: array [1 .. 3] of TPar;
    relLayerM_S: array [1 .. 3] of TPar;
    relLayerA_S: array [1 .. 3] of TPar;

    sumLAL: TVar;
    sumMLAL: TVar;
    fdsen: TVar;

    /// sum of single leaf areas
    sumPLsc: TVar;
    /// green leaf mass of layer
    MLAL: array [1 .. 4] of TVar;
    /// Leaf area of a lamina i
    LAL: array [1 .. 4] of TVar;
    DSsen: TVar;
    LLsen: TVar;
    Nsen: TVar;

    /// smoothed transpiration interception ratio
    evenTransIntRatio: TVar;

    /// potential transpiration [mm/d]
    PotTrans: TExternV;

    /// Leaf dry matter per m2 [g/m2]
    LFWT_m2: TExternV;

    /// Leaf dry matter per plant [g/plant]
    LFWT_pl: TExternV;

    /// interception rate [mm/d]
    interception: TExternV;

    /// Actual transpiration [mm/d]
    ActTrans: TExternV;

    /// Global radiation [MJ/m2/d]
    GlobRad: TExternV;

    /// extinction coefficient of global radiation [-]
    exk_GlobRad: TExternV;

    /// ratio of actual to potential transpiration [-]
    TransRatio: TExternV;

    /// ratio of actual to potential transpiration interception [-]
    TransIntRatio: TExternV;

    /// net rainfall (rainfall - interception) [-]
    NetRain: TExternV;

    /// radiation intercepted by the canopy [W/m2]
    Rad_Int: TExternV;

    /// EC stage at which leaf growth stops
    EC_lgend: TExternV;
    // NStoragepool_pl: TExternV;
    NcLAL: array [1 .. 4] of TExternV;

    /// areodynamic resistance [-]
    ra: TExternV;

    /// Saturation deficit [-]
    Sat_def: TExternV;

    /// air pressure [-]
    P: TExternV;

    /// specific interception capacity [mm/m2]
    sic: TExternV;

    /// interception storage [-]
    int_stor: TExternV;

    /// precipitation [mm/d]
    rain: TExternV;

    /// canopy resistance under well watered conditions [-]
    rc0: TExternV;
    // Ncmob:    TExternV;
    gamma: real;
    delta: real;
    LAIs: real;
    PARi: array [1 .. 4] of TState;
    /// amount of PAR incident on the surface of lamina i

    /// method for creating all variables, states and parameters
    procedure createAll; override;

    /// method for initializing the module
    procedure Init(var GlobMod: TMod); override;

    /// method for calculating all rates
    procedure CalcRates; override;

    /// method for integrating all state variables
    procedure Integrate; override;

  published
    // -----------------------------------
    Property Var_GPLA: TVar read GPLA write GPLA;
    Property Var_LN_: TVar read LN_ write LN_;
    Property Var_PLAG: TVar read PLAG write PLAG;
    Property Var_PLAGMS: TVar read PLAGMS write PLAGMS;
    Property Var_PLALR: TVar read PLALR write PLALR;
    Property Var_V1: TVar read V1 write V1;
    Property Var_V2: TVar read V2 write V2;
    // Property Par_CLG : TPar read CLG write CLG;
    Property St_LAI: TState read LAI write LAI;
    Property St_PLA: TState read PLA write PLA;
    Property St_SENLA: TState read SENLA write SENLA;
    Property St_CUMPH: TState read CUMPH write CUMPH;
    // Parameters
    Property Ex_GROLF: TExternV read GROLF write GROLF;
    // Property Ex_GROSTM : TExternV read GROSTM write GROSTM;
    Property Ex_ISTAGE: TExternV read ISTAGE write ISTAGE;
    Property Ex_Phint: TExternV read Phint write Phint;
    Property Ex_P5: TExternV read P5 write P5;
    Property Ex_plants: TExternV read plants write plants;
    // Property Ex_SWDF1 : TExternV read SWDF1 write SWDF1;
    // Property Ex_TDU : TExternV read TDU write TDU;
    Property Ex_TMPM: TExternV read TMPM write TMPM;
    Property Ex_TMPMN: TExternV read TMPMN write TMPMN;
    Property Ex_TMPMX: TExternV read TMPMX write TMPMX;
    Property Ex_TSumInc: TExternV read TSumInc write TSumInc;
    property opt_DroughtImpact: TDroughtImpact read fDroughtImpact
      write fDroughtImpact;
    // -----------------------------------
    property Ex_rc0: TExternV Read rc0 Write rc0;
    property Ex_rain: TExternV Read rain Write rain;
    property Ex_sic: TExternV Read sic Write sic;
    property Ex_Sint_stor: TExternV Read int_stor Write int_stor;
    property Ex_P: TExternV Read P Write P;
    property Ex_Sat_def: TExternV Read Sat_def Write Sat_def;
    property Ex_ra: TExternV Read ra Write ra;
    property Ex_Rad_Int: TExternV Read Rad_Int Write Rad_Int;
    property Ex_NetRain: TExternV Read NetRain Write NetRain;
    property Ex_TransRatio: TExternV Read TransRatio Write TransRatio;
    property Ex_TransIntRatio: TExternV Read TransIntRatio Write TransIntRatio;
    property Ex_exk_GlobRad: TExternV Read exk_GlobRad Write exk_GlobRad;
    property Ex_ActTrans: TExternV Read ActTrans Write ActTrans;
    property Ex_interception: TExternV Read interception Write interception;
    property Ex_PotTrans: TExternV Read PotTrans Write PotTrans;
  end;

procedure Register;

implementation

uses
  Math, Classes;

procedure THumeWheatLeafArea.createAll;
var
  i: integer;
begin
  inherited createAll;
  // -------------------------------------------------------
  VarCreate('LAImax', '[]', 0, true, LAImax, ' maximum LAI simulated');
  VarCreate('GAI', '[]', 0, true, GAI);
  VarCreate('avSLA', '[square cm/g]', 0, true, avSLA);
  VarCreate('GPLA', '[cm2/plant]', 0, true, GPLA,
    'GPLA is the plant green leaf area (PLA - SENLA)');
  VarCreate('LN_', '[n]', 0, true, LN_, 'Leaf number of the primary tiller');
  VarCreate('PLAG', '[cm2/day]', 0, true, PLAG,
    'The rate of expansion of leaf area on one plant');
  VarCreate('PLAGMS', '', 0, true, PLAGMS,
    'plant leaf area growth rate on the main stem (PLAGMS)');
  VarCreate('PLALR', '[cm2/(plant*d)]', 0, true, PLALR,
    'Plant leaf area loss rate');

  VarCreate('PLALR_a', '[cm2/(plant*d)]', 0, true, PLALR_a,
    'age induced pot. leaf senescence rate (according to CeresWheat3)');
  VarCreate('PLALR_d', '[cm2/(plant*d)]', 0, true, PLALR_d,
    'drought induced pot. leaf senescence rate');
  VarCreate('PLALR_n', '[cm2/(plant*d)]', 0, true, PLALR_n,
    'pot. leaf senescence rate induced by N limitation (during grain filling)');
  VarCreate('PLALR_l', '[cm2/(plant*d)]', 0, true, PLALR_l,
    'low radiation induced leaf senescence');

  for i := 1 to MaxLeafNumber do
    if i < 10 then
      VarCreate('PLSCGR__' + inttostr(i), '[cm2/plant]', 0, true, PLSCGR[i],
        'Leaf area growth rate of single leaves')
    else
      VarCreate('PLSCGR_' + inttostr(i), '[cm2/plant]', 0, true, PLSCGR[i]);
  VarCreate('V1', '', 0, true, V1, 'source limited leaf growth rate');
  VarCreate('V2', '', 0, true, V2, 'sink limited leaf growth rate');
  // VarCreate('fSLAWR', '',0, true, fSLAWR);
  VarCreate('potSLA', '', 0, true, potSLA,
    'average specific leaf area of canopy');
  VarCreate('avIcrop', '', 0, true, avIcrop, 'Average radiation over 10 days');

  StateCreate('LAI', '[m2/m2]', 0, true, LAI, 'Leaf area index');
  StateCreate('PLA', '[cm2/plant]', 0, true, PLA, 'Plant leaf area');
  for i := 1 to MaxLeafNumber do
  begin
    if i < 10 then
      StateCreate('PLSC__' + inttostr(i), '[cm2/plant]', 0, true, PLSC[i],
        'Leaf area of single leaves')
    else
      StateCreate('PLSC_' + inttostr(i), '[cm2/plant]', 0, true, PLSC[i],
        'Leaf area of single leaves');
  end;
  StateCreate('SENLA', '[cm2/d]', 0, true, SENLA,
    'Area of leaf that senesces from a tiller on a given day');
  StateCreate('CUMPH', '[-]', 0, true, CUMPH,
    'cumulative phyllochrons since emergence');
  StateCreate('SUMDTT5', '[degree days]', 0, true, SUMDTT5,
    'cumulated temperature sum during ISTAGE 5 (grain filling)');

  // Parameters
  ParCreate('fGAI', '[-]', 0.2, fGAI, 'LAI->GAI (94er 2004)');
  ParCreate('maxPLALR', ' %LAI_max', 5, maxPLALR, 'maximum senescence rate');
  maxPLALR.DocuWebLink :=  'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#nitrogen-stress-nitrogen-induced-leaf-senescence';
  ParCreate('aSLA', '[cm2/g]', 136.69, aSLA,
    'Intercept of function describing effect of shading on average specific leaf area');
  aSLA.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#calculation-of-slapot';
  ParCreate('bSLA', '[cm2/(g*LAI)]', 14.93, bSLA,
    'Slope of function describing effect of shading on average specific leaf area');
  bSLA.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#calculation-of-slapot';
  ParCreate('maxSLA', '[cm2/g]', 250, maxSLA,
    'start values of SLA after emgergence');
  maxSLA.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#calculation-of-slapot';
  ParCreate('PSENLeaf1', '[-]', 0.0003, PSENLeaf1,
    'Parameter for leaf senescence');
  PSENLeaf1.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#leaf-senescence-in-later-stages-bbch-31-71';
  ParCreate('PSENLeaf2', '[-]', 0.0006, PSENLeaf2,
    'Parameter for leaf senescence');
  PSENLeaf2.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#leaf-senescence-in-later-stages-bbch-31-71';
  ParCreate('Icrit', '[MJ/(m2*d)]', 0.2, Icrit,
    'critical radiation value for leaf area index');
  ParCreate('f1_SLA', '[-]', -1.1237, f1_SLA,
    'parameter for SLA calculation, change of ');
  f1_SLA.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#calculation-of-slapot';
  ParCreate('f2_SLA', '[-]', 0.3, f2_SLA, 'parameter for SLA calculation');
  f2_SLA.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#calculation-of-slapot';
  ParCreate('kTransPAR', '[-]', 0.7, kTransPAR, 'PAR transmission coefficient');
  ParCreate('critSLNtot', '[g N/m²]', 0.8, critSLNtot,
    'critical SLN value for leaf senescense');
  critSLNtot.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#nitrogen-stress-nitrogen-induced-leaf-senescence';


  ParCreate('TRCrit', '[-]', 0.8, TRcrit, 'transpiration ratio critical');
  TRcrit.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#drought-stress';
  ExternVCreate('sln', 'g/m2 leaf', statefield, SLN, 'Specific leaf N content');
  ExternVCreate('NLeaf_m2', 'g/m2', statefield, NLeaf_m2,
    'N content of leaves per m2 ground');
  ExternVCreate('GROLF', '[g/(pl*d)]', statefield, GROLF,
    'growth rate of leaves');
  ExternVCreate('ISTAGE', '', statefield, ISTAGE,
    'integer growth stage according to ceres');
  ExternVCreate('P5', '[-]', statefield, P5,
    'Parameter or length of grain filling period');
  ExternVCreate('plants', '', statefield, plants, 'number of plants (1/m2)');
  ExternVCreate('TMPM', '[°C]', statefield, TMPM, 'mean day temperature');
  ExternVCreate('TMPMN', '[°C]', statefield, TMPMN, 'minimum day temperature');
  ExternVCreate('TMPMX', '[°C]', statefield, TMPMX, 'maximum day temperature');
  ExternVCreate('EC', '', statefield, EC, 'ec stage of crop');
  ExternVCreate('SENL', '', ratefield, SENL,
    'Senescence rate of leaf dry matter (total)');
  ExternVCreate('Phint', '[°Cd]', statefield, Phint, 'Phyllochronintervall');
  ExternVCreate('TSumInc', '', statefield, TSumInc,
    'Daily increment of temperature sum');
  ExternVCreate('kPAR', '', statefield, kPAR, 'k for PAR');
  ExternVCreate('PAR', '[MJ/m²*d]', statefield, PAR, 'PAR');
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerA_Int' + inttostr(i), '[-]', 0.2976, relLayerA_Int[i]);
    if i = 2 then
      ParCreate('relLayerA_Int' + inttostr(i), '[-]', 0.2562, relLayerA_Int[i]);
    if i = 3 then
      ParCreate('relLayerA_Int' + inttostr(i), '[-]', 0.2404, relLayerA_Int[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerA_S' + inttostr(i), '[-]', 0.0087, relLayerA_S[i]);
    if i = 2 then
      ParCreate('relLayerA_S' + inttostr(i), '[-]', 0.0187, relLayerA_S[i]);
    if i = 3 then
      ParCreate('relLayerA_S' + inttostr(i), '[-]', -0.0018, relLayerA_S[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerM_Int' + inttostr(i), '[-]', 0.2916, relLayerM_Int[i]);
    if i = 2 then
      ParCreate('relLayerM_Int' + inttostr(i), '[-]', 0.2694, relLayerM_Int[i]);
    if i = 3 then
      ParCreate('relLayerM_Int' + inttostr(i), '[-]', 0.2504, relLayerM_Int[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerM_S' + inttostr(i), '[-]', 0.0168, relLayerM_S[i]);
    if i = 2 then
      ParCreate('relLayerM_S' + inttostr(i), '[-]', 0.0161, relLayerM_S[i]);
    if i = 3 then
      ParCreate('relLayerM_S' + inttostr(i), '[-]', -0.0089, relLayerM_S[i]);
  end;
  for i := 1 to 4 do
  begin // Vier Blattetagen
    VarCreate('MLAL' + inttostr(i), '[g/m2]', 0, true, MLAL[i]);
  end;
  for i := 1 to 4 do
  begin // Vier Blattetagen
    VarCreate('LAL_' + inttostr(i), '[m2/m2]', 0, true, LAL[i]);
  end;
  VarCreate('evenTransIntRatio', '[-]', 1, False, evenTransIntRatio,
    'mean of 10 days TransintRatio');
  VarCreate('sumplsc', '[cm2/pl]', 0, False, sumPLsc,
    'sum of single leaf areas');
  VarCreate('sumLAL', '[m2/m2]', 0, False, sumLAL,
    'sum of leaf area of all leaves');
  VarCreate('sumMLAL', '[g/m2]', 0, False, sumMLAL,
    'sum of green leaf mass of all leaves');
  VarCreate('DSsen', 'cm2/(plant*d)', 0, False, DSsen,
    'daily senescence rate of leaf area');
  VarCreate('Nsen', 'cm2/(plant*d)', 0, False, Nsen,
    'fraction of senescent leaf area caused by N limitation');
  VarCreate('LLsen', 'cm2/(plant*d)', 0, False, LLsen,
    'fraction of senescent leaf area caused by light limitation');
  VarCreate('fdsen', '[]', 0, False, fdsen,
    'fraction of senescent leaf area caused by drought');
  // ExternVcreate('Ncmob', '[-]', stateField, Ncmob, 'N content of mobile pool');
  ExternVCreate('EC_lgend', '[-]', statefield, EC_lgend);
  // ExternVcreate('NStoragepool_pl', '[g/plant]', stateField, NStoragepool_pl);
  ExternVCreate('LFWT_m2', '[g/m2]', statefield, LFWT_m2, 'Leaf DM per m2');
  ExternVCreate('LFWT_pl', '[g/pl]', statefield, LFWT_pl, 'Leaf DM per plant');
  ExternVCreate('PotTrans', '[mm.d-1]', statefield, PotTrans,
    'Potential transpiration');
  ExternVCreate('ActTrans', '[mm.d-1]', statefield, ActTrans,
    'Actual transpiration');
  ExternVCreate('interception', '[-]', statefield, interception,
    'Interception');
  ExternVCreate('GlobRad', '[W.m-2]', statefield, GlobRad, 'Global radiation');
  ExternVCreate('exk_GlobRad', '[-]', statefield, exk_GlobRad,
    'Extinction coefficient of global radiation');
  ExternVCreate('SIC', '[mm.m2.m2]', statefield, sic,
    'Specific interception capacity');
  ExternVCreate('TransRatio', '[-]', statefield, TransRatio,
    'Transpiration ratio');
  ExternVCreate('TransIntRatio', '[-]', statefield, TransIntRatio,
    'Transpiration interception ratio');
  ExternVCreate('int_stor', '[-]', statefield, int_stor,
    'Interception storage');
  ExternVCreate('rain', '[mm/d]', statefield, rain, 'Rainfall');
  ExternVCreate('P', '[-]', statefield, P, 'Atmospheric pressure');
  ExternVCreate('sat_def', '[-]', statefield, Sat_def, 'Saturation deficit');
  ExternVCreate('ra', '[-]', statefield, ra, 'Aerodynamic resistance');
  ExternVCreate('rc0', '[-]', statefield, rc0,
    'Canopy resistance under well watered conditions');
  ExternVCreate('NetRain', '[-]', statefield, NetRain,
    'Net rainfall (rainfall - interception)');
  ExternVCreate('Rad_Int', '[W/m2]', statefield, Rad_Int,
    'Radiation intercepted by the canopy');
  // ExternVCreate('Tiln', '[-]', statefield, Tiln);
  for i := 1 to 4 do
  begin // Vier Blattetagen
    ExternVCreate('NcLAL__' + inttostr(i), '[%]', statefield, NcLAL[i]);
  end;
  for i := 1 to 4 do
  begin // Vier Blattetagen
    StateCreate('PARi' + inttostr(i), '[W/m2]', 0, true, PARi[i]);
  end;
  optCreate('optDroughtimpact', 'DroughtImpact', OptDroughtimpact,
    'Option for drought impact');
  OptDroughtimpact.OptionList.Clear;
  OptDroughtimpact.OptionList.Add('DroughtImpact');
  OptDroughtimpact.OptionList.Add('NoDroughtImpact');
  OptCreate('OptNSenescenceType', 'Concentration', OptNSenescenceType,
    'Option for type of N senescence, CWT3 is N insensitive, CERES Wheat type late leaf senescence');
  OptNSenescenceType.OptionList.Clear;
  OptNSenescenceType.OptionList.Add('CWT3');
  OptNSenescenceType.OptionList.Add('Concentration');
  OptNSenescenceType.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#nitrogen-stress-nitrogen-induced-leaf-senescence';


  optCreate('optUseAgeDependentLeafSenescence', 'false',
    UseAgeDependentLeafSenescence,
    'Option for using age dependent leaf senescence rate');
  UseAgeDependentLeafSenescence.OptionList.Clear;
  UseAgeDependentLeafSenescence.OptionList.Add('true');
  UseAgeDependentLeafSenescence.OptionList.Add('false');
  UseAgeDependentLeafSenescence.DocuWebLink :=
    'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#age';
  // link to documentation

  optCreate('optUseLightDependentLeafSenescence', 'true',
    UseLightDependentLeafSenescence,
    'Option for using Light dependent leaf senescence rate');
  UseLightDependentLeafSenescence.OptionList.Clear;
  UseLightDependentLeafSenescence.OptionList.Add('true');
  UseLightDependentLeafSenescence.OptionList.Add('false');
  UseLightDependentLeafSenescence.DocuWebLink :=
  'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#light-limitation';

  optCreate('optUseDroughtDependentLeafSenescence', 'true',
    UseDroughtDependentLeafSenescence,
    'Option for using Drought dependent leaf senescence rate');
  UseDroughtDependentLeafSenescence.OptionList.Clear;
  UseDroughtDependentLeafSenescence.OptionList.Add('true');
  UseDroughtDependentLeafSenescence.OptionList.Add('false');
  UseDroughtDependentLeafSenescence.DocuWebLink :=
    'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/THumeWheatLeafArea.html#drought-stress';
  // link to documentation

end;

function THumeWheatLeafArea.calcGAI(EC, LAI: real): real;
{
  After booting, GAI is 20% higher than LAI dest. [94er 2004]
  linear transition-phase between BBCH50-60
}
var
  fGAI_: real; // factor vor LAI->GAI
begin
  // fGAI:=0;
  if (EC > 50) then
  begin
    if (EC < 60) then
      fGAI_ := fGAI.v * 0.1 * (EC - 50)
    else
      fGAI_ := fGAI.v;
    calcGAI := LAI * (1 + fGAI_);
  end
  else
    calcGAI := LAI;
end;

procedure THumeWheatLeafArea.setleaf_arr(PLALR_: real);

var
  i, LN_, spos: integer;
  fLWS, sumla: real;

begin
  LN_ := -1;
  sumla := 0;
  for i := MaxLeafNumber downto 1 do
  begin
    sumla := sumla + PLSC[i].v;
    if (PLSC[i].v > 0) and (LN_ < 0) then
    begin
      LN_ := i;
    end;
  end;
  if LN_ = -1 then
    exit;
  // find first leaf pos:
  spos := -1;
  for i := 1 to LN_ do
  begin
    if (PLSC[i].v > 0) then
    begin
      if (spos = -1) then
        spos := i;
    end;
  end;
  PLALR_ := min(PLALR_, sumla);
  while (PLALR_ > 0) do
  begin
    if PLALR_ < PLSC[spos].v then
    begin
      fLWS := (PLSC[spos].v - PLALR_) / PLSC[spos].v;
      PLALR_ := 0;
      PLSC[spos].v := PLSC[spos].v * fLWS;
    end
    else
    begin
      PLALR_ := PLALR_ - PLSC[spos].v;
      PLSC[spos].v := 0;
    end;
    if (PLALR_ > 0) and (spos < LN_) then
      spos := spos + 1
    else if (spos = LN_) then
      PLALR_ := 0; // to prevent rounding errors;
  end;
  sumla := 0;
  for i := MaxLeafNumber downto 1 do
  begin
    sumla := sumla + PLSC[i].v;
  end;
end;

/// <summary>
/// Calculates the potential specific leaf area (SLA) based on the given parameters.
/// </summary>
/// <param name="Wleaf">The current leaf weight.</param>
/// <param name="dWleaf">The change in leaf weight.</param>
/// <param name="BBCH">The BBCH stage of the wheat plant.</param>
/// <param name="SLA_old"> The previous value of specific leaf area (SLA).</param>
/// <returns>The calculated potential specific leaf area (SLA).</returns>
function THumeWheatLeafArea.calcPotSLA(Wleaf, dWleaf, BBCH,
  SLA_old: real): real;

var
  SLA_, SLAs, SLAw, w, LAIe, a, b, SLA_B: real;

begin
  a := aSLA.v; // intercept
  b := bSLA.v; // slope
  SLA_B := maxSLA.v; // start SLA of juvenescent leafs (APSIM, Asseng 2003)
  if (SLA_old = 0) and (BBCH < 20) then
    SLA_ := SLA_B // initialise with high SLA of juvenile leafs
  else
  begin
    w := (Wleaf + dWleaf) * 1E-4; // g->10kg
    LAIe := w * SLA_old; // estimation of LAI
    // SLAs: SLA as a function of LAI(empiric fit see Chapt. 3 Diss. Ratjen)
    SLAs := min(SLA_B, a + b * LAIe); // SLA as a function of LAI
    if SLA_old > SLAs then
    begin
      // transition phase between initial SLA and later phase where
      // mutual shading dominates SLA
      SLAw := SLAs + (SLA_B - SLAs) * exp(f1_SLA.v * LAIe + f2_SLA.v);
      SLA_ := min(SLA_old, SLAw)
    end
    else
      // phase where shading dominates SLA (equates LAI~2)
      SLA_ := SLAs;
  end;
  calcPotSLA := SLA_;
end;

/// <summary>
/// Calculates a sustainable leaf area index (LAI) for which the actual transpiration rate
/// equals the potential transpiration rate.
/// </summary>
/// <param name="Temp_">The temperature in degrees Celsius.</param>
/// <param name="Sat_def_">The saturation deficit.</param>
/// <param name="Net_beam_">The net beam radiation.</param>
/// <param name="delta_">The psychrometric constant.</param>
/// <param name="gamma_">The gamma value.</param>
/// <param name="ra_">The aerodynamic resistance.</param>
/// <param name="actTrans_">The actual transpiration rate.</param>
/// <param name="exLAI">The external leaf area index.</param>
/// <returns>The calculated leaf area index (LAI).</returns>
function THumeWheatLeafArea.s_LAI(Temp_, Sat_def_, Net_beam_, delta_, gamma_,
  ra_, actTrans_, exLAI: real): real;

var
  pETP_: Extended;
  ro, int_stor_: Extended;
  Pot_Evapo_: Extended;
  pot_trans_, delta2, // Iterationsschrittweite
  a, F, exLAI_, b, // Steigung (Ableitung)
  rc, actTransInt, potTransInt, PTI, interception_: Extended;
  // Summe von interception und potentieller Transpirationsrate
  steps: integer;
begin
  b := 0;
  steps := 0;
  int_stor_ := int_stor.v;
  potTransInt := PotTrans.v + interception.v;
  actTransInt := actTrans_ + interception.v;

  // the function to evaluate, i.e. to minimize
  F := potTransInt * TRcrit.v - actTransInt;
  delta2 := LAI.v / 1000;


  // the Newton method is used to find a leaf area index
  // which leads to an actual transpiration rate equal to the potential transpiration

  while Power(F, 2) > 0.000001 do
  begin
    steps := steps + 1;
    if steps > 10 then
    begin
      s_LAI := exLAI;
      exit;
    end;
    if (exLAI = LAI.v) then // first iteration
    begin
      exLAI_ := LAI.v;
      // change LAI for numerical differentiation
      exLAI := LAI.v - (delta2);
    end
    else
    begin
      exLAI_ := exLAI;
      if b <> 0 then
      begin
        // change the value of LAI
        exLAI := exLAI_ - (F / b);
        if (exLAI = LAI.v) then
        begin
          s_LAI := exLAI_;
          exit;
        end;
      end
      else
      begin
        s_LAI := exLAI_;
        exit;
      end;
    end;
    // calculate canopy resistance
    Calc_rc(exLAI, ro, Temp_, rc);

    Calc_pETP(ro, rc, pETP_, Net_beam_, Sat_def_, ra_, delta_, gamma_);

    // calc pot. soil evopration
    Pot_Evapo_ := pETP_ * exp(-exk_GlobRad.v * exLAI);
    if Pot_Evapo_ < 0.0 then
      Pot_Evapo_ := 0.0;

    // calc potential transpiration + interception
    PTI := pETP_ - Pot_Evapo_;

    // calculate interception
    CalcInterception(int_stor_, exLAI, PTI, interception_); // End interception

    // calculate potential Transpiration+Interception
    if pETP_ > 0.0 then
      pot_trans_ := (pETP_ - Pot_Evapo_ - interception_)
    else
      pot_trans_ := 0.0;
    if pot_trans_ < 0.0 then
      pot_trans_ := 0.0;
    potTransInt := pot_trans_ + interception_;
    // End potTrans

    a := F; // save old function value
    // evaluate the goal function, i.e. the LAI which gives

    F := potTransInt * TRcrit.v - actTransInt;
    if Power(a, 2) <= Power(F, 2) then
    begin
      s_LAI := exLAI_;
      exit;
    end;
    if (exLAI - exLAI_) <> 0 then
      // evaluate the gradient numerically
      b := (F - a) / (exLAI - exLAI_)
    else
      break;
  end; // while end
  s_LAI := exLAI;
end; { End sLAI }

procedure THumeWheatLeafArea.calcSenescence;
var
  Nccrit_: real;
  SLN_, maxLAIsen, NLAL_, MLAL_s, LAL_s, senrate, tmp: real;

begin
  PLALR_a.v := 0;
  PLALR_d.v := 0;
  PLALR_n.v := 0;
  PLALR_l.v := 0;
  PLALR.v := 0;

  if fUseAgeDependentLeafSenescence then
    CalcCERESAgeDependenLeafSenescence(senrate)
  else
    senrate := 0.0;
  PLALR_a.v := senrate;

  // for later stages senescence happens according to the CERES-Wheat algorithm
  if (ISTAGE.v >= 2) and (ISTAGE.v < 4) then
    PLALR_a.v := PSENLeaf1.v * TSumInc.v * GPLA.v; // PLALR_a := 0.0;
  if (ISTAGE.v >= 4) and (ISTAGE.v < 5) then
    PLALR_a.v := PSENLeaf2.v * TSumInc.v * GPLA.v;

  if fSenescence = concentration then
  begin
    CalcNdependentLeafSenescence(senrate);
  end
  else
    senrate := 0;
  PLALR_n.v := senrate;

// calculation of leaf senescence during ripening according to CERES-Wheat 3
// independently of N shortage but based on a quadratic function of temperature sum
// within ISTAGE 5
  if fSenescence = cwt3 then
    If (ISTAGE.v >= 5) and (ISTAGE.v < 6) then
      PLALR_n.v := GPLA.v * 2 * SUMDTT5.v * TSumInc.v / (p5_ * p5_)
    else
      PLALR_n.v := 0.0;

  if self.fUseLightDependentLeafSenescence then
    CalcLightDependendLeafSenescence(senrate)
  else
    senrate := 0;
  PLALR_l.v := senrate;

  if self.fUseDroughtDependentLeafSenescence then
    CalcDroughtDependentLeafSenescence(senrate)
  else
    senrate := 0.0;
  PLALR_d.v := 0.0;

  // set plant leaf area loss rate
  //
  if LAI.v > 0 then
  begin
    // PLALR.v:= min((LAI.v*1E4)/plants.v, max(max(PLALR_a.v,PLALR_d.v),
    // max(PLALR_n.v, PLALR_l.v)))

    tmp := max(PLALR_a.v, PLALR_d.v);
    tmp := max(tmp, PLALR_n.v);
    tmp := max(tmp, PLALR_l.v);
    PLALR.v := min((LAI.v * 1E4) / plants.v, tmp);
  end
  else
    PLALR.v := 0;

  // senescence fraction caused by drought stress
  DSsen.v := max(0, PLALR_d.v - max(PLALR_a.v, max(PLALR_n.v, PLALR_l.v)));

  // senescence fraction caused by N limitation
  Nsen.v := max(0, PLALR_n.fv - max(PLALR_a.fv, max(PLALR_d.fv, PLALR_l.fv)));

  if PLALR.v > 0 then
    // drought stress fraction (relative)
    fdsen.v := DSsen.v / PLALR.v
  else
    fdsen.v := 0;
  // senescence fraction caused by light limitation
  LLsen.v := max(0, PLALR_l.v - max(PLALR_a.v, max(PLALR_n.v, PLALR_d.v)));
  // now senescence rate for canopy (plant level)
  SENLA.c := PLALR.v;
end;

procedure THumeWheatLeafArea.SetLaiLayers;
var
  (*
    applying an average plant with four layers (1 = top layer, 4 = bottom layer)
    First leaf growth occurs in layer 1, senescence starts up from layer 4
  *)
  i, lastLAL: integer;
  LAIdiff: real;
  LAI_: real;
begin

  (*
    during vegetative stage, layers are defined by a distribution function
  *)
  if EC.v < 65 then
  begin // distribution is a function of LAI
    LAI_ := max(2, min(6, LAI.v));
    // limiting to range of measurements at anthesis
    // rain-out-shelter exp. HS 103 2010)
    for i := 1 to 4 do
    begin
      // leaf mass and area distribution to single leaf layer as a function of
      // LAI (rain-out-shelter exp. HS 2010)
      if (LFWT_m2.v > 0) and (PLA.v > 0) and (LAI.v > 0) then
      begin
        if (i < 4) then
        begin
          MLAL[i].v := LFWT_m2.v *
            (relLayerM_Int[i].v + relLayerM_S[i].v * LAI_);
          LAL[i].v := LAI.v * (relLayerA_Int[i].v + relLayerA_S[i].v * LAI_);
        end
        else
        begin
          MLAL[i].v := LFWT_m2.v - MLAL[1].v - MLAL[2].v - MLAL[3].v;
          LAL[i].v := LAI.v - LAL[1].v - LAL[2].v - LAL[3].v;
        end;
      end
      else
      begin
        MLAL[i].v := 0;
        LAL[i].v := 0;
      end;
    end; // for Schleife zu
  end
  else
  begin
    (*
      during grain filling the leaf-layer development
      is ruled by the N dynamic
    *)
    if sumLAL.v > 0 then
    begin
      LAIdiff := PLALR.v * plants.v * 1E-4;
      if LAI.v <= 0 then
        LAIdiff := sumLAL.v;
    end
    else
      LAIdiff := 0;
    while LAIdiff > 0 do
    begin
      // find the bottom leaf layer
      lastLAL := -1;
      for i := 4 downto 1 do
      begin
        if (LAL[i].v > 0) then
          if (lastLAL = -1) then
            lastLAL := i;
      end;
      if lastLAL = -1 then
        lastLAL := 1;
      // start senescence from the last leaf layer
      for i := lastLAL downto 1 do
      begin
        if LAIdiff > 0 then
          if LAIdiff <= LAL[i].v then
          begin
            MLAL[i].v := max(0, (LAL[i].v - LAIdiff) / LAL[i].v * MLAL[i].v);
            LAL[i].v := LAL[i].v - LAIdiff;
            LAIdiff := 0;
          end
          else
          begin
            LAIdiff := LAIdiff - LAL[i].v;
            LAL[i].v := 0;
            MLAL[i].v := 0;
            if lastLAL = 1 then
              LAIdiff := 0; // to prevent rounding errors
          end;
        if LAL[i].v = 0 then
          lastLAL := max(1, lastLAL - 1);
      end;
    end;
  end;

  sumMLAL.v := 0;
  sumLAL.v := 0;
  for i := 1 to 4 do
  begin
    sumLAL.v := sumLAL.v + LAL[i].v;
    sumMLAL.v := sumMLAL.v + MLAL[i].v;
  end;
  if sumMLAL.v > 0 then
    avSLA.v := (sumLAL.v / sumMLAL.v) * 1E4
  else
    avSLA.v := 0;
  if EC.v > 65 then
  begin
    SENL.v := (LFWT_m2.v - sumMLAL.v) / plants.v;
  end
  else if avSLA.v > 0 then
    SENL.v := min(LFWT_pl.v, PLALR.v / avSLA.v)
  else
    SENL.v := 0;
  if (sumLAL.v > LAI.v) then
    sumLAL.v := sumLAL.v;
end;

procedure THumeWheatLeafArea.Init;
var
  i: integer;
begin
  inherited Init(GlobMod);
  if OptDroughtimpact.option = 'droughtimpact' then
    fDroughtImpact := UHumeWheatDryMatter.DroughtImpact;
  if OptDroughtimpact.option = 'nodroughtimpact' then
    fDroughtImpact := UHumeWheatDryMatter.noDroughtImpact;

  LAI.v := 0;
  PLA.v := 0;
  for i := 1 to MaxLeafNumber do
  begin
    PLSC[i].v := 0;
    senratesLA[i] := 0;
    senratesDM[i] := 0;
  end;
  SENLA.v := 0;
  SUMDTT5.v := 0;
  p5_ := 430 + P5.v * 20; // unscaled value of parameter p5
  LAIs := 0;
  for i := 10 downto 1 do
  begin
    Icrop[i] := 0;
  end;
  if OptNSenescenceType.option = 'concentration' then
  begin
    fSenescence := concentration;
  end;
  if OptNSenescenceType.option = 'cwt3' then
  begin
    fSenescence := cwt3;
  end;

  if self.UseAgeDependentLeafSenescence.option = 'true' then
    fUseAgeDependentLeafSenescence := true
  else
    fUseAgeDependentLeafSenescence := False;

  if self.UseLightDependentLeafSenescence.option = 'true' then
    fUseLightDependentLeafSenescence := true
  else
    fUseLightDependentLeafSenescence := False;

  if self.UseDroughtDependentLeafSenescence.option = 'true' then
    fUseDroughtDependentLeafSenescence := true
  else
    fUseDroughtDependentLeafSenescence := False;

  for i := 10 downto 1 do
  begin
    avTransIntRatio_arr[i] := 1;
  end;
  potSLA.v := 0;
end;

procedure THumeWheatLeafArea.CalcRates;
begin
  if (ISTAGE.v >= 5) and (ISTAGE.v < 6) then
    SUMDTT5.c := 0.25 * TMPMN.v + 0.75 * TMPMX.v
  else
    SUMDTT5.c := 0;

  SetSingleLeafGrowthRatesToZero;
  CalcLeafNumberOnMainStem;
  CalcSingleLeafGrowth;
  calcSenescence;
end;

procedure THumeWheatLeafArea.Integrate;

  procedure CalcPARonLeafLayers;

  var
    F: array [1 .. 4] of real; // cumulative leaf area above lamina i
    LL: TnLeafLayer;

  begin
    // the amount of PAR incident on the sureface of lamina i :
    for LL := low(LL) to high(LL) do
    begin
      case LL of
        1:
          F[LL] := 0;
        2:
          F[LL] := LAL[LL - 1].v;
        3:
          F[LL] := LAL[LL - 1].v + LAL[LL - 2].v;
        4:
          F[LL] := LAL[LL - 1].v + LAL[LL - 2].v + LAL[LL - 3].v;
      end;
      PARi[LL].v := kPAR.v * (Rad_Int.v * 0.5) * kTransPAR.v *
        exp(-kPAR.v * F[LL]);
    end;

  end;

var
  i: integer;

begin
  inherited Integrate;

  InitializeLeafAreaOfFirstLeafAtEmergence;

  // substract senescent leaf tissue from leaf arrays and calc. av. SLA
  setleaf_arr(PLALR.v);

  SumUpSingleLeafAreas;

  if (PLA.v > 0) then
    // Leaf area index as the difference of total and senescent leaf area
    LAI.v := (PLA.v - SENLA.v) * plants.v * 1E-4;

  // After istage 6 leaf area index is zero
  If (ISTAGE.v >= 6) and (LAI.v >= 0) then
    LAI.v := 0;

  // calculate green leaf area per plant
  GPLA.v := (PLA.v - SENLA.v);

  // calculate the level of incident radiation on 4 leaf layers
  CalcPARonLeafLayers;

  SetLaiLayers;

  GAI.v := calcGAI(EC.v, LAI.v);

  // catch the maximum value of leaf area index
  if (LAI.v > LAImax.v) then
    LAImax.v := LAI.v;

end;

procedure THumeWheatLeafArea.CalcRadiationAverage;
var
  i: integer;
  SUM_I: real;
  j: integer;
begin
  // Leaf senescence due to light limition (APSIM I_Wheat Meinke 1998)
  // ten day running mean of global radiation above canopy(avIcrop)
  for i := 9 downto 1 do
  begin
    Icrop[i + 1] := Icrop[i];
  end;
  Icrop[1] := PAR.v * exp(-kPAR.v * LAI.v);
  avIcrop.v := 0;
  SUM_I := 0;
  for j := 1 to 10 do
  begin
    SUM_I := SUM_I + Icrop[j];
  end;
  avIcrop.v := SUM_I / 10;
end;

procedure THumeWheatLeafArea.CalcEvenTransIntRatio;
var
  i: integer;
  SUM_avTIR: real;
begin
  // calc. runnig average of TransIntRatio (avTransIntRatio)
  for i := 9 downto 1 do
  begin
    // shuffle values one slot backwards
    avTransIntRatio_arr[i + 1] := avTransIntRatio_arr[i];
  end;
  avTransIntRatio_arr[1] := TransIntRatio.v;
  SUM_avTIR := 0;
  for i := 1 to 10 do
  begin
    SUM_avTIR := SUM_avTIR + avTransIntRatio_arr[i];
  end;
  evenTransIntRatio.v := SUM_avTIR / 10;
end;

procedure THumeWheatLeafArea.CalcInterception(int_stor_: Extended; exLAI: real;
  PTI: Extended; var interception_: Extended);
var
  max_int_cap: Extended;
  int_cap: Extended;
begin
  // interception:
  max_int_cap := exLAI * sic.v;
  int_cap := max_int_cap - int_stor_;
  if int_cap > 0.0 then
  begin
    if int_cap > (rain.v * GlobTime.c) then
    begin
      int_stor_ := int_stor_ + rain.v * GlobTime.c;
    end
    else
      int_stor_ := max_int_cap;
  end;
  if PTI * GlobTime.c > int_stor_ then
  begin
    PTI := PTI - int_stor_ / GlobTime.c;
    interception_ := int_stor_ / GlobTime.c;
    int_stor_ := 0.0;
  end
  else
  begin
    interception_ := PTI;
    int_stor_ := int_stor_ - PTI * GlobTime.c;
  end;
end;

procedure THumeWheatLeafArea.Calc_pETP(ro: Extended; rc: Extended;
  var pETP_: Extended; Net_beam_: real; Sat_def_: real; ra_: real; delta_: real;
  gamma_: real);
const
  cp = 1005.0;
begin
  pETP_ := (delta * Net_beam_ + ro * cp * Sat_def_ / ra_) /
    (delta_ + gamma_ * (1 + rc / ra_));
  pETP_ := pETP_ / (2.477 * 1E6) * 86400.0;
end;

procedure THumeWheatLeafArea.Calc_rc(exLAI: real; var ro: Extended; Temp_: real;
  var rc: Extended);
begin
  // PenMonteith:
  ro := 1.2917 - 0.00434 * Temp_;
  if exLAI < 1.0 then
    rc := rc0.v
  else if (exLAI >= 1.0) and (exLAI < 2) then
    rc := rc0.v / exLAI
  else if (exLAI >= 2.0) and (exLAI < 6) then
    rc := rc0.v / 2 - (rc0.v / 2 - rc0.v / 3) * ((exLAI - 2) / 4)
  else
    // according to Stockle (????)
    rc := rc0.v / 3;
  if rc < 0.1 then
    rc := 0.1;
end;

procedure THumeWheatLeafArea.CalcDroughtDependentLeafSenescence
  (var PLALR_d: real);
var
  NetBeam: real;
begin
  // Leaf senescence due to water limitation (APSIM I_Wheat Meinke 1998)
  if (fDroughtImpact = UHumeWheatDryMatter.DroughtImpact) then
  begin
    // calculate a 10 day running average of actual transpiration + interception /(potential transpiration + interception)
    CalcEvenTransIntRatio;
    if (TransIntRatio.v < TRcrit.v) and (evenTransIntRatio.v < TRcrit.v) then
    begin
      gamma := P.v * 0.000662;
      // 0.000662 = Psychrometerkonstante [1/�K]  ;
      delta := 239.0 * 17.4 * 6.11 * exp(17.4 * TMPM.v / (TMPM.v + 239.0)) /
        sqr(TMPM.v + 239.0);
      NetBeam := max(0, 0.6494 * (Rad_Int.v) - 18.417);

      // calculate a "sustainable LAI", i.e. a LAI which gives a TransIntration equal to TRcrit
      LAIs := s_LAI(TMPM.v, Sat_def.v, NetBeam, delta, gamma, ra.v,
        PotTrans.v * evenTransIntRatio.v, LAI.v);

      // calculate a drought induced senescence rate [cm2/plant/d]
      if LAI.v > 0 then
        PLALR_d := max(0, ((LAI.v - LAIs) / 15 * evenTransIntRatio.v * 1E4) /
          plants.v);
    end;
  end;
end;

procedure THumeWheatLeafArea.CalcLightDependendLeafSenescence
  (var PLALR_l: real);

begin

  // Calculate a 10 day average of irradiation
  CalcRadiationAverage;

  if (ISTAGE.v >= 2) and (avIcrop.v < Icrit.v) and (EC.v < EC_lgend.v) then
  begin
    // calc. shading forced senescence (similar to APSIM I_Wheat Meinke 1998)
    // LAIs = (ln(I)-ln(I0))/-k || I = Icrit

    // calculate a light dependend sustainable leaf area index
    // LAIs := (ln(Icrit.v) - ln(avIcrop.v)) / -kPAR.v;
    LAIs := (ln(Icrit.v / avIcrop.v)) / -kPAR.v; // changed HK 2025-05-22

    if LAI.v > 0 then
      PLALR_l := max(0, min((((LAI.v - LAIs) / 20) * 1E4) / plants.v,
        // shading only limits net increase of LAI (in contrast to Meinke 1998)
        PLA.c));
  end;
end;

procedure THumeWheatLeafArea.CalcNdependentLeafSenescence(var PLALR_n: real);
begin
  // if the actual specific leaf nitrogen concentration is lower than the
  // critical sln value
  //
  if (SLN.v < critSLNtot.v) and (LAI.v > 0) and (SLN.v > 0) then
    PLALR_n := min((LAImax.v * 1E4 / plants.v) * maxPLALR.v / 100,
      (LAI.v * 1E4 / plants.v) * (1 - SLN.v / critSLNtot.v));
end;

procedure THumeWheatLeafArea.CalcCERESAgeDependenLeafSenescence
  (var PLALR_a: real);
begin
  PLALR_a := 0.0;
  // if crop is emerged and not shooting then 5th oldest leaf is decaying within one phyllochron
  if (round(ISTAGE.v) >= 1) and (round(ISTAGE.v) <= 2) and (CUMPH.v > 4) and
    (EC.v < 30) then
  // senescence only until EC 30, changed ..
  begin
    if senratesLA[trunc(LN_.v) - 4] = 0 then
    begin
      // First the leaf area of the oldest leaf fraction
      // is fixed as a potential senescence rate when four younger leaves are present
      senratesLA[trunc(LN_.v) - 4] := (PLSC[trunc(LN_.v) - 4].v);
      // the fifth oldest leaf is deceasing
    end;
    // on the level of single plant leaf area, the senescence of the 5th oldes leaf is happening during
    // one phyllochron
    // the leaf loss rate of that leaf age fraction is calculated from the leaf area of this fraction
    // at the beginning of the senescence process and the fraction of the leaf fraction
    // of the effective temperature (T~eff~) and the phyllochron interval (PHINT)
    PLALR_a := min(PLSC[trunc(LN_.v) - 4].v / GlobTime.c,
      senratesLA[trunc(LN_.v) - 4] * TSumInc.v / (Phint.v));
    // if (SENLA.v / PLA.v > 0.4) then
    // PLALR_a := 0;

    if (LN_.v > 5) and (PLSC[trunc(LN_.v) - 5].v > 0.0) then
    begin
      // if there is any leaf area left on leaves older than the 5th
      PLALR_a := PLALR_a + PLSC[trunc(LN_.v) - 5].v / GlobTime.c;
    end;

  end; // (round(ISTAGE.v) >= 1) and (round(ISTAGE.v) <= 2) and (CUMPH.v > 4)
end;

procedure THumeWheatLeafArea.SumUpSingleLeafAreas;
var
  i: integer;
begin
  // sum up single leaf areas
  sumPLsc.v := 0;
  for i := 1 to trunc(LN_.v) do
  begin
    sumPLsc.v := sumPLsc.v + PLSC[i].v;
  end;
end;

procedure THumeWheatLeafArea.InitializeLeafAreaOfFirstLeafAtEmergence;
begin
  // for initialisation initial plant leaf area is set to parameter value
  if (ISTAGE.v >= 1) and (PLA.v <= 0) and (ISTAGE.v < 3) then
  begin
    PLA.v := LFWT_pl.v * potSLA.v;
    PLSC[1].v := LFWT_pl.v * potSLA.v;
  end;
end;

procedure THumeWheatLeafArea.SetSingleLeafGrowthRatesToZero;
var
  i: integer;
begin
  // set growth rates of single leaf area to zero
  for i := 1 to MaxLeafNumber do
  begin
    PLSC[i].c := 0.0;
  end;
end;

procedure THumeWheatLeafArea.CalcLeafNumberOnMainStem;
begin
  // rate of change of cumulative phyllochron
  if (ISTAGE.v >= 1) and (ISTAGE.v < 3) then
    CUMPH.c := TSumInc.v / Phint.v
  else
    CUMPH.c := 0;
  // leaf number
  LN_.v := trunc(min(MaxLeafNumber, CUMPH.v + 1));
end;

procedure THumeWheatLeafArea.CalcSingleLeafGrowth;
var
  i: integer;
begin
  for i := 1 to MaxLeafNumber do
  begin
    if i = trunc(LN_.v) then // only one leaf is actually growing
    begin
      // potential specific leaf area (SLA) of leaf i
      if LAI.v > 0 then
        potSLA.v := calcPotSLA(LFWT_pl.v * plants.v, GROLF.v * plants.v,
          EC.v, potSLA.v)
      else
        potSLA.v := calcPotSLA(LFWT_pl.v * plants.v,
          GROLF.v * plants.v, EC.v, 0);
      // leaf area change of leaf i(cm2/pl)
      if GROLF.v > 0 then
      begin
        PLSCGR[i].v := max(0, (LFWT_pl.v + GROLF.v) * potSLA.v - sumPLsc.v);
        PLA.c := PLSCGR[i].v;
      end
      else
      begin
        PLSCGR[i].v := 0;
        // only one leaf is actually growing
        PLA.c := 0;
      end;
    end
    else
      PLSCGR[i].v := 0;
    PLSC[i].c := PLSCGR[i].v;
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Ceres Wheat', [THumeWheatLeafArea]);
{$ENDIF}
end;

end.
