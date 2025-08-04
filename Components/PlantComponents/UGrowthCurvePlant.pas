/// <summary>
/// Simulates logistic, monomolecular, Gompertz, or Richards growth. It is mainly used for describing or interpolating the crop parameters
/// such as LAI, DM, CropHeight, and ShootN over time, which are needed to simulate soil water and soil nitrogen. The approach depends on
/// the experimental data to which the growth curve is fitted or on temporally dense observations that can be used for interpolation.
/// </summary>
/// <remarks>
/// <author>
/// Henning Kage & Agronomy Group, University of Kiel
/// </author>
/// <Timestamp>
/// First edited: 6.10.89
/// Last edited: 02.08.25
/// </Timestamp>
/// <References>
/// <item>Kage, H., Kochler, M., Stutzel, H., 2000. Root growth of cauliflower (Brassica oleracea L. botrytis) under unstressed conditions: Measurement and modelling. Plant Soil 223, 131–145.</item>
/// </References>
/// </remarks>

unit UGrowthCurvePlant;

interface

uses
  UMod, UState, classes, math, sysutils, UAbstractPlant, USoilMineralisation,
  UMinMod2Pool;

type

  /// <summary>
  /// Defines the types of growth curves/interpolation methods available.
  /// </summary>
  TGrowth = (Logistisch, LogIntBased, Monomolekular, Gompertz, Richards, Linear,
    expolinear, LogIntDecay, Log_Decay, IntPol);

  /// <summary>  Enumeration type for the state variables used in the growth curve plant model</summary>
  TStateVars = (LAI, DM, CropHeight, ShootN);

  /// <summary>Enumeration type for the parameters used in the growth curve plant model.</summary>
  /// <remarks>Be aware that the meaning of the parameters depends on the growth curve type.</remarks>
  TParameters = (BaseTemp, rgr, gr, Capacity, Richards_f, IniValue);

const

  /// <summary>  Array of state variable names for the growth curve plant model</summary>
  Statenames: array [TStateVars] of string = ('LAI', 'DM', 'Height', 'ShootN');
  /// <summary>  Array of state variable units for the growth curve plant model</summary>
  StateUnits: array [TStateVars] of string = ('[-]', '[g/m2]', '[m]',
    '[gN/m2]');

  /// <summary>  Array of parameter names for the growth curve plant model</summary>
  Parnames: array [TParameters] of string = ('BaseTemp', 'rgr', 'gr',
    'Capacity', 'Richards_f', 'IniValue');

  /// <summary>Array of parameter units for the growth curve plant model.</summary>
  /// <remarks>Be aware that these units depend on the associated state variables.</remarks>
  ParUnits: array [TParameters] of string = ('[°C]', '[1/d]', '[]', '[]',
    '[]', '[]');

  /// <summary>Maximum number of data points for interpolation</summary>
  MaxVals = 10000;

type

  /// <summary>
  /// Plant model that simulates growth curves based on logistic, monomolecular, Gompertz, Richards,
  /// linear, or expo-linear growth. It calculates growth rates based on temperature and other parameters
  /// and integrates these rates over time to update state variables such as LAI, DM, CropHeight, and ShootN.
  /// </summary>
  /// <remarks>
  /// This class extends TAbstractPlant and provides methods for calculating growth rates, integrating state variables,
  /// and handling temperature effects on plant growth. It also supports soil nitrogen uptake if enabled.
  /// </remarks>

  TGrowthCurvePlant = class(TAbstractPlant)

  private
    /// <summary>Indicates if the plant has emerged.</summary>
    /// <remarks>This flag is set to true when the plant has emerged from the soil.</remarks>
    fEmergence: boolean;
  protected

    /// <summary>Interpolation values for state variables, storing time and value pairs.</summary>
    IntPolVals: array [TStateVars, 0 .. MaxVals] of record t: real;
    V: real;
  end;

  /// <summary>Indicates if nitrogen uptake should be simulated.</summary>
fWithNUptake:
boolean;

/// <summary>Calculates the growth rate based on the current state, temperature, and curve-specific parameters.</summary>
function CalcGrowthRate(ActValue, temp, BaseTemp, rgr, gr, Capacity, Form: real;
  CurveType: TGrowth; StateVar: TStateVars): real;
