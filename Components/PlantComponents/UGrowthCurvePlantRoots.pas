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
  classes;

type

  /// <summary> TGrowthCurvePlantRoots extends TGrowthCurvePlant to model root growth dynamics. </summary>
  TGrowthCurvePlantRoots = class(TGrowthCurvePlant)

  private

    function WLD_z_t_f(z1, z2, t, // Zrmax, Zr0, Kz,
      SRLmax, SRL0, kL, ka: real): real;
  protected

    function GetWLD(Index: Integer): THumeNumEntity; override;

    function GetSumRootLength: THumeNumEntity; override;
    function GetSumRootLength_eff: THumeNumEntity; override;

  public
    Root_Matrix: array [1 .. Max_Comp, 1 .. MaxAgeCl] of real;
    n_age_cl: Integer;

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

    /// <summary>Option to enable root growth.</summary>
    OptWithRoots: TOption;

    /// <summary>Option for the root depth growth model.</summary>
    depthgrowthOptStr: TOption;

    /// <summary>Option for root ageing.</summary>
    Opt_RootAgeing: TOption;

    depthgrowthchoice: TRootingdepthIncrease;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcRates; override;

  published

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

function TGrowthCurvePlantRoots.WLD_z_t_f(z1, z2, t, // Zrmax, Zr0, Kz,
  SRLmax, SRL0, kL, ka: real): real;

var
  SRL, WLD0, a: real;

begin

  if z1 > zr.v then
  begin
    WLD_z_t_f := 0.0;
    exit;
  end;
  if (z2 > zr.v) and (z1 <> zr.v) then
    z2 := zr.v;
  // a   := 1/(ka*zr.v);
  a := -ln(ka) / zr.v;
  // if a > zr.v then begin
  // showmessage('GrowthCurvePlantRoots, Objectname:'+self.name+ 'Par a>Zr.v');
  // halt;
  // end;
  SRL := logist_f(SRLmax, SRL0, kL, t);
  WLD0 := (SRL * a) / (1 - exp(-a * zr.v));
  WLD_z_t_f := WLD0 * (exp(-a * z1) - exp(-a * z2)) / (a * (z2 - z1));

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

  OptCreate('OptWithRoots', 'true', OptWithRoots);
  OptWithRoots.OptionList.Add('true');
  OptWithRoots.OptionList.Add('false');


  fwithRoots := true;
  OptWithRoots.Option := 'true';
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

  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    Wld_arr[i].v := 0.0;
    WL_arr[i].v := 0.0;
  end;
  N_Rootcomp.v := 20;
  for i := 0 to trunc(N_Rootcomp.v) do
    Tiefe[i].Search := withRoots;

end;

procedure TGrowthCurvePlantRoots.CalcRates;

var
  i, j: Integer;
  wl_alt, ActiveRL, zrkrit: real;

begin
  inherited;
  if (GlobTime.v >= SowingDate.v) and (GlobTime.v < HarvestDate.v) then
  begin
    SRL.v := 0.0;
    SRL_eff.v := 0.0;
    if depthgrowthchoice = monomolecular then
    begin
      zr.v := monomo_f(zr_max.v, zr_0.v, k_z.v, TSum.v);
      zr.c := 0.0;
    end;
    if depthgrowthchoice = linear then
    begin
      zr.v := min(zr_max.v, zr_0.v + TSum.v * k_z.v);
      zr.c := 0.0;
    end;
    if depthgrowthchoice = expolinear then
      zr.v := min(zr_max.v, zr_0.v + TSum.v * k_z.v);
    If depthgrowthchoice = expolinear then
    begin
      zrkrit := k_z.v / k_za.v;
      // TsumKrit := ln(zrkrit / zr0.v) / k_za.v;
      if zr.v < zrkrit then
        zr.c := zr.v * (max(0, Temp.v - TempSumRootBaseTemp.v)) * k_za.v
      else
        zr.c := k_z.v * max(0, Temp.v - TempSumRootBaseTemp.v);
    end;

    if withRoots then
      for i := 1 to trunc(N_Rootcomp.v) do
      begin

        if (Opt_RootAgeing.Option = 'true') then
        begin

          for j := n_age_cl downto 2 do
            Root_Matrix[i, j] := Root_Matrix[i, j - 1];
          wl_alt := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);

          Wld_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, Tiefe[i].v, TSum.v,
            // Zr_max.v, Zr_0.v, K_z.v,
            WL_max.v, WL_0.v, k_Wl.v, K_a.v);

          WL_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);

          Root_Matrix[i, 1] := max(0, WL_arr[i].v - wl_alt);
          ActiveRL := 0.0;
          for j := 1 to trunc(ActiveDuration.v) do
            ActiveRL := ActiveRL + Root_Matrix[i, j];

          effWL_arr[i].v := ActiveRL;
          SRL_eff.v := SRL_eff.v + ActiveRL;
          EffWld_arr[i].v := ActiveRL / (Tiefe[i].v - Tiefe[i - 1].v);

          SRL.v := SRL.v + WL_arr[i].v;
        end
        else
        begin

          Wld_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, Tiefe[i].v, TSum.v,
            // Zr_max.v, Zr_0.v, K_z.v,
            WL_max.v, WL_0.v, k_Wl.v, K_a.v);
          WL_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);
          SRL.v := SRL.v + WL_arr[i].v;
          SRL_eff.v := SRL_eff.v + WL_arr[i].v;
          EffWld_arr[i].v := Wld_arr[i].v;

        end;

      end;
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TGrowthCurvePlantRoots]);

{$ENDIF}
end;

end.
