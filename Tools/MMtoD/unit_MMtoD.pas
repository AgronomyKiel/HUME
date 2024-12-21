unit unit_MMtoD;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Math, ComCtrls, Spin, CheckLst, Mask, advspin, UVarREc,
  UState,
  Grids, AdvGrid, Buttons, UFormAddPar, BaseGrid;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    PageControlOutput: TPageControl;
    TabSheetMMFile: TTabSheet;
    MemoMM: TMemo;
    StatusBar1: TStatusBar;
    Panel2: TPanel;
    OpenButton: TButton;
    SaveButton: TButton;
    TabSheetTemp: TTabSheet;
    MemoOutput: TMemo;
    ButtonAnalyze: TButton;
    TabSheetState: TTabSheet;
    TabSheetVar: TTabSheet;
    TabSheetPar: TTabSheet;
    TabExVar: TTabSheet;
    AdvStringGridStateVar: TAdvStringGrid;
    ControlBar1: TControlBar;
    AdvStringGridPar: TAdvStringGrid;
    ControlBar2: TControlBar;
    SpeedButtonAddPar: TSpeedButton;
    AdvStringGridExVar: TAdvStringGrid;
    AdvStringGridVar: TAdvStringGrid;
    SpeedButtonSavePar: TSpeedButton;
    SpeedButtonLoadPar: TSpeedButton;
    ControlBar3: TControlBar;
    SpeedButtonNewExVar: TSpeedButton;
    SpeedButtonSaveExVar: TSpeedButton;
    SpeedButtonLoadExVar: TSpeedButton;
    TabSheetConstants: TTabSheet;
    AdvStringGridConst: TAdvStringGrid;
    SpeedButtonDelExVar: TSpeedButton;
    SpeedButtonchangeExToPar: TSpeedButton;
    ControlBar4: TControlBar;
    SpeedButtonChangeVar_to_Par: TSpeedButton;
    SpeedButtonSaveStateGrid: TSpeedButton;
    SpeedButtonSaveVarGrid: TSpeedButton;
    SaveAllToTableButton: TButton;

    procedure OpenButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure SpeedButtonAddParClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButtonSaveParClick(Sender: TObject);
    procedure SpeedButtonLoadParClick(Sender: TObject);
    procedure SpeedButtonNewExVarClick(Sender: TObject);
    procedure SpeedButtonSaveExVarClick(Sender: TObject);
    procedure SpeedButtonLoadExVarClick(Sender: TObject);
    procedure ButtonAnalyzeClick(Sender: TObject);
    procedure SpeedButtonDelExVarClick(Sender: TObject);
    procedure SpeedButtonchangeExToParClick(Sender: TObject);
    procedure SpeedButtonChangeVar_to_ParClick(Sender: TObject);
    procedure SpeedButtonSaveStateGridClick(Sender: TObject);
    procedure SpeedButtonSaveVarGridClick(Sender: TObject);
    procedure SaveAllToTableButtonClick(Sender: TObject);

  private
    { Private-Deklarationen }

  public
    { Public-Deklarationen }
    SubModelName: String;

    SubModName: string; // Name of instance
    StateStrList: TStringList; // List of state variables
    ParStrList: TStringList; // List of parameters
    VarStrList: TStringList; // List of variables
    ConstStrList: TStringList; // List of constants
    ExternVStrList: TStringList; // List of external values
    IEventStrList: TStringList; // List of Independent Events
    ArgList: TStringList; // List of used arguments in functions
    AllArgs: TStringList; // List of all arguments in submodel
    procedure write_ClassDefinition;
    { procedure write_ProcCreateAll;
      procedure write_ProcInit;
      procedure write_ProcCalcRates; }

  end;

var
  Form1: TForm1;

implementation

uses UFormAddExVar;
{$R *.DFM}

procedure Extract_Arguments(InStr: string; var Arguments: TStringList);

// this procedure extracts argument strings

const
  Letters: set of Char = ['A' .. 'Z', 'a' .. 'z', '_'];
  Numbers: set of Char = ['0' .. '9'];
  Operators: set of Char = ['+', '-', '*', '/', '(', ')'];
  // functions : set of string = ['max', 'min', 'abs', 'ln', 'exp', 'div', 'mod'];
var
  i: integer;
  ch: Char;
  newarg: string;

begin
  Arguments.Clear;
  newarg := '';
  for i := 1 to length(InStr) do
  begin
    if (InStr[i] in Letters) or ((InStr[i] in Numbers) and (newarg <> '')) then
      newarg := newarg + InStr[i]
    else
    begin
      if newarg <> '' then
      begin
        if (uppercase(newarg) <> 'ABS') and (uppercase(newarg) <> 'ATAN') and
          (uppercase(newarg) <> 'COS') and (uppercase(newarg) <> 'EXP') and
          (uppercase(newarg) <> 'LN') and (uppercase(newarg) <> 'ROUND') and
          (uppercase(newarg) <> 'SIN') and (uppercase(newarg) <> 'SQRT') and
          (uppercase(newarg) <> 'SQR') and (uppercase(newarg) <> 'TRUNC') and
          (lowercase(newarg) <> 'max') and (lowercase(newarg) <> 'and') and
          (lowercase(newarg) <> 'or') and (lowercase(newarg) <> 'not') and
          (lowercase(newarg) <> 'min') and (lowercase(newarg) <> 'i') and
          (lowercase(newarg) <> 't') and (lowercase(newarg) <> 'div') then
          Arguments.Append(newarg);
        newarg := '';
      end;
    end;
  end;

end;

procedure TForm1.write_ClassDefinition;

const
  TempFileName = 'temp_file.txt';

var
  cf: textfile; // CodeFile
  cfn: string; // CodeFileName
  i, j: integer;
  ActVar: TVar;
  ActSTate: TState;
  ActPar: TPar;
  ActEx: TExternV;
  ActEvent: T_CompEvent;

