unit Usnowpack;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type

TSnowPack = class(TSubmodel)

private

protected

public
  Es : TVar;   // evaporation plus sublimation from snow storage [mm]
  EsS : TVar;   // evaporation from snow storage [mm]
  Js : TVar;   // leaking water [mm]
  Evap_pot : Tvar; // potentielle Evaporation Ohne Snow Pack für SoilWater
  M : TVar;   // actual melting [mm]
  maxM : TVar;   // maximum possible melting [mm]
  minM : TVar;   // minimal posible melting [mm]
  Mpot : TVar;   // potential snow melting [mm]
  mr : TVar;   // radiation melting factor [kg/J]
  mt : TVar;   // air temperature melting factor [kg/m2/h*C]
  P : TVar;   // precipitation [mm]
  Percolation: TVar; // Percolation into soil [mm]
  Pr : TVar;   // precipitation rain [mm]
  Ps : TVar;   // precipitation snow [mm]
  qh : TVar;   // soil heat flux at the surface
  rhop : TVar;   // density of newly fallen precipitation (snow-rain mixture), calculated as a weighted average of the density of water and powder snow
  ScS : TVar;   // storage capacity on snow storage for retention of liquid water [mm]
  Si : TVar;   // radiation
  Tact : TVar;   // temperature
  Zs : TVar;   // depth of snow layer [m]
  Ks :TVar ; // Thermal conductivity of snow
  Tsf : TVar ; // Temperature at soil surface under snow


  // Constant Variables

  SnowAge : TState;   // age since last snow
  SsS : TState;   // snow storage expressed as water [mm]
  SwS : TState;   // water in snow storage [mm]

  // Parameters

  fc : TPar;   // water capacity in snow factor
  Lm : TPar;   // snow melting heat factor [J/kg]
  m1 : TPar;   // radiation melting linear factor [kg/J]
  m2 : TPar;   // radiation melting exponential factor [1/h]
  mf : TPar;   // snow pack depth melting factor [1/m]
  mrp : TPar;   // radiation melting  factor [kg/J]
  mtp : TPar;   // [air temperature melting factor [kg/m2/h C]
  rhos : TPar;   // density of newly fallen snow [kg/m3]
  rhow : TPar;   // water density
  t1 : TPar;   // 
  t2 : TPar;   // 
  f : TPar;   //
  alpha_h : TPar; //  parameter for heat conductivity of snow
  z1 : TPar; // soil depth in cm
  

  // External Variables

  Epot : TExternV;   //
  global_radiation : TExternV;   //
  rainfall_mm : TExternV;   //
  Temp1 : TExternV; // Temperature in first soil layer
  Lambda1 : TExternV; // Thermal conductivity in first soil layer

  //  SoilHeatFlux : TExternV;

  AirTemp : TExternV;   //



  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;



published
  Property Var_Es : TVar read Es write Es;
  Property Var_EsS : TVar read EsS write EsS;
  property Var_EvapPot : TVar read Evap_pot write Evap_pot;
  Property Var_Js : TVar read Js write Js;
  Property Var_M : TVar read M write M;
  Property Var_maxM : TVar read maxM write maxM;
  Property Var_minM : TVar read minM write minM;
  Property Var_Mpot : TVar read Mpot write Mpot;
  Property Var_mr : TVar read mr write mr;
  Property Var_mt : TVar read mt write mt;
  Property Var_P : TVar read P write P;
  property var_percolation: TVar read Percolation write Percolation;
  Property Var_Pr : TVar read Pr write Pr;
  Property Var_Ps : TVar read Ps write Ps;
  Property Var_qh : TVar read qh write qh;
  Property Var_rhop : TVar read rhop write rhop;
  Property Var_ScS : TVar read ScS write ScS;
  Property Var_Si : TVar read Si write Si;
  Property Var_Tact : TVar read Tact write Tact;
  Property Var_Zs : TVar read Zs write Zs;
  Property St_SnowAge : TState read SnowAge write SnowAge;
  Property St_SsS : TState read SsS write SsS;
  Property St_SwS : TState read SwS write SwS;


  // Parameters

  Property Par_fc : TPar read fc write fc;
  Property Par_Lm : TPar read Lm write Lm;
  Property Par_m1 : TPar read m1 write m1;
  Property Par_m2 : TPar read m2 write m2;
  Property Par_mf : TPar read mf write mf;
  Property Par_mrp : TPar read mrp write mrp;
  Property Par_mtp : TPar read mtp write mtp;
  Property Par_rhos : TPar read rhos write rhos;
  Property Par_rhow : TPar read rhow write rhow;
  Property Par_t1 : TPar read t1 write t1;
  Property Par_t2 : TPar read t2 write t2;

  // Properties External Variables

  Property Ex_Epot : TExternV read Epot write Epot;
  Property Ex_global_radiation : TExternV read global_radiation write global_radiation;
  Property Ex_rainfall_mm : TExternV read rainfall_mm write rainfall_mm;
  //  Property Ex_SoilHeatFlux : TExternV read SoilHeatFlux write SoilHeatFlux;
  Property Ex_AirTemp : TExternV read AirTemp write AirTemp;
  Property Ex_Temp1 : TExternV read Temp1 write Temp1;
  Property Ex_Lambda1 : TExternV read Lambda1 write Lambda1;


