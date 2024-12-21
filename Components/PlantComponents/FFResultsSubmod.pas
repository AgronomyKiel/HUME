unit FFResultsSubmod;

interface

uses
  UMod, UState, IniFiles, classes, math, sysutils, UAbstractPlant, URootedSoil,
  UAbstractSoilMin, UGrowthCurvePlantRoots;

const
  maxCrop = 20;

type
  CropArray = array[0..maxCrop] of TState;

  TGrowthCurvePlantRoots_fT = class(TGrowthCurvePlantRoots)
  public
    T1,T2,T3,T4: TPar;
    fT: TVar;
    procedure CalcRates; override;
    procedure CreateAll; override;
  end;

  TFFResultsSubmod =  class(TSubmodel)

  private
    fSoilMinMod : TAbstractSoilMin;
    fActPlantmodel: TAbstractPlant;
    fSoilwaterMod: TSoilWaterModelR;
    fActCrop: integer;
  protected
    function IndexStr(i: integer): string;
  public
    Tact: TVar;
    Eact: TVar;
    Tpot: TVar;
    Epot: TVar;
    fInt: TVar;
    fT: TVar;
    IntPar: TVar;
    ActCrop: TVar;
    ActLAI: TVar;
    ActCropHeight: TVar;
    ActShootN: TVar;
    ActNShoot: TVar;
    PAW: TVar;
    PAWR: TVar;
    GlobRad : TExternV;   //   global radiation [MJ/m2/d]
    Sat_Def: TExternV;     //   saturation deficit [mbar]
    CumIntPARArr: CropArray;
    CumQfTArr: CropArray;    // IntPar * fT
    CumGlobRadArr: CropArray;
    CumTactArr: CropArray;
    CumT_SD_Arr: CropArray;
    CumEactArr: CropArray;
    CumTpotArr: CropArray;
    CumEpotArr: CropArray;
    CumNetRainArr: CropArray;
    CumDrainageArr: CropArray;
    CumDroughtDaysArr: CropArray;
    CumLAIDaysArr: CropArray;
    CumNUptakeArr: CropArray;
    SumMinr: TVar;            // sum of net mineralisation in all layers [kg N/ha/d]
    SumNmin: TVar;            // sum of mineral N downto bil_nr
    Nmin0_90: TVar;            // Nmin(NO3+NH4) 0-90
    NSystMin:TVar;             // mineral N in the system (ShootN + Nmin0_90 [kgN/ha/d]
    SumNDrain: TVar;            // sum of washed out N
    NSupplyMin: TState;
    NSupplyOrg: TVar;
    nCrops: TPar;
    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;   // initialisation method
    procedure Integrate; override;
  published
    Property SoilwaterMod: TSoilWaterModelR read fSoilwaterMod write fSoilwaterMod;
    Property Ex_GlobRad : TExternV read GlobRad write GlobRad;
    Property SoilMinMod : TAbstractSoilMin read fSoilMinMod write fSoilMinMod;
  end;

procedure Register;


implementation
uses vcl.Dialogs, UGrowthCurvePlant, OSRGrowth, UHumeWheatPartitioning, Usubpartitioning_Maize_Roots_N, USoilNitrogenUp,
     USoilNitrogen, USoilMineralisationNH4;


procedure TGrowthCurvePlantRoots_fT.CreateAll;
begin
  inherited CreateAll;
  VarCreate('fT', '',0, true, fT, 'Temperaturfunktion');
  ParCreate('T1', '°C', 0 , T1,'Wachstumsgrenze unten');
  ParCreate('T2', '°C', 10 , T2,'Optimumsgrenze unten');
  ParCreate('T3', '°C', 20 , T3,'Optimumsgrenze oben');
  ParCreate('T4', '°C', 35 , T4,'Wachstumsgrenze oben');
end;

procedure TGrowthCurvePlantRoots_fT.CalcRates;
begin
  inherited;
  if TEMP.v < T1.v then fT.v := 0
  else If TEMP.v <= T2.v then fT.v := (TEMP.v-T1.v)/(T2.v-T1.v)
  else if TEMP.v <= T3.v then fT.v := 1
  else if TEMP.v <= T4.v then fT.v := (T4.v-TEMP.V)/(T4.v-T3.v)
  else fT.v := 0;
end;

procedure TFFResultsSubmod.Init(var GlobMod: Tmod);
var
  i,j: integer;
