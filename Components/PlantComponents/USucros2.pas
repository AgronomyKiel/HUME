unit USucros2;

interface

uses
  UState, IniFiles, UMod , Classes, UDryMatProdComp;

type
  real = double;
  TPmax_f = (Pmax_const, Pmax_fI);

CONST

  RAD = pi/180.0;
  SCV = 0.2;   // Scattering coefficient of leaves for visible radiation (PAR)

  max_tab = 12;     { maximale Anzahl der Zahlen in einer Interpolations-
                      tabelle }
//  n_gauss = 3;
  n_gauss = 5;

type
  gauss_arr = array[1..n_gauss] of real;

const

//  XGAUSS : gauss_arr = (0.1127, 0.5,    0.8873);
//  WGAUSS : gauss_arr = (0.2778, 0.4444, 0.2778);
  XGAUSS : gauss_arr = (0.0469101, 0.2307534, 0.5, 0.7692465, 0.9530899);
  WGAUSS : gauss_arr = (0.1184635, 0.2393144, 0.2844444, 0.2393144, 0.1184635);

type
  table_arr = array[1..max_tab] of real;


TSucrosTotDry = Class(TDrymatterProduction)

private

protected

public
     alpha           : TPar;
     Pmax            : Tpar;
     CVE             : TPar;
     LAT             : TPar;
     I_av            : TVar;
     fabs            : TVar;
     keff            : Tvar;
     PARin           : TVar;
     Pmax_f : TPmax_f;

   procedure createAll; override;
   procedure CalcRates; override;


   private

   public

   published

   property OptPmax_f : TPmax_f read Pmax_f write Pmax_f;
   property Par_Pmax : TPar read Pmax  write Pmax;
   property Par_alpha : TPar read alpha write alpha;
   property PAR_CVE : TPar read CVE write CVE;
   property PAR_LAT : TPar read LAT write LAT;
   property Var_fabs : Tvar read fabs write fabs;

 end;


var
  pardr,
  pardf,
  sinb  : gauss_arr;

  dayl  : real;


{ ************************************************************************* }

PROCEDURE ASTRO (day,
                 lat,
                 avrad
                      : real;
             var sinb,
                 pardf,
                 pardr : gauss_arr;
             var dayl  : real    );


{ ************************************************************************* }
{**********************************************************************
*                                                                     *
*                         procedure ASTRO                             *
*                        ================                             *
*                                                                     *
*  Autor   : Daniel van Kraalingen (9-AUG-1987)                       *
*            modifiziert: Jan Goudriaan (4-FEB-1988)                  *
*                                                                     *
*  Zweck   : Mit dieser Subroutine wird die astronomische und die     *
*            photoperiodische Tageslaenge berechnet. Weiterhin        *
*            werden charakteristische Werte der taeglichen Strah-     *
*            lung wie Tagesintegral der Sonneneinstrahlungswinkel     *
*            und Solarkonstante verwendet. Aus der gemessenen         *
*            taeglichen Globalstrahlung wird die atmosphaerische      *
*            Transmission und der Anteil diffuser Strahlung           *
*            ermittelt.                                               *
*                                                                     *
***********************************************************************



**********************************************************************
*                                                                    *
*  Parameter und Variable                                            *
*                                                                    *
*  Name     Bedeutung                            Einheit    Klasse   *
*                                                                    *
*  ANGOT    In Abhaengigkeit von den Einstrah-                       *
*           lungswinkeln korrigierte Solar-                          *
*           konstante (Tagessumme)               J m-2 d-1     O     *
*  ATMTR    Lichttransmissionskoeffizient der                        *
*           Atmosphaere                              -         O     *
*  AVRAD    gemessene taegliche Globalstrahlung  J m-2 d-1     I     *
*  COSLD    Amplitudes des Verlaufs der Sonnen-                      *
*           einstrahlungswinkel                      -         O     *
*  DAY      Tagesnummer (1. 1. = 1)                  -         I     *
*  DAYL     Astronomische Tageslaenge (0 Grad)       h         O     *
*  DAYLP    Photoperiodische Tageslaenge (-4 Grad)   h         O     *
*  DEC      Deklination                              -         O     *
*  DSINB    Integral der taeglichen Einstrah-                        *
*           lungswinkel                              s         O     *
*  DSINBE   Integral der effektiven taeglichen                       *
*           Einstrahlungswinkel                      s         O     *
*  FRDIF    Anteil diffuser Strahlung an der                         *
*           Globalstrahlung (mehr als Durchschnitt)  -         O     *
*  LAT      Breitengrad des Ortes                                    *
*           Gueltigkeitsbereich: +/- 67 Grad        Grad       I     *
*  SC       Solarkonstante                       J m-2 d-1     P     *
*  SINLD    Saisonale Veraenderung des Einstrah-                     *
*           lungswinkels der Sonne                   -         O     *
*  ----------                                                        *
*  Klasse:  I=Input, O=Output, C=Kontrolle, P=Parameter, T=Zeit      *
*                                                                    *
*  keine weiteren Subroutinen oder Funktionen werden aufgerufen      *
*                                                                    *
**********************************************************************}



