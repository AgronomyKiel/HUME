unit UFormMod;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.ExtCtrls, vcl.Menus, vcl.StdCtrls, UFormGraph, vcl.ComCtrls, UMod, vcl.Grids, //vcl.DirOutln,
  vcl.Buttons, vcl.ToolWin, IniFiles, BaseGrid, AdvGrid, VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,
  UTextFileH, UHumeShow, UFormOpt, UFormSelPar, ModLink, UFormChiSquareAnalysis,
  VCLTee.TECanvas, System.UITypes, VclTee.TeeGDIPlus, System.ImageList,
  Vcl.ImgList, Vcl.WinXCtrls; // , JvCsvData;

const
  MaxSeries = 1000;

type
  TLineSeriesArr = array [0 .. MaxSeries - 1] of TFastLineSeries;
  TCustomSeriesArr = array [0 .. MaxSeries - 1] of TCustomSeries;

  TFormMod = class(TForm)
    MainMenu1: TMainMenu;
    Menu_File: TMenuItem;
    Menu_Run: TMenuItem;
    Menu_Exit: TMenuItem;
    Menu_Edit: TMenuItem;
    Menu_Parameter: TMenuItem;
    MenuInitParams: TMenuItem;
    MenuView: TMenuItem;
    MenuViewState: TMenuItem;
    StatusBarMain: TStatusBar;
    Optimize1: TMenuItem;
    Graph1: TMenuItem;
    Timer1: TTimer;
    PageControl: TPageControl;
    TabSheetGlobal: TTabSheet;
    TabSheetParameter: TTabSheet;
    TabSheetState: TTabSheet;
    TabSheetData: TTabSheet;
    AdvStringGridParam: TAdvStringGrid;
    AdvStringGridState: TAdvStringGrid;
    AdvStringGridData: TAdvStringGrid;
    TabSheetModelDiagram: TTabSheet;
    TabSheetStat: TTabSheet;
    TabSheetResultTab: TTabSheet;
    AdvStringGridResults: TAdvStringGrid;
    TabSheetGraphResult: TTabSheet;
    ChartSimResults: TChart;
    TabSheetVariables: TTabSheet;
    AdvStringGridVar: TAdvStringGrid;
    ToolBarStateSheet: TToolBar;
    LabelStateFileName: TLabel;
    EditStateFileName: TEdit;
    ToolBarPlotPage: TToolBar;
    ToolBarPageTable: TToolBar;
    ToolBarDataPage: TToolBar;
    LabelDataFileNameDesc: TLabel;
    EditDataFileName: TEdit;
    SpeedButtonInsRow: TSpeedButton;
    ToolBarVarPage: TToolBar;
    ToolBarParSheet: TToolBar;
    LabelparamFileName: TLabel;
    EditParamFileName: TEdit;
    PrintButton: TSpeedButton;
    PrintDialog1: TPrintDialog;
    ButtonSaveState: TBitBtn;
    ButtonSaveParam: TBitBtn;
    OpenDialog1: TOpenDialog;
    Help1: TMenuItem;
    Info1: TMenuItem;
    SensitivityAnalysis: TMenuItem;
    ComboBoxTimeAxisOption: TComboBox;
    LabelTimeSeriesOption: TLabel;
    SelectMeasDataCheckBox: TCheckBox;
    GroupBoxStarttime: TGroupBox;
    SaveDialog1: TSaveDialog;
    SpeedChangeParamIniFile: TSpeedButton;
    BitBtnSaveParamTo: TBitBtn;
    GroupBoxWeatherDates: TGroupBox;
    LabelWeatherDataFirstEntry: TLabel;
    FWDLabel: TLabel;
    LabelWeatherDataLatEntry: TLabel;
    LWDLabel: TLabel;
    BitBtnSaveStateTo: TBitBtn;
    SpeedButtonOpenDataFile: TSpeedButton;
    LabelOutputdatafile: TLabel;
    EditOutputdatafilename: TEdit;
    SpeedButtonOpenOutputFile: TSpeedButton;
    TabSheetOptions: TTabSheet;
    ToolBarOptions: TToolBar;
    ButtonSaveOptions: TBitBtn;
    BitBtnSaveOptionsTo: TBitBtn;
    LabelOptionsFilename: TLabel;
    EditOptionsFileName: TEdit;
    SpeedButtonChangeOptionsFilename: TSpeedButton;
    AdvStringGridOptions: TAdvStringGrid;
    ChisquareAnalysis: TMenuItem;
    N1: TMenuItem;
    CheckBoxDateFormat: TCheckBox;
    CheckBoxDataDateFormat: TCheckBox;
    SpeedButtonFinalvalues: TSpeedButton;
    TabSheetExternalValues: TTabSheet;
    AdvStringGridExternV: TAdvStringGrid;
    ViewVariables1: TMenuItem;
    EditExternals1: TMenuItem;
    EditOptions1: TMenuItem;
    Statistics1: TMenuItem;
    AdvStringGridStat: TAdvStringGrid;
    ToolBarStatistics: TToolBar;
    PanelMainFormHeader: TPanel;
    ComboBoxIniFile: TComboBox;
    ComboBoxSubMod: TComboBox;
    LabelActIniFileDesc: TLabel;
    LabelSubModelCombobox: TLabel;
    SpeedButtonRun: TSpeedButton;
    btnSaveasPNG: TSpeedButton;
    ToolBarExternals: TToolBar;
    btnAdvStatToClipBoardButton: TSpeedButton;
    btnSaveDataChanges: TSpeedButton;
    il1: TImageList;
    SpeedButtonIncFontSize: TSpeedButton;
    TabSheetDocumentation: TTabSheet;
    ToolBarDocu: TToolBar;
    SpeedButtonCreateDocu: TSpeedButton;
    MemoModelDocu: TMemo;
    EditDokuFilename: TEdit;
    AdvStringGridModelSummary: TAdvStringGrid;
    SpeedButtonMergeData: TSpeedButton;
    btnCheckButton1: TSpeedButton;
    Lmod: TModLink;
 //   CheckBoxContOutput: TCheckBox;
    GroupBoxIniFileEdits: TGroupBox;
    GroupBoxControlFileName: TGroupBox;
    EditControlFile: TEdit;
    btnButtonChangeControlFile: TSpeedButton;
    GroupBoxEndtime: TGroupBox;
    EditEndTime: TEdit;
    EndTimePicker: TDateTimePicker;
    EditStartTime: TEdit;
    DateTimePickerStart: TDateTimePicker;
    GroupBoxTimestep: TGroupBox;
    EditTimeStep: TEdit;
    GroupBoxStateIniFile: TGroupBox;
    EditStateIniFileName: TEdit;
    SpeedButtonChangeStateIniFile: TSpeedButton;
    GroupBoxPamIniFileName: TGroupBox;
    EditParamIniFileName: TEdit;
    SpeedButtonChangeParamIniFile: TSpeedButton;
    GroupBoxWeatherFile: TGroupBox;
    EditWeatherfile: TEdit;
    SpeedButtonChangeWeatherFile: TSpeedButton;
    GroupBoxOutput: TGroupBox;
    GroupBoxOutputDirectory: TGroupBox;
    SpeedButtonOutputDirectory: TSpeedButton;
    EditOutputDirectory: TEdit;
    GroupBoxContinousOutput: TGroupBox;
    ComboBoxContOutput: TComboBox;
    GroupBoxSaveIniFileChanges: TGroupBox;
    btnButtonSaveIntegrChanges1: TSpeedButton;
    btnButtonSaveToNewIniFile1: TSpeedButton;
    BitBtnMergeWeatherFN: TBitBtn;
    ToggleSwitchVarContOutput: TToggleSwitch;
    ToggleSwitchStateContOutput: TToggleSwitch;
    ToggleSwitchExternContOutput: TToggleSwitch;
    GroupBox1: TGroupBox;
    SpeedButtonNoContOutput: TSpeedButton;
    SpeedButtonAllContOutput: TSpeedButton;

    procedure RunModel; virtual;
    procedure Menu_RunClick(Sender: TObject); virtual;
    procedure Menu_ExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ViewTabelleClick(Sender: TObject); virtual;
    procedure ViewGraphClick(Sender: TObject);
    procedure OptimizeClick(Sender: TObject);
    procedure MenuEditStateClick(Sender: TObject);
    procedure MenuInitParamsClick(Sender: TObject);
    procedure ComboBoxInifileChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ComboBoxSubModChange(Sender: TObject);
    procedure SpeedButtonRunClick(Sender: TObject);
    // procedure ButtonReInitClick(Sender: TObject);
    procedure ButtonSaveDataChangesClick(Sender: TObject);
    procedure ButtonSaveStateClick(Sender: TObject);
    procedure ButtonSaveParamsClick(Sender: TObject);
    procedure SpeedButtonInsRowClick(Sender: TObject);
    procedure ButtonSaveIntegrChangesClick(Sender: TObject);
    procedure update_StringGrid(fn: string);
    procedure ShowDataFile(FFileName: string);
    procedure UpdatePageResultTab;
    procedure UpdatePageGraphResult;
    procedure TabSheetResultTabEnter(Sender: TObject);
    // procedure ButtonSaveVarClick(Sender: TObject);
    procedure SaveVar();
    procedure SaveExterns;
    procedure PrintButtonClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure Info1Click(Sender: TObject);
    procedure btnButtonChangeControlFileClick(Sender: TObject);
    procedure SensitivityAnalysisClick(Sender: TObject);
    procedure ComboBoxTimeAxisOptionChange(Sender: TObject);
    procedure AdvStringGridStateCheckBoxClick(Sender: TObject;
      aCol, aRow: Integer; state: Boolean);
    procedure AdvStringGridVarCheckBoxClick(Sender: TObject;
      aCol, aRow: Integer; state: Boolean);
    procedure EditStartTimeChange(Sender: TObject);
    procedure EditEndTimeChange(Sender: TObject);
    procedure StartTimePickerChange(Sender: TObject);
    procedure EndTimePickerChange(Sender: TObject);
    procedure ButtonSaveToNewIniFileClick(Sender: TObject);
    procedure SpeedButtonChangeStateIniFileClick(Sender: TObject);
    procedure SpeedButtonChangeParamIniFileClick(Sender: TObject);
    procedure SpeedButtonChangeWeatherFileClick(Sender: TObject);
    procedure SpeedChangeParamIniFileClick(Sender: TObject);
    procedure BitBtnSaveParamToClick(Sender: TObject);
    procedure SpeedButtonChangeSTageFileNameClick(Sender: TObject);
    procedure BitBtnSaveStateToClick(Sender: TObject);
    procedure TabSheetGraphResultEnter(Sender: TObject);
    procedure SpeedButtonOpenDataFileClick(Sender: TObject);
    procedure EditParamIniFileNameMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure LabelActIniFileDescMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure EditStateIniFileNameMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure EditWeatherfileMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);

    procedure AdvStringOptionsGetEditorType(Sender: TObject;
      aCol, aRow: Integer; var aEditor: TEditorType);
    procedure ButtonSaveOptionsClick(Sender: TObject);
    procedure BitBtnSaveOptionsToClick(Sender: TObject);
    procedure ChisquareAnalysisClick(Sender: TObject);
    procedure GAOptClic(Sender: TObject);
    procedure CheckBoxDateFormatClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure AdvStringGridStatButtonClick(Sender: TObject;
      aCol, aRow: Integer);
    procedure AdvStringGridParamButtonClick(Sender: TObject;
      aCol, aRow: Integer);
    procedure AdvStringGridOptionsAnchorClick(Sender: TObject;
      aRow, aCol: Integer; anchor: string; var AutoHandle: Boolean);
    procedure AdvStringGridStateButtonClick(Sender: TObject;
      aCol, aRow: Integer);
    procedure AdvStringGridOptionsButtonClick(Sender: TObject;
      aCol, aRow: Integer);
    procedure CheckBoxDataDateFormatClick(Sender: TObject);
    procedure SpeedButtonFinalvaluesClick(Sender: TObject);
    // procedure SpeedButtonInitExternVClick(Sender: TObject);
    procedure AdvStringGridVarButtonClick(Sender: TObject; aCol, aRow: Integer);
    procedure AdvStringGridExternVButtonClick(Sender: TObject;
      aCol, aRow: Integer);
    procedure ViewVariables1Click(Sender: TObject);
    procedure EditExternals1Click(Sender: TObject);
    procedure EditOptions1Click(Sender: TObject);
    procedure Statistics1Click(Sender: TObject);
    procedure AdvStringGridExternVCheckBoxClick(Sender: TObject;
      aCol, aRow: Integer; state: Boolean);
    procedure ButtonSaveExVarClick(Sender: TObject);
    procedure updateForm();
    procedure AdvStringGridStateEditCellDone(Sender: TObject;
      aCol, aRow: Integer);
    procedure AdvStringGridOptionsEditCellDone(Sender: TObject;
      aCol, aRow: Integer);
    procedure btnAdvStatToClipBoardButton1Click(Sender: TObject);
    procedure ComboBoxIniFileDropDown(Sender: TObject);
    procedure btnSaveasPNGClick(Sender: TObject);
    procedure changeIni(titlestr, keyname: string;
      EditFileName, EditIniFileName: TEdit);
    function SaveTo(title, keyname: string;
      EditFileName, EditIniFileName: TEdit): Boolean;
    procedure InitAllAndCheckExternalV();
    procedure CheckButtonClick(Sender: TObject);
    procedure btnAdvStatToClipBoardButtonClick(Sender: TObject);
    procedure btnSaveDataChangesClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure AdvStatToClipBoardButtonClick(Sender: TObject);
    procedure SpeedButtonDelRowClick(Sender: TObject);
    procedure SpeedButtonSaveToWMFClick(Sender: TObject);
    procedure SpeedButtonIncFontSizeClick(Sender: TObject);
    procedure SpeedButtonDecFontSizeClick(Sender: TObject);
    procedure SpeedButtonCreateDocuClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TabSheetGraphResultShow(Sender: TObject);
    procedure TabSheetResultTabShow(Sender: TObject);
    procedure TabSheetParameterShow(Sender: TObject);
    procedure TabSheetOptionsShow(Sender: TObject);
    procedure TabSheetExternalValuesShow(Sender: TObject);
    procedure TabSheetDataShow(Sender: TObject);
    procedure TabSheetStateShow(Sender: TObject);
    procedure TabSheetVariablesShow(Sender: TObject);
    procedure BitBtnMergeWeatherFNClick(Sender: TObject);
    procedure SpeedButtonMergeDataClick(Sender: TObject);
    procedure SpeedButtonOutputDirectoryClick(Sender: TObject);
    procedure SpeedButtonNoContOutputClick(Sender: TObject);
//    procedure CheckBoxContOutputClick(Sender: TObject);
    procedure ComboBoxContOutputChange(Sender: TObject);
    procedure SpeedButtonAllContOutputClick(Sender: TObject);
    procedure ToggleSwitchVarContOutputClick(Sender: TObject);
    procedure ToggleSwitchStateContOutputClick(Sender: TObject);
    procedure ToggleSwitchExternContOutputClick(Sender: TObject);
  private
    n_lineSeries, n_PointSeries, nFormGraph: Integer;
    FormGraphArray: array [1 .. 10] of TFormGraph;
    LineSeriesArr: TLineSeriesArr;
    // DataFileSim: TTextFileH;
    // DataFileMeas: TTextFileH;

    img_help, img_savetoall: TBitmap;
    EXE_PATH: string;
    function getLinkedModel(): TMod;
    procedure testSubModIndex(n: Integer);
    procedure updatePropIniFile(strList: TStringList; submodname: string);
