unit UFormMod;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Menus, StdCtrls, UFormGraph, ComCtrls, UMod, Grids, DirOutln,
  Buttons, ToolWin, IniFiles, AdvGrid, TeeProcs, TeEngine, Chart, Series,
  UTextFileH, UHumeShow, UFormOpt, UFormSelPar, ModLink, UFormChiSquareAnalysis,
  UFormShowFinalValues, Math, FormSGA, BaseGrid, Variants, pngimage, ImgList,
  UVisualization; // , JvCsvData;

const
  MaxSeries = 100;

type
  TLineSeriesArr = array[0..MaxSeries - 1] of TFastLineSeries;
  TCustomSeriesArr = array[0..MaxSeries - 1] of TCustomSeries;

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
    LabelControlFileDesc: TLabel;
    LabelWeathFileDesc: TLabel;
    TabSheetParameter: TTabSheet;
    TabSheetState: TTabSheet;
    TabSheetData: TTabSheet;
    AdvStringGridParam: TAdvStringGrid;
    AdvStringGridState: TAdvStringGrid;
    AdvStringGridData: TAdvStringGrid;
    TabSheetModelDiagram: TTabSheet;
    TabSheetStat: TTabSheet;
    LabelTimeStepDesc: TLabel;
    EditTimeStep: TEdit;
    EditStartTime: TEdit;
    EditEndTime: TEdit;
    TabSheetResultTab: TTabSheet;
    AdvStringGridResults: TAdvStringGrid;
    TabSheetGraphResult: TTabSheet;
    Chart1: TChart;
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
    EditControlFile: TEdit;
    OpenDialog1: TOpenDialog;
    Help1: TMenuItem;
    Info1: TMenuItem;
    EditWeatherfile: TEdit;
    SensitivityAnalysis: TMenuItem;
    LMod: TModLink;
    ComboBoxTimeAxisOption: TComboBox;
    LabelTimeSeriesOption: TLabel;
    SelectMeasDataCheckBox: TCheckBox;
    StartTimePicker: TDateTimePicker;
    EndTimePicker: TDateTimePicker;
    GroupBoxStarttime: TGroupBox;
    GroupBoxEndtime: TGroupBox;
    EditStateIniFileName: TEdit;
    LabelStateIniFileName: TLabel;
    EditParamIniFileName: TEdit;
    LabelParamIniFileName: TLabel;
    SaveDialog1: TSaveDialog;
    SpeedButtonChangeStateIniFile: TSpeedButton;
    SpeedButtonChangeWeatherFile: TSpeedButton;
    SpeedButtonChangeParamIniFile: TSpeedButton;
    SpeedChangeParamIniFile: TSpeedButton;
    BitBtnSaveParamTo: TBitBtn;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    FWDLabel: TLabel;
    Label5: TLabel;
    LWDLabel: TLabel;
    FWDDateLabel: TLabel;
    LWDDateLabel: TLabel;
    BitBtnSaveStateTo: TBitBtn;
    SpeedButtonChangeSTageFileName: TSpeedButton;
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
    ToolBar1: TToolBar;
    Panel1: TPanel;
    ComboBoxIniFile: TComboBox;
    ComboBoxSubMod: TComboBox;
    LabelActIniFileDesc: TLabel;
    LabelSubModelCombobox: TLabel;
    SpeedButtonRun: TSpeedButton;
    btnSaveasPNG: TSpeedButton;
    ToolBarExternals: TToolBar;
    btnAdvStatToClipBoardButton: TSpeedButton;
    btn1: TSpeedButton;
    btnButtonSaveIntegrChanges1: TSpeedButton;
    btnButtonSaveToNewIniFile1: TSpeedButton;
    btnCheckButton1: TSpeedButton;
    btnButtonChangeControlFile: TSpeedButton;
    il1: TImageList;

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
    procedure EditParamIniFileNameMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
    procedure LabelActIniFileDescMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure EditStateIniFileNameMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
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
  private
    n_lineSeries, n_PointSeries, nFormGraph: Integer;
    FormGraphArray: array[1..10] of TFormGraph;
    LineSeriesArr: TLineSeriesArr;
    DataFileSim: TTextFileH;
    DataFileMeas: TTextFileH;

    img_help, img_savetoall: TBitmap;
    EXE_PATH: string;
    function getLinkedModel(): TMod;
    procedure testSubModIndex(n: Integer);
    procedure updatePropIniFile(strList: TStringList; submodname: string);
//    procedure ConnectionPaint(Sender: TObject);
  public
    FPropIniFile: TMyIniFile;
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
    procedure ChangeStateIniFile;
  end;

var
  FormMod: TFormMod;
  paintbox: TPaintBox;

implementation

uses
  UState, UFormShow1_1, UMeasValue;
{$R *.DFM}

procedure TFormMod.Menu_RunClick(Sender: TObject);
begin
  RunModel;
end;

procedure TFormMod.SpeedButtonRunClick(Sender: TObject);
begin
  RunModel;
end;

procedure TFormMod.Menu_ExitClick(Sender: TObject);
begin
  application.terminate;
end;

procedure TFormMod.FormCreate(Sender: TObject);
begin
  FPropIniFile := TMyIniFile.create(ExtractFilePath(ParamStr(0))
    + 'properties.ini');

  ModelWasRunning := false;
  nFormGraph := 0;
  if LMod.fModel <> nil then begin
    if (LMod.fModel.title <> '') then
      self.Caption := LMod.fModel.title;
    LMod.fModel.init(LMod.fModel.actIniFile);
    ComboBoxTimeAxisOption.ItemIndex := 0;
  end;
  //StatusBarMain.Panels[2].Style := psOwnerDraw;
  EXE_PATH := ExtractFilePath(application.EXEName);
  AdvStringGridStat.ControlLook.NoDisabledButtonLook := True;

  // ReportMemoryLeaksOnShutdown := True;

//  img_help := TBitmap.Create();
//  img_savetoall := TBitMap.Create();
//  il1.GetBitmap(1, img_help);
//  il1.GetBitmap(0, img_savetoall);

end;

procedure TFormMod.RunModel;
var
  starttime, endtime, timelapsed: real;
