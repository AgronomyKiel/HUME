unit USubDryMatterSimple_GF;

 // simplified version of the dry matter production module for parameterisation
 // 'SWDF' is a none linear funktion of 'transratio' according to (Ferreyra 2003)
 // 'PCARB' is limited by 'SWDF' or spezific leaf N (SLN) 

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState,
  URootedSoil, USubDrymatterSimple;

type


  TCarboRed = (CWT3, Concentration, noCarboRed);

  TsubdrymatterSimple_GF = class(TSubDrymatterSimple)

  private
  protected
    fCarboRed: TCarboRed;
  public

    CARBOred: TVar;   // Reduction factor for assimilation during ripening [0..1]

    {RSUMT4570: TSTATE;
    RSUMT4090: TSTATE;
    RSUMT4080: TSTATE;
    RSUMT4575: TSTATE;
    RSUMT4590: TSTATE;
    RSUMT5075: TSTATE;
    RSUMT5580: TSTATE;
    RSUMT6085: TSTATE;
    RSUMT6590: TSTATE;}
    RSUMT5080: TSTATE;
    RSUMSS:    TSTATE;
    QHI: TVar;
    int:         TPar;
    Carbored_b:  TPar;
    //TR_x : TPAR;
    //TR_y : TPAR;
    pSWDF:       TPAR;
    SLN_crit:    TPar;
    Ncleaf:      TExternV;
    EC_LGEND:    TExternV;
    SLN:         TExternV;
    SumDTT5:     TExternV;
    TransIntRatio:     TExternV;
    OptCarboRed: Toption;
    SUMGRHI: real;
    SUMTEMPHI: real;
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    { procedure Integrate; override;}

  published

    property Ex_EC_LGEND: TExternV Read EC_LGEND Write EC_LGEND;
    property Ex_TransIntRatio: TExternV Read TransIntRatio Write TransIntRatio;


  end;  // SubmodelName

procedure Register;

implementation

uses Math, UModUtils;

procedure TSubDryMatterSimple_GF.createAll;
begin
  inherited createAll;
  // ParCreate('TR_x','[-]', 1, TR_x);
  // ParCreate('TR_y','[-]', 1, TR_y);pSWDF
  ParCreate('pSWDF', '[-]', 1, pSWDF,
    'parameter for none linear relation between Tansratio and SWDF (Ferreyra 2003)');
  ParCreate('int', '[-]', 1, int);
  ParCreate('carbored_b', '[-]', 1, carbored_b);
  ParCreate('SLN_crit', '[-]', 2, SLN_crit);
  VarCreate('CARBOred', '[0..1]', 0, True, CARBOred);
  VarCreate('QHI', '[0..1]', 0, True, QHI);

 {StateCreate('RSUMT4570', '[-]', 0, True, RSUMT4570);
  StateCreate('RSUMT4090', '[-]', 0, True, RSUMT4090);
  StateCreate('RSUMT4080', '[-]', 0, True, RSUMT4080);
  StateCreate('RSUMT4575', '[-]', 0, True, RSUMT4575);
  StateCreate('RSUMT5075', '[-]', 0, True, RSUMT5075);
  StateCreate('RSUMT5580', '[-]', 0, True, RSUMT5580);
  StateCreate('RSUMT6085', '[-]', 0, True, RSUMT6085);
  StateCreate('RSUMT6590', '[-]', 0, True, RSUMT6590);
  StateCreate('RSUMT4590', '[-]', 0, True, RSUMT4590);}
  StateCreate('RSUMT5080', '[-]', 0, True, RSUMT5080);
  StateCreate('RSUMSS', '[-]', 0, True, RSUMSS);
  ExternVCreate('SumDTT5', '[°Cd]', statefield, SumDTT5);
  ExternVCreate('SLN', '[g/m2]', statefield, SLN);
  ExternVCreate('NcLeaf', '[%]', statefield, NcLeaf);
  ExternVCreate('EC_LGEnd', '[-]', statefield, EC_LGEnd);
  ExternVCreate('TransIntRatio', '[-]', statefield, TransIntRatio);
  OptCreate('CarboRed', 'CWT3', optCarbored);
  optCarbored.OptionList.Clear;
  optCarbored.OptionList.Add('CWT3');
  optCarbored.OptionList.Add('Concentration');
  optCarbored.OptionList.Add('noCarboRed');

end;


procedure TSubDryMatterSimple_GF.init(var GlobMod: TMod);

