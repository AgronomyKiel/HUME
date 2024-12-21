unit USimpleSoilHeat;

interface

uses
  UMod, UState, UlayeredSoil, UAbstractSoilHeat, classes, 
  USoilWaterMod; //dn


type

TSimpleSoilHeat = class (TAbstractSoilHeat)

private


  WCapa  : TSoilArray;
  fClay  : real; // Clay content either from Parameter or from texture

  lower, diag, upper, b_vektor : TSoilArray;
  procedure UpperBoundary;
  Procedure MiddleLayers;
  procedure LowerBoundary;
  procedure CalcConductivities;

protected
  fSoilWaterModel : TSoilWaterMod; //dn
public

  SpecWeight,
  ClayContent,
  GPV
             : TPar;
  Theta : TSoilExtArray;
  Lambda: TSoilVarArray;
  AirTemp : TExternV;
  procedure Init(Var GlobMod: TMod); Override;
  procedure CreateAll; override;
  procedure CalcRates; override;

published
  property Par_Dichte : TPar read SpecWeight write SpecWeight;
  property Par_Tongehalt : Tpar read ClayContent write ClayContent;
  property Par_GPV : TPar read GPV write GPV;
  property ExAirTemp : TExternV read AirTemp write AirTemp;
  property SoilWaterModel : TSoilWaterMod read fSoilWaterModel write fSoilWaterModel; //dn

end;

procedure Register;

implementation


uses
  math, dialogs, SysUtils,
  USoilTexture; //dn
  

const
  Cm = 2.13;
  Cw = 4.18;
  


function lambda_f ( Theta, Dichte, Ton : real ) : real;

const
  E = 4;
var
  A, B, C, D,
  Lambda : real;

begin
  D := 0.03+0.1*sqr(Dichte);
  B := 1.06*Dichte*Theta;
  A := 0.65-0.78*Dichte+0.6*sqr(Dichte);
  C := 1+2.6/sqrt(Ton);
  Lambda := A+B*Theta-(A-D)*exp(-power(C*Theta,E));
  Lambda_f := Lambda/100*86400;
end;


function heat_Capa ( Theta, GPV : real):real;

begin
  heat_Capa := Cm*(1.0-GPV) + Cw*Theta;
end;


Procedure TSimpleSoilHeat.Init(var GlobMod:Tmod);

var
  i : integer;

begin
  inherited Init(GlobMod);
    For I := 1 to n_comp+1 do begin
    Lambda[i].v := 0.0;
    WCapa[i]  := 0.0;
  end;
  if assigned(fSoilWaterModel) then //dn neu eingefügt Anfang
  begin
    if fSoilWaterModel.Opt_VanGenPars_from_Texture = fromTexture
      then fClay := ClayFromTexture(fSoilWaterModel.Texture[i])
      else fClay := ClayContent.v;
  end
  else fClay := ClayContent.v;
end;


Procedure TSimpleSoilHeat.CreateAll;

var
  i : integer;

begin
  inherited createAll;
  ParCreate('Dichte', '[g/cm3]', 1.5,  SpecWeight);   { Trockenraum-Dichte [g/cm3] }
  ParCreate('Tongehalt', '[-]', 0.1, ClayContent);   { Tongehalt [-] }
  ParCreate('GPV', '[-]', 0.5, GPV);   { GPV [-] }
  ExternVCreate('Temp',    '[°C]', StateField, AirTemp);


  for I := 1 to N_comp+1 do
    if i<10 then begin
       ExternVCreate('WG_'+IntTostr(i),    '[cm3/cm3]', StateField, theta[i]);
       VarCreate('Lambda_'+IntTostr(i),    '[W/m2]',0,true, Lambda[i]);
     end
     else begin
       ExternVCreate('WG'+IntTostr(i),    '[cm3/cm3]', StateField, theta[i]);
       VarCreate('Lambda'+IntTostr(i),    '[W/m2]',0,true, Lambda[i]);
    end;

end;

procedure TSimpleSoilHeat.UpperBoundary;
var
  K : real;

begin
  K  := globmod.time.c/(Thick[1]*WCapa[1]);
  b_vektor[1] := Temp[1].v - Temp[0].v*Lambda[1].v*K/(Depth[0].v-Depth[1].v);
  Diag[1]     :=  -lambda[1].v*K/(Depth[0].v-Depth[1].v)-lambda[1].v*K/(Depth[1].v-Depth[2].v)+1;
  Upper[1]    :=  lambda[1].v*K/(Depth[1].v-Depth[2].v);
end;

procedure TSimpleSoilHeat.MiddleLayers;


var
  K : real;
  i : byte;

begin
  For I := 2 to N_comp-1 do begin
    K  := self.GlobMod.time.c/(Thick[i]*WCapa[i]);
    b_vektor[i] := Temp[i].v;
    Lower[i]    := Lambda[i].v*K/(Depth[i-1].v-Depth[i].v);
    Diag[i]     :=  -lambda[i].v*K/(Depth[i-1].v-Depth[i].v)-lambda[i].v*K/(Depth[i].v-Depth[i+1].v)+1;
    Upper[i]    :=  lambda[i].v*K/(Depth[i].v-Depth[i+1].v);
  end;
end;


procedure TSimpleSoilHeat.LowerBoundary;

var
  K : real;

begin
  Temp[0].v := AirTemp.v;
  K  := globmod.time.c/(Thick[n_comp]*WCapa[n_comp]);
  b_vektor[N_comp] := Temp[n_comp].v;
  Lower[n_comp]    := Lambda[n_comp].v*K/(Depth[n_comp-1].v-Depth[N_comp].v);
  Diag[N_comp]     :=  -lambda[n_comp].v*K/(Depth[n_comp-1].v-Depth[n_comp].v)+1;
end;


procedure TSimpleSoilHeat.CalcConductivities;

var
  i : integer;

begin

  For I := 1 to n_comp+1 do begin
    Lambda[i].v := lambda_f (Theta[i].v, SpecWeight.v, fClay);       { Waermeleitfaehigkeit }
    WCapa[i]  := Heat_Capa(Theta[i].v, GPV.v);                       { Waermekapazitaet }

  end; //dn neu eingefügt Ende

//begin
//  For I := 1 to n_comp+1 do begin
//    Lambda[i].v := lambda_f (Theta[i].v, Dichte.v, TonGehalt.v );       { Waermeleitfaehigkeit }
//    WCapa[i]  := Heat_Capa(Theta[i].v, GPV.v);                       { Waermekapazitaet }
//
//  end; //dn auskommentiert
end;


Procedure TSimpleSoilHeat.Calcrates;

var

  result, i : byte;



begin
  inherited calcrates;
  CalcConductivities;
  UpperBoundary;
  MiddleLayers;
  LowerBoundary;
  trdiag (false, n_comp, 1,
                 lower,
                 diag,
                 upper,
                     b_vektor);

  for i := 1 to n_comp do
    temp[i].v := b_vektor[i];
  temp[n_comp+1].v := temp[n_comp].v;

end;

procedure Register;

begin
  RegisterComponents('Simulation', [TSimpleSoilHeat]);
end;

end.