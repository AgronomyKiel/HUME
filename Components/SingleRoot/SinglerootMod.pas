unit SinglerootMod;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod;


const
  max_N  = 20;              { Zahl der Kompartimente }
  potenz_f = 0.5;           { Potenz der Funktion zur Einteilung der Kompartimente }
  max_w_aenderung = 0.0001; { maximale Wassergehaltsaenderung in einem Zeitschritt }
  max_n_aenderung = 1e-10;  { maximale Konzentrationsaenderung in einem Zeitschritt }
  max_dt = 0.5;             { Maximale Zeitschrittweite [h] }
  first_dt = 0.05;          { erstes Zeitintervall [h] }


type
    RealArray = Array[1..max_n+2] of real;
    VarArray = Array[1..max_n+2] of TVar;
    StateArray = Array[1..max_n+2] of TState;



  TSinglerootMod = class(TSubmodel)
  private
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }

    Zylinderradius : TVar;
    Zylindervolumen: Tvar;
    Radius_arr     : VarArray;

    Delta_R    : RealArray;
    Abstand    : RealArray;
    Flaeche    : RealArray;
    Flae_Ab    : RealArray;
    Volumen    : RealArray;
    RAD        : RealArray;

    qTheta          : Tvar;
    qWasserflux     : TVar;
    qSurface_thet   : TVar;
    Theta_arr       : VarArray;
    qKonzentra      : TVar;
    qNitrat_flux    : TVar;
    qSurface_konz   : TVar;
    qKonzentra_arr  : VarArray;

    nTheta            : TVar;
    Theta_arr        : VarArray;
    Wassermengen_arr : VarArray;
    Flow_water       : VarArray;
    nKonzentra        : TVar;
    nsum_Nitrat       : TVar;
    nKonzentra_arr    : VarArray;
    nNitratmengen_arr : VarArray;
    Flow_salt        : VarArray;

    b_sat : TPar;
    b_rest: TPar;
    Ks    : TPar;
    alpha : TPar;
    n_par : TPar;
    m_par : TPar;
    l_par : TPar;

    Ar,
    quasi_Ar,
  WL,
  L,             { Wurzellänge in cm/ha       }
  Root_area_ha,
    Mg,
    quasi_mg,
    Cl,
    quasi_Cl,
  avg_Transpi_rate,
  quasi_avg_Transpi_rate,
  Transpi_rate,
  quasi_Transpi_rate,
  Wassermenge,
  quasi_Wassermenge,
  quasi_NO3_Menge,
  NO3_Menge,
  Minr_ha_d,
  Min_mol_cm3_sec,
  a_avg,
  q_a_avg,
  e_avg,
  q_e_avg,
  sum_w_bilanzflr,
  sum_n_bilanzflr,
  PWP

     : TVar;


    Ar_soll,
    Tiefe,
    Clamin,
    iniMg,
      Lrv,

  potenz_f = 0.5;           { Potenz der Funktion zur Einteilung der Kompartimente }
  max_w_aenderung = 0.0001; { maximale Wassergehaltsaenderung in einem Zeitschritt }
  max_n_aenderung = 1e-10;  { maximale Konzentrationsaenderung in einem Zeitschritt }
  max_dt = 0.5;             { Maximale Zeitschrittweite [h] }
  first_dt = 0.05;          { erstes Zeitintervall [h] }

    Wurzelradius   : TPar;


     : Tpar;


  int_dt,
  Clr,

  Ausgabezeit,
  tausg,


  Wasser_konk,
  nitrat_konk,
  Sinus_func,
  no_mflw            : Toption;


  profile, prof_f :text;

  procedure Init(var GlobMod: Tmod); override;
  procedure CalcRates; override;
  procedure CreateAll; overrride;

  published
    { Published-Deklarationen }
  end;

procedure Register;

implementation

procedure TSinglerootMod.CreateAll;

begin

end;


procedure TSinglerootMod.Init(var GlobMod: Tmod); override;

