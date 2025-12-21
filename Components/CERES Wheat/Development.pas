/// <summary>
/// This unit defines the TDevelopment class, a core component of the HUME-Wheat crop model, responsible for simulating the phenological development (growth stages) of wheat. 
/// The class models the progression of the crop through its life cycle, from sowing and emergence to maturity and harvest, using temperature, daylength, and genetic parameters.
/// 
/// **Key features:**
/// - **Growth Stage Tracking: Extends the XSTAGE stages of Ceres Wheat with EC, BBCH stages scales to represent crop development.
/// - **Development Rates: Calculates stage-specific development rates, including the effects of temperature (thermal time), photoperiod (daylength), and vernalization (cold exposure).
/// - **Leaf Appearance and Initiation: Simulates the initiation and appearance of leaves on the main stem, using phyllochron and plastochron intervals.
/// - **Modular Design: Integrates with other model components via external variables and options.
///
///   **Phenological stages in integer values and corresponding BBCH stages:**
/// 1 **Emergence to terminal spikelet(TS), BBCH 10-30
/// 2 **TS to end of vegetative growth, BBCH 30-39
/// 3 **End of vegetative growth and beginning ear growth to end of pre-anthesis ear growth, BBCH 40-57
/// 4 **End of pre-anthesis ear growth to beginning of grain filling (anthesis occurs during this phase), BBCH 57-71
/// 5 **Beginning of grain filling to physiological maturity, BBCH 71-90
/// 6 **Physiological maturity to fallow (harvest), BBCH 90-99
/// 7 **Fallow to sowing
/// 8 **Sowing to germination
/// 9 **Germination to emergence
///
/// **Typical usage:**
/// This module is used to drive the timing of crop processes (e.g., leaf growth, flowering, grain filling) in response to weather and management, providing the developmental framework for the rest of the crop model.
/// </summary>

{@author(Ulf Boettcher <boettcher@pflanzenbau.uni-kiel.de>)}

unit Development; 

{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}
{$IFDEF CONSOLE}
{$DEFINE NONVISUAL}
{$ENDIF CONSOLE}

interface  

uses 
  SysUtils, Classes,
  UMod, UState,
  UMeasValue,          
  Math;

type   

/// <summary>
/// Enumeration for data initialization methods in the TDevelopment class.
/// This enumeration defines how the development data is initialized, either from measured dates or calculated values.
/// - EC_Date: Uses measured dates for specific growth stages (e.g., EC25, EC30, EC37).
/// - Days_to_EC: Uses a calculated approach based on days to reach specific growth stages.
/// </summary>
  TDataInitMethod = (EC_Date, Days_to_EC);

/// <summary>
/// Enumeration for options related to Phyllochron/TSumIndernode calculation.
/// </summary>
  TOptTSumInternode = (constant, daylength);

