unit USubmodRoot2DDiffNitrate;

 {$J+}
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid, U2DSoilBaseClassNitrate,
  UMod, UState, Diffko, SubmodRootStructureNew, URootObject, URootUptakeFunctions,
  U2DSoilBaseClasses, MathImge;

type
  /// <summary>Type declarations</summary>
  /// <summary>Records and sets</summary>


  /// <summary> Declaration of class TSubmodRootDiff. Class based on base class for derived diffusion models
  /// implements further details for nitrate transport
  /// </summary>
  TSubmodRoot2DNitrate = class(TSubmodRootBase2D)
  private
    /// <summary>
    ///   diffusive nitrate uptake rate
    /// </summary>
    Diffuptake: double;

    /// <summary>
    ///   Two dimensional solution of nitrate transport
    /// </summary>
    procedure zweid_solut(dt_globmod: real);
    
    // Helper methods
    procedure InitConc;
    procedure createSteadyState(DiffSteadyState: double);
    function avg_conz: double;

    function calcAmountUptakeRoots: double;
    function calcActArdt: double;
    function convertConcToAmount(i: integer): double;

  protected

/// <summary> C_xy: array for concentrations in the computational elements.
/// c_xy was declared as a dynamic array (see NG, p.65 ff) because the size of
///      the array should be declared with values of dim_x and dim_y (number of
///      computational elements in the x and y directions) that are assigned later.
/// </summary>

    C_xy: array of array of double;

    /// <summary>Protected declarations, also accessible by derived classes</summary>
    ///


    /// <remarks>Margins are necessary so that edge effects can be excluded when the root exit points are hexagonally distributed</remarks>


   ActArFromConc : TVar;

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
    /// <summary>
    ///   maximum nitrate concentration in grid [mol/cm3]
    /// </summary>
    max_c : real;

    /// <summary>Public declarations</summary>
    /// <summary>Flag for one-time write access</summary>
    procedure createAll; override;
    // procedure Init(var GlobModReferenz: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure Init(var GlobMod: TMod); override;
    procedure Get_Sink(x_loc, y_loc: word; var s: real);
    procedure get_minGrid(x_loc, y_loc: word; var s: real);
    // Helper method
    /// <summary>current concentrations can be output via a form</summary>
    procedure showActConc;
    function influx_fVar(Imax, Km, ClAv, x, Db: double): double;


    procedure writeNitrateUptakeSinkToFile;


  published
    /// <summary>Published declarations</summary>
    property MyMathImage: TMathImage read fMyMathImage write fMyMathImage;

  end; { Ende Deklaration TSubmodRootDiff }

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
procedure TSubmodRoot2DNitrate.createAll;
begin
  inherited createAll;
  // Create and initialize TVar
  { Caveat: variables are always initialized to 0. If a start value other than 0 is
    needed, calculation and assignment must occur in init. It would be better not to
    declare such variables as TVar. }



  OptCreate('ContGrowth', 'no', ContGrowth, 'Switch for continuous growth of the root system');
  ContGrowth.OptionList.add('yes');
  ContGrowth.OptionList.add('no');

  OptCreate('ShowConc', 'True', ShowConc, 'Switch for showing concentration');
  ShowConc.OptionList.add('true');
  ShowConc.OptionList.add('false');

  OptCreate('CalcModeSteadyState', 'withoutMargin', CalcModeSteadyState, 'Calculation mode for steady state');
  CalcModeSteadyState.OptionList.add('withMargin');
  CalcModeSteadyState.OptionList.add('withoutMargin');

  OptCreate('SteadyState', 'no', SteadyState, 'Switch for steady state');
  SteadyState.OptionList.add('yes');
  SteadyState.OptionList.add('no');

  OptCreate('RootDistribution', 'Random', RootDistribution, 'Root distribution method');
  RootDistribution.OptionList.add('Random');
  RootDistribution.OptionList.add('Regular');
  RootDistribution.OptionList.add('FromSource');

  OptCreate('DelMarginRoots', 'no', DelMarginRoots, 'Delete margin roots');
  DelMarginRoots.OptionList.add('yes');
  DelMarginRoots.OptionList.add('no');

  OptCreate('writeConcField', 'no', writeConcField, 'Switch for writing concentration field');
  writeConcField.OptionList.add('no');
  writeConcField.OptionList.add('yes');

  OptCreate('writeSinkCellFile', 'no', writeSinkCellFile, 'Switch for writing sink cell file');
  writeSinkCellFile.OptionList.add('no');
  writeSinkCellFile.OptionList.add('yes');

  OptCreate('OutputSink', 'no', OutputSink, 'Switch for outputting sink');
  OutputSink.OptionList.add('no');
  OutputSink.OptionList.add('yes');

  OptCreate('ConcFieldDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv', ConcFieldDataFile, 'Concentration field data file name');
  ConcFieldDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\concField.csv');

  OptCreate('SinkCellFileFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv', SinkCellFileFile, 'Sink cell file name');
  SinkCellFileFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\SinkFile.csv');

  OptCreate('RootSinkOutpDataFile',
    'Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat', RootSinkOutpDataFile, 'Root sink output data file name');
  RootSinkOutpDataFile.OptionList.add
    ('Q:\Kohl\DiffModell\IniFilesAusgaben\in.dat');

  OptCreate('OutputXY', 'no', OutputXY, 'Switch for outputting XY data');
  OutputXY.OptionList.add('no');
  OutputXY.OptionList.add('yes');
  { Paths for model comparison 1D vs 2D }
  { Paths to input and output files are identical for both submodels. Running both
    submodels simultaneously in one model run only makes sense for comparison. }

