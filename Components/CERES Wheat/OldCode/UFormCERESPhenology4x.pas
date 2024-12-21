unit UFormCERESPhenology4x;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, Daylength, UMod, Usubphenology_ceres_wheat_v_4x, ModLink,
  ExtCtrls, Menus, ComCtrls, TeeProcs, TeEngine, Chart, StdCtrls, Buttons,
  Grids, AdvGrid, ToolWin;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Development1: Tsubphenology_ceres_wheat_v_4x;
    Daylength1: TDaylength;
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
