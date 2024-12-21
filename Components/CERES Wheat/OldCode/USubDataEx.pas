unit USubDataEx;

//{$INCLUDE compiler_settings.inc}
interface

uses
  Classes, Dialogs, Sysutils,
  USoilWaterMod, UMod, UState;//, UFORMMOD;

type
  TOptDataEx = (DataEx,NoDataEx);
  // weWind must stay at last position and weTMPM at first (0) in enumeration!!
  TWeatherEx = (weTMPM, weTMPMX, weTMPMN, weGlobRad, weRain, weLF, weWind);

  TSubDataEX = class(TSubModel)
  private
    fSWMOD: TSoilWaterMod;

    // switches for images- export
    ExportAbb_Act, ExportAbb_Ref,
    done, done1, done2, done3, done4, done5, done6, done7, done8, done9,
    done10, done11, done12, done13, done14, done15: boolean;
    dateC2, dateC3,
    sumIrrigation_, IrriAmount,
    PSI_Crit_min, PSI_Crit_max,
    PSI_Root_of_PSI_Crit,
    WG0_90_,
    // last weather export event
    DateWeatherEx:   Real;
    // static grid for 10 days weather data, sum and mean
    Weather: array[0..6,0..11] of Real;

    projname,
    fn_DatFile,
    fn_AbbFile: String;
    // regular export file
    exDatFile,
    // export file for images
    exAbbFile: TStringList;

    procedure WriteActLine;
    procedure WriteActAbbLine;
    procedure WriteRefLine;
    procedure WriteRefAbbLine;

  public
    optDataEx : TOption;
    optProject: Toption;

    MinType : TPar;
    ExportType: TPar;
    avNuptake: TPar;
    sumDrainVB, sumMinVB: TVar;
    // weather data
    TMPM,
    TMPMX,
    TMPMN,
    GlobRad,
    Rain,
    LF,
    Wind: TExternV;

    DayOfYear: TExternV;
    NAPP1: TExternV;
    NAPP2: TExternV;
    NAPP3: TExternV;
    SumDrain: TExternV;
    CumDrainage: TExternV;
    ProznFK0_Weff: TExternV;
    ProznFK0_30: TExternV;
    GRYD: TExternV;
    NUpTake : TExternV;
    Vorfrucht : TExternV;
    MineralisedN : TExternV;
    TransRatio: TExternV;
    zr: TExternV;
    EC: TExternV;

    sumIrrigation,
    pF_Crit,
    Szenario,
    LAI,
    psiRoot,
    WG0_90:       TExternV;

    WMenge  :  array[1..21] of TExternV;
    theta_arr: array[1..21] of TExternV;

    cumTemp, cumRain, cumRad, cumRad_, cumCWSI: real;
    DrainStart, MinStart: real;

    procedure Init(var GlobMod: TMod); override;
    procedure CreateAll; override;
    destructor Destroy; override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    property swmod: TSoilWaterMod read fSWMOD write fSWMOD;
  end;

procedure Register;

implementation
uses math;

procedure TSubDataEx.createAll;
var
  i: integer;
  ndx_str: String;
