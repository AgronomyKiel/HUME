program ProjectTest12;

uses
  Vcl.Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  UFormTest12 in 'UFormTest12.pas' {FormMod12};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod12, FormMod12);
  Application.Run;
end.
