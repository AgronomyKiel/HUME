unit uopt_log_decay;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Buttons, EditBtn, StdCtrls, ComCtrls, Math, essolver,
  ESInterfaces;

type
  TStateVars = (Height, LAI,  ShootN);
  { TForm1 }

  TForm1 = class(TForm)
    DirectoryInput: TDirectoryEdit;
    DirectoryOutput: TDirectoryEdit;
    Label1: TLabel;
    Label2: TLabel;
    ProgressBar1: TProgressBar;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure optimize();
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  states: array[TStateVars] of string = ('Height', 'LAI', 'ShootN');
  Form1: TForm1;
  strlist, files, captions:  TStringList;
  sowing, harvest: integer;
  efftemp6, efftemp0, efftemp:   array[38000..40100] of double;
  sowingdates: array[0..10] of integer = (38718, 38971, 39191, 39217, 39300, 39371, 39562, 39661, 39690, 39745, 39927);
  grasscuts: array[0..1] of integer = (39365, 39734);
  // sortiert!
  globstate: string;
  inivaluemax: double;


  function CalcTarget(ATarget: integer; ALocation: PVector): extended;


implementation

 function CalcTarget(ATarget: integer; ALocation: PVector): extended;
var
  i, date:   integer;
  line:      TStringList;
  values:    array[38000..40100] of double;
  iniValue, ActValue, rgr, gr, capacity: double;
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
  end else begin

    values[sowing] := IniValue;
    ActValue := IniValue;
    switch := False;

    for date := sowing + 1 to harvest do begin
      //ActValue := ActValue + math.max(0,ActValue*rgr*effTemp[date]*(1-ActValue/Capacity));
      // log decay
      if (ActValue < 0.99 * Capacity) and (not switch) then begin
        ActValue := ActValue + Math.max(0, ActValue * rgr * effTemp[date] *
          (1 - ActValue / Capacity));
      end else begin
        ActValue := ActValue + -1 * Math.max(0, gr * efftemp[date] *
          ActValue * (Capacity - ActValue));
        ActValue := Math.max(ActValue,0);
        switch   := True;
      end;
      values[date] := ActValue;
    end;

    line := TStringList.Create;
    for i := 0 to strList.Count - 1 do begin
      line.commatext := strList[i];
      date := StrToInt(line[captions.IndexOf('Time')]);

      if (date < sowing) or (harvest < date) or
         (line[captions.IndexOf(globstate)] = '.') then
        continue;

      ActValue := StrToFloat(line[captions.IndexOf(globstate)]);
      Result := Result + power(ActValue - values[date], 2);
    end;

    line.Free;
  end;
end;

{ TForm1 }

procedure TForm1.SpeedButton1Click(Sender: TObject);
var
  i, j,  date, mindate, cutday, temp: integer;
  f: TextFile;
  line, optvalues: TStringList;
  searchResult: TSearchRec;
  Value:  double;
  filename: String;
