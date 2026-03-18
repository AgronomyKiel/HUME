unit URootedSoil; // Neue Komponente

interface

{$IFDEF LINUX}
{$DEFINE NONVISUAL}
{$ENDIF LINUX}

uses
  USoilWaterMod, UMod, UState,
{$IFNDEF NONVISUAL}
  Vcl.Dialogs,
{$ENDIF}
  ULayeredSoil,
  classes,
  UAbstractPlant,
  WFlowFunctions;

const
  Max_Root_Index = 20;

type
  real = double;

  /// <summary> Options for calculation of sink reduction factor for root water uptake </summary>
  TSinkTermMethod = (nFK_crit, Psicrit, Psicrit_corr, Feddes, MFP);
  
  /// <summary> Options for calculation of automatic irrigation </summary>
  TAutoirriMethod = (amTransRatio, amProznFKWe, amProznFKActRootedComps);
  
  /// <summary> Options for calculation of sink reduction factor based on root length distribution and potential water uptake </summary>
  T_Sqrwl_Funct = (ReductionFactor, NoReductionFactor);


/// <summary> Model component for adding root soil water uptake to the simulation of vertical (1D) soil water transport
///  The distribution of water uptake over the soil layers and the calculation of drought limited water uptake can
///  be calculated with different options
///  </summary>
  TSoilWaterModelR = class(TSoilWaterMod)

  private
    f_Sqrwl_funct: T_Sqrwl_Funct;
    Sum_Sink: real;
    /// internal variable for summing up all sink terms
    FWithRoots: boolean;
    /// Option for calculation with/without roots
    fAutoirri: boolean;
    fAutoirriMethod: TAutoirriMethod;
    fPsi2Opt: TSource;
    /// Source of Psi2 value
    FSinkTermMethod: TSinkTermMethod;
    fWriteMFPTable: boolean;

    procedure setWithRoots(settrue: boolean);
    procedure CreateOptionsRootedSoil;
    // function GetWLD(Index:Integer):real; virtual;

  protected

  public
    AutoIrriOptStr: Toption;
    AutoIrriMethodOptStr: Toption;
    SinkTermMethodOptStr: Toption;
    WriteMFPTable: Toption;
    /// Option for output of MFP-table functions as txt file
    WcontDiff_arr: TSoilvarArray;
    /// Wassergehaltsdifferenzen Wurzeloberfl�che/Bodenraum [cm3/cm3]
    PsiRootDiff_arr: TSoilvarArray;
    /// Wasserspannungsdifferenzen Wurzeloberfl�che/Bodenraum [cm3/cm3]
    ProzNFK_arr: TSoilvarArray;

    ExWld_arr: TSoilExtArray;
    /// Wurzellaengendichten [cm.cm-3]
    WLges: TVar;
    /// GesamtWurzell�nge [cm]
    // w_influx : TSoilVarArray; /// Wasserinfluxraten [cm3.cm-1.d-1]
    SinkRedF: TSoilArray;
    /// Reduktionsfaktoren bei Wasseraufnahme
    psiRoot: TVar;
    /// average, weighted soil water potential within the rooting zone [pF]
    psi_2,
    /// Wasserspannung ab der Wasseraufnahme beginnt abzunehmen
    psi_3,
    /// Wasserspannung ab der Wasseraufnahme = 0
    CompFactor,
    /// Konkurrenzfaktor f�r Wasseraufnahme der Wurzeln (i.d.R. < 1.0)
    IrriAmount
    /// Auto BEw. Menge [mm]
      : Tpar;
    Autoirri_nFKcrit: Tpar;
    /// critical nFK value for triggering irrigation
    nfk_threshold: Tpar;
    feddes_a: Tpar;
    feddes_b: Tpar;
    feddes_c: Tpar;
    ProznFK_act_rooted_comps: TVar;

    nFKcrit: Tpar;

    PotTrans: TexternV;
    /// External value for potential transpiration
    Interzeption: TexternV;
    /// External value for Interception
    ActTrans: TVar;
    /// aktuelle Transpirationsrate [mm/d]
    TransRatio: TVar;
    /// Verh�ltnis aktuelle zu potentielle Transpiration
    TransIntRatio: TVar;
    /// Verh�ltnis aktuelle zu potentielle Transpiration
    Eact_ETP: TVar;
    /// Ration of act. evaporation to pot. evapotranspiration
    Psi2: TVar;
    /// water potential at which water uptake by the plant starts to decrease [hPa]
    act_rooted_comps: TVar;
    /// actual number of rooted compartiments
    EmergenceDay: TexternV;
    /// used for Autoirrigation

    CumAutoIrrigation: TState;
    /// cum. Amount of  Irrigation
    CumTrans: TState;
    /// kumulative Transpiration [mm]
    CumET: TState;
    /// cumulative actual Evapotranspiration
    CumETpot: TState;
    /// cumulative potential Evapotranspiration
    CumTranspot: TState;
    /// cumulative potential Transpiration
    f_SqrWl_Option: Toption;
    /// Option for sink reduction (Sqr_wl_arr calculation)
    r_root: Tpar;
    /// root radius

    MFP_arr: array [0 .. 20] of TMFP_table;

    procedure SetPlantModel(NewPlantModel: TAbstractplant); override;
    procedure CreateAll; override;

    procedure Init(var GlobMod: TMod); override;

    procedure Calcsink_red_f;
    procedure CalcSinks; override;
    procedure CalcRatesAndIntegrate; override;
    procedure CalcRates; override;
    // procedure Integrate; override;

    // property Wld_arr[Index : Integer]: real read getWLD;  /// Wurzell�ngendichten [cm.cm-3]

    // procedure Set_GlobMod(value:TMod);override;
  published
    property Ex_PotTrans: TexternV read PotTrans write PotTrans;
    property Ex_Interzeption: TexternV read Interzeption write Interzeption;
    property Ex_EmergenceDay: TexternV read EmergenceDay write EmergenceDay;
    property Par_Psi_2: Tpar read psi_2 write psi_2;
    property Par_psi_3: Tpar read psi_3 write psi_3;
    property Comp_fact: Tpar read CompFactor write CompFactor;
    property Par_nFKcrit: Tpar read nFKcrit write nFKcrit;
    property St_CumTrans: TState read CumTrans write CumTrans;
    property Var_ActTrans: TVar read ActTrans write ActTrans;
    property Var_TransRatio: TVar read TransRatio write TransRatio;
    property Var_ProznFK_act_rooted_comps: TVar read ProznFK_act_rooted_comps
      write ProznFK_act_rooted_comps;
    property Var_TransIntRatio: TVar read TransIntRatio write TransIntRatio;
    property Psi_Root: TVar read psiRoot write psiRoot;
    // property AutoIrrigate: TAutoIrri read fAutoIrrigate write fAutoIrrigate;
    property AutoirriMethod: TAutoirriMethod read fAutoirriMethod
      write fAutoirriMethod;
    property Opt_WithRoots: boolean read FWithRoots write setWithRoots;
    property OptSinkTermMethod: TSinkTermMethod read FSinkTermMethod
      write FSinkTermMethod;
    property Opt_Psi2: TSource read fPsi2Opt write fPsi2Opt;
    // Source of Psi2 value
    property OptWriteMFPtable: boolean read fWriteMFPTable write fWriteMFPTable;

  end;

