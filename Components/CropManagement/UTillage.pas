unit UTillage;
{SubModel TTillage describes the effect of Tillage on mineralisation. Tillage
 operations are defined in the state.ini file by date and depth in cm of the
 tillage operation: 20.10.2006=30
 The tillage operation triggers the MixLayers method of the mineralisation model
 and increases the BBf factor of all concerned layers in the mineralisation model
 by the value of parameter TillageMinEffect}

interface

uses
  UMod, UState, IniFiles, Classes, UAbstractSoilMin;

const
  MaxTillDates = 100;
  MaxTillLayers = 3;

type

TTillage = class(TsubModel)
  fMineralisationModel :  TAbstractSoilMin;


private

protected

public
  TillageMinEffect : TPar;
  TillageOps : array[0..MaxTillDates-1] of TState;
  TillDates  : TStringList;
  BBf : array[1..MaxTillLayers] of TExternV;


{$IFNDEF NONVISUAL}
    constructor Create(AOwner: TComponent); override; /// constructor if visual
{$ELSE}
    constructor create; /// constructor if nonvisual
{$ENDIF}


  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure CreateAll; override;

published
  property SoilMinModel : TAbstractSoilMin read fMineralisationModel write fMineralisationModel;
end;

procedure Register;


implementation
uses
  SysUtils,
{$IFNDEF NONVISUAL}
  vcl.Dialogs,
{$ENDIF}
  ULayeredSoil;

{$IFNDEF NONVISUAL}
    constructor TTillage.Create(AOwner: TComponent); /// constructor if visual
{$ELSE}
    constructor TTillage.create; /// constructor if nonvisual
{$ENDIF}

begin
  inherited;
  TillDates := TStringlist.create;
end;


procedure TTillage.CreateAll;
var
  i        : integer;
begin
  inherited createAll;
  ParCreate('TillageMinEffect', '[]', 0.5, TillageMinEffect, 'Tillage effect on mineralisation. This value is added to the BBf-factor.');
  for i := 1 to MaxTillLayers do
    ExternVcreate('BBf'+ndx_str(i), '[-]', STateField, BBf[i]);
end;


procedure TTillage.Init(var GlobMod: TMod);

var
  i : integer;
  name   : string;
  Tiefe  : real;

begin
  // StateIniF       := Globmod.StateIniFile;
  // inherited init(GlobMod);
  TillDates.clear;
  for i := 0 to StateStrList.Count - 1 do
    TState(StateStrList.Objects[i]).Free;
  StateStrList.clear;
  for i := 0 to MaxTillDates - 1 do
    TillageOps[i] := nil;

  inherited;
  if stateIniF <> nil then
  begin

    stateIniF.ReadSection(SubModName, TillDates);
    For i := 0 to TillDates.Count - 1 do
    begin
      name := TillDates[i];
      Tiefe := stateIniF.ReadFloat(SubModName, TillDates[i], 0.0);
      stateCreate(name, '[cm]', Tiefe, true, TillageOps[i]);
    end;
  end;
end;

procedure TTillage.calcrates;

var
  index  : integer;
  schicht : integer;
  TillState : Tstate;
  DateString : String;
  ActDate : TDateTime;
begin
  ActDate := GlobTime.v;
  DateSTring := DateToStr(ActDate);
  index := TillDates.IndexOf(DateSTring);
  If Index <> -1 then begin
    TillState := TillageOps[index];
    For schicht := 1 to trunc(TillState.v/10) do
      BBf[schicht].f_v^ := BBf[schicht].v+TillageMinEffect.v;
    if fMineralisationmodel <> nil then
      fMineralisationModel.MixLayers(TillState.v);
    TillState.v := 0.0;
    TillageOps[index].v := 0.0;
    TillageOps[index].name := '';
  end;
end;

procedure Register;

begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TTillage]);
  {$ENDIF}
end;


end.
