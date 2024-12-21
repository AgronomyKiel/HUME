program PrSGATest;

uses
  Forms,
  UFormMod in 'C:\Modelle\HUME\HUME\UFORMMOD.pas' {FormMod},
  FormSGATest in 'FormSGATest.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
