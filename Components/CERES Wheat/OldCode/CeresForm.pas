unit CeresForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, ModLink, ExtCtrls, Menus, StdCtrls, ComCtrls, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, ToolWin, Daylength, UMod,
  Development, USubDryMatter, UTillerdevelopment, USubLeafAreaGrowth,
  USubPartitioning, UPlantN;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Daylength1: TDaylength;
    Development1: TDevelopment;
    Tillerdevelopment1: TTillerdevelopment;
    PlantN1: TPlantN;
    subpartitioning1: Tsubpartitioning;
    subleafareagrowth1: Tsubleafareagrowth;
    subdrymatter1: Tsubdrymatter;
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
