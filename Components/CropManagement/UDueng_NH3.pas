unit UDueng_NH3;

interface
uses
  UMod, UState, IniFiles, Classes, UDueng;

type
TWeathRec = record
              Time: TDateTime;
              Wind: real;
              TMPM: real;
              GlobRad: real;
              Rain: real;
            end;

T_f_NH3_calc  = (KangNi, Factor);  // Options for calculation of NH3 Emission
T_Slurry_Type = (cattle, pig, biogas, no_slurry);
T_CropType    = (maize, wheat, gras);

TDueng_NH3 = class(TDueng)
private
  f_NH3_Calcmethod: T_f_NH3_calc;  // calculation of NH3 Emission
  Slurry_Type: T_Slurry_Type;
  CropType: T_CropType;

protected
  WeathArr: array of TWeathRec;
  fWindName, fTMPMName, fGlobRadName, fRainName: string;
  NH3emissionArr: array[1..5] of real;
  WeatherFN: string;

public

  f_NH3: TPar;     // NH3 emission factor

  // Parameter for KangNi model
  pH_slurry: TPar;
  Visc_slurry: TPar;
  DM_slurry: TPar;


  TMPact: TVar;
//  TMPext: TVar;
  TMPave3: TVar;
//  TMPM: TExternV;
  Windact: TVar;
  Windave3: TVar;
  GlobRadact: TVar;
  GlobRadave3: TVar;
  Rainact: TVar;
  Rainsum3: TVar;

  NH4applied: TVar;
  NH3emissionTotal: TVar;
  NH3emission: TVar;
  CumNH3emission: TState;
  Km: TVar;

  LAI: TExternV;

  f_NH3_Calcmethod_Option: TOption; // Calculation method for NH3 Emission
  Slurry_Type_Option: TOption;  //pig, cattle, biogas, no_slurry
  CropType_Option: TOption;  //maize, wheat, gras

  procedure Init(var GlobMod: TMod); Override;
  procedure CalcRates; override;
  procedure CreateAll; override;
  constructor Create(AOwner : TComponent); override;
published
  property WindName: string read fWindName write fWindName;
  property TMPMName: string read fTMPMName write fTMPMName;
  property GlobRadName: string read fGlobRadName write fGlobRadName;
  property RainName: string read fRainName write fRainName;

  Property Ex_LAI: TExternV read LAI write LAI;

end;

procedure Register;

implementation
uses
  SysUtils, vcl.Dialogs;

constructor TDueng_NH3.create(AOwner : TComponent);

begin
  inherited create(AOwner);
  fWindName := 'Wind';
  fTMPMName := 'TMPM';
  fGlobRadName := 'Rad_Int';
  fRainName := 'Rain';
end;


procedure TDueng_NH3.CreateAll;
begin
  inherited createAll;

  VarCreate('TMPact', '[°C]', 0, true, TMPact, 'actual Temperature');
//  VarCreate('TMPext', '[°C]', 0, true, TMPext, 'external Temperature (from weather file)');
  VarCreate('TMPave3', '[°C]', 0, true, TMPave3, 'avarage Temperature of following 3 days');
  VarCreate('Windact', '[m/s]', 0, true, Windact, 'actual Wind speed');
  VarCreate('Windave3', '[m/s]', 0, true, Windave3, 'avarage  Wind speed of following 3 days');
  VarCreate('GlobRadact', '[W/m2]', 0, true, GlobRadact, 'actual Global radiation speed');
  VarCreate('GlobRadave3', '[W/m2]', 0, true, GlobRadave3, 'avarage  Global radiation of following 3 days');
  VarCreate('Rainact', '[mm]', 0, true, Rainact, 'actual Rain');
  VarCreate('Rainsum3', '[mm]', 0, true, Rainsum3, 'Rain sum of following 3 days');

  VarCreate('NH4applied', '[kg N/ha]', 0, true, NH4applied, 'NH4 applied by fertilisation');
  VarCreate('NH3emissionTotal', '[kg N/ha]', 0, true, NH3emissionTotal, 'Total NH3 emission from NH4 fertilisation');
  VarCreate('NH3emission', '[kg N/ha]', 0, true, NH3emission, 'Actual NH3 emission');
  VarCreate('Km', '[kg N/ha]', 0, true, Km, '');

  ParCreate('f_NH3','[-]',0.3,f_NH3,'NH3 emission factor (used if NH3_Calcmethod = Factor)');

  ParCreate('pH_slurry','[-]',7.3,pH_slurry,'pH in slurry (currently not used)');
  ParCreate('Visc_slurry','[mPa s]',180,Visc_slurry,'Viscosity of slurry (currently not used)');
  ParCreate('DM_slurry','[%]',7,DM_slurry,'Dry matter in slurry (currently not used)');
  StateCreate( 'CumNH3Emission', '[kg N/ha]', 0, true, CumNH3Emission,'cumulative NH3 emission');
  CumNH3Emission.WriteFinalValue := true;
  ExternVCreate( 'LAI', '[-]', StateField, LAI);

  // Options
  OptCreate('f_NH3_Calcmethod', 'KangNi', f_NH3_Calcmethod_Option, 'Option for calculation of NH3 Emission');
  f_NH3_Calcmethod_Option.OptionList.Add('KangNi');
  f_NH3_Calcmethod_Option.OptionList.Add('Factor');

  OptCreate('Slurry_Type', 'no_slurry', Slurry_Type_Option, 'Option for slurry type');
  Slurry_Type_Option.OptionList.Add('biogas');
  Slurry_Type_Option.OptionList.Add('cattle');
  Slurry_Type_Option.OptionList.Add('pig');
  Slurry_Type_Option.OptionList.Add('no_slurry');

  OptCreate('CropType', 'maize', CropType_Option, 'Option for crop type');
  CropType_Option.OptionList.Add('maize');
  CropType_Option.OptionList.Add('wheat');
  CropType_Option.OptionList.Add('gras');

