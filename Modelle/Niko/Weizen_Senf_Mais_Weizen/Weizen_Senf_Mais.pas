unit Weizen_Senf_Mais;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, UlayeredSoil, USoilWaterMod, URootedSoil, USoilNitrogen,
  USoilNitrogenUp, UFertilization, UMinMod2Pool, Concentration_Niko,
  UAbstractPlant, UPenMonteith, UMod, UGrowthCurvePlant, UGrowthCurvePlantRoots,
  ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs, Chart,
  Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, UMultiGrowthCurvePlant,
  UMultiGrowthCurvePlantRoots;

type
  TFormMod2 = class(TFormMod)
    Mais: TGrowthCurvePlantRoots;
    Mod1: TMod;
    PenMonteith1: TPenMonteith;
    Concentration1: TConcentration;
    MinMod2Pool1: TMinMod2Pool;
    Fertilization1: TFertilization;
    SoilNitrogenUp1: TSoilNitrogenUp;
    Weizen2: TMultiGrowthCurvePlantRoots;
    Weizen1: TMultiGrowthCurvePlantRoots;
    Senf: TMultiGrowthCurvePlantRoots;
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
