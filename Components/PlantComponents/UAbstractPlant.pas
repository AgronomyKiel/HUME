/// <summary>Abstract base unit for plant submodels</summary>
/// <remarks>This unit defines the abstract base class for plant submodels and related soil submodels.
/// It includes properties and methods for managing plant growth, soil interactions, and environmental parameters.</remarks>
/// <author>HUME Development Team</author>

unit UAbstractPlant;

interface

uses
  UState, Umod,
{$IFNDEF NONVISUAL}
  vcl.dialogs,
  vcl.Graphics, Windows, Messages,
{$ENDIF}
   Classes,  Variants  ;

const
  /// <summary> maximum number of soil layers </summary>
  max_comp = 50;
  /// <summary>maximum number of rooted compartments</summary>
  max_rootedcomp = 20;

type
  /// <summary>redefine real to double precision floating point</summary>
  real = double;

  /// <summary>Source of extinction coefficient / rc0 / Psi2 / Weff</summary>
  TSource = (fromParameter, fromPlantModel);

  TRootingDepthIncrease = (linear, monomolecular);

  /// <summary>abstract base type for plant submodel</summary>
  TAbstractPlant = class;

  /// <summary>abstract type for plant related soil submodels</summary>
  TPlantRelatedSubMod = class(TSubModel)
  private
    /// <summary>first plant model from a possible list of</summary>
    fFirstPlantMod: TAbstractPlant;
    /// <summary>actual plant submodel instance</summary>
    fPlantModel: TAbstractPlant;
  protected

/// <summary> getter to check if a plant model is set</summary>
    /// <returns>boolean indicating if a plant model is set</returns>  
    function GetIsPlantModelset: boolean;

/// <summary>setter for the plant model</summary>
    /// <param name="NewPlantModel">new plant model to set</param>
    /// <remarks>This method sets the plant model and initializes the first plant model if not already set.</remarks>    
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); virtual;
  public

 /// <summary>initialization method for the submodel</summary>
    /// <param name="GlobMod">global model instance</param>
    /// <remarks>This method initializes the submodel</remarks>
    
    procedure Init(var GlobMod: Tmod); override;
    property IsPlantModelSet: boolean read GetIsPlantModelset;
  published

/// <summary>property to access the plant model</summary>
    /// <remarks>This property allows access to the current plant model instance.</remarks>
    /// <returns>current plant model</returns>
    /// <param name="PlantModel">new plant model to set</param>
    /// <remarks>This property allows setting the plant model for the submodel.</remarks>  
    property PlantModel: TAbstractplant read fPlantModel write SetPlantModel;
  end;

  /// <summary>base class for plant components interacting with soil components</summary>
  TAbstractPlant = class(TSubModel)
  private
 /// <summary>next crop in the rotation</summary>
    /// <remarks>This property holds a reference to the next crop in the rotation.</remarks>
    /// <param name="NextCrop">next crop to set</param>
    /// <returns>next crop in the rotation</returns> 
    fNextCrop: TAbstractPlant;

    /// <summary>rotation length in years</summary>
    /// <remarks>This property defines the length of the crop rotation in years.</remarks>
    /// <param name="RotationLength">rotation length in years</param>
    /// <returns>rotation length in years</returns>
    fRotationlength: byte;

