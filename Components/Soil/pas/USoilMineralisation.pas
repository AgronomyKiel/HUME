unit USoilMineralisation;

{Sub-Modell zur Beschreibung der Dynamik der Umsetzungen organischer Substanz
 im Boden.
 Vereinfachte Umsetzung des Artikels von Verberne et al. 1990: Modelling organic matter dynamics
 in different soils, Neth.J.agr.Sci., 38, 221-238}


interface

uses
  Ustate, UlayeredSoil, UMod, IniFiles, classes, UAbstractSoilMin;

const
  CN_biom : real = 8.0;           { CN-Verhältnis BIOM }
  CN_som : real = 10.0;           { CN-Verhältnis SOM  }
  CN_DPM : real = 6.0;            { CN-Verhältnis DPM  }
  CN_RPM : real = 80;             { CN-Verhältnis RPM  }

  ik_dpm_biom : real = 1.34;      // Reaktionskonstanten der einzelnen Prozessse
  iE_dpm_biom : real = 0.4;       // Umwandlungseffizienzen
  ik_rpm_biom : real = 0.086;
  iE_rpm_biom : real = 0.4;
  ik_som_biom : real = 0.0001;
  iE_som_biom : real = 0.2;
  ik_biom_som : real = 0.3;
  iE_biom_som : real = 1;


type
  Pools =
  {Es werden zwei Fraktionen in den Pflanzenrückständen angenommen:}
          (DPM, { = decomposable material  }
           RPM,  { = resistant material     }
           BIOM, { = mikrobielle Biomasse gesamt }
           SOM );{ = stabilized organic matter }

  { zwischen den pools laufen folgende Umwandlungsprozesse ab :}

  processes   = (dpm_biom,
                 rpm_biom,
                 som_biom,
                 biom_som);

TPoolStateArray = array[Pools] of TState;
TPoolVarArray   = array[Pools] of TVar;
TPoolParArray   = array[Pools] of TPar;


TMinProcess = Class(Tobject)

