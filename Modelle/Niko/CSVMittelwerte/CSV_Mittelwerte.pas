unit CSV_Mittelwerte;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, StdCtrls, ComCtrls, Math, FileCtrl;

type
  TMyStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

type
  TForm1 = class(TForm)
    ScrollBox1: TScrollBox;
    ListBox_Output: TListBox;
    pb: TProgressBar;
    chk_mittelwerte: TCheckBox;
    mm1: TMainMenu;
    Datei1: TMenuItem;
    mniOeffnen1: TMenuItem;
    btn2: TButton;
    edtSpeicherort: TEdit;
    lblSpeicherort: TLabel;
    btn3: TButton;
    mniHilfe1: TMenuItem;
    cbb_minmittel: TComboBox;
    lbl1: TLabel;
    chk_statistik: TCheckBox;
    chkWithCaptions: TCheckBox;
    edtDateiEndung: TEdit;
    lbl2: TLabel;
    lbl3: TLabel;
    cbbSonstigeSpaltenBreite: TComboBox;
    cbbTimeSpaltenbreite: TComboBox;
    lbl4: TLabel;
    function getFileName(): string;
    procedure InitListBoxes();
    procedure calc();
    procedure btn1Click(Sender: TObject);
    procedure mniOeffnen1Click(Sender: TObject);
    procedure oeffnen();
    procedure btn3Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure generateIndexArray();
    procedure mniHilfe1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;
  listboxes_input: TStringList;
  checkboxes_input: TStringList;
  editfield_input: TStringList;
  csv_strlist: TMyStringList;
  captions: TStringList;
  dates: TStringList;
  date_col: Integer;
  firstline: TStringList;
  unitrow: TStringList;
  combinations: array of array of Integer;

implementation

procedure QuickSort(var A: array of double);

  procedure Quick_Sort(var A: array of double; iLo, iHi: Integer);
  var
    Lo, Hi: Integer;
    Mid, T: double;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := A[(Lo + Hi) div 2];
    repeat
      while A[Lo] < Mid do Inc(Lo);
      while A[Hi] > Mid do Dec(Hi);
      if Lo <= Hi then begin
        T := A[Lo];
        A[Lo] := A[Hi];
        A[Hi] := T;
        Inc(Lo);
        Dec(Hi);
      end;
    until Lo > Hi;
    if Hi > iLo then Quick_Sort(A, iLo, Hi);
    if Lo < iHi then Quick_Sort(A, Lo, iHi);
  end;

begin
  Quick_Sort(A, Low(A), High(A));
end;

function TMyStringList.CompareStrings(const S1, S2: string): Integer;
var
  list: TStringList;
  time1, time2: Integer;
begin

  list := TStringList.Create;
  list.Delimiter := ';';
  list.StrictDelimiter := True;
  list.DelimitedText := s1;
  time1 := StrToInt(list[date_col]); // date_col
  list.DelimitedText := s2;
  time2 := StrToInt(list[date_col]);
  result := CompareValue(time1, time2);
  list.Free;
end;

{$R *.dfm}

function TForm1.getFileName(): string;
var
  dlgOpen: TOpenDialog;
begin
  result := '';
  dlgOpen := TOpenDialog.Create(self);
  try
    if dlgOpen.Execute then
      result := dlgOpen.FileName;
  except
  end;
  dlgOpen.Free;
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

procedure TForm1.InitListBoxes();
var
  i, j, x: Integer;
  actlistbox: TListBox;
  actlabel: TLabel;
  actedit: TEdit;
  actchb: TCheckbox;
  strList: TStringList;

  actlist: TStringList;
  line: TStringList;
  output_strlist: TStringList;
  maxWidth: Integer;
