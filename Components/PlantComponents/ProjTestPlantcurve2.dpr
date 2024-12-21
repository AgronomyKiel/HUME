program ProjTestPlantcurve2;

uses
  Forms,
  UFormMod in '\\SAMBA\PFLANZENMOD\HUME\UFORMMOD.pas' {FormMod},
  UFormTestPlantCurve2 in 'UFormTestPlantCurve2.pas' {FormMod2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
