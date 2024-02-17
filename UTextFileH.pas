unit UTextFileH;
{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

interface

uses
  classes, SysUtils, Ustate, UModUtils, math, IniFiles;

{* The class TtextFileH defines a simple ASCII file
  of a tabular structure which has a heading of two lines whereby the first lines
  gives the name of each column and the second line gives the corresponding units.
  The first column is reserved for the independent variable of the model which is
  usually the time.
  }
type
  TTextFileH = class(TPersistent)
//  TTextFileH = class(TObject)
  private
    fFileName: TMyFileName;
    procedure SetFilename (fn:TMyFileName);
    function  GetFilename:TMyFilename;
  public
    fFirstLine: TStringList;
    fUnitLine: TStringList;
    fn_Line: integer;
    ActLine: TStringList;
    actlines: TStringList;
    slFile: THashedStringList;
    actnr: Integer;
    constructor create; virtual;
    procedure NextLine;
    procedure FastNextLine;
    function getValue(Name: string): real;
    function getIndexValue(Index: integer): real;
    function indexOf(Name: string): Integer;
    procedure LocateFor(Name: string; Value: real);
    procedure GoTop;
    function GetFirstLine: string;
    function GetLastLine: string;
    function hasMoreLines(): Boolean;
    function containsName(name: string): boolean;
    procedure init(fFileName: string); virtual;

  published
    property FName: TMyFileName read GetFilename write SetFilename;
    property n_Line: integer read fn_line;
    property FirstLine: TStringList read fFirstLine;
    property UnitLine: TStringList read fUnitLine;
    procedure BeforeDestruction; override;
  end;

implementation

uses
  UMod
{$IFNDEF NONVISUAL}
  , vcl.Dialogs
{$ENDIF};

constructor TTextFileH.create;
var
  i: integer;
begin
  inherited create;
  fn_line := 0;
  actnr := 0;
  FName := '';
  fFirstLine := TStringList.Create;
  fFirstLine.OwnsObjects := true;
  fUnitLine := TStringList.Create;
  fUnitLine.OwnsObjects := true;
  ActLine := TStringList.Create;
  slFile := THashedStringList.Create;
end;


procedure TTextFileH.init(fFileName: string);
var
  i: integer;
begin
  fFirstLine.clear;
  fUnitLine.Clear;
  ActLine.Clear;
  slFile.Clear;
  FName := ffilename;
  fn_line := 0;
  actnr := 0;
  FName := ffilename;

  if FileExists(FName) then begin
    slFile.LoadFromFile(FName);
    if slFile.Count > 2 then begin

    FirstLine.CommaText := slFile[0];
    UnitLine.CommaText := slFile[1];
    if UnitLIne.Count < FirstLine.Count then
      for I := UnitLine.Count to FirstLine.Count do
        UnitLine.Append('[]');
     for i := 0 to firstLine.count - 1 do
      firstLine.objects[i] := TVar.create(firstline.strings[i],
        UnitLIne.strings[i], 0.0, '');
    fn_Line := slFile.Count - 2;
    end;
  end;
end;


procedure TTextfileH.GoTop;
begin
  actnr := 1;
end;

function TTextfileH.containsName(name: string): boolean;
begin
  result := (FirstLine.IndexOf(uppercase(Name)) >= 0);
end;

function TTextfileH.GetFirstLine: string;
begin
  result := slFile[2];
end;

function TTextfileH.GetLastLine: string;
begin
  actnr := 0;
  result := slfile[slFile.count - 1];
end;

function TTextfileH.hasMoreLines(): Boolean;
begin
  result := actnr < slFile.Count - 1;
end;

procedure TTextfileH.NextLine;
var
  ActVar: TVar;
  i: Integer;
begin
  if hasMoreLines() then begin
    Inc(actnr);
    actLine.CommaText := slFile[actnr];
    for i := 0 to actline.count - 1 do begin
      ActVar := TVar(Firstline.Objects[i]);
      ActVar.v := StrToFloatDef(actline[i], 0);
    end;
  end;
end;

procedure TTextfileH.FastNextLine;
begin
  if hasMoreLines() then begin
    Inc(actnr);
    actLine.CommaText := slFile[actnr];
  end;
end;

function TTextfileH.indexOf(Name: string): Integer;
begin
  result := Firstline.indexOf(Name);
end;

function TTextFileH.getValue(Name: string): real;
var
  index: integer;
begin
  index := FirstLine.IndexOf(uppercase(Name));
  if (Index >= 0) and (index < ActLine.count) then begin
    if ActLine[index] = '.' then
      result := NaN
    else
      result := StrToFloatDef(ActLine[index], NaN);
  end else begin
    result := NaN;
  end;
end;

function TTextFileH.getIndexValue(Index: integer): real;
begin
  if (index < actline.Count) then begin
    if (ActLine[index] = '.') then
      result := NaN
    else
      result := StrToFloatDef(ActLine[index], NaN);
  end else begin
    result := NaN;
{$IFNDEF NONVISUAL}
    showmessage(self.FName + ' ' + 'Not found in File');
{$ENDIF}
  end;
end;

procedure TTextFileH.LocateFor(Name: string; Value: real);
var
  actValue: real;
  success: boolean;
begin
  success := true;
  actnr := 1;
  while hasMoreLines() do begin
    NextLine;
    actValue := Getvalue(name);
    if (actValue >= Value) then begin
      success := true;
      break;
    end;
  end;

  if not success then
{$IFNDEF NONVISUAL}
     ShowMessage('Error in Locating Column ' + Name + ' in File ' + self.FName)
{$ELSE}
    writeln('Error in Locating Column ' + Name + ' in File ' + self.FName)
 {$ENDIF}


end;



procedure TTextFileH.SetFilename (fn:TMyFileName);

begin
  fFileName :=  fn;
end;

function TTextFileH.GetFilename:TMyFilename;
begin
  GetFilename := fFileName;
end;

// Destructor - frees up memory used by the class object

procedure TTextFileH.BeforeDestruction;

var
 i : integer;
begin
  FreeAndNil(slFile);
  FreeAndNil(fFirstLine);
  FreeAndNil(fUnitLine);
  FreeAndNil(ActLine);
  // Call the parent class destructor
  inherited;
end;

end.

