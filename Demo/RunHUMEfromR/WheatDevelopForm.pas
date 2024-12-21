unit WheatDevelopForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFORMMOD, ImgList, ExtCtrls, Menus, ModLink, StdCtrls, TeEngine,
  TeeProcs, Chart, ToolWin, ComCtrls, Grids, BaseGrid, AdvGrid, Buttons,
  Development, UMod, Daylength, VclTee.TeeGDIPlus, System.ImageList;

type
  TFormMod2 = class(TFormMod)
    Mod1: TMod;
    Daylength1: TDaylength;
    Development1: TDevelopment;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.dfm}

end.
