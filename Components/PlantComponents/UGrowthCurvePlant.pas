/// <summary>
/// Simulates logistic, monomolecular, Gompertz, or Richards growth. It is mainly used for describing/interpolation the crop parameters
/// such as LAI, DM, CropHeight, and ShootN over time which are needed to simulate soil water and soil nitrogen.No license found. Thereby it depends on 
/// the experimental data to which the growth curve is fitted or typically temporally even denser observed data which then dan be used for interpolation.
/// </summary>
/// <remarks>
///   <author>
///     Henning Kage & Agronomy Group, University of Kiel
///   </author>
///   <Timestamp>
///     First edited: 6.10.89
///     Last edited: 02.08.25
///   </Timestamp>
///   <References>
///       <item>Kage, H., Kochler, M., Stutzel, H., 2000. Root growth of cauliflower (Brassica oleracea L. botrytis) under unstressed conditions: Measurement and modelling. Plant Soil 223, 131–145.</item>
///   </References>
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
  TGrowth = (Logistisch, LogIntBased, Monomolekular, Gompertz, Richards, Linear, expolinear,
    LogIntDecay, Log_Decay, IntPol);

/// <summary>  Enumeration type for the state variables used in the growth curve plant model</summary>    
  TStateVars = (LAI, DM, CropHeight, ShootN);

/// <summary>   Enumeration type for the parameters used in the growth curve plant model</summary>
//// <remarks> be aware that th meaning of the parameters depends on the growth curve type</remarks>
  TParameters = (BaseTemp, rgr, gr, Capacity, Richards_f, IniValue);

const

/// <summary>  Array of state variable names for the growth curve plant model</summary>
  Statenames: array[TStatevars] of string = ('LAI', 'DM', 'Height', 'ShootN');
/// <summary>  Array of state variable units for the growth curve plant model</summary>  
  StateUnits: array[TStatevars] of string = ('[-]', '[g/m2]', '[m]', '[gN/m2]');

/// <summary>  Array of parameter names for the growth curve plant model</summary>  
  Parnames: array[TParameters] of string = ('BaseTemp', 'rgr', 'gr', 'Capacity',
    'Richards_f', 'IniValue');

/// <summary>  Array of parameter units for the growth curve plant model</summary>
/// <remarks> be aware that the the units can not defined independently from the state variables</remarks>    
  ParUnits: array[TParameters] of string = ('[°C]', '[1/d]', '[]', '[]', '[]',
    '[]');

/// <summary>Maximum number of data points for interpolation</summary>
  MaxVals = 10000; 

type

/// <summary>
/// Plant model that simulates growth curves based on logistic, monomolecular, Gompertz, or Richards growth.
/// It calculates growth rates based on temperature and other parameters, and integrates these rates
/// over time to update state variables such as LAI, DM, CropHeight, and ShootN.
/// </summary>
/// <remarks>
/// This class extends TAbstractPlant and provides methods for calculating growth rates, integrating state variables,
/// and handling temperature effects on plant growth. It also supports soil nitrogen uptake if enabled.
/// </remarks>  

  TGrowthCurvePlant = class(TAbstractPlant)

  private
/// <summary>Indicates if the plant has emerged</summary>
    /// <remarks>This boolean flag is set to true when the plant has emerged from the soil</remarks>
    fEmergence: boolean;
  protected

/// <summary>Interpolation values for state variables containing records of time and value</summary>
    IntPolVals: array[TStateVars, 0..MaxVals] of record
      t: real;
      V: real;
    end;

/// <summary>Indicates if nitrogen uptake should be simulated </summary>    
    fWithNUptake: boolean;

