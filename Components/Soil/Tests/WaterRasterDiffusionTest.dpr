program WaterRasterDiffusionTest;
{$APPTYPE CONSOLE}
{$R+}
{$Q+}
uses System.SysUtils, System.Math, U2DSoilBaseClasses, USubModRootH2O, UGenucht, USoilTexture;
type
  THydraulicModel = class(TSubmodRoot2DH2O)
  public
    function Diffusivity(X, Y: integer; Theta: double): double;
  end;
  TLaws = class
    D, S: double;
    VariableD: boolean;
    DCalls, SCalls: integer;
    function Diffusivity(X, Y: integer; Theta: double): double;
    function Uptake(X, Y: integer; Theta: double): double;
  end;
function THydraulicModel.Diffusivity(X, Y: integer; Theta: double): double;
begin
  Result := WaterDiffusivity(X, Y, Theta);
end;
function TLaws.Diffusivity(X, Y: integer; Theta: double): double;
begin
  Inc(DCalls);
  Result := D;
  if VariableD then Result := D * (2 * X - 1);
end;
function TLaws.Uptake(X, Y: integer; Theta: double): double;
begin
  Inc(SCalls);
  Result := S;
end;
procedure Near(const Name: string; Actual, Expected: double);
begin
  if IsNan(Actual) or IsInfinite(Actual) or (Abs(Actual - Expected) > 1E-11) then
    raise Exception.CreateFmt('%s: expected %.15g, got %.15g', [Name, Expected, Actual]);
end;
procedure CheckHydraulicDiffusion;
var
  Model: THydraulicModel;
  Soil: TGenucht;
  G: TRasterData;
  W: TRasterDataH2O;
  Step: integer;
  LeftTheta, RightTheta, DL, DR, FaceD, Factor, Dt: double;
begin
  Model := THydraulicModel.Create;
  Soil := TGenucht.Create;
  G := TRasterData.Create;
  W := TRasterDataH2O.Create(G);
  try
    VanGenuchtenFromTextureClass_RR(Soil, Sl3);
    Soil.Ks := KSFromTextureClass_RR(Sl3, OldVersion);
    Soil.m_par := 1 - 1 / Soil.n_par;
    Model.ConfigureWaterUptakeSoil(Soil);
    /// <summary>The callback must use Theta even without a model field initialization.</summary>
    Near('Hydraulic callback state and day units', Model.Diffusivity(1, 1, 0.3), Soil.Dw_f(0.3));
    G.Init(2, 1, 2, 3, 0, 0, 0);
    W.Init(0.3);
    W.Theta_xy[1, 1] := 0.25;
    W.Theta_xy[2, 1] := 0.35;
    Dt := 0.001;
    for Step := 1 to 2 do
    begin
      LeftTheta := W.Theta_xy[1, 1];
      RightTheta := W.Theta_xy[2, 1];
      DL := Soil.Dw_f(LeftTheta);
      DR := Soil.Dw_f(RightTheta);
      if not ((DL > 0) and (DR > DL)) then
        raise Exception.Create('Expected increasing hydraulic diffusivity');
      FaceD := 2 * DL * DR / (DL + DR);
      Factor := (1 - Dt * FaceD / 4) / (1 + Dt * FaceD / 4);
      W.SolveWaterDiffusionADI(Dt, Model.Diffusivity);
      Near('Nonlinear frozen-step left', W.Theta_xy[1, 1], 0.3 + (LeftTheta - 0.3) * Factor);
      Near('Nonlinear frozen-step right', W.Theta_xy[2, 1], 0.3 + (RightTheta - 0.3) * Factor);
      Near('Nonlinear mass conservation', W.WaterBalanceError, 0);
    end;
  finally
    W.Free;
    G.Free;
    Soil.Free;
    Model.Free;
  end;
end;

procedure Run;
var
  G: TRasterData;
  W: TRasterDataH2O;
  L: TLaws;
  X, Y, I: integer;
  LX, LY, Factor, Expected, OldAmount, OldBalance, OldUptake: double;
  Failed: boolean;
