unit USubPartitioningGenNew;

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
UMod, UState,Dialogs,Sysutils,
USubPartitioningVegNew; //Unit in der TSubPart.... definiert ist


     Type
     TGRNFILL = (gf_Ceres, gf_Moreno, gf_jamieson);
     TGPSM = (GPSM_Ceres, GPSM_Ceres_C3, GPSM_Fischer,GPSM_Groot, GPSM_Demotes, GPSM_New, GPSM_UPDATE);
     TMKFrac = (NoFrac, MorenoKFrac);
     TAP_New = (NoAP_New, AP_New);

     TSubPartitioningGenNew = class(TSubPartitioningVegNew)
     // TSubPartitioningGenNew = class(TAbstractPlant)

     protected

     public //
      G1_C3: TPar;
      G1_C4: TPar; //Kernel number per unit at anthesis kernels/g stem
      G1_New:TPAR;
      G1_D:TPAR; // Demotes-Sotomayor
      G1_F:TPAR; // Fischer
      GT_: TPar; //Schwellentemp. für KernelFrac


      G2_C: TPar; //Kernel filling rate under optimum conditions mg per kernel per day
      G2_FischerC: TPar;
      G2_GrootC: TPar;
      G2_DemotesC: TPar;
      G2_New: TPar;

      G2_M: TPar;
      G2_FischerM: TPar;
      G2_GrootM: TPar;
      G2_DemotesM: TPar;
      //G2_NewM: TPar;
      RSWT: TPAR; //ReserveWT Ceres 4.0
      G2_J: TPar;
      G2_FischerJ: TPar;
      G2_GrootJ: TPar;
      G2_DemotesJ: TPar;
      //G2_NewJ: TPar;

      NNIEC60: TVar;
      NNIEC65: TVar; //NNI bei EC65
      TMAX: TState; //Schwellentemp. für Reduktion der Kornanlage
      DFKS: TState; //Tage zwischen BBCH 61-70
      SPIKEBM: TState; // akkumulierte Ährenbiomasse  von BBCH 39 bis 65 für Berechnung von GPSM (Jamieson 1998)
      GRNWT: TState;
      STMWT_GC: TState;
      P5: TState;
      cGrainN: TState;
      AssimPool: TState;  //Assimilat-Pool analog zu Sirius
      Carbo_gf: TVar;

      Q45: TVAR;
      TEMP: TVAR;    //schnittstelle für GrowthwCurve
      RGFILL : TVar; //Rate of grain fill - [mg/(Plant*day)]
      RGNFIL : TVar; //Rate of N fill to grain - [mg/(Plant*day)]
      SWMIN_gf : TVar;   //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]
      TKM : TVar;
      RGFILL_New : TVar; //0-1 Funktion  g
      GPP : TVar; //Number of grain per plant [n]
      GPPvar : TVar; //Number of grain per plant [n]
      GPPend : TVar; //Number of grain per plant [n]
      GPSM : TVar; //Körner pro m2 [n]

      Plants_GC : TVar; //
      GROGRN:TVAR; //Zuwachsrate Körner [g/d]
      TOPWT_m2:TVAR;
      NSINK:TVAR; //Demand for N associated with grain filling (g N/plant/day)
      GRYD: TVAR; //Ertrag [dt/ha]
      DMEAR: TVar;
      optGRNFILL : TOption;
      optGPSM : TOption;
      optMKFrac : TOption;
      optAP_New : TOption;

      GPSM_UD : TState; // gets GPSM from measurment file
      AssimPool_UD: TState;
      NcShoot: TExternV;
      DM_v: TExternV;   // DM from GrowthCurve
      DMSTEM_v: TExternV;   // DMSTEM from GrowthCurve
      GRNN_v: TExternV;   // GRNN from GrowthCurve
      IPOL_DMSTEM_v: TExternV;
      DM_c: TExternV;   // DM from GrowthCurve
      GlobRad: TExternV;   // Globalstrahlung aus Wetterdatei
      DMSTEM_c: TExternV;   // DMSTEM from GrowthCurve
      GRNN_c: TExternV;   // GRNN from GrowthCurve
      procedure UpDateValues; override;
    private

      set49, set65, done, done2, AssimPool_set: BOOLEAN;
      KFS: BOOLEAN;
      fCeres: BOOLEAN;
      fMoreno: BOOLEAN;



      fGRNFILL : TGRNFILL;
      fGPSM: TGPSM;
      fMKFrac: TMKFrac;
      fAP_New: TAP_New;
      PAR_arr: Array [1..45] of real; // CumPAR for Demotes
      
      MTEMP_arr: Array [1..45] of real; // CumMTemp for Demotes
      ProzN,critN,AvDM,AvShootN: real;