/// <summary>flag to indicate if new sowing and harvest dates should be set for the next crop </summary>    
    fSetNewDates: boolean;
    /// <summary>pointer to soil water & nitrogen module</summary>
    fSoilNitrogenMod: TPlantRelatedSubmod;
    fSoilMinMod: TPlantRelatedSubmod;
    fSoilLayerMod: TPlantRelatedSubmod;
    fEvapModel: TPlantRelatedSubmod;
    fDMprodModel: TPlantRelatedSubmod;

  protected
    fwithRoots: boolean;  // moved to protected hk 2025/03/20

    procedure setNextCrop(NextCrop: TAbstractplant); virtual;
    function  GetLAI: THumeNumEntity; virtual; abstract;
    procedure SetLai(NewLAI:THumeNumEntity); virtual; abstract;
    function  GetCropHeight: THumeNumEntity; virtual; abstract;
    procedure SetCropHeight(NewCropHeight:THumeNumEntity); virtual; abstract;
    function  GetNUptakeRate: THumeNumEntity; virtual; abstract;
    procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); virtual; abstract;
    function  GetWLD(Index: Integer): THumeNumEntity; virtual; abstract;
    function  GetSumRootLength: THumeNumEntity; virtual; abstract;
    function  GetSumRootLength_eff: THumeNumEntity; virtual; abstract;
    procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); virtual; abstract;
    function  getExtCoeffPAR: real; virtual;
    function  getExtCoeffGlobRad: real; virtual;
    function  getrc0: real; virtual;
    function  getPsi2: real; virtual;
    function  getWeff: real; virtual;
    function  getDM_c: real; virtual;
    procedure setDM_c (DM_c:real); virtual; abstract;
    procedure SetDMprodModel(DMProdmodel: TPlantRelatedSubMod); virtual;
    procedure setSoilNitrogenMod(AModel: TPlantRelatedSubmod); virtual;


  public
    /// <summary>Total dry matter</summary>
    DMtotal     : TState;

    /// <summary>Fine root dry matter</summary>
    DMFineRoot  : TState;

    /// <summary>C residues [g C/m2]</summary>
    C_Residues  : TState;

    /// <summary>N residues [g N/m2]</summary>
    N_Residues  : TState;

    /// <summary>Do harvest</summary>
    DoHarvest   : boolean;

    /// <summary>Harvested?</summary>
    Harvested   : boolean;

    /// <summary>Parameter sowing date (TPar object) [day]</summary>
    SowingDate  : TPar;

    /// <summary>Parameter harvest date (TPar object) [day]</summary>
    HarvestDate : TPar;

    /// <summary>Parameter water potential at which water uptake by the plant starts to decrease (only valid if SoilWaterModel uses Option Opt_Psi2=fromPlantModel)</summary>
    Par_Psi2    : TPar;

    /// <summary>Parameter Canopy resistance at potential transpiration (only valid if EvapotranspirationModel uses Option Opt_rc0=fromPlantModel)</summary>
    Par_rc0     : TPar;

    /// <summary>Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)</summary>
    Par_ExtCoeffPAR: TPar;

    /// <summary>Effective rooting depth [cm] (only valid if SoilWaterModel uses Option Opt_Weff=fromPlantModel)</summary>
    Par_Weff: TPar;

    /// <summary>Pointer array to root length density data</summary>
    pWLD_arr: array[1..max_comp] of ^real;

    /// <summary>Option added HK 2025/03/20</summary>
    OptWithRoots : TOption;
    procedure SetSowingDate(NewSowingDate: real); virtual;

    procedure Integrate; override;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;

//    Property St_TotalDrymatter : TState read TotalDryMatter write TotalDryMatter;
    /// <summary>Extinction coefficient for photosynthetically active radiation</summary>
    property ExtCoeffPAR: real read getExtCoeffPAR;

    /// <summary>Extinction coefficient for global radiation</summary>
    property ExtCoeffGlobRad: real read getExtCoeffGlobRad;

    /// <summary>Canopy resistance at potential transpiration</summary>
    property rc0: real read getrc0;

    /// <summary>Water potential at which water uptake by the plant starts to decrease</summary>
    property Psi2: real read getPsi2;

    /// <summary>Effective rooting depth [cm]</summary>
    property Weff: real read getWeff;

 /// <summary>getter for root length density in a certain soil layser</summary>
    property p_WLD[Index: Integer]: THumeNumEntity read getWLD; 

/// <summary> propterty for total root length</summary>
    /// <remarks>This property returns the total root length of the plant.</remarks>    
    property p_SumRootLength: THumeNumEntity read getSumRootLength;

/// <summary> Property for effective root length</summary>
    /// <remarks>This property returns the effective root length of the plant. The effective root length
///   is the root length that is actively taking up water and nutrients.</remarks>    
    property p_SumRootLength_eff: THumeNumEntity read getSumRootLength_eff;

/// <summary> property for leaf area index (LAI)</summary>
    /// <remarks>This property returns the leaf area index of the plant.</remarks>   
    property p_LAI: THumeNumEntity read getLAI write setLAI;

/// <summary>property for crop height</summary>    
    property p_CropHeight: THumeNumEntity read getCropHeight write setCropHeight;

/// <summary>property for total dry matter growth rate </summary>    
    property p_TotalDryMatterGR : real read getDM_c;

/// <summary>property for nitrogen uptake rate</summary>    
    property p_NUptakeRate: THumeNumEntity read getNUptakeRate write setNUptakeRate;

  published

/// <summary>property for soil mineralisation sub model linked to the plant</summary>  
    property SoilMinMod: TPlantRelatedSubmod read fSoilMinMod write fSoilMinMod;
/// <summary>property for soil layer sub model linked to the plant</summary>
    /// <remarks>This property allows linking a soil layer submodel to the plant model.</remarks    
    property SoilLayerMod: TPlantRelatedSubmod read fSoilLayerMod write
      fSoilLayerMod;
