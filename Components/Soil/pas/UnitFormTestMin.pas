unit UnitFormTestMin;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, UMod, UPenMonteith,
  UAbstractPlant, UGrowthCurvePlant, UGrowthCurvePlantRoots, UlayeredSoil,
  USoilWaterMod, URootedSoil, USoilNitrogen, USoilNitrogenUp,
  USoilMineralisation;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    SoilMin1: TSoilMin;
    SoilNitrogenUp1: TSoilNitrogenUp;
    GrowthCurvePlantRoots1: TGrowthCurvePlantRoots;
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
