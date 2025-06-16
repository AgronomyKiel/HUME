///<unit>
///  <name>UState</name>
///  <summary>
///    Defines core data types and classes for representing state variables, parameters, and external variables in a crop simulation model.
///    Provides a standardized way to handle variables that change over time (states), fixed model parameters, and variables imported from other modules or the environment.
///  </summary>
///  <details>
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
///  </details>
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
 /// setting all floating points to double as a standard  
  real = double;    

/// enumeration type to for pointer, imortan for external state variables and external values, where the name of a state variable can mean either the state or the rate of change
 TExValue = (RateField, StateField); 

  {* -----------------------------------------------------------------
    CLASS     THumeEntity
    ANCESTOR  TPersistent
    PURPOSE   Abstracted basic class for TVar and TExternV,
    provides basic funtionality for variables (parameters,
    state variables) and external "driving forces"
    ------------------------------------------------------------------ }

  {$IFDEF NONVISUAL}
  THumeEntity = class(TObject)
  {$ELSE}

 /// <summary> THumeEntity is the base class for all objects representing either numerical values (states, variables, parameters, constants) or Options.
 /// If the destination is a console app it is derived from TObject.
 /// For the use of within the IDE/GUI applications it is derived from the TPersistent class. </summary>
   THumeEntity = class(TPersistent)
  {$ENDIF}

  private
    /// Name field
    N { ame }: string;
    /// Field for comments/explanation
    FComment: string;
    /// private field for the name of the Entity
    fName: string;
    /// field submodel to which the Entity belongs
    fSubmod: string;
    /// field documentation link
    fDocuWebLink: string;
  public
    /// units of the entity
    U { nits }: string;
    /// indicates if the entity is indexed (array)
    Indexed: boolean;
    /// lower bound for indexed entities
    lowerbound: integer;
    /// upper bound for indexed entities
    upperbound: integer;
    /// flag for initialisation from file
    ReadFromIniFile: boolean;
    /// flag for output to text file
    WriteToFile: boolean;
    /// flag for output to Ini file
    WriteToIniFile: boolean;
    /// flag for selection for output
    SelForSensOut : boolean;
    /// flag for initialisation from file, false indicates need for alternative initialisation
    WasReadFromFile: boolean;
  published
    /// Name of the object
    property Name: string read N write N;  
    /// Name of the submodule
    property SubModName: string read fSubmod write fSubmod; 
    /// Comment or description
    property Comment: string read FComment write FComment;
    /// DocuWebLink
    property DocuWebLink: string read fDocuWebLink write fDocuWebLink;
    /// Flag indicating whether to write output to a text file
    property Opt_writetoFile: boolean read WriteToFile write WriteToFile;
    /// Flag indicating selection for sensitivity analysis output
    property Opt_SelForSensOut : boolean read SelForSensOut write SelForSensOut; 
    /// Units associated with the object
    property Units: string read U write U; 
  end;

/// <summary> TOption is a class representing an option with a string value and a list of possible options. </summary>
  TOption = class(THumeEntity)
  private
    /// the private field for the option string
    fOption: string;
    
    /// getter for the option string
    function getOption: string;

    /// setter for the option string
    procedure setOption(const Option: string);
  public
    
    /// default string/option for the option
    DefaultString: string;
    /// a list of possible options
    OptionList: TStringList;
    
    /// the constructor initializes the option with a name, default value, and comment
    constructor create(name: string; Default: string; c: string);
    destructor Destroy; override;
  published

    /// property to access the option string
    property Option: string read getOption write setOption;

  end;

  {* -----------------------------------------------------------------
    CLASS     THumeNumEntity
    ANCESTOR  TPersistent
    PURPOSE   Abstracted basic class for TVar and TExternV,
    provides basic funtionality for variables (parameters,
    state variables) and external "driving forces"
    ------------------------------------------------------------------ }

