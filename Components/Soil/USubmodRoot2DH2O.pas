/// <summary>Horizontal water transport and MFP-limited root water uptake.</summary>
unit USubmodRoot2DH2O;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils, UMod, UState, URootObject,
  UGenucht, WFlowFunctions, USoilTexture, U2DSoilBaseClasses;

type
  /// <summary>Cell law evaluated at the beginning of a water step; callbacks must not modify state.</summary>
  TWaterCellFunction = function(X, Y: integer; ATheta: double): double of object;
  
  /// <summary>2D water content field, including helper slots 0 and N+1.</summary>
  TWaterGrid = array of array of double;

  /// <summary>Water field using the submodel's shared geometry. Does not own Geometry.</summary>
  TRasterDataH2O = class(TObject)
  private
    /// <summary>Shared geometry of the computational grid.</summary>
    FGeometry: TRasterData;
    FLayerDepth: double;
    FLastDrainage: double;

    /// <summary>Water balance error [cm3] after the last accepted step.</summary>
    FWaterBalanceError, 
    /// <summary>Total water removed in the last accepted step [cm3].</summary>
    FLastWaterUptake: double;
    /// <summary>Water storage change over the last accepted interval [cm3].</summary>
    fStorageChange: double;
    function GetCellWaterVolume(X, Y: integer): double;
  public
    /// <summary>Volumetric water content of each cell [cm3/cm3].</summary>
    Theta_xy: TWaterGrid;
    /// <summary>Mean full-depth cell water volume [cm3]; not a substitute for local water storage.</summary>
    CellWaterAmount: double;
    constructor Create(AGeometry: TRasterData);

    /// <summary> Initializes the water field to a uniform value; call after geometry is initialized </summary>
    procedure Init(ATheta: double; ADepth: double = 1);
    /// <summary>Full water volume of the requested active grid cell [cm3].</summary>
    property CellWaterVolume[X, Y: integer]: double read GetCellWaterVolume;
    property LayerDepth: double read FLayerDepth;
    /// <summary>Water leaving the bottom during the last accepted interval [cm3].</summary>
    property LastDrainage: double read FLastDrainage;

    /// <summary>Water-content transport with closed boundaries except optional bottom free drainage.</summary>
    /// <param name="ADtDays">Timestep [d]. Zero leaves the field unchanged.</param>
    /// <param name="ADiffusivity">Required nonnegative water diffusivity D(theta) [cm2/d].</param>
    /// <param name="AUptake">Optional nonnegative volumetric water removal rate [cm3/cm3/d].</param>
    /// <param name="AFreeDrainage">Set bottom outflow to local Ku with zero matric gradient; requires AConductivity.</param>
    /// <param name="AConductivity">Optional Ku(theta) [cm/d]; nil means horizontal. Positive Y is downward.</param>
    /// <param name="AMinTheta">Minimum permitted water content [cm3/cm3].</param>
    /// <param name="AMaxTheta">Maximum permitted water content [cm3/cm3].</param>
    /// <remarks>Peaceman-Rachford ADI with coefficients frozen at the old state, harmonic face diffusivities
    /// and active indices 1..N. Each callback is evaluated once per cell. Optional gravity uses harmonic Ku at internal Y faces, frozen at the old state; outer flux is zero except optional bottom unit-gradient drainage. No circular mask.
    /// Failure raises an exception without committing field/diagnostics; reduce the timestep and retry.
    /// Nonlinear diffusivity is lagged, not Picard-iterated. This is not a mixed-form Richards solver.</remarks>
    procedure SolveWaterDiffusionADI(ADtDays: double; ADiffusivity: TWaterCellFunction;
      AUptake: TWaterCellFunction = nil; AMinTheta: double = 0; AMaxTheta: double = 1; AConductivity: TWaterCellFunction = nil; AFreeDrainage: boolean = false);
    /// <summary>Water storage change over the last accepted interval [cm3].</summary>
    property StorageChange: double read FStorageChange;
    /// <summary>Water balance error [cm3] after the last accepted step.</summary>
    property WaterBalanceError: double read FWaterBalanceError;

    /// <summary>Total water removed in the last accepted step [cm3].</summary>
    property LastWaterUptake: double read FLastWaterUptake;

    /// <summary>Shared geometry of the computational grid.</summary>
    property Geometry: TRasterData read FGeometry;
  end;


  /// <summary>Horizontal soil water diffusion and optional uptake, without nitrate quantities.</summary>
  TSubmodRoot2DH2O = class(TSubmodRoot2D)
  private

    /// <summary>Owned hydraulic properties of the soil</summary>
    FHydraulicSoil: TGenucht;

    /// <summary>Owned MFP table for the hydraulic law</summary>
    FMFPTable: TMFP_table;

    /// <summary>Owned water uptake grid, used to model water uptake by roots</summary>
    FRootWaterSink: TWaterGrid;
    FPendingRootInflux: array of double;
    FNextWaterDt, FWaterDemandFactor: double;
    FInfluxPath: string;
    FInfluxStarted: boolean;
    FInfluxStart, FInfluxNext, FInfluxEnd: double;
    FInfluxVolumes, FInfluxCumulative: TArray<double>;
    procedure AppendInfluxOutput(Lines: TStrings);
    procedure PrepareRootWaterUptake;
    procedure InitializeWaterUptakeSoil;
  protected
    RasterDataH2O: TRasterDataH2O;

    /// <summary>Texture-derived water diffusivity D(ATheta) [cm2/d], frozen for each ADI step.</summary>
    function WaterDiffusivity(X, Y: integer; ATheta: double): double; virtual;
    /// <summary>Ku [cm/d] for gravity along positive Y (downward), or zero for horizontal planes.</summary>
    function GravityConductivity(X, Y: integer; ATheta: double): double; virtual;
    /// <summary>Potential influx [cm3/cm root/s]; equal shares of domain demand by default.
    /// Override for other distributions; shares must sum to at most the domain demand.</summary>
    function PotentialRootWaterInflux(ARootIndex: integer): double; virtual;
    /// <summary>Exact interval mean of the legacy 04:00..20:00 sinusf curve.
    /// The caller splits intervals at hour boundaries.</summary>
    function DiurnalDemandFactor(StartDay, StepDays: double): double;
    /// <summary>Prepared nonnegative MFP-limited cell removal [cm3/cm3/d].</summary>
    function WaterUptake(X, Y: integer; ATheta: double): double; virtual;
    procedure UpdateWaterTotals;
  public
    /// <summary>Legacy constant diffusivity parameter [cm2/d]; unused by the texture-derived law.</summary>
    WaterDiffusionCoefficient: TPar;
    /// <summary>Internal step control in days; the outer model clock is not changed.</summary>
    MinWaterDt, MaxThetaChange: TPar;
    /// <summary>Interval-average per-root influx output; interval is in days.</summary>
    RootInfluxOutputInterval: TPar;
    WriteRootWaterInflux, RootWaterInfluxFile: TOption;
    AdaptiveWaterTimeStep, WaterUptakePattern: TOption;
    /// <summary>horizontal (no gravity) or vertical (Y increases downward); closed boundaries.</summary>
    TransportPlane: TOption;
    /// <summary>closed or freeDrainage; free drainage requires vertical transport.</summary>
    BottomBoundary: TOption;
    WaterInternalSteps, WaterRejectedSteps: TVar;
    /// <summary>Potential extraction per unit domain ground area [cm/d].</summary>
    PotentialWaterUptake: TPar;
    /// <summary>Ground-area normalized extraction [cm/d], cumulative extraction and balance error [cm].</summary>
    ActualWaterUptake, CumulativeWaterUptake, WaterBalanceError: TVar;
    /// <summary>Bottom outflow normalized by domain area: rate [cm/d], total [cm].</summary>
    ActualDrainage, CumulativeDrainage: TVar;
    /// <summary>Uniform soil texture, pedotransfer table (RR/KA), and RR bulk density.</summary>
    SoilTexture, TextureVersion, SoilBulkDensity: TOption;
    /// <summary>Permitted water-content interval [cm3/cm3].</summary>
    MinTheta, MaxTheta: TPar;



    /// <summary>Copies a uniform hydraulic law (Ks in cm/d) and rebuilds its MFP table.
    /// Call again after changing soil parameters; caller retains ownership of ASoil.</summary>
    procedure ConfigureWaterUptakeSoil(ASoil: TGenucht);
    destructor Destroy; override;
    procedure createAll; override;
    /// <summary>Initializes shared geometry and roots, then texture hydraulics,
    /// the MFP table, root uptake diagnostics and water totals for each simulation.</summary>
    procedure Init(var GlobMod: TMod); override;
    /// <summary>Advances water through GlobTime.c days; the ADI solver rejects invalid steps atomically.</summary>
    procedure CalcRates; override;
    procedure Integrate; override;

  public
    function getWaterRasterData: TRasterDataH2O;

  end;

