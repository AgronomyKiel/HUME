unit UHumeWheatLeafArea;
(*
Developer: A.M. Ratjen
- the module calculates leaf area development and leaf senescence
- LAI net increase is calculated as a function of leaf dry matter and
  over all canopý specific leaf area (SLA)
- SLA is calculated as a function of leaf dry matter
  (see Chapt. 3 and Appendix Diss. Ratjen)
- during vegetative growth, leaf senescence forced by aging is similar to
  the CeresWheat3.0 routines, but accelerated under drought, N limitation
  or light limitation(according to Meinke 1998).
- leaf distribution (mass, area) is calculated for specific leaf-layers
  as a function of LAI(empiric fit exp. 103 2010, see also Appendix Diss. Ratjen)
- during reproductive stage, senescence is forced by N translocation(SLN threshold
  according to Meinke 1998)
*)

interface

uses
  UMod, UState, vcl.Dialogs, SysUtils, UHumeWheatDryMatter;

const
  MaxLeafNumber = 25;

type
  TSenescence = (cwt3, concentration);

  THumeWheatLeafArea = class(TSubmodel)
  private
    p5_:         real;
    fSenescence: TSenescence;
    avTransIntRatio_arr:  array [1..10] of real;
    procedure SetLaiLayers;
  protected
 //----------------
     fDroughtImpact : TDroughtImpact;
 //----------------
    function s_LAI(Temp_, Sat_def_, Net_beam_, delta_, gamma_, ra_,
      actTrans_, exLAI: real): real;
    function calcPotSLA(Wleaf,dWleaf,BBCH,SLA_old: real): real;
     function calcGAI(EC,LAI: real): real;
    procedure setleaf_arr(PLALR_: real);
    procedure calcSenescence;
  public

//--------------------------------------------------------------------
  senratesLA : array[1..MaxLeafNumber] of real; // senescence rates leaf area of individual leaves
  senratesDM : array[1..MaxLeafNumber] of real; // senescence rates dry matter of individual leaves

  LAImax     : TVar;   /// maximum LAI simulated
  GPLA       : TVar;   /// GPLA is the plant green leaf area (PLA - SENLA) [cm2/plant]
  LN_        : TVar;   /// Leaf number of the primary tiller [n]
  PLAG       : TVar;   /// The rate of expansion of leaf area on one plant [cm2/day]
  PLAGMS     : TVar;   /// plant leaf area growth rate on the main stem (PLAGMS)
  PLALR      : TVar;   /// Plant leaf area loss rate [cm2/(plant*d)]
  PLSCGR     : array [1..MaxLeafNumber] of TVar;   ///  Leaf area growth rate of single leaves
  V1         : TVar;   /// source limited leaf growth rate
  V2         : TVar;   /// sink limited leaf growth rate
  GAI         : TVar;   /// green area index
 // fSLAWR     : TVar;   /// factor for correcting SLA under drought stress
  potSLA      : TVar;   /// average specific leaf area of canopy [square cm/g]
  avSLA     : TVar;
  avIcrop    : TVar; /// Mittlere Einstrahlung im Bestand (I) über 10 Tage
  // Constant Variables
  LAI         : TState;   /// Leaf area index [m2/m2]
  PLA         : TState;   /// Plant leaf area  [cm2/plant]
  PLSC        : array[1..MaxLeafNumber] of TState;   ///  Leaf area of single leaves
 // PL_weight   : array[1..MaxLeafNumber] of TState;   ///  Leaf weight of single leaves
  SENLA       : TState;   ///  Area of leaf that senesces from a tiller on a given day - [cm2/d]
  CUMPH : TState;   /// cumulative phyllochrons since emergence [-]

  // Parameters
  maxPLALR    : TPar;   // maximum senescens rate  [cm2/(plant*d)]
  aSLA         : TPar; /// intercept specific leaf area due to shading [cm2/g]
  bSLA         : TPar; /// slope specific leaf area due to shading [cm2/(g*LAI)]
  maxSLA       : TPar; /// initial and maximum SLA [cm2/g]
  PSENLeaf1    : TPar; /// Parameter for leaf senescence
  PSENLeaf2    : TPar; /// Parameter for leaf senescence
  fGAI         : TPar;
  // External Variables
  sln    : TExternV;
  NLeaf_m2    : TExternV;
  GROLF       : TExternV;   ///  growth rate of leaves (g/pl/d)
///  GROSTM      : TExternV;   /// Daily stem growth  [g/(plant.d)]
  ISTAGE      : TExternV;   ///  integer growth stage according to ceres
//  XSTAGE      : TExternV;
  P5          : TExternV;   /// Parameter or length of grain filling period
  plants      : TExternV;   /// number of plants (1/m2)
//  SWDF1       : TExternV;   // Soil Water deficit factor (Tact/Tpot)
//  TDU         : TExternV;   // termal developmental units
  TMPM        : TExternV;   /// mean day temperature
  TMPMN       : TExternv;   /// minimum day temperature
  TMPMX       : TExternV;   /// maximum day temperature
  //TI          : TExternV;   // increase of tiller number (1/d)
  //TILN        : TExternV;   // tiller number per plant
  //TPSM        : TExternV;   // tiller number per m2
  EC          : TExternV;   /// ec stage of crop
  SENL        : TExternV;   /// Senescence rate of leaf dry matter (total) (g/pl/d)
  Phint       : TExternV;   /// Phyllochronintervall [°d]
  TSumInc     : TExternV;   ///Tagestemperatur >=0 zur Basistemperatur
  PAR        : TExternV;
  kPAR        : TExternV; /// k for PAR
  Icrop: Array [1..10] of real; ///Mittlere Einstrahlung über 10 Tage
  // Options
  OptDroughtimpact : Toption;
