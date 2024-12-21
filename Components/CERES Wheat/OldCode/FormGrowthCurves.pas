unit FormGrowthCurves;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, USimpleRootModDM_2,
  UGrowthCurve, UlayeredSoil, USoilWaterMod, URootedSoil, UPenMonteith,
  UPlantN, UTillerdevelopment, USubLeafAreaGrowth, USubPartitioning,
  USubDryMatter, Development, UMod, Daylength, USimplePlant,
  USimplePlantWW_R, UDryMatProdComp, ULUETotDry, UFileInput, UAbstractPlant;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    GC_Height: TGrowthCurve;
    Root: TSimpleRootModDM_2;
    Partitioning: TSimplePlantWW_R;
    GC_DM: TGrowthCurve;
    Daylength: TDaylength;
    Development: TDevelopment;
    GC_LAI: TGrowthCurve;
    LayeredSoil1: TLayeredSoil;
    GC_ShootN: TGrowthCurve;
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
