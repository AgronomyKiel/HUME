unit UDailyCropSurfaceTemperatures;

{ *
  by Arne M. Ratjen
  - according to 'Integrating wheat canopy temperatures in crop system models'
  Neukamp et al. 2015
  - CO2 affected change of canopy temperature implemented (luig & Ratjen 03.08.2016)
  * }
interface

uses
  Windows, UAbstractPlant, Messages, SysUtils, Classes,
  // Graphics, Controls, Forms,
  // Dialogs,
  UMod, Math, UState;

type
  TCropSurfaceTemp = class(TPlantRelatedSubMod)

  protected
    // fHemisphere: THemisphere;
    function f_dec(DOY: real): real;
    function calcSunElevationAngle(LST, DOY, lat: real): real;
    function getSunTime(DOY, dec_hour, lon, lonCTZ: real): real;
    function calcHourlyTemp(dec_hour, Tmax, Tmin: real): real;

  private
    // private Objekts

  public
    EC: TExternV;
    TransIntRatio: TExternV;
    TMPM: TExternV; // daily mean temperature
    TMPMN: TExternV; // daily minimum temperature
    TMPMX: TExternV; // daily maximum temperature
    Sat_def: TExternV;
    Rad_Int: TExternV;
    LAI: TExternV;
    CropHeight: TExternV;
    Act_Evap: TExternV;
    ActTrans: TExternV;
    pETP: TExternV;
    Eact_ETP: TExternV; // Ratio of act. evaporation to pot. evapotranspiration
    DayofYear: TExternV;
    CO2TransDiff: TExternV;
    relCO2TransDiff: TExternV;

    measTcMax: TExternV;
    // measured maximum canopy temperature from weather file to replace MaxCanopyTemp if Opt_Tc_source is set to fromWeatherFile
    measTcMean: TExternV;
    // measured mean canopy temperature from weather file to replace MeanCanopyTemp if Opt_Tc_source is set to fromWeatherFile
    measTcMin: TExternV;
    // measured minimum canopy temperature from weather file to replace MinCanopyTemp if Opt_Tc_source is set to fromWeatherFile
    HeatRing_IO: TExternV;
    // O/I  signal that reflects if maesTc[...] are maniupulated with T-FACE technique

    pIntT45corr: TPar;
    pCT_0T45corr: TPar;
    pdayTMPMT45corr: TPar;
    pTDiffMeanT45corr: TPar;
    pTDiffMaxT45corr: TPar;
    pln_LAIT45corr: TPar;
    pSunAngleT45corr: TPar;
    pRad_IntT45corr: TPar;
    pTDiffMean_lnLAIT45corr: TPar;
    pTDiffMean_SunAngleT45corr: TPar;
    pTDiffMax_lnLAIT45corr: TPar;
    plnLAI_Rad_IntT45corr: TPar;
    pSunAngle_Rad_IntT45corr: TPar;

    Mean_Int: TPar;
    Mean_TMPM: TPar;
    Mean_Rint: TPar;
    Mean_LAI_log: TPar;
    Mean_Eact_ETP: TPar;
    Mean_VPD: TPar;
    Mean_TransRatio_VPD: TPar;
    minLAI: TPar;
    lon: TPar;
    lat: TPar;
    lonCTZ: TPar;

    Max_I_Int: TPar;
    Max_I_Rint: TPar;
    Max_I_TMPMX: TPar;
    Max_I_LAI_log: TPar;
    Max_I_TransRatio_VPD: TPar;

    Max_II_Int: TPar;
    Max_II_Rint: TPar;
    Max_II_TMPMX: TPar;
    Max_II_LAI_log: TPar;
    Max_II_TransRatio_VPD: TPar;

    Min_I_Int: TPar;
    Min_I_CH: TPar;
    Min_I_TMPMN: TPar;

    Min_II_Int: TPar;
    Min_II_VPD: TPar;
    Min_II_TMPMN: TPar;
    Min_II_Eact_ETP: TPar;

    fWMeanTpheno: TPar; // weighting factor for phenological mean. canopy temp
    fWMeanTDrymatter: TPar;
    fWMeanTpartitioning: TPar;
    // restrict extrem values to the observed pattern according to Neukam et al. ??
    Mean_min_Delta: TPar;
    Mean_max_Delta: TPar;
    Min_min_Delta: TPar;
    Min_max_Delta: TPar;
    Max_min_Delta: TPar;
    Max_max_Delta: TPar;

    CO2IncreaseTcmax, CO2IncreaseTcmean, CO2IncreaseTcmin: TPar;
    { *
      luig, ratjen: 03.08.2016
      - linear regression models (Intercept = 0) to calculate the change of canopy temperature as a function of
      the absolute difference in transpiration from ambient (threshold of 380ppm set in PenmanMonteith) to differing CO2 concentrations (CO2TransDiff)
      - assuming a proportionality between rel. CO2 effect on pot. transpiration and act. transpiration
      - fits were done on basis of nadir=45° canopy temperature measurements  from Braunschweig FACE trial 2013/2014 & 2014/2015
      - current implementation assumes same canopy temperature changes for measurement angles nadir=0° and nadir=45°
      - deltaTModel takes the model error due to the consideration of CO2 affected TransRatio into account (at original model (Neukam et al. 2016)
      CO2 is negative correlated with canopy temperature).
      - while deltaTMeasured  represents the camopy temperature change from ambient to differing (enhanced) CO2 concentrations
      - both parameters were combined to
      CO2IncreaseTc[...] =    deltaTModelTc[...] +  deltaTMeasuredTc[...]

      summarized resutls from linear regression fits
      target       slope     adj.R2    pValue       Significance
      deltaTModelTcmean45 -0.90202822   0.27  4.506942e-17          ***
      deltaTModelTcmax45 -1.22956546   0.40  4.514456e-26          ***
      deltaTModelTcmin45  0.27749148   0.06  1.661850e-04          ***
      deltaTMeasuredTcmean45 -0.51332939   0.28  5.805150e-18          ***
      deltaTMeasuredTcmax45 -0.93811569   0.28  7.573895e-18          ***
      deltaTMeasuredTcmin45 -0.23466416   0.05  7.766288e-04          ***
      CO2IncreaseTcmax -2.16768115   0.58  3.495563e-43          ***
      CO2IncreaseTcmean -1.41535761   0.44  6.494532e-30          ***
      CO2IncreaseTcmin  0.04282732   0.00  6.501400e-01
    }
    Dphen: TVar;
    MeanCanopyTemp: TVar;
    MinCanopyTemp: TVar;
    MaxCanopyTemp: TVar;
    MinCanopyTemp45: TVar;
    MaxCanopyTemp45: TVar;
    PhenoTemp: TVar;
    DryMatterTemp: TVar;
    PartitioningTemp: TVar;
    TDiffMean: TVar;
    TDiffMin: TVar;
    TDiffMax: TVar;
    TDiffMin45: TVar;
    TDiffMax45: TVar;
    EstTranspDiff: TVar;
    PseudoMeanTemp: TVar;

    TmaxCO2Change, TmeanCO2Change, TminCO2Change: TVar;
    TC_Hourly: array [1 .. 24] of TVar;
    TC_Hourly_45: array [1 .. 24] of TVar;
    Hourly_Elevation: array [1 .. 24] of TVar;

    Opt_Tc_source: TOption;

    procedure calc45AngleT(LAI: real);
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    property Ex_EC: TExternV read EC write EC;
    property Ex_TransIntRatio: TExternV read TransIntRatio write TransIntRatio;
    property Ex_TMPMN: TExternV read TMPMN write TMPMN;
    property Ex_TMPMX: TExternV read TMPMX write TMPMX;
    property Ex_Sat_def: TExternV read Sat_def write Sat_def;
    property Ex_Rad_Int: TExternV read Rad_Int write Rad_Int;
    property Ex_LAI: TExternV read LAI write LAI;
    property Ex_CropHeight: TExternV read CropHeight write CropHeight;
    property Ex_Act_Evap: TExternV read Act_Evap write Act_Evap;
    property Ex_ActTrans: TExternV read ActTrans write ActTrans;
    property Ex_pETP: TExternV read pETP write pETP;
    property Ex_Eact_ETP: TExternV read Eact_ETP write Eact_ETP;
    property Ex_CO2TransDiff: TExternV read CO2TransDiff write CO2TransDiff;
    property Ex_relCO2TransDiff: TExternV read relCO2TransDiff
      write relCO2TransDiff;
    property Ex_measTcMax: TExternV read measTcMax write measTcMax;
    property Ex_measTcMean: TExternV read measTcMean write measTcMean;
    property Ex_measTcMin: TExternV read measTcMin write measTcMin;
    property Ex_HeatRing_IO: TExternV read HeatRing_IO write HeatRing_IO;

    // property Ex_DayofYear : TExternV read DayofYear write DayofYear;

  end;

