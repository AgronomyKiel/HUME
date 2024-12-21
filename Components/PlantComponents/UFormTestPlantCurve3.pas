unit UFormTestPlantCurve3;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, UMod, UAbstractPlant,
  UGrowthCurvePlant, UPenMonteith;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    GrowthCurvePlant1: TGrowthCurvePlant;
    GrowthCurvePlant2: TGrowthCurvePlant;
    PenMonteith1: TPenMonteith;
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
