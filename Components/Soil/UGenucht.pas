Unit UGenucht;

{ Collection of functions from:
  Van Genuchten, M. T. (1980)
  A closed-form equation for predicting the hydraulic conductivity
  of unsaturated soils
  Soil Sci. Soc. Am. J. (1980), 44, 892-898 }

{ Extended on 25.8.89 by the parameter "l"
  see:
  Wosten, J.H.M., M.Th. Van Genuchten (1988)
  Using Texture and Other Soil Properties to predict
  the Unsaturated Soil Hydraulic Functions
  Soil Sci.Soc.Am.J. (1988) 52, 1762-1770 }

interface

const
  psimin = 2.0;

type
  real = double;

  TGenucht = class(TObject)
  private
    FbSat: real;
    FbRest: real;
    FKs: real;
    FAlpha: real;
    FnPar: real;
    FmPar: real;
    FlPar: real;

    FCoefficientsCalculated: Boolean;
    FInvMParValid: Boolean;
    FInvNParValid: Boolean;
    FInvWaterContentRangeValid: Boolean;
    FCapacityCoefficientValid: Boolean;
    FDiffusivityCoefficientValid: Boolean;
    FInvMPar: real;
    FInvNPar: real;
    FWaterContentRange: real;
    FInvWaterContentRange: real;
    FLMinusInvMPar: real;
    FCapacityCoefficient: real;
    FDiffusivityCoefficient: real;

    procedure InvalidateCoefficients; inline;
    procedure EnsureCoefficients; inline;
    procedure SetBSat(Value: real);
    procedure SetBRest(Value: real);
    procedure SetKs(Value: real);
    procedure SetAlpha(Value: real);
    procedure SetNPar(Value: real);
    procedure SetMPar(Value: real);
    procedure SetLPar(Value: real);

  public
    /// <summary>Water content at saturation [cm3/cm3].</summary>
    property b_sat: real read FbSat write SetBSat;

    /// <summary>Residual water content [cm3/cm3].</summary>
    property b_rest: real read FbRest write SetBRest;

    /// <summary>Saturated hydraulic conductivity [cm/d].</summary>
    property Ks: real read FKs write SetKs;

    /// <summary>Fitting parameter "alpha" [1/cm].</summary>
    property alpha: real read FAlpha write SetAlpha;

    /// <summary>Dimensionless fitting parameter "n".</summary>
    property n_par: real read FnPar write SetNPar;

    /// <summary>
    /// Fitting parameter "m" = 1-1/n (Mualem), 1-2/n (Burdine), or 1 (Vereecken).
    /// </summary>
    property m_par: real read FmPar write SetMPar;

    /// <summary>Fitting parameter "l".</summary>
    property l_par: real read FlPar write SetLPar;

    /// <summary>Precalculates coefficients that depend only on soil parameters.</summary>
    procedure PrecalculateCoefficients;

    /// <summary>
    /// Calculates the relative water content from volumetric water content (b),
    /// residual water content (b_rest), and water content at saturation (b_sat).
    /// </summary>
    function b_rel_f(b: real): real;

    /// <summary>Calculates volumetric water content (b) from water tension (psi).</summary>
    function b_psi_f(psi: real): real;

    /// <summary>
    /// Calculates the absolute value of water tension (positive)
    /// from volumetric water content.
    /// </summary>
    function psi_b_f(b: real): real;

    /// <summary>Calculates unsaturated hydraulic conductivity.</summary>
    function Ku_b_f(b: real): real;

    /// <summary>Calculates unsaturated hydraulic conductivity.</summary>
    function Ku_psi_f(psi: real): real;

    /// <summary>Calculates specific water storage capacity.</summary>
    function C_b_f(b: real): real;

    /// <summary>Calculates specific water storage capacity.</summary>
    function C_psi_f(psi: real): real;

    /// <summary>Calculates water diffusivity.</summary>
    function Dw_f(b: real): real;

    /// <summary>Calculates relative water content from water tension "psi".</summary>
    function b_rel_psi_f(psi: real): real;

  end;

implementation

uses
  Math;

procedure TGenucht.InvalidateCoefficients;
begin
  FCoefficientsCalculated := False;
end;

procedure TGenucht.EnsureCoefficients;
begin
  if not FCoefficientsCalculated then
    PrecalculateCoefficients;
