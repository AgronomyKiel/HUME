

unit Development; // Kopfzeile

interface  // bestimmt, was in der Unit von außen zugänglich ist

uses // Benennung von Units (Prozedurbibliotheken), die von der aktuellen Unit
// verwendet werden
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    UMeasValue,          // HUME: MeasValue and TMeasList, handling measurement data

  UMod, UState, Math;

type   //Typdekleration des Formularobjektes (enthält alle Komponenten,
//die auf dem Formular angeordnet sind, sowie die zum Formular gehörenden
//Prozeduren)

  TDataInitMethod = (EC_Date, Days_to_EC);  // Varianten für Dateninput
  TOptTSumInternode = (constant, daylength);

  TDevelopment = class(TSubmodel)
  private
    fReCalcSowingDate : boolean;
    fTSumInternode :TOptTSumInternode;
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
      protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    devrates1,    // developmet rate during istage 1
    devrates2,    // developmet rate during istage 2
    devrates3,    // developmet rate during istage 3
    devrates4,    // developmet rate during istage 4
    devrates5,    // developmet rate during istage 5
    devrates6,    // developmet rate during istage 6
    devrates9,    // developmet rate during istage 9
    dvs10,        // xstage times 10, for convenience of plotting
    istage,

    //   Phenologicalstages in integer values
    // 1 Emergence to terminal spikelet(TS),
    // 2 TS to endof vegetative growth
    // 3 end of vegetative growth to beginning of pre-anthesis ear growth
    // 4 Pre-anthesis ear growth to beginning of grain filling (anthesis occurs during this phase)
    // 5 Beginning of grain fill to physiological maturity
    // 6 Physiological maturity to fallow (harvest)
    // 7 Fallow to sowing
    // 8 Sowing to germination
    // 9 germination to emergence

    rdr_p,   // relative development rate of photoperiod
    rdr_v,   // relative development rate of vernalization
    tsuminc, //Tagestemperatur >=0 zur Basistemperatur
    zstage,  //Zadock's stages
    vernf: TVar; // vernalisationfactor
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

    c,                  // variable photoperiodic influence factor (0..1)
    k_v,                // vernalisation variable
    tempsumemergence,
    d10,     // Day when EC equals 10
    d29,     // Day when EC equals 29
    d50,     // Day when EC equals 50
    d75,     // Day when EC equals 75
    d90,     // Day when EC equals 90
    DOY_BegStemElong,
    DOY_BegFlower,
    DOY_PhysRipe,
    ECa,
    DayOfYearSowingDate  // Dayof Year of sowingdate
     : TVar;

    DaySSow,     // days since sowing
    cumvern,    // cumulative vernalisation

    ec,         // EC stage
    tdu,        // thermal developmental units
    tsums,      // temperature sum since sowing
    xstage,     // non integer growth stage indicator ranging from zero to six
    nL_MS,      // number of leaves on main stem
    TSumEC30,    // Temperature sum since EC30
    TSum_until_EC_30,    // Temperature sum until EC30
    TSum_until_EC_37,    // Temperature sum until EC37

    inL_MS      // initial leaf number on main stem
       : TState;
    inl_MS_xstage2 : TVar;// Anzahl nicht ausgebildeter Blätter zum Zeitpunkt Xstage 2
    
    daylengthp, // photoperiodic daylength
    TMPM,       // mean air temperature
    dayofyear: TExternV;

    Ph39,        // TSUM 37 bis 39
    p1d,        // genetic specific parameter of photoperiod sensitivity
    p1v,        // genetic specific parameter of vernalisation sensitivity
    sdepth,     // sowing depth (cm), not actual in use
    phint,      // the phyllochron interval, the interval in thermal time
                //(degree days) between successive leaf and tiller appearances
    p3,         // End of leaf growth and beginning of ear growth to end of pre-anthesis ear growth
    p4,         // thermal time between Pre-anthesis ear growth to beginning of
                // grain filling (anthesis occurs during this phase)in°Cd
    p5,         // thermal time between beginning of grain fill and maturity in°Cd
    p9,         // thermal timen from germination to seedling emergence in °Cd
    tBase,      // base temperature
    Internode,  // Multiplikator des Phyllochronintervalls in der Schossenphase
    sowingdate,
    plastochron,  // interval in thermal time between leaf initiation
    ini_inLMS,    // initial number of initiated leaves at emergence
    xstage_fin_leaf_prim, // xstage an dem kiene weiteren leaf primordien angelegt werden



    TSumInternode, // te´mperature sumd between two internodes
    minLeaf_number,
    MaxVernDays,    // maximum number of vernalisation days which increase developmental rate
    MaxPhotoperiod, // maximum daylength which increase developmental rate
    VernMinTemp,    // minimum vernalisation temperature
    VernOptTemp1,   // temperature where vernalisation is starting to be optimal
    VernOptTemp2,   // temperature where vernalisation is ending to be optimal
    VernMaxTemp,     // temperature where vernalisation is getting zero
    fdl              // weighting factor for daylength influence
    : TPar;


    DataInitMethod : Toption;
    OptTSumInternode: TOption;

    procedure createAll; override;//erweitern, existiert schon
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
    procedure addDataValueToDataSeries; override;
    procedure AddSimValueToDataSeries; override;

  published

   property Var_c : TVar read c write c; // Define Value
   property Var_devrates1 : TVar read devrates1 write devrates1;
   property Var_devrates2 : TVar read devrates2 write devrates2;
   property Var_devrates3 : TVar read devrates3 write devrates3;
   property Var_devrates4 : TVar read devrates4 write devrates4;
   property Var_devrates5 : TVar read devrates5 write devrates5;
   property Var_devrates6 : TVar read devrates6 write devrates6;
   property Var_devrates9 : TVar read devrates9 write devrates9;
   property Var_dvs10 : TVar read dvs10 write dvs10;
   property Var_istage : TVar read istage write istage;
   property Var_k_v : TVar read k_v write k_v; // Define Value
   property Var_rdr_p : TVar read rdr_p write rdr_p;
   property Var_rdr_v : TVar read rdr_v write rdr_v;

   property Var_tempsumemergence : TVar read tempsumemergence write tempsumemergence; // Define Value
   property Var_tsuminc : TVar read tsuminc write tsuminc;
   property Var_zstage : TVar read zstage write zstage;
   property Var_vernf : TVar read vernf write vernf;
   property Var_d10 : TVar read d10 write d10;
   property Var_d29 : TVar read d29 write d29;
   property Var_DOY_BegStemElong: TVar read DOY_BegStemElong write DOY_BegStemElong;
   property Var_DOY_BegFlower: TVar read DOY_BegFlower write DOY_BegFlower;
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

   property Par_p9 : TPar read p9 write p9; // Define Value
   property Par_p4 : TPar read p4 write p4; // Define Value
   property Par_p5 : TPar read p5 write p5; // Define Value
   property Par_minLeaf_number : TPar read minLeaf_number write minLeaf_number;
   property Par_plastochron : TPar read plastochron write plastochron;
   property Par_phint : TPar read phint write phint;
   property Par_Ini_inLMS : TPar read Ini_inLMS write Ini_inLMS;
   //property Par_TsumInternode : TPar read TsumInternode write TsumInternode;
   property PAR_sowingdate: TPar read sowingdate write sowingdate;
   property PAR_MaxVernDays: TPar read MaxVernDays write MaxVernDays;
   property PAR_MaxPhotoperiod: TPar read MaxPhotoperiod write MaxPhotoperiod;
   property PAR_VernMinTemp: TPar read VernMinTemp write VernMinTemp;    // minimum vernalisation temperature
   property PAR_VernOptTemp1: TPar read VernOptTemp1 write VernOptTemp1;   // temperature where vernalisation is starting to be optimal
   property PAR_VernOptTemp2: TPar read VernOptTemp2 write VernOptTemp2;   // temperature where vernalisation is ending to be optimal
   property PAR_VernMaxTemp: TPar read VernMaxTemp write VernMaxTemp;     // temperature where vernalisation is getting zero

   property Opt_DataIniMethod : TOption read DataInitMethod write DataInitMethod;
   property Opt_ReCalcSowingDate : boolean read fReCalcSowingDate write fReCalcSowingDate;
    { Published-Deklarationen }

  end;  // bis hier Deklarationen, die von anderen Units oder dem Programm
        //genutzt werden können

