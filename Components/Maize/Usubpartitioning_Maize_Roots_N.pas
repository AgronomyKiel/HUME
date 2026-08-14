unit Usubpartitioning_Maize_Roots_N;
// Module for dry matter and nitrogen partitioning of silage maize.
// Authors: Katja Holzhauser, Josephine Bukowiecki, Babette Wienforth, Henning Kage & Crop Science and Agronomy Group, Kiel University
// Last edited: 14.08.2026
// Parts of the module are published in:
// References
// Holzhauser, K., Wienforth, B.M., Komainda, M., Herrmann, A., Zimmermann, I. & Dippold, M.A. et al. (2026) HUME-Maize: modelling silage maize yield formation across genotypes and scales. The Journal of Agricultural Science, 164, e34. Available from: https://doi.org/10.1017/S0021859626100719.
// Holzhauser, K. (2025) Cover Crops for Sustainable Silage-Maize Production: Enhancing Resource Use Efficiency through Modelling and Remote Sensing (Doctoral dissertation). Christian-Albrechts-Universität zu Kiel: Kiel Available from: https://macau.uni-kiel.de/receive/macau_mods_00006346.
// Wienforth, B. (2011) Cropping systems for biomethane production: a simulation based analysis of yield, yield potential and resource use efficiency (Doctoral dissertation). Christian-Albrechts-Universität zu Kiel

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
  vcl.Dialogs,
  UMod,
  UState, UAbstractPlant, UlayeredSoil, Usubpartitioning_Maize,
  USimpleRootModDM, USoilNitrogenUp;

Type

  TNcShoot_Calc = (f_ln, herrmann04, organ_specific);

  Tsubpartitioning_Maize_Roots_N = class(Tsubpartitioning_Maize)

  private
    fNcShoot_Calc: TNcShoot_Calc;
  protected
    fRootModel: TSimpleRootModDM;
    function GetWLD(Index: Integer): THumeNumEntity; override;
    function GetSumRootLength: THumeNumEntity; override;
    function GetSumRootLength_eff: THumeNumEntity; override;
    function GetNUptakeRate: THumeNumEntity; override;
    procedure setSoilNitrogenMod(AModel: TPlantRelatedSubmod); override;

  public
    // Variables        //
    // Ntot : TVar;      // g N/m2
    NcOptShoot, NcOptRoot, NcOptLeaf, NcOptStem, NcOptCob, // (holzhauser)
    // NcactShoot,
    NcMinShoot, NcStem,
    // N concentration stem, supposed to be half of N-concentration shoot    (Neukam, Residue calculation)
    NcCob, //
      NcLeaf, //
      NDemand, // potenzielle N-Aufnahmerate  Gesamtpflanze g/m²*d
    NUptakeRate_act, // g/m²*d =   ActNUptake.v/10
    NPlantDef, // N-Mengendefizit der Pflanze g N/m2
    NPlantOpt, // optimale N-Menge in der Pflanze
    NShootDef, // N-Mengendefizit der Pflanze g N/m2
    NShootOpt, // optimale N-Menge in der Pflanze
    NRootDef, // N-Mengendefizit der Pflanze g N/m2
    NRootOpt, // optimale N-Menge in der Pflanze
    NLeafOpt, NStemOpt, NCobOpt, NLeafDef, NStemDef, NCobDef: TVar;
    DummyVar: TVar;
    NcShoot, NcRoot, //
      NNI, NNIShoot, NNILeaf: TVar; // %
    NDemandShoot,
    /// NDemand of the shoot [gN.m-2.d-1]
    NDemandLeaf, NDemandStem, NDemandCob, NDemandRoot: TVar;
    /// NDemand of the organs [gN.m-2.d-1]
    Ntrans, NNIstem, NNIcob: TVar;
    SupplyDemandRatio: TVar;
    NPlant_Soil: TVar;
    // State Variables
    Nshoot, Nroot, Nstem, Nleaf, Ncob, Ntot: TState; // g N/m2


    // Parameters
    Ncshoot_min, // niedrigste N Konzentration shoot
    Ncshoot_max, Ncshoot_a, Ncshoot_b: TPar;
    // Parameter für Verdünnungsfunktion NShootOpt
    Ncleaf_a, Ncleaf_b, Ncleaf_max, Ncleaf_min, Ncstem_max, Ncstem_min,
      Nccob_max, Nccob_min, Ncstem_a, Ncstem_b, Nccob_a, Nccob_b: TPar;
    // Parameter für organspezifische Verdünnungsfunktionen             //(holzhauser)
    Ncroot_min, // niedrigste N Konzentration root
    Ncroot_max, Ncroot_a, Ncroot_b: TPar;
    // Parameter für Verdünnungsfunktion NRootOpt
    DMStubble_par: TPar; // Stoppel-TM als Parameter
    NNI_fact: TPar;

    // External Variables
    ActNUptake: TExternV; // Aktuelle N-Aufnahmerate aus dem Boden-Modul
    MaxNUptake: TExternV; // Maximale N-Aufnahmerate aus dem Boden-Modul
    Nmin0_90: TExternV; //     (holzhauser)
    // Options
    OptNcShoot_Calc: TOption;

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

    Property St_Nshoot: TState read Nshoot write Nshoot;
    Property St_Nroot: TState read Nroot write Nroot;
    Property St_Ntot: TState read Ntot write Ntot;

    // Parameters

    Property RootModel: TSimpleRootModDM read fRootModel write fRootModel;

    // External Variables

    Property Ex_ActNUptake: TExternV read ActNUptake write ActNUptake;
    Property Ex_MaxNUptake: TExternV read MaxNUptake write MaxNUptake;

    // Options

    Property opt_NcShoot_Calc: TNcShoot_Calc read fNcShoot_Calc
      write fNcShoot_Calc;

  end; // SubmodelName

