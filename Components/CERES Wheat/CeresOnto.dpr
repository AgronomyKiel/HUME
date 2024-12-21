program CeresOnto;

uses
  Forms,
  UFormMod in '\\SAMBARZ\SUAPP194\USER\DELPHI5\SIMPACKAGE\UFORMMOD.pas' {FormMod},
  CeresDev in 'CeresDev.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
