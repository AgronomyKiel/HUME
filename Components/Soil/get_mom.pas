{*******************************************************************
 *******************************************************************
 *****   Unit get_mom                                          *****
 *****                                                         *****
 *****   Autor   : H.Kage                                      *****
 *****   Zweck   : Erzeugung eines Arrays mit Momenten         *****
 *****             einer lognormal Verteilten Grundgesamt-     *****
 *****             heit zur stochastischen Simulation          *****
 *****   letzte Bearbeitung : 18.11.89                         *****
 *****                                                         *****
 *****   Literatur : Anlauf et al. (1988)                      *****
 *****               Modelle fÅr Prozesse im Boden             *****
 *******************************************************************
 *******************************************************************}


unit get_mom;


interface

const

  { Values calculated with Excel: }
  z_5 = 1.6448534756699800;
  z_15 = 1.0364334736256900;
  z_25 = 0.6744895256679870;
  z_35 = 0.3853206036265890;
  z_45 = 0.1256612463220620;

  { Excel values for 20 classes:
  if this should be implmented, the z_moments initialisation
  has to be adopted}
  z_475 = 0.062706777943;
  z_425 = 0.189118426273;
  z_375 = 0.318639363964;
  z_325 = 0.453762190170;
  z_275 = 0.597760126042;
  z_225 = 0.755415026360;
  z_175 = 0.934589291073;
  z_125 = 1.150349380376;
  z_075 = 1.439531470938;
  z_025 = 1.959963984540;


//  Z_d_Momente = 10;
  Z_d_Momente = 20;

  type


{ Folgende Konstanten und Typvereinbarungen mÅssen zur Compilation
  getroffen sein : }


    moment_arr_type = array[0..Z_d_Momente-1] of real;


const
{    z_moments : moment_arr_type = (-z_5, -z_15, -z_25,-z_35, -z_45,
                                 z_45, z_35, z_25, z_15, z_5);     }
// in case Z_d_Momente = 20

    z_moments : moment_arr_type = (-z_025, -z_075, -z_125,-z_175, -z_225,
                                   -z_275, -z_325, -z_375,-z_425, -z_475,
                                   z_475, z_425, z_375, z_325, z_275,
                                   z_225, z_175, z_125, z_075, z_025);


{$IFDEF CPU87}
Type
  real = extended;
{$ENDIF}




procedure get_par_moments ( mean, VK : real;
                            z_moments: array of real;
                      var par_moments : moment_arr_type);

{ ********************************************************************** }
{ Zweck : Berechnung der Werte von 10 Momenten einer lognormal verteilten
          Grundgesamtheit mit den SummenhÑufigkeiten 5, 10, 15,... Prozent
          aus dem Mittelwert und dem Variationskoeffizienten des Parameters.
          Die Berechnung erfolgt durch Transformation aus dem
          Konstanten-Array "z_Moments"

  Parameter :

    Name             Inhalt                          Einheit      Typ
    mean             Mittelwert des                  -            I
                     Parameters

    Vk               Variationskoeffizient            [%]         I   }



{ ********************************************************************** }

procedure get_npar_moments ( mean, VK : real;
                        var par_moments : moment_arr_type);
{ ********************************************************************** }
{ Zweck : Berechnung der Werte von 10 Momenten einer normalverteilten
          Grundgesamtheit mit den SummenhÑufigkeiten 5, 10, 15,... Prozent
          aus dem Mittelwert und dem Variationskoeffizienten des Parameters.
          Die Berechnung erfolgt durch Transformation aus dem
          Konstanten-Array "z_Moments"

  Parameter :

    Name             Inhalt                          Einheit      Typ
    mean             Mittelwert des                  -            I
                     Parameters

    Vk               Variationskoeffizient            [%]         I   }



{ ********************************************************************** }



implementation


function SA_f ( mean, VK : real):real;
{ ********************************************************************** }
{ Zweck : Berechnung der Standardabweichung

  Parameter :

    Name             Inhalt                          Einheit      Typ
    mean             Mittelwert                                   I
    VK               Variationskoeffizient                        I

    SA_f             Standardabweichung                           O  }

{ ********************************************************************** }



begin
  SA_f := VK*mean/100;
end;

function transform_f( mean_ln, SA_ln, z:real):real;
{ ********************************************************************** }
{ Zweck : Transformation eines Wertes z aus der Standardnormalverteilung
          (Mittelwert 0, Standardabweichung 1) in den entsprechenden Wert
          der lognormal verteilten Grundgesamtheit mit Mittelwert (mean_ln)
          und der Standardabweichung (SA_ln) der log-transformierten Werte

  Parameter :

    Name             Inhalt                          Einheit      Typ
    Mean_ln          Mittelwert der log-                          I
                     transformierten Grundgesamtheit
    SA_ln            Standardabweichung der logtrans-
                     formierten Grundgesamtheit                   I
    z                Wert aus der Standardnormal-                 I
                     verteilung

    transform_f      entsprechender Wert aus der log-
                     normal verteilten Grundgesamtheit            O }

{ ********************************************************************** }


begin
  transform_f := exp(z*SA_ln+mean_ln);
end;

function SA_ln_f(mean, SA:real):real;
{ ********************************************************************** }
{ Zweck : Berechnung der Standardabweichung der logtransformierten Werte
          aus dem Mittelwert und der Standardabweichung der nicht
          transformierten Werte

  Parameter :

    Name             Inhalt                          Einheit      Typ

    mean             Mittelwert                                   I
    SA               Standardabweichung                           I

    SA_ln_f          Standardabweichung der log-
                     transformierten Werte                        O}

{ ********************************************************************** }


begin
  SA_ln_f := sqrt(ln((SA*SA)/(mean*mean)+1));
end;

function mean_ln_f (mean, SA_ln:real):real;
{ ********************************************************************** }
{ Zweck : Berechnung des Mittelwertes der log-transformierten
          Werte aus dem Mittelwert der nicht transformierten Werte
          und der Standardabweichung der der log-transormierten Werte

  Parameter :

    Name             Inhalt                          Einheit      Typ

    mean             Mittelwert (nicht transformiert)             I
    SA_ln            Standardabweichung (transformiert)           I

    mean_ln_f        Mittelwert (transformiert)                   O}

{ ********************************************************************** }


begin
  mean_ln_f := ln(mean)-0.5*SA_ln*SA_ln;
end;


procedure get_par_moments ( mean, VK : real;
                            z_moments : array of real;
                        var par_moments : moment_arr_type);

{const
  z_5  = 1.64486;
  z_15 = 1.03644;
  z_25 = 0.674492;
  z_35 = 0.385322;
  z_45 = 0.125663;

  z_moments : moment_arr_type = (-z_5, -z_15, -z_25,-z_35, -z_45,
                                 z_45, z_35, z_25, z_15, z_5);  }



var
  i : integer;


var
  SA, SA_ln, mean_ln:real;

begin
  SA := SA_f(mean, VK);
  SA_ln := SA_ln_f(mean,SA);
  mean_ln := mean_ln_f(mean, SA_ln);
  For I := low(z_moments) to high(z_moments) do begin
    par_moments[i] := transform_f(mean_ln, SA_ln, z_moments[i]);
  end;
end;



procedure get_npar_moments ( mean, VK : real;
                        var par_moments : moment_arr_type);


var
  i : integer;


var
  SA:real;

begin
  SA := SA_f(mean, VK);
  For I := 1 to Z_d_Momente do begin
    par_moments[i] := par_moments[i]*SA+mean;
  end;
end;



begin
end.
