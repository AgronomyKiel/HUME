unit Usubpartitioning_Maize;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod, UState, UAbstractPlant, UlayeredSoil,
  USubDevelopment_Maize, Usublightint_growth_Maize, USimpleRootModDM;

Type
TSLA = (SLAfGAI, SLAconst);
TDroughtImpact = (DroughtImpact, NoDroughtImpact);
TLAIe_calc = (logistisch, Log_Decay);


Tsubpartitioning_Maize = class(TAbstractPlant)

private

protected
  Curveswitch_decay: Boolean; // für Log_decay Berrechnung LAIe
  CurveswitchTSUM: real; // TSUM am Curveswitch (Umschaltpunkt der Log_decay-Funktion)
  fSLA_ : TSLA;
  fDroughtImpact_SLA : TDroughtImpact;
  fDevelopmentModel: TsubDevelopment_Maize;
  fDrymatterModel: Tsublightint_growth_Maize;
  procedure setDevelopmentModel(AModel: TsubDevelopment_Maize); virtual;
  procedure setDrymatterModel(AModel: Tsublightint_growth_Maize);
  function GetLAI:THumeNumEntity; override;
  function GetCropHeight:THumeNumEntity; override;
  function GetWLD(Index:Integer):THumeNumEntity; override;
  function getExtCoeffPAR: real; override;
  // Variables