{ ************************************************************************* }
PROCEDURE ASSIM (sinb,
                 pardf,
                 pardr  : gauss_arr;
                 Pmax0,
                 eff,
                 lai,
                 dayl  : real;
                 Pmax_f : TPmax_f;
             var gphot, PARabs : real);


{ ************************************************************************* }

{*********************************************************************
*                                                                    *
*                        procedure ASSIM                             *
*                        =================                           *
*                                                                    *
*  Autor   :                   (10-DEC-1987)                         *
*                                                                    *
*  Zweck   : Mit dieser Subroutine wird die taegliche Bruttophoto-   *
*            synthese berechnet. Dazu wird das Gauss-Integrations-   *
*            verfahren eingesetzt, d. h. es wird an drei verschie-   *
*            denen Zeitpunkten im Tagesverlauf die Strahlung be-     *
*            rechnet, daraus die Assimilation bestimmt und an-       *
*            schliessend integriert.                                 *
*                                                                    *
**********************************************************************



**********************************************************************
*                                                                    *
*  Parameter und Variable                                            *
*                                                                    *
*  Name     Bedeutung                            Einheit    Klasse   *
*                                                                    *
*  ATMTR    Lichttransmissionskoeffizient der                        *
*           Atmosphaere                              -         I     *
*  AVRAD    gemessene taegliche Globalstrahlung  J m-2 d-1     I     *
*  COSLD    Amplitude des Verlaufs der                               *
*           Sonneneinstrahlungswinkel                -         I     *
*  DAYL     Astronomische Tageslaenge (0 Grad)       h         I     *
*  DPARDF   Tagessumme der diffusen PAR im                           *
*           Gewaechshaus                         J m-2 d-1     O     *
*  DPARDR   Tagessumme der direkten PAR im                           *
*                                                J m-2 d-1     O     *
*  DSINBE   Integral der effektiven taeglichen                       *
*           Einstrahlungswinkel                      s         I     *
*  DTGA     Taegliche Brutto-CO2-Assimilation   g CO2 m-2 d-1  O     *
*  EFF      initial light use efficiency           g CO2 J-1   I     *
*  FGMAX    Bruttophotosynthese bei Licht-                           *
*           saettigung                          g CO2 m-2 s-1  I     *
*  FRDIF    Anteil diffuser Strahlung an der                         *
*           Globalstrahlung                          -         I     *
*  GPHOT    Bruttophotosynthese (Kohlenhydrate) g CH2O m-2 d-1 O     *
*  KDIF     Extinktionskoeffizient fuer                              *
*           diffuses Licht                           -         I     *
*  LAI      Blattflaechenindex                     m2 m-2      I     *
*  SCV      Streuungskoeffizient (fuer PAR)          -         I     *
*  SINB     Sinus des Sonneneinstrahlungswinkels     -         I     *
*  SINLD    Saisonale Veraenderung des Einstrah-                     *
*           lungswinkels der Sonne                   -         I     *
*  PAR      photosynthetisch aktive Strahlung                        *
*           (400-700 nm)                            W m-2      O     *
*  PARDF    diffuse PAR                             W m-2      O     *
*  PARDIF   diffuser PAR-Flux                       W m-2      O     *
*  PARDIR   direkter PAR-Flux                       W m-2      O     *
*  PARDR    direkte PAR                             W m-2      O     *
*  ----------                                                        *
*  Klasse: I=Input, O=Output, C=Kontrolle, P=Parameter, T=Zeit       *
*                                                                    *
*                                                                    *
**********************************************************************}


