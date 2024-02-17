unit UFormModelEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.StdCtrls, vcl.ComCtrls, vcl.Buttons, vcl.ExtCtrls, IniFiles, vcl.FileCtrl;

type
  TModelEdit = class(TForm)
    SpeedButtonDown: TSpeedButton;
    PageControl_ModelSettings: TPageControl;
    TabSheet_Modeltime: TTabSheet;
    TabSheet_Modelpath: TTabSheet;
    PageControl_ModelPath: TPageControl;
    TabSheet_Inputpath: TTabSheet;
    TabSheet_Outputpath: TTabSheet;
    TabSheet_Parameterfile: TTabSheet;
    TabSheet_regressionfile: TTabSheet;
    DriveComboBox_Inputpath: TDriveComboBox;
    DirectoryListBox_Inputpath: TDirectoryListBox;
    DriveComboBox_Outputpath: TDriveComboBox;
    DirectoryListBox_Outputpath: TDirectoryListBox;
    DriveComboBox_Parameterfile: TDriveComboBox;
    DirectoryListBox_Parameterfile: TDirectoryListBox;
    FileListBox_Parameterfile: TFileListBox;
    FilterComboBox_Parameterfile: TFilterComboBox;
    DriveComboBox_Regressionfile: TDriveComboBox;
    DirectoryListBox_regressionfile: TDirectoryListBox;
    FileListBox_Regressionfile: TFileListBox;
    FilterComboBox_Regressionfile: TFilterComboBox;
    TabSheet_Globalsettings: TTabSheet;
    Panel1: TPanel;
    Label4: TLabel;
    ComboBox_Separator: TComboBox;
    TabSheet_MarquardOptions: TTabSheet;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Edit_MO_DefaultError: TEdit;
    Edit_MO_Divisor: TEdit;
    Edit_MO_IniLambda: TEdit;
    Edit_MP_Inputpath: TEdit;
    Label_Inputpath: TLabel;
    Label15: TLabel;
    Edit_MP_Outputpath: TEdit;
    Label_TModName: TLabel;
    Edit_ModelName: TEdit;
    BitBtn_close: TBitBtn;
    BitBtn_uebernehmen: TBitBtn;
    BitBtn_verwerfen: TBitBtn;
    Label17: TLabel;
    Edit_MP_Controlfilepath: TEdit;
    Label18: TLabel;
    Edit_MP_Regressionfilepath: TEdit;
    PageControl2: TPageControl;
    TabSheet_ModTime: TTabSheet;
    TabSheet_Runtime: TTabSheet;
    Label5: TLabel;
    Edit_MT_Name: TEdit;
    Label6: TLabel;
    Edit_MT_Unit: TEdit;
    Label7: TLabel;
    Edit_MT_Value: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    Edit_MT_Precision: TEdit;
    Edit_MT_Digits: TEdit;
    CheckBox_MT_WriteToFile: TCheckBox;
    Label1: TLabel;
    DateTimePicker_MT_Starttime: TDateTimePicker;
    Label2: TLabel;
    DateTimePicker_MT_Endtime: TDateTimePicker;
    Label3: TLabel;
    Edit_MT_Timestep: TEdit;
    UpDown_Timestep: TUpDown;
    ComboBox_MO_WeightOptions: TComboBox;
    SubModels: TTabSheet;
    ListBoxSubModels: TListBox;
    SpeedButtonUp: TSpeedButton;
    TabSheet1: TTabSheet;
    ListBoxControlFileStrings: TListBox;
    EditNameControlFile: TEdit;
    LabelNameControlFile: TLabel;
    SaveDialogIniFile: TSaveDialog;
    BitBtnSaveTo: TBitBtn;
    LabelStateIniFile: TLabel;
    EditStateInifile: TEdit;
    LabelParInifile: TLabel;
    EditParIniFile: TEdit;
    LabelWeatherFile: TLabel;
    EditWeatherFile: TEdit;
    SpeedButtonEditStateIniFileName: TSpeedButton;
    SpeedButtonEditParInifileName: TSpeedButton;
    SpeedButtonEditWeatherFileName: TSpeedButton;
    DateTimePickerStartHour: TDateTimePicker;
    DateTimePickerEndHour: TDateTimePicker;
    Label14: TLabel;
    Label16: TLabel;
    DateTimePicker1: TDateTimePicker;
    procedure BitBtn_CloseClick(Sender: TObject);
    procedure FilterComboBox_RegressionfileChange(Sender: TObject);
    procedure DirectoryListBox_InputpathChange(Sender: TObject);
    procedure DirectoryListBox_OutputpathChange(Sender: TObject);
    procedure DirectoryListBox_ParameterfileChange(Sender: TObject);
    procedure FileListBox_ParameterfileChange(Sender: TObject);
    procedure DirectoryListBox_regressionfileChange(Sender: TObject);
    procedure FileListBox_RegressionfileChange(Sender: TObject);
    procedure PageControl_ModelPathChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BitBtn_uebernehmenClick(Sender: TObject);
    procedure BitBtn_verwerfenClick(Sender: TObject);
    procedure SpeedButtonDownClick(Sender: TObject);
    procedure SpeedButtonUpClick(Sender: TObject);
    procedure BitBtnSaveToClick(Sender: TObject);
    procedure DateTimePickerStartHourChange(Sender: TObject);
    procedure DateTimePickerEndHourChange(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    TimeInit,
      FileNames,
      StartZeit,
      endZeit,
      TimeStep,
      StateIniFN,
      ParamIniFN,
      WeatherFileFN: string;

    Save_Status: boolean;
  end;

var
  ModelEdit: TModelEdit;

implementation

uses UMod;

{$R *.DFM}

procedure TModelEdit.BitBtn_CloseClick(Sender: TObject);
begin
  close;
end;

procedure TModelEdit.FilterComboBox_RegressionfileChange(
  Sender: TObject);
begin
  FileListBox_Regressionfile.FileType :=
    FilterComboBox_Regressionfile.FileList.FileType;
end;

procedure TModelEdit.DirectoryListBox_InputpathChange(Sender: TObject);
begin
  Edit_MP_Inputpath.text := DirectoryListBox_Inputpath.Directory;
end;

procedure TModelEdit.DirectoryListBox_OutputpathChange(
  Sender: TObject);
begin
  Edit_MP_Outputpath.Text := DirectoryListBox_Outputpath.Directory;
end;

procedure TModelEdit.DirectoryListBox_ParameterfileChange(
  Sender: TObject);
begin
  Edit_MP_Controlfilepath.Text := DirectoryListBox_Parameterfile.Directory;
end;

procedure TModelEdit.FileListBox_ParameterfileChange(Sender: TObject);
begin
  Edit_MP_Controlfilepath.Text := FileListBox_Parameterfile.FileName;
end;

procedure TModelEdit.DirectoryListBox_regressionfileChange(
  Sender: TObject);
begin
  Edit_MP_Regressionfilepath.Text := DirectoryListBox_regressionfile.Directory;
end;

procedure TModelEdit.FileListBox_RegressionfileChange(Sender: TObject);
begin
  Edit_MP_Regressionfilepath.Text := FileListBox_Regressionfile.FileName;
end;

procedure TModelEdit.PageControl_ModelPathChange(Sender: TObject);
begin
  if PageControl_ModelPath.ActivePage = TabSheet_Inputpath then
    DirectoryListBox_Inputpath.Directory := Edit_MP_Inputpath.Text;
  if PageControl_ModelPath.ActivePage = TabSheet_Outputpath then
    DirectoryListBox_Outputpath.Directory := Edit_MP_Outputpath.Text;
  if PageControl_ModelPath.ActivePage = TabSheet_Parameterfile then
    DirectoryListBox_Parameterfile.Directory := Edit_MP_Controlfilepath.Text;
  if PageControl_ModelPath.ActivePage = TabSheet_regressionfile then
    DirectoryListBox_regressionfile.Directory :=
      Edit_MP_Regressionfilepath.Text;

end;

procedure TModelEdit.FormCreate(Sender: TObject);
const
  screenheightdev = 768;
  screenwidthdev = 1024;
var
  x, y: integer;
begin
  Save_Status := false;
  scaled := True;
  x := Screen.Width;
  y := Screen.Height;
  if (y <> screenheightdev) or
    (y <> screenwidthdev) then begin
    height := (ClientHeight * y div screenheightdev) + Height - ClientHeight;
    Width := (ClientWidth * x div screenwidthdev) + Height - ClientHeight;
    ScaleBy(x, screenwidthdev);
  end;
end;

procedure TModelEdit.BitBtn_uebernehmenClick(Sender: TObject);
begin
  Save_Status := true;
end;

procedure TModelEdit.BitBtn_verwerfenClick(Sender: TObject);
begin
  Save_Status := false;
end;

procedure TModelEdit.SpeedButtonUpClick(Sender: TObject);
var
  index: integer;
begin
  Index := self.ListBoxSubModels.Itemindex;
  if index >0 then
    ListBoxSubModels.Items.Exchange(Index, index - 1);
  self.ListBoxSubModels.Itemindex := self.ListBoxSubModels.Itemindex;
end;

procedure TModelEdit.SpeedButtonDownClick(Sender: TObject);
var
  index: integer;
begin
  Index := self.ListBoxSubModels.Itemindex;
  if index < ListBoxSubModels.count then
    ListBoxSubModels.Items.Exchange(Index, index + 1);
  self.ListBoxSubModels.Itemindex := self.ListBoxSubModels.Itemindex;

end;

procedure TModelEdit.BitBtnSaveToClick(Sender: TObject);

var
  Success: boolean;
  Inifile: TIniFile;//TMyIniFile;

begin
  success := SaveDialogInifile.Execute;
  if success then begin
    Inifile := TIniFile.Create(SaveDialogIniFile.FileName);
    with Inifile do begin
      WriteFloat(TimeInit, StartZeit, DateTimePicker_MT_Starttime.Date);
      WriteFloat(TimeInit, EndZeit, DateTimePicker_MT_Endtime.Date);
      WriteFloat(TimeInit, TimeStep, StrToFloat(Edit_MT_TimeStep.Text));

      WriteString(FileNames, StateIniFN, EditStateIniFile.text);
      WriteString(FileNames, ParamIniFN, EditParIniFile.text);
      WriteSTring(FileNames, WeatherFileFN, EditWeatherFile.text);
      UpdateFile;
      Free;
    end;
  end;

end;

procedure TModelEdit.DateTimePickerStartHourChange(Sender: TObject);
begin
  DateTimePicker_MT_Starttime.Time := DateTimePickerStartHour.time;
end;

procedure TModelEdit.DateTimePickerEndHourChange(Sender: TObject);
begin
  DateTimePicker_MT_Endtime.Time := DateTimePickerEndHour.time;
end;

end.

