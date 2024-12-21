unit UDueng_ISIP;

interface

uses
  UMod,
  UState,
  IniFiles,
  Classes,
//  UDueng,
{$IFNDEF NONVISUAL}
  Windows,
  Messages,
{$ENDIF}

  Math,
   UAbstractPlant;

const
  MaxDuengDates = 100;

type

  TDueng_ISIP = class(TsubModel)
  private

  protected
    factNapp1, factNapp2, factNapp3 : real;

  public
    NApp1, NApp2, NApp3, NApp4, NApp5: TVar;
    ModNup1, ModNup2, ModMin1, ModMin2, ModLeach1, ModLeach2: TVar;  // An Output
    Q1Nup, Q1Leach, Q1Min, Q2GRYD, Q2Leach, Q2Min: TPar;  // von MUI gesetzt

    avGRYD: TPAR;

    STDNApp1:  TPar;
    STDNApp2:  TPar;
    STDNApp3:  TPar;

    fNEff:     TPar;
    fSenspar : TPar; /// Parameter for changing N supply in a sensitivity analysis

    App:       array [1..5] of boolean;
    EC:        TExternV;
    Doy:       TExternV;
    NUpTake:   TExternV;
  //  Vorfrucht: TExternV;
   // MinType:   TExternV;
    Nmin0_90:  TExternV;  //08.06.11 ar
   // Netmin_1:       TExternV;
    SoilNitrate : TExternV;
    appliedN:  TVar;
    NminVB:    TVar; // Nmin0_90 zu Vegetationsbegin  //08.06.11 ar
    Sollwert:  TVar;

    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure integrate; override;
    procedure CreateAll; override;
  published

    property Ex_SoilNitrate: TExternV Read SoilNitrate Write SoilNitrate;

  end;

procedure Register;


implementation

uses
  SysUtils;

procedure TDueng_ISIP.Init(var GlobMod: TMod);

var
  i: integer;
  fStdTotalN, factTotalN, DiffN : real;
begin
  inherited init(GlobMod);
    for i := 1 to 5 do
  begin
    App[i] := False;
  end;

  factNapp1 := STDNapp1.v*fSensPar.v;
  factNapp2 := STDNapp2.v*fSensPar.v;
  factNapp3 := STDNapp3.v*fSensPar.v;
  fSTDTotalN := STDNapp1.v+STDNapp2.v+STDNapp3.v;
  factTotalN := fSTDTotalN*fSensPar.v;



  DiffN := fSTDTotalN-factTotalN;
  if DiffN>0 then begin
    if DiffN <= STDNapp3.v then begin
      factNapp3 := STDNapp3.v-DiffN;
      exit;
    end
    else begin
      factNapp3 := 0.0;
      DiffN := DiffN-STDNapp3.v;
      factNapp1 := STDNapp1.v - STDNapp1.v/(STDNapp1.v+STDNapp2.v)*DiffN;
      factNapp2 := STDNapp2.v - STDNapp2.v/(STDNapp1.v+STDNapp2.v)*DiffN;
    end
  end else begin
      factNapp1 := STDNapp1.v*fSensPar.v;
      factNapp2 := STDNapp2.v*fSensPar.v;
      factNapp3 := STDNapp3.v*fSensPar.v;
    end;

end;

procedure TDueng_ISIP.CreateAll;

begin
  inherited;

  ParCreate('fNEff', '[-]', 0.7, fNEff, 'fraction of not immobilised nitrogen');
  ParCreate('STDNApp1', '[kg/ha]', 60, STDNApp1);
  ParCreate('STDNApp2', '[kg/ha]', 70, STDNApp2);
  ParCreate('STDNApp3', '[kg/ha]', 70, STDNApp3);
  ParCreate('fSensPar', '[-]', 1, fSensPar, '');


  VarCreate('Sollwert', '[KgN/ha]', 230, True, Sollwert);
  VarCreate('NApp1', '[KgN/ha]', 0, True, NApp1, 'N application');
  VarCreate('NApp2', '[KgN/ha]', 0, True, NApp2, 'N application');
  VarCreate('NApp3', '[KgN/ha]', 0, True, NApp3, 'N application');
  VarCreate('NApp4', '[KgN/ha]', 0, True, NApp4, 'N application');
  VarCreate('NApp5', '[KgN/ha]', 0, True, NApp5, 'N application');

  VarCreate('NminVB', '[KgN/ha]', 30, True, NminVB);   //08.06.11 ar

  VarCreate('appliedN', '[KgN/ha]', 0, True, appliedN);
  ExternVCreate('EC', '[]', statefield, EC);
 // ExternVCreate('Vorfrucht', '[-]', statefield, Vorfrucht);
  ExternVCreate('dayofyear', '', statefield, doy);
  ExternVCreate('Nmin0_90', '[kgN/ha]', statefield, Nmin0_90); //08.06.11 ar
  ExternVCreate('NUpTake', '[kgN/ha]', statefield, NUpTake);
 // ExternVCreate('MinType', '[-]', statefield, MinType);
  ExternVcreate('Nmin__1', '[kgN/ha]', STateField, SoilNitrate);
 //ExternVCreate('Netmin__1', '', statefield, Netmin_1);
end;

procedure TDueng_ISIP.integrate;
var
  Year, Month, Day: word;
  MinDemand, calcMin: real;
begin
  inherited;
  DecodeDate(GlobTime.v, Year, Month, Day);

    if (Month=3) and (Day=1) then NminVB.v:=Nmin0_90.v;   //08.06.11 ar

  if ((EC.v >= 23) and (App[1] = False) and (STDNApp1.v > 0) and (Month >= 3) and
    (Month < 4)) or ((Month >= 4) and (App[1] = False) and (Month < 5)) then
  begin
    SoilNitrate.f_v^ := SoilNitrate.v + factNapp1*fNEff.v;
    NApp1.v := factNapp1;

    appliedN.v := appliedN.v + NApp1.v;
    App[1] := True;
  end;


  if (EC.v >= 31) and (App[2] = False) and (factNapp2 > 0)  then
  begin
    NApp2.v := max(30,factNapp2 - NminVB.v);
    SoilNitrate.f_v^ := SoilNitrate.v + NApp2.v*fNEff.v;
      //min(20, max(-10, (ModNup1.v - ModMin1.v + ModLeach1.v)));

    appliedN.v := appliedN.v + NApp2.v;
    App[2] := True;
  end;
  if (EC.v >= 39) and (App[3] = False) and (factNapp3 > 0) then
  begin
    NApp3.v := max(0,(factNapp2+factNapp3)- NminVB.v -NApp2.v);
    appliedN.v := appliedN.v + NApp3.v;
    SoilNitrate.f_v^ := SoilNitrate.v + NApp3.v*fNEff.v; //08.06.11 ar
    App[3] := True;
  end;

end;



procedure TDueng_ISIP.calcrates;
begin

end;

procedure Register;

begin
{$IFNDEF NONVISUAL}
  Classes.RegisterComponents('Simulation', [TDueng_ISIP]);
{$ENDIF}

end;


end.