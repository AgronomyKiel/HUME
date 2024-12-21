unit grass_growth_quality;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UState, math, IniFiles, UAbstractPlant, USoilMineralisation,
  UlayeredSoil, UMultiGrowthCurvePlantRoots, UGrowthCurvePlant;

type

  TGrass_growth_quality = class(TMultiGrowthCurvePlantRoots)

  private
  protected
  public

    w0_arr: array[0..growth_count] of TPar;
    rs_arr: array[0..growth_count] of TPar;
    lai50_arr: array[0..growth_count] of TPar;
    ak_arr: array[0..growth_count] of TPar;
    pk_arr: array[0..growth_count] of TPar;
    mfk_arr: array[0..growth_count] of TPar;
    tkq_arr: array[0..growth_count] of TPar;
    rkq_arr: array[0..growth_count] of TPar;
    qmin_arr: array[0..growth_count] of TPar;
    qmax_arr: array[0..growth_count] of TPar;
    schr50_arr: array[0..growth_count] of TPar;
    chrk_arr: array[0..growth_count] of TPar;

    AGE, cai, dW, GI, radiation, RI, rmax, SW1, TI, WI, WI_2, LAI_foproq: TVar;

    //quality
    daylength, mchr, pchr, pechr, quality, r, rchr, TAGB, TAGLI, TAGX, tchr:
    TVar;

    TLAM, TNR, fertig: TVAR;

    // seasonal values
    ak, lai50, rs, w0, chrk, mfk, pk, qmax, qmin, rkq, schr50, tkq: TVAR;

    SW, W, yield_total: TState;
    shootN: TState; //N-MEnge
    spechr: TState; //  sumof change rates

    // Parameters
    agelim, agend: TPar; //
    akm, begbas, begsum, cank, clai, blai, etpa, etpb: TPar;
    laih, lail, rk, rmlo, rmxp: TPar;
    swact, swmax, swthr, tk1, tk2, topt, tpmax, tthr: TPar;

    wh: TPar; // dW/Bestandshöhe
    al, bl: TPar; //

    funct, mchr_switch, pthr, qlat, qphsw, ageswitch, rchr_switch, rthrq, tthrq:
    TPar; //

    // External Variables
    pETP, GlobRad, TransRatio, Rain: TExternV; //

    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;

  published

    property Ex_pETP: TExternV read pETP write pETP;
    property Ex_GlobRad: TExternV read GlobRad write GlobRad;
    property Ex_TransRatio: TExternV read TransRatio write TransRatio;
    property Ex_Rain: TExternV read Rain write Rain;
    property Ex_Temp: TExternV read Temp write Temp;

  end;

procedure Register;

implementation

procedure TGrass_growth_quality.createAll;
var
  i: integer;