{************************************************************************ }

PROCEDURE TABF (table : table_arr;
                Iltab : integer;
                x     : real;
                var y : real);
{ ************************************************************************* }

{**********************************************************************
*                                                                    *
*                        Tabellenfunktion                            *
*                        ================                            *
*                                                                    *
*  Autor  : veraendert nach Daniel van Kraalingen                    *
*                                                                    *
*  Datum  : 28-NOV-1989                                              *
*                                                                    *
*  Zweck  : Lineare Interpolationsfunktion ohne Extrapolation        *
*                                                                    *
**********************************************************************


**********************************************************************
*                                                                    *
*  Variablen                                                         *
*                                                                    *
*  Name     Bedeutung                            Einheit    Klasse   *
*                                                                    *
*  ILTAB    Anzahl der Elemente der Tabelle         -          I     *
*  TABLE    eindimensionales Feld mit                                *
*           paarweisen Daten: x,y, x,y tec.         -          I     *
*  X        Wert der Abszisse fuer den inter-                        *
*           poliert werden soll                     -          I     *
*  Y        interpolierter Ordinatenwert            -          O     *
*  ----------                                                        *
*  Klasse: I=Input, O=Output, C=Kontrolle, IN=Anfangswert, T=Zeit    *
*                                                                    *
*  keine weiteren Subroutinen oder Funktionen werden aufgerufen      *
*                                                                    *
**********************************************************************}

procedure DAYLength(Day: integer; LAT: real;
                     Var DayL , DayLP : real );


procedure register;


implementation

uses
  Math, Dialogs;

procedure DAYLength(Day: integer; LAT: real;
                  var DayL , DayLP : real );


var
  x,
  Dec,
  SinLd,
  CosLd,
  AOB   : real;

BEGIN  { Procedure DAYLlength }

{  Pruefung des Gueltigkeitsbereichs  }

  IF LAT > 67. THEN BEGIN
    WRITELN(' Fehler in Dailength: LAT > 67');
    HALT;
  END;

  IF LAT < -67. THEN BEGIN
     ShowMessage(' Fehler in ASTRO: LAT <-67');
     HALT;
  END;

{ Deklination der Sonne als Funktion der Jahreszeit (DAY) }

   X:= arcsin(SIN(23.45*RAD)*COS(2.*PI*(DAY+10)/365));
   DEC:=X*-1;

{ Zwischenwerte SINLD, COSLD und AOB }

   SINLD:=SIN(RAD*LAT)*SIN(DEC);
   COSLD:=COS(RAD*LAT)*COS(DEC);
   AOB:=  SINLD/COSLD;

{Tageslaenge (DAYL) und photoperiodische Tageslaenge (DAYLP) }

   X:=ARCSIN(AOB);
   DAYL:= 12.0*(1+2*X/PI);
   X:=arcsin((-SIN(-4*RAD)+SINLD)/COSLD);
   DAYLP:=12.0*(1+2*X/PI);
end;


{ ************************************************************************* }

PROCEDURE ASTRO (day,
                 lat,
                 avrad
                        : real;
                 var sinb,
                     pardf,
                     pardr : gauss_arr;
                 var dayl  : real    );

{ ************************************************************************* }





VAR
  ANGOT,                 { Angots-value [W/m2]}
  atmtr,                 { atmosphÑrische Transmission }
  sinld,
  cosld,
  AOB,
  DEC,
  X,
  hour,
  dsinb,
  dsinbe,
  sc,
  frdif,
  par
                                        : REAL;

  I : integer;


BEGIN  { Procedure ASTRO }

{  Pruefung des Gueltigkeitsbereichs  }

  IF LAT > 67. THEN BEGIN
    ShowMessage(' Fehler in ASTRO: LAT > 67');
    HALT;
  END;

  IF LAT < -67. THEN BEGIN
     ShowMessage(' Fehler in ASTRO: LAT <-67');
     HALT;
  END;