public
  // Variables
  ACroot: TVar; // drymatter allocation coefficient for roots
  BodBedeck : TVar;   //
  LAIe : TVar;   // LAIe is the LAI which is fitted to the data sets (1 Site, 1 year, one cultivar)
  CobGr : TVar;   //
 // DMShoot : TVar;   //   State siehe unten
  fCob : TVar;   //
  fLEAF : TVar;   //
  LeafGr : TVar;   //
  ShootGR : TVar;   //
  StemGr : TVar;   //
  CropHeight : TVar; // CropHeight [m]
  XStage5 : TVar; // Date of Harvest
  TUEsim : TVar; //
  WUEsim : TVar; //  WUE zu latestharvestdate
  LAItotal : TVar; // entspricht GAI, LAIleaf (defined as green and dead leafs) +LAIstem
  SLAleaf : TVar;
  SLAstem : TVar;
  fSLAWR : TVar;
  SLAleaf_average : TVar;
  SLAstem_average : TVar;
  ExtPAR_varLAI : TVar;
  LAIgreen : TVar;  // LAI exkl. toter Blattanteile
  LAI : TVar;  //Entweder LAIe oder LAIgreen, je nach LAIkrit.
               //In jedem Fall der LAI, der an SublightInt übergeben wird.


  // State Variables
 // DMRoot: TState; // g N/m2
 // DMtot: TState; // g N/m2
  DMcob : TState;   //
  DMleaf : TState;   // g/m²
  DMStem : TState;   //
  DMShoot : TState;   //
  LAIleaf : TState;   //
  LAIstem : TState;   //
  LeafDuration : TState; //
  cumET_Veg : TState; // CumETact bis Ernte
  cumET_latestharvest : TState; // CumETact bis immer bis latest harvest date
  SEEDRV : TState;
  TSumLAI : TState;   // same value than GDD8_from_emergence,
                      // needed for the curveswitch while calculating LAIe

  // Parameters
  ACEroot: TPar; // that is the ACroot (TM-Verteilungskoeffizient für die Wurzel) at emergence
  DSstop: TPar; // DevelopmentStage when root growth stops
  LAI0 : TPar;   // parameter for LAIe calculation
  LAIkrit : TPar;  // instead of an option for LAI calculation: LAIkrit = 0.000001,
                   // LAI will be calculated by LAIgreen; LAIkrit = 10, LAI will be calculated by LAIe
  LAImax : TPar;  // parameter for LAIe calculation
  RGRL : TPar;   //  parameter for LAIe calculation
  RGRdecay : TPar; // parameter for LAIe calculation
  SLAleaf_const : TPar;   // konstante SLA
  SLAstem_const : TPar;   // konstante SLA
  SLAl_a : TPar;   // über GAI abnehmende SLA
  SLAl_b : TPar;   // über GAI abnehmende SLA
  SLAs_a : TPar;   // über GAI abnehmende SLA
  SLAs_b : TPar;   // über GAI abnehmende SLA
  SLAleafini : TPar; // initial sla leaf
  SLAstemini : TPar; // initianl sla stem
  f1fslawr: TPar;
  fSLAmin: TPar;
  psiWRsla: TPar;
  fCob_ini : TPar;   //
  fCob_steig : TPar; //
  fCob_e : TPar;   //
  fla : TPar;   //
  flb : TPar;   //
  fCropHeight : TPar;
  latestharvestdate : TPar;
  INI_DMleaf : TPar;
  k_SEEDRV : TPar; // mobilisation constant for seed reseves
  Ini_SEEDRV : TPar; // initial seed weight (g/m²)
  ExtPAR_const : TPar; //if LAI > LAIcritExtPAR, then ExtPAR_varLAI is suposed to be constant
  LAIcritExtPAR : TPar; //critical LAI value which defines the switching point of calculating the extinktion coefficient(ExtPAR_varLAI)
                  //negative linear vs. constant
  ExtPAR_steig : TPar; //if LAI < LAIcritExtPAR, then ExtPAR_varLAI is suposed to be negativ linear with LAIgreen
  g : TPar;      //Parameter for fleaf   (slope)  (holzhauser)
  h : TPar;      // Parameter for fleaf (intecept)       (holzhauser)
  fstemmin : TPar; // ca. 25% TM befinden sich zu Erntezeitpunkt noch im Stängel (Datengrundlage: Babette)  (holzhauser: 28.5%)
  decay_a: TPar;    //Parameter for calculating fleaf after Xstage=3, when leaf dry matter is translocated to stem.  (slope)      (holzhauser)
  decay_b: TPar;     //Parameter for calculating fleaf after Xstage=3, when leaf dry matter is translocated to stem.   (exponent)     (holzhauser)
  SLAleafmin: TPar;   //Second plateau for SLA   (holzhauser)
  SLAstemmin: TPar;     //Second plateau for SLAstem   (holzhauser)

  // External Variables
   DS: TExternV; // DevelopmentSage for root growth
   TempSumR: TExternV; // Temperatursumme für die Wurzelentwicklung
  CumPH : TExternV;   //
  TotTMgRate : TExternV;   //
  TLNO : TExternV;   //
  XStage : TExternV;   //
  Tempfact : TExternV;   //
  ExWld_arr : TSoilExtArray;  // Wurzellängendichten [cm.cm-3]
  WLD : TSoilVarArray;
  CumTrans : TExternV;
  ETact : TExternV; //
  psiroot:TExternV;
  Sen_fact : TExternV;
  Tbase6 : TExternV;   //
  Temp : TExternV;   //

  // Options
  OptDroughtimpact_SLA : Toption;
  OptSLA_ : Toption;
  OptLAIe_calc : TOption;

  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  Property DevelopmentModel: TsubDevelopment_Maize read fDevelopmentModel write setDevelopmentModel;
  Property DrymatterModel: Tsublightint_growth_Maize read fDrymatterModel write setDrymatterModel;
   // Variables
  Property Var_ACroot: TVar read ACroot write ACroot;
  Property Var_BodBedeck : TVar read BodBedeck write BodBedeck;
  Property Var_LAIe : TVar read LAIe write LAIe;
  Property Var_CobGr : TVar read CobGr write CobGr;
  //Property Var_DMShoot : TVar read DMShoot write DMShoot;
  Property Var_fCob : TVar read fCob write fCob;
  Property Var_fLEAF : TVar read fLEAF write fLEAF;
  Property Var_LeafGr : TVar read LeafGr write LeafGr;
  Property Var_ShootGR : TVar read ShootGR write ShootGR;
  Property Var_StemGr : TVar read StemGr write StemGr;
  Property Var_CropHeight : TVar read CropHeight write CropHeight;
  Property Var_TUEsim : TVar read TUEsim write TUEsim;
  Property Var_LAItotal : TVar read LAItotal write LAItotal;
  Property Var_SLAleaf : TVar read SLAleaf write SLAleaf;
  Property Var_SLAstem : TVar read SLAstem write SLAstem;
  Property Var_SLAleaf_average : TVar read SLAleaf_average write SLAleaf_average;
  Property Var_SLAstem_average : TVar read SLAstem_average write SLAstem_average;
  Property Var_ExtPAR_varLAI : TVar read ExtPAR_varLAI write ExtPAR_varLAI;
  Property Var_LAIgreen : TVar read LAIgreen write LAIgreen;
  Property Var_LAI : TVar read LAI write LAI;

  // State
 // Property St_DMRoot: TState read DMRoot write DMRoot;
  //Property St_DMtot: TState read DMtot write DMtot;

  Property St_DMcob : TState read DMcob write DMcob;
  Property St_DMleaf : TState read DMleaf write DMleaf;
  Property St_DMStem : TState read DMStem write DMStem;
  Property St_DMShoot : TState read DMShoot write DMShoot;
  Property St_LAIleaf : TState read LAIleaf write LAIleaf;
  Property St_LAIstem : TState read LAIstem write LAIstem;
  Property St_SEEDRV : TState read SEEDRV write SEEDRV;
  Property St_TSumLAI : TState read TSumLAI write TSumLAI;

  // Parameters
  Property Par_ACEroot: TPar read ACEroot write ACEroot;
  Property Par_DSstop: TPar read DSstop write DSstop;
  Property Par_LAI0 : TPar read LAI0 write LAI0;
  Property Par_LAIkrit : TPar read LAIkrit write LAIkrit;
  Property Par_LAImax : TPar read LAImax write LAImax;
  Property Par_RGRL : TPar read RGRL write RGRL;
  Property Par_RGRdecay : TPar read RGRdecay  write RGRdecay;
  Property Par_fCob_ini : TPar read fCob_ini write fCob_ini;
  Property Par_fCob_steig : TPar read fCob_steig write fCob_steig;
  Property Par_fCob_e : TPar read fCob_e write fCob_e;
  Property Par_fla : TPar read fla write fla;
  Property Par_flb : TPar read flb write flb;
  Property Par_SLAleaf_const : TPar read SLAleaf_const write SLAleaf_const;
  Property Par_SLAstem_const : TPar read SLAstem_const write SLAstem_const;
  Property Par_SLAl_a : TPar read SLAl_a write SLAl_a;
  Property Par_SLAl_b : TPar read SLAl_b write SLAl_b;
  Property Par_SLAs_a : TPar read SLAs_a write SLAs_a;
  Property Par_SLAs_b : TPar read SLAs_b write SLAs_b;
  Property Par_SLAleafini : TPar read SLAleafini write SLAleafini;
  Property Par_SLAstemini : TPar read SLAstemini write SLAstemini;
  Property Par_fCropHeight : TPar read fCropHeight write fCropHeight;
  Property Par_latestharvestdate : TPar read latestharvestdate write latestharvestdate;
  Property Par_INI_DMleaf : TPar read INI_DMleaf write INI_DMleaf;
  property Par_k_SEEDRV : TPar read k_SEEDRV write k_SEEDRV; // mobilisation constant for seed reseves
  property Par_Ini_SEEDRV : TPar read Ini_SEEDRV  write Ini_SEEDRV;  // initial seed weight (g/pl)
  property Par_ExtPAR_const : TPar read ExtPAR_const  write ExtPAR_const;
  property Par_LAIcritExtPAR : TPar read LAIcritExtPAR  write LAIcritExtPAR;
  property Par_ExtPAR_steig : TPar read ExtPAR_steig  write ExtPAR_steig;
  Property Par_g : TPar read g write g;
  Property Par_h : TPar read h write h;
  Property Par_fstemmin : TPar read fstemmin write fstemmin;
  Property Par_decay_a : TPar read decay_a write decay_a;
  Property Par_decay_b : TPar read decay_b write decay_b;
  Property Par_SLAleafmin : TPar read SLAleafmin write SLAleafmin;
  Property Par_SLAstemmin : TPar read SLAstemmin write SLAstemmin;

  // External Variables
  Property Ex_TempSumR: TExternV read TempSumR write TempSumR;
  Property Ex_DS: TExternV read DS write DS;
  Property Ex_CumPH : TExternV read CumPH write CumPH;
  Property Ex_TotTMgRate : TExternV read TotTMgRate write TotTMgRate;
  Property Ex_TLNO : TExternV read TLNO write TLNO;
  Property Ex_XStage : TExternV read XStage write XStage;
  Property Ex_CumTrans : TExternV read CumTrans write CumTrans;
  Property Ex_Temp : TExternV read Temp write Temp;
  Property Ex_Tbase6 : TExternV read Tbase6 write Tbase6;

  // Options
  property opt_DroughtImpact_SLA : TDroughtImpact read fDroughtImpact_SLA write fDroughtImpact_SLA;
  property opt_SLA_ : TSLA read fSLA_ write fSLA_;

