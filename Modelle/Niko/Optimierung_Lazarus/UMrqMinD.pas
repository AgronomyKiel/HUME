unit UmrqminD;

interface
uses
  Umod;

CONST
   MAxndatap =  10000;    { Maximale Zahl der Datenpunkte }
   MAxmap =     10;      { Maximale Zahl der Parameter   }

TYPE
   real = double;
   RealArrayNDATA = ARRAY [1..Maxndatap] OF real;
   RealArrayMA = ARRAY [1..MaxMap] OF real;
   PREalArrayMA = array[1..MaxMap] of ^real;
   IntegerArrayMFIT = ARRAY [1..MaxMap] OF integer;
   RealArrayMAbyMA = ARRAY [1..MaxMap,1..MaxMap] OF real;
   RealArrayMAby1 = ARRAY [1..MaxMap,1..1] OF real;
   RealArrayNPbyNP = RealArrayMAbyMA;
   RealArrayNPbyMP = RealArrayMAby1;
   RealArraybig = Array [1..MaxNDataP, 1..MaxMap] of real;
   IntegerArrayNP = IntegerArrayMFIT;

procedure mrq_fit( var Model : Tmod;
                   { Adresse der Prozedur deren Parameter zu optimieren sind }
                   {Schalter Array }
                   {Zahl der Datenpunkte bzw. der Parameter }
                   fit, protok   : boolean;
                   { Schalter fr Datei und Bildschirmausgabe }
                   fn             : string;
                   { Filename fr Ausgabe der Ergebnisse }
               var NewPar, ErrPar : RealArrayMa;
                   {Neue Parameterwerte und asympt. Fehler }
               var ChiSq          : real;
                   { Chi-Quadrat }
               var CorMat, Alpha  : RealArrayMaByMa;
                   {Korrelationmatrix und ?}
               var Yfit           : RealArrayNdata   );
                   { Funktionswerte mit opt. Parametern }


PROCEDURE mrqmin(var Model   : Tmod;
                 VAR covar,               { Kovarianzmatrix der Parameter }
                     alpha                { Curvature-Matrix }
                           : RealArrayMAbyMA;
                 VAR chisq,               { Chi-Quadrat  }
                     alambda: real;        { Schrittweite,
                                            alambda < 0 for initialisation
                                            mit alambda = 0 werden
                                            zur Ausgabe der Kovarianzmatrix
                                            und der Curvature-Matrix }
                 var yopt:REalArrayNdata);


procedure ASE ( CoVar      :  RealArrayMAbyMA;
                ndata, ma  :  integer;
                ChiSq      :  real;
                var SEa    :  RealArrayMA;
                var CorMat :  RealArrayMAbyMA);

{ Berechnung der asymptotischen Standardfehlers der Parameter
  CoVar = Covarianzmatrix
  ndata = Zahl der Datenpunkte
  ma    = Zahl der Parameter
  ChiSq = Chi-Quadrat
  SEa   = asymptotischer Standardfehler der Parameter
  CorMat= Korrelationsmatrix der Parameter }


implementation

Uses
  UMeasValue, UState, Dialogs, SysUtils;

VAR
   MrqminOchisq: real;
   MrqminBeta: RealArrayMA;


PROCEDURE covsrt(VAR covar: RealArrayMAbyMA;
                        ma: integer;
                      mfit: integer);
VAR
   j,i: integer;
BEGIN
   FOR j := 1 TO ma-1 DO
      FOR i := j+1 TO ma DO covar[i,j] := 0.0;
END;

PROCEDURE gaussj(VAR a: RealArrayNPbyNP;
                     n: integer;
                 VAR b: RealArrayNPbyMP;
                     m: integer);
VAR
   big,dum,pivinv: real;
   i,icol,irow,j,k,l,ll: integer;
   indxc,indxr,ipiv: ^IntegerArrayNP;
