/// <summary>
/// Implemtents different methods for vertical soil water transport either with differen variants
/// of the potential based water transport or as a simple tipping bucket approach.
/// </summary>
/// <remarks>
/// <author>
/// Henning Kage, Ulf Böttcher & Agronomy Group, University of Kiel
/// </author>
/// </remarks>

unit USoilWaterMod;

interface

uses
  UMod, UState, ULayeredSoil, UGenucht, classes, UAbstractSoilHeat,
  UAbstractPlant, USoilTexture,
  // Forms, VCLTee.Chart, VCLTee.Series,
  // InifilesNew;
  System.Inifiles,
  System.Threading,
  System.Diagnostics,
  System.SyncObjs;


const
  /// <summary>      delta for changing water contents</summary>
  dWg = 1E-8;
  /// <summary>matrix potential of very dry soil</summary>
  PsiAirDryness = 20000;

type
  /// <summary>TTexture_version = (RR, KA);</summary>
  TVGParsFromTexture = (FromPar, FromTexture);

  /// <summary>type for calculaiton options of evaporation</summary>
  Tact_Evaporation = (red_f, inclExfiltration);

  /// <summary>type of model for calculating the parameter 'm' within the van Genuchten model</summary>
  Tm_model = (Mualem, Burdine, Vereecken);

  /// <summary>type for specifying lower boundary conditions</summary>
  TLowerBoundaryCondition = (NoFlow, FreeFlow, ConstContent, Groundwatertable);

  /// <summary>type for specifying computation method</summary>
  TCompMethod = (Capacity, Diffusion, Richards, Mixed, MixedHydrus);
  /// <summary>type for specifying conductivity calculation context</summary>
  TConductivityContext = (ccDiffusion, ccRichardsMixed, ccMixedHydrus);

  /// <summary>type for specifying computation method for nFK</summary>
  TnFKCalcMethod = (FromParameter, Input);

  /// <summary>type for initialization method</summary>
  TIniMethod = (Watercontents, Potentials, Parameter);

  /// <summary>Type of soil evaporation reduction function</summary>
  Tred_f = (modifiedBeese, Beese1978);

  /// <summary>Type for soil water parameters</summary>
  TSoilWaterParams = array [1 .. max_comp] of TGenucht;

  /// <summary>Component implementing vertical soil water transport</summary>
  TSoilWaterMod = class(TLayeredSoil)

  private
    /// <summary>flag for resetting time step</summary>
    ResetTimeStep: boolean;
    /// <summary>flag for start of a new day</summary>
    NewDay: boolean;
    /// <summary>number of iterations during previous internal time step</summary>
    last_iter: integer;
    /// <summary>field for saving itermax</summary>
    Iter_save: integer;
    /// <summary>total number of iterations during internal time step</summary>
    total_iter: integer;
    /// <summary>maximum water content change within a single layer during an internal time step</summary>
    delt_iter_max: real;
    /// <summary>maximum ratio of flow to soil water storage during iteration in any layer</summary>
    max_flow_ratio: real;
    /// <summary>lower limit to soil water content [cm3/cm3]</summary>
    theta_airdryness: real;
    /// <summary>upper flow rate, constant over one day  [cm/d]</summary>
    DayFlow1: real;
    /// <summary>cumulative flow into layer 1 over the day [cm/d]</summary>
    CumDayFlow1: real;
    /// <summary>for saving old runoff rate value</summary>
    oldrunoff: real;
    /// <summary>maximum infiltration rate</summary>
    MaxInfil: real;
    /// <summary>for saving max_IterError</summary>
    max_IterErrorsave: real;
    /// <summary>number of layer where solution of equation system starts, mostly the first sometimes the second ..</summary>
    start: byte;
    /// <summary>Saturation in the uppermost compartment?</summary>
    wet: boolean;
    /// <summary>Water content below b_rest in the uppermost compartment?</summary>
    dry: boolean;
    /// <summary>solution converged</summary>
    success: boolean;
    /// <summary>was dt set during act. iteration</summary>
    dt_set: boolean;

    /// <summary>Enumeration type variable for computation method</summary>
    fCompMethod: TCompMethod;
    /// <summary>Switch for put Warnings on and off</summary>
    fShowWarnings: boolean;
    /// <summary>Option to take Van-Genuchten-Parameters from texture estimates</summary>
    FVGParsFromTexture: TVGParsFromTexture;
    /// <summary>type for defining pedotransfer function either KA5 or RR</summary>
    Texture_version: TTexture_version;
    /// <summary>FKsFromTexture;</summary>
    FKsFromTexture: TVGParsFromTexture;

    ///
    FTextureClass1,
    { Soil type in horizon 1 if TVGParsFromTexture = FromTexture }
    FTextureClass2, FTextureClass3, FTextureClass4, FTextureClass5,
      FTextureClass6: TTextureClass;

    /// <summary>
    /// soil bulk density classes in Horizon x }
    /// </summary>
    fLDClass1,
    FLDClass2, FLDClass3, FLDClass4, FLDClass5, FLDClass6: TLDClass;

    /// <summary>numerical bulk density as constants for each of the six possible soil horizons</summary>
    fLD1, fLD2, fLD3, fLD4, fLD5, fLD6: TLD;

    /// <summary>type of m_model used</summary>
    fm_model: Tm_model;
    /// <summary>flag for writing texture VG-Pars into Param-Ini-file</summary>
    fWriteParsFromTexture: boolean;
    /// <summary>Option for soil evaporation reduction function</summary>
    fred_f: Tred_f;
    /// <summary>previous time step width [d]</summary>
    dt_old,
    /// <summary>maximum change in water content</summary>
    MaxActChangeSWC: real;
    /// <summary></summary>
    TempFactor: real;

    /// <summary>index of layer where maximum Weff is reached</summary>
    ndx_Weff: integer;

    /// <summary>dummy to set array settings</summary>
    PSI_dummy: TVAR;

    /// <summary>Enumeration type variable for initialisation method</summary>
    IniMethod: TIniMethod;

    /// <summary> type of calculation method for plant available soil water </summary>
    nFKCalcMethod: TnFKCalcMethod;

    /// <summary>Source of effective rooting depth (Weff)</summary>
    fWeffOpt: TSource;

    /// <summary>Link to soil temperature model</summary>
    FSoilHeatModel: TAbstractSoilHeat;

    /// <summary>Option field, if true water contents are written into the next state ini-File of the control file</summary>
    fTransferWGs: boolean;
    alpha, beta, gamma, Res: TSoilArray;

    /// <summary>Calculation of freezing effect</summary>
    procedure CalcTempFactor;
    /// <summary>Calculation of conductivities</summary>
    procedure CalcConductivities(const context: TConductivityContext;
      const useGeometricMean, includeCoefficients, applyFreezing: Boolean);
    /// <summary>caculation of water transport according to diffusivity approach</summary>
    procedure CapWatSolut;
    procedure get_water_contents;
    /// <summary>caculation of water transport according to diffusivity approach</summary>
    procedure Diffwater_solut;
    /// <summary>caculation of water transport according to Richards equation approach</summary>
    procedure Richardswater_solut;
    /// <summary>caculation of water transport according to "Mixed" approach</summary>
    procedure Mixedwater_solut;
    /// <summary>caculation of water transport according to "Mixed Hydrus" approach</summary>
    procedure MixedHydruswater_solut;

    /// <summary>Calculation of soil water balance</summary>
    procedure GetWaterBalance;
    /// <summary>Calculation of new internal time step width</summary>
    procedure get_new_dt;
    /// <summary>adjust time step during picard iteration</summary>
    procedure adjust_dt;
    /// <summary>Calculation of maximal water content change within an internal time step</summary>
    procedure get_delt_iter_max;
    /// <summary>setting up the new state vars</summary>
    procedure set_new_state_vars;
    /// <summary>calculation of runoff</summary>
    procedure CalcOverflow;

    procedure SetRangeAverage(var target: TVAR; startIdx, endIdx: integer);

    function getNetRain: TExternV;
    function getPotEvap: TExternV;
    /// <summary>wrapper for all parameter creation</summary>
    procedure CreateParameters;
    procedure CreateHorizonParameters;
    /// <summary>wrapper for all option creation</summary>
    procedure CreateOptions;
    
    /// <summary>wrapper for all state creation</summary>
    procedure CreateStates;
    /// <summary>wrapper for all external variable creation</summary>
    procedure CreateVars;
    /// <summary>initialisation of van Genuchten parameters</summary>
    procedure InitGenuchtenPars;
    /// summary> set the computation method </summary>
    procedure SetCompMethod;
    /// <summary> initialisation of vectors and arrays </summary>
    procedure InitVectors;
    procedure SetGenuchtenPars;
    
    /// <summary> set the layer density classes and values </summary>
    procedure SetLDPars;

    procedure SetLDnumbers;
    procedure SetLowerBoundaryCondition;
    procedure SetEvaporationReductionOption;
    
    /// <summary>calculation of nFK values</summary>
    procedure Calc_nFK(psiFK: Extended; psiWP: Extended);


    procedure Calc_nFKparsForHorizons;
    procedure SetNewPsi_and_Theta_Values;
    procedure CheckForHoriIndexInitialisation;
    procedure SaveOldValuesForCrankNicholson_SoluteTransport;
    procedure Find_Number_of_computation_Layers;
    procedure CalcTotalWaterAmounts;
    procedure CalcProfileWaterBalance(OldSumSoilwater: Extended);
    procedure CalcGlobalWaterBalance;
    procedure InitDailySums_and_Changes(var OldSumSoilwater: real);
    procedure CalcProfile_and_HorizonSums;
    procedure TransferWGsToNextINI;
    procedure UpperBoundaryCondition;

  protected
    /// <summary>soil water diffusivities [cm2/d] }</summary>
    Dw_arr: TSoilArray;
    /// <summary>specific water capacity</summary>
    c_arr: TSoilArray;
    /// <summary>intermediate variable dt.v/(C_arr*??)</summary>
    P: TSoilArray;
    /// <summary>saturated hydraulic conductivities [cm/d]</summary>
    kf: TSoilArray;
    /// <summary>unsaturated hydraulic conductivities [cm/d]</summary>
    Ku_arr: TSoilArray;
    /// <summary>average soil water diffusivities between 2 compartments [cm2/d]</summary>
    avg_Dw: TSoilArray;
    /// <summary>average unsaturated hydraulic conductivities between 2 compartments [cm/d]</summary>
    avg_Ku: TSoilArray;
    /// <summary>Intermediate variable</summary>
    Dw_fact: TSoilArray;
    /// <summary>Intermediate variable</summary>
    Ku_fact: TSoilArray;
    /// <summary>Intermediate variable: TSoilArray; known values and solution vektor</summary>
    B_vektor: TSoilArray;
    /// <summary>lower vector of the tri-diagonal matrix</summary>
    lower: TSoilArray;
    /// <summary>central vector of the tri-diagonal matrix</summary>
    diag: TSoilArray;
    /// <summary>upper vector of the tri-diagonal matrix</summary>
    upper: TSoilArray;
    /// <summary>water contents during the last iteration step</summary>
    last_iter_theta: TSoilArray;
    /// <summary>extrapolated soil water content for first iteration step</summary>
    est_theta: TSoilArray;
    /// <summary>factor for calculation of flows in cases of near saturation</summary>
    wf: TSoilArray;
    /// <summary>ratio of flow to soil water storage</summary>
    flow_ratio: TSoilArray;

    /// <summary>Lower boundary condition specification</summary>
    LowerBoundaryCondition: TLowerBoundaryCondition;

    function ndx_str(i: integer): string;
    function getTexture(i: integer): TTextureClass;
    function getLD(i: integer): TLDClass;
    function GetHorizonIndexForLayer(i: integer): integer;

  public
    /// <summary>actual number of layers to be calculated, variable in case of groundwater influence</summary>
    act_n_comp: integer;
    /// <summary>number of iterations during internal time step</summary>
    iter: integer;
    ActBalanceError: real;
    SumBalanceError: real;
    /// <summary>sum of soil and ponded water [mm]</summary>
    SWCStart, global_WaterBalance, old_global_WaterBalance: real;
    /// <summary>water content vector [cm3/cm3]</summary>
    theta_arr: TSoilvarArray;
    /// <summary>new soil water contents</summary>
    theta_new: TSoilArray;
    /// <summary>water amount per layer [cm]</summary>
    WAmount: TSoilStateArray;
    /// <summary>water tension vector [cm]</summary>
    psi_arr: TSoilvarArray;
    /// <summary>flow vector [cm/d]</summary>
    Wflow_arr: TSoilvarArray;
    /// <summary>flow vector [cm/d] for internal time step</summary>
    WflowInt_arr: TSoilvarArray;
    /// <summary>sink vector [cm]</summary>
    Sink_arr: TSoilvarArray;
    /// <summary>sink vector [cm/d] for internal time step</summary>
    SinkInt_arr: TSoilvarArray;
    /// <summary>field capacity [cm3/cm3]</summary>
    FK_Arr: TSoilArray;
    /// <summary>permanent wilting point [cm3/cm3]</summary>
    PWP_Arr: TSoilArray;
    /// <summary>usable field capacity [cm3/cm3]</summary>
    nFK_Arr: TSoilArray;
    /// <summary>array of van Genuchten parameters for each layer</summary>
    WPar: TSoilWaterParams;

    /// <summary>old water flows</summary [cm/d]>
    Wflow_old: TSoilArray;
    /// <summary>previous water contents</summary>
    theta_old: TSoilArray;
    /// <summary>New estimate of water potential [cm]</summary>
    psi_neu: TSoilArray;
    /// <summary>actual values of water balance for single layers</summary>
    SW_Balance_arr: TSoilArray;
    /// <summary>cumulative values of water balance for single layers</summary>
    cumSW_Balance_arr: TSoilArray;

    /// <summary>number of soil horizons with different textures</summary>
    nHorizons: TPar;

    /// <summary>index of the lowest layer in each horizon</summary>
    HoriNdx1, HoriNdx2, HoriNdx3, HoriNdx4, HoriNdx5, HoriNdx6: TPar;

    /// <summary>Texture_versionOption: TOption;</summary>
    FVGParsFromTextOption: TOption;
    /// <summary></summary>
    FKsFromTextOption: TOption;
    act_EvaporationOption: TOption;
    red_fOption: TOption;

    /// <summary>lowerBoundCond</summary>
    OptLowerBoundary: TOption;
    /// <summary>Option for choosing the initialisaiton method</summary>
    OptIniMethod: TOption;
    /// <summary>Option for choosing the computation method</summary>
    OptCompMethod: TOption;
    /// <summary>Option for writing VG-Pars from Texture estimates into Param-Ini-file</summary>
    /// <summary></summary>
    OptWriteParsFromTexture: TOption;
    /// <summary></summary>
    /// <summary></summary>
    OptTransferWGToNextIniFile: TOption;

    /// <summary>depth of groundwatertable [cm] needed if option is selected</summary>
    Groundwaterdepth: TExternV;

    FTextClass1Option, FTextClass2Option, FTextClass3Option, FTextClass4Option,
    /// <summary>Options for choosing Parameters for 6 distinct horizons</summary>
    FTextClass5Option, FTextClass6Option: TTextClassOption;

    fLDClass1Option, fLDClass2Option, fLDClass3Option, fLDClass4Option,
    /// <summary>Options for choosing layer density  for 6 distinct horizons</summary>
    fLDClass5Option, fLDClass6Option: TLDClassOption;

    /// <summary>Options for choosing layer density  for 6 distinct horizons</summary>
    fLD1Option, fLD2Option, fLD3Option, fLD4Option, fLD5Option,
      fLD6Option: TLDOption;

    /// <summary> maximum change of water content in a layer within a time step </summary>
    max_aenderWG: TPar;
    
    /// <summary>maximum change of water content in a layer between two iterations</summary>
    max_IterError: TPar;

    /// <summary>maximum internal time step</summary>
    Max_dt: TPar;
    /// <summary>minimum internal time step [d]</summary>
    Min_dt: TPar;
    /// <summary>maximum number of Iterations before internal time step is reduced</summary>
    IterMax: TPar;

    /// <summary>Parameter for linear scaling of soil hydraulic Parameter bsat</summary>
    bsat_scaling: TPar;
    /// <summary>Parameter for linear scaling of soil hydraulic Parameter alpha</summary>
    alpha_scaling: TPar;

    /// <summary>van-Genuchten Parameter fuer Horizont 1</summary>
    /// 
    
    /// <summary> Saturation water content [cm3/cm3] for horizon 1 </summary>
    b_sat1: TPar;
    /// <summary>"residual water content" [cm3/cm3]</summary>

    /// <summary> residual water content  for horizon 1 </summary>
    b_rest1: TPar;

    /// <summary>Fitparameter "alpha" [1/cm] } for horizon 1</summary>
    alpha1: TPar;

    /// <summary>Fitparameter "n" dimensionless } for horizon 1</summary>
    n_par1: TPar;

    /// <summary>parameter for hydraulic conductivity shape for horizon 1</summary>
    l_par1: TPar;

    /// <summary>saturated hydraulic conductivity [cm.d-1] for horizon 1</summary>
    Ks1: TPar;
    /// <summary>field capacity [cm3/cm3] for horizon 1</summary>
    FK1: TPar;
    /// <summary>permanent wilting point for horizon 1</summary>
    PWP1: TPar;
    /// <summary>usable field capacity for horizon 1</summary>
    nFK1: TPar;

    /// <summary>van-Genuchten Parameter fuer Horizont 2</summary>
    /// <summary> Saturation water content [cm3/cm3] for horizon 2 </summary>
    b_sat2: TPar;
    /// <summary> residual water content  for horizon 2 </summary>
    b_rest2: TPar;
    /// <summary>fitting parameter "alpha" [1/cm]</summary>
    alpha2: TPar;
    /// <summary>fitting parameter "n" dimensionless</summary>
    n_par2: TPar;
    /// <summary>parameter for hydraulic conductivity shape</summary>
    l_par2: TPar;
    /// <summary> saturated hydraulic conductivity [cm.d-1] for horizon 2</summary>
    Ks2: TPar;
    /// <summary>field capacity [cm3/cm3] for horizon 2</summary>
    FK2: TPar;
    /// <summary>permanent wilting point for horizon 2</summary>
    PWP2: TPar;
    /// <summary>usable field capacity for horizon 2</summary>
    nFK2: TPar;

    /// <summary>van Genuchten parameters for horizon 3</summary>
    /// <summary>water content at saturation [cm3/cm3]</summary>
    b_sat3: TPar;
    /// <summary>"residual water content" [cm3/cm3]</summary>
    b_rest3: TPar;
    /// <summary>fitting parameter "alpha" [1/cm]</summary>
    alpha3: TPar;
    /// <summary>fitting parameter "n" dimensionless</summary>
    n_par3: TPar;
    /// <summary>parameter for hydraulic conductivity shape</summary>
    l_par3: TPar;
    /// <summary> saturated hydraulic conductivity [cm.d-1] for horizon 3</summary>
    Ks3: TPar;
    /// <summary>field capacity [cm3/cm3] for horizon 3</summary>
    FK3: TPar;
    /// <summary>permanent wilting point for horizon 3</summary>
    PWP3: TPar;
    /// <summary>usable field capacity for horizon 3</summary>
    nFK3: TPar;

    /// <summary>van Genuchten parameters for horizon 4</summary>
    /// <summary>water content at saturation [cm3/cm3]</summary>
    b_sat4: TPar;
    /// <summary>"residual water content" [cm3/cm3]</summary>
    b_rest4: TPar;
    /// <summary>fitting parameter "alpha" [1/cm]</summary>
    alpha4: TPar;
    /// <summary>fitting parameter "n" dimensionless</summary>
    n_par4: TPar;
    /// <summary>parameter for hydraulic conductivity shape</summary>
    l_par4: TPar;
    /// <summary> saturated hydraulic conductivity [cm.d-1] for horizon 4</summary>
    Ks4: TPar;
    /// <summary>field capacity [cm3/cm3] for horizon 4</summary>
    FK4: TPar;
    /// <summary>permanent wilting point for horizon 4</summary>
    PWP4: TPar;
    /// <summary>usable field capacity for horizon 4</summary>
    nFK4: TPar;
    /// <summary>van Genuchten parameters for horizon 5</summary>
    nFK5: TPar;
    /// <summary>water content at saturation [cm3/cm3]</summary>
    b_sat5: TPar;
    /// <summary>"residual water content" [cm3/cm3]</summary>
    b_rest5: TPar;
    /// <summary>fitting parameter "alpha" [1/cm]</summary>
    alpha5: TPar;
    /// <summary>fitting parameter "n" dimensionless</summary>
    n_par5: TPar;
    /// <summary>parameter for hydraulic conductivity shape</summary>
    l_par5: TPar;
    /// <summary>saturated conductivity [cm/d]</summary>
    Ks5: TPar;
    /// <summary>field capacity [cm3/cm3]</summary>
    FK5: TPar;
    /// <summary>permanent wilting point</summary>
    PWP5: TPar;
    /// <summary>usable field capacity</summary>
    nFK6: TPar;
    /// <summary>water content at saturation [cm3/cm3]</summary>
    b_sat6: TPar;
    /// <summary>"residual water content" [cm3/cm3]</summary>
    b_rest6: TPar;
    /// <summary>fitting parameter "alpha" [1/cm]</summary>
    alpha6: TPar;
    /// <summary>fitting parameter "n" dimensionless</summary>
    n_par6: TPar;
    /// <summary>parameter for hydraulic conductivity shape</summary>
    l_par6: TPar;
    /// <summary>saturated conductivity [cm/d]</summary>
    Ks6: TPar;
    /// <summary>field capacity [cm3/cm3]</summary>
    FK6: TPar;
    /// <summary>permanent wilting point</summary>
    PWP6: TPar;
    /// <summary>For initalisation of Soil water contents and suction values</summary>
    PsiStart1: TPar;
    /// <summary>Index of Layer where lower boundary fluxes are calculated</summary>
    bil_nr: TPar;
    /// <summary>effective rooting deph [cm]</summary>
    Weff: TPar;
    /// <summary>matric potential at which evaporation declines [hPa]</summary>
    psi_critEvap: TPar;
    /// <summary>NetRain = precipitation - interception</summary>
    NetRain: TExternV;
    /// <summary>NetRain = precipitation - interception</summary>
    // THumeNumEntity;
    /// <summary>cumulative precipitation [mm]</summary>
    CumNetRain: TState;
    /// <summary>potential evaporation rate</summary>
    Pot_Evap: THumeNumEntity;

    /// <summary>reduction factor for evaporation</summary>
    red_evap: TVAR;
    /// <summary>actual evaporation rate</summary>
    Act_Evap: TVAR;
    /// <summary>Estimation of maximum exfiltration rate</summary>
    Exfiltration: TVAR;
    /// <summary>cumulative transpiration [mm]</summary>
    CumTrans: TState;
    /// <summary>cumulative evaporation</summary>
    CumEvap: TState;
    /// <summary>cumulative drainage/capillary rise [mm]</summary>
    CumDrainage: TState;
    /// <summary></summary>
    CumWaterBalance: TState;
    /// <summary></summary>
    // CumAbsWaterBalance: TState;
    /// <summary>Water-balance based on Evapotranspiration, losses and Rain</summary>
    CumGlobalWaterBalance: TState;

    /// <summary>amount of ponded water on the soil surface [mm]</summary>
    PondedWater: TState;
    /// <summary>maximum ponding height [mm];</summary>
    PondMax: TPar;

    /// <summary>cumulative balance [mm] for verification</summary>
    /// <summary>cumulative Runoff [mm]</summary>
    CumRunoff: TState;

    /// <summary>sum of soil water down to boundary given by the Par "bil_nr"</summary>
    SumSoilWater: TVAR;
    /// <summary>sum of plant available soil water down to boundary given by the Par "bil_nr"</summary>
    SumPAVSoilWater: TVAR;
    /// <summary>sum of plant available soil water in the rooting zone (down to Weff)</summary>
    SumPAvSoilWaterRZ: TVAR;
    /// <summary>total number of iterations over the simulation run</summary>
    global_iter: TVAR;

    /// <summary>internal time step width of the diffusive water transport model</summary>
    dt: TVAR;
    /// <summary>number of time steps per day</summary>
    n_int_timesteps: TVAR;
    /// <summary>sum of internal time steps (control variable)</summary>
    SumOfInternalTimeSteps: TVAR;

    /// <summary>soil water contents in different aggregated layers [cm3/cm3]</summary>
    WG0_30, WG30_60, WG60_90, WG90_120, WG0_60,

      WG0_10, WG0_20, WG0_40, WG10_30, WG20_30, WG20_40, WG30_40, WG30_50,
      WG30_120, WG30_100, WG40_60, WG60_80, WG80_100, WG90_110, WG0_100,
      WG0_120, wg0_90, WG60_100: TVAR;
    
    /// <summary>plant available soil water down to effective rooting depth</summary>
    ProzNFK0_Weff: TVAR;

    /// <summary>plant available soil water down to 100 cm</summary>
    ProzNFK0_100: TVAR;
    /// <summary>plant available soil water down to 30 cm</summary>
    ProzNFK0_30: TVAR;

    /// <summary>Set the plant model</summary>
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override;
    
    /// <summary>creation of all parameters, options, states and external variables</summary>
    procedure CreateAll; override;

    /// <summary>initialisation of the component</summary>
    procedure Init(var GlobMod: Tmod); override;

    /// <summary>calculation of evaporation reduction factor</summary>
    procedure CalcEvap_red_f;

    /// <summary>integration of soil water transport over one time step</summary>
    procedure Integrate; override;

    /// <summary>calculation of rates and integration over time step</summary>
    procedure CalcRatesAndIntegrate; virtual;

    /// <summary>calculation of rates without integration</summary>
    procedure CalcRates; override;

    /// <summary>calculation of sink terms for water uptake and evaporation</summary>
    procedure CalcSinks; virtual;

    procedure update_Wcont_Values;

    procedure BeforeDestruction; override;
    property Texture[i: integer]: TTextureClass read getTexture;
    property LD[i: integer]: TLDClass read getLD;

  published
    property ShowWarnings: boolean read fShowWarnings write fShowWarnings;
    property m_model: Tm_model read fm_model write fm_model;
    property Opt_CompMethod: TCompMethod read fCompMethod write fCompMethod;
    property Opt_red_f: Tred_f read fred_f write fred_f;
    property Opt_maxWGchange: TPar read max_aenderWG write max_aenderWG;
    property Opt_IterError: TPar read max_IterError write max_IterError;

    property Opt_Randbed: TLowerBoundaryCondition read LowerBoundaryCondition
      write LowerBoundaryCondition;
    property Opt_IniMethod: TIniMethod read IniMethod write IniMethod;
    property Opt_maxdt: TPar read Max_dt write Max_dt;
    property Opt_mindt: TPar read Min_dt write Min_dt;
    property Opt_nFKCalcMethod: TnFKCalcMethod read nFKCalcMethod
      write nFKCalcMethod;
    property Opt_VanGenPars_from_Texture: TVGParsFromTexture
      read FVGParsFromTexture write FVGParsFromTexture;
    property Opt_Ks_from_Texture: TVGParsFromTexture read FKsFromTexture
      write FKsFromTexture;
    property Opt_TextureClass1: TTextureClass read FTextureClass1
      write FTextureClass1;
    property Opt_TextureClass2: TTextureClass read FTextureClass2
      write FTextureClass2;
    property Opt_TextureClass3: TTextureClass read FTextureClass3
      write FTextureClass3;
    property Opt_TextureClass4: TTextureClass read FTextureClass4
      write FTextureClass4;
    property Opt_TextureClass5: TTextureClass read FTextureClass4
      write FTextureClass4;
    property Opt_TextureClass6: TTextureClass read FTextureClass4
      write FTextureClass4;
    property Opt_TransferWGsToNextINI: boolean read fTransferWGs
      write fTransferWGs;
    /// <summary>Option for Source of parameter Weff</summary>
    property Opt_Weff: TSource read fWeffOpt write fWeffOpt;

    property Ext_NetRain: TExternV read getNetRain;
    property Ex_PotEvap: TExternV read getPotEvap;
    property Ex_Groundwaterdepth: TExternV read Groundwaterdepth
      write Groundwaterdepth;

    property Par_nHorizons: TPar read nHorizons write nHorizons;

    property Par_b_sat1: TPar read b_sat1 write b_sat1;
    property Par_b_rest1: TPar read b_rest1 write b_rest1;
    property Par_b_KS1: TPar read Ks1 write Ks1;
    property Par_n1: TPar read n_par1 write n_par1;
    property Par_lpar1: TPar read l_par1 write l_par1;
    property Par_alpha1: TPar read alpha1 write alpha1;
    /// <summary>field capacity [cm3/cm3]</summary>
    property Par_FK1: TPar read FK1 write FK1;
    /// <summary>permanent wilting point</summary>
    property Par_PWP1: TPar read PWP1 write PWP1;
    /// <summary>usable field capacity</summary>
    property Par_nFK1: TPar read nFK1;

    property Par_b_sat2: TPar read b_sat2 write b_sat2;
    property Par_b_rest2: TPar read b_rest2 write b_rest2;
    property Par_b_KS2: TPar read Ks2 write Ks2;
    property Par_n2: TPar read n_par2 write n_par2;
    property Par_lpar2: TPar read l_par2 write l_par2;
    property Par_alpha2: TPar read alpha2 write alpha2;
    /// <summary>field capacity [cm3/cm3]</summary>
    property Par_FK2: TPar read FK2 write FK2;
    /// <summary>permanent wilting point</summary>
    property Par_PWP2: TPar read PWP2 write PWP2;
    /// <summary>usable field capacity</summary>
    property Par_nFK2: TPar read nFK2;

    property Par_b_sat3: TPar read b_sat3 write b_sat3;
    property Par_b_rest3: TPar read b_rest3 write b_rest3;
    property Par_b_KS3: TPar read Ks3 write Ks3;
    property Par_n3: TPar read n_par3 write n_par3;
    property Par_lpar3: TPar read l_par3 write l_par3;
    property Par_alpha3: TPar read alpha3 write alpha3;
    /// <summary>field capacity [cm3/cm3]</summary>
    property Par_FK3: TPar read FK3 write FK3;
    /// <summary>permanent wilting point</summary>
    property Par_PWP3: TPar read PWP3 write PWP3;
    /// <summary>usable field capacity</summary>
    property Par_nFK3: TPar read nFK3;

    property Par_b_sat4: TPar read b_sat4 write b_sat4;
    property Par_b_rest4: TPar read b_rest4 write b_rest4;
    property Par_b_KS4: TPar read Ks4 write Ks4;
    property Par_n4: TPar read n_par4 write n_par4;
    property Par_lpar4: TPar read l_par4 write l_par4;
    property Par_alpha4: TPar read alpha4 write alpha4;
    /// <summary>field capacity [cm3/cm3]</summary>
    property Par_FK4: TPar read FK4 write FK4;
    /// <summary>permanent wilting point</summary>
    property Par_PWP4: TPar read PWP4 write PWP4;
    /// <summary>usable field capacity</summary>
    property Par_nFK4: TPar read nFK4;

    property Par_b_sat5: TPar read b_sat5 write b_sat5;
    property Par_b_rest5: TPar read b_rest5 write b_rest5;
    property Par_b_KS5: TPar read Ks5 write Ks5;
    property Par_n5: TPar read n_par5 write n_par5;
    property Par_lpar5: TPar read l_par5 write l_par5;
    property Par_alpha5: TPar read alpha5 write alpha5;
    /// <summary>field capacity [cm3/cm3]</summary>
    property Par_FK5: TPar read FK5 write FK5;
    /// <summary>permanent wilting point</summary>
    property Par_PWP5: TPar read PWP5 write PWP5;
    /// <summary>usable field capacity</summary>
    property Par_nFK5: TPar read nFK5;

    property Par_b_sat6: TPar read b_sat6 write b_sat6;
    property Par_b_rest6: TPar read b_rest6 write b_rest6;
    property Par_b_KS6: TPar read Ks6 write Ks6;
    property Par_n6: TPar read n_par6 write n_par6;
    property Par_lpar6: TPar read l_par6 write l_par6;
    property Par_alpha6: TPar read alpha6 write alpha6;
    /// <summary>field capacity [cm3/cm3]</summary>
    property Par_FK6: TPar read FK6 write FK6;
    /// <summary>permanent wilting point</summary>
    property Par_PWP6: TPar read PWP6 write PWP6;
    /// <summary>usable field capacity</summary>
    property Par_nFK6: TPar read nFK6;

    property Par_PsiStart1: TPar read PsiStart1 write PsiStart1;
    property Par_Weff: TPar read Weff write Weff;
    property Par_PondMax: TPar read PondMax write PondMax;

    property Var_WG0_30: TVAR read WG0_30 write WG0_30;
    property Var_WG30_60: TVAR read WG30_60 write WG30_60;
    property Var_WG30_120: TVAR read WG30_120 write WG30_120;
    property Var_WG30_100: TVAR read WG30_100 write WG30_100;
    property Var_WG60_90: TVAR read WG60_90 write WG60_90;
    property Var_WG90_120: TVAR read WG90_120 write WG90_120;
    property Var_WG0_100: TVAR read WG0_100 write WG0_100;
    property Var_WG0_120: TVAR read WG0_120 write WG0_120;
    property Var_WG0_90: TVAR read wg0_90 write wg0_90;
    property Var_WG0_60: TVAR read WG0_60 write WG0_60;

    property Var_Psi_dummy: TVAR read PSI_dummy write PSI_dummy;
    property Var_ActEvap: TVAR read Act_Evap write Act_Evap;

    property St_CumEvap: TState read CumEvap write CumEvap;
    property St_CumDrainage: TState read CumDrainage write CumDrainage;
    property St_CumNetRain: TState read CumNetRain write CumNetRain;
    property St_PondedWater: TState read PondedWater write PondedWater;

    property Par_psi_critEvap: TPar read psi_critEvap write psi_critEvap;

    property Par_Horindx1: TPar read HoriNdx1 write HoriNdx1;
    property Par_Horindx2: TPar read HoriNdx2 write HoriNdx2;
    property Par_Horindx3: TPar read HoriNdx3 write HoriNdx3;
    property Par_Horindx4: TPar read HoriNdx4 write HoriNdx4;
    property Par_Horindx5: TPar read HoriNdx5 write HoriNdx5;
    property Par_Horindx6: TPar read HoriNdx6 write HoriNdx6;

    property SoilHeatModel: TAbstractSoilHeat read FSoilHeatModel
      write FSoilHeatModel;

  end;

