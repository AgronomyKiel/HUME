unit UMinModHan;

interface

uses
  Windows,USoilWaterMod, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
  vcl.Dialogs, UMod, Math, UState;

type
  TSpring_only = (is_true, is_false);
  TMinType     = (null, eins, zwei, drei);

  TMinModHan = class(TSubmodel)

  private
    fSpring_only: TSpring_only;
    fSWMOD: TSoilWaterMod;
  protected

  public
    Vorfrucht:    TPar;
    TextureClass: TPar;


    TextureClassIndex: TPar;
    kfast:           TVar;   // reaction constant for first order decomposition of Nfast [1/d]
    kslow:           TVar;   // reaction constant for first order decomposition of Nfast [1/d]
    MinRate:         TVar;
    Nfast_Min_N:     TVar;
    Nslow_Min_N:     TVar;
    TSUMSA:          TVar;
    DAYSA:           TVar;
    MeanTemp_autumn: TVAR;
    //fTempAutumn  : TVar;   //
    RF_WG:           TVar;
    avClayContent:   TVar;
    iniNfs:        TVar;
    // State Variables
    Nfast:           TState;   // fast decomposable pool of soil N [kg N/ha]
    Nslow:           TState;   // slow decomposable pool of soil N [kg N/ha]
    MineralisedN:    TState;

    // External Variables
    EC:             TExternV;
    Tmpm:           TExternV;
    WG0_30:         TExternV;
    Nmin1:       TExternV;
    Nmin2:       TExternV;
    Nmin3:       TExternV;
    sowingdate:     TExternV;
    dayofyear:      TExternV;
    optSpring_only: TOption;
    optMinType:     TOption;
    tempcorr:       boolean;
    fMinType : String;
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;


  published
    property Var_kfast: TVar Read kfast Write kfast;
    property Var_kslow: TVar Read kslow Write kslow;
    property Var_MinRate: TVar Read MinRate Write MinRate;
    property Var_Nfast_Min_N: TVar Read Nfast_Min_N Write Nfast_Min_N;
    property Var_Nslow_Min_N: TVar Read Nslow_Min_N Write Nslow_Min_N;
    property Var_RF_WG: TVar Read RF_WG Write RF_WG;

    property St_Nfast: TState Read Nfast Write Nfast;
    property St_Nslow: TState Read Nslow Write Nslow;
    property Ex_dayofyear: TExternV Read dayofyear Write dayofyear;
//    property Ex_


    // Properties External Variables
    property Ex_Tmpm: TExternV Read Tmpm Write Tmpm;
    property Ex_WG0_30: TExternV Read WG0_30 Write WG0_30;
    property opt_Spring_only: TSpring_only Read fSpring_only Write fSpring_only;
    property swmod: TSoilWaterMod read fSWMOD write fSWMOD; // to regard txtureclass of the toplyer
  end;  // SubmodelName

procedure Register;

implementation

procedure TMinModHan.createAll;

