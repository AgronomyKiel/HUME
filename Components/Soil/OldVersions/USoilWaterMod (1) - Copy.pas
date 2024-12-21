unit USoilWaterMod; {Stand 19.4.09, Grundwasser eingebaut - Ulf Bˆttcher}

interface

uses
  UMod, IniFilesNew, UState, ULayeredSoil, UGenucht, classes, UAbstractSoilHeat,
  UAbstractPlant, USoilTexture;

type
  TVGParsFromTexture = (FromPar, FromTexture);
  TKsFromTexture = TVGParsFromTexture;
  Tact_Evaporation = (red_f, inclExfiltration);
  Tm_model = (Mualem, Burdine, Vereecken);
    // type of model for calculating the parameter 'm' within the van Genuchten model
  TLowerBoundaryCondition = (Flow, content, Groundwatertable);
    // type for specifying lower boundary conditions
  TCompMethod = (Capacity, Potential, Richards);
    // type for specifying computation method
  TnFKCalcMethod = (FromParameter, Input);
    // type for specifying computation method for nFK
  TIniMethod = (Watercontents, Potentials, Parameter);
    // type for initialization method
  Tred_f = (modifiedBeese, Beese1978);
  TSoilWaterParams = array[1..max_comp] of TGenucht;

  TSoilWaterMod = class(TLayeredSoil)
    // Component implementing vertical soil water transport
  private
    FVGParsFromTexture: TVGParsFromTexture;
    FKsFromTexture: TKsFromTexture;
    FTextureClass1, { Bodenart in Horizont 1 bei TVGParsFromTexture = FromTexture}
      FTextureClass2,
      FTextureClass3,
      FTextureClass4: TTextureClass;
    fm_model: Tm_model; // type of m_model used
    fred_f: Tred_f;
    theta_neu: TSoilArray; // neue
    dt_alt, // alte Zeitschrittweite [d]
      MaxAktAenderWaGe, // maximale Wassergehalts‰nderung
      akt_bilanz_f,
      sum_Bilanz_f
      : real;

    ndx_Weff: integer; // index of layer where maximum Weff is reached

    Dw_arr, // Diffusivit‰ten [cm2/d] }
      c_arr, // specific water capacity
      P, // ???
      kf,
      psi_neu,
      Ku_arr, { unges‰ttigte hydraulische Leitf‰higkeiten [cm/d] }
      avg_Dw, { Mittelwert der Diffusivit‰t zwischen 2 Kompartimenten [cm2/d] }
      avg_Ku, { Mittelwert der ungesÑttigten hydr. LeitfÑhigkeit
                            zwischen 2 Kompartimenten [cm/d] }
    Dw_fact,
      Ku_fact,
      B_vektor,
      lower,
      diag,
      upper,
      last_iter_theta, { Wassergehalte bei der letzten Iteration [cm3/cm3 }
      est_theta : TSoilArray;

    PSI_dummy: TVAR; // dummy to set array settings
    CompMethod: TCompMethod;
    IniMethod: TIniMethod;
    nFKCalcMethod: TnFKCalcMethod;
    fWeffOpt: TSource; // Source of Weff

    max_aenderWG: real; // maximale Wassergehalts‰nderung pro Zeitschritt

    FSoilHeatModel: TAbstractSoilHeat;
    fTransferWGs: boolean;

    procedure CapWatSolut;
    procedure get_water_contents;
    procedure Diffwater_solut;
    procedure Richardswater_solut;

  protected
    Untere_Randb: TLowerBoundaryCondition;

    act_n_comp: integer;
      // actual number of layers to be calculated, variable in case of groundwater influence
    SumOfInternalTimeSteps: real;
    Max_dt: real;
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override;
    function ndx_str(i: integer): string;
    function getTexture(i: integer): TTextureClass;


  public
    theta_arr: TSoilvarArray; // Wassergehaltsvektor [cm3/cm3]
    WMenge: TSoilStateArray; // Wassermenge je Schicht [cm]
    psi_arr: TSoilVarArray; // Wasserspannungsvektor [cm]
    Wflow_arr: TSoilVarArray; // Flussvektor [cm/d]
    WflowInt_arr: TSoilVarArray; // Flussvektor [cm/d] f¸r internen Zeitschritt
    Sink_arr: TSoilVarArray; // Sinkvektor [cm]
    SinkInt_arr: TSoilVarArray; // Sinkvektor [cm/d] f¸r internen Zeitschritt
    FK_Arr: TSoilArray; // Feldkapazit‰t [cm3/cm3]
    PWP_Arr: TSoilArray; // permanenter Welkepunkt [cm3/cm3]
    nFK_Arr: TSoilArray; // nutzbare Feldkapazit‰t [cm3/cm3]
    WPar: TSoilWaterParams; // Array der Van-Genuchten Parameter f¸r jede Schicht

    Wflow_alt: TSoilArray; // alte Wasserfl¸sse [cm/d]
    theta_alt: TSoilArray; // alte Wassergehalte

    HoriNdx1,
      HoriNdx2,
      HoriNdx3,
      HoriNdx4: TPar; //Index der untersten Schicht im jeweiligen Horizont

    FVGParsFromTextOption: TOption;
    FKsFromTextOption: TOption;
    act_EvaporationOption: TOption;
    red_fOption: TOption;
  //lowerBoundCond
    OptUntere_Randb: TOption;
    Groundwaterdepth: TExternV;
      // depth of groundwatertable [cm] needed if option is selected

    FTextClass1Option,
      FTextClass2Option,
      FTextClass3Option,
      FTextClass4Option: TTextClassOption;

    bsat_scaling: TPar;
    alpha_scaling: TPar;

// van-Genuchten Parameter fuer Horizont 1
    b_sat1: Tpar; // Wassergehalt bei S‰ttigung [cm3/cm3] }
    b_rest1: Tpar; // "Restwassergehalt" [cm3/cm3] }
    alpha1: TPar; // Fitparameter "" [1/cm] }
    n_par1: TPar; // Fitparameter "n" dimensionslos }
    Ks1: TPar; // ges‰ttigte Leitf‰higkeit [cm.d-1]
    FK1: TPar; // Feldkapazit‰t [cm3/cm3]
    PWP1: TPar; // permanenter Welkepunkt
    nFK1: TPar; // nutzbare Feldkapazit‰t

// van-Genuchten Parameter fuer Horizont 2
    b_sat2: Tpar; // Wassergehalt bei S‰ttigung [cm3/cm3] }
    b_rest2: Tpar; // "Restwassergehalt" [cm3/cm3] }
    alpha2: TPar; // Fitparameter "" [1/cm] }
    n_par2: TPar; // Fitparameter "n" dimensionslos }
    Ks2: TPar; // ges‰ttigte Leitf‰higkeit [cm.d-1]
    FK2: TPar; // Feldkapazit‰t [cm3/cm3]
    PWP2: TPar; // permanenter Welkepunkt
    nFK2: TPar; // nutzbare Feldkapazit‰t

// van-Genuchten Parameter fuer Horizont 3
    b_sat3: Tpar; // Wassergehalt bei S‰ttigung [cm3/cm3] }
    b_rest3: Tpar; // "Restwassergehalt" [cm3/cm3] }
    alpha3: TPar; // Fitparameter "" [1/cm] }
    n_par3: TPar; // Fitparameter "n" dimensionslos }
    Ks3: TPar; // ges‰ttigte Leitf‰higkeit [cm.d-1]
    FK3: TPar; // Feldkapazit‰t [cm3/cm3]
    PWP3: TPar; // permanenter Welkepunkt
    nFK3: TPar; // nutzbare Feldkapazit‰t

// van-Genuchten Parameter fuer Horizont 4
    b_sat4: Tpar; // Wassergehalt bei S‰ttigung [cm3/cm3] }
    b_rest4: Tpar; // "Restwassergehalt" [cm3/cm3] }
    alpha4: TPar; // Fitparameter "" [1/cm] }
    n_par4: TPar; // Fitparameter "n" dimensionslos }
    Ks4: TPar; // ges‰ttigte Leitf‰higkeit [cm.d-1]
    FK4: TPar; // Feldkapazit‰t [cm3/cm3]
    PWP4: TPar; // permanenter Welkepunkt
    nFK4: TPar; // nutzbare Feldkapazit‰t

    PsiStart1: TPar;
      // For initalisation of Soil water contents and suction values

    bil_nr: TPar; // Index of Layer where lower boundary fluxes are calculated
    Weff: TPar; // effective rooting deph [cm]

    psi_critEvap: TPar; // Wasserspannung ab der Evaporation abnimmt [hPa]

    NetRain: TExternV;
      //THumeNumEntity;              //  NetRain = Niederschlag - Interzeption
    CumNetRain: TState; // kumulativer Niederschlag [mm]
    Pot_Evap: THumeNumEntity; //  potentielle Evaporationsrate

    red_evap: TVar; // Reduktionsfaktor f¸r Evaporation
    Act_Evap: Tvar; // aktuelle Evaporationsrate
    Exfiltration: TVar; // Estimation of maximum exfiltration rate
    CumEvap: TState; // kumulative Evaporation
    CumDrainage: TState;
      // kumulative Sickerwasserspende/kapillarer Aufstieg [mm]
    CumWaterBalance: TState; // kumulative Bilanz [mm] zur Kontrolle!
    CumRunoff: TState;

    SumSoilWater, // sum of soil water down to boundary given by the Par "bil_nr"
      SumPAVSoilWater: TVar;
        // sum of plant available soil water down to boundary given by the Par "bil_nr"
    SumPAvSoilWaterRZ: TVar;
      // sum of plant available soil water in the rooting zone (down to Weff)
    dt: TVar; // interne Zeitschrittweite des Diff. Wassertransportmodells
    n_int_timesteps: TVar;
    WG0_30,
      WG30_60,
      WG60_90,
      WG90_120,
      WG0_60,

    WG0_10,
      WG0_20,
      WG10_30,
      WG20_30,
      WG30_40,
      WG30_50,
      WG30_120,
      WG30_100,
      WG40_60,
      WG60_80,
      WG80_100,
      WG90_110,
      WG0_100,
      WG0_120,
      wg0_90,
      WG60_100: TVar;
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

    procedure update_WG_Values;

    function getNetRain: TExternV;
    function getPot_Evap: TExternV;
    property Texture[i:integer]: TTextureClass read getTexture;

  published

    property m_model: Tm_model read fm_model write fm_model;
    property Opt_CompMethod: TCompMethod read CompMethod write CompMethod;
    property Opt_red_f: Tred_f read fred_f write fred_f;
    property Opt_maxWGchange: real read max_aenderWG write max_aenderWG;
    property Opt_Randbed: TLowerBoundaryCondition read Untere_Randb write
      Untere_Randb;
    property Opt_IniMethod: TIniMethod read IniMethod write IniMethod;
    property Opt_maxdt: real read max_dt write max_dt;
    property Opt_nFKCalcMethod: TnFKCalcMethod read nFKCalcMethod write
      nFKCalcMethod;
    property Opt_VanGenPars_from_Texture: TVGParsFromTexture read
      FVGParsFromTexture write FVGParsFromTexture;
    property Opt_Ks_from_Texture: TKsFromTexture read FKsFromTexture write
      FKsFromTexture;
    property Opt_TextureClass1: TTextureClass read FTextureClass1 write
      FTextureClass1;
    property Opt_TextureClass2: TTextureClass read FTextureClass2 write
      FTextureClass2;
    property Opt_TextureClass3: TTextureClass read FTextureClass3 write
      FTextureClass3;
    property Opt_TextureClass4: TTextureClass read FTextureClass4 write
      FTextureClass4;
    property Opt_TransferWGsToNextINI: boolean read fTransferWGs write
      fTransferWGs;
    property Opt_Weff: TSource read fWeffOpt write fWeffOpt;
      //Option for Source of parameter Weff
    property Ext_NetRain: TExternV read getNetRain;
    property Ex_PotEvap: TExternV read getPot_Evap;
    property Ex_Groundwaterdepth: TExternV read Groundwaterdepth write
      Groundwaterdepth;

    property Par_b_sat1: TPar read B_sat1 write b_sat1;
    property Par_b_rest1: TPar read B_rest1 write b_rest1;
    property Par_b_KS1: TPar read KS1 write KS1;
    property Par_n1: TPar read n_par1 write n_par1;
    property Par_alpha1: TPar read alpha1 write alpha1;
    property Par_FK1: TPar read FK1 write FK1; // Feldkapazit‰t [cm3/cm3]
    property Par_PWP1: TPar read PWP1 write PWP1; // permanenter Welkepunkt
    property Par_nFK1: TPar read nFK1; // nutzbare Feldkapazit‰t

    property Par_b_sat2: TPar read B_sat2 write b_sat2;
    property Par_b_rest2: TPar read B_rest2 write b_rest2;
    property Par_b_KS2: TPar read KS2 write KS2;
    property Par_n2: TPar read n_par2 write n_par2;
    property Par_alpha2: TPar read alpha2 write alpha2;
    property Par_FK2: TPar read FK2 write FK2; // Feldkapazit‰t [cm3/cm3]
    property Par_PWP2: TPar read PWP2 write PWP2; // permanenter Welkepunkt
    property Par_nFK2: TPar read nFK2; // nutzbare Feldkapazit‰t

    property Par_b_sat3: TPar read B_sat3 write b_sat3;
    property Par_b_rest3: TPar read B_rest3 write b_rest3;
    property Par_b_KS3: TPar read KS3 write KS3;
    property Par_n3: TPar read n_par3 write n_par3;
    property Par_alpha3: TPar read alpha3 write alpha3;
    property Par_FK3: TPar read FK3 write FK3; // Feldkapazit‰t [cm3/cm3]
    property Par_PWP3: TPar read PWP3 write PWP3; // permanenter Welkepunkt
    property Par_nFK3: TPar read nFK3; // nutzbare Feldkapazit‰t

    property Par_b_sat4: TPar read B_sat4 write b_sat4;
    property Par_b_rest4: TPar read B_rest4 write b_rest4;
    property Par_b_KS4: TPar read KS4 write KS4;
    property Par_n4: TPar read n_par4 write n_par4;
    property Par_alpha4: TPar read alpha4 write alpha4;
    property Par_FK4: TPar read FK4 write FK4; // Feldkapazit‰t [cm3/cm3]
    property Par_PWP4: TPar read PWP4 write PWP4; // permanenter Welkepunkt
    property Par_nFK4: TPar read nFK4; // nutzbare Feldkapazit‰t

    property Par_PsiStart1: TPar read PsiStart1 write PsiStart1;
    property Par_Weff: TPar read Weff write Weff;

    property Var_WG0_30: TVar read WG0_30 write WG0_30;
    property Var_WG30_60: TVar read WG30_60 write WG30_60;
    property Var_WG30_120: TVar read WG30_120 write WG30_120;
    property Var_WG30_100: TVar read WG30_100 write WG30_100;
    property Var_WG60_90: TVar read WG60_90 write WG60_90;
    property Var_WG90_120: TVar read WG90_120 write WG90_120;
    property Var_WG0_100: TVar read WG0_100 write WG0_100;
    property Var_WG0_120: TVar read WG0_120 write WG0_120;
    property Var_WG0_90: TVar read WG0_90 write WG0_90;
    property Var_WG0_60: TVar read WG0_60 write WG0_60;

    property Var_Psi_dummy: TVar read Psi_dummy write Psi_dummy;
    property Var_ActEvap: TVar read Act_Evap write Act_Evap;

    property St_CumEvap: TState read CumEvap write CumEvap;
    property St_CumDrainage: TState read CumDrainage write CumDrainage;
    property St_CumNetRain: TState read CumNetRain write CumNetRain;

    property Par_psi_critEvap: TPar read psi_critEvap write psi_critEvap;

    property Par_Horindx1: TPar read HoriNdx1 write HoriNdx1;
    property Par_Horindx2: TPar read HoriNdx2 write HoriNdx2;
    property Par_Horindx3: TPar read HoriNdx3 write HoriNdx3;
    property Par_Horindx4: TPar read HoriNdx4 write HoriNdx4;

    property SoilHeatModel: TAbstractSoilHeat read fSoilHeatModel write
      FSoilHeatModel;

  end;

procedure Register;

var
  SoilWaterMod: TSoilWaterMod;

implementation

uses
  SysUtils, Math, Dialogs;

procedure TSoilWaterMod.update_WG_Values;
var
  i: Integer;
begin
  // Berechnung der abgeleiteten Wassergehalte f¸r verschiedene Bodenschichten

  WG0_30.v := (theta_arr[1].v + theta_arr[2].v + theta_arr[3].v) / 3;
  WG30_60.v := (theta_arr[4].v + theta_arr[5].v + theta_arr[6].v) / 3;
  WG60_90.v := (theta_arr[7].v + theta_arr[8].v + theta_arr[9].v) / 3;
  WG90_120.v := (theta_arr[10].v + theta_arr[11].v + theta_arr[12].v) / 3;

  WG0_10.v := theta_arr[1].v;
  WG20_30.v := theta_arr[3].v;
  WG30_40.v := theta_arr[4].v;

  WG0_20.v := (theta_arr[1].v + theta_arr[2].v) / 2;
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
  WG30_120.v := 0;
  WG30_100.v := 0;
  WG60_100.v := 0;

  for i := 4 to 12 do
    WG30_120.v := WG30_120.v + theta_arr[i].v;
  for i := 4 to 10 do
    WG30_100.v := WG30_100.v + theta_arr[i].v;
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
  wg0_90.v := wg0_90.v / 9;
  WG0_100.v := WG0_100.v / 10;
  WG0_120.v := WG0_120.v / 12;
  WG30_100.v := WG30_100.v / 7;
  WG30_120.v := WG30_120.v / 9;
  WG60_100.v := WG60_100.v / 4;

end;

function TSoilWaterMod.ndx_str(i: integer): string;
begin
  if i <= 9 then result := '_' + IntTostr(i) else result := IntTostr(i);
end;

function TSoilWaterMod.getTexture(i: integer): TTextureClass;
begin
  result := FTextureClass4;
  if i <= HoriNdx3.v then result := FTextureClass3;
  if i <= HoriNdx2.v then result := FTextureClass2;
  if i <= HoriNdx1.v then result := FTextureClass1;
end;


procedure TSoilWaterMod.CreateAll;

var
  i: integer;
//  ndx_str: string;

begin
  inherited createAll;
  m_model := mualem;
  ParCreate('bil_nr', '[]', 12, bil_nr); // Index f¸r Bilanzierung

  for i := 1 to n_comp + 1 do
    if WPar[i] = nil then
      Wpar[i] := TGenucht.create;

  ParCreate('HoriNdx1', '[-]', 3, HoriNdx1,
    'unterste Schicht des 1. Bodenhorizonts');
  ParCreate('HoriNdx2', '[-]', 6, HoriNdx2,
    'unterste Schicht des 2. Bodenhorizonts');
  ParCreate('HoriNdx3', '[-]', 10, HoriNdx3,
    'unterste Schicht des 3. Bodenhorizonts');
  ParCreate('HoriNdx4', '[-]', 20, HoriNdx4,
    'unterste Schicht des 4. Bodenhorizonts');

  ParCreate('bsat_scaling', '[-]', 1, bsat_scaling,
    'Skalierungsfaktor f¸r bsat (wird in allen Horizonten mit diesem Faktor multipliziert)');
  ParCreate('alpha_scaling', '[-]', 1, alpha_scaling);

  ParCreate('b_sat1', '[cm3.cm-3]', 0.4298, b_sat1);
  ParCreate('b_rest1', '[cm3.cm-3]', 0.09, b_rest1);
  ParCreate('alpha1', '[1/cm]', 0.00677, alpha1,
    'Van-Genuchten-Parameter alpha f¸r den 1. Bodenhorizont');
  ParCreate('n_par1', '[-]', 1.29494, n_par1);
  ParCreate('Ks_1', '[-]', 50.0, Ks1);
  ParCreate('FK_1', '[cm3/cm3]', 0.35, fk1);
  ParCreate('nFK_1', '[cm3/cm3]', 0.25, nfk1);
  ParCreate('PWP_1', '[cm3/cm3]', 0.1, PWP1);

  ParCreate('b_sat2', '[cm3.cm-3]', 0.45, b_sat2);
  ParCreate('b_rest2', '[cm3.cm-3]', 0.09, b_rest2);
  ParCreate('alpha2', '[1/cm]', 0.00677, alpha2);
  ParCreate('n_par2', '[-]', 1.29494, n_par2);
  ParCreate('Ks_2', '[-]', 50.0, Ks2);
  ParCreate('FK_2', '[cm3/cm3]', 0.35, fk2);
  ParCreate('nFK_2', '[cm3/cm3]', 0.25, nfk2);
  ParCreate('PWP_2', '[cm3/cm3]', 0.1, PWP2);

  ParCreate('b_sat3', '[cm3.cm-3]', 0.45, b_sat3);
  ParCreate('b_rest3', '[cm3.cm-3]', 0.09, b_rest3);
  ParCreate('alpha3', '[1/cm]', 0.00677, alpha3);
  ParCreate('n_par3', '[-]', 1.29494, n_par3);
  ParCreate('Ks_3', '[-]', 50.0, Ks3);
  ParCreate('FK_3', '[cm3/cm3]', 0.35, fk3);
  ParCreate('nFK_3', '[cm3/cm3]', 0.25, nfk3);
  ParCreate('PWP_3', '[cm3/cm3]', 0.1, PWP3);

  ParCreate('b_sat4', '[cm3.cm-3]', 0.45, b_sat4);
  ParCreate('b_rest4', '[cm3.cm-3]', 0.09, b_rest4);
  ParCreate('alpha4', '[1/cm]', 0.00677, alpha4);
  ParCreate('n_par4', '[-]', 1.29494, n_par4);
  ParCreate('Ks_4', '[-]', 50.0, Ks4);
  ParCreate('FK_4', '[cm3/cm3]', 0.35, fk4);
  ParCreate('nFK_4', '[cm3/cm3]', 0.25, nfk4);
  ParCreate('PWP_4', '[cm3/cm3]', 0.1, PWP4);

  ParCreate('PsiStart1', '[cm]', 500, PsiStart1);
  ParCreate('Weff', '[cm]', 100, Weff, 'effective rooting deph [cm]');

  OptCreate('FVGParsFromTexture', 'FromPar', FVGParsFromTextOption);
  FVGParsFromTextOption.OptionList.Clear;
  FVGParsFromTextOption.OptionList.Add('FromPar');
  FVGParsFromTextOption.OptionList.Add('FromTexture');
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
  OptCreate('Untere_Randb', 'content', OptUntere_Randb);
  OptUntere_Randb.OptionList.Add('content');
  OptUntere_Randb.OptionList.Add('noFlux');
  OptUntere_Randb.OptionList.Add('Groundwater');
  ExternVCreate('Groundwaterdepth', '[cm]', StateField, Groundwaterdepth);
  if untere_Randb = Groundwatertable then Groundwaterdepth.Search := true
  else Groundwaterdepth.Search := false;

  ParCreate('psi_critEvap', '[hPa]', 500.0, psi_critEvap);
  StateCreate('CumEvap', '[mm]', 0, true, CumEvap);
  StateCreate('CumDrainage', '[mm]', 0, true, CumDrainage);
  StateCreate('CumWaterBalance', '[mm]', 0, true, CumWaterBalance);
  StateCreate('CumRunoff', '[mm]', 0, true, CumRunoff);

  VarCreate('Exfiltration', '[mm]', 0.0, true, Exfiltration);

  VarCreate('SumSoilWater', '[mm]', 0.0, true, SumSoilWater);
  VarCreate('SumPavSoilWater', '[mm]', 0.0, true, SumPavSoilWater);
  VarCreate('SumPAvSoilWaterRZ', '[mm]', 0.0, true, SumPAvSoilWaterRZ,
    'sum of plant available soil water in the rooting zone (down to Weff)');
  VarCreate('psi_dummy', '[]', 0.0, true, psi_dummy);
  VarCreate('n_int_timesteps', '[]', 0.0, true, n_int_timesteps);

  StateCreate('CumNetRain', '[mm]', 0, true, CumNetRain);
 // if not (Netrain is TVar) then
  ExternVCreate('NetRain', '[mm/d]', StateField, TExternV(Netrain));
  if not (Pot_Evap is TVar) then
    ExternVCreate('PotEvap', '[mm/d]', StateField, TExternV(Pot_evap));

  for i := 1 to n_comp + 1 do begin
{    if i <= 9 then
      ndx_str := '_' + IntTostr(i)
    else
      ndx_str := IntTostr(i);}
    Varcreate('WG' + ndx_str(i), '[cm3.cm-3]', 0.3, true, theta_arr[i]);
    Theta_arr[i].readFromFile := true;
    StateCreate('WMenge' + ndx_str(i), '[cm]', Theta_arr[i].v * Dicke[i], false,
      WMenge[i]);
    WMenge[i].readFromFile := false;
    //Wmenge[i].writetoFile := false;
    VarCreate('Psi' + ndx_str(i), '[cm]', WPar[i].psi_b_f(theta_arr[i].v), true,
      psi_arr[i]);
    VarCreate('WFlowInt' + ndx_str(i), '[cm.d-1]', 0.0, false, WflowInt_arr[i]);
    WflowInt_arr[i].writetoFile := false;
    VarCreate('WFlow' + ndx_str(i), '[cm.d-1]', 0.0, false, Wflow_arr[i]);
    Wflow_arr[i].writeToFile := true;
    VarCreate('Sink' + ndx_str(i), '[cm.d-1]', 0.0, false, Sink_arr[i]);
    VarCreate('SinkInt_' + ndx_str(i), '[cm.d-1]', 0.0, false, SinkInt_arr[i]);
    SinkInt_arr[i].WriteToFile := false;
  end;
  VarCreate('red_evap', '[]', 1.0, false, red_evap);
  VarCreate('act_evap', '[mm/d]', 0.0, false, act_evap);
  VarCreate('dt_int', '[d]', 0.1, false, dt);

  Untere_Randb := content;
  for i := 1 to n_comp + 1 do
    theta_alt[i] := theta_arr[i].v;

  for i := 1 to n_comp + 1 do begin
    WMenge[i].v := Theta_arr[i].v * Dicke[i];
    theta_alt[i] := theta_arr[i].v;
  end;
  VarCreate('WG0_30', '[cm3/cm3]', 0.0, false, WG0_30);
  VarCreate('WG30_60', '[cm3/cm3]', 0.0, false, WG30_60);
  VarCreate('WG60_90', '[cm3/cm3]', 0.0, false, WG60_90);
  VarCreate('WG90_120', '[cm3/cm3]', 0.0, false, WG90_120);
  VarCreate('WG0_60', '[cm3/cm3]', 0.0, false, WG0_60);
  VarCreate('WG0_10', '[cm3/cm3]', 0.0, false, WG0_10);
  VarCreate('WG0_20', '[cm3/cm3]', 0.0, false, WG0_20);
  VarCreate('WG10_30', '[cm3/cm3]', 0.0, false, WG10_30);
  VarCreate('WG20_30', '[cm3/cm3]', 0.0, false, WG20_30);
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
  VarCreate('WG0_90', '[cm3/cm3]', 0.0, false, WG0_90);
  VarCreate('WG60_100', '[cm3/cm3]', 0.0, false, WG60_100);
  VarCreate('ProzNFK0_Weff', '[%]', 0.0, false, ProzNFK0_Weff);
  VarCreate('ProzNFK0_100', '[%]', 0.0, false, ProzNFK0_100);
  VarCreate('ProzNFK0_30', '[%]', 0.0, false, ProzNFK0_30,
    'Anteil pflanzenverf¸gbares Wasser an der nFK in Prozent');

  Untere_Randb := content;

end;

function TSoilWaterMod.getNetRain: TExternV;
begin
  if NetRain is TExternV then
    result := TExternV(NetRain)
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
  ndx_weff := 0;
  if (fWeffOpt = fromPlantmodel) and IsPlantModelSet then begin
    repeat
      inc(ndx_weff);
    until (tiefe[ndx_weff].v >= Plantmodel.Weff) or (ndx_weff >= n_comp + 1);
  end else begin
    repeat
      inc(ndx_weff);
    until (tiefe[ndx_weff].v >= Weff.v) or (ndx_weff >= n_comp + 1);
  end;
end;

procedure TSoilWaterMod.Init(var GlobMod: TMod);
var
  i: integer;
  error: boolean;
  psiWP, psiFK: real;
  nFK0_Weff, PWP0_Weff, WG0_Weff: real;
  nFK0_100, PWP0_100: real;

begin
  inherited Init(GlobMod);
  MaxAktAenderWaGe := 0.0; // hp & ar 07.01.2010  !
  dt_alt := dt.v;
  red_evap.v := 1.0;
  act_evap.v := 0.0;
  dt.v := 0.1;
  dt_alt := dt.v;
  max_dt := globmod.Time.c; // value of maximum timestep
  // hk 25.1.01: sollte eigentlich ¸ber die Property einzustellen sein ...
  // keine Ahnung wer das reingeschrieben hatte ...
//  max_aenderWG := 0.01; // maximale Wassergehalts‰nderung pro Zeitschritt

  for i := 1 to n_comp + 1 do begin
    psi_arr[i].Digits := psi_dummy.Digits;
    psi_arr[i].Precision := psi_dummy.Precision;
  end;

  for i := 1 to round(Horindx1.v) do begin
    WPar[i].b_sat := b_sat1.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest1.v;
    WPar[i].alpha := alpha1.v * alpha_scaling.v;
    Wpar[i].n_par := n_par1.v;
    case m_model of
      Mualem: WPar[i].m_par := 1 - 1 / n_par1.v;
      Burdine: WPar[i].m_par := 1 - 2 / n_par1.v;
      Vereecken: WPar[i].m_par := 1;
    end;
    WPar[i].l_par := 0.5;
    WPar[i].Ks := Ks1.v;
  end;

  for i := round(Horindx1.v) + 1 to round(Horindx2.v) do begin
    WPar[i].b_sat := b_sat2.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest2.v;
    WPar[i].alpha := alpha2.v * alpha_scaling.v;
    Wpar[i].n_par := n_par2.v;
    case m_model of
      Mualem: WPar[i].m_par := 1 - 1 / n_par2.v;
      Burdine: WPar[i].m_par := 1 - 2 / n_par2.v;
      Vereecken: WPar[i].m_par := 1;
    end;
    WPar[i].l_par := 0.5;
    WPar[i].Ks := Ks2.v;
  end;

  for i := round(Horindx2.v) + 1 to round(Horindx3.v) do begin
    WPar[i].b_sat := b_sat3.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest3.v;
    WPar[i].alpha := alpha3.v * alpha_scaling.v;
    Wpar[i].n_par := n_par3.v;
    case m_model of
      Mualem: WPar[i].m_par := 1 - 1 / n_par3.v;
      Burdine: WPar[i].m_par := 1 - 2 / n_par3.v;
      Vereecken: WPar[i].m_par := 1;
    end;
    WPar[i].l_par := 0.5;
    WPar[i].Ks := Ks3.v;
  end;

  for i := round(Horindx3.v) + 1 to n_comp + 1 do begin
    WPar[i].b_sat := b_sat4.v * bsat_scaling.v;
    WPar[i].b_rest := b_rest4.v;
    WPar[i].alpha := alpha4.v * alpha_scaling.v;
    Wpar[i].n_par := n_par4.v;
    case m_model of
      Mualem: WPar[i].m_par := 1 - 1 / n_par4.v;
      Burdine: WPar[i].m_par := 1 - 2 / n_par4.v;
      Vereecken: WPar[i].m_par := 1;
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

  if FVGParsFromTexture = FromTexture then begin
    for i := 1 to round(Horindx1.v) do begin
      VanGenuchtenFromTextureClass(WPar[i], FTextureClass1);
      WPar[i].Ks := Ks1.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine: WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken: WPar[i].m_par := 1;
      end;
    end;
    for i := round(Horindx1.v) + 1 to round(Horindx2.v) do begin
      VanGenuchtenFromTextureClass(WPar[i], FTextureClass2);
      WPar[i].Ks := Ks2.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine: WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken: WPar[i].m_par := 1;
      end;
    end;
    for i := round(Horindx2.v) + 1 to round(Horindx3.v) do begin
      VanGenuchtenFromTextureClass(WPar[i], FTextureClass3);
      WPar[i].Ks := Ks3.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine: WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken: WPar[i].m_par := 1;
      end;
    end;
    for i := round(Horindx3.v) + 1 to n_comp + 1 do begin
      VanGenuchtenFromTextureClass(WPar[i], FTextureClass4);
      WPar[i].Ks := Ks4.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / WPar[i].n_par;
        Burdine: WPar[i].m_par := 1 - 2 / WPar[i].n_par;
        Vereecken: WPar[i].m_par := 1;
      end;
    end;
  end else begin {FVGParsFromTexture = FromPar}
    for i := 1 to round(Horindx1.v) do begin
      WPar[i].b_sat := b_sat1.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest1.v;
      WPar[i].alpha := alpha1.v * alpha_scaling.v;
      Wpar[i].n_par := n_par1.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / n_par1.v;
        Burdine: WPar[i].m_par := 1 - 2 / n_par1.v;
        Vereecken: WPar[i].m_par := 1;
      end;
      WPar[i].l_par := 0.5;
      WPar[i].Ks := Ks1.v;
    end;

    for i := round(Horindx1.v) + 1 to round(Horindx2.v) do begin
      WPar[i].b_sat := b_sat2.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest2.v;
      WPar[i].alpha := alpha2.v * alpha_scaling.v;
      Wpar[i].n_par := n_par2.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / n_par2.v;
        Burdine: WPar[i].m_par := 1 - 2 / n_par2.v;
        Vereecken: WPar[i].m_par := 1;
      end;
      WPar[i].l_par := 0.5;
      WPar[i].Ks := Ks2.v;
    end;

    for i := round(Horindx2.v) + 1 to round(Horindx3.v) do begin
      WPar[i].b_sat := b_sat3.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest3.v;
      WPar[i].alpha := alpha3.v * alpha_scaling.v;
      Wpar[i].n_par := n_par3.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / n_par3.v;
        Burdine: WPar[i].m_par := 1 - 2 / n_par3.v;
        Vereecken: WPar[i].m_par := 1;
      end;
      WPar[i].l_par := 0.5;
      WPar[i].Ks := Ks3.v;
    end;

    for i := round(Horindx3.v) + 1 to n_comp + 1 do begin
      WPar[i].b_sat := b_sat4.v * bsat_scaling.v;
      WPar[i].b_rest := b_rest4.v;
      WPar[i].alpha := alpha4.v * alpha_scaling.v;
      Wpar[i].n_par := n_par4.v;
      case m_model of
        Mualem: WPar[i].m_par := 1 - 1 / n_par4.v;
        Burdine: WPar[i].m_par := 1 - 2 / n_par4.v;
        Vereecken: WPar[i].m_par := 1;
      end;
      WPar[i].l_par := 0.5;
      WPar[i].Ks := Ks4.v;
    end;
  end;

  if FKsFromTexture = FromTexture then begin
    for i := 1 to round(Horindx1.v) do
      WPar[i].Ks := KSFromTextureClass(FTextureClass1);
    for i := round(Horindx1.v) + 1 to round(Horindx2.v) do
      WPar[i].Ks := KSFromTextureClass(FTextureClass2);
    for i := round(Horindx2.v) + 1 to round(Horindx3.v) do
      WPar[i].Ks := KSFromTextureClass(FTextureClass3);
    for i := round(Horindx3.v) + 1 to n_comp + 1 do
      WPar[i].Ks := KSFromTextureClass(FTextureClass4);
  end;

  if self.Opt_IniMethod = WaterContents then begin
    for i := 1 to n_comp + 1 do begin
      if Theta_arr[i].wasreadfromfile = false then
        begin // if initial water content was only measured in upper horizons, it is assumed that psi is decreasing according to layer depth
        if i > 1 then
          psi_arr[i].v := max(10, psi_arr[i - 1].v - Dicke[i]) else
            // to avoid saturation ...
          psi_arr[i].v := Dicke[i] / 2;
        theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      end else
        psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
      globmod.StateIniFile.WriteFloat(self.name, psi_arr[i].name, psi_arr[i].v);
      WMenge[i].v := Theta_arr[i].v * Dicke[i];
      theta_alt[i] := theta_arr[i].v
    end
  end else if self.Opt_IniMethod = Potentials then begin
    for i := 1 to n_comp + 1 do begin
      psi_arr[i].v := globmod.StateIniFile.ReadFloat(self.name, psi_arr[i].name,
        100);
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      globmod.StateIniFile.WriteFloat(name, theta_arr[i].name, theta_arr[i].v);
      WMenge[i].v := Theta_arr[i].v * Dicke[i];
      theta_alt[i] := theta_arr[i].v
    end
  end else if self.Opt_IniMethod = Parameter then begin
    for i := 1 to n_comp + 1 do begin
      psi_arr[i].v := PsiStart1.v - (i - 1) * 10;
      theta_arr[i].v := WPar[i].b_psi_f(psi_arr[i].v);
      globmod.StateIniFile.WriteFloat(name, theta_arr[i].name, theta_arr[i].v);
      WMenge[i].v := Theta_arr[i].v * Dicke[i];
      theta_alt[i] := theta_arr[i].v
    end;

  end;

  psiWP := power(10, 4.2);
  psiFK := power(10, 1.8);

  red_evap.v := 1.0;
  act_evap.v := 0.0;
  CumEvap.v := 0.0;
  CumDrainage.v := 0.0;
  dt.v := 0.1;
  dt_alt := dt.v;
  Untere_Randb := Content;

  if round(Horindx1.v) = 0 then begin
    showmessage('Warning ! No specification of Indexes for hydraulic parameters');
    showmessage('Please check !');
  end;

  if Opt_nFKCalcMethod = FromParameter then begin
{Berechnung von FK, PWP und nFK aus van-Genuchten-Parametern mit der Funktion b_psi_f (unit UGenucht)}

    Par_FK1.v := WPar[round(Horindx1.v)].b_psi_f(power(10, 1.8));
    Par_PWP1.v := WPar[round(Horindx1.v)].b_psi_f(power(10, 4.2));
    Par_nFK1.v := Par_fk1.v - par_PWP1.v;

    Par_FK2.v := WPar[round(Horindx2.v)].b_psi_f(power(10, 1.8));
    Par_PWP2.v := WPar[round(Horindx2.v)].b_psi_f(power(10, 4.2));
    Par_nFK2.v := Par_fk2.v - par_PWP2.v;

    Par_FK3.v := WPar[round(Horindx3.v)].b_psi_f(power(10, 1.8));
    Par_PWP3.v := WPar[round(Horindx3.v)].b_psi_f(power(10, 4.2));
    Par_nFK3.v := Par_fk3.v - par_PWP3.v;

    Par_FK4.v := WPar[round(Horindx4.v)].b_psi_f(power(10, 1.8));
    Par_PWP4.v := WPar[round(Horindx4.v)].b_psi_f(power(10, 4.2));
    Par_nFK4.v := Par_fk4.v - par_PWP4.v;
  end;

  if uppercase(OptUntere_Randb.Option) = 'CONTENT' then Untere_Randb := content;
  if uppercase(OptUntere_Randb.Option) = 'NOFLUX' then Untere_Randb := flow;
  if uppercase(OptUntere_Randb.Option) = 'GROUNDWATER' then
    Untere_Randb := Groundwatertable;
  if Untere_Randb = Groundwatertable then Groundwaterdepth.Search := true
  else Groundwaterdepth.Search := false;

  {Berechnung der abgeleiteten Wassergehalte f¸r verschiedene Bodenschichten}

  // Berechnung der abgeleiteten Wassergehalte f¸r verschiedene Bodenschichten
  update_WG_Values;

  for i := 1 to n_comp do begin
    FK_arr[i] := WPar[i].b_psi_f(psiFK);
    PWP_arr[i] := Wpar[i].b_psi_f(psiWP);
    nFK_arr[i] := fk_arr[i] - pwp_arr[i];
  end;

  nFK0_100 := 0;
  PWP0_100 := 0;
  for i := 1 to 10 do begin
    nFK0_100 := nFK0_100 + nFK_Arr[i];
    PWP0_100 := PWP0_100 + PWP_Arr[i];
  end;
  ProzNFK0_100.v := (WG0_100.v - PWP0_100 / 10) / nFK0_100 * 1000;
  ndx_weff := 0;

  if (fWeffOpt = fromPlantmodel) and IsPlantModelSet then begin
    repeat
      inc(ndx_weff);
    until tiefe[ndx_weff].v >= Plantmodel.Weff;
  end else begin
    repeat
      inc(ndx_weff);
    until tiefe[ndx_weff].v >= Weff.v;
  end;

  nFK0_Weff := 0;
  PWP0_Weff := 0;
  WG0_Weff := 0;
  for i := 1 to ndx_Weff do begin
    WG0_Weff := WG0_Weff + theta_arr[i].v;
    nFK0_Weff := nFK0_WEff + nFK_Arr[i];
    PWP0_Weff := PWP0_Weff + PWP_Arr[i];
  end;
  SumPAvSoilWaterRZ.v := WG0_Weff - PWP0_Weff;
  ProzNFK0_Weff.v := (WG0_WEff - PWP0_Weff) / nFK0_Weff * 100;
  ProzNFK0_30.v := (WG0_30.v * 3 - (PWP_Arr[1] + PWP_Arr[2] + PWP_Arr[3])) /
    (nFK_arr[1] + nFK_arr[2] + nFK_arr[3]) * 100;

  if uppercase(red_fOption.Option) = 'MODIFIEDBEESE' then
    fred_f := modifiedBeese;
  if uppercase(red_fOption.Option) = 'BEESE1978' then fred_f := Beese1978;

end;

procedure TSoilWaterMod.CalcSinks;
begin
  WflowInt_arr[1].v := -0.1 * Act_Evap.v
    + 0.1 * TExternV(Netrain).v;
  CumNetRain.c := TExternV(Netrain).v;
end;

procedure TSoilWaterMod.CalcEvap_red_f;
{ ********************************************************************** }
{ Zweck : Ermittlung eines Reduktionsfaktors der die potentielle
          Evaporation um den Einflu· einer geringen Bodenfeuchte an der
          BodenflÑche korrigiert

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
  if psi_arr[1].v > 0.0 then begin
    pf_5 := log10(psi_arr[1].v);
    if fred_f = modifiedBeese then
      red_f := -1 * (pf_5 - 4.2) / (4.2 - log10(psi_critEvap.v));
    if fred_f = Beese1978 then red_f := -0.5767 * log10(psi_arr[1].v) + 1.78;
  end else
    red_f := 0.0;
  if red_f > 1.0 then red_f := 1.0;
  if red_f < 0.0 then red_f := 0.0;
  Red_Evap.v := red_f;
end;

procedure TSoilWaterMod.CalcRates;

var
  i: integer;
  OldSumSoilwater: real;

begin
  SumOfInternalTimeSteps := 0.0;
  Act_Evap.v := 0.0;
  CumEvap.c := 0.0;
  CumDrainage.c := 0.0;
  CumRunoff.c := 0.0;
  for i := 1 to n_comp + 1 do Wflow_arr[i].v := 0.0;
//  Act_Evap.V := 0.0;
  n_int_timesteps.v := 0;
  dt.v := dt_alt;
    {Startwert f¸r Zeitschrittweiten-Steuerung ist der vorletzte Zeitschritt des vorherigen Tages.}
  act_n_comp := n_comp; // default value for computation index
  if Opt_Randbed = groundwatertable then begin
    act_n_comp := 2;
    repeat
      inc(act_n_comp);
    until (Tiefe[act_n_comp + 1].v >= groundwaterdepth.v) or (act_n_comp >=
      n_comp);
  end;
  repeat
    CalcRatesAndIntegrate;
    SumOfInternalTimeSteps := SumOfInternalTimeSteps + dt.v;
    n_int_timesteps.v := n_int_timesteps.v + 1;
    for i := 1 to n_comp + 1 do
      Wflow_arr[i].v := Wflow_arr[i].v + WflowInt_arr[i].v * dt.v / GlobTime.c;
 //   sink_arr[i].v := sink_arr[i].v + SinkInt_arr[i].v*dt.v/Globtime.c;
  until SumOfInternalTimeSteps >= self.GlobTime.c;

  OldSumSoilWater := SumSoilwater.v;
  SumSoilwater.v := 0.0;
  SumPavSoilWater.v := 0.0;
  for i := 1 to trunc(bil_nr.v) do begin
    SumSoilwater.v := SumSoilWater.v + Wmenge[i].v * 10;
    SumPAVSoilWater.v := SumPAVSoilwater.v + Wmenge[i].v * 10 - PWP_Arr[i] *
      Dicke[i] * 10;
  end;

  if GlobTime.v > GlobMod.Starttime then begin
    CumWaterBalance.c := (SumSoilWater.v - OldSumSoilWater) + (-CumNetRain.c +
      CumDrainage.c + CumEvap.c + CumRunoff.c) * Globtime.c;
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
  for i := 1 to 10 do begin
    nFK0_100 := nFK0_100 + nFK_Arr[i];
    PWP0_100 := PWP0_100 + PWP_Arr[i];
  end;
  ProzNFK0_100.v := (WG0_100.v - PWP0_100 / 10) / nFK0_100 * 1000;
  nFK0_Weff := 0;
  PWP0_Weff := 0;
  WG0_Weff := 0;
  for i := 1 to ndx_WEff do begin
    WG0_Weff := WG0_Weff + theta_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);
    nFK0_Weff := nFK0_Weff + nFK_Arr[i] * (Tiefe[i].v - Tiefe[i - 1].v);
    PWP0_Weff := PWP0_Weff + PWP_Arr[i] * (Tiefe[i].v - Tiefe[i - 1].v);
  end;
  SumPAvSoilWaterRZ.v := (WG0_Weff - PWP0_Weff) * 10;
  ProzNFK0_WEff.v := (WG0_WEff - PWP0_WEff) / nFK0_Weff * 100;
  ProzNFK0_30.v := (WG0_30.v * 3 - (PWP_Arr[1] + PWP_Arr[2] + PWP_Arr[3])) /
    (nFK_arr[1] + nFK_arr[2] + nFK_arr[3]) * 100;
  if Opt_TransferWGsToNextINI and (GlobTime.v = GlobMod.Endtime) then begin
    if GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName) =
      GlobMod.IniFileNames.Count - 1 then exit;
    NextINI := TMyIniFile.Create;
    NextINI.Init(GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName) + 1]);
    NextStateINI := TMyIniFile.Create;
    NextStateINI.Init(NextINI.ReadString('FileNames', 'StateIniFN', ''));
    for i := 1 to n_comp + 1 do begin
      if i <= 9 then
        ndx_str := '_' + IntTostr(i)
      else
        ndx_str := IntTostr(i);
      NextStateINI.WriteString(self.Name, 'WG' + ndx_str,
        FloatToStrF(theta_arr[i].v, ffFixed, 9, 6));
    end;
    NextIni.Free;
    NextStateIni.Free;
  end;
