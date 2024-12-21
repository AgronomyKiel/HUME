unit UFormWheatAllTest2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, Daylength, UAbstractPlant,
  WheatAll, UlayeredSoil, USoilWaterMod, URootedSoil, UMod, UPenMonteith,
  Development, USubLeafAreaGrowthSimple, USubDryMatterSimple,
  USubPartitioningVegNew, USimpleRootModDM;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    PenMonteith: TPenMonteith;
    SoilWaterModel: TSoilWaterModelR;
    WheatAll1: TWheatAll;
    Daylength1: TDaylength;
    Development1: TDevelopment;
    subdrymatterSimple1: TsubdrymatterSimple;
    SubLeafAreaGrowthSimple1: TSubLeafAreaGrowthSimple;
    SimpleRootModDM1: TSimpleRootModDM;
    SubPartitioningVegNew1: TSubPartitioningVegNew;
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