procedure Register;

implementation

uses UModUtils, DateUtils;

procedure TDevelopment.createall;
begin
  inherited createAll;//Möglichkeit, die Methoden des Vorgängermodells
  //aufzurufen, so daß mit einer einzigen Anweisung die ganze Funktionalität der
  // Vorgängermethoden übernommen werden
   VarCreate('c', '', 0, true, c); // Define Value
   VarCreate('devrates1', '', 0, true, devrates1);
   VarCreate('devrates2', '', 0, true, devrates2);
   VarCreate('devrates3', '', 0, true, devrates3);
   VarCreate('devrates4', '', 0, true, devrates4);
   VarCreate('devrates5', '', 0, true, devrates5);
   VarCreate('devrates6', '', 0, true, devrates6);
   VarCreate('devrates9', '', 0, true, devrates9);
   VarCreate('dvs10', '', 0, true, dvs10);
   VarCreate('istage', '', 0, true, istage);
   VarCreate('k_v', '', 0, true, k_v); // Define Value
   VarCreate('rdr_p', '', 0, true, rdr_p);
   VarCreate('rdr_v', '', 0, true, rdr_v);
   VarCreate('TSEC32', '', 0, true, TSEC32,'Date of BBCH32 (needed for calibration');
   VarCreate('TSEC33', '', 0, true, TSEC33,'Date of BBCH33 (needed for calibration');
   VarCreate('TSEC37', '', 0, true, TSEC37,'Date of BBCH37 (needed for calibration');
   VarCreate('TSEC38', '', 0, true, TSEC38,'Date of BBCH38 (needed for calibration');
   VarCreate('TSEC57', '', 0, true, TSEC57,'Date of BBCH57 (needed for calibration');
   VarCreate('TSEC59', '', 0, true, TSEC59,'Date of BBCH59 (needed for calibration');
   VarCreate('TSEC61', '', 0, true, TSEC61,'Date of BBCH61 (needed for calibration');
   VarCreate('TSEC65', '', 0, true, TSEC65,'Date of BBCH65 (needed for calibration');
   VarCreate('TSEC69', '', 0, true, TSEC69,'Date of BBCH69 (needed for calibration');
   VarCreate('TSEC71', '', 0, true, TSEC71,'Date of BBCH71 (needed for calibration');

   VarCreate('tempsumemergence', '', 0, true, tempsumemergence); // Define Value
   VarCreate('tsuminc', '', 0, true, tsuminc); // 0 = max(0,TMPM-tbase)
   VarCreate('zstage', '', 0, true, zstage);
   VarCreate('vernf', '', 0, true, vernf);
   VarCreate('GS_EC25', '', 0, true, GS_EC25);

   VarCreate('d10', '', 0, true, d10);
   VarCreate('d29', '', 0, true, d29);
   VarCreate('d50', '', 0, true, d50,'Day when EC equals 50');
   VarCreate('d75', '', 0, true, d75,'Day when EC equals 75');
   VarCreate('d90', '', 0, true, d90,'Day when EC equals 90');
   VarCreate('ECa', '', 0, true, ECa);
   VarCreate('inl_MS_xstage2', '', 0, true, inl_MS_xstage2);
   VarCreate('DayOfYearSowingDate', '[DOY]', 0, true, DayofYearSowingDate);
   VarCreate('DOY_BegStemElong','[DOY]', 0, true, DOY_BegStemElong, 'DOY for begin stem elongation');
   VarCreate('DOY_BegFlower',   '[DOY]', 0, true, DOY_BegFlower, 'DOY for begin of flowering');
   VarCreate('DOY_PhysRipe',    '[DOY]', 0, true, DOY_PhysRipe, 'DOY for physiological ripeness');
   VarCreate('TSumInternode_opt',    '[°Cd]', 0, true, TSumInternode_opt, 'a function of phint and day length');
   VarCreate('ph39_opt',    '[°Cd]', 0, true, ph39_opt, 'a function of phint and day length');




   StateCreate('cumvern', '', 0, true, cumvern);
   StateCreate('ec', '', 0, true, ec);
   ec.PlotTograpH := true;
   StateCreate('tdu', '', 0, true, tdu);
   StateCreate('tsums', '', 0, true, tsums);
   StateCreate('xstage', '', 0, true, xstage);
   StateCreate('nl_MS', 'n', 0, false, nl_MS);
   StateCreate('inl_MS', 'n', 5, false, inl_MS);
   StateCreate('DaySSow', 'n', 0, false, DaySSow);
   StateCreate('TSumEC30', '', 0, true, TSumEC30);
   StateCreate('TSum_until_EC_30', '', 0, true, TSum_until_EC_30);
   StateCreate('TSum_until_EC_37', '', 0, true, TSum_until_EC_37);

   Parcreate('p1d', '', 2.76 ,p1d);  //aktualisiert nach John-Manuskript 29.Jan.09
   Parcreate('p1v', '', 2.84  ,p1v);  //aktualisiert nach John-Manuskript 29.Jan.09
   Parcreate('sdepth', 'cm', 3 ,sdepth);
   Parcreate('phint', '°Cd', 91.74,phint); //aktualisiert nach John-Manuskript 29.Jan.09
   Parcreate('tBase', '', 0,tBase);
   Parcreate('sowingdate', 'doy', 300, sowingdate);
   Parcreate('p3', '°Cd', 183.48, p3);
   Parcreate('p4', '°Cd', 200, p4);
   Parcreate('p5', '-', 11.67, p5);//aktualisiert nach John-Manuskript 29.Jan.09
   ParCreate('p9', '°Cd', 139.9, p9);  //aktualisiert nach John-Manuskript 29.Jan.09
   ParCreate('plastochron', '°Cd', 68.3914	, plastochron); //aktualisiert am 17.01.
   ParCreate('Ini_inLMS', 'n', 4, Ini_inLMS); //aktualisiert am 17.01. nach Kage 2012
   ParCreate('TSumInternode', '°Cd', 97.09, TSumInternode); //aktualisiert nach John-Manuskript 29.Jan.09
   ParCreate('minLeaf_number', '', 7, minLeaf_number);
   ParCreate('Internode', '', 3, Internode);
   ParCreate('MaxVernDays', 'd', 50, MaxVernDays);
   ParCreate('MaxPhotoperiod', 'h', 20, MaxPhotoperiod);
   ParCreate('VernMinTemp', '°C', -0.5, VernMinTemp);
   ParCreate('VernOptTemp1', '°C', 0.5, VernOptTemp1);
   ParCreate('VernOptTemp2', '°C', 6, VernOptTemp2);
   ParCreate('VernMaxTemp', '°C', 18, VernMaxTemp);
   ParCreate('Ph39', '-', 101.56, Ph39); //aktualisiert nach John-Manuskript 29.Jan.09
   ParCreate(' xstage_fin_leaf_prim', '-',1.78171 ,  xstage_fin_leaf_prim); // neu angepasst 17.01.
   ParCreate('fdl', '-', 0, fdl);

   ExternVCreate('daylengthp',  'h', ratefield, daylengthp);
   ExternVCreate('dayofyear',  'n', statefield, dayofyear);
   ExternVCreate('TMPM',  '[°C]', ratefield, TMPM);

   OptCreate('DataInitMethod', 'EC_date', DataInitMethod);
   DataInitMethod.OptionList.Add('EC_date');
   DataInitMethod.OptionList.Add('Days_to_EC');

   OptCreate('optTSumInternode', 'constant', OptTSumInternode);
   //OptTSumInternode.OptionList.Clear;
   OptTSumInternode.OptionList.Add('constant');
   OptTSumInternode.OptionList.Add('daylength');




