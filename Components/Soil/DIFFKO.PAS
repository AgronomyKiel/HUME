unit Diffko;


Interface
uses
  math;


function Dbf(b:real):real;

function Dwf (b, Ks, bmin, bsat, alpha, nb: real):real;

function Dw2f(b, Dws, bw, bs: real):real;



implementation


function Dbf { (b:real):real} ;

var
  Db:real;

begin

Db := 1.92e-5*(3.35*b*b)*b;

If (Db < 0) then dbf:= 1e-9
else Dbf := Db;
end;



function Dw2f {(b, Dws, bw, bs:real):real} ;

{ Wasserdiffusit„tsfunktion nach WILLIGEN, VAN NOORDWIJK (1988)  S.100 }

var
   Dummy : real;


begin

Dummy := Dws * exp((bw*(b-bs)));

 If Dummy <= 1e-15 then Dw2f:= 1e-15
 Else Dw2f := Dummy/86400.0;

end;


function Dwf  {(b, Ks, bmin, bsat, alpha, nb: real):real} ;

var
  Dw, z1, z2, z3, z4, z5, z6, m, brelativ: real;

begin

  m:= 1-(1/nb);
  brelativ:= (b-bmin)/(bsat-bmin);
  z1:= 1-Power(brelativ, 1/m);
  z2:= Power(z1, m);
  z3:= Power(z1, -m);
  z4:= z3+z2-2;
  z5:= ((1-m)*Ks)/(alpha*m*(bsat-bmin))*Power(brelativ, 0.5-(1/m));
  Dw:= z5*z4/86400;


  If Dw <= 0 then Dwf:= 1e-9
  else Dwf := Dw;

end;
end.