/// <summary>
/// Development class, a core component of the HUME-Wheat crop model, responsible for simulating the phenological development (growth stages) of wheat. The class models the progression of the crop through its life cycle, from sowing and emergence to maturity and harvest, using temperature, daylength, and genetic parameters.
/// 
/// Key features:
/// - Growth Stage Tracking: Uses both integer (EC, BBCH, Zadoks) and continuous (xstage) scales to represent crop development.
/// - Development Rates: Calculates stage-specific development rates, including the effects of temperature (thermal time), photoperiod (daylength), and vernalization (cold exposure).
/// - Leaf Appearance and Initiation: Simulates the initiation and appearance of leaves on the main stem, using phyllochron and plastochron intervals.
/// - Event Timing: Records the day of year (DOY) for key phenological events (e.g., stem elongation, heading, flowering, ripeness).
/// - Parameterization: Supports genetic and environmental parameters (e.g., base temperature, photoperiod sensitivity, vernalization requirements).
/// - Data Integration: Can initialize and calibrate development using measured data (e.g., measured EC dates).
/// - Modular Design: Integrates with other model components via external variables and options.
/// 
/// Typical usage:
/// This module is used to drive the timing of crop processes (e.g., leaf growth, flowering, grain filling) in response to weather and management, providing the developmental framework for the rest of the crop model.
/// </summary>
  TDevelopment = class(TSubmodel)
  private
    fReCalcSowingDate : boolean;
    fTSumInternode : TOptTSumInternode;
    { Private-Deklarationen }
    EC25MeasDate,
    EC37MeasDate,
    EC30MeasDate : real;
    TSEC32_min, TSEC32_max : real;
    TSEC33_min, TSEC33_max : real;
    TSEC37_min, TSEC37_max : real;
    TSEC38_min, TSEC38_max : real;
    TSEC57_min, TSEC57_max : real;
    TSEC59_min, TSEC59_max : real;
    TSEC61_min, TSEC61_max : real;
    TSEC65_min, TSEC65_max : real;
    TSEC69_min, TSEC69_max : real;
    TSEC71_min, TSEC71_max : real;

  fDataInitMethod : TDataInitMethod;
    procedure CreateVars;
    procedure CreateStates;
    procedure CreatePars;
    procedure CreateExterns;
    procedure CreateOptions;
    procedure InitComments;
    procedure LookForEC30MeasurementDate;
    procedure SetVarsToZero;
    procedure CalcLeafAppearanceRate;
    procedure CalcLeafInitiationRate;
    procedure CalcVernalisationRate;
    procedure CalcStage9DevRate;
    procedure CalcXStageChangeRate;
    procedure CalcSpecificDays_and_TemperatureSums;
      protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    /// <summary>Development rate during istage 1.</summary>
    devrates1: TVar;
    /// <summary>Development rate during istage 2.</summary>
    devrates2: TVar;
    /// <summary>Development rate during istage 3.</summary>
    devrates3: TVar;
    /// <summary>Development rate during istage 4.</summary>
    devrates4: TVar;
    /// <summary>Development rate during istage 5.</summary>
    devrates5: TVar;
    /// <summary>Development rate during istage 6.</summary>
    devrates6: TVar;
    /// <summary>Development rate during istage 9.</summary>
    devrates9: TVar;
    /// <summary>Xstage multiplied by ten for easier plotting.</summary>
    dvs10: TVar;
    /// <summary>Integer value of the development stage.</summary>
    istage: TVar;

    /// <summary>Relative development rate influenced by photoperiod.</summary>
    rdr_p: TVar;   
    /// <summary>Relative development rate influenced by vernalization.</summary>
    rdr_v: TVar;   
    /// <summary>Effective day temperature above the base temperature.</summary>
    Teff: TVar;   
    /// <summary>Zadock's stages.</summary>
    zstage: TVar;  
    /// <summary>Vernalisation factor.</summary>
    vernf: TVar;   
    GS_EC25: TVar;
    TSEC32: Tvar;
    TSEC33: Tvar;
    TSEC37: Tvar;
    TSEC38: Tvar;
    TSEC39: Tvar;
    TSEC57: Tvar;
    TSEC59: Tvar;
    TSEC61: Tvar;
    TSEC65: Tvar;
    TSEC69: Tvar;
    TSEC71: Tvar;
    Ph39_opt: Tvar;
    TSumInternode_opt: TVar;
    /// <summary>Variable photoperiodic influence factor (0..1).</summary>
    c: TVar;
    /// <summary>Vernalisation variable.</summary>
    k_v: TVar;
    /// <summary>Temperature sum from emergence to EC30.</summary>
    tempsumemergence: TVar;
    /// <summary>Day when EC equals 10.</summary>
    d10: TVar;
    /// <summary>Day when EC equals 29.</summary>
    d29: TVar;
    /// <summary>Day when EC equals 50.</summary>
    d50: TVar;
    /// <summary>Day when EC equals 59.</summary>
    d59: TVar;
    /// <summary>Day when EC equals 75.</summary>
    d75: TVar;
    /// <summary>Day when EC equals 90.</summary>
    d90: TVar;
    /// <summary>Day of year for beginning of stem elongation.</summary>
    DOY_BegStemElong: TVar;
    /// <summary>Day of year when BBCH 51 occurs.</summary>
    DOY_BegHeading: TVar;
    /// <summary>Day of year when BBCH 59 occurs.</summary>
    DOY_EndHeading: TVar;
    /// <summary>Day of year for beginning of flowering.</summary>
    DOY_BegFlower: TVar;
    /// <summary>Day of year when BBCH 88 occurs.</summary>
    DOY_YellowRipeness: TVar;
    /// <summary>Day of year for physiological ripeness.</summary>
    DOY_PhysRipe: TVar;
    ECa: TVar;
    /// <summary>Day of year of the sowing date.</summary>
    DayOfYearSowingDate: TVar;
    /// <summary>Number of leaves not formed at Xstage 2.</summary>
    inl_MS_xstage2 : TVar;

    /// <summary>Days since sowing.</summary>
    DaySSow,
    /// <summary>Cumulative vernalisation.</summary>
    cumvern,

    /// <summary>EC stage.</summary>
    ec: TState;
    /// <summary>Thermal developmental units.</summary>
    tdu: TState;
    /// <summary>Temperature sum since sowing.</summary>
    tsums: TState;
    /// <summary>Non-integer growth stage indicator ranging from zero to six.</summary>
    xstage: TState;
    /// <summary>Number of leaves on the main stem.</summary>
    nL_MS: TState;
    /// <summary>Temperature sum since EC30.</summary>
    TSumEC30: TState;
    /// <summary>Temperature sum until EC30.</summary>
    TSum_until_EC_30: TState;
    /// <summary>Temperature sum until EC37.</summary>
    TSum_until_EC_37: TState;

    /// <summary>Initial leaf number on the main stem.</summary>
    inL_MS: TState;

    /// <summary>Photoperiodic daylength.</summary>
    daylengthp,
    /// <summary>Mean air temperature.</summary>
    TMPM,
    dayofyear: TExternV;

    /// <summary>Temperature sum from stage 37 to 39.</summary>
    Ph39: TPar;
    /// <summary>Genotype-specific parameter of photoperiod sensitivity.</summary>
    p1d: TPar;
    /// <summary>Genotype-specific parameter of vernalisation sensitivity.</summary>
    p1v: TPar;
    /// <summary>Sowing depth in centimeters (not currently in use).</summary>
    sdepth: TPar;
    /// <summary>Phyllochron interval in thermal time (degree days) between successive leaf and tiller appearances.</summary>
    phint: TPar;
    /// <summary>Thermal time from end of leaf growth through pre-anthesis ear growth.</summary>
    p3: TPar;
    /// <summary>Thermal time between pre-anthesis ear growth and beginning of grain filling (anthesis occurs during this phase) in °Cd.</summary>
    p4: TPar;
    /// <summary>Thermal time between beginning of grain fill and maturity in °Cd.</summary>
    p5: TPar;
    /// <summary>Thermal time from germination to seedling emergence in °Cd.</summary>
    p9: TPar;
    /// <summary>Base temperature.</summary>
    tBase: TPar;
    /// <summary>Multiplier of the phyllochron interval during stem elongation.</summary>
    Internode: TPar;
    sowingdate: TPar;
    /// <summary>Interval in thermal time between leaf initiation.</summary>
    plastochron: TPar;
    /// <summary>Initial number of initiated leaves at emergence.</summary>
    ini_inLMS: TPar;
    /// <summary>Xstage value at which no further leaf primordia are initiated.</summary>
    xstage_fin_leaf_prim: TPar;

    /// <summary>Temperature sum between two internodes.</summary>
    TSumInternode: TPar;
    minLeaf_number: TPar;
    /// <summary>Maximum number of vernalisation days that increase developmental rate.</summary>
    MaxVernDays: TPar;
    /// <summary>Maximum daylength that increases developmental rate.</summary>
    MaxPhotoperiod: TPar;
    /// <summary>Minimum vernalisation temperature.</summary>
    VernMinTemp: TPar;
    /// <summary>Temperature at which vernalisation starts to be optimal.</summary>
    VernOptTemp1: TPar;
    /// <summary>Temperature at which vernalisation stops being optimal.</summary>
    VernOptTemp2: TPar;
    /// <summary>Temperature at which vernalisation effect becomes zero.</summary>
    VernMaxTemp: TPar;
    /// <summary>Weighting factor for daylength influence.</summary>
    fdl: TPar;  
    /// <summary>Option for selecting the data initialization method.</summary>
    DataInitMethod: Toption;

    /// <summary>Option for recalculating the sowing date.</summary>
    ReCalcSowingDate : Toption;

    /// <summary>Option for TSumInternode calculation.</summary>
    OptTSumInternode: Toption;
    
    /// <summary>Option for using measured dates for development.</summary>
    procedure createAll; override;

    /// <summary>
    /// Initializes the TDevelopment model with global parameters and sets initial values for variables and states.
    /// </summary>  
    procedure Init(var GlobMod: TMod); override;
    
    /// <summary>
    /// Calculates the rates conditions.
    /// </summary>
    procedure CalcRates; override;

    /// <summary>
    /// Integrates the model states over time, updating growth stages and phenological events.
    /// </summary>
    procedure Integrate; override;
    procedure addDataValueToDataSeries; override;
    procedure AddSimValueToDataSeries; override;

  published

   /// <summary>
   /// Photoperiodic influence factor (0..1).
   /// </summary>
   property Var_c : TVar read c write c;

   /// <summary>
    /// Development rate during istage 1.
    /// </summary>
   property Var_devrates1 : TVar read devrates1 write devrates1;

   /// <summary>
   /// Development rate during istage 2.
   /// </summary>
   property Var_devrates2 : TVar read devrates2 write devrates2;
 
   /// <summary>
   /// Development rate during istage 3.
   /// </summary>
   property Var_devrates3 : TVar read devrates3 write devrates3;
   
   /// <summary>
    /// Development rate during istage 4.
    /// </summary>
   property Var_devrates4 : TVar read devrates4 write devrates4;

   /// <summary>
    /// Development rate during istage 5.
    /// </summary>
   property Var_devrates5 : TVar read devrates5 write devrates5;
   
   /// <summary>
    /// Development rate during istage 6.
    /// </summary>  
   property Var_devrates6 : TVar read devrates6 write devrates6;

   /// <summary>
    /// Development rate during istage 9.
    /// </summary>    
   property Var_devrates9 : TVar read devrates9 write devrates9;
   
   /// <summary>
    /// Xstage multiplied by ten for convenience of plotting.
    /// </summary>
   property Var_dvs10 : TVar read dvs10 write dvs10;
   
   
   /// <summary>
    /// Integer value of the development stage.
    /// </summary>  
   property Var_istage : TVar read istage write istage;
   
   /// <summary>
    /// Vernalisation factor.
    /// </summary>
   property Var_k_v : TVar read k_v write k_v;
   
   /// <summary>
    /// Relative development rate effect of photoperiod.
    /// </summary>
   property Var_rdr_p : TVar read rdr_p write rdr_p;
   
   /// <summary>
    /// Relative development rate effect of vernalisation.
    /// </summary>
   property Var_rdr_v : TVar read rdr_v write rdr_v;

   /// <summary>
   /// Temperature sum from emergence to EC30.
   /// </summary>
   property Var_tempsumemergence : TVar read tempsumemergence write tempsumemergence;
   property Var_tsuminc : TVar read Teff write Teff;
   property Var_zstage : TVar read zstage write zstage;
   property Var_vernf : TVar read vernf write vernf;
   property Var_d10 : TVar read d10 write d10;
   property Var_d29 : TVar read d29 write d29;
   property Var_d59 : TVar read d59 write d59;
   property Var_DOY_BegStemElong: TVar read DOY_BegStemElong write DOY_BegStemElong;
   property Var_DOY_BegHeading: TVar read DOY_BegHeading write DOY_BegHeading;
   property Var_DOY_EndHeading: TVar read DOY_EndHeading write DOY_EndHeading;
   property Var_DOY_BegFlower: TVar read DOY_BegFlower write DOY_BegFlower;
   property Var_DOY_yellowRipeness: TVar read DOY_YellowRipeness write DOY_YellowRipeness;
   property Var_DOY_PhysRipe: TVar read DOY_PhysRipe write DOY_PhysRipe;


   property Var_dayofYearSowingDate : TVar read DayOfYearSowingDate write DayofYearSowingDate;

   property ST_cumvern : TState read cumvern write cumvern;
   property ST_ec : TState read ec write ec;
   property ST_tdu : TState read tdu write tdu;
   property ST_tsums : TState read tsums write tsums;
   property ST_xstage : TState read xstage write xstage;
   property ST_nl_MS : TState read nl_MS write nl_MS;
   property ST_inl_MS : TState read inl_MS write inl_MS;
   property ST_Tsum_until_EC_30 : TState read Tsum_until_EC_30 write Tsum_until_EC_30;
   property ST_Tsum_until_EC_37 : TState read Tsum_until_EC_37 write Tsum_until_EC_37;

   property Ex_daylengthp : TExternV read daylengthp write daylengthp;
   property Ex_dayofyear : TExternV read dayofyear write dayofyear;
   property Ex_TMPM : TExternV read TMPM write TMPM;

   /// <summary>
   /// Thermal time from germination to seedling emergence (°Cd).
   /// </summary>
   property Par_p9 : TPar read p9 write p9;
   /// <summary>
   /// Thermal time between pre-anthesis ear growth and start of grain filling (°Cd).
   /// </summary>
   property Par_p4 : TPar read p4 write p4;
   /// <summary>
   /// Thermal time between start of grain filling and maturity (°Cd).
   /// </summary>
   property Par_p5 : TPar read p5 write p5;
   property Par_minLeaf_number : TPar read minLeaf_number write minLeaf_number;
   property Par_plastochron : TPar read plastochron write plastochron;
   property Par_phint : TPar read phint write phint;
   property Par_Ini_inLMS : TPar read Ini_inLMS write Ini_inLMS;
 //  property Par_TsumInternode : TPar read TsumInternode write TsumInternode;
   property PAR_sowingdate: TPar read sowingdate write sowingdate;
   property PAR_MaxVernDays: TPar read MaxVernDays write MaxVernDays;
   property PAR_MaxPhotoperiod: TPar read MaxPhotoperiod write MaxPhotoperiod;
   /// <summary>
   /// Minimum vernalisation temperature.
   /// </summary>
   property PAR_VernMinTemp: TPar read VernMinTemp write VernMinTemp;
   /// <summary>
   /// Temperature where vernalisation starts to be optimal.
   /// </summary>
   property PAR_VernOptTemp1: TPar read VernOptTemp1 write VernOptTemp1;
   /// <summary>
   /// Temperature where vernalisation ends being optimal.
   /// </summary>
   property PAR_VernOptTemp2: TPar read VernOptTemp2 write VernOptTemp2;
   /// <summary>
   /// Temperature where vernalisation effect becomes zero.
   /// </summary>
   property PAR_VernMaxTemp: TPar read VernMaxTemp write VernMaxTemp;

   property Opt_DataIniMethod : TOption read DataInitMethod write DataInitMethod;
   property Opt_ReCalcSowingDate : boolean read fReCalcSowingDate write fReCalcSowingDate;
    { Published-Deklarationen }

  end;  


