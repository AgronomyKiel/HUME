unit UFormYearAnalysis_OSR_WW;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Mask, advspin, Buttons, StdCtrls, Grids, Calendar, Spin, ComCtrls, UMod, UState, Inifiles,
   UTextfileH, FileCtrl, dateutils // HUME: TTextFileH class, handling tabular ASCII files
;

type
   TManagementEvents = (Tillage, Fert_NH4, Fert_NO3);

const
  SectionNameParamIniFilename = 'ParamIniFN';
  SectionNameStateIniFilename = 'StateIniFN';
  SectionNameOptionIniFilename = 'OptionsIniFN';
  SowingDateString : string = 'Sowingdate';
  HarvestDateString : string = 'Harvestdate';
  TManagementEventStrgs : array[TManagementEvents] of string = ('Tillage', 'Fert_NH4','Fert_NO3' );
  SectionNameNH4Fert : string = 'Fert_NH4';
  SectionNameNO3Fert : string = 'Fert_NO3';
  SectionNameTillage : string = 'Tillage';



type
   TCropSimDates = (SimStart, SimEnd);
   TMyIniFile = TMemIniFile;

  TFormYearAnalysis = class(TForm)
    LabelIniFileName: TLabel;
    SpeedButtonIniFileName: TSpeedButton;
    LabelControlFileName: TLabel;
    LabelStartYear: TLabel;
    LabelEndYear: TLabel;
    LabelInputDirectory: TLabel;
    SpeedButtonInputDirectory: TSpeedButton;
    EditInifileName: TEdit;
    EditControlFileName: TEdit;
    EditInputDirectory: TEdit;
    ButtonStart: TButton;
    SpinEditStartYear: TSpinEdit;
    SpinEditEndYear: TSpinEdit;
    DateTimePickerStartDate: TDateTimePicker;
    DateTimePickerEndDate: TDateTimePicker;
    OpenDialog1: TOpenDialog;
    LabelSowingDateName: TLabel;
    EditSowingDateString: TEdit;
    LabelStartDate: TLabel;
    LabelEndDate: TLabel;
    LabelSowingDate: TLabel;
    DateTimePickerSowingDate: TDateTimePicker;
    LabelHarvestDate: TLabel;
    DateTimePickerHarvestDate: TDateTimePicker;
    LabelWeatherfilename: TLabel;
    EditWeatherfileName: TEdit;
    SpeedButtonWeatherFileName: TSpeedButton;
    LabelHarvestDateName: TLabel;
    EditHarvestDateName: TEdit;
    LabelControlFile: TLabel;
    OpenDialogDirectory: TOpenDialog;
    LabelFirstWeather: TLabel;
    LabelLastWeather: TLabel;
    procedure SpeedButtonIniFileNameClick(Sender: TObject);
    procedure SpeedButtonControlfileNameClick(Sender: TObject);
    procedure FormActivate; virtual;
    procedure ButtonStartClick(Sender: TObject);
    procedure EditControlFileNameChange(Sender: TObject);
    procedure SpinEditStartYearChange(Sender: TObject);
    procedure EditInputDirectoryChange(Sender: TObject);
    procedure SpeedButtonInputDirectoryClick(Sender: TObject);
    procedure SpeedButtonWeatherFileNameClick(Sender: TObject);

  private
    { Private-Deklarationen }
    IniFileName : String;
    NewCropSimDates, DefaultCropSimDates : array[TCropSimDates] of TDate;
    OldCropSowingdates, OldCropHarvestDates : array[1..100] of TDate;
    ManagementDates: array[TManagementEvents, 1..100] of TDate;
    ManagementValues: array[TManagementEvents, 1..100] of real;

  public
    WeatherFile: TTextFileH; // Weather data
    ControlFileName: TFilename;
    StartYear, Endyear, NewSowingDate, act_year,
  start_date, end_date, Start_year : integer;
  TemplateIniFileName,
  ParIniFile_fn,
  NewIniFileCaption,
  NewIniFileName,
  NewParIniFileName,
  NewStateIniFileName,
  NewOptionIniFileName,
  NewInputFileName,
  TemplateParIniFileName,
  TemplateStateIniFileName,
  TemplateOptionIniFileName,
  TemplateInputFileName,
  Weatherfilefn,
  DirectoryName,
  cfn,   test,
  sitename : string;
  TemplateIniFile, NewIniFile, TemplateParIniFile, TemplateStateIniFile, NewParIniFile,
  NewStateIniFile, ParIniFile, NewInputFile : TMyIniFile;
  SowingdatePar : TPar;
  actSubmod : TSubmodel;
  ControlFile : Textfile;
  FirstWeatherData, LastWeatherData: Integer;

  end;