procedure Register;

implementation

uses UModUtils;

procedure TCropSurfaceTemp.calc45AngleT(LAI: real);
var
  i: integer;
  TDiffA45_arr: array [1 .. 24] of real;
begin
  { *
    Call:
    lm(formula = TDiffAngle ~ CT_0. + dayTMPM + TDiffMean + TDiffMax +
    lnLAI + SunAngle + Rad_Int + TDiffMean:lnLAI + TDiffMean:SunAngle +
    TDiffMax:lnLAI + Rad_Int:lnLAI + Rad_Int:SunAngle, data = parallelMeasurements)

    Residuals:
    Min      1Q  Median      3Q     Max
    -5.2492 -0.3717  0.0080  0.3433  4.1540

    Coefficients:
    Estimate Std. Error t value Pr(>|t|)
    (Intercept)         5.798e-01  8.558e-02   6.775 1.46e-11 ***
    CT_0.              -5.998e-02  4.132e-03 -14.515  < 2e-16 ***
    dayTMPM             4.739e-02  5.809e-03   8.158 4.74e-16 ***
    TDiffMean           2.817e-01  4.839e-02   5.821 6.40e-09 ***
    TDiffMax           -2.465e-01  2.435e-02 -10.124  < 2e-16 ***
    lnLAI              -4.122e-01  4.645e-02  -8.874  < 2e-16 ***
    SunAngle            1.104e-02  1.310e-03   8.427  < 2e-16 ***
    Rad_Int             1.164e-03  2.565e-04   4.537 5.92e-06 ***
    TDiffMean:lnLAI    -2.327e-01  3.159e-02  -7.366 2.21e-13 ***
    TDiffMean:SunAngle -4.626e-03  4.387e-04 -10.544  < 2e-16 ***
    TDiffMax:lnLAI      6.567e-02  2.171e-02   3.025   0.0025 **
    lnLAI:Rad_Int       4.358e-04  8.178e-05   5.329 1.05e-07 ***
    SunAngle:Rad_Int   -3.233e-05  5.046e-06  -6.407 1.69e-10 ***
    ---
    Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

    Residual standard error: 0.7395 on 3372 degrees of freedom
    Multiple R-squared:  0.3712,	Adjusted R-squared:  0.369
    F-statistic: 165.9 on 12 and 3372 DF,  p-value: < 2.2e-16
    * }

  for i := 1 to 24 do
  begin

    if LAI > 0 then
    begin
      TDiffA45_arr[i] := pIntT45corr.v + pCT_0T45corr.v * TC_Hourly[i].v +
        pdayTMPMT45corr.v * TMPM.v + pTDiffMeanT45corr.v * TDiffMean.v +
        pTDiffMaxT45corr.v * TDiffMax.v + pln_LAIT45corr.v * ln(LAI) +
        pSunAngleT45corr.v * Hourly_Elevation[i].v + pRad_IntT45corr.v *
        Rad_Int.v + pTDiffMean_lnLAIT45corr.v * TDiffMean.v * ln(LAI) +
        pTDiffMean_SunAngleT45corr.v * TDiffMean.v * Hourly_Elevation[i].v +
        pTDiffMax_lnLAIT45corr.v * TDiffMax.v * ln(LAI) +
        plnLAI_Rad_IntT45corr.v * ln(LAI) * Rad_Int.v +
        pSunAngle_Rad_IntT45corr.v * Hourly_Elevation[i].v * Rad_Int.v;

      TC_Hourly_45[i].v := TC_Hourly[i].v + TDiffA45_arr[i];

    end
    else
      TC_Hourly_45[i].v := TC_Hourly[i].v;
    if i = 1 then
    begin
      MinCanopyTemp45.v := TC_Hourly_45[i].v;
      MaxCanopyTemp45.v := TC_Hourly_45[i].v
    end
    else
    begin
      if MinCanopyTemp45.v > TC_Hourly_45[i].v then
        MinCanopyTemp45.v := TC_Hourly_45[i].v;
      if MaxCanopyTemp45.v < TC_Hourly_45[i].v then
        MaxCanopyTemp45.v := TC_Hourly_45[i].v;
    end;
  end;
  TDiffMin45.v := MinCanopyTemp45.v - TMPMN.v;
  TDiffMax45.v := MaxCanopyTemp45.v - TMPMX.v;
