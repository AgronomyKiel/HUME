program Ceres_V02;

uses
  Forms,
  UFormMod in '..\UFORMMOD.pas' {FormMod},
  FormCERES_V02 in 'FormCERES_V02.pas' {FormMod1},
  UFormSubmodelEditor in 'EditorForm\UFormSubmodelEditor.pas' {F_SubmodelEditor};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TF_SubmodelEditor, F_SubmodelEditor);
  Application.Run;
end.
