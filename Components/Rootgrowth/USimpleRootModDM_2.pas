unit USimpleRootModDM_2;

interface

uses
  UState, UMod, IniFiles, UlayeredSoil,
  classes, UModUtils, USimplePlant, UAbstractPlant;

const
  MaxAgeCl = 500;


type

TRootingdepthIncrease = (linear, expolinear);

TSimpleRootModDM_2 = class(TSubModel)

private

  //fPlantDMModel : TSimplePlant;
  OldDMFineRoot : real;
  RootDepthInc : TRootingdepthIncrease;
  TempSumRootBaseTemp : TPar;  // Basistemperatur für Wurzelentwicklung
  fName_WL : string;
  function WLD_z_t_f ( z1, z2: real): real;
  Procedure set_Name_WL(const Name_WL: string);
  //Procedure Set_PlantDMModel (const PlantDMModel : TSimplePlant);
  procedure createAll; override;

protected

public
  Wld_arr : TSoilVarArray;    // Wurzellängendichten [cm.cm-3]
  EffWld_arr : TsoilVarArray; // effective root length density []
  WL_arr  : TSoilVarArray;    // Wurzellängen [cm.cm-2]
  effWL_arr : TSoilVarArray;  // active root length [cm.cm-2]

  N_Rootcomp : TVar;

{WLD_0_15,
WLD_15_30,
WLD_30_45,
WLD_45_60,
WLD_60_75,
WLD_75_90,
WLD_90_105,
WLD_105_120}

  WLD_0_10,
  WLD_10_20,
  WLD_20_30,
  WLD_30_40,
  WLD_40_50,
  WLD_50_60,
  WLD_60_70,
  WLD_70_80,
  WLD_80_90,
  WLD_90_100 : TVar;

Root_Matrix : array[1..Max_Comp, 1..MaxAgeCl] of real;
n_age_cl    : integer;

Tiefe : TSoilExtArray;

zr0    : TPar;            // Wurzeltiefe zur Pflanzung / Aussaat [cm]

k_za   : TPar;            // relative Wurzeltiefenwachstumsrate [cm.cm-1°Cd-1]
k_zb   : TPar;            // Wurzelwachstum je Grad-Tag im linearen Teil
Zrmax   : TPar;            // maximale Wurzeltiefe [cm]

sp_RL                     // specific root length [cm/g DM]
,
ratio                     // Verhältnis WLD0 / WLDzr
,
ActiveDuration            // time of root activity
 : Tpar;

zr : TVar;                // rooting depth (cm)

TempSumR : TState;         // Temperatursumme für die Wurzelentwicklung
SRL,
SRL_eff : TVar;               // Total root length (cm.cm-2)

Temp,
DMFineRoot,         // Dry matter of fine roots (g/m2)

SowingDate, HarvestDate : TexternV;

constructor create( AOwner:TComponent); override;

procedure Init(var GlobMod: Tmod); override;

procedure CalcRates; override;

procedure Set_GlobMod(value:TMod); override;

published

property Var_SRL : TVar read SRL write SRL;
property Var_zr : TVar read zr write zr;

property  Par_BaseTemp : TPar read TempSumRootBaseTemp write TempSumRootBaseTemp;
property  Par_zr0   : TPar read zr0  write zr0;
property  Par_kza   : TPar read k_za  write k_za;
property  Par_kzb   : TPar read k_zb  write k_zb;
property  Par_Ratio : TPar read Ratio write Ratio;
property  Par_zrmax   : TPar read zrmax  write zrmax;

property Par_sp_WL   : TPar read sp_RL write sp_RL;

property Par_ActiveDuration : Tpar read ActiveDuration write ActiveDuration;

property Ex_Temp : TExternV read Temp write Temp;
property Ex_DMFineRoot : TExternV read DMFineRoot write DMFineRoot;
property Ex_SowingDate : TExternV read SowingDate write SowingDate;
property Ex_HarvestDate : TExternV read HarvestDate write HarvestDate;


property Opt_RootDepthInc : Trootingdepthincrease read RootDepthinc write Rootdepthinc;
property Name_Wl : string read fName_WL write Set_Name_WL;

