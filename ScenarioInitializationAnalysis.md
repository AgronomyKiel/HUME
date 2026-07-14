# HUME scenario initialization analysis

## Purpose

This document records an initial analysis of possible runtime improvements for batches of HUME simulations. It also sketches a backward-compatible in-memory scenario representation based on `TScenarioDefinition`.

The analysis is preliminary. It should be validated with timing measurements before architectural changes are implemented.

## Summary

There is significant potential to reduce the runtime of batches containing many short simulations. The main opportunity is not specifically the choice between INI, JSON, or XML. HUME already uses `TMemIniFile` in important initialization paths, and the main scenario INI files listed by a control file are loaded into memory.

The larger opportunity is to parse, validate, and prepare scenario data once, then reuse immutable data across simulation runs. JSON or XML could be added as consolidated input formats, but they should feed the same internal scenario representation as the existing control-file and INI sequence.

For long, computationally intensive simulations, initialization may only account for a small part of total runtime. For sensitivity analyses, parameter searches, Monte Carlo analyses, and other batches with hundreds or thousands of relatively short runs, initialization overhead may be substantial.

## Observations from the current implementation

The relevant implementation is primarily in `UMod.pas` and `UTextFileH.pas`.

### Existing in-memory INI handling

`TMyIniFile` is currently declared as `TMemIniFile`. When `TMod.ReadOrCreateInifiles` reads a legacy `*.fn` control file, it creates and stores a `TMemIniFile` instance for each listed main INI file.

This means that merely replacing the main INI syntax with JSON or XML would not automatically produce a large performance improvement.

### Repeated parameter, state, and option parsing

For each simulation, `TMod.Init` calls the routines that determine the parameter, state, and option filenames. `TMod.CreateIniFiles` then frees and recreates the corresponding `TMemIniFile` objects.

Consequently, these referenced files are parsed again for every scenario initialization, even where several scenarios reference the same files.

### Repeated weather-file loading

`TMod.Init` calls `WeatherFile.Init` for every run. `TTextFileH.Init` clears its current contents and calls `LoadFromFile`, loading the complete weather file again.

Weather data is a good candidate for a shared immutable cache keyed by canonical filename and, optionally, file modification time.

### Repeated measurement and update-file loading

Measurement files are loaded during submodel initialization. They appear to be loaded again when data series are initialized. Update files are also loaded during each submodel initialization.

These inputs can also be cached, provided each simulation receives its own cursor or current-position state while sharing immutable table contents.

### INI writes during initialization

Options are written to the option INI during submodel initialization, followed by `UpdateFile`. At the end of a simulation, parameter, state, option, and property INI objects are flushed.

For batch execution, writes should ideally be collected in memory and performed only when values have changed and write-back is explicitly required. Input files should normally be treated as immutable during a batch.

### Other repeated work

Additional candidates for investigation include:

- the first scenario being initialized before the main run loop and then initialized again inside the loop;
- repeated sorting of submodel and model-element lists;
- repeated output filename and directory preparation;
- repeated conversion of textual parameter and state values;
- continuous and final output costs, which may exceed initialization costs in output-intensive simulations.

## Recommended architecture

The file format should be separated from the internal representation:

```text
Legacy *.fn and INI files --+
JSON batch document --------+--> TScenarioDefinition --> TMod initialization
XML batch document ---------+            |
                                         +--> shared resource cache
                                              weather data
                                              measurements
                                              update tables
```

The proposed responsibilities are:

- `TScenarioDefinition` contains the complete normalized input for one simulation.
- `TScenarioValues` provides case-insensitive section/key access to raw values.
- A legacy loader reads the existing `*.fn` -> main INI -> parameter/state/option INI sequence.
- Future JSON and XML loaders populate the same structure.
- A resource cache shares immutable weather, measurement, and update data.
- Mutable model states, file cursors, result data, and output writers remain private to each simulation.

## Backward-compatibility requirements

The legacy loader should preserve:

- existing control files and INI files without requiring conversion;
- existing section and key names;
- case-insensitive lookup;
- UTF-8 handling currently used by HUME;
- default-value semantics;
- current relative-path interpretation;
- handling of duplicate entries in control files;
- existing output and optional write-back behavior where requested.

One particularly important issue is path resolution. The current implementation depends partly on the HUME working directory. Resolving every referenced file relative to its main INI file would be cleaner, but it could change the meaning of existing projects. A legacy base directory should therefore be supplied explicitly during migration.

The current implementation can create missing parameter, state, and option files and insert defaults. That mutation should be retained in a separate legacy preparation or compatibility layer. `TScenarioDefinition` itself should preferably describe input and should not silently modify source files.

## Suggested implementation sequence

