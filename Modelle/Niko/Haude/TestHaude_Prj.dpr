program TestHaude_Prj;

uses
  Forms,
  UFORMMOD in '..\..\..\UFORMMOD.pas' {FormMod},
  TestHaude in 'TestHaude.pas' {FormMod2},
  Concentration_Niko in '..\..\..\Components\Soil\Concentration_Niko.pas',
  UFormShow1_1 in '..\..\..\EditorForm\UFormShow1_1.pas' {FormShow1_1};

{$R *.RES}


begin
  Application.Initialize;
  Application.Title := 'HUME';
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.