// comments initialisation

    devrates1.comment :=   'developmet rate during istage 1';
    devrates2.comment :=   'developmet rate during istage 2';
    devrates3.comment :=   'developmet rate during istage 3';
    devrates4.comment :=   'developmet rate during istage 4';
    devrates5.comment :=   'developmet rate during istage 5';
    devrates6.comment :=   'developmet rate during istage 6';
    devrates9.comment :=   'developmet rate during istage 9';
    dvs10.comment :=   'xstage times 10, for convenience of plotting';
    istage.comment :=   ' Phenologicalstages in integer values';
    rdr_p.comment :=   'relative development rate of photoperiod';
    rdr_v.comment :=   'relative development rate of vernalization';
    tsuminc.comment :=   'Tagestemperatur >=0 zur Basistemperatur';
    zstage.comment :=   'Zadocks stages';
    vernf.comment :=   'vernalisation factor';

    c.comment :=   'variable photoperiodic influence factor (0..1)';
    k_v.comment :=   'vernalisation variable';
    tempsumemergence.comment :=   '';
    d10.comment :=   'Day when EC equals 10';
    d29.comment :=   'Day when EC equals 29';

    ECa.comment :=   '';
    DayOfYearSowingDate.comment :=   'Dayof Year of sowingdate';
    DaySSow.comment :=   'days since sowing';
    cumvern.comment :=   'cumulative vernalisation';
    ec.comment :=   'EC stage';
    tdu.comment :=   'thermal developmental units';
    tsums.comment :=   'temperature sum since sowing';
    xstage.comment :=   'non integer growth stage indicator ranging from zero to six';
    nL_MS.comment :=   'number of leaves on main stem';
    TSumEC30.comment :=   'Temperature sum since EC30';
    inL_MS.comment :=   'initial leaf number on main stem';
    inl_MS_xstage2 .comment :=   'Anzahl nicht ausgebildeter Blätter zum Zeitpunkt Xstage 2';

    daylengthp.comment :=   'photoperiodic daylength';
    TMPM.comment :=   'mean air temperature';
    dayofyear.comment :=   '';

    Ph39_opt.comment :=   'TSUM 37 bis 39';
    p1d.comment :=   'genetic specific parameter of photoperiod sensitivity';
    p1v.comment :=   'genetic specific parameter of vernalisation sensitivity';
    sdepth.comment :=   'sowing depth (cm), not actual in use';
    phint.comment :=   'the phyllochron interval, the interval in thermal time'+
                '(degree days) between successive leaf and tiller appearances';
    p4.comment :=   'thermal time between Pre-anthesis ear growth to beginning of'+
                ' grain filling (anthesis occurs during this phase)in°Cd';
    p5.comment :=   'thermal time between beginning of grain fill and maturity in°Cd';
    p9.comment :=   'thermal timen from germination to seedling emergence in °Cd';
    tBase.comment :=   'base temperature';
    Internode.comment :=   'Multiplikator des Phyllochronintervalls in der Schossphase';
    sowingdate.comment :=   '';
    plastochron.comment :=   'interval in thermal time between leaf initiation';
    xstage_fin_leaf_prim.comment :=   'xstage an dem kiene weiteren leaf primordien angelegt werden';

    TSumInternode.comment :=   'te´mperature sumd between two internodes';
    minLeaf_number.comment :=   '';
    MaxVernDays.comment :=   'maximum number of vernalisation days which increase developmental rate';
    MaxPhotoperiod.comment :=   'maximum daylength which increase developmental rate';
    VernMinTemp.comment :=   'minimum vernalisation temperature';
    VernOptTemp1.comment :=   'temperature where vernalisation is starting to be optimal';
    VernOptTemp2.comment :=   'temperature where vernalisation is ending to be optimal';
    VernMaxTemp.comment :=   'temperature where vernalisation is getting zero';