procedure Register;

var
  SoilWaterMod: TSoilWaterMod;

implementation

uses
  SysUtils, Math
{$IFNDEF NONVISUAL}
    , vcl.Dialogs
{$ENDIF}
    ;


procedure TSoilWaterMod.SetRangeAverage(var target: TVAR; startIdx, endIdx: integer);

var
    i: integer;
begin
  target.v := 0;
  for i := startIdx to endIdx do
    target.v := target.v + theta_arr[i].v;
  target.v := target.v / (endIdx - startIdx + 1);
end;



    /// <summary>Update of aggregated soil water contents in different soil layers</summary>
procedure TSoilWaterMod.update_Wcont_Values;

begin
  // Calculation of derived water contents for different soil layers

  SetRangeAverage(WG0_30, 1, 3);
  SetRangeAverage(WG30_60, 4, 6);
  SetRangeAverage(WG60_90, 7, 9);
  SetRangeAverage(WG90_120, 10, 12);

  SetRangeAverage(WG0_10, 1, 1);
  SetRangeAverage(WG20_30, 3, 3);
  SetRangeAverage(WG30_40, 4, 4);

  SetRangeAverage(WG0_20, 1, 2);
  SetRangeAverage(WG20_40, 3, 4);
  SetRangeAverage(WG10_30, 2, 3);
  SetRangeAverage(WG30_50, 4, 5);
  SetRangeAverage(WG40_60, 5, 6);
  SetRangeAverage(WG60_80, 7, 8);
  SetRangeAverage(WG80_100, 9, 10);
  SetRangeAverage(WG90_110, 10, 11);

  SetRangeAverage(WG0_120, 1, 12);
  SetRangeAverage(WG0_100, 1, 10);
  SetRangeAverage(wg0_90, 1, 9);
  SetRangeAverage(WG0_60, 1, 6);
  SetRangeAverage(WG0_40, 1, 4);
  SetRangeAverage(WG30_120, 4, 12);
  SetRangeAverage(WG30_100, 4, 10);
  SetRangeAverage(WG60_100, 7, 10);
end;

/// <summary>returns string for index with leading underscore if index < 10</summary>
function TSoilWaterMod.ndx_str(i: integer): string;
begin
  if i <= 9 then
    result := '_' + IntToStr(i)
  else
    result := IntToStr(i);
end;

function TSoilWaterMod.GetHorizonIndexForLayer(i: integer): integer;
begin
  result := 6;
  if i <= HoriNdx5.v then
    result := 5;
  if i <= HoriNdx4.v then
    result := 4;
  if i <= HoriNdx3.v then
    result := 3;
  if i <= HoriNdx2.v then
    result := 2;
  if i <= HoriNdx1.v then
    result := 1;
end;

/// <summary>returns the texture class for horizon i</summary>
function TSoilWaterMod.getTexture(i: integer): TTextureClass;
// var
// nHorizons : integer;
begin
  // nHorizons := round(nHorizons.v);
  case GetHorizonIndexForLayer(i) of
    1:
      result := FTextureClass1;
    2:
      result := FTextureClass2;
    3:
      result := FTextureClass3;
    4:
      result := FTextureClass4;
    5:
      result := FTextureClass5;
  else
    result := FTextureClass6;
  end;
end;

/// <summary>returns the layer density class for horizon i</summary>
function TSoilWaterMod.getLD(i: integer): TLDClass;
// var
// nHorizons : integer;
begin
  // nHorizons := round(nHorizons.v);
  case GetHorizonIndexForLayer(i) of
    1:
      result := fLDClass1;
    2:
      result := FLDClass2;
    3:
      result := FLDClass3;
    4:
      result := FLDClass4;
    5:
      result := FLDClass5;
  else
    result := FLDClass6;
  end;
end;

/// <summary>creation of all parameters, options, states and external variables</summary>
procedure TSoilWaterMod.CreateAll;

var
  i: integer;

begin
  fShowWarnings := true;
  inherited CreateAll; // call TLayeredSoil.CreateAll
  m_model := Mualem; // set Genuchten model option to Mualem model
  CreateParameters; // Wrapper for parameter creation
  CreateOptions;
  CreateVars;
  CreateStates;
  ExternVCreate('Groundwaterdepth', '[cm]', StateField, Groundwaterdepth);
  if LowerBoundaryCondition = Groundwatertable then
    Groundwaterdepth.Search := true
  else
    Groundwaterdepth.Search := false;
  // if not (Netrain is TVar) then
  ExternVCreate('NetRain', '[mm/d]', StateField, NetRain,
    'rain minus interception');
  if not(Pot_Evap is TVAR) then
    ExternVCreate('PotEvap', '[mm/d]', StateField, TExternV(Pot_Evap));
  LowerBoundaryCondition := FreeFlow;
  // default for lower boundary is a free flow
