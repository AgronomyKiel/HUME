
procedure TSoilWaterMod.get_new_dt;
{ ********************************************************************** }
{ Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verhältnisses
  der maximal erlaubten Wassergehaltsänderung zur maximalen aktuellen
  Wassergehaltsänderung

  Parameter :

  Name             Inhalt                          Einheit      Typ

  max_aender       maximal erlaubte Änderung       [cm3/cm3]    I
  der Wassergehalte in einem
  Zeitschritt

  akt_aender       maximale Änderung des Wasser-   [cm3/cm3]    I
  gehaltes in einem Kompartiment
  im letzten Zeitschritt

  dt               Zeitschrittweite                [d]          O
  dt_alt           letzte Zeitschrittweite         [d]          O }

{ ********************************************************************** }
const
 crit_h =5;

var
  delta_t, dt_neu, min_h: real;

  i: integer;

  function calc_dt_power(x,x_max,x_min,y_max,y_min: real): real;
    var
    a, b: real;
  begin
    {y_max is y(x_max)
     y_min is y(x_min)}
    b:= ln(y_max/y_min)/ln(x_max);
    a:= y_max/power(x_max,b);
    calc_dt_power := a*power(x,b);
  end;

begin
  iter := iter + 1;
  total_iter := total_iter + 1;
  // Set new time-step
  if (dt_set = false) then
  begin
    // How many iteration last time-step? -> reduce width of time step if necessary
    if(last_iter >3) then // takes place only after 'reset'
      delta_t := calc_dt_power(last_iter,IterMax,1,min_dt,1)
    else
      delta_t :=1 ;
    // Verhältniss der erlaubten zur aktuellen Wassergehaltsänderung
    if max(MaxAktAenderWaGe, NetRain.v * dt.v / (Dicke[1] * 10)) <> 0.0 then
    begin
      dt_neu := (max_aenderWG.v / max(MaxAktAenderWaGe,
          NetRain.v * dt.v / (Dicke[1] * 10))) * dt.v;
      if ((dt_neu > (1.5 * dt.v)) and (dt_neu > min_dt*100)) then
              dt_neu := dt.v * 1.5; { Zu großer Zeitschrittsprung ? }
      delta_t := max(min(delta_t, dt_neu), min_dt)
    end
    else
      dt_neu := delta_t;
    // is iteration or change rate of wc limiting ?
    delta_t := max(delta_t, min_dt);
    dt.v :=delta_t;
    // niedrige Wasserspannungen bzw. hohe Flussraten in vielen Schichten
    if(((fCompMethod = Richards) or (fCompMethod = Mixed) or
    (fCompMethod = MixedHydrus)))
    then begin
      min_h:=100;
      for i := 1 to n_comp do
      begin
        if(psi_neu[i]<min_h) then
          min_h:= psi_neu[i];
      end;
      if(min_h < crit_h) then
        dt.v := min(delta_t, calc_dt_power((crit_h-min_h), crit_h,1,min_dt,1))
      else
      dt.v :=delta_t;
    end;

    if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then begin
      dt_alt := dt.v;
      dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
      newday := true;
    end;
    dt_set := true;
  end;
  // Reset
  If iter > IterMax then
  begin
    for i := 1 to n_comp + 1 do
    begin
      theta_neu[i] := theta_arr[i].v;
      psi_neu[i] := psi_arr[i].v;
    end;
    last_iter := iter;
    iter := 0;
    IterMax := IterMax + 1;

    ResetTimeStep := true;
    dt.v := min_dt;
    if SumOfInternalTimeSteps.v + dt.v > GlobTime.c then
      dt.v := (GlobTime.c - SumOfInternalTimeSteps.v);
    if(last_iter > 10) then
      last_iter:=+1;
    dt_set := true;
  end; // Reset end

  if ((delt_iter_max < max_IterError.v) and (iter > 1) or (total_iter > 100))
    then
  begin
    success := true;
    last_iter := 0;
    iter := 0;
    dt_set := false;
    IterMax := 20;
    min_dt := 0.00001;
    global_iter.v := global_iter.v + total_iter;
    total_iter := 0;
  end;
  dt.v := min(Max_dt.v, dt.v);
  //iter := 0;
end;