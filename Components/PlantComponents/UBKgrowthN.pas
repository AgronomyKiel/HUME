unit UBkGrowthN;

interface

uses
 UState, Umod, UBKGrowth, IniFiles, classes;

type
  real = double;

TBkGrowthN = Class(TBKGrowth)

  public
    NStem  : TState;            // NMenge Stengel [g N/m2]
    NLeaf  : TState;
    NGen   : TState;            // N-Menge in generativen Organen [g N/m2]
    NRoot  : TState;            //  N-Menge in Wurzeln [g N/m2]
    NTapRoot  : TState;
    NFineRoot : Tstate;
    NVeg   : TState;
    NShoot : TState;
    NTotal : TState;
    PlantNDemand : TVar;
    rgrStem,
    rgrLeaf,
    rgrGen,
    rgrTapRoot,
    rgrFineRoot : TVar;

    NOptStem,
    NOptLeaf,
    NOptGen,
    NOptTapRoot,
    NOptFineRoot  : TVar;

    NPrStem,
    NPrLeaf,
    NPrGen,
    NPrTapRoot,
    NPrFineRoot  : TVar;

    NTranslocation,
    MaxNTranslocation : TVar;
    MaxDailyNTrans : Tpar;

    fflrgrred : TPar;   // Reduktion der Kopfwachstumsrate bei N-Mangel

    MaxFineRootFrac : TPar;

    ActNUptake   : TExternV;
    MAxNUptake    : TExternV;

   Constructor create(AOwner: TComponent); override;

   procedure CreateAll; override;
   procedure Set_GlobMod(value:TMod); override;

   procedure calcrates; override;

   procedure Init(var GlobMod:Tmod); override;

   procedure integrate; override;

   private
  NDemandStem,
  NDemandLeaf,
  NDemandGen,
  NDemandTapRoot,
  NDemandFineRoot,
  LastNDemandStem,
  LastNDemandLeaf,
  LastNDemandGen
                : real;

  Function GetNOptStem(DMStem:real):real;
  Function GetNOptLeaf(DMLeaf:real):real;
  Function GetNOptGen(DMGen:real):real;
  Function GetNOptTapRoot(DMTapRoot:real):real;
  published
  property St_NStem : TState read NStem write NStem;
  property St_NLeaf : TState read NLeaf write NLeaf;
  Property St_NGen : Tstate read NGen write NGen;
  property St_NRoot : TState read NRoot write NRoot;
  property St_NTapRoot : TState read NTapRoot write NTapRoot;
  property St_NFineRoot : TState read NFineRoot write NFineRoot;
  property St_NShoot : TState read NShoot write NShoot;
  property St_NVeg : TState read NVeg write NVeg;
  property St_NTotal : TState read NTotal write NTotal;

  property Var_PlantNDemand : TVar read PlantNDemand write PlantNDemand;


  property  Var_rgrStem : TVar read rgrStem write rgrStem;
  property  Var_rgrLeaf : TVar read rgrLeaf write rgrLeaf;
  property  Var_rgrGen  : TVar read rgrGen write rgrGen;

  property  Var_NOptStem : TVar read NOptStem write NOptStem;
  property  Var_NOptLeaf : TVar read NOptLeaf write NOptLeaf;
  property  Var_NOptGen  : TVar read NOptGen write NOptGen;

  property  Var_NPrStem  : TVar read NPrStem write NPrStem;
  property  Var_NPrLeaf  : TVar read NPrLeaf write NPrLeaf;
  property  Var_NPrGen   : TVar read NPrGen write NPrGen;

  property Var_NTranslocation : TVar read NTranslocation write NTranslocation;
  property Var_MaxNTranslocation : Tvar read MaxNTranslocation write MaxNTranslocation;
  property Par_MaxDailyNTrans : TPar read MaxDailyNTrans write MaxDailyNTrans;
  property Par_MaxFineRootFrac : TPar read MaxFineRootFrac write MaxFineRootFrac;
  property Par_fflrgrRed : TPar read fflrgrRed write fflrgrRed;


  property  Ex_ActNUptake  : TExternV read ActNUptake write ActNUptake;
  property  Ex_MAxNUptake  : TExternV read MAxNUptake write MAxNUptake;


 end;

procedure Register;

implementation

uses math;

function max(a, b: real):real;

begin
  if a>b then result := a
  else result := b;

end;
function min(a, b: real):real;

begin
  if a<b then result := a
  else result := b;

end;


constructor TBkGrowthN.create (AOwner : Tcomponent);

begin

  inherited create(AOwner);
  CreateAll;

end;


procedure TBkGrowthN.CreateAll;