end;

procedure TDevelopment.init(var GlobMod: TMod);

var
  year, month, day: word;
  tempsowdate : real;
  ActSeries: TMeasList;
  ActMeas : TMeasValue;

  index, i : integer;

  ActIniFileName : String;
begin


  if OptTSumInternode.option = 'constant' then
    fTSumInternode := constant
  else
    fTSumInternode := daylength;

  inL_MS.V := 5;   // initial leaf number on main stem

  inherited init(GlobMod);
  TSEC32_min:=0;
  TSEC32_max:=0;

  TSEC33_min:=0;
  TSEC33_max:=0;
  TSEC37_min:=0;
  TSEC37_max:=0;

  TSEC38_min:=0; TSEC38_max:=0;
  TSEC57_min:=0; TSEC57_max:=0;
  TSEC59_min:=0; TSEC59_max:=0;
  TSEC61_min:=0; TSEC61_max:=0;
  TSEC65_min:=0; TSEC65_max:=0;
  TSEC69_min:=0; TSEC69_max:=0;
  TSEC71_min:=0; TSEC71_max:=0;

  inL_MS.V := ini_inlMS.v;   // initial leaf number on main stem
//  Index := DataList.IndexOf(d29.name);
//  if Index >= 0 then ActSeries := TMEasList(DataList.objects[Index]);
  EC25MeasDate := 0;
  EC30MeasDate := 0;
  EC37MeasDate := 0;
  TSumEC30.c := 0.0;
  TSumEC30.v := 0.0;
  Index := DataList.IndexOf(ec.name);
  if index <> -1 then begin
      ActSeries := TMeaslist(DataList.objects[Index]);
      for i := 0 to  ActSeries.count-1 do begin
        ActMeas := TMeasValue(ActSEries.items[i]);
        if ActMeas.meas = 30 then
          EC30MeasDate := ActMeas.date;
      end;
  end;



  //*.v= Value; *.c=change =Änderungsrate

  c.v := p1d.V*0.002;            // photoperiodical factor unscaled
  k_v.v := (p1v.v+0.55)/183;     // vernalisation factor unscaled
  // duration of stage 9
  //p9.v := (40 + 10.2 * sdepth.v);
  tempsumemergence.v := p9.v; // 40+10.2*sdepth.V;
  DecodeDate(Sowingdate.v, Year, Month, Day);
  tempsowdate := sowingdate.v + 2 - EncodeDate(Year, 1, 1);
  DayOfYearSowingDate.v := TempSowDate;

  If opt_ReCalcSowingDate = true then
    sowingdate.v := trunc(tempsowdate);

  istage.v := trunc(xstage.v);

  d10.v := 0;
  d29.v := 0;
  d50.v := 0;
  d75.v := 0;
  d90.v := 0;