BEGIN
   new(indxc);
   new(indxr);
   new(ipiv);
   FOR j := 1 TO n DO ipiv^[j] := 0;
   FOR i := 1 TO n DO BEGIN
      big := 0.0;
      FOR j := 1 TO n DO
         IF ipiv^[j] <> 1 THEN
            FOR k := 1 TO n DO
               IF ipiv^[k] = 0 THEN
                  IF abs(a[j,k]) >= big THEN BEGIN
                     big := abs(a[j,k]);
                     irow := j;
                     icol := k
                  END
               ELSE IF ipiv^[k] > 1 THEN BEGIN
                  ShowMessage('pause 1 in GAUSSJ - singular matrix');
               END;
      ipiv^[icol] := ipiv^[icol]+1;
      IF irow <> icol THEN BEGIN
         FOR l := 1 TO n DO BEGIN
            dum := a[irow,l];
            a[irow,l] := a[icol,l];
            a[icol,l] := dum
         END;
         FOR l := 1 TO m DO BEGIN
            dum := b[irow,l];
            b[irow,l] := b[icol,l];
            b[icol,l] := dum
         END
      END;
      indxr^[i] := irow;
      indxc^[i] := icol;
      IF a[icol,icol] = 0.0 THEN BEGIN
         ShowMessage('pause 2 in GAUSSJ - singular matrix');
      END;
      if a[icol,icol] <> 0.0 then
        pivinv := 1.0/a[icol,icol];
      a[icol,icol] := 1.0;
      FOR l := 1 TO n DO
         a[icol,l] := a[icol,l]*pivinv;
      FOR l := 1 TO m DO
         b[icol,l] := b[icol,l]*pivinv;
      FOR ll := 1 TO n DO
         IF ll <> icol THEN BEGIN
            dum := a[ll,icol];
            a[ll,icol] := 0.0;
            FOR l := 1 TO n DO
               a[ll,l] := a[ll,l]-a[icol,l]*dum;
            FOR l := 1 TO m DO
               b[ll,l] := b[ll,l]-b[icol,l]*dum
         END
   END;
   FOR l := n DOWNTO 1 DO
      IF indxr^[l] <> indxc^[l] THEN
         FOR k := 1 TO n DO BEGIN
            dum := a[k,indxr^[l]];
            a[k,indxr^[l]] := a[k,indxc^[l]];
            a[k,indxc^[l]] := dum
         END;
   dispose(ipiv);
   dispose(indxr);
   dispose(indxc)
END;


PROCEDURE mrqmin(var Model: Tmod;
             VAR covar,          { Kovarianzmatrix der Parameter }
                 alpha:          { Curvature-Matrix }
                 RealArrayMAbyMA;
            VAR  chisq,           { Chi-Quadrat  }
            alambda: real; var yopt:realArrayNdata);       { Schrittweite,
                                   alambda < 0 for initialisation
                                   mit alambda = 0 werden
                                   zur Ausgabe der Kovarianzmatrix
                                   und der Curvature-Matrix }
LABEL 99;

VAR
   k,j: integer;
   ParSave, atry, da: RealArrayMA;
   oneda: ^RealArrayMAby1;
   nfit : integer;


PROCEDURE mrqcof2 (var Model : Tmod;
                  VAR alpha: RealArrayMAbyMA;
                  VAR beta: RealArrayMA;
                  VAR chisq: real;
                  var yopt :  RealArrayNDATA );

{ Veränderte Version }


