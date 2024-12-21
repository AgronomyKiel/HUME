program exceltoini_proj;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, exel2ini, LResources
  { you can add units after this };

{$IFDEF WINDOWS}{$R exceltoini_proj.rc}{$ENDIF}

begin
  {$I exceltoini_proj.lrs}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

