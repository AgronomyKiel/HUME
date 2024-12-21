unit USleafGrowth;

{$DEFINE GROUP5}

interface

uses
 UState, Umod, IniFiles, USimplePlant, UBKGrowth, Classes;

const
  MaxLeaves = 50;

type
  real = double;
  TLeafStatus = (none, green, senescing, senescent, aborted);

TBKGrowthSL = class(TBkGrowth)

private
  sum_rgr        : real;

protected

public
    TempSum    : TState;
    NsenLeaves : TState;
    NabLeaves  : TState;
    LATotal    : TState;
    LeafStatus_arr : array[1..MaxLeaves] of TLeafstatus;

    MaxTSumLeaf : TPar;
    SenTsumLeaf : TPar;

    Senrate     : TPar;  // specific senescence rate (g/(g*°C*d)
    Abrate      : TPar;  // specific abortion rate (g/(g*°C*d)
    FTransDM    : TPar;  // fraction of translocable dry weight
    rgr_crit    : TPar;  // fraction of the inital growth rate when senescence starts

    sleaf_mass : array[1..maxLeaves]   of TState;

    TransLmass  : array[1..maxLeaves]   of TState; // Translocable leaf mass
    TSsen       : array[1..maxLeaves]   of real; // Tsum when leaves are senescent
    TSab        : array[1..maxLeaves]   of real; // Tsum when leaves are aborted
    StructLMass : array[1..maxLeaves]  of real;
    Translocated: array[1..maxLeaves] of real; // Translocated leaf mass
    DMTransRate : array[1..maxLeaves]  of real;  // Rate of Translocated leaf mass (g/pl/d)
    DMAbortRate : array[1..maxLeaves]  of real;  // Rate of DM abortion from leaf mass (g/pl/d)
    LAAbortRate : array[1..maxLeaves]  of real;  // Rate of Leaf area abortion (cm2/pl/d)
    STransRate  : array[1..maxLeaves]   of real;   // specific rate of Translocated leaf mass
    SAbortRate  : array[1..maxLeaves]   of real;   // specific rate leaf mass abortion
    rgr_mat     : array[1..maxLeaves, 1..MaxParDays]  of real;  // relative growth rates of single leaves
    rgr_        : array[1..maxLeaves]  of real;  // relative growth rates of single leaves

    sleaf_area  : array[1..maxLeaves] of TState;
    frac_growth : array[1..maxLeaves] of real;



    LMass_1_5,
    lMass_6_10,
    lMass_11_15,
    lMass_16_20,
    lMass_21_25,
    lMass_26_30,
    lMass_31_35 : TVar;

    lArea_1_5,
    lArea_6_10,
    lArea_11_15,
    lArea_16_20,
    lArea_21_25,
    lArea_26_30,
    lArea_31_35 : TVar;

    SLA_1_5,
    SLA_6_10,
    SLA_11_15,
    SLA_16_20,
    SLA_21_25,
    SLA_26_30,
    SLA_31_35 : TVar;


{    LMass_1_3,
    lMass_4_6,
    lMass_7_9,
    lMass_10_12,
    lMass_13_15,
    lMass_16_18,
    lMass_19_21,
    lMass_22_24,
    lMass_25_27,
    lMass_28_30

     : TVar;


    LArea_1_3,
    LArea_4_6,
    LArea_7_9,
    LArea_10_12,
    LArea_13_15,
    LArea_16_18,
    LArea_19_21,
    LArea_22_24,
    LArea_25_27,
    LArea_28_30

     : TVar;

    SLA_1_3,
    SLA_4_6,
    SLA_7_9,
    SLA_10_12,
    SLA_13_15,
    SLA_16_18,
    SLA_19_21,
    SLA_22_24,
    SLA_25_27,
    SLA_28_30

     : TVar;}


    TotalLeafArea,
    TotalLeafMass : TVar;


    Dominanz : Tpar;   // Dominanz der jungen über die alten Blätter
    rgr0     : TPar;    // potentielle relative Wachstumsrate der jungen Blätter [1/d]
    rgr_dec  : TPar;
    rgr_min  : TPar;

    rgr      : TVar;
    SLA0     : TPar;
    SLA_pardec : TPar;
    SLA_ndec : TPar;
    SLA_Sizedec : TPar;
    SumTrans       : TVar;
    SumAbort       : TVar;

    k           : TExternV; // light extinction coefficient

   procedure createAll; override;


   Constructor create(AOwner : TComponent); override;
   procedure Set_GlobMod(value:TMod); override;


   procedure Init(var GlobMod:Tmod); override;

   procedure CalcRates; override;
   procedure Integrate; override;