begin
  inherited;
  if optCarbored.option = 'cwt3' then
  begin
    fCarboRed := CWT3;
  end;
  if optCarbored.option = 'concentration' then
  begin
    fCarbored := Concentration;
  end;
  if optCarbored.option = 'nocarbored' then
  begin
    fCarbored := noCarboRed;
  end;
  SumGRHI:=0;
  SumTempHI:=0;
  QHI.v:=0;
end;


procedure TSubDryMatterSimple_GF.CalcRates;

begin
  inherited;
  // tmpm  :=  0.25*TMPMN.v+0.75*TMPMX.v;

  PAR.v  := 0.5 * GlobRad.v;
  kpar_eff.v := kPAR.v; //+(k_max.v-kPAR.v)*EXP(-k_k.v*LAI.v);
  fInt.v := (1 - EXP(-kPAR_eff.v * LAI.v));

  IPAR.v := PAR.v * fint.v;
  CumPAR.c := IPAR.v;
  if (SoilWaterModel <> nil) and (fDroughtImpact = DroughtImpact) then
  begin
    // SWDF1.v := TR_Y.v+((1-TR_Y.v)/(1-TR_X.v))*(TransRatio.v-TR_X.v);  // (Ratjen)
    SWDF1.v := 1 - power((1 - TransIntRatio.v), pSWDF.v);    //  (Ferreyra 2003)
  end else
    SWDF1.v := 1;
  if (fCarbored = Concentration) then
  begin
    if SLN_crit.v > 0 then    // Meinke 1997
      CarboRed.v := min(1, SLN.v / SLN_crit.v)
    else
      CarboRed.v := 0;
  end else
  if (xStage.v >= 5) and (XStage.v <= 6) and (fCarbored = CWT3) then
  begin
    CarboRed.v := max(0, (1. - ({1.2}int.v - {0.8}carbored_b.v *
      SWMIN.v / STMWT_pl.v) * (sumdtt5.v + 100.0) / ((430 + P5.v * 20) + 100.0)));
  end else
    CarboRed.v := 1;
  if fDMCalcMethod = Ritchie then
  begin
    if ipar.v > 0 then
    begin
      PRFT.v  := max(0, 1 - 0.0025 * sqr((0.25 * TMPMN.v + 0.75 * TMPMX.v) - 16));
      PCARB.v := LUE0.v * Power(PAR.v, LUEexp.v) * fint.v * PRFT.v;
    end
    else
    begin
      PCARB.v := 0;
    end;
  end;

  if fDMCalcMethod = ConstLUE then
  begin
    if ipar.v > 0 then
    begin
      Tempf.v := trapez_f(tmpm.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
      PCARB.v := pLUE.v * PAR.v * fint.v * TEmpf.v;

    end
    else
      PCARB.v := 0;
  end;

  if fDMCalcMethod = LUE_f_rad then
  begin
    if ipar.v > 0 then
    begin
      Tempf.v := trapez_f(tmpm.v, Tmin.v, Topt1.v, Topt2.v, Tmax.v, 0, 1);
      PCARB.v := (pLUE0_d.v - pLUEdec.v * PAR.v) * PAR.v * fint.v;
    end
    else
      PCARB.v := 0;
  end;

  PCARB.v := PCARB.v * min(SWDF1.v, Carbored.v);  // soil water deficit factor correction
  // PCARB.v := PCARB.v * SWDF1.v*Carbored.v;

  if Plants.v > 0 then
    CARBO.v := PCARB.v / Plants.v;
  cumCarbo.c := PCarb.v;
  if (EC.v > 50) and (EC.v < 75) then
  begin
    SumGRHI := GlobRad.v+SUMGRHI;
    SumTempHI := Tmpm.v+SUMTempHI;
    QHI.v:= SUMGRHI/SumTempHI;
  end;


  if (EC.v > 50) and (EC.v < 75) then
  begin
    TSumEC50.c := tmpm.v;
    RSumEC50.c := GlobRad.V;
    RSumEC50Drought.c := GlobRad.v * TransIntRatio.v;

  end else
  begin
    TSumEC50.c := 0;
    RSumEC50.c := 0;
    RSumEC50Drought.c := 0;
  end;
  RSumT5080.c  := trapez_f(EC.v, 50, 50, 75, 80, 0, 1) * GlobRad.V;

  CumPARcorr.c := IPAR.v * Tempf.v * TransIntratio.v;
  if cumPAR.v + cumPAR.c > 0 then
    RSUMSS.c := GlobRad.v;
end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubDrymatterSimple_GF]);
end;

end.