//    procedure setPropFromIniFile(strList: TStringList; submodname: string);
    // procedure ConnectionPaint(Sender: TObject);
  public
    ModelWasRunning: Boolean;
    procedure UpdateStringGridParam;
    procedure UpdateStringGridState;
    procedure UpdateStringGridVar;
    procedure UpdateStringGridData;
    procedure UpdatePageIntegration;
    procedure UpdateStringGridOptions;
    procedure UpdateStringGridExternV;
    procedure SaveParams;
    procedure SaveState;
    procedure SaveOptions;
    // procedure SaveExterns;
    procedure ChangeStateIniFile;
  end;

var
  FormMod: TFormMod;
//  paintbox: TPaintBox;

implementation

uses
  UState, UFormShow1_1, UMeasValue, math, UFormShowFinalValues, FormSGA,
  Vcl.Imaging.pngimage, System.TypInfo;
{$R *.DFM}

function FileIsEmpty(const FileName: String): Boolean;
var
  fad: TWin32FileAttributeData;
begin
  Result := GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @fad)
    and (fad.nFileSizeLow = 0) and (fad.nFileSizeHigh = 0);
end;

procedure TFormMod.Menu_RunClick(Sender: TObject);
begin
  RunModel;
end;

procedure TFormMod.SpeedButtonRunClick(Sender: TObject);
begin
  RunModel;
end;

procedure TFormMod.SpeedButtonSaveToWMFClick(Sender: TObject);

var
  fn: string;
begin
  fn := self.EditOutputdatafilename.Text;
  fn := ChangeFileExt(fn, '.wmf');
  self.ChartSimResults.SaveToMetafileEnh(fn);
  showmessage('Saved Chart to ' + fn)
end;

procedure TFormMod.Menu_ExitClick(Sender: TObject);
begin
  application.terminate;
end;

procedure TFormMod.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Lmod.LinkedModel.FPropIniFile.WriteInteger('ComboBoxes', ComboBoxSubMod.Name, self.ComboBoxSubMod.ItemIndex);
  Lmod.LinkedModel.FPropIniFile.WriteInteger('ComboBoxes', self.ComboBoxIniFile.Name, self.ComboBoxIniFile.ItemIndex);
  Lmod.LinkedModel.FPropIniFile.UpdateFile;
  Lmod.LinkedModel.FPropIniFile.Free;
  img_help.Free;
  img_savetoall.Free;
  // if LMod.LinkedModel <> nil then
  // self.LMod.LinkedModel.BeforeDestruction;
end;

procedure TFormMod.FormCreate(Sender: TObject);

var
  CtrlFileFN, fn, path, prop_path,
  FirstIniFileFN, OutDir : string;
  CtrlFile : TStreamReader;
//  CtrlfileLine : string;
//  CtrlFile : textfile;

  i: Integer;
  ActSubMod: TSubModel;
  SelectionStr : string;

begin
 inherited;
  if ParamCount > 0 then begin
    // Execute HUME with ParameterStrings 1: FN-File and 2; Output-Directory
    // without showing the GUI   -  Ulf Böttcher 25.8.2021
    CtrlFileFN := ParamStr(1);
    OutDir := ParamStr(2);
    if Lmod.fModel <> nil then
    begin
      if OutDir <> '' then Lmod.fModel.GM_OutPutPath := OutDir;
      LMod.fModel.Set_ControlFileFN(CtrlFileFN);
      Lmod.fModel.init(Lmod.fModel.actIniFile);
      Lmod.fModel.InitAllSubMods;

      // gespeicherte Properties aus *ini Datei einlesen
  {    path :=  ExtractFilePath(ParamStr(0));
      fn := path+ 'properties.ini';
      FPropIniFile := TMyIniFile.create(fn);
      for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
      begin
        ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
        with ActSubMod do
        begin
          setPropFromIniFile(stateStrList, Name);
          setPropFromIniFile(VarStrList, Name);
          setPropFromIniFile(ExternVStrList, Name);
        end;
      end;     }

      Lmod.fModel.run;
    end;
//    halt;
    Application.Terminate;
//    Application.ProcessMessages;
//    Application.HandleException(self);
//    If Application.Terminated then begin
//     halt;
//    end;
  end;

//  Lmod.fModel.Get_ControlFileFn;
{  path :=  ExtractFilePath(ParamStr(0));
  fn := path+ 'properties.ini';
  if self.Lmod.fModel <> NIL then begin
    self.Lmod.fModel.FPropIniFile := TMyIniFile.create(fn, TEncoding.UTF8);
    CtrlFileFN := Lmod.fModel.FPropIniFile.ReadString('Files', 'ControlFile',CtrlFileFN);
     Lmod.fModel.GM_ControlFile  := CtrlFileFN;
     Lmod.fModel.FPropIniFile.UpdateFile;
  end;
  fn := self.Lmod.fModel.FPropIniFile.ReadString('Files', 'ControlFile', path+'Control.fn');
  if fn <> (path+'Control.fn') then
  CtrlFileFN := fn;      }

  ModelWasRunning := false;
  nFormGraph := 0;
  if Lmod.fModel <> nil then
  begin
    if (Lmod.fModel.title <> '') then
      self.Caption := Lmod.fModel.title;
    CtrlFileFN := Lmod.fModel.GM_ControlFile;
    if fileexists(CtrlFileFN) then begin
      CtrlFile := TStreamReader.Create(CtrlFileFN, TEncoding.UTF8, True);
//      assignfile(CtrlFile, CtrlFileFN);
//      reset(CtrlFile);
      FirstIniFileFN := CtrlFile.Readline;
//      readln(CtrlFile, FirstIniFileFN);
//      closefile(CtrlFile);
      If Lmod.fModel.ActIniFile = nil then
        Lmod.fModel.ActIniFile := TMemIniFile.Create( FirstIniFileFN);
      CtrlFile.free;
      Lmod.fModel.init(Lmod.fModel.ActIniFile);
      ComboBoxTimeAxisOption.ItemIndex := 0;
      EditOutputDirectory.Text := Lmod.fModel.GM_OutPutPath;
    end;
  if Lmod.fModel <> nil then
  begin
    if Lmod.fModel.FPropIniFile = nil then
    begin
      prop_path := ExtractFilePath(ParamStr(0));
      fn := prop_path + 'properties.ini';
      // fn := 'properties.ini';
      Lmod.fModel.FPropIniFile := TMyIniFile.Create(fn, TEncoding.UTF8);
    end;
  end;
  self.Lmod.fModel.FPropIniFile.ReadInteger('ComboBoxes', ComboBoxSubMod.Name,ComboBoxSubMod.ItemIndex);
  self.Lmod.fModel.FPropIniFile.ReadInteger('ComboBoxes', ComboBoxIniFile.Name,ComboBoxIniFile.ItemIndex);
  SelectionStr := Lmod.fModel.FPropIniFile.ReadString('ModelSettings', 'ContOutput', 'ContOutput');
  Lmod.fModel.OptContOutput :=  TContOutput(GetEnumValue(System.TypeInfo(TContOutput), SelectionStr));
  self.ComboBoxContOutput.ItemIndex := GetEnumValue(System.TypeInfo(TContOutput), SelectionStr);
  // if PropIniFile has already content
  if (ComboBoxSubMod.ItemIndex <>-1) and (ComboBoxIniFile.ItemIndex <> -1) then
    ComboBoxSubMod.OnChange(nil);
  end;

  // StatusBarMain.Panels[2].Style := psOwnerDraw;
  EXE_PATH := ExtractFilePath(application.EXEName);
  AdvStringGridStat.ControlLook.NoDisabledButtonLook := True;


  // ReportMemoryLeaksOnShutdown := True;

  img_help := TBitmap.create();
  img_savetoall := TBitmap.create();
  il1.GetBitmap(1, img_help);
  il1.GetBitmap(0, img_savetoall);
  if self.Lmod.fModel <> nil then
  begin
   CtrlFileFN := self.Lmod.fModel.FPropIniFile.ReadString('Files',
      'ControlFile', '');
    if CtrlFileFN = '' then
      CtrlFileFN := Lmod.fModel.GM_ControlFile;
    EditControlFile.Text := CtrlFileFN;
  end;
 // Lmod.fModel.Set_ControlFileFN(CtrlFileFN);
//  Lmod.fModel.GM_ControlFile := CtrlFileFN;
  updateForm;


end;

procedure TFormMod.RunModel;
var
  starttime, endtime, timelapsed: real;
begin
  // setSoilWaterMod;
  Screen.cursor := CrHourGlass;
  StatusBarMain.Panels.Items[0].Text := 'Running';
  StatusBarMain.show;
  MenuView.Enabled := True;
  starttime := time;

  if Lmod.fModel <> nil then
    Lmod.fModel.run
  else
  begin
    showmessage('No Model linked!');
    exit;
  end;
  endtime := time;
  timelapsed := endtime - starttime;
  update_StringGrid(Lmod.fModel.reg_fn); // TODO
  Screen.cursor := CrDefault;
  StatusBarMain.Panels.Items[0].Text := ' Runtime: ' + TimeToStr(timelapsed);
  // if LMod.fModel.ReInitAfterRun then // TODO
  // LMod.fModel.init(LMod.fModel.actIniFile);

  // SaveState;
  // SaveOptions;
  // SaveParams;

  ComboBoxInifileChange(nil);
  ComboBoxSubModChange(nil);

end;

// ==============================================================================
// UpdateStringGrid für alle States
// ==============================================================================

procedure TFormMod.UpdateStringGridParam;
var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  Param: TPar;
  line: string;
begin
  with AdvStringGridParam do
  begin
    BeginUpdate;
    if Lmod.fModel.ParamInifile <> nil  then begin

    EditParamFileName.Text := Lmod.fModel.ParamInifile.FileName;
    Clear;
    Rows[0].commatext := 'Name, Unit, Value, Save_to_all_Inis, Info';
    RowCount := 2;
    FixedRows := 1;

    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.ParStrList.count + 1;
      for i := 0 to SubModel.ParStrList.count - 1 do
      begin
        Param := TPar(SubModel.ParStrList.objects[i]);
        with Param do
          line := name + ',' + u + ',' + floattoStrF(v, ffgeneral, 6, 3);
        Rows[i + 1].commatext := line;
        AddBitButton(3, i + 1, 20, 20, '', img_savetoall, haCenter, vaCenter);
        if Param.Comment <> '' then
          AddBitButton(4, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
      end;
    end;
    EditParamFileName.hint := Lmod.fModel.ParamInifile.FileName;
    AutoSizeColumns(True);
    end;
    Endupdate;
  end;

end;

procedure TFormMod.UpdateStringGridState();

var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  state: TState;
  line: string;
begin
  with AdvStringGridState do
  begin

    BeginUpdate;
    // WIESO WIRD HIER DAS GESAMTE MODELL NOCH MAL ERZEUGT?
    // ActIniFileIndex := ComboBoxIniFile.ItemIndex;
    // Inifile := TMyIniFile(LMod.fModel.FiniFiles.objects[ActIniFileIndex]);
    // LMod.fModel.init(IniFile);
    // LMod.fModel.InitAllSubMods;
    if LMod.fModel.StateIniFile <> nil then begin

    EditStateFileName.Text := Lmod.fModel.StateIniFile.FileName;
    Clear;
    Rows[0].commatext :=
      'Name, Unit, Ini.Value, SaveToAllInis, WriteToFile, Plot, WriteFinalValue, GlobalOutput, Ínfo';
    // Description';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex >= 0 then
    begin
      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.stateStrList.count + 1;
      for i := 0 to SubModel.stateStrList.count - 1 do
      begin
        state := TState(SubModel.stateStrList.objects[i]);
        with state do
          line := name + ',' + u + ',' + floattoStrF(v, ffgeneral, 6, 3);
        Rows[i + 1].commatext := line;
        AddBitButton(3, i + 1, 20, 20, '', img_savetoall, haCenter, vaCenter);
        AddCheckBox(4, i + 1, True, True);
        SetCheckBoxState(4, i + 1, state.writeToFile);
        AddCheckBox(5, i + 1, True, True);
        SetCheckBoxState(5, i + 1, state.PlotToGraph);
        AddCheckBox(6, i + 1, True, True);
        SetCheckBoxState(6, i + 1, state.WriteFinalValue);
        AddCheckBox(7, i + 1, True, True);
        SetCheckBoxState(7, i + 1, state.GlobalOutput);
        if state.Comment <> '' then
          AddBitButton(8, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
      end;
    end;
    EditStateFileName.hint := Lmod.fModel.StateIniFile.FileName;

    AutoSizeColumns(True);
    end;
    Endupdate;
  end;
end;

procedure TFormMod.UpdateStringGridExternV;

var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  ExVar: TExternV;
  line: string;

begin
  with AdvStringGridExternV do
  begin
    BeginUpdate;
    Clear;
    Rows[0].commatext := 'Name, Unit, Factor, Source, WriteToFile, Plot, Info';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.ExternVStrList.count + 1;
      for i := 0 to SubModel.ExternVStrList.count - 1 do
      begin
        ExVar := TExternV(SubModel.ExternVStrList.objects[i]);
        with ExVar do
          line := name + ',' + u + ',' + floattoStrF(C_f, ffgeneral, 6, 3) +
            ',' + Source;
        Rows[i + 1].commatext := line;
        AddCheckBox(4, i + 1, True, True);
        SetCheckBoxState(4, i + 1, ExVar.writeToFile);
        AddCheckBox(5, i + 1, True, True);
        SetCheckBoxState(5, i + 1, ExVar.PlotToGraph);
        if ExVar.Comment <> '' then
          AddBitButton(6, i + 1, 20, 20, '', img_help, haCenter, vaCenter);

      end;
    end;
    AutoSizeColumns(True);
    Endupdate;
  end;
end;

procedure TFormMod.UpdateStringGridOptions();
var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  Option: TOption;
  line: string;
begin
  with AdvStringGridOptions do
  begin
    BeginUpdate;
    // TODO ActIniFileIndex := ComboBoxIniFile.ItemIndex;
    // TODO Inifile := TMyIniFile(LMod.fModel.FiniFiles.objects[ActIniFileIndex]);
    // TODO LMod.fModel.init(IniFile);
    // TODO LMod.fModel.InitAllSubMods;
    if Lmod.fModel.OptionIniFile <> nil then begin

    EditOptionsFileName.Text := Lmod.fModel.OptionIniFile.FileName;
    Clear;
    Rows[0].commatext := 'Name, Options, SaveToAllIni, Info';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.OptionStrList.count + 1;
      for i := 0 to SubModel.OptionStrList.count - 1 do
      begin
        Option := TOption(SubModel.OptionStrList.objects[i]);
        line := Option.name + ',' + Option.Option;
        Rows[i + 1].commatext := line;
        AddBitButton(2, i + 1, 20, 20, '', img_savetoall, haCenter, vaCenter);
        if Option.Comment <> '' then
          AddBitButton(3, i + 1, 20, 20, '', img_help, haCenter, vaCenter);

      end;
    end;
    AutoSizeColumns(True);
    end;
    Endupdate;
  end;
end;

procedure TFormMod.UpdateStringGridVar;
var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  Variable: TVar;
  line: string;
begin
  if LMod.fModel.StateIniFile <> nil then begin

  EditStateFileName.Text := Lmod.fModel.StateIniFile.FileName;
  with AdvStringGridVar do
  begin
    BeginUpdate;
    Clear;
    Rows[0].commatext := 'Name, Unit, WriteToFile,  Plot, WriteFinalValue,Globaloutput,Info';
    // Description';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex >= 0 then
    begin
      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.VarStrList.count + 1;
      for i := 0 to SubModel.VarStrList.count - 1 do
      begin
        Variable := TVar(SubModel.VarStrList.objects[i]);
        line := Variable.name + ',' + Variable.u;
        Rows[i + 1].commatext := line;
        AddCheckBox(2, i + 1, True, True);
        SetCheckBoxState(2, i + 1, Variable.writeToFile);
        AddCheckBox(3, i + 1, True, True);
        SetCheckBoxState(3, i + 1, Variable.PlotToGraph);
        AddCheckBox(4, i + 1, True, True);
        SetCheckBoxState(4, i + 1, Variable.WriteFinalValue);
        AddCheckBox(5, i + 1, True, True);
        SetCheckBoxState(5, i + 1, Variable.fGlobalOutput);
        if Variable.Comment <> '' then
          AddBitButton(6, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
      end;

    end;
    AutoSizeColumns(True);
    Endupdate;
  end;
  end;
end;

procedure TFormMod.UpdatePageResultTab;
var
  actSubModIndex, actInifileIndex: Integer;
  SubModel: TSubModel;
  IniFile: TMyIniFile;
  fn: string;
  i: Integer;
begin
  Screen.cursor := CrHourGlass;
  with AdvStringGridResults do
  begin
    BeginUpdate;
    ColCount := 2;
    RowCount := 3;
    Clear;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    actInifileIndex := ComboBoxIniFile.ItemIndex;
    if (actSubModIndex <> -1) and (actInifileIndex <> -1) then
    begin

      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      IniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[actInifileIndex]);
      fn := IniFile.ReadString('OutputFiles', SubModel.name, '');
      if fn = '' then
        fn := SubModel.fn_state
      else
        fn := fn + '_dat.csv';
      if FileExists(fn) = True then
      begin
        ShowDataFile(fn);
        EditOutputdatafilename.Text := fn
      end;
      if CheckBoxDateFormat.Checked = True then
        for i := 1 to RowCount - 2 do
          cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]));

      AutoSizeColumns(True);
    end;
    Endupdate;
  end;
  Screen.cursor := CrDefault;