published
   property State_nSenLeaves : TState read nSenLeaves write nSenLeaves;
   property State_nabLeaves : TState read nabLeaves write nabLeaves;
   property Par_MaxTSumLeaf : TPar read maxTSumLeaf write MaxTSumLeaf;
   property Par_SenTSumLeaf : TPar read SenTSumLeaf write SenTSumLeaf;

   property Par_Dominanz : TPar read Dominanz write Dominanz;
   property Par_rgr0      : TPar read rgr0 write rgr0;
   property Par_rgr_dec      : TPar read rgr_dec write rgr_dec;
   property Par_rgr_min      : TPar read rgr_min write rgr_min;

{

   property Var_lArea_1_5 : TVar read lArea_1_5 write lArea_1_5;
   property Var_lArea_6_10 : TVar read lArea_6_10 write lArea_6_10;
   property Var_lArea_11_15 : TVar read lArea_11_15 write lArea_11_15;
   property Var_lArea_16_20 : TVar read lArea_16_20 write lArea_16_20;
   property Var_lArea_21_25 : TVar read lArea_21_25 write lArea_21_25;
   property Var_lArea_26_30 : TVar read lArea_26_30 write lArea_26_30;
   property Var_lArea_31_35 : TVar read lArea_31_35 write lArea_31_35;


   property Var_lMass_1_5 : TVar read lMass_1_5 write lMass_1_5;
   property Var_lMass_6_10 : TVar read lMass_6_10 write lMass_6_10;
   property Var_lMass_11_15 : TVar read lMass_11_15 write lMass_11_15;
   property Var_lMass_16_20 : TVar read lMass_16_20 write lMass_16_20;
   property Var_lMass_21_25 : TVar read lMass_21_25 write lMass_21_25;
   property Var_lMass_26_30 : TVar read lMass_26_30 write lMass_26_30;
   property Var_lMass_31_35 : TVar read lMass_31_35 write lMass_31_35;
}

end;

procedure register;

implementation

uses
  SysUtils, math,
 UModUtils ;



procedure TBkGrowthSL.createAll;

var
  i : integer;

begin
  inherited CreateAll;
  StateCreate('TempSum', '[n]', 0.0, false, TempSum);
  StateCreate('BZsen', '[n]', 0.0, false, NsenLeaves);
  StateCreate('BZab', '[n]', 0.0, false, NabLeaves);
  StateCreate('LATotal', '[n]', 0.0, false, LATotal);
  ParCreate('MaxTSumLeaf','[°C*d]', 400, MaxTSumLeaf);
  ParCreate('SenTSumLeaf','[°C*d]', 300, SenTSumLeaf);

  VarCreate('SumTrans', '[g.m-2]', 0.0, false, SumTrans);
  VarCreate('SumAbort', '[g.m-2]', 0.0, false, SumAbort);
  For i :=  1 to maxLeaves do begin
    LeafStatus_arr[i] := green;
  end;

  ExternVCreate('k', '[]', StateField, k);

{$IFDEF GROUP5}
  VarCreate('LMass_1_5','[g/pl]', 0.0, false, LMass_1_5);
  VarCreate('LMass_6_10','[g/pl]', 0.0, false, LMass_6_10);
  VarCreate('LMass_11_15','[g/pl]', 0.0, false, LMass_11_15);
  VarCreate('LMass_16_20','[g/pl]', 0.0, false, LMass_16_20);
  VarCreate('LMass_21_25','[g/pl]', 0.0, false, LMass_21_25);
  VarCreate('LMass_26_30','[g/pl]', 0.0, false, LMass_26_30);
  VarCreate('LMass_31_35','[g/pl]', 0.0, false, LMass_31_35);

  VarCreate('LArea_1_5','[g/pl]', 0.0, false, LArea_1_5);
  VarCreate('LArea_6_10','[g/pl]', 0.0, false, LArea_6_10);
  VarCreate('LArea_11_15','[g/pl]', 0.0, false, LArea_11_15);
  VarCreate('LArea_16_20','[g/pl]', 0.0, false, LArea_16_20);
  VarCreate('LArea_21_25','[g/pl]', 0.0, false, LArea_21_25);
  VarCreate('LArea_26_30','[g/pl]', 0.0, false, LArea_26_30);
  VarCreate('LArea_31_35','[g/pl]', 0.0, false, LArea_31_35);

  VarCreate('SLA_1_5','[g/pl]', 0.0, false, SLA_1_5);
  VarCreate('SLA_6_10','[g/pl]', 0.0, false, SLA_6_10);
  VarCreate('SLA_11_15','[g/pl]', 0.0, false, SLA_11_15);
  VarCreate('SLA_16_20','[g/pl]', 0.0, false, SLA_16_20);
  VarCreate('SLA_21_25','[g/pl]', 0.0, false, SLA_21_25);
  VarCreate('SLA_26_30','[g/pl]', 0.0, false, SLA_26_30);
  VarCreate('SLA_31_35','[g/pl]', 0.0, false, SLA_31_35);

