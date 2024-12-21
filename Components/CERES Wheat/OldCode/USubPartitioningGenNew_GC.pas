unit USubPartitioningGenNew_GC;

{ **********************************************************************
  ************************  Unit PartitionigGenNew  **************************
  **********************************************************************

  Erstellt von : Arne M. Ratjen
  Literatur :

 A. Moreno-Sotomayor, A. Weiss;
Improvements in the simulation of kernel number and
grain yield in CERES-Wheat,
Field Crops Research 88 (2004) 157–169

Jamieson, P.D., Semenov, M.A., Brooking, I.R., Francis, G.S.,
1998a. Sirius: a mechanistic model of wheat response to
environmental conditions. Eur. J. Agron. 8, 161–179.

Jamieson, P.D., Porter, J., Goudriaan, J.R., Ritchie, J.T., van
Keulen, H., Stol, W., 1998b. A comparison of the models
AFRCWHEAT2, CERES-Wheat SUCROS2 and SWHEAT
with measurements from wheat grown under drought. Field
Crops Res. 55, 23–44.


  Tag der ersten Bearbeitung  : 30.6.2008
  Tag der letzten Bearbeitung :



  **********************************************************************
  **********************************************************************
  ********************************************************************** }
interface
uses
UMod, UState,Dialogs,
USubPartitioningVegNew; //Unit in der TSubPart.... definiert ist


     Type
     TGRNFILL = (gf_Ceres, gf_Moreno, gf_CombiNew);   //Liste der Optionen
     TSubPartitioningGenNew = class(TSubPartitioningVegNew)

     protected




     public //
      //Zustandsvariablen
      G2_: TPar;
      G1_: TPar;



      TMAX: TState; //Schwellentemp. für Reduktion der Kornanlage
      DFKS: TState; //Tage zwischen BBCH 61-70
      SPIKEBM: TState; // akkumulierte Ährenbiomasse  von BBCH 39 bis 65 für Berechnung von GPSM (Jamieson 1998)
      STMWT_gf: TState;
      GRNWT: TState;
      P5: TState;




      RGFILL : TVar; //Rate of grain fill - [mg/(Plant*day)]
      RGNFIL : TVar; //Rate of N fill to grain - [mg/(Plant*day)]
      SWMIN_gf : TVar;   //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]
      TKM : TVar;
      RGFILL_new : TVar; //0-1 Funktion  g
      GPP : TVar; //Number of grain per plant [n]
      GPPvar : TVar; //Number of grain per plant [n]
      GPPend : TVar; //Number of grain per plant [n]
      Carbo_gf: TVar;
      GPSM : TVar; //Körner pro m2 [n]

      GROGRN:TVAR; //Zuwachsrate Körner [g/d]
      TOPWT_m2:TVAR;
      NSINK:TVAR; //Demand for N associated with grain filling (g N/plant/day)
      GRYD: TVAR; //Ertrag [dt/ha]


      DMEAR: TVar;
      optGRNFILL : TOption;

      TILN   : TExternV;

      private
      KFS: BOOLEAN;
      fCeres: BOOLEAN;
      fMoreno: BOOLEAN;
      fCombiNew: BOOLEAN;
      fGRNFILL : TGRNFILL;





      Frac_kernel_set : TVar; // 0-1 Funktion limitiert GPSM bei hohen Temperaturen
      //externe Variablen



       procedure createAll; override; //override, weil Prozedur schon in der Mutter drin ist
       procedure Init(var GlobMod: TMod); override;

       procedure CalcRates; override;
       published // Definitionen (für Objektinsp.)
        //Property Var_GRNYD : TVar read GRNYD write GRNYD;
        //Property Var_GROLF : TVar read GROLF write GROLF;
        property opt_GRNFILL : TGRNFILL read fGRNFILL write fGRNFILL;


     end;
           //regestriert das Submodell
   procedure Register;

implementation
uses Classes, math;


procedure TSubPartitioningGenNew.createAll;

begin
  inherited;

StateCreate('TMAX','[°C]',0,true,TMAX);
StateCreate('DFKS','[d]',0,true,DFKS);
StateCreate('SPIKEBM','[g/m2]',0,true,SPIKEBM);

StateCreate('GRNWT', '[g/Plant]',0, true,GRNWT);
StateCreate('P5', '[d]',0, true,P5);
StateCreate('STMWT_gf','[g/Plant]',0,true,STMWT_gf);

