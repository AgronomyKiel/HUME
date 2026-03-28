unit USubmodRoot2DDiffNitrate;

 {$J+}
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series, AdvGrid, U2DSoilBaseClassNitrate,
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

//    C_xy: array of array of double;

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
    for i := 0 to trunc(dim_x.v)-1 do
    begin
      for j := 0 to trunc(dim_y.v)-1 do
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
        ColorSurface.Make(i - 1, j - 1, RasterData.x_arr[i], RasterData.y_arr[j], RasterData.C_xy[i, j],
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
