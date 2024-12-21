unit FormSGA;

{ A Simple Genetic Algorithm - SGA - v1.0 }
{ (c)   David Edward Goldberg  1986       }
{       All Rights Reserved               }

{$M+}

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.StdCtrls, vcl.ComCtrls, NumEdit, vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.TeEngine, VCLTee.Chart, VCLTee.series,
  OverlayImage, MathImge, UState, UMod, vcl.Grids, AdvGrid, vcl.Buttons, BaseGrid,
  VclTee.TeeGDIPlus;

const
  maxpop = 1000;
  maxstring = 600;
  maxparms = 10;

  rep_fn = 'GA_report.txt';

type

  TRange = record
    max: real;
    min: real;

  end;

  Tparmparm = record { parameters of the parameter }
    name, units: string;
    lparm: integer; { length of the parameter }
    value, maxparm, minparm: real; { parameter & range }
  end;
  Tparmspecs = array[1..maxparms] of Tparmparm;

  allele = boolean; { Allele = bit position }
  chromosome = array[1..maxstring] of allele; { String of bits }

  Tindividual = record
    chrom: chromosome; { Genotype = bit string }
    x: real; { Phenotype = unsigned integer }
    parm: TParmspecs;
    objective: real; // unscaled fitness
    fitness: real; { scaled Objective function value }
    parent1, parent2, xsite: integer; { parents & cross pt }
  end;

  Tpopulation = array[1..maxpop] of Tindividual;

  TSGA = class(TObject)
  private
    rep: Textfile; // reportfile
    f_scaling: boolean;
      // true for scaling of objective function during optimization
    fmultiple: real;
    nparms: integer;

    ParSave: array[1..maxParms] of TPar;
    { Private-Deklarationen }

    procedure report(gen: integer);
    procedure initreport;
    procedure Initdata;

    function scale(u, a, b: real): real;

    procedure prescale(umax, uavg, umin: real; var a, b: real);
                  { Calculate scaling coefficients for linear scaling }

    procedure scalepop(popsize: integer; var maxfit, avgfit, minfit, sumfitness:
      real;
      var pop: TPopulation);

    function decode(chrom: chromosome; lbits: integer): real;
    function select(popsize: integer; sumfitness: real;
      var pop: TPopulation): integer;
                                      { Select a single individual via roulette wheel selection }
    function mutation(alleleval: allele; pmutation: real;
      var nmutation: integer): allele;
                                       { Mutate an allele w/ pmutation, count number of mutations }

    procedure crossover(var parent1, parent2, child1, child2: chromosome;
      var lchrom, ncross, nmutation, jcross: integer;
      var pcross, pmutation: real);
        { Cross 2 parent strings, place in 2 child strings }

    procedure extract_parm(var chromfrom, chromto: chromosome;
      var jposition, lchrom, lparm: integer);
                       { Extract a substring from a full string }

    procedure decode_parms(var nparms, lchrom: integer;
      var chrom: chromosome;
      var parms: Tparmspecs);

  public
    { Public-Deklarationen }
    ParList: TList; // List of Parameters to be optimized
    oldpop, newpop: Tpopulation; { Two non-overlapping populations }
    popsize, // size of population
      lchrom, // length of the total chromosome [bit]
      gen, // Generation
      maxgen // maximum number of Generations
      : integer; { Integer global variables }
    pcross, // propability of crossing over
      pmutation, // propability of mutation
      sumfitness
      : real; { Real global variables }
    nmutation, // number of mutations
      ncross // number of crossing overs
      : integer; { Integer statistics }

    avgfit, // average fitness of population
      maxfit, // maximum fitness of popultation
      minfit: real; { Real statistics }

    Model: TMod;

    SaveParList: TStringList;

    Bestparms: Tparmspecs;

    constructor create; virtual;
    procedure set_model(Model: TMod); virtual;
    procedure Optimize; virtual;
    function obj_func(Parms: Tparmspecs): real;
    procedure randomize;
    procedure generation;
    procedure initpop;
    procedure initialize;
    procedure writechrom(var out: text; chrom: chromosome; lchrom: integer);
    procedure statistics(popsize: integer;
      var max, avg, min, sumfitness: real;
      var pop: Tpopulation); { Calculate population statistics }

    // procedure calc_objective; virtual;
  published
    property P_Popsize: integer read popsize write popsize;
    property P_lchrom: integer read lchrom write lchrom;
    property p_maxgen: integer read maxgen write maxgen;
    property p_pmutation: real read pmutation write pmutation;
    property p_pcross: real read pcross write pcross;
    property scaling: boolean read f_scaling write f_scaling;
    property Cmult: real read fmultiple write fmultiple;

  end;

  TFormGAOpt = class(TForm)
    Button1: TButton;
    PageControl1: TPageControl;
    TabSheetTextOutput: TTabSheet;
    Memo1: TMemo;
    TabSheetOptparams: TTabSheet;
    Labelpopulationsize: TLabel;
    Labelchromosomelength: TLabel;
    Labelmaxgenerations: TLabel;
    Labelcrossoverprobability: TLabel;
    Labelmutationprobability: TLabel;
    IntEditPopSize: TIntEdit;
    IntEditChromLength: TIntEdit;
    IntEditMaxGen: TIntEdit;
    FloatEditCrossProb: TFloatEdit;
    FloatEditMutProb: TFloatEdit;
    TabsheetFitness: TTabSheet;
    Chart1: TChart;
    TabSheetParameter: TTabSheet;
    ChartParms: TChart;
    TabSheet3DOut: TTabSheet;
    AdvStringGridParams: TAdvStringGrid;
    TabSheet3: TTabSheet;
    SrcLabel: TLabel;
    DstLabel: TLabel;
    IncludeBtnPar: TSpeedButton;
    IncAllBtnPar: TSpeedButton;
    ExcludeBtnPar: TSpeedButton;
    ExAllBtnPar: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    IncludeBtnData: TSpeedButton;
    IncAllBtnData: TSpeedButton;
    ExcludeBtnData: TSpeedButton;
    ExAllBtnData: TSpeedButton;
    Label3: TLabel;
    Label4: TLabel;
    SrcListPar: TListBox;
    DstListPar: TListBox;
    SrcListData: TListBox;
    DstListData: TListBox;
    LabelWeightOption: TLabel;
    Label5: TLabel;
    ComboBoxWeightOption: TComboBox;
    StatusBar1: TStatusBar;
    MathImage1: TMathImage;

    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IntEditPopSizeExit(Sender: TObject);
    procedure IntEditMaxGenExit(Sender: TObject);
    procedure FloatEditCrossProbExit(Sender: TObject);
    procedure FloatEditMutProbExit(Sender: TObject);
    procedure InitParGrid;
    procedure IncludeBtnParClick(Sender: TObject);
    procedure IncAllBtnParClick(Sender: TObject);
    procedure ExcludeBtnParClick(Sender: TObject);
    procedure ExAllBtnParClick(Sender: TObject);
    procedure IncludeBtnDataClick(Sender: TObject);
    procedure IncAllBtnDataClick(Sender: TObject);
    procedure ExcludeBtnDataClick(Sender: TObject);
    procedure ExAllBtnDataClick(Sender: TObject);
    procedure SetItem(List: TListBox; Index: Integer);
    function GetFirstSelection(List: TCustomListBox): Integer;
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetButtons;

    procedure UpdateParaValueListBox;
    procedure FormGAActivate;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    SGA: TSGA;

  end;

