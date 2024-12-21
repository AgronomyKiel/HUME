unit UBkLeafDev;

interface

uses UState, Umod, IniFiles, Classes, USimplePlant;

type
  real = double;

  TBkLeafDev = Class(TSimplePlant)
  public
     Bzs    : TState;
     Bza    : TVar;
     Bzk1   : TPar;
     bzk2   : Tpar;
     EndBZ  : real;
     BZkrit : real;

     Vern : TExternV;
     procedure CreateAll; override;
     Constructor create(AOwner: TComponent ); override;
     procedure Set_GlobMod(Value:TMod); override;


   procedure CalcRates; override;
   procedure Init (var GlobMod: Tmod); override;
   published
   property Ex_Vern : TExternV read Vern write Vern;
   property ST_Bzs : TState read Bzs write bzs;
   property Var_bza : TVar read BZa write bza;

   property Par_bzk1 : TPar read bzk1 write bzk1;
   property par_bzk2 : TPar read bzk2 write bzk2;


 end;

procedure register;


implementation

uses
  SysUtils;

function aBZ_f ( sBZ:real ):real;
{ Funktion zur Umrechnung von sichbaren (>1cm) Blattzahlen in
  Anzahlen angelegter Blaetter waehrend der Jugendphase
  nach R. Boij (1990) }
begin
  aBZ_f := 1.86*sBZ+1.24;
end;


procedure TBkLeafDev.CreateAll;

var
  i : integer;

begin
  inherited createAll;

  ParCreate('bzk1','[n-1*°C-1]', 0.03, bzk1);
  ParCreate('bzk2','[°C-1]', 0.006, bzk2);
  StateCreate('Bzs' ,'[n]', 4.0, true, bzs);
  VarCreate('Bza' ,'[n]', aBZ_f(bzs.v), false, bza);

  externVcreate('Vern', '[1/d]', StateField, vern);



end;

constructor TBkLeafDev.create (AOwner: TComponent);

var
  i : integer;

begin
  inherited create(AOwner);
  CreateAll;


end;

procedure TBKLeafDev.Set_GlobMod(Value:TMod);

var
  i : integer;

begin
  inherited Set_GlobMod(Value);
  CreateAll;


end;

procedure TBKLeafDev.init(Var GlobMod: TMod);
var
  i : integer;
begin
  EndBZ  := 1000;
  inherited init(GlobMod);
  BZa.v := aBZ_f(bzs.v);

end;


procedure TbkLeafDev.CalcRates;


begin
  BZkrit := bzk2.v/bzk1.v;
  if BZs.v < EndBZ then begin
    if BZs.v < BZkrit then
      BZs.c := BZs.v*Temp.v*bzk1.v
    else
      Bzs.c :=  Temp.v*bzk2.v;
    if Vern.v < 0.85 then
       BZa.v := aBZ_f(bzs.v)
    else
      EndBZ := BZa.v;
  end else
    Bzs.C := 0.0;

end;

procedure Register;

begin
  RegisterComponents('CauliSim', [TBkLeafDev]);
end;


end.
