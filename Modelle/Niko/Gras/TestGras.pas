unit TestGras;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, UMod, UAbstractPlant,
  UGrowthCurvePlant, UGrowthCurvePlantRoots, UlayeredSoil, USoilWaterMod,
  URootedSoil, UPenMonteith, BaseGrid, grass_growth_quality_ff;

type

  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    SoilWaterModelR1: TSoilWaterModelR;
    PenMonteith1: TPenMonteith;
    Grass_growth_quality_dauer1: TGrass_growth_quality_dauer;
        
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

