unit GenNew_small;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, Development, UGrowthCurve, UAbstractPlant,
  USubPartitioningVegNew, USubPartitioningGenNew, UMod, USubDataEx,
  ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart, StdCtrls,
  Buttons, Grids, AdvGrid, ToolWin;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    SubDataEX1: TSubDataEX;
    SubPartitioningSimple1: TSubPartitioningGenNew;
    GrowthCurvePlant1: TGrowthCurve;
    GC_GRNN: TGrowthCurve;
    GC_DMStem: TGrowthCurve;
    Development1: TDevelopment;
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
