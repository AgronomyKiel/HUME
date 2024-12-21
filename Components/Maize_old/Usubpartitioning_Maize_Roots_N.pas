unit Usubpartitioning_Maize_Roots_N;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod,
  UState, UAbstractPlant, UlayeredSoil, Usubpartitioning_Maize,
  USimpleRootModDM, USoilNitrogenUp;

Type

  TNcShoot_Calc = (f_ln, herrmann04);

  Tsubpartitioning_Maize_Roots_N = class(Tsubpartitioning_Maize)

  private
    fNcShoot_Calc : TNcShoot_Calc;
  protected
    fRootModel: TSimpleRootModDM;
    function GetWLD(Index: Integer): THumeNumEntity; override;
    function GetSumRootLength: THumeNumEntity; override;
    function GetSumRootLength_eff: THumeNumEntity; override;
    function GetNUptakeRate: THumeNumEntity; override;
    procedure setSoilNitrogenMod(AModel: TPlantRelatedSubmod); override;

  public
    // Variables        //

    ACroot: TVar; // drymatter allocation coefficient for roots
    // Ntot : TVar;      // g N/m2
    NcOptShoot, NcOptRoot,
    // NcactShoot,
    NcMinShoot,
    NcStem  // N concentration stem, supposed to be half of N-concentration shoot
      : TVar; // %
    NDemand, // potenzielle N-Aufnahmerate  g/m²*d
    NUptakeRate_act, // g/m²*d =   ActNUptake.v/10
    NPlantDef, // N-Mengendefizit der Pflanze g N/m2
    NPlantOpt, // optimale N-Menge in der Pflanze
    NShootDef, // N-Mengendefizit der Pflanze g N/m2
    NShootOpt, // optimale N-Menge in der Pflanze
    NRootDef, // N-Mengendefizit der Pflanze g N/m2
    NRootOpt // optimale N-Menge in der Pflanze
      : TVar;
    DummyVar: TVar;
    NcShoot, NcRoot, //
    NNI: TVar; // %

    // State Variables

    DMRoot: TState; // g N/m2
    DMtot: TState; // g N/m2
    Nshoot, Nroot, Ntot: TState; // g N/m2

    // Parameters

    ACEroot: TPar; // that is the ACroot (TM-Verteilungskoeffizient für die Wurzel) at emergence
    DSstop: TPar; // DevelopmentStage when root growth stops
    Ncshoot_min, // niedrigste N Konzentration shoot
    Ncshoot_max, Ncshoot_a, Ncshoot_b: TPar; // Parameter für Verdünnungsfunktion NShootOpt
    Ncroot_min, // niedrigste N Konzentration root
    Ncroot_max, Ncroot_a, Ncroot_b: TPar; // Parameter für Verdünnungsfunktion NRootOpt
    DMStubble_par: TPar; // Stoppel-TM als Parameter

    // External Variables

    DS: TExternV; // DevelopmentSage for root growth
    TempSumR: TExternV; // Temperatursumme für die Wurzelentwicklung
    ActNUptake: TExternV; // Aktuelle N-Aufnahmerate aus dem Boden-Modul
    MaxNUptake: TExternV; // Maximale N-Aufnahmerate aus dem Boden-Modul

    NDemandShoot, NDemandRoot, NDemandPlant: real;

    // Options

    OptNcShoot_Calc  : TOption;

    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    // Variables

    Property Var_ACroot: TVar read ACroot write ACroot;
    Property Var_NNI: TVar read NNI write NNI;
    Property Var_NcMinShoot: TVar read NcMinShoot write NcMinShoot;
    Property Var_NPlantDef: TVar read NPlantDef write NPlantDef;
    Property Var_NPlantOpt: TVar read NPlantOpt write NPlantOpt;
    Property Var_NShootDef: TVar read NShootDef write NShootDef;
    Property Var_NShootOpt: TVar read NShootOpt write NShootOpt;
    Property Var_NRootDef: TVar read NRootDef write NRootDef;
    Property Var_NRootOpt: TVar read NRootOpt write NRootOpt;

    // State

    Property St_DMRoot: TState read DMRoot write DMRoot;
    Property St_DMtot: TState read DMtot write DMtot;
    Property St_Nshoot: TState read Nshoot write Nshoot;
    Property St_Nroot: TState read Nroot write Nroot;
    Property St_Ntot: TState read Ntot write Ntot;


    // Parameters

    Property Par_ACEroot: TPar read ACEroot write ACEroot;
    Property Par_DSstop: TPar read DSstop write DSstop;
    Property RootModel: TSimpleRootModDM read fRootModel write fRootModel;

    // External Variables

    Property Ex_ActNUptake: TExternV read ActNUptake write ActNUptake;
    Property Ex_MaxNUptake: TExternV read MaxNUptake write MaxNUptake;

    // Options

    Property opt_NcShoot_Calc : TNcShoot_Calc read fNcShoot_Calc write fNcShoot_Calc;

  end; // SubmodelName

