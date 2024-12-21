unit UFormSelPar;

interface

uses Windows, SysUtils, Classes, vcl.Graphics, vcl.Forms, vcl.Controls, vcl.StdCtrls,
  vcl.Buttons, Umod, vcl.ComCtrls, vcl.Grids, AdvGrid, vcl.Mask,
  advspin, vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.TeEngine, VCLTee.Series, VCLTee.Chart, UTextFileH,
  BaseGrid, math, VclTee.TeeGDIPlus, Vcl.Samples.Spin;

const
  MaxSeries = 50;

type

  TLineSeriesArr = array[0..MaxSeries - 1] of TFastLineSeries;
  TPointSeriesArr = array[0..MaxSeries - 1] of TPointSeries;

type
  real = double;
  TFormSensOpt = class(TForm)
    StatusBarSens: TStatusBar;
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
    UebernehmenBtn: TButton;
    SrcListData: TListBox;
    DstListData: TListBox;
    EditActualValue: TEdit;
    EditFinalvalue: TEdit;
    ComboBoxParameter: TComboBox;
    EditInitialValue: TEdit;
    ButtonRunSens: TButton;
    TabSheetResultsSingleRun: TTabSheet;
    AdvStrGrdEndResultTab: TAdvStringGrid;
    TabSheetGraphSingleRun: TTabSheet;
    Chart1: TChart;
    TabSheetResultsMultRun: TTabSheet;
    SpinEditSensSteps: TSpinEdit;
    ButtonRunMultSens: TButton;
    EditFileNameMultRunFinal: TEdit;
    AdvStringGridMultRunFinal: TAdvStringGrid;
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
    procedure update_StringGrid(StrGrd: TAdvStringGrid; fn: string);
    procedure UpdatePageGraphResult(fn: string);
    procedure FormShow(Sender: TObject);
    procedure ButtonRunMultSensClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    model: TMod;
    FPropIniFile : TMyIniFile;
  end;

var
  FormSensOpt: TFormSensOpt;

implementation

uses
  vcl.Dialogs, Ustate, UMeasValue, UFormRichTExt, IniFiles, UModUtils;

{$R *.DFM}

procedure TFormSensOpt.IncludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListData);
  MoveSelected(SrcListData, DstListData.Items);
  SetItem(SrcListData, Index);
end;

procedure TFormSensOpt.ExcludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstListData);
  MoveSelected(DstListData, SrcListData.Items);
  SetItem(DstListData, Index);
end;

procedure TFormSensOpt.IncAllBtnDataClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcListData.Items.Count - 1 do
    DstListData.Items.AddObject(SrcListData.Items[I],
      SrcListData.Items.Objects[I]);
  SrcListData.Items.Clear;
  SetItem(SrcListData, 0);
end;

procedure TFormSensOpt.ExcAllBtnDataClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstListData.Items.Count - 1 do
    SrcListData.Items.AddObject(DstListData.Items[I],
      DstListData.Items.Objects[I]);
  DstListData.Items.Clear;
  SetItem(DstListData, 0);
end;

procedure TFormSensOpt.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;

procedure TFormSensOpt.SetButtons;
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

function TFormSensOpt.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TFormSensOpt.SetItem(List: TListBox; Index: Integer);
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

procedure TFormSensOpt.FormActivate;

var
  i, j, k: Integer;
  SubMod: TSubModel;
  ActPar: TPar;
  ActState: TState;
  ActVar: TVar;
  Name, submodname: string;

