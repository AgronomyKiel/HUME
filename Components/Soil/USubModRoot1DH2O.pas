/// <summary>Independent root cylinders with quasi-steady radial MFP transport.</summary>
unit USubModRoot1DH2O;

interface

uses System.SysUtils, System.Classes, System.Math, UMod, UState,
  U2DSoilBaseClasses, UGenucht, WFlowFunctions, USoilTexture;

type
  /// <summary>One representative cylinder; influx is per cm root per second.</summary>
  TWaterRootCylinder = record
    RLD, Radius, VolumeFraction, Theta, Influx: double;
  end;
  TWaterRootCylinders = array of TWaterRootCylinder;

  /// <summary>Water uptake in one uniform RLD class or ten equal-volume lognormal RLD classes.
  /// Each root spans Depth; ContRad defines the total represented circular domain.
  /// Cylinders have no external water supply and exchange no water with other classes.</summary>
  TSubmodRoot1DH2O = class(TSubmodRootBase)
  private
    FHydraulicSoil: TGenucht;
    FMFPTable: TMFP_table;
    FCylinders: TWaterRootCylinders;
    FRootGeometrySource: TSubmodRoot2D;
    procedure SetRootGeometrySource(Value: TSubmodRoot2D);
    procedure InitializeWaterUptakeSoil;
    procedure UpdateTotals;
    function DiurnalDemandFactor(StartDay, StepDays: double): double;
    function GetCylinder(Index: integer): TWaterRootCylinder;
    function GetCylinderCount: integer;
  protected
{$IFNDEF NONVISUAL}
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
{$ENDIF}
  public
    /// <summary>Maximum internal integration interval [hours], default 0.5.</summary>
    IntegrationInterval: TPar;
    /// <summary>Coefficient of variation of lognormal RLD [%].</summary>
    ParCV: TPar;
    /// <summary>Potential extraction per unit ground area [cm/d].</summary>
    PotentialWaterUptake: TPar;
    MinTheta, MaxTheta: TPar;
    /// <summary>single or lognormal; fixed demand capped by transport, or maximum transport.</summary>
    RootDistribution, WaterUptakeMode: TOption;
    /// <summary>Constant or normalized 04:00..20:00 demand in fixed uptake mode.</summary>
    WaterUptakePattern: TOption;
    SoilTexture, TextureVersion, SoilBulkDensity: TOption;
    ActualWaterUptake, CumulativeWaterUptake, WaterBalanceError: TVar;
    /// <summary>Selectable cylinder outputs; indices 0..9 are registered as classes 1..10.</summary>
    ClassRLD, ClassTheta, ClassInflux: array[0..9] of TVar;
    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    /// <summary>Advance through GlobTime.c days, splitting at IntegrationInterval.
    /// Commits only after the complete interval succeeds; Integrate must not repeat uptake.</summary>
    procedure CalcRates; override;
    procedure Integrate; override;
    destructor Destroy; override;
    /// <summary>Copy a hydraulic law with Ks in cm/d and rebuild the MFP table.</summary>
    procedure ConfigureWaterUptakeSoil(ASoil: TGenucht);
    /// <summary>Optional 2-D source initialized before this model. Its whole-domain,
    /// area-weighted RLD moments override ParMRLD and ParCV; RootDistribution still selects one or ten classes.</summary>
    property RootGeometrySource: TSubmodRoot2D read FRootGeometrySource write SetRootGeometrySource;
    property CylinderCount: integer read GetCylinderCount;
    property Cylinders[Index: integer]: TWaterRootCylinder read GetCylinder;
  end;

procedure Register;

implementation

procedure TSubmodRoot1DH2O.SetRootGeometrySource(Value: TSubmodRoot2D);
begin
  if FRootGeometrySource = Value then Exit;
{$IFNDEF NONVISUAL}
  if Assigned(FRootGeometrySource) then FRootGeometrySource.RemoveFreeNotification(Self);
{$ENDIF}
  FRootGeometrySource := Value;
{$IFNDEF NONVISUAL}
  if Assigned(FRootGeometrySource) then FRootGeometrySource.FreeNotification(Self);
{$ENDIF}
end;

