program Ceres_V02;

uses
  Forms,
  UFormMod in '..\HUME\UFORMMOD.pas' {FormMod},
  FormCERES_V02 in '..\HUME\EditorForm\FormCERES_V02.pas' {FormMod1},
  UFormSubmodelEditor in '\\sambarz\pflanzenmodell\HUME\EditorForm\UFormSubmodelEditor.pas' {F_SubmodelEditor};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TF_SubmodelEditor, F_SubmodelEditor);
  Application.Run;
end.
