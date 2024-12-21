program opt_log_decay_project;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uopt_log_decay, LResources;

{$IFDEF WINDOWS}{$R opt_log_decay_project.rc}{$ENDIF}

begin
  Application.Title:='log_decay Optimierer';
  {$I opt_log_decay_project.lrs}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

