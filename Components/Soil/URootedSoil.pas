/// <summary>
/// Implements different methods for soil water uptake from a one dimensional soil layer
/// </summary>
/// <remarks>
/// <author>
/// Henning Kage, Dorothee Neukam, Ulf Böttcher & Agronomy Group, University of Kiel
/// </author>
/// </remarks>

unit URootedSoil;

interface

{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}

uses
  USoilWaterMod, UMod, UState,
{$IFNDEF NONVISUAL}
  Vcl.Dialogs,
{$ENDIF}
  ULayeredSoil,
  classes,
  UAbstractPlant,
  WFlowFunctions,
  URootGrowthUtils;

const
  /// <summary> Maximum number of soil layers for root water uptake calculation </summary>
  Max_Root_Index = RootLengthDensityLayerCount;

type
  real = double;

  /// <summary>Water amount contributions assigned to the ten RLD classes in each soil layer [cm].</summary>
  TSoilWaterAmountMatrix = array [1 .. Max_Root_Index,
    1 .. RootLengthDensityMomentCount] of real;

  /// <summary>Water uptake rate contributions assigned to the ten RLD classes in each soil layer [cm.d-1].</summary>
  TSoilWaterSinkMatrix = array [1 .. Max_Root_Index,
    1 .. RootLengthDensityMomentCount] of real;

  /// <summary> Options for calculation of sink reduction factor for root water uptake </summary>
  TSinkTermMethod = (nFK_crit, Psicrit, Psicrit_corr, Feddes, MFP, MFPvar);
  
  /// <summary> Options for calculation of automatic irrigation </summary>
  TAutoirriMethod = (amTransRatio, amProznFKWe, amProznFKActRootedComps);
  
  /// <summary> Options for calculation of sink reduction factor based on root length distribution and potential water uptake </summary>
  T_Sqrwl_Funct = (ReductionFactor, NoReductionFactor);