procedure Register;

implementation

uses
  UModUtils,
  DateUtils;

procedure TDevelopment.createall;
begin
  inherited createAll;
  CreateVars;
  CreateStates;
  CreatePars;
  CreateExterns;
  CreateOptions;
  InitComments;
end;

procedure TDevelopment.init(var GlobMod: TMod);

var
  year, month, day: word;
  tempsowdate : real;
  ActIniFileName : String;
begin
  inL_MS.V := 5;   // initial leaf number on main stem

  inherited init(GlobMod);
  SetVarsToZero; // set all variables to zero
  LookForEC30MeasurementDate; // look for EC30 measurement date in data series

  //*.v= Value; *.c=change  

  inL_MS.V := ini_inlMS.v;   // initial leaf number on main stem
  c.v := p1d.V*0.002;            // photoperiodical factor unscaled
  k_v.v := (p1v.v+0.55)/183;     // vernalisation factor unscaled
  istage.v := trunc(xstage.v); // istage is integer value of xstage
  // duration of stage 9
  //p9.v := (40 + 10.2 * sdepth.v);
  tempsumemergence.v := p9.v; // 40+10.2*sdepth.V;
  DecodeDate(Sowingdate.v, Year, Month, Day); 
  tempsowdate := sowingdate.v + 2 - EncodeDate(Year, 1, 1);
  DayOfYearSowingDate.v := TempSowDate;

  If opt_ReCalcSowingDate = true then
    sowingdate.v := trunc(tempsowdate);
   if OptTSumInternode.option = 'constant' then
    fTSumInternode := constant
  else
    fTSumInternode := daylength;



end;

procedure TDevelopment.CalcRates;

