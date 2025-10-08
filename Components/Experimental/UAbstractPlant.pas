unit UAbstractPlant;

interface

uses
  UState, Umod,
{$IFNDEF NONVISUAL}
  vcl.dialogs,
  vcl.Graphics, Windows, Messages,
{$ENDIF}
   Classes,  Variants
//  Controls, Forms,
//  StdCtrls, ExtCtrls
  ;

const
/// <summary> maximum number of soil layers </summary>
  max_comp = 50;
/// <summary> maximum number of rooted compartiments </summary>
  max_rootedcomp = 20;

type
/// <summary> redefine real to double precision floating point </summary>
  real = double;

/// <summary> Source of extinction coefficient / rc0 / Psi2 / Weff </summary>
  TSource = (fromParameter, fromPlantModel);

/// <summary> abstract base type for plant submodel </summary>
  TAbstractPlantNoRoots = class;
  TAbstractPlant = class;

/// <summary> abstract type for plant related soil submodels </summary>
/// <remarks> This is used to link soil submodels with plant submodels,
/// classes derived from TPlantRelatedSubMod can access the properties of the plant model instances
/// derived from TAbstractPlant. </remarks>
  TPlantRelatedSubMod = class(TSubModel)
  private
/// <summary> first plant model from a possible list of </summary>
    fFirstPlantMod: TAbstractPlant;
/// <summary> actual plant submodel instance </summary>
    fPlantModel: TAbstractPlant;
  protected
    function GetIsPlantModelset: boolean;
  public
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); virtual;
    procedure Init(var GlobMod: Tmod); override;
    property IsPlantModelSet: boolean read GetIsPlantModelset;
  published
    property PlantModel: TAbstractplant read fPlantModel write SetPlantModel;
  end;

/// <summary> base class for plant components interacting with soil components </summary>
/// <remarks> This base class is used to link plant submodels with soil submodels,
/// classes derived from TAbstractPlant deliver standardized properties for the soil submodels.
/// </remarks>
  TAbstractPlantNoRoots = class(TSubModel)
  private
    fNextCrop: TAbstractPlant;
    fRotationlength: byte;
    fSetNewDates: boolean;
/// <summary> pointer to soil water & nitrogen module </summary>
    fSoilNitrogenMod: TPlantRelatedSubmod;
/// pointer to soil mineralisation module </summary>
    fSoilMinMod: TPlantRelatedSubmod;
    /// pointer to soil layer module </summary>
    fSoilLayerMod: TPlantRelatedSubmod;
 /// <summary> pointer to evapotranspiration module </summary>
    fEvapModel: TPlantRelatedSubmod;

/// <summary> pointer to dry matter production module </summary>
    fDMprodModel: TPlantRelatedSubmod;

  protected
    fwithRoots: boolean;  // moved to protected hk 2025/03/20

    procedure setNextCrop(NextCrop: TAbstractplant); virtual;
    function  GetLAI: THumeNumEntity; virtual; abstract;
    procedure SetLai(NewLAI:THumeNumEntity); virtual; abstract;
    function  GetCropHeight: THumeNumEntity; virtual; abstract;
    procedure SetCropHeight(NewCropHeight:THumeNumEntity); virtual; abstract;
    function  getExtCoeffPAR: real; virtual;
    function  getExtCoeffGlobRad: real; virtual;
    function  getrc0: real; virtual;
    function  getPsi2: real; virtual; abstract;
    function  getWeff: real; virtual; abstract;
    function  getDM_c: real; virtual; abstract;
//    procedure setDM_c (DM_c:real); virtual; abstract;
    procedure SetDMprodModel(DMProdmodel: TPlantRelatedSubMod); virtual;
    function  GetNUptakeRate: THumeNumEntity; virtual; abstract;
    procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); virtual; abstract;


  public
/// <summary> total dry matter </summary>
    DMtotal     : TState;
/// <summary> C residues [g C/m2] </summary>
    C_Residues  : TState;
/// <summary> N residues [g N/m2] </summary>
    N_Residues  : TState;
/// <summary> do charvest </summary>
    DoHarvest   : boolean;
/// <summary>  </summary>
    Harvested   : boolean;
/// <summary>  </summary>
    SowingDate  : TPar;
    HarvestDate : TPar;
/// <summary> water potential at which water uptake by the plant starts to decrease (only valid if SoilWaterModel uses Option Opt_Psi2=fromPlantModel)} </summary>
    Par_Psi2    : TPar;
/// <summary> Canopy resistance at potential transpiration (only valid if EvapotranspirationModel uses Option Opt_rc0=fromPlantModel)} </summary>
    Par_rc0     : TPar;