begin
  n_var_rec.Konzentra  := Cli_func(Mg, Tiefe, n_var_rec.Theta);
  q_var_rec.Konzentra  := n_var_rec.Konzentra;
  Clamin               := Clamin * 1e-6;
  Cl                   := n_var_rec.Konzentra * 1e6;
  quasi_cl             := Cl;
  L                  := Wl*1e9;           { Wurzell„nge in cm/ha              }
  Root_area_ha       := Area_func(L, q_geo_rec.Wurzelradius);         { Wurzeloberfl„che in cm2/ha        }
  Lrv                := Lrv_func(Wl, Tiefe);
  q_geo_rec.Zylinderradius  := Abstand_func(Lrv);
  q_geo_rec.Zylindervolumen := volumen_func(q_geo_rec.Zylinderradius, q_geo_rec.Wurzelradius);
  NO3_Menge          := n_var_rec.Konzentra*q_var_rec.Theta*q_geo_rec.Zylindervolumen;
  Wassermenge        := q_var_rec.Theta*q_geo_rec.Zylindervolumen;
  quasi_NO3_Menge    := NO3_Menge;
  quasi_Wassermenge  := Wassermenge;
  Min_mol_cm3_sec    := Min_mol_cm3_sec_func (
                        Minr_ha_d, Tiefe);



  with n_geo_rec, q_geo_rec, n_var_rec do begin
    find_rad_arr ( zylinderradius, wurzelradius, potenz_f,
                         max_n,
                         rad);

    For I := 1 to max_n+1 do
     Delta_R[i]:= Rad[i+1] - Rad[i];

    For i := 2 to max_n+1 do
      Abstand[i] := (delta_R[i-1]+delta_R[i])/2;

    Flaeche[1] := 2 * PI * Rad[1];
    For I := 2 to max_N+2 do begin
      Volumen[I-1]   := PI*sqr(Rad[I]) - PI*sqr(Rad[I-1]);
      Flaeche[I] := 2 * PI * Rad[I];
    end;


  For i := 1 to max_N+1 do begin
    n_var_rec.Konzentra_arr[i] := n_var_rec.Konzentra;
    n_var_rec.Theta_arr[i]   := n_var_rec.Theta;
    n_var_rec.flow_water[i]  := 0.0;
    n_var_rec.flow_salt[i]   := 0.0;
  end;

 For i := 1 to max_N do begin
   n_var_rec.Wassermengen_arr[i] := N_var_rec.Theta_arr[i]*n_geo_rec.volumen[i];
   n_var_rec.Nitratmengen_arr[i] := n_var_rec.Konzentra*
   n_var_rec.Wassermengen_arr[i];
 end;


end;


procedure TSinglerootMod.CalcRates;

begin


{------------------- quasistation„re L”sung ------------------------}

  q_var_rec.wasserflux := Water_flow_func (avg_transpi_rate, L,
                                               Time_rec.Stunden, sinus_func);
  q_var_rec.Nitrat_flux    := NO3_Flow_func ( Ar_soll, L);

  quasi_Wasser (q_geo_rec,
                Dw_par_rec,
                PWP,
                max_N+1,
                q_var_rec);

  quasi_Nitrat (q_geo_rec,
               Clamin,
               max_n+1,
               q_var_rec);

{------------------------- Bilanz -----------------------------}

  with q_geo_rec, q_var_rec do begin
      q_Bilanz (Wasser_konk, const_theta, Nitrat_konk,
                Zylinderradius, Wurzelradius, Tiefe, dt,
                Wasserflux, Nitrat_flux,
                Min_mol_cm3_sec,
                quasi_Wassermenge, Theta,
                quasi_NO3_Menge, quasi_Mg, L, Konzentra,
                quasi_Transpi_rate, quasi_Ar);
  end;