end;

function TCropSurfaceTemp.f_dec(DOY: real): real;
var
  rad, x, dec: real;
begin
  rad := pi / 180.0;
  x := arcsin(sin(23.45 * rad) * cos(2. * pi * (DOY + 10) / 365));
  dec := x * -1;
  result := dec;
end;

function TCropSurfaceTemp.calcSunElevationAngle(LST, DOY, lat: real): real;
var
  dec, rad, sinld, cosld, x: real;
begin
  // hour as local sun time
  dec := f_dec(DOY);
  rad := pi / 180.0;
  sinld := sin(rad * lat) * sin(dec);
  cosld := cos(rad * lat) * cos(dec);
  x := sinld + cosld * cos(2.0 * pi * (LST + 12.0) / 24);
  x := x / (pi / 180.0); // rad ->°
  if (x < 0) then
    x := 0;
  result := x;
end;

function TCropSurfaceTemp.getSunTime(DOY, dec_hour, lon, lonCTZ: real): real;
var
  Year, Month, Day, Min: Word;
  lamda_loc, lamda_st, EOT, B, suntime: real;
begin
  // DOY := GlobMod.Time.v + 1 - EncodeDate(Year, 1, 1);
  B := (DOY - 1) * (360 / 365);
  // EOT(equation of time)
  EOT := 229.2 * (0.000075 + 0.001868 * cos(B) - 0.032077 * sin(B) - 0.014615 *
    cos(B * 2.0) - 0.04089 * sin(B * 2.0));
  // min. -> dec. hour
  EOT := EOT / 60;
  suntime := dec_hour + (4 / 60) * (lon - lonCTZ) + EOT;
  if (suntime < 0) then
    suntime := suntime + 23;
  result := suntime;
