unit USimpleRootModDM;

/// <summary>
/// Models root growth using daily fine-root dry matter increments and assumes a negative exponential root distribution with depth.
/// Root aging is simulated with a simple box-car approach.
/// </summary>
/// <remarks>
/// Reference: Kage, H., Kochler, M. & Stützel, H. Root growth of cauliflower (Brassica oleracea L. botrytis) under unstressed conditions: Measurement and modelling. Plant and Soil 223, 133–147 (2000). https://doi.org/10.1023/A:1004866823128
/// </remarks>
/// <remarks>
/// Effects of soil texture and bulk density on root growth follow the KA5 classification.
/// </remarks>
interface

uses
  UState, UMod, IniFiles, UlayeredSoil,
  classes, UModUtils, USimplePlant, UAbstractPlant,
  USoilTexture,
  URootedSoil,
  URootGrowthUtils;

type

  /// <summary>
  /// Main class for the root growth model. Represents the root growth model in the HUME system and subclasses TPlantRelatedSubMod.
  /// Provides properties and methods for root growth and root length density calculations and includes a coupled soil water model and a list of texture effects.
  /// </summary>
  TSimpleRootModDM = class(TPlantRelatedSubMod)

  private

    /// <summary>Prefix for variable names.</summary>
    fName_WL: string;

    /// <summary>Coupled soil water model.</summary>
    fRootedSoilWatermodel: TSoilWaterModelR;

    /// <summary>List of texture effects initialized at component creation.</summary>
    fTextureEffectList: TStringlist;

    /// <summary>True if root growth starts only after emergence.</summary>
    fRootGrowthAfterEmergence: boolean;

    /// <summary>Sets the variable name prefix.</summary>
    procedure Set_Name_WL(const Name_WL: string);

  protected
    /// <summary>Option controlling rooting depth increase.</summary>
    RootDepthInc: TRootingdepthIncrease;

    OldDMFineRoot: real;

    /// <summary>Calculates root length density between two depths.</summary>
    function WLD_z_t_f(z1, z2: real): real; virtual;
    /// <summary>Assigns the plant model.</summary>
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override;

  public
    /// <summary>Option defining the depth growth model.</summary>
    depthgrowthOptStr: Toption;

    /// <summary>Root length densities [cm.cm-3].</summary>
    Wld_arr: TSoilVarArray;
    /// <summary>Effective root length density [].</summary>
    EffWld_arr: TSoilVarArray;
    /// <summary>Root length per layer [cm.cm-2].</summary>
    WL_arr: TSoilVarArray;
    /// <summary>Active root length [cm.cm-2].</summary>
    effWL_arr: TSoilVarArray;

    /// <summary>Maximum number of rooted compartments.</summary>
    N_Rootcomp,

    /// <summary>Root length density in the first 15 cm.</summary>
    WLD_0_15, WLD_15_30, WLD_30_45, WLD_45_60, WLD_60_75, WLD_75_90, WLD_90_105,
      WLD_105_120,

      WLD_0_30, WLD_30_60, WLD_60_90, WLD_90_120, WLD_120_150, WLD_0_150,

    /// <summary>Effective root length density in the first 30 cm, i.e., after subtracting dead or inactive roots.</summary>
    effWLD_0_30, effWLD_30_60, effWLD_60_90, effWLD_90_120, effWLD_120_150,

      WLD_0_10, WLD_10_20, WLD_20_30, WLD_30_40, WLD_40_50, WLD_50_60,
      WLD_60_70, WLD_70_80, WLD_80_90, WLD_90_100: TVar;

    /// <summary>Root matrix storing age-classed root length per soil compartment.</summary>
    Root_Matrix: array [1 .. Max_Comp, 1 .. MaxAgeCl] of real;
    n_age_cl: integer;

    Tiefe: TSoilExtArray;

    /// <summary>Rooting depth at planting/sowing [cm].</summary>
    zr0: TPar;

    /// <summary>Relative rooting depth increase in optional exponential phase [cm.cm-1.Cd-1].</summary>
    k_za: TPar;
    /// <summary>Root growth per degree-day in the linear phase.</summary>
    k_zb: TPar;
    /// <summary>Maximum rooting depth [cm].</summary>
    Zrmax: TPar;
    /// <summary>Base temperature for root growth.</summary>
    TempSumRootBaseTemp: TPar;
    /// <summary>Specific root length [cm g⁻¹ DM].</summary>
    sp_RL,
    /// <summary>Ratio WLD0 / WLDzr.</summary>
    ratio,
    /// <summary>Duration of root activity.</summary>
    ActiveDuration: TPar;

    /// <summary>Temperature sum for root growth.</summary>
    TempSumR: TState;
    /// <summary>Rooting depth (cm).</summary>
    zr: TState;
    SRL,
    /// <summary>Total effective root length (cm cm-2).</summary>
    SRL_eff: TVar;

    /// <summary>Air temperature at 2 m.</summary>
    Temp,
    /// <summary>Dry matter of fine roots (g/m2).</summary>
    DMFineRoot,

    /// <summary>Daily DM growth rate of fine roots [g/m2/d].</summary>
    DMroot_inc: TExternV;
    /// <summary>Day of emergence.</summary>
    EmergenceDay: TExternV;

    SowingDate, HarvestDate: TPar;

    /// <summary>Option for texture effects on root growth.</summary>
    TextureEffect: Toption;
    /// <summary>If true, root growth does not start before emergence.</summary>
    RootGrowthAfterEmergence: Toption;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcRates; override;

    procedure Integrate; override;

  published

    property RootedSoilWaterModel: TSoilWaterModelR read fRootedSoilWatermodel
      write fRootedSoilWatermodel;

    /// <summary>
    /// Initializes arrays and variables for root compartments and age classes.
    /// </summary>
    procedure InitArraysAndVars;

    property Var_SRL: TVar read SRL write SRL;
    property State_zr: TState read zr write zr;

    property Par_BaseTemp: TPar read TempSumRootBaseTemp
      write TempSumRootBaseTemp;
    property Par_zr0: TPar read zr0 write zr0;
    property Par_kza: TPar read k_za write k_za;
    property Par_kzb: TPar read k_zb write k_zb;
    property Par_Ratio: TPar read ratio write ratio;
    property Par_zrmax: TPar read Zrmax write Zrmax;

    property Par_sp_WL: TPar read sp_RL write sp_RL;

    property Par_ActiveDuration: TPar read ActiveDuration write ActiveDuration;

    property Ex_Temp: TExternV read Temp write Temp;
    property Ex_EmergenceDay: TExternV read EmergenceDay write EmergenceDay;
    property Ex_DMFineRoot: TExternV read DMFineRoot write DMFineRoot;
    property Ex_DMRoot_inc: TExternV read DMroot_inc write DMroot_inc;
    property Opt_RootDepthInc: TRootingdepthIncrease read RootDepthInc
      write RootDepthInc;
    property Name_WL: string read fName_WL write Set_Name_WL;
    property var_WLD_0_15: TVar read WLD_0_15 write WLD_0_15;
    property var_WLD_15_30: TVar read WLD_15_30 write WLD_15_30;
    property var_WLD_30_45: TVar read WLD_30_45 write WLD_30_45;
    property var_WLD_45_60: TVar read WLD_45_60 write WLD_45_60;
    property var_WLD_60_75: TVar read WLD_60_75 write WLD_60_75;
    property var_WLD_75_90: TVar read WLD_75_90 write WLD_75_90;
    property var_WLD_90_105: TVar read WLD_90_105 write WLD_90_105;
    property var_WLD_105_120: TVar read WLD_105_120 write WLD_105_120;

    property var_WLD_0_30: TVar read WLD_0_30 write WLD_0_30;
    property var_WLD_30_60: TVar read WLD_30_60 write WLD_30_60;
    property var_WLD_60_90: TVar read WLD_60_90 write WLD_60_90;
    property var_WLD_90_120: TVar read WLD_90_120 write WLD_90_120;
    property var_WLD_120_150: TVar read WLD_120_150 write WLD_120_150;
    property var_WLD_0_150: TVar read WLD_0_150 write WLD_0_150;

    property var_effWLD_0_30: TVar read effWLD_0_30 write effWLD_0_30;
    property var_effWLD_30_60: TVar read effWLD_30_60 write effWLD_30_60;
    property var_effWLD_60_90: TVar read effWLD_60_90 write effWLD_60_90;
    property var_effWLD_90_120: TVar read effWLD_90_120 write effWLD_90_120;
    property var_effWLD_120_150: TVar read effWLD_120_150 write effWLD_120_150;

  end;

