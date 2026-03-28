unit URootUptakeFunctions;

interface

const
  /// <summary>
  /// Diffusionskoeffizient von Nitrat in Wasser [cm2/d]
  /// </summary>
  D0NO3 = 1.92E-5 * 86400.0;

type
  real = double;

function f_Tortuosity(theta: real): real;

/// <summary>
/// function for calculation of maximum nitrate uptake rates of roots
/// </summary>
/// parameters:
/// <param name="Cl">Soil solution concentration [Kg N/cm3 H2O]</param>
/// <param name="clmin">Minimum soil solution concentration [Kg N/cm3 H2O]</param>
/// <param name="theta">Volumetric water content [cm3/cm3]</param>
/// <param name="w_influx">Water influx [cm3/cm*d]</param>
/// <param name="rld">Mean root length density [cm/cm3]</param>
/// <param name="rad">Mean root radius [cm]</param>
/// <returns>Maximum nitrate influx [Kg N/cm*d]</returns>
/// <remarks>
/// Nitrate Concentrations are in [Kg NO3-N/cm H2O]
/// this unusual unit is the consequence of
/// giving the amount of water in cm throughout the
/// classes of this class library
/// in order to convert to g N /l
/// multiply by 1000 -> from kg to g
/// multiply by 10000 x 10 from cm to l
/// -> multiply by 1e8
/// </remarks>
function Imax_f(Cl, clmin, theta, w_influx, rld, rad: real): real;

/// <summary>
/// function for calculation of nitrate uptake rates of roots
/// using the Michaelis-Menten-cinetic as an inner boundary
/// </summary>
/// parameters:
/// <param name="Cl">Soil solution concentration [Kg N/cm3 H2O]</param>
/// <param name="clmin">Minimum soil solution concentration [Kg N/cm3 H2O]</param>
/// <param name="theta">Volumetric water content [cm3/cm3]</param>
/// <param name="w_influx">Water influx [cm3/cm*d]</param>
/// <param name="rld">Mean root length density [cm/cm3]</param>
/// <param name="rad">Mean root radius [cm]</param>
/// <returns>Maximum nitrate influx [Kg N/cm*d]</returns>
/// <remarks>
/// Nitrate Concentrations are in [Kg NO3-N/cm H2O]
/// this unusual unit is the consequence of
/// giving the amount of water in cm throughout the
/// classes of this class library
/// in order to convert to g N /l
/// multiply by 1000 -> from kg to g
/// multiply by 10000 x 10 from cm to l
/// -> multiply by 1e8
/// </remarks>

function MM_NInflux(Cl, rld, rad, theta, w_influx, Imax, Km, clmin: real): real;


/// <summary>
/// calculates maximum water uptake rate of roots
/// according to the single root approach of Gardner (1960)
/// </summary>
/// <param name="b">average soil water content of the root cylinder [cm3/cm3]</param>
/// <param name="bmin">minimum soil water content at permanent wilting point [cm]</param>
/// <param name="Dw">diffusion coefficient of water [cm2/d]</param>
/// <param name="xl"> half distance between roots [cm]</param>
/// <param name="a"> root radius [cm]</param>

function Iwmax (b, bmin, Dw, xl, a: real):real;


/// <summary>
/// calculates the soil water content at the root surface
/// according to the single root approach of Gardner (1960)
/// </summary>
/// <param name="b">average soil water content of the root cylinder [cm3/cm3]</param>
/// <param name="Iw">water influx [cm3/cm/d]</param>
/// <param name="Dw">diffusion coefficient of water [cm2/d]</param>
/// <param name="xl"> half distance between roots [cm]</param>
/// <param name="a"> root radius [cm]</param>
function baf (b, Iw, Dw, xl, a:real):real;

implementation

uses
  math;

/// <summary>
/// Tortuosity factor for solute diffusion in soil
/// empirical function of based on data of Barraclough (1993?)
/// </summary>
function f_Tortuosity(theta: real): real;

var
  f: real;

begin
  f := 3.35 * theta * theta; // Tortuositaetsfaktor
  if f < 0.0 then
    f := 0.0;
  f_Tortuosity := f;
end;

