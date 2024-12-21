unit test_controlfilesetting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UFORMMOD, VclTee.TeeGDIPlus, ModLink,
  System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, Vcl.ToolWin, Vcl.ComCtrls,
  Vcl.Grids, BaseGrid, AdvGrid, Vcl.Buttons, UMod, ULogGrowthDemo;

type
  TFormMod19 = class(TFormMod)
    Mod1: TMod;
    LogGrowth1: TLogGrowth;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod19: TFormMod19;

implementation

{$R *.dfm}

end.
