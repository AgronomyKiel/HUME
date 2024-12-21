unit Mais;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs,
  Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, UPenMonteith,
  UAbstractPlant, UMultiGrowthCurvePlant, UMultiGrowthCurvePlantRoots, UMod,
  UlayeredSoil, USoilWaterMod, URootedSoil, USoilNitrogen, USoilNitrogenUp,
  UMinMod2Pool, UDueng, Concentration_Niko, UGrowthCurvePlant, UDueng_Par,
  UFertilization, ImgList;

type
  TFormMod1 = class(TFormMod)
    MinMod2Pool1: TMinMod2Pool;
    Mod1: TMod;
    MultiGrowthCurvePlantRoots1: TMultiGrowthCurvePlantRoots;
    MultiGrowthCurvePlantRoots2: TMultiGrowthCurvePlantRoots;
    PenMonteith1: TPenMonteith;
    SoilNitrogenUp1: TSoilNitrogenUp;
    Concentration1: TConcentration;
    MinMod2Pool2: TMinMod2Pool;
    Dueng_Par1: TDueng_Par;
    Fertilization1: TFertilization;

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