var

  FormGAOpt: TFormGAOpt;
  MaxSeries, AvSeries, MinSeries: TFastLIneSeries;
  ParSeriesArr: array[1..maxparms] of TFastLineSeries;

  rep: textfile;

implementation

{$R *.DFM}

uses
  math, UMeasValue;

procedure TSGA.set_model(Model: TMod);

var
  i: integer;
  NewPar: TPar;
begin
  Model := model;
  for I := 0 to model.SelParList.Count - 1 do begin
    NewPar := TPar(Model.SelParList.objects[i]);
    Parlist.add(Newpar);
    Newpar.max := 10 * Newpar.V;
    NewPar.min := 0.1 * Newpar.V;
  end;
end;

procedure TSGA.writechrom(var out: text; chrom: chromosome; lchrom: integer);
{ Write a chromosome as a string of 1's (true's) and 0's (false's) }
var
  j: integer;
begin
  for j := lchrom downto 1 do
    if chrom[j] then write(out, '1')
    else write(out, '0');
end;

procedure TSGA.report(gen: integer);
{ Write the population report }
const
  linelength = 132;
var
  i, j: integer;
begin
  for i := 1 to linelength do
    write(rep, '-');
  writeln(rep);
  for i := 1 to 50 do
    write(rep, ' ');
  writeln(rep, 'Population Report');
  for i := 1 to 23 do
    write(rep, ' ');
  write(rep, 'Generation ', gen - 1: 2);
  for i := 1 to 57 do
    write(rep, ' ');
  writeln(rep, 'Generation ', gen: 2);
  writeln(rep);
  write(rep,
    ' #                string                    x             y            fitness');
  write(rep, '            #  parents xsite');
  writeln(rep,
    '               string                    x             y            fitness');
  for i := 1 to linelength do
    write(rep, '-');
  writeln(rep);
  for j := 1 to popsize do begin
    write(rep, j: 2, ')  ');
     { Old string }
    with oldpop[j] do begin
      writechrom(rep, chrom, lchrom);
      write(rep, ' ', parm[1].value: 10: 2, ' ', parm[2].value: 10: 2, ' ',
        fitness: 6: 4, '      |');
    end;
   { New string }
    with newpop[j] do begin
      write(rep, '    ', j: 2, ') (', parent1: 2, ',', parent2: 2, ')   ',
        xsite: 2, '   ');
      writechrom(rep, chrom, lchrom);
      writeln(rep, ' ', parm[1].value: 10: 2, ' ', parm[2].value: 10: 2, ' ',
        fitness: 6: 4);
    end;
  end;
  for i := 1 to linelength do
    write(rep, '-');
  writeln(rep);
 { Generation statistics and accumulated values }
  writeln(rep, ' Note: Generation ', gen: 2, ' & Accumulated Statistics: '
    , ' max=', maxfit: 6: 4, ',  min=', minfit: 6: 4, ',  avg=', avgfit: 6: 4,
      ',  sum='
    , sumfitness: 6: 4, ',  nmutation=', nmutation, ',  ncross= ', ncross);
  write(rep, 'Best Parameters: ');
  for i := 1 to nparms do
    write(rep, 'Par # ', i, ' ', Bestparms[i].value: 10: 4, '  ');
  writeln(rep);

  MaxSeries.AddXY(gen, maxfit);
  AvSeries.AddXY(gen, avgfit);
  MinSeries.AddXY(gen, minfit);
  for i := 1 to nparms do
    ParSeriesArr[i].AddXY(gen, BestParms[i].value);

  FormGAopt.chart1.Repaint;
  FormGAopt.Chart1.Show;
 //MaxSeries.AddXY(gen,max);

  for i := 1 to linelength do
    write(rep, '-');
  writeln(rep);
  writeln(rep);
  writeln(rep);
  writeln(rep);
 //closefile(rep);