procedure Register;

implementation

uses Math, JCLdatetime;

procedure Tsubpartitioning_Maize_Roots_N.setSoilNitrogenMod
  (AModel: TPlantRelatedSubmod);
begin
  inherited;
  ActNUptake.Search := false;
  if SoilNitrogenMod is TSoilNitrogenUp then
  begin
    ActNUptake.f_v := @TSoilNitrogenUp(SoilNitrogenMod).ActNUptake.fv;
    ActNUptake.Source := '[' + SoilNitrogenMod.Name + ']';
    MaxNUptake.Search := false;
    MaxNUptake.f_v := @TSoilNitrogenUp(SoilNitrogenMod).MaxNUptake.fv;
    MaxNUptake.Source := '[' + SoilNitrogenMod.Name + ']';
    PsiRoot.Search := false;
    PsiRoot.f_v := @TSoilNitrogenUp(SoilNitrogenMod).PsiRoot.fv;
    PsiRoot.Source := '[' + SoilNitrogenMod.Name + ']';
  end;
end;

procedure Tsubpartitioning_Maize_Roots_N.CreateAll;
// var
// i: Integer;
// ndx_str: string;

begin
  inherited CreateAll;
  // Variables

VarCreate('NDemand', 'g/m²·d', 0, true, NDemand,
  'Potential N uptake rate of the entire plant (g/m²·d), sum of all simulated organ-demands');
VarCreate('NDemandShoot', 'g/m²·d', 0, true, NDemandShoot,
  'Potential N uptake rate for the shoot (g/m²·d), only active when option "hermann04" is selected');
VarCreate('NDemandRoot', 'g/m²·d', 0, true, NDemandRoot,
  'Potential N uptake rate for the roots (g/m²·d)');
VarCreate('NDemandLeaf', 'g/m²·d', 0, true, NDemandLeaf,
  'Potential N uptake rate for leaves (g/m²·d), only active when option "organ-specific" is selected');
VarCreate('NDemandStem', 'g/m²·d', 0, true, NDemandStem,
  'Potential N uptake rate for stems (g/m²·d), only active when option "organ-specific" is selected');
VarCreate('NDemandCob', 'g/m²·d', 0, true, NDemandCob,
  'Potential N uptake rate for cobs (g/m²·d) ,only active when option "organ-specific" is selected');
VarCreate('NUptakeRate_act', 'g/m²·d', 0, true, NUptakeRate_act,
  'Actual N uptake rate from soil (g/m²·d)');
VarCreate('NcOptShoot', 'g/g', 0, true, NcOptShoot,
  'Optimal N concentration in the shoot (g/g),Ncrit, only active when option "hermann04" is selected');
VarCreate('NcOptStem', 'g/g', 0, true, NcOptStem,
  'Optimal N concentration in stems (g/g) ,Ncrit,only active when option "organ-specific" is selected');
VarCreate('NcOptLeaf', 'g/g', 0, true, NcOptLeaf,
  'Optimal N concentration in leaves (g/g), Ncrit, only active when option "organ-specific" is selected');
VarCreate('NcOptCob', 'g/g', 0, true, NcOptCob,
  'Optimal N concentration in cobs (g/g), Ncrit,only active when option "organ-specific" is selected');
VarCreate('NcStem', 'g/g', 0, true, NcStem,
  'Actual N concentration in stems (g/g), only active when option "organ-specific" is selected');
VarCreate('NcLeaf', 'g/g', 0, true, NcLeaf,
  'Actual N concentration in leaves (g/g), only active when option "organ-specific" is selected');
VarCreate('NcCob', 'g/g', 0, true, NcCob,
  'Actual N concentration in cobs (g/g), only active when option "organ-specific" is selected');
VarCreate('NcMinShoot', 'g/g', 0, true, NcMinShoot,
  'Minimum N concentration in the shoot (g/g)');
VarCreate('NcOptRoot', 'g/g', 0, true, NcOptRoot,
  'Optimal N concentration in roots (g/g), Ncrit');
VarCreate('NcShoot', 'g/g', 0, true, NcShoot,
  'Actual N concentration in the shoot (g/g), only activated when option "hermann04" is selected');
VarCreate('NcRoot', 'g/g', 0, true, NcRoot,
  'Actual N concentration in roots (g/g)');
VarCreate('DummyVar', '–', 0, true, DummyVar,
  '');
VarCreate('NNI', '–', 1, true, NNI,
  'Nitrogen Nutrition Index (N status of the plant, dimensionless between 0 and 1), if organ-specific option is selected, NNI = NNIleaf, otherwise NNI = NNIshoot)');
