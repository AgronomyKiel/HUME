/// <summary>
/// This unit defines the TGrowthCurvePlantRoots class, which extends its parent class to
/// model the growth of plant roots. It evaluates parameters such as root depth, root
/// length and the associated growth rates. The unit also calculates root length density
/// and effective root length and provides several models for the development of root
/// depth. Optional features include root ageing and different choices for depth growth.
/// </summary>
/// <remarks>
/// TGrowthCurvePlantRoots inherits from TGrowthCurvePlant and provides specific
/// implementations for root growth dynamics. It exposes properties for root depth,
/// root length and growth parameters, as well as methods for initialising and
/// calculating growth rates based on the current state of the plant and the prevailing
/// environmental conditions.
/// </remarks>

unit UGrowthCurvePlantRoots;

interface

uses
  UState,
  UMod,
  UlayeredSoil,
  UGrowthCurvePlant,
  UAbstractPlant,
  URootGrowthUtils,
  URootedSoil,
  classes;

type

  /// <summary> TGrowthCurvePlantRoots extends TGrowthCurvePlant to model root growth dynamics. </summary>
  TGrowthCurvePlantRoots = class(TGrowthCurvePlant)

  private
    fRootedSoilWaterModel: TSoilWaterModelR;

    function WLD_z_t_f(z1, z2, TotalRootLength: real): real;
    procedure ResetRoots;
    procedure CalculateRootLengthDensityMoments;
    procedure SetRootedSoilWaterModel(const Value: TSoilWaterModelR);
  protected
    function GetWldMomentsAddress: PRootLengthDensityMomentMatrix; override;
    function GetEffWldMomentsAddress: PRootLengthDensityMomentMatrix; override;

    function GetWLD(Index: Integer): THumeNumEntity; override;

    function GetSumRootLength: THumeNumEntity; override;
    function GetSumRootLength_eff: THumeNumEntity; override;

  public
    /// <summary>Circular root-age cohorts and running active lengths.</summary>
    Root_Matrix: array [1 .. Max_Comp] of TRootAgeCohorts;
    n_age_cl, RootAgeHead, ActiveAgeClassCount: Integer;
    ActiveRootLength: array [1 .. Max_Comp] of real;
    /// <summary>Root length calculation: growth curve (default) or fine-root biomass.</summary>
    SRLcalc: TOption;
    /// <summary>Specific root length in cm per g fine-root dry matter.</summary>
    sp_RL: TPar;
    /// <summary>Optional within-layer lognormal RLD variation.</summary>
    CalcMoments: TOption;
    VK_lrv_int, VK_lrv_slope: TPar;
    VK_lrv: array [1 .. RootLengthDensityLayerCount] of TVar;
    Wld_moments, EffWld_moments: TRootLengthDensityMomentMatrix;
    WldStdDev_arr, EffWldStdDev_arr: TSoilVarArray;


    /// <summary>Active duration of root growth.</summary>
    ActiveDuration: TPar;

    /// <summary>Array of root length densities [cm.cm-3].</summary>
    Wld_arr: TSoilVarArray; // Root length densities [cm.cm-3]

    /// <summary>Array of root lengths [cm.cm-2].</summary>
    WL_arr: TSoilVarArray; // Root lengths [cm.cm-2]
    /// <summary>Array of effective root length densities [cm.cm-3].</summary>
    EffWld_arr: TSoilVarArray; // Effective root length density [cm.cm-3]
    /// <summary>Array of effective root lengths [cm.cm-2].</summary>
    effWL_arr: TSoilVarArray; // Active root length [cm.cm-2]

    /// <summary>Number of potential rooted soil layers.</summary>
    N_Rootcomp: TVar;

    /// <summary>Soil depth for each root component [cm].</summary>
    Tiefe: TSoilExtArray;

    /// <summary>Root depth at planting or sowing [cm].</summary>
    zr_0: TPar;

    /// <summary>Maximum rooting depth [cm].</summary>
    zr_max: TPar;
    /// <summary>Root length at planting or sowing [cm].</summary>
    WL_0: TPar;
    /// <summary>Maximum root length [cm].</summary>
    WL_max: TPar;

    /// <summary>Growth-rate parameter for root depth development [cm.d-1.°C].</summary>
    k_z: TPar;
    /// <summary>Growth-rate parameter for root depth in an exponential phase [cm.d-1.°C].</summary>
    k_za: TPar;

    /// <summary>Growth-rate parameter for root length development [cm.d-1.°C].</summary>
    k_Wl: TPar;

    /// <summary>Parameter for the vertical distribution of root length; ratio of RLD at z=0 to RLD at z=zr [-].</summary>
    K_a: TPar;

    /// <summary>Base temperature for root growth.</summary>
    TempSumRootBaseTemp: TPar;

    /// <summary>Sum of root length [cm.cm-2].</summary>
    SRL: TVar;

    /// <summary>Sum of effective root length [cm.cm-2].</summary>
    SRL_eff: TVar;

    /// <summary>State variable for root depth [cm].</summary>
    zr: TState;

    /// <summary>Option for the root depth growth model.</summary>
    depthgrowthOptStr: TOption;

    /// <summary>Option for root ageing.</summary>
    Opt_RootAgeing: TOption;

    depthgrowthchoice: TRootingdepthIncrease;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcRates; override;

  published

    property RootedSoilWaterModel: TSoilWaterModelR read fRootedSoilWaterModel
      write SetRootedSoilWaterModel;
    property Par_sp_RL: TPar read sp_RL write sp_RL;
    property Par_VK_lrv_int: TPar read VK_lrv_int write VK_lrv_int;
    property Par_VK_lrv_slope: TPar read VK_lrv_slope write VK_lrv_slope;
    property Par_zr0: TPar read zr_0 write zr_0;
    property Par_zrmax: TPar read zr_max write zr_max;
    property Par_kz: TPar read k_z write k_z;

    property Par_Wl0: TPar read WL_0 write WL_0;
    property Par_Wlmax: TPar read WL_max write WL_max;
    property Par_kWL: TPar read k_Wl write k_Wl;
    property Par_ActiveDuration: TPar read ActiveDuration write ActiveDuration;
    // property opt_rootdepthgrowthchoice read depthgrowthchoice write depthgrowthchoice;

  end;

