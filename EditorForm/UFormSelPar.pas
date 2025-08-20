unit UFormSelPar;

interface

uses Windows, SysUtils, Classes, vcl.Graphics, vcl.Forms, vcl.Controls,
  vcl.StdCtrls,
  vcl.Buttons, Umod, vcl.ComCtrls, vcl.Grids, AdvGrid, vcl.Mask,
  advspin, vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.TeEngine, VCLTee.Series,
  VCLTee.Chart, UTextFileH,
  BaseGrid, math, VCLTee.TeeGDIPlus, vcl.Samples.Spin;

const
  MaxSeries = 50;

type

  TLineSeriesArr = array [0 .. MaxSeries - 1] of TFastLineSeries;
  TPointSeriesArr = array [0 .. MaxSeries - 1] of TPointSeries;

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
    procedure AcceptButtonClick(Sender: TObject);
    procedure ButtonRunSensClick(Sender: TObject);
    procedure update_StringGrid(StrGrd: TAdvStringGrid; fn: string);
    procedure UpdatePageGraphResult(fn: string);
    procedure FormShow(Sender: TObject);
    procedure ButtonRunMultSensClick(Sender: TObject);
    procedure SaveSettings;
  private
    { Private declarations }
  public
    { Public declarations }
    model: TMod;
    FPropIniFile: TMyIniFile;
  end;

procedure MoveItemsByList(const FromLB, ToLB: TListBox; const ToMove: TStrings;
  const AllowDuplicatesInDest: Boolean = True);

var
  FormSensOpt: TFormSensOpt;

implementation

uses
  vcl.Dialogs, Ustate, UMeasValue, UFormRichTExt, IniFiles, UModUtils;

{$R *.DFM}

const
  // File names and section keys for INI file access
  fnSensIni = 'SensSettings.ini';
  SectionSelPar = 'SelPar';
  KeySelPar = 'SelPar';
  SectionValues = 'Values';
  SectionDestPars = 'DSTListBox';
  KeyActVal = 'ActVal';
  KeyIniVal = 'IniVal';
  KeyFinalVal = 'FinalVal';
  KeySteps = 'Steps';
  KeyOutVals = 'DSTListBox';

procedure MoveItemsByList(const FromLB, ToLB: TListBox; const ToMove: TStrings;
  const AllowDuplicatesInDest: Boolean = True);
var
  LSet: TStringList;
  i: Integer;
  S: string;
  Obj: TObject;
begin
  // Build a fast lookup set from ToMove (sorted list + binary search)
  LSet := TStringList.Create;
  try
    LSet.Sorted := True;
    LSet.Duplicates := dupIgnore;
    LSet.Assign(ToMove);

    FromLB.Items.BeginUpdate;
    ToLB.Items.BeginUpdate;
    try
      // Walk backwards to safely delete from the source
      for i := FromLB.Items.Count - 1 downto 0 do
      begin
        S := FromLB.Items[i];
        if LSet.IndexOf(S) >= 0 then
        begin
          if AllowDuplicatesInDest or (ToLB.Items.IndexOf(S) < 0) then
          begin
            Obj := FromLB.Items.Objects[i]; // preserve associated object
            ToLB.Items.AddObject(S, Obj); // add to destination
          end;
          FromLB.Items.Delete(i); // remove from source (doesn't free Obj)
        end;
      end;
    finally
      ToLB.Items.EndUpdate;
      FromLB.Items.EndUpdate;
    end;
  finally
    LSet.Free;
  end;
end;

/// <summary> Include selected data from source list to destination list </summary>
procedure TFormSensOpt.IncludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListData);
  MoveSelected(SrcListData, DstListData.Items);
  SetItem(SrcListData, Index);
end;

/// <summary> Exclude selected data from destination list </summary>
procedure TFormSensOpt.ExcludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstListData);
  MoveSelected(DstListData, SrcListData.Items);
  SetItem(DstListData, Index);
end;

/// <summary> Include all data from source list to destination list </summary>
procedure TFormSensOpt.IncAllBtnDataClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to SrcListData.Items.Count - 1 do
    DstListData.Items.AddObject(SrcListData.Items[i],
      SrcListData.Items.Objects[i]);
  SrcListData.Items.Clear;
  SetItem(SrcListData, 0);