/// <summary> Model component for adding root soil water uptake to the simulation of vertical (1D) soil water transport
///  The distribution of water uptake over the soil layers and the calculation of drought limited water uptake can
///  be calculated with different options
///  </summary>
  TSoilWaterModelR = class(TSoilWaterMod)

  private
    f_Sqrwl_funct: T_Sqrwl_Funct;
    /// <summary>Link to the total root length density moment matrix.</summary>
    fWldMoments: PRootLengthDensityMomentMatrix;

    /// <summary>Link to the effective root length density moment matrix.</summary>
    fEffWldMoments: PRootLengthDensityMomentMatrix;

    /// <summary> internal variable for summing up all sink terms </summary>
    Sum_Sink: real;
    
    /// <summary> field for option with or without roots, if false water uptake is calculated without considering root distribution and sink reduction,
    /// if true root distribution and sink reduction are considered </summary>
    FWithRoots: boolean;
    
    /// <summary> field for automatic irrigation  (yes/no) </summary>
    fAutoirri: boolean;

    /// <summary> field for automatic irrigation method (amTransRatio, amProznFKWe, amProznFKActRootedComps) </summary>
    fAutoirriMethod: TAutoirriMethod;
    
    /// <summary> source of Psi2 value, could be supplied from plant model </summary>
    fPsi2Opt: TSource;
    
    /// <summary> field for option to use log scale for sink reduction </summary>
    fpsi_logscale: boolean;


    /// <summary> field for sink term calculation method (Feddes, Psicrit, Psicrit_corr, nFKcrit, MFP, MFPvar) </summary>
    FSinkTermMethod: TSinkTermMethod;

    /// <summary> field for option to write the matrix flux table </summary>
    fWriteMFPTable: boolean;

    /// <summary> procedure for setting the with roots option </summary>
    procedure setWithRoots(settrue: boolean);
    procedure CreateOptionsRootedSoil;
    procedure InitializeSoilWaterMatrices;
    /// <summary>Updates the actual standard deviation of volumetric soil water content in every layer.</summary>
    procedure CalculateSoilWaterContentStandardDeviations;
    /// <summary>Calculates MFP-limited water uptake for every RLD moment and soil layer.</summary>
    procedure CalculateSinkMatrix;
    procedure UpdateSoilWaterAmountMatrix(const SurfaceWaterAddition: real);
    // function GetWLD(Index:Integer):real; virtual;

  protected
    /// <summary>Applies the available-water limit and keeps MFPvar moment sinks synchronized with the layer sinks.</summary>
    procedure LimitSinkRatesToAvailableWater; override;

  public
    
    /// <summary> Option for automatic irrigation yes/no </summary>
    AutoIrriOptStr: Toption;

    /// <summary> Option for method of automatic irrigation (amTransRatio, amProznFKWe, amProznFKActRootedComps) </summary>
    AutoIrriMethodOptStr: Toption;

    /// <summary> Option for method of sink term calculation (Feddes, Psicrit, Psicrit_corr, nFKcrit, MFP, MFPvar) </summary>
    SinkTermMethodOptStr: Toption;
    
    /// <summary> Option to write the matrix flux table </summary>
    WriteMFPTable: Toption;

    /// <summary> Array for soil water content differences between bulk soil and root surface for each soil layer </summary>
    WcontDiff_arr: TSoilvarArray;
    /// <summary> Matrix potential differences between root surface and bulk soil [cm3/cm3] </summary>
    PsiRootDiff_arr: TSoilvarArray;
    
    /// <summary> Array for proportional nFK values for each soil layer </summary>
    ProzNFK_arr: TSoilvarArray;

    /// <summary> Array for effective root length density distribution [cm/cm3] </summary>
    ExWld_arr: TSoilExtArray;
    /// <summary>Water amount contributions whose row sum equals WAmount for the soil layer [cm].</summary>
    SoilWaterAmountMatrix: TSoilWaterAmountMatrix;

    /// <summary>Water uptake contributions whose row sum equals Sink_arr for the soil layer [cm.d-1].</summary>
    SinkMatrix: TSoilWaterSinkMatrix;

    /// <summary>Actual standard deviation of volumetric soil water content in each layer [cm3.cm-3].</summary>
    ThetaStdDev_arr: TSoilVarArray;
    
    /// <summary> Total root length density [cm/m2] </summary>
    WLges: TVar;
    
    // w_influx : TSoilVarArray; /// Wasserinfluxraten [cm3.cm-1.d-1]
    
    /// <summary> Array for sink reduction factors for each soil layer </summary>
    SinkRedF: TSoilArray;
    
    /// <summary>average, weighted soil water potential within the rooting zone [pF] </summary>
    psiRoot: TVar;
    
    /// <summary> water potential at which water uptake by the plant starts to decrease [hPa] </summary>
    psi_2: Tpar;
    
    /// <summary> water potential at which water uptake by the plant stops [hPa] </summary>
    psi_3: Tpar;
    
    /// <summary> root competition factor, 1 leads to proportional potential water uptake by relative root length, 0.5 accounts for root competition </summary>
    CompFactor : Tpar;
    
    /// <summary> amount of irrigation [mm] if automatic irrigation </summary>
    IrriAmount: TPar;
    
    /// <summary> critical nFK value for triggering irrigation if automatic irrigation </summary>
    Autoirri_nFKcrit: Tpar;
    /// <summary> critical nFK value for triggering irrigation </summary>
    nfk_threshold: Tpar;
    /// <summary> Feddes parameter a </summary>
    feddes_a: Tpar;
    /// <summary> Feddes parameter b </summary>
    feddes_b: Tpar;
    /// <summary> Feddes parameter c </summary>
    feddes_c: Tpar;
    /// <summary> actual proportional nFK values for rooted compartments </summary>
    ProznFK_act_rooted_comps: TVar;
    /// <summary> critical nFK value for sink reduction </summary>
    nFKcrit: Tpar;
    
    /// <summary> potential transpiration (external variable) </summary>
    PotTrans: TexternV;
    
    /// <summary> interception (external variable) </summary>
    Interzeption: TexternV;
    
    /// <summary> actual transpiration rate [mm/d] </summary>
    ActTrans: TVar;
    
    /// <summary> ratio of actual to potential transpiration </summary>
    TransRatio: TVar;
    
    /// <summary> ratio of actual to potential sum of transpiration and interception </summary>
    TransIntRatio: TVar;
    
    /// <summary> ratio of actual to potential evapotranspiration </summary>
    Eact_ETP: TVar;
    
    /// <summary> Ratio of act. evaporation to pot. evapotranspiration </summary>
    Psi2: TVar;
    
    /// <summary> water potential at which water uptake by the plant starts to decrease [hPa] </summary>
    act_rooted_comps: TVar;
    /// <summary> actual number of rooted compartiments </summary>
    EmergenceDay: TexternV;
    
    /// <summary> sum of Autoirrigation </summary>
    CumAutoIrrigation: TState;
    
    /// <summary> cum. Transpiration </summary>
    CumTrans: TState;
    /// <summary> cum. actual Evapotranspiration </summary>
    CumET: TState;
    /// <summary> cumulative actual Evapotranspiration </summary>
    CumETpot: TState;
    /// <summary> cumulative potential Evapotranspiration </summary>
    CumTranspot: TState;
    /// <summary> cumulative potential Transpiration </summary>
    
    /// <summary> Option for sink reduction (Sqr_wl_arr calculation) </summary>
    f_SqrWl_Option: Toption;

    /// <summary> Option for sink reduction (SinkRedF calculation), log scale true/false </summary>
    psi_logscale: Toption;
    
    /// <summary> root radius </summary>
   r_root: Tpar;
 
    /// <summary> array for matrix flux potential calculation </summary>
    MFP_arr: array [0 .. 20] of TMFP_table;
    /// <summary>Links the total and effective RLD moment matrices supplied by a root model.</summary>
    procedure SetRootLengthDensityMomentMatrices(
      AWldMoments, AEffWldMoments: PRootLengthDensityMomentMatrix);

    procedure SetPlantModel(NewPlantModel: TAbstractplant); override;
    procedure CreateAll; override;

    procedure Init(var GlobMod: TMod); override;

    procedure Calcsink_red_f;
    procedure CalcSinks; override;
    procedure CalcRatesAndIntegrate; override;
    procedure CalcRates; override;
    // procedure Integrate; override;

    /// <summary>Linked total root length density moment matrix.</summary>
    property WldMoments: PRootLengthDensityMomentMatrix read fWldMoments;

    /// <summary>Linked effective root length density moment matrix.</summary>
    property EffWldMoments: PRootLengthDensityMomentMatrix read fEffWldMoments;

    // property Wld_arr[Index : Integer]: real read getWLD;  /// Wurzell�ngendichten [cm.cm-3]

    // procedure Set_GlobMod(value:TMod);override;
  published
    property Ex_PotTrans: TexternV read PotTrans write PotTrans;
    property Ex_Interzeption: TexternV read Interzeption write Interzeption;
    property Ex_EmergenceDay: TexternV read EmergenceDay write EmergenceDay;
    property Par_Psi_2: Tpar read psi_2 write psi_2;
    property Par_psi_3: Tpar read psi_3 write psi_3;
    property Comp_fact: Tpar read CompFactor write CompFactor;
    property Par_nFKcrit: Tpar read nFKcrit write nFKcrit;
    property St_CumTrans: TState read CumTrans write CumTrans;
    property Var_ActTrans: TVar read ActTrans write ActTrans;
    property Var_TransRatio: TVar read TransRatio write TransRatio;
    property Var_ProznFK_act_rooted_comps: TVar read ProznFK_act_rooted_comps
      write ProznFK_act_rooted_comps;
    property Var_TransIntRatio: TVar read TransIntRatio write TransIntRatio;
    property Psi_Root: TVar read psiRoot write psiRoot;
    // property AutoIrrigate: TAutoIrri read fAutoIrrigate write fAutoIrrigate;
    property AutoirriMethod: TAutoirriMethod read fAutoirriMethod
      write fAutoirriMethod;
    property Opt_WithRoots: boolean read FWithRoots write setWithRoots;
    property OptSinkTermMethod: TSinkTermMethod read FSinkTermMethod
      write FSinkTermMethod;
    property Opt_Psi2: TSource read fPsi2Opt write fPsi2Opt;
    // Source of Psi2 value
    property OptWriteMFPtable: boolean read fWriteMFPTable write fWriteMFPTable;

  end;

procedure Register;

implementation

uses
  SysUtils, math; // , dialogs;

