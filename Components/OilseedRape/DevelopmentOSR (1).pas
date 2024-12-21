unit DevelopmentOSR;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type
TOptimizeOpt = (OOEC11, OOEC13, OOEC27, OOEC39, OOEC51, OOEC61, OOEC69, OOAll);

TDevelopmentOSR = class(TSubmodel)

private
  fOptimizeOpt: TOptimizeOpt;

protected

public
  DVR1  : TVar;   // Entwicklungsrate bis Auflauf
  DVR2  : TVar;   // Entwicklungsrate bis EC27
  DVR2a : TVar;   // Entwicklungsrate von EC27 bis EC39
  DVR2b : TVar;   // Entwicklungsrate von EC39 bis Blühbeginn
  DVR3  : TVar;   // Entwicklungsrate bis Blühende
  DVR4  : TVar;   // Entwicklungsrate bis Reife
  Teff  : TVar;   // Effektive Tagestemperatur  Tday-Tb
  Fp    : TVar;   // photoperiodischer Faktor
  BBCH  : TVar;   // Entwicklungsstadium nach BBCH
  EC    : TVar;   // EC-Stadium nach Schütte aus DVS
  BBCH30: TVar;   // Variable for estimating DVS30
  BBCH50: TVar;   // Variable for estimating DVSInflor

  // Constant Variables
  DVS : TState;  // Entwicklungsstadium
  Blattanzahl : TState;   //
  NumExtInternodes: TState;  // Number of extended internodes (BBCH stages 30 to 39)
  Fv : TState;   //
  TS : TState;   // Temperatur Summe
  TS11: TState;  // TSum from DVS=1/BBCH=9/EC=11

             // Parameters
  aT1 : TPar;   // Parameter für Entwicklungsrate bis EC11
  aT2 : TPar;   // Parameter für Entwicklungsrate EC11 bis EC39
  aT2a : TPar;   // Parameter für Entwicklungsrate EC39 bis EC61
  aT3 : TPar;   // Parameter für Entwicklungsrate EC61 bis EC69
  aT4 : TPar;   // Parameter für Entwicklungsrate EC69 bis EC89
  Phyllochron : TPar;   //
  TSumInternode: TPar;
  Rvmax : TPar;   // Maximale Vernalisationsrate
  Tb : TPar;   // Basis-Temperatur
  Tvmin : TPar; // Minimaltemperatur für Vernalisation
  Tvopt1 : TPar; // Untere optimale Vernalisationstemperatur
  Tvopt2 : TPar; // Obere optimale Vernalisationstemperatur
  Tvmax : TPar; // Maximaltemperatur für Vernalisation
  Dlpmin : TPar; //Minimale Tageslänge für Photoperiodischen Faktor
  Dlpopt : TPar; //Optimale Tageslänge für Photoperiodischen Faktor
  DVS30 : TPar; // Geschätze DVS bei EC 30
  DVS13 : TPar; // Geschätze DVS bei EC 13
  DVSInflor: TPar; // DVS at beginning of inflorescence emergence (BBCH=50 / EC=51)
  TSumCotEm: TPar; // Temperature Sum from first appearance of Cotyledons to complete unfolding (DVS=1/BBCH=9 to BBCH=10)
  SowingDate : TPar; // Aussaattermin

  OptimizeOpt : TOption;

             // External Variables
  DayLengthP : TExternV;   //
  Tmpm       : TExternV;   //


  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;


published
  Property Var_DVR1 : TVar read DVR1 write DVR1;
  Property Var_DVR2 : TVar read DVR2 write DVR2;
  Property Var_DVR2a : TVar read DVR2a write DVR2a;
  Property Var_DVR2b : TVar read DVR2b write DVR2b;
  Property Var_DVR3 : TVar read DVR3 write DVR3;
  Property Var_DVR4 : TVar read DVR4 write DVR4;
  Property Var_Teff : TVar read Teff write Teff;
  Property Var_BBCH : TVar read BBCH write BBCH;
  Property Var_EC : TVar read EC write EC;

  Property St_DVS : TState read DVS write DVS;
  Property St_Blattanzahl : TState read Blattanzahl write Blattanzahl;
  Property St_Fv : TState read Fv write Fv;
  Property St_TS : TState read TS write TS;


         // Parameters
  Property Par_aT1 : TPar read aT1 write aT1;
  Property Par_aT2 : TPar read aT2 write aT2;
  Property Par_aT2a : TPar read aT2a write aT2a;
  Property Par_aT3 : TPar read aT3 write aT3;
  Property Par_aT4 : TPar read aT4 write aT4;
  Property Par_Phyllochron : TPar read Phyllochron write Phyllochron;
  Property Par_Rvmax : TPar read Rvmax write Rvmax;
  Property Par_Tb : TPar read Tb write Tb;
  Property Par_DVS30 : TPar read DVS30 write DVS30;
  Property Par_DVS13 : TPar read DVS13 write DVS13;
  Property Par_DVSInflor: TPar read DVSInflor write DVSInflor;
  Property Par_SowingDate : TPar read SowingDate write SowingDate;
  Property Par_TSumCotEm: TPar read TSumCotEm write TSumCotEm;


         // Properties External Variables
  Property Ex_DayLengthP : TExternV read DayLengthP write DayLengthP;
  Property Ex_Tmpm : TExternV read Tmpm write Tmpm;


