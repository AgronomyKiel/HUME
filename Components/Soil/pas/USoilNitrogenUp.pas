unit USoilNitrogenUp;

interface

uses
  UMod, UlayeredSoil, USoilNitrogen, UState, UAbstractPlant,
  classes;

const

  Max_Root_Index = 20;

type

  TSoilNitrogenUp = class(TSoilNitrogen)

  private

  protected
    procedure SetPlantModel(NewPlantModel: TAbstractplant); override;

  public
    Cmin: TPar;    /// minimal nitrate concentration, substracted from actual concentration [kg/cm water]
    not_av_N : TPar;  /// nicht verfügbarer Teil des Bodenstickstoffs [kg N/10 cm]
    RootRad: TPar;    /// root radius [cm]
    Max_Wl_Nuptake: TPar;   /// maximum value for N uptake per unit root length [kg/cm/d]
    // NTotal       : TExternV;
    Ex_PlantNDemand: TExternV;  /// plant N demand [kg N/ha]
    SRL            : TExternV; /// sum or root length cm/cm2
    SRL_eff: TExternV;         /// effective sum or root length cm/cm2
    ActNUptake: TVar;      /// actual N uptake rate averaged over day
    MaxNUptake: TVar;      /// maximum N uptake rate averaged over day
    MassFlow: TVar;        /// sum of apparent mass flow transport to roots kg N/ha/d
    NUptake: TSoilVarArray; /// N uptake per day kg N/ha/d
    WInflux: TSoilArray;    /// water influx per unit root length [cm3/cm/d]
    NInflux_WL: TVar;       ///
    NInflux_WL_eff: TVar;  ///

    SumSoilNUptake: TState;    ///
    SoilNUptakeGrowth: TState; ///
    SumPlantNDemand: TState;   /// sum of nitrate uptake from soil

    plantNDemand: real;

    procedure CreateAll; override;

    procedure CalcRatesAndIntegrate; override;

    procedure CalcRates; override;

  published

    property Par_Cmin: TPar read Cmin write Cmin;
    property Par_Not_av_N: TPar read Not_av_N write Not_av_N;

    property Par_RootRad: TPar read RootRad write RootRad;
    property Var_MaxNuptake: TVar read MaxNUptake write MaxNUptake;
    property Var_ActNUptake: TVar read ActNUptake write ActNUptake;
    property Var_Massflow: TVar read MassFlow write MassFlow;

    property Ex_PlantNUptake
      : TExternV read Ex_PlantNDemand write Ex_PlantNDemand;
    property Ex_SRL: TExternV read SRL write SRL;
    property Ex_SRL_eff: TExternV read SRL_eff write SRL_eff;

    property St_SumSoilNUptake: TState read SumSoilNUptake write SumSoilNUptake;

  end;

procedure Register;

implementation

uses
  Math, SysUtils, UModUtils;

function Imax(Cl, clmin, theta, w_influx, wld, rad: real): real;