{$IFNDEF NONVISUAL}
procedure TSubmodRoot1DH2O.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FRootGeometrySource) then
    FRootGeometrySource := nil;
end;
{$ENDIF}

procedure RequireFinite(Value: double; const Name: string);
begin
  if IsNan(Value) or IsInfinite(Value) then
    raise EArgumentException.Create(Name + ' must be finite');
end;

procedure TSubmodRoot1DH2O.CreateAll;
var I: integer;
begin
  inherited;
  SetEntityDeclarationClass(TSubmodRoot1DH2O);
  ParCreate('IntegrationInterval', '[h]', 0.5, IntegrationInterval, 'maximum internal integration interval');
  ParCreate('ParCV', '[%]', 0, ParCV, 'coefficient of variation of lognormal root length density');
  ParCreate('PotentialWaterUptake', '[cm/d]', 0, PotentialWaterUptake, 'potential extraction per unit ground area');
  ParCreate('MinTheta', '[cm3/cm3]', 0, MinTheta, 'minimum water content');
  ParCreate('MaxTheta', '[cm3/cm3]', 1, MaxTheta, 'maximum water content');
  OptCreate('RootDistribution', 'single', RootDistribution, 'single cylinder class or ten lognormal RLD classes');
  RootDistribution.OptionList.CommaText := 'single,lognormal';
  OptCreate('WaterUptakeMode', 'fixed', WaterUptakeMode, 'fixed demand capped by MFP transport, or maximum MFP transport');
  WaterUptakeMode.OptionList.CommaText := 'fixed,maximum';
  OptCreate('WaterUptakePattern', 'constant', WaterUptakePattern, 'constant or 16-hour sinusf daily demand in fixed uptake mode');
  WaterUptakePattern.OptionList.CommaText := 'constant,diurnal16h';
  OptCreate('SoilTexture', 'Sl3', SoilTexture, 'uniform soil texture');
  AddClasses(SoilTexture.OptionList);
  OptCreate('TextureVersion', 'RR', TextureVersion, 'hydraulic pedotransfer table');
  TextureVersion.OptionList.CommaText := 'RR,KA';
  OptCreate('SoilBulkDensity', 'OldVersion', SoilBulkDensity, 'RR bulk density');
  SoilBulkDensity.OptionList.CommaText := 'LD13,LD142,LD15,LD164,LD17,OldVersion';
  VarCreate('ActualWaterUptake', '[cm/d]', 0, false, ActualWaterUptake, 'mean uptake over the last model interval');
  VarCreate('CumulativeWaterUptake', '[cm]', 0, false, CumulativeWaterUptake, 'water removed since initialization');
  VarCreate('WaterBalanceError', '[cm]', 0, false, WaterBalanceError, 'storage change plus uptake');
  for I := 0 to 9 do
  begin
    VarCreate(Format('ClassRLD_%d', [I+1]), '[cm/cm3]', 0, false, ClassRLD[I], 'class root length density');
    VarCreate(Format('ClassTheta_%d', [I+1]), '[cm3/cm3]', 0, false, ClassTheta[I], 'class mean water content');
    VarCreate(Format('ClassInflux_%d', [I+1]), '[cm3/cm/s]', 0, false, ClassInflux[I], 'interval mean influx per cm root');
  end;
end;

procedure TSubmodRoot1DH2O.Init(var GlobMod: TMod);
const
  Z: array[0..9] of double = (-1.64485362695147, -1.03643338949379,
    -0.674489750196082, -0.385320466407568, -0.125661346855074,
    0.125661346855074, 0.385320466407568, 0.674489750196082,
    1.03643338949379, 1.64485362695147);