end;

procedure TDevelopment.CalcRates;

begin
// Variablen Prozeduren *************
  if(fTSumInternode = daylength) then begin
    TSumInternode_opt.v:= phint.v + fdl.v*daylengthp.v*daylengthp.v;
    ph39_opt.v:=TSumInternode_opt.v;
  end else begin
    TSumInternode_opt.v:= TSumInternode.v;
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


  // calculate rate of change of temperature sum
  tsuminc.V := max(0, TMPM.v-tbase.v);


  If opt_ReCalcSowingDate = true then
    if (dayofyear.v<dayofyearsowingdate.V)and(tsums.v<=0)
      then tsuminc.V := 0;

  If opt_ReCalcSowingDate = false then
    if (globtime.v<sowingdate.V)and(tsums.v<=0)
      then tsuminc.V := 0;



  tsums.c:= tsuminc.v;


{  If (Dayofyear.v-3>sowingdate.v)and(tsums.v<=0)
    then showmessage('SimStart later than sowing !');  }

  // calculate rate of leaf apperance until visible number of leaves is smaller than initiated number
  If (Istage.v >=1) and (nl_ms.v<inL_MS.v) then
  begin
    if phint.v > 0 then
      if (xstage.v < 2) then
        nl_MS.c := Tsuminc.v/phint.v
      else
        nl_MS.c := Tsuminc.v/TSumInternode_opt.v;  // number of leaves on main stem.change
  end
  else
  begin
    nl_MS.c := 0.0;
  end;

  // calculate rate of leaf initiation until apical meristeme is not generative
  If (Istage.v >=1) and (xstage.v< xstage_fin_leaf_prim.v)then    // (xstage.v< xstage_fin_leaf_prim.v)
    inL_MS.c := 1/plastochron.v*Tsuminc.v
  else
    inL_MS.c :=0;

  // calculate rate of change of vernalisation status
  if (cumvern.v < MaxVernDays.v)and(tsums.v > tempsumemergence.v) then begin
    vernf.v := trapez_f (TMPM.V, VernMinTemp.v, VernOptTemp1.v, VernOptTemp2.v, VernMaxTemp.v, 0, 1);
    cumvern.c:= vernf.v;
  end
  else
    cumvern.c := 0;  // by default

  // calculate vernalisation influence factor
  rdr_v.v := min(1,max(0,1-k_v.v*(MaxVernDays.v-cumvern.v)));

  // calculate daylength influence factor
  rdr_p.v := min(1,max(0,1-c.v*sqr(MaxPhotoperiod.v-daylengthp.v)));

  // thermal development units
  tdu.c:= tsuminc.v*min(rdr_p.v, rdr_v.v);

  case trunc(istage.v) of
     1: ;
  end;

