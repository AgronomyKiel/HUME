

unit DevelopmentTJEnd; // Kopfzeile

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

  TDevelopment = class(TSubmodel)
  private
    { Private-Deklarationen }

  fDataInitMethod : TDataInitMethod;
      protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    devrates1,    //Entwicklungsraten
    devrates2,
    devrates3,
    devrates4,
    devrates5,
    devrates6,
    devrates9,
    dvs10,
    istage,//Phanologicalstage, 1 Emergence to terminal spikelet(TS),2TSto end
           //of vegetative growth, 3 end of vegetative growth to beginning of
           //pre-anthesis ear growth, 4 Pre-anthesis ear growth to beginning of
           //grain filling (anthesis occurs during this phase), 5 Beginning of
           //grain fill to physiological maturity, 6 Physiological maturity to
           //fallow (harvest), 7 Fallow to sowing, 8 Sowing to germination
           //9 germination to emergence
    rdr_p, //relative development rate of photoperiod
    rdr_v, //relative development rate of vernalization
    tdif,
    tsuminc,//Tagestemperatur >=0 zur Basistemperatur
    zstage,//Zadock's stages
    vernf: TVar; //Vernalizationsfaktor?

    c,                  // photoperioden Konstante
    k_v,                // Vernalizationskonstante
    tempsumemergence,
    d10,
    d29: TVar; // Define Values

    ECa : TVar;

    DaySSow,
    cumvern,

    ec,
    tdu,
    tsums,
    xstage,// non integer growth stage indicator ranging from zero to six
    nL_MS, // number of leaves on main stem
    inL_MS // // initial leaf number on main stem
       : TState;

    daylengthp,
    TMPM,
    dayofyear: TExternV;

    p1d, // genetic specific characteristic of photoperiod sensitivity
    p1v, // genetic specific characteristic of vernalisation sensitivity
    sdepth, // sowing depth (cm)
    phint, // the phyllochron interval, the interval in thermal time
          //(degree days) between successive leaf and tiller appearances
    p5,  // thermal time between beginning of grain fill and maturaty in°Cd
    p9,  // thermal timen from germination to seedling emergence in °Cd
    tBase,  // base temperature
    Internode, //Multiplikator des Phyllochronintervalls in der Schossenphase
    sowingdate,
    plastochron,  //
    minLeaf_number: TPar;


    DataInitMethod : Toption;

    procedure createAll; override;//erweitern, existiert schon
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;
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
   property Par_p9 : TPar read p9 write p9; // Define Value
   property Var_rdr_p : TVar read rdr_p write rdr_p;
   property Var_rdr_v : TVar read rdr_v write rdr_v;

   property Var_tdif : TVar read tdif write tdif;
   property Var_tempsumemergence : TVar read tempsumemergence write tempsumemergence; // Define Value
   property Var_tsuminc : TVar read tsuminc write tsuminc;
   property Var_zstage : TVar read zstage write zstage;
   property Var_vernf : TVar read vernf write vernf;
   property Var_d10 : TVar read d10 write d10;
   property Var_d29 : TVar read d29 write d29;

   property ST_cumvern : TState read cumvern write cumvern;
   property ST_ec : TState read ec write ec;
   property ST_tdu : TState read tdu write tdu;
   property ST_tsums : TState read tsums write tsums;
   property ST_xstage : TState read xstage write xstage;
   property ST_nl_MS : TState read nl_MS write nl_MS;
   property ST_inl_MS : TState read inl_MS write inl_MS;

   property Ex_daylengthp : TExternV read daylengthp write daylengthp;
   property Ex_dayofyear : TExternV read dayofyear write dayofyear;
   property Ex_TMPM : TExternV read TMPM write TMPM;

   property Par_minLeaf_number : TPar read minLeaf_number write minLeaf_number;
   property Par_plastochron : TPar read plastochron write plastochron;
   property PAR_sowingdate: TPar read sowingdate write sowingdate;

   property Opt_DataIniMethod : TOption read DataInitMethod write DataInitMethod;
    { Published-Deklarationen }

  end;  // bis hier Deklarationen, die von anderen Units oder dem Programm
        //genutzt werden können

procedure Register;

