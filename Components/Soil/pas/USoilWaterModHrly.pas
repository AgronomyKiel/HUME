unit USoilWaterModHrly; // Neue Komponente

interface

uses
  {UMod,} USoilWaterMod{, IniFiles, UState, ULayeredSoil, UGenucht, classes};

type
  TSoilWaterModHrly = class(TSoilWaterMod)

private

   procedure CapWatSolut; override;
   procedure get_water_contents;
   Procedure Diffwater_solut;


protected
   procedure createAll; override;

public
procedure Init (var GlobMod:Tmod); override;
procedure Integrate; override;
procedure CalcRatesAndIntegrate; override;
procedure CalcRates; override;

end;

procedure Register;

var
  SoilWaterModHrly : TsoilWaterModHrly;

implementation

uses
  SysUtils, Math, Dialogs;



procedure TSoilWaterModHrly.createAll;
begin
  inherited createAll;
end;

Constructor TSoilWaterModHrly.create(AOwner:Tcomponent);
begin
  inherited create(AOwner);
  max_dt := 1/24;
  CreateAll;
end;


procedure TSoilWaterModHrly.Init(Var GlobMod: TMod);
begin
  Inherited Init(GlobMod);
  dt.v := 1/24;
  dt_alt := dt.v;
end;


procedure TSoilWaterModHrly.CalcRates;
begin
  SumOfInternalTimeSteps := 0.0;
//  Act_Evap.V := 0.0;
  repeat
    CalcRatesAndIntegrate;
    SumOfInternalTimeSteps := SumOfInternalTimeSteps+dt.v;
  until SumOfInternalTimeSteps >= self.GlobTime.c;

end;


procedure TSoilWaterModHrly.CapWatSolut;

const
  rep : boolean = false;

var
  psiWP,
  psiFK   : real;
  WCap    : TSoilArray;
  i       : byte;

begin
  if rep = false then begin
    { Berechnung der Wasserspannungen [cm] bei Feldkapazit„t bzw. beim
      permanenten Welkepunkt }
    psiWP := power(10, 4.2);
    psiFK := power(10, 1.8);

    If nFKCalcMethod = input then begin

      If HoriNdx1.v = 0 then begin
    showmessage('Warning ! No specification of Indexes for hydraulic parameters');
    showmessage('Please check !');
  end;

    for i := 1 to round(HoriNdx1.v) do begin
      FK_arr[i]  := par_FK1.v;
      PWP_Arr[i] := par_PWP1.v;
      nFK_arr[i] := par_fk1.v-par_PWP1.v;

   end;

  for i := round(HoriNdx1.v)+1 to round(HoriNdx2.v) do begin
      FK_arr[i]  := par_FK2.v;
      PWP_Arr[i] := par_PWP2.v;
      nFK_arr[i] := par_fk2.v-par_PWP2.v;
   end;

  for i := round(HoriNdx2.v)+1 to round(HoriNdx3.v) do begin
      FK_arr[i]  := par_FK3.v;
      PWP_Arr[i] := par_PWP3.v;
      nFK_arr[i] := par_fk3.v-par_PWP3.v;
   end;

  for i := round(HoriNdx3.v)+1 to n_comp+1 do begin
      FK_arr[i]  := par_FK4.v;
      PWP_Arr[i] := par_PWP4.v;
      nFK_arr[i] := par_fk4.v-par_PWP4.v;
  end;

   end else begin


    for i := 1 to n_comp do begin
      FK_arr[i] := WPar[i].b_psi_f (psiFK);
      PWP_arr[i] := Wpar[i].b_psi_f (psiWP);
      nFK_arr[i] := fk_arr[i]-pwp_arr[i];
      WMenge[i].v := Theta_arr[i].v*Dicke[i];
    end;

    end;
    rep := true;

  end; { Ende Initialisierungssequenz }

  dt.v := GlobTime.c/24;  // bei Kapazitätswassermodell immer 1/24 Zeitschritt des globalen
                          // Modells = stundenweise

  for i := 1 to n_comp+1 do begin
    Theta_arr[i].v := Wmenge[i].v/dicke[i];
    WFlow_arr[i].v := 0.0;
    theta_alt[i] := theta_arr[i].v;
    Wflow_alt[i]  := WFlow_arr[i].v;
  end;

  if (netrain.v > 0.0) then begin
    WFlow_arr[1].v := netrain.v*0.1;
    for I := 1 to n_comp do begin
      WCap[i] := (FK_arr[i]-theta_arr[i].v)*dicke[i];
      If (WCap[i] < WFlow_arr[i].v) then begin       // Saturation ?
        theta_arr[i].v := FK_arr[i];
        WFlow_arr[i+1].v := WFlow_arr[i].v-WCap[i];
      end else begin
        theta_arr[i].v := theta_arr[i].v+WFlow_arr[i].v/dicke[i]*GlobTime.c;
        WFlow_arr[i+1].v := 0.0;
      end;
    end;
  end;
  // evaporation
  theta_arr[1].v := theta_arr[1].v - 0.1*act_evap.v/dicke[1]*GlobTime.c;

  //   water uptake of plant roots
  for i := 1 to n_comp do begin
    theta_arr[i].v := theta_arr[i].v - sink_arr[i].v/dicke[i]*GlobTime.c;
    psi_arr[i].v   := Wpar[i].psi_b_f(theta_arr[i].v);
  end;

