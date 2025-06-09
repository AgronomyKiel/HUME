/// <summary> UMod is a unit that defines the base classes TMod and TSubmodel. TMod can be instantiated directly and is the central control object of a simulation model.No license found
/// It summarizes the submodels of the simulation model and provides methods for data output, parameter estimation, and sensitivity analysis. 
/// TSubModel is an abstract base class for problem specific submodels. Furthermore some other classes are defined. </summary>
unit UMod;

{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

interface

uses
  //AdvGrid,
  SysUtils, Classes,
  System.IniFiles,
  System.UITypes,
  // DesignEditors,
  // instance properties
  // IniFilesNew, // Delphi VCL: Implements TIniFile class, handling INI file text format
  UState, // HUME: TVar, TPar, TState and TExternV classes
  UTextfileH, // HUME: TTextFileH class, handling tabular ASCII files
  UMeasValue, // HUME: MeasValue and TMeasList, handling measurement data
  UModUtils, // HUME: string routines and numerical routines
  {$IFNDEF NONVISUAL}
  Windows,
  Messages,
  vcl.controls,
  vcl.ComCtrls,
  vcl.Graphics,
  vcl.Dialogs,
  UFormSubmodelEditor, // HUME: TF_SubModelEdit, Designtime formular for editing
  // TSubModel instance properties
  UFormModelEditor, // HUME: TModelEdit, Designtime formular for editing TMod
  UFormDebugAbstract,
  {$ENDIF}
  Math;

type

  /// <summary> enumeration type for model Elements </summary>
  TModelElements = (States, Vars, Params, Externals, Consts);

  /// <summary> enumeration type strings for model Elements </summary>
  TModelElementNames = array [TModelElements] of string;

  /// <summary> type for numbers of Model Elements in each submodel </summary>
  TNumbersOf = array [TModelElements] of Integer;

  /// <summary> type for list of stringlists of Model Elements in each submodel </summary>
  TListsOf = array [TModelElements] of TStringList;


  /// <summary> Use TMemIniFile for Inifiles </summary>
  TMyIniFile   = TMemIniFile;

  /// <summary> redefined floating point type </summary>
  real = double;

  /// <summary> enumeration type for shape of submodel in diagram </summary>
  TShapeType = (stRectangle, stSquare, stRoundRect, stRoundSquare, stEllipse,
    stCircle);

  /// <summary> Options for weighting of data points during optimization </summary>
  TWeightOptions = (OptNoWeight, OptDefaultWeight, OptMeasErrorWeight);

  /// <summary> Options for parameter Optimization </summary>
  TOptOption = (optAllInis, optAllInisSeperate, optOnlyActIni);

/// <summary> Options for continous output,
/// NoContOuput: No Outputfile is written, even if Option ContOutput of submodel is true,
/// AllContOutput: Outputfile is written, even if Option ContOuput of submodel is false
/// SubmodelSpecific: Outputfile is written, according to Option ContOutpus of submodel </summary>
  TContOutput  = (NoContOutput,
                AllContoutput,
                SubmodelSpecific);

const
  
  /// <summary> string constants for Model element names </summary>
  ModelElementNames: TModelElementNames = ('State Variables', 'Variables',
    'Parameters', 'Exernal Values', 'Constants');

  {$IFDEF LINUX}
/// <summary> Path separator for Linux </summary>
  Path_sep =  '/';
  {$ELSE}
/// <summary> Path separator for Windows </summary>  
  Path_sep =  '\';
  {$ENDIF}



type

/// <summary> abstract base type for the main model control component 
/// all submodels have to be connected to this component via their property gm_submodel property. </summary>
  TMod = class;
  

  { * -----------------------------------------------------------------
    CLASS     TMarquardOptions
    ANCESTOR  TPersistent
    PURPOSE   Options for the Marquard-Method used for parameter estimation
    ------------------------------------------------------------------ }

/// <summary> Options for the Marquard-Method used for parameter estimation 
/// it is descended either from Tobject if compiled for command line application or from
/// TPersistent if compiled for GUI appplication </summary>
{$IFDEF NONVISUAL}
  TMarquardOptions = class(TObject)
{$ELSE}
  TMarquardOptions = class(TPersistent)
{$ENDIF}
  private
  protected
  public
    /// <PublicField> Initial value of parameter Lambda </PublicField>
    FIniLambda: real;
    /// <PublicField> Value which is needed for numerical approximation of function derivative </PublicField>
    FDivisor: real;
    
    /// <PublicField> Options for weighting of data points during optimization </PublicField>
    FWeightOptions: TWeightOptions;
    
    /// <PublicField> Default error for weighting of data points </PublicField>
    FDefaultError: real;
    
    /// <PublicField> Options for parameter Optimization </PublicField>
    FOptOption: TOptOption;
    
    constructor create;
  published

    /// <summary> Initial value of parameter Lambda </summary>
    property IniLambda: real read FIniLambda write FIniLambda;
  
    /// <summary> Value which is needed for numerical approximation of function derivative </summary>
    property Divisor: real read FDivisor write FDivisor;
  
    /// <summary> Options for weighting of data points during optimization </summary>
    property WeightOptions: TWeightOptions read FWeightOptions
      write FWeightOptions;
  
    /// <summary> Default error for weighting of data points </summary>
    property DefaultError: real read FDefaultError write FDefaultError;
    
    /// <summary> Options for parameter Optimization </summary>
    property OptOption: TOptOption read FOptOption write FOptOption;
  end;

  { * ----------------------------------------------------------------
    CLASS     TSensitivityOptions
    ANCESTOR  TPersistent
    PURPOSE   Simple class to save options for Sensitivity analysis
    used within the TMod class
    ------------------------------------------------------------------ }

/// <summary> Simple class to save options for Sensitivity analysis </summary>
{$IFDEF NONVISUAL}
  TSensitivityOptions = class(TObject)
{$ELSE}
  TSensitivityOptions = class(TPersistent)
{$ENDIF}
  private
/// <summary> The ModelComponenent </summary>    
    fMod: TMod;
    
    /// <summary> file variables and names for output of sensitivity analysis </summary>
    f_a, f_b: array [0 .. 30] of textFile;
    fn_a, fn_b: array [0 .. 30] of string;
    
    /// <summary> maximum value during sensitivity analysis </summary>
    FMaxValue: real;
    
    /// <summary> minimum value during sensitivity analysis </summary>
    FMinValue: real;
    
    /// <summary> Steps of sensitivity analysis </summary>
    FSteps: Integer;
    
/// <summary> change of parameter per sensitivy setpp </summary>
    FDPar: real;
    
    /// <summary> Variables selected for output </summary>
    Sens_f: textFile;
    
    /// <summary> output file name for sensitivity data </summary>
    FSens_fn: string;//TMyFileName;
    
    /// <summary> Parameter selected for sensitivity analysis </summary>
    procedure SetMAxValue(const MaxValue: real); /// Sets maximum value during sensitivity analysis

    /// <summary> Parameter selected for sensitivity analysis </summary>
    procedure SetMinValue(const MinValue: real); /// Sets minimum value during sensitivity analysis

    /// <summary> Parameter selected for sensitivity analysis </summary>
    procedure SetSteps(const Steps: Integer);/// Sets number of steps of sensitivity analysis
  protected
  public
    /// <summary> Parameter selected for sensitivity analysis </summary>
    SelSenspar: TPar;   
    /// <summary> Output variables selected for sensitivity analysis </summary>
    FOutList: TStringList;  
    MultSens_fn_final,
    MultSens_fn_cont: string;
    constructor create(Model: TMod);
  published
    /// <summary> Maximum value during sensitivity analysis </summary>
    property MaxValue: real read FMaxValue write SetMAxValue;

    /// <summary> Minimum value during sensitivity analysis </summary>
    property MinValue: real read FMinValue write SetMinValue;

    /// <summary> Steps of sensitivity analysis </summary>
    property Steps: Integer read FSteps write SetSteps;

    /// <summary> change of parameter per sensitivy stet </summary>
    property DPar: real read FDPar write FDPar;

    /// <summary> Variables selected for output </summary>
    property OutList: TStringList read FOutList write FOutList;

    /// <summary> file variables and names for output of sensitivity analysis </summary>
    property Sens_fn: string read FSens_fn write FSens_fn;
  end;

 /// <summary> Abstract base class for a model component </summary>
  TSubmodel = class; /// abstract base type for a model component, forward declaration

  { * -----------------------------------------------------------------
    CLASS     TMod
    ANCESTOR  TGraphicControl
    PURPOSE   Basic model integrator and control module:
    Provides routines for simulation process control,
    parameter estimation and statistical quality control
    ------------------------------------------------------------------ }


/// <summary> Base type for the central model component 
/// It summarizes the submodels of the simulation model and provides methods for data output, parameter estimation, and sensitivity analysis.
/// It is descended either from Tobject if compiled for command line application or from
/// TPersistent if compiled for GUI appplication.
/// </summary>

{$IFDEF NONVISUAL}
  TMod = class(TObject) 
{$ELSE}
  TMod = class(TGraphicControl) 
{$ENDIF}
  private
    /// <PrivateField> Name of Model </PrivateField>
    fName : string; /// Name of Model
    
    /// <PrivateField> directory where program file is located </PrivateField>
    EXE_DIR: string; /// directory where program file is located
    /// directory where program file is located
    /// <PrivateField> directory where program file is located </PrivateField>
    FApplicationPath: TPath; /// directory where program file is located
    /// field for adress of status bar on main model formula
    
    /// <PrivateField> Model name </PrivateField>
    FTitle: string;     /// Modeltitle


{$IFNDEF NONVISUAL}
    /// <PrivateField> status bar in Main Formular Simulation info </PrivateField>
    fStatusBar: TStatusBar; /// status bar in Main Formular Simulation info
    fStatusBarOpt : TStatusBar; /// status bar in Formular for optimization
{$ENDIF}
    
    /// <PrivateField> Name of controlfile </PrivateField>
    fControlFileFn: string; //TMyFileName; /// Name for controlfile
    
    /// <PrivateField> Name of file where regression results are stored </PrivateField>
    FReg_FN: string;  /// Name of file where regression results are stored
    
    /// <PrivateField> Name of file where Model documentation is stored </PrivateField>
    fDocu_FN: string;  /// Name of file where Model documentation is stored
    fDocu_FN2: string; /// Name of file where Model documentation 2 is stored
    
    /// <PrivateField> Name of global output file </PrivateField>
    fFNGlobalOutput: string; /// file name for global Output
///
    /// <PrivateField> Default directory for output </PrivateField>
    FOutputPath: TPath; /// default directory for output
    
    /// <PrivateField> flag for reading output path from Ini-file </PrivateField>
    fReadIniOutputPath: boolean; /// flag for
    
    /// <PrivateField> Default directory for input </PrivateField>
    FInputPath: TPath;
    
    /// <PrivateField> separator in outputfiles </PrivateField>
    FSeparatorChar: Char;

    /// <PrivateField> Time step for model integration </PrivateField>
    FTimeStep: real;
    /// Time step for model integration
    
    /// <PrivateField> Start of simulation </PrivateField>
    FStartTime: TDateTime;  /// Start of simulation
    
    /// <PrivateField> End of simulation </PrivateField>
    FEndTime: TDateTime;   /// End of simulation
    
    /// <PrivateField> Options for optimization </PrivateField>
    FSensOptions: TSensitivityOptions; /// Options for sensitivity analysis
    
    /// <PrivateField> smallest measured value accepted in Optimization </PrivateField>
    FMinLegalValue: real; /// smallest measured value accepted in Optimization
    
    /// <PrivateField> flag if model should be reinitalised after run: defaul: true </PrivateField>
    fReInitAfterRun: boolean;/// flag if model should be reinitalised after run: defaul: true
    
    /// <PrivateField> flag for showing time in date format </PrivateField>
    fShowDateFormat: boolean;  /// flag for showing time in date format
    
    /// <PrivateField> flag for writing res.ini files for documentation </PrivateField>
    fWriteResIni: boolean; /// flag for writing res.ini files for documentation.
    
    /// <PrivateField> flag for writing res.ini files for documentation </PrivateField>
    fChiSqr: real;
    /// field for total sum of squared differences (sim-meas)
    
    /// <PrivateField> option for continous output, type is TContOutput which defines the options
    /// NoContOutput, SubmodelSpecific and  AllContoutput </PrivateField>
    fContOutput: TContOutput; /// option for
    fOptContOutput: TOption;
    /// Toggle choice for file output every time step

 // strings for section names in Ini files
    FStr_SectionName_TimeInit,
    FStr_SectionNameMeasurementFiles,
    FStr_SectionNameUpdateFiles,
    FStr_SectionNameOutputFiles,
    FStr_SectionName_FileNames,
    FStr_SectionTopic_SimStart,
    FStr_SectionTopic_SimEnd,
    FStr_SectionName_SimOptions,
    FStr_SectionTopic_TimeStep,
    FStr_SectionTopic_ContOutput,
    FStr_SectionTopic_StateIniFN,
    FStr_SectionTopic_ParamIniFN,
    FStr_SectionTopic_OptionIniFN,
    FStr_SectionTopic_WeatherFileFN,
    FStr_SectionTopic_OutputDir: string;

    /// setter for submodel 
    procedure setSubModel(index: Integer; const SubModel: TSubmodel);

    /// <summary> getter for submodel </summary>
    function getSubModel(index: Integer): TSubmodel;

    /// <summary> Method for setting the start time of the simulation </summary>
    procedure Set_StartTime(const StartTime: TDateTime);

    /// <summary> Method for setting the end time of the simulation </summary>
    procedure Set_EndTime(const EndTime: TDateTime);

    /// <summary> Method for setting the time step of the simulation </summary>
    procedure Set_TimeStep(const TimeStep: real);

    /// <summary> Method for writing the names of variables for the sensitivity analysis to a file </summary>
    procedure WriteSensNames(Variable: Tvar; var f: text);

    /// <summary> Method for writing the names of variables for the global output to a file </summary>
    procedure WriteGlobalOutputNames(fn: string);

    /// <summary> Method for writing the names of variables for the global output to a file </summary>
    procedure WriteSensValue(Variable: Tvar; Iter: Integer; var f_a, f_b: text);

    /// <summary> Method creating an Inifile from scratch</summary>
    procedure CreateIniFiles(OptionInifilefn: string; ParamIniFilefn: string;
      StateInifilefn: string);
    
    /// <summary> Method for sorting the submodels in the list of submodels according to their value of thier property CompIndex </summary> 
    procedure SortSubMods;
    
    /// <summary> Method for time initialisation </summary>
    procedure InitTime(IniFile: TMyIniFile);
    
    /// <summary> Method for initialising the state ini file </summary>
    procedure InitStateIniFile(var StateInifilefn: string);

    /// <summary> Method for initialising the parameter ini file </summary>
    procedure InitParmIniFile(var ParamIniFilefn: string);

    /// <summary> Method for initialising the options ini file </summary>
    procedure InitOptionsIniFile(var OptionInifilefn: string);

    /// <summary> Method for calculation and savin linear regressions between measured and simulated values </summary>
    procedure CalcAndSaveLinearRegressionSimMeas(fn: string; i: Integer);
    
    /// <summary> Method for checking if the submodel is set for continuous output </summary> 
    procedure IsSubModelContOutput;

    /// <summary> Method for reading or creating the ini files </summary>
    procedure ReadOrCreateInifiles;
    
    /// <summary> Method for initialisation of the weather data file </summary>
    procedure InitWeatherFile(WeatherFilefn: string);
{$IFNDEF NONVISUAL}
    procedure Check_GM_OutputPath;
    procedure LookForControlfile(var ControlFileFN:string);
    
    /// <summary> Method for updating the status bar on the GUI at every timestep </summary>
    procedure UpdateStatusbar;
    procedure SetPaintStyle;
{$ENDIF}

  protected

{$IFNDEF NONVISUAL}
    /// Method for showing object on the screen
    procedure Paint; override;  
{$ENDIF}

    /// <summary> Method for writing results to file, including a summary of the model settings </summary>
    procedure writeRes(fn: string);  /// write parameters and filenames of simulation run to result file
  public
    FLMOptions: TMarquardOptions;
 //   {$IFNDEF NONVISUAL}
    FPropIniFile: TMyIniFile; /// Pointer for GUI-properties saving file
 //   {$ENDIF}

    /// List of Inifiles
    FIniFiles: TStringList;

    /// File variable of results of regression analysis
    FRegFile: textFile;

    /// <summary> The time state variable </summary>
    Time: TState;  /// model time
    
    /// <summary> List of sub-models </summary>
    SubModStrList: TStringList;    /// List of sub-models
    
    /// <summary> flag for end of simulation </summary>
    ModelEnd: boolean;  /// End of simulation ?
    
    /// <summary> the actual ini-file </summary>
    ActIniFile: TMyIniFile; /// TMyIniFile; // actual Ini-File
    
    /// <summary> Ini-file with parameter values </summary>
    ParamInifile: TMyIniFile; /// Ini-file with parameter values
    
    /// <summary> Ini-file with state variable initial values </summary>
    StateIniFile: TMyIniFile;  /// Ini-file with state variable initial values
    
    /// <summary> Ini-file with options for submodels </summary>
    OptionIniFile: TMyIniFile; /// Ini-file with options for submodels
    
    /// <summary> TXT-file with weather data </summary>
    WeatherFile: TTextFileH; /// Weather data
    
    /// <summary> Output file stream for global output </summary>
    f_GlobalOutput : TStreamWriter;  /// output stream/file for output of selected vars
    
    /// <summary> Output file stream for global output </summary>
    AllMeasVal: TMeasList; /// list of all measurement values
    
    /// <summary> List of measured values </summary>
    SelMeasVal: TMeasList;  /// list of measurement values selected for optimization
    
    /// <summary> List of all parameters to be optimized </summary>
    SelParList: TStringList;  /// address list of all parameters to be optimized
    
    /// <summary> List of output variables selected for global output </summary>
    GlobalOutputList: TStringList; ///  address list of all values for global output
    
    /// <summary> Time of first weather data in Excel-Time integers </summary>
    FirstWeatherData: Integer;

    /// <summary> Time of last weather data in Excel-Time integers </summary>
    LastWeatherData: Integer;
    procedure free;

// {$IFDEF NONVISUAL}

/// <summary> Name of Model </summary>
  property Name: string read fName write fName;
// {$ENDIF}

{$IFNDEF NONVISUAL}
 ///  constructor create
    constructor Create(AOwner: TComponent); override;
{$ELSE}
    constructor create;
{$ENDIF}
    
    /// <summary> method for setting a new control file name </summary>
    procedure Set_ControlFileFN(NewFN:string);// (NewFN:string);
    
    /// <summary> method for retrieving the control file name </summary>
    function Get_ControlFileFn: string;
    procedure setPropFromIniFile(strList: TStringList; submodname: string) ;

    /// <summary> Method retrieving a parameter adress by its name </summary>
    procedure GetParameter(ParName: string; var Par: TPar;
      var SubModname: string; var Success: boolean); virtual;
    
   /// <summary> Method retrieving a state variable adress by its name </summary> 
    procedure GetStateVar(StateName: string; var State: TState;
      var SubModname: string; var Success: boolean);

    /// <summary> Method retrieving a variable adress by its name </summary>  
    procedure GetVariable(VarName: string; var Variable: Tvar;
      var SubModname: string; var Success: boolean);
    
    /// <summary> Method for running the simulation model
    /// over all inifiles specified in the control file </summary>
    procedure run; virtual; /// run method
    
    /// <summary> Method for running the simulation model for the actual inifile </summary> 
    procedure runActIni; virtual;  /// run method for actual INI-file
    
    /// <summary> Method intialisation of the model </summary>
    procedure Init(IniFile: TMyIniFile); virtual; /// Initialisation method
    
    /// call inititalisation methods of sub-models
    procedure InitAllSubMods;
    /// call data inititalisation methods of sub-models
    procedure InitAllDataSeries;
    /// call data inititalisation methods of sub-models
    procedure InitGlobalOutputList;///
    /// call integration methods of all sub-models
    procedure integrateAllSubModels; virtual;
    /// call rate calculations of all sum-models
    procedure CalcAllRates;
    /// call variable calculations of all sub-models
    procedure CalcAllVars;
    /// call update procedure for all sub-models if applicable
    procedure UpdateAll;
    /// write state and rate names for all sub-models
    procedure WriteAllNames;
    
    /// <summary> write final names of all sub-models to file </summary>
    procedure WriteAllFinalNames;
    
    /// <summary> add simulated values to the corresponding measurement data </summary>
    procedure AddAllSimValuestoDataSeries;
    
    /// <summary> save the values of the state variables to the output file each time step </summary>
    procedure SaveStates;
    
    /// save last values of states in file
    procedure SaveFinalStates;
    
    /// save last values of rates in file
    procedure SaveRates;
    
    /// <summary> write selected values to a 'global' output file, containing the results of each single simulation
    /// wrapped toegether in the corresponding control file </summary>
    procedure SaveGlobalOutput(IniFile: string);
    
    /// <summary>  close all files opened during simulation run </summary>
    procedure CloseAllFiles;

    /// <summary>  close all final files opened during simulation run </summary>
    procedure CloseAllFinalFiles;

    /// <summary> write all 1/1 regression value pairs to file </summary>
    procedure WriteAll_1_1_Files;
    
    /// <summary> write the results of all regression analysis to a file </summary>
    procedure CalcAllLinearRegressions;

    /// <summary> Initialise the pointers of all external variables to their corresponding entities </summary>
    function InitAllExternV: boolean;

    /// <summary> Method for checking if the model is finished </summary>
    procedure IsFinished; virtual;
    
    procedure CalcChiSq;
    /// calculation of sum of squared differences
    procedure ClearAllDataSeries;
    
    /// Optimization routine
    procedure MarquardOptimization(fn: string);
    /// Sensitivity analysis for single simulation run
    procedure CalcSensitivity;
    /// Sensitivity analysis for single simulation run
    procedure CalcSensitivityMultRun;
    /// Sensititvity of ChiSquare Values over 1 to several simulation runs
    procedure CalcChiSquareSensitivity;
    /// write some text file for documentation
    procedure write_documentation;
    
    /// Array property for convenient Access of Submodels, allows to access submodels by their index
    /// index is the index of the submodel in the list of submodels, starting with 0
    /// e.g. SubModel[0] returns the first submodel in the list of submodels
    /// SubModel[1] returns the second submodel in the list of submodels, etc. 
    /// useful for accessing submodels in a loop
    property SubModel[Index: Integer]: TSubmodel read getSubModel
      write setSubModel;
    
    /// <summary> property for the control file name </summary>
    property ReadIniOutputPath: boolean read fReadIniOutputPath write fReadIniOutputPath;

    {$IFNDEF NONVISUAL}

    /// method for showing and changing model during design time
    procedure DblClick; override;

    {$ENDIF}

  published

    // property Name:string read fName write fName; /// Name of Model
    property GM_ControlFile: string read Get_ControlFileFn
      write Set_ControlFileFN;
    property GM_SubModStrList: TStringList read SubModStrList
    { write SubModStrList };
    property ApplicationPath: TPath read FApplicationPath
      write FApplicationPath;
    property GM_OutPutPath: TPath read FOutputPath write FOutputPath;
    property GM_InPutPath: TPath read FInputPath write FInputPath;
    property GM_OutputFileName: string read fFNGlobalOutput write fFNGlobalOutput;
    property Separator: Char read FSeparatorChar write FSeparatorChar
      default ',';
    property TimeStep: real read FTimeStep write Set_TimeStep;
    property StartTime: TDateTime read FStartTime write Set_StartTime;
    property EndTime: TDateTime read FEndTime write Set_EndTime;
    property ChiSqr: real read fChiSqr write fChiSqr;
    property Reg_fn: string {TMyFileName} read FReg_FN write FReg_FN;
    property WriteResIni: boolean read fWriteResIni write fWriteResIni;
    property Docu_fn: string {TMyFileName} read fDocu_FN write fDocu_FN;
    property Docu_fn2: string {TMyFileName} read fDocu_FN2 write fDocu_FN2;
    property ModTime: TState read Time write Time;
    property LMOptions: TMarquardOptions read FLMOptions write FLMOptions;
    property SensOpt: TSensitivityOptions read FSensOptions write FSensOptions;
    property IniFileNames: TStringList read FIniFiles;
    property Title: string read FTitle write FTitle;
//    property ContOutput: TContOutput read FContOutput write FContOutput;
    property OptContOutput: TContOutput read FContOutput write FContOutput;
//    property FinalOutput: boolean read FFinalOutput write FFinalOutput;
    property MinLegalValue: real read FMinLegalValue write FMinLegalValue;
    /// smallest measurement value accepted in optimization
    property Str_SectionName_TimeInit: string read FStr_SectionName_TimeInit
      write FStr_SectionName_TimeInit;
    property Str_SectionName_FileNames: string read FStr_SectionName_FileNames
      write FStr_SectionName_FileNames;
    property Str_SectionName_SimOptions: string read FStr_SectionName_SimOptions
      write FStr_SectionName_SimOptions;
    property Str_SectionName_MeasurementFiles: string
      read FStr_SectionNameMeasurementFiles
      write FStr_SectionNameMeasurementFiles;
    property Str_SectionName_UpdateFiles: string
      read FStr_SectionNameUpdateFiles write FStr_SectionNameUpdateFiles;
    property Str_SectionName_OutPutFiles: string
      read FStr_SectionNameOutputFiles write FStr_SectionNameOutputFiles;
    property Str_SectionTopic_SimStart: string read FStr_SectionTopic_SimStart
      write FStr_SectionTopic_SimStart;
    property Str_SectionTopic_SimEnd: string read FStr_SectionTopic_SimEnd
      write FStr_SectionTopic_SimEnd;
    property Str_SectionTopic_TimeStep: string read FStr_SectionTopic_TimeStep
      write FStr_SectionTopic_TimeStep;
    property Str_SectionTopic_ContOutput: string read FStr_SectionTopic_ContOutput
      write FStr_SectionTopic_ContOutput;
    property Str_SectionTopic_StateIniFN: string
      read FStr_SectionTopic_StateIniFN write FStr_SectionTopic_StateIniFN;
    property Str_SectionTopic_ParamIniFN: string
      read FStr_SectionTopic_ParamIniFN write FStr_SectionTopic_ParamIniFN;
    property Str_SectionTopic_WeatherFileFN: string
      read FStr_SectionTopic_WeatherFileFN
      write FStr_SectionTopic_WeatherFileFN;
    property Str_SectionTopic_OptionIniFN: string
      read FStr_SectionTopic_OptionIniFN write FStr_SectionTopic_OptionIniFN;
    property Str_SectionTopic_OutputDir: string read FStr_SectionTopic_OutputDir
      write FStr_SectionTopic_OutputDir;
    property ReInitAfterRun: boolean read fReInitAfterRun write fReInitAfterRun;
    property ShowDateFormat: boolean read fShowDateFormat write fShowDateFormat;
 {$IFNDEF NONVISUAL}
    property Visible;
    property Parent;//: TWinControl read fParent; // write SetParent;
    property Canvas;
    property StatusBar: TStatusBar read fStatusBar write fStatusBar;
    property StatusBarOpt: TStatusBar read fStatusBarOpt write fStatusBarOpt;
    property OnDblclick;
 {$ENDIF}
  end;
  // end of Object TMod

  { * -----------------------------------------------------------------
    CLASS     TSubmodel
    ANCESTOR  TGraphicControl
    PURPOSE   Base class of all sub-models: Provides routines for
    initialization, input and ouput and integration
    ------------------------------------------------------------------ }

/// <summary> Base class of all sub-models. Provides methods for initialisation, input, output and integration. Acestor is 
/// TObject if compiled for command line application or from TGraphicControl if compiled for GUI application </summary>
{$IFDEF NONVISUAL}
  TSubmodel = class(TObject) // from TObject if nonvisual
{$ELSE}
  TSubmodel = class(TGraphicControl) // from TGraphicControl if visual
{$ENDIF}
  private
    /// Name of instance
    fName: string;
    /// Index of computation order
    FCompIndex: Integer;
    /// List of assimilated submodels
    fAssimilatedSubmodList: TStringList;
    /// List of update values
    fUpdateValueList: TStringList;
    /// List of Model Elements, i.e. State, Vars, Params, Externals, Consts
    fModelElementLists: TListsOf;
    /// flag for enabling debugging mode
    fDebugmodus: boolean;
    /// Option for writing output each time step
    fOptContOutput: TOption;
    /// Should output be written to file continously
    fWritecontinuouslyToFile: boolean;
    /// Option for writing final values output at end of simulation
    fOptFinalOutput: TOption;
    /// Should output be written to file finally
    fWriteFinallyToFile: boolean;

    {$IFNDEF NONVISUAL}
    /// Pointer to abstract Form for debugging
    fDebugForm: TFormDebugAbstract;
    {$ENDIF}
    /// Registrate a parameter
    procedure RegistrateParameter(Par: TPar); virtual;
    /// Registrate an option
    procedure RegistrateOption(Option: TOption); virtual;
    /// Registrate a variable
    procedure RegistrateVariable(Variable: Tvar); virtual;
    /// Registrate a state variable
    procedure RegistrateStateVar(State: TState); virtual;
    /// Registrate a constant
    procedure RegistrateConstant(Constant: Tvar); virtual;
    /// Registrate a submodel
    procedure RegistrateSubMod(SubModname: string; var Model: TMod); virtual;
    /// Clear data series
    procedure ClearDataSeries; virtual;
    procedure set_State(index: Integer; const State: TState); virtual;
    function get_State(index: Integer): TState;
    procedure set_Par(index: Integer; const Par: TPar);
    function Get_Par(index: Integer): TPar;
    procedure set_Var(index: Integer; const Variable: Tvar);
    function Get_Var(index: Integer): Tvar;
    procedure set_Const(index: Integer; const Constant: Tvar);
    function get_Const(index: Integer): Tvar;
    procedure set_Option(index: Integer; const Option: TOption);
    function get_Option(index: Integer): TOption;
    procedure set_ExternVar(index: Integer; const ExternVar: TExternV);
    function get_ExternVar(index: Integer): TExternV;
    /// Initialisation of state variables
    procedure InitStates(var GlobMod: TMod); virtual;
    /// Initialisation of parameters
    procedure InitParms(var GlobMod: TMod); virtual;
    /// Initialisation of variables
    procedure InitVars(var GlobMod: TMod); virtual;
    /// Initialisation of options
    procedure InitOptions(var GlobMod: TMod); virtual;
    /// Initialisation of output file names
    procedure InitOutputFileNames(var GlobMod: TMod); virtual;
    /// Initialisation of update file
    procedure InitUpdateFile(var GlobMod: TMod); virtual;
    /// Check for output
    procedure IsOutput(var IsOutput:boolean); virtual;
  protected
    function Get_GlobMod: TMod;
    procedure Set_GlobMod(Model: TMod); virtual;
    function UpdateValue(n: string): real;
  {$IFNDEF NONVISUAL}
   /// new Paint procedure
   procedure Paint; override; 
  {$ENDIF}
  public
   /// Name of instance
   submodname: string;
   /// Instance of class Tmod to which sub-model is linked
   GlobMod: TMod;
   /// List of state variables
   StateStrList: TStringList;
   /// List of parameters
   ParStrList: TStringList;
   /// List of variables
   VarStrList: TStringList;
   /// List of constants
   ConstStrList: TStringList;
   /// List of Options (saved as strings)
   OptionStrList: TStringList;
   /// List of external values
   ExternVStrList: TStringList;
   /// Ini-file with parameters
   ParIniF: TMyIniFile;
   /// Ini-file with initial values of state variables
   StateIniF: TMyIniFile;
   /// Ini-file with options
   OptionIniF: TMyIniFile;
   /// File variable for state output, now implemented as TStreamWriter
   f_state: TStreamWriter;
   // f_state: textfile;
   /// File variable for final state output, now implemented as TStreamWriter
   ffin_state: TStreamWriter;
   /// File variable for rate output, now implemented as TStreamWriter
   f_rate: TStreamWriter;
   /// File name for state output
   fn_state: string {TMyFileName};
   /// File name for final output of states
   fn_finalstate: string;
   /// File name for rate output
   fn_rate: string {TMyFileName};
   /// file with measured data
   FMeasValues: TTextFileH;
   /// second file with measured data, meant for input with different time resolution
   FMeasValues_2: TTextFileH;
   /// file with measured data for updating
   FUpdValues: TTextFileH;
   /// true if measurement data is available
   SomethingMeasured: boolean;
   /// true if data for updating is available
   DoUpdate: boolean;
   /// Time of next Update
   NextUpdate: double;
   /// List of measured data series
   DataList: TStringList;
   /// Check for inactivation
   IsActive: boolean;
//    WriteFinallyTofile: boolean;
   /// Should output be written to file finally
   ShowWarnings: boolean;
   /// show warnings during simulation
   GlobTime: TState;
   /// global time of simulation model

{$IFNDEF NONVISUAL}
    constructor Create(AOwner: TComponent); override; /// constructor if visual
{$ELSE}
    constructor create; /// constructor if nonvisual
{$ENDIF}
    procedure free;
    procedure BeforeDestruction; override;

    /// <summary> Method for creating and and initialising a TPar variable </summary>
    /// <param name="ParName"> Name of parameter </param>
    /// <param name="ParUnits"> Units of parameter </param>
    /// <param name="DefaultValue"> Default value of parameter </param>
    /// <param name="Par"> Parameter variable to be created </param>
    /// <param name="comm"> Comment/explanation </param>
    procedure ParCreate(ParName: string; ParUnits: string; DefaultValue: real;     /// method for creating and and initialising a TPar variable
      var Par: TPar; comm: string = ''); virtual;
    
    
    /// <summary> Method for creating and and initialising a TOption variable </summary>
    /// <param name="OptName"> Name of option </param>
    /// <param name="Defaultstring"> Default value of option </param>
    /// <param name="Option"> Option variable to be created </param>
    /// <param name="comm"> Comment/explanation </param>
    procedure OptCreate(OptName: string; Defaultstring: string;
      var Option: TOption; comm: string = ''); /// creation objects for options
    
    
    /// <summary> Method for creating and and initialising a TVar variable </summary>
    /// <param name="VarName"> Name string of variable 
    /// </param>
    /// <param name="VarUnits"> Units of variable </param>
    /// <param name="DefaultValue"> Default value of variable </param>
    /// <param name="ReadFromFile"> Flag for reading from ini file </param>
    /// <param name="Variable"> Variable to be created </param>
    /// <param name="comm"> Comment/explanation </param>
    /// <remarks>
    /// The created vars are also added to the corresponding stringlist TVarsStrList
    /// </remarks>
    procedure VarCreate(VarName: string; VarUnits: string; DefaultValue: real;
      ReadFromFile: boolean; var Variable: Tvar; comm: string = '');     /// method for creating and and initialising a TVar variable
    
    /// <summary> Method for creating and and initialising a TConst variable </summary>
    /// <param name="ConstName"> Name of constant </param>
    /// <param name="ConstUnits"> Units of constant </param>
    /// <param name="DefaultValue"> Default value of constant </param>
    /// <param name="ReadFromFile"> Flag for reading from ini file </param>
    /// <param name="Constant"> Constant to be created </param>
    /// <param name="comm"> Comment/explanation </param>
    procedure ConstCreate(ConstName: string; ConstUnits: string; DefaultValue: real;
      ReadFromFile: boolean; var Constant: TVar; comm: string = '');  /// method for creating and and initialising a Constant
    
    /// <summary> Method for creating and and initialising a TState variable </summary>
    /// <param name="StateName"> Name of state variable </param>
    /// <param name="StateUnits"> Units of state variable </param>
    /// <param name="DefaultValue"> Default value of state variable </param>
    /// <param name="ReadFromFile"> Flag for reading from file </param>
    /// <param name="State"> State variable to be created </param>
    /// <param name="comm"> Comment/explanation </param>
    procedure StateCreate(StateName: string; StateUnits: string;
      DefaultValue: real; ReadFromFile: boolean; var State: TState;
      comm: string = ''); virtual;   /// method for creating and initialising a TState variable
    
    /// <summary> Method for creating and and initialising a TExternV variable </summary>
    /// <param name="Name"> Name of external variable </param>
    /// <param name="Units"> Units of external variable </param>
    /// <param name="ExV"> Default value of external variable </param>
    /// <param name="ExternV"> External variable to be created </param>
    /// <param name="comm"> Comment/explanation </param>
    procedure ExternVcreate(Name, Units: string; ExV: TexValue;
      var ExternV: TExternV; comm: string = ''); virtual;     /// method for creating and  and initialising a TExternV variable
    
    /// <summary> Method for initialising external variables </summary>
    /// <param name="Model"> Model to which submodel is linked </param>
    /// <returns> True if successful </returns>
    function ExternVinit(Model: TMod): boolean; virtual;   /// setting pointers of external variables
    
    
    /// <summary> Method for creating all entities of the submodel </summary>
    /// <remarks>
    /// This method is called by the constructor of the submodel
    /// </remarks>
    procedure CreateAll; virtual;  /// Instantiates all objects
    
    /// <summary> Method for initialising the submodel </summary>
    procedure Init(var GlobMod: TMod); virtual; /// initialisation method
    
    /// <summary> Method for calculating the rates of change for every time step for the submodel </summary>
    procedure CalcRates; virtual;   /// rate calculation
    
    /// <summary> Method for integrating the submodel </summary>
    procedure Integrate; virtual;  /// integration of state variables
    
    /// <summary> Method for calculating the variables of the submodel </summary>
    procedure CalcVars; virtual;   /// calculation of rate variables
    
    /// <summary> Method for updating the submodel with measurement data </summary>
    procedure UpdateValues; virtual;     /// Update by measured values

    /// <summary> Method for writing the names of all state variables of the submodel to file </summary>
    procedure WriteStateName(var f: TStreamWriter; fn:string; IniFile: string = '');
//    procedure WriteStateName(var f: textfile; fn:string); virtual;

    /// <summary> Method for writing the names of all state variables of the submodel to
    /// the output file with final values </summary>
    procedure WriteFinalStateName(IniFile: string = ''); virtual;
//    procedure WriteRateName(var f: textfile; fn:string);
    
    /// <summary> Method for writing the names of all rate variables of the submodel to file </summary>
    procedure WriteRateName(var f: TStreamWriter; fn:string);

    /// <summary> Method for writing the state values  of the submodel to file </summary>
    procedure SaveState(var f: TStreamWriter; IniFile: string = ''); virtual;
    
    /// <summary> Method for writing the rate values of the submodel to file </summary>
    procedure SaveRate(var f: TStreamWriter); virtual;

    /// <summary> Method for writing the final state values of the submodel to file </summary>
    procedure SaveFinalState(var f: TStreamWriter; IniFile: string = ''); virtual;
    
    /// <summary> Method for closing all output files of the submodel</summary>
    procedure closeOutputfiles; virtual;

    /// <summary> Set the Isactive flag to true </summary>
    procedure activate; virtual;

    /// <summary> Set the Isactive flag to false </summary>
    procedure deactivate; virtual;
    
    /// <summary> Method for adding measured values to data serie </summary>
    procedure AddDataValueToDataSeries; virtual;   /// adding data Values to Data series

    /// <summary> Method for adding corresponding simulated values to data serie </summary>  
    procedure AddSimValueToDataSeries; virtual;   /// adding sim values to corresponding measured data
    procedure write_1_1_files; virtual;
    /// output of sim./meas. data pairs
    procedure CalcLinearRegressions;
    /// calculation of linear regression

    /// <summary> property to access state vars via index </summary>
    property StateVar[index: Integer]: TState read get_State write set_State; /// List of state variables
    
    /// <summary> property to access parameters via index </summary>
    property ParamVar[index: Integer]: TPar read Get_Par write set_Par;
    
    /// <summary> property to access variables via index </summary>
    property VarVar[index: Integer]: Tvar read Get_Var write set_Var;
    
    /// <summary> property to access constants via index </summary>
    property ConstVar[index: Integer]: Tvar read get_Const write set_Const;

    /// <summary> property to access options via index </summary>
    property Option[index: Integer]: TOption read get_Option write set_Option;
    
    /// <summary> property to access external variables via index </summary>
    property ExternVar[index: Integer]: TExternV read get_ExternVar
      write set_ExternVar;
  {$IFDEF NONVISUAL}
    property name:string read fName write fName;
  {$ENDIF}
   {$IFNDEF NONVISUAL}
    procedure DblClick; override;
   // procedure Click; override;
   {$ENDIF}

  published

    /// <summary> property to linkt the submodel to the main model component </summary>
    property SM_GlobMod: TMod read Get_GlobMod write Set_GlobMod;
    
    /// <summary> property to access the stringlist with external variables of the submodel </summary>
    property SM_ExternVStrList: TStringList read ExternVStrList
    { write Set_ExternVStrList };
    
    /// <summary> property to access the stringlist with variables of the submodel </summary>
    property SM_VarStrList: TStringList read VarStrList
    { write  Set_VarStrList };
    
    /// <summary> property to access the stringlist with constants of the submodel </summary>
    property SM_ConstStrList: TStringList read ConstStrList
    { write  Set_VarStrList };
    
    /// <summary> property to access the stringlist with parameters of the submodel </summary>
    property SM_ParStrList: TStringList read ParStrList
    { write Set_ParStrList };
    
    /// <summary> property to access the stringlist with state variables of the submodel </summary>
    property SM_StateStrList: TStringList read StateStrList
    { write Set_ParStrList };
 //   property OnClick;//:TNotifyEvent read fOnClick write fOnClick;
    
    /// <summary> property to access the compindex field of the submodel. This field 
    /// controls the execution order of the submodels </summary>
    property CompIndex: Integer read FCompIndex write FCompIndex;
    
    /// <summary> property to access the file name of the submodel rate output file </summary>
    property FN_ratefn: string {TMyFileName} read fn_rate write fn_rate;
    
    /// <summary> property to access the file name of the submodel state output file </summary>
    property FN_Statefn: string {TMyFileName} read fn_state write fn_state;
    
    /// <summary> property to access the file name of the measruement data for the submodel </summary>
    property MeasFile: TTextFileH read FMeasValues write FMeasValues;
    // property fn_MeasFile: TMyFileName read get_fnMeasFile write set_fnMeasFile;
    
    /// <summary> property to access the stringlist with assimilated sub models, i.e. submodels which are 
    /// linked to the submodel but not to the central model, this feature is not yet worked out </summary>
    property AssimilatedSubmodList: TStringList read fAssimilatedSubmodList
      write fAssimilatedSubmodList;
    
    /// <summary> property access the debug modus field of the sub model </summary>
    property DebugModus: boolean read fDebugmodus write fDebugmodus;

    /// <summary> property to access the flag for writing output continously </summary>
    property OptContOutput: boolean read fwritecontinuouslytofile
                                    write fwritecontinuouslytofile;
 //   property OnClick: TNotifyEvent read FOnClick write FOnClick;

   {$IFNDEF NONVISUAL}
    property Parent; //: TWinControl read fParent write SetParent;
    property Canvas; //
    property Visible; //
    property color default clgreen;
    property DebugForm: TFormDebugAbstract read fDebugForm write fDebugForm;
    property OnDblClick; // TNotifyEvent read FOnDblClick write FOnDblClick;
  {$ENDIF}


  end;

  // end of object TSubModel
  { * -----------------------------------------------------------------
    CLASS     TModEditor
    ANCESTOR  TComponentEditor
    PURPOSE   Exchanges data with TModelEdit form and
    starts designtime editing
    ------------------------------------------------------------------ }

  { [
    TModEditor = class(TcomponentEditor)
    procedure Edit; override;
    end;

    TSubModelEditor = class(TcomponentEditor)
    procedure Edit; override;
    end; }


function IsDesignTime: Boolean;

/// <summary> Registering the TMod and TSubModel components for designtime editing </summary>
procedure Register;


implementation

uses
{$IFNDEF NONVISUAL}
  vcl.Forms,
{$ENDIF}
  UMrqMinD, // HUME: routines for parameter estimation (Marquard method)
 System.TypInfo;

var
  DesignTime: Boolean;

function IsDesignTime: Boolean;
begin
  Result := DesignTime;
end;


constructor TMarquardOptions.create;
begin
  inherited create;
  FDivisor := 100; // Value which is needed for numerical
  // approximation of function derivative
  FIniLambda := 0.001; // Initial value of parameter Lambda
  FDefaultError := 0.1; // one may use an default error for weighting
  OptOption := optOnlyActIni;
end;

{ * *****************************************************************
  CLASS   TSensitivityOptions
  METHOD  create
  PURPOSE Create an TSensitivityOptions instance to save options for
  Sensitivity analysis used within the TMod class
  ****************************************************************** }

constructor TSensitivityOptions.create(Model: TMod);
var
  fn, dir: string;
begin
  inherited create;
  fMod := Model;
  FOutList := TStringList.create; // Variables selected for output
  FMinValue := 1.0; // minimum value during sensitivity analysis
  FMaxValue := 10.0; // maximum value during sensitivity analysis
  FSteps := 5; // Steps of sensitivity analysis
  FDPar := 1;
  fn := 'sens.dat';
  FSens_fn := fn;
{$IFDEF LINUX}
  dir := fMod.GM_OutPutPath + '/Sens/';
{$ELSE}
  dir := fMod.GM_OutPutPath + '\Sens\';
{$ENDIF}
  if SysUtils.ForceDirectories(dir) then
    FSens_fn := dir + fn;

end;

/// <summary>
/// CLASS   TSensitivityOptions
/// METHOD  SetMaxValue
/// PURPOSE Sets maximum value during sensitivity analysis
/// INPUT   const MAxValue: real
/// </summary>

procedure TSensitivityOptions.SetMAxValue(const MaxValue: real);
begin
  FMaxValue := MaxValue;
  FDPar := (FMaxValue - FMinValue) / (FSteps - 1);
end;

/// <summary>
/// CLASS   TSensitivityOptions
/// METHOD  SetMinValue
/// PURPOSE Sets minimum value during sensitivity analysis
/// INPUT   const MinValue: real
/// </summary>

procedure TSensitivityOptions.SetMinValue(const MinValue: real);
begin
  FMinValue := MinValue;
  FDPar := (FMaxValue - FMinValue) / (FSteps - 1);
end;

{ * *****************************************************************
  CLASS   TSensitivityOptions
  METHOD  SetSteps
  PURPOSE Sets number of steps of sensitivity analysis
  INPUT   const Steps: integer
  ****************************************************************** }

procedure TSensitivityOptions.SetSteps(const Steps: Integer);
begin
  FSteps := Steps;
  FDPar := (FMaxValue - FMinValue) / (FSteps - 1);
end;


{$IFNDEF NONVISUAL}

{ * *****************************************************************
  CLASS   TMod
  METHOD  Paint
  PURPOSE Method for showing object on the screen
  ****************************************************************** }


procedure TMod.Paint;
var
  X, Y, w, h, text_left, text_length: Integer;
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

{$ENDIF}


{ * *****************************************************************
  CLASS   TMod
  METHOD  Get_ControlFileFn
  PURPOSE Gets name of Control file (published for use in object inspector)
  OUTPUT  TMyFileName
  ****************************************************************** }

function TMod.Get_ControlFileFn: string;//TMyFileName;

var
//  FPropIniFile: TMyIniFile;
  fn, fn_ctrl, NewCtrlFileFN, prop_path: string;

  procedure GetControlFN_from_properties_ini(var ControlFileFN: string);

  begin
    begin
      // extract path of application
      prop_path := ExtractFilePath(ParamStr(0));

      // construct path of properties.ini
      fn := prop_path + 'properties.ini';
      // fn :=  'properties.ini';
      // fn := self.FPropIniFile.FileName;

      // check if properties.ini exists
      if fileexists(fn) then
      // if yes, read control file name from properties.ini
      begin
        if FPropIniFile = nil then
          FPropIniFile := TMyIniFile.create(fn, TEncoding.UTF8);
        // if FPropIniFile.FileName = '' then
        // FPropIniFile := TMyIniFile.create(fn, TEncoding.UTF8);
        NewCtrlFileFN := FPropIniFile.ReadString('Files', 'ControlFile', '');
      end;
    end;
    // if control file exists, return control file name
    if fileexists(NewCtrlFileFN) then
      ControlFileFN := NewCtrlFileFN else
      ControlFileFN := '';
  end;

 // procedure for retrieving control file name from user dialog
 procedure GetControlFN_from_Dialog(var ControlFileFN: string);

  begin
 {$IFNDEF NONVISUAL}
    LookForControlfile(NewCtrlFileFN);
{$ENDIF}
    if fileexists(ControlFileFN) then
    begin
      if FPropIniFile = nil then
        FPropIniFile := TMyIniFile.create(fn, TEncoding.UTF8);
      FPropIniFile.WriteString('Files', 'ControlFile', NewCtrlFileFN);
      FPropIniFile.UpdateFile;
    end;
    if fileexists(NewCtrlFileFN) then
      ControlFileFN := NewCtrlFileFN else
      ControlFileFN := '';
  end;

begin
 if not IsDesignTime then
  begin
    NewCtrlFileFN := ParamStr(1);
    if fileexists(NewCtrlFileFN) then
      fControlFileFn := NewCtrlFileFN
    else // No control file name from command line strings, then look in properties.ini
    begin
      GetControlFN_from_properties_ini(NewCtrlFileFN);
{$IFNDEF NONVISUAL}
      if not fileexists(NewCtrlFileFN) then
        GetControlFN_from_Dialog(NewCtrlFileFN);
{$ELSE}
      writeln('Control file does not exist!');
      exit;
{$ENDIF}
    end;
    Result := NewCtrlFileFN;
  end
else
  Result := '';
  if Result <> '' then begin
    self.fControlFileFn := NewCtrlFileFN;
    ReadOrCreateInifiles;
  end;
end;

/// <summary>
/// CLASS   TMod
/// METHOD  Set_ControlFileFN
/// PURPOSE Sets name of control Ini file (published for use in object inspector)
///         and reads or creates Ini files
/// <param name="NewCtrlFileFN">Name of control Ini file</param>
/// <remarks>
/// If no control files are existing they will be created
/// </remarks>
/// </summary>

procedure TMod.Set_ControlFileFN(newFN:string);

var
  FPropIniFile: TMyIniFile;
  fn, NewCtrlFileFN, prop_path: string;

begin
  fControlFileFn := newFN;
  if FIniFiles = NIL then
    FIniFiles := TStringList.create;
  ReadOrCreateInifiles;
  ActIniFile := TMyIniFile(FIniFiles.objects[0]);
  Init(ActIniFile);
end;


{ * *****************************************************************
  CLASS   TMod
  METHOD  setPropFromIniFile
  PURPOSE Set properties from Ini file for a submodel
  INPUT  strList: TStringList; List of all THumeNumEntity objects
         submodname: string; Name of submodel
  COMMENT
 ****************************************************************** }

/// <summary> Set the plot and output properties from Ini file for entities in a stringlist of a submodel </summary>
/// <param name="strList"> List of all THumeNumEntity objects </param>
/// <param name="submodname"> Name of submodel </param>
procedure TMod.setPropFromIniFile(strList: TStringList; submodname: string);

var
  i: Integer;
  entity: THumeNumEntity;
  path, fn : string;

begin
   //path :=  ExtractFilePath(ParamStr(0));
   //fn := path+ 'properties.ini';
   //fn := 'properties.ini';
   fn := self.FPropIniFile.FileName;
   if (FPropIniFile = nil) then
     FPropIniFile := TMyIniFile.create(fn,  TEncoding.UTF8);
//  FPropIniFile.UpdateFile;
  for i := 0 to strList.count - 1 do
  begin
    entity := THumeNumEntity(strList.objects[i]);
    with FPropIniFile do
    begin
      entity.PlotToGraph := ReadBool(submodname, entity.Name + '.PlotTograpH', entity.PlotToGraph);
      entity.WriteFinalValue := ReadBool(submodname, entity.Name + '.WriteFinalValue',
        entity.WriteFinalValue);
      entity.fGlobalOutput := ReadBool(submodname, entity.Name + '.GlobalOutput', entity.fGlobalOutput);
      entity.writeToFile := ReadBool(submodname, entity.Name + '.WriteToFile', entity.writeToFile);
      if entity is TPar then
        entity.writeToFile := false;
      entity.SelForSensOut := ReadBool(submodname, entity.Name + '.SelForSensOut',
        entity.SelForSensOut);
    end;
  end;
//  FPropIniFile.UpdateFile;
end;

procedure TMod.setSubModel(index: Integer; const SubModel: TSubmodel);
begin
  SubModStrList.objects[index] := SubModel;
end;

function TMod.getSubModel(index: Integer): TSubmodel;
begin
  Result := nil;
  if (index >= 0) and (index <= SubModStrList.count) then
    Result := TSubmodel(SubModStrList.objects[index])
end;

{ * *****************************************************************
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

{ * *****************************************************************
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

{ * *****************************************************************
  CLASS   TMod
  METHOD  Set_EndTime
  PURPOSE Sets end time of simulation
  INPUT   const EndTime: TDateTime
  ****************************************************************** }

procedure TMod.Set_EndTime(const EndTime: TDateTime);
begin
  FEndTime := EndTime;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  init
  PURPOSE Initialize state, parameter and weather files; init time
  settings; resort submodels
  ****************************************************************** }

/// <summary> Initialize state, parameter and weather files; init time settings; resort submodels </summary>
procedure TMod.Init;
var
  StateInifilefn: string;
  ParamIniFilefn: string;
  OptionInifilefn: string;
  WeatherFilefn: string;
  Inifn, dir, fn : string;
//  f: textFile;

begin
  // change to application directory

  Inifn := ExpandFileName(ActIniFile.FileName);
  if (ActIniFile <> nil) and FileExists( Inifn) then begin

  if (FApplicationPath <> '') and DirectoryExists(FApplicationPath) then
  begin
    chdir(self.FApplicationPath);
  end;
  if ReadIniOutputpath then
    GM_OutPutPath := ActIniFile.ReadString(Str_SectionName_FileNames,
      Str_SectionTopic_OutputDir, GM_OutPutPath);


  InitStateIniFile(StateInifilefn);
  InitParmIniFile(ParamIniFilefn);
  InitOptionsIniFile(OptionInifilefn);
  CreateIniFiles(OptionInifilefn, ParamIniFilefn, StateInifilefn);

  // read weather file name and create if not existing
  WeatherFilefn := ActIniFile.ReadString(Str_SectionName_FileNames,
    Str_SectionTopic_WeatherFileFN, '');

  if not FileExists(WeatherFilefn) then
  begin
  {$IFNDEF NONVISUAL}
    ShowMessage('WeatherFile ' + WeatherFilefn + ' does not exist');
    {$ELSE}
      writeln('WeatherFile ' + WeatherFilefn + ' does not exist');
  {$ENDIF}
    Exit;
  end;
  Self.WeatherFile.init(WeatherFilefn);
  //InitWeatherFile(WeatherFilefn);
  InitTime(IniFile);

  ModelEnd := false;
  SortSubMods;
  end
  else writeln('No ActIniFile');
  end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  InitAllsubMods
  PURPOSE Call inititalisation methods of sub-models
  ****************************************************************** }

/// <summary> Call inititalisation methods of sub-models </summary>
procedure TMod.InitAllSubMods;
var
  SubModIndex: Integer;
begin
  if self <> nil then
  begin
    for SubModIndex := 0 to self.SubModStrList.count - 1 do
    begin
      if SubModel[SubModIndex] <> nil then
        SubModel[SubModIndex].Init(self);
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  Create
  PURPOSE Calls inherited TGssraphicControl.create and  initializes
  properties, lists and files
  ****************************************************************** }

/// <summary> Calls inherited create and  initializes properties, lists and files </summary>
{$IFNDEF NONVISUAL}
constructor TMod.create(AOwner: TComponent);
{$ELSE}
constructor TMod.create;
{$ENDIF}

var
  i, NewIndex, OldIndex: Integer;
  subMod: TSubmodel;
  SubName: string;
begin

{$IFNDEF NONVISUAL}
  inherited create(AOwner);
{$ELSE}
  inherited create;
{$ENDIF}

//  self.ControlStyle.
  // initialize several properties, lists and files
  SubModStrList := TStringList.create;
  // SubModStrList.OwnsObjects := true;
  SubModStrList.Sorted := false;
  if FIniFiles = NIL then // maybe already created
    FIniFiles := TStringList.create;
  AllMeasVal := TMeasList.create('All', '[-]');
  SelMeasVal := TMeasList.create('Sel', '[-]');
  SelParList := TStringList.create;
  GlobalOutputList := TStringList.Create;
  FLMOptions := TMarquardOptions.create;
  SensOpt := TSensitivityOptions.create(self);

  Separator := ',';
  // initialize model time settings
  Time := TState.create('Time', '[d]', 0.0, 1.0, '');
  FTimeStep := 1.0;
  try
    FStartTime := StrToDateTime('01.01.1999');
    FEndTime := StrToDateTime('31.12.1999');
  except
{$IFNDEF NONVISUAL}
    ShowMessage
      ('Error on converting 01.01.1999 to date, please check date format')
{$ENDIF}
  end;
  fShowDateFormat := true;
  // initialize several properties, lists and files
{$IFNDEF NONVISUAL}
  Cursor := CrHandPoint;
{$ENDIF}
 //  fContOutput := true;
//  FinalOutput := false;
  ReInitAfterRun := true;
  fWriteResIni := true;
  // sets smallest measured value accepted in Optimization
  FMinLegalValue := 1E-999;
  // set section names (used in ini files)
  FStr_SectionNameMeasurementFiles := 'MeasurementFiles';
  FStr_SectionNameUpdateFiles := 'UpdateFiles';
  FStr_SectionNameOutputFiles := 'OutPutFiles';
  FStr_SectionName_FileNames := 'FileNames';
  FStr_SectionName_SimOptions := 'SimOptions';

  Str_SectionName_TimeInit := 'TimeInit';
  Str_SectionTopic_SimStart := 'Startzeit';
  Str_SectionTopic_SimEnd := 'Endzeit';
  Str_SectionTopic_TimeStep := 'TimeStep';
  Str_SectionTopic_ContOutput := 'ContOutput';
  Str_SectionTopic_ParamIniFN := 'ParamIniFN';
  FStr_SectionTopic_OptionIniFN := 'OptionsIniFN';
  Str_SectionTopic_WeatherFileFN := 'WeatherFileFN';
  Str_SectionTopic_StateIniFN := 'StateIniFN';
  Str_SectionTopic_OutputDir := 'OutPutDir';
  // self.Name := 'HUME';
  ReadIniOutputPath := true;
{$IFNDEF NONVISUAL}
  EXE_DIR := extractFiledir(Application.exename);
{$ENDIF}
  WeatherFile := TTextfileH.create;
//  if self.GM_ControlFile = '' then
//  begin
    // ShowMessage('No Controlfile specified');
    // halt;
    // does not work because controlfile is not specified from the property
    // at that moment
//  end;

{$IFNDEF NONVISUAL}
  SetPaintStyle;

{$ENDIF}

end;

procedure TMod.IsSubModelContOutput;

var
  subMod, Entity, IniFile: Integer;
  Element: TModelElements;

begin
  for subMod := SubModStrList.count - 1 downto 0 do
  begin
    SubModel[subMod].fWriteContinuouslyTofile := false;
    for Element := low(TModelElements) to high(TModelElements) do
    begin
      for Entity := SubModel[subMod].fModelElementLists[Element].count - 1 
      downto 0 do
      begin
        If THumeEntity(SubModel[subMod].fModelElementLists[Element].objects
          [Entity]).WriteToFile then
          SubModel[subMod].fWriteContinuouslyTofile := true;
      end;
    end;
  end;
end;

procedure TMod.Free;

var
  subMod, Entity, IniFile: Integer;
  Element: TModelElements;

begin
  for IniFile := 0 to FIniFiles.count - 1 do
    FIniFiles.objects[IniFile].Free;

  FIniFiles.Free;
  AllMeasVal.Free;
  SelMeasVal.Free;
  SelParList.Free;
  self.Time.Free;

  // SensOptions.Free;
  FLMOptions.Free;
  WeatherFile.Free;
  for subMod := SubModStrList.count - 1 downto 0 do
  begin
    for Element := low(TModelElements) to high(TModelElements) do
    begin
      for Entity := SubModel[subMod].fModelElementLists[Element].count -
        1 downto 0 do
      begin
        SubModel[subMod].fModelElementLists[Element].objects[Entity].Free;
        // Submodel[SubMod].fModelElementLists[Element].objects[Entity] := nil;
      end;
    end;
  end;
  for subMod := 0 to SubModStrList.count - 1 do
    // SubModel[SubMod].destroy;
    SubModStrList.Free;

  inherited;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  WriteAllNames
  PURPOSE For all submodels write state and rate names to output files
  ****************************************************************** }

