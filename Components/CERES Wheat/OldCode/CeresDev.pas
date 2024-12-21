unit CeresDev;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, Daylength, UMod, Development, ModLink, ExtCtrls, Menus,
  StdCtrls, ComCtrls, TeeProcs, TeEngine, Chart, Buttons, Grids, AdvGrid,
  ToolWin;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Development1: TDevelopment;
    Daylength1: TDaylength;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.DFM}

end.
