unit UAbstractSoilMin;

interface
uses
  UState, UMod, UAbstractPlant, UAbstractSoilHeat, USoilWaterMod;

const
  MaxNOrgLayers = 9;             // maximum number of org. Layers
  MaxSoilLayers = 20;            // maximum number of total soil layers

type
  TAbstractSoilMin = class(TPlantRelatedSubMod)
  protected
    fSoilHeatModel : TAbstractSoilHeat;
    fSoilWaterModel : TSoilWaterMod;
    fPlantModel    : TAbstractPlant;
  public
    NOrgLayers : Tpar;      // number of organic layers a 10 [cm]
    BBf     : array[0..MaxNOrgLayers] of TState; // soil tillage factor [1..inf.] increasing decomposition rates after tillage for a certain time
    procedure CreateAll; override;
    procedure Init(Var GlobMod: TMod); Override;
    procedure AddResidues(Carbon, nitrogen:real); virtual;
    procedure MixLayers(depth: real);  virtual;
  published
    Property SoilHeatModel : TAbstractSoilHeat read fSoilHeatModel write fSoilHeatModel;
    Property SoilWaterModel : TSoilWaterMod read fSoilWaterModel write fSoilWaterModel;
    Property PlantModel : TAbstractplant read fPlantModel write fPlantModel;
  end;


implementation
uses
  UlayeredSoil;

procedure TAbstractSoilMin.CreateAll;
var
  layer: integer;
begin
  ParCreate('NOrgLayers', '[]',MAxNorgLayers, NOrgLayers);
  for layer := 1 to trunc(NOrgLayers.v) do begin
    StateCreate('BBf'+ndx_str(layer), '[]', 1, true, BBf[layer]);
  end;
end;

procedure TAbstractSoilMin.Init;
var
  layer: integer;
begin
  inherited;
  for layer := 1 to trunc(MAxNorgLayers) do begin
    BBf[layer].v     := 1.0;
  end;
end;

procedure TAbstractSoilMin.AddResidues(Carbon, nitrogen:real);
begin

end;

procedure TAbstractSoilMin.MixLayers(depth: real);
begin
end;

end.
