unit BKGrowthSL_N;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, USimplePlant, UBkLeafDev, UBkGrowth, USleafGrowth, UState;

type
//  real = double;

  TNStress = (NoStress, MildStress, SevereStress);

  TBKGrowthSL_N = class(TBKGrowthSL)
  private
    { Private-Deklarationen }

    NDemandStem,
    NDemandLeaf,
    NDemandLeafProtein,
    NDemandLeafNitrate,
    NDemandGen,
    NDemandTapRoot,
    NDemandFineRoot
      : real;
    MaxNitrateMobilisation,
    NitrateMobilisation: real;
    SLeafNDemand,
    SLeafProtNDemand,
    SLeafNitrNDemand: array[1..maxLeaves] of real;



    function GetNOptStem(DMStem: real): real;
    function GetNOptLeaf(DMLeaf: real): real;
    function GetNOptGen(DMGen: real): real;
    function GetNOptTapRoot(DMTapRoot: real): real;
    function GetNOptSLeaf(DMLeaf: real; LeafNumber: integer): real;
    function GetNOptProtSLeaf(DMLeaf: real; LeafNumber: integer): real;
    procedure GetSLeafNChange;
  protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    sleaf_NCont: array[1..maxLeaves] of TVar;
    SLeaf_ProtNCont: array[1..maxLeaves] of TVar;
    SLeaf_NitrNCont: array[1..maxLeaves] of TVar;
    SLeaf_NArea: array[1..maxLeaves] of TVar;
    SLeaf_NAmount: array[1..maxLeaves] of TState;
    SLeaf_ProtAmount: array[1..maxLeaves] of TState;
    SLeaf_NitrAmount: array[1..maxLeaves] of TState;

    NStem: TState; // NMenge Stengel [g N/m2]
    NLeaf: TState; // NMenge Blatt (total-N)
    LeafNitrateN: TState; // Nitrate-N amount in leaf pool [g/m2]
    LeafNitrateNInGreenLeaves: TVar; // Nitrate-N amount in green leaf pool [g/m2]
    LeafProteinN: TState; // Protein-N Amount in Leaves [g/m2]
    NGen: TState; // N-Menge in generativen Organen [g N/m2]
    NRoot: TState; //  N-Menge in Wurzeln [g N/m2]
    NTapRoot: TState;
    NFineRoot: Tstate;
    NVeg: TState;
    NShoot: TState;
    NTotal: TState;
    PlantProteinN: TVar;
    PlantNDemand,
      PlantMinNDemand: TVar;

    NOptStem,
      NOptLeaf,
      NOptLeafProtein, // [% N DM]
      NoptNitrate,
      NOptGen,
      NOptTapRoot,
      NOptFineRoot,
      NOptLeafProtContArea: TVar;

    NPrStem,
      NPrLeaf,
      NPrLeafNitrate,
      NPrLeafProtein,
      NProtLeafArea, // Leaf nitrogen content per area [gN.m-2]
      NPrGen,
      NPrTapRoot,
      NPrFineRoot: TVar;

    NTranslocation,
      NAbortion: TVar;

    SumNTrans,
      SumNAbortion: TState;


    MaxFineRootFrac: TPar;
    kNO3: TPar;
    NConcTransDM: TPar; // Nitrogen concentration of translocated dry matter

    ActNUptake: TExternV;
    MAxNUptake: TExternV;
    NStress     : TNStress;
    MaxNAvailable: real; // Maximum available amount of Nitrogen from soil
                        // and translocation

    Diff: real; // Difference between NDemand and N available
    NUptReduct: real; // Reduction of N uptake

    procedure createAll; override;


    procedure CalcRates; override;
    procedure integrate; override;
    procedure Init(var GlobMod: Tmod); override;

  published
    { Published-Deklarationen }
    property St_NStem: TState read NStem write NStem;
    property St_NLeaf: TState read NLeaf write NLeaf;
    property St_NGen: Tstate read NGen write NGen;
    property St_NRoot: TState read NRoot write NRoot;
    property St_NTapRoot: TState read NTapRoot write NTapRoot;
    property St_NFineRoot: TState read NFineRoot write NFineRoot;
    property St_NShoot: TState read NShoot write NShoot;
    property St_NVeg: TState read NVeg write NVeg;
    property St_NTotal: TState read NTotal write NTotal;

    property Var_PlantNDemand: TVar read PlantNDemand write PlantNDemand;

    property Var_NOptStem: TVar read NOptStem write NOptStem;
    property Var_NOptLeaf: TVar read NOptLeaf write NOptLeaf;
    property Var_NOptGen: TVar read NOptGen write NOptGen;

    property Var_NPrStem: TVar read NPrStem write NPrStem;
    property Var_NPrLeaf: TVar read NPrLeaf write NPrLeaf;
    property Var_NPrGen: TVar read NPrGen write NPrGen;

    property Var_NTranslocation: TVar read NTranslocation write NTranslocation;
    property Par_MaxFineRootFrac: TPar read MaxFineRootFrac write MaxFineRootFrac;


    property Ex_ActNUptake: TExternV read ActNUptake write ActNUptake;
    property Ex_MAxNUptake: TExternV read MAxNUptake write MAxNUptake;



  end;

