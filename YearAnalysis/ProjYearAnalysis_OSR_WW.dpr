program ProjYearAnalysis_OSR_WW;

uses
  Forms,
  UFormYearAnalysis_PhenTrend in 'UFormYearAnalysis_PhenTrend.pas' {FormYearAnalysis};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormYearAnalysis, FormYearAnalysis);
  Application.Run;
end.
