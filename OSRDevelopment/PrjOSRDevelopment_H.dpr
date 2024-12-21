program PrjOSRDevelopment_H;

uses
  Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  FormOSRDevelopment_H in 'FormOSRDevelopment_H.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.CreateForm(TFormMod, FormMod);
  Application.Run;
end.
