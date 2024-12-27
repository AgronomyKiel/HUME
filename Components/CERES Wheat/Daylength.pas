unit Daylength;
{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

interface

uses
  SysUtils, Classes,
  Umod, UState,
  Math, DateUtils;

const
     RADi = PI / 180;
type
/// <summary> TDaylength: class for calculating day length and photoperiodic day length </summary>
  TDaylength = class(TSubmodel)
  private
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    DayLength, DayLengthp: TVar;
    DayofYear: TState;
    Latitude: TPar;

    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcVars; override;
    procedure CalcRates; override;
//    procedure Integrate; override;

  published
    { Published-Deklarationen }
    Property Var_Daylength : TVar read daylength write daylength;
    property Var_daylengthp: TVar read daylengthp write daylengthp;
    property St_DayofYear: TState read DayofYear write DayofYear;
    property Par_Latitude: TPar read latitude write latitude;
  end;

procedure Register;

implementation

procedure TDayLength.Createall;

begin
  inherited CreateAll;
  Varcreate('Daylength', '[h]', 0, true, daylength);
  Varcreate('Daylengthp', '[h]', 0, true, daylengthp);
  Parcreate('Latitude', '[�]', 51, Latitude);
  StateCreate('DayofYear', '[n]', 1, true, DayofYear);
end;


procedure TDayLength.CalcVars;

var
    DEC, AOB, SINLD, COSLD: real;

begin
  DayofYear.v := DayofTheYear(GlobTime.v);
  DEC:= -ARCSIN(SIN(23.45 * RADi) * COS(2* PI * (DayOfYear.v + 10) / 365));
  SINLD:= Sin(RADi * Latitude.v) * Sin(Dec);
  COSLD:= COS(RADi * Latitude.v) * COS(DEC);
  AOB:= SINLD / COSLD;
  DayLength.v := 12.0 * ( 1 + 2 * ARCSIN(AOB) / PI);
  DayLengthP.v := 12.0 * ( 1 + 2 * ARCSIN((-SIN(-4 * RADi) + SINLD) / COSLD) / PI);
end;

procedure TDayLength.CalcRates;
begin
end;


procedure TDayLength.Init(var GlobMod: TMod);

begin
  inherited;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('CERES Wheat', [TDaylength]);

{$ENDIF}

end;

end.
