unit USoilNitrogen;

interface

uses
  UMod, UState, classes, USoilWaterMod, URootedSoil, ULayeredSoil, IniFilesNew;

type

  TSoilNitrogen = class(TSoilWaterModelR)

  private
    konz_alt: TSoilArray;
    fTransferNminss : boolean;
  protected

  public
    NMenge: TSoilStateArray; /// Nitratmenge im Kompartiment [Kg N/ha]
    Nkonz: TSoilVarArray;    /// Nitratkonzentration [Kg NO3-N/cm H2O]
    Nsink: TSoilVarArray;    /// Senkenterm [Kg N/ha*d }
    NetMin: TSoilVarArray;   /// Quellenterm [Kg N/ha*d }
    NFlow: TSoilVarArray;    /// Nitratflüsse [Kg N/ha*d] }
    Nmin0_10 : TVar;
    Nmin0_30: TVar;
    Nmin30_60: TVar;
    Nmin60_90: TVar;
    Nmin90_120: TVar;
    Nmin0_90: TVar;
    Nmin0_60: TVar;
    LongTermNBalance: TVar;
    SumNmin: Tvar; /// Summe des Nmin-Stickstoffs
    SumDrain: Tvar; /// Summe der Auswaschung
    DrainageNFlow: TVar; /// Auswaschungsrate im Mittel des Tages
    Dispersion_length: Tpar; /// Dispersionslänge
    Imp_factor: TPar; /// relative "implicitness" of calculation procedure
    Groundwaterconc: TExternV;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;
    procedure CalcRatesAndIntegrate; override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure update_Nmin_Values();
  published
//property ShowWarnings  : boolean read Warnings write warnings;
    property Var_Nmin0_10: TVar read Nmin0_10 write Nmin0_10;
    property Var_Nmin0_30: TVar read Nmin0_30 write Nmin0_30;
    property Var_Nmin30_60: TVar read Nmin30_60 write Nmin30_60;
    property Var_Nmin60_90: TVar read Nmin60_90 write Nmin60_90;
    property Var_Nmin90_120: TVar read Nmin90_120 write Nmin90_120;
    property Var_Nmin0_60: TVar read Nmin0_60 write Nmin0_60;
    property Var_Nmin0_90: TVar read Nmin0_90 write Nmin0_90;
    property Var_SumNmin: TVar read SumNmin write SumNmin;
    property Var_SumDrain: TVar read SumDrain write SumDrain;
    property Var_DrainageNFlow: TVar read DrainageNFlow write DrainageNFlow;
    property Var_NBalance: TVar read LongTermNBalance write LongTermNBalance;
    property Par_Imp_factor: TPar read Imp_factor write Imp_factor;
    property Opt_TransferNMinsToNextINI
      : boolean read fTransferNminss write fTransferNminss;

  end;

procedure Register;

var
  SoilNitrogen: TSoilNitrogen;

implementation

uses
  SysUtils, Dialogs;

procedure TSoilNitrogen.update_Nmin_Values;
begin
  Nmin0_10.v := Nmenge[1].v;
  Nmin0_30.v := Nmenge[1].v + Nmenge[2].v + Nmenge[3].v;
  Nmin30_60.v := Nmenge[4].v + Nmenge[5].v + Nmenge[6].v;
  Nmin60_90.v := Nmenge[7].v + Nmenge[8].v + Nmenge[9].v;
  Nmin90_120.v := Nmenge[10].v + Nmenge[11].v + Nmenge[12].v;
  Nmin0_60.v := Nmin0_30.v + Nmin30_60.v;
  Nmin0_90.v := Nmin0_30.v + Nmin30_60.v + Nmin60_90.v;
end;

procedure TSoilnitrogen.createAll;
var
  i: integer;