begin
  cfn := TempFileName;
  assignfile(cf, cfn);
  rewrite(cf);
  writeln(cf, 'unit U', SubModelName, ';');
  writeln(cf);
  writeln(cf, 'interface');

  writeln(cf);
  writeln(cf, 'uses');
  writeln(cf,
    '  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;');

  writeln(cf);
  writeln(cf, 'Type');
  writeln(cf);
  writeln(cf, 'T', SubModelName, ' = class(TSubmodel)');

  writeln(cf);
  writeln(cf, 'private');
  { Private declarations }
  writeln(cf);
  writeln(cf, 'protected');
  { Protected declarations }
  writeln(cf);
  writeln(cf, 'public');

  for i := 0 to VarStrList.count - 1 do
  begin
    ActVar := TVar(VarStrList.objects[i]);
    ActVar.write_declaration(cf);
  end;
  writeln(cf);
  writeln(cf);
  writeln(cf, '  // Constant Variables');

  for i := 0 to ConstStrList.count - 1 do
  begin
    ActVar := TVar(ConstStrList.objects[i]);
    ActVar.write_declaration(cf);
  end;
  writeln(cf);

  writeln(cf);
  writeln(cf, '  // State Variables');

  for i := 0 to StateStrList.count - 1 do
  begin
    ActSTate := TState(StateStrList.objects[i]);
    ActSTate.write_declaration(cf);
  end;

  writeln(cf);
  writeln(cf, '             // Parameters');

  for i := 0 to ParStrList.count - 1 do
  begin
    ActPar := TPar(ParStrList.objects[i]);
    ActPar.write_declaration(cf);
  end;

  writeln(cf);
  writeln(cf, '             // External Variables');

  for i := 0 to ExternVStrList.count - 1 do
  begin
    ActEx := TExternV(ExternVStrList.objects[i]);
    ActEx.write_declaration(cf);
  end;

  writeln(cf);
  writeln(cf);
  writeln(cf, '  procedure createAll; override; ');
  writeln(cf, '  procedure Init(var GlobMod: TMod); override; ');
  writeln(cf, '  procedure CalcRates; override; ');
  writeln(cf);

  writeln(cf);
  writeln(cf, 'published');
  for i := 0 to VarStrList.count - 1 do
  begin
    ActVar := TVar(VarStrList.objects[i]);
    ActVar.write_property(cf);
  end;
  writeln(cf);

  for i := 0 to StateStrList.count - 1 do
  begin
    ActSTate := TState(StateStrList.objects[i]);
    ActSTate.write_property(cf);
  end;
  writeln(cf);

  writeln(cf);
  writeln(cf, '         // Parameters');

  for i := 0 to ParStrList.count - 1 do
  begin
    ActPar := TPar(ParStrList.objects[i]);
    ActPar.write_property(cf);
  end;

  writeln(cf);
  writeln(cf, '         // Properties External Variables');

  for i := 0 to ExternVStrList.count - 1 do
  begin
    ActEx := TExternV(ExternVStrList.objects[i]);
    ActEx.write_property(cf);
  end;

  writeln(cf);
  writeln(cf);

  writeln(cf, 'end;  // SubmodelName');

  writeln(cf);
  writeln(cf, 'procedure Register;');

  writeln(cf);
  writeln(cf, 'implementation');

  writeln(cf);
  writeln(cf, 'procedure T', SubModelName, '.createAll;');
  writeln(cf);

  writeln(cf, 'begin');
  writeln(cf, '  inherited createAll;');
  for i := 0 to VarStrList.count - 1 do
  begin
    ActVar := TVar(VarStrList.objects[i]);
    ActVar.write_Create(cf);
  end;
  writeln(cf);

  for i := 0 to ConstStrList.count - 1 do
  begin
    ActVar := TVar(ConstStrList.objects[i]);
    ActVar.write_Create(cf);
  end;
  writeln(cf);

  for i := 0 to StateStrList.count - 1 do
  begin
    ActSTate := TState(StateStrList.objects[i]);
    ActSTate.write_Create(cf);
  end;
  writeln(cf);

  writeln(cf);
  writeln(cf, '  // Parameters');

  for i := 0 to ParStrList.count - 1 do
  begin
    ActPar := TPar(ParStrList.objects[i]);
    ActPar.write_Create(cf);
  end;
  writeln(cf);
  writeln(cf, '         // External Variable');

  for i := 0 to ExternVStrList.count - 1 do
  begin
    ActEx := TExternV(ExternVStrList.objects[i]);
    ActEx.write_Create(cf);
  end;

  writeln(cf, 'end;');

  writeln(cf);
  writeln(cf);

  writeln(cf, 'procedure T', SubModelName, '.init(var GlobMod: TMod);');
  writeln(cf);
  writeln(cf, 'begin');
  writeln(cf, '  inherited init(GlobMod);');
  for i := 0 to StateStrList.count - 1 do
  begin
    ActSTate := TState(StateStrList.objects[i]);
    ActSTate.write_init(cf);
  end;
  writeln(cf);

  for i := 0 to ConstStrList.count - 1 do
  begin
    ActVar := TVar(ConstStrList.objects[i]);
    ActVar.write_init(cf);
  end;
  writeln(cf);

  writeln(cf, 'end;');

  writeln(cf);
  writeln(cf);
  writeln(cf, 'procedure T', SubModelName, '.CalcRates;');
  writeln(cf);
  writeln(cf, 'begin');
  writeln(cf);

  for i := 0 to VarStrList.count - 1 do
  begin
    ActVar := TVar(VarStrList.objects[i]);
    ActVar.write_Rate(cf);
  end;
  writeln(cf);

  writeln(cf);
  for i := 0 to StateStrList.count - 1 do
  begin
    ActSTate := TState(StateStrList.objects[i]);
    ActSTate.write_Rate(cf);
  end;
  writeln(cf);
  writeln(cf);

  writeln(cf, 'end;');

  writeln(cf);
  writeln(cf);
  If self.IEventStrList.count > 0 then
  begin
    writeln(cf, 'procedure T', SubModelName, '.Integrate;');
    writeln(cf);
    writeln(cf, 'begin');
    writeln(cf);
    writeln(cf, '  inherited  integrate;');
    for i := 0 to self.IEventStrList.count - 1 do
    begin
      ActEvent := T_CompEvent(IEventStrList.objects[i]);
      writeln(cf, '  If ' + ActEvent.conditionStr + ' then begin');
      for j := 1 to 20 do
      begin
        if ActEvent.ActionStrArr[j] <> '' then
          writeln(cf, '    ' + ActEvent.ActionStrArr[j]);
      end;
      writeln(cf, '  end;');
    end;
    writeln(cf);
    writeln(cf);
  end;

  writeln(cf);
  writeln(cf, 'end;');
  writeln(cf);

  writeln(cf, 'procedure Register;');
  writeln(cf, 'begin');
  writeln(cf, '  RegisterComponents(', '''Ceres Wheat''', ', ', '[T',
    SubModelName, ']);');
  writeln(cf, 'end;');
  writeln(cf);

  writeln(cf, 'end.');

  closefile(cf);
  MemoOutput.Lines.LoadFromFile(cfn);
  SaveButton.Enabled := true;