VarCreate('NNIshoot', '–', 0, true, NNIShoot,
  'Nitrogen Deficiency Index for the shoot (dimensionless between 0 and 1)');
VarCreate('NPlantDef', 'g/m²', 0, true, NPlantDef,
  'N deficit in the entire plant (g/m²)');
VarCreate('NPlantOpt', 'g/m²', 0, true, NPlantOpt,
  'Optimal N content in the entire plant (g/m²)');
VarCreate('NShootDef', 'g/m²', 0, true, NShootDef,
  'N deficit in the shoot (g/m²)');
VarCreate('NShootOpt', 'g/m²', 0, true, NShootOpt,
  'Optimal N content in the shoot (g/m²)');
VarCreate('NRootDef', 'g/m²', 0, true, NRootDef,
  'N deficit in roots (g/m²)');
VarCreate('NRootOpt', 'g/m²', 0, true, NRootOpt,
  'Optimal N content in roots (g/m²)');
VarCreate('NLeafDef', 'g/m²', 0, true, NLeafDef,
  'N deficit in leaves (g/m²)');
VarCreate('NLeafOpt', 'g/m²', 0, true, NLeafOpt,
  'Optimal N content in leaves (g/m²)');
VarCreate('NStemDef', 'g/m²', 0, true, NStemDef,
  'N deficiency in stems (g/m²)');
VarCreate('NStemOpt', 'g/m²', 0, true, NStemOpt,
  'Optimal N content in stems (g/m²)');
VarCreate('NCobDef', 'g/m²', 0, true, NCobDef,
  'N deficit in cobs (g/m²)');
VarCreate('NCobOpt', 'g/m²', 0, true, NCobOpt,
  'Optimal N content in cobs (g/m²)');
VarCreate('Ntrans', 'g/m²', 0, true, Ntrans,
  'N translocation pool from leaves and stems to cob (g/m²·d)');
VarCreate('NNIleaf', '–', 0, true, NNILeaf,
  'Nitrogen Deficiency Index for leaves (dimensionless)');
VarCreate('NNIstem', '–', 0, true, NNIstem,
  'Nitrogen Deficiency Index for stems (dimensionless)');
VarCreate('NNIcob', '–', 0, true, NNIcob,
  'Nitrogen Deficiency Index for cobs (dimensionless)');
VarCreate('SupplyDemandRatio', '–', 0, true, SupplyDemandRatio,
  'Ratio of N supply from soil to N demand from plant (dimensionless)');
VarCreate('NPlant_Soil', 'g/m²', 0, true, NPlant_Soil,
  'N content in the plant derived from soil (g/m²)');

// States
StateCreate('Nshoot', 'g/m²', 0, true, Nshoot,
  'Nitrogen content in the shoot (g/m²), if organ-specific option is selected, Nshoot = 0, Ntot serves as the sum of all organs');
StateCreate('Nleaf', 'g/m²', 0, true, Nleaf,
  'Nitrogen content in leaves (g/m²)');
StateCreate('Nstem', 'g/m²', 0, true, Nstem,
  'Nitrogen content in stems (g/m²)');
StateCreate('Ncob', 'g/m²', 0, true, Ncob,
  'Nitrogen content in cobs (g/m²)');
StateCreate('Nroot', 'g/m²', 0, true, Nroot,
  'Nitrogen content in roots (g/m²)');
StateCreate('Ntot', 'g/m²', 0, true, Ntot,
  'Total nitrogen content in the plant (g/m²), sum of all simulated organs (depending on the option)');


// Parameters

// Parameter for shoot dilution function, estimated from data
// Biogas Expert 2007/2008 HS, KD, M1, N3, N4
ParCreate('Ncshoot_max', 'g/g', 4.9, Ncshoot_max,
  'Maximum possible N concentration in shoot, plateau of N delution curve, until DM>, only calculated if option is "hermann04"'); // (holzhauser)
// 3.4 after Plenet / Herrmann
ParCreate('Ncshoot_a', '–', 3.85, Ncshoot_a,
  'Coefficient a for Ncrit shoot dilution function (holzhauser)');
// Coefficients a and b for Ncrit shoot dilution function // (holzhauser)
ParCreate('Ncshoot_b', '–', -0.37, Ncshoot_b,
  'Coefficient b for Ncrit shoot dilution function (holzhauser)');
// In publication: a = 34.12, valid for Ncrit in gN·kg?¹DM ? per mille ? 3.4 gives Ncrit in percent (g·100g?¹DM)
// Parameters for organ-specific dilution functions (holzhauser)
// Calibrated on Biogas Expert 2007/2008 dataset
ParCreate('Ncleaf_a', '–', 3.56, Ncleaf_a,
  'Coefficient a for Ncrit leaf dilution function (holzhauser)');
ParCreate('Ncleaf_b', '–', -0.26, Ncleaf_b,
  'Coefficient b for Ncrit leaf dilution function (holzhauser)');
ParCreate('Ncleaf_max', 'g/g', 5.34, Ncleaf_max,
  'Ncrit plateau for leaves (g/g)'); // (holzhauser)
ParCreate('Ncstem_max', 'g/g', 4.02, Ncstem_max,
  'Ncrit plateau for stems (g/g)'); // (holzhauser)
