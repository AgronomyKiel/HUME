unit UFormCalcTimes;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormCalcTimes = class(TForm)
    PanelFileName: TPanel;
    LabelFileName: TLabel;
    EditFileName: TEdit;
    MemoCalcTimes: TMemo;
    PanelButtons: TPanel;
    ButtonCopy: TButton;
    ButtonClose: TButton;
    procedure ButtonCopyClick(Sender: TObject);
  public
    /// <summary>Loads and displays a calculation-times output file.</summary>
    procedure LoadResults(const FileName: string);
  end;

implementation

uses
  Vcl.Clipbrd;

{$R *.dfm}

procedure TFormCalcTimes.ButtonCopyClick(Sender: TObject);
begin
  Clipboard.AsText := MemoCalcTimes.Text;
end;

procedure TFormCalcTimes.LoadResults(const FileName: string);
begin
  EditFileName.Text := FileName;
  MemoCalcTimes.Lines.LoadFromFile(FileName);
  MemoCalcTimes.SelStart := 0;
end;

end.