end;

procedure TSoilWaterMod.CalcRatesAndIntegrate;
begin
  CalcEvap_red_f;
  Exfiltration.v := Dw_arr[1] * Theta_arr[1].v / (0.5 * Dicke[1]) * 10;
  Act_Evap.v := TExternV(pot_evap).v * Red_Evap.v;
  if (act_Evaporationoption.Option = 'inclExfiltration') then
    Act_Evap.v := min(Act_Evap.v, Exfiltration.v);

  CalcSinks;

  if CompMethod = Capacity then
    CapWatSolut; // Kapazit‰tsbasiertes Modell
  if CompMethod = Potential then
    Diffwater_solut; // Potentialbasiertes Modell mit Wassergehalten
  if CompMethod = Richards then
    Richardswater_solut; // Potentialbasiertes Modell mit Wasserspannungen

  // Berechnung der abgeleiteten Wassergehalte f¸r verschiedene Bodenschichten
  update_WG_Values;

  CumEvap.c := CumEvap.c - WflowInt_arr[1].v * 10 * dt.v + CumNetRain.c * dt.v -
    CumRunoff.c * dt.v;
  //if WFlowInt_arr[1] was reduced because of dry, this is the new ActEvap of InternTimeStep
  CumDrainage.c := CumDrainage.c + WflowInt_arr[trunc(bil_nr.v) + 1].v * 10 *
    dt.v;
    // hk 25.1.2011: changed to variable depth in case of groundwater higher than depth of comartment bil_nr
