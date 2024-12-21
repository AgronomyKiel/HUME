unit UForm_GCTestRoot;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, UMod, UAbstractPlant, UGrowthCurvePlant,
  UGrowthCurvePlantRoots, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs,
  TeEngine, Chart, StdCtrls, Buttons, Grids, AdvGrid, ToolWin,
  USubDryMatterSimple, Development, Daylength, USubPartitioningSimple;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    GrowthCurvePlant1: TGrowthCurvePlant;
    Daylength1: TDaylength;
    Development1: TDevelopment;
    subdrymatterSimple1: TsubdrymatterSimple;
    SubPartitioningSimple1: TSubPartitioningSimple;
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