/// <summary>Registers the transport component on the Simulation palette.</summary>
procedure Register;

implementation

{$I trdiag.pas}


function TSubmodRoot2DH2O.getWaterRasterData: TRasterDataH2O;
begin
  Result := RasterDataH2O;
end;

constructor TRasterDataH2O.Create(AGeometry: TRasterData);
begin
  inherited Create;
  if AGeometry = nil then
    raise EArgumentException.Create('Water raster requires shared geometry');
  FGeometry := AGeometry;
end;

procedure TRasterDataH2O.Init(ATheta: double; ADepth: double);
var
  i, j: integer;
begin
  if IsNan(ADepth) or IsInfinite(ADepth) or (ADepth <= 0) then
    raise EArgumentException.Create('Layer depth must be finite and positive');
  FLayerDepth := ADepth;
  SetLength(Theta_xy, Geometry.NCols + 2, Geometry.NRows + 2);
  for i := 0 to Geometry.NCols + 1 do
    for j := 0 to Geometry.NRows + 1 do
      Theta_xy[i, j] := ATheta;
  CellWaterAmount := ATheta * Geometry.ColWidth * Geometry.RowHeight * FLayerDepth;
  FWaterBalanceError := 0;
  FLastDrainage := 0;
  FLastWaterUptake := 0;
end;

function TRasterDataH2O.GetCellWaterVolume(X, Y: integer): double;
begin
  if (X < 1) or (X > Geometry.NCols) or (Y < 1) or (Y > Geometry.NRows) then
    raise ERangeError.Create('Water volume requires an active grid cell');
  Result := Theta_xy[X,Y] * Geometry.ColWidth * Geometry.RowHeight * FLayerDepth;
end;

procedure TRasterDataH2O.SolveWaterDiffusionADI(ADtDays: double;
  ADiffusivity, AUptake: TWaterCellFunction; AMinTheta, AMaxTheta: double;
  AConductivity: TWaterCellFunction; AFreeDrainage: boolean);
var
  NX, NY, X, Y: integer;
  DX, DY, HalfDt, LeftRate, RightRate, BottomRate, TopRate: double;
  BeforeSum, AfterSum, UptakeSum, DrainageSum, Balance, CellVolume: double;
  OldTheta, HalfTheta, NewTheta, CellD, SinkRate, FaceDX, FaceDY: TWaterGrid;
  CellK, FaceKY: TWaterGrid;
  Lower, Diagonal, Upper, RHS: array_type;

  procedure RequireFinite(AValue: double; const AName: string);
  begin
    if IsNan(AValue) or IsInfinite(AValue) then
      raise EArgumentException.Create(AName + ' must be finite');
  end;

  procedure CheckTheta(AValue: double);
  begin
    RequireFinite(AValue, 'Water content');
    if (AValue < AMinTheta) or (AValue > AMaxTheta) then
      raise ERangeError.Create('Water content outside limits; reduce the water timestep');
  end;

  function HarmonicMean(A, B: double): double;
  begin
    if (A = 0) or (B = 0) then
      Exit(0);
    /// <summary>Preserve impermeable cells and avoid overflow in the product A*B.</summary>
    if A < B then
      Result := A * (2 / (1 + A / B))
    else
      Result := B * (2 / (1 + B / A));
  end;

  procedure Allocate(var Grid: TWaterGrid);
  begin
    SetLength(Grid, NX + 2, NY + 2);
  end;

  procedure SolveLine(Count: integer);
  var
    I: integer;
  begin
    for I := 1 to Count do
    begin
      RequireFinite(Diagonal[I], 'Water matrix diagonal');
      RequireFinite(RHS[I], 'Water right-hand side');
    end;
    if trdiag(false, Count, 1, Lower, Diagonal, Upper, RHS) <> 0 then
      raise EInvalidOp.Create('Water diffusion tridiagonal solve failed');
    for I := 1 to Count do
      CheckTheta(RHS[I]);
  end;