procedure Register;

implementation

uses
  SysUtils, math; // , Dialogs;

function TGrowthCurvePlantRoots.WLD_z_t_f(z1, z2,
  TotalRootLength: real): real;
var
  a, RootedBottom, Thickness: real;
begin
  Result := 0.0;
  Thickness := z2 - z1;
  if (Thickness <= 0.0) or (zr.v <= 0.0) or (z1 >= zr.v) or
    (TotalRootLength <= 0.0) then
    exit;
  RootedBottom := min(z2, zr.v);
  if K_a.v <= 0.0 then
    raise EArgumentException.Create('k_a must be positive');
  a := -ln(K_a.v) / zr.v;
  /// <summary>Use full layer thickness, including the unrooted part of a partial layer.</summary>
  if abs(a * zr.v) < 1E-8 then
    Result := TotalRootLength * (RootedBottom - z1) / (zr.v * Thickness)
  else
    Result := TotalRootLength * (exp(-a * z1) - exp(-a * RootedBottom)) /
      ((1 - exp(-a * zr.v)) * Thickness);
end;

function TGrowthCurvePlantRoots.GetWldMomentsAddress: PRootLengthDensityMomentMatrix;
begin
  Result := @Wld_moments;
end;

function TGrowthCurvePlantRoots.GetEffWldMomentsAddress: PRootLengthDensityMomentMatrix;
begin
  Result := @EffWld_moments;
end;

