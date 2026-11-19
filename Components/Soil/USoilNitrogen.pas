unit USoilNitrogen;

interface

uses
  UMod, UState, classes, USoilWaterMod, URootedSoil, ULayeredSoil,
  System.IniFiles;

type
  /// <summary>In-memory INI-file type used when transferring nitrate states to the next simulation.</summary>
  TMyIniFile = TMemInifile;

  /// <summary>Layered soil nitrate transport model coupled to root-zone water flow, mineralization inputs, uptake sinks, and nitrogen balances.</summary>
  TSoilNitrogen = class(TSoilWaterModelR)

  private
    /// <summary>Nitrate concentrations at the start of the internal transport step, in the same units as NConc.</summary>
    ConcOld: TSoilArray;
    /// <summary>Enables writing final nitrate amounts to the state file of the next configured simulation.</summary>
    fTransferNminss: boolean;

    /// <summary>Initial nitrate amount within the nitrogen-balance profile, in kg N/ha.</summary>
    NminStart: real;

    /// <summary>Nitrate fluxes evaluated during internal transport steps, in kg N/(ha d).</summary>
    NFlowInt: TSoilArray;

  protected

    /// <summary>Initializes nitrate concentrations, transport buffers, fluxes, and available layer source and sink variables.</summary>
    procedure InitSoilNVectors;

  public

    /// <summary>Nitrate-N amount in each soil compartment, in kg N/ha.</summary>
    NitrateAmount: TSoilStateArray;

    /// <summary>Nitrate-N concentration calculated as layer nitrate amount divided by layer water depth.</summary>
    /// <remarks>Internal units are (kg N/ha)/cm water depth; retain the area basis when converting to solution concentration.</remarks>
    NConc: TSoilVarArray;

    /// <summary>Signed nitrate source or sink rate for each layer, in kg N/(ha d); added to the transport balance.</summary>
    Nsink: TSoilVarArray;

    /// <summary>Net mineralization rate supplied to each layer, in kg N/(ha d).</summary>
    NetMin: TSoilVarArray;

    /// <summary>Nitrate transport accumulated across compartment interfaces during internal steps.</summary>
    NFlow: TSoilVarArray;

    /// <summary>Cumulative signed nitrate uptake contribution within the balance profile, in kg N/ha.</summary>
    CumSumUptake: TState;

    /// <summary>Cumulative net nitrate mineralization within the balance profile, in kg N/ha.</summary>
    CumSumMinera: TState;

    /// <summary>Cumulative nitrate leaching below the balance profile, in kg N/ha.</summary>
    CumSumNitrateLeaching: TState;

    /// <summary>Nitrate-N amount in the 0-10 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin0_10: TVar;
    /// <summary>Nitrate-N amount in the 0-30 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin0_30: TVar;
    /// <summary>Nitrate-N amount in the 30-60 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin30_60: TVar;
    /// <summary>Nitrate-N amount in the 60-90 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin60_90: TVar;
    /// <summary>Nitrate-N amount in the 90-120 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin90_120: TVar;
    /// <summary>Nitrate-N amount in the 0-90 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin0_90: TVar;
    /// <summary>Nitrate-N amount in the 0-60 cm depth interval for 10 cm compartments, in kg N/ha.</summary>
    Nmin0_60: TVar;
    /// <summary>Variable registered for the long-term computational nitrogen balance, in kg N/ha.</summary>
    LongTermNBalance: TVar;

    /// <summary>Computational nitrogen-balance residual accumulated over internal transport steps.</summary>
    DailyNBalance: TState;

    /// <summary>Cumulative computational nitrogen-balance state.</summary>
    TotalNBalance: TState;

    /// <summary>Total nitrate-N amount within the configured balance profile, in kg N/ha.</summary>
    SumNmin: TVar;

    /// <summary>Nitrate-leaching rate reported from accumulated internal-step fluxes, in kg N/(ha d).</summary>
    NitrateLeachingRate: TVar;

    /// <summary>Dispersivity used to calculate hydrodynamic dispersion, in cm.</summary>
    Dispersion_length: Tpar;

    /// <summary>Implicit weighting of the transport discretization; 0.5 gives equal old and new weighting, and 1 is fully implicit.</summary>
    Imp_factor: Tpar;

    /// <summary>Start and end times for optional restricted leaching accumulation; registered as day of year.</summary>
    LeachingStartDay, LeachingEndDay: Tpar;

    /// <summary>Selects whether leaching accumulation is restricted to the configured start and end times.</summary>
    SelectedLeachingPeriod: TOption;

    /// <summary>Optional groundwater nitrate concentration used for compartments below the active transport domain.</summary>
    Groundwaterconc: TExternV;
    /// <summary>Registers nitrate states, fluxes, balance variables, transport parameters, and leaching options.</summary>
    procedure CreateAll; override;
    /// <summary>Initializes nitrate transport variables and records the initial profile nitrate amount after inherited initialization.</summary>
    /// <param name="GlobMod">Global model providing simulation configuration and timing.</param>
    procedure Init(var GlobMod: Tmod); override;
    /// <summary>Advances soil water and solves one-dimensional nitrate convection and dispersion during an internal time step.</summary>
    procedure CalcRatesAndIntegrate; override;
    /// <summary>Resets internal-step accumulators, runs inherited rate calculations, and updates nitrate-leaching and balance rates.</summary>
    procedure CalcRates; override;
    /// <summary>Updates depth summaries, integrates model states, and optionally writes final nitrate amounts to the next simulation state file.</summary>
    procedure Integrate; override;
    /// <summary>Updates fixed-depth nitrate summaries using the compartment indices of a 10 cm soil-layer discretization.</summary>
    procedure update_Nmin_Values();

  published
    // property ShowWarnings  : boolean read Warnings write warnings;

    /// <summary>Published access to nitrate-N amount in the 0-10 cm depth interval.</summary>
    property Var_Nmin0_10: TVar read Nmin0_10 write Nmin0_10;
    /// <summary>Published access to nitrate-N amount in the 0-30 cm depth interval.</summary>
    property Var_Nmin0_30: TVar read Nmin0_30 write Nmin0_30;
    /// <summary>Published access to nitrate-N amount in the 30-60 cm depth interval.</summary>
    property Var_Nmin30_60: TVar read Nmin30_60 write Nmin30_60;
    /// <summary>Published access to nitrate-N amount in the 60-90 cm depth interval.</summary>
    property Var_Nmin60_90: TVar read Nmin60_90 write Nmin60_90;
    /// <summary>Published access to nitrate-N amount in the 90-120 cm depth interval.</summary>
    property Var_Nmin90_120: TVar read Nmin90_120 write Nmin90_120;
    /// <summary>Published access to nitrate-N amount in the 0-60 cm depth interval.</summary>
    property Var_Nmin0_60: TVar read Nmin0_60 write Nmin0_60;
    /// <summary>Published access to nitrate-N amount in the 0-90 cm depth interval.</summary>
    property Var_Nmin0_90: TVar read Nmin0_90 write Nmin0_90;
    /// <summary>Published access to the total nitrate amount in the balance profile.</summary>
    property Var_SumNmin: TVar read SumNmin write SumNmin;
    /// <summary>Published access to cumulative nitrate leaching.</summary>
    property Var_SumDrain: TState read CumSumNitrateLeaching
      write CumSumNitrateLeaching;
    /// <summary>Published access to the nitrate-leaching rate.</summary>
    property Var_DrainageNFlow: TVar read NitrateLeachingRate
      write NitrateLeachingRate;
    /// <summary>Published access to the long-term computational nitrogen-balance variable.</summary>
    property Var_NBalance: TVar read LongTermNBalance write LongTermNBalance;
    /// <summary>Published access to the daily computational nitrogen-balance state.</summary>
    property Var_DailyNBalance: TState read DailyNBalance write DailyNBalance;
    /// <summary>Published access to the implicit transport weighting parameter.</summary>
    property Par_Imp_factor: Tpar read Imp_factor write Imp_factor;
    /// <summary>Controls transfer of final nitrate amounts to the next configured simulation.</summary>
    property Opt_TransferNMinsToNextINI: boolean read fTransferNminss
      write fTransferNminss;

  end;

