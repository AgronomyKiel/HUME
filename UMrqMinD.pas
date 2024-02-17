unit UmrqminD;
{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

interface
uses
  Umod;

const
  MAxndatap = 10000; { Maximale Zahl der Datenpunkte }
  MAxmap = 10; { Maximale Zahl der Parameter   }


type
  real = double;
  RealArrayNDATA = array[1..Maxndatap] of real;
  RealArrayMA = array[1..MaxMap] of real;
  PREalArrayMA = array[1..MaxMap] of ^real;
  IntegerArrayMFIT = array[1..MaxMap] of integer;
  RealArrayMAbyMA = array[1..MaxMap, 1..MaxMap] of real;
  RealArrayMAby1 = array[1..MaxMap, 1..1] of real;
  RealArrayNPbyNP = RealArrayMAbyMA;
  RealArrayNPbyMP = RealArrayMAby1;
  RealArraybig = array[1..MaxNDataP, 1..MaxMap] of real;
  IntegerArrayNP = IntegerArrayMFIT;


procedure mrq_fit(var Model: Tmod;
                   { Adresse der Prozedur deren Parameter zu optimieren sind }
                   {Schalter Array }
                   {Zahl der Datenpunkte bzw. der Parameter }
  fit, protok: boolean;
                   { Schalter fÅr Datei und Bildschirmausgabe }
  fn: string;
                   { Filename fÅr Ausgabe der Ergebnisse }
  var NewPar, ErrPar: RealArrayMa;
                   {Neue Parameterwerte und asympt. Fehler }
  var ChiSq: real;
                   { Chi-Quadrat }
  var CorMat, Alpha: RealArrayMaByMa;
                   {Korrelationmatrix und ?}
  var Yfit: RealArrayNdata //);
                   { Funktionswerte mit opt. Parametern }

 );

procedure mrqmin(var Model: Tmod;
  var covar, { Kovarianzmatrix der Parameter }
  alpha { Curvature-Matrix }
  : RealArrayMAbyMA;
  var chisq, { Chi-Quadrat  }
  alambda: real; { Schrittweite,
                                            alambda < 0 for initialisation
                                            mit alambda = 0 werden
                                            zur Ausgabe der Kovarianzmatrix
                                            und der Curvature-Matrix }
  var yopt: REalArrayNdata);

procedure ASE(CoVar: RealArrayMAbyMA;
  ndata, ma: integer;
  ChiSq: real;
  var SEa: RealArrayMA;
  var CorMat: RealArrayMAbyMA);

{ Berechnung der asymptotischen Standardfehlers der Parameter
  CoVar = Covarianzmatrix
  ndata = Zahl der Datenpunkte
  ma    = Zahl der Parameter
  ChiSq = Chi-Quadrat
  SEa   = asymptotischer Standardfehler der Parameter
  CorMat= Korrelationsmatrix der Parameter }

implementation

uses
  UMeasValue, UState,
  {$IFNDEF NONVISUAL}
   vcl.Dialogs,
  {$ENDIF}
    SysUtils;

var
  MrqminOchisq: real;
  MrqminBeta: RealArrayMA;

{------------ Anfang von PROCEDURE covsrt ---------------------------}

procedure covsrt(var covar: RealArrayMAbyMA;
  ma: integer;
  mfit: integer);
var
  j, i: integer;
begin
  for j := 1 to ma - 1 do
    for i := j + 1 to ma do covar[i, j] := 0.0;
end;

{------------ Ende von PROCEDURE covsrt ---------------------------}

{------------ Anfang von PROCEDURE gaussj -------------------------}

procedure gaussj(var a: RealArrayNPbyNP;
  n: integer;
  var b: RealArrayNPbyMP;
  m: integer);
var
  big, dum, pivinv: real;
  i, icol, irow, j, k, l, ll: integer;
  indxc, indxr, ipiv: ^IntegerArrayNP;
begin
  icol := 0;
  irow := 0;
  pivinv := 0;
  new(indxc);
  new(indxr);
  new(ipiv);
  for j := 1 to n do ipiv^[j] := 0;
  for i := 1 to n do begin
    big := 0.0;
    for j := 1 to n do
      if ipiv^[j] <> 1 then
        for k := 1 to n do
          if ipiv^[k] = 0 then
            if abs(a[j, k]) >= big then begin
              big := abs(a[j, k]);
              irow := j;
              icol := k
            end else if ipiv^[k] > 1 then begin
              //ShowMessage('pause 1 in GAUSSJ - singular matrix');
            end;
    ipiv^[icol] := ipiv^[icol] + 1;
    if irow <> icol then begin
      for l := 1 to n do begin
        dum := a[irow, l];
        a[irow, l] := a[icol, l];
        a[icol, l] := dum
      end;
      for l := 1 to m do begin
        dum := b[irow, l];
        b[irow, l] := b[icol, l];
        b[icol, l] := dum
      end
    end;
    indxr^[i] := irow;
    indxc^[i] := icol;
    if a[icol, icol] = 0.0 then begin
      //ShowMessage('pause 2 in GAUSSJ - singular matrix');
    end;
    if a[icol, icol] <> 0.0 then
      pivinv := 1.0 / a[icol, icol];
    a[icol, icol] := 1.0;
    for l := 1 to n do
      a[icol, l] := a[icol, l] * pivinv;
    for l := 1 to m do
      b[icol, l] := b[icol, l] * pivinv;
    for ll := 1 to n do
      if ll <> icol then begin
        dum := a[ll, icol];
        a[ll, icol] := 0.0;
        for l := 1 to n do
          a[ll, l] := a[ll, l] - a[icol, l] * dum;
        for l := 1 to m do
          b[ll, l] := b[ll, l] - b[icol, l] * dum
      end
  end;
  for l := n downto 1 do
    if indxr^[l] <> indxc^[l] then
      for k := 1 to n do begin
        dum := a[k, indxr^[l]];
        a[k, indxr^[l]] := a[k, indxc^[l]];
        a[k, indxc^[l]] := dum
      end;
  dispose(ipiv);
  dispose(indxr);
  dispose(indxc)
end;

{------------ Ende von PROCEDURE gaussj -------------------------}

{------------ Anfang von PROCEDURE mrqmin -------------------------}

procedure mrqmin(var Model: Tmod;
  var covar, { Kovarianzmatrix der Parameter }
  alpha: { Curvature-Matrix }
  RealArrayMAbyMA;
  var chisq, { Chi-Quadrat  }
  alambda: real; var yopt: realArrayNdata { Schrittweite,
                                   alambda < 0 for initialisation
                                   mit alambda = 0 werden
                                   zur Ausgabe der Kovarianzmatrix
                                   und der Curvature-Matrix }
                                   );
label
  99;

var
  k, j: integer;
  ParSave, atry, da: RealArrayMA;
  oneda: ^RealArrayMAby1;
  nfit: integer;

{------------ Anfang von PROCEDURE mrqcof2 -------------------------}

  procedure mrqcof2(var Model: Tmod;
    var alpha: RealArrayMAbyMA;
    var beta: RealArrayMA;
    var chisq: real;
    var yopt: RealArrayNDATA);

{ Ver‰nderte Version }

  var
    nfit, ndata, k, j, i: integer;
    teiler, wt, ErrVal: real;
    dyda: ^RealArrayBig;
    y, ymod, sig, sig2i, dy, yAlt: RealArrayNdata;
    ParSave, parh, dPar: RealArrayMa;
    ActPar: TPar;
    SubModName: string;
    success: boolean;

  begin
    for i := 1 to MaxNDataP do begin
      y[i] := 0;
      ymod[i] := 0;
      yAlt[i] := 0;
      dy[i] := 0;
      sig[i] := 0;
      sig2i[i] := 0;
    end;
    new(dyda);
    teiler := model.LMOptions.Divisor;
    model.CalcChiSq;
    nfit := model.selParlist.count; {Zahl der Parameter bestimmen}
    ndata := model.AllMeasVal.count; {Zahl der Datenpunkte bestimmen}

    for i := 1 to ndata do {‹bergeben der Datenpunkte an lokales Array}
      y[i] := TMeasValue(model.AllMeasVal.items[i - 1]).meas;

    for j := 1 to nfit do begin {Setzen der Ableitungsmatrix auf Null }
      for k := 1 to j do alpha[j, k] := 0.0;
      beta[j] := 0.0
    end;

    chisq := 0.0; { Chi-Quadrat initialisieren }

    //Model.run; { 1. Modelldurchlauf }

    if model.LMOptions.OptOption = optAllInis then
      model.run
    else if model.LMOptions.OptOption = optOnlyActIni then
      model.runActINI;


                                 { Umsetzen der Ergebnisse }
    for I := 1 to model.AllMeasVal.Count do begin
      yalt[i] := TMeasValue(Model.AllMeasVal.Items[i - 1]).sim;
        { Ausgabe der optimierten Modellergebnisse }
      sig[i] := TMeasValue(Model.AllMeasVal.Items[i - 1]).err;
    end;

    yopt := yalt; {}

    case model.LMOptions.WeightOptions of

      OptNoWeight: begin
          for i := 1 to ndata do begin
            sig2i[i] := 1; // ungewichtetes fitten
            dy[i] := y[i] - yalt[i]; { Differenz zwischen Messung und Simuation }
            chisq := chisq + dy[i] * dy[i];
              { Aufsummieren der gewichteten Abweichungsquadrate }
          end;
        end;

      OptDefaultWeight: begin
          for i := 1 to ndata do begin
            ErrVal := y[i] * Model.LMOptions.DefaultError;
              // Berechnung eines fiktiven Standardfehlers
            sig2i[i] := 1.0 / (Sqr(ErrVal)); { Berechnung des Wichtungsfaktors }
            dy[i] := y[i] - yalt[i]; { Differenz zwischen Messung und Simuation }
            chisq := chisq + dy[i] * dy[i] * sig2i[i];
              { Aufsummieren der gewichteten Abweichungsquadrate }
          end;
        end;

      OptMeasErrorWeight: begin
          for i := 1 to ndata do begin
            sig2i[i] := 1.0 / (sig[i] * sig[i]);
              { Berechnung des Wichtungsfaktors }
            dy[i] := y[i] - yalt[i];
              { Differenz zwischen Messung und Simulation }
            chisq := chisq + dy[i] * dy[i] * sig2i[i];
              { Aufsummieren der gewichteten Abweichungsquadrate }
          end;

        end;
    end; // Case

    for j := 1 to nfit do begin {Beginn Schleife ¸ber Parameter }
      ActPar := Tpar(Model.SelParList.Objects[j - 1]);
        {Umkopieren der Parameterwerte auf Hilfsobjekt}
      parSave[j] := ActPar.v; { Umschreiben in Sicherungsarray}
      dpar[j] := ActPar.v / teiler; { ƒnderung des Parameters berechnen }
      if abs(dpar[j]) < 1e-99 then dpar[j] := 1e-8;
      ActPar.v := ActPar.v + dPar[j]; { Neuer Parameterwert }
//     model.GetParameter(ActPar.name, ActPar, Actpar.submodname, success);
// hk 10.6.16 added because in some cases the init sequence is necessary for parameter
// changes to take effect
      model.ParamInifile.WriteFloat(ActPar.Submodname, ActPar.name, ActPar.V);
      model.ParamInifile.UpdateFile;

      Tpar(Model.SelParList.Objects[j - 1]).v := ActPar.v;
        {ƒnderung des Modellparameters }

      //Model.run; { Modelldurchlauf mit ge‰ndertem Parameter }
       if model.LMOptions.OptOption = optAllInis then
         model.run
       else if model.LMOptions.OptOption = optOnlyActIni then
         model.runActINI;


      for I := 1 to model.AllMeasVal.Count do
        ymod[i] := TMeasValue(Model.AllMeasVal.Items[i - 1]).sim;
          { Ausgabe der mit neuem Parameter
                                                                 berechneten Modellergebnisse }

      for i := 1 to ndata do
        dyda^[i, j] := (ymod[i] - yalt[i]) / dpar[j];
          { Schreiben der Ableitungsmatrix }

      Tpar(Model.SelParList.Objects[j - 1]).v := Parsave[j];

    end; {Ende Schleife ¸ber Parameter }


    for i := 1 to ndata do begin
      for j := 1 to nfit do begin
        wt := dyda^[i, j] * sig2i[i];
        for k := 1 to j do
          alpha[j, k] := alpha[j, k] + wt * dyda^[i, k];
        beta[j] := beta[j] + dy[i] * wt
      end;
    end;
    for j := 2 to nfit do
      for k := 1 to j - 1 do alpha[k, j] := alpha[j, k];
    dispose(dyda);


  end;

{------------ Ende von PROCEDURE mrqcof2 -------------------------}

begin
  nfit := model.selParlist.count;

  new(oneda);
  if alambda < 0.0 then begin {Ini}
    alambda := model.LMOptions.IniLambda;
    mrqcof2(Model, alpha, MrqminBeta, chisq, yopt);
    MrqminOchisq := chisq;
    for j := 1 to nfit do
      atry[j] := TPar(Model.SelParList.Objects[j - 1]).v
  end;
  for j := 1 to nfit do begin
    for k := 1 to nfit do covar[j, k] := alpha[j, k];
    covar[j, j] := alpha[j, j] * (1.0 + alambda);
    oneda^[j, 1] := MrqminBeta[j]
  end;
  gaussj(covar, nfit, oneda^, 1);
  for j := 1 to nfit do
    da[j] := oneda^[j, 1];
  if alambda = 0.0 then begin
    covsrt(covar, nfit, nfit);
    goto 99
  end;
  for j := 1 to nfit do begin
    ParSave[j] := TPar(Model.SelParList.Objects[j - 1]).v;
    TPar(Model.SelParList.Objects[j - 1]).v := TPar(Model.SelParList.Objects[j -
      1]).v + da[j];
    If TPar(Model.SelParList.Objects[j - 1]).v <  TPar(Model.SelParList.Objects[j - 1]).min then
       TPar(Model.SelParList.Objects[j - 1]).v := TPar(Model.SelParList.Objects[j - 1]).min;
  end;
  mrqcof2(model, covar, da, chisq, yopt);
  if chisq < MrqminOchisq then begin
    alambda := 0.1 * alambda;
    MrqminOchisq := chisq;
    for j := 1 to nfit do begin
      for k := 1 to nfit do alpha[j, k] := covar[j, k];
      MrqminBeta[j] := da[j];
    end
  end else begin
    alambda := 10.0 * alambda;
    chisq := MrqminOchisq;
    for j := 1 to nfit do
      TPar(Model.SelParList.Objects[j - 1]).v := ParSave[j];
  end;
  99:
  dispose(oneda);
end;

{--------------- Ende von PROCEDURE mrqmin --------------------------}

{------------ Anfang von PROCEDURE least_squar -----------------------}

procedure least_square(x, y: array of real;
  n, npar: word;
  chisq: real;
  list, protok: boolean;
  var f: textfile;
  var slope, intercept, r2: real);

var
  i: integer;
  xsum, ysum, sq_x, xy_sum, sq_y, sp_xy,
    sumDiff, RMSE, ModellingEfficiency,
    SQges, SQRest, SQmod, MQmod, MQRest, Fvalue, prob: real;
  AdjRsquare: real; // Adjusted r2
  FGges, FGMod, FGrest: integer;

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

{komplement‰re  Beta-Funktion aus Num.Recipes}

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
      ShowMessage('a or b too big, or itmax too small');
{$ENDIF}

      99:
      betacf := az
    end;

  var
    bt: real;
  begin
    if (x < 0.0) or (x > 1.0) then begin
{$IFNDEF NONVISUAL}
      ShowMessage('pause in routine BETAI');
{$ENDIF}
    end;
    if (x = 0.0) or (x = 1.0) then bt := 0.0
    else bt := exp(gammln(a + b) - gammln(a) - gammln(b)
        + a * ln(x) + b * ln(1.0 - x));
    if x < (a + 1.0) / (a + b + 2.0) then
      betai := bt * betacf(a, b, x) / a
    else
      betai := 1.0 - bt * betacf(b, a, 1.0 - x) / b
  end;

  procedure output_1(var f: text);

  begin
    writeln(f);
    writeln(f);

    writeln(f, '               Analysis of Variance ');
    writeln(f);
    writeln(f, '   Source |   FG       SSQ         MQ         F          p');
    writeln(f, '  ________ _________________________________________________');
    writeln(f, '   Model  |', FGmod: 5, '  ', FloatToStrF(SQmod, ffgeneral, 8,
      2), '  ',
      FloatToStrF(MQmod, ffgeneral, 8, 2), '  ', FloatToStrF(Fvalue, ffgeneral,
        8, 2), '  ', FloatToStrF(prob, ffGeneral, 8, 2));
    writeln(f, '   Error  |', FGRest: 5, ' ', SQrest: 10: 3, ' ', MQRest: 10:
      3);
    writeln(f, '   Total  |', FGges: 5, ' ', SQges: 10: 3);

    writeln(f);
    writeln(f);

    writeln(f, ' r2        = ', FloatToStrf(r2, ffgeneral, 8, 2));
    writeln(f, ' Adj. r2   = ', FloatToStrf(Adjrsquare, ffgeneral, 8, 2));
    writeln(f, ' RMSE      = ', FloatToStrf(RMSE, ffgeneral, 8, 2));
    writeln(f, ' EF        = ', FloatToStrf(ModellingEfficiency, ffgeneral, 8,
      2));
    writeln(f);
    writeln(f);

  end;

  procedure output_2(var f: text);

  var
    i: integer;

  begin
    writeln(f);
    writeln(f);
    writeln(f, '        Analysis of Variance for linear Regression:');
    writeln(f, '       between measured (x) and simulated (y) values');
    writeln(f);
    writeln(f, '   Quelle |   FG       SSQ         MQ         F          P');
    writeln(f, '  ________ ________________________________________________');
    writeln(f, '   Model  |', FGmod: 5, ' ', SQmod: 10: 3, ' ', MQmod: 10: 3,
      Fvalue: 10: 3, prob: 10: 6);
    writeln(f, '   Error  |', FGRest: 5, ' ', SQrest: 10: 3, ' ', MQRest: 10:
      3);
    writeln(f, '   Total  |', FGges: 5, ' ', SQges: 10: 3);

    writeln(f);
    writeln(f);

    writeln(f, ' r2        = ', r2: 8: 4);
    writeln(f, ' slope     = ', slope: 8: 4);
    writeln(f, ' intercept = ', intercept: 8: 4);

    writeln(f);
    writeln(f);

    writeln(f, 'Sim. value   Meas. value');
    for i := 0 to n - 1 do
      writeln(f, floattostrf(x[i], ffgeneral, 6, 2), '   ',
        floattostrf(y[i], ffgeneral, 6, 2));

  end;

begin
  if n > 0 then begin

  FGges := n - 1;
  if Npar > 1 then
    FGmod := npar - 1
  else
    FGmod := 1;

  FGRest := FGges - FGmod;

  xsum := 0.0;
  ysum := 0.0;
  //sq_x := 0.0;
  xy_sum := 0.0;
  sq_y := 0.0;
  sq_x := 0.0;
  sumDiff := 0.0;
  //chisqalt := chisq;
  chisq := 0.0;
  for i := 0 to n - 1 do begin
    chisq := chisq + sqr(x[i] - y[i]);
    xsum := xsum + x[i];
    ysum := ysum + y[i];
    sq_y := sq_y + sqr(y[i]);
    sq_x := sq_x + sqr(x[i]);
    xy_sum := xy_sum + x[i] * y[i];
    SumDiff := SumDiff + sqr(x[i] - y[i]);
  end;
  //xavg := xsum/n;
  //yavg := ysum/n;

  sp_xy := xy_sum - ysum * xsum / n;
  sq_y := sq_y - sqr(ysum) / n;
  sq_x := sq_x - sqr(xsum) / n;
  RMSE := {100/yavg*} sqrt(SumDiff / n);
  if sq_y <> 0 then ModellingEfficiency := (sq_y - SumDiff) / sq_y;

  SQges := SQ_y;
  SQRest := chisq;
    // simply the squared sum of differences between measured and simulated values
  if (SQGes > SQRest) then begin
    SQMod := SQges - SQRest;
//    if FGmod < 1 then FGmod := 1;
    MQmod := SQmod / FGmod;
    if FGRest < 1 then begin
      prob := 1.0;
      r2 := 1.0;
      FGRest := 1;
      exit;
    end;

    MQrest := SQrest / FGrest;
    Fvalue := MQmod / MQrest;
    R2 := SQmod / SQges;
    prob := 2.0 * betai(0.5 * FGRest, 0.5 * FGmod, FGrest / (FGrest + Fgmod *
      fvalue));

    if prob > 1.0 then prob := 2.0 - prob;
  end else begin
    prob := 1.0;
    r2 := 0.0;
    fvalue := 0.0;
    SQMOD := 0.0;
    SQRest := 0.0;
    MQRest := 0.0;
    MQMod := 0.0;
  end;

  if n - npar > 0 then AdjRsquare := 1 - (((n - 1) * (1 - r2)) / (n - npar))
  else AdjRsquare := 0;
  output_1(f);

{lineare Regression zwischen Modell u. Messwert }

  FGMod := 1; { immer 1 !}
  FGRest := FGges - FGmod;
  if sq_x > 0.0 then begin
    SQRest := SQ_y - sqr(sp_xy) / sq_x; { anderer SQRest }
    SQMod := sqr(sp_xy) / sq_x;
  end else begin
    SQRest := 0.0;
    SQMod := 1.0
  end;

  MQmod := SQmod / FGmod;
  if FGRest > 0.0 then
    MQrest := SQrest / FGrest
  else MQRest := 0.0;
  if MQREst > 0.0 then
    Fvalue := MQmod / MQrest
  else FValue := 0.0;
  if fvalue > 0.0 then
    prob := 2.0 * betai(0.5 * FGRest, 0.5 * FGmod, FGrest / (FGrest + Fgmod *
      fvalue));
  if prob > 1.0 then prob := 2.0 - prob;
  if SQ_x > 0.0 then begin
    slope := sp_xy / sq_x;
    intercept := (ysum - (slope * xsum)) / n;
    r2 := (sqr(sp_xy) / sq_x) / sq_y;
  end else begin
    slope := 1.0;
    intercept := 0.0;
    r2 := 1.0;
  end;

  output_2(f);
  end else
{$IFNDEF NONVISUAL}
    showmessage('No Data');
{$ENDIF}


end;

{------------ Ende von PROCEDURE least_square -------------------------}

procedure ASE(CoVar: RealArrayMAbyMA;
  ndata, ma: integer;
  ChiSq: real;
  var SEa: RealArrayMA;
  var CorMat: RealArrayMAbyMA);

{ Berechnung der asymptotischen Standardfehlers der Parameter
  CoVar = Covarianzmatrix
  ndata = Zahl der Datenpunkte
  ma    = Zahl der Parameter
  ChiSq = Chi-Quadrat
  SEa   = asymptotischer Standardfehler der Parameter
  CorMat= Korrelationsmatrix der Parameter }

var
  i, j: integer;

begin

  for i := 1 to ma do begin
    if (Ndata - ma) > 0 then begin
      SEa[i] := sqrt(CoVar[i, i] * ChiSq / (ndata - ma));
  //msq :=(ChiSq/(ndata-ma));
    end else begin
      SEa[i] := 0.0;
   //msq := 0.0;
    end;
  end;

  for i := 1 to ma do begin
    for j := i to ma do begin
      if (CoVar[i, i] * CoVar[j, j]) <= 0 then CorMat[i, j] := 1
      else CorMat[i, j] := CoVar[i, j] / sqrt(CoVar[i, i] * CoVar[j, j]);
    end;
  end;

end;

procedure mrq_fit(var Model: Tmod;
  fit, protok: boolean;
  fn: string;
  var NewPar, ErrPar: RealArrayMa;
  var ChiSq: real;
  var CorMat, Alpha: RealArrayMaByMa;
  var Yfit: RealArrayNdata);

var
  i, j, iter, k: integer;
  alambda, ochisq: real;
  nfit, ndata: integer;
  f: text;
  CoVar: RealArrayMabyMA;
  y: RealArrayNdata;
  ActPar: TPar;
  ActSubModel: TSubModel;
  //Par_Save : array[1..100] of real;

begin
  Nfit := model.SelParList.Count;
  ndata := model.AllMeasVal.Count;

  assign(f, fn);
  rewrite(f);
  writeln(f, '             Results of Optimisation ');
  writeln(f);


  alambda := -1;

  mrqmin(Model,
    coVar, { Kovarianzmatrix der Parameter }
    alpha, { Curvature-Matrix }
    chisq, { Chi-Quadrat  }
    alambda, yfit); { Schrittweite,
                                   alambda < 0 for initialisation
                                   mit alambda = 0 werden
                                   zur Ausgabe der Kovarianzmatrix
                                   und der Curvature-Matrix }

  {chisq := 0.0;}
  Iter := 0;
  k := 1;
  if fit then begin
    repeat
      if protok then begin
        for i := 1 to Nfit do
          write(f, TPar(Model.SelParList.Objects[i - 1]).name, '  ',
            TPar(Model.SelParList.Objects[i - 1]).v: 10: 6, '  ');
        writeln(f, ' Iteration #', k, '   Chi2 = ', chisq: 6: 4);
      end;
{$IFNDEF NONVISUAL}
      model.StatusBarOpt.Panels.Items[2].Text := 'Iter #:' + IntToStr(k);
      model.StatusBarOpt.Panels.Items[3].Text := 'Chi2 = ' + FloatToStrf(chisq,
        ffgeneral, 6, 4);
      model.StatusBarOpt.update;
{$ENDIF}
      ochisq := chisq;
      inc(k);

      mrqmin(Model,
        CoVar, { Kovarianzmatrix der Parameter }
        alpha, { Curvature-Matrix }
        chisq, { Chi-Quadrat  }
        alambda, yfit); { Schrittweite,
                                   alambda < 0 for initialisation
                                   mit alambda = 0 werden
                                   zur Ausgabe der Kovarianzmatrix
                                   und der Curvature-Matrix }

      if (chisq > ochisq) then
        iter := 0

      else
        if (chisq <= 0.0) or (abs((ochisq - chisq) / chisq) < 1e-10) then begin
        inc(iter);
      end;

    until (Iter > 2) or (k > 100); ;
  end; { Ende des Fit-Blockes }

  alambda := 0.0;

  mrqmin(Model,
    CoVar, { Kovarianzmatrix der Parameter }
    alpha, { Curvature-Matrix }
    chisq, { Chi-Quadrat  }
    alambda, yfit); { Schrittweite, }

  {NewPar := Par;}

  ASE(CoVar,
    ndata, Nfit,
    ChiSq,
    ErrPar,
    CorMat);

  if protok then begin
    writeln(f);
    writeln(f);
    writeln(f);
    writeln(f, '        Parameter values:    ');

    for i := 1 to Nfit do begin
      TPar(Model.SelParList.Objects[i - 1]).error := ErrPar[i];
      writeln(f, TPar(Model.SelParList.Objects[i - 1]).name, '  ',
        floattostrf(TPar(Model.SelParList.Objects[i - 1]).v, ffgeneral, 6, 2),
        '  SE = ', floattostrf(ErrPar[i], ffgeneral, 6, 2), '  ');
    end;
    writeln(f);
    writeln(f);
    writeln(f, '        Correlation matrix:');
    writeln(f);
    for i := 1 to Nfit do begin
      for j := 1 to Nfit do begin
        if j < i then write(f, '            ') else
          write(f, Cormat[i, j]: 10: 6, '  ');
      end;
      writeln(f);
    end;
    writeln(f);
  end;
  for I := 1 to model.AllMeasVal.Count do begin
    yfit[i] := TMeasValue(Model.AllMeasVal.Items[i - 1]).sim;
      { Ausgabe der mit neuem Parameter  }
    y[i] := TMeasValue(Model.AllMeasVal.Items[i - 1]).meas;
  end;

  least_square(yfit, y, ndata, nfit, chisq, true, true, f,
    Model.AllMeasVal.slope, Model.AllMeasVal.intercept, Model.AllMeasVal.r2);
  writeln(f);
  writeln(f);
  writeln(f, 'Other Parameters:');

  for i := 0 to model.SubModStrList.Count - 1 do begin
    actSubModel := TSubModel(model.SubModStrList.objects[i]);
    writeln(f);
    writeln(f, ActSubModel.name);
    for J := 0 to actSubModel.ParStrList.count - 1 do begin
      actPar := TPar(actSubModel.ParStrList.objects[j]);
      writeln(f, actPar.Name, ' ', floatToStrf(actpar.v, ffgeneral, 6, 2));
    end;

  end;

  close(f);

     {Zur¸ckschreiben der alten Parameter }
 { for J := 1 to nfit do begin
    ActPar := Tpar(Model.SelParList.Objects[j - 1]);
    ActPar.SelForOpt := false;
    ActPar.v := Par_save[j];
    model.ParamInifile.WriteFloat(ActPar.Submodname, ActPar.name, ActPar.v);
    model.ParamIniFile.UpdateFile;
    ActPar.SelForOpt := true;
  end;   }


end;

{------------ Ende von PROCEDURE mrqfit -------------------------}

end.

