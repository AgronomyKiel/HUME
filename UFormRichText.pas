unit UFormRichText;

interface

uses Windows, SysUtils, Classes, vcl.Graphics, vcl.Forms, vcl.Controls, vcl.StdCtrls,
  vcl.Buttons, vcl.ExtCtrls, vcl.ComCtrls, vcl.ToolWin, vcl.Dialogs;

type
  TViewFileRichtext = class(TForm)
    RichEdit1: TRichEdit;
    ToolBar1: TToolBar;
    SpeedButtonPrint: TSpeedButton;
    SpeedButtonSave: TSpeedButton;
    SaveDialog1: TSaveDialog;
    PrintDialog1: TPrintDialog;
    procedure FormShow(Sender: TObject);
    procedure SpeedButtonPrintClick(Sender: TObject);
    procedure SpeedButtonSaveClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FileName : string;
  end;

var
  ViewFileRichtext: TViewFileRichtext;

implementation

{$R *.DFM}

procedure TViewFileRichtext.FormShow(Sender: TObject);

begin
  RichEdit1.Lines.Clear;
  RichEdit1.Lines.LoadFromFile(Filename);
  Caption := Filename;
  RichEdit1.Update;

end;


procedure TViewFileRichtext.SpeedButtonPrintClick(Sender: TObject);
var
  success : Boolean;

begin
   success := PrintDialog1.Execute;
   if success then
     Richedit1.Print(FileName);
end;



procedure TViewFileRichtext.SpeedButtonSaveClick(Sender: TObject);
var
  success : Boolean;

begin
  SaveDialog1.FileName := fileName;
   success := SaveDialog1.Execute;
   if success then begin
      FileName := SaveDialog1.FileName;
      Caption  := FileName;
      RichEdit1.Lines.SaveToFile(Filename);
   end;   

end;

end.
