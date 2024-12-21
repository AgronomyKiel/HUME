unit UTUETotDry;

interface

uses UState, Umod, IniFiles, classes, UDryMatProdComp;


type
  real = extended;

TTUETotDry = Class(TDrymatterproduction)

private

protected
   procedure CreateAll; override;

public
     TUE              : TVar;
     TUE0             : TPar;
     TRans            : TExternV;
     procedure CalcRates; override;
     procedure Integrate; override;
published
     property Par_TUE0   : Tpar read TUE0 write TUE0;
     property Ex_Trans   : TExternV read Trans write Trans;
     property Var_TUE    : TVar read TUE write TUE;

end;

procedure Register;

implementation

uses
  UModUtils;

procedure TTUETotDry.CreateAll;

begin
  inherited CreateAll;
  ParCreate( 'TUE0','[-]', 5, TUE0);
  ExternVCreate('Trans', '[l/d]',StateField, Trans);
  VarCreate('TUE', '[g/l]', 3, false, TUE);
end;


procedure TTUETotDry.CalcRates;

begin
  inherited calcRates;

  TUE.v := Temp_f.v*(TUE0.v);

  Assiflow.v := Trans.v*TUE.v;

end;

procedure TTUETotDry.Integrate;

begin
// Do nothing
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TTUETotDry]);
end;


end.
