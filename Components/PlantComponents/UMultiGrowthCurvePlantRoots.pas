unit UMultiGrowthCurvePlantRoots;

interface

uses
  UState, UMod, IniFiles, UlayeredSoil, UAbstractPlant, UMultiGrowthCurvePlant,
  classes, Math, UGrowthCurvePlant;

const
  MaxAgeCl = 500;
  growth_count = 5;

type

  TRootDepthgrowth = (linear, monomolecular);

  TMultiGrowthCurvePlantRoots = class(TMultiGrowthCurvePlant)

  private
    function WLD_z_t_f(z1, z2, t, Zrmax, Zr0, Kz,
      SRLmax, SRL0, kL, ka: double): double;
  protected
    function GetWLD(Index: Integer): THumeNumEntity; override;
    function GetSumRootLength: THumeNumEntity; override;
    function GetSumRootLength_eff: THumeNumEntity; override;
  public

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

    ActiveDuration // time of root activity
      : Tpar;

    Root_Matrix: array[1..Max_Comp, 1..MaxAgeCl] of double;
    n_age_cl: integer;

    SRL, // Sum of root length [cm/cm2]
      SRL_eff, // Total root length of functional roots (cm.cm-2)

    zr: TVar; // Durchwurzelungstiefe [cm]
    depthgrowthOptStr: Toption;
    depthgrowthchoice: TRootdepthgrowth;

    aufwuechse_zr_0,
      aufwuechse_zr_max,
      aufwuechse_WL_0,
      aufwuechse_WL_max,
      aufwuechse_k_z,
      aufwuechse_k_WL,
      aufwuechse_k_a,
      aufwuechse_b: array[0..growth_count] of TPar;

    wl_max_var: array[0..20] of Double;

    periode: Integer;

    aufwuechse_N_Rootcomp, aufwuechse_zr,
      aufwuechse_SRL, aufwuechse_SRL_eff: array[0..growth_count] of TVar;

    procedure CreateAll; override;
    procedure Init(var GlobMod: Tmod); override;
    procedure CalcRates; override;

  published

    property Par_zr0: TPar read zr_0 write zr_0;
    property Par_zrmax: TPar read zr_max write zr_max;
    property Par_kz: TPar read k_z write k_z;
    property Par_ActiveDuration: Tpar read ActiveDuration write ActiveDuration;
    property Par_Wl0: TPar read Wl_0 write Wl_0;
    property Par_Wlmax: TPar read WL_max write WL_max;
    property Par_kWL: TPar read k_WL write k_WL;
  end;

procedure Register;

implementation

uses
  SysUtils, vcl.Dialogs;

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

function monomo_f(Pmax, P0, k, t: double): double;
begin
  result := Pmax - (Pmax - P0) * exp(-k * t);
end;

function Logist_f(Wmax, W0, k, Tsum: double): double;
begin
  if W0 = 0 then
    showmessage('W0 = ' + floattostr(W0));
  result := WMax / (1 + (WMAx / W0 - 1) * EXP(-TSum * k))
end;

function WLD_z_f(wld0, a, z: double): double;
begin
  result := wld0 * exp(-a * z);
end;

function TMultiGrowthCurvePlantRoots.WLD_z_t_f(z1, z2, t, Zrmax, Zr0, Kz,
  SRLmax, SRL0, kL, ka: double): double;
var
  SRL, WLD0, a: double;
begin

  if depthgrowthchoice = monomolecular then begin
    zr.v := monomo_f(Zrmax, Zr0, kz, t);
  end;

  if depthgrowthchoice = linear then
    zr.v := min(zrmax, zr0 + Tsum.v * Kz);

  if z1 > zr.v then begin
    result := 0.0;
  end else begin
    if (z2 > zr.v) and (z1 <> zr.v) then z2 := zr.v;
    a := -ln(ka) / zr.v;

    if a = 0 then
      result := 0
    else begin
      SRL := logist_f(SRLmax, SRL0, kL, t);
      WLD0 := (SRL * a) / (1 - exp(-a * zr.v));
      result := wld0 * (exp(-a * z1) - exp(-a * z2)) / (a * (z2 - z1));
    end;
  end
end;

function TMultiGrowthCurvePlantRoots.GetWLD(Index: Integer): THumeNumEntity;
begin
  result := effwld_arr[index];
end;