var I, N, SourceIndex, ModelIndex: integer; Sigma, Mean, LowerTheta: double;
begin
  initialised := false;
  inherited;
  if Assigned(FRootGeometrySource) then begin
    if Assigned(GlobMod) then begin
      SourceIndex := GlobMod.SubModStrList.IndexOfObject(FRootGeometrySource);
      ModelIndex := GlobMod.SubModStrList.IndexOfObject(Self);
      if (SourceIndex >= 0) and (ModelIndex >= 0) and (SourceIndex >= ModelIndex) then
        raise EInvalidOp.Create('Initialize the root geometry source before the 1-D PDF model');
    end;
    if (FRootGeometrySource.RootList.Count = 0) or
       (Length(FRootGeometrySource.VoronoiCells) <> FRootGeometrySource.RootList.Count) or
       (FRootGeometrySource.VoronoiAreaMeanRLD.v <= 0) then
      raise EInvalidOp.Create('The 1-D PDF source requires initialized Voronoi cells');
    ParMRLD.v := FRootGeometrySource.VoronoiAreaMeanRLD.v;
    ParCV.v := 100 * FRootGeometrySource.VoronoiAreaRLDCV.v;
    /// <summary>Keep the INI-selected single/lognormal mode when borrowing geometry moments.</summary>
  end;
  RequireFinite(ParMRLD.v, 'ParMRLD');
  RequireFinite(ParCV.v, 'ParCV');
  RequireFinite(Depth.v, 'Depth');
  RequireFinite(ContRad.v, 'ContRad');
  RequireFinite(RootRadius.v, 'RootRadius');
  RequireFinite(IniTheta.v, 'IniTheta');
  RequireFinite(MinTheta.v, 'MinTheta');
  RequireFinite(MaxTheta.v, 'MaxTheta');
  RequireFinite(IntegrationInterval.v, 'IntegrationInterval');
  if (ParMRLD.v <= 0)  or (Depth.v <= 0) or // or (ParCV.v < 0)
    (ContRad.v <= 0) or (RootRadius.v <= 0) or (IntegrationInterval.v <= 0) or
    (MinTheta.v < 0) or (MaxTheta.v > 1) or (MinTheta.v > MaxTheta.v) then
    raise EArgumentException.Create('Invalid root cylinder geometry or water parameters');
  N := 1;
  if SameText(RootDistribution.Option, 'lognormal') then N := 10
  else if not SameText(RootDistribution.Option, 'single') then
    raise EArgumentException.Create('Unknown root cylinder distribution');
  InitializeWaterUptakeSoil;
  LowerTheta := Max(MinTheta.v, FHydraulicSoil.b_rest);
  if (IniTheta.v < LowerTheta) or (IniTheta.v > Min(MaxTheta.v, FHydraulicSoil.b_sat)) then
    raise EArgumentException.Create('Initial water content outside hydraulic limits');
  SetLength(FCylinders, N);
  Sigma := Sqrt(Ln(1 + Sqr(ParCV.v / 100)));
  Mean := 0;
  for I := 0 to N-1 do
  begin
    FCylinders[I].RLD := 1;
    if N = 10 then FCylinders[I].RLD := Exp(Sigma * Z[I]);
    Mean := Mean + FCylinders[I].RLD / N;
  end;
  for I := 0 to N-1 do
    with FCylinders[I] do
    begin
      /// <summary>Normalize midpoint quadrature to conserve prescribed mean RLD.</summary>
      RLD := ParMRLD.v * RLD / Mean;
      Radius := Sqrt(1 / (Pi * RLD));
      RequireFinite(Radius, 'Cylinder radius');
      if 0.56 * Radius <= RootRadius.v then
        raise EArgumentException.Create('Root cylinder too small for radial MFP solution');
      VolumeFraction := 1 / N;
      Theta := IniTheta.v;
      Influx := 0;
    end;
  Area.v := Pi * Sqr(ContRad.v);
  Volume.v := Area.v * Depth.v;
  num_roots.v := ParMRLD.v * Area.v;
  RLD_mean.v := ParMRLD.v;
  wl.v := ParMRLD.v * 1E4 * Depth.v;
  wl_ha.v := wl.v * 1E4;
  AvDistance.v := Sqrt(1 / (Pi * ParMRLD.v));
  CumulativeWaterUptake.v := 0;
  ActualWaterUptake.v := 0;
  WaterBalanceError.v := 0;
  int_dt.v := 0;
  UpdateTotals;
  initialised := true;
