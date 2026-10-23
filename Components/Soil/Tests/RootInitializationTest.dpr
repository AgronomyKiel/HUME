program RootInitializationTest;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, UMod, U2DSoilBaseClasses, URootObject;
procedure Check(B: Boolean; const S: string);
begin if not B then raise Exception.Create(S); end;
procedure Near(A,B: Double; const S: string);
begin Check(Abs(A-B)<1E-9,S); end;
procedure Run;
var M: TSubmodRoot2D; Clock: TMod; F: string; I, Count: Integer; R: TRootObjectIn2D;
begin
  FormatSettings.DecimalSeparator := '.';
  Clock := TMod.Create;
  M := TSubmodRoot2D.Create;
  F := TPath.Combine(TPath.GetTempPath, TPath.GetRandomFileName + '.xy');
  try
    M.dimensionX.v := 20; M.dimensionY.v := 12;
    M.dim_x.v := 10; M.dim_y.v := 4;
    M.gridWidth.v := 2; M.gridHeight.v := 3;
    M.Depth.v := 10;
    M.verticMargin.v := 2; M.horizMargin.v := 1;
    M.IniMethod.Option := 'file'; M.RootDistribution.Option := 'fromsource';
    M.RootInpDataFile.Option := F;
    Check(M.RootInpDataFile.IsFileInput, 'Root input has Browse metadata');
    Check(M.OptionStrList.IndexOf('RootInpDataFileXY') < 0, 'Only one filename option');
    M.WithMargins.Option := 'withoutmargin'; M.OutputXY.Option := 'no';
    TFile.WriteAllText(F,'x y root area'+sLineBreak+'1 5 1'+#9+'20'+sLineBreak+
      '2 1 2'+#9+'20'+sLineBreak+'19 11 3'+#9+'20'+sLineBreak+'10 6 4'+#9+'20'+sLineBreak);
    Clock.Time.c := 0.0123;
    M.Init(Clock);
    Near(Clock.Time.c,0.0123,'Root initialization preserves governing timestep');
    Check(M.RootList.Count=4,'XY input without chart');
    Near(M.number_consid_roots.v,4,'Fitted domain includes all imported roots');
    Near(M.AreaMiddle.v,180,'Asymmetric margin axes');
    Near(M.RLD_mean.v,4/180,'Observed density');
    Near(M.wl.v,4/180*1E4*10,'Root length per square metre');
    R := TRootObjectIn2D(M.RootList.Objects[3]);
    Check((R.xi=6) and (R.yi=4),'Physical-coordinate cell mapping');
    M.Init(Clock); Check(M.RootList.Count=4,'Repeat init does not accumulate roots');
    M.IniMethod.Option := 'inppar';
    M.Init(Clock);
    Check(M.RootDistribution.Option='fromsource','FromSource is preserved');
    Check(M.IniMethod.Option='xyfile','FromSource selects XY input');
    Check(M.RootList.Count=4,'FromSource reads file rather than regular lattice');
    R := TRootObjectIn2D(M.RootList.Objects[3]);
    Near(R.x,11,'Imported X translated to padded domain'); Near(R.y,6,'Imported Y translated to padded domain');
    Check(Length(M.VoronoiCells)=4,'Imported roots have Voronoi cells');
    Check(M.VoronoiRadiusMean.v>0,'Imported radius statistics initialized');
    Check(M.VoronoiRLDCV.v>=0,'Imported RLD statistics initialized');
    M.WithMargins.Option := 'withmargin'; M.Init(Clock);
    Check(M.RootList.Count=4,'Padded import keeps roots at the observation bounds');
    M.WithMargins.Option := 'withoutmargin';
    M.IniMethod.Option := 'inppar'; M.RootDistribution.Option := 'regular';
    M.dimensionX.v := 20; M.dimensionY.v := 12;
    M.dim_x.v := 10; M.dim_y.v := 4; M.gridHeight.v := 3;
    M.ParMRLD.v := 0.1; M.Init(Clock); Count := M.RootList.Count;
    Check(Count>0,'Regular roots created');
    for I := 0 to Count-1 do begin
      R := TRootObjectIn2D(M.RootList.Objects[I]);
      Check((R.x>=0) and (R.y>=0),'Regular coordinates nonnegative');
      Check((R.xi>=1) and (R.xi<=10) and (R.yi>=1) and (R.yi<=4),'Regular active indices');
    end;
    Check(TRootObjectIn2D(M.RootList.Objects[Count-1]).y > 0,'Regular Y coordinates populated');
    M.Init(Clock);Check(M.RootList.Count=Count,'Regular repeat count');
    M.RootDistribution.Option := 'random'; M.Init(Clock);
    Check(M.RootList.Count=24,'Random uses requested count');
    M.ParMRLD.v := 0.2; M.Init(Clock);
    Check(M.RootList.Count=48,'Reset recalculates count after density change');
    Near(M.num_roots.v,48,'Root count output refreshed');
    M.Depth.v := 20; M.Init(Clock);
    Check(M.RootList.Count=48,'Depth scales soil volume and individual root length equally');
    Near(M.Volume.v,4800,'Reset updates soil volume');
    M.dimensionX.v := 40; M.Init(Clock);
    Check(M.RootList.Count=96,'Reset recalculates count after domain width change');
    M.dimensionY.v := 24; M.Init(Clock);
    Check(M.RootList.Count=192,'Reset recalculates count after domain height change');
    M.dimensionX.v := 20; M.dimensionY.v := 12; M.Depth.v := 10;
    M.ParMRLD.v := 0; M.Init(Clock);
    Near(M.number_consid_roots.v,0,'Reset observed count');Near(M.wl.v,0,'Reset length');
    Near(M.AvDistance.v,0,'Reset distance');
    DeleteFile(F); F := ChangeFileExt(F, '.grid');
    M.RootInpDataFile.Option := F;
    M.IniMethod.Option := 'xyfile'; M.RootDistribution.Option := 'fromsource';
    TFile.WriteAllText(F,'counts'+sLineBreak+'0'+sLineBreak+'2'+sLineBreak+'2'+sLineBreak+
      '6'+sLineBreak+'10'+sLineBreak+'1 2'+sLineBreak+'0 1'+sLineBreak);
    M.Init(Clock);Check(M.RootList.Count=4,'Raster input without grid or chart');
    M.RootInpDataFile.Option := ChangeFileExt(F, '.xy'); M.IniMethod.Option := 'file';
    try M.Init(Clock);raise Exception.Create('Missing XY input was ignored');
    except on E: ERootInputError do ; end;
    M.RootInpDataFile.Option := ChangeFileExt(F, '.txt');
    try M.Init(Clock);raise Exception.Create('Unsupported extension was accepted');
    except on E: ERootInputError do Check(Pos('expected .grid or .xy', E.Message)>0,
      'Unsupported extension explains allowed file types'); end;
    Clock.OptionIniFile := TMyIniFile.Create(F+'.ini', TEncoding.UTF8);
    Clock.OptionIniFile.WriteString(M.Name, 'IniMethod', 'InpPar');
    Clock.OptionIniFile.WriteString(M.Name, 'RootDistribution', 'regular');
    Clock.OptionIniFile.WriteString(M.Name, 'RootInpDataFileXY',
      'Q:\Kohl\DiffModell\IniFilesAusgaben\p2_t3_ges.txt');
    M.Init(Clock);
    Check(SameText(M.RootInpDataFile.Option, 'Q:\Soil2D\InpData\p2_t3_ges.xy'),
      'Legacy XY key and old built-in path migrate');
    Clock.OptionIniFile.WriteString(M.Name, 'IniMethod', 'XYFile');
    Clock.OptionIniFile.WriteString(M.Name, 'RootInpDataFile',
      'Q:\Kohl\DiffModell\IniFilesAusgaben\abo130782.txt');
    Clock.OptionIniFile.WriteString(M.Name, 'RootInpDataFileXY', ChangeFileExt(F, '.xy'));
    try M.Init(Clock);raise Exception.Create('Missing legacy XY input was ignored');
    except on E: ERootInputError do ; end;
    Check(SameText(M.RootInpDataFile.Option, ChangeFileExt(F, '.xy')),
      'Legacy XY mode selects the legacy XY key when both old keys exist');
    Clock.OptionIniFile.WriteString(M.Name, 'RootInpDataFile', F);
    Clock.OptionIniFile.WriteString(M.Name, 'RootDistribution', 'fromsource');
    M.Init(Clock);
    Check(M.IniMethod.Option='rasterdatafile', 'Grid extension overrides legacy XY mode');
    Check(M.RootList.Count=4, 'Unified filename takes precedence over legacy XY key');
    Writeln('PASS: file dispatch, legacy migration, XY/raster inputs, geometry and repeated initialization');
  finally M.Free;Clock.Free;DeleteFile(F);end;
end;
begin try Run;except on E:Exception do begin Writeln(E.ClassName+': '+E.Message);Halt(1);end;end;end.
