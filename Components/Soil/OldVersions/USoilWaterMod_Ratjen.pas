unit USoilWaterMod; { Stand 19.4.09, Grundwasser eingebaut - Ulf Böttcher }

interface

uses
  UMod, IniFilesNew, UState, ULayeredSoil, UGenucht, classes, UAbstractSoilHeat,
  UAbstractPlant, USoilTexture, Forms, Chart, Series;

const

  dWg = 0.0; // 1E-8;     /// delta for changing water contents
  PsiAirDryness = 20000;


type
  TVGParsFromTexture = (FromPar, FromTexture);
  // TTexture_version = (RR, KA);
  TKsFromTexture = TVGParsFromTexture;
  Tact_Evaporation = (red_f, inclExfiltration);
  Tm_model = (Mualem, Burdine, Vereecken);
  /// type of model for calculating the parameter 'm' within the van Genuchten model
  TLowerBoundaryCondition = (NoFlow, FreeFlow, ConstContent, Groundwatertable);
  /// type for specifying lower boundary conditions
  TCompMethod = (Capacity, Diffusion, Richards, Mixed, MixedHydrus);
  /// type for specifying computation method
  TnFKCalcMethod = (FromParameter, Input);
  /// type for specifying computation method for nFK
  TIniMethod = (Watercontents, Potentials, Parameter);
  /// type for initialization method
  Tred_f = (modifiedBeese, Beese1978);
  /// Type of soil evaporation reduction function
  TSoilWaterParams = array [1 .. max_comp] of TGenucht;
  /// Type for soil water parameters

  TSoilWaterMod = class(TLayeredSoil)
  /// Component implementing vertical soil water transport

  private
    flag_cascadic: boolean;
    /// flag for not run FindFlows
    ResetTimeStep: boolean;
    /// flag for resetting time step
    NewDay: boolean;
    /// flag for start of a new day
    last_iter: integer;
    /// number of iterations during previous internal time step
    total_iter: integer; // total number of iterations during internal time step
    delt_iter_max: real;
    /// maximum water content change within a single layer during an internal time step
    theta_airdryness: real;  /// lower limit to soil water content [cm3/cm3]
    IterMax: real;
    min_dt: real;
    DayFlow1 : real;  // upper flow rate, constant over one day  [cm/d]
    CumDayFlow1 : real; // cumulative flow into layer 1 over the day [cm/d]
    oldrunoff : real; /// for saving old runoff rate value
    MaxInfil : real; /// maximum infiltration rate
    start: byte;
    /// number of layer where solution of equation system starts, mostly the first sometimes the second ..
    wet: boolean;
    /// Sättigung im obersten Kompartiment ?
    dry: boolean;
    /// Wassergehalt kleiner b_rest im obersten Komp.?
    success: boolean;
    /// solution converged
    dt_set: boolean;
    /// was dt set during act. iteration

    fCompMethod: TCompMethod;
    /// Enumeration type variable for computation method
    fShowWarnings: boolean;
    /// Switch for put Warnings on and off
    FVGParsFromTexture: TVGParsFromTexture;
    Texture_version: TTexture_version;
    FKsFromTexture: TKsFromTexture;
    FTextureClass1,
    { Bodenart in Horizont 1 bei TVGParsFromTexture = FromTexture }
    FTextureClass2, FTextureClass3, FTextureClass4: TTextureClass;
    fm_model: Tm_model;
    /// type of m_model used
    fred_f: Tred_f;
    /// Option for soil evaporation reduction function
    dt_alt,
    /// alte Zeitschrittweite [d]
    MaxAktAenderWaGe : real;
    /// maximale Wassergehaltsänderung

    ndx_Weff: integer;
    /// index of layer where maximum Weff is reached

    Dw_arr,
    /// Diffusivitäten [cm2/d] }
    c_arr,
    /// specific water capacity
    P,
    /// intermediate variable dt.v/(C_arr*??)
    kf,
    /// saturated hydraulic conductivities [cm/d]
    Ku_arr,
    /// ungesättigte hydraulische Leitfähigkeiten [cm/d] }
    avg_Dw,
    /// Mittelwert der Diffusivität zwischen 2 Kompartimenten [cm2/d] }
    avg_Ku,
    /// Mittelwert der unges„ttigten hydr. Leitfähigkeit zwischen 2 Kompartimenten [cm/d] }
    Dw_fact,
    /// Intermediate variable
    Ku_fact,
    /// Intermediate variable
    B_vektor,
    /// Intermediate variable, known values and solution vektor
    lower,
    /// lower vector of the tri-diagonal matrix
    diag,
    /// central vector of the tri-diagonal matrix
    upper,
    /// upper vector of the tri-diagonal matrix
    last_iter_theta,
    /// Wassergehalte bei der letzten Iteration [cm3/cm3 }
    est_theta,
    wf  /// factor for calculation of flows in cases of near saturation
    : TSoilArray;

    PSI_dummy: TVAR;
    /// dummy to set array settings

    IniMethod: TIniMethod;
    /// Enumeration type variable for initialisation method
    nFKCalcMethod: TnFKCalcMethod;
    ///
    fWeffOpt: TSource;
    /// Source of Weff

    FSoilHeatModel: TAbstractSoilHeat;
    /// Link to soil temperature model
    fTransferWGs: boolean;
    /// Option, if true water contents are written into the next state ini-File of the control file
    alpha, beta, gamma, Res: TSoilArray;

    procedure Leitfaehigkeiten;
    procedure CapWatSolut;
    procedure get_water_contents;
    procedure Diffwater_solut;
    procedure Richardswater_solut;
    procedure Mixedwater_solut;
    procedure MixedHydruswater_solut;

    procedure get_bilanz;
    /// Calculation of soil water balance
    procedure get_new_dt;
    /// Calculation of new internal time step width
    procedure get_delt_iter_max;
    /// Calculation of maximal water content change within an internal time step
    procedure set_new_state_vars;
    /// setting up the new state vars
    procedure calcoverflow;
    /// calculation of runoff
    procedure cascadic;
    /// rescue method if diffwater_solut failed
    function getNetRain: TExternV;
    function getPot_Evap: TExternV;

  protected
    Untere_Randb: TLowerBoundaryCondition;

    act_n_comp: integer;
    /// actual number of layers to be calculated, variable in case of groundwater influence
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override;
    function ndx_str(i: integer): string;
    function getTexture(i: integer): TTextureClass;

  public
    iter: integer;
    /// number of iterations during internal time step
    ///
    akt_bilanz_f, sum_Bilanz_f: real;
    SW_start, global_WaterBalance, old_global_WaterBalance: real;
    theta_arr: TSoilvarArray;
    /// Wassergehaltsvektor [cm3/cm3]
    theta_neu: TSoilArray;
    /// new soil water contents
    WMenge: TSoilStateArray;
    /// Wassermenge je Schicht [cm]
    psi_arr: TSoilvarArray;
    /// Wasserspannungsvektor [cm]
    Wflow_arr: TSoilvarArray;
    /// Flussvektor [cm/d]
    WflowInt_arr: TSoilvarArray;
    /// Flussvektor [cm/d] für internen Zeitschritt
    Sink_arr: TSoilvarArray;
    /// Sinkvektor [cm]
    SinkInt_arr: TSoilvarArray;
    /// Sinkvektor [cm/d] für internen Zeitschritt
    FK_Arr: TSoilArray;
    /// Feldkapazität [cm3/cm3]
    PWP_Arr: TSoilArray;
    /// permanenter Welkepunkt [cm3/cm3]
    nFK_Arr: TSoilArray;
    /// nutzbare Feldkapazität [cm3/cm3]
    WPar: TSoilWaterParams;
    /// Array der Van-Genuchten Parameter für jede Schicht

    Wflow_alt: TSoilArray;
    /// alte Wasserflüsse [cm/d]
    theta_alt: TSoilArray;
    /// alte Wassergehalte
    psi_neu: TSoilArray;
    /// New estimate of water potential [cm]
    Bilanz_f_arr: TSoilArray; /// actual values of water balance for single layers
    cumBilanz_f_arr: TSoilArray; /// cumulative values of water balance for single layers

    HoriNdx1, HoriNdx2, HoriNdx3, HoriNdx4: TPar;
    /// Index der untersten Schicht im jeweiligen Horizont

    FVGParsFromTextOption: TOption;
    // Texture_versionOption: TOption;
    FKsFromTextOption: TOption;
    act_EvaporationOption: TOption;
    red_fOption: TOption;

    OptUntere_Randb: TOption;
    /// / lowerBoundCond
    OptIniMethod: TOption;
    /// Option for choosing the initialisaiton method
    OptCompMethod: TOption;
    /// Option for choosing the computation method

    Groundwaterdepth: TExternV;
    /// depth of groundwatertable [cm] needed if option is selected

    FTextClass1Option, FTextClass2Option, FTextClass3Option,
      FTextClass4Option: TTextClassOption;
    /// Options for choosing Parameters for 4 distinct horizons

    max_aenderWG: TPar;
    /// maximale Wassergehaltsänderung pro Zeitschritt
    max_IterError: TPar;
    /// maximum change of water content in a layer between two iterations
    ///

    Max_dt: TPar;
    /// maximum internal time step

    bsat_scaling: TPar;
    /// Parameter for linear scaling of soil hydraulic Parameter bsat
    alpha_scaling: TPar;
    /// Parameter for linear scaling of soil hydraulic Parameter alpha

    /// van-Genuchten Parameter fuer Horizont 1
    b_sat1: TPar;
    /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest1: TPar;
    /// "Restwassergehalt" [cm3/cm3] }
    alpha1: TPar;
    /// Fitparameter "" [1/cm] }
    n_par1: TPar;
    /// Fitparameter "n" dimensionslos }
    Ks1: TPar;
    /// gesättigte Leitfähigkeit [cm.d-1]
    FK1: TPar;
    /// Feldkapazität [cm3/cm3]
    PWP1: TPar;
    /// permanenter Welkepunkt
    nFK1: TPar;
    /// nutzbare Feldkapazität

    /// van-Genuchten Parameter fuer Horizont 2
    b_sat2: TPar;
    /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest2: TPar;
    /// "Restwassergehalt" [cm3/cm3] }
    alpha2: TPar;
    /// Fitparameter "" [1/cm] }
    n_par2: TPar;
    /// Fitparameter "n" dimensionslos }
    Ks2: TPar;
    /// gesättigte Leitfähigkeit [cm.d-1]
    FK2: TPar;
    /// Feldkapazität [cm3/cm3]
    PWP2: TPar;
    /// permanenter Welkepunkt
    nFK2: TPar;
    /// nutzbare Feldkapazität

    /// van-Genuchten Parameter fuer Horizont 3
    b_sat3: TPar;
    /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest3: TPar;
    /// "Restwassergehalt" [cm3/cm3] }
    alpha3: TPar;
    /// Fitparameter "" [1/cm] }
    n_par3: TPar;
    /// Fitparameter "n" dimensionslos }
    Ks3: TPar;
    /// gesättigte Leitfähigkeit [cm.d-1]
    FK3: TPar;
    /// Feldkapazität [cm3/cm3]
    PWP3: TPar;
    /// permanenter Welkepunkt
    nFK3: TPar;
    /// nutzbare Feldkapazität

    /// van-Genuchten Parameter fuer Horizont 4
    b_sat4: TPar;
    /// Wassergehalt bei Sättigung [cm3/cm3] }
    b_rest4: TPar;
    /// "Restwassergehalt" [cm3/cm3] }
    alpha4: TPar;
    /// Fitparameter "" [1/cm] }
    n_par4: TPar;
    /// Fitparameter "n" dimensionslos }
    Ks4: TPar;
    /// gesättigte Leitfähigkeit [cm.d-1]
    FK4: TPar;
    /// Feldkapazität [cm3/cm3]
    PWP4: TPar;
    /// permanenter Welkepunkt
    nFK4: TPar;
    /// nutzbare Feldkapazität

    PsiStart1: TPar;
    /// For initalisation of Soil water contents and suction values

    bil_nr: TPar;
    /// Index of Layer where lower boundary fluxes are calculated
    Weff: TPar;
    /// effective rooting deph [cm]

    psi_critEvap: TPar;
    /// Wasserspannung ab der Evaporation abnimmt [hPa]

    NetRain: TExternV;
    /// NetRain = Niederschlag - Interzeption
    // THumeNumEntity;              ///  NetRain = Niederschlag - Interzeption
    CumNetRain: TState;
    /// kumulativer Niederschlag [mm]
    Pot_Evap: THumeNumEntity;
    /// potentielle Evaporationsrate

    red_evap: TVAR;
    /// Reduktionsfaktor für Evaporation
    Act_Evap: TVAR;
    /// aktuelle Evaporationsrate
    Exfiltration: TVAR;
    /// Estimation of maximum exfiltration rate
    //CumTrans : TState;       /// kumulative Transpiration [mm]
    CumEvap: TState;
    /// kumulative Evaporation
    CumDrainage: TState;
    /// kumulative Sickerwasserspende/kapillarer Aufstieg [mm]
    CumWaterBalance: TState;
    CumAbsWaterBalance: TState;
    CumGlobalWaterBalance : TState;  /// Water-balance based on Evapotranspiration, losses and Rain

    PondedWater : TState; /// amount of ponded water on the soil surface [mm]
    PondMax : TPar; /// maximum ponding height [mm];

    /// kumulative Bilanz [mm] zur Kontrolle!
    CumRunoff: TState;    /// cumulative Runoff [mm]

    SumSoilWater,
    /// sum of soil water down to boundary given by the Par "bil_nr"
    SumPAVSoilWater: TVAR;
    /// sum of plant available soil water down to boundary given by the Par "bil_nr"
    SumPAvSoilWaterRZ: TVAR;
    global_iter: TVAR;
    /// total number of iterations over the simulation run
    /// sum of plant available soil water in the rooting zone (down to Weff)
    dt: TVAR;
    /// interne Zeitschrittweite des Diff. Wassertransportmodells
    n_int_timesteps: TVAR;
    SumOfInternalTimeSteps: TVAR;
    /// Summe der internen Zeitschritte (Kontrollvariable)

    WG0_30, WG30_60, WG60_90, WG90_120, WG0_60,

      WG0_10, WG0_20, WG0_40, WG10_30, WG20_30, WG20_40, WG30_40, WG30_50,
      WG30_120, WG30_100, WG40_60, WG60_80, WG80_100, WG90_110, WG0_100,
      WG0_120, wg0_90, WG60_100: TVAR;
    ProzNFK0_Weff: TVAR;
    ProzNFK0_100: TVAR;
    ProzNFK0_30: TVAR;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcEvap_red_f;

    procedure Integrate; override;

    procedure CalcRatesAndIntegrate; virtual;

    procedure CalcRates; override;

    procedure CalcSinks; virtual;

    procedure update_WG_Values;

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
      : TLowerBoundaryCondition read Untere_Randb write Untere_Randb;
    property Opt_IniMethod: TIniMethod read IniMethod write IniMethod;
    property Opt_maxdt: TPar read Max_dt write Max_dt;
    property Opt_nFKCalcMethod
      : TnFKCalcMethod read nFKCalcMethod write nFKCalcMethod;
    property Opt_VanGenPars_from_Texture
      : TVGParsFromTexture read FVGParsFromTexture write FVGParsFromTexture;
    property Opt_Ks_from_Texture
      : TKsFromTexture read FKsFromTexture write FKsFromTexture;
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
    property Opt_Weff: TSource read fWeffOpt write fWeffOpt;
    /// Option for Source of parameter Weff

    property Ext_NetRain: TExternV read getNetRain;
    property Ex_PotEvap: TExternV read getPot_Evap;
    property Ex_Groundwaterdepth
      : TExternV read Groundwaterdepth write Groundwaterdepth;

    property Par_b_sat1: TPar read b_sat1 write b_sat1;
    property Par_b_rest1: TPar read b_rest1 write b_rest1;
    property Par_b_KS1: TPar read Ks1 write Ks1;
    property Par_n1: TPar read n_par1 write n_par1;
    property Par_alpha1: TPar read alpha1 write alpha1;
    property Par_FK1: TPar read FK1 write FK1;
    /// Feldkapazität [cm3/cm3]
    property Par_PWP1: TPar read PWP1 write PWP1;
    /// permanenter Welkepunkt
    property Par_nFK1: TPar read nFK1;
    /// nutzbare Feldkapazität

    property Par_b_sat2: TPar read b_sat2 write b_sat2;
    property Par_b_rest2: TPar read b_rest2 write b_rest2;
    property Par_b_KS2: TPar read Ks2 write Ks2;
    property Par_n2: TPar read n_par2 write n_par2;
    property Par_alpha2: TPar read alpha2 write alpha2;
    property Par_FK2: TPar read FK2 write FK2;
    /// Feldkapazität [cm3/cm3]
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
    property Par_FK4: TPar read FK4 write FK4;
    /// Feldkapazität [cm3/cm3]
    property Par_PWP4: TPar read PWP4 write PWP4;
    /// permanenter Welkepunkt
    property Par_nFK4: TPar read nFK4;
    /// nutzbare Feldkapazität

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

    property SoilHeatModel
      : TAbstractSoilHeat read FSoilHeatModel write FSoilHeatModel;

  end;

