/// <summary>
/// Provides the dry-matter production submodel for CERES-Wheat.
/// </summary>
/// <remarks>
/// This simplified module supports parameterisation. The soil-water deficit factor
/// is a nonlinear function of the transpiration ratio (Ferreyra 2003), and potential
/// biomass production is limited by soil-water availability or specific leaf nitrogen.
/// Temperature effects use the Wang-Engel response function. The module also includes
/// an empirical representation of the atmospheric CO2 effect.
/// </remarks>
unit UHumeWheatDryMatter;

interface

uses
    {$IFNDEF NONVISUAL}
    windows,
    Messages,
    vcl.Graphics,
    vcl.Controls,
    vcl.Forms,
    vcl.Dialogs,
    {$ENDIF}
    SysUtils,
    Classes,
    UMod,
    UState,
  URootedSoil;

type
  /// <summary>Specifies whether drought affects dry-matter production.</summary>
  TDroughtImpact = (DroughtImpact, NoDroughtImpact);

  /// <summary>Specifies how assimilation is reduced during ripening.</summary>
  TCarboRed = (CWT3, Concentration, noCarboRed);

  /// <summary>Specifies the function used to calculate the temperature effect.</summary>
  TCalcTempEffect = (WangEngel, Tranpzoidal);

  /// <summary>
  /// Implements the dry-matter production submodel for CERES-Wheat.
  /// </summary>
  /// <remarks>
  /// The submodel calculates intercepted radiation, temperature, water and nitrogen
  /// effects, and the resulting daily biomass production.
  /// </remarks>
  THumeWheatDryMatter =  class(TSubmodel)

  private
    /// <summary>Assigns the soil-water model used to calculate drought effects.</summary>
    /// <param name="SoilWaterMod">The soil-water model to associate with this submodel.</param>
    Procedure SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);
    /// <summary>Recalculates mean daily temperature from the daily minimum and maximum.</summary>
    procedure ReCalcDailyMeanTemperature;
    /// <summary>Calculates the effect of drought on dry-matter production.</summary>
    procedure CalcDroughtImpact;
  protected

    /// <summary>References the soil-water model used by this submodel.</summary>
    fSoilWaterModel : TSoilWaterModelR;

    /// <summary>Stores the selected drought-impact option.</summary>
    fDroughtImpact : TDroughtImpact;

    /// <summary>Indicates whether nitrogen availability affects assimilation.</summary>
    fNImpact : boolean;

    /// <summary>Stores the selected temperature-effect calculation method.</summary>
    fCalcTempEffect : TCalcTempEffect;

    /// <summary>Calculates the Wang-Engel temperature response.</summary>
    /// <param name="T">The temperature for which the response is calculated.</param>
    /// <param name="Tmin">The lower temperature threshold.</param>
    /// <param name="Tmax">The upper temperature threshold.</param>
    /// <param name="Topt">The optimum temperature.</param>
    /// <returns>A dimensionless temperature-response factor in the range 0..1.</returns>
    function fT_WE(T,Tmin,Tmax,Topt: real): real;
  public

    /// <summary>Cumulative intercepted photosynthetically active radiation [MJ/m2].</summary>
    CumPAR   : TState;
    /// <summary>Cumulative assimilated dry matter [g/m2].</summary>
    CumCarbo : TState;

    /// <summary>Controls the nonlinear relationship between transpiration ratio and SWDF (Ferreyra 2003).</summary>
    pSWDF:       TPAR;

    /// <summary>Intercept of the critical-SLN function (Ratjen &amp; Kage 2015).</summary>
    SLN_crit_int:  TPAR;

    /// <summary>Slope of the critical-SLN function (Ratjen &amp; Kage 2015).</summary>
    SLN_crit_inc:  TPAR;

    /// <summary>Constant coefficient of the SLN-index response.</summary>
    SLNI_a:  TPAR;

    /// <summary>Linear coefficient of the SLN-index response.</summary>
    SLNI_b:  TPAR;

    /// <summary>Quadratic coefficient of the SLN-index response.</summary>
    SLNI_c:  TPAR;

    /// <summary>Initial PAR extinction coefficient, which decreases as LAI increases.</summary>
    k_ini:       TPar;

    /// <summary>Decrease in the PAR extinction coefficient per unit of LAI.</summary>
    k_inc:       TPar;

    /// <summary>Potential light-use efficiency assuming a constant LUE.</summary>
    pLUE   : TPar;

    /// <summary>Minimum temperature for assimilation.</summary>
    Tmin : TPar;

    /// <summary>Temperature at which the optimum assimilation range begins.</summary>
    Topt1 : Tpar;

    /// <summary>Temperature at which the optimum assimilation range ends.</summary>
    Topt2 : TPar;

    /// <summary>Optimum temperature of the Wang-Engel response function.</summary>
    Topt_WE: TPar;

    /// <summary>Maximum temperature for assimilation.</summary>
    Tmax : Tpar;

    /// <summary>PAR extinction coefficient.</summary>
    kPAR : TPar;
    /// <summary>Baseline scaling parameter for the atmospheric CO2 effect.</summary>
    fCO2_scale     : TPar;
    /// <summary>Exponent used to calculate the atmospheric CO2 effect.</summary>
    fCO2           : TPar;
    /// <summary>Adjusts the atmospheric CO2 effect according to drought stress.</summary>
    fCWSI          : TPar;
    /// <summary>CO2 concentration at which photosynthesis is not limited by CO2 [ppm].</summary>
    CiCompensation : TPar;
    /// <summary>Critical daily temperature range for recalculating mean temperature [°C].</summary>
    critTempDiff   : TPar;
    /// <summary>Weight assigned to maximum temperature when the critical daily range is exceeded.</summary>
    TmaxweightingF : TPar;

    /// <summary>Assimilation reduction factor during ripening [0..1].</summary>
    CARBOred: TVar;
    /// <summary>Photosynthetically active radiation [MJ/(m2*d)].</summary>
    PAR       : TVar;
    /// <summary>Effective PAR extinction coefficient.</summary>
    kPar_eff  : TVar;
    /// <summary>Fraction of PAR intercepted by the canopy.</summary>
    fINT      : TVar;
    /// <summary>Soil-water deficit factor [0..1].</summary>
    SWDF     : TVar;
    /// <summary>Specific-leaf-nitrogen nutrition index (Ratjen &amp; Kage 2015).</summary>
    SLNI      : TVar;
    /// <summary>Temperature factor calculated from mean daily temperature.</summary>
    TempF     : TVar;
    /// <summary>Temperature factor calculated from the weighted surface temperature.</summary>
    Tempf_surface     : TVar;

    /// <summary>Daily biomass production [g/(plant*d)].</summary>
    CARBO     : TVar;
    /// <summary>Potential daily biomass production [g/(m2*d)].</summary>
    PCARB     : TVar;
    /// <summary>Light-use efficiency [g/MJ].</summary>
    LUE       : TVar;
    /// <summary>Critical specific leaf nitrogen concentration (Ratjen &amp; Kage 2015).</summary>
    SLN_crit:    TVar;
    /// <summary>Factor that adjusts light-use efficiency for atmospheric CO2.</summary>
    CO2_factor :TVar;
    /// <summary>Intercepted photosynthetically active radiation [MJ/(m2*d)].</summary>
    IPAR      : TVar;
    /// <summary>External EC or BBCH development stage.</summary>
    EC:      TExternV;
    /// <summary>Actual nitrogen concentration of the leaf fraction [%].</summary>
    Ncleaf:      TExternV;
    /// <summary>Actual area-based nitrogen concentration of the leaf fraction [g/m2].</summary>
    SLN:         TExternV;
    /// <summary>Green area index [m2/m2].</summary>
    GAI:         TExternV;
    /// <summary>Mean daily temperature [°C].</summary>
    TMPM   : TExternV;
    /// <summary>Maximum daily temperature [°C].</summary>
    TMPMX   : TExternV;
    /// <summary>Minimum daily temperature [°C].</summary>
    TMPMN   : TExternV;
    /// <summary>Weighted surface temperature used by the dry-matter submodel [°C].</summary>
    DryMatterTemp:  TExternV;
    /// <summary>Leaf area index [m2/m2].</summary>
    LAI     : TExternV;
    /// <summary>Global radiation [MJ/(m2*d)].</summary>
    GlobRad : TExternV;
    /// <summary>Plant density [plants/m2].</summary>
    Plants  : TExternV;
    /// <summary>Ratio of actual to potential transpiration plus interception.</summary>
    TransIntRatio:  TExternV;
    /// <summary>Atmospheric CO2 concentration [ppm].</summary>
    CO2pp:    TExternV;
    /// <summary>Optimum specific leaf nitrogen concentration.</summary>
    optSLN: TExternV;
    /// <summary>Minimum stem weight used to calculate translocation and senescence.</summary>
    SWMIN_pl : TExternV;
    /// <summary>Stem weight per plant.</summary>
    STMWT_pl : TExternV;
    /// <summary>Temperature sum accumulated from the beginning of stage 5.</summary>
    SUMDTT5 : TExternV;
    /// <summary>CERES-Wheat development parameter for stage 5.</summary>
    P5 : TExternV;
    SUMGRHI: real;
    /// <summary>Intermediate value used in the PAR extinction calculation.</summary>
    k_ : real;
    SUMTEMPHI: real;


    OptDroughtimpact : Toption;
    OptNimpact: TOption;
    OptWithCO2: TOption;
    /// <summary>Selects the temperature-response function used for assimilation.</summary>
    OptCalcTempEffect: TOption;
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    Property Ex_TMPM   : TExternV read TMPM write TMPM;
    Property Ex_EC   : TExternV read EC write EC;
    property Ex_TransIntRatio: TExternV Read TransIntRatio Write TransIntRatio;
    property Ex_CO2pp: TExternV Read CO2pp Write CO2pp;
    property Ex_Ncleaf: TExternV Read Ncleaf Write Ncleaf;
    property Ex_SLN: TExternV Read SLN Write SLN;
    property Ex_GAI: TExternV Read GAI Write GAI;
    property Ex_Plants: TExternV read Plants write Plants;
    property Ex_DryMatterTemp: TExternV read DryMatterTemp write DryMatterTemp;
    property Ex_LAI: TExternV read LAI write LAI;
    property Ex_GlobRad: TExternV read GlobRad write GlobRad;
    property Ex_TMPMX: TExternV read  TMPMX write  TMPMX;
    property Ex_TMPMN: TExternV read  TMPMN write  TMPMN;
    property Ex_optSLN: TExternV read  optSLN write  optSLN;
    property Ex_SWMIN_pl : TExternV read SWMIN_pl write SWMIN_pl;
    property Ex_STMWT_pl : TExternV read STMWT_pl write STMWT_pl;
    property Ex_SUMDTT5 : TExternV read SUMDTT5 write SUMDTT5;
    property Ex_P5 : TExternV read P5 write P5;

    property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;
    property SoilWaterModel : TSoilWaterModelR read fSoilWaterModel write SetSoilWaterMod;

  end;

