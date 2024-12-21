unit polation;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

type

  TMyFileName = TFileName;
  TForm1 = class(TForm)
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ButtonOpen: TButton;
    ProgressBar1: TProgressBar;
    EditOpen: TEdit;
    RadioGroup1: TRadioGroup;
    RBStandort1: TRadioButton;
    RBStandort2: TRadioButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ButtonSave: TButton;
    Label7: TLabel;
    Label8: TLabel;
    EditSave: TEdit;
    procedure ButtonOpenClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure foo(spalte: integer);
    procedure ButtonSaveClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    csv_file: TFileName;
    csv_save_file: TFileName;

    messtage: TStringList;

    start_cum_date, end_cum_date: Integer;

    csv_lines: TStringList;
    csv_lines2: TStringList;

    line, date: string;
    sl: TStringList;
    idx: Integer;
    slFile: TStringList;
    lines: TStringList;

    d, dl, dr: Double;

    l, m, r: TStringList;

    b1, b2, b3, b4, list, listl, listm, listr: TStringList;

    d1, d2, d3, d4: double;

    bloecke: set of 1..4;
    f: Textfile;
    count: Integer;

    helpl: TStringList;
    helplist: TStringList;

    procedure run;
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  IniFiles, Math;

procedure TForm1.foo(spalte: integer);
var
  CSV_Erntejahr,
    CSV_VN,
    CSV_Standort,
    CSV_Reihe,
    CSV_Spalte,
    CSV_Fruchtfolge,
    CSV_FF_Glied,
    CSV_N_Form,
    CSV_N_Menge,
    CSV_Block,
    CSV_Aufwuchs,
    CSV_Datum,
    CSV_Roh_Nges_N,
    CSV_Roh_NO3_N,
    CSV_NO3_N,
    CSV_Roh_NH4_N,
    CSV_NH4_N: Integer;

  i, j, k, tagid: Integer;

