unit UMod;

interface

uses
  AdvGrid, SysUtils, Windows, Messages, Classes, Dialogs,
  Graphics, Controls, comctrls, ExtCtrls,
 // DesignEditors,
  UFormSubmodelEditor, // HUME: TF_SubModelEdit, Designtime formular for editing
  // TSubModel instance properties
  UFormModelEditor, // HUME: TModelEdit, Designtime formular for editing TMod
  // instance properties
  IniFiles, // Delphi VCL: Implements TIniFile class, handling INI file text format
  UState, // HUME: TVar, TPar, TState and TExternV classes
  UTextfileH, // HUME: TTextFileH class, handling tabular ASCII files
  UMeasValue, // HUME: MeasValue and TMeasList, handling measurement data
  UModUtils, // HUME: string routines and numerical routines
  Math;

type
/// enumeration type for model Elements
  TModelElements = (States, Vars, Params, Externals, Consts);
  TModelElementNames = array[TModelElements] of string;

  TNumbersOf = array[TModelElements] of Integer; /// type for numbers of Model Elements in each submodel
  TListsOf = array[TModelElements] of TStringList; /// type for numbers of Model Elements in each submodel
  TMyIniFile = TMemIniFile;     /// Use TMemIniFile for Inifiles
  real = double;
  TShapeType = (stRectangle, stSquare, stRoundRect, stRoundSquare, stEllipse,
    stCircle);
  /// Options for weighting of data points during optimization
  TWeightOptions = (OptNoWeight, OptDefaultWeight, OptMeasErrorWeight);
  TOptOption = (optAllInis, optAllInisSeperate, optOnlyActIni);

const
 ModelElementNames : TModelElementNames = ('State Variables', 'Variables', 'Parameters', 'Exernal Values', 'Constants');

type

  {* -----------------------------------------------------------------
    CLASS     TMarquardOptions
    ANCESTOR  TPersistent
    PURPOSE   Options for the Marquard-Method used for parameter estimation
    ------------------------------------------------------------------ }
  TMarquardOptions = class(TPersistent)
  private
  protected
  public
    FIniLambda: real; /// Initial value of parameter Lambda
    FDivisor: real; /// Value which is needed for numerical
    /// approximation of function derivative
    FWeightOptions: TWeightOptions;
    /// Options for weighting of data points during optimization
    FDefaultError: real; /// one may use an default error for weighting
    FOptOption: TOptOption;
    constructor create;
  published
    property IniLambda: real read FIniLambda write FIniLambda;
    property Divisor: real read FDivisor write FDivisor;
    property WeightOptions
      : TWeightOptions read FWeightOptions write FWeightOptions;
    property DefaultError: real read FDefaultError write FDefaultError;
    property OptOption: TOptOption read FoptOption write FoptOption;
  end;

  {* ----------------------------------------------------------------
    CLASS     TSensitivityOptions
    ANCESTOR  TPersistent
    PURPOSE   Simple class to save options for Sensitivity analysis
    used within the TMod class
    ------------------------------------------------------------------ }
  TSensitivityOptions = class(TPersistent)
  private
    f_a, f_b: array [0 .. 30] of textFile; /// file variables and names for output
    fn_a, fn_b: array [0 .. 30] of string;
    FMaxValue: real; /// maximum value during sensitivity analysis
    FMinValue: real; /// minimum value during sensitivity analysis
    FSteps: integer; /// Steps of sensitivity analysis
    FDPar: real;
    Sens_f: textfile; /// Textfile variable for output
    FSens_fn: TMyFileName; /// output file name for sensitivity data
    MultSens_f_final, MultSens_f_cont : textfile;

    procedure SetMAxValue(const MaxValue: real);
    procedure SetMinValue(const MinValue: real);
    procedure SetSteps(const Steps: integer);
  protected
  public
    SelSenspar: TPar; /// Parameter selected for sensitivity analysis
    FOutList: TStringList; /// Variables selected for output
    MultSens_fn_final, MultSens_fn_cont : TMyFileName;
    constructor create;
  published
    property MaxValue: real read FMaxValue write SetMAxValue;
    property MinValue: real read FMinValue write SetMinValue;
    property Steps: integer read FSteps write SetSteps;
    property DPar: real read FDPar write FDPar;
    property OutList: TStringList read FOutList write FOutList;
    property Sens_fn: TMyFileName read FSens_fn write FSens_fn;
  end;

  TSubmodel = class;

  {* -----------------------------------------------------------------
    CLASS     TMod
    ANCESTOR  TGraphicControl
    PURPOSE   Basic model integrator and control module:
    Provides routines for simulation process control,
    parameter estimation and statistical quality control
    ------------------------------------------------------------------ }
  TMod = class(TGraphicControl)
  private
//    fName : string; /// Name of Model
    EXE_DIR: string;
    fParent: TWinControl;
    fStatusBar: TStatusBar;
    FTitle: string; /// Modeltitle
    FReg_FN: TMyFileName; /// Name of file where regression results are stored
    fDocu_FN: TMyFileName; /// Name of file where Model documentatin is stored
    FOutputPath: TPath; /// default directory for output
    FInputPath: TPath; /// Default directory for input
    FApplicationPath: TPath; ///
    FSeparatorChar: Char; /// separator in outputfiles
    FTimeStep: real; /// Time step for model integration
    FStartTime: TDateTime; /// Start of simulation
    FEndTime: TDateTime; /// End of simulation
    FSensOptions: TSensitivityOptions; /// Options for sensitivity analysis
    FContOutput: boolean; /// Toggle choice for file output every time step
    FFinalOutput: boolean; /// Toggle choice for file output end of simulation
    FMinLegalValue: real; /// smallest measured value accepted in Optimization
    fReInitAfterRun: boolean;
    /// flag if model should be reinitalised after run: defaul: true
    fShowDateFormat: boolean; /// flag for showing time in date format



    FStr_SectionName_TimeInit, /// strings for section names in Ini files
    FStr_SectionNameMeasurementFiles, FStr_SectionNameUpdateFiles,
      FStr_SectionNameOutputFiles, FStr_SectionName_FileNames,
      FStr_SectionTopic_SimStart, FStr_SectionTopic_SimEnd,
      FStr_SectionTopic_TimeStep, FStr_SectionTopic_StateIniFN,
      FStr_SectionTopic_ParamIniFN, FStr_SectionTopic_OptionIniFN,
      FStr_SectionTopic_WeatherFileFN: string;

    procedure setSubModel(index: integer; const SubModel: TSubmodel);
    function getSubModel(index: integer): TSubmodel;
    procedure Set_StartTime(const StartTime: TDateTime);
    procedure Set_EndTime(const EndTime: TDateTime);
    procedure Set_ControlFileFN(const fn_: TMyFileName);
    function Get_ControlFileFn: TMyFileName;
    procedure Set_TimeStep(const TimeStep: real);

    procedure WriteSensNames(Variable: Tvar; var f: text);
    procedure WriteSensValue(Variable: Tvar; Iter: integer; var f_a, f_b: text);
  protected
    procedure Paint; override; /// Method for showing object on the screen
    procedure writeRes(fn: string); /// write parameters and filenames of simulation run to result file
  public
    FLMOptions: TMarquardOptions; /// Options for optimization
    StatusBarOpt: TStatusBar;
    ControlFile: textFile;
    /// ControlFile containing list of Inifiles to be executed
    ControlFileFn: TMyFileName; /// Name for controlfile
    FIniFiles: TStringList; /// List of Inifiles
    FRegFile: textFile; /// File variable of results of regression analysis
    Time: TState; /// model time
    SubModStrList: TStringList; /// List of sub-models
    ModelEnd: boolean; /// End of simulation ?
    ActIniFile: TMyIniFile; /// TMyIniFile; // actual Ini-File
    ParamInifile: TMyIniFile; /// Ini-file with parameter values
    ParamCommentFile: TMyIniFile;
    StateIniFile: TMyIniFile; /// Ini-file with state variable initial values
    OptionIniFile: TMyIniFile; /// Ini-file with options for submodels
    WeatherFile: TTextFileH; /// Weather data
    AllMeasVal: TMeasList; /// list of all measurement values
    SelParList: TStringList; /// adress list of all parameters to be optimized
    FirstWeatherData: integer;
    LastWeatherData: integer;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure GetParameter(ParName: string; var Par: TPar;
      var SubModname: string; var Success: boolean);
    procedure GetStateVar(StateName: string; var State: TState;
      var SubModname: string; var Success: boolean);
    procedure GetVariable(VarName: string; var Variable: Tvar;
      var SubModname: string; var Success: boolean);
    procedure run; virtual; /// run method
    procedure runActIni; virtual; /// run method for actual INI-file
    procedure Init(IniFile: TMyIniFile); virtual; /// Initialisation method
    procedure InitAllSubMods; /// call inititalisation methods of sub-models
    procedure InitAllDataSeries;
    /// call data inititalisation methods of sub-models
    procedure integrateAllSubModels; virtual;
    /// call integration methods of all sub-models
    procedure CalcAllRates; /// call rate calculations of all sum-models
    procedure CalcAllVars;
    procedure UpdateAll;
    /// call update procedure for all sub-models if applicable
    procedure WriteAllNames; ///
    procedure WriteAllFinalNames; ///
    procedure AddAllSimValuestoDataSeries; ///
    procedure SaveStates;
    procedure SaveFinalStates; /// save last values of states in file
    procedure SaveRates; /// save last values of rates in file
    procedure CloseAllFiles;
    procedure CloseAllFinalFiles;
    procedure WriteAll_1_1_Files;
    procedure CalcAllLinearRegressions;
    function InitAllExternV: boolean;
    procedure IsFinished; virtual; /// chech for model termination condition
    procedure CalcChiSq; /// calculation of sum of squared differences
    procedure ClearAllDataSeries;
    procedure MarquardOptimization; /// Optimization routine
    procedure CalcSensitivity; /// Sensitivity analysis for single simulation run
    procedure CalcSensitivityMultRun; /// Sensitivity analysis for single simulation run

    procedure CalcChiSquareSensitivity;
    /// Sensititvity of ChiSquare Values over 1 to several simulation runs
    procedure DblClick; override; /// show info during runtime
    procedure write_documentation; /// write some text file for documentation
    property SubModel[Index: integer]
      : TSubmodel read getSubModel write setSubModel;
    /// Array property for convenient Access of Submodels

  published
 //   property Name:string read fName write fName; /// Name of Model
    property Parent: TWinControl read fParent write SetParent;
    property GM_ControlFile: TMyFileName read Get_ControlFileFn write
      Set_ControlFileFN;
    property GM_SubModStrList: TStringList read SubModStrList
    { write SubModStrList } ;
    property ApplicationPath
      : TPath read FApplicationPath write FApplicationPath;
    property GM_OutPutPath: TPath read FOutputPath write FOutputPath;
    property GM_InPutPath: TPath read FInputPath write FInputPath;
    property Separator
      : Char read FSeparatorChar write FSeparatorChar default ',';
    property TimeStep: real read FTimeStep write Set_TimeStep;
    property StartTime: TDateTime read FStartTime write Set_StartTime;
    property EndTime: TDateTime read FEndTime write Set_EndTime;
    property Visible;
    property Reg_fn: TMyFileName read FReg_FN write FReg_FN;
    property Docu_fn: TMyFileName read fDocu_FN write FDocu_FN;
    property ModTime: TState read Time write Time;
    property LMOptions: TMarquardOptions read FLMOptions write FLMOptions;
    property SensOpt: TSensitivityOptions read FSensOptions write FSensOptions;
    property Canvas;
    property IniFileNames: TStringList read FIniFiles;
    property Title: string read FTitle write FTitle;
    property ContOutput: boolean read FContOutput write FContOutput;
    property FinalOutput: boolean read FFinalOutput write FFinalOutput;
    property MinLegalValue: real read FMinLegalValue write FMinLegalValue;
    /// smallest measurement value accepted in optimization
    property StatusBar: TStatusBar read fStatusBar write fStatusBar;
    property Str_SectionName_TimeInit
      : string read FStr_SectionName_TimeInit write
      FStr_SectionName_TimeInit;
    property Str_SectionName_FileNames
      : string read FStr_SectionName_FileNames write
      FStr_SectionName_FileNames;
    property Str_SectionName_MeasurementFiles
      : string read FStr_SectionNameMeasurementFiles write
      FStr_SectionNameMeasurementFiles;
    property Str_SectionName_UpdateFiles
      : string read FStr_SectionNameUpdateFiles write
      FStr_SectionNameUpdateFiles;
    property Str_SectionName_OutPutFiles
      : string read FStr_SectionNameOutputFiles write
      FStr_SectionNameOutputFiles;
    property Str_SectionTopic_SimStart
      : string read FStr_SectionTopic_SimStart write
      FStr_SectionTopic_SimStart;
    property Str_SectionTopic_SimEnd
      : string read FStr_SectionTopic_SimEnd write
      FStr_SectionTopic_SimEnd;
    property Str_SectionTopic_TimeStep
      : string read FStr_SectionTopic_TimeStep write
      FStr_SectionTopic_TimeStep;
    property Str_SectionTopic_StateIniFN
      : string read FStr_SectionTopic_StateIniFN write
      FStr_SectionTopic_StateIniFN;
    property Str_SectionTopic_ParamIniFN
      : string read FStr_SectionTopic_ParamIniFN write
      FStr_SectionTopic_ParamIniFN;
    property Str_SectionTopic_WeatherFileFN
      : string read FStr_SectionTopic_WeatherFileFN write
      FStr_SectionTopic_WeatherFileFN;
    property Str_SectionTopic_OptionIniFN
      : string read FStr_SectionTopic_OptionIniFN write
      FStr_SectionTopic_OptionIniFN;
    property ReInitAfterRun: boolean read fReInitAfterRun write fReInitAfterRun;
    property ShowDateFormat: boolean read fShowDateFormat write fShowDateFormat;
  end; /// end of Object TMod

  {* -----------------------------------------------------------------
    CLASS     TSubmodel
    ANCESTOR  TGraphicControl
    PURPOSE   Base class of all sub-models: Provides routines for
    initialization, input and ouput and integration
    ------------------------------------------------------------------ }
  TSubmodel = class(TGraphicControl)
  private
    fParent: TWinControl;
    FCompIndex: integer; /// Index of computation order
    fAssimilatedSubmodList: TStringList;
    fUpdateValueList: TStringList;

   fModelElementLists : TListsOf;
    procedure RegistrateParameter(Par: TPar); virtual;
    procedure RegistrateOption(Option: TOption); virtual;
    procedure RegistrateVariable(Variable: Tvar);
    procedure RegistrateStateVar(State: TState); virtual;
    procedure RegistrateSubMod(SubModname: string; var Model: TMod);
    procedure ClearDataSeries;
    procedure set_State(index: integer; const State: TState);
    function get_State(index: integer): TState;
    procedure set_Par(index: integer; const Par: TPar);
    function Get_Par(index: integer): TPar;
    procedure set_Var(index: integer; const Variable: Tvar);
    function Get_Var(index: integer): Tvar;
    procedure set_Const(index: integer; const Constant: Tvar);
    function get_Const(index: integer): Tvar;
    procedure set_Option(index: integer; const Option: TOption);
    function get_Option(index: integer): TOption;
    procedure set_ExternVar(index: integer; const ExternVar: TExternV);
    function get_ExternVar(index: integer): TExternV;
  protected
    function Get_GlobMod: TMod;
    procedure Set_GlobMod(Model: TMod); virtual;
    procedure Paint; override; /// new Paint procedure
    function UpdateValue(n: string): real;
  public
    SubModname: string; /// Name of instance
    GlobMod: TMod; /// Instance of class Tmod to which sub-model is linked
    StateStrList: TStringList; /// List of state variables
    ParStrList: TStringList; /// List of parameters
    VarStrList: TStringList; /// List of variables
    ConstStrList: TStringList; /// List of constants
    OptionStrList: TStringList; /// List of Options (saved as strings)
    ExternVStrList: TStringList; /// List of external values
    ParIniF: TMyIniFile; /// Ini-file with paramters
    ParCommentF: TMyIniFile;
    StateIniF: TMyIniFile; /// Ini-file with initial values of state variables
    OptionIniF: TMyIniFile; /// Ini-file with options
    f_state, /// File variable for state output
    ffin_state, /// File variable for final state output
    f_rate: text; /// File variable for rate output
    fn_state, /// File name for state output
    fn_finalstate, /// File name for final output of states
    fn_rate: TMyFileName; /// File name for rate output
    FMeasValues: TTextFileH; /// file with measured data
    FMeasValues_2: TTextFileH; /// file with measured data
    FUpdValues: TTextFileH; /// file with measured data for updating
    SomethingMeasured: boolean; /// true if measurement data is available
    DoUpdate: boolean; /// true if data for updating is available
    NextUpdate: Double; /// Time of next Update
    DataList: TStringList; /// List of measured data series
    IsActive: boolean; /// Check for inactivation
    WriteTofile: boolean;
    ShowWarnings: boolean; /// show warnings ?
    GlobTime: TState; /// global time of simulation model
    constructor Create(AOwner: TComponent); override;
    destructor destroy; override;


    procedure BeforeDestruction; override;
    procedure ParCreate(ParName: string; /// method for creating and
      /// and initialising a TPar variable
      ParUnits: string; DefaultValue: real; var Par: TPar; comm: string = '');
      virtual;
    procedure OptCreate(OptName: string; /// creation objects for options
      Defaultstring: string; var Option: TOption; comm: string = '');
    procedure VarCreate(VarName: string; /// method for creating and
      VarUnits: string; /// and initialising a TVar variable
      DefaultValue: real; ReadFromFile: boolean; var Variable: Tvar;
      comm: string = '');
    procedure StateCreate(StateName: string; /// method for creating and
      StateUnits: string; /// and initialising a TState variable
      DefaultValue: real; ReadFromFile: boolean; var State: TState;
      comm: string = ''); virtual;
    procedure ExternVcreate(Name, Units: string; /// method for creating and
      ExV: TexValue; /// and initialising a TExternV variable
      var ExternV: TExternV; comm: string = ''); virtual;
    function ExternVinit(Model: TMod): boolean; virtual;
    /// setting pointers of external variables
    procedure CreateAll; virtual; /// Instantiates all objects
    procedure Init(var GlobMod: TMod); virtual; /// initialisation method
    procedure CalcRates; virtual; /// rate calculation
    procedure Integrate; virtual; /// integration of state variables
    procedure CalcVars; virtual; /// calculation of rate variables
    procedure UpdateValues; virtual; /// Update by measured values
    procedure WriteStateName(var f: text; fn: string; Time: TState);
    procedure WriteRateName(var f: text; fn: string; Time: TState);
    procedure SaveState(var f: text; fn: string; Time: TState); virtual;
    procedure SaveRate(var f: text; fn: string; Time: TState); virtual;
    procedure closeOutputfiles; virtual;
    procedure activate; virtual;
    procedure deactivate; virtual;
    procedure AddDataValueToDataSeries; virtual;
    /// adding data Values to Data series
    procedure AddSimValueToDataSeries; virtual;
    /// adding sim values to corresponding
    /// measured data
    procedure write_1_1_files; virtual; /// output of sim./meas. data pairs
    procedure CalcLinearRegressions; /// calculation of linear regression
    procedure DblClick; override;


    /// property Submodel[Index:integer]: TSubmodel read GetSubmodel write SetSubmodel; // Array property for convenient Access of Submodels
    property StateVar[index: integer]: TState read get_State write set_State;
    /// List of state variables
    property ParamVar[index: integer]: TPar read Get_Par write set_Par;
    property VarVar[index: integer]: Tvar read Get_Var write set_Var;
    property ConstVar[index: integer]: Tvar read get_Const write set_Const;
    property Option[index: integer]: TOption read get_Option write set_Option;
    property ExternVar[index: integer]
      : TExternV read get_ExternVar write set_ExternVar;
  published
    property Parent: TWinControl read fParent write SetParent;
    property SM_GlobMod: TMod read Get_GlobMod write Set_GlobMod;
    property SM_ExternVStrList: TStringList read ExternVStrList
    { write Set_ExternVStrList } ;
    property SM_VarStrList: TStringList read VarStrList
    { write  Set_VarStrList } ;
    property SM_ConstStrList: TStringList read ConstStrList
    { write  Set_VarStrList } ;
    property SM_ParStrList: TStringList read ParStrList
    { write Set_ParStrList } ;
    property SM_StateStrList: TStringList read StateStrList
    { write Set_ParStrList } ;
    property OnDblClick;
    property Visible;
    property CompIndex: integer read FCompIndex write FCompIndex;
    property Canvas;
    property FN_ratefn: TMyFileName read fn_rate write fn_rate;
    property FN_Statefn: TMyFileName read fn_state write fn_state;
    property f_MeasFile: TTextFileH read FMeasValues write FMeasValues;
    // property fn_MeasFile: TMyFileName read get_fnMeasFile write set_fnMeasFile;
    property AssimilatedSubmodList
      : TStringList read fAssimilatedSubmodList write
      fAssimilatedSubmodList;
    property color default clgreen;
  end;

  // end of object TSubModel
  {* -----------------------------------------------------------------
    CLASS     TModEditor
    ANCESTOR  TComponentEditor
    PURPOSE   Exchanges data with TModelEdit form and
    starts designtime editing
    ------------------------------------------------------------------ }

 {[
  TModEditor = class(TcomponentEditor)
    procedure Edit; override;
  end;

  TSubModelEditor = class(TcomponentEditor)
    procedure Edit; override;
  end;    }


implementation

uses
  Forms, UMrqMinD; // HUME: routines for parameter estimation (Marquard method)

{* *****************************************************************
  CLASS   TMarquardOptions
  METHOD  create
  PURPOSE Creating an TMarquardOptions instance, used for parameter estimation
  ****************************************************************** }

constructor TMarquardOptions.create;
begin
  inherited create;
  FDivisor := 100; // Value which is needed for numerical
  // approximation of function derivative
  FIniLambda := 0.001; // Initial value of parameter Lambda
  FDefaultError := 0.1; // one may use an default error for weighting
  OptOption := optOnlyActIni;
end;

{* *****************************************************************
  CLASS   TSensitivityOptions
  METHOD  create
  PURPOSE Create an TSensitivityOptions instance to save options for
  Sensitivity analysis used within the TMod class
  ****************************************************************** }

constructor TSensitivityOptions.create;
begin
  inherited create;
  FOutList := TStringList.create; // Variables selected for output
  FMinValue := 1.0; // minimum value during sensitivity analysis
  FMaxValue := 10.0; // maximum value during sensitivity analysis
  FSteps := 5; // Steps of sensitivity analysis
  FDPar := 1;
  FSens_fn := 'Sens.dat' // output file name for sensitivity data
end;

{* *****************************************************************
  CLASS   TSensitivityOptions
  METHOD  SetMaxValue
  PURPOSE Sets maximum value during sensitivity analysis
  INPUT   const MAxValue: real
  ****************************************************************** }

procedure TSensitivityOptions.SetMAxValue(const MaxValue: real);
begin
  FMaxValue := MaxValue;
  FDPar := (FMaxValue - FMinValue) / (FSteps - 1);
end;

{* *****************************************************************
  CLASS   TSensitivityOptions
  METHOD  SetMinValue
  PURPOSE Sets minimum value during sensitivity analysis
  INPUT   const MinValue: real
  ****************************************************************** }

procedure TSensitivityOptions.SetMinValue(const MinValue: real);
begin
  FMinValue := MinValue;
  FDPar := (FMaxValue - FMinValue) / (FSteps - 1);
end;

{* *****************************************************************
  CLASS   TSensitivityOptions
  METHOD  SetSteps
  PURPOSE Sets number of steps of sensitivity analysis
  INPUT   const Steps: integer
  ****************************************************************** }

procedure TSensitivityOptions.SetSteps(const Steps: integer);
begin
  FSteps := Steps;
  FDPar := (FMaxValue - FMinValue) / (FSteps - 1);
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Paint
  PURPOSE Method for showing object on the screen
  ****************************************************************** }

