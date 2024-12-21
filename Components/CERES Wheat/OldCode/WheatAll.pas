unit WheatAll;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UState, UAbstractPlant, Daylength, Development, USubdrymattersimple,
  USubPartitioningVegNew, UTillerdevelopmentSimple, USubLeafAreaGrowthsimple,
  USimpleRootModDM;

type
  TWheatAll = class(TAbstractPlant)
  private
    fSubDaylength: TDaylength;
    fSubDevelopment: TDevelopment;
    FSubdrymatter: TsubdrymatterSimple;
    FSubPartitioning: TSubPartitioningVegNew;
    FSubTillerdevelopment: TTillerdevelopmentSimple;
    FSubLeafAreaGrowth: TSubLeafAreaGrowthSimple;
    FSubSimpleRootModDM: TSimpleRootModDM;


    procedure setSubDaylength( SubDay : TDaylength); virtual;
    procedure setSubDevelopment( SubDevelopment: TDevelopment); virtual;
    procedure setSubdrymatter( Subdrymatter: TsubdrymatterSimple); virtual;
    procedure setSubPartitioning( SubPartitioning: TSubPartitioningVegNew); virtual;
    procedure setSubTillerdevelopment( SubTillerdevelopment: TTillerdevelopmentSimple); virtual;
    procedure setSubLeafAreaGrowth( LeafAreaGrowth: TSubLeafAreaGrowthSimple); virtual;
    procedure setSubSimpleRootModDM( RootModDM: TSimpleRootModDM); virtual;

    procedure AddSubModVarsToLists(SubModel: TSubmodel);


    { Private-Deklarationen }
  protected




    { Protected-Deklarationen }
    function GetLAI:THumeNumEntity; override;
//    procedure SetLai(NewLAI:THumeNumEntity);  override;
    function GetCropHeight:THumeNumEntity; override;
//    procedure SetCropHeight(NewCropHeight:THumeNumEntity); override;
    function GetNUptakeRate:THumeNumEntity; override;
//    procedure SetNUptakeRate(NewNUptakeRate:THumeNumEntity); override;
    function GetWLD(Index:Integer):THumeNumEntity; override;
//    procedure SetWLD(Index:Integer; NewWLD:THumeNumEntity); override;

  public

    ECHarvest : TPar;
    { Public-Deklarationen }
    constructor create(AOwner: TComponent); override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); Override;
    procedure CalcRates; Override;
    procedure Integrate; Override;
    procedure SetSowingDate(NewSowingDate: real);  override;

  published
    property Par_ECHarvest : TPar read ECHarvest write ECHarvest;
    { Published-Deklarationen }
    property SubDaylength: TDaylength read fSubDaylength write setSubDaylength;
    property SubDevelopment: TDevelopment read fSubDevelopment write setSubDevelopment;
    property Subdrymatter: TsubdrymatterSimple read fSubdrymatter write setSubdrymatter;
    property SubPartitioning: TSubPartitioningVegNew read fSubPartitioning write setSubPartitioning;
    property SubTillerdevelopment: TTillerdevelopmentSimple read fSubTillerdevelopment write setSubTillerdevelopment;
    property SubLeafAreaGrowth: TSubLeafAreaGrowthSimple read fSubLeafAreaGrowth write setSubLeafAreaGrowth;
    property SubSimpleRootModDM: TSimpleRootModDM read fSubSimpleRootModDM write setSubSimpleRootModDM;


  end;

procedure Register;

implementation



procedure TWheatAll.SetSowingDate(NewSowingDate: real);

begin
   inherited;
   if fSubDevelopment <> nil then
     fSubDevelopment.sowingdate.v := Newsowingdate;
   if fSubPartitioning <> nil then
     fSubPartitioning.sowingdate.v := Newsowingdate;
end;







procedure TWheatAll.AddSubModVarsToLists(SubModel: TSubmodel);

var
  j: Integer;

begin

    for j := 0 to Submodel.StateStrList.count-1 do
      StateStrList.AddObject(Submodel.StateStrList.Strings[j], Submodel.StateStrList.objects[j]);
    for j := 0 to Submodel.VarStrList.count-1 do
      VarStrList.AddObject(Submodel.VarStrList.Strings[j], Submodel.VarStrList.objects[j]);
    for j := 0 to Submodel.ParStrList.count-1 do
      ParStrList.AddObject(Submodel.ParStrList.Strings[j], Submodel.ParStrList.objects[j]);
    for j := 0 to Submodel.ExternVStrList.count-1 do
      ExternVStrList.AddObject(Submodel.ExternVStrList.Strings[j], Submodel.ExternVStrList.objects[j]);
    for j := 0 to Submodel.OptionStrList.count-1 do
      OptionStrList.AddObject(Submodel.OptionStrList.Strings[j], Submodel.OptionStrList.objects[j]);
    for j := 0 to Submodel.ConstStrList.count-1 do
      ConstStrList.AddObject(Submodel.ConstStrList.Strings[j], Submodel.ConstStrList.objects[j]);

