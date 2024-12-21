
unit grass_growth_quality_ff;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState, math, iniFiles, UAbstractPlant, USoilMineralisation,
  UlayeredSoil;

type

  TGrass_growth_quality_dauer = class(TAbstractPlant)

  private

    springcut: boolean;
    function WLD_z_t_f(z1, z2, t, Zrmax, Zr0, Kz,
      SRLmax, SRL0, kL, ka: real): real;


  protected
    function GetLAI: THumeNumEntity; override;
//    procedure SetLai(NewLAI: THumeNumEntity); override;
    function GetCropHeight: THumeNumEntity; override;
//    procedure SetCropHeight(NewCropHeight: THumeNumEntity); override;
    function GetNUptakeRate: THumeNumEntity; override;
//    procedure SetNUptakeRate(NewNUptakeRate: THumeNumEntity); override;

    function GetWLD(Index: Integer): THumeNumEntity; override;
//    procedure SetWLD(Index: Integer; NewWLD: THumeNumEntity); override;




  public
    AGE: TVar; //
    cai: TVar; //
    dW: TVar; //
    GI: TVar; //
    LAI: TVar; //
    radiation: TVar; //
    RI: TVar; //
    rmax: TVar; //
    SW1: TVar; //
    TI: TVar; //
    WI: TVar; //
    WI_2: TVar; //
    cropHeight: TVar; //   Bestandshöhe
  //quality
    daylength: TVar; //
    mchr: TVar; //
    pchr: TVar; //
    pechr: TVar; //
    quality: TVar; //
    r: TVar; //
    rchr: TVar; //
    TAGB: TVar; //
    TAGLI: TVar; //
    TAGX: TVar; //
    tchr: TVar; //

    TLAM: TVar; //
    TNR: TVar; //
    fertig: TVAR;

   // seasonal values
    ak: TVAR; //
    lai50: TVAR; //
    rs: TVAR; //
    w0: TVAR; //
    chrk: TVAR; //
    mfk: TVAR;
    pk: TVAR; //
    qmax: TVAR; //
    qmin: TVAR; //
    rkq: TVAR; //
    schr50: TVAR; //
    tkq: TVAR; //

  // Constant Variables

    SW: TState; //
    W: TState; //
    yield_total: TState;
    zr: TState; // Wurzellänge
    shootN: TState; //N-MEnge
    TSum: TState; //Temperatursumme
    spechr: TState; //  sumof change rates

             // Parameters
    agelim: TPar; //
    agend: TPar; //

    ak1: TPar; //
    ak2: TPar; //
    ak3: TPar; //
    akm: TPar; //
    begbas: TPar; //
    begsum: TPar; //
    cank: TPar; //
    clai: TPar; //
    etpa: TPar; //
    etpb: TPar; //

    lai50_1: TPar; //
    lai50_2: TPar; //
    lai50_3: TPar; //
    laih: TPar; //
    lail: TPar; //
    rk: TPar; //
    rmlo: TPar; //
    rmxp: TPar; //

    rs1: TPar; //
    rs2: TPar; //
    rs3: TPar; //
    swact: TPar; //
    swmax: TPar; //
    swthr: TPar; //
    tk1: TPar; //
    tk2: TPar; //
    topt: TPar; //
    tpmax: TPar; //
    tthr: TPar; //

    w01: TPar; //
    w02: TPar; //
    w03: TPar; //
    wh: TPar; // dW/Bestandshöhe
    al: TPar; //
    bl: TPar; //

    chrk1: TPar; //
    chrk2: TPar; //
    chrk3: TPar; //
    funct: TPar; //
    cut1: TPar; //
    cutW: TPar; //
    cut2: TPar; //
    cut2W: TPar; //
    cut3: TPar; //
    cut3W: TPar; //
    mchr_switch: TPar; //

    mfk1: TPar; //
    mfk2: TPar; //
    mfk3: TPar; //

    pk1: TPar; //
    pk2: TPar; //
    pk3: TPar; //
    pthr: TPar; //
    qlat: TPar; //

    qmax1: TPar; //
    qmax2: TPar; //
    qmax3: TPar; //

    qmin1: TPar; //
    qmin2: TPar; //
    qmin3: TPar; //

    qphsw: TPar; //
    rchr_switch: TPar; //

    rkq1: TPar; //
    rkq2: TPar; //
    rkq3: TPar; //
    rthrq: TPar; //

    schr50_1: TPar; //
    schr50_2: TPar; //
    schr50_3: TPar; //

    tkq1: TPar; //
    tkq2: TPar; //
    tkq3: TPar; //
    tthrq: Tpar;
    oldharvestdate: TPar; //


             // External Variables
    pETP: TExternV; //
    GlobRad: TExternV; //
    TransRatio: TExternV; //
    Rain: TExternV; //
    Temp: TExternV; //





    Wld_arr: TSoilVarArray; // Wurzellängendichten [cm.cm-3]
    WL_arr: TSoilVarArray; // Wurzellängen [cm.cm-2]

    N_Rootcomp: TVar;

    Tiefe: TSoilExtArray;

    zr_0: TPar; // Wurzeltiefe zur Pflanzung / Aussaat [cm]
    zr_max: TPar; // maximale Wurzeltiefe [cm]

    WL_0: TPar; // Wurzellänge zur Pflanzung / Aussaat [cm]
    WL_max: TPar; // maximale Wurzellänge [cm]

    k_z, // Wachstumsratenparameter für Tiefenentwicklung [cm]
      k_Wl,
      K_a
      : Tpar;

    SRL, // Sum of root length [cm/cm2]
      SRL_eff: Tvar; // Total root length of functional roots (cm.cm-2)



    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;


  published
    property Var_AGE: TVar read AGE write AGE;
    property Var_cai: TVar read cai write cai;
    property Var_dW: TVar read dW write dW;
    property Var_GI: TVar read GI write GI;
    property Var_LAI: TVar read LAI write LAI;
    property Var_radiation: TVar read radiation write radiation;
    property Var_RI: TVar read RI write RI;
    property Var_rmax: TVar read rmax write rmax;
    property Var_SW1: TVar read SW1 write SW1;
    property Var_TI: TVar read TI write TI;
    property Var_WI: TVar read WI write WI;
    property Var_WI_2: TVar read WI_2 write WI_2;
    property Var_cropHeight: Tvar read cropHeight write cropHeight;

    property Var_daylength: TVar read daylength write daylength;
    property Var_mchr: TVar read mchr write mchr;
    property Var_pchr: TVar read pchr write pchr;
    property Var_pechr: TVar read pechr write pechr;
    property Var_quality: TVar read quality write quality;
    property Var_r: TVar read r write r;
    property Var_rchr: TVar read rchr write rchr;
    property Var_TAGB: TVar read TAGB write TAGB;
    property Var_TAGLI: TVar read TAGLI write TAGLI;
    property Var_TAGX: TVar read TAGX write TAGX;
    property Var_tchr: TVar read tchr write tchr;

    property Var_TLAM: TVar read TLAM write TLAM;
    property Var_TNR: TVar read TNR write TNR;

    property Par_fertig: TVar read fertig write fertig;

    property St_spechr: TState read spechr write spechr;
    property St_SW: TState read SW write SW;
    property St_W: TState read W write W;
    property St_yield_total: TState read yield_total write yield_total;
    property St_zr: TState read zr write zr;
    property St_shootN: TState read ShootN write ShootN;
    property St_TSum: TState read TSum write TSum;


         // Parameters
    property Par_agelim: TPar read agelim write agelim;
    property Par_agend: TPar read agend write agend;
 // Property Par_ak : TPar read ak write ak;
    property Par_akm: TPar read akm write akm;
    property Par_begbas: TPar read begbas write begbas;
    property Par_begsum: TPar read begsum write begsum;
    property Par_cank: TPar read cank write cank;
    property Par_clai: TPar read clai write clai;
    property Par_etpa: TPar read etpa write etpa;
    property Par_etpb: TPar read etpb write etpb;
 // Property Par_lai50 : TPar read lai50 write lai50;
    property Par_laih: TPar read laih write laih;
    property Par_lail: TPar read lail write lail;
    property Par_rk: TPar read rk write rk;
    property Par_rmlo: TPar read rmlo write rmlo;
    property Par_rmxp: TPar read rmxp write rmxp;
  //Property Par_rs : TPar read rs write rs;
    property Par_swact: TPar read swact write swact;
    property Par_swmax: TPar read swmax write swmax;
    property Par_swthr: TPar read swthr write swthr;
    property Par_tk1: TPar read tk1 write tk1;
    property Par_tk2: TPar read tk2 write tk2;
    property Par_topt: TPar read topt write topt;
    property Par_tpmax: TPar read tpmax write tpmax;
    property Par_tthr: TPar read tthr write tthr;
 // Property Par_w0 : TPar read w0 write w0;
    property Par_wh: TPar read wh write wh;

    property Par_zr0: TPar read zr_0 write zr_0;
    property Par_zrmax: TPar read zr_max write zr_max;
    property Par_kz: TPar read k_z write k_z;
    property Par_Wl0: TPar read Wl_0 write Wl_0;
    property Par_Wlmax: TPar read WL_max write WL_max;
    property Par_kWL: TPar read k_WL write k_WL;


    property Par_al: TPAr read al write al;
    property Par_bl: TPAr read bl write bl;
  //Property Par_chrk : TPAr read chrk write chrk;
    property Par_funct: TPAr read funct write funct;
    property Par_mchr_switch: TPAr read mchr_switch write mchr_switch;
 // Property Par_mfk : TPAr read mfk write mfk;
  //Property Par_pk : TPAr read pk write pk;
    property Par_pthr: TPAr read pthr write pthr;
    property Par_qlat: TPAr read qlat write qlat;
 // Property Par_qmax : TPAr read qmax write qmax;
  //Property Par_qmin : TPAr read qmin write qmin;
    property Par_qphsw: TPAr read qphsw write qphsw;
    property Par_rchr_switch: TPAr read rchr_switch write rchr_switch;
 // Property Par_rkq : TPAr read rkq write rkq;
    property Par_rthrq: TPAr read rthrq write rthrq;
 // Property Par_schr50 : TPAr read schr50 write schr50;
 // Property Par_tkq : TPAr read tkq write tkq;
    property Par_tthrq: TPAr read tthrq write tthrq;
    property Par_cut1: TPAr read cut1 write cut1;
    property Par_cutW: TPAr read cutW write cutW;
    property Par_oldharvestdate: TPAr read oldharvestdate write oldharvestdate;



         // Properties External Variables
    property Ex_pETP: TExternV read pETP write pETP;
    property Ex_GlobRad: TExternV read GlobRad write GlobRad;
    property Ex_TransRatio: TExternV read TransRatio write TransRatio;
    property Ex_Rain: TExternV read Rain write Rain;
    property Ex_Temp: TExternV read Temp write Temp;



  end; // SubmodelName

