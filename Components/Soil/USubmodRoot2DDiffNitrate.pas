unit USubmodRoot2DDiffNitrate;

 {$J+}
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid,
  UMod, UState, Diffko, SubmodRootStructureNew, U2DSoilBaseClasses, MathImge;


type
  /// <summary>Type declarations</summary>
  /// <summary>Records and sets</summary>




  /// <summary> Declaration of class TSubmodRootDiff. Class based on base class for derived diffusion models
  /// implements further details for nitrate transport
  /// </summary>
  TSubmodRoot2DDiffNitrate = class(TBaseSubmodRootDiff)
  private
    /// <summary>
    ///   diffusive nitrate uptake rate
    /// </summary>
    Diffuptake: double;
    fMyMathImage: TMathImage;
    ColorSurface: TColorSurface;

    procedure zweid_solut(dt_globmod: real);
    // Helper methods
    procedure InitConc;
    procedure createSteadyState(DiffSteadyState: double);
    function avg_conz: double;
    function influx_fVar(Imax, Km, ClAv, x, Db: double): double;

    function calcAmountUptakeRoots: double;
    function calcActArdt: double;
    function convertConcToAmount(i: integer): double;
    procedure writeNitrateUptakeSinkToFile;

  protected
    /// <summary>Protected declarations, also accessible by derived classes</summary>
    ///
    /// <summary>uptake rate [Kg N/ha*d]</summary>
    Ar: TPar;

    /// <summary>Diffusion coefficient of nitrate in free H2O [cm^2/s]</summary>
    Dl: TPar;

    /// <remarks>Mineralization model not yet available but should be implemented for both models</remarks>
    /// <summary>Mineralization rate [kg N/ha*d]</summary>
    minera: TPar;
    /// <summary>Minimum soil solution concentration [Mol/l], also needed for the numerical solution in the 1D model; note: originally in micromol/l</summary>
    Clmin: TPar;

    /// <summary>Michaelis-Menten constant [mol/cm3]</summary>
    Km: TPar;



    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>

    /// <summary>Member HUME base class TState (state variables)</summary>
    /// <summary>N amount [kg N/ha], also basis for calculating concentrations in the calculation elements; see Kage dissertation p.79 where concentrations of 10.0 micromol/l were assumed</summary>
    N_AmountSoil: TState;
    /// <summary>Cumulative amount of N taken up by the roots [kg N/ha] for the specified depth</summary>
    Sum_N_AmountRoots: TState;
    /// <summary>Member HUME base class TVar (variables)</summary>

    /// <summary>Mineralization rate [Mol/cm^3*s]</summary>
    Min_S: TVar;
    /// <summary>Initial concentration [mol/cm^3], calculated from the initial N amount; the 1D model can also calculate concentrations</summary>
    c_start: TVar;
    /// <summary>Average concentration in the soil solution [Mol/cm^3]</summary>
    cl_av: TVar;
    /// <summary>Effective diffusion coefficient [cm^2/s]</summary>
    De: TVar;

   /// <summary>maximum influx [mol/cm*s]</summary>
   Imax: TVar;

    ActArFromConc : TVar;
    ActAr : TVar;

    /// <summary>
    /// average Concentration [mol/cm3]
    /// </summary>
    c_av: TVar;




    /// <summary>Type of uptake calculation</summary>
    NitrateUptakeFunction: TOption;

    OutputSink: Toption; { specify whether nutrient uptake of individual sinks
      should be written to a file }
    RootDistribution: TOption; { define the distribution of WAP, differs from
      the 1D model }
    CalcModeSteadyState: TOption; { specify the mode in which steady state
      should be calculated (with or without margins) }
    ShowConc: TOption; { specify whether concentrations should be displayed
      or not }
    SteadyState: TOption; { flag whether a steady state should be generated
      in the 2D model or not }
    RootSinkOutpDataFile: TOption; { path and name of the output file for nutrient
      uptake of individual sinks }
    // Switches to control whether the following files are written.
    writeConcField: TOption;
    writeSinkCellFile: TOption;
    ConcFieldDataFile: TOption;
    { path and name of the output file for nutrient uptake of
      individual sinks }
    SinkCellFileFile: TOption; { path and name of the output file for nutrient
      uptake of individual sinks }
    /// <summary>deletes boundary roots from PosArr</summary>
    DelMarginRoots: TOption;
    /// <summary>switch for growth in pots</summary>
    ContGrowth : TOption;

  public
    /// <summary>Public declarations</summary>
    /// <summary>Flag for one-time write access</summary>
    procedure createAll; override;
    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobModReferenz: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure Get_Sink(x_loc, y_loc: word; var s: real);
    procedure get_minGrid(x_loc, y_loc: word; var s: real);
    // Helper method
    /// <summary>current concentrations can be output via a form</summary>
    procedure showActConc;

  published
    /// <summary>Published declarations</summary>
    property MyMathImage: TMathImage read fMyMathImage write fMyMathImage;

  end; { Ende Deklaration TSubmodRootDiff }

//var
  /// <summary>
  /// Stores the root positions read from a file. A global variable is necessary,
  /// because when PosArr_eingelesen is a member of an object, an unexplained crash
  /// occurs.
  /// </summary>


  //  PosArr_FromFile: array [1 .. max_num_roots] of TRootPosition;

procedure Register;



implementation



{ -------------------------------------------------------------------- }
{ -------------------------   MODUL TRDIAG  -------------------------- }
{ ------------ Lösung eines tridiagonalen Gleichungssystems ---------- }
{ ----------- Aus Formelsammlung zur numerischen Mathematik ---------- }
{ --------------------------------------------------------------------- }

