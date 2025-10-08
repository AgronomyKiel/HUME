unit PlantIntegrator;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
  vcl.Dialogs,
  UMod, ULayeredSoil, Ustate, UAbstractPlant;

const
  Maxplants = 6;

type
  TExPlantArr = array [1 .. Maxplants] of TExternV;
  TexPlantMatr = array [1 .. Maxplants, 1 .. Max_comp] of TExternV;

  TPlantIntegrator = class(TSubmodel)
  private
    { Private-Deklarationen }
    fNPlants, fNLayers: integer;
    fLAIName, fPlantHeightName, fNuptake: string;
  protected
    { Protected-Deklarationen }
  public
    LAI, PlantHeight, NUptake: TVar;
    WLD_arr, effWLD_arr, WL_arr, effWL_arr: TSoilVarArray;

    exLAI, exNUptake, exPlantHeight: TExPlantArr;
    exWLD, exWL, exeffWLD, exeffWL: TexPlantMatr;

    procedure createAll; override;

    Constructor create(AOwner: TComponent); override;
    // procedure Set_GlobMod(value:TMod);


    // procedure Init(var GlobMod:Tmod); override;

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
  i, j: integer;

begin
  VarCreate('LAI', '[-]', 0.0, false, LAI);
  VarCreate('PlantNDemand', '[gN.m-2.d-1]', 0.0, false, NUptake);
  VarCreate('CropHeight', '[-]', 0.0, false, PlantHeight);

  for i := 1 to NPlants do
  begin
    ExternVCreate('LAI' + inttostr(i), '[]', StateField, exLAI[i]);
    ExternVCreate('PlantNDemand' + inttostr(i), '[]', RateField, exNUptake[i]);
    ExternVCreate('CropHeight' + inttostr(i), '[]', StateField,
      exPlantHeight[i]);
    for j := 1 to NLayers do
    begin
      ExternVCreate('Sal' + inttostr(i) + 'WLD_' + inttostr(j), '[]',
        StateField, exWLD[i, j]);
      ExternVCreate('Sal' + inttostr(i) + 'WL_' + inttostr(j), '[]', StateField,
        exWL[i, j]);
      ExternVCreate('Sal' + inttostr(i) + 'effWLD_' + inttostr(j), '[]',
        StateField, exeffWLD[i, j]);
      ExternVCreate('Sal' + inttostr(i) + 'effWL_' + inttostr(j), '[]',
        StateField, exeffWL[i, j]);

    end;

  end;

  for i := 1 to NLayers do
  begin
    VarCreate('WLD_' + inttostr(i), '[-]', 0.0, false, WLD_arr[i]);
    WLD_arr[i].WriteToFile := false;
    VarCreate('WL_' + inttostr(i), '[-]', 0.0, false, WL_arr[i]);
    WL_arr[i].WriteToFile := false;
    VarCreate('effWLD_' + inttostr(i), '[-]', 0.0, false, effWLD_arr[i]);
    effWLD_arr[i].WriteToFile := false;
    VarCreate('effWL_' + inttostr(i), '[-]', 0.0, false, effWL_arr[i]);
    effWL_arr[i].WriteToFile := false;

  end;

end;

Constructor TPlantIntegrator.create(AOwner: TComponent);

begin
  fNPlants := 2;
  fNLayers := 20;
  inherited create(AOwner);
  createAll;
end;

procedure TPlantIntegrator.CalcRates;

var
  i, j: integer;
begin
  LAI.V := 0.0;
  NUptake.V := 0.0;
  PlantHeight.V := 0.0;
  for j := 1 to NLayers do
  begin
    WLD_arr[j].V := 0.0;
    WL_arr[j].V := 0.0;
    effWLD_arr[j].V := 0.0;
    effWL_arr[j].V := 0.0;
  end;

  for i := 1 to NPlants do
  begin
    LAI.V := LAI.V + exLAI[i].V;
    NUptake.V := NUptake.V + exNUptake[i].V;
    PlantHeight.V := PlantHeight.V + exPlantHeight[i].V;

    for j := 1 to NLayers do
    begin
      WLD_arr[j].V := WLD_arr[j].V + exWLD[i, j].V;
      WL_arr[j].V := WL_arr[j].V + exWL[i, j].V;
      effWLD_arr[j].V := effWLD_arr[j].V + exeffWLD[i, j].V;
      effWL_arr[j].V := effWL_arr[j].V + exeffWL[i, j].V;
    end;

  end;

end;

procedure Register;
begin
  RegisterComponents('Simulation', [TPlantIntegrator]);
end;

end.