begin
  if(fTSumInternode = daylength) then begin
    TSumInternode_opt.v:= phint.v + fdl.v*daylengthp.v*daylengthp.v; // calculate TSumInternode_opt from phint, fdl, and daylengthp
    ph39_opt.v:=TSumInternode_opt.v;
  end else begin
    TSumInternode_opt.v:= TSumInternode.v; // use TSumInternode as constant value
    ph39_opt.v:= ph39.v;
  end;

  if (EC30MeasDate > 0)  and (GlobMod.Time.v > EC30MeasDate) and (ec.v>11) then
    TSumEC30.c := max(0, TMPM.v-tbase.v)
  else
    TSumEC30.c := 0.0;

  if (EC30MeasDate > 0)  and (GlobMod.Time.v < EC30MeasDate) and (GlobMod.Time.v > Sowingdate.v) and (ec.v <= 30) then
    TSum_until_EC_30.c := max(0, TMPM.v-tbase.v)
  else
    TSum_until_EC_30.c := 0.0;

  if (EC37MeasDate > 0)  and (GlobMod.Time.v < EC37MeasDate) and (GlobMod.Time.v > Sowingdate.v) and (ec.v <= 37) then
    TSum_until_EC_37.c := max(0, TMPM.v-tbase.v)
  else
    TSum_until_EC_37.c := 0.0;


  // calculate days since sowing
  If opt_ReCalcSowingDate = true then
    if (dayofyear.v>=dayofyearsowingdate.V) then
      Dayssow.c := GlobTime.C;

  If opt_ReCalcSowingDate = false then
    if (globtime.v>=sowingdate.V) then
      Dayssow.c := GlobTime.C;

  // calculate effective day temperature
  Teff.V := max(0, TMPM.v-tbase.v);

  If opt_ReCalcSowingDate = true then
    if (dayofyear.v<dayofyearsowingdate.V)and(tsums.v<=0)
      then Teff.V := 0;

  If opt_ReCalcSowingDate = false then
    if (globtime.v<sowingdate.V)and(tsums.v<=0)
      then Teff.V := 0;

  tsums.c:= Teff.v;
  tdu.c := tsums.c; // default for tdu.c, recalclated during stage 1


  CalcLeafAppearanceRate;
  CalcLeafInitiationRate;
  CalcVernalisationRate;  // by default

  // calculate vernalisation influence factor
  rdr_v.v := min(1,max(0,1-k_v.v*(MaxVernDays.v-cumvern.v)));

  /// <summary>Calculates the daylength influence factor.</summary>
  /// <remarks>See http://localhost:4685/Components/CERES%20Wheat/Documentation/TDevelopment.html#photoperiod.</remarks>
  rdr_p.v := min(1,max(0,1-c.v*sqr(MaxPhotoperiod.v-daylengthp.v)));

  CalcStage9DevRate;

// calculation of development rate from emergence until terminal spikelet initiation
  if (istage.v>=1)and(istage.v<2) then
  begin
      // thermal development units
    tdu.c:= Teff.v*min(rdr_p.v, rdr_v.v);
    devrates1.v := tdu.c/(400*phint.V/95)
    //devrates1.v := tsuminc.V* min(rdr_p.v, rdr_v.v)/(((minLeaf_number.v-3)*plastochron.v)*phint.V/95)
  end
 else devrates1.v := 0;  // by default

  //devrates2.v := tsuminc.v/(3*phint.v);   //  bei modifizierung ausklammern
  devrates6.v := Teff.v/250;

// development according to zadok's scale and EC stages
if (xstage.v>=0)and(xstage.v<2) then
  begin
     zstage.v := xstage.v*10;
     If XSTAGE.v< 1 then
       EC.c := devrates9.v*10  // XSTAGE 1 is equivalent to BBCH 10  !!
     else
       ec.C:= Teff.v/phint.v  // rate of change of EC stages invers to phyllochron
  end else begin
    zstage.V := 0;
    ec.c := 0;
  end;

  if (xstage.v>=2) and (inl_MS_xstage2.v=0)then   // if double ridge stage is not yet reached
    inl_MS_xstage2.v := max(0,inl_MS.v-2-nl_MS.v); // number of leaves which have to emerge
// inl_MS_xstage2.v := max(0, inl_MS.v-{2-}nl_MS.v);     // two leaves will never emerge ...

  if (xstage.v>=2)and(xstage.v<3) then
  begin

     zstage.v := 2.0+2.0*(XSTAGE.v-2.0);
     ZStage.v := zSTage.v*10;