procedure Register;

implementation

uses Math, UModUtils;

/// <summary>Calculates the Wang-Engel temperature response.</summary>
/// <param name="T">The temperature for which the response is calculated.</param>
/// <param name="Tmin">The lower temperature threshold.</param>
/// <param name="Tmax">The upper temperature threshold.</param>
/// <param name="Topt">The optimum temperature.</param>
function THumeWheatDryMatter.fT_WE(T,Tmin,Tmax,Topt: real): real;
  var
  alpha: real;
  begin
   if(T >= Tmin) and (T <= Tmax) then begin
    alpha:= Ln(2)/ln(((Tmax-Tmin)/(Topt-Tmin)));
     fT_WE:=(2*power((T-Tmin),alpha)*
      power((Topt-Tmin),alpha)-power((T-Tmin),(2*alpha)))/
          power((Topt-Tmin),(2*alpha));
    end else
     fT_WE:=0;
end;

Procedure THumeWheatDryMatter.SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);

begin
  fSoilWaterModel := SoilWaterMod;
end;

procedure THumeWheatDryMatter.createAll;
begin
  inherited createAll;
  StateCreate('CumPAR', '[MJ/m2]', 0, true, CumPAR, 'cumulative PAR uptake');
  StateCreate('CumCarbo', '[g/m2]', 0, true, CumCarbo, 'cumulative assimilated production ');
  ParCreate('pSWDF', '[-]', 1, pSWDF,
    'parameter for none linear relation between Tansratio and SWDF (Ferreyra 2003), default = 1, values > 1 decrease the effect of drought stress on SWDF');
  //ParCreate('SLN_crit', '[-]', 2, SLN_crit);
  ParCreate('SLN_crit_int', '[-]',   3.74,  SLN_crit_int, 'intercept of the linear function for calculation of critical SLN, see Ratjen & Kage 2015');
  ParCreate('SLN_crit_inc', '[-]', -0.228,  SLN_crit_inc, 'slope of the linear function for calculation of critical SLN, see Ratjen & Kage 2015');
  ParCreate('SLNI_a', '[-]', -0.197,  SLNI_a);
  ParCreate('SLNI_b', '[-]',   2.80,  SLNI_b);
  ParCreate('SLNI_c', '[-]',  -1.60,  SLNI_c);
  ParCreate('kPAR', '[-]',0.7, kPAR, 'standard extinction coefficient for PAR radiation');
  ParCreate('k_ini', '[-]',0.75, k_ini, 'initial extinction coefficient, which decreases with increasing LAI');
