program Pixelzaehler;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  UPixelzaehler in 'UPixelzaehler.pas' {Form1},
  Help in 'Help.pas' {FormFarbraum},
  Info in 'Info.pas' {FormInfo};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormFarbraum, FormFarbraum);
  Application.CreateForm(TFormInfo, FormInfo);
  Application.Run;
end.
