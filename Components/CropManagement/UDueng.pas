unit UDueng;

interface

uses
  UMod, UState, IniFiles, Classes;

type

  TDuengungen = class
  private
    DList: TList;
    function getD(i: integer): TState;
    procedure setD(i: integer; st: TState);
  public
    property Duengungen[i: integer]: TState read getD write setD; default;
    constructor Create;
    procedure clear;
  end;

  TDueng = class(TSubModel)
  private

  protected

  public
    Duengungen: TDuengungen;
    DuengTermine: TStringList;
    f_rec: TPar;
    // recovery factor, only this fraction will be added as fertilizer
    f_ExtFertSens: TExternV;
    // factor to change in sensitivity analysis to change fertilizer rate, set in TInput
    SoilNitrate: TExternV;
    CumDueng: TState;

    // constructor Create(AOwner : TComponent); override;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;

  published
    property Ex_SoilNitrate: TExternV read SoilNitrate write SoilNitrate;
    property Ex_f_ExtFertSens: TExternV read f_ExtFertSens write f_ExtFertSens;
    Property St_CumDueng: TState read CumDueng write CumDueng;

  end;

procedure Register;

implementation

uses
  SysUtils
{$IFNDEF NONVISUAL}
    , vcl.Dialogs
{$ENDIF}
    ;

constructor TDuengungen.Create;
begin
  DList := TList.Create;
end;

procedure TDuengungen.clear;
begin
  DList.clear;
end;

function TDuengungen.getD(i: integer): TState;
begin
  if i < DList.Count then
  begin
    if DList[i] = nil then
      result := nil
    else
      result := TState(DList[i]);
  end
  else
    result := nil;
end;

procedure TDuengungen.setD(i: integer; st: TState);
begin
  while i > DList.Count do
    DList.Add(nil);
  if i = DList.Count then
    DList.Add(st)
  else
    DList[i] := st;
end;

procedure TDueng.CreateAll;

begin
  DuengTermine := TStringList.Create;
  Duengungen := TDuengungen.Create;
  inherited CreateAll;
  ExternVcreate('Nmin_1', '[kgN/ha]', STateField, SoilNitrate);
  StateCreate('CumDueng', '[kgN/ha]', 0.0, false, CumDueng);
  ParCreate('f_rec', '', 1.0, f_rec);
  ExternVcreate('f_FertSensVar', '', STateField, f_ExtFertSens);

end;

function isDate(const DateString: string): boolean;
var
  dt: TDateTime;
begin
  FormatSettings.shortdateformat := 'dd.mm.yyyy';
  FormatSettings.dateseparator := '.';
  result := TryStrToDate(DateString, dt);
end;

procedure TDueng.Init(var GlobMod: TMod);

var
  i, actStateNdx, ndx: integer;
  name: string;
  Menge: real;
  ActState, NewState: TState;

begin
  Duengungen.clear;
  for i := 0 to DuengTermine.Count - 1 do
  begin
    actStateNdx := StateStrList.IndexOf(DuengTermine[i]);
    if actStateNdx <> -1 then
    begin
      ActState := TState(StateStrList.Objects[actStateNdx]);
      ActState.Free;
      StateStrList.Delete(actStateNdx);
    end;
  end;
  DuengTermine.clear;

  inherited Init(GlobMod);

  if stateIniF <> nil then
  begin
    stateIniF.ReadSection(SubModName, DuengTermine);
    // writeln('Es wurden ', IntToStr(DuengTermine.count), ' Düngetermine eingelesen');
    ndx := 0;
    if DuengTermine.Count > 0 then
      repeat
        if (isDate(DuengTermine[ndx]) = false) then
          DuengTermine.Delete(ndx)
        else
          inc(ndx);
      until ndx > DuengTermine.Count - 1;
    DuengTermine.Sort;
    For i := 0 to DuengTermine.Count - 1 do
    begin
      name := DuengTermine[i];
      // writeln('Duengetermin: ', name);
      Menge := stateIniF.ReadFloat(SubModName, DuengTermine[i], 0.0);
      if (f_ExtFertSens.Source <> '') then
        Menge := Menge * f_ExtFertSens.v; // Adjust during Sensitivity analysis
      StateCreate(name, '[kg N/ha]', Menge, false, NewState);
      Duengungen[i] := NewState;
      Duengungen[i].v := Menge;
    end;
  end;
  // writeln(DuengTermine.Strings[1]);
end;

procedure TDueng.CalcRates;

var
  index: integer;
  FertState: TState;
  DateString: String;
  ActDate: TDateTime;
  ActDay, ActMonth, ActYear: word;
  ActDayStr, ActMonthStr, ActYearStr: string;

begin
  ActDate := GlobTime.v;
  DateString := DateToStr(ActDate);
  // Writeln('Maschinendatumsformat: '+DateString);
{$IFDEF LINUX}
  SysUtils.DecodeDate(GlobTime.v, ActYear, ActMonth, ActDay);
  ActDayStr := IntToStr(ActDay);
  if Length(ActDayStr) = 1 then
    ActDayStr := '0' + ActDayStr;
  ActMonthStr := IntToStr(ActMonth);
  if Length(ActMonthStr) = 1 then
    ActMonthStr := '0' + ActMonthStr;
  ActYearStr := IntToStr(ActYear);

  DateString := ActDayStr + '.' + ActMonthStr + '.' + ActYearStr;
  // writeln('Nach Konvertierung: ' + DateString);
{$ENDIF}
  index := DuengTermine.IndexOf(DateString);
  If Index <> -1 then
  begin
    FertState := Duengungen[index];
    { if (f_ExtFertSens = nil) then }
    SoilNitrate.v := SoilNitrate.v + FertState.v * f_rec.v
    { else
      SoilNitrate.f_v^ := SoilNitrate.v+FertState.v * f_rec.v* f_ExtFertSens.v };
    CumDueng.c := FertState.v;
    FertState.v := 0.0;
    Duengungen[index].v := 0.0;
    Duengungen[index].name := '';
  end
  else
    CumDueng.c := 0;
end;

procedure Register;

begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TDueng]);
{$ENDIF}
end;

end.
