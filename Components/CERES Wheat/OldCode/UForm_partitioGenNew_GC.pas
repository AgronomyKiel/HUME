unit UForm_partitioGenNew_GC;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, USubLeafAreaGrowthSimple, UPenMonteith, UAbstractPlant,
  UlayeredSoil, USoilWaterMod, URootedSoil, Daylength,
  UTillerdevelopmentSimple, USubDryMatterSimple, Development,
  USubPartitioningVegNew, UMod, USimpleRootModDM,
  ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart, StdCtrls,
  Buttons, Grids, AdvGrid, ToolWin, UPlantN, UGrowthCurvePlant,
  USubPartitioningGenNew, UGrowthCurve, USubDataEx, UFileInputIntPol;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    SimpleRootModDM: TSimpleRootModDM;
    Development1: TDevelopment;
    subdrymatterSimple1: TsubdrymatterSimple;
    TillerdevelopmentSimple1: TTillerdevelopmentSimple;
    Daylength1: TDaylength;
    SoilWaterModel: TSoilWaterModelR;
    PenMonteith1: TPenMonteith;
    SubLeafAreaGrowthSimple1: TSubLeafAreaGrowthSimple;
    PlantN1: TPlantN;
    GrowthCurvePlant1: TGrowthCurvePlant;
    GC_GRNN: TGrowthCurve;
    GC_DMStem: TGrowthCurve;
    SubPartitioningSimple1: TSubPartitioningGenNew;
    IPol_ShootN: TFileInputIntPol;
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
