/// <summary>
/// Contains implementation for derivation of Van Genuchten parameters from texture
/// classes according to Ad-hoc-AG Boden: Verknüpfungsregel 1.18, Tabelle 1.
/// Ulf Böttcher, 29.4.09
/// 1st modification: new values for parameters b_sat, b_rest, alpha and n_par according to DWA-Regelwerk: Arbeitsblatt DWA-A 920-1-Bodenfunktionsansprache
/// Teil 1: Ableitung von Kennwerten des Bodenwasserhaushalts, Tabelle 16.
/// Thomas Räbiger, 16.03.2017
/// </summary>
unit USoilTexture;



interface
uses
  Classes, UState, UGenucht;

type
/// <summary>
/// Texture classes according to Bodenkundliche Kartieranleitung 5. Auflage
/// </summary>
  TTextureClass = (Ss,mS,mSgs,mSfs,fS,fSms,Sl2,Sl3,Sl4,Slu,St2,St3,Su2,Su3,Su4,Ls2,Ls3,Ls4,Lt2,Lt3,Lts,Lu,Uu,Uls,Us,Ut2,Ut3,Ut4,Tt,Tl,Ts2,Ts3,Ts4,Tu2,Tu3,Tu4);

/// <summary>
/// bulk density classes according to KA5
/// </summary>
  TLDClass = (LD1, LD2, LD3, LD4, LD5);

/// <summary>
/// numerical bulk density as constants
/// </summary>
  TLD = (LD13, LD142, LD15, LD164, LD17, OldVersion);

/// <summary>
/// Option for texture classes
/// </summary>
  TTextClassOption = class(TOption)
    procedure AddTextureClasses;
  end;
  // TTexture_version = (RR,KA5)
  //TTextClassOption = class(TOption)
  //TTexture_version = class(TOption)

  /// <summary>
  /// Option for bulk density classes
  /// </summary>
  TLDClassOption = class(TOption)
    procedure AddLDClasses;
  end;

  /// <summary>
  /// option for numerical bulk density
        /// </summary>
 TLDOption = class(TOption)
  procedure AddLD;
 end;


procedure setTextClassOption(var ATextureClass: TTextureClass; AOptionVal: string);
procedure setLDClassOption(var ALDClass: TLDClass; AOptionVal: string);
procedure setLDOption(var ALD: TLD; AOptionVal: string);
procedure VanGenuchtenFromTextureClass_RR(GPar: TGenucht; TC: TTextureClass);
procedure VanGenuchtenFromTextureClass_KA(GPar: TGenucht; TC: TTextureClass);
function KSFromTextureClass_RR(TC: TTextureClass; ALD: TLD): real;
function KSFromTextureClass_KA(TC: TTextureClass): real;
function ClayFromTexture(TC: TTextureClass): real;
procedure AddClasses(l: TStrings);


implementation
uses
  SysUtils;

procedure AddClasses(l: TStrings);
begin
  l.Add('Ss');
  l.Add('mS');
  l.Add('mSgs');
  l.Add('mSfs');
  l.Add('fS');
  l.Add('fSms');
  l.Add('Sl2');
  l.Add('Sl3');
  l.Add('Sl4');
  l.Add('Slu');
  l.Add('St2');
  l.Add('St3');
  l.Add('Su2');
  l.Add('Su3');
  l.Add('Su4');
  l.Add('Ls2');
  l.Add('Ls3');
  l.Add('Ls4');
  l.Add('Lt2');
  l.Add('Lt3');
  l.Add('Lts');
  l.Add('Lu');
  l.Add('Uu');
  l.Add('Uls');
  l.Add('Us');
  l.Add('Ut2');
  l.Add('Ut3');
  l.Add('Ut4');
  l.Add('Tt');
  l.Add('Tl');
  l.Add('Tu2');
  l.Add('Tu3');
  l.Add('Tu4');
  l.Add('Ts2');
  l.Add('Ts3');
  l.Add('Ts4');
end;

procedure TTextClassOption.AddTextureClasses;
begin
  AddClasses(OptionList);
end;

