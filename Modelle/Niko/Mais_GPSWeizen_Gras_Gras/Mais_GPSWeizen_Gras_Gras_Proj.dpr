program Mais_GPSWeizen_Gras_Gras_Proj;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UFORMMOD in '..\..\..\UFORMMOD.pas' {FormMod},
  Mais_GPSWeizen_Gras_Gras in 'Mais_GPSWeizen_Gras_Gras.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