//     xstage.c := Teff.v*(1/(inl_MS_xstage2.v*Phint.v+Ph39.v));// denumerator: thermal time from xstage 2 to BBCH 39
     xstage.c := teff.v*(1/(inl_MS_xstage2.v* TSumInternode_opt.v +Ph39_opt.v));     //EC.c := zstage.v - EC.v;
     If EC.v < 37 then
       EC.c     := teff.v/TSumInternode_opt.v // EC stage change according to the inverse of the temperature sum between the appearance of two internodes
    else
       EC.c := min(2*teff.v/Ph39_opt.v,40-EC.v);// 40-EC.v beschr�nkt, dass Entw.rate auf �ber 40 springt  min(tsuminc.v/Phint.v,40-EC.v);
     (* If (EC.v+EC.c*Globtime.c<39) and (xstage.v+Devrates2.v*globtime.c>3) then
       devrates2.v :=0;*)     //WENN DIESE BEDINGUNG ENTF�LLT WIRD XSTAGE NICHT ANGEHALTEN WENN ec 39 NOCH NICHT ERRREICHT WURDE UND SOMIT L�UFT EC BERECHNUNG MIT N�CHSTER DEVRATE WEITER
    (*If (EC.v >= 37) and (xstage.v<2) then
    EC.c := min(2*tsuminc.v/Ph39.v,40-EC.v);//min(tsuminc.v/Phint.v,40-EC.v);
      (*If (EC.v+EC.c*Globtime.c<39) and (xstage.v+Devrates2.v*globtime.c>3) then
       devrates2.v :=0;*)
  end else
// if (xstage.v>=3)and(xstage.v<4) and (ec.v<=39) then  begin
//    EC.c := tsuminc.v/Phint.v
 //end else

 if (xstage.v>=3)and(xstage.v<4) {and (ec.v>=39)} then
  begin
    devrates3.v := teff.v/p3.v;
								  
    zstage.v := 4 + 1.7*(xstage.v-3.0);       // EC 57 nach Berechnung, 39-61 nach
                                              // Beschreibung
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end else

  devrates4.v := Teff.v/p4.v;                     // p4 ~ 200 degree days

  devrates5.v := (max(0,Teff.v-1))/((p5.v+21.5)/0.05); //

  if (xstage.v>=4)and(xstage.v<4.4) then
    begin
      zstage.v := 5.7 + 0.8*(xstage.v-4.0);   // EC 62
      ZStage.v := zSTage.v*10;
      EC.c := zstage.v - EC.v;
    end else

if (xstage.v>=4.4)and(xstage.v<6) then
  begin
    zstage.v := 6.02 + 1.86*(xstage.v-4.4); // from CERES nitrogen module
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end else

if (xstage.v>= 6) and (xstage.v <7) then
  begin
    zstage.v := 9 + (xstage.v-6);           // from CERES nitrogen module
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end;

  CalcXStageChangeRate;
end;


procedure TDevelopment.Integrate;

var
   i, ListPos: integer;
  ActSeries: TMeasList;
  ActMeas: TMeasValue;
  ActState: TState;
  ActVar: TVar;
  index : integer;

begin
  inherited integrate;
// non-integer growth stage indicator ranging from zero to six
  istage.V := trunc(xstage.V);
  dvs10.v := Istage.v*10;    // dvs10 = scaled variable for plotting

																	  if (d10.V <=0) and (ec.v >=10) then    // calculation of day of emergence
   d10.V := dayssow.v;
   // d10.v := dayofyear.v;
  if (d29.V <=0) and (ec.v >=29) then
    d29.v := dayssow.v;
    //d29.v := dayofyear.v;
	   

  Eca.v := EC.v;
  If Ec.v> 15 then ECa.V := EC.v-7.5;

// setting of some variables at defined events ...
     // If XSTAGE reaches 1 first time, set back to 1 and set number of visisble
     // leaves to 1
//  if (xstage.v > 1) and (nl_ms.v < 1) then nl_ms.v := 1; ratjen 16.01.2013

  If (EC.v >= 13.5) and (EC.v < 20) then  // Tillering starts after 4. leaf appears
    EC.v := EC.v+7.5;                     // EC = 21 when first tiller emerged
  If (xSTAGE.v >=2) and (EC.v < 30) then
    EC.v :=30;                          //Spitzen�hrchen "terminal spikelet" = EC 30

   // if the number of visible leaves reaches the number of initialised leaves (minus 2, for collar and ?)
   // the flag leaves appears and we have EC-Stage 37!!
  If (nL_MS.v >= (inL_MS.v-2)) and (EC.v<37) //and  (EC.v>=33)
  then begin
 //   Ec.v := 37+min(2*(nL_MS.v-(inL_MS.v-2))*phint.v/Ph39.v,40-EC.v);
    // impact of exceeding leaf number (fraction) on EC progress
    Ec.v := 37+min(2*(nL_MS.v-(inL_MS.v-2))*TSumInternode_opt.v/Ph39_opt.v,40-EC.v);
    //XStage.v := 2+(37-29)/(40-29);
  end;

  If (EC.v >= 40) and (xstage.v<3) then
    xstage.v :=3;  // Damit Xstage wieder EC Stand entspricht

  if (EC25MeasDate > 0)  and (GlobMod.Time.v >= EC25MeasDate) and (GS_EC25.v<=0.0) then
    GS_EC25.v := Xstage.v;
  CalcSpecificDays_and_TemperatureSums;


end;

procedure TDevelopment.AddDataValueToDataSeries;

var
  i, ListPos: integer;
  ActSeries: TMeasList;
  ActMeas: TMeasValue;
  ActState: TState;
  ActVar: TVar;
  index : integer;
  ActIniFileName : string;

begin
  inherited AddDataValueToDataSeries;
  ActIniFilename := ExtractFileName(GlobMod.ActIniFile.FileName);


  Index := DataList.IndexOf(ec.name);
  if index <> -1 then begin
      ActSeries := TMeaslist(DataList.objects[Index]);
      for i := 0 to  ActSeries.count-1 do begin
        ActMeas := TMeasValue(ActSEries.items[i]);
        if (trunc(ActMeas.meas) = 25)
        then if (actMeas.Comment = ActIniFileName) then
          EC25MeasDate := trunc(ActMeas.date);
        if ActMeas.meas = 30 then
         if (actMeas.Comment = ActIniFileName) then
          EC30MeasDate := ActMeas.date;
        if ActMeas.meas = 37 then
          if (actMeas.Comment = ActIniFileName) then
          EC37MeasDate := ActMeas.date;
      end;
  end;


end;


procedure TDevelopment.AddSimValueToDataSeries;

var
  i, ListPos: integer;
  ActSeries: TMeasList;
  ActMeas: TMeasValue;
  ActState: TState;
  ActVar: TVar;
  index : integer;

begin
  If DataInitMethod.option = 'ec_date' then
  inherited AddSimValueToDataSeries
  else begin

  Index := DataList.IndexOf(d10.name);
  if index <> -1 then begin
      ActSeries := TMeaslist(DataList.objects[Index]);
      If ActSeries.ActPos+1 <= ActSeries.count then begin
        ActMeas := TMeasValue(ActSEries.items[ActSeries.ActPos]);
        if (d10.v <> 0) and (actMeas.sim = 0) then begin
          ActMeas.sim := d10.V;
          if ActSeries.actPos < ActSeries.count then
            inc(ActSeries.actPos);
          //ActMeas.date := self.GlobTime.v;
          ActSEries.SumSqrdiff := ActSEries.SumSqrdiff + sqr(ActMeas.sim - ActMeas.meas);
        end;
      end;
  end;


  Index := DataList.IndexOf(d29.name);
  if index <> -1 then begin
      ActSeries := TMEasList(DataList.objects[Index]);
      If ActSeries.ActPos+1 <= ActSeries.count then begin
        ActMeas := TMeasValue(ActSEries.items[ActSeries.ActPos]);
        if (d29.v <> 0) and (actMeas.sim = 0) then begin
          ActMeas.sim := d29.V;
          if ActSeries.actPos < ActSeries.count then
            inc(ActSeries.actPos);
          //ActMeas.date := self.GlobTime.v;
          ActSEries.SumSqrdiff := ActSEries.SumSqrdiff + sqr(ActMeas.sim - ActMeas.meas);
        end;
      end;
  end;

  end;

end;

procedure TDevelopment.CalcSpecificDays_and_TemperatureSums;
begin
  if (d10.V <= 0) and (ec.v >= 10) then
    // calculation of day of emergence
    d10.V := dayssow.v;
  // d10.v := dayofyear.v;
  if (d29.V <= 0) and (ec.v >= 29) then
    d29.v := dayssow.v;
  //d29.v := dayofyear.v;
  if (d50.V <= 0) and (ec.v >= 50) then
    d50.v := dayssow.v;
  if (d59.V <= 0) and (ec.v >= 59) then
    d59.v := dayssow.v;
  if (d75.V <= 0) and (ec.v >= 75) then
    d75.v := dayssow.v;
  if (d90.V <= 0) and (ec.v >= 90) then
    d90.v := dayssow.v;
  // TSEC37 is a derived value for calibration only!
  if (self.DOY_BegStemElong.V <= 0) and (ec.v >= 30) then
    DOY_BegStemElong.V := DayOfTheYear(GlobTime.v);
  if (self.DOY_BegHeading.V <= 0) and (ec.v >= 51) then
    DOY_BegHeading.V := DayOfTheYear(GlobTime.v);
  if (self.DOY_EndHeading.V <= 0) and (ec.v >= 59) then
    DOY_EndHeading.V := DayOfTheYear(GlobTime.v);
  if (self.DOY_BegFlower.V <= 0) and (ec.v >= 61) then
    DOY_BegFlower.V := DayOfTheYear(GlobTime.v);
  if (self.DOY_YellowRipeness.V <= 0) and (ec.v >= 88) then
    DOY_YellowRipeness.V := DayOfTheYear(GlobTime.v);
  if (self.DOY_PhysRipe.V <= 0) and (ec.v >= 90) then
    DOY_PhysRipe.V := DayOfTheYear(GlobTime.v);
  if ((trunc(ec.v) = 32) and (TSEC32_min = 0)) then
    TSEC32_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 32) and (TSEC32_max = 0) and (TSEC32_min > 0)) then
  begin
    TSEC32_max := TSums.v;
    TSEC32.v := (TSEC32_min - 1 + TSEC32_max) / 2;
  end;
  if ((trunc(ec.v) = 33) and (TSEC33_min = 0)) then
    TSEC33_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 33) and (TSEC33_max = 0) and (TSEC33_min > 0)) then
  begin
    TSEC33_max := TSums.v;
    TSEC33.v := (TSEC33_min - 1 + TSEC33_max) / 2;
  end;
  if ((trunc(ec.v) = 37) and (TSEC37_min = 0)) then
    TSEC37_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 37) and (TSEC37_max = 0) and (TSEC37_min > 0)) then
  begin
    TSEC37_max := TSums.v;
    TSEC37.v := (TSEC37_min - 1 + TSEC37_max) / 2;
  end;
  if ((trunc(ec.v) = 38) and (TSEC38_min = 0)) then
    TSEC38_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 38) and (TSEC38_max = 0) and (TSEC38_min > 0)) then
  begin
    TSEC38_max := TSums.v;
    TSEC38.v := (TSEC38_min - 1 + TSEC38_max) / 2;
  end;
  if ((trunc(ec.v) = 57) and (TSEC57_min = 0)) then
    TSEC57_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 57) and (TSEC57_max = 0) and (TSEC57_min > 0)) then
  begin
    TSEC57_max := TSums.v;
    TSEC57.v := (TSEC57_min - 1 + TSEC57_max) / 2;
  end;
  if ((trunc(ec.v) = 59) and (TSEC59_min = 0)) then
    TSEC59_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 59) and (TSEC59_max = 0) and (TSEC59_min > 0)) then
  begin
    TSEC59_max := TSums.v;
    TSEC59.v := (TSEC59_min - 1 + TSEC59_max) / 2;
  end;
  if ((trunc(ec.v) = 61) and (TSEC61_min = 0)) then
    TSEC61_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 61) and (TSEC61_max = 0) and (TSEC61_min > 0)) then
  begin
    TSEC61_max := TSums.v;
    TSEC61.v := (TSEC61_min - 1 + TSEC61_max) / 2;
  end;
  if ((trunc(ec.v) = 65) and (TSEC65_min = 0)) then
    TSEC65_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 65) and (TSEC65_max = 0) and (TSEC65_min > 0)) then
  begin
    TSEC65_max := TSums.v;
    TSEC65.v := (TSEC65_min - 1 + TSEC65_max) / 2;
  end;
  if ((trunc(ec.v) = 69) and (TSEC69_min = 0)) then
    TSEC69_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 69) and (TSEC69_max = 0) and (TSEC69_min > 0)) then
  begin
    TSEC69_max := TSums.v;
    TSEC69.v := (TSEC69_min - 1 + TSEC69_max) / 2;
  end;
  if ((trunc(ec.v) = 71) and (TSEC71_min = 0)) then
    TSEC71_min := TSums.v - Tsums.c;
  if ((trunc(ec.v) > 71) and (TSEC71_max = 0) and (TSEC71_min > 0)) then
  begin
    TSEC71_max := TSums.v;
    TSEC71.v := (TSEC71_min - 1 + TSEC71_max) / 2;
  end;
