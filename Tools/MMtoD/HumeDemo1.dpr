program HumeDemo1;

uses
  Forms,
  UFormMod in '..\UFORMMOD.pas' {FormMod},
  UHumeDemo1 in 'UHumeDemo1.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