//  ParCreate('pGAI', '[-]',0.2,  pGAI);
  ParCreate('k_inc', '[-]', -0.06, k_inc, 'decrease of extinction coefficient per ln LAI unit');
  ParCreate('Tmin', '[°C]',  0.0, Tmin, 'minimum temperature for assimilation');
  ParCreate('Topt1', '[°C]',  10.0, Topt1, 'start of optimum temperature range for assimilation');
  ParCreate('Topt2', '[°C]',  20.0, Topt2, 'end of optimum temperature range for assimilation');
  ParCreate('Topt_WE', '[°C]',  20.0, Topt_WE, 'temperature where optimum (value of 1) of WE-function is reached');
  ParCreate('Tmax', '[°C]',  35.0, Tmax, 'maximum temperature for assimilation');
  ParCreate('pLUE', '[g/MJ]',   3.1,  pLUE, 'potential light use efficiency');
  ParCreate('fCO2', '[-]',   0.086,  fCO2, 'parameter for calculation of CO2 effect');
  ParCreate('fCO2_scale', '[-]',   0.723,  fCO2_scale, 'parameter for calculation of CO2 effect');
  ParCreate('fCWSI', '[-]',   0.077,  fCWSI, 'parameter adjusting CO2-effect for drought stress level');
  ParCreate('CiCompensation', '[ppm]',   350,  CiCompensation, 'CO2 concentration where photosynthesis is not limited by CO2');
  ParCreate('critTempDiff', '[°C]', 8,  critTempDiff,'critical temperature between min and max, if difference is too high, max temperature is weighted higher' );
  ParCreate('TmaxweightingF', '[°C]', 0.567,  TmaxweightingF,'If difference between min and max temperature is high, the maximum temperature is weighted stronger according to CeresWheat 2.0' );


  VarCreate('SLN_crit', '[-]', 0, True, SLN_crit,'actual critical SLN, see Ratjen & Kage 2015');
  VarCreate('CARBOred', '[0..1]', 0, True, CARBOred, 'reduction factor for daily assimilation due to N limitation and senescence');
  VarCreate('PAR', '[MJ/(m2*d]',0, true, PAR, 'PAR radiation (0.5*Globalradiation)');
  VarCreate('SLNI', '[-]',0, true, SLNI, 'SLN based N nutrition index (see Raten & Kage 2015)');
  VarCreate('SWDF', '[0..1]',1, true, SWDF, 'soil water deficit factor, potentially nonlinear reacting to TransIntRatio');
  VarCreate('kPar_eff', '[0..1]',0, true, kPar_eff, 'effective extinction coefficient');
  VarCreate('fINT', '[0..1]',0, true, fINT, 'fractional light interception PAR');
  VarCreate('IPAR', '[MJ/(m2*d)]',0, true, IPAR, 'intercepted photosynthetically active radiation');
  VarCreate('Temp_f', '[0..1]',0, true, Tempf, 'Variable for temperature effect');
  VarCreate('Tempf_surface', '[0..1]',0, true, Tempf_surface, 'Variable for temperature effect');
  VarCreate('CARBO', '[g/(plant*d)]',0, true, CARBO, 'Daily biomass production per plant');
  VarCreate('PCARB', '[g/(m2*d)]',0, true, PCARB, 'Daily biomass production of the canopy');
  VarCreate('LUE', '[g/MJ]',0, true, LUE, 'light use efficiency');
  VarCreate('CO2_factor', '[-]',0, true,  CO2_factor, 'Factor for CO2 effect');
  ExternVCreate('GAI', '[-]', statefield, GAI, 'Green area index');
  ExternVCreate('SLN', '[g/m2]', statefield, SLN, 'External specific leaf nitrogen concentration');
  ExternVCreate('NcLeaf', '[%]', statefield, NcLeaf, 'External actual nitrogen concentration of the leaf fraction');
  ExternVCreate('TMPM', '', statefield, TMPM,   'mean daily temperature');
  ExternVCreate('DryMatterTemp',  '[°C]', statefield, DryMatterTemp, 'weighted surface temp.');
  ExternVCreate('EC', '', statefield, EC, 'EC or BBCH stage');
  ExternVCreate('GlobRad', '', statefield, GlobRad, 'Global radiation');
  ExternVCreate('TransIntRatio', '[-]', statefield, TransIntRatio, 'ratio of actual to potential transpiration+interception');
  ExternVCreate('LAI',  '', statefield, LAI,  'Leaf area index');
  ExternVCreate('Plants', '', statefield, Plants, 'number of plants per square meter');
  ExternVCreate('CO2pp','[ppm]',statefield,CO2pp, 'external atmospheric CO2-concentration');
  ExternVCreate('optSLN', '[g/m2]', Statefield, optSLN,   'optimum specific leaf nitrogen concentration');
  ExternVCreate('TMPMX', '[°C]', Statefield, TMPMX, 'maximum daily temperature');
  ExternVCreate('TMPMN', '[°C]', Statefield, TMPMN,   'minimum daily temperature');

  ExternVCreate('SWMIN_pl', '[g/pl]', Statefield, SWMIN_pl,   'minimum stem weight at stage 37, used for calculation of senescence');
  ExternVCreate('STMWT_pl', '[g/pl]', Statefield, STMWT_pl,   'weight per plant');
  ExternVCreate('SUMDTT5', '[°Cd]', Statefield, SUMDTT5,   'temperature sum from stage 5 on');
  ExternVCreate('P5', '[-]', Statefield, P5,   'Development paramter for stage 5 of CERES Wheat');

  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
	optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');

  OptCreate('optNimpact', 'NoNImpact', OptNimpact);
	OptNimpact.OptionList.Clear;
	OptNimpact.OptionList.Add('NImpact');
	OptNimpact.OptionList.Add('NoNImpact');

  OptCreate('optCO2', 'NoCO2Effect', OptWithCO2);
  OptWithCO2.OptionList.Clear;
  OptWithCO2.OptionList.Add('NoCO2Effect');
  OptWithCO2.OptionList.Add('WithCO2Effect');

  OptCreate('OptCalcTempEffect', 'WangEngel', OptCalcTempEffect,
    'Selects the function used to calculate the temperature effect on assimilation');
  OptCalcTempEffect.OptionList.Clear;
  OptCalcTempEffect.OptionList.Add('WangEngel');
  OptCalcTempEffect.OptionList.Add('Tranpzoidal');
