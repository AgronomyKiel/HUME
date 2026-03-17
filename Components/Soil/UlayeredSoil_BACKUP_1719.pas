unit UlayeredSoil; // Nur Vorläufer für TSoilwatermod, nicht installieren
﻿// Nur Vorläufer für TSoilwatermod, nicht installieren
unit UlayeredSoil;

interface

uses
  UMod, UState, classes, UAbstractPlant;

type
  real = double;
  /// basic array type for soil layer states
  TSoilStateArray = array [0 .. max_comp + 1] of TState;
  /// basic array type for soil layer variables
  TSoilVarArray = array [0 .. max_comp + 2] of TVar;
  /// basic array type for soil layer external variables
  TSoilExtArray = array [0 .. max_comp + 1] of TExternV;
  /// basic array type for soil layer variables
  TSoilArray = array [0 .. max_comp + 1] of real;
  /// type for pedotransfer function version, RR= Rote Reihe, KA= addendum to KA5
  TTexture_version = (RR, KA);

  

  TLayeredSoil = class(TPlantRelatedSubMod)

  private
    private

  protected
    protected

    procedure LayerInit(max_Tiefe, potenz_f: real; n_comp: byte); virtual;
      /// <summary>Initializes geometrically distributed soil layers.</summary>
      /// <param name="max_Tiefe">Maximum depth of the soil profile.</param>
      /// <param name="potenz_f">Exponent shaping the geometric distribution.</param>
      /// <param name="n_comp">Number of compartments to create.</param>
      procedure LayerInit(max_Tiefe, potenz_f: real; n_comp: byte); virtual;

  public
    n_comp: Integer;
    /// Zahl der berechneten Schichten [n]}
    MaxProfileDepth: TPar;
    /// Tiefe bis zu der berechnet wird [cm]}
    Power_f: TPar;
    /// power factor for uneven layer thickness
    dz: real;
    /// thickness of layer}
    Dist: TSoilArray;
    /// Vektor der Abstaende der Kompartimentmittelpunkte [cm] }
    Thick: TSoilArray;
    /// Vektor der Kompartimentdicken [cm] }
    Depth: TSoilVarArray;
    /// Abstand der unteren Kompartimentgrenze von der Bodenoberfläche in [cm] }
    upper_w_f: TSoilArray;
    /// Wichtungsfaktoren zur Errechnung der mittleren Leitfähigkeit zwischen 2 Kompartimenten }
    lower_w_f: TSoilArray;
    /// dito
    Texture_versionOption: TOption;
    /// Version of pedotransfer function to be used

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcRates; override;

  published
    property parMaxTiefe: TPar read MaxProfileDepth write MaxProfileDepth;
    property p_NComp: Integer read n_comp write n_comp;
  end;

function trdiag(rep: boolean; { Wiederholungsflagge }
  max_n, min_n: Integer; { Dimension der Matrix }
  var lower, { Subdiagonale }
  diag, { Diagonale }
  upper, { Superdiagonale }
  b: TSoilArray { Rechte Seite des Systems }
  ): byte; { Fehlerparameter }
{ Wiederholungsflagge }
function trdiag(rep: boolean;
  { Dimension der Matrix }
  max_n, min_n: Integer;
  { Subdiagonale }
  var lower,
  { Diagonale }
  diag,
  { Superdiagonale }
  upper,
  { Rechte Seite des Systems }
  b: TSoilArray
  { Fehlerparameter }
  ): byte;

function ndx_str(i: Integer): string;
procedure Register;

implementation

uses
  math,
{$IFNDEF NONVISUAL}
  vcl.dialogs,
{$ENDIF}
  SysUtils;

procedure TLayeredSoil.LayerInit(max_Tiefe, potenz_f: real; n_comp: byte);

var
  i: byte;
  geo_fact: real;

begin
  if n_comp + 2 > max_comp then
  begin