begin
  inherited;
  fActCrop := 0;
  ActCrop.v := 0;
  i := round(nCrops.v);
  for j := 0 to maxCrop do begin
    CumTactArr[j].WriteToFile := j<=i;
    CumTactArr[j].WriteFinalValue := j<=i;
    CumT_SD_Arr[j].WriteToFile := j<=i;
    CumT_SD_Arr[j].WriteFinalValue := j<=i;
    CumEactArr[j].WriteToFile := j<=i;
    CumEactArr[j].WriteFinalValue := j<=i;
    CumTpotArr[j].WriteToFile := j<=i;
    CumTpotArr[j].WriteFinalValue := j<=i;
    CumEpotArr[j].WriteToFile := j<=i;
    CumEpotArr[j].WriteFinalValue := j<=i;
    CumIntPARArr[j].WriteToFile := j<=i;
    CumIntPARArr[j].WriteFinalValue := j<=i;
    CumQfTArr[j].WriteToFile := j<=i;
    CumQfTArr[j].WriteFinalValue := j<=i;
    CumGlobRadArr[j].WriteToFile := j<=i;
    CumGlobRadArr[j].WriteFinalValue := j<=i;
    CumNetRainArr[j].WriteToFile := j<=i;
    CumNetRainArr[j].WriteFinalValue := j<=i;
    CumDrainageArr[j].WriteToFile := j<=i;
    CumDrainageArr[j].WriteFinalValue := j<=i;
    CumDroughtDaysArr[j].WriteToFile := j<=i;
    CumDroughtDaysArr[j].WriteFinalValue := j<=i;
    CumLAIDaysArr[j].WriteToFile := j<=i;
    CumLAIDaysArr[j].WriteFinalValue := j<=i;
    CumNUptakeArr[j].WriteToFile := j<=i;
    CumNUptakeArr[j].WriteFinalValue := j<=i;
  end;
end;

procedure TFFResultsSubmod.CreateAll;
var
  i: integer;
begin
  inherited createall;
  VarCreate('Tact','mm',0,false,Tact,'aktuelle Transpiration, eingelesen von SoilwaterMod');
  VarCreate('Eact','mm',0,false,Eact,'aktuelle Evaporation, eingelesen von SoilwaterMod');
  VarCreate('Tpot','mm',0,false,Tpot,'potentielle Transpiration, eingelesen von SoilwaterMod');
  VarCreate('Epot','mm',0,false,Epot,'potentielle Evaporation, eingelesen von SoilwaterMod');
  VarCreate('PAW','mm',0,false,PAW,'pflanzenverfügbares Wasser im Boden');
  VarCreate('PAWR','mm',0,false,PAWR,'pflanzenverfügbares Wasser im effektiven Wurzelraum (bis Weff)');
  VarCreate('ActCrop','',0,false,ActCrop,'aktuell wachsendes Fruchtfolgeglied');
  VarCreate('IntPar','MJ/m2',0,false,IntPar,'aufgenommene PAR-Strahlung [MJ/m2]');
  VarCreate('fInt','-',0,false,fInt,'Anteil der aufgenommenen PAR-Strahlung');
  VarCreate('fT','-',0,false,fT,'Temperaturfunktion');
  VarCreate('ActLAI','m2/m2',0,false,ActLAI,'LAI');
  VarCreate('ActCropHeight','m',0,false,ActCropHeight,'CropHeight');
  VarCreate('ActShootN','gN/m2',0,false,ActShootN,'N-Menge im Bestand');
  VarCreate('ActNShoot','kgN/ha',0,false,ActNShoot,'N-Menge im Bestand');
  VarCreate('SumMinr', '[kg N/ha]', 0.0, false, SumMinr);
  VarCreate('SumNmin', '[kg N/ha]', 0.0, false, SumNmin);
  VarCreate('Nmin0_90', '[kg N/ha]', 0.0, false, Nmin0_90);
  VarCreate('NSystMin', '[kg N/ha]', 0.0, false, NSystMin, 'N im System(Nmin_0-90 + NShoot)');
  VarCreate('SumNDrain', '[kg N/ha]', 0.0, false, SumNDrain);
  StateCreate('NSupplyMin','[kg N/ha]',0,true,NSupplyMin,'kumulierte N-Zufuhr, mineralisch');
  VarCreate('NSupplyOrg','[kg N/ha]',0,false,NSupplyOrg,'kumulierte N-Zufuhr, organisch');
  for i := 0 to maxCrop do begin
    StateCreate('CumTact'+IndexStr(i),'mm',0,true,CumTactArr[i],'kumulierte aktuelle Transpiration, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumT_SD_Arr'+IndexStr(i),'mm',0,true,CumT_SD_Arr[i],'kumuliert aktuelle Transpiration geteilt durch Sättigungsdefizit, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumEact'+IndexStr(i),'mm',0,true,CumEactArr[i],'kumulierte aktuelle Evaporation, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumTpot'+IndexStr(i),'mm',0,true,CumTpotArr[i],'kumulierte potentielle Transpiration, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumEpot'+IndexStr(i),'mm',0,true,CumEpotArr[i],'kumulierte potentielle Evaporation, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumIntPAR'+IndexStr(i),'MJ/m2',0,true,CumIntPARArr[i],'kumulierte aufgenommene Strahlung, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumQfTArr'+IndexStr(i),'MJ°C/m2',0,true,CumQfTArr[i],'kumulierte aufgenommene Strahlung * Temperaturfunktion, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumGlobRad'+IndexStr(i),'MJ/m2',0,true,CumGlobRadArr[i],'kumulierte Globalstrahlung, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumNetRain'+IndexStr(i),'mm',0,true,CumNetRainArr[i],'kumulierter Niederschlag (abzügl. Interzeption), Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumDrainage'+IndexStr(i),'mm',0,true,CumDrainageArr[i],'kumulierte Sickerwassermenge, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumDroughtDays'+IndexStr(i),'d',0,true,CumDroughtDaysArr[i],'kumulierte Trockenstresstage, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumLAIDays'+IndexStr(i),'d',0,true,CumLAIDaysArr[i],'kumulierte Blattflächendauer, Fruchtfolgeglied '+IndexStr(i));
    StateCreate('CumNUptake'+IndexStr(i),'kg/ha',0,true,CumNUptakeArr[i],'kumulierte N-Aufnahme, Fruchtfolgeglied '+IndexStr(i));
  end;
  ExternVCreate('GlobRad', 'MJ/m2/d', statefield, GlobRad, 'global radiation [MJ/m2/d]');
  ExternVCreate('Sat_Def', 'mbar', statefield, Sat_Def, 'saturation deficit [mbar]');
  ParCreate('nCrops','',3,nCrops,'Anzahl Fruchtfolgeglieder');
