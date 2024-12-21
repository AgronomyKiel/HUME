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


    //Ntot : TVar;      // g N/m2
    NcOptShoot,
    NcOptRoot,
    // NcactShoot,
    NcMinShoot,
    NcStem  // N concentration stem, supposed to be half of N-concentration shoot
      : TVar; // %
    NDemand, // potenzielle N-Aufnahmerate  Gesamtpflanze g/m²*d
    NUptakeRate_act, // g/m²*d =   ActNUptake.v/10
    NPlantDef, // N-Mengendefizit der Pflanze g N/m2
    NPlantOpt, // optimale N-Menge in der Pflanze
    NShootDef, // N-Mengendefizit der Pflanze g N/m2
    NShootOpt, // optimale N-Menge in der Pflanze
    NRootDef,  // N-Mengendefizit der Pflanze g N/m2
    NRootOpt   // optimale N-Menge in der Pflanze
      : TVar;
    DummyVar: TVar;
    NcShoot, NcRoot, //
    NNI: TVar; // %
    NDemandShoot,  /// NDemand of the shoot [gN.m-2.d-1]
    NDemandRoot: TVar;  /// NDemand of the root [gN.m-2.d-1]


    // State Variables
    Nshoot,
    Nroot,
    Ntot
             : TState; // g N/m2

    // Parameters
    Ncshoot_min, // niedrigste N Konzentration shoot
    Ncshoot_max, Ncshoot_a, Ncshoot_b: TPar; // Parameter für Verdünnungsfunktion NShootOpt
    Ncroot_min, // niedrigste N Konzentration root
    Ncroot_max, Ncroot_a, Ncroot_b: TPar; // Parameter für Verdünnungsfunktion NRootOpt
    DMStubble_par: TPar; // Stoppel-TM als Parameter

    // External Variables
    ActNUptake: TExternV; // Aktuelle N-Aufnahmerate aus dem Boden-Modul
    MaxNUptake: TExternV; // Maximale N-Aufnahmerate aus dem Boden-Modul


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

    Property St_Nshoot: TState read Nshoot write Nshoot;
    Property St_Nroot: TState read Nroot write Nroot;
    Property St_Ntot: TState read Ntot write Ntot;


    // Parameters

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

  VarCreate('NDemand', 'g m-2 d-1', 0, true, NDemand,'potenzielle N-Aufnahmerate (g.m-2.d-1)');
  VarCreate('NDemandShoot', 'g m-2 d-1', 0, true, NDemandShoot, 'potential N uptake rate shoot (g.m-2.d-1)');
  VarCreate('NDemandRoot', 'g m-2 d-1', 0, true, NDemandRoot, 'potential N uptake rate root (g.m-2.d-1)');
  VarCreate('NUptakeRate_act', 'g m-2 d-1', 0, true, NUptakeRate_act,'maximale N-Aufnahmerate (g.m-2.d-1)');
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

  StateCreate('Nshoot', '', 0, true, Nshoot);
  StateCreate('Nroot', '', 0, true, Nroot);
  StateCreate('Ntot', '', 0, true, Ntot);

  // Parameters

  // Parameter Verdünnungsfunktion Sproß aus Daten geschätzt
  // Biogas-Expert 2007/2008 HS, KD, M1, N3, N4
  ParCreate('Ncshoot_max', '', 3.4, Ncshoot_max);     //  4.944      3.4 nach Plenet /Herrmann
  ParCreate('Ncshoot_a', '', 3.412, Ncshoot_a);                      // Koeffizienten a und b nach Herrmann und Taube.
  ParCreate('Ncshoot_b', '', -0.391, Ncshoot_b);                     // in der Veröffentlichung a: 34.12   gilt für ein Nkrit in gN/kgDM also eine promille -> 3.4 ergibt NKrit in Prozent (g/100gDM)
  // Parameter Verdünnungsfunktion Wurzel
  ParCreate('Ncroot_max', '', 1.6, Ncroot_max);
  ParCreate('Ncroot_a', '', 2.0, Ncroot_a);
  ParCreate('Ncroot_b', '', -0.225, Ncroot_b);
  ParCreate('DMStubble_par', 'g.m-2', 200, DMStubble_par,'Stubble DM [g.m-2] after harvest, default 2t.ha-1');

  // External Variable
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
  NShoot.v:=  INI_DMleaf.v*Ncshoot_max.v/100;
  //NShoot.v := DMShoot.v*Ncshoot_max.v/100;
  NcShoot.v :=  Ncshoot_max.v;
  NNI.v := 1;

   if optNcShoot_Calc.option = 'f_ln' then begin
    fNcShoot_Calc := f_ln;
  end;
  if optNcShoot_Calc.option = 'herrmann04' then begin
    fNcShoot_Calc := herrmann04;
  end;
  NRootDef.v := 0;
  NShootDef.v := 0;