end;

function TCropSurfaceTemp.calcHourlyTemp(dec_hour, Tmax, Tmin: real): real;
var
  p1, p2, p3, h_temp, x: real;
begin
  // Campbell & Norman Environmental Biophysics (1998) p. 23
  p1 := 0.44;
  p2 := 0.46;
  p3 := 0.9;
  x := getSunTime(DayofYear.v, dec_hour, lon.v, lonCTZ.v);
  h_temp := Tmax * (p1 - p2 * sin((x * pi) / 12 + p3) + 0.11 *
    sin((x * 2 * pi) / 12 + p3)) + Tmin *
    (1 - (p1 - p2 * sin((x * pi) / 12 + p3) + 0.11 * sin((x * 2 * pi) /
    12 + p3)));
  result := h_temp;

end;

procedure TCropSurfaceTemp.createAll;
var
  i: integer;
begin
  inherited createAll;

  ExternVCreate('EC', '[BBCH]', statefield, EC);
  ExternVCreate('TransIntRatio', '[-]', statefield, TransIntRatio);
  ExternVCreate('TMPM', '[°C]', statefield, TMPM);
  ExternVCreate('TMPMN', '[°C]', statefield, TMPMN);
  ExternVCreate('TMPMX', '[°C]', statefield, TMPMX);
  ExternVCreate('Sat_def', '[hPa]', statefield, Sat_def);
  ExternVCreate('Rad_Int', '[W/m2]', statefield, Rad_Int);
  ExternVCreate('LAI', '[-]', statefield, LAI);
  ExternVCreate('Height', '[m]', statefield, CropHeight);
  ExternVCreate('Act_Evap', '[mm/d]', statefield, Act_Evap);
  ExternVCreate('ActTrans', '[mm/d]', statefield, ActTrans);
  ExternVCreate('pETP', '[mm/d]', statefield, pETP, 'pot. evapo-transpiration');
  ExternVCreate('Eact_ETP', '[-]', statefield, Eact_ETP,
    'Ration of act. evaporation to pot. evapotranspiration');
  ExternVCreate('DayofYear', '[d]', statefield, DayofYear);
  ExternVCreate('CO2TransDiff', '[mm/d]', statefield, CO2TransDiff,
    'CO2 induced reduction of pot_trans');
  ExternVCreate('relCO2TransDiff', '[-]', statefield, relCO2TransDiff,
    'rel. CO2 induced reduction of pot_trans');
  ExternVCreate('measTcMax', '[°C]', statefield, measTcMax,
    'measured maximum canopy temperature from weather file to replace MaxCanopyTemp if Opt_Tc_source is set to fromWeatherFile');
  ExternVCreate('measTcMean', '[°C]', statefield, measTcMean,
    'measured mean canopy temperature from weather file to replace MeanCanopyTemp if Opt_Tc_source is set to fromWeatherFile');
  ExternVCreate('measTcMin', '[°C]', statefield, measTcMin,
    'measured minimum canopy temperature from weather file to replace MinCanopyTemp if Opt_Tc_source is set to fromWeatherFile');
  ExternVCreate('HeatRing_IO', '[-]', statefield, HeatRing_IO,
    'O/I  signal that reflects if maesTc[...] are maniupulated with T-FACE technique');

  ParCreate('pIntT45corr', '[°C]', 5.798E-01, pIntT45corr);
  ParCreate('pCT_0T45corr', '[-]', -5.998E-02, pCT_0T45corr);
  ParCreate('pdayTMPMT45corr', '[-]', 4.739E-02, pdayTMPMT45corr);
  ParCreate('pTDiffMeanT45corr', '[-]', 2.817E-01, pTDiffMeanT45corr);
  ParCreate('pTDiffMaxT45corr', '[-]', -2.465E-01, pTDiffMaxT45corr);
  ParCreate('pln_LAIT45corr', '[-]', -4.122E-01, pln_LAIT45corr);
  ParCreate('pSunAngleT45corr', '[-]', 1.104E-02, pSunAngleT45corr);
  ParCreate('pRad_IntT45corr', '[-]', 1.164E-03, pRad_IntT45corr);
  ParCreate('pTDiffMean_lnLAIT45corr', '[-]', -2.327E-01,
    pTDiffMean_lnLAIT45corr);
  ParCreate('pTDiffMean_SunAngleT45corr', '[-]', -4.626E-03,
    pTDiffMean_SunAngleT45corr);
  ParCreate('pTDiffMax_lnLAIT45corr', '[-]', 6.567E-02, pTDiffMax_lnLAIT45corr);
  ParCreate('plnLAI_Rad_IntT45corr', '[-]', 4.358E-04, plnLAI_Rad_IntT45corr);
  ParCreate('pSunAngle_Rad_IntT45corr', '[-]', -3.233E-05,
    pSunAngle_Rad_IntT45corr);

  ParCreate('CO2IncreaseTcmin', '[°C mm^-1 d^-1]', 0.04282732, CO2IncreaseTcmin,
    'changes canopy minimum canopy temperature as function of relCO2TransDiff');
  // derived from Braunschweig FACE trial 2013/2014 & 2014/2015 (nadir viewing angle 45°)
  ParCreate('CO2IncreaseTcmean', '[°C mm^-1 d^-1]', -1.41535761,
    CO2IncreaseTcmean,
    'changes canopy mean canopy temperature as function of relCO2TransDiff');
  // derived from Braunschweig FACE trial 2013/2014 & 2014/2015  (nadir viewing angle 45°)
  ParCreate('CO2IncreaseTcmax', '[°C mm^-1 d^-1]', -2.16768115,
    CO2IncreaseTcmax,
    'changes canopy maximum canopy temperature as function of relCO2TransDiff');
  // derived from Braunschweig FACE trial 2013/2014 & 2014/2015

  ParCreate('lon', '[decimal degree]', 15, lon, 'local longitude');
  ParCreate('lonCTZ', '[decimal degree]', 15, lonCTZ,
    'longitude of the time zone');
  ParCreate('lat', '[decimal degree]', 54, lat, 'local latitude');

  ParCreate('Mean_Int', '[°C]', 2.730, Mean_Int);
  ParCreate('Mean_TMPM', '[°C]', 0.942, Mean_TMPM);
  ParCreate('Mean_Rint', '[W/m2]', 0.005, Mean_Rint);
  ParCreate('Mean_LAI_log', '[-]', -1.358, Mean_LAI_log);
  ParCreate('Mean_Eact_ETP', '[-]', -5.491, Mean_Eact_ETP);
  ParCreate('Mean_VPD', '[haPa]', -0.263, Mean_VPD);
  ParCreate('Mean_TransRatio_VPD', '[-]', -0.299, Mean_TransRatio_VPD);
  ParCreate('minLAI', '[-]', 1, minLAI);

  ParCreate('Max_I_Int', '[°C]', 4.241, Max_I_Int);
  ParCreate('Max_I_Rint', '[W/m2]', 0.016, Max_I_Rint);
  ParCreate('Max_I_TMPMX', '[°C]', 0.922, Max_I_TMPMX);
  ParCreate('Max_I_LAI_log', '[-]', -2.816, Max_I_LAI_log);
  ParCreate('Max_I_TransRatio_VPD', '[mm/d]', -0.477, Max_I_TransRatio_VPD);

  ParCreate('Max_II_Int', '[°C]', 4.011, Max_II_Int);
  ParCreate('Max_II_Rint', '[W/m2]', 0.014, Max_II_Rint);
  ParCreate('Max_II_TMPMX', '[°C]', 0.888, Max_II_TMPMX);
  ParCreate('Max_II_LAI_log', '[-]', -1.847, Max_II_LAI_log);
  ParCreate('Max_II_TransRatio_VPD', '[mm/d]', -0.623, Max_II_TransRatio_VPD);

  ParCreate('Min_I_Int', '[°C]', 1.116, Min_I_Int);
  ParCreate('Min_I_CH', '[m]', -4.147, Min_I_CH);
  ParCreate('Min_I_TMPMN', '[°C]', 1.088, Min_I_TMPMN);

  ParCreate('Min_II_Int', '[°C]', -0.202, Min_II_Int);
  ParCreate('Min_II_VPD', '[hPa', -0.101, Min_II_VPD);
  ParCreate('Min_II_TMPMN', '[°C]', 1.013, Min_II_TMPMN);
  ParCreate('Min_II_Eact_ETP', '[-]', -3.158, Min_II_Eact_ETP);

  ParCreate('Mean_min_Delta', '[°C]', -4, Mean_min_Delta);
  ParCreate('Mean_max_Delta', '[°C]', 3.8, Mean_max_Delta);

  ParCreate('Min_min_Delta', '[°C]', -7.2, Min_min_Delta);
  ParCreate('Min_max_Delta', '[°C]', 1.8, Min_max_Delta);

  ParCreate('Max_min_Delta', '[°C]', -2.5, Max_min_Delta);
  ParCreate('Max_max_Delta', '[°C]', 11.6, Max_max_Delta);

  ParCreate('fWMeanTpheno', '[-]', 0.681876, fWMeanTpheno,
    'weighting factor to include mean. canopy temperature in Development');
  ParCreate('fWMeanTDrymatter', '[-]', 3.38952, fWMeanTDrymatter,
    'weighting factor to include max. canopy temperature in Dry Matter Production');
  ParCreate('fWMeanTPartitioning', '[-]', 1.9167, fWMeanTpartitioning,
    'weighting factor to include mean. canopy temperature in Partitioning');

  for i := 1 to 24 do
  begin
    if i < 11 then
      VarCreate('TC_Hourly__' + IntToStr(i - 1), '[°C]', 0, true, TC_Hourly[i])
    else
      VarCreate('TC_Hourly_' + IntToStr(i - 1), '[°C]', 0, true, TC_Hourly[i]);

    if i < 11 then
      VarCreate('TC_Hourly_45__' + IntToStr(i - 1), '[°C]', 0, true,
        TC_Hourly_45[i])
    else
      VarCreate('TC_Hourly_45_' + IntToStr(i - 1), '[°C]', 0, true,
        TC_Hourly_45[i]);

    if i < 11 then
      VarCreate('Hourly_Elevation__' + IntToStr(i - 1), '[°]', 0, true,
        Hourly_Elevation[i])
    else
      VarCreate('Hourly__Elevation' + IntToStr(i - 1), '[°]', 0, true,
        Hourly_Elevation[i]);
  end;

  VarCreate('Dphen', '[-]', 0, true, Dphen, 'logical 0_1 variable');
  VarCreate('MeanCanopyTemp', '[°C]', 0, true, MeanCanopyTemp);
  VarCreate('MinCanopyTemp', '[°C]', 0, true, MinCanopyTemp);
  VarCreate('MaxCanopyTemp', '[°C]', 0, true, MaxCanopyTemp);
  VarCreate('MinCanopyTemp45', '[°C]', 0, true, MinCanopyTemp45);
  VarCreate('MaxCanopyTemp45', '[°C]', 0, true, MaxCanopyTemp45);
  VarCreate('PhenoTemp', '[°C]', 0, true, PhenoTemp);
  VarCreate('DryMatterTemp', '[°C]', 0, true, DryMatterTemp);
  VarCreate('PartitioningTemp', '[°C]', 0, true, PartitioningTemp);
  VarCreate('TDiffMean', '[°C]', 0, true, TDiffMean);
  VarCreate('TDiffMin', '[°C]', 0, true, TDiffMin);
  VarCreate('TDiffMax', '[°C]', 0, true, TDiffMax);
  VarCreate('TDiffMin45', '[°C]', 0, true, TDiffMin45);
  VarCreate('TDiffMax45', '[°C]', 0, true, TDiffMax45);
  VarCreate('EstTranspDiff', '[mm/d]', 0, true, EstTranspDiff);
  VarCreate('TmaxCO2Change', '[°C]', 0, true, TmaxCO2Change,
    'absolute change of maximum canopy temperature due to CO2');
  VarCreate('TmeanCO2Change', '[°C]', 0, true, TmeanCO2Change,
    'absolute change of mean canopy temperature due to CO2');
  VarCreate('TminCO2Change', '[°C]', 0, true, TminCO2Change,
    'absolute change of minimum canopy temperature due to CO2');
  VarCreate('PseudoMeanTemp', '[°C]', 0, true, PseudoMeanTemp,
    'hourly averaged temp. of the sinus distribution');

  OptCreate('Opt_Tc_source', 'calculate_tc', Opt_Tc_source);
  Opt_Tc_source.OptionList.Clear;
  Opt_Tc_source.OptionList.Add('calculate_tc');
  Opt_Tc_source.OptionList.Add('fromweatherfile');
  Opt_Tc_source.OptionList.Add('manipulated_with_heatring');
