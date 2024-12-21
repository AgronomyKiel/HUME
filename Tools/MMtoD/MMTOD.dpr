program MMTOD_;

uses
  Forms,
  unit_MMtoD in 'unit_MMtoD.pas' {Form1},
  UVarREc in 'UVarREc.pas',
  UFormAddPar in 'UFormAddPar.pas' {AddParDlg},
  UFormAddExVar in 'UFormAddExVar.pas' {AddExVarDlg};

{AddExVarDlg}
{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAddParDlg, AddParDlg);
  Application.CreateForm(TAddExVarDlg, AddExVarDlg);
  Application.Run;
end.
