unit UMinMod2Pool;

interface

uses
{$IFNDEF NONVISUAL}
  Windows, Messages, SysUtils, Classes,// Graphics, Controls, Forms, Dialogs,
{$ENDIF}

  UMod, UState, UAbstractPlant;

type

  TMinMod2Pool = class(TPlantRelatedSubMod)

  private

  protected

  public
    MinRate, Nfast_Min_N, Nslow_Min_N: TVar;

    k_water_reduction_factor,
      kfast_temp_coeff, kslow_temp_coeff: TVar;

    kfast_factor, kslow_factor: TPar;

    Nfast: TState; // fast decomposable pool of soil N [kg N/ha]
    Nslow: TState; // slow decomposable pool of soil N [kg N/ha]

    Nfast_par, Nslow_par: TPar;
    MineralisedN: TState;
    Temp: TExternV;
    WG0_30: TExternV;
    Nmin_1: TExternV;
    Nmin_2: TExternV;
    Nmin_3: TExternV;
    theta_300: TPar;
    theta_PWP, theta_FK, theta_SAT: TExternV;

    calcRatesIsActive, isfirstminmod: Boolean;

    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure setCalcRatesActive(active: Boolean);

  published
    property Var_MinRate: TVar read MinRate write MinRate;
    property Var_Nfast_Min_N: TVar read Nfast_Min_N write Nfast_Min_N;
    property Var_Nslow_Min_N: TVar read Nslow_Min_N write Nslow_Min_N;
    property St_Nfast: TState read Nfast write Nfast;
    property St_Nslow: TState read Nslow write Nslow;
    property Ex_WG0_30: TExternV read WG0_30 write WG0_30;
    property Ex_Temp: TExternV read Temp write Temp;
    property Par_kfast_factor: TPar read kfast_factor write kfast_factor;
    property Par_kslow_factor: TPar read kslow_factor write kslow_factor;
    property FirstMinMod: Boolean read isfirstminmod write isfirstminmod;
  end;

procedure Register;

implementation

uses Math;


procedure TMinMod2Pool.setCalcRatesActive(active: Boolean);
begin
  calcRatesIsActive := active;
end;

{ -------------------------------------------------------------------------------
  Procedure: TMinMod2Pool.createAll
  Author:    ckluss
  DateTime:  2010.07.29
  Arguments: None
  Result:    None
  ------------------------------------------------------------------------------- }

procedure TMinMod2Pool.CreateAll;

begin
  inherited CreateAll;

  VarCreate('MinRate', '', 0, true, MinRate, '');
  VarCreate('Nfast_Min_N', '', 0, true, Nfast_Min_N,
    'bereits mineralisierter Teil von Nfast');
  VarCreate('Nslow_Min_N', '', 0, true, Nslow_Min_N,
    'bereits mineralisierter Teil von Nslow');

  ParCreate('kfast_factor', '[]', 5.6, kfast_factor, '');
  ParCreate('kslow_factor', '[]', 4, kslow_factor, '');

  VarCreate('kfast_temp_coeff', '[]', 0, true, kfast_temp_coeff, '');
  VarCreate('kslow_temp_coeff', '[]', 0, true, kslow_temp_coeff, '');

  VarCreate('k_water_reduction_factor', '', 0, true, k_water_reduction_factor,
    '');

  ParCreate('Nfast', '[]', 50, Nfast_par,
    'Fast decomposable Pool of Soil N [kg N/ha]');
  ParCreate('NSlow', '[]', 700, Nslow_par,
    'slow decomposable Pool of Soil N [kg N/ha]');

  ExternVCreate('b_Rest1', '', statefield, theta_PWP);
  ParCreate('b_300', '[]', 0.27, theta_300);
  ExternVCreate('FK_1', '', statefield, theta_FK);
  ExternVCreate('b_Sat1', '', statefield, theta_SAT);

  StateCreate('Nfast', '[kg N/ha]', 0, true, Nfast,
    'Fast decomposable Pool of Soil N [kg N/ha]');
  StateCreate('Nslow', '[kg N/ha]', 0, true, Nslow,
    'slow decomposable Pool of Soil N [kg N/ha]');

  StateCreate('MineralisedN', '[kg N/ha]', 0, true, MineralisedN);

  ExternVCreate('Nmin_1', '', statefield, Nmin_1);
  ExternVCreate('Nmin_2', '', statefield, Nmin_2);
  ExternVCreate('Nmin_3', '', statefield, Nmin_3);
  ExternVCreate('Temp', '', statefield, Temp);
  ExternVCreate('WG0_30', '', statefield, WG0_30);