end;  // SubmodelName

procedure Register;

implementation


uses math;

procedure TSnowPack.createAll;

begin
  inherited createAll;
  VarCreate('Es', '',0, true, Es);
  VarCreate('EsS', '',0, true, EsS);
  VarCreate('Evap_pot', '[mm]',0,true,Evap_pot);
  VarCreate('Js', '',0, true, Js);
  VarCreate('M', '',0, true, M);
  VarCreate('maxM', '',0, true, maxM);
  VarCreate('minM', '',0, true, minM);
  VarCreate('Mpot', '',0, true, Mpot);
  VarCreate('mr', '',0, true, mr);
  VarCreate('mt', '',0, true, mt);
  VarCreate('P', '',0, true, P);
  VarCreate('Percolation','[mm]',0,true,Percolation);
  VarCreate('Pr', '',0, true, Pr);
  VarCreate('Ps', '',0, true, Ps);
  VarCreate('qh', '',0, true, qh);
  VarCreate('rhop', '',0, true, rhop);
  VarCreate('ScS', '',0, true, ScS);
  VarCreate('Si', '',0, true, Si);
  VarCreate('Tact', '',0, true, Tact);
  VarCreate('Zs', '',0, true, Zs);
  VarCreate('Ks', '',0, true, Ks);
  VarCreate('Tsf', '',0, true, Tsf);


  StateCreate('SnowAge', '',0, true,SnowAge);
  StateCreate('SsS', '',0, true,SsS);
  StateCreate('SwS', '',0, true,SwS);


  // Parameters
  ParCreate('fc', '[-]',0.07,fc);
  ParCreate('Lm', '[-]',334000,Lm);
  ParCreate('m1', '[kg/J]',2,m1);
  ParCreate('m2', '[1/days]',0.1,m2);
  ParCreate('mf', '[m-1]',10,mf);
  ParCreate('mrp', '[kg*J-1]',1.5E-7,mrp);
  ParCreate('mtp', '[kg*m-2*day-1*°C]',2,mtp);
  ParCreate('rhos', '[kg*m-3]',100,rhos);
  ParCreate('rhow', '[kg*m-3]',1000,rhow);
  ParCreate('t1', '[°C]',-2,t1);
  ParCreate('t2', '[°C]',2,t2);
  ParCreate('f', '[-]',1,f);
  ParCreate('z1', '[m]',0.05,z1);
  ParCreate('alpha_h', '[W m4 kg-2]',2.86E-6,alpha_h,'Thermal conductivity parameter for snow');

         // External Variable
  ExternVCreate('Epot', '',statefield, Epot);
  ExternVCreate('global_radiation', '',statefield, global_radiation);
  ExternVCreate('rainfall_mm', '',statefield, rainfall_mm);
  ExternVCreate('AirTemp', '',statefield, AirTemp);
  ExternVCreate('SoilTemp__1', '[°C]',statefield, Temp1);
  ExternVCreate('Lambda_1', '',statefield, Lambda1);
//  ExternVCreate('SoilHeatFlux', '',statefield, SoilHeatFlux);

end;


procedure TSnowPack.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  SnowAge.v := 0;
  SsS.v := 0;
  SwS.v := 0;