end;

procedure TFormMod.UpdatePageGraphResult;
var
  actSubModIndex, actInifileIndex: Integer;
  SubModel: TSubModel;
  IniFile: TMyIniFile;
//  ActState: TState;
  ActVar: TVar;
  fnMeas: string;
  X, Y: real;
  ActLineSeries: TFastLineSeries;
  ActPointSeries: TPointSeries;
  DataFileSim: TTextFileH;
  DataFileMeas: TTextFileH;
  HasDataFilesim, HasDataFileMeas : boolean;
  // nrs: array[0..MaxSeries - 1] of Integer;

  procedure drawSimGraph(strList: TStringList);
  var
    i, nr: Integer;
    ActState : TState;
  begin
    for i := 0 to strList.count - 1 do
    begin
      ActState := TState(strList.objects[i]);
      if ActState.PlotToGraph then
      begin
        inc(n_lineSeries);
        LineSeriesArr[n_lineSeries] := TFastLineSeries.create(ChartSimResults);
        ActLineSeries := LineSeriesArr[n_lineSeries];
        with ActLineSeries do
        begin
          Xvalues.DateTime := (ComboBoxTimeAxisOption.Text = 'Date');
          title := ActState.name + ' ' + ActState.u;
          LinePen.Width := 2;
        end;
        ChartSimResults.AddSeries(ActLineSeries);
        nr := DataFileSim.indexOf(ActState.name);
        if nr <> -1 then
        begin

          with DataFileSim do
          begin
            GoTop;
            while hasMoreLines() do
            begin
              FastNextLine;

              X := getIndexValue(0);
              Y := getIndexValue(nr);
              if not isnan(X) and not isnan(Y) then
                ActLineSeries.addxy(X, Y, '', ClteeColor);
            end;
          end;
        end;
      end;
    end;

  end;

  procedure drawMeasGraph(strList: TStringList);
  var
    i, nr: Integer;
  begin
    for i := 0 to strList.count - 1 do
    begin
      ActVar := TVar(strList.objects[i]);
      if ActVar.PlotToGraph then
      begin
        inc(n_PointSeries);
        if (DataFileMeas.containsName(ActVar.name)) then
        begin
          ActPointSeries := TPointSeries.create(ChartSimResults);
          with ActPointSeries do
          begin
            title := ActVar.name + ' ' + ActVar.u;
            if (LineSeriesArr[n_PointSeries] <> nil) then
            begin
              SeriesColor := LineSeriesArr[n_PointSeries].SeriesColor;
            end;
          end;
          ChartSimResults.AddSeries(ActPointSeries);

          with DataFileMeas do
          begin
            nr := indexOf(ActVar.name);
            GoTop;
            while hasMoreLines() do
            begin
              FastNextLine;
              X := getIndexValue(0);
              Y := getIndexValue(nr);
              if not isnan(X) and not isnan(Y) and (X >= Lmod.fModel.starttime)
                and (X <= Lmod.fModel.endtime) then
                if (LineSeriesArr[n_PointSeries] <> nil) then
                begin
                  ActPointSeries.addxy(X, Y, '',
                    LineSeriesArr[n_PointSeries].SeriesColor)
                end
                else
                begin
                  ActPointSeries.addxy(X, Y, '', ClteeColor);
                end;
            end;
          end;
        end;
      end;
    end;
  end;

begin
  // UpdatePageResultTab;
  HasDataFilesim := false;
  HasDataFileMeas := false;

  Screen.cursor := CrHourGlass;
  ChartSimResults.AutoRepaint := false;

  actSubModIndex := ComboBoxSubMod.ItemIndex;
  actInifileIndex := ComboBoxIniFile.ItemIndex;
  if (actSubModIndex <> -1) and (actInifileIndex <> -1) then
  begin

    SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
    IniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[actInifileIndex]);

    fnMeas := IniFile.ReadString('MeasurementFiles', SubModel.name, '');

    with ChartSimResults do
    begin
      RemoveAllSeries;
      title.Clear;
      Legend.LegendStyle := lsSeries;
    end;

    if (SubModel.OptContOutput) or (Lmod.fModel.OptContOutput = AllContoutput) then begin
      DataFileSim := TTextFileH.create;
      if fileexists(SubModel.fn_state) then begin
        DataFileSim.init(SubModel.fn_state);
        HasDataFileSim := true;
      end;
    end;
    if fnMeas <> '' then begin
      DataFileMeas := TTextFileH.create;
      DataFileMeas.init (fnMeas);
      HasDataFileMeas := true;
    end;


    if FileExists(SubModel.fn_state) and (SubModel.OptContOutput) then
    begin
      n_lineSeries := -1;
      drawSimGraph(SubModel.stateStrList);
      drawSimGraph(SubModel.VarStrList);
      drawSimGraph(SubModel.ExternVStrList);
    end;

    if FileExists(fnMeas) and SelectMeasDataCheckBox.Checked then
    begin
      n_PointSeries := -1;
      drawMeasGraph(SubModel.stateStrList);
      drawMeasGraph(SubModel.VarStrList);
    end;

  //  if (DataFileSim.FName <> '') then
//  if (DataFileMeas.FName <> '') then

    ChartSimResults.AutoRepaint := True;
    ChartSimResults.Repaint;
  end;
  Screen.cursor := CrDefault;
  if HasDataFileSim then
     FreeAndNil(DataFileSim);
  if HasDataFileMeas then
      FreeAndNil(DataFileMeas);
end;

procedure TFormMod.UpdateStringGridData;

var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  filedata, linedata: TStringList;

begin
  Screen.cursor := CrHourGlass;
  AdvStringGridData.BeginUpdate;
  AdvStringGridData.Clear;
  AdvStringGridData.ColCount := 3;
  AdvStringGridData.RowCount := 3;

  actSubModIndex := ComboBoxSubMod.ItemIndex;
  if actSubModIndex <> -1 then
  begin

    SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);

      if SubModel.SomethingMeasured then
    begin
      filedata := TStringList.create;
      try
        filedata.loadfromfile(SubModel.FMeasValues.FName);
        AdvStringGridData.RowCount := Math.Max(filedata.count,
          AdvStringGridData.FixedRows + 1);
        linedata := TStringList.create;
        try
          linedata.Delimiter := #32;
          // space, multiple spaces are treated as one delimiter
          for i := 0 to filedata.count - 1 do
          begin
            linedata.DelimitedText := filedata[i];
            if AdvStringGridData.ColCount < linedata.count then
              AdvStringGridData.ColCount := linedata.count;
            AdvStringGridData.Rows[i].Assign(linedata);
          end;
        finally
          linedata.Free;
        end;
      finally
        filedata.Free;
      end;
      AdvStringGridData.FixedRows := 2;
      AdvStringGridData.FixedCols := 0;

      EditDataFileName.Text := SubModel.FMeasValues.FName;
      EditDataFileName.hint := SubModel.FMeasValues.FName;

      // LoadFromCSV(SubModel.FMeasValues.FileName);
      // wäre wesentlich einfacher, geht aber nicht,
      // weil die Daten mit beliebig vielen Leerzeichen getrennt sind

      if CheckBoxDataDateFormat.Checked then
        for i := 1 to AdvStringGridData.RowCount - 1 do
          AdvStringGridData.cells[0, i + 1] :=
            datetimetostr(strtofloat(AdvStringGridData.cells[0, i + 1]));
    end
    else
    begin
      EditDataFileName.Text := '';
      EditDataFileName.hint := '';
    end;
    AdvStringGridData.AutoSizeColumns(True);
  end;
  AdvStringGridData.Endupdate;
  Screen.cursor := CrDefault;
  AdvStringGridData.visible := True;
  // AdvStringGridData.Show;
end;

procedure TFormMod.UpdatePageIntegration;
begin
  EditTimeStep.Text := FloatToStr(Lmod.fModel.time.c);
  EditStartTime.Text := FloatToStr(Lmod.fModel.time.v);
  EditEndTime.Text := FloatToStr(Lmod.fModel.endtime);
  // Treue
  FWDLabel.Caption := IntToStr(Lmod.fModel.FirstWeatherData);
  // FWDDateLabel.Caption := DateToStr(LMod.fModel.FirstWeatherData);
  LWDLabel.Caption := IntToStr(Lmod.fModel.LastWeatherData);
  // LWDDateLabel.Caption := DateToStr(LMod.fModel.LastWeatherData);
  // Treue
  if (Lmod.fModel.weatherfile <> nil) and
    FileExists(Lmod.fModel.weatherfile.FName) then
    EditWeatherfile.Text := Lmod.fModel.weatherfile.FName;
  if Lmod.fModel.StateIniFile <> nil then
    EditStateIniFileName.Text := Lmod.fModel.StateIniFile.FileName;
  if Lmod.fModel.ParamIniFile <> nil then
    EditParamIniFileName.Text := Lmod.fModel.ParamInifile.FileName;
  if Lmod.fModel <> nil then
   EditOutputDirectory.Text := Lmod.fModel.GM_OutPutPath;
end;

// ==============================================================================
// ComboxBox
// ==============================================================================

procedure TFormMod.ComboBoxContOutputChange(Sender: TObject);

{const
  ContOutputstr : array of string = ['NoContOutput',
                'AllContoutput',
                'SubmodelSpecific'];    }

var
  Selndx : integer;
  SelectionStr : string;
  Selection : TContoutput;
  Model : TMod;


begin
  Selndx := self.ComboBoxContOutput.ItemIndex;
  SelectionStr := GetEnumName(System.TypeInfo(TContOutput), Selndx);
  Model := Lmod.fModel;
  if Selndx <> -1 then
    Model.FPropIniFile.WriteString('ModelSettings', 'ContOutput', SelectionStr) ;
end;

procedure TFormMod.ComboBoxInifileChange(Sender: TObject);
var
  actInifileIndex: Integer;
begin
  actInifileIndex := ComboBoxIniFile.ItemIndex;
  ComboBoxIniFile.hint := ComboBoxIniFile.Items[ComboBoxIniFile.ItemIndex];
  Lmod.fModel.actIniFile :=
    TMyIniFile(Lmod.fModel.FIniFiles.objects[actInifileIndex]);
  Lmod.fModel.init(Lmod.fModel.actIniFile);
  Lmod.fModel.InitAllSubMods;
  UpdateStringGridData;
  UpdateStringGridParam;
  UpdateStringGridState;
  UpdateStringGridVar;
  UpdateStringGridOptions;
  UpdatePageIntegration;
  if PageControl.ActivePage = TabSheetResultTab then
    UpdatePageResultTab
  else if PageControl.ActivePage = TabSheetGraphResult then
    UpdatePageGraphResult;
end;

procedure TFormMod.ComboBoxIniFileDropDown(Sender: TObject);
var
  i: Integer;
  ItemWidth: Integer;
begin
  ItemWidth := 0;
  with ComboBoxIniFile do
  begin
    for i := 0 to Items.count - 1 do
      if Canvas.TextWidth(Items[i]) > ItemWidth then
        ItemWidth := Canvas.TextWidth((Items[i]));
    inc(ItemWidth, 10);
    Perform(CB_SetDroppedWidth, ItemWidth, 0);
  end;
end;

procedure TFormMod.ComboBoxSubModChange(Sender: TObject);
begin
  Lmod.fModel.InitAllSubMods;
  UpdateStringGridParam;
  UpdateStringGridState;
  UpdateStringGridExternV;
  UpdateStringGridVar;
  UpdateStringGridData;
  UpdateStringGridOptions;

  if PageControl.ActivePage = TabSheetResultTab then
    UpdatePageResultTab
  else if PageControl.ActivePage = TabSheetGraphResult then
    UpdatePageGraphResult;

  if PageControl.ActivePage = TabSheetParameter then
    AdvStringGridParam.SetFocus
  else if PageControl.ActivePage = TabSheetState then
    AdvStringGridState.SetFocus
  else if PageControl.ActivePage = TabSheetVariables then
    AdvStringGridVar.SetFocus
  else if PageControl.ActivePage = TabSheetOptions then
    AdvStringGridOptions.SetFocus
  else if PageControl.ActivePage = TabSheetData then
    AdvStringGridData.SetFocus
  else if PageControl.ActivePage = TabSheetExternalValues then
    AdvStringGridExternV.SetFocus
  else if PageControl.ActivePage = TabSheetResultTab then
    AdvStringGridResults.SetFocus;
  // else if PageControl.ActivePage = TabSheetGraphResult then
  // ChartSimResults.SetFocus;

end;

procedure TFormMod.ComboBoxTimeAxisOptionChange(Sender: TObject);
begin
  UpdatePageGraphResult;
end;

procedure TFormMod.update_StringGrid(fn: string);
var
  i: Integer;
  strList: TStringList;
begin
  if (AdvStringGridStat <> nil) then begin

    with AdvStringGridStat do begin
      Clear;
      if (Lmod.fModel <> nil) and FileExists(Lmod.fModel.reg_fn) then
      begin
        strList := TStringList.create;
        strList.loadfromfile(Lmod.fModel.reg_fn);
        if strList.count > 1 then
          begin
            BeginUpdate;
            RowCount := strList.count;
            FixedRows := 1;
            ColCount := 12;
            FixedCols := 2;
            Rows[0].commatext := strList[0];
            for i := 1 to strList.count - 1 do
            begin
              Rows[i].commatext := strList[i];
              AddButton(11, i, 50, 20, '1 / 1', haBeforeText, vaCenter);
            end;

            AutoSizeColumns(True);
            Endupdate;
          end;

        strList.Free;
      end;
    end;
  end;