end;

{$WRITEABLECONST ON}

procedure TSoilWaterMod.CapWatSolut;

const
  rep: boolean = false;

var
  psiWP,
    psiFK: real;
  WCap: TSoilArray;
  i: byte;

begin
  if rep = false then begin
    { Berechnung der Wasserspannungen [cm] bei FeldkapazitÑt bzw. beim
      permanenten Welkepunkt }
    psiWP := power(10, 4.2);
    psiFK := power(10, 1.8);

    if nFKCalcMethod = input then begin

      if HoriNdx1.v = 0 then begin
        showmessage('Warning ! No specification of Indexes for hydraulic parameters');
        showmessage('Please check !');
      end;

      for i := 1 to round(HoriNdx1.v) do begin
        FK_arr[i] := par_FK1.v;
        PWP_Arr[i] := par_PWP1.v;
        nFK_arr[i] := par_fk1.v - par_PWP1.v;
      end;

      for i := round(HoriNdx1.v) + 1 to round(HoriNdx2.v) do begin
        FK_arr[i] := par_FK2.v;
        PWP_Arr[i] := par_PWP2.v;
        nFK_arr[i] := par_fk2.v - par_PWP2.v;
      end;

      for i := round(HoriNdx2.v) + 1 to round(HoriNdx3.v) do begin
        FK_arr[i] := par_FK3.v;
        PWP_Arr[i] := par_PWP3.v;
        nFK_arr[i] := par_fk3.v - par_PWP3.v;
      end;

      for i := round(HoriNdx3.v) + 1 to n_comp + 1 do begin
        FK_arr[i] := par_FK4.v;
        PWP_Arr[i] := par_PWP4.v;
        nFK_arr[i] := par_fk4.v - par_PWP4.v;
      end;
    end else begin {nFKCalcMethod = FromParameter}
      for i := 1 to n_comp do begin
        FK_arr[i] := WPar[i].b_psi_f(psiFK);
        PWP_arr[i] := Wpar[i].b_psi_f(psiWP);
        nFK_arr[i] := fk_arr[i] - pwp_arr[i];
        WMenge[i].v := Theta_arr[i].v * Dicke[i];
      end;
    end;
    rep := true;
  end; { Ende Initialisierungssequenz }

  dt.v := GlobTime.c;
    // bei Kapazit‰tswassermodell immer Zeitschritt des globalen
                       // Modells

  for i := 1 to n_comp + 1 do begin
    Theta_arr[i].v := Wmenge[i].v / dicke[i];
    theta_alt[i] := theta_arr[i].v;
    Wflow_alt[i] := WflowInt_arr[i].v;
    WflowInt_arr[i].v := 0.0;
  end;

  if (TExternV(netrain).v > 0.0) then begin
    WflowInt_arr[1].v := TExternV(netrain).v * 0.1;
    for I := 1 to n_comp do begin
      WCap[i] := (FK_arr[i] - theta_arr[i].v) * dicke[i];
      if (WCap[i] < WflowInt_arr[i].v) then begin // Saturation ?
        theta_arr[i].v := FK_arr[i];
        WflowInt_arr[i + 1].v := WflowInt_arr[i].v - WCap[i];
      end else begin
        theta_arr[i].v := theta_arr[i].v + WflowInt_arr[i].v / dicke[i] *
          GlobTime.c;
        WflowInt_arr[i + 1].v := 0.0;
      end;
    end;
  end;
  // evaporation
  theta_arr[1].v := theta_arr[1].v - 0.1 * act_evap.v / dicke[1] * GlobTime.c;

  //   water uptake of plant roots
  for i := 1 to n_comp do begin
    theta_arr[i].v := theta_arr[i].v - sink_arr[i].v / dicke[i] * GlobTime.c;
    psi_arr[i].v := Wpar[i].psi_b_f(theta_arr[i].v);
  end;

