program PrjOSRDevelopment;

uses
  Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  FormOSRDevelopment in 'FormOSRDevelopment.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.CreateForm(TFormMod, FormMod);
  Application.Run;
end.