begin
  Screen.cursor := CrHourGlass;
  StatusBarMain.Panels.Items[0].Text := 'Running';
  StatusBarMain.show;
  MenuView.Enabled := True;
  starttime := time;

  if LMod.fModel <> nil then
    LMod.fModel.run
  else begin
    showmessage('No Model linked!');
    exit;
  end;
  endtime := time;
  timelapsed := endtime - starttime;
  update_StringGrid(LMod.fModel.reg_fn); // TODO
  Screen.cursor := CrDefault;
  StatusBarMain.Panels.Items[0].Text := ' Runtime: ' + TimeToStr(timelapsed);

  //if LMod.fModel.ReInitAfterRun then // TODO
  //  LMod.fModel.init(LMod.fModel.actIniFile);

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
  with AdvStringGridParam do begin
    BeginUpdate;
    EditParamFileName.Text := LMod.fModel.ParamInifile.FileName;
    Clear;
    Rows[0].commatext := 'Name, Unit, Value,,';
    RowCount := 2;
    FixedRows := 1;

    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then begin
      SubModel := TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.ParStrList.count + 1;
      for i := 0 to SubModel.ParStrList.count - 1 do begin
        Param := TPar(SubModel.ParStrList.objects[i]);
        with Param do
          line := name + ',' + u + ',' + floattoStrF(v, ffgeneral, 6, 3);
        Rows[i + 1].commatext := line;
        AddBitButton(3, i + 1, 20, 20, '', img_savetoall, haCenter, vaCenter);
        if Param.Comment <> '' then
          AddBitButton(4, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
      end;
    end;
    EditParamFileName.hint := LMod.fModel.ParamInifile.FileName;
    AutoSizeColumns(True);
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
  with AdvStringGridState do begin

    BeginUpdate;
    // WIESO WIRD HIER DAS GESAMTE MODELL NOCH MAL ERZEUGT?
    // ActIniFileIndex := ComboBoxIniFile.ItemIndex;
    // Inifile := TMyIniFile(LMod.fModel.FiniFiles.objects[ActIniFileIndex]);
    // LMod.fModel.init(IniFile);
    // LMod.fModel.InitAllSubMods;

    EditStateFileName.Text := LMod.fModel.StateIniFile.FileName;
    Clear;
    Rows[0].commatext :=
      'Name, Unit, Ini.Value,, WriteToFile, Plot, WriteFinalValue,'; //Description';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex >= 0 then begin
      SubModel := TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.stateStrList.count + 1;
      for i := 0 to SubModel.stateStrList.count - 1 do begin
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
        if state.Comment <> '' then
          AddBitButton(7, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
      end;
    end;
    EditStateFileName.hint := LMod.fModel.StateIniFile.FileName;

    AutoSizeColumns(True);
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
  with AdvStringGridExternV do begin
    BeginUpdate;
    Clear;
    Rows[0].commatext := 'Name, Unit, Factor, Source, , Plot';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then begin
      SubModel := TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.ExternVStrList.count + 1;
      for i := 0 to SubModel.ExternVStrList.count - 1 do begin
        ExVar := TExternV(SubModel.ExternVStrList.objects[i]);
        with ExVar do
          line := name + ',' + u + ',' + floattoStrF(C_f, ffgeneral, 6, 3)
            + ',' + Source;
        Rows[i + 1].commatext := line;
        if ExVar.Comment <> '' then begin
          AddBitButton(4, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
        end;
        AddCheckBox(5, i + 1, True, True);
        SetCheckBoxState(5, i + 1, ExVar.PlotToGraph);
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
  with AdvStringGridOptions do begin
    BeginUpdate;
    // TODO ActIniFileIndex := ComboBoxIniFile.ItemIndex;
    // TODO Inifile := TMyIniFile(LMod.fModel.FiniFiles.objects[ActIniFileIndex]);
    // TODO LMod.fModel.init(IniFile);
    // TODO LMod.fModel.InitAllSubMods;

    EditOptionsFileName.Text := LMod.fModel.OptionIniFile.FileName;
    Clear;
    Rows[0].commatext := 'Name, Options';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex <> -1 then begin
      SubModel := TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.OptionStrList.count + 1;
      for i := 0 to SubModel.OptionStrList.count - 1 do begin
        Option := TOption(SubModel.OptionStrList.objects[i]);
        line := Option.name + ',' + Option.Option;
        Rows[i + 1].commatext := line;
        AddBitButton(2, i + 1, 20, 20, '', img_savetoall, haCenter, vaCenter);
      end;
    end;
    AutoSizeColumns(True);
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
  EditStateFileName.Text := LMod.fModel.StateIniFile.FileName;
  with AdvStringGridVar do begin
    BeginUpdate;
    Clear;
    Rows[0].commatext :=
      'Name, Unit, WriteToFile,  Plot, WriteFinalValue,'; //  Description';
    RowCount := 2;
    FixedRows := 1;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    if actSubModIndex >= 0 then begin
      SubModel := TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
      RowCount := SubModel.VarStrList.count + 1;
      for i := 0 to SubModel.VarStrList.count - 1 do begin
        Variable := TVar(SubModel.VarStrList.objects[i]);
        line := Variable.name + ',' + Variable.u;
        Rows[i + 1].commatext := line;
        AddCheckBox(2, i + 1, True, True);
        SetCheckBoxState(2, i + 1, Variable.writeToFile);
        AddCheckBox(3, i + 1, True, True);
        SetCheckBoxState(3, i + 1, Variable.PlotToGraph);
        AddCheckBox(4, i + 1, True, True);
        SetCheckBoxState(4, i + 1, Variable.WriteFinalValue);
        if Variable.Comment <> '' then
          AddBitButton(5, i + 1, 20, 20, '', img_help, haCenter, vaCenter);
      end;

    end;
    AutoSizeColumns(True);
    Endupdate;
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
  with AdvStringGridResults do begin
    BeginUpdate;
    ColCount := 2;
    RowCount := 3;
    Clear;
    actSubModIndex := ComboBoxSubMod.ItemIndex;
    actInifileIndex := ComboBoxIniFile.ItemIndex;
    SubModel := TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
    IniFile := TMyIniFile(LMod.fModel.FIniFiles.objects[actInifileIndex]);
    fn := IniFile.ReadString('OutputFiles', SubModel.name, '');
    if fn = '' then
      fn := SubModel.fn_state
    else
      fn := fn + '_dat.csv';
    if FileExists(fn) then begin
      ShowDataFile(fn);
      EditOutputdatafilename.Text := fn
    end;

    if CheckBoxDateFormat.Checked then
      for i := 1 to RowCount - 2 do
        cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]));

    AutoSizeColumns(True);
    Endupdate;
  end;
  Screen.cursor := CrDefault;
end;

procedure TFormMod.UpdatePageGraphResult;
var
  actSubModIndex, actInifileIndex: Integer;
  SubModel: TSubModel;
  IniFile: TMyIniFile;
  ActState: TState;
  ActVar: TVar;
  fnMeas: string;
  X, Y: real;
  ActLineSeries: TFastLineSeries;
  ActPointSeries: TPointSeries;
  DataFileSim: TTextFileH;
  DataFileMeas: TTextFileH;
  //nrs: array[0..MaxSeries - 1] of Integer;

  procedure drawSimGraph(strList: TStringList);
  var
    i, nr: Integer;
  begin
    for i := 0 to strList.count - 1 do begin
      ActState := TState(strList.objects[i]);
      if ActState.PlotToGraph then begin
        inc(n_lineSeries);
        LineSeriesArr[n_lineSeries] := TFastLineSeries.create(Chart1);
        ActLineSeries := LineSeriesArr[n_lineSeries];
        with ActLineSeries do begin
          Xvalues.DateTime := (ComboBoxTimeAxisOption.Text = 'Date');
          title := ActState.name + ' ' + ActState.u;
          LinePen.Width := 2;
        end;
        Chart1.AddSeries(ActLineSeries);
        nr := DataFileSim.indexOf(ActState.name);

        with DataFileSim do begin
          GoTop;
          while hasMoreLines() do begin
            FastNextLine;
            X := getIndexValue(0);
            Y := getIndexValue(nr);
            //if not isnan(X) and not isnan(Y) then
              ActLineSeries.addxy(X, Y, '', ClteeColor);
          end;
        end;
      end;
    end;

  end;

  procedure drawMeasGraph(strList: TStringList);
  var
    i, nr: Integer;
  begin
    for i := 0 to strList.count - 1 do begin
      ActVar := TVar(strList.objects[i]);
      if ActVar.PlotToGraph then begin
        inc(n_PointSeries);
        if (DataFileMeas.containsName(ActVar.name)) then begin
          ActPointSeries := TPointSeries.create(Chart1);
          with ActPointSeries do begin
            title := ActVar.name + ' ' + ActVar.u;
            if (LineSeriesArr[n_PointSeries] <> nil) then begin
              SeriesColor := LineSeriesArr[n_PointSeries].SeriesColor;
            end;
          end;
          Chart1.AddSeries(ActPointSeries);

          with DataFileMeas do begin
            nr := indexOf(ActVar.name);
            GoTop;
            while hasMoreLines() do begin
              FastNextLine;
              X := getIndexValue(0);
              Y := getIndexValue(nr);
              if not isnan(X) and not isnan(Y) and (X >=
                LMod.fModel.starttime)
                and (X <= LMod.fModel.endtime) then
                if (LineSeriesArr[n_PointSeries] <> nil) then begin
                  ActPointSeries.addxy(X, Y, '',
                    LineSeriesArr[n_PointSeries].SeriesColor)
                end else begin
                  ActPointSeries.addxy(X, Y, '', ClteeColor);
                end;
            end;
          end;
        end;
      end;
    end;
  end;

