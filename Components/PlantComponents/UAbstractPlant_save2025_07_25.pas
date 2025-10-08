unit UAbstractPlant_save2025_07_25;

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
/// <remarks> This is froward declaration the base class for all plant submodels. It contains the
///          basic properties and methods that are common to all plant models.
///          The actual plant model should inherit from this class and implement
///          the abstract methods. </remarks>
  TAbstractPlant = class;

/// <summary> abstract type for plant related soil submodels </summary>
/// <remarks> This is a the base class for all plant related soil submodels.
///          It contains the basic properties and methods that are common to all plant related soil models.
///          The actual plant related soil model should inherit from this class and implement
///          the abstract methods. </remarks>
  TPlantRelatedSubMod = class(TSubModel)
  private
/// <summary> first plant model from a possible list of </summary>
    fFirstPlantMod: TAbstractPlant;
/// <summary> actual plant submodel instance </summary>
    fPlantModel: TAbstractPlant;
  protected
    function GetIsPlantModelset: boolean;
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); virtual;
  public

    procedure Init(var GlobMod: Tmod); virtual;

    property IsPlantModelSet: boolean read GetIsPlantModelset;
  published
    property PlantModel: TAbstractplant read fPlantModel write SetPlantModel;
  end;

/// <summary> base class for plant components interacting with soil components </summary>
  TAbstractPlant = class(TSubModel)
  private
    fNextCrop: TAbstractPlant;
    fRotationlength: integer;
    fSetNewDates: boolean;
/// <summary> pointer to soil water & nitrogen module </summary>
    fSoilNitrogenMod: TPlantRelatedSubmod;
    fSoilMinMod: TPlantRelatedSubmod;
    fSoilLayerMod: TPlantRelatedSubmod;
    fEvapModel: TPlantRelatedSubmod;
    fDMprodModel: TPlantRelatedSubmod;

  protected
    fwithRoots: boolean;  // moved to protected hk 2025/03/20

    procedure setNextCrop(NextCrop: TAbstractplant); virtual;
    function  GetLAI: THumeNumEntity; virtual;
    procedure SetLai(NewLAI:THumeNumEntity); virtual;
    function  GetCropHeight: THumeNumEntity; virtual;
    procedure SetCropHeight(NewCropHeight:THumeNumEntity); virtual;
    function  GetNUptakeRate: THumeNumEntity; virtual;
    procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); virtual;
    function  GetWLD(Index: Integer): THumeNumEntity; virtual;
    function  GetSumRootLength: THumeNumEntity; virtual;
    function  GetSumRootLength_eff: THumeNumEntity; virtual;
    procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); virtual;
    function  getExtCoeffPAR: real; virtual;
    function  getExtCoeffGlobRad: real; virtual;
    function  getrc0: real; virtual;
    function  getPsi2: real; virtual;
    function  getWeff: real; virtual;
    function  getDM_c: real; virtual;
    procedure setDM_c (DM_c:real); virtual;
    procedure SetDMprodModel(DMProdmodel: TPlantRelatedSubMod); virtual;
    procedure setSoilNitrogenMod(AModel: TPlantRelatedSubmod); virtual;


  public
/// <summary> total dry matter </summary>
    DMtotal     : TState;
/// <summary> Fine root dry matter </summary>
    DMFineRoot  : TState;
/// <summary> C residues [g C/m2] </summary>
    C_Residues  : TState;
/// <summary> N residues [g N/m2] </summary>
    N_Residues  : TState;
/// <summary> do charvest </summary>
    DoHarvest   : boolean;
/// <summary>  </summary>
    Harvested   : boolean;
/// <summary> Day of sowing as integer value, usually in ExcelTime format </summary>
    SowingDate  : TPar;

///
    HarvestDate : TPar;
/// <summary> water potential at which water uptake by the plant starts to decrease (only valid if SoilWaterModel uses Option Opt_Psi2=fromPlantModel)} </summary>
    Par_Psi2    : TPar;
/// <summary> Canopy resistance at potential transpiration (only valid if EvapotranspirationModel uses Option Opt_rc0=fromPlantModel)} </summary>
    Par_rc0     : TPar;
/// <summary> Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)} </summary>
    Par_ExtCoeffPAR: TPar;
/// <summary> Effective rooting depth [cm] (only valid if SoilWaterModel uses Option Opt_Weff=fromPlantModel)} </summary>
    Par_Weff: TPar;
/// <summary> Pointer array to root length density data </summary>
    pWLD_arr: array[1..max_comp] of ^real;
/// <summary> Option added HK 2025/03/20 </summary>
    OptWithRoots : TOption;
    procedure SetSowingDate(NewSowingDate: real); virtual;

    procedure Integrate; virtual;
    procedure CreateAll; virtual;
    procedure Init(var GlobMod: Tmod); virtual;
/// <summary> write setWLD; </summary>
    property p_WLD[Index: Integer]: THumeNumEntity read getWLD;


/// <summary> Effective rooting depth [cm] </summary>
    property Weff: real read getWeff;

/// <summary> property for total root length </summary>
    property p_SumRootLength: THumeNumEntity read getSumRootLength;
/// <summary> property for effective total root length </summary>
    property p_SumRootLength_eff: THumeNumEntity read getSumRootLength_eff;

/// <summary> property for leaf area index </summary>
    property p_LAI: THumeNumEntity read getLAI write setLAI;