begin

  ScrollBox1.CleanupInstance;

  strList := TStringList.Create;
  actlist := TStringList.create;
  line := TStringList.Create;
  checkboxes_input := TStringList.Create;
  editfield_input := TStringList.Create;

  for i := 0 to captions.Count - 1 do begin
    if AnsiCompareText(Trim(firstline[i]), 'code') = 0 then
      strList.AddObject(captions[i], createUniqueAndSortedStrList);
  end;

  output_strlist := createUniqueAndSortedStrList;
  line.Delimiter := ';';
  line.StrictDelimiter := True;
  dates := createUniqueAndSortedStrList;

  // lesen der Daten für Auswahllisten aus der CSV-Datei
  for i := 2 to csv_strlist.Count - 1 do begin
    line.DelimitedText := csv_strlist[i];

    for j := 0 to captions.Count - 1 do begin
      line[j] := trim(line[j]);
      if (line[j] <> '') and (line[j] <> '.') and
        (AnsiCompareText(Trim(firstline[j]), 'code') = 0) then
        (strList.Objects[strList.IndexOf(captions[j])] as
          TStringList).Add(line[j]);
    end;
    dates.Add(line[date_col]);
  end;

  x := 0;

  // Eingabe-Auswahllisten generieren
  for i := 0 to captions.Count - 1 do begin
    if i >= firstline.Count then break;

    if AnsiCompareText(Trim(firstline[i]), 'code') = 0 then begin
      actlistbox := TListBox.Create(self);
      actlabel := TLabel.Create(self);
      actedit := TEdit.Create(self);
      actchb := TCheckBox.Create(self);

      actlist.Clear;

      with actlabel do begin
        Parent := ScrollBox1;
        Left := x;
        Caption := captions[i];
        actlist.Add(captions[i]);
      end;

      with actlistbox do begin
        Top := 20;
        Parent := ScrollBox1;
        Left := x;
        MultiSelect := True;
        Height := 70;

        actlist.AddStrings(strList.Objects[strList.IndexOf(captions[i])] as
          TStringList);
        Items.AddStrings(strList.Objects[strList.IndexOf(captions[i])] as
          TStringList);

        SelectAll;

        maxWidth := 0;
        for j := 0 to actlist.Count - 1 do begin
          maxWidth := Math.max(maxWidth, canvas.TextWidth(actlist[j]) + 10);
        end;

        maxwidth := Math.Max(maxWidth, 60);
        Width := maxWidth;
      end;

      with actchb do begin
        Parent := ScrollBox1;
        Left := x;
        Top := 90;
        Caption := 'seperate';
      end;

      with actedit do begin
        Parent := ScrollBox1;
        Left := x;
        Width := maxWidth;
        Top := 110;
      end;

      x := x + maxWidth + 5;

      listboxes_input.AddObject(captions[i], actlistbox);
      editfield_input.AddObject(captions[i], actedit);
      checkboxes_input.AddObject(captions[i], actchb);

    end else begin
      if AnsiCompareText(Trim(firstline[i]), 'data') = 0 then begin
        output_strlist.Add(captions[i])
      end;
    end;
  end;

  ListBox_Output.Clear;
  ListBox_Output.Items.AddStrings(output_strlist);
  ListBox_Output.SelectAll;
end;

procedure TForm1.btn1Click(Sender: TObject);
begin
  if csv_strlist = nil then
    oeffnen()
  else
    calc();
end;

procedure TForm1.generateIndexArray();
var
  i, j, k: Integer;
  ls: array of Integer;
  p, count: Integer;
  s: string;
begin
  count := listboxes_input.Count;
  SetLength(ls, count);

  p := 1;
  for i := 0 to count - 1 do begin
    if (checkboxes_input.objects[i] as TCheckBox).checked then
      ls[i] := (listboxes_input.objects[i] as TListBox).Count
    else
      ls[i] := 1;

    p := p * ls[i];
  end;

  SetLength(combinations, p);

  for i := 0 to p - 1 do begin
    SetLength(combinations[i], count);
  end;

  for i := 1 to p - 1 do begin

    for j := 0 to count - 1 do begin
      if combinations[i - 1, j] < ls[j] - 1 then begin
        combinations[i, j] := combinations[i - 1, j] + 1;
        for k := j + 1 to count - 1 do
          combinations[i, k] := combinations[i - 1, k];
        Break;
      end else
        combinations[i, j] := 0;
    end;

    s := '';
    for j := 0 to count - 1 do
      s := s + ' ' + IntToStr(combinations[i, j]);
  end;