procedure TMod.Paint;
var
  X, Y, w, h, text_left, text_length: integer;
  Titel: string;
begin
  inherited;
  Titel := Name;
  with Canvas do
  begin
    X := Pen.Width div 2;
    Y := X;
    w := Width - Pen.Width + 1;
    h := Height - Pen.Width + 1;
    RoundRect(X, Y, X + w, Y + h, 8, 8);
    text_length := TextWidth(Titel);
    text_left := (Width - text_length) div 2;
    TextOut(text_left, Height div 2 - TextHeight(Titel) div 2, Titel);
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Get_ControlFileFn
  PURPOSE Gets name of Control file (published for use in object inspector)
  OUTPUT  TMyFileName
  ****************************************************************** }

function TMod.Get_ControlFileFn: TMyFileName;
begin
  Result := ControlFileFn;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Set_ControlFileFN
  PURPOSE Sets name of control Ini file (published for use in object inspector)
  INPUT   const fn: TMyFileName
  COMMENT If no control files are existing they will be created
  ****************************************************************** }

procedure TMod.Set_ControlFileFN(const fn_: TMyFileName);
var
  act_IniFn: string;
  NewInifile: TMyIniFile;
  fn: TMyFileName;
  DlgFileOpen: TopenDialog;
  NewFile: boolean;
  FPropIniFile: TMyIniFile;
begin
  FPropIniFile := TMyIniFile.create(ExtractFilePath(ParamStr(0))
      + 'properties.ini');

  fn := FPropIniFile.ReadString('Files', 'ControlFile', fn_);

  // control files have ".fn" file extension

  ControlFileFn := fn;

  // start dialog if no control file found on specified path
  if not FileExists(fn) then
  begin
    DlgFileOpen := TopenDialog.create(Application);
    with DlgFileOpen do
    begin
      Filter := 'Controlfiles {*.fn)|*.fn';
      Title := 'Open Control File';
      DefaultExt := 'fn';
      Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
      if Execute then
      begin
        ControlFileFn := Filename;
        assignfile(ControlFile, Filename);
      end;
      DlgFileOpen.Free;
    end;
  end
  else
  begin
    assignfile(ControlFile, fn);
  end;
  reset(ControlFile);

  if FIniFiles = NIL then
    FIniFiles := TStringList.create;

  // go through list of all Ini files specified in control file
  while not eof(ControlFile) do
  begin
    // open or create next Ini file and add to Ini file list of TMod
    NewFile := false;
    readln(ControlFile, act_IniFn);

    if trim(act_IniFn) = '' then
      continue;

    if not FileExists(act_IniFn) then
      NewFile := true;
    NewInifile := TMyIniFile.create(act_IniFn);
    with NewInifile do
    begin
      CaseSensitive := false;
      FIniFiles.AddObject(Filename, NewInifile);
      // if Ini file is newly created put some default values in it
      if NewFile then
      begin
        WriteFloat(Str_SectionName_TimeInit, Str_SectionTopic_SimStart, 0.0);
        WriteFloat(Str_SectionName_TimeInit, Str_SectionTopic_SimEnd, 100.0);
        WriteFloat(Str_SectionName_TimeInit, Str_SectionTopic_TimeStep, 1.0);
        Writestring(Str_SectionName_FileNames, Str_SectionTopic_StateIniFN,
          GetCurrentDir + '\State.ini');
        Writestring(Str_SectionName_FileNames, Str_SectionTopic_ParamIniFN,
          GetCurrentDir + '\Parameters_x.ini');
        UpdateFile;
      end;
    end;
    { MessageDlg('IniFile ' + Act_IniFn + ' does not exist !',
      mtInformation, [mbOK], 0);
      end; }
  end;
//  NewInifile.Free;
  // activate and initialize first of all Ini files specified in control file
  ActIniFile := TMyIniFile(FIniFiles.objects[0]);
  ActIniFile.UpdateFile;
  // f_ParamIniFile.FileName := ActIniFile.ReadString(Str_SectionName_FileNames, Str_SectionTopic_ParamIniFN, '');
  // f_StateIniFile.FileName := ActIniFile.ReadString(Str_SectionName_FileNames, Str_SectionTopic_StateIniFN, '');
  // showmessage(actinifile.FileName);
  self.init(ActIniFile);

  CloseFile(ControlFile);
  FPropIniFile.Free;
end;

procedure TMod.setSubModel(index: integer; const SubModel: TSubmodel);
begin
  SubModStrList.objects[index] := SubModel;
end;

function TMod.getSubModel(index: integer): TSubmodel;
begin
  Result := nil;
  if (index >= 0) and (index <= SubModStrList.count) then
    Result := TSubmodel(SubModStrList.objects[index])
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Set_TimeStep
  PURPOSE Set time step for model integration
  INPUT   const TimeStep: real
  ****************************************************************** }

procedure TMod.Set_TimeStep(const TimeStep: real);
begin
  FTimeStep := TimeStep;
  Time.c := TimeStep;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Set_StartTime
  PURPOSE Sets start time of simulation
  INPUT   const StartTime: TDateTime
  ****************************************************************** }

procedure TMod.Set_StartTime(const StartTime: TDateTime);
begin
  FStartTime := StartTime;
  Time.v := StartTime;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Set_EndTime
  PURPOSE Sets end time of simulation
  INPUT   const EndTime: TDateTime
  ****************************************************************** }

procedure TMod.Set_EndTime(const EndTime: TDateTime);
begin
  FEndTime := EndTime;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  init
  PURPOSE Initialize state, parameter and weather files; init time
  settings; resort submodels
  ****************************************************************** }

procedure TMod.init;
var
  StateInifilefn: string;
  ParamIniFilefn: string;
  ParamCommentFilefn: string;
  OptionInifilefn: string;
  WeatherFilefn: string;
  f: textFile;
  i, j: integer;
  TempString: TStringList;
begin
  // change to application directory
  if (FApplicationPath <> '') and DirectoryExists(FApplicationPath) then
  begin
    chdir(self.FApplicationPath);
  end;
  // check decimal separator setting
  if DecimalSeparator <> '.' then begin
    ShowMessage('Decimal Separator is '+DecimalSeparator+' - please change to .');
    Exit;
  end;
  // read state Ini file name and create if not existing
  StateInifilefn := ActIniFile.ReadString(Str_SectionName_FileNames,
    Str_SectionTopic_StateIniFN, '');
  if not FileExists(StateInifilefn) then
  begin
    if StateInifilefn = '' then
    begin
      StateInifilefn := EXE_DIR + '\State.ini';
      ActIniFile.Writestring(Str_SectionName_FileNames,
        Str_SectionTopic_StateIniFN, StateInifilefn);
      ActIniFile.UpdateFile;
    end;
    assignfile(f, StateInifilefn);
    rewrite(f);
    writeln(f);
    close(f);
  end;

  // read parameter Ini file name and create if not existing
  ParamIniFilefn := ActIniFile.ReadString(Str_SectionName_FileNames,
    Str_SectionTopic_ParamIniFN, '');
  if not FileExists(ParamIniFilefn) then
  begin
    if ParamIniFilefn = '' then
    begin
      ActIniFile.Writestring(Str_SectionName_FileNames,
        Str_SectionTopic_ParamIniFN, ParamIniFilefn);
      ActIniFile.UpdateFile;
    end;
    assignfile(f, ParamIniFilefn);
    rewrite(f);
    writeln(f);
    close(f);
  end;

  ParamCommentFilefn := ExtractFilePath(ParamIniFilefn) + 'ParamComments.ini';
  if not FileExists(ParamCommentFilefn) then
  begin
    assignfile(f, ParamCommentFilefn);
    rewrite(f);
    writeln(f);
    close(f);
  end;

  // read Option Ini file name and create if not existing
  OptionInifilefn := ActIniFile.ReadString(Str_SectionName_FileNames,
    FStr_SectionTopic_OptionIniFN, '');
  if not FileExists(OptionInifilefn) then
  begin
    if OptionInifilefn = '' then
    begin
      OptionInifilefn := GetCurrentDir + '\Options.ini';
      ActIniFile.Writestring(Str_SectionName_FileNames,
        FStr_SectionTopic_OptionIniFN, OptionInifilefn);
      ActIniFile.UpdateFile;
    end;
    assignfile(f, OptionInifilefn);
    rewrite(f);
    // showmessage(OptionInifilefn);
    writeln(f);
    close(f);
  end;

  // read weather file name and create if not existing
  WeatherFilefn := ActIniFile.ReadString(Str_SectionName_FileNames,
    Str_SectionTopic_WeatherFileFN, '');
  if not FileExists(WeatherFilefn) then
  begin
    ShowMessage('WeatherFile ' + WeatherFilefn + ' does not exist');
    exit;
  end;

  // init weather data file
  // if fileExists(WeatherFilefn) then
  // WeatherFile.Init(WeatherFileFN);

  StateIniFile.free;
  StateIniFile := TMyIniFile.create(StateInifilefn);
  StateIniFile.CaseSensitive := false;

  ParamInifile.free;
  ParamInifile := TMyIniFile.create(ParamIniFilefn);
  ParamInifile.CaseSensitive := false;

  ParamCommentFile.free;
  ParamCommentFile := TMyIniFile.create(ParamCommentFilefn);
  ParamCommentFile.CaseSensitive := false;

  OptionIniFile.free;
  OptionIniFile := TMyIniFile.create(OptionInifilefn);
  OptionIniFile.CaseSensitive := false;
  // init weather data file again (?)
  TempString := TStringList.create; // Treue
  if FileExists(WeatherFilefn) then
  begin
    // WeatherFile.init(WeatherFileFN);
    WeatherFile.Free;
    WeatherFile := TTextFileH.create(WeatherFilefn);
    // TempString := TStringList.Create; // Treue
    TempString.CommaText := WeatherFile.GetFirstLine; // Treue
    FirstWeatherData := round(StrToFloat(TempString.Strings[0])); // Treue
    // TempString := TStringList.Create; // Treue

    TempString.CommaText := WeatherFile.GetLastLine; // Treue

    LastWeatherData := round(StrToFloat(TempString.Strings[0])); // Treue
    WeatherFile.GoTop;
  end;
  TempString.Free;

  // init time settings
  with IniFile do
  begin
    FStartTime := ReadFloat(Str_SectionName_TimeInit,
      Str_SectionTopic_SimStart, 0);
    FEndTime := ReadFloat(Str_SectionName_TimeInit, Str_SectionTopic_SimEnd,
      365);
    TimeStep := ReadFloat(Str_SectionName_TimeInit, Str_SectionTopic_TimeStep,
      1);
  end;

  if Time = nil then
    Time := TState.create('Time', '[d]', FStartTime, TimeStep, '')
  else
  begin
    Time.v := FStartTime;
    Time.c := TimeStep;
  end;

  ModelEnd := false;
  // resort string list of submodels
  // using bubblesort algorithm (corrected UB 08.07.2013)

  for j := SubModStrList.Count - 2 downto 0 do
    for i := 0 to j do
      if TSubmodel(SubModStrList.objects[i]).CompIndex > TSubmodel(SubModStrList.objects[i+1]).CompIndex
      then SubModStrList.Exchange(i,i+1);
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  InitAllsubMods
  PURPOSE Call inititalisation methods of sub-models
  ****************************************************************** }

