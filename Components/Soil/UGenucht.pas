Unit UGenucht;

{ Sammlung der Funktionen aus:
  Van Genuchten, M. T. (1980)
  A closed-form equation for predicting the hydraulic conductivity
  of unsaturated soils
  Soil Sci. Soc. Am. J. (1980), 44, 892-898 }

{ Am 25.8.89 erweitert um den Parameter "l"
  siehe :
  W”sten, J.H.M., M.Th. Van Genuchten (1988)
  Using Texture and Other Soil Properties to predict
  the Unsaturated Soil Hydraulic Functions
  Soil Sci.Soc.Am.J. (1988) 52, 1762-1770 }

interface

const
  psimin = 2.0;


type
   real = double;



TGenucht = class (Tobject)

public

  b_sat    : real;   // Wassergehalt bei S„ttigung [cm3/cm3]
  b_rest   : real;   // "Restwassergehalt" [cm3/cm3]
  Ks       : real;   //  ges„ttigte hydraulische Leitf„higkeit [cm/d]
  alpha    : real;   //  Fitparameter "à" [1/cm]
  n_par    : real;   //  Fitparameter "n" dimensionslos
  m_par    : real;   //  Fitparameter "m" = 1-1/n (Mualem) bzw. 1-2/n (Burdine) bzw. 1 (Vereecken)
  l_par    : real;      //



function b_rel_f ( b:real):real;

{ Funktion zur Berechnung des relativen Wassergehaltes aus
  volumetrischem Wassergehalt (b), "Restwassergehalt (b_rest) und
  Wassergehalt bei S„ttigung (b_sat) }

function b_psi_f ( psi : real ):real;

{ Funktion zur Berechnung des volumetrischen Wassergehaltes (b)
  aus der Wasserspannung (psi) }


function psi_b_f ( b : real ):real;

{ Funktion zur Berechnung des Absolutwertes der Wasserspannung (positiv)
  aus dem volumetrischen Wassergehalt }

function Ku_b_f ( b : real):real;

{ Funktion zur Berechnung der unges„ttigten hydraulischen Leitf„higkeit }


function Ku_psi_f ( psi : real):real;

{ Funktion zur Berechnung der unges„ttigten hydraulischen Leitf„higkeit }

function C_b_f ( b : real):real;

{ Funktion zur Berechnung der spezifischen Wasserspeicherkapazit„t }


function C_psi_f ( psi : real): real;


function Dw_f ( b : real):real;

{ Funktion zur Berechnung der Wasserdiffusivit„t }

function b_rel_psi_f ( psi : real): real;

end;


implementation

uses
  Math;

function TGenucht.b_rel_f ( b:real):real;

{ Funktion zur Berechnung des relativen Wassergehaltes aus
  volumetrischem Wassergehalt (b), "Restwassergehalt (b_rest) und
  Wassergehalt bei S„ttigung (b_sat) }

begin
  b_rel_f := min(1,max(0,(b-b_rest)/(b_sat-b_rest)));
end;



function TGenucht.b_rel_psi_f ( psi : real): real;

{ Funktion zur Berechnung des relativen Wassergehaltes aus der
  Wasserspannung "Psi" }

var
  z1 : real;

begin
//    psi := max(psi, psimin);
    z1 := 1+power(alpha*max(0,psi),n_par);
    b_rel_psi_f := power(1/z1,m_par);
end;


function TGenucht.b_psi_f ( psi : real ):real;


{ Funktion zur Berechnung des volumetrischen Wassergehaltes (b)
  aus der Wasserspannung (psi) }

var
  z1, z2:real;


begin
   // psi := max(psi, psimin);

//    If psi <= 0.0 then b_psi_f := b_sat else begin
      z1 := power(alpha*abs(psi),n_par);
      z2 := power(1+z1,m_par);
      b_psi_f := b_rest+(b_sat-b_rest)/z2;
//    end;
end;


function TGenucht.psi_b_f ( b : real ):real;

{ Funktion zur Berechnung des Absolutwertes der Wasserspannung (positiv)
  aus dem volumetrischen Wassergehalt }

var
  z1, z2 : real;

begin
    If b >= b_sat then begin
      psi_b_f := 0.0;
      exit;
    end;
