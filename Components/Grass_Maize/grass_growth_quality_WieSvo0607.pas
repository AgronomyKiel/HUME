unit grass_growth_quality_WieSvo0607;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState,math,IniFiles, UAbstractPlant, USoilMineralisation,
  UlayeredSoil;

Type

TGrass_growth_quality = class(TAbstractPlant)

private

springcut : boolean;
function WLD_z_t_f ( z1, z2, t, Zrmax, Zr0, Kz,
                     SRLmax, SRL0, kL, ka : real): real;


protected
 function GetLAI:THumeNumEntity; override;
    procedure SetLai(NewLAI:THumeNumEntity); override;
  function GetCropHeight:THumeNumEntity; override;
  procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;
function GetNUptakeRate:THumeNumEntity; override;
  procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); override;

 function GetWLD(Index:Integer):THumeNumEntity; override;
 procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); override;




public
  AGE : TVar;   //
  cai : TVar;   //
  dW : TVar;   //
  GI : TVar;   //
  LAI : TVar;   //
  radiation : TVar;   //
  RI : TVar;   //
  rmax : TVar;   //
  SW1 : TVar;   //
  TI : TVar;   //
  WI : TVar;   //
  WI_2 : TVar;   //
  cropHeight : TVar;//   Bestandshöhe
  //quality
  daylength : TVar;   //
  mchr : TVar;   //
  pchr : TVar;   //
  pechr : TVar;   //
  quality : TVar;   //
  r : TVar;   // 
  rchr : TVar;   //
  TAGB : TVar;   // 
  TAGLI : TVar;   // 
  TAGX : TVar;   // 
  tchr : TVar;   //
  tresmax : TVar;
 
  TLAM : TVar;   // 
  TNR : TVar;   //
   fertig : TVAR;

  // Constant Variables

  SW : TState;   // 
  W : TState;   // 
   zr : TState; // Wurzellänge
  shootN : TState;  //N-MEnge
  TSum : TState;  //Temperatursumme
   spechr : TState;   //  sumof change rates

             // Parameters
  agelim : TPar;   // 
  agend : TPar;   // 
  ak : TPar;   //
  akm : TPar;   // 
  begbas : TPar;   // 
  begsum : TPar;   // 
  cank : TPar;   // 
  clai : TPar;   //
  etpa : TPar;   // 
  etpb : TPar;   // 
  lai50 : TPar;   //
  laih : TPar;   // 
  lail : TPar;   // 
  rk : TPar;   // 
  rmlo : TPar;   // 
  rmxp : TPar;   // 
  rs : TPar;   // 
  swact : TPar;   // 
  swmax : TPar;   //
  swthr : TPar;   // 
  tk1 : TPar;   // 
  tk2 : TPar;   // 
  topt : TPar;   // 
  tpmax : TPar;   // 
  tthr : TPar;   // 
  w0 : TPar;   //
  wh : TPar; // dW/Bestandshöhe
  al : TPar;   //
  bl : TPar;   //
  chrk : TPar;   //
  funct : TPar;   //
  cut1 : TPar;   //
  cutW : TPar;   //
  mchr_switch : TPar;   //
  mfk : TPar;   //
  pk : TPar;   //
  pthr : TPar;   //
  qlat : TPar;   //
  qmax : TPar;   //
  qmin : TPar;   //
  qphsw : TPar;   //
  rchr_switch : TPar;   //
  rkq : TPar;   //
  rthrq : TPar;   //
  schr50 : TPar;   //
  tkq : TPar;   //
  tthrq : Tpar;
  oldharvestdate : TPar;   //


             // External Variables
  pETP : TExternV;   //
  GlobRad : TExternV;   //
  TransRatio : TExternV;   //
  Rain : TExternV;   //
  Temp : TExternV;   //





  Wld_arr : TSoilVarArray;  // Wurzellängendichten [cm.cm-3]
WL_arr  : TSoilVarArray;  // Wurzellängen [cm.cm-2]

N_Rootcomp : TVar;

Tiefe : TSoilExtArray;

