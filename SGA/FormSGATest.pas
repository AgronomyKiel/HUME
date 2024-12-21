unit FormSGATest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, UMod, UGrowthCurve;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    GrowthCurve1: TGrowthCurve;
    GrowthCurve2: TGrowthCurve;
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
