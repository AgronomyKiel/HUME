program wurzelparam_opt;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, wurzelparam_optimierung, LResources
  { you can add units after this };

{$IFDEF WINDOWS}{$R wurzelparam_opt.rc}{$ENDIF}

begin
  {$I wurzelparam_opt.lrs}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

