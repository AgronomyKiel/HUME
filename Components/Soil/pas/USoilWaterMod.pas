unit USoilWaterMod; { Stand 19.4.09, Grundwasser eingebaut - Ulf Böttcher }

interface

uses
  UMod, UState, ULayeredSoil, UGenucht, classes, UAbstractSoilHeat,
  UAbstractPlant, USoilTexture, Forms, Chart, Series, InifilesNew;

const

  dWg = 0.0; /// 1E-8;     /// delta for changing water contents
  PsiAirDryness = 20000;  /// matrix potential of very dry soil


type
  TVGParsFromTexture = (FromPar, FromTexture);         /// TTexture_version = (RR, KA);
//  TKsFromTexture = TVGParsFromTexture;
  Tact_Evaporation = (red_f, inclExfiltration);       /// type for calculaiton options of evaporation
  Tm_model = (Mualem, Burdine, Vereecken);            /// type of model for calculating the parameter 'm' within the van Genuchten model
  TLowerBoundaryCondition = (NoFlow, FreeFlow, ConstContent, Groundwatertable);/// type for specifying lower boundary conditions
  TCompMethod = (Capacity, Diffusion, Richards, Mixed, MixedHydrus);/// type for specifying computation method
  TnFKCalcMethod = (FromParameter, Input);             /// type for specifying computation method for nFK
  TIniMethod = (Watercontents, Potentials, Parameter);/// type for initialization method
  Tred_f = (modifiedBeese, Beese1978);                /// Type of soil evaporation reduction function
  TSoilWaterParams = array [1 .. max_comp] of TGenucht;  /// Type for soil water parameters

  TSoilWaterMod = class(TLayeredSoil)  /// Component implementing vertical soil water transport

  private
    ResetTimeStep: boolean;  /// flag for resetting time step
    NewDay: boolean;         /// flag for start of a new day
    last_iter: integer;      /// number of iterations during previous internal time step
    Iter_save: integer;      /// field for saving itermax
    total_iter: integer;     /// total number of iterations during internal time step
    delt_iter_max: real;     /// maximum water content change within a single layer during an internal time step
    max_flow_ratio: real;    /// maximum ratio of flow to soil water storage during iteration in any layer
    theta_airdryness: real;  /// lower limit to soil water content [cm3/cm3]
    DayFlow1 : real;         /// upper flow rate, constant over one day  [cm/d]
    CumDayFlow1 : real;      /// cumulative flow into layer 1 over the day [cm/d]
    oldrunoff : real;        /// for saving old runoff rate value
    MaxInfil : real;         /// maximum infiltration rate
    max_IterErrorsave: real; ///
    start: byte;             /// number of layer where solution of equation system starts, mostly the first sometimes the second ..
    wet: boolean;            /// Sättigung im obersten Kompartiment ?
    dry: boolean;            /// Wassergehalt kleiner b_rest im obersten Komp.?
    success: boolean;        /// solution converged
    dt_set: boolean;         /// was dt set during act. iteration

    fCompMethod: TCompMethod; /// Enumeration type variable for computation method
    fShowWarnings: boolean;   /// Switch for put Warnings on and off
    FVGParsFromTexture: TVGParsFromTexture;
    Texture_version: TTexture_version;    /// type for defining pedotransfer function
    FKsFromTexture:  TVGParsFromTexture;//TKsFromTexture;
    FTextureClass1,
    { Bodenart in Horizont 1 bei TVGParsFromTexture = FromTexture }
    FTextureClass2, FTextureClass3, FTextureClass4: TTextureClass;
    fm_model: Tm_model;   /// type of m_model used
    fred_f: Tred_f;       /// Option for soil evaporation reduction function
    dt_old,               /// alte Zeitschrittweite [d]
    MaxAktAenderWaGe : real;  /// maximale Wassergehaltsänderung
    TempFactor : real; ///

    ndx_Weff: integer;     /// index of layer where maximum Weff is reached


    Dw_arr : TSoilArray;       /// Diffusivitäten [cm2/d] }
    c_arr: TSoilArray;        /// specific water capacity
    P: TSoilArray;            /// intermediate variable dt.v/(C_arr*??)
    kf: TSoilArray;           /// saturated hydraulic conductivities [cm/d]
    Ku_arr: TSoilArray;       /// ungesättigte hydraulische Leitfähigkeiten [cm/d] }
    avg_Dw: TSoilArray;       /// Mittelwert der Diffusivität zwischen 2 Kompartimenten [cm2/d] }
    avg_Ku: TSoilArray;       /// Mittelwert der unges„ttigten hydr. Leitfähigkeit zwischen 2 Kompartimenten [cm/d] }
    Dw_fact: TSoilArray;      /// Intermediate variable
    Ku_fact: TSoilArray;      /// Intermediate variable
    B_vektor: TSoilArray;     /// Intermediate variable: TSoilArray; known values and solution vektor
    lower: TSoilArray;        /// lower vector of the tri-diagonal matrix
    diag: TSoilArray;         /// central vector of the tri-diagonal matrix
    upper: TSoilArray;        /// upper vector of the tri-diagonal matrix
    last_iter_theta: TSoilArray; /// Wassergehalte bei der letzten Iteration [cm3/cm3 }
    est_theta: TSoilArray;    /// extrapolated soil water content for first iteration step
    wf: TSoilArray;           /// factor for calculation of flows in cases of near saturation
    flow_ratio: TSoilArray;   ///  ratio of flow to soil water storage


    PSI_dummy: TVAR;    /// dummy to set array settings

    IniMethod: TIniMethod;  /// Enumeration type variable for initialisation method
    nFKCalcMethod: TnFKCalcMethod;
    ///
    fWeffOpt: TSource;     /// Source of Weff

    FSoilHeatModel: TAbstractSoilHeat; /// Link to soil temperature model
    fTransferWGs: boolean;  /// Option, if true water contents are written into the next state ini-File of the control file
    alpha, beta, gamma, Res: TSoilArray;

    procedure CalcTempFactor; /// Calculation of freezing effect
    procedure CalcConductivities;  /// Calculation of conductivities
    procedure CapWatSolut;   /// caculation of water transport according to diffusivity approach
    procedure get_water_contents;
    procedure Diffwater_solut;     /// caculation of water transport according to diffusivity approach
    procedure Richardswater_solut; /// caculation of water transport according to Richards equation approach
    procedure Mixedwater_solut;   /// caculation of water transport according to "Mixed" approach
    procedure MixedHydruswater_solut;  /// caculation of water transport according to "Mixed Hydrus" approach

    procedure GetWaterBalance;  /// Calculation of soil water balance
    procedure get_new_dt;       /// Calculation of new internal time step width
    procedure adjust_dt;       /// adjust time step during picard iteration
    procedure get_delt_iter_max;   /// Calculation of maximal water content change within an internal time step
    procedure set_new_state_vars;   /// setting up the new state vars
    procedure CalcOverflow;        /// calculation of runoff
    function getNetRain: TExternV;
    function getPotEvap: TExternV;
    procedure CreateParameters;   /// wrapper for all parameter creation
    procedure CreateOptions;
    procedure CreateStates;
    procedure CreateVars;
    procedure InitGenuchtenPars;
    procedure SetCompMethod;
    procedure InitVectors;
    procedure SetGenuchtenPars;
    procedure SetLowerBoundaryCondition;
    procedure SetEvaporationReductionOption;
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
    procedure obere_Randbedingung;

  protected
    LowerBoundaryCondition: TLowerBoundaryCondition;    /// Lower boundary condition specification

    act_n_comp: integer;  /// actual number of layers to be calculated, variable in case of groundwater influence
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override;
    function ndx_str(i: integer): string;
    function getTexture(i: integer): TTextureClass;

  public
    ///
     iter: integer;    /// number of iterations during internal time step
    akt_bilanz_f  :real;
    sum_Bilanz_f: real;
    SW_start,   /// sum of soil and ponded water [mm]
    global_WaterBalance,
    old_global_WaterBalance: real;
    theta_arr: TSoilvarArray;  /// Wassergehaltsvektor [cm3/cm3]
    theta_neu: TSoilArray;     /// new soil water contents
    WAmount: TSoilStateArray;   /// Wassermenge je Schicht [cm]
    psi_arr: TSoilvarArray;    /// Wasserspannungsvektor [cm]
    Wflow_arr: TSoilvarArray;  /// Flussvektor [cm/d]
    WflowInt_arr: TSoilvarArray;  /// Flussvektor [cm/d] für internen Zeitschritt
    Sink_arr: TSoilvarArray;     /// Sinkvektor [cm]
    SinkInt_arr: TSoilvarArray;   /// Sinkvektor [cm/d] für internen Zeitschritt
    FK_Arr: TSoilArray;          /// Feldkapazität [cm3/cm3]
    PWP_Arr: TSoilArray;         /// permanenter Welkepunkt [cm3/cm3]
    nFK_Arr: TSoilArray;         /// nutzbare Feldkapazität [cm3/cm3]
    WPar: TSoilWaterParams;      /// Array der Van-Genuchten Parameter für jede Schicht

    Wflow_old: TSoilArray;       /// alte Wasserflüsse [cm/d]
    theta_old: TSoilArray;       /// alte Wassergehalte
    psi_neu: TSoilArray;         /// New estimate of water potential [cm]
    SW_Balance_arr: TSoilArray;  /// actual values of water balance for single layers
    cumSW_Balance_arr: TSoilArray; /// cumulative values of water balance for single layers

    HoriNdx1, HoriNdx2, HoriNdx3, HoriNdx4: TPar;
    /// Index der untersten Schicht im jeweiligen Horizont

    FVGParsFromTextOption: TOption; /// Texture_versionOption: TOption;
    FKsFromTextOption: TOption;
    act_EvaporationOption: TOption;
    red_fOption: TOption;

    OptUntere_Randb: TOption;     /// lowerBoundCond
    OptIniMethod: TOption;       /// Option for choosing the initialisaiton method
    OptCompMethod: TOption;     /// Option for choosing the computation method

    Groundwaterdepth: TExternV;  /// depth of groundwatertable [cm] needed if option is selected

    FTextClass1Option, FTextClass2Option, FTextClass3Option,
      FTextClass4Option: TTextClassOption;
    /// Options for choosing Parameters for 4 distinct horizons

    max_aenderWG: TPar;  /// maximale Wassergehaltsänderung pro Zeitschritt
    max_IterError: TPar; /// maximum change of water content in a layer between two iterations
    ///

    Max_dt: TPar;     /// maximum internal time step
    Min_dt: TPar;     /// minimum internal time step [d]
    IterMax: TPar;    /// maximum number of Iterations before internal time step is reduced

    bsat_scaling: TPar; /// Parameter for linear scaling of soil hydraulic Parameter bsat
    alpha_scaling: TPar;  /// Parameter for linear scaling of soil hydraulic Parameter alpha

    /// van-Genuchten Parameter fuer Horizont 1
    b_sat1: TPar;      /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest1: TPar;     /// "Restwassergehalt" [cm3/cm3] }
    alpha1: TPar;      /// Fitparameter "" [1/cm] }
    n_par1: TPar;      /// Fitparameter "n" dimensionslos }
    Ks1: TPar;         /// gesättigte Leitfähigkeit [cm.d-1]
    FK1: TPar;         /// Feldkapazität [cm3/cm3]
    PWP1: TPar;        /// permanenter Welkepunkt
    nFK1: TPar;        /// nutzbare Feldkapazität

    /// van-Genuchten Parameter fuer Horizont 2
    b_sat2: TPar;      /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest2: TPar;     /// "Restwassergehalt" [cm3/cm3] }
    alpha2: TPar;      /// Fitparameter "" [1/cm] }
    n_par2: TPar;      /// Fitparameter "n" dimensionslos }
    Ks2: TPar;         /// gesättigte Leitfähigkeit [cm.d-1]
    FK2: TPar;         /// Feldkapazität [cm3/cm3]
    PWP2: TPar;        /// permanenter Welkepunkt
    nFK2: TPar;        /// nutzbare Feldkapazität

    /// van-Genuchten Parameter fuer Horizont 3
    b_sat3: TPar;      /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest3: TPar;     /// "Restwassergehalt" [cm3/cm3] }
    alpha3: TPar;      /// Fitparameter "" [1/cm] }
    n_par3: TPar;      /// Fitparameter "n" dimensionslos }
    Ks3: TPar;         /// gesättigte Leitfähigkeit [cm.d-1]
    FK3: TPar;         /// Feldkapazität [cm3/cm3]
    PWP3: TPar;        /// permanenter Welkepunkt
    nFK3: TPar;        /// nutzbare Feldkapazität

    /// van-Genuchten Parameter fuer Horizont 4
    b_sat4: TPar;      /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest4: TPar;     /// "Restwassergehalt" [cm3/cm3] }
    alpha4: TPar;      /// Fitparameter "" [1/cm] }
    n_par4: TPar;      /// Fitparameter "n" dimensionslos }
    Ks4: TPar;         /// gesättigte Leitfähigkeit [cm.d-1]
    FK4: TPar;         /// Feldkapazität [cm3/cm3]
    PWP4: TPar;        /// permanenter Welkepunkt
    nFK4: TPar;        /// nutzbare Feldkapazität

    PsiStart1: TPar;     /// For initalisation of Soil water contents and suction values

    bil_nr: TPar;        /// Index of Layer where lower boundary fluxes are calculated
    Weff: TPar;          /// effective rooting deph [cm]

    psi_critEvap: TPar;     /// Wasserspannung ab der Evaporation abnimmt [hPa]

    NetRain: TExternV;    /// NetRain = Niederschlag - Interzeption
    // THumeNumEntity;              ///  NetRain = Niederschlag - Interzeption
    CumNetRain: TState;     /// kumulativer Niederschlag [mm]
    Pot_Evap: THumeNumEntity;  /// potentielle Evaporationsrate

    red_evap: TVAR;       /// Reduktionsfaktor für Evaporation
    Act_Evap: TVAR;       /// aktuelle Evaporationsrate
    Exfiltration: TVAR;     /// Estimation of maximum exfiltration rate
    CumTrans : TState;       /// kumulative Transpiration [mm]
    CumEvap: TState;        /// kumulative Evaporation
    CumDrainage: TState;     /// kumulative Sickerwasserspende/kapillarer Aufstieg [mm]
    CumWaterBalance: TState; ///
 //   CumAbsWaterBalance: TState; ///
    CumGlobalWaterBalance : TState;  /// Water-balance based on Evapotranspiration, losses and Rain

    PondedWater : TState; /// amount of ponded water on the soil surface [mm]
    PondMax : TPar; /// maximum ponding height [mm];

    /// kumulative Bilanz [mm] zur Kontrolle!
    CumRunoff: TState;    /// cumulative Runoff [mm]

    SumSoilWater: TVar;     /// sum of soil water down to boundary given by the Par "bil_nr"
    SumPAVSoilWater: TVar;  /// sum of plant available soil water down to boundary given by the Par "bil_nr"
    SumPAvSoilWaterRZ: TVar;   /// sum of plant available soil water in the rooting zone (down to Weff)
    global_iter: TVar;   /// total number of iterations over the simulation run

    dt: TVar; /// interne Zeitschrittweite des Diff. Wassertransportmodells
    n_int_timesteps: TVar;
    SumOfInternalTimeSteps: TVar;  /// Summe der internen Zeitschritte (Kontrollvariable)

    WG0_30, WG30_60, WG60_90, WG90_120, WG0_60,

      WG0_10, WG0_20, WG0_40, WG10_30, WG20_30, WG20_40, WG30_40, WG30_50,
      WG30_120, WG30_100, WG40_60, WG60_80, WG80_100, WG90_110, WG0_100,
      WG0_120, wg0_90, WG60_100: TVar;
    ProzNFK0_Weff: TVar;
    ProzNFK0_100: TVar;
    ProzNFK0_30: TVar;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcEvap_red_f;

    procedure Integrate; override;

    procedure CalcRatesAndIntegrate; virtual;

    procedure CalcRates; override;

    procedure CalcSinks; virtual;

    procedure update_Wcont_Values;

    procedure BeforeDestruction; override;
    property Texture[i: integer]: TTextureClass read getTexture;

  published
    property ShowWarnings: boolean read fShowWarnings write fShowWarnings;
    property m_model: Tm_model read fm_model write fm_model;
    property Opt_CompMethod: TCompMethod read fCompMethod write fCompMethod;
    property Opt_red_f: Tred_f read fred_f write fred_f;
    property Opt_maxWGchange: TPar read max_aenderWG write max_aenderWG;
    property Opt_IterError: TPar read max_IterError write max_IterError;

    property Opt_Randbed
      : TLowerBoundaryCondition read LowerBoundaryCondition write LowerBoundaryCondition;
    property Opt_IniMethod: TIniMethod read IniMethod write IniMethod;
    property Opt_maxdt: TPar read Max_dt write Max_dt;
    property Opt_mindt: TPar read min_dt write min_dt;
    property Opt_nFKCalcMethod
      : TnFKCalcMethod read nFKCalcMethod write nFKCalcMethod;
    property Opt_VanGenPars_from_Texture
      : TVGParsFromTexture read FVGParsFromTexture write FVGParsFromTexture;