end;


procedure THumeWheatDryMatter.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  k_:=999;

  // initialisation of the drought impact
  if optDroughtimpact.option = 'droughtimpact' then begin
    fdroughtimpact := DroughtImpact;
    TransIntratio.Search := true;
  end;
  if optDroughtimpact.option = 'nodroughtimpact' then begin
    fdroughtimpact := noDroughtImpact;
    TransIntratio.Search := false;
  end;

  if OptNimpact.option = 'NImpact' then begin
    fNImpact := true;
    Ex_Ncleaf.Search := true;

  end else begin
    fNImpact := false;
    Ex_Ncleaf.Search := false;

  end;

  if OptWithCO2.option = 'withco2effect' then
    CO2pp.Search := true
    else
    CO2pp.Search := false;

  if SameText(OptCalcTempEffect.Option, 'Tranpzoidal') then
    fCalcTempEffect := Tranpzoidal
  else
    fCalcTempEffect := WangEngel;

end;


procedure THumeWheatDryMatter.CalcRates;
  var
  CWSI,
  CO2_factor_min :real;

  begin
  // if difference between min and max temperature is high
  // max temperature has to be weighted stronger
  // according to CeresWheat 2.0
  ReCalcDailyMeanTemperature;

// calculation of radiation interception
// PAR radiation is 50% of global radiation
  PAR.v  := 0.5 * GlobRad.v;

 // calculation of effective extinction coefficient
 // which is a function of LAI, i.e. decreasing with increasing LAI 
  if(LAI.v>0) then begin
    if(k_ > k_ini.v+ln(LAI.v)*k_inc.v) then begin
       kpar_eff.v := min(0.9,max(k_ini.v+ln(LAI.v)*k_inc.v,kPAR.v));