end;

function tsga.decode(chrom: chromosome; lbits: integer): real;
{ Decode string as unsigned binary integer - true=1, false=0 }
var
  j: integer;
  accum, powerof2: real;
begin
  accum := 0.0;
  powerof2 := 1;
  for j := 1 to lbits do begin
    if chrom[j] then accum := accum + powerof2;
    powerof2 := powerof2 * 2;
  end;
  decode := accum;
end;

procedure tsga.extract_parm(var chromfrom, chromto: chromosome;
  var jposition, lchrom, lparm: integer);
{ Extract a substring from a full string }
var
  j, jtarget: integer;
begin
  j := 1;
  jtarget := jposition + lparm - 1;
  if jtarget > lchrom then jtarget := lchrom; { Clamp if excessive }
  while (jposition <= jtarget) do begin
    chromto[j] := chromfrom[jposition];
    jposition := jposition + 1;
    j := j + 1;
  end;
end;

function map_parm(x, maxparm, minparm, fullscale: real): real;
{ Map an unsigned binary integer to range [minparm,maxparm] }
begin
  map_parm := minparm + (maxparm - minparm) / fullscale * x
end;

procedure tsga.decode_parms(var nparms, lchrom: integer;
  var chrom: chromosome;
  var parms: Tparmspecs);
var
  j, jposition: integer;
  chromtemp: chromosome; { Temporary string buffer }
begin
  j := 1; { Parameter counter }
  jposition := 1; { String position counter }
  repeat
    with parms[j] do if lparm > 0 then begin
        extract_parm(chrom, chromtemp, jposition, lchrom, lparm);
        parms[j].value := map_parm(decode(chromtemp, lparm {, range}),
          maxparm, minparm, power(2.0, lparm) - 1.0);
      end else value := 0.0;
    j := j + 1;
  until j > nparms;
end;

procedure page(var out: text);
{ Issue form feed to device or file }
begin
  write(out, chr(12)) end;

procedure repchar(var out: text; ch: char; repcount: integer);
{ Repeatedly write a character to an output device }
var
  j: integer;
begin
  for j := 1 to repcount do write(out, ch) end;

procedure skip(var out: text; skipcount: integer);
{ Skip skipcount lines on device out }
var
  j: integer;
begin
  for j := 1 to skipcount do writeln(out) end;

{ random.apb: contains random number generator and related utilities
              including advance_random, warmup_random, random, randomize,
              flip, rnd }