//    property Opt_Ks_from_Texture
//      : TKsFromTexture read FKsFromTexture write FKsFromTexture;
    property Opt_Ks_from_Texture
      : TVGParsFromTexture read FKsFromTexture write FKsFromTexture;
    property Opt_TextureClass1
      : TTextureClass read FTextureClass1 write FTextureClass1;
    property Opt_TextureClass2
      : TTextureClass read FTextureClass2 write FTextureClass2;
    property Opt_TextureClass3
      : TTextureClass read FTextureClass3 write FTextureClass3;
    property Opt_TextureClass4
      : TTextureClass read FTextureClass4 write FTextureClass4;
    property Opt_TransferWGsToNextINI
      : boolean read fTransferWGs write fTransferWGs;
    property Opt_Weff: TSource read fWeffOpt write fWeffOpt;  /// Option for Source of parameter Weff

    property Ext_NetRain: TExternV read getNetRain;
    property Ex_PotEvap: TExternV read getPotEvap;
    property Ex_Groundwaterdepth  : TExternV read Groundwaterdepth write Groundwaterdepth;

    property Par_b_sat1: TPar read b_sat1 write b_sat1;
    property Par_b_rest1: TPar read b_rest1 write b_rest1;
    property Par_b_KS1: TPar read Ks1 write Ks1;
    property Par_n1: TPar read n_par1 write n_par1;
    property Par_alpha1: TPar read alpha1 write alpha1;
    property Par_FK1: TPar read FK1 write FK1;   /// Feldkapazität [cm3/cm3]
    property Par_PWP1: TPar read PWP1 write PWP1; /// permanenter Welkepunkt
    property Par_nFK1: TPar read nFK1;       /// nutzbare Feldkapazität

    property Par_b_sat2: TPar read b_sat2 write b_sat2;
    property Par_b_rest2: TPar read b_rest2 write b_rest2;
    property Par_b_KS2: TPar read Ks2 write Ks2;
    property Par_n2: TPar read n_par2 write n_par2;
    property Par_alpha2: TPar read alpha2 write alpha2;
    property Par_FK2: TPar read FK2 write FK2;    /// Feldkapazität [cm3/cm3]
    property Par_PWP2: TPar read PWP2 write PWP2;
    /// permanenter Welkepunkt
    property Par_nFK2: TPar read nFK2;
    /// nutzbare Feldkapazität

    property Par_b_sat3: TPar read b_sat3 write b_sat3;
    property Par_b_rest3: TPar read b_rest3 write b_rest3;
    property Par_b_KS3: TPar read Ks3 write Ks3;
    property Par_n3: TPar read n_par3 write n_par3;
    property Par_alpha3: TPar read alpha3 write alpha3;
    property Par_FK3: TPar read FK3 write FK3;
    /// Feldkapazität [cm3/cm3]
    property Par_PWP3: TPar read PWP3 write PWP3;
    /// permanenter Welkepunkt
    property Par_nFK3: TPar read nFK3;
    /// nutzbare Feldkapazität

    property Par_b_sat4: TPar read b_sat4 write b_sat4;
    property Par_b_rest4: TPar read b_rest4 write b_rest4;
    property Par_b_KS4: TPar read Ks4 write Ks4;
    property Par_n4: TPar read n_par4 write n_par4;
    property Par_alpha4: TPar read alpha4 write alpha4;
    property Par_FK4: TPar read FK4 write FK4;     /// Feldkapazität [cm3/cm3]
    property Par_PWP4: TPar read PWP4 write PWP4;  /// permanenter Welkepunkt
    property Par_nFK4: TPar read nFK4;              /// nutzbare Feldkapazität

    property Par_PsiStart1: TPar read PsiStart1 write PsiStart1;
    property Par_Weff: TPar read Weff write Weff;
    property Par_PondMax: TPar read PondMax write PondMax;

    property Var_WG0_30: TVar read WG0_30 write WG0_30;
    property Var_WG30_60: TVar read WG30_60 write WG30_60;
    property Var_WG30_120: TVar read WG30_120 write WG30_120;
    property Var_WG30_100: TVar read WG30_100 write WG30_100;
    property Var_WG60_90: TVar read WG60_90 write WG60_90;
    property Var_WG90_120: TVar read WG90_120 write WG90_120;
    property Var_WG0_100: TVar read WG0_100 write WG0_100;
    property Var_WG0_120: TVar read WG0_120 write WG0_120;
    property Var_WG0_90: TVar read wg0_90 write wg0_90;
    property Var_WG0_60: TVar read WG0_60 write WG0_60;

    property Var_Psi_dummy: TVar read PSI_dummy write PSI_dummy;
    property Var_ActEvap: TVar read Act_Evap write Act_Evap;

    property St_CumEvap: TState read CumEvap write CumEvap;
    property St_CumDrainage: TState read CumDrainage write CumDrainage;
    property St_CumNetRain: TState read CumNetRain write CumNetRain;
    property St_PondedWater: TState read PondedWater write PondedWater;

    property Par_psi_critEvap: TPar read psi_critEvap write psi_critEvap;

    property Par_Horindx1: TPar read HoriNdx1 write HoriNdx1;
    property Par_Horindx2: TPar read HoriNdx2 write HoriNdx2;
    property Par_Horindx3: TPar read HoriNdx3 write HoriNdx3;
    property Par_Horindx4: TPar read HoriNdx4 write HoriNdx4;

    property SoilHeatModel
      : TAbstractSoilHeat read FSoilHeatModel write FSoilHeatModel;

  end;

procedure Register;

var
  SoilWaterMod: TSoilWaterMod;

implementation

uses
  SysUtils, Math, Dialogs;

procedure TSoilWaterMod.update_Wcont_Values;
var
  i: integer;
begin
  // Berechnung der abgeleiteten Wassergehalte für verschiedene Bodenschichten

  WG0_30.v := (theta_arr[1].v + theta_arr[2].v + theta_arr[3].v) / 3;
  WG30_60.v := (theta_arr[4].v + theta_arr[5].v + theta_arr[6].v) / 3;
  WG60_90.v := (theta_arr[7].v + theta_arr[8].v + theta_arr[9].v) / 3;
  WG90_120.v := (theta_arr[10].v + theta_arr[11].v + theta_arr[12].v) / 3;

  WG0_10.v := theta_arr[1].v;
  WG20_30.v := theta_arr[3].v;
  WG30_40.v := theta_arr[4].v;

  WG0_20.v := (theta_arr[1].v + theta_arr[2].v) / 2;
  WG20_40.v := (theta_arr[2].v + theta_arr[4].v) / 2;
  WG10_30.v := (theta_arr[2].v + theta_arr[3].v) / 2;
  WG30_50.v := (theta_arr[4].v + theta_arr[5].v) / 2;
  WG40_60.v := (theta_arr[5].v + theta_arr[6].v) / 2;
  WG60_80.v := (theta_arr[7].v + theta_arr[8].v) / 2;
  WG80_100.v := (theta_arr[9].v + theta_arr[10].v) / 2;
  WG90_110.v := (theta_arr[10].v + theta_arr[11].v) / 2;

  WG0_120.v := 0;
  WG0_100.v := 0;
  wg0_90.v := 0;
  WG0_60.v := 0;
  WG0_40.v := 0;
  WG30_120.v := 0;
  WG30_100.v := 0;
  WG60_100.v := 0;

  for i := 4 to 12 do
    WG30_120.v := WG30_120.v + theta_arr[i].v;
  for i := 4 to 10 do
    WG30_100.v := WG30_100.v + theta_arr[i].v;
  for i := 1 to 4 do
    WG0_40.v := WG0_40.v + theta_arr[i].v;
  for i := 1 to 6 do
    WG0_60.v := WG0_60.v + theta_arr[i].v;
  for i := 1 to 9 do
    wg0_90.v := wg0_90.v + theta_arr[i].v;
  for i := 1 to 10 do
    WG0_100.v := WG0_100.v + theta_arr[i].v;
  for i := 1 to 12 do
    WG0_120.v := WG0_120.v + theta_arr[i].v;
  for i := 7 to 10 do
    WG60_100.v := WG60_100.v + theta_arr[i].v;

  WG0_60.v := WG0_60.v / 6;
  WG0_40.v := WG0_40.v / 4;
  wg0_90.v := wg0_90.v / 9;
  WG0_100.v := WG0_100.v / 10;
  WG0_120.v := WG0_120.v / 12;
  WG30_100.v := WG30_100.v / 7;
  WG30_120.v := WG30_120.v / 9;
  WG60_100.v := WG60_100.v / 4;
end;

function TSoilWaterMod.ndx_str(i: integer): string;
begin
  if i <= 9 then
    result := '_' + IntTostr(i)
  else
    result := IntTostr(i);
end;

function TSoilWaterMod.getTexture(i: integer): TTextureClass;
begin
  result := FTextureClass4;
  if i <= HoriNdx3.v then
    result := FTextureClass3;
  if i <= HoriNdx2.v then
    result := FTextureClass2;
  if i <= HoriNdx1.v then
    result := FTextureClass1;
end;

procedure TSoilWaterMod.CreateAll;

var
  i: integer;

begin
  fShowWarnings := true;
  inherited CreateAll;  // call TLayeredSoil.CreateAll
  m_model := Mualem;    // set Genuchten model option to Mualem model
  CreateParameters;     // Wrapper for parameter creation
  CreateOptions;
  CreateVars;
  CreateStates;
  ExternVCreate('Groundwaterdepth', '[cm]', StateField, Groundwaterdepth);
  if LowerBoundaryCondition = Groundwatertable then
    Groundwaterdepth.Search := true
  else
    Groundwaterdepth.Search := false;
  // if not (Netrain is TVar) then
  ExternVCreate('NetRain', '[mm/d]', StateField, NetRain, 'rain minus interception');
  if not(Pot_Evap is TVar) then
    ExternVCreate('PotEvap', '[mm/d]', StateField, TExternV(Pot_Evap));
  LowerBoundaryCondition := FreeFlow; // default for lower boundary is a free flow