end;

procedure TDevelopment.CalcXStageChangeRate;
begin
  if (istage.v >=7) then
    xstage.c := 0.0;
  if (istage.v < 7) and (istage.v >= 6) then
    xstage.c := devrates6.v
  else if (istage.v < 6) and (istage.v >= 5) then
    xstage.c := devrates5.v
  else if (istage.v < 5) and (istage.v >= 4) then
    xstage.c := devrates4.v
  else if (istage.v < 4) and (istage.v >= 3) then
    xstage.c := devrates3.v
  else if (istage.v < 1) then
    xstage.c := devrates9.v
  else if (istage.v >= 1) and (tsums.v >= tempsumemergence.v) and (istage.v < 2) then
    xstage.c := devrates1.v;
end;

procedure TDevelopment.CalcStage9DevRate;
begin
  // calculation of development rate until emergence (stage 9 according to Ritchie)
  if (p9.v > 0) then
    // begin
    devrates9.v := Teff.v / p9.v;
end;

procedure TDevelopment.CalcVernalisationRate;
begin
  // calculate rate of change of vernalisation status
  if (cumvern.v < MaxVernDays.v) and (tsums.v > tempsumemergence.v) then
  begin
    vernf.v := trapez_f(TMPM.V, VernMinTemp.v, VernOptTemp1.v, VernOptTemp2.v, VernMaxTemp.v, 0, 1);
    cumvern.c := vernf.v;
  end
  else
    cumvern.c := 0;
end;

procedure TDevelopment.CalcLeafInitiationRate;
begin
  // calculate rate of leaf initiation until apical meristeme is not generative
  if (Istage.v >= 1) and (xstage.v < xstage_fin_leaf_prim.v) then
    // (xstage.v< xstage_fin_leaf_prim.v)
    inL_MS.c := Teff.v / plastochron.v 
  else
    inL_MS.c := 0;
end;

procedure TDevelopment.CalcLeafAppearanceRate;
begin
  {  If (Dayofyear.v-3>sowingdate.v)and(tsums.v<=0)
    then showmessage('SimStart later than sowing !');  }
  // calculate rate of leaf apperance until visible number of leaves is smaller than initiated number
  If (Istage.v >=1) and (nl_ms.v<inL_MS.v) then
  begin
    if phint.v > 0 then
      if (xstage.v < 2) then
        nl_MS.c := Teff.v/phint.v
      else
        nl_MS.c := Teff.v/TSumInternode_opt.v;  // number of leaves on main stem.change
  end
  else
  begin
    nl_MS.c := 0.0;
  end;
end;

procedure TDevelopment.SetVarsToZero;
begin
  TSEC32_min := 0;
  TSEC32_max := 0;
  TSEC33_min := 0;
  TSEC33_max := 0;
  TSEC37_min := 0;
  TSEC37_max := 0;
  TSEC38_min := 0;
  TSEC38_max := 0;
  TSEC57_min := 0;
  TSEC57_max := 0;
  TSEC59_min := 0;
  TSEC59_max := 0;
  TSEC61_min := 0;
  TSEC61_max := 0;
  TSEC65_min := 0;
  TSEC65_max := 0;
  TSEC69_min := 0;
  TSEC69_max := 0;
  TSEC71_min := 0;
  TSEC71_max := 0;
  //  Index := DataList.IndexOf(d29.name);
  //  if Index >= 0 then ActSeries := TMEasList(DataList.objects[Index]);
  EC25MeasDate := 0;
  EC30MeasDate := 0;
  EC37MeasDate := 0;
  TSumEC30.c := 0;
  TSumEC30.v := 0;
  d10.v := 0;
  d29.v := 0;
  d50.v := 0;
  d59.v := 0;
  d75.v := 0;
  d90.v := 0;
end;

