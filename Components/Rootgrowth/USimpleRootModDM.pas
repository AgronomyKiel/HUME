unit USimpleRootModDM;


{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

/// a unit to model root growth in a simple way based on daily growth rates of fine root DM
/// a negative exponential root disribution with depth is assumed
/// root ageing is implemented by a simple box car approach
/// see also:
/// Kage, H., Kochler, M. & Stützel, H. 
/// Root growth of cauliflower (Brassica oleracea L. botrytis) ander unstressed conditions: Measurement and modelling. 
/// Plant and Soil 223, 133–147 (2000). https://doi.org/10.1023/A:1004866823128 


/// effects of soil texture and soil bulk density class on root growth are implemented according to the KA5 classification
interface

uses
  UState,
  UMod,
  IniFiles,
  UlayeredSoil,
  classes,
//  UModUtils,
//  USimplePlant,
  UAbstractPlant,
  USoilTexture,
  URootedSoil;

const
// maximum number of days in age classes
  MaxAgeCl = 2500;

type

// an object to store the effects of soil texture on root growth
/// <summary>
/// Represents a texture effect for root growth.
/// </summary>
TTextureEffect = class(TObject)
private
  fTextureClass: string; // the texture class according to KA5
  fLD: string; // a string with the layer density class LD1 .. LD5 according to KA5
  fWeff: real; // the effective rooting depth in dm
  frelWeff: real; // the relative effective rooting depth, relative to Ut3 at LD3
protected
  /// <summary>
  /// Creates a new instance of the TTextureEffect class.
  /// </summary>
  /// <param name="TextureClass">The texture class according to KA5.</param>
  /// <param name="LD">A string with the layer density class LD1 .. LD5 according to KA5.</param>
  /// <param name="Weff">The effective rooting depth in dm.</param>
  /// <param name="relWeff">The relative effective rooting depth, relative to Ut3 at LD3.</param>
  constructor Create(TextureClass: string; LD: string; Weff: real; relWeff: real);
end;


/// Enumeration of options for the increase of rooting depth.
/// The options include linear and expolinear.
TRootingdepthIncrease = (linear, expolinear);



///////////////////////////////////////////////////////////////////////////////////

{/**
 * @class TSimpleRootModDM
 * @brief The main class for the root growth model.
 *
 * This class represents the root growth model in the HUME system. It is a subclass of TPlantRelatedSubMod.
 * The class contains various properties and methods related to root growth and root length density calculations.
 * It also includes a coupled soil water model and a list of texture effects.
 */
...}
/// the main class for the root growth model
TSimpleRootModDM = class(TPlantRelatedSubMod)

private

fName_WL : string; /// the name prefix for the variables

// private field for the coupled soil water model
  fRootedSoilWatermodel : TSoilWaterModelR;


fTextureEffectList : TStringlist; /// a list of texture effects filled at creation of the component
fRootGrowthAfterEmergence : boolean; ///

/// set the prefix name
Procedure set_Name_WL(const Name_WL: string);


protected
  RootDepthInc  : TRootingdepthIncrease;  /// field for the option of rooting depth increase 


  OldDMFineRoot : real;

  function WLD_z_t_f ( z1, z2: real): real; virtual; /// function to calculate the root length density between two depths
  procedure SetPlantModel(NewPlantmodel: TAbstractPlant); override; /// procedure to set the plant model


public
  depthgrowthOptStr : Toption; /// Toption object for the depth growth model

  Wld_arr : TSoilVarArray;    /// root length densities [cm.cm-3]
  EffWld_arr : TsoilVarArray; /// effective root length density []
  WL_arr  : TSoilVarArray;    /// root legnth per layer [cm.cm-2]
  effWL_arr : TSoilVarArray;  /// active root length [cm.cm-2]

  N_Rootcomp,               ///  maximum number of rooted compartiments

  WLD_0_15, /// root length density in the first 15 cm
  WLD_15_30,
  WLD_30_45,
  WLD_45_60,
  WLD_60_75,
  WLD_75_90,
  WLD_90_105,
  WLD_105_120,

  WLD_0_30,
  WLD_30_60,
  WLD_60_90,
  WLD_90_120,
  WLD_120_150,
  WLD_0_150,

  effWLD_0_30, /// effective root length density in the first 30 cm, i.e. after substractin dead/inactive roots
  effWLD_30_60,
  effWLD_60_90,
  effWLD_90_120,
  effWLD_120_150,

  WLD_0_10,
  WLD_10_20,
  WLD_20_30,
  WLD_30_40,
  WLD_40_50,
  WLD_50_60,
  WLD_60_70,
  WLD_70_80,
  WLD_80_90,
  WLD_90_100 : TVar;

  Root_Matrix : array[1..Max_Comp, 1..MaxAgeCl] of real;
  n_age_cl    : integer;

  Tiefe : TSoilExtArray;

  zr0    : TPar;            ///  root depth at plantig / sowing cm]

  k_za   : TPar;            /// relative root depth increase in optional exponential phase [cm.cm-1.Cd-1]
  k_zb   : TPar;            /// Wurzelwachstum je Grad-Tag im linearen Teil
  Zrmax   : TPar;            /// maximum  rooting depth [cm]
  TempSumRootBaseTemp : TPar;  /// Base temperature for root growth
  sp_RL                     /// specific root length [cm/g DM]
,
  ratio                     /// ratio WLD0 / WLDzr
,
  ActiveDuration            /// time of root activity
 : Tpar;

  TempSumR : TState;         /// Temperatur sum for root growth
  zr : TState;               /// rooting depth (cm)
  SRL,
  SRL_eff : TVar;            /// Total "effective" root length (cm.cm-2)

  Temp,               /// air temperature in 2m
  DMFineRoot,         /// Dry matter of fine roots (g/m2)

  DMroot_inc : TExternV;    /// Daily DM growth rate of fine roots [g/m2/d]
  EmergenceDay : TExternV;   ///

  SowingDate,
  HarvestDate : TPar;

  TextureEffect: TOption; /// option for texture effect on root growth
  RootGrowthAfterEmergence: TOption; /// If true root growth starts not earlier than after emergence




procedure CreateAll; override;

procedure Init(var GlobMod: Tmod); override;

procedure CalcRates; override;

procedure Integrate; override;

published

property RootedSoilWaterModel : TSoilWaterModelR read fRootedSoilWatermodel write fRootedSoilWaterModel;

property Var_SRL : TVar read SRL write SRL;
property State_zr : TState read zr write zr;

property  Par_BaseTemp : TPar read TempSumRootBaseTemp write TempSumRootBaseTemp;
property  Par_zr0   : TPar read zr0  write zr0;
property  Par_kza   : TPar read k_za  write k_za;
property  Par_kzb   : TPar read k_zb  write k_zb;
property  Par_Ratio : TPar read Ratio write Ratio;
property  Par_zrmax   : TPar read zrmax  write zrmax;

property Par_sp_WL   : TPar read sp_RL write sp_RL;

property Par_ActiveDuration : Tpar read ActiveDuration write ActiveDuration;

property Ex_Temp : TExternV read Temp write Temp;
property Ex_EmergenceDay : TExternV read EmergenceDay write EmergenceDay;
property Ex_DMFineRoot : TExternV read DMFineRoot write DMFineRoot;
property Ex_DMRoot_inc : TExternV read DMRoot_inc write DMRoot_inc;
property Opt_RootDepthInc : Trootingdepthincrease read RootDepthinc write Rootdepthinc;
property Name_Wl : string read fName_WL write Set_Name_WL;
property var_WLD_0_15 : TVar read WLD_0_15 write WLD_0_15;
property var_WLD_15_30 : TVar read WLD_15_30 write WLD_15_30;
property var_WLD_30_45 : TVar read WLD_30_45 write WLD_30_45 ;
property var_WLD_45_60 : TVar read WLD_45_60 write WLD_45_60;
property var_WLD_60_75 : TVar read WLD_60_75 write WLD_60_75;
property var_WLD_75_90 : TVar read WLD_75_90 write WLD_75_90;
property var_WLD_90_105 : TVar read WLD_90_105 write WLD_90_105;
property var_WLD_105_120 : TVar read WLD_105_120 write WLD_105_120;

property var_WLD_0_30 : TVar read WLD_0_30 write WLD_0_30;
property var_WLD_30_60 : TVar read WLD_30_60 write WLD_30_60;
property var_WLD_60_90 : TVar read WLD_60_90 write WLD_60_90;
property var_WLD_90_120 : TVar read WLD_90_120 write WLD_90_120;
property var_WLD_120_150 : TVar read WLD_120_150 write WLD_120_150;
property var_WLD_0_150 : TVar read WLD_0_150 write WLD_0_150;

property var_effWLD_0_30 : TVar read effWLD_0_30 write effWLD_0_30;
property var_effWLD_30_60 : TVar read effWLD_30_60 write effWLD_30_60;
property var_effWLD_60_90 : TVar read effWLD_60_90 write effWLD_60_90;
property var_effWLD_90_120 : TVar read effWLD_90_120 write effWLD_90_120;
property var_effWLD_120_150 : TVar read effWLD_120_150 write effWLD_120_150;

end;

procedure Register;

implementation

uses
  SysUtils, math, System.TypInfo;


/// <summary>
/// Constructor for TTextureeffect class.
/// </summary>
/// <param name="TextureClass">The texture class.</param>
/// <param name="LD">The LD value.</param>
/// <param name="Weff">The Weff value.</param>
/// <param name="relWeff">The relative Weff value.</param>
constructor TTextureeffect.create(TextureClass: string; LD: string; Weff: real; relWeff: real);
begin
  fTextureClass := TextureClass;
  fLD := LD;
  fWeff := Weff;
  frelWeff := relWeff;
end;


{*************************************************************************}

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

{*************************************************************************}


{*************************************************************************}


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


{*************************************************************************}


function monomo_f (Pmax, P0, k, t : real): real;

begin
  monomo_f := Pmax-(Pmax-P0)*exp(-k*t);
end;

function Logis_f(Wmax, W0, k, Tsum:real):real;

begin
  result :=   WMax/(1+(WMAx/W0-1)*EXP(-TSum*k))

end;

/// Calculates the value of root length density
///
/// \param wld0 The initial value of WLD.
/// \param a The coefficient a.
/// \param z The value of z.
/// \return The calculated value of root length density.
function WLD_z_f(wld0, a, z: real): real;
begin
  WLD_z_f := wld0 * exp(-a * z);
end;



/// <summary>
/// Calculates the value of WLD_z_t_f.
/// </summary>
/// <param name="z1">The first input value.</param>
/// <param name="z2">The second input value.</param>
/// <returns>The calculated value of WLD_z_t_f.</returns>
function TSimpleRootModDM.WLD_z_t_f(z1, z2  : real): real;

var
  WLD0,
  a  : real;

begin

  If z1>zr.v then begin
    WLD_z_t_f := 0.0;
    exit;
  end;
//  If (z2>zr.v) and (z1<>zr.v) then z2 := zr.v;
  if (zr.v > 0) and (SRL.v > 0) then begin

   a   := -ln(Ratio.v)/zr.v;
  // if a > zr.v then halt;

    SRL.v := DMFineRoot.v*sp_RL.v/1e4;

    WLD0:= (SRL.v*a)/(1-exp(-a*zr.v));
    wld_z_t_f := wld0*(exp(-a*z1)-exp(-a*min(z2,zr.v)))/(a*(z2-z1));
   end else begin
     SRL.v := 0.0;
     wld_z_t_f := 0.0;
   end;
end;


procedure TSimpleRootModDM.CreateAll;
var
  i : integer;
  NewTextureEffect : TTextureEffect;
  txtndx_str: string;

begin
  inherited CreateAll;

  ParCreate('BaseTempRoots', '[°C]',0,TempSumRootBaseTemp);

  ParCreate('zr_0',  '[cm]', 2,    zr0, 'rooting depth at simulation start');
  ParCreate('K_za',  '[cm.cm-1.°C*d-1]', 0.00394, k_za, 'relative rooting depth increase during exponential phase (if applies)');
  ParCreate('K_zb',  '[cm.°C*d-1]', 0.107,   k_zb, 'rooting depth increase during linear phase (if applies)');
  ParCreate('Ratio', '[-]', 0.01731, Ratio, 'root length density disribution factor');
  ParCreate('Zrmax', '[-]', 160, Zrmax, 'maximum rooting depth');

  ParCreate('sp_WL', '[cm.g DM-1]',    7000,   sp_RL, 'specific root length');
  ParCreate('ActiveDuration', '[d]',    200,   ActiveDuration, 'active uptake period of roots, determines effective root length and density');

  VarCreate('N_Rootcomp', '[n]',  20, true, N_Rootcomp, 'number of layers which can in maximum contain roots');

  VarCreate('WLD_0_15', '[cm.cm-3]',  0, false, WLD_0_15, 'Root length density for 0-15 cm depth');
  VarCreate('WLD_15_30', '[cm.cm-3]',  0, false, WLD_15_30);
  VarCreate('WLD_30_45', '[cm.cm-3]',  0, false, WLD_30_45);
  VarCreate('WLD_45_60', '[cm.cm-3]',  0, false, WLD_45_60);
  VarCreate('WLD_60_75', '[cm.cm-3]',  0, false, WLD_60_75);
  VarCreate('WLD_75_90', '[cm.cm-3]',  0, false, WLD_75_90);
  VarCreate('WLD_90_105', '[cm.cm-3]',  0, false, WLD_90_105);
  VarCreate('WLD_105_120', '[cm.cm-3]',  0, false, WLD_105_120);
  VarCreate('WLD_0_30', '[cm.cm-3]',  0, false, WLD_0_30);
  VarCreate('WLD_30_60', '[cm.cm-3]',  0, false, WLD_30_60);
  VarCreate('WLD_60_90', '[cm.cm-3]',  0, false, WLD_60_90);
  VarCreate('WLD_90_120', '[cm.cm-3]',  0, false, WLD_90_120);
  VarCreate('WLD_120_150', '[cm.cm-3]',  0, false, WLD_120_150);
  VarCreate('WLD_0_150', '[cm.cm-3]',  0, false, WLD_0_150);
  VarCreate('effWLD_0_30', '[cm.cm-3]',  0, false, effWLD_0_30);
  VarCreate('effWLD_30_60', '[cm.cm-3]',  0, false, effWLD_30_60);
  VarCreate('effWLD_60_90', '[cm.cm-3]',  0, false, effWLD_60_90);
  VarCreate('effWLD_90_120', '[cm.cm-3]',  0, false, effWLD_90_120);
  VarCreate('effWLD_120_150', '[cm.cm-3]',  0, false, effWLD_120_150);
  VarCreate('WLD_10', '[cm.cm-3]',  0, false, WLD_0_10);
  VarCreate('WLD_20', '[cm.cm-3]',  0, false, WLD_10_20);
  VarCreate('WLD_30', '[cm.cm-3]',  0, false, WLD_20_30);
  VarCreate('WLD_40', '[cm.cm-3]',  0, false, WLD_30_40);
  VarCreate('WLD_50', '[cm.cm-3]',  0, false, WLD_40_50);
  VarCreate('WLD_60', '[cm.cm-3]',  0, false, WLD_50_60);
  VarCreate('WLD_70', '[cm.cm-3]',  0, false, WLD_60_70);
  VarCreate('WLD_80', '[cm.cm-3]',  0, false, WLD_70_80);
  VarCreate('WLD_90', '[cm.cm-3]',  0, false, WLD_80_90);
  VarCreate('WLD_100', '[cm.cm-3]',  0, false, WLD_90_100);

  StateCreate('zr', '[cm]',  0, true, zr, 'rooting depth');
  StateCreate('TempSumR', '[°C*d]', 0.0, false, TempSumR, 'temperature sum effective for rooting');
  TempSumR.ReadFromIniFile := true; // false;
  Varcreate('SRL', '[cm.cm-2]', 0.0, false, SRL, 'Sum of root length');
  Varcreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff, 'sum of effective root length');
  ExternVcreate('TMPM', '[°C]', stateField, Temp, 'daily average air temperature');
  ExternVcreate('DMFineRoot', '[g.m-2]', stateField, DMFineRoot, 'fine root mass');
  DMFineRoot.Search := true;
  ExternVCreate('DMFineRoot', '[g.m-2.d-1]',ratefield, DMroot_inc, 'daily increase in fine root mass');
  ExternVcreate('EmergenceDay', '[-]', stateField, EmergenceDay, 'day of emergence taken from potato growth module');


  DMroot_inc.Search := true;
  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate(fName_WL+'WLD_'+ndx_Str(i), '[cm.cm-3]', 0.0, false,WLD_arr[i]);
    VarCreate(fName_WL+'WL_'+ndx_Str(i), '[cm.cm-2]', 0.0, false,WL_arr[i]);
    VarCreate(fName_WL+'effWLD_'+ndx_Str(i), '[cm.cm-3]', 0.0, false, effWLD_arr[i]);
    VarCreate(fName_WL+'effWL_'+ndx_Str(i), '[cm.cm-3]', 0.0, false, effWL_arr[i]);
  end;

  OptCreate('TextureEffect', 'none', TextureEffect, 'Effect of texture on velocity of rooting depth growth relative to Weff of KA5 texture class at LD3');
  TextureEffect.OptionList.Add('none');
  TextureEffect.OptionList.Add('true');

  OptCreate('RootGrowthAfterEmergence', 'false', RootGrowthAfterEmergence,
            'If yes root growth starts not ealier than after emergence');
  RootGrowthAfterEmergence.OptionList.Add('false');
  RootGrowthAfterEmergence.OptionList.Add('true');



  for i := 0 to trunc(n_Rootcomp.v) do
      ExternVCreate('Tiefe'+ndx_Str(i),'[cm]', StateField, Tiefe[i]);

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
  end;

  OptCreate('Rootdepthgrowth', 'linear', depthgrowthoptstr);
  depthgrowthoptstr.optionlist.Clear;
  depthgrowthoptstr.optionlist.Add('linear');
  depthgrowthoptstr.OptionList.Add('expolinear');
  RootDepthInc := linear;

  fTextureEffectList := TStringlist.Create;
  fTextureEffectList.CaseSensitive := false;