/// <summary>Registers the soil nitrate component on the Simulation palette in visual builds.</summary>
procedure Register;

// var
// SoilNitrogen: TSoilNitrogen;

implementation

uses
{$IFNDEF NONVISUAL}
  vcl.Dialogs,
{$ENDIF}
  SysUtils;

procedure TSoilNitrogen.update_Nmin_Values;
begin
  Nmin0_10.v := NitrateAmount[1].v;
  Nmin0_30.v := NitrateAmount[1].v + NitrateAmount[2].v + NitrateAmount[3].v;
  Nmin30_60.v := NitrateAmount[4].v + NitrateAmount[5].v + NitrateAmount[6].v;
  Nmin60_90.v := NitrateAmount[7].v + NitrateAmount[8].v + NitrateAmount[9].v;
  Nmin90_120.v := NitrateAmount[10].v + NitrateAmount[11].v +
    NitrateAmount[12].v;
  Nmin0_60.v := Nmin0_30.v + Nmin30_60.v;
  Nmin0_90.v := Nmin0_30.v + Nmin30_60.v + Nmin60_90.v;
end;

procedure TSoilNitrogen.CreateAll;
var
  i: integer;
begin
  inherited CreateAll;
  SetEntityDeclarationClass(TSoilNitrogen);
  VarCreate('SumNmin', '[kg N/ha]', 0.0, false, SumNmin,
    'Total soil mineral nitrate nitrogen');
  StateCreate('SumNitrateLeaching', '[kg N/ha]', 0.0, false,
    CumSumNitrateLeaching, 'Sum of leached Nitrate');
  StateCreate('CumSumUptake', '[kg N/ha]', 0.0, false, CumSumUptake,
    'Sum of Nitrate uptake by crop');
  StateCreate('CumSumMinera', '[kg N/ha]', 0.0, false, CumSumMinera,
    'Sum of mineralised Nitrate');
  StateCreate('Daily_NBal', '[kg N/ha/d]', 0.0, false, DailyNBalance,
    'daily computational N balance');
  StateCreate('Total_NBal', '[kg N/ha/d]', 0.0, false, TotalNBalance,
    'Total computational N balance');

  VarCreate('DrainageNFlow', '[kg N/ha/d]', 0.0, false, NitrateLeachingRate,
    'Daily nitrate-leaching rate');
  ParCreate('Dispersion length', '[cm]', 1.0, Dispersion_length,
    'Parameter for hydraulic dispersion');
  ParCreate('Imp_factor', '[-]', 0.5, Imp_factor,
    'Factor for implicitiness of calculation,' +
    ' 0.5 to 1 recommended, 1 has higher numerical stability');
  ParCreate('LeachingStartDay', '[doy]', 0, LeachingStartDay,
    'day when leaching sum calculation starts' +
    'works only if the option SelectedLeachingPeriod is set to true');
  ParCreate('LeachingEndDay', '[doy]', 1E9, LeachingEndDay,
    'day when leaching sum calculation ends');

  OptCreate('SelectedLeachingPeriod', 'false', SelectedLeachingPeriod,
    'Should Leaching sum be calculated only ' +
    'for a certain period given by the parameters LeachingStartDay and LeachingEndDay');
  SelectedLeachingPeriod.OptionList.Add('false');
  SelectedLeachingPeriod.OptionList.Add('true');

  VarCreate('Nmin0_10', '[kg N/ha]', 0.0, false, Nmin0_10, 'Nitrate in 0-10 cm depth');
  VarCreate('Nmin0_30', '[kg N/ha]', 0.0, false, Nmin0_30, 'Nitrate in 0-30 cm depth');
  VarCreate('Nmin30_60', '[kg N/ha]', 0.0, false, Nmin30_60, 'Nitrate in 30-60 cm depth');
  VarCreate('Nmin60_90', '[kg N/ha]', 0.0, false, Nmin60_90, 'Nitrate in 60-90 cm depth');
  VarCreate('Nmin90_120', '[kg N/ha]', 0.0, false, Nmin90_120, 'Nitrate in 90-120 cm depth');
  VarCreate('Nmin0_60', '[kg N/ha]', 0.0, false, Nmin0_60, 'Nitrate in 0-60 cm depth');
  VarCreate('Nmin0_90', '[kg N/ha]', 0.0, false, Nmin0_90, 'Nitrate in 0-90 cm depth');
  VarCreate('LT_NBal', '[kg N/ha]', 0.0, false, LongTermNBalance,
    'computational N balance of simulation');
  ExternVCreate('Groundwaterconc', '[kg NO3-N/cm H20]', StateField,
    Groundwaterconc,
    'optional external variable with groundwater nitrate concentration');

  Groundwaterconc.Search := (LowerBoundaryCondition = Groundwatertable);

  for i := 1 to n_comp + 1 do
  begin
    StateCreate('Nmin' + ndx_str(i), '[kg.ha-1]', 5.0, true, NitrateAmount[i],
      'Soil nitrate in layer ' + inttostr(i));
    VarCreate('NKonz' + ndx_str(i), '[kg NO3/cm H20]', 0.0, false, NConc[i],
      'Nitrate concentration in layer ' + inttostr(i));

    // NConc[i].writetofile := false;
    NConc[i].writetofile := true;
    VarCreate('NFlow' + ndx_str(i), '[kg.d-1]', 0.0, false, NFlow[i],
      'nitrate flow between layer ' + inttostr(i - 1) + ' and layer ' +
      inttostr(i));
  end;

  for i := 1 to n_comp do
  begin
    VarCreate('NSink' + ndx_str(i), '[kg N.ha-1.d-1]', 0.0, false, Nsink[i], 'Nitrate sink in layer ' + inttostr(i));
    VarCreate('NetMin' + ndx_str(i), '[kg N.ha-1.d-1]', 0.0, false, NetMin[i], 'Net mineralization in layer ' + inttostr(i));
  end;

  ShowWarnings := false;
  update_Nmin_Values;

  for i := 11 to n_comp + 1 do
    NitrateAmount[i].v := Nmin90_120.v / 3.0;

  for i := 1 to n_comp + 1 do
    theta_old[i] := theta_arr[i].v;