end;

function NcOptShoot_f (DMShoot, XStage, Ncshoot_max, Ncshoot_a, Ncshoot_b: real): real;

  begin
    // potenziell nach Herrmann und Taube (2004)
    if (DMShoot > 100) then // obere und untere Bedingung(holzhauser): Nach Herrmann und Taube konstantes Nkrit bei DM < 1t/ha
      NcOptShoot_f := min(Ncshoot_max, Ncshoot_a * power((DMShoot/100), Ncshoot_b))         //100 um DM in t/ha umzurechnen
    else if (XStage > 0) then
         NcOptShoot_f := Ncshoot_max
    else
      NcOptShoot_f := 0;

  end;

procedure Tsubpartitioning_Maize_Roots_N.CalcRates;

var
  i: Integer;
  Surplus: real;

begin
inherited CalcRates;

// Verdünnungsfunktion
// Nshoot und Nroot, A.Knieß Nov. 2014

 If (DMShoot.v + ShootGR.v > 0)  then

    begin
    if fNcShoot_Calc = f_ln then     // logarithmisch
        NcOptShoot.v := min(Ncshoot_max.v,
          Ncshoot_a.v + Ncshoot_b.v * ln(DMShoot.v + ShootGR.v));

       if fNcShoot_Calc = herrmann04 then
      NcOptShoot.v := NcOptShoot_f(DMShoot.v, XStage.v, Ncshoot_max.v, Ncshoot_a.v, Ncshoot_b.v);

    end;

  if (DMFineRoot.v + DMFineRoot.c > 0) then
    NcOptRoot.v := min(Ncroot_max.v,
    Ncroot_a.v + Ncroot_b.v * ln(DMFineRoot.v + DMFineRoot.c));

// N-Bedarfsermittlung:      (holzhauser)

  //vorheriger Ansatz; Wenn NShoot.v > NShootOpt dann ist der Demand = 0 und gleichzeitig der Uptake = 0
  //NDemandShoot := max(0,((DMShoot.v + DMShoot.c * Globtime.c) * NcOptShoot.v /100 - (Nshoot.v))/ Globtime.c);

 if (DMShoot.v>0) and (DMShoot.v < 100)then
   NDemandShoot.v := max(0,DMShoot.c*(NcOptShoot.v/100))
 else
   NDemandShoot.v:= max(0,DMShoot.c*(NcOptShoot.v +
    ((DMShoot.v/100)*Ncshoot_a.v*Ncshoot_b.v*power((DMShoot.v/100),(Ncshoot_b.v-1))))/100);


 NDemandRoot.v := max(0,((DMFineRoot.v + DMFineRoot.c * Globtime.c) * NcOptRoot.v / 100 - (Nroot.v))/ Globtime.c);

 NDemand.v := max(0, NDemandShoot.v + NDemandRoot.v);

  If (XSTAGE.v >= 5) or (dayoftheyear(Globtime.v) >= latestharvestdate.v) or
    (XStage5.v > 0) then
         NDemand.v := 0;
//  DMFineRoot.c := DMFineRoot.c;
end;

procedure Tsubpartitioning_Maize_Roots_N.Integrate;

var
  SupplyDemandRatio : real;