{ Deklination der Sonne als Funktion der Jahreszeit (DAY) }

   X:= arcsin(SIN(23.45*RAD)*COS(2.*PI*(DAY+10)/365));
   DEC:=X*-1;

{ Zwischenwerte SINLD, COSLD und AOB }

   SINLD:=SIN(RAD*LAT)*SIN(DEC);
   COSLD:=COS(RAD*LAT)*COS(DEC);
   AOB:=  SINLD/COSLD;

{Tageslaenge (DAYL) und photoperiodische Tageslaenge (DAYLP) }

   X:=ARCSIN(AOB);
   DAYL:= 12.0*(1+2*X/PI);
//   X:=arcsin((-SIN(-4*RAD)+SINLD)/COSLD);
//   DAYLP:=12.0*(1+2*X/PI);

{ Sonnenwinkel - Integration }

   DSINB:= 3600*(DAYL*SINLD+24*COSLD*SQRT(1-AOB*AOB)/PI);
   DSINBE:=3600*(DAYL*(SINLD+0.4*(SINLD*SINLD+COSLD*COSLD*0.5))+
              12.0*COSLD*(2.0+3.0*0.4*SINLD)*SQRT(1-AOB*AOB)/PI);

{ Solarkonstante (SC) und taegliche extraterrestrische Strahlung (ANGOT) }

   SC:=   1370*(1+0.033*COS(2*PI*DAY/365));
   ANGOT:=SC*DSINB;

{ Diffuser Lichtanteil (FRDIF) berechnet nach dem atmosphaerischen
  Transmissionskoeffizienten (ATMTR) }

   ATMTR:=AVRAD/ANGOT;

   IF ATMTR > 0.75 THEN
      FRDIF:= 0.23

   ELSE IF (ATMTR <= 0.75) AND (ATMTR > 0.35) THEN
     FRDIF:= 1.33-1.46*ATMTR

   ELSE IF (ATMTR <= 0.35) AND (ATMTR > 0.07) THEN
     FRDIF:= 1-2.3*(ATMTR-0.07)*(ATMTR-0.07)

   ELSE
     FRDIF:= 1.0;

{ Berechnung der 3 (5) Zeitpunkte der Gauss-Integration }

   for I := 1 to n_gauss do begin

     Hour    := 12.0+0.5*DayL*xgauss[i];
     sinb[i] := sinld+cosld*cos(2.0*pi*(hour+12.0)/24);
     if sinb[i] < 0.0 then sinb[i] := 0.0;

{ Berechnung der diffusen und direkten PAR }

     PAR       := 0.5*AVRAD*sinb[i]*(1.0+0.4*sinb[i])/dsinbe;

     pardf[i] := PAR*frdif;
     if pardf[i] > PAR then pardf[i] := par;

     pardr[i] := par-pardf[i];


   end;

END;  { Procedure ASTRO }
{ ************************************************************************* }



{ ************************************************************************* }

PROCEDURE TABF (table : table_arr;
                Iltab : integer;
                x     : real;
                var y : real);
{ ************************************************************************* }



VAR
  SLOPE                                                : REAL;
  IUP,I                                                : INTEGER;

BEGIN  { Procedure Tabf }

{ PrÅfung auf Wertepaare }

  IF ILTAB MOD 2 <> 0 THEN BEGIN
    WRITELN (' Fehler in der Eingabetabelle ');
    WRITELN (' Wertepaare nicht vollstÑndig! ');
    WRITELN (' Programm beendet ');
    HALT;
  END;

{ PrÅfung auf ansteigend geordnete x-Werte }

  IUP:=0;
  I:=3;
  repeat

    IF TABLE[I] <= TABLE[I-2] THEN BEGIN

      WRITELN(' X-Koordinaten nicht ansteigend geordnet bei Element ',I:4);
      WRITELN(' Tabellenfunktion enthÑlt ',ILTAB:4,' Punkte');
      WRITELN(' Programm beendet! ');
      HALT;

    END;

    IF (IUP=0) AND (TABLE[I] >= X) THEN IUP:=I;
    I:=I+2;

  until I > ILTAB;