end;

procedure TForm1.btn2Click(Sender: TObject);
var
  chosenDirectory: string;
begin
  if csv_strlist = nil then begin
    oeffnen();
  end else begin
    if edtSpeicherort.Text = '' then begin
      if (SelectDirectory('Speicherort für die generierten Dateine auswählen',
        '', chosenDirectory)) then begin
        edtSpeicherort.Text := chosenDirectory;
        calc();
      end;
    end else begin
      calc();
    end;
  end;
end;

procedure TForm1.btn3Click(Sender: TObject);
var
  chosenDirectory: string;
begin
  SelectDirectory('Bitte den Speicherort für die genierierten Dateien auswählen',
    '', chosenDirectory);
  edtSpeicherort.Text := chosenDirectory;
end;

procedure TForm1.calc();
var
  nameidx: Integer;
  captionline, line, eingabe, unitline: string;
  list, list2: TStringList;
  i, j, k, l, m, idx, idx2, n: Integer;
  time, time_act: Integer;
  choosen, eingabe_namen: TStringList;

  eingabe_count: array of Integer;
  eingabe_sum: array of Double;

  eingabe_werte: array of TStringList;

  name_choosen, act: TStringList;
  actlistbox: TListBox;
  d: double;
  code, min: Integer;
  logline: string;
  success: Boolean;
  actcaption: string;
  spalte, zeile: Integer;
  reslist: TStringList;
  fn, sel: string;
  actcheckbox: TCheckBox;

  doublearr: array of Double;
  median: double;

