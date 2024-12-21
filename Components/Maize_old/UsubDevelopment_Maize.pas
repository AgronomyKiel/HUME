unit UsubDevelopment_Maize;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
   vcl.Dialogs, UMod, UState, UAbstractPlant;

Type

TsubDevelopment_Maize = class(TSubmodel)

private
  fGrowthCurveModel: TAbstractPlant;
protected

public
  // Variables

  DevRateS0 : TVar;   /// Development rate during IStage 0 (from sowing to emergence, 0 to 1)
  DevRateS1 : TVar;   /// development rate during IStage 1 (from emergence to tassel initiation, 1-2)
  DevRateS2 : TVar;   /// Development rate during ISTAGE 2 (from tassel initiation to silking, 2-3)
  DevRateS3 : TVar;   /// Development rate during ISTAGE 3 (from silking to effective grain filling, 3-4)
  DevRateS4 : TVar;   /// Development rate during ISTAGE 4 (from effective grain filling to physiological maturity, 4-5)
  integerXN : TVar;   /// leaf nummber of the oldest expending leaf; integer from CumPh
  ISTAGE : TVar;      /// Integer growth stage indicator ranging from zero to five [0..5]
  PC : TVar;           /// Intermediate variable
  Teff6 : TVar;   /// effective daily air temperature
  Teff8 : TVar;   /// Just for Information, not for calculation.
  TI : TVar;       /// Daily increase in leaf number
  Sen_fact :TVar; ///Seneszenzfaktor
  BBCH: TVar;     /// BBCH stage

  // State Variables

  CumPH : TState;   /// number of fully expanded leaves
  CumPH_Booting : TState; /// number of fully expanded leaves
  GDD6 : TState;   ///  Growing degree days from sowing
  GDD6_from_emergence : TState;   /// Growing degree days from emergence
  GDD8 : TState;   /// Just for Information, not for calculation.
  TLNO : TState;   /// TLNO is the total number of leaves that will eventually appear
  TSum_leafLagphase : TState;   /// TSum needed to
  XSTAGE : TState;   /// Phenological stage, non integer values
  DS : TState; /// Development stage for calculating root drymatter (See Hybrid-Maize)
  XSTAGE_till_tassel_emergence : TSTate; ///  XSTAGE_till_tassel_emergence

  // Parameters

  GDD6Emergence : TPar;   /// Temperature sum sowing to emergence
  GDD6Silking : TPar;   /// Temperature sum silking
  GDD6Stage3 : TPar;   ///  Temperature sum stage 3
  GDD6total : TPar;   ///  Temperature sum
  Phyllochron : TPar;   /// Phyllochron
  Plastochron : TPar;   /// Plastochron
  SowingDate : TPar;   /// Date of sowing (days from 1.1.1990)
  Tbase6 : TPar;   ///  Base temperature
  sen_par : TPar; /// Sen_fact wird als potenz Funktion angenommen, sen_par ist der Krümmungsfaktor dieser
  sen_parexp : TPar;  /// Sen_fact wird als potenz Funktion angenommen, sen_parexp ist der Exponent dieser

  // External Variables

  Temp : TExternV;   ///
  DidLastLeafAppear: boolean;///


  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  // Variables

  Property Var_DevRateS0 : TVar read DevRateS0 write DevRateS0;
  Property Var_DevRateS1 : TVar read DevRateS1 write DevRateS1;
  Property Var_DevRateS2 : TVar read DevRateS2 write DevRateS2;
  Property Var_DevRateS3 : TVar read DevRateS3 write DevRateS3;
  Property Var_DevRateS4 : TVar read DevRateS4 write DevRateS4;
  Property Var_integerXN : TVar read integerXN write integerXN;
  Property Var_ISTAGE : TVar read ISTAGE write ISTAGE;
  Property Var_PC : TVar read PC write PC;
  Property Var_Teff6 : TVar read Teff6 write Teff6;
  Property Var_Teff8 : TVar read Teff8 write Teff8;
  Property Var_TI : TVar read TI write TI;
  Property Var_BBCH : TVar read BBCH write BBCH;

  // State Variables
  Property St_CumPH : TState read CumPH write CumPH;
  Property St_CumPH_Booting : TState read CumPH_Booting write CumPH_Booting;
  Property St_GDD6 : TState read GDD6 write GDD6;
  Property St_GDD6_from_emergence : TState read GDD6_from_emergence write GDD6_from_emergence;
  Property St_GDD8 : TState read GDD8 write GDD8;
  Property St_TLNO : TState read TLNO write TLNO;
  Property St_TSum_leafLagphase : TState read TSum_leafLagphase write TSum_leafLagphase;
  Property St_XSTAGE : TState read XSTAGE write XSTAGE;
  Property St_DS : TState read DS write DS;
  Property St_XStage_till_tassel_emergence : TState read XStage_till_tassel_emergence
          write XStage_till_tassel_emergence;


  // Parameters
  Property Par_GDD6Emergence : TPar read GDD6Emergence write GDD6Emergence;
  Property Par_GDD6Silking : TPar read GDD6Silking write GDD6Silking;
  Property Par_GDD6Stage3 : TPar read GDD6Stage3 write GDD6Stage3;
  Property Par_GDD6total : TPar read GDD6total write GDD6total;
  Property Par_Phyllochron : TPar read Phyllochron write Phyllochron;
  Property Par_Plastochron : TPar read Plastochron write Plastochron;
  Property Par_SowingDate : TPar read SowingDate write SowingDate;
  Property Par_Tbase6 : TPar read Tbase6 write Tbase6;

  // External Variables
  Property Ex_Temp : TExternV read Temp write Temp;

  Property GrowthCurveModel : TAbstractPlant read fGrowthCurveModel write fGrowthCurveModel;


