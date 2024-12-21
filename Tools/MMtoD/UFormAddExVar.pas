unit UFormAddExVar;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAddExVarDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Bevel1: TBevel;
    Label1: TLabel;
    EditName: TEdit;
    LabelConvFaktor: TLabel;
    EditConvFactor: TEdit;
    Label3: TLabel;
    EditUnits: TEdit;
    Label4: TLabel;
    EditComment: TEdit;
    procedure CancelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    FSaved : boolean;
    { Private declarations }
  public
    { Public declarations }
    property saved : boolean read fsaved write fsaved;
  end;

var
  AddExVarDlg: TAddExVarDlg;

implementation

{$R *.DFM}

procedure TAddExVarDlg.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TAddExVarDlg.OKBtnClick(Sender: TObject);
begin
   tag := 1;
   close;
end;


end.