VAR
   nfit, ndata, k,j,i: integer;
   teiler, wt, ErrVal: real;
   dyda: ^RealArrayBig;
   y, ymod, sig, sig2i,dy, yAlt: RealArrayNdata;
    ParSave, parh, dPar : RealArrayMa;
    ActPar : TPar;
    SubModName : string;
    success : boolean;

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
   nfit := model.selParlist.count;    {Zahl der Parameter bestimmen}
   ndata := model.AllMeasVal.count;   {Zahl der Datenpunkte bestimmen}

   for i := 1 to ndata do      {Übergeben der Datenpunkte an lokales Array}
     y[i] := TMeasValue(model.AllMeasVal.items[i-1]).meas;

   FOR j := 1 TO nfit DO BEGIN   {Setzen der Ableitungsmatrix auf Null }
      FOR k := 1 TO j DO alpha[j,k] := 0.0;
      beta[j] := 0.0
   END;

   chisq := 0.0;                 { Chi-Quadrat initialisieren }

   Model.run;          { 1. Modelldurchlauf }

                                 { Umsetzen der Ergebnisse }
   For I := 1 to model.AllMeasVal.Count do begin
     yalt[i] := TMeasValue(Model.AllMeasVal.Items[i-1]).sim;  { Ausgabe der optimierten Modellergebnisse }
     sig[i]  := TMeasValue(Model.AllMeasVal.Items[i-1]).err;
   end;


   yopt := yalt;   {}

   Case model.LMOptions.WeightOptions of

   OptNoWeight : begin
      for i := 1 to ndata do begin
        sig2i[i] := 1;              // ungewichtetes fitten
        dy[i] := y[i]-yalt[i];                { Differenz zwischen Messung und Simuation }
        chisq := chisq+dy[i]*dy[i];  { Aufsummieren der gewichteten Abweichungsquadrate }
      end;
    end;

   OptDefaultWeight : begin
     for i := 1 to ndata do begin
        ErrVal := y[i]*Model.LMOptions.DefaultError; // Berechnung eines fiktiven Standardfehlers
        sig2i[i] := 1.0/(Sqr(ErrVal));        { Berechnung des Wichtungsfaktors }
        dy[i] := y[i]-yalt[i];                { Differenz zwischen Messung und Simuation }
        chisq := chisq+dy[i]*dy[i]*sig2i[i];  { Aufsummieren der gewichteten Abweichungsquadrate }
     end;
   end;

   OptMeasErrorWeight : begin
     for i := 1 to ndata do begin
        sig2i[i] := 1.0/(sig[i]*sig[i]);       { Berechnung des Wichtungsfaktors }
        dy[i] := y[i]-yalt[i];                 { Differenz zwischen Messung und Simulation }
        chisq := chisq+dy[i]*dy[i]*sig2i[i];   { Aufsummieren der gewichteten Abweichungsquadrate }
     end;

     end;
   end; // Case



   for j := 1 to nfit do begin             {Beginn Schleife über Parameter }
     ActPar := Tpar(Model.SelParList.Objects[j-1]);  {Umkopieren der Parameterwerte
                                                       auf Hilfsobjekt}
     parSave[j] := ActPar.v;                         { Umschreiben in Sicherungsarray}
     dpar[j] := ActPar.v/teiler;                     { Änderung des Parameters berechnen }
     If abs(dpar[j]) < 1e-99
       then dpar[j] := 1e-8;
     ActPar.v := ActPar.v+dPar[j];                   { Neuer Parameterwert }
//     model.GetParameter(ActPar.name, ActPar, Actpar.submodname, success);
     model.ParamInifile.WriteFloat(ActPar.Submodname, ActPar.name, ActPar.V);

     Tpar(Model.SelParList.Objects[j-1]).v := ActPar.v; {Änderung des Modellparameters }

     Model.run;                 { Modelldurchlauf mit geändertem Parameter }

     For I := 1 to model.AllMeasVal.Count do
       ymod[i] := TMeasValue(Model.AllMeasVal.Items[i-1]).sim;  { Ausgabe der mit neuem Parameter
                                                                 berechneten Modellergebnisse }

     for i := 1 to ndata do
       dyda^[i, j] := (ymod[i]-yalt[i])/dpar[j];               { Schreiben der Ableitungsmatrix }

     Tpar(Model.SelParList.Objects[j-1]).v := Parsave[j];

   end;                                    {Ende Schleife über Parameter }

   {Zurücksetzen der alten Parameter}
   For J := 1 to nfit do begin
     ActPar := Tpar(Model.SelParList.Objects[j-1]);
     ActPar.v := Parsave[j];
     model.ParamInifile.WriteFloat(ActPar.Submodname, ActPar.name, ActPar.v);

   end;

   FOR i := 1 TO ndata DO BEGIN
      FOR j := 1 TO nfit DO BEGIN
         wt := dyda^[i, j]*sig2i[i];
         FOR k := 1 TO j DO
            alpha[j,k] := alpha[j,k]+wt*dyda^[i, k];
         beta[j] := beta[j]+dy[i]*wt
      END;
   END;
   FOR j := 2 TO nfit DO
      FOR k := 1 TO j-1 DO alpha[k,j] := alpha[j,k];
   dispose(dyda);

end;