VarCreate('SWMIN_gf', '[g/plant]',0, true,SWMIN_gf);
VarCreate('TOPWT_m2', '[g/m2]',0, true,TOPWT_m2);
VarCreate('TKM','[g/kKernel]',0,true,TKM);
VarCreate('RGFILL','[mg/(Plant*day)]',0,true,RGFILL);
VarCreate('RGNFIL','[mg/(Plant*day)]',0,true,RGNFIL);
VarCreate('RGFILL_new','[0-1]',0,true,RGFILL_new);
VarCreate('GPP','[n]',0,true,GPP);
VarCreate('GPPvar','[n]',0,true,GPPvar);
VarCreate('GPPend','[n]',0,true,GPPend);
//VarCreate('G1','[-]',0,true,G1);//Parameter für GPP
VarCreate('GROGRN','[g/d]',0,true,GROGRN);
VarCreate('NSINK','[g/d]',0,true,NSINK);
VarCreate('GRYD','[dt/ha]',0,true,GRYD);
VarCreate('Carbo_gf','[g/Plant/d]',0,true,Carbo_gf);
VarCreate('GPSM','[n]',0,true,GPSM);
VarCreate('Frac_kernel_set','[n]',0,true,Frac_kernel_set);
VarCreate('DMear','[g/m2]',0,true,DMEAR);

ExternVCreate('TILN', '',statefield, TILN);

ParCreate('G1_', '[-]',6.3, G1_);
//Options
OptCreate('optGRNFILL', 'gf_moreno',optGRNFILL);
  optGRNFILL.OptionList.Clear;
  optGRNFILL.OptionList.Add('gf_Ceres');
  optGRNFILL.OptionList.Add('gf_Moreno');
  optGRNFILL.OptionList.Add('gf_CombiNew');




  //externe Variablen


end;

procedure TsubPartitioningGenNew.init(var GlobMod: TMod);  //Initialisieren
begin
  inherited init(GlobMod);

  if optGRNFILL.option = 'gf_ceres' then begin
  fGRNFILL:= gf_Ceres;
  fCeres:= true;
  fMoreno:= false;
  fCombiNew:= false;
    end;

  if optGRNFILL.option = 'gf_moreno' then begin
  fGRNFILL:= gf_Moreno;
  fCeres:= true;
  fMoreno:= true;
  fCombiNew:= false;
    end;

  if optGRNFILL.option = 'gf_combiNew' then begin
  fGRNFILL:= gf_CombiNew;
    fCeres:= false;
    fMoreno:= false;
    fCombiNew:= true;
    end;


end;
procedure TSubPartitioningGenNew.CalcRates;
 var done: BOOLEAN;

 begin

inherited;


 { Option:  nach Ceres Wheat ********************************************************************************************}
     // RGFILL nach  Cres
  if (fCeres = true)then begin
//SWMIN_gf berechnen (Stroh)
If (ISTAGE.v>=4) and (SWMIN_gf.v<=0) then begin
SWMIN_gf.v := STMWT_pl.v;                         // save value of Stemweight for labile
end;

If (ISTAGE.v>=5) and (GPP.v<=0)  then begin
   GPP.v := STMWT_pl.v*5.+G1_.v*5.;
   GPSM.v:=GPP.v*Plants.v;
end;


If (ISTAGE.v>=5) and (ISTAGE.v<=6)then begin

     if(STMWT_gf.v<=0) then STMWT_gf.v:= STMWT_pl.v;
     if(TEMPM.v<10) then RGFILL.v:= 0.065*TEMPM.v;
     if(TEMPM.v>10) then RGFILL.v:= 0.65 + (0.0787-0.00328*(TeMPMX.v-TeMPMN.v))*Power((TEMPM.v-10),0.8);
   P5.c:=+1;        //duration grainfill
   CARBO_gf.v := CARBO.v*(1-(1.2 -0.8*SWMIN_gf.v/STMWT_gf.v)*(DTT.v+100)/(P5.v+100)); //Assimilatfluss
   PTF.v:= SWMIN_gf.v/STMWT_gf.v*0.35+0.65;

   if(STMWT_gf.v<=SWMIN_gf.v) then
           GROGRN.v:= min(RGFILL.v*GPP.v*(0.65+G3_.v*0.35)*0.001,CARBO_gf.v)//0.65+G2_*0.35
           else GROGRN.v:=RGFILL.v*GPP.v*(0.65+G3_.v*0.35)*0.001;
           GRNWT.c:=GROGRN.v;
   STMWT_gf.c := CARBO_gf.v*PTF.v-GROGRN.v; //GROSTEM.v => kann negativ sein!!
   if (fMoreno = true) then STMWT_gf.c:=min(0,STMWT_gf.c);

      DMEAR.v:= GRNWT.v*Plants.v;

                    if (fMoreno=false) then begin
                     GRYD.v:= (GRNWT.v*Plants.v)/10;
                     TKM.v:= (GRNWT.v*Plants.v)/GPSM.v*1000;
                    end;

