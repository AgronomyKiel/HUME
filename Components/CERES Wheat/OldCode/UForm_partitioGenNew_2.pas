unit UForm_partitioGenNew_2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, USubLeafAreaGrowthSimple, UPenMonteith, UAbstractPlant,
  UlayeredSoil, USoilWaterMod, URootedSoil, Daylength,
  UTillerdevelopmentSimple, USubDryMatterSimple, Development,
  USubPartitioningVegNew, USubPartitioningGenNew, UMod, USimpleRootModDM,
  ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart, StdCtrls,
  Buttons, Grids, AdvGrid, ToolWin;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    SimpleRootModDM1: TSimpleRootModDM;
    SubPartitioningGenNew1: TSubPartitioningGenNew;
    Development1: TDevelopment;
    subdrymatterSimple1: TsubdrymatterSimple;
    TillerdevelopmentSimple1: TTillerdevelopmentSimple;
    Daylength1: TDaylength;
    SoilWaterModelR1: TSoilWaterModelR;
    PenMonteith1: TPenMonteith;
    SubLeafAreaGrowthSimple1: TSubLeafAreaGrowthSimple;
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
