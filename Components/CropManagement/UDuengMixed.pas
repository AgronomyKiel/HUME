unit UDuengMixed;

interface

uses
  UMod, UState, IniFiles, Classes, UDueng;

type
  /// <summary>Supported nutrient forms for fertilizer application events.</summary>
  TFertilizerKind = (fkUnsupported, fkNitrate, fkAmmonium, fkUrea);

  /// <summary>Handling options for urea applications.</summary>
  TUreaHandling = (uhToAmmonium, uhSeparatePool);

  /// <summary>Stores one fertilizer application event for a simulation date.</summary>
  TMixedFertilizerEvent = class(TObject)
  public
    /// <summary>Date string in format dd.mm.yyyy.</summary>
    DateString: string;
    /// <summary>Nitrate amount applied on the date [kg N/ha].</summary>
    Nitrate: real;
    /// <summary>Ammonium amount applied on the date [kg N/ha].</summary>
    Ammonium: real;
    /// <summary>Urea amount applied on the date [kg N/ha].</summary>
    Urea: real;
  end;

  /// <summary>
  /// Combined fertilizer component based on TDueng.
  /// Supports nitrate, ammonium, and optionally urea applications within one submodel.
  /// </summary>
  /// <remarks>
  /// Plain date entries without suffix remain compatible with TDueng and are interpreted as nitrate.
  /// Additional entries can be defined in the same section using suffixes `_NO3`, `_NH4`, and `_Urea`.
  /// By default, urea is added to the ammonium target because the current soil components do not expose
  /// a dedicated urea pool by default.
  /// </remarks>
  TDuengMixed = class(TDueng)
  private
    FApplications: TList;
    FSoilAmmonium: TExternV;
    FSoilUrea: TExternV;
    FUreaHandling: TUreaHandling;

    procedure ApplyAmount(Target: TExternV; Amount: real);
    procedure ClearApplications;
    function FindApplication(const ADateString: string): TMixedFertilizerEvent;
    function GetTodayString: string;
    function ParseFertilizerKey(const Key: string; out ADateString: string;
      out AFertilizerKind: TFertilizerKind): boolean;
    procedure UpdateUreaHandling;

  public
    /// <summary>Nitrate fertilizer applied on the current simulation day [kg N/ha].</summary>
    CumDuengNO3: TState;
    /// <summary>Ammonium fertilizer applied on the current simulation day [kg N/ha].</summary>
    CumDuengNH4: TState;
    /// <summary>Urea fertilizer applied on the current simulation day [kg N/ha].</summary>
    CumDuengUrea: TState;
    /// <summary>Option defining whether urea is routed to ammonium or to a separate urea pool.</summary>
    UreaHandlingOption: TOption;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure CalcRates; override;
    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;

  published
    /// <summary>External target for ammonium in the top soil layer, typically `NH4_Arr_1`.</summary>
    property Ex_SoilAmmonium: TExternV read FSoilAmmonium write FSoilAmmonium;
    /// <summary>Optional external target for a dedicated urea pool in the top soil layer.</summary>
    property Ex_SoilUrea: TExternV read FSoilUrea write FSoilUrea;
  end;

procedure Register;

implementation

uses
  SysUtils
{$IFNDEF NONVISUAL}
    , vcl.Dialogs
{$ENDIF}
    ;

function IsDateString(const DateString: string): boolean;
var
  DateValue: TDateTime;
  LocalFormatSettings: TFormatSettings;
begin
  LocalFormatSettings := FormatSettings;
  LocalFormatSettings.ShortDateFormat := 'dd.mm.yyyy';
  LocalFormatSettings.DateSeparator := '.';
  result := TryStrToDate(DateString, DateValue, LocalFormatSettings);
end;

constructor TDuengMixed.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FApplications := TList.Create;
end;

destructor TDuengMixed.Destroy;
begin
  ClearApplications;
  FApplications.Free;
  inherited Destroy;
end;

procedure TDuengMixed.ApplyAmount(Target: TExternV; Amount: real);
begin
  if (Target <> nil) and (Target.f_v <> nil) and (Amount <> 0.0) then
    Target.v := Target.v + Amount;
end;

procedure TDuengMixed.ClearApplications;
var
  i: integer;
begin
  if FApplications <> nil then
  begin
    for i := 0 to FApplications.Count - 1 do
      TObject(FApplications[i]).Free;
    FApplications.Clear;
  end;
end;

function TDuengMixed.FindApplication(const ADateString: string): TMixedFertilizerEvent;
var
  i: integer;
  Application: TMixedFertilizerEvent;
begin
  result := nil;
  for i := 0 to FApplications.Count - 1 do
  begin
    Application := TMixedFertilizerEvent(FApplications[i]);
    if SameText(Application.DateString, ADateString) then
    begin
      result := Application;
      exit;
    end;
  end;

  Application := TMixedFertilizerEvent.Create;
  Application.DateString := ADateString;
  Application.Nitrate := 0.0;
  Application.Ammonium := 0.0;
  Application.Urea := 0.0;
  FApplications.Add(Application);
  result := Application;
end;

function TDuengMixed.GetTodayString: string;
var
  ActDay: word;
  ActMonth: word;
  ActYear: word;
begin
  DecodeDate(GlobTime.v, ActYear, ActMonth, ActDay);
  result := Format('%.2d.%.2d.%.4d', [ActDay, ActMonth, ActYear]);
end;

function TDuengMixed.ParseFertilizerKey(const Key: string;
  out ADateString: string; out AFertilizerKind: TFertilizerKind): boolean;
var
  SepPos: integer;
  Suffix: string;
