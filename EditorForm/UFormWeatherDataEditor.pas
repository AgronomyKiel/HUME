unit UFormWeatherDataEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, UMod, ComCtrls, Db, DBTables, checklst, Grids, DBGrids, AdvGrid,
  Buttons, ExtCtrls;

type
  TF_WeatherDataEditor = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Query1: TQuery;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    ComboBox_AliasNames: TComboBox;
    Label2: TLabel;
    ComboBox_TableNames: TComboBox;
    Label5: TLabel;
    GroupBox2: TGroupBox;
    EditAliasDriverName: TEdit;
    GroupBox3: TGroupBox;
    SrcList: TListBox;
    DstList: TListBox;
    Panel2: TPanel;
    BitBtn_close: TBitBtn;
    IncludeBtn: TSpeedButton;
    IncAllBtn: TSpeedButton;
    ExcludeBtn: TSpeedButton;
    ExAllBtn: TSpeedButton;
    procedure FormShow(Sender: TObject);
    procedure ComboBox_AliasNamesChange(Sender: TObject);
    procedure ComboBox_TableNamesChange(Sender: TObject);

    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetItem(List: TListBox; Index: Integer);
    function GetFirstSelection(List: TCustomListBox): Integer;
    procedure SetButtons;
    procedure IncludeBtnClick(Sender: TObject);
    procedure ExcludeBtnClick(Sender: TObject);
    procedure IncAllBtnClick(Sender: TObject);
    procedure ExAllBtnClick(Sender: TObject);
    procedure BitBtn_closeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  save_status:boolean;
  end;

var
  F_WeatherDataEditor: TF_WeatherDataEditor;

implementation

{$R *.DFM}



procedure TF_WeatherDataEditor.FormShow(Sender: TObject);
begin
Session.GetAliasNames(ComboBox_AliasNames.Items);
if not (ComboBox_AliasNames.Text ='') then
   begin
        Session.GetTableNames(ComboBox_AliasNames.Text,'*.*',true,false,Self.ComboBox_TableNames.Items);
        EditAliasDriverName.Text:=Session.GetAliasDriverName(ComboBox_AliasNames.Text);
   end;
end;

procedure TF_WeatherDataEditor.ComboBox_AliasNamesChange(Sender: TObject);
begin
if ComboBox_AliasNames.Text =''
    then
    Query1.Close
else
    begin
    Query1.Close;
    Session.GetTableNames(ComboBox_AliasNames.Text,'*.*',true,false,Self.ComboBox_TableNames.Items);
    Query1.DatabaseName:=ComboBox_AliasNames.Text;
    ComboBox_TableNames.Text:=ComboBox_TableNames.Items[0];
    ComboBox_TableNamesChange(Self);
    EditAliasDriverName.Text:=Session.GetAliasDriverName(ComboBox_AliasNames.Text);
    end;
end;

procedure TF_WeatherDataEditor.ComboBox_TableNamesChange(Sender: TObject);
begin
  SrcList.Clear;
  DstList.Clear;   
  Query1.Close;
  Query1.SQL.Clear;
  Query1.SQL.Add('select * from '+ComboBox_TableNames.Text);
  Query1.Active:=true;
  Query1.GetFieldNames(SrcList.Items);
end;



procedure TF_WeatherDataEditor.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then
    begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;

procedure TF_WeatherDataEditor.SetButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcList.Items.Count = 0;
  DstEmpty := DstList.Items.Count = 0;
  IncludeBtn.Enabled := not SrcEmpty;
  IncAllBtn.Enabled := not SrcEmpty;
  ExcludeBtn.Enabled := not DstEmpty;
  ExAllBtn.Enabled := not DstEmpty;
end;

function TF_WeatherDataEditor.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TF_WeatherDataEditor.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do
  begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then Index := 0
    else if Index > MaxIndex then Index := MaxIndex;
  //  Selected[Index] := True;   Gibt Fehlermeldung 'Maximumüberschreitung'
  end;
  SetButtons;
end;


procedure TF_WeatherDataEditor.IncludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcList);
  MoveSelected(SrcList, DstList.Items);
  SetItem(SrcList, Index);
end;

procedure TF_WeatherDataEditor.ExcludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstList);
  MoveSelected(DstList, SrcList.Items);
  SetItem(DstList, Index);
end;

procedure TF_WeatherDataEditor.IncAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcList.Items.Count - 1 do
    DstList.Items.AddObject(SrcList.Items[I],
      SrcList.Items.Objects[I]);
  SrcList.Items.Clear;          
  SetItem(SrcList, 0);
end;

procedure TF_WeatherDataEditor.ExAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstList.Items.Count - 1 do
    SrcList.Items.AddObject(DstList.Items[I], DstList.Items.Objects[I]);
  DstList.Items.Clear;
  SetItem(DstList, 0);
end;




procedure TF_WeatherDataEditor.BitBtn_closeClick(Sender: TObject);
begin
close;
end;

procedure TF_WeatherDataEditor.FormCreate(Sender: TObject);
const
screenheightdev = 768;
screenwidthdev  = 1024;
var
x,y             :integer;
begin
scaled :=True;
x := Screen.Width;
y := Screen.Height;
if (y <> screenheightdev) or
   (y <> screenwidthdev) then
   begin
   height:= (ClientHeight * y div screenheightdev) + Height - ClientHeight;
   Width := (ClientWidth * x div screenwidthdev) + Height - ClientHeight;
   ScaleBy(x, screenwidthdev);
   end;
Save_Status:=false;
end;

end.