procedure setTextClassOption(var ATextureClass: TTextureClass; AOptionVal: string);
begin
  if Uppercase(AOptionVal) = Uppercase('Ss') then ATextureClass := Ss;
  if Uppercase(AOptionVal) = Uppercase('mS') then ATextureClass := mS;
  if Uppercase(AOptionVal) = Uppercase('mSgs') then ATextureClass := mSgs;
  if Uppercase(AOptionVal) = Uppercase('mSfs') then ATextureClass := mSfs;
  if Uppercase(AOptionVal) = Uppercase('fS') then ATextureClass := fS;
  if Uppercase(AOptionVal) = Uppercase('fSms') then ATextureClass := fSms;
  if Uppercase(AOptionVal) = Uppercase('Sl2') then ATextureClass := Sl2;
  if Uppercase(AOptionVal) = Uppercase('Sl3') then ATextureClass := Sl3;
  if Uppercase(AOptionVal) = Uppercase('Sl4') then ATextureClass := Sl4;
  if Uppercase(AOptionVal) = Uppercase('Slu') then ATextureClass := Slu;
  if Uppercase(AOptionVal) = Uppercase('St2') then ATextureClass := St2;
  if Uppercase(AOptionVal) = Uppercase('St3') then ATextureClass := St3;
  if Uppercase(AOptionVal) = Uppercase('Su2') then ATextureClass := Su2;
  if Uppercase(AOptionVal) = Uppercase('Su3') then ATextureClass := Su3;
  if Uppercase(AOptionVal) = Uppercase('Su4') then ATextureClass := Su4;
  if Uppercase(AOptionVal) = Uppercase('Ls2') then ATextureClass := Ls2;
  if Uppercase(AOptionVal) = Uppercase('Ls3') then ATextureClass := Ls3;
  if Uppercase(AOptionVal) = Uppercase('Ls4') then ATextureClass := Ls4;
  if Uppercase(AOptionVal) = Uppercase('Lt2') then ATextureClass := Lt2;
  if Uppercase(AOptionVal) = Uppercase('Lt3') then ATextureClass := Lt3;
  if Uppercase(AOptionVal) = Uppercase('Lts') then ATextureClass := Lts;
  if Uppercase(AOptionVal) = Uppercase('Lu')  then ATextureClass := Lu;
  if Uppercase(AOptionVal) = Uppercase('Uu') then ATextureClass := Uu;
  if Uppercase(AOptionVal) = Uppercase('Uls') then ATextureClass := Uls;
  if Uppercase(AOptionVal) = Uppercase('Us') then ATextureClass := Us;
  if Uppercase(AOptionVal) = Uppercase('Ut2') then ATextureClass := Ut2;
  if Uppercase(AOptionVal) = Uppercase('Ut3') then ATextureClass := Ut3;
  if Uppercase(AOptionVal) = Uppercase('Ut4') then ATextureClass := Ut4;
  if Uppercase(AOptionVal) = Uppercase('Lt3') then ATextureClass := Lt3;
  if Uppercase(AOptionVal) = Uppercase('Tt') then ATextureClass := Tt;
  if Uppercase(AOptionVal) = Uppercase('Tl')  then ATextureClass := Tl;
  if Uppercase(AOptionVal) = Uppercase('Tu2') then ATextureClass := Tu2;
  if Uppercase(AOptionVal) = Uppercase('Tu3') then ATextureClass := Tu3;
  if Uppercase(AOptionVal) = Uppercase('Tu4') then ATextureClass := Tu4;
  if Uppercase(AOptionVal) = Uppercase('Ts2') then ATextureClass := Ts2;
  if Uppercase(AOptionVal) = Uppercase('Ts3') then ATextureClass := Ts3;
  if Uppercase(AOptionVal) = Uppercase('Ts4') then ATextureClass := Ts4;
end;



procedure AddMyLDClasses(l: TStrings);
begin
  l.Add('LD1');
  l.Add('LD2');
  l.Add('LD3');
  l.Add('LD4');
  l.Add('LD5');
end;


procedure TLDClassOption.AddLDClasses;
begin
  AddMyLDClasses(OptionList);
end;


procedure AddMyLDs(l: TStrings);
begin
        l.Add('LD13');
        l.Add('LD142');
        l.Add('LD15');
        l.Add('LD164');
        l.Add('LD17');
        l.Add('OldVersion');
end;


procedure TLDOption.AddLD;
begin
  AddMyLDs(OptionList);
end;

procedure setLDClassOption(var ALDClass: TLDClass; AOptionVal: string);
begin
  if Uppercase(AOptionVal) = Uppercase('LD1') then ALDClass := LD1;
  if Uppercase(AOptionVal) = Uppercase('LD2') then ALDClass := LD2;
  if Uppercase(AOptionVal) = Uppercase('LD3') then ALDClass := LD3;
  if Uppercase(AOptionVal) = Uppercase('LD4') then ALDClass := LD4;
  if Uppercase(AOptionVal) = Uppercase('LD5') then ALDClass := LD5;
end;