/// <summary>
/// Call methods for calculation of variables of all active submodels
/// </summary>
procedure TMod.WriteAllNames;
var
  i: Integer;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    with SubModel[i] do
    begin
      if (fWriteContinuouslyTofile or (fContOutput = AllContoutput)) then
      begin
        WriteStateName(f_state, fn_state);
        WriteRateName(f_rate, fn_rate);
      end;
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  UpdateAll
  PURPOSE For each submodel do update using measured values
  ****************************************************************** }

procedure TMod.UpdateAll;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if SubModel[i].IsActive and SubModel[i].DoUpdate and
      (Time.v >= SubModel[i].NextUpdate) then
      SubModel[i].UpdateValues;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  SaveRates
  PURPOSE For each submodel save rates to output files
  ****************************************************************** }

procedure TMod.SaveRates;
var
  i: Integer;
  MakeContOutput : boolean;

  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active save rates to _rat.csv output file
    MakeContOutput := (SubModel[i].fWriteContinuouslyTofile or (fContOutput = AllContoutput));
    if (SubModel[i].IsActive) and (MakeContOutput) then
      SubModel[i].SaveRate(SubModel[i].f_rate);
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  SaveStates
  PURPOSE For each submodel save states to output files
  ****************************************************************** }

procedure TMod.SaveStates;
var
  i: Integer;
  MakeContOutput : boolean;
  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active save states to _dat.csv output file
    MakeContOutput := (SubModel[i].fWriteContinuouslyTofile or (fContOutput = AllContoutput));
    if (SubModel[i].IsActive) and  (MakecontOutput) then
 //     if SubModel[i].f_state <> NIL then
        SubModel[i].SaveState(SubModel[i].f_state);

  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  SaveFinalStates
  PURPOSE For all submodels write state values to final output file
  ****************************************************************** }

