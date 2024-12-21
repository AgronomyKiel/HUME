unit UBkGrowth;

interface

uses
 UState, Umod, Classes, IniFiles, UBkLeafDev, USimplePlant;

const
  MaxParDays = 10;

type
  real = double;

  DMPart_opt = (Kage, Alt);


  TBkGrowth = Class(TBkLeafDev)
  private
    AssiToVeg : real;
    FAutoStop : boolean;
  protected
   rgr_arr : array[1..AvDays] of real;
   procedure Set_GlobMod(Model:TMod); override;
   procedure createAll; override;

  public
    CurdDiameter : TVar;
    LAI          : TState;
    TS           : TState;
    GrowthDuration : TState;
    TS3          : TState; {Temperatursumme in Stadium 3}

    Max_CD   : TPar;
    h        : TPar;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}
    g        : Tpar;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}
    o        : TPar;   {Parameter Stem- tap-root-partitioning}
    p        : TPar;   {Parameter Stem- tap-root-partitioning}

    a_Alt    : TPar;   // parameter for leaf/stem partitioning according to Alt
    f_stem   : TPar;    // parameter for stem growth due to curd growth according to Alt

    frac_froots0  : TPar;   { Fraction of DM increase allocated to fine roots
                              under unstressed conditions}
    frac_froots  : TVar; // actual fraction of DM increase allocated to fine roots
    Ffl0         : TPar;   {ffl_0 Anteil Kopwachstum an Gesamtwachstumsrate bei Kopfanlage }
    Fflmax       : TPar;   {ffl_f Anteil Kopwachstum an Gesamtwachstumsrate bei Reife }
    FFlrgr0      : TPar;   {ffl_r Wachstumsrate des Kopfanteiles }
    fflrgrPar1   : TPar;
    fflrgrPar2   : TPar;
    BSTD         : TPar;   // Bestandesdichte
    DMVegStart   : TPar;  // Schätzwert für Starttrockenmasse

    fflrgr : TVar;
    ffl    : TVar; // fraction of assimilates allocated to the curd

    DMTrans : TVar; // rate of dry matter translocation [g/m2/d]
    DMAbort : TVar; // rate of dry matter abortion [g/m2/d]
    PlantDiameter : TVar; // [m]
    RelGroundCov  : TVar; // relative ground cover []

    PAR
         : TExternV;

    Par_arr : array[1..MaxParDays] of real;
    Growth_arr : array[1..MaxParDays] of real;

    PARav : Tvar;
    GrowthAv : TVar;

    PartOption : DMPart_opt;


   Constructor create(AOwner: TComponent); override;

   procedure leaf_stem_growth; virtual;
   procedure root_growth; virtual;
   procedure CurdGrowth;
   procedure GetCurdDiameter;
   procedure GetLAI;
   procedure Init(var GlobMod:Tmod); override;
   procedure CalcRates; override;
   procedure Integrate; override;

   published
   property Ex_PAR  : TExternV read PAR write PAR;

   property Par_Max_CD  : TPar read Max_CD write Max_CD;
   property Par_h : TPar read h write h ;   { Proportionalitaetskonstante Blatt-Stengel-Verteilung}
   property Par_g        : Tpar read g write g;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}
   property Par_o        : TPar read o write o ;
   property Par_p        : Tpar read p write p;

   property Par_a_Alt    : Tpar read a_Alt write a_Alt;
   property Par_fStem    : Tpar read f_Stem write f_Stem;

   property Par_frac_froots0   : Tpar read frac_froots0 write frac_froots0;
   property Var_frac_froots   : TVar read frac_froots write frac_froots;
   property Par_Ffl0     : TPar read  Ffl0 write Ffl0;   {ffl_0 Anteil Kopwachstum an Gesamtwachstumsrate bei Kopfanlage }
   property Par_Fflmax   : TPar read Fflmax write Fflmax;   {ffl_f Anteil Kopwachstum an Gesamtwachstumsrate bei Reife }
   property Par_FFlrgr0  : Tpar read FFlrgr0 write FFlrgr0;   {ffl_r Wachstumsrate des Kopfanteiles }
   property Par_BSTD     : TPar read BSTD write BSTD;       // Bestandesdichte
   property Var_FFlrgr   : TVar read fflrgr write fflrgr;
   property Var_FFl      : TVar read ffl    write ffl;
   property Var_DMTrans : TVar read DMTrans write DMTrans;
   property Var_Parav : TVar read Parav write Parav;
   property Var_Plantdiameter : TVar read Plantdiameter write Plantdiameter;
   property Var_RelGroundCov : TVar read RelGroundCov write RelGroundCov;

   property Opt_Part : DMPart_opt read PartOption write PartOption;
   property Opt_AutoStop : boolean read FAutoStop write FAutoStop;

 end;

procedure register;

implementation

uses math, Dialogs,
 UModUtils ;