end;

// ==============================================================================
// Save
// ==============================================================================

procedure TFormMod.ButtonSaveIntegrChangesClick(Sender: TObject);

var
  i: Integer;
  ActSubMod: TSubModel;
begin
  with Lmod.fModel.actIniFile do
  begin
    UpdateFile;
    WriteFloat('TimeInit', 'Startzeit', strtofloat(EditStartTime.Text));
    WriteFloat('TimeInit', 'Endzeit', strtofloat(EditEndTime.Text));
    WriteFloat('TimeInit', 'TimeStep', strtofloat(EditTimeStep.Text));
    WriteString('FileNames', 'StateIniFN', EditStateIniFileName.Text);
    WriteString('FileNames', 'ParamIniFN', EditParamIniFileName.Text);
    WriteString('FileNames', 'WeatherFileFN', EditWeatherfile.Text);
    for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
      if ActSubMod.FMeasValues <> nil then
        if FileExists(ActSubMod.FMeasValues.FName) then
          with ActSubMod do
            WriteString('MeasurementFiles', Name, FMeasValues.FName)
    end;
    for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
      if ActSubMod.FMeasValues <> nil then
        if FileExists(ActSubMod.FMeasValues.FName) then
          with ActSubMod do
            WriteString('MeasurementFiles', Name, FMeasValues.FName)
    end;

    UpdateFile;
  end;
end;

procedure TFormMod.ButtonSaveDataChangesClick(Sender: TObject);
var
  SubModel: TSubModel;
  i, actSubModIndex: Integer;
  f: textFile;
  line: string;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  if (actSubModIndex = -1) then
  begin
    SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
    assignFile(f, SubModel.FMeasValues.FName);
    reset(f);
    for i := 1 to AdvStringGridData.RowCount do
    begin
      line := AdvStringGridData.Rows[i].Text;
      writeln(f, line);
    end;
    SubModel.init(Lmod.fModel);
    closeFile(f);
  end;
end;

procedure TFormMod.updatePropIniFile(strList: TStringList; submodname: string);
var
  i: Integer;
  entity: THumeNumEntity;
begin
  for i := 0 to strList.count - 1 do
  begin
    entity := THumeNumEntity(strList.objects[i]);
    with self.Lmod.fModel.FPropIniFile  do
    begin
      WriteBool(submodname, entity.Name + '.PlotTograpH', entity.PlotToGraph);
      WriteBool(submodname, entity.Name + '.WriteFinalValue', entity.WriteFinalValue);
      WriteBool(submodname, entity.Name + '.GlobalOutput', entity.fGlobalOutput);
      // if entity.PlotToGraph then
      // entity.WriteToFile := true;
      WriteBool(submodname, entity.Name + '.WriteToFile', entity.writeToFile);
      WriteBool(submodname, entity.Name + '.SelForSensOut', entity.SelForSensOut);
    end;
  end;
  Lmod.fModel.FPropIniFile.UpdateFile;
end;

procedure TFormMod.SaveState;
var
  StateIniFile: TMyIniFile;
  actSubModIndex, i: Integer;
  SubModel: TSubModel;
  ActState: TState;
  StateNdx: Integer;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  StateIniFile := Lmod.fModel.StateIniFile;
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);

  with AdvStringGridState do
  begin
    for i := 1 to RowCount - 1 do
    begin
      StateIniFile.WriteFloat(SubModel.submodname, cells[0, i],
        strtofloat(cells[2, i]));
      StateNdx := SubModel.stateStrList.indexOf(cells[0, i]);
      if StateNdx >= 0 then
      begin
        ActState := TState(SubModel.stateStrList.objects[StateNdx]);
        ActState.v := strtofloat(cells[2, i]);
        GetCheckBoxState(4, i, ActState.writeToFile);
        GetCheckBoxState(5, i, ActState.PlotToGraph);
        if not ActState.writeToFile then
          GetCheckBoxState(4, i, ActState.writeToFile);
        // if plotToGraph is set then also WriteToFile ..
        GetCheckBoxState(6, i, ActState.WriteFinalValue);
        GetCheckBoxState(7, i, ActState.fGlobalOutput);

      end;
    end;
  end;

  updatePropIniFile(SubModel.stateStrList, SubModel.name);
  StateIniFile.UpdateFile;
  self.UpdateStringGridState;
  Lmod.fModel.init(Lmod.fModel.actIniFile);
  Lmod.fModel.InitAllSubMods;
  // UpdateStringGridState;
end;

procedure TFormMod.SaveOptions;
var
  OptionIniFile: TMyIniFile;
  actSubModIndex, i: Integer;
  SubModel: TSubModel;
  OptionString: string;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  OptionIniFile := Lmod.fModel.OptionIniFile;
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  with AdvStringGridOptions do
  begin
    if cells[1, 1] <> '' then
    begin
      for i := 1 to RowCount - 1 do
      begin
        OptionString := cells[1, i];
        OptionIniFile.WriteString(SubModel.submodname, cells[0, i],
          cells[1, i]);
        // OptionNdx := SubModel.OptionSTrList.IndexOf(AdvStringGridOptions.Cells[0, i]);
        // ActOption := TOption(SubModel.OptionSTrList.objects[OptionNdx]);
      end;
    end;
  end;

  OptionIniFile.UpdateFile;
  Lmod.fModel.init(Lmod.fModel.actIniFile);
  Lmod.fModel.InitAllSubMods;
  // UpdateStringGridOptions();
end;

procedure TFormMod.SaveParams;
var
  ParamInifile: TMyIniFile;
  actSubModIndex, i: Integer;
  SubModel: TSubModel;
  Actpar: TPar;
  index: Integer;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  ParamInifile := Lmod.fModel.ParamInifile;
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  with AdvStringGridParam do
  begin
    for i := 1 to RowCount - 1 do
    begin
      index := SubModel.ParStrList.indexOf(cells[0, i]);
      if index >= 0 then
      begin
        Actpar := TPar(SubModel.ParStrList.objects[index]);
        if Actpar.writeToIniFile then
        begin
          ParamInifile.WriteFloat(SubModel.submodname, cells[0, i],
            strtofloat(cells[2, i]));
        end;
      end;
    end;
  end;

  ParamInifile.UpdateFile;
  Lmod.fModel.init(Lmod.fModel.actIniFile);
  Lmod.fModel.InitAllSubMods;
  // UpdateStringGridParam;
end;

 procedure TFormMod.SaveExterns;

 var
   actSubModIndex, i: Integer;
   SubModel: TSubModel;
   ActExVar: TExternV;
   index: Integer;
 begin
   actSubModIndex := ComboBoxSubMod.ItemIndex;
   SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
   with self.AdvStringGridExternV do
   begin
     for i := 1 to RowCount - 1 do
     begin
       index := SubModel.ExternVStrList.indexOf(cells[0, i]);
       if index >= 0 then
       begin
         ActExVar := TExternV(SubModel.ExternVStrList.objects[index]);
         GetCheckBoxState(5, i, ActExVar.PlotToGraph);
       end;
     end;
   end;
 end;

 procedure TFormMod.SaveVar();
var
  ActVar: TVar;
  i, actSubModIndex, VarNdx: Integer;
  SubModel: TSubModel;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  with AdvStringGridVar do
  begin
    for i := 1 to RowCount - 1 do
    begin
      VarNdx := SubModel.VarStrList.indexOf(cells[0, i]);
      if VarNdx >= 0 then
      begin
        ActVar := TVar(SubModel.VarStrList.objects[VarNdx]);
        GetCheckBoxState(2, i, ActVar.writeToFile);
        GetCheckBoxState(3, i, ActVar.PlotToGraph);
        if not ActVar.writeToFile then
          GetCheckBoxState(2, i, ActVar.writeToFile);
        GetCheckBoxState(4, i, ActVar.WriteFinalValue);
        GetCheckBoxState(5, i, ActVar.fGlobalOutput);
      end;
    end;
  end;
  updatePropIniFile(SubModel.VarStrList, SubModel.name);
  self.UpdateStringGridVar;
end;

procedure TFormMod.ButtonSaveToNewIniFileClick(Sender: TObject);

var
  NewInifile: TMyIniFile;
  index, i: Integer;
  IniFN: string;
  TempFile: TStreamWriter;
  ActSubMod: TSubModel;
begin
  with SaveDialog1 do
  begin
    title := 'New IniFile';
    DefaultExt := 'ini';
    Filter := 'Conrolfiles (*.ini)|*.ini';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
  end;
  if SaveDialog1.Execute then
  begin

    for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
      if FileExists(ActSubMod.FMeasValues.FName) then
        Lmod.fModel.actIniFile.WriteString('MeasurementFiles', ActSubMod.name,
          ActSubMod.FMeasValues.FName)
    end;

    Lmod.fModel.actIniFile.UpdateFile;

    NewInifile := TMyIniFile.create(SaveDialog1.FileName, TEncoding.UTF8);
    with NewInifile do
    begin
      WriteFloat('TimeInit', 'Startzeit', strtofloat(EditStartTime.Text));
      WriteFloat('TimeInit', 'Endzeit', strtofloat(EditEndTime.Text));
      WriteFloat('TimeInit', 'TimeStep', strtofloat(EditTimeStep.Text));
      WriteString('FileNames', 'StateIniFN', EditStateIniFileName.Text);
      WriteString('FileNames', 'ParamIniFN', EditParamIniFileName.Text);
      WriteString('FileNames', 'WeatherFileFN', EditWeatherfile.Text);
      UpdateFile;
    end;
    Lmod.fModel.FIniFiles.append(NewInifile.FileName);
    index := Lmod.fModel.FIniFiles.count - 1;
    Lmod.fModel.FIniFiles.objects[index] := NewInifile;

    TempFile := TStreamWriter.Create(Lmod.fModel.Get_ControlFileFn, false, TEncoding.UTF8);
  //  assignFile(TempFile, Lmod.fModel.Get_ControlFileFn);
//    rewrite(TempFile);
    for i := 0 to Lmod.fModel.FIniFiles.count - 1 do
    begin
      IniFN := TMyIniFile(Lmod.fModel.FIniFiles.objects[i]).FileName;
      TempFile.WriteLine(IniFN);
//      writeln(TempFile, IniFN);
    end;
//    closeFile(TempFile);
    TempFile.Free;

    Lmod.fModel.actIniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[index]);
    Lmod.fModel.init(Lmod.fModel.actIniFile);
    Lmod.fModel.InitAllSubMods;
    UpdateStringGridData;
    UpdateStringGridParam;
    UpdateStringGridState;
    UpdateStringGridVar;
    UpdatePageIntegration;
    UpdateStringGridOptions();
    if PageControl.ActivePage = TabSheetResultTab then
      UpdatePageResultTab;
    if PageControl.ActivePage = TabSheetGraphResult then
      UpdatePageGraphResult;

    FormShow(self);
    ComboBoxIniFile.ItemIndex := index;
    ComboBoxIniFile.OnChange(self);
  end;
  NewInifile.Free;
end;

procedure TFormMod.ButtonSaveStateClick(Sender: TObject);
begin
  //self.AdvStringGridState.SaveColPositions;
  SaveState
end;

procedure TFormMod.ButtonSaveOptionsClick(Sender: TObject);
begin
  SaveOptions;
end;

procedure TFormMod.ButtonSaveParamsClick(Sender: TObject);
begin
  SaveParams;
end;

procedure TFormMod.BitBtnMergeWeatherFNClick(Sender: TObject);

var
  i, lines: Integer;
  fn, w_fn, w_str, t_fn, actIniFN: string;
  AllData, actfile: textFile;
  NewLine: string;
  Model: TMod;
  actIniFile: TMyIniFile;
  ActWeather: TStringList;
  rep: Boolean;

  function DelDoubleSpaces(s: String): string;
  var
    p: Integer;
  begin
    s := trim(s);
    Repeat
      p := pos('  ', s);
      if p > 0 then
        delete(s, p + 1, 1);
    Until p = 0;

    Result := s;
  end;

begin
  ActWeather := TStringList.create;
  Model := Lmod.fModel;
  fn := Model.GM_OutPutPath + '\' + 'AllWeather.dat';
  assignFile(AllData, fn);
  rewrite(AllData);
  rep := false;
  for i := 0 to Model.FIniFiles.count - 1 do
  begin
    actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
    actIniFN := actIniFile.FileName;
    w_str := Model.Str_SectionTopic_WeatherFileFN;
    w_fn := actIniFile.ReadString(Model.Str_SectionName_FileNames, w_str, '');
    ActWeather.loadfromfile(w_fn);
    if rep = false then
    begin
      NewLine := DelDoubleSpaces(ActWeather.Strings[0]);
      NewLine := StringReplace(NewLine, ' ', Model.separator,
        [rfReplaceAll, rfIgnoreCase]);
      NewLine := 'IniFile' + Model.separator + 'WeatherFile' + Model.separator
        + NewLine;
      writeln(AllData, NewLine);
      for lines := 2 to ActWeather.count - 1 do
      begin
        NewLine := DelDoubleSpaces(ActWeather.Strings[lines]);
        NewLine := StringReplace(NewLine, ' ', Model.separator,
          [rfReplaceAll, rfIgnoreCase]);
        NewLine := actIniFN + Model.separator + w_fn + Model.separator
          + NewLine;
        writeln(AllData, NewLine);
        rep := True;
      end;
    end
    else
    begin
      for lines := 2 to ActWeather.count - 1 do
      begin
        NewLine := DelDoubleSpaces(ActWeather.Strings[lines]);
        NewLine := StringReplace(NewLine, ' ', Model.separator,
          [rfReplaceAll, rfIgnoreCase]);
        NewLine := actIniFN + Model.separator + w_fn + Model.separator
          + NewLine;
        writeln(AllData, NewLine);
      end;
    end;

  end;
  closeFile(AllData);
end;

procedure TFormMod.BitBtnSaveOptionsToClick(Sender: TObject);
begin
  if SaveTo('New OptionIniFile', 'OptionsIniFN', EditOptionsFileName,
    EditOptionsFileName) then
    SaveOptions;
end;

// ==============================================================================
// AdvStringGrid ButtonClick für alle States
// ==============================================================================

procedure TFormMod.AdvStringGridParamButtonClick(Sender: TObject;
  aCol, aRow: Integer);
var
  actIniFile, ActParamIniFile: TMyIniFile;
  actSubModIndex, index, i: Integer;
  SubModel: TSubModel;
  Model: TMod;
  Actpar: TPar;
  ParamIniFileFN: string;
begin
  Model := Lmod.fModel;

  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  if actSubModIndex < 0 then
  begin
    showmessage('Kein aktives Submodel gefunden.');
    exit;
  end;

  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.ParStrList.indexOf(AdvStringGridParam.cells[0, aRow]);

  if index >= 0 then
  begin
    Actpar := TPar(SubModel.ParStrList.objects[index]);
    if Actpar.writeToIniFile and (aCol = 3) then
    begin
      for i := 0 to Model.FIniFiles.count - 1 do
      begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        ParamIniFileFN := actIniFile.ReadString(Model.Str_SectionName_FileNames,
          Model.Str_SectionTopic_ParamIniFN, '');
        ActParamIniFile := TMyIniFile.create(ParamIniFileFN, TEncoding.UTF8);

        with ActParamIniFile, AdvStringGridParam do
        begin
          WriteFloat(SubModel.submodname, cells[0, aRow],
            strtofloat(cells[2, aRow]));
        end;
        ActParamIniFile.UpdateFile;
        ActParamIniFile.Free;
      end;
    end;
    if (aCol = 4) then
      showmessage(Actpar.Comment);
  end;
