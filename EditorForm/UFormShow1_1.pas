unit UFormShow1_1;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.Buttons, vcl.Grids, AdvGrid, vcl.ExtCtrls,  vcl.ToolWin,
  vcl.ComCtrls, vcl.StdCtrls, BaseGrid, RichEdit, VclTee.TeeGDIPlus, VCLTee.TeEngine,
  VCLTee.TeeProcs, VCLTee.Chart, Vcl.ExtDlgs;

type
  TFormShow1_1 = class(TForm)
    ToolBar1: TToolBar;
    PrintButton: TSpeedButton;
    CheckBox1: TCheckBox;
    PageControlStat: TPageControl;
    TabSheet1_1Plot: TTabSheet;
    Chart1_1: TChart;
    TabSheetDataTab: TTabSheet;
    AdvStringGrid1_1: TAdvStringGrid;
    TabSheetResPlot: TTabSheet;
    ChartResPlot: TChart;
    AdvStringGridLegend: TAdvStringGrid;
    TabSheetStatistics: TTabSheet;
    MemoStatistics: TMemo;
    Edit_1_1_FileName: TEdit;
    SpeedButtonSave_1_1_as_png: TSpeedButton;
    SavePictureDialog1: TSavePictureDialog;
    procedure FormShow(Sender: TObject);
    procedure PrintButtonClick(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure SpeedButtonSave_1_1_as_pngClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormShow1_1: TFormShow1_1;


implementation

{$R *.DFM}
uses
  System.IOUtils;

procedure TFormShow1_1.FormShow(Sender: TObject);
begin
  self.CheckBox1.checked := true;
end;


procedure TFormShow1_1.PrintButtonClick(Sender: TObject);
begin
  self.Chart1_1.Print;
end;

procedure TFormShow1_1.SpeedButtonSave_1_1_as_pngClick(Sender: TObject);
var
  fn, path : string;
begin
  with self.SavePictureDialog1 do
  begin
    title := 'save chart';
    DefaultExt := '';
    Filter := 'WMF-files (*.wmf)|*.wmf';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then begin
      fn := FileName;
      path := TPath.GetDirectoryName(fn);
      fn := TPath.GetFileNameWithoutExtension(fn);
      fn := path+'\'+fn+'.wmf';
      Chart1_1.SaveToMetafile(fn);
   end;
  end;
end;

procedure TFormShow1_1.CheckBox1Click(Sender: TObject);

var
  i : integer;
begin
  For  i := 1 to self.AdvStringGrid1_1.RowCount-1 do
    if self.CheckBox1.checked then
      AdvStringGrid1_1.Cells[0, i] := DateTimeToStr(strtofloat(AdvStringGrid1_1.Cells[0, i]))
    else
      AdvStringGrid1_1.Cells[0, i] := floattostr(StrToDateTime(AdvStringGrid1_1.Cells[0, i]));


end;

end.