end;

procedure TSubmodRoot1DH2O.UpdateTotals;
var I: integer;
begin
  theta.v := 0;
  for I := 0 to 9 do
  begin
    ClassRLD[I].v := 0;
    ClassTheta[I].v := 0;
    ClassInflux[I].v := 0;
    if I < Length(FCylinders) then
    begin
      theta.v := theta.v + FCylinders[I].Theta * FCylinders[I].VolumeFraction;
      ClassRLD[I].v := FCylinders[I].RLD;
      ClassTheta[I].v := FCylinders[I].Theta;
      ClassInflux[I].v := FCylinders[I].Influx;
    end;
  end;
  /// <summary>As in the 2-D water model, WAmount is water depth [cm].</summary>
  WAmount.v := theta.v * Depth.v;
  WAmount.c := 0;
end;

function TSubmodRoot1DH2O.DiurnalDemandFactor(StartDay, StepDays: double): double;
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

procedure TSubmodRoot1DH2O.CalcRates;
var Work: TWaterRootCylinders; Amounts: array of double;
  I: integer;
  Diurnal: boolean;
  StepStart, NextHour, DemandFactor: double;
  Dt, Remaining, Step, Psi, MFP, Rate, Demand, LowerTheta,
    Removed, BeforeStorage, AfterStorage, Uptake, Balance, LastStep: double;
