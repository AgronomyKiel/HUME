unit UModUtils;

interface

uses
  {dialogs,} classes, sysutils;


type
  real = double;
  TPath = string; // ansonsten unnötige casting Probleme [100];
  TMyFileName = string; // [120]; ansonsten viele potentielle casting Probleme

(******************************************************************)
function StripExtension(Filename: string): string;
(******************************************************************
ENTRY: Filename ... filename to be stripped from extension

EXIT:  A string is returned which has no extension (that is any part
       following a point).
*******************************************************************)

function del_blank(InStr: string): string;

function trapez_f(x, x0, x1, x2, x3, fmin, fmax: real): real;



implementation

function trapez_f(x, x0, x1, x2, x3, fmin, fmax: real): real;

{ bildet folgende Funktion ab :

  y |
    |
fmax|             ***********
    |           * |         | *
    |         *   |         |   *
    |       *     |         |     *
    |     *       |         |       *
fmin ___*_________|_________|_________*_______
        x0       x1        x2         x3

  }

begin
  if (x >= x1) and (x <= x2) then begin
    Trapez_f := fmax;
    exit;
  end;
  if (x <= x0) or (x >= x3) then begin
    Trapez_f := fmin;
    exit;
  end;
  if (x > x2) then begin
    Trapez_f := fmax - (x - x2) * (fmax - fmin) / (x3 - x2);
    exit;
  end;

  if (x > x0) and (x < x1) then begin
    Trapez_f := fmin + (x - x0) * (fmax - fmin) / (x1 - x0);
    exit;
  end;
  trapez_f := 0.0;
end;

function del_blank(InStr: string): string;
var
  Ch  : Char;
  i,n : Integer;
  P   : PChar;
  Len : Integer;
begin
  Len := Length(InStr);
  SetLength(Result, Len);
  P := Pointer(Result);
  n := 0;
  for i := 1 to Len do
  begin
    Ch := InStr[i];
    if Ch <> ' ' then
    begin
      P[n] := Ch;
      Inc(n);
    end;
  end;
  SetLength(Result, n);
end;


(******************************************************************)

function StripExtension(Filename: string): string;
(******************************************************************
ENTRY: Filename ... filename to be stripped from extension

EXIT:  A string is returned which has no extension (that is any part
       following a point).
*******************************************************************)
var
  i: integer;
begin
  i := pos('.', FileName);
  if i <> 0 then delete(FileName, i, Length(FileName) - i + 1);
  result := AnsiUpperCase(FileName);
end;

end.