begin
  // combinations ausrechnen!

  generateIndexArray();

  min := 1;
  if (cbb_minmittel.ItemIndex >= 0) and
    (Trim(cbb_minmittel.items[cbb_minmittel.ItemIndex]) <> '') then
    min := StrToInt(Trim(cbb_minmittel.items[cbb_minmittel.ItemIndex]));

  reslist := TStringList.Create;
  eingabe_namen := TStringList.Create;
  list := TStringList.Create;

  captionline := 'Time';
  unitline := '[d]';

  for i := 0 to listbox_output.count - 1 do begin
    if ListBox_Output.Selected[i] then begin
      eingabe_namen.Add(ListBox_Output.items[i]);
      captionline := captionline + '  ' + ListBox_Output.items[i];

      if chk_statistik.Checked then begin
        captionline := captionline + '  ' + ListBox_Output.items[i] + '_[n]';
        captionline := captionline + '  ' + ListBox_Output.items[i] + '_[min]';
        captionline := captionline + '  ' + ListBox_Output.items[i] + '_[max]';
        captionline := captionline + '  ' + ListBox_Output.items[i] +
          '_[median]';
        captionline := captionline + '  ' + ListBox_Output.items[i] + '_[sd]';
        captionline := captionline + '  ' + ListBox_Output.items[i] + '_[sem]';

        unitline := unitline + ' [] [] [] [] [] []';
      end;

      j := captions.IndexOf(ListBox_Output.items[i]);
      if (j >= 0) then
        unitline := unitline + ' ' + unitrow[j]
      else
        unitline := unitline + ' []';
    end;
  end;

  setlength(eingabe_count, eingabe_namen.Count);
  SetLength(eingabe_sum, eingabe_namen.Count);
  SetLength(eingabe_werte, eingabe_namen.Count);

  for k := 0 to eingabe_namen.count - 1 do begin
    eingabe_werte[k] := TStringList.Create;
  end;

  pb.Max := Length(combinations) * dates.count; // dates.Count;
  pb.Step := 1;
  list.Delimiter := ';';
  list.StrictDelimiter := True;

  for zeile := 0 to Length(combinations) - 1 do begin
    reslist.Clear;
    if (chkWithCaptions.checked) then begin
      reslist.Add(captionline);
      reslist.Add(unitline);
    end;

    for i := 0 to dates.Count - 1 do begin

      success := true;
      pb.StepIt;
      time := StrToInt(dates[i]);

      for k := 0 to eingabe_namen.count - 1 do begin
        eingabe_count[k] := 0;
        eingabe_sum[k] := 0;
        (eingabe_werte[k] as TStringList).Clear;
      end;

      for k := 0 to csv_strlist.Count - 1 do begin

        success := true;

        list.DelimitedText := csv_strlist[k];
        time_act := StrToInt(list[date_col]);

        if (time_act <> time) then continue;
        if (time_act > time) then Break; // Liste ist sortiert!

        for l := 0 to listboxes_input.Count - 1 do begin

          actcaption := listboxes_input[l];
          actlistbox := listboxes_input.Objects[l] as TListBox;
          idx := captions.IndexOf(actcaption);

          if (idx < 0) then
            ShowMessage(actcaption + ' nicht gefunden');

          if ((trim(list[idx]) = '') or (trim(list[idx]) = '.')) then
            continue;

          // der Eintrag nicht ausgewählt ist
          if not actlistbox.Selected[actlistbox.Items.IndexOf(Trim(list[idx]))]
            then begin
            success := False;
            break;
          end;

          // falls die Checkbox aktiviert ist, aber die aktuelle ListBox-Zeile
          // nicht der der aktuellen Kombination ist, success := false
          if (checkboxes_input.Objects[l] as TCheckBox).checked
            and (combinations[zeile, idx] <>
            actlistbox.Items.IndexOf(trim(list[idx]))) then begin

            //showmessage( actcaption + ' ' + IntToStr(zeile) + ' ' + inttostr(idx) + ' ' + inttostr(combinations[zeile, idx]) + ' <> ' +
            //  IntToStr(actlistbox.Items.IndexOf(trim(list[idx]))) + ' ' +  list[idx] );

            success := False;
            break;
          end;
        end;

        if success then begin
          success := false;

          with cbbTimeSpaltenbreite do begin
            if Items[ItemIndex] <> '0' then begin
              line := Format('%' + Items[ItemIndex] + 'd', [time]) + '';
            end else begin
              line := IntToStr(time) + '   ';
            end;
          end;

          for j := 0 to eingabe_namen.Count - 1 do begin

            eingabe := list[captions.IndexOf(eingabe_namen[j])];

            val(eingabe, d, code);
            if (code = 0) and (d > 0) then success := True;

            if chk_mittelwerte.Checked then begin
              if (code = 0) and (d > 0) then begin
                eingabe_sum[j] := eingabe_sum[j] + d;
                eingabe_count[j] := eingabe_count[j] + 1;
                (eingabe_werte[j] as TStringList).Add(FloatToStr(d));
              end;
            end else begin
              with cbbSonstigeSpaltenbreite do begin
                if Items[ItemIndex] <> '0' then begin
                  line := line + Format('%' + Items[ItemIndex] + '.2n',
                    [StrToFloat(eingabe)]);
                end else begin
                  line := line + '   ' + eingabe;
                end;
              end;
            end;
          end;

          if not chk_mittelwerte.Checked and success then
            reslist.Add(line);
        end;
      end;

      if chk_mittelwerte.Checked then begin

        line := IntToStr(time) + '   ';
        success := false;

        for j := 0 to eingabe_namen.Count - 1 do begin

          if (eingabe_count[j] >= min) then begin
            line := line + floattostr(eingabe_sum[j] / eingabe_count[j]) +
              '   ';

            if chk_statistik.Checked then begin

              SetLength(doublearr, (eingabe_werte[j] as TStringList).Count);

              for m := 0 to length(doublearr) - 1 do begin
                doublearr[m] := StrToFloat((eingabe_werte[j] as
                  TStringList)[m]);
              end;

              QuickSort(doublearr);

              line := line + FloatToStr(length(doublearr)) + '   ';
              line := line + FloatToStr(doublearr[Low(doublearr)]) + '   ';
              line := line + FloatToStr(doublearr[High(doublearr)]) + '   ';

              n := length(doublearr);

              if odd(n) then
                median := doublearr[n div 2]
              else
                median := (doublearr[n div 2] + doublearr[(n div 2) + 1]) /
                2.0;

              if n = 2 then
                median := (doublearr[0] + doublearr[1]) / 2;

              line := line + FloatToStr(median) + '   ';
              line := line + FloatToStr(math.StdDev(doublearr)) + '   ';
              line := line + FloatToStr(math.StdDev(doublearr) / Sqrt(n)) +
                '   ';

            end;

            success := true;
          end else begin
            line := line + ' .  ';

            if chk_statistik.Checked then begin
              line := line + ' .  ';
              line := line + ' .  ';
              line := line + ' .  ';
              line := line + ' .  ';
              line := line + ' .  ';
              line := line + ' .  ';
            end;
          end;

        end;

        if success then
          reslist.Add(line);
      end;

    end;


    with cbbSonstigeSpaltenbreite do begin
                if Items[ItemIndex] <> '0' then begin
                  line := Format('   0' + '%' + Items[ItemIndex] + '.2n',
                    [0.0]);
                end;
                reslist.add(line);
    end;



    fn := edtSpeicherort.Text + '\';

    for i := 0 to editfield_input.Count - 1 do begin

      actlistbox := listboxes_input.Objects[i] as TListBox;
      actcheckbox := checkboxes_input.Objects[i] as TCheckBox;
      if actcheckbox.Checked then begin
        sel := (editfield_input.objects[i] as TEdit).Text +
          actlistbox.items[combinations[zeile, i]];
      end else begin
        if actlistbox.SelCount = 1 then
          sel := (editfield_input.objects[i] as TEdit).Text +
            actlistbox.Items[actlistbox.ItemIndex]
        else
          sel := (editfield_input.objects[i] as TEdit).Text; // + 'm';

        if trim((editfield_input.objects[i] as TEdit).Text) = '' then
          sel := '';
      end;
      fn := fn + sel;
    end;

    for i := 0 to reslist.Count - 1 do  begin
      reslist[i] := StringReplace(reslist[i], ThousandSeparator, '',[rfReplaceAll]);
    end;

    if ((reslist.Count > 2) and chkWithCaptions.checked)
      or ((reslist.Count > 0) and not chkWithCaptions.Checked) then
      reslist.SaveToFile(fn + '.' + edtDateiEndung.Text);

  end;