//--------------------------------------------------------------------
    Icrit:     TPAR;
    f1_SLA: TPAR;
    f2_SLA: TPAR;
    kTransPAR: TPAR; /// PAR transmission coefficient
   // critSLN:   TPAR; // APSIM meinke 1998, 107
    critSLNtot:   TPAR; /// Minium observed 95er
    P5_2:      TPAR;
    TRcrit:    TPAR;
    relLayerM_Int:  array[1..3] of TPAR;
    relLayerA_Int:  array[1..3] of TPAR;
    relLayerM_S  :  array[1..3] of TPAR;
    relLayerA_S  :  array[1..3] of TPAR;
    GROLA:     TVAR;
    sumLAL:    TVAR;
    sumMLAL:   TVAR;
    fdsen:     TVAR;
    sumPLsc:      TVAR;
    MLAL:         array[1..4] of TVAR; /// green leaf mass of layer
    LAL:          array[1..4] of TVAR;   ///  Leaf area of a lamina i
    DSsen:        TVAR;
    LLsen:        TVAR;
    Nsen:         TVAR;
    evenTransIntRatio: TVar;
    PotTrans: TExternV;
    LFWT_m2:  TExternV;
    LFWT_pl:  TExternV;
    interzeption: TExternV;
    ActTrans: TExternV;
    GlobRad:  TExternV;
    exk_GlobRad: TExternV;
    TransRatio: TExternV;
    TransIntRatio: TExternV;
    NetRain:  TExternV;
    Rad_Int:  TExternV;
    EC_lgend: TExternV;
//    NStoragepool_pl: TExternV;
    NcLAL:    array[1..4] of TExternV;
    ra:       TExternV;
    Sat_def:  TExternV;
    P:        TExternV;
    sic:      TExternV;
    int_stor: TExternV;
    rain:     TExternV;
    rc0:      TExternV;
//    Ncmob:    TExternV;
    gamma:    real;
    delta:    real;
    LAIs:     real;
    PARi:     array[1..4] of TState;////  amount of PAR incident on the surface of lamina i
    optSenescence: TOption;
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;


  published
   //-----------------------------------
    Property Var_GPLA : TVar read GPLA write GPLA;
    Property Var_LN_ : TVar read LN_ write LN_;
    Property Var_PLAG : TVar read PLAG write PLAG;
    Property Var_PLAGMS : TVar read PLAGMS write PLAGMS;
    Property Var_PLALR : TVar read PLALR write PLALR;
    Property Var_V1 : TVar read V1 write V1;
    Property Var_V2 : TVar read V2 write V2;
   // Property Par_CLG : TPar read CLG write CLG;
    Property St_LAI : TState read LAI write LAI;
    Property St_PLA : TState read PLA write PLA;
    Property St_SENLA : TState read SENLA write SENLA;
    Property St_CUMPH : TState read CUMPH write CUMPH;
         // Parameters
    Property Ex_GROLF : TExternV read GROLF write GROLF;
//    Property Ex_GROSTM : TExternV read GROSTM write GROSTM;
    Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
    Property Ex_Phint : TExternV read Phint write Phint;
    Property Ex_P5 : TExternV read P5 write P5;
    Property Ex_plants : TExternV read plants write plants;
//    Property Ex_SWDF1 : TExternV read SWDF1 write SWDF1;
//    Property Ex_TDU : TExternV read TDU write TDU;
    Property Ex_TMPM : TExternV read TMPM write TMPM;
    Property Ex_TMPMN : TExternV read TMPMN write TMPMN;
    Property Ex_TMPMX : TExternV read TMPMX write TMPMX;
    Property Ex_TSumInc : TExternV read TSumInc write TSumInc;
    property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;
  //-----------------------------------
    property Ex_rc0: TExternV Read rc0 Write rc0;
    property Ex_rain: TExternV Read rain Write rain;
    property Ex_sic: TExternV Read sic Write sic;
    property Ex_Sint_stor: TExternV Read int_stor Write int_stor;
    property Ex_P: TExternV Read P Write P;
    property Ex_Sat_def: TExternV Read Sat_def Write Sat_def;
    property Ex_ra: TExternV Read ra Write ra;
    property Ex_Rad_Int: TExternV Read Rad_Int Write Rad_Int;
    property Ex_NetRain: TExternV Read NetRain Write NetRain;
    property Ex_TransRatio: TExternV Read TransRatio Write TransRatio;
    property Ex_TransIntRatio: TExternV Read TransIntRatio Write TransIntRatio;
    property Ex_exk_GlobRad: TExternV Read exk_GlobRad Write exk_GlobRad;
    property Ex_ActTrans: TExternV Read ActTrans Write ActTrans;
    property Ex_interzeption: TExternV Read interzeption Write interzeption;
    property Ex_PotTrans: TExternV Read PotTrans Write PotTrans;
  end;

procedure Register;

implementation

uses
  Math, Classes;

function THumeWheatLeafArea.calcGAI(EC,LAI: real): real;
{
 After booting, GAI is 20% higher than LAI dest. [94er 2004]
 linear transition-phase between BBCH50-60
}
var
fGAI_: real; // factor vor LAI->GAI
begin
  //fGAI:=0;
  if(EC>50) then begin
    if(EC<60) then
      fGAI_:=fGAI.v*0.1*(EC-50)
      else
        fGAI_:=fGAI.v;
    calcGAI:=LAI*(1+fGAI_);
  end else
  calcGAI:=LAI;