/// <summary> Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)} </summary>
    Par_ExtCoeffPAR: TPar;
/// <summary> Effective rooting depth [cm] (only valid if SoilWaterModel uses Option Opt_Weff=fromPlantModel)} </summary>
    Par_Weff: TPar;
    procedure SetSowingDate(NewSowingDate: real); virtual;
    procedure Integrate; override;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;

//    Property St_TotalDrymatter : TState read TotalDryMatter write TotalDryMatter;
/// <summary> Extinction coefficient for photosynthetically active radiation} </summary>
    property ExtCoeffPAR: real read getExtCoeffPAR;
/// <summary> Extinction coefficient for global radiation} </summary>
    property ExtCoeffGlobRad: real read getExtCoeffGlobRad;
/// <summary> Canopy resistance at potential transpiration} </summary>
    property rc0: real read getrc0;
/// <summary> Water potential at which water uptake by the plant starts to decrease} </summary>
    property Psi2: real read getPsi2;
/// <summary> Effective rooting depth [cm] </summary>
    property Weff: real read getWeff;

    property p_LAI: THumeNumEntity read getLAI write setLAI;
    property p_CropHeight: THumeNumEntity read getCropHeight write setCropHeight;
    property p_TotalDryMatterGR : real read getDM_c;
    property p_NUptakeRate: THumeNumEntity read getNUptakeRate write setNUptakeRate;

  published
    property EvapModel: TPlantRelatedSubmod read fEvapmodel write fEvapModel;
    property DMprodModel: TPlantRelatedSubmod read fDMprodModel write setDMprodModel;
    property Par_SowingDate: TPar read SowingDate write SowingDate;
    property Par_HarvestDate: TPar read HarvestDate write HarvestDate;
    property NextCrop: TAbstractPlant read fNextCrop write SetNextCrop;
    property Rotationlength: byte read frotationlength write fRotationLength;
    property St_C_Residues: TState read C_Residues write C_Residues;
    property St_N_Residues: TState read N_Residues write N_Residues;
    property St_DMtotal: TState read DMtotal write DMtotal;
    property SetNewDates: Boolean read fSetNewDates write fSetNewDates;
  end;


/// <summary> base class for plant components interacting with soil components </summary>
/// <remarks> This base class is used to link plant submodels with soil submodels,
/// classes derived from TAbstractPlant deliver standardized properties for the soil submodels.
/// </remarks>
  TAbstractPlant = class(TAbstractPlantNoRoots)
  private
/// <summary> pointer to soil water & nitrogen module </summary>
    fSoilNitrogenMod: TPlantRelatedSubmod;
/// pointer to soil mineralisation module </summary>
    fSoilMinMod: TPlantRelatedSubmod;
    /// pointer to soil layer module </summary>
    fSoilLayerMod: TPlantRelatedSubmod;

  protected
    fwithRoots: boolean;  // moved to protected hk 2025/03/20

    function  GetWLD(Index: Integer): THumeNumEntity; virtual; abstract;
    function  GetSumRootLength: THumeNumEntity; virtual; abstract;
    function  GetSumRootLength_eff: THumeNumEntity; virtual; abstract;
    procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); virtual; abstract;
    function  getPsi2: real; virtual;
    function  getWeff: real; virtual;
    function  getDM_c: real; virtual;
    procedure setSoilNitrogenMod(AModel: TPlantRelatedSubmod);//    procedure setDM_c (DM_c:real); virtual; abstract;
  public
    DMFineRoot  : TState;
    SowingDate  : TPar;
    HarvestDate : TPar;
/// <summary> Effective rooting depth [cm] (only valid if SoilWaterModel uses Option Opt_Weff=fromPlantModel)} </summary>
    Par_Weff: TPar;
/// <summary> Option added HK 2025/03/20 </summary>
    OptWithRoots : TOption;
    procedure Integrate; override;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;

    property Psi2: real read getPsi2;
/// <summary> Effective rooting depth [cm] </summary>
    property Weff: real read getWeff;

/// <summary> write setWLD; </summary>
    property p_WLD[Index: Integer]: THumeNumEntity read getWLD;
    property p_SumRootLength: THumeNumEntity read getSumRootLength;
    property p_SumRootLength_eff: THumeNumEntity read getSumRootLength_eff;

  published
    property SoilMinMod: TPlantRelatedSubmod read fSoilMinMod write fSoilMinMod;
    property SoilLayerMod: TPlantRelatedSubmod read fSoilLayerMod write
      fSoilLayerMod;

    Property SoilNitrogenMod: TPlantRelatedSubmod read fSoilNitrogenMod write setSoilNitrogenMod;

    property St_DMFineRoot: TState read DMFineRoot write DMFineRoot;
    property withRoots: boolean read fWithRoots write fWithRoots;

  end;



