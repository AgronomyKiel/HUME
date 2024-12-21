unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus, ComCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    btn_start: TButton;
    lst_n_form: TListBox;
    lst_n_menge: TListBox;
    lst_block: TListBox;
    dlgOpen1: TOpenDialog;
    mm1: TMainMenu;
    Datei1: TMenuItem;
    open: TMenuItem;
    Memo1: TMemo;
    dlgSave1: TSaveDialog;

    lbl1: TLabel;
    lbl2: TLabel;

    lbl_block: TLabel;
    btn_save: TButton;
    lst_erntejahr: TListBox;
    lst_vn: TListBox;
    lst_standort: TListBox;
    lst_reihe: TListBox;
    lst_spalte: TListBox;
    lst_fruchtfolge: TListBox;
    lst_aufwuchs: TListBox;
    //lst_methode: TListBox;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl6: TLabel;
    lbl7: TLabel;
    lbl8: TLabel;
    lbl5: TLabel;
    lbl9: TLabel;
    chk_mittelwert: TCheckBox;
    pb: TProgressBar;
    lst_ff_glied: TListBox;
    Label1: TLabel;
    RadioGroup1: TRadioGroup;
    minMittel2: TRadioButton;
    minMittel3: TRadioButton;
    minMittel4: TRadioButton;
    minMittel1: TRadioButton;
    ListBox1: TListBox;
    Label2: TLabel;
    lst_methode: TListBox;
    Label3: TLabel;
    procedure btn_startClick(Sender: TObject);
    procedure openClick(Sender: TObject);
    function ParseRecord(sRecord: string): TStringList;
    procedure btn_saveClick(Sender: TObject);

  private
    { Private declarations }
    procedure init();
    procedure calc();
    procedure setFileName();
    procedure saveToFile();
    function getIndexOf(captions: TStringList; caption: string): integer;
    function getChoosenList(list: TStringList; listbox: TListBox): TStringList;
    //function uniqueAdd(strlist: TStringList; item: string): TStringList;
    procedure sortAndAdd(listbox: TListBox; strlist: TStringList);
  public

    { Public declarations }
  end;

var
  Form1: TForm1;
  captions, dates: TStringList;
  filename: TFileName;
  date_col, erntejahr_col, vn_col, standort_col, reihe_col, spalte_col,
    n_form_col, n_menge_col, block_col, fruchtfolge_col, ff_glied_col,
    aufwuchs_col, methode_col: Integer;
  n_form, n_menge, block: Integer;
  wg_col: array[0..3] of Integer;
  logList: TStringList;
   eingabe_all:  TStringList;
  eingabe_namen: TStringList;
   fileaslist: TStringList;

implementation

{$R *.DFM}

// {$APPTYPE CONSOLE}
{-------------------------------------------------------------------------------
  Procedure: TForm1.setFileName
  Author:    ckluss
  DateTime:  2009.10.19
  Arguments:
  Result:    None
  Comment:
-------------------------------------------------------------------------------}

procedure TForm1.setFileName();
begin
  try
    if dlgOpen1.Execute then
      filename := dlgOpen1.FileName;
  except
    ShowMessage('Fehler beim öffnen der Datei');
  end;
end;

procedure TForm1.saveToFile();
var
  f_save: TFileName;
begin
  try
    if dlgSave1.Execute then begin
      f_save := dlgSave1.FileName;
      memo1.lines.savetofile(f_save);
    end;
  except
    ShowMessage('Fehler beim öffnen der Datei');
  end;
end;

function isSelected(listbox: TListBox): Boolean;
var
  i: Integer;
begin
  result := false;
  for i := 0 to listbox.Items.Count - 1 do begin
    result := listbox.selected[i];
    if result then break;
  end;
end;

{-------------------------------------------------------------------------------
  Procedure: TForm1.btn_startClick
  Author:    ckluss
  DateTime:  2009.10.19
  Arguments: Sender: TObject
  Comment: ListBoxen werden aktualisiert und die Mittelwertberechnung
           der Wassergehalte wird gestartet.
-------------------------------------------------------------------------------}

