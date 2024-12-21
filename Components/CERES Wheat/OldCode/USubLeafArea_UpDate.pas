unit USubLeafArea_UpDate;

{
okt. 2008 : updating LAI and related values with field measurements (Böttcher, Ratjen)
Juni 2009:  Leaf senescence due to light limition implemented (Ratjen)
Juli 2009:  Leaf senescence due to drought stress implemened (Ratjen)
Nov. 2009:  calculating layerwise LAI  for an average tiller (Ratjen)
Nov. 2009:  distribution of leafs (weight and area) to max. four Leaf layers
Nov. 2009:  Seneszens on singel leaf level (PLSC[i]) during further growth stages corrected to the act. LAI (Ratjen)
Nov. 2009:  The amount of PAR incident on the sureface of different lamina (Ratjen)
Jan. 2010:  optional seneszenz due to N concentration during grain filling phasae (Ratjen)
Jun. 2011: SLA function was replaced, SLA is now assumed as an function of leaf dry matter and BBCH
}
interface

uses
  UMod, UState, Dialogs, SysUtils,
  USubLeafAreaGrowthSimple;

const
  MaxLeafNumber = 25;

type
  TSenescence = (cwt3, concentration);

  TSubLeafArea_UpDate = class(TSubLeafAreaGrowthSimple)
  private
    p5_:         real;
    fSenescence: TSenescence;
    PSIroot_arr: array [1..10] of real;
    avTransIntRatio_arr:  array [1..10] of real;
    procedure SetLaiLayers;
  protected
    function s_LAI(Temp_, Sat_def_, Net_beam_, delta_, gamma_, ra_,
      actTrans_, exLAI: real): real;
    function evenPSIroot(PSIroot_: real): real;
    function calcPotSLA(Wleaf,dWleaf,BBCH,SLA_old: real): real;
    procedure setleaf_arr(PLALR_: real);
  public
    LAI2000:   TState;
    Icrit:     TPAR;
    maxSLA_decay: TPAR;
    b_decay:      TPAR;
    // kritische Einstrahlung im Bestand (Kompensationspunkt Seneszens)
    kTransPAR: TPAR; // PAR transmission coefficient
    critSLN:   TPAR; // APSIM meinke 1998, 107
   // SLA_B:     TPAR;
    P5_2:      TPAR;
    //sum of temperature for calculating leaf senescens during grain filling
    k_SLA:     TPAR;
    TRcrit:    TPAR;
    pLFWT:     TPAR;
    relLayerMInt:   array[1..3] of TPAR;
    relLayerLInt:    array[1..3] of TPAR;
    relLayerMS:   array[1..3] of TPAR;
    relLayerLS:    array[1..3] of TPAR;
    GROLA:     TVAR;
    sumLAL:    TVAR;
    sumMLAL:   TVAR;
    fdsen:     TVAR;

    sumPL_weight: TVAR;
    sumPLsc:      TVAR;
    MLAL:         array[1..4] of TVAR; // green leaf mass of layer
    LAL:          array[1..4] of TVAR;   //  Leaf area of a lamina i
    DSsen:        TVAR;     //Zuwachs  von PLALR auf Grund von Trockstress
    LLsen:        TVAR;     //Zuwachs  von PPLALR auf Grund von Lichtmagel
    potSLA:       TVAR;
    Nccrit:       TVAR;
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
    NStoragepool_pl: TExternV;
    Tiln:     TExternV;
    NcLAL:    array[1..4] of TExternV;
    ra:       TExternV;
    Sat_def:  TExternV;
    P:        TExternV;
    sic:      TExternV;
    int_stor: TExternV;
    rain:     TExternV;
    rc0:      TExternV;
    Ncmob:    TExternV;
    gamma:    real;
    delta:    real;
    LAIs:     real;
    PARi:     array[1..4] of TState;
    //  amount of PAR incident on the surface of lamina i
    optSenescence: TOption;
    procedure UpdateValues; override;

    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
  published
    property Ex_rc0: TExternV Read rc0 Write rc0;
    property Ex_rain: TExternV Read rain Write rain;
    property Ex_sic: TExternV Read sic Write sic;
    property Ex_Sint_stor: TExternV Read int_stor Write int_stor;
    property Ex_P: TExternV Read P Write P;
    property Ex_Sat_def: TExternV Read Sat_def Write Sat_def;
    property Ex_ra: TExternV Read ra Write ra;
    property Ex_Tiln: TExternV Read Tiln Write Tiln;
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