begin
//  FpropInifile := self.
  SrcListData.clear;
  DstListData.clear;
  for i := 0 to Model.SubModStrList.Count - 1 do begin
    SubMod := TSubModel(Model.SubModStrList.Objects[i]);
    for j := 0 to SubMod.ParStrList.count - 1 do begin
      ActPar := TPar(SubMod.ParStrList.objects[j]);
      ComboBoxParameter.Items.Addobject(SubMod.name + '.' + ActPar.name, ActPar);
    end;
  end;

  for i := 0 to self.ComboBoxParameter.Items.Count-1 do begin
      ActPar := TPar(ComboBoxParameter.Items.objects[i]);
      Name   := self.ComboBoxParameter.Items[i];
      Submodname := copy(name, 1,  pos('.', name)-1);
      ActPar.SelForSens := FPropIniFile.ReadBool(SubMod.Name, ActPar.Name+'.SelForSens', false);
      if ActPar.SelForSens then begin
        k := self.ComboBoxParameter.Items.IndexOf(Submodname+'.'+ActPar.name);
        ComboBoxParameter.SelText := ActPar.Name;
        self.ComboBoxParameter.ItemIndex := k;
        ComboBoxParameterChange(self);
    end;
  end;

  for i := 0 to Model.SubModStrList.Count - 1 do begin
    SubMod := TSubModel(Model.SubModStrList.Objects[i]);
    if SubMod.StateStrList <> nil then begin
      for j := 0 to SubMod.StateSTrList.count - 1 do begin
        ActState := TState(SubMod.StateStrList.objects[j]);
        ActState.SelForSensOut    := FPropIniFile.ReadBool(Submod.Name, ActSTate.name+'.SelForSensOut', false);
        if ActState.SelForSensOut = false then
          SrcListData.Items.add(SubMod.name + '.' + ActState.name);
        if ActState.SelForSensOut = true then
          self.DstListData.Items.add(SubMod.name + '.' + ActState.name);
      end;
    end;
    if SubMod.VarStrList <> nil then begin
      for j := 0 to SubMod.VarSTrList.count - 1 do begin
        ActVar := TVar(SubMod.VarStrList.objects[j]);
        ActVar.SelForSensOut    := FPropIniFile.ReadBool(Submod.Name, ActVar.name+'.SelForSensOut', false);
        if ActVar.SelForSensOut = false then
          SrcListData.Items.add(SubMod.name + '.' + ActVar.name);
        if ActVar.SelForSensOut = true then
          DstListData.Items.add(SubMod.name + '.' + ActVar.name);
      end;
    end;
  end;
  self.EditFinalvalue.Text     := floattostrf(model.SensOpt.MaxValue, ffgeneral, 8,2);
  self.EditInitialValue.text   := floattostrf(model.SensOpt.MinValue, ffgeneral,8,2);
  self.SpinEditSensSteps.Value := model.SensOpt.Steps;
end;

procedure TFormSensOpt.FormClose(Sender: TObject;
  var Action: TCloseAction);

begin
  self.ComboBoxParameter.clear;
  self.SrcListData.clear;

  self.DstListData.clear;
  self.EditActualValue.Text := '';
  self.EditFinalvalue.text := '';
  self.editInitialValue.text := '';
end;

procedure TFormSensOpt.OKBtnClick(Sender: TObject);

begin
  close;
end;

procedure TFormSensOpt.ComboBoxParameterChange(Sender: TObject);

var
  Fullname, parName: string;
  ActPar: Tpar;
  ActSubMod: TSubmodel;
  index, i: integer;
  SubModName: string;
  success: boolean;
begin
  success := false;
  fullname := self.ComboBoxParameter.items[ComboBoxParameter.Itemindex];
    // SelText;
  Parname := copy(fullname, pos('.', fullname) + 1, length(fullname) - pos('.',
    fullname));
  SubModName := copy(fullname, 1, pos('.', fullname) - 1);
  index := self.model.SubmodStrlist.indexof(SubmodName);

  if Index <> -1 then begin
    ActSubMod := TSubmodel(model.SubmodStrlist.objects[index]);
    //   pars := ActSubMod.ParStrList.CommaText;
    i := 0;
    repeat
      ActPar := TPar(ActSubMod.ParStrList.objects[i]);
      if ActPar.Name = Parname then begin
        success := true;
        ActPar.SelForSens := true;
      end;
      inc(i);
    until success or (i >= ActSubMod.ParStrList.count);

    if success then begin
      EditActualValue.Text := floatToStrF(Actpar.v, ffgeneral, 8, 6);
      EditInitialValue.text := floatToStrF(Actpar.v * 0.5, ffgeneral, 8, 6);
      EditFinalValue.text := floatToStrF(Actpar.v * 1.5, ffgeneral, 8, 6);

    end;
  end;