end;

procedure TSoilWaterMod.BeforeDestruction;
var
  i: integer;

begin
  for i := 1 to n_comp + 1 do
    if WPar[i] <> nil then
      FreeAndNil(WPar[i]);
  inherited;
end;

procedure TSoilWaterMod.TransferWGsToNextINI;
var
  i: Integer;
  NextINI: TMyIniFile;
  NextStateINI: TMyIniFile;
  IniFileNdx : Integer;
begin
  begin
    IniFileNdx := GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName);
    if (IniFileNdx <> GlobMod.IniFileNames.Count - 1) then  begin
      //  exit;
      NextINI := TMyIniFile.create;
      NextINI.Init(GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName) + 1]);
      NextStateINI := TMyIniFile.create;
      NextStateINI.Init(NextINI.ReadString('FileNames', 'StateIniFN', ''));
      for i := 1 to n_comp + 1 do
      begin
        NextStateINI.WriteString(Name, 'WG' + ndx_str(i), FloatToStrF(theta_arr[i].v, ffFixed, 9, 6));
      end;
      NextINI.Free;
      NextStateINI.Free;
    end;
  end;
end;

procedure TSoilWaterMod.CalcProfile_and_HorizonSums;
var
  nFK0_100: real;
  i: Integer;
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
  ProzNFK0_30.v := (WG0_30.v * 3 - (PWP_Arr[1] + PWP_Arr[2] + PWP_Arr[3])) / (nFK_Arr[1] + nFK_Arr[2] + nFK_Arr[3]) * 100;
end;

procedure TSoilWaterMod.InitDailySums_and_Changes(var OldSumSoilwater: real);
var
  OldSumWater: real;
  OldPondedWater: real;
  i: Integer;
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
  OldSumWater := OldSumSoilWater + PondedWater.v;
  for i := 1 to n_comp + 1 do
    Wflow_arr[i].v := 0;
  n_int_timesteps.v := 0;
  dt.v := dt_old;
end;

procedure TSoilWaterMod.CalcGlobalWaterBalance;
begin
  //Rain-W_loss-Trans-Evap-SW_diff
  old_global_WaterBalance := global_WaterBalance;
  global_WaterBalance := CumNetRain.v - (CumRunoff.v + CumDrainage.v) - CumTrans.v - CumEvap.v - (SumSoilWater.v + PondedWater.v - SW_start);
  CumGlobalWaterBalance.c := abs(global_WaterBalance - old_global_WaterBalance);
end;

procedure TSoilWaterMod.CalcProfileWaterBalance(OldSumSoilwater: Extended);
begin
  if GlobTime.v > GlobMod.Starttime then
  begin
    CumWaterBalance.c := (SumSoilWater.v - OldSumSoilwater) + (-Wflow_arr[1].v * 10 + CumDrainage.c) * GlobTime.c;
  end;
  // [mm]
end;

procedure TSoilWaterMod.CalcTotalWaterAmounts;
var
  i: Integer;
  SumWater: Extended;
begin
  SumSoilWater.v := 0;
  SumPAVSoilWater.v := 0;
  for i := 1 to trunc(bil_nr.v) do
  begin
    SumSoilWater.v := SumSoilWater.v + WAmount[i].v * 10;
    // [mm]
    SumPAVSoilWater.v := SumPAVSoilWater.v + WAmount[i].v * 10 - PWP_Arr[i] * Thick[i] * 10;
  end;
  SumWater := SumSoilWater.v + PondedWater.v;
end;

procedure TSoilWaterMod.Find_Number_of_computation_Layers;
begin
  // default value for computation index
  if Opt_Randbed = Groundwatertable then
  begin
    act_n_comp := 2;
    repeat
      inc(act_n_comp);
    until (Depth[act_n_comp + 1].v >= Groundwaterdepth.v) or (act_n_comp >= n_comp);
  end;
end;

procedure TSoilWaterMod.SaveOldValuesForCrankNicholson_SoluteTransport;
var
  i: Integer;
begin
  // save old flows for Crank-Nicholson calculation of solute transport
  for i := 1 to n_comp + 1 do
  begin
    Wflow_old[i] := wflow_arr[i].v;
    theta_old[i] := theta_arr[i].v;
  end;
end;

procedure TSoilWaterMod.CheckForHoriIndexInitialisation;
begin
  if round(HoriNdx1.v) = 0 then
  begin
    if ShowWarnings then
    begin
      showmessage('Warning ! No specification of Indexes for hydraulic parameters');
      showmessage('Please check !');
    end;
  end;
end;

procedure TSoilWaterMod.SetNewPsi_and_Theta_Values;
var
  i: Integer;
begin
  for i := 1 to n_comp + 1 do
  begin
    psi_neu[i] := psi_arr[i].v;
    theta_neu[i] := theta_arr[i].v;
  end;
end;

procedure TSoilWaterMod.Calc_nFKparsForHorizons;

begin
  begin
    { Berechnung von FK, PWP und nFK aus van-Genuchten-Parametern mit der Funktion b_psi_f (unit UGenucht) }
    Par_FK1.v := WPar[round(HoriNdx1.v)].b_psi_f(power(10, 1.8));
    Par_PWP1.v := WPar[round(HoriNdx1.v)].b_psi_f(power(10, 4.2));
    Par_nFK1.v := Par_FK1.v - Par_PWP1.v;
    Par_FK2.v := WPar[round(HoriNdx2.v)].b_psi_f(power(10, 1.8));
    Par_PWP2.v := WPar[round(HoriNdx2.v)].b_psi_f(power(10, 4.2));
    Par_nFK2.v := Par_FK2.v - Par_PWP2.v;
    Par_FK3.v := WPar[round(HoriNdx3.v)].b_psi_f(power(10, 1.8));
    Par_PWP3.v := WPar[round(HoriNdx3.v)].b_psi_f(power(10, 4.2));
    Par_nFK3.v := Par_FK3.v - Par_PWP3.v;
    Par_FK4.v := WPar[round(HoriNdx4.v)].b_psi_f(power(10, 1.8));
    Par_PWP4.v := WPar[round(HoriNdx4.v)].b_psi_f(power(10, 4.2));
    Par_nFK4.v := Par_FK4.v - Par_PWP4.v;
  end;
end;

procedure TSoilWaterMod.Calc_nFK(psiFK: Extended; psiWP: Extended);

var
  PWP0_100: Extended;
  nFK0_100: Extended;

  nFK0_Weff : real;
  PWP0_Weff : real;
  WG0_Weff : real;
  i: Integer;

  begin
  for i := 1 to n_comp do
  begin
    FK_Arr[i] := WPar[i].b_psi_f(psiFK);
    PWP_Arr[i] := WPar[i].b_psi_f(psiWP);
    nFK_Arr[i] := FK_Arr[i] - PWP_Arr[i];
  end;
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

procedure TSoilWaterMod.SetEvaporationReductionOption;
begin
  if uppercase(red_fOption.Option) = 'MODIFIEDBEESE' then
    fred_f := modifiedBeese;
  if uppercase(red_fOption.Option) = 'BEESE1978' then
    fred_f := Beese1978;
end;

procedure TSoilWaterMod.SetLowerBoundaryCondition;
begin
  if uppercase(OptUntere_Randb.Option) = 'CONSTCONTENT' then
    LowerBoundaryCondition := ConstContent;
  if uppercase(OptUntere_Randb.Option) = 'NOFLUX' then
    LowerBoundaryCondition := NoFlow;
  if uppercase(OptUntere_Randb.Option) = 'GROUNDWATER' then
    LowerBoundaryCondition := Groundwatertable;
  if uppercase(OptUntere_Randb.Option) = 'FREEFLOW' then
    LowerBoundaryCondition := FreeFlow;
  if LowerBoundaryCondition = Groundwatertable then
    Groundwaterdepth.Search := true
  else
    Groundwaterdepth.Search := false;
end;

procedure TSoilWaterMod.SetGenuchtenPars;
var
  i: Integer;
begin
  setTextClassOption(FTextureClass1, FTextClass1Option.Option);
  setTextClassOption(FTextureClass2, FTextClass2Option.Option);
  setTextClassOption(FTextureClass3, FTextClass3Option.Option);
  setTextClassOption(FTextureClass4, FTextClass4Option.Option);
  if FVGParsFromTexture = FromTexture then
  begin
    for i := 1 to round(HoriNdx1.v) do
    begin
      if uppercase(Texture_versionOption.Option) = 'RR' then
        VanGenuchtenFromTextureClass_RR(WPar[i], FTextureClass1)
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
    for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
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
      WPar[i].l_par := 0.5;
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
      WPar[i].l_par := 0.5;
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
      WPar[i].l_par := 0.5;
      WPar[i].Ks := Ks3.v;
    end;
    for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
    begin
      WPar[i].b_sat := b_sat4.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest4.v;
      WPar[i].alpha := alpha4.v * alpha_scaling.v;
      WPar[i].n_par := n_par4.v;
      case m_model of
        Mualem:
          WPar[i].m_par := 1 - 1 / n_par4.v;
        Burdine:
          WPar[i].m_par := 1 - 2 / n_par4.v;
        Vereecken:
          WPar[i].m_par := 1;
      end;
      WPar[i].l_par := 0.5;
      WPar[i].Ks := Ks4.v;
    end;
  end;
  if FKsFromTexture = FromTexture then
  begin
    for i := 1 to round(HoriNdx1.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass1)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass1);
    for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass2)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass2);
    for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass3)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass3);
    for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
      if uppercase(Texture_versionOption.Option) = 'RR' then
        WPar[i].Ks := KSFromTextureClass_RR(FTextureClass4)
      else
        WPar[i].Ks := KSFromTextureClass_KA(FTextureClass4);
  end;
end;

procedure TSoilWaterMod.InitVectors;
var
  i: Integer;
begin
  for i := 0 to max_comp do
  begin
    Dw_arr[i] := 0;     /// Diffusivitäten [cm2/d] }
    c_arr[i] := 0;      /// specific water capacity
    P[i] := 0;          /// intermediate variable dt.v/(C_arr*??)
    kf[i] := 0;         /// saturated hydraulic conductivities [cm/d]
    Ku_arr[i] := 0;     /// ungesättigte hydraulische Leitfähigkeiten [cm/d] }
    avg_Dw[i] := 0;     /// Mittelwert der Diffusivität zwischen 2 Kompartimenten [cm2/d] }
    avg_Ku[i] := 0;     /// Mittelwert der unges„ttigten hydr. Leitfähigkeit zwischen 2 Kompartimenten [cm/d] }
    Dw_fact[i] := 0;    /// Intermediate variable
    Ku_fact[i] := 0;    /// Intermediate variable
    B_vektor[i] := 0;   /// Intermediate variable[i] := 0.0; known values and solution vektor
    lower[i] := 0;      /// lower vector of the tri-diagonal matrix
    diag[i] := 0;      /// central vector of the tri-diagonal matrix
    upper[i] := 0;     /// upper vector of the tri-diagonal matrix
    last_iter_theta[i] := 0;     /// Wassergehalte bei der letzten Iteration [cm3/cm3 }
    est_theta[i] := 0;
    theta_neu[i] := 0;  /// new soil water contents
    FK_Arr[i] := 0;   /// Feldkapazität [cm3/cm3]
    PWP_Arr[i] := 0;    /// permanenter Welkepunkt [cm3/cm3]
    nFK_Arr[i] := 0;    /// nutzbare Feldkapazität [cm3/cm3]
    Wflow_old[i] := 0;    /// alte Wasserflüsse [cm/d]
    theta_old[i] := 0;   /// alte Wassergehalte
    psi_neu[i] := 0;      /// New estimate of water potential [cm]
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
  i: Integer;
begin
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
    WPar[i].l_par := 0.5;
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
    WPar[i].l_par := 0.5;
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
    WPar[i].l_par := 0.5;
    WPar[i].Ks := Ks3.v;
  end;
  for i := round(HoriNdx3.v) + 1 to n_comp + 1 do
  begin
    WPar[i].b_sat := b_sat4.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest4.v;
    WPar[i].alpha := alpha4.v * alpha_scaling.v;
    WPar[i].n_par := n_par4.v;
    case m_model of
      Mualem:
        WPar[i].m_par := 1 - 1 / n_par4.v;
      Burdine:
        WPar[i].m_par := 1 - 2 / n_par4.v;
      Vereecken:
        WPar[i].m_par := 1;
    end;
    WPar[i].l_par := 0.5;
    WPar[i].Ks := Ks4.v;
  end;
end;

procedure TSoilWaterMod.CreateVars;
var
  i: Integer;