end;

procedure TFormMod.AdvStringGridOptionsAnchorClick(Sender: TObject;
  aRow, aCol: Integer; anchor: string; var AutoHandle: Boolean);
var
  actIniFile, ActOptionIniFile: TMyIniFile;
  i: Integer;
  index: Integer;
  actSubModIndex: Integer;
  SubModel: TSubModel;
  Model: TMod;
  Actpar: TPar;
  OptionIniFileFN: string;
begin
  Model := getLinkedModel;
  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);

  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.ParStrList.indexOf(AdvStringGridOptions.cells[0, aRow]);
  if index >= 0 then
  begin
    Actpar := TPar(SubModel.ParStrList.objects[index]);
    if Actpar.writeToIniFile then
    begin
      for i := 0 to Model.FIniFiles.count - 1 do
      begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        OptionIniFileFN := actIniFile.ReadString
          (Model.Str_SectionName_FileNames,
          Model.Str_SectionTopic_OptionIniFN, '');

        ActOptionIniFile := TMyIniFile.create(OptionIniFileFN, TEncoding.UTF8);
        with ActOptionIniFile do
        begin
          WriteFloat(SubModel.submodname, AdvStringGridOptions.cells[0, aRow],
            strtofloat(AdvStringGridOptions.cells[1, aRow]));
          UpdateFile;
          Free;
        end;
      end;
    end;
  end;
  ActOptionIniFile.Free
  // UpdateStringGridOptions;
end;

procedure TFormMod.AdvStringGridStateButtonClick(Sender: TObject;
  aCol, aRow: Integer);

var
  actIniFile, ActStateIniFile: TMyIniFile;
  actSubModIndex, i, index: Integer;
  SubModel: TSubModel;
  Model: TMod;
  ActState: TState;
  StateIniFileFN: string;
begin
  Model := getLinkedModel();

  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);

  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.stateStrList.indexOf(AdvStringGridState.cells[0, aRow]);
  if index >= 0 then
  begin
    ActState := TState(SubModel.stateStrList.objects[index]);

    if ActState.writeToIniFile and (aCol = 3) then
    begin
      for i := 0 to Model.FIniFiles.count - 1 do
      begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        StateIniFileFN := actIniFile.ReadString(Model.Str_SectionName_FileNames,
          Model.Str_SectionTopic_StateIniFN, '');

        ActStateIniFile := TMyIniFile.create(StateIniFileFN, TEncoding.UTF8);
        with ActStateIniFile, AdvStringGridState do
        begin
          WriteFloat(SubModel.submodname, cells[0, aRow],
            strtofloat(cells[2, aRow]));
          UpdateFile;
          FreeAndNil(ActStateIniFile);
        end;
      end;
    end;

    if aCol = 8 then
      showmessage(ActState.Comment);

  end;
//  ActStateIniFile.Free;
  // KLUSS UpdateStringGridState;
end;

procedure TFormMod.AdvStringGridOptionsButtonClick(Sender: TObject;
  aCol, aRow: Integer);
var
  actIniFile, ActOptionIniFile: TMyIniFile;
  actSubModIndex, index, i: Integer;
  SubModel: TSubModel;
  // Model: TMod;
  ActOption: TOption;
  OptionIniFileFN: string;
begin
  // Model := getLinkedModel();
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.OptionStrList.indexOf(AdvStringGridOptions.cells[0, aRow]);
  if index >= 0 then
  begin
    ActOption := TOption(SubModel.OptionStrList.objects[index]);
    if ActOption.writeToIniFile then
    begin
      for i := 0 to Lmod.fModel.FIniFiles.count - 1 do
      begin
        actIniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[i]);
        OptionIniFileFN := actIniFile.ReadString
          (Lmod.fModel.Str_SectionName_FileNames,
          Lmod.fModel.Str_SectionTopic_OptionIniFN, '');
        ActOptionIniFile := TMyIniFile.create(OptionIniFileFN, TEncoding.UTF8);
        with ActOptionIniFile, AdvStringGridOptions do
        begin
          WriteString(SubModel.submodname, cells[0, aRow], cells[1, aRow]);
          UpdateFile;
          FreeAndNil(ActOptionIniFile);
        end;
      end;
    end;
    if (aCol = 3) then
      showmessage(ActOption.Comment);

  end;
  ActOptionIniFile.Free
  // UpdateStringGridOptions;
end;

procedure TFormMod.AdvStringGridVarButtonClick(Sender: TObject;
  aCol, aRow: Integer);
var
  actSubModIndex, index: Integer;
  SubModel: TSubModel;
  ActVar: TVar;
begin
  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.VarStrList.indexOf(AdvStringGridVar.cells[0, aRow]);
  if index <> -1 then
  begin
    ActVar := TVar(SubModel.VarStrList.objects[index]);
    showmessage(ActVar.Comment);
  end;
end;

procedure TFormMod.btnSaveDataChangesClick(Sender: TObject);
var
  SubModel: TSubModel;
  row, col, actSubModIndex: Integer;
  f: textFile;
  line: string;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  if (actSubModIndex <> -1) then
  begin
    SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
    // assignFile(f, SubModel.FMeasValues.FileName);
    // rewrite(f);
    AdvStringGridData.SaveToASCII(SubModel.FMeasValues.FName);
    { for row := 0 to AdvStringGridData.RowCount-1 do begin
      for col := 0 to AdvStringGridData.ColCount - 1 do
      write(f, AdvStringGridData.Cells[col, row]+LMod.LinkedModel.Separator);
      writeln(f)
      end;
      closeFile(f); }
    SubModel.init(Lmod.fModel);
  end;
end;

procedure TFormMod.btn1Click(Sender: TObject);
var
  SubModel: TSubModel;
  i,j, actSubModIndex: Integer;
  f: textFile;
  line: string;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  if (actSubModIndex <> -1) then
  begin
    SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
    assignFile(f, SubModel.FMeasValues.FName);
    //AdvStringGridData.SaveColPositionsFMeasValues.FName);
    rewrite(f);
    for i := 0 to AdvStringGridData.RowCount-1 do
    begin
      for j := 0 to AdvStringGridData.ColCount-1 do begin
        write(f, AdvStringGridData.Cells[j,i], ' ');
      end;
      writeln(f);
    end;
    closeFile(f);
    SubModel.init(Lmod.fModel);
  end;
end;

procedure TFormMod.AdvStatToClipBoardButtonClick(Sender: TObject);
begin
  AdvStringGridStat.CopyToClipBoard;
end;

procedure TFormMod.btnAdvStatToClipBoardButton1Click(Sender: TObject);
begin
  AdvStringGridStat.CopyToClipBoard;
end;

procedure TFormMod.AdvStringGridExternVButtonClick(Sender: TObject;
  aCol, aRow: Integer);
var
  actSubModIndex, index: Integer;
  SubModel: TSubModel;
  ActExVar: TExternV;
begin
  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.ExternVStrList.indexOf(AdvStringGridExternV.cells[0, aRow]);
  if index <> -1 then
  begin
    ActExVar := TExternV(SubModel.ExternVStrList.objects[index]);
    showmessage(ActExVar.Comment);
  end;
end;

procedure TFormMod.AdvStringOptionsGetEditorType(Sender: TObject;
  aCol, aRow: Integer; var aEditor: TEditorType);

var
  ActStrLst: TStringList;
  ActOption: TOption;
  actSubModIndex: Integer;
  SubModel: TSubModel;
begin
  if aCol = 1 then
    aEditor := edComboList;
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  if self.AdvStringGridOptions.cells[aCol, aRow] <> '' then
  begin
    ActOption := TOption(SubModel.OptionStrList.objects[aRow - 1]);
    ActStrLst := ActOption.OptionList;
    AdvStringGridOptions.combobox.Items.Assign(ActStrLst);
  end;
end;

procedure TFormMod.AdvStringGridStateCheckBoxClick(Sender: TObject;
  aCol, aRow: Integer; state: Boolean);

const
  ColWriteToFile = 4;
  ColPlot = 5;

begin
  // if checkbox plot is true, checkbox WriteToFile has also be true
  if aCol= ColPlot then begin
     AdvStringGridState.GetCheckBoxState(ColPlot, aRow, state);
     if state = true then
       AdvStringGridState.SetCheckBoxState(ColWriteToFile, aRow, state);
  end;

  // if checkbox write to file is false, checkbox plot has also be false
  if aCol= ColWriteToFile then begin
     AdvStringGridState.GetCheckBoxState(ColWriteToFile,aRow, state);
     if state = false then
       AdvStringGridState.SetCheckBoxState(ColPlot, aRow, state);
  end;

  ButtonSaveStateClick(Sender);
  AdvStringGridState.GotoCell(aCol, min(aRow+1,  self.AdvStringGridState.RowCount-1));
end;

procedure TFormMod.AdvStringGridVarCheckBoxClick(Sender: TObject;
  aCol, aRow: Integer; state: Boolean);

const
  ColWriteToFile = 2;
  ColPlot = 3;

  begin
  // if checkbox plot is true, checkbox WriteToFile has also be true
  if aCol= ColPlot then begin
     AdvStringGridVar.GetCheckBoxState(ColPlot, aRow, state);
     if state = true then
       AdvStringGridVar.SetCheckBoxState(ColWriteToFile, aRow, state);
  end;

  // if checkbox write to file is false, checkbox plot has also be false
  if aCol= ColWriteToFile then begin
     AdvStringGridVar.GetCheckBoxState(ColWriteToFile,aRow, state);
     if state = false then
       AdvStringGridVar.SetCheckBoxState(ColPlot, aRow, state);
  end;

  self.SaveVar();
  AdvStringGridVar.GotoCell(aCol, min(aRow+1,  self.AdvStringGridVar.RowCount-1));
end;

procedure TFormMod.AdvStringGridStatButtonClick(Sender: TObject;
  aCol, aRow: Integer);
var
  ActSubMod: TSubModel;
  ActMeasList: TMeasList;
  ActMeasValue: TMeasValue;
  idx, i: Integer;
  Model: TMod;
  Diagramtitle, lastdatastring, datastring: string;
  Series_Sim, Series_Res: TPointSeries;
  Series_Reg, Series_1_1: TLineSeries;
  actcolor: TColor;
  fn: string;
const
  colorset: array [0 .. 11] of TColor =
  ($00A46744,$00379FF4,$00154DF2,$00A9974E,$006D412B,$00657D1D,$000C08B4,
   $005EC3F3,$009FB75E,$00717171,$008FE9F3,$00B5B5B5) ;

//   (clBlue, clGreen, clRed, clGray,
//    clFuchsia, clTeal, clPurple, clNavy, clLime, clMaroon, clAqua, clOlive);


begin

  if FormShow1_1 = nil then
    FormShow1_1 := TFormShow1_1.create(self);

  FormShow1_1.AdvStringGrid1_1.Clear;
  with FormShow1_1 do
  begin
    try
      Model := Lmod.LinkedModel;
      idx := Model.SubModStrList.indexOf(AdvStringGridStat.cells[0, aRow]);
      ActSubMod := TSubModel(Model.SubModStrList.objects[idx]);
      idx := ActSubMod.DataList.indexOf(AdvStringGridStat.cells[1, aRow]);
      if idx >= 0 then
      begin
        ActMeasList := TMeasList(ActSubMod.DataList.objects[idx]);
        AdvStringGrid1_1.RowCount := ActMeasList.count + 1
      end
      else
        exit;
    except
      exit;
    end;

    datastring := '';
    lastdatastring := '';

    with AdvStringGrid1_1 do
    begin
      cells[0, 0] := 'Date';
      cells[1, 0] := 'Measurement';
      cells[2, 0] := 'Simulation';
      cells[3, 0] := 'Data Set';
    end;

    Series_Sim := TPointSeries.create(Chart1_1);
    Series_Res := TPointSeries.create(ChartResPlot);
    Series_Reg := TLineSeries.create(Chart1_1);
    Series_1_1 := TLineSeries.create(Chart1_1);

    Series_Sim.LinePen.Width := 2;
    Series_Res.LinePen.Width := 2;
    Series_Reg.LinePen.Width := 2;
    Series_1_1.LinePen.Width := 2;

    Chart1_1.RemoveAllSeries;
    Chart1_1.AddSeries(Series_Sim);
    Chart1_1.AddSeries(Series_1_1);
    Chart1_1.AddSeries(Series_Reg);
    ChartResPlot.AddSeries(Series_Res);

    Series_Sim.title := 'Data';
    Series_Reg.title := 'Regression';
    Series_1_1.title := '1_1_Line';
    Series_Res.title := 'Residuals';

    AdvStringGridLegend.Clear;
    AdvStringGridLegend.RowCount := 0;

    actcolor := colorset[0];
    fn := Model.GM_OutPutPath + '\1_1\' + ActMeasList.name + '_1_1.csv';
    FormShow1_1.Edit_1_1_FileName.Text := fn;
    for i := 0 to ActMeasList.count - 1 do
    begin
      ActMeasValue := TMeasValue(ActMeasList.Items[i]);
      lastdatastring := datastring;
      datastring := ActMeasValue.Comment;

      if datastring <> lastdatastring then
      begin
        with AdvStringGridLegend do
        begin
          RowCount := RowCount + 1;
          //ColorPalettes.ApplyPalette( ChartSimResults, 5 );
          actcolor := colorset[RowCount mod Length(colorset)];
          richedit.plaintext := false;
          richedit.font.color := actcolor;
          richedit.font.Style := [fsbold];
          richedit.Text := ActMeasValue.Comment;
          // Richtocell(0, rowindex, AdvStringGridLegend.richedit);
          FontColors[0, RowCount - 1] := actcolor; // myc
          FontStyles[0, RowCount - 1] := FontStyles[2, 3] + [fsbold];
          cells[0, RowCount - 1] := ActMeasValue.Comment;
        end;
      end;

      with ActMeasValue do
      begin

        Series_Sim.addxy(sim, meas, '', actcolor);
        Series_Res.addxy(meas, sim - meas, '', actcolor);
        Series_Reg.addxy(sim, ActMeasList.intercept + ActMeasList.slope * sim,
          '', ClteeColor);
        Series_1_1.addxy(meas, meas, '', ClteeColor);

        with AdvStringGrid1_1 do
        begin
          if CheckBox1.Checked then
            cells[0, i + 1] := datetimetostr(date)
          else
            cells[0, i + 1] := FloatToStr(date);
          cells[1, i + 1] := floattoStrF(meas, ffgeneral, 8, 4);
          cells[2, i + 1] := floattoStrF(sim, ffgeneral, 8, 4);
          cells[3, i + 1] := Comment;
        end;

      end;
    end;

    with ActMeasList do
    begin

      if ActMeasList.slope > 0 then
        Diagramtitle := 'y = ' + floattoStrF(intercept, ffgeneral, 5, 3) + '(' +
          floattoStrF(se_intercept, ffgeneral, 5, 3) + ') + ' +
          floattoStrF(slope, ffgeneral, 5, 3) + '(' + floattoStrF(se_slope,
          ffgeneral, 5, 3) + ') ' + '* x' + ', r2= ' +
          floattoStrF(r2, ffgeneral, 5, 2) + ',  n = ' + IntToStr(count)
      else
        Diagramtitle := 'y = ' + floattoStrF(intercept, ffgeneral, 5, 3) + ' ' +
          floattoStrF(slope, ffgeneral, 5, 3) + '* x';

      with Chart1_1 do
      begin
        title.Text.Clear;
        Legend.LegendStyle := lsSeries;
        title.Text.Add(Diagramtitle);
      end;

      with MemoStatistics.lines do
      begin
        Add('');
        Add('');
        Add(' average meas. value  = ' + floattoStrF(average_meas,
          ffgeneral, 6, 4));
        Add(' average sim. value   = ' + floattoStrF(average_sim,
          ffgeneral, 6, 4));
        Add(' Bias                 = ' + floattoStrF(Bias, ffgeneral, 6, 4));
        Add(' RMSE                 = ' + floattoStrF(RMSE, ffgeneral, 6, 4));
        Add(' Modelling Efficiency = ' + floattoStrF(modellingefficiency,
          ffgeneral, 6, 4));
        Add(' CD                   = ' + floattoStrF(CD, ffgeneral, 6, 4));
        Add('');
        Add(' MSD                = ' + floattoStrF(MSD, ffgeneral, 6, 4) +
          '  Sum of squared deviations');
        Add(' SB                 = ' + floattoStrF(SB, ffgeneral, 6, 4) +
          '  Squared bias');
        Add(' NU                 = ' + floattoStrF(NU, ffgeneral, 6, 4) +
          '  nonunity slope');
        Add(' LC                 = ' + floattoStrF(NU, ffgeneral, 6, 4) +
          '  lack of correlation');
        Add('');
        Add('');
        Add('');
        Add('        Analysis of Variance for linear Regression:');
        Add('       between measured (y) and simulated (x) values');
        Add('');
        Add('   Source |   DF       SSQ         MQ         F          P');
        Add('  ________ ________________________________________________');
        Add('   Model  |  ' + formatfloat('0000', FGmod) + '   ' +
          formatfloat('######0.00', SQmod) + '  ' + formatfloat('######0.00',
          MQmod) + '  ' + floattoStrF(F_value, ffgeneral, 6, 3) + '  ' +
          floattoStrF(prob, ffgeneral, 6, 3));
        Add('   Error  |  ' + formatfloat('0000', FGRest) + '   ' +
          formatfloat('######0.00', SQrest) + '  ' +
          formatfloat('######0.00', MQRest));
        Add('   Total  |  ' + formatfloat('0000', FGges) + '   ' +
          floattoStrF(SQ_y, ffgeneral, 6, 3));
        Add('');
        Add('');
        Add(' r2        = ' + floattoStrF(r2, ffgeneral, 6, 4) + '  (p = ' +
          floattoStrF(prob, ffgeneral, 6, 4) + ')');
        Add(' slope     = ' + floattoStrF(slope, ffgeneral, 6, 4) + ' (' +
          floattoStrF(se_slope, ffgeneral, 6, 4) + ')');
        Add(' intercept = ' + floattoStrF(intercept, ffgeneral, 6, 4) + ' (' +
          floattoStrF(se_intercept, ffgeneral, 6, 4) + ')');
        Add('');
        Add('');
      end;
    end;

    showmodal;
    MemoStatistics.lines.Clear;

    AdvStringGrid1_1.Clear;
    AdvStringGridLegend.Clear;

    Chart1_1.RemoveAllSeries;

    FreeAndNil(Series_Sim);
    FreeAndNil(Series_Reg);
    FreeAndNil(Series_1_1);
    FreeAndNil(Series_Res);
  end;