procedure Register;

implementation


function max(a, b: real): real;

begin
  if a > b then result := a
  else result := b;

end;

function min(a, b: real): real;

begin
  if a < b then result := a
  else result := b;
end;


procedure TBKGrowthSL_N.CreateAll;

var
  i: integer;

begin
  inherited CreateAll;
  StateCreate('NStem', '[g N .m-2]', 0.0, false, NStem);
  StateCreate('LeafNitrateN', '[g N .m-2]', 0.0, false, LeafNitrateN);
  VarCreate('LeafNitrateNinGreenLeaves', '[g N .m-2]', 0.0, false, LeafNitrateNinGreenLeaves);
  StateCreate('LeafProteinN', '[g N .m-2]', 0.0, false, LeafProteinN);
  StateCreate('NLeaf', '[g N .m-2]', 0.0, false, NLeaf);
  StateCreate('NCurd', '[g N .m-2]', 0.0, false, NGen);
  StateCreate('NRoot', '[g N .m-2]', 0.0, false, NRoot);
  StateCreate('NTapRoot', '[g N .m-2]', 0.0, false, NTapRoot);
  StateCreate('NFineRoot', '[g N .m-2]', 0.0, false, NFineRoot);
  Statecreate('TotalPlantNitrogen', '[gN /(m2)]', 0.0, true, NTotal);

  StateCreate('Nveg', '[g N .m-2]', 0.0, false, NVeg);
  StateCreate('NShoot', '[g N .m-2]', 0.0, false, NShoot);

  Statecreate('SumNTrans', '[gN /m2]', 0.0, true, SumNTrans);
  Statecreate('SumNAbortion', '[gN /m2]', 0.0, true, SumNAbortion);


  VarCreate('NOptStem', '[%N/DM]', 3.0, false, NOptStem);
  VarCreate('NOptLeaf', '[%N/DM]', 5.0, false, NOptLeaf);
  VarCreate('NOptLeafProtein', '[%N/DM]', 5.0, false, NOptLeafProtein);
  VarCreate('NOptNitrate', '[%N/DM]', 5.0, false, NOptNitrate);
  VarCreate('NOptGen', '[%N/DM]', 5.0, false, NOptGen);
  VarCreate('NOptTapRoot', '[%N/DM]', 2.6, false, NOptTapRoot);
  VarCreate('NOptFineRoot', '[%N/DM]', 1, false, NOptFineRoot);
  VarCreate('NOptLeafProtContArea', '[gN/m2]', 4, false, NOptLeafProtContArea);

  VarCreate('NPrStem', '[%N/DM]', 3.0, false, NPrStem);
  VarCreate('NPrLeaf', '[%N/DM]', 5.0, false, NPrLeaf);
  VarCreate('NPrLeafNitrate', '[%N/DM]', 5.0, false, NPrLeafNitrate);
  VarCreate('NPrLeafProtein', '[%N/DM]', 5.0, false, NPrLeafProtein);
  VarCreate('NProtLeafArea', '[gN/m2]', 0, false, NProtLeafArea);
  VarCreate('NPrGen', '[%N/DM]', 5.0, false, NPrGen);
  VarCreate('NPrTapRoot', '[%N/DM]', 2.6, false, NPrTapRoot);
  VarCreate('NPrFineRoot', '[%N/DM]', 1, false, NPrFineRoot);
  Varcreate('PlantProteinN', '[gN /(m2)]', 0.0, true, PlantProteinN);

  Varcreate('PlantNDemand', '[gN /(m2*d-1)]', 0.0, true, PlantNDemand);
  Varcreate('PlantMinNDemand', '[gN /(m2*d-1)]', 0.0, true, PlantMinNDemand);

  Varcreate('NTranslocation', '[gN /(m2*d-1)]', 0.0, true, NTranslocation);
  Varcreate('NAbortion', '[gN /(m2*d-1)]', 0.0, true, NAbortion);

  Parcreate('MaxFineRootFrac', '[-]', 0.15, MaxFineRootFrac);
  Parcreate('kNO3', '[-]', 0.33, kNO3);
  Parcreate('NconcTransDM', '[%DM]', 6.25, NConcTransDM);

  ExternVcreate('ActNUptake', '[kg N.ha-1.d-1]', statefield, ActNUptake);
  ExternVcreate('MaxNUptake', '[kg N.ha-1.d-1]', statefield, MaxNUptake);


  for i := 1 to MaxLeaves do begin
      VarCreate('SLeaf_NCont_' + IntToStr(i), '[%N]', 0.0, false, SLeaf_NCont[i]);
      VarCreate('SLeaf_ProtNCont_' + IntToStr(i), '[%N]', 0.0, false, SLeaf_ProtNCont[i]);
      VarCreate('SLeaf_NitrNCont_' + IntToStr(i), '[%N]', 0.0, false, SLeaf_NitrNCont[i]);
      VarCreate('SLeaf_NArea_' + IntToStr(i), '[gN.m-2]', 0.0, false, SLeaf_NArea[i]);

      StateCreate('SLeaf_NAmount_' + IntToStr(i), '[g/pl]', 0.0, false, SLeaf_NAmount[i]);
      StateCreate('SLeaf_NitrAmount_' + IntToStr(i), '[g/pl]', 0.0, false, SLeaf_NitrAmount[i]);
      StateCreate('SLeaf_ProtAmount_' + IntToStr(i), '[g/pl]', 0.0, false, SLeaf_ProtAmount[i]);
      SLeaf_NAmount[i].writeToFile := false;
      SLeaf_NitrAmount[i].writeToFile := false;
      SLeaf_ProtNcont[i].writeToFile := false;
      SLeaf_NitrNcont[i].writeToFile := false;
      SLeaf_ProtAmount[i].writeToFile := false;

    end;