end;

/// <summary> Exclude all data from destination list </summary>
procedure TFormSensOpt.ExcAllBtnDataClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to DstListData.Items.Count - 1 do
    SrcListData.Items.AddObject(DstListData.Items[i],
      DstListData.Items.Objects[i]);
  DstListData.Items.Clear;
  SetItem(DstListData, 0);
end;

/// <summary> Move selected items from one list to another </summary>
procedure TFormSensOpt.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  i: Integer;
begin
  for i := List.Items.Count - 1 downto 0 do
    if List.Selected[i] then
    begin
      Items.AddObject(List.Items[i], List.Items.Objects[i]);
      List.Items.Delete(i);
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
  ExcludeBtnData.Enabled := not DstEmptyData;
  ExAllBtnData.Enabled := not DstEmptyData;
end;

function TFormSensOpt.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then
      Exit;
  Result := LB_ERR;
end;

procedure TFormSensOpt.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do
  begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then
      Index := 0
    else if Index > MaxIndex then
      Index := MaxIndex;
    Selected[Index] := True;
  end;
  SetButtons;
end;

/// <summary> Form activation event </summary>
procedure TFormSensOpt.FormActivate;

var
  i, j, k, comboboxindex: Integer;
  SubMod: TSubModel;
  ActPar: TPar;
  ActState: TState;
  ActVar: TVar;
  Name, submodname: string;
  fnSensSettings, userdir: string;
  IniSensSettings: TMemInifile;
  SelOutVars: TStringList;
  SelVar, SelKey, SelParstr: string;

begin

  /// <summary> clear the source and destination list data </summary>
  SrcListData.Clear;
  DstListData.Clear;

  // Add all parameters of all submodels to ComboBoxParameter
  for i := 0 to model.SubModStrList.Count - 1 do
  begin
    SubMod := TSubModel(model.SubModStrList.Objects[i]);
    for j := 0 to SubMod.ParStrList.Count - 1 do
    begin
      ActPar := TPar(SubMod.ParStrList.Objects[j]);
      ComboBoxParameter.Items.AddObject(SubMod.Name + '.' +
        ActPar.Name, ActPar);
    end;
  end;

  // add all Statevars and vars to the source datalistbox
  for i := 0 to model.SubModStrList.Count - 1 do
  begin
    SubMod := TSubModel(model.SubModStrList.Objects[i]);
    if SubMod.StateStrList <> nil then
    begin
      for j := 0 to SubMod.StateStrList.Count - 1 do
      begin
        ActState := TState(SubMod.StateStrList.Objects[j]);
        SrcListData.Items.add(SubMod.Name + '.' + ActState.Name);
      end;
    end;
    if SubMod.VarStrList <> nil then
    begin
      for j := 0 to SubMod.VarStrList.Count - 1 do
      begin
        ActVar := TVar(SubMod.VarStrList.Objects[j]);
        SrcListData.Items.add(SubMod.Name + '.' + ActVar.Name);
      end;
    end;
  end;

  // Get user directory and INI file name
  userdir := ExtractFilePath(ParamStr(0));
  fnSensSettings := userdir + 'SensSettings.ini';
  IniSensSettings := TMemInifile.Create(fnSensSettings);

  // read selected parameter from INI file
  SelParStr := IniSensSettings.ReadString(SectionSelPar,
    KeySelPar, '');
  ComboBoxIndex := ComboBoxParameter.Items.IndexOf(SelParStr);
  if ComboBoxIndex >= 0 then
    ComboBoxParameter.ItemIndex := ComboBoxIndex
  else
    ComboBoxParameter.Text := SelParStr;

  // Read final, initial, and actual values
  self.EditFinalvalue.Text := IniSensSettings.ReadString(SectionValues,
    KeyFinalVal, '');
  self.EditInitialValue.Text := IniSensSettings.ReadString(SectionValues,
    KeyIniVal, '');
  self.EditActualValue.Text := IniSensSettings.ReadString(SectionValues,
    KeyActVal, '');
  self.SpinEditSensSteps.Value := IniSensSettings.ReadInteger(SectionValues,
    KeySteps, 1);

  // Read selected output variables from INI file
  // and move them to the destination list
  SelOutVars := TStringList.Create;
  SelOutVars.NameValueSeparator := '=';
  IniSensSettings.ReadSectionValues(KeyOutVals, SelOutVars);
  for i := 0 to SelOutVars.Count - 1 do
    SelOutVars.strings[i] := SelOutVars.Values[SelOutVars.KeyNames[i]];
  MoveItemsByList(self.SrcListData, self.DstListData, SelOutVars, True);
  if i > 0 then
    self.ExcludeBtnData.Enabled := True;

  IniSensSettings.Free;
  SelOutVars.Free;

