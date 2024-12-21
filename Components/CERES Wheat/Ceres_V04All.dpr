program Ceres_V04All;

uses
  Forms,
  UFormMod in '..\HUME\UFORMMOD.pas' {FormMod},
  FormCERES_V04All in '..\HUME\Components\Soil\FormCERES_V04All.pas' {FormMod1},
  UFormSubmodelEditor in '\\sambarz\pflanzenmodell\HUME\EditorForm\UFormSubmodelEditor.pas' {F_SubmodelEditor};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TF_SubmodelEditor, F_SubmodelEditor);
  Application.Run;
end.