end;  // SubmodelName

procedure Register;

implementation
uses Math, JCLDatetime;

procedure TsubDevelopment_Maize.createAll;

begin
  inherited createAll;
  //Variables

  VarCreate('DevRateS0', '[1/(°Cd)]',0, true, DevRateS0, 'Development rate during IStage 0 (from sowing to emergence, 0 to 1)');
  VarCreate('DevRateS1', '[1/(°Cd)]',0, true, DevRateS1, 'development rate during IStage 1 (from emergence to tassel initiation, 1-2)');
  VarCreate('DevRateS2', '[1/(°Cd)]',0, true, DevRateS2, 'Development rate during ISTAGE 2 (from tassel initiation to silking, 2-3)');
  VarCreate('DevRateS3', '[1/(°Cd)]',0, true, DevRateS3, 'Development rate during ISTAGE 3 (from silking to effective grain filling, 3-4)');
  VarCreate('DevRateS4', '[1/(°Cd)]',0, true, DevRateS4, 'Development rate during ISTAGE 4 (from effective grain filling to physiological maturity, 4-5)');
  VarCreate('integerXN', '',0, true, integerXN, 'leaf nummber of the oldest expending leaf; integer from CumPh');
  VarCreate('ISTAGE', '',0, true, ISTAGE, 'nteger growth stage indicator ranging from zero to five [0..5]');
  VarCreate('PC', '',0, true, PC, 'Intermediate variable');
  VarCreate('Teff6', '[°C]',0, true, Teff6, 'effective daily air temperature');
  VarCreate('Teff8', '[°C]',0, true, Teff8, 'Just for Information, not for calculation.');
  VarCreate('TI', '[°C]',0, true, TI, 'Daily increase in leaf number');
  VarCreate('Sen_fact', '',0, true, Sen_fact, 'Seneszenzfaktor');
  VarCreate('BBCH', '',0, true, BBCH, 'BBCH stage');

  //State Variables

  StateCreate('CumPH', '[n]',1, true,CumPH, 'number of fully expanded leaves');
  StateCreate('CumPH_Booting', '[n]',0, true,CumPH_Booting, 'number of nodes');
  StateCreate('GDD6', '[°C*d]',0, true,GDD6, 'Growing degree days from sowing');
  StateCreate('GDD6_from_emergence', '[°C*d]',0, true,GDD6_from_emergence, 'growing degree days from emergence');
  StateCreate('GDD8', '[°C*d]',0, true,GDD8, 'Just for Information, not for calculation.');
  StateCreate('TLNO', '[n]',6, true,TLNO, 'TLNO is the total number of leaves that will eventually appear');
  StateCreate('TSum_leafLagphase', '',0, true,TSum_leafLagphase, '');
  StateCreate('XSTAGE', '[-]',0, true,XSTAGE, 'Phenological stage, non integer values');
  StateCreate('DS', '[-]',0, true,DS, 'Development stage for calculating root drymatter (See Hybrid-Maize)');
  StateCreate('XSTAGE_till_tassel_emergence', '[-]',0, true,XSTAGE_till_tassel_emergence, '');

  // Parameters

  ParCreate('GDD6Emergence', '[°C*d]',68.34,GDD6Emergence, 'Temperature sum sowing to emergence');
  ParCreate('GDD6Silking', '[°C*d]',822.6,GDD6Silking, 'Temperature sum silking');
  ParCreate('GDD6Stage3', '[°C*d]',202.6,GDD6Stage3, 'Temperature sum stage 3');
  ParCreate('GDD6total', '[°C*d]',1534.97,GDD6total, 'Temperature sum');
  ParCreate('Phyllochron', '[°C*d]',54.05,Phyllochron, ' Phyllochron');
  ParCreate('Plastochron', '[°C*d]',29.18,Plastochron, 'Plastochron');
  ParCreate('SowingDate', '[-]',39191,SowingDate, 'Date of sowing (days from 1.1.1990)');
  ParCreate('Tbase6', '[°C]',6,Tbase6, 'Base temperature');
  ParCreate('sen_par', '[-]',0.15,sen_par, 'en_fact wird als potenz Funktion angenommen, sen_par ist der Krümmungsfaktor dieser');
  ParCreate('sen_parexp', '[-]',2,sen_parexp, 'en_fact wird als potenz Funktion angenommen, sen_parexp ist der Exponent dieser');

  // External Variable

  ExternVCreate('Temp', '[°C]',statefield, Temp, 'Air temperature in 2 m height');