{----------------------------------------------------------------}



    num_solut (  Wasser_konk, Nitrat_konk, const_theta,
                 max_N,
                 avg_transpi_rate, Ar,
                 Min_mol_cm3_sec,
                 Clamin, L,
                 Dw_par_rec,
                 n_geo_rec,
                 dt,
                 time_rec,
                 n_var_rec);

    num_Bilanz ( max_N,
                  dt, Tiefe, L,
                  q_geo_rec,
                  n_var_rec,
                  Mg,Transpi_rate, Ar);



end;





Procedure num_solut  (  Wasser_konk, Nitrat_konk, const_theta: boolean;
                         max_N :  byte;
                         avg_transpi_rate,
                         Aufrate,
                         Min_rate,
                         Clamin, Laenge : real;
                         Dw_par_rec              : gen_par_rec_type;
                         n_geo_rec               : n_geo_rec_typ;
                     var dt                      : real;
                     var time_rec                : time_rec_typ;
                     var n_var_rec               : n_var_rec_typ);


var
  Theta_alt,
  Flw_alt,
  Konzentra_alt,
  flw_save : Array_type;

  avg_w_bilanzfehler, max_w_bilanzflr,
  akt_max_w_delt, akt_max_n_delt,
  avg_n_bilanzfehler, max_n_bilanzflr : real;
  Start  : integer;

procedure get_bilanz ( flow_arr, konz_alt,
                       konz_neu, kapaz_arr, Vol_arr : array_type;
                       Prod_rate,
                       num_dt              : real;
                       n_comp : integer;
                   var sum_bilanzflr, max_bilanzflr,
                       max_aender : real );

var
  net_flow, sum_net_flow,
  d_Mass, sum_aender  : real;

begin
  max_aender       := 0.0;
  sum_aender       := 0.0;
  sum_net_flow     := 0.0;
  max_bilanzflr := 0.0;
  For I := 1 to n_comp do begin
    net_flow := (flow_arr[i] - flow_arr[i+1] - Prod_rate*Vol_arr[i])*num_dt;
    d_Mass    := (konz_alt[i]-konz_neu[i])*Kapaz_arr[i];
    If abs(d_Mass+net_flow) > max_bilanzflr then
          max_bilanzflr := abs(d_Mass-net_flow);
    If abs(d_Mass) > max_aender then
          max_aender := abs(d_Mass);
    sum_aender   := sum_aender + d_Mass;
    sum_net_flow := sum_net_flow + net_flow;
  end;
  sum_bilanzflr := sum_aender + sum_net_flow;
end;



procedure  get_new_dt ( max_w_aender, max_n_aender,
                        akt_w_max_aender, akt_n_max_aender,
                        max_dt : real;
                    var dt : real);

var
  dt_neu_w, dt_neu_n : real;

procedure get_dt (max_poss_aender, akt_aender, max_dt: real;
                     var dt : real);
var
  dt_neu : real;

begin
  If akt_aender <> 0.0 then begin
    dt_neu := (max_poss_aender/akt_aender)*dt;
    If dt_neu > max_dt then dt_neu := max_dt;
    if dt_neu > 1.2*dt then dt_neu := dt*1.2;
    dt := dt_neu;
  end;
end;

begin
  dt_neu_n := dt;
  get_dt ( max_n_aender, akt_max_n_delt, max_dt,
           dt_neu_n);
  If NumWater then begin
    dt := dt_neu_n;
    dt_neu_w := dt;
    get_dt ( max_w_aender, akt_max_w_delt, max_dt,
             dt_neu_w);
     If dt_neu_w < dt_neu_n then
       dt := dt_neu_w
  end
  else dt := dt_neu_n;
end;

{$I trdiag.pas} { Funktion Trdiag zum l”sen eines triadiagonalen
                  Gleichungssystems }


{$I SIROWAT.INC}

Procedure num_salt_solut (Nitrat_konk            : boolean;
                          max_N                  : integer;
                          Aufrate,
                          Min_rate,
                          Clamin, Laenge,
                          num_dt                  : real;
                          Theta_alt               : Array_type;
                          n_geo_rec               : n_geo_rec_typ;
                      var n_var_rec               : n_var_rec_typ);