procedure TMod.InitAllSubMods;
var
  SubModIndex: integer;
begin
  if self <> nil then
  begin
    for SubModIndex := 0 to self.SubModStrList.count - 1 do
    begin
      SubModel[SubModIndex].init(self);
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Create
  PURPOSE Calls inherited TGssraphicControl.create and  initializes
  properties, lists and files
  ****************************************************************** }

constructor TMod.create(AOwner: TComponent);
var
  i, NewIndex, OldIndex: integer;
  subMod: TSubmodel;
  SubName: string;
begin
  inherited;
  Width := 80;
  Height := 30;
  Canvas.Pen.Color := CLTeal; // CLWhite;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Width := 2;
  Canvas.Brush.Color := clred;
  Canvas.Brush.Style := bsSolid;
  Canvas.Font.Size := 14;
  // initialize several properties, lists and files
  SubModStrList := TStringList.create;
//  SubModStrList.OwnsObjects := true;
  SubModStrList.Sorted := False;
  if FIniFiles = NIL then // maybe already created
    FIniFiles := TStringList.create;
  AllMeasVal := TMeasList.create('All', '[-]');
  SelParList := TStringList.create;
  Separator := ',';
  // initialize model time settings
  Time := TState.create('Time', '[d]', 0.0, 1.0, '');
  FTimeStep := 1.0;
  FStartTime := StrToDateTime('01.01.1999');
  FEndTime := StrToDateTime('31.12.1999');
  fShowDateFormat := true;
  // initialize several properties, lists and files
  Cursor := CrHandPoint;
  FLMOptions := TMarquardOptions.create;
  SensOpt := TSensitivityOptions.create;
  // KLUSS WeatherFile := TTextfileH.create;
  ContOutput := true;
  FinalOutput := false;
  ReInitAfterRun := true;
  // WIESO HIER IN CREATE?
  // ODER IST submodlist NICHT IMMER LEER?
  // NACH WAS WIRD SORTIERT? CompIndex
  // re-sort list of submodels

  for i := 0 to SubModStrList.count - 1 do
  begin
    SubName := SubModStrList.Strings[i];
    ShowMessage('TMod.create: ' + SubName);
    subMod := TSubmodel(SubModStrList.objects[i]);
    OldIndex := SubModStrList.indexof(SubName);
    NewIndex := subMod.CompIndex;
    if NewIndex <> -1 then
      SubModStrList.Exchange(OldIndex, NewIndex);
  end;

  // sets smallest measured value accepted in Optimization
  FMinLegalValue := 1E-999;
  // set section names (used in ini files)
  FStr_SectionNameMeasurementFiles := 'MeasurementFiles';
  FStr_SectionNameUpdateFiles := 'UpdateFiles';
  FStr_SectionNameOutputFiles := 'OutPutFiles';
  FStr_SectionName_FileNames := 'FileNames';
  Str_SectionName_TimeInit := 'TimeInit';
  Str_SectionTopic_SimStart := 'Startzeit';
  Str_SectionTopic_SimEnd := 'Endzeit';
  Str_SectionTopic_TimeStep := 'TimeStep';
  Str_SectionTopic_ParamIniFN := 'ParamIniFN';
  FStr_SectionTopic_OptionIniFN := 'OptionsIniFN';
  Str_SectionTopic_WeatherFileFN := 'WeatherFileFN';
  Str_SectionTopic_StateIniFN := 'StateIniFN';
//  self.Name := 'HUME';
  EXE_DIR := extractFiledir(Application.exename);
  if self.GM_ControlFile = '' then begin
    //ShowMessage('No Controlfile specified');
    //halt;
    // does not work because controlfile is not specified from the property
    // at that moment
  end;
end;



destructor Tmod.destroy;

var
 SubMod, Entity, IniFile : integer;
 Element : TModelElements;

begin
 for Inifile := 0 to fInifiles.Count - 1 do
   FIniFiles.objects[IniFile].free;

 FIniFiles.Free;
 AllMeasVal.Free;
 SelParList.Free;
 self.Time.Free;
// self.SelParList.Free;

 self.FSensOptions.Free;
 self.FLMOptions.Free;
 self.WeatherFile.Free;
 for SubMod := SubModStrList.Count - 1 downto 0 do begin
   for Element := low(TModelElements) to high(TModelElements) do begin
     for Entity := Submodel[SubMod].fModelElementLists[Element].count-1 downto 0 do begin
        Submodel[SubMod].fModelElementLists[Element].objects[Entity].Free;
  //     Submodel[SubMod].fModelElementLists[Element].objects[Entity] := nil;
     end;
   end;
 end;
// for SubMod := 0 to SubModStrList.Count - 1 do
//     SubModel[SubMod].destroy;
 //SubModStrList.Free;

 inherited;
end;




{* *****************************************************************
  CLASS   TMod
  METHOD  WriteAllNames
  PURPOSE For all submodels write state and rate names to output files
  ****************************************************************** }

procedure TMod.WriteAllNames;
var
  i: integer;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    with SubModel[i] do
    begin
      if WriteTofile then
      begin
        WriteStateName(f_state, fn_state, Time);
        WriteRateName(f_rate, fn_rate, Time);
      end;
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  WriteAllFinalNames
  PURPOSE For all submodels write state names to final output file
  ****************************************************************** }

procedure TMod.WriteAllFinalNames;
var
  i: integer;
  subMod: TSubmodel;
  fn: string;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    if subMod.WriteTofile then
    begin
      // writes state names of specific submodel to _dat.csv file
     subMod.WriteStateName(subMod.ffin_state, subMod.fn_finalstate, Time);
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  AddAllSimValuestoDataSeries
  PURPOSE For each submodel add simulated values to corresponding measured data
  ****************************************************************** }

procedure TMod.AddAllSimValuestoDataSeries;
var
  i: integer;
  subMod: TSubmodel;
begin
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    subMod := TSubmodel(SubModStrList.objects[i]);
    // for each submodel add simulated values to corresponding measured data
    if subMod.SomethingMeasured then
      subMod.AddSimValueToDataSeries;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CalcAllRates
  PURPOSE For each submodel calculate rates
  ****************************************************************** }

procedure TMod.CalcAllRates;
var
  i: integer;
  subMod: TSubmodel;
begin
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if subMod.IsActive then
      subMod.CalcRates;
  end;
end;


{* *****************************************************************
  CLASS   TMod
  METHOD  CalcAllVars
  PURPOSE For each submodel calculate Variables
  ****************************************************************** }

procedure TMod.CalcAllVars;
var
  i: integer;
  subMod: TSubmodel;
begin
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if subMod.IsActive then
      subMod.CalcVars;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  UpdateAll
  PURPOSE For each submodel do update
  ****************************************************************** }

procedure TMod.UpdateAll;
var
  i: integer;
  subMod: TSubmodel;
begin
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if subMod.IsActive and subMod.DoUpdate and (Time.v >= subMod.NextUpdate)
      then
      subMod.UpdateValues;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  SaveRates
  PURPOSE For each submodel save rates to output files
  ****************************************************************** }

procedure TMod.SaveRates;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active save rates to _rat.csv output file
    if (subMod.IsActive) and (subMod.WriteTofile) then
      subMod.SaveRate(subMod.f_rate, subMod.fn_rate, Time);
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  SaveStates
  PURPOSE For each submodel save states to output files
  ****************************************************************** }

procedure TMod.SaveStates;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active save states to _dat.csv output file
    if (subMod.IsActive) and (subMod.WriteTofile) then
      subMod.SaveState(subMod.f_state, subMod.fn_state, Time);
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  SaveFinalStates
  PURPOSE For all submodels write state values to final output file
  ****************************************************************** }

procedure TMod.SaveFinalStates;
var
  i: integer;
  subMod: TSubmodel;
  fn : string;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active save final state values to _dat.csv output file
    if (subMod.IsActive) and (subMod.WriteTofile) then
      subMod.SaveState(subMod.ffin_state, submod.fn_finalstate , Time);
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  IntegrateAllSubModels
  PURPOSE For each submodel do integration
  ****************************************************************** }

procedure TMod.integrateAllSubModels;
var
  i: integer;
  subMod: TSubmodel;
begin
  Time.v := Time.v + Time.c; // next time step
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active call its integration routine
    if subMod.IsActive then
      subMod.Integrate;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  InitAllExternV
  PURPOSE For each submodel initialize external variables (setting their pointers)
  ****************************************************************** }

function TMod.InitAllExternV: boolean;
var
  i: integer;
  subMod: TSubmodel;
  success: boolean;
begin
  success := true;

  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if external values exist initialize them (setting their pointers)
    if subMod.ExternVStrList.count > 0 then
    begin
      success := success and subMod.ExternVinit(self);
      if not success then
        break;
    end;
  end;

  result := success;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CloseAllFiles
  PURPOSE For each submodel close state and rate output file (_dat.csv/_rat.csv)
  ****************************************************************** }

procedure TMod.CloseAllFiles;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // close state and rate output files
    subMod.closeOutputfiles;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CloseAllFinalFiles
  PURPOSE For each submodel close final state output files
  ****************************************************************** }

procedure TMod.CloseAllFinalFiles;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // close final state output file
    close(subMod.ffin_state);
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CalcAllRates
  PURPOSE For each submodel calculate rates
  ****************************************************************** }

procedure TMod.InitAllDataSeries;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if subMod.IsActive then
      subMod.AddDataValueToDataSeries;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  Run
  PURPOSE Run method
  INPUT
  OUTPUT
  COMMENT
  ****************************************************************** }
// {$APPTYPE CONSOLE}

procedure TMod.run;
var
  i: integer;
  fn: string;
  statFile: textFile;
  strlist, strlist_act: TStringList;
  globResFN, iniResFN: string;
  globRes: textFile;
begin
  // change directory to application path
  chdir(EXE_DIR);
  // clear list of all measurement values
  AllMeasVal.Clear;
  // For every submodel clear data pair series
  ClearAllDataSeries;
  // make sure that output directory exists
  if (GM_OutPutPath <> '') and (not DirectoryExists(GM_OutPutPath)) then begin
    if MessageDlg('Output directory '+GM_OutPutPath+'does not exist. Create directory?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes
    then begin
      if not CreateDir(GM_OutPutPath) then begin
        ShowMessage('Can not create '+GM_OutPutPath);
        Application.terminate;
      end;
    end
    else Application.terminate;
  end;
  Reg_fn := GM_OutPutPath + '\' + 'regression.dat';
  // For all submodels write state names to final output file
  if FinalOutput then
    WriteAllFinalNames;
  // Go through all INI files (listed in *.fn control file)

  // fn name
  fn := EXE_DIR + '\' + StripExtension(ExtractFileName(self.ControlFileFn))
    + '.stat';

  assignfile(statFile, fn);
  rewrite(statFile);
  CloseFile(statFile);
  globResFN := GM_OutputPath +'\'+StripExtension(ExtractFileName(self.ControlFileFn))+'_res.hrl';
  AssignFile(globRes,globResFN);
  Rewrite(globRes);
  for i := 0 to FIniFiles.count - 1 do
  begin
    // Determine and initialize actual INI file

    ActIniFile := TMyIniFile(FIniFiles.objects[i]);

    // showmessage(ActIniFile.FileName);

    self.init(ActIniFile);
    iniResFN := GM_OutputPath +'\'+StripExtension(ExtractFileName(ActIniFile.FileName))+'_res.ini';
    // Initialize all submodels
    InitAllSubMods;
    InitAllDataSeries;

    // Initialize all external variables
    InitAllExternV;

    // Set weather file pointer to actual time step
    // #TS#029: infinite loop depending on ModTime.Name

    WeatherFile.LocateFor(Time.Name, Time.v);
    // write names, state and rate values (if ContOutput true)

    if ContOutput then
    begin
      WriteAllNames;
      SaveStates;
      SaveRates;
    end;
    // central loop of TMod.Run
    repeat
      // rate calculation for all submodels
      CalcAllRates;
      // update values from measured data for all submodels if applicable
      UpdateAll;
      // integration for all submodels
      integrateAllSubModels;
      // add simulated values to corresponding measured data for all submodels
      AddAllSimValuestoDataSeries;
      // write state and rate values (if ContOutput)
      if ContOutput then
      begin
        SaveStates;
        SaveRates;
      end;
      if StatusBar <> nil then
      begin
        if ShowDateFormat then
          StatusBar.Panels.Items[1].text := ' Time: ' + DateTimeToStr(
            { FloatToDateTime } (Time.v))
        else
          StatusBar.Panels.Items[1].text := ' Time: ' + FloatToStrf(Time.v,
            ffgeneral, 6, 1);
        StatusBar.Repaint;
      end;
      // Sets TMod.ModelEnd to true if time counter passed endtime of model
      IsFinished;
      // step forward in weather file
      if Time.v >= WeatherFile.getIndexValue(0) then
      begin
        WeatherFile.NextLine;
        // weatherFile.CalcValues;
      end;
      // exit central loop if TMod.ModelEnd was flagged by IsFinished (see above)
    until ModelEnd;

    // showmessage(self.actinifile.filename);
    // close state and rate output files of all submodels
    if ContOutput then
      CloseAllFiles;
    // write state values to final output file for all submodels
    if FinalOutput then
      SaveFinalStates;
    { ShowMessage(ActIniFile.FileName); }
    writeRes(iniResFN);
    writeln(GlobRes, iniResFN);

    strlist := TStringList.create;
    strlist.loadFromFile(fn);
    strlist.add('');
    strlist.add('');
    strlist.add(FIniFiles[i]);
    strlist.add('');

    strlist_act := TStringList.create;

    // for all submodels calculate linear regression
    CalcAllLinearRegressions;

    if FileExists(Reg_fn) then
      strlist_act.loadFromFile(Reg_fn);
    strlist.addstrings(strlist_act);
    strlist.savetofile(fn);

    strlist.Free;
    strlist_act.Free;

    // DeleteFile(FReg_FN);    // für einzelberechnungen entfernen!
    // ClearAllDataSeries;     // für einzelberechnungen entfernen!
    // AllMeasVal.Clear;       // für einzelberechnungen entfernen!

  end; // End of simulation run
  CloseFile(GlobRes);
  // for all submodels calculate linear regression
   CalcAllLinearRegressions;
  // close final state and rate output files of all submodels
  if FinalOutput then
    CloseAllFinalFiles;
  // Output of simulated/measured data pairs to _1_1.csv files
  WriteAll_1_1_Files;
  // // for all submodels calculate linear regression
  // CalcAllLinearRegressions;
  // clear list of all measurement values
  AllMeasVal.Clear;
  // Calculation of sum of squared differences
  CalcChiSq;

end;

{* *****************************************************************
  CLASS   TMod
  METHOD  RunActIni
  PURPOSE Run method for actual INI-file only
  INPUT
  OUTPUT
  COMMENT
  ****************************************************************** }

procedure TMod.runActIni;
begin
  // change directory to application path
  // chdir(ExtractFiledir(application.ExeName));
  chdir(EXE_DIR);
  // clear list of all measurement values
  AllMeasVal.Clear;
  // For every submodel clear data pair series
  ClearAllDataSeries;
  // For all submodels write state names to final output file
  if FinalOutput then
    WriteAllFinalNames;
  // initialize actual INI file
  { ActIniFile := TMyIniFile(FIniFiles.objects[ActInifileIndex]); }
  init(ActIniFile);
  // Initialize all external variables
  InitAllExternV;
  // Initialize all submodels
  InitAllSubMods;
  InitAllDataSeries;
  // Set weather file pointer to actual time step
  // #TS#029: infinite loop depending on ModTime.Name
  WeatherFile.LocateFor(Time.Name, Time.v);
  // write names, state and rate values (if ContOutput true)
  if ContOutput then
  begin
    WriteAllNames;
    SaveStates;
    SaveRates;
  end;
  // central loop of TMod.Run
  repeat
    // rate calculation for all submodels
    CalcAllRates;
    // update values from measured data for all submodels if applicable
    UpdateAll;
    // integration for all submodels
    integrateAllSubModels;
    // add simulated values to corresponding measured data for all submodels
    AddAllSimValuestoDataSeries;
    // write state and rate values (if ContOutput)
    if ContOutput then
    begin
      SaveStates;
      SaveRates;
    end;
    // Sets TMod.ModelEnd to true if time counter passed endtime of model
    IsFinished;
    // step forward in weather file
    if Time.v >= WeatherFile.getIndexValue(0) then
    begin
      WeatherFile.NextLine;
      // weatherFile.CalcValues;
    end;
    // exit central loop if TMod.ModelEnd was flagged by IsFinished (see above)
  until ModelEnd;
  // showmessage(self.actinifile.filename);
  // close state and rate output files of all submodels
  if ContOutput then
    CloseAllFiles;
  // write state values to final output file for all submodels
  if FinalOutput then
    SaveFinalStates;
  { ShowMessage(ActIniFile.FileName); }
  // close final state and rate output files of all submodels
  if FinalOutput then
    CloseAllFinalFiles;
  // Output of simulated/measured data pairs to _1_1.csv files
  WriteAll_1_1_Files;
  // for all submodels calculate linear regression
  CalcAllLinearRegressions;

  // clear list of all measurement values
  // AllMeasVal.Clear;

  // Calculation of sum of squared differences
  CalcChiSq;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CalcSensitivity
  PURPOSE Sensitivity analysis
  COMMENT Note partial code similarities (resp. redundancies) to TMod.Run
  ****************************************************************** }

