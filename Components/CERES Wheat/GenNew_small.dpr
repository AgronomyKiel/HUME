program GenNew_small;

uses
  Forms,
  UFormMod in '\\FILESERVER\PFLANZENMOD\HUME\UFORMMOD.pas' {FormMod},
  Unit2 in 'Unit2.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
