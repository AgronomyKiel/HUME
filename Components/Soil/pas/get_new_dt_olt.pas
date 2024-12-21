  procedure get_new_dt;
  { ********************************************************************** }
  { Zweck :  Berechnung der neuen Zeitschrittweite "dt" aufgrund des Verhältnisses
    der maximal erlaubten Wassergehaltsänderung zur maximalen aktuellen
    Wassergehaltsänderung

    Parameter :
					  
					  
			
		  
			   

    Name             Inhalt                          Einheit      Typ
																			
																		
																			
													   
	   
																								
																									 
													 
													

    max_aender       maximal erlaubte Žnderung       [cm3/cm3]    I
    der Wassergehalte in einem
    Zeitschritt

    akt_aender       maximale Änderung des Wasser-   [cm3/cm3]    I
    gehaltes in einem Kompartiment
    im letzten Zeitschritt

    dt               Zeitschrittweite                [d]          O
    dt_alt           letzte Zeitschrittweite         [d]          O }
																   
																		   
									   
					
									  
		  
	  

  { ********************************************************************** }
				  
							   
	  

  var
    dt_neu    : real;
					
									
														  
																			   
																			 
																						 
										
									   
			  
		 
												  
							   
																		  
																		   
																				 
																		

    i:integer;
																					  
									 
		

	 

					   
	 
			   
  begin
    if max(MaxAktAenderWaGe, NetRain.v * dt.v / (Dicke[1] * 10)) <> 0.0 then
    begin
      if (dt_alt / dt.v <= 1.5) then
        dt_alt := dt.v { Speicherung der alten Zeitschrittweite }
      else
        dt.v := dt_alt; { wenn der alte Zeitschritt Rest des Tages war,
        dann vorletzter Zeitschritt als Startwert für neuen Zeitschritt. }
          dt_neu := (max_aenderWG.v / max(MaxAktAenderWaGe,NetRain.v * dt.v / (Dicke[1] * 10))) * dt.v;
      if dt_neu > Max_dt.v then
        dt_neu := Max_dt.v; { Zu großer Zeitschritt ? }
      if dt_neu > 1.5 * dt.v then
        dt_neu := dt.v * 1.5; { Zu großer Zeitschrittsprung ? }
																	   
								 

      { Der folgende Algorithmus wurde eingefügt, um Diskontinuitäten bei der
        Verwendung von Eingabedaten auf täglicher Basis zu vermeiden. }
      if SumOfInternalTimeSteps.v + dt_neu > GlobTime.c
      { Ende des Tages überschritten mit neuem Zeitschritt ? } then
        dt_neu := (GlobTime.c - SumOfInternalTimeSteps.v);
      dt.v := dt_neu;
    end;

  end;
	  