/// <summary>Getter for the Leaf Area Index (LAI)</summary>
/// <returns>Leaf Area Index as a THumeNumEntity</returns>
/// <remarks>This method retrieves the current Leaf Area Index from the state variables.</remarks>
function GetLAI: THumeNumEntity; override;

/// <summary>Getter for the Crop Height</summary>
/// <returns>Crop Height as a THumeNumEntity</returns>
/// <remarks>This method retrieves the current crop height from the state variables.</remarks>
function GetCropHeight: THumeNumEntity; override;

/// <summary>Getter for the Nitrogen uptake rate</summary>
/// <returns>Nitrogen uptake rate as a THumeNumEntity</returns>
/// <remarks>This method retrieves the current nitrogen uptake rate from the growth rates.</remarks>
function GetNUptakeRate: THumeNumEntity; override;

public
  /// <summary>Indicates if the plant is currently growing</summary>
  /// <remarks>This boolean flag is set to true when the plant is actively growing, false otherwise.</remarks>
  plantIsGrowing: boolean;

  /// Pointer to external temperature variable of type TExternV
  temp: TExternV;
  /// <summary> Temperature sum state variable</summary>
  TSum: TState;

  /// <summary> Temperature sum state variable for dry matter</summary>
  TSum_DM: TState;
  Harvestindex, C_cont_Res, N_Harvestindex: TPar;

  /// <summary>Array of state variables for the growth model</summary>
  StateVars: array [TStateVars] of TState;

  /// <summary>Array of growth curve types for each state variable</summary>
  CurveTypes: array [TStateVars] of TGrowth;

  /// <summary>Array of curve options for each state variable</summary>
  /// <remarks>Options are the user interface to define the type of growth curve used for each state variable.</remarks>
  CurveOptions: array [TStateVars] of TOption;
  CurveSwitches: array [TStateVars] of boolean;

  /// <summary>Array of variable changes for each state variable</summary>
  GrowthRates: array [TStateVars] of TVar;

  /// <summary>Two dimensional Array of parameters for each state variable</summary>
  Parameters: array [TStateVars, TParameters] of TPar;

  /// <summary>Temperature sum for emergence</summary>
  TempSumEmerge: TPar;

  SoilNUptakeGrowthRate: TExternV;
  SumSoilNUptakeGrowth: TState;

  procedure CalcRates;
  override;
  procedure Integrate;
  override;
  procedure CreateAll;
  override;

  procedure Init(var GlobMod: Tmod);
  override;

published
  property withNUptake: boolean read fWithNUptake write fWithNUptake;
  property Ex_Temp: TExternV read temp write temp;
  property Par_LAImax: TPar read Parameters[LAI, Capacity]
    write Parameters[LAI, Capacity];
  property Par_TempsumEmerge: TPar read TempSumEmerge write TempSumEmerge;
  end;

  procedure Register;

implementation

uses
  UAbstractSoilMin;

function TGrowthCurvePlant.GetCropHeight: THumeNumEntity;

begin
  result := StateVars[CropHeight]
end;

function TGrowthCurvePlant.GetLAI: THumeNumEntity;

begin
  result := StateVars[LAI]
end;

function TGrowthCurvePlant.GetNUptakeRate: THumeNumEntity;
begin
  result := GrowthRates[ShootN]
end;

function TGrowthCurvePlant.CalcGrowthRate(ActValue, temp, BaseTemp, rgr, gr,
  Capacity, Form: real; CurveType: TGrowth; StateVar: TStateVars): real;

var
  effTemp, x2, y2, t_x, y_tx, Int_: real;
  i: integer;
  test: double;