end;  // SubmodelName

procedure Register;

implementation
uses Math, JCLdatetime;

procedure Tsubpartitioning_Maize.createAll;
var
i:integer;
ndx_str:string;

begin
  inherited createAll;
// Variables
VarCreate('ACroot', '[-]', 0, true, ACroot, 'Dry matter allocation coefficient for roots (DM distribution coefficient at emergence)');
VarCreate('BodBedeck', '[-]', 0, true, BodBedeck, 'Soil cover fraction (e.g., plant canopy cover)');
VarCreate('LAIe', '[m²/m²]', 0, true, LAIe, 'Fitted leaf area index (LAI) based on field data (1 site, 1 year, 1 cultivar), LAIe is only activated if');
VarCreate('CobGr', '[g/m²/d]', 0, true, CobGr, 'Cob growth rate (dry matter accumulation per day)');
VarCreate('fCob', '[-]', 0, true, fCob, 'Fraction of total aboveground biomass allocated to the cob');
VarCreate('fLEAF', '[-]', 0, true, fLEAF, 'Fraction of total aboveground biomass allocated to leaves');
VarCreate('LeafGr', '[g/m²/d]', 0, true, LeafGr, 'Leaf growth rate (dry matter accumulation per day)');
VarCreate('ShootGR', '[g/m²/d]', 0, true, ShootGR, 'Shoot growth rate (total aboveground biomass accumulation per day)');
VarCreate('StemGr', '[g/m²/d]', 0, true, StemGr, 'Stem growth rate (dry matter accumulation per day)');
VarCreate('CropHeight', '[m]', 0, true, CropHeight, 'Plant height [m]');
VarCreate('XStage5', '[day]', 0, true, XStage5, 'XStage 5 = Maturity');
VarCreate('TUEsim', '[g/l]', 0, true, TUEsim, 'Simulated transpiration use efficiency');
VarCreate('WUEsim', '[g/l]', 0, true, WUEsim, 'Simulated water use efficiency (WUE) up to latest harvest date');
VarCreate('LAItotal', '[m²/m²]', 0, true, LAItotal, 'Total green area index (leaves + stems) – equivalent to GAI');
VarCreate('SLAleaf', '[m²/g]', 0, true, SLAleaf, 'Specific leaf area of leaves (leaf area per unit dry mass)');
VarCreate('SLAstem', '[m²/g]', 0, true, SLAstem, 'Specific stem area (stem area per unit dry mass)');
VarCreate('fSLAWR', '[-]', 0, true, fSLAWR, '?');
VarCreate('SLAleaf_average', '[m²/g]', 0, true, SLAleaf_average, '?');
VarCreate('SLAstem_average', '[m²/g]', 0, true, SLAstem_average, '?');
VarCreate('ExtPAR_varLAI', '[-]', 0, true, ExtPAR_varLAI, 'Variable extinction coefficient for PAR (light extinction)');
VarCreate('LAIgreen', '[m²/m²]', 0, true, LAIgreen, 'Green leaf area index (only living leaf tissue)');
VarCreate('LAI', '[m²/m²]', 0, true, LAI, 'Leaf area index (LAI) – either LAIe or LAIgreen, depending on parameter LAIkrit. Used as input to SublightInt.');

