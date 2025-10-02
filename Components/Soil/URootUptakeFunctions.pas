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
///   Tortuosity factor
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
  function Imax(Cl, clmin, theta, w_influx, wld, rad: real): real;

{ ********************************************************************** }
{ Zweck : Berechnung des maximalen Nitratinfluxes [Kg N/cm*d]

  Parameter :

  Name             Inhalt                          Einheit      Typ
  Cl               Bodenlösungskonzentration       [Kg N/cm H2o]  I
  Clmin            min. Bodenlösungkonzentration   [Kg N/cm H2o]  I
  theta            volumetrischer Wassergehalt     [cm3/cm3]      I
  w_influx         Wasserinflux                    [cm3/cm*d]      I
  dist             mittlerer halber Wurzelabst.    [cm]
  rad              mittlerer Wurzelradius          [cm]

  Imax             maximaler Nitratinflux          [Kg N/cm*d]   O

  { ********************************************************************** }


var
  v, { Wasserinfluxgeschwindigkeit [cm3/cm2*d] }
  f, { Widerstandsfaktor }
  x, x1, x2, y, z1, Db, dist, Ima: real;


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
    dist := 1 / sqrt(pi * wld)
  else
  begin
    result := 0;
    exit;
  end;
  if Cl > 0.0 then
    Cl := Cl * 1E-8 // Umrechnung auf kg N/cm3 H2O
  else
  begin
    result := 0;
    exit;
  end;
  clmin := clmin * 1E-8; // Umrechnung auf kg N/
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