ParCreate('Ncstem_a', '–', 4.30, Ncstem_a,
  'Coefficient a for Ncrit stem dilution function (holzhauser)');
ParCreate('Ncstem_b', '–', -0.33, Ncstem_b,
  'Coefficient b for Ncrit stem dilution function (holzhauser)'); // (holzhauser)
ParCreate('Nccob_a', '–', 3.20, Nccob_a,
  'Coefficient a for Ncrit cob dilution function (holzhauser)');
ParCreate('Nccob_b', '–', -0.34, Nccob_b,
  'Coefficient b for Ncrit cob dilution function (holzhauser)'); // (holzhauser)
// Parameters for root dilution function
ParCreate('Ncroot_max', 'g/g', 1.6, Ncroot_max,
  'Ncrit plateau for roots (g/g)');
ParCreate('Ncroot_a', '–', 2.0, Ncroot_a,
  'Coefficient a for Ncrit root dilution function');
ParCreate('Ncroot_b', '–', -0.225, Ncroot_b,
  'Coefficient b for Ncrit root dilution function');
ParCreate('DMStubble_par', 'g/m²', 200, DMStubble_par,
  'Stubble dry matter after harvest (g/m²), default 2 t/ha');
ParCreate('NNI_fact', '–', 2.43, NNI_fact,
  'NNI power factor (dimensionless), if NNI_fact = 1, NNI will be multiplied to DM production as usual');


// External Variables
ExternVCreate('ActNUptake', 'kg·N/ha·d', statefield, ActNUptake,
  'Actual N uptake rate (kg·N/ha·d)');
ExternVCreate('MaxNUptake', 'kg·N/ha·d', statefield, MaxNUptake,
  'Maximum N supply from the soil at that timestep (kg·N/ha·d)');
ExternVCreate('Nmin0_90', 'kg·N/ha·d', statefield, Nmin0_90,
  'Mineral N in soil layer 0–90 cm (kg·N/ha·d)');

  // Options
  OptCreate('NcShoot_Calc', 'herrmann04', OptNcShoot_Calc, 'hermann04: simulation of N content via whole plant assumption, organ-specific: simulation of N content via organ-specific delution curves, dynamic simulation of N uptake including Translocation pool. f_ln: is not working');
  OptNcShoot_Calc.OptionList.Clear;
  OptNcShoot_Calc.OptionList.Add('f_ln');
  OptNcShoot_Calc.OptionList.Add('herrmann04');
  OptNcShoot_Calc.OptionList.Add('organ_specific') // (holzhauser)

end;

procedure Tsubpartitioning_Maize_Roots_N.Init(var GlobMod: TMod);

begin
  inherited Init(GlobMod);
  // NcMinShoot.v := 0.0;
  // Nshoot.v := DMShoot.v * Ncshoot_max.v / 100;
  // NcShoot.v := Ncshoot_max.v;
  NNI.v := 1;
  NShootDef.v := 0;
  NLeafDef.v := 0;
  NStemDef.v := 0;
  NCobDef.v := 0;
  NRootDef.v := 0;
  Ntrans.v := 0;
  NDemand.v := 0;
  NDemandLeaf.v := 0;
  NDemandStem.v := 0;
  NDemandCob.v := 0;
  NDemandRoot.v := 0;
  Nleaf.v := 0;
  Nstem.v := 0;
  Ncob.v := 0;
  Nshoot.v := 0;
  Nroot.v := 0;
  Ntot.v := 0;
  SupplyDemandRatio.v := 0;
  Ncleaf.v:= 0;
  Ncstem.v:=0;
  Ncroot.v:=0;
  Nccob.v:=0;
  Ncoptleaf.v:= 0;
  Ncoptstem.v:=0;
  Ncoptroot.v:=0;
  Ncoptcob.v:=0;

  if OptNcShoot_Calc.option = 'f_ln' then
  begin
    fNcShoot_Calc := f_ln;
  end;
  if OptNcShoot_Calc.option = 'herrmann04' then
  begin
    fNcShoot_Calc := herrmann04;
  end;
  if OptNcShoot_Calc.option = 'organ_specific' then
  begin
    fNcShoot_Calc := organ_specific;
  end;

end;

// Verdünnungsfunktionen:
// Shoot
function NcOptShoot_f(DMShoot, XStage, Ncshoot_max, Ncshoot_a,
  Ncshoot_b: real): real;
begin
  // potenziell nach Herrmann und Taube (2004)
  //if (DMShoot > 100) then
    // obere und untere Bedingung(holzhauser): Nach Herrmann und Taube konstantes Nkrit bei DM < 1t/ha
   if (DMShoot > 52) then          // holzhauser 2024    berechnet mit Biogas-Expert Datensatz
    NcOptShoot_f := min(Ncshoot_max, Ncshoot_a * power((DMShoot / 100),
      Ncshoot_b)) // 100 um DM in t/ha umzurechnen;
  else if (XStage > 0) then
    NcOptShoot_f := Ncshoot_a
  else
    NcOptShoot_f := 0;
end;

// Leaves
function NcOptLeaf_f(DMLeaf, XStage, Ncleaf_max, Ncleaf_a,
  Ncleaf_b: real): real;
