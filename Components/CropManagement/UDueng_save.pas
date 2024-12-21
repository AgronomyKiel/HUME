unit UDueng;

interface

uses
  UMod, UState, IniFiles, Classes;

const
  MaxDuengDates = 10;

type

TDueng = class(TsubModel)
private

protected

public

Duengungen : array[0..MaxDuengDates-1] of TState;

DuengTermine : TStringList;

SoilNitrate : TExternV;

procedure Init(var GlobMod: TMod); Override;

procedure CalcRates; override;

procedure CreateAll; override;

published

//property Ex_SoilNitrate   : TExternV read SoilNitrate write SoilNitrate;

end;

 procedure Register;


implementation
uses
  SysUtils, Dialogs;

procedure TDueng.CreateAll;

var
  DateStr  : string;
  i        : integer;
  Menge    : real;
  error    : boolean;


begin
  ExternVcreate('Nmin_1', '[kgN/ha]',STateField, SoilNitrate);
  DuengTermine := TStringlist.create;
//  for I := 0 to MaxDuengDates-1 do
//    stateCreate('','[kgN/ha]', 0, true, Duengungen[i]);

end;



procedure TDueng.Init(var GlobMod: TMod);

var
  i : integer;
  name   : string;
  Menge  : real;
  error  : boolean;

begin
  ParIniF         := Globmod.ParamInifile;
  StateIniF       := Globmod.StateIniFile;
  GlobTime        := GlobMod.Time;

  DuengTermine.clear;

  for I := 1 to MaxDuengDates do begin
    if Duengungen[i] <> nil then begin
      Duengungen[i].v := 0.0;
      Duengungen[i].name := '';
    end;
  end;

  stateIniF.ReadSection(SubModName, DuengTermine);
  For i := 0 to DuengTermine.count-1 do begin
    name :=DuengTermine[i];
    Menge := stateIniF.ReadFloat(SubModName, DuengTermine[i], 0.0, error);
    if Duengungen[i] = nil then
      stateCreate(name,'[kgN/ha]',Menge, true, Duengungen[i])
    else begin
      Duengungen[i].v := Menge;
      Duengungen[i].name := name;
    end;

    DuengTermine.AddObject(name, Duengungen[i]);
  end;
  inherited Init(GlobMod);

end;

procedure TDueng.calcrates;

var
  index  : integer;
  Duengstate : Tstate;
  DateString : String;
  ActDate : TDateTime;
begin
  ActDate := GlobTime.v;
  DateSTring := DateToStr(ActDate);
  index := DuengTermine.IndexOf(DateSTring);
  If Index <> -1 then begin
    Duengstate := Duengungen[index];
    SoilNitrate.f_v^ := SoilNitrate.v+Duengstate.v;
    Duengstate.v := 0.0;
    Duengungen[index].v := 0.0;
    Duengungen[index].name := '';
  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TDueng]);
end;


end.
