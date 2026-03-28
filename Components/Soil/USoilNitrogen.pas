unit USoilNitrogen;

interface

uses
  UMod, UState, classes, USoilWaterMod, URootedSoil, ULayeredSoil,
  System.IniFiles;

type
  TMyIniFile = TMemInifile;

  TSoilNitrogen = class(TSoilWaterModelR)

  private
    ConcOld: TSoilArray;
    fTransferNminss: boolean;
    NminStart: real;
    /// nitrate amount in soil profile at simulation start [Kg N/ha]
    NFlowInt: TSoilArray;
    /// Nitratflüsse during internal time steps [Kg N/ha*d] ///

  protected
    procedure InitSoilNVectors;

  public
    /// <summary>
    /// Nitrat menge im Kompartiment [Kg N/ha]
    /// </summary>
    NitrateAmount: TSoilStateArray;

    /// <summary>
    /// Nitrate Concentration [Kg NO3-N/cm H2O]
    /// this unusual unit is the consequence of
    /// giving the amount of water in cm troughout the
    ///  classes of this class library
    ///  in order to convert to g N /l
    ///  multiply by 1000 -> from kg to g
    ///  multiply by 10000 x 10 from cm to l
    ///  -> multiply by 1e8
    /// </summary>
    NConc: TSoilVarArray;

    Nsink: TSoilVarArray;
    /// Sink term [Kg N/ha*d }
    NetMin: TSoilVarArray;
    /// Source term [Kg N/ha*d }
    NFlow: TSoilVarArray;
    /// Nitrate flows [Kg N/ha*d] }
    CumSumUptake: TState;
    /// cumulative sum of soil N uptake
    CumSumMinera: TState;
    /// cumulative sum of soil N mineralisation
    CumSumNitrateLeaching: TState;
    /// Sum of nitrate leaching
    Nmin0_10: TVar;
    Nmin0_30: TVar;
    Nmin30_60: TVar;
    Nmin60_90: TVar;
    Nmin90_120: TVar;
    Nmin0_90: TVar;
    Nmin0_60: TVar;
    LongTermNBalance: TVar;
    /// long term nitrogen computational balance
    DailyNBalance: TState;
    /// daily nitrogen computational balance
    TotalNBalance: TState;
    /// cumulative N balance
    SumNmin: TVar;
    /// Sum of Nmin-nitrate
    NitrateLeachingRate: TVar;
    /// Leachingrate as daily average
    Dispersion_length: Tpar;
    /// Dispersion length
    Imp_factor: Tpar;
    /// relative "implicitness" of calculation procedure
    LeachingStartDay, LeachingEndDay: Tpar;
    // start and end of cumulation period for leaching
    SelectedLeachingPeriod: TOption;
    /// Option for restricting Leaching accumulation to a certain period
    Groundwaterconc: TExternV;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;
    procedure CalcRatesAndIntegrate; override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure update_Nmin_Values();

  published
    // property ShowWarnings  : boolean read Warnings write warnings;
    property Var_Nmin0_10: TVar read Nmin0_10 write Nmin0_10;
    property Var_Nmin0_30: TVar read Nmin0_30 write Nmin0_30;
    property Var_Nmin30_60: TVar read Nmin30_60 write Nmin30_60;
    property Var_Nmin60_90: TVar read Nmin60_90 write Nmin60_90;
    property Var_Nmin90_120: TVar read Nmin90_120 write Nmin90_120;
    property Var_Nmin0_60: TVar read Nmin0_60 write Nmin0_60;
    property Var_Nmin0_90: TVar read Nmin0_90 write Nmin0_90;
    property Var_SumNmin: TVar read SumNmin write SumNmin;
    property Var_SumDrain: TState read CumSumNitrateLeaching
      write CumSumNitrateLeaching;
    property Var_DrainageNFlow: TVar read NitrateLeachingRate
      write NitrateLeachingRate;
    property Var_NBalance: TVar read LongTermNBalance write LongTermNBalance;
    property Var_DailyNBalance: TState read DailyNBalance write DailyNBalance;
    property Par_Imp_factor: Tpar read Imp_factor write Imp_factor;
    property Opt_TransferNMinsToNextINI: boolean read fTransferNminss
      write fTransferNminss;

  end;

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
  VarCreate('SumNmin', '[kg N/ha]', 0.0, false, SumNmin,
    'Summe des Nmin-Stickstoffs');
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

  VarCreate('Nmin0_10', '[kg N/ha]', 0.0, false, Nmin0_10);
  VarCreate('Nmin0_30', '[kg N/ha]', 0.0, false, Nmin0_30);
  VarCreate('Nmin30_60', '[kg N/ha]', 0.0, false, Nmin30_60);
  VarCreate('Nmin60_90', '[kg N/ha]', 0.0, false, Nmin60_90);
  VarCreate('Nmin90_120', '[kg N/ha]', 0.0, false, Nmin90_120);
  VarCreate('Nmin0_60', '[kg N/ha]', 0.0, false, Nmin0_60);
  VarCreate('Nmin0_90', '[kg N/ha]', 0.0, false, Nmin0_90);
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
    VarCreate('NSink' + ndx_str(i), '[kg N.ha-1.d-1]', 0.0, false, Nsink[i]);
    VarCreate('NetMin' + ndx_str(i), '[kg N.ha-1.d-1]', 0.0, false, NetMin[i]);
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