end;

procedure TGenucht.SetBSat(Value: real);
begin
  FbSat := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.SetBRest(Value: real);
begin
  FbRest := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.SetKs(Value: real);
begin
  FKs := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.SetAlpha(Value: real);
begin
  FAlpha := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.SetNPar(Value: real);
begin
  FnPar := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.SetMPar(Value: real);
begin
  FmPar := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.SetLPar(Value: real);
begin
  FlPar := Value;
  InvalidateCoefficients;
end;

procedure TGenucht.PrecalculateCoefficients;
var
  Denominator: real;
begin
  FWaterContentRange := FbSat - FbRest;

  FInvMParValid := FmPar <> 0.0;
  if FInvMParValid then
    FInvMPar := 1.0 / FmPar;

  FInvNParValid := FnPar <> 0.0;
  if FInvNParValid then
    FInvNPar := 1.0 / FnPar;

  FInvWaterContentRangeValid := FWaterContentRange <> 0.0;
  if FInvWaterContentRangeValid then
    FInvWaterContentRange := 1.0 / FWaterContentRange;

  if FInvMParValid then
    FLMinusInvMPar := FlPar - FInvMPar;

  Denominator := 1.0 - FmPar;
  FCapacityCoefficientValid := Denominator <> 0.0;
  if FCapacityCoefficientValid then
    FCapacityCoefficient :=
      -(FAlpha * FmPar * FWaterContentRange) / Denominator;

  Denominator := FAlpha * FmPar * FWaterContentRange;
  FDiffusivityCoefficientValid := Denominator <> 0.0;
  if FDiffusivityCoefficientValid then
    FDiffusivityCoefficient := ((1.0 - FmPar) * FKs) / Denominator;

  FCoefficientsCalculated := True;
end;

function TGenucht.b_rel_f(b: real): real;
begin
  EnsureCoefficients;
  if FInvWaterContentRangeValid then
    b_rel_f := min(1, max(0, (b - FbRest) * FInvWaterContentRange))
  else
    b_rel_f := min(1, max(0, (b - FbRest) / (FbSat - FbRest)));
end;

function TGenucht.b_rel_psi_f(psi: real): real;
var
  z1: real;

begin
  // psi := max(psi, psimin);
  z1 := 1 + power(alpha * max(0, psi), n_par);
  b_rel_psi_f := power(1 / z1, m_par);
end;

function TGenucht.b_psi_f(psi: real): real;
var
  z1, z2: real;

begin
  EnsureCoefficients;
  // psi := max(psi, psimin);

  // If psi <= 0.0 then b_psi_f := b_sat else begin
  z1 := power(FAlpha * abs(psi), FnPar);
  z2 := power(1 + z1, FmPar);
  b_psi_f := FbRest + FWaterContentRange / z2;
  // end;
end;

function TGenucht.psi_b_f(b: real): real;
var
  InvM, InvN, z1, z2: real;

begin
  EnsureCoefficients;
  If b >= FbSat then
  begin
    psi_b_f := 0.0;
    exit;
  end;
  // psi := max(psi, psimin);

  if b < FbRest then
  begin
    psi_b_f := 1E5;
    exit;
  end;
  // if (b-b_rest)>0.0 then begin
  // if (b-b_rest)>1e-06 then begin // ar: 26.05.17
  if (b - FbRest) > 1E-03 then
  begin
    if FInvMParValid then
      InvM := FInvMPar
    else
      InvM := 1.0 / FmPar;
    if FInvNParValid then
      InvN := FInvNPar
    else
      InvN := 1.0 / FnPar;

    z1 := FWaterContentRange / (b - FbRest);
    z2 := power(z1, InvM) - 1;
    psi_b_f := power(z2, InvN) / FAlpha;
  end
  // else psi_b_f := 1e10;
  else
    psi_b_f := 1E5;
end;

function TGenucht.Ku_b_f(b: real): real;
var
  b_rel, InvM, K_rel, Ku, z1, z2, z3: real;