end;


procedure TWheatAll.SetSubDaylength( SubDay : TDaylength);

begin
  fSubDaylength := SubDay;
  SubDaylength.GlobMod := GlobMod;
  SubDay.Canvas.Brush.Color := cllime;
  SubDay.Canvas.Font.Color := clblack;

 // AddSubModVarsToLists(TSubModel(SubDaylength));
end;

procedure TWheatAll.setSubDevelopment( SubDevelopment: TDevelopment);

begin
  fsubDevelopment := SubDevelopment;
  SubDevelopment.GlobMod := GlobMod;
  SubDevelopment.Canvas.Brush.Color := cllime;
  SubDevelopment.Canvas.Font.Color := clblack;

//  AddSubModVarsToLists(TSubModel(SubDevelopment));


end;

procedure TWheatAll.setSubdrymatter( Subdrymatter: TsubdrymatterSimple);

begin
  fsubDryMatter := SubDryMatter;
  SubDryMatter.GlobMod := GlobMod;
  SubDrymatter.Canvas.Brush.Color := cllime;
  Subdrymatter.Canvas.Font.Color := clblack;


end;

procedure TWheatAll.setSubPartitioning( SubPartitioning: TSubPartitioningVegNew);

var
  i : integer;
begin
  fsubPartitioning := SubPartitioning;
  SubPartitioning.GlobMod := GlobMod;
  SubPartitioning.Canvas.Brush.Color := cllime;
  SubPartitioning.Canvas.Font.Color := clblack;


end;

procedure TWheatAll.SetSubTillerdevelopment( SubTillerdevelopment: TTillerdevelopmentSimple);

begin
  fSubTillerDevelopment := SubTillerdevelopment;
  SubTillerDevelopment.GlobMod := GlobMod;
  SubTillerDevelopment.Canvas.Brush.Color := cllime;
  SubTillerdevelopment.Canvas.Font.Color := clblack;

end;

procedure TWheatAll.setSubLeafAreaGrowth( LeafAreaGrowth: TSubLeafAreaGrowthSimple);

begin
  fSubLeafAreaGrowth := LeafAreaGrowth;
  SubLeafAreaGrowth.GlobMod := GlobMod;
  SubLeafAreaGrowth.Canvas.Brush.Color := cllime;
  SubLeafAreaGrowth.Canvas.Font.Color := clblack;


end;

procedure TWheatAll.setSubSimpleRootModDM( RootModDM: TSimpleRootModDM);


begin
  fSubSimpleRootModDM := RootModDM;
  SubSimpleRootModDM.GlobMod := GlobMod;
  SubSimpleRootModDM.Canvas.Brush.Color := cllime;
  SubSimpleRootModDM.Canvas.Font.Color := clblack;

end;


constructor TWheatAll.create(AOwner: TComponent);

begin
  inherited create(AOwner);


//  If fSubDaylength = nil then
//     fSubDaylength := TDaylength.create(self.owner);
//  fSubDaylength.Visible := false;
//  if fSubDaylength.Name = '' then
//    fSubDaylength.Name := self.name + '_SubDaylength';
//  assimilatedsubmodlist.addobject(fsubDaylength.name, fSubDaylength);

//  If fSubDevelopment = nil then
//    fSubDevelopment := TDevelopment.create(self.owner);
//  fSubDevelopment.Visible := false;
//  fSubDevelopment.Name := self.name + '_SubDevelopment';
//  assimilatedsubmodlist.addobject(fSubDevelopment.name, fSubDevelopment);

//  If fSubDryMatter = nil then
//    fSubDryMatter := TSubDryMatterSimple.create(self.owner);
//  fSubDryMatter.Visible := false;
//  fSubDryMatter.Name := self.name + '_SubDryMatter';
//  assimilatedsubmodlist.addobject(fSubDryMatter.name, fSubDryMatter);


//  If fSubPartitioning = nil then
//    fSubPartitioning := TSubPartitioningVegNew.create(self.owner);
//  fSubPartitioning.Visible := false;
//  fSubPartitioning.Name := self.name + '_SubPartitioning';
//  assimilatedsubmodlist.addobject(fSubPartitioning.name, fSubPartitioning);