{ PrÅfung auf Wertbereichsunterschreitung }

  IF X < TABLE[1] THEN BEGIN   { If-Abfrage }

    WRITELN (' Wertbereichsunterschreitung!!! ');
    WRITELN (' Tabellenfunktion enthÑlt ',ILTAB:4,' Punkte ');
    WRITELN (' Interpolation bei X= ',X:12:4);
    Y:=TABLE[2];
    exit;

  END; { If-Abfrage }

{ PrÅfung auf WertbereichsÅberschreitung }

  IF X > TABLE[ILTAB-1] THEN BEGIN {If-Abfrage}

     WRITELN (' WertbereichsÅberschreitung!!! ');
     WRITELN (' Tabellenfunktion enthÑlt ',ILTAB:4,' Punkte');
     WRITELN (' Interpolation bei X= ',X:12:4);
     Y:=TABLE[ILTAB];
     exit;

  END;   {If-Abfrage }

{ Normale Interpolation }

   SLOPE:=(TABLE[IUP+1]-TABLE[IUP-1])/(TABLE[IUP]-TABLE[IUP-2]);

   Y:=TABLE[IUP-1]+(X-TABLE[IUP-2])*SLOPE;


END; {Procedure Tabf}

{ ************************************************************************* }





{ ************************************************************************* }

PROCEDURE ASSIM (sinb,
                 pardf,
                 pardr  : gauss_arr;
                 Pmax0,
                 eff,
                 lai,
                 dayl  : real;
                 Pmax_f : TPmax_f;
             var gphot, PARabs : real);

{ ************************************************************************* }




VAR
  dtga,
  FSLLA,
  fgl,
  FGROS,
  FGRS,
  FGRSH,
  FGRSUN,
  KDIF,
  KDIRBL,
  KDIRT,
  laic,
  refh,
  refs,
  sqv,
  VISD,
  VISDF,
  VISPP,
  VISSHD,
  VISSUN,
  VIST,
  VISTOT,
  VISLAIC,
  Pmax_L     : real;

  hour,
  layer,
  angle
           : INTEGER;

BEGIN
  SQV  := SQRT(1.0-SCV);
  dtga := 0.0;
// daily canopy absorption is set to zero
  VISTOT := 0;
  for hour := 1 to n_gauss do begin

 { Reflexion der horizontalen und sph‰rischen Blattverteilung }

  REFH := (1.0-SQV)/(1.0+SQV);
  REFS:=REFH*2.0/(1.0+1.6*SINB[hour]);

 { Extinktionskoeffizienten f¸r direkte Strahlung }
  KDIF := 0.8*SQV;
  KDIRBL:=(0.5/SINB[hour])*KDIF/(0.8*SQV);
  KDIRT:=KDIRBL*SQV;


  FGROS:=0;

// selection of depth in canopy, canopy absorption (J / m2 / s) is set to zero
    VISLAIC := 0;
    for layer := 1 to n_gauss do begin

    LAIC:=LAI*XGAUSS[layer];
    If Pmax_f = Pmax_fI then
      Pmax_L := Pmax0*exp(-kdif*LAIC)
    else Pmax_L := Pmax0;
// absorbed fluxes per unit leaf area: diffuse flux, total direct flux,
// direct component of direct flux

    VISDF:=(1-REFS)*PARDF[hour]*KDIF  *EXP(-KDIF  *LAIC);
    VIST :=(1-REFS)*PARDR[hour]*KDIRT *EXP(-KDIRT *LAIC);
    VISD :=(1-SCV) *PARDR[hour]*KDIRBL*EXP(-KDIRBL*LAIC);

    VISSHD:=VISDF+VIST-VISD;

  //    FGRSH :=Pmax*(1.0-EXP(-VISSHD*EFF/Pmax));
  // Ersatz der Exponentialfunktion durch die rechtwinklige Hyperbel
    If Pmax_f = Pmax_const then
       fgrsh := Pmax0*eff*Visshd/(eff*visshd+Pmax0)
    else fgrsh := Pmax_L*eff*Visshd/(eff*visshd+Pmax_L);

    VISPP:=(1-SCV)*PARDR[hour]/SINB[hour];