procedure TSoilWaterModelR.InitializeSoilWaterMatrices;
var
  LayerIndex, MomentIndex: integer;
  WaterAmountPerClass: real;
begin
  for LayerIndex := 1 to Max_Root_Index do
  begin
    if LayerIndex <= n_comp then
      WaterAmountPerClass := WAmount[LayerIndex].v /
        RootLengthDensityMomentCount
    else
      WaterAmountPerClass := 0.0;

    for MomentIndex := 1 to RootLengthDensityMomentCount do
    begin
      SoilWaterAmountMatrix[LayerIndex, MomentIndex] :=
        WaterAmountPerClass;
      SinkMatrix[LayerIndex, MomentIndex] := 0.0;
    end;
  end;
  CalculateSoilWaterContentStandardDeviations;
end;

procedure TSoilWaterModelR.CalculateSoilWaterContentStandardDeviations;
var
  LayerIndex, MomentIndex: integer;
  LocalTheta, MeanTheta, SumSquaredDeviations: real;
begin
  for LayerIndex := 1 to Max_Root_Index do
  begin
    if (LayerIndex <= n_comp) and (Thick[LayerIndex] > 0.0) then
    begin
      MeanTheta := 0.0;
      for MomentIndex := 1 to RootLengthDensityMomentCount do
      begin
        LocalTheta := SoilWaterAmountMatrix[LayerIndex, MomentIndex] *
          RootLengthDensityMomentCount / Thick[LayerIndex];
        MeanTheta := MeanTheta + LocalTheta;
      end;
      MeanTheta := MeanTheta / RootLengthDensityMomentCount;

      SumSquaredDeviations := 0.0;
      for MomentIndex := 1 to RootLengthDensityMomentCount do
      begin
        LocalTheta := SoilWaterAmountMatrix[LayerIndex, MomentIndex] *
          RootLengthDensityMomentCount / Thick[LayerIndex];
        SumSquaredDeviations := SumSquaredDeviations +
          sqr(LocalTheta - MeanTheta);
      end;
      ThetaStdDev_arr[LayerIndex].v := sqrt(SumSquaredDeviations /
        RootLengthDensityMomentCount);
    end
    else
      ThetaStdDev_arr[LayerIndex].v := 0.0;
  end;
end;


procedure TSoilWaterModelR.CalculateSinkMatrix;
var
  LayerIndex, MomentIndex: integer;
  MaximumSinkMatrix: TSoilWaterSinkMatrix;
  EffectiveRootLengthDensity, LocalTheta, LocalPsi: real;
  MatrixFluxPotential, MaximumInflux, RootCylinderRadius: extended;
  PotentialProfileSink, RowMomentSum, TotalMaximumSink: real;
begin
  TotalMaximumSink := 0.0;
  Sum_Sink := 0.0;
  act_rooted_comps.v := 0.0;
  psiRoot.v := 0.0;

  for LayerIndex := 1 to Max_Root_Index do
  begin
    if LayerIndex <= n_comp then
      Sink_arr[LayerIndex].v := 0.0;

    RowMomentSum := 0.0;
    if (fEffWldMoments <> nil) and (LayerIndex <= act_n_comp) then
      for MomentIndex := 1 to RootLengthDensityMomentCount do
        RowMomentSum := RowMomentSum +
          max(0.0, fEffWldMoments^[LayerIndex, MomentIndex]);

    if (LayerIndex <= act_n_comp) and (ExWld_arr[LayerIndex].v > 0.0) then
      act_rooted_comps.v := LayerIndex;

    for MomentIndex := 1 to RootLengthDensityMomentCount do
    begin
      SinkMatrix[LayerIndex, MomentIndex] := 0.0;
      MaximumSinkMatrix[LayerIndex, MomentIndex] := 0.0;

      if FWithRoots and (LayerIndex <= act_n_comp) and
        (MFP_arr[LayerIndex] <> nil) then
      begin
        if RowMomentSum > 0.0 then
          EffectiveRootLengthDensity := max(0.0,
            fEffWldMoments^[LayerIndex, MomentIndex])
        else
          EffectiveRootLengthDensity := max(0.0,
            ExWld_arr[LayerIndex].v);

        if EffectiveRootLengthDensity > 0.0 then
        begin
          // Each matrix cell stores one tenth of the layer water amount.
          LocalTheta := SoilWaterAmountMatrix[LayerIndex, MomentIndex] *
            RootLengthDensityMomentCount / Thick[LayerIndex];
          LocalTheta := max(WPar[LayerIndex].b_rest,
            min(WPar[LayerIndex].b_sat, LocalTheta));
          LocalPsi := WPar[LayerIndex].psi_b_f(LocalTheta);
          MatrixFluxPotential := max(0.0,
            MFP_arr[LayerIndex].get_sumku(LocalPsi));
          RootCylinderRadius :=
            abstand_func(EffectiveRootLengthDensity);

          if (MatrixFluxPotential > 0.0) and
            (0.56 * RootCylinderRadius > r_root.v) then
          begin
            MaximumInflux := max(0.0, MFP_IWmax(MatrixFluxPotential,
              RootCylinderRadius, r_root.v));
            MaximumSinkMatrix[LayerIndex, MomentIndex] := MaximumInflux *
              EffectiveRootLengthDensity * Thick[LayerIndex] /
              RootLengthDensityMomentCount;
            TotalMaximumSink := TotalMaximumSink +
              MaximumSinkMatrix[LayerIndex, MomentIndex];
          end;
        end;
      end;
    end;
  end;

  PotentialProfileSink := max(0.0, 0.1 * PotTrans.v);
  if TotalMaximumSink > 0.0 then
    for LayerIndex := 1 to act_n_comp do
      for MomentIndex := 1 to RootLengthDensityMomentCount do
      begin
        SinkMatrix[LayerIndex, MomentIndex] := min(
          MaximumSinkMatrix[LayerIndex, MomentIndex],
          PotentialProfileSink *
          MaximumSinkMatrix[LayerIndex, MomentIndex] / TotalMaximumSink);
        Sink_arr[LayerIndex].v := Sink_arr[LayerIndex].v +
          SinkMatrix[LayerIndex, MomentIndex];
      end;

  for LayerIndex := 1 to act_n_comp do
    Sum_Sink := Sum_Sink + Sink_arr[LayerIndex].v;
