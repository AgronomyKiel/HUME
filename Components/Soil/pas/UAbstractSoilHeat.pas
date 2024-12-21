unit UAbstractSoilHeat;

interface

uses
  UMod, UState, UlayeredSoil, classes;

type

TAbstractSoilHeat = class (TLayeredSoil)

private

protected


public
  /// State
  Temp  : TSoilStateArray;
  procedure Init(var GlobMod:Tmod); override;
  procedure CreateAll; override;


published


end;



implementation


uses
  math, dialogs, SysUtils;




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

  for I := 0 to n_comp+1 do begin
    if i< 10 then
          StateCreate('SoilTemp__'+IntTostr(i),'[°C]', 8, true, Temp[i])
     else
                  StateCreate('SoilTemp_'+IntTostr(i),'[°C]', 8, true, Temp[i]);
   end;

end;

end.