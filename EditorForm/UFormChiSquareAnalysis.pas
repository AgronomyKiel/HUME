unit UFormChiSquareAnalysis;

interface

uses Windows, SysUtils, Classes, vcl.Graphics, vcl.Forms, vcl.Controls, vcl.StdCtrls,
  vcl.Buttons, Umod, vcl.ComCtrls, vcl.Grids, AdvGrid, vcl.ExtCtrls,
  VCLTee.TeeProcs, VCLTee.TeEngine, VCLTee.Chart, BaseGrid,  vcl.Mask,
  advspin, VCLTee.Series, UTextFileH, VclTee.TeeGDIPlus, Vcl.Samples.Spin
  ;

const
  MaxSeries = 20;

type

  TLineSeriesArr = array[0..MaxSeries - 1] of TFastLineSeries;
  TPointSeriesArr = array[0..MaxSeries - 1] of TPointSeries;

type
  real = double;
  TFormChiSqOpt = class(TForm)
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheetOptions: TTabSheet;
    LabelDataAvailable: TLabel;
    LabelDataselected: TLabel;
    IncludeBtnData: TSpeedButton;
    IncAllBtnData: TSpeedButton;
    ExcludeBtnData: TSpeedButton;
    ExAllBtnData: TSpeedButton;
    Label3: TLabel;
    Label4: TLabel;
    LabelIniValue: TLabel;
    LabelFinalValue: TLabel;
    LabelSensSteps: TLabel;
    LabelStartvalue: TLabel;
    OKBtn: TButton;
    SrcListData: TListBox;
    DstListData: TListBox;
    EditActualValue: TEdit;
    EditFinalvalue: TEdit;
    ComboBoxParameter: TComboBox;
    EditInitialValue: TEdit;
    ButtonRunSens: TButton;
    TabSheetResults: TTabSheet;
    AdvStrGrdEndResultTab: TAdvStringGrid;
    TabSheetGraph: TTabSheet;
    Chart1: TChart;
    SpinEditSensSteps: TSpinEdit;
    procedure IncludeBtnDataClick(Sender: TObject);
    procedure ExcludeBtnDataClick(Sender: TObject);
    procedure IncAllBtnDataClick(Sender: TObject);
    procedure ExcAllBtnDataClick(Sender: TObject);
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetItem(List: TListBox; Index: Integer);
    function GetFirstSelection(List: TCustomListBox): Integer;
    procedure SetButtons;
    procedure FormActivate;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure OKBtnClick(Sender: TObject);
    procedure ComboBoxParameterChange(Sender: TObject);
    procedure UebernehmenBtnClick(Sender: TObject);
    procedure ButtonRunSensClick(Sender: TObject);
    procedure update_StringGrid(fn: string);
    procedure UpdatePageGraphResult(fn: string);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    model: TMod;
  end;

var
  FormChiSqOpt: TFormChiSqOpt;

implementation

uses
  vcl.Dialogs, Ustate, UMeasValue, UFormRichTExt, IniFiles, UModUtils;

{$R *.DFM}

procedure TFormChiSqOpt.IncludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListData);
  MoveSelected(SrcListData, DstListData.Items);
  SetItem(SrcListData, Index);
end;

procedure TFormChiSqOpt.ExcludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstListData);
  MoveSelected(DstListData, SrcListData.Items);
  SetItem(DstListData, Index);
end;

procedure TFormChiSqOpt.IncAllBtnDataClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcListData.Items.Count - 1 do
    DstListData.Items.AddObject(SrcListData.Items[I],
      SrcListData.Items.Objects[I]);
  SrcListData.Items.Clear;
  SetItem(SrcListData, 0);
end;

procedure TFormChiSqOpt.ExcAllBtnDataClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstListData.Items.Count - 1 do
    SrcListData.Items.AddObject(DstListData.Items[I],
      DstListData.Items.Objects[I]);
  DstListData.Items.Clear;
  SetItem(DstListData, 0);
end;

procedure TFormChiSqOpt.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;

procedure TFormChiSqOpt.SetButtons;
var
  SrcEmptyData, DstEmptyData: Boolean;
begin
  SrcEmptyData := SrcListData.Items.Count = 0;
  DstEmptyData := DstListData.Items.Count = 0;
  IncludeBtnData.Enabled := not SrcEmptyData;
  IncAllBtnData.Enabled := not SrcEmptyData;
  ExcludeBtndata.Enabled := not DstEmptyData;
  ExAllBtnData.Enabled := not DstEmptyData;
end;

function TFormChiSqOpt.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TFormChiSqOpt.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then Index := 0
    else if Index > MaxIndex then Index := MaxIndex;
    Selected[Index] := True;
  end;
  SetButtons;