procedure Register;

var
  SoilWaterMod: TSoilWaterMod;

implementation

uses
  SysUtils, Math, Dialogs;

procedure TSoilWaterMod.update_WG_Values;
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
  // ndx_str: string;

begin
  fShowWarnings := true;
  inherited CreateAll;
  m_model := Mualem;

  ParCreate('Max_dt', '[d]', 1, Max_dt,
    'maximum time step length for internal calculation');
  // Index für Bilanzierung
  ParCreate('Max_aenderWG', '[cm3/cm3]', 0.001, max_aenderWG,
    'maximum WChange during one internal time step'); // Index für Bilanzierung
  ParCreate('Max_IterError', '[cm3/cm3]', 0.0001, max_IterError,
    'maximum Change of Water content during one (Picard)-Iteration ');
  // Index für Bilanzierung
  ParCreate('bil_nr', '[]', 18, bil_nr); // Index für Bilanzierung

  for i := 1 to n_comp + 1 do
    if WPar[i] = nil then
      WPar[i] := TGenucht.create;

  ParCreate('HoriNdx1', '[-]', 3, HoriNdx1,
    'unterste Schicht des 1. Bodenhorizonts');
  ParCreate('HoriNdx2', '[-]', 6, HoriNdx2,
    'unterste Schicht des 2. Bodenhorizonts');
  ParCreate('HoriNdx3', '[-]', 10, HoriNdx3,
    'unterste Schicht des 3. Bodenhorizonts');
  ParCreate('HoriNdx4', '[-]', 20, HoriNdx4,
    'unterste Schicht des 4. Bodenhorizonts');

  ParCreate('bsat_scaling', '[-]', 1, bsat_scaling,
    'Skalierungsfaktor für bsat (wird in allen Horizonten mit diesem Faktor multipliziert)');
  ParCreate('alpha_scaling', '[-]', 1, alpha_scaling);

  ParCreate('b_sat1', '[cm3.cm-3]', 0.4298, b_sat1);
  ParCreate('b_rest1', '[cm3.cm-3]', 0.09, b_rest1);
  ParCreate('alpha1', '[1/cm]', 0.00677, alpha1,
    'Van-Genuchten-Parameter alpha für den 1. Bodenhorizont');
  ParCreate('n_par1', '[-]', 1.29494, n_par1);
  ParCreate('Ks_1', '[-]', 50.0, Ks1);
  ParCreate('FK_1', '[cm3/cm3]', 0.35, FK1);
  ParCreate('nFK_1', '[cm3/cm3]', 0.25, nFK1);
  ParCreate('PWP_1', '[cm3/cm3]', 0.1, PWP1);

  ParCreate('b_sat2', '[cm3.cm-3]', 0.45, b_sat2);
  ParCreate('b_rest2', '[cm3.cm-3]', 0.09, b_rest2);
  ParCreate('alpha2', '[1/cm]', 0.00677, alpha2);
  ParCreate('n_par2', '[-]', 1.29494, n_par2);
  ParCreate('Ks_2', '[-]', 50.0, Ks2);
  ParCreate('FK_2', '[cm3/cm3]', 0.35, FK2);
  ParCreate('nFK_2', '[cm3/cm3]', 0.25, nFK2);
  ParCreate('PWP_2', '[cm3/cm3]', 0.1, PWP2);

  ParCreate('b_sat3', '[cm3.cm-3]', 0.45, b_sat3);
  ParCreate('b_rest3', '[cm3.cm-3]', 0.09, b_rest3);
  ParCreate('alpha3', '[1/cm]', 0.00677, alpha3);
  ParCreate('n_par3', '[-]', 1.29494, n_par3);
  ParCreate('Ks_3', '[-]', 50.0, Ks3);
  ParCreate('FK_3', '[cm3/cm3]', 0.35, FK3);
  ParCreate('nFK_3', '[cm3/cm3]', 0.25, nFK3);
  ParCreate('PWP_3', '[cm3/cm3]', 0.1, PWP3);

  ParCreate('b_sat4', '[cm3.cm-3]', 0.45, b_sat4);
  ParCreate('b_rest4', '[cm3.cm-3]', 0.09, b_rest4);
  ParCreate('alpha4', '[1/cm]', 0.00677, alpha4);
  ParCreate('n_par4', '[-]', 1.29494, n_par4);
  ParCreate('Ks_4', '[-]', 50.0, Ks4);
  ParCreate('FK_4', '[cm3/cm3]', 0.35, FK4);
  ParCreate('nFK_4', '[cm3/cm3]', 0.25, nFK4);
  ParCreate('PWP_4', '[cm3/cm3]', 0.1, PWP4);

  ParCreate('PsiStart1', '[cm]', 500, PsiStart1);
  ParCreate('Weff', '[cm]', 100, Weff, 'effective rooting deph [cm]');
  ParCreate('PondMax', '[mm]', 10, PondMax, 'maximum height of ponded Water on Soil Surface');

  OptCreate('FVGParsFromTexture', 'FromPar', FVGParsFromTextOption);
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
  OptCreate('act_Evaporation', 'red_f', act_EvaporationOption,
    'Option for calculation actual evaporation');
  act_EvaporationOption.OptionList.Clear;
  act_EvaporationOption.OptionList.Add('red_f');
  act_EvaporationOption.OptionList.Add('inclExfiltration');
  OptCreate('evaporation red_f', 'modifiedBeese', red_fOption,
    'Option for calculation evaporation reduction factor');
  red_fOption.OptionList.Clear;
  red_fOption.OptionList.Add('modifiedBeese');
  red_fOption.OptionList.Add('Beese1978');
  OptCreate('FTextureClass1', 'Sl3', TOption(FTextClass1Option));
  OptCreate('FTextureClass2', 'Sl3', TOption(FTextClass2Option));
  OptCreate('FTextureClass3', 'Sl3', TOption(FTextClass3Option));
  OptCreate('FTextureClass4', 'Sl3', TOption(FTextClass4Option));
  FTextClass1Option.AddTextureClasses;
  FTextClass2Option.AddTextureClasses;
  FTextClass3Option.AddTextureClasses;
  FTextClass4Option.AddTextureClasses;

  // Options for lower boundary: NoFlow, Flow, Content, Groundwatertable
  OptCreate('Untere_Randb', 'ConstContent', OptUntere_Randb);
  OptUntere_Randb.OptionList.Add('ConstContent');
  OptUntere_Randb.OptionList.Add('NoFlux');
  OptUntere_Randb.OptionList.Add('Groundwater');
  OptUntere_Randb.OptionList.Add('FreeFlow');

  OptCreate('IniMethod', 'Parameter', OptIniMethod);
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

  fCompMethod := Diffusion; // Defaul Computatio option
  OptCreate('CompMethod', 'Diffusion', OptCompMethod);
  OptCompMethod.OptionList.Clear;
  OptCompMethod.OptionList.Add('Diffusion');
  OptCompMethod.OptionList.Add('Richards');
  OptCompMethod.OptionList.Add('Mixed');
  OptCompMethod.OptionList.Add('MixedHydrus');

  ExternVCreate('Groundwaterdepth', '[cm]', StateField, Groundwaterdepth);
  if Untere_Randb = Groundwatertable then
    Groundwaterdepth.Search := true
  else
    Groundwaterdepth.Search := false;

  ParCreate('psi_critEvap', '[hPa]', 500.0, psi_critEvap);
  StateCreate('CumGlobalWaterBalance', '[mm]',  0, true, CumGlobalWaterBalance);
  StateCreate('CumEvap', '[mm]', 0, true, CumEvap);
  StateCreate('CumDrainage', '[mm]', 0, true, CumDrainage);
  StateCreate('CumWaterBalance', '[mm]', 0, true, CumWaterBalance);
  StateCreate('CumAbsWaterBalance', '[mm]', 0, true, CumAbsWaterBalance);
  StateCreate('CumRunoff', '[mm]', 0, true, CumRunoff);

  VarCreate('Exfiltration', '[mm]', 0.0, true, Exfiltration);

  VarCreate('SumSoilWater', '[mm]', 0.0, true, SumSoilWater);
  VarCreate('SumPavSoilWater', '[mm]', 0.0, true, SumPAVSoilWater);
  VarCreate('SumPAvSoilWaterRZ', '[mm]', 0.0, true, SumPAvSoilWaterRZ,
    'sum of plant available soil water in the rooting zone (down to Weff)');
  VarCreate('psi_dummy', '[]', 0.0, true, PSI_dummy);
  VarCreate('n_int_timesteps', '[]', 0.0, true, n_int_timesteps);
  VarCreate('sumof_internaltimesteps', '[]', 0.0, true, SumOfInternalTimeSteps);
  VarCreate('global_iter', '[]', 0.0, true, global_iter,
    'total number of iterations over the current run');
 // StateCreate('CumTrans', '[mm]', 0, true, CumTrans);
  StateCreate('CumNetRain', '[mm]', 0, true, CumNetRain);
  StateCreate('PondedWater', '[mm]', 0, false, PondedWater, 'Amount of ponded water on soil surface');
  // if not (Netrain is TVar) then
  ExternVCreate('NetRain', '[mm/d]', StateField, NetRain);
  if not(Pot_Evap is TVAR) then
    ExternVCreate('PotEvap', '[mm/d]', StateField, TExternV(Pot_Evap));

  for i := 1 to n_comp + 1 do
  begin
    { if i <= 9 then
      ndx_str := '_' + IntTostr(i)
      else
      ndx_str := IntTostr(i); }

    VarCreate('WG' + ndx_str(i), '[cm3.cm-3]', 0.3, true, theta_arr[i],
      'Wassergehaltsvektor [cm3/cm3]');
    theta_arr[i].readFromFile := true;
    StateCreate('WMenge' + ndx_str(i), '[cm]', theta_arr[i].v * Dicke[i],
      false, WMenge[i], 'Wassermenge je Schicht [cm]');
    WMenge[i].readFromFile := false;
    // Wmenge[i].writetoFile := false;
    VarCreate('Psi' + ndx_str(i), '[cm]', WPar[i].psi_b_f(theta_arr[i].v),
      true, psi_arr[i], '// Wasserspannungsvektor [cm]');
    VarCreate('WFlowInt' + ndx_str(i), '[cm.d-1]', 0.0, false, WflowInt_arr[i]);
    WflowInt_arr[i].writetoFile := false;
    VarCreate('WFlow' + ndx_str(i), '[cm.d-1]', 0.0, false, Wflow_arr[i],
      'Flussvektor [cm/d]');
    Wflow_arr[i].writetoFile := true;
    VarCreate('Sink' + ndx_str(i), '[cm.d-1]', 0.0, false, Sink_arr[i],
      'Sinkvektor [cm]');
    VarCreate('SinkInt_' + ndx_str(i), '[cm.d-1]', 0.0, false, SinkInt_arr[i]);
    SinkInt_arr[i].writetoFile := false;
  end;
  VarCreate('red_evap', '[]', 1.0, false, red_evap);
  VarCreate('act_evap', '[mm/d]', 0.0, false, Act_Evap);
  VarCreate('dt_int', '[d]', 0.1, false, dt);

  Untere_Randb := ConstContent; // default for lower boundary is a constant content