function trdiag(rep: boolean; { Wiederholungsflagge }
  max_n, min_n: Integer; { Dimension der Matrix }
  var lower, { Subdiagonale }
  diag, { Diagonale }
  upper, { Superdiagonale }
  b: array of double { Rechte Seite des Systems }
  ): byte; { Fehlerparameter }
{ ==================================================================== }
{ trdiag bestimmt die Loesung x des linearen Gleichungssystems }
{ A * x = b mit tridiagonaler n x n Koeffizientenmatrix A, die in }
{ den 3 Vektoren lower, upper und diag wie folgt abgespeichert ist: }
{ }
{ ( diag[min_n] upper[min_n]    0        0  .   .     .   0          ) }
{ ( lower[min_n+1] diag[min_n+1]   upper[min_n+1]   0      .     .   .          ) }
{ (   0      lower[min_n+2]  diag[min_n+2]  upper[min_n+2]   0       .          ) }
{ A =  (   .        0       lower[5]  .     .       .              ) }
{ (   .          .           .        .     .      0          ) }
{ (   .              .           .        .      .            ) }
{ (                    .           .         . upper[max_n-1] ) }
{ (   0 .   .    .   .     0     lower[max_n]    diag[max_n]  ) }
{ ==================================================================== }
{ Anwendung: }
{ Vorwiegend fuer diagonaldominante Tridiagonalmatrizen, wie }
{ sie bei der Spline-Interpolation auftreten. }
{ Fuer diagonaldominante Matrizen existiert immer eine LU- }
{ Zerlegeung; fuer nicht diagonaldominante Tridiagonalmatrizen }
{ sollte die Funktion band vorgezogen werden, da diese mit }
{ Spaltenpivotsuche arbeitet und daher numerisch stabiler ist. }
{ ==================================================================== }
{ Eingabeparameter: }
{ }
{ Name    Typ         Bedeutung }
{ ---------------------------------------------------------------- }
{ rep     byte        Aufrufart von trdiag }
{ = True : Bestimmung der Zerlegungsmatrix und }
{ Berechnung der Loesung des Systems }
{ = False: Nur Loesen des Gleichungssystems; }
{ zuvor muss die Zerlegungsmatrix be- }
{ stimmt sein. }
{ n       integer     n > 1; Anzahl der Komponenten von lower }
{ diag, upper }
{ bei rep = False: }
{ lower   RealVector  untere Nebendiagonale; lower[i], i=1(1)n-1 }
{ diag    RealVector  Hauptdiagonale;        diag[i],  i=0(1)n-1 }
{ upper   RealVector  obere Nebendiagonale;  upper[i], i=0(1)n-2 }
{ b       RealVector  Rechte Seite des Systems: b[i], i=0(1)n-1 }
{ }
{ Ausgabeparameter: }
{ Name    Typ         Bedeutung }
{ --------------------------------------------------------------- }
{ lower   RealVector  ) }
{ diag    RealVector  ) enthalten die LU-Zerlegung }
{ upper   RealVector  ) }
{ b       RealVector  Loesungsvektor des Systems: b[i], i=0(1)n-1 }
{ det(A) = diag[0] *..* diag[n-1]. }
{ Rueckgabewert: }
{ = 0 : alles ok }
{ = 1 : n < 2 oder n > MAXDIM_1 gewaehlt }
{ = 2 : LU-Zerlegung existiert nicht }
{ ==================================================================== }

var
  i: Integer;

begin

  if not(rep) then { Wenn rep:=false ist, }
  begin { Dreieckzerlegung der }
    for i := min_n + 1 to max_n do { Matrix bestimmen }
    begin
      if (abs(diag[i - 1]) < 1E-16) then { Wenn ein diag[i] = 0 }
      begin
        trdiag := 2;
        exit;
      end; { ist, ex. keine Zerle- }
      lower[i] := lower[i] / diag[i - 1]; { gung. }
      diag[i] := diag[i] - lower[i] * upper[i - 1];
    end;
    if (abs(diag[max_n]) < 1E-16) then
    begin
      trdiag := 2;
      exit
    end;
  end;
  for i := min_n + 1 to max_n do { Vorwaertselimination }
    b[i] := b[i] - lower[i] * b[i - 1];
  b[max_n] := b[max_n] / diag[max_n]; { Rueckwaertselimination }
  for i := max_n - 1 downto min_n do
    b[i] := (b[i] - upper[i] * b[i + 1]) / diag[i];
  trdiag := 0;
end;

{ --------------------------  ENDE TRDIAG  --------------------------- }

function ndx_str(i: Integer): string;
begin
  if i <= 9 then
    result := '_' + IntTostr(i)
  else
    result := '' + IntTostr(i);
end;