begin
  if (DMLeaf > 21) and (XStage > 0) then
    NcOptLeaf_f := min(Ncleaf_max, Ncleaf_a * power((DMLeaf / 100), Ncleaf_b))
    // 100 um DM in t/ha umzurechnen
  else
    NcOptLeaf_f := Ncleaf_a;
end;

// Stems
function NcOptStem_f(DMStem, XStage, Ncstem_max, Ncstem_a,
  Ncstem_b: real): real;
begin
  if (DMStem > 1) and (XStage > 0) then
    NcOptStem_f := min(Ncstem_max, Ncstem_a * exp((DMStem / 100) * Ncstem_b))
    // 100 um DM in t/ha umzurechnen
  else
    NcOptStem_f := Ncstem_a;
end;

// Cobs
function NcOptCob_f(DMcob, Nccob_a, Nccob_b: real): real;
begin
  if (DMcob > 98) then
    NcOptCob_f := min(Nccob_a, Nccob_a * power((DMcob / 100), Nccob_b))
    // 100 um DM in t/ha umzurechnen   /5 noch nurch Ncmax ersetzen!
  else  if (DMcob > 0) then
     NcOptCob_f := Nccob_a
   else
    NcOptCob_f := 0;
end;

procedure Tsubpartitioning_Maize_Roots_N.CalcRates;

// var
// i: Integer;
// Surplus: real;

begin
  inherited CalcRates;

  // Verdünnungsfunktion
  // Nshoot und Nroot, A.Knieß Nov. 2014

  If (DMShoot.v + ShootGR.v > 0) then
  begin
    if fNcShoot_Calc = f_ln then
    begin // logarithmisch  (nicht funktionsfähig)
      NcOptShoot.v := min(Ncshoot_max.v, Ncshoot_a.v + Ncshoot_b.v *ln(DMShoot.v + ShootGR.v));
    end;

    // Verdünnungsfunktion nach Herrmann für Gesamtpflanze
    if fNcShoot_Calc = herrmann04 then
    begin
      NcOptShoot.v := NcOptShoot_f(DMShoot.v, XStage.v, Ncshoot_max.v,Ncshoot_a.v, Ncshoot_b.v);
    end;

    // organspezifische Option
    if fNcShoot_Calc = organ_specific then
    begin
      if NcOptLeaf.v > 0 then
      // Absicherung, dass die Verdünnungskurve am Ende ein Minimum-Plateau erreicht.
        NcOptLeaf.v := min(NcOptLeaf.v,
          NcOptLeaf_f(DMLeaf.v + DMLeaf.c * Globtime.c, XStage.v, Ncleaf_max.v,
          Ncleaf_a.v, Ncleaf_b.v))
      else
        NcOptLeaf.v := NcOptLeaf_f(DMLeaf.v + DMLeaf.c * Globtime.c, XStage.v,
          Ncleaf_max.v, Ncleaf_a.v, Ncleaf_b.v);
      if (NcOptStem.v > 0) then
        NcOptStem.v := min(NcOptStem.v,
          NcOptStem_f(DMStem.v + DMStem.c * Globtime.c, XStage.v, Ncstem_max.v,
          Ncstem_a.v, Ncstem_b.v))
      else
        NcOptStem.v := NcOptStem_f(DMStem.v + DMStem.c * Globtime.c, XStage.v,
          Ncstem_max.v, Ncstem_a.v, Ncstem_b.v);
      NcOptCob.v := NcOptCob_f(DMcob.v + DMcob.c * Globtime.c, Nccob_a.v,
        Nccob_b.v);
    end;

  end;

  if (DMFineRoot.v + DMFineRoot.c > 0) then
    NcOptRoot.v := min(Ncroot_max.v, Ncroot_a.v + Ncroot_b.v *
      ln(DMFineRoot.v + DMFineRoot.c * Globtime.c));

  // N-Bedarfsermittlung:      (holzhauser)

  // vorheriger Ansatz; Wenn NShoot.v > NShootOpt dann ist der Demand = 0 und gleichzeitig der Uptake = 0
  // NDemandShoot := max(0,((DMShoot.v + DMShoot.c * Globtime.c) * NcOptShoot.v /100 - (Nshoot.v))/ Globtime.c);

  if (fNcShoot_Calc = herrmann04) then
  begin // Shoot
    if (DMShoot.v > 0) and (DMShoot.v < 52) then
      NDemandShoot.v := max(0, DMShoot.c * (NcOptShoot.v / 100))
    else
      NDemandShoot.v :=((DMShoot.v + DMShoot.c * Globtime.c) * (NcOptShoot.v / 100) -(NShoot.v)) / Globtime.c

        //max(0, DMShoot.c * (NcOptShoot.v + ((DMShoot.v / 100) * Ncshoot_a.v *
        //Ncshoot_b.v * power((DMShoot.v / 100), (Ncshoot_b.v - 1)))) / 100)
      // Ableitung der Verdünnungsfunktion. Siehe Vorlesungsfolien H.Kage.
  end
  else
  begin
    NDemandShoot.v := 0
  end;

  if (fNcShoot_Calc = organ_specific) then // (holzhauser)
  begin
    // Leaves   (Demand von Blatt und Stängel darf auch negativ werden ->Translokation zu Kolben)
    {if DMLeaf.v > 0 then}
    if DMLeaf.c >0 then
      NDemandLeaf.v := ((DMLeaf.v + DMLeaf.c * Globtime.c) * (NcOptLeaf.v / 100) -(Nleaf.v)) / Globtime.c
      else if (DMLeaf.c < 0) then
      NDemandLeaf.v := DMLeaf.c * NLeaf.v / DMLeaf.v
      else
      NDemandLeaf.v := 0;


    { if (DMLeaf.v > 0) and (DMLeaf.v < 2) then
      NDemandLeaf.v := max(0, DMLeaf.c * (NcOptLeaf.v / 100))
      else
      NDemandLeaf.v :=DMLeaf.c *(NcOptLeaf.v+((DMLeaf.v / 100)*NcLeaf_a.v *NcLeaf_b.v*power((DMLeaf.v / 100), (NcLeaf_b.v - 1)))) / 100; }
    // Stems
    if DMStem.c > 0 then
      NDemandStem.v := ((DMStem.v + DMStem.c * Globtime.c) * (NcOptStem.v / 100) -(Nstem.v)) / Globtime.c
      else if (DMStem.c < 0) then
      NDemandStem.v := DMStem.c * NStem.v / DMStem.v
      else
      NDemandStem.v := 0;

    { if (DMStem.v > 0) and (DMStem.v < 1.4) then
      NDemandStem.v := max(0, DMStem.c * (NcOptStem.v / 100))
      else
      NDemandStem.v := DMStem.c *(NcOptStem.v+((DMStem.v / 100)*NcStem_a.v *NcStem_b.v*exp((DMStem.v / 100)*NcStem_b.v ))) / 100; }
    // Cobs
    if DMcob.v > 0 then
      NDemandCob.v := max(0, ((DMcob.v + DMcob.c * Globtime.c) * (NcOptCob.v /100) - (Ncob.v)) / Globtime.c);

    // NDemandCob.v := max(0,DMCob.c *(NcOptCob.v+((DMCob.v / 100)*NcCob_a.v *NcCob_b.v*power((DMCob.v / 100), (NcCob_b.v - 1)))) / 100);
  end
  else
  begin
    NDemandLeaf.v := 0;
    NDemandStem.v := 0;
    NDemandCob.v := 0;
  end;

  // Roots
  NDemandRoot.v := ((DMFineRoot.v + DMFineRoot.c * Globtime.c) * NcOptRoot.v /
    100 - (Nroot.v)) / Globtime.c;

  // total NDemand (Je nach ausgewählter Option ist NDemandShoot oder der Demand der Organe = 0)
  NDemand.v := max(0, NDemandShoot.v + max(0, NDemandRoot.v) + max(0,NDemandLeaf.v) + max(0, NDemandStem.v) + NDemandCob.v);

  // If (XStage.v >= 5) or (dayoftheyear(Globtime.v) >= latestharvestdate.v) or (XStage5.v > 0) then
  if (dayoftheyear(Globtime.v) >= latestharvestdate.v) then
    NDemand.v := 0;

