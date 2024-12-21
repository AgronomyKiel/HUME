unit UGrowthCurve;

{******************************************************************************
*******************************************************************************
**  Simuliert logistisches, monomolekulares, Gomperz oder Richards Wachstum **
*******************************************************************************
{******************************************************************************

benötigte externe Größen:
                  - Temperatur                               -->Temp

benötigte Parameter:
                  - Wachstumsrate [1/d]                      -->rgr
                  - maximaler LAI [m2/m2]                    -->max
                  - Basistemperatur [°C]                     -->BaseTemp
                  - Richards Formparameter                   --> Richards_m
                  - Auspflanzdatum [d]                       -->SowingDate
                  - Rode/ Erntedatum [d]                     -->HarvestDate

Zustandsgrößen:
                  - Temperatursumme [°C]                     -->Tsum

Optionen:
                  - Wachstumart [logistisch,
                                 monomolekular,
                                 Gompertz,
                                 Richards]
******************************************************************************}

interface

uses
  UMod, UState, IniFiles, classes, math, sysutils;

type

  TGrowth = (Logistisch, Monomolekular, Gompertz, Richards, Linear, expolinear,
    Log_Decay);
//TArea = (SoilCover, LeafAreaIndex);

  TGrowthCurve = class(TSubModel)

  private
//  procedure setCapacity

    function CalcGrowthRate(ActValue, temp, BaseTemp, rgr, gr, Capacity, Form:
      real;
      CurveType: TGrowth): real;

  protected

  public

    Temp: TExternV;
    TSum: TState;
    SimValue: TState;

    BaseTemp,
      rgr,
      gr,
      Capacity,
      Richards_f: TPar;
    SowingDate: TPar;
    HarvestDate: Tpar;
    IniValue: TPar;

    Growthrate: TVar;
    CurveOption: Toption;
    CurveType: TGrowth;
    CurveSwitch: boolean;

    procedure calcrates; override;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

  published
    property Ex_Temp: TExternV read Temp write Temp;
    property Par_SowingDate: TPar read SowingDate write SowingDate;
    property Par_HarvestDate: TPar read HarvestDate write HarvestDate;
    property Par_Capacity: TPar read Capacity write Capacity;
    property Par_BaseTemp: TPar read Basetemp write basetemp;
    property Par_rgr: TPar read rgr write rgr;
    property Par_gr: TPar read gr write gr;
    property Par_Richards_F: TPar read Richards_f write Richards_f;
    property Par_IniValue: TPar read IniValue write IniValue;
    property Opt_CurveType: TGrowth read CurveType write Curvetype;
    property St_SimValue: TState read SimValue write SimValue;

  end;

procedure Register;

implementation

function TGrowthCurve.CalcGrowthRate(ActValue, temp, BaseTemp, rgr, gr,
  Capacity, Form: real;
  CurveType: TGrowth): real;

var
  effTemp: real;

begin
  effTemp := temp - BaseTemp;
  if effTemp > 0.0 then begin
    if CurveType = logistisch then
      result := ActValue * rgr * effTemp * (1 - ActValue / Capacity);
    if CurveType = monomolekular then
      result := rgr * efftemp * (Capacity - ActValue);
    if CurveType = gompertz then
      result := rgr * actValue * efftemp * ln(Capacity / actvalue);
    if CurveType = Richards then
      result := rgr * efftemp * actvalue * (Power(Capacity, form) -
        Power(ActValue, Form)) / (Form * power(capacity, form));
    if CurveType = linear then
      result := gr;
    if CurveType = expolinear then begin
      if ActValue < gr / rgr then
        result := rgr * efftemp * ActValue
      else
        result := gr * effTemp;
      if ActValue >= Capacity then begin
        result := 0.0;
        Harvestdate.v := GlobTime.v;
      end;
    end;
    if CurveType = Log_Decay then begin
      if (ActValue < 0.99 * Capacity) and (CurveSwitch = false) then
        result := ActValue * rgr * effTemp * (1 - ActValue / Capacity)
      else begin
        Result := -gr * efftemp * ActValue * (Capacity - ActValue);
        CurveSwitch := true;
      end;
    end;
  end else begin
    result := 0.0;
  end;

end;

procedure TGrowthCurve.CreateAll;

begin
  inherited createall;
  Parcreate('SowingDate', '[d]', 34335, SowingDate);
  Parcreate('HarvestDate', '[d]', 34669, HarvestDate);
  Parcreate('Capacity', '[-]', 100, Capacity);
  ParCreate('rgr', '[1/d]', 0.015, rgr);
  ParCreate('gr', '[-]', 0.015, gr);
  ParCreate('BaseTemp', '[°C]', 0, Basetemp);
  ParCreate('Richards_f', '[-]', 1.5, richards_f);
  ParCreate('IniValue', '[]', 0.01, IniValue);
  StateCreate('TSum', '[°d]', 0.0, false, TSum);
  StateCreate('SimValue', '[m2/m2]', 0.01, true, SimValue);
  ExternVCreate('Temp', '[°C]', RateField, Temp);
  OptCreate('CurveType', 'Logistisch', CurveOption);
  CurveOption.OptionList.Add('Logistisch');
  CurveOption.OptionList.Add('Monomolekular');
  CurveOption.OptionList.Add('Gompertz');
  CurveOption.OptionList.Add('Richards');
  CurveOption.OptionList.Add('Linear');
  CurveOption.OptionList.Add('Expolinear');
  CurveOption.OptionList.Add('Log_Decay');

end;

procedure TGrowthCurve.Init(var GlobMod: TMod);

//TGrowth = (Logistisch, Monomolekular, Gompertz, Richards, Linear, expolinear);

begin
  inherited Init(GlobMod);
  SimValue.v := IniValue.v;
  CurveSwitch := false;
  if CurveOption.Option = lowercase('Logistisch') then
    Curvetype := Logistisch;
  if CurveOption.Option = lowercase('Linear') then
    Curvetype := Linear;
  if CurveOption.Option = lowercase('Expolinear') then
    Curvetype := Expolinear;
  if CurveOption.Option = lowercase('Richards') then
    Curvetype := Richards;
  if CurveOption.Option = lowercase('Gompertz') then
    Curvetype := Gompertz;
  if CurveOption.Option = lowercase('Monomolekular') then
    Curvetype := Monomolekular;
  if CurveOption.Option = lowercase('Log_Decay') then
    Curvetype := Log_Decay;

end;

procedure TGrowthCurve.CalcRates;

begin
  if (GlobTime.v >= SowingDate.v) and (GlobTime.v <= HarvestDate.v) then begin
    if SimValue.V <= 0.0 then SimValue.v := IniValue.v;
    begin
      if Temp.v >= BaseTemp.v then begin
        TSum.C := Temp.v;
        SimValue.C := CalcGrowthRate(SimValue.v, temp.v, BaseTemp.v, rgr.v,
          gr.v,
          capacity.v, Richards_f.V, CurveType)
      end else begin
        TSum.c := 0.0;
        SimValue.c := 0.0;
      end;
    end;
  end else begin
    TSum.c := 0.0;
    SimValue.c := 0.0;
  end;
  if GlobTime.V > HarvestDate.V then begin
    SimValue.V := 0.0;
    SimValue.c := 0.0;
  end;
end;




procedure Register;
begin
  RegisterComponents('Simulation', [TGrowthCurve]);
end;

end.

