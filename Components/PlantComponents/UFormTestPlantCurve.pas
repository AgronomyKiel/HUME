unit UFormTestPlantCurve;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, UMod, UAbstractPlant,
  UGrowthCurvePlant, USoilMineralisation, UPenMonteith, UAbstractSoilHeat,
  USimpleSoilHeat, UlayeredSoil, USoilWaterMod, URootedSoil, USoilNitrogen,
  USoilNitrogenUp, USimpleRootModel;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    GrowthCurvePlant1: TGrowthCurvePlant;
    SoilMin1: TSoilMin;
    SoilNitrogenUp1: TSoilNitrogenUp;
    SimpleSoilHeat1: TSimpleSoilHeat;
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