var
  FormYearAnalysis: TFormYearAnalysis;

implementation

{$R *.DFM}
uses JCLFileUtils, JCLStrings;

function isDate ( const DateString: string ): boolean;
begin

  try
    StrToDate ( DateString );
    result := true;
  except
  on E: EConvertError do

    result := false;
  end;
end;


procedure TFormYearAnalysis.SpeedButtonControlfileNameClick(Sender: TObject);
var
  success : boolean;
begin
  OpenDialog1.FileName := '*.fn';
  OpenDialog1.Filter := 'Inifiles (*.fn)|*.fn';
  success := OpenDialog1.Execute;
  If success = true then begin
     ControlFileName := self.OpenDialog1.FileName;
  end;
  EditIniFilename.text := ControlFileName;
end;

procedure TFormYearAnalysis.SpeedButtonIniFileNameClick(Sender: TObject);

var
  success : boolean;
  i, index : integer;
  Date : TDate;
  SubModelStrings, ParNames, StateNames, TempString : TStringlist;
  j: Integer;
begin
  OpenDialog1.FileName := '*.ini';
  OpenDialog1.Filter := 'Inifiles (*.ini)|*.ini';
  success := OpenDialog1.Execute;
  If success = true then begin
     IniFileName := self.OpenDialog1.FileName;
  end;
 EditInifileName.text := IniFileName;
 TemplateIniFileName := self.EditInifileName.text;
  if fileexists(TemplateIniFileName) then  begin
    TemplateIniFile := TMyInifile.Create(TemplateIniFileName);
      TempString := TStringList.create; // Treue

  TemplateInputFileName := TemplateIniFileName;
  TemplateInputFileName := PathRemoveExtension(TemplateInputFileName)+'_Input.ini';
  if not FileExists(TemplateInputFileName) then TemplateInputFileName := '';

  self.EditInputDirectory.Text := ExtractFilePath(TemplateIniFileName);
  DirectoryName := self.EditInputDirectory.Text;
  self.LabelControlFile.Caption := self.EditControlFileName.Text+'_'+InttoStr(self.SpinEditStartYear.Value)+'_'
                                        + inttostr(self.SpinEditEndYear.Value)+'.fn';
  EditInputDirectory.Visible := true;
  LabelInputDirectory.Visible := true;
  LabelControlFile.visible := true;
  weatherfilefn := TemplateIniFile.readstring('FileNames', 'WeatherFileFN', '');
  if FileExists(WeatherFilefn) then
  begin
    WeatherFile.Free;
    WeatherFile := TTextFileH.create(WeatherFilefn);
    TempString.CommaText := WeatherFile.GetFirstLine;
    FirstWeatherData := round(StrToFloat(TempString.Strings[0]));
    self.LabelFirstWeather.Caption := DateToStr(Firstweatherdata);
    self.LabelFirstWeather.Visible := true;
    self.DateTimePickerStartDate.MinDate := FirstWeatherData;
    DateTimePickerStartDate.visible := true;
    self.LabelStartDate.Visible := true;
    self.DateTimePickerSowingDate.MinDate := FirstWeatherData;
    DateTimePickerSowingDate.visible := true;
    self.LabelSowingDate.Visible := true;
    // TempString := TStringList.Create;

    TempString.CommaText := WeatherFile.GetLastLine;
    LastWeatherData := round(StrToFloat(TempString.Strings[0]));
    self.LabelLastWeather.Caption := DateToStr(Lastweatherdata);
    self.LabelLastWeather.Visible := true;
    self.DateTimePickerEndDate.MaxDate := LastWeatherData;
    self.DateTimePickerHarvestDate.MaxDate := LastWeatherData;
    DateTimePickerHarvestDate.visible := true;
    self.LabelHarvestDate.Visible := true;
    WeatherFile.GoTop;
  end;
  TempString.Free;
  EditWeatherfileName.Text := Weatherfilefn;
  EditWeatherfileName.Visible := true;
  LabelWeatherfilename.Visible := true;
  DateTimePickerStartDate.DateTime := TemplateIniFile.ReadInteger('TimeInit', 'Startzeit', 0);
  DateTimePickerStartDate.visible := true;
  LabelStartDate.Visible := true;
  DateTimePickerEndDate.DateTime := TemplateIniFile.ReadInteger('TimeInit', 'Endzeit', 0);
  DateTimePickerEndDate.visible := true;
  LabelEndDate.Visible := true;
  self.SpeedButtonWeatherFileName.Visible := true;


