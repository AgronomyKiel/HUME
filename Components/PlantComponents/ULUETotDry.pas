unit ULUETotDry;

interface

uses UState, Umod, IniFiles, classes, Math,
  UDryMatProdComp;

type
  real = double;

  TLUETotDry = Class(TDrymatterproduction)

  private

  protected
    procedure CreateAll; override;

  public
    LUE0: TPar;
    LUE_dec: TPar;
    cluster_f: TVar;
    Int_Corr: boolean;
    TransRatio: TExternV; // Transpiration ratio
    pfW: TPar;
    SWDF: TVar;

    // RelGroundCov    : TExternV;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure Init(Var GlobMod: TMod); override;
  published
    property Par_LUE0: TPar read LUE0 write LUE0;
    property Par_LUEdec: TPar read LUE_dec write LUE_dec;
    property Par_pfW: TPar read pfW write pfW;
    property Var_SWDF: TVar read SWDF write SWDF;
    property Opt_intCorr: boolean read Int_Corr write Int_Corr;
    property Ex_TransRatio: TExternV Read TransRatio Write TransRatio;

    // property Ex_RelGroundCover : TExternV read RelGroundCov write RelGroundCov;

  end;

procedure Register;

implementation

uses
  UModUtils;

procedure TLUETotDry.CreateAll;

begin
  inherited CreateAll;
  ParCreate('LUE0', '[-]', 5, LUE0);
  ParCreate('LUE_dec', '[-]', 0.2, LUE_dec);
  VarCreate('Cluster_f', '[-]', 1.0, false, cluster_f);
  ParCreate('pfW', '[-]', 1, pfW);
  VarCreate('SWDF', '[-]', 1.0, false, SWDF);
  ExternVCreate('TransRatio', '[-]', StateField, TransRatio);

  // ExternVCreate('RelGroundCov', '[-]', StateField, RelGroundCov);
end;

procedure TLUETotDry.Init(Var GlobMod: TMod);
begin
  inherited Init(GlobMod);
  cluster_f.v := 1.0;

end;

procedure TLUETotDry.CalcRates;

begin
  inherited CalcRates;
  if Int_Corr then
  begin
    // cluster_f.v := (0.77+0.28*(1-exp(-1.65*RelGroundCov.v)));
    Par_abs.v := Par_abs.v * cluster_f.v;
  end;

  LUE.v := Temp_f.v * (LUE0.v - LUE_dec.v * Par.v);

  If LUE.v < 0.1 then
    LUE.v := 0.1;

  SWDF.v := 1 - power((1 - TransRatio.v), pfW.v);
  Assiflow.v := Par_abs.v * LUE.v * SWDF.v;

end;

procedure TLUETotDry.Integrate;

begin
  inherited Integrate;
end;

procedure Register;

begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TLUETotDry]);
{$ENDIF}
end;

end.