procedure TBkGrowth.createAll;
begin
  inherited createAll;
  StateCreate( 'TS3', '[°C*d]', 0.0, false, TS3);
  StateCreate( 'TS', '[°C*d]', 0.0, false, TS);
  StateCreate( 'Duration', '[°C*d]', 0.0, false, GrowthDuration);

  DMgen.Name := 'DMCurd';

  ParCreate('h','[-]', -0.974, h);
  ParCreate('g','[-]', 0.941, g);
  ParCreate('o','[-]', 0.932, o);
  ParCreate('p','[-]', -2.194, p);

  ParCreate('a_Alt','[-]', 12.93, a_Alt);
  ParCreate('f_stem','[-]', 0.15, f_stem);

  ParCreate('Frac_fRoots0','[-]', 0.1167, frac_froots0);
  VarCreate('Frac_fRoots','[-]', 0.1, false, frac_froots);
  ParCreate('FFl0','[-]', 0.000206012, ffl0);
  ParCreate('FFlmax','[-]', 0.8152, fflmax);
  ParCreate('FFlrgr0','[-]', 0.01498, fflrgr0);
  ParCreate('FFlrgrPar1','[-]', 0.0078, fflrgrPar1);
  ParCreate('FFlrgrPar2','[-]', 3, fflrgrPar2);
  VarCreate('FFlrgr','[-]', 0.01498, false, fflrgr);
  VarCreate('FFl','[-]', 0.01498, false, ffl);
  VarCreate('DMTrans','[-]', 0.0, false, DMTrans);
  VarCreate('DMAbort','[-]', 0.0, false, DMAbort);
  VarCreate('Parav','[-]', 0.0, false, Parav);
  VarCreate('Growthav','[-]', 0.0, false, growthav);

  VarCreate('CurdDiameter', '[mm]', 0.6, false, CurdDiameter);
  VarCreate('PlantDiameter', '[m]', 0.0, false, PlantDiameter);
  VarCreate('RelGroundCov', '[mm]', 0.0, false, RelGroundCov);

  ParCreate('max_CD','[mm]', 200, max_cd);
  ParCreate('DMVegStart','[g/m2]', 0.5, DMVegStart);
  ParCreate('BSTD','[g/m2]', 4, BSTD);
  StateCreate('LAI', '[m2./m2]', DMLeaf.v*sla.v/10000, true, LAI);
  GetLai;
  ExternVcreate('PAR', '[MJ/m2/d]', stateField, PAR);

end;

constructor TBkGrowth.create (AOwner: Tcomponent);

begin
  inherited create(AOwner);
  createAll;
end;

procedure TBkGrowth.Set_GlobMod(Model:TMod);

begin

inherited Set_GlobMod(Model);
  createAll;
end;


procedure TBkGrowth.Init(var GlobMod: Tmod);

const
  F_Leaf = 0.7;

var
  i : integer;

begin
  Inherited init(GlobMod);
  if DMVeg.v <= 0.0 then
    ShowMessage('Fehler bei Trockenmasseinitialisierung');
  DMShoot.v := DMVeg.v;

// Schätzung der Starttrockenmasse, normalerweise auszukommentieren
//  DMVeg.v := DMVegStart.v;
  DMLeaf.v := f_leaf*DMVeg.v;
  DMStem.V := (1-f_leaf)*DMVeg.v;
  TotalDrymatter.v := DMVeg.v;
  if RootOptions = Roots then begin
    DMTaproot.v := exp(p.v+o.v*ln(DMVeg.v));
    DMFineRoot.v := DMVeg.v;
  end;
  fflrgr.v := fflrgr0.v;
  Frac_FRoots.V := Frac_fRoots0.v;

  CurdDiameter.v := 0.0;
  TS3.c := 0.0;
  TS.c := 0.0;
  TS.v := 0.0;
  Growthduration.v := 0.0;
  for i := 1 to MaxParDays do
    Par_arr[i] := 5.0;
  PARav.v := 0;
  for i := 1 to MAxParDays do
    Parav.v := Parav.v+par_arr[i];
  parav.v := parav.v/MaxParDays;


  for i := 1 to MaxParDays do
    growth_arr[i] := 0.0;

  for i := 1 to AVDays do
    rgr_arr[i] := 0;


//  GetLAI;
  lai.v := DMLeaf.v*200/1e4; // leaf area is initialised using a SLA of 200
  ffl.v := -1.0;
end;

procedure TBkGrowth.Root_Growth;

Var
  AssiToRoot : real;

begin
  AssiToShoot.v := AssiFlow.v*((1-frac_fRoots.v)/(1+exp(p.v)*o.v*power(DMShoot.v, o.v-1)));
  AssiToRoot := AssiFlow.v-AssiToShoot.v;
  AssiToFineRoot.v := Assiflow.v*frac_FRoots.v;
  AssiToTapRoot.v  := AssiToRoot-AssiToFineRoot.v;
end;

procedure TBkGrowth.leaf_stem_growth;

var
  exh : real;

begin
 if PartOption = Kage then begin
    exh          :=  exp(h.v);
    AssiToLeaf.v :=  AssiToVeg*1/(1+exh*power(DMLeaf.v,g.v-1)*g.v);
    AssiToStem.v :=  AssiToVeg-AssiToLeaf.v;
 end else begin
   AssiToStem.v := f_stem.v*AssiToGen.v+a_Alt.v/1e4*SLA.v*AssiToLeaf.v;
   AssiToLeaf.v := AssiToShoot.v-AssitoStem.v-AssiToGEn.v;
 end;

