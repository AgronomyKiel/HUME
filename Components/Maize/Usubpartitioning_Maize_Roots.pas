unit Usubpartitioning_Maize_Roots;

interface

uses
  Windows, Messages, SysUtils, Classes,
  vcl.Graphics,
  vcl.Controls,
  vcl.Forms,
  vcl.Dialogs,
  UMod, UState, UAbstractPlant, UlayeredSoil, Usubpartitioning_Maize;

Type

Tsubpartitioning_Maize_Roots = class(Tsubpartitioning_Maize)

private

protected

public
  // Variables
    ACroot : TVar;   // drymatter allocation coefficient for roots

  // State Variables

//  DMroot : TState;
    DMtot : TState;

  // Parameters

    ACEroot : TPar; //  that is the ACroot (TM-Verteilungskoeffizient für die Wurzel) at emergence
    DSstop : TPar;  //  DevelopmentStage when root growth stops
    g : TPar;      //Parameter for fleaf   (slope)  (holzhauser)
    h : TPar;      // Parameter for fleaf (intecept)       (holzhauser)
    fstemmin : TPar; // ca. 25% TM befinden sich zu Erntezeitpunkt noch im Stängel (Datengrundlage: Babette)  (holzhauser: 28.5%)
    decay_a: TPar;    //Parameter for calculating fleaf after Xstage=3, when leaf dry matter is translocated to stem.  (slope)      (holzhauser)
    decay_b: TPar;     //Parameter for calculating fleaf after Xstage=3, when leaf dry matter is translocated to stem.   (exponent)     (holzhauser)
    SLAleafmin: TPar;   //Second plateau for SLA   (holzhauser)
    SLAstemmin: TPar;     //Second plateau for SLAstem   (holzhauser)
  // External Variables

  DS : TExternV;   //  DevelopmentSage for root growth
  TempSumR  : TExternV; // Temperatursumme für die Wurzelentwicklung

  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  // Vaiables
  Property Var_ACroot : TVar read ACroot write ACroot;

  // State


//  Property St_DMroot : TState read DMroot write DMroot;
  Property St_DMtot : TState read DMtot write DMtot;

  // Parameters

  Property Par_ACEroot : TPar read ACEroot write ACEroot;
  Property Par_DSstop : TPar read DSstop write DSstop;
  Property Par_g : TPar read g write g;
  Property Par_h : TPar read h write h;
  Property Par_fstemmin : TPar read fstemmin write fstemmin;
  Property Par_decay_a : TPar read decay_a write decay_a;
  Property Par_decay_b : TPar read decay_b write decay_b;
  Property Par_SLAleafmin : TPar read SLAleafmin write SLAleafmin;
  Property Par_SLAstemmin : TPar read SLAstemmin write SLAstemmin;

  // External Variables

end;  // SubmodelName

procedure Register;

implementation
uses Math, JCLdatetime;

procedure Tsubpartitioning_Maize_Roots.createAll;
var
i:integer;
ndx_str:string;

begin
  inherited createAll;
  //Variables
  VarCreate ('ACroot', '', 0, true, ACroot);

  //State Variables

 // StateCreate('DMroot', '',0, true,DMroot);
  StateCreate('DMtot', '',0, true,DMtot);
  // Parameters

  ParCreate ('ACEroot', '', 0.35, ACEroot);
  ParCreate ('DSstop', '', 1.15, DSstop);
  ParCreate ('g','', -0.2934,g);
  ParCreate ('h','', 1.0318,h);
  ParCreate ('fstemmin', '', 0.285,fstemmin);
  ParCreate ('decay_a', '', -0.000000000000003232,decay_a);
  ParCreate ('decay_b', '', 22.32,decay_b);
  ParCreate ('SLAleafmin','', 0.01644612,SLAleafmin);
  ParCreate ('SLAstemmin','', 0.0005716101,SLAstemmin);
  // External Variable

  ExternVCreate('DS', '',statefield, DS);
  ExternVCreate('TempSumR','°C*d',statefield, TempSumR);
 //   WithRoots := true;
//  self.SoilLayerMod := TPlantRelatedSubMod(self.GlobMod.SubModel[3]);
//  if (WithRoots = true) and (soillayermod <> nil) then begin
    for i := 1 to 20 {tlayeredsoil(soillayermod).p_NComp} do begin
//    for i := 1 to tlayeredsoil(soillayermod).p_NComp do begin
      if i <= 9 then
        ndx_str := '_'+IntTostr(i)
      else
        ndx_str := IntTostr(i);

      ExternVCreate('WLD_'+ndx_str,'[cm/cm3]',StateField, exWLD_arr[i]);
      VarCreate ('WLD_'+ ndx_str,'',0,true, WLD[i]);
    end;
//  end;

end;