/// <summary>
/// function for calculation of maximum nitrate uptake rates of roots
/// </summary>
/// parameters:
/// <param name="Cl">Soil solution concentration [Kg N/cm3 H2O]</param>
/// <param name="clmin">Minimum soil solution concentration [Kg N/cm3 H2O]</param>
/// <param name="theta">Volumetric water content [cm3/cm3]</param>
/// <param name="w_influx">Water influx [cm3/cm*d]</param>
/// <param name="wld">Mean root length density [cm/cm3]</param>
/// <param name="rad">Mean root radius [cm]</param>
/// <returns>Maximum nitrate influx [Kg N/cm*d]</returns>
/// <remarks>
/// Nitrate Concentrations are in [Kg NO3-N/cm H2O]
/// this unusual unit is the consequence of
/// giving the amount of water in cm throughout the
/// classes of this class library
/// in order to convert to g N /l
/// multiply by 1000 -> from kg to g
/// multiply by 10000 x 10 from cm to l
/// -> multiply by 1e8
/// </remarks>
function Imax_f(Cl, clmin, theta, w_influx, rld, rad: real): real;

{ ********************************************************************** }
{ Purpose : Calculation of the maximum nitrate influx [Kg N/cm*d]

  Parameters :

  Name             Description                          Unit           Type
  Cl               Soil solution concentration          [Kg N/cm H2O]  Input
  Clmin            Minimum soil solution concentration  [Kg N/cm H2O]  Input
  theta            Volumetric water content             [cm3/cm3]      Input
  w_influx         Water influx                         [cm3/cm*d]     Input
  dist             Mean half root spacing               [cm]           Input
  rad              Mean root radius                     [cm]           Input

  Imax             Maximum nitrate influx               [Kg N/cm*d]    Output
}

var
  v, { Wasserinfluxgeschwindigkeit [cm3/cm2*d] }
  f, { Widerstandsfaktor }
  x, x1, x2, y, z1, Db, dist, Ima: real;

  /// <summary>
  /// function for maximum nitrate uptakrate without massflow
  /// under steady state conditions
  /// </summary>
  function v0Imax(Cl, clmin, Db, dist, rad: real): real;
  // maximum nitrate influx without mass flow

  begin
    if Cl - clmin < 0.0 then
      v0Imax := 0.0
    else
      v0Imax := ((Cl - clmin) * 2 * pi * Db) / (ln(dist / (1.65 * rad)));
  end;

begin
  Ima := 0;

  if rld > 0.0 then
    // half distance between roots [cm]
    dist := 1 / sqrt(pi * rld)
  else
  begin
    result := 0;
    exit;
  end;
  if Cl > 0.0 then
    Cl := Cl * 1E-8 // transformation from  kg N/cm3 H2O to g/l
  else
  begin
    result := 0;
    exit;
  end;
  clmin := clmin * 1E-8; // transformation from  kg N/cm3 H2O to g/l
  w_influx := w_influx * 1E8; // Umrechnung auf cm3
  f := f_Tortuosity(theta);
  Db := D0NO3 * f * theta;
  if Db <= 0.0 then
  begin
    result := 0.0;
    exit;
  end
  else
  begin
    if Cl - clmin <= 0.0 then
    begin
      result := 0.0;
      exit;
    end
    else
    begin
      if w_influx <= 1E-10 then
      begin
        Ima := v0Imax(Cl, clmin, Db, dist, rad);
        // result := Ima;  // wird nie benutzt!
      end
      else
      begin
        v := w_influx / (2 * pi * rad);
        x1 := 2 / (2 - (rad * v) / Db);
        x2 := Power(dist / rad, 2 - (rad * v) / Db) - 1;
        x := x1 * x2;
        y := Power(dist / rad, 2) - 1;
        z1 := x / y;
        if clmin > 0.0 then
          Ima := (Cl * 2 * pi * rad * v - 2 * pi * rad * clmin * v * z1)
            / (1 - z1)
        else if z1 <> 1 then
          Ima := (Cl * 2 * pi * rad * v) / (1 - z1)
      end;
    end;
  end;
  result := max(0, Ima);
end;

function uptake_f(Imax, Km, Cmin, Cla: real): real;

{ berechnet die Aufnahme in [mol/(sec*cm Wurzel)] nach der
  Michaelis-Menten-Kinetik aus den Parametern Imax [mol/(cm*sec)],
  Km [mol/cm3] und Cmin [mol/cm3] }