/// <summary> function to calculate the growth rate based on the current state, temperature, and parameters depending
/// on the type of growth curve</summary>
    function CalcGrowthRate(ActValue, temp, BaseTemp, rgr, gr, Capacity, Form:
      real;
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
    plantIsGrowing: Boolean;

/// Pointer to external temperature variable of type TExternV
    Temp: TExternV;
/// <summary> Temperature sum state variable</summary>    
    TSum: TState;

/// <summary> Temperature sum state variable for dry matter</summary>    
    TSum_DM: TState;
    Harvestindex,
      C_cont_Res,
      N_Harvestindex: TPar;

/// <summary>Array of state variables for the growth model</summary>
    StateVars: array[TStateVars] of TState;

/// <summary>Array of growth curve types for each state variable</summary>    
    CurveTypes: array[TStateVars] of TGrowth;

/// <summary>Array of curve options for each state variable</summary>
 /// <remarks>Options are the user interface to define the type of growth curve used for each state variable.</remarks> 
    CurveOptions: array[TStateVars] of TOption;
    CurveSwitches: array[TStateVars] of boolean;

/// <summary>Array of variable changes for each state variable</summary>    
    GrowthRates: array[TStateVars] of TVar;

/// <summary>Two dimensional Array of parameters for each state variable</summary>
   Parameters: array[TStateVars, TParameters] of Tpar;


/// <summary>Temperature sum for emergence</summary>    
    TempSumEmerge: TPar;

    SoilNUptakeGrowthRate: TExternV;
    SumSoilNUptakeGrowth: TState;

 
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

  published
    property withNUptake: boolean read fWithNUptake write fWithNUptake;
    property Ex_Temp: TExternV read Temp write Temp;
    property Par_LAImax: TPar read Parameters[LAI, Capacity] write
      Parameters[LAI, Capacity];
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
  result := GrowthRates[SHOOTN]
end;

function TGrowthCurvePlant.CalcGrowthRate(ActValue, temp, BaseTemp, rgr, gr,
  Capacity, Form: real;
  CurveType: TGrowth; StateVar: TStateVars): real;

var
  effTemp, x2,y2, t_x, y_tx,Int_: real;
  i: integer;
  test: double;

begin
  result := 0.0;
  effTemp := temp - BaseTemp;
  if effTemp > 0.0 then
    case CurveType of
      logistisch: if capacity > 0
                  then
                    result := ActValue * rgr * effTemp * (1 - ActValue / Capacity)
                  else result := 0.0;

      LogIntBased: if capacity > 0
                  then
                    result := (Capacity/(1+exp((gr-(TSUM_DM.v+TSUM_DM.c))/rgr))) -
                                ActValue

                  else result := 0.0;

      monomolekular: result := rgr * efftemp * (Capacity - ActValue);
      gompertz: result := rgr * actValue * efftemp * ln(Capacity / actvalue);

      Richards: if (Form * power(capacity, form)) <> 0   // prevent division by zero
                then
                  result := rgr * efftemp * actvalue * (Power(Capacity, form) -
                         Power(ActValue, Form)) / (Form * power(capacity, form))
                else result := 0.0;
      linear: result := gr;
      expolinear: if rgr = 0                             // prevent division by zero
                  then result := 0
                  else if ActValue < gr / rgr
                       then
                         result := rgr * efftemp * ActValue
                       else
                         result := gr * effTemp;
      LogIntDecay: if Capacity = 0
                   then result:=0
                   else begin
                      t_x:= ln(99)*rgr+gr;
                      if (TSUM_DM.v+TSUM_DM.c) >= t_x then begin
                      x2:= (TSUM_DM.v+TSUM_DM.c) - t_x;
                      Int_ := max(0,((1-(1-0.99)*exp(-form*x2))* Capacity))
                     end else
                      Int_ :=Capacity/(1+exp((gr-(TSUM_DM.v+TSUM_DM.c))/rgr));
                     if Int_ = 0 then
                        result:= - ActValue
                      else
                        result:= Int_ - ActValue;
                   end;

      Log_Decay: if Capacity = 0
                 then result := 0
                 else if (ActValue < 0.99 * Capacity) and (CurveSwitches[StateVar] = false)
                      then
                        result := ActValue * rgr * effTemp * (1 - ActValue / Capacity)
                      else begin
                        test := -gr * efftemp * ActValue * (Capacity - ActValue);
                        Result := math.min(0, test);
                        CurveSwitches[StateVar] := true;
                      end;
      IntPol: if SomethingMeasured then begin
          i := 0;
          while (IntPolVals[StateVar, i].T <= GlobTime.v) and
            (IntPolVals[StateVar, i].T > 0) do inc(i);
          result := IntPolVals[StateVar, i - 1].V + (IntPolVals[StateVar, i].V -
            IntPolVals[StateVar, i - 1].V) * (GlobTime.v - IntPolVals[StateVar, i
            - 1].T) / (IntPolVals[StateVar, i].T - IntPolVals[StateVar, i - 1].T)
            - ActValue;
        end;
    end; // Case
end;

procedure TGrowthCurvePlant.CreateAll;

var
  State: TStateVars;
  Parm: TParameters;

begin
  inherited createall;
  StateCreate('TSum', '[°Cd]', 0.0, false, TSUM, 'Temperature sum for growth, starting at sowing date corrected for base temperature');
  StateCreate('TSum_DM', '[°Cd]', 0.0, false, TSUM_DM, 'Temperature sum for dry matter');
  Parcreate('Harvestindex', '[-]', 0.5, Harvestindex, 'Harvest index');
  Parcreate('C_cont_Res', '[-]', 0.45, C_cont_Res, 'C content residues');
  Parcreate('N_Harvestindex', '[-]', 0.5, N_Harvestindex, 'N harvest index');
  Parcreate('TempSumEmerge', '[°C*d]', 150, TempSumEmerge, 'Temperature sum for emergence, emerges when TSum >= TempSumEmerge');

  for State := low(TStateVars) to high(TStateVars) do begin
/// <summary>Create state variable with name, units, initial value and comment date</summary>
    if ((State = DM) or (State = ShootN)) then
      StateCreate(StateNames[State], StateUnits[State], 0.0, false,
      StateVars[State],'if Opt = LogIntBased then Capacity: ASYM; gr: XMID; rgr: SCAL (SSLogisR)')
    else
    StateCreate(StateNames[State], StateUnits[State], 0.0, false,
      StateVars[State]);
    StateVars[State].PlotTograpH := true;
 /// <summary>Create options for curve type with name, default value and comment</summary>   
    OptCreate(StateNames[State] + '_CurveType', 'Logistisch',
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
/// <summary>Create variable with name, units, initial value and comment</summary>
    VarCreate(StateNames[State] + '_Change', StateUnits[State], 0, false,
      Growthrates[State]);
  end;
/// 
  for State := low(TStateVars) to high(TStateVars) do begin
    for Parm := low(TParameters) to high(TParameters) do begin
      Parcreate(StateNames[State] + '_' + ParNames[Parm], ParUnits[Parm], 0,
        Parameters[State, Parm]);

    end;
  end;
///
  ExternVCreate('TMPM', '[�C]', RateField, Temp);
  if withNUptake then begin
    ExternVcreate('SoilNUptakeGrowth','[]',RateField,SoilNUptakeGrowthRate);
    StateCreate('SumSoilNUptakeGrowth','[]',0.0,false,SumSoilNUptakeGrowth);
  end;
end;

procedure TGrowthCurvePlant.Init(var GlobMod: TMod);

var
  State: TStateVars;
  i: integer;
  t: real;

//TGrowth = (Logistisch, Monomolekular, Gompertz, Richards, Linear, expolinear);

begin
  inherited Init(GlobMod);
  fEmergence := false;
  for State := low(TStateVars) to high(TStateVars) do begin
    CurveSwitches[State] := false;
    if CurveOptions[State].Option = lowercase('Logistisch') then
      Curvetypes[State] := Logistisch;
    if CurveOptions[State].Option = lowercase('LogIntBased') then
      Curvetypes[State] := LogIntBased;
    if CurveOptions[State].Option = lowercase('Linear') then
      Curvetypes[State] := Linear;
    if CurveOptions[State].Option = lowercase('Expolinear') then
      Curvetypes[State] := Expolinear;
    if CurveOptions[State].Option = lowercase('Richards') then
      Curvetypes[State] := Richards;
    if CurveOptions[State].Option = lowercase('Gompertz') then
      Curvetypes[State] := Gompertz;
    if CurveOptions[State].Option = lowercase('Monomolekular') then
      Curvetypes[State] := Monomolekular;
    if CurveOptions[State].Option = lowercase('LogIntDecay') then
      Curvetypes[State] := LogIntDecay;
    if CurveOptions[State].Option = lowercase('Log_Decay') then
      Curvetypes[State] := Log_decay;
    if CurveOptions[State].Option = lowercase('IntPol') then
      Curvetypes[State] := IntPol;
    if TempSumEmerge.v > 0.0 then
      StateVars[State].v := 0.0;
    if SomethingMeasured and (Curvetypes[State] = IntPol) then begin
      for i := 0 to MaxVals do IntPolVals[State, i].T := 0;
      for i := 0 to MaxVals do IntPolVals[State, i].V := 0;
      IntPolVals[State, 0].T := SowingDate.v;
      IntPolVals[State, 0].V := Parameters[State, IniValue].v;
      i := 1;
      FMeasValues.LocateFor(GlobTime.Name, GlobTime.v);
      if fMeasValues.GetValue(StateNames[State]) <> 0 then begin
        IntPolVals[State, i].T := fMeasValues.Getindexvalue(0);
        IntPolVals[State, i].V := fMeasValues.GetValue(StateNames[State]);
        inc(i);
      end;
      while (i < MaxVals) do begin
        t := fMeasValues.Getindexvalue(0);
        fMeasValues.NextLine;
        if t >= fMeasValues.Getindexvalue(0) then break;
        if fMeasValues.GetValue(StateNames[State]) <> 0 then begin
          IntPolVals[State, i].T := fMeasValues.Getindexvalue(0);
          IntPolVals[State, i].V := fMeasValues.GetValue(StateNames[State]);
          inc(i);
        end;
      end;
      if IntPolVals[State, i - 1].T < HarvestDate.v then begin
        IntPolVals[State, i].T := HarvestDate.v;
        if (i > 1) and (fMeasValues.GetValue(StateNames[State]) > 0) then
          IntPolVals[State, i].V := IntPolVals[State, i - 2].V +
          (IntPolVals[State, i - 1].V - IntPolVals[State, i - 2].V) *
          (IntPolVals[State, i].T - IntPolVals[State, i - 2].T) /
          (IntPolVals[State, i - 1].T - IntPolVals[State, i - 2].T)
        else IntPolVals[State, i].V := IntPolVals[State, i - 1].V;
      end else
        IntPolVals[State, i].T := 0;
    end;
  end;

end;

procedure TGrowthCurvePlant.CalcRates;

var
  State: TStateVars;

begin
/// <summary> after the sowing date, initialize state variables with initial values</summary>
  if (GlobTime.v >= SowingDate.v) and (GlobTime.v <= HarvestDate.v) then begin
    for State := low(TStateVars) to high(TStateVars) do begin
      if StateVars[State].V <= 0.0 then
        StateVars[State].v := Parameters[State, IniValue].v;
    end;
  end;

  if (GlobTime.v >= SowingDate.v) and (GlobTime.v <= HarvestDate.v) then begin
    if Temp.v > Parameters[LAI, BaseTemp].v then
      TSum.c := Temp.v - Parameters[LAI, BaseTemp].v
    else
      TSum.c := 0.0;
    if TSum.v >= TempSumEmerge.v then begin
      if Temp.v > Parameters[DM, BaseTemp].v then
        TSum_DM.c := Temp.v - Parameters[DM, BaseTemp].v
      else
        TSum_DM.c := 0.0;
      for State := low(TStateVars) to high(TStateVars) do begin
        if Temp.v >= Parameters[State, BaseTemp].v then begin
        //  TSum.C := Temp.v;
          StateVars[State].C := CalcGrowthRate(StateVars[State].v, temp.v,
            Parameters[State, BaseTemp].v,
            Parameters[State, rgr].v, Parameters[State, gr].v,
            Parameters[State, capacity].v, Parameters[State, Richards_f].V,
            CurveTypes[State], State);
          if StateVars[State].v + StateVars[State].c < 0 then
            StateVars[State].c := -StateVars[State].v;
        end else begin
      //   TSum.c := 0.0;
          StateVars[State].c := 0.0;

        end; //
      end;
    end;
    if withNUptake then SumSoilNUptakeGrowth.c := SoilNUptakeGrowthRate.v;
  end
  else if withNUptake then begin
    SumSoilNUptakeGrowth.c := 0;
    SumSoilNUptakeGrowth.v := 0;
  end;

  if GlobTime.v = harvestdate.v then begin
    plantIsGrowing := False;

    if (SoilMinMOd is TMinMod2Pool)  then begin
          if self <> nil then
            TMinMod2Pool(self.SoilMinMOd).calcRatesIsActive := false;

          if (NextCrop <> nil) and (NextCrop.SoilMinMOd <> nil) then
            TMinMod2Pool(NextCrop.SoilMinMOd).calcRatesIsActive := true;

    end;
  end;

  if (GlobTime.V > HarvestDate.V) and (harvested = false)
  then begin // +1 ge�ndert Mehrtens //zur�ck ge�ndert Wienforth (28.11.08)
    DoHarvest := true;
    C_Residues.v := {C_residues.v +} (1 - Harvestindex.v) * StateVars[DM].v * C_cont_Res.v;
    N_Residues.v := {N_Residues.v +} (1 - N_harvestindex.v) * StateVars[ShootN].v;
  end;

  for State := low(TStateVars) to high(TStateVars) do
    GrowthRates[state].v := StateVars[State].c;

  inherited CalcRates;
end;

procedure TGrowthCurvePlant.Integrate;

var
  State: TStateVars;
begin
  inherited Integrate;

  if (GlobTime.v >= SowingDate.v) and (TSum.v >= TempSumEmerge.v) and (fEmergence
    = false) then begin
    for State := low(TStateVars) to high(TStateVars) do begin
      StateVars[State].v := Parameters[State, IniValue].v;
      if CurveTypes[State] = IntPol then 
        IntPolVals[State, 0].t := GlobTime.V;
    end;
    femergence := true;
  end;

end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TGrowthCurvePlant]);
{$ENDIF}

end;

end.

