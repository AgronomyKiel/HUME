program ProjGCTestRoot;

uses
  Forms,
  UFormMod in '\\SAMBA\PFLANZENMOD\HUME\UFORMMOD.pas' {FormMod},
  UForm_GCTestRoot in 'UForm_GCTestRoot.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