end;


procedure TBkGrowthSL_N.Init(var GlobMod: Tmod);

var
  i: integer;

begin
  inherited init(GlobMod);
  NStem.v := DMStem.v * GetNoptStem(DMStem.v / BSTD.v) / 100;
  NLeaf.v := DMLeaf.v * GetNoptLeaf(DMLeaf.v / BStd.v) / 100;
  LeafNitrateN.v := 0.1 * NLeaf.v;
  LeafProteinN.v := NLeaf.v - LeafNitrateN.v; // Protein-N Amount in Leaves [g/m2]

  NTapRoot.v := DMTapRoot.v * GetNoptTapRoot(DMTapRoot.v / Bstd.v) / 100;
  Nfineroot.v := DMFineRoot.v * 0.01;

  NVeg.v := NStem.v + NLeaf.v + NTapRoot.v + NFineRoot.v;
  NDemandLeaf := 0.0;
  NDemandGen := 0.0;
  NDemandStem := 0.0;
  NPrSTem.v := GetNoptStem(DMStem.v / BSTD.v);
  NPrLeaf.v := GetNoptLeaf(DMLeaf.v / BStd.v);
  NPrGen.v := GetNoptGen(DMGen.v / Bstd.v);
  NLeaf.v := 0.0;
  LeafProteinN.v := 0.9 * NLeaf.v;
  LeafNitrateN.v := 0.0;
  for I := 1 to trunc(bzs.v) do begin
      SLeaf_NAmount[i].v := SLeaf_mass[i].v * GetNOptSLeaf(SLeaf_mass[i].v, i) / 100;
      SLeaf_NitrAmount[i].v := 0.1 * SLeaf_NAmount[i].v;
      SLeaf_ProtAmount[i].v := SLeaf_NAmount[i].v - SLeaf_NitrAmount[i].v;
      NLeaf.v := NLeaf.v + SLeaf_NAmount[i].v;
      LeafProteinN.v := LeafProteinN.v + SLeaf_ProtAmount[i].v;
      LeafNitrateN.v := LeafNitrateN.v + SLeaf_NitrAmount[i].v;
      SLeaf_NArea[i].v := SLeaf_ProtAmount[i].v / (Sleaf_area[i].v) * 1E4;
    end;
  NProtLeafArea.v := LeafProteinN.v / LAI.v;
  LeafNitrateNInGreenleaves.v := LeafNitrateN.v;
