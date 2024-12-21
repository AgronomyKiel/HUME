unit Converter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ClipBrd;

type
  TForm1 = class(TForm)
    DateTimePicker1: TDateTimePicker;
    Edit1: TEdit;
    procedure Edit1Change(Sender: TObject);
    procedure DateTimePicker1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);  

  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }

  protected
    procedure WMDrawClipboard(var Message : TMessage);  message WM_DRAWCLIPBOARD;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Edit1.Text := FloatToStr(Trunc(DateTimePicker1.Date));
  SetClipboardViewer(Handle);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  DateTimePicker1.Date := StrToInt(Edit1.Text);
end;

procedure TForm1.DateTimePicker1Change(Sender: TObject);
begin
  Edit1.Text := FloatToStr(Trunc(DateTimePicker1.Date));
end;

procedure TForm1.WMDrawClipboard(var Message : TMessage);
var
  n: Integer;
begin
  try
    //if Clipboard.HasFormat(CF_TEXT) then
    //  if (TryStrToInt(Clipboard.AsText,n)) then Edit1.Text := IntToStr(n);
  finally
  end;  
end;

end.
