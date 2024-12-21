program ProjectLogGrowth_V2019;

uses
  Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  SubmodLogist_v2019 in 'SubmodLogist_v2019.pas' {FormMod2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod2, FormMod2);
  Application.Run;
end.