var
  Db,                        { Diffusionskoeffizient innerhalb eines Kompartiments}
  Db_alt,                    { dito, alter Zeitschritt }
  avgDb,                     { mittlerer Diffusionskoeffizient zwischen zwei Kompartimenten}
  avgDb_alt,                 { dito, alter Zeitschritt }
  b1, b2, b3, b4, B_vektor,  { bekannte Gr”áen bzw. L”sungsvektor }
  Db_fact,
  Db_alt_fact,
  Flw_n_fact,
  Flw_alt_fact,
  old_konz,
  lower,
  diag,
  upper
            : Array_type;

  Inflow,
  Outflow
            : real;

  Start
            : integer;
  result    : byte;
  success   : boolean;

Procedure Leitfaehigkeiten;

begin
 with N_var_rec, N_geo_rec do begin
   For  I:= 1 to max_N+1 do begin
     Db[i]     := dbf (Theta_arr[i]);
     Db_alt[i] := dbf (Theta_alt[i]);
   end;

   For I := 2 to max_N+1 do begin
     avgDb[i-1]            := ( Db[i] + Db[i-1]) / 2;
     avgDb_alt[i-1]        := ( Db_alt[i] +  Db_alt[i-1] ) / 2;
     Db_fact[i-1]     := avgDb[i-1]*Flaeche[i]/Abstand[i]*num_dt/2;
     Db_alt_fact[i-1] := avgDb_alt[i-1]*Flaeche[i]/Abstand[i]*num_dt/2;
     Flw_n_fact[i]      := Flow_water[i]*num_dt/4;
     Flw_alt_fact[i]    := Flw_alt[i]*num_dt/4;
   end;
 end;
end;


function Flow_f ( Flaeche, Cond, C, C_1, Abst, FLW : real):real;


{ Funktion zur Berechnung des Fluáe durch Diffusion und Massenfluá
  zwischen zwei Kompartimenten


Parameter            Bedeutung                    Einheit

Flaeche                                           [cm2]
Cond                 Diffusionskoeffizient        [cm2/s]
C                    Konzentration                [mol/cm3]
C_1                  Konzentration im
                     wurzeln„heren Kompartiment   [mol/cm3]
Abst                 Abstand der Kompartiment-
                     mittelpunkte                 [cm]
FlW                  Wasserfluá                   [cm3/s]

}


var
  Diff_flow,        { Fluá durch Diffusion }
  Mass_flow         { Fluá durch Massenfluá }
            : real;

begin
  Diff_flow := Flaeche*Cond*(C-C_1)/Abst;
  Mass_flow := 0.5*FLW*(C+C_1);
  Flow_f    := Diff_flow+Mass_flow;
end;



Procedure innere_Randbedingung;

begin
  with N_var_rec, N_geo_rec do begin
    If success = false then begin
      success := true;
      Start := 2;
      Konzentra_arr[1] := Clamin;
      Inflow := Flow_f( Flaeche[3], avgDb_alt[2],
                        Konzentra_arr[3],Konzentra_arr[2], Abstand[3],
                        Flw_alt[3]);
      Outflow := Flow_f( Flaeche[2], avgDb_alt[1],
                        Konzentra_arr[2], Clamin, Abstand[2],
                        Flw_alt[2]);

      B_vektor[2]  := Nitratmengen_arr[2] / Wassermengen_arr[2]
                      + 0.5*(Inflow-Outflow)*num_dt/ Wassermengen_arr[2]
                      + (Konzentra_arr[1]*(Db_fact[1]-Flw_n_fact[2]))/Wassermengen_arr[2]
                      + Min_rate*Volumen[2]*num_dt/Wassermengen_arr[2];
      Diag[2]  :=  (Db_fact[2] + Db_fact[1]
                        + Flw_n_fact[2] - Flw_n_fact[3])/Wassermengen_arr[2]+1;
      Upper[2] :=  (- Db_fact[2] - Flw_n_fact[3])/Wassermengen_arr[2];
    end else begin
      Start := 1;
      Flow_salt[1] := NO3_flow_func (Ar_soll, L);
      Inflow := Flow_f( Flaeche[2], avgDb_alt[1],
                        Konzentra_arr[2],Konzentra_arr[1], Abstand[2],
                        Flw_alt[2]);

      B_vektor[1] := (Nitratmengen_arr[1] - Flow_salt[1]*num_dt
                          + Inflow*0.5*num_dt
                          + Min_rate*Volumen[1]*num_dt)
                          /Wassermengen_arr[1];
      diag[1]  :=  (Db_fact[1] - Flw_n_fact[2])/Wassermengen_arr[1] + 1;
      upper[1] := (-Db_fact[1] - Flw_n_fact[2])/Wassermengen_arr[1];
    end;
  end;
