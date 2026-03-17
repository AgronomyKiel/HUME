unit Umain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type

Tmain = class(TSubmodel)

private

protected

public
  f_NI : TVar;   // 
  f_temp : TVar;   // 
  f_UI : TVar;   // 
  f_water : TVar;   // 
  Hydrolyse : TVar;   // 
  NI_Abbaurate : TVar;   // 
  Nitrifikation : TVar;   // 
  Temp : TVar;   // Bodentemperatur [°C]
  UI_Abbaurate : TVar;   // 
  Volatilisation : TVar;   // 
  WFP : TVar;   // water filled pore space [-]
  WG : TVar;   // volumetrischer Wassergehalt [cm3/cm3]


  // Constant Variables
  WG50 : TVar;   // 


  // State Variables
  HST : TState;   // 
  N2 : TState;   // 
  N2O : TState;   // 
  NH3 : TState;   // 
  NH4 : TState;   // 
  NI : TState;   // 
  NIAbbauprodukte : TState;   // 
  NO3 : TState;   // 
  UI : TState;   // 
  UIAbbauprodukte : TState;   // 

             // Parameters
  FK : TPar;   // 
  k_hyd : TPar;   // 
  k_NI : TPar;   // 
  k_nit : TPar;   // 
  k_UI : TPar;   // 
  Porosity : TPar;   // 
  WGpwp : TPar;   // 

             // External Variables


  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override; 


published
  Property Var_f_NI : TVar read f_NI write f_NI;
  Property Var_f_temp : TVar read f_temp write f_temp;
  Property Var_f_UI : TVar read f_UI write f_UI;
  Property Var_f_water : TVar read f_water write f_water;
  Property Var_Hydrolyse : TVar read Hydrolyse write Hydrolyse;
  Property Var_NI_Abbaurate : TVar read NI_Abbaurate write NI_Abbaurate;
  Property Var_Nitrifikation : TVar read Nitrifikation write Nitrifikation;
  Property Var_Temp : TVar read Temp write Temp;
  Property Var_UI_Abbaurate : TVar read UI_Abbaurate write UI_Abbaurate;
  Property Var_Volatilisation : TVar read Volatilisation write Volatilisation;
  Property Var_WFP : TVar read WFP write WFP;
  Property Var_WG : TVar read WG write WG;

  Property St_HST : TState read HST write HST;
  Property St_N2 : TState read N2 write N2;
  Property St_N2O : TState read N2O write N2O;
  Property St_NH3 : TState read NH3 write NH3;
  Property St_NH4 : TState read NH4 write NH4;
  Property St_NI : TState read NI write NI;
  Property St_NIAbbauprodukte : TState read NIAbbauprodukte write NIAbbauprodukte;
  Property St_NO3 : TState read NO3 write NO3;
  Property St_UI : TState read UI write UI;
  Property St_UIAbbauprodukte : TState read UIAbbauprodukte write UIAbbauprodukte;


         // Parameters
  Property Par_FK : TPar read FK write FK;
  Property Par_k_hyd : TPar read k_hyd write k_hyd;
  Property Par_k_NI : TPar read k_NI write k_NI;
  Property Par_k_nit : TPar read k_nit write k_nit;
  Property Par_k_UI : TPar read k_UI write k_UI;
  Property Par_Porosity : TPar read Porosity write Porosity;
  Property Par_WGpwp : TPar read WGpwp write WGpwp;

         // Properties External Variables


end;  // SubmodelName

procedure Register;

implementation

procedure Tmain.createAll;

