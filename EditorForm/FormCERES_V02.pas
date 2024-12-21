unit FormCERES_V02;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, USimpleRootModDM_2,
  UGrowthCurve, UlayeredSoil, USoilWaterMod, URootedSoil, UPenMonteith,
  UPlantN, UTillerdevelopment, USubLeafAreaGrowth, USubPartitioning,
  USubDryMatter, Development, UMod, Daylength, USimplePlant,
  USimplePlantWW_R;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    PenMonteith: TPenMonteith;
    SoilWaterModelR1: TSoilWaterModelR;
    PlantHeight: TGrowthCurve;
    SimpleRootModDM: TSimpleRootModDM_2;
    GrowthCurveLAI: TGrowthCurve;
    SimplePlantWW_R1: TSimplePlantWW_R;
    GrowthCurveDM: TGrowthCurve;
    GrowthCurvePlantN: TGrowthCurve;
    Daylength: TDaylength;
    Development: TDevelopment;
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
