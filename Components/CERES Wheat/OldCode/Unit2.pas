unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, UMod, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine,
  Chart, StdCtrls, Buttons, Grids, AdvGrid, ToolWin, UAbstractPlant,
  USubPartitioningVegNew, USubPartitioningGenNew, USubDataEx,
  UFileInputIntPol, UGrowthCurve;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    GrowthCurvePlant1: TGrowthCurve;
    GC_GRNN: TGrowthCurve;
    GC_DMSTEM: TGrowthCurve;
    IPOLSHOOTN: TFileInputIntPol;
    SubDataEX1: TSubDataEX;
    SubPartitioningSimple1: TSubPartitioningGenNew;
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