procedure TForm1.btn_startClick(Sender: TObject);
begin
  if filename = '' then begin
    setFilename;
    init();
  end else begin

    if not (isSelected(lst_n_form) and isSelected(lst_n_menge) and
      isSelected(lst_block) and isSelected(lst_erntejahr) and
      isSelected(lst_vn) and isSelected(lst_standort) and
      isSelected(lst_reihe) and isSelected(lst_spalte) and
      isSelected(lst_fruchtfolge) and isSelected(lst_aufwuchs) and
      isSelected(lst_ff_glied)
      //and      isSelected(lst_methode)
      )
      then begin
      ShowMessage('In jeder ListBox muss mindestens ein Eintrag selektiert sein!')
    end else
      calc();

  end;

end;

{-------------------------------------------------------------------------------
  Procedure: TForm1.Button1Click
  Author:    ckluss
  DateTime:  2009.10.19
  Arguments: Sender: TObject
  Result:    None
  Comment:
-------------------------------------------------------------------------------}

procedure TForm1.btn_saveClick(Sender: TObject);
begin
  saveToFile();
end;

function TForm1.getIndexOf(captions: TStringList; caption: string): integer;
var
  idx: Integer;
begin
  idx := captions.IndexOf(caption);

  if (idx < 0) and (caption = 'Datum') then
    idx := captions.IndexOf('Time');


  if (idx < 0) then
    ShowMessage('Die Spalte ' + caption +
      ' wurde in der CSV Datei in Zeile 2 nicht gefunden!');
  result := idx;
end;

function createUniqueAndSortedStrList(): TStringList;
var
  list: TStringList;
begin
  list := TStringList.Create;
  list.Sorted := True;
  list.Duplicates := dupIgnore;
  result := list;
end;

procedure TForm1.sortAndAdd(listbox: TListBox; strlist: TStringList);
var
  i: Integer;
begin
  listbox.Clear;
  listbox.Items.AddStrings(strlist);

  for i := 0 to listbox.Items.Count - 1 do begin
    listbox.Selected[i] := True;
  end;
end;

{-------------------------------------------------------------------------------
  Procedure: TForm1.init
  Author:    ckluss
  DateTime:  2009.10.18
  Comment: Initialisiert anhand der aktuellen CSV Datei die globalen
           StringListen
-------------------------------------------------------------------------------}

procedure TForm1.init();
var
  f: TextFile;
  i: Integer;
  list: TStringList;
  line: string;
  n_formen, n_mengen, vns, bloecke, erntejahre, standorte, reihen, spalten,
    fruchtfolgen, ff_glieder, aufwuechse, methoden: TStringList;
