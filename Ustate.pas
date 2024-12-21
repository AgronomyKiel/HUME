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
  real = double;     /// setting all floating points to double as a standard

  TExValue = (RateField, StateField); /// enumeration type to for pointer

  {* -----------------------------------------------------------------
    CLASS     THumeEntity
    ANCESTOR  TPersistent
    PURPOSE   Abstracted basic class for TVar and TExternV,
    provides basic funtionality for variables (parameters,
    state variables) and external "driving forces"
    ------------------------------------------------------------------ }

  {$IFDEF NONVISUAL}
  // if the destination is a console app ...
  THumeEntity = class(TObject)
  {$ELSE}
 // if it is used for compilation of a vcl app
  THumeEntity = class(TPersistent)
  {$ENDIF}

  private
    N { ame }: string;  /// Name field
    FComment: string;   /// Field for comments/explanation
    fSubmod: string;    /// field submodel to which the Entity belongs
  public
    Indexed: boolean;
    lowerbound, upperbound: integer;
    U { nits }: string;    /// units of values
    ReadFromIniFile: boolean; /// flag for initialisation from file
    WriteToFile: boolean;  /// flag for output to text file
    WriteToIniFile: boolean;  /// flag for output to Ini file
    SelForSensOut : boolean;  /// flag for selection for output
    WasReadFromFile: boolean; /// flag for initialisation from file, false indicates need for alternative initialisation
  published
    property Name: string read N write N;    /// name property
    property SubModName: string read fSubmod write fSubmod;  /// name of submod
    property Comment: string read FComment write FComment;  /// comment
    property Opt_writetoFile: boolean read WriteToFile write WriteToFile;
    property Opt_SelForSensOut : boolean read SelForSensOut write SelForSensOut;
    property Units: string read U write U;
  end;

  TOption = class(THumeEntity)
  private
    fOption: string;
    function getOption: string;
    procedure setOption(const Option: string);
  public
    DefaultString: string;
    OptionList: TStringList;
    constructor create(name: string; Default: string; c: string);
    destructor Destroy; override;
  published
    property Option: string read getOption write setOption;

  end;

  {* -----------------------------------------------------------------
    CLASS     THumeNumEntity
    ANCESTOR  TPersistent
    PURPOSE   Abstracted basic class for TVar and TExternV,
    provides basic funtionality for variables (parameters,
    state variables) and external "driving forces"
    ------------------------------------------------------------------ }

  THumeNumEntity = class(THumeEntity)

  private
    FDigits: integer;      /// number of digits
    FPrecision: integer;   /// number of after comma digits
    function get_value: real; virtual;
    procedure set_value(value: real); virtual;
  public
    fv: real;
    U { nits }: string;

    DefaultValue: real;    /// default value for parameters, states (Ini value)
    PlotToGraph: boolean;  /// flag for graphical output
    fGlobalOutput:boolean; /// flag for selection to global output file
    WriteFinalValue: boolean;  /// flag for extra output of final values in file
    IsMeasured: boolean;      ///  flag if measured data are available
    procedure write_declaration(var f: textfile);
    procedure write_property(var f: textfile);
    procedure write_Create(var f: textfile); virtual;

  published
    constructor create;
    property Opt_PlotToGraph: boolean read PlotTograpH write PlotTograpH;
    property Opt_WriteFinalValue
      : boolean read WriteFinalValue write WriteFinalValue;
    property Digits: integer read FDigits write FDigits;
    property Precision: integer read FPrecision write FPrecision;
    property GlobalOutput: boolean read fGlobalOutput write fGlobalOutput;
    property v: real read get_value write set_value;

  end;

  {* -----------------------------------------------------------------
    CLASS     TVar
    ANCESTOR  THumeEntity
    PURPOSE   Model variables, therefore enhanced by "value" element.
    Basic class for TPar and TState.
    ------------------------------------------------------------------ }

  TVar = class(THumeNumEntity)
  private
    function get_value: real; override;
    procedure set_value(value: real); override;

  public
    RateSTring: string; /// String containing source code for rate calculation
    IniString: String;  /// String containing source code for intialisation
    procedure write_Create(var f: textfile); override;
    procedure write_Init(var f: textfile);
    procedure write_Rate(var f: textfile);
    procedure write_RInit(var f: textfile);
    procedure write_RRate(var f: textfile);
  published
    constructor create(na, un: string; va: real; c: string);
  end;

  {* -----------------------------------------------------------------
    CLASS     TPar
    ANCESTOR  TVar
    PURPOSE   Parameter variable, therefore enhanced by "error" element
    and an option flag for optimization.
    ------------------------------------------------------------------ }

  TPar = class(TVar)
  private
    fmax: real; /// maximum exptected value added 12.01.05 for GA optimisation   hk
    fmin: real; /// minimum expected value

  public
    SelForOpt: boolean;    /// selected for optimization?
    SelForSens: boolean;   /// selected for sensitivity analysis?
    error: real;           /// uncertainty value

  public
    constructor create(na, un: string; va, error: real; c: string);
  published
    property opt_SelForSens: boolean read SelForSens write SelForSens;
    property max:real read fmax write fmax;
    property min:real read fmin write fmax;

  end;

  {* -----------------------------------------------------------------
    CLASS     TState
    ANCESTOR  TVar
    PURPOSE   State variable, therefore enhanced by "rate of change" element
    ------------------------------------------------------------------ }

  TState = class(TVar)

  public
    iv : real; /// initial value
    c { hange }: real;    /// change rate of state variable
    constructor create(na,  //name
     un: // unit
     string;
      va, // value
       cr: real;
        comm // comment
        : string);

  end;

  {* -----------------------------------------------------------------
    CLASS     TExternV
    ANCESTOR  THumeEntity
    PURPOSE
    ------------------------------------------------------------------ }

  TExternV = class(THumeNumEntity)

  private
    fSearch: boolean;
    f_Ex: TExValue;
    Conversion_f: real;
    fSource: string;

    function get_value: real; override;
    procedure set_value(value: real); override;

  public
    F_N: string;
    Units: string;
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

  Struct1 = record
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

