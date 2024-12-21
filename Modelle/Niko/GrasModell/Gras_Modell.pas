unit Gras_Modell;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, UMinMod2Pool, UPenMonteith, UFertilization,
  Concentration_Niko, UAbstractPlant, UlayeredSoil, USoilWaterMod, URootedSoil,
  USoilNitrogen, USoilNitrogenUp, UMod, UGrowthCurvePlant,
  UMultiGrowthCurvePlant, UMultiGrowthCurvePlantRoots, ImgList, ModLink,
  ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs, Chart, Buttons, ToolWin,
  ComCtrls, Grids, BaseGrid, AdvGrid;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    MultiGrowthCurvePlantRoots1: TMultiGrowthCurvePlantRoots;
    MultiGrowthCurvePlantRoots2: TMultiGrowthCurvePlantRoots;
    SoilNitrogenUp1: TSoilNitrogenUp;
    Concentration1: TConcentration;
    Fertilization1: TFertilization;
    PenMonteith1: TPenMonteith;
    MinMod2Pool1: TMinMod2Pool;
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
