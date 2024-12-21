unit essolver;

{$mode objfpc}{$H+}

interface

uses
  dynlibs, sysutils, ESInterfaces;

type
  TAboutProc = function: PChar;
  TPrepareDEPSSolverProc = function(AVariables, ATargets: Integer): IDEPSSolver;

var
  AboutESSolver: TAboutProc;
  PrepareDEPSSolver: TPrepareDEPSSolverProc;

implementation

var
  eslib: THandle;

initialization
  //eslib := LoadLibrary(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0) )) +
   eslib := LoadLibrary('C:\essolver.dll');

  if eslib <> 0 then
  begin
    AboutESSolver := TAboutProc(GetProcAddress(eslib, 'About'));
    PrepareDEPSSolver := TPrepareDEPSSolverProc(GetProcAddress(eslib, 'PrepareDEPSSolver'));
  end else
    writeln('Unable to load the essolver library.');
finalization
  FreeLibrary(eslib);

end.

