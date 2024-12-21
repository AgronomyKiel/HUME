unit UMinModHan2;
// Written by A. M. Ratjen
// 03.07.2015  very simple model for N mineralization.
interface

uses
  Windows,USoilWaterMod, UDueng_ISIP, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
  vcl.Dialogs, UMod, Math, UState;

type
   TMinHash = (a1a,a2a,a3a,a4a,a5a,a6a,a1b,a2b,a3b,a4b,a5b,a6b,a1c,a2c,a3c,a4c,a5c,a6c,a1d,a2d,a3d,a4d,a5d,a6d);
  TMinModHan = class(TSubmodel)

  private
    fSWMOD: TSoilWaterMod;
    fdueng_isip: TDueng_ISIP;
    dNmin:  array[1..9] of real;
    strMinHash: String;
  protected
    fMinHash : TMinHash;
  public
    Vorfrucht:    TPar;
    avNcrop:           TPar;
    yRain:             TPar;
    avMayTemp:         TPar;
    TextureClass: TPar;
    BP:                TPar;
    relImmoRate:       TPar;
    ArrheniusRelMin:   TPar;
    TextureClassIndex: TPar;

    avClayContent:   TVar;
    MinRate:         TVar;
    ft:                TVar;
    PSI0_30:           TVar;
    fpF:               TVar;
    fclay:             TVar;
    VFW:               TVar;
    NImmoAutumn:       TVar;
    avMineff:          TVar;
    ImmoRate:          TVar;
    Nslow:             TVar;
    NminVB:            TVar;
    // State Variables
    MineralisedN:    TState;
    cumImmoN:                    TState;
    DaisyWeightedTsumAutumn :    TState;
    DaisyWeightedTsumS :         TState; // Daisy weited TSums since sowing
    DaisyWeightedTsum :          TState; // Daisy weited TSums since Spring

    // External Variables
    EC:             TExternV;
    Nmin0_90:       TExternV;
    Tmpm:           TExternV;
    WG0_30:         TExternV;
    Nmin:     array[1..9] of TExternV;
    sowingdate:     TExternV;
    dayofyear:      TExternV;
    OptMinHash : Toption;
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    FUNCTION DaisyRateCoeff(Tmpm,clay_c,PSI: real): real;
    FUNCTION calcAvgMineff(AMinHash: String;
                ANcrop,
                ANmin,
                AavMayTemp,
                ABP,
                AyRain:real
                ):real;
    FUNCTION calcPSI(b: real): real;

  published

    property Ex_dayofyear: TExternV Read dayofyear Write dayofyear;
    // Properties External Variables
    property Ex_Tmpm: TExternV Read Tmpm Write Tmpm;
    property Ex_WG0_30: TExternV Read WG0_30 Write WG0_30;
    property swmod: TSoilWaterMod read fSWMOD write fSWMOD; // to regard txtureclass of the toplyer
    // dueng_isip: TDueng_ISIP;
    property duengisip: TDueng_ISIP read fdueng_isip write fdueng_isip; // to regard fertilization of the toplyer

  end;

procedure Register;

implementation

function TMinModHan.calcAvgMineff(AMinHash: String;
                ANcrop,
                ANmin,
                AavMayTemp,
                ABP,
                AyRain:real
                ):real;
// linear regression derived from N-response curves. The effective N mineralization
// is the difference between Ncrop and N supply at Nopt (at marginal yield = 5)
   const pIntercept  = -173.4;
   const pNcrop      =  0.507;
   const pBP         =  0.22;
   const pMayTemp    =  6.106;
   const pyRain      = -0.039;
   const pNminVB     = -0.246;
   const pMaxMineff  =  60;
   const pMinMineff  =  10;
   const pAddOrg     =  20; // lang. org. Duenung
   const pMaxAddOrg  =  40;
   const pOrgInt     =  34.2;
   const pOrgInc     =  0.832;

  Var
  Mineff,MinAdd: extended;
  VFG: integer;
  VFW: extended;
  OrgFert : String;

  BEGIN
  Result := 0;
  MinAdd:=0;
  VFG:= StrToInt(copy(AMinHash,1,1));
  OrgFert:= copy(AMinHash,2,3);
  VFW:=20;  // sonstiges VFG:= 6
  case VFG of
        1 : VFW:= 0;
        2 : VFW:= 10;
        3 : VFW:= 20;
        4 : VFW:= 30;
        5 : VFW:= 40;
  end;
    Mineff:= VFW
           +pIntercept
           +pNcrop*ANcrop
           +pBP*ABP
           +pMayTemp*AavMayTemp
           +pyRain*AyRain
           +pNminVB*ANmin;
  Mineff:=max(min(pMaxMineff,Mineff),pMinMineff);

  if(OrgFert = 'b') then  //   lang. org. Düngun
    MinAdd:= 20
    else if(OrgFert = 'c') then  // Gülle Herbstg
      MinAdd:= (pOrgInt+ pOrgInc*Mineff)-Mineff
        else if(OrgFert = 'd') then // Gülle Herbst & lang. org. Düngung
          MinAdd:= (pOrgInt + pOrgInc*Mineff)-Mineff + pAddOrg;
  MinAdd:= min(MinAdd,pMaxAddOrg);
  Result := Mineff+ MinAdd;

  END;