begin
  inherited createAll;

  // weather data
  ExternVCreate('TMPM', '[?C]', StateField, TMPM);
  ExternVCreate('TMPMX', '[?C]', StateField, TMPMX);
  ExternVCreate('TMPMN', '[?C]', StateField, TMPMN);
  ExternVCreate('GlobRad', '[MJ/m2/d]', StateField, GlobRad);
  ExternVCreate('Rain', '[mm/d]', StateField, Rain);
  ExternVCreate('LF', '[%]', StateField, LF);
  ExternVCreate('Wind', '[W/m2]', StateField, Wind);

  ExternVCreate('Transratio', '',statefield,Transratio);
  ExternVCreate('DayOfYear', '',statefield, DayOfYear);
  ExternVCreate('EC', '',statefield, EC);
  ExternVCreate('GRYD', '',statefield, GRYD);
  ExternVCreate('Szenario', '',statefield, Szenario);
  ExternVCreate('zr', '',statefield, zr);
  ExternVCreate('SumDrain', '',statefield, SumDrain);
  ExternVCreate('CumDrainage', '',statefield, CumDrainage);
  ExternVCreate('NUpTake', '',statefield, NUpTake);
  ExternVCreate('MineralisedN', '',statefield, MineralisedN);
  ExternVCreate('Vorfrucht', '',statefield, Vorfrucht);
  ExternVCreate('ProznFK0_Weff', '',statefield, ProznFK0_Weff);
  ExternVCreate('ProznFK0_30', '',statefield, ProznFK0_30);
  ExternVCreate('NAPP1', '',statefield,NAPP1);
  ExternVCreate('NAPP2', '',statefield,NAPP2);
  ExternVCreate('NAPP3', '',statefield,NAPP3);
  ExternVCreate('sumIrrigation', '[mm]',StateField, sumIrrigation);
  ExternVCreate('LAI', '[m2/m2]',StateField, LAI);
  ExternVcreate('psiRoot', '[pF]',StateField, psiRoot);
  ExternVcreate('pF_Crit', '[pF]',StateField, pF_Crit);
  ExternVcreate('WG0_100', '[cm3/cm3]',StateField, WG0_90);
  VarCreate('sumDrainVB', '[KgN/ha]', 0, True, sumDrainVB);
  VarCreate('sumMinVB', '[KgN/ha]', 0, True, sumMinVB);

  done:= false;
  for i := 1 to 21 do begin
    if i <= 9 then
      ndx_str := '_'+IntTostr(i)
    else
      ndx_str := IntTostr(i);
    ExternVCreate('WMenge'+ndx_str,'[cm]',statefield, WMenge[i]);
    ExternVCreate('WG'+ndx_str,'[cm]',statefield, theta_arr[i]);
    //Varcreate('WG'+ndx_str, '[cm3.cm-3]',0.3, true, theta_arr[i]);
  end;

  ParCreate('avNuptake', '[kg/ha]',0,avNuptake);
  ParCreate('ExportType', '[-]',0,ExportType);
  ParCreate('MinType', '[-]',0,MinType);
  //ParCreate('k1', '[kg/kg]',0.0018, k1);

  OptCreate('optProject', '-',optProject);
  OptCreate('optDataEx', 'DataEX',optDataEx);
  optDataEx.OptionList.Clear;
  optDataEx.OptionList.Add('DataEx');
  optDataEx.OptionList.Add('NoDataEx');

  ExportAbb_Act:=true;
  ExportAbb_Ref:=true;

  exDatFile:= TStringList.Create;
  exAbbFile:= TStringList.Create;
  fn_DatFile:= '';
  fn_AbbFile:= '';
end;

destructor TsubDataEx.Destroy;
begin
  exDatFile.Free;
  exAbbFile.Free;

  inherited Destroy;
end;

procedure TsubDataEx.Init(var GlobMod: TMod);
var
  i, j, ExType: Integer;
  nameDat, nameAbb,
  current: String;
begin
  inherited init(GlobMod);

  // init weather grid
  for i:=0 to High(Weather[0]) do
    for j:=0 to High(Weather) do
      Weather[j][i]:=0;

  if GlobMod.FIniFiles.Objects[0] = GlobMod.ActIniFile then
    done:= false; // first inifile

  done1:= false;
  done2:= false;
  done3:= false;
  done4:= false;
  done5:= false;
  done6:= false;
  done7:= false;
  done8:= false;
  done9:= false;
  done10:= false;
  done11:= false;
  done12:= false;
  done13:= false;
  done14:= false;
  done15:= false;

  cumCWSI:=0;
  cumTemp:= 0;
  cumRain:= 0;
  cumRad_:= 0;
  cumRad:= 0;
  DrainStart:= 0;
  MinStart:=0;
  SumDrainVB.v:= 0;
  SumMinVb.v:=0;
  dateC2:=0;
  dateC3:=0;
  sumIrrigation_:=0;
  IrriAmount:=0;

  WG0_90_:=0;
  PSI_Root_of_PSI_Crit:=0;
  PSI_Crit_min:=0;
  PSI_Crit_max:=0;
  DateWeatherEx:=GlobMod.StartTime;

  // initialize export dir and filenames for the whole run
  if GlobMod.FIniFiles.Objects[0] = GlobMod.ActIniFile then
    begin // first inifile
    if GlobTime.v <= GlobMod.StartTime then
      begin // at start
{$ifdef fpc}
      current:=GlobMod.ApplicationPath;
{$else}
      current:=ExtractFilePath(ParamStr(0));
{$endif}

      projname:='';
      if optProject.option <> '-' then
        projname:=optProject.option;

      fn_DatFile:= '';
      fn_AbbFile:= '';
      nameDat:= '';
      nameAbb:= '';

      ExType := trunc(ExportType.v);
      case ExType of
        1: // actual weather
          begin
          nameDat:= 'Export_Act';
          nameAbb:= 'Export_Act_Abb';
          end;
        2: // scenario
          begin
          nameDat:= 'Export_SZ';
          nameAbb:= '';
          end;
        3: // reference
          begin
          nameDat:= 'Export_Ref';
          nameAbb:= 'Export_Ref_Abb';
          end;
        5: // temp
          begin
          nameDat:= 'Temp_';
          nameAbb:= '';
          end;
      end;

      if nameDat <> '' then
        fn_DatFile:= Concat(current, '..\', projname, '\SubDataEx\',
          nameDat, '.csv');
      if nameAbb <> '' then
        fn_AbbFile:= Concat(current, '..\', projname, '\SubDataEx\',
          nameAbb, '.csv');

