unit FormCERES_V04All;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, USimpleRootModDM_2,
  UGrowthCurve, UlayeredSoil, USoilWaterMod, URootedSoil, UPenMonteith,
  UPlantN, UTillerdevelopment, 
  USubDryMatter, Development, UMod, Daylength, USimplePlant,
  USubLeafAreaGrowthNew, USubPartitioningNew, UAbstractPlant;

type
  TFormMod1 = class(TFormMod)
    ModelControl: TMod;
    Evapotranspiration: TPenMonteith;
    SoilWater: TSoilWaterModelR;
    RootGrowth: TSimpleRootModDM_2;
    Daylength: TDaylength;
    Development: TDevelopment;
    DrymatterProduction: Tsubdrymatter;
    PlantNitrogen: TPlantN;
    LeafAreaGrowth: TSubLeafAreaGrowthNew;
    Tillerdevelopment: TTillerdevelopment;
    DM_Partitioning: TSubPartitioningNew;
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