end;

procedure TFormSensOpt.UebernehmenBtnClick(Sender: TObject);

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
    Model.sensOpt.Steps      := SpinEditSensSteps.Value;
    model.SensOpt.DPar := (model.sensOpt.maxValue - model.sensopt.minValue) /
      (Model.SensOpt.Steps - 1);
    Model.SensOpt.FOutList.Clear;
    for I := 0 to DStListData.Items.Count - 1 do begin
      Name := DstListData.items[i];
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

procedure TFormSensOpt.update_StringGrid(StrGrd: TAdvStringGrid; fn: string);

var
  f: textFile;
  i: integer;
  line: string;
  StrLst: TSTringlist;
begin
   StrLst := TStringlist.create;
  if FileExists(fn) then begin
    assignfile(f, fn);
    reset(f);
    for i := 0 to StrGrd.RowCount - 1 do
      StrGrd.Rows[i].clear;
    i := 0;
    while not eof(f) do begin
      readln(f, line);
      StrLst.CommaText := line;
      StrGrd.ColCount := StrLst.Capacity;
      if StrGrd.RowCount < i + 1 then
        StrGrd.rowcount := StrGrd.rowcount + 1;
      StrGrd.Rows[i].commatext := line;
      inc(i);
    end;
    StrGrd.Repaint;
    closefile(f);
  end else
    ShowMessage('File ' + fn + ' not found !');
end;



procedure TFormSensOpt.ButtonRunMultSensClick(Sender: TObject);
var
  Name, Fullname,
    SubModName: string;
  success: boolean;
  Actpar: TPar;
  SaveParValue: real;
  ActState: TState;
  ActVar: Tvar;
  i: integer;

begin

  name := ComboBoxParameter.items[ComboBoxParameter.Itemindex]; // SelText;
  name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
    // Delete Submodelname from string

  model.GetParameter(name, Actpar, subModName, success);
  ActPar.SelForSens := true;
  FPropIniFile.WriteBool(SubModName, SubModName+'.'+ActPar.Name+'.SelForSens', ActPar.SelForSens);
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
      FullName := DstListData.items[i];
      name := copy(Fullname, pos('.', Fullname) + 1, length(Fullname) - pos('.', Fullname));
      subModName := copy(Fullname, 1, pos('.', Fullname)-1);
      Model.SensOpt.fOutList.Add(Name);
      model.GetStateVar(Name, ActSTate, SubModName, success);
      if success then begin
        Model.SensOpt.FOutList.Objects[i] := ActState;
        ActState.Opt_SelForSensOut := true;
        FPropIniFile.WriteBool(SubModName, ActState.Name+'.SelForSensOut', ActState.SelForSensOut);
      end else begin
        model.GetVariable(Name, ActVar, SubModName, success);
        if success then begin
          Model.SensOpt.FOutList.Objects[i] := ActVar;
          ActVar.Opt_SelForSensOut := true;
          FPropIniFile.WriteBool(SubModName, ActVar.Name+'.SelForSensOut', ActVar.SelForSensOut);
        end

        else
          ShowMessage('Problem: ' + name + ' not found');
      end;
    end;

 // for all non selected Items set and write SelForSensOut FALSE
    for I := 0 to SrcListData.Items.Count - 1 do begin
      FullName := SrcListData.items[i];
      name := copy(Fullname, pos('.', Fullname) + 1, length(Fullname) - pos('.', Fullname));
      subModName := copy(Fullname, 1, pos('.', Fullname)-1);
      model.GetStateVar(Name, ActSTate, SubModName, success);
      if success then begin
        ActState.Opt_SelForSensOut := false;
        FPropIniFile.WriteBool(SubModName, ActState.Name, ActState.SelForSensOut);
      end else begin
        model.GetVariable(Name, ActVar, SubModName, success);
        if success then begin
          ActVar.Opt_SelForSensOut := false;
          FPropIniFile.WriteBool(SubModName, ActVar.Name, ActVar.SelForSensOut);
        end

        else
          ShowMessage('Problem: ' + name + ' not found');
      end;
    end;
    FPropIniFile.UpdateFile;
    model.CalcSensitivityMultRun;
    ActPar.fv := SaveParValue;

    update_StringGrid(self.AdvStringGridMultRunFinal, model.SensOpt.MultSens_fn_final);
    self.EditFileNameMultRunFinal.Text := model.SensOpt.MultSens_fn_final;
