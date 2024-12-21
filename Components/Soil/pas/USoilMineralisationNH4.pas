unit USoilMineralisationNH4;

{ Sub-Modell zur Beschreibung der Dynamik der Umsetzungen organischer Substanz
  im Boden.
  After Verberne et al. 1990: Modelling organic matter dynamics
  in different soils, Neth.J.agr.Sci., 38, 221-238 }

interface

uses
  Ustate, UlayeredSoil, UMod, IniFiles, classes, UAbstractSoilMin;

const
  CN_biom: real = 8.0; /// CN ratio BIOM }
  CN_som: real = 10.0; /// CN ratio SOM }
  CN_DPM: real = 6.0; /// CN ratio DPM }
  CN_RPM: real = 80; /// CN ratio RPM }

  ik_dpm_biom: real = 1.34; /// reaction constants of respective processes
  iE_dpm_biom: real = 0.4; /// conversion efficiency
  ik_rpm_biom: real = 0.086;
  iE_rpm_biom: real = 0.4;
  ik_som_biom: real = 0.0001;
  iE_som_biom: real = 0.2;
  ik_biom_som: real = 0.3;
  iE_biom_som: real = 1;

type
  { There are two fractions of plant residues }
  Pools = (DPM, { = decomposable material }
    RPM, { = resistant material }
    BIOM, { = microbial Biomass total }
    SOM); { = stabilized organic matter }

  { These are the transfer processes between the pools: }
  processes = (dpm_biom, rpm_biom, som_biom, biom_som);

  TPoolStateArray = array [Pools] of TState;
  TPoolVarArray = array [Pools] of TVar;
  TPoolParArray = array [Pools] of TPar;

  T_f_abiot_calc = (Verbruggen, Petersen, Zhou, DAISY, Mueller, APSIM);
  /// Options for calculation of f_abiot
  T_ProcessType = (minp, nitp, denp); /// mineralisation, nitrification, denitrification

  TMinProcess = Class(Tobject)
  public
    Name: string;
    k: TPar; { decay constant               [1/d] }
    E: TPar; { conversion efficiency        [-] }
    C_flow: real; /// actual C flow rate from (loss from Edukt)
    CO2_Flow: real; /// actual CO2 flow rate
    Nr: real; { Mineralisation/immobilisation rate [kg N/(ha*d] }
    Edukt, Produkt: Pools;

    procedure init(iName: string; ik, iE: TPar; iEdukt, iProdukt: Pools);

    procedure Calculate(F_abiot: real; f_Nmin: real; CN: TPoolParArray;
      var CPools: TPoolStateArray; var NPools: TPoolVarArray;
      NoImmobilisation: boolean);
  end;

  // *****************************************************************
  // *********    Object for mineralisation **************************
  // *****************************************************************

  TSoilMinNH4 = class(TAbstractSoilMin)

  private
    f_abiot_min_Calcmethod, /// calculation of abiotic influences for mineralisation
    f_abiot_nit_Calcmethod, /// calculation of abiotic influences for nitrification
    f_abiot_den_Calcmethod: T_f_abiot_calc; /// calculation of abiotic influences for denitrification

  protected
    function Calc_f_abiot(ProcessType: T_ProcessType; layer: integer): real;
    function calc_f_abiot_Verbruggen(WC, temp, BD: real): real;
    function calc_f_abiot_DAISY(ProcessType: T_ProcessType;
      T, pF, WFPS, Clay: real): real;
    function calc_f_abiot_Mueller(ProcessType: T_ProcessType;
      T, WFPS: real): real;
    function calc_f_abiot_APSIM(ProcessType: T_ProcessType;
      T, WC, FK, Sat: real): real;
    function calcR_NOx_N2O(WFPS: real): real;

  public
    OrgDepth: TPar; /// total depth of organic layer [cm]
    iBulkDensity: TPar; /// inital density of soil
    BulkDensity: TVar; /// actual density of soil
    HumusContent: TPar; /// Humus content

    MinNmin: TPar; /// minimal SMN content
    kBBf: TPar; /// "Decay rate" of tillage factor

    NH4_Arr: array [1 .. MaxSoilLayers] of TState;
    /// sum of ammonia N in each layer
    Nmin_Arr: array [1 .. MaxSoilLayers] of TVar; /// sum of nitrate (external) and ammonia
    SumNmin: TVar; /// sum of Nmin
    cum_N2O: array [1 .. MaxNOrgLayers] of TState;
    /// cumulative N2O loss [kg N ha-1]
    { external values }
    temp: TExternV; /// Mean air temperature
    Theta_Array: array [1 .. MaxNOrgLayers] of TExternV; /// volumetric soil water content [cm3/cm3] , external
    NO3_Arr: array [1 .. MaxSoilLayers] of TExternV;
    /// soil nitrate [kg N/ha], external
    WFPS_Arr: array [1 .. MaxNOrgLayers] of TVar;
    WFPS0_30: TVar; /// waterfilled pore space 0-30 cm [%]

    MinProcesses: array [0 .. MaxNOrgLayers, processes] of TMinProcess;
    /// array for iterating the processes
    CFlowArr: array [processes, 0 .. MaxNOrgLayers] of TVar; /// C flows
    CO2FlowArr: array [processes, 0 .. MaxNOrgLayers] of TVar; /// CO2 flows
    C_ges, /// Total C content of the soil [kg/ha]
    C_ER, /// C in crop residues    [kg/ha]
    N_ER, /// N in crop residues    [kg/ha]
    Added_N, Added_C, /// Norg / Corg added from Input [kg N/ha]
    cum_N2O_nit, /// cumulative N2O emissions from nitrification [kg N/ha]
    cum_N2O_den, /// cumulative N2O emissions from denitrification [kg N/ha]
    cum_N2, /// cumulative N2 emissions [kg N/ha]
    cum_NOx /// cumulative NOx emissions [kg N/ha]
      : TState;

    total_N2O, N_ges, /// Total N content of the soil  [kg/ha]
    f_DPM, /// fraction of decomposable carbon in residues
    SumMinr, /// sum of net mineralisation in all layers [kg N/ha/d]
    Net_ming, NSumme, /// sum of N in all pools
    NBilanz /// balance of nitrogen
      : TVar;
    NetMinArr: array [processes, 0 .. MaxNOrgLayers] of TVar;

    km_Nmin, /// Parameter for decreasing decomposition rates under nitrogen shortage
    k_dpm_biom, /// decay constant dpm to biom
    k_rpm_biom, k_som_biom, k_biom_som, E_dpm_biom, E_rpm_biom, E_som_biom,
      E_biom_som, k_nit, /// nitrification constant
    fr_Nloss_nit, /// fraction of N loss during nitrification  in Zhou et al. 2010: Parameter Kn := 0.05
    k_den, /// denitrification constant
    km_den, /// Michaelis Menten constant for denitrification
    f_biom, /// fraction of Biomass C to total C  ~ 0.0001;
    Soil_pH /// Soil pH for calculation of f_abiot_nit according to Zhou
      : TPar;

    ResidueIncorp: TOption; /// Option if residues are initally incorporated or stay on top
    C_distributionmethod: TOption;
    f_abiot_min_Calcmethod_Option: TOption; /// Calculation method for the abiotic factor for mineralisation
    f_abiot_nit_Calcmethod_Option: TOption; /// Calculation method for the abiotic factor for nitrification
    f_abiot_den_Calcmethod_Option: TOption; /// Calculation method for the abiotic factor for denitrification
    CN_Residues: TVar; /// C/N ratio in added crop residues

    CPool: TPoolStateArray; /// array of carbon pools (sum over layers)
    NPool: TPoolVarArray; /// array of carbon pools (sum over layers)
    CN: TPoolParArray; /// array of CN ratios in the pools

    Net_min: array [0 .. MaxNOrgLayers] of TVar;
    /// net mineralisation rate [kg N/ha/d]
    f_abiot_min: array [0 .. MaxNOrgLayers] of TVar; /// abiotic influence factor accounting for temperature and soil water content
    f_abiot_nit: array [0 .. MaxNOrgLayers] of TVar;
    f_abiot_den: array [0 .. MaxNOrgLayers] of TVar;
    f_Nmin: array [0 .. MaxNOrgLayers] of TVar; /// relative factor [0..1] for reducing decomposition rate under nitrogen shortage
    Layerfactor: array [0 .. MaxNOrgLayers] of TPar; /// factor to correct decomposition rates in individual soil layers
    c_frac: array [0 .. MaxNOrgLayers] of TPar; /// fraction of carbon initially within a certain soil layer

    NPool_i: array [0 .. MaxNOrgLayers] of TPoolVarArray;
    /// all nitrogen pools, two dimensional Var matrix
    CPool_i: array [0 .. MaxNOrgLayers] of TPoolStateArray; /// all carbon pools
    NitrificationRate: array [0 .. MaxNOrgLayers] of TVar;
    /// rate of NO3 production by nitrification
    DenitrificationRate: array [0 .. MaxNOrgLayers] of TVar;
    /// rate of NO3 consumption by denitrification
    NetMinRate: array [0 .. MaxNOrgLayers] of TExternV;
    /// net rate of NO3 production

    R_N2_N2O: array [0 .. MaxNOrgLayers] of TVar;
    /// ratio of N2 / N2O from denitrification

    Norg, /// total amount of organic nitrogen [kg/ha] sum of all other pools and over layers
    Corg: TVar; /// total amount of organic carbon [kg/ha]

    NH4_0_10, NH4_0_30, NH4_30_60, NH4_60_90, NH4_0_60, NH4_0_90,
    /// ammonium in 30cm soil layers [kg N/ha] and layer 0-10cm
    Nmin0_10, Nmin0_30, Nmin30_60, Nmin60_90, Nmin0_60, Nmin0_90: TVar; /// soil mineral nitrogen in 30cm soil layers [kg N/ha] and layer 0-10cm

    NH4_N2O_rate: array [0 .. MaxNOrgLayers] of TVar;
    /// N2O-N emission rate from nitrification
    NH4_NOx_rate: array [0 .. MaxNOrgLayers] of TVar;
    /// NOx-N emission rate from nitrification
    NO3_N2O_rate: array [0 .. MaxNOrgLayers] of TVar;
    /// N2O-N emission rate from denitrification
    NO3_N2_rate: array [0 .. MaxNOrgLayers] of TVar;
    /// N2-N emission rate from denitrification

    N2O_flux,  /// N2O flux rate [kg N ha-1 d-1]
    N2_flux,   /// N2 flux rate [kg N ha-1 d-1]
    NOx_flux,  /// NOx flux rate [kg N ha-1 d-1]
    CO2_flux: TVar; /// CO2 flux rate [kg C ha-1 d-1]

    procedure CreateAll; override;

    procedure init(Var GlobMod: TMod); Override;
    procedure CalcRates; override;
    procedure Integrate; override;

    procedure AddResidues(Carbon, nitrogen: real); override;
    procedure MixLayers(depth: real); override;

  published
    property Par_km_Nmin: TPar read km_Nmin write km_Nmin;
    property Par_k_nit: TPar read k_nit write k_nit;
    property Par_k_den: TPar read k_den write k_den;
    property Ex_Temp: TExternV read temp write temp;
    property Var_NetMinG: TVar read Net_ming write Net_ming;
    property Var_SumMInr: TVar read SumMinr write SumMinr;
    property opt_c_distributionmethod
      : TOption read C_distributionmethod write C_distributionmethod;
  end;

var
  SoilMineralisation: TSoilMinNH4;

procedure Register;

implementation

uses
  math, SysUtils, dialogs,
  USoilWaterMod, USoilTexture;

procedure TMinProcess.init(iName: string; ik, iE: TPar;
  iEdukt, iProdukt: Pools);

begin
  Name := iName;
  k    := ik;
  E    := iE;
  Edukt := iEdukt;
  Produkt := iProdukt;
end;

procedure TMinProcess.Calculate(F_abiot: real; f_Nmin: real; CN: TPoolParArray;
  var CPools: TPoolStateArray; var NPools: TPoolVarArray;
  NoImmobilisation: boolean);

Var
  C_flow_educt, C_flow_product: real;

begin
  C_flow_educt   := min(1, F_abiot * k.v) * (CPools[Edukt].v);
  C_flow_product := min(1, F_abiot * k.v) * (CPools[Edukt].v * E.v);
  Nr := C_flow_educt * (1 / CN[Edukt].v - E.v / CN[Produkt].v);
  if Nr <= 0.0 then
  begin
    C_flow_educt := f_Nmin * C_flow_educt; // if nr is negative, fNmin accounts for influence of nitrate availability
    C_flow_product := f_Nmin * C_flow_product;
    Nr := C_flow_educt * (1 / CN[Edukt].v - E.v / CN[Produkt].v);
  end;
  If (Nr <= 0) and NoImmobilisation then
  begin
    CPools[Edukt].c := 0.0;
    CPools[Produkt].c := 0.0;
    Nr := 0.0;
  end;
  CPools[Edukt].c := CPools[Edukt].c - C_flow_educt;
  CPools[Produkt].c := CPools[Produkt].c + C_flow_product;

  Nr := C_flow_educt * (1 / CN[Edukt].v - E.v / CN[Produkt].v);
  CO2_Flow := C_flow_educt - C_flow_product;
  C_flow := C_flow_educt;
end;

procedure TSoilMinNH4.CreateAll;

var
  layer: integer;
  value: real;
  Process: processes;

begin
  inherited;
  ParCreate('CN_dpm', '[-]', CN_DPM, CN[DPM]);
  ParCreate('CN_rpm', '[-]', CN_RPM, CN[RPM]);
  ParCreate('CN_som', '[-]', CN_som, CN[SOM]);
  ParCreate('CN_biom', '[-]', CN_biom, CN[BIOM]);
  ParCreate('f_biom', '[-]', 0.001, f_biom);
  ParCreate('Km_Nmin', '[-]', 1, km_Nmin, 'Michaelis-Constand for Effect of Nmin on mineralisation');
  ParCreate('k_nit', '[1/d]', 0.5, k_nit);
  ParCreate('fr_Nloss_nit', '[-]', 0.05, fr_Nloss_nit,
    'fraction of N loss during nitrification'); // in Zhou et al. 2010: Parameter Kn := 0.05
  ParCreate('k_den', '[1/d]', 0.1, k_den);
  ParCreate('Km_den', '[kg N/ha]', 26, km_den,
    'Michaelis-Menten constant for denitrification'); // Zhou et al. 2010: Km = 20ug/g = 26 kg N/ha/soil layer
  ParCreate('kBBf', '[1/d]', 0.05, kBBf, 'factor for soil tillage effect');
  ParCreate('OrgDepth', '[cm]', 30, OrgDepth, 'depth of organic layers');
  ParCreate('ini.BulkDensity', '[g/cm3]', 1.3, iBulkDensity);
  VarCreate('act.BulkDensity', '[g/cm3]', 1.3, false, BulkDensity);
  ParCreate('HumusContent', '[-]', 0.018, HumusContent);
  ParCreate('MinNmin', '[kg N/ha/layer]', 2., MinNmin, 'Minimum Nmin value ');
  ParCreate('Soil_pH', '[-]', 6.4, Soil_pH,
    'Soil pH for calculation of f_abiot_nit according to Zhou');
  value := 0.0;
  StateCreate('C_ges', '[kg C/ha]', 0, false, C_ges, 'Total soil organic carbon');
  VarCreate('N_ges', '[kg N/ha]', value, false, N_ges, 'Total soil organic nitrogen');
  VarCreate('NSumme', '[kg N/ha]', value, false, NSumme);
  VarCreate('NBilanz', '[kg N/ha]', value, false, NBilanz);
  VarCreate('CN_Residues', '[-]', value, false, CN_Residues,
    'C/N ratio in added crop residues');

  ExternVCreate('Temp', '[°C]', StateField, temp);
  for layer := 1 to trunc(NOrgLayers.v) do
  begin
    ExternVCreate('WG' + ndx_str(layer), '[cm3.cm3]', StateField,
      Theta_Array[layer]);
    VarCreate('WFPS' + ndx_str(layer), '[-]', 0.0, false, WFPS_Arr[layer]);
  end;
  VarCreate('WFPS0_30', '[%]', 0.0, false, WFPS0_30,
    'waterfilled pore space 0-30 cm');

  VarCreate('f_abiot0', '[-]', 1.0, false, f_abiot_min[0]);
  VarCreate('Net_min0', '[kg N.ha-1.d-1]', 0.0, false, Net_min[0]);
  VarCreate('N2O_flux', '[kg N ha-1 d-1]', 0, false, N2O_flux);
  VarCreate('NOx_flux', '[kg N ha-1 d-1]', 0, false, NOx_flux);
  VarCreate('N2_flux', '[kg N ha-1 d-1]', 0, false, N2_flux);
  VarCreate('CO2_flux', '[kg C ha-1 d-1]', 0, false, CO2_flux);

  for layer := 0 to trunc(NOrgLayers.v) do
    VarCreate('f_Nmin' + IntToStr(layer), '[-]', 1.0, false, f_Nmin[layer]);

  for layer := 1 to trunc(NOrgLayers.v) do
  begin
    VarCreate('f_abiot_min' + ndx_str(layer), '[-]', 1.0, false,
      f_abiot_min[layer]);
    VarCreate('f_abiot_nit' + ndx_str(layer), '[-]', 1.0, false,
      f_abiot_nit[layer]);
    VarCreate('f_abiot_den' + ndx_str(layer), '[-]', 1.0, false,
      f_abiot_den[layer]);
    VarCreate('Net_min' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0, false,
      Net_min[layer]);
    VarCreate('NH4_N2O_rate' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0, false,
      NH4_N2O_rate[layer], 'N2O-N emission rate from nitrification');
    VarCreate('NH4_NOx_rate' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0, false,
      NH4_NOx_rate[layer], 'NOx-N emission rate from nitrification');
    VarCreate('NO3_N2O_rate' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0, false,
      NO3_N2O_rate[layer], 'N2O-N emission rate from denitrification');
    VarCreate('NO3_N2_rate' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0, false,
      NO3_N2_rate[layer], 'N2-N emission rate from denitrification');

    VarCreate('NitrificationRate' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0,
      false, NitrificationRate[layer]);
    VarCreate('DenitrificationRate' + ndx_str(layer), '[kg N.ha-1.d-1]', 0.0,
      false, DenitrificationRate[layer]);
    ExternVCreate('NetMin' + ndx_str(layer), '[kg N.ha-1.d-1]', StateField,
      NetMinRate[layer], 'net NO3 production rate');
    ParCreate('Layerfactor' + ndx_str(layer), '[-]', 1, Layerfactor[layer]);
    ParCreate('C_frac' + ndx_str(layer), '[-]', 1 / trunc(NOrgLayers.v),
      c_frac[layer]);
    StateCreate('cum_N2O' + ndx_str(layer), '[kg N/ha]', 0.0, false,
      cum_N2O[layer]);
    VarCreate('R_N2_N2O' + ndx_str(layer), '[-]', 4, false, R_N2_N2O[layer],
      'ratio of N2 / N2O from denitrification in layer' + IntToStr(layer));
  end;

  for layer := 1 to MaxSoilLayers do
  begin
    StateCreate('NH4_Arr' + ndx_str(layer), '[kg N/ha]', 0.0, false,
      NH4_Arr[layer]);
    VarCreate('Nmin_Arr' + ndx_str(layer), '[kg N/ha]', 0.0, false,
      Nmin_Arr[layer], 'sum of nitrate and ammonia N per layer');
          ExternVCreate('Nmin' + ndx_str(layer), '[kg N.ha-1]', StateField,
      NO3_Arr[layer]);

  end;

  VarCreate('SumNmin', '[kg N/ha]', 0, true, SumNmin, 'sum of Nmin');

  StateCreate('cum_N2O_nit', '[kg N/ha]', 0, true, cum_N2O_nit,
    'cumulative N2O emissions from nitrification');
  StateCreate('cum_N2O_den', '[kg N/ha]', 0, true, cum_N2O_den,
    'cumulative N2O emissions from denitrification');
  StateCreate('cum_N2', '[kg N/ha]', 0, true, cum_N2,
    'cumulative N2 emissions');
  StateCreate('cum_NOx', '[kg N/ha]', 0, true, cum_NOx,
    'cumulative NOx emissions');

  StateCreate('C_ER', '[kg C/ha]', 0.1, true, C_ER);
  StateCreate('N_ER', '[kg N/ha]', 0.01, true, N_ER);
  StateCreate('Added_C', '[kg C/ha]', 0.0, true, Added_C);
  // Corg added from Input [kg N/ha]
  StateCreate('Added_N', '[kg N/ha]', 0.0, true, Added_N);
  // Norg added from Input [kg N/ha]

  VarCreate('total_N2O', '[kg N/ha]', 0, true, total_N2O);
  VarCreate('F_DPM', '[-]', value, true, f_DPM);
  VarCreate('SumMinr', '[kg N/ha]', 0.0, false, SumMinr);
  VarCreate('Net_ming', '[kg N.ha-1.d-1]', 0.0, false, Net_ming);

  for layer := 0 to trunc(NOrgLayers.v) do
  begin
    for Process := low(processes) to high(processes) do
    begin
      MinProcesses[layer, Process] := TMinProcess.create;
      Case Process of
        dpm_biom:
          VarCreate('NetMin_' + 'dpm_biom_' + IntToStr(layer), '[kg N/ha*d]',
            value, false, NetMinArr[Process, layer]);
        rpm_biom:
          VarCreate('NetMin_' + 'rpm_biom_' + IntToStr(layer), '[kg N/ha*d]',
            value, false, NetMinArr[Process, layer]);
        som_biom:
          VarCreate('NetMin_' + 'som_biom_' + IntToStr(layer), '[kg N/ha*d]',
            value, false, NetMinArr[Process, layer]);
        biom_som:
          VarCreate('NetMin_' + 'biom_som_' + IntToStr(layer), '[kg N/ha*d]',
            value, false, NetMinArr[Process, layer]);
      end;
      Case Process of
        dpm_biom:
          VarCreate('Cflow_' + 'dpm_biom_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CFlowArr[Process, layer]);
        rpm_biom:
          VarCreate('Cflow_' + 'rpm_biom_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CFlowArr[Process, layer]);
        som_biom:
          VarCreate('Cflow_' + 'som_biom_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CFlowArr[Process, layer]);
        biom_som:
          VarCreate('Cflow_' + 'biom_som_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CFlowArr[Process, layer]);
      end;
      Case Process of
        dpm_biom:
          VarCreate('CO2flow_' + 'dpm_biom_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CO2FlowArr[Process, layer]);
        rpm_biom:
          VarCreate('CO2flow_' + 'rpm_biom_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CO2FlowArr[Process, layer]);
        som_biom:
          VarCreate('CO2flow_' + 'som_biom_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CO2FlowArr[Process, layer]);
        biom_som:
          VarCreate('CO2flow_' + 'biom_som_' + IntToStr(layer), '[kg C/ha*d]',
            value, false, CO2FlowArr[Process, layer]);
      end;
    end;
  end;

  ParCreate('k_dpm_biom', '[1/d]', ik_dpm_biom, k_dpm_biom);
  ParCreate('E_dpm_biom', '[1/d]', iE_dpm_biom, E_dpm_biom);
  ParCreate('k_rpm_biom', '[1/d]', ik_rpm_biom, k_rpm_biom);
  ParCreate('E_rpm_biom', '[1/d]', iE_rpm_biom, E_rpm_biom);
  ParCreate('k_som_biom', '[1/d]', ik_som_biom, k_som_biom);
  ParCreate('E_som_biom', '[1/d]', iE_som_biom, E_som_biom);
  ParCreate('k_biom_som', '[1/d]', ik_biom_som, k_biom_som);
  ParCreate('E_biom_som', '[1/d]', iE_biom_som, E_biom_som);

  StateCreate('C_DPM', '[kg C/ha]', value, true, CPool[DPM]);
  VarCreate('N_DPM', '[kg N/ha]', value, false, NPool[DPM]);
  StateCreate('C_RPM', '[kg C/ha]', value, true, CPool[RPM]);
  VarCreate('N_RPM', '[kg N/ha]', value, false, NPool[RPM]);
  StateCreate('C_SOM', '[kg C/ha]', value, true, CPool[SOM]);
  VarCreate('N_SOM', '[kg N/ha]', 0.0, false, NPool[SOM]);
  StateCreate('C_BIOM', '[kg C/ha]', value, true, CPool[BIOM]);
  VarCreate('N_BIOM', '[kg N/ha]', 0, true, NPool[BIOM]);

  VarCreate('C_org', '[kg N/ha]', value, false, Corg);
  VarCreate('N_org', '[kg N/ha]', value, false, Norg);

  for layer := 0 to trunc(NOrgLayers.v) do
  begin
    StateCreate('C_DPM_' + IntToStr(layer), '[kg C/ha]', 0.0, false,
      CPool_i[layer, DPM]);
    VarCreate('N_DPM_' + IntToStr(layer), '[kg N/ha]',
      CPool_i[layer, DPM].v / CN[DPM].v, false, NPool_i[layer, DPM]);
    StateCreate('C_rpm_' + IntToStr(layer), '[kg C/ha]', 0.0, false,
      CPool_i[layer, RPM]);
    VarCreate('N_rpm_' + IntToStr(layer), '[kg N/ha]',
      CPool_i[layer, RPM].v / CN[RPM].v, false, NPool_i[layer, RPM]);
    StateCreate('C_som_' + IntToStr(layer), '[kg C/ha]', 0.0, false,
      CPool_i[layer, SOM]);
    VarCreate('N_som_' + IntToStr(layer), '[kg N/ha]', 0.0, false,
      NPool_i[layer, SOM]);
    StateCreate('C_Biom_' + IntToStr(layer), '[kg C/ha]', 0.0, false,
      CPool_i[layer, BIOM]);
    VarCreate('N_Biom_' + IntToStr(layer), '[kg N/ha]', 0.0, false,
      NPool_i[layer, BIOM]);
  end;
  OptCreate('c_distributionmethod', 'even', C_distributionmethod);
  C_distributionmethod.OptionList.Add('even');
  C_distributionmethod.OptionList.Add('user specific');

  OptCreate('ResidueIncorp', 'InSoil', ResidueIncorp);
  ResidueIncorp.OptionList.Add('InSoil');
  ResidueIncorp.OptionList.Add('OnTop');

  OptCreate('f_abiot_min_Calcmethod', 'Verbruggen',
    f_abiot_min_Calcmethod_Option,
    'Option for the abiotic factor for mineralisation');
  f_abiot_min_Calcmethod_Option.OptionList.Add('Verbruggen');
  f_abiot_min_Calcmethod_Option.OptionList.Add('Petersen');
  f_abiot_min_Calcmethod_Option.OptionList.Add('Zhou');
  f_abiot_min_Calcmethod_Option.OptionList.Add('DAISY');
  f_abiot_min_Calcmethod_Option.OptionList.Add('Mueller');

  OptCreate('f_abiot_nit_Calcmethod', 'Verbruggen',
    f_abiot_nit_Calcmethod_Option,
    'Option for the abiotic factor for mineralisation');
  f_abiot_nit_Calcmethod_Option.OptionList.Add('Verbruggen');
  f_abiot_nit_Calcmethod_Option.OptionList.Add('Petersen');
  f_abiot_nit_Calcmethod_Option.OptionList.Add('Zhou');
  f_abiot_nit_Calcmethod_Option.OptionList.Add('DAISY');
  f_abiot_nit_Calcmethod_Option.OptionList.Add('Mueller');

  OptCreate('f_abiot_den_Calcmethod', 'Mueller', f_abiot_den_Calcmethod_Option,
    'Option for the abiotic factor for mineralisation');
  f_abiot_den_Calcmethod_Option.OptionList.Add('Petersen');
  f_abiot_den_Calcmethod_Option.OptionList.Add('Zhou');
  f_abiot_den_Calcmethod_Option.OptionList.Add('DAISY');
  f_abiot_den_Calcmethod_Option.OptionList.Add('Mueller');
  f_abiot_den_Calcmethod_Option.OptionList.Add('APSIM');

  VarCreate('NH4_0_10', '[kg N/ha]', 0.0, false, NH4_0_10,
    'NH4 in 0 to 10 cm soil depth [kg N/ha]');
  VarCreate('NH4_0_30', '[kg N/ha]', 0.0, false, NH4_0_30,
    'NH4 in 0 to 30 cm soil depth [kg N/ha]');
  VarCreate('NH4_30_60', '[kg N/ha]', 0.0, false, NH4_30_60,
    'NH4 in 30 to 60 cm soil depth [kg N/ha]');
  VarCreate('NH4_60_90', '[kg N/ha]', 0.0, false, NH4_60_90,
    'NH4 in 60 to 90 cm soil depth [kg N/ha]');
  VarCreate('NH4_0_60', '[kg N/ha]', 0.0, false, NH4_0_60,
    'NH4 in 0 to 60 cm soil depth [kg N/ha]');
  VarCreate('NH4_0_90', '[kg N/ha]', 0.0, false, NH4_0_90,
    'NH4 in 0 to 90 cm soil depth [kg N/ha]');
  VarCreate('Nmin0_10', '[kg N/ha]', 0.0, false, Nmin0_10,
    'Soil mineral nitrogen in 0 to 10 cm soil depth [kg N/ha]');
  VarCreate('Nmin0_30', '[kg N/ha]', 0.0, false, Nmin0_30,
    'Soil mineral nitrogen in 0 to 30 cm soil depth [kg N/ha]');
  VarCreate('Nmin30_60', '[kg N/ha]', 0.0, false, Nmin30_60,
    'Soil mineral nitrogen in 30 to 60 cm soil depth [kg N/ha]');
  VarCreate('Nmin60_90', '[kg N/ha]', 0.0, false, Nmin60_90,
    'Soil mineral nitrogen in 60 to 90 cm soil depth [kg N/ha]');
  VarCreate('Nmin0_60', '[kg N/ha]', 0.0, false, Nmin0_60,
    'Soil mineral nitrogen in 0 to 60 cm soil depth [kg N/ha]');
  VarCreate('Nmin0_90', '[kg N/ha]', 0.0, false, Nmin0_90,
    'Soil mineral nitrogen in 0 to 90 cm soil depth [kg N/ha]');
end;

procedure TSoilMinNH4.init(Var GlobMod: TMod);

var
  layer: integer;
  Pool: Pools;
  c_frac_control: real;

begin
  inherited init(GlobMod);
  BulkDensity.v := iBulkDensity.v;
  if C_distributionmethod.Option = 'even' then
  begin // default option, calculates fractions evenly distributed between all organic soil layers
    for layer := 1 to trunc(NOrgLayers.v) do
      c_frac[layer].v := 1 / trunc(NOrgLayers.v);
    for layer := trunc(NOrgLayers.v) + 1 to MaxNOrgLayers do
      c_frac[layer].v := 0.0;
  end;

  c_frac_control := 0; // if not overwritten by previous routine, fractions from inifile are used and a control variable is calculated here
  for layer := 1 to trunc(NOrgLayers.v) do
    c_frac_control := c_frac_control + c_frac[layer].v;
  if (c_frac_control > (1 + 1E-5)) or (c_frac_control < (1 - 1E-5)) then
    showmessage('Error in fractioning of organic matter between layers!');

  C_ges.v := 0.5 * OrgDepth.v / 100 * 1E4 * 1000 * iBulkDensity.v *
    HumusContent.v;
  N_ges.v := C_ges.v / CN[SOM].v;

  for layer := 1 to trunc(NOrgLayers.v) do
  begin
    Net_min[layer].v := 0.0;
    f_abiot_min[layer].v := 1.0;
    BBf[layer].v := 1.0;
    cum_N2O[layer].v := 0;
    f_abiot_nit[layer].v := 1.0;
    f_abiot_den[layer].v := 1.0;
  end;

  if C_ER.v > 0.0 then
    f_DPM.v := (-N_ER.v * CN[DPM].v * CN[RPM].v / C_ER.v + CN[DPM].v) /
      (-CN[RPM].v + CN[DPM].v)
  else
    f_DPM.v := 0.0;

  SumMinr.v := 0.0;
  Net_ming.v := 0.0;

  CPool[DPM].v := 0.0; // set sum to zero
  CPool[RPM].v := 0.0; // set sum to zero

  for layer := 1 to trunc(NOrgLayers.v) do
  begin
    CPool[DPM].v := CPool[DPM].v + CPool[DPM].v; // if 'historic' residues are present they are added first to the total sums
    CPool[RPM].v := CPool[RPM].v + CPool[RPM].v; // if 'historic' residues are present they are added first to the total sums
  end;

  CPool[DPM].v := CPool[DPM].v + C_ER.v * f_DPM.v; // total pools for all layers
  NPool[DPM].v := CPool[DPM].v / CN[DPM].v;
  CPool[RPM].v := CPool[RPM].v + C_ER.v * (1 - f_DPM.v);
  NPool[RPM].v := CPool[RPM].v / CN[RPM].v;
  CPool[SOM].v := C_ges.v * (1 - f_biom.v);
  NPool[SOM].v := CPool[SOM].v / CN[SOM].v;
  CPool[BIOM].v := C_ges.v * f_biom.v;
  NPool[BIOM].v := CPool[BIOM].v / CN[BIOM].v;

  If lowercase(ResidueIncorp.Option) = 'insoil' then
  begin
    for layer := 1 to trunc(NOrgLayers.v) do
    begin
      for Pool := DPM to SOM do
      begin
        CPool_i[layer, Pool].v := CPool[Pool].v * c_frac[layer].v;
        NPool_i[layer, Pool].v := CPool_i[layer, Pool].v / CN[Pool].v;
      end;
    end;
  end;
  If lowercase(ResidueIncorp.Option) = 'ontop' then
  begin
    for Pool := DPM to RPM do
    begin
      CPool_i[0, Pool].v := CPool[Pool].v;
      NPool_i[0, Pool].v := CPool_i[0, Pool].v / CN[Pool].v;
    end;
    for layer := 1 to trunc(NOrgLayers.v) do
    begin
      for Pool := BIOM to SOM do
      begin
        CPool_i[layer, Pool].v := CPool[Pool].v * c_frac[layer].v;
        NPool_i[layer, Pool].v := CPool_i[layer, Pool].v / CN[Pool].v;
      end;
    end;
  end;

  for layer := 0 to trunc(NOrgLayers.v) do
  begin
    MinProcesses[layer, dpm_biom].init('dpm_biom', k_dpm_biom, E_dpm_biom, DPM,
      BIOM);
    MinProcesses[layer, rpm_biom].init('rpm_biom', k_rpm_biom, E_rpm_biom, RPM,
      BIOM);
    MinProcesses[layer, som_biom].init('som_biom', k_som_biom, E_som_biom, SOM,
      BIOM);
    MinProcesses[layer, biom_som].init('biom_som', k_biom_som, E_biom_som,
      BIOM, SOM);
  end;

  if uppercase(f_abiot_min_Calcmethod_Option.Option) = uppercase('Verbruggen')
    then
    f_abiot_min_Calcmethod := Verbruggen;
  if uppercase(f_abiot_min_Calcmethod_Option.Option) = uppercase('Petersen')
    then
    f_abiot_min_Calcmethod := Petersen;
  if uppercase(f_abiot_min_Calcmethod_Option.Option) = uppercase('Zhou') then
    f_abiot_min_Calcmethod := Zhou;
  if uppercase(f_abiot_min_Calcmethod_Option.Option) = uppercase('DAISY') then
    f_abiot_min_Calcmethod := DAISY;
  if uppercase(f_abiot_min_Calcmethod_Option.Option) = uppercase('Mueller') then
    f_abiot_min_Calcmethod := Mueller;
  if uppercase(f_abiot_min_Calcmethod_Option.Option) = uppercase('APSIM') then
    f_abiot_min_Calcmethod := APSIM;

  if uppercase(f_abiot_nit_Calcmethod_Option.Option) = uppercase('Verbruggen')
    then
    f_abiot_nit_Calcmethod := Verbruggen;
  if uppercase(f_abiot_nit_Calcmethod_Option.Option) = uppercase('Petersen')
    then
    f_abiot_nit_Calcmethod := Petersen;
  if uppercase(f_abiot_nit_Calcmethod_Option.Option) = uppercase('Zhou') then
    f_abiot_nit_Calcmethod := Zhou;
  if uppercase(f_abiot_nit_Calcmethod_Option.Option) = uppercase('DAISY') then
    f_abiot_nit_Calcmethod := DAISY;
  if uppercase(f_abiot_nit_Calcmethod_Option.Option) = uppercase('Mueller') then
    f_abiot_nit_Calcmethod := Mueller;
  if uppercase(f_abiot_nit_Calcmethod_Option.Option) = uppercase('APSIM') then
    f_abiot_nit_Calcmethod := APSIM;

  if uppercase(f_abiot_den_Calcmethod_Option.Option) = uppercase('Verbruggen')
    then
    f_abiot_den_Calcmethod := Verbruggen;
  if uppercase(f_abiot_den_Calcmethod_Option.Option) = uppercase('Petersen')
    then
    f_abiot_den_Calcmethod := Petersen;
  if uppercase(f_abiot_den_Calcmethod_Option.Option) = uppercase('Zhou') then
    f_abiot_den_Calcmethod := Zhou;
  if uppercase(f_abiot_den_Calcmethod_Option.Option) = uppercase('DAISY') then
    f_abiot_den_Calcmethod := DAISY;
  if uppercase(f_abiot_den_Calcmethod_Option.Option) = uppercase('Mueller') then
    f_abiot_den_Calcmethod := Mueller;
  if uppercase(f_abiot_den_Calcmethod_Option.Option) = uppercase('APSIM') then
    f_abiot_den_Calcmethod := APSIM;
end;

procedure TSoilMinNH4.AddResidues(Carbon, nitrogen: real);

begin
  if nitrogen > 0 then
    CN_Residues.v := Carbon / nitrogen
  else
    CN_Residues.v := 0;
  Added_N.c := nitrogen;
  Added_C.c := Carbon;
  if Carbon > 0.0 then
    f_DPM.v := (-nitrogen * CN[DPM].v * CN[RPM].v / Carbon + CN[DPM].v) /
      (-CN[RPM].v + CN[DPM].v)
  else
    f_DPM.v := 0.0;
  CPool_i[0, DPM].v := CPool_i[0, DPM].v + Carbon * f_DPM.v;
  NPool_i[0, DPM].v := NPool_i[0, DPM].v + CPool_i[0, DPM].v / CN[DPM].v;
  CPool_i[0, RPM].v := CPool_i[0, RPM].v + Carbon * (1 - f_DPM.v);
  NPool_i[0, RPM].v := NPool_i[0, RPM].v + CPool_i[0, RPM].v / CN[RPM].v;

  CPool[DPM].v := CPool[DPM].v + Carbon * f_DPM.v;
  NPool[DPM].v := NPool[DPM].v + CPool[DPM].v / CN[DPM].v;
  CPool[RPM].v := CPool[RPM].v + Carbon * (1 - f_DPM.v);
  NPool[RPM].v := NPool[RPM].v + CPool[RPM].v / CN[RPM].v;
end;

procedure TSoilMinNH4.MixLayers(depth: real);

var
  n_layers, layer: byte;
  CPoolav, NPoolav: array [Pools] of real;
  Pool: Pools;

begin
  n_layers := trunc(depth / 10);
  If (depth > 2) and (n_layers < 1) then
    n_layers := 1;
  If n_layers < 1 then
    exit;
  for Pool := low(Pools) to high(Pools) do
  begin // set to zero
    CPoolav[Pool] := 0.0;
    NPoolav[Pool] := 0.0;
  end;
  for layer := 0 to n_layers do
  begin // sum all pools incl. litter layer
    for Pool := low(Pools) to high(Pools) do
    begin
      CPoolav[Pool] := CPoolav[Pool] + CPool_i[layer, Pool].v;
      NPoolav[Pool] := NPoolav[Pool] + NPool_i[layer, Pool].v;
    end;
  end;
  for Pool := low(Pools) to high(Pools) do
  begin // calculate average for soil layers
    CPoolav[Pool] := CPoolav[Pool] / n_layers;
    NPoolav[Pool] := NPoolav[Pool] / n_layers;
  end;
  for layer := 1 to n_layers do
  begin // sum all pools
    for Pool := low(Pools) to high(Pools) do
    begin
      CPool_i[layer, Pool].v := CPoolav[Pool];
      NPool_i[layer, Pool].v := NPoolav[Pool];
    end;
  end;
  for Pool := low(Pools) to high(Pools) do
  begin // Litter layer is empty!!
    CPool_i[0, Pool].v := 0.0;
    CPool_i[0, Pool].c := 0.0;
    NPool_i[0, Pool].v := 0.0;
  end;
end;

function TSoilMinNH4.calc_f_abiot_Verbruggen(WC, temp, BD: real): real;
{ ********************************************************************** }
{ Purpose: Calculation of reduction factor for mineralisation dependent on
  soil moisture and soil temperature, assuming maximal mineralisation
  at 35°C an 35 Vol% water content.

  Quelle: Verbruggen (1985) zit. in Groot (1987)

  Parameter :
  Name             Inhalt                          Einheit      Typ

  WC               volumetric water content        [cm3/cm3]    I
  Temp             soil temperature                [øC]         I
  BD               bulk density                    [g/cm3]      I

  Min_red_f        reduction factor                [-]          O
  { ********************************************************************** }

const
  RefTemp = 20.0; // Reference temperature [°C]
  RefWC = 0.35; // Reference water content
  RefBD = 1.5; // Reference bulk density

var
  a, b, f: real;
  RefMin: real;

begin
  a := 0.22 * power((RefTemp + 0.00064), 1.4425);
  b := 0.1737 * exp(-0.119 * RefTemp) + 0.1107;
  RefMin := a * (1.0 - exp(-b * RefWC / RefBD));
  If temp > 0.0 then
  begin
    a := 0.22 * power((temp + 0.00064), 1.4425);
    b := 0.1737 * exp(-0.119 * temp) + 0.1107;
    f := a * (1.0 - exp(-b * WC / BD));
    f := f / RefMin;
    If f > 3.0 then
      f := 3.0;
    If f < 0.0 then
      f := 0.0;
  end
  else
    f := 0.0;
  result := f;
end;

function TSoilMinNH4.calc_f_abiot_DAISY(ProcessType: T_ProcessType;
  T, pF, WFPS, Clay: real): real;
var
  f_T, f_W, f_Clay: real;
begin
  result := 1;
  case ProcessType of
    minp:
      begin
        if pF < 1.5 then
          f_W := 1 - 0.4 * (1.5 - pF) / 1.5
        else if pF < 2.5 then
          f_W := 1
        else if pF < 6.5 then
          f_W := 1 - 0.25 * (pF - 2.5)
        else
          f_W := 0;
        if T <= 0 then
          f_T := 0
        else if T <= 20 then
          f_T := 0.1 * T
        else if T <= 28 then
          f_T := exp(0.47 - 0.027 * T + 0.00193 * sqr(T))
        else
          f_T := exp(0.47 - 0.027 * 28 + 0.00193 * sqr(28));
        f_T := f_T / exp(0.47 - 0.027 * 28 + 0.00193 * sqr(28));
        f_Clay := 1 - 2 * min(0.25, Clay);
        result := f_W * f_T * f_Clay;
      end;
    nitp:
      begin
        if pF < 1.5 then
          f_W := 1 - (1.5 - pF) / 1.5
        else if pF < 2.5 then
          f_W := 1
        else if pF < 5 then
          f_W := 1 - 0.4 * (pF - 2.5)
        else
          f_W := 0;
        if T <= 2 then
          f_T := 0
        else if T <= 6 then
          f_T := 0.15 * (T - 2)
        else if T <= 20 then
          f_T := 0.1 * T
        else if T <= 28 then
          f_T := exp(0.47 - 0.027 * T + 0.00193 * sqr(T))
        else
          f_T := exp(0.47 - 0.027 * 28 + 0.00193 * sqr(28));
        f_T := f_T / exp(0.47 - 0.027 * 28 + 0.00193 * sqr(28));
        result := f_W * f_T;
      end;
    denp:
      begin
        if T <= 0 then
          f_T := 0
        else if T <= 20 then
          f_T := 0.1 * T
        else if T <= 28 then
          f_T := exp(0.47 - 0.027 * T + 0.00193 * sqr(T))
        else
          f_T := exp(0.47 - 0.027 * 28 + 0.00193 * sqr(28));
        f_T := f_T / exp(0.47 - 0.027 * 28 + 0.00193 * sqr(28));
        if WFPS < 0.8 then
          f_W := 0
        else if WFPS < 0.9 then
          f_W := 2 * (WFPS - 0.8)
        else
          f_W := 0.2 + 0.4 * (WFPS - 0.9);
        result := f_W * f_T;
      end;
  end;
end;

function TSoilMinNH4.calc_f_abiot_Mueller(ProcessType: T_ProcessType;
  T, WFPS: real): real;
type
  TFPoint = record
    X, Y: real;
  end;

  TLookupPoints = array of TFPoint;

var
  f_T, f_W: real;
  LPs: TLookupPoints;

  function LP(X, Y: real): TFPoint;
  begin
    result.X := X;
    result.Y := Y;
  end;

  function LookupF(P: TLookupPoints; X: real): real;
  var
    i: integer;
  begin
    result := P[0].Y;
    for i := low(P) to high(P) - 1 do
      if (X > P[i].X) and (X <= P[i + 1].X) then
        result := P[i].Y + (P[i + 1].Y - P[i].Y) * (X - P[i].X) /
          (P[i + 1].X - P[i].X);
    if X >= P[ high(P)].X then
      result := P[ high(P)].Y;
  end;

  function QF(i, a, o, q, X: real): real;
  begin
    if (X < i) or (X > a) then
      result := 0
    else
      result := (power((X - i), q) * (a - X)) / (power((o - i), q) * (o - X));
  end;

begin
  f_W := 1;
  f_T := 1;
  case ProcessType of
    minp:
      begin
        LPs := TLookupPoints.create(LP(0, 0), LP(0.4, 0.57), LP(0.58, 1),
          LP(0.63, 1), LP(1, 0.36914));
        f_W := LookupF(LPs, WFPS);
        Finalize(LPs);
        f_T := QF(-5, 60, 35, 1.6, T);
      end;
    nitp:
      begin
        LPs := TLookupPoints.create(LP(0, 0), LP(0.087, 0), LP(0.54, 1),
          LP(0.69, 1), LP(1, 0.27));
        f_W := LookupF(LPs, WFPS);
        Finalize(LPs);
        f_T := QF(-10, 50, 30, 2, T);
      end;
    denp:
      begin
        LPs := TLookupPoints.create(LP(0, 0), LP(0.37, 0.06), LP(1, 1));
        f_W := LookupF(LPs, WFPS);
        Finalize(LPs);
        f_T := QF(-15, 75, 30, 1, T);
      end;
  end;
  result := f_W * f_T;
end;

function TSoilMinNH4.calc_f_abiot_APSIM(ProcessType: T_ProcessType;
  T, WC, FK, Sat: real): real;
var
  f_T, f_W: real;
begin
  f_W := 1;
  f_T := 1;
  case ProcessType of
    denp:
      begin
        f_W := min(1, max(0, (WC-FK)/(Sat-FK)));
        f_T := 0.1 * exp(0.046*T);
      end;
  end;
  result := f_W * f_T;
end;

function TSoilMinNH4.Calc_f_abiot(ProcessType: T_ProcessType;
  layer: integer): real;
var
  WFPS, WC, PWP, FK, Sat, T, pH, Clay, pF: real;
begin
  result := 1;
  WC := Theta_Array[layer].v;
  WFPS := Theta_Array[layer].v /(1-BulkDensity.v / 2.65);
  if assigned(fSoilHeatModel) then
    T := fSoilHeatModel.temp[layer].v
  else
    T := temp.v;
  pF := 5 * (1 - WFPS);
  Clay := 0;
  if assigned(fSoilWaterModel) then
  begin
    WC := fSoilWaterModel.theta_arr[layer].v;
    pF := log10(max(1, fSoilWaterModel.psi_arr[layer].v));
    if fSoilWaterModel.Opt_VanGenPars_from_Texture = fromTexture then
      Clay := ClayFromTexture(fSoilWaterModel.Texture[layer]);
    PWP := fSoilWaterModel.WPar[layer].b_psi_f(power(10, 4.2));
    FK := fSoilWaterModel.WPar[layer].b_psi_f(power(10, 1.8));
    Sat := fSoilWaterModel.WPar[layer].b_sat;
    WFPS := (WC - PWP) / (Sat - PWP);
  end;
  pH := Soil_pH.v;

  case ProcessType of
    minp:
      begin
        case f_abiot_min_Calcmethod of
          Verbruggen:
            result := calc_f_abiot_Verbruggen(WC, T, BulkDensity.v);
          Petersen:
            result := 1;
          Zhou:
            result := 1;
          DAISY:
            result := calc_f_abiot_DAISY(minp, T, pF, WFPS, Clay);
          Mueller:
            result := calc_f_abiot_Mueller(minp, T, WFPS);
        end;
      end;
    nitp:
      begin
        case f_abiot_nit_Calcmethod of
          Verbruggen:
            result := calc_f_abiot_Verbruggen(WC, T, BulkDensity.v);
          Petersen:
            result := 1;
          Zhou:
            result := 1;
          DAISY:
            result := calc_f_abiot_DAISY(nitp, T, pF, WFPS, Clay);
          Mueller:
            result := calc_f_abiot_Mueller(nitp, T, WFPS);
        end;
      end;
    denp:
      begin
        case f_abiot_den_Calcmethod of
          Petersen:
            result := 1;
          Zhou:
            result := 1;
          DAISY:
            result := calc_f_abiot_DAISY(denp, T, pF, WFPS, Clay);
          Mueller:
            result := calc_f_abiot_Mueller(denp, T, WFPS);
          APSIM:
            result := calc_f_abiot_APSIM(denp, T, WC, FK, Sat);
        end;
      end;
  end; // of case
end;

function TSoilMinNH4.calcR_NOx_N2O(WFPS: real): real;
begin
  result := exp(-3.79 * WFPS + 2.73); { Zhou et al. 2010 }
end;

procedure TSoilMinNH4.CalcRates;

var
  Pool: Pools; // local iteration variable
  Procs: processes; // local iteration variable
  layer: integer; // local iteration variable
  CO2, active_C, WFPS, WC, PWP, Sat, DFC, // soil gas diffusivity at field capacity
  epsilon, // air filled porosity (at field capacity)
  phi, // total porosity
  k1, // parameter for N2/N2O ratio according to del Grosso et al. 2000
  value: real;
begin
  for layer := 0 to trunc(NOrgLayers.v) do
  begin // set all change rates to zero
    Net_min[layer].v := 0.0;
    for Pool := low(Pools) to high(Pools) do
      CPool_i[layer, Pool].c := 0.0;
  end;

  for Pool := low(Pools) to high(Pools) do // set all change rates to zero
    CPool[Pool].c := 0.0;

  Net_ming.v := 0.0; // set net mineralisation to zero

  f_abiot_min[0].v := 0.5 * Calc_f_abiot(minp, 1); // ( theta_array[1].v, temp.v, BulkDensity.v);      // provisionally set factor for litter layer to 50% of value in first soil layer
  for Procs := low(processes) to high(processes) do
  begin
    MinProcesses[0, Procs].Calculate(f_abiot_min[0].v, f_Nmin[0].v, CN,
      CPool_i[0], NPool_i[0], false);
    NetMinArr[Procs, 0].v := MinProcesses[0, Procs].Nr;
    CFlowArr[Procs, 0].v := MinProcesses[0, Procs].C_flow;
    CO2FlowArr[Procs, 0].v := MinProcesses[0, Procs].CO2_Flow;
    Net_min[0].v := Net_min[0].v + MinProcesses[0, Procs].Nr; // Mineralisation from surface layer is added to first soil layer !
  end;
  Net_ming.v := Net_ming.v + Net_min[0].v;

  for layer := 1 to trunc(NOrgLayers.v) do
  begin
    { michalis-menten like factor to decrease mineralisation under nitrate shortage }
    f_Nmin[layer].v := min(1,
      max(0, (Nmin_Arr[layer].v - MinNmin.v) /
          ((Nmin_Arr[layer].v - MinNmin.v) + km_Nmin.v)));

    { calculation of factors for abiotic influences }
    f_abiot_min[layer].v := Calc_f_abiot(minp, layer) * Layerfactor[layer].v;
    f_abiot_nit[layer].v := Calc_f_abiot(nitp, layer);
    f_abiot_den[layer].v := Calc_f_abiot(denp, layer);

    { Calculation of turn-over between the pools }
    If layer > 1 then
      Net_min[layer].v := 0.0; // In layer 1 the surface layer is included, therefore no reset to 0
    for Procs := dpm_biom to biom_som do
    begin
      if (Procs = biom_som) then // No effect of tillage on the decomposition of biom...
        MinProcesses[layer, Procs].Calculate(f_abiot_min[layer].v,
          f_Nmin[layer].v, CN, CPool_i[layer], NPool_i[layer], false)
      else // ...for all other processes include the tillage factor BBf
        MinProcesses[layer, Procs].Calculate
          (f_abiot_min[layer].v * BBf[layer].v, f_Nmin[layer].v, CN,
          CPool_i[layer], NPool_i[layer], false);
      NetMinArr[Procs, layer].v := MinProcesses[layer, Procs].Nr;
      CFlowArr[Procs, layer].v := MinProcesses[layer, Procs].C_flow;
      CO2FlowArr[Procs, layer].v := MinProcesses[layer, Procs].CO2_Flow;
      Net_min[layer].v := Net_min[layer].v + MinProcesses[layer, Procs].Nr;
    end;

    // if fixation is larger than available Nmin then mineralisation rate has to be reduced !
    If ((Net_min[layer].v * GlobTime.c + Nmin_Arr[layer].v) < MinNmin.v) and
      (Net_min[layer].v < 0) then
    begin
      // reset C changes
      for Pool := DPM to SOM do
        CPool_i[layer, Pool].c := 0.0;
      Net_min[layer].v := 0.0;
      for Procs := dpm_biom to biom_som do
      begin
        // set all nitrate consuming processes to zero!
        // If MinProcesses[layer,Procs].nr<0.0 then
        if (Procs = biom_som) then // No effect of tillage on the decomposition of biom...
          MinProcesses[layer, Procs].Calculate(f_abiot_min[layer].v,
            f_Nmin[layer].v, CN, CPool_i[layer], NPool_i[layer], true)
        else // ...for all other processes include the tillage factor BBf
          MinProcesses[layer, Procs].Calculate
            (f_abiot_min[layer].v * BBf[layer].v, f_Nmin[layer].v, CN,
            CPool_i[layer], NPool_i[layer], true);
        CFlowArr[Procs, layer].v := MinProcesses[layer, Procs].C_flow;
        CO2FlowArr[Procs, layer].v := MinProcesses[layer, Procs].CO2_Flow;
        NetMinArr[Procs, layer].v := MinProcesses[layer, Procs].Nr;

        Net_min[layer].v := Net_min[layer].v + MinProcesses[layer, Procs].Nr;
      end; // loop procs
    end; // end
    Net_ming.v := Net_ming.v + Net_min[layer].v;
  end; // End of Loop over layers

  Net_min[1].v := Net_min[1].v + Net_min[0].v;
  Net_min[0].v := 0.0;
  SumMinr.v := SumMinr.v + Net_ming.v * GlobTime.c;

  For Pool := low(Pools) to high(Pools) do
  begin
    CPool[Pool].c := 0.0;
    for layer := 0 to trunc(NOrgLayers.v) do
    begin // sum up all carbon change rates over soil layers
      CPool[Pool].c := CPool[Pool].c + CPool_i[layer, Pool].c;
    end;
  end;

  for layer := 1 to trunc(NOrgLayers.v) do // Decrease of tillage factor
    BBf[layer].c := -max(0, BBf[layer].v - 1) * kBBf.v;

  For layer := 1 to trunc(NOrgLayers.v) do
  begin // set mineralisation rate in linked transport model
    CO2 := 0;
    for Procs := low(processes) to high(processes) do
      CO2 := CO2FlowArr[Procs, layer].v + CO2;
    NitrificationRate[layer].v := min(1, k_nit.v * f_abiot_nit[layer].v)
      * NH4_Arr[layer].v;
    if Net_min[layer].v < 0 then
      NitrificationRate[layer].v := min(NitrificationRate[layer].v,
        NH4_Arr[layer].v + Net_min[layer].v);

    WFPS := Theta_Array[layer].v / (1 - BulkDensity.v / 2.65);
    k1 := 25;
    if assigned(fSoilWaterModel) then
    begin
      WC   := fSoilWaterModel.theta_arr[layer].v;
      PWP  := fSoilWaterModel.WPar[layer].b_psi_f(power(10, 4.2));
      Sat  := fSoilWaterModel.WPar[layer].b_sat;
      WFPS := (WC - PWP) / (Sat - PWP);
      phi  := Sat; // total porosity
      epsilon := Sat - fSoilWaterModel.WPar[layer].b_psi_f(power(10, 1.8));
      // air filled porosity at FK
      DFC := power(epsilon, (10 / 3)) / sqr(phi); // Millington and Quirk (1961) as cited in Kristensen et al. (2010)
      k1  := max(1.7, 38.4 - 350 * DFC); // Del Grosso et al. (2000)
    end;
    WFPS_Arr[layer].v := WFPS;

    NH4_N2O_rate[layer].v := fr_Nloss_nit.v * NitrificationRate[layer].v *
      (1 / (1 + calcR_NOx_N2O(WFPS)));
    NH4_NOx_rate[layer].v := fr_Nloss_nit.v * NitrificationRate[layer].v *
      (calcR_NOx_N2O(WFPS) / (1 + calcR_NOx_N2O(WFPS)));
    NitrificationRate[layer].v := (1 - fr_Nloss_nit.v) * NitrificationRate[layer].v;

    NH4_Arr[layer].c := Net_min[layer].v - NitrificationRate[layer].v;
    // active_C:= 0.0031*(CPool_i[layer,SOM].v/BulkDensity.v)+24.5;
    // DenitrificationRate[layer].v:=k_den.v*NO3_Arr[layer].v*f_abiot_den[layer].v*active_C;

    DenitrificationRate[layer].v := k_den.v *
      (NO3_Arr[layer].v / (km_den.v + NO3_Arr[layer].v)) * f_abiot_den[layer].v * CO2;
    if CO2 < 0.0001 then
      R_N2_N2O[layer].v := 0.16 * k1 { .v } * max(0.1, (1.5 * WFPS - 0.32))
    else
      R_N2_N2O[layer].v := max((0.16 * k1 { .v } ), (k1
          { .v } * exp(-0.8 * NO3_Arr[layer].v / (CO2)))) * max(0.1,
        (1.5 * WFPS - 0.32));
    NO3_N2O_rate[layer].v := DenitrificationRate[layer].v /
      (1 + R_N2_N2O[layer].v);
    NO3_N2_rate[layer].v := DenitrificationRate[layer].v * R_N2_N2O[layer].v /
      (1 + R_N2_N2O[layer].v);

    cum_N2O[layer].c := NO3_N2O_rate[layer].v + NH4_N2O_rate[layer].v;
    // set external variable of net NO3 production for NO3 transport submodel
    NetMinRate[layer].v := NitrificationRate[layer].v - DenitrificationRate
      [layer].v;
  end;
  WFPS0_30.v := (WFPS_Arr[1].v + WFPS_Arr[2].v + WFPS_Arr[3].v) * 100 / 3;

  // sum up N2O emissions from all org.layers
  N2O_flux.v := 0;
  N2_flux.v := 0;
  NOx_flux.v := 0;
  cum_N2O_nit.c := 0;
  cum_N2O_den.c := 0;
  For layer := 1 to trunc(NOrgLayers.v) do
  begin
    N2O_flux.v := N2O_flux.v + NO3_N2O_rate[layer].v + NH4_N2O_rate[layer].v;
    cum_N2O_nit.c := cum_N2O_nit.c + NH4_N2O_rate[layer].v;
    cum_N2O_den.c := cum_N2O_den.c + NO3_N2O_rate[layer].v;
    N2_flux.v := N2_flux.v + NO3_N2_rate[layer].v;
    NOx_flux.v := NOx_flux.v + NH4_NOx_rate[layer].v;
  end;

  cum_N2.c := N2_flux.v;
  cum_NOx.c := NOx_flux.v;

  // sum up cumulative N2O emissions from all org.layers
  total_N2O.v := 0;
  For layer := 1 to trunc(NOrgLayers.v) do
    total_N2O.v := total_N2O.v + cum_N2O[layer].v; // add N2O of each layer

  // sum up CO2 emissions from all processes and all org.layers
  CO2_flux.v := 0;
  For layer := 1 to trunc(NOrgLayers.v) do
  begin
    for Procs := low(processes) to high(processes) do
      CO2_flux.v := CO2_flux.v + CO2FlowArr[Procs, layer].v;
  end;
end;

procedure TSoilMinNH4.Integrate;

var
  layer: integer;
  Pool: Pools;
  i: integer;
  NsummeAlt: real;

begin
  inherited Integrate;
  Added_N.c := 0;
  Added_C.c := 0;
  For i := 1 to MaxSoilLayers do
    Nmin_Arr[i].v := NH4_Arr[i].v + NO3_Arr[i].v; // add nitrate and ammonia

  NsummeAlt := NSumme.v;
  NSumme.v := 0.0;
  for Pool := low(Pools) to high(Pools) do
  begin
    NPool[Pool].v := CPool[Pool].v / CN[Pool].v;
    NSumme.v := NSumme.v + NPool[Pool].v;
    for layer := 0 to trunc(NOrgLayers.v) do
      NPool_i[layer, Pool].v := CPool_i[layer, Pool].v / CN[Pool].v;
  end;
  If NsummeAlt > 0.0 then
    NBilanz.v := (NsummeAlt - NSumme.v) / GlobTime.c - Net_ming.v
  else
    NBilanz.v := 0.0;
  N_ER.v := NPool[DPM].v + NPool[RPM].v;
  C_ER.v := CPool[DPM].v + CPool[RPM].v;
  Norg.v := 0.0;
  Corg.v := 0.0;
  for Pool := low(Pools) to high(Pools) do
  begin
    Norg.v := Norg.v + NPool[Pool].v;
    Corg.v := Corg.v + CPool[Pool].v;
  end;
  SumNmin.v := 0;
  if assigned(soilwatermodel) then
    for i := 1 to round(soilwatermodel.bil_nr.v) do
      SumNmin.v := SumNmin.v + Nmin_Arr[i].v;

  NH4_0_10.v := NH4_Arr[1].v;
  NH4_0_30.v := NH4_Arr[1].v + NH4_Arr[2].v + NH4_Arr[3].v;
  NH4_30_60.v := NH4_Arr[4].v + NH4_Arr[5].v + NH4_Arr[6].v;
  NH4_60_90.v := NH4_Arr[7].v + NH4_Arr[8].v + NH4_Arr[9].v;
  NH4_0_60.v := NH4_0_30.v + NH4_30_60.v;
  NH4_0_90.v := NH4_0_30.v + NH4_30_60.v + NH4_60_90.v;
  Nmin0_10.v := Nmin_Arr[1].v;
  Nmin0_30.v := Nmin_Arr[1].v + Nmin_Arr[2].v + Nmin_Arr[3].v;
  Nmin30_60.v := Nmin_Arr[4].v + Nmin_Arr[5].v + Nmin_Arr[6].v;
  Nmin60_90.v := Nmin_Arr[7].v + Nmin_Arr[8].v + Nmin_Arr[9].v;
  Nmin0_60.v := Nmin0_30.v + Nmin30_60.v;
  Nmin0_90.v := Nmin0_30.v + Nmin30_60.v + Nmin60_90.v;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilMinNH4]);
end;

end.