procedure TDevelopment.LookForEC30MeasurementDate;
var
  index: Integer;
  i: Integer;
  ActMeas: TMeasValue;
  ActSeries: TMeasList;
begin
  Index := DataList.IndexOf(ec.name);
  if index <> -1 then
  begin
    ActSeries := TMeaslist(DataList.objects[Index]);
    for i := 0 to ActSeries.count - 1 do
    begin
      ActMeas := TMeasValue(ActSEries.items[i]);
      if ActMeas.meas = 30 then
        EC30MeasDate := ActMeas.date;
    end;
  end;
end;

procedure TDevelopment.InitComments;
begin
  // comments initialisation
  devrates1.comment := 'developmet rate during istage 1';
  devrates2.comment := 'developmet rate during istage 2';
  devrates3.comment := 'developmet rate during istage 3';
  devrates4.comment := 'developmet rate during istage 4';
  devrates5.comment := 'developmet rate during istage 5';
  devrates6.comment := 'developmet rate during istage 6';
  devrates9.comment := 'developmet rate during istage 9';
  dvs10.comment := 'xstage times 10, for convenience of plotting';
  istage.comment := ' Phenologicalstages in integer values';
  rdr_p.comment := 'relative development rate of photoperiod';
  rdr_v.comment := 'relative development rate of vernalization';
  Teff.comment := 'effective day temperature, i.e. temperature above base temperature';
  zstage.comment := 'Zadocks stages';
  vernf.comment := 'vernalisation factor';
  c.comment := 'variable photoperiodic influence factor (0..1)';
  k_v.comment := 'vernalisation variable';
  tempsumemergence.comment := 'temperature sum until emergence';
  d10.comment := 'Day when EC equals 10';
  d29.comment := 'Day when EC equals 29';
  ECa.comment := '';
  DayOfYearSowingDate.comment := 'Day of Year of sowing date';
  DaySSow.comment := 'days since sowing';
  cumvern.comment := 'cumulative vernalisation';
  ec.comment := 'EC stage';
  tdu.comment := 'thermal developmental units';
  tsums.comment := 'temperature sum since sowing';
  xstage.comment := 'non integer growth stage indicator ranging from zero to six';
  nL_MS.comment := 'number of leaves on main stem';
  TSumEC30.comment := 'Temperature sum since EC30';
  inL_MS.comment := 'initial leaf number on main stem';
  inl_MS_xstage2.comment := 'number of not emerged leaves at Xstage 2';
  daylengthp.comment := 'photoperiodic daylength';
  TMPM.comment := 'mean air temperature';
  dayofyear.comment := 'day of year';
  Ph39.comment := 'TSUM 37 to 39';
  p1d.comment := 'genetic specific parameter of photoperiod sensitivity';
  p1v.comment := 'genetic specific parameter of vernalisation sensitivity';
  sdepth.comment := 'sowing depth (cm), not actual in use';
  phint.comment := 'the phyllochron interval, the interval in thermal time' + '(degree days) between successive leaf and tiller appearances';
  p4.comment := 'thermal time between Pre-anthesis ear growth to beginning of' + ' grain filling (anthesis occurs during this phase)in °Cd';
  p5.comment := 'thermal time between beginning of grain fill and maturity in °Cd';
  p9.comment := 'thermal timen from germination to seedling emergence in °Cd';
  tBase.comment := 'base temperature';
  Internode.comment := 'Multiplikator des Phyllochronintervalls in der Schossphase';
  sowingdate.comment := 'sowing date in day of year';
  plastochron.comment := 'interval in thermal time between leaf initiation';
  xstage_fin_leaf_prim.comment := 'xstage at which  xstage at which no further leaf primordia are formed';
  TSumInternode.comment := 'temperature sumd between two internodes';
  minLeaf_number.comment := '';
  MaxVernDays.comment := 'maximum number of vernalisation days which increase developmental rate';
  MaxPhotoperiod.comment := 'maximum daylength which increase developmental rate';
  VernMinTemp.comment := 'minimum vernalisation temperature';
  VernOptTemp1.comment := 'temperature where vernalisation is starting to be optimal';
  VernOptTemp2.comment := 'temperature where vernalisation is ending to be optimal';
  VernMaxTemp.comment := 'temperature where vernalisation is getting zero';

end;

procedure TDevelopment.CreateOptions;
begin
  OptCreate('DataInitMethod', 'EC_date', DataInitMethod);
  DataInitMethod.OptionList.Add('EC_date');
  DataInitMethod.OptionList.Add('Days_to_EC');
  OptCreate('RecalcSowingDate', 'True', RecalcSowingDate);
  RecalcSowingDate.OptionList.Add('True');
  RecalcSowingDate.OptionList.Add('False');
  OptCreate('optTSumInternode', 'constant', OptTSumInternode, 'option to set daylength effect on TSumInternode');
   OptTSumInternode.OptionList.Add('constant');
   OptTSumInternode.OptionList.Add('daylength');
   optTSumInternode.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/TDevelopment.html#day-length-effects'
//  optTSumInternode.DocuWebLink := 'Doku <a href="https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/TDevelopment.html#day-length-effects" title="Hume-Doku">hyperlink</a>';
end;

procedure TDevelopment.CreateExterns;
begin
  // neu angepasst 17.01.
  ExternVCreate('daylengthp', 'h', ratefield, daylengthp, 'photoperiodic daylength');
  ExternVCreate('dayofyear', 'n', statefield, dayofyear, 'day of year');
  ExternVCreate('TMPM', '[°C]', ratefield, TMPM, 'mean air temperature');
end;

procedure TDevelopment.CreatePars;
begin
  Parcreate('p1d', '', 2.76, p1d);
  p1d.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/TDevelopment.html#photoperiod';
    //aktualisiert nach John-Manuskript 29.Jan.09
  Parcreate('p1v', '', 2.84, p1v);
  p1v.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/TDevelopment.html#vernalisation';

  //aktualisiert nach John-Manuskript 29.Jan.09
  Parcreate('sdepth', 'cm', 3, sdepth);
  Parcreate('phint', '°Cd', 91.74, phint);
  phint.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/TDevelopment.html#eq-dnLMS';
  //aktualisiert nach John-Manuskript 29.Jan.09
  Parcreate('tBase', '', 0, tBase);
  Parcreate('sowingdate', 'doy', 300, sowingdate);
  ParCreate('fdl', '-', 0, fdl);
  fdl.DocuWebLink := 'https://agronomykiel.github.io/HUME/Components/CERES%20Wheat/Documentation/TDevelopment.html#day-length-effects';
  Parcreate('p3', '°Cd', 183.48, p3);

  Parcreate('p4', '°Cd', 200, p4);
  Parcreate('p5', '-', 11.67, p5);
  //aktualisiert nach Johnen-Manuskript 29.Jan.09
  ParCreate('p9', '°Cd', 139.9, p9);
  //aktualisiert nach Johnen-Manuskript 29.Jan.09
  ParCreate('plastochron', '°Cd', 68.3914, plastochron);
  //aktualisiert am 17.01.
  ParCreate('Ini_inLMS', 'n', 4, Ini_inLMS);
  //aktualisiert am 17.01. nach Kage 2012
  ParCreate('TSumInternode', '°Cd', 97.09, TSumInternode);
  //aktualisiert nach John-Manuskript 29.Jan.09
  ParCreate('minLeaf_number', '', 7, minLeaf_number);
  ParCreate('Internode', '', 3, Internode);
  ParCreate('MaxVernDays', 'd', 50, MaxVernDays);
  ParCreate('MaxPhotoperiod', 'h', 20, MaxPhotoperiod);
  ParCreate('VernMinTemp', '°C', -0.5, VernMinTemp);
  ParCreate('VernOptTemp1', '°C', 0.5, VernOptTemp1);
  ParCreate('VernOptTemp2', '°C', 6, VernOptTemp2);
  ParCreate('VernMaxTemp', '°C', 18, VernMaxTemp);
  ParCreate('Ph39', '-', 101.56, Ph39);
  //aktualisiert nach John-Manuskript 29.Jan.09
  ParCreate(' xstage_fin_leaf_prim', '-', 1.78171, xstage_fin_leaf_prim);
