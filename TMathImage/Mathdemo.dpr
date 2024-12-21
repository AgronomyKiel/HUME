program Mathdemo;


{%ToDo 'Mathdemo.todo'}

uses
 // MultiMM in '..\..\othstuff5\Robert Lee Memory Manager\MultiMM.pas',
 // HPMM in '..\..\othstuff5\Robert Lee Memory Manager\HPMM.pas',
  Forms,
  Plane in 'PLANE.PAS' {PlaneGraphs},
  Surface in 'SURFACE.PAS' {SurfaceForm},
  Ani1 in 'ANI1.PAS' {AniForm},
  Mdemo1 in 'MDEMO1.PAS' {DemoForm},
  Spcurv in 'SPCURV.PAS' {SpaceCurveForm},
  Dataplot in 'DATAPLOT.PAS' {DataPlotForm},
  Contour in 'Contour.pas' {ContourForm},
  Light in 'Light.pas' {LitSurfaceForm},
  Math in 'C:\Program Files\Borland\Delphi5\Source\Rtl\Sys\math.pas',
  Lorenz in 'Lorenz.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TDemoForm, DemoForm);
  Application.Run;
end.