/// <summary>Implementierung TSubmodRootDiff</summary>
/// <summary>
/// Creates and initializes state variables, variables and parameters. The first
/// parameter of the function call passes a string identical to the identifier and
/// can be searched for. The second parameter contains a string indicating the
/// unit used ([-] for dimensionless parameters, etc.). The third parameter is the
/// actual floating-point value. For an explanation of the identifiers, see the
/// declaration.
/// </summary>
procedure TSubmodRoot2DDiffNitrate.createAll;
begin
  inherited createAll;
  ParCreate('Ar', '[kg N/ha*d]', 0, Ar);

  ParCreate('Minera', '[kg N/ha*d]', 0, minera);
  ParCreate('Dl', '[cm^2/s]', 1.92E-5, Dl);
  ParCreate('Clmin', '[mol/l]', 0, Clmin);
  ParCreate('Km', '[mikromol/l]', 0, Km, '');

  // Create and initialize TState
  StateCreate('N_AmountSoil', '[kg N/ha]', 0, false, N_AmountSoil);
  StateCreate('Sum_N_AmountRoots', '[kg N/ha]', 0, false, Sum_N_AmountRoots);
  // Create and initialize TVar
  { Caveat: variables are always initialized to 0. If a start value other than 0 is
    needed, calculation and assignment must occur in init. It would be better not to
    declare such variables as TVar. }

  VarCreate('Min_s', '[Mol/cm^3*s]', 0, false, Min_S);
  VarCreate('c_start', '[Mol/cm^3]', 0, false, c_start);
  VarCreate('cl_av', '[Mol/cm^3]', 0, false, cl_av);
  VarCreate('De ', '[cm^2/s]', 0, false, De);
  VarCreate('Imax', '[mol/cm/s]', 0, false, Imax);

  VarCreate('ActArFromConc', '[mol/cm/s]', 0, false, ActArFromConc);
  VarCreate('ActAr', '[mol/cm/s]', 0, false, ActAr);
  VarCreate('C_av', '[mol/cm3]', 0, false, C_av);


  // Create and initialize TOption
  { Specify the source of the root data }
  { Define uptake function }
  OptCreate('NitrateUptake_function', 'ZeroSink', NitrateUptakeFunction);
  NitrateUptakeFunction.OptionList.add('ZeroSink');
  NitrateUptakeFunction.OptionList.add('ConstInflux');
  NitrateUptakeFunction.OptionList.add('MM');

  OptCreate('ContGrowth', 'no', ContGrowth);
  ContGrowth.OptionList.add('yes');
  ContGrowth.OptionList.add('no');

  OptCreate('ShowConc', 'True', ShowConc);
  ShowConc.OptionList.add('true');
  ShowConc.OptionList.add('false');

  OptCreate('CalcModeSteadyState', 'withoutMargin', CalcModeSteadyState);
  CalcModeSteadyState.OptionList.add('withMargin');
  CalcModeSteadyState.OptionList.add('withoutMargin');

  OptCreate('SteadyState', 'no', SteadyState);
  SteadyState.OptionList.add('yes');
  SteadyState.OptionList.add('no');

  OptCreate('RootDistribution', 'Random', RootDistribution);
  RootDistribution.OptionList.add('Random');
  RootDistribution.OptionList.add('Regular');
  RootDistribution.OptionList.add('FromSource');

  OptCreate('DelMarginRoots', 'no', DelMarginRoots);
  DelMarginRoots.OptionList.add('yes');
  DelMarginRoots.OptionList.add('no');

  OptCreate('writeConcField', 'no', writeConcField);
  writeConcField.OptionList.add('no');
  writeConcField.OptionList.add('yes');

  OptCreate('writeSinkCellFile', 'no', writeSinkCellFile);
  writeSinkCellFile.OptionList.add('no');
  writeSinkCellFile.OptionList.add('yes');

  OptCreate('OutputSink', 'no', OutputSink);
  OutputSink.OptionList.add('no');
  OutputSink.OptionList.add('yes');

  OptCreate('ConcFieldDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv', ConcFieldDataFile);
  ConcFieldDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv');

  OptCreate('SinkCellFileFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv', SinkCellFileFile);
  SinkCellFileFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv');

  OptCreate('RootSinkOutpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat', RootSinkOutpDataFile);
  RootSinkOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat');

  OptCreate('OutputXY', 'no', OutputXY);
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Paths for model comparison 1D vs 2D }
  { Paths to input and output files are identical for both submodels. Running both
    submodels simultaneously in one model run only makes sense for comparison. }





end; // End TSubmodRootDiff.CreateAll

/// <summary>Performs various initializations</summary>
procedure TSubmodRoot2DDiffNitrate.AddDataValueToDataSeries;
var
  i: integer;
  // Number of grid cells in X and Y direction
  numberGridCellsX, numberGridCellsY: integer;
begin
  inherited;
  // Rewrite output file for XY coordinates

  AssignFile(xyFile, RootXYOutpDataFile.Option);
  rewrite(xyFile); { Create or replace the file; it is rewritten for each model run }
  closeFile(xyFile);
  numberGridCellsX := trunc(dimensionX.v / gridWidth.v);
  numberGridCellsY := trunc(dimensionY.v / self.gridHeight.v);
  setLength(RasterData.CountArr, trunc(numberGridCellsX));
  for i := 0 to high(RasterData.CountArr)-1 do
  begin
    setLength(RasterData.CountArr[i], trunc(numberGridCellsY));
  end;
  { Calculation of the diffusion coefficient of the solution in soil from the
    effective diffusion coefficient. See Kage dissertation p.43f.: for the 1D model
    (Nye/Tinker, Solute movement p.299) the effective diffusion coefficient is needed.
    It is calculated as De = Dl * f, where Dl is the diffusion coefficient in free
    water and f is the impedance factor. The relationship between theta and f is
    given by f = 3.35 * Theta^2 (Kage, p.41). }
  De.v := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  { Calculation of effective diffusion coefficient [cm2/s] for the 2D model }
  // De.v := Dbf(theta.v)/Theta.v; //alte Implementierung
  // Initialize TVar where appropriate at this stage
  Area := dimensionX.v * dimensionY.v;
  { Area of the layer under investigation }
  Volume.v := Area * Depth.v;
  { Calculation of mineralization rate in [Mol/cm3*s] }
  // Min_S.V := minera.v/14*1000/86400*1/(Tiefe.v*1e8);
  Min_S.v := minera.v * 1000 / (14 * 86400 * Depth.v * 1E8);
  { Calculation of the initial N amount in the soil layer from the concentration.
    Issue: Should theta be multiplied here because the concentration refers only to
    the volume of water contained in the soil? }
  // Init_NAmount_layer.V:=c_start.V*volumen.V*14/1000;
  { About the units:
    [g] = Mol/l * l * g/Mol }
  { Implementation of a check for previous initialization. This allows easy extension
    for initializations requiring file access or object instantiation. This should be
    done in the _init method. Initializations should only be performed when roots
    have already been read. The original TSubmodel method cannot be used because it
    is called multiple times. }

end;