procedure setLDOption(var ALD: TLD; AOptionVal: string);
begin
  if Uppercase(AOptionVal) = Uppercase('LD13') then ALD := LD13;
  if Uppercase(AOptionVal) = Uppercase('LD142') then ALD := LD142;
  if Uppercase(AOptionVal) = Uppercase('LD15') then ALD := LD15;
  if Uppercase(AOptionVal) = Uppercase('LD164') then ALD := LD164;
  if Uppercase(AOptionVal) = Uppercase('LD17') then ALD := LD17;
  if Uppercase(AOptionVal) = Uppercase('OldVersion') then ALD := OldVersion;

end;



procedure VanGenuchtenFromTextureClass_KA(GPar: TGenucht; TC: TTextureClass);
begin
  case TC of
  Ss: begin
          GPar.b_sat := 0.370687;
          GPar.b_rest := 0.043019;
          GPar.alpha := 0.087424;
          GPar.n_par := 1.57535;
          GPar.l_par := 0.5;
       end;
  mS: begin
          GPar.b_sat := 0.381373;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.184987;
          GPar.n_par := 1.37136;
          GPar.l_par := 0.5;
       end;
  mSgs: begin
          GPar.b_sat := 0.371479;
          GPar.b_rest := 0.042115;
          GPar.alpha := 0.095519;
          GPar.n_par := 1.61630;
          GPar.l_par := 0.5;
        end;
  mSfs: begin
          GPar.b_sat := 0.384542;
          GPar.b_rest := 0.048476;
          GPar.alpha := 0.068725;
          GPar.n_par := 1.63898;
          GPar.l_par := 0.5;
      end;
  fS: begin
          GPar.b_sat := 0.400616;
          GPar.b_rest := 0.005931;
          GPar.alpha := 0.050887;
          GPar.n_par := 1.46409;
          GPar.l_par := 0.5;
      end;
  fSms: begin
          GPar.b_sat := 0.382462;
          GPar.b_rest := 0.021223;
          GPar.alpha := 0.059958;
          GPar.n_par := 1.48881;
          GPar.l_par := 0.5;
       end;
  Sl2: begin
          GPar.b_sat := 0.379577;
          GPar.b_rest := 0;
          GPar.alpha := 0.078636;
          GPar.n_par := 1.26415;
          GPar.l_par := 0.5;
       end;
  Sl3: begin
          GPar.b_sat := 0.363891;
          GPar.b_rest := 0;
          GPar.alpha := 0.047598;
          GPar.n_par := 1.22044;
          GPar.l_par := 0.5;
       end;
  Sl4: begin
          GPar.b_sat := 0.339446;
          GPar.b_rest := 0;
          GPar.alpha := 0.04281;
          GPar.n_par := 1.17651;
          GPar.l_par := 0.5;
       end;
  Slu: begin
          GPar.b_sat := 0.386028;
          GPar.b_rest := 0;
          GPar.alpha := 0.017596;
          GPar.n_par := 1.232950;
          GPar.l_par := 0.5;
       end;
  St2: begin
          GPar.b_sat := 0.381248;
          GPar.b_rest := 0;
          GPar.alpha := 0.121368;
          GPar.n_par := 1.22531;
          GPar.l_par := 0.5;
       end;
  St3: begin
          GPar.b_sat := 0.368492;
          GPar.b_rest := 0.030253;
          GPar.alpha := 0.108036;
          GPar.n_par := 1.13906;
          GPar.l_par := 0.5;
       end;
  Su2: begin
          GPar.b_sat := 0.382197;
          GPar.b_rest := 0.050770;
          GPar.alpha := 0.067866;
          GPar.n_par := 1.437040;
          GPar.l_par := 0.5;
       end;
  Su3: begin
          GPar.b_sat := 0.363185;
          GPar.b_rest := 0;
          GPar.alpha := 0.026439;
          GPar.n_par := 1.281280;
          GPar.l_par := 0.5;
       end;
  Su4: begin
          GPar.b_sat := 0.373858;
          GPar.b_rest := 0;
          GPar.alpha := 0.016678;
          GPar.n_par := 1.275000;
          GPar.l_par := 0.5;
       end;
  Ls2: begin
          GPar.b_sat := 0.398235;
          GPar.b_rest := 0;
          GPar.alpha := 0.031428;
          GPar.n_par := 1.125800;
          GPar.l_par := 0.5;
       end;
  Ls3: begin
          GPar.b_sat := 0.356344;
          GPar.b_rest := 0;
          GPar.alpha := 0.035990;
          GPar.n_par := 1.115820;
          GPar.l_par := 0.5;
       end;
  Ls4: begin
          GPar.b_sat := 0.343159;
          GPar.b_rest := 0;
          GPar.alpha := 0.049791;
          GPar.n_par := 1.114930;
          GPar.l_par := 0.5;
       end;
  Lt2: begin
          GPar.b_sat := 0.409840;
          GPar.b_rest := 0;
          GPar.alpha := 0.012252;
          GPar.n_par := 1.102330;
          GPar.l_par := 0.5;
       end;
  Lt3: begin
          GPar.b_sat := 0.432805;
          GPar.b_rest := 0;
          GPar.alpha := 0.00843;
          GPar.n_par := 1.083260;
          GPar.l_par := 0.5;
       end;
  Lts: begin
          GPar.b_sat := 0.377863;
          GPar.b_rest := 0;
          GPar.alpha := 0.015133;
          GPar.n_par := 1.088250;
          GPar.l_par := 0.5;
       end;
  Lu: begin
          GPar.b_sat := 0.421217;
          GPar.b_rest := 0;
          GPar.alpha := 0.013345;
          GPar.n_par := 1.126140;
          GPar.l_par := 0.5;
       end;
  Uu: begin
          GPar.b_sat := 0.421256;
          GPar.b_rest := 0;
          GPar.alpha := 0.003405;
          GPar.n_par := 1.34475;
          GPar.l_par := 0.5;
       end;
  Uls: begin
          GPar.b_sat := 0.400900;
          GPar.b_rest := 0;
          GPar.alpha := 0.013197;
          GPar.n_par := 1.21234;
          GPar.l_par := 0.5;
       end;
 Us: begin
          GPar.b_sat := 0.416694;
          GPar.b_rest := 0;
          GPar.alpha := 0.008960;
          GPar.n_par := 1.25126;
          GPar.l_par := 0.5;
       end;
  Ut2: begin
          GPar.b_sat := 0.407810;
          GPar.b_rest := 0;
          GPar.alpha := 0.007585;
          GPar.n_par := 1.253520;
          GPar.l_par := 0.5;
       end;
  Ut3: begin
          GPar.b_sat := 0.399765;
          GPar.b_rest := 0;
          GPar.alpha := 0.008499;
          GPar.n_par := 1.225240;
          GPar.l_par := 0.5;
       end;
  Ut4: begin
          GPar.b_sat := 0.399654;
          GPar.b_rest := 0;
          GPar.alpha := 0.009133;
          GPar.n_par := 1.174410;
          GPar.l_par := 0.5;
       end;
  Tt: begin
          GPar.b_sat := 0.550541;
          GPar.b_rest := 0;
          GPar.alpha := 0.006812;
          GPar.n_par := 1.08155;
          GPar.l_par := 0.5;
       end;
  Tl: begin
          GPar.b_sat := 0.501398;
          GPar.b_rest := 0.003932;
          GPar.alpha := 0.033118;
          GPar.n_par := 1.06283;
          GPar.l_par := 0.5;
       end;
  Tu2: begin
          GPar.b_sat := 0.487379;
          GPar.b_rest := 0;
          GPar.alpha := 0.003318;
          GPar.n_par := 1.09388;
          GPar.l_par := 0.5;
       end;
  Tu3: begin
          GPar.b_sat := 0.446182;
          GPar.b_rest := 0;
          GPar.alpha := 0.007518;
          GPar.n_par := 1.09276;
          GPar.l_par := 0.5;
       end;
  Tu4: begin
          GPar.b_sat := 0.421068;
          GPar.b_rest := 0;
          GPar.alpha := 0.019840;
          GPar.n_par := 1.10522;
          GPar.l_par := 0.5;
       end;
  end; {of case}
