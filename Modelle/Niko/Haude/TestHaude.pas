unit TestHaude;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, UMod, UAbstractPlant,
  UGrowthCurvePlant, UGrowthCurvePlantRoots, UlayeredSoil, USoilWaterMod,
  URootedSoil, UPenMonteith, BaseGrid, Concentration_Niko, UHaude;

type

  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    GrowthCurvePlantRoots1: TGrowthCurvePlantRoots;
    SoilWaterModelR1: TSoilWaterModelR;
    GrowthCurvePlantRoots2: TGrowthCurvePlantRoots;
    Concentration1: TConcentration;
    GrowthCurvePlantRoots3: TGrowthCurvePlantRoots;
    Haude1: THaude;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.DFM}

end.