begin
  RequireFinite(ADtDays, 'Water timestep');
  RequireFinite(AMinTheta, 'Minimum water content');
  RequireFinite(AMaxTheta, 'Maximum water content');
  if (ADtDays < 0) or (AMinTheta < 0) or (AMaxTheta > 1) or
    (AMinTheta > AMaxTheta) then
    raise EArgumentException.Create('Invalid water timestep or water-content limits');
  if ADtDays = 0 then
    Exit;
  if AFreeDrainage and not Assigned(AConductivity) then
    raise EArgumentException.Create('Free drainage requires hydraulic conductivity');
  if not Assigned(ADiffusivity) then
    raise EArgumentException.Create('Water diffusivity callback is required');
  NX := Geometry.NCols;
  NY := Geometry.NRows;
  DX := Geometry.ColWidth;
  DY := Geometry.RowHeight;
  RequireFinite(DX, 'Cell width');
  RequireFinite(DY, 'Cell height');
  if (NX < 1) or (NY < 1) or (NX > dim_max) or (NY > dim_max) or
    (DX <= 0) or (DY <= 0) then
    raise EArgumentException.Create('Invalid computational geometry for water diffusion');
  if Length(Theta_xy) <> NX + 2 then
    raise EArgumentException.Create('Initialize the water field after changing geometry');
  for X := 0 to NX + 1 do
    if Length(Theta_xy[X]) <> NY + 2 then
      raise EArgumentException.Create('Water field dimensions do not match geometry');

  Allocate(OldTheta);
  Allocate(HalfTheta);
  Allocate(NewTheta);
  Allocate(CellD);
  Allocate(SinkRate);
  Allocate(FaceDX);
  Allocate(FaceDY);
  Allocate(CellK);
  Allocate(FaceKY);
  /// <summary>Deep copies: a rejected step must not alter the public dynamic arrays.</summary>
  for X := 0 to NX + 1 do
    for Y := 0 to NY + 1 do
    begin
      OldTheta[X, Y] := Theta_xy[X, Y];
      NewTheta[X, Y] := Theta_xy[X, Y];
    end;
  BeforeSum := 0;
  UptakeSum := 0;
  for X := 1 to NX do
    for Y := 1 to NY do
    begin
      CheckTheta(OldTheta[X, Y]);
      CellD[X, Y] := ADiffusivity(X, Y, OldTheta[X, Y]);
      RequireFinite(CellD[X, Y], 'Water diffusivity');
      if CellD[X, Y] < 0 then
        raise EArgumentException.Create('Water diffusivity must be nonnegative');
      if Assigned(AConductivity) then
        CellK[X, Y] := AConductivity(X, Y, OldTheta[X, Y]);
      RequireFinite(CellK[X, Y], 'Hydraulic conductivity');
      if CellK[X, Y] < 0 then
        raise EArgumentException.Create('Hydraulic conductivity must be nonnegative');
      if Assigned(AUptake) then
        SinkRate[X, Y] := AUptake(X, Y, OldTheta[X, Y]);
      RequireFinite(SinkRate[X, Y], 'Water uptake');
      if SinkRate[X, Y] < 0 then
        raise EArgumentException.Create('Water uptake must be nonnegative');
      BeforeSum := BeforeSum + OldTheta[X, Y];
      UptakeSum := UptakeSum + SinkRate[X, Y] * ADtDays;
    end;

  /// <summary>One value per shared face; untouched outer faces remain zero (no flow).</summary>
  for X := 1 to NX do
    for Y := 1 to NY do
    begin
      if X < NX then
        FaceDX[X, Y] := HarmonicMean(CellD[X, Y], CellD[X + 1, Y]);
      if Y < NY then
      begin
        FaceDY[X, Y] := HarmonicMean(CellD[X, Y], CellD[X, Y + 1]);
        FaceKY[X, Y] := HarmonicMean(CellK[X, Y], CellK[X, Y + 1]);
      end;
    end;
  /// <summary>Unit-gradient drainage: zero matric gradient and outward bottom flux Ku.</summary>
  DrainageSum := 0;
  if AFreeDrainage then
    for X := 1 to NX do
    begin
      FaceKY[X, NY] := CellK[X, NY];
      DrainageSum := DrainageSum + ADtDays * FaceKY[X, NY] / DY;
    end;
  HalfDt := ADtDays / 2;
  /// <summary>(I - dt/2 Lx) theta* = (I + dt/2 Ly) thetaOld + dt/2 (gravity divergence - uptake).</summary>
  for Y := 1 to NY do
  begin
    for X := 1 to NX do
    begin
      LeftRate := HalfDt * FaceDX[X - 1, Y] / Sqr(DX);
      RightRate := HalfDt * FaceDX[X, Y] / Sqr(DX);
      BottomRate := HalfDt * FaceDY[X, Y - 1] / Sqr(DY);
      TopRate := HalfDt * FaceDY[X, Y] / Sqr(DY);
      Lower[X] := -LeftRate;
      Diagonal[X] := 1 + LeftRate + RightRate;
      Upper[X] := -RightRate;
      RHS[X] := OldTheta[X, Y] - HalfDt * SinkRate[X, Y]
        + HalfDt * (FaceKY[X, Y - 1] - FaceKY[X, Y]) / DY;
      if Y > 1 then
        RHS[X] := RHS[X] + BottomRate * (OldTheta[X, Y - 1] - OldTheta[X, Y]);
      if Y < NY then
        RHS[X] := RHS[X] + TopRate * (OldTheta[X, Y + 1] - OldTheta[X, Y]);
    end;
    SolveLine(NX);
    for X := 1 to NX do
      HalfTheta[X, Y] := RHS[X];
  end;
  /// <summary>(I - dt/2 Ly) thetaNew = (I + dt/2 Lx) theta* + dt/2 (gravity divergence - uptake).</summary>
  for X := 1 to NX do
  begin
    for Y := 1 to NY do
    begin
      LeftRate := HalfDt * FaceDX[X - 1, Y] / Sqr(DX);
      RightRate := HalfDt * FaceDX[X, Y] / Sqr(DX);
      BottomRate := HalfDt * FaceDY[X, Y - 1] / Sqr(DY);
      TopRate := HalfDt * FaceDY[X, Y] / Sqr(DY);
      Lower[Y] := -BottomRate;
      Diagonal[Y] := 1 + BottomRate + TopRate;
      Upper[Y] := -TopRate;
      RHS[Y] := HalfTheta[X, Y] - HalfDt * SinkRate[X, Y]
        + HalfDt * (FaceKY[X, Y - 1] - FaceKY[X, Y]) / DY;
      if X > 1 then
        RHS[Y] := RHS[Y] + LeftRate * (HalfTheta[X - 1, Y] - HalfTheta[X, Y]);
      if X < NX then
        RHS[Y] := RHS[Y] + RightRate * (HalfTheta[X + 1, Y] - HalfTheta[X, Y]);
    end;
    SolveLine(NY);
    for Y := 1 to NY do
      NewTheta[X, Y] := RHS[Y];
  end;
  AfterSum := 0;
  for X := 1 to NX do
    for Y := 1 to NY do
      AfterSum := AfterSum + NewTheta[X, Y];
  CellVolume := DX * DY * FLayerDepth; // complete soil cell [cm3]
  Balance := (AfterSum - BeforeSum + UptakeSum + DrainageSum) * CellVolume;
  RequireFinite(Balance, 'Water balance');
  if Abs(Balance) > 1E-10 * Max(1.0, (BeforeSum + UptakeSum) * CellVolume) then
    raise EInvalidOp.Create('Water diffusion balance check failed');
  /// <summary>Commit only after both sweeps and the balance check succeeded.</summary>
  Theta_xy := NewTheta;
  CellWaterAmount := AfterSum / (double(NX) * NY) * CellVolume;
  FLastWaterUptake := UptakeSum * CellVolume;
  FLastDrainage := DrainageSum * CellVolume;
  FStorageChange := (AfterSum - BeforeSum) * CellVolume;
  FWaterBalanceError := Balance;