procedure TGrowthCurvePlantRoots.SetRootedSoilWaterModel(const Value: TSoilWaterModelR);
begin
  if fRootedSoilWaterModel <> nil then
    fRootedSoilWaterModel.SetRootLengthDensityMomentMatrices(nil, nil);
  fRootedSoilWaterModel := Value;
  if Value <> nil then
    Value.SetRootLengthDensityMomentMatrices(WldMomentsAddress, EffWldMomentsAddress);
end;

procedure TGrowthCurvePlantRoots.ResetRoots;
var
  i: Integer;
begin
  FillChar(Root_Matrix, SizeOf(Root_Matrix), 0);
  FillChar(ActiveRootLength, SizeOf(ActiveRootLength), 0);
  FillChar(Wld_moments, SizeOf(Wld_moments), 0);
  FillChar(EffWld_moments, SizeOf(EffWld_moments), 0);
  n_age_cl := 0;
  RootAgeHead := 0;
  ActiveAgeClassCount := min(max(trunc(ActiveDuration.v), 0), MaxAgeCl);
  SRL.v := 0.0;
  SRL_eff.v := 0.0;
  zr.v := 0.0;
  zr.c := 0.0;
  for i := 1 to RootLengthDensityLayerCount do
  begin
    Wld_arr[i].v := 0.0;
    WL_arr[i].v := 0.0;
    EffWld_arr[i].v := 0.0;
    effWL_arr[i].v := 0.0;
    VK_lrv[i].v := 0.0;
    WldStdDev_arr[i].v := 0.0;
    EffWldStdDev_arr[i].v := 0.0;
  end;
end;

procedure TGrowthCurvePlantRoots.CalculateRootLengthDensityMoments;
var
  LayerIndex: integer;
begin
  for LayerIndex := 1 to RootLengthDensityLayerCount do
  begin
    if SameText(CalcMoments.Option, 'true') and
      (Wld_arr[LayerIndex].v > 0.0) then
      VK_lrv[LayerIndex].v := max(0.0, VK_lrv_int.v +
        VK_lrv_slope.v * ln(Wld_arr[LayerIndex].v))
    else
      VK_lrv[LayerIndex].v := 0.0;

    CalculateLognormalMoments(Wld_arr[LayerIndex].v,
      VK_lrv[LayerIndex].v, Wld_moments[LayerIndex]);
    CalculateLognormalMoments(EffWld_arr[LayerIndex].v,
      VK_lrv[LayerIndex].v, EffWld_moments[LayerIndex]);
    WldStdDev_arr[LayerIndex].v := CalculateMomentStandardDeviation(
      Wld_moments[LayerIndex]);
    EffWldStdDev_arr[LayerIndex].v := CalculateMomentStandardDeviation(
      EffWld_moments[LayerIndex]);
  end;
end;

function TGrowthCurvePlantRoots.GetWLD(Index: Integer): THumeNumEntity;

begin
  result := Wld_arr[index];

end;

function TGrowthCurvePlantRoots.GetSumRootLength: THumeNumEntity;

begin
  result := SRL;

end;

function TGrowthCurvePlantRoots.GetSumRootLength_eff: THumeNumEntity;

begin
  result := SRL_eff;
end;

procedure TGrowthCurvePlantRoots.CreateAll;
var
  i: Integer;
