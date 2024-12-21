unit  UIrrigate_ISIP;

 {
   Automatic irrigation when Transratio.v falls below a threshold value (IrriTHV).
   Irrigation amount of a singel irrigation event is calculated from the total
   charge of irrigation water (IrriQuantity) and maximal number of
   irrigation events (IrriEvents).

 }
interface

uses
  UMod, UState, IniFiles, Classes, UIrrigate;

const
  MaxIrriDates = 100;

type
  TIrrigation = (irri, no_irri);
  TpFcrit = (calculated, fromparam);
  TIrrigate_ISIP = class(TSubModel)

  private
    fIrri: TIrrigation;
    fTH: TpFcrit;


  protected

    procedure CreateAll; override;

  public
    TransRatio:  TExternV;
    ProzNFK0_Weff: TExternV;
    PSIroot: TExternV;
    Rain:        TExternV;
    EC:          TExternV;
    IrrQuantity: TPar;
    sumIrrigation: TState;
    IrrTHV:      TPar;
    IrrEvents:   TPar;
    //LastIrr: TVar;
    pF_Crit: TVar;
    LeftIrr:       integer;
    LastIrr:       real;
    optIrrigation: TOption;
    optTH: TOption;
    procedure CalcRates; override;
    procedure Init(var GlobMod: TMod); override;

  published



  end;

procedure Register;

implementation

uses Math, SysUtils, vcl.Dialogs;

procedure TIrrigate_ISIP.CreateAll;
begin
  ExternVcreate('TransRatio', '[-]', StateField, TransRatio);
  ExternVcreate('ProzNFK0_Weff', '[-]', StateField, ProzNFK0_Weff);
  ExternVcreate('psiRoot', '[pF]', StateField, psiRoot);
  ExternVcreate('Rain', '[-]', StateField, Rain);
  ExternVcreate('EC', '[-]', StateField, EC);
  ParCreate('IrrQuantity', '[mm]', 0, IrrQuantity);
  ParCreate('IrrEvents', '[-]', 0, IrrEvents);
  ParCreate('IrrTHV', '[-]', 2.5, IrrTHV);
  VarCreate('pF_Crit', '[pF]', 0, True, pF_Crit);
  StateCreate('SumIrrigation', '[mm]', 0, True, SumIrrigation);
  OptCreate('optIrrigation', 'Irrigation', optIrrigation);
  optIrrigation.OptionList.Clear;
  optIrrigation.OptionList.Add('Irrigation');
  optIrrigation.OptionList.Add('no_Irrigation');
  OptCreate('optTH', 'calculated', optTH);
  optTH.OptionList.Clear;
  optTH.OptionList.Add('calculated');
  optTH.OptionList.Add('fromParam');
  //VarCreate('LastIrr', '[date]',0,true LastIrr);

  inherited;

end;

procedure TIrrigate_ISIP.Init(var GlobMod: TMod);

begin
  inherited;
  if optIrrigation.option = 'irrigation' then
  begin
    fIrri := irri;
  end;
  if optIrrigation.option = 'no_irrigation' then
  begin
    fIrri := no_irri;
  end;
  LeftIrr := Trunc(IrrEvents.v);
  LastIrr := 0;

  if optTH.option = 'calculated' then
  begin
    fTH := calculated;
  end;
  if optTH.option = 'fromparam' then
  begin
    fTH := fromParam;
  end;



end;


procedure TIrrigate_ISIP.calcrates;
var
  irrdistance: integer;
  Amount: real;
  Year_st, Month_st, Day_st: word;
  Year_gt, Month_gt, Day_gt: word;
begin

     pF_Crit.v:=  -2E-05*power(min(125,max(50,IrrQuantity.v)),2)
     - 0.0009*min(125,max(50,IrrQuantity.v)) + 3.1283;

     if fTH = fromParam then
     pF_Crit.v:= IrrTHV.v;  //optional auch mit fixem Schwellenwert

     if (fIrri = irri) and (PSIroot.v > pF_Crit.v) then // dyn. Schwellenwert ar 23.05.11
     begin
      if IrrEvents.v > 0 then
       Amount := Round(IrrQuantity.v / IrrEvents.v)
      else
       Amount := 0;

      irrdistance := max(5, round(Amount / 10 + 1));

    DecodeDate(Globtime.v, Year_gt, Month_gt, Day_gt);
    DecodeDate(Globmod.Starttime, Year_st, Month_st, Day_st);
  if (LeftIrr > 0) {and (Year_gt=Year_st+1)} and (EC.v>=31) and (globtime.v > LastIrr + irrdistance) and    // Beregnung schon bei BBCH 30 erlauben ar 23.05.11
      (Amount > 0) then
    begin
      Rain.f_v^ := Rain.v + Amount;
      sumIrrigation.c := Amount;
      LeftIrr := LeftIrr - 1;
      {if globtime.v> LastIrr then} LastIrr := globtime.v;
    end else
      sumIrrigation.c := 0;
  end else
    sumIrrigation.c := 0;

end;



procedure Register;

begin
  RegisterComponents('Simulation', [TIrrigate_ISIP]);
end;




end.