begin
  inherited createAll;
  VarCreate('f_NI', '',0, true, f_NI, '');  
  VarCreate('f_temp', '',0, true, f_temp, '');  
  VarCreate('f_UI', '',0, true, f_UI, '');  
  VarCreate('f_water', '',0, true, f_water, '');  
  VarCreate('Hydrolyse', '',0, true, Hydrolyse, '');  
  VarCreate('NI_Abbaurate', '',0, true, NI_Abbaurate, '');  
  VarCreate('Nitrifikation', '',0, true, Nitrifikation, '');  
  VarCreate('Temp', '',0, true, Temp, 'Bodentemperatur [°C]');  
  VarCreate('UI_Abbaurate', '',0, true, UI_Abbaurate, '');  
  VarCreate('Volatilisation', '',0, true, Volatilisation, '');  
  VarCreate('WFP', '',0, true, WFP, 'water filled pore space [-]');  
  VarCreate('WG', '',0, true, WG, 'volumetrischer Wassergehalt [cm3/cm3]');  

  VarCreate('WG50', '',0, true, WG50, '');  

  StateCreate('HST', '',0, true,HST, '');
  StateCreate('N2', '',0, true,N2, '');
  StateCreate('N2O', '',0, true,N2O, '');
  StateCreate('NH3', '',0, true,NH3, '');
  StateCreate('NH4', '',0, true,NH4, '');
  StateCreate('NI', '',0, true,NI, '');
  StateCreate('NIAbbauprodukte', '',0, true,NIAbbauprodukte, '');
  StateCreate('NO3', '',0, true,NO3, '');
  StateCreate('UI', '',0, true,UI, '');
  StateCreate('UIAbbauprodukte', '',0, true,UIAbbauprodukte, '');


  // Parameters
  ParCreate('FK', '',0,FK, '');
  ParCreate('k_hyd', '',0,k_hyd, '');
  ParCreate('k_NI', '',0,k_NI, '');
  ParCreate('k_nit', '',0,k_nit, '');
  ParCreate('k_UI', '',0,k_UI, '');
  ParCreate('Porosity', '',0,Porosity, '');
  ParCreate('WGpwp', '',0,WGpwp, '');

         // External Variable
end;


procedure Tmain.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  HST.v :=  10;
  N2.v :=  0.0;
  N2O.v :=  0.0;
  NH3.v :=  0.0;
  NH4.v :=  0.1;
  NI.v :=  10;
  NIAbbauprodukte.v :=  0.0;
  NO3.v :=  1.8;
  UI.v :=  10;
  UIAbbauprodukte.v :=  0.0;

  WG50.v :=  WGpwp+0.5*(FK-WGpwp);

end;


procedure Tmain.CalcRates;

begin

    If  NI.v<=8 then 
     f_NI.v :=   NI.v/8  
  else   If  NI.v>8 then 
     f_NI.v :=   1  
  else  f_NI.v :=   1  ;
   f_temp.v :=  Temp.v/40+0.2;
    If  UI.v<=8 then 
     f_UI.v :=   UI.v/8  
  else   If  UI.v>8 then 
     f_UI.v :=   1  
  else  f_UI.v :=   1  ;
    If  WG.v<WG.vpwp then 
     f_water.v :=   0.2  
  else   If  (WG.v>WG.vpwp) and (WG.v<WG.v50) then 
     f_water.v :=   0.2+0.8*(WG.v-WG.vpwp)/(WG.v50-WG.vpwp)  
  else   If  (WG.v>=WG.v50) and (WG.v<=FK.v) then 
     f_water.v :=   1  
  else   If  (WG.v>FK.v) and (WG.v<=Porosity.v) then 
     f_water.v :=   1-0.3*(WG.v-FK.v)/(Porosity.v-FK.v)  
  else  f_water.v :=   1  ;
   Hydrolyse.v :=  HST.v*k_hyd.v*min(f_water.v,f_temp.v)*f_UI;
   NI_Abbaurate.v :=  k_NI.v * NI;
   Nitrifikation.v :=  k_nit.v* NH4.v*f_NI;
   Temp.v :=  20;
   UI_Abbaurate.v :=  k_UI.v * UI;
   Volatilisation.v :=  0* NH4;
   WFP.v :=  min(1,WG.v/Porosity.v);
   WG.v :=  0.2;


   HST.c :=  -Hydrolyse;
   N2.c :=  0;
   N2O.c :=  0;
   NH3.c :=  +Volatilisation;
   NH4.c :=  -Nitrifikation.v+Hydrolyse.v-Volatilisation;
   NI.c :=  -NI_Abbaurate;
   NIAbbauprodukte.c :=  +NI_Abbaurate;
   NO3.c :=  +Nitrifikation;
   UI.c :=  -UI_Abbaurate;
   UIAbbauprodukte.c :=  +UI_Abbaurate;


end;



end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Tmain]);
end;

end.