end;




function TBkGrowthSL_n.GetNOptStem(DMStem: real): real;

{-------------------------------------------------------------- JAHR=1996 ------------------------------------------------------------------

Model: MODEL1
Dependent Variable: NPRSTR

                                                             Analysis of Variance

                        Sum of         Mean
Source          DF      Squares       Square      F Value       Prob>F

Model            1      1.85836      1.85836      258.362       0.0001
Error            9      0.06474      0.00719
C Total         10      1.92309
Root MSE       0.08481     R-square       0.9663
Dep Mean       2.81909     Adj R-sq       0.9626
C.V.           3.00844
Parameter Estimates

                  Parameter      Standard    T for H0:
Variable  DF      Estimate         Error   Parameter=0    Prob > |T|
INTERCEP   1      3.445952    0.04663523        73.892        0.0001
LNSTR      1     -0.346517    0.02155810       -16.074        0.0001

}

begin
  result := -0.346 * ln(DMStem) + 3.45;
end;

function TBkGrowthSL_n.GetNOptLeaf(DMLeaf: real): real;
begin
  result := -0.01118 * DMLeaf + 5.63;
end;

function TBkGrowthSL_n.GetNOptSLeaf(DMLeaf: real; LeafNumber: integer): real;

{  Analyse der 1996 Daten
                                                             Analysis of Variance

                      Sum of         Mean
 Source          DF      Squares       Square      F Value       Prob>F
 Model            2      7.45558      3.72779       59.398       0.0001
 Error           19      1.19243      0.06276
 C Total         21      8.64801
 Root MSE       0.25052     R-square       0.8621
 Dep Mean       5.23495     Adj R-sq       0.8476
 C.V.           4.78549

                 Parameter Estimates

                       Parameter      Standard    T for H0:
     Variable  DF      Estimate         Error   Parameter=0    Prob > |T|
     INTERCEP   1      6.988985    0.21389086        32.675        0.0001
     TM         1     -0.037464    0.00345128       -10.855        0.0001
     ORG        1     -0.080011    0.01249189        -6.405        0.0001}


begin
  result := 6.99 - 0.0375 * DMLeaf * 5 - 0.08 * Leafnumber;
end;

function TBkGrowthSL_n.GetNOptProtSLeaf(DMLeaf: real; LeafNumber: integer): real;

// Parameter values for the treatments without shading in 1996 field experiment
begin
  result := 6.741 - -0.0402 * DMLeaf * 5 - 0.023 * Leafnumber;
end;


function TBkGrowthSL_n.GetNOptGen(DMGen: real): real;


{
Analyse der 1996 daten
R = 0.93159287	Rsqr = 0.86786527	Adj Rsqr = 0.84143832

Standard Error of Estimate = 0.5924

  Coefficient	Std. Error	t	P
a	6.7633	0.2927	23.1092	<0.0001
b	0.0091	0.0018	4.9562	0.0043

Analysis of Variance:
  DF	SS	MS	F	P
Regression	1	11.5265	11.5265	32.8402	0.0023
Residual	5	1.7549	0.3510
Total	6	13.2814	2.2136}



begin
  result := 6.763 * exp(-0.0091 * DMGen);
end;

function TBkGrowthSL_n.GetNOptTapRoot(DMTapRoot: real): real;

begin
  result := 2.65 - 0.0381 * DMTapRoot;
end;



procedure TBkGrowthSL_n.GetSLeafNChange;

var
  i: integer;

