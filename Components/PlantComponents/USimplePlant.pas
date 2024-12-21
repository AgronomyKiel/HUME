unit USimplePlant;

interface

uses
 UState,
 Umod,
 IniFiles,
 UAbstractPlant,
// vcl.dialogs,
 Classes;

const
  Tref = 20;
  AvDays = 5;

type
  real = double;

  TRespOptions = (NoResp, MaintResp);
  TRootOptions = (No_Roots, Roots);


TSimplePlant = Class(TAbstractPlant)
  private
  protected


  public
    TotalDryMatter  : TState;

    DMStem  : TState;         // Trockenmasse des Stengels
    DMLeaf  : TState;         // Trockenmasse der gesamten Blätter
    DMGreenLeaf : TState;     // Trockenmasse der grünen Blätter
    DMsenLeaf : TState;       // Trockenmasse der senseszenten Blätter
    DMabortedLeaf : TState;   // Trockenmasse der abgeworfenen Blätter
    DMGen   : TState;
    DMRoot  : TState;
    DMTapRoot : TState;
    DMFineRoot : TState;
    DMVeg   : TState;
    DMShoot : TState;
    CropHeight : TState;

    AssiToStem : Tvar;
    AssiToLeaf : Tvar;
    AssiToGen  : Tvar;
    AssiToFineRoot : TVar;
    AssiToTapRoot : TVar;
    AssiToShoot : TVar;
    StemGrowthRespiration : TVar;
    StemMaintRespiration  : TVar;
    LeafGrowthRespiration : TVar;
    LeafMaintRespiration  : TVar;
    GenGrowthRespiration  : TVar;
    GenMaintRespiration   : TVar;
    FineRootGrowthRespiration  : TVar;
    FineRootMaintRespiration   : TVar;
    TapRootGrowthRespiration  : TVar;
    TapRootMaintRespiration   : TVar;
    SLA     : TVar;
    SLAav   : TVar;
    Teff    : TVar;
    rgrPlant : TVar; // relative growth rate of total plant dry matter
    rgrPlantav : Tvar; // running average of relative plant growth rate

    AssiFlow  : TExternV;
    Temp           : TExternV;
//    Trans          : TExternV; // Transmission


    MaintCoeffLeaf : TPar;
    MaintCoeffStem : TPar;
    MaintCoeffGen  : TPar;
    MaintCoeffFineRoot : TPar;
    MaintCoeffTapRoot  : TPar;
    Q10            : TPar;

    SowingDate     : TPar;
    HarvestDate    : TPar;
    RespOptions    : TRespOptions;
    RootOptions : TRootOptions;


   procedure calcDMChange;
   procedure integrate; override;
   procedure CreateAll; override;



   published
   property St_CropHeight : TState read CropHeight write CropHeight;
   property St_TotaldryMatter: TState read Totaldrymatter write Totaldrymatter;
   property St_DMShoot: TState read DMShoot write DMShoot;

   property St_DMLeaf : TState read DMLeaf write DMLeaf;
   property St_DMStem : Tstate read DMStem write DMStem;

   property St_DMGen  : Tstate read DMGen write DMGen;
   property St_DMveg  : Tstate read DMveg write DMveg;
   property St_DMroot  : Tstate read DMroot write DMroot;
   property St_DMTapRoot  : Tstate read DMTapRoot write DMTapRoot;
   property St_DMFineRoot  : Tstate read DMFineRoot write DMFineRoot;
   property St_DMGreenLeaf : TState read DMGreenLeaf write DMGreenLeaf;
   property St_DMSenLeaf : TState read DMSenLeaf write DMSenLeaf;

   property Ex_Temp : TexternV read Temp write Temp;
   property Ex_AssiFlow : TexternV read AssiFlow write AssiFlow;

   property Par_MaintCoeffLeaf : TPar read MaintCoeffLeaf write MaintCoeffLeaf;
   property Par_MaintCoeffStem : TPar read MaintCoeffStem write MaintCoeffStem;
   property Par_MaintCoeffGen  : TPar read MaintCoeffGen write MaintCoeffGen;
   property Par_MaintCoeffFineRoot : TPar read MaintCoeffFineRoot write MaintCoeffFineRoot;
   property Par_MaintCoeffTapRoot : TPar read MaintCoeffTapRoot write MaintCoeffTapRoot;
   property Par_Q10            : TPar read Q10 write Q10;

   property Par_SowingDate : TPar read SowingDate write SowingDate;
   property Par_HarvestDate : TPar read HarvestDate write HarvestDate;

   property Var_AssiToStem : Tvar read AssiToStem write AssiToStem;
   property Var_AssiToLeaf : Tvar read AssiToLeaf write AssiToLeaf;
   property Var_AssiToGen  : Tvar read AssiToGen write AssiToGen;
   property Var_AssiToFineRoot  : Tvar read AssiToFineRoot write AssiToFineRoot;
   property Var_AssiToTapRoot  : Tvar read AssiToTapRoot write AssiToTapRoot;
   property Var_AssiToShoot  : Tvar read AssiToShoot write AssiToShoot;
   property Var_StemGrowthRespiration : TVar read StemGrowthRespiration write StemGrowthRespiration;
   property Var_StemMaintRespiration  : TVar read StemMaintRespiration write StemMaintRespiration;
   property Var_LeafGrowthRespiration : TVar read LeafGrowthRespiration write LeafGrowthRespiration;
   property Var_LeafMaintRespiration  : TVar read LeafMaintRespiration write LeafMaintRespiration;
   property Var_GenGrowthRespiration  : TVar read GenGrowthRespiration write GenGrowthRespiration;
   property Var_GenMaintRespiration   : TVar read GenMaintRespiration write GenMaintRespiration;
   property Var_FineRootGrowthRespiration   : TVar read FineRootGrowthRespiration write FineRootGrowthRespiration;
   property Var_TapRootGrowthRespiration   : TVar read TapRootGrowthRespiration write TapRootGrowthRespiration;
   property Var_FineRootMaintRespiration   : TVar read FineRootMaintRespiration write fineRootMaintRespiration;
   property Var_TapRootMaintRespiration   : TVar read TapRootMaintRespiration write TapRootMaintRespiration;
   property Var_SLA     : TVar read SLA write SLA;
   property Var_SLAav   : TVar read SLAav write SLAav;
   property Var_Teff    : TVar read Teff write Teff;



   property Opt_Respiration : TRespOptions read RespOptions write RespOptions;
   property Opt_Root     : TRootOptions read RootOptions write RootOptions;

 end;