implementation

uses math, SysUtils, UAbstractSoilMin;

procedure TAbstractPlantNoRoots.SetSowingDate(NewSowingDate: real);
begin
  Sowingdate.v := NewSowingDate;
end;



procedure TAbstractPlantNoRoots.CreateAll;
begin

  inherited createAll;
 // fSetNewDates:= false;
  ParCreate('SowingDate', '[]', 0.0, SowingDate, 'Day of sowing');
  ParCreate('HarvestDate', '[]', 1e6, HarvestDate);
  StateCreate('C_Residues', '[g C/m2]', 0, true, C_Residues);
  StateCreate('N_Residues', '[g N/m2]', 0, true, N_Residues);
  StateCreate('DMtotal', '[g.m-2]', 0, true, DMtotal);
  ParCreate('Par_rc0', '[s.m-1]', 50, Par_rc0,
    'Canopy resistance at potential transpiration');
  ParCreate('Par_ExtCoeffPAR', '[-]', 0.675, Par_ExtCoeffPAR,
    'Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)');

end;


procedure TAbstractPlant.CreateAll;
begin

  inherited createAll;
 // fSetNewDates:= false;
  StateCreate('DMfineroot', '[g.m-2]', 0, true, DMfineroot);
  ParCreate('Par_rc0', '[s.m-1]', 50, Par_rc0,
    'Canopy resistance at potential transpiration');
  ParCreate('Par_Weff', '[cm]', 100, Par_Weff, 'effective rooting depth');
  OptCreate('WithRoots', 'true', OptWithRoots, 'Option to flag that root growth is calculated within the component');
  OptWithRoots.OptionList.add('true');
  OptWithRoots.OptionList.add('false');


end;


procedure TAbstractPlantNoRoots.Integrate;

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

    if NextCrop <> nil then begin
      NextCrop.Harvested := false;
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



procedure TAbstractPlant.Integrate;

var
  Year, month, date: word;
  newdate: real;
  I: Integer;

begin
  inherited Integrate;
  if (Globtime.v > Harvestdate.v + 1) or (Doharvest) then
  if Harvested = false then begin
    if assigned(SoilMinMod) and (SoilMinMod is TAbstractSoilMin) then begin
      TAbstractSoilMin(SoilMinMod).AddResidues(C_Residues.v*10,N_Residues.v*10);
    end;
    if NextCrop <> nil then begin
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
    end;
    for I := 1 to self.StateStrList.Count - 1 do begin
     // StateVar[i].v := 0.0;
      StateVar[i].c := 0.0;
    end;
  end;
end;


procedure TAbstractPlantNoRoots.Init(var GlobMod: Tmod);
var
  day, month, year : integer;
begin
  inherited;

  DoHarvest := false;
  Harvested := false;
//  OptContOutput := true;
  // hkage
  C_Residues.v := 0;
  N_Residues.v := 0;
  if harvestdate.v < sowingdate.v then
     harvestdate.v := sowingdate.v+365;
  end;


procedure TAbstractPlant.Init(var GlobMod: Tmod);

begin
  inherited;
  if lowercase(OptWithRoots.Option) = 'true' then begin
    self.fwithRoots := true;
  end else begin
    self.fWithRoots := false;
  end;
end;



procedure TAbstractPlantNoRoots.CalcRates;
begin

end;


procedure TAbstractPlant.CalcRates;
begin

end;

//end;

function TAbstractPlantNoRoots.getExtCoeffPAR: real;
begin
  result := Par_ExtCoeffPAR.v;
end;

function TAbstractPlantNoRoots.getExtCoeffGlobRad: real;
begin
  {C.F. Green 1987: Nitrogen nutrition and wheat growth in relation to absorbed solar
                    radiation. Agricultural and Forest Meteorology 41, 207-248
                    ExtCoeffPAR / ExtCoeffGlobRad = 1.35}
  result := ExtCoeffPAR / 1.35;
end;

function TAbstractPlantNoRoots.getrc0: real;
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

procedure TAbstractPlantNoRoots.setNextCrop(NextCrop: TAbstractplant);
begin
  fNextcrop := Nextcrop;
end;


function TAbstractPlant.getDM_c:real;
begin
  result := DMTotal.c;
end;

procedure TAbstractPlantNoRoots.SetDMprodModel(DMprodModel: TPlantrelatedSubmod);
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