/// create a texture effect object, create an index string and add the object to the lis
NewTextureEffect := TTextureEffect.create('gS', 'LD1' , 9, 0.75);
  txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSms', 'LD1' , 9, 0.75);
  txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
  fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);
NewTextureEffect := TTextureEffect.create('gSfs', 'LD1' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gS', 'LD2' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSms', 'LD2' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSfs', 'LD2' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gS', 'LD3' , 7, 0.583333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSms', 'LD3' , 7, 0.583333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSfs', 'LD3' , 7, 0.583333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gS', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSms', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSfs', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gS', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSms', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('gSfs', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ss', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mS', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('fS', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSgs', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSfs', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ss', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mS', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('fS', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSgs', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSfs', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ss', 'LD3' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mS', 'LD3' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('fS', 'LD3' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSgs', 'LD3' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSfs', 'LD3' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ss', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mS', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('fS', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSgs', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSfs', 'LD4' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ss', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mS', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('fS', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSgs', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('mSfs', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl2', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl2', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl2', 'LD3' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl2', 'LD4' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl2', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su2', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su2', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su2', 'LD3' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su2', 'LD4' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su2', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su3', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su3', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su3', 'LD3' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su3', 'LD4' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su3', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su4', 'LD1' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su4', 'LD2' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su4', 'LD3' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su4', 'LD4' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Su4', 'LD5' , 4, 0.333333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl3', 'LD1' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl3', 'LD2' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl3', 'LD3' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl3', 'LD4' , 7, 0.583333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl3', 'LD5' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St2', 'LD1' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St2', 'LD2' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St2', 'LD3' , 9, 0.75);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St2', 'LD4' , 7, 0.583333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St2', 'LD5' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl4', 'LD1' , 13, 1.08333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl4', 'LD2' , 13, 1.08333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl4', 'LD3' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl4', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Sl4', 'LD5' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St4', 'LD1' , 13, 1.08333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St4', 'LD2' , 13, 1.08333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St4', 'LD3' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St4', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('St4', 'LD5' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Slu', 'LD1' , 13, 1.08333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Slu', 'LD2' , 13, 1.08333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Slu', 'LD3' , 10, 0.833333333333333);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Slu', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Slu', 'LD5' , 5, 0.416666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls2', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls2', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls2', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls2', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls2', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls3', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls3', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls3', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls3', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls3', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls4', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls4', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls4', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls4', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ls4', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt2', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt2', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt2', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt2', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt2', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt3', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt3', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt3', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt3', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lt3', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lts', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lts', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lts', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lts', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lts', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uu', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uu', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uu', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uu', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uu', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Us', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Us', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Us', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Us', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Us', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu2', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu2', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu2', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu2', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu2', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tl', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tl', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tl', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tl', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tl', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tt', 'LD1' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tt', 'LD2' , 14, 1.16666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tt', 'LD3' , 11, 0.916666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tt', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tt', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uls', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uls', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uls', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uls', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Uls', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut2', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut2', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut2', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut2', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut2', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut3', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut3', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut3', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut3', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut3', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut4', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut4', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut4', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut4', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Ut4', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lu', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lu', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lu', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lu', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Lu', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu3', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu3', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu3', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu3', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu3', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu4', 'LD1' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu4', 'LD2' , 15, 1.25);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu4', 'LD3' , 12, 1);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu4', 'LD4' , 8, 0.666666666666667);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