end;
procedure VanGenuchtenFromTextureClass_RR(GPar: TGenucht; TC: TTextureClass);
begin
  case TC of
  Ss: begin
          GPar.b_sat := 0.3879;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.26437;
          GPar.n_par := 1.35154;
          GPar.l_par := -0.594;
	   end;
  mS: begin
          GPar.b_sat := 0.3886;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.26188;
          GPar.n_par := 1.35330;
          GPar.l_par := -0.58;
       end;
  mSgs: begin
          GPar.b_sat := 0.3886;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.26188;
          GPar.n_par := 1.35330;
          GPar.l_par := -0.579;
        end;
  mSfs: begin
          GPar.b_sat := 0.3886;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.26188;
          GPar.n_par := 1.35330;
          GPar.l_par := -0.579;
      end;
  fS: begin
          GPar.b_sat := 0.4095;
          GPar.b_rest := 0;
          GPar.alpha := 0.15041;
          GPar.n_par := 1.33576;
          GPar.l_par := -0.579;
      end;
  fSms: begin
          GPar.b_sat := 0.4095;
          GPar.b_rest := 0;
          GPar.alpha := 0.15041;
          GPar.n_par := 1.33576;
          GPar.l_par := -0.328;
       end;
  Sl2: begin
          GPar.b_sat := 0.3949;
          GPar.b_rest := 0;
          GPar.alpha := 0.11647;
          GPar.n_par := 1.25425;
          GPar.l_par := 0.5;
       end;
  Sl3: begin
          GPar.b_sat := 0.3952;
          GPar.b_rest := 0.0519;
          GPar.alpha := 0.07097;
          GPar.n_par := 1.35096;
          GPar.l_par := 0.5;
       end;
  Sl4: begin
          GPar.b_sat := 0.4101;
          GPar.b_rest := 0;
          GPar.alpha := 0.10486;
          GPar.n_par := 1.18427;
          GPar.l_par := -3.236;
       end;
  Slu: begin
          GPar.b_sat := 0.4138;
          GPar.b_rest := 0;
          GPar.alpha := 0.08165;
          GPar.n_par := 1.17695;
          GPar.l_par := -3.919;
       end;
  St2: begin
          GPar.b_sat := 0.4049;
          GPar.b_rest := 0;
          GPar.alpha := 0.48458;
          GPar.n_par := 1.18828;
          GPar.l_par := -6.189;
       end;
  St3: begin
          GPar.b_sat := 0.4214;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.18023;
          GPar.n_par := 1.13230;
          GPar.l_par := -3.42;
       end;
  Su2: begin
          GPar.b_sat := 0.3786;
          GPar.b_rest := 0.00;
          GPar.alpha := 0.20387;
          GPar.n_par := 1.23473;
          GPar.l_par := -3.339;
       end;
  Su3: begin
          GPar.b_sat := 0.3765;
          GPar.b_rest := 0;
          GPar.alpha := 0.08862;
          GPar.n_par := 1.21398;
          GPar.l_par := -3.611;
       end;
  Su4: begin
          GPar.b_sat := 0.3839;
          GPar.b_rest := 0;
          GPar.alpha := 0.06005;
          GPar.n_par := 1.22228;
          GPar.l_par := -3.738;
       end;
  Ls2: begin
          GPar.b_sat := 0.4148;
          GPar.b_rest := 0.1406;
          GPar.alpha := 0.04052;
          GPar.n_par := 1.32416;
          GPar.l_par := -2.067;
       end;
  Ls3: begin
          GPar.b_sat := 0.4091;
          GPar.b_rest := 0.07284;
          GPar.alpha := 0.06835;
          GPar.n_par := 1.20501;
          GPar.l_par := -3.226;
       end;
  Ls4: begin
          GPar.b_sat := 0.4129;
          GPar.b_rest := 0.0463;
          GPar.alpha := 0.09955;
          GPar.n_par := 1.18213;
          GPar.l_par := -3.604;
       end;
  Lt2: begin
          GPar.b_sat := 0.4380;
          GPar.b_rest := 0.1492;
          GPar.alpha := 0.07013;
          GPar.n_par := 1.24572;
          GPar.l_par := -3.18;
       end;
  Lt3: begin
          GPar.b_sat := 0.4530;
          GPar.b_rest := 0.1629;
          GPar.alpha := 0.04947;
          GPar.n_par := 1.17003;
          GPar.l_par := -4.099;
       end;
  Lts: begin
          GPar.b_sat := 0.4325;
          GPar.b_rest := 0.1154;
          GPar.alpha := 0.03401;
          GPar.n_par := 1.19442;
          GPar.l_par := 0.5;
       end;
  Lu: begin
          GPar.b_sat := 0.4284;
          GPar.b_rest := 0.0534;
          GPar.alpha := 0.04321;
          GPar.n_par := 1.16518;
          GPar.l_par := -3.227;
       end;
  Uu: begin
          GPar.b_sat := 0.4030;
          GPar.b_rest := 0;
          GPar.alpha := 0.01420;
          GPar.n_par := 1.21344;
          GPar.l_par := -0.56;
       end;
  Uls: begin
          GPar.b_sat := 0.4003;
          GPar.b_rest := 0;
          GPar.alpha := 0.02513;
          GPar.n_par := 1.19338;
          GPar.l_par := -4.032;
       end;
 Us: begin
          GPar.b_sat := 0.3946;
          GPar.b_rest := 0;
          GPar.alpha := 0.02747;
          GPar.n_par := 1.22393;
          GPar.l_par := -2.728;
       end;
  Ut2: begin
          GPar.b_sat := 0.4001;
          GPar.b_rest := 0.0101;
          GPar.alpha := 0.01868;
          GPar.n_par := 1.22068;
          GPar.l_par := -1.38;
       end;
  Ut3: begin
          GPar.b_sat := 0.4031;
          GPar.b_rest := 0.0053;
          GPar.alpha := 0.01679;
          GPar.n_par := 1.20668;
          GPar.l_par := -1.2;
       end;
  Ut4: begin
          GPar.b_sat := 0.4162;
          GPar.b_rest := 0.0276;
          GPar.alpha := 0.01697;
          GPar.n_par := 1.20483;
          GPar.l_par := -0.77;
       end;
  Tt: begin
          GPar.b_sat := 0.5238;
          GPar.b_rest := 0;
          GPar.alpha := 0.06612;
          GPar.n_par := 1.05215;
          GPar.l_par := 0.5;
       end;
  Tl: begin
          GPar.b_sat := 0.4931;
          GPar.b_rest := 0;
          GPar.alpha := 0.07339;
          GPar.n_par := 1.06254;
          GPar.l_par := 0.5;
       end;
  Tu2: begin
          GPar.b_sat := 0.4971;
          GPar.b_rest := 0;
          GPar.alpha := 0.07242;
          GPar.n_par := 1.06062;
          GPar.l_par := 0.5;
       end;
  Tu3: begin
          GPar.b_sat := 0.4589;
          GPar.b_rest := 0;
          GPar.alpha := 0.05500;
          GPar.n_par := 1.08166;
          GPar.l_par := 0.5;
       end;
  Tu4: begin
          GPar.b_sat := 0.4372;
          GPar.b_rest := 0.0170;
          GPar.alpha := 0.04538;
          GPar.n_par := 1.12039;
          GPar.l_par := 0.5;
       end;
  Ts2: begin
          GPar.b_sat := 0.4836;
          GPar.b_rest := 0;
          GPar.alpha := 0.08402;
          GPar.n_par := 1.07669;
          GPar.l_par := 0.5;
       end;
  Ts3: begin
          GPar.b_sat := 0.4374;
          GPar.b_rest := 0.07841;
          GPar.alpha := 0.06194;
          GPar.n_par := 1.14565;
          GPar.l_par := 0.5;
       end;
  Ts4: begin
          GPar.b_sat := 0.4355;
          GPar.b_rest := 0;
          GPar.alpha := 0.20919;
          GPar.n_par := 1.11419;
          GPar.l_par := -7.612;
       end;
  end; {of case}