{$ifdef fpc}
      DoDirSeparators(fn_DatFile);
      DoDirSeparators(fn_AbbFile);
{$endif}
      end;
    end;
end;

procedure TSubDataEx.CalcRates;
var
  i, j: integer;
  wDat: TWeatherEx;
begin
  if ExportType.v = 1 then // Aktuelles Wetter:
    begin
    // Run abbrechen, wenn mehr als 13 Tage Durchschnittswetter angehängt sind:
    if Szenario.v > GlobTime.v + 13 then
      GlobMod.Endtime:= Szenario.v;
    // Run abbrechen, wenn die Wetterdatei zuende ist:
    if (Szenario.v > 0) and (GlobTime.v > Szenario.v) then
      GlobMod.Endtime:= Szenario.v;
    end;

  // clear sum
  for wDat:=weTMPM to weWind do
    Weather[Ord(wDat)][1]:=0;

  // rotate weather grid and build new sum
  for i:=High(Weather[0]) downto 3 do
    for wDat:=weTMPM to weWind do
      begin j:=Ord(wDat);
      Weather[j][i]:=Weather[j][i-1];
      Weather[j][1]:=Weather[j][1]+Weather[j][i];
      end;

  // assign new value
  for wDat:=weTMPM to weWind do
    begin i:=2; j:=Ord(wDat);
    case wDat  of
      weTMPM:    Weather[j][i]:=TMPM.v;
      weTMPMX:   Weather[j][i]:=TMPMX.v;
      weTMPMN:   Weather[j][i]:=TMPMN.v;
      weGlobRad: Weather[j][i]:=GlobRad.v;
      weRain:    Weather[j][i]:=Rain.v;
      weLF:      Weather[j][i]:=LF.v;
      weWind:    Weather[j][i]:=Wind.v;
      end;
    Weather[j][1]:=Weather[j][1]+Weather[j][i];
    end;

  // generate mean for weather over 10 days
  for wDat:=weTMPM to weWind do
    Weather[Ord(wDat)][0]:=Weather[Ord(wDat)][1]/10;

  {  if (EC.v>=50) and (ec.v <=75) then begin
   cumGRcorr50_75:=cumGRcorr50_75+GlobRad.v*Transratio.v;
   cumCWSI:=CumCWSI+1/Transratio.v;
   cumrad:= GlobRad.v+Cumrad;
  end; 29.03.11 Ratjen }

  cumTemp:=cumTemp+TMPM.v;
  cumRad:=cumRad+GlobRad.v;
  cumRain:=cumRain+Rain.v;

  if (GlobTime.v=GlobMod.StartTime) and (ExportType.v = 4)  then begin
    SWMOD.Opt_IniMethod:= parameter;
    SWMOD.init(GlobMod);
    end;
end;

procedure TSubDataEx.WriteActLine;
var
  line: String;