begin
  //UpdatePageResultTab;

  Screen.cursor := CrHourGlass;
  Chart1.AutoRepaint := false;

  actSubModIndex := ComboBoxSubMod.ItemIndex;
  actInifileIndex := ComboBoxIniFile.ItemIndex;
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  IniFile := TMyIniFile(LMod.fModel.FIniFiles.objects[actInifileIndex]);

  fnMeas := IniFile.ReadString('MeasurementFiles', SubModel.name, '');

  with Chart1 do begin
    RemoveAllSeries;
    title.Clear;
    Legend.LegendStyle := lsSeries;
  end;

  DataFileSim := TTextFileH.create(SubModel.fn_state);
  DataFileMeas := TTextFileH.create(fnMeas);

  if FileExists(SubModel.fn_state) then begin
    n_lineSeries := -1;
    drawSimGraph(SubModel.stateStrList);
    drawSimGraph(SubModel.VarStrList);
    drawSimGraph(SubModel.ExternVStrList);
  end;

  if FileExists(fnMeas) and SelectMeasDataCheckBox.Checked then begin
    n_PointSeries := -1;
    drawMeasGraph(SubModel.stateStrList);
    drawMeasGraph(SubModel.VarStrList);
  end;

  FreeAndNil(DataFileSim);
  FreeAndNil(DataFileMeas);

  Chart1.autorepaint := true;
  Chart1.Repaint;
  Screen.cursor := CrDefault;
end;

procedure TFormMod.UpdateStringGridData;

var
  i, actSubModIndex: Integer;
  SubModel: TSubModel;
  filedata, linedata: TStringlist;

begin
  Screen.cursor := CrHourGlass;
  with AdvStringGridData do begin
    BeginUpdate;
    Clear;
    ColCount := 3;
    RowCount := 3;

    actSubModIndex := ComboBoxSubMod.ItemIndex;
    SubModel :=
      TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);

    if SubModel.SomethingMeasured then begin
      filedata := TStringlist.Create;
      try
        filedata.loadfromfile(SubModel.FMeasValues.FileName);
        RowCount := Math.Max(filedata.Count, FixedRows + 1);
        linedata := TStringlist.Create;
        try
          linedata.Delimiter := #32;
          //space, multiple spaces are treated as one delimiter
          for i := 0 to filedata.count - 1 do begin
            linedata.DelimitedText := filedata[i];
            if ColCount < linedata.Count then
              ColCount := linedata.Count;
            Rows[i].Assign(linedata);
          end;
        finally
          linedata.Free;
        end;
      finally
        filedata.Free;
      end;
      FixedRows := 2;
      FixedCols := 0;

      EditDataFileName.Text := SubModel.FMeasValues.FileName;

      //LoadFromCSV(SubModel.FMeasValues.FileName);
      // wäre wesentlich einfacher, geht aber nicht,
      // weil die Daten mit beliebig vielen Leerzeichen getrennt sind

      if CheckBoxDataDateFormat.Checked then
        for i := 1 to RowCount - 1 do
          cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]));
    end else begin
      EditDataFileName.Text := '';
    end;
    EditDataFileName.hint := SubModel.FMeasValues.FileName;
    AutoSizeColumns(True);
    Endupdate;
  end;
  Screen.cursor := CrDefault;
end;

procedure TFormMod.UpdatePageIntegration;
begin
  EditTimeStep.Text := FloatToStr(LMod.fModel.time.c);
  EditStartTime.Text := FloatToStr(LMod.fModel.time.v);
  EditEndTime.Text := FloatToStr(LMod.fModel.endtime);
  // Treue
  FWDLabel.Caption := IntToStr(LMod.fModel.FirstWeatherData);
  FWDDateLabel.Caption := DateToStr(LMod.fModel.FirstWeatherData);
  LWDLabel.Caption := IntToStr(LMod.fModel.LastWeatherData);
  LWDDateLabel.Caption := DateToStr(LMod.fModel.LastWeatherData);
  // Treue
  if (LMod.fModel.weatherfile <> nil) and FileExists
    (LMod.fModel.weatherfile.FileName) then
    EditWeatherfile.Text := LMod.fModel.weatherfile.FileName;
  self.EditStateIniFileName.Text := LMod.fModel.StateIniFile.FileName;
  self.EditParamIniFileName.Text := LMod.fModel.ParamInifile.FileName;
end;

// ==============================================================================
// ComboxBox
// ==============================================================================

procedure TFormMod.ComboBoxInifileChange(Sender: TObject);
var
  actInifileIndex: Integer;
begin
  actInifileIndex := ComboBoxIniFile.ItemIndex;
  ComboBoxIniFile.hint :=
    ComboBoxIniFile.Items[ComboBoxIniFile.ItemIndex];
  LMod.fModel.actIniFile := TMyIniFile
    (LMod.fModel.FIniFiles.objects[actInifileIndex]);
  LMod.fModel.init(LMod.fModel.actIniFile);
  LMod.fModel.InitAllSubMods;
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
  with ComboBoxIniFile do begin
    for i := 0 to Items.count - 1 do
      if Canvas.TextWidth(Items[i]) > ItemWidth then
        ItemWidth := Canvas.TextWidth((Items[i]));
    inc(ItemWidth, 10);
    Perform(CB_SetDroppedWidth, ItemWidth, 0);
  end;
end;

procedure TFormMod.ComboBoxSubModChange(Sender: TObject);
begin
  LMod.fModel.InitAllSubMods;
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
    AdvStringGridResults.SetFocus
      ;
  //else if PageControl.ActivePage = TabSheetGraphResult then
  //  Chart1.SetFocus;

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
  with AdvStringGridStat do begin
    Clear;
    if (LMod.fModel <> nil) and FileExists(LMod.fModel.reg_fn) then begin
      strList := TStringList.create;
      strList.LoadFromFile(LMod.fModel.reg_fn);
      if strList.count > 1 then begin
        BeginUpdate;
        RowCount := strList.count;
        FixedRows := 1;
        ColCount := 12;
        fixedcols := 2;
        Rows[0].commatext := strList[0];
        for i := 1 to strList.count - 1 do begin
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

// ==============================================================================
// Save
// ==============================================================================

procedure TFormMod.ButtonSaveIntegrChangesClick(Sender: TObject);

var
  i: Integer;
  ActSubMod: TSubModel;
begin
  with LMod.fModel.actIniFile do begin
    UpdateFile;
    WriteFloat('TimeInit', 'Startzeit', strtofloat(EditStartTime.Text));
    WriteFloat('TimeInit', 'Endzeit', strtofloat(EditEndTime.Text));
    WriteFloat('TimeInit', 'TimeStep', strtofloat(EditTimeStep.Text));
    WriteString('FileNames', 'StateIniFN', EditStateIniFileName.Text);
    WriteString('FileNames', 'ParamIniFN', EditParamIniFileName.Text);
    WriteString('FileNames', 'WeatherFileFN', EditWeatherfile.Text);
    for i := 0 to LMod.fModel.SubModStrList.count - 1 do begin
      ActSubMod := TSubModel(LMod.fModel.SubModStrList.objects[i]);
      if FileExists(ActSubMod.FMeasValues.FFileName) then
        with ActSubMod do
          WriteString('MeasurementFiles', Name, FMeasValues.FFileName)
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
  if (actSubModIndex = -1) then begin
    SubModel :=
      TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
    assignFile(f, SubModel.FMeasValues.FileName);
    reset(f);
    for i := 1 to AdvStringGridData.RowCount do begin
      line := AdvStringGridData.Rows[i].Text;
      writeln(f, line);
    end;
    SubModel.init(LMod.fModel);
    closeFile(f);
  end;
