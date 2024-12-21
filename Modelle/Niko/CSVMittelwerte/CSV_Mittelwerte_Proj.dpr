program CSV_Mittelwerte_Proj;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  CSV_Mittelwerte in 'CSV_Mittelwerte.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CSV Mittelwerte';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
