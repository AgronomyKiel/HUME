program CeresProject;

uses
  Forms,
  CeresForm in 'CeresForm.pas' {FormMod2},
  UFormMod in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UFORMMOD.pas' {FormMod},
  UFormGraph in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UFormGraph.pas' {FormGraph},
  UTextFileH in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UTextFileH.pas',
  UState in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UState.pas',
  UModUtils in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UModUtils.pas',
  UMod in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UMod.pas',
  UMeasValue in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UMeasValue.pas',
  UFormSubmodelEditor in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\EditorForm\UFormSubmodelEditor.pas' {F_SubmodelEditor},
  UFormModelEditor in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\EditorForm\UFormModelEditor.pas' {ModelEdit},
  UmrqminD in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UMrqMinD.pas',
  UHumeShow in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UHumeShow.pas',
  UrlLabel in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UrlLabel.pas',
  mdURLLabel in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\mdURLLabel.pas',
  UFormSelPar in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\EditorForm\UFormSelPar.pas' {FormSensOpt},
  UFormRichText in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UFormRichText.pas' {ViewFileRichtext},
  ModLink in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\ModLink.pas',
  UFormOpt in '\\samba.rz.uni-kiel.de\pflanzenmodell\HUME\UFormOpt.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.CreateForm(TFormMod, FormMod);
  Application.CreateForm(TFormGraph, FormGraph);
  Application.CreateForm(TF_SubmodelEditor, F_SubmodelEditor);
  Application.CreateForm(TModelEdit, ModelEdit);
  Application.CreateForm(TFormSensOpt, FormSensOpt);
  Application.CreateForm(TViewFileRichtext, ViewFileRichtext);
  Application.Run;
end.
