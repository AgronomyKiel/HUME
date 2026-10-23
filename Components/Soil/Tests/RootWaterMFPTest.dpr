program RootWaterMFPTest;

{$APPTYPE CONSOLE}

uses System.SysUtils, System.Math, UMod, U2DSoilBaseClasses, USubModRootH2O,
  URootObject, UGenucht, USoilTexture, WFlowFunctions;

type
  /// <summary>Isolate root uptake from horizontal redistribution in these tests.</summary>
  TUptakeOnlyModel = class(TSubmodRoot2DH2O)
  protected
    function WaterDiffusivity(X, Y: integer; ATheta: double): double; override;
  end;

function TUptakeOnlyModel.WaterDiffusivity(X, Y: integer; ATheta: double): double;
begin
  Result := 0;
end;

procedure Near(const Name: string; Actual, Expected: double);
begin
  if Abs(Actual - Expected) > 1E-10 * Max(1, Abs(Expected)) then
    raise Exception.CreateFmt('%s: expected %.15g, got %.15g', [Name, Expected, Actual]);
end;

procedure Check(Condition: boolean; const Name: string);
begin
  if not Condition then raise Exception.Create(Name);
end;

function AddRoot(Model: TSubmodRoot2DH2O; X, Y: integer): TRootObjectIn2D;
begin
  Result := TRootObjectIn2D.Create;
  Result.xi := X;
  Result.yi := Y;
  Model.RootList.AddObject(IntToStr(Model.RootList.Count), Result);
end;

procedure Run;
var
  Clock: TMod;
  Model: TSubmodRoot2DH2O;
  A, B, C: TRootObjectIn2D;
  Soil: TGenucht;
  Table: TMFP_table;
  OldTheta, OldSum, OldInflux, Capacity, Demand: double;
  Failed: boolean;
begin
  FormatSettings.ShortDateFormat := 'dd.mm.yyyy';
  FormatSettings.DateSeparator := '.';
  Clock := TMod.Create;
  Model := TUptakeOnlyModel.Create;
  Soil := TGenucht.Create;
  try
    Model.dim_x.v := 2;
    Model.dim_y.v := 1;
    Model.dimensionX.v := 4;
    Model.dimensionY.v := 2;
    Model.gridWidth.v := 2;
    Model.gridHeight.v := 2;
    Model.Depth.v := 10;
    Model.IniTheta.v := 0.3;
    Model.ParMRLD.v := 0;
    Model.OutputXY.Option := 'no';
    Model.RootRadius.v := 0.02;
    Model.SoilTexture.Option := 'Sl3';
    Model.TextureVersion.Option := 'RR';
    Model.Init(Clock);
    Clock.Time.c := 0.01;
    Model.PotentialWaterUptake.v := 0.3;
    Model.CalcRates;
    Near('No roots', Model.getWaterRasterData.LastWaterUptake, 0);
    A := AddRoot(Model, 1, 1);
    B := AddRoot(Model, 1, 1);
    C := AddRoot(Model, 2, 1);
    Model.NRoots := 999;
    Model.CalcRates;
    Demand := 0.3 / 3 / 10 / 86400;
    Near('Equal root demand in seconds', A.WInflux, Demand);
    Near('Second root in same cell', B.WInflux, Demand);
    Near('Other cell root', C.WInflux, Demand);
    Near('Cell aggregates both roots', Model.getWaterRasterData.Theta_xy[1, 1], 0.3 - 0.2 / 40 * 0.01);
    Near('Whole domain water balance', Model.getWaterRasterData.LastWaterUptake * 10, 0.3 * 0.01);
    Near('Cumulative influx per root length', A.SumWInflux, 0.1 / 10 * 0.01);
    Near('Solver balance', Model.getWaterRasterData.WaterBalanceError, 0);

    VanGenuchtenFromTextureClass_RR(Soil, Sl3);
    Soil.Ks := KSFromTextureClass_RR(Sl3, OldVersion);
    Soil.m_par := 1 - 1 / Soil.n_par;
    Table := TMFP_table.Create(Soil);
    try
      Capacity := MFP_IWmax(Table.get_sumku(Soil.psi_b_f(0.3)), Sqrt(4 / Pi), 0.02) / 86400;
    finally
      Table.Free;
    end;
    Model.PotentialWaterUptake.v := 1E8;
    Clock.Time.c := 1E-8;
    Model.getWaterRasterData.Init(0.3);
    Model.CalcRates;
    Check(Capacity > 0, 'Positive transport capacity');
    Near('Transport-limited root', A.WInflux * 86400, Capacity * 86400);
    Near('Full area for each colocated root', A.WInflux * 86400, C.WInflux * 86400);
    Near('Transport-limited balance', Model.getWaterRasterData.LastWaterUptake, Capacity * 86400 * 3 * Clock.Time.c);

    Model.getWaterRasterData.Theta_xy[1, 1] := Soil.b_rest;
    Model.CalcRates;
    Near('Dry cell uptake', A.WInflux, 0);
    Near('Second dry root', B.WInflux, 0);
    Check(C.WInflux > 0, 'Wet cell still supplies water');
    Model.getWaterRasterData.Init(Soil.b_sat);
    Model.CalcRates;
    Check(A.WInflux > 0, 'Saturated endpoint is finite and positive');

    OldTheta := Model.getWaterRasterData.Theta_xy[1, 1];
    OldSum := A.SumWInflux;
    OldInflux := A.WInflux;
    /// <summary>Single-step rejection remains available when adaptation is disabled.</summary>
    Model.AdaptiveWaterTimeStep.Option := 'no';
    Clock.Time.c := 1E6;
    Failed := false;
    try Model.CalcRates;
    except on E: Exception do Failed := true; end;
    Check(Failed, 'Overlarge timestep must reject');
    Near('Rejected field unchanged', Model.getWaterRasterData.Theta_xy[1, 1], OldTheta);
    Near('Rejected cumulative root uptake unchanged', A.SumWInflux, OldSum);
    Near('Rejected root rate unchanged', A.WInflux, OldInflux);

    Model.AdaptiveWaterTimeStep.Option := 'yes';
    Clock.Time.c := 0.01;
    Model.PotentialWaterUptake.v := 0;
    Model.CalcRates;
    Near('Zero demand resets rate', A.WInflux, 0);
    Near('Zero demand preserves cumulative uptake', A.SumWInflux, OldSum);
    Model.PotentialWaterUptake.v := -1;
    Failed := false;
    try Model.CalcRates;
    except on E: EArgumentException do Failed := true; end;
    Check(Failed, 'Negative demand rejected');
    Model.PotentialWaterUptake.v := 1;
    A.xi := 0;
    Failed := false;
    try Model.CalcRates;
    except on E: ERangeError do Failed := true; end;
    Check(Failed, 'Root outside grid rejected');
    A.xi := 1;
    Model.RootRadius.v := 1;
    Failed := false;
    try Model.CalcRates;
    except on E: EArgumentException do Failed := true; end;
    Check(Failed, 'Invalid radial geometry rejected');
    Model.RootRadius.v := 0.02;
    Model.TextureVersion.Option := 'KA';
    Model.SoilTexture.Option := 'Ss';
    Model.Init(Clock);
    A := AddRoot(Model, 1, 1);
    Model.CalcRates;
    Check(A.WInflux > 0, 'KA texture selection initializes uptake');
    Writeln('Root water MFP tests passed');
  finally
    Soil.Free;
    Model.Free;
    Clock.Free;
  end;
end;

begin
  try Run;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