function Dbf(b: real): real;
{ Berechnung des effektiven Diffusionskoeffizienten von Nitrat in
  der Bodenlösung }
const
  D0 = 1.92E-5; // Diffusionskoeffizient in Wasser [cm2.s-1]
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

//

{ ********************************************************************** }
{ Zweck :   Lösung der eindimensionalen Diffusions-, Konvektionsgleichung
  zur Verlagerung Nicht-Wechselwirkender Ionen ohne Berücksichtigung
  von Anionenausschluss oder immobilen Wasser }

{ Parameter :

  Name             Inhalt                          Einheit      Typ

  n_comp           Zahl der Kompartimente           [-]          I
  dt               Zeitschrittweite                 [d]          I
  w_rec            Record mit den Wasserdaten                    I
  ( siehe Typdefinitionen )
  geo_rec          Record mit den Geometriedaten                 I
  n_rec            Record mit den Stickstoffdaten                I/O }

{ ********************************************************************** }

var
  Db_arr, { effektive Diffusionskoeffizienten [cm2/d] }
  Db_alt, Dh_arr, { Hydrodynamische Dispersionskoeffizienten [cm2/d] }
  Dh_alt, Ds_arr, { scheinbarer Diffusionskoeffizient [cm2/d] }
  Ds_alt, avg_Ds, { mittlerer scheinbarer Diffusionskoeffizient }
  avg_Dsalt, B_vektor, Ds_fact, Ds_alt_fact, Flw_n_fact, flow_alt_fact, lower,
    diag, upper, NitrateAmountOld: TSoilArray;
  result, i: byte;

  function Flow_f(Cond, C_1, C, Abst, FLW: real): real;

  { Funktion zur Berechnung des Flusses durch Diffusion und Massenfluss
    zwischen zwei Kompartimenten

    Parameter            Bedeutung                    Einheit
    Cond                 Dispersionskoeffizient       [cm2/d]
    C                    Konzentration unt.Komp.      [kg/mm]
    C_1                  Konzentration im
    oberen        Kompartiment   [kg/mm]
    Abst                 Abstand der Kompartiment-
    mittelpunkte                 [cm]
    FlW                  Wasserfluss                  [mm/d]
  }

  var
    Diff_flow, { Fluß durch Diffusion }
    Mass_flow { Fluß durch Massenfluß }
      : real;
  begin
    Diff_flow := Cond * (C_1 - C) / Abst;
    // Mass_flow := FLW * sqrt(C * C_1);
    Mass_flow := FLW * (C + C_1) / 2;
    Flow_f := Diff_flow + Mass_flow;
  end;

  procedure Leitfaehigkeiten;

  { Berechnung der scheinbaren Diffusionskoeffizienten }

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

  procedure obere_Randbedingung;

  { Berechnung der oberen Randbedingung, wobei in der hier dargestellten
    Form ein bekannter Nitratfluss in das erste Kompartiment angenommen wird,
    der durch geeignete Werte der Variable Flow[1] berücksichtigt wird }

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

  procedure Mittelteil;
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
          showmessage('Fehler: WAmount_' + inttostr(i) + ' = 0');
{$ELSE}
          writeln('Fehler: WAmount_' + inttostr(i) + ' = 0');
{$ENDIF}
        if (i < (n_comp - 1)) then
        begin
          WAmount[i].v := 0.01;
          WAmount[i + 1].v := WAmount[i + 1].v - 0.01;
        end
        else if ShowWarnings then
{$IFNDEF NONVISUAL}
          showmessage('Fehler: WAmount_' + inttostr(i) + ' = 0');
{$ELSE}
          writeln('Fehler: WAmount_' + inttostr(i) + ' = 0')
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

  procedure untere_Randbedingung;
  { Berechnung der unteren Randbedingung, Annahme einer
    bekannten Konzentration am unteren Rand (Kompartiment[n_comp+1]) }

  var
    inflow, outflow: real;
    ncomp: integer;
  begin
    ncomp := act_n_comp;
    // in case of groundwater number of calculated comps may change
    // calculation of the flows from known old concentrations
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

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
  begin
    // Änderung n_comp -> act_n_comp (ckluss)
    result := trdiag(false, act_n_comp, 1, lower, diag, upper, B_vektor);
    if result <> 0 then
      if ShowWarnings then
{$IFNDEF NONVISUAL}
        showmessage('Fehler Lösung Gleichungsystem NSoil!');
{$ELSE}
        writeln('Fehler Lösung Gleichungsystem NSoil!');
{$ENDIF}
    for i := 1 to act_n_comp do
    begin
      NConc[i].v := B_vektor[i];
      if NConc[i].v < 0.0 then
      begin
        if ShowWarnings then
{$IFNDEF NONVISUAL}
          showmessage('Negative N-Konzentration = ' + FloatToStrF(NConc[i].v,
            FFgeneral, 6, 3) + ' comp' + inttostr(i));
{$ELSE}
          writeln('Negative N-Konzentration = ' + FloatToStrF(NConc[i].v,
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

  procedure find_flows;
  var
    diff_flow_new, diff_flow_alt, mass_flow_new, mass_flow_alt: real;
    i: byte;
  begin
    for i := 2 to n_comp do
    begin
      diff_flow_alt := avg_Dsalt[i - 1] * (ConcOld[i - 1] - ConcOld[i])
        / Dist[i];
      // mass_flow_alt := Wflow_old[i] * sqrt(ConcOld[i] * ConcOld[i - 1]);
      mass_flow_alt := Wflow_old[i] * (ConcOld[i] + ConcOld[i - 1]) / 2;
      diff_flow_new := avg_Ds[i - 1] * (NConc[i - 1].v - NConc[i].v) / Dist[i];
      // mass_flow_new := WflowInt_arr[i].v * sqrt(NConc[i - 1].v * NConc[i].v);
      mass_flow_new := Wflowint_arr[i].v * (NConc[i - 1].v + NConc[i].v) / 2;
      NFlowInt[i] := (diff_flow_alt + mass_flow_alt) * (1 - Imp_factor.v) +
        (diff_flow_new + mass_flow_new) * Imp_factor.v;
    end;
    diff_flow_alt := avg_Dsalt[n_comp] * (ConcOld[n_comp] - ConcOld[n_comp + 1])
      / Dist[n_comp];
    mass_flow_alt := Wflow_old[n_comp + 1] *
      (ConcOld[n_comp + 1] + ConcOld[n_comp]) / 2;
    NFlowInt[n_comp + 1] := (diff_flow_alt + mass_flow_alt);
  end;

  procedure UpdateDailySums;
  // updating daily sums of flows during iteration calcrates and integrate

  var
    i: byte;
    NewAmount, SumNminOld, DiffNmin, // Bilanz,
    SumUptake, SumMinera: real;
    Net_flow: TSoilArray;
    ncomp: integer;

  begin
    ncomp := n_comp;
    SumNminOld := SumNmin.v;
    for i := 1 to n_comp do
    begin
      NewAmount := NConc[i].v * theta_new[i] * Thick[i];
      // new nitrate amount from concentration and water amount
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

    DiffNmin := (SumNmin.v - SumNminOld); // change rate of soil mineral nitrate
    // Leaching can be calculated for only certain time periods hk 2023/08/18
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

    // einstellen einer gleichen Konzentration
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

  Leitfaehigkeiten;
  obere_Randbedingung;
  Mittelteil;
  untere_Randbedingung;
  Loesung_Gleichungssystem;
  find_flows;
  UpdateDailySums;

end;

procedure TSoilNitrogen.CalcRates;
var
  i: integer;
begin
  // set values which are derived from cumulation during internal iteration to zero
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
