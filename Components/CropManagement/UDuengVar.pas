unit UDuengVar;

interface

uses
  UMod, UState,  Classes;

const
  MaxDuengDates = 100;

type

TDuengVar = class(TsubModel)
private

fConsideredLayers : integer;

protected

public

Duengungen : array[0..MaxDuengDates-1] of TState;

DuengTermine     : TStringList;

NTargetValue     : Tpar;

Nmin1,
Nmin2,
Nmin3            : TExternV;

SoilNitrate : TExternV;

SumFertN : TVar;

constructor create(AOwner : Tcomponent); override;

procedure Init(var GlobMod: TMod); Override;

procedure CalcRates; override;

procedure Set_GlobMod(value:TMod); override;
procedure CreateAll; override;

published

property Ex_Nmin1 : TExternV read Nmin1 write Nmin1;
property Ex_Nmin2 : TExternV read Nmin2 write Nmin2;
property Ex_Nmin3 : TExternV read Nmin3 write Nmin3;
property Par_NTargetValue : TPar read NTargetValue write NTargetValue;

property opt_ConsideredLayers : integer read fConsideredLayers write fconsideredLayers;

property Ex_SoilNitrate   : TExternV read SoilNitrate write SoilNitrate;

end;

 procedure Register;


implementation
uses
  SysUtils, Dialogs, UModUtils, math;

procedure TDuengVar.CreateAll;

var
  DateStr  : string;
  i        : integer;
  Menge    : real;
  error    : boolean;


begin
//  FConsideredLayers := 1;
  ExternVcreate('Nmin_1', '[kgN/ha]', STateField, SoilNitrate);
  ExternVcreate('Nmin0_30', '[kgN/ha]', STateField, Nmin1);
  ExternVcreate('Nmin30_60', '[kgN/ha]', STateField, Nmin2);
  ExternVcreate('Nmin60_90', '[kgN/ha]', STateField, Nmin3);
  ParCreate('NTargetValue',  '[kgN.ha-1]', 0.0,    NTargetValue);
  VarCreate('SumFertN', '[kgN.ha-1]',  0, false, SumFertN);

  DuengTermine := TStringlist.create;

end;

constructor TDuengVar.create(AOwner : TComponent);

begin
  inherited create(AOwner);
  CreateAll;
end;

procedure TDuengVar.Set_GlobMod(value:TMod);

begin
  inherited Set_globMod(Value);
  CreateAll;

end;


procedure TDuengVar.Init(var GlobMod: TMod);

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

  for I := 1 to 10 do begin
    if Duengungen[i] <> nil then begin
      Duengungen[i].v := 0.0;
      Duengungen[i].name := '';
    end;
  end;

  stateIniF.ReadSection(SubModName, DuengTermine);
  For i := 0 to DuengTermine.count-1 do begin
    name :=DuengTermine[i];
    //Menge := stateIniF.ReadFloat(SubModName, DuengTermine[i], 0.0, error);
    Menge := stateIniF.ReadFloat(SubModName, DuengTermine[i], 0.0);
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

procedure TDuengVar.calcrates;

var
  index  : integer;
  DateString : String;
  ActDate    : TDateTime;
  NApplication : real;
begin
//  SumFertN.c := 0.0;
  ActDate := GlobTime.v;
  DateSTring := DateToStr(ActDate);
  index := DuengTermine.IndexOf(DateSTring);


  If Index <> -1 then begin
    Case FConsideredLayers Of
      1 : NApplication := max(0, duengungen[index].v-Nmin1.v);
      2 : NApplication := max(0, duengungen[index].v-Nmin1.v-Nmin2.v);
      3 : NApplication := max(0, duengungen[index].v-Nmin1.v-Nmin2.v-Nmin3.v);
    end;
    SumFertN.v := SumFertN.v+NApplication;
    SoilNitrate.f_v^ := SoilNitrate.v+NApplication;
  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TDuengVar]);
end;


end.