begin
  inherited createAll;

  for i := 0 to growth_count do begin
    ParCreate('w0_' + IntToStr(i), '[-]', 1.25, w0_arr[i]);
    ParCreate('rs_' + IntToStr(i), '[-]', 0.515, rs_arr[i]);
    ParCreate('lai50_' + IntToStr(i), '[-]', 87.13, lai50_arr[i]);
    ParCreate('ak_' + IntToStr(i), '[-]', 1.422, ak_arr[i]);

    ParCreate('pk_' + IntToStr(i), '[-]', 0.1, pk_arr[i]);
    ParCreate('tkq_' + IntToStr(i), '[-]', 0.027, tkq_arr[i]);
    ParCreate('rkq_' + IntToStr(i), '[-]', 0.044, rkq_arr[i]);
    ParCreate('mfk_' + IntToStr(i), '[-]', 0.05, mfk_arr[i]);

    ParCreate('qmin_' + IntToStr(i), '[-]', 15.75, qmin_arr[i]);
    ParCreate('qmax_' + IntToStr(i), '[-]', 34.8, qmax_arr[i]);
    ParCreate('schr50_' + IntToStr(i), '[-]', 2.28, schr50_arr[i]);
    ParCreate('chrk_' + IntToStr(i), '[-]', 2.34, chrk_arr[i]);
  end;

  VarCreate('AGE', '', 0, true, AGE);
  VarCreate('cai', '', 0, true, cai);
  VarCreate('dW', '', 0, true, dW);
  VarCreate('GI', '', 0, true, GI);
  VarCreate('LAI_foproq', '', 0, true, LAI_foproq);
  VarCreate('radiation', '', 0, true, radiation);
  VarCreate('RI', '', 0, true, RI);
  VarCreate('rmax', '', 0, true, rmax);
  VarCreate('SW1', '', 0, true, SW1);
  VarCreate('TI', '', 0, true, TI);
  VarCreate('WI', '', 0, true, WI);
  VarCreate('WI_2', '', 0, true, WI_2);

  VarCreate('daylength', '', 0, true, daylength);
  VarCreate('mchr', '', 0, true, mchr);
  VarCreate('pchr', '', 0, true, pchr);
  VarCreate('pechr', '', 0, true, pechr);
  VarCreate('quality', '', 0, true, quality);
  VarCreate('rchr', '', 0, true, rchr);
  VarCreate('TAGB', '', 0, true, TAGB);
  VarCreate('TAGLI', '', 0, true, TAGLI);
  VarCreate('TAGX', '', 0, true, TAGX);
  VarCreate('tchr', '', 0, true, tchr);

  VarCreate('TLAM', '', 0, true, TLAM);
  VarCreate('TNR', '', 0, true, TNR);

   // seasonal values
  VarCreate('ak', '[-]', 0, true, ak);
  VarCreate('lai50', '[-]', 0, true, lai50);
  VarCreate('rs', '[-]', 0, true, rs);
  VarCreate('w0', '[-]', 0, true, w0);
  VarCreate('chrk', '[-]', 0, true, chrk);
  VarCreate('mfk', '[-]', 0, true, mfk);
  VarCreate('pk', '[-]', 0, true, pk);
  VarCreate('qmax', '[-]', 0, true, qmax);
  VarCreate('qmin', '[-]', 0, true, qmin);
  VarCreate('rkq', '[-]', 0, true, rkq);
  VarCreate('schr50', '[-]', 0, true, schr50);
  VarCreate('tkq', '[-]', 0, true, tkq);

  StateCreate('SW', '', 0, true, SW);
  StateCreate('W', '', 0, true, W);
  StateCreate('yield_total', '', 0, true, yield_total);
  StateCreate('spechr', '', 0, true, spechr);

  // Parameters
  ParCreate('agend', '[-]', -0.003, agend);
  ParCreate('akm', '[-]', 0.001, akm);

  ParCreate('begbas', '[-]', 0, begbas);
  ParCreate('begsum', '[-]', 0, begsum);
  ParCreate('cank', '[-]', 1, cank);
  ParCreate('clai', '[-]', 0, clai);
  ParCreate('blai', '[-]', 1, blai);
  ParCreate('etpa', '[-]', 0.3, etpa);
  ParCreate('etpb', '[-]', 0.233, etpb);

  ParCreate('laih', '[-]', 6, laih);
  ParCreate('lail', '[-]', 1, lail);
  ParCreate('rk', '[-]', 3, rk);
  ParCreate('rmlo', '[-]', 32, rmlo);
  ParCreate('rmxp', '[-]', 32, rmxp);

  ParCreate('swact', '[-]', 100, swact);
  ParCreate('swmax', '[-]', 100, swmax);
  ParCreate('swthr', '[-]', 0.8, swthr);
  ParCreate('tk1', '[-]', 3, tk1);
  ParCreate('tk2', '[-]', 0.3, tk2);
  ParCreate('topt', '[-]', 15, topt);
  ParCreate('tpmax', '[-]', 42, tpmax);
  ParCreate('tthr', '[-]', 1, tthr);

  ParCreate('wh', '[-]', 0.001, wh);
  ParCreate('al', '[-]', 1, al);
  ParCreate('bl', '[-]', 1, bl);

  ParCreate('funct', '[-]', 3, funct);
  ParCreate('mchr_switch', '[-]', 2, mchr_switch);
  ParCreate('age_switch', '[-]', 4, ageswitch);
  ParCreate('pthr', '[-]', 10, pthr);
  ParCreate('qlat', '[-]', 54, qlat);

  ParCreate('qphsw', '[-]', 2, qphsw);
  ParCreate('rchr_switch', '[-]', 1, rchr_switch);

  ParCreate('rthrq', '[-]', 3, rthrq);
  ParCreate('tthrq', '[-]', 4, tthrq);

  // External Variable
  ExternVCreate('pETP', '', statefield, pETP);
  ExternVCreate('GlobRad', '', statefield, GlobRad);
  ExternVCreate('TransRatio', '', statefield, TransRatio);
  ExternVCreate('Rain', '', statefield, Rain);
