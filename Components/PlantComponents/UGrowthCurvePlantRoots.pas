unit UGrowthCurvePlantRoots; // Neue Komponente

interface

uses
  UState,
  UMod,
  UlayeredSoil,
  UGrowthCurvePlant,
  UAbstractPlant,
  classes;
const  MaxAgeCl = 500;
type



  TRootDepthgrowth = (linear, monomolecular);

  TGrowthCurvePlantRoots = class(TGrowthCurvePlant)

  private

    function WLD_z_t_f(z1, z2, t, //Zrmax, Zr0, Kz,
      SRLmax, SRL0, kL, ka: real): real;
  protected

    function GetWLD(Index: Integer): THumeNumEntity; override;

    function GetSumRootLength: THumeNumEntity; override;
    function GetSumRootLength_eff: THumeNumEntity; override;

  public
    Root_Matrix: array[1..Max_Comp, 1..MaxAgeCl] of real;
    n_age_cl: integer;

    ActiveDuration // time of root activity
      : Tpar;

    Wld_arr: TSoilVarArray; // Wurzellängendichten [cm.cm-3]

    WL_arr: TSoilVarArray; // Wurzellängen [cm.cm-2]

    EffWld_arr: TsoilVarArray; // effective root length density []
    effWL_arr: TSoilVarArray; // active root length [cm.cm-2]

    N_Rootcomp: TVar;

    Tiefe: TSoilExtArray;

    zr_0: TPar; // Wurzeltiefe zur Pflanzung / Aussaat [cm]
    zr_max: TPar; // maximale Wurzeltiefe [cm]

    WL_0: TPar; // Wurzellänge zur Pflanzung / Aussaat [cm]
    WL_max: TPar; // maximale Wurzellänge [cm]

    k_z, // Wachstumsratenparameter für Tiefenentwicklung [cm]
      k_Wl,
      K_a
      : Tpar;

    SRL, // Sum of root length [cm/cm2]
      SRL_eff, // Total root length of functional roots (cm.cm-2)

    zr: TVar; // Durchwurzelungstiefe [cm]
    depthgrowthOptStr: Toption;
    Opt_RootAgeing: TOption;
    depthgrowthchoice: TRootdepthgrowth;

    procedure CreateAll; override;

    procedure Init(var GlobMod: Tmod); override;

    procedure CalcRates; override;

  published

    property Par_zr0: TPar read zr_0 write zr_0;
    property Par_zrmax: TPar read zr_max write zr_max;
    property Par_kz: TPar read k_z write k_z;

    property Par_Wl0: TPar read Wl_0 write Wl_0;
    property Par_Wlmax: TPar read WL_max write WL_max;
    property Par_kWL: TPar read k_WL write k_WL;
    property Par_ActiveDuration: Tpar read ActiveDuration write ActiveDuration;
//property opt_rootdepthgrowthchoice read depthgrowthchoice write depthgrowthchoice;

  end;

procedure Register;

implementation

uses
  SysUtils, math;//, Dialogs;

{*************************************************************************}

