unit Wetterdaten_Analyse;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Math;

type
  TString = class(TObject)
  private
    fStr: string;
  public
    constructor Create(const AStr: string);
    property Str: string read FStr write FStr;
  end;

  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }

  public
    { Public-Deklarationen }

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

constructor TString.Create(const AStr: string);
begin
  inherited Create;
  FStr := AStr;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  f, f2: TextFile;
  fname, line, line2, excelDatum: string;
  wetterdatenListen, datenListe, list: TStringList;
  i, j: Integer;
  jahr, monat, tag, akt_tag, akt_monat, akt_jahr: Word;
  searchResult, searchResultDir: TSearchRec;

  tmp_mittel_liste, sum_list, help2, tsumlist, tmit_sum_list, tmp_sumfrom_liste,
    tmp_summen_liste, list1: TStringList;

  tstr: TString;

  datenListe2: TStringList;

  count: Integer;
  success: Boolean;
  sum, tmit_sum, d: Double;

  monateTemp: array[1..12] of TStringList;
  monateRR: array[1..12] of TStringList;

  monateTempRes: array[1..12] of Double;
  monateRRRes: array[1..12] of Double;

  idx, outputfile, dir, datumstr, str, fall: string;
  rr, tmit, tmax, tmin, glob, datumundort, help: TStringList;

  datenindex: Integer;