//    self.WeatherFile
  end else begin
    Showmessage(TemplateIniFileName + ' does not exist!');
    exit;
  end;
  Submodelstrings := TStringlist.Create;
  Parnames := TSTringlist.Create;

  test :=  TemplateIniFile.Readstring('FileNames', SectionNameParamIniFilename, '');
  TemplateParIniFileName := test;// TemplateIniFile.Readstring('FileNames', SectionNameParamIniFilename, 'asdf');
  if FileExists(TemplateParIniFileName) then begin
    TemplateParIniFile := TMyInifile.Create(TemplateParIniFileName);
    TemplateParIniFile.ReadSections(Submodelstrings);
  end else begin
    Showmessage(TemplateParIniFileName + ' does not exist!');
    exit;
  end;

  for i := 0 to SubModelStrings.Count - 1 do begin

    TEmplateParIniFile.ReadSection(SubModelStrings[i], ParNames);
    Parnames.casesensitive := false;
    TemplateParIniFile.CaseSensitive := false;
    Index := Parnames.Indexof(SowingDateString);
    if  Index <> -1 then begin
      OldCropSowingdates[i] := TemplateParIniFile.Readfloat(SubmodelStrings[i], SowingDateString, 0);
      DateTimePickerSowingDate.DateTime := OldCropSowingdates[i];
    end;

    Index := Parnames.Indexof(HarvestDatestring);
    if Index <> -1 then begin
      OldCropHarvestDates[i] := TemplateParIniFile.Readfloat(SubmodelStrings[i], HarvestDateString, 0);
      self.DateTimePickerHarvestDate.DateTime := OldCropHarvestDates[i];
    end;
   end;

  Statenames := TSTringlist.Create;

  test :=  TemplateIniFile.Readstring('FileNames', SectionNameStateIniFilename, '');
  TemplateStateIniFileName := test;// TemplateIniFile.Readstring('FileNames', SectionNameStateamIniFilename, 'asdf');
  Submodelstrings.Clear;
  if FileExists(TemplateStateIniFileName) then begin
    TemplateStateIniFile := TMyInifile.Create(TemplateStateIniFileName);
    TemplateStateIniFile.ReadSections(Submodelstrings);
  end else begin
    Showmessage(TemplateStateIniFileName + ' does not exist!');
    exit;
  end;

  for i := ord(low(TManagementEvents)) to ord(high(TManagementEvents)) do begin
    TemplateStateIniFile.ReadSection(TManagementEventStrgs[TManagementEvents(i)], StateNames);
    for j := StateNames.Count-1 downto 0 do if isDate(StateNames[j])=false then StateNames.Delete(j);

    for j := 0 to StateNames.Count - 1 do begin
      self.ManagementDates[TManagementEvents(i),j+1] := strtoDate(StateNames[j]);
      self.ManagementValues[TManagementEvents(i),j+1] := TemplateSTateIniFile.readfloat(TManagementEventStrgs[TManagementEvents(i)], StateNames[j], 0);
    end;
  end;

  test :=  TemplateIniFile.Readstring('FileNames', SectionNameStateIniFilename, 'asdf');
  TemplateStateIniFileName := test;// TemplateIniFile.Readstring('FileNames', SectionNameParamIniFilename, 'asdf');
  test :=  TemplateIniFile.Readstring('FileNames', SectionNameOptionIniFilename, 'asdf');
  TemplateOptionIniFileName := test;// TemplateIniFile.Readstring('FileNames', SectionNameParamIniFilename, 'asdf');

   self.ButtonStart.Visible := true;
   submodelstrings.free;