end;


procedure TBkGrowth.CurdGrowth;

var
  i : integer;
begin
// Calculation of an average growth rate
If Vern.v < 1.0 then begin
  for i := MaxParDays downto 2 do
    Growth_arr[i] := Growth_arr[i-1];
  Growth_arr[1] := TotalDrymatter.c;
  Growthav.v := 0;
  for i := 1 to MAxPARDays do
    Growthav.v := Growthav.v+Growth_arr[i];
  Growthav.v := Growthav.v/MaxPARDays;
end;


  If Vern.v >= 1.0 then begin
    if ffl.v <= 0.0 then
      ffl.v := ffl0.v;
//     If DMGen.v <= 0.0 then
//       DMGen.v :=6.4e-6*Bstd.v;
//    fflrgr.v := 0.0059*growthav.v/Bstd.v+0.0122;
//    fflrgr.v := 0.0087*exp(rgrplantav.v*7.26);                 // für späte Sätze 1996
//    fflrgr.v := fflrgrPar1.v*exp(rgrplantav.v*fflrgrPar2.v); // für alle anderen Sätze
    TS3.c := Temp.v;
    ffl.v := ffl.v+ffl.v *Temp.v*fflrgr.v*sqrt(Growthav.v)*(1-ffl.v/fflmax.v)*GlobTime.c;
    ffl.v   := (fflmax.v*ffl0.v)/(ffl0.v+(fflmax.v-ffl0.v)*EXP(-fflrgr.v*TS3.v));
//    AssiToGen.v := min(DMGen.v*Temp.v{*Growthav.v}*fflrgr.v, fflmax.v*AssiToShoot.v)
  end
  else begin
    TS3.c       := 0.0;
    AssiToGen.v := 0.0;
  end;
  ffl.v := min (1.0,ffl.v);
  ffl.v := max (0.0, ffl.v);
//  ffl.v := AssiToGen.v/AssiToShoot.v;
  AssiToGen.v := AssiToShoot.v*ffl.v;

end;

procedure TBkGrowth.GetCurdDiameter;

var
  DMperCurd : real;

begin
  if DMGen.v > 0.0 then begin
    DMperCurd   := DMGen.v/Bstd.v;
    CurdDiameter.v := 33.82*power(DMperCurd, 0.422);
  end else begin
    CurdDiameter.v := 0.0;
  end;
end;


procedure TBkGrowth.GetLAI;

var
 i : integer;

begin
  if (PAR <> nil) and (Par.f_v <> nil) then begin
  for i := MaxParDays downto 2 do
    Par_arr[i] := Par_arr[i-1];
  Par_arr[1] := par.v;
  PARav.v := 0;
  for i := 1 to MAxParDays do
    Parav.v := Parav.v+par_arr[i];
  parav.v := parav.v/MaxParDays;

  SLA.v := 0.059*power(parav.v, -0.851)*1e4;
  if sla.v < 0.0 then
    sla.v := 100;

  LAI.c := DMleaf.c*sla.v/10000.0;
  end;
end;

procedure TBkGrowth.CalcRates;

var
  i : integer;

begin
  inherited calcrates;
  TS.c := Temp.v;
  Growthduration.c := SM_GlobMod.Time.c;
  If RootOptions = Roots then
    Root_growth;
  If RootOptions = Roots then
     AssiToShoot.v := AssiToShoot.v+DMTrans.v
  else begin
     AssitoShoot.v := AssiFlow.v+DMTrans.v;
  end;
  DMTrans.v := 0.0;
  CurdGrowth;
  GetCurdDiameter;
  AssiToVeg := AssiToShoot.v-AssiToGen.v;
  leaf_stem_growth;
  GetLAI;

// Höhenfunktion nach Röhrig  S. 74
  CropHeight.v := DMStem.v*0.882/(19.49+DmStem.v);
  PlantDiameter.v := DMVeg.v*0.656/(46.31+DMVeg.v);
  RelGroundCov.v := min(sqr(PlantDiameter.v)*Pi/4*Bstd.v,1.0);

  CalcDMChange;

If Vern.v <1.0 then begin
 for i := AvDays downto 2 do
    rgr_arr[i] := rgr_arr[i-1];
  rgr_arr[1] := rgrPlant.v;
  rgrPlantav.v := 0;
  for i := 1 to AvDays do
    rgrPlantav.v := rgrPlantav.v+rgr_arr[i];
  rgrPlantav.v := rgrPlantav.v/AvDays;
end;
  If (FAutostop = true) and (CurdDiameter.v > Max_CD.v) then
    sm_globmod.Modelend := true;
  If (FAutostop = true) and (GrowthDuration.v > 110) then
    sm_globmod.Modelend := true;

end;


procedure TBkGrowth.Integrate;

begin
  inherited integrate;
  slaav.v := lai.v/dmleaf.v*10000;

end;

procedure Register;

begin
  RegisterComponents('CauliSim', [TBkGrowth]);
end;

end.
