unit UFormSoilHeatTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, UMod, UlayeredSoil,
  USimpleSoilHeat, UPenMonteith, USoilWaterMod, URootedSoil_zr,
  UAbstractSoilHeat;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    SoilWaterModel_zR1: TSoilWaterModel_zR;
    PenMonteith1: TPenMonteith;
    SimpleSoilHeat1: TSimpleSoilHeat;
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
