///<unit>
///  <name>UState</name>
///  <summary>
///    Defines core data types and classes for representing state variables, parameters, and external variables in a crop simulation model.
///    Provides a standardized way to handle variables that change over time (states), fixed model parameters, and variables imported from other modules or the environment.
///  </summary>
///  <remarks>
///    <item>
///      <desc>TState</desc>
///      <info>Type or class for state variables (e.g., leaf area, biomass) updated during simulation.</info>
///    </item>
///    <item>
///      <desc>TPar / TPAR</desc>
///      <info>Types or classes for model parameters (constants or tunable values).</info>
///    </item>
///    <item>
///      <desc>TExternV</desc>
///      <info>Types or classes for external variables (inputs from other modules, weather, soil, etc.).</info>
///    </item>
///    <item>
///      <desc>TOption</desc>
///      <info>Type for model options or switches (e.g., to enable/disable certain processes).</info>
///    </item>
///    <item>
///      <desc>TVAR</desc>
///      <info>General-purpose variable type, often for intermediate or calculated values.</info>
///    </item>
///  </remarks>
unit UState;
{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

interface

uses
  classes,
  {$IFNDEF NONVISUAL}
  Vcl.Dialogs,
  {$ENDIF}
  sysutils;

type
  /// <summary>Setting all floating points to double as a standard.</summary>
  real = double;

  /// <summary>Enumeration type for pointers, important for external state variables and external values where the name of a state variable can refer to the state or its rate of change.</summary>
  TExValue = (RateField, StateField);

  {$IFDEF NONVISUAL}
  THumeEntity = class(TObject)
  {$ELSE}

  /// <summary>THumeEntity is the base class for all objects representing either numerical values (states, variables, parameters, constants) or options.</summary>
  /// <remarks>Provides basic functionality for variables (parameters, state variables) and external "driving forces". If the destination is a console app it derives from TObject; otherwise it derives from TPersistent for IDE/GUI use.</remarks>
   THumeEntity = class(TPersistent)
  {$ENDIF}

  private
    /// <summary>Name field.</summary>
    N { ame }: string;
    /// <summary>Field for comments/explanation.</summary>
    FComment: string;
    /// <summary>Private field for the name of the Entity.</summary>
    fName: string;
    /// <summary>Field submodel to which the Entity belongs.</summary>
    fSubmod: string;
    /// <summary>Field documentation link.</summary>
    fDocuWebLink: string;
  public
    /// <summary>Units of the entity.</summary>
    U { nits }: string;
    /// <summary>Indicates if the entity is indexed (array).</summary>
    Indexed: boolean;
    /// <summary>Lower bound for indexed entities.</summary>
    lowerbound: integer;
    /// <summary>Upper bound for indexed entities.</summary>
    upperbound: integer;
    /// <summary>Flag for initialisation from file.</summary>
    ReadFromIniFile: boolean;
    /// <summary>Flag for output to text file.</summary>
    WriteToFile: boolean;
    /// <summary>Flag for output to Ini file.</summary>
    WriteToIniFile: boolean;
    /// <summary>Flag for selection for output.</summary>
    SelForSensOut : boolean;
    /// <summary>Flag for initialisation from file; false indicates need for alternative initialisation.</summary>
    WasReadFromFile: boolean;
  published
    /// <summary>Name of the object.</summary>
    property Name: string read N write N;
    /// <summary>Name of the submodule.</summary>
    property SubModName: string read fSubmod write fSubmod;
    /// <summary>Comment or description.</summary>
    property Comment: string read FComment write FComment;
    /// <summary>DocuWebLink.</summary>
    property DocuWebLink: string read fDocuWebLink write fDocuWebLink;
    /// <summary>Flag indicating whether to write output to a text file.</summary>
    property Opt_writetoFile: boolean read WriteToFile write WriteToFile;
    /// <summary>Flag indicating selection for sensitivity analysis output.</summary>
    property Opt_SelForSensOut : boolean read SelForSensOut write SelForSensOut;
    /// <summary>Units associated with the object.</summary>
    property Units: string read U write U;
  end;

/// <summary> TOption is a class representing an option with a string value and a list of possible options. </summary>
  TOption = class(THumeEntity)
  private
    /// <summary>The private field for the option string.</summary>
    fOption: string;

    /// <summary>Getter for the option string.</summary>
    function getOption: string;

    /// <summary>Setter for the option string.</summary>
    procedure setOption(const Option: string);
  public
    
    /// <summary>Default string/option for the option.</summary>
    DefaultString: string;
    /// <summary>A list of possible options.</summary>
    OptionList: TStringList;

    /// <summary>Initializes the option with a name, default value, and comment.</summary>
    constructor create(name: string; Default: string; c: string);
    destructor Destroy; override;
  published

    /// <summary>Property to access the option string.</summary>
    property Option: string read getOption write setOption;

  end;

  /// <summary>THumeNumEntity is a base class for numerical entities in the model, such as variables and external values.</summary>
  /// <remarks>Extends THumeEntity with properties for numerical values, units, and flags for plotting and output.</remarks>
  THumeNumEntity = class(THumeEntity)

  private
    /// <summary>Number of digits.</summary>
    FDigits: integer;
    /// <summary>Number of digits after the decimal separator.</summary>
    FPrecision: integer;
    /// <summary>Getter for the numerical value.</summary>
    function get_value: real; virtual;
    /// <summary>Setter for the numerical value.</summary>
    procedure set_value(value: real); virtual;
  public
    /// <summary>Private field with numerical value of the entity.</summary>
    fv: real;
    /// <summary>Units of the numerical value.</summary>
    U { nits }: string;

    /// <summary>Default value for parameters or states (initial value).</summary>
    DefaultValue: real;
    /// <summary>Flag for graphical output.</summary>
    PlotToGraph: boolean;
    /// <summary>Flag for selection to global output file.</summary>
    fGlobalOutput:boolean;
    /// <summary>Flag for extra output of final values in file.</summary>
    WriteFinalValue: boolean;
    /// <summary>Flag indicating if measured data are available.</summary>
    IsMeasured: boolean;
    /// <summary>Writes the declaration code for the entity into a source code file.</summary>
    procedure write_declaration(var f: textfile);
    /// <summary>Writes the property code for the entity into a source code file.</summary>
    procedure write_property(var f: textfile);
    /// <summary>Writes the creation code for the entity into a source code file.</summary>
    procedure write_Create(var f: textfile); virtual;

  published
    constructor create;
    /// <summary>Property for optional plotting to graph.</summary>
    property Opt_PlotToGraph: boolean read PlotTograpH write PlotTograpH;

    /// <summary>Property for the optional output of final values.</summary>
    property Opt_WriteFinalValue
      : boolean read WriteFinalValue write WriteFinalValue;

    /// <summary>Property for the digits used in output.</summary>
    /// <remarks>Default is 2 digits.</remarks>
    property Digits: integer read FDigits write FDigits;

    /// <summary>Property for the precision of the numerical value.</summary>
    property Precision: integer read FPrecision write FPrecision;

    /// <summary>Property for the flag indicating if the entity is written to a global output file.</summary>
    property GlobalOutput: boolean read fGlobalOutput write fGlobalOutput;

    /// <summary>Property for the numerical value of the entity.</summary>
    property v: real read get_value write set_value;

  end;

  /// <summary>TVar is a class representing a variable, i.e. a value that can be calculated for each time step in the model from other variables, state variables or parameters.</summary>
  /// <remarks>Extends THumeNumEntity and provides methods for automatic source code generation for initialization and rate calculation.</remarks>
  TVar = class(THumeNumEntity)
  private
    function get_value: real; override;
    procedure set_value(value: real); override;

  public
    /// <summary>String containing source code for rate calculation.</summary>
    RateSTring: string;
    /// <summary>String containing source code for initialization.</summary>
    IniString: String;
    procedure write_Create(var f: textfile); override;
    procedure write_Init(var f: textfile);
    procedure write_Rate(var f: textfile);
    procedure write_RInit(var f: textfile);
    procedure write_RRate(var f: textfile);
  published
    /// <summary>Creates a variable with name, units, value and comment.</summary>
    /// <param name="na">Name of the variable.</param>
    /// <param name="un">Units of the variable.</param>
    /// <param name="va">Initial value of the variable.</param>
    /// <param name="c">Comment or description.</param>
    constructor create(na, un: string; va: real; c: string);
  end;

  /// <summary>TPar is a class representing a parameter variable in the model, which can be selected for optimization or sensitivity analysis.</summary>
  /// <remarks>Extends TVar and adds properties for maximum and minimum expected values, error, and selection flags.</remarks>

  TPar = class(TVar)
  private
    /// <summary>Maximum expected value (added 12.01.05 for GA optimisation).</summary>
    fmax: real;
    /// <summary>Minimum expected value.</summary>
    fmin: real;

    public

    /// <summary>Selected for optimization?</summary>
    SelForOpt: boolean;

    /// <summary>Selected for sensitivity analysis?</summary>
    SelForSens: boolean;

    /// <summary>Uncertainty value.</summary>
    error: real;

  public
    
    /// <summary>Creates a parameter with name, units, value, error and comment.</summary>
    /// <param name="na">Name of the parameter.</param>
    /// <param name="un">Units of the parameter.</param>
    /// <param name="va">Initial value of the parameter.</param>
    /// <param name="error">Uncertainty value.</param>
    /// <param name="c">Comment or description.</param>
    constructor create(na, un: string; va, error: real; c: string);
  published
    /// <summary>Property for selection for sensitivity analysis.</summary>
    property opt_SelForSens: boolean read SelForSens write SelForSens;
    property max:real read fmax write fmax;
    property min:real read fmin write fmax;

  end;

  /// <summary>TState is a class representing a state variable in the model, which has an initial value and a rate of change.</summary>
  /// <remarks>Extends TVar and provides a constructor for creating state variables with initial value, change rate, and comment.</remarks>
  TState = class(TVar)

  public
    /// <summary>Initial value.</summary>
    iv : real;
    /// <summary>Change rate of state variable.</summary>
    c { hange }: real;


    /// <summary>Creates a state variable with name, units, initial value, change rate and comment.</summary>
    /// <param name="na">Name of the state variable.</param>
    /// <param name="un">Units of the state variable.</param>
    /// <param name="va">Initial value.</param>
    /// <param name="cr">Change rate.</param>
    /// <param name="comm">Comment or description.</param>
    constructor create(na, un: string; va, cr: real; comm  : string);

  end;

  /// <summary>TExternV is a class representing an external variable in the model. Values of model elements outside a submodel are called "external variables" and can be accessed via pointers.</summary>
  /// <remarks>The default method for setting the link to the external variable is to search for it in the model by its name. Extends THumeNumEntity and provides methods for getting and setting the value, as well as creating the external variable with a name, units, and an external value type.</remarks>
  TExternV = class(THumeNumEntity)

  private
    /// <summary>Indicates if the external variable is searched for in the model. If not, it is assumed to be set by connecting two submodels by a direct link.</summary>
    fSearch: boolean;

    /// <summary>External value type.</summary>
    f_Ex: TExValue;

    /// <summary>Conversion factor.</summary>
    Conversion_f: real;

    /// <summary>Source of the external variable, e.g. a file or a submodel.</summary>
    fSource: string;

    /// <summary>Getter for the numerical value of the external variable.</summary>
    function get_value: real; override;
    /// <summary>Setter for the numerical value of the external variable.</summary>
    procedure set_value(value: real); override;

  public
    F_N: string;
    f_v: ^real;

    /// <summary>Creates an external variable with a name, units, external value type, and comment.</summary>
    /// <param name="Nname">Name of the external variable.</param>
    /// <param name="NUnits">Units of the external variable.</param>
    /// <param name="ExV">Type of external value.</param>
    /// <param name="c">Comment or description.</param>
    constructor create(Nname, NUnits: string; ExV: TExValue; c: string);
    // function v:real;
    // function get_value:real;
    procedure setPointer(NewPointer: Pointer);
  published
    /// <summary>Type of external value.</summary>
    property Ex: TExValue read f_Ex write f_Ex;
    /// <summary>Flag indicating if the external variable is searched for in the model.</summary>
    property Search: boolean read fSearch write fSearch;
    /// <summary>Conversion factor.</summary>
    property C_f: real read Conversion_f write Conversion_f;
    /// <summary>Source of the external variable.</summary>
    property Source: string read fSource write fSource;
    // property Link : THumeEntity read f_link;

  end;


implementation

uses
  UModUtils;

constructor TOption.create(name: string; Default: string; c: string);

begin
  inherited create; // call THumeEntity.create
  OptionList := TStringList.create;
  N := del_blank(name); // Name
  Option := default; // Value
  DefaultString := default;
  ReadFromIniFile := true; // read from Ini file
  WriteToFile := true;
  WriteToIniFile := true;
  Comment := c;
end;



destructor TOption.Destroy;
begin
  OptionList.Free;
  inherited;
end;

constructor THumeNumEntity.create;
begin
  inherited;
  IsMeasured := false;
  fGlobalOutput := false;
end;


/// <summary>Instantiates a variable object.</summary>
/// <param name="na">Name of the variable.</param>
/// <param name="un">Units of the variable.</param>
/// <param name="va">Floating point value.</param>
/// <param name="c">Comment or explanation string.</param>
constructor TVar.create(na, un: string; va: real; c: string);

begin
  inherited create; // call THumeEntity.create
  N := del_blank(na); // Name
  U := del_blank(un); // Units
  v := va; // Value
  DefaultValue := va;
  ReadFromIniFile := false; // do not read from Ini file
  WriteToFile := true;
  WriteToIniFile := true;
  SelForSensOut := false;
  WasReadFromFile := false;
  WriteFinalValue := false;
  Comment := c;
  FDigits := 2;
  FPrecision := 6;
end;

function THumeNumEntity.get_value: real;

begin
  result := fv;
end;

procedure THumeNumEntity.set_value(value: real);
begin
  fv := value;

end;

procedure THumeNumEntity.write_declaration;

begin
  if Indexed = false then
    writeln(f, '  ', Name, ' : ', ClassName, ';   // ', Comment)
  else
    writeln(f, '  ', Name, '[', inttostr(lowerbound), '..',
      inttostr(upperbound), ']', ' : ', ClassName, ';   // ', Comment)
end;

procedure THumeNumEntity.write_property;

var
  ID_str: string;
begin
  if ClassName = 'TVar' then
    ID_str := 'Var_'
  else if ClassName = 'TState' then
    ID_str := 'St_'
  else if ClassName = 'TPar' then
    ID_str := 'Par_'
  else if ClassName = 'TExternV' then
    ID_str := 'Ex_'
  else if ClassName = 'TOption' then
    ID_str := 'Opt_';

  writeln(f, '  Property ', ID_str, Name, ' : ', ClassName, ' read ', name,
    ' write ', name, ';');
end;

procedure THumeNumEntity.write_Create;

begin
  writeln(f, '  ExternVCreate(''', Name, ''', ''', U, ''',', 'statefield, ',
    Name, ');');
  // writeln(f, '  ExternVCreate(''', Name, ''', ''', Units, ''',', floattostrf(v, ffgeneral,6,3), ', true, ', Name,');  ');
end;

function TVar.get_value: real;
begin
  result := fv;
end;

procedure TVar.set_value(value: real);

begin
  fv := value;
end;

procedure TVar.write_Create;

begin
  if not Indexed then begin
    if ClassName = 'TVar' then
      writeln(f, '  VarCreate(''', Name, ''', ''', Units, ''',',
        floattostrf(v, ffgeneral, 6, 3), ', true, ', Name, ', ''', Comment,
        ''');  ')
    else if ClassName = 'TState' then
      writeln(f, '  StateCreate(''', Name, ''', ''', Units, ''',',
        floattostrf(v, ffgeneral, 6, 3), ', true,', Name, ', ''', Comment,
        ''');')
    else if ClassName = 'TPar' then
      writeln(f, '  ParCreate(''', Name, ''', ''', Units, ''',',
        floattostrf(v, ffgeneral, 6, 3), ',', Name, ', ''', Comment, ''');')
    else if ClassName = 'TexternV' then
      writeln(f, '  ExternVCreate(''', Name, ''', ''', Units, 'statefield',
        Name, ', ''', Comment, ''');')
    else if ClassName = 'TOption' then
      writeln(f, '  OptCreate(''', Name, ''', ''', Name, ');');
  end else begin
    writeln(f, '  for i := ', inttostr(lowerbound), ' to ',
      inttostr(upperbound), ' do');
    if ClassName = 'TVar' then
      writeln(f, '    VarCreate(''', Name, '_', '''', '+', 'inttostr(i)', ',',
        '''', Units, '''', ',', '0.0, true, ', Name, '[i]);  ')
    else if ClassName = 'TState' then
      writeln(f, '    StateCreate(''', Name, '_', '''', '+', 'inttostr(i)',
        ',', '''', Units, '''', ',', '0.0, true, ', Name, '[i]);  ')
    else if ClassName = 'TPar' then
      writeln(f, '    ParCreate(''', Name, '_', '''', '+', 'inttostr(i)', ',',
        '''', Units, '''', ',', '0.0, true, ', Name, '[i]);  ')
    else if ClassName = 'TexternV' then
      writeln(f, '    ExternVCreate(''', Name, '_', '''', '+', 'inttostr(i)',
        ',', '''', Units, '''', ',', 'Statefield', Name, '[i]);  ')
    else if ClassName = 'TOption' then
      writeln(f, '    OptCreate(''', Name, '_', '''', '+', 'inttostr(i)', ',',
        '''', '', '''', Name, '[i]);  ');

  end;
end;

procedure TVar.write_Init;

begin
  if ClassName = 'TState' then
    writeln(f, '  ', name, '.v := ', IniString, ';')
  else if ClassName = 'TVar' then
    writeln(f, '  ', name, '.v := ', RateSTring, ';');
end;


procedure TVar.write_RInit;

begin
  if ClassName = 'TState' then
    writeln(f, '  ', name, ' <- ', IniString)
  else if ClassName = 'TVar' then
    writeln(f, '  ', name, ' <- ', RateSTring);
end;




procedure TVar.write_Rate;

begin

  if ClassName = 'TVar' then
    writeln(f, '  ', { name, '.v := ', } RateSTring, ';')
  else if ClassName = 'TState' then
    writeln(f, '  ', { name, '.c := ', } RateSTring, ';');

end;




procedure TVar.write_RRate;

begin

  if ClassName = 'TVar' then
    writeln(f, '  ', { name, ' <- ', } RateSTring)
  else if ClassName = 'TState' then
    writeln(f, '  ', { name, 'c <- ', } RateSTring);

end;



/// <summary>Instantiates a parameter object.</summary>
/// <param name="na">Name of the parameter.</param>
/// <param name="un">Units of the parameter.</param>
/// <param name="va">Initial value.</param>
/// <param name="error">Error value.</param>
/// <param name="c">Comment or description.</param>
constructor TPar.create(na, un: string; va, error: real; c: string);

begin
  inherited create(na, un, va, c); // call TVar.create
  WriteToFile := false;
  SelForOpt := false; // can be selected later for optimization
  self.SelForOpt := false; // can be selected for sensitivity analysis
  ReadFromIniFile := true; // read from Ini file
  if va > 0 then
    min := 0.0
  else min := va-100*va;
  if va > 0 then
    max := 100*va
  else max := 0;


end;

/// <summary>Instantiates a state variable object.</summary>
/// <param name="na">Name of the state variable.</param>
/// <param name="un">Units of the state variable.</param>
/// <param name="va">Initial value.</param>
/// <param name="cr">Rate of change.</param>
/// <param name="comm">Comment or description.</param>
constructor TState.create(na, un: string; va, cr: real; comm: string);

begin
  inherited create(na, un, va, comm); // call TVar.create
  c := cr;
  ReadFromIniFile := true; // read from Ini file
end;

/// <summary>Instantiates an external variable object.</summary>
/// <param name="Nname">Name of the external variable.</param>
/// <param name="NUnits">Units of the external variable.</param>
/// <param name="ExV">Type of external value.</param>
/// <param name="c">Comment or description.</param>
constructor TExternV.create(Nname, NUnits: string; ExV: TExValue; c: string);

begin
  inherited create; // call THumeEntity.create
  Name := Nname;
  Units := NUnits;
  Ex := ExV;
  Conversion_f := 1;
  WriteToFile := true;
  fSearch := true;
  Comment := c;
end;

  { function TExternV.v:real;

  begin
  If f_v <> nil then
  result := f_v^*Conversion_f
  else begin
  result := 0.0 ;
  // showmessage('error');
  end;
  end; }

function TExternV.get_value;

begin
  if f_v <> nil then
    result := f_v^ * Conversion_f
  else begin
    result := 0.0;
    // showmessage('Error: Wert von '+Name+' nicht verf�gbar');
  end;

end;

procedure TExternV.set_value(value: real);
begin
  if f_v <> nil then
    f_v^ := value;
end;

/// <summary>Set pointer of the "value" variable.</summary>
/// <param name="NewPointer">Pointer to the external value.</param>
procedure TExternV.setPointer(NewPointer: Pointer);
begin
  if NewPointer <> nil then
    f_v := NewPointer
  else
    {$IFNDEF NONVISUAL}
    ShowMessage('Error during Pointer-Initalisation of: ' + self.name);
    {$ENDIF}
end;

function TOption.getOption;
begin
  result := lowercase(fOption);
end;

procedure TOption.setOption;
begin
  fOption := lowercase(Option);
end;

end.