procedure Register;

implementation

uses Math, JCLdatetime;

procedure Tsubpartitioning_Maize_Roots_N.setSoilNitrogenMod(AModel: TPlantRelatedSubmod);
begin
  inherited;
  ActNUptake.Search := false;
  if SoilNitrogenMod is TSoilNitrogenUp then begin
    ActNUptake.f_v := @TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.fv;
    ActNUptake.Source := '['+SoilNitrogenMod.Name+']';
    MaxNUptake.Search := false;
    MaxNUptake.f_v := @TSoilNitrogenUp(SoilNitrogenMod).MaxNUptake.fv;
    MaxNUptake.Source := '['+SoilNitrogenMod.Name+']';
    PsiRoot.Search := false;
    PsiRoot.f_v := @TSoilNitrogenUp(SoilNitrogenMod).PsiRoot.fv;
    PsiRoot.Source := '['+SoilNitrogenMod.Name+']';
  end;
end;

procedure Tsubpartitioning_Maize_Roots_N.CreateAll;
var
  i: Integer;
  ndx_str: string;

begin
  inherited CreateAll;
  // Variables
  VarCreate('ACroot', '', 0, true, ACroot);
  VarCreate('NDemand', 'g m-2 d-1', 0, true, NDemand,
    'potenzielle N-Aufnahmerate (g.m-2.d-1)');
  VarCreate('NUptakeRate_act', 'g m-2 d-1', 0, true, NUptakeRate_act,
    'maximale N-Aufnahmerate (g.m-2.d-1)');

  // VarCreate('Nshoot', '',0, true,Nshoot);
  // VarCreate('Nroot', '',0, true,Nroot);
  // VarCreate('Ntot', '',0, true,Ntot);
  VarCreate('NcOptShoot', '', 0, true, NcOptShoot);
  VarCreate('NcMinShoot', '', 0, true, NcMinShoot);
  VarCreate('NcOptRoot', '', 0, true, NcOptRoot);
  VarCreate('NcShoot', '', 0, true, NcShoot);
  VarCreate('NcRoot', '', 0, true, NcRoot);
  VarCreate('NcStem', '', 0, true, NcStem,'N concentration stem, supposed to be half of N-concentration shoot');
  VarCreate('DummyVar', '', 0, true, DummyVar);
  VarCreate('NNI', '', 0, true, NNI);
  VarCreate('NPlantDef', '', 0, true, NPlantDef);
  VarCreate('NPlantOpt', '', 0, true, NPlantOpt);
  VarCreate('NShootDef', '', 0, true, NShootDef);
  VarCreate('NShootOpt', '', 0, true, NShootOpt);
  VarCreate('NRootDef', '', 0, true, NRootDef);
  VarCreate('NRootOpt', '', 0, true, NRootOpt);

  // State Variables

  StateCreate('DMRoot', '', 0, true, DMRoot);
  StateCreate('DMtot', '', 0, true, DMtot);
  StateCreate('Nshoot', '', 0, true, Nshoot);
  StateCreate('Nroot', '', 0, true, Nroot);
  StateCreate('Ntot', '', 0, true, Ntot);

  // Parameters

  ParCreate('ACEroot', '', 0.35, ACEroot);
  ParCreate('DSstop', '', 1.15, DSstop);

  // Parameter Verdünnungsfunktion Sproß aus Daten geschätzt
  // Biogas-Expert 2007/2008 HS, KD, M1, N3, N4
  ParCreate('Ncshoot_max', '', 4.944, Ncshoot_max);
  ParCreate('Ncshoot_a', '', 6.931, Ncshoot_a);
  ParCreate('Ncshoot_b', '', -0.716, Ncshoot_b);
  // Parameter Verdünnungsfunktion Wurzel
  ParCreate('Ncroot_max', '', 1.6, Ncroot_max);
  ParCreate('Ncroot_a', '', 2.0, Ncroot_a);
  ParCreate('Ncroot_b', '', -0.225, Ncroot_b);
  ParCreate('DMStubble_par', 'g.m-2', 200, DMStubble_par,'Stubble DM [g.m-2] after harvest, default 2t.ha-1');

  // External Variable

  ExternVCreate('DS', '', statefield, DS);
  ExternVCreate('TempSumR', '°C*d', statefield, TempSumR);
  ExternVCreate('ActNUptake', 'kg N/ha*d', statefield, ActNUptake);
  ExternVCreate('MaxNUptake', 'kg N/ha*d', statefield, MaxNUptake);

  // Options

  OptCreate('NcShoot_Calc', 'f_ln', optNcShoot_Calc);
  optNcShoot_Calc.OptionList.Clear;
  optNcShoot_Calc.OptionList.Add('f_ln');
  optNcShoot_Calc.OptionList.Add('herrmann04');