end else begin GRNWT.c:= 0; STMWT_gf.c:=0; P5.c:=0;end;

end;
 { Option:  Ceres Wheat Ende  ********************************************************************************************}


 { Option:  MORENO modifikation von Ceres********************************************************************************}
 // RGFILL_new Milchreife
if (fMoreno = true)then begin
     if  (EC.v>=73.0) and (EC.v<=77.0)
         then begin
              if (TEMPM.v>20) then RGFILL_new.v := -0.0058*Power(TEMPM.v,2) +0.2377*TEMPM.v -1.434; //Moreno~ Weiss 2003
              if(TEMPM.v<15.4) then RGFILL_new.v :=  0.065*TEMPM.v;
              if(TEMPM.v>15.4) and (TEMPM.v<20) then RGFILL_new.v:=1; // wie Ceres
     end;

     // RGFILL_new Teigreife
      if (EC.v>77) and (EC.v<=92)
         then begin
              if (TEMPM.v>20) then RGFILL_new.v := -0.0213*TEMPM.v+1.4275; //Moreno~ Weiss 2003
              if(TEMPM.v<15.4)then RGFILL_new.v :=  0.065*TEMPM.v;
              if(TEMPM.v>15.4) and (TEMPM.v<20) then RGFILL_new.v:=1; // wie Ceres
      end;

  if  (EC.v>=73) and (EC.v<=92)
       then begin
               RGFILL.v:=RGFILL.v*RGFILL_new.v;
            end;

//Faktor pot./akt. GPSM
If  (EC.v>=61) and (EC.v<=70)
         then begin

              if(DFKS.v >=1) then DFKS.c := 1;
              if(DFKS.v <=0) then DFKS.v := 1; //Tage nach Blüte
              TMAX.c := max(0,TeMPMX.v);

                     if((TMAX.v/(DFKS.v))>=25)then begin
                        Frac_kernel_set.v := -0.0627*(TMAX.v/(DFKS.v))+2.57
                     end else Frac_kernel_set.v := 1;
end else begin DFKS.c := 0; TMAX.c := 0; end;



              If(EC.v>=39) and (EC.v<=65)
              then begin
                   SPIKEBM.c :=  STMWT_pl.c*Plants.v*0.5; //Ährenbiomasse g pro m2
                   //GPSM.v := SPIKEBM.v*100 //potentielle Kornzahl pro m2
               GPSM.v := GPP.v*Plants.v;
              end else SPIKEBM.c:=0 ;
// aktuelle Kornzahl EC 65

                   if (EC.v>=70) and (done=false) then begin
                          GPSM.v:= GPSM.v*Frac_kernel_set.v; done:=true;
                  end;
If (ISTAGE.v>=5) and (ISTAGE.v<6)then begin

   P5.c:=+1;        //duration grainfill
   TKM.v:= (GRNWT.v*Plants.v)/GPSM.v*1000;
   GPP.v:= GPSM.v/Plants.v;
   GRYD.v:= (GRNWT.v*Plants.v)/10;

end else begin GRNWT.c:= 0; P5.c:=0;end;

 end;
{ *******Moreno End ******************************************************************************************************************}
{ Option:  Combi_New********************************************************************************}
                  //further modifications...to be continued
{ Option:  Combi_New End********************************************************************************}


{ N-Translokation  *****************************************************************************************************************}
if (fCeres= true) then begin

 If (ISTAGE.v>=5) and (ISTAGE.v<6)then begin
     if(TEMPM.v >10) then RGNFIL.v:= 4.8297-3.2488*max(0,TeMPM.v-1)+0.2503*(TeMPMX.v-TeMPMN.v)+4.3067*TeMPM.v;
     if(TEMPM.v <10) then RGNFIL.v:= 0.483*TeMPM.v;
     NSINK.v:= RGNFIL.v*GPP.v*1.E-6;
     //NSINK.v:= NSINK.v * NDEF4.v;        //N-Deficit not implemented yet

 end;
end; //end routine
{ Option:  drought stress End************************************************************************************************************}


{ Option:  drought stress *****************************************************************************************************************}
                  //further modifications...to be continued



{ Option:  drought stress End************************************************************************************************************}








end;//ENDE











procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningGenNew]);
end;

end.