end; // End TSubmodRootDiff.CreateAll


procedure TSubmodRoot2DNitrate.zweid_solut(dt_globmod: real);
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
  SinkCellFileName: string;
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
        write(SinkCellFile, 'SimZeit', ' ', 'dt_akt[d]', ' ', 'sumDtInt[d]',
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
    for i := 1 to RasterData.NRoots do begin
      ARoot := TRootObjectIn2D(RasterData.RootList.Objects[i]);
      if (ARoot.xi > trunc(dim_x.v / 10)) and
        (ARoot.xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (ARoot.yi > trunc(self.dim_y.v / 10)) and
        (ARoot.yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, ARoot.NInflux, ' ');
    end;
    for i := 1 to RasterData.NRoots do begin
      ARoot := TRootObjectIn2D(RasterData.RootList.Objects[i]); 
      if (ARoot.xi > trunc(dim_x.v / 10)) and
        (ARoot.xi < self.dim_x.v - trunc(self.dim_x.v / 10)) and
        (ARoot.yi > trunc(self.dim_y.v / 10)) and
        (ARoot.yi < self.dim_y.v - trunc(self.dim_y.v / 10)) then
        write(SinkCellFile, C_xy[ARoot.xi, ARoot.yi], ' ');
          TRootObjectIn2D(RasterData.RootList.Objects[i]).yi], ' ');
    writeln(SinkCellFile);
    closefile(SinkCellFile);
    end;
  end;
end;
(* ------------------------------------------------------------------------------
  End of central procedure
  ------------------------------------------------------------------------------ *)


