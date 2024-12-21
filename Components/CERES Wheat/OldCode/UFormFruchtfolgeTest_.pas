unit UFormFruchtfolgeTest_;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, WheatAll, USimpleRootModDM,
  USubLeafAreaGrowthSimple, UTillerdevelopmentSimple, UAbstractPlant,
  USubPartitioningVegNew, USubDryMatterSimple, Development, Daylength,
  UlayeredSoil, USoilWaterMod, URootedSoil, UMod, UPenMonteith,
  grass_growth_quality_ff, maize_growth_quality;

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
    Grass_growth_quality_dauer1: TGrass_growth_quality_dauer;
    maize_growth_quality1: Tmaize_growth_quality;
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