{$ENDIF}

{$IFDEF GROUP3}
  VarCreate('LMass_1_3','[g/pl]', 0.0, false, LMass_1_3);
  VarCreate('LMass_4_6','[g/pl]', 0.0, false, LMass_4_6);
  VarCreate('LMass_7_9','[g/pl]', 0.0, false, LMass_7_9);
  VarCreate('LMass_10_12','[g/pl]', 0.0, false, LMass_10_12);
  VarCreate('LMass_13_15','[g/pl]', 0.0, false, LMass_13_15);
  VarCreate('LMass_16_18','[g/pl]', 0.0, false, LMass_16_18);
  VarCreate('LMass_19_21','[g/pl]', 0.0, false, LMass_19_21);
  VarCreate('LMass_22_24','[g/pl]', 0.0, false, LMass_22_24);
  VarCreate('LMass_25_27','[g/pl]', 0.0, false, LMass_25_27);
  VarCreate('LMass_28_30','[g/pl]', 0.0, false, LMass_28_30);

  VarCreate('LArea_1_3','[cm2/pl]', 0.0, false, LArea_1_3);
  VarCreate('LArea_4_6','[cm2/pl]', 0.0, false, LArea_4_6);
  VarCreate('LArea_7_9','[cm2/pl]', 0.0, false, LArea_7_9);
  VarCreate('LArea_10_12','[cm2/pl]', 0.0, false, LArea_10_12);
  VarCreate('LArea_13_15','[cm2/pl]', 0.0, false, LArea_13_15);
  VarCreate('LArea_16_18','[cm2/pl]', 0.0, false, LArea_16_18);
  VarCreate('LArea_19_21','[cm2/pl]', 0.0, false, LArea_19_21);
  VarCreate('LArea_22_24','[cm2/pl]', 0.0, false, LArea_22_24);
  VarCreate('LArea_25_27','[cm2/pl]', 0.0, false, LArea_25_27);
  VarCreate('LArea_28_30','[cm2/pl]', 0.0, false, LArea_28_30);

  VarCreate('SLA_1_3','[cm2/pl]', 0.0, false, SLA_1_3);
  VarCreate('SLA_4_6','[cm2/pl]', 0.0, false, SLA_4_6);
  VarCreate('SLA_7_9','[cm2/pl]', 0.0, false, SLA_7_9);
  VarCreate('SLA_10_12','[cm2/pl]', 0.0, false, SLA_10_12);
  VarCreate('SLA_13_15','[cm2/pl]', 0.0, false, SLA_13_15);
  VarCreate('SLA_16_18','[cm2/pl]', 0.0, false, SLA_16_18);
  VarCreate('SLA_19_21','[cm2/pl]', 0.0, false, SLA_19_21);
  VarCreate('SLA_22_24','[cm2/pl]', 0.0, false, SLA_22_24);
  VarCreate('SLA_25_27','[cm2/pl]', 0.0, false, SLA_25_27);
  VarCreate('SLA_28_30','[cm2/pl]', 0.0, false, SLA_28_30);


  {$ENDIF}


  VarCreate('LAges','[cm2/pl]', 0.0, false, TotalLeafArea);
  VarCreate('TotalLeafMass','[g/pl]', 0.0, false, TotalLeafMass);

  VarCreate('rgr', '[1/d]', 0.3, false, rgr);

  ParCreate('Dominanz','[-]', 0.9, Dominanz);
  ParCreate('rgr0','[-]', 0.33, rgr0);
  ParCreate('rgr_dec','[-]', 0.0001, rgr_dec);
  ParCreate('rgr_min','[]',0.05, rgr_min);
  ParCreate('BSTD','[1/m2]', 3.5,  bstd);
  ParCreate('SLA0','[cm2/g]', 120,  SLA0);
  ParCreate('SLA_pardec','[cm2/g/MJ]', -14,  SLA_pardec);
  ParCreate('SLA_ndec','[cm2/g]', -2.765866,  SLA_ndec);
  ParCreate('SLA_Sizedec','[cm2/g/MJ]', -0.008732,  SLA_Sizedec);

  ParCreate('Senrate','[g/(g*°C*d)]',  0.001,  Senrate);
  ParCreate('Abrate','[g/(g*°C*d)]',   0.001,  Abrate);
  ParCreate('rgr_crit','[g/(g*°C*d)]', 0.05,  rgr_crit);
  ParCreate('FTransDM','[g/(g*°C*d)]', 0.25,  FTransDM);

  For i :=  1 to maxLeaves do begin
    StateCreate('SLeaf_mass_'+IntToStr(i),'[g/pl]',0.0,false, SLeaf_mass[i]);
    StateCreate('SLeaf_area'+IntToStr(i),'[cm2/pl]',0.0, false, SLeaf_area[i]);
    StateCreate('TransLMass_'+IntToStr(i),'[g/pl]',0.0, false, TransLMass[i]);
    SLeaf_mass[i].writetoFile := false;
    SLeaf_area[i].writetoFile := false;
    TransLmass[i].writetofile := false;
  end;