//Prozedur CalcAssimPool:
       {ZW: double ;  //Zuwachs DMShoot zw. EC49 und EC65
       ZWS: double; //Zuwachs DMShoot zw. EC49 und EC65
       DMS49: double;//DMStem bei EC49
       DM49: double;//DMShoot bei EC49
       DMS65: double;//DMStem bei EC65
       DM65: double;//DMShoot bei EC65} // 16.12.10 hp
       ZW,     //Zuwachs DMShoot zw. EC49 und EC65
       ZWS,    //Zuwachs DMShoot zw. EC49 und EC65
       DMS49,  //DMStem bei EC49
       DM49,   //DMShoot bei EC49
       DMS65,  //DMStem bei EC65
       DM65,   //DMShoot bei EC65
       STEM1:real;
       STEM2:real;
//       AP_Frac: double;
       AP_Frac: real; // 10.12.10 hp

//--------------------------------

      Frac_kernel_set : TVar; // 0-1 Funktion limitiert GPSM bei hohen Temperaturen
      //externe Variablen
      // procedure SetUpDateValue; override;
       procedure CalcNNI;
       procedure CalcAssimPool;
       procedure CalcQ45;
       procedure GRFILL;
       procedure Gateway;
       procedure CalcGPSM;
       procedure KernelFrac;
       procedure createAll; override; //override, weil Prozedur schon in der Mutter drin ist

       procedure Init(var GlobMod: TMod); override;

       procedure CalcRates; override;
        published // Definitionen (für Objektinsp.)

        //Property Var_GRNYD : TVar read GRNYD write GRNYD;
        Property Var_GROLF : TVar read GROLF write GROLF;

        property opt_GRNFILL : TGRNFILL read fGRNFILL write fGRNFILL;
        property opt_GPSM : TGPSM read fGPSM write fGPSM;
        property opt_MKFrac : TMKFrac read fMKFrac write fMKFrac;
        property opt_AP_New : TAP_New read fAP_New write fAP_New;

        Property Ex_DM_v : TExternV read DM_v write DM_v;
        Property Ex_DMSTEM_v : TExternV read DMSTEM_v write DMSTEM_v;
        Property Ex_GRNN_v : TExternV read GRNN_v write GRNN_v;
        Property Ex_DM_c : TExternV read DM_c write DM_c;
        Property Ex_DMSTEM_c : TExternV read DMSTEM_c write DMSTEM_c;
        Property Ex_GRNN_c : TExternV read GRNN_c write GRNN_c;
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
StateCreate('cGRAINN','[%]',0,true,cGRAINN);
StateCreate('STMWT_GC','[g/plant]',0,true,STMWT_GC);
StateCreate('AssimPool','[g/m2]',0,true,AssimPool);
StateCreate('GRNWT', '[g/Plant]',0, true,GRNWT);
StateCreate('P5', '[d]',0, true,P5);
StateCreate('GPSM_UD', '[K/m2]',0, true,GPSM_UD);
StateCreate('AssimPool_UD', '[g/m2]',0, true,AssimPool_UD);
VarCreate('Carbo_gf','[g/m2]',0,true,Carbo_gf);

VarCreate('SWMIN_gf', '[g/plant]',0, true,SWMIN_gf);
VarCreate('TOPWT_m2', '[g/m2]',0, true,TOPWT_m2);
VarCreate('TKM','[g]',0,true,TKM);
VarCreate('RGFILL','[mg/(Plant*day)]',0,true,RGFILL);
VarCreate('RGNFIL','[mg/(Plant*day)]',0,true,RGNFIL);
VarCreate('RGFILL_New','[0-1]',0,true,RGFILL_New);
VarCreate('GPP','[n]',0,true,GPP);


//VarCreate('G1','[-]',0,true,G1);//Parameter für GPP
VarCreate('Q45','',0,true,Q45);
VarCreate('GROGRN','[g/d]',0,true,GROGRN);
VarCreate('NSINK','[g/d]',0,true,NSINK);
VarCreate('GRYD','[dt/ha]',0,true,GRYD);
VarCreate('GPSM','[n]',0,true,GPSM);
VarCreate('Frac_kernel_set','[n]',0,true,Frac_kernel_set);
VarCreate('DMear','[g/m2]',0,true,DMEAR);
VarCreate('TEMP', '[°C]',0, true,TEMP);
VarCreate('Plants_GC', '[n/m2]',230, true,Plants_GC);
ExternVCreate('TILN', '',statefield, TILN);
ExternVCreate('NcShoot', '%',statefield,NcShoot);
ExternVCreate('DM', '[g/m2]',statefield, DM_v);
ExternVCreate('DMSTEM', '[g/m2]',statefield, DMSTEM_v);
ExternVCreate('GRNN', '[g/m2]',statefield, GRNN_v);
 ExternVCreate('DM', '[g/m2]',ratefield, DM_c);
 ExternVCreate('DMSTEM', '[g/m2]',ratefield, DMSTEM_c);
 ExternVCreate('GRNN', '[g/m2]',ratefield, GRNN_c);
 ExternVCreate('GlobRad', '[W/m2]',statefield, GlobRad);


ParCreate('RSWT', '[g/m2]',0, RSWT);
ParCreate('GT_', '[-]',25, GT_);
ParCreate('G1_C4', '[-]',15, G1_C4);
ParCreate('G1_C3', '[-]',10.3, G1_C3);
ParCreate('G1_New', '[-]',1, G1_New);
ParCreate('G1_D', '[-]',1, G1_D);
ParCreate('G1_F', '[-]',1, G1_F);

ParCreate('G2_C', '[-]',0, G2_C);
ParCreate('G2_FischerC', '[-]',0, G2_FischerC);
ParCreate('G2_DemotesC', '[-]',0, G2_DemotesC);
ParCreate('G2_GrootC', '[-]',0, G2_GrootC);
ParCreate('G2_New', '[-]',3764.72, G2_New);

ParCreate('G2_M', '[-]',0, G2_M);
ParCreate('G2_FischerM', '[-]',0, G2_FischerM);
ParCreate('G2_DemotesM', '[-]',0, G2_DemotesM);
ParCreate('G2_GrootM', '[-]',0, G2_GrootM);


ParCreate('G2_J', '[-]',0, G2_J);
ParCreate('G2_FischerJ', '[-]',0, G2_FischerJ);
ParCreate('G2_DemotesJ', '[-]',0, G2_DemotesJ);
ParCreate('G2_GrootJ', '[-]',0, G2_GrootJ);



VarCreate('NNIEC60', '[-]',0,true, NNIEC60);
VarCreate('NNIEC65', '[-]',0,true, NNIEC65);
//Options
OptCreate('optGRNFILL', 'gf_Ceres',optGRNFILL);
  optGRNFILL.OptionList.Clear;
  optGRNFILL.OptionList.Add('gf_Ceres');
  optGRNFILL.OptionList.Add('gf_Moreno');
  optGRNFILL.OptionList.Add('gf_jamieson');

  OptCreate('optGPSM', 'GPSM_Ceres',optGPSM);
  optGPSM.OptionList.Clear;
  optGPSM.OptionList.Add('GPSM_Ceres');
  optGPSM.OptionList.Add('GPSM_Fischer');
  optGPSM.OptionList.Add('GPSM_Groot');
  optGPSM.OptionList.Add('GPSM_Demotes');
  optGPSM.OptionList.Add('GPSM_Ceres_3');
  optGPSM.OptionList.Add('GPSM_UPDATE');
  optGPSM.OptionList.Add('GPSM_New');

  OptCreate('optMKFrac', 'NoFrac',optMKFrac);
  optMKFrac.OptionList.Clear;
  optMKFrac.OptionList.Add('NoFrac');
  optMKFrac.OptionList.Add('MorenoKFrac');

  OptCreate('optAP_New', 'NoAP_New',optAP_New);
  optAP_New.OptionList.Clear;
  optAP_New.OptionList.Add('NoAP_New');
  optAP_New.OptionList.Add('AP_New');
  //externe Variablen


end;

procedure TsubPartitioningGenNew.init(var GlobMod: TMod);  //Initialisieren
begin

  inherited init(GlobMod);

  if optGRNFILL.option = 'gf_ceres' then begin
  fGRNFILL:= gf_Ceres;

    end;

  if optGRNFILL.option = 'gf_moreno' then begin
  fGRNFILL:= gf_Moreno;

    end;

  if optGRNFILL.option = 'gf_jamieson' then begin
  fGRNFILL:= gf_jamieson;

    end;

  if optGPSM.option = 'gpsm_ceres' then begin
  fGPSM:= GPSM_Ceres;
    end;
      if optGPSM.option = 'gpsm_ceres_3' then begin
  fGPSM:= GPSM_Ceres_C3;
    end;

  if optGPSM.option = 'gpsm_fischer' then begin
  fGPSM:= GPSM_Fischer;
       end;


  if optGPSM.option = 'gpsm_new' then begin
    fGPSM:= GPSM_New;

    end;
  if optGPSM.option = 'gpsm_groot' then begin
  fGPSM:= GPSM_Groot;

    end;

  if optGPSM.option = 'gpsm_demotes' then begin
  fGPSM:= GPSM_Demotes;

    end;

  if optGPSM.option = 'gpsm_update' then begin
  fGPSM:= GPSM_UPDATE;

    end;

  if optMKFrac.option = 'nofrac' then begin
  fMKFrac:= NoFrac;
    end;

  if optMKFrac.option = 'morenokfrac' then begin
  fMKFrac:= MorenoKFrac;
    end;

    if optAP_New.option = 'ap_new' then begin
  fAP_New:= AP_New;
    end;

      if optAP_New.option = 'noap_new' then begin
  fAP_New:= NoAp_New;
    end;

     STEM1:=0;
     STEM2:=0;
     done:=false;
     done2:=false;
     STMWT_GC.c:=0;
     SPIKEBM.v:=0;
     Q45.v:=0;
     AssimPool_set:= false;
     prozN:= 0;
     critN:= 0;
     AvDM:= 0;
     AvShootN:= 0;
     set49:=false;
     set65:=false;
end;//Ende INI


procedure TSubPartitioningGenNew.CalcAssimPool;
 begin
 if (fGPSM <> GPSM_UPDATE) then begin  //wenn GPSM_UPDATE wird auch AssimPool wird aus Datei vorgegeben
     if(fAP_New= NoAp_New) then
       begin
            if(fGRNFILL= gf_jamieson) then begin
                 if (EC.v>=65) and (AssimPool_set=false)  then begin      //AP nach Sirius/APSIM
                               if(fAP_New = NoAp_New) then begin
                                          AssimPool.v:= DM_v.v*0.25; AssimPool_set:=true;
                               end;
                 end;
            end else
                if (EC.v>=49) and (SWMIN_gf.v<=0) then
                begin
                     SWMIN_gf.v:=DMSTEM_v.v; AssimPool_set:=true;
                end;
       end else

      begin //AssimPoolNew

        if (EC.v>=65) and (set65 = false) then
         begin
                  DM65:= DM_v.v;
                  CalcNNI;
                  AssimPool.v:=-0.000007*power(DM65,2)+0.1669*min(2.1,1/NNIEC65.v)*DM65-0.0689*DM65;
                                      set65:= true;
                  AssimPool_set:=true;
         end;
   end;
 end;
end ;

procedure TSubPartitioningGenNew.UpDateValues;

begin

 inherited;
 if UpdateValue(GPSM_UD.Name)<>0 then begin
   if (fGPSM = GPSM_UPDATE) then begin
      GPSM.v:=UpdateValue(GPSM_UD.Name); //write
      AssimPool.v:=UpdateValue(AssimPool_UD.Name);
   end;
 end;
end;

procedure TSubPartitioningGenNew.CalcNNI;
var

i: integer;

begin

    if(EC.v>=60) and (NNIEC60.v<=0) then begin
              if(DM_v.v/100<1.55)  then critN:=4.4  else critN:=5.35*Power(DM_v.v/100,-0.442);
              prozN:= NcShoot.v;
              NNIEC60.v:= prozN/critN;
    end;
    if(EC.v>=65) and (NNIEC65.v<=0) and (fAP_New = AP_New) then begin
              if(DM_v.v/100<1.55)  then critN:=4.4  else critN:=5.35*Power(DM_v.v/100,-0.442);
              prozN:= NcShoot.v;
              NNIEC65.v:= prozN/critN;
    end;

end;//end  CalcNNI

procedure TSubPartitioningGenNew.GRFILL;
begin
     if (fGRNFILL= gf_Ceres)then begin
              If (ISTAGE.v>=5) and (ISTAGE.v<=6)then begin
              if(TEMPM.v<10) then RGFILL.v:= max(0.065*TEMPM.v,0);
              if(TEMPM.v>=10) then RGFILL.v:=max(0.65 + (0.0787-0.00328*(TeMPMX.v-TeMPMN.v))*Power((TEMPM.v-10),0.8),0);
     end;

end;

if (fGRNFILL= gf_Moreno) or (fGRNFILL= gf_jamieson) then begin


//wie Ceres
      If (ISTAGE.v>=5) and (ISTAGE.v<=6)then begin
         if(TEMPM.v<10) then RGFILL.v:= max(0.065*TEMPM.v,0);
         if(TEMPM.v>=10) then RGFILL.v:=max(0.65 + (0.0787-0.00328*(TeMPMX.v-TeMPMN.v))*Power((TEMPM.v-10),0.8),0);
//Modifikation Moreno
         if  (EC.v>=73.0) and (EC.v<=77.0)then begin
              if (TEMPM.v>20) then RGFILL_New.v := max(-0.0058*Power(TEMPM.v,2) +0.2377*TEMPM.v -1.434,0); //Moreno~ Weiss 2003
              if(TEMPM.v<15.4) then RGFILL_New.v :=  max(0.065*TEMPM.v,0);
              if(TEMPM.v>15.4) and (TEMPM.v<20) then RGFILL_New.v:=1; // wie Ceres
     end;

     // RGFILL_New Teigreife
      if (EC.v>77) and (EC.v<=92)
         then begin
              if (TEMPM.v>20) then RGFILL_New.v := max(-0.0213*TEMPM.v+1.4275,0); //Moreno~ Weiss 2003
              if(TEMPM.v<15.4)then RGFILL_New.v :=  max(0.065*TEMPM.v,0);
              if(TEMPM.v>15.4) and (TEMPM.v<20) then RGFILL_New.v:=1; // wie Ceres
      end;

  if  (EC.v>=73) and (EC.v<=92)
       then begin
               RGFILL.v:=max(RGFILL.v*RGFILL_New.v,0);
            end;
end;end;

end;//ENDE GRFILL


procedure TSubPartitioningGenNew.KernelFrac;
begin
if(fMKFrac=MorenoKFrac) then begin
           If  (EC.v>=61) and (EC.v<=70)
         then begin

              if(DFKS.v >=1) then DFKS.c := 1;
              if(DFKS.v <=0) then DFKS.v := 1; //Tage nach Blüte
              TMAX.c := max(0,TeMPMX.v);

                     if((TMAX.v/(DFKS.v))>=GT_.v)then begin
                        Frac_kernel_set.v := -0.0627*(TMAX.v/(DFKS.v))+2.57
                     end else Frac_kernel_set.v := 1;
end else begin DFKS.c := 0; TMAX.c := 0; end;

 // aktuelle Kornzahl EC 65

                   if (EC.v>=70) and (done=false) then begin
                          GPSM.v:= GPSM.v*Frac_kernel_set.v; done:=true;
                          GPP.V:=GPSM.v/Plants_GC.v;
                  end;
end;
end;//Ende KernelFrac



procedure TSubPartitioningGenNew.Gateway;

begin
{GrothCurve-Schnittstelle********************************************************************************************
vorgegebene INPUT-Groessen:
SWMIN_gf  : Stängelgewicht bei EC49
Carbo_gf  : täglicher Zuwachs
STMWT_GC  : Stängelgewicht (Startwert) bei EC65
Plants_GC    : berechnet aus den Ährentragenden Trieben pro m2 und der simulierten Triebzahl pro Einzelpflanze
}


      if (EC.v<=65) and (DMSTEM_v.v>0) then begin           //STMWT wird bis EC65 vorgegeben
         STMWT_GC.v:=DMSTEM_v.v;                              //nur für Ceres 3 Ansatz
         STMWT_GC.c:=DMSTEM_c.v;
      end;
      if (EC.v<=65) and (XSTAGE.v<5) then STMWT_GC.c:=DMSTEM_c.v;


      if (DM_v.v>0) and (EC.v>=39)then Carbo_gf.v:=DM_c.v;    //Carbo zuweisen
end;

procedure TSubPartitioningGenNew.CalcQ45;
var
i: integer;
SUMPAR, SUMMTEMP: real;
begin
if(EC.v>=20) and (Ec.v<60) then begin

              for i := 44 downto 1 do begin//Werte Rücken
                  PAR_arr[i+1]:=PAR_arr[i];
                  MTEMP_arr[i+1]:=MTEMP_arr[i];
              end;
     PAR_arr[1]:=GlobRad.v*0.48;
     MTEMP_arr[1]:= TEMPM.v;
end;

if(EC.v>=60) and (Q45.v<=0) then begin
                 SUMPAR:=0;
                 SUMMTEMP:=0;
                 for i := 1 to 45 do begin
                     SUMPAR:=   SUMPAR+   PAR_arr[i];
                     SUMMTEMP:= SUMMTEMP+ MTEMP_arr[i];
                 end;
                 Q45.v:= SUMPAR/SUMMTEMP;
     end;
end;

procedure TSubPartitioningGenNew.CalcGPSM;
    var SHOOT: real;
    var SUMPAR: real;
    var SUMMTEMP: real;
    var i :integer;

begin
   if (fGPSM <> GPSM_UPDATE) then begin
   Shoot:=0;

  if (fGPSM=GPSM_Ceres_C3)then begin
     If (EC.v>=69) and (GPSM.v<=0)  then begin
        GPSM.v := STMWT_GC.v*G1_C3.v;
        //GPP.v:=GPSM.v/Plants_GC.v;
     end;
  end;
  if (fGPSM=GPSM_Ceres)then begin
     If (EC.v>=69) and (GPSM.v<=0)  then begin //End of Stage 4 (CW 2.0/3.0,4.0)
        GPSM.v := (DM_v.v)*G1_C4.v; //GRNUM = (LFWT+STWT+RSWT)*G1CWT (CW 4.0)
        //GPP.v:=GPSM.v/Plants_GC.v;
     end;
  end;
  if (fGPSM=GPSM_Fischer)then begin
     // If(EC.v>=39) and (GPSM.v<=0)
      If(EC.v>=39) and (EC.v<=65) then begin
                  SPIKEBM.c :=  DM_c.v*0.5;
                  { if(STEM1<=0) then STEM1:=DMSTEM_v.v;
                   if(STEM2<=0) and (EC.v>=65)  then begin
                                STEM2:=DMSTEM_v.v;
                                SPIKEBM.v :=  (STEM2-STEM1)*0.5;}
                  GPSM.v := SPIKEBM.v*100*G1_F.v; //18.08.09 Genotypischer Parameter eingeführt
      end else SPIKEBM.c:=0 ;

                   //GPP.v:=GPSM.v/Plants_GC.v;

  end;

  if (fGPSM=GPSM_Groot)then begin
{
	TADW = DMShoot bei EC60  [kg/ha]
}
  If (EC.v>=60) and (GPSM.v<=0)  then begin
        GPSM.v:=(35E6+14E3*(DM_v.v*10))/1E4;
        //GPSM.v:=(G1_Groot.v+14E3*(DM_v.v*10))/1E4+(7836.5*ln(NNI.v)+ 1681.3); //NUMGR = 3500E4+1.4E4*TADW [GR/ha],TADW = DMShoot bei EC60  [kg/ha]
        //GPP.v := GPSM.v/Plants_GC.v;
     end;
  end;

  if (fGPSM=GPSM_Demotes) then begin
     CalcQ45;
  if (EC.v>=60) and (NNIEC60.v<>0)  then begin

  if(Q45.v<>0) and (GPSM.v=0) then
  GPSM.v:= (-4091.8+12160*ln(NNIEC60.v)+41889*Q45.v)*G1_D.v; //18.08.09 Genotypischer Parameter eingeführt
  end;
   end;

if (fGPSM=GPSM_New)then begin
calcNNI; calcQ45;

 If (EC.v>=65) and (GPSM.v<=0)  then begin
//Shoot:=DM_v.v;
 GPSM.v:= G1_New.v*(148.07*power(ln(DM_v.v*NNIEC60.v*Q45.v),2.7568));     
   end;
     end;
 end;
end;//CalcGPSM Ende




procedure TSubPartitioningGenNew.CalcRates;
begin


     inherited;
     Gateway;
     CalcGPSM;
     KernelFrac;GRFILL;
     CalcNNI;
     if (AssimPool_set= false) then CalcAssimPool;

If (ISTAGE.v>=5) and (ISTAGE.v<=6)then begin
   P5.c:=+1;        //duration grainfill
   //Carbo.v := CARBO.v*(1-(1.2 -0.8*SWMIN_gf.v/STMWT_GC.v)*(DTT.v+100)/(P5.v+100)); //Assimilatfluss
   PTF.v:=1;                                             //PTF.v:= SWMIN_gf.v/STMWT_pl.v*0.35+0.65;
     if (fGRNFILL = gf_Ceres) then begin
           {case fGPSM of
           GPSM_Ceres: GROGRN.v:=RGFILL.v*GPSM.v*G2_C.v*0.001;
           GPSM_Fischer: GROGRN.v:=RGFILL.v*GPSM.v*G2_FischerC.v*0.001;

           GPSM_Groot: GROGRN.v:=RGFILL.v*GPSM.v*G2_GrootC.v*0.001;
           GPSM_Demotes: GROGRN.v:=RGFILL.v*GPSM.v*G2_DemotesC.v*0.001;
           GPSM_New: GROGRN.v:=RGFILL.v*GPSM.v*2.5*0.001;
           end;}
           GROGRN.v:=RGFILL.v*GPSM.v*G2_C.v*0.001; //GPSM kommt aus UpDateDatei
       end;
      if (fGRNFILL = gf_Moreno) then begin
           {case fGPSM of
           GPSM_Ceres: GROGRN.v:=RGFILL.v*GPSM.v*G2_M.v*0.001;
           GPSM_Fischer: GROGRN.v:=RGFILL.v*GPSM.v*G2_FischerM.v*0.001;

           GPSM_Groot: GROGRN.v:=RGFILL.v*GPSM.v*G2_GrootM.v*0.001;
           GPSM_Demotes: GROGRN.v:=RGFILL.v*GPSM.v*G2_DemotesM.v*0.001;
           GPSM_New: GROGRN.v:=RGFILL.v*GPSM.v*2.5*0.001;
           end;}
           GROGRN.v:=RGFILL.v*GPSM.v*G2_M.v*0.001;//GPSM kommt aus UpDateDatei
      end;

       {if (fGRNFILL = gf_Jamieson) then begin
           case fGPSM of
           GPSM_Ceres: GROGRN.v:=RGFILL.v*GPSM.v*G2_J.v*0.001;
           GPSM_Fischer: GROGRN.v:=RGFILL.v*GPSM.v*G2_FischerJ.v*0.001;
           GPSM_UPDATE: GROGRN.v:=RGFILL.v*GPSM.v*G2_FischerJ.v*0.001;
           GPSM_Groot: GROGRN.v:=RGFILL.v*GPSM.v*G2_GrootJ.v*0.001;
           GPSM_Demotes: GROGRN.v:=RGFILL.v*GPSM.v*G2_DemotesJ.v*0.001;
           GPSM_New: GROGRN.v:=RGFILL.v*GPSM.v*2.5*0.001;
           end;


      end;}
        if(fGRNFILL= gf_Ceres) then begin
              if(STMWT_GC.v)<=(SWMIN_gf.v) then GROGRN.v:= min(GROGRN.v,Carbo_gf.v)
              else GROGRN.v:=min(STMWT_GC.v+Carbo_gf.v-SWMIN_gf.v,GROGRN.v);


        end else begin
              if (AssimPool.v <= 0) then
              GROGRN.v:= min(GROGRN.v,Carbo_gf.v)
              else GROGRN.v:=min(AssimPool.v+Carbo_gf.v,GROGRN.v);
              AssimPool.c := (Carbo_gf.v*PTF.v-GROGRN.v);
        end;

           STMWT_GC.c := (Carbo_gf.v-GROGRN.v);
           GRNWT.c:=GROGRN.v;

           //TKM.v:= GRNWT.v/GPSM.v*1000;
           GRYD.v:= GRNWT.v/10;

end else begin GROGRN.v:=0; GRNWT.c:= 0; P5.c:=0; AssimPool.c:=0; end;

end;//ENDE

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningGenNew]);
end;

end.