//  for i := 1 to n_comp + 1 do
//    theta_alt[i] := theta_arr[i].v;

  for i := 1 to n_comp + 1 do
  begin
    WMenge[i].v := theta_arr[i].v * Dicke[i];
    theta_alt[i] := theta_arr[i].v;
  end;
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

procedure TSoilWaterMod.BeforeDestruction;
var
  i: integer;

begin
  for i := 1 to n_comp + 1 do
    if WPar[i] <> nil then
      FreeAndNil(WPar[i]);
  inherited;
end;

function TSoilWaterMod.getNetRain: TExternV;
begin
  if NetRain is TExternV then
    result := NetRain
  else
    result := nil;
end;

function TSoilWaterMod.getPot_Evap: TExternV;
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
    until (tiefe[ndx_Weff].v >= Plantmodel.Weff) or (ndx_Weff >= n_comp + 1);
  end
  else
  begin
    repeat
      inc(ndx_Weff);
    until (tiefe[ndx_Weff].v >= Weff.v) or (ndx_Weff >= n_comp + 1);
  end;
end;

procedure TSoilWaterMod.Init(var GlobMod: Tmod);
var
  i: integer;
  error: boolean;
  psiWP, psiFK: real;
  nFK0_Weff, PWP0_Weff, WG0_Weff: real;
  nFK0_100, PWP0_100: real;