procedure TMod.SaveFinalStates;
var
  i: Integer;
  // subMod: TSubmodel;
  inif_fn: string;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // Submodel[i] := TSubmodel[i]el(Submodel[i]StrList.objects[i]);
    // if Submodel[i]el is active save final state values to _dat.csv output file
    if (SubModel[i].IsActive) and (SubModel[i].fWriteFinallyTofile) then
    begin
      inif_fn := extractfilename(SubModel[i].GlobMod.ActIniFile.Filename);
  //    inif_fn := GM_OutPutPath + '\' + inif_fn;
      SubModel[i].SaveFinalState(SubModel[i].ffin_state, inif_fn);
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  IntegrateAllSubModels
  PURPOSE For each submodel do integration
  ****************************************************************** }

procedure TMod.integrateAllSubModels;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  Time.v := Time.v + Time.c; // next time step
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active call its integration routine
    if SubModel[i].IsActive then
      SubModel[i].Integrate;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  InitAllExternV
  PURPOSE For each submodel initialize external variables (setting their pointers)
  ****************************************************************** }

function TMod.InitAllExternV: boolean;
var
  i: Integer;
  // subMod: TSubmodel;
  Success: boolean;
begin
  Success := true;

  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if external values exist initialize them (setting their pointers)
    if SubModel[i].ExternVStrList.count > 0 then
    begin
      Success := Success and SubModel[i].ExternVinit(self);
      if not Success then
        break;
    end;
  end;

  Result := Success;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  CloseAllFiles
  PURPOSE For each submodel close state and rate output file (_dat.csv/_rat.csv)
  ****************************************************************** }