end;

constructor TBkGrowthSL.create (AOwner : TComponent);


begin

  inherited create(AOwner);
  CreateAll;
end;

procedure TBkGrowthSL.Set_GlobMod(value:TMod);

begin
  inherited Set_GlobMod(value);
  CreateAll;

end;


procedure TBkGrowthSL.Init(var GlobMod: Tmod);

var
  i, j :integer;
  SumIln : real;
  frac : array[1..20] of real;
  sla_act : real;

begin
  inherited Init(GlobMod);

  NSenLeaves.v := 0.0;
  NAbLeaves.v := 0.0;

  sumIln := 0.0;
  for i :=   1 to trunc(bzs.v) do begin
   frac[i] := power(trunc(bzs.v)+1-i, 2);
   SumIln := SumIln+frac[i];
   LeafStatus_arr[i] := green;
  end;
  for i :=   1 to trunc(bzs.v) do
    frac[i] := frac[i]/sumIln;



  for i := 1 to trunc(bzs.v) do begin
      sleaf_mass[i].v := DMLeaf.v*frac[i]*1/bstd.v;
      sla_act := SLA0.v+PARav.v*SLA_pardec.v+sla_Sizedec.v*sleaf_mass[i].v+sla_ndec.v*i;
      sleaf_area[i].v := sleaf_mass[i].v * 100{sla_act};
  end;

  for i := 1 to maxLeaves do begin
    TransLmass[i].v   := 0.0;
    StructLMass[i]  := 0.0;
    Translocated[i] := 0.0;
//    ITransMass[i]   := 0.0;
    DMTransRate[i]  := 0.0;
    DMAbortRate[i]  := 0.0;
    LAAbortRate[i]  := 0.0;
    STransrate[i]   := 0.0;
    SAbortrate[i]   := 0.0;
    rgr_[i]         := rgr0.v;
    for j := 1 to maxpardays do
      rgr_mat[i,j] := rgr0.v;
    TSsen[i]        := SenTsumLeaf.v+i/Senrate.v;
    TSab[i]         := MaxTSumLeaf.v+i/AbRate.v;
  end;

  For i := trunc(bzs.v)+1 to maxLeaves do begin
    sleaf_mass[i].v := 0.0;
    sleaf_area[i].v := 0.0;
    leafstatus_arr[i] := none;

  end;

  SumTrans.v := 0.0;
  SumAbort.v := 0.0;
  rgr.v := rgr0.v;
  sum_rgr := rgr0.v;
  Tempsum.v := 0.0;
  LATotal.v := LAI.v;
end;



procedure TBkGrowthSL.CalcRates;

var
  i,j              : integer;
  pot_gr, rest   : double;
  sla_act        : real;
  Irel           : array[1..MaxLeaves] of real;
  rgr_act        : real;