begin
  SumNAbortion.c := 0.0;
  for i := 1 to trunc(BZs.v) do begin
    case LeafStatus_arr[i] of
      aborted: begin
        SLeaf_NAmount[i].c := 0.0;
        SLeaf_ProtAmount[i].c := 0.0;
        SLeaf_NitrAmount[i].c := 0.0;
        SLeaf_NAmount[i].v := 0.0;
        SLeaf_ProtAmount[i].v := 0.0;
        SLeaf_NitrAmount[i].v := 0.0;
      end;
      senescent: begin
        NAbortion.v := DMAbortrate[i] * SLeaf_NCont[i].v / 100;
        SumNAbortion.c := SumNAbortion.c - NAbortion.v * Bstd.v;
        SLeaf_NAmount[i].c := NAbortion.v;
        if SLeaf_NAmount[i].v > 0.0 then begin
          SLeaf_ProtAmount[i].c := SLeaf_NAmount[i].c * SLeaf_ProtAmount[i].v / SLeaf_NAmount[i].v;
          SLeaf_NitrAmount[i].c := SLeaf_NAmount[i].c * SLeaf_NitrAmount[i].v / SLeaf_NAmount[i].v
        end else begin
          SLeaf_ProtAmount[i].c := 0.0;
          SLeaf_NitrAmount[i].c := 0.0;
        end;
        SLeaf_NAmount[i].c := SLeaf_ProtAmount[i].c + SLeaf_NitrAmount[i].c;
      end;
      senescing: begin
        SLeaf_NAmount[i].c := -DMTransRate[i] * NConcTransDM.v / 100;
        SLeaf_ProtAmount[i].c := SLeaf_NAmount[i].c * SLeaf_ProtAmount[i].v / SLeaf_NAmount[i].v;
        SLeaf_NitrAmount[i].c := SLeaf_NAmount[i].c * SLeaf_NitrAmount[i].v / SLeaf_NAmount[i].v;
      end;
      green: begin
        case NStress of
          NoStress: begin
            SLeaf_ProtAmount[i].c := SLeafProtNDemand[i];
            SLeaf_NitrAmount[i].c := SLeafNitrNDemand[i];
            SLeaf_NAmount[i].c := SLeafNDemand[i];
//            SLeaf_NAmount[i].c    :=  SLeaf_ProtAmount[i].c+SLeaf_NitrAmount[i].c;
          end;

          MildStress: begin
            SLeaf_ProtAmount[i].c := SLeafProtNDemand[i];
            if NDemandLeafNitrate > 0.0 then begin
              if SLeafNitrNDemand[i] > 0.0 then
                SLeaf_NitrAmount[i].c := NitrateMobilisation / NDemandLeafNitrate * SLeafNitrNDemand[i]
              else
                SLeaf_NitrAmount[i].c := 0.0;
            end;
//             SLeaf_NitrAmount[i].c := SLeafNitrNDemand[i]
//              else
//                SLeaf_NAmount[i].c := SLeaf_ProtAmount[i].c + SLeaf_NitrAmount[i].c;
         end;

         SevereStress: begin
                    SLeaf_ProtAmount[i].c := min(SLeafProtNDemand[i] * NUptReduct, SLeafProtNDemand[i]);
                    if SLeaf_NitrAmount[i].v > 0.0 then
                      if SLeafNitrNDemand[i] > 0.0 then
                        SLeaf_NitrAmount[i].c := NitrateMobilisation * (SLeaf_NitrAmount[i].v) / LeafNitrateNinGreenLeaves.v
                      else
                        SLeaf_NitrAmount[i].c := SLeafNitrNDemand[i]
                    else
                      SLeaf_NitrAmount[i].c := 0.0;
                    SLeaf_NAmount[i].c := SLeaf_ProtAmount[i].c + SLeaf_NitrAmount[i].c;
                  end;
              end;
            end;
        end;
      end;
    NLeaf.c := 0.0;
    LeafNitrateN.c := 0.0;
    LeafProteinN.c := 0.0;
    NitrateMobilisation := 0.0;
    for i := 1 to trunc(bzs.v) do begin
        NLeaf.c := NLeaf.c + SLeaf_NAmount[i].c * Bstd.v;
        LeafNitrateN.c := LeafNitrateN.c + Sleaf_NitrAmount[i].c * Bstd.v;
        LeafProteinN.c := LeafProteinN.c + SLeaf_ProtAmount[i].c * Bstd.v;
        if LeafStatus_arr[i] = green then
          NitrateMobilisation := NitrateMobilisation + Sleaf_NitrAmount[i].c * Bstd.v;
   end;
end;




procedure TBKGrowthSL_N.CalcRates;


