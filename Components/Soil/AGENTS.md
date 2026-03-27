# AGENTS.md

## Scope

This file adds subsystem-specific guidance for work inside `Components/Soil/`. It complements the root `AGENTS.md`; the root rules still apply unless this file narrows them further.

The Soil subsystem contains the layered soil profile infrastructure, soil water transport, root water uptake coupling, pedotransfer and van Genuchten utilities, and nitrogen / mineralisation sub-models.

Primary units in this area include:

- `UlayeredSoil.pas`: base class for layered 1D soil profile models and shared layer geometry.
- `USoilWaterMod.pas`: core 1D soil water transport implementation and most shared hydraulic state.
- `URootedSoil.pas`: root water uptake extension of `TSoilWaterMod`.
- `USoilNitrogen.pas`: nitrate transport and balance on top of the rooted soil water model.
- `USoilNitrogenUp.pas`: plant nitrogen uptake extension.
- `UAbstractSoilHeat.pas`: abstract soil temperature state support.
- `UAbstractSoilMin.pas`, `USoilMineralisationNH4.pas`: organic matter turnover and mineral N processes.
- `USoilTexture.pas`, `UGenucht.pas`: texture classes, pedotransfer functions, and hydraulic parameter utilities.
- `Trdiag.pas`: tridiagonal equation solver used by transport calculations.

## Architecture Notes

- Treat `TLayeredSoil` as the common geometric and layer-index foundation. Changes to `n_comp`, `Depth`, `Thick`, `Dist`, `upper_w_f`, or `lower_w_f` affect nearly all Soil models.
- `TSoilWaterMod` is the main base for water-related Soil models. Derived classes such as `TSoilWaterModelR`, `TSoilNitrogen`, and `TSoilNitrogenUp` depend on its state arrays, boundary handling, and time-stepping behaviour.
- Nitrogen models depend on water-model quantities such as `WAmount`, `theta_arr`, drainage, sink terms, and internal time stepping. Do not change water-flow semantics in isolation when nitrate transport or uptake is affected.
- Mineralisation classes are coupled to soil water and soil heat models through linked submodels. Preserve these links and initialization order when extending `UAbstractSoilMin` or `USoilMineralisationNH4`.
- `USoilTexture` and `UGenucht` encode core hydraulic conventions. Keep unit usage, option mappings, and parameter interpretations consistent with the scientific documentation and existing model assumptions.

## Layering And Indexing Rules

- Preserve the existing layer-index conventions exactly. Many Soil units use arrays sized to `max_comp + 1` or `max_comp + 2`, with active layers often running from `1` to `n_comp` and boundary/helper entries at `0` and `n_comp + 1`.
- Before changing loops, check whether the code is iterating over compartments, interfaces, horizons, or helper boundary slots. Off-by-one changes here are high risk.
- Keep the distinction between:
  - `Thick`: compartment thickness.
  - `Dist`: distance between compartment centres.
  - `Depth`: cumulative lower boundary depth of compartments.
- Be careful when changing default resolutions. The code and documentation assume a standard 20-layer profile in many places.

## Scientific And Numerical Safety

- Prefer small, local changes. The Soil subsystem contains numerically sensitive code for diffusion, Richards-type flow, mixed formulations, uptake sinks, and coupled balances.
- Do not change signs, units, or implicit/explicit time-stepping behaviour without tracing the dependent calculations in derived classes.
- When editing `Trdiag.pas` or the embedded `trdiag` implementation in `UlayeredSoil.pas`, treat the solver as high risk. Verify parameter meaning, array bounds, and reuse expectations before changing it.
- Keep water balance and nitrogen balance accounting readable and explicit. If behaviour changes, document the reason in Delphi/XML comments and mention it in the final summary.
- Preserve naming patterns for model variables created with `ParCreate`, `VarCreate`, `StateCreate`, `ExternVCreate`, and `OptCreate`. These names are part of configuration, output, and documentation workflows.

## Documentation Style

- Inline source documentation in this folder should use Delphi/XML documentation comments.
- Existing older comments may be converted into Delphi/XML format when touched, and may be translated from German to English for consistency and clarity.
- For public classes, methods, options, states, parameters, and external variables, prefer short XML summaries that describe scientific meaning, units, and model role.
- Keep source comments aligned with generated XML documentation and Quarto documentation where possible.

## Documentation Workflow

- Soil documentation source files live in `Components/Soil/Documentation/`.
- Generated site output lives in `docs/Components/Soil/Documentation/`; prefer editing `.qmd` source files rather than generated `.html` output.
- The most relevant maintained docs currently include:
  - `Components/Soil/Documentation/TSoilWaterMod.qmd`
  - `Components/Soil/Documentation/TSoilWaterModelR.qmd`
  - `Components/Soil/Documentation/TSoilTexture.qmd`
- If code changes alter public behaviour, options, equations, units, or class responsibilities, update the corresponding `.qmd` source and note whether generated docs were rebuilt.

## File Hygiene In This Folder

This folder contains a mix of source files and many generated or backup artifacts. Do not treat the following as primary source unless the task explicitly requires them:

- `*.dcu`, `*.dproj.local`, `*.identcache`, `*.dsm`, `Win32/`, `__history/`, `__recovery/`
- backup or scratch files such as `*.pas_save`, `*_save*.pas`, `.~pas`, dated backup copies, and alternative historical variants like `URootedSoil_10_2023.pas` or `URootedSoil_zr.pas`
- IDE support folders such as `.github/` and `.vscode/` unless the task is specifically about those files

Prefer editing the main active units named without `_save`, date suffixes, or backup markers.

## Testing And Verification

- Narrow verification to the smallest affected Delphi project or package when possible. Relevant local project files include `SoilWaterPackage.dproj`, `Diffusion1D2D.dproj`, and `SoilWaterAndET.dproj`.
- If you change shared soil-water base logic, consider the impact on rooted-soil and nitrogen descendants even if only one package is built.
- In this environment, clearly state if Delphi/RAD Studio builds could not be run.
- For documentation-only changes, mention whether Quarto regeneration was not run.

## Change Notes Expectations

When summarizing Soil-subsystem changes, mention:

- which core Soil units were changed,
- whether the change affects layer geometry, water transport, root uptake, texture/pedotransfer logic, or nitrogen/mineralisation coupling,
- whether any matching Soil documentation source was updated,
- and whether Delphi/Quarto verification was run or not run.
