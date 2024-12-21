unit UAbstractSoilMin;

interface
uses
  UState, UMod, UAbstractPlant, UAbstractSoilHeat, USoilWaterMod;

const
  MaxNOrgLayers = 9;             // maximum number of org. Layers
  MaxSoilLayers = 20;            // maximum number of total soil layers

  CN_biom: real = 8.0; /// CN ratio BIOM
  CN_som: real = 10.0; /// CN ratio SOM
  CN_iom: real = 10.0; /// CN ratio IOM
  CN_DPM: real = 6.0; /// CN ratio DPM
  CN_RPM: real = 80; /// CN ratio RPM

  ik_dpm_biom: real = 1.34; /// reaction constants of respective processes
  iE_dpm_biom: real = 0.4; /// conversion efficiency of dpm carbon substrate into microbial biomass
  ik_rpm_biom: real = 0.086;
  iE_rpm_biom: real = 0.4;
  ik_som_biom: real = 0.0001;
  iE_som_biom: real = 0.2;
  ik_biom_som: real = 0.3;
  iE_biom_som: real = 1;

type
  { There are two fractions of plant residues }
  Pools = (DPM, { = decomposable material }
    RPM, { = resistant material }
    BIOM, { = microbial Biomass total }
    SOM,  { = stabilized organic matter }
    IOM); /// inert organic matter



  { These are the transfer processes between the pools: }
  processes = (dpm_biom, rpm_biom, som_biom, biom_som);



  TPoolStateArray = array [Pools] of TState;
  TPoolVarArray = array [Pools] of TVar;
  TPoolParArray = array [Pools] of TPar;

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
  inherited Createall;
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
