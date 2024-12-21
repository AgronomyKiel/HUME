unit wurzelparam_optimierung2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, EditBtn, ComCtrls, Math, normaldistr, essolver, ESInterfaces;

type
  TStateVars = (LAI, Height, ShootN);
  { TForm1 }

  TForm1 = class(TForm)
    ProgressBar1: TProgressBar;
    start:  TButton;
    DirectoryEdit1: TDirectoryEdit;
    FileNameEdit1: TFileNameEdit;
    Label3: TLabel;
    Label4: TLabel;
    procedure startClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);

  private
    { private declarations }

  public


  end;




var
  Form1:     TForm1;
  strlist:   TStringList;
  captions:  TStringList;
  sowing, harvest: integer;
  efftemp:   array[38000..40100] of double;
  sowingdates: array[0..5] of integer = (38718, 38971, 39191, 39217, 39371, 39562);
  // sortiert!
  globstate: string;

function CalcTarget(ATarget: integer; ALocation: PVector): extended;

implementation

{ TForm1 }

function CalcTarget(ATarget: integer; ALocation: PVector): extended;
var
  calcValue: extended;
  i, date:   integer;
  line:      TStringList;
  values:    array[38000..40100] of double;
  iniValue, ActValue, rgr, gr, capacity, h: double;
  switch:    boolean;
begin
  Result := 0;
  IniValue := ALocation^[0];
  rgr := ALocation^[1];
  capacity := ALocation^[2];
  gr := ALocation^[3];

  if (inivalue < 0) or (rgr < 0) or (gr < 0) or (capacity < 0) or
    (captions.IndexOf(globstate) < 0) then begin
    Result := Math.MaxDouble;
    exit;
  end

  else
  begin
    line := TStringList.Create;

    values[sowing] := IniValue;
    ActValue := IniValue;

    switch := False;

    for date := sowing + 1 to harvest do begin
      //ActValue := ActValue + math.max(0,ActValue*rgr*effTemp[date]*(1-ActValue/Capacity));

      if (ActValue < 0.99 * Capacity) and (not switch) then begin
        ActValue := ActValue + Math.max(0, ActValue * rgr * effTemp[date] *
          (1 - ActValue / Capacity));
      end
      else
      begin
        ActValue := ActValue + -gr * Math.max(0, efftemp[date] *
          ActValue * (Capacity - ActValue));
        switch   := True;
      end;


      values[date] := ActValue;
    end;

    for i := 0 to strList.Count - 1 do begin
      line.commatext := strList[i];

      date := StrToInt(line[captions.IndexOf('Time')]);
      if (line[captions.IndexOf(globstate)] = '.') then
        continue;
      ActValue := StrToFloat(line[captions.IndexOf(globstate)]);

      Result := Result + power(ActValue - values[date], 2);
    end;

    line.Free;
  end;
end;



procedure TForm1.startClick(Sender: TObject);
var
  line:   TStringList;
  i, j, learningCycle: integer;
  f:      TextFile;
  depssolver: IDEPSSolver;
  files:  TStringList;
  optValues: TStringList;
  searchResult: TSearchRec;
  tmpList: TStringList;
  date:   integer;
  Value:  double;
  states: array[TStateVars] of string = ('LAI', 'Height', 'ShootN');
  state:  TStateVars;
  max:    array[TStateVars] of double = (0.0, 0.0, 0.0);

  mindate: integer;

