unit UGrowthCurvePlantsRootDM;

interface

uses
  Classes,UGrowthCurvePlant, UMod, UState;

type
  real = double;

  TGrowthCurvePlantRootDM = class(TGrowthCurvePlant)
  public
    procedure CalcRates; override;

  end;


  procedure Register;


implementation


procedure TGrowthCurvePlantRootDM.CalcRates;

var
  Assiflow: real;

begin
  inherited CalcRates;
  if (GlobTime.v < SowingDate.v) or (GlobTime.v >= HarvestDate.v) then
    exit;

  /// <summary>Preserve the legacy shoot-to-root allocation formula using inherited parameters.</summary>
  Assiflow := StateVars[DM].C;
  DMFineRoot.C := Assiflow * (FFineroot.v) / (1 - FFineroot.v);

end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TGrowthCurvePlantRootDM]);
{$ENDIF}
end;

end.