procedure TMod.CloseAllFiles;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // close state and rate output files
    if ((SubModel[i].fWriteContinuouslyTofile) or (self.fContOutput=AllContoutput)) then
      SubModel[i].closeOutputfiles;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  CloseAllFinalFiles
  PURPOSE For each submodel close final state output files
  ****************************************************************** }

procedure TMod.CloseAllFinalFiles;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // close final state output file
    if SubModel[i].fWriteFinallyToFile then
    begin

      SubModel[i].ffin_state.Flush;
      SubModel[i].ffin_state.Close;
//      SubModel[i].ffin_state.FreeInstance;
//      SubModel[i].ffin_state := NIL;
    end;
    // close(SubModel[i].ffin_state);
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  CalcAllRates
  PURPOSE For each submodel calculate rates
  ****************************************************************** }

procedure TMod.CalcAllRates;

var
  i: Integer;
  // subMod: TSubmodel; 
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if SubModel[i].IsActive then
      SubModel[i].CalcRates;
  end;
end;

procedure TMod.CalcAllVars;
var
  i: Integer;
  // subMod: TSubmodel; 
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if SubModel[i].IsActive then
      SubModel[i].CalcVars;
  end;
end;


{ * *****************************************************************
  CLASS   TMod
  METHOD  AddAllSimValuestoDataSeries
  PURPOSE For each submodel add simulated values to corresponding measured data
  ****************************************************************** }

procedure TMod.AddAllSimValuestoDataSeries;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  for i := 0 to SubModStrList.count - 1 do
  begin // for all submodels do...
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // for each submodel add simulated values to corresponding measured data
    if SubModel[i].SomethingMeasured then
      SubModel[i].AddSimValueToDataSeries;
  end;
end;



procedure TMod.WriteAllFinalNames;
var
  i: Integer;
  dir :  string;
  // subMod: TSubmodel;
  // fn: string;
begin
  // for all submodels do...
for i := 0 to SubModStrList.count - 1 do begin
  with SubModel[i] do begin
    if SubModel[i].fWriteFinallyToFile then begin
          if GlobMod <> nil then begin
            SubModel[i].fn_finalstate := extractfilename(GlobMod.fControlFileFn);
            delete(SubModel[i].fn_finalstate, pos('.', fn_finalstate), 3);
            SubModel[i].fn_finalstate := fn_finalstate + '_' + SubModname;
          {$IFDEF LINUX}
            dir := GM_OutputPath + '/finalstate/';
          {$ELSE}
            dir := GM_OutputPath + '\finalstate\';
          {$ENDIF}
           if SysUtils.ForceDirectories(dir) then
           SubModel[i].fn_finalstate := dir + SubModel[i].fn_finalstate + '_dat.csv';
           SubModel[i].WriteFinalStateName(SubModel[i].fn_finalstate );
          end else
           SubModel[i].fn_finalstate := SubModel[i].fn_finalstate + '_dat.csv';
        // writes state names of specific submodel to _dat.csv file
//        WriteStateName(SubModel[i].ffin_state, 'IniFile');
      end;
    end;
  end;
end;


{ * *****************************************************************
  CLASS   TMod
  METHOD  ClearAllDataSeries
  PURPOSE For each submodel clear data pair series
  ****************************************************************** }

{ * *****************************************************************
  CLASS   TMod
  METHOD  ClearAllDataSeries
  PURPOSE For each submodel clear data pair series
  ****************************************************************** }
  


{ * *****************************************************************
  CLASS   TMod
  METHOD  ClearAllDataSeries
  PURPOSE For each submodel clear data pair series
  ****************************************************************** }


procedure TMod.InitAllDataSeries;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // if submodel is active calculate rates
    if SubModel[i].IsActive then
      SubModel[i].AddDataValueToDataSeries;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  Run
  PURPOSE Run method
  INPUT
  OUTPUT
  COMMENT
  ****************************************************************** }
// {$APPTYPE CONSOLE}

/// <summary> Run method, runs the model over the list of ini files </summary>
procedure TMod.run;
var
  i, j: Integer;
  fn, dir: string;
  statFile: textFile; // temporary lists for weather data handling
  path,
  globResFN,
  iniResFN,
  SelectionStr: string; // Name for "result file"
  globRes: TStreamWriter;
//    globRes: textfile;
    ActSubMod : TSubModel;
    Selndx : integer;

begin
  Get_ControlFileFn();
  if FPropIniFile = nil then
    FPropIniFile := TMemInifile.Create('properties.ini');
  SelectionStr := FPropIniFile.ReadString('ModelSettings', 'ContOutput', 'ContOutput');
  fContOutput :=  TContOutput(GetEnumValue(System.TypeInfo(TContOutput), SelectionStr));

  AllMeasVal.Clear;
  // For every submodel clear data pair series
  ClearAllDataSeries;
{$IFNDEF NONVISUAL}
  Check_GM_OutputPath;
{$ENDIF}
{$IFDEF LINUX}
  dir := GM_OutPutPath + '/' + 'statistics/';
{$ELSE}
  dir := GM_OutPutPath + '\' + 'statistics\';
{$ENDIF}
  if SysUtils.ForceDirectories(dir) then
    Reg_fn := dir + 'regression.dat'
  else
    Reg_fn := GM_OutPutPath + '\' + 'regression.dat';



{$IFDEF LINUX}
  GM_OutputFileName := GM_OutPutPath + '/' + stripextension(extractfilename( fControlFileFn)) + '_'+ 'GlobalOutput.csv';
{$ELSE}
  GM_OutputFileName := GM_OutPutPath + '\' + stripextension(extractfilename( fControlFileFn))+'_'+ 'GlobalOutput.csv';
{$ENDIF}



{$IFDEF NONVISUAL}

path :=  ExtractFilePath(ParamStr(0));
SetLength(path, Length(path) - 1);

{$IFDEF LINUX}
  path := path + '/';;
{$ELSE}
  path := path + '\';
{$ENDIF}
      for j := 0 to self.SubModStrList.Count - 1 do begin
        ActSubMod := TSubModel(SubModStrList.objects[j]);
        with ActSubMod do
        begin
          setPropFromIniFile(stateStrList, Name);
          setPropFromIniFile(VarStrList, Name);
          setPropFromIniFile(ExternVStrList, Name);
        end;
      end;
{$ENDIF}
   FPropInifile.UpdateFile;

   InitGlobalOutputList;
   WriteGlobalOutputNames(fFNGlobalOutput);

//  end;
  // Go through all INI files (listed in *.fn control file)
//  IsSubModelContOutput;
  // checks if there is anything to write continously for every submodel
  // fn name
  fn := StripExtension(extractfilename(fControlFileFn)) + '.stat';
  if DirectoryExists(GM_OutPutPath) then
  begin
{$IFDEF LINUX}
  dir := GM_OutPutPath + '/statistics/';
{$ELSE}
    dir := GM_OutPutPath + '\statistics\';
{$ENDIF}
    if SysUtils.ForceDirectories(dir) then
      fn := dir + fn;
  end
  else
  begin
{$IFDEF LINUX}
    dir := EXE_DIR + '/statistics/';
{$ELSE}
    dir := EXE_DIR + '\statistics\';
{$ENDIF}
    if SysUtils.ForceDirectories(dir) then
      fn := dir + fn;
  end;

  assignfile(statFile, fn);
  rewrite(statFile);
  CloseFile(statFile);

  if DirectoryExists(GM_OutPutPath) then
{$IFDEF LINUX}
    globResFN := GM_OutPutPath + '/' +
      StripExtension(extractfilename(fControlFileFn)) + '_res.hrl'
{$ELSE}
    globResFN := GM_OutPutPath + '\' +
      StripExtension(extractfilename(fControlFileFn)) + '_res.hrl'
{$ENDIF}
  else
{$IFDEF LINUX}
    globResFN := EXE_DIR + '/' + StripExtension
      (extractfilename(fControlFileFn)) + '_res.hrl';
{$ELSE}
    globResFN := EXE_DIR + '\' + StripExtension
      (extractfilename(fControlFileFn)) + '_res.hrl';
{$ENDIF}
  if (globRes = NIL) and (WriteResIni) then
    globRes := TStreamWriter.Create(globResFN, false, TEncoding.UTF8);
//  assignfile(globRes, globResFN);
//  rewrite(globRes);

    ActIniFile := TMyIniFile(FIniFiles.objects[0]);
    Init(ActIniFile); // Init for actual initialisation file
    InitAllSubMods; // Initialize all submodels
  // For all submodels write state names to final output file
  //  if FinalOutput then   begin
    WriteAllFinalNames;

  for i := 0 to FIniFiles.count - 1 do
  begin
    // Determine and initialize actual INI file

    ActIniFile := TMyIniFile(FIniFiles.objects[i]);
{$IFNDEF NONVISUAL}
    StatusBar.Panels.Items[0].Text := 'Running '+ ExtractFileName(ActIniFile.FileName)+
    ' ('+IntToStr(i+1)+'/'+IntToStr(FIniFiles.count)+')';
{$ELSE}
writeln('Running '+ ExtractFileName(ActIniFile.FileName)+
    ' ('+IntToStr(i+1)+'/'+IntToStr(FIniFiles.count)+')');
{$ENDIF}
    // showmessage(ActIniFile.FileName);    // for debugging

    Init(ActIniFile); // Init for actual initialisation file



    if self.WriteResIni then
    begin
{$IFDEF LINUX}
    iniResFN := GM_OutPutPath + '/' + StripExtension
      (extractfilename(ActIniFile.Filename)) + '_res.ini';
{$ELSE}
    iniResFN := GM_OutPutPath + '\' + StripExtension
      (extractfilename(ActIniFile.Filename)) + '_res.ini';
{$ENDIF}
	end;

    InitAllSubMods; // Initialize all submodels
    InitAllDataSeries;
    InitAllExternV; // Initialize all external variables

    // Set weather file pointer to actual time step
    WeatherFile.LocateFor(Time.Name, Time.v);
    // write names, state and rate values (if ContOutput true)

    if fContOutput <> NoContOutput then
    begin
      WriteAllNames;
      SaveStates;
      SaveRates;
    end;
    // central loop of TMod.Run
{$IFDEF LINUX}
  write('running model');
{$ENDIF}
    repeat
{$IFDEF LINUX}
      write('.');
{$ENDIF}
      CalcAllVars;
      // Variable calculation after integration from previous time step
      // rate calculation for all submodels
      CalcAllRates;
      // update values from measured data for all submodels if applicable
      UpdateAll;
      // integration for all submodels
      integrateAllSubModels;
      // add simulated values to corresponding measured data for all submodels
      AddAllSimValuestoDataSeries;

      // write state and rate values (if ContOutput)
      if fContOutput <> NoContOutput then
      begin
        SaveStates;
        SaveRates;
        SaveGlobalOutput(extractfilename(ActIniFile.Filename));
      end;
{$IFNDEF NONVISUAL}
      UpdateStatusbar;
{$ENDIF}
      IsFinished;
      // Sets TMod.ModelEnd to true if time counter passed endtime of model
      // step forward in weather file
      if Time.v >= WeatherFile.getIndexValue(0) then
      begin
        WeatherFile.NextLine;
        // weatherFile.CalcValues;
      end;
      // exit central loop if TMod.ModelEnd was flagged by IsFinished (see above)
    until ModelEnd;
{$IFDEF LINUX}
    writeln(' '+IntToStr(trunc(Time.v))+' -  finished');
{$ENDIF}
    if fWriteResIni then begin
      writeRes(iniResFN); // write parameters and filenames of simulation run to result file
        globRes.WriteLine(iniResFN);
 //     writeln(globRes, iniResFN);
    end;
    CalcAndSaveLinearRegressionSimMeas(FReg_FN, i);

    // showmessage(self.actinifile.filename);
    // close state and rate output files of all submodels
    if fContOutput <> NoContOutput then
      CloseAllFiles;
    // write state values to final output file for all submodels
//    if FinalOutput then
      SaveFinalStates;
    { ShowMessage(ActIniFile.FileName); }

    // DeleteFile(FReg_FN);    // f�r einzelberechnungen entfernen!
    // ClearAllDataSeries;     // f�r einzelberechnungen entfernen!
    // AllMeasVal.Clear;       // f�r einzelberechnungen entfernen!
	ParamInifile.UpdateFile;
    StateIniFile.UpdateFile;
    OptionIniFile.updatefile;
    FPropIniFile.UpdateFile

  end; // End of simulation run
 // globRes.Flush;
 // globRes.Close;
if (WriteResIni = true) then  begin
//  CloseFile(globRes);
  globRes.Flush;
  globRes.Close;
  globRes.Free;
end;

  CalcAllLinearRegressions; // for all submodels calculate linear regression
//  if FinalOutput then
  // close final state and rate output files of all submodels
    CloseAllFinalFiles;
  WriteAll_1_1_Files;
  // Output of simulated/measured data pairs to _1_1.csv files
  CalcChiSq; // Calculation of sum of squared differences
  // AllMeasVal.Clear;    // clear list of all measurement values
  f_GlobalOutput.Flush;
  f_GlobalOutput.close;
  f_GlobalOutput.Free;
  // closefile(f_GlobalOutput);

end;

{ * *****************************************************************
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

  if DirectoryExists(GM_OutPutPath) then
    chdir(GM_OutPutPath)
  else
    chdir(EXE_DIR);
  // clear list of all measurement values
  AllMeasVal.Clear;
  // For every submodel clear data pair series
  ClearAllDataSeries;
  // For all submodels write state names to final output file
//  if FinalOutput then
    WriteAllFinalNames;
  // initialize actual INI file
  { ActIniFile := TMyIniFile(FIniFiles.objects[ActInifileIndex]); }
  Init(ActIniFile);
  // Initialize all external variables
  InitAllExternV;
  // Initialize all submodels
  InitAllSubMods;
  InitAllDataSeries;
  // Set weather file pointer to actual time step
  // #TS#029: infinite loop depending on ModTime.Name
  WeatherFile.LocateFor(Time.Name, Time.v);
  // write names, state and rate values (if ContOutput true)
  if fContOutput <> NoContOutput then
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
    if fContOutput <> NoContOutput then
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
  if fContOutput <> NoContOutput then
    CloseAllFiles;
  // write state values to final output file for all submodels
//  if FinalOutput then
    SaveFinalStates;
  { ShowMessage(ActIniFile.FileName); }
  // close final state and rate output files of all submodels
//  if FinalOutput then
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

{ * *****************************************************************
  CLASS   TMod
  METHOD  CalcSensitivity
  PURPOSE Sensitivity analysis
  COMMENT Note partial code similarities (resp. redundancies) to TMod.Run
  ****************************************************************** }

procedure TMod.CalcSensitivity;

const
  cont_output = true;

var
  i, Iter: Integer;
  ActParameterValue: real;
  OldParameterValue: real;
  ActVar: Tvar;
  rep, Success: boolean;
  line, dir: string;
  SubModname, path: string;
  TempPar: TPar;
begin
  // flag false for first loop, flag true for second and following loops
  rep := false;
  // GetParameter(
  GetParameter(SensOpt.SelSenspar.Name, TempPar, SubModname, Success);
  OldParameterValue := FSensOptions.SelSenspar.v;
  // chdir(ExtractFiledir(application.ExeName));
  // chdir(EXE_DIR);
  // start with minimal value as actual value
  ActParameterValue := SensOpt.MinValue;
  // open output file for sensitivity analysis data (sens.dat)
  if ExtractFilePath(SensOpt.Sens_fn) = '' then
    // if fileexists(SensOpt.Sens_fn)= false then
    SensOpt.Sens_fn := GM_OutPutPath + '\' + SensOpt.Sens_fn;
  assignfile(SensOpt.Sens_f, SensOpt.Sens_fn);
  // reset(SensOpt.Sens_f);
{$I-}
  rewrite(SensOpt.Sens_f);
{$I+}
  if ioresult = 0 then
    // first row of output file: write name of selected sensitivity parameter
    write(SensOpt.Sens_f, SensOpt.SelSenspar.Name, Separator)
  else
{$IFNDEF NONVISUAL}
    ShowMessage(SysErrorMessage(GetLastError));
{$ENDIF}
  // first row of output file: write names of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(SensOpt.Sens_f, ActVar.Name, Separator);
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
    dir := GM_OutPutPath + '\sens\';
    if SysUtils.ForceDirectories(dir) then
    begin
      ActVar := Tvar(SensOpt.FOutList.objects[i]);
      SensOpt.fn_a[i] := dir + ActVar.Name + '_sens_a.csv';
      SensOpt.fn_b[i] := dir + ActVar.Name + '_sens_b.csv';
    end;
    assignfile(SensOpt.f_a[i], SensOpt.fn_a[i]);
    assignfile(SensOpt.f_b[i], SensOpt.fn_b[i]);
    rewrite(SensOpt.f_a[i]);
    rewrite(SensOpt.f_b[i]);
  end;
  if cont_output then
  begin
    WriteAllNames;
    SaveStates;
    SaveRates;
  end;

  // for each step of sensitivity analysis do...
  for Iter := 1 to SensOpt.Steps do
  begin
    ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.Name, //
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
    Init(ActIniFile);
    InitAllExternV;
    InitAllSubMods;
    InitAllDataSeries;
    // set parameter value according to step respectively loop count
    // first loop (see above): ActparameterValue := SensOpt.MinValue;
    // others (see below): ActParameterValue := ActParameterValue + SensOpt.DPar;
    SensOpt.SelSenspar.v := ActParameterValue;
    // ActParameterValue := SensOpt.SelSenspar.v;
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

      if cont_output then
      begin
        SaveStates;
        SaveRates;
      end;

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

    for i := 0 to SensOpt.FOutList.count - 1 do
    begin
      CloseFile(SensOpt.f_a[i]);
      CloseFile(SensOpt.f_b[i]);
    end;

    for i := 0 to SensOpt.FOutList.count - 1 do
    begin
      // if fileexists(sensOpt.fn_a[i]) then
      reset(SensOpt.f_a[i]);
      readln(SensOpt.f_a[i]);
      readln(SensOpt.f_a[i]);
      rewrite(SensOpt.f_b[i]);
      while not eof(SensOpt.f_a[i]) do
      begin
        readln(SensOpt.f_a[i], line);
        writeln(SensOpt.f_b[i], line);
      end;
      CloseFile(SensOpt.f_a[i]);
      CloseFile(SensOpt.f_b[i]);
    end;
    { SaveFinalValues;
      CopyAllSensFiles; }
  end;
  // close output file (sens.dat)
  if cont_output then
    CloseAllFiles;

  CloseFile(SensOpt.Sens_f);
  ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.Name, //
    OldParameterValue); //
  ParamInifile.UpdateFile; //
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
  i, j, Iter, inif: Integer;
  ActParameterValue: real;
  OldParameterValue: real;
  ActVar: Tvar;
  rep, Success: boolean;
  FinalSensFileName, ContSensFileName, ParamIniFilefn: string;
  SubModname: string;
  TempPar: TPar;
  FinalSensfile, ContSensFile: textFile;

begin
  // flag false for first loop, flag true for second and following loops
  rep := false;
  // GetParameter(
  GetParameter(SensOpt.SelSenspar.Name, TempPar, SubModname, Success);
  OldParameterValue := FSensOptions.SelSenspar.v;
  // chdir(ExtractFiledir(application.ExeName));
  chdir(EXE_DIR);