BEGIN
   nfit := model.selParlist.count;

   new(oneda);
   IF alambda < 0.0 THEN BEGIN           {Ini}
      alambda := model.LMOptions.IniLambda ;
      mrqcof2(Model, alpha, MrqminBeta, chisq, yopt);
      MrqminOchisq := chisq;
      FOR j := 1 TO nfit DO
         atry[j] := TPar(Model.SelParList.Objects[j-1]).v
   END;
   FOR j := 1 TO nfit DO BEGIN
      FOR k := 1 TO nfit DO covar[j,k] := alpha[j,k];
      covar[j,j] := alpha[j,j]*(1.0+alambda);
      oneda^[j,1] := MrqminBeta[j]
   END;
   gaussj(covar,nfit,oneda^,1);
   FOR j := 1 TO nfit DO
      da[j] := oneda^[j,1];
   IF alambda = 0.0 THEN BEGIN
      covsrt(covar,nfit,nfit);
      GOTO 99
   END;
   FOR j := 1 TO nfit DO begin
      ParSave[j] := TPar(Model.SelParList.Objects[j-1]).v;
      TPar(Model.SelParList.Objects[j-1]).v := TPar(Model.SelParList.Objects[j-1]).v+da[j];
   end;
   mrqcof2 (model, covar, da, chisq, yopt);
   IF chisq < MrqminOchisq THEN BEGIN
      alambda := 0.1*alambda;
      MrqminOchisq := chisq;
      FOR j := 1 TO nfit DO BEGIN
         FOR k := 1 TO nfit DO alpha[j,k] := covar[j,k];
         MrqminBeta[j] := da[j];
      END
   END
   ELSE BEGIN
      alambda := 10.0*alambda;
      chisq := MrqminOchisq;
      FOR j := 1 TO nfit DO
        TPar(Model.SelParList.Objects[j-1]).v := ParSave[j];
   END;
99:
   dispose(oneda);
END;


procedure least_square (x, y : array of real;
                        n, npar : word;
                        chisq   : real;
                        list, protok : boolean;
                    var f : textfile;
                    var slope, intercept, r2 : real);

var
  i :integer;
  xsum, ysum, sq_x, xy_sum, sq_y, sp_xy,
  sumDiff, RMSE, ModellingEfficiency,
  SQges, SQRest, SQmod, MQmod, MQRest, Fvalue, prob : real;
  AdjRsquare : real;  // Adjusted r2
  FGges, FGMod, FGrest : integer;


FUNCTION betai(a,b,x: real): real;
{inverse Beta-Funktion aus Num.Recipes}

FUNCTION gammln(xx: real): real;
CONST
   stp  =  2.50662827465;
VAR
   x,tmp,ser: double;
BEGIN
   x := xx-1.0;
   tmp := x+5.5;
   tmp := (x+0.5)*ln(tmp)-tmp;
   ser := 1.0+76.18009173/(x+1.0)-86.50532033/(x+2.0)+24.01409822/(x+3.0)
            -1.231739516/(x+4.0)+0.120858003e-2/(x+5.0)-0.536382e-5/(x+6.0);
   gammln := tmp+ln(stp*ser)
END;

FUNCTION betacf(a,b,x: real): real;

{komplementäre  Beta-Funktion aus Num.Recipes}

LABEL 99;
CONST
   itmax = 100;
   eps = 3.0e-7;
VAR
   tem,qap,qam,qab,em,d: real;
   bz,bpp,bp,bm,az,app: real;
   am,aold,ap: real;
   m: integer;
BEGIN
   am := 1.0;
   bm := 1.0;
   az := 1.0;
   qab := a+b;
   qap := a+1.0;
   qam := a-1.0;
   bz := 1.0-qab*x/qap;
   FOR m := 1 TO itmax DO BEGIN
      em := m;
      tem := em+em;
      d := em*(b-m)*x/((qam+tem)*(a+tem));
      ap := az+d*am;
      bp := bz+d*bm;
      d := -(a+em)*(qab+em)*x/((a+tem)*(qap+tem));
      app := ap+d*az;
      bpp := bp+d*bz;
      aold := az;
      am := ap/bpp;
      bm := bp/bpp;
      az := app/bpp;
      bz := 1.0;
      IF abs(az-aold) < eps*abs(az) THEN GOTO 99
   END;
   ShowMessage('pause in BETACF');
   ShowMessage('a or b too big, or itmax too small');
99:
   betacf := az
END;


VAR
   bt: real;