end;

procedure TForm1.OpenButtonClick(Sender: TObject);

const
  Letters: set of Char = ['A' .. 'Z', 'a' .. 'z', '_'];

var
  MMFile, TempFile, Resultfile: textfile;
  LO, L, Vari, Vari2, Keyword, VariType, Diff, varunit: String;
  P, i, j, k, zz, VarCount, ValCount, CompCount, CompEvCount, row: integer;
  firstValue: boolean;
  VRec: AListRecord;
  VList: TList;
  NewVar, ActVar: TVar;
  NewConst, ActConst: TVar;
  NewState, ActSTate: TState;
  NewPar: TPar;
  NewExV: TExternV;
  CondVar: boolean;
  VarName, VarComment, VarRateStr, IniValueStr, conditionStr, ActionStr, arg,
    newarg, LoopStr: string;
  IniValue: real;
  CEvent: T_CompEvent;
  LastVarEvent: boolean;
  upper_bound, lower_bound: integer;
  indexVar: boolean;

begin
  self.VarStrList.Clear;
  self.StateStrList.Clear;
  self.VarStrList.Clear;
  self.ParStrList.Clear;
  self.ExternVStrList.Clear;

  if OpenDialog1.Execute=true then
  begin
    assignfile(MMFile, OpenDialog1.FileName);
    { Append(MMFile);
      Writeln(MMFile, ''); }
    Reset(MMFile);

    // DecimalSeparator:= DecSepEdit.Text[1];


    // Start Leseroutine

    while not eof(MMFile) do
    begin

      Readln(MMFile, LO); // Read in string to analyse

      // Entfernen doppelter Leerzeichen

      while pos('  ', LO) > 0 do
        delete(LO, pos('  ', LO), 1);

      L := lowercase(LO); // temporary string, all lowercase
      LO := lowercase(LO); // convert to all lowercase

      If (pos('sub', LO) = 1) or ((pos('main', LO) = 1)) then
        SubModelName := LO;
      LastVarEvent := false;
      repeat

        If LastVarEvent = false then
        begin // new variable?
          Readln(MMFile, LO);
          LastVarEvent := false;
        end;

        /// /////// Variables ///

        if (pos('variable:', LO) > 0) then
        begin
          LastVarEvent := false;
          VarComment := '';
          VarRateStr := '';
          LoopStr := '';
          varunit := '';
          CondVar := true;
          indexVar := false;
          If pos('[', LO) = 0 then
            VarName := copy(LO, pos(':', LO) + 1,
              pos('  ', LO) - pos(':', LO) - 1)
          else
            VarName := copy(LO, pos(':', LO) + 1,
              pos('[', LO) - pos(':', LO) - 1);
          If pos('Unconditional', LO) <> 0 then
            CondVar := false;
          if (pos('[', LO) > 0) then
          begin
            indexVar := true;
            lower_bound := StrtoInt(copy(LO, pos('[', LO) + 1,
                pos('..', LO) - pos('[', LO) - 1));
            upper_bound := StrtoInt(copy(LO, pos('..', LO) + 2,
                pos(']', LO) - pos('..', LO) - 2));
            LoopStr := #10#13'  For i := ' + InttoStr(lower_bound)
              + ' to ' + InttoStr(upper_bound) + ' do'#10#13;
          end;

          Readln(MMFile, LO);
          If pos('=', LO) = 0 then
          begin
            VarComment := LO;
            If pos('[', VarComment) <> 0 then
              varunit := copy(VarComment, pos('[', VarComment),
                pos(']', VarComment) - pos('[', VarComment) + 1);
            Readln(MMFile, LO);
          end;
          If CondVar = true then
          begin
            // readln(mmfile);
            // VarRateSTr := Varname+'.v := ';
            repeat
              Readln(MMFile, LO);
              If pos('for', LO) <> 0 then
              begin
                conditionStr := copy(LO, pos('for', LO) + 4,
                  length(LO) - pos('for', LO));
                Extract_Arguments(conditionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, conditionStr) <> 0 then
                    conditionStr := stringreplace(conditionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;
                ActionStr := copy(LO, 1, pos('for', LO) - 1);
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, ActionStr) <> 0 then
                    ActionStr := stringreplace(ActionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;

                If VarRateStr = '' then
                  VarRateStr := LoopStr;
                If indexVar then
                  VarRateStr := VarRateStr + '  If ' + conditionStr +
                    ' then '#13#10'    ' + VarName + '[i].v := ' + ActionStr +
                    #13#10'  else '
                else
                  VarRateStr := VarRateStr + '  If ' + conditionStr +
                    ' then '#13#10'    ' + VarName + '.v := ' + ActionStr +
                    #13#10'  else ';

              end;
              If pos('by default', LO) <> 0 then
              begin
                ActionStr := copy(LO, 1, pos('by default', LO) - 1);
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, ActionStr) <> 0 then
                    ActionStr := stringreplace(ActionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;

                VarRateStr := VarRateStr +
                { '  end else '+ } VarName + '.v := ' + ActionStr;
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
              end;
            until pos('by default', LO) <> 0;
          end
          else
          begin
            // readln(mmfile, lo);
            VarRateStr := copy(LO, pos('=', LO) + 1, length(LO) - pos('=', LO));
            Extract_Arguments(VarRateStr, ArgList);
            AllArgs.CommaText := AllArgs.CommaText + ',' + ArgList.CommaText;
            for i := 0 to ArgList.count - 1 do
            begin
              arg := ArgList[i];
              newarg := arg + '.v';
              if pos(arg, VarRateStr) <> 0 then
              begin
                VarRateStr := stringreplace(VarRateStr, arg, newarg,
                  [rfReplaceAll, rfIgnoreCase]);
              end;
            end;
            If indexVar then
              VarRateStr := LoopStr + #10#13 + VarName + '[i].v := ' +
                VarRateStr
            else
              VarRateStr := VarName + '.v := ' + VarRateStr

          end;

          VarRateStr := stringreplace(VarRateStr, '.v[i]', '[i].v',
            [rfReplaceAll, rfIgnoreCase]);
          // NewVar.Comment := VarComment;
          NewVar := TVar.create(VarName, '', 0, VarComment);
          NewVar.RateSTring := VarRateStr;
          NewVar.U := varunit;
          NewVar.Indexed := indexVar;
          NewVar.lowerbound := lower_bound;
          NewVar.upperbound := upper_bound;

          VarStrList.AddObject(NewVar.name, NewVar);
        end;

        /// /////// Flows ///

        if (pos('flow:', LO) > 0) then
        begin
          LastVarEvent := false;
          VarComment := '';
          VarRateStr := '';
          LoopStr := '';
          varunit := '';
          CondVar := true;
          indexVar := false;
          If pos('[', LO) = 0 then
            VarName := copy(LO, pos(':', LO) + 1,
              pos('  ', LO) - pos(':', LO) - 1)
          else
            VarName := copy(LO, pos(':', LO) + 1,
              pos('[', LO) - pos(':', LO) - 1);
          If pos('Unconditional', LO) <> 0 then
            CondVar := false;
          if (pos('[', LO) > 0) then
          begin
            indexVar := true;
            lower_bound := StrtoInt(copy(LO, pos('[', LO) + 1,
                pos('..', LO) - pos('[', LO) - 1));
            upper_bound := StrtoInt(copy(LO, pos('..', LO) + 2,
                pos(']', LO) - pos('..', LO) - 2));
            VarRateStr := #10#13 + '  For i := ' + InttoStr(lower_bound)
              + ' to ' + InttoStr(upper_bound) + ' do'#10#13;
          end;

          Readln(MMFile, LO);
          Readln(MMFile, LO);
          If pos('=', LO) = 0 then
          begin
            VarComment := LO;
            If pos('[', VarComment) <> 0 then
              varunit := copy(VarComment, pos('[', VarComment),
                pos(']', VarComment) - pos('[', VarComment) + 1);
            Readln(MMFile, LO);
          end;
          If CondVar = true then
          begin
            // readln(mmfile);
            // VarRateSTr := Varname+'.v := ';
            repeat
              Readln(MMFile, LO);
              If pos('for', LO) <> 0 then
              begin
                conditionStr := copy(LO, pos('for', LO) + 4,
                  length(LO) - pos('for', LO));
                Extract_Arguments(conditionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, conditionStr) <> 0 then
                    conditionStr := stringreplace(conditionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;
                ActionStr := copy(LO, 1, pos('for', LO) - 1);
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, ActionStr) <> 0 then
                  begin
                    ActionStr := stringreplace(ActionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                    ActionStr := stringreplace(ActionStr, '.v[i]', '[i].v',
                      [rfReplaceAll, rfIgnoreCase]);
                  end;
                end;

                VarRateStr := VarRateStr + '  If ' + conditionStr +
                  ' then '#13#10'    ' + VarName + '.v := ' + ActionStr +
                  #13#10' else ';

              end;
              If pos('by default', LO) <> 0 then
              begin
                ActionStr := copy(LO, 1, pos('by default', LO) - 1);
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, ActionStr) <> 0 then
                    ActionStr := stringreplace(ActionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;

                VarRateStr := VarRateStr +
                { '  end else '+ } VarName + '.v := ' + ActionStr;
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
              end;
            until pos('by default', LO) <> 0;
          end
          else
          begin
            // readln(mmfile, lo);
            VarRateStr := copy(LO, pos('=', LO) + 1, length(LO) - pos('=', LO));
            Extract_Arguments(VarRateStr, ArgList);
            AllArgs.CommaText := AllArgs.CommaText + ',' + ArgList.CommaText;
            for i := 0 to ArgList.count - 1 do
            begin
              arg := ArgList[i];
              newarg := arg + '.v';
              if pos(arg, VarRateStr) <> 0 then
              begin
                VarRateStr := stringreplace(VarRateStr, arg, newarg,
                  [rfReplaceAll, rfIgnoreCase]);
                VarRateStr := stringreplace(VarRateStr, '.v[i]', '[i].v',
                  [rfReplaceAll, rfIgnoreCase]);
              end;
            end;
            If indexVar then
              VarRateStr := LoopStr + VarName + '[i].v := ' + VarRateStr
            else
              VarRateStr := VarName + '.v := ' + VarRateStr
          end;
          VarRateStr := stringreplace(VarRateStr, '.v[i]', '[i].v',
            [rfReplaceAll, rfIgnoreCase]);
          // NewVar.Comment := VarComment;

          NewVar := TVar.create(VarName, '', 0, VarComment);
          NewVar.RateSTring := VarRateStr;
          NewVar.U := varunit;
          VarStrList.AddObject(NewVar.name, NewVar);
        end;

        /// //////// State Variables ///
        if (pos('compartment:', LO) > 0) then
        begin
          LastVarEvent := false;
          VarComment := '';
          VarRateStr := '';
          LoopStr := '';
          varunit := '';
          CondVar := true;
          indexVar := false;
          If pos('[', LO) = 0 then
            VarName := copy(LO, pos(':', LO) + 1,
              pos('  ', LO) - pos(':', LO) - 1)
          else
            VarName := copy(LO, pos(':', LO) + 1,
              pos('[', LO) - pos(':', LO) - 1);
          If pos('Unconditional', LO) <> 0 then
            CondVar := false;
          if (pos('[', LO) > 0) then
          begin
            indexVar := true;
            lower_bound := StrtoInt(copy(LO, pos('[', LO) + 1,
                pos('..', LO) - pos('[', LO) - 1));
            upper_bound := StrtoInt(copy(LO, pos('..', LO) + 2,
                pos(']', LO) - pos('..', LO) - 2));
            LoopStr := '  For i := ' + InttoStr(lower_bound) + ' to ' + InttoStr
              (upper_bound) + ' do'#10#13;
          end;

          Readln(MMFile, LO);
          If pos('=', LO) = 0 then
          begin
            VarComment := LO;
            If pos('[', VarComment) <> 0 then
              varunit := copy(VarComment, pos('[', VarComment),
                pos(']', VarComment) - pos('[', VarComment) + 1);
            Readln(MMFile, LO);
          end;
          If CondVar = true then
          begin
            // readln(mmfile);
            VarRateStr := '';
            repeat
              Readln(MMFile, LO);

              If pos('for', LO) <> 0 then
              begin
                conditionStr := copy(LO, pos('for', LO) + 4,
                  length(LO) - pos('for', LO));
                Extract_Arguments(conditionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, conditionStr) <> 0 then
                    conditionStr := stringreplace(conditionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;

                ActionStr := copy(LO, 1, pos('for', LO) - 1);
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, ActionStr) <> 0 then
                    ActionStr := stringreplace(ActionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;

                If indexVar then
                  VarRateStr := VarRateStr + ' If ' + conditionStr +
                    ' then '#13#10'    ' + VarName + '[i].c := ' + ActionStr +
                    #13#10'  else '
                else
                  VarRateStr := VarRateStr + '  If ' + conditionStr +
                    ' then '#13#10'    ' + VarName + '.c := ' + ActionStr +
                    #13#10'  else ';
              end;
              If pos('by default', LO) <> 0 then
              begin
                ActionStr := copy(LO, 1, pos('by default', LO) - 1);
                Extract_Arguments(ActionStr, ArgList);
                AllArgs.CommaText := AllArgs.CommaText + ',' +
                  ArgList.CommaText;
                for i := 0 to ArgList.count - 1 do
                begin
                  arg := ArgList[i];
                  newarg := arg + '.v';
                  if pos(arg, ActionStr) <> 0 then
                    ActionStr := stringreplace(ActionStr, arg, newarg,
                      [rfReplaceAll, rfIgnoreCase]);
                end;

                VarRateStr := VarRateStr +
                { '  end else '+ } VarName + '.c := ' + ActionStr;
              end;

              // VarRateStr := VarRateStr+lo;
            until pos('by default', LO) <> 0;
          end
          else
          begin
            // readln(mmfile, lo);
            VarRateStr := copy(LO, pos('=', LO) + 1, length(LO) - pos('=', LO));
            Extract_Arguments(VarRateStr, ArgList);
            AllArgs.CommaText := AllArgs.CommaText + ',' + ArgList.CommaText;
            for i := 0 to ArgList.count - 1 do
            begin
              arg := ArgList[i];
              newarg := arg + '.v';
              if pos(arg, VarRateStr) <> 0 then
              begin
                VarRateStr := stringreplace(VarRateStr, arg, newarg,
                  [rfReplaceAll, rfIgnoreCase]);
                VarRateStr := stringreplace(VarRateStr, '.v[i]', '[i].v',
                  [rfReplaceAll, rfIgnoreCase]);
              end;
            end;
            If indexVar then
              VarRateStr := LoopStr + VarName + '[i].c := ' + VarRateStr
            else
              VarRateStr := VarName + '.c := ' + VarRateStr

              // VarRateSTr := lo;
          end;
          Readln(MMFile, LO);
          IniValueStr := copy(LO, pos('=', LO) + 1, length(LO) - pos('=', LO));

          // If Letters in IniValueStr then begin

          // end;

          try
          //  IniValue := strtofloat(IniValueStr);
          except
          on econverterror do
            IniValue := 0;
          end;
          VarRateStr := stringreplace(VarRateStr, '.v[i]', '[i].v',
            [rfReplaceAll, rfIgnoreCase]);
          // NewState.Comment := VarComment;
          NewState := TState.create(VarName, '', 0, IniValue, VarComment);
          NewState.RateSTring := VarRateStr;
          NewState.inistring := IniValueStr;
          NewState.U := varunit;
          NewState.Indexed := indexVar;
          NewState.lowerbound := lower_bound;
          NewState.upperbound := upper_bound;
          StateStrList.AddObject(NewState.name, NewState);
        end;

        /// //////// define value: ///
        if (pos('define value:', LO) > 0) then
        begin
          LastVarEvent := false;
          VarComment := '';
          VarRateStr := '';
          LoopStr := '';
          CondVar := false;
          If pos('[', LO) = 0 then
            VarName := copy(LO, pos(':', LO) + 1,
              pos('  ', LO) - pos(':', LO) - 1)
          else
            VarName := copy(LO, pos(':', LO) + 1,
              pos('[', LO) - pos(':', LO) - 1);
          If pos('Conditional', LO) <> 0 then
            CondVar := true;
          if (pos('[', LO) > 0) then
          begin
            indexVar := true;
            lower_bound := StrtoInt(copy(LO, pos('[', LO) + 1,
                pos('..', LO) - pos('[', LO) - 1));
            upper_bound := StrtoInt(copy(LO, pos('..', LO) + 2,
                pos(']', LO) - pos('..', LO) - 2));
          end;

          Readln(MMFile, LO);
          If pos('=', LO) = 0 then
          begin
            VarComment := LO;
            Readln(MMFile, LO);
          end;
          If CondVar = true then
          begin
            // readln(mmfile);
            VarRateStr := '';
            repeat
              Readln(MMFile, LO);
              VarRateStr := VarRateStr + LO;
            until pos('by default', LO) <> 0;
          end
          else
          begin
            // readln(mmfile, lo);
            VarRateStr := copy(LO, pos('=', LO) + 1, length(LO) - pos('=', LO));
          end;

          VarRateStr := stringreplace(VarRateStr, '.v[i]', '[i].v',
            [rfReplaceAll, rfIgnoreCase]);
          // NewConst.Comment := VarComment;
          NewConst := TVar.create(VarName, '', 0, VarComment);
          NewConst.RateSTring := VarRateStr;
          ConstStrList.AddObject(NewConst.name, NewConst);
        end;

        /// //////// Indepentent Events ///
        if (pos('independent event:', LO) > 0) then
        begin
          CEvent := T_CompEvent.create;
          LastVarEvent := true;
          CEvent.Name := copy(LO, pos(':', LO) + 1,
            pos('  ', LO) - pos(':', LO));
          Readln(MMFile, LO);
          If (pos('=', LO) = 0) and (pos('>', LO) = 0) and (pos('<', LO) = 0)
            then
          begin
            CEvent.Comment := LO;
            Readln(MMFile, LO);
          end;
          CEvent.conditionStr := LO;

          Readln(MMFile, LO); // Tolerance
          Readln(MMFile, LO); // Actions
          i := 1;
          repeat
            Readln(MMFile, LO);
            inc(i);
            if (pos(';', LO) <> 0) or (pos('//', LO) <> 0) then
            begin
              CEvent.ActionStrArr[i] := LO;
              CEvent.ActionStrArr[i] := stringreplace(CEvent.ActionStrArr[i],
                '=', ':=', [rfReplaceAll, rfIgnoreCase]);
            end;
          until (pos(':', LO) <> 0); //(pos(';', LO) = 0) and (pos('//', LO) = 0);

          IEventStrList.AddObject(CEvent.name, CEvent);
        end;

        if (pos('component event:', LO) > 0) then
        begin
          CEvent := T_CompEvent.create;
          LastVarEvent := true;
          CEvent.Name := copy(LO, pos(':', LO) + 1,
            pos('  ', LO) - pos(':', LO));
          Readln(MMFile, LO);
          If (pos('=', LO) = 0) and (pos('>', LO) = 0) and (pos('<', LO) = 0)
            then
          begin
            CEvent.Comment := LO;
            Readln(MMFile, LO);
          end;
          CEvent.conditionStr := LO;

          Readln(MMFile, LO); // Tolerance
          Readln(MMFile, LO); // Actions
          i := 1;
          repeat
            Readln(MMFile, LO);
            inc(i);
            if (pos(';', LO) <> 0) or (pos('//', LO) <> 0) then
            begin
              CEvent.ActionStrArr[i] := LO;
              CEvent.ActionStrArr[i] := stringreplace(CEvent.ActionStrArr[i],
                '=', ':=', [rfReplaceAll, rfIgnoreCase]);
            end;
          until (pos(';', LO) = 0); // and (pos('//', lo) = 0);

          IEventStrList.AddObject(CEvent.name, CEvent);
        end;

      until (pos('sub', LO) = 1) or (eof(MMFile));
      // Bis zum Beginn des nächsten Submodells





      // ################################################
      // ################################################

    end;
    closefile(MMFile);
    MemoMM.Lines.LoadFromFile(OpenDialog1.FileName);
    // AdvStringGridStateVar.Clear;
    AdvStringGridStateVar.RemoveRows(2, AdvStringGridStateVar.rowcount - 2);
    AdvStringGridStateVar.rowcount := StateStrList.count + 1;

    for i := 0 to StateStrList.count - 1 do
    begin
      ActSTate := TState(StateStrList.objects[i]);
      row := i + 1;
      AdvStringGridStateVar.Cells[0, row] := ActSTate.name;
      AdvStringGridStateVar.Cells[1, row] := floattostrf(ActSTate.v, ffgeneral,
        6, 3);
      AdvStringGridStateVar.Cells[2, row] := ActSTate.U;
      AdvStringGridStateVar.Cells[3, row] := ActSTate.RateSTring;
      AdvStringGridStateVar.Cells[4, row] := ActSTate.Comment;

    end;

    AdvStringGridVar.RemoveRows(2, AdvStringGridVar.rowcount - 2);
    AdvStringGridVar.rowcount := VarStrList.count + 1;

    for i := 0 to VarStrList.count - 1 do
    begin
      ActVar := TVar(VarStrList.objects[i]);
      row := i + 1;
      AdvStringGridVar.Cells[0, row] := ActVar.name;
      AdvStringGridVar.Cells[1, row] := ActVar.U;
      AdvStringGridVar.Cells[2, row] := ActVar.RateSTring;
      AdvStringGridVar.Cells[3, row] := ActVar.Comment;

    end;

    AdvStringGridConst.RemoveRows(2, AdvStringGridConst.rowcount - 2);
    AdvStringGridConst.rowcount := ConstStrList.count + 1;

    for i := 0 to ConstStrList.count - 1 do
    begin
      ActConst := TVar(ConstStrList.objects[i]);
      row := i + 1;
      AdvStringGridConst.Cells[0, row] := ActConst.name;
      AdvStringGridConst.Cells[1, row] := ActConst.U;
      AdvStringGridConst.Cells[2, row] := ActConst.RateSTring;
      AdvStringGridConst.Cells[3, row] := ActConst.Comment;

    end;

    write_ClassDefinition;
  end;

end;

procedure TForm1.SaveAllToTableButtonClick(Sender: TObject);

var
 s, v, p, c: integer;
 f : textfile;
 fn : string;
 act_state : TState;
 act_var : TVar;
 act_Par : TPar;


begin

  fn := 'AllVarsOut.csv';
  assignfile(f, fn);
  rewrite(f);
  writeln(f, 'IniFile;Submodel;EntityType;EntityName;Units;Value;Option;Comment');
  for s := 0 to  Form1.StateStrList.Count - 1 do begin
     act_state := TState(Form1.StateStrList.Objects[s]);
     write(f, 'Test.ini;', SubModelName, ';', 'State', ';');
     writeln(f, act_state.Name, ';', act_state.U, ';',act_state.IniString, ';', 'NA;', act_state.Comment);
  end;
  for s := 0 to  Form1.VarStrList.Count - 1 do begin
     act_Var := TVar(Form1.VarStrList.Objects[s]);
     write(f, 'Test.ini;', SubModelName, ';', 'Variable', ';');
     writeln(f, act_Var.Name, ';', act_Var.U, ';', 'NA;', act_var.Comment);
  end;
  for s := 0 to  Form1.ParStrList.Count - 1 do begin
     act_Par := TPar(Form1.ParStrList.Objects[s]);
     write(f, 'Test.ini;', SubModelName, ';', 'Parameter', ';');
     writeln(f, act_Par.Name, ';', act_Par.U, ';', act_Par.v, ';NA;', act_par.Comment);
  end;
  closefile(f);
end;

procedure TForm1.SaveButtonClick(Sender: TObject);

begin
  SaveDialog1.FileName := 'U' + SubModelName + '.pas';
  if SaveDialog1.Execute then
  begin
    self.MemoOutput.Lines.SaveToFile(SaveDialog1.FileName);
    // memoOUt.Lines.SaveToFile(SaveDialog1.FileName);
  end;

end;



procedure TForm1.SpeedButtonAddParClick(Sender: TObject);

var
  NewPar, par: TPar;
  i, row, cols: integer;
begin
  AddPardlg.tag := 0;
  AddPardlg.ShowModal;
  If AddPardlg.tag = 1 then
  begin
    NewPar.Comment := AddPardlg.EditComment.text;
    NewPar := TPar.create(AddPardlg.editname.text, AddPardlg.editunits.text,
      strtofloat(AddPardlg.EditValue.text), 0, NewPar.Comment);
    ParStrList.AddObject(NewPar.name, NewPar);
    AdvStringGridPar.rowcount := ParStrList.count + 1;
    for i := 0 to ParStrList.count - 1 do
    begin
      par := TPar(ParStrList.objects[i]);
      row := i + 1;
      AdvStringGridPar.Cells[0, row] := par.name;
      AdvStringGridPar.Cells[1, row] := floattostrf(par.v, ffgeneral, 6, 3);
      AdvStringGridPar.Cells[2, row] := par.U;
      AdvStringGridPar.Cells[3, row] := par.Comment;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  StateStrList := TStringList.create; // List of state
  StateStrList.Sorted := true;

  ParStrList := TStringList.create; // List of parameters
  ParStrList.Sorted := true;
  VarStrList := TStringList.create; // List of variables
  VarStrList.Sorted := true;
  ConstStrList := TStringList.create; // List of constants
  ConstStrList.Sorted := true;
  ExternVStrList := TStringList.create; // List of external values
  ExternVStrList.Duplicates := dupignore;
  ExternVStrList.Sorted := true;
  IEventStrList := TStringList.create;
  ArgList := TStringList.create;
  ArgList.Sorted := true;
  ArgList.Duplicates := dupignore;
  ArgList.Clear;
  AllArgs := TStringList.create;
  AllArgs.Sorted := true;
  AllArgs.Duplicates := dupignore;
  AllArgs.Clear;
  PageControlOutput.ActivePage := TabSheetMMFile;

end;

procedure TForm1.SpeedButtonSaveParClick(Sender: TObject);
begin
  SaveDialog1.Title := 'Parameterfile';
  SaveDialog1.FileName := '*.par';
  SaveDialog1.Filter := 'Parameterfiles (*.par)|*.par';
  SaveDialog1.Options := OpenDialog1.Options + [ofShowHelp, ofPathMustExist,
    ofFileMustExist];
  self.AdvStringGridPar.Delimiter := ';';
  if SaveDialog1.Execute then
  begin
    self.AdvStringGridPar.SaveTocsv(SaveDialog1.FileName);
  end

end;

procedure TForm1.SpeedButtonSaveStateGridClick(Sender: TObject);
var
 fn : string;
 f  : textfile;

begin
  fn := 'stategrid.csv';
//  assignfile(f, fn);
//  rewrite(f);
  self.AdvStringGridStateVar.SaveToCSV(fn);
end;

procedure TForm1.SpeedButtonSaveVarGridClick(Sender: TObject);
var
 fn : string;
begin
  fn := 'vargrid.csv';
//  assignfile(f, fn);
//  rewrite(f);
  self.AdvStringGridVar.SaveToCSV(fn);

end;

procedure TForm1.SpeedButtonLoadParClick(Sender: TObject);

var
  row: integer;
  NewPar: TPar;
  ParValue : real;
  ParName : string;
begin
  OpenDialog1.Title := 'Open Parameterfile';
  OpenDialog1.FileName := '*.par';
  OpenDialog1.Filter := 'Conrolfiles (*.par)|*.par';
  OpenDialog1.Options := OpenDialog1.Options + [ofShowHelp, ofPathMustExist,
    ofFileMustExist];
  if OpenDialog1.Execute then
  begin
    self.AdvStringGridPar.LoadFromCSV(OpenDialog1.FileName);
    ParStrList.Clear;
    for row := 1 to self.AdvStringGridPar.rowcount - 1 do
    if AdvStringGridPar.Cells[0, row] <> '' then begin
      begin
        ParName :=   AdvStringGridPar.Cells[0, row];
        if AdvStringGridPar.Cells[1, row] <> '' then begin

        try
         ParValue :=  strtofloat(AdvStringGridPar.Cells[1, row]);
        except
         ParValue := 0;
        end;
        end else ParValue := 0;
        NewPar := TPar.create(ParName,
        AdvStringGridPar.Cells[2, row],
          ParValue, 0, AdvStringGridPar.Cells[3, row]);
//      NewPar.Comment := ;
        ParStrList.AddObject(NewPar.name, NewPar);
      end;
    end;
  end;

end;

procedure TForm1.SpeedButtonNewExVarClick(Sender: TObject);
var
  NewExVar, exVar: TExternV;
  i, row, cols: integer;
begin
  AddPardlg.tag := 0;
  addExVardlg.ShowModal;
  If addExVardlg.tag = 1 then
  begin
    NewExVar := TExternV.create(addExVardlg.editname.text,
      addExVardlg.editunits.text, statefield, '');
    // NewExVar.Comment := addpardlg.EditComment.text;
    ExternVStrList.AddObject(NewExVar.name, NewExVar);
    self.AdvStringGridExVar.rowcount := ExternVStrList.count + 1;
    for i := 0 to ExternVStrList.count - 1 do
    begin
      exVar := TExternV(ExternVStrList.objects[i]);
      row := i + 1;
      AdvStringGridExVar.Cells[0, row] := exVar.name;
      AdvStringGridExVar.Cells[1, row] := exVar.U;
      AdvStringGridExVar.Cells[2, row] := exVar.Comment;
    end;
  end;

end;

procedure TForm1.SpeedButtonSaveExVarClick(Sender: TObject);
begin
  SaveDialog1.Title := 'Externval. File';
  SaveDialog1.FileName := '*.exv';
  SaveDialog1.Filter := 'Parameterfiles (*.exv)|*.exv';
  SaveDialog1.Options := OpenDialog1.Options + [ofShowHelp, ofPathMustExist,
    ofFileMustExist];
  self.AdvStringGridExVar.Delimiter := ';';
  if SaveDialog1.Execute then
  begin
    self.AdvStringGridExVar.SaveTocsv(SaveDialog1.FileName);
  end

end;

procedure TForm1.SpeedButtonLoadExVarClick(Sender: TObject);
var
  row: integer;
  NewExV: TExternV;
begin
  OpenDialog1.Title := 'Open ExVarfile';
  OpenDialog1.FileName := '*.exv';
  OpenDialog1.Filter := 'EXV-Files (*.exv)|*.exv';
  OpenDialog1.Options := OpenDialog1.Options + [ofShowHelp, ofPathMustExist,
    ofFileMustExist];
  if OpenDialog1.Execute then
  begin
    self.AdvStringGridExVar.LoadFromCSV(OpenDialog1.FileName);
    ExternVStrList.Clear;
    for row := 1 to self.AdvStringGridPar.rowcount - 1 do
    begin
      NewExV := TExternV.create(AdvStringGridPar.Cells[0, row],
        AdvStringGridPar.Cells[2, row], ratefield, '');
      NewExV.Comment := AdvStringGridPar.Cells[3, row];
      ExternVStrList.AddObject(NewExV.name, NewExV);
    end;
  end;
end;

procedure TForm1.ButtonAnalyzeClick(Sender: TObject);
var
  i, NrExVar, row: integer;
  NewExVar, exVar: TExternV;
  ActSTate: TState;
  ActVar, ActConst: TVar;
  ActPar: TPar;

begin
  NrExVar := 0;
  ExternVSTrList.clear;
  for i := 0 to AllArgs.count - 1 do
  begin
    if (StateStrList.IndexOf(AllArgs[i]) = -1) and
      (VarStrList.IndexOf(AllArgs[i]) = -1) and
      (ConstStrList.IndexOf(AllArgs[i]) = -1) and
      (self.ParStrList.IndexOf(AllArgs[i]) = -1) and (AllArgs[i] <> '') then
    begin
      //ExternVStrList.Append(AllArgs[i]);
      NewExVar := TExternV.create(AllArgs[i], '', statefield, '');
      ExternVStrList.AddObject(NewExVar.name, NewExVar);
    end;
  end;

  if AdvStringGridExVar.Cells[0, 2] <> '' then
  begin // already yet external or unknown variables identified
    AdvStringGridExVar.rowcount := ExternVStrList.count + 1;
    for i := 0 to ExternVStrList.count - 1 do
    begin
      exVar := TExternV(ExternVStrList.objects[i]);
      row := i + 1;
      exVar.name := AdvStringGridExVar.Cells[0, row];
      exVar.U := AdvStringGridExVar.Cells[1, row];
      exVar.Comment := AdvStringGridExVar.Cells[2, row];
    end;
  end
  else
  begin
    AdvStringGridExVar.rowcount := ExternVStrList.count + 1;
    for i := 0 to ExternVStrList.count - 1 do
    begin
      exVar := TExternV(ExternVStrList.objects[i]);
      row := i + 1;
      AdvStringGridExVar.Cells[0, row] := exVar.name;
      AdvStringGridExVar.Cells[1, row] := exVar.U;
      AdvStringGridExVar.Cells[2, row] := exVar.Comment;
    end;
  end;

  for i := 0 to StateStrList.count - 1 do
  begin
    ActSTate := TState(StateStrList.objects[i]);
    row := i + 1;
    ActSTate.name := AdvStringGridStateVar.Cells[0, row];
    ActSTate.v := strtofloat(AdvStringGridStateVar.Cells[1, row]);
    ActSTate.U := AdvStringGridStateVar.Cells[2, row];
    ActSTate.RateSTring := AdvStringGridStateVar.Cells[3, row];
    ActSTate.Comment := AdvStringGridStateVar.Cells[4, row];
  end;

  // advstringgridVar.RemoveRows(2, advstringgridVar.rowcount-2);
  // advstringgridVar.RowCount := VarStrList.count+1;

  for i := 0 to VarStrList.count - 1 do
  begin
    ActVar := TVar(VarStrList.objects[i]);
    row := i + 1;
    ActVar.name := AdvStringGridVar.Cells[0, row];
    ActVar.U := AdvStringGridVar.Cells[1, row];
    ActVar.RateSTring := AdvStringGridVar.Cells[2, row];
    ActVar.Comment := AdvStringGridVar.Cells[3, row];

  end;

  // advstringgridPar.RemoveRows(2, advstringgridPar.rowcount-2);
  // advstringgridPar.RowCount := ParStrList.count+1;

  for i := 0 to ParStrList.count - 1 do
  begin
    ActPar := TPar(ParStrList.objects[i]);
    row := i + 1;
    ActPar.name := AdvStringGridPar.Cells[0, row];
    if AdvStringGridPar.Cells[1, row] <> '' then
      try
        ActPar.v := strtofloat(AdvStringGridPar.Cells[1, row]);
      finally
      end;
    ActPar.U := AdvStringGridPar.Cells[2, row];
    ActPar.RateSTring := AdvStringGridPar.Cells[3, row];
    ActPar.Comment := AdvStringGridPar.Cells[4, row];

  end;



  // advstringgridConst.RemoveRows(2, advstringgridConst.rowcount-2);
  // advstringgridConst.RowCount := ConstStrList.count+1;

  for i := 0 to ConstStrList.count - 1 do
  begin
    ActConst := TVar(ConstStrList.objects[i]);
    row := i + 1;
    ActConst.name := AdvStringGridConst.Cells[0, row];
    ActConst.U := AdvStringGridConst.Cells[1, row];
    ActConst.RateSTring := AdvStringGridConst.Cells[2, row];
    ActConst.Comment := AdvStringGridConst.Cells[3, row];

  end;

  write_ClassDefinition;
end;

procedure TForm1.SpeedButtonDelExVarClick(Sender: TObject);

var
  index: integer;

begin

  index := ExternVStrList.IndexOf(AdvStringGridExVar.Cells[0,
    AdvStringGridExVar.row]);
  if index <> -1 then
    ExternVStrList.delete(index);

  index := AllArgs.IndexOf(AdvStringGridExVar.Cells[0, AdvStringGridExVar.row]);
  if index <> -1 then
    AllArgs.delete(index);

  AdvStringGridExVar.RemoveRowsEx(AdvStringGridExVar.row, 1);

end;

procedure TForm1.SpeedButtonchangeExToParClick(Sender: TObject);

var
  NewPar: TPar;
  exVar: TExternV;
  index: integer;
begin

  index := ExternVStrList.IndexOf(AdvStringGridExVar.Cells[0,
    AdvStringGridExVar.row]);
  if index <> -1 then
  begin
    exVar := TExternV(ExternVStrList.objects[index]);
    NewPar := TPar.create(exVar.name, exVar.U, 0.0, 0.0, ExVar.Comment);
    if ExVar.Comment <> '' then
      NewPar.Comment := ExVar.Comment;
    ParStrList.AddObject(NewPar.name, NewPar);
    ExternVStrList.delete(index);
  end;

  AdvStringGridExVar.RemoveRowsEx(AdvStringGridExVar.row, 1);
  self.AdvStringGridPar.InsertRows(ParStrList.IndexOf(NewPar.name) + 1, 1);
  AdvStringGridPar.Cells[0, ParStrList.IndexOf(NewPar.name) + 1] := NewPar.Name;

end;

procedure TForm1.SpeedButtonChangeVar_to_ParClick(Sender: TObject);

var
  NewPar: TPar;
  ActVar: TVar;
  index: integer;
begin

  index := self.VarStrList.IndexOf(AdvStringGridVar.Cells[0,
    AdvStringGridVar.row]);
  if index <> -1 then
  begin
    actVar := TVar(VarStrList.objects[index]);
    NewPar := TPar.create(actVar.name, actVar.U, 0.0, 0.0, actVar.Comment);
    if actVar.Comment <> '' then
      NewPar.Comment := actVar.Comment;
    ParStrList.AddObject(NewPar.name, NewPar);
    VarStrList.delete(index);
  end;

  AdvStringGridVar.RemoveRowsEx(AdvStringGridExVar.row, 1);
  AdvStringGridPar.InsertRows(ParStrList.IndexOf(NewPar.name) + 1, 1);
  AdvStringGridPar.Cells[0, ParStrList.IndexOf(NewPar.name) + 1] := NewPar.Name;

end;

end.