procedure TSubLeafArea_UpDate.setleaf_arr(PLALR_: real);
var
  i, ln_, spos: integer;
  fLWS, sumLA:  real;
begin
  //ln_ herausfinden:
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
  // erstes aktive Blatt finden:
  spos := -1;
  for i := 1 to ln_ do
  begin
    if (PLSC[i].v > 0) then
    begin
      if (spos = -1) then
        spos := i;
    end else
      PL_weight[i].v := 0;
  end;
  // Blattfläche anpassen
  PLALR_ := min(PLALR_, sumla);
  while (PLALR_ > 0) do
  begin
    if PLALR_ < PLSC[spos].v then
    begin
      fLWS := (PLSC[spos].v - PLALR_) / PLSC[spos].v;
      PLALR_ := 0;
      PLSC[spos].v := PLSC[spos].v * fLWS;
      PL_weight[spos].v := PL_weight[spos].v * fLWS;

    end else
    begin
      PLALR_ := PLALR_ - PLSC[spos].v;
      PLSC[spos].v := 0;
      PL_weight[spos].v := 0;
    end;
    if (PLALR_ > 0) and (spos < ln_) then
      spos := spos + 1
    else
    if (spos = ln_) then
      PLALR_ := 0; // to prevent rounding errors;
  end;
end;

function TSubLeafArea_UpDate.evenPSIroot(PSIroot_: real): real;
var
  i, cast: integer;
  sumPSI:  real;
begin
  cast := 0;
  sumPSI := 0;
  for i := 9 downto 1 do
  begin//Werte Rücken
    if PSIroot_arr[i] > 0 then
      cast := min(10, cast + 1);
    PSIroot_arr[i + 1] := PSIroot_arr[i];
  end;
  PSIroot_arr[1] := PSIroot_;
  if PSIroot_ > 0 then
    cast := min(10, cast + 1);
  for i := 1 to 10 do
  begin
    sumPSI := sumPSI + PSIroot_arr[i];
  end;

  if cast > 0 then
    evenPSIroot := sumPSI / cast
  else
    evenPSIroot := 0;
end;

function TSubLeafArea_UpDate.calcPotSLA(Wleaf,dWleaf,BBCH,SLA_old: real): real;
const
//SLA vs. LAI BBCH >31
 a = 136.69; //Intercept
 b = 14.93;  // Slope

 ftillering = 1.2; // increase factor during tilleríng
 SLA_B = 300; //start SLA of juvenescent leafs (APSIM, Asseng 2003)
 decay_a= 0.329677; //smooth decrease during leaf growth,
 decay_b = -3; //according to Asseng 2003
var
 max_Decay, SLA_g,dSLAp,dSLA_,w,LAI_: real; // max. decrease of SLA
begin
     if (SLA_old=0) and (bbch<30) then
        SLA_g:=SLA_B //initialise with high SLA of juvenile leafs
        else begin
          w:=(Wleaf+dWleaf)*1E-4; //g->10kg
     // SLA as a funktion of shading during stem elongation
          if Wleaf>0 then
            begin
              SLA_g:= -a/(b*w-1);
     // is enhanced during tillering
            if BBCH <31 then
              SLA_g:= SLA_g*ftillering;
              // smoothing the decrease of SLA during leaf growth
          if  (SLA_g<SLA_old) then
            begin
              dSLAp:= SLA_g-SLA_old; // pot. change
              // alteration is weighted by leaf weight change
              dSLA_:= dSLAp*(abs(dWleaf)/Wleaf)*decay_a;
              // smoothing is decreasing when LAI is raising and shading becomes more important
              LAI_:= w*1E-4*SLA_old;
              SLA_g:= SLA_old+dSLAp+(dSLA_-dSLAp)*exp(LAI_*decay_b);
            end;
          end;
     end;
       calcPotSLA:= SLA_g;