end;

procedure TFormChiSqOpt.FormActivate;

var
  i, j: Integer;
  SubMod: TSubModel;
  ActPar: TPar;
  ActState: TState;
  ActVar: TVar;

begin

  SrcListData.clear;
  DstListData.clear;

  for i := 0 to Model.SubModStrList.Count - 1 do begin
    SubMod := TSubModel(Model.SubModStrList.Objects[i]);
    for j := 0 to SubMod.ParStrList.count - 1 do begin
      ActPar := TPar(SubMod.ParStrList.objects[j]);
      ComboBoxParameter.Items.Add(SubMod.name + '.' + ActPar.name);
    end;
    if SubMod.StateStrList <> nil then begin
      for j := 0 to SubMod.StateSTrList.count - 1 do begin
        ActState := TState(SubMod.StateStrList.objects[j]);
        if ActState.IsMeasured then
          SrcListData.Items.add(SubMod.name + '.' + ActState.name);
      end;
    end;
    if SubMod.VarStrList <> nil then begin
      for j := 0 to SubMod.VarSTrList.count - 1 do begin
        ActVar := TVar(SubMod.VarStrList.objects[j]);
        if ActVar.IsMeasured then
          SrcListData.Items.add(SubMod.name + '.' + ActVar.name);
      end;
    end;
  end;
end;

procedure TFormChiSqOpt.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  self.ComboBoxParameter.clear;
  self.SrcListData.clear;
  self.DstListData.clear;
  self.EditActualValue.Text := '';
  self.EditFinalvalue.text := '';
  self.editInitialValue.text := '';
end;

procedure TFormChiSqOpt.OKBtnClick(Sender: TObject);

begin
  close;
end;

procedure TFormChiSqOpt.ComboBoxParameterChange(Sender: TObject);

var
  Name: string;
  ActPar: Tpar;
  SubModName: string;
  success: boolean;
begin
  name := self.ComboBoxParameter.items[ComboBoxParameter.Itemindex]; // SelText;
  name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
  model.GetParameter(name, Actpar, subModName, success);
  if success then begin
    EditActualValue.Text := floatToStrF(Actpar.v, ffgeneral, 8, 6);
    EditInitialValue.text := floatToStrF(Actpar.v * 0.5, ffgeneral, 8, 6);
    EditFinalValue.text := floatToStrF(Actpar.v * 1.5, ffgeneral, 8, 6);

  end;
end;

procedure TFormChiSqOpt.UebernehmenBtnClick(Sender: TObject);

var
  Name,
    SubModName: string;
  success: boolean;
  Actpar: TPar;
  ActState: TState;
  ActVar: Tvar;
  i: integer;

begin
  name := ComboBoxParameter.items[ComboBoxParameter.Itemindex]; // SelText;
  model.GetParameter(name, Actpar, subModName, success);
  if success then begin
    model.SensOpt.SelSensPar := ActPar;
    model.SensOpt.MaxValue := StrTofloat(editfinalvalue.text);
    model.SensOpt.MinValue := StrTofloat(editInitialvalue.text);
    Model.sensOpt.Steps    := SpinEditSensSteps.Value;
    model.SensOpt.DPar := (model.sensOpt.maxValue - model.sensopt.minValue) /
      (Model.SensOpt.Steps - 1);
    Model.SensOpt.FOutList.Clear;
    for I := 0 to DStListData.Items.Count - 1 do begin
      Name := DstListData.items[i];
      name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
      Model.SensOpt.fOutList.Add(Name);
      model.GetStateVar(Name, ActSTate, SubModName, success);
      if success then
        Model.SensOpt.FOutList.Objects[i] := ActState
      else begin
        model.GetVariable(Name, ActVar, SubModName, success);
        if success then
          Model.SensOpt.FOutList.Objects[i] := ActVar
        else
          ShowMessage('Problem: ' + name + ' not found');
      end;
//      model.
    end;
  end;
end;

procedure TFormChiSqOpt.update_StringGrid(fn: string);

var
  f: textFile;
  i: integer;
  line: string;
begin
  if FileExists(fn) then begin
    assignfile(f, fn);
    reset(f);
    for i := 0 to AdvStrGrdEndResultTab.RowCount - 1 do
      AdvStrGrdEndResultTab.Rows[i].clear;
    i := 0;
    while not eof(f) do begin
      readln(f, line);
      if AdvStrGrdEndResultTab.RowCount < i + 1 then
        AdvStrGrdEndResultTab.rowcount := AdvStrGrdEndResultTab.rowcount + 1;
      AdvStrGrdEndResultTab.Rows[i].commatext := line;
      inc(i);
    end;
    AdvStrGrdEndResultTab.Repaint;
    closefile(f);
  end else
    ShowMessage('File ' + fn + ' not found !');
