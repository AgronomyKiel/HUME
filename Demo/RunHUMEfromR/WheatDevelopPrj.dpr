program WheatDevelopPrj;

uses
  Forms,
  UFORMMOD in '..\..\UFORMMOD.pas' {FormMod},
  WheatDevelopForm in 'WheatDevelopForm.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