end;

procedure TFormYearAnalysis.SpeedButtonInputDirectoryClick(Sender: TObject);

var
  DirectoryName : string;
  success : boolean;

  begin

  OpenDialog1.Filter := ' (*.)|*.';
  success := OpenDialogDirectory.Execute;
  If success = true then begin
     DirectoryName := ExtractFilePath(OpenDialogDirectory.Filename);
  end;
//  EditInputDirectory.Text := extractfilepath(opendialog.filename);  }
  self.EditInputDirectory.Text := DirectoryName;

end;

procedure TFormYearAnalysis.SpeedButtonWeatherFileNameClick(Sender: TObject);
var
  success : boolean;
  TempString : TSTringlist;
begin
  TempString := TStringlist.Create;
  OpenDialog1.FileName := '*.*';
//  OpenDialog1.Filter := ' (*.*)|*.*';
  success := OpenDialog1.Execute;
  If success = true then begin
     Weatherfilefn := self.OpenDialog1.FileName;
  end;
  if FileExists(WeatherFilefn) then
  begin
    WeatherFile.Free;
    WeatherFile := TTextFileH.create(WeatherFilefn);
    TempString.CommaText := WeatherFile.GetFirstLine;
    FirstWeatherData := round(StrToFloat(TempString.Strings[0]));
    self.LabelFirstWeather.Caption := DateToStr(Firstweatherdata);
    self.LabelFirstWeather.Visible := true;
    self.DateTimePickerStartDate.MinDate := FirstWeatherData;
    DateTimePickerStartDate.visible := true;
    self.LabelStartDate.Visible := true;
    self.DateTimePickerSowingDate.MinDate := FirstWeatherData;
    DateTimePickerSowingDate.visible := true;
    self.LabelSowingDate.Visible := true;
    // TempString := TStringList.Create;

    TempString.CommaText := WeatherFile.GetLastLine;
    LastWeatherData := round(StrToFloat(TempString.Strings[0]));
    self.LabelLastWeather.Caption := DateToStr(Lastweatherdata);
    self.LabelLastWeather.Visible := true;
    self.DateTimePickerEndDate.MaxDate := LastWeatherData;
    self.DateTimePickerHarvestDate.MaxDate := LastWeatherData;
    DateTimePickerHarvestDate.visible := true;
    self.LabelHarvestDate.Visible := true;
    WeatherFile.GoTop;
  end;
  EditWeatherfileName.Text := Weatherfilefn;
  EditWeatherfileName.Visible := true;
  LabelWeatherfilename.Visible := true;
  TempString.Free;


end;

procedure TFormYearAnalysis.SpinEditStartYearChange(Sender: TObject);
var
  day, month, year  : word;
  date : TDateTime;

