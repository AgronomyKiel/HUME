unit Langfrist_Wetter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, UAbstractPlant,
  UGrowthCurvePlant, UMultiGrowthCurvePlant, UMultiGrowthCurvePlantRoots, UMod,
  UPenMonteith, ImgList, ModLink, ExtCtrls, Menus, StdCtrls, TeEngine, TeeProcs,
  Chart, Buttons, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, URootedSoil,
  USoilNitrogen, USoilNitrogenUp, UlayeredSoil, USoilWaterMod;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    MultiGrowthCurvePlantRoots1: TMultiGrowthCurvePlantRoots;
    SoilNitrogenUp1: TSoilNitrogenUp;
    PenMonteith1: TPenMonteith;
  
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
