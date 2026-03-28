unit USoilNitrogenUp;

interface

uses
  UMod, UlayeredSoil, USoilNitrogen, UState, UAbstractPlant, URootUptakeFunctions,
  classes;

const
  Max_Root_Index = 20;

type
  TSoilNitrogenUp = class(TSoilNitrogen)

  private
    fplantNDemand: real;

  protected
    procedure SetPlantModel(NewPlantModel: TAbstractplant); override;

  public
    /// <summary>Actual N uptake rate averaged over the day.</summary>
    ActNUptake: TVar;
    /// <summary>Maximum N uptake rate averaged over the day.</summary>
    MaxNUptake: TVar;
    /// <summary>Sum of apparent mass flow transport to roots [kg N/ha/d].</summary>
    MassFlow: TVar;
    /// <summary>N uptake per day [kg N/ha/d].</summary>
    NUptake: TSoilVarArray;
    /// <summary>Water influx per unit root length [cm3/cm/d].</summary>
    WInflux: TSoilArray;
    /// <summary>Nitrate influx per unit root length.</summary>
    NInflux_WL: TVar;
    /// <summary>Nitrate influx per unit effective root length.</summary>
    NInflux_WL_eff: TVar;

    /// <summary>Average N uptake rate per day for plotting as a state variable.</summary>
    SumSoilNUptake: TState;
    /// <summary>Average N uptake rate per day in units of g/m2/d.</summary>
    SoilNUptakeGrowth: TState;
    /// <summary>Total sum of plant nitrogen demand.</summary>
    SumPlantNDemand: TState;

    /// <summary>Minimum nitrate concentration subtracted from the actual concentration [kg/cm water].</summary>
    Cmin: TPar;
    /// <summary>Plant unavailable share of nitrate [kg N/10 cm].</summary>
    not_av_N: TPar;
    /// <summary>Root radius [cm].</summary>
    RootRad: TPar;
    /// <summary>Maximum value for N uptake per unit root length [kg/cm/d].</summary>
    Max_Wl_Nuptake: TPar;
    // NTotal       : TExternV;
    /// <summary>Plant N demand [g N/m/d].</summary>
    Ex_PlantNDemand: TExternV;
    /// <summary>Sum of root length [cm/cm2].</summary>
    SRL: TExternV;
    /// <summary>Effective sum of root length [cm/cm2].</summary>
    SRL_eff: TExternV;

    procedure CreateAll; override;
    procedure CalcRatesAndIntegrate; override;
    procedure CalcRates; override;

  published

    property Par_Cmin: TPar read Cmin write Cmin;
    property Par_Not_av_N: TPar read not_av_N write not_av_N;

    property Par_RootRad: TPar read RootRad write RootRad;
    property Var_MaxNuptake: TVar read MaxNUptake write MaxNUptake;
    property Var_ActNUptake: TVar read ActNUptake write ActNUptake;
    property Var_Massflow: TVar read MassFlow write MassFlow;

    property Ex_PlantNUptake: TExternV read Ex_PlantNDemand
      write Ex_PlantNDemand;
    property Ex_SRL: TExternV read SRL write SRL;
    property Ex_SRL_eff: TExternV read SRL_eff write SRL_eff;

    property St_SumSoilNUptake: TState read SumSoilNUptake write SumSoilNUptake;

  end;

procedure Register;

implementation

uses
  Math, SysUtils, UModUtils;

procedure TSoilNitrogenUp.CalcRatesAndIntegrate;

var
  SumImax { Sum of the maximum influx rates }
    : real;

  Max_uptake: TSoilArray;
  /// maximum N uptake rate in [kg N/(ha*d)] per layer
  Imax_arr: TSoilArray;
  /// maximum N influx rate in kg N/(cm*d) per layer
  Cl_min_arr: TSoilArray;
  /// Not available concentration of soil nitrate (sum of Cmin and not_av_N
  i: byte;
  actMaxNUptake: real;
  /// Maximum N uptake rate in the internal time step
  actMassFlow: real;
  /// Mass flow transport rate in the internal time step
  Sum_N_Nuptake: real;
  /// Sum of maximum N uptake rate in the internal time step