begin
  inherited Init(GlobMod);
  MaxAktAenderWaGe := 0.0; // hp & ar 07.01.2010  !
  sum_Bilanz_f := 0.0;
  dt_alt := dt.v;
  red_evap.v := 1.0;
  Act_Evap.v := 0.0;
  dt_set := false;
  dt.v := 0.001;
  dt_alt := dt.v;
  iter := 0;
  total_iter := 0;
  last_iter := 0;
  IterMax := 7;
  min_dt := 0.001;
  SW_start:= 0;
  flag_cascadic:=false;
  global_WaterBalance:= 0;
  old_global_WaterBalance:= 0;
  Max_dt.v := min(Max_dt.v, GlobMod.Time.c); // value of maximum timestep
  // UB 20.1.16: Min eingefügt, damit kleinere maximale Zeitschritte über property
  // einstellbar sind.
  // hk 25.1.01: sollte eigentlich über die Property einzustellen sein ...
  // keine Ahnung wer das reingeschrieben hatte ...
  // max_aenderWG := 0.01; // maximale Wassergehaltsänderung pro Zeitschritt
  for i := 0 to max_comp do
  begin

    Dw_arr[i] := 0.0;
    /// Diffusivitäten [cm2/d] }
    c_arr[i] := 0.0;
    /// specific water capacity
    P[i] := 0.0;
    /// intermediate variable dt.v/(C_arr*??)
    kf[i] := 0.0;
    /// saturated hydraulic conductivities [cm/d]
    Ku_arr[i] := 0.0;
    /// ungesättigte hydraulische Leitfähigkeiten [cm/d] }
    avg_Dw[i] := 0.0;
    /// Mittelwert der Diffusivität zwischen 2 Kompartimenten [cm2/d] }
    avg_Ku[i] := 0.0;
    /// Mittelwert der unges„ttigten hydr. Leitfähigkeit zwischen 2 Kompartimenten [cm/d] }
    Dw_fact[i] := 0.0;
    /// Intermediate variable
    Ku_fact[i] := 0.0;
    /// Intermediate variable
    B_vektor[i] := 0.0;
    /// Intermediate variable[i] := 0.0; known values and solution vektor
    lower[i] := 0.0;
    /// lower vector of the tri-diagonal matrix
    diag[i] := 0.0;
    /// central vector of the tri-diagonal matrix
    upper[i] := 0.0;
    /// upper vector of the tri-diagonal matrix
    last_iter_theta[i] := 0.0;
    /// Wassergehalte bei der letzten Iteration [cm3/cm3 }
    est_theta[i] := 0.0;
    theta_neu[i] := 0.0;
    /// new soil water contents
    FK_Arr[i] := 0.0;
    /// Feldkapazität [cm3/cm3]
    PWP_Arr[i] := 0.0;
    /// permanenter Welkepunkt [cm3/cm3]
    nFK_Arr[i] := 0.0;
    /// nutzbare Feldkapazität [cm3/cm3]
    Wflow_alt[i] := 0.0;
    /// alte Wasserflüsse [cm/d]
    theta_alt[i] := 0.0;
    /// alte Wassergehalte
    psi_neu[i] := 0.0;
    /// New estimate of water potential [cm]
    Bilanz_f_arr[i] := 0.0;
    cumBilanz_f_arr[i] := 0.0;
    alpha[i] := 0.0;
    beta[i] := 0.0;
    gamma[i] := 0.0;
    Res[i] := 0.0;
    upper[i] := 0.0;
    diag[i] := 0.0;
    lower[i] := 0.0;
    B_vektor[i] := 0.0;
    wf[i] := 1.0;
  end;

  for i := 1 to n_comp + 1 do
  begin
    psi_arr[i].Digits := PSI_dummy.Digits;
    psi_arr[i].Precision := PSI_dummy.Precision;
  end;

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

  if uppercase(FVGParsFromTextOption.Option) = 'FROMPAR' then
    FVGParsFromTexture := FromPar;
  if uppercase(FVGParsFromTextOption.Option) = 'FROMTEXTURE' then
    FVGParsFromTexture := FromTexture;
  if uppercase(FKsFromTextOption.Option) = 'FROMPAR' then
    FKsFromTexture := FromPar;
  if uppercase(FKsFromTextOption.Option) = 'FROMTEXTURE' then
    FKsFromTexture := FromTexture;
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
  begin { FVGParsFromTexture = FromPar }
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
          psi_arr[i].v := max(10, psi_arr[i - 1].v - Dicke[i])
        else
          // to avoid saturation ...
          psi_arr[i].v := Dicke[i] / 2;
        theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      end
      else
        psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(name, psi_arr[i].name, psi_arr[i].v);
      WMenge[i].v := theta_arr[i].v * Dicke[i];
      theta_alt[i] := theta_arr[i].v
    end
  end
  else if Opt_IniMethod = Potentials then
  begin
    for i := 1 to n_comp + 1 do
    begin
      psi_arr[i].v := GlobMod.StateIniFile.ReadFloat(name, psi_arr[i].name,
        100);
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(name, theta_arr[i].name, theta_arr[i].v);
      WMenge[i].v := theta_arr[i].v * Dicke[i];
      theta_alt[i] := theta_arr[i].v
    end
  end
  else if Opt_IniMethod = Parameter then
  begin
    for i := 1 to n_comp + 1 do
    begin
      psi_arr[i].v := PsiStart1.v - (i - 1) * 10;
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      GlobMod.StateIniFile.WriteFloat(name, theta_arr[i].name, theta_arr[i].v);
      WMenge[i].v := theta_arr[i].v * Dicke[i];
      theta_alt[i] := theta_arr[i].v
    end;

  end;
  for i := 1 to n_comp + 1 do
  begin
    psi_neu[i] := psi_arr[i].v;
    theta_neu[i] := theta_arr[i].v;
  end;

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

  psiWP := power(10, 4.2);
  psiFK := power(10, 1.8);

  red_evap.v := 1.0;
  Act_Evap.v := 0.0;
  CumEvap.v := 0.0;
  CumDrainage.v := 0.0;
  Untere_Randb := ConstContent;

  if round(HoriNdx1.v) = 0 then
  begin
    if ShowWarnings then
    begin
      showmessage(
        'Warning ! No specification of Indexes for hydraulic parameters');
      showmessage('Please check !');
    end;
  end;

  if Opt_nFKCalcMethod = FromParameter then
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

  if uppercase(OptUntere_Randb.Option) = 'CONSTCONTENT' then
    Untere_Randb := ConstContent;
  if uppercase(OptUntere_Randb.Option) = 'NOFLUX' then
    Untere_Randb := NoFlow;
  if uppercase(OptUntere_Randb.Option) = 'GROUNDWATER' then
    Untere_Randb := Groundwatertable;
  if uppercase(OptUntere_Randb.Option) = 'FREEFLOW' then
    Untere_Randb := FreeFlow;

  if Untere_Randb = Groundwatertable then
    Groundwaterdepth.Search := true
  else
    Groundwaterdepth.Search := false;
  { Berechnung der abgeleiteten Wassergehalte für verschiedene Bodenschichten }

  // Berechnung der abgeleiteten Wassergehalte für verschiedene Bodenschichten
  update_WG_Values;

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
    until tiefe[ndx_Weff].v >= Plantmodel.Weff;
  end
  else
  begin
    repeat
      inc(ndx_Weff);
    until tiefe[ndx_Weff].v >= Weff.v;
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

  if uppercase(red_fOption.Option) = 'MODIFIEDBEESE' then
    fred_f := modifiedBeese;
  if uppercase(red_fOption.Option) = 'BEESE1978' then
    fred_f := Beese1978;

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
 }
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
  OldSumSoilwater,  // amount of soil water in previous time step
  OldSumWater,      // amount of water (soil + ponded) in previous time step
  SumWater,          // amount of water (soil + ponded)
  OldPondedWater
  : real;

begin

  SumOfInternalTimeSteps.v := 0.0;
  Act_Evap.v := 0.0;
  CumEvap.c := 0.0;
  CumDrainage.c := 0.0;
  CumRunoff.c := 0.0;
  PondedWater.c := 0.0;
  CumDayFlow1 := 0.0;
  OldPondedWater := PondedWater.v;
  for i := 1 to n_comp + 1 do begin
    Wflow_alt[i] := wflow_arr[i].v;
    theta_alt[i] := theta_arr[i].v;
  end;

  for i := 1 to n_comp + 1 do
    Wflow_arr[i].v := 0.0;

  n_int_timesteps.v := 0;
  dt.v := dt_alt;
  { Startwert für Zeitschrittweiten-Steuerung ist der vorletzte Zeitschritt des vorherigen Tages. }
  act_n_comp := n_comp; // default value for computation index
  if Opt_Randbed = Groundwatertable then
  begin
    act_n_comp := 2;
    repeat
      inc(act_n_comp);
    until (tiefe[act_n_comp + 1].v >= Groundwaterdepth.v) or
      (act_n_comp >= n_comp);
  end;
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
  OldSumSoilwater := SumSoilWater.v;
  OldSumWater := OldSumSoilWater + PondedWater.v;
  SumSoilWater.v := 0.0;
  SumPAVSoilWater.v := 0.0;
  for i := 1 to trunc(bil_nr.v) do
  begin
    SumSoilWater.v := SumSoilWater.v + WMenge[i].v * 10;
    SumPAVSoilWater.v := SumPAVSoilWater.v + WMenge[i].v * 10 - PWP_Arr[i]
      * Dicke[i] * 10;
  end;
  SumWater := SumSoilWater.v+PondedWater.v;

  if GlobTime.v > GlobMod.Starttime then
  begin