function TMinModHan.DaisyRateCoeff(Tmpm,clay_c,PSI: real): real;
    var pF:real;
  BEGIN
// SOURCE:
// http://code.google.com/p/daisy-model/source/browse/tags/release_0_001/organic_matter.C?r=848
// Dez. 2013
  if(PSI>0)then
    pF:= log10(PSI) else
      pF:=0;

  if Tmpm < 0.0 then
    ft.v:=0 else
      if Tmpm< 20.0 then
        ft.v:=0.1 * Tmpm else
          ft.v:=exp(0.47 - 0.027 * Tmpm + 0.00193 * Tmpm *Tmpm);
  if (pF <= 0.0) then
    fpF.v:=0.6 else
    if (pF <= 1.5) then
      fpF.v:= 0.6 + (1.0 - 0.6) * pF / 1.5 else
        if (pF <= 2.5) then
         fpF.v:= 1.0 else
            if (pF <= 6.5) then
              fpF.v:= 1.0 - (pF - 2.5) / (6.5 - 2.5) else
                fpF.v:=0;

 // fclay.v:= (1.0 - (0.5/0.25) * (min (clay_c, 0.25)));
  DaisyRateCoeff:=max(0,Tmpm)*fpF.v*ft.v{*fclay.v};

  END;

  function TMinModHan.calcPSI(b: real): real;
  var
  psi_b_f,z1,z2:real;
  BEGIN
    If b >= swmod.WPar[1].b_sat then begin
      calcPSI := 0.0;

      exit;
    end;
    if b< swmod.WPar[1].b_rest then begin
      calcPSI := 1e5;

      exit;
    end;
    if (b-swmod.WPar[1].b_rest)>0.0 then begin
      z1 := (swmod.WPar[1].b_sat-swmod.WPar[1].b_rest)/(b-swmod.WPar[1].b_rest);
      z2 := power(z1, 1/swmod.WPar[1].m_par)-1;
      calcPSI := power(z2, 1/swmod.WPar[1].n_par)*1/swmod.WPar[1].alpha;
    end
    else calcPSI := 1e10;

  END;

procedure TMinModHan.createAll;
    Var
    i :integer;
