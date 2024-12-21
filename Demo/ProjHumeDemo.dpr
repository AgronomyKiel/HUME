program ProjHumeDemo;

uses
{  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules, }
  Forms,
  HUME_Demo in 'HUME_Demo.pas' {FormMod2},
  UMod in '..\UMod.pas',
  UFORMMOD in '..\UFORMMOD.pas' {FormMod};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