end;

procedure TMinMod2Pool.Init(var GlobMod: TMod);
begin
  inherited Init(GlobMod);
  Nfast.v := Nfast_par.v;
  Nslow.v := Nslow_par.v;

   Nslow.c := 0;
   Nfast.c := 0;

   Nfast_Min_N.v := 0;
   Nslow_Min_N.v := 0;

   MinRate.v := 0;
   MineralisedN.c := 0;

    if isfirstminmod then
    calcRatesIsActive := True
  else
    calcRatesIsActive := False;
end;

{ -------------------------------------------------------------------------------
  Procedure: TMinMod2Pool.CalcRates
  Author:    ckluss
  DateTime:  2010.07.29
  Arguments: None
  Result:    None
  ------------------------------------------------------------------------------- }
// @article{kersebaum2001performance,
// title={{Performance of a nitrogen dynamics model applied to evaluate
// agricultural management practices}},
// author={Kersebaum, KC and Beblik, AJ},
// journal={Modeling carbon and nitrogen dynamics for soil management},
// pages={549--569},
// year={2001}}

procedure TMinMod2Pool.CalcRates;
begin

  if not calcRatesIsActive then  begin
     Nslow.c := 0;
     Nfast.c := 0;
     Nfast_Min_N.v := 0;
     Nslow_Min_N.v := 0;
     MinRate.v := 0;
     MineralisedN.c := 0;
  end else begin
  // calculation Mineralisation coeffizientes depending on TEMPERATURE AND WATER

    if (Temp.v > 0) then begin
    // Mineralisation (kg N/ha) from fast fraction
      kfast_temp_coeff.v := kfast_factor.v * 1E12 * Exp(-9800 / (Temp.v + 273));
    // Mineralisation (kg N/ha) from slow fraction
      kslow_temp_coeff.v := kslow_factor.v * 1E9 * Exp(-8400 / (Temp.v + 273));
    end else begin
      kfast_temp_coeff.v := 0;
      kslow_temp_coeff.v := 0
    end;

  // Reduction factor suboptimal water content
    if (WG0_30.v <= theta_PWP.v) or (theta_SAT.v <= WG0_30.v) then
      k_water_reduction_factor.v := 0
    else if (theta_PWP.v < WG0_30.v) and (WG0_30.v < theta_300.v) then
      k_water_reduction_factor.v := (WG0_30.v - theta_PWP.v) /
        (theta_300.v - theta_PWP.v)
    else if (theta_300.v <= WG0_30.v) and (WG0_30.v <= theta_FK.v) then
      k_water_reduction_factor.v := 1
    else if (theta_FK.v < WG0_30.v) and (WG0_30.v < theta_SAT.v) then
      k_water_reduction_factor.v := (theta_SAT.v - WG0_30.v) /
        (theta_SAT.v - theta_FK.v);

    Nfast_Min_N.v := kfast_temp_coeff.v * Nfast.v * k_water_reduction_factor.v;
    Nslow_Min_N.v := kslow_temp_coeff.v * Nslow.v * k_water_reduction_factor.v;

    Nslow.c := -Nslow_Min_N.v;
    Nfast.c := -Nfast_Min_N.v;

    MinRate.v := Nfast_Min_N.v + Nslow_Min_N.v;

    MineralisedN.c := MinRate.v;

    Nmin_1.f_v^ := Nmin_1.f_v^ + MinRate.v * 1 / 3;
    Nmin_2.f_v^ := Nmin_2.f_v^ + MinRate.v * 1 / 3;
    Nmin_3.f_v^ := Nmin_3.f_v^ + MinRate.v * 1 / 3;
  end;

end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TMinMod2Pool]);
{$ENDIF}

end;

end.