begin
  for i := 1 to n_comp + 1 do
  begin
    VarCreate('WG' + ndx_str(i), '[cm3.cm-3]', 0.3, true, theta_arr[i], 'Wassergehaltsvektor [cm3/cm3]');
    theta_arr[i].ReadFromIniFile := true;
    VarCreate('Psi' + ndx_str(i), '[cm]', WPar[i].psi_b_f(theta_arr[i].v), true, psi_arr[i], '// Wasserspannungsvektor [cm]');
    VarCreate('WFlowInt' + ndx_str(i), '[cm.d-1]', 0, false, WflowInt_arr[i]);
    WflowInt_arr[i].writetoFile := false;
    VarCreate('WFlow' + ndx_str(i), '[cm.d-1]', 0, false, Wflow_arr[i], 'Flussvektor [cm/d]');
    Wflow_arr[i].writetoFile := true;
    VarCreate('Sink' + ndx_str(i), '[cm.d-1]', 0, false, Sink_arr[i], 'Sinkvektor [cm]');
    VarCreate('SinkInt_' + ndx_str(i), '[cm.d-1]', 0, false, SinkInt_arr[i]);
    SinkInt_arr[i].writetoFile := false;
  end;
  VarCreate('red_evap', '[]', 1, false, red_evap, 'reduction factor for evaporation');
  VarCreate('act_evap', '[mm/d]', 0, false, Act_Evap, 'actual daily evaporation rate');
  VarCreate('dt_int', '[d]', 0.1, false, dt, 'internal time step length');
    VarCreate('Exfiltration', '[mm]', 0.0, true, Exfiltration);
  VarCreate('SumSoilWater', '[mm]', 0.0, true, SumSoilWater, 'sum of soil water in entire profile');
  VarCreate('SumPavSoilWater', '[mm]', 0.0, true, SumPAVSoilWater, 'sum of plant available soil water in entire profile');
  VarCreate('SumPAvSoilWaterRZ', '[mm]', 0.0, true, SumPAvSoilWaterRZ ,
    'sum of plant available soil water in the rooting zone (down to Weff)');
  VarCreate('psi_dummy', '[]', 0.0, true, PSI_dummy);
  VarCreate('n_int_timesteps', '[]', 0.0, true, n_int_timesteps, 'number of internal daily time steps');
  VarCreate('sumof_internaltimesteps', '[]', 0.0, true, SumOfInternalTimeSteps, 'total number of time steps of water balance calculation over simulation period');
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
    'Anteil pflanzenverfügbares Wasser an der nFK in Prozent');


end;

procedure TSoilWaterMod.CreateStates;
var
  i: Integer;
begin
  StateCreate('CumGlobalWaterBalance', '[mm]', 0, true, CumGlobalWaterBalance);
  StateCreate('CumEvap', '[mm]', 0, true, CumEvap, 'Cumulative evaporation');
  StateCreate('CumDrainage', '[mm]', 0, true, CumDrainage, 'cumulative water loss at layer xx');
  StateCreate('CumWaterBalance', '[mm]', 0, true, CumWaterBalance, 'water balance calculated from total soil profile changes [mm]');
//  StateCreate('CumAbsWaterBalance', '[mm]', 0, true, CumAbsWaterBalance);
  StateCreate('CumRunoff', '[mm]', 0, true, CumRunoff, 'calculated survace run off');
  StateCreate('CumTrans', '[mm]', 0, true, CumTrans, 'cumulative transpiration');
  StateCreate('CumNetRain', '[mm]', 0, true, CumNetRain, 'cumulative rain minus interception');
  StateCreate('PondedWater', '[mm]', 0, false, PondedWater, 'Amount of ponded water on soil surface');
  for i := 1 to n_comp + 1 do
  begin
    StateCreate('WMenge' + ndx_str(i), '[cm]', theta_arr[i].v * Thick[i], false, WAmount[i], 'Wassermenge je Schicht [cm]');
    WAmount[i].ReadFromIniFile := false;
  end;
end;

procedure TSoilWaterMod.CreateOptions;
begin
  OptCreate('FVGParsFromTexture', 'FromPar', FVGParsFromTextOption, 'Option for Initiatlisation of Van Genuchten Parameters');
  FVGParsFromTextOption.OptionList.Clear;
  FVGParsFromTextOption.OptionList.Add('FromPar');
  FVGParsFromTextOption.OptionList.Add('FromTexture');
  { OptCreate('Texture_version', 'RR', Texture_versionOption);
    Texture_versionOption.OptionList.Clear;
    Texture_versionOption.OptionList.Add('RR');
    Texture_versionOption.OptionList.Add('KA'); }
  OptCreate('FKsFromTexture', 'FromPar', FKsFromTextOption);
  FKsFromTextOption.OptionList.Clear;
  FKsFromTextOption.OptionList.Add('FromPar');
  FKsFromTextOption.OptionList.Add('FromTexture');
  OptCreate('act_Evaporation', 'red_f', act_EvaporationOption, 'Option for calculation actual evaporation');
  act_EvaporationOption.OptionList.Clear;
  act_EvaporationOption.OptionList.Add('red_f');
  act_EvaporationOption.OptionList.Add('inclExfiltration');
  OptCreate('evaporation red_f', 'modifiedBeese', red_fOption, 'Option for calculation evaporation reduction factor');
  red_fOption.OptionList.Clear;
  red_fOption.OptionList.Add('modifiedBeese');
  red_fOption.OptionList.Add('Beese1978');
  OptCreate('FTextureClass1', 'Sl3', TOption(FTextClass1Option), 'texture class for first horizon');
  OptCreate('FTextureClass2', 'Sl3', TOption(FTextClass2Option), 'texture class for second horizon');
  OptCreate('FTextureClass3', 'Sl3', TOption(FTextClass3Option), 'texture class for third horizon');
  OptCreate('FTextureClass4', 'Sl3', TOption(FTextClass4Option), 'texture class for fourth horizon');
  FTextClass1Option.AddTextureClasses;
  FTextClass2Option.AddTextureClasses;
  FTextClass3Option.AddTextureClasses;
  FTextClass4Option.AddTextureClasses;
  // Options for lower boundary: NoFlow, Flow, Content, Groundwatertable
  OptCreate('Untere_Randb', 'ConstContent', OptUntere_Randb, 'Option for lower boundary condition, 4 options implemented, constant water content/matrix potential („ConstContent“), n_comp + 1 keeps constant, („FreeFlow“) („NoFlow“)');
  OptUntere_Randb.OptionList.Add('ConstContent');
  OptUntere_Randb.OptionList.Add('NoFlux');
  OptUntere_Randb.OptionList.Add('Groundwater');
  OptUntere_Randb.OptionList.Add('FreeFlow');
  OptCreate('IniMethod', 'Parameter', OptIniMethod, 'Option for initialisation method');
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
  // Defaul Computatio option
  OptCreate('CompMethod', 'Diffusion', OptCompMethod, 'Option for numerical solution of water transport equation');
  OptCompMethod.OptionList.Clear;
  OptCompMethod.OptionList.Add('Diffusion');
  OptCompMethod.OptionList.Add('Richards');
  OptCompMethod.OptionList.Add('Mixed');
  OptCompMethod.OptionList.Add('MixedHydrus');
  OptCompMethod.OptionList.Add('Capacity');
end;

procedure TSoilWaterMod.CreateParameters;
var
  i: Integer;

begin
  ParCreate('Max_dt', '[d]', 1, Max_dt, 'maximum time step length for internal calculation');
  ParCreate('Min_dt', '[d]', 0.0001, Min_dt, 'minimum time step length for internal calculation');
  ParCreate('Itermax ', '[n]', 7, itermax, 'minimum number of iterations before time step is adjusted');
  // Index für Bilanzierung
  ParCreate('Max_aenderWG', '[cm3/cm3]', 0.001, max_aenderWG, 'maximum WChange during one internal time step');
  // Index für Bilanzierung
  ParCreate('Max_IterError', '[cm3/cm3]', 0.0001, max_IterError, 'maximum Change of Water content during one (Picard)-Iteration ');
  // Index für Bilanzierung
  ParCreate('bil_nr', '[]', 18, bil_nr);
  // Index für Bilanzierung
  for i := 1 to n_comp + 1 do
    if WPar[i] = nil then
      WPar[i] := TGenucht.create;
  ParCreate('HoriNdx1', '[-]', 3, HoriNdx1, 'unterste Schicht des 1. Bodenhorizonts');
  ParCreate('HoriNdx2', '[-]', 6, HoriNdx2, 'unterste Schicht des 2. Bodenhorizonts');
  ParCreate('HoriNdx3', '[-]', 10, HoriNdx3, 'unterste Schicht des 3. Bodenhorizonts');
  ParCreate('HoriNdx4', '[-]', 20, HoriNdx4, 'unterste Schicht des 4. Bodenhorizonts');
  ParCreate('bsat_scaling', '[-]', 1, bsat_scaling, 'Skalierungsfaktor für bsat (wird in allen Horizonten mit diesem Faktor multipliziert)');
  ParCreate('alpha_scaling', '[-]', 1, alpha_scaling, 'Parameter for linear scaling of soil hydraulic Parameter alpha');
  ParCreate('b_sat1', '[cm3.cm-3]', 0.4298, b_sat1, 'Van Genuchten Parameter b_sat');
  ParCreate('b_rest1', '[cm3.cm-3]', 0.09, b_rest1, 'Van Genuchten Parameter b_rest');
  ParCreate('alpha1', '[1/cm]', 0.00677, alpha1, 'Van-Genuchten-Parameter alpha für den 1. Bodenhorizont');
  ParCreate('n_par1', '[-]', 1.29494, n_par1, 'Van-Genuchten-Parameter n für den 1. Bodenhorizont');
  ParCreate('Ks_1', '[-]', 50, Ks1, 'Van Genuchten Parameter K_sat');
  ParCreate('FK_1', '[cm3/cm3]', 0.35, FK1, 'field capacity');
  ParCreate('nFK_1', '[cm3/cm3]', 0.25, nFK1, 'plant available soil water content');
  ParCreate('PWP_1', '[cm3/cm3]', 0.1, PWP1, 'residual soil water, not plant available content');
  ParCreate('b_sat2', '[cm3.cm-3]', 0.45, b_sat2);
  ParCreate('b_rest2', '[cm3.cm-3]', 0.09, b_rest2);
  ParCreate('alpha2', '[1/cm]', 0.00677, alpha2);
  ParCreate('n_par2', '[-]', 1.29494, n_par2);
  ParCreate('Ks_2', '[-]', 50, Ks2);
  ParCreate('FK_2', '[cm3/cm3]', 0.35, FK2);
  ParCreate('nFK_2', '[cm3/cm3]', 0.25, nFK2);
  ParCreate('PWP_2', '[cm3/cm3]', 0.1, PWP2);
  ParCreate('b_sat3', '[cm3.cm-3]', 0.45, b_sat3);
  ParCreate('b_rest3', '[cm3.cm-3]', 0.09, b_rest3);
  ParCreate('alpha3', '[1/cm]', 0.00677, alpha3);
  ParCreate('n_par3', '[-]', 1.29494, n_par3);
  ParCreate('Ks_3', '[-]', 50, Ks3);
  ParCreate('FK_3', '[cm3/cm3]', 0.35, FK3);
  ParCreate('nFK_3', '[cm3/cm3]', 0.25, nFK3);
  ParCreate('PWP_3', '[cm3/cm3]', 0.1, PWP3);
  ParCreate('b_sat4', '[cm3.cm-3]', 0.45, b_sat4);
  ParCreate('b_rest4', '[cm3.cm-3]', 0.09, b_rest4);
  ParCreate('alpha4', '[1/cm]', 0.00677, alpha4);
  ParCreate('n_par4', '[-]', 1.29494, n_par4);
  ParCreate('Ks_4', '[-]', 50, Ks4);
  ParCreate('FK_4', '[cm3/cm3]', 0.35, FK4);
  ParCreate('nFK_4', '[cm3/cm3]', 0.25, nFK4);
  ParCreate('PWP_4', '[cm3/cm3]', 0.1, PWP4);
  ParCreate('PsiStart1', '[cm]', 500, PsiStart1, 'Initial matric potential of uppermost layer at simulation start');
  ParCreate('Weff', '[cm]', 100, Weff, 'effective rooting deph [cm]');
  ParCreate('PondMax', '[mm]', 10, PondMax, 'maximum height of ponded Water on Soil Surface');
  ParCreate('psi_critEvap', '[hPa]', 500.0, psi_critEvap, 'suction where evaporation switches from potential to transport limited rate');
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
  nFK0_Weff, PWP0_Weff, WG0_Weff: real;

begin
  inherited Init(GlobMod);
  self.max_IterErrorsave := self.max_aenderWG.v;
  Iter_save := trunc(IterMax.v);
  MaxAktAenderWaGe := 0.0; // hp & ar 07.01.2010  !
  sum_Bilanz_f := 0.0;
  dt_old := dt.v;
  red_evap.v := 1.0;
  Act_Evap.v := 0.0;
  dt_set := false;
  dt.v := 0.001;
  dt_old := dt.v;
  iter := 0;
  total_iter := 0;
  last_iter := 0;
  SW_start:= 0;
  global_WaterBalance:= 0;
  old_global_WaterBalance:= 0;
  psiWP := power(10, 4.2);
  psiFK := power(10, 1.8);
  CumEvap.v := 0.0;
  CumDrainage.v := 0.0;

  SetLowerBoundaryCondition;             // from option

  Max_dt.v := min(Max_dt.v, GlobMod.Time.c);
  // value of maximum timestep
  // UB 20.1.16: Min eingefügt, damit kleinere maximale Zeitschritte über property
  // einstellbar sind.
  // hk 25.1.01: sollte eigentlich über die Property einzustellen sein ...
  // keine Ahnung wer das reingeschrieben hatte ...
  // max_aenderWG := 0.01; // maximale Wassergehaltsänderung pro Zeitschritt

  InitVectors;

