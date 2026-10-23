/// <summary>Nitrate transport and root uptake using a shared fixed water field.</summary>
unit USubModRootNO3;

interface

uses
  System.SysUtils, System.Classes, System.Math, UMod, UState, URootObject,
  Vcl.Dialogs, Diffko, URootUptakeFunctions, U2DSoilBaseClasses, USubModRoot2DH2O;

type
  /// <summary>Forward declaration of the nitrate submodel, which owns the nitrate field and solver.</summary>
  TSubmodRoot2DNO3 = class;

  /// <summary>Callback signature for a cell sink or source, evaluated at the beginning of a nitrate step; callbacks must not modify state.</summary>
  TGridSinkEvent = procedure(X, Y: Word; var Sink: real) of object;

  /// <summary>Nitrate field and diffusion solver sharing geometry and water with the submodel.</summary>
  TRasterDataNO3 = class(TObject)
  private
    /// <summary>Shared geometry of the computational grid.</summary>
    FGeometry: TRasterData;
    /// <summary>Shared water content of the computational grid.</summary>
    FWater: TRasterDataH2O;

    /// <summary>Reference to the owning nitrate submodel, which provides the sink callback.</summary>
    FSubmodel: TSubmodRoot2DNO3;

    /// <summary>Diffusion coefficient [cm2/d] used in the last accepted step.</summary>
    fDe: real;

    /// <summary>Whether to write the sink cell file; set by the owning submodel.</summary>
    fWriteSinkCells: boolean;

    /// <summary>Path and name of the sink cell file; set by the owning submodel.</summary>
    fSinkCellFileName: string;

    /// <summary>Whether the sink cell file was created; set by the owning submodel.</summary>
    FSinkCellFileWasCreated: boolean;

    /// <summary>Whether to write the concentration field file; set by the owning submodel.</summary>
    FFileWasCreated: boolean;

    /// <summary>Path and name of the concentration field file; set by the owning submodel.</summary>
    FOnConcentrationChanged: TNotifyEvent;

    /// <summary>Whether the concentration field file was created; set by the owning submodel.</summary>
    procedure WriteNitrateUptakeSinkToFile;
  public
    /// <summary>Nitrate concentration in soil solution; legacy solver units are retained.</summary>
    C_xy: array of array of double;
    constructor Create(AGeometry: TRasterData; AWater: TRasterDataH2O;
      ASubmodel: TSubmodRoot2DNO3);
    procedure Init(AConcentration: double);
  public
    /// <summary>Nitrate-specific options registered by the owning HUME submodel.</summary>

    /// <summary>Whether to write the concentration field file.</summary>
    ContGrowth,
    /// <summary>Nitrate-specific options registered by the owning HUME submodel.</summary>
    CalcModeSteadyState, SteadyState, DelMarginRoots: TOption;
    writeConcField, writeSinkCellFile, OutputSink: TOption;
    ConcFieldDataFile, SinkCellFileFile, RootSinkOutpDataFile: TOption;
    /// <summary>Extrema calculated by avg_conz, in the same units as C_xy.</summary>
    min_c, max_c: double;
    /// <summary>Initializes field concentrations and output bookkeeping after geometry and initial N are set.</summary>
    procedure InitializeModel;
    /// <summary>Advances the legacy nitrate calculation through the owner's current timestep.</summary>
    procedure CalcRates;
    /// <summary>Signed cell source: mineralization minus root uptake. Retains the sink callback signature.</summary>
    procedure Get_Sink(x_loc, y_loc: word; var s: real);
    /// <summary>Mineralization source in one unit-depth computational cell.</summary>
    procedure get_minGrid(x_loc, y_loc: word; var s: real);
    procedure InitConc;
    procedure createSteadyState(DiffSteadyState: double);
    function avg_conz: double;
    function influx_fVar(Imax, Km, ClAv, x, Db: double): double;
    function calcAmountUptakeRoots: double;
    function convertConcToAmount(i: integer): double;
    function calcActArdt: double;
    /// <summary>Optional notification for visualization; the field does not draw on VCL controls.</summary>
    property OnConcentrationChanged: TNotifyEvent read FOnConcentrationChanged
      write FOnConcentrationChanged;
    /// <summary>Legacy diffusion sweep accepting a field-owned sink callback.</summary>
    procedure zweid_solut(dt_globmod: real; AGetSink: TGridSinkEvent;
      AContainerMode: boolean);
    /// <summary>Shared geometry of the computational grid.</summary>
    property Geometry: TRasterData read FGeometry;
    /// <summary>Water content of the computational grid.</summary>
    property Water: TRasterDataH2O read FWater;
  end;

  /// <summary>Nitrate diffusion and root uptake at fixed, spatially uniform water content.</summary>
  TSubmodRoot2DNO3 = class(TSubmodRoot2DH2O)
  protected
    RasterDataNO3: TRasterDataNO3;
  public
        /// <summary> Potential N uptake rate [Kg N/ha*d]</summary>
    NUptakeratepot: TPar;

    /// <summary>Mineralization rate [kg N/ha*d]</summary>
    NMinerRate_kgNha: TPar;

    /// <summary>Minimum soil solution concentration [g N/l], also needed for the numerical solution in the 1D model; note: originally in micromol/l</summary>
    Clmin: TPar;

    /// <summary>Michaelis-Menten constant [mol/cm3]</summary>
    Km: TPar;

    /// <summary>
    ///   initial soil nitrate [kg N/ha]
    /// </summary>
    IniSoilNitrate: TPar;

    /// <summary>Member HUME base class TState (state variables)</summary>
    /// <summary>N amount [kg N/ha], also basis for calculating concentrations in the calculation elements; see Kage dissertation p.79 where concentrations of 10.0 micromol/l were assumed</summary>
    NAmount: TState;

    /// <summary>Cumulative amount of N taken up by the roots [kg N/ha] for the specified depth</summary>
    SumNUptake: TState;

    /// <summary>Mineralization rate [Mol/cm^3*d]</summary>
    Min_S: TVar;

    /// <summary>Initial concentration [kg N/cm], calculated from the initial N amount; the 1D model can also calculate concentrations</summary>
    c_start: TVar;

    /// <summary>Average concentration in the soil solution [kg N/cm]</summary>
    cl_av: TVar;

    /// <summary>
    /// average Concentration [mol/cm3]
    /// </summary>
    c_av: TVar;

   /// <summary>maximum influx [g N/cm*d]</summary>
   Imax: TVar;

   ActArFromConc : TVar;

   ActAr : TVar;

    /// <summary>
    ///   Potential N Influx rate [mol/cm/d]
    /// </summary>
    PotentialNInfluxrate : TVar;

    /// <summary>
    ///   effective Diffusion coefficient [cm2/d]
    /// </summary>
    De : TVar;

    /// <summary>
    ///   Diffusion coefficient of nitrate in water [cm2/d]
    /// </summary>
    Dl : TVar;

    /// <summary>Type of uptake calculation</summary>
    NitrateUptakeFunction: TOption;

    procedure createAll; override;
    /// <summary>Initializes shared geometry and roots, then nitrate concentrations,
    /// uptake quantities and output bookkeeping using the loaded inputs.</summary>
    procedure Init(var GlobMod: TMod); override;
    destructor Destroy; override;
    function getNitrateRasterData: TRasterDataNO3;
    procedure CalcRates; override;
    procedure Integrate; override;
  end;

  /// <summary>Retains the renamed combined model and its legacy nitrate calculation at fixed water content.</summary>
  /// <remarks>Coupling nitrate storage/fluxes to changing water content is not implemented.</remarks>
  TSubmodRoot2DH2ONO3 = class(TSubmodRoot2DNO3)
  public
    procedure createAll; override;
  end;

