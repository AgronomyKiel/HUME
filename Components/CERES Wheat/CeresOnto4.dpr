program CeresOnto4;

uses
  Forms,
  CeresDev4 in 'CeresDev4.pas' {FormMod1},
  UFormMod in 'M:\HUME\UFORMMOD.pas' {FormMod},
  UFormGraph in 'M:\HUME\UFormGraph.pas' {FormGraph},
  UTextFileH in 'M:\HUME\UTextFileH.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TFormMod, FormMod);
  Application.CreateForm(TFormGraph, FormGraph);
  Application.Run;
end.
