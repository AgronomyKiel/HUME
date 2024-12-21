program CeresOntoWangEngel;

uses
  Forms,
  CeresDevWang in 'CeresDevWang.pas' {FormMod1},
  UFormMod in '\\samba\pflanzenmod\HUME\UFORMMOD.pas' {FormMod},
  UFormGraph in '\\samba\pflanzenmod\HUME\UFormGraph.pas' {FormGraph},
  UTextFileH in '\\samba\pflanzenmod\HUME\UTextFileH.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.CreateForm(TFormMod, FormMod);
  Application.CreateForm(TFormGraph, FormGraph);
  Application.Run;
end.                             
