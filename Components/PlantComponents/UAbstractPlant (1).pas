unit UAbstractPlant;

interface

uses
  UState, Umod, dialogs, Classes, Graphics, Windows, Messages, Variants,
  Controls, Forms,
  StdCtrls, ExtCtrls;

const
  max_comp = 50;

type
  real = double;

  TSource = (fromParameter, fromPlantModel);
    // Source of extinction coefficient / rc0 / Psi2 / Weff

  TAbstractPlant = class;

  TPlantRelatedSubMod = class(TSubModel)
  private
    fFirstPlantMod: TAbstractPlant;
    fPlantModel: TAbstractPlant;
    function GetIsPlantModelset: boolean;
  protected
    procedure SetPlantModel(NewPlantmodel: TAbstractPlant); virtual;
  public

    procedure Init(var GlobMod: Tmod); override;

    property IsPlantModelSet: boolean read GetIsPlantModelset;
  published
    property PlantModel: TAbstractplant read fPlantModel write SetPlantModel;
  end;

  TAbstractPlant = class(TSubModel)
  private
    fwithRoots: boolean;
    fNextCrop: TAbstractPlant;
    fRotationlength: byte;
    fSetNewDates: boolean;
    fSoilMinMod: TPlantRelatedSubmod;
    fSoilLayerMod: TPlantRelatedSubmod;
    fEvapModel: TPlantRelatedSubmod;

  protected

    procedure setNextCrop(NextCrop: TAbstractplant); virtual;
    function GetLAI: THumeNumEntity; virtual; abstract;
    procedure SetLai(NewLAI:THumeNumEntity); virtual; abstract;
    function GetCropHeight: THumeNumEntity; virtual; abstract;
    procedure SetCropHeight(NewCropHeight:THumeNumEntity); virtual; abstract;
    function GetNUptakeRate: THumeNumEntity; virtual; abstract;
    procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); virtual; abstract;
    function GetWLD(Index: Integer): THumeNumEntity; virtual; abstract;
    function GetSumRootLength: THumeNumEntity; virtual; abstract;
    function GetSumRootLength_eff: THumeNumEntity; virtual; abstract;
    procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); virtual; abstract;
    function getExtCoeffPAR: real; virtual;
    function getExtCoeffGlobRad: real; virtual;
    function getrc0: real; virtual;
    function getPsi2: real; virtual;
    function getWeff: real; virtual;

  public
    DoHarvest: boolean;
    Harvested: boolean;
    C_Residues: TState;
    N_Residues: TState;
    SowingDate: TPar;
    HarvestDate: TPar;
    Par_Psi2: TPar;
      {water potential at which water uptake by the plant starts to decrease (only valid if SoilWaterModel uses Option Opt_Psi2=fromPlantModel)}
    Par_rc0: TPar;
      {Canopy resistance at potential transpiration (only valid if EvapotranspirationModel uses Option Opt_rc0=fromPlantModel)}
    Par_ExtCoeffPAR: TPar;
      {Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)}
    Par_Weff: TPar;
      {Effective rooting depth [cm] (only valid if SoilWaterModel uses Option Opt_Weff=fromPlantModel)}
    pWLD_arr: array[1..max_comp] of ^real;
    procedure SetSowingDate(NewSowingDate: real); virtual;

    procedure Integrate; override;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;

    property ExtCoeffPAR: real read getExtCoeffPAR;
      {Extinction coefficient for photosynthetically active radiation}
    property ExtCoeffGlobRad: real read getExtCoeffGlobRad;
      {Extinction coefficient for global radiation}
    property rc0: real read getrc0;
      {Canopy resistance at potential transpiration}
    property Psi2: real read getPsi2;
      {water potential at which water uptake by the plant starts to decrease}
    property Weff: real read getWeff; {Effective rooting depth [cm]}

    property p_WLD[Index: Integer]: THumeNumEntity read getWLD; // write setWLD;
    property p_SumRootLength: THumeNumEntity read getSumRootLength;
    property p_SumRootLength_eff: THumeNumEntity read getSumRootLength_eff;
    property p_LAI: THumeNumEntity read getLAI write setLAI;
    property p_CropHeight: THumeNumEntity read getCropHeight write setCropHeight;
    property p_NUptakeRate: THumeNumEntity read getNUptakeRate write setNUptakeRate;

  published
    property SoilMinMod: TPlantRelatedSubmod read fSoilMinMod write fSoilMinMod;
    property SoilLayerMod: TPlantRelatedSubmod read fSoilLayerMod write
      fSoilLayerMod;
    property EvapModel: TPlantRelatedSubmod read fEvapmodel write fEvapModel;
    property Par_SowingDate: TPar read SowingDate write SowingDate;
    property Par_HarvestDate: TPar read HarvestDate write HarvestDate;
    property NextCrop: TAbstractPlant read fNextCrop write SetNextCrop;
    property Rotationlength: byte read frotationlength write fRotationLength;
    property St_C_Residues: TState read C_Residues write C_Residues;
    property St_N_Residues: TState read N_Residues write N_Residues;
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
  StateCreate('C_Residues', '[g C/m2]', 0, true, C_Residues);
  StateCreate('N_Residues', '[g N/m2]', 0, true, N_Residues);
  ParCreate('Par_Psi2', '[cm]', 200, Par_Psi2,
    'water potential at which water uptake by the plant starts to decrease');
  ParCreate('Par_rc0', '[s.m-1]', 50, Par_rc0,
    'Canopy resistance at potential transpiration');
  ParCreate('Par_ExtCoeffPAR', '[-]', 0.675, Par_ExtCoeffPAR,
    'Extinction coefficient for PAR (only valid if EvapotranspirationModel uses Option Opt_Exk_Glob = fromPlantModel)');
  ParCreate('Par_Weff', '[cm]', 100, Par_Weff, 'effective rooting depth');
end;

procedure TAbstractPlant.Integrate;

var
  Year, month, date: word;
  newdate: real;

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
  end;
end;

procedure TAbstractPlant.CalcRates;
begin

end;

procedure TAbstractPlant.Init(var GlobMod: Tmod);
begin
  inherited;
  DoHarvest := false;
  Harvested := false;
  // hkage
  C_Residues.v := 0;
  N_Residues.v := 0;
  if HarvestDate.v <= SowingDate.v then
    harvestdate.v := sowingdate.v+365;
end;

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