end;


procedure TsubDevelopment_Maize.init(var GlobMod: TMod);
var
  Y,M,D: word;
begin
  inherited init(GlobMod);
  CumPH.v := 1;
  GDD6.v := 0;
  GDD6_from_emergence.v := 0;
  GDD8.v := 0;
  TLNO.v := 6;
  TSum_leafLagphase.v := (6-2)*Phyllochron.v+(2.467867*Phyllochron.v)- Phyllochron.v;  //Bei Auflaufen 6 schon vorhanden
  //Blattanlagen minus 2 Blattanlagen die am Ende nicht ausgebildet werden  plus 2.46Phyllochrone, was der Zeitraum zwischen
  //Ausbildung des letzten Blattes und Silking ist und -Phyllochron, d.h. das bei auflaufen das (Keim)blatt schon da ist.
  DS.v := 0;
  BBCH.v := 0;
  DidLastLeafAppear := false;

  If (SowingDate.v <= 366) and (GrowthCurveModel<>nil) then begin
     decodedate(Globmod.Starttime,Y,M,D);
     GrowthCurveModel.setSowingDate(Encodedate(Y-1,12,31)+Sowingdate.v);
  end;


end;


procedure TsubDevelopment_Maize.CalcRates;

var
  IsAfterSowing : boolean;
  nodes_count : integer;
  IntStg : integer;