begin
  inherited createAll;
  for i := 1 to 9 do
  begin
     ExternVCreate('Nmin_' + IntToStr(i), '[kg N/ha]', statefield, Nmin[i]);
  end;
  VarCreate('avMineff', '[kg N/ha]', 0, True, avMineff);
  VarCreate('avClayContent', '[%]', 0, True, avClayContent);

  VarCreate('MinRate', '', 0, True, MinRate, '');
  VarCreate('PSI0_30', '[hPa]', 0, True, PSI0_30, '');
  VarCreate('VFW', '[kg N/ha]', 0, True, VFW, 'N-Nachlieferung aus Vorffrucht nach DüV (Stand 2007)');
  VarCreate('fpF', '-', 0, True, fpF, 'abiotic rate coefficient for pF according to Daisy');
  VarCreate('fclay', '-', 0, True, fclay, 'abiotic rate coefficient for clay content according to Daisy');
  VarCreate('ft', '-', 0, True, ft, 'abiotic rate coefficient for temperature according to Daisy');
  VarCreate('ImmoRate', '-', 0, True, ImmoRate, 'N immobilization rate after harvest in autumn');
  VarCreate('NSlow', '[kg N/ha]', 50, True, NSlow,
             'Slow decomposable Pool of Soil N [kg N/ha]');
             //NImmoAutumn
  VarCreate('NminVB', '[KgN/ha]', 30, True, NminVB);
  VarCreate('NImmoAutumn', '-', 0, True, NImmoAutumn);
  ParCreate('Vorfrucht', '[-]', 0,
    Vorfrucht, '0=Sonstiges,1=Gerste,2=Weizen,3=Kartoffel,4=Raps,5=ZR');
  ParCreate('TextureClassIndex', '[-]', 0, TextureClassIndex, 'TextureClass 0-30');
  ParCreate('yRain', '[-]', 0, yRain, 'avg. annual rainfall');
  ParCreate('avNcrop', '[kg N/ha]', 250, avNcrop, 'avg. Crop N uptake');
  ParCreate('BP', '[-]',50, BP, 'Bodenwertzahl');
  ParCreate('avMayTemp', '[°C]',10, avMayTemp, ' avg. temperature during may');
  ParCreate('relImmoRate', '[-]',0.0003126, relImmoRate, 'rel incease rate of immobilization (based on Daisy rate coefficients)');
  ParCreate('ArrheniusRelMin', '[-]',0.01768, ArrheniusRelMin);

  StateCreate('cumImmoN', '[kg N/ha]', 0, True, cumImmoN);
  StateCreate('MineralisedN', '[kg N/ha]', 0, True, MineralisedN);
  StateCreate('DaisyWeightedTsumAutumn', '[°Cd]', 0, True, DaisyWeightedTsumAutumn);
  StateCreate('DaisyWeightedTsumS', '[°Cd]', 0, True, DaisyWeightedTsumS);
  StateCreate('DaisyWeightedTsum', '[°Cd]', 0, True, DaisyWeightedTsum);


  // External Variable
  ExternVCreate('EC', '', statefield, EC);
  //ExternVCreate('Netmin__1', '', statefield, Netmin_1);
  //ExternVCreate('Netmin__2', '', statefield, Netmin_2);
  //ExternVCreate('Netmin__3', '', statefield, Netmin_3);
  ExternVCreate('sowingdate', '', statefield, sowingdate);
  ExternVCreate('Nmin0_90', '[kgN/ha]', statefield, Nmin0_90);
  ExternVCreate('Tmpm', '', statefield, Tmpm);
  ExternVCreate('WG0_30', '', statefield, WG0_30);
  ExternVCreate('dayofyear', '', statefield, dayofyear);
  //ExternVCreate('NUpTake', '[kgN/ha]',statefield, NUpTake);
  OptCreate('MinHash','2b', optMinHash);
  optMinHash.OptionList.Clear;
  optMinHash.OptionList.Add('1a');
  optMinHash.OptionList.Add('2a');
  optMinHash.OptionList.Add('3a');
  optMinHash.OptionList.Add('4a');
  optMinHash.OptionList.Add('5a');
  optMinHash.OptionList.Add('6a');
  optMinHash.OptionList.Add('1b');
  optMinHash.OptionList.Add('2b');
  optMinHash.OptionList.Add('3b');
  optMinHash.OptionList.Add('4b');
  optMinHash.OptionList.Add('5b');
  optMinHash.OptionList.Add('6b');
  optMinHash.OptionList.Add('1c');
  optMinHash.OptionList.Add('2c');
  optMinHash.OptionList.Add('3c');
  optMinHash.OptionList.Add('4c');
  optMinHash.OptionList.Add('5c');
  optMinHash.OptionList.Add('6c');
  optMinHash.OptionList.Add('1d');
  optMinHash.OptionList.Add('2d');
  optMinHash.OptionList.Add('3d');
  optMinHash.OptionList.Add('4d');
  optMinHash.OptionList.Add('5d');
  optMinHash.OptionList.Add('6d');
end;


procedure TMinModHan.init(var GlobMod: TMod);
  var
  i: integer;
  Nfert: real; // amount of fertilized N
begin
  inherited init(GlobMod);

  strMinHash:=optMinHash.option;
 SWMOD.init(GlobMod);
 duengisip.Init(GlobMod); // VORSICHT ComIndex!!
// calc fertilization rate
 Nfert:= duengisip.STDNApp1.v +duengisip.STDNApp2.v+duengisip.STDNApp3.v
           -duengisip.NminVB.v;

 for i := 1 to 9 do begin
  dNmin[i]:=0;
 end;

if ((Vorfrucht.v = 1) or (Vorfrucht.v = 2) or (Vorfrucht.v = 3)) then begin
// Gerste, Weizen, Kartoffel
    NImmoAutumn.v := 50;
    VFW.v:= 0;
end else
  if Vorfrucht.v = 4 then begin //Raps
    NImmoAutumn.v := 35;
    VFW.v:= 10;
  end else
     if (Vorfrucht.v = 5) then begin //Zuckerrübe
       NImmoAutumn.v := 20;
       VFW.v:= 20;
      end else begin         // sonstige
          NImmoAutumn.v := 20;
          VFW.v:= 20;
        end;


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

  NSlow.v := 20+50*(avClayContent.v/100);