Function Water_flow_func(avg_transpi_rate, L, hour: real;
  sinus_func: boolean): real;
procedure Register;

implementation

uses
  SysUtils, math; // , dialogs;

function baf(b, Iw, Dw, xl, a: real): real;
// calculation of soil water content at root surface
// b: average soil water content [cm3/cm3]
// Iw: water influx rate [cm3.cm-2.d-1]
// Dw: soil water diffusivity [cm2.s-1]
// xl: average half distance between roots [cm]
// a: root radius [cm]

begin
  if Dw > 0 then
    baf := b - (Iw / (2 * pi * Dw) * ln(xl / (1.65 * a)))
  else
    baf := 0;
end;

function Iwmax(b, bmin, Dw, xl, a: real): real;

// calculation of maximum water influx rate [cm3.cm-1.d-1]
// b: average soil water content [cm3/cm3]
// bmin: minimum soil water content [cm3/cm3]
// Dw: soil water diffusivity [cm2.s-1]
// xl: average half distance between roots [cm]

begin
  If (b - bmin < 0.0) then
    Iwmax := 0.0
  else
    Iwmax := ((b - bmin) * 2 * pi * Dw) / (ln(xl / (1.65 * a)));
end;

function sinusf(hour: real): real;
var
  output: real;
begin
  output := max(0, 1.64221194 * (0.5 + sin(pi * ((hour + 18) / 12))));
  sinusf := output;
end;

Function Water_flow_func(avg_transpi_rate, L, hour: real;
  sinus_func: boolean): real;