end;

Procedure Mittelteil;

begin
  with N_var_rec, N_geo_rec do begin
    For I := Start+1 to max_N-1 do begin
      Inflow  := Flow_f( Flaeche[i+1], avgDb_alt[i],
                        Konzentra_arr[i+1],Konzentra_arr[i], Abstand[i+1],
                        Flw_alt[i+1]);
      Outflow := Flow_f( Flaeche[i], avgDb_alt[i-1],
                        Konzentra_arr[i], Konzentra_arr[i-1], Abstand[i],
                        Flw_alt[i]);
      B_vektor[i]  := Nitratmengen_arr[i]/Wassermengen_arr[i]
                      + 0.5*(Inflow-Outflow)*num_dt/ Wassermengen_arr[i]
                      + min_rate*volumen[i]*num_dt/Wassermengen_arr[i];

      Lower[i] := (-Db_fact[i-1] + Flw_n_fact[i])/Wassermengen_arr[i];
      Diag[i]  := ( Db_fact[i] + Db_fact[i-1]
                      + Flw_n_fact[i] - Flw_n_fact[i+1])/Wassermengen_arr[i]+1;
      Upper[i] := (-Db_fact[i] - Flw_n_fact[i+1])/Wassermengen_arr[i];
    end;
  end;
end;


Procedure aeussere_Randbedingung;

begin
  with N_var_rec, N_geo_rec do begin
    If Nitrat_konk = true then begin
      Outflow := Flow_f( Flaeche[max_n], avgDb_alt[max_n-1],
                        Konzentra_arr[max_n], Konzentra_arr[max_n-1], Abstand[max_n],
                        Flw_alt[max_n]);
      B_vektor[max_n] := Nitratmengen_arr[max_n]/Wassermengen_arr[max_n]
                          + 0.5*(-Outflow)*num_dt/ Wassermengen_arr[max_n]
                          + min_rate*volumen[max_n]*num_dt/Wassermengen_arr[max_n];

      Lower[max_n] := (-Db_fact[max_n-1] + Flw_n_fact[max_n])/Wassermengen_arr[max_n];
      Diag[max_n]  := ( Db_fact[max_n-1] + Flw_n_fact[max_n])/Wassermengen_arr[max_n]+1;
    end else begin
       Inflow  := Flow_f( Flaeche[max_n+1], avgDb_alt[max_n],
                        Konzentra_arr[max_n+1],Konzentra_arr[max_n], Abstand[max_n+1],
                        Flw_alt[max_n+1]);

       Outflow := Flow_f( Flaeche[max_n], avgDb_alt[max_n-1],
                        Konzentra_arr[max_n], Konzentra_arr[max_n-1], Abstand[max_n],
                        Flw_alt[max_n]);
       B_vektor[max_n]  := Nitratmengen_arr[max_n]/Wassermengen_arr[max_n]
                      + 0.5*(Inflow-Outflow)*num_dt/ Wassermengen_arr[max_n]
                      + Konzentra_arr[max_n+1]*(Db_fact[max_n]+Flw_alt_fact[max_n+1])/Wassermengen_arr[max_n]
                      + min_rate*volumen[max_n]*num_dt/Wassermengen_arr[max_n];

       Lower[max_n] := (-Db_fact[max_n-1] + Flw_n_fact[max_n])/Wassermengen_arr[max_n];
       Diag[max_n]  := ( Db_fact[max_n] + Db_fact[max_n-1]
                       + Flw_n_fact[max_n] - Flw_n_fact[max_n+1])/Wassermengen_arr[max_n]+1;

    end;
 end;
