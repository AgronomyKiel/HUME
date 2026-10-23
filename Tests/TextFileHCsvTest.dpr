program TextFileHCsvTest;
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  UTextFileH, UState, UMod, UMeasValue;

procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create(MessageText);
end;

procedure Near(Actual, Expected: Double; const MessageText: string);
begin
  Check(not IsNan(Actual) and (Abs(Actual - Expected) < 1E-9), MessageText);
end;

procedure WriteFixture(const FileName, Contents: string);
begin
  TFile.WriteAllText(FileName, Contents, TEncoding.UTF8);
end;

procedure TestReader(const FileName: string);
var
  Reader: TTextFileH;
begin
  Reader := TTextFileH.Create;
  try
    WriteFixture(FileName,
      'Time,Dry mass,"Leaf, area","A ""quoted"" name",Missing' + sLineBreak +
      'd,kg,"m2, plant",kg,[]' + sLineBreak +
      '1.5,2.75,"3.25",4e-2,' + sLineBreak +
      '2.5,,.,5.5,7.5' + sLineBreak);
    Reader.Init(FileName);
    Check(Reader.FirstLine.Count = 5, 'CSV header column count');
    Check(Reader.FirstLine[1] = 'Dry mass', 'Unquoted spaces preserved');
    Check(Reader.FirstLine[2] = 'Leaf, area', 'Quoted comma preserved');
    Check(Reader.FirstLine[3] = 'A "quoted" name', 'Escaped quotes');
    Check(Reader.UnitLine[2] = 'm2, plant', 'Quoted unit');
    Reader.GoTop;
    Reader.NextLine;
    Near(Reader.getIndexValue(0), 1.5, 'CSV date independent of locale');
    Near(Reader.getValue('Dry mass'), 2.75, 'CSV decimal independent of locale');
    Near(TVar(Reader.FirstLine.Objects[1]).v, 2.75, 'NextLine variable value');
    Near(Reader.getValue('Leaf, area'), 3.25, 'Quoted numeric value');
    Near(Reader.getIndexValue(3), 0.04, 'Scientific notation');
    Check(IsNan(Reader.getIndexValue(4)), 'Trailing empty field');
    Reader.FastNextLine;
    Check(IsNan(Reader.getIndexValue(1)), 'Interior empty field');
    Check(IsNan(Reader.getIndexValue(2)), 'Dot missing value');
    Near(Reader.getIndexValue(4), 7.5, 'Empty fields retain column alignment');
    Check(not Reader.hasMoreLines, 'End of data');
    Reader.LocateFor('Time', 2);
    Near(Reader.getIndexValue(0), 2.5, 'LocateFor uses CSV conversion');

    WriteFixture(FileName, 'Time Value Other' + sLineBreak +
      'd kg []' + sLineBreak + '1' + #9 + '"2,75" 3' + sLineBreak);
    Reader.Init(FileName);
    Reader.GoTop;
    Reader.NextLine;
    Check(Reader.FirstLine.Count = 3, 'Legacy whitespace header');
    Near(Reader.getValue('Value'), 2.75, 'Legacy locale decimal conversion');
    Near(Reader.getIndexValue(2), 3, 'Legacy tabs and spaces');

    WriteFixture(FileName, 'Time,Value,Other' + sLineBreak +
      'd,kg' + sLineBreak + '1,2,3,4' + sLineBreak);
    Reader.Init(FileName);
    Check(Reader.UnitLine[2] = '[]', 'Missing units are padded');
    Reader.GoTop;
    Reader.NextLine;
    Near(Reader.getValue('Other'), 3, 'Extra columns do not overrun header');
  finally
    Reader.Free;
  end;
end;

procedure TestMeasurementImport(const FileName: string);
var
  Model: TMod;
  Submodel: TSubmodel;
  Series: TMeasList;
  i: Integer;
begin
  WriteFixture(FileName, 'Time,Dry mass,Other' + sLineBreak +
    'd,kg,[]' + sLineBreak + '1.5,2.75,' + sLineBreak +
    '2.5,,3.25' + sLineBreak);
  Model := TMod.Create;
  Submodel := TSubmodel.Create;
  try
    Model.ActIniFile := TMyIniFile.Create(ChangeFileExt(FileName, '.ini'));
    Model.StartTime := 1;
    Model.EndTime := 3;
    Model.MinLegalValue := 0;
    Submodel.GlobMod := Model;
    Submodel.Name := 'CSVTest';
    Submodel.SubModName := 'CSVTest';
    Model.SubModStrList.AddObject(Submodel.Name, Submodel);
    Submodel.SomethingMeasured := True;
    Model.ActIniFile.WriteString(Model.Str_SectionName_MeasurementFiles,
      Submodel.SubModName, FileName);
    Submodel.AddDataValueToDataSeries;
    Check(Submodel.DataList.Count = 2, 'Measurement series count');
    Series := TMeasList(Submodel.DataList.Objects[Submodel.DataList.IndexOf('Dry mass')]);
    Check(Series.Count = 1, 'Missing measurement skipped');
    Check(Series.Units = 'kg', 'Measurement units');
    Near(TMeasValue(Series[0]).date, 1.5, 'Imported measurement date');
    Near(TMeasValue(Series[0]).meas, 2.75, 'Imported measurement value');
    Series := TMeasList(Submodel.DataList.Objects[Submodel.DataList.IndexOf('Other')]);
    Check(Series.Count = 1, 'Empty CSV field keeps measurement alignment');
    Near(TMeasValue(Series[0]).meas, 3.25, 'Second measurement series');
  finally
    for i := 0 to Submodel.DataList.Count - 1 do begin
      Series := TMeasList(Submodel.DataList.Objects[i]);
      Series.Clear;
      Series.Free;
    end;
    Submodel.DataList.Clear;
    Submodel.Free;
    Model.ActIniFile.Free;
    Model.ActIniFile := nil;
    Model.Free;
  end;
end;

/// <summary>Optionally verify all display cells and dates in a supplied CSV.</summary>
procedure TestDisplayFile(const FileName: string);
var
  Reader: TTextFileH;
  Expected: TStringList;
  Row, Col: Integer;
begin
  Reader := TTextFileH.Create;
  Expected := TStringList.Create;
  try
    Reader.Init(FileName);
    Check(Reader.n_Line > 0, 'Display file contains data');
    Expected.StrictDelimiter := True;
    Expected.Delimiter := ',';
    Expected.DelimitedText := Reader.slFile[0];
    Check(Reader.FirstLine.Count = Expected.Count, 'Display header width');
    for Col := 0 to Expected.Count - 1 do
      Check(Reader.FirstLine[Col] = Trim(Expected[Col]), 'Display header cell');
    Reader.GoTop;
    for Row := 2 to Reader.n_Line + 1 do
    begin
      Reader.FastNextLine;
      Expected.DelimitedText := Reader.slFile[Row];
      Check(Reader.ActLine.Count = Expected.Count, 'Display row width');
      for Col := 0 to Expected.Count - 1 do
        Check(Reader.ActLine[Col] = Trim(Expected[Col]), 'Display data cell');
      Check(not IsNan(Reader.getIndexValue(0)), 'Display date is numeric');
      Check(DateTimeToStr(Reader.getIndexValue(0)) <> '', 'Display date formatting');
    end;
    Check(not Reader.hasMoreLines, 'Display includes final row');
    Writeln('Display file verified: ', Reader.n_Line, ' data rows, ',
      Reader.FirstLine.Count, ' header columns.');
  finally
    Expected.Free;
    Reader.Free;
  end;
end;

var
  SavedFormat: TFormatSettings;
  Fixture: string;
begin
  SavedFormat := FormatSettings;
  Fixture := TPath.GetTempFileName;
  try
    FormatSettings.DecimalSeparator := ',';
    FormatSettings.ThousandSeparator := '.';
    TestReader(Fixture);
    TestMeasurementImport(Fixture);
    if ParamCount > 0 then
      TestDisplayFile(ParamStr(1));
    FormatSettings.DecimalSeparator := '.';
    FormatSettings.ThousandSeparator := ',';
    TestMeasurementImport(Fixture);
    Writeln('CSV reader and measurement import tests passed.');
  finally
    FormatSettings := SavedFormat;
    DeleteFile(Fixture);
  end;
end.