end;             { procedure CapWatSolut }

{--------------------------------------------------------------------------}

Procedure TSoilWaterMod.Diffwater_solut;

const
  max_iter_error = 0.0001;

var
  sum_aender,
  sum_net_flow,
  delt_iter_max
   : real;

  iter  : integer;
  result,
  start    : byte;
  wet,                  { S„ttigung im obersten Kompartiment ? }
  dry,                  { Wassergehalt kleiner b_rest im obersten Komp.? }
  success               { Flag-Variable fr fehlerfreie Ausfhrung }
   : boolean;


procedure Leitfaehigkeiten;

var
  i         : byte;

begin

  { lineare Extrapolation der Wassergehalte bei der ersten Iteration }

  If Iter = 0 then begin
    for I := 1 to n_comp do
      est_theta[i+1] := 0.5*(1+dt.v/(2*dt_alt))*(theta_arr[i].v+theta_arr[i+1].v)
                       -0.25*dt.v/dt_alt*(theta_alt[i]+theta_alt[i+1]);


    For I := 2 to n_comp+1 do begin
      avg_Dw[i] := Wpar[i].Dw_f(est_theta[i]);
      avg_Ku[i] := WPar[i].Ku_b_f(est_theta[i]);
    end;

    for I := 2 to n_comp+1 do begin
      Dw_fact[i] := avg_Dw[i]*dt.v/Abst[i-1];
      Ku_fact[i] := avg_Ku[i]*dt.v;
    end;

   end else begin

{ Berechnung der Wasserdiffusivit„t und der unges„ttigten hydraulischen
  Leitf„higkeit fr jedes Kompartiment aus dem Mittelwert der Wassergehalte
  zu Beginn des Zeitschrittes und zum Ende des Zeitschrittes }

    For I := 1 to n_comp+1 do begin
      Dw_arr[i] := WPar[i].Dw_f((theta_neu[i]+theta_arr[i].v)/2.0);
      Ku_arr[i] := WPar[i].Ku_b_f ( (theta_neu[i]+theta_arr[i].v)/2.0);
    end;


