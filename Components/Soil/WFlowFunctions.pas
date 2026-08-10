/// <summary> This unit contains functions to implement the Matrix Flow Potential approach into URootedSoil </summary>
/// <author> U. Böttcher </author>
/// <date> 31.08.2023 </date>

unit WFlowFunctions;

interface
uses UGenucht;

type
  TMFP = record
           logpsi: extended; // log10 scaled soil water tension
           psi: extended;  //soil water tension
           ku: extended; // unsaturated hydraulic conductivity
           sumku: extended; // summed ku values
         end;

  TMFP_table = class
  private
    /// <summary> array to store the MFP values for a given soil, 
    /// TMFP beeing a record containing the MFP parameters, logpsi, psi, ku and sumku </summary>
    vals: array[0..100] of TMFP;
  public
    /// <summary> function to get the summed ku value for a given soil water tension </summary> 
    function get_sumku(aPsi: extended): extended;

    /// <summary> constructor to create the MFP table for a given soil </summary>
    constructor create(aSoil: TGenucht);
    /// <summary> function to get the summed ku values as a string </summary>
    function getline: string;

  end;
  /// <summary> function to calculate the average distance between roots based on root length density </summary>
  function abstand_func (Wurzellaengendichte:real):real;

  /// <summary> function to calculate the maximum possible water influx into the roots based on MFP approach </summary>
  function MFP_IWmax(MFP_, xl, r_root: extended): extended;

  /// <summary> function to calculate the MFP at the root surface based on MFP0, water influx, root radius, distance from root and average distance between roots </summary>
  function MFP_r_f(MFP0, Iw, r_root, r, xl: extended): extended;

  /// <summary> function to calculate the MFP at the root surface based on MFP, average distance between roots, root radius and water influx </summary>
  function MFP0_f(MFP_, xl, r_root, Iw: extended): extended;

  /// <summary> function to calculate the sink term based on MFP, MFP0, average distance between roots and root radius </summary>
  function MFP_Sz_f(MFP_,MFP0, xl, r_root: extended): extended;

  /// <summary> function to calculate the sink term based on water content, soil layer thickness, MFP, root radius and sink term at the root surface </summary>
  function MFP_Inflow(WLD,thick,MFP_,r_root,sink0: extended): extended;

  /// <summary> function to calculate the soil water content at the root surface </summary>
  function baf(b, Iw, Dw, xl, a: real): real;


  /// <summary> function to calculate the maximum water influx rate into the roots </summary>
  function Iwmax(b, bmin, Dw, xl, a: real): real;

  /// <summary> function to calculate the sinusoidal course of water uptake over the day </summary>
  function sinusf(hour: real): real;  

  /// <summary> function for calculation of the water uptake for a specific hour of the day </summary>
Function Water_flow_func(avg_transpi_rate, L, hour: real;
  sinus_func: boolean): real;


implementation
uses SysUtils, math, URootedSoil;


function baf(b, Iw, Dw, xl, a: real): real;
// calculation of soil water content at root surface
// b: average soil water content [cm3/cm3]
// Iw: water influx rate [cm3.cm-2.d-1]
// Dw: soil water diffusivity [cm2.s-1]
// xl: average half distance between roots [cm]
// a: root radius [cm]

begin
  if Dw > 0 then
    baf := b - (Iw / (2 * pi * Dw) * ln(xl / (1.65 * a)))
  else
    baf := 0;
end;

function Iwmax(b, bmin, Dw, xl, a: real): real;

// calculation of maximum water influx rate [cm3.cm-1.d-1]
// b: average soil water content [cm3/cm3]
// bmin: minimum soil water content [cm3/cm3]
// Dw: soil water diffusivity [cm2.s-1]
// xl: average half distance between roots [cm]

begin
  If (b - bmin < 0.0) then
    Iwmax := 0.0
  else
    Iwmax := ((b - bmin) * 2 * pi * Dw) / (ln(xl / (1.65 * a)));
end;

function sinusf(hour: real): real;
var
  output: real;
begin
  output := max(0, 1.64221194 * (0.5 + sin(pi * ((hour + 18) / 12))));
  sinusf := output;
end;

Function Water_flow_func(avg_transpi_rate, L, hour: real;
  sinus_func: boolean): real;