end;

procedure TSubmodRoot2DH2O.createAll;
begin
  inherited createAll;
  RasterDataH2O := TRasterDataH2O.Create(RasterData);
  SetEntityDeclarationClass(TSubmodRoot2DH2O);
  ParCreate('WaterDiffusionCoefficient', '[cm2/d]', 0,
    WaterDiffusionCoefficient, 'legacy constant diffusivity; unused by the texture-derived law');
  OptCreate('BottomBoundary', 'closed', BottomBoundary, 'closed bottom or unit-gradient free drainage in vertical mode');
  BottomBoundary.OptionList.CommaText := 'closed,freeDrainage';
  VarCreate('ActualDrainage', '[cm/d]', 0, false, ActualDrainage, 'mean bottom drainage rate');
  VarCreate('CumulativeDrainage', '[cm]', 0, false, CumulativeDrainage, 'bottom drainage since initialization');
  OptCreate('TransportPlane', 'horizontal', TransportPlane, 'horizontal plane or vertical plane with positive Y downward');
  TransportPlane.OptionList.CommaText := 'horizontal,vertical';
  OptCreate('SoilTexture', 'Sl3', SoilTexture, 'uniform soil texture for root water uptake');
  AddClasses(SoilTexture.OptionList);
  OptCreate('TextureVersion', 'RR', TextureVersion, 'hydraulic pedotransfer table');
  TextureVersion.OptionList.Add('RR');
  TextureVersion.OptionList.Add('KA');
  OptCreate('SoilBulkDensity', 'OldVersion', SoilBulkDensity, 'bulk density for RR conductivity');
  SoilBulkDensity.OptionList.CommaText := 'LD13,LD142,LD15,LD164,LD17,OldVersion';
  ParCreate('PotentialWaterUptake', '[cm/d]', 0, PotentialWaterUptake,
    'potential extraction per unit ground area');
  VarCreate('ActualWaterUptake', '[cm/d]', 0, false, ActualWaterUptake, 'mean extraction over the last outer interval');
  VarCreate('CumulativeWaterUptake', '[cm]', 0, false, CumulativeWaterUptake, 'extraction since initialization');
  VarCreate('WaterBalanceError', '[cm]', 0, false, WaterBalanceError, 'storage change plus extraction and drainage');
  ParCreate('MinTheta', '[cm3/cm3]', 0, MinTheta, 'minimum permitted water content');
  ParCreate('MaxTheta', '[cm3/cm3]', 1, MaxTheta, 'maximum permitted water content');
  ParCreate('MinWaterDt', '[d]', 1E-8, MinWaterDt, 'minimum internal water timestep');
  ParCreate('MaxThetaChange', '[cm3/cm3]', 0.005, MaxThetaChange, 'maximum water-content change per internal step');
  ParCreate('RootInfluxOutputInterval', '[d]', 1/24, RootInfluxOutputInterval, 'per-root influx averaging/output interval');
  OptCreate('WriteRootWaterInflux', 'no', WriteRootWaterInflux, 'write interval-average root water influx CSV');
  WriteRootWaterInflux.OptionList.CommaText := 'yes,no';
  OptCreate('RootWaterInfluxFile', 'root_water_influx.csv', RootWaterInfluxFile, 'CSV filename, relative to the model output directory');
  RootWaterInfluxFile.IsFileOutput := True;
  RootWaterInfluxFile.FileFilter := 'CSV files (*.csv)|*.csv|All files (*.*)|*.*';
  OptCreate('WaterUptakePattern', 'constant', WaterUptakePattern, 'constant or 16-hour sinusf daily water demand');
  WaterUptakePattern.OptionList.CommaText := 'constant,diurnal16h';
  OptCreate('AdaptiveWaterTimeStep', 'yes', AdaptiveWaterTimeStep, 'adapt internal water steps without changing the outer clock');
  AdaptiveWaterTimeStep.OptionList.CommaText := 'yes,no';
  VarCreate('WaterInternalSteps', '[]', 0, false, WaterInternalSteps, 'accepted steps in the last outer timestep');
  VarCreate('WaterRejectedSteps', '[]', 0, false, WaterRejectedSteps, 'rejected trials in the last outer timestep');
end;

procedure TSubmodRoot2DH2O.Init(var GlobMod: TMod);
var
  I: integer;