begin
  if exDatFile.Count < 1 then
    begin
    line:=Concat('IniFile:,',
      'Time:,',
      'BBCH:,',
      'ProznFK0_100:,',
      'N-Auswaschung_[kgN/ha]:,',
      'N-Aufnahme_[kgN/ha]:,',
      'Mineralisation_[kgN/ha]:,',
      'GRYD_[dt/ha]:,',
      'LAI_[m2/m2]:,',
      'cumTemp:,',
      'cumRain:,',
      'cumRad:,',
      'Durchwurzelung:,',
      'MinType:,',
      'Sollwert:,',
      'Szenario:,',
      'NApp1:,',
      'NApp2:,',
      'NApp3:');
      exDatFile.Add(line);
    end;

  line:=Concat(ExtractFileName(GlobMod.actinifile.filename)+',',
    FloatToStrF(globtime.v-1,ffFixed,15,0)+',',
    FloatToStrF(EC.v,ffFixed,15,2)+',',
    FloatToStrF(ProznFK0_Weff.v,ffFixed,15,0)+',',
    FloatToStrF(sumdrainVB.v,ffFixed,15,2)+',',
    FloatToStrF(NUpTake.v,ffFixed,15,2)+',',
    FloatToStrF(SumMinVB.v,ffFixed,15,2)+',',
    FloatToStrF(GRYD.v,ffFixed,15,2)+',',
    FloatToStrF(LAI.v,ffFixed,15,2)+',',
    FloatToStrF(cumTemp,ffFixed,15,2)+',',
    FloatToStrF(cumRain,ffFixed,15,2)+',',
    FloatToStrF(cumRad,ffFixed,15,2)+',',
    FloatToStrF(zr.v,ffFixed,15,1)+',',
    FloatToStrF(Mintype.v,ffFixed,15,0)+',',
    FloatToStrF(avNuptake.v,ffFixed,15,0)+',',
    FloatToStrF(Szenario.v,ffFixed,15,0)+',',
    FloatToStrF(NApp1.v,ffFixed,15,2)+',',
    FloatToStrF(NApp2.v,ffFixed,15,2)+',',
    FloatToStrF(NApp3.v,ffFixed,15,2));
  exDatFile.Add(line);
end;

procedure TSubDataEx.WriteActAbbLine;
var
  line, part: String;
  wDat: TWeatherEx;
begin
  part:='';
  {
  Writeln(exFile,'IniFile:,',
    'Time:,',
    'BBCH:,',
    'ProznFK0_100:,',
    'N-Auswaschung_[kgN/ha]:,',
    'N-Aufnahme_[kgN/ha]:,',
    'Mineralisation_[kgN/ha]:,',
    'WG_0-100[nFK%]:,',
    'GRYD_[dt/ha]:,',
    'LAI_[m2/m2]:,',
    'cumTemp:,',
    'cumRain:,',
    'cumRad:,',
    'Durchwurzelung:,',
    'MinType:,',
    'Sollwert:,',
    'Szenario:,',
    'ProznFK0_30: ,',
    'SumIrr [mm] ,');

    writeln(exFile,
      ExtractFileName(GlobMod.actinifile.filename)+',',
      FloatToStrF(globtime.v-1,ffFixed,15,0)+',',
      FloatToStrF(EC.v,ffFixed,15,2)+',',
      FloatToStrF(ProznFK0_Weff.v,ffFixed,15,0)+',',
      FloatToStrF(sumdrainVB,ffFixed,15,2)+',',
      FloatToStrF(NUpTake.v,ffFixed,15,2)+',',
      FloatToStrF(SumMinVB.v,ffFixed,15,2)+',',
      FloatToStrF(ProznFK0_Weff.v,ffFixed,15,2)+',',
      FloatToStrF(GRYD.v,ffFixed,15,2)+',',
      FloatToStrF(LAI.v,ffFixed,15,2)+',',
      FloatToStrF(cumTemp,ffFixed,15,2)+',',
      FloatToStrF(cumRain,ffFixed,15,2)+',',
      FloatToStrF(cumRad,ffFixed,15,2)+',',
      FloatToStrF(zr.v,ffFixed,15,1)+',',
      FloatToStrF(Mintype.v,ffFixed,15,0)+',',
      FloatToStrF(avNuptake.v,ffFixed,15,0)+',',
      FloatToStrF(Szenario.v,ffFixed,15,0)+',',
      FloatToStrF(ProznFK0_30.v,ffFixed,15,0)+',',
      FloatToStrF(sumirrigation.v,ffFixed,15,0));

  }
  if exAbbFile.Count < 1 then
    begin
    line:=Concat('IniFile:,',
      'Time:,',
      'WG_0-90_[%]:,',
      'PSI_Root_[%PSI_Crit]:,',
      'IrriAmount_[mm]:,',
      'PSI_Crit_min_[%]:,',
      'PSI_Crit_max_[%]:,',
      'Ndrain,',
      'NdrainVB,',
      'NMinVB,',
      'mTMPM_[?C],',
      'mTMPMX_[?C],',
      'mTMPMN_[?C],',
      'mGlobRad_[MJ/m2/d],',
      'mRain_[mm/d],',
      'mLF_[%],',
      'mWind_[W/m2],',
      'cumRad_[MJ/m2],',
      'cumRain_[mm],',
      'Szenario:');
    exAbbFile.Add(line);
    end;

  for wDat:=weTMPM to weWind do
    part:=Concat(part, FloatToStrF(weather[Ord(wDat)][0],ffFixed,15,2), ',');

  line:=Concat(ExtractFileName(GlobMod.actinifile.filename),',',
    FloatToStrF(globtime.v-1,ffFixed,15,0),',',
    FloatToStrF(WG0_90_,ffFixed,15,0),',',
    FloatToStrF(PSI_Root_of_PSI_Crit,ffFixed,15,0),',',
    FloatToStrF(IrriAmount,ffFixed,15,0),',',
    FloatToStrF(PSI_Crit_min,ffFixed,15,0),',',
    FloatToStrF(PSI_Crit_max,ffFixed,15,0),',',
    FloatToStrF(SumDrain.v,ffFixed,15,1),',',
    FloatToStrF(drainstart,ffFixed,15,1),',',
    FloatToStrF(SumMinVB.v,ffFixed,15,1),',',
    part,
    FloatToStrF(cumRad,ffFixed,15,2),',',
    FloatToStrF(cumRain,ffFixed,15,2),',',
    FloatToStrF(Szenario.v,ffFixed,15,0));
  exAbbFile.Add(line);
