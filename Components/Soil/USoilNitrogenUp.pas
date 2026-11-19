unit USoilNitrogenUp;

interface

uses
  UMod, UlayeredSoil, USoilNitrogen, UState, UAbstractPlant, URootUptakeFunctions,
  classes;

const
  /// <summary>Maximum soil-layer index used for root nitrate uptake calculations.</summary>
  Max_Root_Index = 20;

type

  /// <summary>Soil nitrate transport and root uptake model in which actual uptake is limited by plant demand and maximum nitrate supply.</summary>
  /// <remarks>Extends TSoilNitrogen and requires plant demand and root-distribution inputs. Maximum supply uses the quasi-steady single-root transport approach.</remarks>
  TSoilNitrogenUp = class(TSoilNitrogen)

  private
    /// <summary>Non-negative plant nitrogen demand converted to kg N/(ha d).</summary>
    fplantNDemand: real;

  protected
    /// <summary>Links plant nitrogen demand and, when present, total and effective root-length inputs to the coupled plant model.</summary>
    /// <param name="NewPlantModel">Plant model to link through the inherited coupling mechanism.</param>
    procedure SetPlantModel(NewPlantModel: TAbstractplant); override;

  public

    /// <summary>Actual nitrate uptake accumulated over internal steps using dt, reported in kg N/(ha d).</summary>
    ActNUptake: TVar;

    /// <summary>Maximum nitrate uptake accumulated over internal steps using dt, reported in kg N/(ha d).</summary>
    MaxNUptake: TVar;

    /// <summary>Apparent nitrate transport to roots by water uptake, accumulated over internal steps and reported in kg N/(ha d).</summary>
    MassFlow: TVar;

    /// <summary>Layer-specific nitrate uptake sinks, in kg N/(ha d); uptake is stored as a negative value.</summary>
    NUptake: TSoilVarArray;

    /// <summary>Layer-specific water influx per unit root length in internal area-scaled units used by Imax_f.</summary>
    /// <remarks>The root length denominator includes 1E8 cm2/ha; Imax_f multiplies this input by 1E8 to recover physical water influx per unit root length.</remarks>
    WInflux: TSoilArray;

    /// <summary>Nitrate influx normalized by total root length; the calculation converts uptake to mol N/(cm root s).</summary>
    NInflux_WL: TVar;

    /// <summary>Nitrate influx normalized by effective root length; the calculation converts uptake to mol N/(cm root s).</summary>
    /// <remarks>The registered unit label is kg/(cm d), which differs from the conversion performed by the current calculation.</remarks>
    NInflux_WL_eff: TVar;

    /// <summary>Cumulative soil nitrogen uptake state, in kg N/ha; its rate is assigned from ActNUptake.</summary>
    SumSoilNUptake: TState;

    /// <summary>Soil nitrogen uptake state whose rate is assigned in g N/(m2 d) from ActNUptake divided by 10.</summary>
    SoilNUptakeGrowth: TState;

    /// <summary>Cumulative plant nitrogen demand state, in kg N/ha.</summary>
    SumPlantNDemand: TState;

    /// <summary>Minimum nitrate concentration that roots can deplete to, expressed in the internal units used by NConc.</summary>
    Cmin: TPar;

    /// <summary>Unavailable nitrate amount subtracted through the layer concentration threshold; registered in kg N per 10 cm soil layer.</summary>
    not_av_N: TPar;

    /// <summary>Physiological upper limit on nitrate influx per unit root length, applied to the result of Imax_f.</summary>
    Max_Wl_Nuptake: TPar;

    // NTotal       : TExternV;
    /// <summary>External plant nitrogen demand, in g N/(m2 d).</summary>
    Ex_PlantNDemand: TExternV;

    /// <summary>Total root length per unit ground area, in cm root/cm2 soil.</summary>
    SRL: TExternV;

    /// <summary>Effective root length per unit ground area, in cm root/cm2 soil.</summary>
    SRL_eff: TExternV;

    /// <summary>Registers uptake parameters, external plant inputs, cumulative states, and layer uptake variables.</summary>
    procedure CreateAll; override;
    /// <summary>Calculates layer uptake capacities, allocates demand, passes uptake sinks to nitrate transport, and accumulates uptake outputs.</summary>
    procedure CalcRatesAndIntegrate; override;
    /// <summary>Resets uptake accumulators, converts plant demand to internal area units, and runs inherited rate calculations.</summary>
    procedure CalcRates; override;

  published

    /// <summary>Published access to the minimum available nitrate concentration.</summary>
    property Par_Cmin: TPar read Cmin write Cmin;
    /// <summary>Published access to the unavailable nitrate amount per soil layer.</summary>
    property Par_Not_av_N: TPar read not_av_N write not_av_N;

    /// <summary>Published access to the maximum nitrate uptake output.</summary>
    property Var_MaxNuptake: TVar read MaxNUptake write MaxNUptake;
    /// <summary>Published access to the actual nitrate uptake output.</summary>
    property Var_ActNUptake: TVar read ActNUptake write ActNUptake;
    /// <summary>Published access to apparent mass-flow transport of nitrate to roots.</summary>
    property Var_Massflow: TVar read MassFlow write MassFlow;

    /// <summary>Published access to the external plant nitrogen-demand input.</summary>
    property Ex_PlantNUptake: TExternV read Ex_PlantNDemand
      write Ex_PlantNDemand;
    /// <summary>Published access to total root length per unit ground area.</summary>
    property Ex_SRL: TExternV read SRL write SRL;
    /// <summary>Published access to effective root length per unit ground area.</summary>
    property Ex_SRL_eff: TExternV read SRL_eff write SRL_eff;

    /// <summary>Published access to the cumulative soil nitrogen uptake state.</summary>
    property St_SumSoilNUptake: TState read SumSoilNUptake write SumSoilNUptake;

  end;

