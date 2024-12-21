unit TestForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, UMod, UAbstractPlant,
  UGrowthCurvePlant, UGrowthCurvePlantRoots, UlayeredSoil, USoilWaterMod,
  URootedSoil, USoilNitrogen, USoilNitrogenUp, UPenMonteith,
  USoilMineralisation, UTillage;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    GrowthCurvePlant1: TGrowthCurvePlantRoots;
    GrowthCurvePlant2: TGrowthCurvePlantRoots;
    PenMonteith1: TPenMonteith;
    SoilNitrogenUp1: TSoilNitrogenUp;
    SoilMin1: TSoilMin;
    Tillage1: TTillage;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod1: TFormMod1;

implementation

{$R *.DFM}

end.