begin
inherited CreateAll;
  StateCreate('NStem', '[g N .m-2]', 0.0, false, NStem);
  StateCreate('NLeaf', '[g N .m-2]', 0.0, false, NLeaf);
  StateCreate('NCurd', '[g N .m-2]', 0.0, false, NGen);
  StateCreate('NRoot',  '[g N .m-2]', 0.0, false,NRoot);
  StateCreate('NTapRoot',  '[g N .m-2]', 0.0,  false, NTapRoot);
  StateCreate('NFineRoot',  '[g N .m-2]', 0.0, false, NFineRoot);
  Statecreate('TotalPlantNitrogen', '[gN /(m2)]', 0.0,true, NTotal);

  StateCreate('Nveg',  '[g N .m-2]', 0.0,   false, NVeg);
  StateCreate('NShoot',  '[g N .m-2]', 0.0,   false, NShoot);

  VarCreate('rgrLeaf',  '[g.g-1]', 0.0,   false, rgrLeaf);
  VarCreate('rgrStem',  '[g.g-1]', 0.0,   false, rgrstem);
  VarCreate('rgrGen',  '[g.g-1]', 0.0,   false, rgrGen);
  VarCreate('rgrFineRoot',  '[g.g-1]', 0.0,   false, rgrFineRoot);
  VarCreate('rgrTapRoot',  '[g.g-1]', 0.0,   false, rgrTapRoot);

  VarCreate('NOptStem',  '[%N/DM]', 3.0,  false, NOptStem);
  VarCreate('NOptLeaf',  '[%N/DM]', 5.0,  false, NOptLeaf);
  VarCreate('NOptGen',  '[%N/DM]', 5.0,   false, NOptGen);
  VarCreate('NOptTapRoot',  '[%N/DM]', 2.6, false, NOptTapRoot);
  VarCreate('NOptFineRoot',  '[%N/DM]', 1, false, NOptFineRoot);

  VarCreate('NPrStem',  '[%N/DM]', 3.0,  false, NPrStem);
  VarCreate('NPrLeaf',  '[%N/DM]', 5.0,  false, NPrLeaf);
  VarCreate('NPrGen',  '[%N/DM]', 5.0,   false, NPrGen);
  VarCreate('NPrTapRoot',  '[%N/DM]', 2.6,   false, NPrTapRoot);
  VarCreate('NPrFineRoot',  '[%N/DM]', 1,   false, NPrFineRoot);

  Varcreate('PlantNDemand', '[gN /(m2*d-1)]', 0.0,true, PlantNDemand);

  Varcreate('NTranslocation', '[gN /(m2*d-1)]', 0.0,true, NTranslocation);
  Varcreate('MAxNTranslocation', '[gN /(m2*d-1)]', 0.0,true, MaxNTranslocation);
  Parcreate('MaxDailyNTrans', '[gN /(gN*d-1)]', 0.01, MaxDailyNTrans);

  Parcreate('MaxFineRootFrac', '[-]', 0.15, MaxFineRootFrac);

  Parcreate('fflrgrRed', '[-]', 0.3, fflrgrred);

  ExternVcreate('ActNUptake', '[kg N.ha-1.d-1]', statefield, ActNUptake);
  ExternVcreate('MaxNUptake', '[kg N.ha-1.d-1]', statefield, MaxNUptake);

end;

procedure TBkGrowthN.Set_GlobMod(value:TMod);

begin
inherited Set_GlobMod(Value);
CreateAll;
end;


// Vorläufige Version der Ermittlung der optimalen N-Gehalte der Organe
// Daten aus N-Versuch 1997 N-Stufe 300 u. 450 kg N


Function TBkGrowthN.GetNOptStem(DMStem:real):real;

begin
  result := -0.0187*DMStem+ 3.4982;
end;

Function TBkGrowthN.GetNOptLeaf(DMLeaf:real):real;
begin
  result := -0.0124*DMLeaf+ 5.69;
end;

Function TBkGrowthN.GetNOptGen(DMGen:real):real;

begin
  result := 6.3378*exp(-0.0084*DMGen);

end;

Function TBkGrowthN.GetNOptTapRoot(DMTapRoot:real):real;

begin
  result := 2.6046*exp(-0.0291*DMTapRoot);

end;


procedure TBkGrowthN.CalcRates;

var
  SumOfRgr,
  MaxUptake : real;
  CurdSatisf,
  LeafSatisf,
  StemSatisf,
  FineRootSatisf,
  TapRootSatisf : boolean;


