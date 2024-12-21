unit UChangeDirs;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, FileCtrl, IniFilesNew, Grids, Outline, DirOutln,
  AdvGrid, ExtCtrls, ComCtrls, BaseGrid;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Panel1: TPanel;
    EditFNfile: TEdit;
    BitBtnFN: TBitBtn;
    ButtonChange: TButton;
    LabelFNFile: TLabel;
    LabelSourceDirectory: TLabel;
    LabelDestDirectory: TLabel;
    DirectoryListBoxSource: TDirectoryListBox;
    DriveComboBoxSource: TDriveComboBox;
    DriveComboBoxDest: TDriveComboBox;
    DirectoryListBoxDest: TDirectoryListBox;
    EditSource: TEdit;
    EditDest: TEdit;
    TabSheetDataNames: TTabSheet;
    AdvStringGrid1: TAdvStringGrid;
    ButtonLoadDataNames: TButton;
    ButtonChangeDataVarNames: TButton;
    procedure BitBtnFNClick(Sender: TObject);
    procedure DriveComboBoxSourceChange(Sender: TObject);
    procedure DriveComboBoxDestChange(Sender: TObject);
    procedure DirectoryListBoxSourceChange(Sender: TObject);
    procedure DirectoryListBoxDestChange(Sender: TObject);
    procedure ButtonChangeClick(Sender: TObject);
    procedure ButtonLoadDataNamesClick(Sender: TObject);
    procedure ButtonChangeDataVarNamesClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation


{$R *.DFM}

procedure TForm1.BitBtnFNClick(Sender: TObject);
begin
   self.OpenDialog1.Filter := 'Controlfiles (*.fn)|*.FN';
   self.OpenDialog1.Execute;
   If Fileexists(OpenDialog1.FileName) then begin
     self.EditFNfile.text := self.OpenDialog1.FileName;
   end;
end;

procedure TForm1.DriveComboBoxSourceChange(Sender: TObject);
begin
   self.DirectoryListBoxSource.Drive := self.DriveComboBoxSource.Drive;
   self.DriveComboBoxSource.Update;
end;

procedure TForm1.DriveComboBoxDestChange(Sender: TObject);
begin
   self.DirectoryListBoxDest.Drive := self.DriveComboBoxDest.Drive;
   self.DriveComboBoxDest.Update;

end;

procedure TForm1.DirectoryListBoxSourceChange(Sender: TObject);
begin
  self.EditSource.Text := self.DirectoryListBoxSource.Directory;
end;

procedure TForm1.DirectoryListBoxDestChange(Sender: TObject);
begin
  self.EditDest.Text := self.DirectoryListBoxDest.Directory;

end;

procedure TForm1.ButtonChangeClick(Sender: TObject);

var
  SourceDir,
  DestDir,
  FNName,
  IniFileFN,
  InString, NewString,
  SectStr,
  KeyString,
  NewDirString,
  oldpath, newpath
   : string;

  NewStrings : TStringList;

  Controlfile : textfile;
  Inifile : TextFile;
  NewIniFile : TMyIniFile;

  i : integer;

begin
//  If NewStrings = nil then
    NewStrings := TStringlist.Create;

   If fileexists(EditFNfile.Text) and (EditSource.text <> '') and (EditDest.text <> '') then begin
     FNName := EditFNfile.Text;
     SourceDir := Editsource.text;
     DestDir := EditDest.text;
   end;

   assignfile(Controlfile,fnName);
   reset(Controlfile);
   while not eof(Controlfile) do begin
     readln(ControlFile, InifileFN);
     if fileexists(IniFileFN) = FALSE then
     begin
        IniFileFN := extractFilename(IniFileFN);
        IniFileFN := EditDest.text+IniFileFN;
     end;
     assignfile(Inifile, IniFileFN);
     reset(Inifile);
     If NewStrings.Count >0 then
       NewStrings.Clear;
     while not eof(Inifile) do begin
       readln(Inifile, InString);
       NewString := StringReplace(InString, SourceDir, DestDir,[rfReplaceAll, rfIgnoreCase]);
       If length(NewString)>0 then
         if (NewString[1] = '[') then
           SectStr := NewString;
       if NewString <> InString then
         NewStrings.Add(SectStr+NewString);


     end;
     closefile(IniFile);
     If NewStrings.Count > 0 then begin
       If NewIniFile = nil then
         NewInifile := TMyInifile.Create;
       NewInifile.Init(InifileFN);
       For i := 0 to NewStrings.count-1 do begin
         KeyString := copy(NewStrings.Strings[i],    pos(']', NewStrings.Strings[i])+1, pos('=', NewStrings.Strings[i])-pos(']', NewStrings.Strings[i])-1);
         NewDirString := copy(NewStrings.Strings[i], pos('=', NewStrings.Strings[i])+1, length(NewStrings.Strings[i])-pos('=', NewStrings.Strings[i]));
         SectStr :=  copy(NewStrings.Strings[i], 2, pos(']', NewStrings.Strings[i])-2);
         NewIniFile.WriteString(SectStr, KeyString, NewDirString);
       end;

     end;

   end;
   closefile(controlFile);