{$IFNDEF NONVISUAL}
    ShowMessage('Initialisierung eines Bodenobjektes mit ' +
      'zu großer Zahl an Kompartimenten');
{$ELSE}
    writeln('Initialisierung eines Bodenobjektes mit ' +
      'zu großer Zahl an Kompartimenten');
{$ENDIF}
    exit;
  end;
  geo_fact := power(max_Tiefe, potenz_f) / (n_comp);

  Depth[0].v := 0.0;
  for i := 1 to n_comp + 2 do
    Depth[i].v := power(geo_fact * (i), 1 / potenz_f);

  { Belegung des Tiefenvektors mit geometrisch steigenden Tiefen,
    auch eine freie Belegung ist möglich.
    Tiefe[0] ist die Oberfl„che (=0),
    Tiefe[n_comp+1] ist die Unterkannte des untersten berechneten
    Kompartimentes,
    Tiefe[n_com+2] ist die Unterkannte des gedachten n„chsten
    Kompartimentes }

  for i := 1 to n_comp + 1 do
    Thick[i] := Depth[i + 1].v - Depth[i].v;

  { Schichtdicke der einzelnen Kompartimente,
    Dicke[1] ist die Dicke des ersten Kompartiments }

  Dist[0] := Thick[1] / 2;
  For i := 1 to n_comp do
    Dist[i] := (Thick[i + 1] + Thick[i]) / 2;
  Dist[n_comp + 1] := Dist[n_comp];

  { Abstände der Mittelpunkte der einzelnen Kompartimente,
    Abst[1] ist der Abstand zwischen ersten und zweitem
    Kompartimentmittelpunkt }

  for i := 1 to n_comp do
  begin
    upper_w_f[i] := Thick[i] / (Thick[i] + Thick[i + 1]) * 2;
    lower_w_f[i] := Thick[i + 1] / (Thick[i] + Thick[i + 1]) * 2;
  end;

  { Wichtungsfaktoren für die Berechnung gemittelter Leitfähigkeiten
    bei unterschiedlich dicken Kompartimenten }

end;

Procedure TLayeredSoil.CreateAll;
var
  i: Integer;

begin
  inherited CreateAll;
  n_comp := 20;
  ParCreate('MaxDepth', '[cm]', 200.0, MaxProfileDepth,
    'maximum depth of calculated profile');
  ParCreate('Potenz_f', '[]', 1.0, Power_f,
    'factor for uneven layer depth distribution');

  for i := 0 to n_comp + 2 do
  begin
    ConstCreate('Tiefe' + ndx_str(i), '[cm]', 0.0, false, Depth[i]); // richtig
    // richtig
    ConstCreate('Tiefe' + ndx_str(i), '[cm]', 0.0, false, Depth[i]);
    Depth[i].writeToFile := false;
  end;
  OptCreate('Texture_version', 'KA', Texture_versionOption,
    'Option for choosing different pedotransfer functions, RR="Rote Reihe", "KA"=addendum to KA5');
  Texture_versionOption.OptionList.Clear;
  Texture_versionOption.OptionList.Add('RR');
  Texture_versionOption.OptionList.Add('KA');

end;

procedure TLayeredSoil.Init(var GlobMod: Tmod);

begin
  // If GlobMod <> nil then
  inherited Init(GlobMod);
  // If GlobMod <> nil then
  LayerInit(MaxProfileDepth.v, 1, n_comp);

end;

procedure TLayeredSoil.CalcRates;

begin
  // do nothing
end;

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
  b: TSoilArray { Rechte Seite des Systems }
  ): byte; { Fehlerparameter }
{ Wiederholungsflagge }
function trdiag(rep: boolean;
  { Dimension der Matrix }
  max_n, min_n: Integer;
  { Subdiagonale }
  var lower,
  { Diagonale }
  diag,
  { Superdiagonale }
  upper,
  { Rechte Seite des Systems }
  b: TSoilArray
  { Fehlerparameter }
  ): byte;
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
  { Wenn rep:=false ist, }
  if not(rep) then
  begin
    { Dreieckzerlegung der Matrix bestimmen }
    for i := min_n + 1 to max_n do
    begin
      if (abs(diag[i - 1]) < 1E-16) then { Wenn ein diag[i] = 0 }
      { Wenn ein diag[i] = 0 }
      if (abs(diag[i - 1]) < 1E-16) then
      begin
        trdiag := 2;
        exit;
      end; { ist, ex. keine Zerle- }
      lower[i] := lower[i] / diag[i - 1]; { gung. }
      end;
      { ist, ex. keine Zerle- gung. }
      lower[i] := lower[i] / diag[i - 1];
      diag[i] := diag[i] - lower[i] * upper[i - 1];
    end;
    if (abs(diag[max_n]) < 1E-16) then
    begin
      trdiag := 2;
      exit
    end;
  end;
  for i := min_n + 1 to max_n do { Vorwaertselimination }
  { Vorwaertselimination }
  for i := min_n + 1 to max_n do
    b[i] := b[i] - lower[i] * b[i - 1];
  b[max_n] := b[max_n] / diag[max_n]; { Rueckwaertselimination }
  { Rueckwaertselimination }
  b[max_n] := b[max_n] / diag[max_n];
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

procedure Register;
begin

{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TLayeredSoil]);
{$ELSE}
{$ENDIF}
end;

end.

