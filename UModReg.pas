unit UModReg;

interface

uses
  DesignIntf, DesignEditors, VCLEditors,
  UFormSubmodelEditor, // HUME: TF_SubModelEdit, Designtime formular for editing
  // TSubModel instance properties
  UFormModelEditor, // HUME: TModelEdit, Designtime formular for editing TMod
  // instance properties
   toolsAPI ;

type
  /// <summary>
  /// Property editor for the <c>TMod</c> class. Displays a file open dialog
  /// for selecting the control file by overriding <see cref="GetAttributes"/>.
  /// </summary>
  TGMFilenameProperty = class(TStringProperty)
  public
    /// <summary>Edit the value using a file open dialog.</summary>
    procedure Edit; override;
    /// <summary>Return the attribute set for the property.</summary>
    function GetAttributes: TPropertyAttributes; override;
  end;

  /// <summary>
  /// Property editor for the <c>TMod</c> class. Displays a directory selection
  /// dialog for editing path properties by overriding
  /// <see cref="GetAttributes"/>.
  /// </summary>
  TGMPathProperty = class(TStringProperty)
  public
    /// <summary>Edit the value using a directory selection dialog.</summary>
    procedure Edit; override;
    /// <summary>Return the attribute set for the property.</summary>
    function GetAttributes: TPropertyAttributes; override;
  end;

  (* -----------------------------------------------------------------
    CLASS     TGMSensOptProperty
    ANCESTOR  TPropertyEditor
    PURPOSE
    COMMENT   Not yet implemented property editor
    ------------------------------------------------------------------ *)

  { TGMSensOptProperty = Class(TPropertyEditor)
    public
    procedure Edit ; override;
    function GetAttributes : TPropertyAttributes; override;
    end; }

  (* -----------------------------------------------------------------
    CLASS     TExLstProperty
    ANCESTOR  TPropertyEditor
    PURPOSE
    COMMENT   Not yet implemented property editor
    ------------------------------------------------------------------ *)

  { TExLstProperty = class(TPropertyEditor)
    public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    end; }

  /// <summary>Component editor for <c>TMod</c>; starts design-time editing.</summary>
  TModEditor = class(TComponentEditor)
    /// <summary>Exchanges data with <c>TModelEdit</c> and starts editing.</summary>
    procedure Edit; override;
  end;

  /// <summary>
  /// Component editor for <c>TSubModel</c>. Exchanges data with
  /// <c>TF_SubmodelEditor</c> and starts design-time editing.
  /// </summary>
  TSubModelEditor = class(TComponentEditor)
    /// <summary>Starts the submodel editor and stores changes.</summary>
    procedure Edit; override;
  end;

/// <summary>Registers TMod and TSubModel components for design-time editing.</summary>
procedure Register;

implementation

uses Classes, UMod, ModLink, UTextFileH, vcl.Dialogs, SysUtils, UState, vcl.Forms,
  vcl.FileCtrl, UModUtils;

/// <summary>
/// Exchanges data with <c>TModelEdit</c> form and starts design-time editing.
/// </summary>
procedure TModEditor.Edit;

var
  FormModelEditor: TModelEdit;
  i, j, submodindex, OldIndex, NewIndex: integer;
  SubMod: TSubModel;
  Name: string;

