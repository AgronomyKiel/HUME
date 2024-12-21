unit UForm_partitioGenW;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, UMod, UAbstractPlant, UGrowthCurvePlant,
  UGrowthCurvePlantRoots, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs,
  TeEngine, Chart, StdCtrls, Buttons, Grids, AdvGrid, ToolWin,
  USubDryMatterSimple, Development, Daylength, USubPartitioningSimple,
  USubPartitioningVegNew, UTillerdevelopmentSimple,
  USubPartitioningSimpleLAI, USubLeafAreaGrowthSimple, UPenMonteith,
  USimpleRootModDM, UlayeredSoil, USoilWaterMod, URootedSoil, USubPartitioningGen;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Daylength1: TDaylength;
    Development1: TDevelopment;
    subdrymatterSimple1: TsubdrymatterSimple;
    TillerdevelopmentSimple1: TTillerdevelopmentSimple;
    SubLeafAreaGrowthSimple1: TSubLeafAreaGrowthSimple;
    SoilWaterModel: TSoilWaterModelR;
    SimpleRootModDM: TSimpleRootModDM;
    PenMonteith1: TPenMonteith;
    SubPartitioningSimple1: TSubPartitioningGen;
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
