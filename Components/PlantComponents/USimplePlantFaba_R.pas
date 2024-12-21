unit USimplePlantFaba_R;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, USimplePlant, UState;

type
  TSimplePlantFaba_R = class(TSimplePlant)
  private
    fFineRoot0 : TPar;
    FFineRootDec : TPar;
    FFineroot    : TVar;
    TempSum      : TState;
    PlantNDemand : tVar;
    NTotal       : TExternV;
    MAxNUptake   : TExternV;
    NShoot,
    NFix      : TState;
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
   procedure createAll; override;
   procedure CalcRates; override;
    { Public-Deklarationen }
  published
  property Par_FFineRoot : TVar read FFineRoot write FFineroot;
  property Par_FFineRoot0 : TPar read FFineRoot0 write FFineroot0;
  property Par_FFineRootDec : TPar read FFineRootDec write FFinerootDec;
  property Ex_NTotal        : TExternV read NTotal write NTotal;
  property Ex_MAxNUptake    : TExternV read MaxNUptake write MaxNUptake;
  property Var_PlantNDemand : Tvar read PlantNDemand write PlantNDemand;
  property St_TempSum        : TState read TempSum write Tempsum;
  property St_NShoot : TState read NShoot write NShoot;
  property St_NFix : TState read NFix write NFix;
    { Published-Deklarationen }
  end;

procedure Register;

implementation

uses
  UModUtils;

procedure TSimplePlantFaba_R.createAll;

begin
  inherited CreateAll;
  VarCreate('fFineRoot', '[-]', 0.4, false, fFineroot);
  VarCreate('PlantNDemand', '[-]', 0.0, false, PlantNDemand);
  ParCreate('fFineRoot0', '[-]', 0.4, fFineroot0);
  ParCreate('fFineRootDec', '[-]', 0.0002, fFinerootdec);
  StateCreate('TempSum', '[°C.d]', 0, true, TempSum);
  StateCreate('NShoot', '[gN.m-2]', 0, true, NShoot);
  StateCreate('NFix', '[gN.m-2]', 0, true, NFix);
  ExternVcreate('NTotal', '[gN.m-2]', RateField, NTotal);
  ExternVcreate('MaxNUptake', '[kg N.ha-1.d-1]', statefield, MaxNUptake);

end;

procedure TSimplePlantFaba_R.CalcRates;

begin
//  inherited CalcRates;
  If GlobTime.v >= SowingDate.v then begin
    If Temp.v > 0.0 then
      TempSum.c := Temp.v
    else TempSum.c := 0.0;

    FFineRoot.v := fFineRoot0.v-FFinerootDec.v*TempSum.v;
    If FFineRoot.v<0 then FFineroot.v := 0.0;
    DMFineRoot.C   := Assiflow.v * (FFineRoot.v)/(1-FFineRoot.v);
    DMLeaf.c      := Assiflow.v;
    PlantNDemand.v := NTotal.v;
    NFix.c         := max(0, PlantNDemand.v-MaxNUptake.v/10);
    NShoot.c       := PlantNDemand.v;
    CropHeight.c   := 0.00001*Assiflow.v;
  end;

end;

procedure Register;
begin
  RegisterComponents('HUME', [TSimplePlantFaba_R]);
end;

end.
