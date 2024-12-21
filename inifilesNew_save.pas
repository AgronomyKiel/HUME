
{*******************************************************}
{                                                       }
{       Delphi Visual Component Library                 }
{                                                       }
{       Copyright (c) 1995,97 Borland International     }
{                                                       }
{*******************************************************}

unit inifilesNew_save;

{$R-}

interface                                                

uses
{$IFNDEF NONVISUAL}
Windows,
{$ENDIF}
//Sysutils,
Classes,
UModUtils;

type
  real = double;
  TMyIniFile = class(TPersistent)
  private
    FFileName: TMyFileName;

  public
    constructor Create;
    Procedure Init(const FileName: string);
    function ReadString(const Section, Ident, Default: string): string;
    procedure WriteString(const Section, Ident, Value: String);
    function ReadInteger(const Section, Ident: string;
      Default: Longint): Longint;
    procedure WriteInteger(const Section, Ident: string; Value: Longint);
    function ReadBool(const Section, Ident: string;
      Default: Boolean): Boolean;

    function ReadFloat(const Section, Ident: string;
    Default: real; var Error: boolean): Real;
    procedure WriteFloat(const Section, Ident: string; Value: REal);

    procedure WriteBool(const Section, Ident: string; Value: Boolean);
    procedure ReadSection(const Section: string; Strings: TStrings);
    procedure ReadSections(Strings: TStrings);
    procedure ReadSectionValues(const Section: string; Strings: TStrings);
    procedure EraseSection(const Section: string);
    procedure DeleteKey(const Section, Ident: String);
  published  
    property FileName: TMyFileName read FFileName write FFileName;
  end;

implementation

uses
{$IFNDEF NONVISUAL}
  Vcl.Consts,
{$ENDIF}
  System.SysUtils;


function StrToFloatDef (ValueStr : string; DefaultValue : real; var Error:boolean):real;


begin
 error := false;
 while Pos(',', ValueStr) > 0 do
    ValueStr[Pos(',', ValueStr)] := '.';
 If ValueStr <> '' then begin
 Try

  StrToFloatDef := StrToFloat(ValueStr);

  except on EConvertError do begin
   Error := true;
   StrToFloatDef := DefaultValue;
   end;
 end;
 end else begin
   StrToFloatDef := DefaultValue;
   error := true;
 end;  

end;

constructor TMyIniFile.Create;
begin
  inherited create;
end;

procedure TMyIniFile.Init(const FileName: string);
begin
  FFileName := FileName;
end;


function TMyIniFile.ReadString(const Section, Ident, Default: string): string;
var
  Buffer: array[0..1023] of Char;
begin
  SetString(Result, Buffer, GetPrivateProfileString(PChar(Section),
    PChar(Ident), PChar(Default), Buffer, SizeOf(Buffer), PChar(string(FFileName))));
end;

procedure TMyIniFile.WriteString(const Section, Ident, Value: string);
begin
  if not WritePrivateProfileString(PChar(Section), PChar(Ident),
    PChar(Value), PChar(string(FFileName))) then
    raise Exception.CreateFmt(SIniFileWriteError, [FileName]);
end;

function TMyIniFile.ReadInteger(const Section, Ident: string;
  Default: Longint): Longint;
var
  IntStr: string;
begin
  IntStr := ReadString(Section, Ident, '');
  if (Length(IntStr) > 2) and (IntStr[1] = '0') and
    ((IntStr[2] = 'X') or (IntStr[2] = 'x')) then
    IntStr := '$' + Copy(IntStr, 3, Maxint);
  Result := StrToIntDef(IntStr, Default);
end;

procedure TMyIniFile.WriteInteger(const Section, Ident: string; Value: Longint);
begin
  WriteString(Section, Ident, IntToStr(Value));
end;

function TMyIniFile.ReadFloat(const Section, Ident: string;
  Default: real; var error: boolean): Real;
var
  IntStr: string;
begin
  IntStr := ReadString(Section, Ident, '');
  {if (Length(IntStr) > 2) and (IntStr[1] = '0') and
    ((IntStr[2] = 'X') or (IntStr[2] = 'x')) then
    IntStr := '$' + Copy(IntStr, 3, Maxint);}
  Result := StrToFloatDef(IntStr, Default, error);
end;

procedure TMyIniFile.WriteFloat(const Section, Ident: string; Value: Real);
begin
  WriteString(Section, Ident, FloatToStrF(Value, ffGeneral, 8, 2));
end;


function TMyIniFile.ReadBool(const Section, Ident: string;
  Default: Boolean): Boolean;
begin
  Result := ReadInteger(Section, Ident, Ord(Default)) <> 0;
end;

procedure TMyIniFile.WriteBool(const Section, Ident: string; Value: Boolean);
const
  Values: array[Boolean] of string = ('0', '1');
begin
  WriteString(Section, Ident, Values[Value]);
end;

procedure TMyIniFile.ReadSections(Strings: TStrings);
const
  BufSize = 8192;
var
  Buffer, P: PChar;
begin
  GetMem(Buffer, BufSize);
  try
    Strings.BeginUpdate;
    try
      Strings.Clear;
      if GetPrivateProfileString(nil, nil, nil, Buffer, BufSize,
        PChar(string(FFileName))) <> 0 then
      begin
        P := Buffer;
        while P^ <> #0 do
        begin
          Strings.Add(P);
          Inc(P, StrLen(P) + 1);
        end;
      end;
    finally
      Strings.EndUpdate;
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;

procedure TMyIniFile.ReadSection(const Section: string; Strings: TStrings);
const
  BufSize = 8192;
var
  Buffer, P: PChar;
begin
  GetMem(Buffer, BufSize);
  try
    Strings.BeginUpdate;
    try
      Strings.Clear;
      if GetPrivateProfileString(PChar(Section), nil, nil, Buffer, BufSize,
        PChar(string(FFileName))) <> 0 then
      begin
        P := Buffer;
        while P^ <> #0 do
        begin
          Strings.Add(P);
          Inc(P, StrLen(P) + 1);
        end;
      end;
    finally
      Strings.EndUpdate;
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;

procedure TMyIniFile.ReadSectionValues(const Section: string; Strings: TStrings);
var
  KeyList: TStringList;
  I: Integer;
begin
  KeyList := TStringList.Create;
  try
    ReadSection(Section, KeyList);
    Strings.BeginUpdate;
    try
      for I := 0 to KeyList.Count - 1 do
        Strings.Values[KeyList[I]] := ReadString(Section, KeyList[I], '');
    finally
      Strings.EndUpdate;
    end;
  finally
    KeyList.Free;
  end;
end;

procedure TMyIniFile.EraseSection(const Section: string);
begin
  if not WritePrivateProfileString(PChar(Section), nil, nil,
    PChar(string(FFileName))) then
    raise Exception.CreateFmt(SIniFileWriteError, [FileName]);
end;

procedure TMyIniFile.DeleteKey(const Section, Ident: String);
begin
  WritePrivateProfileString(PChar(string(Section)), PChar(Ident), nil,
     PChar(string(FFileName)));
end;


end.