//  InitGenuchtenPars;

  if uppercase(FVGParsFromTextOption.Option) = 'FROMPAR' then
    FVGParsFromTexture := FromPar;
  if uppercase(FVGParsFromTextOption.Option) = 'FROMTEXTURE' then
    FVGParsFromTexture := FromTexture;


  SetGenuchtenPars;       // Init Genuchten Pars

  // set "property Variable" according to option choise in Options.ini
  if OptIniMethod.Option = 'watercontents' then
    Opt_IniMethod := Watercontents;
  if OptIniMethod.Option = 'potentials' then
    Opt_IniMethod := Potentials;
  if OptIniMethod.Option = 'parameter' then
    Opt_IniMethod := Parameter;

  if Opt_IniMethod = Watercontents then
  begin
    for i := 1 to n_comp + 1 do
    begin
      if theta_arr[i].wasreadfromfile = false then
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
      GlobMod.StateIniFile.WriteFloat(SubModName , psi_arr[i].name, psi_arr[i].v);
      WAmount[i].v := theta_arr[i].v * Thick[i];
      theta_old[i] := theta_arr[i].v
    end
  end
  else if Opt_IniMethod = Potentials then
  begin
    for i := 1 to n_comp + 1 do
    begin
      psi_arr[i].v := GlobMod.StateIniFile.ReadFloat(self.name, psi_arr[i].name,
        100);
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(self.name, theta_arr[i].name, theta_arr[i].v);
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
      GlobMod.StateIniFile.WriteFloat(self.name, theta_arr[i].name, theta_arr[i].v);
      WAmount[i].v := theta_arr[i].v * Thick[i];
      theta_old[i] := theta_arr[i].v
    end;

  end;

  SetNewPsi_and_Theta_Values;
  SetCompMethod;
  CheckForHoriIndexInitialisation;

  if Opt_nFKCalcMethod = FromParameter then
    Calc_nFKparsForHorizons;

  update_Wcont_Values;

  Calc_nFK(psiFK, psiWP);

  SetEvaporationReductionOption;
  for i := 1 to n_comp do
    sink_arr[i].v := 0.0;

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
{ Zweck : Ermittlung eines Reduktionsfaktors der die potentielle
  Evaporation um den Einfluá einer geringen Bodenfeuchte an der
  Bodenfl„che korrigiert

  Parameter :

  Name             Inhalt                          Einheit      Typ

  Psi              Bodenwasserspannung im          [cm]         I
  obersten Kompartimente (10 cm Tiefe)

  evap_red_f       Reduktionsfaktor der            [-]           O
  potentiellen Evaporation

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
  OldSumSoilwater
  : real;

begin
  SaveOldValuesForCrankNicholson_SoluteTransport;
  InitDailySums_and_Changes(OldSumSoilwater);
  { Startwert für Zeitschrittweiten-Steuerung ist der vorletzte Zeitschritt des vorherigen Tages. }
  act_n_comp := n_comp;
  Find_Number_of_computation_Layers;
  repeat
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

procedure TSoilWaterMod.CalcConductivities;

var
  i: byte;
  Overflow: real;
begin
  {if (iter = 0) and (fCompMethod = Diffusion) then
  begin // lineare Extrapolation der Wassergehalte bei der ersten Iteration
    for i := 1 to n_comp do begin
      est_theta[i + 1] := 0.5 * (1 + dt.v / (2 * dt_alt)) *
        (theta_arr[i].v + theta_arr[i + 1].v) - 0.25 * dt.v / dt_alt *
        (theta_alt[i] + theta_alt[i + 1]);
      // psi_arr[i].v := WPar[i].psi_b_f(est_theta[i]);
    end;

    for i := 2 to n_comp + 1 do
    begin
      avg_Dw[i] := sqrt(max(0,WPar[i].Dw_f(est_theta[i]) * WPar[i - 1].Dw_f
          (est_theta[i - 1])));
      avg_Ku[i] := sqrt(max(0,WPar[i].Ku_b_f(est_theta[i]) * WPar[i - 1].Ku_b_f
          (est_theta[i - 1])));
    end;
    for i := 2 to n_comp + 1 do
    begin
      Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
      Ku_fact[i] := avg_Ku[i] * dt.v;
    end;
  end
  else  }
    begin // weitere Iterationen
    // Berechnung der Wasserdiffusivität und der ungesättigten hydraulischen
    // Leitfähigkeit für jedes Kompartiment aus dem Mittelwert der Wassergehalte
    // zu Beginn des Zeitschrittes und zum Ende des Zeitschrittes
    for i := 1 to n_comp + 1 do
    begin
      // c_arr[i]  := WPar[i].C_psi_f(psi_arr[i].v);
      // Dw_arr[i] := WPar[i].Dw_f((theta_neu[i] + theta_arr[i].v) / 2.0);
      // Ku_arr[i] := WPar[i].Ku_b_f((theta_neu[i] + theta_arr[i].v) / 2.0);

      // Version mit C gemittelt über Beginn und Ende Zeitschritt und impliziter Berechnung der Leitfähigkeiten
      // c_arr[i]  := (WPar[i].C_psi_f(psi_neu[i])+WPar[i].C_psi_f(psi_arr[i].v))/2;
      Dw_arr[i] := WPar[i].Dw_f(theta_neu[i]);
      Ku_arr[i] := WPar[i].Ku_b_f(theta_neu[i]);
    end;

    { Berechnung des Mittelwertes der Leitfähigkeit zwischen 2 Kompartimenten }
    for i := 2 to n_comp + 1 do
    begin
      // if (psi_neu[i-1]>(psi_neu[i]+Abst[i])) and // upward flow according to tensions
      // (theta_neu[i-1] < theta_neu[i]) then //  upward flow according to soil water
      // avg_Dw[i] := Dw_arr[i-1];
      // if (psi_neu[i-1]<(psi_neu[i]+Abst[i])) and // downward flow according to tensions
      // (theta_neu[i-1] > theta_neu[i]) then //  downward flow according to soil water
      // avg_Dw[i] := Dw_arr[i];

      { if (psi_neu[i-1]>(psi_neu[i]+Abst[i])) and // upward flow according to tensions
        (theta_neu[i-1] > theta_neu[i]) then //  downward flow according to soil water
        avg_Dw[i] := 0;

        if (psi_neu[i-1]<(psi_neu[i]+Abst[i])) and // downward flow according to tensions
        (theta_neu[i-1] < theta_neu[i]) then //  upward flow according to soil water
        avg_Dw[i] := 0; }



      // avg_Dw[i] := min (Dw_arr[i - 1] , Dw_arr[i]);  //
      // avg_Ku[i] := min (Ku_arr[i - 1] , Ku_arr[i]); // / 2.0;    //cm/d

      // avg_Dw[i] := (Dw_arr[i - 1] + Dw_arr[i]) / 2.0;    //cm2/d
      // avg_Ku[i] := (Ku_arr[i - 1] + Ku_arr[i]) / 2.0;    //cm/d

      // harmonic mean of conductivities
      avg_Dw[i] := sqrt(Dw_arr[i - 1] * Dw_arr[i]); // cm2/d
      avg_Ku[i] := sqrt(Ku_arr[i - 1] * Ku_arr[i]); // cm/d

    end;

    avg_ku[0] := (Wpar[1].ks+Ku_arr[1])/2;    // aritmethic mean
    avg_ku[1] := (Wpar[1].ks+Ku_arr[1])/2;    // aritmethic mean
    avg_Dw[1] := (Wpar[1].Dw_f((Wpar[1].b_sat + theta_neu[1])/2));     // aritmethic mea
    { Berechnung von Koeffizienten für die Aufstellung des Gleichungssystems,
      Abst.vektor mit dem Index i-1, weil Abstand zwischen erstem und
      zweiten Kompartiment Index 1 hat (verschobene Indizierung }

    for i := 1 to n_comp + 1 do
    begin
      { unter PWP  => keine Flüsse }   // Ratjen 20.07.17
{      if ((theta_neu[i] < PWP_Arr[i]) and (Dw_fact[i] > 0)) then
      begin
        avg_Dw[i] := 0.0;
        avg_Ku[i] := 0.0;
        Dw_fact[i] := 0.0;
        Ku_fact[i] := 0.0;
      end
      else  }
      begin
        Dw_fact[i] := avg_Dw[i] * dt.v / Dist[i - 1];
        Ku_fact[i] := avg_Ku[i] * dt.v;
      end;
      { Bei WG > Sat  => keine Flüsse }   // Ratjen
      { if ((theta_neu[i] >= WPar[i].b_sat) and (Dw_fact[i]<0)) then
        begin
        avg_Dw[i] := 0.0;
        avg_Ku[i] := 0.0;
        Dw_fact[i] := 0.0;
        Ku_fact[i] := 0.0;
        end else begin
        Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
        Ku_fact[i] := avg_Ku[i] * dt.v;
        end;
        }
    end;
  end;
  CalcTempFactor;

end;

procedure TSoilWaterMod.CalcTempFactor;

var
  TempFactor:real;
  i: integer;
begin
  if FSoilHeatModel <> nil then
  begin
    for i := 1 to n_comp + 1 do
    begin
      if FSoilHeatModel.Temp[i].v <= 1 then
      begin
          Tempfactor :=  max(0, min(1,(FSoilHeatModel.Temp[i].v+1)/2));
          avg_Ku[i] := avg_Ku[i]*Tempfactor;
          Ku_fact[i] := Ku_fact[i]*Tempfactor;
          Dw_fact[i] := Dw_fact[i]*Tempfactor;
          P[i] := P[i]*Tempfactor;
          kf[i] := kf[i]*Tempfactor;
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
  If ( (GlobTime.v > GlobMod.Starttime) and (SW_start > 0) ) then
    CalcGlobalWaterBalance;
  if ( (SW_start = 0)  and  (SumSoilWater.v > 0) )then
       SW_start:= SumSoilWater.v + PondedWater.v;
end;

procedure TSoilWaterMod.GetWaterBalance;

{ ********************************************************************** }
{ Zweck : Berechnung der Massenbilanz und der maximalen Wassergehalts-
  änderung im Simulationszeitschritt

  Parameter :

  Name             Inhalt                          Einheit      Typ
  w_rec            Record mit den Wasserdaten                    I
  ( siehe Typdefinitionen )
  geo_rec          Record mit den Geometriedaten                 I
  comps            Zahl der Kompartimente           [-]          I

  max_d_WaGe       maximale Wassergehalts„nderung   [cm3/cm3]    O }
{ ********************************************************************** }

var
  i: byte;

  net_flow, { Netto-Fluss                       [cm] }
  d_WaMe, { Aenderung der Wassermenge im Kompartiment                  [cm] }
  d_WaGe,
  { Aenderung des Wassergehaltes  im Kompartiment                  [cm3/cm3] }
  sum_d_WaMe, { Summe der Wassermengen-aenderungen                       [cm] }
  sum_sink { Summe der Sink-Terme            [cm] }

  : real;

begin
  for i := 0 to n_comp + 1 do
    SW_Balance_arr[i] := 0.0;
  MaxAktAenderWaGe := 0.0;
  sum_d_WaMe := 0.0;
  sum_sink := 0.0;
  akt_bilanz_f := 0.0;
  for i := 1 to n_comp do
  begin
    net_flow := (WflowInt_arr[i].v - WflowInt_arr[i + 1].v) * dt.v; // [cm]
    d_WaMe := (theta_arr[i].v - theta_neu[i]) * Thick[i];   //[cm]
    d_WaGe := theta_arr[i].v - theta_neu[i];
    SW_Balance_arr[i] := d_WaMe + net_flow - Sink_arr[i].v * dt.v; //[cm]
    cumSW_Balance_arr[i] := cumSW_Balance_arr[i] + SW_Balance_arr[i];
    akt_bilanz_f := akt_bilanz_f + SW_Balance_arr[i];
    if abs(d_WaGe) > MaxAktAenderWaGe then
      MaxAktAenderWaGe := abs(d_WaGe);
    sum_d_WaMe := sum_d_WaMe + d_WaMe;
    sum_sink := sum_sink + Sink_arr[i].v * dt.v;  // cm
  end;
  sum_Bilanz_f := sum_Bilanz_f + akt_bilanz_f;
end;




procedure TSoilWaterMod.adjust_dt;   // adjusting dt during iteration
  // Reset  state variable if iteration is not successfull
  // reduce time step length and increase possible water content change during iteration

var

  i: integer;

begin
  iter := iter + 1;
  total_iter := total_iter + 1;
  if ((delt_iter_max < max_IterError.v) and (iter >= 2)) then begin
    success := true;
    last_iter := 0;
    iter := 0;
    exit;
  end;

  If iter > IterMax.v then   // after maximum number of iterations no success
  begin
    for i := 1 to n_comp + 1 do
    begin
      theta_neu[i] := theta_arr[i].v;      // set back to old values
      psi_neu[i] := psi_arr[i].v;
    end;
    last_iter := iter;
    iter := 0;
  //  IterMax.v := min(1000,IterMax.v *2);  // increase allowed number of Iterations up to an allowed maximum
    max_IterError.v := max_IterError.v*2; // double the allowed water content change during one iteration

//    ResetTimeStep := true;                // set flag for change of time step
    dt.v := dt.v/10;         // reduce time step length down to a certain minimum

//    dt.v := max(dt.v/10, min_dt.v);         // reduce time step length down to a certain minimum
//    if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then begin
//      dt_old := dt.v;
//      dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
// if(last_iter > 10) then last_iter:=+1;
//      newday := true;
//      dt_set := true;
//    end;
  end; // Reset end



  //iter := 0;
end;

procedure  TSoilWaterMod.get_new_dt;

{ ********************************************************************** }
{ Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verhältnisses
  der maximal erlaubten Wassergehaltsänderung zur maximalen aktuellen
  Wassergehaltsänderung

  Parameter :

  Name             Inhalt                          Einheit      Typ

  max_aender       maximal erlaubte Änderung       [cm3/cm3]    I
  der Wassergehalte in einem
  Zeitschritt

  akt_aender       maximale Änderung des Wasser-   [cm3/cm3]    I
  gehaltes in einem Kompartiment
  im letzten Zeitschritt

  dt               Zeitschrittweite                [d]          O
  dt_alt           letzte Zeitschrittweite         [d]          O }

{ ********************************************************************** }

const
 crit_h =5;

var
  delta_t, dt_neu, dt_neu_flow, min_h: real;



begin
    dt_set := false;
    IterMax.v := Iter_Save;
    max_IterError.v := max_IterErrorsave;
    global_iter.v := global_iter.v + total_iter;
    total_iter := 0;
    if max(MaxAktAenderWaGe, NetRain.v * dt.v / (Thick[1] * 10)) <> 0.0 then
      dt_neu := (max_aenderWG.v / max(MaxAktAenderWaGe,NetRain.v * dt.v / (Thick[1] * 10)));
    dt_neu_flow := 900*max_flow_ratio;
    if dt_neu > dt_neu_flow then
      dt_neu := dt_neu_flow;
    //dt_neu := min(dt_neu, dt_neu_flow);

    if ((dt_neu > (1.5 * dt.v)) {and (dt_neu > min_dt*100)}) then
         dt_neu := dt.v * 1.5; { Zu großer Zeitschrittsprung ? }
    dt.v :=dt_neu;
    if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then begin
      dt_old := dt.v;
      dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
      newday := true;
      dt_set := true;
    end;
    dt.v := max(min_dt.v, min(Max_dt.v, dt.v));
end;



procedure TSoilWaterMod.get_delt_iter_max;
{ ********************************************************************** }
{ Zweck : Berechnung des maximalen Wassergehaltsunterschiedes in einem
  Kompartiment von einem Iterationsschritt zum nächsten }
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
      WG_diff := abs(last_iter_theta[i] - theta_neu[i]);
      delt_iter_max := max(delt_iter_max, WG_diff);
      flow_ratio[i] := abs(WflowInt_arr[i].v)*dt.v/(theta_neu[i]*Thick[i]);
      max_flow_ratio := max(max_flow_ratio, flow_ratio[i]);
    end;
  end;

end;

procedure TSoilWaterMod.CalcOverflow;


var
  i: integer;
  Overflow,
  maxstorage: real;
  layer: byte;

begin
  for i := n_comp downto start do
  begin
    if theta_neu[i] > WPar[i].b_sat then
    begin
      Overflow := (theta_neu[i] - WPar[i].b_sat) * Thick[i];    // [cm]
      // save overshooting amount of water
      theta_neu[i] := WPar[i].b_sat;
      psi_neu[i] := 0;
      WflowInt_arr[i].v := WflowInt_arr[i].v - Overflow / dt.v;   // [cm/d]
      layer := i-1; // start with the layer above the layer where overflow occurred
      repeat
        if layer >=1 then begin
         if theta_neu[layer] < WPar[layer].b_sat then begin // water capacity available?
           maxstorage := (WPar[layer].b_sat - theta_neu[layer]) * Thick[layer];    // [cm]
            // how much?
           if Overflow > maxstorage then begin // everything fits in this layer ?
             theta_neu[layer] := WPar[layer].b_sat;
             WflowInt_arr[layer].v := WflowInt_arr[layer].v - maxstorage / dt.v;
             Overflow := Overflow - maxstorage;
           end else         // all fits into this layer
            begin
              theta_neu[layer] := theta_neu[layer] + Overflow / Thick[layer];    // increase water content
              Overflow := 0.0;
            end;
          end;
          dec(layer);
        end;
      until (layer = 0) or (Overflow <= 0);
      // all overflow distributed or surface layer reached ...
      if Overflow > 0 then
       // CumRunoff.c := CumRunoff.c + Overflow * 10 * GlobTime.c;
       PondedWater.v:= PondedWater.v + Overflow * 10 * GlobTime.c;
    end;

  end;
end;

procedure TSoilWaterMod.CalcRatesAndIntegrate;

begin

  Iter_save := trunc(Itermax.v);     // save maximum iteration step number
  Exfiltration.v := Dw_arr[1] * theta_arr[1].v / (0.5 * Thick[1]) * 10;
  CalcEvap_red_f;

  // for Debugging    Act_Evap.v := 0.0;

  Act_Evap.v := Pot_Evap.v * red_evap.v;

if (uppercase(act_EvaporationOption.Option) = uppercase('inclExfiltration')) then
    Act_Evap.v := min(Act_Evap.v, Exfiltration.v);

  CalcSinks;

  if fCompMethod = Capacity then
    CapWatSolut; // Kapazitätsbasiertes Modell
  if fCompMethod = Diffusion then
    Diffwater_solut; // Potentialbasiertes Modell mit Wassergehalten
  if fCompMethod = Richards then
    Richardswater_solut; // Potentialbasiertes Modell mit Wasserspannungen
  if fCompMethod = Mixed then
    Mixedwater_solut; // Potentialbasiertes Modell mit Wasserspannungen
  if fCompMethod = MixedHydrus then
    MixedHydruswater_solut; // Potentialbasiertes Modell mit Wasserspannungen

  // Berechnung der abgeleiteten Wassergehalte für verschiedene Bodenschichten
  update_Wcont_Values;

  // CumEvap.c := CumEvap.c +
  // (-WflowInt_arr[1].v * 10 + CumNetRain.c - CumRunoff.c) * dt.v;
  CumEvap.c := CumEvap.c + Act_Evap.v * dt.v;  // [mm]
  // if WFlowInt_arr[1] was reduced because of dry, this is the new ActEvap of InternTimeStep
  CumDrainage.c := CumDrainage.c + WflowInt_arr[trunc(bil_nr.v) + 1].v* 10 * dt.v;    // [mm]
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
    { Berechnung der Wasserspannungen [cm] bei Feldkapazität bzw. beim
      permanenten Welkepunkt }
    psiWP := power(10, 4.2);
    psiFK := power(10, 1.8);

    if nFKCalcMethod = Input then
    begin

      if HoriNdx1.v = 0 then
      begin
        if ShowWarnings then
        begin

          showmessage(
            'Warning ! No specification of Indexes for hydraulic parameters');
          showmessage('Please check !');
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
  end; { Ende Initialisierungssequenz }

  dt.v := GlobTime.c;
  // bei Kapazitätswassermodell immer Zeitschritt des globalen
  // Modells

  for i := 1 to n_comp + 1 do
  begin
    theta_arr[i].v := WAmount[i].v / Thick[i];
    theta_old[i] := theta_arr[i].v;
    Wflow_old[i] := WflowInt_arr[i].v;
    WflowInt_arr[i].v := 0.0;
  end;

  WflowInt_arr[1].v := 0.1 * NetRain.v  - 0.1 * Act_Evap.v;   // upper boundary

  for i := 1 to n_comp do begin
      WCap[i] := (FK_Arr[i] - theta_arr[i].v) * Thick[i];
      if (WCap[i] < WflowInt_arr[i].v*dt.v) then begin // Saturation ?
        theta_arr[i].v := FK_Arr[i];
        WAmount[i].v := theta_arr[i].v *Thick[i];
        WflowInt_arr[i + 1].v := WflowInt_arr[i].v - WCap[i];
      end
      else begin
        WAmount[i].v := WAmount[i].v + WflowInt_arr[i].v *dt.v;
        theta_arr[i].v  := WAmount[i].v/Thick[i];
        WflowInt_arr[i + 1].v := 0.0;
      end;
  end;

  // water uptake of plant roots
  for i := 1 to n_comp do
  begin
    WAmount[i].v :=  WAmount[i].v  - Sink_arr[i].v*dt.v;
    theta_arr[i].v := WAmount[i].v/Thick[i];
    psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
  end;

  if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;



end; { procedure CapWatSolut }

{ -------------------------------------------------------------------------- }

procedure TSoilWaterMod.get_water_contents;
var
  i: byte;
begin
  for i := 1 to n_comp {+ 1} do
  begin
    theta_arr[i].v := WAmount[i].v / Thick[i];
    theta_neu[i] := theta_arr[i].v;
 //   Wflow_old[i] := avg_Dw[i] * (theta_old[i - 1] - theta_old[i])
  //        / Dist[i - 1] + avg_Ku[i];
  end;
end;

procedure TSoilWaterMod.set_new_state_vars;
{ ********************************************************************** }
{ Zweck : Umsetzen der errechneten Wassergehalte in die globale
  "state"-Variable, Errechnung der Wasserspannungen }
{ ********************************************************************** }

var
  i: byte;

begin
  for i := 1 to n_comp do
  begin
    theta_old[i] := theta_arr[i].v;
    theta_arr[i].v := theta_neu[i];
    if self.Opt_CompMethod = Diffusion then
     psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v)
    else
      psi_arr[i].v := psi_neu[i];
    WAmount[i].v := theta_arr[i].v * Thick[i];
  end;
  if LowerBoundaryCondition = FreeFlow then
  begin
    if Opt_CompMethod = Diffusion then begin
        theta_arr[n_comp + 1].v := theta_neu[n_comp];
        psi_arr[n_comp + 1].v   := WPar[n_comp].psi_b_f(theta_arr[n_comp].v);
        theta_neu[n_comp+1] := theta_arr[n_comp].v;
        WAmount[n_comp+1].v   := theta_arr[n_comp+1].v *Thick[n_comp+1];
    end else begin
      psi_arr[n_comp + 1].v := psi_arr[n_comp].v; // -Abst[n_comp];
  //    psi_arr[n_comp + 1].v := psi_arr[n_comp].v -Abst[n_comp];
      theta_arr[n_comp + 1].v := WPar[n_comp].b_psi_f(psi_arr[n_comp+1].v);
  //    theta_arr[n_comp + 1].v :=  theta_arr[n_comp].v;
      psi_neu[n_comp+1] := psi_arr[n_comp + 1].v;
      theta_neu[n_comp+1] := theta_arr[n_comp+1].v;
    end;
  end;
end;


procedure TSoilWaterMod.obere_Randbedingung;

  { zur Verhinderung von ungültigen Funktionsaufrufen wird zuerst
    eine Prüfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
    "Restwassergehalt b_rest" oder ein Ansteigen über den "Sättigungs-
    wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prüfung wird
    in den Variablen "Wet", bzw. "Dry" gespeichert. }
var
    psi_top, MaxFlow1 : real;


begin
    dry := false;
    wet := false;
    success := false;
    start := 1;

    MaxFlow1 :=  DayFlow1 + 0.1*PondedWater.v/dt.v;  // maximum possible water influx rate [cm/d]
    if MaxFlow1 > 0  then begin
        psi_top := -PondedWater.v/10; // tension including ponded water [cm]
        MaxInfil :=  2.0*avg_ku[1]*((psi_neu[1]-psi_top)/Thick[1])+avg_ku[1];
    end;

    if ( (MaxFlow1 > MaxInfil)  )then
    begin
      wet := true; { Prüfung auf Sättigung }
      WFlowInt_arr[1].v := MaxInfil;
    end;

   if (theta_neu[1] < WPar[1].b_rest) and (WflowInt_arr[1].v <= 0.0) then
      dry := true;

    if not (wet or dry ) then
    begin
//      success := true;
      B_vektor[1] := theta_arr[1].v
          + WflowInt_arr[1].v * dt.v / Thick[1]
          - Ku_fact[2] / Thick[1]
              - Sink_arr[1].v * dt.v / Thick[1];
      diag[1] := Dw_fact[2] / Thick[1] + 1.0;
      upper[1] := -Dw_fact[2] / Thick[1];
    end else
    begin
      B_vektor[1] :=
        theta_arr[1].v
        + Wpar[1].b_sat*Dw_fact[1]/Thick[1]
        + ku_fact[1] / Thick[1]
        - Ku_fact[2] / Thick[1]
        - Sink_arr[1].v * dt.v / Thick[1];
      lower[1] :=  0;
      diag[1]  :=  Dw_fact[1] / Thick[1] + Dw_fact[2] / Thick[1] + 1.0;
      upper[1] := - Dw_fact[2] / Thick[1];
   end;

end;



procedure TSoilWaterMod.Diffwater_solut;

var
  result: byte;
  i: integer;


  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      B_vektor[i] := theta_arr[i].v
                    - Ku_fact[i + 1] / Thick[i]
                    + Ku_fact[i] / Thick[i]
                    - Sink_arr[i].v * dt.v / Thick[i];
      lower[i] := -Dw_fact[i] / Thick[i];
      diag[i]  := Dw_fact[i] / Thick[i] + Dw_fact[i + 1] / Thick[i] + 1.0;
      upper[i] := -Dw_fact[i + 1] / Thick[i];
    end;
  end;

  procedure untere_Randbedingung;

  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
      { Gehalts-Randbedingungen }
      B_vektor[act_n_comp] := theta_arr[act_n_comp].v + Ku_fact[act_n_comp]
        / Thick[act_n_comp] - Ku_fact[act_n_comp + 1] / Thick[act_n_comp + 1]
        + Dw_fact[act_n_comp + 1] * theta_arr[act_n_comp + 1].v / Thick
        [act_n_comp + 1] - Sink_arr[act_n_comp].v * dt.v / Thick[act_n_comp]
    else if (LowerBoundaryCondition = NoFlow) then
      { No Flow Fluß-Randbedingung }
      B_vektor[n_comp] := theta_arr[n_comp].v + Ku_fact[n_comp] / Thick[n_comp]
        - WflowInt_arr[n_comp + 1].v / Thick[n_comp] - Sink_arr[n_comp]
        .v * dt.v / Thick[n_comp]
    else if ShowWarnings then
      showmessage('Lower Boundary not defined!');
    lower[act_n_comp] := -Dw_fact[act_n_comp] / Thick[act_n_comp];
    diag[act_n_comp] := Dw_fact[act_n_comp] / Thick[act_n_comp] + Dw_fact
      [act_n_comp + 1] / Thick[act_n_comp + 1] + 1.0;
  end;

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
  begin
    result := trdiag(false, act_n_comp, start, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then
        showmessage('Fehler beim Lösen des Gleichungssystems');
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp {+ 1} do
      begin
        last_iter_theta[i] := theta_neu[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_neu[i];
      theta_neu[i] := B_vektor[i];
      if ShowWarnings then
      begin
        if theta_neu[i] < 1E-20 then
        begin
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));
        end;
      end;
    end;
  end;

  procedure Find_flows;

  var
    GW_inflow: TSoilArray; // flows induced by increasing groundwater table
    infilbalance,PondCapa,overflow : real;
    PondDischargeRate : real;
    i: byte;
  begin
    if (LowerBoundaryCondition = ConstContent) or (LowerBoundaryCondition = FreeFlow) then
    begin
      for i := 2 to act_n_comp + 1 do
      begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i])
          / Dist[i - 1] + avg_Ku[i];
      end;
    end;

    if (LowerBoundaryCondition = Groundwatertable) then
    begin
      for i := 2 to act_n_comp + 1 do
      begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i])
          / Dist[i - 1] + avg_Ku[i];
      end;

      for i := act_n_comp + 1 to n_comp do
      begin
        GW_inflow[i + 1] := (theta_neu[i] - WPar[i].b_sat) * Thick[i] / dt.v;
        theta_neu[i] := WPar[i].b_sat;
      end;

      for i := act_n_comp + 2 to n_comp + 1 do
      begin
        WflowInt_arr[i].v := WflowInt_arr[i - 1].v + GW_inflow[i];
      end;

    if wet then begin  // inflow higher than max. infiltration, infiltration is at its maximum value
     infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
     infilbalance := infilbalance * 10 * dt.v; // change into [mm]
    if Infilbalance < 0.0 then   // more infiltration than DayFlow
       PondedWater.v := PondedWater.v+Infilbalance
     else begin   // not all water can infiltrate ...
       PondCapa := PondMax.v-PondedWater.v;  // in [mm]
       if infilbalance > PondCapa then // More water than can be stored
       begin
         overflow := (InfilBalance-PondCapa);  // [mm]
         PondedWater.v := PondMax.v;
         CumRunoff.c := CumRunoff.c + overflow;
       end else // soil surface is wet, max. infiltration but excess water is stored as ponded water
       begin
         PondedWater.v := PondedWater.v + infilbalance;  // [mm]
       end;
      end;

    end;

    end;

    if not(wet) and (PondedWater.v > 0) then     // discharge of ponded water possible
    begin
      PondDischargeRate :=  MaxInfil-DayFlow1;
      PondedWater.v   := max(0, PondedWater.v - 10*PondDischargeRate*dt.v);
    end;

  end;