{$IFNDEF NONVISUAL}


  // make sure that output directory exists
  if (GM_OutPutPath <> '') and (not DirectoryExists(GM_OutPutPath)) then
  begin
    if MessageDlg('Output directory ' + GM_OutPutPath +
      'does not exist. Create directory?', mtConfirmation, [mbYes, mbNo], 0,
      mbYes) = mrYes then
    begin
      if not CreateDir(GM_OutPutPath) then
      begin
        ShowMessage('Can not create ' + GM_OutPutPath);
        Application.terminate;
      end;
    end
    else
      Application.terminate;
  end;
{$ENDIF}

  // prepare header for final output file
  // WriteAllFinalNames;

  // open output file for sensitivity analysis data (sens.dat)
  ContSensFileName := GM_OutPutPath + '\' + ContFileNameStr + '_' +
    StripExtension(extractfilename(fControlFileFn)) + '_' +
    SensOpt.SelSenspar.Name + '_' + '.csv';

  SensOpt.MultSens_fn_cont := ContSensFileName;

  FinalSensFileName := self.GM_OutPutPath + '\' + FinalFileNameStr + '_' +
    StripExtension(extractfilename(fControlFileFn)) + '_' +
    SensOpt.SelSenspar.Name + '_' + '.csv';
  SensOpt.MultSens_fn_final := FinalSensFileName;
  assignfile(ContSensFile, ContSensFileName);
  rewrite(ContSensFile);
  assignfile(FinalSensfile, FinalSensFileName);
  rewrite(FinalSensfile);

  // first row of output file: write IniFilename
  write(ContSensFile, 'IniFile', Separator);
  write(FinalSensfile, 'IniFile', Separator);

  // first row of output file: write name of selected sensitivity parameter
  write(ContSensFile, SensOpt.SelSenspar.Name, Separator);
  write(FinalSensfile, SensOpt.SelSenspar.Name, Separator);
  write(ContSensFile, 'Time', Separator);
  write(FinalSensfile, 'Time', Separator);

  // first row of output file: write names of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(ContSensFile, ActVar.Name, Separator);
    write(FinalSensfile, ActVar.Name, Separator);
  end;
  writeln(ContSensFile);
  writeln(FinalSensfile);

  // second row of output file: write units of selected sensitivity parameter

  write(ContSensFile, '[]', Separator, '[d]', Separator);
  write(FinalSensfile, '[]', Separator, '[d]', Separator);
  write(ContSensFile, SensOpt.SelSenspar.U, Separator);
  write(FinalSensfile, SensOpt.SelSenspar.U, Separator);

  // second row of output file: write units of selected variables
  for i := 0 to SensOpt.FOutList.count - 1 do
  begin
    // ActVar := Tvar(SensOpt.FOutList.objects[i]);
    write(ContSensFile, SensOpt.SelSenspar.U, Separator);
    write(FinalSensfile, SensOpt.SelSenspar.U, Separator);
  end;
  writeln(ContSensFile);
  writeln(FinalSensfile);

  // start with minimal value as actual value
  ActParameterValue := SensOpt.MinValue;

  // for each step of sensitivity analysis do...
  for Iter := 1 to SensOpt.Steps do
  begin
    for j := 0 to self.FIniFiles.count - 1 do
    begin
      ActIniFile := TMyIniFile(FIniFiles.objects[j]);
      ParamIniFilefn := ActIniFile.ReadString('FileNames', 'ParamIniFN', '');
      ParamInifile.Free;
      ParamInifile := TMyIniFile.create(ParamIniFilefn,  TEncoding.UTF8);
      ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.Name, //
        ActParameterValue); //
      ParamInifile.UpdateFile; //
    end;

    // prepare for simulation run, regarding the actual "step" of the
    // chosen sensitivity parameter

    for inif := 0 to FIniFiles.count - 1 do
    begin
      // Determine and initialize actual INI file
      ActIniFile := TMyIniFile(FIniFiles.objects[inif]);
      Init(ActIniFile);
      InitAllExternV;
      InitAllSubMods;
      // InitAllDataSeries;
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
        write(ContSensFile, StripExtension(extractfilename(ActIniFile.Filename)
          ), Separator);
        write(ContSensFile, ActParameterValue, Separator);
        write(ContSensFile, self.Time.v, Separator);
        for i := 0 to SensOpt.FOutList.count - 1 do
        begin
          ActVar := Tvar(SensOpt.FOutList.objects[i]);
          Write(ContSensFile, ActVar.v, Separator);
        end;
        writeln(ContSensFile);
        IsFinished;
        // step forward in weather file
        if Time.v >= WeatherFile.getIndexValue(0) then
        begin
          WeatherFile.NextLine;
          // weatherFile.CalcValues;
        end;
      until ModelEnd;

      write(FinalSensfile, StripExtension(extractfilename(ActIniFile.Filename)),
        Separator);
      write(FinalSensfile, ActParameterValue, Separator);
      write(FinalSensfile, self.Time.v, Separator);
      for i := 0 to SensOpt.FOutList.count - 1 do
      begin
        ActVar := Tvar(SensOpt.FOutList.objects[i]);
        Write(FinalSensfile, ActVar.v, Separator);
      end;
      writeln(FinalSensfile);
      rep := true;
    end; // End of Loop IniFiles
    ActParameterValue := ActParameterValue + SensOpt.DPar;
  end; // end of loop Parameter-Iteration
  CloseFile(ContSensFile);
  CloseFile(FinalSensfile);

  for j := 0 to self.FIniFiles.count - 1 do
  begin
    ActIniFile := TMyIniFile(FIniFiles.objects[j]);
    ParamIniFilefn := ActIniFile.ReadString('FileNames', 'ParamIniFN', '');
    ParamInifile.Free;
    ParamInifile := TMyIniFile.create(ParamIniFilefn,  TEncoding.UTF8);
    ParamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.Name, //
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
  i, j: Integer;
  s: string;//TMyFileName;
  subMod: TSubmodel;
  ActPar: TPar;
  ActOpt: TOption;
  MeasFile: TTextFileH;
begin
  assignfile(f, fn);
  rewrite(f);
  // write information on Simulation run
  writeln(f, '[SimulationRun]');
  writeln(f, 'iniFile=', ActIniFile.Filename);
  writeln(f, 'TimeOfRun=', DateTimeToStr(Now));
  writeln(f);
  // write Measurement Data Filenames
  writeln(f, '[MeasurementFiles]');
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    if subMod.MeasFile <> NIL then
    begin
      try
        MeasFile := subMod.MeasFile;
        if MeasFile.FName <> '' then
        begin
          s := MeasFile.FName;
          { // replace '\' by '/' for R
            for j := 1 to length(s) do if s[j]='\' then s[j]:='/'; }
          if subMod.SomethingMeasured then
            writeln(f, subMod.Name, '=', s);
        end;
      Except
        s := '';
        // on E : Exception do
        // ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
      end;
    end;
  end;
  writeln(f);
  // write State Output Filenames
  writeln(f, '[StateOutput]');
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    s := subMod.fn_state;
    { for j := 1 to length(s) do if s[j]='\' then s[j]:='/'; }
    writeln(f, subMod.Name, '=', s);
  end;
  writeln(f);
  // write State Output Filenames
  writeln(f, '[RateOutput]');
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    s := subMod.fn_rate;
    { for j := 1 to length(s) do if s[j]='\' then s[j]:='/'; }
    writeln(f, subMod.Name, '=', s);
  end;
  writeln(f);
  // write parameter list
  writeln(f, '[Paramters]');
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    for j := 0 to subMod.ParStrList.count - 1 do
    begin
      ActPar := TPar(subMod.ParStrList.objects[j]);
      writeln(f, subMod.Name + '.' + ActPar.Name, '=', FloatToStr(ActPar.v));
    end;
  end;
  writeln(f);
  // write options list
  writeln(f, '[Options]');
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    for j := 0 to subMod.OptionStrList.count - 1 do
    begin
      ActOpt := TOption(subMod.OptionStrList.objects[j]);
      writeln(f, subMod.Name + '.' + ActOpt.Name, '=', ActOpt.Option);
    end;
  end;
  CloseFile(f);
end;

procedure TMod.CalcChiSquareSensitivity;
var
  i, Iter: Integer;
  OldParameterValues: array [0 .. 1000] of real;
  ActIniFile, ActparamInifile: TMyIniFile;
  ActParamFileName: string;
  Success: boolean;
  SubModname: string;
  TempPar: TPar;
  SaveContOutput: TContOutput;
begin
  // flag false for first loop, flag true for second and following loops
  // rep := false;
  // TODO ActParamIniFile := TMyInifile.Create;

  if ExtractFilePath(SensOpt.Sens_fn) = '' then
    // if fileexists(SensOpt.Sens_fn)= false then
    SensOpt.Sens_fn := GM_OutPutPath + '\' + SensOpt.Sens_fn;
  assignfile(SensOpt.Sens_f, SensOpt.Sens_fn);

  GetParameter(SensOpt.SelSenspar.Name, TempPar, SubModname, Success);
  for i := 0 to self.IniFileNames.count - 1 do
  begin // read old Parameter values for saving
    ActIniFile := TMyIniFile(FIniFiles.objects[i]);
    ActParamFileName := ActIniFile.ReadString('FileNames', 'ParamIniFN',
      ActParamFileName);
    // ActParamInifile.FileName := ActParamfileName;
    ActparamInifile := TMyIniFile.create(ActParamFileName,  TEncoding.UTF8);
    ActparamInifile.CaseSensitive := false;
    OldParameterValues[i] := ActparamInifile.ReadFloat(SubModname,
      SensOpt.SelSenspar.Name, OldParameterValues[i]); // , success);
  end;
  // chdir(ExtractFiledir(application.ExeName));
  chdir(GM_OutPutPath);
  // start with minimal value as actual value
  SensOpt.SelSenspar.SelForOpt := true;
  SensOpt.SelSenspar.v := SensOpt.MinValue;
  // open output file for sensitivity analysis data (sens.dat)
  assignfile(SensOpt.Sens_f, SensOpt.Sens_fn);
  rewrite(SensOpt.Sens_f);
  // first row of output file: write name of selected sensitivity parameter
  write(SensOpt.Sens_f, SensOpt.SelSenspar.Name, Separator);
  // first row of output file: write names of selected variables
  writeln(SensOpt.Sens_f, 'n', Separator, 'SumSqr', Separator, 'slope',
    Separator, 'intercept', Separator, 'r2', Separator, 'RMSE',
    Separator, 'EF');
  // second row of output file: write units of selected sensitivity parameter
  write(SensOpt.Sens_f, SensOpt.SelSenspar.U, Separator);
  // second row of output file: write units of selected Parameter
  writeln(SensOpt.Sens_f, '[', SensOpt.SelSenspar.U, ']');
  // for each step of sensitivity analysis do...
  SaveContOutput := fContOutput;
  fContOutput := NoContOutput;
  for Iter := 1 to SensOpt.Steps do
  begin
    run;
    AllMeasVal.LeastSquares;
    // write parameter and variable values to output
    write(SensOpt.Sens_f, FloatToStrf(SensOpt.SelSenspar.v, ffgeneral, 8, 4),
      Separator);
    writeln(SensOpt.Sens_f, AllMeasVal.count, Separator, AllMeasVal.SumSqrdiff:8
      :4, Separator, AllMeasVal.slope:8:4, Separator, AllMeasVal.intercept:8:4,
      Separator, AllMeasVal.r2:8:4, Separator, AllMeasVal.RMSE:8:4, Separator,
      AllMeasVal.modellingefficiency:6:3);
    // increase value of sensitivity parameter by stepwidth
    SensOpt.SelSenspar.v := SensOpt.SelSenspar.v + SensOpt.DPar;
  end;
  fContOutput := SaveContOutput;
  SensOpt.SelSenspar.SelForOpt := false;
  // close output file (sens.dat)
  CloseFile(SensOpt.Sens_f);
  for i := 0 to IniFileNames.count - 1 do
  begin // rewrite old values to Ini-files
    ActIniFile := TMyIniFile(FIniFiles.objects[i]);
    ActParamFileName := ActIniFile.ReadString('FileNames', 'ParamIniFN',
      ActParamFileName);
    // TODO ActParamInifile.FileName := ActParamfileName;
    ActparamInifile := TMyIniFile.create(ActParamFileName,  TEncoding.UTF8);
    ActparamInifile.WriteFloat(SubModname, SensOpt.SelSenspar.Name,
      OldParameterValues[i]);
    ActparamInifile.UpdateFile;
    ActparamInifile.Free;
  end;

  AllMeasVal.Clear;
  // This TMod.CalcSensitivity method was called by the procedure
  // TFormSensOpt.ButtonRunSensClick from the unit UFormSelPar.
  // There, to present the sensitivity results, the string grid  will
  // now be actualized and displayed
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  ClearAllDataSeries
  PURPOSE For each submodel clear data pair series
  ****************************************************************** }

procedure TMod.ClearAllDataSeries;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // clear submodel's data pair series
    SubModel[i].ClearDataSeries;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  WriteAll_1_1_Files
  PURPOSE Output of simulated/measured data pairs to _1_1.csv files for all submodells
  ****************************************************************** }

procedure TMod.WriteAll_1_1_Files;
var
  i: Integer;
  // subMod: TSubmodel;
begin
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    // subMod := TSubmodel(SubModStrList.objects[i]);
    // Output of simulated/measured data pairs to _1_1.csv files
    if SubModel[i].SomethingMeasured then
      SubModel[i].write_1_1_files;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  CalcAllLinearRegressions
  PURPOSE For all submodels calculate linear regression statistics
  COMMENT Called by TMod.Run
  ****************************************************************** }

procedure TMod.CalcAllLinearRegressions;
var
  i, j: Integer;
  subMod: TSubmodel;
  DataSeries: TMeasList;
begin
  // create output file for regression data
  if Reg_fn = '' then
	{$IFDEF LINUX}
    Reg_fn := GM_OutPutPath + '/' + 'regression.dat';
    {$ELSE}
    Reg_fn := GM_OutPutPath + '\' + 'regression.dat';
    {$ENDIF}

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
    if { subMod.SomethingMeasured } subMod.DataList.count <> 0 then
    begin
      // calculate linear regression of submodel
      subMod.CalcLinearRegressions;
      // write regression data of submodel to output file
      for j := 0 to subMod.DataList.count - 1 do
      begin
        DataSeries := TMeasList(subMod.DataList.objects[j]);
        writeln(FRegFile, SubModStrList.Strings[i], Separator, DataSeries.Name,
          Separator, DataSeries.slope:6:4, Separator, DataSeries.se_slope:6:4,
          Separator, DataSeries.intercept:6:4, Separator,
          DataSeries.se_intercept:6:4, Separator, DataSeries.r2:6:4, Separator,
          DataSeries.count:6, Separator, DataSeries.RMSE:6:4, Separator,
          DataSeries.modellingefficiency:6:4, Separator, DataSeries.cd:6:4);
      end;
    end;
  end;
  // close output file for regression data
  CloseFile(FRegFile);
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  CalcChiSq
  PURPOSE Calculation of sum of squared differences
  INPUT
  OUTPUT
  COMMENT
  ****************************************************************** }

procedure TMod.CalcChiSq;
var
  i, j, k: Integer;
  subMod: TSubmodel;
  DataSeries: TMeasList;
  MeasRec: TmeasValue;
begin
  ChiSqr := 0;
  // for all submodels do...
  for i := 0 to SubModStrList.count - 1 do
  begin
    subMod := TSubmodel(SubModStrList.objects[i]);
    if subMod.SomethingMeasured then
    begin
      for j := 0 to subMod.DataList.count - 1 do
      begin
        DataSeries := TMeasList(subMod.DataList.objects[j]);
        // DataSeries.SelForOpt := true;
        if DataSeries.SelForOpt then
        begin
          for k := 0 to DataSeries.actPOs - 1 do
          begin
            MeasRec := TmeasValue(DataSeries.Items[k]);
            if (Abs(MeasRec.meas) > MinLegalValue) and
              (Abs(MeasRec.sim) > MinLegalValue) then
            begin
              // add measurement data points
              AllMeasVal.add(MeasRec);
              ChiSqr := ChiSqr + Sqr(MeasRec.sim - MeasRec.meas);
            end;
          end;
        end;
      end;
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  MarquardOptimization
  PURPOSE Optimization routine
  COMMENT Called by TFormOpt.StartBtnClick (unit UFormOpt)
  ****************************************************************** }

procedure TMod.MarquardOptimization(fn: string);
var
  NewPar, ErrPar: RealArrayMa;
  CorMat, Alpha: RealArrayMaByMa;
  Yfit: RealArrayNdata;
  NewChiSq: real;
  SaveContOutput : TContoutput;
begin
  // filename for output of optimization data
  // No file output during optimisation
  SaveContOutput := fContOutput;
  fContOutput := NoContOutput;
  mrq_fit(self, // this TMod instance
    true, // fit?
    true, // flag for output to file / screen
    fn, // output file name
    NewPar, ErrPar, // new parameter values and asymptotic error values
    NewChiSq, // Chi square value
    CorMat, Alpha, // Correlation matrix, alpha
    Yfit); // function results with otpimal parameters
  // Activate file output
  fContOutput := SaveContoutput;
  // Generate new output
  run; // wieso hier run? Das verstellt die actini Datei!
  // Das erneute Aufrufen ist notwendig, damit die Inhalte der der Ausgabedateien mit den
  // Parameterwerten im Array NewPar korrespondieren ...

end;