end;

procedure TFFResultsSubmod.CalcRates;
var
  i: integer;
begin
  for i := 0 to maxCrop do begin
    CumTactArr[i].c := 0;
    CumT_SD_Arr[i].c := 0;
    CumEactArr[i].c := 0;
    CumTpotArr[i].c := 0;
    CumEpotArr[i].c := 0;
    CumIntPARArr[i].c := 0;
    CumQfTArr[i].c := 0;
    CumGlobRadArr[i].c := 0;
    CumNetRainArr[i].c := 0;
    CumDrainageArr[i].c := 0;
    CumDroughtDaysArr[i].c := 0;
    CumLAIDaysArr[i].c := 0;
    CumNUptakeArr[i].c := 0;
  end;
  if assigned(SoilWaterMod) then begin
    if SoilWaterMod.Plantmodel <> fActPlantmodel then begin
      fActPlantmodel := SoilWaterMod.Plantmodel;
      Inc(fActCrop);
    end;
    ActCrop.v := fActCrop;
    Tact.V := SoilWaterMod.ActTrans.v;
    CumTactArr[0].c := Tact.V;
    CumTactArr[fActCrop].c := Tact.V;
    if Sat_Def.v <> 0 then CumT_SD_Arr[0].c := Tact.V/Sat_Def.V else CumT_SD_Arr[0].c := 0;
    if Sat_Def.v <> 0 then CumT_SD_Arr[fActCrop].c := Tact.V/Sat_Def.V else CumT_SD_Arr[fActCrop].c := 0;
    Eact.V := SoilWaterMod.Act_Evap.v;
    CumEactArr[0].c := Eact.V;
    CumEactArr[fActCrop].c := Eact.V;
    Tpot.V := SoilWaterMod.PotTrans.v;
    CumTpotArr[0].c := Tpot.V;
    CumTpotArr[fActCrop].c := Tpot.V;
    Epot.V := SoilWaterMod.Pot_Evap.v;
    CumEpotArr[0].c := Epot.V;
    CumEpotArr[fActCrop].c := Epot.V;
    ActLAI.v := SoilWaterMod.Plantmodel.p_LAI.v;
    ActCropHeight.v := SoilWaterMod.Plantmodel.p_CropHeight.v;
    if (SoilWaterMod.Plantmodel) is (TGrowthCurvePlant) then
      ActShootN.v := TGrowthCurvePlant(SoilWaterMod.Plantmodel).StateVars[ShootN].v
      else if (SoilWaterMod.Plantmodel) is TOSRGrowth then
      ActShootN.v := TOSRGrowth(SoilWaterMod.Plantmodel).NShoot.v
      else if (SoilWaterMod.Plantmodel) is Tsubpartitioning_Maize_Roots_N then
      ActShootN.v := Tsubpartitioning_Maize_Roots_N(SoilWaterMod.Plantmodel).NShoot.v
      else if (SoilWaterMod.Plantmodel) is THumeWheatPartitioning then
      ActShootN.v := THumeWheatPartitioning(SoilWaterMod.Plantmodel).NShoot_m2.v;
    CumLAIDaysArr[0].c := ActLAI.v;
    CumLAIDaysArr[fActCrop].c := ActLAI.v;
    fInt.v := (1 - EXP(-SoilWaterMod.Plantmodel.ExtCoeffPAR * ActLAI.v));
    IntPar.v := fInt.v*0.5*GlobRad.v;
    CumIntPARArr[0].C := IntPar.v;
    CumIntPARArr[fActCrop].C := IntPar.v;
    if SoilWaterMod.Plantmodel is TGrowthCurvePlantRoots_fT
      then fT.V := TGrowthCurvePlantRoots_fT(SoilWaterMod.Plantmodel).fT.v
      else fT.V := 0;
    if SoilWaterMod is TSoilNitrogenUp then begin
      CumNUptakeArr[0].C := TSoilNitrogenUp(SoilWaterMod).ActNUptake.v;//Plantmodel.p_NUptakeRate.v*10;
      CumNUptakeArr[fActCrop].C := TSoilNitrogenUp(SoilWaterMod).ActNUptake.v;//.Plantmodel.p_NUptakeRate.v*10;
    end;
    CumQfTArr[0].C := IntPar.v*fT.v;
    CumQfTArr[fActCrop].C := IntPar.v*fT.v;
    CumGlobRadArr[0].C := GlobRad.v;
    CumGlobRadArr[fActCrop].C := GlobRad.v;
    CumNetRainArr[0].c := SoilWaterMod.NetRain.v;
    CumNetRainArr[fActCrop].c := SoilWaterMod.NetRain.v;
    CumDrainageArr[0].c := SoilWaterMod.CumDrainage.c;
    CumDrainageArr[fActCrop].c := SoilWaterMod.CumDrainage.c;
    CumDroughtDaysArr[0].c := 1-SoilWaterMod.TransRatio.v;
    CumDroughtDaysArr[fActCrop].c := 1-SoilWaterMod.TransRatio.v;
  end;
  if assigned(SoilMinMod) then begin
    if SoilMinMod is TSoilMinNH4 then begin
      SumMinr.v := TSoilMinNH4(SoilMinMod).SumMinr.v;

    end;
  end;