end;

/// <summary>deallocation of dynamically created objects</summary>
procedure TSoilWaterMod.BeforeDestruction;
var
  i: integer;

begin
  for i := 1 to n_comp + 1 do
    if WPar[i] <> nil then
      FreeAndNil(WPar[i]);
  inherited;
end;

/// <summary>Transfer of soil water contents to next ini file if option is set</summary>
procedure TSoilWaterMod.TransferWGsToNextINI;
var
  i: integer;
  NextINI: TMemIniFile;
  NextStateINI: TMemIniFile;
  IniFileNdx: integer;
begin
  begin
    IniFileNdx := GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName);
    if (IniFileNdx <> GlobMod.IniFileNames.Count - 1) then
    begin
      // exit;
      NextINI := TMemIniFile.create
        (GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf
        (GlobMod.ActIniFile.FileName) + 1], TEncoding.UTF8);
      // NextINI.Init();
      NextStateINI := TMemIniFile.create(NextINI.ReadString('FileNames',
        'StateIniFN', ''), TEncoding.UTF8);
      // NextStateINI.Init(NextINI.ReadString('FileNames', 'StateIniFN', ''));
      for i := 1 to n_comp + 1 do
      begin
        NextStateINI.WriteString(Name, 'WG' + ndx_str(i),
          FloatToStrF(theta_arr[i].v, ffFixed, 9, 6));
      end;
      NextINI.UpdateFile;
      NextStateINI.UpdateFile;
      NextINI.Free;
      NextStateINI.Free;
    end;
  end;
end;

/// <summary>calculation of sums of plant available water for profile and rooting zone</summary>
procedure TSoilWaterMod.CalcProfile_and_HorizonSums;
var
  nFK0_100: real;
  i: integer;
  PWP0_Weff: real;
  nFK0_Weff: real;
  PWP0_100: real;
  WG0_Weff: real;
begin
  nFK0_100 := 0;
  PWP0_100 := 0;
  for i := 1 to 10 do
  begin
    nFK0_100 := nFK0_100 + nFK_Arr[i];
    PWP0_100 := PWP0_100 + PWP_Arr[i];
  end;
  ProzNFK0_100.v := (WG0_100.v - PWP0_100 / 10) / nFK0_100 * 1000;
  nFK0_Weff := 0;
  PWP0_Weff := 0;
  WG0_Weff := 0;
  for i := 1 to ndx_Weff do
  begin
    WG0_Weff := WG0_Weff + theta_arr[i].v * (Depth[i].v - Depth[i - 1].v);
    nFK0_Weff := nFK0_Weff + nFK_Arr[i] * (Depth[i].v - Depth[i - 1].v);
    PWP0_Weff := PWP0_Weff + PWP_Arr[i] * (Depth[i].v - Depth[i - 1].v);
  end;
  SumPAvSoilWaterRZ.v := (WG0_Weff - PWP0_Weff) * 10;
  ProzNFK0_Weff.v := (WG0_Weff - PWP0_Weff) / nFK0_Weff * 100;
  ProzNFK0_30.v := (WG0_30.v * 3 - (PWP_Arr[1] + PWP_Arr[2] + PWP_Arr[3])) /
    (nFK_Arr[1] + nFK_Arr[2] + nFK_Arr[3]) * 100;
end;

/// <summary>initialisation of daily sums and changes</summary>
procedure TSoilWaterMod.InitDailySums_and_Changes(var OldSumSoilwater: real);
var
  OldSumWater: real;
  OldPondedWater: real;
  i: integer;
begin
  SumOfInternalTimeSteps.v := 0;
  Act_Evap.v := 0;
  CumEvap.c := 0;
  CumDrainage.c := 0;
  CumRunoff.c := 0;
  PondedWater.c := 0;
  CumDayFlow1 := 0;
  OldPondedWater := PondedWater.v;
  OldSumSoilwater := SumSoilWater.v;
  OldSumWater := OldSumSoilwater + PondedWater.v;
  for i := 1 to n_comp + 1 do
    Wflow_arr[i].v := 0;
  n_int_timesteps.v := 0;
  dt.v := dt_old;
end;

/// <summary>calculation of global water balance</summary>
procedure TSoilWaterMod.CalcGlobalWaterBalance;
begin
  // Rain-W_loss-Trans-Evap-SW_diff
  old_global_WaterBalance := global_WaterBalance;
  global_WaterBalance := CumNetRain.v - (CumRunoff.v + CumDrainage.v) -
    CumTrans.v - CumEvap.v - (SumSoilWater.v + PondedWater.v - SWCStart);
  CumGlobalWaterBalance.c := abs(global_WaterBalance - old_global_WaterBalance);
end;

/// <summary>calculation of soil water balance for the soil profile</summary>
procedure TSoilWaterMod.CalcProfileWaterBalance(OldSumSoilwater: Extended);
begin
  if GlobTime.v > GlobMod.Starttime then
  begin
    CumWaterBalance.c := (SumSoilWater.v - OldSumSoilwater) +
      (-Wflow_arr[1].v * 10 + CumDrainage.c) * GlobTime.c;
  end;
  // [mm]
end;

/// <summary>calculation of total water amounts in the soil profile</summary>
procedure TSoilWaterMod.CalcTotalWaterAmounts;
var
  i: integer;
  SumWater: Extended;
begin
  SumSoilWater.v := 0;
  SumPAVSoilWater.v := 0;
  for i := 1 to trunc(bil_nr.v) do
  begin
    SumSoilWater.v := SumSoilWater.v + WAmount[i].v * 10;
    // [mm]
    SumPAVSoilWater.v := SumPAVSoilWater.v + WAmount[i].v * 10 - PWP_Arr[i] *
      Thick[i] * 10;
  end;
  SumWater := SumSoilWater.v + PondedWater.v;
end;

/// <summary>determination of number of computation layers for current time step considering the groundwater table</summary>
procedure TSoilWaterMod.Find_Number_of_computation_Layers;
begin
  // default value for computation index
  if Opt_Randbed = Groundwatertable then
  begin
    act_n_comp := 2;
    repeat
      inc(act_n_comp);
    until (Depth[act_n_comp + 1].v >= Groundwaterdepth.v) or
      (act_n_comp >= n_comp);
  end;
end;

/// <summary>save old values for Crank-Nicholson calculation of solute transport</summary>
procedure TSoilWaterMod.SaveOldValuesForCrankNicholson_SoluteTransport;
var
  i: integer;
begin
  // save old flows for Crank-Nicholson calculation of solute transport
  for i := 1 to n_comp + 1 do
  begin
    Wflow_old[i] := WflowInt_arr[i].v;
    theta_old[i] := theta_arr[i].v;
  end;
end;

procedure TSoilWaterMod.CheckForHoriIndexInitialisation;
begin
  if round(HoriNdx1.v) = 0 then
  begin
    if ShowWarnings then
    begin

{$IFNDEF NONVISUAL}
      showmessage
        ('Warning ! No specification of Indexes for hydraulic parameters');
      showmessage('Please check !');

{$ELSE}
      writeln('Warning ! No specification of Indexes for hydraulic parameters');
      writeln('Please check !');
{$ENDIF}
    end;
  end;
end;

/// <summary>set new psi and theta values after integration step</summary>
procedure TSoilWaterMod.SetNewPsi_and_Theta_Values;
var
  i: integer;
begin
  for i := 1 to n_comp + 1 do
  begin
    psi_neu[i] := psi_arr[i].v;
    theta_new[i] := theta_arr[i].v;
  end;
end;

/// <summary>calculation of FK, PWP and nFK for all horizons from van-Genuchten parameters</summary>
procedure TSoilWaterMod.Calc_nFKparsForHorizons;
var
  horizonIndex: integer;
  horizonBoundaries: array [1 .. 6] of TPar;
  fkPars: array [1 .. 6] of TPar;
  pwpPars: array [1 .. 6] of TPar;
  nfkPars: array [1 .. 6] of TPar;
  i: integer;
begin
  { Calculation von FK, PWP und nFK aus van-Genuchten-Parametern mit der Funktion b_psi_f (unit UGenucht) }
  horizonBoundaries[1] := HoriNdx1;
  horizonBoundaries[2] := HoriNdx2;
  horizonBoundaries[3] := HoriNdx3;
  horizonBoundaries[4] := HoriNdx4;
  horizonBoundaries[5] := HoriNdx5;
  horizonBoundaries[6] := HoriNdx6;

  fkPars[1] := Par_FK1;
  fkPars[2] := Par_FK2;
  fkPars[3] := Par_FK3;
  fkPars[4] := Par_FK4;
  fkPars[5] := FK5;
  fkPars[6] := FK6;

  pwpPars[1] := Par_PWP1;
  pwpPars[2] := Par_PWP2;
  pwpPars[3] := Par_PWP3;
  pwpPars[4] := Par_PWP4;
  pwpPars[5] := PWP5;
  pwpPars[6] := PWP6;

  nfkPars[1] := Par_nFK1;
  nfkPars[2] := Par_nFK2;
  nfkPars[3] := Par_nFK3;
  nfkPars[4] := Par_nFK4;
  nfkPars[5] := nFK5;
  nfkPars[6] := nFK6;

  for i := 1 to 6 do
  begin
    horizonIndex := round(horizonBoundaries[i].v);
    fkPars[i].v := WPar[horizonIndex].b_psi_f(power(10, 1.8));
    pwpPars[i].v := WPar[horizonIndex].b_psi_f(power(10, 4.2));
    nfkPars[i].v := fkPars[i].v - pwpPars[i].v;
  end;
end;

/// <summary>calculation of sums of plant available water for profile and rooting zone</summary>
procedure TSoilWaterMod.Calc_nFK(psiFK: Extended; psiWP: Extended);

var
  PWP0_100: Extended;
  nFK0_100: Extended;

  nFK0_Weff: real;
  PWP0_Weff: real;
  WG0_Weff: real;
  i: integer;

begin
  nFK0_100 := 0;
  PWP0_100 := 0;
  for i := 1 to 10 do
  begin
    nFK0_100 := nFK0_100 + nFK_Arr[i];
    PWP0_100 := PWP0_100 + PWP_Arr[i];
  end;
  ProzNFK0_100.v := (WG0_100.v - PWP0_100 / 10) / nFK0_100 * 1000;
  ndx_Weff := 0;

  if (fWeffOpt = fromPlantmodel) and IsPlantModelSet then
  begin
    repeat
      inc(ndx_Weff);
    until Depth[ndx_Weff].v >= Plantmodel.Weff;
  end
  else
  begin
    repeat
      inc(ndx_Weff);
    until Depth[ndx_Weff].v >= Weff.v;
  end;

  nFK0_Weff := 0;
  PWP0_Weff := 0;
  WG0_Weff := 0;
  for i := 1 to ndx_Weff do
  begin
    WG0_Weff := WG0_Weff + theta_arr[i].v;
    nFK0_Weff := nFK0_Weff + nFK_Arr[i];
    PWP0_Weff := PWP0_Weff + PWP_Arr[i];
  end;
  SumPAvSoilWaterRZ.v := WG0_Weff - PWP0_Weff;
  ProzNFK0_Weff.v := (WG0_Weff - PWP0_Weff) / nFK0_Weff * 100;
  ProzNFK0_30.v := (WG0_30.v * 3 - (PWP_Arr[1] + PWP_Arr[2] + PWP_Arr[3])) /
    (nFK_Arr[1] + nFK_Arr[2] + nFK_Arr[3]) * 100;

end;

/// <summary>set option for evaporation reduction method</summary>
procedure TSoilWaterMod.SetEvaporationReductionOption;
begin
  if uppercase(red_fOption.Option) = 'MODIFIEDBEESE' then
    fred_f := modifiedBeese;
  if uppercase(red_fOption.Option) = 'BEESE1978' then
    fred_f := Beese1978;
end;

/// <summary>set option for lower boundary condition</summary>
procedure TSoilWaterMod.SetLowerBoundaryCondition;
begin
  if uppercase(OptLowerBoundary.Option) = 'CONSTCONTENT' then
    LowerBoundaryCondition := ConstContent;
  if uppercase(OptLowerBoundary.Option) = 'NOFLUX' then
    LowerBoundaryCondition := NoFlow;
  if uppercase(OptLowerBoundary.Option) = 'GROUNDWATER' then
    LowerBoundaryCondition := Groundwatertable;
  if uppercase(OptLowerBoundary.Option) = 'FREEFLOW' then
    LowerBoundaryCondition := FreeFlow;
  if LowerBoundaryCondition = Groundwatertable then
    Groundwaterdepth.Search := true
  else
    Groundwaterdepth.Search := false;
end;

/// <summary>set van-Genuchten parameters from texture classes</summary>
procedure TSoilWaterMod.SetGenuchtenPars;
var
  i: integer;
begin
  setTextClassOption(FTextureClass1, FTextClass1Option.Option);
  setTextClassOption(FTextureClass2, FTextClass2Option.Option);
  setTextClassOption(FTextureClass3, FTextClass3Option.Option);
  setTextClassOption(FTextureClass4, FTextClass4Option.Option);
  setTextClassOption(FTextureClass5, FTextClass5Option.Option);
  setTextClassOption(FTextureClass6, FTextClass6Option.Option);

  if FVGParsFromTexture = FromTexture then
  begin
    for i := 1 to round(HoriNdx1.v) do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
      begin
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass1);
      end
      else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass1);
      WPar[i].Ks := Ks1.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine:
          WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken:
          WPar[i].m_par := 1;
      end;
    end;
    for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass2)
      else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass2);
      WPar[i].Ks := Ks2.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine:
          WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken:
          WPar[i].m_par := 1;
      end;
    end;
    for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass3)
      else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass3);
      WPar[i].Ks := Ks3.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine:
          WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken:
          WPar[i].m_par := 1;
      end;
    end;
    for i := round(HoriNdx3.v) + 1 to round(HoriNdx4.v) do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass4)
      else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass4);
      WPar[i].Ks := Ks4.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine:
          WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken:
          WPar[i].m_par := 1;
      end;
    end;
    for i := round(HoriNdx4.v) + 1 to round(HoriNdx5.v) do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass5)
      else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass5);
      WPar[i].Ks := Ks5.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine:
          WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken:
          WPar[i].m_par := 1;
      end;
    end;
    for i := round(HoriNdx5.v) + 1 to n_comp + 1 do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass6)
      else
        VanGenuchtenFromTextureClass_KA(WPar[i], FTextureClass6);
      WPar[i].Ks := Ks6.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine:
          WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken:
          WPar[i].m_par := 1;
      end;
    end;
  end
  else
  begin
    { FVGParsFromTexture = FromPar }
    for i := 1 to round(HoriNdx1.v) do
    begin
      WPar[i].b_sat := b_sat1.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest1.v;
      WPar[i].alpha := alpha1.v * alpha_scaling.v;
      WPar[i].n_par := n_par1.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / n_par1.v;
        Burdine:
          WPar[i].m_par := 1 - 2 / n_par1.v;
        Vereecken:
          WPar[i].m_par := 1;
      end;
      WPar[i].l_par := l_par1.v;
      WPar[i].Ks := Ks1.v;
    end;
    for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
    begin
      WPar[i].b_sat := b_sat2.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest2.v;
      WPar[i].alpha := alpha2.v * alpha_scaling.v;
      WPar[i].n_par := n_par2.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / n_par2.v;
        Burdine:
          WPar[i].m_par := 1 - 2 / n_par2.v;
        Vereecken:
          WPar[i].m_par := 1;
      end;
      WPar[i].l_par := l_par2.v;
      WPar[i].Ks := Ks2.v;
    end;
    for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
    begin
      WPar[i].b_sat := b_sat3.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest3.v;
      WPar[i].alpha := alpha3.v * alpha_scaling.v;
      WPar[i].n_par := n_par3.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / n_par3.v;
        Burdine:
          WPar[i].m_par := 1 - 2 / n_par3.v;
        Vereecken:
          WPar[i].m_par := 1;
      end;
      WPar[i].l_par := l_par3.v;
      WPar[i].Ks := Ks3.v;
    end;
    for i := round(HoriNdx3.v) + 1 to round(HoriNdx4.v) do
    begin
      WPar[i].b_sat := b_sat5.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest5.v;
      WPar[i].alpha := alpha5.v * alpha_scaling.v;
      WPar[i].n_par := n_par5.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / n_par5.v;
        Burdine:
          WPar[i].m_par := 1 - 2 / n_par5.v;
        Vereecken:
          WPar[i].m_par := 1;
      end;
      WPar[i].l_par := l_par5.v;
      WPar[i].Ks := Ks5.v;
    end;
    for i := round(HoriNdx5.v) + 1 to n_comp + 1 do
    begin
      WPar[i].b_sat := b_sat6.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest6.v;
      WPar[i].alpha := alpha6.v * alpha_scaling.v;
      WPar[i].n_par := n_par6.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / n_par6.v;
        Burdine:
          WPar[i].m_par := 1 - 2 / n_par6.v;
        Vereecken:
          WPar[i].m_par := 1;
      end;
      WPar[i].l_par := l_par6.v;
      WPar[i].Ks := Ks6.v;
    end;

  end;
  if FKsFromTexture = FromTexture then
  begin
    for i := 1 to round(HoriNdx1.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass1, fLD1)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass1);
    for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass2, fLD2)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass2);
    for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass3, fLD3)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass3);
    for i := round(HoriNdx3.v) + 1 to round(HoriNdx4.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass4, fLD4)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass4);
    for i := round(HoriNdx4.v) + 1 to round(HoriNdx5.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass5, fLD5)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass5);
    for i := round(HoriNdx5.v) + 1 to n_comp + 1 do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass6, fLD6)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass6);
  end;

  if fWriteParsFromTexture then
  begin
    ParIniF.WriteFloat(Name, Par_b_sat1.Name, WPar[trunc(HoriNdx1.v)].b_sat);
    ParIniF.WriteFloat(Name, Par_b_sat2.Name, WPar[trunc(HoriNdx2.v)].b_sat);
    ParIniF.WriteFloat(Name, Par_b_sat3.Name, WPar[trunc(HoriNdx3.v)].b_sat);
    ParIniF.WriteFloat(Name, Par_b_sat4.Name, WPar[trunc(HoriNdx4.v)].b_sat);
    ParIniF.WriteFloat(Name, Par_b_sat5.Name, WPar[trunc(HoriNdx5.v)].b_sat);
    ParIniF.WriteFloat(Name, Par_b_sat6.Name, WPar[trunc(HoriNdx6.v)].b_sat);
    ParIniF.WriteFloat(Name, Par_b_rest1.Name, WPar[trunc(HoriNdx1.v)].b_rest);
    ParIniF.WriteFloat(Name, Par_b_rest2.Name, WPar[trunc(HoriNdx2.v)].b_rest);
    ParIniF.WriteFloat(Name, Par_b_rest3.Name, WPar[trunc(HoriNdx3.v)].b_rest);
    ParIniF.WriteFloat(Name, Par_b_rest4.Name, WPar[trunc(HoriNdx4.v)].b_rest);
    ParIniF.WriteFloat(Name, Par_b_rest5.Name, WPar[trunc(HoriNdx5.v)].b_rest);
    ParIniF.WriteFloat(Name, Par_b_rest6.Name, WPar[trunc(HoriNdx6.v)].b_rest);
    ParIniF.WriteFloat(Name, Par_alpha1.Name, WPar[trunc(HoriNdx1.v)].alpha);
    ParIniF.WriteFloat(Name, Par_alpha2.Name, WPar[trunc(HoriNdx2.v)].alpha);
    ParIniF.WriteFloat(Name, Par_alpha3.Name, WPar[trunc(HoriNdx3.v)].alpha);
    ParIniF.WriteFloat(Name, Par_alpha4.Name, WPar[trunc(HoriNdx4.v)].alpha);
    ParIniF.WriteFloat(Name, Par_alpha5.Name, WPar[trunc(HoriNdx5.v)].alpha);
    ParIniF.WriteFloat(Name, Par_alpha6.Name, WPar[trunc(HoriNdx6.v)].alpha);
    ParIniF.WriteFloat(Name, Par_n1.Name, WPar[trunc(HoriNdx1.v)].n_par);
    ParIniF.WriteFloat(Name, Par_n2.Name, WPar[trunc(HoriNdx2.v)].n_par);
    ParIniF.WriteFloat(Name, Par_n3.Name, WPar[trunc(HoriNdx3.v)].n_par);
    ParIniF.WriteFloat(Name, Par_n4.Name, WPar[trunc(HoriNdx4.v)].n_par);
    ParIniF.WriteFloat(Name, Par_n5.Name, WPar[trunc(HoriNdx5.v)].n_par);
    ParIniF.WriteFloat(Name, Par_n6.Name, WPar[trunc(HoriNdx6.v)].n_par);
    ParIniF.WriteFloat(Name, Par_lpar1.Name, WPar[trunc(HoriNdx1.v)].l_par);
    ParIniF.WriteFloat(Name, Par_lpar2.Name, WPar[trunc(HoriNdx2.v)].l_par);
    ParIniF.WriteFloat(Name, Par_lpar3.Name, WPar[trunc(HoriNdx3.v)].l_par);
    ParIniF.WriteFloat(Name, Par_lpar4.Name, WPar[trunc(HoriNdx4.v)].l_par);
    ParIniF.WriteFloat(Name, Par_lpar5.Name, WPar[trunc(HoriNdx5.v)].l_par);
    ParIniF.WriteFloat(Name, Par_lpar6.Name, WPar[trunc(HoriNdx6.v)].l_par);
    ParIniF.WriteFloat(Name, Par_b_KS1.Name, WPar[trunc(HoriNdx1.v)].Ks);
    ParIniF.WriteFloat(Name, Par_b_KS2.Name, WPar[trunc(HoriNdx2.v)].Ks);
    ParIniF.WriteFloat(Name, Par_b_KS3.Name, WPar[trunc(HoriNdx3.v)].Ks);
    ParIniF.WriteFloat(Name, Par_b_KS4.Name, WPar[trunc(HoriNdx4.v)].Ks);
    ParIniF.WriteFloat(Name, Par_b_KS5.Name, WPar[trunc(HoriNdx5.v)].Ks);
    ParIniF.WriteFloat(Name, Par_b_KS6.Name, WPar[trunc(HoriNdx6.v)].Ks);
  end;
  if ParIniF <> nil then
    ParIniF.UpdateFile;