implementation

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

   VarCreate('tdif', '', 0, true, tdif);
   VarCreate('tempsumemergence', '', 0, true, tempsumemergence); // Define Value
   VarCreate('tsuminc', '', 0, true, tsuminc); // 0 = max(0,TMPM-tbase)
   VarCreate('zstage', '', 0, true, zstage);
   VarCreate('vernf', '', 0, true, vernf);
   VarCreate('d10', '', 0, true, d10);
   VarCreate('d29', '', 0, true, d29);
   VarCreate('ECa', '', 0, true, ECa);

   StateCreate('cumvern', '', 0, true, cumvern);
   StateCreate('ec', '', 0, true, ec);
   StateCreate('tdu', '', 0, true, tdu);
   StateCreate('tsums', '', 0, true, tsums);
   StateCreate('xstage', '', 0, true, xstage);
   StateCreate('nl_MS', 'n', 0, false, nl_MS);
   StateCreate('inl_MS', 'n', 0, false, inl_MS);
   StateCreate('DaySSow', 'n', 0, false, DaySSow);

   Parcreate('p1d', '', 3.23,p1d);
   Parcreate('p1v', '', 6 ,p1v);
   Parcreate('sdepth', '', 3 ,sdepth);
   Parcreate('phint', '', 100,phint);
   Parcreate('p5', '', 3, p5);
   Parcreate('tBase', '', 0,tBase);
   Parcreate('sowingdate', ' ', 300, sowingdate);
   ParCreate('p9', '', 0, p9); // Define Value
   ParCreate('plastochron', '', 70, plastochron);
   ParCreate('minLeaf_number', '', 7, minLeaf_number);
   ParCreate('Internode', '', 3, Internode);

   ExternVCreate('daylengthp',  'h', ratefield, daylengthp);
   ExternVCreate('dayofyear',  'n', statefield, dayofyear);
   ExternVCreate('TMPM',  '[°C]', ratefield, TMPM);

   OptCreate('DataInitMethod', 'EC_date', DataInitMethod);
   DataInitMethod.OptionList.Add('EC_date');
   DataInitMethod.OptionList.Add('Days_to_EC');

end;

procedure TDevelopment.init(var GlobMod: TMod);

var
  year, month, day: word;
  tempsowdate : real;
  ActSeries: TMeasList;
  index : integer;

begin
  inherited init(GlobMod);
  Index := DataList.IndexOf(d29.name);
  if Index >= 0 then ActSeries := TMEasList(DataList.objects[Index]);

  //showmessage(InttoStr(ActSEries.count));

  //*.v= Value; *.c=change =Änderungsrate

  c.v := p1d.V*0.002;            // photoperiodical factor unscaled
  k_v.v := (p1v.v+0.55)/183;     // vernalisation factor unscaled
  // duration of stage 9
  //p9.v := (40 + 10.2 * sdepth.v);
  tempsumemergence.v := p9.v; // 40+10.2*sdepth.V;
  DecodeDate(Sowingdate.v, Year, Month, Day);
  tempsowdate := sowingdate.v + 2 - EncodeDate(Year, 1, 1);
  sowingdate.v := trunc(tempsowdate);
  istage.v := trunc(xstage.v);
  inL_MS.V := 3;   // initial leaf number on main stem

end;

procedure TDevelopment.CalcRates;

begin
// Variablen Prozeduren *************

  if (dayofyear.v>=sowingdate.V) then
    Dayssow.c := self.GlobTime.C;
  tsuminc.V := max(0, TMPM.v-tbase.v);
  if (dayofyear.v<sowingdate.V)and(tsums.v<=0)
    then tsuminc.V := 0; 
{  If (Dayofyear.v-3>sowingdate.v)and(tsums.v<=0)
    then showmessage('SimStart later than sowing !');  }

  tsums.c:= tsuminc.v;

  If (Istage.v >=1) and (nl_ms.v<inL_MS.v) then
  begin
    nl_MS.c := Tsuminc.v/phint.v;  // number of leaves on main stem.change
  end
  else
  begin
    nl_MS.c := 0.0;
  end;


  If (Istage.v >=1) and (EC.v<25) then
  begin
    inL_MS.c := 1/plastochron.v*Tsuminc.v;
  end
  else
  begin
    inL_MS.c :=0
  end;
  
  if (TMPM.V < -0.5)
    then vernf.v:= 0;
  if (TMPM.v >= -0.5) and (TMPM.v <= 0.5)
    then Vernf.v:= TMPM.v + 0.5;
  if (TMPM.v > 0.5) and (TMPM.v < 6)
   then vernf.V:= 1;
  if (TMPM.v >= 6) and (TMPM.v <= 18)
    then vernf.V:= 1 - (TMPM.v - 6) / (18-6);
  if (TMPM.v > 18) and (TMPM.v <= 40)
   then vernf.V:= 0;

  if (cumvern.v<50)and(tsums.v>tempsumemergence.v) then
   cumvern.c:= vernf.v
  else cumvern.c := 0;  // by default

  rdr_p.v := min(1,max(0,1-c.v*sqr(20-daylengthp.v)));
  rdr_v.v := min(1,max(0,1-k_v.v*(50-cumvern.v)));

  tdif.v := 0;

  // thermal development units
  tdu.c:= tsuminc.v*min(rdr_p.v, rdr_v.v);