begin
  inherited Init(GlobMod);
  theta.v := IniTheta.v;
  WAmount.v := theta.v * Depth.v; // water depth [cm]
  RasterDataH2O.Init(theta.v, Depth.v);
  ActualWaterUptake.v := 0;
  CumulativeWaterUptake.v := 0;
  WaterBalanceError.v := 0;
  ActualDrainage.v := 0;
  CumulativeDrainage.v := 0;
  InitializeWaterUptakeSoil;
  FNextWaterDt := ini_dt.v;
  FWaterDemandFactor := 1;
  if (WaterUptakePattern.Option <> 'constant') and (WaterUptakePattern.Option <> 'diurnal16h') then
    raise EArgumentException.Create('Unknown WaterUptakePattern');
  FInfluxStarted := false;
  FInfluxStart := GlobMod.Time.v;
  FInfluxNext := FInfluxStart + RootInfluxOutputInterval.v;
  FInfluxEnd := GlobMod.EndTime;
  SetLength(FInfluxVolumes, 0);
  SetLength(FInfluxCumulative, 0);
  if WriteRootWaterInflux.Option = 'yes' then begin
    if IsNan(RootInfluxOutputInterval.v) or IsInfinite(RootInfluxOutputInterval.v) or
       (RootInfluxOutputInterval.v <= 0) or (FInfluxNext <= FInfluxStart) then
      raise EArgumentException.Create('RootInfluxOutputInterval must be a positive representable interval');
    FInfluxPath := RootWaterInfluxFile.Option;
    if Trim(FInfluxPath) = '' then raise EArgumentException.Create('RootWaterInfluxFile is empty');
    if (Trim(GlobMod.GM_OutPutPath) <> '') and
       not System.IOUtils.TPath.IsPathRooted(FInfluxPath) then
      FInfluxPath := IncludeTrailingPathDelimiter(GlobMod.GM_OutPutPath) + FInfluxPath;
    FInfluxPath := ExpandFileName(FInfluxPath);
  end;
  WaterInternalSteps.v := 0;
  WaterRejectedSteps.v := 0;
  for I := 0 to RootList.Count - 1 do
  begin
    TRootObjectIn2D(RootList.Objects[I]).WInflux := 0;
    TRootObjectIn2D(RootList.Objects[I]).SumWInflux := 0;
  end;
  int_dt.v := ini_dt.v;
  UpdateWaterTotals;
end;

function TSubmodRoot2DH2O.WaterDiffusivity(X, Y: integer; ATheta: double): double;
begin
  if FHydraulicSoil = nil then
    raise EInvalidOp.Create('Initialize the hydraulic soil before water diffusion');
  /// <summary>Ks is in cm/d, so Dw_f returns cm2/d. Use the solver-supplied state.</summary>
  Result := FHydraulicSoil.Dw_f(ATheta);
end;

function TSubmodRoot2DH2O.GravityConductivity(X, Y: integer; ATheta: double): double;
begin
  if SameText(TransportPlane.Option, 'horizontal') then Exit(0);
  if not SameText(TransportPlane.Option, 'vertical') then
    raise EArgumentException.Create('Unknown transport plane');
  if FHydraulicSoil = nil then
    raise EInvalidOp.Create('Initialize hydraulic soil before gravity transport');
  Result := FHydraulicSoil.Ku_b_f(ATheta);
end;
procedure TSubmodRoot2DH2O.InitializeWaterUptakeSoil;
var
  Texture: TTextureClass;
  Density: TLD;
  Soil: TGenucht;
begin
  if SoilTexture.OptionList.IndexOf(SoilTexture.Option) < 0 then
    raise EArgumentException.Create('Unknown soil texture for root water uptake');
  if SoilBulkDensity.OptionList.IndexOf(SoilBulkDensity.Option) < 0 then
    raise EArgumentException.Create('Unknown bulk density for root water uptake');
  Texture := Sl3;
  Density := OldVersion;
  setTextClassOption(Texture, SoilTexture.Option);
  setLDOption(Density, SoilBulkDensity.Option);
  Soil := TGenucht.Create;
  try
    if SameText(TextureVersion.Option, 'RR') then
    begin
      VanGenuchtenFromTextureClass_RR(Soil, Texture);
      Soil.Ks := KSFromTextureClass_RR(Texture, Density);
    end
    else if SameText(TextureVersion.Option, 'KA') then
    begin
      VanGenuchtenFromTextureClass_KA(Soil, Texture);
      Soil.Ks := KSFromTextureClass_KA(Texture);
    end
    else
      raise EArgumentException.Create('Unknown hydraulic texture table');
    /// <summary>Use the Mualem relation, as in the default 1-D water model.</summary>
    if Soil.n_par <= 1 then
      raise EArgumentException.Create('Texture table requires n greater than one');
    Soil.m_par := 1 - 1 / Soil.n_par;
    ConfigureWaterUptakeSoil(Soil);
  finally
    Soil.Free;
  end;
end;

procedure TSubmodRoot2DH2O.ConfigureWaterUptakeSoil(ASoil: TGenucht);
var
  Soil: TGenucht;
  Table: TMFP_table;

  procedure CheckFinite(Value: double);
  begin
    if IsNan(Value) or IsInfinite(Value) then
      raise EArgumentException.Create('Hydraulic parameters must be finite');
  end;

begin
  if ASoil = nil then
    raise EArgumentException.Create('Root water uptake requires a soil');
  CheckFinite(ASoil.b_rest);
  CheckFinite(ASoil.b_sat);
  CheckFinite(ASoil.Ks);
  CheckFinite(ASoil.alpha);
  CheckFinite(ASoil.n_par);
  CheckFinite(ASoil.m_par);
  CheckFinite(ASoil.l_par);
  if (ASoil.b_rest < 0) or (ASoil.b_sat > 1) or
     (ASoil.b_sat <= ASoil.b_rest) or (ASoil.Ks < 0) or
     (ASoil.alpha <= 0) or (ASoil.n_par <= 1) or
     (ASoil.m_par <= 0) or (ASoil.m_par > 1) then
    raise EArgumentException.Create('Invalid root water uptake hydraulic parameters');
  Soil := TGenucht.Create;
  try
    Soil.b_rest := ASoil.b_rest;
    Soil.b_sat := ASoil.b_sat;
    Soil.Ks := ASoil.Ks;
    Soil.alpha := ASoil.alpha;
    Soil.n_par := ASoil.n_par;
    Soil.m_par := ASoil.m_par;
    Soil.l_par := ASoil.l_par;
    Table := TMFP_table.Create(Soil);
  except
    Soil.Free;
    raise;
  end;
  FMFPTable.Free;
  FHydraulicSoil.Free;
  FMFPTable := Table;
  FHydraulicSoil := Soil;
end;

destructor TSubmodRoot2DH2O.Destroy;
begin
  RasterDataH2O.Free;
  FMFPTable.Free;
  FHydraulicSoil.Free;
  inherited Destroy;
end;

function TSubmodRoot2DH2O.PotentialRootWaterInflux(ARootIndex: integer): double;
begin
  Result := PotentialWaterUptake.v * Area.v * FWaterDemandFactor / RootList.Count / Depth.v / 86400;
end;