begin
  self.ControlFileName := EditControlFileName.Text + '_'+InttoStr(self.SpinEditStartYear.Value)+'_'
                                        + inttostr(self.SpinEditEndYear.Value)+'.fn';
  labelControlfile.Caption := ControlFileName;
  LabelControlFile.Update;

  decodedate(self.DateTimePickerHarvestDate.DateTime, year, month, day);
  Year := SpinEditStartYear.Value;
  self.DateTimePickerHarvestDate.DateTime := encodedate(year, month, day);
  self.DateTimePickerHarvestDate.Update;

  decodedate(self.DateTimePickerEndDate.DateTime, year, month, day);
  Year := SpinEditStartYear.Value;
  self.DateTimePickerEndDate.DateTime := encodedate(year, month, day);
  self.DateTimePickerEndDate.Update;


  decodedate(self.DateTimePickerSowingDate.DateTime, year, month, day);
  Year := SpinEditStartYear.Value;
  self.DateTimePickerSowingDate.DateTime := encodedate(year-1, month, day);
  self.DateTimePickerSowingDate.Update;

  decodedate(self.DateTimePickerStartDate.DateTime, year, month, day);
  Year := SpinEditStartYear.Value;
  self.DateTimePickerStartDate.DateTime := encodedate(year-1, month, day);
  self.DateTimePickerStartDate.Update;

end;

procedure TFormYearAnalysis.ButtonStartClick(Sender: TObject);

var
  i, j, index, year : integer;
  CropSimDates  : TCropSimDates;
  SubModelStrings, ParNames, StateNames, inputSections : TStringlist;
  s: string;
  NewDate : integer;
  TemplateInputFile, NewInputFile: TextFile;

begin
  Submodelstrings := TStringlist.Create;
  Parnames := TSTringlist.Create;

//  SowingDateString := self.EditSowingDateString.Text;
//  HarvestDateString := self.EditHarvestDateName.Text;

{  for I := 0 to model.SubModStrList.Count - 1 do begin
    actSubmod := TSubmodel(SubModStrList.objects[i]);
  end; }

  if SowingDateString <> '' then

  StartYear := self.SpinEditStartYear.Value;
  EndYear := self.SpinEditEndYear.Value;

//  NewSowingdate
  NewCropSimDates[SimStart] := round(DateTimePickerStartDate.DateTime);
  NewCropSimDates[SimEnd] := round(DateTimePickerEndDate.DateTime);
  ControlFileName := DirectoryName + LabelControlFile.Caption;
  AssignFile(ControlFile, ControlFileName);
//  closefile(Controlfile);
  rewrite(Controlfile);


  NewCropSimDates[SimStart] := self.DateTimePickerStartDate.DateTime;
  NewCropSimDates[SimEnd] := self.DateTimePickerEndDate.DateTime;


  NewStateIniFileName := DirectoryName + 'State_'+EditControlFileName.text+'.ini';
  NewOptionIniFileName := DirectoryName + 'Options_'+EditControlFileName.text+'.ini';
  CopyFile(PChar(TemplateStateIniFileName), PChar(NewStateIniFileName), False);
  CopyFile(PChar(TemplateOptionIniFileName), PChar(NewOptionIniFileName), False);

  TemplateParIniFile.ReadSections(Submodelstrings);


  for year := StartYear to Endyear do begin
  // Create and modify IniFiles
    NewIniFileName := DirectoryName + EditControlFileName.text+'_'+IntToStr(year)+'.ini';
    writeln(ControlFile, NewIniFileName);
    CopyFile(PChar(TemplateIniFileName), PChar(NewIniFileName), False);
    NewIniFile := TMyIniFile.Create(NewIniFileName);
    NewIniFile.CaseSensitive := false;
    NewIniFile.WriteInteger('TimeInit', 'Startzeit', trunc(NewCropSimDates[SimStart]));
    NewIniFile.WriteInteger('TimeInit', 'Endzeit', trunc(NewCropSimDates[SimEnd]));
    NewIniFile.WriteString('FileNames', 'WeatherFileFN', Weatherfilefn);
    NewIniFile.WriteString('FileNames', 'OptionsIniFN', NewOptionIniFileName);
