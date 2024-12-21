unit CeresDevWang;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, Development, UMod, Daylength, ModLink, ExtCtrls, Menus,
  StdCtrls, ComCtrls, TeeProcs, TeEngine, Chart, Buttons, Grids, AdvGrid,
  ToolWin, UDevWangEngel;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    Daylength1: TDaylength;
    Development1: TDevWangEngel;
    
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod1: TFormMod1;

implementation

{$R *.DFM}

end.
