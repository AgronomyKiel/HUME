unit URootedSoil_zr; // Neue Komponente

interface

uses
  USoilWaterMod, UMod, UState, ULayeredSoil, classes;

type
  real = double;

  TSoilWaterModel_zR = class(TSoilWaterMod)

  private

  protected

    procedure CreateAll; override;

  public

    zr: TexternV; // Durchwurzelungstiefe [cm]

    // w_influx : TSoilVarArray; // Wasserinfluxraten [cm3.cm-1.d-1]
    SinkRedF: TSoilArray; // Reduktionsfaktoren bei Wasseraufnahme

    psi_2, // Wasserspannung ab der Wasseraufnahme beginnt abzunehmen
    psi_3: Tpar;

    PotTrans: TexternV;
    ActTrans: Tvar; // aktuelle Transpirationsrate [mm/d]

    constructor create(AOwner: TComponent); override;

    procedure Init(var GlobMod: TMod); override;
    procedure CalcSinks; override;

    procedure Calcsink_red_f;
    procedure CalcRatesAndIntegrate; override;
    procedure CalcRates; override;

  published

    property Par_Psi_2: Tpar read psi_2 write psi_2;
    property Par_psi_3: Tpar read psi_3 write psi_3;

  end;

procedure Register;

implementation

uses
  SysUtils, math;

procedure TSoilWaterModel_zR.CreateAll;

var
  i: integer;

begin

  inherited CreateAll;
  ParCreate('psi_2', '[cm]', 200, psi_2);
  ParCreate('psi_3', '[cm]', 15000, psi_3);

  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans);
  VarCreate('ActTrans', '[mm.d-1]', 0.0, false, ActTrans);

  ExternVcreate('zr', '[cm]', stateField, zr);
  for i := 1 to p_ncomp do
  begin
    VarCreate('WAuf' + IntToStr(i), '[cm.d-1]', 0.0, false, Sink_arr[i]);
  end;

end;

constructor TSoilWaterModel_zR.create(AOwner: TComponent);

begin
  inherited create(AOwner);
  CreateAll;

end;

procedure TSoilWaterModel_zR.Init(var GlobMod: TMod);

var
  i: integer;
begin
  inherited Init(GlobMod);
  ActTrans.v := 0.0;
  for i := 1 to p_ncomp do
    Sink_arr[i].v := 0.0;

end;

procedure TSoilWaterModel_zR.Calcsink_red_f;

var
  red_f: real;
  i: integer;

begin
  for i := 1 to p_ncomp do
  begin
    If psi_arr[i].v < psi_2.v then
      red_f := 1.0
    else
      red_f := (log10(psi_arr[i].v) - log10(psi_3.v)) /
        (log10(psi_2.v) - log10(psi_3.v));
    if red_f < 0.0 then
      red_f := 0.0;
    SinkRedF[i] := red_f;
  end;
end;

procedure TSoilWaterModel_zR.CalcSinks;

var
  sum_sink: real;
  i, n_root: integer;

begin
  inherited CalcSinks;
  i := 1;
  repeat
    if Depth[i].v < zr.v then
      n_root := i;
    inc(i);
  until Depth[i].v >= zr.v;

  sum_sink := 0.0;
  for i := 1 to p_ncomp do
  begin
    if zr.v > Depth[i].v then
      Sink_arr[i].v := 0.1 * PotTrans.v / n_root
    else
      Sink_arr[i].v := 0.0;
    Sink_arr[i].v := Sink_arr[i].v * SinkRedF[i];
    sum_sink := sum_sink + Sink_arr[i].v;
  end;
  ActTrans.v := ActTrans.v + sum_sink * 10.0 * dt.v;
end;

procedure TSoilWaterModel_zR.CalcRatesAndIntegrate;

var
  i: integer;

begin
  Calcsink_red_f;
  // CalcSinks;

  inherited CalcRatesAndIntegrate;

end;

procedure TSoilWaterModel_zR.CalcRates;

begin
  ActTrans.v := 0.0;
  inherited CalcRates;
  ActTrans.v := ActTrans.v / GlobTime.c;

end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterModel_zR]);
end;

end.