function TSubmodRoot2DH2O.DiurnalDemandFactor(StartDay, StepDays: double): double;
var Hour, MidValue, Amplitude, HalfAngle, Sinc, DailyMean: double;
begin
  Hour := 24 * ((StartDay + StepDays*0.5) - Floor(StartDay + StepDays*0.5));
  if (Hour <= 4) or (Hour >= 20) then Exit(0);
  /// <summary>sinusf has a constant offset plus a sinusoid in daylight. Integrating
  /// the sinusoidal part gives sinc(pi*StepDays) times its midpoint value.</summary>
  MidValue := sinusf(Hour);
  Amplitude := sinusf(12)/1.5;
  HalfAngle := Pi*StepDays;
  Sinc := 1;
  if Abs(HalfAngle) > 1E-8 then Sinc := Sin(HalfAngle)/HalfAngle;
  /// <summary>Remove rounding in the legacy amplitude so the full-day mean is one.</summary>
  DailyMean := Amplitude * (8 + 12*Sqrt(3)/Pi) / 24;
  Result := Max(0, (Amplitude*0.5 + (MidValue-Amplitude*0.5)*Sinc)/DailyMean);
end;

procedure TSubmodRoot2DH2O.PrepareRootWaterUptake;
var
  Counts: array of array of integer;
  Limits: TWaterGrid;
  I, X, Y: integer;
  Root: TRootObjectIn2D;
  CellArea, XL, Psi, MFP, Demand, Influx: double;

  procedure RequirePositive(Value: double; const Name: string);
  begin
    if IsNan(Value) or IsInfinite(Value) or (Value <= 0) then
      raise EArgumentException.Create(Name + ' must be finite and positive');
  end;

begin
  if IsNan(PotentialWaterUptake.v) or IsInfinite(PotentialWaterUptake.v) or
     (PotentialWaterUptake.v < 0) then
    raise EArgumentException.Create('Potential water uptake must be finite and nonnegative');
  
  // Initialize the root water sink and related arrays
  SetLength(FRootWaterSink, RasterData.NCols + 1, RasterData.NRows + 1);
  SetLength(Counts, RasterData.NCols + 1, RasterData.NRows + 1);
  SetLength(Limits, RasterData.NCols + 1, RasterData.NRows + 1);
  SetLength(FPendingRootInflux, RootList.Count);
  
  // set all counts and sinks to zero
  for X := 1 to RasterData.NCols do
    for Y := 1 to RasterData.NRows do
      FRootWaterSink[X, Y] := 0;
  for I := 0 to RootList.Count - 1 do
    FPendingRootInflux[I] := 0;
  if (RootList.Count = 0) or (PotentialWaterUptake.v = 0) then
    Exit;
  if FMFPTable = nil then
    raise EInvalidOp.Create('ConfigureWaterUptakeSoil must precede positive root water uptake');
  RequirePositive(Depth.v, 'Layer depth');
  RequirePositive(RootRadius.v, 'Root radius');
  RequirePositive(RasterData.ColWidth, 'Cell width');
  RequirePositive(RasterData.RowHeight, 'Cell height');
  CellArea := RasterData.ColWidth * RasterData.RowHeight;
  for I := 0 to RootList.Count - 1 do
  begin
    Root := TRootObjectIn2D(RootList.Objects[I]);
    if (Root.xi < 1) or (Root.xi > RasterData.NCols) or
       (Root.yi < 1) or (Root.yi > RasterData.NRows) then
      raise ERangeError.Create('Water uptake root lies outside active grid');
    Inc(Counts[Root.xi, Root.yi]);
  end;
  for X := 1 to RasterData.NCols do
    for Y := 1 to RasterData.NRows do
      if Counts[X, Y] > 0 then
      begin
        /// <summary>Each root uses the full cell area for its radial transport limit.</summary>
        XL := Sqrt(CellArea / Pi);
        if 0.56 * XL <= RootRadius.v then
          raise EArgumentException.Create('Cell soil cylinder is too small for radial MFP uptake');
        /// <summary>The existing table spans positive tensions 0.1..10^4.2 cm.
        /// Clamp the wet endpoint; beyond its dry endpoint no transport is available.</summary>
        Psi := FHydraulicSoil.psi_b_f(RasterDataH2O.Theta_xy[X, Y]);
        if IsNan(Psi) or IsInfinite(Psi) then
          raise EInvalidOp.Create('Nonfinite soil water tension');
        MFP := 0;
        if Psi < Power(10, 4.2) then
          MFP := Max(0, FMFPTable.get_sumku(Max(0.1, Psi)));
        Limits[X, Y] := MFP_IWmax(MFP, XL, RootRadius.v) / 86400;
        if IsNan(Limits[X, Y]) or IsInfinite(Limits[X, Y]) or (Limits[X, Y] < 0) then
          raise EInvalidOp.Create('Invalid radial MFP water influx');
      end;
  for I := 0 to RootList.Count - 1 do
  begin
    Root := TRootObjectIn2D(RootList.Objects[I]);
    Demand := PotentialRootWaterInflux(I);
    if IsNan(Demand) or IsInfinite(Demand) or (Demand < 0) then
      raise EArgumentException.Create('Root water demand must be finite and nonnegative');
    Influx := Min(Demand, Limits[Root.xi, Root.yi]);
    FPendingRootInflux[I] := Influx;
    /// <summary>Root length and cell volume both contain Depth, which cancels.</summary>
    FRootWaterSink[Root.xi, Root.yi] := FRootWaterSink[Root.xi, Root.yi] +
      Influx * 86400 / CellArea;
  end;
end;

function TSubmodRoot2DH2O.WaterUptake(X, Y: integer; ATheta: double): double;
begin
  Result := FRootWaterSink[X, Y];
end;

procedure TSubmodRoot2DH2O.UpdateWaterTotals;
var
  X, Y: integer;
  TotalTheta: double;
begin
  TotalTheta := 0;
  for X := 1 to RasterData.NCols do
    for Y := 1 to RasterData.NRows do
      TotalTheta := TotalTheta + RasterDataH2O.Theta_xy[X, Y];
  theta.v := TotalTheta / (RasterData.NCols * RasterData.NRows);
  /// <summary>Retain the base model's water-depth convention [cm] for WAmount.</summary>
  WAmount.v := theta.v * Depth.v;
  WAmount.c := 0;
end;

