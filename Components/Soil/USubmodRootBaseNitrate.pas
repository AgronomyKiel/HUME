unit USubmodRootBaseNitrate;

 {$J+}
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid,
  UMod, UState, Diffko, URootObject, URootUptakeFunctions,
  U2DSoilBaseClasses, MathImge;

type

  /// <summary> Declaration of class TSubmodRootDiff. Class based on base class for derived diffusion models
  /// implements further details for nitrate budget but without explicit formulation for
  ///  nitrate transport which are defined in derived classes
  /// </summary>
  TSubmodRootBaseNitrate = class(TSubmodRootBase)
  private

    /// <summary>Protected declarations, also accessible by derived classes</summary>
  protected



  public
        /// <summary> Potential N uptake rate [Kg N/ha*d]</summary>
    NUptakeratepot: TPar;

    /// <summary>Mineralization rate [kg N/ha*d]</summary>
    NMinerRate_kgNha: TPar;

    /// <summary>Minimum soil solution concentration [g N/l], also needed for the numerical solution in the 1D model; note: originally in micromol/l</summary>
    Clmin: TPar;

    /// <summary>Michaelis-Menten constant [mol/cm3]</summary>
    Km: TPar;

    /// <summary>
    ///   initial soil nitrate [kg N/ha]
    /// </summary>
    IniSoilNitrate: TPar;

    /// <summary>Member HUME base class TState (state variables)</summary>
    /// <summary>N amount [kg N/ha], also basis for calculating concentrations in the calculation elements; see Kage dissertation p.79 where concentrations of 10.0 micromol/l were assumed</summary>
    NAmount: TState;

    /// <summary>Cumulative amount of N taken up by the roots [kg N/ha] for the specified depth</summary>
    SumNUptake: TState;

    /// <summary>Mineralization rate [Mol/cm^3*d]</summary>
    Min_S: TVar;

    /// <summary>Initial concentration [kg N/cm], calculated from the initial N amount; the 1D model can also calculate concentrations</summary>
    c_start: TVar;

    /// <summary>Average concentration in the soil solution [kg N/cm]</summary>
    cl_av: TVar;

    /// <summary>
    /// average Concentration [mol/cm3]
    /// </summary>
    c_av: TVar;

   /// <summary>maximum influx [g N/cm*d]</summary>
   Imax: TVar;

   ActArFromConc : TVar;

   ActAr : TVar;

    /// <summary>
    ///   Potential N Influx rate [mol/cm/d]
    /// </summary>
    PotentialNInfluxrate : TVar;

    /// <summary>
    ///   effective Diffusion coefficient [cm2/d]
    /// </summary>
    De : TVar;

    /// <summary>
    ///   Diffusion coefficient of nitrate in water [cm2/d]
    /// </summary>
    Dl : TVar;

    /// <summary>Type of uptake calculation</summary>
    NitrateUptakeFunction: TOption;


    procedure createAll; override;

    // procedure Init(var GlobModReferenz: TMod); override;
    procedure Init(var GlobMod: TMod); override;

  end; { Ende Deklaration TSubmodRootDiff }

implementation

/// <summary>Implementierung TSubmodRootDiff</summary>
/// <summary>
/// Creates and initializes state variables, variables and parameters. The first
/// parameter of the function call passes a string identical to the identifier and
/// can be searched for. The second parameter contains a string indicating the
/// unit used ([-] for dimensionless parameters, etc.). The third parameter is the
/// actual floating-point value. For an explanation of the identifiers, see the
/// declaration.
/// </summary>
procedure TSubmodRootBaseNitrate.createAll;
begin
  inherited createAll;
  SetEntityDeclarationClass(TSubmodRootBaseNitrate);
  ParCreate('Ar', '[kg N/ha*d]', 0, NUptakeratepot, 'Potential nitrate uptake rate');
  ParCreate('Minera', '[kg N/ha*d]', 0, NMinerRate_kgNha, 'Mineralization rate');
  ParCreate('Clmin', '[mol/l]', 0, Clmin, 'Minimum concentration');
  ParCreate('Km', '[mikromol/l]', 0, Km, 'Half-saturation concentration');
  ParCreate('iniSoilNitrate', '[kg N/ha]', 30, iniSoilNitrate, 'Initial nitrate amount in soil');

  // Create and initialize TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 30, false, NAmount,
    'N amount in the soil');
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, SumNUptake,
    'Cumulative N amount taken up by roots');
  // Create and initialize TVar
  { Caveat: variables are always initialized to 0. If a start value other than 0 is
    needed, calculation and assignment must occur in init. It would be better not to
    declare such variables as TVar. }

  VarCreate('Min_s', '[Mol/cm^3*d]', 0, false, Min_S, 'Mineralization rate in mol/cm3*s');
  VarCreate('c_start', '[Mol/cm^3]', 1e-5, false, c_start, 'Initial concentration');
  VarCreate('cl_av', '[Mol/cm^3]', 0, false, cl_av, 'Average concentration');
  VarCreate('Imax', '[mol/cm/d]', 0, false, Imax, 'Maximum influx rate');

  VarCreate('ActArFromConc', '[mol/cm/d]', 0, false, ActArFromConc, 'Actual uptake rate calculated from concentration');
  VarCreate('ActAr', '[mol/cm/d]', 0, false, ActAr, 'Actual uptake rate');
  VarCreate('C_av', '[mol/cm3]', 0, false, C_av, 'Average concentration');
  VarCreate('De', '[cm2/d]',  D0NO3*0.2*0.2*3.35, false, De, 'effective nitrate diffusion coefficient');
  ConstCreate('Dl', '[cm2/d]',  D0NO3, false, Dl, 'nitrate diffusion coefficient in water');

  // Create and initialize TOption
  { Specify the source of the root data }
  { Define uptake function }
  OptCreate('NitrateUptake_function', 'ZeroSink', NitrateUptakeFunction,
    'Defines the nitrate uptake function');
  NitrateUptakeFunction.OptionList.add('ZeroSink');
  NitrateUptakeFunction.OptionList.add('ConstInflux');
  NitrateUptakeFunction.OptionList.add('MM');

end; // End TSubmodRootDiff.CreateAll



procedure TSubmodRootBaseNitrate.Init(var GlobMod: TMod);
begin
  inherited Init(GlobMod);
  /// <summary>Preserve the 1-D nitrate models' initial water and nitrate quantities.
  /// Their concentration and influx conventions differ from the 2-D raster solver.</summary>
  theta.v := IniTheta.v;
  WAmount.v := theta.v * Depth.v;
  De.v := D0NO3 * f_Tortuosity(theta.v);
  NAmount.v := IniSoilNitrate.v;
  c_av.v := NAmount.v / WAmount.v;
  c_start.v := c_av.v;
  Min_S.v := NMinerRate_kgNha.v;
  if wl_ha.v > 0 then
    Imax.v := NUptakeratepot.v / wl_ha.v
  else
    Imax.v := 0;
end;



end.