end;

/// <summary>set texture classes for horizons</summary>
procedure TSoilWaterMod.SetLDPars;
var
  i: integer;
begin
  setLDClassOption(fLDClass1, fLDClass1Option.Option);
  setLDClassOption(FLDClass2, fLDClass2Option.Option);
  setLDClassOption(FLDClass3, fLDClass3Option.Option);
  setLDClassOption(FLDClass4, fLDClass4Option.Option);
  setLDClassOption(FLDClass5, fLDClass5Option.Option);
  setLDClassOption(FLDClass6, fLDClass6Option.Option);

  if ParIniF <> nil then
    ParIniF.UpdateFile;

end;

procedure TSoilWaterMod.SetLDnumbers;
var
  i: integer;
begin
  setLDOption(fLD1, fLD1Option.Option);
  setLDOption(fLD2, fLD2Option.Option);
  setLDOption(fLD3, fLD3Option.Option);
  setLDOption(fLD4, fLD4Option.Option);
  setLDOption(fLD5, fLD5Option.Option);
  setLDOption(fLD6, fLD6Option.Option);

  if ParIniF <> nil then
    ParIniF.UpdateFile;

end;

/// <summary>initialisation of vectors for soil water calculation</summary>
procedure TSoilWaterMod.InitVectors;
var
  i: integer;
begin
  for i := 0 to max_comp + 1 do
  begin
    /// <summary>soil water diffusivities [cm2/d] }</summary>
    Dw_arr[i] := 0;
    /// <summary>specific water capacity</summary>
    c_arr[i] := 0;
    /// <summary>intermediate variable dt.v/(C_arr*??)</summary>
    P[i] := 0;
    /// <summary>saturated hydraulic conductivities [cm/d]</summary>
    kf[i] := 0;
    /// <summary>unsaturated hydraulic conductivities [cm/d]</summary>
    Ku_arr[i] := 0;
    /// <summary>mean diffusivity between two compartments [cm2/d]</summary>
    avg_Dw[i] := 0;
    /// <summary>mean unsaturated hydraulic conductivity between two compartments [cm/d]</summary>
    avg_Ku[i] := 0;
    /// <summary>Intermediate variable</summary>
    Dw_fact[i] := 0;
    /// <summary>Intermediate variable</summary>
    Ku_fact[i] := 0;
    /// <summary>Intermediate variable[i] := 0.0; known values and solution vektor</summary>
    B_vektor[i] := 0;
    /// <summary>lower vector of the tri-diagonal matrix</summary>
    lower[i] := 0;
    /// <summary>central vector of the tri-diagonal matrix</summary>
    diag[i] := 0;
    /// <summary>upper vector of the tri-diagonal matrix</summary>
    upper[i] := 0;
    /// <summary>water contents at the last iteration [cm3/cm3]</summary>
    last_iter_theta[i] := 0;
    est_theta[i] := 0;
    /// <summary>new soil water contents</summary>
    theta_new[i] := 0;
    /// <summary>field capacity [cm3/cm3]</summary>
    FK_Arr[i] := 0;
    /// <summary>permanent wilting point [cm3/cm3]</summary>
    PWP_Arr[i] := 0;
    /// <summary>usable field capacity [cm3/cm3]</summary>
    nFK_Arr[i] := 0;
    /// <summary>previous water flows [cm/d]</summary>
    Wflow_old[i] := 0;
    /// <summary>previous water contents</summary>
    theta_old[i] := 0;
    /// <summary>New estimate of water potential [cm]</summary>
    psi_neu[i] := 0;
    SW_Balance_arr[i] := 0;
    cumSW_Balance_arr[i] := 0;
    alpha[i] := 0;
    beta[i] := 0;
    gamma[i] := 0;
    Res[i] := 0;
    upper[i] := 0;
    diag[i] := 0;
    lower[i] := 0;
    B_vektor[i] := 0;
    wf[i] := 1;
    Wflow_old[i] := 0;
    // WAmount[i].v := 0.0;
  end;
  for i := 1 to n_comp + 1 do
  begin
    psi_arr[i].Digits := PSI_dummy.Digits;
    psi_arr[i].Precision := PSI_dummy.Precision;
  end;
end;

procedure TSoilWaterMod.SetCompMethod;
begin
  if uppercase(OptCompMethod.Option) = 'DIFFUSION' then
    fCompMethod := Diffusion;
  if uppercase(OptCompMethod.Option) = 'RICHARDS' then
    fCompMethod := Richards;
  if uppercase(OptCompMethod.Option) = 'CAPACITY' then
    fCompMethod := Capacity;
  if uppercase(OptCompMethod.Option) = 'MIXED' then
    fCompMethod := Mixed;
  if uppercase(OptCompMethod.Option) = 'MIXEDHYDRUS' then
    fCompMethod := MixedHydrus;
end;

procedure TSoilWaterMod.InitGenuchtenPars;
var
  i: integer;
begin
  for i := 1 to round(HoriNdx1.v) do
  begin
    WPar[i].b_sat := b_sat1.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest1.v;
    WPar[i].alpha := alpha1.v * alpha_scaling.v;
    WPar[i].n_par := n_par1.v;
    WPar[i].l_par := l_par1.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par1.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par1.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := l_par1.v;
    WPar[i].Ks := Ks1.v;
  end;
  for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
  begin
    WPar[i].b_sat := b_sat2.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest2.v;
    WPar[i].alpha := alpha2.v * alpha_scaling.v;
    WPar[i].n_par := n_par2.v;
    WPar[i].l_par := l_par2.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par2.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par2.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := l_par2.v;
    WPar[i].Ks := Ks2.v;
  end;
  for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
  begin
    WPar[i].b_sat := b_sat3.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest3.v;
    WPar[i].alpha := alpha3.v * alpha_scaling.v;
    WPar[i].n_par := n_par3.v;
    WPar[i].l_par := l_par3.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par3.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par3.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := l_par3.v;
    WPar[i].Ks := Ks3.v;
  end;
  for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
  begin
    WPar[i].b_sat := b_sat4.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest4.v;
    WPar[i].alpha := alpha4.v * alpha_scaling.v;
    WPar[i].n_par := n_par4.v;
    WPar[i].l_par := l_par4.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par4.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par4.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := l_par4.v;
    WPar[i].Ks := Ks4.v;
  end;
  for i := round(HoriNdx4.v) + 1 to n_comp + 1 do
  begin
    WPar[i].b_sat := b_sat5.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest5.v;
    WPar[i].alpha := alpha5.v * alpha_scaling.v;
    WPar[i].n_par := n_par5.v;
    WPar[i].l_par := l_par5.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par5.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par5.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := l_par5.v;
    WPar[i].Ks := Ks5.v;
  end;
  for i := round(HoriNdx5.v) + 1 to n_comp + 1 do
  begin
    WPar[i].b_sat := b_sat6.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest6.v;
    WPar[i].alpha := alpha6.v * alpha_scaling.v;
    WPar[i].n_par := n_par6.v;
    WPar[i].l_par := l_par6.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par6.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par6.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := l_par6.v;
    WPar[i].Ks := Ks6.v;
  end;

end;

procedure TSoilWaterMod.CreateVars;
var
  i: integer;
begin
  for i := 1 to n_comp + 1 do
  begin
    VarCreate('WG' + ndx_str(i), '[cm3.cm-3]', 0.3, true, theta_arr[i],
      'soil water content vector [cm3/cm3]');
    theta_arr[i].ReadFromIniFile := true;
    VarCreate('Psi' + ndx_str(i), '[cm]', WPar[i].psi_b_f(theta_arr[i].v), true,
      psi_arr[i], 'soil water potential vector [cm]');
    VarCreate('WFlowInt' + ndx_str(i), '[cm.d-1]', 0, false, WflowInt_arr[i]);
    WflowInt_arr[i].writetoFile := false;
    VarCreate('WFlow' + ndx_str(i), '[cm.d-1]', 0, false, Wflow_arr[i],
      'flow vector [cm/d]');
    Wflow_arr[i].writetoFile := true;
    VarCreate('Sink' + ndx_str(i), '[cm.d-1]', 0, false, Sink_arr[i],
      'sink vector [cm]');
    VarCreate('SinkInt_' + ndx_str(i), '[cm.d-1]', 0, false, SinkInt_arr[i]);
    SinkInt_arr[i].writetoFile := false;
  end;
  VarCreate('red_evap', '[]', 1, false, red_evap,
    'reduction factor for evaporation');
  VarCreate('act_evap', '[mm/d]', 0, false, Act_Evap,
    'actual daily evaporation rate');
  VarCreate('dt_int', '[d]', 0.1, false, dt, 'internal time step length');
  VarCreate('Exfiltration', '[mm]', 0.0, true, Exfiltration);
  VarCreate('SumSoilWater', '[mm]', 0.0, true, SumSoilWater,
    'sum of soil water in entire profile');
  VarCreate('SumPavSoilWater', '[mm]', 0.0, true, SumPAVSoilWater,
    'sum of plant available soil water in entire profile');
  VarCreate('SumPAvSoilWaterRZ', '[mm]', 0.0, true, SumPAvSoilWaterRZ,
    'sum of plant available soil water in the rooting zone (down to Weff)');
  VarCreate('psi_dummy', '[]', 0.0, true, PSI_dummy);
  VarCreate('n_int_timesteps', '[]', 0.0, true, n_int_timesteps,
    'number of internal daily time steps');
  VarCreate('sumof_internaltimesteps', '[]', 0.0, true, SumOfInternalTimeSteps,
    'total number of time steps of water balance calculation over simulation period');
  VarCreate('global_iter', '[]', 0.0, true, global_iter,
    'total number of iterations over the current run');

  VarCreate('WG0_30', '[cm3/cm3]', 0.0, false, WG0_30);
  VarCreate('WG0_40', '[cm3/cm3]', 0.0, false, WG0_40);
  VarCreate('WG30_60', '[cm3/cm3]', 0.0, false, WG30_60);
  VarCreate('WG60_90', '[cm3/cm3]', 0.0, false, WG60_90);
  VarCreate('WG90_120', '[cm3/cm3]', 0.0, false, WG90_120);
  VarCreate('WG0_60', '[cm3/cm3]', 0.0, false, WG0_60);
  VarCreate('WG0_10', '[cm3/cm3]', 0.0, false, WG0_10);
  VarCreate('WG0_20', '[cm3/cm3]', 0.0, false, WG0_20);
  VarCreate('WG10_30', '[cm3/cm3]', 0.0, false, WG10_30);
  VarCreate('WG20_30', '[cm3/cm3]', 0.0, false, WG20_30);
  VarCreate('WG20_40', '[cm3/cm3]', 0.0, false, WG20_40);
  VarCreate('WG30_40', '[cm3/cm3]', 0.0, false, WG30_40);
  VarCreate('WG30_50', '[cm3/cm3]', 0.0, false, WG30_50);
  VarCreate('WG30_120', '[cm3/cm3]', 0.0, false, WG30_120);
  VarCreate('WG30_100', '[cm3/cm3]', 0.0, false, WG30_100);
  VarCreate('WG40_60', '[cm3/cm3]', 0.0, false, WG40_60);
  VarCreate('WG60_80', '[cm3/cm3]', 0.0, false, WG60_80);
  VarCreate('WG80_100', '[cm3/cm3]', 0.0, false, WG80_100);
  VarCreate('WG90_110', '[cm3/cm3]', 0.0, false, WG90_110);
  VarCreate('WG0_100', '[cm3/cm3]', 0.0, false, WG0_100);
  VarCreate('WG0_120', '[cm3/cm3]', 0.0, false, WG0_120);
  VarCreate('WG0_90', '[cm3/cm3]', 0.0, false, wg0_90);
  VarCreate('WG60_100', '[cm3/cm3]', 0.0, false, WG60_100);
  VarCreate('ProzNFK0_Weff', '[%]', 0.0, false, ProzNFK0_Weff);
  VarCreate('ProzNFK0_100', '[%]', 0.0, false, ProzNFK0_100);
  VarCreate('ProzNFK0_30', '[%]', 0.0, false, ProzNFK0_30,
    'proportion of plant available water at field capacity in percent from 0-30cm');

end;

procedure TSoilWaterMod.CreateStates;
var
  i: integer;
begin
  StateCreate('CumGlobalWaterBalance', '[mm]', 0, true, CumGlobalWaterBalance);
  StateCreate('CumEvap', '[mm]', 0, true, CumEvap, 'Cumulative evaporation');
  StateCreate('CumDrainage', '[mm]', 0, true, CumDrainage,
    'cumulative water loss at layer xx');
  StateCreate('CumWaterBalance', '[mm]', 0, true, CumWaterBalance,
    'water balance calculated from total soil profile changes [mm]');
  // StateCreate('CumAbsWaterBalance', '[mm]', 0, true, CumAbsWaterBalance);
  StateCreate('CumRunoff', '[mm]', 0, true, CumRunoff,
    'calculated survace run off');
  StateCreate('CumTrans', '[mm]', 0, true, CumTrans,
    'cumulative transpiration');
  StateCreate('CumNetRain', '[mm]', 0, true, CumNetRain,
    'cumulative rain minus interception');
  StateCreate('PondedWater', '[mm]', 0, false, PondedWater,
    'Amount of ponded water on soil surface');
  for i := 1 to n_comp + 1 do
  begin
    StateCreate('WMenge' + ndx_str(i), '[cm]', theta_arr[i].v * Thick[i], false,
      WAmount[i], 'Water amount per layer [cm]');
    WAmount[i].ReadFromIniFile := false;
  end;
end;

