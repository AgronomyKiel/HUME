/// <summary>Bounded Voronoi cells in physical coordinates, independent of VCL.</summary>
unit URootVoronoi;
interface
uses System.SysUtils, System.Math;
type
  TVoronoiPoint = record
    X, Y: Double;
  end;
  TVoronoiPolygon = TArray<TVoronoiPoint>;
  TVoronoiCell = record
    Vertices: TVoronoiPolygon;
    Area, EquivalentRadius: Double;
  end;
  TVoronoiCells = TArray<TVoronoiCell>;
/// <summary>Clips each nearest-root cell to [0,Width] x [0,Height].
/// Duplicate sites share their geometric cell area equally. Complexity O(N squared).
/// Radius is sqrt(area/pi), in the same units as the coordinates.</summary>
function BuildRootVoronoi(const Sites: TVoronoiPolygon;
  Width, Height: Double): TVoronoiCells;
/// <summary>Area-weighted moments of local density 1/cell area over all bounded cells.
/// Equal root length through the layer makes these also soil-volume-weighted moments.</summary>
procedure VoronoiAreaRLDMoments(const Cells: TVoronoiCells; out Mean, CV: Double);
implementation
procedure VoronoiAreaRLDMoments(const Cells: TVoronoiCells; out Mean, CV: Double);
var I: Integer; TotalArea, Variance, Delta: Double;
begin
  Mean := 0; CV := 0;
  if Length(Cells) = 0 then Exit;
  TotalArea := 0;
  for I := 0 to High(Cells) do begin
    if IsNan(Cells[I].Area) or IsInfinite(Cells[I].Area) or (Cells[I].Area <= 0) then
      raise EArgumentException.Create('RLD moments require finite positive Voronoi areas');
    TotalArea := TotalArea + Cells[I].Area;
  end;
  if IsInfinite(TotalArea) then
    raise EArgumentException.Create('Total Voronoi area must be finite');
  /// <summary>Sum(area * 1/area) / sum(area) conserves the observed root count.</summary>
  Mean := Length(Cells) / TotalArea;
  Variance := 0;
  for I := 0 to High(Cells) do begin
    Delta := 1/Cells[I].Area - Mean;
    Variance := Variance + (Cells[I].Area/TotalArea)*Sqr(Delta);
  end;
  CV := Sqrt(Max(0, Variance)) / Mean;
end;

function Point(X, Y: Double): TVoronoiPoint;
begin Result.X := X; Result.Y := Y; end;
function Clip(const P: TVoronoiPolygon; NX, NY, MX, MY: Double): TVoronoiPolygon;
var I, Count: Integer; A, B: TVoronoiPoint; DA, DB, T: Double;
  procedure Add(const V: TVoronoiPoint);
  begin Result[Count] := V; Inc(Count); end;
begin
  SetLength(Result, 2*Length(P)); Count := 0;
  if Length(P) = 0 then Exit;
  A := P[High(P)]; DA := NX*(A.X-MX)+NY*(A.Y-MY);
  for I := 0 to High(P) do begin
    B := P[I]; DB := NX*(B.X-MX)+NY*(B.Y-MY);
    if (DA <= 0) <> (DB <= 0) then begin
      T := DA/(DA-DB);
      Add(Point(A.X+T*(B.X-A.X), A.Y+T*(B.Y-A.Y)));
    end;
    if DB <= 0 then Add(B);
    A := B; DA := DB;
  end;
  SetLength(Result, Count);
end;
function BuildRootVoronoi(const Sites: TVoronoiPolygon;
  Width, Height: Double): TVoronoiCells;
var I, J, K, L, Multiplicity: Integer; P: TVoronoiPolygon; A, NX, NY: Double;
begin
  if IsNan(Width) or IsInfinite(Width) or IsNan(Height) or IsInfinite(Height) or
    (Width <= 0) or (Height <= 0) then
    raise EArgumentException.Create('Voronoi domain must be finite and positive');
  for I := 0 to High(Sites) do
    if IsNan(Sites[I].X) or IsInfinite(Sites[I].X) or
       IsNan(Sites[I].Y) or IsInfinite(Sites[I].Y) or
       (Sites[I].X < 0) or (Sites[I].X > Width) or
       (Sites[I].Y < 0) or (Sites[I].Y > Height) then
      raise EArgumentException.Create('Voronoi root coordinates must lie in the domain');
  SetLength(Result, Length(Sites));
  for I := 0 to High(Sites) do begin
    P := TVoronoiPolygon.Create(Point(0,0), Point(Width,0),
      Point(Width,Height), Point(0,Height));
    Multiplicity := 1;
    for J := 0 to High(Sites) do if J <> I then begin
      NX := Sites[J].X-Sites[I].X; NY := Sites[J].Y-Sites[I].Y;
      if (NX = 0) and (NY = 0) then Inc(Multiplicity)
      else P := Clip(P, NX, NY, Sites[I].X+NX/2, Sites[I].Y+NY/2);
    end;
    A := 0;
    if Length(P) >= 3 then
      for K := 1 to High(P)-1 do begin
        L := K+1;
        A := A+(P[K].X-P[0].X)*(P[L].Y-P[0].Y)-
          (P[L].X-P[0].X)*(P[K].Y-P[0].Y);
      end;
    Result[I].Vertices := P;
    Result[I].Area := Abs(A)/2/Multiplicity;
    Result[I].EquivalentRadius := Sqrt(Result[I].Area/Pi);
  end;
end;
end.