begin
  result := 0.0;
  effTemp := temp - BaseTemp;
  if effTemp > 0.0 then
    case CurveType of
      Logistisch:
        if Capacity > 0 then
          result := ActValue * rgr * effTemp * (1 - ActValue / Capacity)
        else
          result := 0.0;

      LogIntBased:
        if Capacity > 0 then
          result := (Capacity / (1 + exp((gr - (TSum_DM.V + TSum_DM.c)) / rgr)))
            - ActValue

        else
          result := 0.0;

      Monomolekular:
        result := rgr * effTemp * (Capacity - ActValue);
      Gompertz:
        result := rgr * ActValue * effTemp * ln(Capacity / ActValue);

      Richards:
        if (Form * power(Capacity, Form)) <> 0 // prevent division by zero
        then
          result := rgr * effTemp * ActValue *
            (power(Capacity, Form) - power(ActValue, Form)) /
            (Form * power(Capacity, Form))
        else
          result := 0.0;
      Linear:
        result := gr;
      expolinear:
        if rgr = 0 // prevent division by zero
        then
          result := 0
        else if ActValue < gr / rgr then
          result := rgr * effTemp * ActValue
        else
          result := gr * effTemp;
      LogIntDecay:
        if Capacity = 0 then
          result := 0
        else
        begin
          t_x := ln(99) * rgr + gr;
          if (TSum_DM.V + TSum_DM.c) >= t_x then
          begin
            x2 := (TSum_DM.V + TSum_DM.c) - t_x;
            Int_ := max(0, ((1 - (1 - 0.99) * exp(-Form * x2)) * Capacity))
          end
          else
            Int_ := Capacity / (1 + exp((gr - (TSum_DM.V + TSum_DM.c)) / rgr));
          if Int_ = 0 then
            result := -ActValue
          else
            result := Int_ - ActValue;
        end;

      Log_Decay:
        if Capacity = 0 then
          result := 0
        else if (ActValue < 0.99 * Capacity) and
          (CurveSwitches[StateVar] = false) then
          result := ActValue * rgr * effTemp * (1 - ActValue / Capacity)
        else
        begin
          test := -gr * effTemp * ActValue * (Capacity - ActValue);
          result := math.min(0, test);
          CurveSwitches[StateVar] := true;
        end;
      IntPol:
        if SomethingMeasured then
        begin
          i := 0;
          while (IntPolVals[StateVar, i].t <= GlobTime.V) and
            (IntPolVals[StateVar, i].t > 0) do
            inc(i);
          result := IntPolVals[StateVar, i - 1].V +
            (IntPolVals[StateVar, i].V - IntPolVals[StateVar, i - 1].V) *
            (GlobTime.V - IntPolVals[StateVar, i - 1].t) /
            (IntPolVals[StateVar, i].t - IntPolVals[StateVar, i - 1].t)
            - ActValue;
        end;
    end; // Case
end;

procedure TGrowthCurvePlant.CreateAll;

var
  State: TStateVars;
  Parm: TParameters;

begin
  inherited CreateAll;
  StateCreate('TSum', '[°Cd]', 0.0, false, TSum,
    'Temperature sum for growth, starting at sowing date corrected for base temperature');
  StateCreate('TSum_DM', '[°Cd]', 0.0, false, TSum_DM,
    'Temperature sum for dry matter');
  Parcreate('Harvestindex', '[-]', 0.5, Harvestindex, 'Harvest index');
  Parcreate('C_cont_Res', '[-]', 0.45, C_cont_Res, 'C content residues');
  Parcreate('N_Harvestindex', '[-]', 0.5, N_Harvestindex, 'N harvest index');
  Parcreate('TempSumEmerge', '[°C*d]', 150, TempSumEmerge,
    'Temperature sum for emergence, emerges when TSum >= TempSumEmerge');

  for State := low(TStateVars) to high(TStateVars) do
  begin
    /// <summary>Create state variable with name, units, initial value, and optional comment.</summary>
    if ((State = DM) or (State = ShootN)) then
      StateCreate(Statenames[State], StateUnits[State], 0.0, false,
        StateVars[State],
        'if Opt = LogIntBased then Capacity: ASYM; gr: XMID; rgr: SCAL (SSLogisR)')
    else
      StateCreate(Statenames[State], StateUnits[State], 0.0, false,
        StateVars[State]);
    StateVars[State].PlotTograpH := true;
    /// <summary>Create options for curve type with name, default value, and comment.</summary>
    OptCreate(Statenames[State] + '_CurveType', 'Logistisch',
      CurveOptions[State], 'Curve type for growth rate calculation');
    CurveOptions[State].OptionList.Add('Logistisch');
    CurveOptions[State].OptionList.Add('LogIntBased');
    CurveOptions[State].OptionList.Add('Monomolekular');
    CurveOptions[State].OptionList.Add('Gompertz');
    CurveOptions[State].OptionList.Add('Richards');
    CurveOptions[State].OptionList.Add('Linear');
    CurveOptions[State].OptionList.Add('Expolinear');
    CurveOptions[State].OptionList.Add('LogIntDecay');
    CurveOptions[State].OptionList.Add('Log_Decay');
    CurveOptions[State].OptionList.Add('IntPol');
    /// <summary>Create variable with name, units, initial value, and comment.</summary>
    VarCreate(Statenames[State] + '_Change', StateUnits[State], 0, false,
      GrowthRates[State]);
  end;
  for State := low(TStateVars) to high(TStateVars) do
  begin
    for Parm := low(TParameters) to high(TParameters) do
    begin
      Parcreate(Statenames[State] + '_' + Parnames[Parm], ParUnits[Parm], 0,
        Parameters[State, Parm]);

    end;
  end;
  ExternVCreate('TMPM', '[°C]', RateField, temp);
  if withNUptake then
  begin
    ExternVCreate('SoilNUptakeGrowth', '[]', RateField, SoilNUptakeGrowthRate);
    StateCreate('SumSoilNUptakeGrowth', '[]', 0.0, false, SumSoilNUptakeGrowth);
  end;
