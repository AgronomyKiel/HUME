// JCL_DEBUG_EXPERT_GENERATEJDBG ON
program ProjHumeDemo3;

uses
  Vcl.Forms,
  UFORMMOD in '..\UFORMMOD.pas' {FormMod},
  HUME_Demo3 in 'HUME_Demo3.pas' {FormMod_Demo};

{$R *.res}

begin
  Application.Initialize;
//  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMod_Demo, FormMod_Demo);
  Application.Run;
end.
