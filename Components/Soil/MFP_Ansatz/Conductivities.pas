procedure TSoilWaterMod.CalcConductivities;

var
  i: byte;
  Overflow: real;
begin
  { if (iter = 0) and (fCompMethod = Diffusion) then
    begin // linear extrapolation of water contents during the first iteration
    for i := 1 to n_comp do begin
    est_theta[i + 1] := 0.5 * (1 + dt.v / (2 * dt_alt)) *
    (theta_arr[i].v + theta_arr[i + 1].v) - 0.25 * dt.v / dt_alt *
    (theta_alt[i] + theta_alt[i + 1]);
    // psi_arr[i].v := WPar[i].psi_b_f(est_theta[i]);
    end;

    for i := 2 to n_comp + 1 do
    begin
    avg_Dw[i] := sqrt(max(0,WPar[i].Dw_f(est_theta[i]) * WPar[i - 1].Dw_f
    (est_theta[i - 1])));
    avg_Ku[i] := sqrt(max(0,WPar[i].Ku_b_f(est_theta[i]) * WPar[i - 1].Ku_b_f
    (est_theta[i - 1])));
    end;
    for i := 2 to n_comp + 1 do
    begin
    Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
    Ku_fact[i] := avg_Ku[i] * dt.v;
    end;
    end
    else }
  // begin // further iterations
  // Calculation of water diffusivity and unsaturated hydraulic conductivity
  // for each compartment from the mean water contents at the start and end of
  // the time step

  { for i := 1 to n_comp + 1 do
    begin
    // c_arr[i]  := WPar[i].C_psi_f(psi_arr[i].v);
    // Dw_arr[i] := WPar[i].Dw_f((theta_neu[i] + theta_arr[i].v) / 2.0);
    // Ku_arr[i] := WPar[i].Ku_b_f((theta_neu[i] + theta_arr[i].v) / 2.0);

    // Version with C averaged over start and end of the time step and implicit
    // calculation of conductivities
    // c_arr[i]  := (WPar[i].C_psi_f(psi_neu[i])+WPar[i].C_psi_f(psi_arr[i].v))/2;
    Dw_arr[i] := max(0, WPar[i].Dw_f(max(self.WPar[i].b_rest, theta_new[i])));
    Ku_arr[i] := max(0, WPar[i].Ku_b_f(max(self.WPar[i].b_rest, theta_new[i])));
    end; }

  TParallel.For(1, n_comp + 1,
    procedure(i: Int64)
    begin
      Dw_arr[i] := max(0, WPar[i].Dw_f(max(WPar[i].b_rest, theta_new[i])));
      Ku_arr[i] := max(0, WPar[i].Ku_b_f(max(WPar[i].b_rest, theta_new[i])));
    end);

  { Calculation des Mittelwertes der conductivity zwischen 2 Kompartimenten }
  for i := 2 to n_comp + 1 do
  begin
    // if (psi_neu[i-1]>(psi_neu[i]+Abst[i])) and // upward flow according to tensions
    // (theta_neu[i-1] < theta_neu[i]) then //  upward flow according to soil water
    // avg_Dw[i] := Dw_arr[i-1];
    // if (psi_neu[i-1]<(psi_neu[i]+Abst[i])) and // downward flow according to tensions
    // (theta_neu[i-1] > theta_neu[i]) then //  downward flow according to soil water
    // avg_Dw[i] := Dw_arr[i];

    { if (psi_neu[i-1]>(psi_neu[i]+Abst[i])) and // upward flow according to tensions
      (theta_neu[i-1] > theta_neu[i]) then //  downward flow according to soil water
      avg_Dw[i] := 0;

      if (psi_neu[i-1]<(psi_neu[i]+Abst[i])) and // downward flow according to tensions
      (theta_neu[i-1] < theta_neu[i]) then //  upward flow according to soil water
      avg_Dw[i] := 0; }



    // avg_Dw[i] := min (Dw_arr[i - 1] , Dw_arr[i]);  //
    // avg_Ku[i] := min (Ku_arr[i - 1] , Ku_arr[i]); // / 2.0;    //cm/d

    // avg_Dw[i] := (Dw_arr[i - 1] + Dw_arr[i]) / 2.0;    //cm2/d
    // avg_Ku[i] := (Ku_arr[i - 1] + Ku_arr[i]) / 2.0;    //cm/d

    // harmonic mean of conductivities
    avg_Dw[i] := sqrt(Dw_arr[i - 1] * Dw_arr[i]); // cm2/d
    avg_Ku[i] := sqrt(Ku_arr[i - 1] * Ku_arr[i]); // cm/d

  end;

  avg_Ku[0] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean
  avg_Ku[1] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean
  avg_Dw[1] := (WPar[1].Dw_f((WPar[1].b_sat + theta_new[1]) / 2));
  // aritmethic mea
  { Calculation von Koeffizienten for die Aufstellung des Gleichungssystems,
    Abst.vektor mit dem Index i-1, weil Abstand zwischen erstem und
    zweiten Kompartiment Index 1 hat (verschobene Indizierung }

  for i := 1 to n_comp + 1 do
  begin
    { below PWP  => no flows }   // Ratjen 20.07.17
    { if ((theta_neu[i] < PWP_Arr[i]) and (Dw_fact[i] > 0)) then
      begin
      avg_Dw[i] := 0.0;
      avg_Ku[i] := 0.0;
      Dw_fact[i] := 0.0;
      Ku_fact[i] := 0.0;
      end
      else }
    begin
      Dw_fact[i] := avg_Dw[i] * dt.v / Dist[i - 1];
      Ku_fact[i] := avg_Ku[i] * dt.v;
    end;
    { If water content > saturation => no flows }   // Ratjen
    { if ((theta_neu[i] >= WPar[i].b_sat) and (Dw_fact[i]<0)) then
      begin
      avg_Dw[i] := 0.0;
      avg_Ku[i] := 0.0;
      Dw_fact[i] := 0.0;
      Ku_fact[i] := 0.0;
      end else begin
      Dw_fact[i] := avg_Dw[i] * dt.v / Abst[i - 1];
      Ku_fact[i] := avg_Ku[i] * dt.v;
      end;
    }
  end;
  // end;
  CalcTempFactor;

end;

procedure TSoilWaterMod.CalcLeitfaehigkeiten(const useGeometricMean,
  includeCoefficients, applyFreezing: Boolean);

var
  i: byte;

begin
  for i := 1 to n_comp + 1 do
  begin
    c_arr[i] := WPar[i].C_psi_f(psi_neu[i]);
    Ku_arr[i] := WPar[i].Ku_b_f(theta_new[i]);
  end;

  for i := 1 to n_comp do
  begin
    if useGeometricMean then
      avg_Ku[i] := sqrt(Ku_arr[i] * Ku_arr[i + 1])
    else
      avg_Ku[i] := (Ku_arr[i] + Ku_arr[i + 1]) / 2;
  end;

  if includeCoefficients then
  begin
    avg_Ku[0] := (WPar[1].Ks + Ku_arr[1]) / 2; // aritmethic mean

    for i := 1 to n_comp do
    begin
      if c_arr[i] >= 0.0 then
        P[i] := 0.0
      else
        P[i] := dt.v / (c_arr[i] * Thick[i]);
      kf[i] := avg_Ku[i] / Dist[i];
      wf[i] := 1;
    end;

    kf[0] := 2 * avg_Ku[0] / Dist[1];
  end;

  if applyFreezing and (FSoilHeatModel <> nil) then
  begin
    for i := 1 to n_comp + 1 do
    begin
      if FSoilHeatModel.Temp[i].v <= 0 then
      begin
        avg_Ku[i] := 0.0;
        Ku_fact[i] := 0.0;
        kf[i] := 0.0;
      end;
    end;
  end;
end;