procedure TMultiGrowthCurvePlantRoots.createAll;
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
  ParCreate('k_a', '[-]', 0.42, k_a);
  ParCreate('ActiveDuration', '[d]', 20, ActiveDuration);
  VarCreate('N_Rootcomp', '[n]', 20, true, N_Rootcomp);
  VarCreate('zr', '[cm]', 0, true, zr);
  Varcreate('SRL', '[cm.cm-2]', 0.0, false, SRL);
  Varcreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff);

  for i := 0 to growth_count do begin
    ParCreate('aufwuchs_' + IntToStr(i) + '_zr_0', '[cm]', 10,
      aufwuechse_zr_0[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_zr_max', '[cm]', 120,
      aufwuechse_zr_max[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_WL_0', '[cm]', 1,
      aufwuechse_WL_0[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_WL_max', '[cm]', 15,
      aufwuechse_WL_max[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_k_z', '[cm.d-1.°C]', 0.0009,
      aufwuechse_k_z[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_k_WL', '[cm.d-1.°C]', 0.002,
      aufwuechse_k_WL[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_k_a', '[-]', 0.42,
      aufwuechse_k_a[i]);
    ParCreate('aufwuchs_' + IntToStr(i) + '_b', '[-]', 1, aufwuechse_b[i]);
    VarCreate('aufwuchs_' + IntToStr(i) + '_N_Rootcomp', '[n]', 20, true,
      aufwuechse_N_Rootcomp[i]);
    VarCreate('aufwuchs_' + IntToStr(i) + '_zr', '[cm]', 0, true,
      aufwuechse_zr[i]);
  end;

  OptCreate('Rootdepthgrowth', 'Monomolecular', depthgrowthoptstr);
  depthgrowthoptstr.optionlist.Clear;
  depthgrowthoptstr.optionlist.Add('linear');
  depthgrowthoptstr.OptionList.Add('monomolecular');
  depthgrowthchoice := monomolecular;

  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate('WLD_' + IntToStr(i), '[cm.cm-3]', 0.0, false, WLD_arr[i]);
    VarCreate('WL_' + IntToStr(i), '[cm.cm-2]', 0.0, false, WL_arr[i]);
    VarCreate('effWLD_' + IntToStr(i), '[cm.cm-3]', 0.0, false, effWLD_arr[i]);
    VarCreate('effWL_' + IntToStr(i), '[cm.cm-3]', 0.0, false, effWL_arr[i]);
  end;
  for i := 0 to trunc(n_Rootcomp.v) do
    ExternVCreate('Tiefe' + IntToStr(i), '[cm]', StateField, Tiefe[i]);

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := 0.0;
  end;

end;

procedure TMultiGrowthCurvePlantRoots.Init(var GlobMod: TMod);
var
  i, j: integer;
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
  periode := 0;

  for i := 1 to max_Comp do
    for j := 1 to MaxAgeCl do
      Root_matrix[i, j] := 0.0;
  n_age_cl := 0;

end;

procedure TMultiGrowthCurvePlantRoots.CalcRates;
var
  i, j: integer;
  day, month, year1, day_h, month_h, year_h: Word;
  wl_alt, ActiveRL: double;
begin
  inherited;
  if (AnsiLowerCase(with_multiple_aufwuechse.Option) <> 'ja') then begin

    if (harvestdate_var < GlobTime.v) then begin
      SRL.v := 0.0;
      SRL_eff.v := 0.0;
      zr.v := 0.0;
      for i := 1 to trunc(n_Rootcomp.v) do begin
        Wl_arr[i].v := 0.0;
        Wld_arr[i].v := 0.0;
      end;
      Exit;
    end;
  end;

  if (AnsiLowerCase(with_multiple_aufwuechse.Option) = 'ja') then begin

    DecodeDate(GlobMod.Time.v, Year1, Month, Day);
    DecodeDate(harvestdates[0].v, year_h, month_h, day_h);

    if ((GlobMod.Time.v < SowingDate_var) or (GlobMod.Time.v > HarvestDate.v))
      then begin
      SRL.v := 0.0;
      SRL_eff.v := 0.0;
      zr.v := 0.0;
      for i := 1 to trunc(n_Rootcomp.v) do begin
        Wl_arr[i].v := 0.0;
        WlD_arr[i].v := 0.0;
      end;
      Exit;
    end;

    for i := 0 to growth_count do begin
      if harvestdates[i].v = GlobTime.v then begin
        periode := i + 1 mod Length(harvestdates);
        Break;
      end;
    end;
  end;

  if ((GlobTime.v >= SowingDate_var) and
    (GlobTime.v < HarvestDate.v)) then begin

    inc(N_age_cl);
    SRL.v := 0.0;
    SRL_eff.v := 0.0;

    N_age_cl := Math.min(N_Age_cl, MaxAgeCl - 1);

    for i := 1 to trunc(n_Rootcomp.v) do begin

      for j := N_age_cl downto 2 do
        Root_matrix[i, j] := Root_Matrix[i, j - 1];

      WL_alt := WLD_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);

      if AnsiLowerCase(with_multiple_aufwuechse.Option) <> 'ja' then begin
        WLD_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, tiefe[i].v, TSum.v, Zr_max.v,
          Zr_0.v, K_z.v, WL_max.v, WL_0.v, k_WL.v, k_a.v);
      end else begin
        WLD_arr[i].v := WLD_z_t_f(Tiefe[i - 1].v, tiefe[i].v, TSum.v,
          aufwuechse_Zr_max[periode].v, aufwuechse_Zr_0[periode].v,
          aufwuechse_K_z[periode].v,
          aufwuechse_WL_max[periode].v, aufwuechse_WL_0[periode].v,
          aufwuechse_k_WL[periode].v, aufwuechse_k_a[periode].v);
      end;

      Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v - Tiefe[i - 1].v);

      Root_Matrix[i, 1] := max(0, Wl_arr[i].v - wl_alt);
      ActiveRL := 0.0;

      for j := 1 to Trunc(ActiveDuration.v) do
        ActiveRL := ActiveRl + Root_matrix[i, j];

      effWL_arr[i].v := ActiveRL;
      SRL_eff.v := SRL_eff.v + ActiveRL;
      EffWLD_Arr[i].v := ActiveRL / (Tiefe[i].v - Tiefe[i - 1].v);

      SRL.v := SRL.v + WL_arr[i].v;

    end;
  end;

end;

function TMultiGrowthCurvePlantRoots.GetSumRootLength: THumeNumEntity;
begin
  result := SRL;
end;

function TMultiGrowthCurvePlantRoots.GetSumRootLength_eff: THumeNumEntity;
begin
  result := SRL_eff;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TMultiGrowthCurvePlantRoots]);
end;

end.