begin

  i := 0;
  if FindFirst(DirectoryInput.text + '/*.txt*', faAnyFile, searchResult) = 0 then
  begin
    repeat
      inc(i);
    until FindNext(searchResult) <> 0;
    FindClose(searchResult);
  end;

  ProgressBar1.Position := 0;
  ProgressBar1.Min := 0;
  ProgressBar1.Max := i * 3;

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
    efftemp6[date] := Value - 6;
    efftemp0[date] := Value;
  end;

  strList.Free;
  captions.Free;

  captions := TStringList.Create();
  strList  := TStringList.Create();

  // Try to find regular files matching in the current dir
  if FindFirst(DirectoryInput.text + '/*.txt*', faAnyFile, searchResult) = 0 then
  begin
    repeat

  harvest := 0;
  mindate := 100000;
  strList.LoadFromFile(DirectoryInput.text + '\' + searchResult.Name);
  // 'J2007S1FF2FFG1NF1N1Bm.txt'
  captions.commatext := strList[0];
  if (strList.count < 5) or
   (captions.IndexOf('Time')  < 0)or
   (captions.IndexOf('LAI')  < 0) or
   (captions.IndexOf('ShootN')  < 0) or
   (captions.IndexOf('Height')  < 0) then begin
     ProgressBar1.StepIt;
     continue;
  end;

  // Mais sonderbehandlung, Basistemperatur 6
  if ( AnsiPos('FFG1',AnsiUpperCase(searchResult.Name)) = 0) then
    efftemp := efftemp0
  else
    efftemp := efftemp6;

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

  cutday := harvest;
  // Gras Sonderbehandlung, Erster Schnitttermine
  if ( AnsiPos('FFG3',AnsiUpperCase(searchResult.Name)) <> 0) and (AnsiPos('FF3',AnsiUpperCase(searchResult.Name)) = 0) then begin
    for i := low(grasscuts) to high(grasscuts) do begin
      if (sowing < grasscuts[i]) and (grasscuts[i] < harvest) then
        cutday := grasscuts[i];
      end;
  end;

  filename := searchResult.name;

  temp := harvest;

  inivaluemax := 0.1;

  // geht so nur für einen Schnitt zwischen Aussaat und Ernte!
  if cutday <> harvest then begin
    harvest := cutday;
    optimize;
    inivaluemax := 1.0;
    sowing := cutday;
    harvest := temp;
  end;

  optimize();

  AssignFile(f, DirectoryOutput.text + '\opt_' + filename);
  Rewrite(f);
  writeln(f, 'Reihenfolge: Height, LAI, ShootN jeweils 4 Werte,');
  writeln(f, '(inivalue, rgr, capacity, gr)');
  writeln(f, 'Direkt untereinander, um sie möglichst einfach in die');
  writeln(f, 'Parameter.csv für das Excel2Ini Tool zu kopieren.');
  writeln(f, '');

  for i := 0 to files.Count - 1 do begin
    optValues := files.objects[i] as TStringList;
    for j := 0 to optvalues.Count - 1
      do writeln(f, optValues[j]);
  end;

  writeln(f,Format('SowingDate=%d', [sowing]));
  writeln(f,Format('HarvestDate=%d', [harvest]));

  files.clear;
  CloseFile(f);

  until FindNext(searchResult) <> 0;
    FindClose(searchResult);
  end;

  strList.free;
  captions.free;

  showmessage('fertig');

end;


procedure TForm1.optimize();
var
 line: TStringList;
 i, learningCycle: Integer;
 value: double;
 state:  TStateVars;
 depssolver: IDEPSSolver;
 max:    array[TStateVars] of double = (0.0, 0.0, 0.0);
 optValues: TStringList;
 date: Integer;
 ok: boolean;
begin
 optValues := TStringList.create;
 line := TStringList.create;
 for state := low(TStateVars) to high(TStateVars) do begin

    globstate := states[state];
    max[state] := 2;

    // Maximalwert ausrechnen (Wertebereichsoptimierung)
    for i := 0 to strList.Count - 1 do begin
      line.commatext := strList[i];
      if (trim(line[captions.indexof(states[state])]) = '.') then
        continue;
      Value := strtofloat(line[captions.indexof(states[state])]);
      date := strtoint(line[captions.indexof('Time')]);
      if (sowing <= date) and (date <= harvest) then
        max[state] := Math.max(max[state], Value);
    end;



    //create a problem with 4 variables and 1 target function
    depssolver := PrepareDEPSSolver(4, 1);
    depssolver.SetTargetBounds(0, MinBounds, MinBounds);
    depssolver.SetVariableBounds(0, 0.001, inivaluemax);   // 0.05 inivalue
    depssolver.SetVariableBounds(1, 0.0001, 0.01);  // rgr
    depssolver.SetVariableBounds(2, 0.1, max[state] + 1);  // capacity
    depssolver.SetVariableBounds(3, 0, 0.01);  // gr

    //usually leads to faster stagnation
    depssolver.SetPSCognitiveFactor(1.494);
    depssolver.SetPSSocialFactor(1.494);
    depssolver.SetPSWeight(0.4);
    depssolver.SetCalcTargetCallback(@CalcTarget);
    depssolver.Init;

    // Berechnung der Lösung durch den OpenOffice Solver
    learningCycle := 0;
    try
    ok := true;
    repeat
      depssolver.RunLearningCycle;
      Inc(learningCycle);
    until (depssolver.Stagnation >= 70) or (learningCycle = 10000);
    except
     ok := false;
    end;
    optValues := TStringList.Create();

    if (learningCycle = 10000)
      //or (depssolver.Location^[0] < 0)
      or (depssolver.Location^[1] < 0)
      or (depssolver.Location^[2] <= 0.1)
      //or (depssolver.Location^[3] < 0)
      or (not ok) then begin
      optValues.add('0');
      optValues.add('0');
      optValues.add('0');
      optValues.add('0');
    end else begin
      optValues.add(Format('%10.8f', [math.max(0,depssolver.Location^[0])]));
      optValues.add(Format('%10.8f', [depssolver.Location^[1]]));
      optValues.add(Format('%10.8f', [depssolver.Location^[2]]));
      optValues.add(Format('%10.8f', [math.max(0,depssolver.Location^[3])]));
    end;

    //optValues.add(Format(state+'%10.8f',[depssolver.ObjectiveValue]));

    depssolver.Free;
    files.AddObject(states[state], optValues);
    ProgressBar1.StepIt;
  end;

  line.free;
end;

initialization
  {$I uopt_log_decay.lrs}

end.