end;

procedure TSubDataEx.WriteRefLine;
var
  line: String;
begin
  if exDatFile.Count < 1 then
    begin
    line:=Concat('IniFile:,',
      'Time:,',
      'BBCH:,',
      'ProznFK0_100:,',
      'N-Auswaschung_[kgN/ha]:,',
      'N-Aufnahme_[kgN/ha]:,',
      'Mineralisation_[kgN/ha]:,',
      'GRYD_[dt/ha]:,',
      'LAI_[m2/m2]:,',
      'cumTemp:,',
      'cumRain:,',
      'cumRad:,',
      'Durchwurzelung:,',
      'MinType:,',
      'Sollwert:,',
      'Szenario:,');
    exDatFile.Add(line);
    end;

  line:=Concat(ExtractFileName(GlobMod.actinifile.filename)+',',
    FloatToStrF(globtime.v-1,ffFixed,15,0)+',',
    FloatToStrF(EC.v,ffFixed,15,2)+',',
    FloatToStrF(ProznFK0_Weff.v,ffFixed,15,0)+',',
    FloatToStrF(sumdrainVB.v,ffFixed,15,2)+',',
    FloatToStrF(NUpTake.v,ffFixed,15,2)+',',
    FloatToStrF(SumMinVB.v,ffFixed,15,2)+',',
    FloatToStrF(GRYD.v,ffFixed,15,2)+',',
    FloatToStrF(LAI.v,ffFixed,15,2)+',',
    FloatToStrF(cumTemp,ffFixed,15,2)+',',
    FloatToStrF(cumRain,ffFixed,15,2)+',',
    FloatToStrF(cumRad,ffFixed,15,2)+',',
    FloatToStrF(zr.v,ffFixed,15,1)+',',
    FloatToStrF(Mintype.v,ffFixed,15,0)+',',
    FloatToStrF(avNuptake.v,ffFixed,15,0)+',',
    FloatToStrF(Szenario.v,ffFixed,15,0));
  exDatFile.Add(line);
end;


procedure TSubDataEx.WriteRefAbbLine;
var
  line, part: String;
  wDat: TWeatherEx;
