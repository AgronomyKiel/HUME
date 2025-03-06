unit USimplePlantWW_old_R;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod, USimplePlant, UState ;

type
  real = double;
  TSimplePlantWW_old_R = class(TSubModel)
  private
    { Private-Deklarationen }
    DMFineRoot : TState;
    TempSum       : TState;
    fFineRoot0    : TPar;
    FFineRootDec  : TPar;
    FFineroot     : TVar;
    AssiToFineRoot : TVar;
    AssiFlow      : TExternV;
    Temp          : TExternV;
    SowingDate     : TPar;
    HarvestDate    : TPar;

  protected
    { Protected-Deklarationen }
  public
   procedure createAll; override;
   procedure init(var GlobMod: TMod); override;
   procedure CalcRates; override;
   procedure Integrate; override;
    { Public-Deklarationen }
  published


  property Var_FFineRoot : TVar read FFineRoot write FFineroot;
  property Par_FFineRoot0 : TPar read FFineRoot0 write FFineroot0;
  property Par_FFineRootDec : TPar read FFineRootDec write FFinerootDec;
  property Ex_Temp        : TExternV read Temp write Temp;
    { Published-Deklarationen }
  end;

procedure Register;

implementation

uses
  math;

procedure TSimplePlantWW_old_R.createAll;

begin
  inherited CreateAll;
  StateCreate('DMFineRoot', '[g/m2]', 0, false, DMFineRoot,'Dry matter of fine roots per square meter');
  StateCreate('TempSum', '[°C]', 0, false, TempSum, 'Temperature sum since sowing');
  VarCreate('fFineRoot', '[-]', 0.4, false, fFineroot);
  VarCreate('AssitoFineRoot', '[g/m2/d]', 0, false, AssiToFineRoot, 'fraction of assimilates allocated to the fine roots');
  ParCreate('fFineRoot0', '[-]', 0.4, fFineroot0);
  ParCreate('fFineRootDec', '[-]', 0.0002, fFinerootdec);
  ParCreate('SowingDate', '[ExcelDate]', 0,  SowingDate, 'Day of sowing');
  ExternVcreate('Temp', '[-]', StateField, Temp,'Air temperature [°C]');
  ExternVcreate('DMShoot', '[-]', RateField, AssiFlow, 'Daily crop growth rate [g/m2/d]');
end;

procedure TsimplePlantWW_old_R.init;

begin
  inherited;
end;

procedure TSimplePlantWW_old_R.CalcRates;

begin
//  inherited CalcRates;
   If GlobTime.v >= SowingDate.v then begin
    If Temp.v > 0.0 then
      TempSum.c := Temp.v
    else TempSum.c  := 0.0;

// own approach
    FFineRoot.v := max(0,fFineRoot0.v-FFinerootDec.v*TempSum.v);      // old version

    DMFineRoot.C    := Assiflow.v * (FFineRoot.v)/(1-FFineRoot.v);
    AssiToFineRoot.v := DMFineRoot.c;


  end;

end;

procedure TSimplePlantWW_old_R.Integrate;

begin
  inherited;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSimplePlantWW_old_R]);
end;

end.