end;

procedure TDevelopment.CreateStates;
begin
  StateCreate('cumvern', '', 0, true, cumvern, 'cumulative vernalisation days');
  StateCreate('ec', '', 0, true, ec, 'EC stage');
  ec.PlotTograpH := true;
  StateCreate('tdu', '', 0, true, tdu, 'thermal developmental units');
  StateCreate('tsums', '', 0, true, tsums);
  StateCreate('xstage', '', 0, true, xstage, 'non integer growth stage indicator ranging from zero to six');
  StateCreate('nl_MS', 'n', 0, false, nl_MS, 'number of leaves on main stem');
  StateCreate('inl_MS', 'n', 5, false, inl_MS, 'initial leaf number on main stem');
  StateCreate('DaySSow', 'n', 0, false, DaySSow, 'day since sowing');
  StateCreate('TSumEC30', '', 0, true, TSumEC30, 'Temperature sum since EC30');
  StateCreate('TSum_until_EC_30', '', 0, true, TSum_until_EC_30);
  StateCreate('TSum_until_EC_37', '', 0, true, TSum_until_EC_37);
end;

procedure TDevelopment.CreateVars;
begin
  //Möglichkeit, die Methoden des Vorgängermodells
  //aufzurufen, so daß mit einer einzigen Anweisung die ganze Funktionalität der
  // Vorgängermethoden übernommen werden
  
  VarCreate('c', '', 0, true, c);
  // Define Value
  VarCreate('devrates1', '', 0, true, devrates1, 'development rate during istage 1');
  VarCreate('devrates2', '', 0, true, devrates2, 'development rate during istage 2');
  VarCreate('devrates3', '', 0, true, devrates3, 'development rate during istage 3');
  VarCreate('devrates4', '', 0, true, devrates4, 'development rate during istage 4');
  VarCreate('devrates5', '', 0, true, devrates5, 'development rate during istage 5');
  VarCreate('devrates6', '', 0, true, devrates6, 'development rate during istage 6');
  VarCreate('devrates9', '', 0, true, devrates9, 'development rate during istage 9');
  VarCreate('dvs10', '', 0, true, dvs10, 'xstage times 10, for convenience of plotting');
  VarCreate('istage', '', 0, true, istage, ' Phenologicalstages in integer values');
  VarCreate('k_v', '', 0, true, k_v, 'vernalisation variable');
  // Define Value
  VarCreate('rdr_p', '', 0, true, rdr_p, 'relative development rate effect of photoperiod');
  VarCreate('rdr_v', '', 0, true, rdr_v, 'relative development rate effect of vernalisation');
  VarCreate('TSEC32', '', 0, true, TSEC32, 'Date of BBCH32 (needed for calibration');
  VarCreate('TSEC33', '', 0, true, TSEC33, 'Date of BBCH33 (needed for calibration');
  VarCreate('TSEC37', '', 0, true, TSEC37, 'Date of BBCH37 (needed for calibration');
  VarCreate('TSEC38', '', 0, true, TSEC38, 'Date of BBCH38 (needed for calibration');
  VarCreate('TSEC57', '', 0, true, TSEC57, 'Date of BBCH57 (needed for calibration');
  VarCreate('TSEC59', '', 0, true, TSEC59, 'Date of BBCH59 (needed for calibration');
  VarCreate('TSEC61', '', 0, true, TSEC61, 'Date of BBCH61 (needed for calibration');
  VarCreate('TSEC65', '', 0, true, TSEC65, 'Date of BBCH65 (needed for calibration');
  VarCreate('TSEC69', '', 0, true, TSEC69, 'Date of BBCH69 (needed for calibration');
  VarCreate('TSEC71', '', 0, true, TSEC71, 'Date of BBCH71 (needed for calibration');
  VarCreate('tempsumemergence', '', 0, true, tempsumemergence, 'temperature sum since emergence');
  VarCreate('TSumInternode_opt',    '[°Cd]', 0, true, TSumInternode_opt, 'a function of phint and day length');

  // Define Value
  VarCreate('tsuminc', '', 0, true, Teff, 'effective day temperature, i.e. temperature above base temperature');
  // 0 = max(0,TMPM-tbase)
  VarCreate('ph39_opt',    '[°Cd]', 0, true, ph39_opt, 'a function of phint and day length');

  VarCreate('zstage', '', 0, true, zstage, 'Zadocks stages');
  VarCreate('vernf', '', 0, true, vernf, 'vernalisation factor');
  VarCreate('GS_EC25', '', 0, true, GS_EC25);
  VarCreate('d10', '', 0, true, d10, 'Day of year when EC was equal 10');
  VarCreate('d29', '', 0, true, d29, 'Day when EC equals 29');
  VarCreate('d50', '', 0, true, d50, 'Day when EC equals 50');
  VarCreate('d59', '[DOY]', 0, true, d59, 'Day when EC equals 59');
  VarCreate('d75', '', 0, true, d75, 'Day when EC equals 75');
  VarCreate('d90', '', 0, true, d90, 'Day when EC equals 90');
  VarCreate('ECa', '', 0, true, ECa);
  VarCreate('inl_MS_xstage2', '', 0, true, inl_MS_xstage2);
  VarCreate('DayOfYearSowingDate', '[DOY]', 0, true, DayofYearSowingDate);
  VarCreate('DOY_BegStemElong', '[DOY]', 0, true, DOY_BegStemElong, 'DOY for begin stem elongation');
  VarCreate('DOY_BegHeading', '[DOY]', 0, true, DOY_BegHeading, 'DOY for begin heading');
  VarCreate('DOY_EndHeading', '[DOY]', 0, true, DOY_EndHeading, 'DOY for end heading');
  VarCreate('DOY_BegFlower', '[DOY]', 0, true, DOY_BegFlower, 'DOY for begin of flowering');
  VarCreate('DOY_YellowRipeness', '[DOY]', 0, true, DOY_YellowRipeness, 'DOY for yellow ripeness');
  VarCreate('DOY_PhysRipe', '[DOY]', 0, true, DOY_PhysRipe, 'DOY for physiological ripeness');
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('CERES Wheat', [TDevelopment]);
{$ENDIF}

end;

end.