// Water_flow_func: water uptake rate per unit root length
// avg_transp_rate: average transpiration rate [mm.d-1]
// L : total root length [cm/ha]
// hour: hour of the day
// sinus_func: switch for even or sinusoidal course of water uptake

var
  Es, // transpiration rate per cm3.s-1
  Transpi_rate: real;

begin
  If sinus_func = true then
  begin
    Transpi_rate := avg_transpi_rate * sinusf(hour);
    If Transpi_rate <= 1E-12 then
      Transpi_rate := 0.0;
  end
  else
    Transpi_rate := avg_transpi_rate;
  Es := Transpi_rate * 1E7 / 86400.0;
  if L > 0 then
    Water_flow_func := Es / L
  else
    Water_flow_func := 0.0;
end;

procedure TSoilWaterModelR.CreateAll;

var
  i: integer;

begin
  inherited CreateAll;
{$IFNDEF NONVISUAL}
  if DebugForm <> NIL then
    DebugForm.MyCreate;
{$ENDIF}
  ParCreate('psi_2', '[cm]', 200, psi_2,
    'soil water tension from which root water uptake reduces if eíther FEDDES, psi_crit or psicrit_corr option is choosen');
  ParCreate('psi_3', '[cm]', 15000, psi_3,
    'lower limit of soil water extraction');
  ParCreate('feddes_a', '[hPa]', 400, feddes_a,
    'Enhancement of psi_2 at high pot. Transp.');
  ParCreate('feddes_b', '[mm/d]', 5, feddes_b, 'Transpiration threshold for psi_2 calculation');
  ParCreate('feddes_c', '[mm/d]', 1, feddes_c,
    'lower transpiration rate threshold for psi_2 calculation, for lower transpiration rates psi_2 not further increased');
  ParCreate('nfk_threshold', '[-]', 0.01, nfk_threshold,
    'threshold (water buffer) for sink reduction');
  ParCreate('CompFactor', '[-]', 0.5, CompFactor,
    'root competition factor, 1 leads to proportional potential water uptake by relative root length, 0.5 accounts for root competition');
  ParCreate('nFKcrit', '[-]', 0.5, nFKcrit,
    'relative soil water content where root water uptake reduces if nFKcrit option is choosen');
  ParCreate('IrriAmount', '[mm]', 10, IrriAmount,
    'Amount of automated irrigation per irrigation');
  ParCreate('Autoirri_nFKcrit', '[%]', 60, Autoirri_nFKcrit,
    'Prozent nFK ab der bewässert wird, wenn AutoirriMeth auf amProznFKWe steht');
  ParCreate('r_root', '[cm]', 0.01, r_root, 'root radius [cm]');

  ExternVcreate('PotTrans', '[mm.d-1]', stateField, PotTrans,
    'potential transpiration rate');
  ExternVcreate('Interception', '[mm.d-1]', stateField, Interzeption,
    'interception rate');
  ExternVcreate('EmergenceDay', '[-]', stateField, EmergenceDay,
    'day of emergence taken from plant growth module');

  VarCreate('ActTrans', '[mm.d-1]', 0.0, false, ActTrans,
    'Actual transpiration rate');
  VarCreate('TransRatio', '[-]', 0.0, false, TransRatio,
    'relation between actual and potential transpiration');
  VarCreate('TransIntRatio', '[-]', 0.0, false, TransIntRatio,
    'relation between sum of actual transpiration plus interception and potential transpiration');
  VarCreate('Eact_ETP', '[-]', 0.0, false, Eact_ETP,
    'relation between actual evaporation and potential evapotranspiration');
  VarCreate('psiRoot', '[pF]', 0.0, false, psiRoot,
    'root length weighted soil water tension (log scale)');
  VarCreate('Psi2', '[cm]', 0.0, false, Psi2, '');
  VarCreate('act_rooted_comps', '[n]', 0, true, act_rooted_comps,
    'number of actual rooted soil compartments');
  VarCreate('ProznFK_act_rooted_comps', '[%]', 0.0, false,
    ProznFK_act_rooted_comps, '');

  StateCreate('CumAutoIrrigation', '[mm]', 0, true, CumAutoIrrigation);
  StateCreate('CumTrans', '[mm]', 0, true, CumTrans,
    'cumulative transpiration');
  StateCreate('CumET', '[mm]', 0, true, CumET,
    'cumulative actual evapotranspiration');
  StateCreate('CumETpot', '[mm]', 0, true, CumETpot,
    'cumulative potential evapotranspiration');
  StateCreate('CumTranspot', '[mm]', 0, true, CumTranspot,
    'cumulative potential transpiration');

  for i := 1 to Max_Root_Index do
  begin
    VarCreate('ProzNFK_arr' + ndx_str(i), '[%]', 0.0, false, ProzNFK_arr[i], 'percentage of available water (nFK) in the soil compartment');
  end;

  for i := 1 to n_comp do
  begin
    VarCreate('WcontDiff_arr' + ndx_str(i), '[cm3.cm-3]', 0.0, false,
      WcontDiff_arr[i], 'Difference in water content soil root surface');
    VarCreate('PsiRootDiff_arr' + ndx_str(i), '[cm]', 0.0, false,
      PsiRootDiff_arr[i],
      'Difference in matrix potential at soil root surface');
  end;

  if FWithRoots = true then
  begin
    for i := 1 to n_comp do
    begin
      ExternVcreate('effWLD_' + ndx_str(i), '[cm/cm3]', stateField,
        ExWld_arr[i]);
      VarCreate('WAuf' + ndx_str(i), '[cm.d-1]', 0.0, false, Sink_arr[i], 'water uptake rate in the soil compartment');
    end;
  end;
  CreateOptionsRootedSoil;