end;

procedure Loesung_Gleichungssystem;


begin
  with n_var_rec, n_geo_rec do begin
    result := trdiag (false, max_n, start,
                   lower,  diag, upper,
                   b_vektor);
    If result <> 0 then begin
      closegraph;
      restorecrtmode; clrscr;
      put_error(' Fehler beim l”sen des Gleichungssystems ! ', 12,20);
      antwort := readkey;
      repeat until keypressed; halt;
    end;
    If (Start = 1) and (b_vektor[start] <= Clamin) then
      success := false;
    If Success then for I := start to max_n do
      Konzentra_arr[i] := b_vektor[i];
  end;
end;



procedure find_flows;

var
  flow_new, flow_alt : real;

begin
  with n_var_rec, n_geo_rec do begin
    for i := 2 to max_n+1 do begin
      flow_alt :=  Flow_f ( Flaeche[i],avgDb_alt[i-1],Konzentra_alt[i],
                            Konzentra_alt[i-1], Abstand[i],flw_alt[i]);
      flow_new :=  Flow_f ( Flaeche[i], avgDb[i-1],Konzentra_arr[i],
                            Konzentra_arr[i-1], Abstand[i], Flow_water[i]);
      flow_salt[i]  := (flow_alt+flow_new)/2;
    end;
    If Konzentra_arr[1] <= Clamin then
         Flow_salt[1] := flow_salt[2]
                      {+min_rate*volumen[1]*num_dt/Wassermengen_arr[1]
                      +(Konzentra_alt[1]-Clamin)*Wassermengen_arr[1]/num_dt};
    If Flow_salt[1] > NO3_flow_func (Ar_soll, L) then
      Flow_salt[1] := NO3_flow_func (Ar_soll, L);

  end;
end;


procedure set_new_state_var;

begin
  with n_var_rec, n_geo_rec do begin
    For I := 1 to max_n do
      Nitratmengen_arr[i] := Konzentra_arr[i] * Wassermengen_arr[i];

    If Nitrat_konk = true then
       Konzentra_arr[max_n+1] := Konzentra_arr[max_n];
  end;
end;


begin
  with n_var_rec, n_geo_rec do
   begin
     success := true;
     Leitfaehigkeiten;
     repeat
       innere_Randbedingung;
       Mittelteil;
       aeussere_Randbedingung;
       Loesung_Gleichungssystem;
       find_flows;
     until success;
     get_bilanz ( flow_salt, konzentra_alt,
                  konzentra_arr, wassermengen_arr, Volumen, Min_rate,
                  num_dt,
                  max_n,
                  sum_n_bilanzflr, max_n_bilanzflr,
                  akt_max_n_delt);
     set_new_state_var;

   end;
end;


{--------------------------------------------------------------------------}


procedure save_old_vars;

begin
  Theta_alt := n_var_rec.Theta_arr;
  Flw_alt   := n_var_rec.flow_water;
  Konzentra_alt := n_var_rec.Konzentra_arr;
end;


{--------------------------------------------------------------------------}

procedure InitWFlows;

var
  flow_w, sum_w : real;
  i : byte;

begin
  with N_var_rec do begin
    flow_w := water_flow_func (avg_transpi_rate, L,
                                             time_rec.stunden, sinus_func);
    sum_water  := sum_water-flow_w*dt*3600;
    theta      := sum_water/q_geo_rec.zylindervolumen;
    For I := 1 to max_n do begin
      flow_water[i] :=  flow_w;
      theta_arr[i]  := theta;
      wassermengen_arr[i]  := theta_arr[i]*n_geo_rec.volumen[i];
    end;
    If Wasser_Konk then n_var_rec.flow_water[max_n+1] := 0.0;
  end;