procedure TSoilWaterMod.CreateOptions;
begin
  OptCreate('FVGParsFromTexture', 'FromPar', FVGParsFromTextOption,
    'Option for Initialisation of Van Genuchten Parameters, parameters are estimated from texture with pedotransfer function if option is fromtexture');
  FVGParsFromTextOption.OptionList.Clear;
  FVGParsFromTextOption.OptionList.Add('FromPar');
  FVGParsFromTextOption.OptionList.Add('FromTexture');
  { OptCreate('Texture_version', 'RR', Texture_versionOption);
    Texture_versionOption.OptionList.Clear;
    Texture_versionOption.OptionList.Add('RR');
    Texture_versionOption.OptionList.Add('KA'); }

  OptCreate('FKsFromTexture', 'FromPar', FKsFromTextOption,'Option to take Ks values either from a texture based table or as specific parameter values');
  FKsFromTextOption.OptionList.Clear;
  FKsFromTextOption.OptionList.Add('FromPar');
  FKsFromTextOption.OptionList.Add('FromTexture');

  OptCreate('act_Evaporation', 'red_f', act_EvaporationOption,
    'Option for calculation actual evaporation, red_f is recommended, inclExfiltration experimental');
  act_EvaporationOption.OptionList.Clear;
  act_EvaporationOption.OptionList.Add('red_f');
  act_EvaporationOption.OptionList.Add('inclExfiltration');

  OptCreate('evaporation red_f', 'modifiedBeese', red_fOption,
    'Option for calculation evaporation reduction factor from soil water potential in first layer, modifiedBeese is standard');
  red_fOption.OptionList.Clear;
  red_fOption.OptionList.Add('modifiedBeese');
  red_fOption.OptionList.Add('Beese1978');
  red_fOption.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/Soil/Documentation/TSoilWaterModelR.html#soil-evaporation';



  OptCreate('FTextureClass1', 'Sl3', TOption(FTextClass1Option),
    'texture class for first horizon');
  OptCreate('FTextureClass2', 'Sl3', TOption(FTextClass2Option),
    'texture class for second horizon');
  OptCreate('FTextureClass3', 'Sl3', TOption(FTextClass3Option),
    'texture class for third horizon');
  OptCreate('FTextureClass4', 'Sl3', TOption(FTextClass4Option),
    'texture class for fourth horizon');
  OptCreate('FTextureClass5', 'Sl3', TOption(FTextClass5Option),
    'texture class for fourth horizon');
  OptCreate('FTextureClass6', 'Sl3', TOption(FTextClass6Option),
    'texture class for fourth horizon');
  FTextClass1Option.AddTextureClasses;
  FTextClass2Option.AddTextureClasses;
  FTextClass3Option.AddTextureClasses;
  FTextClass4Option.AddTextureClasses;
  FTextClass5Option.AddTextureClasses;
  FTextClass6Option.AddTextureClasses;
  // Options for lower boundary: NoFlow, Flow, Content, Groundwatertable

  OptCreate('FLDClass1', 'LD3', TOption(fLDClass1Option),
    'layer density class for first horizon');
  OptCreate('FLDClass2', 'LD3', TOption(fLDClass2Option),
    'layer density class for second horizon');
  OptCreate('FLDClass3', 'LD3', TOption(fLDClass3Option),
    'layer density class for third horizon');
  OptCreate('FLDClass4', 'LD3', TOption(fLDClass4Option),
    'layer density class for fourth horizon');
  OptCreate('FLDClass5', 'LD3', TOption(fLDClass5Option),
    'layer density class for fifth horizon');
  OptCreate('FLDClass6', 'LD3', TOption(fLDClass6Option),
    'layer density class for sixth horizon');
  fLDClass1Option.AddLDClasses;
  fLDClass2Option.AddLDClasses;
  fLDClass3Option.AddLDClasses;
  fLDClass4Option.AddLDClasses;
  fLDClass5Option.AddLDClasses;
  fLDClass6Option.AddLDClasses;

  /// summary> set options for numerical bulk density classes </summary>

  OptCreate('fLD1', 'OldVersion', TOption(fLD1Option),
    'numerical layer density for first horizon');
  OptCreate('fLD2', 'OldVersion', TOption(fLD2Option),
    'numerical layer density for second horizon');
  OptCreate('fLD3', 'OldVersion', TOption(fLD3Option),
    'numerical layer density for third horizon');
  OptCreate('fLD4', 'OldVersion', TOption(fLD4Option),
    'numerical layer density for fourth horizon');
  OptCreate('fLD5', 'OldVersion', TOption(fLD5Option),
    'numerical layer density for fifth horizon');
  OptCreate('fLD6', 'OldVersion', TOption(fLD6Option),
    'numerical layer density for sixth horizon');

  fLD1Option.AddLD;
  fLD2Option.AddLD;
  fLD3Option.AddLD;
  fLD4Option.AddLD;
  fLD5Option.AddLD;
  fLD6Option.AddLD;

  OptCreate('Untere_Randb', 'freeflow', OptLowerBoundary,
    'Option for lower boundary condition, 4 options implemented, constant water content/matrix potential (ConstContent), n_comp + 1 keeps constant, (FreeFlow) (NoFlow)');
  OptLowerBoundary.OptionList.Add('ConstContent');
  OptLowerBoundary.OptionList.Add('NoFlux');
  OptLowerBoundary.OptionList.Add('Groundwater');
  OptLowerBoundary.OptionList.Add('FreeFlow');

  OptCreate('IniMethod', 'Parameter', OptIniMethod,
    'Option for initialisation method, Watercontents: inital water' +
    'content data are provided; Potentials: intial soil water matrix potential is provided, Parameter: initial soil water content is calculated from a matrix potential in the first layer.No license found');
  OptIniMethod.OptionList.Clear;
  OptIniMethod.OptionList.Add('Watercontents');
  OptIniMethod.OptionList.Add('Potentials');
  OptIniMethod.OptionList.Add('Parameter');
  if Opt_IniMethod = Watercontents then
    OptIniMethod.Option := 'watercontents';
  if Opt_IniMethod = Potentials then
    OptIniMethod.Option := 'potentials';
  if Opt_IniMethod = Parameter then
    OptIniMethod.Option := 'parameter';
  fCompMethod := Diffusion;

  // Default Computational option is diffusion
  OptCreate('CompMethod', 'Diffusion', OptCompMethod,
    'Option for numerical solution of water transport equation: Diffusion not strictly correct for layer soil but fast or MixedHydrus are recommendet. The other options are experimental/outdated');
  OptCompMethod.OptionList.Clear;
  OptCompMethod.OptionList.Add('Diffusion');
  OptCompMethod.OptionList.Add('Richards');
  OptCompMethod.OptionList.Add('Mixed');
  OptCompMethod.OptionList.Add('MixedHydrus');
  OptCompMethod.OptionList.Add('Capacity');

  // OptWriteParsFromTexture
  OptCreate('WriteParsFromTexture?', 'false', OptWriteParsFromTexture,
    'Option writing Van Genuchten-Pars from Texture estimates to Param-Ini-file');
  OptWriteParsFromTexture.OptionList.Clear;
  OptWriteParsFromTexture.OptionList.Add('false');
  OptWriteParsFromTexture.OptionList.Add('true');

  OptCreate('Transfer water contents to next IniFile?', 'false',
    OptTransferWGToNextIniFile,
    'Option writing water contents from end of simulation to next StateIni-file as initial values');
  OptTransferWGToNextIniFile.OptionList.Clear;
  OptTransferWGToNextIniFile.OptionList.Add('false');
  OptTransferWGToNextIniFile.OptionList.Add('true');

end;

procedure TSoilWaterMod.CreateHorizonParameters;
type
  THorizonDefaults = record
    b_sat: real;
    b_rest: real;
    alpha: real;
    n_par: real;
    l_par: real;
    Ks: real;
    FK: real;
    nFK: real;
    PWP: real;
  end;
var
  defaults: THorizonDefaults;
  i: integer;
begin
  defaults.b_sat := 0.4298;
  defaults.b_rest := 0.09;
  defaults.alpha := 0.00677;
  defaults.n_par := 1.29494;
  defaults.l_par := 0.5;
  defaults.Ks := 50;
  defaults.FK := 0.35;
  defaults.nFK := 0.25;
  defaults.PWP := 0.1;



// Create parameters for all 6 horizons
// has to be without a loop because of the ParCreate procedure
    ParCreate('b_sat1', '[cm3.cm-3]', defaults.b_sat,
      b_sat1, 'Van Genuchten parameter b_sat');
    ParCreate('b_rest1', '[cm3.cm-3]', defaults.b_rest,
      b_rest1, 'Van Genuchten parameter b_rest');
    ParCreate('alpha1', '[1/cm]', defaults.alpha, alpha1,
      'Van Genuchten parameter alpha for horizon 1',);
    ParCreate('n_par1', '[-]', defaults.n_par,
      n_par1, 'Van Genuchten parameter n');
    ParCreate('l_par1', '[-]', defaults.l_par,
      l_par1, 'Van Genuchten parameter l for 1th horizon',);
    ParCreate('Ks_1', '[-]', defaults.Ks, Ks1,
      'Van Genuchten parameter K_sat');
    ParCreate('FK_1', '[cm3/cm3]', defaults.FK, FK1,
      'field capacity');
    ParCreate('nFK_1', '[cm3/cm3]', defaults.nFK,
      nFK1, 'plant available soil water content');
    ParCreate('PWP_1', '[cm3/cm3]', defaults.PWP,
      PWP1, 'residual soil water, not plant available content');


    ParCreate('b_sat2', '[cm3.cm-3]', defaults.b_sat,
      b_sat2, 'Van Genuchten parameter b_sat');
    ParCreate('b_rest2', '[cm3.cm-3]', defaults.b_rest,
      b_rest2, 'Van Genuchten parameter b_rest');
    ParCreate('alpha2', '[1/cm]', defaults.alpha, alpha2,
      'Van Genuchten parameter alpha for horizon 2',);
    ParCreate('n_par2', '[-]', defaults.n_par,
      n_par2, 'Van Genuchten parameter n');
    ParCreate('l_par2', '[-]', defaults.l_par,
      l_par2, 'Van Genuchten parameter l for 2th horizon',);
    ParCreate('Ks_2', '[-]', defaults.Ks, Ks2,
      'Van Genuchten parameter K_sat');
    ParCreate('FK_2', '[cm3/cm3]', defaults.FK, FK2,
      'field capacity');
    ParCreate('nFK_2', '[cm3/cm3]', defaults.nFK,
      nFK2, 'plant available soil water content');
    ParCreate('PWP_2', '[cm3/cm3]', defaults.PWP,
      PWP2, 'residual soil water, not plant available content');

    ParCreate('b_sat3', '[cm3.cm-3]', defaults.b_sat,
      b_sat3, 'Van Genuchten parameter b_sat');
    ParCreate('b_rest3', '[cm3.cm-3]', defaults.b_rest,
      b_rest3, 'Van Genuchten parameter b_rest');
    ParCreate('alpha3', '[1/cm]', defaults.alpha, alpha3,
      'Van Genuchten parameter alpha for horizon 3',);
    ParCreate('n_par3', '[-]', defaults.n_par,
      n_par3, 'Van Genuchten parameter n');
    ParCreate('l_par3', '[-]', defaults.l_par,
      l_par3, 'Van Genuchten parameter l for 3th horizon',);
    ParCreate('Ks_3', '[-]', defaults.Ks, Ks3,
      'Van Genuchten parameter K_sat');
    ParCreate('FK_3', '[cm3/cm3]', defaults.FK, FK3,
      'field capacity');
    ParCreate('nFK_3', '[cm3/cm3]', defaults.nFK,
      nFK3, 'plant available soil water content');
    ParCreate('PWP_3', '[cm3/cm3]', defaults.PWP,
      PWP3, 'residual soil water, not plant available content');

   ParCreate('b_sat4', '[cm3.cm-3]', defaults.b_sat,
      b_sat4, 'Van Genuchten parameter b_sat');
    ParCreate('b_rest4', '[cm3.cm-3]', defaults.b_rest,
      b_rest4, 'Van Genuchten parameter b_rest');
    ParCreate('alpha4', '[1/cm]', defaults.alpha, alpha4,
      'Van Genuchten parameter alpha for horizon 4',);
    ParCreate('n_par4', '[-]', defaults.n_par,
      n_par4, 'Van Genuchten parameter n');
    ParCreate('l_par4', '[-]', defaults.l_par,
      l_par4, 'Van Genuchten parameter l for 4th horizon',);
    ParCreate('Ks_4', '[-]', defaults.Ks, Ks4,
      'Van Genuchten parameter K_sat');
    ParCreate('FK_4', '[cm3/cm3]', defaults.FK, FK4,
      'field capacity');
    ParCreate('nFK_4', '[cm3/cm3]', defaults.nFK,
      nFK4, 'plant available soil water content');
    ParCreate('PWP_4', '[cm3/cm3]', defaults.PWP,
      PWP4, 'residual soil water, not plant available content');

  ParCreate('b_sat5', '[cm3.cm-3]', defaults.b_sat,
      b_sat5, 'Van Genuchten parameter b_sat');
    ParCreate('b_rest5', '[cm3.cm-3]', defaults.b_rest,
      b_rest5, 'Van Genuchten parameter b_rest');
    ParCreate('alpha5', '[1/cm]', defaults.alpha, alpha5,
      'Van Genuchten parameter alpha for horizon 5',);
    ParCreate('n_par5', '[-]', defaults.n_par,
      n_par5, 'Van Genuchten parameter n');
    ParCreate('l_par5', '[-]', defaults.l_par,
      l_par5, 'Van Genuchten parameter l for 5th horizon',);
    ParCreate('Ks_5', '[-]', defaults.Ks, Ks5,
      'Van Genuchten parameter K_sat');
    ParCreate('FK_5', '[cm3/cm3]', defaults.FK, FK5,
      'field capacity');
    ParCreate('nFK_5', '[cm3/cm3]', defaults.nFK,
      nFK5, 'plant available soil water content');
    ParCreate('PWP_5', '[cm3/cm3]', defaults.PWP,
      PWP5, 'residual soil water, not plant available content');

    ParCreate('b_sat6', '[cm3.cm-3]', defaults.b_sat,
        b_sat6, 'Van Genuchten parameter b_sat');
      ParCreate('b_rest6', '[cm3.cm-3]', defaults.b_rest,
        b_rest6, 'Van Genuchten parameter b_rest');
      ParCreate('alpha6', '[1/cm]', defaults.alpha, alpha6,
        'Van Genuchten parameter alpha for horizon 6',);
      ParCreate('n_par6', '[-]', defaults.n_par,
        n_par6, 'Van Genuchten parameter n');
      ParCreate('l_par6', '[-]', defaults.l_par,
        l_par6, 'Van Genuchten parameter l for 6th horizon',);
      ParCreate('Ks_6', '[-]', defaults.Ks, Ks6,
        'Van Genuchten parameter K_sat');
      ParCreate('FK_6', '[cm3/cm3]', defaults.FK, FK6,
        'field capacity');
      ParCreate('nFK_6', '[cm3/cm3]', defaults.nFK,
        nFK6, 'plant available soil water content');
      ParCreate('PWP_6', '[cm3/cm3]', defaults.PWP,
        PWP6, 'residual soil water, not plant available content');





end;

procedure TSoilWaterMod.CreateParameters;
var
  i: integer;

begin
  ParCreate('nHorizons', '[n]', 4, nHorizons, 'number of soil Horizons');
  ParCreate('Max_dt', '[d]', 1, Max_dt,
    'maximum time step length for internal calculation');
  ParCreate('Min_dt', '[d]', 0.0001, Min_dt,
    'minimum time step length for internal calculation');
  ParCreate('Itermax ', '[n]', 7, IterMax,
    'minimum number of iterations before time step is adjusted');
  ParCreate('Max_aenderWG', '[cm3/cm3]', 0.001, max_aenderWG,
    'maximum WChange during one internal time step');
  ParCreate('Max_IterError', '[cm3/cm3]', 0.0001, max_IterError,
    'maximum Change of Water content during one (Picard)-Iteration ');
  ParCreate('bil_nr', '[]', 18, bil_nr);
  for i := 1 to n_comp + 1 do
    if WPar[i] = nil then
      WPar[i] := TGenucht.create;
  ParCreate('HoriNdx1', '[-]', 3, HoriNdx1,
    'lowest layer of the 1st soil horizon');
  ParCreate('HoriNdx2', '[-]', 6, HoriNdx2,
    'lowest layer of the 2nd soil horizon');
  ParCreate('HoriNdx3', '[-]', 10, HoriNdx3,
    'lowest layer of the 3rd soil horizon');
  ParCreate('HoriNdx4', '[-]', 20, HoriNdx4,
    'lowest layer of the 4th soil horizon');
  ParCreate('HoriNdx5', '[-]', 20, HoriNdx5,
    'lowest layer of the 5th soil horizon');
  ParCreate('HoriNdx6', '[-]', 20, HoriNdx6,
    'lowest layer of the 6th soil horizon');
  ParCreate('bsat_scaling', '[-]', 1, bsat_scaling,
    'Scaling factor for bsat (multiplied in all horizons)');
  ParCreate('alpha_scaling', '[-]', 1, alpha_scaling,
    'Parameter for linear scaling of soil hydraulic Parameter alpha');
  CreateHorizonParameters;
  ParCreate('PsiStart1', '[cm]', 500, PsiStart1,
    'Initial matric potential of uppermost layer at simulation start');
  ParCreate('Weff', '[cm]', 100, Weff, 'effective rooting deph [cm]');
  ParCreate('PondMax', '[mm]', 10, PondMax,
    'maximum height of ponded Water on Soil Surface');
  ParCreate('psi_critEvap', '[hPa]', 500.0, psi_critEvap,
    'suction where evaporation switches from potential to transport limited rate');
end;

function TSoilWaterMod.getNetRain: TExternV;
begin
  if NetRain is TExternV then
    result := NetRain
  else
    result := nil;
end;

function TSoilWaterMod.getPotEvap: TExternV;
begin
  if Pot_Evap is TExternV then
    result := TExternV(Pot_Evap)
  else
    result := nil;
end;

procedure TSoilWaterMod.SetPlantModel(NewPlantmodel: TAbstractPlant);
begin
  inherited;
  ndx_Weff := 0;
  if (fWeffOpt = fromPlantmodel) and IsPlantModelSet then
  begin
    repeat
      inc(ndx_Weff);
    until (Depth[ndx_Weff].v >= Plantmodel.Weff) or (ndx_Weff >= n_comp + 1);
  end
  else
  begin
    repeat
      inc(ndx_Weff);
    until (Depth[ndx_Weff].v >= Weff.v) or (ndx_Weff >= n_comp + 1);
  end;
end;

procedure TSoilWaterMod.Init(var GlobMod: Tmod);
var
  i: integer;
  error: boolean;
  psiWP, psiFK: real;
  nFK0_Weff, PWP0_Weff, WG0_Weff, defaultvalue: real;

begin
  inherited Init(GlobMod);
  // InitGenuchtenPars;    // set parameter values to individual layers from horizon parameters
  // now implemented in SetGenuchtenPars
  InitVectors;
  if uppercase(FVGParsFromTextOption.Option) = 'FROMPAR' then
    FVGParsFromTexture := FromPar;
  if uppercase(FVGParsFromTextOption.Option) = 'FROMTEXTURE' then
    FVGParsFromTexture := FromTexture;
  if uppercase(self.FKsFromTextOption.Option) = 'FROMPAR' then
    FKsFromTexture := FromPar;
  if uppercase(FKsFromTextOption.Option) = 'FROMTEXTURE' then
    FKsFromTexture := FromTexture;
  SetGenuchtenPars; // Init Genuchten Pars
  SetLDPars; // Init LDs
  SetLDnumbers; // Init numerical LD classes

  self.max_IterErrorsave := self.max_aenderWG.v;
  Iter_save := trunc(IterMax.v);
  MaxActChangeSWC := 0.0; // hp & ar 07.01.2010  !
  SumBalanceError := 0.0;
  dt_old := dt.v;
  red_evap.v := 1.0;
  Act_Evap.v := 0.0;
  dt_set := false;
  dt.v := 0.001;
  dt_old := dt.v;
  iter := 0;
  total_iter := 0;
  last_iter := 0;
  SWCStart := 0;
  global_WaterBalance := 0;
  old_global_WaterBalance := 0;
  psiWP := power(10, 4.2);
  psiFK := power(10, 1.8);
  for i := 1 to n_comp do
  begin
    FK_Arr[i] := WPar[i].b_psi_f(psiFK);
    PWP_Arr[i] := WPar[i].b_psi_f(psiWP);
    nFK_Arr[i] := FK_Arr[i] - PWP_Arr[i];
  end;

  CumEvap.v := 0.0;
  CumDrainage.v := 0.0;

  SetLowerBoundaryCondition; // from option

  Max_dt.v := min(Max_dt.v, GlobMod.Time.c);
  // value of maximum timestep
  // UB 20.1.16: minimum added so smaller maximum time steps can be set via
  // property.
  // hk 25.1.01: should actually be set via the property ...
  // no idea who wrote this ...
  // max_aenderWG := 0.01; // maximum change in water content per time step

  // set "property Variable" according to option choise in Options.ini
  if OptIniMethod.Option = 'watercontents' then
    Opt_IniMethod := Watercontents;
  if OptIniMethod.Option = 'potentials' then
    Opt_IniMethod := Potentials;
  if OptIniMethod.Option = 'parameter' then
    Opt_IniMethod := Parameter;

  if OptWriteParsFromTexture.Option = 'true' then
    fWriteParsFromTexture := true
  else
    fWriteParsFromTexture := false;

  if OptTransferWGToNextIniFile.Option = 'true' then
    fTransferWGs := true
  else
    fTransferWGs := false;

  // if then

  if Opt_IniMethod = Watercontents then
  begin
    for i := 1 to n_comp + 1 do
    begin
      defaultvalue := WPar[i].b_sat * 0.5;
      if GlobMod.StateIniFile.ValueExists(SubModname, theta_arr[i].Name) then
      begin
        theta_arr[i].v := GlobMod.StateIniFile.ReadFloat(SubModname,
          theta_arr[i].Name, defaultvalue);
        // hk 2023-08-01
        theta_arr[i].v := max(PWP_Arr[i] * 1.05, theta_arr[i].v);
        theta_arr[i].v := min(WPar[i].b_sat * 0.95, theta_arr[i].v);
      end
      else
      begin
        theta_arr[i].v := defaultvalue;
        theta_arr[i].WasReadFromFile := false;
      end;
    end;

    for i := 1 to n_comp + 1 do
    begin
      if theta_arr[i].WasReadFromFile = false then
      begin // if initial water content was only measured in upper horizons, it is assumed that psi is decreasing according to layer depth
        if i > 1 then
          psi_arr[i].v := max(10, psi_arr[i - 1].v - Thick[i])
        else
          // to avoid saturation ...
          psi_arr[i].v := Thick[i] / 2;
        theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      end
      else
        psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(SubModname, psi_arr[i].Name,
        psi_arr[i].v);
      WAmount[i].v := theta_arr[i].v * Thick[i];
      theta_old[i] := theta_arr[i].v
    end
  end
  else if Opt_IniMethod = Potentials then
  begin
    for i := 1 to n_comp + 1 do
    begin
      psi_arr[i].v := GlobMod.StateIniFile.ReadFloat(self.Name,
        psi_arr[i].Name, 100);
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(self.Name, theta_arr[i].Name,
        theta_arr[i].v);
      WAmount[i].v := theta_arr[i].v * Thick[i];
      theta_old[i] := theta_arr[i].v
    end
  end
  else if Opt_IniMethod = Parameter then
  begin
    for i := 1 to n_comp + 1 do
    begin
      psi_arr[i].v := PsiStart1.v - (i - 1) * 10;
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(self.Name, theta_arr[i].Name,
        theta_arr[i].v);
      WAmount[i].v := theta_arr[i].v * Thick[i];
      theta_old[i] := theta_arr[i].v
    end;

  end;

  GlobMod.StateIniFile.UpdateFile;

  SetNewPsi_and_Theta_Values;
  SetCompMethod;
  CheckForHoriIndexInitialisation;

  if Opt_nFKCalcMethod = FromParameter then
    Calc_nFKparsForHorizons;
  update_Wcont_Values;
  Calc_nFK(psiFK, psiWP);

  SetEvaporationReductionOption;
  for i := 1 to n_comp do
    Sink_arr[i].v := 0.0;
  theta_airdryness := WPar[1].b_psi_f(PsiAirDryness);