NewTextureEffect := TTextureEffect.create('Tu4', 'LD5' , 6, 0.5);
	txtndx_str := NewTextureEffect.fTextureClass + '_' +NewTextureEffect.fLD;
	fTextureEffectList.AddObject(txtndx_str, NewTextureEffect);

end;


Procedure TSimpleRootModDM.set_Name_WL(const Name_WL: string);

var
  i : integer;

begin
  fName_WL := Name_WL;
  for I := 1 to trunc(n_Rootcomp.v) do begin
     WLD_arr[i].name := fName_WL+WLD_arr[i].name;
     WL_arr[i].name := fName_WL+WL_arr[i].name;
     effWLD_arr[i].name := fName_WL+effWLD_arr[i].name;
     effWL_arr[i].name := fName_WL+effWL_arr[i].name;

  end;
end;


Procedure TSimpleRootModDM.SetPlantModel(NewPlantmodel: TAbstractPlant);

begin
  inherited SetPlantModel(NewPlantModel);
  if IsPlantModelSet then begin
    Ex_DMfineroot.Search := false;
    Ex_DMfineroot.f_v    := @NewPlantmodel.DMFineRoot.fv;
    Ex_DMfineroot.Source := NewPlantmodel.Name+'.'+NewPlantmodel.DMFineRoot.Name;
    Ex_DMroot_inc.Search := false;
    Ex_DMroot_inc.f_v    := @NewPlantmodel.DMfineroot.c;
    Ex_DMroot_inc.Source := NewPlantmodel.Name+'.'+ NewPlantmodel.DMFineRoot.Name;
  end else begin
    Ex_DMfineroot.Search := true;
    Ex_DMfineroot.f_v    := nil;
    Ex_DMfineroot.Source := '';
    Ex_DMroot_inc.Search := true;
    Ex_DMroot_inc.f_v    := nil;
    Ex_DMroot_inc.Source := '';
  end;