begin
  if Tmod(component).GM_ControlFile = '' then
  begin
    showmessage('No Controlfile specified');
  //  exit;
  end;

  // creates model editor form
  FormModelEditor := TModelEdit.create(nil);

  // copies values from TMod properties to editor form
  FormModelEditor.TimeInit := Tmod(component).str_SectionName_TimeInit;
  FormModelEditor.FileNames := Tmod(component).str_SectionName_FileNames;
  FormModelEditor.StartZeit := Tmod(component).str_SectionTopic_SimStart;
  FormModelEditor.endZeit := Tmod(component).str_SectionTopic_SimEnd;
  FormModelEditor.TimeStep := Tmod(component).str_SectionTopic_TimeStep;
  FormModelEditor.StateIniFN := Tmod(component).str_SectionTopic_StateIniFN;
  FormModelEditor.ParamIniFN := Tmod(component).str_SectionTopic_ParamIniFN;
  FormModelEditor.WeatherFileFN := Tmod(component).str_sectionTopic_WeatherFileFN;

  if Tmod(component).SubModStrList.count > 0 then
  begin
    for i := 0 to Tmod(component).SubModStrList.count - 1 do
      FormModelEditor.ListBoxSubModels.items.Add
        (Tmod(component).SubModStrList.strings[i]);
  end;

  FormModelEditor.Edit_ModelName.text := Tmod(component).Name;
  FormModelEditor.ComboBox_Separator.text := Tmod(component).Separator;
  FormModelEditor.DateTimePicker_MT_Starttime.Date := Tmod(component).starttime;
  FormModelEditor.DateTimePicker_MT_Endtime.Date := Tmod(component).Endtime;
  FormModelEditor.Edit_MT_Name.text := Tmod(component).ModTime.Name;
  FormModelEditor.Edit_MT_Unit.text := Tmod(component).ModTime.u;
  FormModelEditor.Edit_MT_Value.text := FloatToStr(Tmod(component).ModTime.v);
  FormModelEditor.Edit_MT_Digits.text :=
    IntToStr(Tmod(component).ModTime.digits);
  FormModelEditor.Edit_MT_Precision.text :=
    IntToStr(Tmod(component).ModTime.precision);
  FormModelEditor.CheckBox_MT_WriteToFile.Checked := Tmod(component)
    .ModTime.WriteToFile;

  FormModelEditor.Edit_MP_Inputpath.text := Tmod(component).GM_InPutPath;
  FormModelEditor.Edit_MP_Outputpath.text := Tmod(component).GM_OutPutPath;
  FormModelEditor.Edit_MP_Controlfilepath.text := Tmod(component).GM_ControlFile;
  FormModelEditor.Edit_MP_Regressionfilepath.text := Tmod(component).Reg_fn;

  FormModelEditor.Edit_MO_DefaultError.text :=
    FloatToStr(Tmod(component).LMOptions.FDefaultError);
  FormModelEditor.Edit_MO_Divisor.text :=
    FloatToStr(Tmod(component).LMOptions.Divisor);
  FormModelEditor.Edit_MO_IniLambda.text :=
    FloatToStr(Tmod(component).LMOptions.FIniLambda);

  if Tmod(component).LMOptions.WeightOptions = OptNoWeight then
    FormModelEditor.ComboBox_MO_WeightOptions.text := 'OptNoWeight';
  if Tmod(component).LMOptions.WeightOptions = OptDefaultWeight then
    FormModelEditor.ComboBox_MO_WeightOptions.text := 'OptDefaultWeight';
  if Tmod(component).LMOptions.WeightOptions = OptMeasErrorWeight then
    FormModelEditor.ComboBox_MO_WeightOptions.text := 'OptMeasErrorWeight';

  FormModelEditor.ListBoxControlFileStrings.items := Tmod(component).FInifiles;
  FormModelEditor.EditNameControlFile.text := Tmod(component).get_ControlFileFN;

  // shows Editor
  FormModelEditor.ShowModal;


  // stores modified values from editor form to properties

  { if FormModelEditor.Save_Status then
    ShowMessage('Save = true') else
    ShowMessage('Save = false'); }

  if FormModelEditor.Save_Status then
  begin
    // ShowMessage('hello - FormModelEditor.Save_Status');
    Tmod(component).Name := FormModelEditor.Edit_ModelName.text;
    Tmod(component).Separator := FormModelEditor.ComboBox_Separator.text[1];
    Tmod(component).starttime :=
      FormModelEditor.DateTimePicker_MT_Starttime.Date;
    Tmod(component).Endtime := FormModelEditor.DateTimePicker_MT_Endtime.Date;
    Tmod(component).ModTime.Name := FormModelEditor.Edit_MT_Name.text;
    Tmod(component).ModTime.u := FormModelEditor.Edit_MT_Unit.text;
    Tmod(component).ModTime.v := strtofloat(FormModelEditor.Edit_MT_Value.text);
    Tmod(component).ModTime.digits :=
      strtoint(FormModelEditor.Edit_MT_Digits.text);
    Tmod(component).ModTime.precision :=
      strtoint(FormModelEditor.Edit_MT_Precision.text);
    Tmod(component).ModTime.WriteToFile :=
      FormModelEditor.CheckBox_MT_WriteToFile.Checked;
    Tmod(component).GM_InPutPath := FormModelEditor.Edit_MP_Inputpath.text;
    Tmod(component).GM_OutPutPath := FormModelEditor.Edit_MP_Outputpath.text;
    Tmod(component).GM_ControlFile := FormModelEditor.Edit_MP_Controlfilepath.text;
    Tmod(component).Reg_fn := FormModelEditor.Edit_MP_Regressionfilepath.text;
    Tmod(component).LMOptions.FDefaultError :=
      strtofloat(FormModelEditor.Edit_MO_DefaultError.text);
    Tmod(component).LMOptions.Divisor :=
      strtofloat(FormModelEditor.Edit_MO_Divisor.text);
    Tmod(component).LMOptions.FIniLambda :=
      strtofloat(FormModelEditor.Edit_MO_IniLambda.text);

    if FormModelEditor.ComboBox_MO_WeightOptions.text = 'OptNoWeight' then
      Tmod(component).LMOptions.WeightOptions := OptNoWeight;

    if FormModelEditor.ComboBox_MO_WeightOptions.text = 'OptDefaultWeight' then
      Tmod(component).LMOptions.WeightOptions := OptDefaultWeight;

    if FormModelEditor.ComboBox_MO_WeightOptions.text = 'OptMeasErrorWeight'
    then
      Tmod(component).LMOptions.WeightOptions := OptMeasErrorWeight;

    for i := 0 to FormModelEditor.ListBoxSubModels.count - 1 do
    begin
      Name := FormModelEditor.ListBoxSubModels.items[i];
      submodindex := Tmod(component).SubModStrList.indexof(Name);
      SubMod := TSubModel(Tmod(component).SubModStrList.objects[submodindex]);
      SubMod.CompIndex := i;
    end;

    for j := Tmod(component).SubModStrList.count - 2 downto 0 do
      for i := 0 to j do
        if TSubModel(Tmod(component).SubModStrList.objects[i]).CompIndex >
          TSubModel(Tmod(component).SubModStrList.objects[i + 1]).CompIndex then
          Tmod(component).SubModStrList.Exchange(i, i + 1);

    { for i := 0 to TMod(Component).SubModStrList.count - 1 do begin
      Name := TMod(Component).SubModStrList.strings[i];
      TMod(Component).SubModStrList.sort;
      OldIndex := TMod(Component).SubModStrList.indexof(Name);
      NewIndex := FormModelEditor.ListBoxSubmodels.items.indexof(Name);
      SubMod := TsubModel(TMod(Component).SubModStrList.objects[OldIndex]);
      SubMod.CompIndex := NewIndex;
      end; }
  end;

  FormModelEditor.Free;
  FormModelEditor := nil;
