# HUME Framework - AI Coding Agent Guide

## Project Overview

HUME is an Object Pascal (Delphi) framework for building modular dynamic simulation models, particularly for agro-ecological systems. You're working in the **Soil components** subsystem, which implements soil-related submodels (water, heat, nitrogen dynamics, etc.).

## Core Architecture

### Component Hierarchy
- **`TMod`** (in `Q:\HUME\HUME\UMod.pas`): Central model coordinator
  - Manages simulation lifecycle (`Init` → `Run` → finalization)
  - Contains list of submodels (`SubModStrList`)
  - Handles INI file configuration, time stepping, and parameter optimization
- **`TSubmodel`** (base class): Abstract parent for all domain submodels
  - Concrete implementations: `TSoilWaterMod`, `URootedSoil`, `USoilHeat`, etc.
  - Each submodel has its own state variables, parameters, and calculation methods

### Execution Flow
```
TMod.Run()
  ├─ Init(IniFile) - read INI configs, initialize submodels
  ├─ Loop over time steps:
  │   ├─ CalcAllVars() - calculate derived variables
  │   ├─ CalcAllRates() - compute rate of change (derivatives)
  │   ├─ integrateAllSubModels() - update states
  │   └─ SaveStates() - write outputs
  └─ SaveFinalStates() - write final values
```

## Critical Patterns

### 1. Conditional Compilation for Console vs GUI
All classes use compiler directives to support both visual (GUI) and non-visual (console) builds:
```pascal
{$IFDEF NONVISUAL}
  TMod = class(TObject)      // Console: plain object
{$ELSE}
  TMod = class(TGraphicControl)  // GUI: visual component
{$ENDIF}
```
- `NONVISUAL` defined automatically when `LINUX` or `CONSOLE` is set
- GUI builds inherit from VCL controls; console builds use plain `TObject`

### 2. Inter-Component Communication via `TExternV`
Submodels don't directly reference each other. Instead, they use **external values**:
```pascal
// In submodel A (producer):
procedure TSubmodelA.CreateAll;
begin
  VarCreate('SoilTemp', '[°C]', 20.0, false, SoilTemp);
end;

// In submodel B (consumer):
procedure TSubmodelB.CreateAll;
begin
  ExternVCreate('SoilTemp', '[°C]', StateField, MySoilTemp);
end;

// Framework resolves pointers in ExternVinit():
function TSubmodelB.ExternVinit(Model: TMod): boolean;
begin
  Result := MySoilTemp.Init(Model);  // Searches for 'SoilTemp' in all submodels
end;
```
- Loose coupling: submodels find data by **string name** at runtime
- External values can reference: `TState`, `TPar`, `TVar`, or constants

### 3. INI File Configuration System
Model runs are controlled by multiple INI files:
- **Control File** (e.g., `control.ini`): Lists which parameter/state INI files to use
- **State.ini**: Initial values for state variables
- **Parameters_x.ini**: Parameter values for each submodel
- **Options.ini**: Boolean flags and string options
- **properties.ini**: GUI-specific settings (plot flags, output selection)

INI structure:
```ini
[TimeInit]
Startzeit=01.01.2020
Endzeit=31.12.2020
TimeStep=1.0

[FileNames]
StateIniFN=State.ini
ParamIniFN=Parameters_x.ini
WeatherFileFN=weather.csv
```

### 4. Entity Creation Workflow in Submodels
Override `CreateAll()` to define model structure:
```pascal
procedure TMySubmodel.CreateAll;
begin
  // States: values that change over time (integrated)
  StateCreate('SoilWater', '[mm]', 100.0, true, SoilWater, 'Initial soil water');
  
  // Parameters: fixed values (read from INI)
  ParCreate('MaxRootDepth', '[cm]', 150.0, MaxRootDepth, 'Maximum rooting depth');
  
  // Variables: derived/calculated values
  VarCreate('Transpiration', '[mm/d]', 0.0, false, Transpiration);
  
  // External values: data from other submodels
  ExternVCreate('AirTemp', '[°C]', StateField, AirTemp);
end;
```

### 5. Naming Conventions
- **Units**: Prefix `U` (e.g., `UMod.pas`, `USoilWaterMod.pas`)
- **Classes**: Prefix `T` (e.g., `TMod`, `TSoilWaterMod`)
- **Forms**: Prefix `TForm` or `TF_` (e.g., `TF_SubmodelEditor`)
- **Fields**: Prefix `f` for private fields (e.g., `fControlFileFn`)
- **Properties**: Prefix `F` for backing fields (e.g., `FTimeStep`)
- **Project Files**: 
  - `.dpr` = Delphi program (executable entry point)
  - `.dpk` = Delphi package (component library)
  - `.dproj` = Delphi project (MSBuild format)

## Common Tasks

### Building the Project
- Open `.dproj` or `.dpk` file in Delphi IDE (Embarcadero RAD Studio)
- Or use command line: `dcc32 ProjectName.dpr` (for 32-bit) or `dcc64` (for 64-bit)
- Compiled units (`.dcu`) are build artifacts - do not edit
- For console builds, define `CONSOLE` or `NONVISUAL` in project options

### Adding a New Submodel
1. Create unit inheriting from `TSubmodel`: `unit UMySubmodel;`
2. Override key methods:
   - `CreateAll`: Define states/params/variables
   - `CalcRates`: Compute derivatives (rates of change)
   - `Integrate`: Update states (usually call inherited)
   - `CalcVars`: Compute derived variables
3. Register in component palette (GUI) or instantiate programmatically
4. Link to `TMod` via `SM_GlobMod` property
5. Add INI file sections for parameters and states

### Working with Soil-Specific Components
Key files in this directory:
- `USoilWaterMod.pas` - Soil water balance (infiltration, drainage, evaporation)
- `URootedSoil.pas` - Rooted soil with water uptake
- `USoilHeat.pas` - Soil temperature dynamics
- `USoilNitrogen.pas` - Nitrogen cycling (mineralization, nitrification)
- `UlayeredSoil.pas` - Base class for layered soil profiles

Common integration: Soil water affects root uptake → plant transpiration → soil drying

## Key Dependencies
- **UState.pas**: Defines `TVar`, `TPar`, `TState`, `TExternV` base classes
- **UTextfileH.pas**: ASCII file I/O for weather data and outputs
- **UMeasValue.pas**: Handling measured data for calibration/validation
- **UModUtils.pas**: String utilities, numerical helpers

## Documentation
- XML comments use `///` (PasDoc/Doxygen style)
- Compiled HTML docs may exist in `PasDoc/` directories
- Quarto markdown (`.qmd`) files provide high-level architecture docs

## Debugging Tips
- Use `{$IFNDEF NONVISUAL}` blocks to add debug forms/dialogs (GUI only)
- Check `CompIndex` property: controls submodel execution order
- INI file issues: Verify section names match exactly (case-sensitive)
- External value not found: Check spelling in both producer and consumer `CreateAll()`