procedure GetNDemLeaf;

  var
    i: integer;
    CumLAI: real; // cumulative LAI
    fNitr: real; // fraction of nitrate nitrogen
    IncidPar: array[1..MaxLeaves] of real; // radiation intensity [W PAR . m-2]
    OptSLeaf_NCont: array[1..MaxLeaves] of real; // optimum Ncontent [%DM]
    OptSLeafNAmount, // optimum Namount [g N. pl-1]
      OptSLeafProtNAmount, //
      OptLeafProtAmount,
      OptSLeafNitrNAmount: real; //


  begin
    cumLai := SLeaf_area[trunc(bzs.v)].v / 1E4 * Bstd.v;
    IncidPar[trunc(bzs.v)] := PARav.v * exp(-0.75 * CumLai) * 1E6 / 86400;
    for i := trunc(Bzs.v) - 1 downto 1 do begin
        Cumlai := CumLai + SLeaf_area[i].v / 1E4 * Bstd.v;
        IncidPar[i] := PARav.v * exp(-0.75 * CumLai) * 1E6 / 86400;
      end;

    NDemandLeaf := 0.0;
    NDemandLeafProtein := 0.0;
    NDemandLeafNitrate := 0.0;
    OptLeafProtAmount := 0.0;
    for i := 1 to trunc(Bzs.v) do begin
        if Leafstatus_arr[i] = green then begin
            OptSLeaf_NCont[i] := GetNOptSLeaf(SLeaf_mass[i].v + SLeaf_mass[i].c * GlobTime.c, i);
            fNitr := max(0, 0.2456 - 0.0023 * IncidPar[i]);

            OptSLeafNAmount := OptSLeaf_NCont[i] * (SLeaf_mass[i].v + SLeaf_mass[i].c * GlobTime.c) / 100;
            OptSLeafProtNAmount := OptSLeafNAmount * (1 - FNitr);
            OptLeafProtAmount := OptLeafProtAmount + OptSLeafProtNAmount;
            OptSLeafNitrNAmount := OptSLeafNAmount * FNitr;

//      OptSLeafProtNAmount := OptSLeaf_NCont[i]*(1-FNitr)*SLeaf_mass[i].v/100;
//      OptSLeafNitrNAmount := OptSLeaf_NCont[i]*FNitr*SLeaf_mass[i].v/100;

            SLeafNDemand[i] := (OptSleafNAmount - SLeaf_NAmount[i].v) / GlobTime.c;
            SLeafProtNDemand[i] := (OptSleafProtNAmount - SLeaf_ProtAmount[i].v) / GlobTime.c;
            SLeafNitrNDemand[i] := (OptSleafNitrNAmount - SLeaf_NitrAmount[i].v) / GlobTime.c;
          end else begin
            SLeafNDemand[i] := 0.0;
            SLeafProtNDemand[i] := 0.0;
            SLeafNitrNDemand[i] := 0.0;
            OptLeafProtAmount := OptLeafProtAmount + SLeaf_ProtAmount[i].v;
          end;

        NDemandLeaf := NDemandLeaf + SLeafNDemand[i];
        NDemandLeafNitrate := NDemandLeafNitrate + SLeafNitrNDemand[i];
        NDemandLeafProtein := NDemandLeafProtein + SLeafProtNDemand[i];

      end;
    NDemandLeaf := NDemandLeaf * Bstd.v;
    NDemandLeafProtein := NDemandLeafProtein * Bstd.v;
    NDemandLeafNitrate := NDemandLeafNItrate * Bstd.v;
    NOptLeafProtContArea.v := (NDemandLeafProtein + LeafProteinN.v) / (LAI.v + LAI.c * GlobTime.c);
    NOptLeafProtein.v := (OptLeafProtAmount * Bstd.v) / (DMLeaf.v + DMLeaf.c * GlobTime.c) * 100;
    NoptNItrate.v := (NdemandLeafNitrate + LeafNitrateN.v) / (DMLeaf.v + DMLeaf.c * GlobTime.c) * 100;

 end;


begin
  inherited CalcRates;

// Initialisiation of newly formed leaves
  if (SLeaf_Namount[trunc(bzs.v)].v <= 0.0) then begin
      SLeaf_NAmount[trunc(bzs.v)].v := SLeaf_mass[trunc(bzs.v)].v * GetNoptsLeaf(SLeaf_mass[trunc(bzs.v)].v, trunc(bzs.v)) / 100;
      SLeaf_NitrAmount[trunc(bzs.v)].v := 0.02 * SLeaf_NAmount[trunc(bzs.v)].v;
      SLeaf_ProtAmount[trunc(bzs.v)].v := SLeaf_NAmount[trunc(bzs.v)].v - SLeaf_NitrAmount[trunc(bzs.v)].v;
    end;
  NStress := NoStress;

// Calculation of N-Translocation
  NTranslocation.v := DMTrans.v * NconcTransDM.v / 100 * Bstd.v;
  SumNTrans.c := NTranslocation.v;
  MaxNAvailable := MAxNUptake.v / 10 + NTranslocation.v;