end;

procedure THumeWheatLeafArea.setleaf_arr(PLALR_: real);
var
  i, ln_, spos: integer;
  fLWS, sumla:  real;
begin
  ln_ := -1;
  sumla := 0;
  for i := MaxLeafNumber downto 1 do
  begin
    sumla := sumla + PLSC[i].v;
    if (PLSC[i].v > 0) and (ln_ < 0) then
    begin
      ln_ := i;
    end;
  end;
  if ln_ = -1 then
    exit;
  // find first leaf pos:
  spos := -1;
  for i := 1 to ln_ do
  begin
    if (PLSC[i].v > 0) then
    begin
      if (spos = -1) then
        spos := i;
    end;
  end;
  PLALR_ := min(PLALR_, sumla);
  while (PLALR_ > 0) do
  begin
    if PLALR_ < PLSC[spos].v then
    begin
      fLWS := (PLSC[spos].v - PLALR_) / PLSC[spos].v;
      PLALR_ := 0;
      PLSC[spos].v := PLSC[spos].v * fLWS;
    end else
    begin
      PLALR_ := PLALR_ - PLSC[spos].v;
      PLSC[spos].v := 0;
    end;
    if (PLALR_ > 0) and (spos < ln_) then
      spos := spos + 1
    else
    if (spos = ln_) then
      PLALR_ := 0; // to prevent rounding errors;
  end;
  sumla := 0;
  for i := MaxLeafNumber downto 1 do
  begin
    sumla := sumla + PLSC[i].v;
  end;
end;

function THumeWheatLeafArea.calcPotSLA(Wleaf,dWleaf,BBCH,SLA_old: real): real;

var
  SLA_,SLAs,SLAw,w,LAIe,a,b,SLA_B: real;
begin
     a := aSLA.v; //intercept
     b := bSLA.v;  // slope
     SLA_B := maxSLA.v; //start SLA of juvenescent leafs (APSIM, Asseng 2003)
     if (SLA_old=0) and (bbch<20) then
        SLA_:=SLA_B //initialise with high SLA of juvenile leafs
        else
        begin
          w:=(Wleaf+dWleaf)*1E-4; //g->10kg
          LAIe:= w*SLA_old;
     // SLAs: SLA as a function of LAI(empiric fit see Chapt. 3 Diss. Ratjen)
          SLAs:= min(SLA_B,a+b*LAIe);
          if SLA_old>SLAs then
            begin
          // transition phase between initial SLA and later phase where
          // mutual shading dominates SLA
              SLAw:= SLAs+(SLA_B-SLAs)*exp(f1_SLA.v*LAIe+f2_SLA.v);
              SLA_:= min(SLA_old,SLAw)
            end else
              // phase where shading dominates SLA (equates LAI~2)
              SLA_:=SLAs;
            end;
     calcPotSLA:= SLA_;
end;

function THumeWheatLeafArea.s_LAI(Temp_, Sat_def_, Net_beam_, delta_,
  gamma_, ra_, actTrans_, exLAI: real): real;
(*
  this function calculates the sustaiable LAI (LAIs) under drought,
  defined as the leaf area that results if the ratio between actual and
  potential transpiration equals the  threshold (TRcrit).
  LAIs2 is thereby estimated iteratively, by calculating potential and actual
  transpiration (assuming constant transpiration of interception water),
  using the Newton's method for optimization.
*)
  const
  cp = 1005.0;      { spezifische Wärme der Luft [J/(Kg*K)] }
var
  pETP_: Extended;
  ro, int_stor_: Extended;
  max_int_cap,             { maximale Interzeptionskapazit„t [mm] }
  int_cap,                  { aktuelle Interzeptionskapazität [mm]  }
  Pot_Evapo_:Extended;
  pot_trans_, delta2, //Iterationsschrittweite
  a, F, exLAI_, b, // Steigung (Ableitung)
  rc, actTransInt, potTransInt, PTI, Interzeption_: Extended;
  // Summe von Interzeption und potentieller Transpirationsrate
  steps: integer;
