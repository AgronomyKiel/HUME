unit FormCERES_V2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, USimpleRootModDM_2,
  UGrowthCurve, UlayeredSoil, USoilWaterMod, URootedSoil, UPenMonteith,
  UPlantN, UTillerdevelopment, USubLeafAreaGrowth, USubPartitioning,
  USubDryMatter, Development, UMod, Daylength, UAbstractPlant;

type
  TFormMod1 = class(TFormMod)
    Mod1: TMod;
    Daylength: TDaylength;
    Development: TDevelopment;
    subdrymatter: Tsubdrymatter;
    subpartitioning: Tsubpartitioning;
    subleafareagrowth: Tsubleafareagrowth;
    Tillerdevelopment: TTillerdevelopment;
    PlantN: TPlantN;
    PenMonteith: TPenMonteith;
    SoilWaterModelR1: TSoilWaterModelR;
    PlantHeight: TGrowthCurve;
    SimpleRootModDM: TSimpleRootModDM_2;
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