BEGIN
   IF (x < 0.0) OR (x > 1.0) THEN BEGIN
      ShowMessage('pause in routine BETAI');

   END;
   IF (x = 0.0) OR (x = 1.0) THEN bt := 0.0
   ELSE bt := exp(gammln(a+b)-gammln(a)-gammln(b)
      +a*ln(x)+b*ln(1.0-x));
   IF x < (a+1.0)/(a+b+2.0) THEN
      betai := bt*betacf(a,b,x)/a
   ELSE
      betai := 1.0-bt*betacf(b,a,1.0-x)/b
END;



procedure output_1(var f : text);

begin
  writeln(f);
  writeln(f);

  writeln(f, '               Analysis of Variance ');
  writeln(f);
  writeln(f, '   Source |   FG       SSQ         MQ         F          p');
  writeln(f, '  ________ _________________________________________________');
  writeln(f, '   Model  |', FGmod:5,'  ', FloatToStrF(SQmod, ffgeneral,8,2), '  ',
                            FloatToStrF(MQmod, ffgeneral,8,2), '  ',FloatToStrF(Fvalue, ffgeneral,8,2), '  ',FloatToStrF(prob, ffGeneral,8,2));
  writeln(f, '   Error  |', FGRest:5,' ',  SQrest:10:3, ' ',MQRest:10:3);
  writeln(f, '   Total  |', FGges:5,' ',  SQges:10:3);

  writeln(f);
  writeln(f);

  writeln(f,' r2        = ',  FloatToStrf(r2, ffgeneral,8,2));
  writeln(f,' Adj. r2   = ',  FloatToStrf(Adjrsquare, ffgeneral, 8,2));
  writeln(f,' RMSE      = ',  FloatToStrf(RMSE, ffgeneral, 8,2));
  writeln(f,' EF        = ',  FloatToStrf(ModellingEfficiency, ffgeneral, 8,2));
  writeln(f);
  writeln(f);

end;

procedure output_2(var f: text);

var
  i : integer;

begin
  writeln(f);
  writeln(f);
  writeln(f,'        Analysis of Variance for linear Regression:');
  writeln(f,'       between measured (x) and simulated (y) values');
  writeln(f);
  writeln(f, '   Quelle |   FG       SSQ         MQ         F          P');
  writeln(f, '  ________ ________________________________________________');
  writeln(f, '   Model  |', FGmod:5,' ',   SQmod:10:3, ' ',MQmod:10:3, Fvalue:10:3, prob:10:6);
  writeln(f, '   Error  |', FGRest:5,' ',  SQrest:10:3, ' ',MQRest:10:3);
  writeln(f, '   Total  |', FGges:5,' ',   SQges:10:3);

  writeln(f);
  writeln(f);

  writeln(f,' r2        = ',        r2:8:4);
  writeln(f,' slope     = ',     slope:8:4);
  writeln(f,' intercept = ', intercept:8:4);

  writeln(f);
  writeln(f);

  writeln(f, 'Sim. value   Meas. value');
  for i := 0 to n-1 do
      writeln(f, floattostrf(x[i], ffgeneral, 6,2), '   ',
                 floattostrf(y[i], ffgeneral, 6,2));


end;




begin

  FGges := n-1;
  if Npar > 1 then
    FGmod := npar-1
  else
    FGmod := 1;

  FGRest:= FGges-FGmod;

  xsum := 0.0;
  ysum := 0.0;
  //sq_x := 0.0;
  xy_sum := 0.0;
  sq_y  := 0.0;
  sq_x  := 0.0;
  sumDiff := 0.0;
  //chisqalt := chisq;
  chisq := 0.0;
  for i := 0 to n-1 do begin
    chisq := chisq+sqr(x[i]-y[i]);
    xsum := xsum + x[i];
    ysum := ysum + y[i];
    sq_y := sq_y + sqr(y[i]);
    sq_x := sq_x + sqr(x[i]);
    xy_sum := xy_sum + x[i]*y[i];
    SumDiff := SumDiff+sqr(x[i]-y[i]);
  end;
  //xavg := xsum/n;
  //yavg := ysum/n;
  sp_xy := xy_sum-ysum*xsum/n;
  sq_y  := sq_y-sqr(ysum)/n;
  sq_x  := sq_x-sqr(xsum)/n;
  RMSE := {100/yavg*}sqrt(SumDiff/n);
  if sq_y <> 0 then ModellingEfficiency := (sq_y-SumDiff)/sq_y;

  SQges := SQ_y;
  SQRest := chisq;  // simply the squared sum of differences between measured and simulated values
  If (SQGes>SQRest) then begin
    SQMod  := SQges-SQRest;
