program ProjHumeDemo_06;

uses
  Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  HUME_Demo_06 in 'HUME_Demo_06.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