begin
  helpl := TStringList.Create();
  helplist := TStringList.Create();

  CSV_Erntejahr := 0;
  CSV_VN := 1;
  CSV_Standort := 2;
  CSV_Reihe := 3;
  CSV_Spalte := 4;
  CSV_Fruchtfolge := 5;
  CSV_FF_Glied := 6;
  CSV_N_Form := 7;
  CSV_N_Menge := 8;
  CSV_Block := 9;
  CSV_Aufwuchs := 10;
  CSV_Datum := 11;
  //CSV_Nges_N := 12;
  //CSV_NO3_N := 13;
  //CSV_NH4_N := 14;

  // horizontale Interpolation

  list.Delimiter := ';';

  b1 := TStringList.create;
  b1.Delimiter := ';';
  b2 := TStringList.create;
  b2.Delimiter := ';';
  b3 := TStringList.create;
  b3.Delimiter := ';';
  b4 := TStringList.create;
  b4.Delimiter := ';';
  list := TStringList.create;
  list.Delimiter := ';';
  listl := TStringList.create;
  listl.Delimiter := ';';
  listm := TStringList.create;
  listm.Delimiter := ';';
  listr := TStringList.create;
  listr.Delimiter := ';';

  // horizontale Interpolation
  Progressbar1.min := 0;
  Progressbar1.max := 3 * csv_lines.Count;
  ProgressBar1.Step := 1;

  ProgressBar1.StepIt;
  ProgressBar1.StepIt;
  for tagid := 1 to csv_lines.Count - 2 do begin
    ProgressBar1.StepIt;

    l := csv_lines.objects[tagid - 1] as TStringList;
    m := csv_lines.objects[tagid] as TStringList;
    r := csv_lines.objects[tagid + 1] as TStringList;

    // alle Einträge des Messtages behandeln

    for i := 0 to m.Count - 1 do begin

      listm.delimitedtext := m[i];

      //listm[CSV_Standort]

      if (listm[spalte] = '.') then begin

        dl := NaN;
        dr := NaN;

        for j := 0 to l.count - 1 do begin
          listl.delimitedtext := l[j];

          if (listl[CSV_Standort] = listm[CSV_Standort])
            and (listl[CSV_Fruchtfolge] = listm[CSV_Fruchtfolge])
            and (listl[CSV_FF_GLIED] = listm[CSV_FF_GLIED])
            and (listl[CSV_N_Form] = listm[CSV_N_FORM])
            and (listl[CSV_N_Menge] = listm[CSV_N_Menge])
            and (listl[CSV_BLOCK] = listm[CSV_BLOCK]) then begin
            if listl[spalte] <> '.' then begin
              dl := StrToFloat(listl[spalte]);
              Break;
            end;
          end;
        end;

        for j := 0 to r.count - 1 do begin
          listr.delimitedtext := r[j];

          if (listr[CSV_Standort] = listm[CSV_Standort])
            and (listr[CSV_Fruchtfolge] = listm[CSV_Fruchtfolge])
            and (listr[CSV_FF_GLIED] = listm[CSV_FF_GLIED])
            and (listr[CSV_N_Form] = listm[CSV_N_FORM])
            and (listr[CSV_N_Menge] = listm[CSV_N_Menge])
            and (listr[CSV_BLOCK] = listm[CSV_BLOCK]) then begin
            if listr[spalte] <> '.' then begin
              dr := StrToFloat(listr[spalte]);
              break;
            end;
          end;

        end;

        if not IsNan(dl) and not IsNan(dr) then begin
          listm[spalte] := FloatToStr((dl + dr) / 2.0);
          (csv_lines.objects[tagid] as TStringList)[i] := listm.delimitedtext;
          //showmessage( (csv_lines.objects[tagid] as TStringList)[i]);
          Inc(count);
        end;

      end;
    end;
  end;

  Label1.Caption := IntToStr(count);
  count := 0;

  // horizontale Extrapolation    EXTRAPOLATION!
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------

  ProgressBar1.StepIt;
  ProgressBar1.StepIt;

  helpl := TStringList.Create;

  for tagid := 0 to csv_lines.Count - 1 do begin
    ProgressBar1.StepIt;

    if tagid > 0 then
      l := csv_lines.Objects[tagid - 1] as TStringList
    else
      l := nil;

    m := csv_lines.Objects[tagid] as TStringList;

    if (tagid < csv_lines.Count - 1) then
      r := csv_lines.Objects[tagid + 1] as TStringList
    else
      r := nil;

    // alle Einträge des Messtages behandeln

    for i := 0 to m.Count - 1 do begin
      listm.delimitedtext := m[i];

      if (listm[spalte] = '.') then begin

        dl := NaN;
        dr := NaN;

        if l <> nil then
          for j := 0 to l.count - 1 do begin
            listl.delimitedtext := l[j];
            if (listl[CSV_Standort] = listm[CSV_Standort])
              and (listl[CSV_Fruchtfolge] = listm[CSV_Fruchtfolge])
              and (listl[CSV_FF_GLIED] = listm[CSV_FF_GLIED])
              and (listl[CSV_N_Form] = listm[CSV_N_FORM])
              and (listl[CSV_N_Menge] = listm[CSV_N_Menge])
              and (listl[CSV_BLOCK] = listm[CSV_BLOCK]) then begin

              if listl[spalte] <> '.' then begin
                dl := StrToFloat(listl[spalte]);
                listm[spalte] := FloatToStr(dl);
              //Fehler???
              //(csv_lines.objects[tagid] as TStringList)[i] := listm.delimitedtext;
                helplist := TStringList.Create;
                helplist.Add(Inttostr(i));
                helplist.Add(listm.delimitedtext);
                helpl.AddObject(IntToStr(tagid), helplist);

                inc(count);
              end;
            end;
          end;

        if (listm[spalte] = '.') then begin
          dl := NaN;
          dr := NaN;

          if r <> nil then
            for j := 0 to r.count - 1 do begin
              listr.delimitedtext := r[j];
              if (listr[CSV_Standort] = listm[CSV_Standort])
                and (listr[CSV_Fruchtfolge] = listm[CSV_Fruchtfolge])
                and (listr[CSV_FF_GLIED] = listm[CSV_FF_GLIED])
                and (listr[CSV_N_Form] = listm[CSV_N_FORM])
                and (listr[CSV_N_Menge] = listm[CSV_N_Menge])
                and (listr[CSV_BLOCK] = listm[CSV_BLOCK]) then begin

                if listr[spalte] <> '.' then begin
                  dr := StrToFloat(listr[spalte]);
                  listm[spalte] := FloatToStr(dr);
                // Fehler ???
                //(csv_lines.objects[tagid] as TStringList)[i] := listm.delimitedtext;

                  helplist := TStringList.Create;
                  helplist.Add(Inttostr(i));
                  helplist.Add(listm.delimitedtext);
                  helpl.AddObject(IntToStr(tagid), helplist);

                  Inc(count);

                end;
              end;
            end;
        end;

      end;
    end;

  end;

  for i := 0 to helpl.Count - 1 do begin
    helplist := TStringList.Create;
    helplist := helpl.objects[i] as TStringList;
    tagid := strtoint(helpl[i]);

    (csv_lines.objects[tagid] as TStringList)[StrToInt(helplist[0])] :=
      helplist[1];

  end;

  Label2.Caption := IntToStr(count);
  count := 0;

  //ShowMessage('vertikale');

  // vertikale Interpolation (Wert des Blocks = Mittelwert über anderen 3 Blöcke)

  for tagid := 0 to csv_lines.Count - 1 do begin
    ProgressBar1.StepIt;

    m := csv_lines.Objects[tagid] as TStringList;

    // alle Einträge des Messtages behandeln

    for i := 0 to m.Count - 1 do begin

      bloecke := [];

      b1.delimitedtext := m[i];

      bloecke := bloecke + [strtoint(b1[CSV_BLOCK])];

      d2 := NaN;
      d3 := NaN;
      d4 := NaN;

      if (b1[spalte] = '.') then begin

        for j := 0 to m.count - 1 do begin
          b2.delimitedtext := m[j];

          if not (strtoint(b2[CSV_BLOCK]) in bloecke) then begin

            if (b1[CSV_Standort] = b2[CSV_Standort])
              and (b1[CSV_Fruchtfolge] = b2[CSV_Fruchtfolge])
              and (b1[CSV_FF_GLIED] = b2[CSV_FF_GLIED])
              and (b1[CSV_N_Form] = b2[CSV_N_FORM])
              and (b1[CSV_N_Menge] = b2[CSV_N_Menge]) then begin

              if b2[spalte] <> '.' then begin
                d2 := StrToFloat(b2[spalte]);
                bloecke := bloecke + [strtoint(b2[CSV_BLOCK])];
                Break;
              end;
            end;
          end;
        end;

        for j := 0 to m.count - 1 do begin
          b3.delimitedtext := m[j];

          if not (strtoint(b3[CSV_BLOCK]) in bloecke) then begin

            if (b1[CSV_Standort] = b3[CSV_Standort])
              and (b1[CSV_Fruchtfolge] = b3[CSV_Fruchtfolge])
              and (b1[CSV_FF_GLIED] = b3[CSV_FF_GLIED])
              and (b1[CSV_N_Form] = b3[CSV_N_FORM])
              and (b1[CSV_N_Menge] = b3[CSV_N_Menge]) then begin
              if b3[spalte] <> '.' then begin
                d3 := StrToFloat(b3[spalte]);
                bloecke := bloecke + [strtoint(b3[CSV_BLOCK])];
                break;
              end;

            end;
          end;
        end;
      end;

      for j := 0 to m.count - 1 do begin
        b4.delimitedtext := m[j];

        if not (strtoint(b4[CSV_BLOCK]) in bloecke) then begin

          if (b1[CSV_Standort] = b4[CSV_Standort])
            and (b1[CSV_Fruchtfolge] = b4[CSV_Fruchtfolge])
            and (b1[CSV_FF_GLIED] = b4[CSV_FF_GLIED])
            and (b1[CSV_N_Form] = b4[CSV_N_FORM])
            and (b1[CSV_N_Menge] = b4[CSV_N_Menge]) then begin
            if b4[spalte] <> '.' then begin
              d4 := StrToFloat(b4[spalte]);
              bloecke := bloecke + [strtoint(b4[CSV_BLOCK])];
              break;
            end;
          end;
        end;
      end;

      if not IsNan(d2) and not IsNan(d3) and not IsNan(d4) then begin
        b1[spalte] := FloatToStr((d2 + d3 + d4) / 3.0);
        (csv_lines.objects[tagid] as TStringList)[i] := b1.delimitedtext;
        Inc(count);
      end;
    end;
  end;