begin
  part:='';
  {
  if exAbbFile.Count < 1 then
    begin
    line:=Concat('IniFile:,',
      'Time:,',
      'BBCH:,',
      'ProznFK0_100:,',
      'N-Auswaschung_[kgN/ha]:,',
      'N-Aufnahme_[kgN/ha]:,',
      'Mineralisation_[kgN/ha]:,',
      'WG_0-100[nFK%]:,',
      'GRYD_[dt/ha]:,',
      'LAI_[m2/m2]:,',
      'cumTemp:,',
      'cumRain:,',
      'cumRad:,',
      'Durchwurzelung:,',
      'MinType:,',
      'Sollwert:,',
      'Szenario:,',
      'ProznFK0_30: ,',
      'SumIrr [mm] ,');
    exAbbFile.Add(line);
    end;

  line:=Concat(ExtractFileName(GlobMod.actinifile.filename)+',',
    FloatToStrF(globtime.v-1,ffFixed,15,0)+',',
    FloatToStrF(EC.v,ffFixed,15,2)+',',
    FloatToStrF(ProznFK0_Weff.v,ffFixed,15,0)+',',
    FloatToStrF(sumdrainVB,ffFixed,15,2)+',',
    FloatToStrF(NUpTake.v,ffFixed,15,2)+',',
    FloatToStrF(SumMinVB.v,ffFixed,15,2)+',',
    FloatToStrF(ProznFK0_Weff.v,ffFixed,15,2)+',',
    FloatToStrF(GRYD.v,ffFixed,15,2)+',',
    FloatToStrF(LAI.v,ffFixed,15,2)+',',
    FloatToStrF(cumTemp,ffFixed,15,2)+',',
    FloatToStrF(cumRain,ffFixed,15,2)+',',
    FloatToStrF(cumRad,ffFixed,15,2)+',',
    FloatToStrF(zr.v,ffFixed,15,1)+',',
    FloatToStrF(Mintype.v,ffFixed,15,0)+',',
    FloatToStrF(avNuptake.v,ffFixed,15,0)+',',
    FloatToStrF(Szenario.v,ffFixed,15,0)+',',
    FloatToStrF(ProznFK0_30.v,ffFixed,15,0)+',',
    FloatToStrF(sumirrigation.v,ffFixed,15,0));
  exAbbFile.Add(line);
  }

  if exAbbFile.Count < 1 then
    begin
    line:=Concat('IniFile:,',
      'Time:,',
      'Ndrain,',
      'NdrainVB,',
      'NMinVB,',
      'mTMPM_[?C],',
      'mTMPMX_[?C],',
      'mTMPMN_[?C],',
      'mGlobRad_[MJ/m2/d],',
      'mRain_[mm/d],',
      'mLF_[%],',
      'mWind_[W/m2],',
      'cumRad_[MJ/m2],',
      'cumRain_[mm],',
      'Szenario:');
    exAbbFile.Add(line);
    end;

  for wDat:=weTMPM to weWind do
    part:=Concat(part, FloatToStrF(weather[Ord(wDat)][0],ffFixed,15,2), ',');

  line:=Concat(ExtractFileName(GlobMod.actinifile.filename),',',
    FloatToStrF(globtime.v-1,ffFixed,15,0),',',
    FloatToStrF(SumDrain.v,ffFixed,15,1),',',
    FloatToStrF(drainstart,ffFixed,15,1),',',
    FloatToStrF(SumMinVB.v,ffFixed,15,1),',',
    part,
    FloatToStrF(cumRad,ffFixed,15,2),',',
    FloatToStrF(cumRain,ffFixed,15,2),',',
    FloatToStrF(Szenario.v,ffFixed,15,0));
  exAbbFile.Add(line);
end;

procedure TSubDataEx.integrate;
const
  DOY_LEACH_MIN= 61;
  DOY_LEACH_MAX= 182;
var
  i, ExType:           integer;
  ndx_str,
  headline:            String;
  wDat:                TWeatherEx;