end;



function TSubLeafArea_UpDate.s_LAI(Temp_, Sat_def_, Net_beam_, delta_,
  gamma_, ra_, actTrans_, exLAI: real): real;

const
  cp = 1005.0;      { spezifische Wärme der Luft [J/(Kg*K)] }
var
  pETP_, ro, int_stor_: real;
  max_int_cap,             { maximale Interzeptionskapazit„t [mm] }
  int_cap,                  { aktuelle Interzeptionskapazit„t [mm]  }
  Pot_Evapo_, pot_trans_, delta2, //Iterationsschrittweite
  a, F, exLAI_, b, // Steigung (Ableitung)
  rc, actTransInt, potTransInt, PTI, Interzeption_: real;
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
    if (ExLAI = LAI.v) then // erster Schritt
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
    f := potTransInt*TRcrit.v - actTransInt;    // TRcrit wird angestrebt..
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

procedure TSubLeafArea_UpDate.CreateAll;
var
  i: integer;
begin
  inherited createAll;
  ParCreate('Icrit', '[MJ/(m2*d)]', 0.8, Icrit);
  ParCreate('maxSLA_decay', '[-]', -0.0535, maxSLA_decay);
  ParCreate('b_decay', '[-]', 0, b_decay);
  ParCreate('kTransPAR', '[-]', 0.7, kTransPAR);
  ParCreate('critSLN', '[-]', 1.32, critSLN, 'critical SLN value for leave senescense');
  ParCreate('TRCrit', '[-]', 0.8, TRCrit);