end;

procedure TFormMod.updatePropIniFile(strList: TStringList; submodname:
  string);
var
  i: Integer;
  entity: THumeNumEntity;
begin
  for i := 0 to strList.count - 1 do begin
    entity := THumeNumEntity(strList.objects[i]);
    with FPropIniFile, entity do begin
      WriteBool(submodname, Name + '.PlotTograpH', PlotToGraph);
      WriteBool(submodname, Name + '.WriteFinalValue', WriteFinalValue);
      WriteBool(submodname, Name + '.WriteToFile', writeToFile);
      WriteBool(submodname, Name + '.SelForSensOut', SelForSensOut);
    end;
  end;
  FPropIniFile.UpdateFile;
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
  StateIniFile := LMod.fModel.StateIniFile;
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);

  with AdvStringGridState do begin
    for i := 1 to RowCount - 1 do begin
      StateIniFile.WriteFloat(SubModel.submodname, cells[0, i],
        strtofloat(cells[2, i]));
      StateNdx := SubModel.stateStrList.IndexOf(cells[0, i]);
      if StateNdx >= 0 then begin
        ActState := TState(SubModel.stateStrList.objects[StateNdx]);
        ActState.v := strtofloat(cells[2, i]);
        GetCheckBoxState(4, i, ActState.writeToFile);
        GetCheckBoxState(5, i, ActState.PlotToGraph);
        GetCheckBoxState(6, i, ActState.WriteFinalValue);
      end;
    end;
  end;

  updatePropIniFile(SubModel.stateStrList, SubModel.name);
  StateIniFile.UpdateFile;
  LMod.fModel.init(LMod.fModel.actIniFile);
  LMod.fModel.InitAllSubMods;
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
  OptionIniFile := LMod.fModel.OptionIniFile;
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  with AdvStringGridOptions do begin
    if cells[1, 1] <> '' then begin
      for i := 1 to RowCount - 1 do begin
        OptionString := cells[1, i];
        OptionIniFile.WriteString(SubModel.submodname, cells[0, i],
          cells[1, i]);
        // OptionNdx := SubModel.OptionSTrList.IndexOf(AdvStringGridOptions.Cells[0, i]);
        // ActOption := TOption(SubModel.OptionSTrList.objects[OptionNdx]);
      end;
    end;
  end;

  OptionIniFile.UpdateFile;
  LMod.fModel.init(LMod.fModel.actIniFile);
  LMod.fModel.InitAllSubMods;
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
  ParamInifile := LMod.fModel.ParamInifile;
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  with AdvStringGridParam do begin
    for i := 1 to RowCount - 1 do begin
      index := SubModel.ParStrList.IndexOf(cells[0, i]);
      if index >= 0 then begin
        Actpar := TPar(SubModel.ParStrList.objects[index]);
        if Actpar.writeToFile then begin
          ParamInifile.WriteFloat(SubModel.submodname, cells[0, i],
            strtofloat(cells[2, i]));
        end;
      end;
    end;
  end;

  ParamInifile.UpdateFile;
  LMod.fModel.init(LMod.fModel.actIniFile);
  LMod.fModel.InitAllSubMods;
  //UpdateStringGridParam;
end;

procedure TFormMod.SaveVar();
var
  ActVar: TVar;
  i, actSubModIndex, VarNdx: Integer;
  SubModel: TSubModel;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  with AdvStringGridVar do begin
    for i := 1 to RowCount - 1 do begin
      VarNdx := SubModel.VarStrList.IndexOf(cells[0, i]);
      if VarNdx >= 0 then begin
        ActVar := TVar(SubModel.VarStrList.objects[VarNdx]);
        GetCheckBoxState(2, i, ActVar.writeToFile);
        GetCheckBoxState(3, i, ActVar.PlotToGraph);
        GetCheckBoxState(4, i, ActVar.WriteFinalValue);
      end;
    end;
  end;
  updatePropIniFile(SubModel.VarStrList, SubModel.Name);

end;

procedure TFormMod.ButtonSaveToNewIniFileClick(Sender: TObject);

var
  NewInifile: TMyIniFile;
  index, i: Integer;
  IniFN: string;
  TempFile: textFile;
  ActSubMod: TSubModel;
begin
  with SaveDialog1 do begin
    title := 'New IniFile';
    DefaultExt := 'ini';
    Filter := 'Conrolfiles (*.ini)|*.ini';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
  end;
  if SaveDialog1.Execute then begin

    for i := 0 to LMod.fModel.SubModStrList.count - 1 do begin
      ActSubMod := TSubModel(LMod.fModel.SubModStrList.objects[i]);
      if FileExists(ActSubMod.FMeasValues.FFileName) then
        LMod.fModel.actIniFile.WriteString('MeasurementFiles',
          ActSubMod.Name,
          ActSubMod.FMeasValues.FFileName)
    end;

    LMod.fModel.actIniFile.UpdateFile;

    NewInifile := TMyIniFile.create(SaveDialog1.FileName);
    with NewInifile do begin
      WriteFloat('TimeInit', 'Startzeit', strtofloat(EditStartTime.Text));
      WriteFloat('TimeInit', 'Endzeit', strtofloat(EditEndTime.Text));
      WriteFloat('TimeInit', 'TimeStep', strtofloat(EditTimeStep.Text));
      WriteString('FileNames', 'StateIniFN', EditStateIniFileName.Text);
      WriteString('FileNames', 'ParamIniFN', EditParamIniFileName.Text);
      WriteString('FileNames', 'WeatherFileFN', EditWeatherfile.Text);
      UpdateFile;
    end;
    LMod.fModel.FIniFiles.append(NewInifile.FileName);
    index := LMod.fModel.FIniFiles.count - 1;
    LMod.fModel.FIniFiles.objects[index] := NewInifile;
    assignFile(TempFile, LMod.fModel.ControlFileFn);

    rewrite(TempFile);
    for i := 0 to LMod.fModel.FIniFiles.count - 1 do begin
      IniFN := TMyIniFile(LMod.fModel.FIniFiles.objects[i]).FileName;
      writeln(TempFile, IniFN);
    end;
    closeFile(TempFile);

    LMod.fModel.actIniFile :=
      TMyIniFile(LMod.fModel.FIniFiles.objects[index]);
    LMod.fModel.init(LMod.fModel.actIniFile);
    LMod.fModel.InitAllSubMods;
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

end;

