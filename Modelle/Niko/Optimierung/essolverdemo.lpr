program essolverdemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, Math, normaldistr, essolver, ESInterfaces;

var
  formatSettings: TFormatSettings;
  data: array of array[0..1] of Extended;
  depssolver: IDEPSSolver;

//a helper function to read the data file
procedure ParseDataFile;
var
  dataFile: TextFile;
  line: string;
  firstValue, secondValue: Extended;
  sepPos, realCount: Integer;
begin
  firstValue := 0;
  secondValue := 0;

  AssignFile(dataFile, 'messwerte.txt');
  Reset(dataFile);

  realCount := 0;
  SetLength(data, 1024);

  while not eof(dataFile) do
  begin
    readln(dataFile, line);
    line := Trim(line);
    sepPos := Pos(#9, line);
    if sepPos > 0 then
    begin
      if TryStrToFloat(Copy(line, 1, sepPos - 1), firstValue, formatSettings) and
        TryStrToFloat(Copy(line, sepPos + 1, Length(line) - sepPos), secondValue, formatSettings) then
      begin
        if realCount >= Length(data) then
          SetLength(data, Length(data) * 2);
        data[realCount][0] := firstValue;
        data[realCount][1] := secondValue;
        Inc(realCount);
      end;
    end;
  end;
  CloseFile(dataFile);
  SetLength(data, realCount);
end;

function CalcTarget(ATarget: Integer; ALocation: PVector): Extended;
var
  calcValue: Extended;
  i: Integer;
begin
  Result := 0;
  //sum up the quadratic errors
  for i := 0 to Length(data) - 1 do
  begin
    calcValue := ALocation^[2] + ALocation^[3] * erf((data[i][0] - ALocation^[0]) /
      (ALocation^[1] * sqrt(2)));
    Result := Result + power(data[i][1] - calcValue, 2);
  end;
end;

var
  learningCycle, i: Integer;

begin
  writeln(AboutESSolver);
  writeln;

  formatSettings.DecimalSeparator := ',';
  ParseDataFile;

  //create a problem with 4 variables and 1 target function
  depssolver := PrepareDEPSSolver(4, 1);

  //minimize target
  depssolver.SetTargetBounds(0, MinBounds, MinBounds);
  //define bounds for the variables
  depssolver.SetVariableBounds(0, -20000, 20000);
  depssolver.SetVariableBounds(1, 0.00001, 20000);
  depssolver.SetVariableBounds(2, -100, 100);
  depssolver.SetVariableBounds(3, -100, 100);

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
      writeln(learningCycle, ': ', FloatToStr(depssolver.ObjectiveValue));

    //... until 70 individuals came to similar solutions without finding
    //anything better
  until depssolver.Stagnation >= 70;

  writeln(FloatToStr(depssolver.ObjectiveValue));
  for i := 0 to 3 do
    writeln(FloatToStr(depssolver.Location^[i]));

  //free up all allocated resources
  depssolver.Free;
end.