end; { procedure CapWatSolut }

{--------------------------------------------------------------------------}

procedure TSoilWaterMod.get_water_contents;
var
  i: byte;
begin
  for I := 1 to n_comp + 1 do begin
    Theta_arr[i].v := Wmenge[i].v / dicke[i];
    theta_neu[i] := theta_arr[i].v;
  end;
end;

procedure TSoilWaterMod.Diffwater_solut;

const
  max_iter_error = 0.0001;

var
  delt_iter_max
    : real;

  iter: integer;
  result,
    start: byte;
  wet, { SÑttigung im obersten Kompartiment ? }
    dry, { Wassergehalt kleiner b_rest im obersten Komp.? }
    success { Flag-Variable fÅr fehlerfreie AusfÅhrung }
    : boolean;

  procedure Leitfaehigkeiten;

  var
    i: byte;

  begin
    if Iter = 0 then
      begin { lineare Extrapolation der Wassergehalte bei der ersten Iteration }
      for I := 1 to n_comp do
        est_theta[i + 1] := 0.5 * (1 + dt.v / (2 * dt_alt)) * (theta_arr[i].v +
          theta_arr[i + 1].v)
          - 0.25 * dt.v / dt_alt * (theta_alt[i] + theta_alt[i + 1]);
      for I := 2 to n_comp + 1 do begin
        avg_Dw[i] := Wpar[i].Dw_f(est_theta[i]);
        avg_Ku[i] := WPar[i].Ku_b_f(est_theta[i]);
      end;
      for I := 2 to n_comp + 1 do begin
        Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
        Ku_fact[i] := avg_Ku[i] * dt.v;
      end;
    end else begin {weitere Iterationen}

  { Berechnung der Wasserdiffusivit‰t und der unges‰ttigten hydraulischen
    Leitf‰higkeit f¸r jedes Kompartiment aus dem Mittelwert der Wassergehalte
    zu Beginn des Zeitschrittes und zum Ende des Zeitschrittes }
      for I := 1 to n_comp + 1 do begin
        Dw_arr[i] := WPar[i].Dw_f((theta_neu[i] + theta_arr[i].v) / 2.0);
        Ku_arr[i] := WPar[i].Ku_b_f((theta_neu[i] + theta_arr[i].v) / 2.0);
      end;

  { Berechnung des Mittelwertes der Leitf‰higkeit zwischen 2 Kompartimenten }
      for I := 2 to n_comp + 1 do begin
        avg_Dw[i] := (Dw_arr[i - 1] + Dw_arr[i]) / 2.0;
        avg_Ku[i] := (Ku_arr[i - 1] + Ku_arr[i]) / 2.0;
      end;

  { Berechnung von Koeffizienten f¸r die Aufstellung des Gleichungssystems,
    Abst.vektor mit dem Index i-1, weil Abstand zwischen erstem und
    zweiten Kompartiment Index 1 hat (verschobene Indizierung }
      for I := 2 to n_comp + 1 do begin
        Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
        Ku_fact[i] := avg_Ku[i] * dt.v;
      end;

    end;

  { Pr¸fen auf Frost  => keine Fl¸sse }
    if self.FSoilHeatModel <> nil then begin
      for i := 1 to n_comp + 1 do begin
        if fSoilHeatModel.Temp[i].v <= 0 then begin
          avg_Dw[i] := 0.0;
          avg_Ku[i] := 0.0;
          Dw_fact[i] := 0.0;
          Ku_fact[i] := 0.0;
        end;
      end;
    end;
  end;

  procedure obere_Randbedingung;
  const
    dWg = 1e-14;

  { zur Verhinderung von ung¸ltigen Funktionsaufrufen wird zuerst
    eine Pr¸fung vorgenommen, ob ein Absinken des Wassergehaltes unter den
    "Restwassergehalt b_rest" oder ein Ansteigen ¸ber den "S‰ttigungs-
    wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Pr¸fung wird
    in den Variablen "Wet", bzw. "Dry" gespeichert. }

  begin
    dry := false; wet := false; success := false;

    if (Theta_neu[1] > Wpar[1].b_sat) and (WflowInt_arr[1].v > 0.0) then
      wet := true; { Pr¸fung auf S‰ttigung }

    if (Theta_neu[1] < WPar[1].b_rest) and (WflowInt_arr[1].v <= 0.0) then
      dry := true; { Pr¸fung auf PWP }

    if wet then begin
      b_vektor[1] := WPar[1].b_sat - dWG;
      theta_neu[1] := WPar[1].b_sat - dWG;
      Start := 2;
    end;

    if dry then begin
      b_vektor[1] := WPar[1].b_rest + dWG;
      theta_neu[1] := WPar[1].b_rest + dWG + NetRain.v * dt.v / 10 / dicke[1];
      WflowInt_arr[1].v := theta_neu[1] - (theta_arr[1].v - sink_arr[1].v * dt.v
        / Dicke[1]);
      start := 2;
    end;

    if (not wet) and (not dry) then begin
      success := true;
      start := 1;
      B_vektor[1] := theta_arr[1].v
        + WflowInt_arr[1].v * dt.v / Dicke[1] - Ku_fact[2] / Dicke[1]
        - sink_arr[1].v * dt.v / Dicke[1];
      Diag[1] := Dw_fact[2] / Dicke[1] + 1.0;
      Upper[1] := -Dw_fact[2] / Dicke[1];
    end;
  end;

  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do begin
      B_vektor[i] := theta_arr[i].v
        - ku_fact[i + 1] / Dicke[i]
        + ku_fact[i] / Dicke[i]
        - sink_arr[i].v * dt.v / Dicke[i];
      Lower[i] := -Dw_fact[i] / Dicke[i];
      Diag[i] := Dw_fact[i] / Dicke[i] + Dw_fact[i + 1] / Dicke[i] + 1.0;
      Upper[i] := -Dw_fact[i + 1] / Dicke[i];
    end;
  end;

  procedure untere_Randbedingung;

  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    if (untere_Randb = Content) or (untere_Randb = groundwatertable) then
                           { Gehalts-Randbedingung }
      B_vektor[act_n_comp] := theta_arr[act_n_comp].v
        + ku_fact[act_n_comp] / Dicke[act_n_comp]
        - ku_fact[act_n_comp + 1] / Dicke[act_n_comp + 1]
        + Dw_fact[act_n_comp + 1] * theta_arr[act_n_comp + 1].v /
        Dicke[act_n_comp + 1]
        - sink_arr[act_n_comp].v * dt.v / dicke[act_n_comp]
    else
                           { Fluﬂ-Randbedingung }
      B_vektor[n_comp] := theta_arr[n_comp].v
        + ku_fact[n_comp] / Dicke[n_comp]
        - WflowInt_arr[n_comp + 1].v / Dicke[n_comp]
        - sink_arr[n_comp].v * dt.v / dicke[n_comp];

    Lower[act_n_comp] := -Dw_fact[act_n_comp] / Dicke[act_n_comp];
    Diag[act_n_comp] := Dw_fact[act_n_comp] / Dicke[act_n_comp]
      + Dw_fact[act_n_comp + 1] / Dicke[act_n_comp + 1]
      + 1.0;
  end;

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
  begin
    result := trdiag(false, act_n_comp, start, lower, diag, upper, b_vektor);
    if result <> 0 then
      ShowMessage('Fehler beim Lˆsen des Gleichungssystems');
    if (untere_Randb = groundwatertable) then
      for i := n_comp downto act_n_comp + 1 do begin
        last_iter_theta[i] := theta_neu[i];
      end;
    for i := act_n_comp downto Start do begin
      last_iter_theta[i] := theta_neu[i];
      theta_neu[i] := b_vektor[i];
    end;
  end;

  procedure CalcOverflow;
  var
    i: integer;
    Overflow, maxstorage: real;
    layer: byte;
  begin
    for I := n_comp downto Start do begin
      if theta_neu[i] > Wpar[i].b_sat then begin
        overflow := (theta_neu[i] - Wpar[i].b_sat) * Dicke[i];
          // save overshooting amount of water
        theta_neu[i] := Wpar[i].b_sat;
        layer := i; // start with the lowest layer where overflow occurred
        repeat
          if theta_neu[layer] < Wpar[layer].b_sat then
            begin // water capacity available?
            maxstorage := (Wpar[layer].b_sat - theta_neu[layer]) * dicke[layer];
              // how much?
            if overflow > maxstorage then
              begin // everything fits in this layer ?
              theta_neu[layer] := Wpar[layer].b_sat;
              overflow := overflow - maxstorage;
            end else begin
              theta_neu[layer] := theta_neu[layer] + overflow / dicke[layer];
              overflow := 0.0;
            end;
          end;
          WflowInt_arr[layer].v := WflowInt_arr[layer].v - overflow / dt.v;
          dec(layer)
        until (layer = 0) or (overflow <= 0);
          // all overflow distributed or surface layer reached ...
        if overflow > 0 then
          CumRunoff.c := CumRunoff.c + Overflow * 10 {cm -> mm};
      end;
      if theta_neu[i] < 0.0 {Wpar[i].b_rest} then begin
        Theta_neu[i] := 0.0 {Wpar[i].b_rest};
      end;
    end;
  end;

  procedure Find_flows;
  var
    GW_inflow : TSoilArray; // flows induced by increasing groundwater table
    i: byte;
  begin
    if (untere_Randb = Content) then begin
      for i := 2 to act_n_comp + 1 do begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i])
          / Abst[i - 1] + avg_Ku[i];
        Wflow_alt[i] := avg_Dw[i] * (theta_alt[i - 1] - theta_alt[i])
          / Abst[i - 1] + avg_Ku[i];
      end;
    end;

    if (untere_Randb = Groundwatertable) then begin

      for i := 2 to n_comp + 1 do begin
        Wflow_alt[i] := avg_Dw[i] * (theta_alt[i - 1] - theta_alt[i])
          / Abst[i - 1] + avg_Ku[i];
      end;

      for i := 2 to act_n_comp + 1 do begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i])
          / Abst[i - 1] + avg_Ku[i];
      end;

      for i := act_n_comp + 1 to n_comp do begin
        GW_inflow[i + 1] := (theta_neu[i] - WPar[i].b_sat) * Dicke[i] / dt.v;
        theta_neu[i] := WPar[i].b_sat;
      end;

      for i := act_n_comp + 2 to n_comp + 1 do begin
        WflowInt_arr[i].v := WflowInt_arr[i - 1].v + gw_inflow[i];
      end;

    end;

    if (untere_Randb = Flow) then begin
      for I := 2 to n_comp do begin
        WflowInt_arr[i].v := avg_Dw[i] * (theta_neu[i - 1] - theta_neu[i]) /
          Abst[i - 1] + avg_Ku[i];
        Wflow_alt[i] := avg_Dw[i] * (theta_alt[i - 1] - theta_alt[i]) / Abst[i -
          1] + avg_Ku[i];
      end;
       {WflowInt_arr[n_comp+1] := 0.0;      // this would be no flow ...
       flow_alt[n_comp+1] := 0.0;}
    end;

    if (wet and (WflowInt_arr[1].v > WflowInt_arr[2].v)) then begin
      WflowInt_arr[1].v := WflowInt_arr[2].v;
      WFlow_alt[1] := WFlow_alt[2];
    end;
    if (dry and (WflowInt_arr[1].v < WflowInt_arr[2].v)) then begin
      WflowInt_arr[2].v := WflowInt_arr[1].v;
      WFlow_alt[2] := WFlow_alt[1];
    end;
  end;

  procedure get_bilanz;

  { ********************************************************************** }
  { Zweck : Berechnung der Massenbilanz und der maximalen Wassergehalts-
            ‰nderung im Simulationszeitschritt

    Parameter :

      Name             Inhalt                          Einheit      Typ
      w_rec            Record mit den Wasserdaten                    I
                       ( siehe Typdefinitionen )
      geo_rec          Record mit den Geometriedaten                 I
      comps            Zahl der Kompartimente           [-]          I

      max_d_WaGe       maximale WassergehaltsÑnderung   [cm3/cm3]    O }
  { ********************************************************************** }

  var
    i: byte;

    net_flow, { Netto-Flu·                       [cm] }
      d_WaMe, { énderung der Wassermenge
                             im Kompartiment                  [cm] }
    d_WaGe, { énderung des Wassergehaltes
                             im Kompartiment                  [cm3/cm3] }
    sum_d_WaMe, { Summe der Wassermengen-
                             Ñnderungen                       [cm] }
    sum_sink {  Summe der Sink-Terme            [cm] }

    : real;

    Bilanz_f_arr: TSoilArray;

  begin
    maxAktAenderWaGe := 0.0;
    sum_d_WaMe := 0.0;
    sum_sink := 0.0;
    akt_bilanz_f := 0.0;
    for I := 1 to n_comp do begin
      net_flow := (WflowInt_arr[i].v - WflowInt_arr[i + 1].v) * dt.v;
      d_WaMe := (theta_arr[i].v - theta_neu[i]) * Dicke[i];
      d_WaGe := theta_arr[i].v - theta_neu[i];
      Bilanz_f_arr[i] := d_WaMe + net_flow - Sink_arr[i].v * dt.v;
      akt_bilanz_f := akt_bilanz_f + Bilanz_f_arr[i];
      if abs(d_WaGe) > maxAktAenderWaGe then
        maxAktAenderWaGe := abs(d_WaGe);
      sum_d_WaMe := sum_d_WaMe + d_WaMe;
      sum_sink := sum_sink + sink_arr[i].v * dt.v;
    end;
    sum_Bilanz_f := sum_bilanz_f + akt_bilanz_f;
  end;

  procedure get_new_dt;
  { ********************************************************************** }
  { Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verh‰ltnisses
             der maximal erlaubten Wassergehalts‰nderung zur maximalen aktuellen
             Wassergehalts‰nderung

    Parameter :

      Name             Inhalt                          Einheit      Typ

      max_aender       maximal erlaubte énderung       [cm3/cm3]    I
                       der Wassergehalte in einem
                       Zeitschritt

      akt_aender       maximale ƒnderung des Wasser-   [cm3/cm3]    I
                       gehaltes in einem Kompartiment
                       im letzten Zeitschritt

      dt               Zeitschrittweite                [d]          O
      dt_alt           letzte Zeitschrittweite         [d]          O }

  { ********************************************************************** }

  var
    dt_neu: real;

  begin
    if max(MaxaktAenderWaGe, NetRain.v * dt.v / (Dicke[1] * 10)) <> 0.0 then
      begin
      if (dt_alt / dt.v <= 1.5) then
        dt_alt := dt.v { Speicherung der alten Zeitschrittweite}
      else dt.v := dt_alt; { wenn der alte Zeitschritt Rest des Tages war,
                dann vorletzter Zeitschritt als Startwert f¸r neuen Zeitschritt.}

                { Verh‰ltnis der erlaubten zur aktuellen Wassergehalts‰nderung }
      dt_neu := (max_aenderWG / max(MaxaktAenderWaGe, NetRain.v * dt.v /
        (Dicke[1] * 10))) * dt.v;

      if dt_neu > max_dt then dt_neu := max_dt; { Zu groﬂer Zeitschritt ? }
      if dt_neu > 1.5 * dt.v then
        dt_neu := dt.v * 1.5; { Zu groﬂer Zeitschrittsprung ?}

      { Der folgende Algorithmus wurde eingef¸gt, um Diskontinuit‰ten bei der
        Verwendung von Eingabedaten auf t‰glicher Basis zu vermeiden. }
      if SumOfInternalTimeSteps + Dt_neu > GlobTime.c
        { Ende des Tages ¸berschritten mit neuem Zeitschritt ? }then
        dt_neu := (GlobTime.c - SumOfInternalTimeSteps);
      dt.v := dt_neu;
    end;

  end;

  procedure get_delt_iter_max;
  { ********************************************************************** }
  { Zweck : Berechnung des maximalen Wassergehaltsunterschiedes in einem
            Kompartiment von einem Iterationsschritt zum n‰chsten          }
  { ********************************************************************** }

  var
    i: byte;

  begin
    delt_iter_max := 0.0;
    if iter > 0 then begin
      for I := start to n_comp do
        if (abs(last_iter_theta[i] - theta_neu[i]) > abs(delt_iter_max)) then
          delt_iter_max := abs(last_iter_theta[i] - theta_neu[i])
    end;
    if Delt_iter_max < 1e-5 then success := true;
  end;

  procedure set_new_state_vars;
  { ********************************************************************** }
  { Zweck : Umsetzen der errechneten Wassergehalte in die globale
            "state"-Variable, Errechnung der Wasserspannungen              }
  { ********************************************************************** }

  var
    i: byte;

  begin
    for I := 1 to n_comp + 1 do begin
      theta_alt[i] := theta_arr[i].v;
      theta_arr[i].v := theta_neu[i];
      psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
      Wmenge[i].v := theta_arr[i].v * dicke[i];
    end;
  end;

