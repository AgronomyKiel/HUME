unit UInput;

interface

uses
  UMod, UState, IniFiles, Classes, UAbstractSoilMin, JclFileUtils;

type
  ActionType = (Residues, Add, Replace);

  TAction = class
    A: ActionType;
    X: TExternV;
    V: real;
    C: real;
    N: real;
    constructor create(aA: ActionType; aX: TExternV; aV, aC, aN: real);
  end;

  TInput = class(TSubModel)
  protected
    fSoilMinMod: TAbstractSoilMin;
    InputIniFile: TMemIniFile;
    InputDates: TStringList;
    ExtVars: TStringList;
    NextDate: Integer;
    function ConvertDate(s: string): string;
    function FindExVar(s: string): TExternV;
  public

    f_FertSens: TPar;
    // factor to change in sensitivity analysis to change fertilizer rate
    f_FertSensVar: TVar; // =  f_FertSens; to be used in TDueng as ExternV

    // constructor Create(AOwner : Tcomponent); override;
    procedure Init(var GlobMod: TMod); Override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure CreateAll; override;
  published
    property SoilMinMod: TAbstractSoilMin read fSoilMinMod write fSoilMinMod;

    Property Var_f_FertSensVar: TVar read f_FertSensVar write f_FertSensVar;

    Property Par_f_FertSens: TPar read f_FertSens write f_FertSens;

  end;

procedure Register;

implementation

uses
  SysUtils;

{ constructor TInput.Create(AOwner : Tcomponent);
  begin
  inherited;
  InputDates := TStringList.Create;
  InputDates.Sorted := true;
  InputDates.Duplicates := dupAccept;
  ExtVars := TStringList.Create;
  end; }

procedure TInput.Init(var GlobMod: TMod);
var
  InputIniFN: string;
  sl: TStringList;
  Actions: TStringList;
  i, j: Integer;
  V, C, N: real;
  Datum: string;
begin
  inherited;
  If GlobMod.ActIniFile <> nil then
  begin
    InputIniFN := GlobMod.ActIniFile.FileName;
    InputIniFN := PathRemoveExtension(InputIniFN) + '_Input.ini';
    InputIniFile.Free;
    InputIniFile := TMemIniFile.create(InputIniFN);
    sl := TStringList.create;
    InputIniFile.ReadSections(sl);
    InputDates.Clear;
    Actions := TStringList.create;
    for i := 0 to sl.Count - 1 do
    begin
      Datum := ConvertDate(sl[i]);
      InputIniFile.ReadSection(sl[i], Actions);
      C := 0;
      N := 0;
      for j := 0 to Actions.Count - 1 do
      begin
        if UpperCase(Actions[j]) = 'C_RESIDUES' then
          C := InputIniFile.ReadFloat(sl[i], Actions[j], 0)
        else if UpperCase(Actions[j]) = 'N_RESIDUES' then
          N := InputIniFile.ReadFloat(sl[i], Actions[j], 0)
        else
        begin
          V := InputIniFile.ReadFloat(sl[i], Actions[j], 0);
          InputDates.AddObject(Datum, TAction.create(Add, FindExVar(Actions[j]),
            V, 0, 0));
        end;
        if (C > 0) and (N > 0) then
        begin
          InputDates.AddObject(Datum, TAction.create(Residues, nil, 0, C, N));
          C := 0;
          N := 0;
        end;
      end;
      Actions.Clear;
    end;
    Actions.Free;
    sl.Free;
    If InputDates.Count > 0 then
    begin
      i := 0;
      NextDate := StrToInt(InputDates[i]);
      while NextDate < GlobTime.V do
      begin
        if InputDates.Count > i then
          NextDate := StrToInt(InputDates[i]);
        inc(i);
      end;
    end
    else
      NextDate := 100000;
    f_FertSensVar.V := f_FertSens.V;
  end;
end;

procedure TInput.CalcRates;
begin

end;

procedure TInput.Integrate;
var
  i: Integer;
  exv: TExternV;
  V: real;
begin
  inherited;
  if GlobTime.V >= NextDate then
  begin
    InputDates.Find(IntToStr(NextDate), i);
    while StrToInt(InputDates[i]) <= GlobTime.V do
    begin
      case TAction(InputDates.Objects[i]).A of
        Residues:
          begin
            if Assigned(fSoilMinMod) then
              fSoilMinMod.AddResidues(TAction(InputDates.Objects[i]).C *
                f_FertSens.V, TAction(InputDates.Objects[i]).N * f_FertSens.V);
          end;
        Add:
          begin
            exv := TAction(InputDates.Objects[i]).X;
            V := TAction(InputDates.Objects[i]).V;
            exv.f_v^ := exv.f_v^ + V * f_FertSens.V;
          end;
      end;
      inc(i);
      if i >= InputDates.Count then
      begin
        NextDate := 100000;
        exit;
      end;
    end;
    NextDate := StrToInt(InputDates[i]);
  end;
end;

procedure TInput.CreateAll;
begin
  InputDates := TStringList.create;
  InputDates.Sorted := true;
  InputDates.Duplicates := dupAccept;
  ExtVars := TStringList.create;

  inherited CreateAll;
  VarCreate('f_FertSensVar', '', 1, true, f_FertSensVar);
  ParCreate('f_FertSens', '', 1, f_FertSens);

end;

function TInput.ConvertDate(s: string): string;
begin
  result := '0';
  if s <> '' then
  begin
    if Pos('.', s) > 0 then
      result := IntToStr(round(StrToDate(s)))
    else if StrToIntDef(s, 0) = StrToIntDef(s, 1) then
      result := s;
  end;
end;

function TInput.FindExVar(s: string): TExternV;
var
  SubMod, VName: string;
  i: Integer;
  exv: TExternV;
begin
  result := nil;
  if Pos('.', s) > 0 then
  begin
    SubMod := Copy(s, 1, Pos('.', s) - 1);
    VName := Copy(s, Pos('.', s) + 1, length(s) - Pos('.', s));
  end
  else
    VName := s;
  for i := 0 to ExtVars.Count - 1 do
    if (ExtVars[i] = s) or ((Pos('.', ExtVars[i]) > 0) and
      (Copy(ExtVars[i], Pos('.', ExtVars[i]) + 1, length(ExtVars[i]) - Pos('.',
      ExtVars[i])) = VName)) then
    begin
      result := TExternV(ExtVars.Objects[i]);
      break;
    end;
  if result = nil then
  begin
    ExternVcreate(VName, '', StateField, exv);
    ExtVars.AddObject(SubMod + '.' + VName, exv);
    result := exv;
  end;

end;

constructor TAction.create(aA: ActionType; aX: TExternV; aV, aC, aN: real);
begin
  A := aA;
  X := aX;
  V := aV;
  C := aC;
  N := aN;
end;

procedure Register;

begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TInput]);
{$ENDIF}
end;

end.
