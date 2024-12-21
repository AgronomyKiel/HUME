program Polation_proj;

uses
  Forms,
  polation in 'polation.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
