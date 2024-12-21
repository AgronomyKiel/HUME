unit FormOSRDevelopment;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine,
  TeeProcs, Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, UMod,
  Daylength, DevelopmentOSR;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    DevelopmentOSR1: TDevelopmentOSR;
    Daylength1: TDaylength;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.dfm}

end.
