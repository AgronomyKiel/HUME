unit PlantIntegrator;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod, ULayeredSoil, Ustate, UAbstractPlant;

const
  Maxplants = 6;
type
TExPlantArr = array[1..MaxPlants] of TExternV;
TexPlantMatr = array[1..MaxPlants, 1..Max_comp] of TExternV;

  TPlantIntegrator = class(TSubmodel)
  private
    { Private-Deklarationen }
    fNPlants,
    fNLayers : integer;
    fLAIName,
    fPlantHeightName,
    fNuptake : string;
  protected
    { Protected-Deklarationen }
  public
    LAI,
    PlantHeight,
    NUptake
     : TVar;
    WLD_arr,
    effWLD_arr,
    WL_arr,
    effWL_arr : TSoilVarArray;

    exLAI,
    exNUptake,
    exPlantHeight : TExPlantArr;
    exWLD,
    exWL,
    exeffWLD,
    exeffWL         : TExPlantMatr;

   procedure createAll; override;


   Constructor create(AOwner : TComponent); override;
//   procedure Set_GlobMod(value:TMod);


//   procedure Init(var GlobMod:Tmod); override;

   procedure CalcRates; override;


    { Public-Deklarationen }
  published
    { Published-Deklarationen }
  property NPlants: integer read fNPlants write fNPlants;
  property NLayers: integer read fNLayers write fNLayers;


  end;

procedure Register;

implementation

procedure TPlantIntegrator.createAll;

var
  i, j :integer;

begin
  VarCreate('LAI', '[-]', 0.0, false, LAI);
  VarCreate('PlantNDemand', '[gN.m-2.d-1]', 0.0, false, Nuptake);
  VarCreate('CropHeight', '[-]', 0.0, false, Plantheight);

  for i := 1 to NPlants do begin
      ExternVCreate('LAI'+inttostr(i), '[]', StateField, exLAI[i]);
      ExternVCreate('PlantNDemand'+inttostr(i), '[]', RateField, exNUptake[i]);
      ExternVCreate('CropHeight'+inttostr(i), '[]', StateField, exPlantHeight[i]);
      for j := 1 to NLayers do begin
        ExternVCreate('Sal'+inttostr(i)+'WLD_'+inttostr(j), '[]', StateField, exWLD[i,j]);
        ExternVCreate('Sal'+inttostr(i)+'WL_'+inttostr(j),  '[]', StateField, exWL[i,j]);
        ExternVCreate('Sal'+inttostr(i)+'effWLD_'+inttostr(j), '[]', StateField, exeffWLD[i,j]);
        ExternVCreate('Sal'+inttostr(i)+'effWL_'+inttostr(j),  '[]', StateField, exeffWL[i,j]);

      end;

  end;

  for i := 1 to NLayers do begin
     VarCreate('WLD_'+inttostr(i), '[-]', 0.0, false, WLD_arr[i]);
     wld_arr[i].WriteToFile := false;
     VarCreate('WL_'+inttostr(i), '[-]', 0.0, false, WL_arr[i]);
     wl_arr[i].WriteToFile := false;
     VarCreate('effWLD_'+inttostr(i), '[-]', 0.0, false, effWLD_arr[i]);
     effwld_arr[i].WriteToFile := false;
     VarCreate('effWL_'+inttostr(i), '[-]', 0.0, false, effWL_arr[i]);
     effwl_arr[i].WriteToFile := false;

  end;





end;

Constructor TPlantIntegrator.Create(AOwner : TComponent);

begin
  fNplants := 2;
  fNLayers := 20;
  inherited create(AOwner);
  CreateAll;
end;


procedure TPlantIntegrator.CalcRates;

var
  i, j : integer;
begin
  Lai.V := 0.0;
  NUptake.v := 0.0;
  PlantHeight.v := 0.0;
  for j := 1 to NLayers do begin
    WLD_arr[j].v := 0.0;
    WL_arr[j].v := 0.0;
    effWLD_arr[j].v := 0.0;
    effWL_arr[j].v  := 0.0;
  end;


  for i := 1 to NPlants do begin
    lai.v := lai.v + exLAI[i].v;
    NUptake.v := NUptake.v + exNUptake[i].v;
    PlantHeight.v := PlantHeight.v + exPlantHeight[i].v;

    for j := 1 to NLayers do begin
      WLD_arr[j].v := WLD_arr[j].v + exWLD[i,j].v;
      WL_arr[j].v  :=  WL_arr[j].v + exWL[i,j].v;
      effWLD_arr[j].v := effWLD_arr[j].v + exeffWLD[i,j].v;
      effWL_arr[j].v := effWL_arr[j].v + exeffWL[i,j].v;
    end;

  end;

end;



procedure Register;
begin
  RegisterComponents('Simulation', [TPlantIntegrator]);
end;

end.