if (istage.v>=1)and(istage.v<2) then
  begin
  devrates1.v := tsuminc.V* min(rdr_p.v, rdr_v.v)/({((minLeaf_number.v-3)*plastochron.v){300}400*phint.V/95)
  end
 else devrates1.v := 0;  // by default

  devrates2.v := tsuminc.v/(Internode.v*phint.v);
  devrates3.v := tsuminc.v/(2*phint.v);
  devrates4.v := tsuminc.v/(200);
  devrates5.v := (max(0,tsuminc.v-1))/((p5.v+21.5)/0.05);
  devrates6.v := tsuminc.v/250;

  if (p9.v > 0) then begin
    devrates9.v := tsuminc.v/p9.v;
    If (XSTAGE.v < 1) and (XSTAGE.v+devrates9.v*globtime.c > 1) then begin
      XSTAGE.v := 1;           // hier werden evtl. ein paar Gradtage unterschlagen
      devrates9.v := 0.0;
    end;
  end else
    devrates9.v := 0;

 // development according to zadok's scale
if (xstage.v>= 6) and (xstage.v <7) then
  begin
    zstage.v := 9 + (xstage.v-6);//aus Stickstoffmodul berechnet EC 90
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
    end else
if (xstage.v>=5)and(xstage.v<6) then
  begin
    zstage.v := 7.1 + 1.9*(xstage.v-5);//aus Stickstoffmodul berechnet EC 90
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end else
if (xstage.v>=4)and(xstage.v<5) then
  begin
    zstage.v := 5.7 + 1.4*(xstage.v-4.0);   // EC 62
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end else
if (xstage.v>=3)and(xstage.v<4) then
  begin
    zstage.v := 4 + 1.7*(xstage.v-3.0);// EC 57 nach Berechnung, 39-61 nach
                                              //Beschreibung
    ZStage.v := zSTage.v*10;
    EC.c := zstage.v - EC.v;
  end else
if (xstage.v>=2)and(xstage.v<3) then
  begin
     zstage.v := 2.0*(xstage.v);
     ZStage.v := zSTage.v*10;
     EC.c     := devrates2.v*(40-30); //EC 39-29
  end else
if (xstage.v>=0)and(xstage.v<2) then
  begin
     zstage.v := xstage.v*10;
     If XSTAGE.v< 1 then
       EC.c := devrates9.v*10  // XSTAGE 1 is equivalent to BBCH 10  !!
     else
       ec.C:= Tsuminc.v/phint.v
  end else begin
    zstage.V := 0;
    ec.c := 0;
  end;

  // by default
dvs10.v := Istage.v*10;

// Compartment Prozeduren **********


// phenological stage
  if (istage.v <7)and(istage.v>=6)
    then xstage.c := devrates6.v else
  if (istage.v<6)and(istage.v>=5)
    then xstage.c := devrates5.v else
  if (istage.v<5)and(istage.v>=4)
    then xstage.c := devrates4.v else
  if (istage.v<4)and(istage.v>=3)
    then xstage.c := devrates3.v else
  if (istage.v<3)and(istage.v>=2)
    then xstage.c := devrates2.v else
  if (istage.v<1)
    then xstage.c := devrates9.v else
  if (istage.v>=1)and(tsums.v>tempsumemergence.v)
    then xstage.c := devrates1.v else
  xstage.C := 0;  // by default
end;


procedure TDevelopment.Integrate;

begin
  inherited integrate;

  if (xstage.v > 1) and (istage.v = 0) then begin
     xstage.v := 1;
     nl_ms.v := 1;
  end;                                // Bei Überschreiten von Stadium 1 zunächst Rücksetzen auf 1

  If (EC.v >= 13.5) and (EC.v < 20) then   // Bestockung nach Erscheinen des 4. Blattes
    EC.v := EC.v+7.5;
 //{If (EC.v >= 23) and (EC.v < 30) then
    //EC.v := 25; }                         // EC 25 volle Bestockung

  If (xSTAGE.v >=1.9) and (EC.v < 29) then   //Spitzenährchen + Doppelring
    EC.v := 29;
// non-integer growth stage indicator ranging from zero to six
  istage.V := trunc(xstage.V);


  if (d10.V <=0) and (ec.v >=10) then    // calculation of day of emergence
   d10.V := dayssow.v;
   // d10.v := dayofyear.v;
  if (d29.V <=0) and (ec.v >=29) then
    d29.v := dayssow.v;
    //d29.v := dayofyear.v;

 Eca.v := EC.v;
 If Ec.v> 15 then ECa.V := EC.v-7.5;

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
          ActSEries.SumSqr := ActSEries.SumSqr + sqr(ActMeas.sim - ActMeas.meas);
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
          ActSEries.SumSqr := ActSEries.SumSqr + sqr(ActMeas.sim - ActMeas.meas);
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