begin

 // dir := 'C:\Aufgaben\Antje\Wetterdaten Antje\Schleswig-Holstein\';
 dir := 'C:\Aufgaben\Antje\Wetterdaten Antje\Bayern\';

  wetterdatenListen := TStringList.Create;
  wetterdatenListen.Sorted := True;

  for i := 1 to 12 do begin
    monateTemp[i] := TStringList.Create();
    monateRR[i] := TStringList.Create();
  end;

  list := TStringList.create;

  if FindFirst(dir + '*',
    faDirectory,
    searchResultDir) = 0 then begin
    repeat
      if (AnsiPos('.', searchResultDir.Name) = 1) then continue;

      if FindFirst(dir + searchResultDir.Name + '\*', faAnyFile, searchResult) =
        0 then begin
        repeat

          if AnsiPos('.', searchResult.Name) = 1 then Continue;
          if AnsiPos('METD', uppercase(searchResult.Name)) <> 1 then Continue;

          fname := dir + searchResultDir.Name + '\' + searchResult.Name;

          //ShowMessage(ExtractFileExt(fname));

          if (ExtractFileExt(fname) = '.csv') then Continue;
          if (ExtractFileExt(searchResult.Name) = '.csv') then Continue;

          // ShowMessage(ExtractFileExt(fname));

          jahr := strtoint(Copy(searchResult.Name, 6, AnsiPos('.',
            searchResult.Name) - 6));
          if (copy(searchResult.Name, 6, 1) = '0') then
            jahr := 2000 + jahr
          else if (copy(searchResult.Name, 6, 1) <> '2') and
            (copy(searchResult.Name, 6, 1) <> '1') then
            jahr := 1900 + jahr;

          //showmessage(IntToStr(jahr) + ' ' + fname);

          //outputfile := 'C:\Users\ckluss\Desktop\met\' +
          //  ChangeFileExt(searchResult.Name, '.met');

          AssignFile(f, fname);
          ReSet(f);
          while not EOF(f) do begin
            ReadLn(f, line);
            datenListe := TStringList.Create;

            datenListe.add(Trim(copy(line, 1, 3))); // 0 JT

            if trim(datenListe[0]) = '' then break;
            if trim(datenListe[0]) = '-99' then break;
            if trim(datenListe[0]) = '#JT' then break;
            if trim(datenListe[0]) = '366' then break;

            datenListe.add(Trim(copy(line, 4, 6))); // 1 Temp

            datenListe.add(Trim(copy(line, 10, 6))); // 2 TMax
            datenListe.add(Trim(copy(line, 16, 6))); // 3 TMin

             datenListe.Add(FloatToStr(strtofloat(datenListe[2]) -
              strtofloat(datenListe[3]))); // 4 TMax-TMin

            // Sonderbehandlung für fehlende Strahlungsdaten
            if (Trim(copy(line, 41, 5)) = '-99') or
              (Trim(copy(line, 41, 5)) = '') or
              (Trim(copy(line, 41, 5)) = '-9') then begin

              if (searchResultDir.Name = 'Quickborn') or
                (searchResultDir.Name = 'Freising') then begin
                AssignFile(f2, dir + searchResultDir.Name + '\metd_'
                  + inttostr(jahr) + '.csv');
                ReSet(f2);
                ReadLn(f2, line2);

                success := false;

                datenliste2 := TStringList.Create();
                datenliste2.Delimiter := ';';
                while not EOF(f2) do begin
                  ReadLn(f2, line2);

                  datenliste2.DelimitedText := line2;
                  if Trim(copy(line, 1, 3)) = Trim(datenListe2[0]) then begin
                    datenListe.add(Trim(datenListe2[4])); // 5 GlobRad
                    success := True;
                    Break;
                  end;
                end;

                if not success then
                  ShowMessage(dir + searchResultDir.Name + '\metd_'
                    + inttostr(jahr) + '.csv' + '    ' + Trim(copy(line, 1,
                    3)));

                datenliste2.Free;
                CloseFile(f2);
              end else if (searchResultDir.Name = 'Kiel') then begin
                AssignFile(f2, dir + searchResultDir.Name + '\ki'
                  + inttostr(jahr) + '.met');
                ReSet(f2);
                success := false;
                while not EOF(f2) do begin
                  ReadLn(f2, line2);
                  if Trim(copy(line, 1, 3)) = Trim(copy(line2, 1, 3)) then begin
                    datenListe.add(Trim(copy(line2, 18, 5))); // 5 GlobRad
                    success := True;
                    Break;
                  end;
                end;

                if not success then
                  ShowMessage(dir + searchResultDir.Name + '\metd_'
                    + inttostr(jahr) + '.csv' + '    ' + Trim(copy(line, 1,
                    3)));
                CloseFile(f2);
              end;

            end else begin
              datenListe.add(Trim(copy(line, 41, 5))); // 5 GlobRad
            end;

            datenListe.add(Trim(copy(line, 46, 6))); // 6 Rain


          // datenListe.add(Trim(copy(line, 63, 5))); // 4 Haude ... ET0
          //  datenListe.add(Trim(copy(line, 62, 5))); // 4 Haude ... ET0

            {
            Write(f2, Format('%3d', [strtoint(datenListe[0])]));
            if datenListe[2] = '' then
              Write(f2, Format('%5.1n', [0.0]))
            else
              Write(f2, Format('%5.1n', [strtofloat(datenListe[2])]));
            Write(f2, Format('%5.1n', [strtofloat(datenListe[1])]));

            Write(f2, Format('%4.1n', [strtofloat(datenListe[4])]));
            Write(f2, Format('%5d', [strtoint(datenListe[3])]));
            Writeln(f2);
            }

            try
              excelDatum := FloatToStr(encodedate(jahr, 1, 1) - 1.0 +
                strtofloat(datenListe[0]));
            except
              showmessage(fname + ' ' + IntToStr(jahr) + ' ' + datenListe[0] +
                ' ' + datenListe[1]);
            end;

            wetterdatenListen.AddObject(excelDatum + '_' + searchResultDir.Name,
              datenListe);

          end;
          CloseFile(f);

        until FindNext(searchResult) <> 0;
        FindClose(searchResult);
      end;

    until FindNext(searchResultDir) <> 0;
    FindClose(searchResultDir);
  end;

  // B E G I N    D E S   S C H R E I B E N S

  AssignFile(f, 'C:\Users\ckluss\Desktop\aug_sep_bayern.csv');
  ReWrite(f);

  for datenindex := 1 to 6 do begin

    Writeln(f);
    case datenindex of
      1: WriteLn(f, 'Temp_mittel');
      2: Writeln(f, 'Temp_max');
      3: Writeln(f, 'Temp_min');
      4: Writeln(f, 'Temp_max-min');
      5: Writeln(f, 'Globalstrahlung');
      6: Writeln(f, 'Niederschlag');

    end;

    datumundort := TStringList.Create;
    datumundort.Delimiter := '_';
    tmit := TStringList.Create;

    //for akt_monat := 8 to 9 do begin

    for i := 0 to wetterdatenListen.count - 1 do begin
      datenListe := wetterdatenListen.objects[i] as TStringList;

      datumundort.DelimitedText := wetterdatenListen[i];

      DecodeDate(strtoint(datumundort[0]), jahr, monat, tag);

      if (monat = 8) or (monat = 9) then begin
        idx := datumundort[0];

        //datumstr := datenliste[1]; // tmit
        datumstr := datenliste[datenindex];

        if datenindex = 6 then
          fall := 'rain'
        else fall := '';

        if (datumstr = '') and (fall = 'rain') then
          datumstr := '0';

        if tmit.IndexOf(idx) <> -1 then begin
          (tmit.Objects[tmit.IndexOf(idx)] as TStringList).Add(datumstr);
        end else begin
          help := TStringList.Create;
          help.Add(datumstr);
          tmit.AddObject(idx, help);
        end;
      end;
    end;

    //end;

    tmit.Sort;

    sum_list := TStringList.Create;
    help := TStringList.create();

  // Mittelwerte über gleiche Tage bilden

    for i := 0 to tmit.Count - 1 do begin
      DecodeDate(strtoint(tmit[i]), jahr, monat, tag);
      help := tmit.Objects[i] as TStringList;
      sum := 0;
      for j := 0 to help.Count - 1 do begin
        sum := sum + StrToFloat(help[j]);
      end;

      help2 := TStringList.Create;
      help2.Add(floattostr(sum / help.Count));
      sum_list.AddObject(tmit[i], help2);
    end;

  // Ausgabe Tabelle, Tage vertikal, Jahre horizontal

    Write(f, 'Datum');
    for akt_jahr := 1986 to 2010 do begin
      Write(f, ';' + IntToStr(akt_jahr))
    end;
    Writeln(f);

    for akt_monat := 8 to 9 do begin
      for akt_tag := 1 to 31 do begin
        for akt_jahr := 1986 to 2010 do begin
          for i := 0 to sum_list.Count - 1 do begin
            DecodeDate(strtoint(sum_list[i]), jahr, monat, tag);
            if (monat = akt_monat) and (tag = akt_tag) and (jahr = akt_jahr) then
              begin

              if (fall = 'rain') and not ((tag = 1) and (monat = 8)) then begin
                help2 := sum_list.Objects[i - 1] as TStringList;
                help := sum_list.Objects[i] as TStringList;
                help[0] := floattostr(strtofloat(help[0]) +
                  strtofloat(help2[0]));
              end;

              help := sum_list.Objects[i] as TStringList;

              if jahr = 1986 then
                if monat = 8 then
                  Write(f, IntToStr(tag) + '. Aug.;' + help[0])
                else
                  Write(f, IntToStr(tag) + '. Sep.;' + help[0])
              else
                Write(f, ';' + help[0]);
            end;

          end;

        end;
        WriteLn(f);
      end;
    end;

  end;

  CloseFile(f);

  AssignFile(f, 'C:\Users\ckluss\Desktop\may_sep_jahre_bayern.csv');
  ReWrite(f);

  for datenindex := 1 to 6 do begin

    Writeln(f);
    case datenindex of
      1: WriteLn(f, 'Temp_mittel');
      2: Writeln(f, 'Temp_max');
      3: Writeln(f, 'Temp_min');
      4: Writeln(f, 'Temp_max-min');
      5: Writeln(f, 'Globalstrahlung');
      6: Writeln(f, 'Niederschlag');
    end;

    datumundort := TStringList.Create;
    datumundort.Delimiter := '_';
    tmit := TStringList.Create;

    //for akt_monat := 5 to 9 do begin

    for i := 0 to wetterdatenListen.count - 1 do begin
      datenListe := wetterdatenListen.objects[i] as TStringList;

      datumundort.DelimitedText := wetterdatenListen[i];

      DecodeDate(strtoint(datumundort[0]), jahr, monat, tag);

      if (monat >= 5) and (monat <= 9) then begin

        idx := inttostr(jahr) + '_' + datumundort[1];


        datumstr := datenliste[datenindex];

        if datenindex = 6 then
          fall := 'rain'
        else fall := '';

        if (datumstr = '') and (fall = 'rain') then
          datumstr := '0';

        if tmit.IndexOf(idx) <> -1 then begin
          (tmit.Objects[tmit.IndexOf(idx)] as TStringList).Add(datumstr);
        end else begin
          help := TStringList.Create;
          help.Add(datumstr);
          tmit.AddObject(idx, help);
        end;
      end;
    end;
   // end;

    tmit.Sort;

    sum_list := TStringList.Create;
    help := TStringList.create();

  // Mittelwerte über gleiche Tage bilden

    for i := 0 to tmit.Count - 1 do begin
      help := tmit.Objects[i] as TStringList;
      sum := 0;
      for j := 0 to help.Count - 1 do begin
        sum := sum + StrToFloat(help[j]);
      end;

      help2 := TStringList.Create;
      if (fall <> 'rain') then
        help2.Add(floattostr(sum / help.Count))
      else
        help2.Add(floattostr(sum));

    //ShowMessage(FloatToStr(sum) + ' ' + IntToStr(help.count));
      sum_list.AddObject(tmit[i], help2);
    end;

  // Ausgabe Tabelle, Jahre vertikal, Orte horizontal

    str := '';
    write(f, 'Jahr');

    for i := 0 to sum_list.Count - 1 do begin
      datumundort.DelimitedText := sum_list[i];
      if ('1986' = datumundort[0]) then begin
        str := datumundort[1];
        if str <> '' then
          write(f, ';' + str);
      end;
    end;

    writeln(f);
    datumundort.DelimitedText := sum_list[0];
    str := datumundort[1];

    for akt_jahr := 1986 to 2010 do begin
      for i := 0 to sum_list.Count - 1 do begin
        datumundort.DelimitedText := sum_list[i];

        jahr := strtoint(datumundort[0]);

        if (jahr = akt_jahr) then begin

          help := sum_list.Objects[i] as TStringList;

          if datumundort[1] = str then
            Write(f, IntToStr(jahr) + ';' + help[0])
          else
            Write(f, ';' + help[0])

        end;

      end;
      WriteLn(f);
    end;
  end;

  CloseFile(f);