/// <summary>Registers the transport component on the Simulation palette.</summary>
procedure Register;

implementation

{$I trdiag.pas}

constructor TRasterDataNO3.Create(AGeometry: TRasterData;
  AWater: TRasterDataH2O; ASubmodel: TSubmodRoot2DNO3);
begin
  inherited Create;
  if (AGeometry = nil) or (AWater = nil) or (ASubmodel = nil) then
    raise EArgumentException.Create('Nitrate raster requires geometry, water and submodel');
  if AWater.Geometry <> AGeometry then
    raise EArgumentException.Create('Water and nitrate must share the same geometry');
  FGeometry := AGeometry;
  FWater := AWater;
  FSubmodel := ASubmodel;
end;

procedure TRasterDataNO3.Init(AConcentration: double);
var
  i, j: integer;
begin
  SetLength(C_xy, Geometry.NCols + 2, Geometry.NRows + 2);
  for i := 0 to Geometry.NCols + 1 do
    for j := 0 to Geometry.NRows + 1 do
      C_xy[i, j] := AConcentration;
  FSinkCellFileWasCreated := false;
end;

/// <summary>
/// Reads aggregated raster data (root counts) which are then used to randomly
/// determine coordinate points. Example of functionality: readln(f, Ncols)
/// assigns the value read from f to the variable Ncols.
/// </summary>
procedure TSubmodRoot2DNO3.createAll;
begin
  inherited createAll;
  SetEntityDeclarationClass(TSubmodRoot2DNO3);
  ParCreate('Ar', '[kg N/ha*d]', 0, NUptakeratepot, 'Potential nitrate uptake rate');
  ParCreate('Minera', '[kg N/ha*d]', 0, NMinerRate_kgNha, 'Mineralization rate');
  ParCreate('Clmin', '[mol/l]', 0, Clmin, 'Minimum concentration');
  ParCreate('Km', '[mikromol/l]', 0, Km, 'Half-saturation concentration');
  ParCreate('iniSoilNitrate', '[kg N/ha]', 30, iniSoilNitrate, 'Initial nitrate amount in soil');

  // Create and initialize TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 30, false, NAmount,
    'N amount in the soil');
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, SumNUptake,
    'Cumulative N amount taken up by roots');
  // Create and initialize TVar
  { Caveat: variables are always initialized to 0. If a start value other than 0 is
    needed, calculation and assignment must occur in init. It would be better not to
    declare such variables as TVar. }

  VarCreate('Min_s', '[Mol/cm^3*d]', 0, false, Min_S, 'Mineralization rate in mol/cm3*s');
  VarCreate('c_start', '[Mol/cm^3]', 1e-5, false, c_start, 'Initial concentration');
  VarCreate('cl_av', '[Mol/cm^3]', 0, false, cl_av, 'Average concentration');
  VarCreate('Imax', '[mol/cm/d]', 0, false, Imax, 'Maximum influx rate');

  VarCreate('ActArFromConc', '[mol/cm/d]', 0, false, ActArFromConc, 'Actual uptake rate calculated from concentration');
  VarCreate('ActAr', '[mol/cm/d]', 0, false, ActAr, 'Actual uptake rate');
  VarCreate('C_av', '[mol/cm3]', 0, false, C_av, 'Average concentration');
  VarCreate('De', '[cm2/d]',  D0NO3*0.2*0.2*3.35, false, De, 'effective nitrate diffusion coefficient');
  ConstCreate('Dl', '[cm2/d]',  D0NO3, false, Dl, 'nitrate diffusion coefficient in water');

  // Create and initialize TOption
  { Specify the source of the root data }
  { Define uptake function }
  OptCreate('NitrateUptake_function', 'ZeroSink', NitrateUptakeFunction,
    'Defines the nitrate uptake function');
  NitrateUptakeFunction.OptionList.add('ZeroSink');
  NitrateUptakeFunction.OptionList.add('ConstInflux');
  NitrateUptakeFunction.OptionList.add('MM');
  RasterDataNO3 := TRasterDataNO3.Create(RasterData, RasterDataH2O, Self);
  /// <summary>Field options remain owned and registered by HUME.</summary>
  OptCreate('ContGrowth', 'no', RasterDataNO3.ContGrowth);
  RasterDataNO3.ContGrowth.OptionList.Add('yes');
  RasterDataNO3.ContGrowth.OptionList.Add('no');
  OptCreate('CalcModeSteadyState', 'withoutMargin', RasterDataNO3.CalcModeSteadyState);
  RasterDataNO3.CalcModeSteadyState.OptionList.Add('withMargin');
  RasterDataNO3.CalcModeSteadyState.OptionList.Add('withoutMargin');
  OptCreate('SteadyState', 'no', RasterDataNO3.SteadyState);
  RasterDataNO3.SteadyState.OptionList.Add('yes');
  RasterDataNO3.SteadyState.OptionList.Add('no');
  OptCreate('DelMarginRoots', 'no', RasterDataNO3.DelMarginRoots);
  RasterDataNO3.DelMarginRoots.OptionList.Add('yes');
  RasterDataNO3.DelMarginRoots.OptionList.Add('no');
  OptCreate('writeConcField', 'no', RasterDataNO3.writeConcField);
  RasterDataNO3.writeConcField.OptionList.Add('no');
  RasterDataNO3.writeConcField.OptionList.Add('yes');
  OptCreate('writeSinkCellFile', 'no', RasterDataNO3.writeSinkCellFile);
  RasterDataNO3.writeSinkCellFile.OptionList.Add('no');
  RasterDataNO3.writeSinkCellFile.OptionList.Add('yes');
  OptCreate('OutputSink', 'no', RasterDataNO3.OutputSink);
  RasterDataNO3.OutputSink.OptionList.Add('no');
  RasterDataNO3.OutputSink.OptionList.Add('yes');
  OptCreate('ConcFieldDataFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv', RasterDataNO3.ConcFieldDataFile);
  OptCreate('SinkCellFileFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv', RasterDataNO3.SinkCellFileFile);
  OptCreate('RootSinkOutpDataFile', 'Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat', RasterDataNO3.RootSinkOutpDataFile);
  RasterDataNO3.RootSinkOutpDataFile.IsFileOutput := True;
  RasterDataNO3.RootSinkOutpDataFile.FileFilter := 'Nitrate uptake files (*.dat)|*.dat|All files (*.*)|*.*';