end;

/// <summary>
/// Exchanges data with <c>TF_SubmodelEditor</c> form and starts design-time editing.
/// </summary>
procedure TSubModelEditor.Edit;
var
  FormSubModelEditor: TF_SubmodelEditor;
  params: TPar;
  variables: TVar;
  states: TState;
  externs: TExternV;
  h,i,j,k: integer;
  f: TStreamwriter;
  actState: TState;
  actPar : TPar;
  actExVar : TExternV;
  actVar, actConst : TVar;
  actOption: TOption;
  userdir, line : string;
  l,m,n,o: Integer;


begin

  userdir := (BorlandIDEServices as IOTAModuleServices).GetActiveProject.FileName;
  userdir := extractfilepath(userdir);
//  userdir := extractFilePath( getActiveProject.fileName ) ;
  // creates submodel editor form
  f := TStreamWriter.Create(userdir+TSubModel(component).name+'.csv', false, TEncoding.UTF8);
  line := 'SubModel;EntityType;EntityName;Units;Value;Option;Comment';
  f.writeline(line);
  FormSubModelEditor := TF_SubmodelEditor.create(nil);
  FormSubModelEditor.caption := 'Editing ' + TSubModel(component).Name;
  FormSubModelEditor.ADV_Par.EditorMode := true;

  // displays TPar
  if TSubModel(component).parStrList.count > 0 then
    FormSubModelEditor.ADV_Par.rowcount := TSubModel(component)
      .parStrList.count + 1
  else
    FormSubModelEditor.ADV_Par.rowcount := 2;
  FormSubModelEditor.ADV_Par.colcount := 9;
  FormSubModelEditor.ADV_Par.rows[0].CommaText :=
    'Name,Unit,Value,Digits, Precision,ReadFromFile,WriteToFile,Optimization,PlotToGraph';
  for i := 0 to TSubModel(component).parStrList.count - 1 do
  begin
    params := TPar(TSubModel(component).parStrList.objects[i]);
    FormSubModelEditor.ADV_Par.Cells[0, i + 1] := params.Name;
    FormSubModelEditor.ADV_Par.Cells[1, i + 1] := params.u;
    FormSubModelEditor.ADV_Par.Cells[2, i + 1] :=
      floattostrF(params.v, ffgeneral, 6, 3);
    FormSubModelEditor.ADV_Par.Cells[3, i + 1] := IntToStr(params.digits);
    FormSubModelEditor.ADV_Par.Cells[4, i + 1] := IntToStr(params.precision);
    FormSubModelEditor.ADV_Par.AddCheckBox(5, i + 1, true, true);
    FormSubModelEditor.ADV_Par.SetCheckBoxState(5, i + 1,
      params.ReadFromIniFile);
    FormSubModelEditor.ADV_Par.AddCheckBox(6, i + 1, true, true);
    FormSubModelEditor.ADV_Par.SetCheckBoxState(6, i + 1, params.WriteToFile);
    FormSubModelEditor.ADV_Par.AddCheckBox(7, i + 1, true, true);
    FormSubModelEditor.ADV_Par.SetCheckBoxState(7, i + 1, params.SelForOpt);
    FormSubModelEditor.ADV_Par.AddCheckBox(8, i + 1, true, true);
    FormSubModelEditor.ADV_Par.SetCheckBoxState(8, i + 1, params.PlotTograpH);
  end;

  // displays TVar
  if TSubModel(component).varStrList.count > 0 then
    FormSubModelEditor.adv_var.rowcount := TSubModel(component)
      .varStrList.count + 1
  else
    FormSubModelEditor.adv_var.rowcount := 2;
  FormSubModelEditor.adv_var.colcount := 8;
  FormSubModelEditor.adv_var.rows[0].CommaText :=
    'Name,Unit,Value,Digits, Precision,ReadFromFile,WriteToFile,PlotToGraph';
  for i := 0 to TSubModel(component).varStrList.count - 1 do
  begin
    variables := TVar(TSubModel(component).varStrList.objects[i]);
    FormSubModelEditor.adv_var.Cells[0, i + 1] := variables.Name;
    FormSubModelEditor.adv_var.Cells[1, i + 1] := variables.u;
    FormSubModelEditor.adv_var.Cells[2, i + 1] :=
      floattostrF(variables.v, ffgeneral, 6, 3);
    FormSubModelEditor.adv_var.Cells[3, i + 1] := IntToStr(variables.digits);
    FormSubModelEditor.adv_var.Cells[4, i + 1] := IntToStr(variables.precision);
    FormSubModelEditor.adv_var.AddCheckBox(5, i + 1, true, true);
    FormSubModelEditor.adv_var.SetCheckBoxState(5, i + 1,
      variables.ReadFromIniFile);
    FormSubModelEditor.adv_var.AddCheckBox(6, i + 1, true, true);
    FormSubModelEditor.adv_var.SetCheckBoxState(6, i + 1,
      variables.WriteToFile);
    FormSubModelEditor.adv_var.AddCheckBox(7, i + 1, true, true);
    FormSubModelEditor.adv_var.SetCheckBoxState(7, i + 1,
      variables.PlotTograpH);
  end;

  // displays TState
  if TSubModel(component).stateStrList.count > 0 then
    FormSubModelEditor.adv_state.rowcount := TSubModel(component)
      .stateStrList.count + 1
  else
    FormSubModelEditor.adv_state.rowcount := 2;
  FormSubModelEditor.adv_state.colcount := 8;
  FormSubModelEditor.adv_state.rows[0].CommaText :=
    'Name,Unit,Value,Digits, Precision,ReadFromFile,WriteToFile,PlotToGraph';
  for i := 0 to TSubModel(component).stateStrList.count - 1 do
  begin
    states := TState(TSubModel(component).stateStrList.objects[i]);
    FormSubModelEditor.adv_state.Cells[0, i + 1] := states.Name;
    FormSubModelEditor.adv_state.Cells[1, i + 1] := states.u;
    FormSubModelEditor.adv_state.Cells[2, i + 1] :=
      floattostrF(states.v, ffgeneral, 6, 3);
    FormSubModelEditor.adv_state.Cells[3, i + 1] := IntToStr(states.digits);
    FormSubModelEditor.adv_state.Cells[4, i + 1] := IntToStr(states.precision);
    FormSubModelEditor.adv_state.AddCheckBox(5, i + 1, true, true);
    FormSubModelEditor.adv_state.SetCheckBoxState(5, i + 1,
      states.ReadFromIniFile);
    FormSubModelEditor.adv_state.AddCheckBox(6, i + 1, true, true);
    FormSubModelEditor.adv_state.SetCheckBoxState(6, i + 1, states.WriteToFile);
    FormSubModelEditor.adv_state.AddCheckBox(7, i + 1, true, true);
    FormSubModelEditor.adv_state.SetCheckBoxState(7, i + 1, states.PlotTograpH);
  end;

  // displays TExternValue
  if TSubModel(component).externVStrList.count > 0 then
    FormSubModelEditor.ADV_ExternV.rowcount := TSubModel(component)
      .externVStrList.count + 1
  else
    FormSubModelEditor.ADV_ExternV.rowcount := 2;
  FormSubModelEditor.ADV_ExternV.colcount := 3;
  FormSubModelEditor.ADV_ExternV.rows[0].CommaText := 'Name,Unit,C_F';
  for i := 0 to TSubModel(component).externVStrList.count - 1 do
  begin
    externs := TExternV(TSubModel(component).externVStrList.objects[i]);
    FormSubModelEditor.ADV_ExternV.Cells[0, i + 1] := externs.Name;
    FormSubModelEditor.ADV_ExternV.Cells[1, i + 1] := externs.u;
    FormSubModelEditor.ADV_ExternV.Cells[2, i + 1] :=
      floattostrF(externs.C_f, ffgeneral, 6, 3);
  end;

  FormSubModelEditor.ADV_Par.autosizecolumns(true, 0);
  FormSubModelEditor.adv_var.autosizecolumns(true, 0);
  FormSubModelEditor.adv_state.autosizecolumns(true, 0);
  FormSubModelEditor.ADV_ExternV.autosizecolumns(true, 0);

  // shows Editor
  FormSubModelEditor.ShowModal;


  // stores modified values to properties

  if FormSubModelEditor.Save_Status then
  begin

    // stores TPar
    for i := 0 to TSubModel(component).parStrList.count - 1 do
    begin
      params := TPar(TSubModel(component).parStrList.objects[i]);
      params.u := FormSubModelEditor.ADV_Par.Cells[1, i + 1];
      params.v := strtofloat(FormSubModelEditor.ADV_Par.Cells[2, i + 1]);
      params.digits := strtoint(FormSubModelEditor.ADV_Par.Cells[3, i + 1]);
      params.precision := strtoint(FormSubModelEditor.ADV_Par.Cells[4, i + 1]);
      FormSubModelEditor.ADV_Par.GetCheckboxState(5, i + 1,
        params.ReadFromIniFile);
      FormSubModelEditor.ADV_Par.GetCheckboxState(6, i + 1, params.WriteToFile);
      FormSubModelEditor.ADV_Par.GetCheckboxState(7, i + 1, params.SelForOpt);
      FormSubModelEditor.ADV_Par.GetCheckboxState(8, i + 1, params.PlotTograpH);
    end;

    // stores TVar
    for i := 0 to TSubModel(component).varStrList.count - 1 do
    begin
      variables := TVar(TSubModel(component).varStrList.objects[i]);
      variables.u := FormSubModelEditor.adv_var.Cells[1, i + 1];
      variables.v := strtofloat(FormSubModelEditor.adv_var.Cells[2, i + 1]);
      variables.digits := strtoint(FormSubModelEditor.adv_var.Cells[3, i + 1]);
      variables.precision :=
        strtoint(FormSubModelEditor.adv_var.Cells[4, i + 1]);
      FormSubModelEditor.adv_var.GetCheckboxState(5, i + 1,
        variables.ReadFromIniFile);
      FormSubModelEditor.adv_var.GetCheckboxState(6, i + 1,
        variables.WriteToFile);
      FormSubModelEditor.adv_var.GetCheckboxState(7, i + 1,
        variables.PlotTograpH);
    end;

    // stores TState
    for i := 0 to TSubModel(component).stateStrList.count - 1 do
    begin
      states := TState(TSubModel(component).stateStrList.objects[i]);
      states.u := FormSubModelEditor.adv_state.Cells[1, i + 1];
      states.v := strtofloat(FormSubModelEditor.adv_state.Cells[2, i + 1]);
      states.digits := strtoint(FormSubModelEditor.adv_state.Cells[3, i + 1]);
      states.precision := strtoint(FormSubModelEditor.adv_state.Cells
        [4, i + 1]);
      FormSubModelEditor.adv_state.GetCheckboxState(5, i + 1,
        states.ReadFromIniFile);
      FormSubModelEditor.adv_state.GetCheckboxState(6, i + 1,
        states.WriteToFile);
      FormSubModelEditor.adv_state.GetCheckboxState(7, i + 1,
        states.PlotTograpH);
    end;

    // stores TExternValue
    for i := 0 to TSubModel(component).externVStrList.count - 1 do
    begin
      externs := TExternV(TSubModel(component).externVStrList.objects[i]);
      externs.Name := FormSubModelEditor.ADV_ExternV.Cells[0, i + 1];
      externs.u := FormSubModelEditor.ADV_ExternV.Cells[1, i + 1];
      externs.C_f := strtofloat(FormSubModelEditor.ADV_ExternV.Cells[2, i + 1]);
    end;
  end;

  for j := 0 to TSubModel(component).StateStrList.count - 1 do
      begin
        actState := TState(TSubModel(component).StateStrList.objects[j]);
        line := TSubModel(component).Name + ';';
        line := line + 'State' + ';' + actState.Name + ';' + actState.U + ';' +
          FloatToStr(actState.v) + ';' + 'NA' + ';' + actState.Comment;
        f.writeline(line);
      end;
      for k := 0 to TSubModel(component).ParStrList.count - 1 do
      begin
        ActPar := TPar(TSubModel(component).ParStrList.objects[k]);
        line := TSubModel(component).Name + ';';
        line := line + 'Parameter' + ';' + ActPar.Name + ';' + ActPar.U + ';' +
          FloatToStr(ActPar.v) + ';' + 'NA' + ';' + ActPar.Comment;
        f.writeline(line);
      end;
      for l := 0 to TSubModel(component).ExternVStrList.count-1 do
      begin
        ActExVar := TExternV(TSubModel(component).ExternVStrList.objects[l]);
        line := TSubModel(component).Name + ';';
        line := line + 'ExtVar' + ';' + ActExVar.Name + ';' + ActExVar.U + ';' +
          FloatToStr(ActExVar.v) + ';' + 'NA' + ';' + ActExVar.Comment;
        f.writeline(line);
      end;
      for m := 0 to TSubModel(component).VarStrList.count-1 do
      begin
        ActVar := TVar(TSubModel(component).VarStrList.objects[m]);
        line := TSubModel(component).Name + ';';
        line := line + 'Variable' + ';' + ActVar.Name + ';' + ActVar.U + ';' +
          FloatToStr(ActVar.v) + ';' + 'NA' + ';' + ActVar.Comment;
        f.writeline(line);
      end;
      for n := 0 to TSubModel(component).ConstStrList.count-1 do
      begin
        ActConst := TVar(TSubModel(component).ConstStrList.objects[n]);
        line := TSubModel(component).Name + ';';
        line := line + 'Constant' + ';' + ActConst.Name + ';' + ActConst.U + ';' +
          FloatToStr(ActConst.v) + ';' + 'NA' + ';' + ActConst.Comment;
        f.writeline(line);
      end;
      for o := 0 to TSubModel(component).OptionStrList.count-1 do
      begin
        ActOption := TOption(TSubModel(component).OptionStrList.objects[o]);
        line := TSubModel(component).Name + ';';
        line := line + 'Option' + ';' + ActOption.Name + ';' + 'NA' + ';' +
          ActOption.Option + ';' + 'NA' + ';' + ActOption.Comment;
        f.writeline(line);
      end;

  f.Flush;
  f.close;
  f.free;
  FormSubModelEditor.Free;