1. Add high-resolution timing around control-file loading, `TMod.Init`, submodel initialization, data-file loading, the timestep loop, and output processing.
2. Remove demonstrably duplicate initialization and unnecessary `UpdateFile` calls.
3. Cache weather, measurement, and update-file contents by canonical filename.
4. Introduce `TScenarioValues` and `TScenarioDefinition` while continuing to use the existing INI files.
5. Introduce a small reader interface so model initialization is independent of `TMemIniFile`.
6. Add an optional consolidated JSON format if it improves batch management or external integration.
7. Add XML only if required for interoperability or schema-based validation.
8. Compare complete batch runtimes and verify numerical and output compatibility against the legacy route.

## Delphi code sketch

The following code is an architectural sketch rather than a finished production unit. Error reporting, legacy default-file creation, logging, thread safety, and exact Boolean/number parsing semantics would need to be finalized during implementation.

```pascal
unit UScenarioDefinition;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  System.IniFiles;

type
  /// <summary>
  /// Stores all section/key/value pairs from one initialization source.
  /// </summary>
  TScenarioValues = class
  private
    FValues: TDictionary<string, string>;
    class function MakeKey(const Section, Ident: string): string; static;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Assign(Source: TScenarioValues);
    procedure AddOrSetValue(const Section, Ident, Value: string);

    function ValueExists(const Section, Ident: string): Boolean;
    function ReadString(const Section, Ident, Default: string): string;
    function ReadFloat(const Section, Ident: string;
      const Default: Double): Double;
    function ReadInteger(const Section, Ident: string;
      const Default: Integer): Integer;
    function ReadBool(const Section, Ident: string;
      const Default: Boolean): Boolean;
  end;

  /// <summary>
  /// Complete input definition for one HUME simulation.
  /// </summary>
  TScenarioDefinition = class
  private
    FMainIniFileName: string;
    FParameterIniFileName: string;
    FStateIniFileName: string;
    FOptionIniFileName: string;
    FWeatherFileName: string;

    FMainValues: TScenarioValues;
    FParameterValues: TScenarioValues;
    FStateValues: TScenarioValues;
    FOptionValues: TScenarioValues;

    class function ResolveFileName(const FileName,
      BaseDirectory: string): string; static;
    class procedure LoadIniFile(const FileName: string;
      Target: TScenarioValues; Required: Boolean); static;
    procedure ReadReferencedFileNames(const LegacyBaseDirectory: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromMainIni(const MainIniFileName,
      LegacyBaseDirectory: string);

    class function LoadFromControlFile(const ControlFileName: string;
      const LegacyBaseDirectory: string = ''):
      TObjectList<TScenarioDefinition>; static;

    property MainIniFileName: string read FMainIniFileName;
    property ParameterIniFileName: string read FParameterIniFileName;
    property StateIniFileName: string read FStateIniFileName;
    property OptionIniFileName: string read FOptionIniFileName;
    property WeatherFileName: string read FWeatherFileName;

    property MainValues: TScenarioValues read FMainValues;
    property ParameterValues: TScenarioValues read FParameterValues;
    property StateValues: TScenarioValues read FStateValues;
    property OptionValues: TScenarioValues read FOptionValues;
  end;

implementation

{ TScenarioValues }

constructor TScenarioValues.Create;
begin
  inherited Create;
  FValues := TDictionary<string, string>.Create;
end;

destructor TScenarioValues.Destroy;
begin
  FValues.Free;
  inherited;
end;

class function TScenarioValues.MakeKey(const Section,
  Ident: string): string;
begin
  Result := UpperCase(Trim(Section)) + #1 + UpperCase(Trim(Ident));
end;

procedure TScenarioValues.Clear;
begin
  FValues.Clear;
end;

procedure TScenarioValues.Assign(Source: TScenarioValues);
var
  Pair: TPair<string, string>;
begin
  Clear;
  if Source = nil then
    Exit;

  for Pair in Source.FValues do
    FValues.AddOrSetValue(Pair.Key, Pair.Value);
end;

procedure TScenarioValues.AddOrSetValue(const Section, Ident,
  Value: string);
begin
  FValues.AddOrSetValue(MakeKey(Section, Ident), Value);
end;

function TScenarioValues.ValueExists(const Section,
  Ident: string): Boolean;
begin
  Result := FValues.ContainsKey(MakeKey(Section, Ident));
end;

function TScenarioValues.ReadString(const Section, Ident,
  Default: string): string;
begin
  if not FValues.TryGetValue(MakeKey(Section, Ident), Result) then
    Result := Default;
end;

function TScenarioValues.ReadFloat(const Section, Ident: string;
  const Default: Double): Double;
var
  TextValue: string;
  InvariantFormat: TFormatSettings;
begin
  TextValue := ReadString(Section, Ident, '');
  if TryStrToFloat(TextValue, Result) then
    Exit;

  InvariantFormat := TFormatSettings.Invariant;
  if TryStrToFloat(TextValue, Result, InvariantFormat) then
    Exit;

  Result := Default;
end;

function TScenarioValues.ReadInteger(const Section, Ident: string;
  const Default: Integer): Integer;
begin
  Result := StrToIntDef(ReadString(Section, Ident, ''), Default);
end;

function TScenarioValues.ReadBool(const Section, Ident: string;
  const Default: Boolean): Boolean;
var
  TextValue: string;
begin
  TextValue := LowerCase(Trim(ReadString(Section, Ident, '')));

  if (TextValue = 'true') or (TextValue = 'yes') or
     (TextValue = '1') then
    Exit(True);

  if (TextValue = 'false') or (TextValue = 'no') or
     (TextValue = '0') then
    Exit(False);

  Result := Default;
end;

{ TScenarioDefinition }

constructor TScenarioDefinition.Create;
begin
  inherited Create;
  FMainValues := TScenarioValues.Create;
  FParameterValues := TScenarioValues.Create;
  FStateValues := TScenarioValues.Create;
  FOptionValues := TScenarioValues.Create;
end;

destructor TScenarioDefinition.Destroy;
begin
  FOptionValues.Free;
  FStateValues.Free;
  FParameterValues.Free;
  FMainValues.Free;
  inherited;
end;

class function TScenarioDefinition.ResolveFileName(const FileName,
  BaseDirectory: string): string;
var
  EffectiveBaseDirectory: string;
begin
  if Trim(FileName) = '' then
    Exit('');

  if TPath.IsPathRooted(FileName) then
    Exit(TPath.GetFullPath(FileName));

  EffectiveBaseDirectory := BaseDirectory;
  if EffectiveBaseDirectory = '' then
    EffectiveBaseDirectory := GetCurrentDir;

  Result := TPath.GetFullPath(
    TPath.Combine(EffectiveBaseDirectory, FileName));
end;

class procedure TScenarioDefinition.LoadIniFile(const FileName: string;
  Target: TScenarioValues; Required: Boolean);
var
  IniFile: TMemIniFile;
  Sections: TStringList;
  SectionValues: TStringList;
  SectionIndex: Integer;
  ValueIndex: Integer;
  SectionName: string;
  Ident: string;
begin
  Target.Clear;

  if FileName = '' then
  begin
    if Required then
      raise EArgumentException.Create('No INI filename was specified');
    Exit;
  end;

  if not FileExists(FileName) then
  begin
    if Required then
      raise EFileNotFoundException.CreateFmt(
        'INI file "%s" does not exist', [FileName]);
    Exit;
  end;

  IniFile := TMemIniFile.Create(FileName, TEncoding.UTF8);
  Sections := TStringList.Create;
  SectionValues := TStringList.Create;
  try
    IniFile.CaseSensitive := False;
    IniFile.ReadSections(Sections);

    for SectionIndex := 0 to Sections.Count - 1 do
    begin
      SectionName := Sections[SectionIndex];
      SectionValues.Clear;
      IniFile.ReadSectionValues(SectionName, SectionValues);

      for ValueIndex := 0 to SectionValues.Count - 1 do
      begin
        Ident := SectionValues.Names[ValueIndex];
        if Ident <> '' then
          Target.AddOrSetValue(SectionName, Ident,
            SectionValues.ValueFromIndex[ValueIndex]);
      end;
    end;
  finally
    SectionValues.Free;
    Sections.Free;
    IniFile.Free;
  end;
end;

procedure TScenarioDefinition.ReadReferencedFileNames(
  const LegacyBaseDirectory: string);
begin
  FParameterIniFileName := ResolveFileName(
    FMainValues.ReadString('FileNames', 'ParamIniFN', ''),
    LegacyBaseDirectory);

  FStateIniFileName := ResolveFileName(
    FMainValues.ReadString('FileNames', 'StateIniFN', ''),
    LegacyBaseDirectory);

  FOptionIniFileName := ResolveFileName(
    FMainValues.ReadString('FileNames', 'OptionsIniFN', ''),
    LegacyBaseDirectory);

  FWeatherFileName := ResolveFileName(
    FMainValues.ReadString('FileNames', 'WeatherFileFN', ''),
    LegacyBaseDirectory);
end;

procedure TScenarioDefinition.LoadFromMainIni(const MainIniFileName,
  LegacyBaseDirectory: string);
var
  EffectiveBaseDirectory: string;
begin
  EffectiveBaseDirectory := LegacyBaseDirectory;
  if EffectiveBaseDirectory = '' then
    EffectiveBaseDirectory := GetCurrentDir;

  FMainIniFileName := ResolveFileName(
    MainIniFileName, EffectiveBaseDirectory);

  LoadIniFile(FMainIniFileName, FMainValues, True);
  ReadReferencedFileNames(EffectiveBaseDirectory);

  LoadIniFile(FParameterIniFileName, FParameterValues, False);
  LoadIniFile(FStateIniFileName, FStateValues, False);
  LoadIniFile(FOptionIniFileName, FOptionValues, False);
end;

class function TScenarioDefinition.LoadFromControlFile(
  const ControlFileName, LegacyBaseDirectory: string):
  TObjectList<TScenarioDefinition>;
var
  Reader: TStreamReader;
  Scenario: TScenarioDefinition;
  ScenarioFileName: string;
  EffectiveBaseDirectory: string;
  LoadedFiles: TDictionary<string, Byte>;
  DuplicateKey: string;
begin
  Result := TObjectList<TScenarioDefinition>.Create(True);
  LoadedFiles := TDictionary<string, Byte>.Create;
  try
    EffectiveBaseDirectory := LegacyBaseDirectory;
    if EffectiveBaseDirectory = '' then
      EffectiveBaseDirectory := GetCurrentDir;

    Reader := TStreamReader.Create(
      ResolveFileName(ControlFileName, EffectiveBaseDirectory),
      TEncoding.UTF8, True);
    try
      while not Reader.EndOfStream do
      begin
        ScenarioFileName := Trim(Reader.ReadLine);
        if ScenarioFileName = '' then
          Continue;
        if ScenarioFileName[1] = '#' then
          Continue;

        ScenarioFileName := ResolveFileName(
          ScenarioFileName, EffectiveBaseDirectory);
        DuplicateKey := UpperCase(ScenarioFileName);

        if LoadedFiles.ContainsKey(DuplicateKey) then
          Continue;

        Scenario := TScenarioDefinition.Create;
        try
          Scenario.LoadFromMainIni(
            ScenarioFileName, EffectiveBaseDirectory);
          Result.Add(Scenario);
          LoadedFiles.Add(DuplicateKey, 0);
        except
          Scenario.Free;
          raise;
        end;
      end;
    finally
      Reader.Free;
    end;
  except
    Result.Free;
    raise;
  end;

  LoadedFiles.Free;
end;

end.
```

