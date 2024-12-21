unit UForm_Partitioning_UpDate;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UFORMMOD, UMod, UAbstractPlant, UGrowthCurvePlant,
  UGrowthCurvePlantRoots, ModLink, ExtCtrls, Menus, ComCtrls, TeeProcs,
  TeEngine, Chart, StdCtrls, Buttons, Grids, AdvGrid, ToolWin,
  USubDryMatterSimple, Development, Daylength, UTillerdevelopmentSimple,
  USubPartitioningSimpleLAI, USubLeafAreaGrowthSimple, UPenMonteith,
  USimpleRootModDM, UlayeredSoil, USoilWaterMod, URootedSoil,
  USubLeafArea_UpDate, USubPartitioning_UpDate, USubDataEx,
  USubPartitioningVegNew, USubDryMatterSimple_GF, UIrrigate, UIrrigate_ISIP,
  USoilNitrogen, USoilNitrogenUp;

type
  TFormMod2 = class(TFormMod)
    Mod1:           TMod;
    Daylength1:     TDaylength;
    Development1:   TDevelopment;
    TillerdevelopmentSimple1: TTillerdevelopmentSimple;
    SimpleRootModDM: TSimpleRootModDM;
    PenMonteith1:   TPenMonteith;
    SubDataEX1:     TSubDataEX;
    SubLeafAreaSimple1: TSubLeafArea_UpDate;
    SubPartitioningSimple1: TSubPartitioning_UpDate;
    subdrymatterSimple1: TsubdrymatterSimple_GF;
    Irrigate_ISIP1: TIrrigate_ISIP;
    SoilNitrogenUp1: TSoilNitrogenUp;
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormMod2: TFormMod2;

implementation

{$R *.DFM}

procedure TFormMod2.FormCreate(Sender: TObject);
begin
  inherited;
{  i: Integer;
  for i := 0 to ParamCount – 1 do
  begin
    if LowerCase(ParamStr(i)) = 'autorun' then
    SpeedButtonRun
    else if (LowerCase(ParamStr(i)) = 'exit' then
      Application.Terminate;
 }
end;

end.