end;

procedure TSoilWaterModelR.setWithRoots(settrue: boolean);
var
  i: integer;
begin
  if settrue then
    for i := 1 to n_comp do
    begin
      if ExWld_arr[i] = nil then
        ExternVcreate('effWLD_' + ndx_str(i), '[cm/cm3]', stateField,
          ExWld_arr[i]);
      if Sink_arr[i] = nil then
        VarCreate('WAuf' + ndx_str(i), '[cm.d-1]', 0.0, false, Sink_arr[i], 'water uptake rate in the soil compartment');
    end;
  FWithRoots := settrue;
end;

procedure TSoilWaterModelR.Init(var GlobMod: TMod);

var
  i, j: integer;
  f: TextFile;
  fn: string;
begin
  inherited Init(GlobMod);
  if uppercase(f_SqrWl_Option.Option) = uppercase('NoReductionFactor') then
    f_Sqrwl_funct := NoReductionFactor;
  if uppercase(f_SqrWl_Option.Option) = uppercase('ReductionFactor') then
    f_Sqrwl_funct := ReductionFactor;

  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Feddes') then
    OptSinkTermMethod := Feddes;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Psicrit') then
    OptSinkTermMethod := Psicrit;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('Psicrit_corr') then
    OptSinkTermMethod := Psicrit_corr;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('nFKcrit') then
    OptSinkTermMethod := nFK_crit;
  if uppercase(SinkTermMethodOptStr.Option) = uppercase('MFP') then
    OptSinkTermMethod := MFP;

  if uppercase(AutoIrriMethodOptStr.Option) = uppercase('amTransRatio') then
    AutoirriMethod := amTransRatio;
  if uppercase(AutoIrriMethodOptStr.Option) = uppercase('amProznFKWe') then
    AutoirriMethod := amProznFKWe;
  if uppercase(AutoIrriMethodOptStr.Option)
    = uppercase('amProznFKActRootedComps') then
    AutoirriMethod := amProznFKActRootedComps;

  if lowercase(WriteMFPTable.Option) = 'false' then
    fWriteMFPTable := false
  else
    fWriteMFPTable := true;

  if uppercase(AutoIrriOptStr.Option) = uppercase('yes') then
  begin
    fAutoirri := true;
    EmergenceDay.Search := true;
  end
  else
  begin
    fAutoirri := false;
    EmergenceDay.Search := false;
  end;

  ActTrans.v := 0.0;
  CumTrans.v := 0.0;
  CumTrans.c := 0.0;
  CumETpot.v := 0.0;
  CumET.v := 0.0;
  CumTranspot.v := 0.0;
  TransRatio.v := 1.0;
  TransIntRatio.v := 1.0;
  if self.psi_2.v > self.psi_3.v then
    psi_3.v := psi_2.v * 1.1;

  for i := 1 to n_comp do
    Sink_arr[i].v := 0.0;
{$IFNDEF NONVISUAL}
  if DebugForm <> NIL then
    DebugForm.Init;
{$ENDIF}
  if (OptSinkTermMethod = MFP) then
    for i := 1 to n_comp do
      MFP_arr[i] := TMFP_table.create(WPar[i]);

  if fWriteMFPTable then // Ausgabe der MFP-Table in Datei
    for i := 1 to n_comp do
    begin
      begin
        fn := ExtractFilePath(GlobMod.Get_ControlFileFn) +
          ExtractFileName(GlobMod.ActIniFile.FileName);
        fn := ChangeFileExt(fn, '') + '-MFP_table.csv';
        AssignFile(f, fn);
        Rewrite(f);
        write(f, 'Layer;');
        for j := 0 to 100 do
          write(f, FloatToStr(-1 + j * 5.2 / 100) + ';');
        writeln(f);
        for j := 1 to n_comp do
        begin
          writeln(f, IntToStr(i) + '; ' + MFP_arr[i].getline);
        end;
        CloseFile(f);
      end;
    end;