end;


procedure TSimpleRootModDM.Init(Var GlobMod: TMod);
var
  i, j : integer;

begin
  inherited Init(GlobMod);
  if uppercase(depthgrowthoptstr.Option) = uppercase('linear') then
    RootDepthInc := linear;
  if uppercase(depthgrowthoptstr.Option) = uppercase('expolinear') then
    RootDepthInc := expolinear;

  if uppercase(RootGrowthAfterEmergence.Option) = uppercase('true') then
    begin
      fRootGrowthAfterEmergence := true;
      EmergenceDay.Search := true;
    end else begin
      fRootGrowthAfterEmergence := false;
      EmergenceDay.Search := false;
    end;


  If PlantModel <> nil then begin
    SowingDate := PlantModel.SowingDate;
    HarvestDate := PlantModel.HarvestDate;
  end;
  zr.v := zr0.v;
  OldDMFineRoot := 0.0;
//  TempsumR.V := 0.0;
  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;

  for i := 1 to max_Comp do
   for j := 1 to MaxAgeCl do
     Root_matrix[i,j] := 0.0;
   n_age_cl := 0;

end;

procedure TSimpleRootModDM.CalcRates;

var
  i, j : integer;
  WL_alt,
  WL_neu,
  ActiveRL,
  TsumKrit,
  zrkrit  : real;
  act_rooted_comps : integer;
  act_Texture : TTextureClass;
  act_LD : TLDClass;
  act_Texture_str, act_LD_str, TexLD_str : string;
  act_Texture_effect : TTextureEffect;
  Texture_ndx : integer;
  error : boolean;
  Texturefactor : real;