//  If fSubTillerdevelopment = nil then
//    fSubTillerdevelopment := TTillerdevelopmentSimple.create(self.owner);
//  fSubTillerdevelopment.Visible := false;
//  fSubTillerDevelopment.Name := self.name + '_SubTillerDevelopment';
//  assimilatedsubmodlist.addobject(fSubTillerdevelopment.name, fSubTillerdevelopment);

//  If fSubLeafAreaGrowth = nil then
//    fSubLeafAreaGrowth := TSubLeafAreaGrowthSimple.create(self.owner);
//  fSubLeafAreaGrowth.Visible := false;
//  fSubLeafAreaGrowth.Name := self.name + '_SubLeafAreaGrowth';
//  assimilatedsubmodlist.addobject(fSubLeafAreaGrowth.name, fSubLeafAreaGrowth);

//  If fSubSimpleRootModDM = nil then
//    fSubSimpleRootModDM := TSimpleRootModDM.create(self.owner);
//  fSubSimpleRootModDM.Visible := false;
//  fSubSimpleRootModDM.Name := self.name + '_SubSimpleRootModDM';
//  assimilatedsubmodlist.addobject(fSubSimpleRootModDM.name, fSubSimpleRootModDM);


//  CreateAll;
//  fDaylengthsubmod.parent := self.parent;
end;

procedure TWheatAll.CreateAll;

var
  i, j : integer;
  SubModel : TSubModel;
begin
  inherited createAll;
  ParCreate('ECHarvest', 'time', 98, ECHarvest);
  self.AssimilatedSubmodList.Duplicates := dupignore;



 { for i := 0 to self.AssimilatedSubmodList.count-1 do begin
    SubModel := TSubModel(AssimilatedSubmodList.objects[i]);
    for j := 0 to Submodel.StateStrList.count-1 do
      StateStrList.AddObject(Submodel.StateStrList.Strings[j], Submodel.StateStrList.objects[j]);
    for j := 0 to Submodel.VarStrList.count-1 do
      VarStrList.AddObject(Submodel.VarStrList.Strings[j], Submodel.VarStrList.objects[j]);
    for j := 0 to Submodel.ParStrList.count-1 do
      ParStrList.AddObject(Submodel.ParStrList.Strings[j], Submodel.ParStrList.objects[j]);
    for j := 0 to Submodel.ExternVStrList.count-1 do
      ExternVStrList.AddObject(Submodel.ExternVStrList.Strings[j], Submodel.ExternVStrList.objects[j]);
    for j := 0 to Submodel.OptionStrList.count-1 do
      OptionStrList.AddObject(Submodel.OptionStrList.Strings[j], Submodel.OptionStrList.objects[j]);
    for j := 0 to Submodel.ConstStrList.count-1 do
      ConstStrList.AddObject(Submodel.ConstStrList.Strings[j], Submodel.ConstStrList.objects[j]);


  end; }


end;


procedure TWheatAll.Init(var GlobMod: Tmod);

var
  i, j : integer;
  SubModel : TSubModel;

begin
  inherited init(GlobMod);
  if (fSubDaylength <> nil) and (fsubDaylength.name <>  '') then
    assimilatedsubmodlist.addobject(subDaylength.name, subDaylength);
  If subDevelopment <> nil then
    assimilatedsubmodlist.addobject(subDevelopment.name, subDevelopment);
  If subDryMatter <> nil then
    assimilatedsubmodlist.addobject(subDryMatter.name, subDryMatter);
  If subTillerdevelopment <> nil then
    assimilatedsubmodlist.addobject(subTillerdevelopment.name, subTillerdevelopment );
  If subPartitioning  <> nil then
    assimilatedsubmodlist.addobject(subPartitioning.name, subPartitioning );
  If subLeafAreaGrowth <> nil then
    assimilatedsubmodlist.addobject(subLeafAreaGrowth.name, subLeafAreaGrowth );
  If FSubSimpleRootModDM <> nil then
    assimilatedsubmodlist.addobject(FSubSimpleRootModDM.name, FSubSimpleRootModDM );

    fsubdevelopment.sowingdate.writetofile  := false;
    fsubdevelopment.sowingdate.ReadFromFile := false;
    fsubdevelopment.sowingdate.v := self.SowingDate.v;
//    fsubdevelopment.Harvestdate.v := self.SowingDate.v;

    FSubPartitioning.HarvestDate.WriteToFile := false;
    FSubPartitioning.sowingdate.writetofile := false;
    FSubPartitioning.HarvestDate.ReadFromFile := false;
    FSubPartitioning.sowingdate.ReadFromfile := false;
    FSubPartitioning.sowingdate.v := sowingdate.v;
    FSubPartitioning.Harvestdate.v := harvestdate.v;


  {for i := 0 to self.AssimilatedSubmodList.count-1 do begin
         SubModel := TSubModel(AssimilatedSubmodList.objects[i]);
  if Submodel <> nil then
      submodel.Init(GlobMod);

  end;}