// calculation of development rate until emergence (stage 9 according to Ritchie)
  if (p9.v > 0) then // begin
    devrates9.v := tsuminc.v/p9.v;
 (*
    If (XSTAGE.v < 1) and (XSTAGE.v+devrates9.v*globtime.c > 1) then begin
      XSTAGE.v := 1;           // hier werden evtl. ein paar Gradtage unterschlagen
      devrates9.v := 0.0;
    end;
  end else
    devrates9.v := 0;
  *)

// calculation of development rate from emergence until terminal spikelet initiation
  if (istage.v>=1)and(istage.v<2) then
  begin
    devrates1.v := tsuminc.V* min(rdr_p.v, rdr_v.v)/(400*phint.V/95)
    //devrates1.v := tsuminc.V* min(rdr_p.v, rdr_v.v)/(((minLeaf_number.v-3)*plastochron.v)*phint.V/95)
  end
 else devrates1.v := 0;  // by default

  //devrates2.v := tsuminc.v/(3*phint.v);   //  bei modifizierung ausklammern
  devrates6.v := tsuminc.v/250;


// development according to zadok's scale and EC stages
if (xstage.v>=0)and(xstage.v<2) then
  begin
     zstage.v := xstage.v*10;
     If XSTAGE.v< 1 then
       EC.c := devrates9.v*10  // XSTAGE 1 is equivalent to BBCH 10  !!
     else
       ec.C:= Tsuminc.v/phint.v  // rate of change of EC stages invers to phyllochron
  end else begin
    zstage.V := 0;
    ec.c := 0;
  end;


  if (xstage.v>=2) and (inl_MS_xstage2.v=0)then
  inl_MS_xstage2.v := max(0,inl_MS.v-2-nl_MS.v);