zr_0    : TPar;           // Wurzeltiefe zur Pflanzung / Aussaat [cm]
zr_max  : TPar;           // maximale Wurzeltiefe [cm]

WL_0    : TPar;           // Wurzellänge zur Pflanzung / Aussaat [cm]
WL_max  : TPar;           // maximale Wurzellänge [cm]

k_z,                      // Wachstumsratenparameter für Tiefenentwicklung [cm]
k_Wl,
K_a
 : Tpar;

SRL,                       // Sum of root length [cm/cm2]
SRL_eff : Tvar;                    // Total root length of functional roots (cm.cm-2)



  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override; 


published
  Property Var_AGE : TVar read AGE write AGE;
  Property Var_cai : TVar read cai write cai;
  Property Var_dW : TVar read dW write dW;
  Property Var_GI : TVar read GI write GI;
  Property Var_LAI : TVar read LAI write LAI;
  Property Var_radiation : TVar read radiation write radiation;
  Property Var_RI : TVar read RI write RI;
  Property Var_rmax : TVar read rmax write rmax;
  Property Var_SW1 : TVar read SW1 write SW1;
  Property Var_TI : TVar read TI write TI;
  Property Var_WI : TVar read WI write WI;
  Property Var_WI_2 : TVar read WI_2 write WI_2;
  Property Var_cropHeight : Tvar read cropHeight write cropHeight;

  Property Var_daylength : TVar read daylength write daylength;
  Property Var_mchr : TVar read mchr write mchr;
  Property Var_pchr : TVar read pchr write pchr;
  Property Var_pechr : TVar read pechr write pechr;
  Property Var_quality : TVar read quality write quality;
  Property Var_r : TVar read r write r;
  Property Var_rchr : TVar read rchr write rchr;
  Property Var_TAGB : TVar read TAGB write TAGB;
  Property Var_TAGLI : TVar read TAGLI write TAGLI;
  Property Var_TAGX : TVar read TAGX write TAGX;
  Property Var_tchr : TVar read tchr write tchr;
  Property Var_tresmax : TVar read tresmax write tresmax;

  Property Var_TLAM : TVar read TLAM write TLAM;
  Property Var_TNR : TVar read TNR write TNR;

   Property Par_fertig : TVar read fertig write fertig;

  Property St_spechr : TState read spechr write spechr;
  Property St_SW : TState read SW write SW;
  Property St_W : TState read W write W;
  Property St_zr : TState read zr write zr;
  Property St_shootN : TState read ShootN write ShootN;
  Property St_TSum : TState read TSum write TSum;


         // Parameters
  Property Par_agelim : TPar read agelim write agelim;
  Property Par_agend : TPar read agend write agend;
  Property Par_ak : TPar read ak write ak;
  Property Par_akm : TPar read akm write akm;
  Property Par_begbas : TPar read begbas write begbas;
  Property Par_begsum : TPar read begsum write begsum;
  Property Par_cank : TPar read cank write cank;
  Property Par_clai : TPar read clai write clai;
  Property Par_etpa : TPar read etpa write etpa;
  Property Par_etpb : TPar read etpb write etpb;
  Property Par_lai50 : TPar read lai50 write lai50;
  Property Par_laih : TPar read laih write laih;
  Property Par_lail : TPar read lail write lail;
  Property Par_rk : TPar read rk write rk;
  Property Par_rmlo : TPar read rmlo write rmlo;
  Property Par_rmxp : TPar read rmxp write rmxp;
  Property Par_rs : TPar read rs write rs;
  Property Par_swact : TPar read swact write swact;
  Property Par_swmax : TPar read swmax write swmax;
  Property Par_swthr : TPar read swthr write swthr;
  Property Par_tk1 : TPar read tk1 write tk1;
  Property Par_tk2 : TPar read tk2 write tk2;
  Property Par_topt : TPar read topt write topt;
  Property Par_tpmax : TPar read tpmax write tpmax;
  Property Par_tthr : TPar read tthr write tthr;
  Property Par_w0 : TPar read w0 write w0;
  Property Par_wh : TPar read wh write wh;

  property  Par_zr0   : TPar read zr_0 write zr_0;
  property  Par_zrmax : TPar read zr_max write zr_max;
  property  Par_kz    : TPar read k_z write k_z;
  property Par_Wl0   : TPar read Wl_0 write Wl_0;
  property Par_Wlmax : TPar read WL_max write WL_max;
  property Par_kWL   : TPar read k_WL write k_WL;


  Property Par_al : TPAr read al write al;
  Property Par_bl : TPAr read bl write bl;
  Property Par_chrk : TPAr read chrk write chrk;
  Property Par_funct : TPAr read funct write funct;
  Property Par_mchr_switch : TPAr read mchr_switch write mchr_switch;
  Property Par_mfk : TPAr read mfk write mfk;
  Property Par_pk : TPAr read pk write pk;
  Property Par_pthr : TPAr read pthr write pthr;
  Property Par_qlat : TPAr read qlat write qlat;
  Property Par_qmax : TPAr read qmax write qmax;
  Property Par_qmin : TPAr read qmin write qmin;
  Property Par_qphsw : TPAr read qphsw write qphsw;
  Property Par_rchr_switch : TPAr read rchr_switch write rchr_switch;
  Property Par_rkq : TPAr read rkq write rkq;
  Property Par_rthrq : TPAr read rthrq write rthrq;
  Property Par_schr50 : TPAr read schr50 write schr50;
  Property Par_tkq : TPAr read tkq write tkq;
  Property Par_tthrq : TPAr read tthrq write tthrq;
  Property Par_cut1 : TPAr read cut1 write cut1;
   Property Par_cutW : TPAr read cutW write cutW;
  Property Par_oldharvestdate : TPAr read oldharvestdate write oldharvestdate;



         // Properties External Variables
  Property Ex_pETP : TExternV read pETP write pETP;
  Property Ex_GlobRad : TExternV read GlobRad write GlobRad;
  Property Ex_TransRatio : TExternV read TransRatio write TransRatio;
  Property Ex_Rain : TExternV read Rain write Rain;
  Property Ex_Temp : TExternV read Temp write Temp;