begin
  inherited CreateAll;
  SetEntityDeclarationClass(TGrowthCurvePlantRoots);
  OptCreate('SRLcalc', 'fromGrowthcurve', SRLcalc);
  SRLcalc.OptionList.Add('fromGrowthcurve');
  SRLcalc.OptionList.Add('fromDMfineRoot');
  ParCreate('sp_RL', '[cm/g DM]', 7000, sp_RL, 'Specific fine-root length');
  OptCreate('CalcMoments', 'false', CalcMoments);
  CalcMoments.OptionList.Add('false');
  CalcMoments.OptionList.Add('true');
  ParCreate('VK_lrv_int', '[%]', 0.0, VK_lrv_int, 'Intercept of CV versus ln(mean RLD)');
  ParCreate('VK_lrv_slope', '[%]', 0.0, VK_lrv_slope, 'Slope of CV versus ln(mean RLD)');
  ParCreate('k_za', '[1/degCd]', 0.01, k_za, 'Exponential root depth growth rate');
  ParCreate('zr_0', '[cm]', 10, zr_0, 'planting/sowing depth');
  ParCreate('zr_max', '[cm]', 120, zr_max, 'maximum rooting depth');
  ParCreate('WL_0', '[cmcm2]', 1, WL_0, 'root length at begin of root growth');
  ParCreate('WL_max', '[cm/cm2]', 15, WL_max, 'maximum root length');
  ParCreate('k_z', '[cm.d-1.C]', 0.09, k_z,
    'rooting depth increase parameter, value depends on choice of rooting depth model! ');
  ParCreate('k_WL', '[cm.d-1.�C]', 0.002, k_Wl);
  ParCreate('k_a', '[-]', 0.01, K_a, 'Ratio of RLD at z=0 and RLD at z=zr');
  ParCreate('TempSumRootBaseTemp', '[°C]', 0, TempSumRootBaseTemp,
    'Base temperature for root growth');
  VarCreate('N_Rootcomp', '[n]', 20, true, N_Rootcomp);
  StateCreate('zr', '[cm]', 0, true, zr, 'rooting depth');
  VarCreate('SRL', '[cm.cm-2]', 0.0, false, SRL, 'som of root length');
  VarCreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff,
    'sum of effective root length');
  for i := 1 to RootLengthDensityLayerCount do
  begin
    VarCreate('VK_lrv_' + ndx_str(i), '[%]', 0.0, false, VK_lrv[i]);
    VarCreate('WLD_stdev_' + ndx_str(i), '[cm.cm-3]', 0.0, false, WldStdDev_arr[i]);
    VarCreate('effWLD_stdev_' + ndx_str(i), '[cm.cm-3]', 0.0, false, EffWldStdDev_arr[i]);
  end;

  /// <summary>Use the inherited WithRoots option; Init synchronizes the runtime flag.</summary>
  fwithRoots := true;
  OptCreate('Rootdepthgrowth', 'linear', depthgrowthOptStr);
  depthgrowthOptStr.optionlist.Clear;
  depthgrowthOptStr.optionlist.Add('linear');
  depthgrowthOptStr.optionlist.Add('monomolecular');
  depthgrowthOptStr.optionlist.Add('expolinear');
  depthgrowthchoice := linear;

  ParCreate('ActiveDuration', '[d]', 20, ActiveDuration);

  OptCreate('Opt_RootAgeing', 'false', Opt_RootAgeing);
  Opt_RootAgeing.optionlist.Add('false');
  Opt_RootAgeing.optionlist.Add('true');

  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    VarCreate('WLD_' + ndx_str(i), '[cm.cm-3]', 0.0, false, Wld_arr[i]);
    VarCreate('WL_' + ndx_str(i), '[cm.cm-2]', 0.0, false, WL_arr[i]);
    VarCreate('effWLD_' + ndx_str(i), '[cm.cm-3]', 0.0, false, EffWld_arr[i]);
    VarCreate('effWL_' + ndx_str(i), '[cm.cm-3]', 0.0, false, effWL_arr[i]);
  end;
  for i := 0 to trunc(N_Rootcomp.v) do
    ExternVCreate('Tiefe' + ndx_str(i), '[cm]', StateField, Tiefe[i]);

  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    Wld_arr[i].v := 0.0;
  end;

end;

procedure TGrowthCurvePlantRoots.Init(var GlobMod: Tmod);
var
  i: Integer;

