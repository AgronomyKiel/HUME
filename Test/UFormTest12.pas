unit UFormTest12;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UFORMMOD, VclTee.TeeGDIPlus, UMod,
  SubmodLogist_pub, ModLink, System.ImageList, Vcl.ImgList, Vcl.ExtCtrls,
  Vcl.Menus, Vcl.StdCtrls, VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart,
  Vcl.ToolWin, Vcl.ComCtrls, Vcl.Grids, BaseGrid, AdvGrid, Vcl.Buttons;

type
  TFormMod12 = class(TFormMod)
    Mod1: TMod;
    LogistGrowth1: TLogistGrowth;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod12: TFormMod12;

implementation

{$R *.dfm}


end.
