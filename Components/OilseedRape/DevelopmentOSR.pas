unit DevelopmentOSR;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
//  vcl.Graphics,
//  vcl.Controls,
//  vcl.Forms,
//  vcl.Dialogs,
   UMod,
    UState;

Type
/// <summary>Selects the final phenological stage included during calibration or optimization.</summary>
TOptimizeOpt = (OOEC11, OOEC13, OOEC27, OOEC39, OOEC51, OOEC61, OOEC69, OOAll);

/// <summary>
/// Calculates phenological development of winter oilseed rape, including temperature, photoperiod, and vernalisation effects.
/// </summary>
TDevelopmentOSR = class(TSubmodel)

private
  /// <summary>Internal representation of the selected optimization range.</summary>
  fOptimizeOpt: TOptimizeOpt;

protected

public
  /// <summary>Development rate from sowing to emergence.</summary>
  DVR1  : TVar;
  /// <summary>Development rate from emergence to EC 27.</summary>
  DVR2  : TVar;
  /// <summary>Development rate from EC 27 to EC 39.</summary>
  DVR2a : TVar;
  /// <summary>Development rate from EC 39 to the beginning of flowering.</summary>
  DVR2b : TVar;
  /// <summary>Development rate until the end of flowering.</summary>
  DVR3  : TVar;
  /// <summary>Development rate until maturity.</summary>
  DVR4  : TVar;
  /// <summary>Effective daily temperature, calculated as daily mean temperature minus base temperature.</summary>
  Teff  : TVar;
  /// <summary>Photoperiod factor.</summary>
  Fp    : TVar;
  /// <summary>Effective influence of photoperiod on the development rate.</summary>
  Fp_eff : TVar;
  /// <summary>Effective influence of vernalisation on the development rate.</summary>
  FV_eff : TVar;

  /// <summary>Phenological stage on the BBCH scale.</summary>
  BBCH  : TVar;
  /// <summary>Phenological stage on the Schuette EC scale, derived from DVS.</summary>
  EC    : TVar;
  /// <summary>Auxiliary variable used to estimate DVS at BBCH 30.</summary>
  BBCH30: TVar;
  /// <summary>Auxiliary variable used to estimate DVS at inflorescence emergence.</summary>
  BBCH50: TVar;
  /// <summary>Day of year on which flowering starts.</summary>
  DOY51 : TVar;
  /// <summary>Day of year on which full ripening is reached.</summary>
  DOY90 : TVar;

  // State variables
  /// <summary>Continuous development stage.</summary>
  DVS : TState;
  /// <summary>Number of leaves.</summary>
  Blattanzahl : TState;
  /// <summary>Number of extended internodes between BBCH stages 30 and 39.</summary>
  NumExtInternodes: TState;
  /// <summary>Accumulated vernalisation factor.</summary>
  Fv : TState;
  /// <summary>Accumulated effective temperature sum.</summary>
  TS : TState;
  /// <summary>Temperature sum accumulated after DVS 1 (BBCH 9 / EC 11).</summary>
  TS11: TState;

             // Parameters
  /// <summary>Temperature response coefficient for development up to EC 11.</summary>
  aT1 : TPar;
  /// <summary>Temperature response coefficient for development from EC 11 to EC 39.</summary>
  aT2 : TPar;
  /// <summary>Temperature response coefficient for development from EC 39 to EC 61.</summary>
  aT2a : TPar;
  /// <summary>Temperature response coefficient for development from EC 61 to EC 69.</summary>
  aT3 : TPar;
  /// <summary>Temperature response coefficient for development from EC 69 to EC 89.</summary>
  aT4 : TPar;
  /// <summary>Sensitivity of development to vernalisation.</summary>
  fv_sens : TPar;
  /// <summary>Sensitivity of development to photoperiod.</summary>
  fp_sens : TPar;

  /// <summary>Thermal time required for the appearance of one leaf.</summary>
  Phyllochron : TPar;
  /// <summary>Thermal time required to extend one internode.</summary>
  TSumInternode: TPar;
  /// <summary>Maximum vernalisation rate.</summary>
  Rvmax : TPar;
  /// <summary>Base temperature for development.</summary>
  Tb : TPar;
  /// <summary>Minimum temperature for vernalisation.</summary>
  Tvmin : TPar;
  /// <summary>Lower optimum temperature for vernalisation.</summary>
  Tvopt1 : TPar;
  /// <summary>Upper optimum temperature for vernalisation.</summary>
  Tvopt2 : TPar;
  /// <summary>Maximum temperature for vernalisation.</summary>
  Tvmax : TPar;
  /// <summary>Minimum day length used by the photoperiod response.</summary>
  Dlpmin : TPar;
  /// <summary>Optimum day length used by the photoperiod response.</summary>
  Dlpopt : TPar;
  /// <summary>Estimated DVS at EC 30.</summary>
  DVS30 : TPar;
  /// <summary>Estimated DVS at EC 13.</summary>
  DVS13 : TPar;
  /// <summary>DVS at the beginning of inflorescence emergence (BBCH 50 / EC 51).</summary>
  DVSInflor: TPar;
  /// <summary>Temperature sum from first cotyledon appearance to complete unfolding (DVS 1 / BBCH 9 to BBCH 10).</summary>
  TSumCotEm: TPar;
  /// <summary>Sowing date represented as simulation time.</summary>
  SowingDate : TPar;
  /// <summary>Scaling factor for the vegetative development rate.</summary>
  ScaleDevVeg : TPar;
  /// <summary>Scaling factor for the generative development rate.</summary>
  ScaleDevGen : TPar;


  /// <summary>Defines the final EC stage considered in development calculations.</summary>
  OptimizeOpt : TOption;

             // External variables
  /// <summary>External day length.</summary>
  DayLengthP : TExternV;
  /// <summary>External daily mean temperature.</summary>
  Tmpm       : TExternV;


  /// <summary>Creates and registers all variables, state variables, parameters, external variables, and options.</summary>
  procedure CreateAll; override;
  /// <summary>Initializes state variables and resolves the selected optimization option.</summary>
  procedure Init(var GlobMod: TMod); override;
  /// <summary>Calculates daily development, leaf appearance, internode extension, and vernalisation rates.</summary>
  procedure CalcRates; override;
  /// <summary>Integrates state variables and maps DVS to EC and BBCH stages.</summary>
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
  Property Var_Fp_eff : TVar read Fp_eff write Fp_eff;
  Property Var_Fv_eff : TVar read Fv_eff write Fv_eff;
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

  Property Par_fv_sens : TPar read fv_sens write fv_sens;
  Property Par_fp_sens : TPar read fp_sens write fp_sens;

  Property Par_Phyllochron : TPar read Phyllochron write Phyllochron;
  Property Par_Rvmax : TPar read Rvmax write Rvmax;
  Property Par_Tb : TPar read Tb write Tb;
  Property Par_DVS30 : TPar read DVS30 write DVS30;
  Property Par_DVS13 : TPar read DVS13 write DVS13;
  Property Par_DVSInflor: TPar read DVSInflor write DVSInflor;
  Property Par_SowingDate : TPar read SowingDate write SowingDate;
  Property Par_TSumCotEm: TPar read TSumCotEm write TSumCotEm;
  Property Par_ScaleDevVeg: TPar read ScaleDevVeg write ScaleDevVeg;
  Property Par_ScaleDevGen: TPar read ScaleDevGen write ScaleDevGen;



         // Published external-variable properties
  Property Ex_DayLengthP : TExternV read DayLengthP write DayLengthP;
  Property Ex_Tmpm : TExternV read Tmpm write Tmpm;


