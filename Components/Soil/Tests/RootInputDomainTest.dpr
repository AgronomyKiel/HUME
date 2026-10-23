program RootInputDomainTest;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.Math, System.IOUtils,
  UMod, U2DSoilBaseClasses, URootObject;
procedure Check(B: Boolean; const S: string);
begin if not B then raise Exception.Create(S); end;
procedure Near(A, B: Double; const S: string);
begin Check(Abs(A-B) < 1E-8*Max(1,Abs(B)), S); end;
var M: TSubmodRoot2D; Clock: TMod; F: string; I: Integer; Sum: Double;
  R: TRootObjectIn2D;
begin
  M := TSubmodRoot2D.Create; Clock := TMod.Create;
  F := TPath.Combine(TPath.GetTempPath, TPath.GetRandomFileName+'.xy');
  try
    M.IniMethod.Option := 'file'; M.RootDistribution.Option := 'fromsource';
    M.WithMargins.Option := 'withoutmargin'; M.OutputXY.Option := 'no';
    M.RootInpDataFile.Option := F;
    M.gridWidth.v := 3; M.verticMargin.v := 2; M.horizMargin.v := 4;
    M.dimensionX.v := 1; M.dimensionY.v := 1; M.dim_x.v := 0; M.dim_y.v := 0;
    TFile.WriteAllText(F, 'x y root area'+sLineBreak+
      '-30 80 1 1'+sLineBreak+'-20 87 2 1'+sLineBreak+'-26 83 3 1');
    M.Init(Clock);
    Near(M.dimensionX.v,14,'Width includes both X margins');
    Near(M.dimensionY.v,15,'Height includes both Y margins');
    Near(M.dim_x.v,5,'X grid rounds up'); Near(M.dim_y.v,5,'Y grid rounds up');
    Near(M.gridHeight.v,3,'gridWidth controls both axes');
    R := TRootObjectIn2D(M.RootList.Objects[0]);
    Near(R.x,2,'Negative input X normalized'); Near(R.y,4,'Nonzero input Y normalized');
    Sum := 0;
    Check(Length(M.VoronoiCells)=3,'All imported sites have new polygons');
    for I := 0 to High(M.VoronoiCells) do begin
      Check(M.VoronoiCells[I].Area>0,'Positive polygon area');
      Sum := Sum+M.VoronoiCells[I].Area;
      R := TRootObjectIn2D(M.RootList.Objects[I]);
      Check((R.xi>=1) and (R.xi<=5) and (R.yi>=1) and (R.yi<=5),'Mapped active cells');
    end;
    Near(Sum,14*15,'Polygons cover the fitted domain');
    M.Init(Clock);
    Near(TRootObjectIn2D(M.RootList.Objects[0]).x,2,'Repeated imports do not accumulate offsets');
    Near(M.ParMRLD.v,3/(10*7),'Imported mean RLD updates the parameter');
    M.RootDistribution.Option := 'regular';
    M.WithMargins.Option := 'withmargin';
    M.Init(Clock);
    Check(M.RootDistribution.Option='regular','File input preserves Regular selection');
    Check(M.RootList.Count=3,'Regular rows preserve the imported count with margins');
    Near(M.dimensionX.v,14,'Regular distribution preserves fitted width');
    Near(M.dimensionY.v,15,'Regular distribution preserves fitted height');
    Near(M.ParMRLD.v,M.RLD_mean.v,'Regular imported density matches reported density');
    for I := 0 to M.RootList.Count-1 do begin
      R := TRootObjectIn2D(M.RootList.Objects[I]);
      Check(R.nroot=I+1,'Regular arrangement preserves root IDs');
      Check((R.x>2) and (R.x<12) and (R.y>4) and (R.y<11),
        'Regular roots stay strictly inside observation window');
      Check((R.xi>=1) and (R.xi<=5) and (R.yi>=1) and (R.yi<=5),
        'Regular roots map to active raster cells');
    end;
    Near(TRootObjectIn2D(M.RootList.Objects[0]).x,2+5/3,'First row X spacing');
    Near(TRootObjectIn2D(M.RootList.Objects[1]).x,7,'First row has evenly spaced roots');
    Near(TRootObjectIn2D(M.RootList.Objects[2]).x,12-5/3,'Last root is evenly spaced');
    M.Init(Clock);
    Check(M.RootList.Count=3,'Repeated regular import preserves count');
    Near(TRootObjectIn2D(M.RootList.Objects[0]).x,2+5/3,'Repeated regular import is deterministic');
    M.RootDistribution.Option := 'fromsource';
    TFile.WriteAllText(F,'x y root area'+sLineBreak+'1000 -500 1 1');
    M.Init(Clock);
    Near(M.dimensionX.v,7,'Single X gets one cell plus margins');
    Near(M.dimensionY.v,11,'Single Y gets one cell plus margins');
    Check(Length(M.VoronoiCells)=1,'New file content replaces old polygons');
    Near(M.VoronoiCells[0].Area,77,'Single polygon covers the new domain');
    M.gridWidth.v := 0;
    try M.Init(Clock); raise Exception.Create('Zero gridWidth accepted');
    except on E: ERootInputError do ; end;
    Writeln('PASS: automatic input extents, origins, grid counts and fresh Voronoi cells');
  finally M.Free; Clock.Free; DeleteFile(F); end;
end.