procedure TMod.CalcSensitivity;
var
  i, Iter: integer;
  ActParameterValue: real;
  OldParameterValue: real;
  ActVar: Tvar;
  rep, Success: boolean;
  line: string;
  SubModname, path: string;
  TempPar: TPar;
begin
  // flag false for first loop, flag true for second and following loops
  rep := false;
  // GetParameter(
  GetParameter(SensOpt.SelSenspar.name, TempPar, SubModname, Success);
  OldParameterValue := FSensOptions.SelSenspar.v;
  // chdir(ExtractFiledir(application.ExeName));
  chdir(EXE_DIR);
  // start with minimal value as actual value
  ActParameterValue := SensOpt.MinValue;
  // open output file for sensitivity analysis data (sens.dat)
  if extractfilepath(SensOpt.Sens_fn) = '' then
  // if fileexists(SensOpt.Sens_fn)= false then
    SensOpt.Sens_fn := GM_OutPutPath+SensOpt.Sens_fn;
  assignfile(SensOpt.Sens_f, SensOpt.Sens_fn);
  rewrite(SensOpt.Sens_f);
  // first row of output file: write name of selected sensitivity parameter
  write(SensOpt.Sens_f, SensOpt.SelSenspar.name, Separator);
  // first row of output file: write names of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(SensOpt.Sens_f, ActVar.name, Separator);
  end;
  writeln(SensOpt.Sens_f);
  // second row of output file: write units of selected sensitivity parameter
  write(SensOpt.Sens_f, SensOpt.SelSenspar.U, Separator);
  // second row of output file: write units of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(SensOpt.Sens_f, ActVar.U, Separator);
  end;
  writeln(SensOpt.Sens_f);

  // assign output files for selected variables (_sens_a.csv / _sens_b.csv)
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    SensOpt.fn_a[i] := self.GM_OutPutPath + ActVar.name + '_sens_a.csv';
    SensOpt.fn_b[i] := self.GM_OutPutPath + ActVar.name + '_sens_b.csv';
    assignfile(SensOpt.f_a[i], SensOpt.fn_a[i]);
    assignfile(SensOpt.f_b[i], SensOpt.fn_b[i]);
    rewrite(SensOpt.f_a[i]);
    rewrite(SensOpt.f_b[i]);
  end;
  // for each step of sensitivity analysis do...
  for Iter := 1 to SensOpt.Steps do
  begin
    ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.name, //
    ActParameterValue); //
    ParamInifile.UpdateFile; //

    // for all selected variables create _sens_a.csv file
    // and write variable names into first row
    for i := 0 to SensOpt.FOutList.count - 1 do
    begin
      rewrite(SensOpt.f_a[i]);
      ActVar := Tvar(SensOpt.FOutList.objects[i]);
      WriteSensNames(ActVar, SensOpt.f_a[i]);
    end;
    // if second step or later the reset _sens_b.csv files
    if rep then
    begin
      for i := 0 to SensOpt.FOutList.count - 1 do
      begin
        reset(SensOpt.f_b[i]);
      end;
    end;
    // prepare for simulation run, regarding the actual "step" of the
    // chosen sensitivity parameter
    ActIniFile := TMyIniFile(FIniFiles.objects[0]);
    init(ActIniFile);
    InitAllExternV;
    InitAllSubMods;
    InitAllDataSeries;
    // set parameter value according to step respectively loop count
    // first loop (see above): ActparameterValue := SensOpt.MinValue;
    // others (see below): ActParameterValue := ActParameterValue + SensOpt.DPar;
    SensOpt.SelSenspar.v := ActParameterValue;
    ActParameterValue := SensOpt.SelSenspar.v;
    // Set weather file pointer to actual time step
    WeatherFile.LocateFor(Time.Name, Time.v);
    { writeAllSensNames; }
    // doing the actual simulation (from start to end of model time)
    // for the actual "step" of the chosen sensitivity parameter
    repeat
      // calculate rates, integrate, go to next time step
      CalcAllRates;
      UpdateAll;
      integrateAllSubModels;
      // write variable values to output files
      for i := 0 to SensOpt.FOutList.count - 1 do
      begin
        ActVar := Tvar(SensOpt.FOutList.objects[i]);
        WriteSensValue(ActVar, Iter, SensOpt.f_a[i], SensOpt.f_b[i]);
      end;
      IsFinished;
      // step forward in weather file
      if Time.v >= WeatherFile.getIndexValue(0) then
      begin
        WeatherFile.NextLine;
        // weatherFile.CalcValues;
      end;
    until ModelEnd;
    // write parameter and variable values to output
    write(SensOpt.Sens_f, FloatToStrf(ActParameterValue, ffgeneral, 8, 4),
      Separator);
    for i := 0 to SensOpt.FOutList.count - 1 do
    begin
      ActVar := Tvar(SensOpt.FOutList.objects[i]);
      write(SensOpt.Sens_f, FloatToStrf(ActVar.v, ffgeneral, 8, 4), Separator);
    end;
    writeln(SensOpt.Sens_f);
    // increase value of sensitivity parameter by stepwidth
    ActParameterValue := ActParameterValue + SensOpt.DPar;

    // first loop has been done
    rep := true;
    // output file action: shift lines from sens_a_.csv to _sens_b_.csv

    for i := 0 to SensOpt.FOutList.count - 1 do begin
      closefile(SensOpt.f_a[i]);
      closefile(SensOpt.f_b[i]);
    end;


    for i := 0 to SensOpt.FOutList.count - 1 do
    begin
//      if fileexists(sensOpt.fn_a[i]) then
      reset(SensOpt.f_a[i]);
      readln(SensOpt.f_a[i]);
      readln(SensOpt.f_a[i]);
      rewrite(SensOpt.f_b[i]);
      while not eof(SensOpt.f_a[i]) do
      begin
        readln(SensOpt.f_a[i], line);
        writeln(SensOpt.f_b[i], line);
      end;
      closefile(SensOpt.f_a[i]);
      closefile(SensOpt.f_b[i]);
    end;
    { SaveFinalValues;
      CopyAllSensFiles; }
  end;
  // close output file (sens.dat)
  closefile(SensOpt.Sens_f);
  ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.name, //
  OldParameterValue); //
  ParamIniFile.UpdateFile; //
  // This TMod.CalcSensitivity method was called by the procedure
  // TFormSensOpt.ButtonRunSensClick from the unit UFormSelPar.
  // There, to present the sensitivity results, the string grid will
  // now be actualized and displayed
end;



procedure TMod.CalcSensitivityMultRun;



const
  ContFileNameStr = 'MultSensCont';
  FinalFileNameStr = 'MultSensFinal';

var
  i,j, Iter, inif: integer;
  ActParameterValue: real;
  OldParameterValue: real;
  ActVar: Tvar;
  rep, Success: boolean;
  FinalSensFileName, ContSensFileName, line,
  ParamInifileFN: string;
  SubModname: string;
  TempPar: TPar;
  FinalSensfile, ContSensFile: TextFile;

begin
  // flag false for first loop, flag true for second and following loops
  rep := false;
  // GetParameter(
  GetParameter(SensOpt.SelSenspar.name, TempPar, SubModname, Success);
  OldParameterValue := FSensOptions.SelSenspar.v;
  // chdir(ExtractFiledir(application.ExeName));
  chdir(EXE_DIR);

 // make sure that output directory exists
  if (GM_OutPutPath <> '') and (not DirectoryExists(GM_OutPutPath)) then begin
    if MessageDlg('Output directory '+GM_OutPutPath+'does not exist. Create directory?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes
    then begin
      if not CreateDir(GM_OutPutPath) then begin
        ShowMessage('Can not create '+GM_OutPutPath);
        Application.terminate;
      end;
    end
    else Application.terminate;
  end;

// prepare header for final output file
//  WriteAllFinalNames;

  // open output file for sensitivity analysis data (sens.dat)
  ContSensFileName := GM_OutPutPath+'\'+ContFileNameStr+'_'
                      +stripextension(ExtractFileName(ControlFileFN))
                       +'_'+SensOpt.SelSenspar.name+'_'+'.csv';


  SensOpt.MultSens_fn_cont :=  ContSensFileName;

  FinalSensFileName := self.GM_OutPutPath+'\'+FinalFileNameStr
                       +'_'+stripextension(ExtractFileName(ControlFileFN))
                       +'_'+SensOpt.SelSenspar.name+'_'+'.csv';
  SensOpt.MultSens_fn_final := FinalSensFileName;
  assignfile(ContSensFile, ContSensFileName);
  rewrite(ContSensFile);
  assignfile(FinalSensFile, FinalSensFileName);
  rewrite(FinalSensFile);


  // first row of output file: write IniFilename
  write(ContSensFile, 'IniFile', Separator);
  write(FinalSensFile, 'IniFile', Separator);

  // first row of output file: write name of selected sensitivity parameter
  write(ContSensFile, SensOpt.SelSenspar.name, Separator);
  write(FinalSensFile, SensOpt.SelSenspar.name, Separator);
  write(ContSensFile, 'Time', Separator);
  write(FinalSensFile, 'Time', Separator);

  // first row of output file: write names of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(ContSensFile, ActVar.name, Separator);
    write(FinalSensFile, ActVar.name, Separator);
  end;
  writeln(ContSensFile);
  writeln(FinalSensFile);

  // second row of output file: write units of selected sensitivity parameter

  write(ContSensFile, '[]', Separator,'[d]', Separator);
  write(FinalSensFile, '[]', Separator,'[d]', Separator);
  write(ContSensFile, SensOpt.SelSenspar.U, Separator);
  write(FinalSensFile, SensOpt.SelSenspar.U, Separator);

  // second row of output file: write units of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(ContSensFile, SensOpt.SelSenspar.U, Separator);
    write(FinalSensFile, SensOpt.SelSenspar.U, Separator);
  end;
  writeln(ContSensFile);
  writeln(FinalSensFile);

// start with minimal value as actual value
    ActParameterValue := SensOpt.MinValue;


// for each step of sensitivity analysis do...
  for Iter := 1 to SensOpt.Steps do begin
    for j := 0 to self.FInifiles.Count - 1 do begin
      ActIniFile := TMyIniFile(FIniFiles.objects[j]);
      ParamInifileFN := ActIniFile.ReadString('FileNames', 'ParamIniFN', '');
      ParamInifile.free;
      ParamInifile := TMyIniFile.create(ParamIniFilefn);
      ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.name, //
      ActParameterValue); //
      ParamInifile.UpdateFile; //
    end;

  // prepare for simulation run, regarding the actual "step" of the
  // chosen sensitivity parameter

    for inif := 0 to FIniFiles.count - 1 do begin
    // Determine and initialize actual INI file
      ActIniFile := TMyIniFile(FIniFiles.objects[inif]);
      init(ActIniFile);
      InitAllExternV;
      InitAllSubMods;
    //  InitAllDataSeries;
    // set parameter value according to step respectively loop count
    // first loop (see above): ActparameterValue := SensOpt.MinValue;
    // others (see below): ActParameterValue := ActParameterValue + SensOpt.DPar;
      SensOpt.SelSenspar.v := ActParameterValue;
      ActParameterValue := SensOpt.SelSenspar.v;
      // Set weather file pointer to actual time step
      WeatherFile.LocateFor(Time.Name, Time.v);
      { writeAllSensNames; }
      // doing the actual simulation (from start to end of model time)
      // for the actual "step" of the chosen sensitivity parameter
      repeat
      // calculate rates, integrate, go to next time step
        CalcAllRates;
        UpdateAll;
        integrateAllSubModels;
        // write variable values to output files
        write(ContSensFile, stripextension(ExtractFileName(ActIniFile.FileName)), Separator);
        write(ContSensFile, ActParameterValue, Separator);
        write(ContSensFile, self.Time.v, Separator);
        for i := 0 to SensOpt.FOutList.count - 1 do  begin
          ActVar := Tvar(SensOpt.FOutList.objects[i]);
          Write(ContSensFile, ActVar.v, Separator);
        end;
        writeln(ContSensFile);
        IsFinished;
      // step forward in weather file
        if Time.v >= WeatherFile.getIndexValue(0) then begin
          WeatherFile.NextLine;
          // weatherFile.CalcValues;
        end;
      until ModelEnd;

      write(FinalSensFile, stripextension(ExtractFileName(ActIniFile.FileName)), Separator);
      write(FinalSensFile, ActParameterValue, Separator);
      write(FinalSensFile, self.Time.v, Separator);
      for i := 0 to SensOpt.FOutList.count - 1 do
      begin
        ActVar := Tvar(SensOpt.FOutList.objects[i]);
        Write(FinalSensFile, ActVar.v, Separator);
      end;
      writeln(FinalSensFile);
      rep := true;
    end; // End of Loop IniFiles
    ActParameterValue := ActParameterValue + SensOpt.DPar;
  end;  // end of loop Parameter-Iteration
  closeFile(ContSensFile);
  closeFile(FinalSensFile);

    for j := 0 to self.FInifiles.Count - 1 do begin
      ActIniFile := TMyIniFile(FIniFiles.objects[j]);
      ParamInifileFN := ActIniFile.ReadString('FileNames', 'ParamIniFN','' );
      ParamInifile.free;
      ParamInifile := TMyIniFile.create(ParamIniFilefn);
      ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.name, //
      OldParameterValue);
      ParamInifile.UpdateFile; //
    end;

  end;


  // This TMod.CalcSensitivity method was called by the procedure
  // TFormSensOpt.ButtonRunSensClick from the unit UFormSelPar.
  // There, to present the sensitivity results, the string grid will
  // now be actualized and displayed


procedure TMod.writeRes(fn: string);
// write parameters and filenames of simulation run to result file
var
  f: textFile;
  i, j: integer;
  s: string;
  SubMod: TSubmodel;
  ActPar: TPar;
  ActOpt: TOption;