implementation

uses math;


procedure TSimplePlant.CreateAll;

begin
  inherited createAll;
  StateCreate('TotalDryMatter' ,'[g/m2]', 0.0, false, TotalDryMatter);
  StateCreate('DMShoot' ,'[g/m2]', 0.0, false, DMShoot);
  StateCreate('DMStem', '[g.m-2]', 0.0, true, DMStem);

  StateCreate('DMLeaf', '[g.m-2]', 0.0, true,DMLeaf);
  StateCreate('DMsenLeaf', '[g.m-2]', 0.0, true, DMsenLeaf);
  StateCreate('DMgreenLeaf', '[g.m-2]', 0.0, true, DMgreenLeaf);
  StateCreate('DMabortedLeaf', '[g.m-2]', 0.0, true, DMabortedLeaf);

  StateCreate('DMCurd', '[g.m-2]', 0.0, true,DMGen);
  StateCreate('DMveg',  '[g.m-2]', 0.0, true,DMVeg);
  StateCreate('DMRoot',  '[g.m-2]', 0.0, false,DMRoot);
  StateCreate('DMTapRoot',  '[g.m-2]', 0.0, false,DMTapRoot);
  StateCreate('DMFineRoot',  '[g.m-2]', 0.0, false,DMFineRoot);
  StateCreate('CropHeight',  '[m]', 0.01, true, CropHeight);

  VarCreate('AssiToStem', '[]',0.2, false, AssiToStem);
  VarCreate('AssiToLeaf', '[]',0.8, false, AssiToLeaf);
  VarCreate('AssiToGen', '[]',0.0, false, AssiToGen);
  VarCreate('AssiToFineRoot', '[]',0.0, false, AssiToFineRoot);
  VarCreate('AssiToTapRoot', '[]',0.0, false,  AssiToTapRoot);
  VarCreate('AssiToShoot', '[]',0.0, false, AssiToShoot);
  VarCreate('StemGrowthRespiration', '[]',0.0, false, StemGrowthRespiration);
  VarCreate('StemMaintRespiration', '[]',0.0, false, StemMaintRespiration);
  VarCreate('LeafGrowthRespiration', '[]',0.0, false, LeafGrowthRespiration);
  VarCreate('LeafMaintRespiration', '[]',0.0, false, LeafMaintRespiration);
  VarCreate('GenGrowthRespiration', '[]',0.0, false, GenGrowthRespiration);
  VarCreate('GenMaintRespiration', '[]',0.0, false, GenMaintRespiration);
  VarCreate('FineRootGrowthRespiration', '[]',0.0, false, fineRootGrowthRespiration);
  VarCreate('TapRootGrowthRespiration', '[]',0.0, false, TapRootGrowthRespiration);
  VarCreate('FineRootMaintRespiration', '[]',0.0, false, FineRootMaintRespiration);
  VarCreate('TapRootMaintRespiration', '[]',0.0, false, TapRootMaintRespiration);
  VarCreate('SLA', '[cm2/g]', 120, false, SLA);
  VarCreate('SLAav', '[cm2/g]', 120, false, SLAav);

  VarCreate('Teff', '[-]', 120, false, Teff);
  VarCreate('rgrPlant', '[g/g/d]', 0, false, rgrPlant);
  VarCreate('rgrPlantav', '[g/g/d]', 0, false, rgrPlantav);
  ParCreate('MainCoeffLeaf', '[g.g-1]', 0.03, MaintCoeffLeaf);
  ParCreate('MainCoeffStem', '[g.g-1]', 0.01, MaintCoeffStem);
  ParCreate('MainCoeffGen', '[g.g-1]', 0.02,  MaintCoeffGen);
  ParCreate('MainCoeffFineRoot', '[g.g-1]', 0.015,  MaintCoeffFineRoot);
  ParCreate('MainCoeffTapRoot', '[g.g-1]', 0.015,  MaintCoeffTapRoot);
  ParCreate('Q10', '[]', 1.8,  Q10);
  ParCreate('SowingDate', '[]', 0.0,  SowingDate);
  ParCreate('HarvestDate', '[]', 1e6,  HarvestDate);

  ExternVcreate('Assiflow', '[g/(m2*d)]', StateField, AssiFlow);
  ExternVcreate('Temp', '[°C]', stateField, temp);