end;



/// <summary> Sink reduction calculation with 5 options
/// 1) Feddes: reduction factor based on soil water tension thresholds and potential transpiration rate following Feddes et al. (1978)
/// 2) Psicrit: reduction factor based on soil water tension threshold (Psi2) following Van Genuchten (1987)
/// 3) nFKcrit: reduction factor based on relative soil water content (nFK) threshold following Van Genuchten (1987)
/// 4) Psicrit_corr: reduction factor based on soil water tension at the root surface, which is calculated based on potential water uptake and root length distribution, and soil water retention curve
/// 5) MFP: reduction factor based on soil water tension at the root surface, which is calculated based on potential water uptake and root length distribution, and soil water retention curve, with a maximum flow principle (MFP) approach for calculating the potential water uptake
/// </summary>
procedure TSoilWaterModelR.Calcsink_red_f;

var
  red_f, psi2_, psi2_low, rPAW: real;

  potMaxInflow, // potential water inflow [cm3/cm/s]
  rl, // root length in that layer
  HalfDistance, // half distance between roots [cm]
  theta_root, // soil water content at root surface
  Psi_Root, // soil water tension at root surface
  iw_max, // maximum soil water influx rate [cm3.cm-1.s-1]
  Wupmax: TSoilArray;
  i: integer;