begin
  Sum_N_Nuptake := 0.0;
  actMaxNUptake := 0.0;
  actMassFlow := 0.0;
  SumImax := 0.0;

  for i := 0 to max_comp + 1 do
  begin
    Imax_arr[i] := 0.0;
    WInflux[i] := 0.0;
    Max_uptake[i] := 0.0;
  end;

  // calculation of maximum N uptake over all soil layers using the steady state
  // single root model approach of Baldwin/Kage

  if Exwld_arr[1].v > 0.0 then
  begin // Are roots present?
    for i := 1 to Max_Root_Index do
    begin
      if (Exwld_arr[i].v * Thick[i] > 1E-4) then
      begin
        // Accumulation of the mass flow over the internal time steps
        actMassFlow := actMassFlow + Sink_Arr[i].v * NConc[i].v;

        // calculation of the water influx per unit root length [cm3/cm/
        // Conversion of root length from cm/cm2 to cm/had]
        WInflux[i] := Sink_Arr[i].v / (Exwld_arr[i].v * Thick[i] * 1E8);
        Cl_min_arr[i] := not_av_N.v / WAmount[i].v + Cmin.v;
        // ar:  max_Wl_NupTake = physiological limitation of the N uptake per root length (Wl)
        // will be effective if time-step error is high (after N fertilization events)
        Imax_arr[i] := min(Max_Wl_Nuptake.v,
          max(0, Imax_f(NConc[i].v, Cl_min_arr[i], theta_arr[i].v, WInflux[i],
          Exwld_arr[i].v, RootRad.v)));
        SumImax := SumImax + Imax_arr[i];

        // calculation of maximum N uptake rate per soil layer
        // Imax is in g N / cm root / day in order to convert to kg N/ha/d
        // multiply by 1E8 (cm root/cm2 soil to cm root/ha soil) and by
        // Thick[i] (cm soil layer thickness) 
        Max_uptake[i] := Imax_arr[i] * Exwld_arr[i].v * Thick[i] * 1E8;
        // hkage 20.07.16: check if actual maximum N uptake rate would lead to negative N amounts
        // the value of 0.5 is abitrary ...
        // if (Max_uptake[i]/dt.v > (NitrateAmount[i].v))  then
        if (Max_uptake[i] > (NitrateAmount[i].v)) then
          Max_uptake[i] := 0.5 * NitrateAmount[i].v;
        // *dt.v; 09.09.2021 hk should also be stable this way

        // Conversion of root length from cm/cm2 to cm/ha
      end
      else
      begin
        Imax_arr[i] := 0.0;
        Max_uptake[i] := 0.0;
      end;
      // actMaxNUptake := actMaxNUptake + Max_uptake[i];
      // ar 06.06.16
      // limitation of the N uptake to the amount of availale N
      // actMaxNUptake := actMaxNUptake + min(Max_uptake[i],
      // max(0,(self.NMenge[i].v-self.not_av_N.v)));

      // hkage 20.7.16: above code could lead to incorrect N uptake after summing up
      actMaxNUptake := actMaxNUptake + Max_uptake[i];

    end;

    // distribution of N uptake over all layers ...
    if (actMaxNUptake >= fplantNDemand) and (actMaxNUptake > 0.0) then
    begin // If possible uptake > demand
      for i := 1 to Max_Root_Index do
      begin
        NUptake[i].v := -fplantNDemand * Max_uptake[i] / actMaxNUptake;

        // if(NUptake[i].v>(self.NMenge[i].v-self.not_av_N.v)) then
        // NUptake[i].v :=min(NUptake[i].v,(self.NMenge[i].v-self.not_av_N.v));
        // limitation of the N uptake to the amount of availale N
        // NUptake[i].v :=min(NUptake[i].v,(max(0,self.NMenge[i].v-self.not_av_N.v)));
        Sum_N_Nuptake := Sum_N_Nuptake + (-NUptake[i].v);
      end;
    end { Imax_arr[i]/sumImax }
    else
    begin
      for i := 1 to Max_Root_Index do
      begin
        NUptake[i].v := -Max_uptake[i];
        Sum_N_Nuptake := Sum_N_Nuptake + Max_uptake[i];
      end;
    end;
  end
  else
  begin // No uptake without roots
    for i := 1 to Max_Root_Index do
      NUptake[i].v := 0.0;
    Sum_N_Nuptake := 0.0;
  end;
  for i := 1 to n_comp do
    NSink[i].v := NUptake[i].v;

  inherited CalcRatesAndIntegrate;

  MaxNUptake.v := MaxNUptake.v + actMaxNUptake * dt.v;
  MassFlow.v := MassFlow.v + actMassFlow * dt.v;

  // the average N uptake rate per day (globtime.c) for plotting as a var
  ActNUptake.v := ActNUptake.v + Sum_N_Nuptake * dt.v;
  // the average N uptake rate per day (globtime.c) for plotting as a state variable
  SumSoilNUptake.c := ActNUptake.v;

  // the average N uptake rate per day (globtime.c) for plotting as a state in units of g/m2/d
  SoilNUptakeGrowth.c := ActNUptake.v / 10;

  if (SRL.v > 0.0) and (SRL_eff.v > 0.0) then
  begin
    NInflux_WL.v := ActNUptake.v * 1000 / 86400 / 14 / 1E8 / SRL.v;
    NInflux_WL_eff.v := ActNUptake.v * 1000 / 86400 / 14 / 1E8 / SRL_eff.v;
  end
  else
  begin
    NInflux_WL.v := 0.0;
    NInflux_WL_eff.v := 0.0;
  end;