end;

procedure TForm1.ButtonLoadDataNamesClick(Sender: TObject);

var
  FNName,
  IniFileFN,
  InString, 
  DataFileName,
  ColNames
   : string;

  DataStrings,
  SubModMeasFiles,
    ColStrLST,
    DataNameStrLst : TStringList;

  Controlfile, DataFile : textfile;
  Inifile : TMyIniFile;

  i,j : integer;


begin

  DataStrings := TStringlist.Create;
  SubModMeasFiles := TStringlist.Create;
  Inifile := TMyIniFile.create;
  colStrLst := TStringList.create;
  DataNameStrLst := TStringList.create;
  DataNameStrLst.Sorted := true;
  DataNameStrLst.Duplicates := dupIgnore;

   If fileexists(EditFNfile.Text) then begin
     FNName := EditFNfile.Text;
   end;

   assignfile(Controlfile,fnName);
   reset(Controlfile);
   while not eof(Controlfile) do begin
     readln(ControlFile, InifileFN);
     IniFile.Init(IniFileFN);
     Inifile.ReadSection('MeasurementFiles', SubModMeasFiles);
     For i := 0 to SubModMeasFiles.count-1 do begin
       DataFileName := Inifile.ReadString('MeasurementFiles', SubModMeasFiles.Strings[i],'');
       if FileExists(DataFileName) then begin
         assignfile(DataFile, DataFileName);
         reset(DataFile);
         readln(DataFile, ColNames);
         closefile(DataFile);
         ColStrLst.Clear;
         ColStrLst.CommaText := ColNames;
         for J := 0 to ColStrLst.count-1 do
           DatanameStrLst.add(ColStrLst.strings[j]);


       end;

     end;

   end;
   closefile(controlFile);
   AdvStringGrid1.RowCount := DatanameStrLst.count+1;
   for I := 0 to DatanameStrLst.count-1 do
     self.AdvStringGrid1.Cells[0, i+1] := DataNameStrLst.Strings[i];


  DataStrings.free;
  Inifile.free;
  SubModMeasFiles.free;
  ColStrLst.free;
  DataNameStrLst.free;


end;

procedure TForm1.ButtonChangeDataVarNamesClick(Sender: TObject);

var
  FNName,
  IniFileFN,
  InString, NewString,
  SectStr,
  KeyString,
  NewDirString,
  DataFileName,
  ColNames, NewcolNames
   : string;

  DataStrings,
  SubModMeasFiles,
    ColStrLST,
    DataNameStrLst,
    DatSTrings : TStringList;

  Controlfile, DataFile : textfile;
  Inifile : TMyIniFile;
  NewIniFile : TMyIniFile;

  i,j,k : integer;

begin
  Inifile := TMyIniFile.create;
  SubModMeasFiles := TStringlist.Create;
  DatStrings  := TStringlist.Create;


  for i := 1 to self.AdvStringGrid1.RowCount do begin
    If self.AdvStringGrid1.Cells[1,i] <> '' then begin
      If fileexists(EditFNfile.Text) then
        FNName := EditFNfile.Text;

      assignfile(Controlfile,fnName);
      reset(Controlfile);
      while not eof(Controlfile) do begin
        readln(ControlFile, InifileFN);
        IniFile.Init(IniFileFN);
        Inifile.ReadSection('MeasurementFiles', SubModMeasFiles);
        For j := 0 to SubModMeasFiles.count-1 do begin
          DataFileName := Inifile.ReadString('MeasurementFiles', SubModMeasFiles.Strings[j],'');
          if FileExists(DataFileName) then begin
            assignfile(DataFile, DataFileName);
            reset(DataFile);
            readln(DataFile, ColNames);
            DatStrings.Clear;
            while not eof(DATAfile) do begin
              readln(DATAfile, NewString);
              DatSTrings.add(NewString);
            end;
            closefile(DataFile);
            NewColNames := StringReplace(ColNames, AdvStringGrid1.Cells[0,i], AdvStringGrid1.Cells[1,i],[rfReplaceAll, rfIgnoreCase]);
            rewrite(DataFile);
            writeln(DataFile, NewcolNames);
            for k := 0 to DatStrings.count-1 do
              writeln(DataFile, DatStrings.strings[k]);
            closefile(DATAfile);
          end;
        end;
      end;
    end;  
  end;
  Inifile.free;
  SubModMeasFiles.free;
  DatStrings.free;
end;  
end.