/// <summary>Append only after the outer solve succeeds. A new simulation replaces
/// the previous file on its first completed interval, not during UI initialization.</summary>
procedure TSubmodRoot2DH2O.AppendInfluxOutput(Lines: TStrings);
var Stream: TFileStream; Bytes: TBytes; OldSize: Int64; Text: string;
begin
  if Lines.Count = 0 then Exit;
  ForceDirectories(ExtractFilePath(FInfluxPath));
  Text := Lines.Text;
  if not FInfluxStarted then
    Text := 'start_day,end_day,root_index,root_id,x_cm,y_cm,mean_influx_cm3_cm_s,uptake_cm3,cumulative_uptake_cm3'+sLineBreak+Text;
  Bytes := TEncoding.UTF8.GetBytes(Text);
  if FInfluxStarted then Stream := TFileStream.Create(FInfluxPath, fmOpenReadWrite or fmShareDenyWrite)
  else Stream := TFileStream.Create(FInfluxPath, fmCreate);
  try
    OldSize := Stream.Size;
    Stream.Position := OldSize;
    try Stream.WriteBuffer(Bytes[0], Length(Bytes));
    except Stream.Size := OldSize; raise; end;
  finally Stream.Free; end;
  FInfluxStarted := true;
end;

procedure TSubmodRoot2DH2O.CalcRates;
var
  I, X, Y, Accepted, Rejected: integer;
  Root: TRootObjectIn2D;
  Initial, Before: TWaterGrid;
  RootVolumes: array of double;
  Duration, Elapsed, Dt, NextDt, LowerDt, Change, TotalUptake, TotalBalance, TotalDrainage, OldDrainage: double;
  OldUptake, OldBalance, OldCell, OldStorageChange, InitialSum, FinalSum: double;
  Adaptive, Retry, OutputEnabled, Diurnal: boolean;
  StepStart, NextHour: double;
  OutputLines: TStringList;
  OutputVolumes, OutputCumulative: TArray<double>;
  OutputStart, OutputNext: double;
  FS: TFormatSettings;

  procedure EmitInterval(EndDay: double);
  var J: integer; R: TRootObjectIn2D; Seconds: double;
  begin
    Seconds := (EndDay-OutputStart)*86400;
    if Seconds <= 0 then Exit;
    for J := 0 to RootList.Count-1 do begin
      R := TRootObjectIn2D(RootList.Objects[J]);
      OutputLines.Add(FloatToStr(OutputStart,FS)+','+FloatToStr(EndDay,FS)+','+
        IntToStr(J+1)+','+IntToStr(R.nroot)+','+FloatToStr(R.x,FS)+','+FloatToStr(R.y,FS)+','+
        FloatToStr(OutputVolumes[J]/Seconds,FS)+','+FloatToStr(OutputVolumes[J]*Depth.v,FS)+','+
        FloatToStr(OutputCumulative[J]*Depth.v,FS));
      OutputVolumes[J] := 0;
    end;
    OutputStart := EndDay;
  end;

  /// <summary>Partition accepted uptake at reporting boundaries without changing solver steps.</summary>
  procedure AccumulateOutput(StartDay, StepDays: double);
  var Cursor, Finish, SegmentEnd, Segment: double; J: integer;
  begin
    Cursor := StartDay;
    Finish := StartDay + StepDays;
    while Cursor < Finish do begin
      SegmentEnd := Min(Finish, OutputNext);
      Segment := SegmentEnd-Cursor;
      if Segment <= 0 then raise EInvalidOp.Create('Root influx output clock is not increasing');
      for J := 0 to RootList.Count-1 do begin
        OutputVolumes[J] := OutputVolumes[J] + FPendingRootInflux[J]*Segment*86400;
        OutputCumulative[J] := OutputCumulative[J] + FPendingRootInflux[J]*Segment*86400;
      end;
      Cursor := SegmentEnd;
      if Cursor >= OutputNext then begin
        EmitInterval(OutputNext);
        OutputNext := OutputNext + RootInfluxOutputInterval.v;
      end;
    end;
  end;

  procedure Positive(V: double; const Name: string);
  begin
    if IsNan(V) or IsInfinite(V) or (V <= 0) then
      raise EArgumentException.Create(Name + ' must be finite and positive');
  end;