{ ********************************************************************** }
{ Zweck : Berechnung des maximalen Nitratinfluxes [Kg N/cm*d]

  Parameter :

  Name             Inhalt                          Einheit      Typ
  Cl               Bodenlösungskonzentration       [Kg N/cm H2o]  I
  Clmin            min.Bodenlösungkonzentration    [Kg N/cm H2o]  I
  theta            volumetrischer Wassergehalt     [cm3/cm3]      I
  w_influx         Wasserinflux                    [cm3/cm*d]      I
  dist             mittlerer halber Wurzelabst.    [cm]
  rad              mittlerer Wurzelradius          [cm]

  Imax             maximaler Nitratinflux          [Kg N/cm*d]   O

  { ********************************************************************** }

const
  D0 = 1.92E-5 * 86400.0; { Diffusionskoeffizient von Nitrat in Wasser [cm2/d] }

var
  v, { Wasserinfluxgeschwindigkeit [cm3/cm2*d] }
    f, { Widerstandsfaktor }
    x, x1, x2, y, z1, Db, dist, Ima: real;

  function f_f(theta: real): real;

  var
    f: real;

  begin
    f := 3.35 * theta * theta; // Tortuositaetsfaktor
    if f < 0.0 then
      f := 0.0;
    f_f := f;
  end;

  function v0Imax(Cl, clmin, Db, dist, rad: real): real;
  // maximum nitrate influx without mass flow

  begin
    if Cl - clmin < 0.0 then
      v0Imax := 0.0
    else
      v0Imax := ((Cl - clmin) * 2 * pi * Db) / (ln(dist / (1.65 * rad)));
  end;

begin
  Ima := 0;

  if wld > 0.0 then
    dist := 1 / sqrt(pi * wld)
  else begin
    result := 0;
    exit;
  end;
  if Cl > 0.0 then
    Cl := Cl * 1E-8 // Umrechnung auf kg N/cm3 H2O
  else begin
    result := 0;
    exit;
  end;
  clmin := clmin * 1E-8; // Umrechnung auf kg N/
  w_influx := w_influx * 1E8; // Umrechnung auf cm3
  f := f_f(theta);
  Db := D0 * f * theta;
  if Db <= 0.0 then begin
    result := 0.0;
    exit;
  end else begin
    if Cl - clmin <= 0.0 then begin
      result := 0.0;
      exit;
    end else begin
      if w_influx <= 1e-10 then begin
        Ima := v0Imax(Cl, clmin, Db, dist, rad);
        //result := Ima;  // wird nie benutzt!
      end else begin
        v := w_influx / (2 * pi * rad);
        x1 := 2 / (2 - (rad * v) / Db);
        x2 := Power(dist / rad, 2 - (rad * v) / Db) - 1;
        x := x1 * x2;
        y := Power(dist / rad, 2) - 1;
        z1 := x / y;
        if clmin > 0.0 then
          Ima := (Cl * 2 * pi * rad * v - 2 * pi * rad * clmin * v * z1) /
            (1 - z1)
        else if z1 <> 1 then
          ima := (Cl * 2 * pi * rad * v) / (1 - z1)
      end;
    end;
  end;
  result := max(0, Ima);
end;

procedure TSoilNitrogenUp.CalcRatesAndIntegrate;

var
  SumImax { Summe der maximalen Influxraten }
    : real;

  Max_uptake: TSoilArray; /// maximale N-Aufnahmerate in [kg N/(ha*d)] pro Schicht
  Imax_arr: TSoilArray;  /// maximale N-Influxrate in Kg N/(cm*d) pro Schicht
  Cl_min_arr: TSoilArray;  /// not available concentration of soil nitrate (sum of Cmin and not_av_N
  i: byte;
  actMaxNUptake: real;  /// maximale N-Aufnahmerate im internen Zeitschritt
  actMassFlow : real;   /// Massenflußtransportrate im internen Zeitschritt
  Sum_N_Nuptake: real;  /// Summe maximale N-Aufnahmerate im internen Zeitschritt

begin
  Sum_N_Nuptake := 0.0;
  actMaxNUptake := 0.0;
  actMassFlow   := 0.0;
  SumImax       := 0.0;

  for i := 0 to max_comp + 1 do begin
    Imax_arr[i] := 0.0;
    WInflux[i] := 0.0;
    Max_uptake[i] := 0.0;
  end;

  // calculation of maximum N uptake over all soil layers using the steady state
  // single root model approach of Baldwin/Kage

  if Exwld_arr[1].v > 0.0 then begin // Sind Wurzeln da ?
    for i := 1 to Max_Root_Index do begin
      if (Exwld_arr[i].v * Thick[i] > 1E-4) then begin
        actMassFlow := actMassFlow + Sink_Arr[i].v * NKonz[i].v;
        // Aufsummierung des Massenflusses über die internen Zeitschritte
        WInflux[i] := Sink_Arr[i].v / (Exwld_arr[i].v * Thick[i] * 1E8);
        // Wurzellängenumrechnung von cm/cm2 auf cm/ha
        Cl_min_arr[i] := Not_av_N.v/WAmount[i].v+Cmin.v;
        // ar:  max_Wl_NupTake = physiological limitation of the N uptake per root length (Wl)
        // will be effective if time-step error is high (after N fertilization evemts)
        Imax_arr[i] := min(max_Wl_NupTake.v,max(0, Imax(NKonz[i].v, Cl_min_arr[i], theta_arr[i].v, WInflux[i],
          Exwld_arr[i].v, RootRad.v)));
        SumImax := SumImax + Imax_arr[i];
        Max_uptake[i] := Imax_arr[i] * Exwld_arr[i].v * Thick[i] * 1E8;
        // hkage 20.07.16: check if actual maximum N uptake rate would lead to negative N amounts
        // the value of 0.5 is abitrary ...
        if (Max_uptake[i]/dt.v > (NMenge[i].v))  then
          max_uptake[i] := 0.1 * NMenge[i].v *dt.v;

        // Wurzellängenumrechnung von cm/cm2 auf cm/ha
      end else begin
        Imax_arr[i] := 0.0;
        Max_uptake[i] := 0.0;
      end;
      //actMaxNUptake := actMaxNUptake + Max_uptake[i];
      //ar 06.06.16
      // limitation of the N uptake to the amount of availale N
     // actMaxNUptake := actMaxNUptake + min(Max_uptake[i],
      //                  max(0,(self.NMenge[i].v-self.not_av_N.v)));

 // hkage 20.7.16: above code could lead to incorrect N uptake after summing up
      actMaxNUptake := actMaxNUptake + Max_uptake[i];

    end;

// distribution of N uptake over all layers ...
    if (actMaxNUptake >= plantNDemand) and (actMaxNUptake > 0.0) then
      begin // Wenn mögliche Aufnahme > Bedarf
      for i := 1 to Max_Root_Index do begin
        NUptake[i].v  := -plantNDemand * Max_uptake[i] / actMaxNUptake;

        //  if(NUptake[i].v>(self.NMenge[i].v-self.not_av_N.v)) then
        //  NUptake[i].v :=min(NUptake[i].v,(self.NMenge[i].v-self.not_av_N.v));
        //  limitation of the N uptake to the amount of availale N
        //  NUptake[i].v :=min(NUptake[i].v,(max(0,self.NMenge[i].v-self.not_av_N.v)));
        Sum_N_Nuptake := Sum_N_Nuptake + (-NUptake[i].v);
      end;
    end { Imax_arr[i]/sumImax }
    else begin
      for i := 1 to Max_Root_Index do begin
        NUptake[i].v  := -Max_uptake[i];
        Sum_N_Nuptake := Sum_N_Nuptake + Max_uptake[i];
      end;
    end;
  end else begin // ohne Wurzeln keine Aufnahme
    for i := 1 to Max_Root_Index do
      NUptake[i].v := 0.0;
    Sum_N_Nuptake  := 0.0;
  end;
  for i := 1 to n_comp do
    NSink[i].v := NUptake[i].v;


  inherited CalcRatesAndIntegrate;

  MaxNUptake.v  := MaxNUptake.v + actMaxNUptake*dt.v;
  Massflow.v := Massflow.v + actMassflow*dt.v;

  // the average N uptake rate per day (globtime.c) for plotting as a var
  ActNuptake.v    := ActNUptake.v + Sum_N_Nuptake * dt.v;
  // the average N uptake rate per day (globtime.c) for plotting as a state
  SumSoilNUptake.c := ActNuptake.v;

  // the average N uptake rate per day (globtime.c) for plotting as a state in units of g/m2/d
  SoilNUptakeGrowth.c := ActNUptake.v / 10;

  if (SRL.v > 0.0) and (SRL_eff.v > 0.0) then begin
    NInflux_WL.v := ActNUptake.v * 1000 / 86400 / 14 / 1E8 / SRL.v;
    NInflux_WL_eff.v := ActNUptake.v * 1000 / 86400 / 14 / 1E8 / SRL_eff.v;
  end else begin
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
  plantNDemand := max(0, Ex_PlantNDemand.v * 10); // Umrechnung von gN/m2 auf kg N/ha
  SumPlantNDemand.c :=  plantNDemand;


  inherited CalcRates;
  { ActNUptake.v := ActNUptake.v/globtime.c;
    MaxNUptake.v := MaxNUptake.v/globtime.c;
    MassFlow.v   := MassFlow.v/globtime.c; }

end;



procedure TSoilNitrogenUp.createAll;

var
  i: integer;

begin
  inherited createAll;
  ParCreate('Cmin', '[kg N/cm]', 0.0, Cmin, 'minimum nitrate concentration roots can deplete to');
  ParCreate('Not_av_N', '[kg N/10 cm]', 1.5, Not_av_N, 'nicht verfügbarer Teil des Bodenstickstoffs [kg N/10 cm]');
  ParCreate('RootRad', '[cm]', 0.02, RootRad, 'root radius');
  ParCreate('Max_Wl_Nuptake', '[kg/ha/d/Wl]', 3E-9, Max_Wl_Nuptake);
  // ExternVcreate('TotalPlantNitrogen', '[kg N.ha-1.d-1]',   RateField, NTotal);
  ExternVcreate('PlantNDemand', '[g.m-2.d-1]', stateField, Ex_PlantNDemand, 'External plant N demand');
  StateCreate('SumPlantNDemand', '[kg.ha-1]', 0.0, false, SumPlantNDemand, 'total sum of plant demand');

  StateCreate('SoilNUptakeGrowth', '[?]', 0.0, false, SoilNUptakeGrowth);
  ExternVcreate('SRL', '[cm.cm-2]', stateField, SRL, 'sum of root length');
  ExternVcreate('SRL_eff', '[cm.cm-2]', stateField, SRL_eff, 'effective sum of root length');

  VarCreate('ActNUptake', '[kg.ha-1.d-1]', 0.0, false, ActNUptake, 'the average N uptake rate per day (globtime.c) for plotting as a Var');
  VarCreate('MaxNUptake', '[kg.ha-1.d-1]', 0.0, false, MaxNUptake, 'maximum possible N uptake per day');
  VarCreate('MassFlow', '[kg.ha-1.d-1]', 0.0, false, MassFlow, 'apparent mass flow transport of nitrate to roots');
  StateCreate('SumSoilNuptake', '[kg.ha-1]', 0.0, false, SumSoilNUptake, 'the average N uptake rate per day (globtime.c) for plotting as a state');
  VarCreate('NInflux_WL', '[kg.cm-1.d-1]', 0.0, false, NInflux_WL, 'specific nitrate uptake per root length');
  VarCreate('NInflux_WL_eff', '[kg.cm-1.d-1]', 0.0, false, NInflux_WL_eff, 'specific nitrate utpake per effective root length');

  for i := 1 to Max_Root_Index do begin
    VarCreate('NUptake' + ndx_str(i), '[kg.ha-1.d-1]', 0.0, false, NUptake[i]);
  end;
end;


procedure TSoilNitrogenUp.SetPlantModel(NewPlantModel: TAbstractplant);

begin
  inherited;
  if PlantModel <> nil then begin
    Ex_PlantNUptake.Search := false;
    Ex_PlantNDemand.f_v := @PlantModel.p_NUptakeRate.fv;
    Ex_PlantNDemand.Source := '['+PlantModel.Name+']';
    if PlantModel.withRoots then begin
      Ex_SRL.f_v := @PlantModel.p_SumRootLength.fv;
      Ex_SRL.Search := false;
      Ex_SRL.Source := '['+PlantModel.Name+']';
      Ex_SRL_eff.f_v := @PlantModel.p_SumRootLength_eff.fv;
      Ex_SRL_eff.Search := false;
      Ex_SRL_eff.Source := '['+PlantModel.Name+']';
    end;
  end;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilNitrogenUp]);
end;

end.


