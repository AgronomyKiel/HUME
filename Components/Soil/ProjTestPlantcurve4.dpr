program ProjTestPlantcurve4;

uses
  Forms,
  UFormMod in '\\SAMBA\PFLANZENMOD\HUME\UFORMMOD.pas' {FormMod},
  TestForm in '..\PlantComponents\TestForm.pas' {FormMod1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.Run;
end.