end;

// ==============================================================================
// CheckBoxen
// ==============================================================================

{procedure TFormMod.CheckBoxContOutputClick(Sender: TObject);
var
  i : integer;
  actIniFile: TMemInifile;
  actIniFN, sec_str, topic_str : string;

begin
  if CheckBoxContOutput.Checked then begin
    Lmod.fModel.ContOutput := True
  end
  else begin
    Lmod.fModel.ContOutput := false
  end;

  Lmod.fModel.FPropIniFile.WriteBool('ModelSettings','ContOutput', Lmod.fModel.ContOutput);
  Lmod.fModel.FPropIniFile.UpdateFile;

  for i := 0 to self.Lmod.fModel.FIniFiles.count - 1 do
  begin
    actIniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[i]);
    actIniFN := actIniFile.FileName;
    sec_str := Lmod.fModel.Str_SectionName_SimOptions;
    topic_str := Lmod.fModel.Str_SectionTopic_ContOutput;
    actIniFile.WriteBool(sec_str, topic_str, Lmod.fModel.ContOutput);
    actIniFile.UpdateFile;
  end;
//  updateForm;
  Lmod.fModel.Init(Lmod.fModel.ActIniFile);
  UpdateStringGridOptions;
end;}

procedure TFormMod.CheckBoxDataDateFormatClick(Sender: TObject);
var
  i: Integer;
begin
  with AdvStringGridData do
  begin
    BeginUpdate;
    for i := 1 to RowCount - 2 do
      if CheckBoxDataDateFormat.Checked then
        cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]))
      else
        cells[0, i + 1] := FloatToStr(strtodate(cells[0, i + 1]));
    AutoSizeColumns(True);
    Endupdate;
  end;
end;

procedure TFormMod.AdvStringGridExternVCheckBoxClick(Sender: TObject;
  aCol, aRow: Integer; state: Boolean);


const
  ColWriteToFile = 4;
  ColPlot = 5;

  begin
  // if checkbox plot is true, checkbox WriteToFile has also be true
  if aCol= ColPlot then begin
     AdvStringGridExternV.GetCheckBoxState(ColPlot, aRow, state);
     if state = true then
       AdvStringGridExternV.SetCheckBoxState(ColWriteToFile, aRow, state);
  end;

  // if checkbox write to file is false, checkbox plot has also be false
  if aCol= ColWriteToFile then begin
     AdvStringGridExternV.GetCheckBoxState(ColWriteToFile,aRow, state);
     if state = false then
       AdvStringGridExternV.SetCheckBoxState(ColPlot, aRow, state);
  end;

  SaveExterns;
//  self.ButtonSaveExVarClick(Sender);
   AdvStringGridExternV.GotoCell(aCol, min(aRow+1,  self.AdvStringGridExternV.RowCount-1));

end;

procedure TFormMod.CheckBoxDateFormatClick(Sender: TObject);
var
  i: Integer;
begin
  with AdvStringGridResults do
  begin
    if CheckBoxDateFormat.Checked then
      for i := 1 to RowCount - 2 do
        cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]))
    else
      for i := 1 to RowCount - 2 do
        cells[0, i + 1] := FloatToStr(strtodate(cells[0, i + 1]));
    AutoSizeColumns(True);
  end;
end;

// ==============================================================================
// Buttons
// ==============================================================================

procedure TFormMod.SpeedButtonFinalvaluesClick(Sender: TObject);
var
  FileName: string;
  ActSubMod: TSubModel;
  Model: TMod;
  actSubModIndex, linendx: Integer;
  f: textFile;
  line: string;
  i, ncol: Integer;
begin
  if FormShowFinalValues = nil then
    application.CreateForm(TFormShowFinalValues, FormShowFinalValues);
  Model := getLinkedModel();
  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);
  ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);

  if ActSubMod <> nil then
  begin
    if self.Lmod.fModel.GM_OutPutPath <> '' then
      FileName := ActSubMod.fn_finalstate;
    if FileExists(FileName) then
    begin
      FormShowFinalValues.EditFinalValuesFileName.Text := FileName;
      assignFile(f, FileName);
      reset(f);
      linendx := 0;
      repeat
        readln(f, line);
        { if (linendx > 1) and (linendx <= Model.IniFileNames.count + 1) then
          line := Extractfilename(Model.IniFileNames.Strings[linendx - 2])
          + ',' + line
          else
          line := ',' + line; }
        ncol := 1;
        for i := 1 to Length(line) do
          if line[i] = Model.separator then
            inc(ncol);
        with FormShowFinalValues.AdvStringGrid1 do
        begin
          RowCount := linendx + 1;
          ColCount := ncol;
          Rows[linendx].commatext := line;
        end;
        inc(linendx);
      until eof(f);
    end;
  end;
  FormShowFinalValues.show;
end;

procedure TFormMod.ButtonSaveExVarClick(Sender: TObject);

var
  ActExVar: TExternV;
  ActExVarStr: string;
  i, actSubModIndex, ExVarNdx: Integer;
  SubModel: TSubModel;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  SubModel.ExternVStrList.sorted := false;
  for i := 0 to SubModel.ExternVStrList.count - 1 do
    SubModel.ExternVStrList[i] :=
      TExternV(SubModel.ExternVStrList.objects[i]).name;
  SubModel.ExternVStrList.sort;
  SubModel.ExternVStrList.CaseSensitive := false;
  for i := 1 to AdvStringGridExternV.RowCount - 1 do
  begin
    ActExVarStr := AdvStringGridExternV.cells[0, i];
    ExVarNdx := SubModel.ExternVStrList.indexOf(ActExVarStr);
    if ExVarNdx <> -1 then
    begin
      ActExVar := TExternV(SubModel.ExternVStrList.objects[ExVarNdx]);
      AdvStringGridExternV.GetCheckBoxState(5, i, ActExVar.writeToFile);
      AdvStringGridExternV.GetCheckBoxState(6, i, ActExVar.PlotToGraph);
      if not ActExVar.writeToFile then
        AdvStringGridExternV.GetCheckBoxState(6, i, ActExVar.writeToFile);
    end;
  end;
  UpdateStringGridExternV;
  updatePropIniFile(SubModel.ExternVStrList, SubModel.name);
end;

procedure TFormMod.Button1Click(Sender: TObject);
begin
  if self.Lmod.LinkedModel <> nil then
    Lmod.LinkedModel.InitAllExternV;
end;

procedure TFormMod.SpeedButtonIncFontSizeClick(Sender: TObject);
begin
  ChartSimResults.BottomAxis.LabelsFont.Size := ChartSimResults.BottomAxis.LabelsFont.Size + 1;
  ChartSimResults.LeftAxis.LabelsFont.Size := ChartSimResults.LeftAxis.LabelsFont.Size + 1;
  ChartSimResults.Legend.font.Size := ChartSimResults.Legend.font.Size + 1;
  ChartSimResults.Repaint;
end;

procedure TFormMod.SpeedButtonInsRowClick(Sender: TObject);
begin
  AdvStringGridData.InsertRows(AdvStringGridData.row, 1);
end;

procedure TFormMod.SpeedButtonMergeDataClick(Sender: TObject);

var
  i, j, k, lines, actSubModIndex: Integer;
  fn, w_fn, w_str, t_fn, actIniFN, fn_meas: string;
  AllData, actfile: textFile;
  FMeasValues: TTextFileH;
  NewLine: string;
  Model: TMod;
  SubMod: TSubModel;
  actIniFile: TMyIniFile;
  ActData: TStringList;
  rep: Boolean;

begin
  ActData := TStringList.create;
  Model := Lmod.fModel;
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  if actSubModIndex <> -1 then
    SubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
  fn := Model.GM_OutPutPath + '\' + SubMod.name + '_allData.dat';
  assignFile(AllData, fn);
  rewrite(AllData);
  rep := false;
  writeln(AllData, 'Inifile,', SubMod.FMeasValues.fFirstLine.commatext);
  writeln(AllData, '[],', SubMod.FMeasValues.UnitLine.commatext);
  for j := 0 to Model.FIniFiles.count - 1 do
  begin
    actIniFile := TMyIniFile(Model.FIniFiles.objects[j]);
    actIniFN := actIniFile.FileName;
    Model.init(actIniFile);
    Model.actIniFile.UpdateFile;
    fn_meas := actIniFile.ReadString(Model.Str_SectionName_MeasurementFiles,
      SubMod.name, '');
    FMeasValues := TTextFileH.create;
    FMeasValues.init(fn_meas);
    FMeasValues.GoTop;
    for k := 0 to FMeasValues.fn_Line - 1 do
    begin
      NewLine := FMeasValues.slFile[k + 2];
      writeln(AllData, actIniFN, ',', NewLine);
    end;
    { w_str := Model.Str_SectionTopic_WeatherFileFN;
      w_FN := actIniFile.ReadString(Model.Str_SectionName_FileNames, w_str,'');
      ActWeather.LoadFromFile(w_FN);
      if rep = false then begin
      NewLine := DelDoubleSpaces(ActWeather.Strings[0]);
      NewLine := StringReplace(NewLine, ' ', Model.separator,
      [rfReplaceAll, rfIgnoreCase]);
      NewLine := 'IniFile'+Model.Separator+'WeatherFile'+Model.Separator+NewLine;
      writeln(AllData, NewLine);
      for lines := 2 to ActWeather.Count - 1 do begin
      NewLine := DelDoubleSpaces(ActWeather.Strings[lines]);
      NewLine := StringReplace(NewLine, ' ', Model.separator,
      [rfReplaceAll, rfIgnoreCase]);
      NewLine := ActInifn+ Model.Separator+w_fn+Model.Separator+NewLine;
      writeln(AllData, NewLine);
      rep := true;
      end;
      end else begin
      for lines := 2 to ActWeather.Count - 1 do begin
      NewLine := DelDoubleSpaces(ActWeather.Strings[lines]);
      NewLine := StringReplace(NewLine, ' ', Model.separator,
      [rfReplaceAll, rfIgnoreCase]) ;
      NewLine := ActInifn+ Model.Separator+w_fn+Model.Separator+NewLine;
      writeln(AllData, NewLine);
      end;
      end; }

  end;
  closeFile(AllData);
end;

procedure TFormMod.Info1Click(Sender: TObject);
begin
  // Application.CreateForm(TFormHumeshow, FormHumeShow);
  // FormHumeShow.showmodal;
  // FormHumeShow.free;
  MessageBox(0,
    'HUME: AN OBJECT ORIENTED COMPONENT LIBRARY FOR GENERIC MODULAR MODELLING OF DYNAMIC SYSTEMS '
    + #13 + #10 + '' + #13 + #10 + 'H. Kage' + #13 + #10 + '' + #13 + #10 +
    'Any model based on this library consists of one main model ' + #13 + #10 +
    'module, implemented in a class called ‘Tmod’ and a number ' + #13 + #10 +
    'of sub-models. The main model is responsible for the control ' + #13 + #10
    + 'of the simulation, single or multiple runs, and also implements ' + #13 +
    #10 + 'methods like calculating basic statistics and parameter ' + #13 + #10
    + 'estimation based on the Levenberg-Marquardt method. ' + #13 + #10 +
    'All sub-models have to be derived from the base class ' + #13 + #10 +
    '‘TsubMod’ which contains dynamic lists of state variables, ' + #13 + #10 +
    'variables, parameters and ‘external values’, i.e. values ' + #13 + #10 +
    'needed from outside the sub-model. The information' + #13 + #10 +
    'exchange between the sub-models through ‘external values’ ' + #13 + #10 +
    'is flexible, since it is simply based on string identities between ' + #13
    + #10 + 'the information needed and information located in any other ' + #13
    + #10 + 'submodel or input file. This technique allows exchange of ' + #13 +
    #10 + 'sub-models through ‘drag and drop’ without any changes in ' + #13 +
    #10 + 'the source code even for a changing number and order of ' + #13 + #10
    + 'parameters, as long as the necessary input parameters to the ' + #13 +
    #10 + 'sub-model can be found anywhere else in the model. ' + #13 + #10 +
    'A graphical user interface based on the general data structure ' + #13 +
    #10 + 'supports control of parameter values, initial values and allows ' +
    #13 + #10 + 'input of measured data. ' + #13 + #10 + '' + #13 + #10 +
    'Based on these fundamental classes a component hierarchy ' + #13 + #10 +
    'has been and is still further developed, including several ' + #13 + #10 +
    'components for dry matter production, plant development, ' + #13 + #10 +
    'dry matter partitioning, root growth of plants as well as ' + #13 + #10 +
    'modules for soil water and soil nitrogen budget.', '',
    MB_ICONQUESTION or MB_OK);
