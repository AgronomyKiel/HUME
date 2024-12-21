program GrassGrowth;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UFORMMOD in '..\..\..\UFORMMOD.pas' {FormMod},
  UGrasGrowth in 'UGrasGrowth.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
