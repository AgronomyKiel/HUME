unit ULUETotDry;

interface

uses UState, Umod, IniFiles, classes,
     UDryMatProdComp;


type
  real = double;


TLUETotDry = Class(TDrymatterproduction)

private

protected
   procedure CreateAll; override;

public
     LUE0            : TPar;
     LUE_dec         : TPar;
     cluster_f       : TVar;
     Int_Corr        : boolean;
     TransRatio: TExternV; // Transpiration ratio


//     RelGroundCov    : TExternV;
     procedure CalcRates; override;
     procedure Integrate; override;
     procedure Init (Var GlobMod: TMod); override;
published
     property Par_LUE0   : Tpar read LUE0 write LUE0;
     property Par_LUEdec   : Tpar read LUE_dec write LUE_dec;
     property Opt_intCorr : boolean read Int_Corr write Int_Corr;
     property Ex_TransRatio: TExternV Read TransRatio Write TransRatio;

     //     property Ex_RelGroundCover : TExternV read RelGroundCov write RelGroundCov;

end;

procedure Register;

implementation

uses
  UModUtils;

procedure TLUETotDry.CreateAll;

begin
  inherited CreateAll;
  ParCreate( 'LUE0','[-]', 5, LUE0);
  ParCreate( 'LUE_dec','[-]', 0.2, LUE_dec);
  VarCreate( 'Cluster_f','[-]', 1.0, false, Cluster_f);
  ExternVCreate('TransRatio', '[-]', StateField, TransRatio);

//  ExternVCreate('RelGroundCov', '[-]', StateField, RelGroundCov);
end;

procedure TLUETotDry.init(Var GlobMod: Tmod);
begin
  inherited init(GlobMod);
  Cluster_f.v := 1.0;

end;
procedure TLUETotDry.CalcRates;


begin
  inherited calcRates;
  if Int_Corr then begin
//    cluster_f.v := (0.77+0.28*(1-exp(-1.65*RelGroundCov.v)));
    Par_abs.v := Par_Abs.v*Cluster_f.v;
  end;  

  LUE.v := Temp_f.v*(LUE0.v-LUE_dec.v*Par.v);

  If Lue.v < 0.1 then LUe.v := 0.1;
  Assiflow.v := par_abs.v*LUE.v*Transratio.v;

end;

procedure TLUETotDry.Integrate;

begin
  inherited Integrate;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TLUETotDry]);
end;


end.