end;

procedure TGrass_growth_quality.init(var GlobMod: TMod);
begin

  inherited;
  w0.v := w0_arr[0].v;
  rs.v := rs_arr[0].v;
  lai50.v := lai50_arr[0].v;
  ak.v := ak_arr[0].v; ;
  pk.v := pk_arr[0].v;
  mfk.v := mfk_arr[0].v;
  tkq.v := tkq_arr[0].v;
  rkq.v := rkq_arr[0].v;
  qmin.v := qmin_arr[0].v;
  qmax.v := qmax_arr[0].v;
  schr50.v := schr50_arr[0].v; ;
  chrk.v := chrk_arr[0].v;

  SW.v := swact.v;
  W.v := w0.v;
  yield_total.v := 0;
  spechr.v := 0;

end;

procedure TGrass_growth_quality.CalcRates;
var
  i: integer;
  year, month, day, year2, month2, day2: word;
begin
  inherited;

  if GlobTime.v > HarvestDate.v then begin
    w0.v := 0;
    rs.v := 0;
    lai50.v := 0;
    ak.v := 0;
    pk.v := 0;
    mfk.v := 0;
    tkq.v := 0;
    rkq.v := 0;
    qmin.v := 0;
    qmax.v := 0;
    schr50.v := 0;
    chrk.v := 0;

    SW.v := 0;
    W.v := 0;
    yield_total.v := 0;
    LAI_foproq.v := 0;
  end;

  if (GlobTime.v >= SowingDate.v) and (GlobTime.v < HarvestDate.v) then begin

    for i := 0 to growth_count do begin
      DecodeDate(harvestdates[0].v, year, month, day);
      DecodeDate(GlobTime.v, year2, month2, day2);

      if harvestdates[i].v = GlobMod.Time.v then begin
        w0.v := w0_arr[i + 1].v;
        rs.v := rs_arr[i + 1].v;
        lai50.v := lai50_arr[i + 1].v;
        ak.v := ak_arr[i + 1].v; ;
        pk.v := pk_arr[i + 1].v;
        mfk.v := mfk_arr[i + 1].v;
        tkq.v := tkq_arr[i + 1].v;
        rkq.v := rkq_arr[i + 1].v;
        qmin.v := qmin_arr[i + 1].v;
        qmax.v := qmax_arr[i + 1].v;
        schr50.v := schr50_arr[i + 1].v; ;
        chrk.v := chrk_arr[i + 1].v;

        SW.v := swact.v;
        W.v := w0.v;
        yield_total.v := 0;
      end;
    end;

    // LAI
    case trunc(ageswitch.v) of
      1: if (clai.v > 0) then
          LAI_foproq.v := Sqrt(W.v / clai.v)
        else
          LAI_foproq.v := 0;
      2: LAI_foproq.v := blai.v * W.v + clai.v * Math.power(W.v, 2);
      3: LAI_foproq.v := blai.v * (1.0 - exp(-clai.v * W.v));
      4: LAI_foproq.v := W.v;
    end;

    AGE.v := 1 / (1 + power((LAI_foproq.v / LAI50.v), ak.v));

    cai.v := (1 - exp(-cank.v * (LAI_foproq.v - LAIl.v) / LAIh.v)) / (1 -
      exp(-cank.v));

    //LAI_foproq.v := W.v * 0.02; //lineare Regression DW KD 2007

    // RI  radiation index
    radiation.v := GlobRad.v;

    rmax.v := rmlo.v + CAI.v * (rmxp.v - rmlo.v);
    RI.v := min(1, (1 - exp(-rk.v * radiation.v / rmax.v)) / (1 - exp(-rk.v)));

    // TI   temperature index
    TI.v := max(0, min(1.0 - (power(2 * abs(Temp.v - topt.v) / (topt.v -
      tthr.v), tk1.v)) * 0.5, 1));

    // WI  water index
    SW.c := Rain.v - pETP.v;
    SW1.v := max(0, min(SW.v + SWact.v, SWmax.v));

    //  WI.v :=  max(0,TransRatio.v);
    WI.v := min(1.0, TransRatio.v / swthr.v);
    WI_2.v := min(1.0, SW1.v / (swthr.v * swmax.v));

    GI.v := TI.v * RI.v * WI.v;
    dW.v := W.v * rs.v * AGE.v * GI.v;

    W.c := dW.v;

    //Quality

    //daylength
    TNR.v := GlobTime.v + 0.5;
    TLAM.v := TAGLI.v + 1.915 * sin((365.455 + 0.985647 * TNR.v) / 180 * 3.1416)
      + 0.02 * sin(2 * (365.455 + 0.985647 * TNR.v) / 180 * 3.1416);
    TAGX.v := tan(arcsin(0.39781 * sin(tlam.v / 180 * 3.1416)));
    TAGLI.v := 279.097 + 0.985647 * TNR.v;
    TAGB.v := -tan(qlat.v * 3.1416 / 180);
    daylength.v := 0.13333 * arccos(TAGB.v * TAGX.v) * 180 / 3.1416;

    //temperature
    tchr.v := max(0, 1 - exp(-tkq.v * (temp.v - tthrq.v)));

    case trunc(mchr_switch.v) of //moisture
      1: mchr.v := max(0, 1 - (WI.v / mfk.v));
      2: mchr.v := min(1, (WI.v / mfk.v));
    end;

    case trunc(qphsw.v) of //photoperiod
      1: pchr.v := max(0, exp(-pk.v * (daylength.v - pthr.v)));
      2: pchr.v := max(0, 1 - exp(-pk.v * (daylength.v - pthr.v)))
    end;

    radiation.v := GlobRad.v * 100; //radiation

    case trunc(rchr_switch.v) of
      1: rchr.v := max(0, 1 - exp(-rkq.v * (radiation.v - rthrq.v)));
      2: rchr.v := exp(-rkq.v * (radiation.v - rthrq.v));
    end;

    pechr.v := PCHR.v * TCHR.v * RCHR.v * MCHR.v;
    spechr.c := pechr.v;

    case trunc(funct.v) of
      1: quality.v := qmin.v + (1 / (1 + power((SPECHR.v / schr50.v), chrk.v)))
        * (qmax.v - qmin.v);
      2: quality.v := al.v + bl.v * SPECHR.v;
      3: quality.v := qmin.v + (power((SPECHR.v / schr50.v), chrk.v) / (1 +
          power((SPECHR.v / schr50.v), chrk.v))) * (qmax.v - qmin.v);
    end;

  end;

end;

procedure Register;
begin
  RegisterComponents('GrassModel', [TGrass_growth_quality]);
end;

end.