// State Variables
StateCreate('DMcob', '[g/m²]', 0, true, DMcob, 'dry matter accumulation of reproductive organs [g/m²]');
StateCreate('DMleaf', '[g/m²]', 0, true, DMleaf, 'Leaf dry matter accumulation [g/m²]');
StateCreate('DMStem', '[g/m²]', 0, true, DMStem, 'Stem dry matter accumulation [g/m²]');
StateCreate('DMShoot', '[g/m²]', 0, true, DMShoot, 'Total aboveground dry matter [g/m²]');
StateCreate('LAIleaf', '[m²/m²]', 0, true, LAIleaf, 'Leaf area index (only leaves) [m²/m²]');
StateCreate('LAIstem', '[m²/m²]', 0, true, LAIstem, 'Stem area index [m²/m²]');
StateCreate('LeafDuration', '', 0, true, LeafDuration, '?');
StateCreate('cumET_Veg', '[mm]', 0, true, cumET_Veg, 'Cumulative evapotranspiration during vegetative phase [mm]');
StateCreate('cumET_latestharvest', '[mm]', 0, true, cumET_latestharvest, 'Cumulative actual evapotranspiration up to latest_harvestdate (parameter) [mm]');
StateCreate('SEEDRV', '[g/m²]', 0, true, SEEDRV, 'Seed reserve dry matter (e.g., starch, protein) [g/m²]');
StateCreate('TSumLAI', '[°C*d]', 0, true, TSumLAI, 'Cumulative thermal time since emergence (used for LAI curve switching, same value than GDD8_from_emergence)');

// Parameters
ParCreate('ACEroot', '[-]', 0.35, ACEroot, 'Initial ACroot at emergence (root dry matter allocation coefficient)');
ParCreate('DSstop', '[-]', 1.15, DSstop, 'Development (DS) stage at which root growth stops');
ParCreate('g', '[-]', -0.2934, g, 'Slope parameter for leaf biomass fraction (Holzhauser model)');
ParCreate('h', '[-]', 1.0318, h, 'Intercept parameter for leaf biomass fraction (Holzhauser model)');
ParCreate('fstemmin', '[-]', 0.285, fstemmin, 'Minimum stem biomass fraction at harvest (~28.5%, based on Wienforth data)');
ParCreate('decay_a', '[-]', -0.000000000000003232, decay_a, 'Decay parameter for leaf biomass after XStage=3 (slope)(Holzhauser model)');
ParCreate('decay_b', '[-]', 22.32, decay_b, 'Decay parameter for leaf biomass after XStage=3 (exponent)(Holzhauser model)');
ParCreate('SLAleafmin', '[m²/g]', 0.01644612, SLAleafmin, 'Minimum specific leaf area (second plateau),Lower limit of the negative exponential relation between LAI and SLA');
ParCreate('SLAstemmin', '[m²/g]', 0.0005716101, SLAstemmin, 'Minimum specific stem area (second plateau), Lower limit of the negative exponential relation between SAI and SSA');
ParCreate('LAI0', '[m²/m²]', 0.02, LAI0, 'Base LAI at emergence (for LAIe calculation)');
ParCreate('LAIkrit', '[-]', 0.2, LAIkrit, 'Critical LAI threshold: if LAIkrit < 1 LAIgreen is activated; if LAIkrit >= 10 LAIe is activated');
ParCreate('LAImax', '[m²/m²]', 5, LAImax, 'Maximum possible LAI (for LAIe calculation)');
ParCreate('RGRL', '[-]', 0.0025, RGRL, 'Relative growth rate limit (LAIe calculation)');
ParCreate('RGRdecay', '[-]', 0.0025, RGRdecay, 'Decay factor for RGR (exponential decline)');
ParCreate('fCob_ini', '[-]', 0.0990676997, fCob_ini, 'Intercept of cob fraction increase');
ParCreate('fCob_steig', '[-]', 0.6092739, fCob_steig, 'Slope of linear cob fraction increase over development stage');
ParCreate('fCob_e', '[-]', 1.01273817, fCob_e, 'Final cob fraction at maturity (not used)');
ParCreate('fla', '[-]', 1.74, fla, 'Parameter for allometric leaf fraction calculation (1/(1+exp(flb.v)*fla.v*power(DMleaf.v,(fla.v-1)) not activated');
ParCreate('flb', '[-]', -3.8, flb, 'Parameter for allometric leaf fraction calculation  (1/(1+exp(flb.v)*fla.v*power(DMleaf.v,(fla.v-1)), not activated');
ParCreate('SLAleaf_const', '[m²/g]', 0.02109903, SLAleaf_const, 'Constant specific leaf area (when option is on SLAconst)');
ParCreate('SLAstem_const', '[m²/g]', 0.00149819299, SLAstem_const, 'Constant specific stem area (when option is on SLAconst)');
ParCreate('SLAl_a', '[-]', 0.0221, SLAl_a, 'Parameter for decreasing SLA with GAI (leaves)');
ParCreate('SLAl_b', '[-]', 0.1222, SLAl_b, 'Parameter for decreasing SLA with GAI (leaves)');
ParCreate('SLAs_a', '[-]', 0.0014, SLAs_a, 'Parameter for decreasing SLA with GAI (stems)');
ParCreate('SLAs_b', '[-]', 0.4329, SLAs_b, 'Parameter for decreasing SLA with GAI (stems)');
ParCreate('SLAleafini', '[m²/g]', 0.0360954, SLAleafini, 'Upper limit of the negative exponential relation between LAI and SLA');
ParCreate('SLAstemini', '[m²/g]', 0.004444, SLAstemini, 'Upper limit of the negative exponential relation between SAI and SSA');
ParCreate('fCropHeight', '[-]', 0.61, fCropHeight, 'Scaling factor for crop height development (linear increse?)');
ParCreate('latestharvestdate', '[day]', 293, latestharvestdate, 'Latest harvest date (simulation end date), no impact');
ParCreate('INI_DMleaf', '[g/m²]', 0.006, INI_DMleaf, 'Initial leaf dry matter at emergence');
ParCreate('k_SEEDRV', '[-]', 0.15, k_SEEDRV, 'Mobilization constant for seed reserves');
ParCreate('Ini_SEEDRV', '[g/m²]', 3.5, Ini_SEEDRV, 'Initial seed reserve dry matter');
ParCreate('f1fslawr', '[-]', 0.2, f1fslawr, 'Factor for SLA adjustment under root stress (option = DroughtImpact)');
ParCreate('psiWRsla', '[pF]', 2.8, psiWRsla, 'Critical root water potential for SLA reduction (option = DroughtImpact)');
ParCreate('fSLAmin', '[-]', 0.7, fSLAmin, 'Minimum SLA adjustment factor, (option = DroughtImpact)');
ParCreate('ExtPAR_const', '[-]', 0.6537485, ExtPAR_const, 'Constant extinction coefficient for PAR (when LAI > LAIcritExtPAR)');
ParCreate('LAIcritExtPAR', '[m²/m²]', 1.932764, LAIcritExtPAR, 'Critical LAI threshold for switching extinction coefficient (linear vs. constant)');
ParCreate('ExtPAR_steig', '[-]', -0.05330567, ExtPAR_steig, 'Slope of linear extinction coefficient (when LAI < LAIcritExtPAR)');