begin
  AssignFile(f, fn);
  Rewrite(f);
  // write information on Simulation run
  writeln(f, '[SimulationRun]');
  writeln(f, 'iniFile=',ActIniFile.FileName);
  writeln(f, 'TimeOfRun=',DateTimeToStr(Now));
  writeln(f);
  // write Measurement Data Filenames
  writeln(f, '[MeasurementFiles]');
  for i := 0 to submodstrlist.Count - 1 do begin
    SubMod := TSubModel(submodstrlist.Objects[i]);
    s := SubMod.FMeasValues.FileName;
{    // replace '\' by '/' for R
    for j := 1 to length(s) do if s[j]='\' then s[j]:='/';}
    if SubMod.SomethingMeasured then writeln(f,SubMod.Name,'=',s);
  end;
  writeln(f);
  // write State Output Filenames
  writeln(f, '[StateOutput]');
  for i := 0 to submodstrlist.Count - 1 do begin
    SubMod := TSubModel(submodstrlist.Objects[i]);
    s := SubMod.fn_state;
{    for j := 1 to length(s) do if s[j]='\' then s[j]:='/';}
    writeln(f,SubMod.Name,'=',s);
  end;
  writeln(f);
  // write State Output Filenames
  writeln(f, '[RateOutput]');
  for i := 0 to submodstrlist.Count - 1 do begin
    SubMod := TSubModel(submodstrlist.Objects[i]);
    s := SubMod.fn_rate;
{    for j := 1 to length(s) do if s[j]='\' then s[j]:='/';}
    writeln(f,SubMod.Name,'=',s);
  end;
  writeln(f);
  // write parameter list
  writeln(f, '[Paramters]');
  for i := 0 to submodstrlist.Count - 1 do begin
    SubMod := TSubModel(submodstrlist.Objects[i]);
    for j := 0 to SubMod.ParStrList.Count - 1 do begin
      ActPar := TPar(SubMod.ParStrList.Objects[j]);
      writeln(f, SubMod.name + '.' + ActPar.name,'=',FloatToStr(ActPar.v));
    end;
  end;
  writeln(f);
  // write options list
  writeln(f, '[Options]');
  for i := 0 to submodstrlist.Count - 1 do begin
    SubMod := TSubModel(submodstrlist.Objects[i]);
    for j := 0 to SubMod.OptionStrList.Count - 1 do begin
      ActOpt := TOption(SubMod.OptionStrList.Objects[j]);
      writeln(f, SubMod.name + '.' + ActOpt.name,'=',ActOpt.Option);
    end;
  end;
  CloseFile(f);
end;


procedure TMod.CalcChiSquareSensitivity;
var
  i, Iter: integer;
  OldParameterValues: array [0 .. 1000] of real;
  ActIniFile, ActparamInifile: TMyIniFile;
  ActParamFileName: string;
  Success: boolean;
  SubModname: string;
  TempPar: TPar;
begin
  // flag false for first loop, flag true for second and following loops
  // rep := false;
  // TODO ActParamIniFile := TMyInifile.Create;
  GetParameter(SensOpt.SelSenspar.name, TempPar, SubModname, Success);
  for i := 0 to self.IniFileNames.count - 1 do
  begin // read old Parameter values for saving
    ActIniFile := TMyIniFile(FIniFiles.objects[i]);
    ActParamFileName := ActIniFile.ReadString('FileNames', 'ParamIniFN',
      ActParamFileName);
    // ActParamInifile.FileName := ActParamfileName;
    ActparamInifile := TMyIniFile.create(ActParamFileName);
    ActparamInifile.CaseSensitive := false;
    OldParameterValues[i] := ActparamInifile.ReadFloat(SubModname,
      SensOpt.SelSenspar.name, OldParameterValues[i]); // , success);
  end;
  // chdir(ExtractFiledir(application.ExeName));
  chdir(EXE_DIR);
  // start with minimal value as actual value
  SensOpt.SelSenspar.SelForOpt := true;
  SensOpt.SelSenspar.v := SensOpt.MinValue;
  // open output file for sensitivity analysis data (sens.dat)
  assignfile(SensOpt.Sens_f, SensOpt.Sens_fn);
  rewrite(SensOpt.Sens_f);
  // first row of output file: write name of selected sensitivity parameter
  write(SensOpt.Sens_f, SensOpt.SelSenspar.name, Separator);
  // first row of output file: write names of selected variables
  writeln(SensOpt.Sens_f, 'n', Separator, 'SumSqr', Separator, 'slope',
    Separator, 'intercept', Separator, 'r2', Separator, 'RMSE', Separator,
    'EF');
  // second row of output file: write units of selected sensitivity parameter
  write(SensOpt.Sens_f, SensOpt.SelSenspar.U, Separator);
  // second row of output file: write units of selected Parameter
  writeln(SensOpt.Sens_f, '[', SensOpt.SelSenspar.U, ']');
  // for each step of sensitivity analysis do...
  self.ContOutput := false;
  for Iter := 1 to SensOpt.Steps do
  begin
    run;
    AllMeasVal.LeastSquares;
    // write parameter and variable values to output
    write(SensOpt.Sens_f, FloatToStrf(SensOpt.SelSenspar.v, ffgeneral, 8, 4),
      Separator);
    writeln(SensOpt.Sens_f, AllMeasVal.count, Separator,
      AllMeasVal.SumSqrdiff:8:4, Separator, AllMeasVal.slope:8:4, Separator,
      AllMeasVal.intercept:8:4, Separator, AllMeasVal.r2:8:4, Separator,
      AllMeasVal.RMSE:8:4, Separator, AllMeasVal.modellingefficiency:6:3);
    // increase value of sensitivity parameter by stepwidth
    SensOpt.SelSenspar.v := SensOpt.SelSenspar.v + SensOpt.DPar;
  end;
  ContOutput := true;
  SensOpt.SelSenspar.SelForOpt := true;
  // close output file (sens.dat)
  close(SensOpt.Sens_f);
  for i := 0 to IniFileNames.count - 1 do
  begin // rewrite old values to Ini-files
    ActIniFile := TMyIniFile(FIniFiles.objects[i]);
    ActParamFileName := ActIniFile.ReadString('FileNames', 'ParamIniFN',
      ActParamFileName);
    // TODO ActParamInifile.FileName := ActParamfileName;
    ActparamInifile := TMyIniFile.create(ActParamFileName);
    ActparamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.name,
      OldParameterValues[i]);
    ActparamInifile.Free;
  end;

  AllMeasVal.Clear;
  // This TMod.CalcSensitivity method was called by the procedure
  // TFormSensOpt.ButtonRunSensClick from the unit UFormSelPar.
  // There, to present the sensitivity results, the string grid  will
  // now be actualized and displayed
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  ClearAllDataSeries
  PURPOSE For each submodel clear data pair series
  ****************************************************************** }

procedure TMod.ClearAllDataSeries;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // clear submodel's data pair series
    subMod.ClearDataSeries;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  WriteAll_1_1_Files
  PURPOSE Output of simulated/measured data pairs to _1_1.csv files for all submodells
  ****************************************************************** }

procedure TMod.WriteAll_1_1_Files;
var
  i: integer;
  subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    // Output of simulated/measured data pairs to _1_1.csv files
    if subMod.SomethingMeasured then
      subMod.write_1_1_files;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CalcAllLinearRegressions
  PURPOSE For all submodels calculate linear regression statistics
  COMMENT Called by TMod.Run
  ****************************************************************** }

procedure TMod.CalcAllLinearRegressions;
var
  i, j: integer;
  subMod: TSubmodel;
  DataSeries: TMeasList;
begin
  // create output file for regression data
  // if Reg_fn = '' then
  Reg_fn := GM_OutPutPath + '\' + 'regression.dat';

  assignfile(FRegFile, Reg_fn);

  // showmessage(Reg_fn);

  rewrite(FRegFile);
  // reset(fregfile);
  writeln(FRegFile,
    'SubModel Parameter slope SE_slope intercept SE_intercept r2 n RMSE EF CD');
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    if subMod.SomethingMeasured then
    begin
      // calculate linear regression of submodel
      subMod.CalcLinearRegressions;
      // write regression data of submodel to output file
      for j := 0 to subMod.DataList.count - 1 do
      begin
        DataSeries := TMeasList(subMod.DataList.objects[j]);
        writeln(FRegFile, SubModStrList.Strings[i], Separator, DataSeries.name,
          Separator, DataSeries.slope:6:4, Separator, DataSeries.se_slope:6:4,
          Separator, DataSeries.intercept:6:4, Separator,
          DataSeries.se_intercept:6:4, Separator, DataSeries.r2:6:4,
          Separator, DataSeries.count:6, Separator, DataSeries.RMSE:6:4,
          Separator, DataSeries.modellingefficiency:6:4, Separator,
          DataSeries.cd:6:4);
      end;
    end;
  end;
  // close output file for regression data
  CloseFile(FRegFile);
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  CalcChiSq
  PURPOSE Calculation of sum of squared differences
  INPUT
  OUTPUT
  COMMENT
  ****************************************************************** }

procedure TMod.CalcChiSq;
var
  i, j, k: integer;
  subMod: TSubmodel;
  DataSeries: TMeasList;
  MeasRec: TmeasValue;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    if subMod.SomethingMeasured then
    begin
      for j := 0 to subMod.DataList.count - 1 do
      begin
        DataSeries := TMeasList(subMod.DataList.objects[j]);
        if DataSeries.SelForOpt then
        begin
          { ChiSqr := ChiSqr+DataSeries.SumSqr; }
          for k := 0 to DataSeries.actPOs - 1 do
          begin
            MeasRec := TmeasValue(DataSeries.Items[k]);
            if (Abs(MeasRec.meas) > MinLegalValue) and (Abs(MeasRec.sim) > MinLegalValue)
              then
            begin
              // add measurement data points
              AllMeasVal.add(MeasRec);
            end;
          end;
        end;
      end;
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  MarquardOptimization
  PURPOSE Optimization routine
  COMMENT Called by TFormOpt.StartBtnClick (unit UFormOpt)
  ****************************************************************** }

procedure TMod.MarquardOptimization;
var
  NewPar, ErrPar: RealArrayMa;
  CorMat, Alpha: RealArrayMaByMa;
  Yfit: RealArrayNdata;
  NewChiSq: real;
  fn: string;
begin
  // filename for output of optimization data
  fn := StripExtension(self.ControlFileFn) + '_opt.dat';
  // No file output during optimisation
  ContOutput := false;
  mrq_fit(self, // this TMod instance
    true, // fit?
    true, // flag for output to file / screen
    fn, // output file name
    NewPar, ErrPar, // new parameter values and asymptotic error values
    NewChiSq, // Chi square value
    CorMat, Alpha, // Correlation matrix, alpha
    Yfit); // function results with otpimal parameters
  // Activate file output
  ContOutput := true;
  // Generate new output
  run; // wieso hier run? Das verstellt die actini Datei!
  // Das erneute Aufrufen ist notwendig, damit die Inhalte der der Ausgabedateien mit den
  // Parameterwerten im Array NewPar korrespondieren ...

end;

{* *****************************************************************
  CLASS   TMod
  METHOD  GetParameter
  PURPOSE Delivers values of parameter "ParName"
  INPUT   ParName: string;
  var Par: TPar;
  var SubModName: string;
  var Success: boolean
  ****************************************************************** }

procedure TMod.GetParameter(ParName: string; var Par: TPar;
  var SubModname: string; var Success: boolean);
var
  subMod: TSubmodel;
  i, index: integer;
begin
  Success := false;
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    SubModname := SubModStrList.Strings[i];
    index := subMod.ParStrList.indexof(ParName);
    // found parameter ParName
    if index <> -1 then
    begin
      Par := TPar(subMod.ParStrList.objects[index]);
      Success := true;
      Break;
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  GetVariable
  PURPOSE Delivers values of variable "VarName"
  INPUT   VarName: string;
  var Variable: TVar;
  var SubModName: string;
  var Success: boolean
  ****************************************************************** }

procedure TMod.GetVariable(VarName: string; var Variable: Tvar;
  var SubModname: string; var Success: boolean);
var
  subMod: TSubmodel;
  i, index: integer;
begin
  Success := false;
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    SubModname := SubModStrList.Strings[i];
    index := subMod.VarStrList.indexof(VarName);
    // found variable VarName
    if index <> -1 then
    begin
      Variable := Tvar(subMod.VarStrList.objects[index]);
      Success := true;
      Break;
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  GetStateVar
  PURPOSE Delivers values of state variable "StateName"
  INPUT   StateName: string;
  var State: TState;
  var SubModName: string;
  var Success: boolean
  ****************************************************************** }

procedure TMod.GetStateVar(StateName: string; var State: TState;
  var SubModname: string; var Success: boolean);
var
  subMod: TSubmodel;
  i, index: integer;
begin
  Success := false;
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    SubModname := SubModStrList.Strings[i];
    index := subMod.StateStrList.indexof(StateName);
    // found state variable StateName
    if index <> -1 then
    begin
      State := TState(subMod.StateStrList.objects[index]);
      Success := true;
      Break;
    end;
  end;
end;

{* *****************************************************************
  CLASS   TMod
  METHOD  IsFinished
  PURPOSE Sets TMod.ModelEnd to true if time counter passed endtime of model
  ****************************************************************** }

procedure TMod.IsFinished;
begin
  if Time.v >= FEndTime then
    ModelEnd := true;
end;



{* *****************************************************************
  CLASS   TMod
  METHOD  IsFinished
  PURPOSE Sets TMod.ModelEnd to true if time counter passed endtime of model
  ****************************************************************** }

procedure TMod.write_documentation;

var
  fn, path : string;
  f        : textfile;
  i,j, level  : integer;
  ClassRef : TClass;
  tab      : char;
  ModelElements : TModelElements;
  NumbersOf : TNumbersOf;

begin
  InitAllExternV;
  tab := chr(9);
  path := ExtractFilePath(ControlFileFn);
  fn := ExtractFilename(ControlFileFN);
  fn := 'Docu_'+ChangeFileExt(Fn, '.txt');
  fn := path+fn;
  self.fDocu_FN := fn;
  assignfile(f, fn);
  rewrite(f);
  writeln(f, 'Documentation of '+controlfileFN);
  writeln(f);
  writeln(f, 'The model consists of ', self.SubModStrList.Count, ' SubModels');
  writeln(f, 'Name', tab,tab,tab,tab,  'Class', tab, 'ParentClasses');
  for i := 0 to SubModStrList.Count - 1 do begin
     SubModel[i].ClassParent;
     ClassRef := SubModel[i].ClassType;
     writeln(f, self.SubModel[i].Name);
//     while ClassRef.ClassName <> 'TSubmodel' do begin
     level := length(SubModel[i].Name);
     while ClassRef <> TGraphicControl do begin
       for j := 1 to level do
         write(f,' ');
       writeln(f, '|____' , ClassRef.ClassName);
       level := level+length(ClassRef.ClassName)+5;
       ClassRef := ClassRef.ClassParent;
     end;
     writeln(f);
  end;

 for ModelElements  := low(TModelElements) to high(TModelElements) do
   NumbersOf[ModelElements] := 0;

  for i := 0 to SubModStrList.Count - 1 do begin
    for ModelElements  := low(TModelElements) to high(TModelElements) do begin
       NumbersOf[ModelElements] := NumbersOf[ModelElements] + SubModel[i].fModelElementLists[ModelElements].count;
    end;
  end;
  Writeln(f, 'The Model has in total ', NumbersOf[States], ' State Variables');
  Writeln(f, '                       ', NumbersOf[Vars],   ' Variables');
  Writeln(f, '                       ', NumbersOf[Params], ' Parameters');
  Writeln(f, '                       ', NumbersOf[Consts], ' Constants');


  writeln(f);
  writeln(f);


  for i := 0 to SubModStrList.Count - 1 do begin
    for ModelElements  := low(TModelElements) to high(TModelElements) do begin
       Writeln(f, 'The Submodel ', SubModel[i].name,' has in total ', SubModel[i].fModelElementLists[ModelElements].count, ' ', ModelElementNames[ModelElements]);

    end;
    writeln(f);
  end;



  closefile(f);
end;




{* *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateSubMod
  PURPOSE Adds submodel to TMod's Submodel-String-List
  INPUT   SubModName: string;
  var Model: Tmod
  ****************************************************************** }

procedure TSubmodel.RegistrateSubMod(SubModname: string; var Model: TMod);
begin
  Model.SubModStrList.AddObject(SubModname, self);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Set_GlobMod
  PURPOSE Initiates submodel according to "global" model (TMod instance)
  INPUT   Model: TMod
  ****************************************************************** }

procedure TSubmodel.Set_GlobMod(Model: TMod);
var
  SubModIndex: integer;
begin
  SubModname := Name;
  GlobMod := Model;
  if Model.Parent <> nil then
    Parent := Model.Parent;
  Canvas.Brush.Color := clGreen;
  Canvas.Font.Color := clyellow;
  self.Repaint;
  fn_rate := GlobMod.FOutputPath + '\' + Name + '_rat.csv';
  fn_state := GlobMod.FOutputPath + '\' + Name + '_dat.csv';
  ParIniF := GlobMod.ParamInifile;
  ParCommentF := GlobMod.ParamCommentFile;

  StateIniF := GlobMod.StateIniFile;
  OptionIniF := GlobMod.OptionIniFile;
  GlobTime := GlobMod.Time;
  RegistrateSubMod(SubModname, GlobMod);
  SubModIndex := GlobMod.SubModStrList.indexof(Name);
  if CompIndex = -1 then
    CompIndex := SubModIndex;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Get_GlobMod
  PURPOSE Delivers reference to "global" model (TMod instance9 where
  submodel is registered
  OUTPUT  TMod
  ****************************************************************** }

function TSubmodel.Get_GlobMod: TMod;
begin
  Result := GlobMod;
end;

procedure TSubmodel.set_State(index: integer; const State: TState);
begin
  StateStrList.objects[index] := State;
end;