end;

procedure TSubmodRoot2DNO3.Init(var GlobMod: TMod);
begin
  inherited Init(GlobMod);
  /// <summary>Nitrate initialization follows shared water and root initialization.</summary>
  De.v := D0NO3 * f_Tortuosity(theta.v); // [cm2/d]
  NAmount.v := IniSoilNitrate.v; // [kg N/ha]
  RasterDataNO3.Init(0);
  if RasterDataNO3.DelMarginRoots.Option = 'yes' then
    removeMarginRoots;
  NRoots := RootList.Count;
  num_roots.v := NRoots;
  RasterDataNO3.InitializeModel;
  NAmount.v := Mg_func(Depth.v, theta.v, c_start.v);
  c_av.v := RasterDataNO3.avg_conz;
  int_dt.v := ini_dt.v;
  /// <summary>Retain the nitrate solver's existing mineralization and influx units.</summary>
  Min_S.v := NMinerRate_kgNha.v / 14 * 1000 / 86400 / (Depth.v * 1E8);
  if wl_ha.v > 0 then
    Imax.v := NUptakeratepot.v / 14 * 1000 / wl_ha.v
  else
    Imax.v := 0;
  /// <summary>Notify observers only after concentrations and model quantities are ready.</summary>
  if Assigned(RasterDataNO3.FOnConcentrationChanged) then
    RasterDataNO3.FOnConcentrationChanged(RasterDataNO3);
end;

destructor TSubmodRoot2DNO3.Destroy;
begin
  RasterDataNO3.Free;
  inherited Destroy;
end;

procedure TSubmodRoot2DH2ONO3.createAll;
begin
  inherited createAll;
  SetEntityDeclarationClass(TSubmodRoot2DH2ONO3);
end;

procedure TSubmodRoot2DNO3.CalcRates;
begin
  RasterDataNO3.CalcRates;
end;

procedure TSubmodRoot2DNO3.Integrate;
begin
  inherited Integrate;
  c_av.v := RasterDataNO3.avg_conz;
  NAmount.v := Mg_func(Depth.v, theta.v, c_av.v);
end;

function TSubmodRoot2DNO3.getNitrateRasterData: TRasterDataNO3;
begin
  Result := RasterDataNO3;
end;

procedure TRasterDataNO3.zweid_solut(dt_globmod: real;
  AGetSink: TGridSinkEvent; AContainerMode: boolean);
(* ------------------------------------------------------------------------------
  DESCRIPTION: Central procedure. Calculation of nutrient transport in 2D space
  (linear algebra). Note: nested structure
  ------------------------------------------------------------------------------ *)