begin
  if not Assigned(GlobTime) then
    raise Exception.Create('Water transport requires an initialized model clock');
  if not SameText(BottomBoundary.Option, 'closed') and
    not SameText(BottomBoundary.Option, 'freedrainage') then
    raise EArgumentException.Create('Unknown bottom boundary');
  if SameText(BottomBoundary.Option, 'freedrainage') and
    not SameText(TransportPlane.Option, 'vertical') then
    raise EArgumentException.Create('Free drainage requires TransportPlane=vertical');
  Duration := GlobTime.c;
  if Duration = 0 then begin ActualWaterUptake.v := 0; ActualDrainage.v := 0; Exit; end;
  Positive(Duration, 'Outer water timestep');
  Adaptive := AdaptiveWaterTimeStep.Option = 'yes';
  Diurnal := WaterUptakePattern.Option = 'diurnal16h';
  if Adaptive then begin
    Positive(MinWaterDt.v, 'MinWaterDt');
    Positive(max_dt.v, 'max_dt');
    Positive(ini_dt.v, 'Ini_dt');
    Positive(MaxThetaChange.v, 'MaxThetaChange');
    if MinWaterDt.v > max_dt.v then
      raise EArgumentException.Create('MinWaterDt must not exceed max_dt');
  end;
  InitialSum := 0;
  for X := 1 to RasterData.NCols do for Y := 1 to RasterData.NRows do begin
    Change := RasterDataH2O.Theta_xy[X,Y];
    if IsNan(Change) or IsInfinite(Change) or (Change < MinTheta.v) or (Change > MaxTheta.v) then
      raise ERangeError.Create('Initial water content outside limits');
    InitialSum := InitialSum + Change;
  end;
  /// <summary>The raster solver commits a newly allocated grid, so retained array
  /// references are immutable snapshots for retry and full-step rollback.</summary>
  Initial := RasterDataH2O.Theta_xy;
  OldUptake := RasterDataH2O.FLastWaterUptake;
  OldBalance := RasterDataH2O.FWaterBalanceError;
  OldDrainage := RasterDataH2O.FLastDrainage;
  OldCell := RasterDataH2O.CellWaterAmount;
  OldStorageChange := RasterDataH2O.FStorageChange;
  SetLength(RootVolumes, RootList.Count);
  Elapsed := 0; TotalUptake := 0; TotalBalance := 0; TotalDrainage := 0;
  Accepted := 0; Rejected := 0; Dt := 0;
  NextDt := FNextWaterDt;
  if NextDt <= 0 then NextDt := ini_dt.v;
  if not Adaptive then NextDt := Duration;
  OutputEnabled := WriteRootWaterInflux.Option = 'yes';
  OutputLines := TStringList.Create;
  try
  OutputStart := FInfluxStart;
  OutputNext := FInfluxNext;
  FS := TFormatSettings.Create; FS.DecimalSeparator := '.';
  if OutputEnabled then begin
    if (Length(FInfluxVolumes) <> 0) and (Length(FInfluxVolumes) <> RootList.Count) then
      raise EInvalidOp.Create('Root set changed during influx reporting; reinitialize the simulation');
    OutputVolumes := Copy(FInfluxVolumes);
    OutputCumulative := Copy(FInfluxCumulative);
    SetLength(OutputVolumes, RootList.Count);
    SetLength(OutputCumulative, RootList.Count);
  end;
  try
    while Elapsed < Duration do begin
      if Adaptive then Dt := Min(Duration-Elapsed, Max(MinWaterDt.v, Min(max_dt.v, NextDt)))
      else Dt := Duration-Elapsed;
      StepStart := GlobTime.v+Elapsed;
      if Diurnal then begin
        /// <summary>Resolve daylight/night and hourly reporting even with a daily outer step.</summary>
        NextHour := (Floor(StepStart*24)+1)/24;
        if NextHour-StepStart < 1E-12 then NextHour := NextHour+1/24;
        Dt := Min(Dt, NextHour-StepStart);
      end;
      LowerDt := Min(MinWaterDt.v, Dt);
      Before := RasterDataH2O.Theta_xy;
      repeat
        FWaterDemandFactor := 1;
        if Diurnal then FWaterDemandFactor := DiurnalDemandFactor(StepStart, Dt);
        PrepareRootWaterUptake;
        Retry := false;
        try
          RasterDataH2O.SolveWaterDiffusionADI(Dt, WaterDiffusivity, WaterUptake, MinTheta.v, MaxTheta.v, GravityConductivity, SameText(BottomBoundary.Option, 'freedrainage'));
        except
          on E: ERangeError do begin
            if not Adaptive then raise;
            Retry := true;
          end;
        end;
        Change := 0;
        if not Retry then
          for X := 1 to RasterData.NCols do for Y := 1 to RasterData.NRows do
            Change := Max(Change, Abs(RasterDataH2O.Theta_xy[X,Y]-Before[X,Y]));
        if Adaptive and (Change > MaxThetaChange.v) then Retry := true;
        if Retry then begin
          RasterDataH2O.Theta_xy := Before;
          Inc(Rejected);
          if Dt <= LowerDt*(1+1E-12) then
            raise ERangeError.Create('Water step cannot meet bounds/change limit at MinWaterDt');
          Dt := Max(LowerDt, Dt*0.5);
        end;
      until not Retry;
      if OutputEnabled then AccumulateOutput(GlobTime.v+Elapsed, Dt);
      Inc(Accepted);
      TotalUptake := TotalUptake + RasterDataH2O.LastWaterUptake;
      TotalBalance := TotalBalance + RasterDataH2O.WaterBalanceError;
      TotalDrainage := TotalDrainage + RasterDataH2O.LastDrainage;
      for I := 0 to RootList.Count-1 do
        RootVolumes[I] := RootVolumes[I] + FPendingRootInflux[I]*Dt*86400;
      if Dt >= Duration-Elapsed then Elapsed := Duration
      else Elapsed := Elapsed + Dt;
      /// <summary>Avoid a non-advancing floating-point remainder at the outer endpoint.</summary>
      if Duration-Elapsed <= 1E-12*Duration then Elapsed := Duration;
      if Adaptive then begin
        NextDt := Dt*1.5;
        if Change > 0 then NextDt := Min(NextDt, Dt*MaxThetaChange.v/Change);
        NextDt := Max(MinWaterDt.v, Min(max_dt.v, NextDt));
      end;
    end;
    if OutputEnabled then begin
      if (GlobTime.v+Duration >= FInfluxEnd-1E-12) and
         (GlobTime.v+Duration > OutputStart+1E-12) then
        EmitInterval(GlobTime.v+Duration);
      AppendInfluxOutput(OutputLines);
    end;
  except
    RasterDataH2O.Theta_xy := Initial;
    RasterDataH2O.FLastWaterUptake := OldUptake;
    RasterDataH2O.FWaterBalanceError := OldBalance;
    RasterDataH2O.FLastDrainage := OldDrainage;
    RasterDataH2O.CellWaterAmount := OldCell;
    RasterDataH2O.FStorageChange := OldStorageChange;
    raise;
  end;
  /// <summary>Publish only after the complete outer interval succeeds.</summary>
  RasterDataH2O.FLastWaterUptake := TotalUptake;
  RasterDataH2O.FWaterBalanceError := TotalBalance;
  RasterDataH2O.FLastDrainage := TotalDrainage;
  ActualDrainage.v := TotalDrainage / (Area.v * Duration);
  CumulativeDrainage.v := CumulativeDrainage.v + TotalDrainage / Area.v;
  FinalSum := 0;
  for X := 1 to RasterData.NCols do for Y := 1 to RasterData.NRows do
    FinalSum := FinalSum + RasterDataH2O.Theta_xy[X,Y];
  RasterDataH2O.FStorageChange := (FinalSum-InitialSum)*RasterData.ColWidth*RasterData.RowHeight*RasterDataH2O.LayerDepth;
  ActualWaterUptake.v := TotalUptake / (Area.v * Duration);
  CumulativeWaterUptake.v := CumulativeWaterUptake.v + TotalUptake / Area.v;
  WaterBalanceError.v := TotalBalance / Area.v;
  for I := 0 to RootList.Count-1 do begin
    Root := TRootObjectIn2D(RootList.Objects[I]);
    Root.WInflux := RootVolumes[I]/(Duration*86400);
    Root.SumWInflux := Root.SumWInflux + RootVolumes[I];
  end;
  if OutputEnabled then begin
    FInfluxVolumes := OutputVolumes;
    FInfluxCumulative := OutputCumulative;
    FInfluxStart := OutputStart;
    FInfluxNext := OutputNext;
  end;
  FNextWaterDt := NextDt;
  int_dt.v := Dt;
  WaterInternalSteps.v := Accepted;
  WaterRejectedSteps.v := Rejected;
  UpdateWaterTotals;
  finally
    FWaterDemandFactor := 1;
    OutputLines.Free;
  end;
end;

procedure TSubmodRoot2DH2O.Integrate;
begin
  inherited Integrate;
  /// <summary>The field solver has already advanced water; do not integrate storage twice.</summary>
  UpdateWaterTotals;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
{$IFNDEF CONSOLE}
  RegisterComponents('Simulation', [TSubmodRoot2DH2O]);
{$ENDIF}
{$ENDIF}
end;

end.