{ Global variables - Don't use these names in other code }
var
  oldrand: array[1..55] of real; { Array of 55 random numbers }
  jrand: integer; { current random }

procedure advance_random;
{ Create next batch of 55 random numbers }
var
  j1: integer;
  new_random: real;
begin
  for j1 := 1 to 24 do begin
    new_random := oldrand[j1] - oldrand[j1 + 31];
    if (new_random < 0.0) then new_random := new_random + 1.0;
    oldrand[j1] := new_random;
  end;
  for j1 := 25 to 55 do begin
    new_random := oldrand[j1] - oldrand[j1 - 24];
    if (new_random < 0.0) then new_random := new_random + 1.0;
    oldrand[j1] := new_random;
  end;
end;

procedure warmup_random(random_seed: real);
{ Get random off and runnin }
var
  j1, ii: integer;
  new_random, prev_random: real;
begin
  oldrand[55] := random_seed;
  new_random := 1.0e-9;
  prev_random := random_seed;
  for j1 := 1 to 54 do begin
    ii := 21 * j1 mod 55;
    oldrand[ii] := new_random;
    new_random := prev_random - new_random;
    if (new_random < 0.0) then new_random := new_random + 1.0;
    prev_random := oldrand[ii]
  end;
  advance_random; advance_random; advance_random;
  jrand := 0;
end;

function random: real;
{ Fetch a single random number between 0.0 and 1.0 - Subtractive Method }
{ See Knuth, D. (1969), v. 2 for details                                }
begin
  jrand := jrand + 1;
  if (jrand > 55) then begin
    jrand := 1; advance_random end;
  random := oldrand[jrand];
end;

function flip(probability: real): boolean;
{ Flip a biased coin - true if heads }
begin
  if probability = 1.0 then flip := true
  else flip := (random <= probability);
end;

function rnd(low, high: integer): integer;
{ Pick a random integer between low and high }
var
  i: integer;
begin
  if low >= high then i := low
  else begin
    i := trunc(random * (high - low + 1) + low);
    if i > high then i := high;
  end;
  rnd := i;
end;

procedure Tsga.randomize;
{ Get seed number for random and start it up }
//var randomseed:real;
begin
 {repeat
  write('Enter seed random number (0.0..1.0) > '); readln(randomseed);
 until (randomseed>0) and (randomseed<1.0);}
  warmup_random(random());
end;

function Tsga.obj_func(Parms: Tparmspecs): real;
var
  i: Integer;
  ActPar: TPar;
  subModName: string;
  success: boolean;
  SaveContOutput : TContoutput;
begin
  for i := 1 to nparms do begin {Beginn Schleife über Parameter }
    ActPar := Tpar(Model.SelParList.Objects[i - 1]);
      {Umkopieren der Parameterwerte
                                                       auf Hilfsobjekt}
    parSave[i] := ActPar; { Umschreiben in Sicherungsarray}
    model.GetParameter(ActPar.name, ActPar, Submodname, success);

    ActPar.v := Parms[i].value;
    model.ParamInifile.WriteFloat(Submodname, ActPar.name, ActPar.V);
    Tpar(Model.SelParList.Objects[i - 1]).v := ActPar.v;
      {Änderung des Modellparameters }
  end;

  SaveContOutput := model.OptContOutput;
  model.OptContOutput := NoContOutput;
  Model.run; { Modelldurchlauf mit geändertem Parameter }
  model.CalcChiSq;
  model.allmeasval.LeastSquares;
     //Obj_func := power(max(0,model.AllMeasVal.ModellingEfficiency),1);
  Obj_func := power(model.AllMeasVal.r2, 10);
  Model.OptContOutput := SaveContOutput;

   {Zurücksetzen der alten Parameter}
  for i := 1 to nparms do begin
    ActPar := Tpar(Model.SelParList.Objects[i - 1]);
    ActPar.v := Parsave[i].v;
    model.ParamInifile.WriteFloat(Submodname, ActPar.name, ActPar.v);
  end;

//    value :=  (200-sqr(parms[1].value)+30*parms[1].value-sqr(parms[2].value)+60*parms[2].value);
//    obj_func := math.max(0.0,value);

end;

procedure TSGA.statistics(popsize: integer;
  var max, avg, min, sumfitness: real;
  var pop: Tpopulation);
{ Calculate population statistics }
var
  j, k: integer;
begin
 { Initialize }
  sumfitness := pop[1].fitness;
  min := pop[1].fitness;
  max := pop[1].fitness;
  for k := 1 to nparms do
    Bestparms[k].value := pop[1].parm[k].value;
 { Loop for max, min, sumfitness }
  for j := 2 to popsize do with pop[j] do begin
      sumfitness := sumfitness + fitness; { Accumulate fitness sum }
      if fitness > max then begin
        max := fitness; { New max }
        for k := 1 to nparms do
          Bestparms[k].value := parm[k].value;
      end;
      if fitness < min then min := fitness; { New min }
    end;
 { Calculate average }
  avg := sumfitness / popsize;
end;

{ 3-operators: Reproduction (select), Crossover (crossover),
               & Mutation (mutation)                        }

function tsga.select(popsize: integer; sumfitness: real;
  var pop: TPopulation): integer;
{ Select a single individual via roulette wheel selection }
var
  rand, partsum: real; { Random point on wheel, partial sum }
  j: integer; { population index }
begin
  partsum := 0.0; j := 0; { Zero out counter and accumulator }
  rand := random * sumfitness; { Wheel point calc. uses random number [0,1] }
  repeat { Find wheel slot }
    j := j + 1;
    partsum := partsum + pop[j].fitness;
  until (partsum >= rand) or (j = popsize);
 { Return individual number }
  select := j;
end;

function tsga.mutation(alleleval: allele; pmutation: real;
  var nmutation: integer): allele;
{ Mutate an allele w/ pmutation, count number of mutations }
var
  mutate: boolean;
begin
  mutate := flip(pmutation); { Flip the biased coin }
  if mutate then begin
    nmutation := nmutation + 1;
    mutation := not alleleval; { Change bit value }
  end else
    mutation := alleleval; { No change }
end;

procedure tsga.crossover(var parent1, parent2, child1, child2: chromosome;
  var lchrom, ncross, nmutation, jcross: integer;
  var pcross, pmutation: real);
{ Cross 2 parent strings, place in 2 child strings }
var
  j: integer;
begin
  if flip(pcross) then begin { Do crossover with p(cross) }
    jcross := rnd(1, lchrom - 1); { Cross between 1 and l-1 }
    ncross := ncross + 1; { Increment crossover counter }
  end else { Otherwise set cross site to force mutation }
    jcross := lchrom;
 { 1st exchange, 1 to 1 and 2 to 2 }
  for j := 1 to jcross do begin
    child1[j] := mutation(parent1[j], pmutation, nmutation);
    child2[j] := mutation(parent2[j], pmutation, nmutation);
  end;
 { 2nd exchange, 1 to 2 and 2 to 1 ]
 if jcross<>lchrom then   { Skip if cross site is lchrom--no crossover }
  for j := jcross + 1 to lchrom do begin
    child1[j] := mutation(parent2[j], pmutation, nmutation);
    child2[j] := mutation(parent1[j], pmutation, nmutation);
  end;
end;

procedure TSGA.generation;
{ Create a new generation through select, crossover, and mutation }
{ Note: generation assumes an even-numbered popsize               }
var
  minvalue: real;
  j, mate1, mate2, jcross: integer;
begin
  minvalue := oldpop[1].fitness;
  for j := 2 to popsize do with oldpop[j] do
      if fitness < minvalue then minvalue := fitness;
  if MinValue <= 0 then begin
    for j := 1 to PopSize do
      oldpop[j].fitness := oldpop[j].fitness + abs(minvalue);
  end;
  Statistics(popsize, maxfit, avgfit, minfit, sumfitness, oldpop);

  j := 1;
  repeat { select, crossover, and mutation until newpop is filled }
    mate1 := select(popsize, sumfitness, oldpop); { pick pair of mates }
    mate2 := select(popsize, sumfitness, oldpop);
  { Crossover and mutation - mutation embedded within crossover }
    crossover(oldpop[mate1].chrom, oldpop[mate2].chrom,
      newpop[j].chrom, newpop[j + 1].chrom,
      lchrom, ncross, nmutation, jcross, pcross, pmutation);
  { Decode string, evaluate fitness, & record parentage date on both children }
    with newpop[j] do begin
    //x := decode(chrom, lchrom, Range);
    //objective := objfunc(x);
    //fitness := objfunc(x);
      decode_parms(nparms, lchrom, chrom, parm);
      Objective := obj_func(parm);
      FormGAopt.mathimage1.Canvas.Pen.Width := 8;
      FormGAopt.mathimage1.Canvas.pen.Color := clred;
      FormGAopt.MathImage1.d3DrawPoint(parm[1].value, parm[2].value, objective);
    //FormGAopt.MathImage1.d3Moveto(parm[1].value, parm[2].value, objective);
    //FormGAopt.mathimage1.d3DrawLineto(0.99*parm[1].value, 0.99*parm[2].value, 0.99*objective);
      fitness := objective;
      parent1 := mate1;
      parent2 := mate2;
      xsite := jcross;
    end;
    with newpop[j + 1] do begin
//    x := decode(chrom, lchrom{, range});
//    objective := objfunc(x);
//    fitness := objfunc(x);
      decode_parms(nparms, lchrom, chrom, parm);
      Objective := obj_func(parm);
      fitness := objective;
      parent1 := mate1;
      parent2 := mate2;
      xsite := jcross;
    end;
  { Increment population index }
    j := j + 2;
  until j > popsize
end;

procedure tsga.prescale(umax, uavg, umin: real; var a, b: real);
{ Calculate scaling coefficients for linear scaling }

const
  fmultiple = 2.0; { Fitness multiple is 2 }

var
  delta: real; { Divisor }

begin
  if umin > (fmultiple * uavg - umax) / (fmultiple - 1.0) { Non-negative test }
    then begin { Normal Scaling }
    delta := umax - uavg;
    a := (fmultiple - 1.0) * uavg / delta;
    b := uavg * (umax - fmultiple * uavg) / delta;
  end else begin { Scale as much as possible }
    delta := uavg - umin;
    if delta <> 0.0 then begin
      a := uavg / delta;
      b := -umin * uavg / delta;
    end else begin
      a := 1;
      b := 0;
    end;

  end;
end;

function tsga.scale(u, a, b: real): real;
{ Scale an objective function value }
begin
  scale := a * u + b
end;

procedure tsga.scalepop(popsize: integer; var maxfit, avgfit, minfit,
  sumfitness: real;
  var pop: TPopulation);
{ Scale entire population }
var
  j: integer;
  a, b: real; { slope & intercept for linear equation }

begin
  if Minfit < 0 then
    for j := 1 to popsize do
      pop[j].objective := Pop[j].objective + abs(minfit);
  minfit := 0.0;

  prescale(maxfit, avgfit, minfit, a, b);
    { Get slope and intercept for function }
  sumfitness := 0.0;
  for j := 1 to popsize do with pop[j] do begin
      fitness := scale(objective, a, b);
      sumfitness := sumfitness + fitness;
    end;
end;

procedure TSGA.initdata;
{ Interactive data inquiry and setup }
begin
  writeln(rep, '--------------------------------');
  writeln(rep, 'A Simple Genetic Algorithm - SGA');
  writeln(rep, ' (c) David Edward Goldberg 1986');
  writeln(rep, '     All Rights Reserved       ');
  writeln(rep, '--------------------------------');
  randomize;
  nmutation := 0;
  ncross := 0;
end;

procedure TSGA.initreport;
{ Initial report }
begin
  writeln(rep, '----------------------------------------------------');
  writeln(rep, '|     A Simple Genetic Algorithm - SGA - v1.0      |');
  writeln(rep, '|      (c)    David Edward Goldberg 1986           |');
  writeln(rep, '|             All Rights Reserved                  |');
  writeln(rep, '----------------------------------------------------');
  writeln(rep);
  writeln(rep);
  writeln(rep, '     SGA Parameters');
  writeln(rep, '     --------------');
  writeln(rep);
  writeln(rep, '   Population size (popsize)          =   ', popsize);
  writeln(rep, '   Chromosome length (lchrom)         =   ', lchrom);
  writeln(rep, '   Maximum # of generation (maxgen)   =   ', maxgen);
  writeln(rep, '   Crossover probability (pcross)     = ', pcross);
  writeln(rep, '   Mutation  probability (pmutation)  = ', pmutation);
  writeln(rep);
  writeln(rep);
  writeln(rep);
  writeln(rep, '     Initial Generation Statistics');
  writeln(rep, '     -----------------------------');
  writeln(rep);
  writeln(rep, '   Initial population maximum fitness = ', maxfit);
  writeln(rep, '   Initial population average fitness = ', avgfit);
  writeln(rep, '   Initial population minimum fitness = ', minfit);
  writeln(rep, '   Initial population sum of fitness  = ', sumfitness);
end;

procedure TSGA.initpop;
{ Initialize a population at random }
var
  j, j1, k: integer;
begin
  for j := 1 to popsize do with oldpop[j] do begin
      for j1 := 1 to lchrom do
        chrom[j1] := flip(0.5); { A fair coin toss }
//   x := decode(chrom,lchrom{, range}); { Decode the string }
//   fitness := objfunc(x);     { Evaluate inital fitness }
      for k := 1 to nparms do begin
        parm[k] := Bestparms[k];
        NewPop[j].parm[k] := Bestparms[k];
      end;
      decode_parms(nparms, lchrom, chrom, parm);
      Objective := obj_func(parm);
      fitness := objective;

      parent1 := 0; parent2 := 0; xsite := 0; { Initialize printout vars }
    end;
end;

procedure TSGA.initialize;
{ Initialization Coordinator }
begin
  randomize;
  initdata;
  initpop;
  statistics(popsize, maxfit, avgfit, minfit, sumfitness, oldpop);
  scalepop(popsize, maxfit, avgfit, minfit, sumfitness, newpop);
  initreport;
end;

procedure TSGA.Optimize;
var
  i: integer;
begin { Main program }
  assignfile(rep, rep_fn);
  rewrite(rep);
  gen := 0; { Set things up }
  initialize;
  repeat { Main iterative loop }
    gen := gen + 1;
    generation;
    statistics(popsize, maxfit, avgfit, minfit, sumfitness, newpop);
    report(gen);
    scalepop(popsize, maxfit, avgfit, minfit, sumfitness, newpop);

    oldpop := newpop; { advance the generation }
  until (gen >= maxgen);
  closefile(rep);
  for I := 1 to self.nparms do
    FormGAopt.AdvStringGridParams.cells[6, i] :=
      floattostrf(self.BestParms[i].value, ffgeneral, 6, 2);
  FormGAopt.Memo1.Lines.LoadFromFile(rep_fn);

end; { End main program }

procedure TFormGAOpt.Button1Click(Sender: TObject);

var
  I, j, k, index: Integer;
  ParName, submodname, DataSeriesName: string;
  SubMod: TSubModel;
  Par: TPar;
  DataSeries: TMeasList;
  StartTime,
    EndTime,
    Timeelapsed: TDateTime;
begin
  self.PageControl1.ActivePage := TabsheetFitness;
  sga.lchrom := 0;

  sga.NParms := self.DstListPar.Items.Count;

  for I := 1 to sga.NParms do begin
    sga.BestParms[i].lparm := StrtoInt(AdvStringGridParams.cells[5, i]);
    sga.BestParms[i].maxparm := StrtoFloat(AdvStringGridParams.cells[4, i]);
    sga.Bestparms[i].minparm := StrtoFloat(AdvStringGridParams.cells[3, i]);
    sga.Bestparms[i].value := StrtoFloat(AdvStringGridParams.cells[2, i]);
    sga.BestParms[i].name := AdvStringGridParams.cells[0, i];
    sga.lchrom := sga.Lchrom + sga.Bestparms[i].lparm;
  end;

  for i := 1 to sga.nparms do begin
    ParSeriesArr[i] := TFastLineSeries.Create(chartParms);
    ParSeriesArr[i].ParentChart := chartParms;
  end;

  self.mathimage1.d3DrawAxes('par1', 'par1', 'fitness', 5, 5, 5, 0, 0, 0, true);
  with AdvStringGridParams do begin
  Cells[0, 0] := 'Name';
  Cells[1, 0] := 'Units';
  Cells[2, 0] := 'value';
  Cells[3, 0] := 'Min';
  Cells[4, 0] := 'Max';
  Cells[5, 0] := 'ChromLength';
  end;

  MaxSeries.Clear;
  AvSeries.clear;
  MinSeries.clear;
  for i := 1 to sga.nparms do
    parSeriesarr[i].clear;

  Screen.Cursor := CrHourGlass;
  case ComboBoxWeightOption.ItemIndex of
    0: sga.Model.LMOptions.WeightOptions := OptNoWeight;
    1: sga.Model.LMOptions.WeightOptions := OptDefaultWeight;
    2: sga.Model.LMOptions.WeightOptions := OptMeasErrorWeight;
  end;

  sga.Model.SelParList.Clear;

  for I := 0 to DstListPar.Items.Count - 1 do begin
    ParName := DstListPar.items[i];
    SubModName := Parname;
    ParName := copy(ParName, pos('.', ParName) + 1, length(ParName) - pos('.',
      ParName)); // Delete Submodelname from string
    SubModName := copy(SubModName, 1, pos('.', SubModname) - 1);
      // Delete Parname from string

    index := sga.model.submodstrlist.indexof(submodname);
    SubMod := TsubModel(sga.Model.subModStrList.objects[index]);
    index := subMod.ParStrList.IndexOf(ParName);
    if index <> -1 then begin
      Par := TPar(SubMod.ParStrList.objects[index]);
      Par.SelForOpt := true;
      sga.model.SelParList.AddObject(Parname, Par);
    end;
  end;

  sga.Model.AllMeasVal.Clear;
  for j := 0 to sga.model.SubModStrList.count - 1 do begin
    SubMod := TsubModel(sga.Model.subModStrList.objects[j]);
    if SubMOd.SomethingMeasured then begin
      for k := 0 to SubMod.DataList.count - 1 do begin
        DataSeries := TMeasList(SubMod.DataList.objects[k]);
        DataSeries.SelForOpt := false;
      end;
    end;
  end;

  for I := 0 to DstListData.Items.Count - 1 do begin
    DataSeriesName := DstListData.items[i];
    for j := 0 to sga.model.SubModStrList.count - 1 do begin
      SubMod := TsubModel(sga.Model.subModStrList.objects[j]);
      if SubMOd.SomethingMeasured then begin
        index := subMod.DataList.IndexOf(DataSeriesName);
        if index <> -1 then begin
          DataSeries := TMeasList(SubMod.DataList.objects[index]);
          DataSeries.SelForOpt := true;
        end;
      end;
    end;
  end;

  if (DstListPar.Items.Count > 0) and (DstListData.Items.Count > 0) then begin
    StartTime := Time;
    Statusbar1.Panels[0].text := 'Optimization running !';
    Statusbar1.Update;

    sga.Optimize;

//    Model.MarquardOptimization;
//    update_StringGrid('reg.dat');
    EndTime := Time;
    TimeElapsed := EndTime - StartTime;
    Statusbar1.Panels[1].text := 'Opt.Time : ' + TimeTostr(Timeelapsed);

    for i := 0 to sga.model.SelParList.count - 1 do begin
      Par := TPar(sga.model.selparlist.objects[i]);
      self.AdvStringGridParams.cells[0, i + 1] := Par.name;
      self.AdvStringGridParams.cells[1, i + 1] := Par.Units;
      self.AdvStringGridParams.cells[2, i + 1] := FloatToStr(Par.V);
    end;
    Statusbar1.Panels[0].text := 'Optimization completed';
    Statusbar1.Update;
  end else begin
    if DstListPar.Items.Count = 0 then ShowMessage('No parameters selected !');
    if DstListData.Items.Count = 0 then ShowMessage('No Data selected !');
  end;
  Screen.Cursor := CrDefault;

end;

constructor TSGA.create;

begin
  inherited create;
  ParList := TList.Create;
  Popsize := 30;
  lchrom := 30;
  maxgen := 100;
  pcross := 6e-1;
  pmutation := 3.33e-2;
end;

procedure TFormGAOpt.FormCreate(Sender: TObject);
var
  i: integer;
begin
  SGA := TSGA.create;
  sga.Popsize := 100;
  //lchrom  := 60;
  sga.maxgen := 30;
  sga.pcross := 3e-1;
  sga.pmutation := 3.33e-2;

  MaxSeries := TFastLineSeries.Create(chart1);
  MaxSeries.Title := 'Max.';
  MaxSeries.ParentChart := chart1;
  AvSeries := TFastLineSeries.Create(chart1);
  AvSeries.ParentChart := chart1;
  AvSeries.title := 'Av.';
  MinSeries := TFastLineSeries.create(chart1);
  MinSeries.ParentChart := chart1;
  MinSeries.title := 'min';
  for i := 1 to sga.nparms do begin
    ParSeriesArr[i] := TFastLineSeries.Create(chartParms);
    ParSeriesArr[i].ParentChart := chartParms;
  end;
  self.IntEditPopSize.Text := InttoStr(sga.PopSize);
  Self.IntEditMaxGen.Text := IntToStr(sga.Maxgen);
  self.FloatEditCrossProb.text := floattoStr(sga.pcross);
  self.FloatEditMutProb.text := floattostr(sga.pmutation);
  self.MathImage1.d3DrawFullWorldBox;

  self.mathimage1.d3DrawAxes('par1', 'par1', 'fitness', 5, 5, 5, 0, 0, 0, true);
  with AdvStringGridParams do begin
  Cells[0, 0] := 'Name';
  Cells[1, 0] := 'Units';
  Cells[2, 0] := 'value';
  Cells[3, 0] := 'Min';
  Cells[4, 0] := 'Max';
  Cells[5, 0] := 'ChromLength';
  Cells[6, 0] := 'NewVal';
  end;

end;

procedure TFormGaOpt.InitPargrid;

var
  par: TPar;
  I: integer;
begin

  if sga.Model <> nil then begin
    for I := 0 to sga.Parlist.count - 1 do begin
      Par := sga.ParList.items[i];
      with AdvStringGridParams do begin
     Cells[0, i + 1] := Par.Name;
      Cells[1, i + 1] := Par.Units;
      Cells[2, i + 1] := floattoStr(Par.v);
      Cells[3, i + 1] := FloattoStr(Par.max);
      Cells[4, i + 1] := FloatToStr(Par.min);
      Cells[5, i + 1] := '30';

    end;
    end;

  end;

end;

procedure TFormGAOpt.IntEditPopSizeExit(Sender: TObject);
begin
  sga.Popsize := IntEditPopsize.Value;
end;

procedure TFormGAOpt.IntEditMaxGenExit(Sender: TObject);
begin
  sga.MaxGen := IntEditMaxGen.Value;
end;

procedure TFormGAOpt.FloatEditCrossProbExit(Sender: TObject);
begin
  sga.Pcross := FloatEditCrossProb.Value;
end;

procedure TFormGAOpt.FloatEditMutProbExit(Sender: TObject);
begin
  sga.pmutation := floatEditMutProb.value;
end;

procedure TFormGAOpt.IncludeBtnParClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListPar);
  MoveSelected(SrcListPar, DstListPar.Items);
  SetItem(SrcListPar, Index);
  UpdateParaValueListBox;