begin
  b:=0;
  Steps := 0;
  int_stor_ := int_stor.v;
  potTransInt := potTrans.v + Interzeption.v;
  actTransInt := actTrans_ + Interzeption.v;
  f := potTransInt*TRcrit.v - actTransInt;
  delta2 := LAI.v / 1000;
  while Power(f, 2) > 0.000001 do
  begin
    Steps := Steps + 1;
    if Steps > 10 then
    begin
      s_LAI := exLAI;
      exit;
    end;
    if (ExLAI = LAI.v) then // first iteration
    begin
      ExLAI_ := LAI.v;
      ExLAI  := LAI.v - (delta2);
    end else
    begin
      ExLAI_ := ExLAI;
      if b <> 0 then
      begin
        ExLAI := ExLAI_ - (f / b);
        if (ExLAI = LAI.v) then
        begin
          s_LAI := exLAI_;
          exit;
        end;
      end else
      begin
        s_LAI := exLAI_;
        exit;
      end;
    end;
    //PenMonteith:
    ro := 1.2917 - 0.00434 * Temp_;
    if ExLAI < 1.0 then
      rc := rc0.v
    else if (ExLAI >= 1.0) and (ExLAI < 2) then
      rc := rc0.v / ExLAI
    else if (ExLAI >= 2.0) and (ExLAI < 6) then
      rc := rc0.v / 2 - (rc0.v / 2 - rc0.v / 3) * ((ExLAI - 2) / 4)
    // according to Stockle (????)
    else
      rc := rc0.v / 3;
    if rc < 0.1 then
      rc := 0.1;
    pETP_ := (Delta * Net_beam_ + ro * cp * Sat_def_ / ra_) /
      (delta_ + gamma_ * (1 + rc / ra_));
    pETP_ := pETP_ / (2.477 * 1e6) * 86400.0;
    //2.477*1e6 = latente Verdunstungsenergie von
    {  Wasser bei bei 10 øC in [J/Kg] }
    Pot_Evapo_ := pETP_ * exp(-exk_GlobRad.v * ExLAI);
    if Pot_Evapo_ < 0.0 then
      Pot_Evapo_ := 0.0;
    pTI := pETP_ - pot_Evapo_;
    //Interzeption:
    max_int_cap := ExLAI * sic.v;
    int_cap := max_int_cap - int_stor_;
    if int_cap > 0.0 then
    begin
      if int_cap > (rain.v * GlobTime.c) then
      begin
        int_stor_ := int_stor_ + rain.v * GlobTime.c;
      end else
        int_stor_ := max_int_cap;
    end;
    if pTI * GlobTime.c > int_stor_ then
    begin
      pTI := pTI - int_stor_ / GlobTime.c;
      Interzeption_ := int_stor_ / GlobTime.c;
      int_stor_ := 0.0;
    end else
    begin
      Interzeption_ := PTI;
      int_stor_ := int_stor_ - pti * GlobTime.c;
    end;    //End Interzeption
    //potTrans:
    if petp_ > 0.0 then
      pot_trans_ := (pETP_ - Pot_Evapo_ - Interzeption_)
    else
      Pot_Trans_ := 0.0;
    if pot_Trans_ < 0.0 then
      pot_Trans_ := 0.0;
    potTransInt := pot_trans_ + Interzeption_;
    // End potTrans
    a := f;
    f := potTransInt*TRcrit.v - actTransInt;
    if power(a, 2) <= power(f, 2) then
    begin
      s_LAI := exLAI_;
      exit;
    end;
    if (ExLAI - ExLAI_) <> 0 then
      b := (f - a) / (ExLAI - ExLAI_)
    else
      break;
  end; //while end
  s_LAI := exLAI;
end;  { End sLAI }

procedure THumeWheatLeafArea.CreateAll;
var
  i: integer;
begin
  inherited createAll;
//-------------------------------------------------------
  VarCreate('LAImax', '[]',0, true, LAImax);
  VarCreate('GAI', '[]',0, true, GAI);
  VarCreate('avSLA', '[square cm/g]',0, true, avSLA);
  VarCreate('GPLA', '[cm2/plant]',0, true, GPLA);
  VarCreate('LN_', '[n]',0, true, LN_);
  VarCreate('PLAG', '[cm2/day]',0, true, PLAG);
  VarCreate('PLAGMS', '',0, true, PLAGMS);
  VarCreate('PLALR', '[cm2/(plant*d)]',0, true, PLALR);
  for I := 1 to MaxLeafNumber do
    if I < 10 then
      VarCreate('PLSCGR__' +inttostr(i), '[cm2/plant]',0, true, PLSCGR[i])
    else
      VarCreate('PLSCGR_' +inttostr(i), '[cm2/plant]',0, true, PLSCGR[i]);
  VarCreate('V1', '',0, true, V1);
  VarCreate('V2', '',0, true, V2);
  //VarCreate('fSLAWR', '',0, true, fSLAWR);
  VarCreate('potSLA', '', 0, true, potSLA);
  VarCreate('avIcrop', '', 0, true, avIcrop);

  StateCreate('LAI', '[m2/m2]',0, true,LAI);
  StateCreate('PLA', '[cm2/plant]',0, true,PLA);
  for i := 1 to MaxLeafNumber do begin
    if i < 10 then
      StateCreate('PLSC__'+inttostr(i),'[cm2/plant]',0, true, PLSC[i])
    else
      StateCreate('PLSC_'+inttostr(i),'[cm2/plant]',0, true, PLSC[i]);
    end;
  StateCreate('SENLA', '[cm2/d]',0, true,SENLA);
  StateCreate('CUMPH', '[-]',0, true,CUMPH);
  // Parameters
  ParCreate('fGAI', '[-]', 0.2 ,fGAI,'LAI->GAI (94er 2004)');
  ParCreate('maxPLALR', ' %LAI_max', 5 ,maxPLALR);
  ParCreate('aSLA', '[cm2/g]', 136.69 ,aSLA);
  ParCreate('bSLA', '[cm2/(g*LAI)]', 14.93 ,bSLA);
  ParCreate('maxSLA', '[cm2/g]', 250 ,maxSLA);
  ParCreate('PSENLeaf1', '[-]',0.0003,PSENLeaf1);
  ParCreate('PSENLeaf2', '[-]',0.0006,PSENLeaf2);
  ParCreate('Icrit', '[MJ/(m2*d)]', 0.8, Icrit);
  ParCreate('f1_SLA', '[-]', -1.1237, f1_SLA);
  ParCreate('f2_SLA', '[-]', 0.3, f2_SLA);
  ParCreate('kTransPAR', '[-]', 0.7, kTransPAR);
  ParCreate('critSLNtot', '[-]', 0.8, critSLNtot, 'critical SLN value for leave senescense');
  ParCreate('TRCrit', '[-]', 0.8, TRCrit);
  ParCreate('P5_2', '[°Cd]', 630, P5_2);
  ExternVCreate('sln', 'g/m2',statefield, sln);
  ExternVCreate('NLeaf_m2', 'g/m2',statefield, NLeaf_m2);
  ExternVCreate('GROLF', '',statefield, GROLF);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