begin
  inherited createAll;
  VarCreate('kfast', '[1/d]', 0, True, kfast,
    'reaction constant for first order decomposition of Nfast [1/d]');
  VarCreate('kslow', '[1/d]', 0, True, kslow,
    'reaction constant for first order decomposition of Nfast [1/d]');
  VarCreate('MinRate', '', 0, True, MinRate, '');
  VarCreate('IniNfs', '', 0, True, iniNfs, 'sum of temp. corr. inital amount of the N-Fast + NSlowpool ');
  VarCreate('Nfast_Min_N', '', 0, True, Nfast_Min_N, '');
  VarCreate('Nslow_Min_N', '', 0, True, Nslow_Min_N, '');
  VarCreate('RF_WG', '', 0, True, RF_WG, '');
  //  VarCreate('fTempAutumn', '',0, true, fTempAutumn, 'rel. temp. factor for modifying Nfast');
  VarCreate('avClayContent', '[%]', 0, True, avClayContent);
  VarCreate('TSUMSA', '[°Cd]', 0, True, TSUMSA);
  VarCreate('DAYSA', '[-]', 0, True, DAYSA);
  VarCreate('MeanTemp_autumn', '[%]', 0, True, MeanTemp_autumn);
  ParCreate('Vorfrucht', '[-]', 0,
    Vorfrucht, '0=Sonstiges,1=Gerste,2=Weizen,3=Kartoffel,4=Raps,5=ZR');
  ParCreate('TextureClassIndex', '[-]', 0, TextureClassIndex, 'TextureClass 0-30');
  StateCreate('Nfast', '[kg N/ha]', 50, True, Nfast,
    'Fast decomposable Pool of Soil N [kg N/ha]');
  StateCreate('Nslow', '[kg N/ha]', 700, True, Nslow,
    'slow decomposable Pool of Soil N [kg N/ha]');
  StateCreate('MineralisedN', '[kg N/ha]', 0, True, MineralisedN);
  // External Variable
  ExternVCreate('EC', '', statefield, EC);
  //ExternVCreate('Netmin__1', '', statefield, Netmin_1);
  //ExternVCreate('Netmin__2', '', statefield, Netmin_2);
  //ExternVCreate('Netmin__3', '', statefield, Netmin_3);
  ExternVCreate('sowingdate', '', statefield, sowingdate);
  ExternVCreate('Tmpm', '', statefield, Tmpm);
  ExternVCreate('WG0_30', '', statefield, WG0_30);
  ExternVCreate('dayofyear', '', statefield, dayofyear);
  ExternVcreate('Nmin__1', '[kgN/ha]',STateField, Nmin1);
  ExternVcreate('Nmin__2', '[kgN/ha]',STateField, Nmin2);
  ExternVcreate('Nmin__3', '[kgN/ha]',STateField, Nmin3);
  OptCreate('optSpring_only', 'is_true', optSpring_only);
  optSpring_only.OptionList.Clear;
  optSpring_only.OptionList.Add('is_true');
  optSpring_only.OptionList.Add('is_false');
end;