procedure TFormMod.ButtonSaveStateClick(Sender: TObject);
begin
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
  Model := LMod.fModel;

  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  if actSubModIndex < 0 then begin
    showmessage('Kein aktives Submodel gefunden.');
    exit;
  end;

  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.ParStrList.IndexOf(AdvStringGridParam.cells[0, aRow]);

  if index >= 0 then begin
    Actpar := TPar(SubModel.ParStrList.objects[index]);
    if Actpar.writeToFile and (aCol = 3) then begin
      for i := 0 to Model.FIniFiles.count - 1 do begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        ParamIniFileFN := actIniFile.ReadString
         (Model.Str_SectionName_FileNames,Model.Str_SectionTopic_ParamIniFN,'');
        ActParamIniFile := TMyIniFile.create(ParamIniFileFN);

        with ActParamIniFile, AdvStringGridParam do begin
          WriteFloat(SubModel.submodname, cells[0, aRow],
            strtofloat(cells[2, aRow]));
        end;
        ActParamIniFile.UpdateFile;
        ActParamIniFile.Free;
        //FreeAndNil(actIniFile);
      end;

    end;
    if (aCol = 4) then
      showmessage(Actpar.Comment);

  end;

  // ActInifile.free;
  // KLUSS UpdateStringGridParam;

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

  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.ParStrList.IndexOf(AdvStringGridOptions.cells[0,
    aRow]);
  if index >= 0 then begin
    Actpar := TPar(SubModel.ParStrList.objects[index]);
    if Actpar.writeToFile then begin
      for i := 0 to Model.FIniFiles.count - 1 do begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        OptionIniFileFN := actIniFile.ReadString
          (Model.Str_SectionName_FileNames,
          Model.Str_SectionTopic_OptionIniFN, '');

        ActOptionIniFile := TMyIniFile.create(OptionIniFileFN);
        with ActOptionIniFile do begin
          WriteFloat(SubModel.submodname, AdvStringGridOptions.cells[0,
            aRow],
              strtofloat(AdvStringGridOptions.cells[1, aRow]));
          UpdateFile;
          Free;
        end;
      end;
    end;
  end;

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

  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.stateStrList.IndexOf(AdvStringGridState.cells[0,
    aRow]);
  if index >= 0 then begin
    ActState := TState(SubModel.stateStrList.objects[index]);

    if ActState.writeToFile and (aCol = 3) then begin
      for i := 0 to Model.FIniFiles.count - 1 do begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        StateIniFileFN := actIniFile.ReadString
          (Model.Str_SectionName_FileNames,
          Model.Str_SectionTopic_StateIniFN,
          '');

        ActStateIniFile := TMyIniFile.create(StateIniFileFN);
        with ActStateIniFile, AdvStringGridState do begin
          WriteFloat(SubModel.submodname, cells[0, aRow],
            strtofloat(cells[2, aRow]));
          UpdateFile;
          FreeAndNil(ActStateIniFile);
        end;
      end;
    end;

    if aCol = 7 then
      showmessage(ActState.Comment);

  end;

  // KLUSS UpdateStringGridState;
end;

procedure TFormMod.AdvStringGridOptionsButtonClick(Sender: TObject;
  aCol, aRow: Integer);
var
  actIniFile, ActOptionIniFile: TMyIniFile;
  actSubModIndex, index, i: Integer;
  SubModel: TSubModel;
  Model: TMod;
  ActOption: TOption;
  OptionIniFileFN: string;
begin
  Model := getLinkedModel();
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.OptionStrList.IndexOf(AdvStringGridOptions.cells[0,
    aRow]);
  if index >= 0 then begin
    ActOption := TOption(SubModel.OptionStrList.objects[index]);
    if ActOption.writeToFile then begin
      for i := 0 to Model.FIniFiles.count - 1 do begin
        actIniFile := TMyIniFile(Model.FIniFiles.objects[i]);
        OptionIniFileFN := actIniFile.ReadString
          (Model.Str_SectionName_FileNames,
          Model.Str_SectionTopic_OptionIniFN, '');
        ActOptionIniFile := TMyIniFile.create(OptionIniFileFN);
        with ActOptionIniFile, AdvStringGridOptions do begin
          WriteString(SubModel.submodname, cells[0, aRow], cells[1,
            aRow]);
          UpdateFile;
          FreeAndNil(ActOptionIniFile);
        end;
      end;
    end;
  end;

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
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.VarStrList.IndexOf(AdvStringGridVar.cells[0, aRow]);
  if index <> -1 then begin
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
  if (actSubModIndex <> -1) then begin
    SubModel :=
      TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
//    assignFile(f, SubModel.FMeasValues.FileName);
//    rewrite(f);
    AdvStringGridData.SaveToASCII(SubModel.FMeasValues.FileName);
{    for row := 0 to AdvStringGridData.RowCount-1 do begin
      for col := 0 to AdvStringGridData.ColCount - 1 do
         write(f, AdvStringGridData.Cells[col, row]+LMod.LinkedModel.Separator);
      writeln(f)
    end;
    closeFile(f); }
    SubModel.init(LMod.fModel);
  end;
end;

procedure TFormMod.btn1Click(Sender: TObject);
var
  SubModel: TSubModel;
  i, actSubModIndex: Integer;
  f: textFile;
  line: string;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  if (actSubModIndex = -1) then begin
    SubModel :=
      TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
    assignFile(f, SubModel.FMeasValues.FileName);
    reset(f);
    for i := 1 to AdvStringGridData.RowCount do begin
      line := AdvStringGridData.Rows[i].Text;
      writeln(f, line);
    end;
    SubModel.init(LMod.fModel);
    closeFile(f);
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
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  index := SubModel.ExternVStrList.IndexOf(AdvStringGridExternV.cells[0,
    aRow]);
  if index <> -1 then begin
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
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  if self.AdvStringGridOptions.cells[aCol, aRow] <> '' then begin
    ActOption := TOption(SubModel.OptionStrList.objects[aRow - 1]);
    ActStrLst := ActOption.OptionList;
    AdvStringGridOptions.combobox.Items.assign(ActStrLst);
  end;
end;

procedure TFormMod.AdvStringGridStateCheckBoxClick(Sender: TObject;
  aCol, aRow: Integer; state: Boolean);
begin
  self.ButtonSaveStateClick(Sender);
end;

procedure TFormMod.AdvStringGridVarCheckBoxClick(Sender: TObject;
  aCol, aRow: Integer; state: Boolean);
begin
  self.SaveVar();
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
const
  colorset: array[0..11] of TColor =
    (clBlue, clGreen, clRed, clGray, clFuchsia, clTeal, clPurple,
    clNavy, clLime, clMaroon, clAqua, clOlive);