begin
  inherited calcRates;
  Tempsum.c := Temp.v;
  DMTrans.v := 0.0;
  DMAbort.v   := 0.0;
  for i := 1 to trunc(bzs.v) do begin
    SLeaf_mass[i].c := 0.0;
    SLeaf_area[i].c := 0.0;
  end;

  if TempSum.v > SenTsumLeaf.v then
    NsenLeaves.c := Temp.v*Senrate.v;

  if TempSum.v > MaxTSumLeaf.v then
    NAbLeaves.c := temp.v*AbRate.v;

  for i := 1 to trunc(bzs.v) do begin
    If SLeaf_mass[i].v < 0.0 then SLeaf_Mass[i].v := 0.0;
    // Newly formed leaves are initiated as green

    If (LeafStatus_arr[i] = none) then begin
      LeafStatus_arr[i] := green;
    end;
    //
    // when the leaf growth ceases the senescence process starts
    //  the status of the leaf is switched to senescing

    if ((rgr_[i]<rgr_crit.v*rgr.v)or(Tempsum.v>(Tssen[i]-250))) and (LeafStatus_arr[i] = green) then begin
      LeafStatus_arr[i] := senescing;
      TransLmass[i].v := FtransDM.v*SLeaf_mass[i].v;
      STransRate[i]  := TransLmass[i].v/(TSsen[i]-Tempsum.v);
    end;

    if (LeafStatus_arr[i] = senescing) then begin
      If TransLmass[i].v > 0.0 then
        DMTransRate[i] := STransrate[i]*Temp.v
      else  begin
        DMTransRate[i]:= 0.0;

      end;
      if DMTransrate[i] < 0.0 then
         DMTransrate[i] := 0.0;
      TransLmass[i].v := TransLmass[i].v-DMTransRate[i]*GlobTime.c;
      Translocated[i] := translocated[i]+DMTransRate[i]*GlobTime.c;
    end;
    SumTrans.v := sumTrans.v+DMTransrate[i]*GlobTime.c*BSTD.v;

    DMTrans.v := DMTrans.v+DMTransrate[i];

   if trunc(NsenLeaves.v) >= I then begin
    if (TSab[i]-TempSum.v)<100 then begin
      If LeafStatus_arr[i] <> senescent  then begin
        SAbortRate[i]  := -(SLeaf_mass[i].v-Sleaf_mass[i].c*globtime.c)/(TSab[i]-Tempsum.v);
        DMTransrate[i]  := 0.0;
        LAAbortrate[i]  := -(SLeaf_area[i].v-Sleaf_area[i].c*globtime.c)/(TSab[i]-Tempsum.v);
        rgr_[i]         := 0.0;
      end;
      If LeafStatus_arr[i] = senescent then begin
        DMAbortRate[i] := SAbortRate[i]*Temp.v;
        SLeaf_mass[i].c := DMAbortRate[i];
        SLeaf_area[i].c := LAAbortRate[i]*Temp.v;
      end;
      Leafstatus_arr[i] := senescent;
      {SLeaf_area[i].v := 0.0;}
     end;
   end;
   DMAbort.v := DMAbort.v + DMAbortrate[i];
   SumAbort.v := SumAbort.v -DMAbortrate[i]*BSTD.v;

   if trunc(NabLeaves.v) >= I then begin
      Leafstatus_arr[i] := aborted;
      SLeaf_area[i].v := 0.0;
      SLeaf_mass[i].v := 0.0;
      SLeaf_area[i].c := 0.0;
      SLeaf_mass[i].c := 0.0;
      DMAbortrate[i]  :=0.0;

    end;


  end;

  If Vern.v > 1.0 then begin
    rgr.v := rgr.v-rgr_dec.v*Temp.v;
    if rgr.v < rgr_min.v then
      rgr.v := rgr_min.v ;
   end;
  rest := (AssiToLeaf.v)/BSTD.v;
// zunächst ist der gesamte Trockenmassezuwachs plus Translokationsmenge verfügbar
  for I := trunc(BZs.v) downto 1 do begin
  If (leafstatus_arr[i]=senescing) then begin
    if DMTransrate[i] > SLeaf_mass[i].v/GlobTime.c then
       DMTransrate[i] := SLeaf_mass[i].v/GlobTime.c;

     sleaf_mass[i].c   := -DmTransRate[i];
     rgr_[i] := 0.0;
  end else begin
  if leafstatus_arr[i] = green then begin
    If (sleaf_mass[i].v <= 0.0) then begin