end;

/// <summary>
/// function to set the satauration hydraulic conductivity from texture class and bulk density
/// </summary>
/// <param name="TC">Texture class</param>
/// <param name="ALD">Bulk density class</param>
/// <returns>Hydraulic conductivity in cm/d</returns>
function KSFromTextureClass_RR(TC: TTextureClass; ALD: TLD): real;

begin
  case ALD of
    OldVersion: // 1. Auflage
      case TC of
        Ss:
          result := 512.1;
        mS:
          result := 507.5;
        mSgs:
          result := 507.5;
        mSfs:
          result := 507.5;
        fS:
          result := 285.1;
        fSms:
          result := 285.1;
        Sl2:
          result := 192.9;
        Sl3:
          result := 89.9;
        Sl4:
          result := 141.3;
        Slu:
          result := 109.5;
        St2:
          result := 420.4;
        St3:
          result := 305.8;
        Su2:
          result := 285.5;
        Su3:
          result := 119.9;
        Su4:
          result := 83.3;
        Ls2:
          result := 38.4;
        Ls3:
          result := 98.2;
        Ls4:
          result := 169.9;
        Lt2:
          result := 62.5;
        Lt3:
          result := 44.3;
        Lts:
          result := 52;
        Lu:
          result := 82.7;
        Uu:
          result := 33.8;
        Uls:
          result := 40.2;
        Us:
          result := 35.5;
        Ut2:
          result := 29.3;
        Ut3:
          result := 27.7;
        Ut4:
          result := 24.6;
        Tt:
          result := 154.7;
        Tl:
          result := 172.5;
        Tu2:
          result := 178.7;
        Tu3:
          result := 123.8;
        Tu4:
          result := 88.6;
        Ts2:
          result := 249.862;
        Ts3:
          result := 118.038;
        Ts4:
          result := 322.257;
      else
        result := 50.0;
      end; { of case TC }
  end; { of case ALD }

  case ALD of
    LD13: // 1. Auflage
      case TC of
        { Trockenrohdichte 1.3 }
        Ss:
          result := 375;
        mS:
          result := 375;
        mSgs:
          result := 375;
        mSfs:
          result := 375;
        fS:
          result := 250;
        fSms:
          result := 250;
        Sl2:
          result := 160;
        Sl3:
          result := 100;
        Sl4:
          result := 80;
        Slu:
          result := 70;
        St2:
          result := 180;
        St3:
          result := 110;
        Su2:
          result := 185;
        Su3:
          result := 95;
        Su4:
          result := 85;
        Ls2:
          result := 50;
        Ls3:
          result := 60;
        Ls4:
          result := 70;
        Lt2:
          result := 40;
        Lt3:
          result := 20;
        Lts:
          result := 30;
        Lu:
          result := 35;
        Uu:
          result := 30;
        Uls:
          result := 35;
        Us:
          result := 30;
        Ut2:
          result := 30;
        Ut3:
          result := 30;
        Ut4:
          result := 30;
        Tt:
          result := 10;
        Tl:
          result := 20;
        Tu2:
          result := 18;
        Tu3:
          result := 20;
        Tu4:
          result := 25;
        Ts2:
          result := 30;
        Ts3:
          result := 35;
        Ts4:
          result := 50;
      else
        result := 20.0;
      end; { of case TC }
  end; { of case ALD }

  case ALD of
    LD142: // 1. Auflage
      case TC of
        Ss:
          result := 335;
        mS:
          result := 335;
        mSgs:
          result := 335;
        mSfs:
          result := 335;
        fS:
          result := 195;
        fSms:
          result := 195;
        Sl2:
          result := 130;
        Sl3:
          result := 85;
        Sl4:
          result := 78;
        Slu:
          result := 68;
        St2:
          result := 150;
        St3:
          result := 110;
        Su2:
          result := 140;
        Su3:
          result := 83;
        Su4:
          result := 75;
        Ls2:
          result := 52;
        Ls3:
          result := 57;
        Ls4:
          result := 70;
        Lt2:
          result := 56;
        Lt3:
          result := 30;
        Lts:
          result := 35;
        Lu:
          result := 35;
        Uu:
          result := 27;
        Uls:
          result := 35;
        Us:
          result := 27;
        Ut2:
          result := 35;
        Ut3:
          result := 35;
        Ut4:
          result := 35;
        Tt:
          result := 43;
        Tl:
          result := 43;
        Tu2:
          result := 43;
        Tu3:
          result := 43;
        Tu4:
          result := 43;
        Ts2:
          result := 47;
        Ts3:
          result := 47;
        Ts4:
          result := 62;
      else
        result := 20.0;

      end; { of case TC }
  end; { of case ALD }

  case ALD of
    LD15: // 1. Auflage
      case TC of
        { Trockenrohdichte 1.5 }
        Ss:
          result := 280;
        mS:
          result := 250;
        mSgs:
          result := 250;
        mSfs:
          result := 250;
        fS:
          result := 150;
        fSms:
          result := 150;
        Sl2:
          result := 100;
        Sl3:
          result := 70;
        Sl4:
          result := 50;
        Slu:
          result := 40;
        St2:
          result := 120;
        St3:
          result := 60;
        Su2:
          result := 125;
        Su3:
          result := 60;
        Su4:
          result := 55;
        Ls2:
          result := 30;
        Ls3:
          result := 35;
        Ls4:
          result := 40;
        Lt2:
          result := 25;
        Lt3:
          result := 10;
        Lts:
          result := 20;
        Lu:
          result := 20;
        Uu:
          result := 18;
        Uls:
          result := 20;
        Us:
          result := 15;
        Ut2:
          result := 15;
        Ut3:
          result := 15;
        Ut4:
          result := 12;
        Tt:
          result := 0.5;
        Tl:
          result := 3;
        Tu2:
          result := 5;
        Tu3:
          result := 5;
        Tu4:
          result := 5;
        Ts2:
          result := 15;
        Ts3:
          result := 20;
        Ts4:
          result := 30;
      else
        result := 20.0;

      end; { of case TC }
  end; { of case ALD }

  case ALD of
    LD164: // 1. Auflage
      case TC of
        { Trockenrohdichte 1.63-1.65 }
        Ss:
          result := 205;
        mS:
          result := 205;
        mSgs:
          result := 205;
        mSfs:
          result := 205;
        fS:
          result := 105;
        fSms:
          result := 105;
        Sl2:
          result := 95;
        Sl3:
          result := 53;
        Sl4:
          result := 44;
        Slu:
          result := 37;
        St2:
          result := 92;
        St3:
          result := 55;
        Su2:
          result := 75;
        Su3:
          result := 45;
        Su4:
          result := 43;
        Ls2:
          result := 30;
        Ls3:
          result := 34;
        Ls4:
          result := 45;
        Lt2:
          result := 38;
        Lt3:
          result := 15;
        Lts:
          result := 21;
        Lu:
          result := 21;
        Uu:
          result := 15;
        Uls:
          result := 19;
        Us:
          result := 12;
        Ut2:
          result := 17;
        Ut3:
          result := 17;
        Ut4:
          result := 18;
        Tt:
          result := 13;
        Tl:
          result := 13;
        Tu2:
          result := 13;
        Tu3:
          result := 13;
        Tu4:
          result := 13;
        Ts2:
          result := 25;
        Ts3:
          result := 25;
        Ts4:
          result := 30;
      else
        result := 20.0;

      end; { of case TC }
  end; { of case ALD }

  case ALD of
    LD17: // 1. Auflage
      case TC of
        { Trockenrohdichte 1.7 }
        Ss:
          result := 150;
        mS:
          result := 150;
        mSgs:
          result := 150;
        mSfs:
          result := 150;
        fS:
          result := 90;
        fSms:
          result := 90;
        Sl2:
          result := 50;
        Sl3:
          result := 40;
        Sl4:
          result := 30;
        Slu:
          result := 20;
        St2:
          result := 60;
        St3:
          result := 30;
        Su2:
          result := 65;
        Su3:
          result := 30;
        Su4:
          result := 30;
        Ls2:
          result := 15;
        Ls3:
          result := 20;
        Ls4:
          result := 25;
        Lt2:
          result := 10;
        Lt3:
          result := 3;
        Lts:
          result := 5;
        Lu:
          result := 8;
        Uu:
          result := 4;
        Uls:
          result := 7;
        Us:
          result := 5;
        Ut2:
          result := 3;
        Ut3:
          result := 3;
        Ut4:
          result := 2;
        Tt:
          result := 0.05;
        Tl:
          result := 0.5;
        Tu2:
          result := 0.5;
        Tu3:
          result := 0.5;
        Tu4:
          result := 1;
        Ts2:
          result := 5;
        Ts3:
          result := 8;
        Ts4:
          result := 10;
      else
        result := 20.0;

      end; { of case TC }
  end; { of case ALD }