end;

procedure TForm1.oeffnen();
var
  i, size: Integer;
  filename: string;
begin
  listboxes_input := TStringList.Create;
  csv_strlist := TMyStringList.Create;

  captions := TStringList.Create;
  unitrow := TStringList.Create;

  filename := getFileName;

  if filename = '' then exit;

  csv_strlist.LoadFromFile(FileName);

  for i := 0 to csv_strlist.Count - 1 do begin
    csv_strlist[i] := StringReplace(csv_strlist[i], ' ', '_', [rfReplaceAll]);
  end;

  captions.Delimiter := ';';
  captions.StrictDelimiter := True;
  unitrow.Delimiter := ';';
  unitrow.StrictDelimiter := True;

  if (AnsiPos('[', csv_strlist[1]) = 0) then begin
    captions.DelimitedText := csv_strlist[1];
    unitrow.DelimitedText := csv_strlist[2];
  end else begin
    captions.DelimitedText := csv_strlist[2];
    unitrow.DelimitedText := csv_strlist[1];
  end;

  size := captions.Count;
  for i := size - 1 downto 0 do begin
    if Trim(captions[i]) = '' then
      captions.Delete(i)
    else
      break;

  end;
  firstline := TStringList.Create;
  firstline.Delimiter := ';';
  firstline.StrictDelimiter := True;
  firstline.DelimitedText := csv_strlist[0];

  date_col := firstline.IndexOf('Time');

  csv_strlist.Delete(0);
  csv_strlist.Delete(0);
  csv_strlist.Delete(0);

  csv_strlist.Sort;
  InitListBoxes;