begin
  dates := createUniqueAndSortedStrList();
  n_formen := createUniqueAndSortedStrList();
  n_mengen := createUniqueAndSortedStrList();
  bloecke := createUniqueAndSortedStrList();
  erntejahre := createUniqueAndSortedStrList();
  standorte := createUniqueAndSortedStrList();
  reihen := createUniqueAndSortedStrList();
  spalten := createUniqueAndSortedStrList();
  fruchtfolgen := createUniqueAndSortedStrList();
  aufwuechse := createUniqueAndSortedStrList();
  vns := createUniqueAndSortedStrList();
  ff_glieder := createUniqueAndSortedStrList();

  methoden := createUniqueAndSortedStrList();

  eingabe_all := TStringList.Create;
  eingabe_namen := TStringList.Create;

  assignfile(f, filename);
  reset(f);
  Readln(f, line);
  Readln(f, line);
  captions := ParseRecord(line); // alle Spaltenüberschriften

  date_col := getIndexOf(captions, 'Datum'); //'Time');
  erntejahr_col := getIndexOf(captions, 'Erntejahr');
  vn_col := getIndexOf(captions, 'VN');
  standort_col := getIndexOf(captions, 'Standort');
  reihe_col := getIndexOf(captions, 'Reihe');
  spalte_col := getIndexOf(captions, 'Spalte');
  fruchtfolge_col := getIndexOf(captions, 'Fruchtfolge');
  ff_glied_col := getIndexOf(captions, 'FF-Glied');
  n_form_col := getIndexOf(captions, 'N-Form');
  n_menge_col := getIndexOf(captions, 'N-Menge');
  block_col := getIndexOf(captions, 'Block');
  aufwuchs_col := getIndexOf(captions, 'Aufwuchs');
  methode_col := captions.IndexOf('Methode');

  while (not eof(f)) do begin
    Readln(f, line);
    list := ParseRecord(line);
    dates.Add(list[date_col]);
    n_formen.Add(list[n_form_col]);
    n_mengen.Add(list[n_menge_col]);
    bloecke.Add(list[block_col]);
    erntejahre.Add(list[erntejahr_col]);
    standorte.Add(list[standort_col]);
    reihen.Add(list[reihe_col]);
    spalten.Add(list[spalte_col]);
    fruchtfolgen.Add(list[fruchtfolge_col]);
    ff_glieder.Add(list[ff_glied_col]);
    aufwuechse.Add(list[aufwuchs_col]);
    if methode_col <> -1 then
      methoden.Add(list[methode_col]);

    vns.Add(list[vn_col]);
  end;
  CloseFile(f);

  sortAndAdd(lst_n_form, n_formen);
  sortAndAdd(lst_n_menge, n_mengen);
  sortAndAdd(lst_block, bloecke);
  sortAndAdd(lst_erntejahr, erntejahre);
  sortAndAdd(lst_standort, standorte);
  sortAndAdd(lst_reihe, reihen);
  sortAndAdd(lst_spalte, spalten);
  sortAndAdd(lst_fruchtfolge, fruchtfolgen);
  sortAndAdd(lst_aufwuchs, aufwuechse);
  sortAndAdd(lst_methode, methoden);
  //sortAndAdd(lst_prioritaet, methoden);
  sortAndAdd(lst_vn, vns);
  sortAndAdd(lst_ff_glied, ff_glieder);

  list.Free;

  n_formen.Free;
  n_mengen.Free;
  bloecke.Free;
  erntejahre.Free;
  standorte.Free;
  reihen.Free;
  spalten.Free;
  fruchtfolgen.Free;
  aufwuechse.Free;
  vns.Free;
  ff_glieder.Free;

  fileaslist := TStringList.Create;
  fileaslist.LoadFromFile(filename);

  eingabe_all := ParseRecord(fileaslist[1]);

  line := 'Time';

  for i := date_col + 1 to eingabe_all.count - 1 do begin
    eingabe_namen.Add(eingabe_all[i]);
    line := line + '  ' +  eingabe_all[i];
  end;

  sortAndAdd(ListBox1,eingabe_namen);

end;

function TForm1.getChoosenList(list: TStringList; listbox: TListBox):
  TStringList;
var
  i: Integer;
begin
  for i := 0 to listbox.Items.Count - 1 do
    if (listbox.selected[i]) then
      list.add(listbox.Items[i]);
  result := list;
end;

{-------------------------------------------------------------------------------
  Procedure: isInList
  Author:    ckluss
  DateTime:  2009.10.20
  Arguments: list: TStringList; item: string
  Result:    Boolean
  Comment:
-------------------------------------------------------------------------------}

function isInList(list: TStringList; item: string): Boolean;
begin
  result := list.IndexOf(item) >= 0
end;

{-------------------------------------------------------------------------------
  Procedure: TForm1.calc
  Author:    ckluss
  DateTime:  2009.10.18
  Comment: gruppiert anhand Datum und bildet Mittelwerte für die Wassermengen
-------------------------------------------------------------------------------}

procedure TForm1.calc();
var
  //f: TextFile;

  nameidx: Integer;

  line: string;
  list, list2: TStringList;
  i, j, k, l, m, idx, idx2: Integer;
  time, time_act: Integer;

  n_formen_choosen, n_mengen_choosen, bloecke_choosen, block_chosen,
    erntejahre_choosen, vn_choosen, standorte_choosen, reihen_choosen,
    spalten_choosen, fruchtfolgen_choosen, ff_glieder_choosen,
    aufwuechse_choosen, methoden_choosen, prioritaeten_choosen: TStringList;

  eingabe_count: array of Integer; // TStringList;
  eingabe_sum : array of Double; // TStringList;

  eingabe: String;

  name_choosen: TStringList;


  block_act, n_menge_act, n_form_act, erntejahr_act, vn_act, standort_act,
    reihe_act, spalte_act, fruchtfolge_act,
    aufwuchs_act, methode_act, ff_glied_act: string;

  d: double;
  code, min: Integer;
  logline: string;
  myFile : TextFile;