// External Variables
ExternVCreate('DS', '[-]', statefield, DS, 'Development stage of roots');
ExternVCreate('TempSumR', '[°C*d]', statefield, TempSumR, 'Cumulative temperature sum for root development');
ExternVCreate('CumPH', '[-]', statefield, CumPH, 'Cumulative phyllochron');
ExternVCreate('TotTMgRate', '[g/m²/d]', statefield, TotTMgRate, 'Total dry matter production rate');
ExternVCreate('TLNO', '[-]', statefield, TLNO, 'Total leave number');
ExternVCreate('CumTrans', '[mm]', statefield, CumTrans, 'Cumulative transpiration');
ExternVCreate('XStage', '[-]', statefield, XStage, 'Numeric development stages 1-5');
ExternVCreate('Tempfact', '[-]', statefield, Tempfact, 'Temperature factor influencing dry matter production (0–1)');
ExternVCreate('CumET', '[mm]', ratefield, ETact, 'Cumulative evapotranspiration');
ExternVCreate('psiroot', '[MPa]', statefield, psiroot, 'Root water potential');
ExternVCreate('Sen_fact', '[-]', statefield, Sen_fact, 'Senescence factor (leaf decay rate)');
ExternVCreate('Temp', '[°C]', statefield, Temp, 'Daily mean temperature');
ExternVCreate('Tbase6', '[°C]', statefield, Tbase6, 'Base temperature for development (Tbase6)');
  
  // Options
  OptCreate('optDroughtimpact_SLA', 'DroughtImpact', optDroughtimpact_SLA);
  optDroughtimpact_SLA.OptionList.Clear;
  optDroughtimpact_SLA.OptionList.Add('DroughtImpact');
  optDroughtimpact_SLA.OptionList.Add('NoDroughtImpact');

  OptCreate('optSLA_', 'SLA', optSLA_, 'SLAfGAI: SLA and SSA decrease with increasing LAI or SAI, SLAconst: constant SLA');
  optSLA_.OptionList.Clear;
  optSLA_.OptionList.Add('SLAfGAI');
  optSLA_.OptionList.Add('SLAconst');

  OptCreate('optLAIe_calc', 'logistisch', optLAIe_calc);
  optLAIe_calc.OptionList.Clear;
  optLAIe_calc.OptionList.Add('logistisch');
  optLAIe_calc.OptionList.Add('Log_Decay');
  WithRoots := true;

//  self.SoilLayerMod := TPlantRelatedSubMod(self.GlobMod.SubModel[3]);
  if (WithRoots = true) and (soillayermod <> nil) then begin
    for i := 1 to tlayeredsoil(soillayermod).p_NComp do begin
      if i <= 9 then
        ndx_str := '_'+IntTostr(i)
      else
        ndx_str := IntTostr(i);

      ExternVCreate('WLD_'+ndx_str,'[cm/cm3]',StateField, exWLD_arr[i]);
      VarCreate ('WLD_'+ ndx_str,'',0,true, WLD[i]);
    end;
  end;