end;



function KSFromTextureClass_KA(TC: TTextureClass): real;
{Bodenkundliche Kartieranleitung 5. Aufl. Tabelle 76,
 Trockenrohdichte 3}
begin
  case TC of
    Ss: result := 340;
    mS: result := 490;
    mSgs: result := 490;
    mSfs: result := 490;
    fS: result := 300;
    fSms: result := 300;
    Sl2: result := 98;
    Sl3: result := 65;
    Sl4: result := 42;
    Slu: result := 28;
    St2: result := 118;
    St3: result := 42;
    Su2: result := 127;
    Su3: result := 59;
    Su4: result := 38;
    Ls2: result := 23;
    Ls3: result := 23;
    Ls4: result := 36;
    Lt2: result := 13;
    Lt3: result := 7;
    Lts: result := 10;
    Lu: result := 16;
    Uu: result := 13;
    Uls: result := 20;
    Us: result := 22;
    Ut2: result := 12;
    Ut3: result := 12;
    Ut4: result := 13;
    Tt: result := 3;
    Tl: result := 6;
    Tu2: result := 3;
    Tu3: result := 9;
    Tu4: result := 12;
    else result := 50.0;
  end; {of case}
end;


function ClayFromTexture(TC: TTextureClass): real;
begin
  case TC of
    Ss,mS,mSgs,mSfs,fS,fSms, Su2: result := 0.025;
    Sl2: result := 0.065;
    Su3,Su4,Us,Uu: result := 0.04;
    Sl3,Ut2: result := 0.1;
    St2: result := 0.11;
    Slu,Uls: result := 0.125;
    Sl4,Ut3: result := 0.145;
    St3,Ls4,Ls3,Ls2,Ut4: result := 0.21;
    Lu: result := 0.235;
    Ts4,Lt2,Tu4: result := 0.3;
    Lts: result := 0.35;
    Tu3: result := 0.375;
    Ts3,Lt3: result := 0.4;
    Ts2,Tl,Tu2: result := 0.55;
    Tt: result := 0.825;
  end; {of case}
end;

end.