// inl_MS_xstage2.v := max(0, inl_MS.v-{2-}nl_MS.v);     // two leaves will never emerge ...
  
  if (xstage.v>=2)and(xstage.v<3) then
  begin

     zstage.v := 2.0+2.0*(XSTAGE.v-2.0);
     ZStage.v := zSTage.v*10;
     //EC.c := zstage.v - EC.v;
     xstage.c := tsuminc.v*(1/(inl_MS_xstage2.v* TSumInternode_opt.v +Ph39_opt.v));//EC.c/(40-29);m
     If EC.v < 37 then
       EC.c     := tsuminc.v/TSumInternode_opt.v // EC stage change according to the inverse of the temperature sum between the appearance of two internodes
    else
       EC.c := min(2*tsuminc.v/Ph39_opt.v,40-EC.v);// 40-EC.v beschränkt das Entw.rate auf über 40 springt  min(tsuminc.v/Phint.v,40-EC.v);

     (* If (EC.v+EC.c*Globtime.c<39) and (xstage.v+Devrates2.v*globtime.c>3) then
       devrates2.v :=0;*)     //WENN DIESE BEDINGUNG ENTFÄLLT WIRD XSTAGE NICHT ANGEHALTEN WENN ec 39 NOCH NICHT ERRREICHT WURDE UND SOMIT LÄUFT EC BERECHNUNG MIT NÄCHSTER DEVRATE WEITER
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
    //devrates3.v := tsuminc.v/(2*phint.v);     // 2 phyllochron intervals from stage 2 to 3
    devrates3.v := tsuminc.v/p3.v;
    zstage.v := 4 + 1.7*(xstage.v-3.0);       // EC 57 nach Berechnung, 39-61 nach
                                              // Beschreibung
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end else

  devrates4.v := tsuminc.v/p4.v;                     // p4 ~ 200 degree days
  devrates5.v := (max(0,tsuminc.v-1))/((p5.v+21.5)/0.05); //

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

  if (istage.v <7)and(istage.v>=6)
    then xstage.c := devrates6.v else
    if (istage.v<6)and(istage.v>=5)
      then xstage.c := devrates5.v else
      if (istage.v<5)and(istage.v>=4)
        then xstage.c := devrates4.v else
        if (istage.v<4)and(istage.v>=3)
          then xstage.c := devrates3.v else
            if (istage.v<1)
              then xstage.c := devrates9.v else
                if (istage.v>=1)and(tsums.v>=tempsumemergence.v) and (istage.v<2)
                  then xstage.c := devrates1.v;
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
// non-iecnteger growth stage indicator ranging from zero to six
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
    EC.v :=30;                          //Spitzenährchen "terminal spikelet" = EC 30

   // if the number of visible leaves reaches the number of initialised leaves (minus 2, for collar and ?)
   // the flag leaves appears and we have EC-Stage 37!!
  If (nL_MS.v >= (inL_MS.v-2)) and (EC.v<37) //and  (EC.v>=33)
  then begin
    //Ec.v := 37+min(2*(nL_MS.v-(inL_MS.v-2))*phint.v/Ph39_opt.v,40-EC.v);
    // impact of exceeding leaf number (fraction) on EC progress
    Ec.v := 37+min(2*(nL_MS.v-(inL_MS.v-2))*TSumInternode_opt.v/Ph39_opt.v,40-EC.v);
    //XStage.v := 2+(37-29)/(40-29);
  end;

  If (EC.v >= 40) and (xstage.v<3) then
    xstage.v :=3;  // Damit Xstage wieder EC Stand entspricht

  if (EC25MeasDate > 0)  and (GlobMod.Time.v >= EC25MeasDate) and (GS_EC25.v<=0.0) then
    GS_EC25.v := Xstage.v;


  if (d10.V <=0) and (ec.v >=10) then    // calculation of day of emergence
    d10.V := dayssow.v;
   // d10.v := dayofyear.v;
  if (d29.V <=0) and (ec.v >=29) then
    d29.v := dayssow.v;
    //d29.v := dayofyear.v;
  if (d50.V <=0) and (ec.v >=50) then
    d50.v := dayssow.v;
  if (d75.V <=0) and (ec.v >=75) then
    d75.v := dayssow.v;
  if (d90.V <=0) and (ec.v >=90) then
    d90.v := dayssow.v;
    // TSEC37 is a derived value for calibration only!

 if (self.DOY_BegStemElong.V <=0) and (ec.v >=30) then
    DOY_BegStemElong.V := DayOfTheYear(GlobTime.v);
 if (self.DOY_BegFlower.V <=0) and (ec.v >=61) then
    DOY_BegFlower.V := DayOfTheYear(GlobTime.v);
 if (self.DOY_PhysRipe.V <=0) and (ec.v >=90) then
    DOY_PhysRipe.V := DayOfTheYear(GlobTime.v);



  if ((trunc(ec.v) = 32) and (TSEC32_min = 0)) then
    TSEC32_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 32) and (TSEC32_max = 0) and (TSEC32_min>0) ) then begin
    TSEC32_max:=TSums.v;
    TSEC32.v:= (TSEC32_min-1+TSEC32_max)/2;
  end;

  if ((trunc(ec.v) = 33) and (TSEC33_min = 0)) then
    TSEC33_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 33) and (TSEC33_max = 0) and (TSEC33_min>0)) then begin
    TSEC33_max:=TSums.v;
    TSEC33.v:= (TSEC33_min-1+TSEC33_max)/2;
  end;



  if ((trunc(ec.v) = 37) and (TSEC37_min = 0)) then
    TSEC37_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 37) and (TSEC37_max = 0) and (TSEC37_min>0)) then begin
    TSEC37_max:=TSums.v;
    TSEC37.v:= (TSEC37_min-1+TSEC37_max)/2;
  end;

  if ((trunc(ec.v) = 38) and (TSEC38_min = 0)) then
    TSEC38_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 38) and (TSEC38_max = 0) and (TSEC38_min>0)) then begin
    TSEC38_max:=TSums.v;
    TSEC38.v:= (TSEC38_min-1+TSEC38_max)/2;
  end;

  if ((trunc(ec.v) = 57) and (TSEC57_min = 0)) then
    TSEC57_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 57) and (TSEC57_max = 0) and (TSEC57_min>0)) then begin
    TSEC57_max:=TSums.v;
    TSEC57.v:= (TSEC57_min-1+TSEC57_max)/2;
  end;

  if ((trunc(ec.v) = 59) and (TSEC59_min = 0)) then
    TSEC59_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 59) and (TSEC59_max = 0) and (TSEC59_min>0)) then begin
    TSEC59_max:=TSums.v;
    TSEC59.v:= (TSEC59_min-1+TSEC59_max)/2;
  end;

  if ((trunc(ec.v) = 61) and (TSEC61_min = 0)) then
    TSEC61_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 61) and (TSEC61_max = 0) and (TSEC61_min>0)) then begin
    TSEC61_max:=TSums.v;
    TSEC61.v:= (TSEC61_min-1+TSEC61_max)/2;
  end;

  if ((trunc(ec.v) = 65) and (TSEC65_min = 0)) then
    TSEC65_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 65) and (TSEC65_max = 0) and (TSEC65_min>0)) then begin
    TSEC65_max:=TSums.v;
    TSEC65.v:= (TSEC65_min-1+TSEC65_max)/2;
  end;

  if ((trunc(ec.v) = 69) and (TSEC69_min = 0)) then
    TSEC69_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 69) and (TSEC69_max = 0) and (TSEC69_min>0)) then begin
    TSEC69_max:=TSums.v;
    TSEC69.v:= (TSEC69_min-1+TSEC69_max)/2;
  end;

  if ((trunc(ec.v) = 71) and (TSEC71_min = 0)) then
    TSEC71_min:=TSums.v-Tsums.c;
  if ((trunc(ec.v) > 71) and (TSEC71_max = 0) and (TSEC71_min>0)) then begin
    TSEC71_max:=TSums.v;
    TSEC71.v:= (TSEC71_min-1+TSEC71_max)/2;
  end;


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

procedure Register;
begin
  RegisterComponents('CERES Wheat', [TDevelopment]);
end;

end.
