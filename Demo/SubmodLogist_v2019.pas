unit SubmodLogist_v2019;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, UMod, ULogGrowthDemo, ImgList, ExtCtrls, Menus, ModLink,
  StdCtrls, TeEngine, TeeProcs, Chart, ToolWin, ComCtrls, Grids, BaseGrid,
  AdvGrid, Buttons, VclTee.TeeGDIPlus, System.ImageList;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    LogGrowth1: TLogGrowth;
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
