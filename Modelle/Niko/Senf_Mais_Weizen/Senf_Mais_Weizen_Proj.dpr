program Senf_Mais_Weizen_Proj;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UFORMMOD in '..\..\..\UFORMMOD.pas' {FormMod},
  Senf_Mais_Weizen in 'Senf_Mais_Weizen.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