end;

{--------------------------------------------------------------------------}

begin { Prozedur}

     save_old_vars;

     If NumWater then

     num_wat_solut (Wasser_konk, const_theta,
                    max_N,
                    avg_transpi_rate, Laenge,
                    Dw_par_rec,
                    n_geo_rec,
                    time_rec,
                    Theta_alt,
                    dt*3600.0,
                    n_var_rec)
     else InitWFlows;

     If no_mflw then begin
       flw_save := n_var_rec.flow_water;
       for I := 1 to max_n + 2 do begin
         n_var_rec.flow_water[i] := 0.0;
         flw_alt[i] := 0.0;
       end;
     end;



      num_salt_solut (Nitrat_konk,
                     max_N,
                     Aufrate,
                     Min_rate,
                     Clamin, Laenge, dt*3600.0,
                     Theta_alt,
                     n_geo_rec,
                     n_var_rec);

     If no_mflw then
       n_var_rec.flow_water := flw_save;


  get_new_dt ( max_w_aenderung, max_n_aenderung,
                        akt_max_w_delt, akt_max_n_delt,
                        max_dt,
                        dt);

END;

{--------------------------------------------------------------------------}

function Imax (Cli, clamin, Db, v, xl, a :real): real;

var
   x, x1, x2, y, z1: real;

 begin
 If cli-clamin <= 0.0 then imax := 0.0 else
  x1:= 2/(2-(a*v)/Db);
  x2:= Potenz(xl/a, 2-(a*v)/Db) - 1;
  x:= x1 * x2;
  y:= Potenz( xl/a, 2) - 1;
  z1:= x/y;
  Imax:= (Cli*2*pi*a*v - 2*pi*a*Clamin*v*z1) / (1-z1)
 end;

function v0Imax (Cli, Clamin, Db, xl, a: real):real;

begin
  If cli-clamin < 0.0 then v0imax := 0.0 else
  v0Imax := ((Cli-Clamin)*2*pi*Db)/(ln(xl/(1.65*a)));
end;


function Iwmax (b, bmin, Dw, xl, a: real):real;

begin
  If (b-bmin < 0.0) then Iwmax := 0.0 else
  Iwmax := ((b-bmin)*2*pi*Dw)/(ln(xl/(1.65*a)));
end;



function Claf (Inflow, Cli, v, a, Db, xl: real):real;

var
  x, x1, x2, y, z1, z2: real;

begin

 x1:= 2/(2-(a*v)/Db);
 x2:= Potenz(xl/a, 2-(a*v)/Db) - 1;
 x:= x1 * x2;
 y:= Potenz( xl/a, 2) - 1;
 z1:= Inflow/(2*Pi*a*v);
 z2:=  y / x ;
 Claf:= Cli * z2 - z1 * z2 + z1;

end;

function v0Claf(Inflow, Cli, Db, xl, a:real):real;

begin
  v0Claf:= Cli-(Inflow/(2*pi*Db)*ln(xl/(1.65*a)));
end;


function baf (b, Iw, Dw, xl, a:real):real;

begin
  baf:= b-(Iw/(2*pi*Dw)*ln(xl/(1.65*a)));
end;

function Clrnf (Cla, Inflow, v, a, Radius, Db:real):real;

var
 z1, z2, z3: real;

begin
 Z1   := (a*v)/Db;
 Z2   := potenz(Radius/a, -z1);
 Z3   := Inflow/(2*pi*a*Cla*v);
 Clrnf:= Cla*(Z3+(1-Z3)*z2);
end;

function v0Clrnf (Inflow, Cla, Db, Radius, a:real):real;

 begin
   v0Clrnf := Cla+Inflow/(2*pi*Db)*ln(Radius/a);
 end;

function bnf (ba, Iw, Dw, Radius, a:real):real;
 begin
   bnf := ba+Iw/(2*pi*Dw)*ln(Radius/a);
 end;