function TSubmodel.get_State(index: integer): TState;
begin
  if (index > -1) and (index <= StateStrList.count) then
    Result := TState(StateStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Par(index: integer; const Par: TPar);
begin
  ParStrList.objects[index] := Par;
end;

function TSubmodel.Get_Par(index: integer): TPar;
begin
  if (index > -1) and (index <= ParStrList.count) then
    Result := TPar(ParStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Var(index: integer; const Variable: Tvar);
begin
  ParStrList.objects[index] := Variable;
end;

function TSubmodel.Get_Var(index: integer): Tvar;
begin
  if (index > -1) and (index <= VarStrList.count) then
    Result := Tvar(ParStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Const(index: integer; const Constant: Tvar);
begin
  ConstStrList.objects[index] := Constant;
end;

function TSubmodel.get_Const(index: integer): Tvar;
begin
  if (index > -1) and (index <= ConstStrList.count) then
    Result := Tvar(ConstStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Option(index: integer; const Option: TOption);
begin
  OptionStrList.objects[index] := Option;
end;

function TSubmodel.get_Option(index: integer): TOption;
begin
  if (index > -1) and (index <= OptionStrList.count) then
    Result := TOption(OptionStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_ExternVar(index: integer; const ExternVar: TExternV);
begin
  ExternVStrList.objects[index] := ExternVar;
end;

function TSubmodel.get_ExternVar(index: integer): TExternV;
begin
  if (index > -1) and (index <= ExternVStrList.count) then
    Result := TExternV(ExternVStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Create
  PURPOSE Creates TSubModel according to TComponent.create
  INPUT   AOwner: TComponent
  COMMENT The TSubmodel class is derived from the TGraphicControl class
  ****************************************************************** }

constructor TSubmodel.create(AOwner: TComponent);
begin
  inherited create(AOwner);
  Color := clGreen;
  Canvas.Brush.Color := clgreen;
  Canvas.Font.Color := clyellow;
  Canvas.Font.Size := 14;
  ControlStyle := ControlStyle + [csReplicatable];
  Width := 100;
  Height := 50;
  Canvas.Pen.Color := clblack;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Width := 2;
  Canvas.Brush.Style := bsSolid;
  // Initiates lists for state variables, parameters, external values and measured data series
  WriteTofile := true;
  StateStrList := TStringList.create;
//  StateStrList.OwnsObjects := true;
  fModelElementLists[States] := StateStrList;
  StateStrList.Sorted := true;
  // StateStrlist.Duplicates := dupignore;
  ParStrList := TStringList.create;
//  ParStrList.OwnsObjects := true;
  fModelElementLists[Params] := ParStrList;
  ParStrList.Sorted := true;
  // ParStrList.Duplicates := dupignore;
  // adding duplicates to the sorted list will trigger an LListError exception
  ExternVStrList := TStringList.create;
//  ExternVStrList.OwnsObjects := true;
  fModelElementLists[Externals] := ExternVStrList;
  ExternVStrList.Sorted := true;
  ExternVStrList.Duplicates := dupAccept;
  VarStrList := TStringList.create;
//  VarStrList.OwnsObjects := true;
  fModelElementLists[Vars] := VarStrList;
  VarStrList.Sorted := true;
  VarStrList.Duplicates := dupignore;
  ConstStrList := TStringList.create;
//  ConstStrList.OwnsObjects := true;
  fModelElementLists[Consts] := ConstStrList;
  ConstStrList.Sorted := true;
  ConstStrList.Duplicates := dupignore;
  OptionStrList := TStringList.create;
//  OptionStrList.OwnsObjects := true;
  OptionStrList.Sorted := true;
  OptionStrList.Duplicates := dupignore;
  fAssimilatedSubmodList := TStringList.create;
  fAssimilatedSubmodList.Sorted := true;
  fAssimilatedSubmodList.Duplicates := dupignore;
  DataList := TStringList.create; // List of measured data series
  // calls TGraphicControl.activate (virtual)
  activate;
  Cursor := CrHandPoint;
  CompIndex := -1;
  // KLUSS FMeasValues := TTextFileH.create;

  // globalmod wird erst nach create gesetzt!
  CreateAll;

end;


destructor TSubModel.Destroy;
var
  Element : TModelElements;
  Entity, Option : integer;
  Ootion: Integer;

begin
 { self.fUpdateValueList.Free;
  self.FUpdValues.Free;
  self.FMeasValues.Free;
  self.FMeasValues_2.Free;
  if StateIniF <> nil then
    self.StateIniF.Free;
  self.ParIniF.Free;
  self.VarStrList.Free;
  self.ParStrList.Free;
  ExternVStrList.Free;
  ConstStrList.Free;
  OptionStrList.Free;
   fAssimilatedSubmodList.Free;
   DataList.Free;  }


   for Element := low(TModelElements) to high(TModelElements) do begin
     for Entity := fModelElementLists[Element].count-1 downto 0 do begin
        fModelElementLists[Element].objects[Entity].Free;
  //     Submodel[SubMod].fModelElementLists[Element].objects[Entity] := nil;
     end;
   end;

   for Option := self.OptionStrList.Count - 1 downto 0 do
      OptionStrList.objects[Option].free;

  inherited;
end;


{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Init
  PURPOSE Initialisation method for TSubmodel
  INPUT   var GlobMod: TMod
  COMMENT Is being called on creation of application form and on run of simulation
  ****************************************************************** }

procedure TSubmodel.Init(var GlobMod: TMod);
var
  i: integer;
  State: TState;
  Param: TPar;
  Variable: Tvar;
  Option: TOption;
  value: real;
  defaultname, fn_meas: string;
  TempStr: TStringList;
  fn_UpdFile: string;
begin

  ParIniF := GlobMod.ParamInifile;
  ParCommentF := GlobMod.ParamCommentFile;
  StateIniF := GlobMod.StateIniFile;
  OptionIniF := GlobMod.OptionIniFile;
  GlobTime := GlobMod.Time;
  // (Re)initialization of all state variables
  StateStrList.Sorted := false;
  for i := 0 to self.StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    StateVar[i].SubModname := self.name;
    StateStrList.Strings[i] := State.name;
    State.c := 0.0;
    State.v := State.DefaultValue;
    // At the beginning the rate of change equals 0 for all state variables
    if State.ReadFromFile and (State.name <> '') then
      if GlobMod.StateIniFile.valueexists(SubModname, State.name) then
      begin
        value := GlobMod.StateIniFile.ReadFloat(SubModname, State.name, 0.0);
        State.v := value;
        State.wasreadfromfile := true;
      end
      else
      begin
        State.v := 0.0;
        State.wasreadfromfile := false;
        GlobMod.StateIniFile.WriteFloat(SubModname, State.name,
          State.DefaultValue);
      end;
  end;

  StateStrList.Sort;
  StateStrList.Sorted := true;
  // (Re)initialization of all parameters
  ParStrList.Sorted := false;
  for i := 0 to ParStrList.count - 1 do
  begin
    Param := TPar(ParStrList.objects[i]);
    Param.SubModname := self.name;
    ParStrList.Strings[i] := Param.Name;
    // This is necessary because the Name of the parameter may have been
    // altered within the object inspector
    if not Param.SelForOpt and Param.ReadFromFile then
      if GlobMod.ParamInifile.valueexists(SubModname, Param.name) then
      begin
        { Read values only if not selected for optimization ! }
        Param.v := GlobMod.ParamInifile.ReadFloat(SubModname, Param.name,
          Param.DefaultValue);
        { else showMessage(GlobMod.ParamInifile.Filename+' '+Param.name+' '+FloatToStr(Param.v)) } ;
      end
      else
      begin // if error then begin
        Param.v := Param.DefaultValue;
        GlobMod.ParamInifile.WriteFloat(SubModname, Param.name,
          Param.DefaultValue);
        { ShowMessage('Error on initialization of parameters'); }
      end;
  end;
  ParStrList.Sort;
  ParStrList.Sorted := true;
  // (Re)initialization of all variables
  // Warum werden hier Variablen initialisiert?

  VarStrList.Sorted := false;
  for i := 0 to self.VarStrList.count - 1 do
  begin
    Variable := Tvar(VarStrList.objects[i]);
    Variable.SubModname := self.name;
    VarStrList.Strings[i] := Variable.Name;
    Variable.v := Variable.DefaultValue;
    // TODO Warum sollte man Variablen aus einer Datei lesen wollen?
    if Variable.ReadFromFile then
      if GlobMod.StateIniFile.valueexists(SubModname, Variable.name) then
      begin
        Variable.v := GlobMod.StateIniFile.ReadFloat(SubModname, Variable.name,
          Variable.DefaultValue);
        Variable.wasreadfromfile := true;
      end
      else
      begin
        Variable.wasreadfromfile := false;
      end;
  end;
  VarStrList.Sort;
  VarStrList.Sorted := true;
  // (Re)initialization of all options
  OptionStrList.Sorted := false;

  for i := 0 to self.OptionStrList.count - 1 do
  begin
    Option := TOption(OptionStrList.objects[i]);
    Option.SubModname := self.name;
    Option.Option := '';
    if Option.ReadFromFile then
    begin
      Option.Option := GlobMod.OptionIniFile.ReadString(SubModname,
        Option.name, Option.Defaultstring)
    end;
  end;
  OptionStrList.Sort;
  OptionStrList.Sorted := true;

  for i := 0 to self.OptionStrList.count - 1 do
  begin
    Option := TOption(OptionStrList.objects[i]);
    if Option.Option <> '' then
    begin
      GlobMod.OptionIniFile.Writestring(SubModname, Option.name, Option.Option);
      GlobMod.OptionIniFile.UpdateFile;
    end;
  end;

  defaultname := ExtractFileName(GlobMod.ActIniFile.Filename);
  delete(defaultname, pos('.', defaultname), 4);
  defaultname := GlobMod.FOutputPath + '\' + defaultname + '_' + SubModname;
  // creates a default name for output
  fn_state := GlobMod.ActIniFile.ReadString
    (GlobMod.Str_SectionName_OutPutFiles, SubModname, defaultname) + '_dat.csv';
  // write output filename to ini-file if not yet present

  fn_rate := GlobMod.ActIniFile.ReadString(GlobMod.Str_SectionName_OutPutFiles,
    SubModname, defaultname) + '_rat.csv';


  fn_finalstate := ExtractFileName(globMod.ControlFileFn);
  delete(fn_finalstate, pos('.', fn_finalstate), 3);
  if globmod.GM_OutPutPath <> '' then
    fn_finalstate := globmod.GM_OutPutPath + '\' +'Final_' + fn_finalstate + '_' + Name+ '.csv'
   else
      fn_finalstate := globmod.EXE_DIR + '\' +'Final_' + fn_finalstate + '_' + Name+ '.csv';


  // reads filenames of measurement and output files from main Ini-file
  // KLUSS FMeasValues.FileName :=
  FMeasValues := TTextFileH.create(GlobMod.ActIniFile.ReadString
      (GlobMod.Str_SectionName_MeasurementFiles, SubModname, ''));

  activate;
  // reads filenames of measurement and output files from main Ini-file
  fn_meas := GlobMod.ActIniFile.ReadString
    (GlobMod.Str_SectionName_MeasurementFiles, SubModname, '');

  if FileExists(fn_meas) then
  begin
    if FMeasValues = nil then
      FMeasValues := TTextFileH.create(fn_meas);
    SomethingMeasured := true;
  end
  else
  begin
    SomethingMeasured := false;
    if FileExists(fn_meas) and (fn_meas <> '') then
      ShowMessage('Measurementfile ' + fn_meas + 'of ' + self.name +
          ' is specified but does not exist')
  end;

  fn_UpdFile := GlobMod.ActIniFile.ReadString
    (GlobMod.Str_SectionName_UpdateFiles, SubModname, '');

  if FileExists(fn_UpdFile) then
  begin
    FUpdValues := TTextFileH.create(fn_UpdFile);
    DoUpdate := true;
    TempStr := TStringList.create;
    TempStr.CommaText := FUpdValues.GetFirstLine;
    FUpdValues.GoTop;
    FUpdValues.NextLine;
    NextUpdate := StrToFloat(TempStr[0]);
    TempStr.Free;
  end
  else
  begin
    DoUpdate := false;
    if (fn_UpdFile <> '') and not FileExists(fn_UpdFile) then
      ShowMessage('Updatefile ' + fn_UpdFile + ' of Submodel' + self.name +
          ' is specified but does not exist');
  end;
end;

procedure TSubmodel.AddDataValueToDataSeries;
var
  i, line: integer;
  fn_meas, Namestr, Unitstr: string;
  ActSeries: TMeasList;

  Date, X: real;
  NewSeries: TMeasList;
  MeasValue: TmeasValue;
begin
  fn_meas := GlobMod.ActIniFile.ReadString
    (GlobMod.Str_SectionName_MeasurementFiles, SubModname, '');
  if SomethingMeasured then
  begin
    FMeasValues := TTextFileH.create(fn_meas);
    with FMeasValues do
    begin
      for i := 1 to FirstLine.count - 1 do
      begin
        Namestr := FirstLine.Strings[i];
        Unitstr := UnitLine.Strings[i];
        if DataList.indexof(Namestr) = -1 then
        begin
          NewSeries := TMeasList.create(Namestr, Unitstr);
          NewSeries.Clear;
          DataList.AddObject(Namestr, NewSeries);
        end;
      end;
      for i := 0 to DataList.count - 1 do
      begin
        ActSeries := TMeasList(DataList.objects[i]);
        with ActSeries do
        begin
          Lastdate := GlobMod.Time.v - GlobMod.Time.c;
          SumSqrdiff := 0.0;
          slope := 0.0;
          intercept := 0.0;
          r2 := 0.0;
        end;
      end;
      GoTop;
      for line := 1 to FMeasValues.n_Line do
      begin
        NextLine;
        for i := 0 to DataList.count - 1 do
        begin
          try
            Date := FMeasValues.getIndexValue(0);
            X := FMeasValues.getValue(TMeasList(DataList.objects[i]).Name);
            if not IsNan(X) and (Abs(X) > GlobMod.MinLegalValue) and
              (Date >= GlobMod.FStartTime) and (Date < GlobMod.FEndTime)
              then
            begin
              MeasValue := TmeasValue.create(Date, X, GlobMod.MinLegalValue,
                ExtractFileName(GlobMod.ActIniFile.Filename));
              TMeasList(DataList.objects[i]).add(MeasValue);
            end;
          except
            on EInvalidOp do
            begin
              {
                showmessage('Fehler in TSubModel.AddDataValueToDataSeries ' +
                FMeasValues.fFileName + ' ' + IntToStr(DataList.Count) +
                ' Fehler aufgetreten bei: ' + getActLine() + ' ' +
                getActLineStringList()[0] + ' ' + floattostr(date) + ' ');
                }
            end;
          end;
        end;
      end;
    end;
    FMeasValues.Free;
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  ParCreate
  PURPOSE Method for creating and and initialising a TPar variable
  INPUT   ParName: string;
  ParUnits: string;
  DefaultValue: real;
  var Par: TPar
  ****************************************************************** }

procedure TSubmodel.ParCreate(ParName: string; ParUnits: string;
  DefaultValue: real; var Par: TPar; comm: string = '');
var
  value: real;
  comment: string;
begin
  value := DefaultValue;

  if self.GlobMod <> nil then
  begin
    with ParIniF do
    begin
      if valueexists(SubModname, ParName) then
      begin
        value := ReadFloat(SubModname, ParName, DefaultValue);
      end
      else
      begin
        WriteFloat(SubModname, ParName, DefaultValue);
        ParIniF.UpdateFile;
      end
    end;
  end;

  comment := comm;
  if GlobMod <> nil then
  begin
    with ParCommentF do
    begin
      if valueexists(self.ClassName, ParName) then
      begin
        comment := ReadString(ClassName, ParName, '');
      end
      else
      begin
        Writestring(ClassName, ParName, comment);
        ParCommentF.UpdateFile;
      end;
    end;
  end;

  Par := TPar.create(ParName, ParUnits, value, 0.0, comment);
  RegistrateParameter(Par);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  OptCreate
  PURPOSE Method for creating and and initialising a TOption variable
  INPUT   OptName: string;
  DefaultOption: string;
  var Option: TOption
  ****************************************************************** }

procedure TSubmodel.OptCreate(OptName: string; Defaultstring: string;
  var Option: TOption; comm: string = '');
var
  OptString: string;
begin
  OptString := Defaultstring;

  if self.GlobMod <> nil then
  begin
    OptString := OptionIniF.ReadString(SubModname, OptName, Defaultstring);
    if OptString = '' then
    begin
      OptionIniF.Writestring(SubModname, OptName, Option.Option);
      OptionIniF.UpdateFile;
      OptString := Option.Option;
    end;
  end;

  Option := TOption.create(OptName, OptString, comm);
  RegistrateOption(Option);

end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  VarCreate
  PURPOSE Method for creating and and initialising a TVar variable
  INPUT   VarName: string;
  VarUnits: string;
  DefaultValue: real;
  ReadFromFile: boolean;
  var Variable: TVar
  ****************************************************************** }

procedure TSubmodel.VarCreate(VarName: string; VarUnits: string;
  DefaultValue: real; ReadFromFile: boolean; var Variable: Tvar;
  comm: string = '');
var
  value: real;
begin
  // WIESO WERDEN HIER VARIABLEN AUS INI FILES EINGELESEN?
  value := DefaultValue;

  if (self.GlobMod <> nil) and ReadFromFile then
  begin
    with StateIniF do
    begin
      if valueexists(SubModname, VarName) then
      begin
        value := ReadFloat(SubModname, VarName, DefaultValue);
      end
      else
      begin
        WriteFloat(SubModname, VarName, DefaultValue);
        UpdateFile;
      end;
    end;
  end;

  Variable := Tvar.create(VarName, VarUnits, value, comm);
  RegistrateVariable(Variable);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  StateCreate
  PURPOSE Method for creating and and initialising a TState variable
  INPUT   StateName: string;
  StateUnits: string;
  DefaultValue: real;
  ReadFromfile: boolean;
  var State: TState
  ****************************************************************** }

procedure TSubmodel.StateCreate(StateName: string; StateUnits: string;
  DefaultValue: real; ReadFromFile: boolean; var State: TState;
  comm: string = '');
var
  value: real;
begin
  value := DefaultValue;

  if (GlobMod <> nil) and ReadFromFile then
  begin
    with StateIniF do
    begin
      if valueexists(SubModname, StateName) then
      begin
        value := ReadFloat(SubModname, StateName, DefaultValue);
      end
      else
      begin
        WriteFloat(SubModname, StateName, DefaultValue);
        UpdateFile;
      end;
    end;
  end;

  State := TState.create(StateName, StateUnits, value, 0.0, comm);
  RegistrateStateVar(State);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateOption
  PURPOSE Registers Option (TOption instance) in option list of submodel
  INPUT   Par: TOption
  ****************************************************************** }