end;



/// <summary>
/// Handles saves Sensitivity Options form, saving user selections and parameter values to an INI file.
/// </summary>
/// <param name="Sender">The object that triggered the event.</param>
/// <param name="Action">Specifies how the form should be closed.</param>
/// <remarks>
/// Stores selected parameter, actual, initial, and final values, as well as step count and output values.
/// </remarks>
procedure TFormSensOpt.SaveSettings;

var
  fnSensSettings, userdir: string;
  IniSensSettings: TMemInifile;
  i: Integer;
  SelParName, submodname, Name: string;
  SelPar: TPar;
  SelState: TState;
  SelVar: TVar;
  success: Boolean;

begin

  // Get user directory and INI file name
  userdir := ExtractFilePath(ParamStr(0));
  fnSensSettings := userdir + 'SensSettings.ini';

  // Create INI file object
  IniSensSettings := TMemInifile.Create(fnSensSettings);

  // write selected parameter to INI file
  IniSensSettings.WriteString('SelPar', 'SelPar', self.ComboBoxParameter.Text);
  IniSensSettings.WriteFloat('Values', 'ActVal',
    strToFloat(self.EditActualValue.Text));
  IniSensSettings.WriteFloat('Values', 'IniVal',
    strToFloat(self.EditInitialValue.Text));
  IniSensSettings.WriteFloat('Values', 'FinalVal',
    strToFloat(self.EditFinalvalue.Text));
  IniSensSettings.WriteInteger('Values', 'Steps', SpinEditSensSteps.Value);

  // Write output variables to INI file
  IniSensSettings.EraseSection(KeyOutVals);
  for i := 0 to self.DstListData.Items.Count - 1 do
    IniSensSettings.WriteString(KeyOutVals, Format('Item%d', [i]),
      DstListData.Items[i]);

  IniSensSettings.UpdateFile;
  IniSensSettings.Free;
end;




/// <summary>
/// Handles the closing of the Sensitivity Options form, saving user selections and parameter values to an INI file.
/// </summary>
/// <param name="Sender">The object that triggered the event.</param>
/// <param name="Action">Specifies how the form should be closed.</param>
/// <remarks>
/// Stores selected parameter, actual, initial, and final values, as well as step count and output values.
/// </remarks>
procedure TFormSensOpt.FormClose(Sender: TObject; var Action: TCloseAction);


begin
  SaveSettings; 
end;

procedure TFormSensOpt.OKBtnClick(Sender: TObject);

begin
  close;
end;

/// <summary>
/// Handles the change event for the ComboBoxParameter control.
/// Updates the parameter selection for sensitivity analysis based on the user's selection.
/// Retrieves the selected parameter's full name, parses the submodel and parameter names,
/// locates the corresponding submodel and parameter objects, and marks the parameter as selected for sensitivity.
/// Updates the EditActualValue, EditInitialValue, and EditFinalvalue controls with appropriate values
/// depending on the parameter's current value.
/// </summary>
/// <param name="Sender">The object that triggered the event.</param>
/// <remarks>
/// Assumes that ComboBoxParameter contains items in the format 'SubModel.Parameter'.
/// Relies on the existence of model.SubModStrList and each submodel's ParStrList.
/// </remarks>
procedure TFormSensOpt.ComboBoxParameterChange(Sender: TObject);

var
  Fullname, parName: string;
  ActPar: TPar;
  ActSubMod: TSubModel;
  Index, i: Integer;
  submodname: string;
  success: Boolean;
  dotpos : integer;