/// <summary> THumeNumEntity is a base class for numerical entities in the model, such as variables and external values.
/// It extends THumeEntity with properties for numerical values, units, and flags for plotting and output. </summary>
  THumeNumEntity = class(THumeEntity)

  private
    /// number of digits
    FDigits: integer;
    /// number of after comma digits
    FPrecision: integer;
    /// getter for the numerical value
    function get_value: real; virtual;
    /// setter for the numerical value
    procedure set_value(value: real); virtual;
  public
    /// private field with numerical value of the entity
    fv: real;
    /// units of the numerical value
    U { nits }: string;

    /// default value for parameters, states (Ini value)
    DefaultValue: real;
    /// flag for graphical output
    PlotToGraph: boolean;
    /// flag for selection to global output file
    fGlobalOutput:boolean;
    /// flag for extra output of final values in file
    WriteFinalValue: boolean;
    /// flag if measured data are available
    IsMeasured: boolean;
    /// writes the declaration code for entity into source code file
    procedure write_declaration(var f: textfile);
    /// writes the property code for entity into source code file
    procedure write_property(var f: textfile);
    /// writes the creation code for entity into source code file
    procedure write_Create(var f: textfile); virtual;

  published
    constructor create;
    /// property for optional plotting to graph
    property Opt_PlotToGraph: boolean read PlotTograpH write PlotTograpH;
    
    /// property for the optional output of final values
    property Opt_WriteFinalValue
      : boolean read WriteFinalValue write WriteFinalValue;
    
    /// property for the digits used in output
    /// (default is 2 digits)
    property Digits: integer read FDigits write FDigits;
    
    /// property for the precision of the numerical value
    property Precision: integer read FPrecision write FPrecision;

    /// property for the flag indicating if the entity is written to a global output file
    property GlobalOutput: boolean read fGlobalOutput write fGlobalOutput;
    
    /// property for the numerical value of the entity
    property v: real read get_value write set_value;

  end;

  {* -----------------------------------------------------------------
    CLASS     TVar
    ANCESTOR  THumeEntity
    PURPOSE   Model variables, therefore enhanced by "value" element.
    Basic class for TPar and TState.
    ------------------------------------------------------------------ }

/// <summary> TVar is a class representing a variable, i.e. a value that can be calculated for each time step in the model from other variables, state variables or parameters.
/// It extends THumeNumEntity and provides methods for self writing of source code for its initialization, rate calculation. </summary>
  TVar = class(THumeNumEntity)
  private
    function get_value: real; override;
    procedure set_value(value: real); override;

  public
    /// String containing source code for rate calculation
    RateSTring: string;
    /// String containing source code for intialisation
    IniString: String;
    procedure write_Create(var f: textfile); override;
    procedure write_Init(var f: textfile);
    procedure write_Rate(var f: textfile);
    procedure write_RInit(var f: textfile);
    procedure write_RRate(var f: textfile);
  published
  /// constructor procedure to create a variable with name, units, value and comment
    constructor create(na, un: string; va: real; c: string);
  end;

  {* -----------------------------------------------------------------
    CLASS     TPar
    ANCESTOR  TVar
    PURPOSE   Parameter variable, therefore enhanced by "error" element
    and an option flag for optimization.
    ------------------------------------------------------------------ }

/// <summary> TPar is a class representing a parameter variable in the model, which can be selected for optimization or sensitivity analysis.
/// It extends TVar and adds properties for maximum and minimum expected values, error, and selection flags. </summary>

  TPar = class(TVar)
  private
    /// maximum expected value added 12.01.05 for GA optimisation   hk
    fmax: real;
    /// minimum expected value
    fmin: real;

    public
    
    /// selected for optimization?
    SelForOpt: boolean;
    
    /// selected for sensitivity analysis?
    SelForSens: boolean;
    
    /// uncertainty value
    error: real;

  public
    
    /// constructor procedure to create a parameter with name, units, value, error and comment
    constructor create(na, un: string; va, error: real; c: string);
  published

  /// property for selectgion for sensitivity analysis
    property opt_SelForSens: boolean read SelForSens write SelForSens;
    property max:real read fmax write fmax;
    property min:real read fmin write fmax;

  end;

  {* -----------------------------------------------------------------
    CLASS     TState
    ANCESTOR  TVar
    PURPOSE   State variable, therefore enhanced by "rate of change" element
    ------------------------------------------------------------------ }