//    CumWaterBalance.c := (SumSoilWater.v - OldSumSoilwater) +
//      (-CumNetRain.c + CumDrainage.c + CumEvap.c + CumRunoff.c) * GlobTime.c;
    CumWaterBalance.c := (SumSoilWater.v - OldSumSoilwater) +
      (-Wflow_arr[1].v*10 + CumDrainage.c ) * GlobTime.c;

//    CumWaterBalance.c := (SumWater - OldSumwater) +
//      (-CumNetRain.c + CumDrainage.c + CumEvap.c + CumRunoff.c) * GlobTime.c;


      //    CumWaterBalance.c := (SumSoilWater.v - OldSumSoilwater) +
//      (+Wflow_arr[1].v-Wflow_arr[n_comp].v-CumRunoff.c)*10 * GlobTime.c;

  end;
end;

procedure TSoilWaterMod.Leitfaehigkeiten;

var
  i: byte;
  Overflow: real;
begin
    // Berechnung der Wasserdiffusivität und der ungesättigten hydraulischen
    // Leitfähigkeit für jedes Kompartiment aus dem Mittelwert der Wassergehalte
    // zu Beginn des Zeitschrittes und zum Ende des Zeitschrittes
    for i := 1 to n_comp + 1 do
    begin
      Dw_arr[i] := WPar[i].Dw_f(theta_neu[i]);
      Ku_arr[i] := WPar[i].Ku_b_f(theta_neu[i]);
    end;

    { Berechnung des Mittelwertes der Leitfähigkeit zwischen 2 Kompartimenten }
    for i := 2 to n_comp + 1 do
    begin
      // harmonic mean of conductivities
      avg_Dw[i] := sqrt(Dw_arr[i - 1] * Dw_arr[i]); // cm2/d
      avg_Ku[i] := sqrt(Ku_arr[i - 1] * Ku_arr[i]); // cm/d
    end;

    avg_ku[1] := (Wpar[1].ks+Ku_arr[1])/2;    // aritmethic mean
    avg_Dw[1] := (Wpar[1].Dw_f((Wpar[1].b_sat + theta_neu[1])/2));     // aritmethic mea
    { Berechnung von Koeffizienten für die Aufstellung des Gleichungssystems,
      Abst.vektor mit dem Index i-1, weil Abstand zwischen erstem und
      zweiten Kompartiment Index 1 hat (verschobene Indizierung }

    for i := 1 to n_comp + 1 do
    begin
        Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
        Ku_fact[i] := avg_Ku[i] * dt.v;
    end;

  if FSoilHeatModel <> nil then
  begin
    for i := 1 to n_comp + 1 do
    begin
      if FSoilHeatModel.Temp[i].v <= 0 then
      begin
        avg_Ku[i] := 0.0;
        Ku_fact[i] := 0.0;
        Dw_fact[i] := 0.0;
        //P[i] := 0.0;
        kf[i] := 0.0;
      end;
    end;
  end;
end;

procedure TSoilWaterMod.Integrate;
var
  NextINI, NextStateINI: TMyIniFile;
  i: integer;
  ndx_str: string;
  nFK0_Weff, PWP0_Weff, WG0_Weff: real;
  nFK0_100, PWP0_100: real;
begin
  inherited;

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
    WG0_Weff := WG0_Weff + theta_arr[i].v * (tiefe[i].v - tiefe[i - 1].v);
    nFK0_Weff := nFK0_Weff + nFK_Arr[i] * (tiefe[i].v - tiefe[i - 1].v);
    PWP0_Weff := PWP0_Weff + PWP_Arr[i] * (tiefe[i].v - tiefe[i - 1].v);
  end;
  SumPAvSoilWaterRZ.v := (WG0_Weff - PWP0_Weff) * 10;
  ProzNFK0_Weff.v := (WG0_Weff - PWP0_Weff) / nFK0_Weff * 100;
  ProzNFK0_30.v := (WG0_30.v * 3 - (PWP_Arr[1] + PWP_Arr[2] + PWP_Arr[3])) /
    (nFK_Arr[1] + nFK_Arr[2] + nFK_Arr[3]) * 100;
  if Opt_TransferWGsToNextINI and (GlobTime.v = GlobMod.Endtime) then
  begin
    if GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName)
      = GlobMod.IniFileNames.Count - 1 then
      exit;
    NextINI := TMyIniFile.create;
    NextINI.Init(GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf
        (GlobMod.ActIniFile.FileName) + 1]);
    NextStateINI := TMyIniFile.create;
    NextStateINI.Init(NextINI.ReadString('FileNames', 'StateIniFN', ''));
    for i := 1 to n_comp + 1 do
    begin
      if i <= 9 then
        ndx_str := '_' + IntTostr(i)
      else
        ndx_str := IntTostr(i);
      NextStateINI.WriteString(Name, 'WG' + ndx_str,
        FloatToStrF(theta_arr[i].v, ffFixed, 9, 6));
    end;
    NextINI.Free;
    NextStateINI.Free;
  end;

  If ( (GlobTime.v > GlobMod.Starttime) and (SW_start > 0) ) then begin
    //Rain-W_loss-Trans-Evap-SW_diff
    global_WaterBalance := CumNetRain.v - (CumRunoff.v + CumDrainage.v)
    {- CumTrans.v} - CumEvap.v - (SumSoilWater.v + PondedWater.v - SW_start);
    CumGlobalWaterBalance.v:= CumGlobalWaterBalance.v + global_WaterBalance; // - old_global_WaterBalance;

  end;

  if ( (SW_start = 0)  and  (SumSoilWater.v > 0) )then
       SW_start:= SumSoilWater.v + PondedWater.v;
end;

procedure TSoilWaterMod.get_bilanz;

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
  d_WaMe, { Aenderung der Wassermengeim Kompartiment                  [cm] }
  d_WaGe,
  { Žnderung des Wassergehaltes  im Kompartiment                  [cm3/cm3] }
  sum_d_WaMe, { Summe der Wassermengen-aenderungen                       [cm] }
  sum_sink { Summe der Sink-Terme            [cm] }

  : real;

begin
  for i := 0 to n_comp + 1 do
    Bilanz_f_arr[i] := 0.0;
  MaxAktAenderWaGe := 0.0;
  sum_d_WaMe := 0.0;
  sum_sink := 0.0;
  akt_bilanz_f := 0.0;
  for i := 1 to n_comp do
  begin
    net_flow := (WflowInt_arr[i].v - WflowInt_arr[i + 1].v) * dt.v; // [cm/d]
    d_WaMe := (theta_arr[i].v - theta_neu[i]) * Dicke[i];
    d_WaGe := theta_arr[i].v - theta_neu[i];
    Bilanz_f_arr[i] := d_WaMe + net_flow - Sink_arr[i].v * dt.v;
    cumBilanz_f_arr[i] := cumBilanz_f_arr[i] + Bilanz_f_arr[i];
    akt_bilanz_f := akt_bilanz_f + Bilanz_f_arr[i];
    if abs(d_WaGe) > MaxAktAenderWaGe then
      MaxAktAenderWaGe := abs(d_WaGe);
    sum_d_WaMe := sum_d_WaMe + d_WaMe;
    sum_sink := sum_sink + Sink_arr[i].v * dt.v;
  end;
  sum_Bilanz_f := sum_Bilanz_f + akt_bilanz_f;
end;


procedure TSoilWaterMod.get_new_dt;
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
 max_iter = 1000;
var
  delta_t, dt_neu, min_h: real;

  i : integer;

  function calc_dt_power(x,x_max,x_min,y_max,y_min: real): real;
    var
    a, b: real;
  begin
    {y_max is y(x_max)
     y_min is y(x_min)}
    b:= ln(y_max/y_min)/ln(x_max);
    a:= y_max/power(x_max,b);
    calc_dt_power := a*power(x,b);
  end;
  procedure iter_reset;
  var
  i: integer;
  begin
      if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then
			  dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
      for i := 1 to n_comp + 1 do
      begin
        theta_neu[i] := theta_arr[i].v;
        psi_neu[i] := psi_arr[i].v;
      end;
      ResetTimeStep := true;
  end;