end;



procedure Tsubpartitioning_Maize.init(var GlobMod: TMod);
var
  i: integer;
  ndx_str :string;

begin
  inherited init(GlobMod);
  DMcob.v := 0;
  DMleaf.v := 0;
  DMStem.v := 0;
  XStage5.v := 0;
  cumET_Veg.v := 0;
  cumET_latestharvest.v := 0;
  TSumLAI.v := 0;
  CurveswitchTSUM := 0;
  Curveswitch_decay:=false;

  if uppercase(optSLA_.option) = uppercase('SLAfGAI') then
    fSLA_ := SLAfGAI;
  if uppercase (optSLA_.option) = uppercase('SLAconst') then
    fSLA_ := SLAconst;
  if optDroughtimpact_SLA.option = 'droughtimpact' then
    fdroughtimpact_SLA := DroughtImpact;
  if optDroughtimpact_SLA.option = 'nodroughtimpact' then
    fdroughtimpact_SLA := noDroughtImpact;

{  if (WithRoots = true) and (soillayermod <> nil) then begin
    for i := 1 to tlayeredsoil(soillayermod).p_NComp do begin
      if i <= 9 then
        ndx_str := '_'+IntTostr(i)
      else
        ndx_str := IntTostr(i);

      if ExWLD_arr[i] = nil then ExternVCreate('WLD_'+inttostr(i),'[cm/cm3]',StateField, exWLD_arr[i]);
      if WLD[i] = nil then VarCreate ('WLD'+inttostr(i),'',0,true, WLD[i]);
    end;
  end;   }

end;


procedure Tsubpartitioning_Maize.CalcRates;
var
  i:integer;
