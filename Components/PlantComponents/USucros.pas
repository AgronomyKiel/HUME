unit USucros;

interface

uses
  UState, IniFiles, UMod, Classes, UDryMatProdComp;

type
  real = double;
  TPmax_f = (Pmax_const, Pmax_fI);

CONST

  RAD = pi / 180.0;
  SCV = 0.2; // Scattering coefficient of leaves for visible radiation (PAR)

  max_tab = 12; { maximale Anzahl der Zahlen in einer Interpolations-
    tabelle }
  // n_gauss = 3;
  n_gauss = 5;

type
  gauss_arr = array [1 .. n_gauss] of real;

const

  // XGAUSS : gauss_arr = (0.1127, 0.5,    0.8873);
  // WGAUSS : gauss_arr = (0.2778, 0.4444, 0.2778);
  XGAUSS: gauss_arr = (0.0469101, 0.2307534, 0.5, 0.7692465, 0.9530899);
  WGAUSS: gauss_arr = (0.1184635, 0.2393144, 0.2844444, 0.2393144, 0.1184635);

type
  table_arr = array [1 .. max_tab] of real;

  TSucrosTotDry = Class(TDryMatterproduction)

  private

  protected

  public
    alpha: TPar;
    Pmax: TPar;
    CVE: TPar;
    LAT: TPar;
    I_av: TVar;
    fabs: TVar;
    keff: TVar;
    PARin: TVar;
    Pmax_f: TPmax_f;

    procedure createAll; override;
    procedure CalcRates; override;

  private

  public

  published

    property OptPmax_f: TPmax_f read Pmax_f write Pmax_f;
    property Par_Pmax: TPar read Pmax write Pmax;
    property Par_alpha: TPar read alpha write alpha;
    property PAR_CVE: TPar read CVE write CVE;
    property PAR_LAT: TPar read LAT write LAT;
    property Var_fabs: TVar read fabs write fabs;

  end;

procedure register;

implementation

uses
  Math, VCL.Dialogs;

{ ************************************************************************* }

PROCEDURE ASTRO(day, LAT, avrad: real; var sinb, pardf, pardr: gauss_arr;
  var dayl: real);

{ ************************************************************************* }

VAR
  ANGOT, { Angots-value [W/m2] }
  atmtr, { atmosph„rische Transmission }
  sinld, cosld, AOB, DEC, X, hour, dsinb, dsinbe, sc, frdif, par: real;

  I: integer;

BEGIN { Procedure ASTRO }

  { Pruefung des Gueltigkeitsbereichs }

  IF LAT > 67. THEN
  BEGIN
    ShowMessage(' Fehler in ASTRO: LAT > 67');
    HALT;
  END;

  IF LAT < -67. THEN
  BEGIN
    ShowMessage(' Fehler in ASTRO: LAT <-67');
    HALT;
  END;

  { Deklination der Sonne als Funktion der Jahreszeit (DAY) }

  X := arcsin(SIN(23.45 * RAD) * COS(2. * pi * (day + 10) / 365));
  DEC := X * -1;

  { Zwischenwerte SINLD, COSLD und AOB }

  sinld := SIN(RAD * LAT) * SIN(DEC);
  cosld := COS(RAD * LAT) * COS(DEC);
  AOB := sinld / cosld;

  { Tageslaenge (DAYL) und photoperiodische Tageslaenge (DAYLP) }

  X := arcsin(AOB);
  dayl := 12.0 * (1 + 2 * X / pi);
  // X:=arcsin((-SIN(-4*RAD)+SINLD)/COSLD);
  // DAYLP:=12.0*(1+2*X/PI);

  { Sonnenwinkel - Integration }

  dsinb := 3600 * (dayl * sinld + 24 * cosld * SQRT(1 - AOB * AOB) / pi);
  dsinbe := 3600 * (dayl * (sinld + 0.4 * (sinld * sinld + cosld * cosld * 0.5))
    + 12.0 * cosld * (2.0 + 3.0 * 0.4 * sinld) * SQRT(1 - AOB * AOB) / pi);

  { Solarkonstante (SC) und taegliche extraterrestrische Strahlung (ANGOT) }

  sc := 1370 * (1 + 0.033 * COS(2 * pi * day / 365));
  ANGOT := sc * dsinb;

  { Diffuser Lichtanteil (FRDIF) berechnet nach dem atmosphaerischen
    Transmissionskoeffizienten (ATMTR) }

  atmtr := avrad / ANGOT;

  IF atmtr > 0.75 THEN
    frdif := 0.23

  ELSE IF (atmtr <= 0.75) AND (atmtr > 0.35) THEN
    frdif := 1.33 - 1.46 * atmtr

  ELSE IF (atmtr <= 0.35) AND (atmtr > 0.07) THEN
    frdif := 1 - 2.3 * (atmtr - 0.07) * (atmtr - 0.07)

  ELSE
    frdif := 1.0;

  { Berechnung der 3 (5) Zeitpunkte der Gauss-Integration }

  for I := 1 to n_gauss do
  begin

    hour := 12.0 + 0.5 * dayl * XGAUSS[I];
    sinb[I] := sinld + cosld * COS(2.0 * pi * (hour + 12.0) / 24);
    if sinb[I] < 0.0 then
      sinb[I] := 0.0;

    { Berechnung der diffusen und direkten PAR }

    par := 0.5 * avrad * sinb[I] * (1.0 + 0.4 * sinb[I]) / dsinbe;

    pardf[I] := par * frdif;
    if pardf[I] > par then
      pardf[I] := par;

    pardr[I] := par - pardf[I];

  end;