begin

  if OptSinkTermMethod = Feddes then
  begin
    if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet then
      Psi2.v := Plantmodel.Psi2 // Psi2 from plant model
    else
      Psi2.v := psi_2.v; // Psi2 from parameter
    psi2_low := Psi2.v + feddes_a.v;
    if (PotTrans.v < feddes_c.v) then
      psi2_ := psi2_low
    else if (PotTrans.v > feddes_b.v) then
      psi2_ := Psi2.v
    else
      psi2_ := psi2_low + (PotTrans.v - feddes_b.v) *
        ((psi2_low - Psi2.v) / (feddes_c.v - feddes_b.v));
    for i := 1 to (n_comp - 1) do
    begin
      rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
      If psi_arr[i].v < psi2_ then
        red_f := 1.0
      else
        red_f := (psi_arr[i].v - psi_3.v) / (psi2_ - psi_3.v);
      // Staun�sse nach Feddes
      // If psi_arr[i].v < 1 then  red_f :=max(0.1,psi_arr[i].v);
      // rPAW:= ((theta_arr[i].v-pwp_arr[i]))/nFK_arr[i];
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedF[i] := red_f;
    end;
  end; // Feddes end

  if OptSinkTermMethod = Psicrit then
  begin
    if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet then
      Psi2.v := Plantmodel.Psi2 // Psi2 from plant model
    else
      Psi2.v := psi_2.v; // Psi2 from parameter
    for i := 1 to (n_comp - 1) do
    begin
      rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
      If psi_arr[i].v < Psi2.v then
        red_f := 1.0
      else
        red_f := (log10(psi_arr[i].v) - log10(psi_3.v)) /
          (log10(Psi2.v) - log10(psi_3.v));
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedF[i] := red_f;
    end; // Psicrit end
  end;
  if OptSinkTermMethod = nFK_crit then
  begin
    for i := 1 to (n_comp - 1) do
    begin
      rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
      If rPAW > nFKcrit.v then
        red_f := 1.0
      else
        red_f := rPAW / nFKcrit.v;
      If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
        red_f := 0.0;
      SinkRedF[i] := red_f;
    end;
  end; // nFKcrit end
  if (OptSinkTermMethod = Psicrit_corr) or (OptSinkTermMethod = MFP) then
  begin
    for i := 1 to (n_comp - 1) do
    begin
      if ExWld_arr[i].v > 0.0 then
      begin
        // root length in that layer in cm/ha from RLD [cm.cm-3] to rl in cm.ha-1
        rl[i] := 0.1 * ExWld_arr[i].v * Thick[i] * 1E8;
        
        // water inflow per unit root length [cm3/cm/s], potential water inflow based on potential transpiration and root length
        potMaxInflow[i] := Water_flow_func(self.Sink_arr[i].v * 10, rl[i],
          12, true);

        // average half distance between roots [cm]  
        HalfDistance[i] := abstand_func(ExWld_arr[i].v);
        
        // soil water content at root surface based on potential water inflow and soil water diffusivity [cm3/cm3] with steady state flow assumption
        theta_root[i] := baf(theta_arr[i].v, potMaxInflow[i], Dw_arr[i] / 86400,
          HalfDistance[i], 0.02);
        
        // maximum soil water influx rate [cm3.cm-1.s-1] based on soil water content at root surface, minimum soil water content at root surface, soil water diffusivity and half distance between roots
        iw_max[i] := Iwmax(theta_arr[i].v, pwp_arr[i], Dw_arr[i] / 86400,
          HalfDistance[i], 0.02);
        
        // maximum water uptake per layer [cm/d] based on maximum soil water influx rate and root length in that layer
        Wupmax[i] := iw_max[i] * rl[i] * 1E-4 * 1E-3 * 1E-1;
        
        // soil water tension at root surface based on soil water content at root surface and soil water retention curve
        Psi_Root[i] := min(power(10, 4.2), WPar[i].psi_b_f(theta_root[i]));
        
        // calculation of a soil water content difference between the root surface and the bulk soil
        WcontDiff_arr[i].v := theta_arr[i].v - theta_root[i];
        
        // calculation of a soil water tension difference between the root surface and the bulk soil
        PsiRootDiff_arr[i].v := Psi_Root[i] - psi_arr[i].v;

        // now using this soil water tension at the root surface for calculating the sink reduction factor 
        if (fPsi2Opt = fromPlantmodel) and IsPlantModelSet then
          Psi2.v := Plantmodel.Psi2 // Psi2 from plant model
        else
          Psi2.v := psi_2.v; // Psi2 from parameter
        rPAW := ((theta_arr[i].v - pwp_arr[i])) / nFK_arr[i];
        If Psi_Root[i] < Psi2.v then
          red_f := 1.0
        else
          red_f := (log10(Psi_Root[i]) - log10(psi_3.v)) /
            (log10(Psi2.v) - log10(psi_3.v));
        If ((red_f < 0.0) or (rPAW < nfk_threshold.v)) then
          red_f := 0.0;
        SinkRedF[i] := red_f;
      end
      else
      begin
        SinkRedF[i] := 0.0;
        WcontDiff_arr[i].v := 0.0;
        PsiRootDiff_arr[i].v := 0.0;
      end;
    end;
  end; // Psicrit_corr end
end;

procedure TSoilWaterModelR.CalcSinks;

var
  Sqr_Wl_arr, iw_max: TSoilArray;
  Sum_Sqr_wl, sum_wl: real;
  i: integer;
  MFP_, MFPsink: extended;
  Wupmax, rl: TSoilArray;