end;  // SubmodelName

procedure Register;

implementation
uses Math;

procedure TDevelopmentOSR.createAll;

begin
  inherited createAll;
  VarCreate('DVR1', '[-]',0, true, DVR1);
  VarCreate('DVR2', '[-]',0, true, DVR2);
  VarCreate('DVR2a', '[-]',0, true, DVR2a);
  VarCreate('DVR2b', '[-]',0, true, DVR2b);
  VarCreate('DVR3', '[-]',0, true, DVR3);
  VarCreate('DVR4', '[-]',0, true, DVR4);
  VarCreate('Teff', '[°C]',0, true, Teff);
  VarCreate('Fp', '[-]',0, true, Fp);
  VarCreate('BBCH', '[-]',0, true, BBCH,'Entwicklungsstadium nach BBCH');
  VarCreate('EC', '[-]',0, true,EC,'Entwicklungsstadium nach Schütte');
  VarCreate('BBCH30', '[-]',0, true, BBCH30,'Variable for estimating DVS30');
  VarCreate('BBCH50', '[-]',0, true, BBCH50,'Variable for estimating DVSInflor');

  StateCreate('DVS', '[-]',0, true,DVS);
  StateCreate('Blattanzahl', '[n]',0, true,Blattanzahl);
  StateCreate('NumExtInternodes', '[n]', 0, true, NumExtInternodes, 'Number of extended internodes (BBCH stages 30 to 39)');
  StateCreate('Fv', '[-]',0, true,Fv);
  StateCreate('TS', '[-]',0, true,TS);
  StateCreate('TS11', '[-]',0, true,TS11);

  // Parameters
  ParCreate('aT1', '[1/(°C*d)]',0.0077212,aT1);
  ParCreate('aT2', '[1/(°C*d)]',0.0296873,aT2);
  ParCreate('aT2a', '[1/(°C*d)]',0.0296873,aT2a);
  ParCreate('aT3', '[1/(°C*d)]',0.0051036,aT3);
  ParCreate('aT4', '[1/(°C*d)]',0.0014651,aT4);
  ParCreate('Phyllochron', '[°Cd]',59.2,Phyllochron);
  ParCreate('TSumInternode', '[°Cd]',25,TSumInternode);
  ParCreate('Rvmax', '',0.014553,Rvmax);
  ParCreate('Tb', '[°C]',3,Tb);
  ParCreate('Tvmin', '[°C]',-3.7182,Tvmin);
  ParCreate('Tvopt1', '[°C]',0.7260,Tvopt1);
  ParCreate('Tvopt2', '[°C]',5.3770,Tvopt2);
  ParCreate('Tvmax', '[°C]',17.2022,Tvmax);
  ParCreate('Dlpmin', '[h]',5.7,Dlpmin);
  ParCreate('Dlpopt', '[h]',14.8,Dlpopt);
  ParCreate('DVS30', '[-]',1.3,DVS30);
  ParCreate('DVS13', '[-]',1.00072,DVS13);
  ParCreate('DVSInflor','[-]',1.327,DVSInflor,'DVS at beginning of inflorescence emergence (BBCH=50 / EC=51)');
  ParCreate('SowingDate', '[-]',1,SowingDate);
  ParCreate('TSumCotEm','[°C d]',60,TSumCotEm,'Temperature Sum from first appearance of Cotyledons to complete unfolding (DVS=1/BBCH=9 to BBCH=10)');

         // External Variable
  ExternVCreate('DayLengthP', '',statefield, DayLengthP);
  ExternVCreate('TMPM', '',statefield, Tmpm);

  OptCreate('OptimizeOption', 'All', OptimizeOpt,
    'Specifies until which EC stage data and development rates are considered');
  OptimizeOpt.OptionList.Clear;
  OptimizeOpt.OptionList.Add('All');
  OptimizeOpt.OptionList.Add('Until_EC11_BBCH09');
  OptimizeOpt.OptionList.Add('Until_EC13_BBCH10');
  OptimizeOpt.OptionList.Add('Until_EC27_BBCH19');
  OptimizeOpt.OptionList.Add('Until_EC39_BBCH39');
  OptimizeOpt.OptionList.Add('Until_EC51_BBCH50');
  OptimizeOpt.OptionList.Add('Until_EC61_BBCH60');
  OptimizeOpt.OptionList.Add('Until_EC69_BBCH69');
