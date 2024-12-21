unit Senf_Mais_Weizen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, Concentration_Niko, UlayeredSoil, USoilWaterMod,
  URootedSoil, USoilNitrogen, USoilNitrogenUp, UMinMod2Pool, UFertilization,
  UAbstractPlant, UPenMonteith, UMod, UGrowthCurvePlant, UGrowthCurvePlantRoots,
  ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs, Chart,
  Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, UMultiGrowthCurvePlant,
  UMultiGrowthCurvePlantRoots;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Mais: TGrowthCurvePlantRoots;
    PenMonteith1: TPenMonteith;
    Fertilization1: TFertilization;
    MinMod2Pool1: TMinMod2Pool;
    SoilNitrogenUp1: TSoilNitrogenUp;
    Concentration1: TConcentration;
    Weizen: TMultiGrowthCurvePlantRoots;
    Senf2: TMultiGrowthCurvePlantRoots;
    Senf1: TMultiGrowthCurvePlantRoots;
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