//  ExternVCreate('TMPM', '', statefield, TMPM);
end;

procedure TDueng_NH3.CalcRates;
var
  index  : integer;
  FertState : TState;
  DateString : String;
  ActDate : TDateTime;
  i,j,n: integer;
  slurry_yes_no, f_cattle, f_pig, f_rain, f_maize, f_wheat : integer;

begin
//  TMPext.v := TMPM.v;
  CumNH3emission.c  := 0.0;
  CumDueng.c := 0.0;
  i := round((GlobMod.Time.v-GlobMod.StartTime) / GlobMod.TimeStep);
  TMPact.v := WeathArr[i].TMPM;
  Windact.v := WeathArr[i].Wind;
  GlobRadact.v := WeathArr[i].GlobRad;
  Rainact.v := WeathArr[i].Rain;
  n := round(3 / GlobMod.TimeStep);
  ActDate := GlobTime.v;
  DateSTring := DateToStr(ActDate);
  index := DuengTermine.IndexOf(DateSTring);
  If Index <> -1 then begin
     TMPave3.v := 0;
    Windave3.v := 0;
    GlobRadave3.v := 0;
    Rainsum3.v := 0;
    for j := i to i+n-1 do TMPave3.v := TMPave3.v + WeathArr[j].TMPM/n;
    for j := i to i+n-1 do Windave3.v := Windave3.v + WeathArr[j].Wind/n;
    for j := i to i+n-1 do GlobRadave3.v := GlobRadave3.v + WeathArr[j].GlobRad/n;
    for j := i to i+n-1 do Rainsum3.v := Rainsum3.v + WeathArr[j].Rain;

    FertState := Duengungen[index];
    NH4applied.v := FertState.v;

    if(Rainsum3.v > 5) then f_rain:=1 else f_rain:=0;

    case CropType of
            maize: begin f_maize := 1; f_wheat := 0;  end;
            wheat: begin f_maize := 0; f_wheat := 1;  end;
            gras: begin f_maize := 0; f_wheat := 0;  end;
    end;

    case Slurry_Type of
             cattle: begin f_cattle := 1; f_pig := 0; slurry_yes_no := 1; end;
             pig: begin f_cattle := 0; f_pig:=1; slurry_yes_no:=1; end;
             biogas: begin f_cattle:=0; f_pig:=0; slurry_yes_no:=1; end;
             no_slurry: slurry_yes_no:=0;
    end;

    case f_NH3_Calcmethod of
             KangNi: begin             // Kang Ni et al. (2012)
                      NH3emissionTotal.v:=exp(0.552-0.5348*f_cattle-0.4636*f_pig+0.0121*NH4applied.v-1.5498*f_rain-1.2334*f_maize-0.2254*LAI.v+0.1203*TMPave3.v+0.2238*Windave3.v-0.0033*GlobRadave3.v)*slurry_yes_no; // calculate Nmax
                      //Km.v:=exp(11.4763-0.6066*f_pig-0.8583*pH_slurry-0.0012*Visc_slurry+0.1544*DM_slurry-1.8270*f_rain-2.1136*f_wheat+0.6622*LAI.v-0.1435*TMPave3.v-0.0033*GlobRadave3.v)*slurry_yes_no; // calculate Km

                     end;
             Factor: NH3emissionTotal.v := f_NH3.v*NH4applied.v*slurry_yes_no;      // nur ein Emissionsfaktor
    end;

    SoilNitrate.f_v^ := SoilNitrate.v+NH4applied.v-NH3emissionTotal.v;
    CumNH3emission.c := NH3EmissionTotal.v;
    CumDueng.c := NH4applied.v-NH3emissionTotal.v;
    FertState.v := 0.0;
    Duengungen[index].v := 0.0;
    Duengungen[index].name := '';
    for j := 1 to 5 do NH3emissionArr[j] := NH3emissionTotal.v / 5; // Hier Aufteilung der Emissionen
  end
  else begin
    NH4applied.v := 0;
    NH3emissionTotal.v := 0;
    cumNH3emission.c := 0.0;
    CumDueng.c := 0.0;
  end;
  // actual NH3 emission:
  if NH3emissionArr[1] > 0 then begin
    NH3emission.v := NH3emissionArr[1];
    for j := 1 to 4 do NH3emissionArr[j] := NH3emissionArr[j+1];
    NH3emissionArr[5] := 0;
  end
  else NH3emission.v := 0;
