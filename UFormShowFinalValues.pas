unit UFormShowFinalValues;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.Grids, AdvGrid, vcl.ToolWin, vcl.ComCtrls, BaseGrid, vcl.StdCtrls;

type
  TFormShowFinalValues = class(TForm)
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    AdvStringGrid1: TAdvStringGrid;
    EditFinalValuesFileName: TEdit;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormShowFinalValues: TFormShowFinalValues;

implementation

{$R *.DFM}



end.