end;

procedure TFormMod.btnButtonChangeControlFileClick(Sender: TObject);
var
  act_IniFn, NewCtrlFN: string;
  NewInifile: TMyIniFile;
  index: Integer;
//  ControlFile : TextFile;
  ControlFile : TStreamReader;


begin
  with OpenDialog1 do
  begin
    title := 'Open Control File';
    DefaultExt := 'fn';
    Filter := 'Conrolfiles (*.fn)|*.fn';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if not DirectoryExists(InitialDir) then
      InitialDir := ExtractFileDir(Lmod.fModel.Get_ControlFileFn);

    if Execute then
    begin
      NewCtrlFN := FileName;
      Lmod.fModel.Set_ControlFileFN(NewCtrlFN);
      self.EditControlFile.Text := NewCtrlFN;
      Lmod.fModel.FPropIniFile.WriteString('Files', 'ControlFile', NewCtrlFN);
      Lmod.fModel.FPropIniFile.UpdateFile;
      ControlFile := TStreamReader.Create(NewCtrlFN, TEncoding.UTF8);
    //  assignFile(ControlFile, NewCtrlFN);
    //  reset(ControlFile);
      Lmod.fModel.FIniFiles := TStringList.create;
      index := 0;
      while not ControlFile.EndOfStream do
      begin
        act_IniFn := ControlFile.ReadLine;
      //        readln(ControlFile, act_IniFn);
        if trim(act_IniFn) = '' then
          continue;
        if trim(act_IniFn)[1] = '#' then
          continue;
        if FileExists(act_IniFn) then
        begin
          NewInifile := TMyIniFile.create(act_IniFn, TEncoding.UTF8);
          NewInifile.UpdateFile;
          Lmod.fModel.FIniFiles.Add(NewInifile.FileName);
          Lmod.fModel.FIniFiles.objects[index] := NewInifile;
          inc(index);
        end
        else
          MessageDlg('IniFile ' + act_IniFn + ' does not exist !',
            mtInformation, [mbOK], 0);
      end;
      Lmod.fModel.actIniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[0]);
      Lmod.fModel.init(Lmod.fModel.actIniFile);
      //self.ComboBoxIniFile
      self.updateForm;
      ControlFile.Free;
    end;
  end;
  // NewIniFile.Free;
end;

procedure TFormMod.SpeedButtonChangeStateIniFileClick(Sender: TObject);
begin
  ChangeStateIniFile;
end;

procedure TFormMod.SpeedChangeParamIniFileClick(Sender: TObject);
begin
  SpeedButtonChangeParamIniFileClick(self);
end;

procedure TFormMod.SpeedButtonChangeSTageFileNameClick(Sender: TObject);
begin
  ChangeStateIniFile;
end;

function TFormMod.SaveTo(title, keyname: string;
  EditFileName, EditIniFileName: TEdit): Boolean;
var
  NewIniFName: string;
  res: Integer;
begin
  Result := false;
  with SaveDialog1, Lmod.fModel do
  begin
    title := title;
    DefaultExt := 'ini';
    Filter := 'IniFiles (*.ini)|*.ini';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then
    begin
      NewIniFName := ChangeFileExt(FileName, '.ini');
      if FileExists(NewIniFName) then
      begin
        res := application.MessageBox('Overwrite?', '', MB_OKCANCEL);
        if (res = IDOK) or (not FileExists(NewIniFName)) then
        begin
          EditFileName.Text := NewIniFName;
          EditIniFileName.Text := NewIniFName;
          actIniFile.WriteString('FileNames', keyname, NewIniFName);
          actIniFile.UpdateFile;
          init(Lmod.fModel.actIniFile);
          InitAllSubMods;
          Result := True;
        end;
      end;
    end;
  end;

end;

procedure TFormMod.BitBtnSaveStateToClick(Sender: TObject);
begin
  if SaveTo('New StateIniFile', 'StateIniFN', EditStateFileName,
    EditStateIniFileName) then
  begin
    SaveState;
    UpdateStringGridState;
  end;
end;

procedure TFormMod.btnAdvStatToClipBoardButtonClick(Sender: TObject);
begin
  AdvStringGridStat.CopyToClipBoard;
end;

procedure TFormMod.BitBtnSaveParamToClick(Sender: TObject);
begin
  if SaveTo('New ParamIniFile', 'ParamIniFN', EditStateFileName,
    EditStateIniFileName) then
  begin
    SaveParams;
    UpdateStringGridParam;
  end;
end;

procedure TFormMod.changeIni(titlestr, keyname: string;
  EditFileName, EditIniFileName: TEdit);
var
  NewIniFName: string;
begin
  with SaveDialog1, Lmod.fModel.actIniFile do
  begin
    title := titlestr;
    DefaultExt := 'ini';
    Filter := 'IniFiles (*.ini)|*.ini';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then
    begin
      NewIniFName := ChangeFileExt(FileName, '.ini');
      EditFileName.Text := NewIniFName;
      EditIniFileName.Text := NewIniFName;
      WriteString('FileNames', keyname, NewIniFName);
      UpdateFile;
    end;
  end;
  updateForm;
end;

procedure TFormMod.SpeedButtonDecFontSizeClick(Sender: TObject);
begin
  ChartSimResults.BottomAxis.LabelsFont.Size := ChartSimResults.BottomAxis.LabelsFont.Size - 1;
  ChartSimResults.LeftAxis.LabelsFont.Size := ChartSimResults.LeftAxis.LabelsFont.Size - 1;
  ChartSimResults.Legend.font.Size := ChartSimResults.Legend.font.Size - 1;
  ChartSimResults.Repaint;
end;

procedure TFormMod.SpeedButtonDelRowClick(Sender: TObject);

begin
  AdvStringGridData.RemoveSelectedRows;
end;

procedure SetToNoOutput(var strList: TStringList);

var
  i: Integer;
  entity: THumeNumEntity;
begin
  for i := 0 to strList.count - 1 do
  begin
    entity := THumeNumEntity(strList.objects[i]);
    with entity do
    begin
      // if not PlotToGraph then
      writeToFile := false;
      PlotToGraph := false;
    end;
  end;
end;



procedure SetToOutput(var strList: TStringList);

var
  i: Integer;
  entity: THumeNumEntity;
begin
  for i := 0 to strList.count - 1 do
  begin
    entity := THumeNumEntity(strList.objects[i]);
    with entity do
    begin
      writeToFile := true;
      PlotToGraph := true;
    end;
  end;
end;

procedure TFormMod.SpeedButtonNoContOutputClick(Sender: TObject);

var
  i: Integer;
  ActSubMod: TSubModel;

begin
  for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
  begin
    ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
    with ActSubMod do
    begin
      ActSubMod.OptContOutput := false;
//      ActSubMod.OptionIniF.WriteString(ActSubMod, 'ContOutput', 'false');
      SetToNoOutput(stateStrList);
      updatePropIniFile(stateStrList, ActSubMod.name);
      SetToNoOutput(VarStrList);
      updatePropIniFile(VarStrList, ActSubMod.name);
      SetToNoOutput(ExternVStrList);
      updatePropIniFile(ExternVStrList, ActSubMod.name);
      // SetToNoOutput(ParStrList);
      // updatePropIniFile(ParStrList, ActSubMod.Name);
    end;
  end;
  self.Lmod.fModel.init(Lmod.fModel.ActIniFile);
  self.Lmod.fModel.FPropIniFile.UpdateFile;
  self.UpdateStringGridOptions;
end;

procedure TFormMod.SpeedButtonAllContOutputClick(Sender: TObject);

var
  i: Integer;
  ActSubMod: TSubModel;

begin
  for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
  begin
    ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
    with ActSubMod do
    begin
      ActSubMod.OptContOutput := true;
      SetToOutput(stateStrList);
      updatePropIniFile(stateStrList, ActSubMod.name);
      SetToOutput(VarStrList);
      updatePropIniFile(VarStrList, ActSubMod.name);
      SetToOutput(ExternVStrList);
      updatePropIniFile(ExternVStrList, ActSubMod.name);
      // SetToNoOutput(ParStrList);
      // updatePropIniFile(ParStrList, ActSubMod.Name);
    end;
  end;
  self.Lmod.fModel.init(Lmod.fModel.ActIniFile);
  self.Lmod.fModel.FPropIniFile.UpdateFile;
  self.UpdateStringGridOptions;
end;

procedure TFormMod.SpeedButtonChangeParamIniFileClick(Sender: TObject);
begin
  changeIni('New ParamIniFile', 'ParamIniFN', EditParamFileName,
    EditParamIniFileName);
end;

procedure TFormMod.ChangeStateIniFile;
begin
  changeIni('New StateIniFile', 'StateIniFN', EditStateFileName,
    EditStateIniFileName);
end;

procedure TFormMod.SpeedButtonChangeWeatherFileClick(Sender: TObject);
var
  NewWeatherFName: string;
begin
  with SaveDialog1, Lmod.fModel.actIniFile do
  begin
    title := 'New WeatherFile';
    Filter := 'All Files (*.*)|*.*';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then
    begin
      NewWeatherFName := SaveDialog1.FileName;
      EditWeatherfile.Text := NewWeatherFName;
      WriteString('FileNames', 'WeatherFileFN', NewWeatherFName);
      UpdateFile;
    end;
  end;

end;

procedure TFormMod.SpeedButtonCreateDocuClick(Sender: TObject);
begin
  self.Lmod.fModel.write_documentation;
  self.EditDokuFilename.Text := Lmod.fModel.Docu_fn2;
  self.MemoModelDocu.lines.loadfromfile(Lmod.fModel.Docu_fn);
  AdvStringGridModelSummary.LoadFromCSV(Lmod.fModel.Docu_fn2);
  // .LoadFromFile();
end;

// ==============================================================================
// PageControl Änderungen
// ==============================================================================

procedure TFormMod.ViewVariables1Click(Sender: TObject);
begin
  PageControl.ActivePage := self.TabSheetVariables;
end;

procedure TFormMod.EditExternals1Click(Sender: TObject);
begin
  PageControl.ActivePage := self.TabSheetExternalValues;
end;

procedure TFormMod.EditOptions1Click(Sender: TObject);
begin
  PageControl.ActivePage := self.TabSheetOptions;
end;

procedure TFormMod.Statistics1Click(Sender: TObject);
begin
  PageControl.ActivePage := self.TabSheetStat;
end;

procedure TFormMod.ViewTabelleClick(Sender: TObject);
begin
  PageControl.ActivePage := TabSheetResultTab;
end;

procedure TFormMod.MenuEditStateClick(Sender: TObject);
begin
  self.PageControl.ActivePage := self.TabSheetState;
end;

procedure TFormMod.MenuInitParamsClick(Sender: TObject);
begin
  self.PageControl.ActivePage := self.TabSheetParameter;
end;

procedure TFormMod.PageControlChange(Sender: TObject);
begin

  if self.PageControl.ActivePage = self.TabSheetResultTab then
    self.UpdatePageResultTab;
  if self.PageControl.ActivePage = self.TabSheetGraphResult then
    self.UpdatePageGraphResult;
  if self.PageControl.ActivePage = self.TabSheetState then
    UpdateStringGridState();
  if self.PageControl.ActivePage = self.TabSheetOptions then
    UpdateStringGridOptions();
  if self.PageControl.ActivePage = self.TabSheetParameter then
    UpdateStringGridParam;
  if self.PageControl.ActivePage = self.TabSheetExternalValues then
    UpdateStringGridExternV;

end;


// ==============================================================================
// Sonstiges
// ==============================================================================



procedure TFormMod.updateForm();
var
  i: Integer;
  ActSubMod: TSubModel;

begin

  if Lmod.fModel <> NIL then
  begin

    Lmod.fModel.InitAllSubMods; // TODO ???


    Lmod.fModel.Get_ControlFileFn;

    ComboBoxIniFile.Clear;

    for i := 0 to Lmod.fModel.FIniFiles.count - 1 do
    begin
      ComboBoxIniFile.Items.Add(Lmod.fModel.FIniFiles.Strings[i]);
    end;
    ComboBoxIniFile.ItemIndex := 0;
    ComboBoxSubMod.Clear;

    for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
    begin
      ComboBoxSubMod.Items.Add(Lmod.fModel.SubModStrList.Strings[i]);
    end;


   ComboBoxSubMod.ItemIndex := self.Lmod.fModel.FPropInifile.ReadInteger('ComboBoxes', ComboBoxSubMod.Name, 1);

    if Lmod.fModel.weatherfile <> nil then
      EditWeatherfile.Text := Lmod.fModel.weatherfile.FName
    else
      EditWeatherfile.Text := 'File not specified';

    // gespeicherte Properties aus *ini Datei einlesen
    for i := 0 to Lmod.fModel.SubModStrList.count - 1 do
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[i]);
      with ActSubMod do
      begin
        Lmod.fModel.setPropFromIniFile(stateStrList, Name);
        Lmod.fModel.setPropFromIniFile(VarStrList, Name);
        Lmod.fModel.setPropFromIniFile(ExternVStrList, Name);
      end;
    end;

    UpdateStringGridParam;
    UpdateStringGridState;
    UpdateStringGridVar;
    UpdateStringGridExternV;
    UpdateStringGridOptions;
    UpdateStringGridData;
    UpdatePageIntegration;

    if FileExists(Lmod.fModel.reg_fn) then
      update_StringGrid(Lmod.fModel.reg_fn);

    UpdatePageResultTab;
    UpdatePageGraphResult;
    ComboBoxIniFile.hint := ComboBoxIniFile.Items[ComboBoxIniFile.ItemIndex];
 //   SpeedButtonFinalvalues.visible := Lmod.fModel.FinalOutput;
  end
  else
  begin
    // showMessage('TMod instance not linked to Modlink Component!');
    // halt;
  end;
end;

{ procedure TFormMod.ConnectionPaint(Sender: TObject);
  var
  i: Integer;
  actsubmod: TSubmodel;
  actplant: TAbstractPlant;
  begin
  for i := 0 to LMod.fModel.SubModStrList.count - 1 do begin
  ActSubMod := TSubModel(LMod.fModel.SubModStrList.objects[i]);
  if (ActSubMod is TAbstractPlant) then begin
  actplant := TAbstractPlant(actsubmod);

  if actplant.NextCrop <> nil then begin
  UVisualization.drawArrow(paintbox.canvas, actplant,
  actplant.NextCrop,
  clGreen, psSolid);
  end;

  if actplant.SoilLayerMod <> nil then begin
  UVisualization.drawline(paintbox.canvas, actplant,
  actplant.SoilLayerMod,
  clMaroon, psDot);
  end;

  if actplant.SoilMinMOd <> nil then begin
  UVisualization.drawLine(paintbox.canvas, actplant,
  actplant.SoilMinMOd,
  clGray, psDot);
  end;

  if actplant.EvapModel <> nil then begin
  UVisualization.drawLine(paintbox.canvas, actplant,
  actplant.EvapModel,
  clNavy, psDot);
  end;
  end;
  end;
  end; }