{
Zweck

Funktion zur Berechnung der Wurzell„ngendichte in Abh„ngigkeit von der Tiefe

Parameter

Name        Inhalt                       Einheit      Typ

wld0        WLD bei z=0                  [cm/cm3]     I
a           Fitparameter                 [1/cm]       I
            bei 1/a ist WLD=0.63*WLD0
z           Tiefe unter GOF              [cm]         I

WLD_z_f     WLD in Tiefe z               [cm/cm3]     O

{*************************************************************************}

{*************************************************************************}

{
Zweck

Funktion zur Berechnung der mittleren Wurzellängendichte zwischen zwei
Tiefen z1 und z2 (z1 < z2) in Abhängigkeit von Zeit und Tiefe

Parameter

Name        Inhalt                       Einheit      Typ

z1          Tiefe 1                      [cm]         I
z2          Tiefe 2                      [cm]         I
t           Zeit                         [d]          I
Zrmax       maximale Durchwurzelungstiefe[cm]         I
zr0         Durchwurzelungstiefe bei t=0 [cm]         I
kz          Fitparameter                 [1/d]        I
SRLmax      maximale Wurzellänge         [cm/cm2]     I
            (1 cm/cm2 entspr. 0.1 km/m2)
SR0         Wurzellänge bei t=0          [cm/cm2]     I
kL          Fitparameter                 [1/d]        I
ka          Fitparameter                 [1/cm]       I
            bei 1/(ka*zr)ist WLD=0.63*WLD0

WLD_z_t_f   WLD zwischen z1 und z2 bei t [cm/cm3]     O

{*************************************************************************}

function monomo_f(Pmax, P0, k, t: real): real;

begin
  monomo_f := Pmax - (Pmax - P0) * exp(-k * t);
end;

function Logist_f(Wmax, W0, k, Tsum: real): real;

begin
  result := WMax / (1 + (WMAx / W0 - 1) * EXP(-TSum * k))

end;

function WLD_z_f(wld0, a, z: real): real;

begin
  WLD_z_f := wld0 * exp(-a * z);
end;

function TGrowthCurvePlantRoots.WLD_z_t_f(z1, z2, t, //Zrmax, Zr0, Kz,
  SRLmax, SRL0, kL, ka: real): real;

var
  SRL,
    WLD0,
    a: real;

begin
  

  if z1 > zr.v then begin
    WLD_z_t_f := 0.0;
    exit;
  end;
  if (z2 > zr.v) and (z1 <> zr.v) then
    z2 := zr.v;
//  a   := 1/(ka*zr.v);
  a := -ln(ka) / zr.v;
//  if a > zr.v then begin
//      showmessage('GrowthCurvePlantRoots, Objectname:'+self.name+ 'Par a>Zr.v');
//      halt;
//  end;
  SRL := logist_f(SRLmax, SRL0, kL, t);
  WLD0 := (SRL * a) / (1 - exp(-a * zr.v));
  wld_z_t_f := wld0 * (exp(-a * z1) - exp(-a * z2)) / (a * (z2 - z1));

end;

function TGrowthCurvePlantRoots.GetWLD(Index: Integer): THumeNumEntity;

begin
  result := wld_arr[index];

end;

function TGrowthCurvePlantRoots.GetSumRootLength: THumeNumEntity;

begin
  result := SRL;

end;

function TGrowthCurvePlantRoots.GetSumRootLength_eff: THumeNumEntity;

begin
  result := SRL_eff;
end;

procedure TGrowthCurvePlantRoots.createAll;
var
  i: integer;
begin
  inherited createAll;
  ParCreate('zr_0', '[cm]', 10, zr_0);
  ParCreate('zr_max', '[cm]', 120, zr_max);
  ParCreate('WL_0', '[cm]', 1, WL_0);
  ParCreate('WL_max', '[cm]', 15, WL_max);
  ParCreate('k_z', '[cm.d-1.°C]', 0.0009, k_z);
  ParCreate('k_WL', '[cm.d-1.°C]', 0.002, k_WL);
  ParCreate('k_a', '[-]', 0.01, k_a, 'Ratio of RLD at z=0 and RLD at z=zr');
  VarCreate('N_Rootcomp', '[n]', 20, true, N_Rootcomp);
  VarCreate('zr', '[cm]', 0, true, zr);
  Varcreate('SRL', '[cm.cm-2]', 0.0, false, SRL);
  Varcreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff);

  OptCreate('Rootdepthgrowth', 'Monomolecular', depthgrowthoptstr);
  depthgrowthoptstr.optionlist.Clear;
  depthgrowthoptstr.optionlist.Add('linear');
  depthgrowthoptstr.OptionList.Add('monomolecular');
  depthgrowthchoice := monomolecular;

  ParCreate('ActiveDuration', '[d]', 20, ActiveDuration);

  OptCreate('Opt_RootAgeing', 'false', Opt_RootAgeing);
  Opt_RootAgeing.optionlist.Add('false');
  Opt_RootAgeing.OptionList.Add('true');

  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate('WLD_' + ndx_str(i), '[cm.cm-3]', 0.0, false, WLD_arr[i]);
    VarCreate('WL_' + ndx_str(i), '[cm.cm-2]', 0.0, false, WL_arr[i]);
    VarCreate('effWLD_'+ndx_str(i), '[cm.cm-3]', 0.0, false, effWLD_arr[i]);
    VarCreate('effWL_' +ndx_str(i), '[cm.cm-3]', 0.0, false, effWL_arr[i]);
  end;
  for i := 0 to trunc(n_Rootcomp.v) do
    ExternVCreate('Tiefe' + ndx_Str(i), '[cm]', StateField, Tiefe[i]);

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := 0.0;
  end;

end;

procedure TGrowthCurvePlantRoots.Init(var GlobMod: TMod);
var
  i: integer;

begin
  inherited Init(GlobMod);
  if uppercase(depthgrowthoptstr.Option) = uppercase('linear') then
    depthgrowthchoice := linear;
  if uppercase(depthgrowthoptstr.Option) = uppercase('monomolecular') then
    depthgrowthchoice := monomolecular;

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := 0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;
  for i := 0 to trunc(n_Rootcomp.v) do Tiefe[i].Search := withRoots;

end;

procedure TGrowthCurvePlantRoots.CalcRates;

var
  i,j: integer;
  wl_alt, ActiveRL: real;

begin
  inherited;
  if (GlobTime.v >= SowingDate.v) and (GlobTime.v < HarvestDate.v) then begin
    SRL.v := 0.0;
    SRL_eff.v := 0.0;
    if depthgrowthchoice = monomolecular then
      zr.v := monomo_f(Zr_max.v, Zr_0.v, k_z.v, TSum.v);
    if depthgrowthchoice = linear then
      zr.v := min(zr_max.v, zr_0.v + Tsum.v * K_z.v);


    if withRoots then for i := 1 to trunc(n_Rootcomp.v) do begin

        if (Opt_RootAgeing.Option = 'true') then begin

          for j := N_age_cl downto 2 do
            Root_matrix[i, j] := Root_Matrix[i, j - 1];
          WL_alt := WLD_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);

          WLD_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, tiefe[i].v, TSum.v,
            //Zr_max.v, Zr_0.v, K_z.v,
            WL_max.v, WL_0.v, k_WL.v, k_a.v);

          Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);

          Root_Matrix[i, 1] := max(0, Wl_arr[i].v - wl_alt);
          ActiveRL := 0.0;
          for j := 1 to Trunc(ActiveDuration.v) do
            ActiveRL := ActiveRl + Root_matrix[i, j];

          effWL_arr[i].v := ActiveRL;
          SRL_eff.v := SRL_eff.v + ActiveRL;
          EffWLD_Arr[i].v := ActiveRL / (Tiefe[i].v - Tiefe[i - 1].v);

          SRL.v := SRL.v + WL_arr[i].v;
        end else begin

          WLD_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, tiefe[i].v, TSum.v,
            //Zr_max.v, Zr_0.v, K_z.v,
            WL_max.v, WL_0.v, k_WL.v, k_a.v);
          Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);
          SRL.v := SRL.v + WL_arr[i].v;
          SRL_eff.v := SRL_eff.v + WL_arr[i].v;
          EffWLD_Arr[i].v := WLD_arr[i].v;

        end;

      end;
  end;
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TGrowthCurvePlantRoots]);

{$ENDIF}

end;

end.