//    NewIniFile.UpdateFile;
  // Create and modify ParIniFiles

    if TemplateInputFileName <> '' then begin
      NewInputFileName := NewIniFileName;
      NewInputFileName := PathRemoveExtension(NewInputFileName)+'_Input.ini';
      AssignFile(TemplateInputFile, TemplateInputFileName);
      Reset(TemplateInputFile);
      AssignFile(NewInputFile, NewInputFileName);
      Rewrite(NewInputFile);
      while not EOF(TemplateInputFile) do begin
        readln(TemplateInputFile, s);
        if (s <> '')and (s[1]='[') then begin
          s := StrBefore(']',StrAfter('[',s));
          s := DateToStr(IncYear(StrToDate(s),year-StartYear));
          writeln(NewInputFile,'[',s,']');
        end
        else writeln(NewInputFile,s);
      end;
      CloseFile(TemplateInputFile);
      CloseFile(NewInputFile);
    end;

    NewParIniFileName := DirectoryName + 'PAR_'+EditControlFileName.text+'_'+IntToStr(year)+'.ini';
    CopyFile(PChar(TemplateParIniFileName), PChar(NewParIniFileName), False);
    NewStateIniFileName := DirectoryName + 'STATE_'+EditControlFileName.text+'_'+IntToStr(year)+'.ini';
    CopyFile(PChar(TemplateStateIniFileName), PChar(NewStateIniFileName), False);
    NewParIniFile := TMyInifile.Create(NewParIniFileName);
    NewParIniFile.CaseSensitive := false;
    NewIniFile.WriteString('FileNames', 'StateIniFN', NewStateIniFileName);
    NewIniFile.WriteString('FileNames', 'ParamIniFN', NewParIniFileName);
    NewIniFile.UpdateFile;
    NewStateIniFile := TMyInifile.Create(NewStateIniFileName);

    for i := 0 to SubModelStrings.Count - 1 do begin
      NewParIniFile.ReadSection(SubModelStrings[i], ParNames);
      Index := Parnames.Indexof(SowingDateString);

      if  Index <> -1 then
         OldCropSowingDates[i] := DateTimePickerSowingDate.Date;
         NewDate :=  trunc(IncYear(OldCropSowingDates[i],year-StartYear));
        NewParIniFile.WriteInteger(SubModelStrings[i], SowingDateString, NewDate);

      Index := Parnames.Indexof(HarvestDateString);
      if Index <> -1 then
        OldCropHarvestDates[i] := DateTimePickerHarvestDate.Date;
        NewDate := trunc(IncYear(OldCropHarvestDates[i],year-StartYear));
        NewParIniFile.WriteInteger(SubModelStrings[i], HarvestDateString, NewDate);
    end;
    NewParIniFile.UpdateFile;
//  NewYears and Dates
    for  CropSimDates := Low(NewCropSimDates) to high(NewCropSimDates) do
      NewCropSimDates[CropSimDates] := Incyear(NewCropSimDates[CropSimDates],1);
    for i := ord(low(TManagementEvents)) to ord(high(TManagementEvents)) do begin
      NewStateIniFile.EraseSection(TManagementEventStrgs[TManagementEvents(i)]);
      for j := 1 to 100 do if ManagementDates[TManagementEvents(i),j] <> 0 then begin
        s := DateToStr(IncYear(ManagementDates[TManagementEvents(i),j],year-StartYear));
        NewStateIniFile.WriteFloat(TManagementEventStrgs[TManagementEvents(i)],s,ManagementValues[TManagementEvents(i),j]);
      end;
    end;
    NewStateIniFile.UpdateFile;
  end;

  closefile(Controlfile);
  Submodelstrings.free;
  Parnames.free;
end;



procedure TFormYearAnalysis.EditControlFileNameChange(Sender: TObject);
begin
  self.ControlFileName := EditControlFileName.Text + '_'+InttoStr(self.SpinEditStartYear.Value)+'_'
                                        + inttostr(self.SpinEditEndYear.Value)+'.fn';
  labelControlfile.Caption := ControlFileName;
  self.LabelControlFile.Update;
end;

procedure TFormYearAnalysis.EditInputDirectoryChange(Sender: TObject);
begin
  DirectoryName := EditInputDirectory.Text;
end;

procedure TFormYearAnalysis.FormActivate;

var
  I, j: Integer;
  SubMod: TSubModel;
  ActPar: TPar;

begin


  // update_StringGrid(model.reg_fn );
end;



end.