begin
  n_formen_choosen := TStringList.Create;
  n_mengen_choosen := TStringList.Create;
  bloecke_choosen := TStringList.Create;
  erntejahre_choosen := TStringList.Create;
  vn_choosen := TStringList.Create;
  standorte_choosen := TStringList.Create;
  reihen_choosen := TStringList.Create;
  spalten_choosen := TStringList.Create;
  fruchtfolgen_choosen := TStringList.Create;
  aufwuechse_choosen := TStringList.Create;
  ff_glieder_choosen := TStringList.Create;
  methoden_choosen := TStringList.Create;


  name_choosen := TStringList.Create;

  logList := TStringList.Create();

  Memo1.Clear();
  memo1.Lines.BeginUpdate();

  fileaslist := TStringList.Create;
  fileaslist.LoadFromFile(filename);

  eingabe_all := ParseRecord(fileaslist[1]);

  line := 'Time';

  for i := date_col + 1 to eingabe_all.count - 1 do begin
    eingabe_namen.Add(eingabe_all[i]);
    line := line + '  ' +  eingabe_all[i];
  end;

  memo1.Lines.Add(line);

  setlength(eingabe_count,eingabe_namen.Count);
  SetLength(eingabe_sum,eingabe_namen.Count);

  n_formen_choosen := getChoosenList(n_formen_choosen, lst_n_form);
  n_mengen_choosen := getChoosenList(n_mengen_choosen, lst_n_menge);
  bloecke_choosen := getChoosenList(bloecke_choosen, lst_block);
  erntejahre_choosen := getChoosenList(erntejahre_choosen, lst_erntejahr);
  vn_choosen := getChoosenList(vn_choosen, lst_vn);
  standorte_choosen := getChoosenList(standorte_choosen, lst_standort);
  reihen_choosen := getChoosenList(reihen_choosen, lst_reihe);
  spalten_choosen := getChoosenList(spalten_choosen, lst_spalte);
  fruchtfolgen_choosen := getChoosenList(fruchtfolgen_choosen, lst_fruchtfolge);
  ff_glieder_choosen := getChoosenList(ff_glieder_choosen, lst_ff_glied);
  aufwuechse_choosen := getChoosenList(aufwuechse_choosen, lst_aufwuchs);
  name_choosen := getChoosenList(name_choosen, ListBox1);

  methoden_choosen  := getChoosenList(methoden_choosen, lst_methode);

  pb.Max := dates.Count;
  pb.Step := 1;

  AssignFile(myFile, 'log.txt');
  ReWrite(myFile);

  for i := 0 to dates.Count - 1 do begin
    time := StrToInt(dates[i]);


    for k := 0 to eingabe_namen.count - 1 do begin
      eingabe_count[k] := 0;
      eingabe_sum[k] := 0;
    end;

    for k := 2 to fileaslist.Count - 1 do  begin
      line := fileaslist[k];
      list := ParseRecord(line);

      time_act := StrToInt(list[date_col]);
      n_form_act := list[n_form_col];
      n_menge_act := list[n_menge_col];
      block_act := list[block_col];
      erntejahr_act := list[erntejahr_col];
      vn_act := list[vn_col];
      standort_act := list[standort_col];
      reihe_act := list[reihe_col];
      spalte_act := list[spalte_col];
      n_form_act := list[n_form_col];
      n_menge_act := list[n_menge_col];
      block_act := list[block_col];
      fruchtfolge_act := list[fruchtfolge_col];
      ff_glied_act := list[ff_glied_col];
      aufwuchs_act := list[aufwuchs_col];

      if methode_col <> -1 then
        methode_act := list[methode_col];

      if (time_act = time)
        and isInList(n_formen_choosen, n_form_act)
        and isInList(n_mengen_choosen, n_menge_act)
        and isInList(bloecke_choosen, block_act)
        and isInList(erntejahre_choosen, erntejahr_act)
        and isInList(vn_choosen, vn_act)
        and isInList(standorte_choosen, standort_act)
        and isInList(reihen_choosen, reihe_act)
        and isInList(spalten_choosen, spalte_act)
        and isInList(fruchtfolgen_choosen, fruchtfolge_act)
        and isInList(ff_glieder_choosen, ff_glied_act)
        and isInList(aufwuechse_choosen, aufwuchs_act)
        and ((methode_col = -1) or isInList(methoden_choosen, methode_act))
        then begin

        line := IntToStr(time) + '   ';

        for j := 0 to eingabe_namen.Count - 1 do begin

          eingabe := list[eingabe_all.IndexOf(eingabe_namen[j])];

          val(eingabe, d, code);
          if chk_mittelwert.Checked then begin
            if (code = 0) and (d > 0) then begin
              eingabe_sum[j] := eingabe_sum[j] + d;
              Inc(eingabe_count[j]);
            end;
          end else begin
            if isInList(name_choosen, eingabe_namen[j]) then begin
              line := line + '   ' + eingabe;
            end;
          end;
        end;

        if not chk_mittelwert.Checked then
          memo1.Lines.Add(line);
      end;
      list.Free;

    end;

    if chk_mittelwert.Checked then begin

      if minMittel1.checked then min := 1
      else if minMittel2.checked then min := 2
      else if minMittel3.Checked then min := 3
      else if minMittel4.checked then min := 4;

      line := IntToStr(time) + '   ';
      logline := IntToStr(time);

      for j := 0 to eingabe_namen.Count - 1 do begin

          if (eingabe_count[j] >= min) then begin
            line := line + floattostr(eingabe_sum[j] / eingabe_count[j]) + '   ';
            logline := logline + '; ' + IntToStr(eingabe_count[j]);
          end else  begin
            line := line + ' .  ';
            logline := logline + '; 0'
          end;


      end;

      loglist.Add(logline);
      memo1.Lines.Add(line);
    end;

    pb.StepIt;
  end;
  memo1.Lines.EndUpdate();
  //CloseFile(f);

  logList.SaveToFile('Anzahl_Werte_fuer_Mittelwert.log');
  logList.Free;

  n_formen_choosen.Free;
  n_mengen_choosen.Free;
  bloecke_choosen.Free;
  erntejahre_choosen.Free;
  vn_choosen.Free;
  standorte_choosen.Free;
  reihen_choosen.Free;
  spalten_choosen.Free;
  fruchtfolgen_choosen.Free;
  aufwuechse_choosen.Free;
  methoden_choosen.Free;
  ff_glieder_choosen.Free;

  closefile(myFile);
