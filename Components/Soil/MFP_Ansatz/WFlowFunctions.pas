unit WFlowFunctions;
// Functions to implement the Matrix Flow Potential approach into URootedSoil
// U.Böttcher 31.08.2023


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
    vals: array[0..100] of TMFP;
  public
    function get_sumku(aPsi: extended): extended;
    constructor create(aSoil: TGenucht);
    function getline: string;
  end;

  function abstand_func (Wurzellaengendichte:real):real;
  function MFP_IWmax(MFP_, xl, r_root: extended): extended;
  function MFP_r_f(MFP0, Iw, r_root, r, xl: extended): extended;
  function MFP0_f(MFP_, xl, r_root, Iw: extended): extended;
  function MFP_Sz_f(MFP_,MFP0, xl, r_root: extended): extended;
  function MFP_Inflow(WLD,thick,MFP_,r_root,sink0: extended): extended;



implementation
uses SysUtils, math, URootedSoil;

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