// Wenn das Blatt noch nicht angelegt ist, wird es mit 1 cm2 initialisiert
      sleaf_area[i].v := 1.0;
// die Blattmasse wird unter Benutzung der SLA entsprechend initialisiert
      sleaf_mass[i].v := sleaf_area[i].v/50.0;
    end;

   pot_gr := sleaf_mass[i].v*rgr.v*Temp.v;
// Berechnung der potentiellen Wachstumsrate
     If pot_gr < Dominanz.v*rest then begin
// ist die potentielle Zuwachsrate kleiner als die zur Verteilung stehende Assimilatmenge ?
       sleaf_mass[i].c := pot_gr;
       rest := rest-pot_gr;
     end else begin
       if (rest > 0.0) then begin
         sleaf_mass[i].c := Dominanz.v*rest;
         rest := rest-Dominanz.v*rest;
       end;

     end;

     If SLeaf_mass[i].v > 0.0 then begin
       rgr_[i] := 0.0;
       sum_rgr := 0.0;
       rgr_act := Sleaf_mass[i].c/SLeaf_mass[i].v;

       for j := MaxParDays downto 2 do
        rgr_mat[i,j] := rgr_mat[i,j-1];
        rgr_mat[i,1] := rgr_act;
       rgr_[i]:= 0;
       for j := 1 to MAxParDays do
         rgr_[i] := rgr_[i]+rgr_mat[i,j];
       rgr_[i] := rgr_[i]/MaxParDays;

     end;
    end;
   end;
  end;

  for i := 1 to trunc(BZs.v) do begin
     frac_growth[i] := 0.0;
     if leafstatus_arr[i] = green then begin
       If AssiToLeaf.v > 0.0 then
          frac_growth[i] := Sleaf_mass[i].c/(AssiToLeaf.v/BSTD.v)
        else Frac_growth[i] := 0.0;
        Sleaf_mass[i].c := Sleaf_mass[i].c+rest*frac_growth[i];
     end;
  end;


  for i := 1 to trunc(BZs.v) do begin
    if leafstatus_arr[i] < senescent then begin
    sla_act := SLA0.v+PARav.v*SLA_pardec.v+sla_Sizedec.v*sleaf_mass[i].v+sla_ndec.v*i;
    if SLeaf_Area[i].v > 3.0 then
{     SLeaf_Area[i].c := (sleaf_mass[i].v+sleaf_mass[i].c*GlobTime.c)*SLA_act-sleaf_area[i].v}
      SLeaf_Area[i].c := sleaf_mass[i].c*(SLA_act+sleaf_mass[i].v*sla_Sizedec.v)
    else
     SLeaf_Area[i].c:= sla_act*Sleaf_mass[i].c;
    end;
  end;

  LAI.c := 0.0;
  LAI.v := 0.0;
  DMLeaf.c := 0.0;
  LATotal.v := 0.0;
//  DMLeaf.v := 0.0;
  DMLeaf.c := 0.0;
  for i := 1 to trunc(BZs.v) do begin
    DMLeaf.c := DMLeaf.c+SLeaf_mass[i].c*Bstd.v;
    LATotal.v := LAtotal.v+SLeaf_area[i].v*Bstd.v/1e4;
    If LeafStatus_arr[i] < senescent then
      LAI.v := LAI.v+SLeaf_area[i].v*Bstd.v/1e4;
  end;


end;

procedure TBkGrowthSL.Integrate;

var
  i : integer;

begin
inherited integrate;


