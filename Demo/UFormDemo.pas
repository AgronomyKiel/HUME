unit UFormDemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs,
  Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, UMod,
  SubmodLogist_pub, ImgList;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    LogistGrowth1: TLogistGrowth;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod1: TFormMod1;

implementation

{$R *.dfm}



end.