begin
  inherited CreateAll;
  VarCreate('SumNmin', '[kg N/ha]', 0.0, false, SumNmin,
    'Summe des Nmin-Stickstoffs');
  VarCreate('SumDrain', '[kg N/ha]', 0.0, false, SumDrain,
    'Summe des AusgewaschenenStickstoffs');
  VarCreate('DrainageNFlow', '[kg N/ha/d]', 0.0, false, DrainageNFlow,
    'Täglich N-Auswaschungsrate');
  ParCreate('Dispersion length', '[cm]', 1.0, Dispersion_length);
  ParCreate('Imp_factor', '[-]', 0.5, Imp_factor);
  VarCreate('Nmin0_10', '[kg N/ha]', 0.0, false, Nmin0_10);
  VarCreate('Nmin0_30', '[kg N/ha]', 0.0, false, Nmin0_30);
  VarCreate('Nmin30_60', '[kg N/ha]', 0.0, false, Nmin30_60);
  VarCreate('Nmin60_90', '[kg N/ha]', 0.0, false, Nmin60_90);
  VarCreate('Nmin90_120', '[kg N/ha]', 0.0, false, Nmin90_120);
  VarCreate('Nmin0_60', '[kg N/ha]', 0.0, false, Nmin0_60);
  VarCreate('Nmin0_90', '[kg N/ha]', 0.0, false, Nmin0_90);
  VarCreate('LT_NBal', '[kg N/ha]', 0.0, false, LongTermNBalance);
  ExternVCreate('Groundwaterconc', '[kg NO3-N/cm H20]', StateField,
    Groundwaterconc);

  Groundwaterconc.Search := (LowerBoundaryCondition = Groundwatertable);

  for i := 1 to n_comp + 1 do begin
    Statecreate('Nmin' + ndx_str(i), '[kg.ha-1]', 5.0, true, Nmenge[i]);
    VarCreate('NKonz' + ndx_str(i), '[kg NO3/cm H20]', 0.0, false, NKonz[i]);
    Nkonz[i].writetofile := false;
    VarCreate('NFlow' + ndx_str(i), '[kg.d-1]', 0.0, false, NFlow[i]);
  end;

  for i := 1 to n_comp do begin
    VarCreate('NSink' + ndx_str(i), '[kg N.ha-1.d-1]', 0.0, false, Nsink[i]);
    VarCreate('NetMin' + ndx_str(i), '[kg N.ha-1.d-1]', 0.0, false, NetMin[i]);
  end;

  ShowWarnings := false;
  update_NMin_Values;

  for i := 11 to n_comp + 1 do
    Nmenge[i].v := Nmin90_120.v / 3.0;

  for i := 1 to n_comp + 1 do
    theta_old[i] := theta_arr[i].v;

end;

procedure TSoilNitrogen.init(var GlobMod: Tmod);
var
  i: integer;
begin
  inherited Init(GlobMod);

  SumDrain.v := 0.0;
  for i := 1 to n_comp do begin
    NKonz[i].v := Nmenge[i].v / WAmount[i].v;
    NFlow[i].v := 0.0;
    NSink[i].v := 0.0;
    NetMin[i].v := 0.0;
  end;

  update_NMin_Values;
  LongTermNBalance.v := 0.0;

  SumNmin.v := 0.0;
  for I := 1 to trunc(bil_nr.v) do
    SumNmin.v := SumNmin.v + Nmenge[i].v;

end;

function Dbf(b: real): real;
{ Berechnung des effektiven Diffusionskoeffizienten von Nitrat in
  der Bodenlösung }
const
  D0 = 1.92e-5; // Diffusionskoeffizient in Wasser [cm2.s-1]
var
  Db: real;
begin
  Db := D0 * (3.35 * b * b) * b;

  if (Db < 0) then
    dbf := 1e-9
  else
    dbf := Db;
end;

procedure TSoilNitrogen.CalcRatesAndIntegrate;

// dafür passiert hier eine ganze Menge !