end;

procedure TSoilWaterModelR.LimitSinkRatesToAvailableWater;
var
  LayerIndex, MomentIndex: integer;
  OriginalSink, SinkScale, AvailableMomentWater, MaximumMomentSinkRate: real;
  OriginalSinks: TSoilArray;
begin
  for LayerIndex := 1 to n_comp do
    OriginalSinks[LayerIndex] := Sink_arr[LayerIndex].v;

  inherited LimitSinkRatesToAvailableWater;

  if OptSinkTermMethod = MFPvar then
    for LayerIndex := 1 to min(act_n_comp, Max_Root_Index) do
    begin
      OriginalSink := OriginalSinks[LayerIndex];
      if OriginalSink > 0.0 then
        SinkScale := Sink_arr[LayerIndex].v / OriginalSink
      else
        SinkScale := 0.0;

      Sink_arr[LayerIndex].v := 0.0;
      for MomentIndex := 1 to RootLengthDensityMomentCount do
      begin
        SinkMatrix[LayerIndex, MomentIndex] := max(0.0,
          SinkMatrix[LayerIndex, MomentIndex] * SinkScale);
        AvailableMomentWater := max(0.0,
          SoilWaterAmountMatrix[LayerIndex, MomentIndex] -
          PWP_Arr[LayerIndex] * Thick[LayerIndex] /
          RootLengthDensityMomentCount);
        MaximumMomentSinkRate := AvailableMomentWater / dt.v;
        SinkMatrix[LayerIndex, MomentIndex] := min(
          SinkMatrix[LayerIndex, MomentIndex], MaximumMomentSinkRate);
        Sink_arr[LayerIndex].v := Sink_arr[LayerIndex].v +
          SinkMatrix[LayerIndex, MomentIndex];
      end;
    end;

  Sum_Sink := 0.0;
  for LayerIndex := 1 to act_n_comp do
    Sum_Sink := Sum_Sink + Sink_arr[LayerIndex].v;
end;


procedure TSoilWaterModelR.UpdateSoilWaterAmountMatrix(
  const SurfaceWaterAddition: real);
var
  LayerIndex, MomentIndex: integer;
  MeanNetLayerFlow: real;
begin
  for LayerIndex := 1 to Max_Root_Index do
  begin
    if LayerIndex <= n_comp then
    begin
      // WflowInt_arr contains the rates of the accepted adaptive time step.
      // Its first element includes NetRain and Act_Evap in cm.d-1.
      MeanNetLayerFlow := (WflowInt_arr[LayerIndex].v -
        WflowInt_arr[LayerIndex + 1].v) /
        RootLengthDensityMomentCount;
      for MomentIndex := 1 to RootLengthDensityMomentCount do
        SoilWaterAmountMatrix[LayerIndex, MomentIndex] :=
          SoilWaterAmountMatrix[LayerIndex, MomentIndex] +
          (MeanNetLayerFlow - SinkMatrix[LayerIndex, MomentIndex]) * dt.v;
    end
    else
      for MomentIndex := 1 to RootLengthDensityMomentCount do
        SoilWaterAmountMatrix[LayerIndex, MomentIndex] := 0.0;
  end;

  if SurfaceWaterAddition <> 0.0 then
    for MomentIndex := 1 to RootLengthDensityMomentCount do
      SoilWaterAmountMatrix[1, MomentIndex] :=
        SoilWaterAmountMatrix[1, MomentIndex] + SurfaceWaterAddition /
        RootLengthDensityMomentCount;
  CalculateSoilWaterContentStandardDeviations;
end;



procedure TSoilWaterModelR.SetRootLengthDensityMomentMatrices(
  AWldMoments, AEffWldMoments: PRootLengthDensityMomentMatrix);
begin
  fWldMoments := AWldMoments;
  fEffWldMoments := AEffWldMoments;
end;


procedure TSoilWaterModelR.CreateAll;

var
  i: integer;

