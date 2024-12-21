unit Weizen_Gras_Mais_Weizen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine,
  TeeProcs, Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid,
  UMinMod2Pool, UlayeredSoil, USoilWaterMod, URootedSoil, USoilNitrogen,
  USoilNitrogenUp, UFertilization, UAbstractPlant, UPenMonteith,
  UMultiGrowthCurvePlant, UMultiGrowthCurvePlantRoots, UMod, UGrowthCurvePlant,
  UGrowthCurvePlantRoots, Concentration_Niko;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Gras_Gras: TMultiGrowthCurvePlantRoots;
    Mais: TGrowthCurvePlantRoots;
    PenMonteith1: TPenMonteith;
    Fertilization1: TFertilization;
    SoilNitrogenUp1: TSoilNitrogenUp;
    MinMod2Pool1: TMinMod2Pool;
    Concentration1: TConcentration;
    Koernerweizen: TMultiGrowthCurvePlantRoots;
    Koernerweizen2: TMultiGrowthCurvePlantRoots;
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