//    if FGmod < 1 then FGmod := 1;
    MQmod := SQmod/FGmod;
    If FGRest < 1 then begin
      prob := 1.0;
      r2 := 1.0;
      FGRest := 1;
      exit;
    end;

    MQrest := SQrest/FGrest;
    Fvalue := MQmod/MQrest;
    R2 := SQmod/SQges;
    prob := 2.0*betai(0.5*FGRest,0.5*FGmod,FGrest/(FGrest+Fgmod*fvalue));

    IF prob > 1.0 THEN prob := 2.0-prob;
  end else begin
    prob := 1.0;
    r2 := 0.0;
    fvalue := 0.0;
    SQMOD := 0.0;
    SQRest := 0.0;
    MQRest := 0.0;
    MQMod := 0.0;
  end;

 if n-npar>0 then AdjRsquare := 1-(((n-1)*(1-r2))/(n-npar))
 else AdjRsquare :=0;
  output_1(f);


{lineare Regression zwischen Modell u. Messwert }

  FGMod := 1;                       { immer 1 !}
  FGRest:= FGges-FGmod;
  if sq_x > 0.0 then begin
    SQRest := SQ_y-sqr(sp_xy)/sq_x;   { anderer SQRest }
    SQMod := sqr(sp_xy)/sq_x;
  end
  else begin
    SQRest := 0.0;
    SQMod  := 1.0
  end;

  MQmod := SQmod/FGmod;
  if FGRest>0.0 then
    MQrest := SQrest/FGrest
  else MQRest := 0.0;
  if MQREst > 0.0 then
    Fvalue := MQmod/MQrest
  else FValue := 0.0;
  if fvalue>0.0 then
   prob := 2.0*betai(0.5*FGRest,0.5*FGmod,FGrest/(FGrest+Fgmod*fvalue));
  IF prob > 1.0 THEN prob := 2.0-prob;
  if SQ_x > 0.0 then begin
    slope := sp_xy/sq_x;
  intercept := (ysum-(slope*xsum))/n;
  r2 := (sqr(sp_xy)/sq_x)/sq_y;
  end else begin
    slope := 1.0;
    intercept := 0.0;
    r2        := 1.0;
  end;

  output_2(f);

end;



procedure ASE ( CoVar :  RealArrayMAbyMA;
                ndata, ma : integer;
                ChiSq : real;
                var SEa   : RealArrayMA;
                var CorMat :  RealArrayMAbyMA);

{ Berechnung der asymptotischen Standardfehlers der Parameter
  CoVar = Covarianzmatrix
  ndata = Zahl der Datenpunkte
  ma    = Zahl der Parameter
  ChiSq = Chi-Quadrat
  SEa   = asymptotischer Standardfehler der Parameter
  CorMat= Korrelationsmatrix der Parameter }

var
  i, j : integer;

begin

for i := 1 to ma do begin
 if (Ndata-ma) > 0 then begin
  SEa[i] := sqrt(CoVar[i,i] * ChiSq/(ndata-ma));
  //msq :=(ChiSq/(ndata-ma));
 end
 else begin
   SEa[i] := 0.0;
   //msq := 0.0;
 end;
end;

for i := 1 to ma do begin
  for j := i to ma do begin
    CorMat[i,j] := CoVar[i,j]/sqrt(CoVar[i,i]*CoVar[j,j]);
  end;
end;

end;


procedure mrq_fit( var Model      : Tmod;
                   fit, protok    : boolean;
                   fn             : string;
               var NewPar, ErrPar : RealArrayMa;
               var ChiSq          : real;
               var CorMat, Alpha  : RealArrayMaByMa;
               var Yfit           : RealArrayNdata   );


var
  i, j, iter, k         : integer;
  alambda, ochisq       : real;
  nfit, ndata           : integer;
  f                     : text;
  CoVar                 : RealArrayMabyMA;
  y                     : RealArrayNdata;
  ActPar                : TPar;
  ActSubModel           : TSubModel;