/// <summary>Registers the soil nitrate uptake component on the Simulation palette in visual builds.</summary>
procedure Register;

implementation

uses
  Math, SysUtils, UModUtils;

procedure TSoilNitrogenUp.CalcRatesAndIntegrate;

var
  /// <summary>Sum of maximum influx rates per unit root length across rooted layers; not used in the final demand allocation.</summary>
  SumImax: real;
  /// <summary>Maximum nitrate uptake capacity of each layer, in kg N/(ha d), after the availability safeguard.</summary>
  Max_uptake: TSoilArray;
  /// <summary>Maximum nitrate influx per unit root length for each layer, in the internal units returned by Imax_f.</summary>
  Imax_arr: TSoilArray;
  /// <summary>Minimum accessible solution concentration, computed as unavailable layer nitrate divided by water depth plus Cmin.</summary>
  Cl_min_arr: TSoilArray;
  /// <summary>Soil-layer iteration index.</summary>
  i: byte;
  /// <summary>Total maximum nitrate uptake rate during the internal time step, in kg N/(ha d).</summary>
  actMaxNUptake: real;
  /// <summary>Total apparent mass-flow nitrate supply during the internal time step, in kg N/(ha d).</summary>
  actMassFlow: real;
  /// <summary>Total actual nitrate uptake rate after demand allocation, in kg N/(ha d).</summary>
  Sum_N_Nuptake: real;

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

  /// <remarks>Calculate maximum uptake across soil layers using the quasi-steady single-root approach of Baldwin/Kage.</remarks>

  if Exwld_arr[1].v > 0.0 then
  begin
    /// <remarks>The first layer is used to test whether roots are present.</remarks>
    for i := 1 to Max_Root_Index do
    begin
      if (Exwld_arr[i].v * Thick[i] > 1E-4) then
      begin
        /// <remarks>Sum nitrate carried toward roots by water uptake; time integration follows below.</remarks>
        actMassFlow := actMassFlow + Sink_Arr[i].v * NConc[i].v;

        /// <remarks>Divide layer water uptake by root length per hectare; 1E8 converts cm2 to ha in the root-length denominator.</remarks>
        WInflux[i] := Sink_Arr[i].v / (Exwld_arr[i].v * Thick[i] * 1E8);
        Cl_min_arr[i] := not_av_N.v / WAmount[i].v + Cmin.v;
        /// <remarks>Apply the physiological influx cap, including when large concentration changes follow fertilizer events.</remarks>
        Imax_arr[i] := min(Max_Wl_Nuptake.v,
          max(0, Imax_f(NConc[i].v, Cl_min_arr[i], theta_arr[i].v, WInflux[i],
          Exwld_arr[i].v, RootRad.v)));
        SumImax := SumImax + Imax_arr[i];

        /// <remarks>Convert influx per unit root length to layer uptake using root length density, layer thickness, and 1E8 cm2/ha.</remarks>
        Max_uptake[i] := Imax_arr[i] * Exwld_arr[i].v * Thick[i] * 1E8;
        /// <remarks>If uptake capacity exceeds the stored layer nitrate amount, replace it with half that amount as an empirical availability safeguard.</remarks>
        // if (Max_uptake[i]/dt.v > (NitrateAmount[i].v))  then
        if (Max_uptake[i] > (NitrateAmount[i].v)) then
          Max_uptake[i] := 0.5 * NitrateAmount[i].v;
        /// <remarks>The current safeguard does not multiply or divide the comparison by dt.</remarks>

      end
      else
      begin
        Imax_arr[i] := 0.0;
        Max_uptake[i] := 0.0;
      end;
      // actMaxNUptake := actMaxNUptake + Max_uptake[i];
      /// <remarks>The disabled alternative below attempted to limit uptake to available layer nitrogen.</remarks>
      // actMaxNUptake := actMaxNUptake + min(Max_uptake[i],
      // max(0,(self.NMenge[i].v-self.not_av_N.v)));

      /// <remarks>Sum the safeguarded layer capacities directly; the disabled alternative could produce an incorrect total.</remarks>
      actMaxNUptake := actMaxNUptake + Max_uptake[i];

    end;

    /// <remarks>Allocate actual uptake among layers according to maximum layer supply.</remarks>
    if (actMaxNUptake >= fplantNDemand) and (actMaxNUptake > 0.0) then
    begin
      /// <remarks>When supply meets demand, scale layer uptake capacities to plant demand.</remarks>
      for i := 1 to Max_Root_Index do
      begin
        NUptake[i].v := -fplantNDemand * Max_uptake[i] / actMaxNUptake;

        // if(NUptake[i].v>(self.NMenge[i].v-self.not_av_N.v)) then
        // NUptake[i].v :=min(NUptake[i].v,(self.NMenge[i].v-self.not_av_N.v));
        /// <remarks>The disabled alternative limits layer uptake to available nitrate.</remarks>
        // NUptake[i].v :=min(NUptake[i].v,(max(0,self.NMenge[i].v-self.not_av_N.v)));
        Sum_N_Nuptake := Sum_N_Nuptake + (-NUptake[i].v);
      end;
    end
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
  begin
    /// <remarks>No nitrate uptake is assigned when roots are absent.</remarks>
    for i := 1 to Max_Root_Index do
      NUptake[i].v := 0.0;
    Sum_N_Nuptake := 0.0;
  end;
  for i := 1 to n_comp do
    NSink[i].v := NUptake[i].v;

  inherited CalcRatesAndIntegrate;

  MaxNUptake.v := MaxNUptake.v + actMaxNUptake * dt.v;
  MassFlow.v := MassFlow.v + actMassFlow * dt.v;

  /// <remarks>Accumulate actual uptake over internal steps for the reported uptake variable.</remarks>
  ActNUptake.v := ActNUptake.v + Sum_N_Nuptake * dt.v;
  /// <remarks>Use the accumulated uptake output as the rate of the cumulative uptake state.</remarks>
  SumSoilNUptake.c := ActNUptake.v;

  /// <remarks>Convert the uptake rate from kg N/(ha d) to g N/(m2 d) for the growth-related uptake state.</remarks>
  SoilNUptakeGrowth.c := ActNUptake.v / 10;

  /// <remarks>Convert kg N/(ha d) to mol N/(cm root s) using 1000 g/kg, 86400 s/d, 14 g/mol N, and 1E8 cm2/ha.</remarks>
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
  /// <remarks>Convert external demand from g N/(m2 d) to kg N/(ha d), excluding negative demand.</remarks>
  fplantNDemand := max(0, Ex_PlantNDemand.v * 10);
  SumPlantNDemand.c := fplantNDemand;

  inherited CalcRates;
  { ActNUptake.v := ActNUptake.v/globtime.c;
    MaxNUptake.v := MaxNUptake.v/globtime.c;
    MassFlow.v   := MassFlow.v/globtime.c; }

end;

procedure TSoilNitrogenUp.CreateAll;

var
  /// <summary>Soil-layer iteration index used to register uptake variables.</summary>
  i: integer;

begin
  inherited CreateAll;
  SetEntityDeclarationClass(TSoilNitrogenUp);
  ParCreate('Cmin', '[kg N/cm]', 0.0, Cmin,
    'minimum nitrate concentration roots can deplete to');
  ParCreate('Not_av_N', '[kg N/10 cm]', 1.5, not_av_N,
    'non-available part of the soil nitrogen [kg N/10 cm]');
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
  VarCreate('NInflux_WL', '[mol.cm-1.d-1]', 0.0, false, NInflux_WL,
    'specific nitrate uptake per root length');
  VarCreate('NInflux_WL_eff', '[mol.cm-1.d-1]', 0.0, false, NInflux_WL_eff,
    'specific nitrate utpake per effective root length');

  for i := 1 to Max_Root_Index do
  begin
    VarCreate('NUptake' + ndx_str(i), '[kg.ha-1.d-1]', 0.0, false, NUptake[i], 
      'Nitrate uptake in layer ' + inttostr(i));
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