end;

procedure TFormGAOpt.IncAllBtnParClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcListPar.Items.Count - 1 do
    DstListPar.Items.AddObject(SrcListPar.Items[I],
      SrcListPar.Items.Objects[I]);
  SrcListPar.Items.Clear;
  SetItem(SrcListPar, 0);
  UpdateParaValueListBox;
end;

procedure TFormGAOpt.ExcludeBtnParClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstListPar);
  MoveSelected(DstListPar, SrcListPar.Items);
  SetItem(DstListPar, Index);
  UpdateParaValueListBox;
end;

procedure TFormGAOpt.ExAllBtnParClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstListPar.Items.Count - 1 do
    SrcListPar.Items.AddObject(DstListPar.Items[I],
      DstListPar.Items.Objects[I]);
  DstListPar.Items.Clear;
  SetItem(DstListPar, 0);
  UpdateParaValueListBox;
end;

procedure TFormGAOpt.IncludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListData);
  MoveSelected(SrcListData, DstListData.Items);
  SetItem(SrcListData, Index);
end;

procedure TFormGAOpt.IncAllBtnDataClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcListData.Items.Count - 1 do
    DstListData.Items.AddObject(SrcListData.Items[I],
      SrcListData.Items.Objects[I]);
  SrcListData.Items.Clear;
  SetItem(SrcListData, 0);