begin


  If (sowingdate = nil) or (Globtime.v >= SowingDate.v) then begin
    if root_matrix[1,1] <= 0.0 then begin
      SRL.v := DMFineRoot.v*sp_RL.v/1e4; /// sum of root length in cm/cm2
  {    for i := 1 to trunc(n_Rootcomp.v) do
        WLD_arr[i].v := WLD_z_t_f ( depth[i-1].v, depth[i].v);

      for j := Trunc(ActiveDuration.v) downto 1 do
        Root_matrix[1,j] := SRL.v/Trunc(ActiveDuration.v);  }

    end;

  Texturefactor := 1; // default value
  if (TextureEffect.Option = 'true') and (self.RootedSoilWaterModel <> NIL) then begin
    /// get number of rooted compartments
    act_rooted_comps := 0;
    for i  := 1 to RootedSoilWaterModel.act_n_comp do
      if Wld_arr[i].v > 0.0 then
        act_rooted_comps := i;
    
    /// get texture and LD of rooted compartments and calculate texture factor
    act_texture := self.RootedSoilWaterModel.Texture[act_rooted_comps];
    act_texture_str := GetEnumName(typeInfo(TTextureClass), Ord(act_texture)); // string from typee

    act_LD := RootedSoilWaterModel.LD[act_rooted_comps];
    act_LD_str :=    GetEnumName(typeInfo(TLDClass), Ord(act_LD));
    
    /// construct index string
    TexLD_str := act_texture_str +'_' + act_LD_str;
    
    /// retrieve texture effect from lis
    Texture_ndx := fTextureEffectList.IndexOf(TexLD_str);
    if  Texture_ndx <> -1 then begin
      act_Texture_effect := TTextureEffect(fTextureEffectList.Objects[Texture_ndx]);
      Texturefactor := act_Texture_effect.frelWeff;
    end else Texturefactor := 1;       // default


  end;

  If (Zr.v <= (Zrmax.v)) then   // *Texturefactor
  begin
    If RootDepthInc = expolinear then
    begin
      zrkrit := k_zb.v / k_za.v;