/// <summary>property for evapotranspiration sub model linked to the plant</summary>
    property EvapModel: TPlantRelatedSubmod read fEvapmodel write fEvapModel;

/// <summary>property for dry matter production sub model linked to the plant</summary>    
    property DMprodModel: TPlantRelatedSubmod read fDMprodModel write setDMprodModel;

/// <summary>property for soil nitrogen sub model linked to the plant</summary>    
    Property SoilNitrogenMod: TPlantRelatedSubmod read fSoilNitrogenMod write setSoilNitrogenMod;

    property Par_SowingDate: TPar read SowingDate write SowingDate;
    property Par_HarvestDate: TPar read HarvestDate write HarvestDate;
    property NextCrop: TAbstractPlant read fNextCrop write SetNextCrop;
    property Rotationlength: byte read frotationlength write fRotationLength;
    property St_C_Residues: TState read C_Residues write C_Residues;
    property St_N_Residues: TState read N_Residues write N_Residues;
    property St_DMtotal: TState read DMtotal write DMtotal;
    property St_DMFineRoot: TState read DMFineRoot write DMFineRoot;
    property SetNewDates: Boolean read fSetNewDates write fSetNewDates;
    property withRoots: boolean read fWithRoots write fWithRoots;

  end;

implementation

uses math, SysUtils, UAbstractSoilMin;

procedure TAbstractPlant.SetSowingDate(NewSowingDate: real);
begin
  Sowingdate.v := NewSowingDate;
end;



procedure TAbstractPlant.CreateAll;
begin

  inherited createAll;
 // fSetNewDates:= false;
  ParCreate('SowingDate', '[]', 0.0, SowingDate, 'Day of sowing');
  ParCreate('HarvestDate', '[]', 1e6, HarvestDate);
  StateCreate('C_Residues', '[g C/m2]', 0, true, C_Residues, 'Amount of carbon in crop residues');
  StateCreate('N_Residues', '[g N/m2]', 0, true, N_Residues, 'Amount of nitrogen in crop residues');
  StateCreate('DMtotal', '[g.m-2]', 0, true, DMtotal, 'Total aboveground dry matter in crop');
  StateCreate('DMfineroot', '[g.m-2]', 0, true, DMfineroot, 'Total fine root dry matter in crop'  );
  ParCreate('Par_Psi2', '[cm]', 200, Par_Psi2,
    'water potential at which water uptake by the plant starts to decrease');
  ParCreate('Par_rc0', '[s.m-1]', 50, Par_rc0,
    'Canopy resistance at potential transpiration');
  ParCreate('Par_ExtCoeffPAR', '[-]', 0.675, Par_ExtCoeffPAR,
    'Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)');
  ParCreate('Par_Weff', '[cm]', 100, Par_Weff, 'effective rooting depth');
  OptCreate('WithRoots', 'true', OptWithRoots, 'Option to flag that root growth is calculated within the component');
  OptWithRoots.OptionList.add('true');
  OptWithRoots.OptionList.add('false');


end;



/// <summary>Integrates the plant model state variables and performs harvest if conditions are met</summary>
/// <remarks>This method checks if the harvest date has been reached or if harvesting is triggered.
/// If so, it sets the harvested flag, adds residues to the soil model, and prepares the next crop for planting.
/// It also resets state variables and updates sowing and harvest dates based on the rotation lengt
/// furthermore it moves pointer of coupled submodels to the next crop in the rotation.  </remarks>
procedure TAbstractPlant.Integrate;

var
  Year, month, date: word;
  newdate: real;
  I: Integer;