begin

  if FormShow1_1 = nil then
    FormShow1_1 := TFormShow1_1.create(self);

  FormShow1_1.AdvStringGrid1_1.Clear;
  with FormShow1_1 do begin
    try
      Model := LMod.LinkedModel;
      idx := Model.SubModStrList.IndexOf(AdvStringGridStat.cells[0,
        aRow]);
      ActSubMod := TSubModel(Model.SubModStrList.objects[idx]);
      idx := ActSubMod.DataList.IndexOf(AdvStringGridStat.cells[1, aRow]);
      if idx >= 0 then begin
        ActMeasList := TMeasList(ActSubMod.DataList.objects[idx]);
        AdvStringGrid1_1.RowCount := ActMeasList.count + 1
      end else
        Exit;
    except
      Exit;
    end;

    datastring := '';
    lastdatastring := '';

    with AdvStringGrid1_1 do begin
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
    AdvStringGridLegend.Rowcount := 0;

    actcolor := colorset[0];

    for i := 0 to ActMeasList.count - 1 do begin
      ActMeasValue := TMeasValue(ActMeasList.Items[i]);
      lastdatastring := datastring;
      datastring := ActMeasValue.Comment;

      if datastring <> lastdatastring then begin
        with AdvStringGridLegend do begin
          Rowcount := Rowcount + 1;
          actcolor := colorset[RowCount mod Length(colorset)];
          richedit.plaintext := false;
          richedit.font.color := actcolor;
          richedit.font.Style := [fsbold];
          richedit.Text := ActMeasValue.Comment;
          // Richtocell(0, rowindex, AdvStringGridLegend.richedit);
          FontColors[0, Rowcount - 1] := actcolor; // myc
          FontStyles[0, Rowcount - 1] := FontStyles[2, 3] + [fsbold];
          cells[0, Rowcount - 1] := ActMeasValue.Comment;
        end;
      end;

      with ActMeasValue do begin

        Series_Sim.addxy(sim, meas, '', actcolor);
        Series_Res.addxy(meas, sim - meas, '', actcolor);
        Series_Reg.addxy(sim, ActMeasList.intercept + ActMeasList.slope *
          sim,
          '', clteecolor);
        Series_1_1.addxy(meas, meas, '', clteecolor);

        with AdvStringGrid1_1 do begin
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

    with ActMeasList do begin

      if ActMeasList.slope > 0 then
        Diagramtitle := 'y = ' + floattoStrF(intercept, ffgeneral, 5, 3)
          + '(' + floattoStrF(se_intercept, ffgeneral, 5, 3)
          + ') + ' + floattoStrF(slope, ffgeneral, 5, 3) + '(' +
          floattoStrF
          (se_slope, ffgeneral, 5, 3) + ') ' + '* x' + ', r2= ' +
          floattoStrF
          (r2, ffgeneral, 5, 2) + ',  n = ' + IntToStr(count)
      else
        Diagramtitle := 'y = ' + floattoStrF(intercept, ffgeneral, 5, 3)
          + ' ' + floattoStrF(slope, ffgeneral, 5, 3) + '* x';

      with Chart1_1 do begin
        title.Text.Clear;
        Legend.LegendStyle := lsSeries;
        title.Text.Add(Diagramtitle);
      end;

      with MemoStatistics.Lines do begin
        Add('');
        Add('');
        Add(' average meas. value  = ' + floattoStrF(average_meas,
          ffgeneral,
          6, 4));
        Add(' average sim. value   = ' + floattoStrF(average_sim,
          ffgeneral, 6,
          4));
        Add(' Bias                 = ' + floattoStrF(Bias, ffgeneral, 6,
          4));
        Add(' RMSE                 = ' + floattoStrF(RMSE, ffgeneral, 6,
          4));
        Add(' Modelling Efficiency = ' + floattoStrF(modellingefficiency,
          ffgeneral, 6, 4));
        Add(' CD                   = ' + floattoStrF(CD, ffgeneral, 6,
          4));
        Add('');
        Add(' MSD                = ' + floattoStrF(MSD, ffgeneral, 6,
          4) + '  Sum of squared deviations');
        Add(' SB                 = ' + floattoStrF(SB, ffgeneral, 6,
          4) + '  Squared bias');
        Add(' NU                 = ' + floattoStrF(NU, ffgeneral, 6,
          4) + '  nonunity slope');
        Add(' LC                 = ' + floattoStrF(NU, ffgeneral, 6,
          4) + '  lack of correlation');
        Add('');
        Add('');
        Add('');
        Add('        Analysis of Variance for linear Regression:');
        Add('       between measured (y) and simulated (x) values');
        Add('');
        Add('   Source |   DF       SSQ         MQ         F          P');
        Add('  ________ ________________________________________________');
        Add('   Model  |  ' + formatfloat('0000', FGmod) + '   ' +
          formatfloat
          ('######0.00', SQmod) + '  ' + formatfloat('######0.00',
          MQmod) + '  ' + floattoStrF(F_value, ffgeneral, 6,
          3) + '  ' + floattoStrF(prob, ffgeneral, 6, 3));
        Add('   Error  |  ' + formatfloat('0000', FGRest) + '   ' +
          formatfloat
          ('######0.00', SQrest) + '  ' + formatfloat('######0.00',
          MQRest));
        Add('   Total  |  ' + formatfloat('0000', FGges) + '   ' +
          floattoStrF
          (SQ_y, ffgeneral, 6, 3));
        Add('');
        Add('');
        Add(' r2        = ' + floattoStrF(r2, ffgeneral, 6,
          4) + '  (p = ' + floattoStrF(prob, ffgeneral, 6, 4) + ')');
        Add(' slope     = ' + floattoStrF(slope, ffgeneral, 6,
          4) + ' (' + floattoStrF(se_slope, ffgeneral, 6, 4) + ')');
        Add(' intercept = ' + floattoStrF(intercept, ffgeneral, 6,
          4) + ' (' + floattoStrF(se_intercept, ffgeneral, 6, 4) + ')');
        Add('');
        Add('');
      end;
    end;

    showmodal;
    MemoStatistics.Lines.Clear;

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

procedure TFormMod.CheckBoxDataDateFormatClick(Sender: TObject);
var
  i: Integer;
begin
  with AdvStringGridData do begin
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
begin
  self.ButtonSaveExVarClick(Sender);
end;

procedure TFormMod.CheckBoxDateFormatClick(Sender: TObject);
var
  i: Integer;
begin
  with AdvStringGridResults do begin
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
  i, ncol: integer;
begin
  if FormShowFinalValues = nil then
    application.CreateForm(TFormShowFinalValues, FormShowFinalValues);
  Model := getLinkedModel();
  actSubModIndex := self.ComboBoxSubMod.ItemIndex;
  testSubModIndex(actSubModIndex);
  ActSubMod :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);

  if ActSubMod <> nil then begin
    if self.LMod.fModel.GM_OutPutPath <> '' then
       FileName := ActSubMod.fn_finalstate;
    if FileExists(FileName) then begin
      assignFile(f, FileName);
      reset(f);
      linendx := 0;
      repeat
        readln(f, line);
        if (linendx > 1) and (linendx <= Model.IniFileNames.count + 1) then
          line := Extractfilename(Model.IniFileNames.Strings[linendx - 2])
            + ',' + line
        else
          line := ',' + line;
        ncol := 0;
        for I := 1 to length(line) do
          if line[i] = model.Separator then
            inc(ncol);
        with FormShowFinalValues.AdvStringGrid1 do begin
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
  i, actSubModIndex, ExVarNdx: Integer;
  SubModel: TSubModel;
begin
  actSubModIndex := ComboBoxSubMod.ItemIndex;
  SubModel :=
    TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
  for i := 1 to AdvStringGridExternV.RowCount - 1 do begin
    ExVarNdx :=
      SubModel.ExternVStrList.IndexOf(AdvStringGridExternV.cells[0,
      i]);
    if ExVarNdx <> -1 then begin
      ActExVar := TExternV(SubModel.ExternVStrList.objects[ExVarNdx]);
      AdvStringGridExternV.GetCheckBoxState(5, i, ActExVar.PlotToGraph);
    end;
  end;
  // UpdateStringGridExternV;
  updatePropIniFile(SubModel.ExternVStrList, SubModel.Name);
end;

procedure TFormMod.Button1Click(Sender: TObject);
begin
  if self.LMod.LinkedModel <> nil then
    LMod.LinkedModel.InitAllExternV;
end;

procedure TFormMod.SpeedButtonInsRowClick(Sender: TObject);
begin
  AdvStringGridData.InsertRows(AdvStringGridData.row, 1);
end;