end;

(* *****************************************************************
  CLASS   TExLstProperty
  METHOD  Edit
  PURPOSE
  COMMENT Not yet implemented property editor
  ****************************************************************** *)

{ procedure TExLstProperty.Edit;

  var
  ExForm: TFormExValEdit;

  begin
  ExForm := TFormExValEdit.Create(Application);
  self.GetPropInfo
  ExForm.SetExVList(GetValue);
  end; }

/// <summary>
/// Property editor for the <c>TMod</c> class. Displays a file open dialog for
/// the name of the control file (all <c>TMyFileName</c> properties).
/// </summary>
procedure TGMFilenameProperty.Edit;
var
  MPFileOpen: TOpenDialog;
begin
  MPFileOpen := TOpenDialog.create(Application);
  MPFileOpen.Filename := GetValue;
  { MPFileOpen.Filter := 'ControlFile (*.fn) | *.fn'; }
  { MPFileOpen.HelpContext := hcDMediaPlayerOpen; }
  MPFileOpen.Options := MPFileOpen.Options + [ofShowHelp, ofPathMustExist,
    ofFileMustExist];
  try
    if MPFileOpen.Execute then
      SetValue(MPFileOpen.Filename);
  finally
    MPFileOpen.Free;
  end;
end;

/// <summary>
/// Describes the property so the Object Inspector provides the appropriate controls.
/// </summary>
function TGMFilenameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