begin
  inherited Integrate;
  if (Globtime.v > Harvestdate.v + 1) or (Doharvest) then
  if Harvested = false then begin
    harvested := true;
    DoHarvest := false;
    if assigned(SoilMinMod) and (SoilMinMod is TAbstractSoilMin) then begin
      TAbstractSoilMin(SoilMinMod).AddResidues(C_Residues.v*10,N_Residues.v*10);
    end;

    if NextCrop <> nil then begin
      NextCrop.Harvested := false;
      if assigned(SoilMinMod) then begin
        SoilMinMod.PlantModel := NextCrop;
        if not assigned(NextCrop.SoilMinMod) then NextCrop.SoilMinMod := SoilMinMod;
      end;
      if assigned(fSoilNitrogenMod) then begin
        fSoilNitrogenMod.PlantModel := NextCrop;
        if not assigned(NextCrop.fSoilNitrogenMod) then NextCrop.fSoilNitrogenMod := fSoilNitrogenMod;
      end;
      if assigned(SoilLayerMod) then begin
        SoilLayerMod.PlantModel := NextCrop;
        if not assigned(NextCrop.SoilLayerMod) then NextCrop.SoilLayerMod := SoilLayerMod;
      end;
      if assigned(EvapModel) then begin
        EvapModel.PlantModel := NextCrop;
        if not assigned(NextCrop.EvapModel) then NextCrop.EvapModel := EvapModel;
      end;
      if SetNewDates then begin
        HarvestDate.WriteToFile := false;
        sowingdate.writetofile := false;
        decodedate(sowingdate.v, year, month, date);
        year := year + rotationlength;
        NewDate := encodedate(year, month, date);
        Setsowingdate(NewDate);
        decodedate(harvestdate.v, year, month, date);
        year := year + rotationlength;
        newdate := encodedate(year, month, date);
        if newdate > Harvestdate.v then Harvestdate.v := newdate;
      end else begin
        // Kluss, fraglich
        //Setsowingdate(1e6); // arbitrary high number to assure that sowingdate will be set by previous crop
        //harvestdate.v := 1e6; // arbitrary high number to assure that harvestdate will be set by previous crop or on specific internal events
      end;
    end;
    for I := 1 to self.StateStrList.Count - 1 do begin
     // StateVar[i].v := 0.0;
      StateVar[i].c := 0.0;
    end;
    {for I := 1 to self.VarStrList.Count - 1 do
      VarVar[i].v := 0.0; }
    //WriteTofile := false;
  end;
end;

procedure TAbstractPlant.CalcRates;
begin

end;


/// <summary>Initializes the plant model with global model parameters</summary>
/// <remarks>This method sets the initial conditions for the plant model
/// harvest status, and residue states. It also ensures that the harvest date is set correctly relative
/// to the sowing date.</remarks>
/// <param name="GlobMod">global model instance</param> 
procedure TAbstractPlant.Init(var GlobMod: Tmod);
var
  day, month, year : integer;
begin
  inherited;
  if lowercase(OptWithRoots.Option) = 'true' then begin
    self.fwithRoots := true;
  end else begin
    self.fWithRoots := false;
  end;

  DoHarvest := false;
  Harvested := false;
//  OptContOutput := true;
  // hkage
  C_Residues.v := 0;
  N_Residues.v := 0;
  if harvestdate.v < sowingdate.v then
     harvestdate.v := sowingdate.v+365;
  end;

//end;

function TAbstractPlant.getExtCoeffPAR: real;
begin
  result := Par_ExtCoeffPAR.v;
end;

function TAbstractPlant.getExtCoeffGlobRad: real;
begin
  {C.F. Green 1987: Nitrogen nutrition and wheat growth in relation to absorbed solar
                    radiation. Agricultural and Forest Meteorology 41, 207-248
                    ExtCoeffPAR / ExtCoeffGlobRad = 1.35}
  result := ExtCoeffPAR / 1.35;
end;

function TAbstractPlant.getrc0: real;
begin
  result := Par_rc0.v;
end;

function TAbstractPlant.getPsi2: real;
begin
  result := Par_Psi2.v;
end;

function TAbstractPlant.getWeff: real;
begin
  result := Par_Weff.v;
end;

procedure TAbstractPlant.setNextCrop(NextCrop: TAbstractplant);
begin
  fNextcrop := Nextcrop;
end;


function TAbstractPlant.getDM_c:real;
begin
  result := DMTotal.c;
end;

procedure TAbstractPlant.SetDMprodModel(DMprodModel: TPlantrelatedSubmod);
begin
  fDMprodModel := DMprodModel;
end;


procedure TAbstractPlant.setSoilNitrogenMod(AModel: TPlantRelatedSubmod);
begin
  fSoilNitrogenMod := AModel;
end;


{------------------------------------------------------------------------------}
{------- TPlantRelatedSubMod --------------------------------------------------}
{------------------------------------------------------------------------------}

procedure TPlantRelatedSubMod.Init(var GlobMod: Tmod);

begin
  inherited init(GlobMod);
  PlantModel := fFirstPlantMod;
end;

procedure TPlantRelatedSubMod.SetPlantModel(NewPlantModel: TAbstractplant);

begin
  fPlantModel := NewPlantModel;
  if fFirstPlantMod = nil then
    fFirstPlantMod := fPlantModel; // Set fFirstPlantMod only at first time ....
end;

function TPlantRelatedSubMod.GetIsPlantModelset: boolean;
begin
  if fPlantModel <> nil then
    result := true
  else
    result := false;
end;

end.