{ * *****************************************************************
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
  i, index: Integer;
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
      break;
    end;
  end;
end;

{ * *****************************************************************
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
  i, index: Integer;
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
      break;
    end;
  end;
end;

{ * *****************************************************************
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
  i, index: Integer;
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
      break;
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  IsFinished
  PURPOSE Sets TMod.ModelEnd to true if time counter passed endtime of model
  ****************************************************************** }

procedure TMod.IsFinished;
begin
  if Time.v >= FEndTime then
    ModelEnd := true;
end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  IsFinished
  PURPOSE Sets TMod.ModelEnd to true if time counter passed endtime of model
  ****************************************************************** }

procedure TMod.write_documentation;

var
  fn, fn2, path: string;
//  f, f2: textFile;
  f, f2: TStreamwriter;
  h, i, j, level: Integer;
  ClassRef: TClass;
  tab: Char;
  Entity: Integer;
  act_inifile: TMemIniFile;
  ModelElements, Element: TModelElements;
  NumbersOf: TNumbersOf;
  actSubMod: TSubmodel;
  actState: TState;
  actExtern: TExternV;
  ActVar: Tvar;
  ActPar: TPar;
  actOption: TOption;
  k, l, m: Integer;
  line, act_inifile_fn: string;

begin
  InitAllExternV;


  tab := chr(9);
  path := ExtractFilePath(fControlFileFn);
  fn := extractfilename(fControlFileFn);
  fn := 'Docu_' + ChangeFileExt(fn, '.txt');
  fn2 := 'Docu_' + ChangeFileExt(fn, '.csv');
  fn := path + fn;
  fn2 := path + fn2;
  self.fDocu_FN := fn;
  fDocu_FN2 := fn2;

  f := TStreamWriter.Create(fn, false, TEncoding.UTF8);
  f2 := TStreamWriter.Create(fn2, false, TEncoding.UTF8);

  f.Flush;
  f2.Flush;
//  rewrite(f);
//  rewrite(f2);

  f.writeline('Documentation of ' + fControlFileFn);
  f.writeline('');
  f.writeline('The model consists of '+ floattostr(self.SubModStrList.count) + ' SubModels');
  f.writeline('Name'+ tab+ tab+ tab+ tab+ 'Class'+ tab+ 'ParentClasses');
  for i := 0 to SubModStrList.count - 1 do
  begin
    SubModel[i].ClassParent;
    ClassRef := SubModel[i].ClassType;
    f.writeline( self.SubModel[i].Name);
    // while ClassRef.ClassName <> 'TSubmodel' do begin
    level := length(SubModel[i].Name);

{$IFNDEF NONVISUAL}
    while ClassRef <> TGraphicControl do
    begin
      for j := 1 to level do
        f.write(' ');
      f.writeline( '|____'+ ClassRef.ClassName);
      level := level + length(ClassRef.ClassName) + 5;
      ClassRef := ClassRef.ClassParent;
    end;
    f.writeline('');
{$ELSE}
    while ClassRef <> TObject do
    begin
      for j := 1 to level do
        f.write(' ');
      f.writeline( '|____' + ClassRef.ClassName);
      level := level + length(ClassRef.ClassName) + 5;
      ClassRef := ClassRef.ClassParent;
    end;
    f.writeline('');
{$ENDIF}
  end;

  for ModelElements := low(TModelElements) to high(TModelElements) do
    NumbersOf[ModelElements] := 0;

  for i := 0 to SubModStrList.count - 1 do
  begin
    for ModelElements := low(TModelElements) to high(TModelElements) do
    begin
      NumbersOf[ModelElements] := NumbersOf[ModelElements] + SubModel[i]
        .fModelElementLists[ModelElements].count;
    end;
  end;
  f.writeline('The Model has in total '+ floattostr(NumbersOf[States])+ ' State Variables');
  f.writeline('                       '+ floattostr(NumbersOf[Vars])+ ' Variables');
  f.writeline('                       '+ floattostr(NumbersOf[Params])+ ' Parameters');
  f.writeline( '                       '+ floattostr(NumbersOf[Consts])+ ' Constants');

  f.writeline('');
  f.writeline('');

  for i := 0 to SubModStrList.count - 1 do
  begin
    for ModelElements := low(TModelElements) to high(TModelElements) do
    begin
      f.writeline('The Submodel '+ SubModel[i].Name+ ' has in total '+
        floattostr(SubModel[i].fModelElementLists[ModelElements].count)+ ' '+
        ModelElementNames[ModelElements]);

    end;
    f.writeline('');
  end;

  f.writeline('');

  // write csv file with all modell entities ...
  f2.writeline('IniFile;Submodel;EntityType;EntityName;Units;Value;Option;Comment');
  for h := 0 to self.IniFileNames.count - 1 do
  begin

    ActIniFile := TMyIniFile(FIniFiles.objects[h]);
    Init(ActIniFile);
    InitAllSubMods;

    // act_inifile_fn := self.IniFileNames[h];
    // act_inifile := TMemInifile.Create(act_inifile_fn);
    // self.Init(act_inifile);
    for i := 0 to SubModStrList.count - 1 do
    begin
      actSubMod := TSubmodel(SubModStrList.objects[i]);

      for j := 0 to actSubMod.StateStrList.count - 1 do
      begin
        actState := TState(actSubMod.StateStrList.objects[j]);
        line := self.IniFileNames[h] + ';' + SubModel[i].Name + ';';
        line := line + 'State' + ';' + actState.Name + ';' + actState.U + ';' +
          FloatToStr(actState.v) + ';' + 'NA' + ';' + actState.Comment;
        f2.writeline(line);
      end;
      for j := 0 to actSubMod.VarStrList.count - 1 do
      begin
        ActVar := Tvar(actSubMod.VarStrList.objects[j]);
        line := self.IniFileNames[h] + ';' + SubModel[i].Name + ';';
        line := line + 'Variable' + ';' + ActVar.Name + ';' + ActVar.U + ';' +
          FloatToStr(ActVar.v) + ';' + 'NA' + ';' + ActVar.Comment;
        f2.writeline( line);
      end;
      for k := 0 to actSubMod.ParStrList.count - 1 do
      begin
        ActPar := TPar(actSubMod.ParStrList.objects[k]);
        line := self.IniFileNames[h] + ';' + SubModel[i].Name + ';';
        line := line + 'Parameter' + ';' + ActPar.Name + ';' + ActPar.U + ';' +
          FloatToStr(ActPar.v) + ';' + 'NA' + ';' + ActPar.Comment;
        f2.writeline(line);
      end;
      for m := 0 to actSubMod.ExternVStrList.count - 1 do
      begin
        actExtern := TExternV(actSubMod.ExternVStrList.objects[m]);
        line := self.IniFileNames[h] + ';' + SubModel[i].Name + ';';
        line := line + 'ExternalValue' + ';' + ActExtern.Name + ';' + ActExtern.U + ';' +
          'NA' + ';' + ActExtern.Source + ';' + ActExtern.Comment;
        f2.writeline(line);
      end;
      for l := 0 to actSubMod.OptionStrList.count - 1 do
      begin
        actOption := TOption(actSubMod.OptionStrList.objects[l]);
        line := self.IniFileNames[h] + ';' + SubModel[i].Name + ';';
        line := line + 'Option' + ';' + actOption.Name + ';' + ' NA;' + 'NA' +
          ';' + actOption.Option + ';' + actOption.Comment;
        f2.writeline(line);
      end;
    end;
    // fModelElementLists[Element].objects[Entity].;
    // Submodel[SubMod].fModelElementLists[Element].objects[Entity] := nil;
    // writeln(f, line);
    // freeandnil(actIniFile);
  end;

  // Writeln(f, SubModel[i].name, ';',
  // ModelElementNames[ModelElements],';',
  // SubModel[i].fModelElementLists[ModelElements].ClassName,';')
  f.writeline('');

  f.Flush;
  f.Close;
  f2.Flush;
  f2.Close;
//  CloseFile(f);
//  CloseFile(f2);
end;

{$IFNDEF NONVISUAL}
procedure TMod.SetPaintStyle;
begin
  Width := 80;
  Height := 30;
  Canvas.Pen.color := CLTeal;
  // CLWhite;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Width := 2;
  Canvas.Brush.color := clred;
  Canvas.Brush.Style := bsSolid;
  Canvas.Font.Size := 14;
end;
{$ENDIF}


procedure TMod.InitWeatherFile(WeatherFilefn: string);
var
  TempString: TStringList;
begin
  // init weather data file again (?)
  TempString := TStringList.create;
  // Treue
  if FileExists(WeatherFilefn) then
  begin
    // WeatherFile.init(WeatherFileFN);
    WeatherFile.Free;
    WeatherFile.init(WeatherFilefn);
    // TempString := TStringList.Create; // Treue
    TempString.CommaText := WeatherFile.GetFirstLine;
    // Treue
    FirstWeatherData := round(StrToFloat(TempString.Strings[0]));
    // Treue
    // TempString := TStringList.Create; // Treue
    TempString.CommaText := WeatherFile.GetLastLine;
    // Treue
    LastWeatherData := round(StrToFloat(TempString.Strings[0]));
    // Treue
    WeatherFile.GoTop;
  end;
  TempString.Free;
end;

procedure TMod.ReadOrCreateInifiles;
var
  NewFile: boolean;
  act_IniFn: string;
  NewInifile: TMyIniFile;
  ControlFile:TextFile;
  ndx : integer;
  gFile     : TStreamReader;
  gLine     : string;

begin
  // go through list of all Ini files specified in control file
  if fileexists(fControlFileFn) then
  begin
    gFile := TStreamReader.create(fControlFileFn, TEncoding.UTF8, true);
    FIniFiles.Clear;
    // assignfile(ControlFile, fControlFileFn);
    // reset(ControlFile);
    // while not eof(ControlFile) do
    while not gFile.EndOfStream do
    begin
      // open or create next Ini file and add to Ini file list of TMod
      NewFile := false;
      // readln(ControlFile, act_IniFn);
      act_IniFn := gFile.ReadLine;
      if trim(act_IniFn) = '' then
        continue;
      if trim(act_IniFn)[1] = '#' then
        continue;
      if fileexists(act_IniFn) then
      begin
        if not FIniFiles.Find(act_IniFn, ndx) then
          NewInifile := TMyIniFile.create(act_IniFn, TEncoding.UTF8);
        FIniFiles.AddObject(act_IniFn, NewInifile);
      end
      else
      begin
        NewFile := true;
        NewInifile := TMyIniFile.create(act_IniFn, TEncoding.UTF8);
        with NewInifile do
        begin
          CaseSensitive := false;
          FIniFiles.AddObject(FileName, NewInifile);
          // if Ini file is newly created put some default values in it
          if NewFile then
          begin
            WriteFloat(Str_SectionName_TimeInit, Str_SectionTopic_SimStart, 0);
            WriteFloat(Str_SectionName_TimeInit, Str_SectionTopic_SimEnd, 100);
            WriteFloat(Str_SectionName_TimeInit, Str_SectionTopic_TimeStep, 1);
            WriteString(Str_SectionName_FileNames, Str_SectionTopic_StateIniFN,
              GetCurrentDir + '\State.ini');
            WriteString(Str_SectionName_FileNames, Str_SectionTopic_ParamIniFN,
              GetCurrentDir + '\Parameters_x.ini');
            NewInifile.UpDateFile;
          end;
        end;
      end;
    end;
    // CloseFile(ControlFile);
    gFile.free;
  end else begin
{$IFNDEF NONVISUAL}
   showmessage('No ControlFile specified');
//   Application.Terminate;
   halt;
{$ELSE}
   writeln('No ControlFile specified');
   //Application.Terminate;
{$ENDIF}

  end;
end;

{$IFNDEF NONVISUAL}
procedure TMod.LookForControlfile(var ControlFileFN: string);
var
  DlgFileOpen: TOpenDialog;

begin
  begin
    DlgFileOpen := TOpenDialog.create(Application);
    with DlgFileOpen do
    begin
      Filter := 'Controlfiles {*.fn)|*.fn';
      Title := 'Open Control File';
      DefaultExt := 'fn';
      Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
      if Execute then
      begin
        if fileexists(Filename) then
          ControlFileFN := FileName
        else
          ControlFileFN := '';
        DlgFileOpen.free;
      end;
    end;
  end;
end;
{$ENDIF}


procedure TMod.CalcAndSaveLinearRegressionSimMeas(fn: string; i: Integer);
var
  strlist_act: TStringList;
  strlist: TStringList;
begin
 { strlist := TStringList.create;
  if fileexists(fn) then begin
    strlist.loadFromFile(fn);
    strlist.add('');
    strlist.add('');
  end;
  strlist.add(FIniFiles[i]);
  strlist.add('');
  strlist_act := TStringList.create;  }
  // for all submodels calculate linear regression
  CalcAllLinearRegressions;

 { try
    if FileExists(Reg_fn) then
      strlist_act.loadFromFile(Reg_fn);
      strlist.addstrings(strlist_act);
      strlist.savetofile(fn);
      strlist.Free;
     strlist_act.Free;
  finally

  end;  }
end;

{$IFNDEF NONVISUAL}
procedure TMod.UpdateStatusbar;
begin
  if StatusBar <> nil then
  begin
    if ShowDateFormat then
      StatusBar.Panels.Items[1].text := ' Time: ' +
        DateTimeToStr( { FloatToDateTime } (Time.v))
    else
      StatusBar.Panels.Items[1].text := ' Time: ' +
        FloatToStrf(Time.v, ffgeneral, 6, 1);
    StatusBar.Repaint;
  end;
end;

{$ENDIF}


{$IFNDEF NONVISUAL}
procedure TMod.Check_GM_OutputPath;
begin
  // make sure that output directory exists
  if (GM_OutPutPath <> '') and (not DirectoryExists(GM_OutPutPath)) then
  begin
    if MessageDlg('Output directory ' + GM_OutPutPath +
      'does not exist. Create directory?', mtConfirmation, [mbYes, mbNo], 0,
      mbYes) = mrYes then
    begin
      if not CreateDir(GM_OutPutPath) then
      begin
        ShowMessage('Can not create ' + GM_OutPutPath);
        Application.terminate;
      end;
    end
    else
      Application.terminate;
  end;
end;

{$ENDIF}


procedure TMod.InitOptionsIniFile(var OptionInifilefn: string);

var
  f: textFile;
begin
  // read Option Ini file name and create if not existing
  OptionInifilefn := ActIniFile.ReadString(Str_SectionName_FileNames,
    FStr_SectionTopic_OptionIniFN, '');
  if not FileExists(OptionInifilefn) then
  begin
  //  if OptionInifilefn = '' then
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
end;

procedure TMod.InitParmIniFile(var ParamIniFilefn: string);

var
  f: textFile;
begin
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
end;

procedure TMod.InitStateIniFile(var StateInifilefn: string);

var
  f: textFile;
begin
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
end;

procedure TMod.InitTime(IniFile: TMyIniFile);
begin
  // init time settings
  with IniFile do
  begin
    FStartTime := ReadFloat(Str_SectionName_TimeInit,
      Str_SectionTopic_SimStart, 0);
    FEndTime := ReadFloat(Str_SectionName_TimeInit,
      Str_SectionTopic_SimEnd, 365);
    TimeStep := ReadFloat(Str_SectionName_TimeInit,
      Str_SectionTopic_TimeStep, 1);
  end;
  if Time = nil then
    Time := TState.create('Time', '[d]', FStartTime, TimeStep, '')
  else
  begin
    Time.v := FStartTime;
    Time.c := TimeStep;
  end;
end;

procedure TMod.SortSubMods;
var
  j: Integer;
  i: Integer;
begin
  // resort string list of submodels
  // using bubblesort algorithm (corrected UB 08.07.2013)
  for j := SubModStrList.count - 2 downto 0 do
    for i := 0 to j do
      if SubModel[i].CompIndex > SubModel[i + 1].CompIndex then
        SubModStrList.Exchange(i, i + 1);
end;

procedure TMod.CreateIniFiles(OptionInifilefn: string; ParamIniFilefn: string;
  StateInifilefn: string);
begin
  { if not DirectoryExists(FOutputPath) then
    begin
    ShowMessage('Outputdirectory ' + FOutputPath + ' does not exist');
    Exit;
    end; }
  // init weather data file
  // if fileExists(WeatherFilefn) then
  // WeatherFile.Init(WeatherFileFN);
  StateIniFile.Free;
  StateIniFile := TMyIniFile.create(StateInifilefn,  TEncoding.UTF8);
  StateIniFile.CaseSensitive := false;
  ParamInifile.Free;
  ParamInifile := TMyIniFile.create(ParamIniFilefn,  TEncoding.UTF8);
  ParamInifile.CaseSensitive := false;
  OptionIniFile.Free;
  OptionIniFile := TMyIniFile.create(OptionInifilefn,  TEncoding.UTF8);
  OptionIniFile.CaseSensitive := false;
end;

{ * *****************************************************************
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

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  Set_GlobMod
  PURPOSE Initiates submodel according to "global" model (TMod instance)
  INPUT   Model: TMod
  ****************************************************************** }

procedure TSubmodel.Set_GlobMod(Model: TMod);
var
  SubModIndex: Integer;
  dir : string;
begin
  SubModname := Name;
  GlobMod := Model;
{$IFNDEF NONVISUAL}
  if Model.Parent <> nil then
    Parent := Model.Parent;
  Canvas.Brush.color := clgreen;
  Canvas.Font.color := clyellow;
  self.Repaint;
{$ENDIF}
{$IFDEF LINUX}
  dir := GlobMod.FOutputPath + '/rate/';
{$ELSE}
  dir := GlobMod.FOutputPath + '\rate\';
{$ENDIF}
  if SysUtils.ForceDirectories(dir) then
    fn_rate := dir + Name + '_rat.csv'
  else fn_rate := Name + '_rat.csv';
{$IFDEF LINUX}
  dir := GlobMod.FOutputPath + '/state/';
{$ELSE}
  dir := GlobMod.FOutputPath + '\state\';
{$ENDIF}
  if SysUtils.ForceDirectories(dir) then
    fn_state := dir + Name + '_dat.csv'
  else
    fn_state := Name + '_dat.csv';
  ParIniF := GlobMod.ParamInifile;

  StateIniF := GlobMod.StateIniFile;
  OptionIniF := GlobMod.OptionIniFile;
  GlobTime := GlobMod.Time;
  RegistrateSubMod(SubModname, GlobMod);
  SubModIndex := GlobMod.SubModStrList.indexof(Name);
  if CompIndex = -1 then
    CompIndex := SubModIndex;
end;

{ * *****************************************************************
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

procedure TSubmodel.set_State(index: Integer; const State: TState);
begin
  StateStrList.objects[index] := State;
end;

function TSubmodel.get_State(index: Integer): TState;
begin
  if (index > -1) and (index <= StateStrList.count) then
    Result := TState(StateStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Par(index: Integer; const Par: TPar);
begin
  ParStrList.objects[index] := Par;
end;

function TSubmodel.Get_Par(index: Integer): TPar;
begin
  if (index > -1) and (index <= ParStrList.count) then
    Result := TPar(ParStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Var(index: Integer; const Variable: Tvar);
begin
  ParStrList.objects[index] := Variable;
end;

function TSubmodel.Get_Var(index: Integer): Tvar;
begin
  if (index > -1) and (index <= VarStrList.count) then
    Result := Tvar(VarStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Const(index: Integer; const Constant: Tvar);
begin
  ConstStrList.objects[index] := Constant;
end;

function TSubmodel.get_Const(index: Integer): Tvar;
begin
  if (index > -1) and (index <= ConstStrList.count) then
    Result := Tvar(ConstStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_Option(index: Integer; const Option: TOption);
begin
  OptionStrList.objects[index] := Option;
end;

function TSubmodel.get_Option(index: Integer): TOption;
begin
  if (index > -1) and (index <= OptionStrList.count) then
    Result := TOption(OptionStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

procedure TSubmodel.set_ExternVar(index: Integer; const ExternVar: TExternV);
begin
  ExternVStrList.objects[index] := ExternVar;
end;

function TSubmodel.get_ExternVar(index: Integer): TExternV;
begin
  if (index > -1) and (index <= ExternVStrList.count) then
    Result := TExternV(ExternVStrList.objects[index])
  else
  begin
    Result := nil;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  Create
  PURPOSE Creates TSubModel according to TComponent.create
  INPUT   AOwner: TComponent
  COMMENT The TSubmodel class is derived from the TGraphicControl class
  ****************************************************************** }

{$IFNDEF NONVISUAL}
constructor TSubmodel.create(AOwner: TComponent);
{$ELSE}
constructor TSubmodel.create;
{$ENDIF}


begin
{$IFNDEF NONVISUAL}
  inherited create(AOwner);
  color := clgreen;
  Canvas.Brush.color := clgreen;
  Canvas.Font.color := clyellow;
  Canvas.Font.Size := 14;
  ControlStyle := ControlStyle + [csReplicatable];
  Width := 100;
  Height := 50;
  Canvas.Pen.color := clblack;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Width := 2;
  Canvas.Brush.Style := bsSolid;
  Cursor := CrHandPoint;
{$ELSE}
  inherited create;
{$ENDIF}
  // Initiates lists for state variables, parameters, external values and measured data series
  SubModname := Name;
  fWriteContinuouslyTofile := true;
  fWriteFinallyTofile := true;
  StateStrList := TStringList.create;
  // StateStrList.OwnsObjects := true;
  fModelElementLists[States] := StateStrList;
  StateStrList.Sorted := true;
  // StateStrlist.Duplicates := dupignore;
  ParStrList := TStringList.create;
  // ParStrList.OwnsObjects := true;
  fModelElementLists[Params] := ParStrList;
  ParStrList.Sorted := true;
  // ParStrList.Duplicates := dupignore;
  // adding duplicates to the sorted list will trigger an LListError exception
  ExternVStrList := TStringList.create;
  // ExternVStrList.OwnsObjects := true;
  fModelElementLists[Externals] := ExternVStrList;
  ExternVStrList.Sorted := true;
  ExternVStrList.Duplicates := dupAccept;
  VarStrList := TStringList.create;
  // VarStrList.OwnsObjects := true;
  fModelElementLists[Vars] := VarStrList;
  VarStrList.Sorted := true;
  VarStrList.Duplicates := dupignore;
  ConstStrList := TStringList.create;
  // ConstStrList.OwnsObjects := true;
  fModelElementLists[Consts] := ConstStrList;
  ConstStrList.Sorted := true;
  ConstStrList.Duplicates := dupignore;
  OptionStrList := TStringList.create;
  // OptionStrList.OwnsObjects := true;
  OptionStrList.Sorted := true;
  OptionStrList.Duplicates := dupignore;
  fAssimilatedSubmodList := TStringList.create;
  fAssimilatedSubmodList.Sorted := true;
  fAssimilatedSubmodList.Duplicates := dupignore;
  DataList := TStringList.create; // List of measured data series
  // calls TGraphicControl.activate (virtual)
  activate;
  CompIndex := -1;
  FMeasValues := TTextFileH.create;
  FUpdValues := TTextFileH.create;
//  f_state := TStreamwriter.c
  //FMeasValues := NIL;
  // globalmod wird erst nach create gesetzt!

  CreateAll;

end;

procedure TSubmodel.free;
var
  Element: TModelElements;
  Entity, Option: Integer;

begin
  for Element := low(TModelElements) to high(TModelElements) do
  begin
    for Entity := fModelElementLists[Element].count - 1 downto 0 do
    begin
      fModelElementLists[Element].objects[Entity].Free;
      // Submodel[SubMod].fModelElementLists[Element].objects[Entity] := nil;
    end;
  end;

  for Option := self.OptionStrList.count - 1 downto 0 do
    OptionStrList.objects[Option].Free;
  inherited;
end;



procedure TSubmodel.IsOutput(var IsOutput:boolean);

var
  i : integer;
  State : TState;
  Variable : TVar;
  ExValue : TExternV;

begin
  IsOutput := false;
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
      IsOutput := true;
  end;

  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.WriteToFile then
      IsOutput := true;
  end;
  // write values of all external variables to output file
  for i := 0 to self.ExternVStrList.count - 1 do
  begin
    ExValue := TExternV(ExternVStrList.objects[i]);
    if ExValue.opt_WriteToFile then
      IsOutput := true;
    end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  Init
  PURPOSE Initialisation method for TSubmodel
  INPUT   var GlobMod: TMod
  COMMENT Is being called on creation of application form and on run of simulation
  ****************************************************************** }

procedure TSubmodel.Init(var GlobMod: TMod);
var
  output_selected : boolean;
  i: TObject;

begin
  // FreeandNil(self.FMeasValues);
  if GlobMod <> nil then begin

  SomethingMeasured := false;
  GlobTime := GlobMod.Time;
  activate;
  ParIniF := GlobMod.ParamInifile;
  StateIniF := GlobMod.StateIniFile;
  OptionIniF := GlobMod.OptionIniFile;
  InitStates(GlobMod);
  InitParms(GlobMod);
  InitVars(GlobMod);
  InitOptions(GlobMod);
  if self.fOptContOutput.Option = 'true' then
    fWritecontinuouslyToFile := true else
    fWritecontinuouslyToFile := false;
  Output_selected := false;
//  IsOutput(fWritecontinuouslyToFile);
  if self.fOptFinalOutput.Option = 'true' then
    fWriteFinallyToFile := true else
    fWriteFinallyToFile := false;
  Output_selected := false;

  //IsOutput(fWritecontinuouslyToFile);


  InitOutputFileNames(GlobMod);

  InitUpdateFile(GlobMod);
  end;
end;

procedure TSubmodel.AddDataValueToDataSeries;
var
  i, line: Integer;
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
    FMeasValues.init(fn_meas);
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
              (Date >= GlobMod.FStartTime) and (Date < GlobMod.FEndTime) then
            begin
              MeasValue := TmeasValue.create(Date, X, GlobMod.MinLegalValue,
                extractfilename(GlobMod.ActIniFile.Filename));
              TMeasList(DataList.objects[i]).add(MeasValue);
            end;
          except
            on EInvalidOp do
            begin
            {$IFNDEF NONVISUAL}
              ShowMessage('Fehler in TSubModel.AddDataValueToDataSeries ' +
                FMeasValues.FName + ' ' + IntToStr(DataList.count) +
                ' Fehler aufgetreten bei: ' { + FMeasValues.getActLine() + ' ' +
                  getActLineStringList()[0] } + ' ' + FloatToStr(Date) + ' ');
            {$ENDIF}

            end;
          end;
        end;
      end;
    end;
    //FMeasValues.Free;
  end;
end;

{ * *****************************************************************
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
  Comment: string;
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
  Comment := comm;
  Par := TPar.create(ParName, ParUnits, value, 0.0, Comment);
  RegistrateParameter(Par);
end;

{ * *****************************************************************
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

{ * *****************************************************************
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

{ * *****************************************************************
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

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateOption
  PURPOSE Registers Option (TOption instance) in option list of submodel
  INPUT   Par: TOption
  ****************************************************************** }

procedure TSubmodel.RegistrateOption(Option: TOption);
var
  idx: Integer;
begin
  with OptionStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Option.Name);
    if idx >= 0 then
    begin
      objects[idx] := Option;
    end
    else
    begin
      AddObject(Option.Name, Option);
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateParameter
  PURPOSE Registers parameter (TPar instance) in parameter list of submodel
  INPUT   Par: TPar
  ****************************************************************** }

procedure TSubmodel.RegistrateParameter(Par: TPar);
var
  idx: Integer;
begin
  with ParStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Par.Name);
    if idx >= 0 then
      objects[idx] := Par
    else
      AddObject(Par.Name, Par);
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateVariable
  PURPOSE Registers variable (TVar instance) in variable list of submodel
  INPUT   Variable: TVar
  ****************************************************************** }

procedure TSubmodel.RegistrateVariable(Variable: Tvar);
var
  idx: Integer;
begin
  with VarStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Variable.Name);
    if idx >= 0 then
      objects[idx] := Variable
    else
      AddObject(Variable.Name, Variable);
  end;
end;


{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateVariable
  PURPOSE Registers variable (TVar instance) in variable list of submodel
  INPUT   Variable: TVar
  ****************************************************************** }

procedure TSubmodel.RegistrateConstant(Constant: Tvar);
var
  idx: Integer;
begin
  with ConstStrList do
  begin
    CaseSensitive := false;
    idx := indexof(Constant.Name);
    if idx >= 0 then
      objects[idx] := Constant
    else
      AddObject(Constant.Name, Constant);
  end;
end;



{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  RegistrateStateVar
  PURPOSE Registers state variable (TState instance) in state variable list of submodel
  INPUT   State: TState
  ****************************************************************** }

procedure TSubmodel.RegistrateStateVar(State: TState);
var
  idx: Integer;
begin
  with StateStrList do
  begin
    CaseSensitive := false;
    idx := indexof(State.Name);
    if idx >= 0 then
      objects[idx] := State
    else
      AddObject(State.Name, State);
  end;
end;

procedure TSubmodel.CreateAll();
var
  dir: string;

begin
  OptCreate('ContOutput', 'true', fOptContOutput,'Output every time step?');
  fOptContOutput.Optionlist.Clear;
  fOptContOutput.Optionlist.add('true');
  fOptContOutput.Optionlist.add('false');
  self.fWritecontinuouslyToFile := true;

  OptCreate('FinalOutput', 'false', fOptFinalOutput,'Output of final values in separate file?');
  fOptFinalOutput.Optionlist.Clear;
  fOptFinalOutput.Optionlist.add('true');
  fOptFinalOutput.Optionlist.add('false');
  self.fWriteFinallyToFile := false;


end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteStateName
  PURPOSE Write names and units of all variables to output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: TState
  ****************************************************************** }

procedure TSubmodel.WriteStateName(var f: TStreamWriter; fn:string; IniFile: string = '');
//procedure TSubmodel.WriteStateName(var f: textfile; fn:string);

var
  i: Integer;
  line, outstr, Caption: string;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;

begin
 // assignfile(f, fn);
 // rewrite(f);
 // rewrite(f);
  outstr := '';

  if f = NIL then
     f := TStreamWriter.Create(fn, false, TEncoding.UTF8);

  line := '';

  // first row of output file
 // if IniFile <> '' then
 //   line := IniFile + GlobMod.Separator;

  // write value of time variable to output file
  with self.GlobTime do
    Outstr := Name;
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
    begin
      Outstr := State.Name;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all variabes to output file
  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.WriteToFile then
    begin
      Outstr := Variable.Name;
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
      Outstr := ExValue.Name;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // change to next row
// writeln(f, line);
 // WriteLn(f);
 f.WriteLine(line);
  line := '';
  // write value of time variable to output file
  with GlobTime do
    Outstr := U;
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
    begin
      Outstr := State.U;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all variabes to output file
  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.WriteToFile then
    begin
      Outstr := Variable.U;
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
      Outstr := ExValue.U;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // change to next row
//  writeln(f, line); // WriteLn(f);
 f.WriteLine(line);

end;


{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteFinalStateName
  PURPOSE Write names and units of all variables to final output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: TState
  ****************************************************************** }

//procedure TSubmodel.WriteStateName(var f: TStreamWriter; fn:string; IniFile: string = '');
procedure TSubmodel.WriteFinalStateName(IniFile: string = '');

var
  i: Integer;
  line, outstr, Caption: string;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;

begin
 // assignfile(f, fn);
 // rewrite(f);
 // rewrite(f);
  outstr := '';

  if ffin_state = NIL then
     ffin_state := TStreamWriter.Create(IniFile, false, TEncoding.UTF8, 4096);

  line := '';

  // first row of output file
  if IniFile <> '' then
    line := 'IniFile' + self.GlobMod.Separator;

  // write value of time variable to output file
  with self.GlobTime do
    Outstr := Name;
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to self.StateStrList.count - 1 do
  begin
    State := TState(self.StateStrList.objects[i]);
    if State.Opt_WriteFinalValue then
    begin
      Outstr := State.Name;
      line := line + self.GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all variabes to output file
  for i := 0 to self.VarStrList.count - 1 do
  begin
    Variable := TPar(self.VarStrList.objects[i]);
    if Variable.Opt_WriteFinalValue then
    begin
      Outstr := Variable.Name;
      line := line + self.GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all external variables to output file
  for i := 0 to self.ExternVStrList.count - 1 do
  begin
    ExValue := TExternV(self.ExternVStrList.objects[i]);
    if ExValue.Opt_WriteFinalValue then
    begin
      Outstr := ExValue.Name;
      line := line + self.GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // change to next row
 //writeln(f, line);
 // WriteLn(f);
  ffin_state.WriteLine(line);
  line := 'Ini'+ self.globmod.Separator;
  // write value of time variable to output file
  with self.GlobTime do
    Outstr := U;
    line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to self.StateStrList.count - 1 do
  begin
    State := TState(self.StateStrList.objects[i]);
    if State.Opt_WriteFinalValue then
    begin
      Outstr := State.U;
      line := line + self.GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all variabes to output file
  for i := 0 to VarStrList.count - 1 do
  begin
    Variable := TPar(VarStrList.objects[i]);
    if Variable.Opt_WriteFinalValue then
    begin
      Outstr := Variable.U;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all external variables to output file
  for i := 0 to self.ExternVStrList.count - 1 do
  begin
    ExValue := TExternV(ExternVStrList.objects[i]);
    if ExValue.Opt_WriteFinalValue then
    begin
      Outstr := ExValue.U;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // change to next row
 // writeln(f, line); // WriteLn(f);
 ffin_state.WriteLine(line);

end;



{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteSensNames
  PURPOSE Write names and units of all sensitivity steps to output file (_dat.csv)
  INPUT   Variable: Tvar;
  var f: text
  ****************************************************************** }

procedure TMod.WriteSensNames(Variable: Tvar; var f: text);
var
  i: Integer;
  Caption: string;
begin
  // output file already opened: _sens_a.csv files
  { rewrite(f); }
  // first row of output file
  // write name of time variable to output
  write(f, Time.Name, Separator);
  // write names of all steps of sensitivity analysis to output
  for i := 1 to SensOpt.Steps do
  begin
    Caption := Variable.Name + '_' + IntToStr(i);
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

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteSensValue
  PURPOSE Writes values from sensitivity analysis to sens_ output files
  INPUT   Variable: Tvar;
  Iter: integer;
  var f_a, f_b: text
  ****************************************************************** }

procedure TMod.WriteSensValue(Variable: Tvar; Iter: Integer;
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

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  Integrate
  PURPOSE Integration of state variables (Euler method)
  ****************************************************************** }


{ * *****************************************************************
  CLASS   Tmod
  METHOD  InitGlobalOutputList
  PURPOSE Write names and units of all variables to output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: TState
  ****************************************************************** }

procedure TMod.InitGlobalOutputList;

var
  i,s: Integer;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;
  SubMod : TSubModel;

begin
  self.GlobalOutputList.Clear;
  for s := 0 to SubModStrList.count-1 do begin
     SubMod := TSubModel(SubModStrList.objects[s]);
  // write values of all state variables to output file
     for i := 0 to SubMod.StateStrList.count - 1 do begin
       State := TState(SubMod.StateStrList.objects[i]);
       if State.fGlobalOutput then
         GlobalOutputList.addobject(State.Name, State);
     end;
     for i := 0 to SubMod.VarStrList.count - 1 do begin
       Variable := TPar(SubMod.VarStrList.objects[i]);
       if Variable.fGlobalOutput then
          GlobalOutputList.addobject(Variable.Name, Variable);
     end;
     for i := 0 to SubMod.ExternVStrList.count - 1 do begin
       ExValue := TExternV(SubMod.ExternVStrList.objects[i]);
       if ExValue.fGlobalOutput then
          GlobalOutputList.addobject(ExValue.Name, ExValue);
     end;
  end;
end;



{ * *****************************************************************
  CLASS   TMod
  METHOD  WriteGlobalOutputNames
  PURPOSE Write names and units of all variables to output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: TState
  ****************************************************************** }

procedure TMod.WriteGlobalOutputNames(fn: string);

var
  i: Integer;
  path, filename , line, outstr, Caption: string;
  Entity: THumeNumEntity;

begin
//  assignfile(f, fn);
 // outstr := '';
  line := 'IniFile';
  path := self.GM_OutPutPath;
  if path <> '' then
    filename := path+'\'+fn
  else
    filename := fn;
//  if f_GlobalOutput = NIL then
    f_GlobalOutput := TStreamWriter.Create(fn, false, TEncoding.UTF8);
  f_GlobalOutput.AutoFlush := false;
//  assignfile(f, filename);
//  rewrite(f);
  // first row of output file
  line := line + Separator;
  // write value of time variable to output file
  Outstr := Time.Name;
  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to GlobalOutputList.count - 1 do
  begin
    Entity := THumeNumEntity(GlobalOutputList.objects[i]);
      Outstr := Entity.Name;
      line := line + Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  // change to next row
  f_GlobalOutput.WriteLine(line);
//  writeln(f, line); // WriteLn(f);
end;





procedure TSubmodel.Integrate;
var
  j: Integer;
  State: TState;
begin
  // for all state variables do...
  for j := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[j]);
    State.v := State.v + State.c * GlobTime.c;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  UpdateValues
  PURPOSE update Values by measured data
  ****************************************************************** }