begin
	// niedrige Wasserspannungen bzw. hohe Flussraten in vielen Schichten
	if(((fCompMethod = Richards) or (fCompMethod = Mixed) or
	(fCompMethod = MixedHydrus)))
    then begin
		  iter := iter + 1;
		  total_iter := total_iter + 1;
		  // Set new time-step
		  if (dt_set = false) then
		  begin
			// How many iteration last time-step? -> reduce width of time step if necessary
			if(last_iter >3) then // takes place only after 'reset'
			  delta_t := calc_dt_power(last_iter,IterMax,1,min_dt,1)
			else
			  delta_t :=1 ;
			// Verhältniss der erlaubten zur aktuellen Wassergehaltsänderung
			if max(MaxAktAenderWaGe, NetRain.v * dt.v / (Dicke[1] * 10)) <> 0.0 then
			begin
			  dt_neu := (max_aenderWG.v / max(MaxAktAenderWaGe,
				  NetRain.v * dt.v / (Dicke[1] * 10))) * dt.v;
			  if ((dt_neu > (1.5 * dt.v)) and (dt_neu > min_dt*100)) then
					  dt_neu := dt.v * 1.5; { Zu großer Zeitschrittsprung ? }
			  delta_t := max(min(delta_t, dt_neu), min_dt)
			end
			else
			  dt_neu := delta_t;
			// is iteration or change rate of wc limiting ?
			delta_t := max(delta_t, min_dt);
			dt.v := delta_t;
			  min_h:=100;
			  for i := 1 to n_comp do
			  begin
				if(psi_neu[i]<min_h) then
				  min_h:= psi_neu[i];
			  end;
			  if(min_h < crit_h) then
				dt.v := min(delta_t, calc_dt_power((crit_h-min_h), crit_h,1,min_dt,1))
			  else
			  dt.v :=delta_t;
			if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then begin
			  dt_alt := dt.v;
			  dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
			  newday := true;
			end;
			dt_set := true;
		  end;
		  // Reset
		  If iter > IterMax then
		  begin
        last_iter := iter;
        iter := 0;
        IterMax := IterMax + 1;
        dt.v := min_dt;
        if(last_iter > 10) then
          last_iter:=+1;
        dt_set := true;
        iter_reset;
		  end; // Reset end
    end else
	begin // Diffusion
		if max(MaxaktAenderWaGe, NetRain.v * dt.v / (Dicke[1] * 10)) <> 0.0 then
		  begin
		  if (dt_alt / dt.v <= 1.5) then
			dt_alt := dt.v { Speicherung der alten Zeitschrittweite}
		  else dt.v := dt_alt; { wenn der alte Zeitschritt Rest des Tages war,
					dann vorletzter Zeitschritt als Startwert für neuen Zeitschritt.}
					{ Verhältnis der erlaubten zur aktuellen Wassergehaltsänderung }
		  dt_neu := (max_aenderWG.v / max(MaxaktAenderWaGe, NetRain.v * dt.v /
			(Dicke[1] * 10))) * dt.v;
		  if dt_neu > max_dt.v then dt_neu := max_dt.v; { Zu großer Zeitschritt ? }
		  if dt_neu > 1.5 * dt.v then
			dt_neu := dt.v * 1.5; { Zu großer Zeitschrittsprung ?}
		  { Der folgende Algorithmus wurde eingefügt, um Diskontinuitäten bei der
			Verwendung von Eingabedaten auf täglicher Basis zu vermeiden. }
		  if SumOfInternalTimeSteps.v + Dt_neu > GlobTime.c
			{ Ende des Tages überschritten mit neuem Zeitschritt ? }then
			dt_neu := (GlobTime.c - SumOfInternalTimeSteps.v);
		  dt.v := dt_neu;

		end;
     iter := iter + 1;
     total_iter:= iter;
    if (total_iter > max_iter) then
    begin
     iter_reset;
     dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
     Cascadic;
     flag_cascadic:= true;
    end else
     flag_cascadic:= false;
	end;
  if ((delt_iter_max < max_IterError.v) and (iter > 1) or (total_iter > max_iter))
    then
  begin
    success := true;
    last_iter := 0;
    iter := 0;
    dt_set := false;
    IterMax := 7;
    min_dt := 0.001;
    global_iter.v := global_iter.v + total_iter;
    total_iter := 0;
  end;
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
  if (iter > 0) or ResetTimeStep then
  begin
    for i := start to n_comp do
    begin
      WG_diff := abs(last_iter_theta[i] - theta_neu[i]);
      delt_iter_max := max(delt_iter_max, WG_diff);
    end;
  end;

end;

procedure TSoilWaterMod.calcoverflow;
var
  i: integer;
  Overflow, maxstorage: real;
  layer: byte;

begin
  for i := n_comp downto start do
  begin
    if theta_neu[i] > WPar[i].b_sat then
    begin
      Overflow := (theta_neu[i] - WPar[i].b_sat) * Dicke[i];
      // save overshooting amount of water
      theta_neu[i] := WPar[i].b_sat;
      psi_neu[i] := 0;
      layer := i; // start with the lowest layer where overflow occurred
      WflowInt_arr[layer].v := WflowInt_arr[layer].v - Overflow / dt.v;
      repeat
        if theta_neu[layer] < WPar[layer].b_sat then
        begin // water capacity available?
          maxstorage := (WPar[layer].b_sat - theta_neu[layer]) * Dicke[layer];
          // how much?
          if Overflow > maxstorage then
          begin // everything fits in this layer ?
            theta_neu[layer] := WPar[layer].b_sat;
            Overflow := Overflow - maxstorage;
          end
          else
          begin
            theta_neu[layer] := theta_neu[layer] + Overflow / Dicke[layer];
            Overflow := 0.0;
          end;
          WflowInt_arr[layer].v := WflowInt_arr[layer].v + Overflow / dt.v;
        end;
        dec(layer)
      until (layer = 0) or (Overflow <= 0);
      // all overflow distributed or surface layer reached ...
      if Overflow > 0 then
       // CumRunoff.c := CumRunoff.c + Overflow * 10 * GlobTime.c;
       PondedWater.v := PondedWater.v + Overflow * 10 * GlobTime.c;
    end;
    if theta_neu[i] < WPar[i].b_rest then
    begin
      theta_neu[i] := WPar[i].b_rest;
    end;
    psi_neu[i] := WPar[i].psi_b_f(theta_neu[i]);

  end;
end;

procedure TSoilWaterMod.CalcRatesAndIntegrate;

begin
  Exfiltration.v := Dw_arr[1] * theta_arr[1].v / (0.5 * Dicke[1]) * 10;
  CalcEvap_red_f;

  // for Debugging    Act_Evap.v := 0.0;

  Act_Evap.v := Pot_Evap.v * red_evap.v;

  if (act_EvaporationOption.Option = 'inclExfiltration') then
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
  update_WG_Values;

  // CumEvap.c := CumEvap.c +
  // (-WflowInt_arr[1].v * 10 + CumNetRain.c - CumRunoff.c) * dt.v;
  CumEvap.c := CumEvap.c + Act_Evap.v * dt.v;
  // if WFlowInt_arr[1] was reduced because of dry, this is the new ActEvap of InternTimeStep
  CumDrainage.c := CumDrainage.c + WflowInt_arr[trunc(bil_nr.v) + 1].v* 10 * dt.v;
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
    { Berechnung der Wasserspannungen [cm] bei Feldkapazit„t bzw. beim
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
        WMenge[i].v := theta_arr[i].v * Dicke[i];
      end;
    end;
    rep := true;
  end; { Ende Initialisierungssequenz }

  dt.v := GlobTime.c;
  // bei Kapazitätswassermodell immer Zeitschritt des globalen
  // Modells

  for i := 1 to n_comp + 1 do
  begin
    theta_arr[i].v := WMenge[i].v / Dicke[i];
    theta_alt[i] := theta_arr[i].v;
    Wflow_alt[i] := WflowInt_arr[i].v;
    WflowInt_arr[i].v := 0.0;
  end;

  if (NetRain.v > 0.0) then
  begin
    WflowInt_arr[1].v := NetRain.v * 0.1;
    for i := 1 to n_comp do
    begin
      WCap[i] := (FK_Arr[i] - theta_arr[i].v) * Dicke[i];
      if (WCap[i] < WflowInt_arr[i].v) then
      begin // Saturation ?
        theta_arr[i].v := FK_Arr[i];
        WflowInt_arr[i + 1].v := WflowInt_arr[i].v - WCap[i];
      end
      else
      begin
        theta_arr[i].v := theta_arr[i].v + WflowInt_arr[i].v / Dicke[i]
          * GlobTime.c;
        WflowInt_arr[i + 1].v := 0.0;
      end;
    end;
  end;
  // evaporation
  theta_arr[1].v := theta_arr[1].v - 0.1 * Act_Evap.v / Dicke[1] * GlobTime.c;

  // water uptake of plant roots
  for i := 1 to n_comp do
  begin
    theta_arr[i].v := (theta_arr[i].v - Sink_arr[i].v) / Dicke[i] * GlobTime.c;
    psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
  end;

end; { procedure CapWatSolut }

{ -------------------------------------------------------------------------- }

procedure TSoilWaterMod.get_water_contents;
var
  i: byte;
begin
  for i := 1 to n_comp + 1 do
  begin
    theta_arr[i].v := WMenge[i].v / Dicke[i];
    theta_neu[i] := theta_arr[i].v;
    Wflow_alt[i] := avg_Dw[i] * (theta_alt[i - 1] - theta_alt[i])
          / Abst[i - 1] + avg_Ku[i];
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
    theta_alt[i] := theta_arr[i].v;
    theta_arr[i].v := theta_neu[i];
    if self.Opt_CompMethod = Diffusion then
     psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v)
    else
      psi_arr[i].v := psi_neu[i];
    WMenge[i].v := theta_arr[i].v * Dicke[i];
  end;
  if Untere_Randb = FreeFlow then
  begin
    psi_arr[n_comp + 1].v := psi_arr[n_comp].v; // -Abst[n_comp];
//    psi_arr[n_comp + 1].v := psi_arr[n_comp].v -Abst[n_comp];
    theta_arr[n_comp + 1].v := WPar[n_comp].b_psi_f(psi_arr[n_comp+1].v);