var
  { The following arrays are declared with a size of dim_max (largest index).
    From the fluxes, a tridiagonal matrix with main and secondary diagonals is
    formed (see Scholl/Drews: linear algebra) }
  /// <summary>solution vector</summary>
  B_vektor,
  /// <summary>lower diagonal</summary>
  lower,
  /// <summary>middle diagonal</summary>
  diag,
  /// <summary>upper diagonal</summary>
  upper,
  /// <summary>sink terms</summary>
  Sink,
  /// <summary>concentration vector below</summary>
  u_vektor,
  /// <summary>z_vektor : central vector to be calculated</summary>
  z_vektor,
  /// <summary>concentration vector above</summary>
  o_vektor: array_type;
  { Note: since array_type also starts at 0 in the original, nothing needs to be
    changed here }
  Result, i: word;

  /// <summary>
  ///   effective diffusion coeffecient
  /// </summary>
  Df: real;
  /// <summary>loop variables for grid elements</summary>
  x_ndx, y_ndx: integer;

  SinkCellFile: Textfile;

  ARoot: TRootObjectIn2D;


  procedure CalcOneLine(o_vektor, Sink: array_type; dim_z, Start, Ende: word;
    var u_vektor, z_vektor: array_type);
  (* -----------------------------------------------------------------------------
    PARENT method: TSubModDiff2D_k.zweid_solut
    The flux calculation is performed row by row.
    ------------------------------------------------------------------------------ *)
  var
    flow_1, flow_2: real;

    { In the following procedures the fluxes over the borders are determined for
      a grid cell }
    Procedure linker_Rand(Start: integer); // or upper boundary
    (* ------------------------------------------------------------------------------
      PARENT method: (helper procedure eine_Zeile)
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      For i := 1 to Start - 1 do
      begin
        B_vektor[i] := z_vektor[i];
        diag[i] := 0; // vectors are set to zero at the borders
        upper[i] := 0;
      end;
      flow_1 := Geometry.ColWidth * fDe * (u_vektor[Start] - z_vektor[Start]) / Geometry.RowHeight * Df;
      // explicit calculation
      flow_2 := Geometry.ColWidth * fDe * (z_vektor[Start] - o_vektor[Start]) / Geometry.RowHeight * Df;

      B_vektor[Start] := z_vektor[Start] + flow_1 - flow_2 + Sink[Start] * Df;
      diag[Start] := fDe * Geometry.RowHeight / Geometry.ColWidth * Df + 1;
      upper[Start] := -fDe * Geometry.RowHeight / Geometry.ColWidth * Df;
    end; // End linker Rand

    Procedure Mittelteil(Start, Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure CalcOneLine
      DESCRIPTION: Solves the diffusion equation for two-dimensional coordinates
      (grid) using an alternating direction implicit approach?
      Boundary condition: no transport across grid boundaries (no flow)
      ------------------------------------------------------------------------------ *)
    var
      ndx: word;
    begin
      For ndx := Start + 1 to Ende - 1 do
      begin
        flow_1 := Geometry.ColWidth * fDe * (u_vektor[ndx] - z_vektor[ndx]) / Geometry.RowHeight * Df;
        flow_2 := Geometry.ColWidth * fDe * (z_vektor[ndx] - o_vektor[ndx]) / Geometry.RowHeight * Df;

        B_vektor[ndx] := z_vektor[ndx] + flow_1 - flow_2 + Sink[ndx] * Df;
        lower[ndx] := -fDe * Geometry.RowHeight / Geometry.ColWidth * Df;
        diag[ndx] := fDe * Geometry.RowHeight / Geometry.ColWidth * Df + fDe * Geometry.RowHeight / Geometry.ColWidth * Df + 1;
        upper[ndx] := -fDe * Geometry.RowHeight / Geometry.ColWidth * Df;
      end;
    end; // End Mittelteil

    Procedure RightBoundary(Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      flow_1 := Geometry.ColWidth * fDe * (u_vektor[Ende] - z_vektor[Ende]) / Geometry.RowHeight * Df;
      flow_2 := Geometry.ColWidth * fDe * (z_vektor[Ende] - o_vektor[Ende]) / Geometry.RowHeight * Df;

      B_vektor[Ende] := z_vektor[Ende] + flow_1 - flow_2 +
        Sink[Geometry.NCols] * fDe;
      lower[Ende] := -fDe * Geometry.RowHeight / Geometry.ColWidth * Df;
      diag[Ende] := fDe * Geometry.RowHeight / Geometry.ColWidth * Df + 1;
      For i := Ende + 1 to trunc(Geometry.NCols) do
      begin
        B_vektor[i] := z_vektor[i];
        diag[i] := 0;
        upper[i] := 0;
      end;

    end; // End rechter Rand

    procedure SolveEquationSystem;
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      DESCRIPTION: Calls the function trdiag in TRDIAG.pas. The function solves a
      tridiagonal system of equations; see matrix calculations and linear
      combinations. Further explanatory notes on the solution method are in
      tridiag.pas
      ------------------------------------------------------------------------------ *)
    var
      ndx: word;
    begin
      Result := trdiag(false, dim_z, 1, lower, diag, upper, B_vektor);
      If Result <> 0 then
      begin
        { Return value only indicates whether it worked and is used to output an
          error message. Problem: is exception handling needed? }
        showMessage('Error while solving TriDiaMatrix');
      end;
      for ndx := 1 to dim_z do
      begin
        If B_vektor[ndx] < 0.0 then
        begin
          { Negative concentrations should not occur! In this case default values
            are used }
          z_vektor[ndx] := 1E-15;
          u_vektor[ndx] := 1E-15;
        end
        else
        begin
          u_vektor[ndx] := z_vektor[ndx];
          z_vektor[ndx] := B_vektor[ndx];
        end;
      end;
    end; // End Loesung_Gleichungssysteme

  begin
    if fWriteSinkCells then
    begin
//      SinkCellFileName := SinkCellFileFile.Option;
      if FSinkCellFileWasCreated = false then
      begin
        deleteFile(fSinkCellFileName);
        assignfile(SinkCellFile, fSinkCellFileName);
        rewrite(SinkCellFile);
        // Header
        write(SinkCellFile, 'SimZeit', ' ', 'dt_akt[d]', ' ', 'sumDtInt[d]',
          ' ', 'Influx', ' ', 'Konz_Zelle');
        writeln(SinkCellFile);
        closefile(SinkCellFile);
        FSinkCellFileWasCreated := true;
      end;
    end;
    linker_Rand(Start);
    Mittelteil(Start, Ende);
    RightBoundary(Ende);
    SolveEquationSystem;
  end; // End eine_Zeile (correct?)

(* -----------------------------------------------------------------------------
  End of helper methods for the central method
  ------------------------------------------------------------------------------ *)
var
  start_, ende_: integer;
begin

  /// <summary>computation factor for half time step</summary>
  /// <summary>The legacy nitrate sweep uses water storage per unit layer depth.</summary>
  Df := dt_globmod / 2 * Water.LayerDepth / Water.CellWaterAmount;
  { Setup of the system of equations with an IMPLICIT formulation for y and
    an EXPLICIT formulation for x }
  // iterate over all computational elements (except the 1 cell wide margins)

  for y_ndx := 1 to trunc(Geometry.NRows) do
  begin
    For i := 1 to trunc(Geometry.NCols) do
    begin
      AGetSink(i, y_ndx, Sink[i]); // calculate sink terms
      If y_ndx = 1 then
        u_vektor[i] := C_xy[i, 1];
      z_vektor[i] := C_xy[i, y_ndx];
      if y_ndx = trunc(Geometry.NRows) then
        o_vektor[i] := C_xy[i, trunc(Geometry.NRows)]
      else
        o_vektor[i] := C_xy[i, y_ndx + 1];
    end;
    if not AContainerMode then
    begin
      CalcOneLine(o_vektor, Sink, trunc(Geometry.NCols), 1, trunc(Geometry.NCols), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      Geometry.testForContBorder(start_, ende_, i, y_ndx, true);
      CalcOneLine(o_vektor, Sink, trunc(Geometry.NCols), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(Geometry.NCols) do
      C_xy[i, y_ndx] := z_vektor[i];
  end;

  { Setup of the system of equations with an IMPLICIT formulation for x and
    an EXPLICIT formulation for y }

  for x_ndx := 1 to trunc(Geometry.NCols) do
  begin
    For i := 1 to trunc(Geometry.NRows) do
    begin
      AGetSink(x_ndx, i, Sink[i]);
      If x_ndx = 1 then
        u_vektor[i] := C_xy[1, i];
      z_vektor[i] := C_xy[x_ndx, i];
      if x_ndx = Geometry.NCols then
        o_vektor[i] := C_xy[trunc(Geometry.NCols), i]
      else
        o_vektor[i] := C_xy[x_ndx + 1, i];
    end;
    if not AContainerMode then
    begin
      CalcOneLine(o_vektor, Sink, trunc(Geometry.NRows), 1, trunc(Geometry.NRows), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      Geometry.testForContBorder(start_, ende_, x_ndx, i, true);
      CalcOneLine(o_vektor, Sink, trunc(Geometry.NRows), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(Geometry.NRows) do
      C_xy[x_ndx, i] := z_vektor[i];
  end;

  // write the influx of central sinks and concentration of the associated cell
  if fWriteSinkCells then
  begin
    assignfile(SinkCellFile, fSinkCellFileName);
    append(SinkCellFile);
    write(SinkCellFile, FSubmodel.GlobTime.v:6:2, ' ', dt_globmod:6:2, ' ',
      FSubmodel.GlobTime.v * 86400 + FSubmodel.SumOfInternalTimeSteps, ' ');
    for i := 0 to FSubmodel.RootList.Count - 1 do begin
      ARoot := TRootObjectIn2D(FSubmodel.RootList.Objects[i]);
      if (ARoot.xi > trunc(Geometry.NCols / 10)) and
        (ARoot.xi < Geometry.NCols - trunc(Geometry.NCols / 10)) and
        (ARoot.yi > trunc(Geometry.NRows / 10)) and
        (ARoot.yi < Geometry.NRows - trunc(Geometry.NRows / 10)) then
        write(SinkCellFile, ARoot.NInflux, ' ');
    end;
    for i := 0 to FSubmodel.RootList.Count - 1 do begin
      ARoot := TRootObjectIn2D(FSubmodel.RootList.Objects[i]);
      if (ARoot.xi > trunc(Geometry.NCols / 10)) and
        (ARoot.xi < Geometry.NCols - trunc(Geometry.NCols / 10)) and
        (ARoot.yi > trunc(Geometry.NRows / 10)) and
        (ARoot.yi < Geometry.NRows - trunc(Geometry.NRows / 10)) then
        write(SinkCellFile, C_xy[ARoot.xi, ARoot.yi], ' ');
    end;
    writeln(SinkCellFile);
    closefile(SinkCellFile);
  end;
end;
(* ------------------------------------------------------------------------------
  End of central procedure
  ------------------------------------------------------------------------------ *)


/// <summary>Calculates the sink terms (uptake and mineralization) in a computational element</summary>
/// <remarks>Units: [mol/d-1]</remarks>
/// <param name="x_loc">The x-coordinate of the computational element</param>
/// <param name="y_loc">The y-coordinate of the computational element</param>
/// <param name="s">The sink term to be calculated</param>
procedure TRasterDataNO3.Get_Sink(x_loc, y_loc: word; var s: real);

var
  i, j: integer;
  NUptake, Nuptake2, Nuptake3, NUptakeGrid, NAmountRootdt,
  // nitrogen uptake rate for current root [dg/dt]
  SumUptake, x, Db: real;
  De_SinkGrid: double;


begin
  get_minGrid(x_loc, y_loc, s); // calculate mineralization
  NUptake := 0.0;
  SumUptake := 0.0;
  De_SinkGrid := fDe / FSubmodel.theta.v;
  for i := 0 to FSubmodel.RootList.Count - 1 do
  begin
    // test whether a sink exists in the computational element, then calculate uptake
    if ((TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).xi = x_loc) and (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).yi = y_loc))
    then
    begin
      // radius of a circle corresponding to the central cell
      x := sqrt(Geometry.ColWidth * Geometry.RowHeight / pi);

      Db := FSubmodel.dl.v * 3.35 * FSubmodel.theta.v * FSubmodel.theta.v * FSubmodel.theta.v; //
      { Inner boundary condition: constant influx; this scenario can be controlled
        via parameter Ar; another influencing factor is the calculated wl_ha }
      If FSubmodel.NitrateUptakeFunction.Option = lowercase('ConstInflux') then
        NUptake := FSubmodel.Imax.v; // mol/cm*d

      // Innere Randbedingung: Zero sink
      If FSubmodel.NitrateUptakeFunction.Option = lowercase('ZeroSink') then

        // Nuptake :=
        { The flux is calculated considering the absorbing part of the root
          surface. The concentration gradient extends from the center of the
          neighboring cell to the apex of the root surface, with the root located
          centrally in the cell. See hanging file material 2D model. Note on the
          denominator: first term is the concentration gradient, second term the
          edge or the partial absorbing root surface. }
        { fDe*C_xy[x_loc-1, y_loc]/Geometry.ColWidth*Geometry.RowHeight
          +fDe*C_xy[x_loc+1, y_loc]/Geometry.ColWidth*Geometry.RowHeight
          +fDe*C_xy[x_loc, y_loc-1]/Geometry.RowHeight*Geometry.ColWidth
          +fDe*C_xy[x_loc, y_loc+1]/Geometry.RowHeight*Geometry.ColWidth; }
        { Alternative calculation of uptake by the sink: gradient reduced by
          Rad_Wurzel.v, flux in each direction corresponds to a quarter of the
          root circumference (assuming a cylindrical root). }
        { fDe*C_xy[x_loc-1, y_loc]/(Geometry.ColWidth-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +fDe*C_xy[x_loc+1, y_loc]/(Geometry.ColWidth-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +fDe*C_xy[x_loc, y_loc-1]/(Geometry.RowHeight-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +fDe*C_xy[x_loc, y_loc+1]/(Geometry.RowHeight-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2); }

        { NUptakeGrid:= fDe*C_xy[x_loc-1, y_loc]/Geometry.ColWidth*Geometry.RowHeight
          +fDe*C_xy[x_loc+1, y_loc]/Geometry.ColWidth*Geometry.RowHeight
          +fDe*C_xy[x_loc, y_loc-1]/Geometry.RowHeight*Geometry.ColWidth
          +fDe*C_xy[x_loc, y_loc+1]/Geometry.RowHeight*Geometry.ColWidth; }
        { Alternative calculation 2: inside the absorbing computation cell an
          uptake following the 1D approach was assumed, equating the area of the
          computational element with the area of the single root cylinder (see
          calculation of x above, then flux in the element is computed for radial
          coordinates). }
        // Nuptake :=     C_xy[x_loc, y_loc]*2*pi*Db/ln(x/(1.65*Rad_wurzel.v));
        { Alternative calculation 3 (cf. Kage, thesis Eq. 3.6.29, hanging file
          reformulation to In). It assumes that Cl_min corresponds to the
          concentration at the root surface and can become zero }
        NUptake := (C_xy[x_loc, y_loc] - FSubmodel.clmin.v) * 2 * pi * Db /
          (-1 / 2 + (sqr(x) / (sqr(x) - sqr(FSubmodel.rootradius.v)) *
          ln(x / FSubmodel.rootradius.v)));

/// <summary>Alternative calculation 4 (after Moncayo, Eq. 19 and 20):</summary>
      { Nuptake :=
        De_SinkGrid*C_xy[x_loc-1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc+1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc-1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc+1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2); }
/// <summary>Implementation with Cl_min</summary>
      { ZeroSink     : In_arr[pos] := fDe*(C_xy[x_loc-1, y_loc]-clmin.v)/
        Geometry.ColWidth*Geometry.RowHeight+fDe*(C_xy[x_loc+1, y_loc]-clmin.v)/Geometry.ColWidth*Geometry.RowHeight
        +fDe*(C_xy[x_loc, y_loc-1]-clmin.v)/Geometry.RowHeight*Geometry.ColWidth+fDe*
        (C_xy[x_loc,y_loc+1]-clmin.v)/Geometry.RowHeight*Geometry.ColWidth; }
      // Innere Randbedingung: Michaelis-Menten-Kinetik
      If FSubmodel.NitrateUptakeFunction.Option = lowercase('MM') then
        // NUptake :=  Influx_f( Imax.v, Km.v, C_xy[x_loc, y_loc]);
        NUptake := influx_fVar(FSubmodel.Imax.v, FSubmodel.Km.v, C_xy[x_loc, y_loc], x, Db);
      // influx into the sink during the time step

      TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NInflux := NUptake;
      If FSubmodel.NitrateUptakeFunction.Option <> lowercase('ZeroSink') then
        SumUptake := SumUptake + NUptake
      else
        SumUptake := NUptake;
      // calculate cumulative N uptake for the sinks
/// <summary>Problem: there is still a conceptual error here</summary>
      NAmountRootdt := TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NInflux * 14 / 1000 * FSubmodel.int_dt.v;
      // NAmountRootdt:=TRootObjectIn2D(Geometry.PosList.Objects[i]).NInflux*14/1000*86400/int_dt.V;
      TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NAmountdt := NAmountRootdt;
      TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NAmount := TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NAmount +
        NAmountRootdt;
    end;
  end;
/// <summary>Mineralization</summary>
  s := s - SumUptake;
end;

procedure TRasterDataNO3.get_minGrid(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of mineralization [mol/d-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  pos: word;
begin
  /// <summary>sink term from mineralization [mol/d]</summary>
  s := FSubmodel.min_s.v * (Geometry.ColWidth * Geometry.RowHeight);
end;

procedure TRasterDataNO3.CalcRates;
(* ------------------------------------------------------------------------------
  DESCRIPTION: This method invokes the control flow of the submodel for rate
  calculation.
  ------------------------------------------------------------------------------ *)
var
  ConcFieldName: string;
  ConcField, UptakeFile: Textfile;
  i, j: integer;
  last_dt,
/// <summary>difference between concBefore and conc</summary>
  concBegin, // average concentration before calculating fluxes [mol/cm^3]
  ConcAfter, { average concentration after calculating fluxes [mol/cm^3]
    and before redistributing absorbed concentrations to the computational
    elements }
  // SumOfInternalTimeSteps,
  /// <summary>N amount taken up by all valid roots in the time step</summary>
  sumNAmountRootsdt
    : real;
  TimeStepAdaption: boolean;
  /// <summary>Store the endpoint at the same precision as the accumulated internal time.</summary>
  TargetTimeSeconds: double;
begin
  if not Assigned(FSubmodel.GlobTime) then
    raise Exception.Create('Nitrate transport requires an initialized model clock');
  TargetTimeSeconds := FSubmodel.GlobTime.c * 86400;
  if IsNan(TargetTimeSeconds) or IsInfinite(TargetTimeSeconds) or (TargetTimeSeconds < 0) then
    raise Exception.Create('Nitrate transport requires a finite nonnegative timestep');
  if TargetTimeSeconds = 0 then
    Exit;
  if IsNan(FSubmodel.int_dt.v) or IsInfinite(FSubmodel.int_dt.v) or (FSubmodel.int_dt.v <= 0) then
    raise Exception.Create('Nitrate transport requires a finite positive internal timestep');
  /// <summary>nothing happens in the base model (no inherited call)</summary>
  ConcFieldName := ConcFieldDataFile.Option;
  // Communication with the structural model and display of WAP in MathImNutrUptake
  // create new file with outputs for the sinks:
  for i := 0 to FSubmodel.rootlist.Count-1 do
  begin
    TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NAmount := 0;
  end;
  if (OutputSink.Option = 'yes') and not FFileWasCreated then
  begin
    assignfile(UptakeFile, RootSinkOutpDataFile.Option);
    rewrite(UptakeFile);
    closefile(UptakeFile);
    FFileWasCreated := true;
  end;
  if FSubmodel.inimethod.Option = 'submodstruct' then
  begin
//    updateFromStructModell;
    // as long as no roots exist, no fluxes are calculated
    if FSubmodel.num_roots.v < 1 then
      exit;
    FSubmodel.fillchartrootdistr;
  end;
  { Since theta may change in the dynamic model, De must be recalculated each
    time step }
  fDe := FSubmodel.dl.v * 3.35 * sqr(FSubmodel.theta.v) * FSubmodel.theta.v;
  // fDe:=Dl.v*3.35*sqr(theta.v);
  TimeStepAdaption := false;
  FSubmodel.sumofinternaltimesteps := 0.0;
  last_dt := 0.0;
  FSubmodel.actarfromconc.v := 0;
  FSubmodel.actar.v := 0;
  repeat
    if FSubmodel.int_dt.v < FSubmodel.max_dt.v then
      FSubmodel.int_dt.v := FSubmodel.int_dt.v * 1.1; // increase time step
    If FSubmodel.int_dt.v > TargetTimeSeconds then
      FSubmodel.int_dt.v := TargetTimeSeconds;
/// <summary>Has the end of the day been exceeded with the new time step?</summary>
    If FSubmodel.sumofinternaltimesteps + FSubmodel.int_dt.v > TargetTimeSeconds then
    begin
      last_dt := FSubmodel.int_dt.v; // save old time step length
      FSubmodel.int_dt.v := (TargetTimeSeconds - FSubmodel.sumofinternaltimesteps);
      TimeStepAdaption := true;
    end;
    // calculate fluxes
    concBegin := avg_conz;
    zweid_solut(FSubmodel.int_dt.v, Get_Sink, ContGrowth.Option <> 'no');
    FSubmodel.sumofinternaltimesteps := FSubmodel.sumofinternaltimesteps + FSubmodel.int_dt.v;
    { In each time step the cumulative N uptakes of the individual, non-marginal
      sinks are summed. Return value is the total N amount the roots have taken
      up in a time step }
    sumNAmountRootsdt := calcAmountUptakeRoots;
    FSubmodel.sumnuptake.v := FSubmodel.sumnuptake.v + sumNAmountRootsdt;
    { At the end of each internal time step the absorbed influx is redistributed
      to the computational elements }
    { If a steady-state condition should be generated, the constant concentration
      is restored in every time step }
    ConcAfter := avg_conz;
    FSubmodel.actarfromconc.v := FSubmodel.actarfromconc.v + Mg_func(FSubmodel.depth.v, FSubmodel.theta.v,
      concBegin - ConcAfter);
    { For the calculation of the current uptake rate only roots not in the
      margins are considered }
    FSubmodel.actar.v := FSubmodel.actar.v + calcActArdt;
    if SteadyState.Option = 'yes' then
      createSteadyState(concBegin - ConcAfter);
    // write the concentration field in the last internal time step
    if FSubmodel.sumofinternaltimesteps >= TargetTimeSeconds then
    begin
      if writeConcField.Option = 'yes' then
      begin
        assignfile(ConcField, ConcFieldName);
        rewrite(ConcField);
        // new file; only the final concField is written
        // header
        for i := 0 to trunc(Geometry.NCols + 1) do
        begin
          for j := 0 to trunc(Geometry.NRows + 1) do
          begin
            write(ConcField, C_xy[i, j], ' ');
          end;
          writeln(ConcField);
        end;
        closefile(ConcField);
      end;
    end;
  until FSubmodel.sumofinternaltimesteps >= TargetTimeSeconds;
  // if an adaptation of the time step length is intended
  If TimeStepAdaption then
    FSubmodel.int_dt.v := last_dt; // restore old time step length
  If FSubmodel.int_dt.v <= 0.0 then
    showMessage('time step error');
  // output of concentration change
  if Assigned(FOnConcentrationChanged) then
    FOnConcentrationChanged(Self);
  // write valid root data to a file
  if (FSubmodel.outputxy.Option = 'yes') then
  begin
    FSubmodel.writeoutputtofile(FSubmodel.RootXYOutpDataFile.Option, FSubmodel.globtime.v);
  end;
  if (OutputSink.Option = 'yes') then
  begin
    writeNitrateUptakeSinkToFile;
  end;
end; // End TSubmodRootDiff.CalcRates



procedure TRasterDataNO3.InitConc;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Startkonz. aus der initialen N-Menge
  ------------------------------------------------------------------------------ *)
var
  x_ndx, y_ndx: integer;
  NAmountGridzell: double;
begin
  { Berechnen der N-Menge in einer Gridzelle von kg/ha auf g/dim_x*dim_y, die 1000
    im Nenner stammen von der Umrechnung von kg auf g }

  // NAmountGridzell:=N_AmountSoil.V*1000/(Geometry.NCols*Geometry.NRows*10000*vol_Element);  //g N/cm3
  // NAmountGridzell/(theta.v*14*Tiefe.V);   //mol/cm^3
  FSubmodel.c_start.v := Cl_func(FSubmodel.depth.v, FSubmodel.theta.v, FSubmodel.namount.v);
  // c_start.v := NAmountGridzell/(theta.v*Tiefe.v*1e8*14)*1000; //alte Implement.
  For x_ndx := 0 to trunc(Geometry.NCols + 1) do
  begin
    for y_ndx := 0 to trunc(Geometry.NRows + 1) do
    begin
      // C_xy[x_ndx, y_ndx] := c_start.v*(1+x_ndx/1)*(1+y_ndx/1);
      C_xy[x_ndx, y_ndx] := FSubmodel.c_start.v;
    end;
  end;
end;


procedure TRasterDataNO3.InitializeModel;
begin
  FFileWasCreated := false;
  FSinkCellFileWasCreated := false;
  fWriteSinkCells := writeSinkCellFile.Option = 'yes';
  fSinkCellFileName := SinkCellFileFile.Option;
  InitConc;

end;

procedure TRasterDataNO3.createSteadyState(DiffSteadyState: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Erzeugt einen Steady-State-Zustand nach folgendem Verfahren
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
begin
  { die gesamte aufgenommene Menge wird gleichmäßig auf alle Rechenelemente verteilt: }
  for i := 0 to trunc(Geometry.NCols + 1) do
    for j := 0 to trunc(Geometry.NRows + 1) do
    begin
      C_xy[i, j] := C_xy[i, j] + DiffSteadyState;
    end;
end;



function TRasterDataNO3.avg_conz: double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG:  Berechnung von Durchschnittskonzentrationen
  Problem: Sollen randständige Rechenelemente von Berechnung ausgeschlossen werden?
  Quelltext hierfür in Programmiertagebuch vorhanden.
  ------------------------------------------------------------------------------ *)
var
  i, j,
  { erstes und letztes Rechenelement das nicht im Rand liegt, jeweils in x und y-
    Richtung }
  numb1stElemX, numbLastElemX, numb1stElemY, numbLastElemY: integer;
  conc: double;

begin
  min_c := 1E100;
  max_c := 0.0;
  conc := 0.0;
  if CalcModeSteadyState.Option = 'withMargin' then
  begin
    { Randständige Zeilen und Spalten werden berücksichtigt. }
    for i := 1 to trunc(Geometry.NCols) - 1 do
      for j := 1 to trunc(Geometry.NRows) - 1 do
      begin
        // Aufsummerieren der Konzentrationen sämtlicher Rechenelemente:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Mitteln: Teilen durch die Summe der Elemente }
    conc := conc / (Geometry.NCols * Geometry.NRows);
  end
  else // wenn die Ränder nicht berücksichtigt werden sollen.
  begin
    numb1stElemX := trunc((Geometry.NCols - FSubmodel.dim_xmiddle.v) / 2);
    numbLastElemX := trunc(Geometry.NCols - (Geometry.NCols - FSubmodel.dim_xmiddle.v) / 2);
    numb1stElemY := trunc((Geometry.NRows - FSubmodel.dim_ymiddle.v) / 2);
    numbLastElemY := trunc(Geometry.NRows - (Geometry.NRows - FSubmodel.dim_ymiddle.v) / 2);
    for i := numb1stElemX to numbLastElemX - 1 do
      for j := numb1stElemY to numbLastElemY - 1 do
      begin
        // Aufsummerieren der Konzentrationen sämtlicher Rechenelemente:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Mitteln: Teilen durch die Summe der mittigen Elemente }
    conc := conc / ((numbLastElemX - numb1stElemX) *
      (numbLastElemY - numb1stElemY));
  end;
  Result := conc;
end;


function TRasterDataNO3.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: alternative Berechnung des Influx mit Michaelis-Menten-Randbedingung
  unter der Voraussetzung, dass im Einzelwurzelzylinder mit dem quasistationären
  Ansatz gearbeitet wird.
  entspricht dem 2D-S Ansatz (erweitert um Michaelis-Menten-Kinetik). Berechnung
  vor allem der Formel für cla muss noch einmal kontrolliert werden.
  ------------------------------------------------------------------------------ *)
var
  cla, // Konzentration an der Wurzeloberfläche
  influx, // Nährstoffinfluxrate [mol cm^-1 d^-1]
  numerator // Zähler in Gleichung 3.6.33, Diss. Kage
    : double;
begin
  numerator := Km + (sqr(x) * Imax / ((sqr(x) - sqr(FSubmodel.rootradius.v)) * 2 * pi *
    Db)) * ln(x / FSubmodel.rootradius.v) - Imax / (4 * pi * Db);
  cla := FSubmodel.clmin.v + (-ClAv + numerator) / 2;
  cla := cla + sqrt(sqr(ClAv + numerator) / 4 + ClAv * Km);
  influx := Imax * (cla - FSubmodel.clmin.v) / (Km + (cla - FSubmodel.clmin.v));
  If (influx <= 0.0) or (ClAv <= 0.0) // Keine negativen Flüsse
  then
    influx := 0.0;
  Result := influx;
end;

function TRasterDataNO3.calcAmountUptakeRoots: double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Summe aus den kumulierten N-Aufnahmen aller gültigen Wurzeln (im
  Beobachtungsfenster vorhanden, aber nicht in den Rändern). Eigentlich Ratenbe-
  rechnung, aber notwendig, da nicht alle Wurzeln berücksichtigt werden sollen.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  NAmountRoot: double;

begin
  NAmountRoot := 0;
  for i := 0 to FSubmodel.RootList.Count - 1 do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).x >= FSubmodel.verticmargin.v) and
      (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).x <= FSubmodel.dimensionx.v - FSubmodel.verticmargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).y >= FSubmodel.horizmargin.v) and
      (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).y <= FSubmodel.dimensiony.v - FSubmodel.horizmargin.v) then
    begin
      NAmountRoot := NAmountRoot + convertConcToAmount(i);
    end;
  end;
  { Teilen durch areaMiddle -> Aufnahme bezogen auf Quadratcentimenter, Multiplika-
    tion mit 10^8 -> Aufnahmemenge bezogen auf bestimmte Tiefe und ha. }
  Result := NAmountRoot / FSubmodel.areamiddle.v * 1E8; // 10 hoch 8 cm^2 pro ha
  { Warum geht das nicht:
    Sum_N_AmountRoots.V:=Sum_N_AmountRoots.V+Ar.v; }
end;

function TRasterDataNO3.convertConcToAmount(i: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rechnet die Aufnahme [mol/cm*d] in Menge [kg/d], für übergebene
  Wurzeln.
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000;
var
  ha: integer;
  NAmountRoot: double;
begin
  { NINflux in [mol/cm/d }
  NAmountRoot := TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NInflux * kg_mol * FSubmodel.depth.v * FSubmodel.int_dt.v;
  Result := NAmountRoot;
end;

function TRasterDataNO3.calcActArdt: double;
(* ------------------------------------------------------------------------------
  Berechnet die Aktuelle im internen Zeitschritt:
  Aufnahmerate, wobei nur Wurzeln berücksichtigt werden,
  die sich nicht in den Rändern befinden. Zur Berechnung der Einheiten: Bezug auf
  den Hektar wird geleistet, indem auf die wl_ha bezogen wird.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  AvNMenge, AVInflux: double;
  rootCounter: integer;
begin
  Result := 0;
  rootCounter := 0;
  AvNMenge := 0;
  AVInflux := 0;
  for i := 0 to FSubmodel.RootList.Count - 1 do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).x >= FSubmodel.verticmargin.v) and
      (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).x <= FSubmodel.dimensionx.v - FSubmodel.verticmargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).y >= FSubmodel.horizmargin.v) and
      (TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).y <= FSubmodel.dimensiony.v - FSubmodel.horizmargin.v) then
    begin
      AVInflux := AVInflux + TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NInflux;
      AvNMenge := AvNMenge + TRootObjectIn2D(FSubmodel.rootlist.Objects[i]).NAmount;
      inc(rootCounter);
    end;
  end;
  if FSubmodel.number_consid_roots.v <> 0 then
  begin
    AVInflux := AVInflux / FSubmodel.number_consid_roots.v;
    // Berücksichtigt nur den Influx aus dem letzten internen Zeitschritt:
    Result := AVInflux * 14 / 1000 * FSubmodel.wl_ha.v * FSubmodel.int_dt.v;
    // Result:= AvInflux*14/1000*wl_ha.v
    // AvNMenge:=AvNMenge/rootCounter;
    // ActAr.v := AvNMenge*wl_ha.v;
  end;
