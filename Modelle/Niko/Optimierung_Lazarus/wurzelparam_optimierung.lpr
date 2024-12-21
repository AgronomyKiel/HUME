program wurzelparam_optimierung;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  //Interfaces, // this includes the LCL widgetset
  Forms, wurzelparam_optimierung2, Interfaces
  { you can add units after this };

{$IFDEF WINDOWS}{$R wurzelparam_optimierung.rc}{$ENDIF}

begin
  {$I wurzelparam_optimierung.lrs}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