procedure TMinModHan.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
   SWMOD.init(GlobMod);

   if  pos('ut',SWMOD.FTextClass1Option.Option)<> 0 then
      fMinType:='1'    //Löss
      else fMinType:='3';   // Sand


  if optSpring_only.option = 'is_true' then
  begin
    fSpring_only := is_true;
  end;
  if optSpring_only.option = 'is_false' then
  begin
    fSpring_only := is_false;
  end;

  if Vorfrucht.v = 1 then //Gerste
    NFast.v := -32.802 * 10 + 429.36//-32,802*  + 429,36
  else if Vorfrucht.v = 2 then //Weizen
    NFast.v := -37.319 * 10 + 501.62// -37,319 * [durchschnittstemperatur Herbst] + 501,62
  else if Vorfrucht.v = 3 then //Kartoffel
    NFast.v :=
      -4.9052 * 10 + 126.25  //= -4,9052*[durchschnittstemperatur Herbst] + 126,25
  else if Vorfrucht.v = 4 then //Raps
    NFast.v :=
      -18.178 * 10 + 348.03  //= -18,178*[durchschnittstemperatur Herbst] + 348,03
  else if Vorfrucht.v = 5 then //Zuckerrübe
    NFast.v :=
      -21.454 * 10 + 348.63 //= -21,454 * [durchschnittstemperatur Herbst] + 348,63
  else
    NFast.v := -13.379 * 10 + 250.60; // sonstiges -13,379*x + 250,60

  if SWMOD.FTextClass1Option.Option = 'ss' then
    avClayContent.v := 2.5 //Ss'
  else if SWMOD.FTextClass1Option.Option = 'ms'  then
    avClayContent.v := 2.5 //mS'
  else if SWMOD.FTextClass1Option.Option = 'msgs'  then
    avClayContent.v := 2.5 //mSgs'
  else if SWMOD.FTextClass1Option.Option = 'msfs'  then
    avClayContent.v := 2.5 //mSfs'
  else if SWMOD.FTextClass1Option.Option = 'fs'  then
    avClayContent.v := 2.5 //fS'
  else if SWMOD.FTextClass1Option.Option = 'fsms' then
    avClayContent.v := 2.5 //fSms'
  else if SWMOD.FTextClass1Option.Option = 'sl2'  then
    avClayContent.v := 6.5 //Sl2'
  else if SWMOD.FTextClass1Option.Option = 'sl3'  then
    avClayContent.v := 10 //Sl3'
  else if SWMOD.FTextClass1Option.Option = 'sl4'  then
    avClayContent.v := 14.5 //Sl4'
  else if SWMOD.FTextClass1Option.Option = 'slu'  then
    avClayContent.v := 12.5 //Slu'
  else if SWMOD.FTextClass1Option.Option = 'st2'  then
    avClayContent.v := 11 //St2'
  else if SWMOD.FTextClass1Option.Option = 'st3'  then
    avClayContent.v := 21 //St3'
  else if SWMOD.FTextClass1Option.Option = 'su2'  then
    avClayContent.v := 2.5 //Su2'
  else if SWMOD.FTextClass1Option.Option = 'su3'  then
    avClayContent.v := 4 //Su3'
  else if SWMOD.FTextClass1Option.Option = 'su4'  then
    avClayContent.v := 4 //Su4'
  else if SWMOD.FTextClass1Option.Option = 'ls2'  then
    avClayContent.v := 21 //Ls2'
  else if SWMOD.FTextClass1Option.Option = 'ls3'  then
    avClayContent.v := 21 //Ls3'
  else if SWMOD.FTextClass1Option.Option = 'ls4'  then
    avClayContent.v := 21 //Ls4'
  else if SWMOD.FTextClass1Option.Option = 'lt2'  then
    avClayContent.v := 30 //Lt2'
  else if SWMOD.FTextClass1Option.Option = 'lt3'  then
    avClayContent.v := 40 //Lt3'
  else if SWMOD.FTextClass1Option.Option = 'lts'  then
    avClayContent.v := 35 //Lts'
  else if SWMOD.FTextClass1Option.Option = 'lu'  then
    avClayContent.v := 23.5 //Lu'
  else if SWMOD.FTextClass1Option.Option = 'uu'  then
    avClayContent.v := 4 //Uu'
  else if SWMOD.FTextClass1Option.Option = 'uls'  then
    avClayContent.v := 12.5 //Uls'
  else if SWMOD.FTextClass1Option.Option = 'us' then
    avClayContent.v := 4 //Us'
  else if SWMOD.FTextClass1Option.Option = 'ut2'  then
    avClayContent.v := 10 //Ut2'
  else if SWMOD.FTextClass1Option.Option = 'ut3'  then
    avClayContent.v := 14.5 //Ut3'
  else if SWMOD.FTextClass1Option.Option = 'ut4'  then
    avClayContent.v := 21 //Ut4'
  else if SWMOD.FTextClass1Option.Option = 'tt'  then
    avClayContent.v := 82.5 //Tt'
  else if SWMOD.FTextClass1Option.Option = 'tl'  then
    avClayContent.v := 55 //Tl'
  else if SWMOD.FTextClass1Option.Option = 'tu2'  then
    avClayContent.v := 55 //Tu2'
  else if SWMOD.FTextClass1Option.Option = 'tu3'  then
    avClayContent.v := 37.5 //Tu3'
  else if SWMOD.FTextClass1Option.Option = 'tu4'  then
    avClayContent.v := 30 //Tu4'
  else
    avClayContent.v := 20; //default
  NSlow.v := 46.591 * avClayContent.v + 439.96;
  tempcorr := False;

end;


procedure TMinModHan.CalcRates;
var
  WG_proz,
  nFK, res, sat,b1,b2,a1,a2: real;     // WG bei Sättigung
  year, Month, Day: word;
  Month_gt, Day_gt, year_gt: word;
  Month_st, Day_st, year_st: word;