begin { procedure Diffwater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  iter := 0;
  repeat
    CalcConductivities;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
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
  i: integer;
  psi_top,  MaxFlow1,

  ExcessWater : real;

  procedure Leitfaehigkeiten;

  var
    i: byte;

  begin

    for i := 1 to n_comp + 1 do
    begin
      c_arr[i] := WPar[i].C_psi_f(psi_neu[i]);
      Ku_arr[i] := WPar[i].Ku_b_f(theta_neu[i]);
    end;

    for i := 1 to n_comp do
    begin
      avg_Ku[i] := (Ku_arr[i] { *upper_w_f[i] } + Ku_arr[i + 1]
        { *lower_w_f[i] } ) / 2;
    end;
//    avg_ku[0] := sqrt(Wpar[1].ks*Ku_arr[1]);  // geometric mean
    avg_ku[0] := (Wpar[1].ks+Ku_arr[1])/2;    // aritmethic mean

    { Berechnung von Koeffizienten fr die Aufstellung des Gleichungssystems }
    for i := 1 to n_comp do
    begin
      if c_arr[i] >= 0.0 then { Tritt S„ttigung auf ? }
        P[i] := 0.0 { => keine weitere Änderung der Wassergehalte }
      else
        P[i] := dt.v / (c_arr[i] * Thick[i]);
      kf[i] := avg_Ku[i] / Dist[i];
    end;
    kf[0] := 2*avg_Ku[0]/Dist[1];
    for i := 1 to n_comp do
    if psi_neu[i] > 10 then
       wf[i] := 1
    else
      wf[i] := min(1.0,max(0,(psi_neu[i])/(10-1)));
    //  wf[1] := 1.0;

   for i := 1 to n_comp do
       wf[i] := 1 ;


    { Berechnung der Koeffizienten für die Aufstellung des Gleichungssystems }

    if FSoilHeatModel <> nil then
    begin
      for i := 1 to n_comp + 1 do
      begin
        if FSoilHeatModel.Temp[i].v <= 0 then
        begin
         // avg_Ku[i] := 0.0;
         // Ku_fact[i] := 0.0;
          //P[i] := 0.0;
         // kf[i] := 0.0;
        end;
      end;
    end;
  end;

  procedure obere_Randbedingung;

  var
    est_theta_1: real;
    ExcessWater: real;
    psi_top1
   : real;
    i: integer;

    { zur Verhinderung von ungültigen Funktionsaufrufen wird zuerst
      eine Prüfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
      "Restwassergehalt b_rest" oder ein Ansteigen ber den "Sättigungs-
      wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prüfung wird
      in den Variablen "Wet", bzw. "Dry" gespeichert. }
  begin
//    est_theta_1 := WPar[1].b_psi_f(psi_neu[1]) + (NetRain.v -Sink_arr[1].v) * dt.v / Dicke[1];
//    est_theta_1 := WPar[1].b_psi_f(psi_arr[1].v) + (NetRain.v*10 -Sink_arr[1].v) * dt.v / Dicke[1]-
//                   WFlowInt_arr[2].v*dt.v/Dicke[1];
//    if (est_theta_1 < theta_airdryness) then begin

  dry := false;
  wet := false;
  start := 1;

  MaxFlow1 :=  DayFlow1 + 0.1*PondedWater.v/dt.v;  // maximum possible water influx rate [cm/d]

  if MaxFlow1 > 0  then begin
      psi_top := -PondedWater.v/10; // tension including ponded water [cm]
//      MaxInfil :=  avg_ku[0];     // without tension induced flux
      MaxInfil :=  2.0*avg_ku[0]*((psi_neu[1]-psi_top)/Thick[1])+avg_ku[0];
      if MaxFlow1 > MaxInfil then begin
        wet := true;
        WFlowInt_arr[1].v := MaxInfil;
      end;
  end;

  if (psi_neu[1] > PsiAirDryness) then begin
      dry := true;
      psi_top := PsiAirDryness;
  end;

   if not (wet or dry ) then  //  Wassergehalte im erlaubten Rahmen
      begin
         start := 1;
         B_vektor[1] := psi_arr[1].v
                        + MaxFlow1 * P[1]  // known Influx
                        - avg_Ku[1] * P[1]          // drainage to second layer
                       - Sink_arr[1].v * P[1];      // water uptake by plants
         diag[1] := -wf[1]*kf[1] * P[1] + 1;              // tension flow to second layer
         upper[1] := wf[1]*kf[1] * P[1];
         WFlowInt_Arr[1].v := MaxFlow1;
         exit;
      end
    else begin    // fixed tension on soil surface
      B_vektor[1] := psi_neu[1]
                     + psi_top*kf[0]* P[1]*2  // tension infiltration rate
                     + avg_Ku[0]*P[1]         // gravitational infiltration
                     - avg_Ku[1] * P[1]       // gravitation flow to second layer
                     - Sink_arr[1].v * P[1];   // water uptake by plants

      diag[1] := -ku_arr[1]/Dist[1]*2*P[1]    // tension induced flow into first layer
                 -wf[1]*kf[1] * P[1] + 1;           // tension outflow to second layer
      upper[1] := wf[1]*kf[1] * P[1];
    end;

 end;

  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      B_vektor[i] := psi_arr[i].v + P[i] * (avg_Ku[i - 1] - avg_Ku[i])
        - Sink_arr[i].v * P[i];
      if wf[i] >= 1 then begin
        lower[i] := kf[i - 1] * P[i];
        diag[i]  := -kf[i - 1] * P[i] - kf[i] * P[i] + 1;
        upper[i] := kf[i] * P[i];
 //       wf[i] := 1.0;
      end
      else begin
        lower[i] := wf[i]*kf[i - 1] * P[i];
        diag[i]  := wf[i]*-kf[i - 1] * P[i] - wf[i] * kf[i] * P[i] + 1;
        upper[i] := kf[i] * P[i];

        lower[i-1] := wf[i-1]*kf[i - 2] * P[i-1];
        diag[i-1]  := -wf[i] * kf[i - 2] * P[i-1] - wf[i]*kf[i-1] * P[i-1] + 1;
        upper[i-1] := wf[i]*kf[i-1] * P[i-1];
      end;

    end;
  end;

  procedure untere_Randbedingung;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      B_vektor[n_comp] := psi_arr[n_comp].v
                         + P[n_comp] * (avg_Ku[n_comp - 1] - avg_Ku[n_comp])
                         - wf[n_comp]*psi_arr[n_comp + 1].v * kf[n_comp] * P[n_comp]
                         - Sink_arr[n_comp].v * P[n_comp];
    end
    else if (LowerBoundaryCondition = NoFlow) then
    begin
      { No Flow Fluß-Randbedingung }

      B_vektor[n_comp] := psi_arr[n_comp].v + P[n_comp] * (avg_Ku[n_comp - 1])
        - Sink_arr[n_comp].v * P[n_comp];

    end
    else if ShowWarnings then
      showmessage('Lower Boundary not defined!');

    lower[n_comp] := wf[n_comp] * kf[n_comp - 1] * P[n_comp];
    diag[n_comp] := -wf[n_comp] * P[n_comp] * kf[n_comp - 1] - wf[n_comp]*P[n_comp] * kf[n_comp] + 1;

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
    result := trdiag(false, act_n_comp, start, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then
        showmessage('Fehler beim Lösen des Gleichungssystems');
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp {+ 1} do
      begin
        last_iter_theta[i] := theta_neu[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_neu[i];
//      psi_neu[i] := max(0, B_vektor[i]);
      psi_neu[i] := max(0, B_vektor[i]);
      c := WPar[i].C_psi_f(psi_neu[i]);
      theta_neu[i] := theta_arr[i].v + c * (psi_neu[i] - psi_arr[i].v);
      if ShowWarnings then
      begin
        if theta_neu[i] < 1E-20 then
        begin
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));
        end;
      end;
    end;
  end;

  procedure Find_flows;
  var
    i: byte;
    overflow, inflow, infilbalance : real;
    PondCapa,
    PondDischargeRate : real;
  begin
    for i := 2 to n_comp + 1 do
      WflowInt_arr[i].v := wf[i]*avg_Ku[i - 1] *
        ((psi_neu[i] - psi_neu[i - 1]) / Dist[i - 1] ) + avg_ku[i-1];

    if wet then begin  // inflow higher than max. infiltration, infiltration is at its maximum value
     infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
     infilbalance := infilbalance * 10 * dt.v; // change into [mm]
     if Infilbalance < 0.0 then   // more infiltration than DayFlow
       PondedWater.v := PondedWater.v+Infilbalance
     else begin   // not all water can infiltrate ...
       PondCapa := PondMax.v-PondedWater.v;  // in [mm]
       if infilbalance > PondCapa then // More water than can be stored
       begin
         overflow := (InfilBalance-PondCapa);  // [mm]
         PondedWater.v := PondMax.v;
         CumRunoff.c := CumRunoff.c + overflow;
       end else // soil surface is wet, max. infiltration but excess water is stored as ponded water
       begin
         PondedWater.v := PondedWater.v + infilbalance;  // [mm]
       end;
      end;
    end;

    if not(wet) and (PondedWater.v > 0) then     // discharge of ponded water possible
    begin
      PondDischargeRate :=  MaxFlow1-DayFlow1;
      PondedWater.v   := max(0, PondedWater.v - 10*PondDischargeRate*dt.v);
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
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
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

  procedure Leitfaehigkeiten;

  var
    i: byte;

  begin

    for i := 1 to n_comp + 1 do
    begin
      c_arr[i] := WPar[i].C_psi_f(psi_neu[i]);
      Ku_arr[i] := WPar[i].Ku_b_f(theta_neu[i]);
    end;

    for i := 1 to n_comp do
    begin
      // avg_Ku[i] := (Ku_arr[i] {*upper_w_f[i]} + Ku_arr[i + 1] {*lower_w_f[i]}) / 2;
      avg_Ku[i] := sqrt(Ku_arr[i] * Ku_arr[i + 1]);
    end;

    if FSoilHeatModel <> nil then
    begin
      for i := 1 to n_comp + 1 do
      begin
        if FSoilHeatModel.Temp[i].v <= 0 then
        begin
          avg_Ku[i] := 0.0;
          Ku_fact[i] := 0.0;
          //P[i] := 0.0;
          kf[i] := 0.0;
        end;
      end;
    end;
  end;

  procedure obere_Randbedingung;

  const
    AirDryness = 20000;

  var
    est_theta_1: real;


    { zur Verhinderung von ungültigen Funktionsaufrufen wird zuerst
      eine Prüfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
      "Restwassergehalt b_rest" oder ein Ansteigen ber den "Sättigungs-
      wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prüfung wird
      in den Variablen "Wet", bzw. "Dry" gespeichert. }
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
      - (theta_neu[1] - theta_arr[1].v) / dt.v // soil water change
      - Sink_arr[1].v / (Thick[1]); // sink
    alpha[1] := 0.0;
    beta[1] := c_arr[1] / dt.v + (avg_Ku[1]) / (Dist[1] * Thick[1]);
    gamma[1] := -avg_Ku[1] / (Dist[1] * Thick[1]);
  end;

  procedure Mittelteil;
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
        - (theta_neu[i] - theta_arr[i].v) / dt.v // soil water change
        - Sink_arr[i].v / (Thick[i]); // sink term
      alpha[i] := -avg_Ku[i - 1] / (Dist[i] * Thick[i]);
      beta[i] := c_arr[i] / dt.v + (avg_Ku[i - 1] + avg_Ku[i]) /
        (Dist[i] * Thick[i]);
      gamma[i] := -avg_Ku[i] / (Dist[i] * Thick[i]);
    end;
  end;

  procedure untere_Randbedingung;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      Res[n_comp] := avg_Ku[n_comp - 1] / (Thick[n_comp] * Dist[n_comp]) *
        (psi_arr[n_comp].v - psi_arr[n_comp - 1].v) - avg_Ku[n_comp] /
        (Thick[n_comp] * Dist[n_comp + 1]) *
        (psi_arr[n_comp + 1].v - psi_arr[n_comp].v) +
        (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) / Thick[n_comp] -
        (theta_neu[n_comp] - theta_arr[n_comp].v) / dt.v - Sink_arr[n_comp]
        .v / (Thick[n_comp]);
    end
    else if (LowerBoundaryCondition = NoFlow) then
    begin
      // No Flow Fluß-Randbedingung }

      Res[n_comp] := avg_Ku[n_comp - 1] / (Thick[n_comp] * Dist[n_comp]) *
        (psi_arr[n_comp].v - psi_arr[n_comp - 1].v) // inflow from upper layer
        + (avg_Ku[n_comp - 1]) / Thick[n_comp]
      // gravitational flow into the layer
        - (theta_neu[n_comp] - theta_arr[n_comp].v) / dt.v // soil water change
        - Sink_arr[n_comp].v / (Thick[n_comp]);

    end
    else if ShowWarnings then
      showmessage('Lower Boundary not defined!');

    alpha[n_comp] := -avg_Ku[n_comp - 1] / (Dist[n_comp] * Thick[n_comp]);
    beta[n_comp] := c_arr[n_comp] / dt.v +
      (avg_Ku[n_comp - 1] + avg_Ku[n_comp]) / (Dist[n_comp] * Thick[n_comp]);
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
        showmessage('Fehler beim Lösen des Gleichungssystems');
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp + 1 do
      begin
        last_iter_theta[i] := theta_neu[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_neu[i];
      { Umsetzen der berechneten Spannungen }
      psi_neu[i] := max(0, psi_neu[i] + Res[i]);
      // Neue Wassergehalte aus Ableitung
      theta_neu[i] := WPar[i].b_psi_f(psi_neu[i]);
      if ShowWarnings then
      begin
        if theta_neu[i] < 1E-20 then
        begin
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));
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
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
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
  psi_top,  MaxFlow1 : real;