begin
  fflrgr.v := fflrgr0.v-fflrgrRed.v*(NoptLeaf.v-NPrLeaf.v);
  inherited calcrates;
  MaxUptake := MAxNUptake.v/10;
  RgrLeaf.v := DMLeaf.c/DMLeaf.V;
  rgrStem.v := DMStem.c/DMStem.v;
  rgrFineRoot.v := DMFineRoot.c/DMFineRoot.v;
  rgrTapRoot.v  := DMTapRoot.c/DMTapRoot.v;
  If DMGen.v> 0.0 then
    rgrGen.v  := DMGen.c/DMGen.v
  else RGRGen.v := 0.0;
  SumOfRgr := RGRStem.v+rgrLeaf.v+rgrGen.v+rgrFineRoot.v+rgrTapRoot.v;

  NoptStem.v := GetNoptStem((DMStem.v+DMStem.c*GlobTime.c)/Bstd.v);
  NoptLeaf.v := GetNoptLeaf((DMLeaf.v+DMLeaf.c*GlobTime.c)/Bstd.v);
  NoptGen.v  := GetNOptGen(( DMGen.v+ DMGen.c* GlobTime.c)/Bstd.v);
  NOptTapRoot.v := GetNOptTapRoot(( DMTapRoot.v+ DMTapRoot.c* GlobTime.c)/Bstd.v);
  NOptFineRoot.v := 1;

  NDemandStem := max(0,((DMStem.v+DMStem.c*GlobTime.c)*NOptStem.v/100-(NSTem.v))/GlobTime.c);
  NDemandLeaf := max(0,((DMLeaf.v+DMLeaf.c*GlobTime.c)*NOptLeaf.v/100-(NLeaf.v))/GlobTime.c);
  NDemandTapRoot := max(0,((DMTapRoot.v+ DMTapRoot.c* GlobTime.c)*NOptTapRoot.v/100-(NTapRoot.v))/GlobTime.c);
  NDemandFineRoot := max(0,((DMFineRoot.v+ DMFineRoot.c* GlobTime.c)*NOptFineRoot.v/100-(NFineRoot.v))/GlobTime.c);

  If DMGen.v > 0.0 then
    NDemandGen  := max(0,((DMGen.v+ DMGen.c* GlobTime.c)*NOptGen.v /100-(NGen.v))/GlobTime.c);

  If (NGen.v = 0.0) and (DMGen.c > 0.0) then begin
    NGen.v := DMGen.c*GlobTime.c*GetNoptGen(DMGen.c*globTime.c/Bstd.v)/100;
    NGen.c := NGen.v;
    NDemandGen := NGen.c;
  end;

  PlantNDemand.v :=   max(0,NdemandStem
                    + NDemandLeaf+ NDemandGen+NDemandTapRoot+NDemandFineRoot);

  If PlantNDemand.v > 0.0 then begin
    If MAxUptake>=PlantNDemand.v then begin
      NStem.c := NDemandStem;
      NLeaf.c := NDemandLeaf;
      NGen.c  := NDemandGen;
      NTapRoot.c := NDemandTapRoot;
      NFineRoot.c := NDemandFineRoot;
      Frac_FRoots.v := Frac_FRoots0.v;
    end else begin
      if sumofrgr > 0.0 then begin
        MaxNTranslocation.v := MaxDailyNTrans.v*NVeg.v;
        If MAxUptake*(RgrGen.v/SumOfRgr) > NDemandGen then begin
           NGen.c := NDemandGen;
           CurdSatisf := true;
           SumOfRgr := SumOfRgr-RGRGen.v;
           MaxUptake := MaxUptake-NDemandGen;
        end else
          CurdSatisf := false;

        If MAxUptake*(RgrLeaf.v/SumOfRgr) > NDemandLeaf then begin
           NLeaf.c := NDemandLeaf;
           LeafSatisf := true;
           SumOfRgr := SumOfRgr-RGRLeaf.v;
           MaxUptake := MaxUptake-NDemandLeaf;
        end else
          LeafSatisf := false;

        If MAxUptake*(RgrStem.v/SumOfRgr) > NDemandStem then begin
           NStem.c := NDemandStem;
           StemSatisf := true;
           SumOfRgr := SumOfRgr-RGRStem.v;
           MaxUptake := MaxUptake-NDemandStem;
        end else
          StemSatisf := false;

        If MAxUptake*(RgrFineRoot.v/SumOfRgr) > NDemandFineRoot then begin
           NFineRoot.c := NDemandFineRoot;
           FineRootSatisf := true;
           SumOfRgr := SumOfRgr-RGRFineRoot.v;
           MaxUptake := MaxUptake-NDemandFineRoot;
        end else
          FineRootSatisf := false;

        If MAxUptake*(RgrTapRoot.v/SumOfRgr) > NDemandTapRoot then begin
           NTapRoot.c := NDemandTapRoot;
           TapRootSatisf := true;
           SumOfRgr := SumOfRgr-RGRTapRoot.v;
           MaxUptake := MaxUptake-NDemandTapRoot;
        end else
          TapRootSatisf := false;

        If CurdSatisf = false then begin

          NLeaf.v := NLeaf.v-0.01*NLeaf.v*GlobTime.c;
          If MaxNTranslocation.v+MaxUptake*(RgrGen.v/SumOfRgr) > NDemandGen then begin
            NGen.c := NDemandGen;
            NTranslocation.v := NDemandGen-MAxUptake*(RgrGen.v/SumOfRgr);
          end else begin
            NGen.c := MAxUptake*(RgrGen.v/SumOfRgr)+MaxNTranslocation.v;
            NTranslocation.v := MaxNTranslocation.v;
          end;
          NLeaf.v := NLeaf.v-NTranslocation.v*NLeaf.v/NVeg.v*GlobTime.c;
          NStem.v := NStem.v-NTranslocation.v*NStem.v/NVeg.v*GlobTime.c;;
          NTapRoot.v := NTapRoot.v-NTranslocation.v*NTapRoot.v/NVeg.v*GlobTime.c;;
          NFineRoot.v := NFineRoot.v-NTranslocation.v*NFineRoot.v/NVeg.v*GlobTime.c;;

        end;

        If LeafSatisf = false then
          NLeaf.c := MAxUptake*(RgrLeaf.v/SumOfRgr);

        If StemSatisf = false then
          NStem.c := MAxUptake*(RgrStem.v/SumOfRgr);

        If FineRootSatisf = false then
          NFineRoot.c := MAxUptake*(RgrFineRoot.v/SumOfRgr);

        If TapRootSatisf = false then
          NTapRoot.c := MAxUptake*(RgrTapRoot.v/SumOfRgr);

        Frac_FRoots.v := Frac_Froots.v +0.2*(1-Frac_FRoots.v/MaxFineRootFrac.v);
      end else begin

        NLeaf.c     := 0.0;
        NGen.c      := 0.0;
        NLeaf.c     := 0.0;
        NTapRoot.c  := 0.0;
        NFineRoot.c := 0.0;
      end;
    end

  end else begin
    PlantNDemand.v := 0.0;
    NStem.c := 0;
    NLeaf.c := 0;
    NGen.c := 0;
    NTapRoot.c := 0.0;
    NFineRoot.c := 0.0;
  end;

  NVeg.c   := Nstem.c + NLeaf.c + NRoot.c;
  NRoot.c  := NTapRoot.c + NFineRoot.c;
  NShoot.c := Nstem.c + NLeaf.c + Ngen.c;
  NTotal.c := Nstem.c + NLeaf.c + Ngen.c + NRoot.c;