end;

procedure Tsubpartitioning_Maize_Roots_N.Init(var GlobMod: TMod);

begin
  inherited Init(GlobMod);
  NcMinShoot.v := 0.0;

   if optNcShoot_Calc.option = 'f_ln' then begin
    fNcShoot_Calc := f_ln;
  end;
  if optNcShoot_Calc.option = 'herrmann04' then begin
    fNcShoot_Calc := herrmann04;
  end;

end;

procedure Tsubpartitioning_Maize_Roots_N.CalcRates;
var
  i: Integer;
  Surplus: real;
begin
  DMtot.c := TotTMgRate.v;
  ExtPAR_varLAI.v := ExtCoeffPAR;

  If (XSTAGE.v >= 1) and (XSTAGE.v < 2) and (SEEDRV.v > 0) then
  begin
    SEEDRV.c := max(-SEEDRV.v, -k_SEEDRV.v * Tempfact.v);
    DMtot.c := DMtot.c - SEEDRV.c; // Addition of seed reserves to DMtot
  end
  else
    SEEDRV.c := 0;
  ACroot.v := max(0, ACEroot.v - DS.v * ACEroot.v / DSstop.v);
  DMRoot.c := DMtot.c * ACroot.v;
  ShootGR.v := DMtot.c * (1 - ACroot.v);
  If (XSTAGE.v >= 1) and (CumPH.v < TLNO.v - 2) then
    If DMleaf.v > 0 then
      fLEAF.v := 1 / (1 + exp(flb.v) * fla.v * power(DMleaf.v, (fla.v - 1)))
    else
      fLEAF.v := 1
    else
      fLEAF.v := 0;
  LeafGr.v := fLEAF.v * ShootGR.v;
  fCob.v := max(0, fCob_steig.v * XSTAGE.v + fCob_ini.v);
  // If (XStage.v>2) then begin
  // If (XStage.v<=(ln((fCob_steig.v/fCob_e.v)/fCob_ini.v)/fCob_e.v)+2)
  // then fCob.v := fCob_ini.v*exp(fCob_e.v*(XStage.v-2))
  // else fCob.v := fCob_steig.v*XStage.v+fCob_steig.v/fCob_e.v-fCob_steig.v*(ln((fCob_steig.v/fCob_e.v)/fCob_ini.v)/fCob_e.v+2);
  // end
  // else fcob.v :=0;
  If DMStem.v <= 0.25576 * DMShoot.v then
    fCob.v := min(1, fCob.v); // 0.25576 resultieren
  // aus den Messdaten, ca. 25% vom Spross sind zum Erntezeitpunkt noch Stängel.
  fCob.v := fCob.v / (1 + fLEAF.v); // Umrechnung vom Anteil an Kolben+Stängel auf Anteil an Spross.
  CobGr.v := ShootGR.v * fCob.v;
  StemGr.v := (1 - fLEAF.v - fCob.v) * ShootGR.v;

  DMcob.c := CobGr.v;
  DMleaf.c := LeafGr.v;
  DMStem.c := StemGr.v;
  // LAIleaf.c :=  SLAleaf_const.v*LeafGr.v;  // Berechnung des LAIleafs unter der Annahme einer konstanten SLA
  // LAIstem.c :=  SLAstem_const.v*StemGr.v;  // Berechnung des LAIleafs unter der Annahme einer konstanten SLA
  If (LAI.v > 0) or (SEEDRV.c <> 0) then
  begin
    If (fSLA_ = SLAfGAI) then
    begin
      SLAleaf.v := min(SLAleafini.v, SLAl_a.v * power(LAIleaf.v,
          SLAl_b.v) + SLAl_a.v * SLAl_b.v * power(LAIleaf.v,
          SLAl_b.v - 1) * LAIleaf.v);
      // SLAleaf.v := min(SLAleafini.v,SLAl_a.v*power(LAI.v,SLAl_b.v))
      SLAstem.v := min(SLAstemini.v, SLAs_a.v * power(LAIstem.v,
          SLAs_b.v) + SLAs_a.v * SLAs_b.v * power(LAIstem.v,
          SLAs_b.v - 1) * LAIstem.v);
      // SLAstem.v := min(SLAstemini.v,SLAs_a.v*power(LAI.v,SLAs_b.v))
    end;
    // else
    // begin
    If (fSLA_ = SLAconst) then
    begin
      SLAleaf.v := SLAleaf_const.v;
      SLAstem.v := SLAstem_const.v;
    end;
    If (fDroughtImpact_SLA = droughtimpact) then
      fSLAWR.v := min(1, max(1 - f1fslawr.v * (psiroot.v - psiWRsla.v),
          fSLAmin.v))
    else
      fSLAWR.v := 1;
    SLAleaf.v := SLAleaf.v * fSLAWR.v;
    LAIleaf.c := SLAleaf.v * LeafGr.v; // Berechnung des LAIleafs unter der Annahme einer über den LAI sinkenden SLA
    LAIstem.c := SLAstem.v * StemGr.v; // Berechnung des LAIstem unter der Annahme einer über den LAI sinkenden SLA
  end;

  If XSTAGE.v >= 1 then
    TSumLAI.c := max(Temp.v - Tbase6.v, 0)
  else
    TSumLAI.c := 0;

  If (optLAIe_calc.Option = 'logistisch') then
    If XSTAGE.v >= 1 then
      LAIe.v := LAImax.v / (1 + (LAImax.v / LAI0.v - 1) * exp
          (-RGRL.v * TSumLAI.v))
    else If (XSTAGE.v >= 1) and (LAIe.v <= LAIkrit.v) then
      LAIe.v := min(2, LAI0.v * exp(RGRL.v * TSumLAI.v))
    else
      LAIe.v := 0;
  If (optLAIe_calc.Option = 'log_decay') then
    If XSTAGE.v >= 1 then
    begin
      LAIe.v := LAImax.v / (1 + (LAImax.v / LAI0.v - 1) * exp
          (-RGRL.v * TSumLAI.v));
      If (LAIe.v >= 0.99 * LAImax.v) or Curveswitch_decay then
      begin
        If Curveswitch_decay = false then
        begin
          CurveswitchTSUM := TSumLAI.v;
          Curveswitch_decay := true;
        end;
        LAIe.v := max(0, LAImax.v - 0.01 * LAImax.v * exp
            ((TSumLAI.v - CurveswitchTSUM) * RGRdecay.v * LAImax.v));
      end;
    end
    else If (XSTAGE.v >= 1) and (LAIe.v <= LAIkrit.v) then
      LAIe.v := min(2, LAI0.v * exp(RGRL.v * TSumLAI.v))
    else
      LAIe.v := 0;

  LAIgreen.v := max(0, (1 - Sen_fact.v) * (LAIleaf.v + LAIleaf.c) +
      (LAIstem.v + LAIstem.c));

  If LAIe.v < LAIkrit.v then
    LAI.v := LAIe.v
  else
    LAI.v := LAIgreen.v;

  LeafDuration.c := LAI.v + (LAIleaf.c + LAIstem.c) * 0.5;
  // BodBedeck.v :=  (1-exp(-exkPAR.v*LAI.v));
  BodBedeck.v := (1 - exp(-ExtPAR_varLAI.v * LAI.v));

  if (WithRoots = true) and (soillayermod <> nil) then
    for i := 1 to tlayeredsoil(soillayermod).p_NComp do
      WLD[i].v := ExWLD_arr[i].v;

  //If (XSTAGE.v >= 5) or (dayoftheyear(Globtime.v) >= latestharvestdate.v) or
  If (XSTAGE.v >= 5) or (Globtime.v >= latestharvestdate.v) or
    (XStage5.v > 0) then
  begin
    LAI.v := 0;

    If XStage5.v = 0 then
      XStage5.v := dayoftheyear(Globtime.v);
  end;
  If (XSTAGE.v >= 1) and (XStage5.v = 0) then
    cumET_Veg.c := ETact.v
  else
    cumET_Veg.c := 0;
  If (XSTAGE.v > 0) and (XStage5.v = 0) then
    cumET_latestharvest.c := ETact.v
  else
    cumET_latestharvest.c := 0;

  // Nshoot und Nroot, A.Knieß Nov. 2014
  // Verdünnungsfunktion NcOptShoot

  if (DMShoot.v + ShootGR.v > 0) then
  begin
    if fNcShoot_Calc = f_ln then     // logarithmisch
        NcOptShoot.v := min(Ncshoot_max.v,
          Ncshoot_a.v + Ncshoot_b.v * ln(DMShoot.v + ShootGR.v));

    if fNcShoot_Calc = herrmann04 then   // potenziell nach Herrmann und Taube (2004)
        NcOptShoot.v := min(Ncshoot_max.v, (34.12 * power(DMShoot.v/100 ,-0.391 ))/10);
  end;
  // logarithmisch Wurzel
 // Ncroot_max.v := 1.6;
 // Ncroot_a.v := 2.0;
 // Ncroot_b.v := -0.225;
  if (DMRoot.v + DMRoot.c > 0) then
    NcOptRoot.v := min(Ncroot_max.v,
      Ncroot_a.v + Ncroot_b.v * ln(DMRoot.v + DMRoot.c));

  NDemandShoot := max(0,
    ((DMShoot.v + DMShoot.c * Globtime.c) * NcOptShoot.v / 100 - (Nshoot.v))
      / Globtime.c);
  NDemandRoot := max(0,
    ((DMRoot.v + DMRoot.c * Globtime.c) * NcOptRoot.v / 100 - (Nroot.v))
      / Globtime.c);
  NDemandPlant := max(0, NDemandShoot + NDemandRoot);
  If (XSTAGE.v >= 5) or (dayoftheyear(Globtime.v) >= latestharvestdate.v) or
    (XStage5.v > 0) then
         NDemandPlant := 0;
  NDemand.v := NDemandPlant;
  DMFineRoot.c := DMRoot.c;