end;

procedure TGrowthCurvePlant.Init(var GlobMod: Tmod);

var
  State: TStateVars;
  i: integer;
  t: real;

begin
  inherited Init(GlobMod);
  fEmergence := false;
  for State := low(TStateVars) to high(TStateVars) do
  begin
    CurveSwitches[State] := false;
    if CurveOptions[State].Option = lowercase('Logistisch') then
      CurveTypes[State] := Logistisch;
    if CurveOptions[State].Option = lowercase('LogIntBased') then
      CurveTypes[State] := LogIntBased;
    if CurveOptions[State].Option = lowercase('Linear') then
      CurveTypes[State] := Linear;
    if CurveOptions[State].Option = lowercase('Expolinear') then
      CurveTypes[State] := expolinear;
    if CurveOptions[State].Option = lowercase('Richards') then
      CurveTypes[State] := Richards;
    if CurveOptions[State].Option = lowercase('Gompertz') then
      CurveTypes[State] := Gompertz;
    if CurveOptions[State].Option = lowercase('Monomolekular') then
      CurveTypes[State] := Monomolekular;
    if CurveOptions[State].Option = lowercase('LogIntDecay') then
      CurveTypes[State] := LogIntDecay;
    if CurveOptions[State].Option = lowercase('Log_Decay') then
      CurveTypes[State] := Log_Decay;
    if CurveOptions[State].Option = lowercase('IntPol') then
      CurveTypes[State] := IntPol;
    if TempSumEmerge.V > 0.0 then
      StateVars[State].V := 0.0;
    if SomethingMeasured and (CurveTypes[State] = IntPol) then
    begin
      for i := 0 to MaxVals do
        IntPolVals[State, i].t := 0;
      for i := 0 to MaxVals do
        IntPolVals[State, i].V := 0;
      IntPolVals[State, 0].t := SowingDate.V;
      IntPolVals[State, 0].V := Parameters[State, IniValue].V;
      i := 1;
      FMeasValues.LocateFor(GlobTime.Name, GlobTime.V);
      if FMeasValues.GetValue(Statenames[State]) <> 0 then
      begin
        IntPolVals[State, i].t := FMeasValues.Getindexvalue(0);
        IntPolVals[State, i].V := FMeasValues.GetValue(Statenames[State]);
        inc(i);
      end;
      while (i < MaxVals) do
      begin
        t := FMeasValues.Getindexvalue(0);
        FMeasValues.NextLine;
        if t >= FMeasValues.Getindexvalue(0) then
          break;
        if FMeasValues.GetValue(Statenames[State]) <> 0 then
        begin
          IntPolVals[State, i].t := FMeasValues.Getindexvalue(0);
          IntPolVals[State, i].V := FMeasValues.GetValue(Statenames[State]);
          inc(i);
        end;
      end;
      if IntPolVals[State, i - 1].t < HarvestDate.V then
      begin
        IntPolVals[State, i].t := HarvestDate.V;
        if (i > 1) and (FMeasValues.GetValue(Statenames[State]) > 0) then
          IntPolVals[State, i].V := IntPolVals[State, i - 2].V +
            (IntPolVals[State, i - 1].V - IntPolVals[State, i - 2].V) *
            (IntPolVals[State, i].t - IntPolVals[State, i - 2].t) /
            (IntPolVals[State, i - 1].t - IntPolVals[State, i - 2].t)
        else
          IntPolVals[State, i].V := IntPolVals[State, i - 1].V;
      end
      else
        IntPolVals[State, i].t := 0;
    end;
  end;

