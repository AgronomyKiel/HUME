unit HUME_Demo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, UMod, SubmodLogist,
  BaseGrid, SubmodLogist_pub, ImgList;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    LogistGrowth1: TLogistGrowth;
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
