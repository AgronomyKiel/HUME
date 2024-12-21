unit UBkVern;

interface

uses
 UState, Umod, IniFiles, Classes;


type
  real = double;

TBkVern = class(TSubModel)

public
  SectionName : string;
  Vern        : TState;
  x1,
  x2,
  x3,
  m2,
  nl_p1        : TPar;
  Temp, BZa    : TexternV;

  constructor create(AOwner: TComponent);  Override;
  procedure Set_GlobMod(Value:TMod); override;

  procedure  CalcRates; override;

  published
  property Ex_Temp : TexternV read Temp write Temp;
  Property EX_BZa  : TExternV read BZa write BZa;
  property St_Vern : TState read vern write vern;

end;

function trapez_f (x, x0, x1, x2, x3, fmin, fmax  : real):real;

procedure Register;

implementation

function trapez_f (x, x0, x1, x2, x3, fmin, fmax  : real):real;

{ bildet folgende Funktion ab :

  y |
    |
fmax|             ***********
    |           * |         | *
    |         *   |         |   *
    |       *     |         |     *
    |     *       |         |       *
fmin ___*_________|_________|_________*_______
        x0       x1        x2         x3

  }

begin
   if  (x >= x1) and (x <= x2) then begin
     Trapez_f := fmax;
     exit;
   end;
  if  (x <= x0) or (x >= x3) then begin
     Trapez_f := fmin;
     exit;
  end;
   if  (x > x2) then begin
      Trapez_f := fmax-(x-x2)*(fmax-fmin)/(x3-x2);
      exit;
   end;

  if  (x > x0) and (x< x1)then begin
      Trapez_f := fmin+(x-x0)*(fmax-fmin)/(x1-x0);
      exit;
  end;
  trapez_f := 0.0;
end;

constructor TBkVern.create(AOwner: TComponent);

begin
  inherited create (AOwner);
  StateCreate( 'VERN', '[d^(-1)]', 0.0, false, Vern);
  ParCreate('X1','[°C]', 10.0, x1);
  ParCreate('X2','[°C]', 13.0, x2);
  ParCreate('X3','[°C]', 25.0, x3);
  ParCreate('M2','[1/d]', 0.11, m2);
  ParCreate('NL_P1', '[°C-1]', 16, Nl_p1);
  ExternVcreate('Temp','[°C]', StateField, temp);
  ExternVcreate('Bza', '[n]', StateField, bza);

end;

procedure TBkVern.Set_GlobMod(Value:TMod);

begin
inherited Set_GlobMod(Value);
  StateCreate( 'VERN', '[d^(-1)]', 0.0, false, Vern);
  ParCreate('X1','[°C]', 10.0, x1);
  ParCreate('X2','[°C]', 13.0, x2);
  ParCreate('X3','[°C]', 25.0, x3);
  ParCreate('M2','[1/d]', 0.11, m2);
  ParCreate('NL_P1', '[°C-1]', 16, Nl_p1);
  ExternVcreate('Temp','[°C]', StateField, temp);
  ExternVcreate('Bza', '[n]', StateField, bza);

end;


procedure TBkVern.CalcRates;

begin
   if (BZa.v > nl_p1.v) and (Vern.v < 1.0) then
      Vern.c := Trapez_f(Temp.v, 0, x1.v, x2.v, x3.v, 0.0, m2.v)
   else Vern.c := 0.0;
end;

procedure Register;

begin
  RegisterComponents('CauliSim', [TBkVern]);
end;


end.
