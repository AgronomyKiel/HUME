unit HUME_Demo3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UFORMMOD, VclTee.TeeGDIPlus, ModLink,
  System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, Vcl.ToolWin, Vcl.ComCtrls,
  Vcl.Grids, BaseGrid, AdvGrid, Vcl.Buttons, UMod, ULogGrowthDemo;

type
  TFormMod_Demo = class(TFormMod)
    Mod1: TMod;
    LogGrowth1: TLogGrowth;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod_Demo: TFormMod_Demo;

implementation

{$R *.dfm}

end.