procedure TFormMod.Info1Click(Sender: TObject);
begin
  // Application.CreateForm(TFormHumeshow, FormHumeShow);
  // FormHumeShow.showmodal;
  // FormHumeShow.free;
  MessageBox(0,
    'HUME: AN OBJECT ORIENTED COMPONENT LIBRARY FOR GENERIC MODULAR MODELLING OF DYNAMIC SYSTEMS ' + #13
    + #10 + '' + #13 + #10 + 'H. Kage' + #13 + #10 + '' + #13 + #10 +
    'Any model based on this library consists of one main model ' + #13 +
    #10 +
    'module, implemented in a class called ‘Tmod’ and a number ' + #13 +
    #10 +
    'of sub-models. The main model is responsible for the control ' + #13
    + #10
    +
    'of the simulation, single or multiple runs, and also implements ' + #13
    +
    #10
    + 'methods like calculating basic statistics and parameter ' + #13 +
    #10 +
    'estimation based on the Levenberg-Marquardt method. ' + #13 + #10 +
    'All sub-models have to be derived from the base class ' + #13 + #10 +
    '‘TsubMod’ which contains dynamic lists of state variables, ' + #13 +
    #10 +
    'variables, parameters and ‘external values’, i.e. values ' + #13 + #10
    +
    'needed from outside the sub-model. The information' + #13 + #10 +
    'exchange between the sub-models through ‘external values’ ' + #13 +
    #10 +
    'is flexible, since it is simply based on string identities between ' + #13
    +
    #10 + 'the information needed and information located in any other ' +
    #13 +
    #10 + 'submodel or input file. This technique allows exchange of ' +
    #13 +
    #10
    + 'sub-models through ‘drag and drop’ without any changes in ' + #13 +
    #10 +
    'the source code even for a changing number and order of ' + #13 + #10
    +
    'parameters, as long as the necessary input parameters to the ' + #13
    + #10
    +
    'sub-model can be found anywhere else in the model. ' + #13 + #10 +
    'A graphical user interface based on the general data structure ' + #13
    + #10
    +
    'supports control of parameter values, initial values and allows ' + #13
    +
    #10
    + 'input of measured data. ' + #13 + #10 + '' + #13 + #10 +
    'Based on these fundamental classes a component hierarchy ' + #13 + #10
    +
    'has been and is still further developed, including several ' + #13 +
    #10 +
    'components for dry matter production, plant development, ' + #13 + #10
    +
    'dry matter partitioning, root growth of plants as well as ' + #13 +
    #10 +
    'modules for soil water and soil nitrogen budget.', '', MB_ICONQUESTION
    or
    MB_OK);
end;

procedure TFormMod.btnButtonChangeControlFileClick(Sender: TObject);
var
  act_IniFn: string;
  NewInifile: TMyIniFile;
  index: Integer;
begin
  with OpenDialog1 do begin
    title := 'Open Control File';
    DefaultExt := 'fn';
    Filter := 'Conrolfiles (*.fn)|*.fn';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if not DirectoryExists(InitialDir) then InitialDir := ExtractFileDir(LMod.fModel.ControlFileFn);

    if Execute then begin
      LMod.fModel.ControlFileFn := FileName;
      FPropIniFile.WriteString('Files', 'ControlFile', FileName);
      assignFile(LMod.fModel.ControlFile, LMod.fModel.ControlFileFn);
      reset(LMod.fModel.ControlFile);
      LMod.fModel.FIniFiles := TStringList.create;
      index := 0;
      while not eof(LMod.fModel.ControlFile) do begin
        readln(LMod.fModel.ControlFile, act_IniFn);
        if FileExists(act_IniFn) then begin
          NewInifile := TMyIniFile.create(act_IniFn);
          NewInifile.UpdateFile;
          LMod.fModel.FIniFiles.Add(NewInifile.FileName);
          LMod.fModel.FIniFiles.objects[index] := NewInifile;
          inc(index);
        end else
          MessageDlg('IniFile ' + act_IniFn + ' does not exist !',
            mtInformation, [mbOK], 0);
      end;
      LMod.fModel.actIniFile :=
        TMyIniFile(LMod.fModel.FIniFiles.objects[0]);
      LMod.fModel.init(LMod.fModel.actIniFile);
      self.updateForm;
    end;
  end;

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
  with SaveDialog1, LMod.fModel do begin
    title := title;
    DefaultExt := 'ini';
    Filter := 'IniFiles (*.ini)|*.ini';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then begin
      NewIniFName := ChangeFileExt(FileName, '.ini');
      if FileExists(NewIniFName) then begin
        res := application.MessageBox('Overwrite?', '', MB_OKCANCEL);
        if (res = IDOK) or (not FileExists(NewIniFName)) then begin
          EditFileName.Text := NewIniFName;
          EditIniFileName.Text := NewIniFName;
          actIniFile.WriteString('FileNames', keyname, NewIniFName);
          actIniFile.UpdateFile;
          init(LMod.fModel.actIniFile);
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
    EditStateIniFileName) then begin
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
    EditStateIniFileName) then begin
    SaveParams;
    UpdateStringGridParam;
  end;
end;

procedure TFormMod.changeIni(titlestr, keyname: string;
  EditFileName, EditIniFileName: TEdit);
var
  NewIniFName: string;
begin
  with SaveDialog1, LMod.fModel.actIniFile do begin
    title := titlestr;
    DefaultExt := 'ini';
    Filter := 'IniFiles (*.ini)|*.ini';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then begin
      NewIniFName := ChangeFileExt(FileName, '.ini');
      EditFileName.Text := NewIniFName;
      EditIniFileName.Text := NewIniFName;
      WriteString('FileNames', keyname, NewIniFName);
      UpdateFile;
    end;
  end;
  updateForm;
end;

procedure TFormMod.SpeedButtonDelRowClick(Sender: TObject);
var
  line : integer;
begin
  AdvStringGridData.RemoveSelectedRows;
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
  with SaveDialog1, LMod.fModel.actIniFile do begin
    title := 'New WeatherFile';
    Filter := 'All Files (*.*)|*.*';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then begin
      NewWeatherFName := SaveDialog1.FileName;
      EditWeatherfile.Text := NewWeatherFName;
      WriteString('FileNames', 'WeatherFileFN', NewWeatherFName);
      UpdateFile;
    end;
  end;

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

  procedure setPropFromIniFile(strList: TStringList; submodname: string);
  var
    i: Integer;
    entity: THumeNumEntity;
  begin
    FPropIniFile.UpdateFile;
    for i := 0 to strList.count - 1 do begin
      entity := THumeNumEntity(strList.objects[i]);
      with entity, FPropIniFile do begin
        PlotToGraph := ReadBool(submodname, Name + '.PlotTograpH',
          PlotToGraph);
        WriteFinalValue := ReadBool(submodname, Name + '.WriteFinalValue',
          WriteFinalValue);
        writeToFile := ReadBool(submodname, Name + '.WriteToFile',
          writeToFile);
        SelForSensOut := ReadBool(submodname, Name + '.SelForSensOut',
          SelForSensOut);
      end;
    end;
  end;

begin

  LMod.fModel.InitAllSubMods; // TODO ???

  self.EditControlFile.Text := LMod.fModel.ControlFileFn;

  ComboBoxIniFile.Clear;

  for i := 0 to LMod.fModel.FIniFiles.count - 1 do begin
    ComboBoxIniFile.Items.Add(LMod.fModel.FIniFiles.Strings[i]);
  end;
  ComboBoxIniFile.ItemIndex := 0;
  ComboBoxSubMod.Clear;

  for i := 0 to LMod.fModel.SubModStrList.count - 1 do begin
    ComboBoxSubMod.Items.Add(LMod.fModel.SubModStrList.Strings[i]);
  end;

  ComboBoxSubMod.ItemIndex := 0;

  if LMod.fModel.weatherfile <> nil then
    EditWeatherfile.Text := LMod.fModel.weatherfile.FileName
  else
    EditWeatherfile.Text := 'File not specified';

  // gespeicherte Properties aus *ini Datei einlesen
  for i := 0 to LMod.fModel.SubModStrList.count - 1 do begin
    ActSubMod := TSubModel(LMod.fModel.SubModStrList.objects[i]);
    with ActSubMod do begin
      setPropFromIniFile(stateStrList, Name);
      setPropFromIniFile(VarStrList, Name);
      setPropFromIniFile(ExternVStrList, Name);
    end;
  end;

  UpdateStringGridParam;
  UpdateStringGridState;
  UpdateStringGridVar;
  UpdateStringGridExternV;
  UpdateStringGridOptions;
  UpdateStringGridData;
  UpdatePageIntegration;

  if FileExists(LMod.fModel.reg_fn) then
    update_StringGrid(LMod.fModel.reg_fn);

  UpdatePageResultTab;
  UpdatePageGraphResult;
  ComboBoxIniFile.hint :=
    ComboBoxIniFile.Items[ComboBoxIniFile.ItemIndex];
  SpeedButtonFinalvalues.Visible := LMod.fModel.FinalOutput;