end;

procedure TSoilWaterMod.CalcSinks;

begin
  DayFlow1 := -0.1 * Act_Evap.v + 0.1 * NetRain.v; // [cm/d]
  WflowInt_arr[1].v := DayFlow1; // [cm/d]
  CumNetRain.c := NetRain.v;
  // WflowInt_arr[1].v := 0.0;
  // CumNetRain.c := 0.0;
  // self.CumEvap.c := 0.0;
end;

procedure TSoilWaterMod.CalcEvap_red_f;
{ ********************************************************************** }
{ Purpose: Determination of a reduction factor that adjusts potential
  evaporation for the influence of low soil moisture at the soil surface

  Parameters:

  Name             Content                         Unit         Type

  Psi              Soil water tension in the       [cm]         I
  uppermost compartment (10 cm depth)

  evap_red_f       Reduction factor for            [-]           O
  potential evaporation

  { ********************************************************************** }

var
  red_f: real;
  pF_5: real;

begin
  red_f := 0.0;
  if psi_arr[1].v > 0.0 then
  begin
    pF_5 := log10(psi_arr[1].v);
    if fred_f = modifiedBeese then
      red_f := -1 * (pF_5 - 4.2) / (4.2 - log10(psi_critEvap.v));
    if fred_f = Beese1978 then
      red_f := -0.5767 * log10(psi_arr[1].v) + 1.78;
  end
  else
    red_f := 0.0;
  if red_f > 1.0 then
    red_f := 1.0;
  if red_f < 0.0 then
    red_f := 0.0;
  red_evap.v := red_f;
end;

procedure TSoilWaterMod.CalcRates;

var
  i: integer;
  OldSumSoilwater: real;

begin
  InitDailySums_and_Changes(OldSumSoilwater);
  { start value for time step ist der vorletzte Zeitschritt des vorherigen Tages. }
  act_n_comp := n_comp;
  Find_Number_of_computation_Layers;
  repeat
    SaveOldValuesForCrankNicholson_SoluteTransport;
    CalcRatesAndIntegrate;
    SumOfInternalTimeSteps.v := SumOfInternalTimeSteps.v + dt.v;
    n_int_timesteps.v := n_int_timesteps.v + 1;
    for i := 1 to n_comp + 1 do
      Wflow_arr[i].v := Wflow_arr[i].v + WflowInt_arr[i].v * dt.v;
    // sink_arr[i].v := sink_arr[i].v + SinkInt_arr[i].v*dt.v;
    NewDay := false;
  until SumOfInternalTimeSteps.v >= GlobTime.c;
  NewDay := true;
  CalcTotalWaterAmounts;
  CalcProfileWaterBalance(OldSumSoilwater);
end;

procedure TSoilWaterMod.CalcConductivities(const context: TConductivityContext;
  const useGeometricMean, includeCoefficients, applyFreezing: Boolean);

var
  i: byte;

begin
  case context of
    ccDiffusion:
      begin
        TParallel.For(1, n_comp + 1,
          procedure(i: Int64)
          begin
            Dw_arr[i] := max(0, WPar[i].Dw_f(max(WPar[i].b_rest, theta_new[i])));
            Ku_arr[i] := max(0, WPar[i].Ku_b_f(max(WPar[i].b_rest, theta_new[i])));
          end);

        for i := 2 to n_comp + 1 do
        begin
          avg_Dw[i] := sqrt(Dw_arr[i - 1] * Dw_arr[i]); // cm2/d
          avg_Ku[i] := sqrt(Ku_arr[i - 1] * Ku_arr[i]); // cm/d
        end;

        avg_Ku[0] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean
        avg_Ku[1] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean
        avg_Dw[1] := (WPar[1].Dw_f((WPar[1].b_sat + theta_new[1]) / 2));

        for i := 1 to n_comp + 1 do
        begin
          Dw_fact[i] := avg_Dw[i] * dt.v / Dist[i - 1];
          Ku_fact[i] := avg_Ku[i] * dt.v;
        end;

        if applyFreezing then
          CalcTempFactor;
      end;

    ccRichardsMixed:
      begin
        for i := 1 to n_comp + 1 do
        begin
          c_arr[i] := WPar[i].C_psi_f(psi_neu[i]);
          Ku_arr[i] := WPar[i].Ku_b_f(theta_new[i]);
        end;

        for i := 1 to n_comp do
        begin
          if useGeometricMean then
            avg_Ku[i] := sqrt(Ku_arr[i] * Ku_arr[i + 1])
          else
            avg_Ku[i] := (Ku_arr[i] + Ku_arr[i + 1]) / 2;
        end;

        if includeCoefficients then
        begin
          avg_Ku[0] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean

          for i := 1 to n_comp do
          begin
            if c_arr[i] >= 0.0 then
              P[i] := 0.0
            else
              P[i] := dt.v / (c_arr[i] * Thick[i]);
            kf[i] := avg_Ku[i] / Dist[i];
            wf[i] := 1;
          end;

          kf[0] := 2 * avg_Ku[0] / Dist[1];
        end;

        if applyFreezing and (FSoilHeatModel <> nil) then
        begin
          for i := 1 to n_comp + 1 do
          begin
            if FSoilHeatModel.Temp[i].v <= 0 then
            begin
              avg_Ku[i] := 0.0;
              Ku_fact[i] := 0.0;
              kf[i] := 0.0;
            end;
          end;
        end;
      end;

    ccMixedHydrus:
      begin
        TParallel.For(1, n_comp + 1,
          procedure(i: Int64)
          begin
            c_arr[i] := WPar[i].C_psi_f(psi_neu[i]);
            Ku_arr[i] := WPar[i].Ku_psi_f(psi_neu[i]);
          end);

        avg_Ku[0] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean

        TParallel.For(1, n_comp,
          procedure(i: Int64)
          begin
            avg_Ku[i] := sqrt(Ku_arr[i] * Ku_arr[i + 1]);
            kf[i] := avg_Ku[i] / Dist[i];
            P[i] := (c_arr[i] * Thick[i]) / dt.v;
          end);

        kf[0] := 2 * avg_Ku[0] / Dist[1];

        for i := 0 to n_comp + 1 do
          wf[i] := 1;
      end;
  end;
end;

procedure TSoilWaterMod.CalcTempFactor;

var
  TempFactor: real;
  i: integer;
begin
  if FSoilHeatModel <> nil then
  begin
    for i := 1 to n_comp + 1 do
    begin
      if FSoilHeatModel.Temp[i].v <= 1 then
      begin
        TempFactor := max(0, min(1, (FSoilHeatModel.Temp[i].v + 1) / 2));
        avg_Ku[i] := avg_Ku[i] * TempFactor;
        Ku_fact[i] := Ku_fact[i] * TempFactor;
        Dw_fact[i] := Dw_fact[i] * TempFactor;
        P[i] := P[i] * TempFactor;
        kf[i] := kf[i] * TempFactor;
      end;
    end;
  end;
end;

procedure TSoilWaterMod.Integrate;
var
  ndx_str: string;

begin
  inherited;
  CalcProfile_and_HorizonSums;
  if Opt_TransferWGsToNextINI and (GlobTime.v = GlobMod.Endtime) then
    TransferWGsToNextINI;
  If ((GlobTime.v > GlobMod.Starttime) and (SWCStart > 0)) then
    CalcGlobalWaterBalance;
  if ((SWCStart = 0) and (SumSoilWater.v > 0)) then
    SWCStart := SumSoilWater.v + PondedWater.v;
end;

procedure TSoilWaterMod.GetWaterBalance;

{ ********************************************************************** }
{ Purpose: Calculation of the mass balance and the maximum change in
  water content during the simulation time step

  Parameters:

  Name             Content                         Unit         Type
  w_rec            Record with the water data                    I
  (see type definitions)
  geo_rec          Record with the geometry data                 I
  comps            Number of compartments           [-]          I

  max_d_WaGe       maximum change in water content  [cm3/cm3]    O }
{ ********************************************************************** }

var
  i: byte;

  net_flow, { Net flow                      [cm] }
  d_WaMe, { Change in water amount in the compartment                  [cm] }
  d_WaGe,
  { Change in water content  in the compartment                  [cm3/cm3] }
  sum_d_WaMe, { Sum of water amount changes                       [cm] }
  sum_sink { Sum of sink terms            [cm] }

    : real;

begin
  for i := 0 to n_comp + 1 do
    SW_Balance_arr[i] := 0.0;
  MaxActChangeSWC := 0.0;
  sum_d_WaMe := 0.0;
  sum_sink := 0.0;
  ActBalanceError := 0.0;
  for i := 1 to n_comp do
  begin
    net_flow := (WflowInt_arr[i].v - WflowInt_arr[i + 1].v) * dt.v; // [cm]
    d_WaMe := (theta_arr[i].v - theta_new[i]) * Thick[i]; // [cm]
    d_WaGe := theta_arr[i].v - theta_new[i];
    SW_Balance_arr[i] := d_WaMe + net_flow - Sink_arr[i].v * dt.v; // [cm]
    cumSW_Balance_arr[i] := cumSW_Balance_arr[i] + SW_Balance_arr[i];
    ActBalanceError := ActBalanceError + SW_Balance_arr[i];
    if abs(d_WaGe) > MaxActChangeSWC then
      MaxActChangeSWC := abs(d_WaGe);
    sum_d_WaMe := sum_d_WaMe + d_WaMe;
    sum_sink := sum_sink + Sink_arr[i].v * dt.v; // cm
  end;
  SumBalanceError := SumBalanceError + ActBalanceError;
end;

procedure TSoilWaterMod.adjust_dt; // adjusting dt during iteration
// Reset  state variable if iteration is not successfull
// reduce time step length and increase possible water content change during iteration

var

  i: integer;

begin
  iter := iter + 1;
  total_iter := total_iter + 1;
  if ((delt_iter_max < max_IterError.v) and (iter >= 2)) then
  begin
    success := true;
    last_iter := 0;
    iter := 0;
    exit;
  end;

  If iter > IterMax.v then // after maximum number of iterations no success
  begin
    for i := 1 to n_comp + 1 do
    begin
      theta_new[i] := theta_arr[i].v; // set back to old values
      psi_neu[i] := psi_arr[i].v;
    end;
    last_iter := iter;
    iter := 0;
    // IterMax.v := min(1000,IterMax.v *2);  // increase allowed number of Iterations up to an allowed maximum
    max_IterError.v := max_IterError.v * 2;
    // double the allowed water content change during one iteration

    // ResetTimeStep := true;                // set flag for change of time step
    dt.v := max(self.Min_dt.v, dt.v / 10);
    // reduce time step length down to a certain minimum

    // dt.v := max(dt.v/10, min_dt.v);         // reduce time step length down to a certain minimum
    // if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then begin
    // dt_old := dt.v;
    // dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
    // if(last_iter > 10) then last_iter:=+1;
    // newday := true;
    // dt_set := true;
    // end;
  end; // Reset end

  // iter := 0;
end;

procedure TSoilWaterMod.get_new_dt;

{ ********************************************************************** }
{ Purpose:  Calculation of the new time step width "dt" based on the ratio
  of the maximum permitted change in water content to the maximum current
  change in water content

  Parameters:

  Name             Content                         Unit         Type

  max_aender       maximum permitted change        [cm3/cm3]    I
  of water content in a
  time step

  akt_aender       maximum change in water         [cm3/cm3]    I
  content in a compartment
  during the last time step

  dt               time step width                 [d]          O
  dt_alt           previous time step width        [d]          O }

{ ********************************************************************** }

const
  crit_h = 5;

var
  delta_t, dt_neu, dt_neu_flow, min_h: real;

begin
  dt_set := false;
  IterMax.v := Iter_save;
  max_IterError.v := max_IterErrorsave;
  global_iter.v := global_iter.v + total_iter;
  total_iter := 0;
  if max(MaxActChangeSWC, NetRain.v * dt.v / (Thick[1] * 10)) <> 0.0 then
    dt_neu := (max_aenderWG.v / max(MaxActChangeSWC,
      NetRain.v * dt.v / (Thick[1] * 10)));
  dt_neu_flow := 1E5 * max_flow_ratio;
  if dt_neu > dt_neu_flow then
    dt_neu := dt_neu_flow;
  // dt_neu := min(dt_neu, dt_neu_flow);

  if ((dt_neu > (1.5 * dt.v)) { and (dt_neu > min_dt*100) } ) then
    dt_neu := dt.v * 1.5; { Time step increase too large? }
  dt.v := dt_neu;
  if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then
  begin
    dt_old := dt.v;
    dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
    NewDay := true;
    dt_set := true;
  end;
  dt.v := max(Min_dt.v, min(Max_dt.v, dt.v));
end;

procedure TSoilWaterMod.get_delt_iter_max;
{ ********************************************************************** }
{ Purpose: Calculation of the maximum difference in water content within
  a compartment from one iteration step to the next }
{ ********************************************************************** }

var
  i: byte;
  WG_diff: real;

begin
  delt_iter_max := 0.0;
  max_flow_ratio := 0.0;
  if (iter > 0) or ResetTimeStep then
  begin
    for i := start to n_comp do
    begin
      WG_diff := abs(last_iter_theta[i] - theta_new[i]);
      delt_iter_max := max(delt_iter_max, WG_diff);
      flow_ratio[i] := abs(WflowInt_arr[i].v) * dt.v /
        (theta_new[i] * Thick[i]);
      max_flow_ratio := max(max_flow_ratio, flow_ratio[i]);
    end;
  end;

end;

procedure TSoilWaterMod.CalcOverflow;

var
  i: integer;
  Overflow, maxstorage: real;
  layer: byte;

begin
  for i := n_comp downto start do
  begin
    if theta_new[i] > WPar[i].b_sat then
    begin
      Overflow := (theta_new[i] - WPar[i].b_sat) * Thick[i]; // [cm]
      // save overshooting amount of water
      theta_new[i] := WPar[i].b_sat;
      psi_neu[i] := 0;
      WflowInt_arr[i].v := WflowInt_arr[i].v - Overflow / dt.v; // [cm/d]
      layer := i - 1;
      // start with the layer above the layer where overflow occurred
      repeat
        if layer >= 1 then
        begin
          if theta_new[layer] < WPar[layer].b_sat then
          begin // water capacity available?
            maxstorage := (WPar[layer].b_sat - theta_new[layer]) * Thick[layer];
            // [cm]
            // how much?
            if Overflow > maxstorage then
            begin // everything fits in this layer ?
              theta_new[layer] := WPar[layer].b_sat;
              WflowInt_arr[layer].v := WflowInt_arr[layer].v -
                maxstorage / dt.v;
              Overflow := Overflow - maxstorage;
            end
            else // all fits into this layer
            begin
              theta_new[layer] := theta_new[layer] + Overflow / Thick[layer];
              // increase water content
              Overflow := 0.0;
            end;
          end;
          dec(layer);
        end;
      until (layer = 0) or (Overflow <= 0);
      // all overflow distributed or surface layer reached ...
      if Overflow > 0 then
        // CumRunoff.c := CumRunoff.c + Overflow * 10 * GlobTime.c;
        // PondedWater.v:= PondedWater.v + Overflow * 10 * GlobTime.c;
        PondedWater.c := PondedWater.c + Overflow * 10 * dt.v;
    end;

  end;
end;

procedure TSoilWaterMod.CalcRatesAndIntegrate;

begin

  Iter_save := trunc(IterMax.v); // save maximum iteration step number
  Exfiltration.v := Dw_arr[1] * theta_arr[1].v / (0.5 * Thick[1]) * 10;
  CalcEvap_red_f;
  Act_Evap.v := Pot_Evap.v * red_evap.v;

  if (uppercase(act_EvaporationOption.Option) = uppercase('inclExfiltration'))
  then
    Act_Evap.v := min(Act_Evap.v, Exfiltration.v);

  CalcSinks;

  if fCompMethod = Capacity then
    CapWatSolut; // capacity-based model
  if fCompMethod = Diffusion then
    Diffwater_solut; // potential-based model using water contents
  if fCompMethod = Richards then
    Richardswater_solut; // potential-based model using water potentials
  if fCompMethod = Mixed then
    Mixedwater_solut; // potential-based model using water potentials
  if fCompMethod = MixedHydrus then
    MixedHydruswater_solut; // potential-based model using water potentials

  // Calculation of derived water contents for different soil layers
  update_Wcont_Values;

  // CumEvap.c := CumEvap.c +
  // (-WflowInt_arr[1].v * 10 + CumNetRain.c - CumRunoff.c) * dt.v;
  CumEvap.c := CumEvap.c + Act_Evap.v * dt.v; // [mm]
  // if WFlowInt_arr[1] was reduced because of dry, this is the new ActEvap of InternTimeStep
  CumDrainage.c := CumDrainage.c + WflowInt_arr[trunc(bil_nr.v) + 1].v * 10 *
    dt.v; // [mm]
  // hk 25.1.2011: changed to variable depth in case of groundwater higher than depth of comartment bil_nr
end;
{$WRITEABLECONST ON}

procedure TSoilWaterMod.CapWatSolut;

const
  rep: boolean = false;

var
  psiWP, psiFK: real;
  WCap: TSoilArray;
  i: byte;

begin
  if rep = false then
  begin
    { Calculation of water potentials [cm] at field capacity and at the
      permanent wilting point }
    psiWP := power(10, 4.2);
    psiFK := power(10, 1.8);

    if nFKCalcMethod = Input then
    begin

      if HoriNdx1.v = 0 then
      begin
        if ShowWarnings then
        begin

{$IFNDEF NONVISUAL}
          showmessage
            ('Warning ! No specification of Indexes for hydraulic parameters');
          showmessage('Please check !');

{$ELSE}
          writeln('Warning ! No specification of Indexes for hydraulic parameters');
          writeln('Please check !');

{$ENDIF}
        end;
      end;

      for i := 1 to round(HoriNdx1.v) do
      begin
        FK_Arr[i] := Par_FK1.v;
        PWP_Arr[i] := Par_PWP1.v;
        nFK_Arr[i] := Par_FK1.v - Par_PWP1.v;
      end;

      for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
      begin
        FK_Arr[i] := Par_FK2.v;
        PWP_Arr[i] := Par_PWP2.v;
        nFK_Arr[i] := Par_FK2.v - Par_PWP2.v;
      end;

      for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
      begin
        FK_Arr[i] := Par_FK3.v;
        PWP_Arr[i] := Par_PWP3.v;
        nFK_Arr[i] := Par_FK3.v - Par_PWP3.v;
      end;

      for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
      begin
        FK_Arr[i] := Par_FK4.v;
        PWP_Arr[i] := Par_PWP4.v;
        nFK_Arr[i] := Par_FK4.v - Par_PWP4.v;
      end;
    end
    else
    begin { nFKCalcMethod = FromParameter }
      for i := 1 to n_comp do
      begin
        FK_Arr[i] := WPar[i].b_psi_f(psiFK);
        PWP_Arr[i] := WPar[i].b_psi_f(psiWP);
        nFK_Arr[i] := FK_Arr[i] - PWP_Arr[i];
        WAmount[i].v := theta_arr[i].v * Thick[i];
      end;
    end;
    rep := true;
  end; { End initial rep=false }

  // for capacity-based model always time step of global model
  dt.v := GlobTime.c;

  for i := 1 to n_comp + 1 do
  begin
    theta_arr[i].v := WAmount[i].v / Thick[i];
    theta_old[i] := theta_arr[i].v;
    Wflow_old[i] := WflowInt_arr[i].v;
    WflowInt_arr[i].v := 0.0;
  end;

  WflowInt_arr[1].v := 0.1 * NetRain.v - 0.1 * Act_Evap.v; // upper boundary

  for i := 1 to n_comp do
  begin
    WCap[i] := (FK_Arr[i] - theta_arr[i].v) * Thick[i];
    if (WCap[i] < WflowInt_arr[i].v * dt.v) then
    begin // Saturation ?
      theta_arr[i].v := FK_Arr[i];
      WAmount[i].v := theta_arr[i].v * Thick[i];
      WflowInt_arr[i + 1].v := WflowInt_arr[i].v - WCap[i];
    end
    else
    begin
      WAmount[i].v := WAmount[i].v + WflowInt_arr[i].v * dt.v;
      theta_arr[i].v := WAmount[i].v / Thick[i];
      WflowInt_arr[i + 1].v := 0.0;
    end;
  end;

  // water uptake of plant roots
  for i := 1 to n_comp do
  begin
    WAmount[i].v := WAmount[i].v - Sink_arr[i].v * dt.v;
    theta_arr[i].v := WAmount[i].v / Thick[i];
    psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
    self.theta_new[i] := theta_arr[i].v;
    self.theta_old[i] := theta_arr[i].v;
  end;

  for i := 1 to n_comp + 1 do
    Wflow_arr[i].v := WflowInt_arr[i].v;

{$IFNDEF NONVISUAL}
  if (DebugForm <> NIL) and Debugmodus then
    DebugForm.update;
{$ENDIF}
end; { procedure CapWatSolut }

{ -------------------------------------------------------------------------- }

procedure TSoilWaterMod.get_water_contents;
var
  i: byte;
begin
  for i := 1 to n_comp { + 1 } do
  begin
    theta_arr[i].v := WAmount[i].v / Thick[i];
    theta_new[i] := theta_arr[i].v;
    // Wflow_old[i] := avg_Dw[i] * (theta_old[i - 1] - theta_old[i])
    // / Dist[i - 1] + avg_Ku[i];
  end;
end;

procedure TSoilWaterMod.set_new_state_vars;
{ ********************************************************************** }
{ Purpose: Transfer the calculated water contents into the global
  "state" variable and calculate the water potentials }
{ ********************************************************************** }

var
  i: byte;

begin
  for i := 1 to n_comp do
  begin
    theta_old[i] := theta_arr[i].v;
    theta_arr[i].v := theta_new[i];
    if self.Opt_CompMethod = Diffusion then
      psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v)
    else
      psi_arr[i].v := psi_neu[i];
    WAmount[i].v := theta_arr[i].v * Thick[i];
  end;
  if LowerBoundaryCondition = FreeFlow then
  begin
    if Opt_CompMethod = Diffusion then
    begin
      theta_arr[n_comp + 1].v := theta_new[n_comp];
      psi_arr[n_comp + 1].v := WPar[n_comp].psi_b_f(theta_arr[n_comp].v);
      theta_new[n_comp + 1] := theta_arr[n_comp].v;
      WAmount[n_comp + 1].v := theta_arr[n_comp + 1].v * Thick[n_comp + 1];
    end
    else
    begin
      psi_arr[n_comp + 1].v := psi_arr[n_comp].v; // -Abst[n_comp];
      // psi_arr[n_comp + 1].v := psi_arr[n_comp].v -Abst[n_comp];
      theta_arr[n_comp + 1].v := WPar[n_comp].b_psi_f(psi_arr[n_comp + 1].v);
      // theta_arr[n_comp + 1].v :=  theta_arr[n_comp].v;
      psi_neu[n_comp + 1] := psi_arr[n_comp + 1].v;
      theta_new[n_comp + 1] := theta_arr[n_comp + 1].v;
    end;
  end;