//  ParCreate('SLA_b', '[m2/m2]', 250, SLA_b, 'SLA at the beginning of leaf growth');
  ParCreate('k_sla', '[-]', 0.72, k_sla);
  ParCreate('PLFWT', '[-]', 13, PLFWT);
  ParCreate('P5_2', '[°Cd]', 630, P5_2);

  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerLInt' + IntToStr(i), '[-]', 0.249, relLayerLInt[i]);
    if i = 2 then
      ParCreate('relLayerLInt' + IntToStr(i), '[-]',  0.174, relLayerLInt[i]);
    if i = 3 then
      ParCreate('relLayerLInt' + IntToStr(i), '[-]', 0.321, relLayerLInt[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerLS' + IntToStr(i), '[-]', 0.002, relLayerLS[i]);
    if i = 2 then
      ParCreate('relLayerLS' + IntToStr(i), '[-]', 0.037, relLayerLS[i]);
    if i = 3 then
      ParCreate('relLayerLS' + IntToStr(i), '[-]',  -0.010, relLayerLS[i]);
  end;

    for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerMInt' + IntToStr(i), '[-]', 0.246, relLayerMInt[i]);
    if i = 2 then
      ParCreate('relLayerMInt' + IntToStr(i), '[-]', 0.196, relLayerMInt[i]);
    if i = 3 then
      ParCreate('relLayerMInt' + IntToStr(i), '[-]', 0.32, relLayerMInt[i]);
  end;
  for i := 1 to 3 do
  begin
    if i = 1 then
      ParCreate('relLayerMS' + IntToStr(i), '[-]', 0.007, relLayerMS[i]);
    if i = 2 then
      ParCreate('relLayerMS' + IntToStr(i), '[-]', 0.033, relLayerMS[i]);
    if i = 3 then
      ParCreate('relLayerMS' + IntToStr(i), '[-]',  -0.012, relLayerMS[i]);
  end;

  StateCreate('LAI2000', '[m2/m2]', 0, True, LAI2000);
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    VARCreate('MLAL' + IntToStr(i), '[g/m2]', 0, True, MLAL[i]);
  end;
    for i := 1 to 4 do
  begin  // Vier Blattetagen
    VARCreate('LAL_' + IntToStr(i), '[m2/m2]', 0, True, LAL[i]);
  end;
  VarCreate('potSLA', '[cm2/g]', 0, False, potSLA);
  VarCreate('evenTransIntRatio', '[-]', 1, False, evenTransIntRatio, 'mean of 10 days TransintRatio');
  VarCreate('sumpl_weight', '[g/pl]', 0, False, sumpl_weight);
  VarCreate('sumplsc', '[cm2/pl]', 0, False, sumplsc);
  VarCreate('sumLAL', '[m2/m2]', 0, False, sumLAL);
  VarCreate('sumMLAL', '[g/m2]', 0, False, sumMLAL);
  VarCreate('Nccrit', '[%]', 0, False, Nccrit);
  VarCreate('DSsen', 'cm2/(plant*d)', 0, False, DSsen);
  VarCreate('LLsen', 'cm2/(plant*d)', 0, False, LLsen);
  VarCreate('fdsen', '[]', 0, False, fdsen);

  ExternVcreate('Ncmob', '[-]', stateField, Ncmob);
  ExternVcreate('EC_lgend', '[-]', stateField, EC_lgend);
  ExternVcreate('NStoragepool_pl', '[g/plant]', stateField, NStoragepool_pl);
  ExternVcreate('LFWT_m2', '[g/m2]', stateField, LFWT_m2);
  ExternVcreate('LFWT_pl', '[g/pl]', stateField, LFWT_pl);
  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans);
  ExternVcreate('ActTrans', '[mm.d-1]', stateField, ActTrans);
  ExternVcreate('interzeption', '[-]', stateField, interzeption);
  ExternVCreate('GlobRad', '[W.m-2]', StateField, GlobRad);
  // Nettostrahlung [W.m-2]
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
  ExternVCreate('Tiln', '[-]', statefield, Tiln);
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    ExternVCreate('NcLAL__' + IntToStr(i), '[%]', statefield, NcLAL[i]);
  end;
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    StateCreate('PARi' + IntToStr(i), '[W/m2]', 0, True, PARi[i]);
  end;

  OptCreate('optSenescence', 'CWT3', optSenescence);
  optSenescence.OptionList.Clear;
  optSenescence.OptionList.Add('CWT3');
  optSenescence.OptionList.Add('Concentration');
end;

procedure TSubLeafArea_UpDate.SetLaiLayers;
var
{ applying an average plant with four layers (1 = top layer, 4 = bottom layer)
 First leaf growth occurs in layer 1, seneszens starts up from layer 4}
  i, lastLAL: integer;
  fLWS: real; // fraktor for leaf weight shrinkage
  a,  senl_, MLAL_: real;
  LAIdiff: real;
begin
  senl_ := 0;
  sumPL_weight.v := 0;
  for i := 1 to MaxLeafNumber do
  begin
    sumPL_weight.v := sumPL_weight.v + PL_weight[i].v;
  end;
  // before grain filling
  if EC.v < 65 then
  begin
    for i := 1 to 4 do
    begin
      // leaf mass and area distribution to single leaf layer as a function of LAI (rain-out-shelter exp. HS 2010)
      if (LFWT_m2.v>0)and (pla.v>0) and (LAI.v>0)then
       if(i<4) then begin
        MLAL[i].v := LFWT_m2.v*(relLayerMInt[i].v+relLayerMS[i].v*LAI.v);
        LAL[i].v  := LAI.v*(relLayerLInt[i].v+relLayerLS[i].v*LAI.v);
       end else
         begin
            MLAL[i].v := LFWT_m2.v-MLAL[1].v-MLAL[2].v-MLAL[3].v;
            LAL[i].v  := LAI.v-LAL[1].v-LAL[2].v-LAL[3].v;
         end;
      end;
  end else
  begin
    // during grain filling
    // update layers due to senescence
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
            MLAL_ := MLAL[i].v;
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
  if ec.v > 65 then
  begin
    Senl.v := (LFWT_m2.v - sumMLAL.v) / plants.v;
  end;

end;

procedure TSubLeafArea_UpDate.Init;
var
  i: integer;
begin
  inherited;
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
    PSIroot_arr[i] := 0;
  end;

    for i := 10 downto 1 do
  begin
    avTransIntRatio_arr[i] := 1;
  end;
  potSLA.v:=0;
end;


procedure TSubLeafArea_UpDate.CalcRates;
var
  NetBeam: real;
  i: integer;
  SUM_I, MLAL_s, LAL_s, NLAL_,SUM_avTIR: real;
begin
  // **********************************************************
  if Ln_.v > 0 then
    p5_ := 430 + P5.v * 20; // unscaled value of parameter p5
    for i := 1 to MaxLeafNumber do
     begin
      PLSC[i].c := 0.0;
      PL_weight[i].c := 0.0;
     end;
  if round(ISTAGE.v) = 5 then
    SUMDTT5.c := TMPM.v  {TempSum in iStage 5}
  else
    SUMDTT5.c := 0;
 { if (IStage.v >= 2) and (fDroughtImpact = droughtimpact) then
  begin
    potSLA.v := a_pf.v + b_pf.v * max(2.12, evenPSIroot(PSIroot.v));
  end
  else
    potSLA.v := SLAconst.v;
  if (LFWT_m2.v <= pLFWT.v) and (EC.v < 30) then
    // during early leaf growth the SLA is increased in juvenescent leafs
    //APSIM (Asseng 2003) SLA_B = 300 ; SLAconst = 225
    actSLA.v := potSLA.v + (SLA_B.v - potSLA.v) * exp(-2 * xstage.v - 1)
  else
    actSLA.v := potSLA.v;
 } 
  EGFT.v := max(0, min(1, 1.2 - 0.0042 * sqr(TMPM.v - 17)));  // temperature factor
  if (ISTAGE.v >= 1) and (ISTAGE.v < 3) then
    CUMPH.c := TSumInc.v / PHINT.v       // rate of change of cumulative phyllochron
  else
    CUMPH.c := 0;
  LN_.v := trunc(min(MaxLeafNumber, CUMPH.v + 1)); // leaf number
  PLAGMS.v := CLG.v * sqrt(CUMPH.v) * MIN(SWDF1.v, min(EGFT.v, 1{ndef2.v})) * TI.v;
  PLALR.v  := 0;
  if (round(ISTAGE.v) >= 1) and (round(ISTAGE.v) <= 2) and (CUMPH.v > 4) and
    (ec.v < 30) then // senecence only until EC 30, changed ..
  begin
    if senratesLA[trunc(LN_.v) - 4] = 0 then
    begin
      senratesLA[trunc(LN_.v) - 4] := (PLSC[trunc(LN_.v) - 4].v);
      // the fifth oldest leaf is deceasing
      senratesDM[trunc(LN_.v) - 4] := (PL_weight[trunc(LN_.v) - 4].v);
      // the fifth oldest leaf is deceasing
    end;
    PLALR.v := min(PLSC[trunc(LN_.v) - 4].v / globtime.c,
      senratesLA[trunc(LN_.v) - 4] * TSumInc.v / PhInt.v);
    SENL.v  := min(PL_weight[trunc(LN_.v) - 4].v / globtime.c,
      senratesDM[trunc(LN_.v) - 4] * TSumInc.v / PhInt.v);

   { PLSC[trunc(LN_.v) - 4].c := -1 * min(PLSC[trunc(LN_.v) - 4].v / globtime.c, PLALR.v);
    PL_weight[trunc(LN_.v) - 4].c :=
      -1 * min(PL_weight[trunc(LN_.v) - 4].v / globtime.c, SENL.v); }

    if (ln_.v > 5) and (PLSC[trunc(LN_.v) - 5].v > 0.0) then
    begin
      PLALR.v := PLALR.v + PLSC[trunc(LN_.v) - 5].v / globtime.c;
      SENL.v  := SENL.v + PL_weight[trunc(LN_.v) - 5].v / globtime.c;

    {if (ln_.v>5)and (PLSC[trunc(LN_.v)-5].v > 0.0)  then begin
       PLSC[trunc(LN_.v)-5].c :=  -PLSC[trunc(LN_.v)-5].v/globtime.c;
       PLALR.v := PLALR.v - PLSC[trunc(LN_.v)-5].c;
       PL_weight[trunc(LN_.v)-5].c :=  -PL_weight[trunc(LN_.v)-5].v/globtime.c;
       SENL.v := SENL.v - PL_weight[trunc(LN_.v)-5].c;
     end;}
    end;
    setleaf_arr(PLALR.v);
  end else
  begin
    if (round(ISTAGE.v) = 1) and (pla.v > 0) and (SENLA.v / pla.v > 0.4) and
      (LAI.v < 6.0) then
      PLALR.v := 0
    else if (ISTAGE.v >= 2) and (ISTAGE.v < 4) then
    begin
      PLALR.v := PSENLeaf1.v * TSumInc.v * GPLA.v;
      setleaf_arr(PLALR.v);
    end
    else if (ISTAGE.v >= 4) and (ISTAGE.v < 5) then
    begin
      PLALR.v := PSENLeaf2.v * TSumInc.v * GPLA.v;
      setleaf_arr(PLALR.v);
    end
    else
    if (ISTAGE.v >= 5) {and (ISTAGE.v < 6)} then
    begin
      if fSenescence = Concentration then
      begin
        PLALR.v := 0;
        if (pla.v - (senla.v + senla.c) > 0) and (LAL[1].v <= 0) then
          LAL[1].v := 0;
        for i := 4 downto 1 do
        begin
          if LAL[i].v > 0 then
            Nccrit.v := (critSLN.v * (LAL[i].v / MLAL[i].v)) * 100
          else
            Nccrit.v := 0;

          if (NcLAL[i].v < Nccrit.v) and (LAL[i].v > 0) then
          begin
            if (NcLAL[i].v > 0) then
            begin
              NLAL_  := MLAL[i].v * (NcLAL[i].v / 100);
              MLAL_s := NLAL_ / (Nccrit.v / 100);
              LAL_s  := MLAL_s * (LAL[i].v / MLAL[i].v);
              PLALR.v := min(LAI.v * 1E4 / plants.v,
                ((LAL[i].v - LAL_s) * 1E4 / plants.v) + PLALR.v);
            end else
              // if layers Nc is zero the layer is senescent
              PLALR.v := (LAL[i].v * 1E4 / plants.v) + PLALR.v;
          end;
        end;
        // all layers are senescent at the end of grain filling
        if ISTAGE.v = 6 then
          PLALR.v := pla.v - senla.v;
      end;
      if fSenescence = CWT3 then
      begin
        //   PLALR.v := GPLA.v * 2 * SUMDTT5.v * TSumInc.v / (P5_ * P5_);
        PLALR.v := (LAI.v / plants.v) * 2 * SUMDTT5.v * TSumInc.v / (P5_2.v * P5_2.v);
        setleaf_arr(PLALR.v);
      end;
    end else
      PLALR.v := 0;
    if AvSLA.v > 0 then
      SENL.v := PLALR.v / AvSLA.v;
  end;

  sumPLSC.v := 0;
  sumPL_weight.v := 0;
  for i := 1 to trunc(ln_.v) do
  begin
    sumPL_weight.v := sumPL_weight.v + PL_weight[i].v;
    sumplsc.v := sumPLSC.v + PLSC[i].v;
  end;

  for i := 1 to MaxLeafNumber do
  begin
    if i = trunc(ln_.v) then
    begin
      if LAI.v>0 then
         potSLA.v:= calcpotSLA(sumPL_weight.v*plants.v,GROLF.v*plants.v,
                 ec.v,potSLA.v)
      else
         potSLA.v:= calcpotSLA(sumPL_weight.v*plants.v,GROLF.v*plants.v,
                 ec.v,0);


      if GROLF.v > 0 then
        PLSCGR[i].v := max(0, (sumPL_weight.v + GROLF.v) *
                       potSLA.v- sumplsc.v)
      else
        PLSCGR[i].v := 0;   // only one leaf is actually growing
      PL_weight[i].c := GROLF.v;         // only one leaf is actually growing
    end
    else
    begin
      PLSCGR[i].v := 0;
      if i > trunc(ln_.v) - 2 then
        PL_weight[i].c := 0;   // only one leaf is actually growing
    end;
    PLSC[i].c := PLSC[i].c + plscgr[i].v;    // leaf area change of leaf  i  (cm2/pl)
  end;
  if GROLF.v > 0 then
    PLA.c := max(0, (sumPL_weight.v + GROLF.v) * potSLA.v - sumplsc.v)
  else
    PLA.c := 0;   // growth rate of leaf area per plant


  SENLA.c := PLALR.v;      //   rate of change of senescent leaf area per plant (cm2/pl)


  if EC.v < 30 then
    LAIStem.c := SSA1.v * GROSTM.v * PLANTS.v / 10000
  else
    LAIStem.c := SSA2.v * GROSTM.v * PLANTS.v / 10000;
  // **********************************************************VEGNEW ENDE
  // Leaf senescence due to light limition (APSIM I_Wheat Meinke 1998)
  // Mittlere Einstrahlung im Bestand (avIcrop) der letzten 10 Tage berechnen

  for i := 9 downto 1 do
  begin//Werte Rücken
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
    // Seneszens setzen
    //LAIs = (ln(I)-ln(I0))/-k || I = Icrit
    LAIs := (ln(Icrit.v) - ln(PAR.v)) / -kPAR.v;
    if (((((LAI.v - LAIs) / 10) * 10000) / plants.v) > PLALR.v) then
    begin
      LLsen.v := ((((LAI.v - LAIs) / 10) * 1E4) / plants.v) - PLALR.v;
      // no negative growth is caused by Llsen
      LLsen.v := max(0, min(LLSen.v, (pla.c - PLALR.v)));
      if LAI.v > 0 then
        PLALR.v := LLsen.v + PLALR.v
      else
        PLALR.v := 0;
      if AvSLA.v > 0 then
        SENL.v := PLALR.v / AvSLA.v;
    end;
    //    if LLsen.v>0 then setleaf_arr(LLsen.v);
  end else
    LLsen.v := 0;
  // Leaf senescence due to water limitation (APSIM I_Wheat Meinke 1998)
  if (fDroughtImpact = droughtimpact) then
  begin
   // calc. avTransIntRatio
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
      gamma := P.v * 0.000662;
      // 0.000662 = Psychrometerkonstante [1/øK]  ;
      delta := 239.0 * 17.4 * 6.11 * exp(17.4 * TMPM.v / (TMPM.v + 239.0)) /
        sqr(TMPM.v + 239.0);
      NetBeam := max(0, 0.6494 * (Rad_Int.v) - 18.417);
      LAIs  := S_LAI(TMPM.v, Sat_def.v, NetBeam, delta, gamma, ra.v,
        potTrans.v * evenTransIntRatio.v, LAI.v);
      if ((((LAI.v - LAIs) {/10}) * 10000) / plants.v) > PLALR.v then
      begin
        DSsen.v := max(0, ((((LAI.v - LAIs) / 10) * 10000) / plants.v) - PLALR.v);
        // DSsen ist nur der Teil, welcher durch TS verursacht wurde..
        if DSsen.v > 0 then
          setleaf_arr(DSsen.v);
        PLALR.v := DSsen.v + PLALR.v;
        if AvSLA.v > 0 then
          SENL.v := PLALR.v / AvSLA.v;
      end else
        DSsen.v := 0;
    end else
      DSsen.v := 0;
  end;
  if PLALR.v > 0 then
    fdsen.v := dSsen.v / PLALR.v
  else
    fdsen.v := 0; // this is the fraction of senescent leaf area caused by drought stress
  // if PLALR.v>=0 then
  //  setleaf_arr(PLALR.v)
  //  else
  //    PLALR.v:=0;
  SENLA.c := PLALR.v;

 {// optional lineare Seneszenz während der Kornfüllungsphase...
 If (fSenescence  = Linear ) and (ISTAGE.v>=5) and (ISTAGE.v<6) then begin
  PLALR.v :=   GPLA.v-max(0,(GPLA.v*(((p5.v+21.5)/0.05)-SUMDTT5.v)/((p5.v+21.5)/0.05)));
  if AvSLA.v > 0 then SENL.v := PLALR.v / AvSLA.v;
  SENLA.c :=  PLALR.v;      //   rate of change of senescent leaf area per plant (cm2/pl)
 end;
     LAI2000.c:=0;
     LAI2000_v.c:=0;
 }

end;

procedure TSubLeafArea_UpDate.Integrate;
var
  i: integer;
  F: array [1..4] of real;// cummulative leaf area above lamina i
  sumLA, sumDM: real;
begin

  if (ISTAGE.v >= 1) and (lai.v <= 0) and (ISTAGE.v < 3) then
  begin   // for initialisation
    PLA.v := PLAini.v;   // initial plant leaf area set to parameter value
    plsc[1].v := PLAini.v;
  //pl_weight[1].v := PLAini.v / actSLA.v;
    pl_weight[1].v := PLAini.v / potSLA.v;
  end;

  inherited  integrate;

  //The amount of PAR incident on the sureface of lamina i :
  for i := 1 to 4 do
  begin
    case i of   // Blattfläche über layer i ausrechnen
      1: F[i] := 0;
      2: F[i] := LAL[i - 1].v;
      3: F[i] := LAL[i - 1].v + LAL[i - 2].v;
      4: F[i] := LAL[i - 1].v + LAL[i - 2].v + LAL[i - 3].v;
    end;
    //The amount of PAR incident on the sureface of lamina i :
    PARi[i].v := kPAR.v * (Rad_Int.v * 0.5) * kTransPAR.v * exp(-kPAR.v * F[i]);
  end;
  setLaiLayers;
 {
  if LFWT_m2.v>0 then
    avSLA.v := potSLA.v
  else
    avSLA.v := 0.0;
  }
end;

procedure TSubLeafArea_UpDate.UpdateValues;
var
  fLAI: real;
 {LAIStem_val: real;
 GAI_varianz: real;
 LAI_err: real;
 GAI_: real;
 sLAI_V : boolean;
 SD_LAI: real; //Gewichtung des Messwerts}
begin
  inherited;
  if (UpdateValue(LAI2000.Name) <> 0) and (LAI.v > 0) then
  begin
    fLAI := max(0.9, min(1.1, (UpdateValue(LAI2000.Name) {* 0.957}) / LAI.v));
    plants.f_v^ := Round(Plants.v * fLAI);

    {LAI2000.c:= LAI2000.c + UpdateValue(LAI2000.Name)-(LAI2000.v+LAI2000.c);
        GAI_:= (LAI2000.v+LAI2000.c);
        LAI_err:= GAI_*0.957;   //GAI in LAI
        // SD setzen oder berechnen
        if UpdateValue(LAI2000_v.Name)<> 0 then begin   // Hier ist LAI und SD in der UpDatedatei gegeben...
          LAI2000_v.c:= LAI2000_v.c + UpdateValue(LAI2000_v.Name)-(LAI2000_v.v+LAI2000_v.c);
          GAI_Varianz:= LAI2000_v.v+LAI2000_v.c; //
         // sLAI_V:=true;
         // SD_LAI:= max(1,min(0.1,power(GAI_Varianz,(1/2))/(LAI2000.c+LAI2000.v))); //SD 0-1
         //    SD_LAI:= power(GAI_Varianz,(1/2))/(LAI2000.c+LAI2000.v);
          end; // else SD_LAI:= 0.5;
        //Raten aktualisieren:
        //wtGAI.v:= max(0,1-SD_LAI);
        wtGAI.v:=1;    //provisorisch Gewichtung immer auf eins setzen...
        LAIStem_val:= GAI.v-LAI.v;
        LAI_val:= LAI.v*(1-wtGAI.v)+LAI_err*wtGAI.v;
        sLAI:=true;
        fLAI.v:= (LAI_val/LAI.v);
        senla.c:= (senla.v*fLAI.v)-senla.v;
        PLA_val:= (LAI_val/Plants.v)*10000+senla.v+senla.c; //m2->cm2
        GAI.v:= GAI.v*(1-wtGAI.v)+GAI_*wtGAI.v; //keine Rate
        LAIStem.c:=  LAIStem_val-LAIStem.v;
          if sLAI= true then begin
           PLA.c:=  PLA_val-PLA.v;
           sLAI:= false;
         end;
    end else sLAI:= false;
    }end;
end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubLeafArea_UpDate]);
end;

end.