end;

procedure TForm1.run;

var
  i, j, k, tagid: Integer;
  standort: String;

begin

  Label1.Caption := '0';
  Label2.Caption := '0';
  Label3.Caption := '0';

  count := 0;

  csv_lines := TStringList.create();

  if csv_file = '' then exit;

  slFile := TStringList.Create();
  slFile.loadfromfile(csv_file);

  list := TStringList.create();
  list.Delimiter := ';';

   if RBStandort1.Checked then
    standort := '1'
  else
    standort := '2';


  for i := 1 to slFile.Count - 1 do begin
    line := slFile[i];
    list.delimitedtext := line;
    idx := csv_lines.IndexOf(list[11]);

    if list[2] = standort then

      if (idx >= 0) then begin
        (csv_lines.Objects[idx] as TStringList).Add(line);
      end else begin
        sl := TStringList.Create;
        sl.Add(line);
        csv_lines.AddObject(list[11], sl);
      end;
  end;

  csv_lines.sort();

  foo(12);
  foo(13);
  foo(14);

  Label3.Caption := IntToStr(count);

  csv_save_file := EditSave.Text;


  if csv_save_file = '' then begin
  try
    if SaveDialog1.Execute then
      csv_save_file := SaveDialog1.Filename;
  except

  end;
  end;

  Progressbar1.Position := 0;
  Progressbar1.min := 0;
  Progressbar1.max := csv_lines.Count - 1;


  if csv_save_file <> '' then begin

    assignfile(f, csv_save_file);
    rewrite(f);

    writeln(f, slFile[0]);
    //writeln(f, slFile[1]);

    for tagid := 0 to csv_lines.Count - 1 do begin
      ProgressBar1.StepIt;

      m := csv_lines.Objects[tagid] as TStringList;

    // alle Einträge des Messtages behandeln

      for i := 0 to m.Count - 1 do begin

        writeln(f, m[i]);

      end;
    end;
    closefile(f);
  end;

  slFile.Free;

end;

procedure TForm1.ButtonOpenClick(Sender: TObject);
begin
  try
    if OpenDialog1.Execute then csv_file := OpenDialog1.FileName;
    EditOpen.Text := csv_file;
  except
    ShowMessage('Fehler beim Öffnen der Datei')
  end;
end;

procedure TForm1.ButtonSaveClick(Sender: TObject);
begin
  try
    if OpenDialog1.Execute then csv_file := OpenDialog1.FileName;
    EditSave.Text := csv_file;
  except
    ShowMessage('Fehler beim Öffnen der Datei')
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);

begin
  run;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Label1.Caption := '0';
  Label2.Caption := '0';
  Label3.Caption := '0';
end;

end.

