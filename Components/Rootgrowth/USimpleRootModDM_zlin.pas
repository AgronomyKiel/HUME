unit USimpleRootModDM_zlin;

interface

uses
  UState, UMod, IniFiles, UlayeredSoil,
  classes, UModUtils, USimplePlant, UAbstractPlant, USimpleRootModDM;


type

TSimpleRootModDM_zlin = class(TSimpleRootModDM)

private


protected
  function WLD_z_t_f ( z1, z2: real): real;override;

public
depthgrowthOptStr : Toption;

// External Variables
DMroot_inc : TExternV;

procedure createAll; override;

procedure Init(var GlobMod: Tmod); override;

procedure CalcRates; override;

published

end;

procedure Register;

implementation

uses
  SysUtils, math;

function TSimpleRootModDM_zlin.WLD_z_t_f(z1, z2  : real): real;

var
  WLD0,
  a,
  TsumKrit,
  zrkrit   : real;

begin

  If (Zr.v <= Zrmax.v)  then begin
    If RootDepthInc = ExpoLinear then begin
      zrkrit := k_zb.v/k_za.v;
      TsumKrit := ln(zrkrit/zr0.v)/k_za.v;
      if zr.v < zrkrit then zr.v := zr0.v*exp(TempSumR.v*k_za.v)
                       else zr.v := zrkrit+k_zb.v*(tempSumR.v-Tsumkrit);
    end
    else If RootDepthInc = Linear then begin
         if DMroot_inc.v > 0 then zr.v := zr0.v+k_zb.v*tempSumR.v;
    end;
  end;
  OldDMFineRoot := DMFineRoot.v;


  If z1>zr.v then begin
    WLD_z_t_f := 0.0;
    exit;
  end;
//  If (z2>zr.v) and (z1<>zr.v) then z2 := zr.v;
  a   := -ln(Ratio.v)/zr.v;
 // if a > zr.v then halt;
 
  SRL.v := DMFineRoot.v*sp_RL.v/1e4;

  WLD0:= (SRL.v*a)/(1-exp(-a*zr.v));
  wld_z_t_f := wld0*(exp(-a*z1)-exp(-a*min(z2,zr.v)))/(a*(z2-z1));

end;

procedure TSimpleRootModDM_zlin.CreateAll;
var
  i : integer;

begin
  inherited;
  OptCreate('Rootdepthgrowth', 'Monomolecular', depthgrowthoptstr);
  depthgrowthoptstr.optionlist.Clear;
  depthgrowthoptstr.optionlist.Add('linear');
  depthgrowthoptstr.OptionList.Add('expolinear');
  RootDepthInc := linear;

  // External Variable
  ExternVCreate('DMroot', '',ratefield, DMroot_inc);

end;

procedure TSimpleRootModDM_zlin.Init(Var GlobMod: TMod);

begin
  inherited Init(GlobMod);
  if uppercase(depthgrowthoptstr.Option) = uppercase('linear') then
    RootDepthInc := linear;
  if uppercase(depthgrowthoptstr.Option) = uppercase('expolinear') then
    RootDepthInc := expolinear;
end;

procedure TSimpleRootModDM_zlin.CalcRates;

begin
  inherited;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSimpleRootModDM_zlin]);
end;

end.