procedure Register;

implementation
//{$R Grass.res}


function TGrass_growth_quality_dauer.GetCropHeight: THumeNumEntity;

begin
  result := CropHeight;
end;

{procedure TGrass_growth_quality_dauer.SetCropHeight(NewCropHeight: THumeNumEntity);

begin
  p_CropHeight := NewCropHeight;
end;}

function TGrass_growth_quality_dauer.GetLAI: THumeNumEntity;

begin
  result := LAI

end;

{procedure TGrass_growth_quality_dauer.SetLai(NewLAI: THumeNumEntity);

begin
  p_LAI := NewLAI;
end;}

function TGrass_growth_quality_dauer.GetNUptakeRate: THumeNumEntity;

begin
  result := ShootN;
  result.v := ShootN.c;
  result.fv := ShootN.c;

end;

{procedure TGrass_growth_quality_dauer.SetNUptakeRate(NewNUptakeRate: THumeNumEntity);

begin
  p_NUptakeRate := NewNUptakeRate;
  ShootN.name := p_NUptakeRate.Name;
  ShootN.c := p_NuptakeRate.v;

end;}


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


function monomo_f(Pmax, P0, k, t: real): real;

begin
  monomo_f := Pmax - (Pmax - P0) * exp(-k * t);
end;

function Logist_f(Wmax, W0, k, Tsum: real): real;

