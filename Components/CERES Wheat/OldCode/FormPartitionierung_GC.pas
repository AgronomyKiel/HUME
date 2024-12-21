unit FormPartitionierung_GC;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart,
  StdCtrls, Buttons, Grids, AdvGrid, ToolWin, USubPartitioningVegNew,
  Development, UMod, UAbstractPlant, UGrowthCurvePlant, Daylength,
  USubLeafAreaGrowthSimple, UPenMonteith, UlayeredSoil, USoilWaterMod,
  URootedSoil, UTillerdevelopmentSimple, UGrowthCurvePlantRoots,
  UTillerdevelopment;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Development1: TDevelopment;
    SubPartitioningVegNew1: TSubPartitioningVegNew;
    Daylength1: TDaylength;
    SoilWaterModelR1: TSoilWaterModelR;
    PenMonteith1: TPenMonteith;
    GrowthCurvePlant1: TGrowthCurvePlantRoots;
    SubLeafAreaGrowthSimple1: TSubLeafAreaGrowthSimple;
    TillerdevelopmentSimple1: TTillerdevelopmentSimple;
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
