program ProjTestPlantcurve;

uses
  Forms,
  UFormMod in '\\SAMBA\PFLANZENMOD\HUME\UFORMMOD.pas' {FormMod},
  UFormTestPlantCurve in 'UFormTestPlantCurve.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