{ Berechnung des Mittelwertes der Leitf„higkeit zwischen 2 Kompartimenten }
    For I := 2 to n_comp+1 do begin
      avg_Dw[i] := (Dw_arr[i-1] + Dw_arr[i] )/2.0;
      avg_Ku[i] := (Ku_arr[i-1] + Ku_arr[i] )/2.0;
    end;

    { Berechnung von Koeffizienten fr die Aufstellung des Gleichungssystems,
      Abst.vektor mit dem Index i-1, weil Abstand zwischen erstem und
      zweiten Kompartiment Index 1 hat (verschobene Indizierung }

    For I := 2 to n_comp+1 do begin
      Dw_fact[i] := avg_Dw[i]*dt.v/Abst[i-1];
      Ku_fact[i] := avg_Ku[i]*dt.v;
    end;

   end;
end;

Procedure obere_Randbedingung;

const
  dWg = 1e-8;

{ zur Verhinderung von ungltigen Funktionsaufrufen wird zuerst
  eine Prfung vorgenommen, ob ein Absinken des Wassergehaltes unter den
  "Restwassergehalt b_rest" oder ein Ansteigen ber den "S„ttigungs-
  wassergehalt b_sat" zu erwarten ist. Das Ergebniss dieser Prfung wird
  in den Variablen "Wet", bzw. "Dry" gespeichert. }

begin
    dry := false; wet := false; success := false;

    If (Theta_neu[1] >  Wpar[1].b_sat) and (WFlow_arr[1].v > 0.0) then
      wet := true;  success := false; { Prüfung auf Sättigung }

    If (Theta_neu[1] < WPar[1].b_rest) and (WFlow_arr[1].v < 0.0 ) then
        dry := true; success := false; { Prüfung auf PWP }

    If wet then begin
      b_vektor[1]  := WPar[1].b_sat-dWG;
      theta_arr[1].v := WPar[1].b_sat-dWG;
      theta_neu[1] := WPar[1].b_sat-dWG;
      Start        := 2;
    end;

    If dry then begin
      b_vektor[1] := WPar[1].b_rest+dWG;
      theta_arr[1].v:= WPar[1].b_rest+dWG;
      theta_neu[1]:= WPar[1].b_rest+dWG;
      start       := 2;
    end;

    If (not wet) and (not dry) then begin
      success := true;
      start := 1;
      B_vektor[1] := theta_arr[1].v
                     + WFlow_arr[1].v*dt.v/Dicke[1] - Ku_fact[2]/Dicke[1]
                     - sink_arr[1].v*dt.v/Dicke[1];
      Diag[1]     := Dw_fact[2]/Dicke[1] + 1.0;
      Upper[1]    :=  - Dw_fact[2]/Dicke[1];
    end;
end;

Procedure Mittelteil;
var
  i : integer;

begin
     For i := start+1 to n_comp-1 do begin
       B_vektor[i]  :=  theta_arr[i].v
                        - ku_fact[i+1]/Dicke[i]
                        + ku_fact[i]/Dicke[i]
                        - sink_arr[i].v*dt.v/Dicke[i];
       Lower[i] :=   - Dw_fact[i]/Dicke[i];
       Diag[i]  :=     Dw_fact[i]/Dicke[i] + Dw_fact[i+1]/Dicke[i] + 1.0;
       Upper[i] :=   - Dw_fact[i+1]/Dicke[i];
     end;
end;

procedure untere_Randbedingung;

{ In diesem Fall ist ein vorgegebener unterer Wassergehalt,
  bzw. eine 0-Gradienten Randbedingung vorgegeben }

var
  drain_flow : real;

begin
    If untere_Randb = Content then
                         { Gehalts-Randbedingung }
      B_vektor[n_comp]  := theta_arr[n_comp].v
                          + ku_fact[n_comp]/Dicke[n_comp]
                          - ku_fact[n_comp+1]/Dicke[n_comp+1]
                          + Dw_fact[n_comp+1]*theta_arr[n_comp+1].v/Dicke[n_comp+1]
                          - sink_arr[n_comp].v*dt.v/dicke[n_comp]
    else
                         { Fluß-Randbedingung }
    B_vektor[n_comp]  := theta_arr[n_comp].v
                         + ku_fact[n_comp]/Dicke[n_comp]
                         - WFlow_arr[n_comp+1].v/Dicke[n_comp]
                         - sink_arr[n_comp].v*dt.v/dicke[n_comp];

    Lower[n_comp]     := - Dw_fact[n_comp]/Dicke[n_comp];
    Diag[n_comp]      :=   Dw_fact[n_comp]/Dicke[n_comp]
                           + Dw_fact[n_comp+1]/Dicke[n_comp+1]
                           + 1.0;
end;


procedure Loesung_Gleichungssystem;

var
  I : byte;

begin
    result := trdiag (false, n_comp, start,
                      lower,  diag, upper,
                      b_vektor);
   If result <> 0 then
      ShowMessage( 'Fehler beim Lösen des Gleichungssystems');

    For I := Start to n_comp do begin
       last_iter_theta[i] := theta_neu[i];
       theta_neu[i] := b_vektor[i];
       If theta_neu[i] > Wpar[i].b_sat then theta_neu[i]  := Wpar[i].b_sat;
       If theta_neu[i] < Wpar[i].b_rest then Theta_neu[i] := Wpar[i].b_rest;
    end;
end;

procedure Find_flows;

var
  i : byte;

begin

   If untere_Randb = Content then begin
      For I := 2 to n_comp+1 do begin
        WFlow_arr[i].v := avg_Dw[i]*(theta_neu[i-1] - theta_neu[i])/Abst[i-1]
                       + avg_Ku[i];
        Wflow_alt[i] := avg_Dw[i]*(theta_alt[i-1] - theta_alt[i])/Abst[i-1]
                       + avg_Ku[i];

      end;
    end else begin
      For I := 2 to n_comp do begin
        WFlow_arr[i].v := avg_Dw[i]*(theta_neu[i-1] - theta_neu[i])/Abst[i-1]
                       + avg_Ku[i];
        Wflow_alt[i]   := avg_Dw[i]*(theta_alt[i-1] - theta_alt[i])/Abst[i-1]
                       + avg_Ku[i];

      end;
      {WFlow_arr[n_comp+1] := 0.0;
      flow_alt[n_comp+1] := 0.0;}
   end;

   If (dry and (WFlow_arr[1].v < WFlow_arr[2].v)) or
      (wet and (WFlow_arr[1].v > WFlow_arr[2].v)) then begin
      WFlow_arr[1].v := WFlow_arr[2].v;
           WFlow_alt[1] := WFlow_alt[2];
    end;
end;



procedure get_bilanz ;


{ ********************************************************************** }
{ Zweck : Berechnung der Massenbilanz und der maximalen Wassergehalts-
          „nderung im Simulationszeitschritt

  Parameter :

    Name             Inhalt                          Einheit      Typ
    w_rec            Record mit den Wasserdaten                    I
                     ( siehe Typdefinitionen )
    geo_rec          Record mit den Geometriedaten                 I
    comps            Zahl der Kompartimente           [-]          I

    max_d_WaGe       maximale Wassergehalts„nderung   [cm3/cm3]    O }


{ ********************************************************************** }

var
  i : byte;

  net_flow,              { Netto-Fluá                       [cm] }
  d_WaMe,                { Žnderung der Wassermenge
                           im Kompartiment                  [cm] }
  d_WaGe,                { Žnderung des Wassergehaltes
                           im Kompartiment                  [cm3/cm3] }
  sum_d_WaMe,            { Summe der Wassermengen-
                           „nderungen                       [cm] }
  sum_sink,              {  Summe der Sink-Terme            [cm] }
  max_bilanzfehler       { maximaler Bilanzfehler           [cm] }
                  : real;

  Bilanz_f_arr    : TSoilArray;

begin
   maxAktAenderWaGe:= 0.0;
   sum_d_WaMe      := 0.0;
   sum_sink        := 0.0;
   akt_bilanz_f    := 0.0;
   For I := 1 to n_comp do begin
     net_flow        := (WFlow_arr[i].v - WFlow_arr[i+1].v)*dt.v;
     d_WaMe          := (theta_arr[i].v-theta_neu[i])*Dicke[i];
     d_WaGe          := theta_arr[i].v-theta_neu[i];
     Bilanz_f_arr[i] := d_WaMe + net_flow - Sink_arr[i].v*dt.v;
     akt_bilanz_f    := akt_bilanz_f + Bilanz_f_arr[i];
     If abs(d_WaGe) > maxAktAenderWaGe then
            maxAktAenderWaGe := abs(d_WaGe);
     sum_d_WaMe   := sum_d_WaMe + d_WaMe;
     sum_sink     := sum_sink + sink_arr[i].v*dt.v;
   end;
   sum_Bilanz_f   := sum_bilanz_f + akt_bilanz_f;
end;

procedure get_new_dt;

{ ********************************************************************** }
{ Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verh„ltnisses
           der maximal erlaubten Wassergehalts„nderung zur maximalen aktuellen
           Wassergehalts„nderung

  Parameter :

    Name             Inhalt                          Einheit      Typ

    max_aender       maximal erlaubte Žnderung       [cm3/cm3]    I
                     der Wassergehalte in einem
                     Zeitschritt

    akt_aender       maximale Žnderung des Wasser-   [cm3/cm3]    I
                     gehaltes in einem Kompartiment
                     im letzten Zeitschritt

    dt               Zeitschrittweite                [d]          O
    dt_alt           letzte Zeitschrittweite         [d]          O }

{ ********************************************************************** }

var
  dt_neu : real;

begin
  If MaxaktAenderWaGe <> 0.0 then begin
    dt_alt := dt.v;              { Speicherung der alten Zeitschrittweite }

              { Verhältniss der erlaubten zur aktuellen Wassergehaltsänderung }
    dt_neu := (max_aenderWG/MaxaktAenderWaGe)*dt.v;

    If dt_neu > max_dt then dt_neu := max_dt; { Zu großer Zeitschritt ? }
    if dt_neu > 1.5*dt.v then dt_neu := dt.v*1.5; { Zu großer Zeitschrittsprung ?}

    { Der folgende Algorithmus wurde eingefügt, um Diskontinuitäten bei der
      Verwendung von Eingabedaten auf täglicher Basis zu vermeiden. }
    If SumOfInternalTimeSteps+Dt_neu > GlobTime.c then begin { Ende des Tages überschritten mit neuem Zeitschritt ? }
      dt_neu := (GlobTime.c - SumOfInternalTimeSteps);
      dt.v := dt_neu;
    end;
  dt.v := dt_neu;
  end;

end;

procedure get_delt_iter_max;


{ ********************************************************************** }
{
  Zweck : Berechnung des maximalen Wassergehaltsunterschiedes in einem
          Kompartiment von einem Iterationsschritt zu nächsten


}
{ ********************************************************************** }


var
  i : byte;

begin
  delt_iter_max := 0.0;
  if iter > 0 then begin
    for I := start to n_comp do
      if (abs(last_iter_theta[i]-theta_neu[i]) > abs(delt_iter_max)) then
         delt_iter_max := abs(last_iter_theta[i]-theta_neu[i])
  end;
  if Delt_iter_max < 1e-5 then success := true;
end;

procedure set_new_state_vars;
{ ********************************************************************** }
{
  Zweck : Umsetzen der errechneten Wassergehalte in die globale
          "state"-Variable, Errechnung der Wasserspannungen


}
{ ********************************************************************** }

var
  i : byte;

begin
    for I := 1 to n_comp+1 do begin
      theta_alt[i] := theta_arr[i].v;
      theta_arr[i].v := theta_neu[i];
      psi_arr[i].v   := WPar[i].psi_b_f ( theta_arr[i].v);
      Wmenge[i].v     := theta_arr[i].v*dicke[i];
    end;
end;


begin  { procedure num_wat_solut }
   iter := 0;

   get_water_contents;
   get_new_dt;
   repeat
     repeat
       get_delt_iter_max;
       Leitfaehigkeiten;
       obere_Randbedingung;
       Mittelteil;
       untere_Randbedingung;
       Loesung_Gleichungssystem;
     until success;
     iter := iter + 1;
   until ((delt_iter_max < max_iter_error) and (iter > 1)) or (iter > 1000);
   Find_flows;
   get_bilanz ;
   set_new_state_vars;
end;
{--------------------------------------------------------------------------}

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilWaterMod]);
end;


end.