end;

procedure TFormGAOpt.ExcludeBtnDataClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstListData);
  MoveSelected(DstListData, SrcListData.Items);
  SetItem(DstListData, Index);
end;

procedure TFormGAOpt.ExAllBtnDataClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstListData.Items.Count - 1 do
    SrcListData.Items.AddObject(DstListData.Items[I],
      DstListData.Items.Objects[I]);
  DstListData.Items.Clear;
  SetItem(DstListData, 0);
end;

procedure TFormGAOpt.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then Index := 0
    else if Index > MaxIndex then Index := MaxIndex;
    Selected[Index] := True;
  end;
  SetButtons;
end;

function TFormGAOpt.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TFormGAOpt.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;

procedure TFormGAOpt.UpdateParaValueListBox;

var
  i, index: integer;
  ParName, SubModName: string;
  SubMod: TSubModel;
  Par: TPar;

begin
//  ListBoxParaValues.Clear;
  with AdvStringGridParams do begin
  rowcount := DstListPar.Items.Count + 1;

  for I := 0 to DstListPar.Items.Count - 1 do begin
    ParName := DstListPar.items[i];
    SubModName := DstListPar.items[i];
    ParName := copy(ParName, pos('.', Parname) + 1, length(Parname) - pos('.',
      Parname)); // Delete Submodelname from string
    SubModName := copy(SubModName, 1, pos('.', SubModname) - 1);
      // Delete Parname from string
    index := sga.model.submodstrlist.indexof(submodname);
    SubMod := TsubModel(sga.Model.subModStrList.objects[index]);
    index := subMod.ParStrList.IndexOf(ParName);
    if index <> -1 then begin
      Par := TPar(SubMod.ParStrList.objects[index]);
      cells[0, i + 1] := Par.name;
      cells[1, i + 1] := Par.Units;
      cells[2, i + 1] := FloatToStrF(Par.V, ffgeneral, 5, 2);
      cells[3, i + 1] := FloatToStrf(Par.V / 5, ffgeneral, 5, 2);
      cells[4, i + 1] := FloatToStrf(Par.V * 5, ffgeneral, 5, 2);
      cells[5, i + 1] := FloatToStr(30);

