unit Mais_GPSWeizen_Gras_Gras;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine,
  TeeProcs, Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid,
  UMinMod2Pool, UFertilization, UlayeredSoil, USoilWaterMod, URootedSoil,
  USoilNitrogen, USoilNitrogenUp, UAbstractPlant, UPenMonteith, UMod,
  UMultiGrowthCurvePlant, UMultiGrowthCurvePlantRoots, UGrowthCurvePlant,
  UGrowthCurvePlantRoots, Concentration_Niko;

type
  TFormMod2 = class(TFormMod)
    Mais: TGrowthCurvePlantRoots;
    Gras_Gras: TMultiGrowthCurvePlantRoots;
    PenMonteith1: TPenMonteith;
    SoilNitrogenUp1: TSoilNitrogenUp;
    Fertilization1: TFertilization;
    MinMod2Pool1: TMinMod2Pool;
    Concentration1: TConcentration;
    Mod1: TMod;
    GPS_Weizen: TMultiGrowthCurvePlantRoots;
    Gras: TMultiGrowthCurvePlantRoots;
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
