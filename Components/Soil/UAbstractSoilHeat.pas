unit UAbstractSoilHeat;

interface

uses
  UMod, UState, UlayeredSoil, classes;

type

TAbstractSoilHeat = class (TLayeredSoil)

private

protected


public

  Temp  : TSoilStateArray;  /// State for soil temperature
  procedure Init(var GlobMod:Tmod); override;
  procedure CreateAll; override;
published

end;


implementation

uses
  math,
{$IFNDEF NONVISUAL}
   vcl.dialogs,
{$ENDIF}
  SysUtils;


Procedure TAbstractSoilHeat.Init(var GlobMod:Tmod);
var
  i : integer;

begin
  inherited Init(GlobMod);
    For I := 1 to n_comp+1 do
      Temp[i].v := 8.0;

end;

Procedure TAbstractSoilHeat.CreateAll;

var
  i : integer;

begin
  inherited createAll;

  for I := 0 to n_comp+1 do
          StateCreate('SoilTemp_'+ndx_str(i),'[°C]', 8, true, Temp[i])

end;

end.