//       k_:= kpar_eff.v;
    end;
  end
  else
   kpar_eff.v := kPAR.v;
  // fractional PAR interception
  fInt.v := (1 - EXP(-kPAR_eff.v * LAI.v));
  
  // calculation of intercepted PAR
  IPAR.v := PAR.v * fint.v;
  // calculation of rate of change of cumulative PAR
  CumPAR.c := IPAR.v;
// calculation drought impact
  CalcDroughtImpact;

  // calculation of SLN_crit as a function of GAI
  SLN_crit.v:= SLN_crit_int.v+SLN_crit_inc.v*GAI.v;
  // before booting SLN_crit is always lower than optSLN
  if(optSLN.v>0) and (EC.v<30) then    // SLN_crit during autumn as a function of
    SLN_crit.v:=min(SLN_crit.v, optSLN.v); // N-dilution

// calculation of SLN based N nutrition index
    SLNI.v:= min(1, SLN.v / SLN_crit.v);
// CarboRed is in CERES Wheat the variable for the reduction of assimilation during ripening
// it is now used for the reduction of assimilation due to low SLN as well
    if fNimpact then
      CarboRed.v := min(1, max(0, SLNI_a.v+ SLNI_b.v*SLNI.v+ SLNI_c.v*power(SLNI.v,2)))
    else begin
      if EC.v >= 62 then