begin
  EnsureCoefficients;
  If b >= FbSat then
    Ku := FKs
  else if b <= FbRest then
    Ku := 0.0
  else
  { Safeguard against exceeding the function's domain. }
  begin
    if FInvMParValid then
      InvM := FInvMPar
    else
      InvM := 1.0 / FmPar;

    b_rel := b_rel_f(b);
    z1 := power(1 - power(b_rel, InvM), FmPar);
    z2 := power(b_rel, FlPar);
    // Z3     := intpower(1-z1, 2);
    z3 := sqr(1 - z1);
    K_rel := z2 * z3;
    Ku := K_rel * FKs;
    If (Ku < 0.0) then
      Ku := 0.0;
  end;
  Ku_b_f := Ku;
end;

function TGenucht.Ku_psi_f(psi: real): real;
var
  K_rel, Ku, z1, z2, z3, z4, z5: real;

begin
  // If psi <= 0.0 then Ku := Ks
  // else begin

  // psi := max(psi, psimin);

  z1 := power(alpha * psi, n_par);
  z2 := power(alpha * psi, n_par - 1);
  // z2 := z1 * (1.0/n_par) ;
  z3 := power(1 + z1, -m_par);
  z4 := intpower(1 - z2 * z3, 2);
  z5 := power(1 + z1, m_par * l_par);
  K_rel := z4 / z5;
  Ku := K_rel * Ks;
  // end;
  Ku_psi_f := Ku;
end;

function TGenucht.C_b_f(b: real): real;
var
  b_rel, InvM, z1, z2: real;
  help: real;
begin
  EnsureCoefficients;
  If b <= FbRest then
    b := FbRest + 1E-5;
  If b >= FbSat then
    b := FbSat - 1E-5;
  b_rel := b_rel_f(b);

  if FInvMParValid then
    InvM := FInvMPar
  else
    InvM := 1.0 / FmPar;
  help := power(b_rel, InvM);

  // z1       := power(1-power(b_rel,1/m_par),m_par);
  z1 := power(1 - help, FmPar);
  if FCapacityCoefficientValid then
    z2 := FCapacityCoefficient
  else
    z2 := -(FAlpha * FmPar * FWaterContentRange) / (1.0 - FmPar);
  // C_b_f    := z2*power(b_rel,1/m_par)*z1;
  C_b_f := z2 * help * z1;
end;

function TGenucht.C_psi_f(psi: real): real;
var
  b_rel, InvM, z1, z2: real;
  help: real;

begin
  EnsureCoefficients;
  // psi := max(psi, psimin);

  b_rel := b_rel_psi_f(psi);
  if FInvMParValid then
    InvM := FInvMPar
  else
    InvM := 1.0 / FmPar;
  help := power(b_rel, InvM);

  // z1       := power(1-power(b_rel,1/m_par),m_par);
  z1 := power(1 - help, FmPar);
  if FCapacityCoefficientValid then
    z2 := FCapacityCoefficient
  else
    z2 := -(FAlpha * FmPar * FWaterContentRange) / (1.0 - FmPar);
  // C_psi_f    := z2*power(b_rel,1/m_par)*z1;
  C_psi_f := z2 * help * z1;
end;

function TGenucht.Dw_f(b: real): real;
var
  InvM, LMinusInvM, z1, z2, z3, z4, z5, z6, z7, b_rel: real;

begin
  EnsureCoefficients;
  If b <= FbRest then
    b := FbRest + 1E-5;
  If b >= FbSat then
    b := FbSat - 1E-5;

  if FInvWaterContentRangeValid then
    b_rel := (b - FbRest) * FInvWaterContentRange
  else
    b_rel := (b - FbRest) / FWaterContentRange;

  if FInvMParValid then
  begin
    InvM := FInvMPar;
    LMinusInvM := FLMinusInvMPar;
  end
  else
  begin
    InvM := 1.0 / FmPar;
    LMinusInvM := FlPar - InvM;
  end;
  z1 := 1 - power(b_rel, InvM);

  z2 := power(z1, FmPar);
  // z3:= power(z1, -m_par);
  z3 := 1 / z2;
  z4 := z3 + z2 - 2;
  if FDiffusivityCoefficientValid then
    z5 := FDiffusivityCoefficient
  else
    z5 := ((1.0 - FmPar) * FKs) /
      (FAlpha * FmPar * FWaterContentRange);
  z6 := power(b_rel, LMinusInvM);
  z7 := z5 * z6;
  Dw_f := z7 * z4;
end;

end.
