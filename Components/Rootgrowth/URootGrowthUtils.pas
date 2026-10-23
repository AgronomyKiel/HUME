unit URootGrowthUtils;

interface

/// <summary> maximum number of root age cohorts. Dayly root growth is divided into these age classes </summary>
const
  MaxAgeCl = 500;
  RootLengthDensityLayerCount = 20;
  RootLengthDensityMomentCount = 10;

type
  real = double;
  /// <summary>Circular buffer of root length increments, one cohort per model step.</summary>
  TRootAgeCohorts = array [1 .. MaxAgeCl] of real;
  /// <summary>Ten representative quantiles of a root length density distribution.</summary>
  TRootLengthDensityMoments =
    array [1 .. RootLengthDensityMomentCount] of real;

  /// <summary>Root length density quantiles for each of the 20 soil layers.</summary>
  TRootLengthDensityMomentMatrix =
    array [1 .. RootLengthDensityLayerCount] of TRootLengthDensityMoments;

  /// <summary>Typed link to a root length density moment matrix.</summary>
  PRootLengthDensityMomentMatrix = ^TRootLengthDensityMomentMatrix;


  /// Enumeration of options for the increase of rooting depth.
  /// The options include linear and expolinear.
  TRootingdepthIncrease = (linear, expolinear, monomolecular);

  // an object to store the effects of soil texture on root growth
  /// <summary>
  /// Represents a texture effect for root growth.
  /// </summary>
  TTextureEffect = class(TObject)
  private
    fTextureClass: string; // the texture class according to KA5
    fLD: string;
    // a string with the layer density class LD1 .. LD5 according to KA5
    fWeff: real; // the effective rooting depth in dm
    frelWeff: real;
    // the relative effective rooting depth, relative to Ut3 at LD3
  protected
    /// <summary>
    /// Creates a new instance of the TTextureEffect class.
    /// </summary>
    /// <param name="TextureClass">The texture class according to KA5.</param>
    /// <param name="LD">A string with the layer density class LD1 .. LD5 according to KA5.</param>
    /// <param name="Weff">The effective rooting depth in dm.</param>
    /// <param name="relWeff">The relative effective rooting depth, relative to Ut3 at LD3.</param>
    ///
  public
    constructor Create(TextureClass: string; LD: string; Weff: real;
      relWeff: real);
  published
    property TextureClass: string read fTextureClass write fTextureClass;
    property LD: string read fLD write fLD;
    property Weff: real read fWeff write fWeff;
    property relWeff: real read frelWeff write frelWeff;

  end;

function monomo_f(Pmax, P0, k, t: real): real;

function Logist_f(Wmax, W0, k, Tsum: real): real;

function WLD_z_f(wld0, a, z: real): real;

/// <summary>Normalizes ten lognormal quantiles to the supplied mean; CV is in percent.</summary>
procedure CalculateLognormalMoments(const MeanRootLengthDensity,
  CoefficientOfVariation: real; var Moments: TRootLengthDensityMoments);
function CalculateMomentStandardDeviation(
  const Moments: TRootLengthDensityMoments): real;

/// <summary>Replaces the youngest cohort and updates the active sliding sum.</summary>
/// <remarks>Heads are 1-based, PreviousHead may be zero at startup; counts are bounded to MaxAgeCl.</remarks>
procedure UpdateRootAgeCohort(var Cohorts: TRootAgeCohorts;
  Head, PreviousHead, ActiveCount, PreviousActiveCount: integer;
  NewRootLength: real; var ActiveRootLength: real);

implementation

uses Math;

procedure CalculateLognormalMoments(
  const MeanRootLengthDensity, CoefficientOfVariation: real;
  var Moments: TRootLengthDensityMoments);
const
  StandardNormalQuantiles: TRootLengthDensityMoments =
    (-1.64485347566998, -1.03643338949379, -0.674489750196082,
     -0.385320466407568, -0.125661346855074, 0.125661346855074,
      0.385320466407568, 0.674489750196082, 1.03643338949379,
      1.64485347566998);
var
  MomentIndex: integer;
  CoefficientOfVariationFraction: real;
  StandardDeviationLog, MeanLog, SumOfMoments, ScaleFactor: real;