procedure TSubmodel.UpdateValues;
var
  i: Integer;
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


{ * *****************************************************************
  CLASS   TMod
  METHOD  SaveGlobalOutput
  PURPOSE Writes values of state, parameter and external variables to output files
  INPUT   var f: text;
  fn: string;
  Time: TState
  ****************************************************************** }

procedure TMod.SaveGlobalOutput(IniFile: string);
var
  i: Integer;
  Entity: THumeNumEntity;
  fn, Outstr: string;
  line: String;
begin
  fn := ExtractFileName(IniFile);
  if fn <> '' then
    line := fn + Separator;
  // write value of time variable to output file
  with Time do
    Outstr := FloatToStrf(v - c, ffgeneral, Precision, Digits);
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to GlobalOutputList.count - 1 do
  begin
    Entity := THumeNumEntity(GlobalOutputList.objects[i]);
    Outstr := FloatToStrf(Entity.v, ffgeneral, Entity.Precision, Entity.Digits);
      line := line + Separator + Outstr;
  end;
  // change to next row

  f_GlobalOutput.WriteLine(line);
  //  writeln(f_GlobalOutput, line); // WriteLn(f);
end;



{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  SaveState
  PURPOSE Writes values of state, parameter and external variables to output files
  INPUT   var f: text;
  fn: string;
  Time: TState
  COMMENT #TS#026 code modified due to problems with separator
  ****************************************************************** }

procedure TSubmodel.SaveState(var f: TStreamWriter; IniFile: string);
//procedure TSubmodel.SaveState(var f: textfile; IniFile: string);
var
  i: Integer;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;
  Outstr: string;
  line: String;
begin
  self.fWritecontinuouslyToFile := true;
  line := '';
  if IniFile <> '' then
    line := IniFile + GlobMod.Separator;

  // write value of time variable to output file
  with GlobTime do
    Outstr := FloatToStrf(v - c, ffgeneral, Precision, Digits);
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
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
    if Variable.WriteToFile then
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
  f.WriteLine(line);
//  writeln(f, line); // WriteLn(f);
end;



{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  SaveFinalState
  PURPOSE Writes values of state, parameter and external variables to output files
  INPUT   var f: text;
  fn: string;
  Time: TState
  COMMENT #TS#026 code modified due to problems with separator
  ****************************************************************** }

procedure TSubmodel.SaveFinalState(var f: TStreamWriter; IniFile: string);
// procedure TSubmodel.SaveFinalState(var f: textfile; IniFile: string);
var
  i: Integer;
  State: TState;
  Variable: TPar;
  ExValue: TExternV;
  outstr: string;
  line: String;
begin
  if self.fWriteFinallyToFile then
  begin

    line := '';
    if IniFile <> '' then
      line := IniFile + GlobMod.Separator;

    // write value of time variable to output file
    with GlobTime do
      outstr := FloatToStrf(v - c, ffgeneral, Precision, Digits);
    // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

    line := line + outstr; // write(f, Outstr);

    // write values of all state variables to output file
    for i := 0 to StateStrList.count - 1 do
    begin
      State := TState(StateStrList.objects[i]);
      if State.Opt_WriteFinalValue then
      begin
        outstr := FloatToStrf(State.v, ffgeneral, State.Precision,
          State.Digits);
        line := line + GlobMod.Separator + outstr;
        // write(f, GlobMod.Separator, Outstr);
      end;
    end;
    // write values of all variabes to output file
    for i := 0 to VarStrList.count - 1 do
    begin
      Variable := TPar(VarStrList.objects[i]);
      if Variable.Opt_WriteFinalValue then
      begin
        outstr := FloatToStrf(Variable.v, ffgeneral, Variable.Precision,
          Variable.Digits);

        line := line + GlobMod.Separator + outstr;
        // write(f, GlobMod.Separator, Outstr);
      end;
    end;
    // write values of all external variables to output file
    for i := 0 to self.ExternVStrList.count - 1 do
    begin
      ExValue := TExternV(ExternVStrList.objects[i]);
      if ExValue.Opt_WriteFinalValue then
      begin
        outstr := FloatToStrf(ExValue.v, ffgeneral, 6, 2);
        line := line + GlobMod.Separator + outstr;
        // write(f, GlobMod.Separator, Outstr);
      end;
    end;
    // change to next row
    // if (self.GlobMod.FinalOutput) then
    f.WriteLine(line);
    // writeln(f, line); // WriteLn(f);
  end;
end;

procedure TSubmodel.closeOutputfiles;
begin
  if f_state <> NIL then begin

   f_state.Flush;
   f_state.Close;
   f_state.Free;
   f_state := NIL;
  end;
  if f_rate <> NIL then begin

       f_rate.Flush;
       f_rate.Close;
       f_rate.Free;
       f_rate := NIL;
  end;
//  f_state.Close;
//  f_rate.Close;
//  CloseFile(f_state);
//  CloseFile(f_rate);
end;

procedure TSubmodel.ConstCreate(ConstName, ConstUnits: string; DefaultValue: real;
  ReadFromFile: boolean; var Constant: Tvar; comm: string);
var
  value : real;

begin
  value := DefaultValue;
  Constant := TVar.create(ConstName, ConstUnits, value, comm);
  RegistrateConstant(Constant);
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  WriteRateName
  PURPOSE Write names and units of all rate variables to output file (_dat.csv)
  INPUT   var f: text;
  fn: string;
  Time: Tstate
  ****************************************************************** }

procedure TSubmodel.WriteRateName(var f: TStreamWriter; fn: string);
//procedure TSubmodel.WriteRateName(var f: textfile; fn: string);
var
  i: Integer;
  State: TState;
  line, outstr, Caption: string;
begin

  outstr := '';
  line := '';
  f := TStreamWriter.Create(fn, false, TEncoding.UTF8);
  // write value of time variable to output file
  with GlobTime do
    Outstr := Name;
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
    begin
      Outstr := State.Name;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // write values of all variabes to output file
  // change to next row
  f.WriteLine(line);
 // writeln(f, line); // WriteLn(f);

  line := '';
  // write value of time variable to output file
  with GlobTime do
    Outstr := U;
  // #TS#026  previous version: write(f, OutStr, GlobMod.Separator);

  line := line + Outstr; // write(f, Outstr);

  // write values of all state variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
    begin
      Outstr := State.U;
      line := line + GlobMod.Separator + Outstr;
      // write(f, GlobMod.Separator, Outstr);
    end;
  end;
  // change to next row
  f.WriteLine(line);
//  writeln(f, line); // WriteLn(f);

end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  SaveRate
  PURPOSE Writes values of rate variables to output files
  INPUT   var f: text;
  fn: string;
  Time: Tstate
  ****************************************************************** }

procedure TSubmodel.SaveRate(var f: TStreamWriter);
//procedure TSubmodel.SaveRate(var f: textfile);
var
  i: Integer;
  State: TState;
  outstr, line: string;
begin
  // write value of time variable to output file
  line := FloatToStrf(GlobTime.v - GlobTime.c, ffgeneral, GlobTime.Precision,
    GlobTime.Digits);
  line := line + GlobMod.Separator;
//  write(f, Outstr, GlobMod.Separator);
  // write values of all rate variables to output file
  for i := 0 to StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    if State.WriteToFile then
    begin
      Outstr := FloatToStrf(State.c, ffgeneral, GlobTime.Precision, GlobTime.Digits);
//      write(f, Outstr, GlobMod.Separator);
      line := line + Outstr + GlobMod.Separator;
//    f.write(Outstr);
    end;
  end;
  f.WriteLine(line);
//   writeln(f, line);
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  CalcRates
  PURPOSE Rate calculation (to be overwritten by derived classes)
  ****************************************************************** }

procedure TSubmodel.CalcRates;
begin
{$IFNDEF NONVISUAL}
  ShowMessage(' Error !  You should not see this Message ! ');
  ShowMessage(' You did not overwrite Method CalcRates ');
{$ENDIF}

end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  CalcVars
  PURPOSE Variable calculation (to be overwritten by derived classes)
  ****************************************************************** }

procedure TSubmodel.CalcVars;
begin
  // ShowMessage(' Error !  You should not see this Message ! ');
  // ShowMessage(' You did not overwrite Method CalcRates ');
end;

{ * *****************************************************************
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

{ * *****************************************************************
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
    ExternVStrList.Sort;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  ExternVInit
  PURPOSE Setting pointers of external variables
  INPUT   model: Tmod
  ****************************************************************** }

function TSubmodel.ExternVinit(Model: TMod): boolean;
var
  i, j, index: Integer;
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
      index := Model.WeatherFile.FirstLine.indexof(ExternV.Name);
      // yes, external variable is stored in weather file
      if (index >= 0) then
      begin
        Par := TPar(Model.WeatherFile.FirstLine.objects[index]);
        ExternV.SetPointer(@Par.fv);
        ExternV.U := Par.U;
        ExternV.Source := Model.WeatherFile.FName;
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
              ExternV.Source := subMod.Name;
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
                ExternV.Source := subMod.Name;
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
                ExternV.Source := subMod.Name;
                Success := true;
              end;
            end;
            if not Success then
            begin
              index := subMod.ConstStrList.indexof(ExternV.Name);
              if (index >= 0) then
              begin
                Variable := TPar(subMod.ConstStrList.objects[index]);
                ExternV.SetPointer(@Variable.fv);
                ExternV.Source := subMod.Name;
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
{$IFNDEF NONVISUAL}
        ShowMessage('Error on initialisation of interface, Parameter: ' +
          ExternV.Name + '  SubModel:' + self.Name);
{$ELSE}
        writeln('Error on initialisation of interface, Parameter: ' +
          ExternV.Name + '  SubModel:' + self.Name);
{$ENDIF}
        Result := false;
        break;
      end
    end;
  end;

end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  AddSimValueToDataSeries
  PURPOSE Adding simulated values to corresponding measured data
  ****************************************************************** }

procedure TSubmodel.AddSimValueToDataSeries;
var
  i, ListPos: Integer;
  ActSeries: TMeasList;
  ActMeas: TmeasValue;
  actState: TState;
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
            actState := TState(StateStrList.objects[ListPos]);
            ActMeas.sim := actState.v;
            actState.IsMeasured := true;
            SumSqrdiff := SumSqrdiff + Sqr(ActMeas.sim - ActMeas.meas);
            ActMeas.Source := GlobMod.ActIniFile.Filename;
          end
          else
          begin
            ListPos := VarStrList.indexof(name);
            if ListPos <> -1 then
            begin
              ActVar := Tvar(VarStrList.objects[ListPos]);
              ActVar.IsMeasured := true;
              ActMeas.sim := ActVar.v;
              ActMeas.Source := GlobMod.ActIniFile.Filename;
              // if SumSqrdiff < 10E+100 then
              SumSqrdiff := SumSqrdiff + Sqr(ActMeas.sim - ActMeas.meas);
            end;
          end;
        end;
      end;
    end;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  write_1_1_files
  PURPOSE Output of simulated/measured data pairs to _1_1.csv files
  ****************************************************************** }