/// <summary>
/// Property editor for the <c>TMod</c> class. Displays a directory change
/// dialog for editing path properties.
/// </summary>
procedure TGMPathProperty.Edit;
var
  Dir: string;
begin
  getDir(0, Dir);
  if SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate, sdPrompt], 0) then
    SetValue(Dir);
end;

/// <summary>
/// Describes the property so the Object Inspector provides the appropriate controls.
/// </summary>
function TGMPathProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

/// <summary>Registers TMod and TSubModel components for design-time editing.</summary>
procedure Register;
begin
  // Registers PropertyEditors for use in Object inspector
{$IFNDEF NONVISUAL}

  RegisterPropertyEditor(TypeInfo(TMyFileName), nil, '', TGMFilenameProperty);
  RegisterPropertyEditor(TypeInfo(TPath), Tmod, '', TGMPathProperty);
  RegisterPropertyEditor(TypeInfo(TMyFileName), TTextFileH, '', TGMFilenameProperty);

  // Registers designtime Editors for TMod and TSubModel
  RegisterComponentEditor(Tmod, TModEditor);
  RegisterComponentEditor(TSubModel, TSubModelEditor);

  // Registers TMod and TSubModel on HUME Component palette
 //RegisterComponents('HUME', [TSubModel, Tmod]);
  //RegisterComponents('HUME', [TModLink]);
  // RegisterComponents('HUMEDemo', [TLogistGrowth]);
 {$ENDIF}


end;

end.