begin
  if MeanRootLengthDensity <= 0.0 then
  begin
    for MomentIndex := 1 to RootLengthDensityMomentCount do
      Moments[MomentIndex] := 0.0;
    exit;
  end;

  CoefficientOfVariationFraction :=
    max(0.0, CoefficientOfVariation) / 100.0;
  StandardDeviationLog :=
    sqrt(ln(sqr(CoefficientOfVariationFraction) + 1.0));
  MeanLog := ln(MeanRootLengthDensity) -
    0.5 * sqr(StandardDeviationLog);

  SumOfMoments := 0.0;
  for MomentIndex := 1 to RootLengthDensityMomentCount do
  begin
    Moments[MomentIndex] := exp(MeanLog + StandardDeviationLog *
      StandardNormalQuantiles[MomentIndex]);
    SumOfMoments := SumOfMoments + Moments[MomentIndex];
  end;

  if SumOfMoments > 0.0 then
  begin
    ScaleFactor := MeanRootLengthDensity * RootLengthDensityMomentCount /
      SumOfMoments;
    for MomentIndex := 1 to RootLengthDensityMomentCount do
      Moments[MomentIndex] := Moments[MomentIndex] * ScaleFactor;
  end;
end;

function CalculateMomentStandardDeviation(
  const Moments: TRootLengthDensityMoments): real;
var
  MomentIndex: integer;
  MomentMean, SumSquaredDeviations: real;
begin
  MomentMean := 0.0;
  for MomentIndex := 1 to RootLengthDensityMomentCount do
    MomentMean := MomentMean + Moments[MomentIndex];
  MomentMean := MomentMean / RootLengthDensityMomentCount;

  SumSquaredDeviations := 0.0;
  for MomentIndex := 1 to RootLengthDensityMomentCount do
    SumSquaredDeviations := SumSquaredDeviations +
      sqr(Moments[MomentIndex] - MomentMean);

  Result := sqrt(SumSquaredDeviations /
    RootLengthDensityMomentCount);
end;

procedure UpdateRootAgeCohort(var Cohorts: TRootAgeCohorts;
  Head, PreviousHead, ActiveCount, PreviousActiveCount: integer;
  NewRootLength: real; var ActiveRootLength: real);
var
  j, Index: integer;
  ExpiredRootLength: real;
begin
  ActiveCount := min(max(ActiveCount, 0), MaxAgeCl);
  NewRootLength := max(0.0, NewRootLength);
  if ActiveCount <> PreviousActiveCount then
  begin
    Cohorts[Head] := NewRootLength;
    ActiveRootLength := 0.0;
    for j := 1 to ActiveCount do
    begin
      Index := Head - j + 1;
      if Index <= 0 then
        inc(Index, MaxAgeCl);
      ActiveRootLength := ActiveRootLength + Cohorts[Index];
    end;
  end
  else if ActiveCount > 0 then
  begin
    Index := PreviousHead - ActiveCount + 1;
    if Index <= 0 then
      inc(Index, MaxAgeCl);
    ExpiredRootLength := Cohorts[Index];
    Cohorts[Head] := NewRootLength;
    ActiveRootLength := max(0.0,
      ActiveRootLength - ExpiredRootLength + NewRootLength);
  end
  else
  begin
    Cohorts[Head] := NewRootLength;
    ActiveRootLength := 0.0;
  end;
end;


function monomo_f(Pmax, P0, k, t: real): real;

begin
  monomo_f := Pmax - (Pmax - P0) * exp(-k * t);
end;

function Logist_f(Wmax, W0, k, Tsum: real): real;

begin
  result := Wmax / (1 + (Wmax / W0 - 1) * exp(-Tsum * k))

end;

function WLD_z_f(wld0, a, z: real): real;

begin
  WLD_z_f := wld0 * exp(-a * z);
end;

/// <summary>
/// Constructor for TTextureeffect class.
/// </summary>
/// <param name="TextureClass">The texture class.</param>
/// <param name="LD">The LD value.</param>
/// <param name="Weff">The Weff value.</param>
/// <param name="relWeff">The relative Weff value.</param>
constructor TTextureEffect.Create(TextureClass: string; LD: string; Weff: real;
  relWeff: real);
begin
  fTextureClass := TextureClass;
  fLD := LD;
  fWeff := Weff;
  frelWeff := relWeff;
end;

end.
