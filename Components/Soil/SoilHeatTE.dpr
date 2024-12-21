program SoilHeatTE;

uses
  Forms,
  UFormMod in '\\SAMBA\PFLANZENMOD\HUME\UFORMMOD.pas' {FormMod},
  UFormSoilHeatTest in 'UFormSoilHeatTest.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