end;

procedure TFormChiSqOpt.ButtonRunSensClick(Sender: TObject);

var
  Name,
    SubModName,
    DataSeriesName: string;
  success: boolean;
  SubMod: TSubModel;
  Actpar: TPar;
  SaveParValue: real;
  ActState: TState;
  ActVar: Tvar;
  i, j, index: integer;
  DataSeries: TMeasList;

begin
  name := ComboBoxParameter.items[ComboBoxParameter.Itemindex]; // SelText;
  name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
    // Delete Submodelname from string

  model.GetParameter(name, Actpar, subModName, success);

  if success then begin
    SaveParValue := ActPar.fv;
    model.SensOpt.SelSensPar := ActPar;
    model.SensOpt.MaxValue := StrTofloat(editfinalvalue.text);
    model.SensOpt.MinValue := StrTofloat(editInitialvalue.text);
    Model.sensOpt.Steps      := SpinEditSensSteps.Value;
    model.SensOpt.DPar := (model.sensOpt.maxValue - model.sensopt.minValue) /
      (Model.SensOpt.Steps - 1);
    Model.SensOpt.FOutList.Clear;
    for I := 0 to DStListData.Items.Count - 1 do begin
      Name := DstListData.items[i];
      name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
        // Delete Submodelname from string
      Model.SensOpt.fOutList.Add(Name);
      model.GetStateVar(Name, ActSTate, SubModName, success);
      if success then
        Model.SensOpt.FOutList.Objects[i] := ActState
      else begin
        model.GetVariable(Name, ActVar, SubModName, success);
        if success then
          Model.SensOpt.FOutList.Objects[i] := ActVar
        else
          ShowMessage('Problem: ' + name + ' not found');

      end;

    end;

    ActPar.fv := SaveParValue;
  end;

  for I := 0 to DstListData.Items.Count - 1 do begin
    DataSeriesName := DstListData.items[i];
    DataSeriesname := copy(DataSeriesname, pos('.', DataSeriesname) + 1,
      length(DataSeriesname) - pos('.', DataSeriesname));
      // Delete Submodelname from string
    for j := 0 to model.SubModStrList.count - 1 do begin
      SubMod := TsubModel(Model.subModStrList.objects[j]);
      if SubMOd.SomethingMeasured then begin
        index := subMod.DataList.IndexOf(DataSeriesName);
        if index <> -1 then begin
          DataSeries := TMeasList(SubMod.DataList.objects[index]);
          DataSeries.SelForOpt := true;
        end;
      end;
    end;
  end;

  model.CalcChiSquareSensitivity;

  update_stringGrid(model.sensOpt.sens_fn);
  UpdatePageGraphResult(model.sensOpt.sens_fn);
  PageControl1.ActivePage := TabSheetResults;


end;

procedure TFormChiSqOpt.UpdatePageGraphResult(fn: string);

var
   i, n_lineSeries: integer;
  x, y: real;
  f : textfile;
  line : string;
  color: TColor;
  ActLineSeries: TFastLineSeries;
  ActPointSeries: TPointSeries;
  ActVar : Tvar;
  LineSeriesArr : TLineSeriesArr;
  DataFileSim : TTextFileH;

begin
  chart1.BottomAxis.Title.Caption := model.SensOpt.SelSenspar.Name + ' ' +
    model.SensOpt.SelSenspar.u;
  chart1.RemoveAllSeries;
  color := ClBlue;
  n_lineSeries := -1;
  inc(n_lineSeries);
  LineSeriesArr[n_lineseries] := TFastLineSeries.create(Chart1);
  ActLineSeries := LineSeriesArr[n_lineseries];
  ActLineSeries.Seriescolor := ClTeecolor;
  LineSeriesArr[n_lineseries].title := 'ChiSquaredValue';
  ActLineSeries.LinePen.Width := 2;
  Chart1.AddSeries(LineSeriesArr[n_lineseries]);

    if fileexists(fn) then begin
       DataFileSim := TTextFileH.create;
       DataFileSim.init(fn);
       DataFileSim.GoTop;
       while DataFileSim.hasMoreLines do begin
           DataFileSim.NextLine;
           x := DataFileSim.getIndexValue(0);
           y := DataFileSim.getIndexValue(2);
           LineSeriesArr[n_lineseries].addxy(x, y, '', ClteeColor);
       end;
     Datafilesim.free;
     inc(color);
   end;
  Chart1.Update;
  Screen.Cursor := crDefault;
end;

procedure TFormChiSqOpt.FormShow(Sender: TObject);
begin
  self.PageControl1.ActivePage := TabSheetOptions;
end;

end.