{ ********************************************************************** }
{ Zweck :   Lösung der eindimensionalen Diffusions-, Konvektionsgleichung
            zur Verlagerung Nicht-Wechselwirkender Ionen ohne Berücksichtigung
            von Anionenausschluá oder immobilen Wasser                         }

{  Parameter :

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
    Db_alt,
    Dh_arr, { Hydrodynamische Dispersionskoeffizienten [cm2/d] }
    Dh_alt,
    Ds_arr, { scheinbarer Diffusionskoeffizient [cm2/d] }
    Ds_alt,
    avg_Ds, { mittlerer scheinbarer Diffusionskoeffizient }
    avg_Dsalt,
    B_vektor,
    Ds_fact, Ds_alt_fact, Flw_n_fact, flow_alt_fact,
    lower, diag, upper,
    menge_alt: TSoilarray;
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
    Mass_flow := FLW * sqrt(C * C_1);
    Flow_f := Diff_flow + Mass_flow;
  end;

  procedure Leitfaehigkeiten;

{ Berechnung der scheinbaren Diffusionskoeffizienten }

  var
    i: byte;
  begin
    for I := 1 to n_comp + 1 do begin
      Db_arr[i] := dbf(Theta_arr[i].v) * 86400.0;
      Db_alt[i] := dbf(theta_old[i]) * 86400.0;
      if Theta_arr[i].v > 0.0 then begin
        Dh_arr[i] := Dispersion_length.v * abs(Wflow_arr[i].v) / theta_arr[i].v;
        Dh_alt[i] := Dispersion_length.v * abs(Wflow_old[i]) / theta_old[i];
      end else begin
        Dh_arr[i] := 0.0;
        Dh_alt[i] := 0.0;
      end;
      Ds_arr[i] := Db_arr[i] + Dh_arr[i];
      Ds_alt[i] := Db_alt[i] + Dh_alt[i];
    end;

    for I := 2 to n_comp + 1 do begin
      avg_Ds[i - 1] := (Ds_arr[i] + Ds_arr[i - 1]) / 2.0;
      avg_Dsalt[i - 1] := (Ds_alt[i] + Ds_alt[i - 1]) / 2.0;
      Ds_fact[i - 1] := avg_Ds[i - 1] / Dist[i - 1] * dt.v * Imp_factor.v;
      Ds_alt_fact[i - 1] := avg_Dsalt[i - 1] / Dist[i - 1] * dt.v * (1 -
        Imp_factor.v);
      Flw_n_fact[i] := Wflow_arr[i].v * dt.v / 2 * Imp_factor.v;
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
    outflow := flow_f(avg_Dsalt[1], Nkonz[1].v, Nkonz[2].v, Dist[1],
      Wflow_old[2]);
    b_vektor[1] := Nmenge[1].v / WAmount[1].v
      + (1 - Imp_factor.v) * (inflow - outflow) * dt.v / WAmount[1].v
      + (Nsink[1].v + NetMIn[1].v) * dt.v / WAmount[1].v;
    diag[1] := (Ds_fact[1] + Flw_n_fact[2]) / WAmount[1].v + 1.0;
    upper[1] := (-Ds_fact[1] + Flw_n_fact[2]) / WAmount[1].v;
  end;

  procedure Mittelteil;
  var
    i: byte;
    inflow, outflow: real;
  begin
    for i := 2 to n_comp - 1 do begin
      inflow := flow_f(avg_Dsalt[i - 1], Nkonz[i - 1].v, Nkonz[i].v, Dist[i -
        1], Wflow_old[i]);
      outflow := flow_f(avg_Dsalt[i], Nkonz[i].v, Nkonz[i + 1].v, Dist[i],
        Wflow_old[i + 1]);

      if WAmount[i].v < 1E-20 then begin
        showmessage('Fehler: WMenge_' + inttostr(i) + ' = 0');
      end;

      b_vektor[i] := Nmenge[i].v / WAmount[i].v
        + (1 - Imp_factor.v) * (inflow - outflow) * dt.v / WAmount[i].v
        + (Nsink[i].v + NetMin[i].v) * dt.v / WAmount[i].v;

      Lower[i] := (-Ds_fact[i - 1] - Flw_n_fact[i]) / WAmount[i].v;
      Diag[i] := (Ds_fact[i] + Ds_fact[i - 1]
        - Flw_n_fact[i] + Flw_n_fact[i + 1]) / WAmount[i].v + 1.0;
      Upper[i] := (-Ds_fact[i] + Flw_n_fact[i + 1]) / WAmount[i].v;
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

    inflow := flow_f(avg_Dsalt[ncomp - 1], NKonz[ncomp - 1].v, NKonz[ncomp].v,
      Dist[ncomp - 1], Wflow_old[ncomp]);
    outflow := flow_f(avg_Dsalt[ncomp], NKonz[ncomp].v, NKonz[ncomp + 1].v,
      Dist[ncomp], Wflow_old[ncomp + 1]);
    b_vektor[ncomp] := Nmenge[ncomp].v / WAmount[ncomp].v
      + Imp_factor.v * (inflow - outflow) * dt.v / WAmount[ncomp].v
      + (Nsink[ncomp].v + NetMIn[ncomp].v) * dt.v / WAmount[ncomp].v;

    Lower[ncomp] := (-Ds_fact[ncomp - 1] + Flw_n_fact[ncomp]) / WAmount[ncomp].v;
    Diag[ncomp] := (Ds_fact[ncomp] + Ds_fact[ncomp - 1]
      - Flw_n_fact[ncomp] + Flw_n_fact[ncomp + 1]) / WAmount[ncomp].v + 1.0;

  end;

  procedure Loesung_Gleichungssystem;
  var
    i: byte;
  begin
    // Änderung n_comp -> act_n_comp (ckluss)
    result := trdiag(false, act_n_comp, 1, lower, diag, upper, b_vektor);
    if result <> 0 then
      if ShowWarnings then
        ShowMessage('Fehler Lösung Gleichungsystem NSoil!');

    for i := 1 to act_n_comp do begin
      Nkonz[i].v := b_vektor[i];
      if NKonz[i].v < 0.0 then begin
        if ShowWarnings then
          ShowMessage('Negative N-Konzentration = ' + FloatToStrF(Nkonz[i].v,
            FFgeneral, 6, 3) + ' comp' + IntToStr(i));
        Nkonz[i].v := 0.0;
      end;
    end;

    for i := act_n_comp + 1 to n_comp do begin
      Nkonz[i].v := Groundwaterconc.v;
    end;
  end;

  procedure find_flows;
  var
    diff_flow_new, diff_flow_alt, mass_flow_new, mass_flow_alt: real;
    i: byte;
  begin
    for i := 2 to n_comp + 1 do begin
      diff_flow_alt := avg_Dsalt[i - 1] * (Konz_alt[i - 1] - Konz_alt[i]) /
        Dist[i];
      mass_flow_alt := Wflow_old[i] * sqrt(konz_alt[i] * konz_alt[i - 1]);
      diff_flow_new := avg_Ds[i - 1] * (Nkonz[i - 1].v - Nkonz[i].v) /
        Dist[i];
      mass_flow_new := wflow_arr[i].v * sqrt(Nkonz[i - 1].v * Nkonz[i].v);
      Nflow[i].v := (diff_flow_alt + diff_flow_new + mass_flow_alt +
        mass_flow_new) / 2;
    end;
  end;

  procedure set_new_state_var;
  var
    i: byte;
    CumSumUptake: real;
    CumSumMinera: real;
    NeuMenge, // SumNminAlt,
    DiffNmin, // Bilanz,
    SumUptake, SumMinera: real;
    Net_flow: TSoilArray;
    Ncomp: integer;
    NminStart: real;
    rep: Boolean;

  begin
    rep := False;
    CumSumUptake := 0.0;
    CumSumMinera := 0.0;
    NminStart := 0.0;
    ncomp := n_comp;
    for i := 1 to n_comp do begin
      NeuMenge := NKonz[i].v * WAmount[i].v;

      if NeuMenge < 0.0 then
        NeuMenge := 0.0;
      net_flow[i] := (NMenge[i].v - NeuMenge) / dt.v + (Nsink[i].v +
        NetMin[i].v);
      NMenge[i].v := NeuMenge;
    end;

    //SumNminAlt := SumNmin.v;
    SumNmin.v := 0.0;
    SumUptake := 0.0;
    SumMinera := 0.0;
    for i := 1 to trunc(bil_nr.v) do begin
      SumUptake := SumUptake + nsink[i].v;
      SumMinera := SumMinera + NetMin[i].v;
      SumNmin.v := sumNmin.v + Nmenge[i].v;
    end;

    //DiffNmin := (SumNmin.v - SumNminAlt) / dt.v;
    //Bilanz := DiffNmin - (SumMinera - SumUptake + Nflow[trunc(bil_nr.v) + 1].v);
    DrainageNFlow.v := DrainageNFlow.v+Nflow[trunc(bil_nr.v) + 1].v * dt.v;
    SumDrain.v := SumDrain.v + Nflow[trunc(bil_nr.v) + 1].v * dt.v;
    CumSumUptake := CumSumUptake + SumUptake * dt.v;
    CumSumMinera := CumSumMinera + SumMinera * dt.v;

    if rep then begin
      DiffNmin := (SumNmin.v - NminStart);
      LongTermNBalance.v := DiffNmin + SumDrain.v - CumSumUptake - CumSumMinera;

    end else begin
    //NminStart := SumNmin.v;
    //rep := true;
    end;

    // einstellen einer gleichen Konzentration
    Nkonz[ncomp + 1].v := Nkonz[ncomp].v;
    Nmenge[ncomp + 1].v := Nkonz[ncomp + 1].v * WAmount[ncomp + 1].v;

    update_NMin_Values;
    // Berechnung der abgeleiteten Wassergehalte für verschiedene Bodenschichten
    update_Wcont_Values;
  end;

begin
  inherited CalcRatesAndIntegrate;
  for i := 1 to n_comp + 1 do begin
    menge_alt[i] := Nmenge[i].v;
    konz_alt[i] := Nkonz[i].v;
  end;

  Leitfaehigkeiten;
  obere_Randbedingung;
  Mittelteil;
  untere_Randbedingung;
  Loesung_Gleichungssystem;
  find_flows;
  set_new_state_var;
end;

procedure TSoilnitrogen.calcrates;
begin
  DrainageNFlow.v := 0.0;
  inherited calcrates;
end;

procedure TSoilnitrogen.Integrate;

var
  NextINI, NextStateINI: TMyIniFile;
  //ndx_str : string;
  i: integer;
begin
  inherited Integrate;

  if Opt_TransferNminsToNextINI and (GlobTime.v = GlobMod.Endtime) then
  begin
    if GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName)
      = GlobMod.IniFileNames.Count - 1 then
      exit;
    NextINI := TMyIniFile.create;
    NextINI.Init(GlobMod.IniFileNames[GlobMod.IniFileNames.IndexOf
        (GlobMod.ActIniFile.FileName) + 1]);
    NextStateINI := TMyIniFile.create;
    NextStateINI.Init(NextINI.ReadString('FileNames', 'StateIniFN', ''));
    for i := 1 to n_comp + 1 do
    begin
      NextStateINI.WriteString(self.Name, 'Nmin' + ndx_str(i),
        FloatToStrF(self.NMenge[i].v, ffFixed, 9, 6));
    end;
    NextINI.Free;
    NextStateINI.Free;
  end;
end;
procedure Register;
begin
  RegisterComponents('Simulation', [TSoilNitrogen]);
end;

end.

