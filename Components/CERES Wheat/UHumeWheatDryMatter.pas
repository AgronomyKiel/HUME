unit UHumeWheatDryMatter;

 (*
 simplified version of the dry matter production module for parameterisation
 ->'SWDF' is a none linear funktion of 'tranintsratio' according to (Ferreyra 2003)
 ->'PCARB' is limited by 'SWDF' or spezific leaf N
 ->(SLN threshold according to Meinke 1998)
 -> Wang-Engel (WE)	temperature (0-1) function
 -> Empirical approach for CO2 impact (2016)    Wo kommt der nur her?? keine Quellangabe
  ar
 *)
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
 // Options for drought impact
  TDroughtImpact = (DroughtImpact, NoDroughtImpact);
  
  
  TCarboRed = (CWT3, Concentration, noCarboRed);


/// <summary> Class for the dry matter production submodel of Ceres-Wheat
/// </summary>
/// <baseclass> TSubmodel </baseclass> </baseclass>
/// <created> 01.12.2008
/// <unit> HumeWheatDryMatter </unit>
/// <author> A. Ratjen, H. Kage, A. Luig </author>
/// <version> 0.7 </version>
/// <changes> 01.12.2008 (JH) </changes>

/// <remarks> simplified version of the dry matter production module for parameterisation
/// ->'SWDF' is a none linear funktion of 'tranintsratio' according to (Ferreyra 2003)
/// ->'PCARB' is limited by 'SWDF' or spezific leaf N
/// ->(SLN threshold according to Meinke 1998)
/// -> Wang-Engel (WE)	temperature (0-1) function
/// -> Empirical approach for CO2 impact (2016)    Wo kommt der nur her?? keine Quellangabe
/// </remarks>
/// <example>
/// </example>
/// <todo>
/// </todo>
/// <bug>
/// </bug>
/// <history>
/// </history>
/// <unit> HumeWheatDryMatter </unit>
/// <version> 1.0 </version>
/// <created> 01.12.2008 </created>
/// <modified> 01.12.2008 </modified>
/// <modifiedby> J. Hume </modifiedby>
/// <modifications> </modifications>
/// <unit> HumeWheatDryMatter </unit>
/// <version> 1.0 </version>
/// <created> 01.12.2008 </created>
/// <modified> 01.12.2008 </modified>
/// <modifiedby> J. Hume </modifiedby>
/// <modifications> </modifications>
/// <unit> HumeWheatDryMatter </unit>
/// <version> 1.0 </version>
/// <created> 01.12.2008 </created>
/// <modified> 01.12.2008 </modified>
/// <modifiedby> J. Hume </modifiedby>
/// <modifications




  THumeWheatDryMatter =  class(TSubmodel)

  private
    Procedure SetSoilWaterMod(SoilWaterMod: TSoilWaterModelR);
    procedure ReCalcDailyMeanTemperature;
    procedure CalcDroughtImpact;
  protected

  fSoilWaterModel : TSoilWaterModelR;
  fDroughtImpact : TDroughtImpact;

  function fT_WE(T,Tmin,Tmax,Topt: real): real;
  public
    CumPAR   : TState;     /// cumulative PAR uptake [MJ/m2]
    CumCarbo : TState;     /// cumulative assimilated production