end;


procedure TMinModHan.CalcRates;
var
  PSI_, avTempAutumn:real;
  year, Month, Day: word;
  Month_gt, Day_gt, year_gt: word;
  Month_st, Day_st, year_st: word;
  i:integer;

begin
  DecodeDate(globtime.v, Year_gt, Month_gt, Day_gt);
  DecodeDate(sowingdate.v, Year_st, Month_st, Day_st);
  // get Nmin at begin of vegetation
  if (Month_gt=2) and (Day_gt=28) then begin
    NminVB.v:=Nmin0_90.v;
    avMineff.v:= calcAvgMineff(strMinHash,avNcrop.v,NminVB.v,avMayTemp.v,BP.v,yRain.v);
  end;
  // calculation of weighted mean temperatur in Autumn
  // SB 15.10-31.10  16 d
  PSI0_30.v:=calcPSI(WG0_30.v);
  if (Vorfrucht.v = 5) then
  begin
    if ((Year_gt = Year_st) and (Month_gt > 9) and (Month_gt < 11) and (Day_gt>15)) then
          DaisyWeightedTsumAutumn.c:=DaisyRateCoeff(Tmpm.v,avClayContent.v,
            PSI0_30.v) else DaisyWeightedTsumAutumn.c:=0;
  end else
    if (Vorfrucht.v = 4 ) then
    begin
      if ((Year_gt = Year_st) and (Month_gt > 7) and (Month_gt<11)) then
      begin
      // OSR:  01.08.-31.10. 91 d
        DaisyWeightedTsumAutumn.c:=DaisyRateCoeff(Tmpm.v,avClayContent.v,PSI0_30.v);
      end else
      DaisyWeightedTsumAutumn.c:=0;
    end else
        // else 01.09-31.10 60 d
       if ((Year_gt = Year_st) and (Month_gt > 8) and (Month_gt<11)
          and (Vorfrucht.v <> 5) and (Vorfrucht.v <> 4)) then
          begin
             DaisyWeightedTsumAutumn.c:=DaisyRateCoeff(Tmpm.v,avClayContent.v,calcPSI(WG0_30.v));
          end
       else
        DaisyWeightedTsumAutumn.c:=0;

 DaisyWeightedTsumS.c:=DaisyRateCoeff(Tmpm.v,avClayContent.v,PSI0_30.v);

 if((DaisyWeightedTsum.v<=0) and (DaisyWeightedTsumS.v>0)) then begin
   // calculate start Nmin values as a function of clay content and
   //  previous  crop. soils with high glay content have greater Nmin values
   // very rough estimate
    MinRate.v:=NSlow.v*(ArrheniusRelMin.v/(2*sqrt(DaisyWeightedTsumS.v)))*DaisyWeightedTsumS.c;
 end;

 if((Year_gt = Year_st+1) and (Month_gt > 2) ) then
// Tsum since spring:
  DaisyWeightedTsum.c:=DaisyRateCoeff(Tmpm.v,avClayContent.v,PSI0_30.v);

  if(DaisyWeightedTsum.v>0)then
    MinRate.v:=avMineff.v*(ArrheniusRelMin.v/(2*sqrt(DaisyWeightedTsum.v)))*DaisyWeightedTsum.c;
  // Immonilization after harvest (cereals and potato) for start Nmin values at sowing
  if(DaisyWeightedTsumAutumn.c>0)then
   ImmoRate.v:= NImmoAutumn.v*relImmoRate.v*DaisyWeightedTsumAutumn.c
    else ImmoRate.v:= 0;
      MineralisedN.c:= MinRate.v - ImmoRate.v;

   if (MineralisedN.c>0) then begin
      for i := 1 to 3 do begin
        dNmin[i]:= MineralisedN.c/3;
        Nmin[i].f_v^  := Nmin[i].f_v^+dNmin[i];
end;
       MineralisedN.c:= dNmin[1]+dNmin[2]+dNmin[3];
  end else
    if (MineralisedN.c<0) then begin
     for i := 1 to 3 do begin
       dNmin[i]:= max(-Nmin[i].f_v^*0.7,MineralisedN.c/3);
       Nmin[i].f_v^  := Nmin[i].f_v^+dNmin[i];
end;
     MineralisedN.c:= dNmin[1]+dNmin[2]+dNmin[3];
     cumImmoN.c:=-MineralisedN.c;
  end else
      cumImmoN.c:=0;

end;
procedure TMinModHan.Integrate;

begin
 inherited;


end;





procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TMinModHan]);
end;

end.