end;

procedure TSoilNitrogenUp.CalcRates;

begin
  ActNUptake.v := 0.0;
  MaxNUptake.v := 0.0;
  MassFlow.v := 0.0;
  SumSoilNUptake.c := 0.0;
  SoilNUptakeGrowth.c := 0.0;
  SumPlantNDemand.c := 0.0;
  fplantNDemand := max(0, Ex_PlantNDemand.v * 10);
  // Conversion from g N/m2 to kg N/ha
  SumPlantNDemand.c := fplantNDemand;

  inherited CalcRates;
  { ActNUptake.v := ActNUptake.v/globtime.c;
    MaxNUptake.v := MaxNUptake.v/globtime.c;
    MassFlow.v   := MassFlow.v/globtime.c; }

end;

procedure TSoilNitrogenUp.CreateAll;

var
  i: integer;

begin
  inherited CreateAll;
  ParCreate('Cmin', '[kg N/cm]', 0.0, Cmin,
    'minimum nitrate concentration roots can deplete to');
  ParCreate('Not_av_N', '[kg N/10 cm]', 1.5, not_av_N,
    'non-available part of the soil nitrogen [kg N/10 cm]');
  ParCreate('RootRad', '[cm]', 0.02, RootRad, 'root radius');
  ParCreate('Max_Wl_Nuptake', '[kg/ha/d/Wl]', 3E-9, Max_Wl_Nuptake);
  // ExternVcreate('TotalPlantNitrogen', '[kg N.ha-1.d-1]',   RateField, NTotal);
  ExternVcreate('PlantNDemand', '[g.m-2.d-1]', stateField, Ex_PlantNDemand,
    'External plant N demand');
  StateCreate('SumPlantNDemand', '[kg.ha-1]', 0.0, false, SumPlantNDemand,
    'total sum of plant demand');

  StateCreate('SoilNUptakeGrowth', '[?]', 0.0, false, SoilNUptakeGrowth);
  ExternVcreate('SRL', '[cm.cm-2]', stateField, SRL, 'sum of root length');
  ExternVcreate('SRL_eff', '[cm.cm-2]', stateField, SRL_eff,
    'effective sum of root length');

  VarCreate('ActNUptake', '[kg.ha-1.d-1]', 0.0, false, ActNUptake,
    'the average N uptake rate per day (globtime.c) for plotting as a Var');
  VarCreate('MaxNUptake', '[kg.ha-1.d-1]', 0.0, false, MaxNUptake,
    'maximum possible N uptake per day');
  VarCreate('MassFlow', '[kg.ha-1.d-1]', 0.0, false, MassFlow,
    'apparent mass flow transport of nitrate to roots');
  StateCreate('SumSoilNuptake', '[kg.ha-1]', 0.0, false, SumSoilNUptake,
    'the average N uptake rate per day (globtime.c) for plotting as a state');
  VarCreate('NInflux_WL', '[kg.cm-1.d-1]', 0.0, false, NInflux_WL,
    'specific nitrate uptake per root length');
  VarCreate('NInflux_WL_eff', '[kg.cm-1.d-1]', 0.0, false, NInflux_WL_eff,
    'specific nitrate utpake per effective root length');

  for i := 1 to Max_Root_Index do
  begin
    VarCreate('NUptake' + ndx_str(i), '[kg.ha-1.d-1]', 0.0, false, NUptake[i]);
  end;
end;

procedure TSoilNitrogenUp.SetPlantModel(NewPlantModel: TAbstractplant);

begin
  inherited;
  if PlantModel <> nil then
  begin
    Ex_PlantNUptake.Search := false;
    Ex_PlantNDemand.f_v := @PlantModel.p_NUptakeRate.fv;
    Ex_PlantNDemand.Source := '[' + PlantModel.Name + ']';
    if PlantModel.withRoots then
    begin
      Ex_SRL.f_v := @PlantModel.p_SumRootLength.fv;
      Ex_SRL.Search := false;
      Ex_SRL.Source := '[' + PlantModel.Name + ']';
      Ex_SRL_eff.f_v := @PlantModel.p_SumRootLength_eff.fv;
      Ex_SRL_eff.Search := false;
      Ex_SRL_eff.Source := '[' + PlantModel.Name + ']';
    end;
  end;
end;

procedure Register;
begin

{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSoilNitrogenUp]);
{$ENDIF}
end;

end.