begin

  //SumDrain:=CumDrainage.v/5;
  if ((DayOfYear.v>60) or (EC.v>30)) and (DayOfYear.v<180) then
    begin
    if DrainStart = 0 then
      begin  // Auswaschung erst nach NminVB
      DrainStart:= SumDrain.v;
      MinStart:= MineralisedN.v;
      end;
     sumdrainVB.v:= max(0,SumDrain.v-DrainStart);
    if Ec.v<75 then
      sumMinVB.v:= max(0,MineralisedN.v-MinStart);
    end;

  // calculate relative values for water/irrigation chart
  WG0_90_ := WG0_90.v * 100;
  if (pF_Crit.v > 0) and (DayOfYear.v > DOY_LEACH_MIN) and
     (DayOfYear.v < DOY_LEACH_MAX) then
    begin
    PSI_Root_of_PSI_Crit:=(psiRoot.v / pF_Crit.v) * 100;
    // calculate thresholds for recommendation
    PSI_Crit_min := ((pF_Crit.v*0.95)/pF_Crit.v)*100;
    PSI_Crit_max := ((pF_Crit.v*1.05)/pF_Crit.v)*100;
    end
  else
    begin
    PSI_Root_of_PSI_Crit:=0;
    PSI_Crit_min:=0;
    PSI_Crit_max:=0;
    end;

  // detect irrigation event
  if sumIrrigation.v > sumIrrigation_ then
    begin
    IrriAmount := sumIrrigation.v - sumIrrigation_;
    sumIrrigation_:=sumIrrigation.v;
    end
  else IrriAmount:=0;

  // save day data if export type is selected
  ExType := trunc(ExportType.v);
  case ExType of
    1: // actual weather:
      begin
      if (EC.v >= 10) and (done1 = false) then begin
        WriteActLine;
        done1:=true; end;

      if (EC.v >= 13) and (done2 = false) then begin
        WriteActLine;
        done2:=true; end;

      if (EC.v >= 21) and (done3 = false) then begin
        WriteActLine;
        done3:=true; end;

      if (EC.v>=30) and (done5 = false) then begin
        WriteActLine;
        done5:=true; end;

      if (EC.v>=32) and (done6 = false) then begin
        WriteActLine;
        done6:=true; end;

      if (EC.v>=33) and (done7 = false) then begin
        WriteActLine;
        done7:=true; end;

      if (EC.v>=39) and (done8 = false) then begin
        WriteActLine;
        done8:=true; end;

      if (EC.v>=45) and (done9 = false) then begin
        WriteActLine;
        done9:=true; end;

      if (EC.v>=51) and (done10= false) then begin
        WriteActLine;
        done10:=true; end;

      if (EC.v>=60) and (done11 = false) then begin
        WriteActLine;
        done11:=true; end;

      if (EC.v>=70) and (done12 = false) then begin
        WriteActLine;
        done12:=true; end;

      if (EC.v>=80) and (done13 = false) then begin
        WriteActLine;
        done13:=true; end;

      if (EC.v>=90) and (done14 = false) then begin
        WriteActLine;
        done14:=true; end;

      // for graphs
      {
      if (ExportAbb_Act) and (DayOfYear.v > 90) and (DayOfYear.v < 170) and
         ((GlobTime.v <= Szenario.v) or (Szenario.v = 0)) then
         }
      if (ExportAbb_Act) and
         ((GlobTime.v <= Szenario.v) or (Szenario.v = 0)) and
         ((DateWeatherEx+10 <= GlobTime.v) or  // for weather data
         ((DayOfYear.v > DOY_LEACH_MIN) and    // for N -leach
          (DayOfYear.v < DOY_LEACH_MAX))) then
