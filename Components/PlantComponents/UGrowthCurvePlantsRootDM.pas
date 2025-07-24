unit UGrowthCurvePlantsRootDM;

interface

uses
  Classes,UGrowthCurvePlant, UMod, UState;

type
  real = double;

  TGrowthCurvePlantRootDM = class(TGrowthCurvePlant)
  private
    fFineRoot0: TPar;
    FFineRootDec: TPar;
    FFineroot: TVar;
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
    procedure createAll; override;
//    procedure init(var GlobMod: TMod); override;
    procedure CalcRates; override;
  published
    property Var_FFineRoot: TVar read FFineroot write FFineroot;
    property Par_FFineRoot0: TPar read fFineRoot0 write fFineRoot0;
    property Par_FFineRootDec: TPar read FFineRootDec write FFineRootDec;

  end;


  procedure Register;


implementation


procedure TGrowthCurvePlantRootDM.createAll;

begin
  inherited CreateAll;
  VarCreate('fFineRoot', '[-]', 0.4, false, fFineroot);
  ParCreate('fFineRoot0', '[-]', 0.4, fFineroot0);
  ParCreate('fFineRootDec', '[-]', 0.0002, fFinerootdec);
end;

procedure TGrowthCurvePlantRootDM.CalcRates;

var
  Assiflow: real;
  AssiToFineRoot: real;

begin
  inherited CalcRates;

  FFineroot.v := fFineRoot0.v - FFineRootDec.v * TSum.v; // old version

  If FFineroot.v < 0 then
    FFineroot.v := 0.0;

  Assiflow := StateVars[DM].C;
  DMFineRoot.C := Assiflow * (FFineroot.v) / (1 - FFineroot.v);
  AssiToFineRoot := DMFineRoot.C;

end;

procedure Register;
begin
  RegisterComponents('Simulation', [TGrowthCurvePlantRootDM]);
end;

end.