begin
  inherited CreateAll;
{$IFNDEF NONVISUAL}
  if DebugForm <> NIL then
    DebugForm.MyCreate;
{$ENDIF}
  ParCreate('psi_2', '[cm]', 200, psi_2,
    'soil water tension from which root water uptake reduces if eíther FEDDES, psi_crit or psicrit_corr option is choosen');
  ParCreate('psi_3', '[cm]', 15000, psi_3,
    'lower limit of soil water extraction');
  ParCreate('feddes_a', '[hPa]', 400, feddes_a,
    'Enhancement of psi_2 at high pot. Transp.');
  ParCreate('feddes_b', '[mm/d]', 5, feddes_b, 'Transpiration threshold for psi_2 calculation');
  ParCreate('feddes_c', '[mm/d]', 1, feddes_c,
    'lower transpiration rate threshold for psi_2 calculation, for lower transpiration rates psi_2 not further increased');
  ParCreate('nfk_threshold', '[-]', 0.01, nfk_threshold,
    'threshold (water buffer) for sink reduction');
  ParCreate('CompFactor', '[-]', 0.5, CompFactor,
    'root competition factor, 1 leads to proportional potential water uptake by relative root length, 0.5 accounts for root competition');
  ParCreate('nFKcrit', '[-]', 0.5, nFKcrit,
    'relative soil water content where root water uptake reduces if nFKcrit option is choosen');
  ParCreate('IrriAmount', '[mm]', 10, IrriAmount,
    'Amount of automated irrigation per irrigation');
  ParCreate('Autoirri_nFKcrit', '[%]', 60, Autoirri_nFKcrit,
    'Prozent nFK ab der bewässert wird, wenn AutoirriMeth auf amProznFKWe steht');
  ParCreate('r_root', '[cm]', 0.01, r_root, 'root radius [cm]');

  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans,
    'potential transpiration rate');
  ExternVcreate('Interception', '[mm.d-1]', stateField, Interzeption,
    'interception rate');
  ExternVcreate('EmergenceDay', '[-]', stateField, EmergenceDay,
    'day of emergence taken from plant growth module');

  VarCreate('ActTrans', '[mm.d-1]', 0.0, false, ActTrans,
    'Actual transpiration rate');
  VarCreate('TransRatio', '[-]', 0.0, false, TransRatio,
    'relation between actual and potential transpiration');
  VarCreate('TransIntRatio', '[-]', 0.0, false, TransIntRatio,
    'relation between sum of actual transpiration plus interception and potential transpiration');
  VarCreate('Eact_ETP', '[-]', 0.0, false, Eact_ETP,
    'relation between actual evaporation and potential evapotranspiration');
  VarCreate('psiRoot', '[pF]', 0.0, false, psiRoot,
    'root length weighted soil water tension (log scale)');
  VarCreate('Psi2', '[cm]', 0.0, false, Psi2, '');
  VarCreate('act_rooted_comps', '[n]', 0, true, act_rooted_comps,
    'number of actual rooted soil compartments');
  VarCreate('ProznFK_act_rooted_comps', '[%]', 0.0, false,
    ProznFK_act_rooted_comps, '');

  StateCreate('CumAutoIrrigation', '[mm]', 0, true, CumAutoIrrigation);
  StateCreate('CumTrans', '[mm]', 0, true, CumTrans,
    'cumulative transpiration');
  StateCreate('CumET', '[mm]', 0, true, CumET,
    'cumulative actual evapotranspiration');
  StateCreate('CumETpot', '[mm]', 0, true, CumETpot,
    'cumulative potential evapotranspiration');
  StateCreate('CumTranspot', '[mm]', 0, true, CumTranspot,
    'cumulative potential transpiration');

  for i := 1 to Max_Root_Index do
  begin
    VarCreate('ProzNFK_arr' + ndx_str(i), '[%]', 0.0, false, ProzNFK_arr[i], 'percentage of available water (nFK) in the soil compartment');
    VarCreate('theta_stdev_' + ndx_str(i), '[cm3.cm-3]', 0.0, false,
      ThetaStdDev_arr[i],
      'actual standard deviation of volumetric soil water content in this soil layer');
  end;

  for i := 1 to n_comp do
  begin
    VarCreate('WcontDiff_arr' + ndx_str(i), '[cm3.cm-3]', 0.0, false,
      WcontDiff_arr[i], 'Difference in water content soil root surface');
    VarCreate('PsiRootDiff_arr' + ndx_str(i), '[cm]', 0.0, false,
      PsiRootDiff_arr[i],
      'Difference in matrix potential at soil root surface');
  end;

  if FWithRoots = true then
  begin
    for i := 1 to n_comp do
    begin
      ExternVcreate('effWLD_' + ndx_str(i), '[cm/cm3]', stateField,
        ExWld_arr[i]);
      VarCreate('WAuf' + ndx_str(i), '[cm.d-1]', 0.0, false, Sink_arr[i], 'water uptake rate in the soil compartment');
    end;
  end;
  CreateOptionsRootedSoil;

end;

procedure TSoilWaterModelR.setWithRoots(settrue: boolean);
var
  i: integer;
begin
  if settrue then
    for i := 1 to n_comp do
    begin
      if ExWld_arr[i] = nil then
        ExternVcreate('effWLD_' + ndx_str(i), '[cm/cm3]', stateField,
          ExWld_arr[i]);
      if Sink_arr[i] = nil then
        VarCreate('WAuf' + ndx_str(i), '[cm.d-1]', 0.0, false, Sink_arr[i], 'water uptake rate in the soil compartment');
    end;
  FWithRoots := settrue;
end;

procedure TSoilWaterModelR.Init(var GlobMod: TMod);

var
  i, j: integer;
  f: TextFile;
  fn: string;
begin
  inherited Init(GlobMod);
  if uppercase(f_SqrWl_Option.Option) = uppercase('NoReductionFactor') then
    f_Sqrwl_funct := NoReductionFactor;
  if uppercase(f_SqrWl_Option.Option) = uppercase('ReductionFactor') then
    f_Sqrwl_funct := ReductionFactor;

  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Feddes') then
    OptSinkTermMethod := Feddes;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Psicrit') then
    OptSinkTermMethod := Psicrit;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Psicrit_corr') then
    OptSinkTermMethod := Psicrit_corr;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('nFKcrit') then
    OptSinkTermMethod := nFK_crit;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('MFP') then
    OptSinkTermMethod := MFP;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('MFPvar') then
    OptSinkTermMethod := MFPvar;
  if OptSinkTermMethod = MFPvar then
    InitializeSoilWaterMatrices;
  if uppercase(AutoIrriMethodOptStr.Option) = uppercase('amTransRatio') then
    AutoirriMethod := amTransRatio;
  if uppercase(AutoIrriMethodOptStr.Option) = uppercase('amProznFKWe') then
    AutoirriMethod := amProznFKWe;
  if uppercase(AutoIrriMethodOptStr.Option)
    = uppercase('amProznFKActRootedComps') then
    AutoirriMethod := amProznFKActRootedComps;

  if lowercase(WriteMFPTable.Option) = 'false' then
    fWriteMFPTable := false
  else
    fWriteMFPTable := true;

  if uppercase(AutoIrriOptStr.Option) = uppercase('yes') then
  begin
    fAutoirri := true;
    EmergenceDay.Search := true;
  end
  else
  begin
    fAutoirri := false;
    EmergenceDay.Search := false;
  end;

  ActTrans.v := 0.0;
  CumTrans.v := 0.0;
  CumTrans.c := 0.0;
  CumETpot.v := 0.0;
  CumET.v := 0.0;
  CumTranspot.v := 0.0;
  TransRatio.v := 1.0;
  TransIntRatio.v := 1.0;
  if self.psi_2.v > self.psi_3.v then
    psi_3.v := psi_2.v * 1.1;

  for i := 1 to n_comp do
    Sink_arr[i].v := 0.0;
{$IFNDEF NONVISUAL}
  if DebugForm <> NIL then
    DebugForm.Init;
{$ENDIF}
  if (OptSinkTermMethod = MFP) or (OptSinkTermMethod = MFPvar) then
    for i := 1 to n_comp do
      MFP_arr[i] := TMFP_table.create(WPar[i]);

  if fWriteMFPTable then // Ausgabe der MFP-Table in Datei
    for i := 1 to n_comp do
    begin
      begin
        fn := ExtractFilePath(GlobMod.Get_ControlFileFn) +
          ExtractFileName(GlobMod.ActIniFile.FileName);
        fn := ChangeFileExt(fn, '') + '-MFP_table.csv';
        AssignFile(f, fn);
        Rewrite(f);
        write(f, 'Layer;');
        for j := 0 to 100 do
          write(f, FloatToStr(-1 + j * 5.2 / 100) + ';');
        writeln(f);
        for j := 1 to n_comp do
        begin
          writeln(f, IntToStr(i) + '; ' + MFP_arr[i].getline);
        end;
        CloseFile(f);
      end;
    end;
    

    if lowercase(psi_logscale.Option) = 'false' then
      fpsi_logscale := false
    else
      fpsi_logscale := true;