//    UpdatePageGraphResult(self.model.sensOpt.sens_fn);
//    PageControl1.ActivePage := TabSheetResults;
  end;
end;

procedure TFormSensOpt.ButtonRunSensClick(Sender: TObject);

var
  Name,
    SubModName: string;
  success: boolean;
  Actpar: TPar;
  SaveParValue: real;
  ActState: TState;
  ActVar: Tvar;
  i: integer;

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

    model.CalcSensitivity;
    ActPar.fv := SaveParValue;

    update_stringGrid(self.AdvStrGrdEndResultTab, self.model.sensOpt.sens_fn);
    UpdatePageGraphResult(self.model.sensOpt.sens_fn);
    PageControl1.ActivePage := self.TabSheetGraphSingleRun;
  end;

end;

procedure TFormSensOpt.UpdatePageGraphResult(fn: string);

var
  i,
    n_lineSeries: integer;
  x, y: real;

  ActLineSeries: TFastLineSeries;

  ActVar: Tvar;
  LineSeriesArr: TLineSeriesArr;
  DataFileSim: TTextFileH;

begin
  chart1.BottomAxis.Title.Caption := model.SensOpt.SelSenspar.Name + ' ' +
    model.SensOpt.SelSenspar.u;
  chart1.RemoveAllSeries;
  //color := ClBlue;
  n_lineSeries := -1;

  for i := 0 to self.DstListData.items.count - 1 do begin

    ActVar := TVar(model.SensOpt.FOutList.Objects[i]);
    inc(n_lineSeries);
    LineSeriesArr[n_lineseries] := TFastLineSeries.create(Chart1);
    ActLineSeries := LineSeriesArr[n_lineseries];
    ActLineSeries.Seriescolor := ClTeecolor;
    LineSeriesArr[n_lineseries].title := ActVar.name + ' ' + ActVar.U;
    ActLineSeries.LinePen.Width := 2;
    Chart1.AddSeries(LineSeriesArr[n_lineseries]);

    if fileexists(fn) then begin
       {if DataFileSim <> nil then begin
          DataFileSim.init(fn);
      end else }begin
         //KLUSS DataFileSim := TTextFileH.create;
         //KLUSS DataFileSim.init(fn);
        DataFileSim := TTextFileH.create;
        DataFileSim.indexOf(fn);
      end;
      DataFileSim.GoTop;

       //while not eof(DataFileSim.f) do begin
      while DataFileSim.hasMoreLines() do begin
        DataFileSim.NextLine;
        x := DataFileSim.getIndexValue(0);
        y := DataFileSim.getValue(ActVar.name);
        if not isnan(y) then

        LineSeriesArr[n_lineseries].addxy(x, y, '', ClteeColor);
      end;
      //closefile(DataFileSim);
     Datafilesim.CleanupInstance;
     //inc(color);
    end;
  end;

  Chart1.Update;

  Screen.Cursor := crDefault;
end;

procedure TFormSensOpt.FormShow(Sender: TObject);
begin
  self.PageControl1.ActivePage := TabSheetOptions;
end;

end.

