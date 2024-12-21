program Mais_Project;






uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UFORMMOD in '..\..\..\UFORMMOD.pas' {FormMod},
  Mais in 'Mais.pas' {FormMod1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Stickstoff Mais';
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TFormMod, FormMod);
  Application.Run;
end.
