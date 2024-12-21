program CeresOnto3;

uses
  Forms,
  UFormMod in '\\SAMBARZ\PFLANZENMODELL\HUME\UFORMMOD.pas' {FormMod},
  CeresDev3 in 'CeresDev3.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