end;



/// <summary> Sink reduction calculation with 6 options
/// 1) Feddes: reduction factor based on soil water tension thresholds and potential transpiration rate following Feddes et al. (1978)
/// 2) Psicrit: reduction factor based on soil water tension threshold (Psi2) following Van Genuchten (1987)
/// 3) nFKcrit: reduction factor based on relative soil water content (nFK) threshold following Van Genuchten (1987)
/// 4) Psicrit_corr: reduction factor based on soil water tension at the root surface, which is calculated based on potential water uptake and root length distribution, and soil water retention curve
/// 5) MFP: reduction factor based on soil water tension at the root surface, which is calculated based on potential water uptake and root length distribution, and soil water retention curve, with a maximum flow principle (MFP) approach for calculating the potential water uptake
/// </summary>
/// 6) MFPvar: MFP-limited uptake calculated separately for each RLD moment and soil layer
procedure TSoilWaterModelR.Calcsink_red_f;

var
  red_f, psi2_, psi2_low, rPAW: real;

  potMaxInflow, // potential water inflow [cm3/cm/s]
  rl, // root length in that layer
  HalfDistance, // half distance between roots [cm]
  theta_root, // soil water content at root surface
  Psi_Root, // soil water tension at root surface
  iw_max, // maximum soil water influx rate [cm3.cm-1.s-1]
  Wupmax: TSoilArray;
  i: integer;


function f_psi_reduction(psi_root, psi_2, psi_3: real; logscale: boolean): real;

begin
  
  if logscale then
  begin
    if psi_root < psi_2 then
      result := 1.0
    else if psi_root > psi_3 then
      result := 0.0
    else
      result := (log10(psi_root) - log10(psi_3)) /
        (log10(psi_2) - log10(psi_3));
  end
  else
  begin
    if psi_root < psi_2 then
      result := 1.0
    else if psi_root > psi_3 then
      result := 0.0
    else
      result := (psi_root - psi_3) / (psi_2 - psi_3);
  end;

end;


begin

  if OptSinkTermMethod = Feddes then
  begin
    if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet then
      Psi2.v := Plantmodel.Psi2 // Psi2 from plant model
    else
      Psi2.v := psi_2.v; // Psi2 from parameter
    psi2_low := Psi2.v + feddes_a.v;
    if (PotTrans.v < feddes_c.v) then
      psi2_ := psi2_low
    else if (PotTrans.v > feddes_b.v) then
      psi2_ := Psi2.v
    else
      psi2_ := psi2_low + (PotTrans.v - feddes_b.v) *
        ((psi2_low - Psi2.v) / (feddes_c.v - feddes_b.v));
    for i := 1 to (n_comp - 1) do
    begin
      rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
      If psi_arr[i].v < psi2_ then
        red_f := 1.0
      else
 //       red_f := (psi_arr[i].v - psi_3.v) / (psi2_ - psi_3.v);
          red_f := f_psi_reduction(psi_arr[i].v, psi2_, psi_3.v, fpsi_logscale);
      // Staunsse nach Feddes
      // If psi_arr[i].v < 1 then  red_f :=max(0.1,psi_arr[i].v);
      // rPAW:= ((theta_arr[i].v-pwp_arr[i]))/nFK_arr[i];
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedF[i] := red_f;
    end;
  end; // Feddes end

  if OptSinkTermMethod = Psicrit then
  begin
    if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet then
      Psi2.v := Plantmodel.Psi2 // Psi2 from plant model
    else
      Psi2.v := psi_2.v; // Psi2 from parameter
    for i := 1 to (n_comp - 1) do
    begin
      rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
      If psi_arr[i].v < Psi2.v then
        red_f := 1.0
      else
        red_f := f_psi_reduction(psi_arr[i].v, Psi2.v, psi_3.v, fpsi_logscale);
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedF[i] := red_f;
    end; // Psicrit end
  end;
  if OptSinkTermMethod = nFK_crit then
  begin
    for i := 1 to (n_comp - 1) do
    begin
      rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
      If rPAW > nFKcrit.v then
        red_f := 1.0
      else
        red_f := rPAW / nFKcrit.v;
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedF[i] := red_f;
    end;
  end; // nFKcrit end
  if (OptSinkTermMethod = Psicrit_corr) or (OptSinkTermMethod = MFP) then
  begin
    for i := 1 to (n_comp - 1) do
    begin
      if ExWld_arr[i].v > 0.0 then
      begin
        // root length in that layer in cm/ha from RLD [cm.cm-3] to rl in cm.ha-1
        rl[i] := 0.1 * ExWld_arr[i].v * Thick[i] * 1E8;
        
        // water inflow per unit root length [cm3/cm/s], potential water inflow based on potential transpiration and root length
        potMaxInflow[i] := Water_flow_func(self.Sink_arr[i].v * 10, rl[i],
          12, true);

        // average half distance between roots [cm]  
        HalfDistance[i] := abstand_func(ExWld_arr[i].v);
        
        // soil water content at root surface based on potential water inflow and soil water diffusivity [cm3/cm3] with steady state flow assumption
        theta_root[i] := baf(theta_arr[i].v, potMaxInflow[i], Dw_arr[i] / 86400,
          HalfDistance[i], 0.02);
        
        // maximum soil water influx rate [cm3.cm-1.s-1] based on soil water content at root surface, minimum soil water content at root surface, soil water diffusivity and half distance between roots
        iw_max[i] := Iwmax(theta_arr[i].v, pwp_arr[i], Dw_arr[i] / 86400,
          HalfDistance[i], 0.02);
        
        // maximum water uptake per layer [cm/d] based on maximum soil water influx rate and root length in that layer
        Wupmax[i] := iw_max[i] * rl[i] * 1E-4 * 1E-3 * 1E-1;
        
        // soil water tension at root surface based on soil water content at root surface and soil water retention curve
        Psi_Root[i] := min(power(10, 4.2), WPar[i].psi_b_f(theta_root[i]));
        
        // calculation of a soil water content difference between the root surface and the bulk soil
        WcontDiff_arr[i].v := theta_arr[i].v - theta_root[i];
        
        // calculation of a soil water tension difference between the root surface and the bulk soil
        PsiRootDiff_arr[i].v := Psi_Root[i] - psi_arr[i].v;

        // now using this soil water tension at the root surface for calculating the sink reduction factor 
        if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet then
          Psi2.v := Plantmodel.Psi2 // Psi2 from plant model
        else
          Psi2.v := psi_2.v; // Psi2 from parameter

        // relative plant water content of soil layer
        rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
        If Psi_Root[i] < Psi2.v then
          red_f := 1.0
        else
          red_f := f_psi_reduction(Psi_Root[i], Psi2.v, psi_3.v, fpsi_logscale);
        If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
          red_f := 0.0;
        SinkRedF[i] := red_f;
      end
      else
      begin
        SinkRedF[i] := 0.0;
        WcontDiff_arr[i].v := 0.0;
        PsiRootDiff_arr[i].v := 0.0;
      end;
    end;
  end; // Psicrit_corr end
