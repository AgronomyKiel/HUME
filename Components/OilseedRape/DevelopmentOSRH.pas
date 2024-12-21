unit DevelopmentOSRH;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
  vcl.Dialogs, UMod, UState;

Type
TOptimizeOpt = (OODVS1, OODVS2, OODVS3, OOAll);

TDevelopmentOSRH = class(TSubmodel)

private
  fOptimizeOpt: TOptimizeOpt;

protected

public
  DVR1 : TVar;   // Entwicklungsrate bis Auflauf
  DVR2 : TVar;   // Entwicklungsrate bis EC60
  DVR3 : TVar;   // Entwicklungsrate bis Blühende
  DVR4 : TVar;   // Entwicklungsrate bis Reife
  Fp: TVar;  // photoperiodischer Faktor
  BBCH: TVar; // Entwicklungsstadium nach BBCH
  EC: TVar; // Entwicklungsstadium nach Schütte aus DVS

  // Constant Variables

  Fv : TState;   //
  DVS : TState; // Entwicklungsstadium


             // Parameters
  aT1 : TPar;   // Parameter für Entwicklungsrate bis EC11
  aT2 : TPar;   // Parameter für Entwicklungsrate EC11 bis EC60
  aT3 : TPar;   // Parameter für Entwicklungsrate EC61 bis EC69
  aT4 : TPar;   // Parameter für Entwicklungsrate EC69 bis EC89
  Rvmax : TPar;   // Maximale Vernalisationsrate
  Tb1 : TPar;   // Basis-Temperatur
  Tb2 : TPar;   // Basis-Temperatur
  Tb3 : TPar;   // Basis-Temperatur
  Tb4 : TPar;   // Basis-Temperatur
  Tvmin : TPar; // Minimaltemperatur für Vernalisation
  Tvopt1 : TPar; // Untere optimale Vernalisationstemperatur
  Tvopt2 : TPar; // Obere optimale Vernalisationstemperatur
  Tvmax : TPar; // Maximaltemperatur für Vernalisation
  Dlpmin : TPar; //Minimale Tageslänge für Photoperiodischen Faktor Pb
  Dlpopt : TPar; //Optimale Tageslänge für Photoperiodischen Faktor Psat

  OptimizeOpt: TOption;

             // External Variables
  DayLengthP : TExternV;   //
  Tmpm : TExternV;   //


  procedure CreateAll; override;
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override; 
  procedure Integrate; override;

published
  Property Var_DVR1 : TVar read DVR1 write DVR1;
  Property Var_DVR2 : TVar read DVR2 write DVR2;
  Property Var_DVR3 : TVar read DVR3 write DVR3;
  Property Var_DVR4 : TVar read DVR4 write DVR4;
  Property Var_BBCH : TVar read BBCH write BBCH;
  Property Var_EC : TVar read EC write EC;


  Property St_Fv : TState read Fv write Fv;
  Property St_DVS : TState read DVS write DVS;


         // Parameters
  Property Par_aT1 : TPar read aT1 write aT1;
  Property Par_aT2 : TPar read aT2 write aT2;
  Property Par_aT3 : TPar read aT3 write aT3;
  Property Par_aT4 : TPar read aT4 write aT4;
  Property Par_Rvmax : TPar read Rvmax write Rvmax;
  Property Par_Tb1 : TPar read Tb1 write Tb1;
  Property Par_Tb2 : TPar read Tb2 write Tb2;
  Property Par_Tb3 : TPar read Tb3 write Tb3;
  Property Par_Tb4 : TPar read Tb4 write Tb4;

         // Properties External Variables
  Property Ex_DayLengthP : TExternV read DayLengthP write DayLengthP;
  Property Ex_Tmpm : TExternV read Tmpm write Tmpm;


end;  // SubmodelName

procedure Register;

implementation
uses Math;

procedure TDevelopmentOSRH.createAll;

