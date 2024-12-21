unit UGrasGrowth;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, UPenMonteith, UAbstractPlant, UlayeredSoil, USoilWaterMod,
  URootedSoil, USoilNitrogen, USoilNitrogenUp, UMod, grass_growth_quality,
  ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs, Chart,
  Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, UGrowthCurvePlant,
  UMultiGrowthCurvePlant, UMultiGrowthCurvePlantRoots;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Grass_growth_quality1: TGrass_growth_quality;
    SoilNitrogenUp1: TSoilNitrogenUp;
    PenMonteith1: TPenMonteith;
    Grass_growth_quality2: TGrass_growth_quality;
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