end;

procedure TSoilWaterModelR.CalcSinks;

var
  Sqr_Wl_arr, iw_max: TSoilArray;
  Sum_Sqr_wl, sum_wl: real;
  i: integer;
  MFP_, MFPsink: extended;
  Wupmax, rl: TSoilArray;

begin
  inherited CalcSinks;
  if OptSinkTermMethod = MFPvar then
  begin
    CalculateSinkMatrix;
    exit;
  end;
  if FWithRoots = true then
  begin
    Sum_Sqr_wl := 0.0;
    sum_wl := 0.0;
    psiRoot.v := 0.0;

    act_rooted_comps.v := 0.0;
    for i := 1 to act_n_comp do
      if ExWld_arr[i].v > 0.0 then
        act_rooted_comps.v := i;

    if ShowWarnings then
      if act_rooted_comps.v > self.bil_nr.v then
{$IFNDEF NONVISUAL}
        showmessage
          ('Number of rooted compartments larger than balance index, computed balance probably not correct');
{$ELSE}
        writeln('Number of rooted compartments larger than balance index, computed balance probably not correct');
{$ENDIF}

    for i := 1 to act_n_comp do
    begin
    /// Calculation of sink reduction factor based on root length density distribution and potential water uptake per layer
      case f_Sqrwl_funct of
        NoReductionFactor:
          Sqr_Wl_arr[i] := power(ExWld_arr[i].v * Thick[i], CompFactor.v);
        ReductionFactor:
          Sqr_Wl_arr[i] := SinkRedF[i] * power(ExWld_arr[i].v * Thick[i],
            CompFactor.v);
      end;
      sum_wl := sum_wl + ExWld_arr[i].v * Thick[i];
      Sum_Sqr_wl := Sum_Sqr_wl + Sqr_Wl_arr[i];
    end;

    Sum_Sink := 0.0;
    for i := 1 to act_n_comp do
    begin
      if Sqr_Wl_arr[i] > 1E-6 then
        // sink term calculation with proportional distribution of potential transpiration based on root length density distribution and sink reduction factor
        // note the change of the units from [mm/d] to [cm/d] by multiplying with 0.1
        Sink_arr[i].v := 0.1 * PotTrans.v * Sqr_Wl_arr[i] / Sum_Sqr_wl
      else
        Sink_arr[i].v := 0.0;

      // sink term calculation with matrix flux potential based calculation of maximum root water uptake
      if OptSinkTermMethod = MFP then
      begin
        if ExWld_arr[i].v > 0 then
        begin
          // calculation of matrix by numerically integration of the unsaturated hydraulic conductivity from PWP to the actual soil water potential
          MFP_ := MFP_arr[i].get_sumku(psi_arr[i].v);
          // from RLD [cm.cm-3] to rl in cm.ha-1
          rl[i] := ExWld_arr[i].v * Thick[i] * 1E8;
//          iw_max[i] := Iwmax(theta_arr[i].v, pwp_arr[i], Dw_arr[i] / 86400,
//            abstand_func(ExWld_arr[i].v), 0.02);
//          Wupmax[i] := iw_max[i] * rl[i] * 1E-4 * 1E-3 * 1E-1;
          // maximum water uptake per layer [cm/d]
          MFPsink := max(0, min(Sink_arr[i].v, MFP_Inflow(ExWld_arr[i].v,
            Thick[i], MFP_, r_root.v, Sink_arr[i].v)));
          if Sink_arr[i].v > 0 then
            SinkRedF[i] := MFPsink / Sink_arr[i].v
          else
            SinkRedF[i] := 0;
          Sink_arr[i].v := MFPsink;
        end
        else
          Sink_arr[i].v := 0.0;
      end
      else
        Sink_arr[i].v := max(0, Sink_arr[i].v * SinkRedF[i]);
      Sum_Sink := Sum_Sink + Sink_arr[i].v;
    end;
  end; // withRoots
end;

procedure TSoilWaterModelR.CalcRatesAndIntegrate;

var
  Sum_ProzNFK: real;
  i: byte;
  IntegratedTopWaterAmount: real;