//       CarboRed.v := 1.0//  max(0,(1.-(1.2-0.8*SWMIN_pl.v/stmwt_pl.v)*(sumdtt5.v+100.0)/((430+ p5.v*20)+100.0)))
       CarboRed.v :=  max(0,(1.-(1.2-0.8*SWMIN_pl.v/stmwt_pl.v)*(sumdtt5.v+100.0)/((430+ p5.v*20)+100.0)))
      else
        CarboRed.v := 1.0;
    end;

    if ipar.v > 0 then
    begin
      case fCalcTempEffect of
        WangEngel:
          begin
            Tempf.v := fT_WE(TMPM.v, Tmin.v, Tmax.v, Topt_WE.v);
            if TMPM.v < DryMatterTemp.v then
              Tempf_surface.v := fT_WE(DryMatterTemp.v, Tmin.v, Tmax.v, Topt_WE.v);
          end;
        Tranpzoidal:
          begin
            Tempf.v := trapez_f(TMPM.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
            if TMPM.v < DryMatterTemp.v then
              Tempf_surface.v := trapez_f(DryMatterTemp.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
          end;
      end;

      if TMPM.v < DryMatterTemp.v then
        PCARB.v := pLUE.v * PAR.v * fINT.v * Min(Tempf.v, Tempf_surface.v)
      else
        PCARB.v := pLUE.v * PAR.v * fINT.v * Tempf.v;
// Impact of CO2
     if OptWithCO2.option = 'withco2effect' then begin
       // under drought stress the CO2 effect is increased, described by a linear function of CWSI
       CWSI := 1 - TransIntRatio.v;  //
       CO2_factor_min := (fCO2_scale.v+CWSI*fCWSI.v);
       if(CO2pp.v > CiCompensation.v) then
        CO2_factor.v := max(CO2_factor_min, CO2_factor_min*power((CO2pp.v-CiCompensation.v), fCO2.v))
       else
        CO2_factor.v := CO2_factor_min;

        PCARB.v :=PCARB.v * CO2_factor.v;
     end;  // CO2 end

    end
    else
      PCARB.v := 0;

  PCARB.v := PCARB.v * min(SWDF.v, Carbored.v);  // soil water deficit factor correction
  if Plants.v > 0 then
    CARBO.v := PCARB.v / Plants.v;

  cumCarbo.c := PCARB.v;



end;

procedure THumeWheatDryMatter.Integrate;

begin
  inherited integrate;
   If  IPAR.v>0 then
     LUE.v :=   PCARB.v/IPAR.v
   else  LUE.v :=   0;

end;

procedure THumeWheatDryMatter.CalcDroughtImpact;
begin
  if (SoilWaterModel <> nil) and (fDroughtImpact = DroughtImpact) then
  begin
    //  (Ferreyra 2003)
    SWDF.v := 1 - power((1 - TransIntRatio.v), pSWDF.v);
  end
  else
    SWDF.v := 1;
end;

procedure THumeWheatDryMatter.ReCalcDailyMeanTemperature;
begin
  // if difference between min and max temperature is high
  // max temperature has to be weighted stronger
  if ((TMPMX.v - TMPMN.v) > critTempDiff.v) and (tmpm.v > 0) then
    tmpm.v := TMPMX.v * TmaxweightingF.v + TMPMN.v * (1 - TmaxweightingF.v);
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Ceres Wheat', [THumeWheatDryMatter]);
{$ENDIF}
end;

end.