begin

  files := TStringList.Create();

  line     := TStringList.Create();
  strList  := TStringList.Create();
  captions := TStringList.Create();
  strList.LoadFromFile('B:\Modelle\Niko\DATA\Wetter_s1_06_09.txt');
  captions.CommaText := strList[0];

  for i := 2 to strList.Count - 1 do begin
    line.commatext := strList[i];
    date  := StrToInt(line[captions.indexof('Time')]);
    Value := strtofloat(line[captions.indexof('Temp')]);
    efftemp[date] := Value - 6;
  end;

  strList.Free;
  captions.Free;

  //if FindFirst('Wurzeln/*.csv', faAnyFile, searchResult) = 0 then
  //begin

  harvest := 0;
  mindate := 100000;

  captions := TStringList.Create();
  strList  := TStringList.Create();
  strList.LoadFromFile('J2007S1FF2FFG1NF1N1Bm.txt');

  captions.commatext := strList[0];

  strList.Delete(0);
  strList.Delete(0);

  for i := 0 to strList.Count - 1 do begin
    line.commatext := strList[i];
    if (trim(line[0]) = '') then
      continue;
    date    := StrToInt(line[captions.indexof('Time')]);
    harvest := Math.max(harvest, date);
    mindate := Math.min(mindate, date);
  end;

  for i := low(sowingdates) to high(sowingdates) do begin
    if sowingdates[i] < mindate then
      sowing := sowingdates[i];
  end;

  for state := low(TStateVars) to high(TStateVars) do begin
    globstate := states[state];

    //strList.LoadFromFile('Wurzeln/' + searchResult.Name);

    for i := 0 to strList.Count - 1 do begin
      line.commatext := strList[i];
      if (trim(line[captions.indexof(states[state])]) = '.') then
        continue;
      Value      := strtofloat(line[captions.indexof(states[state])]);
      max[state] := Math.max(maxV[state], Value);
    end;

    ShowMessage('test');
    //create a problem with 4 variables and 1 target function
    depssolver := PrepareDEPSSolver(4, 1);
    depssolver.SetTargetBounds(0, MinBounds, MinBounds);
    depssolver.SetVariableBounds(0, 0, 1);   // inivalue
    depssolver.SetVariableBounds(1, 0.000001, 0.01);  // rgr
    depssolver.SetVariableBounds(2, 0.1, max[state] + 5);  // capacity
    depssolver.SetVariableBounds(3, 0.000001, 0.01);  // gr

    //usually leads to faster stagnation
    depssolver.SetPSCognitiveFactor(1.494);
    depssolver.SetPSSocialFactor(1.494);
    depssolver.SetPSWeight(0.4);

    //set the function which calculates the target value(s)
    depssolver.SetCalcTargetCallback(@CalcTarget);

    //initialize the solver with the above parameters
    depssolver.Init;

    learningCycle := 0;
    repeat
      //learn ...
      depssolver.RunLearningCycle;

      Inc(learningCycle);

      //every 100 steps, output the current solution
      if learningCycle mod 100 = 0 then
        //writeln(learningCycle, ': ', FloatToStr(depssolver.ObjectiveValue));
        //... until 70 individuals came to similar solutions without finding
        //anything better
    until (depssolver.Stagnation >= 70) or (learningCycle = 100000);

    //free up all allocated resources

    optValues := TStringList.Create();
    optValues.add(Format(globstate + '_inivalue=%10.8f', [depssolver.Location^[0]]));
    optValues.add(Format(globstate + '_rgr=%10.8f', [depssolver.Location^[1]]));
    optValues.add(Format(globstate + '_capacity=%10.8f', [depssolver.Location^[2]]));
    optValues.add(Format(globstate + '_gr=%10.8f', [depssolver.Location^[3]]));
    optValues.add(Format('SowingDate=%10.8f', [sowing]));
    optValues.add(Format('HarvestDate=%10.8f', [harvest]));
    //optValues.add(Format(state+'%10.8f',[depssolver.ObjectiveValue]));

    depssolver.Free;

    files.AddObject(searchResult.Name, optValues);

    line.Free;
    strList.Free;
    captions.Free;
    //until FindNext(searchResult) <> 0;

    //FindClose(searchResult);

  end;

  AssignFile(f, 'opt.csv');
  Rewrite(f);

  for i := 0 to files.Count - 1 do begin
    optValues := files.objects[i] as TStringList;
    for j := 0 to optvalues.Count - 1 do begin
      writeln(f, optValues[j]);
    end;
  end;

  CloseFile(f);

end;


initialization
  {$I wurzelparam_optimierung2.lrs}

end.

