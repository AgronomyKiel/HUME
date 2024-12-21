unit USimpleRootModNew; // Neue Komponente

interface

uses
  UState, UMod, IniFiles, UlayeredSoil, classes;

type

TSimpleRootModNew = class(TSubModel)

private

TempSumRootBaseTemp : TPar;  // Basistemperatur für Wurzelentwicklung

function WLD_z_t_f ( z1, z2: real): real;

procedure createAll; override;
protected

public

Wld_arr : TSoilVarArray;  // Wurzellängendichten [cm.cm-3]
WL_arr  : TSoilVarArray;  // Wurzellängen [cm.cm-2]

N_Rootcomp : TVar;

Tiefe : TSoilExtArray;

zr0    : TPar;           // Wurzeltiefe zur Pflanzung / Aussaat [cm]

k_za   : TPar;            // relative Wurzeltiefenwachstumsrate [cm.cm-1°Cd-1]
k_zb   : TPar;            // Wurzelwachstum je Grad-Tag im linearen Teil

WL_0    : TPar;           // Wurzellänge zur Pflanzung / Aussaat [cm]
WL_max  : TPar;           // maximale Wurzellänge [cm]

k_Wl,
ratio                     // Verhältnis WLD0 / WLDzr
 : Tpar;

zr : TVar;                // Durchwurzelungstiefe [cm]

TempSumR : TState;        // Temperatursumme für die Wurzelentwicklung
Temp     : TexternV;


constructor create( AOwner:TComponent); override;

procedure Init(var GlobMod: Tmod); override;

procedure CalcRates; override;

procedure Set_GlobMod(value:TMod); override;

published

property  Par_BaseTemp : TPar read TempSumRootBaseTemp write TempSumRootBaseTemp;
property  Par_zr0   : TPar read zr0  write zr0;
property  Par_kza   : TPar read k_za  write k_za;
property  Par_kzb   : TPar read k_zb  write k_zb;
property  Par_Ratio : TPar read Ratio write Ratio;

property Par_Wl0   : TPar read Wl_0 write Wl_0;
property Par_Wlmax : TPar read WL_max write WL_max;
property Par_kWL   : TPar read k_WL write k_WL;


end;

procedure Register;

implementation

uses
  SysUtils, math;

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

Funktion zur Berechnung der mittleren Wurzell„ngendichte zwischen zwei
Tiefen z1 und z2 (z1 < z2) in Abh„ngigkeit von Zeit und Tiefe


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


function monomo_f (Pmax, P0, k, t : real): real;

begin
  monomo_f := Pmax-(Pmax-P0)*exp(-k*t);
end;

function Logist_f(Wmax, W0, k, Tsum:real):real;

begin
  result :=   WMax/(1+(WMAx/W0-1)*EXP(-TSum*k))

end;


function WLD_z_f ( wld0, a, z: real): real;

begin
  WLD_z_f := wld0*exp(-a*z);
end;


function TSimpleRootModNew.WLD_z_t_f(z1, z2  : real): real;

var
  SRL,
  WLD0,
  a,
  TsumKrit,zrkrit   : real;


begin
  zrkrit := k_zb.v/k_za.v;
  TsumKrit := ln(zrkrit/zr0.v)/k_za.v;

  if zr.v < zrkrit then
    zr.v := zr0.v*exp(TempSumR.v*k_za.v)
  else
    zr.v := zrkrit+k_zb.v*(tempSumR.v-Tsumkrit);


  If z1>zr.v then begin
    WLD_z_t_f := 0.0;
    exit;
  end;
  If (z2>zr.v) and (z1<>zr.v) then z2 := zr.v;
  a   := -ln(Ratio.v)/zr.v;
 // if a > zr.v then halt;
  SRL := logist_f (WL_max.v, WL_0.v, k_wL.v, tempSumR.v);
  WLD0:= (SRL*a)/(1-exp(-a*zr.v));
  wld_z_t_f := wld0*(exp(-a*z1)-exp(-a*z2))/(a*(z2-z1));

end;

procedure TSimpleRootModNew.CreateAll;
var
  i : integer;

begin

  ParCreate('BaseTempRoots', '[°C]',0,TempSumRootBaseTemp);

  ParCreate('zr_0', '[cm]', 6.04,    zr0);
  ParCreate('K_za', '[cm.cm-1.°C*d-1]', 0.00394, k_za);
  ParCreate('K_zb', '[cm.°C*d-1]', 0.107,   k_zb);
  ParCreate('Ratio', '[-]', 0.01731, Ratio);

  ParCreate('WL_0', '[cm]',    1,   WL_0);
  ParCreate('WL_max', '[cm]', 15, WL_max);
  ParCreate('k_WL', '[cm.d-1.°C]', 0.002, k_WL);

  VarCreate('N_Rootcomp', '[n]',  20, true, N_Rootcomp);
  VarCreate('zr', '[cm]',  0, true, zr);


  StateCreate('TempSumR', '[°C.d]', 0.0, false, TempSumR);
  TempSumR.ReadFromIniFile := false;
  ExternVcreate('Temp', '[°C]', stateField, temp);

  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate('WLD_'+IntToStr(i), '[cm.cm-3]', 0.0, false,WLD_arr[i]);
    VarCreate('WL_'+IntToStr(i), '[cm.cm-2]', 0.0, false,WL_arr[i]);
//    VarCreate('WInflux'+IntToStr(i), '[cm3.cm-1.d-1]', 0.0, false,W_influx[i]);

  end;
  for i := 0 to trunc(n_Rootcomp.v) do
      ExternVCreate('Tiefe'+IntToStr(i),'[cm]',StateField,Tiefe[i]);


  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
  end;


end;

constructor TSimpleRootModNew.create(AOwner:TComponent);
var
  i : integer;
begin
  inherited create(AOwner);
  createAll;
end;


procedure TSimpleRootModNew.Set_GlobMod(value:TMod);
var
  i : integer;
begin
  inherited Set_GlobMod(Value);
  createAll;

end;

procedure TSimpleRootModNew.Init(Var GlobMod: TMod);
var
  i : integer;

begin
  inherited Init(GlobMod);
  TempsumR.V := 0.0;
  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;

end;

procedure TSimpleRootModNew.CalcRates;

var
  i : integer;

begin

  If Temp.v>TempSumRootBaseTemp.v then
    TempSumR.C := (Temp.v-TempSumRootBaseTemp.V)
  else TempSumr.c := 0.0;

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v := WLD_z_t_f ( Tiefe[i-1].v, tiefe[i].v);
    Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v-Tiefe[i-1].v);
  end;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSimpleRootModNew]);
end;

end.