begin
  if FWithRoots and (OptSinkTermMethod <> MFPvar) then
    Calcsink_red_f;
  // CalcSinks;
  Sum_ProzNFK := 0.0;

  inherited CalcRatesAndIntegrate;
  IntegratedTopWaterAmount := WAmount[1].v;
  if ExWld_arr[1].v > 0.0 then
  begin // Sind Wurzeln da ?
    for i := 1 to Max_Root_Index do
    begin
      if ExWld_arr[i].v > 0.0 then
        ProzNFK_arr[i].v := ((theta_arr[i].v - pwp_arr[i]) / nFK_arr[i]) * 100;
    end;

    for i := 1 to Max_Root_Index do
    begin
      Sum_ProzNFK := Sum_ProzNFK + ProzNFK_arr[i].v;
    end;
  end;

  if ExWld_arr[1].v <= 0.0 then
    ProznFK_act_rooted_comps.v := 100
  else
    ProznFK_act_rooted_comps.v := Sum_ProzNFK / act_rooted_comps.v;

  if AutoIrriOptStr.Option = 'yes' then
  begin
    if AutoirriMethod = amTransRatio then
    begin
      if (self.TransRatio.v < 0.99) then
      begin
        WAmount[1].v := WAmount[1].v + self.IrriAmount.v / 10 * dt.v;
        CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v * dt.v;
      end;
    end;
    if AutoirriMethod = amProznFKWe then
    begin
      if (self.ProznFK0_Weff.v < Autoirri_nFKcrit.v) then
      begin
        WAmount[1].v := WAmount[1].v + self.IrriAmount.v / 10 * dt.v;
        CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v * dt.v;
      end;
    end;
    if AutoirriMethod = amProznFKActRootedComps then
    begin
      if (self.ProznFK_act_rooted_comps.v < Autoirri_nFKcrit.v) and
        (EmergenceDay.v > 0) then
      begin
        WAmount[1].v := WAmount[1].v + self.IrriAmount.v / 10 * dt.v;
        CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v * dt.v;
      end;
    end;
  end;

  if OptSinkTermMethod = MFPvar then
    UpdateSoilWaterAmountMatrix(WAmount[1].v -
      IntegratedTopWaterAmount);
  ActTrans.v := ActTrans.v + Sum_Sink * 10.0 * dt.v; // [mm]
  CumTrans.c := ActTrans.v; // cumTrans.c+sum_sink*10.0*dt.v;
end;

procedure TSoilWaterModelR.CalcRates;
begin
  if FWithRoots = true then
  begin
    ActTrans.v := 0.0;
    CumTrans.c := 0.0;
    CumAutoIrrigation.c := 0.0;
  end;
  // for debugging
  // Pottrans.v := 0.0;
  inherited CalcRates;
  if FWithRoots = true then
    ActTrans.v := ActTrans.v / GlobTime.c;
  If GlobTime.v > GlobMod.Starttime then
  begin // add values to water balance
    CumWaterBalance.c := CumWaterBalance.c + CumTrans.c - CumAutoIrrigation.c;
  end;
  If (ActTrans.v > 0.0) and (PotTrans.v > 0) then
  begin
    TransRatio.v := max(0, min(1, ActTrans.v / PotTrans.v));
    TransIntRatio.v :=
      max(0, min(1, (ActTrans.v + Interzeption.v) /
      (PotTrans.v + Interzeption.v))); // ar
  end
  else
  begin
    TransRatio.v := 1.0;
    TransIntRatio.v := 1.0;
  end;
  if ((PotTrans.v + Interzeption.v + pot_Evap.v) > 0.0) then
    Eact_ETP.v := Act_Evap.v / (PotTrans.v + Interzeption.v + pot_Evap.v)
  else
    Eact_ETP.v := 1;
  CumET.c := CumTrans.c + Act_Evap.v;
  CumETpot.c := PotTrans.v + pot_Evap.v;
  CumTranspot.c := PotTrans.v;
{$IFNDEF NONVISUAL}
  if DebugModus and (DebugForm <> NIL) then
    DebugForm.update;
{$ENDIF}
end;

procedure TSoilWaterModelR.CreateOptionsRootedSoil;
begin
  // fAutoIrrigate := no;
  // option for
  OptCreate('SqrWl_Sink_ReductionFactor', 'NoReductionFactor', f_SqrWl_Option,
    'Option for sink reduction (Sqr_wl_arr calculation), non linear/linear distribution of sink according to relative root length');
  f_SqrWl_Option.OptionList.Add('ReductionFactor');
  f_SqrWl_Option.OptionList.Add('NoReductionFactor');

  OptCreate('AutoIrri', 'no', AutoIrriOptStr, 'Option for using an automatic irrigation algorithm');
  AutoIrriOptStr.OptionList.Clear;
  AutoIrriOptStr.OptionList.Add('no');
  AutoIrriOptStr.OptionList.Add('yes');

  OptCreate('AutoIrriMethod', 'amProznFKWe', AutoIrriMethodOptStr, 'Choice for method of automatic irrigation control');
  AutoIrriMethodOptStr.OptionList.Clear;
  AutoIrriMethodOptStr.OptionList.Add('amProznFKWe');
  AutoIrriMethodOptStr.OptionList.Add('amTransRatio');
  AutoIrriMethodOptStr.OptionList.Add('amProznFKActRootedComps');

  OptCreate('SinkTermMethod', 'Feddes', SinkTermMethodOptStr);
  SinkTermMethodOptStr.OptionList.Clear;
  SinkTermMethodOptStr.OptionList.Add('Psicrit');
  SinkTermMethodOptStr.OptionList.Add('Psicrit_corr');
  SinkTermMethodOptStr.OptionList.Add('nFkcrit');
  SinkTermMethodOptStr.OptionList.Add('Feddes');
  SinkTermMethodOptStr.OptionList.Add('MFP');
  SinkTermMethodOptStr.OptionList.Add('MFPvar');
  OptCreate('WriteMFPTable', 'false', WriteMFPTable,
    'Option for MFP tables for each layer as txt-file');
  WriteMFPTable.OptionList.Add('true');
  WriteMFPTable.OptionList.Add('false');

  OptCreate('psi_logscale', 'true', psi_logscale,
    'Option for log scale or linear scale for sink reduction factor calculation');
  psi_logscale.OptionList.Add('true');    
  psi_logscale.OptionList.Add('false');
end;

procedure TSoilWaterModelR.SetPlantModel(NewPlantModel: TAbstractplant);

var
  i: integer;

begin
  inherited;
  if (Plantmodel <> nil) and (Plantmodel.withroots = true) then
  begin
    for i := 1 to n_comp do
    begin
      ExWld_arr[i].Search := false;
      ExWld_arr[i].f_v := @Plantmodel.p_WLD[i].fv;
      ExWld_arr[i].source := '[' + NewPlantModel.name + ']';
    end;
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSoilWaterModelR]);
{$ENDIF}
end;

end.
