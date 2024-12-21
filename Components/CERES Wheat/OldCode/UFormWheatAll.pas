unit UFormWheatAll;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, WheatAll, USimpleRootModDM,
  USubLeafAreaGrowthSimple, UTillerdevelopmentSimple, UAbstractPlant,
  USubPartitioningVegNew, USubDryMatterSimple, Development, Daylength,
  UlayeredSoil, USoilWaterMod, URootedSoil, UMod, UPenMonteith;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    PenMonteith1: TPenMonteith;
    SoilWaterModel: TSoilWaterModelR;
    Daylength1: TDaylength;
    Development1: TDevelopment;
    SubDrymatterSimple1: TsubdrymatterSimple;
    SubPartitioningSimple1: TSubPartitioningVegNew;
    TillerdevelopmentSimple1: TTillerdevelopmentSimple;
    SubLeafAreaGrowthSimple1: TSubLeafAreaGrowthSimple;
    SimpleRootModDM: TSimpleRootModDM;
    WheatAll: TWheatAll;
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
