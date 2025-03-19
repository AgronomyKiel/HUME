unit USoilMinN2O;

interface

uses
  Ustate, UlayeredSoil, UMod, IniFiles, classes, UAbstractSoilHeat, UAbstractPlant;

Type
TSoilMinN2O = class(TPlantRelatedSubMod)
private

protected

public

	N2O_flux : TExternV;
	N2OEmission : TVar;
	cum_N2O_loss : TState;
  ex_cum_N2O_nit : TExternV;
  ex_cum_N2O_den : TExternV;
  cum_nit : TState;
  cum_den : TState;
  CumN2OStarttime : TPar;
  CumN2Omonthly: TState;
	procedure CreateAll; override;
	procedure Init(Var GlobMod: TMod); Override;
	procedure CalcRates; override;

 published
	property Ex_N2O_flux    : TExternV read N2O_flux write N2O_flux;
  property Var_N2OEmission : Tvar read N2OEmission write N2OEmission;
	property St_cum_N2O_loss : TState read cum_N2O_loss write cum_N2O_loss;
end;

procedure Register;

implementation
uses SysUtils;

procedure TSoilMinN2O.CreateAll;
begin
  inherited createAll;
  VarCreate('N2OEmission', '[kg N ha-1 d-1]',0, true,N2OEmission, 'N2O flux rate');
  ExternVCreate('N2O_flux', '[kg N ha-1 d-1]',ratefield, N2O_flux);
  StateCreate('cum_N2O_loss', '[kg N ha-1]',0,true,cum_N2O_loss, 'cum. total loss of N2O');
  StateCreate('cum_nit', '[kg N ha-1]',0,true,cum_nit, 'cum. N2O loss from nitrification');
  StateCreate('cum_den', '[kg N ha-1]',0,true,cum_den, 'cum. N2O loss from denitrification');
  StateCreate('CumN2Omonthly', '[kg N ha-1]',0,true,CumN2Omonthly, 'monthly cum. total loss of N2O');
  ExternVCreate('cum_N2O_nit', '[kg N ha-1]',ratefield,ex_cum_N2O_nit, 'cum loss of N2O from nitrification');
  ExternVCreate('cum_N2O_den', '[kg N ha-1]',ratefield,ex_cum_N2O_den, 'cum loss of N2O from denitrification');
  ParCreate('CumN2OStarttime','[Datum]',0,CumN2OStarttime, 'Date when cum_N2O_loss starts');
end;
 
procedure TSoilMinN2O.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
   cum_N2O_loss.v:=0;
end; 
  
procedure TSoilMinN2O.CalcRates;
var
  y,m,d: word;
begin
  N2OEmission.v:=N2O_flux.v;
  if GlobMod.Time.v >= CumN2OStarttime.v then begin
    cum_N2O_loss.c := N2OEmission.v;
    cum_nit.c := ex_cum_N2O_nit.v;
    cum_den.c := ex_cum_N2O_den.v;
  end
  else begin
    cum_N2O_loss.c := 0;
    cum_nit.c := 0;
    cum_den.c := 0;
  end;

  decodedate(GlobMod.Time.v,y,m,d);
  if d = 1 then CumN2Omonthly.v := 0;
  CumN2Omonthly.c := N2OEmission.v;
end;
  
procedure Register;
begin
  RegisterComponents('Simulation', [TSoilMinN2O]);
end;

end.