begin

   If SowingDate.v > 366 then If (Globtime.v >= SowingDate.v) then IsAfterSowing := true;
   If SowingDate.v <= 366 then If (dayoftheyear(Globtime.v)>=SowingDate.v) then IsAfterSowing := true;
   If IsAfterSowing then begin
    nodes_count := trunc(CumPH_Booting.v);
    ISTAGE.v :=trunc(XSTAGE.v);
    IntStg := trunc(ISTAGE.v);
    DidLastLeafAppear := (CumPH.v >= (TLNO.v - 2));

    case IntStg of
                0 : BBCH.v := XSTAGE.v * 10;
                1 : BBCH.v := 10 + CumPH.v - 1;
                2 : If not(DidLastLeafAppear) then BBCH.v := 30 + nodes_count else
          BBCH.v := 50+10*((XSTAGE.v-XSTAGE_till_tassel_emergence.v) / (3 - XSTAGE_till_tassel_emergence.v));
                3 : BBCH.v := 61 + (XSTAGE.v - 3) * 18;
                4 : BBCH.v := 80 + (XSTAGE.v - 4) * 10;
                5 : BBCH.v := 80 + (XSTAGE.v - 4) * 10;
    end;



   Teff6.v :=  max(0,Temp.v-Tbase6.v);
   Teff8.v :=  max(0,Temp.v-8);
   If  XSTAGE.v>=0 then  GDD6.c :=Teff6.v else  GDD6.c :=0;
   If  XSTAGE.v>=0 then  GDD8.c :=Teff8.v else  GDD8.c :=0;
   If  XSTAGE.v <= 1
       then  DevRateS0.v :=Teff6.v/GDD6Emergence.v
       else  DevRateS0.v :=0;
   If  (XSTAGE.v>=1) and (XSTAGE.v<=2)
       then DevRateS1.v := Teff6.v/((-(6-2)+GDD6silking.v/Phyllochron.v+5-4.15034-2.467867+1)*Plastochron.v)
       else DevRateS1.v :=0;
   If  (XSTAGE.v>=2) and (XSTAGE.v<=3)
       then  DevRateS2.v :=Teff6.v/TSum_LeafLagphase.v
       else  DevRateS2.v :=0;
   DevRateS3.v :=Teff6.v/GDD6Stage3.v;
   DevRateS4.v :=Teff6.v/(GDD6total.v-GDD6Stage3.v-GDD6Emergence.v-GDD6Silking.v);
   integerXN.v :=trunc(cumph.v+1);
   If  cumPh.v < 5
       then  PC.v := 0.66 + 0.068 * cumPh.v
       else  PC.v :=1;
   TI.v :=  Teff6.v / (Phyllochron.v * PC.v);     //Blattausbildungsrate

   If  (XSTAGE.v>=1)and(CumPH.v<TLNO.v-2)
       then  CumPH.c :=TI.v
       else  CumPH.c :=0;
   If  XSTAGE.v>=1
       then  GDD6_from_emergence.c :=Teff6.v
       else  GDD6_from_emergence.c :=0;
   If  ((GDD6_from_emergence.v+TSum_LeafLagPhase.v)<GDD6Silking.v)and (xstage.v>=1)
       then  TLNO.c :=Teff6.v/Plastochron.v  //Zunahme der Anzahl der Blattanlagen
       else  TLNO.c :=0;
   If  (TSum_leafLagphase.v+GDD6_from_emergence.v<=GDD6Silking.v)and(xstage.v>=1)and(Teff6.v>0)
       then  TSum_leafLagphase.c :=(Teff6.v/Plastochron.v-TI.v)*Phyllochron.v  //noch benötigte TemSum zur Ausbildung (hier als Rate) der angelegten Blätter (zu jedem Zeitpunkt)
       // wobei Teff/Plastochron die Blattanlagerate ist und TI die Blattausbildungsrate
       else  TSum_leafLagphase.c := 0;
   If  GDD6_from_emergence.v<=GDD6Silking.v
       then  DS.v := GDD6_from_emergence.v/GDD6Silking.v
       else  DS.v := 1+(GDD6_from_emergence.v-GDD6Silking.v)/(GDD6total.v-GDD6Silking.v);
   IsAfterSowing := false;
     If  (XStAGE.v <= 1) then begin
       If DevRateS0.v <= 1-XStage.v
       then XSTAGE.c :=  DevRateS0.v
       else XStage.c :=  1-XStage.v+(1-(1-XStage.v)/DevrateS0.v)*DevRateS1.v;
     end
     else  If  (XSTAGE.v>=1) and (XSTAGE.v < 2) then begin
       XSTAGE.c :=   DevRateS1.v
     end
     else  If  (XSTAGE.v>=2) and (XSTAGE.v < 3) then begin
       If DevRateS2.v <= 3-XStage.v
       then XSTAGE.c :=  DevRateS2.v
       else XStage.c :=  3-XStage.v+(1-(3-XStage.v)/DevrateS2.v)*DevRateS3.v;
     end
     else  If  (XSTAGE.v>= 3) and (XSTAGE.v <4)  then begin
       If DevRateS3.v <= 4-XStage.v
       then XSTAGE.c :=  DevRateS3.v
       else XStage.c :=  4-XStage.v+(1-(4-XStage.v)/DevrateS3.v)*DevRateS4.v;
     end
     else  If  XSTAGE.v >= 4 then begin
       XSTAGE.c :=   DevRateS4.v;
     end
     else  XSTAGE.c :=   0;
     If  (XSTAGE.v>= 2) then
     Sen_fact.v := power(((XStage.v-2)* sen_par.v),sen_parexp.v);
  end
  else XStage.c:=0;
  if DidLastLeafAppear then XSTAGE_till_tassel_emergence.c := 0
                                        else XSTAGE_till_tassel_emergence.c := XSTAGE.c;
  if(XSTAGE.v >= 2) and (CumPH.v < (TLNO.v - 2)) then
    CumPH_Booting.c := TI.v else
    CumPH_Booting.c := 0;

end;


procedure TsubDevelopment_Maize.Integrate;

begin

  inherited  integrate;
  If ISTAGE.v>6 then begin

  end;
  If (TSum_leafLagphase.v+GDD6_from_emergence.v>=GDD6Silking.v)and(xstage.v>=1)and(XStage.v<2)
     then begin
     XSTAgE.v:=2;
  end;



end;

procedure Register;
begin
  RegisterComponents('Maize', [TsubDevelopment_Maize]);
end;

end.
