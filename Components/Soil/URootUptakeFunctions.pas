unit URootUptakeFunctions;

interface

const
/// <summary>
///  Diffusionskoeffizient von Nitrat in Wasser [cm2/d]
/// </summary>
  D0NO3 = 1.92E-5 * 86400.0;

function f_Tortuosity(theta: real): real;


function Imax(Cl, clmin, theta, w_influx, wld, rad: real): real;

implementation

uses
  math;


/// <summary>
///  Tortuosity factor for solute diffusion in soil
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
///  function for calculation of maximum nitrate uptake rates of roots
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
///  classes of this class library
///  in order to convert to g N /l
///  multiply by 1000 -> from kg to g
///  multiply by 10000 x 10 from cm to l
///  -> multiply by 1e8
/// </remarks>
  function Imax(Cl, clmin, theta, w_influx, wld, rad: real): real;

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
///  function for maximum nitrate uptakrate without massflow
///  under steady state conditions
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

  if wld > 0.0 then
    // half distance between roots [cm]
    dist := 1 / sqrt(pi * wld)
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



end.