begin
  success := false;
  Fullname := self.ComboBoxParameter.Items[ComboBoxParameter.ItemIndex];
  // SelText;
  Fullname := self.ComboBoxParameter.Items[ComboBoxParameter.ItemIndex];
  // SelText;
  dotPos := pos('.', Fullname);
  parName := copy(Fullname, dotPos + 1, length(Fullname) - dotPos);
  submodname := copy(Fullname, 1, dotPos - 1);
  index := self.model.SubModStrList.IndexOf(submodname);

  if Index <> -1 then
  begin
    ActSubMod := TSubModel(model.SubModStrList.Objects[index]);
    // pars := ActSubMod.ParStrList.CommaText;
    i := 0;
    repeat
      ActPar := TPar(ActSubMod.ParStrList.Objects[i]);
      if ActPar.Name = parName then
      begin
        success := True;
        ActPar.SelForSens := True;
        Break;
      end;
      inc(i);
    until success or (i >= ActSubMod.ParStrList.Count);
    if success then
    begin
      EditActualValue.Text := floatToStrF(ActPar.v, ffgeneral, 8, 6);
      if (ActPar.v > 0) then
      begin
        EditInitialValue.Text := floatToStrF(ActPar.v * 0.5, ffgeneral, 8, 6);
        EditFinalvalue.Text := floatToStrF(ActPar.v * 1.5, ffgeneral, 8, 6);
      end
      else
      begin
        EditInitialValue.Text := floatToStrF(ActPar.v - 1, ffgeneral, 8, 6);
        EditFinalvalue.Text := floatToStrF(ActPar.v + 1, ffgeneral, 8, 6);
      end;
    end;
  end;
end;


  /// <summary>
  /// Handles the click event for the Accept button in the sensitivity options form.
  /// </summary>
  /// <remarks>
  /// This procedure retrieves the selected parameter from the ComboBox, updates the sensitivity options
  /// (including min/max values, steps, and step size), and populates the output list with selected states or variables.
  /// If a state or variable cannot be found, a message is displayed to the user.
  /// </remarks>
  /// <param name="Sender">The object that triggered the event.</param>
procedure TFormSensOpt.AcceptButtonClick(Sender: TObject);

var
  Name, submodname: string;
  success: Boolean;
  ActPar: TPar;
  ActState: TState;
  ActVar: TVar;
  i: Integer;

begin
  name := ComboBoxParameter.Items[ComboBoxParameter.ItemIndex]; // SelText;
  model.GetParameter(name, ActPar, submodname, success);
  if success then
  begin
    model.SensOpt.SelSensPar := ActPar;
    model.SensOpt.MaxValue := strToFloat(EditFinalvalue.Text);
    model.SensOpt.MinValue := strToFloat(EditInitialValue.Text);
    model.SensOpt.Steps := SpinEditSensSteps.Value;
    model.SensOpt.DPar := (model.SensOpt.MaxValue - model.SensOpt.MinValue) /
      (model.SensOpt.Steps - 1);
    model.SensOpt.FOutList.Clear;
    for i := 0 to DstListData.Items.Count - 1 do
    begin
      Name := DstListData.Items[i];
      model.SensOpt.FOutList.add(Name);
      model.GetStateVar(Name, ActState, submodname, success);
      if success then
        model.SensOpt.FOutList.Objects[i] := ActState
      else
      begin
        model.GetVariable(Name, ActVar, submodname, success);
        if success then
          model.SensOpt.FOutList.Objects[i] := ActVar
        else
          ShowMessage('Problem: ' + name + ' not found');
      end;
      // model.
    end;
  end;
  SaveSettings;
end;

procedure TFormSensOpt.update_StringGrid(StrGrd: TAdvStringGrid; fn: string);

var
  f: textFile;
  i: Integer;
  line: string;
  StrLst: TStringList;
begin
  StrLst := TStringList.Create;
  if FileExists(fn) then
  begin
    assignfile(f, fn);
    reset(f);
    for i := 0 to StrGrd.RowCount - 1 do
      StrGrd.Rows[i].Clear;
    i := 0;
    while not eof(f) do
    begin
      readln(f, line);
      StrLst.CommaText := line;
      StrGrd.ColCount := StrLst.Capacity;
      if StrGrd.RowCount < i + 1 then
        StrGrd.RowCount := StrGrd.RowCount + 1;
      StrGrd.Rows[i].CommaText := line;
      inc(i);
    end;
    StrGrd.Repaint;
    closefile(f);
  end
  else
    ShowMessage('File ' + fn + ' not found !');
