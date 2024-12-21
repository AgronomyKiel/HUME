program Weizen_Gras_Mais_WeizenProj;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UFORMMOD in '..\..\..\UFORMMOD.pas' {FormMod},
  Weizen_Gras_Mais_Weizen in 'Weizen_Gras_Mais_Weizen.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