begin
  result := WMax / (1 + (WMAx / W0 - 1) * EXP(-TSum * k))

end;


function WLD_z_f(wld0, a, z: real): real;

begin
  WLD_z_f := wld0 * exp(-a * z);
end;


function TGrass_growth_quality_dauer.WLD_z_t_f(z1, z2, t, Zrmax, Zr0, Kz,
  SRLmax, SRL0, kL, ka: real): real;

var
  SRL,
    WLD0,
    a: real;

begin
  zr.v := monomo_f(Zrmax, Zr0, kz, t);
  if z1 > zr.v then begin
    WLD_z_t_f := 0.0;
    exit;
  end;
  if (z2 > zr.v) and (z1 <> zr.v) then z2 := zr.v;
  a := 1 / (ka * zr.v);
  if a > zr.v then begin
    showmessage('GrowthCurvePlantRoots, Objectname:' + self.name + 'Par a>Zr.v');
    halt;
  end;
  SRL := logist_f(SRLmax, SRL0, kL, t);
  WLD0 := (SRL * a) / (1 - exp(-a * zr.v));
  wld_z_t_f := wld0 * (exp(-a * z1) - exp(-a * z2)) / (a * (z2 - z1));

end;

function TGrass_growth_quality_dauer.GetWLD(Index: Integer): THumeNumEntity;

begin
  result := wld_arr[index];

end;

{procedure TGrass_growth_quality_dauer.SetWLD(Index: Integer; NewWLD: THumeNumEntity);

begin
  wld_arr[index].v := p_WLD[index].v;
end;}






procedure TGrass_growth_quality_dauer.createAll;

var
  i: integer;