end;  // SubmodelName

procedure Register;

implementation
//{$R Grass.res}


function TGrass_growth_quality.GetCropHeight:THumeNumEntity;

begin
  result := CropHeight;
end;

procedure TGrass_growth_quality.SetCropHeight(NewCropHeight:THumeNumEntity);

begin
  p_CropHeight := NewCropHeight;
end;

function TGrass_growth_quality.GetLAI:THumeNumEntity;

begin
   result := LAI

end;

procedure TGrass_growth_quality.SetLai(NewLAI:THumeNumEntity);

begin
  p_LAI := NewLAI;
end;

function TGrass_growth_quality.GetNUptakeRate:THumeNumEntity;

begin
   result := ShootN;
   result.v := ShootN.c;
   result.fv := ShootN.c;

end;

procedure TGrass_growth_quality.SetNUptakeRate(NewNUptakeRate:THumeNumEntity);

begin
  p_NUptakeRate := NewNUptakeRate;
  ShootN.name := p_NUptakeRate.Name;
  ShootN.c := p_NuptakeRate.v;

end;


{*************************************************************************}

{
Zweck

Funktion zur Berechnung der Wurzell„ngendichte in Abh„ngigkeit von der Tiefe


Parameter

Name        Inhalt                       Einheit      Typ


wld0        WLD bei z=0                  [cm/cm3]     I
a           Fitparameter                 [1/cm]       I
            bei 1/a ist WLD=0.63*WLD0
z           Tiefe unter GOF              [cm]         I

WLD_z_f     WLD in Tiefe z               [cm/cm3]     O

{*************************************************************************}


{*************************************************************************}


{
Zweck

Funktion zur Berechnung der mittleren Wurzellängendichte zwischen zwei
Tiefen z1 und z2 (z1 < z2) in Abhängigkeit von Zeit und Tiefe


Parameter

Name        Inhalt                       Einheit      Typ


z1          Tiefe 1                      [cm]         I
z2          Tiefe 2                      [cm]         I
t           Zeit                         [d]          I
Zrmax       maximale Durchwurzelungstiefe[cm]         I
zr0         Durchwurzelungstiefe bei t=0 [cm]         I
kz          Fitparameter                 [1/d]        I
SRLmax      maximale Wurzellänge         [cm/cm2]     I
            (1 cm/cm2 entspr. 0.1 km/m2)
SR0         Wurzellänge bei t=0          [cm/cm2]     I
kL          Fitparameter                 [1/d]        I
ka          Fitparameter                 [1/cm]       I
            bei 1/(ka*zr)ist WLD=0.63*WLD0

WLD_z_t_f   WLD zwischen z1 und z2 bei t [cm/cm3]     O


{*************************************************************************}


function monomo_f (Pmax, P0, k, t : real): real;

begin
  monomo_f := Pmax-(Pmax-P0)*exp(-k*t);
end;

function Logist_f(Wmax, W0, k, Tsum:real):real;

begin
  result :=   WMax/(1+(WMAx/W0-1)*EXP(-TSum*k))

end;


function WLD_z_f ( wld0, a, z: real): real;

begin
  WLD_z_f := wld0*exp(-a*z);
end;


function TGrass_growth_quality.WLD_z_t_f ( z1, z2, t, Zrmax, Zr0, Kz,
                     SRLmax, SRL0, kL, ka : real): real;

var
  SRL,
  WLD0,
  a   : real;

begin
  zr.v  := monomo_f (Zrmax, Zr0, kz, t);
  If z1>zr.v then begin
    WLD_z_t_f := 0.0;
    exit;
  end;
  If (z2>zr.v) and (z1<>zr.v) then z2 := zr.v;
  a   := 1/(ka*zr.v);
  if a > zr.v then begin
      showmessage('GrowthCurvePlantRoots, Objectname:'+self.name+ 'Par a>Zr.v');
      halt;
  end;
  SRL := logist_f (SRLmax, SRL0, kL, t);
  WLD0:= (SRL*a)/(1-exp(-a*zr.v));
  wld_z_t_f := wld0*(exp(-a*z1)-exp(-a*z2))/(a*(z2-z1));

end;

function TGrass_growth_quality.GetWLD(Index: Integer):THumeNumEntity;

begin
  result :=  wld_arr[index];

end;

procedure TGrass_growth_quality.SetWLD(Index: Integer; NewWLD:THumeNumEntity);

begin
  wld_arr[index].v :=   p_WLD[index].v;
end;






procedure TGrass_growth_quality.createAll;

var
  i : integer;


begin
  inherited createAll;
  VarCreate('AGE', '',0, true, AGE);
  VarCreate('cai', '',0, true, cai);
  VarCreate('dW', '',0, true, dW);
  VarCreate('GI', '',0, true, GI);
  VarCreate('LAI', '',0, true, LAI);
  VarCreate('radiation', '',0, true, radiation);
  VarCreate('RI', '',0, true, RI);
  VarCreate('rmax', '',0, true, rmax);
  VarCreate('SW1', '',0, true, SW1);
  VarCreate('TI', '',0, true, TI);
  VarCreate('WI', '',0, true, WI);
  VarCreate('WI_2', '',0, true, WI_2);
  VarCreate('cropHeight', '',0, true, cropHeight);

  VarCreate('daylength', '',0, true, daylength);
  VarCreate('mchr', '',0, true, mchr);
  VarCreate('pchr', '',0, true, pchr);
  VarCreate('pechr', '',0, true, pechr);
  VarCreate('quality', '',0, true, quality);
  VarCreate('r', '',0, true, r);
  VarCreate('rchr', '',0, true, rchr);
  VarCreate('TAGB', '',0, true, TAGB);  
  VarCreate('TAGLI', '',0, true, TAGLI);  
  VarCreate('TAGX', '',0, true, TAGX);
  VarCreate('tchr', '',0, true, tchr);
  VarCreate('tresmax', '',0, true, tresmax); 
  VarCreate('TLAM', '',0, true, TLAM);  
  VarCreate('TNR', '',0, true, TNR);  
  VarCreate('fertig', '',0,true, fertig);

  StateCreate('SW', '',0, true,SW);
  StateCreate('W', '',0, true,W);
  StateCreate('zr', '',100, true,zr);
  StateCreate('ShootN', '',0, true,ShootN);
  StateCreate('TSum', '',0, true,Tsum);
   StateCreate('spechr', '',0, true,spechr);



  // Parameters
  ParCreate('agelim', '[-]',0.002,agelim);
  ParCreate('agend', '[-]',-0.003,agend);
  ParCreate('ak', '[-]',4,ak);
  ParCreate('akm', '[-]',0.001,akm);
  ParCreate('begbas', '[-]',0,begbas);
  ParCreate('begsum', '[-]',0,begsum);
  ParCreate('cank', '[-]',1,cank);
  ParCreate('clai', '[-]',30,clai);
  ParCreate('etpa', '[-]',0.3,etpa);
  ParCreate('etpb', '[-]',0.233,etpb);
  ParCreate('lai50', '[-]',2.5,lai50);
  ParCreate('laih', '[-]',6,laih);
  ParCreate('lail', '[-]',1,lail);
  ParCreate('rk', '[-]',3,rk);
  ParCreate('rmlo', '[-]',32,rmlo);
  ParCreate('rmxp', '[-]',32,rmxp);
  ParCreate('rs', '[-]',0.243,rs);
  ParCreate('swact', '[-]',80,swact);
  ParCreate('swmax', '[-]',80,swmax);
  ParCreate('swthr', '[-]',0.8,swthr);
  ParCreate('tk1', '[-]',3,tk1);
  ParCreate('tk2', '[-]',0.3,tk2);
  ParCreate('topt', '[-]',15,topt);
  ParCreate('tpmax', '[-]',42,tpmax);
  ParCreate('tthr', '[-]',1,tthr);
  ParCreate('w0', '[-]',7.3,w0);
   ParCreate('wh', '[-]',0.001,wh);
 // für ADF 240 kg N spring:
    ParCreate('al', '[-]',1, al);
   ParCreate('bl', '[-]',1, bl);
  ParCreate('chrk', '[-]',2.42, chrk);
  ParCreate('funct', '[-]',3, funct);
  ParCreate('mchr_switch', '[-]',1, mchr_switch);
  ParCreate('mfk', '[-]',0.5, mfk);
  ParCreate('pk', '[-]',0.1, pk);
  ParCreate('pthr', '[-]',10, pthr);
  ParCreate('qlat', '[-]',54, qlat);
  ParCreate('qmax', '[-]',34.8, qmax);
  ParCreate('qmin', '[-]',15.75, qmin);
  ParCreate('qphsw', '[-]',2, qphsw);
  ParCreate('rchr_switch', '[-]',1, rchr_switch);
  ParCreate('rkq', '[-]',0.01, rkq);
  ParCreate('rthrq', '[-]',3, rthrq);
  ParCreate('schr50', '[-]',1.42, schr50);
  ParCreate('tkq', '[-]',0.01, tkq);
  ParCreate('tthrq', '[-]',4, tthrq);
  ParCreate('cut1', '[%]',28, cut1);
  ParCreate('cutW', '[g/m2]',200, cutW);
  ParCreate('oldharvestdate', '[-]', 1e6, oldharvestdate);




         // External Variable
  ExternVCreate('pETP', '',statefield, pETP);
  ExternVCreate('GlobRad', '',statefield, GlobRad);
  ExternVCreate('TransRatio', '',statefield, TransRatio);
  ExternVCreate('Rain', '',statefield, Rain);
  ExternVCreate('Temp', '',statefield, Temp);

  ParCreate('zr_0', '[cm]',10,zr_0);
  ParCreate('zr_max', '[cm]',120,zr_max);
  ParCreate('WL_0', '[cm]',1,WL_0);
  ParCreate('WL_max', '[cm]', 15, WL_max);
  ParCreate('k_z', '[cm.d-1.°C]', 0.0009, k_z);
  ParCreate('k_WL', '[cm.d-1.°C]', 0.002, k_WL);
  ParCreate('k_a', '[-]', 0.42, k_a);

  VarCreate('N_Rootcomp', '[n]',  20, true, N_Rootcomp);
  Varcreate('SRL', '[cm.cm-2]', 0.0, false, SRL);
  Varcreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff);



  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate('WLD_'+IntToStr(i), '[cm.cm-3]', 0.0, false,WLD_arr[i]);
    VarCreate('WL_'+IntToStr(i), '[cm.cm-2]', 0.0, false,WL_arr[i]);
//    VarCreate('WInflux'+IntToStr(i), '[cm3.cm-1.d-1]', 0.0, false,W_influx[i]);
//    pWLD_arr[i] := @wld_arr[i].fv;

  end;
  for i := 0 to trunc(n_Rootcomp.v) do
      ExternVCreate('Tiefe'+IntToStr(i),'[cm]',StateField,Tiefe[i]);


  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
  end;




end;


procedure TGrass_growth_quality.init(var GlobMod: TMod);

var
  i : integer;



begin
  inherited init(GlobMod);
  SW.v := swact.v;
  W.v := w0.v;
  zr.v := zr_0.v;
  spechr.v := 0;

  oldharvestdate.v := harvestdate.v ;

   for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;

 springcut := false;

end;


procedure TGrass_growth_quality.CalcRates;

var
  i : integer;
   year, month, date : word;

begin

//If (GlobTime.v >= SowingDate.v) and (GlobTime.v<HarvestDate.v) then begin
If (GlobTime.v >= SowingDate.v) then begin
harvestdate.v:=oldharvestdate.v;


  // Temperatursumme
  Tsum.c:=max(0,Temp.v);


// LAI
   LAI.v :=  sqrt(W.v/clai.v);
   if LAI.v<1 then
    LAI.v :=1;
   AGE.v :=  1 / (1 + power((LAI.v/LAI50.v),ak.v));

   cai.v :=  (1-exp(-cank.v*(LAI.v-LAIl.v)/LAIh.v))/(1-exp(-cank.v));



 //RI    radiation index
   radiation.v :=  GlobRad.v;

   rmax.v :=   rmlo.v + CAI.v*(rmxp.v - rmlo.v);
   RI.v :=  min(1,(1-exp(-rk.v*radiation.v/rmax.v)) /(1-exp(-rk.v)));

 //TI   temperature index
 tresmax.v:=tthr.v;
 if (Temp.v >=topt.v) then
  tresmax.v :=0.05;
 if ((abs(Temp.v-topt.v)/ (topt.v-tresmax.v)) <0.5  ) then
   TI.v :=  1.0 - (power(2*abs(Temp.v-topt.v)/(topt.v-tresmax.v),tk1.v))*0.5
      else
    TI.v :=  power(2*(1-(abs(Temp.v-topt.v)/(topt.v-tresmax.v))),tk1.v)*0.5     ;

  TI.v:=max(0,min(TI.v,1));

    //WI  water index
   SW.c :=  Rain.v-pETP.v;
   SW1.v :=  max(0,min(SW.v+SWact.v,SWmax.v));

   WI.v :=  max(0,TransRatio.v);
   WI_2.v :=  min(1.0, SW1.v / (swthr.v*swmax.v));

   GI.v :=   TI.v * RI.v * WI.v  ;


   dW.v :=  W.v*rs.v*AGE.v*GI.v;

    W.c :=   dW.v  ;

    cropHeight.v :=(wh.v*W.v)+0.15;
     SRL.v := 0.0;
  SRL_eff.v := 0.0;

  //Quality

      //daylength
      TNR.v :=  GlobTime.v+0.5;
      TLAM.v :=  TAGLI.v + 1.915*sin((365.455+0.985647*TNR.v) /180*3.1416) + 0.02*sin(2*( 365.455+0.985647*TNR.v)/180*3.1416);


      TAGX.v :=  tan(arcsin(0.39781*sin(tlam.v/180*3.1416)));
      TAGLI.v :=  279.097 + 0.985647*TNR.v;
      TAGB.v :=  -tan(qlat.v*3.1416/180);
     daylength.v :=  0.13333*arccos(TAGB.v*TAGX.v)*180/3.1416;

    //temperature
      tchr.v :=  max(0,1 - exp(-tkq.v*(temp.v-tthrq.v)));
   //moisture
   If  mchr_switch.v=1 then
     mchr.v :=   max(0,1-(WI.v/mfk.v))
   else
     mchr.v :=   min(1,(WI.v/mfk.v))  ;

     //photoperiod
   If  qphsw.v=2 then
        pchr.v :=   max(0,1-exp(-pk.v*(daylength.v-pthr.v)))
   else
       pchr.v :=   max(0,exp(-pk.v*(daylength.v-pthr.v)))  ;

    //radiation
   r.v :=  GlobRad.v*100;

  If  rchr_switch.v=1 then
    rchr.v :=   max(0,1-exp(-rkq.v*(r.v-rthrq.v)))
  else
     rchr.v :=   exp(-rkq.v*(r.v-rthrq.v))  ;


   pechr.v :=  PCHR.v * TCHR.v * RCHR.v * MCHR.v;

   spechr.c :=  pechr.v;

   If  funct.v=1 then
        quality.v :=   qmin.v + (1/(1+power((SPECHR.v/schr50.v),chrk.v)))*(qmax.v-qmin.v)
   else If  funct.v=3 then
        quality.v :=   qmin.v + (power((SPECHR.v/schr50.v),chrk.v)/(1+power((SPECHR.v/schr50.v),chrk.v)))*(qmax.v-qmin.v)

   else
       quality.v :=   al.v + bl.v*SPECHR.v  ;




 //roots

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := WLD_z_t_f ( Tiefe[i-1].v, tiefe[i].v, TSum.v, Zr_max.v, Zr_0.v, K_z.v,
                                WL_max.v,   WL_0.v,   k_WL.v,     k_a.v);
    Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v-Tiefe[i-1].v);
    SRL.v := SRL.v + WL_arr[i].v;
    SRL_eff.v := SRL_eff.v + WL_arr[i].v;
  end;


  end;     // growth period
  decodedate(globmod.time.v, year, month, date);