begin
  result := false;
  ADateString := '';
  AFertilizerKind := fkUnsupported;

  SepPos := LastDelimiter('_', Key);
  if SepPos <= 0 then
    exit;

  ADateString := Copy(Key, 1, SepPos - 1);
  if not IsDateString(ADateString) then
    exit;

  Suffix := UpperCase(Trim(Copy(Key, SepPos + 1, MaxInt)));
  if (Suffix = 'NO3') or (Suffix = 'NITRATE') then
    AFertilizerKind := fkNitrate
  else if (Suffix = 'NH4') or (Suffix = 'AMMONIUM') then
    AFertilizerKind := fkAmmonium
  else if (Suffix = 'UREA') or (Suffix = 'HARNSTOFF') then
    AFertilizerKind := fkUrea
  else
    exit;

  result := true;
end;

procedure TDuengMixed.UpdateUreaHandling;
begin
  if SameText(UreaHandlingOption.Option, 'SeparatePool') then
    FUreaHandling := uhSeparatePool
  else
    FUreaHandling := uhToAmmonium;
end;

procedure TDuengMixed.CreateAll;
begin
  inherited CreateAll;

  ExternVCreate('NH4_Arr_1', '[kg N/ha]', StateField, FSoilAmmonium,
    'external target for ammonium fertilizer in the top soil layer');
  ExternVCreate('Urea_1', '[kg N/ha]', StateField, FSoilUrea,
    'optional external target for a dedicated urea pool in the top soil layer');

  StateCreate('CumDuengNO3', '[kg N/ha]', 0.0, false, CumDuengNO3,
    'nitrate fertilizer applied on the current simulation day');
  StateCreate('CumDuengNH4', '[kg N/ha]', 0.0, false, CumDuengNH4,
    'ammonium fertilizer applied on the current simulation day');
  StateCreate('CumDuengUrea', '[kg N/ha]', 0.0, false, CumDuengUrea,
    'urea fertilizer applied on the current simulation day');

  OptCreate('UreaHandling', 'ToAmmonium', UreaHandlingOption,
    'handling of urea applications: add to ammonium or to a separate urea pool');
  UreaHandlingOption.OptionList.Clear;
  UreaHandlingOption.OptionList.Add('ToAmmonium');
  UreaHandlingOption.OptionList.Add('SeparatePool');
end;

procedure TDuengMixed.Init(var GlobMod: TMod);
var
  i: integer;
  Name: string;
  DateString: string;
  Menge: real;
  Entries: TStringList;
  FertilizerKind: TFertilizerKind;
  Application: TMixedFertilizerEvent;
begin
  inherited Init(GlobMod);
  ClearApplications;
  UpdateUreaHandling;

  Entries := TStringList.Create;
  try
    if stateIniF <> nil then
    begin
      stateIniF.ReadSection(SubModName, Entries);
      for i := 0 to Entries.Count - 1 do
      begin
        Name := Entries[i];
        if ParseFertilizerKey(Name, DateString, FertilizerKind) then
        begin
          Menge := stateIniF.ReadFloat(SubModName, Name, 0.0);
          if f_ExtFertSens.Source <> '' then
            Menge := Menge * f_ExtFertSens.v;

          Application := FindApplication(DateString);
          case FertilizerKind of
            fkNitrate:
              Application.Nitrate := Application.Nitrate + Menge;
            fkAmmonium:
              Application.Ammonium := Application.Ammonium + Menge;
            fkUrea:
              Application.Urea := Application.Urea + Menge;
          end;
        end;
      end;
    end;
  finally
    Entries.Free;
  end;
end;

procedure TDuengMixed.CalcRates;
var
  Application: TMixedFertilizerEvent;
  TodayString: string;
  i: integer;
  AppliedNO3: real;
  AppliedNH4: real;
  AppliedUrea: real;
begin
  CumDuengNO3.c := 0.0;
  CumDuengNH4.c := 0.0;
  CumDuengUrea.c := 0.0;

  inherited CalcRates;
  AppliedNO3 := CumDueng.c;
  AppliedNH4 := 0.0;
  AppliedUrea := 0.0;

  TodayString := GetTodayString;
  for i := 0 to FApplications.Count - 1 do
  begin
    Application := TMixedFertilizerEvent(FApplications[i]);
    if SameText(Application.DateString, TodayString) then
    begin
      if Application.Nitrate <> 0.0 then
      begin
        ApplyAmount(SoilNitrate, Application.Nitrate * f_rec.v);
        AppliedNO3 := AppliedNO3 + Application.Nitrate * f_rec.v;
      end;

      if Application.Ammonium <> 0.0 then
      begin
        ApplyAmount(FSoilAmmonium, Application.Ammonium * f_rec.v);
        AppliedNH4 := AppliedNH4 + Application.Ammonium * f_rec.v;
      end;

      if Application.Urea <> 0.0 then
      begin
        if FUreaHandling = uhSeparatePool then
          ApplyAmount(FSoilUrea, Application.Urea * f_rec.v)
        else
          ApplyAmount(FSoilAmmonium, Application.Urea * f_rec.v);
        AppliedUrea := AppliedUrea + Application.Urea * f_rec.v;
      end;

      Application.Nitrate := 0.0;
      Application.Ammonium := 0.0;
      Application.Urea := 0.0;
      break;
    end;
  end;

  CumDuengNO3.c := AppliedNO3;
  CumDuengNH4.c := AppliedNH4;
  CumDuengUrea.c := AppliedUrea;
  CumDueng.c := AppliedNO3 + AppliedNH4 + AppliedUrea;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TDuengMixed]);
{$ENDIF}
end;

end.