//         (GlobTime.v > Now-14) and
        begin
        // kill weather beside 10 day rythm
        if (DateWeatherEx+10 > GlobTime.v) then
          for wDat:=weTMPM to weWind do
            weather[Ord(wDat)][0]:=0
        else
          DateWeatherEx:=GlobTime.v;

        WriteActAbbLine;
        end;
      end;

  2: // scenario
    begin
    if done = false then
      begin
      headline := Concat('IniFile:,',
        'Time:,',
        'BBCH:,',
        'ProznFK0_100:,',
        'GRYD_[dt/ha]:,',
        'Szenario:,',
        'N-Aufnahme_[kgN/ha]:,',
        'Mineralisation_[kgN/ha]:,',
        'Date2C:,',
        'Date3C:');
      exDatFile.Add(headline);
      done:=true;
      end;

    if (EC.v > 31) and (dateC2 = 0) then dateC2:=GlobTime.v;
    if (EC.v > 51) and (dateC3 = 0) then dateC3:=GlobTime.v;
    if (EC.v >= 90) and  (done2 = false) then
      begin
      headline := Concat(ExtractFileName(GlobMod.ActIniFile.FileName)+',',
        FloatToStrF(GlobTime.v-1,ffFixed,15,0)+',',
        FloatToStrF(EC.v,ffFixed,15,2)+',',
        FloatToStrF(ProznFK0_Weff.v,ffFixed,15,0)+',',
        FloatToStrF(GRYD.v,ffFixed,15,2)+',',
        FloatToStrF(Szenario.v,ffFixed,15,0)+',',
        FloatToStrF(NUpTake.v,ffFixed,15,2)+',',
        FloatToStrF(SumMinVB.v,ffFixed,15,2)+',',
        FloatToStrF(dateC2-13,ffFixed,15,0)+',',
        FloatToStrF(dateC3-13,ffFixed,15,0));
      exDatFile.Add(headline);
      done2:=true;
      end;
    end;

  3: // reference
    begin
    if (GlobMod.Starttime = GlobTime.v - 1) then
      begin
      Done1:= false;
      Done2:=false; // Done3:=false; Carbosum:=0; DSEE:=0;
      end;

    if (EC.v >= 10) and (done1 = false) then begin
      WriteRefLine;
      done1:=true; end;

    if (EC.v >= 13) and (done2 = false) then begin
      WriteRefLine;
      done2:=true; end;

    if (EC.v >= 21) and (done3 = false) then begin
      WriteRefLine;
      done3:=true; end;

    if (EC.v >= 30) and (done5 = false) then begin
      WriteRefLine;
      done5:=true; end;

    if (EC.v >= 32) and (done6 = false) then begin
      WriteRefLine;
      done6:=true; end;

    if (EC.v>=33) and (done7 = false) then begin
      WriteRefLine;
      done7:=true; end;

    if (EC.v >= 39) and (done8 = false) then begin
      WriteRefLine;
      done8:=true; end;

    if (EC.v >= 45) and (done9 = false) then begin
      WriteRefLine;
      done9:=true; end;

    if (EC.v >= 51) and (done10 = false) then begin
      WriteRefLine;
      done10:=true; end;

    if (EC.v >= 60) and (done11 = false) then begin
      WriteRefLine;
      done11:=true; end;

    if (EC.v >= 70) and (done12 = false) then begin
      WriteRefLine;
      done12:=true; end;

    if (EC.v >= 80) and (done13 = false) then begin
      WriteRefLine;
      done13:=true; end;

    if (EC.v >= 90) and  (done14 = false) then begin
      WriteRefLine;
      done14:=true; end;

    // for graphs
    if (ExportAbb_Ref) and
       (DateWeatherEx+10 <= GlobTime.v) then  // for weather data
       //(DayOfYear.v > 90) and (DayOfYear.v < 170) then
      begin
      if DateWeatherEx+10 > GlobTime.v then
        for wDat:=weTMPM to weWind do
          weather[Ord(wDat)][0]:=0 // kill weather beside 10 day rythm
      else
        DateWeatherEx:=GlobTime.v;

      WriteRefAbbLine;
      end;
    end;

  4: // Startwerte Wasser
    begin
    // Endwerte in StateINI schreiben...
    if GlobTime.v = GlobMod.Endtime then
      begin
      if GlobMod.IniFileNames.IndexOf(GlobMod.ActIniFile.FileName) = GlobMod.IniFileNames.Count then
        exit;
      for i := 1 to 21 do
        begin  //21 Schichten
        if i <= 9 then
          ndx_str := '_'+IntTostr(i)
        else
          ndx_str := IntTostr(i);
        GlobMod.StateIniFile.WriteString(swmod.SubModName,'WG'+ndx_str,FloatToStrF(theta_arr[i].v,ffFixed,9,6));
        end;
      SWMOD.Opt_IniMethod:= WaterContents;
      end;
    //globmod.init(GlobMod.actinifile);
    end;

  5: // temp
    begin
    //if (GlobMod.Starttime = globtime.v-1) then begin
    //  Done1:= false; Done2:=false; {Done3:=false;}// Carbosum:=0; DSEE:=0;
    //end;

    if (done = false)  then
      begin
      headline := Concat('IniFile:,',
        'Time:,',
        'BBCH:,',
        'N-Aufnahme_[kgN/ha]:,',
        'GRYD_[dt/ha]:,',
        'LAI_[m2/m2]:,',
        'cumRAD:,',
        'cumCWSI:,');
      exDatFile.Add(headline);
      done:= true;
      end;

    if (EC.v > 90) and (done1 = false) then
      begin
      headline := Concat(ExtractFileName(GlobMod.actinifile.filename)+',',
        FloatToStrF(globtime.v-1,ffFixed,15,0)+',',
        FloatToStrF(EC.v,ffFixed,15,2)+',',
        FloatToStrF(NUpTake.v,ffFixed,15,2)+',',
        FloatToStrF(GRYD.v,ffFixed,15,2)+',',
        FloatToStrF(LAI.v,ffFixed,15,2)+',',
        FloatToStrF(cumRAD,ffFixed,15,2)+',',
        FloatToStrF(cumCWSI,ffFixed,15,2));
      exDatFile.Add(headline);
      done1:=true;
      end;
    end;
  end; // case of ExportType

  // save model export to harddisk
  if GlobMod.FIniFiles.Objects[GlobMod.FIniFiles.Count-1] = GlobMod.ActIniFile then
    begin // last inifile
    if GlobTime.v >= GlobMod.Endtime then
      begin // at end
      if fn_DatFile <> '' then
        exDatFile.SaveToFile(fn_DatFile);
      if fn_AbbFile <> '' then
        exAbbFile.SaveToFile(fn_AbbFile);
      exDatFile.Clear;
      exAbbFile.Clear;
      end;
    end;
end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubDataEx]);
end;

end.