begin
  DecodeDate(globtime.v, Year_gt, Month_gt, Day_gt);
  DecodeDate(sowingdate.v, Year_st, Month_st, Day_st);

  if (fSpring_only = is_false) or
     ((Year_gt = Year_st) and (Month_gt >= 11) and (Vorfrucht.v = 5)) or
     ((Year_gt = Year_st) and (Month_gt >= 9) and (Vorfrucht.v <> 5)) or
     ((Year_gt <> Year_st){and (Ec.v<75)})
 then
  begin
   RF_WG.v:=swmod.ProzNFK0_30.v/100;
   RF_WG.v:= min(1,max(0.1,RF_WG.v));
 if fMinType = '1' then
   begin   // Löss
     kfast.v := tmpm.v*tmpm.v*(1.17/100000)+0.0017;
     kslow.v := tmpm.v*tmpm.v*(1.59/1000000)+2.9/100000;
   end else
   begin   //Sand
     kfast.v := tmpm.v*tmpm.v*(2.48/100000)+0.0029;
     kslow.v := tmpm.v*tmpm.v*(2.04/1000000)+2.97/100000;
  end;
    Nfast_Min_N.v := kfast.v * Nfast.v * RF_WG.v;
    Nslow_Min_N.v := kslow.v * Nslow.v * RF_WG.v;
    MinRate.v := Nfast_Min_N.v + Nslow_Min_N.v;
    Nfast.c := -Nfast_Min_N.v;
    Nslow.c := -Nslow_Min_N.v;
  end else
  begin
    MinRate.v := 0;
  end;
  MineralisedN.c := MinRate.v;
  Nmin1.f_v^  := Nmin1.f_v^+Minrate.v/3;
  Nmin2.f_v^  := Nmin2.f_v^+Minrate.v/3;
  Nmin3.f_v^  := Nmin3.f_v^+Minrate.v/3;
end;

procedure TMinModHan.Integrate;
{var
  year, Month, Day: word;
  Month_gt, Day_gt, year_gt: word;
  Month_st, Day_st, year_st: word;}
begin
 inherited;
 //DecodeDate(globtime.v, Year_gt, Month_gt, Day_gt);
 //DecodeDate(sowingdate.v, Year_st, Month_st, Day_st);

  {if Year_gt = Year_st then
  begin
    if (Month_gt >= 9) and (Month_gt < 12)  then
    begin
      TSUMSA.v := TSUMSA.v + TMPM.v * globmod.timestep;
      DAYSA.v  := DAYSA.v + 1 * globmod.timestep;
      MeanTemp_autumn.v := TSUMSA.v / DAYSA.v;
    end;
  end;}
 {if (Month_gt = 12) and (tempcorr = False) and (fSpring_only = is_true) then
  begin
   // to modify Nfast due to mean temperature in autumn /winter
      if Vorfrucht.v = 1 then //Gerste
        NFast.v :=  -32.802 * MeanTemp_autumn.v + 429.36
        else if Vorfrucht.v = 2 then //Weizen
          NFast.v :=  -37.319 * MeanTemp_autumn.v + 501.62
          else if Vorfrucht.v = 3 then //Kartoffel
            NFast.v := -4.9052 * MeanTemp_autumn.v + 126.25
            else if Vorfrucht.v = 4 then //Raps
              NFast.v := -18.178 * MeanTemp_autumn.v + 348.03
              else if Vorfrucht.v = 5 then //Zuckerrübe
                NFast.v :=-21.454 * MeanTemp_autumn.v + 348.63
              // sonstiges -13,379*x + 250,60
                else
                  NFast.v :=  -13.379 * MeanTemp_autumn.v + 250.60;
      tempcorr := True;
    end;}

 end;





procedure Register;
begin
  RegisterComponents('Simulation', [TMinModHan]);
end;

end.