begin
  DMtotal.c := TotTMgRate.v;
  ExtPAR_varLAI.v := ExtCoeffPAR;

  If (XSTAGE.v >= 1) and (XSTAGE.v < 2) and (SEEDRV.v > 0) then
  begin
    SEEDRV.c := max(-SEEDRV.v, -k_SEEDRV.v * Tempfact.v);
    DMtotal.c := DMtotal.c - SEEDRV.c; // Addition of seed reserves to DMtot
  end
  else
    SEEDRV.c := 0;
  ACroot.v := max(0, ACEroot.v - DS.v * ACEroot.v / DSstop.v);
  DMFineRoot.c := DMtotal.c * ACroot.v;
  ShootGR.v := DMtotal.c * (1 - ACroot.v);

  //TM Verteilung nach Holzhauser und Bukowiecki 2024 über XStages
  //Ausgerautete Formeln ist vorherigige Partitioning nach Ratjen et al (2018) und Wienforth (Diss: 2011)
  If  (XStage.v>=1) and  (LAI.v<5.5)  //   (CumPH.v<TLNO.v-2)
   then  fleaf.v := h.v + (g.v*XSTAGE.v) //  1/(1+exp(flb.v)*fla.v*power(DMleaf.v,(fla.v-1)))
   else  fleaf.v := decay_a.v *power(XSTAGE.v,decay_b.v);   // 0;
  LeafGr.v := fLEAF.v * ShootGR.v;
  fCob.v := max(0, fCob_steig.v * XSTAGE.v + fCob_ini.v);

  // If (XStage.v>2) then begin
  // If (XStage.v<=(ln((fCob_steig.v/fCob_e.v)/fCob_ini.v)/fCob_e.v)+2)
  // then fCob.v := fCob_ini.v*exp(fCob_e.v*(XStage.v-2))
  // else fCob.v := fCob_steig.v*XStage.v+fCob_steig.v/fCob_e.v-fCob_steig.v*(ln((fCob_steig.v/fCob_e.v)/fCob_ini.v)/fCob_e.v+2);
  // end
  // else fcob.v :=0;

   If DMStem.v <= fstemmin.v*DMShoot.v then fCob.v:= min(1,fCob.v); // 0.25576 resultieren
  // aus den Messdaten, ca. 25% vom Spross sind zum Erntezeitpunkt noch Stängel.

  fCob.v := fCob.v / (1 + fLEAF.v); // Umrechnung vom Anteil an Kolben+Stängel auf Anteil an Spross.
  CobGr.v := ShootGR.v * fCob.v;
  StemGr.v := (1 - fLEAF.v - fCob.v) * ShootGR.v;

  DMcob.c := CobGr.v;
  DMleaf.c := LeafGr.v;
  DMStem.c := StemGr.v;
  DMShoot.c := ShootGR.v;


  If (LAI.v > 0) or (SEEDRV.c <> 0) then

  begin
    If (fSLA_ = SLAfGAI) then
    begin
       SLAleaf.v := max(SLAleafmin.v,min(SLAleafini.v,SLAl_a.v*power(LAIleaf.v,SLAl_b.v)+SLAl_a.v*SLAl_b.v*power(LAIleaf.v,SLAl_b.v-1)*LAIleaf.v));
      // SLAleaf.v := min(SLAleafini.v,SLAl_a.v*power(LAI.v,SLAl_b.v))
       SLAstem.v := max(SLAstemmin.v,min(SLAstemini.v,SLAs_a.v*power(LAIstem.v,SLAs_b.v)+SLAs_a.v*SLAs_b.v*power(LAIstem.v,SLAs_b.v-1)*LAIstem.v));
      // SLAstem.v := min(SLAstemini.v,SLAs_a.v*power(LAI.v,SLAs_b.v))
    end;
    // else
    // begin
    If (fSLA_ = SLAconst) then
    begin
      SLAleaf.v := SLAleaf_const.v;
      SLAstem.v := SLAstem_const.v;
    end;
    If (fDroughtImpact_SLA = droughtimpact) then
      fSLAWR.v := min(1, max(1 - f1fslawr.v * (psiroot.v - psiWRsla.v),
          fSLAmin.v))
    else
      fSLAWR.v := 1;
    SLAleaf.v := SLAleaf.v * fSLAWR.v;
    LAIleaf.c := SLAleaf.v * LeafGr.v; // Berechnung des LAIleafs unter der Annahme einer über den LAI sinkenden SLA
    LAIstem.c := SLAstem.v * StemGr.v; // Berechnung des LAIstem unter der Annahme einer über den LAI sinkenden SLA
    // LAIleaf.c :=  SLAleaf_const.v*LeafGr.v;  // Berechnung des LAIleafs unter der Annahme einer konstanten SLA
    // LAIstem.c :=  SLAstem_const.v*StemGr.v;  // Berechnung des LAIleafs unter der Annahme einer konstanten SLA
  end;


   If  XStage.v>=1
       then  TSumLAI.c := max(Temp.v-Tbase6.v,0)
       else  TSumLAI.c := 0;

   If (optLAIe_calc.Option = 'logistisch') then
      If  XStage.v>=1
       then  LAIe.v :=   LAImax.v/(1+(LAImax.v/LAI0.v-1)*exp(-LAImax.v*RGRL.v*TSumLAI.v))
       else  If  (XStage.v>=1) and (LAIe.v<=LAIkrit.v)
             then  LAIe.v :=min(2,LAI0.v*exp(RGRL.v*TSUMLAI.v))
             else  LAIe.v :=0;
   If (optLAIe_calc.Option = 'log_decay') then
      If  XStage.v>=1
        then begin
             LAIe.v :=   LAImax.v/(1+(LAImax.v/LAI0.v-1)*exp(-LAImax.v*RGRL.v*TSumLAI.v));
             If (LAIe.v >= 0.99*LAImax.v) or Curveswitch_decay then begin
                If Curveswitch_decay = false then begin
                   CurveswitchTSUM := TSUMLAI.v;
                   Curveswitch_decay := true;
                end;
                LAIe.v := max (0, Laimax.v - 0.01*LAImax.v * exp((TSUMLAI.v-CurveswitchTSUM)* RGRdecay.v));
             end;
        end
        else  If  (XStage.v>=1) and (LAIe.v<=LAIkrit.v)
             then  LAIe.v :=min(2,LAI0.v*exp(RGRL.v*TSUMLAI.v))
             else  LAIe.v :=0;

   LAIgreen.v:= max (0,(1-Sen_fact.v)*(LAIleaf.v+LAIleaf.c)+(LAIstem.v+LAIstem.c));
  //wichtig: LAIe ist nur aktiv, wenn man für LAIkrit einen höheren Wert setzt. (Option)
   If  LAIe.v<LAIkrit.v
       then LAI.v := LAIe.v
       else LAI.v := LAIgreen.v;

   LeafDuration.c := LAI.v + (LAIleaf.c + LAIstem.c)* 0.5;
   //BodBedeck.v :=  (1-exp(-exkPAR.v*LAI.v));
   BodBedeck.v :=  (1-exp(-ExtPAR_varLAI.v*LAI.v));

   if (WithRoots = true) and (soillayermod <> nil) then
    for i := 1 to tlayeredsoil(soillayermod).p_NComp
      do WLD[i].v := ExWLD_arr[i].v;

   //If (XStage.v>=5) or (dayoftheyear(Globtime.v)>=latestharvestdate.v)or (XStage5.v>0) then begin
   If (XStage.v>=5) or (Globtime.v >=latestharvestdate.v)or (XStage5.v>0) then begin
      LAI.v := 0;
      If XStage5.v=0 then XStage5.v := dayoftheyear(Globtime.v);
   end;
   If (XStage.v>=1) and (XStage5.v=0) then cumET_Veg.c := ETact.v else cumET_Veg.c := 0;
   If (XStage.v>0) and (XStage5.v=0) then cumET_latestharvest.c := ETact.v else cumET_latestharvest.c := 0;
end;