end;

procedure Tsubpartitioning_Maize_Roots_N.Integrate;

var
  // SupplyDemandRatio,
  NDemandVeg, NSupply: real;

begin
  {if NDemand.v = 0 then
  begin
    Nshoot.c := 0.0;
    Nroot.c := 0.0;
    Nleaf.c := 0.0;
    Nstem.c := 0.0;
    Ncob.c := 0.0;
  end
  else   }
  begin // (kage)
    { Nroot.c := NDemandRoot.v + NRootDef.v;
      Nshoot.c := NDemandShoot.v + NShootDef.v;
      Nleaf.c := NDemandLeaf.v + NLeafDef.v;
      Nstem.c := NDemandStem.v + NStemDef.v;
      Ncob.c := NDemandCob.v + NCobDef.v; }
    // NDemand.v := NDemand.v + NPlantDef.v;
    // total N supply in [g N/m2]

    if (fNcShoot_Calc = herrmann04) then
    begin
      If (NDemand.v > 0) then
        SupplyDemandRatio.v := max(0, min(1, ((MaxNUptake.v / 10)) / NDemand.v))
        // SupplyDemandRatio := max(0, min(1, (MaxNUptake.v/10) / NDemand.v))
      else
        SupplyDemandRatio.v := 1;
      if NDemandShoot.v > 0 then
        Nshoot.c := NDemandShoot.v * SupplyDemandRatio.v
      else
        Nshoot.c := NDemandShoot.v;

      if NDemandRoot.v > 0 then
        Nroot.c := NDemandRoot.v * SupplyDemandRatio.v
      else
        Nroot.c := NDemandRoot.v;

      Ntot.c := Nshoot.c + Nroot.c;
      NUptakeRate_act.v := Ntot.c;
    end;

    if (fNcShoot_Calc = organ_specific) then
    begin
     // Translokation von Blatt und Stängel N in den Kolben (holzhauser)
      Ntrans.v := 0;
      if (NDemandLeaf.v < 0) then
      begin
        Ntrans.v := Ntrans.v + max(0, -NDemandLeaf.v);
        // Speichern der translozierten Stickstoffmenge. Negatives Vorzeichen, weil NDemandleaf.v negativ ist, wenn NDemand <0
      end;
      if (NDemandStem.v < 0) then
      begin
        Ntrans.v := Ntrans.v + max(0, -NDemandStem.v);
        // Aktualisieren der translozierten Stickstoffmenge
      end;
      if (NDemandRoot.v < 0) then
      begin
        Ntrans.v := Ntrans.v + max(0, -NDemandRoot.v);
        // Aktualisieren der translozierten Stickstoffmenge
      end;


      if(Ntrans.v > 0){(XStage.v >= 3)} then
      begin
        NSupply := max(0, (MaxNUptake.v / 10)+ Ntrans.v);

        if NSupply > NDemandCob.v then
        begin
        Ncob.c := NDemandCob.v;
        end
        else
        begin
        Ncob.c := NSupply;
        end;

        NDemandVeg := max(0,NDemandLeaf.v) + max(0,NDemandStem.v) + max(0,NDemandRoot.v);

        If (NDemandVeg > 0) then
          SupplyDemandRatio.v := max(0,min(1,(NSupply-Ncob.c) / NDemandVeg)) ;
                // SupplyDemandRatio.v := max(0, min(1, (MaxNUptake.v/10) / NDemand.v))
        {else
                         SupplyDemandRatio.v := 1;}

        if NDemandRoot.v > 0 then
          Nroot.c := NDemandRoot.v * SupplyDemandRatio.v
        else
          Nroot.c := NDemandRoot.v;
        if NDemandLeaf.v > 0 then
          Nleaf.c := NDemandLeaf.v * SupplyDemandRatio.v
        else
          Nleaf.c := NDemandLeaf.v;
        if NDemandStem.v > 0 then
          Nstem.c := NDemandStem.v * SupplyDemandRatio.v
        else
          Nstem.c := NDemandStem.v;

      end
      else
      begin
        if NDemand.v > 0 then
          SupplyDemandRatio.v := max(0, min(1, (MaxNUptake.v / 10)/ NDemand.v))
        else
          SupplyDemandRatio.v := 1;
        Nroot.c := NDemandRoot.v * SupplyDemandRatio.v;
        Nleaf.c := NDemandLeaf.v * SupplyDemandRatio.v;
        Nstem.c := NDemandStem.v * SupplyDemandRatio.v;
        Ncob.c := NDemandCob.v * SupplyDemandRatio.v;
      end;

      Ntot.c := Nroot.c + Nleaf.c + Nstem.c + Ncob.c;
      NUptakeRate_act.v := Ntot.c;


    end;
  end;
  inherited Integrate;

  { // calculate again optimal N concentration with updated DM values after integration         (kage/holzhauser)
    If (DMShoot.v + ShootGR.v > 0) then
    begin
    if fNcShoot_Calc = f_ln then // logarithmisch
    NcOptShoot.v := min(Ncshoot_max.v, Ncshoot_a.v + Ncshoot_b.v *ln(DMShoot.v + ShootGR.v));

    if fNcShoot_Calc = herrmann04 then
    begin
    NcOptShoot.v := NcOptShoot_f(DMShoot.v,XStage.v,Ncshoot_max.v,Ncshoot_a.v, Ncshoot_b.v);
    end;

    if fNcShoot_Calc = organ_specific then  begin
    if NcOptLeaf.v > 0 then
    NcOptLeaf.v := min(NcOptLeaf.v,NcOptLeaf_f(DMLeaf.v,XStage.v,Ncleaf_max.v,Ncleaf_a.v, Ncleaf_b.v))
    else
    NcOptLeaf.v := NcOptLeaf_f(DMLeaf.v,XStage.v,Ncleaf_max.v,Ncleaf_a.v, Ncleaf_b.v);
    if (NcOptStem.v > 0) then
    NcOptStem.v :=min(NcOptStem.v,NcOptStem_f(DMStem.v,XStage.v,Ncstem_max.v,Ncstem_a.v, Ncstem_b.v))
    else
    NcOptStem.v :=NcOptStem_f(DMStem.v,XStage.v,Ncstem_max.v,Ncstem_a.v, Ncstem_b.v);
    NcOptCob.v := NcOptCob_f(DMcob.v, Nccob_a.v, Nccob_b.v, XStage.v);
    end;
    end;

    if (DMFineRoot.v + DMFineRoot.c > 0) then
    NcOptRoot.v := min(Ncroot_max.v, Ncroot_a.v + Ncroot_b.v *ln(DMFineRoot.v + DMFineRoot.c)); }

  { // calculate optimum N amounts in organs from updated DM and Nopt values
    NShootOpt.v := DMShoot.v * NcOptShoot.v / 100;
    NRootOpt.v := DMFineRoot.v * NcOptRoot.v / 100;
    NLeafOpt.v := DMLeaf.v * NcOptLeaf.v / 100;
    NStemOpt.v := DMStem.v * NcOptStem.v / 100;
    NCobOpt.v := DMcob.v * NcOptCob.v / 100;
    NPlantOpt.v := NShootOpt.v + NRootOpt.v + NLeafOpt.v + NStemOpt.v + NCobOpt.v; }

  // calculate a possible deficit N amounts        (kage/holzhauser)
  NRootDef.v := max(0, NRootOpt.v - Nroot.v); // g N/m²
  NShootDef.v := max(0, NShootOpt.v - Nshoot.v);
  NLeafDef.v := NLeafOpt.v - Nleaf.v;
  NStemDef.v := NStemOpt.v - Nstem.v;
  // NLeafDef.v := max(0,NLeafOpt.v - Nleaf.v);
  // NStemDef.v := max(0,NStemOpt.v - Nstem.v);
  NCobDef.v := max(0, NCobOpt.v - Ncob.v);
  NPlantDef.v := max(0, NRootDef.v + NShootDef.v + NLeafDef.v + NStemDef.v +
    NCobDef.v);

  NPlant_Soil.v := Nmin0_90.v + (Ntot.v * 10);  //(holzhauser)  Soil N + Plant N

  // calculate actual N concentrations of organs
  if (fNcShoot_Calc = herrmann04) then
  begin
    If (DMShoot.v > 100) then
      NcShoot.v := max(0, min(1, (Nshoot.v / DMShoot.v)) * 100)
    else
      NcShoot.v := Ncshoot_max.v;
  end
  else if (DMShoot.v < 0) then
  begin
    NcShoot.v := 0;
  end;

  If (DMFineRoot.v > 0) then
    NcRoot.v := min(1, Nroot.v / DMFineRoot.v) * 100
  else
    NcRoot.v := 0;

  if (fNcShoot_Calc = organ_specific) then
  begin
    If (DMLeaf.v > 2) and (XStage.v > 0) then
      NcLeaf.v := max(0, min(1, (Nleaf.v / DMLeaf.v)) * 100)
    else
      NcLeaf.v := NcOptLeaf.v;
    If (DMStem.v > 1.4) and (XStage.v > 0) then
      NcStem.v := max(0, min(1, (Nstem.v / DMStem.v)) * 100)
    else
      NcStem.v := NcOptStem.v;
    If (DMcob.v > 0) then
      NcCob.v := max(0, min(1, (Ncob.v / DMcob.v)) * 100)
    else
      NcCob.v := 0;
  end
  else
  begin
    NcLeaf.v := 0;
    NcStem.v := 0;
    NcCob.v := 0;
  end;


  // NNI, Kage & Knieß 04/2016

  // if (DMShoot.v + ShootGR.v >100 ) then //
  // NNI.v := max(0,min(1.0, NcShoot.v / NcOptShoot.v)) //
  // else
  // NNI.v := 1;

  // calculate optimum N amounts in organs from updated DM and Nopt values
  NShootOpt.v := DMShoot.v * NcOptShoot.v / 100;
  NRootOpt.v := DMFineRoot.v * NcOptRoot.v / 100;
  NLeafOpt.v := DMLeaf.v * NcOptLeaf.v / 100;
  NStemOpt.v := DMStem.v * NcOptStem.v / 100;
  NCobOpt.v := DMcob.v * NcOptCob.v / 100;
  NPlantOpt.v := NShootOpt.v + NRootOpt.v + NLeafOpt.v + NStemOpt.v + NCobOpt.v;

  // NNI Holzhauser 2024
  if (fNcShoot_Calc = herrmann04) then
  begin
    if (DMShoot.v + ShootGR.v > 100) then
      NNI.v := max(0, min(1.0, NcShoot.v / NcOptShoot.v))
    else
      NNI.v := 1;
  end;
  if (fNcShoot_Calc = organ_specific) then
  begin
    if (DMShoot.v + ShootGR.v > 100) then
      NNI.v := max(0, min(1.0, (NcLeaf.v) / (NcOptLeaf.v)))
      //NNI.v := min(1,1-power((1-max(0, min(1.0, (NcLeaf.v) / (NcOptLeaf.v)))),NNI_fact.v))
    else
      NNI.v := 1;
  end;
  if (fNcShoot_Calc = organ_specific) then
  begin
    if (DMLeaf.v > 10) then
      NNILeaf.v := max(0, min(1.0, NcLeaf.v / NcOptLeaf.v));
    if (DMStem.v > 10) then
      NNIstem.v := max(0, min(1.0, NcStem.v / NcOptStem.v));
    if (DMcob.v > 0) then
      NNIcob.v := max(0, min(1.0, NcCob.v / NcOptCob.v));
  end;

end;

// auskommentiert für Test der organspezifischen N-Verteilung
// Calculation of Crop-Residues, dneukam 11/2021
// NcStem.v := NcShoot.v / 2;
// C_Residues.v := (DMFineRoot.v + DMStubble_par.v) * 0.45;
// N_Residues.v := Nroot.v + DMStubble_par.v * NcStem.v / 100;

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





// if (DMShoot.v + ShootGR.v > 0) then
// begin
// if fNcShoot_Calc = f_ln then     // logarithmisch
// NcOptShoot.v := min(Ncshoot_max.v,
// Ncshoot_a.v + Ncshoot_b.v * ln(DMShoot.v + ShootGR.v));
//
// if fNcShoot_Calc = herrmann04 then   // potenziell nach Herrmann und Taube (2004)
// NcOptShoot.v := min(Ncshoot_max.v, (34.12 * power(DMShoot.v/100 ,-0.391 ))/10);
// end;

// logarithmisch Wurzel
// Ncroot_max.v := 1.6;
// Ncroot_a.v := 2.0;
// Ncroot_b.v := -0.225;