procedure Tsubpartitioning_Maize_Roots.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);

end;


procedure Tsubpartitioning_Maize_Roots.CalcRates;
var
  i:integer;
begin
   DMtot.c :=TotTMgRate.v;
   ExtPAR_varLAI.v := ExtCoeffPAR;
   
   If  (XSTAGE.v>=1)and(XSTAGE.v<2)and(SEEDRV.v>0) then
    begin
      SEEDRV.c   :=max(-SEEDRV.v,-k_SEEDRV.v*Tempfact.v);
      DMtot.c := DMtot.c-SEEDRV.c;       // Addition of seed reserves to DMtot
    end
   else  SEEDRV.c :=   0;
   ACroot.v:= max(0,ACEroot.v-DS.v*ACEroot.v/DSstop.v);
   DMFineroot.c :=  DMtot.c*ACroot.v;
   ShootGR.v :=DMtot.c*(1-ACroot.v);

   If  (XStage.v < 1)
   then  fleaf.v := 1;
   If  (XStage.v>=1) and  (LAI.v<5.5)  //   (CumPH.v<TLNO.v-2)
   then  fleaf.v := h.v + (g.v*XSTAGE.v) //      1.04-0.345*XSTAGE.v    // 1/(1+exp(flb.v)*fla.v*power(DMleaf.v,(fla.v-1)))            (holzhauser)
   else  fleaf.v := decay_a.v *power(XSTAGE.v,decay_b.v);   // 0;                                                                           (holzhauser)


   //    then  If DMleaf.v > 0
   //then fLEAF.v :=   1/(1+exp(flb.v)*fla.v*power(DMleaf.v,(fla.v-1)))
   //          else  fleaf.v:= 1
   //else  fLEAF.v := 0;


   LeafGr.v := fLEAF.v*ShootGR.v;
   fCob.v := max(0,fCob_steig.v*XStage.v+fCob_ini.v);
   //If (XStage.v>2) then begin
   //   If (XStage.v<=(ln((fCob_steig.v/fCob_e.v)/fCob_ini.v)/fCob_e.v)+2)
   //      then fCob.v := fCob_ini.v*exp(fCob_e.v*(XStage.v-2))
   //   else fCob.v := fCob_steig.v*XStage.v+fCob_steig.v/fCob_e.v-fCob_steig.v*(ln((fCob_steig.v/fCob_e.v)/fCob_ini.v)/fCob_e.v+2);
   //end
   //else fcob.v :=0;
   If DMStem.v <= fstemmin.v*DMShoot.v then fCob.v:= min(1,fCob.v);   // 0.25576 resultieren
   // aus den Messdaten, ca. 25% vom Spross sind zum Erntezeitpunkt noch Stängel.
   fcob.v:=  fcob.v/(1+fleaf.v); //Umrechnung vom Anteil an Kolben+Stängel auf Anteil an Spross.
   CobGr.v :=  ShootGr.v*fCob.v;
   StemGr.v :=(1-fLEAF.v-fCob.v)*ShootGR.v;

   DMcob.c :=  CobGr.v;
   DMleaf.c :=  LeafGr.v;
   DMStem.c :=  StemGr.v;



   //LAIleaf.c :=  SLAleaf_const.v*LeafGr.v;  // Berechnung des LAIleafs unter der Annahme einer konstanten SLA
   //LAIstem.c :=  SLAstem_const.v*StemGr.v;  // Berechnung des LAIleafs unter der Annahme einer konstanten SLA
   If (LAI.v>0) or (SeedRV.c<>0) then begin
      If(fSLA_ = SLAfGAI) then begin
          SLAleaf.v := max(SLAleafmin.v,min(SLAleafini.v,SLAl_a.v*power(LAIleaf.v,SLAl_b.v)+SLAl_a.v*SLAl_b.v*power(LAIleaf.v,SLAl_b.v-1)*LAIleaf.v));    //unteres Plateau =0.017
        //SLAleaf.v := min(SLAleafini.v,SLAl_a.v*power(LAIleaf.v,SLAl_b.v)+SLAl_a.v*SLAl_b.v*power(LAIleaf.v,SLAl_b.v-1)*LAIleaf.v) ;
        //SLAleaf.v := min(SLAleafini.v,SLAl_a.v*power(LAIleaf.v,SLAl_b.v));
        SLAstem.v := max(SLAstemmin.v,min(SLAstemini.v,SLAs_a.v*power(LAIstem.v,SLAs_b.v)+SLAs_a.v*SLAs_b.v*power(LAIstem.v,SLAs_b.v-1)*LAIstem.v));
        //SLAstem.v := min(SLAstemini.v,SLAs_a.v*power(LAIstem.v,SLAs_b.v));
      end;
      //else
      //begin
      If(fSLA_ = SLAconst) then begin
        SLAleaf.v := SLAleaf_const.v;
        SLAstem.v := SLAstem_const.v;
      end;
      If(fDroughtImpact_SLA = droughtimpact) then
        fSLAWR.v := min(1,max(1-f1fslawr.v*(psiroot.v-psiWRsla.v), fSLAmin.v))
      else
        fSLAWR.v := 1;
      SLAleaf.v := SLAleaf.v*fSLAWR.v;
      LAIleaf.c :=  SLAleaf.v*LeafGr.v;   // Berechnung des LAIleafs unter der Annahme einer über den LAI sinkenden SLA
      LAIstem.c :=  SLAstem.v*StemGr.v;   // Berechnung des LAIstem unter der Annahme einer über den LAI sinkenden SLA
   end;

      If  XStage.v>=1
       then  TSumLAI.c := max(Temp.v-Tbase6.v,0)
       else  TSumLAI.c := 0;

   If (optLAIe_calc.Option = 'logistisch') then
      If  XStage.v>=1
       then  LAIe.v :=   LAImax.v/(1+(LAImax.v/LAI0.v-1)*exp(-RGRL.v*TSumLAI.v))
       else  If  (XStage.v>=1) and (LAIe.v<=LAIkrit.v)
             then  LAIe.v :=min(2,LAI0.v*exp(RGRL.v*TSUMLAI.v))
             else  LAIe.v :=0;
   If (optLAIe_calc.Option = 'log_decay') then
      If  XStage.v>=1
        then begin
             LAIe.v :=   LAImax.v/(1+(LAImax.v/LAI0.v-1)*exp(-RGRL.v*TSumLAI.v));
             If (LAIe.v >= 0.99*LAImax.v) or Curveswitch_decay then begin
                If Curveswitch_decay = false then begin
                   CurveswitchTSUM := TSUMLAI.v;
                   Curveswitch_decay := true;
                end;
                LAIe.v := max (0, Laimax.v - 0.01*LAImax.v * exp((TSUMLAI.v-CurveswitchTSUM)* RGRdecay.v*LAImax.v));
             end;
        end
        else  If  (XStage.v>=1) and (LAIe.v<=LAIkrit.v)
             then  LAIe.v :=min(2,LAI0.v*exp(RGRL.v*TSUMLAI.v))
             else  LAIe.v :=0;

   LAIgreen.v:= max (0,(1-Sen_fact.v)*(LAIleaf.v+LAIleaf.c)+(LAIstem.v+LAIstem.c));

   If  LAIe.v<LAIkrit.v
       then LAI.v := LAIe.v
       else LAI.v := LAIgreen.v;

   LeafDuration.c := LAI.v + (LAIleaf.c + LAIstem.c)* 0.5;
   //BodBedeck.v :=  (1-exp(-exkPAR.v*LAI.v));
   BodBedeck.v :=  (1-exp(-ExtPAR_varLAI.v*LAI.v));

   if (WithRoots = true) and (soillayermod <> nil) then
      for i := 1 to tlayeredsoil(soillayermod).p_NComp do 
	  WLD[i].v := ExWLD_arr[i].v;

 If (XStage.v>=5) or (dayoftheyear(Globtime.v)>=latestharvestdate.v)or (XStage5.v>0) then begin
      LAI.v := 0;

      If XStage5.v=0 then XStage5.v := dayoftheyear(Globtime.v);
   end;
   If (XStage.v>=1) and (XStage5.v=0) then cumET_Veg.c := ETact.v else cumET_Veg.c := 0;
   If (XStage.v>0) and (XStage5.v=0) then cumET_latestharvest.c := ETact.v else cumET_latestharvest.c := 0;
end;

procedure Tsubpartitioning_Maize_Roots.integrate;
begin
  inherited;
  If (Xstage.v >=1) and (DMFineRoot.v<=0) then begin
     TempSumR.v:= 0;
     DMFineRoot.v:= DMShoot.v*ACERoot.v/(1-ACERoot.v);
     DMFineRoot.c:= DMShoot.v*ACERoot.v/(1-ACERoot.v);
     DMtot.v:= DMShoot.v+DMFineRoot.v;
   // self.DMFineRoot.v := self.DMFineroot.v;
   //  self.DMFineRoot.v:= self.DMFineroot.v;
  end;
   //DMtot.v :=  DMShoot.v+DMroot.v;
  //If CumTrans.v > 0 then TUEsim.v := DMtot.v/CumTrans.v else TUEsim.v := 0;
  //If CumET_Veg.v > 0 then WUEsim.v := DMtot.v/CumET_Veg.v else WUEsim.v := 0;
end;

procedure Register;
begin
  RegisterComponents('Maize', [Tsubpartitioning_Maize_Roots]);
end;

end.
