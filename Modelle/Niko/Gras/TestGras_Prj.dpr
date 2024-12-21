program TestMais_Prj;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UFormMod in '..\..\..\UFORMMOD.pas' {FormMod},
  TestGras in 'TestGras.pas' {FormMod2};

begin
  Application.Initialize;
  Application.Title := 'HUME';
  //Application.CreateForm(TFormMod, FormMod);
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.