procedure TSubmodel.RegistrateOption(Option: TOption);
var
  idx: integer;
begin
  with OptionStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Option.name);
    if idx >= 0 then
    begin
      objects[idx] := Option;
    end
    else
    begin
      addObject(Option.name, Option);
    end;
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateParameter
  PURPOSE Registers parameter (TPar instance) in parameter list of submodel
  INPUT   Par: TPar
  ****************************************************************** }

procedure TSubmodel.RegistrateParameter(Par: TPar);
var
  idx: integer;
begin
  with ParStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Par.name);
    if idx >= 0 then
      objects[idx] := Par
    else
      addObject(Par.name, Par);
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateVariable
  PURPOSE Registers variable (TVar instance) in variable list of submodel
  INPUT   Variable: TVar
  ****************************************************************** }

procedure TSubmodel.RegistrateVariable(Variable: Tvar);
var
  idx: integer;
begin
  with VarStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Variable.name);
    if idx >= 0 then
      objects[idx] := Variable
    else
      addObject(Variable.name, Variable);
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateStateVar
  PURPOSE Registers state variable (TState instance) in state variable list of submodel
  INPUT   State: TState
  ****************************************************************** }

procedure TSubmodel.RegistrateStateVar(State: TState);
var
  idx: integer;
begin
  with StateStrList do
  begin
    CaseSensitive := false;
    idx := indexof(State.name);
    if idx >= 0 then
      objects[idx] := State
    else
      addObject(State.name, State);
  end;
end;

procedure TSubmodel.CreateAll();
begin

end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteStateName
  PURPOSE Write names and units of all variables to output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: TState
  ****************************************************************** }

procedure TSubmodel.WriteStateName(var f: text; fn: string; Time: TState);
var
  i: integer;
  Caption: string;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;


begin
  // rewrite output file _dat.csv
  // assignfile(f, fn);
  assignfile(f, fn);

  rewrite(f);
  // first row of output file
  // write name of time variable to output
  write(f, Time.name, GlobMod.Separator);
  // write names of all state variables to output
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteTofile then
    begin
      Caption := State.name;
      write(f, Caption, GlobMod.Separator)
    end;
  end;
  // write names of all  variables to output
  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.WriteTofile then
    begin
      Caption := Variable.name;
      write(f, Caption, GlobMod.Separator);
    end;
  end;
  // write names of all external variables to output
  for i := 0 to self.ExternVStrList.count - 1 do
  begin
    ExValue := TExternV(ExternVStrList.objects[i]);
    if ExValue.opt_WriteToFile then
    begin
      Caption := ExValue.name;
      if i<ExternVStrList.count-1 then
        write(f, Caption, GlobMod.Separator)
      else
        write(f, Caption)
    end;
  end;
  // go to second row of output file
  writeln(f);
  // write units of time variable to output
  write(f, Time.U, GlobMod.Separator);
  // write units of all state variables to output
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteTofile then
    begin
      Caption := State.U;
      write(f, Caption, GlobMod.Separator);
    end;
  end;
  // write units of all  variables to output
  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.WriteTofile then
    begin
      Caption := Variable.U;
      write(f, Caption, GlobMod.Separator);
    end;
  end;
  // write units of all external variables to output
  for i := 0 to self.ExternVStrList.count - 1 do
  begin
    ExValue := TExternV(ExternVStrList.objects[i]);
    if ExValue.opt_WriteToFile then
    begin
       if i<ExternVStrList.count-1 then
        write(f, Caption, GlobMod.Separator)
      else
        write(f, Caption)
    end;
  end;
  // go to third row of output file - ready for values...
  writeln(f);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteSensNames
  PURPOSE Write names and units of all sensitivity steps to output file (_dat.csv)
  INPUT   Variable: Tvar;
  var f: text
  ****************************************************************** }

procedure TMod.WriteSensNames(Variable: Tvar; var f: text);
var
  i: integer;
  Caption: string;
begin
  // output file already opened: _sens_a.csv files
  { rewrite(f); }
  // first row of output file
  // write name of time variable to output
  write(f, Time.name, Separator);
  // write names of all steps of sensitivity analysis to output
  for i := 1 to SensOpt.Steps do
  begin
    Caption := Variable.name + '_' + IntToStr(i);
    write(f, Caption, Separator);
  end;
  // go to second row of output file
  writeln(f);
  // write units of time variable to output
  write(f, Time.U, Separator);
  // write units of all steps of sensitivity analysis to output
  for i := 0 to SensOpt.Steps do
  begin
    Caption := Variable.U;
    write(f, Caption, Separator);
  end;
  // go to third row of output file - ready to write values...
  writeln(f);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteSensValue
  PURPOSE Writes values from sensitivity analysis to sens_ output files
  INPUT   Variable: Tvar;
  Iter: integer;
  var f_a, f_b: text
  ****************************************************************** }

procedure TMod.WriteSensValue(Variable: Tvar; Iter: integer;
  var f_a, f_b: text);
var
  line: string;
begin
  with Variable do
  begin
    if Iter > 1 then
    begin
      readln(f_b, line);
      writeln(f_a, line + FloatToStrf(v, ffgeneral, Precision, Digits),
        Separator);
    end
    else
      writeln(f_a, FloatToStrf(Time.v, ffgeneral, Time.Precision, Time.Digits),
        Separator, FloatToStrf(v, ffgeneral, Precision, Digits), Separator);
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Integrate
  PURPOSE Integration of state variables (Euler method)
  ****************************************************************** }

procedure TSubmodel.Integrate;
var
  j: integer;
  State: TState;
begin
  // for all state variables do...
  for j := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[j]);
    State.v := State.v + State.c * GlobTime.c;
  end;
end;

procedure TSubmodel.UpdateValues;
var
  i: integer;
  State: TState;
  v: real;
begin
  if fUpdateValueList = nil then
    fUpdateValueList := TStringList.create
  else
    fUpdateValueList.Clear;

  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    v := FUpdValues.getValue(State.Name);
    if not IsNan(v) then
      fUpdateValueList.add(State.Name + '=' + FloatToStr(v));
  end;

  FUpdValues.NextLine;
  if StrToFloat(FUpdValues.ActLine[0]) > GlobTime.v then
  begin
    NextUpdate := StrToFloat(FUpdValues.ActLine[0]);
    DoUpdate := true;
  end
  else
    DoUpdate := false;
end;

function TSubmodel.UpdateValue(n: string): real;
begin
  Result := StrToFloat(fUpdateValueList.Values[n]);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  SaveState
  PURPOSE Writes values of state, parameter and external variables to output files
  INPUT   var f: text;
  fn: string;
  Time: TState
  COMMENT #TS#026 code modified due to problems with separator
  ****************************************************************** }

procedure TSubmodel.SaveState(var f: text; fn: string; Time: TState);
var
  i: integer;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;
  Outstr: string;
  line: String;
begin

  // write value of time variable to output file
  with Time do
    Outstr := FloatToStrf(v - c, ffgeneral, Precision, Digits);
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteTofile then
    begin
      Outstr := FloatToStrf(State.v, ffgeneral, State.Precision, State.Digits);
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all variabes to output file
  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.WriteTofile then
    begin
      Outstr := FloatToStrf(Variable.v, ffgeneral, Variable.Precision,
        Variable.Digits);

      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all external variables to output file
  for i := 0 to self.ExternVStrList.count - 1 do
  begin
    ExValue := TExternV(ExternVStrList.objects[i]);
    if ExValue.opt_WriteToFile then
    begin
      Outstr := FloatToStrf(ExValue.v, ffgeneral, 6, 2);
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // change to next row
  writeln(f, line); // WriteLn(f);
end;

procedure TSubmodel.closeOutputfiles;
begin
  CloseFile(f_state);
  CloseFile(f_rate);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteRateName
  PURPOSE Write names and units of all rate variables to output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: Tstate
  ****************************************************************** }

procedure TSubmodel.WriteRateName(var f: text; fn: string; Time: TState);
var
  i: integer;
  State: TState;
  Caption: string;
begin
  // rewrite output file _rat.csv
  assignfile(f, fn);
  rewrite(f);
  // now in first row
  // write name of time variable
  write(f, Time.name, GlobMod.Separator);
  // write names of all rate variables
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteTofile then
      write(f, StateStrList.Strings[i], GlobMod.Separator);
  end;
  // change to second row
  writeln(f);
  // write units of time variable
  write(f, Time.U, GlobMod.Separator);
  // write units of all rate variables
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteTofile then
    begin
      Caption := State.U;
      write(f, Caption, GlobMod.Separator);
    end;
  end;
  // change to third row, now ready for writing rate values...
  writeln(f);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  SaveRate
  PURPOSE Writes values of rate variables to output files
  INPUT   var f: text;
  fn: string;
  Time: Tstate
  ****************************************************************** }

procedure TSubmodel.SaveRate(var f: text; fn: string; Time: TState);
var
  i: integer;
  State: TState;
  Outstr: string;
begin
  // write value of time variable to output file
  Outstr := FloatToStrf(Time.v - Time.c, ffgeneral, Time.Precision,
    Time.Digits);
  write(f, Outstr, GlobMod.Separator);
  // write values of all rate variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteTofile then
    begin
      Outstr := FloatToStrf(State.c, ffgeneral, Time.Precision, Time.Digits);
      write(f, Outstr, GlobMod.Separator);
    end;
  end;
  writeln(f);
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  CalcRates
  PURPOSE Rate calculation (to be overwritten by derived classes)
  ****************************************************************** }

procedure TSubmodel.CalcRates;
begin
  ShowMessage(' Error !  You should not see this Message ! ');
  ShowMessage(' You did not overwrite Method CalcRates ');
end;


{* *****************************************************************
  CLASS   TSubmodel
  METHOD  CalcVars
  PURPOSE Variable calculation (to be overwritten by derived classes)
  ****************************************************************** }

procedure TSubmodel.CalcVars;
begin
  ShowMessage(' Error !  You should not see this Message ! ');
  ShowMessage(' You did not overwrite Method CalcRates ');
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Activate
  PURPOSE Set isActive flag
  ****************************************************************** }

procedure TSubmodel.activate;
begin
  IsActive := true;
end;

procedure TSubmodel.deactivate;
begin
  IsActive := false;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  ExternVCreate
  PURPOSE Method for creating and and initialising a TExternV variable
  INPUT   Name, Units: string;
  ExV: TexValue;
  var ExternV: TexternV
  ****************************************************************** }

procedure TSubmodel.ExternVcreate(Name, Units: string; ExV: TexValue;
  var ExternV: TExternV; comm: string = '');
begin
  if ExternV = nil then
  begin
    ExternV := TExternV.create(name, Units, ExV, comm);
    ExternVStrList.Sorted := false; // ??
    ExternVStrList.add(name);
    ExternVStrList.objects[ExternVStrList.count - 1] := ExternV;
    ExternVStrList.Sorted := true; // ??
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  ExternVInit
  PURPOSE Setting pointers of external variables
  INPUT   model: Tmod
  ****************************************************************** }

function TSubmodel.ExternVinit(Model: TMod): boolean;
var
  i, j, index: integer;
  subMod: TSubmodel;
  State: TState;
  Variable: TPar;
  ExternV: TExternV;
  Par: TPar;
  Success: boolean;
begin
  Result := true;
  // for all external variables of the submodel do...
  for i := 0 to ExternVStrList.count - 1 do
  begin
    Success := false;
    ExternV := TExternV(ExternVStrList.objects[i]);
    if ExternV.Search then
    begin
      // is external variable stored within weather file?
      index := Model.WeatherFile.FirstLine.indexof(ExternV.name);
      // yes, external variable is stored in weather file
      if (index >= 0) then
      begin
        Par := TPar(Model.WeatherFile.FirstLine.objects[index]);
        ExternV.SetPointer(@Par.fv);
        ExternV.Source := Model.WeatherFile.Filename;
        Success := true;
      end
      else
      begin // no, external variable is not stored in weather file
        for j := 0 to Model.SubModStrList.count - 1 do
        begin
          // check all submodels except the calling submodel itself
          if j <> Model.SubModStrList.indexof(self.SubModname) then
          begin
            subMod := TSubmodel(Model.SubModStrList.objects[j]);
            // is external variable stored in state variables list?
            index := subMod.StateStrList.indexof(ExternV.Name);
            if (index >= 0) then
            begin
              State := TState(subMod.StateStrList.objects[index]);
              if ExternV.Ex = stateField then
                ExternV.SetPointer(@State.fv)
              else
                ExternV.SetPointer(@State.c);
              ExternV.Source := subMod.name;
              Success := true;
            end;
            // if not successful, try searching variables list
            if not Success then
            begin
              index := subMod.VarStrList.indexof(ExternV.Name);
              if (index >= 0) then
              begin
                Variable := TPar(subMod.VarStrList.objects[index]);
                ExternV.SetPointer(@Variable.fv);
                ExternV.Source := subMod.name;
                Success := true;
              end;
            end;
            // if not successful, try searching parameters list
            if not Success then
            begin
              index := subMod.ParStrList.indexof(ExternV.Name);
              if (index >= 0) then
              begin
                Variable := TPar(subMod.ParStrList.objects[index]);
                ExternV.SetPointer(@Variable.fv);
                ExternV.Source := subMod.name;
                Success := true;
              end;
            end;
          end;
        end;
      end;
      // no success at all
      if not Success then
      begin
        ExternV.Source := 'not found';
        ShowMessage('Error on initialisation of interface, Parameter: ' +
            ExternV.Name + '  SubModel:' + self.name);

        result := False;
        break;
      end
    end;
  end;

end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  AddSimValueToDataSeries
  PURPOSE Adding simulated values to corresponding measured data
  ****************************************************************** }

procedure TSubmodel.AddSimValueToDataSeries;
var
  i, ListPos: integer;
  ActSeries: TMeasList;
  ActMeas: TmeasValue;
  ActState: TState;
  ActVar: Tvar;
begin
  for i := 0 to DataList.count - 1 do
  begin
    ActSeries := TMeasList(DataList.objects[i]);
    with ActSeries do
    begin
      if actPOs <= count - 1 then
      begin
        ActMeas := TmeasValue(Items[actPOs]);
        if (ActMeas.Date <= GlobTime.v - GlobTime.c) and
          (ActMeas.Date > Lastdate) then
        begin
          Lastdate := GlobTime.v - GlobTime.c;
          if actPOs < count then
            inc(actPOs);
          ListPos := StateStrList.indexof(name);
          if ListPos <> -1 then
          begin
            ActState := TState(StateStrList.objects[ListPos]);
            ActMeas.sim := ActState.v;
            SumSqrdiff := SumSqrdiff + sqr(ActMeas.sim - ActMeas.meas);
            ActMeas.source := GlobMod.ActIniFile.FileName;
          end
          else
          begin
            ListPos := VarStrList.indexof(name);
            if ListPos <> -1 then
            begin
              ActVar := Tvar(VarStrList.objects[ListPos]);
              ActMeas.sim := ActVar.v;
              ActMeas.source := GlobMod.ActIniFile.FileName;
              // if SumSqrdiff < 10E+100 then
              SumSqrdiff := SumSqrdiff + sqr(ActMeas.sim - ActMeas.meas);
            end;
          end;
        end;
      end;
    end;
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  write_1_1_files
  PURPOSE Output of simulated/measured data pairs to _1_1.csv files
  ****************************************************************** }

procedure TSubmodel.write_1_1_files;
var
  i: integer;
  ActSeries: TMeasList;
begin
  // for all data pairs do...
  for i := 0 to DataList.count - 1 do
  begin
    ActSeries := TMeasList(DataList.objects[i]);
    ActSeries.WriteTofile(GlobMod.FOutputPath + '/' + ActSeries.name +
        '_1_1.csv');
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  CalcLinearRegressions
  PURPOSE Calculation of linear regression
  ****************************************************************** }

procedure TSubmodel.CalcLinearRegressions;
var
  i: integer;
  ActSeries: TMeasList;
