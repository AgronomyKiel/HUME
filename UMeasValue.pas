unit UMeasValue;
{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

{* References
  Loague, K., and R.E. Green. 1991. Statistical and graphical methods for evaluating solute transport models: overview and applications. J. Contam. Hydrol. 7:51-73.
  Gauch, H.G., J.T.G. Hwang, and G.W. Fick. 2003. Model evaluation by comparison of model-based predictions and measured values. Agronomy Journal 95:1442-1446.
  Kobayashi, K., and M.U. Salam. 2000. Comparing simulated and measured values using mean squared deviation and its components. Agronomy Journal 92:345-352.
  Kobayashi, K. 2004. Comments on another way of partitioning mean squared deviation proposed by Gauch et al. (2003). Agron J 96:1206-1207.

  @Author Henning Kage
   }

interface

uses
  classes

  {$IFNDEF NONVISUAL}
  ,vcl.Dialogs
  {$ENDIF}
  ;

type

  real = double;

  {* -----------------------------------------------------------------
    CLASS     TDataPair
    ANCESTOR  TObject
    PURPOSE   Class for Measurement values
    ------------------------------------------------------------------ }

  TDataPair = class(TObject)
  public
    Comment: string; // string for comments etc ...
    date: real; {Messzeitpunkt}
    meas: real; {Messwert}
    constructor create(dat, me, si: real; com: string); virtual;

  end;


{* -----------------------------------------------------------------
    CLASS     TMeasValue
    ANCESTOR  TDataPair
    PURPOSE   Class for Measurement values
    ------------------------------------------------------------------ }

  TMeasValue = class(TDatapair)
  public
    err: real; /// Fehler des Messwertes }
    sim: real; /// Simulationswert}
    source: string; /// which simulation run ?
    constructor create(dat, me, si: real; com: string); override;

  end;

{* -----------------------------------------------------------------
    CLASS     TMeasValue
    ANCESTOR  TDataPair
    PURPOSE   List Class for Measurement values
    ------------------------------------------------------------------ }

  TMeasList = class(TList) // derivative of TList

  private

  protected

  public
    Name: string;
    Units: string;
    actPos: integer;
    SelForOpt: boolean; ///Für Optimierung selektiert ? }
    LastDate: real;
    average_sim, /// average of simulated values
      average_meas, /// average of measured valuse
      SD_sim, /// standard deviation of simulated values
      SD_meas, /// standard deviation of measured valuse
      slope, /// slope of regression line
      se_slope, /// standard error of slope
      intercept, /// intercept of regression line
      se_intercept, /// standard error of intercept
      r2, /// r2 of linear regression
      f_value, /// f value of linear regression
      prob, /// propability of f value of linear regression
      RMSE, /// root mean squared error
      ModellingEfficiency, /// modelling efficiency
      Bias, /// average deviation
      MSD, /// sum of squared deviations
      SB, /// squared bias
      NU, /// nonunity slope (NU)
      LC, /// lack of correlation (LC)
      CD, /// coefficient of determination
      MSV, /// mean squared variation according to Kobayashi & Salam
      xsum,
      ysum,
      sq_x,
      xy_sum,
      sq_y,
      sp_xy,
      sumsqrdiff, /// sum of squared differences between regression line and measurements
      SQRest,
      SQmod,
      MQmod,
      MQrest,
      sq_xy: real;
    n: real;

    FGMod,
      FGRest,
      FGges
      : integer;

    constructor Create(n, u: string);
    function getNdata: integer;
    property ndata: integer read getndata;

    procedure WriteToFile(fileName: string);
    procedure LeastSquares; // Do the fit
    procedure Clear; override;

  end;

implementation

uses
  SysUtils, UMod;

const
  Separator = ',';

constructor TDataPair.create(dat, me, si: real; com: string);

begin
  inherited create;
  date := dat;
  meas := me;
  comment := com;
end;

constructor TmeasValue.create(dat, me, si: real; com: string);

begin
  inherited create(dat, me, si, com);
  sim := si;
  err := 1.0;
  source := '';
end;

constructor TMeasList.create(n, u: string);

begin
  inherited create;
  LastDate := 0.0;
  name := n;
  units := u;
end;

function TMeasList.GetNData;

begin
  GetNdata := self.Count;
end;

procedure TMeasList.WriteToFile(fileName: string);

var
  f: text;
  i: integer;
  Measurement: TMeasValue;
begin
  assignfile(f, FileName);
  rewrite(f);
  writeln(f, 'Zeit', Separator, name + '_sim', Separator, name + '_meas', separator, 'Source');
  writeln(f, '[d]', Separator, units, Separator, Units, separator, '[Inifile]');
  for i := 0 to count - 1 do begin
    Measurement := Items[i];
    writeln(f, floatToStrf(Measurement.Date, ffgeneral, 8, 2), Separator,
      FloatToStrF(Measurement.sim, ffgeneral, 8, 2),
      Separator, FloatToStrF(Measurement.meas, ffgeneral, 8, 2), separator, Measurement.source);
  end;
  close(f);
end;

procedure TMeasList.leastsquares;

var
  i: integer;
  ActMeas: TmeasValue;
  sq_xsum, sq_ysum: real; //  sums of squared x and y

  sq_ydiff: real;

  function betai(a, b, x: real): real;
{inverse Beta-Funktion aus Num.Recipes}

    function gammln(xx: real): real;
    const
      stp = 2.50662827465;
    var
      x, tmp, ser: double;
    begin
      x := xx - 1.0;
      tmp := x + 5.5;
      tmp := (x + 0.5) * ln(tmp) - tmp;
      ser := 1.0 + 76.18009173 / (x + 1.0) - 86.50532033 / (x + 2.0) +
        24.01409822 / (x + 3.0)
        - 1.231739516 / (x + 4.0) + 0.120858003e-2 / (x + 5.0) - 0.536382e-5 / (x
          + 6.0);
      gammln := tmp + ln(stp * ser)
    end;

    function betacf(a, b, x: real): real;

{komplementäre  Beta-Funktion aus Num.Recipes}

    label
      99;
    const
      itmax = 100;
      eps = 3.0e-7;
    var
      tem, qap, qam, qab, em, d: real;
      bz, bpp, bp, bm, az, app: real;
      am, aold, ap: real;
      m: integer;
    begin
      am := 1.0;
      bm := 1.0;
      az := 1.0;
      qab := a + b;
      qap := a + 1.0;
      qam := a - 1.0;
      bz := 1.0 - qab * x / qap;
      for m := 1 to itmax do begin
        em := m;
        tem := em + em;
        d := em * (b - m) * x / ((qam + tem) * (a + tem));
        ap := az + d * am;
        bp := bz + d * bm;
        d := -(a + em) * (qab + em) * x / ((a + tem) * (qap + tem));
        app := ap + d * az;
        bpp := bp + d * bz;
        aold := az;
        am := ap / bpp;
        bm := bp / bpp;
        az := app / bpp;
        bz := 1.0;
        if abs(az - aold) < eps * abs(az) then goto 99
      end;
      {$IFNDEF NONVISUAL}
      ShowMessage('pause in BETACF');
      {$ENDIF}
      writeln('a or b too big, or itmax too small');
      readln;
      99:
      betacf := az
    end;

  var
    bt: real;
  begin
    if (x < 0.0) or (x > 1.0) then begin
      writeln('pause in routine BETAI');
      readln
    end;
    if (x = 0.0) or (x = 1.0) then bt := 0.0
    else bt := exp(gammln(a + b) - gammln(a) - gammln(b)
        + a * ln(x) + b * ln(1.0 - x));
    if x < (a + 1.0) / (a + b + 2.0) then
      betai := bt * betacf(a, b, x) / a
    else
      betai := 1.0 - bt * betacf(b, a, 1.0 - x) / b
  end;

begin
  n := count;
  FGmod := 1;
  FGRest := count - 2;
  FGges := count - 1;
  if n > 2 then begin
    xsum := 0.0;
    ysum := 0.0;
    sq_x := 0.0;
    xy_sum := 0.0;
    sq_y := 0.0;
    sq_x := 0.0;
    sq_xsum := 0.0;
    sq_ysum := 0.0;
    sumsqrdiff := 0.0;
    sumsqrdiff := 0.0;
    Bias := 0.0;
    for i := 0 to count - 1 do begin
      ActMeas := TmeasValue(Items[i]);
      with ActMeas do begin
        if (Abs(meas) > 1e-999) and (Abs(sim) > 1e-999) then begin
          xsum := xsum + sim;
          ysum := ysum + meas;
          sq_xsum := sq_xsum + sqr(sim);
          sq_ysum := sq_ysum + sqr(meas);

          sq_y := sq_y + sqr(meas);
          sq_x := sq_x + sqr(sim);
          xy_sum := xy_sum + sim * meas;
          SumsqrDiff := SumsqrDiff + sqr(meas - sim);
          Bias := bias + (sim - meas);
        end else
          n := n - 1;
            // measurements outside the data range (zero=invalid measurement)
      end;
    end;
    sumsqrdiff := sumsqrdiff;
    bias := bias / count;
    MSV := 0.0;
    SQ_ydiff := 0.0;

    if (n >= 3) then begin // linear regression makes sense only for n>= 3
      average_sim := xsum / n;
      average_meas := ysum / n;
      sq_xy := 0.0;
      for i := 0 to count - 1 do begin
        ActMeas := TmeasValue(Items[i]);
        sq_xy := sq_xy + sqr(ActMeas.sim - average_meas);
        SQ_ydiff := SQ_ydiff + sqr(ActMeas.meas - average_meas);
        MSV := msv + sqr((ActMeas.sim - average_sim) - (ActMeas.meas -
          average_meas));
      end;
      msv := msv / count;
      if (count * sq_xsum) - sqr(xsum) > 1e-10 then
        SD_sim := sqrt(((count * sq_xsum) - sqr(xsum)) / (count * (count - 1)))
      else SD_sim := 0.0;
      if (count * sq_ysum) - sqr(ysum) > 1e-10 then
        SD_meas := sqrt(((count * sq_ysum) - sqr(ysum)) / (count * (count - 1)))
      else
        SD_meas := 0.0;

      sp_xy := xy_sum - ysum * xsum / n;

      if sq_xy <> 0 then
        CD := SQ_ydiff / sq_xy;

      sq_y := sq_y - sqr(ysum) / n;
      sq_x := sq_x - sqr(xsum) / n;
      if SQ_x <> 0 then
        sqrest := sq_y - sqr(SP_xy) / sq_x
      else
        SQrest := 0.0;
      if SQRest < 0 then SQRest := 0;

      if SQ_x <> 0 then
        SQMod := sqr(sp_xy) / sq_x
      else
        SQMod := 0.0;
      MQmod := SQmod / FGmod;

      MQrest := sqrest / (count - 2);
      if MQrest > 0 then
        f_value := MQmod / MQrest
      else f_value := 0.0;
      RMSE := {100/yavg*} sqrt(sumsqrdiff / n);
      if sq_y <> 0 then
        ModellingEfficiency := (sq_y - sumsqrdiff) / sq_y;

  {lineare Regression zwischen Modell u. Messwert }
      if (sq_x > 0.000001) and (sq_y > 0.000001) then begin
        slope := sp_xy / sq_x;
        se_slope := sqrt(mqrest / sq_x);
        intercept := (ysum - (slope * xsum)) / n;
        se_intercept := sqrt(mqrest * (1 / count + sqr(average_sim) / SQ_x));
        r2 := (sqr(sp_xy) / sq_x) / sq_y;
        MSD := sqr(RMSE);
        sb := sqr(bias); // error components according to Gauch et al.
        NU := sqr(1 - slope) * sqr(SD_meas);
          // NU: indicator of non uniform slope
        LC := (1 - r2) * sqr(SD_sim); // LC: lack of correlation

        if f_value > 0.0 then
          prob := 2.0 * betai(0.5 * FGRest, 0.5 * FGmod, FGrest / (FGrest + Fgmod
            * f_value));
        if prob > 1.0 then prob := 2.0 - prob;
      end else begin
        slope := 0.0;
        intercept := 0.0;
        r2 := 0.0;
      end;
    end;
  end;
end;

procedure TMeasList.clear;

begin
  inherited clear;
  SelForOpt := false;
  actPos := 0;
  LastDate := 1e-90;
  SumSqrdiff := 0.0;
  slope := 0.0;
  intercept := 0.0;
  r2 := 0.0;
end;

end.