//    psi := max(psi, psimin);


    if b< b_rest then begin
      psi_b_f := 1e5;
      exit;
    end;
   // if (b-b_rest)>0.0 then begin
    //if (b-b_rest)>1e-06 then begin // ar: 26.05.17
    if (b-b_rest)>1e-03 then begin
      z1 := (b_sat-b_rest)/(b-b_rest);
      z2 := power(z1, 1/m_par)-1;
      psi_b_f := power(z2, 1/n_par)*1/alpha;
    end
    //else psi_b_f := 1e10;
    else psi_b_f := 1e5;
end;


function TGenucht.Ku_b_f ( b : real):real;


{ Funktion zur Berechnung der ungesättigten hydraulischen Leitf„higkeit }

var
  b_rel, K_rel, Ku, z1, z2, z3 : real;

begin
    If b >= b_sat then Ku := Ks else
    if b <= b_rest then Ku := 0.0 else
       { Sicherung gegen šberschreiten des Definitionsbereichs
         der Funktion }
    begin

      b_rel  := b_rel_f(b);
      z1     := power(1-power(b_rel, 1/m_par),m_par);
      z2     := power(b_rel, l_par );
      //Z3     := intpower(1-z1, 2);
      z3     := sqr(1-z1);
      K_rel  := z2*z3;
      Ku     := K_rel*Ks;
      If (Ku < 0.0) then Ku := 0.0;
    end;
    Ku_b_f := Ku;
end;


function TGenucht.Ku_psi_f ( psi : real):real;


{ Funktion zur Berechnung der unges„ttigten hydraulischen Leitf„higkeit }

var
 k_rel, Ku, z1, z2, z3, z4, z5 : real;

begin
//    If psi <= 0.0 then Ku := Ks
//    else begin

   // psi := max(psi, psimin);

      z1 := power (alpha*psi, n_par);
      z2 := power (alpha*psi, n_par-1);
      //z2 := z1 * (1.0/n_par) ;
      z3 := power(1+z1, -m_par);
      z4 := intpower(1-z2*z3,2);
      z5 := power(1+z1, m_par*l_par);
      k_rel := z4/z5;
      Ku := k_rel*Ks;
//    end;
    Ku_psi_f := Ku;
end;




function TGenucht.C_b_f ( b : real):real;


{ Funktion zur Berechnung der spezifischen Wasserspeicherkapazität }

var
  b_rel, z1, z2 : real;
  help : Real;
begin
    If b <= b_rest then b := b_rest + 1e-5;
    If b >= b_sat then b := b_sat - 1e-5;
    b_rel    :=  b_rel_f ( b);

    help :=  power(b_rel,1/m_par);

    //z1       := power(1-power(b_rel,1/m_par),m_par);
    z1       := power(1-help,m_par);
    z2       := -(alpha*m_par*(b_sat-b_rest))/(1-m_par);
    //C_b_f    := z2*power(b_rel,1/m_par)*z1;
    C_b_f    := z2*help*z1;
end;



function TGenucht.C_psi_f ( psi : real): real;

var
  b_rel, z1, z2 : real;
  help: Real;

begin
//    psi := max(psi, psimin);

  b_rel    :=  b_rel_psi_f ( psi );
   help := power(b_rel,1/m_par);

    //z1       := power(1-power(b_rel,1/m_par),m_par);
    z1       := power(1-help,m_par);
    z2       := -(alpha*m_par*(b_sat-b_rest))/(1-m_par);
    //C_psi_f    := z2*power(b_rel,1/m_par)*z1;
    C_psi_f    := z2*help*z1;
end;


function TGenucht.Dw_f ( b : real):real;

{ Funktion zur Berechnung der Wasserdiffusivität }

var
  z1, z2, z3, z4, z5, z6, z7,b_rel: real;

begin
    If b <= b_rest then b := b_rest + 1e-5;
    If b >= b_sat then b := b_sat - 1e-5;

    b_rel:= (b-b_rest)/(b_sat-b_rest);
    z1:= 1-power(b_rel, 1/m_par);

    z2:= power(z1, m_par);
    //z3:= power(z1, -m_par);
    z3 := 1/z2;
    z4:= z3+z2-2;
    z5:= ((1-m_par)*Ks)/(alpha*m_par*(b_sat-b_rest));
    z6:=power(b_rel, l_par-(1/m_par));
    z7:= z5*z6;
    Dw_f:= z7*z4;
end;

end.