procedure TSubmodRoot2DDiffNitrate.zweid_solut(dt_globmod: real);
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
  Df: real;
  /// <summary>loop variables for grid elements</summary>
  x_ndx, y_ndx: integer;

  SinkCellFile: Textfile;
  SinkCellFileName: string;

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
      flow_1 := dx.v * De.v * (u_vektor[Start] - z_vektor[Start]) / dy.v * Df;
      // explicit calculation
      flow_2 := dx.v * De.v * (z_vektor[Start] - o_vektor[Start]) / dy.v * Df;

      B_vektor[Start] := z_vektor[Start] + flow_1 - flow_2 + Sink[Start] * Df;
      diag[Start] := De.v * dy.v / dx.v * Df + 1;
      upper[Start] := -De.v * dy.v / dx.v * Df;
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
        flow_1 := dx.v * De.v * (u_vektor[ndx] - z_vektor[ndx]) / dy.v * Df;
        flow_2 := dx.v * De.v * (z_vektor[ndx] - o_vektor[ndx]) / dy.v * Df;

        B_vektor[ndx] := z_vektor[ndx] + flow_1 - flow_2 + Sink[ndx] * Df;
        lower[ndx] := -De.v * dy.v / dx.v * Df;
        diag[ndx] := De.v * dy.v / dx.v * Df + De.v * dy.v / dx.v * Df + 1;
        upper[ndx] := -De.v * dy.v / dx.v * Df;
      end;
    end; // End Mittelteil

    Procedure RightBoundary(Ende: integer);
    (* ------------------------------------------------------------------------------
      PARENT method: helper procedure eine_Zeile
      ------------------------------------------------------------------------------ *)
    var
      i: integer;
    begin
      flow_1 := dx.v * De.v * (u_vektor[Ende] - z_vektor[Ende]) / dy.v * Df;
      flow_2 := dx.v * De.v * (z_vektor[Ende] - o_vektor[Ende]) / dy.v * Df;

      B_vektor[Ende] := z_vektor[Ende] + flow_1 - flow_2 +
        Sink[trunc(dim_x.v)] * Df;
      lower[Ende] := -De.v * dy.v / dx.v * Df;
      diag[Ende] := De.v * dy.v / dx.v * Df + 1;
      For i := Ende + 1 to trunc(dim_x.v) do
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
    if self.writeSinkCellFile.Option = 'yes' then
    begin
      SinkCellFileName := SinkCellFileFile.Option;
      if SinkCellFileWasCreated = false then
      begin
        deleteFile(SinkCellFileName);
        assignfile(SinkCellFile, SinkCellFileName);
        rewrite(SinkCellFile);
        // Header
        write(SinkCellFile, 'SimZeit', ' ', 'dt_akt[s]', ' ', 'sumDtInt[s]',
          ' ', 'Influx', ' ', 'Konz_Zelle');
        writeln(SinkCellFile);
        closefile(SinkCellFile);
        SinkCellFileWasCreated := true;
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
  Df := int_dt.v / 2 * 1 / wm;
  { Setup of the system of equations with an IMPLICIT formulation for y and
    an EXPLICIT formulation for x }
  // iterate over all computational elements (except the 1 cell wide margins)

  for y_ndx := 1 to trunc(dim_y.v) do
  begin
    For i := 1 to trunc(dim_x.v) do
    begin
      Get_Sink(i, y_ndx, Sink[i]); // calculate sink terms
      If y_ndx = 1 then
        u_vektor[i] := C_xy[i, 1];
      z_vektor[i] := C_xy[i, y_ndx];
      if y_ndx = trunc(dim_y.v) then
        o_vektor[i] := C_xy[i, trunc(dim_y.v)]
      else
        o_vektor[i] := C_xy[i, y_ndx + 1];
    end;
    if ContGrowth.Option = 'no' then
    begin
      CalcOneLine(o_vektor, Sink, trunc(dim_x.v), 1, trunc(dim_x.v), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      testForContBorder(start_, ende_, i, y_ndx, true);
      CalcOneLine(o_vektor, Sink, trunc(dim_x.v), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(dim_x.v) do
      C_xy[i, y_ndx] := z_vektor[i];
  end;

  { Setup of the system of equations with an IMPLICIT formulation for x and
    an EXPLICIT formulation for y }

  for x_ndx := 1 to trunc(dim_x.v) do
  begin
    For i := 1 to trunc(dim_y.v) do
    begin
      Get_Sink(x_ndx, i, Sink[i]);
      If x_ndx = 1 then
        u_vektor[i] := C_xy[1, i];
      z_vektor[i] := C_xy[x_ndx, i];
      if x_ndx = dim_x.v then
        o_vektor[i] := C_xy[trunc(dim_x.v), i]
      else
        o_vektor[i] := C_xy[x_ndx + 1, i];
    end;
    if ContGrowth.Option = 'no' then
    begin
      CalcOneLine(o_vektor, Sink, trunc(dim_y.v), 1, trunc(dim_y.v), u_vektor,
        z_vektor);
    end
    else // set new outer boundary conditions
    begin
      testForContBorder(start_, ende_, x_ndx, i, true);
      CalcOneLine(o_vektor, Sink, trunc(dim_y.v), start_, ende_, u_vektor,
        z_vektor);
    end;
    for i := 1 to trunc(dim_y.v) do
      C_xy[x_ndx, i] := z_vektor[i];
  end;

  // write the influx of central sinks and concentration of the associated cell
  if self.writeSinkCellFile.Option = 'yes' then
  begin
    assignfile(SinkCellFile, SinkCellFileName);
    append(SinkCellFile);
    write(SinkCellFile, GlobMod.Time.v:6:2, ' ', int_dt.v:6:2, ' ',
      GlobMod.Time.v * 86400 + SumOfInternalTimeSteps, ' ');
    for i := 1 to RasterData.NRoots do
      if (TRootPosition(RasterData.PosList.Objects[i]).xi > trunc(dim_x.v / 10)) and
        (TRootPosition(RasterData.PosList.Objects[i]).xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (TRootPosition(RasterData.PosList.Objects[i]).yi > trunc(self.dim_y.v / 10)) and
        (TRootPosition(RasterData.PosList.Objects[i]).yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, TRootPosition(RasterData.PosList.Objects[i]).NInflux, ' ');
    for i := 1 to RasterData.NRoots do
      if (TRootPosition(RasterData.PosList.Objects[i]).xi > trunc(dim_x.v / 10)) and
        (TRootPosition(RasterData.PosList.Objects[i]).xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (TRootPosition(RasterData.PosList.Objects[i]).yi > trunc(self.dim_y.v / 10)) and
        (TRootPosition(RasterData.PosList.Objects[i]).yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, C_xy[TRootPosition(RasterData.PosList.Objects[i]).xi,
          TRootPosition(RasterData.PosList.Objects[i]).yi], ' ');
    writeln(SinkCellFile);
    closefile(SinkCellFile);
  end;
end;
(* ------------------------------------------------------------------------------
  End of central procedure
  ------------------------------------------------------------------------------ *)


procedure TSubmodRoot2DDiffNitrate.Get_Sink(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of sink terms (uptake and mineralization)
  [mol/s-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  i, j: word;
  NUptake, Nuptake2, Nuptake3, NUptakeGrid, NAmountRootdt,
  // nitrogen uptake rate for current root [dg/dt]
  SumUptake, x, Db: real;
  De_SinkGrid: double;
begin
  get_minGrid(x_loc, y_loc, s); // calculate mineralization
  NUptake := 0.0;
  SumUptake := 0.0;
  De_SinkGrid := De.v / theta.v;
  for i := 1 to trunc(Num_Roots.v) do
  begin
    // test whether a sink exists in the computational element, then calculate uptake
    if ((TRootPosition(RasterData.PosList.Objects[i]).xi = x_loc) and (TRootPosition(RasterData.PosList.Objects[i]).yi = y_loc))
    then
    begin
      x := sqrt(dx.v * dy.v / pi);
      // radius of a circle corresponding to the central cell
      Db := Dl.v * 3.35 * theta.v * theta.v * theta.v; //
      { Inner boundary condition: constant influx; this scenario can be controlled
        via parameter Ar; another influencing factor is the calculated wl_ha }
      If NitrateUptakeFunction.Option = lowercase('ConstInflux') then
        NUptake := Imax.v; // mol/cm*s
      // Innere Randbedingung: Zero sink
      If NitrateUptakeFunction.Option = lowercase('ZeroSink') then

        // Nuptake :=
        { The flux is calculated considering the absorbing part of the root
          surface. The concentration gradient extends from the center of the
          neighboring cell to the apex of the root surface, with the root located
          centrally in the cell. See hanging file material 2D model. Note on the
          denominator: first term is the concentration gradient, second term the
          edge or the partial absorbing root surface. }
        { De.V*C_xy[x_loc-1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc+1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc, y_loc-1]/dy.V*dx.V
          +De.V*C_xy[x_loc, y_loc+1]/dy.V*dx.V; }
        { Alternative calculation of uptake by the sink: gradient reduced by
          Rad_Wurzel.v, flux in each direction corresponds to a quarter of the
          root circumference (assuming a cylindrical root). }
        { De.V*C_xy[x_loc-1, y_loc]/(dx.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc+1, y_loc]/(dx.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc, y_loc-1]/(dy.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2)
          +De.V*C_xy[x_loc, y_loc+1]/(dy.V-Rad_Wurzel.V)*(Pi*Rad_Wurzel.V/2); }

        { NUptakeGrid:= De.V*C_xy[x_loc-1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc+1, y_loc]/dx.V*dy.V
          +De.V*C_xy[x_loc, y_loc-1]/dy.V*dx.V
          +De.V*C_xy[x_loc, y_loc+1]/dy.V*dx.V; }
        { Alternative calculation 2: inside the absorbing computation cell an
          uptake following the 1D approach was assumed, equating the area of the
          computational element with the area of the single root cylinder (see
          calculation of x above, then flux in the element is computed for radial
          coordinates). }
        // Nuptake :=     C_xy[x_loc, y_loc]*2*pi*Db/ln(x/(1.65*Rad_wurzel.v));
        { Alternative calculation 3 (cf. Kage, thesis Eq. 3.6.29, hanging file
          reformulation to In). It assumes that Cl_min corresponds to the
          concentration at the root surface and can become zero }
        NUptake := (C_xy[x_loc, y_loc] - clmin.v) * 2 * pi * Db /
          (-1 / 2 + (sqr(x) / (sqr(x) - sqr(RootRadius.v)) *
          ln(x / RootRadius.v)));

/// <summary>Alternative calculation 4 (after Moncayo, Eq. 19 and 20):</summary>
      { Nuptake :=
        De_SinkGrid*C_xy[x_loc-1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc+1, y_loc]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc-1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2)+
        De_SinkGrid*C_xy[x_loc, y_loc+1]/(ln(x/Rad_Wurzel.v)*x)*(Pi*Rad_Wurzel.V/2); }
/// <summary>Implementation with Cl_min</summary>
      { ZeroSink     : In_arr[pos] := De.v*(C_xy[x_loc-1, y_loc]-clmin.v)/
        dx.v*dy.v+De.v*(C_xy[x_loc+1, y_loc]-clmin.v)/dx.v*dy.v
        +De.v*(C_xy[x_loc, y_loc-1]-clmin.v)/dy.v*dx.v+De.v*
        (C_xy[x_loc,y_loc+1]-clmin.v)/dy.v*dx.v; }
      // Innere Randbedingung: Michaelis-Menten-Kinetik
      If NitrateUptakeFunction.Option = lowercase('MM') then
        // NUptake :=  Influx_f( Imax.v, Km.v, C_xy[x_loc, y_loc]);
        NUptake := influx_fVar(Imax.v, Km.v, C_xy[x_loc, y_loc], x, Db);
      // influx into the sink during the time step
      TRootPosition(RasterData.PosList.Objects[i]).NInflux := NUptake;
      If NitrateUptakeFunction.Option <> lowercase('ZeroSink') then
        SumUptake := SumUptake + NUptake
      else
        SumUptake := NUptake;
      // calculate cumulative N uptake for the sinks
/// <summary>Problem: there is still a conceptual error here</summary>
      NAmountRootdt := TRootPosition(RasterData.PosList.Objects[i]).NInflux * 14 / 1000 * int_dt.v;
      // NAmountRootdt:=TRootPosition(RasterData.PosList.Objects[i]).NInflux*14/1000*86400/int_dt.V;
      TRootPosition(RasterData.PosList.Objects[i]).NAmountdt := NAmountRootdt;
      TRootPosition(RasterData.PosList.Objects[i]).SumNAmount := TRootPosition(RasterData.PosList.Objects[i]).SumNAmount +
        NAmountRootdt;
    end;
  end;
/// <summary>Mineralization</summary>
  s := s - SumUptake;
end;

procedure TSubmodRoot2DDiffNitrate.get_minGrid(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of mineralization [mol/s-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  pos: word;
begin
  /// <summary>sink term from mineralization [mol/s]</summary>
  s := Min_S.v * vol_Element;
end;

procedure TSubmodRoot2DDiffNitrate.CalcRates;
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
begin
  /// <summary>nothing happens in the base model (no inherited call)</summary>
  inherited CalcRates;
  ConcFieldName := ConcFieldDataFile.Option;
  // Communication with the structural model and display of WAP in MathImNutrUptake
  // create new file with outputs for the sinks:
  for i := 0 to RasterData.Poslist.Count-1 do
  begin
    TRootPosition(RasterData.PosList.Objects[i]).SumNAmount := 0;
  end;
  if FileWasCreated = false then
  begin
    assignfile(UptakeFile, RootSinkOutpDataFile.Option);
    rewrite(UptakeFile);
    closefile(UptakeFile);
    FileWasCreated := true;
  end;
  if self.iniMethod.Option = 'submodstruct' then
  begin
    updateFromStructModell;
    // as long as no roots exist, no fluxes are calculated
    if Num_Roots.v < 1 then
      exit;
    fillChartRootDistr;
  end;
  { Since theta may change in the dynamic model, De must be recalculated each
    time step }
  De.v := Dl.v * 3.35 * sqr(theta.v) * theta.v;
  // De.v:=Dl.v*3.35*sqr(theta.v);
  TimeStepAdaption := false;
  SumOfInternalTimeSteps := 0.0;
  last_dt := 0.0;
  ActArFromConc.v := 0;
  ActAr.v := 0;
  repeat
    if int_dt.v < max_dt.v then
      int_dt.v := int_dt.v * 1.1; // increase time step
    If int_dt.v > globtime.C * 86400 then
      int_dt.v := globtime.C * 86400;
/// <summary>Has the end of the day been exceeded with the new time step?</summary>
    If SumOfInternalTimeSteps + int_dt.v > globtime.C * 86400 then
    begin
      last_dt := int_dt.v; // save old time step length
      int_dt.v := (globtime.C * 86400 - SumOfInternalTimeSteps);
      TimeStepAdaption := true;
    end;
    // calculate fluxes
    concBegin := avg_conz;
    zweid_solut(int_dt.v);
    SumOfInternalTimeSteps := SumOfInternalTimeSteps + int_dt.v;
    { In each time step the cumulative N uptakes of the individual, non-marginal
      sinks are summed. Return value is the total N amount the roots have taken
      up in a time step }
    sumNAmountRootsdt := calcAmountUptakeRoots;
    Sum_N_AmountRoots.v := Sum_N_AmountRoots.v + sumNAmountRootsdt;
    { At the end of each internal time step the absorbed influx is redistributed
      to the computational elements }
    { If a steady-state condition should be generated, the constant concentration
      is restored in every time step }
    ConcAfter := avg_conz;
    ActArFromConc.v := ActArFromConc.v + Mg_func(Depth.v, theta.v,
      concBegin - ConcAfter);
    { For the calculation of the current uptake rate only roots not in the
      margins are considered }
    ActAr.v := ActAr.v + calcActArdt;
    if SteadyState.Option = 'yes' then
      createSteadyState(concBegin - ConcAfter);
    // write the concentration field in the last internal time step
    if SumOfInternalTimeSteps >= self.globtime.C * 86400 then
    begin
      if self.writeSinkCellFile.Option = 'yes' then
      begin
        assignfile(ConcField, ConcFieldName);
        rewrite(ConcField);
        // new file; only the final concField is written
        // header
        for i := 0 to trunc(dim_x.v + 1) do
        begin
          for j := 0 to trunc(dim_y.v + 1) do
          begin
            write(ConcField, C_xy[i, j], ' ');
          end;
          writeln(ConcField);
        end;
        closefile(ConcField);
      end;
    end;
  until SumOfInternalTimeSteps >= self.globtime.C * 86400;
  // if an adaptation of the time step length is intended
  If TimeStepAdaption then
    int_dt.v := last_dt; // restore old time step length
  If int_dt.v <= 0.0 then
    showMessage('time step error');
  // output of concentration change
  showActConc;
  // write valid root data to a file
  if (OutputXY.Option = 'yes') then
  begin
    writeOutputToFile;
  end;
  if (OutputSink.Option = 'yes') then
  begin
    writeNitrateUptakeSinkToFile;
  end;
end; // End TSubmodRootDiff.CalcRates



procedure TSubmodRoot2DDiffNitrate.InitConc;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Berechnung der Startkonz. aus der initialen N-Menge
  ------------------------------------------------------------------------------ *)
var
  x_ndx, y_ndx: integer;
  NAmountGridzell: double;
begin
  { Berechnen der N-Menge in einer Gridzelle von kg/ha auf g/dim_x*dim_y, die 1000
    im Nenner stammen von der Umrechnung von kg auf g }

  // NAmountGridzell:=N_AmountSoil.V*1000/(dim_x.v*dim_y.v*10000*vol_Element);  //g N/cm3
  // NAmountGridzell/(theta.v*14*Tiefe.V);   //mol/cm^3
  c_start.v := Cl_func(Depth.v, theta.v, N_amountsoil.v);
  // c_start.v := NAmountGridzell/(theta.v*Tiefe.v*1e8*14)*1000; //alte Implement.
  For x_ndx := 0 to trunc(dim_x.v + 1) do
  begin
    for y_ndx := 0 to trunc(dim_y.v + 1) do
    begin
      // c_xy[x_ndx, y_ndx] := c_start.v*(1+x_ndx/1)*(1+y_ndx/1);
      C_xy[x_ndx, y_ndx] := c_start.v;
    end;
  end;
end;


procedure TSubmodRoot2DDiffNitrate.createSteadyState(DiffSteadyState: double);
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Erzeugt einen Steady-State-Zustand nach folgendem Verfahren
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
begin
  { die gesamte aufgenommene Menge wird gleichmäßig auf alle Rechenelemente verteilt: }
  for i := 0 to trunc(dim_x.v + 1) do
    for j := 0 to trunc(dim_y.v + 1) do
    begin
      C_xy[i, j] := C_xy[i, j] + DiffSteadyState;
    end;
end;



function TSubmodRoot2DDiffNitrate.avg_conz: double;
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
    for i := 1 to trunc(dim_x.v) - 1 do
      for j := 1 to trunc(dim_y.v) - 1 do
      begin
        // Aufsummerieren der Konzentrationen sämtlicher Rechenelemente:
        conc := conc + C_xy[i, j];
        If C_xy[i, j] > max_c then
          max_c := C_xy[i, j];
        If C_xy[i, j] < min_c then
          min_c := C_xy[i, j];
      end;
    { Mitteln: Teilen durch die Summe der Elemente }
    conc := conc / (dim_x.v * dim_y.v);
  end
  else // wenn die Ränder nicht berücksichtigt werden sollen.
  begin
    numb1stElemX := trunc((dim_x.v - dim_xMiddle.v) / 2);
    numbLastElemX := trunc(dim_x.v - (dim_x.v - dim_xMiddle.v) / 2);
    numb1stElemY := trunc((dim_y.v - dim_yMiddle.v) / 2);
    numbLastElemY := trunc(dim_y.v - (dim_y.v - dim_yMiddle.v) / 2);
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


function TSubmodRoot2DDiffNitrate.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: alternative Berechnung des Influx mit Michaelis-Menten-Randbedingung
  unter der Voraussetzung, dass im Einzelwurzelzylinder mit dem quasistationären
  Ansatz gearbeitet wird.
  entspricht dem 2D-S Ansatz (erweitert um Michaelis-Menten-Kinetik). Berechnung
  vor allem der Formel für cla muss noch einmal kontrolliert werden.
  ------------------------------------------------------------------------------ *)
var
  cla, // Konzentration an der Wurzeloberfläche
  influx, // Nährstoffinfluxrate [mol cm^-1 s^-1]
  numerator // Zähler in Gleichung 3.6.33, Diss. Kage
    : double;
begin
  numerator := Km + (sqr(x) * Imax / ((sqr(x) - sqr(RootRadius.v)) * 2 * pi *
    Db)) * ln(x / RootRadius.v) - Imax / (4 * pi * Db);
  cla := clmin.v + (-ClAv + numerator) / 2;
  cla := cla + sqrt(sqr(ClAv + numerator) / 4 + ClAv * Km);
  influx := Imax * (cla - clmin.v) / (Km + (cla - clmin.v));
  If (influx <= 0.0) or (ClAv <= 0.0) // Keine negativen Flüsse
  then
    influx := 0.0;
  Result := influx;
end;

function TSubmodRoot2DDiffNitrate.calcAmountUptakeRoots: double;
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
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootPosition(RasterData.PosList.Objects[i]).x >= verticMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootPosition(RasterData.PosList.Objects[i]).y >= horizMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      NAmountRoot := NAmountRoot + convertConcToAmount(i);
    end;
  end;
  { Teilen durch areaMiddle -> Aufnahme bezogen auf Quadratcentimenter, Multiplika-
    tion mit 10^8 -> Aufnahmemenge bezogen auf bestimmte Tiefe und ha. }
  Result := NAmountRoot / AreaMiddle.v * 1E8; // 10 hoch 8 cm^2 pro ha
  { Warum geht das nicht:
    Sum_N_AmountRoots.V:=Sum_N_AmountRoots.V+Ar.v; }
end;

function TSubmodRoot2DDiffNitrate.convertConcToAmount(i: integer): double;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Rechnet die Aufnahme [mol/cm*s] in Menge [kg/d], für übergebene
  Wurzeln.
  ------------------------------------------------------------------------------ *)
const
  kg_mol = 14 / 1000;
var
  ha: integer;
  NAmountRoot: double;
begin
  { NINflux in [mol/cm/s }
  NAmountRoot := TRootPosition(RasterData.PosList.Objects[i]).NInflux * kg_mol * Depth.v * int_dt.v;
  Result := NAmountRoot;
end;

function TSubmodRoot2DDiffNitrate.calcActArdt: double;
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
  rootCounter := 0;
  AvNMenge := 0;
  AVInflux := 0;
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootPosition(RasterData.PosList.Objects[i]).x >= verticMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootPosition(RasterData.PosList.Objects[i]).y >= horizMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      AVInflux := AVInflux + TRootPosition(RasterData.PosList.Objects[i]).NInflux;
      AvNMenge := AvNMenge + TRootPosition(RasterData.PosList.Objects[i]).SumNAmount;
      inc(rootCounter);
    end;
  end;
  if number_consid_roots.v <> 0 then
  begin
    AVInflux := AVInflux / number_consid_roots.v;
    // Berücksichtigt nur den Influx aus dem letzten internen Zeitschritt:
    Result := AVInflux * 14 / 1000 * wl_ha.v * int_dt.v;
    // Result:= AvInflux*14/1000*wl_ha.v
    // AvNMenge:=AvNMenge/rootCounter;
    // ActAr.v := AvNMenge*wl_ha.v;
  end;
end;


procedure TSubmodRoot2DDiffNitrate.writeNitrateUptakeSinkToFile;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Schreibt eine Datei mit der N-Aufnahme aller Senken (und wg. Zu-
  ordnung auch mit lf. Nr. und Koord.
  ------------------------------------------------------------------------------ *)
var
  UptakeFile: Textfile;
  i, j: integer;
  { Nur Senken, die nicht im Rand und im Beobachtungsfenster liegen werden ausgege-
    ben }
  PosArr_middle: Array of TRootPosition;

begin
  { Wenn Datei noch nicht vorhanden, neu anlegen }
  if not FileExists(RootSinkOutpDataFile.Option) then
  begin
    assignfile(UptakeFile, RootSinkOutpDataFile.Option);
    rewrite(UptakeFile);
    closefile(UptakeFile);
  end;
  SetLength(PosArr_middle, trunc(number_consid_roots.v));
  j := 0;
  for i := 1 to trunc(RasterData.NRoots) do
  begin
    // Punkt nicht in den vertikalen Rändern
    if (TRootPosition(RasterData.PosList.Objects[i]).x >= verticMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootPosition(RasterData.PosList.Objects[i]).y >= horizMargin.v) and
      (TRootPosition(RasterData.PosList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      PosArr_middle[j].x := TRootPosition(RasterData.PosList.Objects[i]).x;
      PosArr_middle[j].y := TRootPosition(RasterData.PosList.Objects[i]).y;
      PosArr_middle[j].xi := TRootPosition(RasterData.PosList.Objects[i]).xi;
      PosArr_middle[j].yi := TRootPosition(RasterData.PosList.Objects[i]).yi;
      PosArr_middle[j].NInflux := TRootPosition(RasterData.PosList.Objects[i]).NInflux;
      PosArr_middle[j].WInflux := TRootPosition(RasterData.PosList.Objects[i]).WInflux;
      PosArr_middle[j].root := TRootPosition(RasterData.PosList.Objects[i]).root;
      PosArr_middle[j].area := TRootPosition(RasterData.PosList.Objects[i]).area;
      inc(j);
    end;
  end;
  assignfile(UptakeFile, RootSinkOutpDataFile.Option);
  append(UptakeFile);
  write(UptakeFile, 'Modellzeit: ', GlobMod.Time.v:6:2, ' ');
  writeln(UptakeFile);
  // Header schreiben
  write(UptakeFile, 'Lfd.Nr.', ' ', 'X', ' ', 'Y', ' ', ' ', 'Flaeche', ' ',
    'N-Aufnahme', ' ');
  writeln(UptakeFile);
  for i := 0 to high(PosArr_middle) do
  begin
    write(UptakeFile, PosArr_middle[i].root, ' ');
    write(UptakeFile, PosArr_middle[i].x, ' ');
    write(UptakeFile, PosArr_middle[i].y, ' ');
    write(UptakeFile, PosArr_middle[i].area, ' ');
    write(UptakeFile, PosArr_middle[i].NInflux, ' ');
    writeln(UptakeFile);
  end;
  closefile(UptakeFile);
end;


procedure TSubmodRoot2DDiffNitrate.Integrate;
(* ------------------------------------------------------------------------------
  ZUGEHÖRIGE KLASSE:  TSubmodRootDiff
  BESCHREIBUNG: Methode wurde überschrieben, um die Zeitschrittweite sukzessive
  zu verändern.
  ------------------------------------------------------------------------------ *)
var
  sumNAmountRoots, n_me_alt: real;
  // Zwischenspeicher für die ursprüngliche N-Menge
begin
  // solange keine Wurzeln vorhanden, werden auch keine Flüsse berechnet.
  if Num_Roots.v < 1 then
    exit;
  inherited Integrate;
  // in der Basisklasse geschieht nichts auch kein inherited
  n_me_alt := N_amountsoil.v;
  c_av.v := avg_conz; // Durchschnittskonz.
  N_amountsoil.v := Mg_func(Depth.v, theta.v, c_av.v);
end; // End TSubmodRootDiff2D.Integrate



procedure TSubmodRoot2DDiffNitrate.showActConc;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Zeigt die aktuelle Konzentration im TMathImage an
  ------------------------------------------------------------------------------ *)

const
  levelsarray: array [0 .. 11] of MathFloat = (-4, -2.5, -2, -1.5, -1, -0.5, 0,
    0.5, 1, 1.5, 2, 2.5);


var
  i, j, k: integer;
  thiscolor: TColor;
begin
  If ((MyMathImage <> nil) and (ShowConc.Option = 'true')) then
  begin
    MyMathImage.Clear;
    // If max_c > MyMathImage.d3WorldZW then
    // MyMathImage.d3WorldZW := 1.2*max_c;

    for i := 0 to high(levelsarray) - 1 do
    begin
      levelsarray[i] := (max_c - min_c) / high(levelsarray) * (i + 1);
    end;
    for i := 1 to trunc(dim_x.v) do
    begin
      for j := 1 to trunc(dim_y.v) do
      begin
        thiscolor := clSilver;
        for k := 0 to High(levelsarray) - 1 do
          if levelsarray[k] <= C_xy[i, j] then
            if levelsarray[k + 1] >= C_xy[i, j] then
            begin
              thiscolor := colorarray[k];
              break;
            end;
        if C_xy[i, j] < levelsarray[0] then
          thiscolor := colorarray[0];
        if C_xy[i, j] > levelsarray[High(levelsarray)] then
          thiscolor := colorarray[High(levelsarray)];
        ColorSurface.Make(i - 1, j - 1, x_arr[i], y_arr[j], C_xy[i, j],
          thiscolor);
      end;
    end;
    MyMathImage.d3drawfullworldbox;
    MyMathImage.d3DrawAxes('x', 'y', 'z', 10, 10, 10, 0, 0, 0, true);
    MyMathImage.Pen.Color := clblue;
    MyMathImage.d3DrawSurface(ColorSurface, true, true);
    MyMathImage.RePaint;
  end;
end;



procedure Register;
(* -----------------------------------------------------------------------------
Prozedur wird für Komponenten benötigt: Registrierung der Komponenten auf einer
Palette.
------------------------------------------------------------------------------*)
begin
  RegisterComponents('Soil2D', [TSubmodRoot2DDiffNitrate]);
end;//End Register



end.
