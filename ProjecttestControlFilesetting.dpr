program ProjecttestControlFilesetting;

uses
  Vcl.Forms,
  UFORMMOD in 'UFORMMOD.pas' {FormMod},
  test_controlfilesetting in 'test_controlfilesetting.pas' {FormMod19};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod19, FormMod19);
  Application.Run;
end.