begin
  if not initialised then raise EInvalidOp.Create('Initialize root cylinders first');
  Dt := GlobTime.c;
  RequireFinite(Dt, 'Model interval');
  RequireFinite(GlobTime.v, 'Model time');
  if not SameText(WaterUptakePattern.Option, 'constant') and
    not SameText(WaterUptakePattern.Option, 'diurnal16h') then
    raise EArgumentException.Create('Unknown water uptake pattern');
  Diurnal := SameText(WaterUptakePattern.Option, 'diurnal16h') and
    SameText(WaterUptakeMode.Option, 'fixed');
  RequireFinite(IntegrationInterval.v, 'IntegrationInterval');
  RequireFinite(PotentialWaterUptake.v, 'PotentialWaterUptake');
  if (Dt < 0) or (IntegrationInterval.v <= 0) or (PotentialWaterUptake.v < 0) then
    raise EArgumentException.Create('Invalid water integration interval or demand');
  if not SameText(WaterUptakeMode.Option, 'fixed') and
    not SameText(WaterUptakeMode.Option, 'maximum') then
    raise EArgumentException.Create('Unknown water uptake mode');
  Work := Copy(FCylinders);
  SetLength(Amounts, Length(Work));
  LowerTheta := Max(MinTheta.v, FHydraulicSoil.b_rest);
  Demand := PotentialWaterUptake.v * Area.v / (ParMRLD.v * Volume.v);
  BeforeStorage := theta.v * Volume.v;
  Remaining := Dt;
  LastStep := 0;
  Uptake := 0;
  while Remaining > 0 do
  begin
    Step := Min(Remaining, IntegrationInterval.v / 24);
    StepStart := GlobTime.v + (Dt - Remaining);
    DemandFactor := 1;
    if Diurnal then
    begin
      /// <summary>Split at hour boundaries so no averaged step crosses sunrise or sunset.</summary>
      NextHour := (Floor(StepStart * 24) + 1) / 24;
      if NextHour - StepStart < 1E-12 then NextHour := NextHour + 1/24;
      Step := Min(Step, NextHour - StepStart);
      DemandFactor := DiurnalDemandFactor(StepStart, Step);
    end;
    if (Step <= 0) or (Remaining - Step = Remaining) then
      raise EInvalidOp.Create('Water timestep cannot advance');
    for I := 0 to High(Work) do
    begin
      Rate := 0;
      if Work[I].Theta > LowerTheta then
      begin
        Psi := FHydraulicSoil.psi_b_f(Work[I].Theta);
        RequireFinite(Psi, 'Water tension');
        MFP := 0;
        if Psi < Power(10, 4.2) then MFP := Max(0, FMFPTable.get_sumku(Max(0.1, Psi)));
        Rate := MFP_IWmax(MFP, Work[I].Radius, RootRadius.v);
        RequireFinite(Rate, 'MFP influx');
        Rate := Max(0, Rate);
        if SameText(WaterUptakeMode.Option, 'fixed') then Rate := Min(Rate, Demand * DemandFactor);
        /// <summary>Limit removal to available storage; rate is cm3/cm root/d.</summary>
        Rate := Min(Rate, (Work[I].Theta - LowerTheta) / (Work[I].RLD * Step));
      end;
      Removed := Rate * Work[I].RLD * Step;
      Work[I].Theta := Max(LowerTheta, Work[I].Theta - Removed);
      Amounts[I] := Amounts[I] + Rate * Step;
      Uptake := Uptake + Removed * Volume.v * Work[I].VolumeFraction;
    end;
    Remaining := Remaining - Step;
    if Remaining <= 1E-12 * Dt then Remaining := 0;
    LastStep := Step;
  end;
  AfterStorage := 0;
  for I := 0 to High(Work) do
  begin
    Work[I].Influx := 0;
    if Dt > 0 then Work[I].Influx := Amounts[I] / Dt / 86400;
    AfterStorage := AfterStorage + Work[I].Theta * Volume.v * Work[I].VolumeFraction;
  end;
  Balance := AfterStorage - BeforeStorage + Uptake;
  RequireFinite(Balance, 'Water balance');
  if Abs(Balance) > 1E-9 * Max(1, BeforeStorage) then
    raise EInvalidOp.Create('Root cylinder water balance failed');
  FCylinders := Work;
  CumulativeWaterUptake.v := CumulativeWaterUptake.v + Uptake / Area.v;
  ActualWaterUptake.v := 0;
  if Dt > 0 then ActualWaterUptake.v := Uptake / (Area.v * Dt);
  WaterBalanceError.v := Balance / Area.v;
  int_dt.v := LastStep;
  UpdateTotals;
end;

procedure TSubmodRoot1DH2O.Integrate;
begin
  /// <summary>Storage is already advanced by CalcRates; no second integration.</summary>
end;

function TSubmodRoot1DH2O.GetCylinderCount: integer;
begin Result := Length(FCylinders); end;

function TSubmodRoot1DH2O.GetCylinder(Index: integer): TWaterRootCylinder;
begin
  if (Index < 0) or (Index >= Length(FCylinders)) then
    raise ERangeError.Create('Invalid root cylinder index');
  Result := FCylinders[Index];
end;

procedure TSubmodRoot1DH2O.InitializeWaterUptakeSoil;
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

procedure TSubmodRoot1DH2O.ConfigureWaterUptakeSoil(ASoil: TGenucht);
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

destructor TSubmodRoot1DH2O.Destroy;
begin
  FMFPTable.Free;
  FHydraulicSoil.Free;
  inherited Destroy;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
{$IFNDEF CONSOLE}
  RegisterComponents('Simulation', [TSubmodRoot1DH2O]);
{$ENDIF}
{$ENDIF}
end;

end.