begin
  // for all data pairs do...
  for i := 0 to DataList.count - 1 do
  begin
    ActSeries := TMeasList(DataList.objects[i]);
    ActSeries.LeastSquares;
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  ClearDataSeries
  PURPOSE Clears data pair series
  ****************************************************************** }

procedure TSubmodel.ClearDataSeries;
var
  i: integer;
  ActSeries: TMeasList;
  IsSelforOpt: boolean;
begin
  // for all data pairs do...
  for i := 0 to DataList.count - 1 do
  begin
    ActSeries := TMeasList(DataList.objects[i]);
    IsSelforOpt := ActSeries.SelForOpt;
    ActSeries.Clear; // Clears data pair series
    ActSeries.SelForOpt := IsSelforOpt;
  end;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Paint
  PURPOSE New Paint procedure for TSubmodel (which is derived from TGraphicControl)
  ****************************************************************** }

procedure TSubmodel.Paint;
var
  X, Y, w, h, text_left, text_length: integer;
  Titel: string;
  TypeStr: string;
  oldfontsize: integer;
begin
  inherited;

  if Visible then
  begin
    Titel := Name;
    TypeStr := ClassName;
    with Canvas do
    begin
      Brush.Color := Color;
      X := Pen.Width div 2;
      Y := X;
      w := Width - Pen.Width + 1;
      h := Height - Pen.Width + 1;
      // if w < h then s := w else s := h;
      Rectangle(X, Y, X + w, Y + h);
      text_length := TextWidth(Titel);
      text_left := (Width - text_length) div 2;
      TextOut(text_left, Height div 4 - TextHeight(Titel) div 2, Titel);
      oldfontsize := Canvas.Font.Size;
      Canvas.Font.Size := Canvas.Font.Size - 2;
      text_length := TextWidth(TypeStr);
      text_left := (Width - text_length) div 2;
      TextOut(text_left, (Height div 4) * 3 - TextHeight(Titel) div 2,
        '(' + TypeStr + ')');
      Canvas.Font.Size := oldfontsize;
    end;

  end;

end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  Destroy
  PURPOSE Remove submodel entry from global TMod instance and call inherited
  destroy method
  ****************************************************************** }

procedure TSubmodel.beforedestruction;
var
  index: integer;
begin
  self.fUpdateValueList.Free;
  self.FUpdValues.Free;
  self.FMeasValues.Free;
  self.FMeasValues_2.Free;
{  if StateIniF <> nil then
    self.StateIniF.Free;
  self.ParIniF.Free;
  self.VarStrList.Free;
  self.ParStrList.Free;
  ExternVStrList.Free;
  ConstStrList.Free;
  OptionStrList.Free;   }
   fAssimilatedSubmodList.Free;
   DataList.Free;

  if self.SM_GlobMod <> nil then
  begin
    If SM_GlobMod.SubModStrList <> nil then begin
    index := SM_GlobMod.SubModStrList.indexof(self.name);
    if SM_GlobMod.SubModStrList.Objects[index] <> nil then
      SM_GlobMod.SubModStrList.delete(index);
  end;
  end;
  inherited beforedestruction;
end;

{* *****************************************************************
  CLASS   TSubmodel
  METHOD  DblClick
  PURPOSE Show Message after doubleclick on TSubmodel during Runtime
  ****************************************************************** }

procedure TSubmodel.DblClick;
var
  FormSubModelEditor: TF_SubmodelEditor;
  params: TPar;
  variables: Tvar;
  states: TState;
  externs: TExternV;
  i: integer;
begin
  // ShowMessage('Sub-model created using HUME');
  { HumeForm := THumeForm.create;
    HumeForm.showmodal;
    HumeForm.clear; }
  self.init(GlobMod);
  FormSubModelEditor := TF_SubmodelEditor.create(nil);
  FormSubModelEditor.Caption := 'Editing ' + name;
  with FormSubModelEditor.ADV_Par do
  begin
    EditorMode := true;
    // displays TPar
    if ParStrList.count > 0 then
      rowcount := ParStrList.count + 1
    else
      rowcount := 2;
    colcount := 9;
    rows[0].CommaText :=
      'Name,Unit,Value,Digits, Precision,ReadFromFile,WriteToFile,Optimization,PlotToGraph';
    for i := 0 to ParStrList.count - 1 do
    begin
      params := TPar(ParStrList.objects[i]);
      Cells[0, i + 1] := params.name;
      Cells[1, i + 1] := params.U;
      Cells[2, i + 1] := FloatToStrf(params.v, ffgeneral, 6, 3);
      Cells[3, i + 1] := IntToStr(params.Digits);
      Cells[4, i + 1] := IntToStr(params.Precision);
      AddCheckBox(5, i + 1, true, true);
      SetCheckBoxState(5, i + 1, params.ReadFromFile);
      AddCheckBox(6, i + 1, true, true);
      SetCheckBoxState(6, i + 1, params.WriteTofile);
      AddCheckBox(7, i + 1, true, true);
      SetCheckBoxState(7, i + 1, params.SelForOpt);
      AddCheckBox(8, i + 1, true, true);
      SetCheckBoxState(8, i + 1, params.PlotTograpH);
    end;
  end;
  // displays TVar
  with FormSubModelEditor.adv_var do
  begin

    if VarStrList.count > 0 then
      rowcount := VarStrList.count + 1
    else
      rowcount := 2;
    colcount := 8;
    rows[0].CommaText :=
      'Name,Unit,Value,Digits, Precision,ReadFromFile,WriteToFile,PlotToGraph';
    for i := 0 to VarStrList.count - 1 do
    begin
      variables := Tvar(VarStrList.objects[i]);
      Cells[0, i + 1] := variables.name;
      Cells[1, i + 1] := variables.U;
      Cells[2, i + 1] := FloatToStrf(variables.v, ffgeneral, 6, 3);
      Cells[3, i + 1] := IntToStr(variables.Digits);
      Cells[4, i + 1] := IntToStr(variables.Precision);
      AddCheckBox(5, i + 1, true, true);
      SetCheckBoxState(5, i + 1, variables.ReadFromFile);
      AddCheckBox(6, i + 1, true, true);
      SetCheckBoxState(6, i + 1, variables.WriteTofile);
      AddCheckBox(7, i + 1, true, true);
      SetCheckBoxState(7, i + 1, variables.PlotTograpH);
    end;
  end;
  // displays TState
  with FormSubModelEditor.adv_state do
  begin

    if StateStrList.count > 0 then
      rowcount := StateStrList.count + 1
    else
      rowcount := 2;
    colcount := 8;
    rows[0].CommaText :=
      'Name,Unit,Value,Digits, Precision,ReadFromFile,WriteToFile,PlotToGraph';
    for i := 0 to StateStrList.count - 1 do
    begin
      states := TState(StateStrList.objects[i]);
      Cells[0, i + 1] := states.name;
      Cells[1, i + 1] := states.U;
      Cells[2, i + 1] := FloatToStrf(states.v, ffgeneral, 6, 3);
      Cells[3, i + 1] := IntToStr(states.Digits);
      Cells[4, i + 1] := IntToStr(states.Precision);
      AddCheckBox(5, i + 1, true, true);
      SetCheckBoxState(5, i + 1, states.ReadFromFile);
      AddCheckBox(6, i + 1, true, true);
      SetCheckBoxState(6, i + 1, states.WriteTofile);
      AddCheckBox(7, i + 1, true, true);
      SetCheckBoxState(7, i + 1, states.PlotTograpH);
    end;
  end;

  with FormSubModelEditor.ADV_ExternV do
  begin
    // displays TExternValue
    if ExternVStrList.count > 0 then
      rowcount := ExternVStrList.count + 1
    else
      rowcount := 2;
    colcount := 4;
    rows[0].CommaText := 'Name,Unit,C_F, Source';
    for i := 0 to ExternVStrList.count - 1 do
    begin
      externs := TExternV(ExternVStrList.objects[i]);
      Cells[0, i + 1] := externs.name;
      Cells[1, i + 1] := externs.U;
      Cells[2, i + 1] := FloatToStrf(externs.C_f, ffgeneral, 6, 3);
      Cells[3, i + 1] := externs.Source;
    end;
  end;

  with FormSubModelEditor do
  begin

    ADV_Par.autosizecolumns(true, 0);
    adv_var.autosizecolumns(true, 0);
    adv_state.autosizecolumns(true, 0);
    ADV_ExternV.autosizecolumns(true, 0);
    // shows Editor
    showmodal;
    // stores modified values to properties
    if save_Status then
    begin
      // stores TPar
      for i := 0 to ParStrList.count - 1 do
      begin
        params := TPar(ParStrList.objects[i]);
        params.U := ADV_Par.Cells[1, i + 1];
        params.v := StrToFloat(ADV_Par.Cells[2, i + 1]);
        params.Digits := strtoint(ADV_Par.Cells[3, i + 1]);
        params.Precision := strtoint(ADV_Par.Cells[4, i + 1]);
        ADV_Par.GetCheckboxState(5, i + 1, params.ReadFromFile);
        ADV_Par.GetCheckboxState(6, i + 1, params.WriteTofile);
        ADV_Par.GetCheckboxState(7, i + 1, params.SelForOpt);
        ADV_Par.GetCheckboxState(8, i + 1, params.PlotTograpH);
      end;
      // stores TVar
      for i := 0 to VarStrList.count - 1 do
      begin
        variables := Tvar(VarStrList.objects[i]);
        variables.U := adv_var.Cells[1, i + 1];
        variables.v := StrToFloat(adv_var.Cells[2, i + 1]);
        variables.Digits := strtoint(adv_var.Cells[3, i + 1]);
        variables.Precision := strtoint(adv_var.Cells[4, i + 1]);
        adv_var.GetCheckboxState(5, i + 1, variables.ReadFromFile);
        adv_var.GetCheckboxState(6, i + 1, variables.WriteTofile);
        adv_var.GetCheckboxState(7, i + 1, variables.PlotTograpH);
      end;
      // stores TState
      for i := 0 to StateStrList.count - 1 do
      begin
        states := TState(StateStrList.objects[i]);
        states.U := adv_state.Cells[1, i + 1];
        states.v := StrToFloat(adv_state.Cells[2, i + 1]);
        states.Digits := strtoint(adv_state.Cells[3, i + 1]);
        states.Precision := strtoint(adv_state.Cells[4, i + 1]);
        adv_state.GetCheckboxState(5, i + 1, states.ReadFromFile);
        adv_state.GetCheckboxState(6, i + 1, states.WriteTofile);
        adv_state.GetCheckboxState(7, i + 1, states.PlotTograpH);
      end;
      // stores TExternValue
      for i := 0 to ExternVStrList.count - 1 do
      begin
        externs := TExternV(ExternVStrList.objects[i]);
        externs.name := ADV_ExternV.Cells[0, i + 1];
        externs.U := ADV_ExternV.Cells[1, i + 1];
        externs.C_f := StrToFloat(ADV_ExternV.Cells[2, i + 1]);
      end;

    end;
    Free;
  end;

end;

{* *****************************************************************
  CLASS   TMod
  METHOD  DblClick
  PURPOSE Shows Message after doubleclick on TMod during Run-time
  ****************************************************************** }

procedure TMod.DblClick;
var
  // HumeForm : TFormHumeShow;
  FormModelEditor: TModelEdit;
  i, j, OldIndex, NewIndex, submodindex: integer;
  subMod: TSubmodel;
  // f: textFile;



begin
  if GM_ControlFile = '' then
  begin
    ShowMessage('No Controlfile specified');
    exit;
  end;
  // creates model editor form
  FormModelEditor := TModelEdit.create(nil);
  // copies values from TMod properties to editor form
  with FormModelEditor do
  begin

    TimeInit := Str_SectionName_TimeInit;
    FileNames := Str_SectionName_FileNames;
    endZeit := Str_SectionTopic_SimEnd;
    TimeStep := Str_SectionTopic_TimeStep;
    StateIniFN := Str_SectionTopic_StateIniFN;
    ParamIniFN := Str_SectionTopic_ParamIniFN;
    WeatherFilefn := Str_SectionTopic_WeatherFileFN;
    ListBoxSubModels.Sorted := false;
    ListBoxSubModels.Items.AddStrings(SubModStrList);
   { if SubModStrList.count > 0 then
    begin
      for i := 0 to SubModStrList.count - 1 do
        ListBoxSubModels.Items.add(SubModStrList.Strings[i]);
    end;}
    Edit_ModelName.text := Name;
    ComboBox_Separator.text := Separator;
    DateTimePicker_MT_Starttime.Date := StartTime;
    DateTimePicker_MT_Endtime.Date := EndTime;
    Edit_MT_Name.text := ModTime.name;
    Edit_MT_Unit.text := ModTime.U;
    Edit_MT_Value.text := FloatToStr(ModTime.v);
    Edit_MT_Digits.text := IntToStr(ModTime.Digits);
    Edit_MT_Precision.text := IntToStr(ModTime.Precision);
    CheckBox_MT_WriteToFile.Checked := ModTime.WriteTofile;
    Edit_MP_Inputpath.text := GM_InPutPath;
    Edit_MP_Outputpath.text := GM_OutPutPath;
    Edit_MP_Controlfilepath.text := GM_ControlFile;
    Edit_MP_Regressionfilepath.text := Reg_fn;
    Edit_MO_DefaultError.text := FloatToStr(LMOptions.FDefaultError);
    Edit_MO_Divisor.text := FloatToStr(LMOptions.Divisor);
    Edit_MO_IniLambda.text := FloatToStr(LMOptions.FIniLambda);
    if LMOptions.WeightOptions = OptNoWeight then
      ComboBox_MO_WeightOptions.text := 'OptNoWeight';
    if LMOptions.WeightOptions = OptDefaultWeight then
      ComboBox_MO_WeightOptions.text := 'OptDefaultWeight';
    if LMOptions.WeightOptions = OptMeasErrorWeight then
      ComboBox_MO_WeightOptions.text := 'OptMeasErrorWeight';
    ListBoxControlFileStrings.Items := FIniFiles;
    EditNameControlFile.text := ControlFileFn;
    // shows Editor
    ShowMessage('Entering Componenent Editor');
    showmodal;
    ShowMessage('Leaving Componenent Editor');
    // stores modified values from editor form to properties
     if FormModelEditor.Save_Status then
      ShowMessage('Save = true') else
      ShowMessage('Save = false');
    if save_Status then
    begin
      // ShowMessage('hello - FormModelEditor.Save_Status');
      Name := Edit_ModelName.text;
      Separator := ComboBox_Separator.text[1];
      StartTime := DateTimePicker_MT_Starttime.Date;
      EndTime := DateTimePicker_MT_Endtime.Date;
      ModTime.name := Edit_MT_Name.text;
      ModTime.U := Edit_MT_Unit.text;
      ModTime.v := StrToFloat(Edit_MT_Value.text);
      ModTime.Digits := strtoint(Edit_MT_Digits.text);
      ModTime.Precision := strtoint(Edit_MT_Precision.text);
      ModTime.WriteTofile := CheckBox_MT_WriteToFile.Checked;
      GM_InPutPath := Edit_MP_Inputpath.text;
      GM_OutPutPath := Edit_MP_Outputpath.text;
      GM_ControlFile := Edit_MP_Controlfilepath.text;
      Reg_fn := Edit_MP_Regressionfilepath.text;
      LMOptions.FDefaultError := StrToFloat(Edit_MO_DefaultError.text);
      LMOptions.Divisor := StrToFloat(Edit_MO_Divisor.text);
      LMOptions.FIniLambda := StrToFloat(Edit_MO_IniLambda.text);
      if ComboBox_MO_WeightOptions.text = 'OptNoWeight' then
        LMOptions.WeightOptions := OptNoWeight;
      if ComboBox_MO_WeightOptions.text = 'OptDefaultWeight' then
        LMOptions.WeightOptions := OptDefaultWeight;
      if ComboBox_MO_WeightOptions.text = 'OptMeasErrorWeight' then
        LMOptions.WeightOptions := OptMeasErrorWeight;

      for I := 0 to ListBoxSubmodels.Count - 1 do begin
         Name := ListBoxSubmodels.Items[i];
         SubModIndex := SubModStrList.indexof(Name);
         SubMod := TSubmodel(SubModStrList.objects[SubModIndex]);
         SubMod.CompIndex := i;
      end;

      for j := SubModStrList.Count - 2 downto 0 do
        for i := 0 to j do
        if TSubmodel(SubModStrList.objects[i]).CompIndex > TSubmodel(SubModStrList.objects[i+1]).CompIndex
           then SubModStrList.Exchange(i,i+1);


{      for i := 0 to SubModStrList.count - 1 do
      begin
        Name := SubModStrList.Strings[i];
        SubModStrList.Sort;
        OldIndex := SubModStrList.indexof(Name);
        NewIndex := ListBoxSubModels.Items.indexof(Name);
        subMod := TSubmodel(SubModStrList.objects[OldIndex]);
        subMod.CompIndex := NewIndex;
//        subMod := TSubmodel(SubModStrList.objects[i]).CompIndex :=
      end;}
    end;
    Free;
  end;
end;

end.
