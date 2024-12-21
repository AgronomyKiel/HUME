unit UFormEditIniFile;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls, OkCancl2, Dialogs, Grids, AdvGrid;

type
  TOKHelpRightDlg = class(TOKRightDlg)
    HelpBtn: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    Label2: TLabel;
    Edit2: TEdit;
    SpeedButton2: TSpeedButton;
    OpenDialog1: TOpenDialog;
    LabelTimeStepDesc: TLabel;
    EditTimeStep: TEdit;
    EditStartTime: TEdit;
    LabelStartTime: TLabel;
    LabelEndTime: TLabel;
    EditEndTime: TEdit;
    AdvStringGrid1: TAdvStringGrid;
    Label3: TLabel;
    procedure HelpBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OKHelpRightDlg: TOKHelpRightDlg;

implementation

{$R *.DFM}

procedure TOKHelpRightDlg.HelpBtnClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

end.