// Calculation of optimal N-content
  NoptStem.v := GetNoptStem((DMStem.v + DMStem.c * GlobTime.c) / Bstd.v);
  NoptGen.v := GetNOptGen((DMGen.v + DMGen.c * GlobTime.c) / Bstd.v);
  NOptTapRoot.v := GetNOptTapRoot((DMTapRoot.v + DMTapRoot.c * GlobTime.c) / Bstd.v);
  NOptLeaf.v := GetNoptLeaf(DMLeaf.v / BStd.v);

  NOptFineRoot.v := 1;

// Calculation of nitrogen demand values for organs
  NDemandStem := max(0, ((DMStem.v + DMStem.c * GlobTime.c) * NOptStem.v / 100 - (NSTem.v)) / GlobTime.c);
  NDemandLeaf := max(0, ((DMLeaf.v + DMLeaf.c * GlobTime.c) * NOptLeaf.v / 100 - (NLeaf.v)) / GlobTime.c);
  NDemandTapRoot := max(0, ((DMTapRoot.v + DMTapRoot.c * GlobTime.c) * NOptTapRoot.v / 100 - (NTapRoot.v)) / GlobTime.c);
  NDemandFineRoot := max(0, ((DMFineRoot.v + DMFineRoot.c * GlobTime.c) * NOptFineRoot.v / 100 - (NFineRoot.v)) / GlobTime.c);
  GetNDemLeaf;
  if DMGen.v > 0.0 then
    NDemandGen := max(0, ((DMGen.v + DMGen.c * GlobTime.c) * NOptGen.v / 100 - (NGen.v)) / GlobTime.c);

// Initialisation of curd nitrogen after curd initiation
  if (NGen.v = 0.0) and (DMGen.c > 0.0) then begin
      NGen.c := DMGen.c * GetNoptGen(DMGen.c / Bstd.v) / 100;
      NDemandGen := NGen.c;
    end;

  PlantNDemand.v := max(0, NdemandStem
    + NDemandLeaf + NDemandGen + NDemandTapRoot + NDemandFineRoot);

  PlantMinNDemand.v := max(0, PlantNDemand.v - NDemandLeafNitrate);

  if PlantNDemand.v > 0.0 then begin
      if MAxNAvailable >= PlantNDemand.v then begin
          NStress := NoStress;
          NStem.c := NDemandStem;
          NGen.c := NDemandGen;
          NTapRoot.c := NDemandTapRoot;
          NFineRoot.c := NDemandFineRoot;
          Frac_FRoots.v := Frac_FRoots0.v;
        end else begin //     MAxNAvailable < PlantNDemand.v
          NStress := MildStress; // only leaf nitrate uptake is not satisfied
          Diff := PlantNDemand.v - MaxNAvailable;
          MaxNitrateMobilisation := LeafNitrateNinGreenLeaves.v * kNO3.v;
          if Diff < MaxNitrateMobilisation then begin
              NStress := MildStress; // only leaf nitrate uptake is not satisfied
              NStem.c := NDemandStem;
              NGen.c := NDemandGen;
              NTapRoot.c := NDemandTapRoot;
              NFineRoot.c := NDemandFineRoot;
              NitrateMobilisation := (NDemandLeafNitrate - Diff);
              Frac_FRoots.v := Frac_FRoots0.v;
            end else begin // Also N-demand of other N-Pools is not satisfied
         // A certain fraction of the leaf nitrate pool is made available for other organs
              MaxNAvailable := MaxNAvailable + MaxNitrateMobilisation;
              if PlantMinNDemand.v > 0.0 then
                NUptReduct := MaxNAvailable / PlantMinNDemand.v
              else NuptReduct := 1.0;
       // This mobilised nitrate oversatifies all demands except of nitrate pool
              if NuptReduct > 1.0 then begin
       // Leaf nitrate change is less than potential rate
                  NitrateMobilisation := MaxNAvailable - PlantMinNDemand.v - MaxNitrateMobilisation;
                  NUptReduct := 1.0;
                  NStem.c := NDemandStem;
                  NTapRoot.c := NDemandTapRoot;
                  NFineRoot.c := NDemandFineRoot;
                  NGen.c := NDemandGen;
                end else begin //
                  NStress := SevereStress; // Leaf protein change is negative
                  NitrateMobilisation := max(MaxNAvailable - PlantMinNDemand.v - MaxNitrateMobilisation, -MaxNitrateMobilisation);
                  if MaxNAvailable > NDemandGen then begin
                      NGen.c := NDemandGen; // Curd N demand is first served
                      MaxNAvailable := MaxNAvailable;
                      NuptReduct := (MaxNAvailable - NGen.c) / (PlantMinNdemand.v - NGen.c);
                      NStem.c := NDemandStem * NUptReduct;
                      NTapRoot.c := NDemandTapRoot * NUptReduct;
                      NFineRoot.c := NDemandFineRoot * NUptReduct;
                    end else begin // less than the N demand of the curd is available
                      NGen.c := MaxNAvailable;
                      NUptReduct := 0.0;
                      NStem.c := 0.0;
                      NTapRoot.c := 0.0;
                      NFineRoot.c := 0.0;
                    end;
                end;
            end;
        end
    end else begin //    PlantNDemand.v < 0.0
      PlantNDemand.v := 0.0;
      NStem.c := 0;
      NGen.c := 0;
      NTapRoot.c := 0.0;
      NFineRoot.c := 0.0;
    end;

  if NStress = SevereStress then
    frac_froots.v := Frac_Froots.v + 0.2 * Frac_Froots.v * (1 - frac_froots.v / MaxFineRootFrac.v)
  else
    Frac_Froots.v := Frac_Froots.v - 0.2 * Frac_FRoots0.v * (1 - Frac_froots0.v / Frac_froots.v);


  GetSLeafNChange;

  NVeg.c := Nstem.c + NLeaf.c + NRoot.c;
  NRoot.c := NTapRoot.c + NFineRoot.c;
  NShoot.c := Nstem.c + NLeaf.c + Ngen.c;
  NTotal.c := Nstem.c + NLeaf.c + Ngen.c + NRoot.c;

