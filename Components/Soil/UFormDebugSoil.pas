unit UFormDebugSoil;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, vcl.Graphics, vcl.Controls,
  vcl.Forms,
  vcl.Dialogs, VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, vcl.ExtCtrls,
  VCLTee.TeeProcs, URootedSoil, UFormDebugAbstract,
  vcl.StdCtrls, VCLTee.TeeGDIPlus;

type
  TFormDebugSoil = class(TFormDebugAbstract)
    LabelSimTime: TLabel;
    LabelIniFileName: TLabel;
    ChartDebugSoil: TChart;
    ChartWaterFlow: TChart;
    ChartTension: TChart;
    LabelBilanz1: TLabel;
    LabelRain: TLabel;
    Label_dt_int: TLabel;
    LabelIterInt: TLabel;
    LabelIntBilFehler: TLabel;
    LabelGlobTime: TLabel;
  private
    { Private-Deklarationen }
    n_comp: integer;
    fSoilWaterModel: TSoilWaterModelR;
    procedure setSoilWatermodel(WaterMod: TSoilWaterModelR);
  public
    { Public-Deklarationen }
    SeriesSoilWater: TPointSeries;
    SeriesFK: TPointSeries;
    Seriesbsat: TPointSeries;
    SeriesPWP: TPointSeries;
    SeriesFlow: TPointSeries;
    SeriesSink: TPointSeries;
    SeriesTension: TPointSeries;
    SeriesNewTension: TPointSeries;
    procedure update; override;
    procedure init; override;
    procedure MyCreate; override;

  published
    property SoilWaterModel: TSoilWaterModelR read fSoilWaterModel
      write setSoilWatermodel;

  end;

var
  FormDebugSoil: TFormDebugSoil;

implementation

{$R *.dfm}

procedure TFormDebugSoil.MyCreate;

begin
  // inherited create;

  { procedure TFormMod.SetSoilWaterMod;

    var
    i : integer;
    SubMod : TSubmodel;
    ClassRef : TClass;
    IsSoilWaterMod : boolean;

    begin
    for i := 0 to Lmod.fModel.SubModStrList.Count - 1 do begin
    SubMod :=  TSubmodel(Lmod.fModel.SubModStrList.objects[i]);
    ClassRef := SubMod.classtype;
    IsSoilWaterMod := false;
    repeat
    ClassRef := ClassRef.ClassParent;
    if ClassRef = TSoilWaterModelR then begin
    IsSoilWaterMod := true;
    if FormDebugSoil = nil then begin
    application.CreateForm(TFormDebugSoil, FormDebugSoil);
    //          FormDebugSoil.Visible := false;
    FormDebugSoil.SoilWaterModel := TSoilWaterModelR(SubMod);
    FormDebugSoil.init
    end;
    end;
    until (ClassRef = TSubmodel) or IsSoilWaterMod;
    end;
    end; }

  FormDebugSoil.SeriesSoilWater :=
    TPointSeries.create(FormDebugSoil.ChartDebugSoil);
  FormDebugSoil.SeriesFK := TPointSeries.create(FormDebugSoil.ChartDebugSoil);
  FormDebugSoil.Seriesbsat := TPointSeries.create(FormDebugSoil.ChartDebugSoil);
  FormDebugSoil.SeriesPWP := TPointSeries.create(FormDebugSoil.ChartDebugSoil);

  FormDebugSoil.SeriesFlow := TPointSeries.create(FormDebugSoil.ChartWaterFlow);
  FormDebugSoil.SeriesSink := TPointSeries.create(FormDebugSoil.ChartWaterFlow);

  FormDebugSoil.SeriesTension := TPointSeries.create
    (FormDebugSoil.ChartTension);
  FormDebugSoil.SeriesNewTension :=
    TPointSeries.create(FormDebugSoil.ChartTension);

  FormDebugSoil.ChartDebugSoil.AddSeries(FormDebugSoil.SeriesSoilWater);
  FormDebugSoil.ChartDebugSoil.AddSeries(FormDebugSoil.SeriesFK);
  FormDebugSoil.ChartDebugSoil.AddSeries(FormDebugSoil.Seriesbsat);
  FormDebugSoil.ChartDebugSoil.AddSeries(FormDebugSoil.SeriesPWP);
  FormDebugSoil.ChartWaterFlow.AddSeries(FormDebugSoil.SeriesFlow);
  FormDebugSoil.ChartWaterFlow.AddSeries(FormDebugSoil.SeriesSink);

  FormDebugSoil.ChartTension.AddSeries(FormDebugSoil.SeriesTension);
  FormDebugSoil.ChartTension.AddSeries(FormDebugSoil.SeriesNewTension);

  FormDebugSoil.SeriesFK.Title := 'FK';
  FormDebugSoil.Seriesbsat.Title := 'bsat';
  FormDebugSoil.SeriesPWP.Title := 'PWP';
  FormDebugSoil.SeriesSoilWater.Title := 'WC';
  FormDebugSoil.SeriesFlow.Title := 'Flow';
  FormDebugSoil.SeriesSink.Title := 'Sink';
  FormDebugSoil.SeriesTension.Title := 'Tension';
  FormDebugSoil.SeriesTension.Title := 'NewTension';