// Integration ¸ber die Blattfl‰chenwinkelklassen
    fgrsun := 0.0;
    For Angle := 1 to n_gauss do begin
      VISSUN := VISSHD + VISPP*xgauss[angle];
      if Pmax0 > 0.0 then
// fgrs := pmax*(1-exp(-VISSUN*Eff/Pmax))
// Ersatz der Exponentialfunktion durch die rechtwinklige Hyperbel
         If Pmax_f = Pmax_const then
           fgrs := Pmax0*eff*Vissun/(eff*vissun+Pmax0)
         else fgrs := Pmax_L*eff*Vissun/(eff*vissun+Pmax_L)
      else
        fgrs := fgrsh;
      fgrsun := fgrsun+fgrs*wgauss[angle];
   end;
    VISSUN := VISSHD + (1 - SCv) * KdirBL * PARDR[hour];
    FSLLA:=EXP(-KDIRBL*LAIC);
    FGL:=FSLLA*FGRSUN+(1-FSLLA)*FGRSH;
    FGROS:=FGROS+FGL*WGAUSS[layer];
//  instantaneous canopy absorption  (J / m2 / s)
    VISLAIC := VISLAIC + (FSLLA * VISSUN + (1-FSLLA) * VISSHD) * WGAUSS[layer] * LAI;
  end;
  VISDF:=(1-REFS)*PARDF[hour]*KDIF  *EXP(-KDIF  *LAI);
  VIST :=(1-REFS)*PARDR[hour]*KDIRT *EXP(-KDIRT *LAI);
//  'hourly canopy absorption (J / m2 / s)
  VISTOT := VISTOT + VISLAIC * WGAUSS [hour] * DAYL  * 3600;
  PARABs := VISTOT;
  FGROS:=FGROS*LAI;
  DTGA:=DTGA+FGROS*WGAUSS[hour];

  end;

  DTGA:=DTGA*DAYL*3600/1e6;
  GPHOT:=DTGA*30.0/44.0;

END;  { Procedure ASSIM }


{ ************************************************************************* }


{Constructor TSucrosTotDry.create (AOwner:TComponent);

begin
  inherited Create(AOwner);
  CreateAll;

end;}



procedure TSucrosTotDry.createAll;

begin
  inherited createAll;
  ParCreate( 'alpha','[g CO2.J-1]', 1e-5, alpha);
  ParCreate( 'Pmax','[g CO2.m-2.s-1]', 1e-3, Pmax);
  ParCreate( 'CVE','[g CH2O.gCO2-1]', 0.7, CVE);
  PARcreate('LAT', '[∞]', 52, Lat);

  VarCreate('I_av','[W.m-2]', 0, false, I_av);
  VarCreate('fabs','[-]', 0, false, fabs);
  VarCreate('keff','[-]', 0, false, keff);

  VarCreate('PARin','[-]', 0, false, PARin);

end;



procedure TSucrosTotDry.CalcRates;

var
  day : integer;
           sinb,
           pardf,
           pardr: gauss_arr;

  Pmax_eff : real;
  GrossPhotosynthesis : real;
  PARAbs              : real;
begin
  inherited CalcRates;
  day := trunc(GlobTime.v);


    ASTRO (day,
           LAT.v,
           PAR.v*1e6*2, // R¸ckrechnung auf Globalstrahlung in W.m-2 aus PAR in MJ.d-1
           sinb,
           pardf,
           pardr,
           dayl );

    {Lichtaufnahme und Stoffproduktion}

  Pmax_eff := Pmax.v*Temp_f.v;
    ASSIM (sinb,
           pardf,
           pardr,
           Pmax_eff,
           alpha.v,
           lai.v,
           dayl,
           Pmax_f,
           GrossPhotosynthesis, PARAbs);
  PARIn.v := par.v;
  PARAbs := PARAbs/1e6;
  fabs.v := PARabs/Par.v;
  AssiFlow.v := GrossPhotosynthesis*CVE.v;
  I_av.v := par.v;
  keff.v := -ln(1-Fabs.v)/Lai.v;
end;

procedure Register;

begin
  RegisterComponents('CERES Wheat', [TSucrosTotDry]);
end;


end.
