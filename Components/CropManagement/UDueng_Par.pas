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

Duengungen : array[0..MaxDuengDates-1] of TPar;

DuengTermine  : TStringList;

SoilNitrate : TExternV;

constructor Create(AOwner : Tcomponent); override;

procedure Init(var GlobMod: TMod); Override;

procedure CalcRates; override;

procedure Set_GlobMod(value:TMod); override;
procedure CreateAll; override;

published

//property Ex_SoilNitrate   : TExternV read SoilNitrate write SoilNitrate;

end;

 procedure Register;


implementation
uses
  SysUtils, vcl.Dialogs;

procedure TDueng_Par.CreateAll;
begin
  ExternVcreate('Nmin_1', '[kgN/ha]',STateField, SoilNitrate);
  DuengTermine := TStringlist.create;

end;

constructor TDueng_Par.create(AOwner : TComponent);

begin
  inherited create(AOwner);
  CreateAll;
end;

procedure TDueng_Par.Set_GlobMod(value:TMod);

begin
  inherited Set_globMod(Value);
  CreateAll;

end;


procedure TDueng_Par.Init(var GlobMod: TMod);

var
  i : integer;
  name   : string;
  Menge  : real;
begin
  ParIniF         := Globmod.ParamInifile;
  GlobTime        := GlobMod.Time;

  DuengTermine.clear;

  for I := 1 to 10 do begin
    if Duengungen[i] <> nil then begin
      Duengungen[i].v := 0.0;
      Duengungen[i].name := '';
    end;
  end;

  ParIniF.ReadSection(SubModName, DuengTermine);
  For i := 0 to DuengTermine.count-1 do begin
    name :=DuengTermine[i];
    Menge := PArIniF.ReadFloat(SubModName, DuengTermine[i], 0.0);
    if Duengungen[i] = nil then
      ParCreate(name,'[kgN/ha]',Menge, Duengungen[i])
    else begin
      Duengungen[i].v := Menge;
      Duengungen[i].name := name;
    end;

    DuengTermine.AddObject(name, Duengungen[i]);
  end;
  inherited Init(GlobMod);

end;

procedure TDueng_Par.calcrates;

var
  index  : integer;
  ActDueng : TPar;
  DateString : String;
  ActDate : TDateTime;
begin
  ActDate := GlobTime.v;
  DateSTring := DateToStr(ActDate);
  index := DuengTermine.IndexOf(DateSTring);
  If Index <> -1 then begin
    ActDueng := Duengungen[index];
    SoilNitrate.f_v^ := SoilNitrate.v+ActDueng.v;
    actDueng.v := 0.0;
    Duengungen[index].v := 0.0;
    Duengungen[index].name := '';
  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TDueng_Par]);
end;


end.