Example usage:

```pascal
var
  Scenarios: TObjectList<TScenarioDefinition>;
  Scenario: TScenarioDefinition;
  InitialWater: Double;
begin
  Scenarios := TScenarioDefinition.LoadFromControlFile(
    'Example.fn', GetCurrentDir);
  try
    for Scenario in Scenarios do
    begin
      InitialWater := Scenario.StateValues.ReadFloat(
        'SoilWaterMod', 'theta_1', 0.25);

      // Model.LoadScenario(Scenario);
      // Model.RunScenario;
    end;
  finally
    Scenarios.Free;
  end;
end;
```

## Proposed integration interface

The current submodel initialization methods directly use `TMemIniFile`. A small abstraction would allow gradual migration:

```pascal
type
  IScenarioValueReader = interface
    ['{2B291058-D26A-4BBD-BBA1-7CB6B6ED631E}']
    function ValueExists(const Section, Ident: string): Boolean;
    function ReadString(const Section, Ident, Default: string): string;
    function ReadFloat(const Section, Ident: string;
      const Default: Double): Double;
    function ReadInteger(const Section, Ident: string;
      const Default: Integer): Integer;
    function ReadBool(const Section, Ident: string;
      const Default: Boolean): Boolean;
  end;
```

Two adapters could initially implement this interface:

- a legacy adapter around `TCustomIniFile`;
- an adapter around `TScenarioValues`.

This would allow `InitParms`, `InitStates`, and `InitOptions` to be migrated independently while retaining the existing file-based route.

## Verification needed

Before adopting the design, verification should include:

- a Delphi Win32 Debug build of the narrowest suitable test project and then `Hume1.dproj`;
- comparison of initialized parameters, states, options, and time settings between both loaders;
- comparison of numerical simulation results and generated output files;
- tests for relative and absolute paths, missing files, comments, empty lines, duplicate scenarios, mixed-case keys, and locale-specific numbers;
- batch timing with representative short, medium, and long simulations;
- memory measurements when large weather or measurement files are shared by many scenarios.

## Current status

No implementation has yet been added to the HUME Delphi package. No RAD Studio or MSBuild verification has been performed. The code above is retained as a basis for later discussion and implementation.
