unit UFormStringGrid;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Menus, Buttons, ToolWin, ComCtrls, AdvGrid, BaseGrid;

type
  TFormStringGrid = class(TForm)
    StringGrid1: TAdvStringGrid;
    OpenDialog1: TOpenDialog;
    SpeedButtonInsCol: TSpeedButton;
    SpeedButtonInsRow: TSpeedButton;
    SpeedButton1: TSpeedButton;
  private
    { Private-Deklarationen }
  F        : text;
  public
  FileName : string;
    { Public-Deklarationen }
  procedure ShowFile (FFileName : string);
  end;

var
  FormStringGrid: TFormStringGrid;

implementation


{$R *.DFM}

procedure TFormStringGrid.ShowFile (FFileName : string);

var
  OneLine : TStringList;
  line    : string;
  i    : integer;
begin
  StringGrid1.fixedrows := 2;
  OneLine := TStringList.create;
  FileName := FFileName;
  assignFile(f, FileName);
  reset(f);
  i := 0;
  While not eof(f) do begin
    readln(f, Line);
    OneLIne.Commatext := line;
    If StringGrid1.RowCount < i+1 then
      StringGrid1.RowCount := StringGrid1.RowCount+1;
    if StringGrid1.ColCount < OneLIne.Count then
       StringGrid1.colCount := OneLIne.Count;
    StringGrid1.Rows[i].commatext := OneLIne.commatext;
    inc(i);
  end;
  StringGrid1.ColCount := oneLIne.Count;
  closefile(f);
  OneLine.Free;
  show;
end;

end.