//property PlantDMModel : TSimplePlant read fPlantDMModel write Set_PlantDMModel;

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


{*************************************************************************}
{Zweck
Funktion zur Berechnung der mittleren Wurzellängendichte zwischen zwei
Tiefen z1 und z2 (z1 < z2) in Abhängigkeit von Zeit und Tiefe

Parameter
Name        Inhalt                       Einheit      Typ
--------    ---------------------------  ---------    ----
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

function TSimpleRootModDM_2.WLD_z_t_f(z1, z2  : real): real;

var
  WLD0,
  a,
  TsumKrit,
  zrkrit   : real;

begin
  zrkrit := k_zb.v/k_za.v;
  TsumKrit := ln(zrkrit/zr0.v)/k_za.v;

  If (Zr.v <= Zrmax.v)  then begin
    If RootDepthInc = ExpoLinear then begin    {expolineare Zunahme der Wureltiefe}
      if zr.v < zrkrit then
        zr.v := zr0.v*exp(TempSumR.v*k_za.v)         {exponentieller Teil der Fkt}
      else
        zr.v := zrkrit+k_zb.v*(tempSumR.v-Tsumkrit); {linearer Teil der Fkt.}
    end else begin
      zr.v := zr0.v+k_zb.v*tempSumR.v;         {lineare Zunahme der Wurzeltiefe}
    end;
  end;
  OldDMFineRoot := DMFineRoot.v;

  If z1>zr.v then begin
                  {Wurzeltiefe hat obere Grenze der Bodenschicht nicht erreicht}
    WLD_z_t_f := 0.0;
    exit;
  end;
  If (z2>zr.v) and (z1<>zr.v) then z2 := zr.v;
                 {Wurzeltiefe hat untere Grenze der Bodenschicht nicht erreicht}
  a   := -ln(Ratio.v)/zr.v;                              {Habil Kage: Gl. 10-9}
 // if a > zr.v then halt;

  SRL.v := DMFineRoot.v*sp_RL.v/1e4;

  WLD0:= (SRL.v*a)/(1-exp(-a*zr.v));                     {Habil Kage: Gl. 10-10}
  wld_z_t_f := wld0*(exp(-a*z1)-exp(-a*z2))/(a*(z2-z1)); {Habil Kage: Gl. 10-11}
end;

procedure TSimpleRootModDM_2.CreateAll;
var
  i : integer;

begin

  ParCreate('BaseTempRoots', '[°C]',0,TempSumRootBaseTemp);

  ParCreate('zr_0',  '[cm]', 6.04,    zr0);
  ParCreate('K_za',  '[cm.cm-1.°C*d-1]', 0.00394, k_za);
  ParCreate('K_zb',  '[cm.°C*d-1]', 0.107,   k_zb);
  ParCreate('Ratio', '[-]', 0.01731, Ratio);
  ParCreate('Zrmax', '[-]', 160, Zrmax);

  ParCreate('sp_WL', '[cm.g DM-1]',    7000,   sp_RL);
  ParCreate('ActiveDuration', '[d]',    20,   ActiveDuration);

  VarCreate('N_Rootcomp', '[n]',  20, true, N_Rootcomp);
  VarCreate('zr', '[cm]',  0, true, zr);

 { VarCreate('WLD_0_15', '[cm.cm-3]',  0, false, WLD_0_15);
  VarCreate('WLD_15_30', '[cm.cm-3]',  0, false, WLD_15_30);
  VarCreate('WLD_30_45', '[cm.cm-3]',  0, false, WLD_30_45);
  VarCreate('WLD_45_60', '[cm.cm-3]',  0, false, WLD_45_60);
  VarCreate('WLD_60_75', '[cm.cm-3]',  0, false, WLD_60_75);
  VarCreate('WLD_75_90', '[cm.cm-3]',  0, false, WLD_75_90);
  VarCreate('WLD_90_105', '[cm.cm-3]',  0, false, WLD_90_105);
  VarCreate('WLD_105_120', '[cm.cm-3]',  0, false, WLD_105_120);}
  VarCreate('WLD_10', '[cm.cm-3]',  0, false, WLD_0_10);
  VarCreate('WLD_20', '[cm.cm-3]',  0, false, WLD_10_20);
  VarCreate('WLD_30', '[cm.cm-3]',  0, false, WLD_20_30);
  VarCreate('WLD_40', '[cm.cm-3]',  0, false, WLD_30_40);
  VarCreate('WLD_50', '[cm.cm-3]',  0, false, WLD_40_50);
  VarCreate('WLD_60', '[cm.cm-3]',  0, false, WLD_50_60);
  VarCreate('WLD_70', '[cm.cm-3]',  0, false, WLD_60_70);
  VarCreate('WLD_80', '[cm.cm-3]',  0, false, WLD_70_80);
  VarCreate('WLD_90', '[cm.cm-3]',  0, false, WLD_80_90);
  VarCreate('WLD_100', '[cm.cm-3]',  0, false, WLD_90_100);


  StateCreate('TempSumR', '[°C*d]', 0.0, false, TempSumR);
  TempSumR.ReadFromIniFile := false;
  Varcreate('SRL', '[cm.cm-2]', 0.0, false, SRL);
  Varcreate('SRL_eff', '[cm.cm-2]', 0.0, false, SRL_eff);
  ExternVcreate('Temp', '[°C]', stateField, Temp);
  ExternVcreate('DMFineRoot', '[g.m-2]', stateField, DMFineRoot);
  ExternVCreate('SowingDate',  '[doy]', StateField, Sowingdate);
  ExternVCreate('HarvestDate', '[doy]', StateField, Harvestdate);



  for i := 1 to trunc(n_Rootcomp.v) do begin
    VarCreate(fName_WL+'WLD_'+IntToStr(i), '[cm.cm-3]', 0.0, false,WLD_arr[i]);
    VarCreate(fName_WL+'WL_'+IntToStr(i), '[cm.cm-2]', 0.0, false,WL_arr[i]);
    VarCreate(fName_WL+'effWLD_'+IntToStr(i), '[cm.cm-3]', 0.0, false, effWLD_arr[i]);
    VarCreate(fName_WL+'effWL_'+IntToStr(i), '[cm.cm-3]', 0.0, false, effWL_arr[i]);
  end;

  for i := 0 to trunc(n_Rootcomp.v) do
      ExternVCreate('Tiefe'+IntToStr(i),'[cm]',StateField,Tiefe[i]);

  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
  end;


end;

constructor TSimpleRootModDM_2.create(AOwner:TComponent);
var
  i : integer;
begin
  inherited create(AOwner);
//  fName_WL := '';
  createAll;
end;


procedure TSimpleRootModDM_2.Set_GlobMod(value:TMod);
var
  i : integer;
begin
  inherited Set_GlobMod(Value);
  createAll;

end;

Procedure TSimpleRootModDM_2.set_Name_WL(const Name_WL: string);

var
  i : integer;

begin
  fName_WL := Name_WL;
  for I := 1 to trunc(n_Rootcomp.v) do begin
     WLD_arr[i].name := fName_WL+WLD_arr[i].name;
     WL_arr[i].name := fName_WL+WL_arr[i].name;
     effWLD_arr[i].name := fName_WL+effWLD_arr[i].name;
     effWL_arr[i].name := fName_WL+effWL_arr[i].name;

  end;
end;


{Procedure TSimpleRootModDM_2.Set_PlantDMModel (const PlantDMModel : TSimplePlant);

begin
  FPlantDMModel := PlantDMModel;
  SowingDate := PlantDMModel.SowingDate;
  HarvestDate := PlantDMModel.HarvestDate;
end;}


procedure TSimpleRootModDM_2.Init(Var GlobMod: TMod);
var
  i, j : integer;

begin
  inherited Init(GlobMod);
//  If PlantModel
  OldDMFineRoot := 0.0;
  TempsumR.V := 0.0;
  for i := 1 to trunc(n_Rootcomp.v) do begin
    WLD_arr[i].v :=0.0;
    Wl_arr[i].v := 0.0;
  end;
  N_rootcomp.v := 20;

  for i := 1 to max_Comp do
   for j := 1 to MaxAgeCl do
     Root_matrix[i,j] := 0.0;
   n_age_cl := 0;

end;

procedure TSimpleRootModDM_2.CalcRates;

var
  i, j : integer;
  WL_alt, WL_neu, ActiveRL : real;

begin
  If (Globtime.v >= SowingDate.v) or (sowingdate = nil) then begin
  if root_matrix[1,1] <= 0.0 then begin
//    SRL.v := DMFineRoot.v*sp_RL.v/1e4;
//    for i := 1 to trunc(n_Rootcomp.v) do
//      WLD_arr[i].v := WLD_z_t_f ( Tiefe[i-1].v, tiefe[i].v);

    for j := Trunc(ActiveDuration.v) downto 1 do
      Root_matrix[1,j] := SRL.v/Trunc(ActiveDuration.v);

  end;


  If Temp.v>TempSumRootBaseTemp.v then
    TempSumR.C := (Temp.v-TempSumRootBaseTemp.V)
  else TempSumr.c := 0.0;
  inc(N_age_cl);

{  WLD_0_15.v := WLD_z_t_f ( 0, 15);
  WLD_15_30.v := WLD_z_t_f ( 15, 30);
  WLD_30_45.v := WLD_z_t_f ( 30, 45);
  WLD_45_60.v := WLD_z_t_f ( 45, 60);
  WLD_60_75.v := WLD_z_t_f ( 60, 75);
  WLD_75_90.v := WLD_z_t_f ( 75, 90);
  WLD_90_105.v := WLD_z_t_f ( 90, 105);
  WLD_105_120.v := WLD_z_t_f ( 105, 120);}



  SRL_eff.v  := 0.0;
  for i := 1 to trunc(n_Rootcomp.v) do begin
    for j := n_age_cl downto 2 do
      Root_matrix[i,j] := Root_Matrix[i,j-1];
    WL_alt := WLD_arr[i].v * (Tiefe[i].v-Tiefe[i-1].v);
    WLD_arr[i].v := WLD_z_t_f ( Tiefe[i-1].v, tiefe[i].v);
    Wl_arr[i].v := Wld_arr[i].v * (Tiefe[i].v-Tiefe[i-1].v);
    Root_Matrix[i,1] := max(0, Wl_arr[i].v-wl_alt);
    ActiveRL := 0.0;
    for j := 1 to Trunc(ActiveDuration.v) do
      ActiveRL := ActiveRl+Root_matrix[i,j];
//    ActiveRL := ActiveRL+            Root_matrix[i,Trunc(ActiveDuration.v)+1]*(ActiveDuration.v -Trunc(ActiveDuration.v));
    effWL_arr[i].v := ActiveRL;
    SRL_eff.v      := SRL_eff.v+ActiveRL;
    EffWLD_Arr[i].v := ActiveRL/(Tiefe[i].v-Tiefe[i-1].v);


    end;
  end;
  WLD_0_10.v := WLD_arr[1].v;
  WLD_10_20.v := WLD_arr[2].v;
  WLD_20_30.v := WLD_arr[3].v;
  WLD_30_40.v := WLD_arr[4].v;
  WLD_40_50.v := WLD_arr[5].v;
  WLD_50_60.v := WLD_arr[6].v;
  WLD_60_70.v := WLD_arr[7].v;
  WLD_70_80.v := WLD_arr[8].v;
  WLD_80_90.v := WLD_arr[9].v;
  WLD_90_100.v := WLD_arr[10].v;



  If (Globtime.v >= HarvestDate.v) and (Harvestdate <> nil) then begin
    zr.v := 0.0;
    SRL.v := 0.0;

    for i := 1 to trunc(n_Rootcomp.v) do begin
      WLD_arr[i].v := 0.0;
      Wl_arr[i].v := 0.0;
      effWLD_arr[i].v := 0.0;
      effWl_arr[i].v := 0.0;
    end;
    IsActive := false;


  end;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSimpleRootModDM_2]);
end;

end.