//    theta_arr[n_comp + 1].v :=  theta_arr[n_comp].v;
    psi_neu[n_comp+1] := psi_arr[n_comp + 1].v;
    theta_neu[n_comp+1] := theta_arr[n_comp+1].v;
  end;
end;


procedure TSoilWaterMod.Cascadic;
  const
    rep: boolean = false;
    psi_overflow: real = 25;
  var
    psiWP, sum_sink_, Wcap_, ku_1, rain_: real;
    i: byte;
    theta_: TSoilArray;
    WflowInt_: TSoilArray;
    pot_RunOff: real;
  begin
    for i := 1 to n_comp + 1 do
    begin
      theta_[i] := WMenge[i].v / Dicke[i];
      theta_alt[i] := theta_arr[i].v;
      Wflow_alt[i] := WflowInt_arr[i].v;
      WflowInt_arr[i].v := 0.0;
      WflowInt_[i]:= 0.0;
      theta_neu[i]:= 0.0;
    end;
    rain_:= NetRain.v * dt.v;
    ku_1:= WPar[1].Ku_psi_f(power(10, 1.8));
    WCap_ := ( WPar[1].b_psi_f(5) - theta_arr[1].v) * Dicke[1] * 10;
    if ( NetRain.v * dt.v -
         WCap_ - // capacity
         Sink_arr[1].v * 10 * dt.v  -	  // sink
         Act_Evap.v * dt.v) > (ku_1 * 10 * dt.v) then
    begin
      {CumRunoff.c:= CumRunoff.c + (NetRain.v * dt.v -
                     WCap_ - // capacity
                      Sink_arr[1].v * 10 * dt.v  -   // sink
                       Act_Evap.v * dt.v) - (ku_1 * 10 * dt.v);
                       }
      pot_RunOff:=  (NetRain.v * dt.v -
                     WCap_ - // capacity
                      Sink_arr[1].v * 10 * dt.v  -   // sink
                      Act_Evap.v * dt.v) - (ku_1 * 10 * dt.v);

      PondedWater.v := PondedWater.v +  pot_RunOff  * GlobTime.c;
      rain_:= NetRain.v * dt.v - pot_RunOff;
  end;
// excess water
  WflowInt_[1] := rain_ * 0.1 ;  // mm/d -> cm/d
  for i := 1 to n_comp do
  begin
     WCap_ := (WPar[i].b_psi_f(5) - theta_[i]) * Dicke[i];
    if (WCap_ < WflowInt_[i]) then
    begin // Saturation ?
      theta_[i] := WPar[i].b_psi_f(psi_overflow);
      WflowInt_[i + 1] := (WflowInt_[i] - WCap_);
    end
    else
    theta_[i] := theta_[i] + (WflowInt_[i] / Dicke[i])
          * GlobTime.c;
  end;
  // evaporation
  theta_[1] := theta_[1] - (0.1 * Act_Evap.v * dt.v // mm->cm
                            / Dicke[1]                // cm ->cm3/cm3
                            * GlobTime.c);
    // water uptake of plant roots
  for i := 1 to n_comp do
  begin
    WflowInt_arr[i].v:= WflowInt_[i];
    theta_neu[i]:=  theta_[i] -
            Sink_arr[i].v * dt.v / Dicke[i] //cm->cm3/cm3
            * GlobTime.c;
    psi_neu[i] := WPar[i].psi_b_f(theta_neu[i]);
    last_iter_theta[i] := theta_neu[i];
  end;
  success := true;
end;



procedure TSoilWaterMod.Diffwater_solut;

var
  result: byte;
  i: integer;
  psi_top, MaxFlow1 : real;

  procedure obere_Randbedingung;

  { zur Verhinderung von ungültigen Funktionsaufrufen wird zuerst
    eine Prüfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
    "Restwassergehalt b_rest" oder ein Ansteigen über den "Sättigungs-
    wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prüfung wird
    in den Variablen "Wet", bzw. "Dry" gespeichert. }

  begin
    dry := false;
    wet := false;
    success := false;
    start := 1;

    MaxFlow1 :=  DayFlow1 + 0.1*PondedWater.v/dt.v;  // maximum possible water influx rate [cm/d]
    if MaxFlow1 > 0  then begin
        psi_top := -PondedWater.v/10; // tension including ponded water [cm]
        //MaxInfil :=  2.0*avg_ku[1]*((psi_neu[1]-psi_top)/Dicke[1])+avg_ku[1];
        MaxInfil := PondMax.v*0.1; // [cm/d]

    end;

   // if ( (MaxFlow1 > MaxInfil)  )then
    if ( theta_neu[1] >= WPar[1].b_sat  )then
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
          + WflowInt_arr[1].v * dt.v / Dicke[1]
          - Ku_fact[2] / Dicke[1]
              - Sink_arr[1].v * dt.v / Dicke[1];
      diag[1] := Dw_fact[2] / Dicke[1] + 1.0;
      upper[1] := -Dw_fact[2] / Dicke[1];
    end else
    begin
      B_vektor[1] :=
        theta_arr[1].v
        + Wpar[1].b_sat*Dw_fact[1]/Dicke[1]
        + ku_fact[1] / Dicke[1]
        - Ku_fact[2] / Dicke[1]
        - Sink_arr[1].v * dt.v / Dicke[1];
      lower[1] :=  0;
      diag[1]  :=  Dw_fact[1] / Dicke[1] + Dw_fact[2] / Dicke[1] + 1.0;
      upper[1] := - Dw_fact[2] / Dicke[1];
   end;
  end;

  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      B_vektor[i] := theta_arr[i].v
                    - Ku_fact[i + 1] / Dicke[i]
                    + Ku_fact[i] / Dicke[i]
                    - Sink_arr[i].v * dt.v / Dicke[i];
      lower[i] := -Dw_fact[i] / Dicke[i];
      diag[i]  := Dw_fact[i] / Dicke[i] + Dw_fact[i + 1] / Dicke[i] + 1.0;
      upper[i] := -Dw_fact[i + 1] / Dicke[i];
    end;
  end;

  procedure untere_Randbedingung;

  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (Untere_Randb = ConstContent) or (Untere_Randb = Groundwatertable) or
      (Untere_Randb = FreeFlow) then
      { Gehalts-Randbedingungen }
      B_vektor[act_n_comp] := theta_arr[act_n_comp].v + Ku_fact[act_n_comp]
        / Dicke[act_n_comp] - Ku_fact[act_n_comp + 1] / Dicke[act_n_comp + 1]
        + Dw_fact[act_n_comp + 1] * theta_arr[act_n_comp + 1].v / Dicke
        [act_n_comp + 1] - Sink_arr[act_n_comp].v * dt.v / Dicke[act_n_comp]
    else if (Untere_Randb = NoFlow) then
      { No Flow Fluß-Randbedingung }
      B_vektor[n_comp] := theta_arr[n_comp].v + Ku_fact[n_comp] / Dicke[n_comp]
        - WflowInt_arr[n_comp + 1].v / Dicke[n_comp] - Sink_arr[n_comp]
        .v * dt.v / Dicke[n_comp]
    else if ShowWarnings then
      showmessage('Lower Boundary not defined!');
    lower[act_n_comp] := -Dw_fact[act_n_comp] / Dicke[act_n_comp];
    diag[act_n_comp] := Dw_fact[act_n_comp] / Dicke[act_n_comp] + Dw_fact
      [act_n_comp + 1] / Dicke[act_n_comp + 1] + 1.0;
  end;

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
  begin
    result := trdiag(false, act_n_comp, start, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then
        showmessage('Fehler beim Lösen des Gleichungssystems');
    if (Untere_Randb = Groundwatertable) then
      for i := n_comp downto act_n_comp + 1 do
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
    if (Untere_Randb = ConstContent) or (Untere_Randb = FreeFlow) then
    begin
      for i := 2 to act_n_comp + 1 do
      begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i])
          / Abst[i - 1] + avg_Ku[i];
      end;
    end;

    if (Untere_Randb = Groundwatertable) then
    begin

      for i := 2 to act_n_comp + 1 do
      begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i])
          / Abst[i - 1] + avg_Ku[i];
      end;

      for i := act_n_comp + 1 to n_comp do
      begin
        GW_inflow[i + 1] := (theta_neu[i] - WPar[i].b_sat) * Dicke[i] / dt.v;
        theta_neu[i] := WPar[i].b_sat;
      end;

      for i := act_n_comp + 2 to n_comp + 1 do
      begin
        WflowInt_arr[i].v := WflowInt_arr[i - 1].v + GW_inflow[i];
      end;
    end;
	if wet then begin  // inflow higher than max. infiltration, infiltration is at its maximum value
	 infilbalance := DayFlow1 - MaxInfil; // in [cm/d]
   //infilbalance := - MaxInfil; // in [cm/d]
	 infilbalance := infilbalance * 10 * dt.v; // change into [mm]
	   if Infilbalance < 0.0 then   // more infiltration than DayFlow
		   PondedWater.v := PondedWater.v + Infilbalance
		 else begin   // not all water can infiltrate ...
		   PondCapa := PondMax.v - PondedWater.v;  // in [mm]
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
      //PondDischargeRate := MaxInfil - DayFlow1; // MaxFlow1-DayFlow1;
      //PondDischargeRate := PondDischargeRate ;
      PondDischargeRate := min(PondMax.v,PondedWater.v)*dt.v ;
      {if(PondDischargeRate > 10) then       //xxx
      PondedWater.v   := max(0, PondedWater.v - 10*PondDischargeRate*dt.v)
      else}
      //PondedWater.v   := max(0, PondedWater.v - 10*PondDischargeRate*dt.v);
      PondedWater.v   := max(0, PondedWater.v - PondDischargeRate);
    end;
  end;