begin
  inherited createAll;
  VarCreate('AGE', '', 0, true, AGE);
  VarCreate('cai', '', 0, true, cai);
  VarCreate('dW', '', 0, true, dW);
  VarCreate('GI', '', 0, true, GI);
  VarCreate('LAI', '', 0, true, LAI);
  VarCreate('radiation', '', 0, true, radiation);
  VarCreate('RI', '', 0, true, RI);
  VarCreate('rmax', '', 0, true, rmax);
  VarCreate('SW1', '', 0, true, SW1);
  VarCreate('TI', '', 0, true, TI);
  VarCreate('WI', '', 0, true, WI);
  VarCreate('WI_2', '', 0, true, WI_2);
  VarCreate('cropHeight', '', 0, true, cropHeight);

  VarCreate('daylength', '', 0, true, daylength);
  VarCreate('mchr', '', 0, true, mchr);
  VarCreate('pchr', '', 0, true, pchr);
  VarCreate('pechr', '', 0, true, pechr);
  VarCreate('quality', '', 0, true, quality);
  VarCreate('r', '', 0, true, r);
  VarCreate('rchr', '', 0, true, rchr);
  VarCreate('TAGB', '', 0, true, TAGB);
  VarCreate('TAGLI', '', 0, true, TAGLI);
  VarCreate('TAGX', '', 0, true, TAGX);
  VarCreate('tchr', '', 0, true, tchr);

  VarCreate('TLAM', '', 0, true, TLAM);
  VarCreate('TNR', '', 0, true, TNR);
  VarCreate('fertig', '', 0, true, fertig);

   // seasonal values
  VarCreate('ak', '[-]', 4, true, ak);
  VarCreate('lai50', '[-]', 2.5, true, lai50);
  VarCreate('rs', '[-]', 0.243, true, rs);
  VarCreate('w0', '[-]', 7.3, true, w0);
  VarCreate('chrk', '[-]', 2.42, true, chrk);
  VarCreate('mfk', '[-]', 0.5, true, mfk);

  VarCreate('pk', '[-]', 0.1, true, pk);
  VarCreate('qmax', '[-]', 34.8, true, qmax);
  VarCreate('qmin', '[-]', 15.75, true, qmin);
  VarCreate('rkq', '[-]', 0.01, true, rkq);
  VarCreate('schr50', '[-]', 1.42, true, schr50);
  VarCreate('tkq', '[-]', 0.01, true, tkq);




  StateCreate('SW', '', 0, true, SW);
  StateCreate('W', '', 0, true, W);
  StateCreate('yield_total', '', 0, true, yield_total);
  StateCreate('zr', '', 100, true, zr);
  StateCreate('ShootN', '', 0, true, ShootN);
  StateCreate('TSum', '', 0, true, Tsum);
  StateCreate('spechr', '', 0, true, spechr);



  // Parameters