end;

function TFFResultsSubmod.IndexStr(i: integer): string;
begin
  if i = 0 then result := ''
  else begin
    result := IntToStr(i);
    while length(result) < 2 do result := '_'+result;
  end;
end;

procedure TFFResultsSubmod.Integrate;
begin
  inherited;
  PAW.v := SoilWaterMod.SumPAvSoilWater.v;
  PAWR.v := SoilWaterMod.SumPAvSoilWaterRZ.v;
  ActNShoot.v := ActShootN.v*10;
  if SoilWaterMod is TSoilNitrogen then begin
    SumNDrain.v := TSoilNitrogen(SoilWaterMod).CumSumNitrateLeaching.v;
  end
  else begin
    SumNmin.v := 0;
    Nmin0_90.v := 0;
    SumNDrain.v := 0;
  end;
  if SoilMinMod is TSoilMinNH4
    then begin
      NSupplyOrg.v := TSoilMinNH4(SoilMinMod).Added_N.v;
      SumNmin.v := TSoilMinNH4(SoilMinMod). SumNmin.v;
      Nmin0_90.v := TSoilMinNH4(SoilMinMod). Nmin0_90.v;
    end
    else begin
      NSupplyOrg.v := 0;
      SumNmin.v := 0;
      Nmin0_90.v := 0;
    end;
 NSystMin.v:=Nmin0_90.v + ActNShoot.v

end;


procedure Register;
begin
  RegisterComponents('Simulation', [TFFResultsSubmod]);
  RegisterComponents('Simulation', [TGrowthCurvePlantRoots_fT]);
end;

end.