//      TsumKrit := ln(zrkrit / zr0.v) / k_za.v;
      if zr.v < zrkrit then
        zr.c := zr.v * (max(0, Temp.v - TempSumRootBaseTemp.v)) * k_za.v*Texturefactor
      else
        zr.c := k_zb.v * max(0, Temp.v - TempSumRootBaseTemp.v) * Texturefactor;
    end
    else If RootDepthInc = linear then
    begin
      if DMroot_inc.v > 0 then
        //zr.v := zr0.v + k_zb.v * TempSumR.v
        zr.c := k_zb.v * max(0, Temp.v - TempSumRootBaseTemp.v)*Texturefactor
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
      if (Temp.v>TempSumRootBaseTemp.v) and (EmergenceDay.v > 0) then
        TempSumR.C := (Temp.v-TempSumRootBaseTemp.V) else
      if Temp.v>TempSumRootBaseTemp.v then
        TempSumR.C := (Temp.v-TempSumRootBaseTemp.V)
    else TempSumr.c := 0.0;
    inc(N_age_cl);
    SRL_eff.v  := 0.0;
    for i := 1 to trunc(n_Rootcomp.v) do begin
      for j := n_age_cl downto 2 do
        Root_matrix[i,j] := Root_Matrix[i,j-1];
      WL_alt := WLD_arr[i].v * (Tiefe[i].v-Tiefe[i-1].v);
      WLD_arr[i].v := WLD_z_t_f ( Tiefe[i-1].v, Tiefe[i].v);
      Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v-Tiefe[i-1].v);
      Root_Matrix[i,1] := max(0, Wl_arr[i].v-wl_alt);
      ActiveRL := 0.0;
      for j := 1 to Trunc(ActiveDuration.v) do
        ActiveRL := ActiveRl+Root_matrix[i,j];
  //    ActiveRL := ActiveRL+            Root_matrix[i,Trunc(ActiveDuration.v)+1]*(ActiveDuration.v -Trunc(ActiveDuration.v));
      effWL_arr[i].v := ActiveRL;
      SRL_eff.v      := SRL_eff.v+ActiveRL;
      EffWLD_Arr[i].v := ActiveRL/(Tiefe[i].v-Tiefe[i-1].v);

    end;
    WLD_0_15.v := WLD_z_t_f ( 0, 15);
    WLD_15_30.v := WLD_z_t_f ( 15, 30);
    WLD_30_45.v := WLD_z_t_f ( 30, 45);
    WLD_45_60.v := WLD_z_t_f ( 45, 60);
    WLD_60_75.v := WLD_z_t_f ( 60, 75);
    WLD_75_90.v := WLD_z_t_f ( 75, 90);
    WLD_90_105.v := WLD_z_t_f ( 90, 105);
    WLD_105_120.v := WLD_z_t_f ( 105, 120);

    WLD_0_30.v := WLD_z_t_f ( 0, 30);
    WLD_30_60.v := WLD_z_t_f ( 30, 60);
    WLD_60_90.v := WLD_z_t_f ( 60, 90);
    WLD_90_120.v := WLD_z_t_f ( 90, 120);
    WLD_120_150.v := WLD_z_t_f ( 120, 150);
    WLD_0_150.v := WLD_z_t_f ( 0, 150);

    effWLD_0_30.v := (EffWLD_Arr[1].v + EffWLD_Arr[2].v + EffWLD_Arr[3].v)/3;
    effWLD_30_60.v := (EffWLD_Arr[4].v + EffWLD_Arr[5].v + EffWLD_Arr[6].v)/3;
    effWLD_60_90.v := (EffWLD_Arr[7].v + EffWLD_Arr[8].v + EffWLD_Arr[9].v)/3;
    effWLD_90_120.v := (EffWLD_Arr[10].v + EffWLD_Arr[11].v + EffWLD_Arr[12].v)/3;
    effWLD_120_150.v := (EffWLD_Arr[13].v + EffWLD_Arr[14].v + EffWLD_Arr[15].v)/3;

  end;
  WLD_0_10.v := WLD_arr[1].v;
  WLD_10_20.v := WLD_arr[2].v;
  WLD_20_30.v := WLD_arr[3].v;
  WLD_30_40.v := WLD_arr[4].v;
  WLD_40_50.v := WLD_arr[5].v;
  WLD_50_60.v := WLD_arr[6].v;
  WLD_60_70.v := WLD_arr[7].v;
  WLD_70_80.v := WLD_arr[8].v;
  WLD_80_90.v := WLD_arr[9].v;
  WLD_90_100.v := WLD_arr[10].v;


  If ((Harvestdate <> nil) and (Globtime.v >= HarvestDate.v)) {or (PlantModel.DoHarvest = true)} then begin
    zr.v := 0.0;
    SRL.v := 0.0;

    for i := 1 to trunc(n_Rootcomp.v) do begin
      WLD_arr[i].v := 0.0;
      Wl_arr[i].v := 0.0;
      effWLD_arr[i].v := 0.0;
      effWl_arr[i].v := 0.0;
    end;
//    IsActive := false;
  end;
end;

procedure TSimpleRootModDM.integrate;

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