end;

procedure TGrowthCurvePlant.CalcRates;

var
  State: TStateVars;

begin
  /// <summary>After sowing and before harvest, initialize state variables with their initial values.</summary>
  if (GlobTime.V >= SowingDate.V) and (GlobTime.V <= HarvestDate.V) then
  begin
    for State := low(TStateVars) to high(TStateVars) do
    begin
      if StateVars[State].V <= 0.0 then
        StateVars[State].V := Parameters[State, IniValue].V;
    end;
  end;

  if (GlobTime.V >= SowingDate.V) and (GlobTime.V <= HarvestDate.V) then
  begin
    if temp.V > Parameters[LAI, BaseTemp].V then
      TSum.c := temp.V - Parameters[LAI, BaseTemp].V
    else
      TSum.c := 0.0;
    if TSum.V >= TempSumEmerge.V then
    begin
      if temp.V > Parameters[DM, BaseTemp].V then
        TSum_DM.c := temp.V - Parameters[DM, BaseTemp].V
      else
        TSum_DM.c := 0.0;
      for State := low(TStateVars) to high(TStateVars) do
      begin
        if temp.V >= Parameters[State, BaseTemp].V then
        begin
          // TSum.C := Temp.v;
          StateVars[State].c := CalcGrowthRate(StateVars[State].V, temp.V,
            Parameters[State, BaseTemp].V, Parameters[State, rgr].V,
            Parameters[State, gr].V, Parameters[State, Capacity].V,
            Parameters[State, Richards_f].V, CurveTypes[State], State);
          if StateVars[State].V + StateVars[State].c < 0 then
            StateVars[State].c := -StateVars[State].V;
        end
        else
        begin
          // TSum.c := 0.0;
          StateVars[State].c := 0.0;

        end; //
      end;
    end;
    if withNUptake then
      SumSoilNUptakeGrowth.c := SoilNUptakeGrowthRate.V;
  end
  else if withNUptake then
  begin
    SumSoilNUptakeGrowth.c := 0;
    SumSoilNUptakeGrowth.V := 0;
  end;

  if GlobTime.V = HarvestDate.V then
  begin
    plantIsGrowing := false;

    if (SoilMinMOd is TMinMod2Pool) then
    begin
      if self <> nil then
        TMinMod2Pool(self.SoilMinMOd).calcRatesIsActive := false;

      if (NextCrop <> nil) and (NextCrop.SoilMinMOd <> nil) then
        TMinMod2Pool(NextCrop.SoilMinMOd).calcRatesIsActive := true;

    end;
  end;

  if (GlobTime.V > HarvestDate.V) and (harvested = false) then
  begin // handle harvest after the harvest date
    DoHarvest := true;
    C_Residues.V := { C_residues.v + } (1 - Harvestindex.V) * StateVars[DM].V *
      C_cont_Res.V;
    N_Residues.V := { N_Residues.v + } (1 - N_Harvestindex.V) *
      StateVars[ShootN].V;
  end;

  for State := low(TStateVars) to high(TStateVars) do
    GrowthRates[State].V := StateVars[State].c;

  inherited CalcRates;
end;

procedure TGrowthCurvePlant.Integrate;

var
  State: TStateVars;
begin
  inherited Integrate;

  if (GlobTime.V >= SowingDate.V) and (TSum.V >= TempSumEmerge.V) and
    (fEmergence = false) then
  begin
    for State := low(TStateVars) to high(TStateVars) do
    begin
      StateVars[State].V := Parameters[State, IniValue].V;
      if CurveTypes[State] = IntPol then
        IntPolVals[State, 0].t := GlobTime.V;
    end;
    fEmergence := true;
  end;

end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TGrowthCurvePlant]);
{$ENDIF}
end;

end.