var
  uptake: real;

begin
  if Cla - Cmin <= 0.0 then
    uptake := 0.0
  else
    uptake := (Imax * (Cla - Cmin)) / (Km + (Cla - Cmin));
  uptake_f := uptake;
end;

procedure quad_solv(a1, a0: real; var x1, x2: real);

{ berechnet die beiden L�sungen x1, x2 eines quadratischen Gleichungssystems
  der Form x^2 + a1*x + a0 = 0 }

begin
{$R-}
  x1 := -a1 / 2 + sqrt((a1 * a1) / 4 - a0);
  x2 := -a1 / 2 - sqrt((a1 * a1) / 4 - a0);
{$R+}
end;

function mm_cla_f(Cl, x, a, Db, v0, Imax, Km, Cmin: real): real;

{ Berechnung der Konzentration an der Wurzeloberfl�che aus den Parametern
  der Michaelis-Menten-Kinetik und dem quasistation�ren Transportansatz
  nach Baldwin }

  function v0_mm_cla_f(Cl, x, a, Db, Imax, Km, Cmin: real): real;

  { Funktion f�r Transport nur durch Diffusion }

  var
    z1, z2, z3, a1, a0, Cla, Cla2: real;

  begin
    z1 := (sqr(x) * Imax) / ((sqr(x) - sqr(a)) * 2 * pi * Db);
    z2 := Imax / (4 * pi * Db);
    z3 := ln(x / a);
    a0 := -Cl * Km;
    a1 := -(Cl - Km - z1 * z3 + z2);
    quad_solv(a1, a0, Cla, Cla2);
    v0_mm_cla_f := Cla;
  end;

var
  a0, a1, x1, x2, xz, yz, z1, z2, Cla, Cla2: real;

begin
  Cl := Cl - Cmin;
  If v0 <= 0.0 then
  begin
    Cla := v0_mm_cla_f(Cl, x, a, Db, Imax, Km, Cmin);
    Cla := Cla + Cmin;
    mm_cla_f := Cla;
  end
  else
  begin
    x1 := 2 / (2 - (a * v0) / Db);
    x2 := Power(x / a, 2 - (a * v0) / Db) - 1;
    xz := x1 * x2;
    yz := Power(x / a, 2) - 1;
    z1 := yz / xz;
    z2 := Imax / (2 * pi * a * v0);
    a0 := -Cl * Km * z1;
    a1 := z1 * (z2 - z2 * xz / yz - Cl + Km);
    quad_solv(a1, a0, Cla, Cla2);
    Cla := Cla + Cmin;
    mm_cla_f := Cla;
  end;
end;

function MM_NInflux(Cl, rld, rad, theta, w_influx, Imax, Km, clmin: real): real;

var
  /// <summary>
  /// nitrate concentration at root surface [kg/cm]
  /// </summary>
  RootSurfaceConc: real;

  /// <summary>
  /// half distance between roots [cm]
  /// </summary>
  HalfDistance,

  /// <summary>
  /// effective Diffusion coefficient times buffering
  /// for nitrat bufferingn is equal to volumetric soil water content
  /// </summary>
  Db, f: real;

begin
  Cl := Cl * 1E-8; // transformation from  kg N/cm3 H2O to g/l
  clmin := clmin * 1E-8; // transformation from  kg N/cm3 H2O to g/l
  w_influx := w_influx * 1E8; // Umrechnung auf cm3
  f := f_Tortuosity(theta);
  Db := D0NO3 * f * theta;

  HalfDistance := 1 / (sqrt(pi * rld));
  RootSurfaceConc := mm_cla_f(Cl, HalfDistance, rad, Db, w_influx, Imax,
    Km, clmin);
  MM_NInflux := uptake_f(Imax, Km, clmin, RootSurfaceConc);
end;



function Iwmax (b, bmin, Dw, xl, a: real):real;

begin
  If (b-bmin < 0.0) then Iwmax := 0.0 else
  Iwmax := ((b-bmin)*2*pi*Dw)/(ln(xl/(1.65*a)));
end;


function baf (b, Iw, Dw, xl, a:real):real;

begin
  baf:= b-(Iw/(2*pi*Dw)*ln(xl/(1.65*a)));
end;



end.