procedure TSubmodRoot2DNitrate.Get_Sink(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of sink terms (uptake and mineralization)
  [mol/d-1] in a computational element
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
  for i := 0 to trunc(Num_Roots.v)-1 do
  begin
    // test whether a sink exists in the computational element, then calculate uptake
    if ((TRootObjectIn2D(RasterData.RootList.Objects[i]).xi = x_loc) and (TRootObjectIn2D(RasterData.RootList.Objects[i]).yi = y_loc))
    then
    begin
      // radius of a circle corresponding to the central cell
      x := sqrt(dx.v * dy.v / pi);

      Db := Dl.v * 3.35 * theta.v * theta.v * theta.v; //
      { Inner boundary condition: constant influx; this scenario can be controlled
        via parameter Ar; another influencing factor is the calculated wl_ha }
      If NitrateUptakeFunction.Option = lowercase('ConstInflux') then
        NUptake := Imax.v; // mol/cm*d

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

      TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux := NUptake;
      If NitrateUptakeFunction.Option <> lowercase('ZeroSink') then
        SumUptake := SumUptake + NUptake
      else
        SumUptake := NUptake;
      // calculate cumulative N uptake for the sinks
/// <summary>Problem: there is still a conceptual error here</summary>
      NAmountRootdt := TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux * 14 / 1000 * int_dt.v;
      // NAmountRootdt:=TRootObjectIn2D(RasterData.PosList.Objects[i]).NInflux*14/1000*86400/int_dt.V;
      TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmountdt := NAmountRootdt;
      TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount := TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount +
        NAmountRootdt;
    end;
  end;
/// <summary>Mineralization</summary>
  s := s - SumUptake;
end;

procedure TSubmodRoot2DNitrate.get_minGrid(x_loc, y_loc: word; var s: real);
(* ------------------------------------------------------------------------------
  DESCRIPTION: calculation of mineralization [mol/d-1] in a computational element
  Problem: Do the units match?
  ------------------------------------------------------------------------------ *)
var
  pos: word;
begin
  /// <summary>sink term from mineralization [mol/d]</summary>
  s := Min_S.v * vol_Element;
end;

procedure TSubmodRoot2DNitrate.CalcRates;
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
  for i := 0 to RasterData.RootList.Count-1 do
  begin
    TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount := 0;
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
//    updateFromStructModell;
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
    SumNUptake.v := SumNUptake.v + sumNAmountRootsdt;
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



procedure TSubmodRoot2DNitrate.InitConc;
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
  c_start.v := Cl_func(Depth.v, theta.v, NAmount.v);
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


procedure TSubmodRoot2DNitrate.Init(var GlobMod: TMod);

var
  DimXMiddle, // Dimension der mittigen Fläche in x-Richtung [cm]
  DimYMiddle // Dimension der mittigen Fläche in y-Richtung [cm]
    : double;
  i: integer;

begin
  inherited;

  ContPosx := 50;
  ContPosy := 50;
  SinkCellFileWasCreated := false;
  FileWasCreated := false;
  hasWritten := false;
  // Listen leeren
  self.RasterData.RootList.clear;
  { Keine dynamische Verbindung zwischen 2D-Diffmodell und Strukturmodell in den
    Verteilungsvarianten regular oder random }
  if (iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option <> 'fromsource') then
  begin
    RootDistribution.Option := 'fromsource';
    // showMessage('Strukturmodell setzt Einstellung lognormal voraus.Wurde umgestellt.');
  end;
  inherited;
  { AddDataValueToDataSeries ersetzt nun die Methode init. Ursprünglich wurde Init
    der übergeordneten Klasse wird mit dem übergebenen Globalmodell aufgerufen. }
  // inherited init(GlobModReferenz);
  (* -----------------------------------------------------------------------------
    c_xy: Festlegen der Arraygröße mit SetLength. Es wird ein mehrdimensionales
    Array deklariert. Cave: Dynamische Arrays beginnen immer bei 0.
    ------------------------------------------------------------------------------ *)
  // Rechenelementebezogene Operationen
  SetLength(C_xy, trunc(dim_x.v + 2), trunc(dim_y.v + 2));
  SetLength(x_arr, trunc(dim_x.v) + 2);
  SetLength(y_arr, trunc(dim_y.v) + 2);
  dx.v := DimensionX.v / dim_x.v;
  dy.v := DimensionY.v / dim_y.v;
  DimXMiddle := DimensionX.v - 2 * verticMargin.v;
  DimYMiddle := DimensionY.v - 2 * horizMargin.v;
  // Berechnung der Anzahl der mittigen Rechenelemente
  dim_xMiddle.v := DimXMiddle / dx.v;
  dim_yMiddle.v := DimYMiddle / dy.v;
  AreaMiddle.v := DimXMiddle * DimYMiddle;
  x_arr[0] := dx.v / 2;
  for i := 1 to trunc(dim_x.v) + 1 do
    x_arr[i] := x_arr[i - 1] + dx.v;
  y_arr[0] := dy.v / 2;
  for i := 1 to trunc(dim_y.v) + 1 do
    y_arr[i] := y_arr[i - 1] + dy.v;

  vol_Element := dx.v * dy.v; { Volumen eines Rechenelements [cm3] }
  wm := theta.v * vol_Element; { Wassermenge eines Rechenelements
    [cm3*cm3 }
  { Berechnung der initial in den Rechenelementen enthaltenen Konzentration aus
    der initialen N-Menge im Boden. Zu diesem Zeitpunkt haben sämtliche Rechenelemente, egal
    ob in der Mitte oder in den Rändern die gleichen Konz. Berechnung o.k. }
  InitConc;
  NAmount.v := Mg_func(Depth.v, theta.v, c_start.v); // Debuggen
  c_av.v := avg_conz;
  // N_AmountSoil.v := mg_func(Tiefe.v, Theta.v, c_av.v);//Debuggen
  int_dt.v := ini_dt.v; // Zuweisung der Startzeitschrittweite ...

  Area.v := DimensionX.v * DimensionY.v;
  { Fläche der zu untersuchenden Schicht
    mit Rändern. }
  volume.v := Area.v * Depth.v;
  { Volumen der betrachteten Bodenschicht[cm3] }
  { Berechnung Mineralisationsrate in [Mol/cm^3*d] }
  Min_S.v := NMinerRate_kgNha.v / 14 * 1000 / 86400 * 1 / (Depth.v * 1E8);
  // Initialisieren der Visuallisierung der Nährstoffaufnahme


    { Ausschluss der Ränder; sollte nicht durchgeführt werden, da die Wurzeln zwar
    vorhanden sein und auch Aufnahme durchführen sollten, aber nicht berücksichtigt
    werden sollten }
  if DelMarginRoots.Option = 'yes' then
    removeMarginRoots;
  calcNumberConsRoots;


  If ((MyMathImage <> nil) and (ShowConc.Option = 'true')) then
  begin
    MyMathImage.d3WorldX1 := x_arr[1];
    MyMathImage.d3WorldXW := x_arr[trunc(dim_x.v)];
    MyMathImage.d3WorldY1 := y_arr[1];
    MyMathImage.d3WorldYW := y_arr[trunc(dim_y.v)];
    MyMathImage.d3Worldz1 := 0; // min_c;
    MyMathImage.d3WorldzW := max_c * 1.2;

    If ColorSurface = nil then
      ColorSurface := TColorSurface.Create(trunc(dim_x.v) - 1,
        trunc(dim_y.v) - 1)
    else
    begin
      ColorSurface.Free;
      ColorSurface := TColorSurface.Create(trunc(dim_x.v) - 1,
        trunc(dim_y.v) - 1)
    end;
    MyMathImage.d3DrawAxes('x', 'y', 'z', 5, 5, 5, 0, 0, 0, true);
    MyMathImage.d3drawfullworldbox;
  end;

  If wl_ha.v > 0.0 then
  begin
    { Berechnung scheint korrekt s. Manuskript Hängeregister Vgl 1D2D }
    Imax.v := NUptakeratepot.v / 14 * 1000 / wl_ha.v;
    { Berechnung Influxrate [mol/(cm/d)] }
    // Imax.V := Ar.v*1000/(14*86400*WL_ha.v);  //Debuggen
  end
  else
    Imax.v := 0.0;
  // Ausgabe von XY-Koord. bei statischem Modell
  if iniMethod.Option <> 'submodstruct' then
    fillChartRootDistr;
  showActConc;



  InitConc;

end;


procedure TSubmodRoot2DNitrate.createSteadyState(DiffSteadyState: double);
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



function TSubmodRoot2DNitrate.avg_conz: double;
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


function TSubmodRoot2DNitrate.influx_fVar(Imax, Km, ClAv, x, Db: double): double;
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

function TSubmodRoot2DNitrate.calcAmountUptakeRoots: double;
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
    if (TRootObjectIn2D(RasterData.RootList.Objects[i]).x >= verticMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(RasterData.RootList.Objects[i]).y >= horizMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
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

function TSubmodRoot2DNitrate.convertConcToAmount(i: integer): double;
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
  NAmountRoot := TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux * kg_mol * Depth.v * int_dt.v;
  Result := NAmountRoot;
end;

function TSubmodRoot2DNitrate.calcActArdt: double;
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
    if (TRootObjectIn2D(RasterData.RootList.Objects[i]).x >= verticMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(RasterData.RootList.Objects[i]).y >= horizMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      AVInflux := AVInflux + TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux;
      AvNMenge := AvNMenge + TRootObjectIn2D(RasterData.RootList.Objects[i]).NAmount;
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


procedure TSubmodRoot2DNitrate.writeNitrateUptakeSinkToFile;
(* ------------------------------------------------------------------------------
  BESCHREIBUNG: Schreibt eine Datei mit der N-Aufnahme aller Senken (und wg. Zu-
  ordnung auch mit lf. Nr. und Koord.
  ------------------------------------------------------------------------------ *)
var
  UptakeFile: Textfile;
  i, j: integer;
  { Nur Senken, die nicht im Rand und im Beobachtungsfenster liegen werden ausgege-
    ben }
  PosArr_middle: Array of TRootObjectIn2D;

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
    if (TRootObjectIn2D(RasterData.RootList.Objects[i]).x >= verticMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).x <= DimensionX.v - verticMargin.v)
    // Punkt nicht in den horizontalen Rändern
      and (TRootObjectIn2D(RasterData.RootList.Objects[i]).y >= horizMargin.v) and
      (TRootObjectIn2D(RasterData.RootList.Objects[i]).y <= DimensionY.v - horizMargin.v) then
    begin
      PosArr_middle[j].x := TRootObjectIn2D(RasterData.RootList.Objects[i]).x;
      PosArr_middle[j].y := TRootObjectIn2D(RasterData.RootList.Objects[i]).y;
      PosArr_middle[j].xi := TRootObjectIn2D(RasterData.RootList.Objects[i]).xi;
      PosArr_middle[j].yi := TRootObjectIn2D(RasterData.RootList.Objects[i]).yi;
      PosArr_middle[j].NInflux := TRootObjectIn2D(RasterData.RootList.Objects[i]).NInflux;
      PosArr_middle[j].WInflux := TRootObjectIn2D(RasterData.RootList.Objects[i]).WInflux;
      PosArr_middle[j].nroot := TRootObjectIn2D(RasterData.RootList.Objects[i]).nroot;
      PosArr_middle[j].area := TRootObjectIn2D(RasterData.RootList.Objects[i]).area;
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
    write(UptakeFile, PosArr_middle[i].nroot, ' ');
    write(UptakeFile, PosArr_middle[i].x, ' ');
    write(UptakeFile, PosArr_middle[i].y, ' ');
    write(UptakeFile, PosArr_middle[i].area, ' ');
    write(UptakeFile, PosArr_middle[i].NInflux, ' ');
    writeln(UptakeFile);
  end;
  closefile(UptakeFile);
end;


procedure TSubmodRoot2DNitrate.Integrate;
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
  n_me_alt := NAmount.v;
  c_av.v := avg_conz; // Durchschnittskonz.
  NAmount.v := Mg_func(Depth.v, theta.v, c_av.v);
end; // End TSubmodRootDiff2D.Integrate



procedure TSubmodRoot2DNitrate.showActConc;
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
  RegisterComponents('Soil2D', [TSubmodRoot2DNitrate]);
end;//End Register



end.