public
  Name   : string;
  k    : TPar;  { Reaktionskonstante          [1/d]        }
  E    : Tpar;  { Umwandlungseffizienz        [-]          }
  C_flow : real; // actual c flow rate from (loss from Edukt
  Nr   : real;  { Mineralisations-/Immobilisationsrate [kg N/(ha*d] }
  Edukt, Produkt : Pools;

  procedure init( iName : string;
                      ik, iE : TPar;
                      iEdukt, iProdukt: Pools);

  procedure Calculate(F_abiot:real; f_Nmin: real; CN : TPoolParArray;
                            var CPools : TPoolStateArray;
                            var NPools : TPoolVarArray;
                            NoImmobilisation: boolean);
//  destructor destroy;
end;



//*****************************************************************
//*********    Objekt das Mineralisation abbildet *****************
//*****************************************************************

TSoilMin = class(TAbstractSoilMin)

protected

public
  NOrgLayers : Tpar;       // Zahl der organischen Schcihten a 10 [cm]
  OrgDepth   : Tpar;       // Gesamttiefe des Humushorizontes in [cm]
  iLagerungsdichte : Tpar; // anfängliche Lagerungsdichte
  Lagerungsdichte  : TVar; // aktuelle Lagerungsdichte
  Humusgehalt     : Tpar;  // Humusgehalt

  MinNmin         : Tpar;  // minimaler Nmin-Gehalt
  kBBf            : TPar; // "Abbaurate" des Bodenbearbeitungseffektes

  Temp : TExternV;         //
  Theta_Array : array[1..MaxNOrgLayers] of TExternV;
  Nmin_Array  : array[1..MaxNOrgLayers] of TExternV;

                           // die einzelnen Mineralisationsprozesse
  MinProcesses : array[0..MaxNOrgLayers, processes] of TMinProcess;
  CFlowArr : array[processes,0..MaxNOrgLayers] of TVar;

  C_ges,              // Gesamtkohlenstoffgehalt des Bodens [kg/ha]
  C_ER,               // Kohlenstoff in Ernterückständen    [kg/ha]
  N_ER                // Stickstoff  in Ernterückständen      [kg/ha]
  : TState;

  N_ges,              // Gesamtstickstoffgehalt des Bodens  [kg/ha]
  f_DPM,
  SumMinr,
  Net_ming,
  NBilanz
              : Tvar;
  NetMinArr : array[processes,0..MaxNOrgLayers] of TVar;

  km_Nmin,            // Parameter for decreasing decomposition rates under nitrogen shortage
  k_dpm_biom,
  k_rpm_biom,
  k_som_biom,
  k_biom_som,
  E_dpm_biom,
  E_rpm_biom,
  E_som_biom,
  E_biom_som,
  f_biom                   // Anteil der Biomasse am Gesamt C  ~ 0.0001;

   : TPar;

  ResidueIncorp : TOption;

  CPool   : Array[Pools] of TState;
  NPool   : Array[Pools] of TVar;
  CN      : TPoolParArray;

  Net_min : array[0..MaxNOrgLayers] of TVar;
  f_abiot : array[0..MaxNOrgLayers] of TVar;
  f_Nmin  : array[0..MaxNOrgLayers] of TVar;   // relative factor [0..1] for reducing decomposition rate under nitrogen shortage
  BBf     : array[0..MaxNOrgLayers] of TState;
  Layerfactor : array[0..MaxNOrgLayers] of TPar;
  c_frac : array[0..MAxNOrgLayers] of TPar;   //


  NPool_i : array[0..MaxNOrgLayers] of TPoolVarArray;
  CPool_i : array[0..MaxNOrgLayers] of TPoolStateArray;
  NetMinE : array[0..MaxNOrgLayers] of TExternV;
  C_distributionmethod : Toption;
  Norg,         // total amount of organic nitrogen [kg/ha] sum of all other pools and over layers
  Corg : TVar;  // total amount of organic carbon [kg/ha]

  procedure CreateAll; override;

  procedure Init(Var GlobMod: TMod); Override;
  procedure CalcRates; override;
  procedure Integrate; override;

  procedure AddResidues(Carbon, nitrogen:real); override;
  procedure MixLayers(depth: real);  override;
  procedure beforedestruction; override;

published

  property Par_km_Nmin     : TPar read km_Nmin write km_Nmin;
  property Ex_Temp     : TExternV read Temp write Temp;
  property Var_NetMinG : Tvar read Net_MinG write Net_Ming;
  property Var_SumMInr : TVar read SumMinr write SumMInr;
  property opt_c_distributionmethod : Toption read c_distributionmethod write c_distributionmethod;


end;

var
  SoilMineralisation : TSoilMin;
   rep     : boolean = false;
  RefMin  : real    = 0.0;
   NsummeAlt : real = 0.0;
  Nsumme    : real = 0.0;

procedure Register;
implementation


uses
  math, SysUtils, dialogs;


{ ********************************************************************** }


function min_red_f ( wasser, temp, TRD : real ) : real;

{ ********************************************************************** }
{ Zweck :  Berechnung eines Reduktionsfaktors der Mineralisation
           in Abh„ngigkeit von Bodenfeuchte und Bodentemperatur.
           Es wird davon ausgegeangen, daá die Mineralisation bei
           35 øC und 35 Vol% Wassergehalt ihren maximalen Wert
           erreicht.

  Quelle: Verbruggen (1985) zit. in Groot (1987)


  Parameter :

    Name             Inhalt                          Einheit      Typ

    Wasser           volumetrischer Wassergehalt     [cm3/cm3]    I
    Temp             Bodentemperatur                 [øC]         I
    TRD              Trockenraumdichte               [g/cm3]      I

    Min_red_f        Reduktionsfaktor                [-]          O
{ ********************************************************************** }


const
  RefTemp = 20.0;    // Referenztemperatur [°C]
  RefWass = 0.35;    // Referenzwassergehalt
  RefTRD  = 1.5;     // Referenzbodendichte


var
  a, b, f : real;

begin
  If rep = false then begin
    a      := 0.22*power((RefTemp+0.00064), 1.4425);
    b      := 0.1737*exp(-0.119*RefTemp)+0.1107;
    RefMin := a*(1.0-exp(-b*RefWass/RefTRD));
    rep    := true;
  end;
  If temp > 0.0 then begin
    a      := 0.22*power((temp+0.00064), 1.4425);
    b      := 0.1737*exp(-0.119*temp)+0.1107;
    f      := a*(1.0-exp(-b*wasser/TRD));
    f      := f/RefMin;
    If f > 3.0 then f := 3.0;
    If f < 0.0 then f := 0.0;
  end else f := 0.0;
  min_red_f := f;
end;





procedure TMinProcess.init( iName : string;
                      ik, iE : TPar;
                      iEdukt, iProdukt: Pools);

begin
  Name := iName;
  k := iK;
  E := iE;
  Edukt  := iEdukt;
  Produkt := iProdukt;
end;

procedure TMinProcess.Calculate(F_abiot:real; f_Nmin: real; CN : TPoolParArray;
                            var CPools : TPoolStateArray;
                            var NPools : TPoolVarArray;
                            NoImmobilisation: boolean);

Var
  C_flow_educt, C_flow_product : real;
begin
   C_flow_educt   := f_abiot*(-CPools[edukt].V*k.v);
   C_flow_product := f_abiot*(CPools[Edukt].V*k.v*E.v);
   Nr  := -C_flow_educt*(1/CN[Edukt].v-E.v/CN[Produkt].v);
   if Nr <= 0.0 then begin
     C_flow_educt   :=  f_Nmin*C_flow_educt; // if nr is negative, fNmin accounts for influence of nitrate availability
     C_flow_product :=  f_Nmin*C_flow_product;
     Nr  := -C_flow_educt*(1/CN[Edukt].v-E.v/CN[Produkt].v);
   end;
   If (Nr <= 0) and NoImmobilisation then begin
     CPools[Edukt].c   :=  0.0;
     CPools[Produkt].c :=  0.0;
     Nr  := 0.0;

   end;
   CPools[Edukt].c := CPools[Edukt].c  + C_flow_educt;
   CPools[produkt].c := CPools[produkt].c  + C_flow_product;

   Nr  := -C_flow_educt*(1/CN[Edukt].v-E.v/CN[Produkt].v);

   C_flow := C_flow_educt;
end;


procedure TSoilMin.CreateAll;
var
  schicht : integer;
  value   : real;
  Process : Processes;

begin
  inherited;
  ParCreate('CN_dpm', '[-]',cn_dpm, cn[dpm]);
  ParCreate('CN_rpm', '[-]',cn_rpm, cn[rpm]);
  ParCreate('CN_som', '[-]',cn_som, cn[som]);
  ParCreate('CN_biom', '[-]',cn_biom, cn[biom]);
  ParCreate('f_biom', '[-]', 0.001, f_biom);
  ParCreate('Km_Nmin', '[-]', 1, Km_Nmin);

  ParCreate('NOrgLayers', '[]',MAxNorgLayers, NOrgLayers);
  ParCreate('kBBf', '[1/d]', 0.05, kBBf);


  ParCreate('OrgDepth','[cm]',30, OrgDepth);
  ParCreate('ini.Lagerungsdichte', '[g/cm3]', 1.3, iLagerungsdichte);
  VarCreate('act.Lagerungsdichte', '[g/cm3]', 1.3, false, Lagerungsdichte);
  ParCreate('Humusgehalt', '[-]',0.018, Humusgehalt);
  ParCreate('MinNmin', '[-]',2., MinNmin);
  value := 0.0;
  StateCreate('C_ges', '[kg C/ha]', 0, false, C_ges);
  VarCreate('N_ges', '[kg N/ha]', value, false, N_ges);
  VarCreate('NBilanz', '[kg N/ha]', value, false, NBilanz);

  ExternVCreate( 'Temp', '[°C]', StateField, Temp);
  for schicht := 1 to trunc(NOrgLayers.v) do
    if schicht < 10
      then ExternVCreate('WG_'+IntToStr(schicht), '[cm3.cm3]',StateField, Theta_Array[Schicht])
      else ExternVCreate('WG'+IntToStr(schicht), '[cm3.cm3]',StateField, Theta_Array[Schicht]);


  VarCreate('f_abiot0', '[-]',1.0, false, f_abiot[0]);
  VarCreate('Net_min0', '[kg N.ha-1.d-1]',  0.0, false, Net_min[0]);


  for schicht := 0 to trunc(NOrgLayers.v) do
    VarCreate('f_Nmin'+IntToStr(Schicht), '[-]',1.0, false, f_Nmin[schicht]);

  for schicht := 1 to trunc(NOrgLayers.v) do begin
    VarCreate('f_abiot'+IntToStr(Schicht), '[-]',1.0, false, f_abiot[schicht]);
    StateCreate('BBf'+IntToStr(Schicht), '[]', 1, true, BBf[schicht]);
    VarCreate('Net_min'+IntToStr(Schicht), '[kg N.ha-1.d-1]',  0.0, false, Net_min[schicht]);
    ExternVCreate('Netmin_'+IntToStr(Schicht), '[kg N.ha-1.d-1]',  rateField, NetminE[schicht]);
    ExternVCreate('Nmin_'+IntToStr(Schicht), '[kg N.ha-1]',  StateField, Nmin_array[schicht]);
    ParCreate('Layerfactor_'+IntToStr(Schicht), '[-]',1, Layerfactor[schicht]);
    ParCreate('C_frac'+IntToStr(Schicht), '[-]', 1/trunc(NOrgLayers.v), C_frac[schicht]);

  end;


  StateCreate('C_ER', '[kg C/ha]', 0.1, true, C_ER);
  StateCreate('N_ER', '[kg N/ha]', 0.01, true, N_ER);

  VarCreate('F_DPM', '[-]', Value, true, F_dpm);

  VarCreate('SumMinr', '[kg N/ha]', 0.0, false, SumMinr);
  VarCreate('Net_ming', '[kg N.ha-1.d-1]', 0.0, false, Net_Ming);

  for schicht := 0 to trunc(NOrgLayers.v) do begin
    for Process := low(processes) to high(processes) do begin
      MinProcesses[schicht, process] := TMinProcess.create;
      Case process of
        dpm_biom : VarCreate('NetMin_'+'dpm_biom_'+InttoStr(schicht), '[kg N/ha*d]', value, false, NetMinArr[process, schicht]);
        rpm_biom : VarCreate('NetMin_'+'rpm_biom_'+InttoStr(schicht), '[kg N/ha*d]', value, false, NetMinArr[process, schicht]);
        som_biom : VarCreate('NetMin_'+'som_biom_'+InttoStr(schicht), '[kg N/ha*d]', value, false, NetMinArr[process, schicht]);
        biom_som : VarCreate('NetMin_'+'biom_som_'+InttoStr(schicht), '[kg N/ha*d]', value, false, NetMinArr[process, schicht]);
      end;
      Case process of
        dpm_biom : VarCreate('Cflow_'+'dpm_biom_'+InttoStr(schicht), '[kg C/ha*d]', value, false, CflowArr[process, schicht]);
        rpm_biom : VarCreate('Cflow_'+'rpm_biom_'+InttoStr(schicht), '[kg C/ha*d]', value, false, CflowArr[process, schicht]);
        som_biom : VarCreate('Cflow_'+'som_biom_'+InttoStr(schicht), '[kg C/ha*d]', value, false, CflowArr[process, schicht]);
        biom_som : VarCreate('Cflow_'+'biom_som_'+InttoStr(schicht), '[kg C/ha*d]', value, false, CflowArr[process, schicht]);
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

  StateCreate('C_RPM', '[kg C/ha]', value, true, CPool[RPM]);
  VarCreate('N_RPM', '[kg N/ha]', value, false, NPool[RPM]);

  StateCreate('C_SOM', '[kg C/ha]', value, true, CPool[SOM]);
  VarCreate('N_SOM', '[kg N/ha]', 0.0, false, NPool[SOM]);

  StateCreate('C_BIOM', '[kg C/ha]', value, true, CPool[BIOM]);
  VarCreate('N_BIOM', '[kg N/ha]', 0, true, NPool[BIOM]);

  VarCreate('C_org', '[kg N/ha]', value, false, Corg);
  VarCreate('N_org', '[kg N/ha]', value, false, Norg);


  for schicht := 0 to trunc(NOrgLayers.v) do begin
    StateCreate('C_DPM_'+IntToStr(Schicht), '[kg C/ha]',
                 0.0, false, CPool_i[schicht, dpm]);
    VarCreate('N_DPM_'+IntToStr(Schicht), '[kg N/ha]', CPool_i[schicht, dpm].v/CN[DPM].v, false, NPool_i[schicht, dpm]);

    StateCreate('C_rpm_'+IntToStr(Schicht), '[kg C/ha]',
                 0.0, false, CPool_i[schicht, rpm]);
    VarCreate('N_rpm_'+IntToStr(Schicht), '[kg N/ha]', CPool_i[schicht, rpm].v/CN[rpm].v, false, NPool_i[schicht, rpm]);

    StateCreate('C_som_'+IntToStr(Schicht), '[kg C/ha]',
                 0.0, false, CPool_i[schicht, som]);
    VarCreate('N_som_'+IntToStr(Schicht), '[kg N/ha]',  0.0, false, NPool_i[schicht, som]);

    StateCreate('C_Biom_'+IntToStr(Schicht), '[kg C/ha]',
                 0.0, false, CPool_i[schicht, Biom]);
    VarCreate('N_Biom_'+IntToStr(Schicht), '[kg N/ha]', 0.0, false, NPool_i[schicht, Biom]);

  end;
  OptCreate('c_distributionmethod', 'even', c_distributionmethod);
  c_distributionmethod.OptionList.Add('even');
  c_distributionmethod.OptionList.Add('user specific');

  OptCreate('ResidueIncorp', 'InSoil', ResidueIncorp);
  ResidueIncorp.OptionList.Add('InSoil');
  ResidueIncorp.OptionList.Add('OnTop');



end;



procedure TSoilMin.BeforeDestruction;

var
  schicht : integer;
  Process : Processes;

begin
  for schicht := 0 to trunc(NOrgLayers.v) do
    for Process := low(processes) to high(processes) do
       FreeandNil(MinProcesses[schicht, process]);
  inherited;
end;


procedure TSoilMin.Init(Var GlobMod: TMod);

var
  schicht : integer;
  Pool    : Pools;
  c_frac_control : real;

begin
  inherited Init(GlobMod);
  if c_distributionmethod.Option = 'even' then begin // default option, calculates fractions evenly distributed between all organic soil layers
    for schicht := 1 to trunc(NorgLayers.v) do
      c_frac[schicht].v := 1/trunc(NorgLayers.v);
    for schicht := trunc(NorgLayers.v)+1 to MAxNOrgLayers do
      c_frac[schicht].v := 0.0;
   end;

  c_frac_control := 0;    // if not overwritten by previous routine, fractions from inifile are used and a control variable is calculated here
  for schicht := 1 to trunc(NorgLayers.v) do
    c_frac_control := c_frac_control+c_frac[schicht].v;
  if (c_frac_control > (1+1e-5)) or (c_frac_control < (1-1e-5))
    then showmessage('Error in fractioning of organic matter between layers!');


  C_ges.v := 0.5*Orgdepth.v/100*1e4*1000*ILagerungsdichte.v*Humusgehalt.v;
  N_ges.v := C_ges.v/CN[som].v;

  for schicht := 1 to trunc(NOrgLayers.v) do begin
    Net_Min[schicht].v := 0.0;
    f_abiot[schicht].v := 1.0;
    BBf[schicht].v     := 1.0;
  end;

  if C_er.v > 0.0 then

    f_dpm.v := (-N_ER.v*CN[DPM].v*CN[RPM].v/C_ER.v+CN[DPM].v)/(-CN[RPM].v+CN[DPM].v)
  else
    f_dpm.v := 0.0;


  SumMinr.v := 0.0;
  Net_Ming.v := 0.0;

    CPool[dpm].v := 0.0; // set sum to zero
    CPool[rpm].v := 0.0; // set sum to zero

    for schicht := 1 to trunc(NOrgLayers.v) do begin
        CPool[dpm].v := CPool[dpm].v+CPool[dpm].v;   // if 'historic' residues are present they are added first to the total sums
        CPool[rpm].v := CPool[rpm].v+CPool[rpm].v;   // if 'historic' residues are present they are added first to the total sums
    end;



  CPool[dpm].v := CPool[dpm].v+C_ER.v*F_DPM.v;             // total pools for all layers
  NPool[dpm].v :=  CPool[dpm].v/CN[DPM].v;
  CPool[RPM].v := CPool[rpm].v+C_ER.v*(1-F_DPM.v);
  NPool[RPM].v := CPool[RPM].v/CN[RPM].v;
  CPool[SOM].v := C_ges.v*(1-f_BIOM.v);
  NPool[SOM].v := CPool[SOM].v/CN[SOM].v;
  CPool[BIOM].v := C_ges.v*f_BIOM.v;
  NPool[BIOM].v := CPool[BIOM].v/CN[BIOM].v;


  If lowercase(ResidueIncorp.Option) = 'insoil' then  begin

  for schicht := 1 to trunc(NOrgLayers.v) do begin
    for Pool := dpm to som do begin
      CPool_i[schicht, Pool].v := CPool[Pool].v*c_frac[Schicht].v;
      NPool_i[schicht, Pool].v := CPool_i[schicht, Pool].v/CN[Pool].v;
    end;
  end;
  end;

  If lowercase(ResidueIncorp.Option) = 'ontop' then begin
    for Pool := dpm to rpm do begin
      CPool_i[0, Pool].v := CPool[Pool].v;
      NPool_i[0, Pool].v := CPool_i[0, Pool].v/CN[Pool].v;
    end;
    for schicht := 1 to trunc(NOrgLayers.v) do begin
      for Pool := biom to som do begin
        CPool_i[schicht, Pool].v := CPool[Pool].v*c_frac[Schicht].v;
        NPool_i[schicht, Pool].v := CPool_i[schicht, Pool].v/CN[Pool].v;
       end;
    end;

  end;



  for schicht := 0 to trunc(NOrgLayers.v) do begin
    MinProcesses[Schicht, dpm_biom].init('dpm_biom', k_dpm_biom, E_dpm_biom, dpm, biom);
    MinProcesses[schicht, rpm_biom].init('rpm_biom', k_rpm_biom, E_rpm_biom, rpm, biom);
    MinProcesses[schicht, som_biom].init('som_biom', k_som_biom, E_som_biom, som, biom);
    MinProcesses[schicht, biom_som].init('biom_som', k_biom_som, E_biom_som, biom, som);
  end;

end;


procedure TSoilMin.AddResidues(Carbon, nitrogen: real);

begin
  if Carbon > 0.0 then

    f_dpm.v := (-Nitrogen*CN[DPM].v*CN[RPM].v/Carbon+CN[DPM].v)/(-CN[RPM].v+CN[DPM].v)
  else
    f_dpm.v := 0.0;

  CPool_i[0, DPM].v := CPool_i[0, DPM].v+Carbon*F_DPM.v;
  NPool_i[0, DPM].v := NPool_i[0, DPM].v+CPool_i[0, dpm].v/CN[DPM].v;
  CPool_i[0, RPM].v := CPool_i[0, RPM].v+Carbon*(1-F_DPM.v);
  NPool_i[0, RPM].v := NPool_i[0, RPM].v+CPool_i[0, rpm].v/CN[rPM].v;



  CPool[dpm].v := CPool[dpm].v + Carbon*F_DPM.v;
  NPool[dpm].v := NPool[dpm].v + CPool[dpm].v/CN[DPM].v;
  CPool[RPM].v := CPool[RPM].v + Carbon*(1-F_DPM.v);
  NPool[RPM].v := NPool[RPM].v + CPool[RPM].v/CN[RPM].v;

end;


procedure TSoilMin.MixLayers(depth: real);

var
  n_layers, schicht : byte;
  CPoolav, NPoolav : array[pools] of real;
  Pool : pools;

begin

  n_layers := trunc(depth/10);
  If (depth>2) and (N_layers<1)
    then N_layers := 1;
  If N_layers<1 then exit;

  for Pool := low(pools) to high(pools) do begin    // set to zero
    CpoolAv[pool] := 0.0;
    NPoolAv[pool] := 0.0;
  end;

  for schicht := 0 to N_layers do begin           // sum all pools incl. litter layer
    for Pool := low(pools) to high(pools) do begin
      Cpoolav[pool] := cpoolav[pool] + CPool_i[schicht, Pool].v;
      NPoolav[pool] := NPoolav[pool] + NPool_i[schicht, Pool].v;
    end;
  end;

  for Pool := low(pools) to high(pools) do begin  // calculate average for soil layers
    CpoolAv[pool] := CpoolAv[pool]/n_layers;
    NPoolAv[pool] := NPoolAv[pool]/n_layers;
  end;

  for schicht := 1 to N_layers do begin                    // sum all pools
    for Pool := low(pools) to high(pools) do begin
      CPool_i[schicht, Pool].v := Cpoolav[pool];
      NPool_i[schicht, Pool].v := NPoolav[pool];
    end;
  end;

  for Pool := low(pools) to high(pools) do begin   // Litter layer is empty!!
    CPool_i[0, Pool].v := 0.0;
    CPool_i[0, Pool].c := 0.0;
    NPool_i[0, Pool].v := 0.0;
  end;


end;

procedure TSoilMin.calcrates;


var
  Pool : Pools;
  Procs : processes;
  schicht : integer;

begin
 if fplantmodel <> nil then begin     // if the soil mineralisation model is linked with a descendant of abstract plant
   AddResidues(fplantmodel.C_Residues.v*10, fplantmodel.N_Residues.v*10);  //Factor 10 to convert from g/m2 to kg/ha
   Fplantmodel.C_Residues.v := 0.0;
   fPlantModel.N_Residues.v := 0.0;
 end;

 for schicht := 0 to trunc(NOrgLayers.v) do begin   // set all change rates to zero
   Net_min[schicht].v := 0.0;
   for Pool :=  low(pools) to high(pools) do
     CPool_i[Schicht, pool].c := 0.0;
 end;    

   for Pool :=  low(pools) to high(pools) do   // set all change rates to zero
     CPool[pool].c := 0.0;

    Net_ming.v := 0.0;                         // set net mineralisation to zero

//    f_abiot[0].v := 0.1; // 10% in der auflageschicht
    f_abiot[0].v := 0.5*Min_red_f( theta_array[1].v, temp.v, 1.5);      // provisionally set factor for litter layer to 50% of value in first soil layer
//    Net_min[1].v := 0.0;    // Auflageschichtmineralisation wird in erste Schicht gesteckt, daher hier rücksetzen
      for Procs := low(processes) to high(processes) do begin
          MinProcesses[0, Procs].Calculate(f_abiot[0].v, f_Nmin[0].v, CN, CPool_i[0], NPool_i[0], false);
          NetMinArr[procs, 0].v := MinProcesses[0, Procs].nr;
          CflowArr[procs, 0].v := MinProcesses[0, Procs].c_flow;
          Net_min[0].v := Net_min[0].v+MinProcesses[0, Procs].nr;     // Mineralisation wird in die erste Bodenschicht gesteckt !
      end;
      Net_ming.v := Net_ming.v + Net_min[0].v;


    for schicht := 1 to trunc(NOrgLayers.v) do begin
      f_Nmin[schicht].v := min(1,max(0, (NMin_Array[schicht].v-MinNmin.v)/((NMin_Array[schicht].v-MinNmin.v)+km_Nmin.v)));   // michalis-menten like factor to decrease mineralisation under nitrate shortage
      if fSoilHeatmodel = nil then
        f_abiot[schicht].v := Min_red_f(theta_array[schicht].v, temp.v, 1.5)*BBf[schicht].v*Layerfactor[schicht].v
      else
        f_abiot[schicht].v := Min_red_f(theta_array[schicht].v, fSoilHeatModel.temp[schicht].v, 1.5)*BBf[schicht].v*Layerfactor[schicht].v;


      If schicht > 1 then
        Net_min[schicht].v := 0.0;      // In Schicht 1 ist schon die Auflageschicht berücksichtigt, daher kein rücksetzen auf 0
      for Procs := DPM_biom to biom_som do begin
          MinProcesses[schicht, Procs].Calculate(f_abiot[schicht].v, f_Nmin[schicht].v, CN, CPool_i[Schicht], NPool_i[Schicht], false);
          NetMinArr[procs, schicht].v := MinProcesses[schicht, Procs].nr;
          CflowArr[procs, schicht].v := MinProcesses[schicht, Procs].c_flow;
          Net_min[schicht].v := Net_min[schicht].v+MinProcesses[schicht, Procs].nr;
      end;
      Net_ming.v := Net_ming.v + Net_min[schicht].v;

// Wenn die Festlegung größer als der Nmin-Vorrate sein sollte muß die Mineralisationsrate verringert werden !!!

      If ((Net_min[schicht].v*GlobTime.c + NMin_Array[schicht].v) < MinNmin.v) and (Net_min[schicht].v <0)then begin

//  zurücksetzen der Mineralisationsrate
        Net_ming.v := Net_ming.v - Net_min[schicht].v;

// zurücksetzen der C-Mengen Änderungen
        for Pool :=  DPM to SOM do
          CPool_i[Schicht, pool].c := 0.0;
        Net_min[schicht].v := 0.0;
        for Procs := DPM_biom to biom_som do begin
// Setze alle Nitratverbrauchenden Umsetzungen auf Null !
         // If MinProcesses[Schicht,Procs].nr<0.0 then
            MinProcesses[schicht, Procs].Calculate(f_abiot[schicht].v, f_nmin[schicht].v, CN, CPool_i[Schicht], NPool_i[Schicht], true);
            NetMinArr[procs, schicht].v := MinProcesses[schicht, Procs].nr;
            CflowArr[procs, schicht].v := MinProcesses[schicht, Procs].c_flow;
            NetMinArr[procs, schicht].v := MinProcesses[schicht, Procs].nr;

          Net_min[schicht].v := Net_min[schicht].v+MinProcesses[schicht, Procs].nr;
        end; // loop procs
        Net_ming.v := Net_ming.v + Net_Min[schicht].v;
      end; // end
    end;     // End of Loop over layers
    Net_min[1].v := Net_min[1].v + Net_min[0].v;
    Net_min[0].v := 0.0;
    SumMinr.v := SumMinr.v+Net_ming.v*GlobTime.c;

  For Pool :=  DPM to SOM do begin
    CPool[Pool].c := 0.0;
    for schicht := 0 to trunc(NOrgLayers.v) do begin      // sum up all carbon change rates over soil layers
     //  If (-CPool_i[schicht, Pool].c*GlobTime.c) > CPool_i[schicht, Pool].v then
     //    CPool_i[schicht,Pool].c := -0.95*CPool_i[schicht, Pool].v/GlobTime.c;        //5% sollen mindestens im Pool bleiben
       CPool[Pool].c := CPool[Pool].c + CPool_i[schicht, Pool].c;

    end;
  end;

  for schicht := 1 to trunc(Norglayers.v) do                // Decrease of tillage factor
    BBf[schicht].c := -max(0, BBf[schicht].v-1)*kBBf.v;

  For schicht := 1 to trunc(Norglayers.v) do      // set mineralisation rate in linked transport model
    NetMinE[Schicht].f_v^ := Net_min[Schicht].v;


end;


procedure TSoilMin.integrate;

//const


var
  schicht : integer;
  pool : pools;

begin
  inherited integrate;
  NsummeAlt := NSumme;
  NSumme := 0.0;
  for Pool := low(pools) to high(pools) do begin
    NPool[Pool].v := CPool[Pool].v/CN[Pool].v;
    Nsumme := Nsumme + NPool[pool].v;
    for schicht := 0 to trunc(NOrgLayers.v) do
      NPool_i[schicht, Pool].v := CPool_i[schicht, Pool].v/CN[Pool].v;
  end;
  If NSummeAlt > 0.0 then
    NBilanz.v := (NSummeAlt-Nsumme)/globTime.C-Net_ming.V
  else
    NBilanz.v := 0.0;  
  N_ER.v := NPool[DPM].v+NPool[RPM].v;
  C_ER.v := CPool[DPM].v+CPool[RPM].v;
  Norg.v := 0.0;
  Corg.v := 0.0;
  for pool := low(pools) to high(pools) do begin
    Norg.v := Norg.v + NPool[pool].v;
    Corg.v := Corg.v + CPool[pool].v;
  end;  


end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSoilMin]);
end;



end.