END; { Procedure ASTRO }
{ ************************************************************************* }

{ ************************************************************************* }

PROCEDURE ASSIM(sinb, pardf, pardr: gauss_arr; Pmax0, eff, lai, dayl: real;
  Pmax_f: TPmax_f; var gphot, PARabs: real);

{ ************************************************************************* }

VAR
  dtga, FSLLA, fgl, FGROS, FGRS, FGRSH, FGRSUN, KDIF, KDIRBL, KDIRT, laic, refh,
    refs, sqv, VISD, VISDF, VISPP, VISSHD, VISSUN, VIST, VISTOT, VISLAIC,
    Pmax_L: real;

  hour, layer, angle: integer;

BEGIN
  sqv := SQRT(1.0 - SCV);
  dtga := 0.0;
  // daily canopy absorption is set to zero
  VISTOT := 0;
  for hour := 1 to n_gauss do
  begin

    { Reflexion der horizontalen und sphärischen Blattverteilung }

    refh := (1.0 - sqv) / (1.0 + sqv);
    refs := refh * 2.0 / (1.0 + 1.6 * sinb[hour]);

    { Extinktionskoeffizienten für direkte Strahlung }
    KDIF := 0.8 * sqv;
    KDIRBL := (0.5 / sinb[hour]) * KDIF / (0.8 * sqv);
    KDIRT := KDIRBL * sqv;

    FGROS := 0;

    // selection of depth in canopy, canopy absorption (J / m2 / s) is set to zero
    VISLAIC := 0;
    for layer := 1 to n_gauss do
    begin

      laic := lai * XGAUSS[layer];
      If Pmax_f = Pmax_fI then
        Pmax_L := Pmax0 * exp(-KDIF * laic)
      else
        Pmax_L := Pmax0;
      // absorbed fluxes per unit leaf area: diffuse flux, total direct flux,
      // direct component of direct flux

      VISDF := (1 - refs) * pardf[hour] * KDIF * exp(-KDIF * laic);
      VIST := (1 - refs) * pardr[hour] * KDIRT * exp(-KDIRT * laic);
      VISD := (1 - SCV) * pardr[hour] * KDIRBL * exp(-KDIRBL * laic);

      VISSHD := VISDF + VIST - VISD;

      // FGRSH :=Pmax*(1.0-EXP(-VISSHD*EFF/Pmax));
      // Ersatz der Exponentialfunktion durch die rechtwinklige Hyperbel
      If Pmax_f = Pmax_const then
        FGRSH := Pmax0 * eff * VISSHD / (eff * VISSHD + Pmax0)
      else
        FGRSH := Pmax_L * eff * VISSHD / (eff * VISSHD + Pmax_L);

      VISPP := (1 - SCV) * pardr[hour] / sinb[hour];
      // Integration über die Blattflächenwinkelklassen
      FGRSUN := 0.0;
      For angle := 1 to n_gauss do
      begin
        VISSUN := VISSHD + VISPP * XGAUSS[angle];
        if Pmax0 > 0.0 then
          // fgrs := pmax*(1-exp(-VISSUN*Eff/Pmax))
          // Ersatz der Exponentialfunktion durch die rechtwinklige Hyperbel
          If Pmax_f = Pmax_const then
            FGRS := Pmax0 * eff * VISSUN / (eff * VISSUN + Pmax0)
          else
            FGRS := Pmax_L * eff * VISSUN / (eff * VISSUN + Pmax_L)
        else
          FGRS := FGRSH;
        FGRSUN := FGRSUN + FGRS * WGAUSS[angle];
      end;
      VISSUN := VISSHD + (1 - SCV) * KDIRBL * pardr[hour];
      FSLLA := exp(-KDIRBL * laic);
      fgl := FSLLA * FGRSUN + (1 - FSLLA) * FGRSH;
      FGROS := FGROS + fgl * WGAUSS[layer];
      // instantaneous canopy absorption  (J / m2 / s)
      VISLAIC := VISLAIC + (FSLLA * VISSUN + (1 - FSLLA) * VISSHD) *
        WGAUSS[layer] * lai;
    end;
    // VISDF:=(1-REFS)*PARDF[hour]*KDIF  *EXP(-KDIF  *LAI);
    // VIST :=(1-REFS)*PARDR[hour]*KDIRT *EXP(-KDIRT *LAI);
    // 'hourly canopy absorption (J / m2 / s)
    VISTOT := VISTOT + VISLAIC * WGAUSS[hour] * dayl * 3600;
    PARabs := VISTOT;
    FGROS := FGROS * lai;
    dtga := dtga + FGROS * WGAUSS[hour];

  end;
  dtga := dtga * dayl * 3600 / 1E6;
  gphot := dtga * 30.0 / 44.0;