end;


/// <summary>Appends nitrate uptake of roots inside the observation window.</summary>
procedure TRasterDataNO3.WriteNitrateUptakeSinkToFile;
var
  F: TextFile;
  i: integer;
  Root: TRootObjectIn2D;
begin
  AssignFile(F, RootSinkOutpDataFile.Option);
  if FileExists(RootSinkOutpDataFile.Option) then
    Append(F)
  else
    Rewrite(F);
  try
    Writeln(F, 'Modellzeit: ', FSubmodel.GlobTime.v:6:2, ' ');
    Writeln(F, 'Lfd.Nr. X Y Flaeche N-Aufnahme ');
    for i := 0 to FSubmodel.RootList.Count - 1 do
    begin
      Root := TRootObjectIn2D(FSubmodel.RootList.Objects[i]);
      if (Root.x >= FSubmodel.verticMargin.v) and
        (Root.x <= FSubmodel.DimensionX.v - FSubmodel.verticMargin.v) and
        (Root.y >= FSubmodel.horizMargin.v) and
        (Root.y <= FSubmodel.DimensionY.v - FSubmodel.horizMargin.v) then
        Writeln(F, Root.nroot, ' ', Root.x, ' ', Root.y, ' ',
          Root.Area, ' ', Root.NInflux, ' ');
    end;
    Writeln(F);
  finally
    CloseFile(F);
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
{$IFNDEF CONSOLE}
  RegisterComponents('Simulation', [TSubmodRoot2DNO3]);
{$ENDIF}
{$ENDIF}
end;

end.