end;

procedure TFormSensOpt.ButtonRunMultSensClick(Sender: TObject);
var
  Name, Fullname, submodname: string;
  success: Boolean;
  ActPar: TPar;
  SaveParValue: real;
  ActState: TState;
  ActVar: TVar;
  i: Integer;

begin

  name := ComboBoxParameter.Items[ComboBoxParameter.ItemIndex]; // SelText;
  name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
  // Delete Submodelname from string

  model.GetParameter(name, ActPar, submodname, success);
  ActPar.SelForSens := True;
  FPropIniFile.WriteBool(submodname, submodname + '.' + ActPar.Name +
    '.SelForSens', ActPar.SelForSens);
  if success then
  begin
    SaveParValue := ActPar.fv;
    model.SensOpt.SelSensPar := ActPar;
    model.SensOpt.MaxValue := strToFloat(EditFinalvalue.Text);
    model.SensOpt.MinValue := strToFloat(EditInitialValue.Text);
    model.SensOpt.Steps := SpinEditSensSteps.Value;
    model.SensOpt.DPar := (model.SensOpt.MaxValue - model.SensOpt.MinValue) /
      (model.SensOpt.Steps - 1);
    model.SensOpt.FOutList.Clear;
    for i := 0 to DstListData.Items.Count - 1 do
    begin
      Fullname := DstListData.Items[i];
      name := copy(Fullname, pos('.', Fullname) + 1, length(Fullname) - pos('.',
        Fullname));
      submodname := copy(Fullname, 1, pos('.', Fullname) - 1);
      model.SensOpt.FOutList.add(Name);
      model.GetStateVar(Name, ActState, submodname, success);
      if success then
      begin
        model.SensOpt.FOutList.Objects[i] := ActState;
        ActState.Opt_SelForSensOut := True;
        FPropIniFile.WriteBool(submodname, ActState.Name + '.SelForSensOut',
          ActState.SelForSensOut);
      end
      else
      begin
        model.GetVariable(Name, ActVar, submodname, success);
        if success then
        begin
          model.SensOpt.FOutList.Objects[i] := ActVar;
          ActVar.Opt_SelForSensOut := True;
          FPropIniFile.WriteBool(submodname, ActVar.Name + '.SelForSensOut',
            ActVar.SelForSensOut);
        end

        else
          ShowMessage('Problem: ' + name + ' not found');
      end;
    end;

    // for all non selected Items set and write SelForSensOut FALSE
    for i := 0 to SrcListData.Items.Count - 1 do
    begin
      Fullname := SrcListData.Items[i];
      name := copy(Fullname, pos('.', Fullname) + 1, length(Fullname) - pos('.',
        Fullname));
      submodname := copy(Fullname, 1, pos('.', Fullname) - 1);
      model.GetStateVar(Name, ActState, submodname, success);
      if success then
      begin
        ActState.Opt_SelForSensOut := false;
        FPropIniFile.WriteBool(submodname, ActState.Name,
          ActState.SelForSensOut);
      end
      else
      begin
        model.GetVariable(Name, ActVar, submodname, success);
        if success then
        begin
          ActVar.Opt_SelForSensOut := false;
          FPropIniFile.WriteBool(submodname, ActVar.Name, ActVar.SelForSensOut);
        end

        else
          ShowMessage('Problem: ' + name + ' not found');
      end;
    end;
    FPropIniFile.UpdateFile;
    model.CalcSensitivityMultRun;
    ActPar.fv := SaveParValue;

    update_StringGrid(self.AdvStringGridMultRunFinal,
      model.SensOpt.MultSens_fn_final);
    self.EditFileNameMultRunFinal.Text := model.SensOpt.MultSens_fn_final;
    // UpdatePageGraphResult(self.model.sensOpt.sens_fn);
    // PageControl1.ActivePage := TabSheetResults;
  end;
end;