END; { Procedure ASSIM }

{ ************************************************************************* }

procedure TSucrosTotDry.createAll;

begin
  inherited createAll;
  ParCreate('alpha', '[g CO2.J-1]', 1E-5, alpha);
  ParCreate('Pmax', '[g CO2.m-2.s-1]', 1E-3, Pmax);
  ParCreate('CVE', '[g CH2O.gCO2-1]', 0.7, CVE);
  ParCreate('LAT', '[°]', 52, LAT);

  VarCreate('I_av', '[W.m-2]', 0, false, I_av);
  VarCreate('fabs', '[-]', 0, false, fabs);
  VarCreate('keff', '[-]', 0, false, keff);

  VarCreate('PARin', '[-]', 0, false, PARin);

end;

procedure TSucrosTotDry.CalcRates;

var
  day: integer;
  sinb, pardf, pardr: gauss_arr;

  Pmax_eff: real;
  dayl: real;
  GrossPhotosynthesis: real;
  PARabs: real;
begin
  inherited CalcRates;
  day := trunc(GlobTime.v);

  ASTRO(day, LAT.v, par.v * 1E6 * 2,
    // Rückrechnung auf Globalstrahlung in W.m-2 aus PAR in MJ.d-1
    sinb, pardf, pardr, dayl);

  { Lichtaufnahme und Stoffproduktion }

  Pmax_eff := Pmax.v * Temp_f.v;
  ASSIM(sinb, pardf, pardr, Pmax_eff, alpha.v, lai.v, dayl, Pmax_f,
    GrossPhotosynthesis, PARabs);
  PARin.v := par.v;
  PARabs := PARabs / 1E6;
  fabs.v := PARabs / par.v;
  AssiFlow.v := GrossPhotosynthesis * CVE.v;
  I_av.v := par.v;
  if lai.v > 0 then

    keff.v := -ln(1 - fabs.v) / lai.v
  else
    keff.v := 0.0;
end;

procedure register;

begin
  RegisterComponents('Simulation', [TSucrosTotDry]);
end;

end.