begin
  inherited CalcSinks;
  if FWithRoots = true then
  begin
    Sum_Sqr_wl := 0.0;
    sum_wl := 0.0;
    psiRoot.v := 0.0;

    act_rooted_comps.v := 0.0;
    for i := 1 to act_n_comp do
      if ExWld_arr[i].v > 0.0 then
        act_rooted_comps.v := i;

    if ShowWarnings then
      if act_rooted_comps.v > self.bil_nr.v then
{$IFNDEF NONVISUAL}
        showmessage
          ('Number of rooted compartments larger than balance index, computed balance probably not correct');
{$ELSE}
        writeln('Number of rooted compartments larger than balance index, computed balance probably not correct');
{$ENDIF}

    for i := 1 to act_n_comp do
    begin
    /// Calculation of sink reduction factor based on root length density distribution and potential water uptake per layer
      case f_Sqrwl_funct of
        NoReductionFactor:
          Sqr_Wl_arr[i] := power(ExWld_arr[i].v * Thick[i], CompFactor.v);
        ReductionFactor:
          Sqr_Wl_arr[i] := SinkRedF[i] * power(ExWld_arr[i].v * Thick[i],
            CompFactor.v);
      end;
      sum_wl := sum_wl + ExWld_arr[i].v * Thick[i];
      Sum_Sqr_wl := Sum_Sqr_wl + Sqr_Wl_arr[i];
    end;

    Sum_Sink := 0.0;
    for i := 1 to act_n_comp do
    begin
      if Sqr_Wl_arr[i] > 1E-6 then
        Sink_arr[i].v := 0.1 * PotTrans.v * Sqr_Wl_arr[i] / Sum_Sqr_wl
      else
        Sink_arr[i].v := 0.0;

      // sink term calculation with matrix flux potential based calculation of maximum root water uptake
      if OptSinkTermMethod = MFP then
      begin
        if ExWld_arr[i].v > 0 then
        begin
          // calculation of matrix by numerically integration of the unsaturated hydraulic conductivity from PWP to the actual soil water potential
          MFP_ := MFP_arr[i].get_sumku(psi_arr[i].v);
          // from RLD [cm.cm-3] to rl in cm.ha-1
          rl[i] := ExWld_arr[i].v * Thick[i] * 1E8;
          iw_max[i] := Iwmax(theta_arr[i].v, pwp_arr[i], Dw_arr[i] / 86400,
            abstand_func(ExWld_arr[i].v), 0.02);
          Wupmax[i] := iw_max[i] * rl[i] * 1E-4 * 1E-3 * 1E-1;
          // maximum water uptake per layer [cm/d]
          MFPsink := max(0, min(Sink_arr[i].v, MFP_Inflow(ExWld_arr[i].v,
            Thick[i], MFP_, r_root.v, Sink_arr[i].v)));
          if Sink_arr[i].v > 0 then
            SinkRedF[i] := MFPsink / Sink_arr[i].v
          else
            SinkRedF[i] := 0;
          Sink_arr[i].v := MFPsink;
        end
        else
          Sink_arr[i].v := 0.0;
      end
      else
        Sink_arr[i].v := max(0, Sink_arr[i].v * SinkRedF[i]);
      // nfk_threshold = buffer in order to avoid incoherent water flows
      if Sink_arr[i].v > (((theta_arr[i].v - WPar[i].b_rest) * Thick[i]) -
        nfk_threshold.v) then
        Sink_arr[i].v := ((theta_arr[i].v - WPar[i].b_rest) * Thick[i]) -
          nfk_threshold.v;
      Sum_Sink := Sum_Sink + Sink_arr[i].v;
    end;
  end; // withRoots
end;

procedure TSoilWaterModelR.CalcRatesAndIntegrate;

var
  Sum_ProzNFK: real;
  i: byte;

begin
  if FWithRoots = true then
    Calcsink_red_f;
  // CalcSinks;
  Sum_ProzNFK := 0.0;

  inherited CalcRatesAndIntegrate;
  if ExWld_arr[1].v > 0.0 then
  begin // Sind Wurzeln da ?
    for i := 1 to Max_Root_Index do
    begin
      if ExWld_arr[i].v > 0.0 then
        ProzNFK_arr[i].v := ((theta_arr[i].v - pwp_arr[i]) / nFK_arr[i]) * 100;
    end;

    for i := 1 to Max_Root_Index do
    begin
      Sum_ProzNFK := Sum_ProzNFK + ProzNFK_arr[i].v;
    end;
  end;

  if ExWld_arr[1].v <= 0.0 then
    ProznFK_act_rooted_comps.v := 100
  else
    ProznFK_act_rooted_comps.v := Sum_ProzNFK / act_rooted_comps.v;

  if AutoIrriOptStr.Option = 'yes' then
  begin
    if AutoirriMethod = amTransRatio then
    begin
      if (self.TransRatio.v < 0.99) then
      begin
        WAmount[1].v := WAmount[1].v + self.IrriAmount.v / 10 * dt.v;
        CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v * dt.v;
      end;
    end;
    if AutoirriMethod = amProznFKWe then
    begin
      if (self.ProznFK0_Weff.v < Autoirri_nFKcrit.v) then
      begin
        WAmount[1].v := WAmount[1].v + self.IrriAmount.v / 10 * dt.v;
        CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v * dt.v;
      end;
    end;
    if AutoirriMethod = amProznFKActRootedComps then
    begin
      if (self.ProznFK_act_rooted_comps.v < Autoirri_nFKcrit.v) and
        (EmergenceDay.v > 0) then
      begin
        WAmount[1].v := WAmount[1].v + self.IrriAmount.v / 10 * dt.v;
        CumAutoIrrigation.c := CumAutoIrrigation.c + self.IrriAmount.v * dt.v;
      end;
    end;
  end;

  ActTrans.v := ActTrans.v + Sum_Sink * 10.0 * dt.v; // [mm]
  CumTrans.c := ActTrans.v; // cumTrans.c+sum_sink*10.0*dt.v;