procedure TFormSensOpt.ButtonRunSensClick(Sender: TObject);

var
  Name, submodname: string;
  success: Boolean;
  ActPar: TPar;
  SaveParValue: real;
  ActState: TState;
  ActVar: TVar;
  i: Integer;

begin
  SaveSettings;
  name := ComboBoxParameter.Items[ComboBoxParameter.ItemIndex]; // SelText;
  submodname := copy(name, 1, length(name) - pos('.', name) - 1);
  name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
  // Delete Submodelname from string

  model.GetParameter(name, ActPar, submodname, success);
  if success then
  begin
    SaveParValue := ActPar.fv;
    model.SensOpt.SelSensPar := ActPar;
    model.SensOpt.MaxValue := strToFloat(EditFinalvalue.Text);
    model.SensOpt.MinValue := strToFloat(EditInitialValue.Text);
    model.SensOpt.Steps := SpinEditSensSteps.Value;
    model.SensOpt.DPar := (model.SensOpt.MaxValue - model.SensOpt.MinValue) /
      (model.SensOpt.Steps - 1);
    model.SensOpt.FOutList.Clear;
    for i := 0 to DstListData.Items.Count - 1 do
    begin
      Name := DstListData.Items[i];
      name := copy(name, pos('.', name) + 1, length(name) - pos('.', name));
      model.SensOpt.FOutList.add(Name);
      model.GetStateVar(Name, ActState, submodname, success);
      if success then
        model.SensOpt.FOutList.Objects[i] := ActState
      else
      begin
        model.GetVariable(Name, ActVar, submodname, success);
        if success then
          model.SensOpt.FOutList.Objects[i] := ActVar
        else
          ShowMessage('Problem: ' + name + ' not found');

      end;

    end;

    model.CalcSensitivity;
    ActPar.fv := SaveParValue;

    update_StringGrid(self.AdvStrGrdEndResultTab, self.model.SensOpt.sens_fn);
    UpdatePageGraphResult(self.model.SensOpt.sens_fn);
    PageControl1.ActivePage := self.TabSheetGraphSingleRun;
  end;

end;

procedure TFormSensOpt.UpdatePageGraphResult(fn: string);

var
  i, n_lineSeries: Integer;
  x, y: real;

  ActLineSeries: TFastLineSeries;

  ActVar: TVar;
  LineSeriesArr: TLineSeriesArr;
  DataFileSim: TTextFileH;

begin
  Chart1.BottomAxis.Title.Caption := model.SensOpt.SelSensPar.Name + ' ' +
    model.SensOpt.SelSensPar.u;
  Chart1.RemoveAllSeries;
  // color := ClBlue;
  n_lineSeries := -1;

  for i := 0 to self.DstListData.Items.Count - 1 do
  begin

    ActVar := TVar(model.SensOpt.FOutList.Objects[i]);
    inc(n_lineSeries);
    LineSeriesArr[n_lineSeries] := TFastLineSeries.Create(Chart1);
    ActLineSeries := LineSeriesArr[n_lineSeries];
    ActLineSeries.Seriescolor := ClTeecolor;
    LineSeriesArr[n_lineSeries].Title := ActVar.Name + ' ' + ActVar.u;
    ActLineSeries.LinePen.Width := 2;
    Chart1.AddSeries(LineSeriesArr[n_lineSeries]);

    if FileExists(fn) then
    begin

      { if DataFileSim <> nil then begin
        DataFileSim.init(fn);
        end else } begin
        // KLUSS DataFileSim := TTextFileH.create;
        // KLUSS DataFileSim.init(fn);
        DataFileSim := TTextFileH.Create;
        DataFileSim.IndexOf(fn);
      end;
      DataFileSim.GoTop;

      // while not eof(DataFileSim.f) do begin
      while DataFileSim.hasMoreLines() do
      begin
        DataFileSim.NextLine;
        x := DataFileSim.getIndexValue(0);
        y := DataFileSim.getValue(ActVar.Name);
        if not isnan(y) then

          LineSeriesArr[n_lineSeries].addxy(x, y, '', ClTeecolor);
      end;
      // closefile(DataFileSim);
      DataFileSim.CleanupInstance;
      // inc(color);
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
