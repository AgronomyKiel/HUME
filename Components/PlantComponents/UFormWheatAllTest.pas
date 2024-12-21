unit UFormWheatAllTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, UMod, UAbstractPlant, UGrowthCurvePlant,
  UGrowthCurvePlantRoots, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs,
  TeEngine, Chart, StdCtrls, Buttons, Grids, AdvGrid, ToolWin,
  USubDryMatterSimple, Development, Daylength,
  USubPartitioningVegNew, UTillerdevelopmentSimple,
  USubPartitioningSimpleLAI, USubLeafAreaGrowthSimple, UPenMonteith,
  USimpleRootModDM, UlayeredSoil, USoilWaterMod, URootedSoil;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    SubPartitioningSimple1: TSubPartitioningVegNew;
    SoilWaterModel: TSoilWaterModelR;
    PenMonteith1: TPenMonteith;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.DFM}

end.