end;

procedure Register;

implementation
uses Math, System.DateUtils;



procedure TDevelopmentOSR.createAll;

begin
  inherited createAll;
  VarCreate('DVR1', '[-]',0, true, DVR1, 'Development rate from sowing to emergence');
  VarCreate('DVR2', '[-]',0, true, DVR2, 'Development rate from emergence to end of vegetative growth');
  VarCreate('DVR2a', '[-]',0, true, DVR2a, 'Development rate from emergence to end of vegetative growth (alternative calculation)');
  VarCreate('DVR2b', '[-]',0, true, DVR2b, 'Development rate from emergence to end of vegetative growth (another alternative calculation)');
  VarCreate('DVR3', '[-]',0, true, DVR3, 'Development rate from end of vegetative growth to flowering');
  VarCreate('DVR4', '[-]',0, true, DVR4, 'Development rate from flowering to full ripening');
  VarCreate('Teff', '[�C]',0, true, Teff,'Effective daily temperature, calculated as daily mean temperature minus base temperature');
  VarCreate('Fp', '[-]',0, true, Fp, 'Photoperiod factor');
  VarCreate('Fp_eff', '[-]',0, true, Fp_eff, 'effect of photoperiod on development rate');
  VarCreate('Fv_eff', '[-]',0, true, Fv_eff, 'effect of vernalisation on development rate');
  VarCreate('BBCH', '[-]',0, true, BBCH,'Phenological stage on the BBCH scale');
  VarCreate('EC', '[-]',0, true,EC,'Phenological stage on the Schuette EC scale');
  VarCreate('BBCH30', '[-]',0, true, BBCH30,'Variable for estimating DVS30');
  VarCreate('BBCH50', '[-]',0, true, BBCH50,'Variable for estimating DVSInflor');
  VarCreate('DOY51', '[-]',0, true, DOY51,'DOY of flowering start');
  VarCreate('DOY90', '[-]',0, true, DOY90,'DOY of full ripening stage');


  StateCreate('DVS', '[-]',0, true, DVS, 'Continuous development stage');
  StateCreate('Blattanzahl', '[n]',0, true,Blattanzahl, 'Number of leaves');
  StateCreate('NumExtInternodes', '[n]', 0, true, NumExtInternodes, 'Number of extended internodes (BBCH stages 30 to 39)');
  StateCreate('Fv', '[-]',0, true,Fv, 'Accumulated vernalisation factor');
  StateCreate('TS', '[-]',0, true,TS, 'Accumulated effective temperature sum');
  StateCreate('TS11', '[-]',0, true,TS11, 'Temperature sum accumulated after DVS 1 (BBCH 9 / EC 11)');

  // Parameters
  ParCreate('aT1', '[1/(�C*d)]',0.0077212,aT1, 'Temperature response coefficient for development up to EC 11');
  ParCreate('aT2', '[1/(�C*d)]',0.0296873,aT2, 'Temperature response coefficient for development from EC 11 to EC 27');
  ParCreate('aT2a', '[1/(C*d)]',0.0296873,aT2a, 'Temperature response coefficient for development from EC 11 to EC 27 (alternative calculation)');
  ParCreate('aT3', '[1/(C*d)]',0.0051036,aT3, 'Temperature response coefficient for development from EC 27 to EC 51');
  ParCreate('aT4', '[1/(C*d)]',0.0014651,aT4, 'Temperature response coefficient for development from EC 51 to EC 69');
  ParCreate('fv_sens', '[-]', 1, fv_sens, 'vernalisaton sensitivity [0..1]');
  ParCreate('fp_sens', '[]', 1, fp_sens, 'photoperiod sensitivity [0..1]');
  ParCreate('Phyllochron', '[�Cd]',59.2,Phyllochron, 'Phyllochron interval');
  ParCreate('TSumInternode', '[Cd]',25,TSumInternode, 'Temperature sum for internode extension');
  ParCreate('Rvmax', '',0.014553,Rvmax, 'Maximum development rate');
  ParCreate('Tb', '[C]',3,Tb, 'Base temperature');
  ParCreate('Tvmin', '[C]',-3.7182,Tvmin, 'Minimum temperature for development');
  ParCreate('Tvopt1', '[C]',0.7260,Tvopt1, 'Optimum temperature for development');
  ParCreate('Tvopt2', '[�C]',5.3770,Tvopt2, 'Optimum temperature for development');
  ParCreate('Tvmax', '[C]',17.2022,Tvmax, 'Maximum temperature for development');
  ParCreate('Dlpmin', '[h]',5.7,Dlpmin, 'Minimum day length for development');
  ParCreate('Dlpopt', '[h]',14.8,Dlpopt, 'Optimum day length for development');
  ParCreate('DVS30', '[-]',1.3,DVS30, 'DVS at EC 30');
  ParCreate('DVS13', '[-]',1.00072,DVS13, 'DVS at EC 13');
  ParCreate('DVSInflor','[-]',1.327,DVSInflor,'DVS at beginning of inflorescence emergence (BBCH=50 / EC=51)');
  ParCreate('SowingDate', '[-]',1,SowingDate, 'Sowing date');
  ParCreate('TSumCotEm','[C d]',60,TSumCotEm,'Temperature Sum from first appearance of Cotyledons to complete unfolding (DVS=1/BBCH=9 to BBCH=10)');

  ParCreate('ScaleDevVeg','[-]',1 ,ScaleDevVeg,'Scaling factor for vegetative development rate');
  ParCreate('ScaleDevGen','[-]',1 ,ScaleDevGen,'Scaling factor for generative development rate');


  // External Variables
  ExternVCreate('DayLengthP', '',statefield, DayLengthP, 'External day length');
  ExternVCreate('TMPM', '',statefield, Tmpm, 'External daily mean temperature');

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
  DOY51.v := 0;
  DOY90.v := 0;

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
  Fp_eff.v := max(0, min(1,fp.v+(1-fp_sens.v)*(1-Fp.v)));
  Fv_eff.v := max(0, min(1,fv.v+(1-fv_sens.v)*(1-Fv.v)));
  DVR1.v :=  ScaleDevVeg.v*Teff.v*aT1.v;
  DVR2.v :=  ScaleDevVeg.v*Teff.v*aT2.v*Fp_eff.v*Fv_eff.v;
  DVR2a.v := ScaleDevVeg.v*Teff.v*aT2a.v;
  DVR3.v :=  ScaleDevGen.v*Teff.v*aT3.v;
  DVR4.v :=  ScaleDevGen.v*Teff.v*aT4.v;

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
  if (DOY51.v <= 0) and (EC.v>=51) then begin
    DOY51.v := DayOfTheYear(GlobTime.v);
  end;
  if (DOY90.v <= 0) and (EC.v>=90) then begin
    DOY90.v := DayOfTheYear(GlobTime.v);
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TDevelopmentOSR]);
{$ENDIF}


end;

end.
