unit URootGrowthUtils;

interface


/// <summary> maximum number of root age cohorts. Dayly root growth is divided into these age classes </summary>
  const  MaxAgeCl = 500;


type
  real = double;


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
  ///
public
  constructor Create(TextureClass: string; LD: string; Weff: real; relWeff: real);
published
 property TextureClass : string read fTextureClass write fTextureClass;
 property LD : string read fLD write fLD;
 property Weff: real read fWeff write fWeff;
 property relWeff: real read frelWeff write frelWeff;

end;

function monomo_f(Pmax, P0, k, t: real): real;

function Logist_f(Wmax, W0, k, Tsum: real): real;

function WLD_z_f(wld0, a, z: real): real;


implementation


function monomo_f(Pmax, P0, k, t: real): real;

begin
  monomo_f := Pmax - (Pmax - P0) * exp(-k * t);
end;

function Logist_f(Wmax, W0, k, Tsum: real): real;

begin
  result := WMax / (1 + (WMAx / W0 - 1) * EXP(-TSum * k))

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
constructor TTextureeffect.create(TextureClass: string; LD: string; Weff: real; relWeff: real);
begin
  fTextureClass := TextureClass;
  fLD := LD;
  fWeff := Weff;
  frelWeff := relWeff;
end;





end.
