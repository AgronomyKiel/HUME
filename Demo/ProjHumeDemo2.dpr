program ProjHumeDemo2;

uses
  Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  UDemo2 in 'UDemo2.pas' {FormMod1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.Run;
end.