begin
  G := TRasterData.Create;
  W := TRasterDataH2O.Create(G);
  L := TLaws.Create;
  try
    G.Init(4, 3, 2, 3, 0, 0, 0);
    W.Init(0.3);
    L.D := 1;
    W.Theta_xy[0, 0] := 99;
    W.SolveWaterDiffusionADI(0.2, L.Diffusivity);
    for X := 1 to 4 do for Y := 1 to 3 do Near('Uniform', W.Theta_xy[X,Y], 0.3);
    Near('Helper retained', W.Theta_xy[0,0], 99);
    Near('Conservation', W.WaterBalanceError, 0);
    Near('Mean cell storage', W.CellWaterAmount, 1.8);

    { Independent discrete cosine eigenmode: unequal dimensions and spacings. }
    LX := -4 / Sqr(G.ColWidth) * Sqr(Sin(Pi / (2 * G.NCols)));
    LY := -4 / Sqr(G.RowHeight) * Sqr(Sin(Pi / (2 * G.NRows)));
    Factor := (1 + 0.1*LX)/(1 - 0.1*LX) * (1 + 0.1*LY)/(1 - 0.1*LY);
    for X := 1 to 4 do for Y := 1 to 3 do
      W.Theta_xy[X,Y] := 0.3 + 0.1*Cos(Pi*(X-0.5)/4)*Cos(Pi*(Y-0.5)/3);
    W.SolveWaterDiffusionADI(0.2, L.Diffusivity);
    for X := 1 to 4 do for Y := 1 to 3 do begin
      Expected := 0.3 + 0.1*Factor*Cos(Pi*(X-0.5)/4)*Cos(Pi*(Y-0.5)/3);
      Near('2D cosine decay', W.Theta_xy[X,Y], Expected);
    end;

    G.Init(2, 1, 2, 3, 0, 0, 0);
    W.Init(0.3);
    W.Theta_xy[1,1] := 0.2;
    W.Theta_xy[2,1] := 0.4;
    L.VariableD := true;
    W.SolveWaterDiffusionADI(0.2, L.Diffusivity);
    Factor := (1 - 0.2*1.5/4)/(1 + 0.2*1.5/4);
    Near('Harmonic face left', W.Theta_xy[1,1], 0.3 - 0.1*Factor);
    Near('Harmonic face right', W.Theta_xy[2,1], 0.3 + 0.1*Factor);
    L.VariableD := false;
    L.D := 0;
    Expected := W.Theta_xy[1,1];
    W.SolveWaterDiffusionADI(2, L.Diffusivity);
    Near('Zero diffusivity', W.Theta_xy[1,1], Expected);

    G.Init(4, 3, 2, 3, 0, 0, 0);
    W.Init(0.3);
    L.D := 1;
    L.S := 0.02;
    L.DCalls := 0;
    L.SCalls := 0;
    W.SolveWaterDiffusionADI(0.5, L.Diffusivity, L.Uptake);
    for X := 1 to 4 do for Y := 1 to 3 do Near('Uptake', W.Theta_xy[X,Y], 0.29);
    Near('Diffusivity calls', L.DCalls, 12);
    Near('Uptake calls', L.SCalls, 12);
    Near('Removed water', W.LastWaterUptake, 0.72);
    Near('Uptake balance', W.WaterBalanceError, 0);
    OldAmount := W.CellWaterAmount;
    OldBalance := W.WaterBalanceError;
    OldUptake := W.LastWaterUptake;
    for I := 1 to 4 do begin
      Failed := false;
      try
        case I of
          1: W.SolveWaterDiffusionADI(100, L.Diffusivity, L.Uptake);
          2: W.SolveWaterDiffusionADI(0.1, nil);
          3: W.SolveWaterDiffusionADI(-1, L.Diffusivity);
          4: begin L.D := -1; W.SolveWaterDiffusionADI(0.1, L.Diffusivity); end;
        end;
      except on E: Exception do Failed := true; end;
      if not Failed then raise Exception.Create('Invalid step accepted');
      for X := 1 to 4 do for Y := 1 to 3 do Near('Rejected field unchanged', W.Theta_xy[X,Y], 0.29);
      Near('Rejected amount unchanged', W.CellWaterAmount, OldAmount);
      Near('Rejected balance unchanged', W.WaterBalanceError, OldBalance);
      Near('Rejected uptake unchanged', W.LastWaterUptake, OldUptake);
    end;
    W.SolveWaterDiffusionADI(0, nil);
    Near('Zero timestep', W.CellWaterAmount, OldAmount);
    G.Init(1, 1, 2, 3, 0, 0, 0);
    W.Init(0.3);
    L.D := 1;
    W.SolveWaterDiffusionADI(0.5, L.Diffusivity, L.Uptake);
    Near('Singleton', W.Theta_xy[1,1], 0.29);
    Near('Singleton removed water', W.LastWaterUptake, 0.06);
    Writeln('PASS: uniform field, rectangular 2D cosine decay, harmonic faces, zero diffusion, uptake, singleton, rejected-step rollback.');
  finally
    L.Free;
    W.Free;
    G.Free;
  end;
end;
begin
  try CheckHydraulicDiffusion; Run;
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end; end;
end.