//  for seasonndx = low(season_str) to high(season_str) do begin
  // for j = 1 to 3 do begin

 // end;

  ParCreate('agend', '[-]', -0.003, agend);

  ParCreate('ak1', '[-]', 4, ak1);
  ParCreate('ak2', '[-]', 4, ak2);
  ParCreate('ak3', '[-]', 5.25, ak3);
  ParCreate('akm', '[-]', 0.001, akm);
  ParCreate('begbas', '[-]', 0, begbas);
  ParCreate('begsum', '[-]', 0, begsum);
  ParCreate('cank', '[-]', 1, cank);
  ParCreate('clai', '[-]', 30, clai);
  ParCreate('etpa', '[-]', 0.3, etpa);
  ParCreate('etpb', '[-]', 0.233, etpb);

  ParCreate('lai50_1', '[-]', 2.5, lai50_1);
  ParCreate('lai50_2', '[-]', 2.5, lai50_2);
  ParCreate('lai50_3', '[-]', 1.85, lai50_3);
  ParCreate('laih', '[-]', 6, laih);
  ParCreate('lail', '[-]', 1, lail);
  ParCreate('rk', '[-]', 3, rk);
  ParCreate('rmlo', '[-]', 32, rmlo);
  ParCreate('rmxp', '[-]', 32, rmxp);

  ParCreate('rs1', '[-]', 0.243, rs1);
  ParCreate('rs2', '[-]', 0.175, rs2);
  ParCreate('rs3', '[-]', 0.219, rs3);
  ParCreate('swact', '[-]', 80, swact);
  ParCreate('swmax', '[-]', 80, swmax);
  ParCreate('swthr', '[-]', 0.8, swthr);
  ParCreate('tk1', '[-]', 3, tk1);
  ParCreate('tk2', '[-]', 0.3, tk2);
  ParCreate('topt', '[-]', 15, topt);
  ParCreate('tpmax', '[-]', 42, tpmax);
  ParCreate('tthr', '[-]', 1, tthr);

  ParCreate('w01', '[-]', 7.3, w01);
  ParCreate('w02', '[-]', 10.7, w02);
  ParCreate('w03', '[-]', 7.05, w03);
  ParCreate('wh', '[-]', 0.001, wh);
 // für ADF 240 kg N spring:
  ParCreate('al', '[-]', 1, al);
  ParCreate('bl', '[-]', 1, bl);

  ParCreate('chrk1', '[-]', 2.42, chrk1);
  ParCreate('chrk2', '[-]', 1.46, chrk2);
  ParCreate('chrk3', '[-]', 1.59, chrk3);
  ParCreate('funct', '[-]', 3, funct);
  ParCreate('mchr_switch', '[-]', 2, mchr_switch);

  ParCreate('mfk1', '[-]', 0.5, mfk1);
  ParCreate('mfk2', '[-]', 0.8, mfk2);
  ParCreate('mfk3', '[-]', 0.8, mfk3);

  ParCreate('pk1', '[-]', 0.1, pk1);
  ParCreate('pk2', '[-]', 10, pk2);
  ParCreate('pk3', '[-]', 10, pk3);
  ParCreate('pthr', '[-]', 10, pthr);
  ParCreate('qlat', '[-]', 54, qlat);

  ParCreate('qmax1', '[-]', 34.8, qmax1);
  ParCreate('qmax2', '[-]', 39.45, qmax2);
  ParCreate('qmax3', '[-]', 39.55, qmax3);

  ParCreate('qmin1', '[-]', 15.75, qmin1);
  ParCreate('qmin2', '[-]', 20.8, qmin2);
  ParCreate('qmin3', '[-]', 20.65, qmin3);
  ParCreate('qphsw', '[-]', 2, qphsw);
  ParCreate('rchr_switch', '[-]', 1, rchr_switch);

  ParCreate('rkq1', '[-]', 0.01, rkq1);
  ParCreate('rkq2', '[-]', 0.042, rkq2);
  ParCreate('rkq3', '[-]', 0.063, rkq3);
  ParCreate('rthrq', '[-]', 3, rthrq);

  ParCreate('schr50_1', '[-]', 1.42, schr50_1);
  ParCreate('schr50_2', '[-]', 16.83, schr50_2);
  ParCreate('schr50_3', '[-]', 25.97, schr50_3);

  ParCreate('tkq1', '[-]', 0.01, tkq1);
  ParCreate('tkq2', '[-]', 0.053, tkq2);
  ParCreate('tkq3', '[-]', 0.047, tkq3);
  ParCreate('tthrq', '[-]', 4, tthrq);
  ParCreate('cut1', '[%]', 28, cut1);
  ParCreate('cutW', '[g/m2]', 200, cutW);
  ParCreate('cut2', '[%]', 28, cut2);
  ParCreate('cut2W', '[g/m2]', 200, cut2W);
  ParCreate('cut3', '[%]', 28, cut3);
  ParCreate('cut3W', '[g/m2]', 200, cut3W);

  ParCreate('oldharvestdate', '[-]', 1E6, oldharvestdate);




         // External Variable
  ExternVCreate('pETP', '', statefield, pETP);
  ExternVCreate('GlobRad', '', statefield, GlobRad);
  ExternVCreate('TransRatio', '', statefield, TransRatio);
  ExternVCreate('Rain', '', statefield, Rain);
  ExternVCreate('Temp', '', statefield, Temp);

  ParCreate('zr_0', '[cm]', 10, zr_0);
  ParCreate('zr_max', '[cm]', 120, zr_max);
  ParCreate('WL_0', '[cm]', 1, WL_0);
  ParCreate('WL_max', '[cm]', 15, WL_max);
  ParCreate('k_z', '[cm.d-1.°C]', 0.0009, k_z);
  ParCreate('k_WL', '[cm.d-1.°C]', 0.002, k_WL);
  ParCreate('k_a', '[-]', 0.42, k_a);

  VarCreate('N_Rootcomp', '[n]', 20, true, N_Rootcomp);
  Varcreate('SRL', '[cm.cm-2]', 0.0, false, SRL);
  Varcreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff);



  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate('WLD_' + IntToStr(i), '[cm.cm-3]', 0.0, false, WLD_arr[i]);
    VarCreate('WL_' + IntToStr(i), '[cm.cm-2]', 0.0, false, WL_arr[i]);
//    VarCreate('WInflux'+IntToStr(i), '[cm3.cm-1.d-1]', 0.0, false,W_influx[i]);
//    pWLD_arr[i] := @wld_arr[i].fv;

  end;
  for i := 0 to trunc(n_Rootcomp.v) do
    ExternVCreate('Tiefe' + IntToStr(i), '[cm]', StateField, Tiefe[i]);


  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := 0.0;
  end;




end;


procedure TGrass_growth_quality_dauer.init(var GlobMod: TMod);
var
  i: integer;
begin

  inherited init(GlobMod);

  SW.v := swact.v;
  W.v := 0;
  quality.v := 0;
 // W.v := w0.v;
  yield_total.v := 0;
  zr.v := zr_0.v;
  //zr.v := 0;
  spechr.v := 0;

  oldharvestdate.v := harvestdate.v;

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := 0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;

  springcut := false;

  //ShowMessage('Init aufruf'); //  + inttostr(globmod.time.v));