procedure TSubmodel.write_1_1_files;
var
  i: Integer;
  dir, fn: string;
  ActSeries: TMeasList;
begin
  // for all data pairs do...
  for i := 0 to DataList.count - 1 do
  begin
    ActSeries := TMeasList(DataList.objects[i]);
    fn := ActSeries.Name + '_1_1.csv';
{$IFDEF LINUX}
    dir := GlobMod.FOutputPath + '/1_1/';
{$ELSE}
    dir := GlobMod.FOutputPath + '\1_1\';
{$ENDIF}
    if SysUtils.ForceDirectories(dir) then
      ActSeries.WriteToFile(dir + fn);
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  CalcLinearRegressions
  PURPOSE Calculation of linear regression
  ****************************************************************** }

procedure TSubmodel.CalcLinearRegressions;
var
  i: Integer;
  ActSeries: TMeasList;
begin
  // for all data pairs do...
  for i := 0 to DataList.count - 1 do
  begin
    ActSeries := TMeasList(DataList.objects[i]);
    ActSeries.LeastSquares;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  ClearDataSeries
  PURPOSE Clears data pair series
  ****************************************************************** }

procedure TSubmodel.ClearDataSeries;
var
  i: Integer;
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

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  Paint
  PURPOSE New Paint procedure for TSubmodel (which is derived from TGraphicControl)
  ****************************************************************** }
{$IFNDEF NONVISUAL}
procedure TSubmodel.Paint;
var
  X, Y, w, h, text_left, text_length: Integer;
  Titel: string;
  TypeStr: string;
  oldfontsize: Integer;
begin
 inherited;

  if Visible then
  begin
    Titel := Name;
    TypeStr := ClassName;
    with Canvas do
    begin
      Brush.color := color;
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

{$ENDIF}

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  Destroy
  PURPOSE Remove submodel entry from global TMod instance and call inherited
  destroy method
  ****************************************************************** }

procedure TSubmodel.BeforeDestruction;
var
  index: Integer;
begin
  self.fUpdateValueList.Free;
  self.FUpdValues.Free;
  self.FMeasValues.Free;
  self.FMeasValues_2.Free;
  { if StateIniF <> nil then
    self.StateIniF.Free;
    self.ParIniF.Free;
    self.VarStrList.Free;
    self.ParStrList.Free;
    ExternVStrList.Free;
    ConstStrList.Free;
    OptionStrList.Free; }
  fAssimilatedSubmodList.Free;
  DataList.Free;

  if self.SM_GlobMod <> nil then
  begin
    If SM_GlobMod.SubModStrList <> nil then
    begin
      index := SM_GlobMod.SubModStrList.indexof(self.Name);
      if SM_GlobMod.SubModStrList.objects[index] <> nil then
        SM_GlobMod.SubModStrList.delete(index);
    end;
    inherited BeforeDestruction;
  end;
end;

{ * *****************************************************************
  CLASS   TSubmodel
  METHOD  DblClick
  PURPOSE Show Message after doubleclick on TSubmodel during Runtime
  ****************************************************************** }

{$IFNDEF NONVISUAL}

procedure TSubmodel.DblClick;

var
  FormSubModelEditor: TF_SubmodelEditor;
  Params: TPar;
  variables: Tvar;
  States: TState;
  externs: TExternV;
  i: Integer;
begin
  Inherited DblClick;
  // ShowMessage('Sub-model created using HUME');
  { HumeForm := THumeForm.create;
    HumeForm.showmodal;
    HumeForm.clear; }
  self.Init(GlobMod);
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
      Params := TPar(ParStrList.objects[i]);
      Cells[0, i + 1] := Params.Name;
      Cells[1, i + 1] := Params.U;
      Cells[2, i + 1] := FloatToStrf(Params.v, ffgeneral, 6, 3);
      Cells[3, i + 1] := IntToStr(Params.Digits);
      Cells[4, i + 1] := IntToStr(Params.Precision);
      AddCheckBox(5, i + 1, true, true);
      SetCheckBoxState(5, i + 1, Params.ReadFromIniFile);
      AddCheckBox(6, i + 1, true, true);
      SetCheckBoxState(6, i + 1, Params.WriteToFile);
      AddCheckBox(7, i + 1, true, true);
      SetCheckBoxState(7, i + 1, Params.SelForOpt);
      AddCheckBox(8, i + 1, true, true);
      SetCheckBoxState(8, i + 1, Params.PlotTograpH);
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
      Cells[0, i + 1] := variables.Name;
      Cells[1, i + 1] := variables.U;
      Cells[2, i + 1] := FloatToStrf(variables.v, ffgeneral, 6, 3);
      Cells[3, i + 1] := IntToStr(variables.Digits);
      Cells[4, i + 1] := IntToStr(variables.Precision);
      AddCheckBox(5, i + 1, true, true);
      SetCheckBoxState(5, i + 1, variables.ReadFromIniFile);
      AddCheckBox(6, i + 1, true, true);
      SetCheckBoxState(6, i + 1, variables.WriteToFile);
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
      States := TState(StateStrList.objects[i]);
      Cells[0, i + 1] := States.Name;
      Cells[1, i + 1] := States.U;
      Cells[2, i + 1] := FloatToStrf(States.v, ffgeneral, 6, 3);
      Cells[3, i + 1] := IntToStr(States.Digits);
      Cells[4, i + 1] := IntToStr(States.Precision);
      AddCheckBox(5, i + 1, true, true);
      SetCheckBoxState(5, i + 1, States.ReadFromIniFile);
      AddCheckBox(6, i + 1, true, true);
      SetCheckBoxState(6, i + 1, States.WriteToFile);
      AddCheckBox(7, i + 1, true, true);
      SetCheckBoxState(7, i + 1, States.PlotTograpH);
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
      Cells[0, i + 1] := externs.Name;
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
        Params := TPar(ParStrList.objects[i]);
        Params.U := ADV_Par.Cells[1, i + 1];
        Params.v := StrToFloat(ADV_Par.Cells[2, i + 1]);
        Params.Digits := strtoint(ADV_Par.Cells[3, i + 1]);
        Params.Precision := strtoint(ADV_Par.Cells[4, i + 1]);
        ADV_Par.GetCheckboxState(5, i + 1, Params.ReadFromIniFile);
        ADV_Par.GetCheckboxState(6, i + 1, Params.WriteToFile);
        ADV_Par.GetCheckboxState(7, i + 1, Params.SelForOpt);
        ADV_Par.GetCheckboxState(8, i + 1, Params.PlotTograpH);
      end;
      // stores TVar
      for i := 0 to VarStrList.count - 1 do
      begin
        variables := Tvar(VarStrList.objects[i]);
        variables.U := adv_var.Cells[1, i + 1];
        variables.v := StrToFloat(adv_var.Cells[2, i + 1]);
        variables.Digits := strtoint(adv_var.Cells[3, i + 1]);
        variables.Precision := strtoint(adv_var.Cells[4, i + 1]);
        adv_var.GetCheckboxState(5, i + 1, variables.ReadFromIniFile);
        adv_var.GetCheckboxState(6, i + 1, variables.WriteToFile);
        adv_var.GetCheckboxState(7, i + 1, variables.PlotTograpH);
      end;
      // stores TState
      for i := 0 to StateStrList.count - 1 do
      begin
        States := TState(StateStrList.objects[i]);
        States.U := adv_state.Cells[1, i + 1];
        States.v := StrToFloat(adv_state.Cells[2, i + 1]);
        States.Digits := strtoint(adv_state.Cells[3, i + 1]);
        States.Precision := strtoint(adv_state.Cells[4, i + 1]);
        adv_state.GetCheckboxState(5, i + 1, States.ReadFromIniFile);
        adv_state.GetCheckboxState(6, i + 1, States.WriteToFile);
        adv_state.GetCheckboxState(7, i + 1, States.PlotTograpH);
      end;
      // stores TExternValue
      for i := 0 to ExternVStrList.count - 1 do
      begin
        externs := TExternV(ExternVStrList.objects[i]);
        externs.Name := ADV_ExternV.Cells[0, i + 1];
        externs.U := ADV_ExternV.Cells[1, i + 1];
        externs.C_f := StrToFloat(ADV_ExternV.Cells[2, i + 1]);
      end;

    end;
    Free;
  end;

end;

{$ENDIF}

procedure TSubmodel.InitUpdateFile(var GlobMod: TMod);
var
  TempStr: TStringList;
  fn_UpdFile: string;
begin
  if GlobMod.ActIniFile <> nil then begin

  // reads filenames of measurement and output files from main Ini-file
  { fn_meas := GlobMod.ActIniFile.ReadString
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
    if (FileExists(fn_meas)=false) and (fn_meas <> '') then
    ShowMessage('Measurementfile ' + fn_meas + 'of ' + self.name +
    ' is specified but does not exist')
    end; }
  fn_UpdFile := GlobMod.ActIniFile.ReadString
    (GlobMod.Str_SectionName_UpdateFiles, SubModname, '');
  if FileExists(fn_UpdFile) then
  begin
    FUpdValues.init(fn_UpdFile);
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
{$IFNDEF NONVISUAL}
      ShowMessage('Updatefile ' + fn_UpdFile + ' of Submodel' + self.Name +
        ' is specified but does not exist');
{$ELSE}
      writeln('Updatefile ' + fn_UpdFile + ' of Submodel' + self.Name +
        ' is specified but does not exist');
{$ENDIF}
  end;
  end;
end;

procedure TSubmodel.InitOutputFileNames(var GlobMod: TMod);
var
  defaultname, dir: string;
  fn_meas: string;
begin
  if GlobMod.ActIniFile <> nil then begin

  defaultname := extractfilename(GlobMod.ActIniFile.Filename);
  delete(defaultname, pos('.', defaultname), 4);
//  defaultname := defaultname + '_' + SubModname;
  defaultname := defaultname + '_' + self.name;
{$IFDEF LINUX}
  dir := GlobMod.FOutputPath + 'rate/';
{$ELSE}
  dir := GlobMod.FOutputPath + '\rate\';
{$ENDIF}
  if SysUtils.ForceDirectories(dir) then
    fn_rate := dir + defaultname + '_rat.csv'
  else fn_rate := defaultname + '_rat.csv';
{$IFDEF LINUX}
  dir := GlobMod.FOutputPath + '/state/';
{$ELSE}
  dir := GlobMod.FOutputPath + '\state\';
{$ENDIF}
  if SysUtils.ForceDirectories(dir) then
    fn_state := dir + defaultname + '_dat.csv'
  else
    fn_state := defaultname + '_dat.csv';

//  self.f_state := TStreamwriter.Create(fn_state, false, )
  // creates a default name for output
 // fn_state := GlobMod.ActIniFile.ReadString(GlobMod.Str_SectionName_OutPutFiles,
 //   SubModname, defaultname) + '_dat.csv';
  // write output filename to ini-file if not yet present
 // fn_rate := GlobMod.ActIniFile.ReadString(GlobMod.Str_SectionName_OutPutFiles,
 //   SubModname, defaultname) + '_rat.csv';



//  if GlobMod.GM_OutPutPath <> '' then
//    fn_finalstate := GlobMod.GM_OutPutPath + '\' + 'Final_' + fn_finalstate +
//      '_' + Name + '.csv'
//  else
//    fn_finalstate := GlobMod.EXE_DIR + '\' + 'Final_' + fn_finalstate + '_' +
//      Name + '.csv';
  // reads filenames of measurement and output files from main Ini-file
  // KLUSS FMeasValues.FileName :=
  fn_meas := GlobMod.ActIniFile.ReadString
    (GlobMod.Str_SectionName_MeasurementFiles, SubModname, '');
  if FileExists(fn_meas) then
  begin
    FMeasValues.init(fn_meas);
    SomethingMeasured := true;
  end
  else
  begin
//    FMeasValues := nil;
    SomethingMeasured := false;
  end;
  end;
end;

procedure TSubmodel.InitOptions(var GlobMod: TMod);
var
  Option: TOption;
  i: Integer;
begin
  if GlobMod.OptionIniFile <> nil then




  begin

    // (Re)initialization of all options
    OptionStrList.Sorted := false;
    for i := 0 to self.OptionStrList.count - 1 do
    begin
      Option := TOption(OptionStrList.objects[i]);
      Option.submodname := self.Name;
      Option.Option := '';
      if Option.ReadFromIniFile then
      begin
        Option.Option := GlobMod.OptionIniFile.ReadString(Option.submodname,
          Option.Name, Option.Defaultstring);
      end;
    end;

    OptionStrList.Sort;
    OptionStrList.Sorted := true;
    for i := 0 to self.OptionStrList.count - 1 do



    begin
      Option := TOption(OptionStrList.objects[i]);
      if Option.Option <> '' then
      begin
        GlobMod.OptionIniFile.WriteString(Option.submodname, Option.Name,
          Option.Option);
      end;
    end;
    GlobMod.OptionIniFile.UpdateFile;
  end;
end;

procedure TSubmodel.InitVars(var GlobMod: TMod);
var
  i: Integer;
  Variable: Tvar;
begin
  // (Re)initialization of all variables
  // Warum werden hier Variablen initialisiert?
  VarStrList.Sorted := false;
  for i := 0 to self.VarStrList.count - 1 do
  begin
    Variable := Tvar(VarStrList.objects[i]);
    Variable.SubModname := self.Name;
    VarStrList.Strings[i] := Variable.Name;
    Variable.v := Variable.DefaultValue;
    // TODO Warum sollte man Variablen aus einer Datei lesen wollen?
    if Variable.ReadFromIniFile then
      if GlobMod.StateIniFile.valueexists(Variable.SubModname, Variable.Name) then
      begin
        Variable.v := GlobMod.StateIniFile.ReadFloat(Variable.SubModname, Variable.Name,
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
end;

procedure TSubmodel.InitParms(var GlobMod: TMod);
var
  i: Integer;
  Param: TPar;
begin
  // (Re)initialization of all parameters
  ParStrList.Sorted := false;
  for i := 0 to ParStrList.count - 1 do
  begin
    Param := TPar(ParStrList.objects[i]);
    Param.SubModname := self.Name;
    ParStrList.Strings[i] := Param.Name;
    // This is necessary because the Name of the parameter may have been
    // altered within the object inspector
    if GlobMod.ParamIniFile <> nil then  begin
    if not Param.SelForOpt and Param.ReadFromIniFile then
      if GlobMod.ParamInifile.valueexists(Param.SubModname, Param.Name) then
      begin
        { Read values only if not selected for optimization ! }
        Param.v := GlobMod.ParamInifile.ReadFloat(Param.SubModname, Param.Name,
          Param.DefaultValue);
        { else showMessage(GlobMod.ParamInifile.Filename+' '+Param.name+' '+FloatToStr(Param.v)) }
      end
      else
      begin
        // if error then begin
        Param.v := Param.DefaultValue;
        GlobMod.ParamInifile.WriteFloat(Param.SubModname, Param.Name,
          Param.DefaultValue);
      end;
    { ShowMessage('Error on initialization of parameters'); }
  end;
  end;
  ParStrList.Sort;
  ParStrList.Sorted := true;
end;

procedure TSubmodel.InitStates(var GlobMod: TMod);
var
  State: TState;
  i: Integer;
  value: real;
begin
  // (Re)initialization of all state variables
  StateStrList.Sorted := false;
  for i := 0 to self.StateStrList.count - 1 do
  begin
    State := TState(StateStrList.objects[i]);
    State.SubModname := self.Name;
    StateVar[i].SubModname := self.Name;
    StateStrList.Strings[i] := State.Name;
    State.c := 0;
    // At the beginning the rate of change equals 0 for all state variables
    State.v := State.DefaultValue;
    if State.ReadFromIniFile and (State.Name <> '') then
      if (GlobMod.StateIniFile <> nil) then begin
        if GlobMod.StateIniFile.valueexists(State.SubModname, State.Name) then
      begin
        value := GlobMod.StateIniFile.ReadFloat(State.SubModname, State.Name, 0);
        State.v := value;
        State.wasreadfromfile := true;
      end
      end
      else
      begin
        State.v := 0;
        State.wasreadfromfile := false;
        if GlobMod.StateIniFile <> nil then
          GlobMod.StateIniFile.WriteFloat(State.SubModname, State.Name,
          State.DefaultValue);
      end;
    State.iv := State.v;
  end;
  StateStrList.Sort;
  StateStrList.Sorted := true;

end;

{ * *****************************************************************
  CLASS   TMod
  METHOD  DblClick
  PURPOSE Shows Message after doubleclick on TMod during Run-time
  ****************************************************************** }

{$IFNDEF NONVISUAL}
procedure TMod.DblClick;
var
  // HumeForm : TFormHumeShow;
  FormModelEditor: TModelEdit;
  i, j, OldIndex, NewIndex, SubModIndex: Integer;
  subMod: TSubmodel;
  // f: textFile;

begin
  if GM_ControlFile = '' then
  begin
    ShowMessage('No Controlfile specified');
//    Exit;
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
    ListBoxSubModels.Items.addstrings(SubModStrList);
    { if SubModStrList.count > 0 then
      begin
      for i := 0 to SubModStrList.count - 1 do
      ListBoxSubModels.Items.add(SubModStrList.Strings[i]);
      end; }
    Edit_ModelName.text := Name;
    ComboBox_Separator.text := Separator;
    DateTimePicker_MT_Starttime.Date := StartTime;
    DateTimePicker_MT_Endtime.Date := EndTime;
    Edit_MT_Name.text := ModTime.Name;
    Edit_MT_Unit.text := ModTime.U;
    Edit_MT_Value.text := FloatToStr(ModTime.v);
    Edit_MT_Digits.text := IntToStr(ModTime.Digits);
    Edit_MT_Precision.text := IntToStr(ModTime.Precision);
    CheckBox_MT_WriteToFile.Checked := ModTime.WriteToFile;
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
    EditNameControlFile.text := fControlFileFn;
    // shows Editor
    ShowMessage('Entering Componenent Editor');
    showmodal;
    ShowMessage('Leaving Componenent Editor');
    // stores modified values from editor form to properties
    if FormModelEditor.save_Status then
      ShowMessage('Save = true')
    else
      ShowMessage('Save = false');
    if save_Status then
    begin
      // ShowMessage('hello - FormModelEditor.Save_Status');
      Name := Edit_ModelName.text;
      Separator := ComboBox_Separator.text[1];
      StartTime := DateTimePicker_MT_Starttime.Date;
      EndTime := DateTimePicker_MT_Endtime.Date;
      ModTime.Name := Edit_MT_Name.text;
      ModTime.U := Edit_MT_Unit.text;
      ModTime.v := StrToFloat(Edit_MT_Value.text);
      ModTime.Digits := strtoint(Edit_MT_Digits.text);
      ModTime.Precision := strtoint(Edit_MT_Precision.text);
      ModTime.WriteToFile := CheckBox_MT_WriteToFile.Checked;
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

      for i := 0 to ListBoxSubModels.count - 1 do
      begin
        Name := ListBoxSubModels.Items[i];
        SubModIndex := SubModStrList.indexof(Name);
        subMod := TSubmodel(SubModStrList.objects[SubModIndex]);
        subMod.CompIndex := i;
      end;

      // SubModStrList.CustomSort( );
      for j := SubModStrList.count - 2 downto 0 do
        for i := 0 to j do
          if TSubmodel(SubModStrList.objects[i]).CompIndex >
            TSubmodel(SubModStrList.objects[i + 1]).CompIndex then
            SubModStrList.Exchange(i, i + 1);

      for i := 0 to SubModStrList.count - 1 do
      begin
        Name := SubModStrList.Strings[i];
        SubModStrList.Sort;
        OldIndex := SubModStrList.indexof(Name);
        NewIndex := ListBoxSubModels.Items.indexof(Name);
        subMod := TSubmodel(SubModStrList.objects[OldIndex]);
        subMod.CompIndex := NewIndex;
        // subMod := TSubmodel(SubModStrList.objects[i]).CompIndex :=
      end;
    end;
    Free;
  end;
end;

{$ENDIF}


{function TSubModel.GetOnClick:TNotifyEvent;
begin
  OnClick := click;
end;

procedure TSubmodel.SetOnClick(const Value: TNotifyEvent);
begin
  FOnClick := Value;
end; }

{procedure TSubModel.Click;
begin
  inherited Click;
  ShowMessage('Click on'+Name+'!') ;
  if Assigned(OnClick) then OnClick(self);
end; }



{procedure TSubModel.DblClick;
begin
  inherited DblClick;
  ShowMessage('Click on'+Name+'!') ;
  if Assigned(OnClick) then OnClick(self);
end;   }


procedure Register;
begin

{$IFNDEF NONVISUAL}
  // Registers TMod and TSubModel on HUME Component palette
  RegisterComponents('HUME', [TSubModel, Tmod]);
  // RegisterComponents('HUMEDemo', [TLogistGrowth]);

{$ENDIF}

end;

initialization
  DesignTime := ParamStr(0).EndsWith('\bds.exe', True);
end.
