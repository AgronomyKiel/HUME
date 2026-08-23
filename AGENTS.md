# AGENTS.md

## Project Overview

HUME is an object-oriented Delphi/VCL component library for modular modelling of dynamic systems. The core package is `Hume1` (`Hume1.dpk` / `Hume1.dproj`), with model logic centered around `TMod` and related sub-model classes.

This repository contains three kinds of work:

- Delphi source for the main package, forms, editors, and support units
- component/model implementations under `Components/`
- Quarto and R-based project documentation that renders into `docs/`

Treat this as a Windows-first Delphi repository. Most code changes should be in Pascal source (`.pas`) and form definitions (`.dfm`).

## Repo Map

- `Hume1.dpk`, `Hume1.dproj`: main Delphi package definition for HUME
- `UMod.pas`, `Ustate.pas`, `UMeasValue.pas`, related root-level units: core model/runtime logic
- `UFORMMOD.pas`, `UForm*.pas`, `EditorForm/`: VCL UI and editor forms
- `Components/`: domain components and sub-model implementations; many component docs live below this tree
- `ModelSupport_Hume1/`: default packages and model support assets
- `Demo/`: demo and sample model code
- `Documentation_Help/`, `PasDoc/`, `XML_Delphi_Docu/`: documentation inputs and generated/reference material
- `index.qmd`, `CodeBasisOverview.qmd`, `_quarto.yml`: Quarto website sources
- `docs/`: generated Quarto site output; edit source `.qmd` files rather than generated HTML unless explicitly asked
- `Rlib/`, `*.R`: R scripts used for extraction, documentation, and analysis workflows

## Build And Verification

Preferred verification is through Delphi project/package builds in RAD Studio or MSBuild-compatible Delphi tooling on Windows.

Primary project files:

- `Hume1.dproj`: main VCL package, default platform `Win32`
- `ProjectGroupHume.groupproj`, `Hume1ProjectGroup.groupproj`, `Packages.groupproj`: useful project groups for IDE builds
- `ProjectGroupTestControlFileSetting.groupproj` and `ProjecttestControlFilesetting.dproj`: small test-style project for control file handling

When changing Delphi code:

- build the narrowest affected project/package first
- prefer `Win32 Debug` unless the task specifically requires another target
- mention clearly if you could not run a Delphi build in the current environment
- On this machine, initialize command-line builds with `C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat`. The default `Hume1` BPL output under `C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl` may reject automated writes with error `F2039`; do not change project output settings to work around this without explicit approval.

### Local Windows Execution Environment

- Treat `Q:\HUME\HUME` and `C:\Users\h_kage\Documents\Modell\HUME\HUME` as two paths to the same worktree. RAD Studio may use `Q:`, but automated shell, Git, build, Quarto, and patch commands should use the local `C:` path as their working directory. Never copy or synchronize files between these paths.
- A sandboxed child process started with a `Q:` working directory may fail before executing with Windows error 267. After one such failure, switch immediately to the local `C:` path; do not repeat the same `Q:` attempt or alter the drive mapping.
- Git commands through the local path may report dubious repository ownership. Use a per-command override such as `git -c safe.directory=C:/Users/h_kage/Documents/Modell/HUME/HUME ...`; do not modify the user's global Git configuration for this.
- Keep RAD Studio/Kai buffers authoritative when the IDE integration is available. If it is unavailable, operate on the same files through the local `C:` path. If the standard patch helper itself fails with error 267 because it inherited `Q:`, try it only once, then use a context-validated patch fallback through the local path and inspect the resulting diff carefully.
- Preserve the existing encoding and line endings. Delphi sources in this worktree commonly use UTF-8 with a BOM and CRLF; after a patch fallback, verify that the patch engine did not silently convert the whole file to LF.
- From PowerShell, pass the complete RAD Studio initialization/build sequence to `cmd.exe` as one literal argument, for example `cmd.exe /d /s /c 'call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" && msbuild ...'`. This avoids PowerShell interpreting `(x86)` or `&&`.
- `SoilWaterPackage` may stop before compiling changed units when the external `Jcl` package is unavailable, and visual unit compilation may require `AdvGrid`. When the affected numerical unit supports it, use an isolated Win32 `NONVISUAL` unit compile with DCU output under `%TEMP%` rather than changing project search paths, dependencies, or output settings.
- Treat these as known environment conditions, not new discoveries. Mention a fallback once when it changes the execution strategy; do not repeat the same warning before every command. Include it in the final summary only when it materially limited verification.

When changing documentation:

- update the `.qmd` source files and supporting assets first
- regenerate `docs/` only if the task asks for built output or the repo normally commits generated docs

## Working Rules

- Preserve existing Delphi/VCL structure and naming. Follow the unit/form naming already in use.
- Keep changes tight and local. Avoid broad refactors unless they are necessary for the task.
- Check both .pas and paired .dfm files before modifying forms.
- Write inline source documentation in Delphi/XML documentation comment style.
- Existing inline comments may be rewritten into Delphi/XML documentation comment style when touched, and may be translated from German to English when needed for consistency and clarity.
- Prefer extending existing model/component classes over creating parallel abstractions.
- Do not silently rewrite project search paths, package dependencies, or IDE config files.
- Some project files and IDE/LSP configs (for example `*.delphilsp.json` such as `Components/CERES Wheat/CeresSubModels.delphilsp.json`) contain machine-specific paths under `C:\Users\...` and `Q:\...`; avoid normalizing or regenerating these in PRs unless the task is specifically about shared build configuration, and prefer not tracking purely local IDE/LSP configs in version control.
- Expect generated binaries and caches such as `.dcu`, `.dsk`, `.identcache`, `__history/`, `__recovery/`, and `Win32/` outputs. Do not edit or rely on them as source of truth.
- `docs/` is generated output. Prefer editing `index.qmd`, `CodeBasisOverview.qmd`, component docs, `_quarto.yml`, and related assets instead.
- R artifacts like `.RData` and `.Rhistory` are user/runtime state, not primary source files.

## Generated And High-Risk Files

Ask before editing these unless the task explicitly requires it:

- `*.dproj`, `*.groupproj`, `*.dof`, `*.cfg`, `*.local`
- package dependency settings such as `DCC_UsePackage`, search paths, or output directories
- generated documentation under `docs/`
- XML output under `XML_Delphi_Docu/`
- committed binary/compiler outputs such as `.dcu`, `.bpl`, `.dcp`, `.res`, `.dsm`

Never mass-delete generated files just to "clean up" the repo unless the user asks.

## Documentation Workflow

The Quarto site is configured in `_quarto.yml` with output directed to `docs/`. The sidebar includes:

- `index.qmd`
- `CodeBasisOverview.qmd`
- component documentation under `Components/.../Documentation/`

For documentation tasks:

- update the source `.qmd` or referenced assets
- keep links and sidebar entries consistent with `_quarto.yml`
- avoid editing generated `docs/*.html` by hand unless explicitly requested

## Change Notes

In your final summary:

- mention which Delphi project/package or doc source you changed
- note whether verification was performed in RAD Studio/MSBuild/Quarto, or not run
- call out any assumptions about local paths, external packages, or unavailable Windows tooling