begin
  inherited Init(GlobMod);
  if uppercase(depthgrowthOptStr.Option) = uppercase('linear') then
    depthgrowthchoice := linear;
  if uppercase(depthgrowthOptStr.Option) = uppercase('monomolecular') then
    depthgrowthchoice := monomolecular;
  if uppercase(depthgrowthOptStr.Option) = uppercase('expolinear') then
    depthgrowthchoice := expolinear;

  N_Rootcomp.v := RootLengthDensityLayerCount;
  ResetRoots;
  for i := 0 to trunc(N_Rootcomp.v) do
    Tiefe[i].Search := withRoots;

end;

procedure TGrowthCurvePlantRoots.CalcRates;
var
  i, PreviousHead, CurrentActiveCount: Integer;
  TotalRootLength, OldLength, Thickness, zrkrit: real;
begin
  inherited;
  if not withRoots or (GlobTime.v < SowingDate.v) or
    (GlobTime.v >= HarvestDate.v) then
  begin
    ResetRoots;
    exit;
  end;

  zr.c := 0.0;
  case depthgrowthchoice of
    monomolecular: zr.v := monomo_f(zr_max.v, zr_0.v, k_z.v, TSum.v);
    linear: zr.v := min(zr_max.v, zr_0.v + TSum.v * k_z.v);
    expolinear:
      begin
        if zr.v <= 0.0 then
          zr.v := zr_0.v;
        if k_za.v <= 0.0 then
          raise EArgumentException.Create('k_za must be positive for expolinear root growth');
        zrkrit := k_z.v / k_za.v;
        if zr.v < zrkrit then
          zr.c := zr.v * max(0.0, Temp.v - TempSumRootBaseTemp.v) * k_za.v
        else
          zr.c := k_z.v * max(0.0, Temp.v - TempSumRootBaseTemp.v);
        if GlobTime.c > 0.0 then
          zr.c := min(zr.c, max(0.0, zr_max.v - zr.v) / GlobTime.c);
      end;
  end;

  if SameText(SRLcalc.Option, 'fromDMfineRoot') then
    TotalRootLength := max(0.0, DMFineRoot.v) * max(0.0, sp_RL.v) / 1E4
  else if SameText(SRLcalc.Option, 'fromGrowthcurve') then
  begin
    if (WL_0.v > 0.0) and (WL_max.v > 0.0) then
      TotalRootLength := logist_f(WL_max.v, WL_0.v, k_Wl.v, TSum.v)
    else
      TotalRootLength := 0.0;
  end
  else
    raise EArgumentException.Create('Unknown SRLcalc option: ' + SRLcalc.Option);

  PreviousHead := RootAgeHead;
  RootAgeHead := RootAgeHead mod MaxAgeCl + 1;
  n_age_cl := min(n_age_cl + 1, MaxAgeCl);
  CurrentActiveCount := min(max(trunc(ActiveDuration.v), 0), MaxAgeCl);
  SRL.v := 0.0;
  SRL_eff.v := 0.0;
  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    Thickness := Tiefe[i].v - Tiefe[i - 1].v;
    if Thickness <= 0.0 then
      raise EArgumentException.Create('Root layer depths must be strictly increasing');
    OldLength := WL_arr[i].v;
    Wld_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, Tiefe[i].v, TotalRootLength);
    WL_arr[i].v := Wld_arr[i].v * Thickness;
    UpdateRootAgeCohort(Root_Matrix[i], RootAgeHead, PreviousHead,
      CurrentActiveCount, ActiveAgeClassCount,
      max(0.0, WL_arr[i].v - OldLength), ActiveRootLength[i]);
    if SameText(Opt_RootAgeing.Option, 'true') then
      effWL_arr[i].v := ActiveRootLength[i]
    else
      effWL_arr[i].v := WL_arr[i].v;
    EffWld_arr[i].v := effWL_arr[i].v / Thickness;
    SRL.v := SRL.v + WL_arr[i].v;
    SRL_eff.v := SRL_eff.v + effWL_arr[i].v;
  end;
  ActiveAgeClassCount := CurrentActiveCount;
  CalculateRootLengthDensityMoments;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TGrowthCurvePlantRoots]);

{$ENDIF}
end;

end.
