unit Mixture;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine,
  TeeProcs, Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid,
  UAbstractPlant, UPenMonteith, UMod, UGrowthCurvePlant, UMultiGrowthCurvePlant,
  UMultiGrowthCurvePlantRoots, UlayeredSoil, USoilWaterMod, URootedSoil,
  USoilNitrogen, USoilNitrogenUp;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Mixture: TMultiGrowthCurvePlantRoots;
    PenMonteith1: TPenMonteith;
    SoilNitrogenUp1: TSoilNitrogenUp;
    Mixture_R_ST: TMultiGrowthCurvePlantRoots;
    Mixture_R_MT: TMultiGrowthCurvePlantRoots;
    Mixture_R_Auger: TMultiGrowthCurvePlantRoots;
    Mixture_Nmin: TMultiGrowthCurvePlantRoots;
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
