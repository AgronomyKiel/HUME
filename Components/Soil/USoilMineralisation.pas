unit USoilMineralisation;

{ Sub-Modell zur Beschreibung der Dynamik der Umsetzungen organischer Substanz
  im Boden.
  Vereinfachte Umsetzung des Artikels von Verberne et al. 1990: Modelling organic matter dynamics
  in different soils, Neth.J.agr.Sci., 38, 221-238 }

interface

uses
  Ustate, UlayeredSoil, UMod, IniFiles, classes, UAbstractSoilMinOld;

type

  TMinProcess = Class(Tobject)

  public
    Name: string;
    k: TPar; { Reaktionskonstante          [1/d] }
    E: TPar; { Umwandlungseffizienz        [-] }
    C_flow: real; // actual c flow rate from (loss from Edukt
    Nr: real; { Mineralisations-/Immobilisationsrate [kg N/(ha*d] }
    Edukt, Produkt: Pools;

    procedure init(iName: string; ik, iE: TPar; iEdukt, iProdukt: Pools);

    procedure Calculate(F_abiot: real; f_Nmin: real; CN: TPoolParArray;
      var CPools: TPoolStateArray; var NPools: TPoolVarArray;
      NoImmobilisation: boolean);
    // destructor destroy;
  end;



  // *****************************************************************
  // *********    Objekt das Mineralisation abbildet *****************
  // *****************************************************************

  TSoilMin = class(TAbstractSoilMinOld)

  protected

  public
    NOrgLayers: TPar; // Zahl der organischen Schcihten a 10 [cm]
    OrgDepth: TPar; // Gesamttiefe des Humushorizontes in [cm]
    iLagerungsdichte: TPar; // anf�ngliche Lagerungsdichte
    Lagerungsdichte: TVar; // aktuelle Lagerungsdichte
    Humusgehalt: TPar; // Humusgehalt

    MinNmin: TPar; // minimaler Nmin-Gehalt
    kBBf: TPar; // "Abbaurate" des Bodenbearbeitungseffektes

    /// <summary> intercept parameter for reducing k_som_biom by Nmin availability </summary>
    k_som_biom_intercept: TPar;

    /// <summary> slope parameter for reducing k_som_biom by Nmin availability </summary>
    k_som_biom_slope: TPar;



    Temp: TExternV; //
    Theta_Array: array [1 .. MaxNOrgLayers] of TExternV;
    Nmin_Array: array [1 .. MaxNOrgLayers] of TExternV;

    // die einzelnen Mineralisationsprozesse
    MinProcesses: array [0 .. MaxNOrgLayers, processes] of TMinProcess;
    CFlowArr: array [processes, 0 .. MaxNOrgLayers] of TVar;

    C_ges, // Gesamtkohlenstoffgehalt des Bodens [kg/ha]
    C_ER, // Kohlenstoff in Ernter�ckst�nden    [kg/ha]
    N_ER // Stickstoff  in Ernter�ckst�nden      [kg/ha]
      : TState;

    N_ges, // Gesamtstickstoffgehalt des Bodens  [kg/ha]
    f_DPM, SumMinr, Net_ming, NBilanz: TVar;
    NetMinArr: array [processes, 0 .. MaxNOrgLayers] of TVar;

    km_Nmin, // Parameter for decreasing decomposition rates under nitrogen shortage
    k_dpm_biom, k_rpm_biom, k_som_biom, k_biom_som, E_dpm_biom, E_rpm_biom,
      E_som_biom, E_biom_som, f_biom
    // Anteil der Biomasse am Gesamt C  ~ 0.0001;

      : TPar;

    ResidueIncorp: TOption;

    CPool: Array [Pools] of TState;
    NPool: Array [Pools] of TVar;
    CN: TPoolParArray;

    Net_min: array [0 .. MaxNOrgLayers] of TVar;
    F_abiot: array [0 .. MaxNOrgLayers] of TVar;
    
    /// <summary>
    /// Relative factor for reducing decomposition rate under nitrogen shortage [0..1]
     /// </summary>
    f_Nmin: array [0 .. MaxNOrgLayers] of TVar;

     /// <summary> factor for affecting k_som_biom by soil mineral N availability </summary>
     f_som_biom: array [0 .. MaxNOrgLayers] of TVar;
    // relative factor [0..1] for reducing decomposition rate under nitrogen shortage
    BBf: array [0 .. MaxNOrgLayers] of TState;
    Layerfactor: array [0 .. MaxNOrgLayers] of TPar;
    c_frac: array [0 .. MaxNOrgLayers] of TPar; //

    NPool_i: array [0 .. MaxNOrgLayers] of TPoolVarArray;
    CPool_i: array [0 .. MaxNOrgLayers] of TPoolStateArray;
    NetMinE: array [0 .. MaxNOrgLayers] of TExternV;
    C_distributionmethod: TOption;
    Norg, // total amount of organic nitrogen [kg/ha] sum of all other pools and over layers
    Corg: TVar; // total amount of organic carbon [kg/ha]

    procedure CreateAll; override;

    procedure init(Var GlobMod: TMod); Override;
    procedure CalcRates; override;
    procedure Integrate; override;

    procedure AddResidues(Carbon, nitrogen: real); override;
    procedure MixLayers(depth: real); override;
    procedure beforedestruction; override;

  published

    property Par_km_Nmin: TPar read km_Nmin write km_Nmin;
    property Ex_Temp: TExternV read Temp write Temp;
    property Var_NetMinG: TVar read Net_ming write Net_ming;
    property Var_SumMInr: TVar read SumMinr write SumMinr;
    property opt_c_distributionmethod: TOption read C_distributionmethod
      write C_distributionmethod;

  end;

var
  SoilMineralisation: TSoilMin;
  rep: boolean = false;
  RefMin: real = 0.0;
  NsummeAlt: real = 0.0;
  Nsumme: real = 0.0;

procedure Register;

implementation

uses
  math, SysUtils
{$IFNDEF NONVISUAL}
    , vcl.dialogs
{$ENDIF}
    ;

{ ********************************************************************** }

function min_red_f(wasser, Temp, TRD: real): real;

{ ********************************************************************** }
{ Zweck :  Berechnung eines Reduktionsfaktors der Mineralisation
  in Abh�ngigkeit von Bodenfeuchte und Bodentemperatur.
  Es wird davon ausgegeangen, da� die Mineralisation bei
  35 �C und 35 Vol% Wassergehalt ihren maximalen Wert
  erreicht.

  Quelle: Verbruggen (1985) zit. in Groot (1987)


  Parameter :

  Name             Inhalt                          Einheit      Typ

  Wasser           volumetrischer Wassergehalt     [cm3/cm3]    I
  Temp             Bodentemperatur                 [�C]         I
  TRD              Trockenraumdichte               [g/cm3]      I

  Min_red_f        Reduktionsfaktor                [-]          O
  { ********************************************************************** }

const
  RefTemp = 20.0; // Referenztemperatur [�C]
  RefWass = 0.35; // Referenzwassergehalt
  RefTRD = 1.5; // Referenzbodendichte

var
  a, b, f: real;

begin
  If rep = false then
  begin
    a := 0.22 * power((RefTemp + 0.00064), 1.4425);
    b := 0.1737 * exp(-0.119 * RefTemp) + 0.1107;
    RefMin := a * (1.0 - exp(-b * RefWass / RefTRD));
    rep := true;
  end;
  If Temp > 0.0 then
  begin
    a := 0.22 * power((Temp + 0.00064), 1.4425);
    b := 0.1737 * exp(-0.119 * Temp) + 0.1107;
    f := a * (1.0 - exp(-b * wasser / TRD));
    f := f / RefMin;
    If f > 3.0 then
      f := 3.0;
    If f < 0.0 then
      f := 0.0;
  end
  else
    f := 0.0;
  min_red_f := f;
end;

procedure TMinProcess.init(iName: string; ik, iE: TPar;
  iEdukt, iProdukt: Pools);

begin
  Name := iName;
  k := ik;
  E := iE;
  Edukt := iEdukt;
  Produkt := iProdukt;
end;

procedure TMinProcess.Calculate(F_abiot: real; f_Nmin: real; CN: TPoolParArray;
  var CPools: TPoolStateArray; var NPools: TPoolVarArray;
  NoImmobilisation: boolean);

Var
  C_flow_educt, C_flow_product: real;
begin
  C_flow_educt := F_abiot * (-CPools[Edukt].V * k.V);
  C_flow_product := F_abiot * (CPools[Edukt].V * k.V * E.V);
  Nr := -C_flow_educt * (1 / CN[Edukt].V - E.V / CN[Produkt].V);
  if Nr <= 0.0 then
  begin
    C_flow_educt := f_Nmin * C_flow_educt;
    // if nr is negative, fNmin accounts for influence of nitrate availability
    C_flow_product := f_Nmin * C_flow_product;
    Nr := -C_flow_educt * (1 / CN[Edukt].V - E.V / CN[Produkt].V);
  end;
  If (Nr <= 0) and NoImmobilisation then
  begin
    CPools[Edukt].c := 0.0;
    CPools[Produkt].c := 0.0;
    Nr := 0.0;

  end;
  CPools[Edukt].c := CPools[Edukt].c + C_flow_educt;
  CPools[Produkt].c := CPools[Produkt].c + C_flow_product;

  Nr := -C_flow_educt * (1 / CN[Edukt].V - E.V / CN[Produkt].V);

  C_flow := C_flow_educt;
end;

procedure TSoilMin.CreateAll;
var
  schicht: integer;
  value: real;
  Process: processes;

begin
  inherited;
  ParCreate('CN_dpm', '[-]', cn_dpm, CN[dpm]);
  ParCreate('CN_rpm', '[-]', cn_rpm, CN[rpm]);
  ParCreate('CN_som', '[-]', cn_som, CN[som]);
  ParCreate('CN_biom', '[-]', cn_biom, CN[biom]);
  ParCreate('f_biom', '[-]', 0.001, f_biom);
  ParCreate('Km_Nmin', '[-]', 1, km_Nmin);

  ParCreate('NOrgLayers', '[]', MaxNOrgLayers, NOrgLayers);
  ParCreate('kBBf', '[1/d]', 0.05, kBBf);

  ParCreate('OrgDepth', '[cm]', 30, OrgDepth);
  ParCreate('ini.Lagerungsdichte', '[g/cm3]', 1.3, iLagerungsdichte);
  VarCreate('act.Lagerungsdichte', '[g/cm3]', 1.3, false, Lagerungsdichte);
  ParCreate('Humusgehalt', '[-]', 0.018, Humusgehalt);
  ParCreate('MinNmin', '[-]', 2., MinNmin);
  
  ParCreate('k_som_biom_intercept', '[-]', 1.2, k_som_biom_intercept);
  ParCreate('k_som_biom_slope', '[1/kg N/ha]', 0.005, k_som_biom_slope);
  value := 0.0;



  StateCreate('C_ges', '[kg C/ha]', 0, false, C_ges);
  VarCreate('N_ges', '[kg N/ha]', value, false, N_ges);
  VarCreate('NBilanz', '[kg N/ha]', value, false, NBilanz);

  ExternVCreate('Temp', '[�C]', StateField, Temp);
  for schicht := 1 to trunc(NOrgLayers.V) do
    if schicht < 10 then
      ExternVCreate('WG_' + IntToStr(schicht), '[cm3.cm3]', StateField,
        Theta_Array[schicht])
    else
      ExternVCreate('WG' + IntToStr(schicht), '[cm3.cm3]', StateField,
        Theta_Array[schicht]);

  VarCreate('f_abiot0', '[-]', 1.0, false, F_abiot[0]);
  VarCreate('Net_min0', '[kg N.ha-1.d-1]', 0.0, false, Net_min[0]);

  for schicht := 0 to trunc(NOrgLayers.V) do
    VarCreate('f_Nmin' + IntToStr(schicht), '[-]', 1.0, false, f_Nmin[schicht]);

  for schicht := 1 to trunc(NOrgLayers.V) do
    VarCreate('f_som_biom' + IntToStr(schicht), '[-]', 1.0, false,
      f_som_biom[schicht]);


  for schicht := 1 to trunc(NOrgLayers.V) do
  begin
    VarCreate('f_abiot' + IntToStr(schicht), '[-]', 1.0, false,
      F_abiot[schicht]);
    StateCreate('BBf' + IntToStr(schicht), '[]', 1, true, BBf[schicht]);
    VarCreate('Net_min' + IntToStr(schicht), '[kg N.ha-1.d-1]', 0.0, false,
      Net_min[schicht]);
    ExternVCreate('Netmin_' + IntToStr(schicht), '[kg N.ha-1.d-1]', rateField,
      NetMinE[schicht]);
    ExternVCreate('Nmin_' + IntToStr(schicht), '[kg N.ha-1]', StateField,
      Nmin_Array[schicht]);
    ParCreate('Layerfactor_' + IntToStr(schicht), '[-]', 1,
      Layerfactor[schicht]);
    ParCreate('C_frac' + IntToStr(schicht), '[-]', 1 / trunc(NOrgLayers.V),
      c_frac[schicht]);

  end;

  StateCreate('C_ER', '[kg C/ha]', 0.1, true, C_ER);
  StateCreate('N_ER', '[kg N/ha]', 0.01, true, N_ER);

  VarCreate('F_DPM', '[-]', value, true, f_DPM);

  VarCreate('SumMinr', '[kg N/ha]', 0.0, false, SumMinr);
  VarCreate('Net_ming', '[kg N.ha-1.d-1]', 0.0, false, Net_ming);

  for schicht := 0 to trunc(NOrgLayers.V) do
  begin
    for Process := low(processes) to high(processes) do
    begin
      MinProcesses[schicht, Process] := TMinProcess.create;
      Case Process of
        dpm_biom:
          VarCreate('NetMin_' + 'dpm_biom_' + IntToStr(schicht), '[kg N/ha*d]',
            value, false, NetMinArr[Process, schicht]);
        rpm_biom:
          VarCreate('NetMin_' + 'rpm_biom_' + IntToStr(schicht), '[kg N/ha*d]',
            value, false, NetMinArr[Process, schicht]);
        som_biom:
          VarCreate('NetMin_' + 'som_biom_' + IntToStr(schicht), '[kg N/ha*d]',
            value, false, NetMinArr[Process, schicht]);
        biom_som:
          VarCreate('NetMin_' + 'biom_som_' + IntToStr(schicht), '[kg N/ha*d]',
            value, false, NetMinArr[Process, schicht]);
      end;
      Case Process of
        dpm_biom:
          VarCreate('Cflow_' + 'dpm_biom_' + IntToStr(schicht), '[kg C/ha*d]',
            value, false, CFlowArr[Process, schicht]);
        rpm_biom:
          VarCreate('Cflow_' + 'rpm_biom_' + IntToStr(schicht), '[kg C/ha*d]',
            value, false, CFlowArr[Process, schicht]);
        som_biom:
          VarCreate('Cflow_' + 'som_biom_' + IntToStr(schicht), '[kg C/ha*d]',
            value, false, CFlowArr[Process, schicht]);
        biom_som:
          VarCreate('Cflow_' + 'biom_som_' + IntToStr(schicht), '[kg C/ha*d]',
            value, false, CFlowArr[Process, schicht]);
      end;
    end;
  end;

  ParCreate('k_dpm_biom', '[1/d]', ik_dpm_biom, k_dpm_biom);
  ParCreate('E_dpm_biom', '[1/d]', iE_dpm_biom, E_dpm_biom);
  ParCreate('k_rpm_biom', '[1/d]', ik_rpm_biom, k_rpm_biom);
  ParCreate('E_rpm_biom', '[1/d]', iE_rpm_biom, E_rpm_biom);

  ParCreate('k_som_biom', '[1/d]', ik_som_biom, k_som_biom);
  ParCreate('E_som_biom', '[1/d]', iE_som_biom, E_som_biom);

  ParCreate('k_biom_som', '[1/d]', ik_biom_som, k_biom_som);
  ParCreate('E_biom_som', '[1/d]', iE_biom_som, E_biom_som);

  StateCreate('C_DPM', '[kg C/ha]', value, true, CPool[dpm]);
  VarCreate('N_DPM', '[kg N/ha]', value, false, NPool[dpm]);

  StateCreate('C_RPM', '[kg C/ha]', value, true, CPool[rpm]);
  VarCreate('N_RPM', '[kg N/ha]', value, false, NPool[rpm]);

  StateCreate('C_SOM', '[kg C/ha]', value, true, CPool[som]);
  VarCreate('N_SOM', '[kg N/ha]', 0.0, false, NPool[som]);

  StateCreate('C_BIOM', '[kg C/ha]', value, true, CPool[biom]);
  VarCreate('N_BIOM', '[kg N/ha]', 0, true, NPool[biom]);

  VarCreate('C_org', '[kg N/ha]', value, false, Corg);
  VarCreate('N_org', '[kg N/ha]', value, false, Norg);

  for schicht := 0 to trunc(NOrgLayers.V) do
  begin
    StateCreate('C_DPM_' + IntToStr(schicht), '[kg C/ha]', 0.0, false,
      CPool_i[schicht, dpm]);
    VarCreate('N_DPM_' + IntToStr(schicht), '[kg N/ha]', CPool_i[schicht, dpm].V
      / CN[dpm].V, false, NPool_i[schicht, dpm]);

    StateCreate('C_rpm_' + IntToStr(schicht), '[kg C/ha]', 0.0, false,
      CPool_i[schicht, rpm]);
    VarCreate('N_rpm_' + IntToStr(schicht), '[kg N/ha]', CPool_i[schicht, rpm].V
      / CN[rpm].V, false, NPool_i[schicht, rpm]);

    StateCreate('C_som_' + IntToStr(schicht), '[kg C/ha]', 0.0, false,
      CPool_i[schicht, som]);
    VarCreate('N_som_' + IntToStr(schicht), '[kg N/ha]', 0.0, false,
      NPool_i[schicht, som]);

    StateCreate('C_Biom_' + IntToStr(schicht), '[kg C/ha]', 0.0, false,
      CPool_i[schicht, biom]);
    VarCreate('N_Biom_' + IntToStr(schicht), '[kg N/ha]', 0.0, false,
      NPool_i[schicht, biom]);

  end;
  OptCreate('c_distributionmethod', 'even', C_distributionmethod);
  C_distributionmethod.OptionList.Add('even');
  C_distributionmethod.OptionList.Add('user specific');

  OptCreate('ResidueIncorp', 'InSoil', ResidueIncorp);
  ResidueIncorp.OptionList.Add('InSoil');
  ResidueIncorp.OptionList.Add('OnTop');

end;

procedure TSoilMin.beforedestruction;

var
  schicht: integer;
  Process: processes;

begin
  for schicht := 0 to trunc(NOrgLayers.V) do
    for Process := low(processes) to high(processes) do
      FreeandNil(MinProcesses[schicht, Process]);
  inherited;
end;

procedure TSoilMin.init(Var GlobMod: TMod);

var
  schicht: integer;
  Pool: Pools;
  c_frac_control: real;

begin
  inherited init(GlobMod);
  if C_distributionmethod.Option = 'even' then
  begin // default option, calculates fractions evenly distributed between all organic soil layers
    for schicht := 1 to trunc(NOrgLayers.V) do
      c_frac[schicht].V := 1 / trunc(NOrgLayers.V);
    for schicht := trunc(NOrgLayers.V) + 1 to MaxNOrgLayers do
      c_frac[schicht].V := 0.0;
  end;

  c_frac_control := 0;
  // if not overwritten by previous routine, fractions from inifile are used and a control variable is calculated here
  for schicht := 1 to trunc(NOrgLayers.V) do
    c_frac_control := c_frac_control + c_frac[schicht].V;
  if (c_frac_control > (1 + 1E-5)) or (c_frac_control < (1 - 1E-5))

{$IFNDEF NONVISUAL}
  then
    showmessage('Error in fractioning of organic matter between layers!');
{$ELSE}
  then writeln('Error in fractioning of organic matter between layers!');
{$ENDIF}
  C_ges.V := 0.5 * OrgDepth.V / 100 * 1E4 * 1000 * iLagerungsdichte.V *
    Humusgehalt.V;
  N_ges.V := C_ges.V / CN[som].V;

  for schicht := 1 to trunc(NOrgLayers.V) do
  begin
    Net_min[schicht].V := 0.0;
    F_abiot[schicht].V := 1.0;
    BBf[schicht].V := 1.0;
  end;

  if C_ER.V > 0.0 then

    f_DPM.V := (-N_ER.V * CN[dpm].V * CN[rpm].V / C_ER.V + CN[dpm].V) /
      (-CN[rpm].V + CN[dpm].V)
  else
    f_DPM.V := 0.0;

  SumMinr.V := 0.0;
  Net_ming.V := 0.0;

  CPool[dpm].V := 0.0; // set sum to zero
  CPool[rpm].V := 0.0; // set sum to zero

  for schicht := 1 to trunc(NOrgLayers.V) do
  begin
    CPool[dpm].V := CPool[dpm].V + CPool[dpm].V;
    // if 'historic' residues are present they are added first to the total sums
    CPool[rpm].V := CPool[rpm].V + CPool[rpm].V;
    // if 'historic' residues are present they are added first to the total sums
  end;

  CPool[dpm].V := CPool[dpm].V + C_ER.V * f_DPM.V; // total pools for all layers
  NPool[dpm].V := CPool[dpm].V / CN[dpm].V;
  CPool[rpm].V := CPool[rpm].V + C_ER.V * (1 - f_DPM.V);
  NPool[rpm].V := CPool[rpm].V / CN[rpm].V;
  CPool[som].V := C_ges.V * (1 - f_biom.V);
  NPool[som].V := CPool[som].V / CN[som].V;
  CPool[biom].V := C_ges.V * f_biom.V;
  NPool[biom].V := CPool[biom].V / CN[biom].V;

  If lowercase(ResidueIncorp.Option) = 'insoil' then
  begin

    for schicht := 1 to trunc(NOrgLayers.V) do
    begin
      for Pool := dpm to som do
      begin
        CPool_i[schicht, Pool].V := CPool[Pool].V * c_frac[schicht].V;
        NPool_i[schicht, Pool].V := CPool_i[schicht, Pool].V / CN[Pool].V;
      end;
    end;
  end;

  If lowercase(ResidueIncorp.Option) = 'ontop' then
  begin
    for Pool := dpm to rpm do
    begin
      CPool_i[0, Pool].V := CPool[Pool].V;
      NPool_i[0, Pool].V := CPool_i[0, Pool].V / CN[Pool].V;
    end;
    for schicht := 1 to trunc(NOrgLayers.V) do
    begin
      for Pool := biom to som do
      begin
        CPool_i[schicht, Pool].V := CPool[Pool].V * c_frac[schicht].V;
        NPool_i[schicht, Pool].V := CPool_i[schicht, Pool].V / CN[Pool].V;
      end;
    end;

  end;

  for schicht := 0 to trunc(NOrgLayers.V) do
  begin
    MinProcesses[schicht, dpm_biom].init('dpm_biom', k_dpm_biom, E_dpm_biom,
      dpm, biom);
    MinProcesses[schicht, rpm_biom].init('rpm_biom', k_rpm_biom, E_rpm_biom,
      rpm, biom);
    MinProcesses[schicht, som_biom].init('som_biom', k_som_biom, E_som_biom,
      som, biom);
    MinProcesses[schicht, biom_som].init('biom_som', k_biom_som, E_biom_som,
      biom, som);
  end;

end;

procedure TSoilMin.AddResidues(Carbon, nitrogen: real);

begin
  if Carbon > 0.0 then

    f_DPM.V := (-nitrogen * CN[dpm].V * CN[rpm].V / Carbon + CN[dpm].V) /
      (-CN[rpm].V + CN[dpm].V)
  else
    f_DPM.V := 0.0;

  CPool_i[0, dpm].V := CPool_i[0, dpm].V + Carbon * f_DPM.V;
  NPool_i[0, dpm].V := NPool_i[0, dpm].V + CPool_i[0, dpm].V / CN[dpm].V;
  CPool_i[0, rpm].V := CPool_i[0, rpm].V + Carbon * (1 - f_DPM.V);
  NPool_i[0, rpm].V := NPool_i[0, rpm].V + CPool_i[0, rpm].V / CN[rpm].V;

  CPool[dpm].V := CPool[dpm].V + Carbon * f_DPM.V;
  NPool[dpm].V := NPool[dpm].V + CPool[dpm].V / CN[dpm].V;
  CPool[rpm].V := CPool[rpm].V + Carbon * (1 - f_DPM.V);
  NPool[rpm].V := NPool[rpm].V + CPool[rpm].V / CN[rpm].V;

end;

procedure TSoilMin.MixLayers(depth: real);

var
  n_layers, schicht: byte;
  CPoolav, NPoolav: array [Pools] of real;
  Pool: Pools;

begin

  n_layers := trunc(depth / 10);
  If (depth > 2) and (n_layers < 1) then
    n_layers := 1;
  If n_layers < 1 then
    exit;

  for Pool := low(Pools) to high(Pools) do
  begin // set to zero
    CPoolav[Pool] := 0.0;
    NPoolav[Pool] := 0.0;
  end;

  for schicht := 0 to n_layers do
  begin // sum all pools incl. litter layer
    for Pool := low(Pools) to high(Pools) do
    begin
      CPoolav[Pool] := CPoolav[Pool] + CPool_i[schicht, Pool].V;
      NPoolav[Pool] := NPoolav[Pool] + NPool_i[schicht, Pool].V;
    end;
  end;

  for Pool := low(Pools) to high(Pools) do
  begin // calculate average for soil layers
    CPoolav[Pool] := CPoolav[Pool] / n_layers;
    NPoolav[Pool] := NPoolav[Pool] / n_layers;
  end;

  for schicht := 1 to n_layers do
  begin // sum all pools
    for Pool := low(Pools) to high(Pools) do
    begin
      CPool_i[schicht, Pool].V := CPoolav[Pool];
      NPool_i[schicht, Pool].V := NPoolav[Pool];
    end;
  end;

  for Pool := low(Pools) to high(Pools) do
  begin // Litter layer is empty!!
    CPool_i[0, Pool].V := 0.0;
    CPool_i[0, Pool].c := 0.0;
    NPool_i[0, Pool].V := 0.0;
  end;

end;

procedure TSoilMin.CalcRates;

var
  Pool: Pools;
  Procs: processes;
  schicht: integer;

begin
  if fplantmodel <> nil then
  begin // if the soil mineralisation model is linked with a descendant of abstract plant
    AddResidues(fplantmodel.C_Residues.V * 10, fplantmodel.N_Residues.V * 10);
    // Factor 10 to convert from g/m2 to kg/ha
    fplantmodel.C_Residues.V := 0.0;
    fplantmodel.N_Residues.V := 0.0;
  end;

  for schicht := 0 to trunc(NOrgLayers.V) do
  begin // set all change rates to zero
    Net_min[schicht].V := 0.0;
    for Pool := low(Pools) to high(Pools) do
      CPool_i[schicht, Pool].c := 0.0;
  end;

  for Pool := low(Pools) to high(Pools) do // set all change rates to zero
    CPool[Pool].c := 0.0;

  Net_ming.V := 0.0; // set net mineralisation to zero

  // f_abiot[0].v := 0.1; // 10% in der auflageschicht
  F_abiot[0].V := 0.5 * min_red_f(Theta_Array[1].V, Temp.V, 1.5);
  // provisionally set factor for litter layer to 50% of value in first soil layer
  // Net_min[1].v := 0.0;    // Auflageschichtmineralisation wird in erste Schicht gesteckt, daher hier r�cksetzen
  for Procs := low(processes) to high(processes) do
  begin
    MinProcesses[0, Procs].Calculate(F_abiot[0].V, f_Nmin[0].V, CN, CPool_i[0],
      NPool_i[0], false);
    NetMinArr[Procs, 0].V := MinProcesses[0, Procs].Nr;
    CFlowArr[Procs, 0].V := MinProcesses[0, Procs].C_flow;
    Net_min[0].V := Net_min[0].V + MinProcesses[0, Procs].Nr;
    // Mineralisation wird in die erste Bodenschicht gesteckt !
  end;
  Net_ming.V := Net_ming.V + Net_min[0].V;

  for schicht := 1 to trunc(NOrgLayers.V) do
  begin
    f_Nmin[schicht].V :=
      min(1, max(0, (Nmin_Array[schicht].V - MinNmin.V) /
      ((Nmin_Array[schicht].V - MinNmin.V) + km_Nmin.V)));
    // michalis-menten like factor to decrease mineralisation under nitrate shortage

    // factor for effect of soil nitrate on som_biom mineralisation
    f_som_biom[schicht].V := k_som_biom_intercept.v - k_som_biom_slope.V * Nmin_Array[schicht].V;

    if fSoilHeatmodel = nil then
      F_abiot[schicht].V := min_red_f(Theta_Array[schicht].V, Temp.V, 1.5) *
        BBf[schicht].V * Layerfactor[schicht].V
    else
      F_abiot[schicht].V := min_red_f(Theta_Array[schicht].V,
        fSoilHeatmodel.Temp[schicht].V, 1.5) * BBf[schicht].V * Layerfactor
        [schicht].V;

    If schicht > 1 then
      Net_min[schicht].V := 0.0;
    // In Schicht 1 ist schon die Auflageschicht ber�cksichtigt, daher kein r�cksetzen auf 0
    for Procs := dpm_biom to biom_som do
    begin
    // in case som to biom conversion is calculated, the mineralisation rate affected 
    // by the factor for nitrate availability 
      if Procs = som_biom then
        F_abiot[schicht].V := F_abiot[schicht].V * f_som_biom[schicht].V;
      MinProcesses[schicht, Procs].Calculate(F_abiot[schicht].V,
        f_Nmin[schicht].V, CN, CPool_i[schicht], NPool_i[schicht], false);
      NetMinArr[Procs, schicht].V := MinProcesses[schicht, Procs].Nr;
      CFlowArr[Procs, schicht].V := MinProcesses[schicht, Procs].C_flow;
      Net_min[schicht].V := Net_min[schicht].V + MinProcesses
        [schicht, Procs].Nr;
    end;
    Net_ming.V := Net_ming.V + Net_min[schicht].V;

    // Wenn die Festlegung gr��er als der Nmin-Vorrate sein sollte mu� die Mineralisationsrate verringert werden !!!

    If ((Net_min[schicht].V * GlobTime.c + Nmin_Array[schicht].V) < MinNmin.V)
      and (Net_min[schicht].V < 0) then
    begin

      // zur�cksetzen der Mineralisationsrate
      Net_ming.V := Net_ming.V - Net_min[schicht].V;

      // zur�cksetzen der C-Mengen �nderungen
      for Pool := dpm to som do
        CPool_i[schicht, Pool].c := 0.0;
      Net_min[schicht].V := 0.0;
      for Procs := dpm_biom to biom_som do
      begin
        // Setze alle Nitratverbrauchenden Umsetzungen auf Null !
        // If MinProcesses[Schicht,Procs].nr<0.0 then
        MinProcesses[schicht, Procs].Calculate(F_abiot[schicht].V,
          f_Nmin[schicht].V, CN, CPool_i[schicht], NPool_i[schicht], true);
        NetMinArr[Procs, schicht].V := MinProcesses[schicht, Procs].Nr;
        CFlowArr[Procs, schicht].V := MinProcesses[schicht, Procs].C_flow;
        NetMinArr[Procs, schicht].V := MinProcesses[schicht, Procs].Nr;

        Net_min[schicht].V := Net_min[schicht].V + MinProcesses
          [schicht, Procs].Nr;
      end; // loop procs
      Net_ming.V := Net_ming.V + Net_min[schicht].V;
    end; // end
  end; // End of Loop over layers
  Net_min[1].V := Net_min[1].V + Net_min[0].V;
  Net_min[0].V := 0.0;
  SumMinr.V := SumMinr.V + Net_ming.V * GlobTime.c;

  For Pool := dpm to som do
  begin
    CPool[Pool].c := 0.0;
    for schicht := 0 to trunc(NOrgLayers.V) do
    begin // sum up all carbon change rates over soil layers
      // If (-CPool_i[schicht, Pool].c*GlobTime.c) > CPool_i[schicht, Pool].v then
      // CPool_i[schicht,Pool].c := -0.95*CPool_i[schicht, Pool].v/GlobTime.c;        //5% sollen mindestens im Pool bleiben
      CPool[Pool].c := CPool[Pool].c + CPool_i[schicht, Pool].c;

    end;
  end;

  for schicht := 1 to trunc(NOrgLayers.V) do // Decrease of tillage factor
    BBf[schicht].c := -max(0, BBf[schicht].V - 1) * kBBf.V;

  For schicht := 1 to trunc(NOrgLayers.V) do
  // set mineralisation rate in linked transport model
    NetMinE[schicht].f_v^ := Net_min[schicht].V;

end;

procedure TSoilMin.Integrate;

// const

var
  schicht: integer;
  Pool: Pools;

begin
  inherited Integrate;
  NsummeAlt := Nsumme;
  Nsumme := 0.0;
  for Pool := low(Pools) to high(Pools) do
  begin
    NPool[Pool].V := CPool[Pool].V / CN[Pool].V;
    Nsumme := Nsumme + NPool[Pool].V;
    for schicht := 0 to trunc(NOrgLayers.V) do
      NPool_i[schicht, Pool].V := CPool_i[schicht, Pool].V / CN[Pool].V;
  end;
  If NsummeAlt > 0.0 then
    NBilanz.V := (NsummeAlt - Nsumme) / GlobTime.c - Net_ming.V
  else
    NBilanz.V := 0.0;
  N_ER.V := NPool[dpm].V + NPool[rpm].V;
  C_ER.V := CPool[dpm].V + CPool[rpm].V;
  Norg.V := 0.0;
  Corg.V := 0.0;
  for Pool := low(Pools) to high(Pools) do
  begin
    Norg.V := Norg.V + NPool[Pool].V;
    Corg.V := Corg.V + CPool[Pool].V;
  end;

end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TSoilMin]);
{$ENDIF}
end;

end.