procedure Tsubpartitioning_Maize.integrate;
begin
  inherited;
   If (XSTAGE.v>=1) and (DMleaf.v<=0)then begin
    DMleaf.v   := INI_DMleaf.v;                      // Initialize leaf weight
    DMstem.v  := exp(fla.v*ln(DMleaf.v)+flb.v);         // Initialize stem weight
    SEEDRV.v    := Ini_SEEDRV.v;// 0.05; // 0.012;
    LAIleaf.v :=  SLAleafini.v*DMleaf.v;
    LAIstem.v :=  SLAstemini.v*DMStem.v;
    LAItotal.v := LAIleaf.v+LAIstem.v;
    LAIgreen.v := LAI.v;
   // NLeaf_pl.v  := LFWT_pl.v * NOptLeaf.v/100;
   // NStem_pl.v  := STMWT_pl.v * NOptStem.v/100;
   // NShoot_pl.v := NLeaf_pl.v + NStem_pl.v;
  end;
  DMShoot.v :=  DMleaf.v+DMStem.v+DMCob.v;
  LAItotal.v := LAIleaf.v+LAIstem.v;
  CropHeight.v :=0.289441+DMShoot.v*0.002721573-0.0000007798244*power(DMShoot.v,2); //LAItotal.v*fCropHeight.v;   (bukowiecki)
  If DMleaf.v>0 then
     SLAleaf_average.v:= LAIleaf.v/DMleaf.v;
  If DMstem.v>0 then
     SLAstem_average.v:= LAIstem.v/DMstem.v;
  // LeafDuration.c := LAI.v;
  //LeafDuration.c := LAI.v * 0.5;
  If CumTrans.v > 0 then TUEsim.v := min(50,DMShoot.v/CumTrans.v) else TUEsim.v := 0;
  If CumET_latestharvest.v > 0 then WUEsim.v := DMShoot.v/CumET_latestharvest.v else WUEsim.v := 0;
  // Initialise growth at emergence
end;

procedure Tsubpartitioning_Maize.setDevelopmentModel(AModel: TsubDevelopment_Maize);
begin
  fDevelopmentModel := AModel;
  CumPH.Search := false;
  CumPH.f_v := @DevelopmentModel.CumPH.fv;
  CumPH.Source := '['+DevelopmentModel.Name+']';
  TLNO.Search := false;
  TLNO.f_v := @DevelopmentModel.TLNO.fv;
  TLNO.Source := '['+DevelopmentModel.Name+']';
  XStage.Search := false;
  XStage.f_v := @DevelopmentModel.XStage.fv;
  XStage.Source := '['+DevelopmentModel.Name+']';
  Sen_fact.Search := false;
  Sen_fact.f_v := @DevelopmentModel.Sen_fact.fv;
  Sen_fact.Source := '['+DevelopmentModel.Name+']';
  Tbase6.Search := false;
  Tbase6.f_v := @DevelopmentModel.Tbase6.fv;
  Tbase6.Source := '['+DevelopmentModel.Name+']';

  if DrymatterModel is Tsublightint_growth_Maize then begin
    DrymatterModel.XStage.Search := false;
    DrymatterModel.XStage.setPointer(@DevelopmentModel.XStage.fv);
    DrymatterModel.XStage.Source := '['+DevelopmentModel.Name+']';
    DrymatterModel.IStage.Search := false;
    DrymatterModel.IStage.setPointer(@DevelopmentModel.IStage.fv);
    DrymatterModel.IStage.Source := '['+DevelopmentModel.Name+']';
    DrymatterModel.Tbase6.Search := false;
    DrymatterModel.Tbase6.setPointer(@DevelopmentModel.Tbase6.fv);
    DrymatterModel.Tbase6.Source := '['+DevelopmentModel.Name+']';
  end;
end;

procedure Tsubpartitioning_Maize.setDrymatterModel(AModel: Tsublightint_growth_Maize);
begin
  fDrymatterModel := AModel;
  TempFact.Search := false;
  TempFact.f_v := @DrymatterModel.TempFact.fv;
  TempFact.Source := '['+DrymatterModel.Name+']';
  TotTMgRate.Search := false;
  TotTMgRate.f_v := @DrymatterModel.TotTMgRate.fv;
  TotTMgRate.Source := '['+DrymatterModel.Name+']';

  DrymatterModel.ExtPAR_varLAI.Search := false;
  DrymatterModel.ExtPAR_varLAI.setPointer(@ExtPAR_varLAI.fv);
  DrymatterModel.ExtPAR_varLAI.Source := '['+Name+']';
  DrymatterModel.LAI.Search := false;
  DrymatterModel.LAI.setPointer(@LAI.fv);
  DrymatterModel.LAI.Source := '['+Name+']';

  if DevelopmentModel is TsubDevelopment_Maize then begin
    DrymatterModel.XStage.Search := false;
    DrymatterModel.XStage.setPointer(@DevelopmentModel.XStage.fv);
    DrymatterModel.XStage.Source := '['+DevelopmentModel.Name+']';
    DrymatterModel.IStage.Search := false;
    DrymatterModel.IStage.setPointer(@DevelopmentModel.IStage.fv);
    DrymatterModel.IStage.Source := '['+DevelopmentModel.Name+']';
    DrymatterModel.Tbase6.Search := false;
    DrymatterModel.Tbase6.setPointer(@DevelopmentModel.Tbase6.fv);
    DrymatterModel.Tbase6.Source := '['+DevelopmentModel.Name+']';
  end;
end;


function Tsubpartitioning_Maize.GetLAI:THumeNumEntity;
begin
  result:= LAI;
end;
function Tsubpartitioning_Maize.GetCropHeight:THumeNumEntity;
begin
  result:= CropHeight;
end;
function Tsubpartitioning_Maize.GetWLD(Index:Integer):THumeNumEntity;
begin
  result:=WLD[index];
end;
function Tsubpartitioning_Maize.getExtCoeffPAR: real;
begin
  if LAI.v > LAIcritExtPAR.v then
  result:=  ExtPAR_const.v
  else result:= ExtPAR_steig.v*(LAI.v-LAIcritExtPAR.v)+ExtPAR_const.v;
end;

procedure Register;
begin
  RegisterComponents('Maize', [Tsubpartitioning_Maize]);
end;

end.