/// <summary> property for crop height </summary>
    property p_CropHeight: THumeNumEntity read getCropHeight write setCropHeight;

    /// <summary> property for total dry matter growth rate </summary>
    property p_TotalDryMatterGR : real read getDM_c;

    /// <summary> property for nitrogen uptake rate </summary>
    property p_NUptakeRate: THumeNumEntity read getNUptakeRate write setNUptakeRate;



    /// <summary> property for carbon in crop residues </summary>
    property St_C_Residues: TState read C_Residues write C_Residues;

    /// <summary> property for nitrogen in crop residues </summary>
    property St_N_Residues: TState read N_Residues write N_Residues;

    /// <summary> property for total dry matter </summary>
    property St_DMtotal: TState read DMtotal write DMtotal;

    /// <summary> property for fine root dry matter </summary>
    property St_DMFineRoot: TState read DMFineRoot write DMFineRoot;
/// <summary> Extinction coefficient for photosynthetically active radiation} </summary>
    property ExtCoeffPAR: real read getExtCoeffPAR;
/// <summary> Extinction coefficient for global radiation} </summary>
    property ExtCoeffGlobRad: real read getExtCoeffGlobRad;
/// <summary> Canopy resistance at potential transpiration} </summary>
    property rc0: real read getrc0;
/// <summary> Water potential at which water uptake by the plant starts to decrease} </summary>
    property Psi2: real read getPsi2;

  published

    /// <summary> property for soil mineralisation model </summary>
    property SoilMinMod: TPlantRelatedSubmod read fSoilMinMod write fSoilMinMod;

    /// <summary> property for soil layer model </summary>
    property SoilLayerMod: TPlantRelatedSubmod read fSoilLayerMod write
      fSoilLayerMod;

    /// <summary> property for evaporation model </summary>
    property EvapModel: TPlantRelatedSubmod read fEvapmodel write fEvapModel;

    /// <summary> property for soil nitrogen model </summary>
    property DMprodModel: TPlantRelatedSubmod read fDMprodModel write setDMprodModel;


    /// <summary> property for soil nitrate nitrogen transport model </summary>
    Property SoilNitrogenMod: TPlantRelatedSubmod read fSoilNitrogenMod write setSoilNitrogenMod;

    /// <summary> property for sowing date parameter </summary>
    property Par_SowingDate: TPar read SowingDate write SowingDate;

    /// <summary> property for harvest date parameter </summary>
    property Par_HarvestDate: TPar read HarvestDate write HarvestDate;

    /// <summary> property for next crop </summary>
    property NextCrop: TAbstractPlant read fNextCrop write SetNextCrop;

    /// <summary> property for rotation length </summary>
    property Rotationlength: integer read frotationlength write fRotationLength;
    property SetNewDates: Boolean read fSetNewDates write fSetNewDates;

    /// <summary> property flag for root presence </summary>
    property withRoots: boolean read fWithRoots write fWithRoots;


  end;

implementation

uses
  math, SysUtils, UAbstractSoilMin;

procedure TAbstractPlant.SetSowingDate(NewSowingDate: real);
begin
  SowingDate.v := NewSowingDate;
end;



procedure TAbstractPlant.CreateAll;

begin

  inherited createAll;
 // fSetNewDates:= false;
  ParCreate('SowingDate', '[]', 0.0, SowingDate, 'Day of sowing, could be DOY or in ExelTime, please check');
  ParCreate('HarvestDate', '[]', 1e6, HarvestDate);
  StateCreate('C_Residues', '[g C/m2]', 0, true, C_Residues);
  StateCreate('N_Residues', '[g N/m2]', 0, true, N_Residues);
  StateCreate('DMtotal', '[g.m-2]', 0, true, DMtotal);
  StateCreate('DMfineroot', '[g.m-2]', 0, true, DMfineroot);
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


    function  TAbstractPlant.GetLAI: THumeNumEntity;
    begin
      GetLAI := NIL;
    end;


    procedure TAbstractPlant.SetLai(NewLAI:THumeNumEntity);
    begin
 //    NewLAI := NIL;
    end;

    function  TAbstractPlant.GetCropHeight: THumeNumEntity;
    begin
       GetCropHeight := NIL;
    end;

    procedure TAbstractPlant.SetCropHeight(NewCropHeight:THumeNumEntity);
    begin
//     NewCropHeight := NIL;
    end;

    function  TAbstractPlant.GetNUptakeRate: THumeNumEntity;
    begin
       GetNUptakeRate := NIL;
    end;

    procedure TAbstractPlant.SetNUptakeRate(NewNUptakeRate:THumeNumEntity);
    begin
//     NewNUptakeRate := NIL;
    end;

   function  TAbstractPlant.GetWLD(Index: Integer): THumeNumEntity;
    begin
 //    result := NIL;
    end;

    function  TAbstractPlant.GetSumRootLength: THumeNumEntity;
    begin
     GetSumRootLength := NIL;
    end;

    function  TAbstractPlant.GetSumRootLength_eff: THumeNumEntity;
    begin
      GetSumRootLength_eff := NIL;
    end;

    procedure TAbstractPlant.SetWLD(Index:Integer; NewWLD:THumeNumEntity);
    begin
 //    NewWLD.v := 0.0;
    end;

    procedure TAbstractPlant.setDM_c (DM_c:real);
    begin
 //    NewWLD.v := 0.0;
    end;



end.