end;

procedure TSoilWaterModelR.CalcRates;
begin
  if FWithRoots = true then
  begin
    ActTrans.v := 0.0;
    CumTrans.c := 0.0;
    CumAutoIrrigation.c := 0.0;
  end;
  // for debugging
  // Pottrans.v := 0.0;
  inherited CalcRates;
  if FWithRoots = true then
    ActTrans.v := ActTrans.v / GlobTime.c;
  If GlobTime.v > GlobMod.Starttime then
  begin // add values to water balance
    CumWaterBalance.c := CumWaterBalance.c + CumTrans.c - CumAutoIrrigation.c;
  end;
  If (ActTrans.v > 0.0) and (PotTrans.v > 0) then
  begin
    TransRatio.v := max(0, min(1, ActTrans.v / PotTrans.v));
    TransIntRatio.v :=
      max(0, min(1, (ActTrans.v + Interzeption.v) /
      (PotTrans.v + Interzeption.v))); // ar
  end
  else
  begin
    TransRatio.v := 1.0;
    TransIntRatio.v := 1.0;
  end;
  if ((PotTrans.v + Interzeption.v + pot_Evap.v) > 0.0) then
    Eact_ETP.v := Act_Evap.v / (PotTrans.v + Interzeption.v + pot_Evap.v)
  else
    Eact_ETP.v := 1;
  CumET.c := CumTrans.c + Act_Evap.v;
  CumETpot.c := PotTrans.v + pot_Evap.v;
  CumTranspot.c := PotTrans.v;
{$IFNDEF NONVISUAL}
  if DebugModus and (DebugForm <> NIL) then
    DebugForm.update;
{$ENDIF}
end;

procedure TSoilWaterModelR.CreateOptionsRootedSoil;
begin
  // fAutoIrrigate := no;
  // option for
  OptCreate('SqrWl_Sink_ReductionFactor', 'NoReductionFactor', f_SqrWl_Option,
    'Option for sink reduction (Sqr_wl_arr calculation), non linear/linear distribution of sink according to relative root length');
  f_SqrWl_Option.OptionList.Add('ReductionFactor');
  f_SqrWl_Option.OptionList.Add('NoReductionFactor');

  OptCreate('AutoIrri', 'no', AutoIrriOptStr, 'Option for using an automatic irrigation algorithm');
  AutoIrriOptStr.OptionList.Clear;
  AutoIrriOptStr.OptionList.Add('no');
  AutoIrriOptStr.OptionList.Add('yes');

  OptCreate('AutoIrriMethod', 'amProznFKWe', AutoIrriMethodOptStr, 'Choice for method of automatic irrigation control');
  AutoIrriMethodOptStr.OptionList.Clear;
  AutoIrriMethodOptStr.OptionList.Add('amProznFKWe');
  AutoIrriMethodOptStr.OptionList.Add('amTransRatio');
  AutoIrriMethodOptStr.OptionList.Add('amProznFKActRootedComps');

  OptCreate('SinkTermMethod', 'Feddes', SinkTermMethodOptStr);
  SinkTermMethodOptStr.OptionList.Clear;
  SinkTermMethodOptStr.OptionList.Add('Psicrit');
  SinkTermMethodOptStr.OptionList.Add('Psicrit_corr');
  SinkTermMethodOptStr.OptionList.Add('nFkcrit');
  SinkTermMethodOptStr.OptionList.Add('Feddes');
  SinkTermMethodOptStr.OptionList.Add('MFP');

  OptCreate('WriteMFPTable', 'false', WriteMFPTable,
    'Option for MFP tables for each layer as txt-file');
  WriteMFPTable.OptionList.Add('true');
  WriteMFPTable.OptionList.Add('false');

end;

procedure TSoilWaterModelR.SetPlantModel(NewPlantModel: TAbstractplant);

var
  i: integer;

begin
  inherited;
  if (Plantmodel <> nil) and (Plantmodel.withroots = true) then
  begin
    for i := 1 to n_comp do
    begin
      ExWld_arr[i].Search := false;
      ExWld_arr[i].f_v := @Plantmodel.p_WLD[i].fv;
      ExWld_arr[i].source := '[' + NewPlantModel.name + ']';
    end;
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSoilWaterModelR]);
{$ENDIF}
end;

end.