end;

procedure TSoilWaterMod.UpperBoundaryCondition;

{ To prevent invalid function calls, first check whether a decline of the
  water content below the residual water content b_rest or a rise above the
  saturated water content b_sat is expected. The result of this check is
  stored in the variables "Wet" and "Dry". }
var
  psi_top, MaxFlow1: real;

begin
  dry := false;
  wet := false;
  success := false;
  start := 1;

  MaxFlow1 := DayFlow1 + 0.1 * PondedWater.v / dt.v;
  // maximum possible water influx rate [cm/d]
  if MaxFlow1 > 0 then
  begin
    psi_top := -PondedWater.v / 10; // tension including ponded water [cm]
    MaxInfil := 2.0 * avg_Ku[1] * ((psi_neu[1] - psi_top) / Thick[1]) +
      avg_Ku[1];
  end;

  if ((MaxFlow1 > MaxInfil)) then
  begin
    wet := true; { Check for saturation }
    WflowInt_arr[1].v := MaxInfil;
  end;

  if (theta_new[1] < WPar[1].b_rest) and (WflowInt_arr[1].v <= 0.0) then
    dry := true;

  if not(wet or dry) then
  begin
    // success := true;
    B_vektor[1] := theta_arr[1].v + WflowInt_arr[1].v * dt.v / Thick[1] -
      Ku_fact[2] / Thick[1] - Sink_arr[1].v * dt.v / Thick[1];
    diag[1] := Dw_fact[2] / Thick[1] + 1.0;
    upper[1] := -Dw_fact[2] / Thick[1];
  end
  else
  begin
    B_vektor[1] := theta_arr[1].v + WPar[1].b_sat * Dw_fact[1] / Thick[1] +
      Ku_fact[1] / Thick[1] - Ku_fact[2] / Thick[1] - Sink_arr[1].v * dt.v
      / Thick[1];
    lower[1] := 0;
    diag[1] := Dw_fact[1] / Thick[1] + Dw_fact[2] / Thick[1] + 1.0;
    upper[1] := -Dw_fact[2] / Thick[1];
  end;

end;

procedure TSoilWaterMod.Diffwater_solut;

var
  result: byte;
  i: integer;

  procedure MainLoop;
  var
    i: integer;
  begin

    TParallel.For(start + 1, n_comp - 1,
      procedure(i: Int64)
      begin
        B_vektor[i] := theta_arr[i].v - Ku_fact[i + 1] / Thick[i] + Ku_fact[i] /
          Thick[i] - Sink_arr[i].v * dt.v / Thick[i];
        lower[i] := -Dw_fact[i] / Thick[i];
        diag[i] := Dw_fact[i] / Thick[i] + Dw_fact[i + 1] / Thick[i] + 1.0;
        upper[i] := -Dw_fact[i + 1] / Thick[i];
      end);

    { for i := start + 1 to n_comp - 1 do
      begin
      B_vektor[i] := theta_arr[i].v
      - Ku_fact[i + 1] / Thick[i]
      + Ku_fact[i] / Thick[i]
      - Sink_arr[i].v * dt.v / Thick[i];
      lower[i] := -Dw_fact[i] / Thick[i];
      diag[i]  := Dw_fact[i] / Thick[i] + Dw_fact[i + 1] / Thick[i] + 1.0;
      upper[i] := -Dw_fact[i + 1] / Thick[i];
      end; }
  end;

  procedure LowerBoundary;

  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or
      (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
      { Gehalts-Randbedingungen }
      B_vektor[act_n_comp] := theta_arr[act_n_comp].v + Ku_fact[act_n_comp] /
        Thick[act_n_comp] - Ku_fact[act_n_comp + 1] / Thick[act_n_comp + 1] +
        Dw_fact[act_n_comp + 1] * theta_arr[act_n_comp + 1].v /
        Thick[act_n_comp + 1] - Sink_arr[act_n_comp].v * dt.v /
        Thick[act_n_comp]
    else if (LowerBoundaryCondition = NoFlow) then
      { no-flow flux boundary condition }
      B_vektor[n_comp] := theta_arr[n_comp].v + Ku_fact[n_comp] / Thick[n_comp]
        - WflowInt_arr[n_comp + 1].v / Thick[n_comp] - Sink_arr[n_comp].v * dt.v
        / Thick[n_comp]
    else if ShowWarnings then

{$IFNDEF NONVISUAL}
      showmessage('Lower Boundary not defined!');
{$ELSE}
      writeln('Lower Boundary not defined!');
{$ENDIF}
    lower[act_n_comp] := -Dw_fact[act_n_comp] / Thick[act_n_comp];
    diag[act_n_comp] := Dw_fact[act_n_comp] / Thick[act_n_comp] +
      Dw_fact[act_n_comp + 1] / Thick[act_n_comp + 1] + 1.0;
  end;

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
  begin
    result := trdiag(false, act_n_comp, start, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then

{$IFNDEF NONVISUAL}
        showmessage('Error solving equation system');
{$ELSE}
        writeln('Error solving equation system');
{$ENDIF}
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp { + 1 } do
      begin
        last_iter_theta[i] := theta_new[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_new[i];
      theta_new[i] := B_vektor[i];
      if ShowWarnings then
      begin
        if theta_new[i] < 1E-20 then
        begin

{$IFNDEF NONVISUAL}
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));
{$ELSE}
          writeln('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          writeln('Datum: ' + floattostr(GlobTime.v));
{$ENDIF}
        end;
      end;
    end;
  end;

  procedure Find_flows;

  var
    GW_inflow: TSoilArray; // flows induced by increasing groundwater table
    infilbalance, PondCapa, Overflow: real;
    PondDischargeRate: real;
    i: byte;
  begin
    if (LowerBoundaryCondition = ConstContent) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      for i := 2 to act_n_comp + 1 do
      begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_new[i - 1] - theta_new[i]) /
          Dist[i - 1] + avg_Ku[i];
      end;
    end;

    if (LowerBoundaryCondition = Groundwatertable) then
    begin
      for i := 2 to act_n_comp + 1 do
      begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_new[i - 1] - theta_new[i]) /
          Dist[i - 1] + avg_Ku[i];
      end;

      for i := act_n_comp + 1 to n_comp do
      begin
        GW_inflow[i + 1] := (theta_new[i] - WPar[i].b_sat) * Thick[i] / dt.v;
        theta_new[i] := WPar[i].b_sat;
      end;

      for i := act_n_comp + 2 to n_comp + 1 do
      begin
        WflowInt_arr[i].v := WflowInt_arr[i - 1].v + GW_inflow[i];
      end;

      if wet then
      begin // inflow higher than max. infiltration, infiltration is at its maximum value
        infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
        infilbalance := infilbalance * 10 * dt.v; // change into [mm]
        if infilbalance < 0.0 then // more infiltration than DayFlow
          PondedWater.v := PondedWater.v + infilbalance
        else
        begin // not all water can infiltrate ...
          PondCapa := PondMax.v - PondedWater.v; // in [mm]
          if infilbalance > PondCapa then // More water than can be stored
          begin
            Overflow := (infilbalance - PondCapa); // [mm]
            PondedWater.v := PondMax.v;
            CumRunoff.c := CumRunoff.c + Overflow;
          end
          else // soil surface is wet, max. infiltration but excess water is stored as ponded water
          begin
            PondedWater.v := PondedWater.v + infilbalance; // [mm]
          end;
        end;

      end;

    end;

    if not(wet) and (PondedWater.v > 0) then
    // discharge of ponded water possible
    begin
      PondDischargeRate := MaxInfil - DayFlow1;
      PondedWater.v := max(0, PondedWater.v - 10 * PondDischargeRate * dt.v);
    end;

  end;