Procedure quasi_wasser ( q_geo_rec  : q_geo_rec_typ;
                         Dw_par_rec : gen_par_rec_type;
                         PWP        : real;
                         quasi_n    : integer;
                     var q_var_rec  : q_var_rec_typ);


var
 Diffu_wasser, Dummy : real;

begin
 with q_geo_rec, q_var_rec, dw_par_rec do begin
   Diffu_wasser := Dw_f(Theta, Dw_par_rec)/86400.0;
  {Diffu_wasser := 8.6e4*exp(45.6*(theta-0.395))/86400;}

   Dummy := baf (Theta, Wasserflux, Diffu_wasser,
               Zylinderradius, Wurzelradius);

   If (Dummy <= PWP) then begin
     Wasserflux := Iwmax(Theta, PWP, Diffu_wasser, Zylinderradius, Wurzelradius);
     Surface_Thet := PWP;
     for I := 1 to quasi_n do
         Theta_arr[i]  := bnf ( Surface_Thet, Wasserflux, Diffu_wasser,
                            Radius_arr[i], Wurzelradius);
   end
   else begin
     Surface_thet := baf (Theta, Wasserflux,Diffu_wasser, Zylinderradius, Wurzelradius);
     for I := 1 to quasi_n do
       Theta_arr[i]  := bnf ( Surface_thet, Wasserflux,Diffu_wasser, Radius_arr[i], Wurzelradius);
    end;
  end;
end;


{$IFNDEF wg}

Procedure quasi_Nitrat (q_geo_rec: q_geo_rec_typ;
                         Clamin   : real;
                        quasi_n : Integer;
                    var q_var_rec: q_var_rec_typ);

var
  Db, v : real;


begin   { Procedure }

 with q_geo_rec, q_var_rec  do
   begin                      { With-Statement }
    Db := dbf(Theta);
    v := Wasserflux/(2*Pi*Wurzelradius);

    If Wasserflux <= 0 Then
     begin
      If (v0Claf(Nitrat_flux, Konzentra, Db,
           Zylinderradius, Wurzelradius) <= Clamin) then
        begin
          Nitrat_flux := v0Imax(Konzentra, Clamin, Db, Zylinderradius,
                                 Wurzelradius);
          Surface_konz := Clamin;

          For I   := 1 to quasi_n do
            begin
             Konzentra_arr[i] := v0Clrnf(Nitrat_flux, Surface_konz, Db,
                                          Radius_arr[i], Wurzelradius);
            end;
        end
      else
      begin
        Surface_konz := v0Claf(Nitrat_flux, Konzentra, Db, Zylinderradius,
                                           Wurzelradius);

        For I := 1 to quasi_n do
          begin
            Konzentra_arr[i] := v0Clrnf(Nitrat_flux, surface_konz, Db,
                                     Radius_arr[i], Wurzelradius);
          end;
      end;
    end
  else          { If Transpi > 0 }
  begin
    If Claf(Nitrat_flux, Konzentra, v, Wurzelradius , Db,
                                Zylinderradius) <= Clamin then
    begin

     Nitrat_flux := Imax(Konzentra, Clamin, Db, v, Zylinderradius,
                             Wurzelradius);

     Surface_konz := Clamin;
     For I   := 1 to quasi_n do
       begin
         Konzentra_arr[i] := Clrnf(Surface_konz, Nitrat_flux, v,
                                   wurzelradius, Radius_arr[i], Db);
       end;
   end
   else
    begin
      Surface_konz := Claf(Nitrat_flux, Konzentra, v,
                             Wurzelradius, Db, Zylinderradius);

      For I := 1 to quasi_n do
       begin
        Konzentra_arr[i] := Clrnf(Surface_konz, Nitrat_flux, v,
                                    Wurzelradius, Radius_arr[i], Db);

        end;
     end;   { Cla > Clamin }
    end;  { Transpi > 0 }
   end;  { With statement }
 end;  { Prozedure }
{$ENDIF}





procedure Register;
begin
  RegisterComponents('Simulation', [TSinglerootMod]);
end;

end.