end;




procedure TWheatAll.CalcRates;

var
  i, j : integer;
  SubModel : TSubModel;

begin
 self.C_Residues.c := 0.0;
 { for i := 0 to self.AssimilatedSubmodList.count-1 do begin
         SubModel := TSubModel(AssimilatedSubmodList.objects[i]);
  if Submodel <> nil then
         submodel.CalcRates;
  end; }


end;

procedure TWheatAll.Integrate;

var
  i, j : integer;
  SubModel : TSubModel;
  actState    : TState;
  actVar      : TVar;
  Year, month, date : word;


begin
 { for i := 0 to self.AssimilatedSubmodList.count-1 do begin
         SubModel := TSubModel(AssimilatedSubmodList.objects[i]);
  if Submodel <> nil then
         submodel.Integrate;
  end; }

  If (self.fSubDevelopment.ec.v >= self.ECHarvest.v) and (harvested=false) then begin
    DoHarvest := true;

     NextCrop.SowingDate.v := globtime.v +14;
      decodedate(globtime.v, year, month, date);
//  If SetNewDates = false then begin
//     SetSowingDate(1e6); // arbitrary high number to assure that sowingdate will be set by previous crop to maize
//     harvestdate.v := 1e6;
//  end;

//     if (year > 1975) then
//     NextCrop.SowingDate.v := globtime.v +14{-730};
     end;
  inherited Integrate;

  If self.fSubDevelopment.ec.v >= self.ECHarvest.v then begin
//    fsubdevelopment.sowingdate.v := sowingdate.v;
//    FSubPartitioning.sowingdate.v := sowingdate.v;
    fsubdevelopment.sowingdate.readfromfile := false;
    fsubpartitioning.sowingdate.readfromfile := false;

    N_Residues.v := self.FSubPartitioning.NStem_m2.v+self.FSubPartitioning.NLEaf_m2.v;
    C_Residues.v := (self.FSubPartitioning.STMWT_m2.v+self.FSubPartitioning.LFWT_m2.v)*0.45; // 45% Carbon content assumed
    for i := 0 to self.AssimilatedSubmodList.count-1 do begin
         SubModel := TSubModel(AssimilatedSubmodList.objects[i]);
      if Submodel <> nil then begin
        For j := 0 to submodel.StateStrList.count-1 do begin
          ActState := TState(Submodel.statestrlist.objects[j]);
          ActState.v := 0.0;
          ActState.c := 0.0;
        end;
        For j := 0 to submodel.VarStrList.count-1 do begin
          ActVar := TVar(Submodel.Varstrlist.objects[j]);
          ActVar.v := 0.0;
        end;
      end;
      if submodel <> nil then
        submodel.init(GlobMod);

     //  submodel.Integrate;
    end;

    self.Harvested := true;


  end;

end;

function TWheatAll.GetCropHeight:THumeNumEntity;

begin
  if fSubPartitioning <> nil then
    result := fSubPartitioning.CropHeight;
end;

{procedure TWheatAll.SetCropHeight(NewCropHeight:THumeNumEntity);

begin
  p_CropHeight := NewCropHeight;
end;}

function TWheatAll.GetLAI:THumeNumEntity;

begin
  if fSubLeafAreaGrowth <> nil then
     result := self.fSubLeafAreaGrowth.LAI;

end;

{procedure TWheatAll.SetLai(NewLAI:THumeNumEntity);

begin
  p_LAI := NewLAI;
end;}

function TWheatAll.GetNUptakeRate:THumeNumEntity;

begin
   result := fSubPartitioning.NDemand;
   result.v := fSubPartitioning.NDemand.v;
   result.fv := fSubPartitioning.NDemand.v;

end;

{procedure TWheatAll.SetNUptakeRate(NewNUptakeRate:THumeNumEntity);

begin
  p_NUptakeRate := NewNUptakeRate;
  fSubPartitioning.NDemand.name := p_NUptakeRate.Name;
  fSubPartitioning.NDemand.v := p_NuptakeRate.v;

end;}


function TWheatAll.GetWLD(Index: Integer):THumeNumEntity;

begin
  if fSubSimpleRootModDM <> nil then
    result :=  fSubSimpleRootModDM.wld_arr[index]
end;

{procedure TWheatAll.SetWLD(Index: Integer; NewWLD:THumeNumEntity);

begin
  fSubSimpleRootModDM.wld_arr[index].v :=   p_WLD[index].v;
end;}



procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TWheatAll]);
end;

end.
