unit UMultiGrowthCurvePlant;

{******************************************************************************
*******************************************************************************
**  Simuliert logistisches, monomolekulares, Gomperz oder Richards Wachstum **
*******************************************************************************
{******************************************************************************

benötigte externe Größen:
                  - Temperatur                               -->Temp

benötigte Parameter:
                  - Wachstumsrate [1/d]                      -->rgr
                  - maximaler LAI [m2/m2]                    -->max
                  - Basistemperatur [°C]                     -->BaseTemp
                  - Richards Formparameter                   --> Richards_m
                  - Auspflanzdatum [d]                       -->SowingDate
                  - Rode/ Erntedatum [d]                     -->HarvestDate

Zustandsgrößen:
                  - Temperatursumme [°C]                     -->Tsum

Optionen:
                  - Wachstumart [logistisch,
                                 monomolekular,
                                 Gompertz,
                                 Richards]
******************************************************************************}

interface

uses
  UMod, UState, IniFiles, math, UAbstractPlant, USoilMineralisation,
  UMinMod2Pool, Windows, Messages, SysUtils, Classes, vcl.Controls, vcl.Dialogs,
  UGrowthCurvePlant;

type
  TMultiGrowthCurvePlant = class(TGrowthCurvePlant)

  const
    growth_count = 5;

  protected

  public

    Parameters_var: array[TStateVars, TParameters] of TVar;

    aufwuechse: array[TStateVars, TParameters, 0..growth_count] of TPar;
    harvestdates: array[0..growth_count] of TPar;

    harvestdates_langfristig: array[0..growth_count] of Double;
    sowingdates_langfristig: array[0..growth_count] of Double;
    harvestdate_langfristig: Double;
    sowingdate_langfristig: Double;

    harvestdate_var: Double;
    sowingdate_var: Double;

    with_multiple_aufwuechse: TOption;
    SoilNUptakeGrowthRate: TExternV;
    SumSoilNUptakeGrowth: TState;

    langfristiges_wetter: TOption;

    procedure CalcRates; override;
    procedure Integrate; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;

  end;

procedure Register;

implementation

procedure TMultiGrowthCurvePlant.CreateAll;

var
  State: TStateVars;
  Parm: TParameters;
  i: Integer;

begin
  inherited createall;

  ExternVcreate('SoilNUptakeGrowth', '[]', RateField, SoilNUptakeGrowthRate);
  StateCreate('SumSoilNUptakeGrowth', '[]', 0.0, false, SumSoilNUptakeGrowth);
  SumSoilNUptakeGrowth.PlotTograpH := True;

  for State := low(TStateVars) to high(TStateVars) do begin
    StateCreate(StateNames[State], StateUnits[State], 0.0, false,
      StateVars[State]);
    VarCreate(StateNames[State] + '_Change', StateUnits[State], 0, false,
      Growthrates[State]);
    if State <> DM then
      StateVars[State].PlotTograpH := true;
  end;

  for State := low(TStateVars) to high(TStateVars) do begin
    for Parm := low(TParameters) to high(TParameters) do begin
      Parcreate(StateNames[State] + '_' + ParNames[Parm], ParUnits[Parm], 0,
        Parameters[State, Parm]);
      VarCreate(StateNames[State] + '_' + ParNames[Parm] + ' aufwuechse',
        ParUnits[Parm], 0, False, Parameters_var[State, Parm]);
    end;
  end;

  OptCreate('with_multiple_aufwuechse', 'nein', with_multiple_aufwuechse);
  with_multiple_aufwuechse.OptionList.Clear;
  with_multiple_aufwuechse.OptionList.Add('nein');
  with_multiple_aufwuechse.OptionList.Add('ja');

  for i := 0 to growth_count do begin
    ParCreate('aufwuchs_' + IntToStr(i) + '_harvestdate', '[d]', 0,
      harvestdates[i]);
    for State := low(TStateVars) to high(TStateVars) do begin
      for Parm := low(TParameters) to high(TParameters) do begin
        ParCreate('aufwuchs_' + IntToStr(i) + '_' + StateNames[State] + '_' +
          ParNames[Parm],
          ParUnits[Parm], 0, aufwuechse[State, Parm, i]);
      end;
    end;
  end;

  OptCreate('langfristiges_wetter', 'nein', langfristiges_wetter);
  langfristiges_wetter.OptionList.Clear;
  langfristiges_wetter.OptionList.Add('nein');
  langfristiges_wetter.OptionList.Add('ja');

end;

procedure TMultiGrowthCurvePlant.Init(var GlobMod: TMod);

var
  i: Integer;
  State: TStateVars;
  Parm: TParameters;
begin
  plantIsGrowing := false;
  inherited Init(GlobMod);

  if (AnsiLowerCase(with_multiple_aufwuechse.Option) = 'ja') then begin

    if AnsiLowerCase(langfristiges_wetter.Option) = 'ja' then begin
      for i := 0 to growth_count do begin
        harvestdates_langfristig[i] := harvestdates[i].v;
      end;
    end;

    // initialisieren auf die Parameter vom 0. Aufwuchs
    for State := low(TStateVars) to high(TStateVars) do begin
      for Parm := low(TParameters) to high(TParameters) do begin
        Parameters_var[State, Parm].v := aufwuechse[State, Parm, 0].v;
      end;
      StateVars[State].C := 0;
      StateVars[State].v := Parameters_var[State, IniValue].v;
      CurveSwitches[State] := false;
    end;

  end else begin
    for State := low(TStateVars) to high(TStateVars) do begin
      for Parm := low(TParameters) to high(TParameters) do begin
        Parameters_var[State, Parm].v := Parameters[State, Parm].v;
      end;
      StateVars[State].C := 0;
      StateVars[State].v := Parameters_var[State, IniValue].v;
      CurveSwitches[State] := false;
    end;
  end;

  harvestdate_var := HarvestDate.v;
  sowingdate_var := SowingDate.v;

  harvestdate_langfristig := HarvestDate.v;
  sowingdate_langfristig := SowingDate.v;


end;

procedure TMultiGrowthCurvePlant.CalcRates;
var
  State: TStateVars;
  Parm: TParameters;
  i: Integer;
  day, month, year1, day_a, month_a, year_a: Word;
  firstDay: Double;
begin
  //if GlobTime.v = GlobMod.StartTime then
  //  Init(GlobMod);

  // nur für Langfrist!
  if AnsiLowerCase(langfristiges_wetter.Option) = 'ja' then begin
    DecodeDate(GlobMod.Time.v, year_a, month_a, day_a);
    firstDay := EncodeDate(year_a, 1, 1);

    if (AnsiLowerCase(with_multiple_aufwuechse.Option) = 'ja') then begin
      for i := 0 to growth_count do begin
        DecodeDate(firstDay + harvestdates_langfristig[i], year_a, month_a,
          day_a);
        harvestdates[i].v := EncodeDate(year_a, month_a, day_a);
      end;

      sowingdate_var := EncodeDate(year_a, 1, 1);
      HarvestDate_var := EncodeDate(year_a, 12, 31);

    end else begin
      DecodeDate(firstDay + harvestdate_langfristig, year_a, month_a, day_a);
      HarvestDate_var := EncodeDate(year_a, month_a, day_a);

      DecodeDate(firstDay + sowingdate_langfristig, year_a, month_a, day_a);
      SowingDate_var := EncodeDate(year_a, month_a, day_a);
    end;

  end;

  // nur Miltiple Cuts!

  if (AnsiLowerCase(with_multiple_aufwuechse.Option) = 'ja') then begin

    DecodeDate(GlobMod.Time.v, Year1, Month, Day);

    if ((GlobMod.Time.v < SowingDate_var) or (GlobMod.Time.v >
      HarvestDate_var)) then begin
      for State := low(TStateVars) to high(TStateVars) do begin
        StateVars[State].V := 0.0;
        StateVars[State].c := 0.0;
        TSum.v := 0.0;
        TSum.c := 0;
        CurveSwitches[State] := false;
        SumSoilNUptakeGrowth.c := 0;
      end;
      Exit;
    end;

    if (GlobMod.Time.v = SowingDate_var) then begin
      for State := low(TStateVars) to high(TStateVars) do begin
        for Parm := low(TParameters) to high(TParameters) do begin
          Parameters_var[State, Parm].v := aufwuechse[State, Parm, 0].v;
        end;
        StateVars[State].C := 0;
        StateVars[State].v := Parameters_var[State, IniValue].v;
        CurveSwitches[State] := false;
      end;
    end;

    for i := 0 to growth_count-1 do begin
      if (harvestdates[i].v = GlobTime.v) then begin
        for State := low(TStateVars) to high(TStateVars) do begin
          for Parm := low(TParameters) to high(TParameters) do begin
            if (harvestdates[i+1].v > GlobTime.v) then begin
              Parameters_var[State, Parm].v := aufwuechse[State, Parm, i + 1].v;
            end;
          end;
          StateVars[State].C := 0;
          StateVars[State].v := Parameters_var[State, IniValue].v;
          CurveSwitches[State] := false;
        end;
      end;
    end;

  end;



  // innerhalb der Wachstumsperiode
  if (GlobTime.v >= SowingDate_var) and (GlobTime.v <= HarvestDate_var) then
    begin
    plantIsGrowing := true;
    for State := low(TStateVars) to high(TStateVars) do begin
      if StateVars[State].V <= 0.0 then
        StateVars[State].v := Parameters_var[State, IniValue].v;
    end;
  end;

  if (GlobTime.v >= SowingDate_var) and (GlobTime.v <= HarvestDate_var) then
    begin
    TSum.c := max(0, Temp.v - Parameters_var[LAI, BaseTemp].v);

    if TSum.v >= TempSumEmerge.v then begin
      for State := low(TStateVars) to high(TStateVars) do begin
        // falls aktuelle Temperatur > Basistemperatur, dann Aufwuchs
        if Temp.v >= Parameters_var[State, BaseTemp].v then begin
          StateVars[State].C := CalcGrowthRate(StateVars[State].v, temp.v,
            Parameters_var[State, BaseTemp].v,
            Parameters_var[State, rgr].v, Parameters_var[State, gr].v,
            Parameters_var[State, capacity].v, Parameters_var[State,
            Richards_f].V, CurveTypes[State], State);
        end else begin
          StateVars[State].c := 0.0;
        end;
      end;
    end;
    SumSoilNUptakeGrowth.c := SoilNUptakeGrowthRate.v;
  end else begin
    SumSoilNUptakeGrowth.c := 0;
    SumSoilNUptakeGrowth.v := 0;
  end;

  if GlobTime.v = harvestdate_var then begin
    plantIsGrowing := False;

    if (SoilMinMOd is TMinMod2Pool) then begin
      if self <> nil then
        TMinMod2Pool(self.SoilMinMOd).calcRatesIsActive := false;

      if (NextCrop <> nil) and (NextCrop.SoilMinMOd <> nil) then
        TMinMod2Pool(NextCrop.SoilMinMOd).calcRatesIsActive := true;
    end;
  end;

  if GlobTime.v > harvestdate_var then begin

    C_Residues.v := C_residues.v + (1 - Harvestindex.v) * StateVars[DM].v *
      C_cont_Res.v; // conversion from g/m2 (Plantmodel) to kg/ha (Soilmin)
    N_Residues.v := N_Residues.v + (1 - N_harvestindex.v) * StateVars[ShootN].v;
      // conversion from g/m2 (Plantmodel) to kg/ha (Soilmin)

    if nextCrop <> nil then begin

      if EvapModel <> nil then begin
        EvapModel.PlantModel := NextCrop;
      end;

      if (SoilMinMOd is TMinMod2Pool) then begin

      end else begin
        if SoilMinMod <> nil then begin
          SoilMinMod.PlantModel := nextCrop;
          NextCrop.SoilMinMod := SoilMinMod;
        end;
      end;

      if SoilLayerMod <> nil then begin
        SoilLayerMod.PlantModel := NextCrop;
        NextCrop.SoilLayerMod := SoilLayerMod;
      end;

    end;

    for State := low(TStateVars) to high(TStateVars) do begin
      StateVars[State].V := 0.0;
      StateVars[State].c := 0.0;
      TSum.v := 0.0;
      TSum.c := 0;
      CurveSwitches[State] := false;
    end;

  end;

  for State := low(TStateVars) to high(TStateVars) do  begin
    GrowthRates[state].v := StateVars[State].c;

  end;



end;

procedure TMultiGrowthCurvePlant.Integrate;
var
  j: integer;
  State: TState;
begin
  // for all state variables do...
  for j := 0 to StateStrList.count - 1 do begin
    State := TState(StateStrList.objects[j]);
    State.v := State.v + State.c * GlobTime.c;
  end;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TMultiGrowthCurvePlant]);
end;

end.

