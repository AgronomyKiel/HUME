program CeresOnto2;

uses
  Forms,
  CeresDev2 in 'CeresDev2.pas' {FormMod1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.Run;
end.