end;

{-------------------------------------------------------------------------------
  Procedure: TForm1.openClick
  DateTime:  2009.10.19
  Arguments: Sender: TObject
  Comment:
-------------------------------------------------------------------------------}

procedure TForm1.openClick(Sender: TObject);
begin
  setFileName();
  init();
end;

{-------------------------------------------------------------------------------
  Procedure: TForm1.ParseRecord
  Author:    ckluss
  DateTime:  2009.10.18
  Arguments: sRecord: durch Semikolon getrennte CSV-Zeilen
             (zum Beispiel Excel-Tabelle als CSV exportiert)
  Result:    TStringList
-------------------------------------------------------------------------------}
// Quelle: http://www.festra.com/eng/les17.htm
// weil DelimitedText in Delphi 5 nicht funktioniert

function TForm1.ParseRecord(sRecord: string): TStringList;
var
  PosComma: integer;
  sField: string;
  list: TStringList;
begin
  list := TStringList.Create;
  sRecord := StringReplace(sRecord, '"', '', [rfReplaceAll]);
  repeat
    PosComma := Pos(';', sRecord);
    if PosComma > 0 then
      sField := Copy(sRecord, 1, PosComma - 1)
    else
      sField := sRecord;
    list.Add(sField);
    if PosComma > 0 then begin
      Delete(sRecord, 1, PosComma);
    end;
  until PosComma = 0;
  result := list;
end;

end.