{$IFDEF GROUP5}

  LMass_1_5.v := 0.0;
  LArea_1_5.v := 0.0;
  for i := 1 to 5 do begin
    LMass_1_5.v := LMass_1_5.v + Sleaf_mass[i].v;
    LArea_1_5.v := LArea_1_5.v + SLeaf_area[i].v;
  end;
  if Lmass_1_5.v > 0.0 then
    SLA_1_5.v   := LArea_1_5.v/Lmass_1_5.v
  else
    SLA_1_5.v := 0.0;


  LMass_6_10.v := 0.0;
  LArea_6_10.v := 0.0;
  for i := 6 to 10 do begin
    LMass_6_10.v := LMass_6_10.v + Sleaf_mass[i].v;
    LArea_6_10.v := LArea_6_10.v + SLeaf_area[i].v;
  end;
  if Lmass_6_10.v > 0.0 then
    SLA_6_10.v   := LArea_6_10.v/Lmass_6_10.v
  else
    SLA_6_10.v := 0.0;


  LMass_11_15.v := 0.0;
  LArea_11_15.v := 0.0;
  for i := 11 to 15 do begin
    LMass_11_15.v := LMass_11_15.v + Sleaf_mass[i].v;
    LArea_11_15.v := LArea_11_15.v + SLeaf_area[i].v;
  end;
  if Lmass_11_15.v > 0.0 then
    SLA_11_15.v   := LArea_11_15.v/Lmass_11_15.v
  else
    SLA_11_15.v := 0.0;




  LMass_16_20.v := 0.0;
  LArea_16_20.v := 0.0;
  for i := 16 to 20 do begin
    LMass_16_20.v := LMass_16_20.v + Sleaf_mass[i].v;
    LArea_16_20.v := LArea_16_20.v + SLeaf_area[i].v;
  end;
  if Lmass_16_20.v > 0.0 then
    SLA_16_20.v   := LArea_16_20.v/Lmass_16_20.v
  else
    SLA_16_20.v := 0.0;


  LMass_21_25.v := 0.0;
  LArea_21_25.v := 0.0;
  for i := 21 to 25 do begin
    LMass_21_25.v := LMass_21_25.v + Sleaf_mass[i].v;
    LArea_21_25.v := LArea_21_25.v + SLeaf_area[i].v;
  end;
  if Lmass_21_25.v > 0.0 then
    SLA_21_25.v   := LArea_21_25.v/Lmass_21_25.v
  else
    SLA_21_25.v := 0.0;

  LMass_26_30.v := 0.0;
  LArea_26_30.v := 0.0;
  for i := 26 to 30 do begin
    LMass_26_30.v := LMass_26_30.v+ Sleaf_mass[i].v;
    LArea_26_30.v := LArea_26_30.v  + SLeaf_area[i].v;
  end;
  if Lmass_26_30.v > 0.0 then
    SLA_26_30.v   := LArea_26_30.v/Lmass_26_30.v
  else
    SLA_26_30.v := 0.0;

  LMass_31_35.v := 0.0;
  LArea_31_35.v := 0.0;
  for i := 31 to 35 do begin
    LMass_31_35.v := LMass_31_35.v+ Sleaf_mass[i].v;
    LArea_31_35.v := LArea_31_35.v  + SLeaf_area[i].v;
  end;
  if Lmass_31_35.v > 0.0 then
    SLA_31_35.v   := LArea_31_35.v/Lmass_31_35.v
  else
    SLA_31_35.v := 0.0;

{$ENDIF}