end;


procedure TGrass_growth_quality_dauer.CalcRates;

var
  i: integer;
  year, month, date: word;


begin


// zwischen Aussaat und Ernte
  if (GlobTime.v >= SowingDate.v) and (GlobTime.v < HarvestDate.v) then begin
//If (GlobTime.v >= SowingDate.v) then begin
//harvestdate.v:=oldharvestdate.v;

{decodedate(globmod.time.v, year, month, date);
if (month >=1) and (month < 6) then begin

    w0.v:=w01.v;
    rs.v:=rs1.v;
    lai50.v:=lai50_1.v;
    ak.v:=ak1.v;
    pk.v:=pk1.v;
    mfk.v:=mfk1.v;
    tkq.v:=tkq1.v;
    rkq.v:=rkq1.v;
    qmin.v:=qmin1.v;
    qmax.v:=qmax1.v;
    schr50.v:=schr50_1.v;
    chrk.v:=chrk1.v;
 end;
if (month >=6)and (month < 9) then begin    // geändert Wienforth Böttcher 25.10.07   }
    if (GlobTime.v = SowingDate.v) then begin
      w0.v := w02.v;
      rs.v := rs2.v;
      lai50.v := lai50_2.v;
      ak.v := ak2.v;
      pk.v := pk2.v;
      mfk.v := mfk2.v;
      tkq.v := tkq2.v;
      rkq.v := rkq2.v;
      qmin.v := qmin2.v;
      qmax.v := qmax2.v;
      schr50.v := schr50_2.v;
      chrk.v := chrk2.v;
      zr_0.v := 3;
      WL_0.v := 1;
      zr.v := zr_0.v;

    end;
 {if (month >=9) then begin          // geändert Wienforth Böttcher 25.10.07

    w0.v:=w03.v;
    rs.v:=rs3.v;
    lai50.v:=lai50_3.v;
    ak.v:=ak3.v;
    pk.v:=pk3.v;
    mfk.v:=mfk3.v;
    tkq.v:=tkq3.v;
    rkq.v:=rkq3.v;
    qmin.v:=qmin3.v;
    qmax.v:=qmax3.v;
    schr50.v:=schr50_3.v;
    chrk.v:=chrk3.v;
 end;    }

    if Globtime.v = SowingDate.v then
      W.v := W0.v;

  // Temperatursumme
    Tsum.c := max(0, Temp.v);


// LAI
    LAI.v := sqrt(W.v / clai.v);
    if LAI.v <= 1 then LAI.v := 1;
    if LAI50.v > 0.0 then
      AGE.v := 1 / (1 + power((LAI.v / LAI50.v), ak.v))
    else AGE.v := 1;

    cai.v := (1 - exp(-cank.v * (LAI.v - LAIl.v) / LAIh.v)) / (1 - exp(-cank.v));



 //RI    radiation index
    radiation.v := GlobRad.v;

    rmax.v := rmlo.v + CAI.v * (rmxp.v - rmlo.v);
    RI.v := min(1, (1 - exp(-rk.v * radiation.v / rmax.v)) / (1 - exp(-rk.v)));

 //TI   temperature index
    TI.v := max(0, min(1.0 - (power(2 * abs(Temp.v - topt.v) / (topt.v - tthr.v), tk1.v)) * 0.5, 1));


    //WI  water index
    SW.c := Rain.v - pETP.v;
    SW1.v := max(0, min(SW.v + SWact.v, SWmax.v));

    WI.v := max(0, TransRatio.v);
    WI_2.v := min(1.0, SW1.v / (swthr.v * swmax.v));

    GI.v := TI.v * RI.v * WI.v;


    dW.v := W.v * rs.v * AGE.v * GI.v;

    W.c := dW.v;

    cropHeight.v := (wh.v * W.v) + 0.15;
    SRL.v := 0.0;
    SRL_eff.v := 0.0;

  //Quality

      //daylength
    TNR.v := GlobTime.v + 0.5;
    TLAM.v := TAGLI.v + 1.915 * sin((365.455 + 0.985647 * TNR.v) / 180 * 3.1416) + 0.02 * sin(2 * (365.455 + 0.985647 * TNR.v) / 180 * 3.1416);


    TAGX.v := tan(arcsin(0.39781 * sin(tlam.v / 180 * 3.1416)));
    TAGLI.v := 279.097 + 0.985647 * TNR.v;
    TAGB.v := -tan(qlat.v * 3.1416 / 180);
    daylength.v := 0.13333 * arccos(TAGB.v * TAGX.v) * 180 / 3.1416;

    //temperature
    tchr.v := max(0, 1 - exp(-tkq.v * (temp.v - tthrq.v)));

//{$APPTYPE CONSOLE}

//Writeln(floattostr(WI.v) + ' / ' + FloatToStr(mfk.v));

   //moisture
    if mchr_switch.v = 1 then
      mchr.v := max(0, 1 - (WI.v / mfk.v))
    else
      mchr.v := min(1, (WI.v / mfk.v));

     //photoperiod
    if qphsw.v = 2 then
      pchr.v := max(0, 1 - exp(-pk.v * (daylength.v - pthr.v)))
    else
      pchr.v := max(0, exp(-pk.v * (daylength.v - pthr.v)));

    //radiation
    r.v := GlobRad.v * 100;

    if rchr_switch.v = 1 then
      rchr.v := max(0, 1 - exp(-rkq.v * (r.v - rthrq.v)))
    else
      rchr.v := exp(-rkq.v * (r.v - rthrq.v));


    pechr.v := PCHR.v * TCHR.v * RCHR.v * MCHR.v;

    spechr.c := pechr.v;

    if funct.v = 1 then
      quality.v := qmin.v + (1 / (1 + power((SPECHR.v / schr50.v), chrk.v))) * (qmax.v - qmin.v)
    else if funct.v = 3 then
      quality.v := qmin.v + (power((SPECHR.v / schr50.v), chrk.v) / (1 + power((SPECHR.v / schr50.v), chrk.v))) * (qmax.v - qmin.v)

    else
      quality.v := al.v + bl.v * SPECHR.v;




 //roots

    for i := 1 to trunc(n_Rootcomp.v) do begin
      WLD_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, tiefe[i].v, TSum.v, Zr_max.v, Zr_0.v, K_z.v,
        WL_max.v, WL_0.v, k_WL.v, k_a.v);
      Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);
      SRL.v := SRL.v + WL_arr[i].v;
      SRL_eff.v := SRL_eff.v + WL_arr[i].v;
    end;



    decodedate(globmod.time.v, year, month, date);
        //If (Month=1) and (date=1) and (springcut=false) then begin
    if (Month = 1) and (date = 1) then begin
      springcut := true;

      w0.v := w01.v;
      rs.v := rs1.v;
      lai50.v := lai50_1.v;
      ak.v := ak1.v;
      pk.v := pk1.v;
      mfk.v := mfk1.v;
      tkq.v := tkq1.v;
      rkq.v := rkq1.v;
      qmin.v := qmin1.v;
      qmax.v := qmax1.v;
      schr50.v := schr50_1.v;
      chrk.v := chrk1.v;
      zr_0.v := zr.v;
      WL_0.v := 165;
      W.v := W01.v;
      W.c := 0;
      dW.v := 0;
      cropHeight.v := 0.15;
      LAI.v := LAIl.v;
      quality.v := qmin.v;
      spechr.v := 0;
      spechr.c := 0;
      Tsum.c := 0;
      Tsum.v := 0;

      SW.v := swact.v;
      zr.v := zr_0.v;
      pechr.v := 0;
      tchr.v := 0;

    // Jahreswechsel, Gesamtertrag null setzen
      yield_total.v := 0;
    end;

  end; // growing season


  //harvest
  decodedate(globmod.time.v, year, month, date);
 //if (quality.v>=cut1.v) or (W.v>=cutW.v) or (GlobTime.v>=HarvestDate.v) then begin
 {if ((quality.v>=cut1.v) and (W0.v=w01.v)) or ((W.v>=cutW.v)and (W0.v<>w01.v))
     or ((quality.v>=cut2.v) and (W0.v=w02.v)) or ((W.v>=cut2W.v)and (W0.v<>w02.v)) or (((month=10) and (date=20))and (W0.v<>w02.v))  //Böttcher u Wienforth
     or ((quality.v>=cut3.v) and (W0.v=w03.v)) or ((W.v>=cut3W.v)and (W0.v<>w03.v)) or (((month=10) and (date=20))and (W0.v<>w03.v)) //Böttcher u Wienforth
     then begin }


  if   (((month = 5) and (date = 10)) and (W.v > W0.v))
    //or ((springcut = true) and ((quality.v >= cut1.v) or (W.v >= cutW.v))) // geändert Wienforth Böttcher 25.10.07
    or ((quality.v >= cut2.v) and (W0.v = w02.v))
    //or ((W.v >= cut2W.v) and (W0.v = w02.v))
    or (((month = 10) and (date = 30)) and (W.v > w0.v)) // geändert Wienforth Böttcher 25.10.07
    //or ((quality.v >= cut3.v) and (W0.v = w03.v))
    //or ((W.v >= cut3W.v) and (W0.v = w03.v))
    //or (((month = 10) and (date = 30)) and (W.v > w0.v)) // geändert Wienforth Böttcher 25.10.07
  then begin
   //springcut := false;

   //  self.SowingDate.v := Globtime.v +1;
    yield_total.v := W.v + yield_total.v;

    decodedate(globmod.time.v, year, month, date);
    if (month >= 1) and (month < 6) then begin
      w0.v := w01.v;
      rs.v := rs1.v;
      lai50.v := lai50_1.v;
      ak.v := ak1.v;
      pk.v := pk1.v;
      mfk.v := mfk1.v;
      tkq.v := tkq1.v;
      rkq.v := rkq1.v;
      qmin.v := qmin1.v;
      qmax.v := qmax1.v;
      schr50.v := schr50_1.v;
      chrk.v := chrk1.v;
      zr_0.v := zr.v;
      WL_0.v := 165;
    end
    else if (month >= 6) and (month < 9) then begin
      w0.v := w02.v;
      rs.v := rs2.v;
      lai50.v := lai50_2.v;
      ak.v := ak2.v;
      pk.v := pk2.v;
      mfk.v := mfk2.v;
      tkq.v := tkq2.v;
      rkq.v := rkq2.v;
      qmin.v := qmin2.v;
      qmax.v := qmax2.v;
      schr50.v := schr50_2.v;
      chrk.v := chrk2.v;
      zr_0.v := zr.v;
      WL_0.v := 165;
    end
    else if (month >= 9) and (month <= 12) then begin
      w0.v := w03.v;
      rs.v := rs3.v;
      lai50.v := lai50_3.v;
      ak.v := ak3.v;
      pk.v := pk3.v;
      mfk.v := mfk3.v;
      tkq.v := tkq3.v;
      rkq.v := rkq3.v;
      qmin.v := qmin3.v;
      qmax.v := qmax3.v;
      schr50.v := schr50_3.v;
      chrk.v := chrk3.v;
      zr_0.v := zr.v;
      WL_0.v := 165;
    end;

     // oldharvestdate.v:=harvestdate.v+365.455;

   // bei Nachwuchs

    W.v := W0.v;

    W.c := 0;
    dW.v := 0;
    cropHeight.v := 0.15;
    LAI.v := LAIl.v;
    quality.v := qmin.v;
    spechr.v := 0;
    spechr.c := 0;
    Tsum.c := 0;
    Tsum.v := 0;

    SW.v := swact.v;
    zr.v := zr_0.v;
    pechr.v := 0;
    tchr.v := 0;

   { for i := 1 to trunc(n_Rootcomp.v) do begin
      WLD_arr[i].v :=0.0;
      Wl_arr[i].v := 0.0;
    end;      }

    {
    if springcut = true then begin
      W.c := 0;
      W.v := 0;
      quality.v := 0;
      spechr.v := 0;
      zr.v := 0;
      for i := 1 to trunc(n_Rootcomp.v) do begin
        WLD_arr[i].v := 0.0;
        Wl_arr[i].v := 0.0;
      end;

      harvestdate.v := Globtime.v;
      DoHarvest := true;

      NextCrop.SowingDate.v := Globtime.v + 10;
      springcut := false;
    end;
    }

    // Wechsel der Feldfrucht nach dem Frühjahrsschnitt
