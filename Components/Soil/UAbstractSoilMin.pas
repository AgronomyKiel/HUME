unit UAbstractSoilMin;

interface
uses
  UState, UMod, UAbstractPlant, UAbstractSoilHeat, USoilWaterMod;

const
  /// <summary>Maximum supported number of 10 cm organic-matter soil layers.</summary>
  MaxNOrgLayers = 9;
  /// <summary>Maximum number of soil layers represented by the shared soil-model convention.</summary>
  MaxSoilLayers = 20;

  /// <summary>Default carbon-to-nitrogen mass ratio of microbial biomass (BIOM); dimensionless.</summary>
  CN_biom: real = 8.0;
  /// <summary>Default carbon-to-nitrogen mass ratio of stabilized soil organic matter (SOM); dimensionless.</summary>
  CN_som: real = 10.0;
  /// <summary>Default carbon-to-nitrogen mass ratio of inert organic matter (IOM); dimensionless.</summary>
  CN_iom: real = 10.0;
  /// <summary>Default carbon-to-nitrogen mass ratio of decomposable plant material (DPM); dimensionless.</summary>
  CN_DPM: real = 6.0;
  /// <summary>Default carbon-to-nitrogen mass ratio of resistant plant material (RPM); dimensionless.</summary>
  CN_RPM: real = 80;

  /// <summary>Default first-order decomposition rate coefficient for DPM turnover to BIOM, in inverse days.</summary>
  ik_dpm_biom: real = 1.34;
  /// <summary>Default fraction of decomposed DPM carbon converted to microbial biomass; dimensionless.</summary>
  iE_dpm_biom: real = 0.4;
  /// <summary>Default first-order decomposition rate coefficient for RPM turnover to BIOM, in inverse days.</summary>
  ik_rpm_biom: real = 0.086;
  /// <summary>Default fraction of decomposed RPM carbon converted to microbial biomass; dimensionless.</summary>
  iE_rpm_biom: real = 0.4;
  /// <summary>Default first-order decomposition rate coefficient for SOM turnover to BIOM, in inverse days.</summary>
  ik_som_biom: real = 0.0001;
  /// <summary>Default fraction of decomposed SOM carbon converted to microbial biomass; dimensionless.</summary>
  iE_som_biom: real = 0.2;
  /// <summary>Default first-order turnover rate coefficient from microbial biomass to SOM, in inverse days.</summary>
  ik_biom_som: real = 0.3;
  /// <summary>Default fraction of microbial biomass carbon transferred to SOM during turnover; dimensionless.</summary>
  iE_biom_som: real = 1;

type
  
  /// <summary>Organic-matter pool identifiers, including two plant-residue fractions, biomass, stabilized and inert material.</summary>
  Pools = (
    /// <summary>Decomposable plant material.</summary>
    DPM,
    /// <summary>Resistant plant material.</summary>
    RPM,
    /// <summary>Total microbial biomass.</summary>
    BIOM,
    /// <summary>Stabilized soil organic matter.</summary>
    SOM,
    /// <summary>Inert organic matter.</summary>
    IOM);

  /// <summary>Organic-carbon transfer pathways between the decomposing pools.</summary>
  processes = (
    /// <summary>Decomposable plant material to microbial biomass.</summary>
    dpm_biom,
    /// <summary>Resistant plant material to microbial biomass.</summary>
    rpm_biom,
    /// <summary>Stabilized organic matter to microbial biomass.</summary>
    som_biom,
    /// <summary>Microbial biomass to stabilized organic matter.</summary>
    biom_som);



  /// <summary>Pool-indexed collection of model state variables.</summary>
  TPoolStateArray = array [Pools] of TState;
  /// <summary>Pool-indexed collection of calculated model variables.</summary>
  TPoolVarArray = array [Pools] of TVar;
  /// <summary>Pool-indexed collection of model parameters.</summary>
  TPoolParArray = array [Pools] of TPar;

  /// <summary>Base class for plant-related soil mineralization models, providing model links and layer-specific tillage factors.</summary>
  TAbstractSoilMin = class(TPlantRelatedSubMod)
  protected
    /// <summary>Reference to the coupled soil heat model.</summary>
    fSoilHeatModel : TAbstractSoilHeat;
    /// <summary>Reference to the coupled soil water model.</summary>
    fSoilWaterModel : TSoilWaterMod;
    /// <summary>Reference to the coupled plant model.</summary>
    fPlantModel    : TAbstractPlant;
  public
    /// <summary>Number of organic-matter soil layers, each representing 10 cm of soil.</summary>
    NOrgLayers : Tpar;
    /// <summary>Dimensionless layer-specific tillage factors; values above 1 increase decomposition rates temporarily.</summary>
    /// <remarks>The array includes index 0; this base class creates states only for soil-layer indices starting at 1.</remarks>
    BBf     : array[0..MaxNOrgLayers] of TState;
    /// <summary>Registers the organic-layer count and creates tillage-factor states for layers 1 through NOrgLayers, initially set to 1.</summary>
    procedure CreateAll; override;
    /// <summary>Initializes the inherited model and resets tillage factors in layers 1 through MaxNOrgLayers to 1.</summary>
    procedure Init(Var GlobMod: TMod); Override;
    /// <summary>Hook for adding residue carbon and nitrogen; the base implementation performs no action.</summary>
    /// <param name="Carbon">Carbon amount supplied with the residues, using the units expected by the descendant.</param>
    /// <param name="nitrogen">Nitrogen amount supplied with the residues, using the units expected by the descendant.</param>
    procedure AddResidues(Carbon, nitrogen:real); virtual;
    /// <summary>Hook for redistributing organic matter within the tilled soil depth; the base implementation performs no action.</summary>
    /// <param name="depth">Depth of soil mixing, in cm.</param>
    procedure MixLayers(depth: real);  virtual;
  published
    /// <summary>Coupled soil heat model supplying the thermal context for mineralization in descendants.</summary>
    Property SoilHeatModel : TAbstractSoilHeat read fSoilHeatModel write fSoilHeatModel;
    /// <summary>Coupled soil water model supplying the water-status context for mineralization in descendants.</summary>
    Property SoilWaterModel : TSoilWaterMod read fSoilWaterModel write fSoilWaterModel;
    /// <summary>Coupled plant model associated with this mineralization submodel.</summary>
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
  SetEntityDeclarationClass(TAbstractSoilMin);
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
