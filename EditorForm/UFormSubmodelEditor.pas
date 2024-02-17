
unit UFormSubmodelEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.StdCtrls, vcl.Buttons, vcl.ExtCtrls, vcl.ComCtrls, AdvGrid, vcl.Grids, AsgMemo, BaseGrid;

type
  TF_SubmodelEditor = class(TForm)
    PageControl1: TPageControl;
    TabSheet_Par: TTabSheet;
    TabSheet_Var: TTabSheet;
    TabSheet_State: TTabSheet;
    Panel1: TPanel;
    ADV_Par: TAdvStringGrid;
    ADV_Var: TAdvStringGrid;
    ADV_State: TAdvStringGrid;
    TabSheet_ExternV: TTabSheet;
    ADV_ExternV: TAdvStringGrid;
    BitBtnAccept: TBitBtn;
    BitBtnClose: TBitBtn;
    BitBtnUndo: TBitBtn;
    TabSheetFileName: TTabSheet;
    EditDataFileName: TEdit;
    LabelDataFileName: TLabel;
    SpeedButtonEditDataFileName: TSpeedButton;
    LabelOutputFile: TLabel;
    EditOutPutFileName: TEdit;
    SpeedButtonEditOutputFileName: TSpeedButton;
    SaveDialog1: TSaveDialog;
    procedure BitBtnAcceptClick(Sender: TObject);
    procedure BitBtnCloseClick(Sender: TObject);
    procedure ADV_ParGetEditorType(Sender: TObject; aCol, aRow: Integer;
      var aEditor: TEditorType);
    procedure ADV_VarGetEditorType(Sender: TObject; aCol, aRow: Integer;
      var aEditor: TEditorType);
    procedure ADV_StateGetEditorType(Sender: TObject; aCol, aRow: Integer;
      var aEditor: TEditorType);
    procedure ADV_ExternVGetEditorType(Sender: TObject; aCol,
      aRow: Integer; var aEditor: TEditorType);
    procedure FormCreate(Sender: TObject);
    procedure BitBtnUndoClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  Save_Status:boolean;
  end;

var
  F_SubmodelEditor: TF_SubmodelEditor;

implementation

{$R *.DFM}


procedure TF_SubmodelEditor.BitBtnAcceptClick(Sender: TObject);
begin
Save_Status:=True;
end;

procedure TF_SubmodelEditor.BitBtnCloseClick(Sender: TObject);
begin
close;
end;

procedure TF_SubmodelEditor.ADV_ParGetEditorType(Sender: TObject; aCol,
  aRow: Integer; var aEditor: TEditorType);
begin
case acol of
0:aEditor:=edNormal;
1:aEditor:=edNormal;
2:aEditor:=edFloat;
3:aEditor:=edFloat;
4:aEditor:=edFloat;
5:aEditor:=edFloat;
6:aEditor:=edCheckBox;
7:aEditor:=edCheckBox;
8:aEditor:=edCheckBox;
end;
end;

procedure TF_SubmodelEditor.ADV_VarGetEditorType(Sender: TObject; aCol,
  aRow: Integer; var aEditor: TEditorType);
begin
case acol of
0:aEditor:=edNormal;
1:aEditor:=edNormal;
2:aEditor:=edFloat;
3:aEditor:=edFloat;
4:aEditor:=edFloat;
5:aEditor:=edFloat;
6:aEditor:=edCheckBox;
7:aEditor:=edCheckBox;
end;
end;

procedure TF_SubmodelEditor.ADV_StateGetEditorType(Sender: TObject; aCol,
  aRow: Integer; var aEditor: TEditorType);
begin
case acol of
0:aEditor:=edNormal;
1:aEditor:=edNormal;
2:aEditor:=edFloat;
3:aEditor:=edFloat;
4:aEditor:=edFloat;
5:aEditor:=edFloat;
6:aEditor:=edCheckBox;
7:aEditor:=edCheckBox;
8:aEditor:=edCheckBox;
end;
end;

procedure TF_SubmodelEditor.ADV_ExternVGetEditorType(Sender: TObject; aCol,
  aRow: Integer; var aEditor: TEditorType);
begin
case acol of
0:aEditor:=edNormal;
1:aEditor:=edNormal;
2:aEditor:=edFloat;
3:aEditor:=edFloat;
4:aEditor:=edFloat;
5:aEditor:=edFloat;
6:aEditor:=edCheckBox;
7:aEditor:=edCheckBox;
8:aEditor:=edCheckBox;
end;
end;

procedure TF_SubmodelEditor.FormCreate(Sender: TObject);
const
screenheightdev = 600;
screenwidthdev  = 800;
//var
//x,y             :integer;
begin
{scaled :=true;
x := Screen.Width;
y := Screen.Height;
if (y <> screenheightdev) or
   (y <> screenwidthdev) then
   begin
   height:= (ClientHeight * y div screenheightdev) + Height - ClientHeight;
   Width := (ClientWidth * x div screenwidthdev) + Height - ClientHeight;
   ScaleBy(x, screenwidthdev);
   end;
Save_Status:=false;}
inherited
end;


procedure TF_SubmodelEditor.BitBtnUndoClick(Sender: TObject);
begin
Save_Status:=false;
end;

end.