procedure Leitfaehigkeiten;

  var
    i: byte;

  begin
    for i := 1 to n_comp + 1 do
    begin
      c_arr[i] := WPar[i].C_psi_f(psi_neu[i]);
      Ku_arr[i] := WPar[i].Ku_psi_f(psi_neu[i]);
    end;

    avg_ku[0] := (Wpar[1].ks+Ku_arr[1])/2;    // aritmethic mean
    for i := 1 to n_comp do
    begin
      // avg_Ku[i] := (Ku_arr[i] {*upper_w_f[i]} + Ku_arr[i + 1] {*lower_w_f[i]}) / 2;
      avg_Ku[i] := sqrt(Ku_arr[i] * Ku_arr[i + 1]);
      kf[i] := avg_Ku[i] / Dist[i];
      P[i] := (c_arr[i] * Thick[i]) / dt.v;
    end;

    kf[0] := 2*avg_Ku[0]/Dist[1];
//    for i := 1 to n_comp do
//    if psi_neu[i] > 10 then
//       wf[i] := 1
//    else
//      wf[i] := min(1.0,max(0,(psi_neu[i])/(10-1)));
    //  wf[1] := 1.0;

   for i := 0 to n_comp+1 do
       wf[i] := 1 ;


 {   if FSoilHeatModel <> nil then
    begin
      for i := 1 to n_comp + 1 do
      begin
        if FSoilHeatModel.Temp[i].v <= 0 then
        begin
          avg_Ku[i] := 0.0;
          Ku_fact[i] := 0.0;
          // p[i] := 0.0;
          kf[i] := 0.0;
        end;
      end;
    end; }
  end;




  procedure obere_Randbedingung;

  const
    AirDryness = 20000;

  var
    est_theta_1: real;
    ExcessWater: real;
    psi_top1 : real;
    i: integer;

    { zur Verhinderung von ungültigen Funktionsaufrufen wird zuerst
      eine Prüfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
      "Restwassergehalt b_rest" oder ein Ansteigen ber den "Sättigungs-
      wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prüfung wird
      in den Variablen "Wet", bzw. "Dry" gespeichert. }

  begin
    // est_theta_1 := WPar[1].b_psi_f(psi_arr[1].v) + NetRain.v * dt.v/dicke[1];
    // theta_airdryness := WPar[1].b_psi_f(Airdryness);
    // if (est_theta_1 > theta_airdryness  { AirDryness } ) { and (psi_arr[1].v> 1) } then
    // begin
    { Wasserspannungen im erlaubten Rahmen ? }
    start := 1;
    dry := false;
    wet := false;


    MaxFlow1 :=  DayFlow1 + 0.1*PondedWater.v/dt.v;  // maximum possible water influx rate [cm/d]

    if MaxFlow1 > 0  then begin
        psi_top := -PondedWater.v/10; // tension including ponded water [cm]
  //      MaxInfil :=  avg_ku[0];     // without tension induced flux
        MaxInfil :=  2.0*avg_ku[0]*((psi_neu[1]-psi_top)/Thick[1])+avg_ku[0];
        if MaxFlow1 > MaxInfil then begin
          wet := true;
          WFlowInt_arr[1].v := MaxInfil;
        end;
    end;
  if (psi_neu[1] > PsiAirDryness) then begin
      dry := true;
      psi_top := PsiAirDryness;
  end;


  if not (wet or dry ) then  //  Wassergehalte im erlaubten Rahmen
      begin

        Res[1] := psi_neu[1] * P[1] + MaxFlow1 // Fluxcondition, known
                  - avg_Ku[1] // gravitational flow induced to second layer
                  - (theta_neu[1] - theta_arr[1].v) * Thick[1] / dt.v // soil water change
                  - Sink_arr[1].v; // sink
        alpha[1] := 0.0;
        beta[1] := P[1] - kf[1];
        gamma[1] := kf[1];

      end
    else begin    // fixed tension on soil surface

      Res[1] := psi_neu[1] * P[1]
                + avg_Ku[0] - avg_Ku[1]  // gravitational flows
                + psi_top*kf[0]
                - (theta_neu[1] - theta_arr[1].v) * Thick[1] / dt.v // soil water change
                - Sink_arr[1].v; // sink term
      alpha[1] := kf[1 - 1];
      beta[1] := P[1] - kf[1];
      gamma[1] := kf[1];
   end;
  end;

  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      Res[i] := psi_neu[i] * P[i]
               + avg_Ku[i - 1]
               - avg_Ku[i]  // gravitational flows
        - (theta_neu[i] - theta_arr[i].v) * Thick[i] / dt.v // soil water change
        - Sink_arr[i].v; // sink term
      alpha[i] := kf[i - 1];
      beta[i] := P[i] - kf[i - 1] - kf[i];
      gamma[i] := kf[i];
    end;
  end;

  procedure untere_Randbedingung;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (LowerBoundaryCondition = ConstContent) or (LowerBoundaryCondition = Groundwatertable) or
      (LowerBoundaryCondition = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      Res[n_comp] := psi_neu[n_comp] * P[n_comp]
                    + avg_Ku[n_comp - 1]  // gravitational inflow
                    - avg_Ku[n_comp]      // gravitational outflow
                    - kf[n_comp] * psi_neu[n_comp + 1] // tension induce flow to bottom layer
                    -(theta_neu[n_comp] - theta_arr[n_comp].v)*Thick[n_comp]/dt.v  // water balance term
                    - Sink_arr[n_comp].v;

      beta[n_comp] := P[n_comp]
                    - kf[n_comp - 1] // tension induced inflow from upper layer
                    - kf[n_comp];    // tension induce i


    end
    else if (LowerBoundaryCondition = NoFlow) then
    begin
      // No Flow Fluß-Randbedingung }
      Res[n_comp] := psi_neu[n_comp] * P[n_comp]
                   + avg_Ku[n_comp - 1]
                   -(theta_neu[n_comp] - theta_arr[n_comp].v)*Thick[n_comp]/dt.v
                   - Sink_arr[n_comp].v;
      beta[n_comp] := P[n_comp] - kf[n_comp - 1];

    end
    else if ShowWarnings then
      showmessage('Lower Boundary not defined!');

    alpha[n_comp] := kf[n_comp - 1];
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
        showmessage('Fehler beim Lösen des Gleichungssystems');
    if (LowerBoundaryCondition = Groundwatertable) then
      for i := n_comp downto act_n_comp {+ 1} do
      begin
        last_iter_theta[i] := theta_neu[i];
      end;
    for i := act_n_comp downto start do
    begin
      last_iter_theta[i] := theta_neu[i];
      { Umsetzen der berechneten Spannungen }
      psi_neu[i] := max(0,Res[i]);     // ggf. weiter prüfen ob eine Nullsetzung notwendig ist ...
      // Neue Wassergehalte aus Ableitung
      theta_neu[i] := WPar[i].b_psi_f(psi_neu[i]);
      if ShowWarnings then
      begin
        if theta_neu[i] < 1E-20 then
        begin
          showmessage('Fehler: WMenge_' + IntTostr(i) + ' = 0');
          showmessage('Datum: ' + floattostr(GlobTime.v));
        end;
      end;
    end;
//    if self.Untere_Randb = FreeFlow then begin
//      psi_neu[act_n_comp+1] := max(0, psi_neu[act_n_comp]);//-Abst[n_comp+1];
//      psi_neu[act_n_comp+1] := max(0,psi_neu[act_n_comp] - Abst[n_comp+1]);
//      theta_neu[act_n_comp+1] := Wpar[n_comp+1].b_psi_f(psi_neu[n_comp]);
//    end;

  end;

  procedure Find_flows;
  var
    i: byte;
    overflow, inflow, infilbalance : real;
    PondCapa,
    PondDischargeRate : real;
    GW_inflow: TSoilArray; // flows induced by increasing groundwater table
  begin
    for i := 2 to n_comp + 1 do
      WflowInt_arr[i].v := wf[i]*avg_Ku[i - 1] *
        ((psi_neu[i] - psi_neu[i - 1]) / Dist[i - 1] ) + avg_ku[i-1];

    if wet then begin  // inflow higher than max. infiltration, infiltration is at its maximum value
     infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
     infilbalance := infilbalance * 10 * dt.v; // change into [mm]
     if Infilbalance < 0.0 then   // more infiltration than DayFlow
       PondedWater.v := PondedWater.v+Infilbalance
     else begin   // not all water can infiltrate ...
       PondCapa := PondMax.v-PondedWater.v;  // in [mm]
       if infilbalance > PondCapa then // More water than can be stored
       begin
         overflow := (InfilBalance-PondCapa);  // [mm]
         PondedWater.v := PondMax.v;
         CumRunoff.c := CumRunoff.c + overflow;
       end else // soil surface is wet, max. infiltration but excess water is stored as ponded water
       begin
         PondedWater.v := PondedWater.v + infilbalance;  // [mm]
       end;
      end;
    end;

    if not(wet) and (PondedWater.v > 0) then     // discharge of ponded water possible
    begin
      PondDischargeRate :=  MaxFlow1-DayFlow1;
      PondedWater.v   := max(0, PondedWater.v - 10*PondDischargeRate*dt.v);
    end;

    if LowerBoundaryCondition = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;
    if (LowerBoundaryCondition = Groundwatertable) then
    begin

      for i := act_n_comp + 1 to n_comp do
      begin
        GW_inflow[i + 1] := (theta_neu[i] - WPar[i].b_sat) * Thick[i] / dt.v;
        theta_neu[i] := WPar[i].b_sat;
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
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
    adjust_dt;
  until (success);
  Find_flows;
//  calcoverflow;
  GetWaterBalance;
  set_new_state_vars;
end;
{ -------------------------------------------------------------------------- }

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterMod]);
end;

end.