end;

procedure TBkGrowthN.integrate;

begin
  inherited integrate;
  If DMStem.v > 0.0 then
    NPrStem.v := NStem.v/DMStem.v*100;
  If DMLeaf.v > 0.0 then
    NPrLeaf.v := NLeaf.v/DMLeaf.v*100;
  If DMGen.v > 0.0 then
    NPrGen.v := NGen.v/DMGen.v*100;
  If DMTapRoot.V > 0.0 then
    NPrTapRoot.v := NTapRoot.v/DMTapRoot.v*100;
  If DMFineRoot.v > 0.0 then
    NPrFineRoot.v := NFineRoot.v/DMFineRoot.v*100;

end;

procedure TBkGrowthN.Init(var GlobMod: Tmod);

begin
  Inherited init(GlobMod);
  NStem.v := DMStem.v*GetNoptStem(DMStem.v/BSTD.v)/100;
  NLeaf.v := DMLeaf.v*GetNoptLeaf(DMLeaf.v/BStd.v)/100;
  NTapRoot.v := DMTapRoot.v*GetNoptTapRoot(DMTapRoot.v/Bstd.v)/100;
  Nfineroot.v := DMFineRoot.v *0.01;

  NVeg.v := NStem.v+NLeaf.v+NTapRoot.v+NFineRoot.v;
  NDemandLeaf := 0.0;
  NDemandGen := 0.0;
  NDemandStem := 0.0;
  NPrSTem.v := GetNoptStem(DMStem.v/BSTD.v);
  NPrLeaf.v := GetNoptLeaf(DMLeaf.v/BStd.v);
  NPrGen.v  := GetNoptGen(DMGen.v/Bstd.v);
end;

procedure Register;
begin
  RegisterComponents('CauliSim', [TBKGrowthN]);
end;



end.