begin { procedure Diffwater_solut }
  iter := 0;

  get_water_contents;
  get_new_dt;
  repeat
    repeat
      get_delt_iter_max;
      Leitfaehigkeiten;
      obere_Randbedingung;
      Mittelteil;
      untere_Randbedingung;
      Loesung_Gleichungssystem;
    until success;
    iter := iter + 1;
  until ((delt_iter_max < max_iter_error) and (iter > 1)) or (iter > 1000);
  Find_flows;
  CalcOverflow;
  get_bilanz;
  set_new_state_vars;
end;
{--------------------------------------------------------------------------}

procedure TSoilWaterMod.Richardswater_solut;

const
  max_iter_error = 0.01;

var
  delt_iter_max
    : real;

  iter: integer;
  result,
    start: byte;
  wet, { SÑttigung im obersten Kompartiment ? }
    dry, { Wassergehalt kleiner b_rest im obersten Komp.? }
    success { Flag-Variable fÅr fehlerfreie AusfÅhrung }
    : boolean;

  procedure Leitfaehigkeiten;

  var
    i: byte;

  begin

    for I := 1 to n_comp + 1 do begin
      C_arr[i] := Wpar[i].C_psi_f(psi_arr[i].v);
      Ku_arr[i] := Wpar[i].Ku_psi_f(psi_arr[i].v);
    end;

    for I := 1 to n_comp do begin
      avg_Ku[i] := (Ku_arr[i] {*upper_w_f[i]} + Ku_arr[i + 1] {*lower_w_f[i]}) /
        2;
    end;

      { Berechnung von Koeffizienten fÅr die Aufstellung des Gleichungssystems}
    for I := 1 to n_comp do begin
      if C_arr[i] >= 0.0 then { Tritt SÑttigung auf ? }
        P[i] := 0.0 { => keine weitere énderung der Wassergehalte }
      else
        P[i] := dt.v / (C_arr[i] * Dicke[i]);
      Kf[i] := Avg_ku[i] / Abst[i];
    end;
      { Berechnung der Koeffizienten fÅr die Aufstellung des Gleichungssystems}

    if self.FSoilHeatModel <> nil then begin
      for i := 1 to n_comp + 1 do begin
        if fSoilHeatModel.Temp[i].v <= 0 then begin
          avg_Ku[i] := 0.0;
          Ku_fact[i] := 0.0;
          p[i] := 0.0;
          Kf[i] := 0.0;
        end;
      end;
    end;
  end;

  procedure obere_Randbedingung;
  const
    dWg = 1e-8;
  { zur Verhinderung von ung¸ltigen Funktionsaufrufen wird zuerst
    eine Pr¸fung vorgenommen, ob ein Absinken des Wassergehaltes unter den
    "Restwassergehalt b_rest" oder ein Ansteigen Åber den "S‰ttigungs-
    wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Pr¸fung wird
    in den Variablen "Wet", bzw. "Dry" gespeichert. }
  begin
    if (WPar[1].b_psi_f(psi_arr[1].v) + NetRain.v * dt.v > WPar[1].b_psi_f(20000)
      {AirDryness}) {and (psi_arr[1].v> 1)} then begin
                                 { Wasserspannungen im erlaubten Rahmen ? }
      start := 1;
      {flow_arr[1] := soll_inflow;}
      B_vektor[1] := Psi_arr[1].v + WflowInt_arr[1].v * P[1]
        - avg_Ku[1] * P[1]
        - sink_arr[1].v * P[1];

      Diag[1] := -Kf[1] * P[1] + 1;
      Upper[1] := Kf[1] * P[1];
    end else begin { sonst keine weiteren ƒnderungen der Wasserspannung }
      if (NetRain.v > 0) and (psi_arr[1].v > 1) then
        psi_neu[1] := WPar[1].psi_b_f(WPar[1].b_psi_f(psi_arr[1].v) + NetRain.v
          *
          dt.v);
      start := 2; { Berechnung beginnt mit 2. Kompartiment }
      b_vektor[2] := psi_arr[2].v + P[2] * (avg_Ku[1] - avg_Ku[2])
        - psi_neu[1] * Kf[1] * P[2]
        - sink_arr[2].v * P[2];
      Diag[2] := -Kf[1] * P[2] - Kf[2] * P[2] + 1;
      upper[2] := Kf[2] * P[2];
      if psi_arr[1].v <= 1 then begin
        b_vektor[1] := 1;
        psi_arr[1].v := 1;
        psi_neu[1] := 1;
      end;
    end;
  end;

  procedure Mittelteil;
  var
    i: integer;
  begin
    for i := start + 1 to n_comp - 1 do begin
      B_vektor[i] := Psi_arr[i].v
        + P[i] * (avg_ku[i - 1] - avg_ku[i])
        - sink_arr[i].v * P[i];
      Lower[i] := Kf[i - 1] * P[i];
      Diag[i] := -Kf[i - 1] * P[i] - Kf[i] * P[i] + 1;
      Upper[i] := Kf[i] * P[i];
    end;
  end;

  procedure untere_Randbedingung;
  { In diesem Fall ist ein vorgegebener unterer Wassergehalt,
    bzw. eine 0-Gradienten Randbedingung vorgegeben }

  begin
    B_vektor[n_comp] := Psi_arr[n_comp].v
      + P[n_comp] * (avg_ku[n_comp - 1] - avg_Ku[n_comp])
      - psi_arr[n_comp + 1].v * Kf[n_comp] * P[n_comp]
      - Sink_arr[n_comp].v * P[n_comp];
    Lower[n_comp] := Kf[n_comp - 1] * P[n_comp];
    Diag[n_comp] := -P[n_comp] * Kf[n_comp - 1] - P[n_comp] * Kf[n_comp] + 1;
  end;

  procedure Loesung_Gleichungssystem;
  var
    I: byte;
  begin
    result := trdiag(false, n_comp, start,
      lower, diag, upper,
      b_vektor);
    for I := start to n_comp do
      psi_neu[i] := b_vektor[i]; { Umsetzen der berechneten }
    for I := 1 to n_comp do begin
      theta_neu[i] := theta_arr[i].v + Wpar[i].C_b_f(theta_arr[i].v) *
        (Psi_neu[i] - psi_arr[i].v);
    end;
  end;

  procedure CalcOverflow;
  var
    i: integer;
    Overflow, maxstorage: real;
    layer: byte;
  const
    MinPsi = 1;
  begin
    for I := n_comp downto 1 {Start} do begin
      if theta_neu[i] > Wpar[i].b_psi_f(MinPsi) then begin
        overflow := (theta_neu[i] - Wpar[i].b_psi_f(MinPsi)) * Dicke[i];
          // save overshooting amount of water
        theta_neu[i] := Wpar[i].b_psi_f(MinPsi);
        layer := i; // start with the lowest layer where overflow occured
        repeat
          if theta_neu[layer] < Wpar[layer].b_psi_f(MinPsi) then
            begin // water capacity available?
            maxstorage := (Wpar[layer].b_psi_f(MinPsi) - theta_neu[layer]) *
              dicke[layer]; // how much?
            if overflow > maxstorage then
              begin // everything fits in this layer ?
              theta_neu[layer] := Wpar[layer].b_psi_f(MinPsi);
              overflow := overflow - maxstorage;
            end else begin
              theta_neu[layer] := theta_neu[layer] + overflow / dicke[layer];
              overflow := 0.0;
            end;
          end;
          WflowInt_arr[layer].v := WflowInt_arr[layer].v - overflow / dt.v;
          psi_neu[layer] := WPar[layer].psi_b_f(theta_neu[layer]);
          dec(layer)
        until (layer = 0) or (overflow <= 0);
          // all overflow distributed or surface layer reached ...
        if overflow > 0 then
          CumRunoff.c := CumRunoff.c + Overflow * 10 {cm -> mm};
      end;
      if theta_neu[i] < Wpar[i].b_rest then begin
        Theta_neu[i] := Wpar[i].b_rest;
      end;
      psi_neu[i] := Wpar[i].psi_b_f(theta_neu[i]);
    end;
  end;

  procedure Find_flows;
  var
    i: byte;
  begin
    for I := 2 to n_comp + 1 do
      WflowInt_arr[i].v := avg_Ku[i - 1] * ((Psi_neu[i] - Psi_neu[i - 1]) /
        Abst[i - 1] + 1);
    if start = 2 then WflowInt_arr[1].v := WflowInt_arr[2].v;
    if (dry and (WflowInt_arr[1].v < WflowInt_arr[2].v)) or
      (wet and (WflowInt_arr[1].v > WflowInt_arr[2].v)) then begin
      WflowInt_arr[1].v := WflowInt_arr[2].v;
      WFlow_alt[1] := WFlow_alt[2];
    end;
  end;

  procedure get_bilanz;
  { ********************************************************************** }
  { Zweck : Berechnung der Massenbilanz und der maximalen Wassergehalts-
            ‰nderung im Simulationszeitschritt

    Parameter :
      Name             Inhalt                          Einheit      Typ
      w_rec            Record mit den Wasserdaten                    I
                       ( siehe Typdefinitionen )
      geo_rec          Record mit den Geometriedaten                 I
      comps            Zahl der Kompartimente           [-]          I

      max_d_WaGe       maximale WassergehaltsÑnderung   [cm3/cm3]    O }
  { ********************************************************************** }

  var
    i: byte;
    net_flow, { Netto-Flu·                       [cm] }
      d_WaMe, { énderung der Wassermenge
                             im Kompartiment                  [cm] }
    d_WaGe, { énderung des Wassergehaltes
                             im Kompartiment                  [cm3/cm3] }
    sum_d_WaMe, { Summe der Wassermengen-
                             Ñnderungen                       [cm] }
    sum_sink {  Summe der Sink-Terme            [cm] }
      : real;

    Bilanz_f_arr: TSoilArray;

  begin
    maxAktAenderWaGe := 0.0;
    sum_d_WaMe := 0.0;
    sum_sink := 0.0;
    akt_bilanz_f := 0.0;
    for I := 1 to n_comp do begin
      net_flow := (WflowInt_arr[i].v - WflowInt_arr[i + 1].v) * dt.v;
      d_WaMe := (theta_arr[i].v - theta_neu[i]) * Dicke[i];
      d_WaGe := theta_arr[i].v - theta_neu[i];
      Bilanz_f_arr[i] := d_WaMe + net_flow - Sink_arr[i].v * dt.v;
      akt_bilanz_f := akt_bilanz_f + Bilanz_f_arr[i];
      if abs(d_WaGe) > maxAktAenderWaGe then maxAktAenderWaGe := abs(d_WaGe);
      sum_d_WaMe := sum_d_WaMe + d_WaMe;
      sum_sink := sum_sink + sink_arr[i].v * dt.v;
    end;
    sum_Bilanz_f := sum_bilanz_f + akt_bilanz_f;
  end;

  procedure get_new_dt;
  { ********************************************************************** }
  { Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verh‰ltnisses
             der maximal erlaubten Wassergehalts‰nderung zur maximalen aktuellen
             Wassergehalts‰nderung

    Parameter :
      Name             Inhalt                          Einheit      Typ

      max_aender       maximal erlaubte énderung       [cm3/cm3]    I
                       der Wassergehalte in einem
                       Zeitschritt

      akt_aender       maximale ƒnderung des Wasser-   [cm3/cm3]    I
                       gehaltes in einem Kompartiment
                       im letzten Zeitschritt

      dt               Zeitschrittweite                [d]          O
      dt_alt           letzte Zeitschrittweite         [d]          O }
  { ********************************************************************** }

  var
    dt_neu: real;

  begin
    if max(MaxaktAenderWaGe, NetRain.v * dt.v / (Dicke[1] * 10)) <> 0.0 then
      begin
      dt_alt := dt.v; { Speicherung der alten Zeitschrittweite }

                { Verh‰ltniss der erlaubten zur aktuellen Wassergehalts‰nderung }
      dt_neu := (max_aenderWG / max(MaxaktAenderWaGe, NetRain.v * dt.v /
        (Dicke[1] * 10))) * dt.v;

      if dt_neu > max_dt then dt_neu := max_dt; { Zu groﬂer Zeitschritt ? }
      if dt_neu > 1.5 * dt.v then
        dt_neu := dt.v * 1.5; { Zu groﬂer Zeitschrittsprung ?}

      { Der folgende Algorithmus wurde eingef¸gt, um Diskontinuit‰ten bei der
        Verwendung von Eingabedaten auf t‰glicher Basis zu vermeiden. }
      if SumOfInternalTimeSteps + Dt_neu > GlobTime.c then
        begin { Ende des Tages ¸berschritten mit neuem Zeitschritt ? }
        dt_neu := (GlobTime.c - SumOfInternalTimeSteps);
        dt.v := dt_neu;
      end;
      dt.v := dt_neu;
    end;
  end;

  procedure get_delt_iter_max;
  { ********************************************************************** }
  { Zweck : Berechnung des maximalen Wassergehaltsunterschiedes in einem
            Kompartiment von einem Iterationsschritt zum n‰chsten          }
  { ********************************************************************** }
  var
    i: byte;
  begin
    delt_iter_max := 0.0;
    if iter > 0 then begin
      for I := start to n_comp do
        if (abs(last_iter_theta[i] - theta_neu[i]) > abs(delt_iter_max)) then
          delt_iter_max := abs(last_iter_theta[i] - theta_neu[i])
    end;
    if Delt_iter_max < 1e-5 then success := true;
  end;

  procedure set_new_state_vars; {Richardswater_solut}
  { ********************************************************************** }
  { Zweck : Umsetzen der errechneten Wassergehalte in die globale
            "state"-Variable, Errechnung der Wasserspannungen              }
  { ********************************************************************** }

  var
    i: byte;
  begin
    for I := 1 to n_comp + 1 do begin
      theta_alt[i] := theta_arr[i].v;
      theta_arr[i].v := theta_neu[i];
      psi_arr[i].v := WPar[i].psi_b_f(theta_arr[i].v);
      Wmenge[i].v := theta_arr[i].v * dicke[i];
    end;
  end;

begin { procedure Richardswater_solut }
  iter := 0;
  get_water_contents;
  get_new_dt;
  repeat
    repeat
      get_delt_iter_max;
      Leitfaehigkeiten;
      obere_Randbedingung;
      Mittelteil;
      untere_Randbedingung;
      Loesung_Gleichungssystem;
    until success;
    iter := iter + 1;
  until ((delt_iter_max < max_iter_error) and (iter > 1)) or (iter > 1000);
  Find_flows;
  CalcOverflow;
  get_bilanz;
  set_new_state_vars;
end;
{--------------------------------------------------------------------------}

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterMod]);
end;

end.

