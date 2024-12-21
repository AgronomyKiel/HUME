unit ULUETotDryN;

interface

uses UState, Umod, IniFiles, ULueTotDry, classes;


type
  real = double;

  TLUETotDryN = class(TLUETotDry)
  private

  protected
    procedure CreateAll; override;

  public
    N_dec: TPar;
    NImpact: TVar;
    NOpt,
      NPrLeaf: TExternV;
      NProtLeafArea : TExternV;
      NOptLeafProtContArea : TExternV;
    procedure CalcRates; override;

  published
    property Par_N_dec: TPar read n_dec write N_dec;
    property Var_NImpact: Tvar read NImpact write NImpact;
    property Ex_Nopt: TExternV read NOpt write NOpt;
    property Ex_NprLeaf: TExternV read NPrLeaf write NPrLeaf;

  end;

var
  BKLUeTotDryN: TLUETotDryN;

procedure Register;

implementation

uses
  UModUtils, math;



procedure TLUETotDryN.createAll;

begin
  inherited createAll;
  ParCreate('N_dec', '[-]', 0.01, N_dec);
  VarCreate('N_Impact', '[]', 0.0, false, NImpact);

  ExternVcreate('NoptLeaf', '[%N DM]', Statefield, NOpt);
  ExternVcreate('NPrLeaf', '[%N DM]', Statefield, NPrLeaf);
  ExternVcreate('NProtLeafArea', '[gN/m2]', Statefield, NProtLeafArea);
  ExternVcreate('NOptLeafProtContArea', '[gN/m2]', Statefield, NOptLeafProtContArea);

end;


procedure TLUETotDryN.CalcRates;


begin
  inherited CalcRates;
//  NImpact.v := ((NOpt.v - NPrLeaf.v) * N_dec.v);
  NImpact.v := ((NOptLeafProtContArea.v - NProtLeafArea.v) * N_dec.v);
  LUE.v := min(LUE.v, LUE.v - NImpact.v);

  if Lue.v < 0.1 then LUE.v := 0.1;
  AssiFlow.v := LUE.v * PAR_abs.v;
end;


procedure Register;

begin
  RegisterComponents('Simulation', [TLUETotDryN]);
end;


end.