end;

procedure TCropSurfaceTemp.Init;
begin
  inherited;
  if (Opt_Tc_source.option = 'fromweatherfile') or
    (Opt_Tc_source.option = 'manipulated_with_heatring') then
  begin
    measTcMax.Search := true;
    measTcMean.Search := true;
    measTcMin.Search := true;
    HeatRing_IO.Search := true;
  end
  else
  begin
    measTcMax.Search := false;
    measTcMean.Search := false;
    measTcMin.Search := false;
    HeatRing_IO.Search := false;
  end;
end;

procedure TCropSurfaceTemp.CalcRates;
var
  LAI_: real;
begin
  LAI_ := max(minLAI.v, LAI.v);
  if (EC.v < 50) then
    Dphen.v := 1
  else
    Dphen.v := 0;

  if (EC.v > 31) then
  begin
    if (LAI.v > 0) and (pETP.v > 0) then
    begin
      TminCO2Change.v := CO2IncreaseTcmin.v * CO2TransDiff.v;
      TmeanCO2Change.v := CO2IncreaseTcmean.v * CO2TransDiff.v;
      TmaxCO2Change.v := CO2IncreaseTcmax.v * CO2TransDiff.v;
      MeanCanopyTemp.v := Mean_Int.v + (TMPM.v * Mean_TMPM.v) +
        (Rad_Int.v * Mean_Rint.v) + (ln(LAI_) * Mean_LAI_log.v) +
        ((1 - Dphen.v) * Eact_ETP.v * Mean_Eact_ETP.v) +
        (Dphen.v * Sat_def.v * Mean_VPD.v) +
        ((1 - Dphen.v) * (Sat_def.v * TransIntRatio.v) * Mean_TransRatio_VPD.v);
    end
    else
      MeanCanopyTemp.v := TMPM.v;

    if (Dphen.v = 1) then
    begin // I
      MinCanopyTemp.v := Min_I_Int.v + Min_I_CH.v * CropHeight.v + Min_I_TMPMN.v
        * TMPMN.v;
      if (LAI.v > 0) then
      begin
        MaxCanopyTemp.v := Max_I_Int.v + Max_I_Rint.v * Rad_Int.v +
          Max_I_TMPMX.v * TMPMX.v + Max_I_LAI_log.v * ln(LAI_) +
          Max_I_TransRatio_VPD.v * TransIntRatio.v * Sat_def.v;
      end
      else
        MaxCanopyTemp.v := TMPMX.v;
    end
    else
    begin // II
      MinCanopyTemp.v := Min_II_Int.v + Min_II_VPD.v * Sat_def.v +
        Min_II_TMPMN.v * TMPMN.v + Min_II_Eact_ETP.v * Eact_ETP.v;
      if (LAI.v > 0) then
      begin
        MaxCanopyTemp.v := Max_II_Int.v + Max_II_Rint.v * Rad_Int.v +
          Max_II_TMPMX.v * TMPMX.v + Max_II_LAI_log.v * ln(LAI_) +
          Max_II_TransRatio_VPD.v * Sat_def.v * TransIntRatio.v;
      end
      else
        MaxCanopyTemp.v := TMPMX.v;
    end;
    MinCanopyTemp.v := MinCanopyTemp.v + TminCO2Change.v;
    MeanCanopyTemp.v := MeanCanopyTemp.v + TmeanCO2Change.v;
    MaxCanopyTemp.v := MaxCanopyTemp.v + TmaxCO2Change.v;
  end
  else
  begin
    MeanCanopyTemp.v := TMPM.v;
    MinCanopyTemp.v := TMPMN.v;
    MaxCanopyTemp.v := TMPMX.v
  end;

  if Opt_Tc_source.option = 'fromweatherfile' then
  begin
    if (measTcMax.v <> 0) and (measTcMean.v <> 0) and (measTcMin.v <> 0) then
    begin
      MeanCanopyTemp.v := measTcMean.v;
      MinCanopyTemp.v := measTcMin.v;
      MaxCanopyTemp.v := measTcMax.v
    end;
  end;
  if Opt_Tc_source.option = 'manipulated_with_heatring' then
  begin
    if (measTcMax.v <> 0) and (measTcMean.v <> 0) and (measTcMin.v <> 0) and
      (HeatRing_IO.v = 1) then
    begin
      MeanCanopyTemp.v := measTcMean.v;
      MinCanopyTemp.v := measTcMin.v;
      MaxCanopyTemp.v := measTcMax.v
    end;
  end;

  TDiffMean.v := max(Min(MeanCanopyTemp.v - TMPM.v, Mean_max_Delta.v),
    Mean_min_Delta.v);
  TDiffMin.v := max(Min(MinCanopyTemp.v - TMPMN.v, Min_max_Delta.v),
    Min_min_Delta.v);
  TDiffMax.v := max(Min(MaxCanopyTemp.v - TMPMX.v, Max_max_Delta.v),
    Max_min_Delta.v);

  PhenoTemp.v := TMPM.v + TDiffMean.v * fWMeanTpheno.v;
  DryMatterTemp.v := TMPM.v + TDiffMax.v * fWMeanTDrymatter.v;
  PartitioningTemp.v := TMPM.v + TDiffMean.v * fWMeanTpartitioning.v;
  EstTranspDiff.v := ActTrans.v * relCO2TransDiff.v;

end;

procedure TCropSurfaceTemp.Integrate;
var
  i: integer;
  LAI_: real;
  // LST_: real; // local sun time
begin
  inherited;
  PseudoMeanTemp.v := 0;
  for i := 1 to 24 do
  begin
    TC_Hourly[i].v := calcHourlyTemp(i - 1, MaxCanopyTemp.v, MinCanopyTemp.v);
    PseudoMeanTemp.v := PseudoMeanTemp.v + TC_Hourly[i].v;
    // LST_:=getSunTime(DayofYear.v, i, lon.v, lonCTZ.v);
    Hourly_Elevation[i].v := calcSunElevationAngle(i, DayofYear.v, lat.v);
  end;
  PseudoMeanTemp.v := PseudoMeanTemp.v / 24;
  LAI_ := max(minLAI.v, LAI.v);
  calc45AngleT(LAI_);

end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TCropSurfaceTemp]);
{$ENDIF}
end;

end.
