unit USubPartitioning_UpDate;

{
sep. 2008 : grain filling with carbon hydrates according to Ceres Wheat 3 (Ratjen)
okt. 2008 : updating of state variables related from updated LAI values (measurments) (Ratjen)
dez. 2008 : modifications kernel fill algorithm according to Moreno~ and Weiss 2003 (Ratjen)
march 2009 : calculation of straw drymatter, straw N and total shoot drymatter (TSDM_m2) implemented (Ratjen)
march 2009 : calculation of NNI implemened (Ratjen)
march 2009 : calculation of Q45 according to Demontes et al. (2001) implemened (Ratjen)
march 2009 : new GPSM algorithem implemented (Ratjen)
juli 2009 : potHI approach according to APSIM I_Wheat (Meinke 1997) implemented (Ratjen)
juli 2009 : modification for determining SWMIN as a dynamic function of potHI implemented (Ratjen)
Jan. 2010 : N distribution during grain-filling (Ratjen)
Aug. 2010 : grain filling with carbon hydrates simplified
Feb. 2011 : potHi is modified due to phototermal quotient BBCH 50-75 (QHI)
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UState, USubPartitioningVegNew, UAbstractPlant;

type
  TRSWT = (gf_cwt3, gf_pothi);

  TSubPartitioning_UpDate = class(TSubPartitioningVegNew)

  private
    fRSWT:        TRSWT;
    dNSP_l:       real;   // change rate of N-storage pool leaf
    dNSP_s:       real;   // change rate of N-storage pool stem
    NLStruc_m2:   real;
    PAR_arr:      array [1..45] of real; // CumPAR for Q45
    MTEMP_arr:    array [1..45] of real; // CumMTemp for Q45
    ProzN, critN: real;
    Nph_c:        real; //Änderungsrate an Blatt N
    NDeg:         real;
    NSyn:         real;
    relNC_:     real;
    Np2, nc_:     real;

    // procedure SetUpDateValue;
  protected

  public

    RND:       TPAR;
    psi_crit:  TPAR;
    psi_s:     TPAR;
    RNS:       TPAR;
    K1:        TPAR;
    K2:        TPAR;
    pHI1:      TPAR;
    pHI2:      TPAR;
    rgr_GrainN: TPar;
    GM4:        TPAR;
    relNC:        array[1..4] of TPAR;
    iniGRNWT:  TPAR;
    dECDP:     TPAR; // duration of endosperm cell devision phase
    HImin:     TPAR;
    pRGFILL:   TPar;
    NNI:       TVar;
    NStemstruc_pl: TVAR;
    NNI60:     TVar;
    NSP_l:     TVar;
    NSP_S:     TVar;
    sumNLAL:   TVAR;
    GN_NRate:  TVar;
    SUMDTTGF:  TVar;
    NGrain_pl: TState;
    GRNWT_pl:  TState;   // Weight of grains [g/plant]
    NLphot_pl: TVAR;
    Nmob_m2:   TVar;        // N available in the common pool (J. Bertheloot et al. 2008)
    TSDM_m2:   TVAR;        //Total Shoot drymatter (incl. Stroh)

    Q45:       TVAR;
    NUPRate:   TVAR;
    GPPVAR:    TVAR;
    relTM_L1:  TVAR;
    relTM_L2:  TVAR;
    relTM_L3:  TVAR;
    relTM_L4:  TVAR;
    relBF_L1:  TVAR;
    relBF_L2:  TVAR;
    relBF_L3:  TVAR;
    relBF_L4:  TVAR;
    GPP:       TVAR;
    NcStruc:   TVAR;
    NcStem_ECLGE: TVAR;
    NHI:       TVAR;
    fracAP:    TVAR;
    RGFILL:    TVar; //Rate of grain fill - [mg/(Plant*day)]
    TKM:       TVar;
    NLStruc_pl: TVar;
    NcStraw:   TVar;
    NGrain_m2: TVar;
    Ncmob:     TVAR; // calculated mobile N concentration
    potGrainN_pl: TState;
    potGROGRN: TVar;
    GPSM:      TVar; //Körner pro m2 [n]
    GROGRN:    TVAR; //Daily growth of the grain  [g/(Plant*day)]
    GRYD:      TVAR; //Ertrag [dt/ha]
    HI:        TVAR;
    potHI:     TVAR;
    NcGrain:   TVAR;
    pINIGN:    TPAR; // initial grain N per grain
    ProtGrain: TVAR;
    GRNWT_m2:  TVAR;
    KernelN:   TVAR;
    SLN:       TVAR;
    R:         TVAR;
    QHI: TExternV;
    fdsen:     TExternV;
    TransIntRatio: TExternV;

    PSIroot:      TExternV;
    SumDTT5:      TExternV;
    sumpl_weight: TExternV;
    P5:           TExternV;
    Rad_Int:      TExternV;
    kPAR:         TExternV;
    TILN:         TExternV;
    SumMLAL:      TExternV;
    SumLAL:       TExternV;
    LAL:          array[1..4] of TExternV;
    NcLAL:        array[1..4] of TVAR;
    NLeaf_struc:  array[1..4] of TVAR;
    PARi:         array[1..4] of TExternV;
    MLAL:         array[1..4] of TExternV; // green leaf mass of layer
    NphLeaf:      array[1..4] of TVar;   //  photosynthetic N in lamina i
    //Varianz der Einzelmesswerte LAI2000 Messwerte aus Updatemethode von TSubModel
    optRSWT:      TOption;
    avSLA:        TExternV;

    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure CalcNNI;
    procedure CalcQ45;
    procedure CalcGPSM;
    procedure GRFILL;
    procedure CalcNRates;
    procedure Allometric_Leaf_Stem_Partitioning; override;
    procedure calc_rootDM; override;
  published

    property Ex_avSLA: TExternV Read avSLA Write avSLA;
    property Ex_PSIroot: TExternV Read PSIroot Write PSIroot;
    property Ex_SumMLAL: TExternV Read SumMLAL Write SumMLAL;
    property Ex_SumLAL: TExternV Read SumLAL Write SumLAL;
    property Ex_TILN: TExternV Read TILN Write TILN;
    property Ex_kPAR: TExternV Read kPAR Write kPAR;
    property Ex_Rad_Int: TExternV Read Rad_Int Write Rad_Int;
    property Ex_P5: TExternV Read P5 Write P5;
    property Ex_SumDTT5: TExternV Read SumDTT5 Write SumDTT5;

  end;

procedure Register;

implementation

uses Math;

procedure Tsubpartitioning_UpDate.createAll;
var
  i: integer;

begin
  inherited createAll;
  VarCreate('GPPVAR', '[grains/plant]', 0, True,
    GPPVAR, 'estimation of grains per plant');
  VarCreate('NSP_l', '[]', 0, True, NSP_l, 'N storage pool leaf');
  VarCreate('NSP_s', '[]', 0, True, NSP_s);
  VarCreate('NcStraw', '[]', 0, True, NcStraw);
  VarCreate('relTM_L1', '[]', 0, True, relTM_L1);
  VarCreate('relTM_L2', '[]', 0, True, relTM_L2);
  VarCreate('relTM_L3', '[]', 0, True, relTM_L3);
  VarCreate('relTM_L4', '[]', 0, True, relTM_L4);
  VarCreate('relBF_L1', '[]', 0, True, relBF_L1);
  VarCreate('relBF_L2', '[]', 0, True, relBF_L2);
  VarCreate('relBF_L3', '[]', 0, True, relBF_L3);
  VarCreate('relBF_L4', '[]', 0, True, relBF_L4);
  VarCreate('SLN', '[g/m2]', 0, True, SLN, 'over all specific leaf nitrogen');
  VarCreate('Ncmob', '[]', 0, True, Ncmob);
  VarCreate('TKM', '[g/kKernel]', 0, True, TKM);
  VarCreate('RGFILL', '[mg/(Plant*day)]', 0, True, RGFILL);
  VarCreate('R', '[-]', 0, True, R, 'Ratio mobileN /photN');
  VarCreate('potGROGRN', '[g/(Plant*day)]', 0, True, potGROGRN);

  VarCreate('Q45', '[-]', 0, True, Q45);
  VarCreate('GROGRN', '[g/(plant*d)]', 0, True, GROGRN);
  VarCreate('GRYD', '[dt/ha]', 0, True, GRYD);
  VarCreate('GPSM', '[k/m2]', 0, True, GPSM);
  VarCreate('NNI', '[-]', 0, True, NNI);
  VarCreate('NStemstruc_pl', '[g/plant]', 0, True, NStemstruc_pl);
  VarCreate('NNI60', '[-]', 0, True, NNI60);
  VarCreate('fracAP', '[-]', 0, True, fracAP);
  VarCreate('TSDM_m2', '[g/m2]', 0, True, TSDM_m2);
  VarCreate('GRNWT_m2', '[g/m2]', 0, True, GRNWT_m2);
  VarCreate('HI', '[-]', 0, True, HI);
  VarCreate('potHI', '[-]', 0, True, potHI);
  VarCreate('NGrain_m2', '[g/m2]', 0, True, NGrain_m2);
  VarCreate('NcGrain', '[%]', 0, True, NcGrain);
  VarCreate('ProtGrain', '[%]', 0, True, ProtGrain);
  VarCreate('KernelN', '[kg/ha]', 0, True, KernelN);
  VarCreate('NHI', '[-]', 0, True, NHI);
  VarCreate('NLStruc_pl', '[g/plant]', 0, True, NLStruc_pl);
  VarCreate('NcStem_ECLGE', '[g/plant]', 0, True, NcStem_ECLGE);
  VarCreate('NupRate', '[g/m2]', 0, True, NupRate, 'daily N-uptake rate');
  VarCreate('GN_NRate', '[g/plant]', 0, True, GN_NRate,
    'linear N uptake after endosperm cell division phase');
  VarCreate('GPP', '[grains/plant]', 0, True, GPP, 'grains per plant');
  VarCreate('SUMDTTGF', '[°Cd]', 0, True,
    SUMDTTGF, 'sum of thermal time since start of grainfilling');

  for i := 1 to 4 do
  begin  // Vier Blattetagen
    VarCreate('NcLAL__' + IntToStr(i), '[%]', 0, True, NcLAL[i]);
  end;
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    VarCreate('NphLeaf' + IntToStr(i), '[g/m2]', 0, True, NphLeaf[i]);
  end;

  for i := 1 to 4 do
  begin  // Vier Blattetagen
    VarCreate('NLeaf_Struc' + IntToStr(i), '[g/m2]', 0, True, NLeaf_Struc[i]);
  end;
  VarCreate('NLphot_pl', '[g/plant]', 0, True, NLphot_pl);
  VarCreate('NcStruc', '[%]', 0, True, NcStruc);
  VarCreate('sumNLAL', '[g/plant]', 0, True, sumNLAL);
  StateCreate('NGrain_pl', '[g/plant]', 0, True, NGrain_pl);
  StateCreate('GRNWT_pl', '[g/plant]', 0, True, GRNWT_pl);
  StateCreate(' potGrainN_pl', '[g/Plant]', 0, True, potGrainN_pl);
  ExternVCreate('avSLA', '', statefield, avSLA);
  ExternVCreate('TransintRatio', '', statefield, TransintRatio);
  ExternVCreate('GlobRad', '[W/m2]', statefield, GlobRad);
  ExternVCreate('SUMDTT5', '', statefield, SUMDTT5);
  ExternVCreate('QHI', '', statefield, QHI);
  ExternVCreate('P5', '', statefield, P5);
  ExternVCreate('SumMLAL', '', statefield, SumMLAL);
  ExternVCreate('SumLAL', '', statefield, SumLAL);
  ExternVCreate('TILN', '', statefield, TILN);
  ExternVCreate('kPAR', '', statefield, kPAR);
  ExternVCreate('fdsen', '', statefield, fdsen);
  ExternVCreate('PSIroot', '', statefield, PSIroot);
  ExternVCreate('sumpl_weight', '[g/plant]', statefield, sumpl_weight);
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    ExternVCreate('LAL_' + IntToStr(i), '[m2/m2]', statefield, LAL[i]);
  end;
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    ExternVCreate('PARi' + IntToStr(i), '[W/m2]', statefield, PARi[i]);
  end;
  for i := 1 to 4 do
  begin  // Vier Blattetagen
    ExternVCreate('MLAL' + IntToStr(i), '[g/m2]', statefield, MLAL[i]);
  end;

  for i := 1 to 4 do
  begin
   if i = 1 then  ParCreate('relNC' + IntToStr(i), '[%]', 4.8,  relNC[i]);
   if i = 2 then  ParCreate('relNC' + IntToStr(i), '[%]', 4.1,  relNC[i]);
   if i = 3 then  ParCreate('relNC' + IntToStr(i), '[%]', 3.3,  relNC[i]);
   if i = 4 then  ParCreate('relNC' + IntToStr(i), '[%]', 2.5,  relNC[i]);
  end;
  ParCreate('psi_s', '[-]', 0.2956942, psi_s,
    'for calculation of kf (allometric leaf/stem partitioning)');
  ParCreate('psi_crit', '[-]',
    2.24499, psi_crit, 'for calculation of kf (allometric leaf/stem partitioning)');
  ParCreate('rgr_GrainN', '[-]', 0.005, rgr_GrainN);
  ParCreate('dECDP', '[°cd]', 250, dECDP, 'duration of endosperm cell devision phase');
  ParCreate('RND', '[/°cd]', 0.008, RND, 'rel. rate of phot. N degradation');
  ParCreate('RNS', '[/°cd]', 0.0015, RNS, 'rel. rate of phot. N synthesis');
  ParCreate('iniGRNWT', '[mg/grain]', 3.5, iniGRNWT, 'initial grain weight (CW 3)');

  ParCreate('k1', '[kg/kg]', 0.0018, k1, 'Michaelis-Menten cons. to mobile N');
  ParCreate('k2', '[J/(m2*s)]', 10, k2, 'Michaelis-Menten cons. to PARi');
  ParCreate('GM4', '[-]', 144.6, GM4,'adjustment of grain number per sqare meter');
  ParCreate('piniGN', '[mg/1K grains]', 210, piniGN,
    'initial grain N of a single grain at the beginning of the endosperm cell division phase');
  ParCreate('pRGFILL', '[-]', 0.00127, pRGFILL);
  ParCreate('pHI1', '[-]', 0.2641838, pHI1);
  ParCreate('pHI2', '[-]', 0.0004443, pHI2);
  ParCreate('HImin', '[-]', 0.51, HImin);
  OptCreate('optRSWT', 'pothi', optRSWT);
  optRSWT.OptionList.Clear;
  optRSWT.OptionList.Add('pothi');
  optRSWT.OptionList.Add('CWT3');

end;

procedure TSubPartitioning_UpDate.Allometric_Leaf_Stem_Partitioning;
var
  kf, fStem_: real;

begin
  if (EC.v < EC_LGend.v) and (ISTAGE.v >= 1) and (LFWT_pl.v > 0) then
  begin
    // kf discribes the influence of psi-root to stem partitioning
    kf := max(1, 1 + (psiroot.v - psi_crit.v) * psi_s.v);
    fStem_ := (1 - 1 / (1 + exp(h.v / ln(1 / plants.v)) * power(LFWT_pl.v, g.v - 1) * g.v));
    fStem.v := min(1,fStem_ * kf);

    STMWT_pl.c := assiflow.v * fSTem.v;
    LFWT_pl.c  := Assiflow.v - STMWT_pl.c;
  end
  else
  begin
    STMWT_pl.c := Assiflow.v;
    LFWT_pl.c  := 0.0;
  end;
  GROLF.v  := LFWT_pl.c;
  GROSTM.v := STMWT_pl.c;
end;
  procedure TSubPartitioning_UpDate.calc_rootDM;



begin
  if fPTF_version = PTF_Kage then begin
// own approach
    PTF.v := min(1,1-(fFineRoot0.v-FFinerootDec.v*TempSum.v));      // old version Kage unpublished ....Ch. 10 Habil.
  end
  else if fPTF_version = PTF_CERES then begin

   {IF (ISTAGE.v < 9) and (ISTAGE.v>=5)    // CERES Version 3.x
     then PTF.v := 1.0 else
   If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  PTF.v :=   0.8
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  PTF.v :=   0.75
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  PTF.v :=   0.70
   else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  PTF.v :=   0.5
   else  PTF.v :=   0.0  ; }

    IF (ISTAGE.v < 9) and (ISTAGE.v>=5)    // Version CERES 4.x Eingefügt von ??, wann ??
      then PTF.v := 1.0 else
    If  (ISTAGE.v<5)and (ISTAGE.v>=4)
      then  PTF.v :=   0.8
    else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
      then  PTF.v :=   0.75
    else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
      then  PTF.v :=   0.70
    else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
      then  PTF.v :=   0.65
    else  PTF.v :=   0.0  ;
  end;

  If (fDroughtImpact = Droughtimpact) and (ISTAGE.v<5) then PTF.v := PTF.v - 0.1*(1-TransIntratio.v);  // to increase root mass under drough stress


  FFineRoot.v := max(0, 1-PTF.v);

  DMfineroot.C := Assiflow.v *Plants.v *FFineRoot.v; // per m2
  RTWT_pl.c :=  Assiflow.v * FFineRoot.v; // per plant
  Assiflow.v := Assiflow.v-RTWT_pl.c; // substract root growth
end;
procedure TSubPartitioning_UpDate.CalcRates;

begin
  //**** USubPartitioningVegNew
  Assiflow.v := Carbo.v + DMTrans_pl.v;
  if (GlobTime.v >= SowingDate.v) and (IStage.v >= 1) then
  begin  // 16.02.09 Tempsum ab IStage 1 = Auflaufen
    TempSum.c := max(TEMPM.V, 0);        // rate of change of temperature sum
  end;

  if (ISTAGE.v >= 0.99) and (ISTAGE.v < 2) and (SEEDRV.v > 0) then
  begin
    SEEDRV.c := -k_SEEDRV.v * Seedrv.v;
    Assiflow.v := Assiflow.v - SEEDRV.c;       // Addition of seed reserves to assiflow
  end
  else
    SEEDRV.c := 0;
  Calc_RootDM;
  if fLeaf_Stem_proc = Allometric then
    Allometric_Leaf_Stem_Partitioning
  else if fLeaf_Stem_proc = CERES then
    CERES_Leaf_Stem_Partitioning;
  // Calculation of N concentrations
  if ec.v >= ECcritNcLeaf.v then
  begin
    NoptLeaf.v := NcLeafVf1.v * (LFWT_m2.v{+SENWT_m2.v}) + NcLEafVf2.v;
    // without dead leaves ...
    NcLeafWinter.c := 0;
  end else
  begin
    if DayOfYear.v < 150 then
      if TEMPM.v > 0 then   // Übergang winter-Frühjahr ....  etwas besser kommentieren !!!
        NcLeafWinter.c := (NcLeafWinter.v - NcLeafMin.v) *
          rgr_NcLeafWinter.v * GlobRad.v * (1 - (NcLeafWinter.v - NcLeafMin.v) /
          (NcLeafVf1.v * LFWT_m2.v + NcLEafVf2.v - NcLeafMin.v));
    NoptLeaf.v := NcLeafWinter.v;
  end;
  if NcLeaf_ECLGE.v > 0 then
    NLeaf_pl.c := LFWT_pl.v * (NcLeaf_ECLGE.v / 100) - Nleaf_pl.v //constant N concentration
  else
    // between end of leaf growth and grainfilling
    NLeaf_pl.c := LFWT_pl.c * NoptLeaf.v / 100 + NOptLeaf.v / 100 * LFWT_pl.v - NLeaf_pl.v;  if NcStemWinter.v >= 0.98{Wo kommt die 0.98 her ???} *
    (1 / (NcStem_a.v + NcStem_b.v * STMWT_m2.v)){ec.v >= ECcritNcLeaf.v} then  begin
    NoptStem.v := 1 / (NcStem_a.v + NcStem_b.v * STMWT_m2.v);
    NcStemWinter.c := 0;
  end
  else
  begin
    if DayOfYear.v < 150 then
      if TEMPM.v > 0 then
        NcStemWinter.c := (NcStemWinter.v - NcStemMin.v) * rgr_NcStemWinter.v * GlobRad.v *
          (1 - (NcStemWinter.v - NcStemMin.v) /
          (1 / (NcStem_a.v + NcStem_b.v * STMWT_m2.v) - NcStemMin.v));

    NoptStem.v := NcStemWinter.v;
  end;

  if NCstem.v >= pNcMinimum_STEM.v then
    NStem_pl.c := STMWT_pl.c * NoptStem.v / 100 + (NoptStem.v / 100 * STMWT_pl.v - NStem_pl.v)
  else
    NStem_pl.c := STMWT_pl.c * pNcMinimum_STEM.v;

  // calculation of senescence and translocation

  if ISTAGE.v >= 1.0 then
  begin
    LFWT_pl.c  := max(-LFWT_pl.v, LFWT_pl.c - SENL.v);
    //  correction of net change of leaf dry matter due to senescence
    DMTrans_pl.v := Senl.v * pDMTrans.v / 100;
    // translocatable fraction of DM change  g/(pl*d)
    Senwt_pl.c := SENL.v * (1 - pDMTrans.v / 100);
    // non translocatable fraction of DM remains as dead leaves
    NLeaf_pl.c := NLeaf_pl.c - Senl.v * NcLeaf.v / 100;
    // correction net change of leaf N for leaf senescence
  end;
  //**** USubPartitioningVegNew end

  // SWmin setzen:
  if (fRSWT = gf_pothi) and (EC.v >= 60) then
  begin
    potHI.v := max(0.49, 0.1960*QHI.v + 0.2786); // provisorisch verankert (wegen ISIP)
    SWMin.v := max(0, (STMWT_m2.v - (TSDM_m2.v * potHI.v - GRNWT_m2.v)) / plants.v);
  end else
  if (EC.v >= 50) and (SWMin.v <= 0) and (fRSWT = gf_CWT3) then
    SWMin.v := STMWT_pl.v
  else
    SWMIN.v := 0;
  {..............Start Kornfüllung...............................................}
  calcNNI;
  if (GPSM.v <= 0) and (EC.v >= 40) then
    CalcGPSM;
  if (EC.v >= 40) and (EC.v < 90) then
    GRFILL
  else
  begin
    GROGRN.v := 0;
    GRNWT_pl.c := 0;
    calcQ45;
  end;
  CalcNRates;
  // Transfer shoot N and weight to senescent pool at the end of grain filling
  if (EC.v > 90) and (STMWT_pl.v > 0) then
  begin
    Senwt_pl.c := STMWT_pl.v + LFWT_pl.v;
    LFWT_pl.c := -LFWT_pl.v;
    STMWT_pl.c := -STMWT_pl.v;
    NSen_pl.c := NStoragepool_pl.v + NSTEM_pl.v + NLeaf_pl.v;
    NSTEM_pl.c := -NSTEM_pl.v;
    NLeaf_pl.c := -NLeaf_pl.v;
    NStoragepool_pl.c := -NStoragepool_pl.v;
    NSP_l.v := 0;
    NSP_s.v := 0;
  end;

end;

procedure TSubPartitioning_UpDate.CalcNRates;
{
N-Translokation während der Kornfüllungsphase:
 - translozierbare N-Menge wird für jede BE separat berechnet.
 - Auf- und Abbaukinetik wird in Abh. von mobiler N-Menge und Beschattung berechnet (Thornley 1998, Bertheloot 2008).
   ein starker Sink mindert daher die 'N-Syntheserate'.
 - N-Aufnahme ins Korn nur aus mobilem Pool
 - Verhältnis aus mobilem und photosynthetischem N im Stängel (r) richtet sich nach dem Verhältnis im Blatt
 - Blattseneszenz kann unabhängig oder in Abh. vom Blatt-N-Gehalt berechnet werden (Option SubLeafArea_UpDate)
 - Blatt N Fraktionen:
         - photosyntetisch
         - struktureller Anteil des gruenen Blattes
         - mobiles N
 }
var
  i: integer;
  Ndsen,sumN_ : real;// fraction of senescent leaf N wich is caused by drought stress
              //not going into the mobile N pool
  cN :array[1..4] of real; // intermediate value for N distribution

begin
  NDsen := 0;
  // calculating fraction of structural N
  NcStruc.v := 2.97 - 0.455 * XSTAGE.v; // according to Ceres Wheat
  NStemStruc_pl.v := STMWT_pl.v * NcStruc.v / 100;
  // calculation of structural N per leaf layer
  NLStruc_pl.v := 0;
  for i := 1 to 4 do
  begin
    if LFWT_pl.v + LFWT_pl.c > 0 then
    begin
      NLeaf_struc[i].v := MLAL[i].v * (NcStruc.v / 100);
      NLStruc_pl.v := NLStruc_pl.v + NLeaf_struc[i].v / plants.v;
    end else
    begin
      NLeaf_struc[i].v := 0;
    end;
  end;

  NLStruc_m2 := NLStruc_pl.v * plants.v;
 { ***calculating initial grain N***
    'piniGN' is the amount of N for a single grain at the begin endosperm cell division phase (Bertheloot 2008)
     }
  if (Ec.v > 40) and (potGrainN_pl.v <= 0) then
    // sliding N accumulation of initial grain N from EC 40 to 65
  begin
    NGrain_pl.c := piniGN.v * (1 / 1E6) * GPPVAR.v * min(1, (ec.v - 40) / (65 - 40)) - NGrain_pl.v;
    NStem_pl.c  := NStem_pl.c - NGrain_pl.c; // initial N comes from the stem fraction
    if GPSM.v > 0 then
      potGrainN_pl.v := Ngrain_pl.v;
  end;

  if GPSM.v <= 0 then
  begin   // before grain filling
    //the none structural fraction of leaf N is translocatable
    NTrans_pl.v := max(0, (Senl.v * (NcLeaf.v - NcStruc.v) / 100));
    // translocatable fraction of leaf N change  g/(pl*d)
    // In the next lines we are now loooking if there is some translocatable N left for the N storage pool

    // first we substract N stem
    if (NStem_pl.c > 0) and (NTrans_pl.v + NStoragepool_pl.v > 0) then
      NTrans_pl.v := NTrans_pl.v - Nstem_pl.c;

    // N translocation to stem growth
    if Nstem_pl.c < 0 then            // should normally not occure
      NTrans_pl.v := NTrans_pl.v - NStem_pl.c;
    // negative changes of N in stem are stored ....

    // then Nleaf
    if (NLeaf_pl.c > 0) and (NTrans_pl.v + NStoragepool_pl.v > 0) then
      NTrans_pl.v := NTrans_pl.v - NLeaf_pl.c;
    // N translocation to leaf growth
    // if the N demand for growth is larger than translocatable N + Storagepool
    // then all of the storagepool is used
    if NTrans_pl.v + NStoragepool_pl.v < 0 then
      NTrans_pl.v := -NStoragepool_pl.v;

    // if not all translocatable N is used for stem or leaf growth the remainder is stored
    NStoragepool_pl.c := NTrans_pl.v;

    // difine the initial amount of mobile N fraction for stem and leaf - later needed for the calculation of stem N release
    if Nleaf_pl.v > 0 then
    begin
      NSP_l.v := NStoragepool_pl.v * (Nleaf_pl.v / (NStem_pl.v + Nleaf_pl.v));
      NSP_s.v := NStoragepool_pl.v - NSP_l.v;
    end else
    begin
      NSP_l.v := 0;
      NSP_s.v := 0;
    end;

 //distribution of leaf N over the layers - starting with uniform leaf concentration
// maximum contrast in cN is reached at LAI 4 (distribution according to Bertheloot 2008)
    if (LFWT_m2.v >0) then
    begin
     for i := 1 to 4 do
        cN[i]:= min(LAI.v/4,1)*relNC[i].v*0.01
        +(1-min(LAI.v/4,1))*(NLEAF_m2.v/LFWT_m2.v);

      sumN_:=cN[1]*MLAL[1].v+ cN[2]*MLAL[2].v+ cN[3]*MLAL[3].v+ cN[4]*MLAL[4].v;
   end;
   for i := 1 to 4 do
     begin
       if MLAL[i].v>0 then begin

         if (LFWT_m2.v>0) and (sumN_>0) then
             // adjustment of layer N to overall canopy N
             NphLeaf[i].v :=cN[i]*MLAL[i].v*(NLEAF_m2.v/sumN_)-NLeaf_struc[i].v
         else NphLeaf[i].v:=0;
       end;
     end;
    NLphot_pl.v := (NphLeaf[1].v + NphLeaf[2].v + NphLeaf[3].v + NphLeaf[4].v) / plants.v;
  end else
    // ******** start of grain filling
  begin
    if GN_NRate.v = 0 then
      GN_Nrate.v := pINIGN.v * power(1 + rgr_GrainN.v, decdp.v) * rgr_GrainN.v;
    // adjustment of the leaf N for each layer by subtracting senescent leaf N
    for i := 1 to 4 do
    begin
      if (NLeaf_struc[i].v > 0) and (NcLAL[i].v > 0) then
      begin
        nc_ := (NphLeaf[i].v + NLeaf_struc[i].v) / MLAL[i].v * 100;
        // when the leaf mass of the layer is shrunken, the N concentration has changed
        if nc_ > NcLAL[i].v then
        begin
          Np2 := (MLAL[i].v * NcLAL[i].v) / 100;
          //the fraction of leaf tissue died by drought stress (fdsen= dsen/plar)
          //will not release N to the mobile N-pool
          NDsen := ((NphLeaf[i].v - (Np2 - NLeaf_struc[i].v)) / plants.v) * fdsen.v;
          NSP_l.v := NSP_l.v + ((NphLeaf[i].v - (Np2 - NLeaf_struc[i].v)) /
            plants.v) - NDsen;
          NphLeaf[i].v := Np2 - NLeaf_struc[i].v;
        end;
      end;
    end;
    // N uptake of the grains
    if potGrainN_pl.v > 0 then
    begin
      // exponential N accumulation until liniear rate is achieved
      SUMDTTGF.v := SUMDTTGF.v + max(0, TeMPM.v);
      potGrainN_pl.c := (pINIGN.v * GPP.v * power(1 + rgr_GrainN.v, min(dECDP.v, SUMDTTGF.v)) *
        (1 / 1E6)) + // exponential uptake
        (GN_Nrate.v * GPP.v * max(0, SUMDTTGF.v - dECDP.v) * (1 / 1E6)) -
        // linear uptake
        potGrainN_pl.v;
      // N accumulation during grain filling phase is limited by mobile N supply
      if Ec.v < 90 then
        Ngrain_pl.c := min((NSP_s.v + NSP_l.v), potGrainN_pl.c)
      else
        Ngrain_pl.c := 0;
      // updating mobile N pools..
      if Ngrain_pl.c > 0 then
      begin
        dNSP_s  := max(-NSP_s.v, -Ngrain_pl.c);  // N translocation from stem first
        dNSP_l  := max(-NSP_l.v, -(Ngrain_pl.c + dNSP_s));
        NSP_l.v := max(0, NSP_l.v + dNSP_l);
        NSP_s.v := max(0, NSP_s.v + dNSP_s);
      end;
    end else
    begin
      potGrainN_pl.c := 0;
      Ngrain_pl.c := 0;
    end;
    // calulating rate for photosynthetic N synthesis and degeneration for each leaf layer
    if (STMWT_pl.v + LFWT_pl.v) > 0 then
      Ncmob.v := (NSP_l.v + NSP_s.v) / (STMWT_pl.v + LFWT_pl.v)
    else
      Ncmob.v := 0;
    for i := 1 to 4 do
    begin  // Vier Blattetagen
      NDeg  := (NphLeaf[i].v / 1000) * RND.v; //g->kg
      NSyn  := RNS.v * (MLAL[i].v / 1000) * (Ncmob.v / (Ncmob.v + k1.v)) *
        (PARi[i].v / (PARi[i].v + k2.v));
      Nph_c := min(NphLeaf[i].v * 0.05, (NSyn - NDeg) * Tempm.v * 1E3);
      if LFWT_pl.v + LFWT_pl.c > 0 then
        NphLeaf[i].v :=
          max(0, min(MLAL[i].v * (NcLeafVf2.v / 100) - NLeaf_struc[i].v, NphLeaf[i].v + Nph_c))
      else
        NphLeaf[i].v := 0;
    end;
    // updating leaf N translocation
    dNSP_l  := NLphot_pl.v - (NphLeaf[1].v + NphLeaf[2].v + NphLeaf[3].v +
      NphLeaf[4].v) / Plants.v;
    NSP_l.v := max(0, NSP_l.v + dNSP_l);
    NLphot_pl.v := (NphLeaf[1].v + NphLeaf[2].v + NphLeaf[3].v + NphLeaf[4].v) / Plants.v;
    NLeaf_pl.c := NLphot_pl.v + NLStruc_pl.v - NLeaf_pl.v;
    if (NLphot_pl.v > 0) and (NStem_pl.v - NStemStruc_pl.v > 0) then
      R.v := NSP_l.v / NLphot_pl.v  // r= mob/ph
    else
      R.v := 0;
    // calculate the mobile fraction of stem N
    if NLphot_pl.v > 0 then
    begin
      dNSP_s := max(0, min(NStem_pl.v - NStemStruc_pl.v, max(0,
        (NStem_pl.v - NStemStruc_pl.v) * R.v - NSP_s.v)));
      NStem_pl.c := -dNSP_s;
    end else
    begin
      // transfer all mobile stem N to the storagepool
      dNSP_s := max(0, (NStem_pl.v - NStemStruc_pl.v));
      NStem_pl.c := -dNSP_s;
    end;
    NSP_s.v := max(0, NSP_s.v + dNSP_s);
    // updating change of mobile fraction
    NStoragepool_pl.c := max(-NStoragepool_pl.v, (NSP_s.v + NSP_l.v) - NStoragepool_pl.v);
  end;
  // ********
  // updating N concentration of the layers
  sumNLAL.v := 0;
  for i := 1 to 4 do
  begin
    if MLAL[i].v > 0 then
    begin
      NcLAL[i].v := ((NphLeaf[i].v + NLeaf_struc[i].v) / MLAL[i].v) * 100;
      sumNLAL.v  := sumNLAL.v + NphLeaf[i].v + NLeaf_struc[i].v;
    end else
      NcLAL[i].v := 0;
  end;
  // calculation of NSen
  NSen_pl.c := Senl.v * (NcStruc.v / 100) + NDsen;
  // transfer senescent stem N to the senescent pool 
  if (Nstem_pl.v > 0) and (STMWT_pl.v = 0) then
  begin
    Nstem_pl.c := -Nstem_pl.v;
    NSen_pl.c  := NSen_pl.c + Nstem_pl.v;
  end;
  // N demand of the plant (uptake from soil)  g/(pl*d)
  NDemand_pl.v := Max(Nstem_pl.c + NLeaf_pl.c + NGrain_pl.c + NSen_pl.c +
    NStoragepool_pl.c, 0);
  NupRate.v := NDemand_pl.v * plants.v;
  NUptake.c := NupRate.v * 10;
end;

procedure TSubPartitioning_UpDate.Integrate;
var
  i: integer;
begin

  inherited;

  if GPSM.v > 0 then
  begin
    TKM.v := (GRNWT_pl.v * plants.v) / GPSM.v * 1000;
    GRYD.v := ((GRNWT_pl.v * plants.v) / 10) * 1.14;// 14% Restfeuchte korr.
    HI.v := GRNWT_m2.v / TSDM_m2.v;
    NSen_m2.v := NSen_pl.v * plants.v;
  end;
  NSen_m2.v  := NSen_pl.v * plants.v;
  NShoot_pl.v := NLeaf_pl.v + NStem_pl.v + NStoragepool_pl.v + NGrain_pl.v;
  TOPWT_pl.v := LFWT_pl.v + STMWT_pl.v + SEEDRV.v + GRNWT_pl.v;
  TOPWT_m2.v := TOPWT_pl.v * plants.v;
  NShoot_m2.v := NShoot_pl.v * plants.v;
  NLeaf_m2.v := NLeaf_pl.v * plants.v;
  NSTEM_m2.v := NStem_pl.v * plants.v;
  if LAI.v > 0 then
    SLN.v := NLeaf_m2.v / LAI.v
  else
    SLN.v := 0;




 
  GRNWT_m2.v  := GRNWT_pl.v * plants.v;
  NGrain_m2.v := NGrain_pl.v * Plants.v;
  if NGrain_m2.v > 0 then
    NHI.v := NGrain_m2.v / (NShoot_m2.v + NSen_m2.v);
  TSDM_m2.v := STMWT_m2.v + LFWT_m2.v + Senwt_m2.v + GRNWT_m2.v;
  if (Senwt_m2.v > 0) then
    NcStraw.v := (NSen_pl.v / Senwt_pl.v) * 100;
  if (GRNWT_pl.v > 0) then
  begin
    NcGrain.v := 100 * (NGrain_pl.v / GRNWT_pl.v);
    ProtGrain.v := NcGrain.v * 5.7;
    KernelN.v := NGrain_m2.v * 10; // kgN/ha
  end;
  if SumMLAL.v > 0 then
  begin
    relTM_L1.v := MLAL[1].v / SumMLAL.v;
    relTM_L2.v := MLAL[2].v / SumMLAL.v;
    relTM_L3.v := MLAL[3].v / SumMLAL.v;
    relTM_L4.v := MLAL[4].v / SumMLAL.v;
  end else
  begin
    relTM_L1.v := 0;
    relTM_L2.v := 0;
    relTM_L3.v := 0;
    relTM_L4.v := 0;
  end;
  if SumLAL.v > 0 then
  begin
    relBF_L1.v := LAL[1].v / sumLAL.v;
    relBF_L2.v := LAL[2].v / sumLAL.v;
    relBF_L3.v := LAL[3].v / sumLAL.v;
    relBF_L4.v := LAL[4].v / sumLAL.v;
  end else
  begin
    relBF_L1.v := 0;
    relBF_L2.v := 0;
    relBF_L3.v := 0;
    relBF_L4.v := 0;
  end;


  if sumMLAL.v > 0 then
    NcLeaf.v := sumNLAL.v / sumMLAL.v * 100
  else
    NcLeaf.v := 0;  // aktuelle Blatt N-Konzentration
  NDemand.v := NDemand_pl.v * plants.v * 10000 / 1000;

end;

procedure Tsubpartitioning_UpDate.init(var GlobMod: TMod);
var
  i: integer;
begin
  inherited init(GlobMod);

  dNSP_l := 0;
  dNSP_s := 0;
  NLStruc_m2 := 0;
  ProzN := 0;
  critN := 0;
  Nph_c := 0;
  NDeg := 0;
  NSyn := 0;
  relNC_:= 0;
  nc_  := 0;
  Np2  := 0;
  for i := 45 downto 1 do
  begin
    PAR_arr[i] := 0;
    MTEMP_arr[i] := 0;
  end;

  if optRSWT.option = 'cwt3' then
  begin
    fRSWT := gf_CWT3;
  end;
  if optRSWT.option = 'pothi' then
  begin
    fRSWT := gf_pothi;
  end;
end;


procedure TSubPartitioning_UpDate.GRFILL;

begin
  // ***calculating initial grain weight ***
  if (Ec.v > 40) and (GPSM.v <= 0) then
    // sliding N accumulation of initial grain N from EC 40 to 65
  begin
    GRNWT_pl.c := (iniGRNWT.v / 1000) * GPPVAR.v * min(1, (ec.v - 40) / (65 - 40)) - GRNWT_pl.v;
    STMWT_pl.c := STMWT_pl.c - GRNWT_pl.c;
    // initial weight comes from the stem fraction
  end else
  begin
    if GPSM.v > 0 then
    begin
      potGROGRN.v := pRGFILL.v * TeMPM.v * STMWT_pl.v;
      //pRGFILL.v = maximum stem release Wageningen datatset 0.00127 [°Cd-1]
      GROGRN.v := max(0, min(potGROGRN.v, STMWT_pl.v - SWMIN.v));
      STMWT_pl.c := STMWT_pl.c - GROGRN.v;
      GRNWT_pl.c := GROGRN.v;
    end;
  end;
end;

procedure TSubPartitioning_UpDate.CalcQ45;
var
  i: integer;
  SUMPAR, SUMMTEMP: real;
begin
  if (EC.v >= 20) and (Ec.v < 60) then
  begin
    for i := 44 downto 1 do
    begin//Werte Rücken
      PAR_arr[i + 1] := PAR_arr[i];
      MTEMP_arr[i + 1] := MTEMP_arr[i];
    end;
    PAR_arr[1] := GlobRad.v * 0.48;
    MTEMP_arr[1] := max(0, TEMPM.v);
    SUMPAR := 0;
    SUMMTEMP := 0;
    for i := 1 to 45 do
    begin
      SUMPAR := SUMPAR + PAR_arr[i];
      SUMMTEMP := SUMMTEMP + MTEMP_arr[i];
    end;
    if SUMMTEMP > 0 then
      Q45.v := SUMPAR / SUMMTEMP
    else
      Q45.v := 0;
  end;
end;


procedure TSubPartitioning_UpDate.CalcNNI;

begin
  if (TSDM_m2.v > 0) and ((NShoot_m2.v + NSen_m2.v) > 0) then
  begin
    if (TSDM_m2.v / 100 < 1.55) then
      critN := 4.4
    else
      critN := 5.35 * Power(TSDM_m2.v / 100, -0.442);
    prozN := ((NShoot_m2.v + NSen_m2.v) / TSDM_m2.v) * 100;
    NNI.v := max(0, prozN / critN);
    if (EC.v >= 60) and (NNI60.v <= 0) then
      NNI60.v := NNI.v;
  end;
end;

procedure TSubPartitioning_UpDate.CalcGPSM;
begin
  // estimation of grains per plant for calculating initial value of grain N
  if (EC.v >= 40) and (NNI60.v <= 0) then
      GPPVAR.v := (GM4.v * power(ln(TOPWT_m2.v* Q45.v),
      2.6233)) / plants.v;
  if (GPSM.v <= 0) and (EC.v >= 65) then
  begin
    GPSM.v := (GM4.v * power(ln(TOPWT_m2.v * min(1, NNI60.v) * Q45.v), 2.6233));
    GPP.v  := GPSM.v / plants.v;
    GPPVar.v := GPP.v;
  end;

end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioning_UpDate]);
end;

end.