end;

procedure TSoilNitrogen.InitSoilNVectors;
var
  i: integer;

begin
  for i := 1 to n_comp + 1 do
  begin
    NConc[i].v := NitrateAmount[i].v / WAmount[i].v;
    ConcOld[i] := NConc[i].v;
    NFlow[i].v := 0.0;
    if Nsink[i] <> nil then
    begin
      Nsink[i].v := 0.0;
      NetMin[i].v := 0.0;
    end;
    self.ConcOld[i] := 0.0;
  end;
  NConc[n_comp + 1] := NConc[n_comp];

end;

procedure TSoilNitrogen.Init(var GlobMod: Tmod);
var
  i: integer;
begin
  inherited Init(GlobMod);
  self.InitSoilNVectors;
  CumSumNitrateLeaching.v := 0.0;
  update_Nmin_Values;
  LongTermNBalance.v := 0.0;
  DailyNBalance.v := 0.0;
  SumNmin.v := 0.0;
  for i := 1 to trunc(bil_nr.v) do
    SumNmin.v := SumNmin.v + NitrateAmount[i].v;
  NminStart := SumNmin.v;

end;

/// <summary>Calculates the effective nitrate diffusion coefficient from volumetric water content, in cm2/s.</summary>
/// <param name="b">Volumetric soil water content, in cm3/cm3.</param>
/// <returns>Water diffusion coefficient multiplied by tortuosity and water content; negative results are replaced by 1E-9.</returns>
function Dbf(b: real): real;