begin
  assign(f,fn);
  rewrite(f);
  writeln(f, '             Results of Optimisation ');
  writeln(f);

  Nfit := model.SelParList.Count;
  ndata := model.AllMeasVal.Count;

  alambda := -1;

  mrqmin(  Model,
           coVar,          { Kovarianzmatrix der Parameter }
           alpha,           { Curvature-Matrix }
           chisq,           { Chi-Quadrat  }
           alambda, yfit);       { Schrittweite,
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
         write(f, TPar(Model.SelParList.Objects[i-1]).name, '  ', TPar(Model.SelParList.Objects[i-1]).v:10:6, '  ');
       writeln(f,' Iteration #',k, '   Chi2 = ', chisq:6:4);
    end;
    model.StatusBarOpt.Panels.Items[2].Text := 'Iter #:'+IntToStr(k);
    model.StatusBarOpt.Panels.Items[3].Text := 'Chi2 = '+FloatToStrf(chisq,ffgeneral,6,4);
    model.StatusBarOpt.update;

    ochisq := chisq;
    inc(k);

    mrqmin( Model,
            CoVar,          { Kovarianzmatrix der Parameter }
            alpha,           { Curvature-Matrix }
            chisq,           { Chi-Quadrat  }
            alambda,yfit);       { Schrittweite,
                                   alambda < 0 for initialisation
                                   mit alambda = 0 werden
                                   zur Ausgabe der Kovarianzmatrix
                                   und der Curvature-Matrix }

  if (chisq > ochisq) then
    iter := 0

  else
    if (chisq <= 0.0) or (abs((ochisq-chisq)/chisq) < 1e-10)  then begin
    inc(iter);
  end;

  until (Iter > 2) or (k > 100);;
end;  { Ende des Fit-Blockes }

  alambda := 0.0;

  mrqmin( Model, 
        CoVar,          { Kovarianzmatrix der Parameter }
        alpha,           { Curvature-Matrix }
        chisq,           { Chi-Quadrat  }
        alambda, yfit);       { Schrittweite, }

  {NewPar := Par;}

  ASE ( CoVar ,
        ndata, Nfit,
        ChiSq,
        ErrPar,
        CorMat );

  if protok then begin
    writeln(f);
    writeln(f);
    writeln(f);
    writeln(f,'        Parameter values:    ');

    for i := 1 to Nfit do begin
       TPar(Model.SelParList.Objects[i-1]).error :=ErrPar[i];
       writeln(f, TPar(Model.SelParList.Objects[i-1]).name,'  ',floattostrf(TPar(Model.SelParList.Objects[i-1]).v, ffgeneral, 6,2),'  SE = ', floattostrf(ErrPar[i], ffgeneral, 6,2),'  ');
    end;
    writeln(f);
    writeln(f);
    writeln(f,'        Correlation matrix:');
    writeln(f);
    for i := 1 to Nfit do begin
      for j := 1 to Nfit do begin
        if j < i then write(f,'            ') else
        write(f, Cormat[i,j]:10:6,'  ');
      end;
      writeln(f);
    end;
    writeln(f);
  end;
  For I := 1 to model.AllMeasVal.Count do begin
    yfit[i] := TMeasValue(Model.AllMeasVal.Items[i-1]).sim;  { Ausgabe der mit neuem Parameter  }
    y[i] :=  TMeasValue(Model.AllMeasVal.Items[i-1]).meas;
  end;

  least_square ( yfit,  y, ndata, nfit, chisq, true, true,f,
                Model.AllMeasVal.slope, Model.AllMeasVal.intercept, Model.AllMeasVal.r2 );
  writeln(f);
  writeln(f);
  writeln(f, 'Other Parameters:');

  for i := 0 to model.SubModStrList.Count-1 do begin
    actSubModel := TSubModel(model.SubModStrList.objects[i]);
    writeln(f);
    writeln(f, ActSubModel.name);
    for J := 0 to actSubModel.ParStrList.count-1 do begin
      actPar := TPar(actSubModel.ParStrList.objects[j]);
      writeln(f, actPar.Name, ' ', floatToStrf(actpar.v, ffgeneral,6,2));
    end;

  end;

  close(f);


end;


end.  