end;


procedure TBkGrowthSL_N.integrate;

var
  i: integer;

begin
  inherited integrate;
  if DMStem.v > 0.0 then
    NPrStem.v := NStem.v / DMStem.v * 100;
  if DMGen.v > 0.0 then
    NPrGen.v := NGen.v / DMGen.v * 100;
  if DMTapRoot.V > 0.0 then
    NPrTapRoot.v := NTapRoot.v / DMTapRoot.v * 100;
  if DMFineRoot.v > 0.0 then
    NPrFineRoot.v := NFineRoot.v / DMFineRoot.v * 100;
  NLeaf.v := 0.0;
  LeafProteinN.v := 0.0;
  LeafNitrateN.v := 0.0;
  LeafNitrateNinGreenLeaves.v := 0.0;

  for i := 1 to trunc(BZs.v) do begin
      if SLeaf_mass[i].v <= 0.0 then begin
          SLeaf_Namount[i].v := 0.0;
          SLeaf_NitrAmount[i].v := 0.0;
          SLeaf_ProtAmount[i].v := 0.0;
        end else begin
          SLeaf_NCont[i].v := SLeaf_NAmount[i].v / SLeaf_mass[i].v * 100;
          SLeaf_ProtNCont[i].v := SLeaf_ProtAmount[i].v / SLeaf_mass[i].v * 100;
          SLeaf_NitrNCont[i].v := SLeaf_NitrAmount[i].v / SLeaf_mass[i].v * 100;
          SLeaf_NArea[i].v := SLeaf_ProtAmount[i].v / (Sleaf_area[i].v) * 1E4;
        end;
      LeafProteinN.v := LeafProteinN.v + SLeaf_ProtAmount[i].v * Bstd.v;
      LeafNitrateN.v := LeafNitrateN.v + SLeaf_NitrAmount[i].v * Bstd.v;
      if Leafstatus_arr[i] = green then
        LeafNitrateNinGreenLeaves.v := LeafNitrateNinGreenLeaves.v + SLeaf_NitrAmount[i].v * Bstd.v;

    end;
  NLeaf.v := LeafProteinN.v + LeafNitrateN.v;

  if DMLeaf.v > 0.0 then begin
      NPrLeaf.v := NLeaf.v / DMLeaf.v * 100;
      NPrLeafProtein.v := LeafProteinN.v / DMLeaf.v * 100;
      NPrLeafNitrate.v := LeafNitrateN.v / DMLeaf.v * 100;
    end;
  NProtLeafArea.v := LeafProteinN.v / LAI.v;
  PlantProteinN.v := LeafProteinN.v + NStem.v + NGen.v + NTaproot.v + NFineRoot.v;

end;

procedure Register;
begin
  RegisterComponents('CauliSim', [TBKGrowthSL_N, TBkGrowth, TBKGrowthSL, TBkLeafDev]);
end;

end.

