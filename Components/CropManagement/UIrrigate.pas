unit UIrrigate;

interface

uses
  UMod, UState, IniFiles, Classes;

const
  MaxIrriDates = 100;

type

  TIrrigate = class(TsubModel)
  private

  protected
    procedure Set_GlobMod(value: TMod); override;
    procedure CreateAll; override;

  public

    Irrigations: array [0 .. MaxIrriDates - 1] of TState;

    IrrigateTermine: TStringList;
    Rain: TExternV;

    constructor create(AOwner: Tcomponent); override;

    procedure Init(var GlobMod: TMod); Override;

    procedure CalcRates; override;

  published

    // property ListIrrigateTermine : TStringList read IrrigateTermine;

  end;

procedure Register;

implementation

uses
  SysUtils, vcl.Dialogs;

procedure TIrrigate.CreateAll;

var
  DateStr: string;
  i: integer;
  Menge: real;
  error: boolean;

begin
  ExternVcreate('Rain', '[mm]', STateField, Rain);
  IrrigateTermine := TStringList.create;
  for i := 1 to 50 do
    StateCreate('', '[mm]', 0.0, true, Irrigations[i]);
  // IrrigateMengen := TStringlist.create;

  // StateIniF.ReadSection(Name, IrrigateTermine);
  // StateIniF.ReadSectionValues(Name, IrrigateMengen);
  // For i := 0 to IrrigateTermine.count-1 do begin
  // DateStr :=IrrigateTermine[i];
  // Menge := StateIniF.ReadFloat(Name, DateStr, 0.0,error);
  // StateCreate(DateStr,'[mm]',Menge, true, Irrigations[i]);
  // NewState := TState.create(name, '[mm]', menge, 0.0);
  // IrrigateTermine.AddObject(name,Irrigations[i]);
  // end;

end;

constructor TIrrigate.create(AOwner: Tcomponent);

const
  MaxIrrigateEvents = 50;

begin
  inherited create(AOwner);
end;

procedure TIrrigate.Set_GlobMod(value: TMod);

begin
  inherited Set_GlobMod(value);
  CreateAll;

end;

procedure TIrrigate.Init(var GlobMod: TMod);

var
  i: integer;
  name: string;
  Menge: real;
  error: boolean;

begin
  ParIniF := GlobMod.ParamInifile;
  StateIniF := GlobMod.StateIniFile;
  GlobTime := GlobMod.Time;

  IrrigateTermine.clear;
  // stateStrList.Clear;
  StateIniF.ReadSection(SubModName, IrrigateTermine);
  For i := 0 to IrrigateTermine.count - 1 do
  begin
    name := IrrigateTermine[i];
    Menge := StateIniF.ReadFloat(SubModName, IrrigateTermine[i], 0.0);
    if Irrigations[i] = nil then
      StateCreate(name, '[mm]', Menge, true, Irrigations[i])
    else
    begin
      Irrigations[i].v := Menge;
      Irrigations[i].name := name;
    end;

    IrrigateTermine.AddObject(name, Irrigations[i]);
  end;
  inherited Init(GlobMod);

end;

procedure TIrrigate.CalcRates;

var
  index: integer;
  Irristate: TState;
  DateString: String;
  ActDate: TDateTime;
begin
  ActDate := GlobTime.v;
  DateString := DateToStr(ActDate);
  index := IrrigateTermine.IndexOf(DateString);
  If Index <> -1 then
  begin
    Irristate := Irrigations[index];
    Rain.f_v^ := Rain.v + Irristate.v;
    Irristate.v := 0.0;
  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TIrrigate]);
end;

end.