end;


procedure TSnowPack.CalcRates;

begin
   Tact.v := AirTemp.v;
   P.v := rainfall_mm.v;
   If Tact.v <= T1.v then
     Ps.v := P.v else
   If T2.v <= Tact.v then
     Ps.v := 0
   else Ps.v := ((T2.v-Tact.v)/(T2.v-T1.v))*P.v; // Unterscheidung Schnee oder Regen in Abhägikeit der Temperatur

   Pr.v := P.v-Ps.v;

   Si.v := global_radiation.v/1e6*86400; // Umrechnung der Strahlung

   If SwS.v <= 0 then
     Es.v := 0 else
   If Es.v > P.v + SwS.v then
     Es.v := P.v + SwS.v
   else Es.v := Epot.v; // Berechnung Evaporation + Sublimation
   If Es.v < 0 then Es.v := 0;
   If Es.v > Epot.v then Es.v := Epot.v;
   If Es.v > SsS.v + P.v then Es.v := SsS.v + P.v;


   If SwS.v <= 0 then
     EsS.v := 0 else
   If Es.v > Pr.v + SsS.v then
     EsS.v := Pr.v + SwS.v
   else EsS.v := Es.v; // Berechung Evaporation

   Zs.v :=  SsS.v/rhos.v; // Schichtdicke vom Vortag, neuer Schnee kommt bei mt dazu

   mr.v := mrp.v * (1 + m1.v * (1 - exp (-m2.v * SnowAge.v))) * 1e6;

   If P.v > 0 then
     rhop.v := rhow.v + (rhos.v + rhow.v) * (Ps.v/P.v)
   else  rhop.v := 1;

   If Tact.v < 0 then
     If Zs.v + P.v = 0 then
     mt.v := mtp.v else
     mt.v := mtp.v * min (1, 1/((Zs.v+P.v/rhoP.v)*mf.v))
   else mt.v := mtp.v;

   If SwS.v <= 0 then
     maxM.v := 0
   else maxM.v := ((SsS.v - SwS.v) + Ps.v - (Es.v - EsS.v));

   If SwS.v <= 0 then
     minM.v:= 0
   else minM.v := -(SwS.v + Pr.v - EsS.v);

   qh.v := 0;

   Mpot.v := (mt.v * Tact.v + mr.v * Si.v + qh.v / Lm.v) * f.v;

   M.v := min(max(minm.v, Mpot.v), maxM.v);


   //If Mpot.v < minM.v then
   //  M.v := minM.v
   //else If maxM.v < Mpot.v then
   //  M.v := maxM.v
   //else M.v := Mpot.v;

   ScS.v :=  fc.v * (SsS.v + (P.v - Es.v));
   If ScS.v < 0 then Scs.V :=0;

   If SwS.v <= 0 then
     Js.v := 0
   else Js.v := Max(0, SwS.v + (Pr.v - Es.v + M.v) - ScS.v);

   Zs.v :=  SsS.v/rhos.v;

   If SsS.v + Ps.v > 0 then
   SsS.c := Ps.v + Pr.v - Es.v - Js.v 
   else SsS.c := 0;
   If SsS.c < -SsS.v then SsS.c := -SsS.v;


   If SsS.v + Ps.v > 0 then
   SwS.c := Pr.v + M.v - Ess.v - Js.v
   else SwS.c := 0;
   If SwS.c < -SwS.v then Sws.c := -SwS.v;

   If Zs.v > 0 then begin
     Evap_pot.v := 0;
     Percolation.v := Js.v;
   end
   else begin
     Evap_pot.v := EPot.v;
     Percolation.v := Rainfall_mm.v;
   end;

   if SwS.v > 0 then
      Tsf.v := 0
   else
      if Zs.v>0 then
      Tsf.v := ((Lambda1.v/z1.v)*Temp1.v+alpha_h.v*sqr(rhos.v)/Zs.v*Airtemp.v)/(Lambda1.v/z1.v+alpha_h.v*sqr(rhos.v)/Zs.v)
      else
      Tsf.v := AirTemp.v;


end;



procedure TSnowPack.Integrate;

begin

  inherited  integrate;
  If Ps.v > 0 then begin
    SnowAge.v:= 0;
  end;



end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSnowPack]);
end;

end.
