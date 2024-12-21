program Ceres_V2;

uses
  Forms,
  UFormMod in 'm:\HUME\UFORMMOD.pas' {FormMod},
  FormCERES_V2 in 'FormCERES_V2.pas' {FormMod1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.Run;
end.