If (Month=2) and (date=15) and (springcut=false) then begin
   springcut := true;
 W.v:=W0.v;
 W.c:=0;
 dW.v:=0;
 cropHeight.v :=0.15;
 LAI.v:=LAIl.v;
 quality.v:=qmin.v;
 spechr.v:=0;
 spechr.c:=0;
 Tsum.c := 0;
 Tsum.v := 0;

  SW.v := swact.v;
  zr.v := zr_0.v;
  pechr.v := 0;
  tchr.v:=0;

  end;


  //harvest
 if (quality.v>=cut1.v) or (W.v>=cutW.v) or (GlobTime.v>=HarvestDate.v) then begin
   //if (quality.v>=cut1.v) or (W.v>=cutW.v) then begin
   oldharvestdate.v:=harvestdate.v+365.455;
    harvestdate.v := Globtime.v;
    springcut := false;
    self.NextCrop.SowingDate.v := self.HarvestDate.v +1;

 //If  (GlobTime.v>=HarvestDate.v) then begin
 W.v:=W0.v;
 W.c:=0;
 dW.v:=0;
 cropHeight.v :=0.15;
 LAI.v:=LAIl.v;
 quality.v:=qmin.v;
 spechr.v:=0;
 spechr.c:=0;
 Tsum.c := 0;
 Tsum.v := 0;

  SW.v := swact.v;
  zr.v := zr_0.v;
  pechr.v := 0;
  tchr.v:=0;

   for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;



 //end;
 end;     // cut 1
 inherited calcrates;
 end;




procedure Register;
begin
  RegisterComponents('GrassModel', [TGrass_growth_quality]);
end;

end.