begin { procedure Diffwater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  iter := 0;
  repeat
    CalcConductivities(ccDiffusion, true, true, true);
    UpperBoundaryCondition;
    MainLoop;
    LowerBoundary;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
{$IFNDEF NONVISUAL}
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
{$ENDIF}
    adjust_dt;
  until (success);
  Find_flows;
  CalcOverflow;
  GetWaterBalance;
  set_new_state_vars;
end;
{ -------------------------------------------------------------------------- }

procedure TSoilWaterMod.Richardswater_solut;

var
  result: byte;
  // i: integer;
  psi_top, MaxFlow1,

    ExcessWater: real;

  procedure UpperBoundary;

  var
    est_theta_1: real;
    // ExcessWater: real;
    psi_top1: real;
    i: integer;

    { To prevent invalid function calls, first check whether a decline of the
      water content below the residual water content b_rest or a rise above the
      saturation water content b_sat is expected. The result of this check is
      stored in the variables "Wet" and "Dry". }
  begin
    // est_theta_1 := WPar[1].b_psi_f(psi_neu[1]) + (NetRain.v -Sink_arr[1].v) * dt.v / Dicke[1];
    // est_theta_1 := WPar[1].b_psi_f(psi_arr[1].v) + (NetRain.v*10 -Sink_arr[1].v) * dt.v / Dicke[1]-
    // WFlowInt_arr[2].v*dt.v/Dicke[1];
    // if (est_theta_1 < theta_airdryness) then begin

    dry := false;
    wet := false;
    start := 1;

    MaxFlow1 := DayFlow1 + 0.1 * PondedWater.v / dt.v;
    // maximum possible water influx rate [cm/d]

    if MaxFlow1 > 0 then
    begin
      psi_top := -PondedWater.v / 10; // tension including ponded water [cm]
      // MaxInfil :=  avg_ku[0];     // without tension induced flux
      MaxInfil := 2.0 * avg_Ku[0] * ((psi_neu[1] - psi_top) / Thick[1]) +
        avg_Ku[0];
      if MaxFlow1 > MaxInfil then
      begin
        wet := true;
        WflowInt_arr[1].v := MaxInfil;
      end;
    end;

    if (psi_neu[1] > PsiAirDryness) then
    begin
      dry := true;
      psi_top := PsiAirDryness;
    end;

    if not(wet or dry) then // Wassergehalte im erlaubten Rahmen
    begin
      start := 1;
      B_vektor[1] := psi_arr[1].v + MaxFlow1 * P[1] // known Influx
        - avg_Ku[1] * P[1] // drainage to second layer
        - Sink_arr[1].v * P[1]; // water uptake by plants
      diag[1] := -wf[1] * kf[1] * P[1] + 1; // tension flow to second layer
      upper[1] := wf[1] * kf[1] * P[1];
      WflowInt_arr[1].v := MaxFlow1;
      exit;
    end
    else
    begin // fixed tension on soil surface
      B_vektor[1] := psi_neu[1] + psi_top * kf[0] * P[1] * 2
      // tension infiltration rate
        + avg_Ku[0] * P[1] // gravitational infiltration
        - avg_Ku[1] * P[1] // gravitation flow to second layer
        - Sink_arr[1].v * P[1]; // water uptake by plants

      diag[1] := -Ku_arr[1] / Dist[1] * 2 * P[1]
      // tension induced flow into first layer
        - wf[1] * kf[1] * P[1] + 1; // tension outflow to second layer
      upper[1] := wf[1] * kf[1] * P[1];
    end;

  end;

  procedure MainLoop;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      B_vektor[i] := psi_arr[i].v + P[i] * (avg_Ku[i - 1] - avg_Ku[i]) -
        Sink_arr[i].v * P[i];
      if wf[i] >= 1 then
      begin
        lower[i] := kf[i - 1] * P[i];
        diag[i] := -kf[i - 1] * P[i] - kf[i] * P[i] + 1;
        upper[i] := kf[i] * P[i];
        // wf[i] := 1.0;
      end
      else
      begin
        lower[i] := wf[i] * kf[i - 1] * P[i];
        diag[i] := wf[i] * -kf[i - 1] * P[i] - wf[i] * kf[i] * P[i] + 1;
        upper[i] := kf[i] * P[i];

        lower[i - 1] := wf[i - 1] * kf[i - 2] * P[i - 1];
        diag[i - 1] := -wf[i] * kf[i - 2] * P[i - 1] - wf[i] * kf[i - 1] *
          P[i - 1] + 1;
        upper[i - 1] := wf[i] * kf[i - 1] * P[i - 1];
      end;

    end;
  end;

  procedure LowerBoundary;

  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }
 begin
    if (LowerBoundaryCondition = ConstContent) or
      (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      B_vektor[n_comp] := psi_arr[n_comp].v + P[n_comp] *
        (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) - wf[n_comp] * psi_arr[n_comp + 1]
        .v * kf[n_comp] * P[n_comp] - Sink_arr[n_comp].v * P[n_comp];
    end
    else if (LowerBoundaryCondition = NoFlow) then
    begin
      { no-flow flux boundary condition }

      B_vektor[n_comp] := psi_arr[n_comp].v + P[n_comp] * (avg_Ku[n_comp - 1]) -
        Sink_arr[n_comp].v * P[n_comp];

    end
    else if ShowWarnings then

{$IFNDEF NONVISUAL}
      showmessage('Lower Boundary not defined!');
{$ELSE}
      writeln('Lower Boundary not defined!');
{$ENDIF}
    lower[n_comp] := wf[n_comp] * kf[n_comp - 1] * P[n_comp];
    diag[n_comp] := -wf[n_comp] * P[n_comp] * kf[n_comp - 1] - wf[n_comp] *
      P[n_comp] * kf[n_comp] + 1;

    { B_vektor[n_comp] := psi_arr[n_comp].v + P[n_comp] *
      (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) - psi_arr[n_comp + 1].v * kf
      [n_comp] * P[n_comp] - Sink_arr[n_comp].v * P[n_comp];
      lower[n_comp] := kf[n_comp - 1] * P[n_comp];
      diag[n_comp] := -P[n_comp] * kf[n_comp - 1] - P[n_comp] * kf[n_comp] + 1; }
  end;

  procedure SolvingEquationSystem;
  var
    i: byte;
    c: real; // specific soil water capacity [1/cm])
  begin
    result := trdiag(false, act_n_comp, start, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then

{$IFNDEF NONVISUAL}
        showmessage('Error solving equation system');

{$ELSE}
        writeln('Error solving equation system');

{$ENDIF}
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp { + 1 } do
      begin
        last_iter_theta[i] := theta_new[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_new[i];
      // psi_neu[i] := max(0, B_vektor[i]);
      psi_neu[i] := max(0, B_vektor[i]);
      c := WPar[i].C_psi_f(psi_neu[i]);
      theta_new[i] := theta_arr[i].v + c * (psi_neu[i] - psi_arr[i].v);
      if ShowWarnings then
      begin
        if theta_new[i] < 1E-20 then
        begin

{$IFNDEF NONVISUAL}
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));

{$ELSE}
          writeln('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          writeln('Datum: ' + floattostr(GlobTime.v));

{$ENDIF}
        end;
      end;
    end;
  end;

  procedure Find_flows;
  var
    i: byte;
    Overflow,
    // inflow,
    infilbalance: real;
    PondCapa, PondDischargeRate: real;
  begin
    for i := 2 to n_comp + 1 do
      WflowInt_arr[i].v := wf[i] * avg_Ku[i - 1] *
        ((psi_neu[i] - psi_neu[i - 1]) / Dist[i - 1]) + avg_Ku[i - 1];

    if wet then
    begin // inflow higher than max. infiltration, infiltration is at its maximum value
      infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
      infilbalance := infilbalance * 10 * dt.v; // change into [mm]
      if infilbalance < 0.0 then // more infiltration than DayFlow
        PondedWater.v := PondedWater.v + infilbalance
      else
      begin // not all water can infiltrate ...
        PondCapa := PondMax.v - PondedWater.v; // in [mm]
        if infilbalance > PondCapa then // More water than can be stored
        begin
          Overflow := (infilbalance - PondCapa); // [mm]
          PondedWater.v := PondMax.v;
          CumRunoff.c := CumRunoff.c + Overflow;
        end
        else // soil surface is wet, max. infiltration but excess water is stored as ponded water
        begin
          PondedWater.v := PondedWater.v + infilbalance; // [mm]
        end;
      end;
    end;

    if not(wet) and (PondedWater.v > 0) then
    // discharge of ponded water possible
    begin
      PondDischargeRate := MaxFlow1 - DayFlow1;
      PondedWater.v := max(0, PondedWater.v - 10 * PondDischargeRate * dt.v);
    end;

    if LowerBoundaryCondition = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;
  end;

begin { procedure Richardswater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  iter := 0;
  repeat
    CalcConductivities(ccRichardsMixed, false, true, false);
    UpperBoundary;
    MainLoop;
    LowerBoundary;
    SolvingEquationSystem;
    get_delt_iter_max;
{$IFNDEF NONVISUAL}
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
{$ENDIF}
    adjust_dt;
  until (success);
  Find_flows;
  CalcOverflow;
  GetWaterBalance;
  set_new_state_vars;
end; // Richards

{ -------------------------------------------------------------------------- }

procedure TSoilWaterMod.Mixedwater_solut;

var
  result: byte;
  i: integer;

  procedure UpperBoundary;

  const
    AirDryness = 20000;

  var
    est_theta_1: real;

    { To prevent invalid function calls, first check whether a decline of the
      water content below the residual water content b_rest or a rise above the
      saturation water content b_sat is expected. The result of this check is
      stored in the variables "Wet" and "Dry". }
  begin
    // est_theta_1 := WPar[1].b_psi_f(psi_arr[1].v) + NetRain.v * dt.v/dicke[1];
    // theta_airdryness := WPar[1].b_psi_f(Airdryness);
    // if (est_theta_1 > theta_airdryness  { AirDryness } ) { and (psi_arr[1].v> 1) } then
    // begin
    { Wasserspannungen im erlaubten Rahmen ? }
    dry := false;
    start := 1;
    { flow_arr[1] := soll_inflow; }
    Res[1] := WflowInt_arr[1].v / Thick[1] // Fluxcondition, known
      - avg_Ku[1] / (Thick[1] * Dist[1]) * (psi_arr[2].v - psi_arr[1].v)
    // pressure induced flow to second layer
      - (avg_Ku[1]) / Thick[1] // gravitational flow induced to second layer
      - (theta_new[1] - theta_arr[1].v) / dt.v // soil water change
      - Sink_arr[1].v / (Thick[1]); // sink
    alpha[1] := 0.0;
    beta[1] := c_arr[1] / dt.v + (avg_Ku[1]) / (Dist[1] * Thick[1]);
    gamma[1] := -avg_Ku[1] / (Dist[1] * Thick[1]);
  end;

  procedure MainLoop;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      Res[i] := avg_Ku[i - 1] / (Thick[i] * Dist[i]) *
        (psi_arr[i].v - psi_arr[i - 1].v) // inflow from upper layer
        - avg_Ku[i] / (Thick[i] * Dist[i]) * (psi_arr[i + 1].v - psi_arr[i].v)
      // outflow to lower layer
        + (avg_Ku[i - 1] - avg_Ku[i]) / Thick[i] // gravitational flows
        - (theta_new[i] - theta_arr[i].v) / dt.v // soil water change
        - Sink_arr[i].v / (Thick[i]); // sink term
      alpha[i] := -avg_Ku[i - 1] / (Dist[i] * Thick[i]);
      beta[i] := c_arr[i] / dt.v + (avg_Ku[i - 1] + avg_Ku[i]) /
        (Dist[i] * Thick[i]);
      gamma[i] := -avg_Ku[i] / (Dist[i] * Thick[i]);
    end;
  end;

  procedure LowerBoundary;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or
      (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      Res[n_comp] := avg_Ku[n_comp - 1] / (Thick[n_comp] * Dist[n_comp]) *
        (psi_arr[n_comp].v - psi_arr[n_comp - 1].v) - avg_Ku[n_comp] /
        (Thick[n_comp] * Dist[n_comp + 1]) *
        (psi_arr[n_comp + 1].v - psi_arr[n_comp].v) +
        (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) / Thick[n_comp] -
        (theta_new[n_comp] - theta_arr[n_comp].v) / dt.v - Sink_arr[n_comp].v /
        (Thick[n_comp]);
    end
    else if (LowerBoundaryCondition = NoFlow) then
    begin
      // no-flow flux boundary condition }

      Res[n_comp] := avg_Ku[n_comp - 1] / (Thick[n_comp] * Dist[n_comp]) *
        (psi_arr[n_comp].v - psi_arr[n_comp - 1].v) // inflow from upper layer
        + (avg_Ku[n_comp - 1]) / Thick[n_comp]
      // gravitational flow into the layer
        - (theta_new[n_comp] - theta_arr[n_comp].v) / dt.v // soil water change
        - Sink_arr[n_comp].v / (Thick[n_comp]);

    end
    else if ShowWarnings then

{$IFNDEF NONVISUAL}
      showmessage('Lower Boundary not defined!');
{$ELSE}
      writeln('Lower Boundary not defined!');
{$ENDIF}
    alpha[n_comp] := -avg_Ku[n_comp - 1] / (Dist[n_comp] * Thick[n_comp]);
    beta[n_comp] := c_arr[n_comp] / dt.v + (avg_Ku[n_comp - 1] + avg_Ku[n_comp])
      / (Dist[n_comp] * Thick[n_comp]);
    gamma[n_comp] := 0.0;

    { B_vektor[n_comp] := psi_arr[n_comp].v + P[n_comp] *
      (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) - psi_arr[n_comp + 1].v * kf
      [n_comp] * P[n_comp] - Sink_arr[n_comp].v * P[n_comp];
      lower[n_comp] := kf[n_comp - 1] * P[n_comp];
      diag[n_comp] := -P[n_comp] * kf[n_comp - 1] - P[n_comp] * kf[n_comp] + 1; }
  end;

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
    c: real; // specific soil water capacity [1/cm])
  begin
    result := trdiag(false, act_n_comp, start, alpha, beta, gamma, Res);
    if result <> 0 then
      if ShowWarnings then

{$IFNDEF NONVISUAL}
        showmessage('Error solving equation system');
{$ELSE}
        writeln('Error solving equation system');
{$ENDIF}
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp + 1 do
      begin
        last_iter_theta[i] := theta_new[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_new[i];
      { Umsetzen der berechneten Spannungen }
      psi_neu[i] := max(0, psi_neu[i] + Res[i]);
      // Neue Wassergehalte aus Ableitung
      theta_new[i] := WPar[i].b_psi_f(psi_neu[i]);
      if ShowWarnings then
      begin
        if theta_new[i] < 1E-20 then
        begin

{$IFNDEF NONVISUAL}
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));

{$ELSE}
          writeln('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          writeln('Datum: ' + floattostr(GlobTime.v));

{$ENDIF}
        end;
      end;
    end;
  end;

  procedure Find_flows;
  var
    i: byte;
  begin
    for i := 2 to n_comp + 1 do
      WflowInt_arr[i].v := avg_Ku[i - 1] *
        ((psi_neu[i] - psi_neu[i - 1]) / Dist[i - 1] + 1);
    if start = 2 then
      WflowInt_arr[1].v := WflowInt_arr[2].v;
    if (dry and (WflowInt_arr[1].v < WflowInt_arr[2].v)) or
      (wet and (WflowInt_arr[1].v > WflowInt_arr[2].v)) then
    begin
      WflowInt_arr[1].v := WflowInt_arr[2].v;
      Wflow_old[1] := Wflow_old[2];
    end;
    if LowerBoundaryCondition = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;

  end;

begin { procedure Mixedwater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  iter := 0;
  repeat
    CalcConductivities(ccRichardsMixed, true, false, true);
    UpperBoundary;
    MainLoop;
    LowerBoundary;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
{$IFNDEF NONVISUAL}
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
{$ENDIF}
    adjust_dt;
  until (success);
  Find_flows;
  CalcOverflow;
  GetWaterBalance;
  set_new_state_vars;
end;
{ -------------------------------------------------------------------------- }

procedure TSoilWaterMod.MixedHydruswater_solut;

var
  result: byte;
  i: integer;
  psi_top, MaxFlow1: real;

  procedure CalcUpperBoundary;

  const
    AirDryness = 20000;

  var
    est_theta_1: real;
    ExcessWater: real;
    psi_top1: real;
    i: integer;

    { To prevent invalid function calls, first check whether a decline of the
      water content below the residual water content b_rest or a rise above the
      saturation water content b_sat is expected. The result of this check is
      stored in the variables "Wet" and "Dry". }

  begin
    // est_theta_1 := WPar[1].b_psi_f(psi_arr[1].v) + NetRain.v * dt.v/dicke[1];
    // theta_airdryness := WPar[1].b_psi_f(Airdryness);
    // if (est_theta_1 > theta_airdryness  { AirDryness } ) { and (psi_arr[1].v> 1) } then
    // begin
    { Wasserspannungen im erlaubten Rahmen ? }
    start := 1;
    dry := false;
    wet := false;

    MaxFlow1 := DayFlow1 + 0.1 * PondedWater.v / dt.v;
    // maximum possible water influx rate [cm/d]

    if MaxFlow1 > 0 then
    begin
      psi_top := -PondedWater.v / 10; // tension including ponded water [cm]
      // MaxInfil :=  avg_ku[0];     // without tension induced flux
      MaxInfil := 2.0 * avg_Ku[0] * ((psi_neu[1] - psi_top) / Thick[1]) +
        avg_Ku[0];
      if MaxFlow1 > MaxInfil then
      begin
        wet := true;
        WflowInt_arr[1].v := MaxInfil;
      end;
    end;
    if (psi_neu[1] > PsiAirDryness) then
    begin
      dry := true;
      psi_top := PsiAirDryness;
    end;

    if not(wet or dry) then // Wassergehalte im erlaubten Rahmen
    begin

      Res[1] := psi_neu[1] * P[1] + MaxFlow1 // Fluxcondition, known
        - avg_Ku[1] // gravitational flow induced to second layer
        - (theta_new[1] - theta_arr[1].v) * Thick[1] / dt.v // soil water change
        - Sink_arr[1].v; // sink
      alpha[1] := 0.0;
      beta[1] := P[1] - kf[1];
      gamma[1] := kf[1];

    end
    else
    begin // fixed tension on soil surface

      Res[1] := psi_neu[1] * P[1] + avg_Ku[0] - avg_Ku[1] // gravitational flows
        + psi_top * kf[0] - (theta_new[1] - theta_arr[1].v) * Thick[1] / dt.v
      // soil water change
        - Sink_arr[1].v; // sink term
      alpha[1] := kf[1 - 1];
      beta[1] := P[1] - kf[1];
      gamma[1] := kf[1];
    end;
  end;

  procedure CalcMainLayers;
  var
    i: integer;
  begin

    TParallel.For(start + 1, n_comp - 1,
      procedure(i: Int64)
      begin
        Res[i] := psi_neu[i] * P[i] + avg_Ku[i - 1] - avg_Ku[i]
        // gravitational flows
          - (theta_new[i] - theta_arr[i].v) * Thick[i] / dt.v
        // soil water change
          - Sink_arr[i].v; // sink term
        alpha[i] := kf[i - 1];
        beta[i] := P[i] - kf[i - 1] - kf[i];
        gamma[i] := kf[i];
      end);

    { for i := start + 1 to n_comp - 1 do
      begin
      Res[i] := psi_neu[i] * P[i]
      + avg_Ku[i - 1]
      - avg_Ku[i]  // gravitational flows
      - (theta_new[i] - theta_arr[i].v) * Thick[i] / dt.v // soil water change
      - Sink_arr[i].v; // sink term
      alpha[i] := kf[i - 1];
      beta[i] := P[i] - kf[i - 1] - kf[i];
      gamma[i] := kf[i];
      end; }
  end;

  procedure CalcLowerBoundary;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or
      (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      Res[n_comp] := psi_neu[n_comp] * P[n_comp] + avg_Ku[n_comp - 1]
      // gravitational inflow
        - avg_Ku[n_comp] // gravitational outflow
        - kf[n_comp] * psi_neu[n_comp + 1]
      // tension induce flow to bottom layer
        - (theta_new[n_comp] - theta_arr[n_comp].v) * Thick[n_comp] / dt.v
      // water balance term
        - Sink_arr[n_comp].v;

      beta[n_comp] := P[n_comp] - kf[n_comp - 1]
      // tension induced inflow from upper layer
        - kf[n_comp]; // tension induce i

    end
    else if (LowerBoundaryCondition = NoFlow) then
    begin
      // no-flow flux boundary condition }
      Res[n_comp] := psi_neu[n_comp] * P[n_comp] + avg_Ku[n_comp - 1] -
        (theta_new[n_comp] - theta_arr[n_comp].v) * Thick[n_comp] / dt.v -
        Sink_arr[n_comp].v;
      beta[n_comp] := P[n_comp] - kf[n_comp - 1];

    end
    else if ShowWarnings then

{$IFNDEF NONVISUAL}
      showmessage('Lower Boundary not defined!');

{$ELSE}
      writeln('Lower Boundary not defined!');
{$ENDIF}
    alpha[n_comp] := kf[n_comp - 1];
    gamma[n_comp] := 0.0;

    { B_vektor[n_comp] := psi_arr[n_comp].v + P[n_comp] *
      (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) - psi_arr[n_comp + 1].v * kf
      [n_comp] * P[n_comp] - Sink_arr[n_comp].v * P[n_comp];
      lower[n_comp] := kf[n_comp - 1] * P[n_comp];
      diag[n_comp] := -P[n_comp] * kf[n_comp - 1] - P[n_comp] * kf[n_comp] + 1; }
  end;

  procedure SolveEquationSystem;
  var
    i: byte;
    c: real; // specific soil water capacity [1/cm])
  begin
    result := trdiag(false, act_n_comp, start, alpha, beta, gamma, Res);
    if result <> 0 then
      if ShowWarnings then

{$IFNDEF NONVISUAL}
        showmessage('Error solving equation system');

{$ELSE}
        writeln('Error solving equation system');

{$ENDIF}
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp { + 1 } do
      begin
        last_iter_theta[i] := theta_new[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_new[i];
      { Umsetzen der berechneten Spannungen }
      psi_neu[i] := max(0, Res[i]);
      // TODO if necessary, further check whether resetting to zero is required ...
      // Neue Wassergehalte aus Ableitung
      theta_new[i] := WPar[i].b_psi_f(psi_neu[i]);
      if ShowWarnings then
      begin
        if theta_new[i] < 1E-20 then
        begin

{$IFNDEF NONVISUAL}
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));

{$ELSE}
          writeln('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          writeln('Datum: ' + floattostr(GlobTime.v));

{$ENDIF}
        end;
      end;
    end;
    // if self.Untere_Randb = FreeFlow then begin
    // psi_neu[act_n_comp+1] := max(0, psi_neu[act_n_comp]);//-Abst[n_comp+1];
    // psi_neu[act_n_comp+1] := max(0,psi_neu[act_n_comp] - Abst[n_comp+1]);
    // theta_neu[act_n_comp+1] := Wpar[n_comp+1].b_psi_f(psi_neu[n_comp]);
    // end;

  end;

  procedure Find_flows;
  var
    i: byte;
    Overflow, inflow, infilbalance: real;
    PondCapa, PondDischargeRate: real;
    GW_inflow: TSoilArray; // flows induced by increasing groundwater table
  begin
    for i := 2 to n_comp + 1 do
      WflowInt_arr[i].v := wf[i] * avg_Ku[i - 1] *
        ((psi_neu[i] - psi_neu[i - 1]) / Dist[i - 1]) + avg_Ku[i - 1];

    if wet then
    begin // inflow higher than max. infiltration, infiltration is at its maximum value
      infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
      infilbalance := infilbalance * 10 * dt.v; // change into [mm]
      if infilbalance < 0.0 then // more infiltration than DayFlow
        PondedWater.v := PondedWater.v + infilbalance
      else
      begin // not all water can infiltrate ...
        PondCapa := PondMax.v - PondedWater.v; // in [mm]
        if infilbalance > PondCapa then // More water than can be stored
        begin
          Overflow := (infilbalance - PondCapa); // [mm]
          PondedWater.v := PondMax.v;
          CumRunoff.c := CumRunoff.c + Overflow;
        end
        else // soil surface is wet, max. infiltration but excess water is stored as ponded water
        begin
          PondedWater.v := PondedWater.v + infilbalance; // [mm]
        end;
      end;
    end;

    if not(wet) and (PondedWater.v > 0) then
    // discharge of ponded water possible
    begin
      PondDischargeRate := MaxFlow1 - DayFlow1;
      PondedWater.v := max(0, PondedWater.v - 10 * PondDischargeRate * dt.v);
    end;

    if LowerBoundaryCondition = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;
    if (LowerBoundaryCondition = Groundwatertable) then
    begin

      for i := act_n_comp + 1 to n_comp do
      begin
        GW_inflow[i + 1] := (theta_new[i] - WPar[i].b_sat) * Thick[i] / dt.v;
        theta_new[i] := WPar[i].b_sat;
      end;

      for i := act_n_comp + 2 to n_comp + 1 do
      begin
        WflowInt_arr[i].v := WflowInt_arr[i - 1].v + GW_inflow[i];
      end;
    end;
  end;

begin { procedure MixedHydruswater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  iter := 0;
  repeat
    CalcConductivities(ccMixedHydrus, true, true, false);
    CalcUpperBoundary;
    CalcMainLayers;
    CalcLowerBoundary;
    SolveEquationSystem;
    get_delt_iter_max;
{$IFNDEF NONVISUAL}
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
{$ENDIF}
    adjust_dt;
  until (success);
  Find_flows;
  // calcoverflow;
  GetWaterBalance;
  set_new_state_vars;
end;
{ -------------------------------------------------------------------------- }

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSoilWaterMod]);
{$ENDIF}
end;

end.
