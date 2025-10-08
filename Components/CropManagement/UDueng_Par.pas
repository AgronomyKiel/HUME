unit UDueng_Par;

interface

uses
  UMod, UState, IniFiles, Classes;

const
  MaxDuengDates = 100;

type

  TDueng_Par = class(TsubModel)
  private

  protected

  public

    Duengungen: array [0 .. MaxDuengDates - 1] of TPar;

    DuengTermine: TStringList;

    SoilNitrate: TExternV;

    constructor Create(AOwner: Tcomponent); override;

    procedure Init(var GlobMod: TMod); Override;

    procedure CalcRates; override;

    procedure Set_GlobMod(value: TMod); override;
    procedure CreateAll; override;

  published

    // property Ex_SoilNitrate   : TExternV read SoilNitrate write SoilNitrate;

  end;

procedure Register;

implementation

uses
  SysUtils, vcl.Dialogs;

procedure TDueng_Par.CreateAll;
begin
  ExternVcreate('Nmin_1', '[kgN/ha]', STateField, SoilNitrate);
  DuengTermine := TStringList.Create;

end;

constructor TDueng_Par.Create(AOwner: Tcomponent);

begin
  inherited Create(AOwner);
  CreateAll;
end;

procedure TDueng_Par.Set_GlobMod(value: TMod);

begin
  inherited Set_GlobMod(value);
  CreateAll;

end;

procedure TDueng_Par.Init(var GlobMod: TMod);

var
  i: integer;
  name: string;
  Menge: real;
begin
  ParIniF := GlobMod.ParamInifile;
  GlobTime := GlobMod.Time;

  DuengTermine.clear;

  for i := 1 to 10 do
  begin
    if Duengungen[i] <> nil then
    begin
      Duengungen[i].v := 0.0;
      Duengungen[i].name := '';
    end;
  end;

  ParIniF.ReadSection(SubModName, DuengTermine);
  For i := 0 to DuengTermine.count - 1 do
  begin
    name := DuengTermine[i];
    Menge := ParIniF.ReadFloat(SubModName, DuengTermine[i], 0.0);
    if Duengungen[i] = nil then
      ParCreate(name, '[kgN/ha]', Menge, Duengungen[i])
    else
    begin
      Duengungen[i].v := Menge;
      Duengungen[i].name := name;
    end;

    DuengTermine.AddObject(name, Duengungen[i]);
  end;
  inherited Init(GlobMod);

end;

procedure TDueng_Par.CalcRates;

var
  index: integer;
  ActDueng: TPar;
  DateString: String;
  ActDate: TDateTime;
begin
  ActDate := GlobTime.v;
  DateString := DateToStr(ActDate);
  index := DuengTermine.IndexOf(DateString);
  If Index <> -1 then
  begin
    ActDueng := Duengungen[index];
    SoilNitrate.f_v^ := SoilNitrate.v + ActDueng.v;
    ActDueng.v := 0.0;
    Duengungen[index].v := 0.0;
    Duengungen[index].name := '';
  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TDueng_Par]);
end;

end.