procedure TFormMod.FormShow(Sender: TObject);
begin
  updateForm();
  AdvStringGridParam.MouseActions.SizeFixedCol := True;
  AdvStringGridState.MouseActions.SizeFixedCol := True;
  AdvStringGridData.MouseActions.SizeFixedCol := True;
  AdvStringGridResults.MouseActions.SizeFixedCol := True;
  AdvStringGridVar.MouseActions.SizeFixedCol := True;
  AdvStringGridOptions.MouseActions.SizeFixedCol := True;
  AdvStringGridExternV.MouseActions.SizeFixedCol := True;

  // TabSheetModelDiagram

//  paintbox := TPaintBox.create(self);
//  paintbox.Parent := self.TabSheetModelDiagram;
//  paintbox.align := alClient;
  // paintbox.OnPaint := ConnectionPaint;
  // paintbox.Visible := True;
  // paintbox.Show;

end;

procedure TFormMod.ShowDataFile(FFileName: string);
var
  i: Integer;
begin
  if not FileIsEmpty(FFileName) then
  begin
    with AdvStringGridResults do
    begin
      BeginUpdate;
      FixedRows := 2;
      FixedCols := 1;
      LoadFromCSV(FFileName);
      if CheckBoxDataDateFormat.Checked then
        for i := 1 to RowCount - 1 do
          cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]));
      Endupdate;
    end;
  end;
end;

procedure TFormMod.TabSheetResultTabEnter(Sender: TObject);
begin
  UpdatePageResultTab;
end;

procedure TFormMod.TabSheetResultTabShow(Sender: TObject);
begin
  UpdatePageResultTab;
end;

procedure TFormMod.TabSheetStateShow(Sender: TObject);
begin
  AdvStringGridState.LoadColPositions;
  UpdateStringGridState;
end;

procedure TFormMod.TabSheetVariablesShow(Sender: TObject);
begin
  UpdateStringGridVar;
end;

procedure TFormMod.PrintButtonClick(Sender: TObject);
begin
  if PrintDialog1.Execute then
    ChartSimResults.PrintLandscape;
end;

procedure TFormMod.SensitivityAnalysisClick(Sender: TObject);
begin
  if FormSensOpt = nil then
    application.CreateForm(TFormSensOpt, FormSensOpt);
  FormSensOpt.Model := Lmod.fModel;
  FormSensOpt.FPropIniFile := self.Lmod.fModel.FPropIniFile;
  FormSensOpt.FormActivate;
  FormSensOpt.showmodal;
end;

procedure TFormMod.EditStartTimeChange(Sender: TObject);
begin
  inherited;
  if DateTimePickerStart.date < Lmod.fModel.FirstWeatherData then
    EditStartTime.font.color := clRed
  else
    EditStartTime.font.color := clBlack;

  DateTimePickerStart.date := StrToINt(EditStartTime.Text);
end;

procedure TFormMod.EditEndTimeChange(Sender: TObject);
begin
  inherited;
  if StrToINt(EditEndTime.Text) > Lmod.fModel.LastWeatherData then
    EditEndTime.font.color := clRed
  else
    EditEndTime.font.color := clBlack;

  EndTimePicker.date := StrToINt(EditEndTime.Text);
end;

procedure TFormMod.StartTimePickerChange(Sender: TObject);
begin
  inherited;
  EditStartTime.Text := FloatToStr(TRUNC(DateTimePickerStart.date));
end;

procedure TFormMod.EndTimePickerChange(Sender: TObject);
begin
  inherited;
  EditEndTime.Text := FloatToStr(TRUNC(EndTimePicker.date));
end;

procedure TFormMod.TabSheetDataShow(Sender: TObject);
begin
  UpdateStringGridData;
end;

procedure TFormMod.TabSheetExternalValuesShow(Sender: TObject);
begin
  UpdateStringGridExternV;
end;

procedure TFormMod.TabSheetGraphResultEnter(Sender: TObject);
begin
  UpdatePageGraphResult;
end;

procedure TFormMod.TabSheetGraphResultShow(Sender: TObject);
begin
  UpdatePageGraphResult;
end;

procedure TFormMod.TabSheetOptionsShow(Sender: TObject);
begin
  self.UpdateStringGridOptions;
end;

procedure TFormMod.TabSheetParameterShow(Sender: TObject);
begin
  UpdateStringGridParam;
end;

procedure TFormMod.SpeedButtonOpenDataFileClick(Sender: TObject);
var
  IniFile: TMyIniFile;
  actInifileIndex, actSubModIndex: Integer;
  SubModel: TSubModel;
  NewDataFName: string;
begin
  with SaveDialog1 do
  begin
    title := 'New DataFile';
    Filter := 'All Files (*.*)|*.*';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then
    begin
      NewDataFName := FileName;
      EditDataFileName.Text := NewDataFName;
      actInifileIndex := ComboBoxIniFile.ItemIndex;
      actSubModIndex := ComboBoxSubMod.ItemIndex;
      IniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[actInifileIndex]);
      SubModel := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      IniFile.WriteString('MeasurementFiles', SubModel.name, NewDataFName);
      IniFile.UpdateFile;
      Lmod.fModel.init(Lmod.fModel.actIniFile);
      Lmod.fModel.InitAllSubMods;
      UpdateStringGridData;
    end;
  end;
end;

procedure TFormMod.SpeedButtonOutputDirectoryClick(Sender: TObject);

var
  fn, SectionName, SectionTopic, SelectedFolder: string;
  i: Integer;
  actIni: TMyIniFile;
  OpenDialog: TFileOpenDialog;
begin
  OpenDialog := TFileOpenDialog.create(nil);
  try
    OpenDialog.Options := OpenDialog.Options + [fdoPickFolders];
    if not OpenDialog.Execute then
      Abort;
    SelectedFolder := OpenDialog.FileName;
  finally
    OpenDialog.Free;
  end;

  showmessage(SelectedFolder);
  EditOutputDirectory.Text := SelectedFolder;
  Lmod.LinkedModel.GM_OutPutPath := SelectedFolder;
  for i := 0 to Lmod.LinkedModel.IniFileNames.count - 1 do
  begin
    fn := Lmod.LinkedModel.IniFileNames.Strings[i];
    actIni := TMyIniFile.create(fn, TEncoding.UTF8);
    SectionName := Lmod.LinkedModel.Str_SectionName_FileNames;
    SectionTopic := Lmod.LinkedModel.Str_SectionTopic_OutputDir;
    actIni.WriteString(SectionName, SectionTopic, SelectedFolder);
    actIni.UpdateFile;
  end;

  { with SaveDialog1 do begin
    title := 'OutputDirectory';
    Filter := 'All Files (*.*)|*.*';
    Options := Options + [fdoPickFolders];
    if Execute then begin
    NewDirectory := ExtractFilePath(SaveDialog1.FileName);
    LMod.LinkedModel.GM_OutPutPath := ExtractFilePath(SaveDialog1.FileName);
    EditOutputDirectory.Text := NewDirectory;
    //      WriteString('FileNames', 'WeatherFileFN', NewWeatherFName);
    //UpdateFile;
    end;
    end; }

end;

procedure TFormMod.EditParamIniFileNameMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  begin
    inherited;
    EditParamIniFileName.hint := EditParamIniFileName.Text;
    EditParamIniFileName.ShowHint := True;
    EditParamIniFileName.Repaint;
  end;

end;

procedure TFormMod.LabelActIniFileDescMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  LabelActIniFileDesc.hint := ComboBoxIniFile.Items[ComboBoxIniFile.ItemIndex];
  LabelActIniFileDesc.ShowHint := True;
  LabelActIniFileDesc.Repaint;
end;

procedure TFormMod.EditStateIniFileNameMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  EditStateIniFileName.hint := EditStateIniFileName.Text;
  EditStateIniFileName.ShowHint := True;
  EditStateIniFileName.Repaint;
end;

procedure TFormMod.EditWeatherfileMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  EditWeatherfile.hint := EditWeatherfile.Text;
  EditWeatherfile.ShowHint := True;
  EditWeatherfile.Repaint;
end;

procedure TFormMod.ChisquareAnalysisClick(Sender: TObject);
begin
  if FormChiSqOpt = nil then
    application.CreateForm(TFormChiSqOpt, FormChiSqOpt);
  FormChiSqOpt.Model := Lmod.fModel;
  FormChiSqOpt.FormActivate;
  FormChiSqOpt.showmodal;
end;

procedure TFormMod.GAOptClic(Sender: TObject);
begin
  if FormGAopt = nil then
    application.CreateForm(TFormGAOpt, FormGAopt);
  FormGAopt.sga.Model := Lmod.fModel;
  // FormGAOpt.sga.set_model(LMod.fModel);

  FormGAopt.FormGAActivate;
  { FormOpt.Update;
    StatusBarMain.Panels.Items[0].Text := 'Optimizing';
    StatusBarMain.show;
    MenuView.Enabled := true;
    StatusBarMain.Panels.Items[0].Text := '';
    UpdateStringGridParam; }
  FormGAopt.show;
end;

procedure TFormMod.ViewGraphClick(Sender: TObject);
begin
  inc(nFormGraph);
  if nFormGraph <= 10 then
  begin
    application.CreateForm(TFormGraph, FormGraphArray[nFormGraph]);
    FormGraphArray[nFormGraph].show;
  end
  else
    showmessage('Mehr als 10 Graph-Fenster geöffnet');
end;

procedure TFormMod.OptimizeClick(Sender: TObject);
begin
  if FormOpt = nil then
    application.CreateForm(TFormOpt, FormOpt);
  Lmod.fModel.InitAllDataSeries;
  FormOpt.Model := Lmod.fModel;
  FormOpt.FormActivate;
  FormOpt.Update;
  StatusBarMain.Panels.Items[0].Text := 'Optimizing';
  StatusBarMain.show;
  FormOpt.showmodal;
  MenuView.Enabled := True;
  StatusBarMain.Panels.Items[0].Text := '';
  UpdateStringGridParam;
end;

function TFormMod.getLinkedModel(): TMod;
begin
  Result := nil;
  if Lmod.LinkedModel <> nil then
    Result := Lmod.LinkedModel
  else
  begin
    showmessage('LMod.LinkedModel darf nicht undefiniert sein!');
    exit;
  end;
end;

procedure TFormMod.testSubModIndex(n: Integer);
begin
  if n < 0 then
  begin
    showmessage('Kein aktives Submodel gefunden!');
    exit;
  end;
end;



procedure TFormMod.ToggleSwitchExternContOutputClick(Sender: TObject);

var
  onState : boolean;
  i, actSubModIndex: Integer;
  ActSubMod: TSubModel;

begin
 if ToggleSwitchExternContOutput.state = tssOn then
  begin
    ToggleSwitchExternContOutput.ThumbColor := $008000; // clYellowgreen;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      with ActSubMod do
      begin
        SetToOutput(ExternVStrList);
        UpdateStringGridExternV;
        updatePropIniFile(ExternVStrList, ActSubMod.Name);
      end;
    end;
  end
  else
  begin
    ToggleSwitchExternContOutput.ThumbColor := $0000FF;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      with ActSubMod do
      begin
        SetToNoOutput(ExternVStrList);
        UpdateStringGridExternV;
        updatePropIniFile(ExternVStrList, ActSubMod.Name);
      end;
    end;
    self.Lmod.fModel.init(Lmod.fModel.actIniFile);
    self.Lmod.fModel.FPropIniFile.UpdateFile;
  end;

end;

procedure TFormMod.ToggleSwitchStateContOutputClick(Sender: TObject);

var
  onState : boolean;
  i, actSubModIndex: Integer;
  ActSubMod: TSubModel;

begin
 if ToggleSwitchStateContOutput.state = tssOn then
  begin
    ToggleSwitchStateContOutput.ThumbColor := $008000; // clYellowgreen;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      with ActSubMod do
      begin
        SetToOutput(StateStrList);
        UpdateStringGridState;
        updatePropIniFile(StateStrList, ActSubMod.Name);
      end;
    end;
  end
  else
  begin
    ToggleSwitchStateContOutput.ThumbColor := $0000FF;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      with ActSubMod do
      begin
        SetToNoOutput(StateStrList);
        UpdateStringGridState;
        updatePropIniFile(StateStrList, ActSubMod.Name);
      end;
    end;
    self.Lmod.fModel.init(Lmod.fModel.actIniFile);
    self.Lmod.fModel.FPropIniFile.UpdateFile;
  end;
end;



procedure TFormMod.ToggleSwitchVarContOutputClick(Sender: TObject);

var
  onState : boolean;
  i, actSubModIndex: Integer;
  ActSubMod: TSubModel;

begin
 if ToggleSwitchVarContOutput.state = tssOn then
  begin
    ToggleSwitchVarContOutput.ThumbColor := $008000; // clYellowgreen;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      with ActSubMod do
      begin
        SetToOutput(VarStrList);
        UpdateStringGridVar;
        updatePropIniFile(VarStrList, ActSubMod.Name);
      end;
    end;
  end
  else
  begin
    ToggleSwitchVarContOutput.ThumbColor := $0000FF;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then
    begin
      ActSubMod := TSubModel(Lmod.fModel.SubModStrList.objects[actSubModIndex]);
      with ActSubMod do
      begin
        SetToNoOutput(VarStrList);
        UpdateStringGridVar;
        updatePropIniFile(VarStrList, ActSubMod.Name);
      end;
    end;
    self.Lmod.fModel.init(Lmod.fModel.actIniFile);
    self.Lmod.fModel.FPropIniFile.UpdateFile;
  end;
end;

procedure TFormMod.btnSaveasPNGClick(Sender: TObject);
var
  PNG: TPNGImage;
  tmpBitmap: TBitmap;
  saveDialog: TSaveDialog;
  idx: Integer;
  IniFile: TMyIniFile;
begin
  idx := ComboBoxIniFile.ItemIndex;
  IniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[idx]);

  saveDialog := TSaveDialog.create(self);
  with saveDialog do
  begin
    title := 'Save your Chart';
    Filter := 'PNG File|*.png';
    DefaultExt := 'png';
    FilterIndex := 1;
    FileName := ChangeFileExt(ExtractFileName(IniFile.FileName), '.png');
  end;

  PNG := TPNGImage.create;
  tmpBitmap := TBitmap.create;

  try
    with tmpBitmap do
    begin
      Width := ChartSimResults.Width;
      Height := ChartSimResults.Height;
      ChartSimResults.Draw(Canvas, Rect(0, 0, Width, Height));
    end;
    PNG.Assign(tmpBitmap);
    with saveDialog do
      if Execute then
        PNG.SaveToFile(FileName);
  finally
    PNG.Free;
    tmpBitmap.Free;
    saveDialog.Free;
  end;
end;

procedure TFormMod.AdvStringGridStateEditCellDone(Sender: TObject;
  aCol, aRow: Integer);
begin
  SaveState;
end;

procedure TFormMod.AdvStringGridOptionsEditCellDone(Sender: TObject;
  aCol, aRow: Integer);
begin
  SaveOptions;
end;

procedure TFormMod.InitAllAndCheckExternalV();
var
  IniFile: TMyIniFile;
  actInifileIndex: Integer;
begin
  actInifileIndex := ComboBoxIniFile.ItemIndex;
  IniFile := TMyIniFile(Lmod.fModel.FIniFiles.objects[actInifileIndex]);
  Lmod.fModel.init(IniFile);
  Lmod.fModel.InitAllSubMods;

  if self.Lmod.LinkedModel <> nil then
    Lmod.LinkedModel.InitAllExternV;

  showmessage('No problems found');

  UpdateStringGridState();
  UpdateStringGridExternV;
end;

procedure TFormMod.CheckButtonClick(Sender: TObject);
begin
  InitAllAndCheckExternalV();
end;

end.