procedure Register;

implementation

uses
  SysUtils, math, System.TypInfo;

{ ************************************************************************* }

{
  purpose
  function for the calculation of the root length density in dependence of the depth


  parameter

  name        meaning                       unit      typee


  wld0        WLD at z=0                  [cm/cm3]     I
  a           fit parameter                 [1/cm]       I
  at 1/a is WLD=0.63*WLD0
  z           depth unter GOF              [cm]         I

  WLD_z_f     WLD in depth z               [cm/cm3]     O

  {************************************************************************* }

{ ************************************************************************* }

{
  purpose
  function to calculate the root length density between two depths


  Parameter

  Name        meaning                       unit      type


  z1          depth 1                      [cm]         I
  z2          depth 2                      [cm]         I
  t           depth                         [d]          I
  Zrmax       maximum rooting depth[cm]         I
  zr0         rooting depth at t=0 [cm]         I
  kz          fit parameter                 [1/d]        I
  SRLmax      maximum root length         [cm/cm2]     I
  (1 cm/cm2 entspr. 0.1 km/m2)
  SR0         root length at t=0          [cm/cm2]     I
  kL          fit parameter                 [1/d]        I
  ka          fit parameter                 [1/cm]       I
  at 1/(ka*zr) is WLD=0.63*WLD0

  WLD_z_t_f   WLD between z1 and z2 at t [cm/cm3]     O


  {************************************************************************* }

function monomo_f(Pmax, P0, k, t: real): real;

begin
  monomo_f := Pmax - (Pmax - P0) * exp(-k * t);
end;

function Logis_f(Wmax, W0, k, Tsum: real): real;

begin
  result := Wmax / (1 + (Wmax / W0 - 1) * exp(-Tsum * k))

end;

/// <summary>Calculates root length density.</summary>
/// <param name="wld0">Initial value of WLD.</param>
/// <param name="a">Coefficient describing exponential decrease with depth.</param>
/// <param name="z">Depth below ground surface [cm].</param>
/// <returns>The calculated value of root length density.</returns>
function WLD_z_f(wld0, a, z: real): real;
begin
  WLD_z_f := wld0 * exp(-a * z);
end;

/// <summary>Calculates average root length density between two depths.</summary>
/// <param name="z1">Lower depth boundary [cm].</param>
/// <param name="z2">Upper depth boundary [cm].</param>
/// <returns>Average root length density between z1 and z2.</returns>
function TSimpleRootModDM.WLD_z_t_f(z1, z2: real): real;

var
  wld0, a: real;

begin

  If z1 > zr.v then
  begin
    WLD_z_t_f := 0.0;
    exit;
  end;
  // If (z2>zr.v) and (z1<>zr.v) then z2 := zr.v;
  if (zr.v > 0) and (SRL.v > 0) then
  begin

    a := -ln(ratio.v) / zr.v;
    // if a > zr.v then halt;

    SRL.v := DMFineRoot.v * sp_RL.v / 1E4;

    wld0 := (SRL.v * a) / (1 - exp(-a * zr.v));
    WLD_z_t_f := wld0 * (exp(-a * z1) - exp(-a * min(z2, zr.v))) /
      (a * (z2 - z1));
  end
  else
  begin
    SRL.v := 0.0;
    WLD_z_t_f := 0.0;
  end;
end;

procedure TSimpleRootModDM.CreateAll;
var
  i: integer;
  NewTextureEffect: TTextureEffect;
  txtndx_str: string;

begin
  inherited CreateAll;

  ParCreate('BaseTempRoots', '[°C]', 0, TempSumRootBaseTemp);

  ParCreate('zr_0', '[cm]', 2, zr0, 'rooting depth at simulation start');
  ParCreate('K_za', '[cm.cm-1.°C*d-1]', 0.00394, k_za,
    'relative rooting depth increase during exponential phase (if applies)');
  ParCreate('K_zb', '[cm.°C*d-1]', 0.107, k_zb,
    'rooting depth increase during linear phase (if applies)');
  ParCreate('Ratio', '[-]', 0.01731, ratio,
    'root length density disribution factor');
  ParCreate('Zrmax', '[-]', 160, Zrmax, 'maximum rooting depth');

  ParCreate('sp_WL', '[cm.g DM-1]', 7000, sp_RL, 'specific root length');
  ParCreate('ActiveDuration', '[d]', 200, ActiveDuration,
    'active uptake period of roots, determines effective root length and density');

  VarCreate('N_Rootcomp', '[n]', 20, true, N_Rootcomp,
    'number of layers which can in maximum contain roots');

  VarCreate('WLD_0_15', '[cm.cm-3]', 0, false, WLD_0_15,
    'Root length density for 0-15 cm depth');
  VarCreate('WLD_15_30', '[cm.cm-3]', 0, false, WLD_15_30,
    'Root length density for 15-30 cm depth');
  VarCreate('WLD_30_45', '[cm.cm-3]', 0, false, WLD_30_45,
    'Root length density for 30-45 cm depth');
  VarCreate('WLD_45_60', '[cm.cm-3]', 0, false, WLD_45_60,
    'Root length density for 45-60 cm depth');
  VarCreate('WLD_60_75', '[cm.cm-3]', 0, false, WLD_60_75,
    'Root length density for 60-75 cm depth');
  VarCreate('WLD_75_90', '[cm.cm-3]', 0, false, WLD_75_90,
    'Root length density for 75-90 cm depth');
  VarCreate('WLD_90_105', '[cm.cm-3]', 0, false, WLD_90_105,
    'Root length density for 90-105 cm depth');
  VarCreate('WLD_105_120', '[cm.cm-3]', 0, false, WLD_105_120,
    'Root length density for 105-120 cm depth');
  VarCreate('WLD_0_30', '[cm.cm-3]', 0, false, WLD_0_30,
    'Root length density for 0-30 cm depth');
  VarCreate('WLD_30_60', '[cm.cm-3]', 0, false, WLD_30_60,
    'Root length density for 30-60 cm depth');
  VarCreate('WLD_60_90', '[cm.cm-3]', 0, false, WLD_60_90,
    'Root length density for 60-90 cm depth');
  VarCreate('WLD_90_120', '[cm.cm-3]', 0, false, WLD_90_120,
    'Root length density for 90-120 cm depth');
  VarCreate('WLD_120_150', '[cm.cm-3]', 0, false, WLD_120_150,
    'Root length density for 120-150 cm depth');
  VarCreate('WLD_0_150', '[cm.cm-3]', 0, false, WLD_0_150,
    'Root length density for 0-150 cm depth');
  VarCreate('effWLD_0_30', '[cm.cm-3]', 0, false, effWLD_0_30,
    'Effective root length density for 0-30 cm depth');
  VarCreate('effWLD_30_60', '[cm.cm-3]', 0, false, effWLD_30_60,
    'Effective root length density for 30-60 cm depth');
  VarCreate('effWLD_60_90', '[cm.cm-3]', 0, false, effWLD_60_90,
    'Effective root length density for 60-90 cm depth');
  VarCreate('effWLD_90_120', '[cm.cm-3]', 0, false, effWLD_90_120,
    'Effective root length density for 90-120 cm depth');
  VarCreate('effWLD_120_150', '[cm.cm-3]', 0, false, effWLD_120_150,
    'Effective root length density for 120-150 cm depth');
  VarCreate('WLD_10', '[cm.cm-3]', 0, false, WLD_0_10,
    'Root length density for 0-10 cm depth');
  VarCreate('WLD_20', '[cm.cm-3]', 0, false, WLD_10_20,
    'Root length density for 10-20 cm depth');
  VarCreate('WLD_30', '[cm.cm-3]', 0, false, WLD_20_30,
    'Root length density for 20-30 cm depth');
  VarCreate('WLD_40', '[cm.cm-3]', 0, false, WLD_30_40,
    'Root length density for 30-40 cm depth');
  VarCreate('WLD_50', '[cm.cm-3]', 0, false, WLD_40_50,
    'Root length density for 40-50 cm depth');
  VarCreate('WLD_60', '[cm.cm-3]', 0, false, WLD_50_60,
    'Root length density for 50-60 cm depth');
  VarCreate('WLD_70', '[cm.cm-3]', 0, false, WLD_60_70,
    'Root length density for 60-70 cm depth');
  VarCreate('WLD_80', '[cm.cm-3]', 0, false, WLD_70_80,
    'Root length density for 70-80 cm depth');
  VarCreate('WLD_90', '[cm.cm-3]', 0, false, WLD_80_90,
    'Root length density for 80-90 cm depth');
  VarCreate('WLD_100', '[cm.cm-3]', 0, false, WLD_90_100,
    'Root length density for 90-100 cm depth');

  StateCreate('zr', '[cm]', 0, true, zr, 'rooting depth');
  StateCreate('TempSumR', '[°C*d]', 0.0, false, TempSumR,
    'temperature sum effective for rooting');
  TempSumR.ReadFromIniFile := true; // false;
  VarCreate('SRL', '[cm.cm-2]', 0.0, false, SRL, 'Sum of root length');
  VarCreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff,
    'sum of effective root length');
  ExternVcreate('TMPM', '[°C]', stateField, Temp,
    'daily average air temperature');
  ExternVcreate('DMFineRoot', '[g.m-2]', stateField, DMFineRoot,
    'fine root mass');
  DMFineRoot.Search := true;
  ExternVcreate('DMFineRoot', '[g.m-2.d-1]', ratefield, DMroot_inc,
    'daily increase in fine root mass');
  ExternVcreate('EmergenceDay', '[-]', stateField, EmergenceDay,
    'day of emergence taken from potato growth module');

  DMroot_inc.Search := true;
  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    VarCreate(fName_WL + 'WLD_' + ndx_Str(i), '[cm.cm-3]', 0.0, false,
      Wld_arr[i]);
    VarCreate(fName_WL + 'WL_' + ndx_Str(i), '[cm.cm-2]', 0.0, false,
      WL_arr[i]);
    VarCreate(fName_WL + 'effWLD_' + ndx_Str(i), '[cm.cm-3]', 0.0, false,
      EffWld_arr[i]);
    VarCreate(fName_WL + 'effWL_' + ndx_Str(i), '[cm.cm-3]', 0.0, false,
      effWL_arr[i]);
  end;

  OptCreate('TextureEffect', 'none', TextureEffect,
    'Effect of texture on velocity of rooting depth growth relative to Weff of KA5 texture class at LD3');
  TextureEffect.OptionList.Add('none');
  TextureEffect.OptionList.Add('true');

  OptCreate('RootGrowthAfterEmergence', 'false', RootGrowthAfterEmergence,
    'If yes root growth starts not ealier than after emergence');
  RootGrowthAfterEmergence.OptionList.Add('false');
  RootGrowthAfterEmergence.OptionList.Add('true');

  for i := 0 to trunc(N_Rootcomp.v) do
    ExternVcreate('Tiefe' + ndx_Str(i), '[cm]', stateField, Tiefe[i]);

  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    Wld_arr[i].v := 0.0;
  end;

  OptCreate('Rootdepthgrowth', 'linear', depthgrowthOptStr);
  depthgrowthOptStr.OptionList.Clear;
  depthgrowthOptStr.OptionList.Add('linear');
  depthgrowthOptStr.OptionList.Add('expolinear');
  RootDepthInc := linear;

  fTextureEffectList := TStringlist.Create;
  fTextureEffectList.CaseSensitive := false;

  // create a texture effect object, create an index string and add the object to the list
  NewTextureEffect := TTextureEffect.Create('gS', 'LD1', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

  NewTextureEffect := TTextureEffect.Create('gSms', 'LD1', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSfs', 'LD1', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gS', 'LD2', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSms', 'LD2', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSfs', 'LD2', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gS', 'LD3', 7, 0.583333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSms', 'LD3', 7,
    0.583333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSfs', 'LD3', 7,
    0.583333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gS', 'LD4', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSms', 'LD4', 5,
    0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSfs', 'LD4', 5,
    0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gS', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSms', 'LD5', 4,
    0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('gSfs', 'LD5', 4,
    0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ss', 'LD1', 10, 0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mS', 'LD1', 10, 0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('fS', 'LD1', 10, 0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSgs', 'LD1', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSfs', 'LD1', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ss', 'LD2', 10, 0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mS', 'LD2', 10, 0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('fS', 'LD2', 10, 0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSgs', 'LD2', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSfs', 'LD2', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ss', 'LD3', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mS', 'LD3', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('fS', 'LD3', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSgs', 'LD3', 8,
    0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSfs', 'LD3', 8,
    0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ss', 'LD4', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mS', 'LD4', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('fS', 'LD4', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSgs', 'LD4', 5,
    0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSfs', 'LD4', 5,
    0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ss', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mS', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('fS', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSgs', 'LD5', 4,
    0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('mSfs', 'LD5', 4,
    0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl2', 'LD1', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl2', 'LD2', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl2', 'LD3', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl2', 'LD4', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl2', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su2', 'LD1', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su2', 'LD2', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su2', 'LD3', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su2', 'LD4', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su2', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su3', 'LD1', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su3', 'LD2', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su3', 'LD3', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su3', 'LD4', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su3', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su4', 'LD1', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su4', 'LD2', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su4', 'LD3', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su4', 'LD4', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Su4', 'LD5', 4, 0.333333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl3', 'LD1', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl3', 'LD2', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl3', 'LD3', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl3', 'LD4', 7, 0.583333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl3', 'LD5', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St2', 'LD1', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St2', 'LD2', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St2', 'LD3', 9, 0.75);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St2', 'LD4', 7, 0.583333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St2', 'LD5', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl4', 'LD1', 13, 1.08333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl4', 'LD2', 13, 1.08333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl4', 'LD3', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl4', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Sl4', 'LD5', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St4', 'LD1', 13, 1.08333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St4', 'LD2', 13, 1.08333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St4', 'LD3', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St4', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('St4', 'LD5', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Slu', 'LD1', 13, 1.08333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Slu', 'LD2', 13, 1.08333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Slu', 'LD3', 10,
    0.833333333333333);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Slu', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Slu', 'LD5', 5, 0.416666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls2', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls2', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls2', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls2', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls2', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls3', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls3', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls3', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls3', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls3', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls4', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls4', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls4', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls4', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ls4', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt2', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt2', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt2', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt2', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt2', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt3', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt3', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt3', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt3', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lt3', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lts', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lts', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lts', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lts', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lts', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uu', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uu', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uu', 'LD3', 11, 0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uu', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uu', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Us', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Us', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Us', 'LD3', 11, 0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Us', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Us', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu2', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu2', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu2', 'LD3', 11,
    0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu2', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu2', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tl', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tl', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tl', 'LD3', 11, 0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tl', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tl', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tt', 'LD1', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tt', 'LD2', 14, 1.16666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tt', 'LD3', 11, 0.916666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tt', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tt', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uls', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uls', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uls', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uls', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Uls', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut2', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut2', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut2', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut2', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut2', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut3', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut3', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut3', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut3', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut3', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut4', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut4', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut4', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut4', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Ut4', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lu', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lu', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lu', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lu', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Lu', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu3', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu3', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu3', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu3', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu3', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu4', 'LD1', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu4', 'LD2', 15, 1.25);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu4', 'LD3', 12, 1);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu4', 'LD4', 8, 0.666666666666667);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
  NewTextureEffect := TTextureEffect.Create('Tu4', 'LD5', 6, 0.5);
  txtndx_str := NewTextureEffect.TextureClass + '_' + NewTextureEffect.LD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

end;

/// <summary> Set the name for root length variables </summary>
/// <param name="Name_WL">The name to be set additionally to the depth increment string </param>
Procedure TSimpleRootModDM.Set_Name_WL(const Name_WL: string);

var
  i: integer;

begin
  fName_WL := Name_WL;
  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    Wld_arr[i].name := fName_WL + Wld_arr[i].name;
    WL_arr[i].name := fName_WL + WL_arr[i].name;
    EffWld_arr[i].name := fName_WL + EffWld_arr[i].name;
    effWL_arr[i].name := fName_WL + effWL_arr[i].name;

  end;
end;

/// <summary> Set the plant model for this module </summary>
/// <param name="NewPlantModel">The new plant model to be set</param>
/// <remarks> This method sets the plant model for the module and updates the search parameters for fine root and root growth variables. </remarks>
Procedure TSimpleRootModDM.SetPlantModel(NewPlantmodel: TAbstractPlant);

begin
  inherited SetPlantModel(NewPlantmodel);
  if IsPlantModelSet then
  begin
    Ex_DMFineRoot.Search := false;
    Ex_DMFineRoot.f_v := @NewPlantmodel.DMFineRoot.fv;
    Ex_DMFineRoot.Source := NewPlantmodel.name + '.' +
      NewPlantmodel.DMFineRoot.name;
    Ex_DMRoot_inc.Search := false;
    Ex_DMRoot_inc.f_v := @NewPlantmodel.DMFineRoot.c;
    Ex_DMRoot_inc.Source := NewPlantmodel.name + '.' +
      NewPlantmodel.DMFineRoot.name;
  end
  else
  begin
    Ex_DMFineRoot.Search := true;
    Ex_DMFineRoot.f_v := nil;
    Ex_DMFineRoot.Source := '';
    Ex_DMRoot_inc.Search := true;
    Ex_DMRoot_inc.f_v := nil;
    Ex_DMRoot_inc.Source := '';
  end;
end;

procedure TSimpleRootModDM.InitArraysAndVars;
var
  i, j: integer;
begin
  for i := 1 to trunc(N_Rootcomp.v) do
  begin
    Wld_arr[i].v := 0.0;
    WL_arr[i].v := 0.0;
    EffWld_arr[i].v := 0.0;
    effWL_arr[i].v := 0.0;
  end;
  for i := 1 to Max_Comp do
    for j := 1 to MaxAgeCl do
      Root_Matrix[i, j] := 0.0;
  n_age_cl := 0;
end;

/// <summary>
/// Initializes the root growth module, sets options, links plant model dates, and prepares arrays and variables for simulation.
/// </summary>
/// <param name="GlobMod">Global module reference for initialization.</param>
procedure TSimpleRootModDM.Init(var GlobMod: Tmod);
begin
  inherited Init(GlobMod);
  if uppercase(depthgrowthOptStr.Option) = uppercase('linear') then
    RootDepthInc := linear
  else if uppercase(depthgrowthOptStr.Option) = uppercase('expolinear') then
    RootDepthInc := expolinear;
  if SameText(RootGrowthAfterEmergence.Option, 'true') then
  begin
    fRootGrowthAfterEmergence := true;
    EmergenceDay.Search := true;
  end
  else
  begin
    fRootGrowthAfterEmergence := false;
    EmergenceDay.Search := false;
  end;
If PlantModel <> nil then
  begin
    SowingDate := PlantModel.SowingDate;
    HarvestDate := PlantModel.HarvestDate;
    // Initialize the number of root age classes to zero at simulation start.
    // This variable is incremented during simulation to track active root age classes.
    n_age_cl := 0;
    zr.v := zr0.v;
    OldDMFineRoot := 0.0;
    N_Rootcomp.v := 20;
    InitArraysAndVars;
  end;
end;


/// <summary>
/// Calculates the rates for root growth and updates root length densities, effective root lengths, and related variables based on current environmental and plant state.
/// Handles texture effects, rooting depth increments, root aging, and resets variables after harvest.
/// </summary>
procedure TSimpleRootModDM.CalcRates;

var
  i, j: integer;
  WL_alt, WL_neu, ActiveRL, TsumKrit, zrkrit: real;
  act_rooted_comps: integer;
  act_Texture: TTextureClass;
  act_LD: TLDClass;
  act_Texture_str, act_LD_str, TexLD_str: string;
  act_Texture_effect: TTextureEffect;
  Texture_ndx: integer;
  error: boolean;
  Texturefactor: real;

begin
  If (SowingDate = nil) or (Globtime.v >= SowingDate.v) then
  begin
    if Root_Matrix[1, 1] <= 0.0 then
    begin
      SRL.v := DMFineRoot.v * sp_RL.v / 1E4; // sum of root length in cm/cm2
      { for i := 1 to trunc(n_Rootcomp.v) do
        WLD_arr[i].v := WLD_z_t_f ( depth[i-1].v, depth[i].v);

        for j := Trunc(ActiveDuration.v) downto 1 do
        Root_matrix[1,j] := SRL.v/Trunc(ActiveDuration.v); }

    end;

    Texturefactor := 1; // default value
    if (TextureEffect.Option = 'true') and (self.RootedSoilWaterModel <> NIL)
    then
    begin
      // get number of rooted compartments
      act_rooted_comps := 0;
      for i := 1 to RootedSoilWaterModel.act_n_comp do
        if Wld_arr[i].v > 0.0 then
          act_rooted_comps := i;

      // get texture and LD (bulk density class) of rooted compartments and calculate texture factor
      act_Texture := self.RootedSoilWaterModel.Texture[act_rooted_comps];
      act_Texture_str := GetEnumName(typeInfo(TTextureClass), Ord(act_Texture));
      // string from typee

      act_LD := RootedSoilWaterModel.LD[act_rooted_comps];
      act_LD_str := GetEnumName(typeInfo(TLDClass), Ord(act_LD));

      // construct index string
      TexLD_str := act_Texture_str + '_' + act_LD_str;

      // retrieve texture effect from list
      Texture_ndx := fTextureEffectList.IndexOf(TexLD_str);
      if Texture_ndx <> -1 then
      begin
        act_Texture_effect :=
          TTextureEffect(fTextureEffectList.Objects[Texture_ndx]);
        Texturefactor := act_Texture_effect.relWeff;
      end
      else
        Texturefactor := 1;

    end;

    If (zr.v <= (Zrmax.v * Texturefactor)) then
    begin
      If RootDepthInc = expolinear then
      begin
        zrkrit := k_zb.v / k_za.v;
        // TsumKrit := ln(zrkrit / zr0.v) / k_za.v;
        if zr.v < zrkrit then
          zr.c := zr.v * (max(0, Temp.v - TempSumRootBaseTemp.v)) * k_za.v *
            Texturefactor
        else
          zr.c := k_zb.v * max(0, Temp.v - TempSumRootBaseTemp.v) *
            Texturefactor;
      end
      else If RootDepthInc = linear then
      begin
        if DMroot_inc.v > 0 then
          // zr.v := zr0.v + k_zb.v * TempSumR.v
          zr.c := k_zb.v * max(0, Temp.v - TempSumRootBaseTemp.v) *
            Texturefactor
        else
          zr.c := 0;
        // if DMroot_inc.v > 0 then
        // zr.c := k_zb.v*max(0,temp.v-TempSumRootBaseTemp.v);// else
        // zr.c :=0;
      end;
    end
    else
      zr.c := 0;

    OldDMFineRoot := DMFineRoot.v;
    if (fRootGrowthAfterEmergence = true) then
    begin
      if (EmergenceDay.v > 0) then
      begin
        TempSumR.c := max(0, (Temp.v - TempSumRootBaseTemp.v))
      end
    end
    else
    begin
      if Globtime.v >= self.SowingDate.v then
        TempSumR.c := max(0, (Temp.v - TempSumRootBaseTemp.v))
      else
        TempSumR.c := 0.0;
    end;

    // If Temp.v>TempSumRootBaseTemp.v then
    // TempSumR.C := (Temp.v-TempSumRootBaseTemp.V)
    // else TempSumr.c := 0.0;
    if n_age_cl < MaxAgeCl then
      inc(n_age_cl);
    SRL_eff.v := 0.0;
    for i := 1 to trunc(N_Rootcomp.v) do
    begin
      for j := n_age_cl downto 2 do
        Root_Matrix[i, j] := Root_Matrix[i, j - 1];
      WL_alt := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);
      Wld_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, Tiefe[i].v);
      WL_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);
      Root_Matrix[i,1] := max(0, Wl_arr[i].v-wl_alt);
      ActiveRL := 0.0;
      for j := 1 to min(trunc(ActiveDuration.v), MaxAgeCl) do
        ActiveRL := ActiveRL + Root_Matrix[i, j];
      // ActiveRL := ActiveRL+            Root_matrix[i,Trunc(ActiveDuration.v)+1]*(ActiveDuration.v -Trunc(ActiveDuration.v));
      effWL_arr[i].v := ActiveRL;
      SRL_eff.v := SRL_eff.v + ActiveRL;
      EffWld_arr[i].v := ActiveRL / (Tiefe[i].v - Tiefe[i - 1].v);
      EffWld_arr[i].v := ActiveRL / (Tiefe[i].v - Tiefe[i - 1].v);

    end;
    WLD_0_15.v := WLD_z_t_f(0, 15);
    WLD_15_30.v := WLD_z_t_f(15, 30);
    WLD_30_45.v := WLD_z_t_f(30, 45);
    WLD_45_60.v := WLD_z_t_f(45, 60);
    WLD_60_75.v := WLD_z_t_f(60, 75);
    WLD_75_90.v := WLD_z_t_f(75, 90);
    WLD_90_105.v := WLD_z_t_f(90, 105);
    WLD_105_120.v := WLD_z_t_f(105, 120);

    WLD_0_30.v := WLD_z_t_f(0, 30);
    WLD_30_60.v := WLD_z_t_f(30, 60);
    WLD_60_90.v := WLD_z_t_f(60, 90);
    WLD_90_120.v := WLD_z_t_f(90, 120);
    WLD_120_150.v := WLD_z_t_f(120, 150);
    WLD_0_150.v := WLD_z_t_f(0, 150);

    if trunc(N_Rootcomp.v) >= 3 then
      effWLD_0_30.v := (EffWld_arr[1].v + EffWld_arr[2].v + EffWld_arr[3].v) / 3
    else
      effWLD_0_30.v := 0;

    if trunc(N_Rootcomp.v) >= 6 then
      effWLD_30_60.v := (EffWld_arr[4].v + EffWld_arr[5].v + EffWld_arr[6].v) / 3
    else
      effWLD_30_60.v := 0;

    if trunc(N_Rootcomp.v) >= 9 then
      effWLD_60_90.v := (EffWld_arr[7].v + EffWld_arr[8].v + EffWld_arr[9].v) / 3
    else
      effWLD_60_90.v := 0;

    if trunc(N_Rootcomp.v) >= 12 then
      effWLD_90_120.v := (EffWld_arr[10].v + EffWld_arr[11].v + EffWld_arr[12].v) / 3
    else
      effWLD_90_120.v := 0;

    if trunc(N_Rootcomp.v) >= 15 then
      effWLD_120_150.v := (EffWld_arr[13].v + EffWld_arr[14].v + EffWld_arr[15].v) / 3
    else
      effWLD_120_150.v := 0;

  end;
  WLD_0_10.v := Wld_arr[1].v;
  WLD_10_20.v := Wld_arr[2].v;
  WLD_20_30.v := Wld_arr[3].v;
  WLD_30_40.v := Wld_arr[4].v;
  WLD_40_50.v := Wld_arr[5].v;
  WLD_50_60.v := Wld_arr[6].v;
  WLD_60_70.v := Wld_arr[7].v;
  WLD_70_80.v := Wld_arr[8].v;
  WLD_80_90.v := Wld_arr[9].v;
  WLD_90_100.v := Wld_arr[10].v;

  If ((HarvestDate <> nil) and (Globtime.v >= HarvestDate.v))
  { or (PlantModel.DoHarvest = true) } then
  begin
    zr.v := 0.0;
    for i := 1 to trunc(N_Rootcomp.v) do
    begin
      WLd_arr[i].v := 0.0;
      WL_arr[i].v := 0.0;
      EffWld_arr[i].v := 0.0;
      effWL_arr[i].v := 0.0;
    end;
    // IsActive := false;
  end;
end;


procedure TSimpleRootModDM.Integrate;

begin
  // just for debugging
  inherited;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSimpleRootModDM]);
{$ENDIF}
end;

end.
