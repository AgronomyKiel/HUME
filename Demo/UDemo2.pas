unit UDemo2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, StdCtrls, TeEngine,
  TeeProcs, Chart, Buttons, ToolWin, Grids, BaseGrid, AdvGrid, UMod,
  UGrowthCurve, ImgList;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    GrowthCurve1: TGrowthCurve;
    GrowthCurve2: TGrowthCurve;
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
