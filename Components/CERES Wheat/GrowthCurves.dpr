program GrowthCurves;

uses
  Forms,
  UFormMod in '..\HUME\UFORMMOD.pas' {FormMod},
  FormGrowthCurves in 'FormGrowthCurves.pas' {FormMod1},
  UFormSubmodelEditor in '..\HUME\EditorForm\UFormSubmodelEditor.pas' {F_SubmodelEditor},
  UmrqminD in '\\samba\pflanzenmod\HUME\UMrqMinD.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TF_SubmodelEditor, F_SubmodelEditor);
  Application.Run;
end.