/// <summary> TState is a class representing a state variable in the model, which has an initial value and a rate of change.
/// It extends TVar and provides a constructor for creating state variables with initial value, change rate, and comment. </summary>
  TState = class(TVar)

  public
    /// initial value
    iv : real;
    /// change rate of state variable
    c { hange }: real;


    /// constructor procedure to create a state variable with name, units, initial value, change rate and comment
    constructor create(na, un: string; va, cr: real; comm  : string);

  end;

  {* -----------------------------------------------------------------
    CLASS     TExternV
    ANCESTOR  THumeEntity
    PURPOSE
    ------------------------------------------------------------------ }

/// <summary> TExternV is a class representing an external variable in the model. Values of model elements outside a submodel are called "external variables". They can be made accessible by adressing a pointer for that value.
/// The default method for setting the link to the external variable is to search for it in the model by its name.
/// It extends THumeNumEntity and provides methods for getting and setting the value, as well as creating the external variable with a name, units, and an external value type. </summary>
  TExternV = class(THumeNumEntity)

  private
  /// private field indicating if the external variable is searched for in the model
  /// if not, it is assumed to be set by connecting two submodels by a direct link
    fSearch: boolean;

 /// private field external value   
    f_Ex: TExValue;

 /// private field for conversion factor   
    Conversion_f: real;

/// <summary> private field for the source of the external variable, e.g. a file or a submodel </summary>    
    fSource: string;

/// getter for the numerical value of the external variable
    function get_value: real; override;
/// setter for the numerical value of the external variable    
    procedure set_value(value: real); override;

  public
    F_N: string;
    f_v: ^real;

    constructor create(Nname, NUnits: string; ExV: TExValue; c: string);
    // function v:real;
    // function get_value:real;
    procedure setPointer(NewPointer: Pointer);
  published
    property Ex: TExValue read f_Ex write f_Ex;
    property Search: boolean read fSearch write fSearch;
    property C_f: real read Conversion_f write Conversion_f;
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


{*------------------------------------------------------------------------------
  CLASS   TVar
  METHOD  create
  PURPOSE Instantiates Variable object

   @param na  Name of Variable
   @param un  Units of Variable
   @param va  Floating point value
   @param c   Comment/Explanation string
 -------------------------------------------------------------------------------}

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



{* *****************************************************************
  CLASS   TPar
  METHOD  create
  PURPOSE Instantiates Parameter object
  INPUT   na,          // Name
  un: string;  // Units
  va,          // Value
  error: real  // Error
  ****************************************************************** }

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

{* *****************************************************************
  CLASS   TState
  METHOD  create
  PURPOSE Instantiates state variable object
  INPUT   na,          // Name
  un: string;  // Units
  va,          // Value
  cr: real     // Rate of change
  ****************************************************************** }

constructor TState.create(na, un: string; va, cr: real; comm: string);

begin
  inherited create(na, un, va, comm); // call TVar.create
  c := cr;
  ReadFromIniFile := true; // read from Ini file
end;

{* *****************************************************************
  CLASS   TExternV
  METHOD  create
  PURPOSE Instantiates external variable object
  INPUT   Nname, Nunits :string; ExV: TExValue
  ****************************************************************** }

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

{* *****************************************************************
  CLASS   TExternV
  METHOD  v
  PURPOSE Delivers external "value" result
  OUTPUT  real
  ****************************************************************** }

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

{* *****************************************************************
  CLASS   TExternV
  METHOD  SetPointer
  PURPOSE Set pointer of "value" variable
  INPUT   NewPointer:Pointer
  ****************************************************************** }

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