begin { procedure Diffwater_solut }
  if(flag_cascadic = false) then get_water_contents;
  get_new_dt;
  success := false;
  repeat
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
    get_new_dt;
  until (success);
  if(flag_cascadic = false) then Find_flows;
  if(flag_cascadic = false) then calcoverflow;
  if(flag_cascadic = false) then get_bilanz;
  if(flag_cascadic = false) then set_new_state_vars;
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
        P[i] := dt.v / (c_arr[i] * Dicke[i]);
      kf[i] := avg_Ku[i] / Abst[i];
    end;
    kf[0] := 2*avg_Ku[0]/Abst[1];
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
          avg_Ku[i] := 0.0;
          Ku_fact[i] := 0.0;
          //P[i] := 0.0;
          kf[i] := 0.0;
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
      MaxInfil :=  2.0*avg_ku[0]*((psi_neu[1]-psi_top)/Dicke[1])+avg_ku[0];
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

      diag[1] := -ku_arr[1]/Abst[1]*2*P[1]    // tension induced flow into first layer
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
    if (Untere_Randb = ConstContent) or (Untere_Randb = Groundwatertable) or
      (Untere_Randb = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      B_vektor[n_comp] := psi_arr[n_comp].v
                         + P[n_comp] * (avg_Ku[n_comp - 1] - avg_Ku[n_comp])
                         - wf[n_comp]*psi_arr[n_comp + 1].v * kf[n_comp] * P[n_comp]
                         - Sink_arr[n_comp].v * P[n_comp];
    end
    else if (Untere_Randb = NoFlow) then
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
    if (Untere_Randb = Groundwatertable) then
      for i := n_comp downto act_n_comp + 1 do
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
        ((psi_neu[i] - psi_neu[i - 1]) / Abst[i - 1] ) + avg_ku[i-1];

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

    if Untere_Randb = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;
  end;

begin { procedure Richardswater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  repeat
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
    get_new_dt;
  until (success);
  Find_flows;
 // calcoverflow;
  get_bilanz;
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
    Res[1] := WflowInt_arr[1].v / Dicke[1] // Fluxcondition, known
      - avg_Ku[1] / (Dicke[1] * Abst[1]) * (psi_arr[2].v - psi_arr[1].v)
    // pressure induced flow to second layer
      - (avg_Ku[1]) / Dicke[1] // gravitational flow induced to second layer
      - (theta_neu[1] - theta_arr[1].v) / dt.v // soil water change
      - Sink_arr[1].v / (Dicke[1]); // sink
    alpha[1] := 0.0;
    beta[1] := c_arr[1] / dt.v + (avg_Ku[1]) / (Abst[1] * Dicke[1]);
    gamma[1] := -avg_Ku[1] / (Abst[1] * Dicke[1]);
  end;

  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do
    begin
      Res[i] := avg_Ku[i - 1] / (Dicke[i] * Abst[i]) *
        (psi_arr[i].v - psi_arr[i - 1].v) // inflow from upper layer
        - avg_Ku[i] / (Dicke[i] * Abst[i]) * (psi_arr[i + 1].v - psi_arr[i].v)
      // outflow to lower layer
        + (avg_Ku[i - 1] - avg_Ku[i]) / Dicke[i] // gravitational flows
        - (theta_neu[i] - theta_arr[i].v) / dt.v // soil water change
        - Sink_arr[i].v / (Dicke[i]); // sink term
      alpha[i] := -avg_Ku[i - 1] / (Abst[i] * Dicke[i]);
      beta[i] := c_arr[i] / dt.v + (avg_Ku[i - 1] + avg_Ku[i]) /
        (Abst[i] * Dicke[i]);
      gamma[i] := -avg_Ku[i] / (Abst[i] * Dicke[i]);
    end;
  end;

  procedure untere_Randbedingung;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (Untere_Randb = ConstContent) or (Untere_Randb = Groundwatertable) or
      (Untere_Randb = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      Res[n_comp] := avg_Ku[n_comp - 1] / (Dicke[n_comp] * Abst[n_comp]) *
        (psi_arr[n_comp].v - psi_arr[n_comp - 1].v) - avg_Ku[n_comp] /
        (Dicke[n_comp] * Abst[n_comp + 1]) *
        (psi_arr[n_comp + 1].v - psi_arr[n_comp].v) +
        (avg_Ku[n_comp - 1] - avg_Ku[n_comp]) / Dicke[n_comp] -
        (theta_neu[n_comp] - theta_arr[n_comp].v) / dt.v - Sink_arr[n_comp]
        .v / (Dicke[n_comp]);
    end
    else if (Untere_Randb = NoFlow) then
    begin
      // No Flow Fluß-Randbedingung }

      Res[n_comp] := avg_Ku[n_comp - 1] / (Dicke[n_comp] * Abst[n_comp]) *
        (psi_arr[n_comp].v - psi_arr[n_comp - 1].v) // inflow from upper layer
        + (avg_Ku[n_comp - 1]) / Dicke[n_comp]
      // gravitational flow into the layer
        - (theta_neu[n_comp] - theta_arr[n_comp].v) / dt.v // soil water change
        - Sink_arr[n_comp].v / (Dicke[n_comp]);

    end
    else if ShowWarnings then
      showmessage('Lower Boundary not defined!');

    alpha[n_comp] := -avg_Ku[n_comp - 1] / (Abst[n_comp] * Dicke[n_comp]);
    beta[n_comp] := c_arr[n_comp] / dt.v +
      (avg_Ku[n_comp - 1] + avg_Ku[n_comp]) / (Abst[n_comp] * Dicke[n_comp]);
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
    if (Untere_Randb = Groundwatertable) then
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
        ((psi_neu[i] - psi_neu[i - 1]) / Abst[i - 1] + 1);
    if start = 2 then
      WflowInt_arr[1].v := WflowInt_arr[2].v;
    if (dry and (WflowInt_arr[1].v < WflowInt_arr[2].v)) or
      (wet and (WflowInt_arr[1].v > WflowInt_arr[2].v)) then
    begin
      WflowInt_arr[1].v := WflowInt_arr[2].v;
      Wflow_alt[1] := Wflow_alt[2];
    end;
    if Untere_Randb = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;

  end;

begin { procedure Mixedwater_solut }
  get_water_contents;
  get_new_dt;
  success := false;
  repeat
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
    get_new_dt;
  until (success);
  Find_flows;
 // calcoverflow;
  get_bilanz;
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
      kf[i] := avg_Ku[i] / Abst[i];
      P[i] := (c_arr[i] * Dicke[i]) / dt.v;
    end;

    kf[0] := 2*avg_Ku[0]/Abst[1];
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
        MaxInfil :=  2.0*avg_ku[0]*((psi_neu[1]-psi_top)/Dicke[1])+avg_ku[0];
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
                  - (theta_neu[1] - theta_arr[1].v) * Dicke[1] / dt.v // soil water change
                  - Sink_arr[1].v; // sink
        alpha[1] := 0.0;
        beta[1] := P[1] - kf[1];
        gamma[1] := kf[1];

      end
    else begin    // fixed tension on soil surface

      Res[1] := psi_neu[1] * P[1]
                + avg_Ku[0] - avg_Ku[1]  // gravitational flows
                + psi_top*kf[0]
                - (theta_neu[1] - theta_arr[1].v) * Dicke[1] / dt.v // soil water change
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
        - (theta_neu[i] - theta_arr[i].v) * Dicke[i] / dt.v // soil water change
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
    if (Untere_Randb = ConstContent) or (Untere_Randb = Groundwatertable) or
      (Untere_Randb = FreeFlow) then
    begin
      { Gehalts-Randbedingungen }
      Res[n_comp] := psi_neu[n_comp] * P[n_comp]
                    + avg_Ku[n_comp - 1]  // gravitational inflow
                    - avg_Ku[n_comp]      // gravitational outflow
                    - kf[n_comp] * psi_neu[n_comp + 1] // tension induce flow to bottom layer
                    -(theta_neu[n_comp] - theta_arr[n_comp].v)*Dicke[n_comp]/dt.v  // water balance term
                    - Sink_arr[n_comp].v;

      beta[n_comp] := P[n_comp]
                    - kf[n_comp - 1] // tension induced inflow from upper layer
                    - kf[n_comp];    // tension induce i


    end
    else if (Untere_Randb = NoFlow) then
    begin
      // No Flow Fluß-Randbedingung }
      Res[n_comp] := psi_neu[n_comp] * P[n_comp]
                   + avg_Ku[n_comp - 1]
                   -(theta_neu[n_comp] - theta_arr[n_comp].v)*Dicke[n_comp]/dt.v
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
    if (Untere_Randb = Groundwatertable) then
      for i := n_comp downto act_n_comp + 1 do
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
        ((psi_neu[i] - psi_neu[i - 1]) / Abst[i - 1] ) + avg_ku[i-1];

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

    if Untere_Randb = NoFlow then
      WflowInt_arr[n_comp + 1].v := 0.0;
    if (Untere_Randb = Groundwatertable) then
    begin

      for i := act_n_comp + 1 to n_comp do
      begin
        GW_inflow[i + 1] := (theta_neu[i] - WPar[i].b_sat) * Dicke[i] / dt.v;
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
  repeat
    Leitfaehigkeiten;
    obere_Randbedingung;
    Mittelteil;
    untere_Randbedingung;
    Loesung_Gleichungssystem;
    get_delt_iter_max;
    if (DebugForm <> NIL) and Debugmodus then
      DebugForm.update;
    get_new_dt;
  until (success);
  Find_flows;
//  calcoverflow;
  get_bilanz;
  set_new_state_vars;
end;
{ -------------------------------------------------------------------------- }

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterMod]);
end;

end.