end;

procedure TFormDebugSoil.init;

var
  i: integer;

begin
  LabelIniFileName.Caption :=
    ExtractFileName(SoilWaterModel.GlobMod.ActIniFile.FileName);
  if FormDebugSoil.SeriesFK = NIL then
    self.MyCreate;
  FormDebugSoil.SeriesFK.clear;
  FormDebugSoil.Seriesbsat.clear;
  FormDebugSoil.SeriesPWP.clear;
  FormDebugSoil.SeriesSoilWater.clear;
  FormDebugSoil.SeriesFlow.clear;
  FormDebugSoil.SeriesSink.clear;
  FormDebugSoil.SeriesTension.clear;
  FormDebugSoil.SeriesNewTension.clear;

  n_comp := fSoilWaterModel.n_comp;
  for i := 1 to n_comp do
  begin
    with fSoilWaterModel do
    begin
      FormDebugSoil.SeriesFK.AddXY(FK_arr[i], -Depth[i].v + Thick[i] / 2, '',
        ClTeeColor);
      FormDebugSoil.Seriesbsat.AddXY(Wpar[i].b_sat, -Depth[i].v + Thick[i] / 2,
        '', ClTeeColor);
      FormDebugSoil.SeriesPWP.AddXY(PWP_arr[i], -Depth[i].v + Thick[i] / 2, '',
        ClTeeColor);
    end;
  end;
  // FormDebugSoil.ChartDebugSoil.Axes.Bottom.Maximum := self.Par_b_sat1.v*1.2;
  // FormDebugSoil.ChartDebugSoil.Axes.Bottom.Minimum := 0.0;

end;

procedure TFormDebugSoil.update;

var
  i: integer;

begin
  FormDebugSoil.Show;
  FormDebugSoil.SeriesSoilWater.clear;
  FormDebugSoil.SeriesFlow.clear;
  FormDebugSoil.SeriesSink.clear;
  FormDebugSoil.SeriesTension.clear;
  FormDebugSoil.SeriesNewTension.clear;

  // FormDebugSoil.Series1.clear;
  for i := 1 to n_comp + 1 do
  begin
    with fSoilWaterModel do
    begin
      FormDebugSoil.SeriesSoilWater.AddXY(theta_arr[i].v,
        -Depth[i].v + Thick[i] / 2, '', ClTeeColor);
      FormDebugSoil.SeriesFlow.AddXY(WflowInt_arr[i].v, -Depth[i - 1].v, '',
        ClTeeColor);
      FormDebugSoil.SeriesSink.AddXY(Sink_arr[i].v * 10,
        -Depth[i].v + Thick[i] / 2, '', ClTeeColor);
      // FormDebugSoil.SeriesSink.AddXY(fSoilWatermodel.cumBilanz_f_arr[i]*100 , -Tiefe[i].v+Dicke[i]/2, '', ClTeeColor);
      FormDebugSoil.SeriesTension.AddXY(psi_arr[i].v, -Depth[i].v + Thick[i] /
        2, '', ClTeeColor);
      FormDebugSoil.SeriesNewTension.AddXY(psi_neu[i], -Depth[i].v + Thick[i] /
        2, '', ClTeeColor);
    end;
  end;
  self.LabelSimTime.Caption := 'Date: ' +
    DateTimeToStr((fSoilWaterModel.GlobTime.v));
  self.LabelBilanz1.Caption := 'Bilanz [mm]: ' +
    FloatToStrf(fSoilWaterModel.CumWaterBalance.v, ffgeneral, 5, 2);
  self.LabelRain.Caption := 'Rain [mm]: ' +
    FloatToStrf(fSoilWaterModel.NetRain.v, ffgeneral, 5, 2);
  self.Label_dt_int.Caption := 'dt_int [d]: ' +
    FloatToStrf(fSoilWaterModel.dt.v, ffgeneral, 5, 2);
  self.LabelIterInt.Caption := 'IterInt: ' + FloatToStrf(fSoilWaterModel.iter,
    ffgeneral, 5, 0);
  self.LabelIntBilFehler.Caption := 'Int. Bilanz [mm]: ' +
    FloatToStrf(fSoilWaterModel.sum_Bilanz_f * 10, ffgeneral, 5, 2);
  self.LabelGlobTime.Caption := 'Time: ' +
    FloatToStrf(fSoilWaterModel.SumOfInternalTimeSteps.v, ffgeneral, 12, 4);


  // if fSoilwatermodel.theta_neu[7] >= 0.99*fSoilWatermodel.WPar[7].b_sat then

  // if fSoilwatermodel.GlobTime.v >= 40447 then
  // showmessage(DateTimeToStr((fSoilwatermodel.GlobTime.v)));
  FormDebugSoil.repaint;
  // FormDebugSoil.ChartDebugSoil.autorepaint := true;
  // FormDebugSoil.ChartDebugSoil.Repaint;
  // FormDebugSoil.update;
  // showmessage( floattostrf(   self.GlobTime.v, ffgeneral, 6,1));

end;

procedure TFormDebugSoil.setSoilWatermodel(WaterMod: TSoilWaterModelR);
begin
  fSoilWaterModel := WaterMod;
  WaterMod.DebugForm := self;
end;

end.