// Water_flow_func: water uptake rate per unit root length
// avg_transp_rate: average transpiration rate [mm.d-1]
// L : total root length [cm/ha]
// hour: hour of the day
// sinus_func: switch for even or sinusoidal course of water uptake

var
  Es, // transpiration rate per cm3.s-1
  Transpi_rate: real;

begin
  If sinus_func = true then
  begin
    Transpi_rate := avg_transpi_rate * sinusf(hour);
    If Transpi_rate <= 1E-12 then
      Transpi_rate := 0.0;
  end
  else
    Transpi_rate := avg_transpi_rate;
  Es := Transpi_rate * 1E7 / 86400.0;
  if L > 0 then
    Water_flow_func := Es / L
  else
    Water_flow_func := 0.0;
end;


function TMFP_table.get_sumku(aPsi: extended): extended;
var
  i: integer;
begin
  i := 1;
  while (aPsi > vals[i].psi) and (i<100) do inc(i);
  result := vals[i-1].sumku + (aPsi - vals[i-1].psi)/(vals[i].psi - vals[i-1].psi)*(vals[i].sumku - vals[i-1].sumku);

end;

constructor TMFP_table.create(aSoil: TGenucht);
var
  i: integer;
begin
  for i := 100 downto 0 do begin
    vals[i].logpsi := -1+i*5.2/100;
    vals[i].psi := power(10, vals[i].logpsi);
    vals[i].ku := aSoil.ku_psi_f(vals[i].psi);
    if i < 100 then vals[i].sumku := vals[i+1].sumku + (vals[i+1].ku+vals[i].ku)/2 *(vals[i+1].psi - vals[i].psi)
             else vals[i].sumku := 0;
  end;
end;

function TMFP_table.getline: string;
var
  i: integer;
begin
  result := '';
  for i := 0 to 100 do begin
    result := result + FloatToStr(vals[i].sumku) + '; ';
  end;
end;


function abstand_func (Wurzellaengendichte:real):real;
begin
  if Wurzellaengendichte >0 then

  abstand_func := 1 / sqrt(pi * Wurzellaengendichte) else
  abstand_func := 0.0;
end;


function MFP_IWmax(MFP_, xl, r_root: extended): extended;
begin
  result := (4*pi*sqr(xl)*MFP_)/((sqr(r_root)-sqr(0.56)*sqr(xl))+2*(sqr(xl)+sqr(r_root))*ln((0.56*xl)/r_root));
end;

function MFP0_f(MFP_, xl, r_root, Iw: extended): extended;
begin
  result := max(0, MFP_- Iw/(2*pi*sqr(xl))*((sqr(r_root)-sqr(0.56*xl))/2+(sqr(xl)+sqr(r_root))*ln((0.56*xl)/r_root)));
end;

function MFP_r_f(MFP0, Iw, r_root, r, xl: extended): extended;
begin
  result := MFP0 + Iw/(2*pi*sqr(xl))*((sqr(r_root)-sqr(r))/2+(sqr(xl)+sqr(r_root))*ln(r/r_root));
end;

function MFP_Sz_f(MFP_,MFP0, xl, r_root: extended): extended;
begin
  result := 4*(MFP_-MFP0)/((sqr(r_root)-sqr(0.56)*sqr(xl))+2*(sqr(xl)+sqr(r_root))*ln((0.56*xl)/r_root));
end;

function MFP_Inflow(WLD,thick,MFP_,r_root,sink0: extended): extended;
var
  rl,
  MFP0,Iw,MFP_r,PotMaxInflow: extended;
begin
  if WLD>0.0 then begin
    rl := 0.1*WLD*thick*1e8;    // from RLD [cm.cm-3] to rl in cm.ha-1
    PotMaxInflow := MFP_IWmax(MFP_, abstand_func(WLD), r_root);
    //Iw := min(water_flow_func(sink0*10, rl, 12, true), PotMaxInflow);
    Iw := PotMaxInflow ;
    MFP0 := MFP0_f(MFP_, abstand_func(WLD), r_root, Iw);
    result := MFP_Sz_f(MFP_,MFP0,abstand_func(WLD), r_root);
  end
  else result := 0.0;
end;



end.