end;


procedure TDevelopmentOSR.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  Blattanzahl.v := 0;
  Fv.v := 0;
  TS.v := 0;
  BBCH.v := 0;
  EC.v := 0;

  if uppercase(OptimizeOpt.Option) = 'ALL' then fOptimizeOpt := OOAll;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC11_BBCH09' then fOptimizeOpt := OOEC11;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC13_BBCH10' then fOptimizeOpt := OOEC13;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC27_BBCH19' then fOptimizeOpt := OOEC27;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC39_BBCH39' then fOptimizeOpt := OOEC39;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC51_BBCH50' then fOptimizeOpt := OOEC51;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC61_BBCH60' then fOptimizeOpt := OOEC61;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_EC69_BBCH69' then fOptimizeOpt := OOEC69;
end;


procedure TDevelopmentOSR.CalcRates;

Var
  StateVar : TState;
  i : integer;

function dFv_dt(T:real):real;
  begin
    if (T>Tvmin.v) and (T<Tvopt1.v) then result := (T-Tvmin.v)/(Tvopt1.v-Tvmin.v)
    else if (T>=Tvopt1.v) and (T<=Tvopt2.v) then result := 1
    else if (T>Tvopt2.v) and (T<Tvmax.v) then result := 1-(T-Tvopt2.v)/(Tvmax.v-Tvopt2.v)
    else result := 0;
  end;

  function Fphoto (Dl:real) : real;
  begin
    if (Dl<Dlpmin.v) then result := 0
    else if (Dl<Dlpopt.v) then result := (Dl-Dlpmin.v)/(Dlpopt.v-Dlpmin.v)
    else result :=1;
  end;

begin
  Teff.v :=  max(0,Tmpm.v-Tb.v);
  Fp.v := Fphoto(DaylengthP.v);
  DVR1.v :=  Teff.v*aT1.v;
  DVR2.v :=  Teff.v*aT2.v*Fp.v*Fv.v;
  DVR2a.v := Teff.v*aT2a.v;
  DVR3.v :=  Teff.v*aT3.v;
  DVR4.v :=  Teff.v*aT4.v;

  if (Globtime.v >= SowingDate.v) and (EC.v<100.0) then begin
     // calculated development rates according to DVS stage
    if (DVS.v < 1) or (fOptimizeOpt = OOEC11) then
     DVS.c := DVR1.v
    else if (DVS.v < DVSInflor.v) or (ord(fOptimizeOpt) <= ord(OOEC51)) then
     DVS.c := DVR2.v
    else if (DVS.v < 2) or (fOptimizeOpt = OOEC61) then
     DVS.c := DVR2a.v
    else if (DVS.v < 3) or (fOptimizeOpt = OOEC69) then DVS.c := DVR3.v else
     DVS.c := DVR4.v;
    // if DVS changes inbetween integration step
    if (DVS.v < 1) and (DVS.v +DVS.c >1) and (ord(fOptimizeOpt) > ord(OOEC11)) then
         DVS.c := (1- DVS.v)+DVR2.v*(1-(1-DVS.v)/DVR1.v);
    if (DVS.v < DVSInflor.v) and (DVS.v +DVS.c >DVSInflor.v) and (ord(fOptimizeOpt) > ord(OOEC39)) then
         DVS.c := (DVSInflor.v- DVS.v)+DVR2a.v*(1-(DVSInflor.v-DVS.v)/DVR2.v);
    if (DVS.v < 2) and (DVS.v +DVS.c >2) and (ord(fOptimizeOpt) > ord(OOEC61)) then
         DVS.c := (2- DVS.v)+DVR3.v*(1-(2-DVS.v)/DVR2a.v);
    if (DVS.v < 3) and (DVS.v +DVS.c >3) and (ord(fOptimizeOpt) > ord(OOEC69)) then
         DVS.c := (3- DVS.v)+DVR4.v*(1-(3-DVS.v)/DVR3.v);
  end;

  If  (TS11.v >= TSumCotEm.v) and (DVS.v<DVS30.v)
    then Blattanzahl.c := Teff.v/Phyllochron.v
    else Blattanzahl.c := 0  ;
  If  (DVS.v>=DVS30.v) and ((DVS.v<DVSInflor.v) or (fOptimizeOpt = OOEC39))
    then NumExtInternodes.c := Teff.v/TSumInternode.v
    else NumExtInternodes.c := 0  ;
  // Calculate Vernalisation factor change rate
  If  (DVS.v>=1) and (Fv.v<1)
    then Fv.c := min(dFv_dt(Tmpm.v)*Rvmax.v,1-Fv.v)
    else  Fv.c :=   0  ;
  TS.c :=  Teff.v;
  if DVS.v >= 1 then TS11.c := Teff.v
  else if DVS.v+DVS.c > 1 then TS11.c := Teff.v-(1-DVS.v)/aT1.v;
  if EC.v>=100 then begin
    for I := 0 to StateStrList.Count - 1 do begin
      StateVar := TState(StateStrList.objects[i]);
      StateVar.c := 0.0;
    end;
  end;