//   if (month<=4) or ((month=5) and (date<15))  then begin
//   if (month<=6) or ((month=7) and (date<15))  then begin
  end; // harvest


 // geändert Wienforth Böttcher 25.10.07 :

//if (((month=5) and (date=15)) and (W.v>W0.v))or (((W0.v<>w01.v)) and ((quality.v>=cut1.v) or (W.v>=cutW.v)))  then begin  //Kage
(* if (((month=5) and (date=15)) and (W.v>W0.v)) or ((springcut=true) and ((quality.v>=cut1.v) or (W.v>=cutW.v)))  then begin //Wienforth
//if (((month=5) and (date=15)) and (W.v>W0.v)) or ((springcut=true) and ((quality.v>=cut1.v) or (W.v>=cutW.v)))  then begin
   W.c:=0;
   W.v:=0;
   quality.v:=0;
   spechr.v:=0;
   harvestdate.v := Globtime.v;
   DoHarvest := true;
   decodedate(globmod.time.v, year, month, date);


   NextCrop.SowingDate.v := Globtime.v +14{-730};
   springcut := false;

 //  If self.SetNewDates = false then begin
 //     sowingdate.v := 1e6; // arbitrary high number to assure that sowingdate will be set by previous crop
 //     harvestdate.v := 1e6;
 //  end;

  { if (year>1975) then
    NextCrop.SowingDate.v := Globtime.v +14; }
//    NextCrop.HarvestDate.v := Globtime.v +14+300;

 end;*)




 // inherited Integrate;


 //inherited calcrates;



end;




procedure Register;
begin
  RegisterComponents('GrassModelDauer', [TGrass_growth_quality_dauer]);
end;

end.