//
//
//  AssignFile(f, 'C:\Users\ckluss\Desktop\wetter_30jahre_mean.csv');
//  ReWrite(f);
//  Writeln(f, 'monat;temp;rr');

//  for i := 1 to 12 do begin
//
//    sum := 0; count := 0;
//    for j := 0 to monateTemp[i].Count - 1 do begin
//      count := count + 1;
//      sum := sum  +  StrToFloat(monateTemp[i][j]);
//    end;
//
//    monateTempRes[i] := sum / count;
//
//    sum := 0; count := 0;
//    for j := 0 to monateRR[i].Count - 1 do begin
//      count := count + 1;
//      sum := sum  +  StrToFloat(monateRR[i][j]);
//    end;
//
//    monateRRRes[i] := sum / 33;
//
//    Writeln(f, IntToStr(i) + ';' + FloatToStr(monateTempRes[i]) + ';' + FloatToStr(monateRRRes[i]));
//  end;

  // CloseFile(f);

  {

  tmit_sum_list := TStringList.Create();

  success := False;

  for i := 0 to wetterdatenListen.count do begin

    if i <> wetterdatenListen.count then begin
      datenListe := wetterdatenListen.objects[i] as TStringList;
      DecodeDate(strtoint(wetterdatenListen[i]), jahr, monat, tag);
    end;

    akt_tag := StrToInt(FloatToStr(EncodeDate(jahr, monat, tag) -
      EncodeDate(jahr, 1, 1) + 1));

    if ((jahr <> akt_jahr) and (monat > 5))or (i = wetterdatenListen.count) then begin
      tmp_summen_liste.addObject(inttostr(akt_jahr), tmit_sum_list);

      tmit_sum := 0;
      akt_jahr := jahr;

      if i = wetterdatenListen.count then Break;

      tmit_sum_list := TStringList.Create();
      success := False;
    end;

    if (jahr <> akt_jahr) and ((monat = 4) and (tag = 15)) then
    //if akt_tag =  320  then    // (319 = 16 Nov)
      success := False;

    //if (akt_tag = 227)
    if ((monat = 8) and (tag = 15))
      or success then begin
      success := True;
      if (StrToFloat(datenListe[1])  >= 0) then begin
        tmit_sum := tmit_sum + strtofloat(datenListe[1]) - 0 ;
        //tmp_sumfrom_liste
      end;

      tmit_sum_list.AddObject(inttostr(akt_tag),
        tstring.Create(floattostr(tmit_sum)));
    end;

  end;

  tmp_sumfrom_liste := TStringList.create();

  for j := 0 to tmp_summen_liste.Count - 1 do begin
    list := tmp_summen_liste.objects[j] as TStringList;
    sum := strtofloat((list.Objects[list.Count - 1] as TString).Str);
    list1 := TStringList.Create();
    for i := 0 to list.count - 1 do begin
      d := strtofloat((list.Objects[i] as TString).Str);
      list1.AddObject(list[i], TString.Create(FloatToStr(sum - d)));
    end;
    tmp_sumfrom_liste.AddObject(tmp_summen_liste[j], list1);
  end;

  AssignFile(f, 'wetter.csv');
  ReWrite(f);

  count := 0;

  //Writeln(f, 'day;date;tmpsum_base_0;tmpsum_base_5');

  list := tmp_sumfrom_liste.objects[1] as TStringList;

  for i := 0 to list.Count - 1 do begin
    excelDatum := FloatToStr(encodedate(1999, 1, 1) - 1.0 + StrToFloat(list[i]));
    DecodeDate(strtoint(excelDatum), jahr, monat, tag);
    if (i mod 7 = 0) then begin
        write(f, ';' + inttostr(tag) + '.' + inttostr(monat) + '.');
    end;
  end;

  writeln(f);

  for j := 0 to tmp_sumfrom_liste.Count - 1 do begin
    list := tmp_sumfrom_liste.objects[j] as TStringList;
    Write(f,tmp_sumfrom_liste[j]);
    for i := 0 to list.count - 1 do begin
      if (i mod 7 = 0) then begin
        tstr := list.objects[i] as TString;
        Write(f, ';' + tstr.Str);
      end;
    end;
    writeln(f);
  end;

  }

//
//  for j := 0 to tmp_sumfrom_liste.Count - 1 do begin
//    list := tmp_sumfrom_liste.objects[j] as TStringList;
//    count := 0;
//    for i := 0 to list.count - 1 do begin
//      if (count mod 7 = 0) then begin
//
//        excelDatum := FloatToStr(encodedate(StrToInt(tmp_sumfrom_liste[j]), 1, 1) - 1.0 +
//          StrToFloat(list[i]));
//        tstr := list.objects[i] as TString;
//
//        write(f, list[i]);
//        write(f, ';' + exceldatum);
//        Write(f, ';' + tstr.Str);
//
//        writeln(f);
//      end;
//      Inc(count);
//    end;
// end;

//  CloseFile(f);

  ShowMessage('fertig');
end;

end.