//  ExternVCreate('XSTAGE', '',statefield, XSTAGE);
//  ExternVCreate('GROSTM', '',statefield, GROSTM);
  ExternVCreate('P5', '', statefield, P5);
  ExternVCreate('plants', '',statefield, plants);
//  ExternVCreate('SWDF1', '',statefield, SWDF1);
//  ExternVCreate('TDU', '',statefield, TDU);
  ExternVCreate('TMPM', '',statefield, TMPM);
  ExternVCreate('TMPMN', '',statefield, TMPMN);
  ExternVCreate('TMPMX', '',statefield, TMPMX);
  ExternVCreate('EC', '',statefield, EC);
  ExternVCreate('SENL', '', ratefield, SENL);
  ExternVCreate('Phint', '',statefield, Phint);
  ExternVCreate('TSumInc', '',statefield, TSumInc);
  ExternVCreate('kPAR', '',statefield, kPAR);
  ExternVCreate('PAR', '',statefield, PAR);
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerA_Int' + IntToStr(i), '[-]', 0.2976, relLayerA_Int[i]);
    if i = 2 then
      ParCreate('relLayerA_Int' + IntToStr(i), '[-]',  0.2562, relLayerA_Int[i]);
    if i = 3 then
      ParCreate('relLayerA_Int' + IntToStr(i), '[-]', 0.2404, relLayerA_Int[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerA_S' + IntToStr(i), '[-]', 0.0087, relLayerA_S[i]);
    if i = 2 then
      ParCreate('relLayerA_S' + IntToStr(i), '[-]', 0.0187, relLayerA_S[i]);
    if i = 3 then
      ParCreate('relLayerA_S' + IntToStr(i), '[-]',  -0.0018, relLayerA_S[i]);
  end;
    for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerM_Int' + IntToStr(i), '[-]', 0.2916, relLayerM_Int[i]);
    if i = 2 then
      ParCreate('relLayerM_Int' + IntToStr(i), '[-]', 0.2694, relLayerM_Int[i]);
    if i = 3 then
      ParCreate('relLayerM_Int' + IntToStr(i), '[-]', 0.2504, relLayerM_Int[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerM_S' + IntToStr(i), '[-]', 0.0168, relLayerM_S[i]);
    if i = 2 then
      ParCreate('relLayerM_S' + IntToStr(i), '[-]', 0.0161, relLayerM_S[i]);
    if i = 3 then
      ParCreate('relLayerM_S' + IntToStr(i), '[-]',  -0.0089, relLayerM_S[i]);
  end;
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    VARCreate('MLAL' + IntToStr(i), '[g/m2]', 0, True, MLAL[i]);
  end;
    for i := 1 to 4 do
  begin  // Vier Blattetagen
    VARCreate('LAL_' + IntToStr(i), '[m2/m2]', 0, True, LAL[i]);
  end;
  VarCreate('evenTransIntRatio', '[-]', 1, False, evenTransIntRatio, 'mean of 10 days TransintRatio');
  VarCreate('sumplsc', '[cm2/pl]', 0, False, sumplsc);
  VarCreate('sumLAL', '[m2/m2]', 0, False, sumLAL);
  VarCreate('sumMLAL', '[g/m2]', 0, False, sumMLAL);
  VarCreate('DSsen', 'cm2/(plant*d)', 0, False, DSsen);
  VarCreate('Nsen', 'cm2/(plant*d)', 0, False, Nsen,'fraction of senescent leaf area caused by N limitation');
  VarCreate('LLsen', 'cm2/(plant*d)', 0, False, LLsen);
  VarCreate('fdsen', '[]', 0, False, fdsen);
//  ExternVcreate('Ncmob', '[-]', stateField, Ncmob);
  ExternVcreate('EC_lgend', '[-]', stateField, EC_lgend);
//  ExternVcreate('NStoragepool_pl', '[g/plant]', stateField, NStoragepool_pl);
  ExternVcreate('LFWT_m2', '[g/m2]', stateField, LFWT_m2);
  ExternVcreate('LFWT_pl', '[g/pl]', stateField, LFWT_pl);
  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans);
  ExternVcreate('ActTrans', '[mm.d-1]', stateField, ActTrans);
  ExternVcreate('interzeption', '[-]', stateField, interzeption);
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad);
  ExternVcreate('exk_GlobRad', '[-]', stateField, exk_GlobRad);
  ExternVcreate('SIC', '[mm.m2.m2]', stateField, SIC);
  ExternVcreate('TransRatio', '[-]', stateField, TransRatio);
  ExternVcreate('TransIntRatio', '[-]', stateField, TransIntRatio);
  ExternVcreate('int_stor', '[-]', stateField, int_stor);
  ExternVcreate('rain', '[-]', stateField, rain);
  ExternVcreate('P', '[-]', stateField, P);
  ExternVcreate('sat_def', '[-]', stateField, sat_def);
  ExternVcreate('ra', '[-]', stateField, ra);
  ExternVcreate('rc0', '[-]', stateField, rc0);
  ExternVcreate('NetRain', '[-]', stateField, NetRain);
  ExternVCreate('PAR', '[MJ/m2]', statefield, PAR);
  ExternVCreate('Rad_Int', '[W/m2]', statefield, Rad_Int);
  //ExternVCreate('Tiln', '[-]', statefield, Tiln);
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    ExternVCreate('NcLAL__' + IntToStr(i), '[%]', statefield, NcLAL[i]);
  end;
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    StateCreate('PARi' + IntToStr(i), '[W/m2]', 0, True, PARi[i]);
  end;
  optCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
  optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');
  optCreate('optSenescence', 'Concentration', optSenescence);
  optSenescence.OptionList.Clear;
  optSenescence.OptionList.Add('CWT3');
  optSenescence.OptionList.Add('Concentration');
end;

procedure THumeWheatLeafArea.calcSenescence;
var
  PLALR_a, // 'age' induced pot. leaf senescence rate(according to CeresWheat3)
  PLALR_d, // drought induced pot. leaf senescence rate
  PLALR_n, // pot. leaf senescence rate induced by N limitation (during grain filling)
  PLALR_l: real;// pot. leaf senescence rate induced by light limitation
  i : integer;
  Nccrit_: real;
  NetBeam: real;
  SLN_,maxLAIsen,NLAL_,MLAL_s, LAL_s,SUM_I,SUM_avTIR: real;
begin
  PLALR_a  := 0;
  PLALR_d  := 0;
  PLALR_n  := 0;
  PLALR_l  := 0;
  PLALR.v  := 0;

  if (round(ISTAGE.v) >= 1) and (round(ISTAGE.v) <= 2) and (CUMPH.v > 4) and
    (ec.v < 30) then // senecence only until EC 30, changed ..
  begin
    if senratesLA[trunc(LN_.v) - 4] = 0 then
    begin
      senratesLA[trunc(LN_.v) - 4] := (PLSC[trunc(LN_.v) - 4].v);
      // the fifth oldest leaf is deceasing
    end;
    PLALR_a := min(PLSC[trunc(LN_.v) - 4].v / globtime.c,
    senratesLA[trunc(LN_.v) - 4] * TSumInc.v / PhInt.v);
    if (ln_.v > 5) and (PLSC[trunc(LN_.v) - 5].v > 0.0) then
    begin
    PLALR_a := PLALR_a + PLSC[trunc(LN_.v) - 5].v / globtime.c;
    end;
  end else
  begin
    if (round(ISTAGE.v) = 1) and (pla.v > 0) and (SENLA.v / pla.v > 0.4) and
      (LAI.v < 6.0) then
      PLALR_a := 0
    else if (ISTAGE.v >= 2) and (ISTAGE.v < 4) then
    begin
      PLALR_a := PSENLeaf1.v * TSumInc.v * GPLA.v;
    end
    else if (ISTAGE.v >= 4) and (ISTAGE.v < 5) then
    begin
      PLALR_a := PSENLeaf2.v * TSumInc.v * GPLA.v;
    end;

  end;

  if fSenescence = Concentration then
  begin
  if (SLN.v<critSLNtot.v) and (LAI.v>0) and (SLN.v>0) then
	  PLALR_n:=min((LAImax.v * 1E4 / plants.v)*maxPLALR.v/100,(LAI.v * 1E4 / plants.v)*(1-SLN.v/critSLNtot.v));
  end else PLALR_n:=0;

 (*
 if fSenescence = Concentration then
      begin
        for i := 4 downto 1 do
        begin
          if LAL[i].v > 0 then
            Nccrit_ := (critSLNtot.v * (LAL[i].v / MLAL[i].v)) * 100
          else
            Nccrit_ := 0;
          if (NcLAL[i].v < Nccrit_) and (LAL[i].v > 0) then
          begin
            if (NcLAL[i].v > 0) then
            begin
              NLAL_  := MLAL[i].v * (NcLAL[i].v / 100);
              MLAL_s := NLAL_ / (Nccrit_ / 100);
              LAL_s  := MLAL_s * (LAL[i].v / MLAL[i].v);
              PLALR_n := min(LAI.v * 1E4 / plants.v,
                ((LAL[i].v - LAL_s) * 1E4 / plants.v) + PLALR_n);
            end else
              // if layers Nc is zero the layer is senescent
              PLALR_n := (LAL[i].v * 1E4 / plants.v) + PLALR_n;
          end;
        end;
    end;
    *)
  // Leaf senescence due to light limition (APSIM I_Wheat Meinke 1998)
  // ten day running mean of global radiation above canopy(avIcrop)
  for i := 9 downto 1 do
  begin
    Icrop[i + 1] := Icrop[i];
  end;
  Icrop[1] := PAR.v * EXP(-kPAR.v * LAI.v);
  avIcrop.v := 0;
  SUM_I := 0;
  for i := 1 to 10 do
  begin
    SUM_I := SUM_I + Icrop[i];
  end;
  avIcrop.v := SUM_I / 10;
  if (ISTAGE.v >= 2) and (avIcrop.v < Icrit.v) and (EC.v < EC_LGEnd.v) then
  begin
    // calc. shading forced senescence (similar to APSIM I_Wheat Meinke 1998)
    //LAIs = (ln(I)-ln(I0))/-k || I = Icrit
    LAIs := (ln(Icrit.v) - ln(PAR.v)) / -kPAR.v;
    if LAI.v > 0 then
    PLALR_l := max(0,
                     min((((LAI.v - LAIs) / 10) * 1E4) / plants.v,
  // shading only limits net increase of LAI (in contrast to Meinke 1998)
                     pla.c));
 end;
  // Leaf senescence due to water limitation (APSIM I_Wheat Meinke 1998)
  if (fDroughtImpact = UHumeWheatDryMatter.droughtimpact) then
  begin
   // calc. runnig average of TransIntRatio (avTransIntRatio)
     for i := 9 downto 1 do
  begin//Werte Rücken
    avTransIntRatio_arr[i + 1] := avTransIntRatio_arr[i];
  end;
  avTransIntRatio_arr[1] := TransIntRatio.v;
  SUM_avTIR := 0;
  for i := 1 to 10 do
  begin
    SUM_avTIR := SUM_avTIR + avTransIntRatio_arr[i];
  end;
  evenTransIntRatio.v := SUM_avTIR / 10;
    if (TransIntRatio.v < TRcrit.v) and (evenTransIntRatio.v < TRcrit.v)  then
    begin
      gamma := P.v * 0.000662;   // 0.000662 = Psychrometerkonstante [1/øK]  ;
      delta := 239.0 * 17.4 * 6.11 * exp(17.4 * TMPM.v / (TMPM.v + 239.0)) /
        sqr(TMPM.v + 239.0);
      NetBeam := max(0, 0.6494 * (Rad_Int.v) - 18.417);
      LAIs  := S_LAI(TMPM.v, Sat_def.v, NetBeam, delta, gamma, ra.v,
        potTrans.v * evenTransIntRatio.v, LAI.v);

      if LAI.v > 0 then
        PLALR_d := max(0, ((((LAI.v - LAIs) / (15/evenTransIntRatio.v)) * 1E4) / plants.v));
    end;
  end;
  // set plant leaf area lost rate
  if LAI.v > 0 then
    PLALR.v:= min((LAI.v*1E4)/plants.v,max(max(PLALR_a,PLALR_d),max(PLALR_n,PLALR_l)))
  else
    PLALR.v:=0;
  // senescence fraction caused by drought stress
  DSsen.v := max(0,PLALR_d-max(PLALR_a,max(PLALR_n,PLALR_l)));
    // senescence fraction caused by N limitation
  NSen.v := max(0,PLALR_n-max(PLALR_a,max(PLALR_d,PLALR_l)));

  if PLALR.v > 0 then
 // drought stress fraction (relative)
    fdsen.v := dSsen.v / PLALR.v
  else
    fdsen.v := 0;
 // senescence fraction caused by light limitation
  LLsen.v := max(0,PLALR_l-max(PLALR_a,max(PLALR_n,PLALR_d)));
 // now senescence rate for canopy (plant level)
  SENLA.c := PLALR.v;
end;


procedure THumeWheatLeafArea.SetLaiLayers;
var
(*
applying an average plant with four layers (1 = top layer, 4 = bottom layer)
 First leaf growth occurs in layer 1, senescence starts up from layer 4
*)
  i, lastLAL: integer;
  LAIdiff   : real;
  LAI_:real;
begin
  for i := 1 to MaxLeafNumber do
  begin
  end;
   (*
    during vegetative stage, layers are defined by a distribution function
   *)
  if EC.v < 65 then
  begin // distribution is a function of LAI
    LAI_:=max(2,min(6,LAI.v));// limiting to range of measuremants at anthesis
                            // rain-out-shelter exp. HS 103 2010)
    for i := 1 to 4 do
    begin
      // leaf mass and area distribution to single leaf layer as a function of
      // LAI (rain-out-shelter exp. HS 2010)
      if (LFWT_m2.v>0)and (pla.v>0) and (LAI.v>0)then
         begin
         if(i<4) then
          begin
            MLAL[i].v := LFWT_m2.v*(relLayerM_Int[i].v+relLayerM_S[i].v*LAI_);
            LAL[i].v  := LAI.v*(relLayerA_Int[i].v+relLayerA_S[i].v*LAI_);
          end else
           begin
              MLAL[i].v := LFWT_m2.v-MLAL[1].v-MLAL[2].v-MLAL[3].v;
              LAL[i].v  := LAI.v-LAL[1].v-LAL[2].v-LAL[3].v;
           end;
         end else begin
              MLAL[i].v := 0;
              LAL[i].v  := 0;
         end;
    end; // for Schleife zu
  end else
  begin
    (*
    during grain filling the leaf-layer developement
    is ruled by the N dynamic
    *)
    if sumLAL.v > 0 then
    begin
      laidiff := PLALR.v * plants.v * 1e-4;
      if LAI.v <= 0 then
        laidiff := sumLAL.v;
    end else
      laidiff := 0;
    while laidiff > 0 do
    begin
      // find the bottom leaf layer
      lastLAL := -1;
      for i := 4 downto 1 do
      begin
        if (LAL[i].v > 0) then
          if (lastLAL = -1) then
            lastLAL := i;
      end;
      if lastLAL = -1 then
        lastLAL := 1;
      // start senescence from the last leaf layer
      for i := lastLAL downto 1 do
      begin
        if laidiff > 0 then
          if laidiff <= LAL[i].v then
          begin
            MLAL[i].v := max(0, (LAL[i].v - LAIdiff) / LAL[i].v * MLAL[i].v);
            LAL[i].v := LAL[i].v - LAIdiff;
            laidiff := 0;
          end else
          begin
            laidiff  := laidiff - LAL[i].v;
            LAL[i].v := 0;
            MLAL[i].v := 0;
            if lastLAL = 1 then
              laidiff := 0; // to prevent rounding errors
          end;
        if LAL[i].v = 0 then
          lastLAL := max(1, lastLAL - 1);
      end;
    end;
  end;
  sumMLAL.v := 0;
  sumLAL.v  := 0;
  for i := 1 to 4 do
  begin
    sumLAL.v  := sumLAL.v + LAL[i].v;
    sumMLAL.v := sumMLAL.v + MLAL[i].v;
  end;
  if sumMLAL.v>0 then
    avSLA.v:= (sumLAL.v/sumMLAL.v)*1E4
  else
    avSLA.v:=0;
  if ec.v > 65 then
  begin
    Senl.v := (LFWT_m2.v - sumMLAL.v) / plants.v;
  end else
     if avSLA.v > 0 then
      SENL.v := min(LFWT_pl.v,PLALR.v / avSLA.v)
    else
      SENL.v :=0;
      if (sumLAL.v>LAI.v) then
         sumLAL.v:= sumLAL.v;
end;

procedure THumeWheatLeafArea.Init;
var
  i: integer;
begin
  inherited init(GlobMod);
  if optDroughtimpact.option = 'droughtimpact' then fdroughtimpact := UHumeWheatDryMatter.DroughtImpact;
  if optDroughtimpact.option = 'nodroughtimpact' then fdroughtimpact := UHumeWheatDryMatter.noDroughtImpact;
  LAI.v := 0;
  PLA.v := 0;
  for i := 1 to MaxLeafNumber do begin
    PLSC[i].v := 0;
    senratesLA[i] := 0;
    senratesDM[i] := 0;
  end;
  SENLA.v := 0;
  p5_ := 430+P5.v*20; // unscaled value of parameter p5
  LAIs := 0;
  for i := 10 downto 1 do
  begin
    Icrop[i] := 0;
  end;
  if optSenescence.option = 'concentration' then
  begin
    fSenescence := Concentration;
  end;
  if optSenescence.option = 'cwt3' then
  begin
    fSenescence := CWT3;
  end;
    for i := 10 downto 1 do
  begin
    avTransIntRatio_arr[i] := 1;
  end;
  potSLA.v:=0;
end;


procedure THumeWheatLeafArea.CalcRates;
var
  i: integer;
begin
  if Ln_.v > 0 then
    p5_ := 430 + P5.v * 20; // unscaled value of parameter p5
    for i := 1 to MaxLeafNumber do
     begin
      PLSC[i].c := 0.0;
     end;


  if (ISTAGE.v >= 1) and (ISTAGE.v < 3) then
    CUMPH.c := TSumInc.v / PHINT.v       // rate of change of cumulative phyllochron
  else
    CUMPH.c := 0;
  LN_.v := trunc(min(MaxLeafNumber, CUMPH.v + 1)); // leaf number
  sumPLSC.v := 0;
// now calc. leaf growth..
  for i := 1 to trunc(ln_.v) do
  begin
    sumplsc.v := sumPLSC.v + PLSC[i].v;
  end;
  for i := 1 to MaxLeafNumber do
  begin
    if i = trunc(ln_.v) then
    begin
      if LAI.v>0 then
         potSLA.v:= calcpotSLA(LFWT_pl.v*plants.v,GROLF.v*plants.v,
                 ec.v,potSLA.v)
      else
         potSLA.v:= calcpotSLA(LFWT_pl.v*plants.v,GROLF.v*plants.v,
                 ec.v,0);
      if GROLF.v > 0 then
      begin
        PLSCGR[i].v := max(0,
                          (LFWT_pl.v + GROLF.v) * potSLA.v- sumplsc.v
                       );
        PLA.c := PLSCGR[i].v;
      end else
        begin
          PLSCGR[i].v := 0;   // only one leaf is actually growing
          PLA.c := 0;
        end;
    end
    else
      PLSCGR[i].v := 0;
    PLSC[i].c := PLSCGR[i].v;// leaf area change of leaf i(cm2/pl)
  end;
    calcSenescence;
end;

procedure THumeWheatLeafArea.Integrate;
var
  i: integer;
  F: array [1..4] of real;// cummulative leaf area above lamina i
begin
  inherited  integrate;
// for initialisation initial plant leaf area is set to parameter value
  if (ISTAGE.v >= 1) and (pla.v <= 0) and (ISTAGE.v < 3) then
  begin
    PLA.v := LFWT_pl.v*potSLA.v;
    plsc[1].v := LFWT_pl.v*potSLA.v;
  end;
 if(LAI.v>LAImax.v) then
   LAImax.v:=LAI.v;
 // substract senescent leaf tissue from leaf arrays and calc. av. SLA
  setleaf_arr(PLALR.v);
   // Leaf area index as the difference of total and senescent leaf area
  if (pla.v>0) then
    LAI.v := (pla.v-senla.v)*plants.v*1e-4;
  If (ISTAGE.v>=6) and (lai.v>=0) then LAI.v:=0;
  GPLA.v :=  (PLA.v - SENLA.v);
  //the amount of PAR incident on the sureface of lamina i :
  for i := 1 to 4 do
  begin
    case i of
      1: F[i] := 0;
      2: F[i] := LAL[i - 1].v;
      3: F[i] := LAL[i - 1].v + LAL[i - 2].v;
      4: F[i] := LAL[i - 1].v + LAL[i - 2].v + LAL[i - 3].v;
    end;
    PARi[i].v := kPAR.v * (Rad_Int.v * 0.5) * kTransPAR.v * exp(-kPAR.v * F[i]);
  end;
  setLaiLayers;
  GAI.v:=calcGAI(ec.v,LAI.v);

end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [THumeWheatLeafArea]);
end;

end.