const
  /// <summary>Nitrate diffusion coefficient in water, in cm2/s.</summary>
  D0 = 1.92E-5;
var
  Db: real;
begin
  Db := D0 * (3.35 * b * b) * b;

  if (Db < 0) then
    Dbf := 1E-9
  else
    Dbf := Db;
end;

procedure TSoilNitrogen.CalcRatesAndIntegrate;

var
  /// <summary>Effective diffusion coefficients at the new time level, in cm2/d.</summary>
  Db_arr,
  /// <summary>Old effective diffusion and new hydrodynamic dispersion coefficients, in cm2/d.</summary>
  Db_alt, Dh_arr,
  /// <summary>Old hydrodynamic dispersion and new total dispersion coefficients, in cm2/d.</summary>
  Dh_alt, Ds_arr,
  /// <summary>Old total dispersion and new interface-average dispersion coefficients, in cm2/d.</summary>
  Ds_alt, avg_Ds,
  /// <summary>Old interface dispersion, transport-system right-hand side, weighted factors, matrix diagonals, and previous nitrate amounts.</summary>
  avg_Dsalt, B_vektor, Ds_fact, Ds_alt_fact, Flw_n_fact, flow_alt_fact, lower,
    diag, upper, NitrateAmountOld: TSoilArray;
  result, i: byte;

  /// <summary>Calculates nitrate flux between adjacent compartments by diffusion and mass flow.</summary>
  /// <param name="Cond">Interface dispersion coefficient, in cm2/d.</param>
  /// <param name="C_1">Nitrate concentration in the upper compartment, in internal concentration units.</param>
  /// <param name="C">Nitrate concentration in the lower compartment, in internal concentration units.</param>
  /// <param name="Abst">Distance between compartment centres, in cm.</param>
  /// <param name="FLW">Water flux in the soil-water model units.</param>
  /// <returns>Sum of the concentration-gradient flux and water flux multiplied by mean concentration.</returns>
  function Flow_f(Cond, C_1, C, Distance, FLW: real): real;

  var
    /// <summary>Diffusive component of the nitrate flux.</summary>
    Diff_flow,
    /// <summary>Advective component of the nitrate flux.</summary>
    Mass_flow
      : real;
  begin
    Diff_flow := Cond * (C_1 - C) / Distance;

    /// <summary>Advective component of the nitrate flux.</summary>
    // Mass_flow := FLW * sqrt(C * C_1);
    Mass_flow := FLW * (C + C_1) / 2;
    Flow_f := Diff_flow + Mass_flow;
  end;

  /// <summary>Calculates old and new effective diffusion and hydrodynamic dispersion coefficients and weighted interface factors.</summary>
  procedure Conductivities;

  var
    i: byte;
  begin
    for i := 1 to n_comp + 1 do
    begin
      Db_arr[i] := Dbf(theta_new[i]) * 86400.0;
      Db_alt[i] := Dbf(theta_old[i]) * 86400.0;
      if theta_new[i] > 0.0 then
      begin
        Dh_arr[i] := Dispersion_length.v * abs(Wflow_arr[i].v) / theta_new[i];
        Dh_alt[i] := Dispersion_length.v * abs(Wflow_old[i]) / theta_old[i];
      end
      else
      begin
        Dh_arr[i] := 0.0;
        Dh_alt[i] := 0.0;
      end;
      Ds_arr[i] := Db_arr[i] + Dh_arr[i];
      Ds_alt[i] := Db_alt[i] + Dh_alt[i];
    end;

    for i := 2 to n_comp + 1 do
    begin
      avg_Ds[i - 1] := (Ds_arr[i] + Ds_arr[i - 1]) / 2.0;
      avg_Dsalt[i - 1] := (Ds_alt[i] + Ds_alt[i - 1]) / 2.0;
      Ds_fact[i - 1] := avg_Ds[i - 1] / Dist[i - 1] * dt.v * Imp_factor.v;
      Ds_alt_fact[i - 1] := avg_Dsalt[i - 1] / Dist[i - 1] * dt.v *
        (1 - Imp_factor.v);
      Flw_n_fact[i] := Wflowint_arr[i].v * dt.v / 2 * Imp_factor.v;
      flow_alt_fact[i] := Wflow_old[i] * dt.v / 2 * (1 - Imp_factor.v);
    end;
  end;

  /// <summary>Assembles the upper boundary equation with zero external nitrate inflow and exchange with the second compartment.</summary>
  procedure upper_boundary;

  var
    inflow, outflow: real;

  begin
    inflow := 0.0;
    outflow := Flow_f(avg_Dsalt[1], ConcOld[1], ConcOld[2], Dist[1],
      Wflow_old[2]);
    B_vektor[1] := NitrateAmountOld[1] / WAmount[1].v + inflow * dt.v /
      WAmount[1].v - (1 - Imp_factor.v) * (outflow) * dt.v / WAmount[1].v +
      (Nsink[1].v + NetMin[1].v) * dt.v / WAmount[1].v;
    diag[1] := (Ds_fact[1] + Flw_n_fact[2]) / WAmount[1].v + 1.0;
    upper[1] := (-Ds_fact[1] + Flw_n_fact[2]) / WAmount[1].v;
  end;

  /// <summary>Assembles transport equations for interior soil compartments, including layer source and sink rates.</summary>
  procedure CalcMiddleLayers;
  var
    i: byte;
    inflow, outflow: real;
  begin
    for i := 2 to n_comp - 1 do
    begin
      inflow := Flow_f(avg_Dsalt[i - 1], ConcOld[i - 1], ConcOld[i],
        Dist[i - 1], Wflow_old[i]);
      outflow := Flow_f(avg_Dsalt[i], ConcOld[i], ConcOld[i + 1], Dist[i],
        Wflow_old[i + 1]);

      if WAmount[i].v < 1E-20 then
      begin
        if ShowWarnings then
{$IFNDEF NONVISUAL}
          showmessage('Error: WAmount_' + inttostr(i) + ' = 0');
{$ELSE}
          writeln('Error: WAmount_' + inttostr(i) + ' = 0');
{$ENDIF}
        if (i < (n_comp - 1)) then
        begin
          WAmount[i].v := 0.01;
          WAmount[i + 1].v := WAmount[i + 1].v - 0.01;
        end
        else if ShowWarnings then
{$IFNDEF NONVISUAL}
          showmessage('Error: WAmount_' + inttostr(i) + ' = 0');
{$ELSE}
          writeln('Error: WAmount_' + inttostr(i) + ' = 0')
{$ENDIF}
      end;

      B_vektor[i] := NitrateAmountOld[i] / WAmount[i].v + (1 - Imp_factor.v) *
        (inflow - outflow) * dt.v / WAmount[i].v + (Nsink[i].v + NetMin[i].v) *
        dt.v / WAmount[i].v;

      lower[i] := (-Ds_fact[i - 1] - Flw_n_fact[i]) / WAmount[i].v;
      diag[i] := (Ds_fact[i] + Ds_fact[i - 1] - Flw_n_fact[i] + Flw_n_fact
        [i + 1]) / WAmount[i].v + 1.0;
      upper[i] := (-Ds_fact[i] + Flw_n_fact[i + 1]) / WAmount[i].v;
    end;
  end;

  /// <summary>Assembles the lower boundary equation using the known concentration below the active transport domain.</summary>
  procedure Lower_boundary;

  var
    inflow, outflow: real;
    ncomp: integer;
  begin
    /// <remarks>The active compartment count may change with the groundwater level.</remarks>
    ncomp := act_n_comp;

    inflow := Flow_f(avg_Dsalt[ncomp - 1], ConcOld[ncomp - 1], ConcOld[ncomp],
      Dist[ncomp - 1], Wflow_old[ncomp]);
    outflow := Flow_f(avg_Dsalt[ncomp], ConcOld[ncomp], ConcOld[ncomp + 1],
      Dist[ncomp], Wflow_old[ncomp + 1]);

    B_vektor[ncomp] := NitrateAmountOld[ncomp] / WAmount[ncomp].v + Imp_factor.v
      * (inflow - outflow) * dt.v / WAmount[ncomp].v +
      (Nsink[ncomp].v + NetMin[ncomp].v) * dt.v / WAmount[ncomp].v +
      ConcOld[ncomp + 1] * (Ds_fact[ncomp] - Flw_n_fact[ncomp + 1]) /
      WAmount[ncomp].v;

    lower[ncomp] := (-Ds_fact[ncomp - 1] + Flw_n_fact[ncomp]) /
      WAmount[ncomp].v;
    diag[ncomp] := (Ds_fact[ncomp] + Ds_fact[ncomp - 1] - Flw_n_fact[ncomp]) /
      WAmount[ncomp].v + 1.0;

  end;

  /// <summary>Solves the tridiagonal transport system, clips negative concentrations, and assigns groundwater concentrations below the active domain.</summary>
  procedure Solve_equation_system;
  var
    i: byte;
  begin

    /// <remarks>Solve only the active transport compartments.</remarks>
    result := trdiag(false, act_n_comp, 1, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then
{$IFNDEF NONVISUAL}
        showmessage('Error solving the soil nitrate equation system!');
{$ELSE}
        writeln('Error solving the soil nitrate equation system!');
{$ENDIF}
    for i := 1 to act_n_comp do
    begin
      NConc[i].v := B_vektor[i];
      if NConc[i].v < 0.0 then
      begin
        if ShowWarnings then
{$IFNDEF NONVISUAL}
          showmessage('Negative nitrate concentration = ' + FloatToStrF(NConc[i].v,
            FFgeneral, 6, 3) + ' comp' + inttostr(i));
{$ELSE}
          writeln('Negative nitrate concentration = ' + FloatToStrF(NConc[i].v,
            FFgeneral, 6, 3) + ' comp' + inttostr(i));
{$ENDIF}
        NConc[i].v := 0.0;
      end;
    end;

    for i := act_n_comp + 1 to n_comp do
    begin
      NConc[i].v := Groundwaterconc.v;
    end;
  end;

  /// <summary>Calculates interface nitrate fluxes from old and new concentrations using the implicit weighting.</summary>
  procedure find_flows;
  var
    diff_flow_new, diff_flow_old, mass_flow_new, mass_flow_old: real;
    i: byte;
  begin
    for i := 2 to n_comp do
    begin
      diff_flow_old := avg_Dsalt[i - 1] * (ConcOld[i - 1] - ConcOld[i])
        / Dist[i];

      // mass_flow_alt := Wflow_old[i] * sqrt(ConcOld[i] * ConcOld[i - 1]);
      mass_flow_old := Wflow_old[i] * (ConcOld[i] + ConcOld[i - 1]) / 2;
      diff_flow_new := avg_Ds[i - 1] * (NConc[i - 1].v - NConc[i].v) / Dist[i];

      // mass_flow_new := WflowInt_arr[i].v * sqrt(NConc[i - 1].v * NConc[i].v);
      mass_flow_new := Wflowint_arr[i].v * (NConc[i - 1].v + NConc[i].v) / 2;
      NFlowInt[i] := (diff_flow_old + mass_flow_old) * (1 - Imp_factor.v) +
        (diff_flow_new + mass_flow_new) * Imp_factor.v;
    end;
    diff_flow_old := avg_Dsalt[n_comp] * (ConcOld[n_comp] - ConcOld[n_comp + 1])
      / Dist[n_comp];
    mass_flow_old := Wflow_old[n_comp + 1] *
      (ConcOld[n_comp + 1] + ConcOld[n_comp]) / 2;
    NFlowInt[n_comp + 1] := (diff_flow_old + mass_flow_old);
  end;

  /// <summary>Updates nitrate amounts, accumulated fluxes, leaching, uptake, mineralization, and computational balances.</summary>
  procedure UpdateDailySums;

  var
    i: byte;
    NewAmount, SumNminOld, DiffNmin,
    SumUptake, SumMinera: real;
    Net_flow: TSoilArray;
    ncomp: integer;

  begin
    ncomp := n_comp;
    SumNminOld := SumNmin.v;
    for i := 1 to n_comp do
    begin
      /// <remarks>Convert solution concentration to nitrate amount using the new layer water depth.</remarks>
      NewAmount := NConc[i].v * theta_new[i] * Thick[i];

      if NewAmount < 0.0 then
        NewAmount := 0.0;
      Net_flow[i] := (NitrateAmount[i].v - NewAmount) / dt.v +
        (Nsink[i].v + NetMin[i].v);
      NitrateAmount[i].v := NewAmount;
    end;

    // SumNminAlt := SumNmin.v;
    SumNmin.v := 0.0;
    SumUptake := 0.0;
    SumMinera := 0.0;
    for i := 1 to trunc(bil_nr.v) do
    begin
      SumUptake := SumUptake + Nsink[i].v;
      SumMinera := SumMinera + NetMin[i].v;
      SumNmin.v := SumNmin.v + NitrateAmount[i].v;
    end;

    for i := 1 to n_comp + 1 do
      NFlow[i].v := NFlow[i].v + NFlowInt[i] * dt.v;

    /// <remarks>Change in nitrate amount within the balance profile during this internal step.</remarks>
    DiffNmin := (SumNmin.v - SumNminOld);

    /// <remarks>Optionally restrict leaching accumulation to the selected time interval.</remarks>
    if lowercase(SelectedLeachingPeriod.Option) = 'true' then
    begin
      if (GlobTime.v >= LeachingStartDay.v) and (GlobTime.v < LeachingEndDay.v)
      then
        CumSumNitrateLeaching.C := CumSumNitrateLeaching.C +
          NFlowInt[trunc(bil_nr.v) + 1] * dt.v
      else
        CumSumNitrateLeaching.C := 0.0;
    end
    else
      CumSumNitrateLeaching.C := CumSumNitrateLeaching.C +
        NFlowInt[trunc(bil_nr.v) + 1] * dt.v;
    CumSumUptake.C := CumSumUptake.C + SumUptake * dt.v;
    CumSumMinera.C := CumSumMinera.C + SumMinera * dt.v;

    // LongTermNBalance.v := DiffNmin + SumNitrateLeaching.v - CumSumUptake - CumSumMinera;
    // DiffNmin := (SumNmin.v - NminOld);
    DailyNBalance.C := DailyNBalance.C + DiffNmin + NFlowInt
      [trunc(bil_nr.v) + 1] * dt.v - SumUptake * dt.v - SumMinera * dt.v;

    /// <remarks>Set equal concentrations across the lower boundary after updating the balance.</remarks>
    NConc[ncomp + 1].v := NConc[ncomp].v;
    NitrateAmount[ncomp + 1].v := NConc[ncomp + 1].v * WAmount[ncomp + 1].v;

  end;

begin
  for i := 1 to n_comp + 1 do
  begin
    NitrateAmountOld[i] := NitrateAmount[i].v;
    ConcOld[i] := NConc[i].v;
  end;

  inherited CalcRatesAndIntegrate;

  Conductivities;
  upper_boundary;
  CalcMiddleLayers;
  Lower_boundary;
  Solve_equation_system;
  find_flows;
  UpdateDailySums;

end;

procedure TSoilNitrogen.CalcRates;
var
  i: integer;
begin
  /// <remarks>Reset quantities accumulated during internal transport steps.</remarks>
  for i := 1 to n_comp + 1 do
    NFlow[i].v := 0.0;
  NitrateLeachingRate.v := 0.0;
  CumSumUptake.C := 0.0;
  CumSumMinera.C := 0.0;
  CumSumNitrateLeaching.C := 0.0;
  DailyNBalance.v := 0.0;
  DailyNBalance.C := 0.0;

  inherited CalcRates;
  NitrateLeachingRate.v := CumSumNitrateLeaching.C;
  TotalNBalance.C := DailyNBalance.C;
end;

procedure TSoilNitrogen.Integrate;

var
  NextINI, NextStateINI: TMyIniFile;
  // ndx_str : string;

  i: integer;
begin
  update_Nmin_Values;

  inherited Integrate;

  if Opt_TransferNMinsToNextINI and (GlobTime.v = GlobMod.Endtime) then
  begin
    if GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName)
      = GlobMod.IniFileNames.Count - 1 then
      exit;
    NextINI := TMyIniFile.create
      (GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf
      (GlobMod.ActIniFile.FileName) + 1], TEncoding.UTF8);

    // NextINI.Init(GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf
    // (GlobMod.ActIniFile.FileName) + 1]);
    NextStateINI := TMyIniFile.create(NextINI.ReadString('FileNames',
      'StateIniFN', ''), TEncoding.UTF8);
    // NextStateINI.Init(NextINI.ReadString('FileNames', 'StateIniFN', ''));

    for i := 1 to n_comp + 1 do
    begin
      NextStateINI.WriteString(self.Name, 'Nmin' + ndx_str(i),
        FloatToStrF(self.NitrateAmount[i].v, ffFixed, 9, 6));
    end;
    NextINI.Free;
    NextStateINI.Free;
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSoilNitrogen]);
{$ENDIF}
end;

end.