//  ExternVcreate('Trans', '[°C]', stateField, trans);

end;


procedure TSimplePlant.calcDMChange;

begin
  Teff.v := power(Q10.v, (Temp.v-Tref)/10);

  If RespOptions = MaintResp then begin
    StemMaintRespiration.v := DMStem.v*MaintCoeffStem.v*Teff.v;
    LeafMaintRespiration.v := DMleaf.v*MaintCoeffleaf.v*Teff.v;
    GenMaintRespiration.v  := DMgen.v*MaintCoeffGen.v*Teff.v;
    If RootOptions = Roots then begin
      FineRootMaintRespiration.v  := DMFineRoot.v*MaintCoeffFineRoot.v*Teff.v;
      TapRootMaintRespiration.v  := DMTapRoot.v*MaintCoeffTapRoot.v*Teff.v;
    end;
  end else begin
    StemMaintRespiration.v := 0.0;
    LeafMaintRespiration.v := 0.0;
    GenMaintRespiration.v  := 0.0;
    FineRootMaintRespiration.v := 0.0;
    TapRootMaintRespiration.v := 0.0;
  end;


  DMStem.C := AssiToStem.v
              -(StemGrowthRespiration.v+StemMaintRespiration.v);
  DMLeaf.C := AssiToLeaf.v
              -(LeafGrowthRespiration.v+LeafMaintRespiration.v);

  DMGen.C := AssiToGen.v
              -(GenGrowthRespiration.v+GenMaintRespiration.v);
  If RootOptions = Roots then begin
    DMFineRoot.c := AssiToFineRoot.v
                -(FineRootGrowthRespiration.v+FineRootMaintRespiration.v);
    DMTapRoot.c  := AssiToTapRoot.v
                -(TapRootGrowthRespiration.v+TapRootMaintRespiration.v);


    DMRoot.c         := DMFineRoot.c+DMTapRoot.c;
  end else DMRoot.c := 0.0;
  DMShoot.c := 0.0;

end;

procedure TSimplePlant.Integrate;


begin
  inherited integrate;
//  DMShoot.v        := dmleaf.v+dmstem.v+dmgen.v;
  DMVeg.v          := DMroot.v+dmleaf.v+dmstem.v;
  TotalDrymatter.v := DMroot.v+dmleaf.v+dmstem.v+dmgen.v;
  Totaldrymatter.c := DMroot.c+dmleaf.c+dmstem.c+dmgen.c;
  if Totaldrymatter.v>0.0 then
    rgrPlant.v := (DMroot.c+dmleaf.c+dmstem.c+dmgen.c)/Totaldrymatter.v
  else
   rgrPlant.v := 0.0;

end;

end.