end;


procedure TDueng_NH3.Init(var GlobMod: TMod);
var
  i,j,k, Windndx, TMPMndx, GlobRadndx, Rainndx, StartDayndx,ActNdx,
  weatherdatalength : integer;
  s: string;
  WeatherDataLine: TStringList;
  FirstWeatherDay : real;

begin
  inherited Init(GlobMod);
  WeatherDataLine := TStringList.Create;

  // read weather file to array
  // only if the actual weather file was not read or if the actual model run has a different time interval
  // UB 12.01.2016
  if (WeatherFN <> GlobMod.WeatherFile.FName)
     or (WeathArr[0].Time > GlobMod.StartTime)
     or (WeathArr[length(WeathArr)-1].Time < GlobMod.EndTime)
  then begin
    Windndx := GlobMod.WeatherFile.indexOf(WindName);
    TMPMndx := GlobMod.WeatherFile.indexOf(TMPMName);
    GlobRadndx := GlobMod.WeatherFile.indexOf(GlobRadName);
    Rainndx := GlobMod.WeatherFile.indexOf(RainName);
    s := GlobMod.StatusBar.Panels[1].Text;
    GlobMod.StatusBar.Panels[1].Text := 'Reading weather file for TDueng_NH3';
    GlobMod.StatusBar.Repaint;
    i := GlobMod.WeatherFile.actnr;
    WeatherDataLength := round((GlobMod.EndTime / GlobMod.TimeStep)-(GlobMod.StartTime / GlobMod.TimeStep))+1;
    SetLength(WeathArr,weatherdatalength);
    k := 0;
    WeatherDataLine.CommaText := GlobMod.WeatherFile.slFile[2];
    FirstWeatherDay := round(StrTofloat(WeatherDataLine[0]));
 //   StartDayndx := self.GlobMod.WeatherFile.slFile. IndexOf(floattostr(globMod.StartTime));
    ActNdx := round(GlobMod.StartTime-FirstWeatherday+2);
    for j := round(GlobMod.StartTime / GlobMod.TimeStep) to round(GlobMod.EndTime / GlobMod.TimeStep) do begin
      //GlobMod.WeatherFile.LocateFor(GlobMod.Time.Name, j*GlobMod.TimeStep);
      if GlobMod.WeatherFile.n_Line >= actNdx then
        WeatherDataLine.CommaText := GlobMod.WeatherFile.slFile[ActNdx];
      //self.GlobMod.WeatherFile.
      WeathArr[k].Time := StrToFloat(WeatherDataLine[0]);
      WeathArr[k].Wind := StrToFloat(WeatherDataLine[WindNdx]);
      WeathArr[k].TMPM := StrToFloat(WeatherDataLine[TMPMNdx]);
      WeathArr[k].GlobRad := StrToFloat(WeatherDataLine[GlobRadNdx]);
      WeathArr[k].Rain := StrToFloat(WeatherDataLine[RainNdx]);

{      WeathArr[k].Time := j*GlobMod.TimeStep;
      WeathArr[k].Wind := GlobMod.WeatherFile.getValue(WindName);
      WeathArr[k].TMPM := GlobMod.WeatherFile.getValue(TMPMName);
      WeathArr[k].GlobRad := GlobMod.WeatherFile.getValue(GlobRadName);
      WeathArr[k].Rain := GlobMod.WeatherFile.getValue(RainName);  }
      inc(k);
      inc(actNdx);
    end;
    GlobMod.WeatherFile.actnr := i;
    GlobMod.StatusBar.Panels[1].Text := s;
    GlobMod.StatusBar.Repaint;
    WeatherFN := GlobMod.WeatherFile.FName;
  end;

  if uppercase(f_NH3_calcmethod_Option.Option) = uppercase('KangNi')
    then f_NH3_calcmethod := KangNi;
  if uppercase(f_NH3_calcmethod_Option.Option) = uppercase('Factor')
    then f_NH3_calcmethod := Factor;

  if uppercase(Slurry_Type_Option.Option)= uppercase('cattle')
    then Slurry_Type := cattle;
  if uppercase(Slurry_Type_Option.Option)= uppercase('pig')
    then Slurry_Type := pig;
  if uppercase(Slurry_Type_Option.Option)= uppercase('biogas')
    then Slurry_Type := biogas;
  if uppercase(Slurry_Type_Option.Option)= uppercase('no_slurry')
    then Slurry_Type := no_slurry;

  if uppercase(CropType_Option.Option)= uppercase('maize')
   then CropType := maize;
  if uppercase(CropType_Option.Option)= uppercase('wheat')
   then CropType := wheat;
  if uppercase(CropType_Option.Option)= uppercase('gras')
   then CropType := gras;

  WeatherDataLine.free;

end;

procedure Register;
begin
  RegisterComponents('Simulation', [TDueng_NH3]);
end;

end.