{$IFDEF GROUP3}

  LMass_1_3.v := 0.0;
  LArea_1_3.v := 0.0;
  for i := 1 to 3 do begin
    LMass_1_3.v := LMass_1_3.v+ Sleaf_mass[i].v;
    LArea_1_3.v := LArea_1_3.v  + SLeaf_area[i].v;
  end;
  if Lmass_1_3.v > 0.0 then
    SLA_1_3.v   := LArea_1_3.v/Lmass_1_3.v
  else
    SLA_1_3.v := 0.0;

  LMass_4_6.v := 0.0;
  LArea_4_6.v := 0.0;
  for i := 4 to 6 do begin
    LMass_4_6.v := LMass_4_6.v+ Sleaf_mass[i].v;
    LArea_4_6.v := LArea_4_6.v  + SLeaf_area[i].v;
  end;
  if Lmass_4_6.v > 0.0 then
    SLA_4_6.v   := LArea_4_6.v/Lmass_4_6.v
  else
    SLA_4_6.v := 0.0;

  LMass_7_9.v := 0.0;
  LArea_7_9.v := 0.0;
  for i := 7 to 9 do begin
    LMass_7_9.v := LMass_7_9.v+ Sleaf_mass[i].v;
    LArea_7_9.v := LArea_7_9.v  + SLeaf_area[i].v;
  end;
  if Lmass_7_9.v > 0.0 then
    SLA_7_9.v   := LArea_7_9.v/Lmass_7_9.v
  else
    SLA_7_9.v := 0.0;

  LMass_10_12.v := 0.0;
  LArea_10_12.v := 0.0;
  for i := 10 to 12 do begin
    LMass_10_12.v := LMass_10_12.v+ Sleaf_mass[i].v;
    LArea_10_12.v := LArea_10_12.v  + SLeaf_area[i].v;
  end;
  if Lmass_10_12.v > 0.0 then
    SLA_10_12.v   := LArea_10_12.v/Lmass_10_12.v
  else
    SLA_10_12.v := 0.0;

  LMass_13_15.v := 0.0;
  LArea_13_15.v := 0.0;
  for i := 13 to 15 do begin
    LMass_13_15.v := LMass_13_15.v+ Sleaf_mass[i].v;
    LArea_13_15.v := LArea_13_15.v  + SLeaf_area[i].v;
  end;
  if Lmass_13_15.v > 0.0 then
    SLA_13_15.v   := LArea_13_15.v/Lmass_13_15.v
  else
    SLA_13_15.v := 0.0;

  LMass_16_18.v := 0.0;
  LArea_16_18.v := 0.0;
  for i := 16 to 18 do begin
    LMass_16_18.v := LMass_16_18.v+ Sleaf_mass[i].v;
    LArea_16_18.v := LArea_16_18.v  + SLeaf_area[i].v;
  end;
  if Lmass_16_18.v > 0.0 then
    SLA_16_18.v   := LArea_16_18.v/Lmass_16_18.v
  else
    SLA_16_18.v := 0.0;

  LMass_19_21.v := 0.0;
  LArea_19_21.v := 0.0;
  for i := 19 to 21 do begin
    LMass_19_21.v := LMass_19_21.v+ Sleaf_mass[i].v;
    LArea_19_21.v := LArea_19_21.v  + SLeaf_area[i].v;
  end;
  if Lmass_19_21.v > 0.0 then
    SLA_19_21.v   := LArea_19_21.v/Lmass_19_21.v
  else
    SLA_19_21.v := 0.0;

  LMass_22_24.v := 0.0;
  LArea_22_24.v := 0.0;
  for i := 22 to 24 do begin
    LMass_22_24.v := LMass_22_24.v+ Sleaf_mass[i].v;
    LArea_22_24.v := LArea_22_24.v  + SLeaf_area[i].v;
  end;
  if Lmass_22_24.v > 0.0 then
    SLA_22_24.v   := LArea_22_24.v/Lmass_22_24.v
  else
    SLA_22_24.v := 0.0;

  LMass_25_27.v := 0.0;
  LArea_25_27.v := 0.0;
  for i := 25 to 27 do begin
    LMass_25_27.v := LMass_25_27.v+ Sleaf_mass[i].v;
    LArea_25_27.v := LArea_25_27.v  + SLeaf_area[i].v;
  end;
  if Lmass_25_27.v > 0.0 then
    SLA_25_27.v   := LArea_25_27.v/Lmass_25_27.v
  else
    SLA_25_27.v := 0.0;

  LMass_28_30.v := 0.0;
  LArea_28_30.v := 0.0;
  for i := 28 to 30 do begin
    LMass_28_30.v := LMass_28_30.v + Sleaf_mass[i].v;
    LArea_28_30.v := LArea_28_30.v + SLeaf_area[i].v;
  end;
  if Lmass_28_30.v > 0.0 then
    SLA_28_30.v   := LArea_28_30.v/Lmass_28_30.v
  else
    SLA_28_30.v := 0.0;

{$ENDIF}
  slaav.v := lai.v/dmleaf.v*10000;

  DMsenLeaf.v := 0.0;
  DMGreenLeaf.v := 0.0;
  TotalLeafArea.v := 0.0;
  TotalLeafMass.v := 0.0;
  for i := 1 to trunc(BZs.v) do begin
      if leafstatus_arr[i]<senescent then
        TotalLeafArea.v := TotalLeafArea.v + SLeaf_area[i].v*BSTD.v;
      if LeafStatus_arr[i]>senescing then
        DMSenLeaf.v := DMSenLeaf.v+SLeaf_mass[i].v*BSTD.v;
      If LeafStatus_arr[i] < Senescent then
        DMGreenLeaf.v := DmGreenLeaf.v+SLeaf_mass[i].v*BSTD.v;
      TotalLeafMass.v := TotalLeafMass.v + SLeaf_Mass[i].v*BSTD.v;
  end;
  slaav.v := totalleafarea.v/totalleafmass.v;

end;


procedure Register;

begin
  RegisterComponents('CauliSim', [TBKGrowthSL]);
end;


end.
