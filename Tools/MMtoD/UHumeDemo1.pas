unit UHumeDemo1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, UMod, SubmodLogist, ModLink, ExtCtrls, Menus, TeeProcs,
  TeEngine, Chart, Buttons, Grids, AdvGrid, StdCtrls, ComCtrls, ToolWin;

type
  TFormMod2 = class(TFormMod)
    Model: Tmod;
    LogistGrowth1: TLogistGrowth;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.DFM}


end.