//      ListBoxParaValues.Items.add(FloatToStrF(Par.v, ffgeneral, 6,2));
    end;
  end;
  end;
//  ListBoxParaValues.Update;

end;

procedure TFormGAOpt.SetButtons;
var
  SrcEmptyPar, DstEmptyPar,
    SrcEmptyData, DstEmptyData: Boolean;
begin
  SrcEmptyPar := SrcListPar.Items.Count = 0;
  DstEmptyPar := DstListPAr.Items.Count = 0;
  SrcEmptyData := SrcListData.Items.Count = 0;
  DstEmptyData := DstListData.Items.Count = 0;
  IncludeBtnPar.Enabled := not SrcEmptyPar;
  IncAllBtnPar.Enabled := not SrcEmptyPar;
  ExcludeBtnPar.Enabled := not DstEmptyPar;
  ExAllBtnPar.Enabled := not DstEmptyPar;
  IncludeBtnData.Enabled := not SrcEmptyData;
  IncAllBtnData.Enabled := not SrcEmptyData;
  ExcludeBtndata.Enabled := not DstEmptyData;
  ExAllBtnData.Enabled := not DstEmptyData;
end;

procedure TFormGAOpt.FormGAActivate;

var
  i, j: Integer;
  SubMod: TSubModel;
  ActPar, SavePar: TPar;
  ActSeries: TMeasList;

