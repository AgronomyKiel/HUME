unit USucros;

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


TSucrosTotDry = Class(TDryMatterproduction)

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


procedure register;


implementation

uses
  Math, VCL.Dialogs;




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
  atmtr,                 { atmosph„rische Transmission }
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

 { Reflexion der horizontalen und sphärischen Blattverteilung }

  REFH := (1.0-SQV)/(1.0+SQV);
  REFS:=REFH*2.0/(1.0+1.6*SINB[hour]);

 { Extinktionskoeffizienten für direkte Strahlung }
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
// Integration über die Blattflächenwinkelklassen
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
//  VISDF:=(1-REFS)*PARDF[hour]*KDIF  *EXP(-KDIF  *LAI);
//  VIST :=(1-REFS)*PARDR[hour]*KDIRT *EXP(-KDIRT *LAI);
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



procedure TSucrosTotDry.createAll;

begin
  inherited createAll;
  ParCreate( 'alpha','[g CO2.J-1]', 1e-5, alpha);
  ParCreate( 'Pmax','[g CO2.m-2.s-1]', 1e-3, Pmax);
  ParCreate( 'CVE','[g CH2O.gCO2-1]', 0.7, CVE);
  PARcreate('LAT', '[°]', 52, Lat);

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
  dayl:real;
  GrossPhotosynthesis : real;
  PARAbs              : real;
begin
  inherited CalcRates;
  day := trunc(GlobTime.v);


    ASTRO (day,
           LAT.v,
           PAR.v*1e6*2, // Rückrechnung auf Globalstrahlung in W.m-2 aus PAR in MJ.d-1
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
  if LAI.v > 0 then

    keff.v := -ln(1-Fabs.v)/Lai.v
  else
    keff.v := 0.0;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TSucrosTotDry]);
end;      


end.