end;

{procedure TFormMod.ConnectionPaint(Sender: TObject);
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
end;  }

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

  //TabSheetModelDiagram

  paintbox := TPaintBox.Create(self);
  paintbox.Parent := self.TabSheetModelDiagram;
  paintbox.align := alClient;
//  paintbox.OnPaint := ConnectionPaint;
  //paintbox.Visible := True;
  //paintbox.Show;

end;

procedure TFormMod.ShowDataFile(FFileName: string);
var
  i: Integer;
begin
  with AdvStringGridResults do begin
    BeginUpdate;
    FixedRows := 2;
    fixedcols := 1;
    LoadFromCSV(FFileName);
    if CheckBoxDataDateFormat.Checked then
      for i := 1 to RowCount - 1 do
        cells[0, i + 1] := datetimetostr(strtofloat(cells[0, i + 1]));
    Endupdate;
  end;
end;

procedure TFormMod.TabSheetResultTabEnter(Sender: TObject);
begin
  UpdatePageResultTab;
end;

procedure TFormMod.PrintButtonClick(Sender: TObject);
begin
  if PrintDialog1.Execute then
    Chart1.PrintLandscape;
end;

procedure TFormMod.SensitivityAnalysisClick(Sender: TObject);
begin
  if FormSensOpt = nil then
    application.CreateForm(TFormSensOpt, FormSensOpt);
  FormSensOpt.Model := LMod.fModel;
  FormSensOpt.FPropIniFile := FPropIniFile;
  FormSensOpt.FormActivate;
  FormSensOpt.showmodal;
end;

procedure TFormMod.EditStartTimeChange(Sender: TObject);
begin
  inherited;
  if StartTimePicker.date < LMod.fModel.FirstWeatherData then
    EditStartTime.font.color := clRed
  else
    EditStartTime.font.color := clBlack;

  StartTimePicker.date := StrToINt(EditStartTime.Text);
end;

procedure TFormMod.EditEndTimeChange(Sender: TObject);
begin
  inherited;
  if StrToINt(EditEndTime.Text) > LMod.fModel.LastWeatherData then
    EditEndTime.font.color := clRed
  else
    EditEndTime.font.color := clBlack;

  EndTimePicker.date := StrToINt(EditEndTime.Text);
end;

procedure TFormMod.StartTimePickerChange(Sender: TObject);
begin
  inherited;
  EditStartTime.Text := FloatToStr(TRUNC(StartTimePicker.date));
end;

procedure TFormMod.EndTimePickerChange(Sender: TObject);
begin
  inherited;
  EditEndTime.Text := FloatToStr(TRUNC(EndTimePicker.date));
end;

procedure TFormMod.TabSheetGraphResultEnter(Sender: TObject);
begin
  self.UpdatePageGraphResult;
end;

procedure TFormMod.SpeedButtonOpenDataFileClick(Sender: TObject);
var
  IniFile: TMyIniFile;
  actInifileIndex, actSubModIndex: Integer;
  SubModel: TSubModel;
  NewDataFName: string;
begin
  with SaveDialog1 do begin
    title := 'New DataFile';
    Filter := 'All Files (*.*)|*.*';
    Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
    if Execute then begin
      NewDataFName := FileName;
      EditDataFileName.Text := NewDataFName;
      actInifileIndex := ComboBoxIniFile.ItemIndex;
      actSubModIndex := ComboBoxSubMod.ItemIndex;
      IniFile :=
        TMyIniFile(LMod.fModel.FIniFiles.objects[actInifileIndex]);
      SubModel :=
        TSubModel(LMod.fModel.SubModStrList.objects[actSubModIndex]);
      IniFile.WriteString('MeasurementFiles', SubModel.name,
        NewDataFName);
      IniFile.UpdateFile;
      LMod.fModel.init(LMod.fModel.actIniFile);
      LMod.fModel.InitAllSubMods;
      UpdateStringGridData;
    end;
  end;
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
  LabelActIniFileDesc.hint :=
    ComboBoxIniFile.Items[ComboBoxIniFile.ItemIndex];
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

procedure TFormMod.EditWeatherfileMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  EditWeatherfile.hint := EditWeatherfile.Text;
  EditWeatherfile.ShowHint := True;
  EditWeatherfile.Repaint;
end;

procedure TFormMod.ChisquareAnalysisClick(Sender: TObject);
begin
  if FormChiSqOpt = nil then
    application.CreateForm(TFormChiSqOpt, FormChiSqOpt);
  FormChiSqOpt.Model := LMod.fModel;
  FormChiSqOpt.FormActivate;
  FormChiSqOpt.showmodal;
end;

procedure TFormMod.GAOptClic(Sender: TObject);
begin
  if FormGAopt = nil then
    application.CreateForm(TFormGAOpt, FormGAopt);
  FormGAopt.sga.Model := LMod.fModel;
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
  if nFormGraph <= 10 then begin
    application.CreateForm(TFormGraph, FormGraphArray[nFormGraph]);
    FormGraphArray[nFormGraph].show;
  end else
    showmessage('Mehr als 10 Graph-Fenster geöffnet');
end;

procedure TFormMod.OptimizeClick(Sender: TObject);
begin
  if FormOpt = nil then
    application.CreateForm(TFormOpt, FormOpt);
  LMod.fModel.InitAllDataSeries;
  FormOpt.Model := LMod.fModel;
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
  if LMod.LinkedModel <> nil then
    Result := LMod.LinkedModel
  else begin
    showmessage('LMod.LinkedModel darf nicht undefiniert sein!');
    exit;
  end;
end;

procedure TFormMod.testSubModIndex(n: Integer);
begin
  if n < 0 then begin
    showmessage('Kein aktives Submodel gefunden!');
    exit;
  end;
end;

procedure TFormMod.btnSaveasPNGClick(Sender: TObject);
var
  PNG: TPNGImage;
  tmpBitmap: TBitmap;
  saveDialog: TSaveDialog;
  idx: integer;
  inifile: TMyIniFile;
begin
  idx := ComboBoxIniFile.ItemIndex;
  inifile := TMyIniFile(LMod.fModel.FIniFiles.objects[idx]);

  saveDialog := TSaveDialog.create(self);
  with saveDialog do begin
    title := 'Save your Chart';
    Filter := 'PNG File|*.png';
    DefaultExt := 'png';
    FilterIndex := 1;
    FileName := ChangeFileExt(ExtractFileName(inifile.FileName),'.png');
  end;

  PNG := TPNGImage.create;
  tmpBitmap := TBitmap.create;

  try
    with tmpBitmap do begin
      Width := Chart1.Width;
      Height := Chart1.Height;
      Chart1.Draw(Canvas, Rect(0, 0, Width, Height));
    end;
    PNG.assign(tmpBitmap);
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
  IniFile := TMyIniFile(LMod.fModel.FIniFiles.objects[actInifileIndex]);
  LMod.fModel.init(IniFile);
  LMod.fModel.InitAllSubMods;

  if self.LMod.LinkedModel <> nil then
    LMod.LinkedModel.InitAllExternV;

  showmessage('No problems found');

  UpdateStringGridState();
  UpdateStringGridExternV;
end;

procedure TFormMod.CheckButtonClick(Sender: TObject);
begin
  InitAllAndCheckExternalV();
end;

end.