end;


procedure TDevelopmentOSR.Integrate;
begin
  inherited;
  if (DVS.v <= 1) or (fOptimizeOpt = OOEC11) then EC.v := 1 + DVS.v*10
  else if (TS11.v <= TSumCotEm.v) or (fOptimizeOpt = OOEC13) then EC.v := 11+2*TS11.v/TSumCotEm.v
  else if (DVS.v <= DVS30.v) or (fOptimizeOpt = OOEC27) then
  begin
    if Blattanzahl.v <=4 then EC.v := 13+Blattanzahl.v*2
    else if Blattanzahl.v <=9 then EC.v := 21+Blattanzahl.v-4
    else if Blattanzahl.v <=12 then EC.v := 26+(Blattanzahl.v-9)/3
    else EC.v := 27;
  end
  else if (DVS.v <= DVSInflor.v) or (fOptimizeOpt = OOEC39) then begin
    if NumExtInternodes.v <= 9 then EC.v := 30+ NumExtInternodes.v
    else EC.v := 39;
  end

  else if DVS.v <=2 then
  begin
    EC.v := 51+(DVS.v-DVSInflor.v)*10/(2-DVSInflor.v);
//    if EC.v >= 40 then EC.v := EC.v+10;
  end
  else if DVS.v <=3 then EC.v := 61+(DVS.v-2)*9
  else EC.v := 70+(DVS.v -3)*19;


  if EC.v<=3 then BBCH.v:= EC.v-1
  else if EC.v<=5 then BBCH.v:= (EC.v-3)/2*3+2
  else if EC.v<=7 then BBCH.v:= EC.v
  else if Ec.v<=21 then BBCH.v:= (EC.v-7)/2+7
  else if EC.v<=26 then BBCH.v:= EC.v-7
  else if EC.v<30 then BBCH.v:= 19
  else if EC.v<40 then BBCH.v:= EC.v
  else if EC.v<=57 then BBCH.v:= (EC.v-50)/2+49.5
  else if EC.v<=60 then BBCH.v:= (EC.v-57)*2+53
  else if EC.v<=61 then BBCH.v:= EC.v-1
  else if EC.v<=64 then BBCH.v:= (EC.v-61)/3*5+60
  else if EC.v<=65 then BBCH.v:= (EC.v-64)*2+65
  else if EC.v<=69 then BBCH.v:= (EC.v-65)/2+67
  else if EC.v<=79 then BBCH.v:= EC.v
  else if EC.v<=83 then BBCH.v:= (EC.v-79)/2+79
  else if EC.v<=87 then BBCH.v:= Ec.v-2
  else if EC.v<=89 then BBCH.v:= (EC.v-87)*2+85;
  if EC.v >= 90 then BBCH.v := EC.v;


  if DVS30.v <> 0 then BBCH30.v := DVS.v/DVS30.v else BBCH30.v := 0;
  if DVSInflor.v <> 0 then BBCH50.v := DVS.v/DVSInflor.v else BBCH50.v := 0;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TDevelopmentOSR]);
end;

end.
