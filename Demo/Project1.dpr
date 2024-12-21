program Project1;

uses
  Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  Unit2 in 'Unit2.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'ModelTest';
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