begin

  if NDemand.v <= 0 then
  begin
    Nshoot.c := 0.0;
    Nroot.c := 0.0;
  end
  else
  begin

    // Nshoot.v := DMShoot.v* NcShoot.v/100;      //(holzhauser) ?

    Nroot.c   := NDemandRoot.v + NRootDef.v; // (kage)
    NShoot.c  := NDemandShoot.v + NShootDef.v;
    NDemand.v :=  NDemand.v  + NPlantDef.v;
    If NDemand.v > 0 then
      SupplyDemandRatio := max(0, min(1, (MaxNUptake.v / 10) / NDemand.v))
    else
      SupplyDemandRatio := 1;
    Nshoot.c := Nshoot.c * SupplyDemandRatio;
    Nroot.c := Nroot.c * SupplyDemandRatio;
    Ntot.c  := Nshoot.c + Nroot.c;
    NUptakeRate_act.v := Ntot.c;
  end;

  inherited Integrate;

   // calculate again optimal N concentration with
   // updated DM values after integration
   If (DMShoot.v + ShootGR.v > 0)  then

    begin
    if fNcShoot_Calc = f_ln then     // logarithmisch
        NcOptShoot.v := min(Ncshoot_max.v,
          Ncshoot_a.v + Ncshoot_b.v * ln(DMShoot.v + ShootGR.v));

       if fNcShoot_Calc = herrmann04 then
      NcOptShoot.v := NcOptShoot_f(DMShoot.v, XStage.v, Ncshoot_max.v, Ncshoot_a.v, Ncshoot_b.v);

    end;
      if (DMFineRoot.v + DMFineRoot.c > 0) then
    NcOptRoot.v := min(Ncroot_max.v,
    Ncroot_a.v + Ncroot_b.v * ln(DMFineRoot.v + DMFineRoot.c));

  // calculate optimum N amounts in organs from updated DM and Nopt values
  NShootOpt.v := DMShoot.v * NcOptShoot.v / 100;
  NRootOpt.v  := DMFineRoot.v * NcOptRoot.v / 100;
  NPlantOpt.v := NShootOpt.v + NRootOpt.v;

  // calculate a possible deficit N amounts
  NRootDef.v := max(0, NRootOpt.v - Nroot.v);      // g N/m²
  NShootDef.v := max(0, NShootOpt.v - Nshoot.v);
  NPlantDef.v := max(0, NRootDef.v+NShootDef.v);

  // calculate actual N concentrations of organs
  if DMShoot.v > 0 then
    NcShoot.v := min(1,(Nshoot.v / DMShoot.v)) * 100
  else
    NcShoot.v := 0.0;
  If (DMFineRoot.v > 0) then
    NcRoot.v := min(1,Nroot.v / DMFineRoot.v) * 100
  else
    NcRoot.v := 0;

  // NNI, Kage & Knieß 04/2016

  if (NcShoot.v > 0) and (XStage.v > 1) then //
    // NNI.v := min(1.0, (NcShoot.v - NcMinShoot.v) / (NcOptShoot.v - NcMinShoot.v))    //Aktuell NcMinShoot := 0 (?)
    NNI.v := max(0,min(1.0, NcShoot.v / NcOptShoot.v)) // (holzhauser)
  else
    NNI.v := 1;


  // Calculation of Crop-Residues, dneukam 11/2021
  NcStem.v := NcShoot.v / 2;
  C_Residues.v := (DMFineRoot.v + DMStubble_par.v) * 0.45;
  N_Residues.v := Nroot.v + DMStubble_par.v * NcStem.v / 100;

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





 // if (DMShoot.v + ShootGR.v > 0) then
 //  begin
 //    if fNcShoot_Calc = f_ln then     // logarithmisch
 //        NcOptShoot.v := min(Ncshoot_max.v,
  //         Ncshoot_a.v + Ncshoot_b.v * ln(DMShoot.v + ShootGR.v));
 //
 //    if fNcShoot_Calc = herrmann04 then   // potenziell nach Herrmann und Taube (2004)
 //        NcOptShoot.v := min(Ncshoot_max.v, (34.12 * power(DMShoot.v/100 ,-0.391 ))/10);
//  end;

 // logarithmisch Wurzel
 // Ncroot_max.v := 1.6;
 // Ncroot_a.v := 2.0;
 // Ncroot_b.v := -0.225;