end;

procedure TForm1.mniHilfe1Click(Sender: TObject);
begin
  MessageBox(0,
    'Aufbau der Eingabedatei (CSV-Datei)' + #13 + #10 + '' + #13 + #10 +
    '1. Zeile: ' + #13 + #10
    + '- "code" für Spalten, die im Code sind' + #13 + #10 +
    '- "time" für die Spalte in der die Zeit/Datum im Excel-Format steht' +
    #13 + #10 +
    '- "data" für Spalten, in denen die Messwerte stehen Spalten mit anderen Bezeichnungen werden ignoriert'
    + #13 + #10 +
    'Bitte diese Reihenfolge (code,...,code,time,data,...,data) genau so wählen, ansonsten' +
    'kann es zu Problemen kommen!'
    + #13 + #10 + #13 + #10 +
    '2. Zeile: Einheit der Kodierungs- und Messspalten in eckigen Klammern []' + #13
      + #10 +
    '3. Zeile: Namen der Kodierungs- und Messspalten ' + #13 + #10 +
    'ab 4. Zeile müssen die Daten in der CSV-Datei stehen. Wenn kein Wert vorliegt,  muss in der Zelle ein "." oder "" stehen, auf keinen Fall 0!'
    + #13 + #10 + '' + #13 + #10 + 'Beispiel' + #13 +
    #10
    + 'code;code;code;time;data;data;data;' + #13 + #10
    + '[];[];[];[];[g];[g];[g];[g]' + #13 + #10
    + 'Plot;N;Y;Date;Grass DM;Clover DM;NAA DM ;Fractionated DM' + #13 + #10
    + '12;0;1;40303;0.33;0;0;0.33' + #13 + #10
    + '12;0;1;40310;4.54;0;0.21;4.75' + #13 + #10
    + '12;0;1;40317;11.91;0;0.28;12.19' + #13 + #10
    + '12;0;1;40323;13.63;0.41;0.23;14.27' + #13 + #10 + #13 + #10
    + 'Bei "seperated" wird für jeden Eintrag in der entsprechenden Listbox eine eigene CSV-Ausgabedatei erstellt.'
    + #13 + #10 + '' + #13 + #10 +
    'Aufbau der Ausgabedateien (CSV-Dateien)' + #13 + #10 + '' + #13 +
    #10
    + '1. Zeile: Datum/Zeit und die ausgewählten Spaltenüberschriften der Messwerte' +
    #13 + #10 + 'ab 2. Zeile: ' + #13 +
    #10
    + '- in der erste Spalte das Datum gefolgt von den Mittelwertberechnung, falls die Checkbox Mittelwerte aktiviert wurde. Ansonsten alle Daten, die den ausgewähltem Code entsprechen ' +
    #13 + #10 +
    '- es kann angegeben werden, über wie viele Werte mindestens gemittelt worden sein muss, damit der Mittelwert in der Ausgabedatei steht.' + #13
    + #10 + '' + #13 + #10 +
    'Der Name der Ausgabedatei setzt sich aus den Strings in den Textfeldern zusammen. ' + #13
    + #10 +
    '- ist seperated aktiviert, folgt der Codewert, der in der jeweiligen Datei betrachtet wurde ' + #13
    + #10 + '- ist seperated deaktiviert, folgt nichts. ' + #13 + #10 +
    '- leere Textfelder werden komplett ignoriert. ', 'Hilfe', MB_ICONQUESTION
    or
    MB_OK);
end;

procedure TForm1.mniOeffnen1Click(Sender: TObject);
begin
  oeffnen();
end;

end.