//    int:         TPar;
//    pGAI:         TPar;    /// for scaling LAI->GAI after booting
    pSWDF:       TPAR;     /// parameter for none linear relation between Tansratio and SWDF (Ferreyra 2003)
    SLN_crit_int:  TPAR;
    SLN_crit_inc:  TPAR;
    SLNI_a:  TPAR;
    SLNI_b:  TPAR;
    SLNI_c:  TPAR;
    k_ini:       TPar;
    k_inc:       TPar; // decrease per LAI unit
    pLUE   : TPar;   // light use efficiency assuming constant LUE
    Tmin : TPar;    // minimum temperature for assimilation
    Topt1 : Tpar;   // temperature where optimum range for assimilation begins
    Topt2 : TPar;   // temperature where optimum range for assimilation ends
    Topt_WE: TPar;  // temperature where optimum of WE-function
    Tmax : Tpar;    // minimum temperature for assimilation
    kPAR : TPar;   // Extinction coefficient for PAR
    fCO2_scale     : TPar;
    fCO2           : TPar;
    fCWSI          : TPar;  /// adjusting CO2-effect for drought stress level
    CiCompensation : TPar;
    critTempDiff   : TPar;  /// critical difference between max. and min. temp. for calculating Tmean
    TmaxweightingF : TPar;  ///

    CARBOred: TVar;    /// Reduction factor for assimilation during ripening [0..1]
    PAR       : TVar;   /// Photosynthetic active radiation [MJ/(m2*d]
    kPar_eff  : TVar;   /// effective  Extinction coefficient
    fINT      : TVar;   /// fractional Interception of PAR
    SWDF     : TVar;   /// Soil Water Deficit Factor [0..1]
    SLNI      : TVar;   /// SLN based N nutrition index (see Raten & Kage 2015)
    TempF     : TVar;   /// Temperature Factor
    Tempf_surface     : TVar;   /// Temperature Factor

    CARBO     : TVar;   /// The daily biomass production [g/(plant*d)]
    PCARB     : TVar;   /// Potential biomass production in [g/(m2*d)]
    LUE       : TVar;   /// Light use efficiency [g/MJ]
    SLN_crit:    TVar; /// according to Ratjen & Kage 2015
    CO2_factor :TVar;  /// factor for adjusting LUE for CO2-effect
    IPAR      : TVar;   /// intercepted photosynthetically active radiation [MJ/(m2*d)]
    EC:      TExternV;
    Ncleaf:      TExternV;   /// actual nitrogen concentration of the leaf fraction [%]
    SLN:         TExternV;   /// actual area related nitrogen concentration of the leaf fraction [g/m2]
    GAI:         TExternV;   /// green area index [m2/m2]
    TMPM   : TExternV;       /// mean daily temperature [°C]
    TMPMX   : TExternV;      /// maximum daily temperature [°C]
    TMPMN   : TExternV;      /// miniimum daily temperature [°C]
    DryMatterTemp:  TExternV;    /// 'weighted surface temp.'
    LAI     : TExternV;   ///   leaf area index
    GlobRad : TExternV;   ///   global radiation [MJ/m2/d]
    Plants  : TExternV;   ///        number of Plants/m2 [1/m²]
    TransIntRatio:  TExternV;  /// ratio of actual to potential transpiration+interception
    CO2pp:    TExternV;        /// external atmospheric CO2-concentration
    optSLN: TExternV;          ///  optimum specific leaf nitrogen concentration
    SUMGRHI: real;
    k_ : real; // intermediate value for technical reason
    SUMTEMPHI: real;


    OptDroughtimpact : Toption;
    OptWithCO2: TOption;
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

    property opt_DroughtImpact : TDroughtImpact read fDroughtImpact write fDroughtImpact;
    property SoilWaterModel : TSoilWaterModelR read fSoilWaterModel write SetSoilWaterMod;

  end;  // SubmodelName

procedure Register;

implementation

uses Math, UModUtils;


function THumeWheatDryMatter.fT_WE(T,Tmin,Tmax,Topt: real): real;
{
 Wang-Engel	 (WE)	 temperature	 function (0-1)	 constructs	 a	 curvilinear
 response	 based	 on	 the	base,
 optimum,	and	 maximum	 temperatures	 of	 the	 simulated	 process.
}
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


  OptCreate('optDroughtimpact', 'DroughtImpact', optDroughtimpact);
	optDroughtimpact.OptionList.Clear;
  optDroughtimpact.OptionList.Add('DroughtImpact');
  optDroughtimpact.OptionList.Add('NoDroughtImpact');



  OptCreate('optCO2', 'NoCO2Effect', OptWithCO2);
  OptWithCO2.OptionList.Clear;
  OptWithCO2.OptionList.Add('NoCO2Effect');
  OptWithCO2.OptionList.Add('WithCO2Effect');


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
  if OptWithCO2.option = 'withco2effect' then
    CO2pp.Search := true
    else
    CO2pp.Search := false;


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
    CarboRed.v := min(1, max(0, SLNI_a.v+ SLNI_b.v*SLNI.v+ SLNI_c.v*power(SLNI.v,2)));

    if ipar.v > 0 then
    begin
     //Tempf.v := trapez_f(tmpm.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
 // calculation of the temperature effect according to the Wang-Engel equation
     Tempf.v := fT_WE(tmpm.v,Tmin.v,Tmax.v,Topt_WE.v);
 // in case the 
     if(tmpm.v < DryMatterTemp.v) then begin
      Tempf_surface.v := fT_WE(DryMatterTemp.v,Tmin.v,Tmax.v,Topt_WE.v);
      PCARB.v := pLUE.v * PAR.v * fint.v * min(Tempf.v,Tempf_surface.v);
     end
      else
      PCARB.v := pLUE.v * PAR.v * fint.v * Tempf.v;
// Impact of CO2
     if OptWithCO2.option = 'withco2effect' then begin
       // under drought stress the CO2 effect is increased, described by a linear function of CWSI
       CWSI := 1 - TransIntRatio.v;  //
       CO2_factor_min := (fCO2_scale.v+CWSI*fCWSI.v);
       if(CO2pp.v > CiCompensation.v) then
        CO2_factor.v := max(CO2_factor_min, CO2_factor_min*power((CO2pp.v-CiCompensation.v), fCO2.v))
       else
        CO2_factor.v := CO2_factor_min;

        PCARB.v :=PCARB.v *CO2_factor.v;
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
    SWDF.v := 1 - power((1 - TransIntRatio.v), pSWDF.v);
  end
  else
    //  (Ferreyra 2003)
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

