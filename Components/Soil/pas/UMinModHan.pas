unit UMinModHan;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UState;

type
  TSpring_only = (is_true, is_false);
  TMinType = (null, eins, zwei, drei);

  TMinModHan = class(TSubmodel)

  private
    fSpring_only: TSpring_only;
    fMinType: TMinType;
  protected

  public
    kfast: TVar;
      // reaction constant for first order decomposition of Nfast [1/d]
    kslow: TVar;
      // reaction constant for first order decomposition of Nfast [1/d]
    MinRate: TVar; //
    Nfast_Min_N: TVar; //
    Nslow_Min_N: TVar; //
    RF_WG: TVar; //
    // State Variables
    Nfast: TState; // fast decomposable pool of soil N [kg N/ha]
    Nslow: TState; // slow decomposable pool of soil N [kg N/ha]

    Nfast_scal: TPar;
    Nslow_scal: TPar;

    Nfast_par: TPar;
    Nslow_par: TPar;


    MineralisedN: TState;

             // External Variables
    Tmpm: TExternV; //
    WG0_30: TExternV; //
    Nmin_1: TExternV;
    Nmin_2: TExternV;
    Nmin_3: TExternV;
    dayofyear: TExternV;
    optSpring_only: TOption;
    optMinType: TOption;
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;

  published
    property Var_kfast: TVar read kfast write kfast;
    property Var_kslow: TVar read kslow write kslow;
    property Var_MinRate: TVar read MinRate write MinRate;
    property Var_Nfast_Min_N: TVar read Nfast_Min_N write Nfast_Min_N;
    property Var_Nslow_Min_N: TVar read Nslow_Min_N write Nslow_Min_N;
    property Var_RF_WG: TVar read RF_WG write RF_WG;

    property St_Nfast: TState read Nfast write Nfast;
    property St_Nslow: TState read Nslow write Nslow;
    property Ex_dayofyear: TExternV read dayofyear write dayofyear;

         // Properties External Variables
    property Ex_Tmpm: TExternV read Tmpm write Tmpm;
    property Ex_WG0_30: TExternV read WG0_30 write WG0_30;
    property opt_Spring_only: TSpring_only read fSpring_only write fSpring_only;
    property opt_MinType: TMinType read fMinType write fMinType;

  end; // SubmodelName

procedure Register;

implementation

  uses Math;

procedure TMinModHan.createAll;

begin
  inherited createAll;
  VarCreate('kfast', '[1/d]', 0, true, kfast,
    'reaction constant for first order decomposition of Nfast [1/d]');
  VarCreate('kslow', '[1/d]', 0, true, kslow,
    'reaction constant for first order decomposition of Nfast [1/d]');
  VarCreate('MinRate', '', 0, true, MinRate, '');
  VarCreate('Nfast_Min_N', '', 0, true, Nfast_Min_N, '');
  VarCreate('Nslow_Min_N', '', 0, true, Nslow_Min_N, '');
  VarCreate('RF_WG', '', 0, true, RF_WG, '');

  ParCreate('Nfast', '[]', 50, Nfast_par);
  ParCreate('NSlow', '[]', 700, Nslow_par);
  ParCreate('NFast_scal', '[]', 1.0, NFast_scal);
  ParCreate('NSlow_scal', '[]', 1.0, Nslow_scal);

  StateCreate('Nfast', '[kg N/ha]',  0, true, Nfast,
    'Fast decomposable Pool of Soil N [kg N/ha]');
  StateCreate('Nslow', '[kg N/ha]',  0, true, Nslow,
    'slow decomposable Pool of Soil N [kg N/ha]');
  StateCreate('MineralisedN', '[kg N/ha]', 0, true, MineralisedN);

         // External Variable
  ExternVCreate('Nmin_1', '', statefield, Nmin_1);
  ExternVCreate('Nmin_2', '', statefield, Nmin_2);
  ExternVCreate('Nmin_3', '', statefield, Nmin_3);
  ExternVCreate('Tmpm', '', statefield, Tmpm);
  ExternVCreate('WG0_30', '', statefield, WG0_30);
  ExternVCreate('dayofyear', '', statefield, dayofyear);






  OptCreate('optSpring_only', 'is_true', optSpring_only);
  optSpring_only.OptionList.Clear;
  optSpring_only.OptionList.Add('is_true');
  optSpring_only.OptionList.Add('is_false');

  OptCreate('optMinType', '3', optMinType);
  optMinType.OptionList.Clear;
  optMinType.OptionList.Add('0');
  optMinType.OptionList.Add('1');
  optMinType.OptionList.Add('2');
  optMinType.OptionList.Add('3');
end;

procedure TMinModHan.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);

  Nfast.v := Nfast_par.v;
  Nslow.v := Nslow_par.v;

  if optSpring_only.option = 'is_true' then
    fSpring_only := is_true
  else
    fSpring_only := is_false;

  if (optMinType.option = '0') then  fMinType := null
  else if (optMinType.option = '1') then fMinType := eins
  else if (optMinType.option = '2') then fMinType := zwei
  else if (optMinType.option = '3') then fMinType := drei;

end;

procedure TMinModHan.CalcRates;
var
  WG_proz: real;
  Mintype: integer;