begin
  sga.SaveParList := TStringList.create;

  for I := 0 to sga.model.SelParList.Count - 1 do begin
    ActPar := TPar(sga.model.SelParList.Objects[i]);
    SavePar := TPar.create(ActPar.name, ActPar.u, ActPar.v, ActPar.error, '');
    Savepar.SelForOpt := true;
    ActPar.selforopt := true;
    sga.SaveParList.AddObject(SavePar.name, SavePar);
  end;

  SrcListPar.Clear;
  SrcListData.clear;
  DstListpar.clear;
  DstListData.clear;
//  ListBoxParaValues.clear;
//  ListBoxOptimizedValues.clear;
//  ListBoxOptimizedValues.Visible := false;
//  LstBxStderror.clear;
//  LstBxStderror.Visible := false;

  for i := 0 to sga.Model.SubModStrList.Count - 1 do begin
    SubMod := TSubModel(sga.Model.SubModStrList.Objects[i]);
    for j := 0 to SubMod.ParStrList.count - 1 do begin
      ActPar := TPar(SubMod.ParStrList.objects[j]);
      SrcListPar.Items.add(SubMod.name + '.' + ActPar.name);
    end;
    if SubMod.DataList <> nil then begin
      for j := 0 to SubMod.DataList.count - 1 do begin
        ActSeries := TMeasList(SubMod.DataList.objects[j]);
        SrcListData.Items.add(ActSeries.name);
      end;
    end;
  end;
//  update_StringGrid(model.reg_fn );
end;

end.