begin
  inherited createAll;
  VarCreate('DVR1', '',0, true, DVR1);
  VarCreate('DVR2', '',0, true, DVR2);
  VarCreate('DVR3', '',0, true, DVR3);  
  VarCreate('DVR4', '',0, true, DVR4);
  VarCreate('Fp', '',0, true, Fp);
  VarCreate('BBCH', '',0, true, BBCH, 'Entwicklungsstadium nach BBCH');
  VarCreate('EC', '',0, true, EC, 'Entwicklungsstadium aus DVS');

  StateCreate('Fv', '',0, true,Fv);
  StateCreate('DVS', '',0, true,DVS);


  // Parameters
  ParCreate('aT1', '',0.0077212,aT1);
  ParCreate('aT2', '',0.0020083,aT2);
  ParCreate('aT3', '',0.0051036,aT3);
  ParCreate('aT4', '',0.0014651,aT4);
  ParCreate('Rvmax', '',0.014553,Rvmax);
  ParCreate('Tb1', '[°C]',0.3024,Tb1);
  ParCreate('Tb2', '[°C]',0.5444,Tb2);
  ParCreate('Tb3', '[°C]',4.9163,Tb3);
  ParCreate('Tb4', '[°C]',0.6870,Tb4);
  ParCreate('Tvmin', '[°C]',-3.7182,Tvmin);
  ParCreate('Tvopt1', '[°C]',0.7260,Tvopt1);
  ParCreate('Tvopt2', '[°C]',5.3770,Tvopt2);
  ParCreate('Tvmax', '[°C]',17.2022,Tvmax);
  ParCreate('Dlpmin', '[h]',5.7416,Dlpmin);
  ParCreate('Dlpopt', '[h]',14.8014,Dlpopt);


         // External Variable
  ExternVCreate('DayLengthP', '',statefield, DayLengthP);
  ExternVCreate('TMPM', '',statefield, Tmpm);

  OptCreate('OptimizeOption', 'All', OptimizeOpt,
    'Specifies until which DVS stage data and development rates are considered');
  OptimizeOpt.OptionList.Clear;
  OptimizeOpt.OptionList.Add('All');
  OptimizeOpt.OptionList.Add('Until_DVS1');
  OptimizeOpt.OptionList.Add('Until_DVS2');
  OptimizeOpt.OptionList.Add('Until_DVS3');
end;


procedure TDevelopmentOSRH.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  Fv.v := 0;
  DVS.v := 0;
  if uppercase(OptimizeOpt.Option) = 'ALL' then fOptimizeOpt := OOAll;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_DVS1' then fOptimizeOpt := OODVS1;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_DVS2' then fOptimizeOpt := OODVS2;
  if uppercase(OptimizeOpt.Option) = 'UNTIL_DVS3' then fOptimizeOpt := OODVS3;
end;


procedure TDevelopmentOSRH.CalcRates;
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
  DVR1.v :=  max(0,Tmpm.v-Tb1.v)*aT1.v;
  Fp.v := Fphoto(DaylengthP.v);
  DVR2.v :=  max(0,Tmpm.v-Tb2.v)*aT2.v*Fp.v*Fv.v;
  DVR3.v :=  max(0,Tmpm.v-Tb3.v)*aT3.v;
  DVR4.v :=  max(0,Tmpm.v-Tb4.v)*aT4.v;

  if (DVS.v < 1) or (fOptimizeOpt = OODVS1) then DVS.c := DVR1.v
  else if (DVS.v < 2) or (fOptimizeOpt = OODVS2) then DVS.c := DVR2.v
  else if (DVS.v < 3) or (fOptimizeOpt = OODVS3) then DVS.c := DVR3.v
  else DVS.c := DVR4.v;
  if (DVS.v <1) and (DVS.v + DVS.c >1) and (ord(fOptimizeOpt) >0) then DVS.c := (1- DVS.v) +DVR2.v*(1-(1-DVS.v)/DVR1.v)
  else if (DVS.v <2) and (DVS.v + DVS.c >2) and (ord(fOptimizeOpt) >1) then DVS.c := (2- DVS.v) +DVR3.v*(1-(2-DVS.v)/DVR2.v)
  else if (DVS.v <3) and (DVS.v + DVS.c >3) and (ord(fOptimizeOpt) >2) then DVS.c := (3- DVS.v) +DVR4.v*(1-(3-DVS.v)/DVR3.v);
  If  (DVS.v >= 1) and (Fv.v < 1)
    then Fv.c := min(dFv_dt(Tmpm.v)*Rvmax.v,1-Fv.v)
    else  Fv.c :=   0  ;

end;

procedure TDevelopmentOSRH.Integrate;
begin
  inherited;

  if  DVS.v<1 then EC.v :=   DVS.v*11
  else   If  (DVS.v >= 1) and (DVS.v < 2) then
  begin
    EC.v := 11+(DVS.v-1)*37;
    if EC.v>27  then EC.v := EC.v+3;
    if EC.v>=40 then EC.v := EC.v+10;
  end
  else   If  (DVS.v >= 2) and (DVS.v < 3) then EC.v :=   (DVS.v-2)*8+61
  else   If  (DVS.v >= 3) and (DVS.v < 4) then EC.v :=   (DVS.v-3)*20+69;


  if EC.v<=3 then BBCH.v := EC.v-1
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

end;




procedure Register;
begin
  RegisterComponents('Simulation', [TDevelopmentOSRH]);
end;

end.