begin

  case fMinType of
    null: MinType := 0;
    eins: MinType := 1;
    zwei: MinType := 2;
    drei: MinType := 3;
  end;

  if (fSpring_only = is_false) or ((dayofyear.v > 30) and (dayofyear.v < 150))
    then begin
    WG_proz := WG0_30.v * 100;

    case MinType of
      0: begin
          if (tmpm.v > 4) then begin
            kfast.v := 0.00283038929694036 + 0.000241238780969197 * TMPM.v +
              4.60438756991133E-17 * EXP(TMPm.v) - 0.00283749213828657 *
              EXP(-TMPm.v);
            kslow.v := 2.63684490474547E-07 - 0.0000377352135515377 * TMPM.v +
              2.42014127605001E-06 * TMPm.v * TMPm.v + 0.0000940601768783453 *
              sqrt(TMPm.v)
          end else if (tmpm.v <= 4) and (tmpm.v > 0) then begin
            kfast.v := 0.00374337393946272;
            kslow.v := 0.0000761654444578145
          end else if (tmpm.v <= 0) then begin
            kfast.v := 0;
            kslow.v := 0
          end;

          if (WG_proz < 7) then // ACHTUNG HORST: HIER GEÄNDERT
            RF_WG.v := 0
          else if (WG_proz < 28) then
            RF_WG.v := 1.05105 - 51.892 / (WG_proz * WG_proz)
          else if (WG_proz < (-0.25 * tmpm.v + 41)) then
            RF_WG.v := 1
          else if (WG_proz >= (-0.25 * tmpm.v + 41)) then
            RF_WG.v := 0;
        end;
      1: begin
          if (tmpm.v > 4) then begin
            kfast.v := 0.00283038929694036 + 0.000241238780969197 * TMPM.v +
              4.60438756991133E-17 * EXP(TMPm.v) - 0.00283749213828657 *
              EXP(-TMPm.v);
            kslow.v := 2.63684490474547E-07 - 0.0000377352135515377 * TMPM.v +
              2.42014127605001E-06 * TMPm.v * TMPm.v + 0.0000940601768783453 *
              sqrt(TMPm.v)
          end else if (tmpm.v <= 4) and (tmpm.v > 0) then begin
            kfast.v := 0.00374337393946272;
            kslow.v := 0.0000761654444578145
          end else if (tmpm.v <= 0) then begin
            kfast.v := 0;
            kslow.v := 0
          end;

          if (WG_proz < 7) then
            RF_WG.v := 0
          else if (WG_proz < 28) then
            RF_WG.v := 1.05105 - 51.892 / (WG_proz * WG_proz)
          else if (WG_proz < (-0.25 * tmpm.v + 41)) then
            RF_WG.v := 1
          else if (WG_proz >= (-0.25 * tmpm.v + 41)) then
            RF_WG.v := 0;
        end;
      2: begin
          if (tmpm.v > 0) then begin
            kfast.v := 0.0000208267214845294 - 0.000606405281917845 * TMPM.v +
              3.41519923263345 - 07 * Tmpm.v * Tmpm.v * Tmpm.v +
              4.46234338201078E-17 *
              EXP(Tmpm.v) + 0.00340242172171783 * sqrt(Tmpm.v); kslow.v :=
            8.04169589872123E-06 + 0.000108210333298957 * TMPM.v -
              0.0000565276121536818 * Tmpm.v * sqrt(Tmpm.v) +
              5.22212708589995E-06 * Tmpm.v * Tmpm.v * sqrt(Tmpm.v) -
                6.47037273867602E-07 * Tmpm.v *
              Tmpm.v * Tmpm.v
          end else if (tmpm.v <= 0) then begin
            kfast.v := 0;
            kslow.v := 0
          end;

          if (WG_proz < 5) then
            RF_WG.v := 0
          else if (WG_proz < 28) then
            RF_WG.v := 1.19858 - (6.02605 / WG_proz)
          else if (WG_proz < (-0.25 * tmpm.v + 35)) then
            RF_WG.v := 1
          else if (WG_proz >= (-0.25 * tmpm.v + 35)) then
            RF_WG.v := 0;
        end;

      3: begin
          if (tmpm.v > 0) then begin
            kfast.v := 0.00346669954909668 + 0.000103766656068994 * TMPM.v +
              3.91298999658486E-06 * Tmpm.v * Tmpm.v * sqrt(Tmpm.v) +
              3.07961781377199E-17 * EXP(Tmpm.v) - 0.0034549269082246 *
              EXP(-Tmpm.v);
            kslow.v := 0.00251072814784391 * EXP(-EXP(-((tmpm.v -
              45.2505227488969) / 21.3262596180801)) - ((tmpm.v -
                45.2505227488969) /
              21.3262596180801) + 1)
          end else if (tmpm.v <= 0) then begin
            kfast.v := 0;
            kslow.v := 0;
          end;

          if (WG_proz < 5) then
            RF_WG.v := 0
          else if (WG_proz < 28) then
            RF_WG.v := 1.19858 - (6.02605 / WG_proz)
          else if (WG_proz < (-0.25 * tmpm.v + 35)) then
            RF_WG.v := 1
          else if (WG_proz >= (-0.25 * tmpm.v + 35)) then
            RF_WG.v := 0
        end;
    end;

    Nfast_Min_N.v := min(Nfast.v, kfast.v * Nfast.v * RF_WG.v);
    Nslow_Min_N.v := kslow.v * Nslow.v * RF_WG.v;
    MinRate.v := Nfast_Min_N.v + Nslow_Min_N.v;
    Nfast.c := -Nfast_Min_N.v;
    Nslow.c := -Nslow_Min_N.v;
  end else MinRate.v := 0;

  Nfast.v := NFast_scal.v * NFast.v;
  Nslow.v := Nslow_scal.v * Nslow.v;

  MineralisedN.c := MinRate.v;
  Nmin_1.f_v^ := Nmin_1.f_v^ + Minrate.v / 3;
  Nmin_2.f_v^ := Nmin_2.f_v^ + Minrate.v / 3;
  Nmin_3.f_v^ := Nmin_3.f_v^ + Minrate.v / 3;

end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TMinModHan]);
end;

end.

