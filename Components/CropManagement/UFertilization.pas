unit UFertilization;

interface

uses
  UMod, UState, IniFiles, Classes, UAbstractPlant, UMinMod2Pool;

const
  MaxDuengDates = 100;

type

  TFertilization = class(TSubmodel)
  private
    fSoilLayerMod: TPlantRelatedSubmod;
  protected

  public
    dates: array[1..MaxDuengDates] of TPar;
    quantities: array[1..MaxDuengDates] of TPar;
    quantitiesNH3: array[1..MaxDuengDates] of TPar;
    fractionsNFast: array[1..MaxDuengDates] of TPar;

    SoilNitrate: TExternV; // NMin1

    constructor Create(AOwner: Tcomponent); override;

    procedure Init(var GlobMod: TMod); override;

    procedure CalcRates; override;

    procedure Set_GlobMod(value: TMod); override;
    procedure CreateAll; override;

  published
    property SoilLayerMod: TPlantRelatedSubmod read fSoilLayerMod write
      fSoilLayerMod;
  end;

procedure Register;

implementation
uses
  SysUtils, vcl.Dialogs;

procedure TFertilization.CreateAll;
begin
  ExternVcreate('Nmin_1', '[kgN/ha]', STateField, SoilNitrate);
end;

constructor TFertilization.create(AOwner: TComponent);

begin
  inherited create(AOwner);
  CreateAll;
end;

procedure TFertilization.Set_GlobMod(value: TMod);

begin
  inherited Set_globMod(Value);
  CreateAll;
end;

// [fertilization1]
// date_1=39999
// quantity_1=120
// quantity_NH3_1=60
// fraction_nfast_1=0.5

procedure TFertilization.Init(var GlobMod: TMod);
var
  i: integer;
  name: string;
  entries: TStringList;
  sl: TStringList;
  idx: Integer;
  value: double;

begin
  ParIniF := Globmod.ParamInifile;
  GlobTime := GlobMod.Time;

  entries := TStringList.create();
  sl := TStringList.Create();

  if ParIniF.SectionExists(SubModName) then begin
    ParIniF.ReadSection(SubModName, entries);

    for i := 0 to entries.Count - 1 do begin
      name := entries[i];
      value := PArIniF.ReadFloat(SubModName, name, 0.0);

      sl.Delimiter := '_';
      sl.DelimitedText := name;

      idx := StrToInt(sl[1]);
      name := sl[0];

      if AnsiCompareText(name, 'date') = 0 then begin
        ParCreate('date_' + sl[1], '[d]', value, dates[idx]);
      end else if AnsiCompareText(name, 'quantity') = 0 then begin
        ParCreate('quantity_' + sl[1], '[kgN/ha]', value, quantities[idx]);
      end else if AnsiCompareText(name, 'quantityNH3') = 0 then begin
        ParCreate('quantityNH3_' + sl[1], '[kgN/ha]', value,
          quantitiesNH3[idx]);
      end else if AnsiCompareText(name, 'fractionNFast') = 0 then begin
        ParCreate('fractionNFast_' + sl[1], '[]', value, fractionsNFast[idx]);
      end;

    end;
  end;

  inherited Init(GlobMod);
end;

procedure TFertilization.calcrates;

var
  idx, i: integer;
  rest, anteil: double;
  actminmod: TMinMod2Pool;
begin

  idx := -1;
  for i := 1 to MaxDuengDates do begin
    if (dates[i] <> nil) and (GlobTime.v = dates[i].v) then begin
      idx := i;
      break;
    end;
  end;

  if idx <> -1 then begin

    SoilNitrate.f_v^ := SoilNitrate.v + quantitiesNH3[idx].v;

    rest := quantities[idx].v - quantitiesNH3[idx].v;
    anteil := fractionsNFast[idx].v;

    actminmod := self.SoilLayerMod.PlantModel.SoilMinMOd as TMinMod2Pool;

    actminmod.NFast.v
      := actminmod.NFast.v + anteil * rest;

    actminmod.NSlow.v
      := actminmod.NSlow.v + (1 - anteil) * rest;

  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TFertilization]);
end;

end.