end;

procedure Tsubpartitioning_Maize_Roots_N.Integrate;
begin

  if NDemandPlant <= 0 then
  begin
    Nshoot.c := 0.0;
    Nroot.c := 0.0;
  end
  else
  begin
    // aktuelle N-Aufnahme
    // bei "absolutem Mangel"
    if (NDemandPlant) > (MaxNUptake.v / 10) then
    begin
      Nshoot.c := (MaxNUptake.v / 10) * NDemandShoot / NDemandPlant;
      Nroot.c  := (MaxNUptake.v / 10) * NDemandRoot  / NDemandPlant;
    end
    // bei "absolutem N Überschuss"
    else if NDemandPlant <= MaxNUptake.v / 10 then
    begin
      Nshoot.c := NDemandShoot;
      Nroot.c  := NDemandRoot;
    end;
  end;
  Ntot.c := Nshoot.c+Nroot.c;
  NUptakeRate_act.v := Ntot.c;

  inherited integrate;

  If (XSTAGE.v >= 1) and (DMRoot.v <= 0) then
  begin
    TempSumR.v := 0;
    DMRoot.v := DMShoot.v * ACEroot.v / (1 - ACEroot.v);
    DMRoot.c := DMShoot.v * ACEroot.v / (1 - ACEroot.v);
    DMtot.v := DMShoot.v + DMRoot.v;
  end;
  // DMtot.v :=  DMShoot.v+DMRoot.v;
  // If CumTrans.v > 0 then TUEsim.v := DMtot.v/CumTrans.v else TUEsim.v := 0;
  // If CumET_Veg.v > 0 then WUEsim.v := DMtot.v/CumET_Veg.v else WUEsim.v := 0;

  // NShoot und Nroot, Knieß

  NShootOpt.v := DMShoot.v * NcOptShoot.v / 100;
  NRootOpt.v := DMRoot.v * NcOptRoot.v / 100;
  NPlantOpt.v := NShootOpt.v + NRootOpt.v;

  NShootDef.v := NShootOpt.v - Nshoot.v;
  NRootDef.v := NRootOpt.v - Nroot.v;
  NPlantDef.v := NPlantOpt.v - Ntot.v;

  If (DMShoot.v > 0) then
    NcShoot.v := Nshoot.v / DMShoot.v * 100
  else
    NcShoot.v := 0;

  // NNI, Kage & Knieß 04/2016

  if (NcShoot.v > 0) and (XSTAGE.v > 1) then
    NNI.v := min(1.0, (NcShoot.v - NcMinShoot.v) / (NcOptShoot.v - NcMinShoot.v)
      )
    // NNI.v := (NcShoot.v-NcMinShoot.v)/(NcOptShoot.v-NcMinShoot.v) //zum Test
  else
    NNI.v := 1;
  // NNI.v := 1.0;  // für Test

  If (DMRoot.v > 0) then
    NcRoot.v := Nroot.v / DMRoot.v * 100
  else
    NcRoot.v := 0;

    // Calculation of Crop-Residues, dneukam 11/2021
    NcStem.v := NcShoot.v/2;
    C_Residues.v := (DMRoot.v + DMStubble_par.v)*0.45 ;
    N_Residues.v := NRoot.v+DMStubble_par.v*NcStem.v/100;

end;

function Tsubpartitioning_Maize_Roots_N.GetNUptakeRate: THumeNumEntity;
begin
  result := NDemand;
end;

function Tsubpartitioning_Maize_Roots_N.GetWLD(Index: Integer): THumeNumEntity;
begin
  if WithRoots and (RootModel <> nil) then
    result := RootModel.WLD_Arr[Index]
  else
    result := DummyVar;
end;

function Tsubpartitioning_Maize_Roots_N.GetSumRootLength: THumeNumEntity;
begin
  if WithRoots and (RootModel <> nil) then
    result := RootModel.SRL
  else
    result := DummyVar;
end;

function Tsubpartitioning_Maize_Roots_N.GetSumRootLength_eff: THumeNumEntity;
begin
  if WithRoots and (RootModel <> nil) then
    result := RootModel.SRL_eff
  else
    result := DummyVar;
end;

procedure Register;
begin
  RegisterComponents('Maize', [Tsubpartitioning_Maize_Roots_N]);
end;

end.
