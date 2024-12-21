unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Math, ComCtrls, Spin, CheckLst, Mask, advspin;

type   PListRecord = ^AListRecord;
       AListRecord = record
       Key, Name, Typ: String;
       Comment: array[0..40] of String;
       Bedingung: array[0..40] of string;
       Action: array[0..40] of string;
       Acb, Formel, Initial, Default,
       Diff, Delay, MaxDelay,
       Tolerance, Period, Start: string;
       end;

       TForm1 = class(TForm)
       Panel1: TPanel;
       OpenDialog1: TOpenDialog;
       SaveDialog1: TSaveDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    StatusBar1: TStatusBar;
    TabSheet2: TTabSheet;
    MemoOut: TMemo;
    TabSheet3: TTabSheet;
    Panel2: TPanel;
    OpenButton: TButton;
    outNameEdit: TEdit;
    Label2: TLabel;
    SaveButton: TButton;
    TabSheet4: TTabSheet;
    MemoTemp: TMemo;
    TempFileEdit: TEdit;
    Label6: TLabel;
    Panel3: TPanel;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Bezeichner: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    VarBezEdit: TEdit;
    ParBezEdit: TEdit;
    CompBezEdit: TEdit;
    Memo4: TMemo;
    Panel4: TPanel;
    DecSepEdit: TEdit;
    Label7: TLabel;
    VarCountSpinEdit: TAdvSpinEdit;


procedure OpenButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure DecSepEditChange(Sender: TObject);

  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }

  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.OpenButtonClick(Sender: TObject);
var MMFile, TempFile, Resultfile: TextFile;
  LO, L, Vari, Vari2, Keyword, VariType, Diff: String;
  P, i, j, k, zz, VarCount, ValCount, CompCount, CompEvCount: Integer;
  firstValue: boolean;
  VRec: PListRecord;
  VList: TList;
begin

if OpenDialog1.Execute then begin
   Assignfile(MMFile, OpenDialog1.FileName);
   AssignFile(TempFile, TempFileEdit.Text);
   Rewrite(TempFile);
    Append(MMFile);
    Writeln(MMFile, '');
    Reset(MMFile);

   DecimalSeparator:= DecSepEdit.Text[1];


// Start Leseroutine

   while not eof(MMFile) do
   begin

   Readln(MMFile, LO);

   // Entfernen doppelter Leerzeichen

   while pos('  ', LO) > 0 do delete(LO,pos('  ', LO), 1);


   L:= Lowercase(LO);
   LO:= Lowercase(LO);


// Programmsegmente markieren, kann später entfallen

   if (LO = 'main') or (pos('sub', LO) = 1) then begin
                                  LO:= '//------------- ' + LO;
                                  writeln(TempFile, '');
                                  end;

          // Abtasten der Schlüsselwörter, ausser: action und period etc.

          if (Pos('variable:', LO) > 0) or
             (Pos('compartment:', LO) > 0) or
             (Pos('independent event:', LO) > 0) or
             (Pos('define value:', LO) > 0) or
             (Pos('component event:', LO) > 0) then

          begin

          L:= LO;

          if (Keyword = 'comp') and (Diff <> '') then writeln(TempFile, 'DIF: ' + Diff);

          Writeln(TempFile, ''); // Absatz schreiben

          Writeln(TempFile, '//O: ' + LO); // Schreiben der Originalzeile
          Delete(L, Pos(':', L), Length(L)); // Entfernen des Strings nach dem Schlüsselwort
          Keyword:= copy(L, 1, 4);           // Schlüsselwort extrahieren 4 digits
          if Pos(' ', L) > 0 then begin      // evtl. 2. Schlüsselwort extrahieren 3 digits
                                          // wenn Leerzeichen enthalten
                             delete(L, 1,Pos(' ', L));
                             Keyword:= Keyword + '_' + copy(L, 1, 3);
                             end;         // Summieren der 2 Schlüsselwörter mit _

          L:= LO;                             // Neuladen des Strings
          Delete(L, 1, Pos(': ', L) + 1);     // Entfernen des Schlüsselwortes
          Vari:= copy(L, 1, Pos(' ', L) - 1); // Variablennamen extrahieren

          if Keyword = 'dela' then Vari:= copy(L, 1, Length(L)); // bei delay Variablennamen extrahieren

          Delete(L, 1, Pos(' ', L));          // Entfernen des Namens im String

          VariType:= copy(L, 1, 3);        // Extrahieren des Types 3 digits
          if Pos(' ', L) > 0 then begin    // evtl. Extrahieren des 2. Types 3 digits
                                        // wenn Leerzeichen enthalten
                             delete(L, 1,Pos(' ', L));
                             VariType:= VariType + '_' + copy(L, 1, 3);
                             end;       // Summieren der 2 Typen mit _

          // VariKompl:= Keyword + '.' + VariType;  // Komplett-Typ summieren mit Punkt

          Writeln(TempFile, 'KEY: ' + Keyword);
          Writeln(TempFile, 'NAM: ' + Vari); // Auflisten
          if Keyword <> 'dela' then Writeln(TempFile, 'TYP: ' + VariType);

          Readln(MMFile, LO); // Weiterlesen im File
          LO:= Lowercase(LO);

          // Kommentar identifizieren und markieren: Kein =, Vari, dVari/, period, delay

          if (pos(Vari + ' =', LO) = 0)
          and (pos('d' + Vari + '/', LO) = 0)
          and (pos('period:', LO) = 0)
          and (pos('actions:', LO) = 0)
          and (pos('delay', LO) = 0)
          and (pos('initial value', LO) = 0)
          and (pos('(', LO) <> 1)
          then LO:= '///: ' + LO;

          end;



   // Folgezeilen nach Component Event herauslesen

   //if Keyword = 'comp_eve' then begin

   // end;

   // Lookup Table identifizieren

   if (Pos('lookup table: ', LO) > 0) then begin
      if (Keyword = 'comp') and (Diff <> '') then writeln(TempFile, 'DIF: ' + Diff);
      Writeln(TempFile, ''); // Absatz schreiben
      Writeln(TempFile, '//O: ' + LO);
      Keyword:= 'lupt';
      Vari:= copy(LO, 15, Length(LO) - 14);
      Writeln(TempFile, 'KEY: ' + Keyword);
      Writeln(TempFile, 'NAM: ' + Vari); // Auflisten
      Readln(MMFile, LO); // Weiterlesen im File
      LO:= Lowercase(LO);
      end;

// Alle Zeilen nach Lookup Table als Kommentar markieren

   if Keyword = 'lupt' then LO:= '///: ' + LO;

   // Delay identifizieren

   if (Pos('delay: ', LO) = 1) then begin
      if (Keyword = 'comp') and (Diff <> '') then writeln(TempFile, 'DIF: ' + Diff);
      Writeln(TempFile, ''); // Absatz schreiben
      Writeln(TempFile, '//O: ' + LO);
      Keyword:= 'dela';
      Vari:= copy(LO, 8, Length(LO) - 7);
      Writeln(TempFile, 'KEY: ' + Keyword);
      Writeln(TempFile, 'NAM: ' + Vari); // Auflisten
      Readln(MMFile, LO); // Weiterlesen im File
      LO:= Lowercase(LO);
      end;

   if Keyword = 'dela' then begin
      if (Pos('delay =', LO) = 1) then
      LO:= 'DLY: ' + copy(LO, 9, Length(LO) - 8);
      if (Pos('maximum delay', LO) = 1) then
      LO:= 'MXD: ' + copy(LO, 16, Length(LO) - 15);
      end;


   // Independent und Component Event Sonderregeln

   if (Keyword = 'comp_eve') or (Keyword = 'inde_eve') then begin
      if (pos('(', LO) = 1) then LO:= 'ACB: if ' + LO + ' then begin';
      if pos('//', LO) = 1 then begin
                                insert(': ', LO, 3);
                                LO:= '/' + LO;
                                end;
      if pos('tolerance =', LO) = 1 then LO:= 'TOL: ' + copy(LO, 13, Length(LO) - 12);
      if pos('period: ', LO) = 1 then begin
                                      LO:= 'PRD: ' + copy(LO, 9, Length(LO) - 8);
                                      Writeln(TempFile, LO);
                                      Readln(MMFile, LO); // Weiterlesen im File
                                         try LO:= 'SRT: ' + FloatToStr(StrToFloat(LO))
                                         except
                                         end;
                                      end;
      if pos('actions:', LO) = 1 then Readln(MMFile, LO); // Weiterlesen im File
      if (pos('///: ', LO) = 0) and
         (pos('TOL: ', LO) = 0) and
         (pos('PRD: ', LO) = 0) and
         (pos('SRT: ', LO) = 0) and                  
         (pos('ACB: ', LO) = 0) then LO:= 'ATN: ' + LO;
      end;

   // Unvollständige Zeile identifizieren (letztes Zeichen =) und folgende
   // Zeile lesen und anhängen

   if Pos('=', LO) = Length(LO) - 1  then begin
      Vari2:= copy(LO, 1, Pos(' ', LO) - 1);
      Readln(MMFile, L);
      L:= Lowercase(L);
      LO:= LO + L;
      end;

   // Voranstellen des Variablennamens + = Bei Default

   if (Pos('default', LO) > 0) then
           LO:= 'DFT: ' + copy(LO, 1, Pos('by default', LO)-2);

   // Voranstellen des Variablennamens + = Bei Initial Value

   if (Pos('initial value', LO) = 1) then
           LO:= 'INI: ' + copy(LO, 16, Length(LO) - 15);


   // Voranstellen des Variablennamens + = bei Bedingungen: for enthalten,
   // kein Kommentar(//) und nicht schon erfolgt

   if (pos('for', LO) > 0)
   and (pos('//', LO) = 0)
   and (pos(Vari + ' =', LO) = 0)
   and (pos('d' + Vari + '/', LO) = 0) then LO:= Vari2 + ' =' + LO;

   // Prophylaktisches Einschalten eines Leerzeichens vor und nach dem =

   if (Pos('=', LO) > 0) and (Pos('>=', LO) = 0) and (Pos('<=', LO) = 0) then begin
                            Insert(' ', LO, Pos('=', LO));
                            Insert(' ', LO, Pos('=', LO) + 1);
                            end;

   // Nochmaliges Entfernen doppelter Leerzeichen

   while pos('  ', LO) > 0 do delete(LO,pos('  ', LO), 1);

   // Einfügen des Doppelpunktes (Delphisyntax) vor das erste =

   if Pos(' =', LO) > 0 then Insert(':', LO, Pos('=', LO));

   // Erkennen einer Bedingung: := und for enthalten

   if (pos(':=', LO) > 0) and (pos(' for ',LO) > 0) then
      begin
      P:= pos(' for ',LO);
      L:= 'if ' + copy(LO, P + 5, length(LO) - P - 4) + ' then ' + copy(LO, 1, pos(' for ',LO)-1);
      LO:= 'BED: ' + L;              // Voranstellen der Bedingung (if then - Delphi)
      end;

   // Statische Variablenformel als letztes markieren

   if (pos(Vari, LO) = 1) or (pos(Vari, LO) = 2) and (pos(':=', LO) > 0) and (pos(' for ', LO) = 0) then
      LO:= 'FRM: ' + LO;

   // Differential identifizieren , Isolieren in Diff

   if (Keyword = 'comp') and  (pos('d'+Vari+'/d', LO) > 0) then begin
      L:= LO;
      Delete(L, 1, pos('d'+Vari+'/d', L) + Length(Vari) + 1);
      Diff:= copy(L, 1, pos(' ', L)-1);

      Delete(LO, pos('d'+Vari+'/d', LO), 1);
      Delete(LO, pos('/d', LO), 2 + Length(Diff));

      end;

   // Schreiben in den Tempfile

   Writeln(TempFile, LO);

   // Anhängen von ; im Tempfile (Delphi) wenn nicht schon erfolgt + Zeilenumbruch
   //if LO[Length(LO)] <> ';' then Writeln(TempFile, ';') else Writeln(TempFile, '');

   end;

   CloseFile(MMFile);
   CloseFile(Tempfile);          // Dateien schliessen

   // ################################################
   // ################################################

   Reset(TempFile);
   VList:= TList.Create;


   // Die Segmente aus dem Tempfile in eine Liste übertragen in die Variable VRec
   while not eof(TempFile) do
   begin
   i:= 0;
   j:= 0;
   k:= 0;
   new(VRec);
   Readln(TempFile, LO);
                    while (LO <> '') and not EOF(TempFile) do begin

                    if pos('KEY: ', LO) = 1 then Vrec^.Key:= copy(LO, 6, Length(LO) - 5);
                    if pos('NAM: ', LO) = 1 then Vrec^.Name:= copy(LO, 6, Length(LO) - 5);
                    if pos('TYP: ', LO) = 1 then Vrec^.Typ:= copy(LO, 6, Length(LO) - 5);
                    if pos('DFT: ', LO) = 1 then Vrec^.default:= copy(LO, 6, Length(LO) - 5);
                    if pos('INI: ', LO) = 1 then Vrec^.Initial:= copy(LO, 6, Length(LO) - 5);
                    if pos('DLY: ', LO) = 1 then Vrec^.Delay:= copy(LO, 6, Length(LO) - 5);
                    if pos('MXD: ', LO) = 1 then Vrec^.MaxDelay:= copy(LO, 6, Length(LO) - 5);
                    if pos('DIF: ', LO) = 1 then Vrec^.Diff:= copy(LO, 6, Length(LO) - 5);
                    if pos('FRM: ', LO) = 1 then Vrec^.Formel:= copy(LO, 6, Length(LO) - 5);
                    if pos('///: ', LO) = 1 then begin
                                                 Vrec^.Comment[i]:= copy(LO, 6, Length(LO) - 5);
                                                 INC(i);
                                                 end;
                    if pos('BED: ', LO) = 1 then begin
                                                 Vrec^.Bedingung[j]:= copy(LO, 6, Length(LO) - 5);
                                                 INC(j);
                                                 end;
                    if pos('ATN: ', LO) = 1 then begin
                                                 Vrec^.Action[k]:= copy(LO, 6, Length(LO) - 5);
                                                 INC(k);
                                                 end;
                    if pos('PRD: ', LO) = 1 then Vrec^.Period:= copy(LO, 6, Length(LO) - 5);
                    if pos('SRT: ', LO) = 1 then Vrec^.Start:= copy(LO, 6, Length(LO) - 5);
                    if pos('TOL: ', LO) = 1 then Vrec^.Tolerance:= copy(LO, 6, Length(LO) - 5);
                    if pos('ACB: ', LO) = 1 then Vrec^.Acb:= copy(LO, 6, Length(LO) - 5);
                    Readln(TempFile, LO);
                    end;
   VList.Add(VRec);
   end;
   CloseFile(TempFile);

   AssignFile(ResultFile, OutNameEdit.Text);
   Rewrite(Resultfile);

   // ################################################
   // Sequentielles Auslesen der Liste und Schreiben des Ausgabefiles.

   writeln(Resultfile, '');
   writeln(Resultfile, '// Variablen ********************');
   writeln(Resultfile, '');
   zz:= 0;
   ValCount:= 0;
   VarCount:= 0;
   CompCount:= 0;
   CompEvCount:= 0;
   firstValue:= false;
   write(Resultfile, 'Var: ');
   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'vari' then begin
                                       INC(VarCount);
                                       if zz = VarCountSpinEdit.Value then begin
                                       write(Resultfile, ', ');
                                       zz:= 0;
                                       firstValue:= false;
                                       writeln(Resultfile, '');
                                       write(Resultfile, '     ');
                                       end;

                                       if firstValue then write(Resultfile, ', ');
                                       write(Resultfile, Vrec^.name);
                                       inc(zz);
                                       firstValue:= true;
                                  end;
       end;

   if (VarCount > 0) and (VarBezEdit.Text <> '') then writeln(Resultfile, ': '
                                  + VarBezEdit.Text + ';');
   memo4.Lines.Append('Anzahl der Variablen: ' + IntToStr(VarCount));

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '');
   writeln(Resultfile, '// Defined values ********************');
   writeln(Resultfile, '');
   zz:= 0;
   firstValue:= false;
   write(Resultfile, '     ');
   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'defi_val' then begin
                                      INC(ValCount);
                                      if zz = VarCountSpinEdit.Value then begin
                                      write(Resultfile, ', ');
                                      zz:= 0;
                                      firstValue:= false;
                                      writeln(Resultfile, '');
                                      write(Resultfile, '     ');
                                      end;

                                      if firstValue then write(Resultfile, ', ');
                                      write(Resultfile, Vrec^.name);
                                      inc(zz);
                                      firstValue:= true;
                                  end;
        end;

   if (ValCount > 0) and (ParBezEdit.Text <> '') then writeln(Resultfile, ': '
                          + ParBezEdit.Text + ';');
   memo4.Lines.Append('Anzahl der defined values: ' + IntToStr(ValCount));

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '');
   writeln(Resultfile, '// Compartements ********************');
   writeln(Resultfile, '');
   zz:= 0;
   firstValue:= false;
   write(Resultfile, '     ');
   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'comp' then begin
                                       INC(CompCount);
                                       if zz = VarCountSpinEdit.Value then begin
                                       write(Resultfile, ', ');
                                       zz:= 0;
                                       firstValue:= false;
                                       writeln(Resultfile, '');
                                       write(Resultfile, '     ');
                                       end;

                                       if firstValue then write(Resultfile, ', ');
                                       write(Resultfile, Vrec^.name);
                                       inc(zz);
                                       firstValue:= true;
                                  end;
      end;

   if (CompCount > 0) and (CompBezEdit.Text <> '') then writeln(Resultfile, ': '
    + CompBezEdit.Text + ';');
   memo4.Lines.Append('Anzahl der compartements: ' + IntToStr(CompCount));

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '');
   writeln(Resultfile, '// Component Events ********************');
   writeln(Resultfile, '');
   zz:= 0;
   firstValue:= false;
   write(Resultfile, '     ');
   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'comp_eve' then begin
                                       INC(CompEvCount);
                                       if zz = VarCountSpinEdit.Value then begin
                                       write(Resultfile, ', ');
                                       zz:= 0;
                                       firstValue:= false;
                                       writeln(Resultfile, '');
                                       write(Resultfile, '     ');
                                       end;

                                       if firstValue then write(Resultfile, ', ');
                                       write(Resultfile, Vrec^.name);
                                       inc(zz);
                                       firstValue:= true;
                                  end;
      end;

   //if (CompCount > 0) and (CompBezEdit.Text <> '') then writeln(Resultfile, ': '
   // + CompBezEdit.Text + ';');
   memo4.Lines.Append('Anzahl der component events: ' + IntToStr(CompEvCount));

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '');
   writeln(Resultfile, '// Lookup Tables ********************');
   writeln(Resultfile, '');
   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'lupt' then writeln(Resultfile, '     ' + Vrec^.name);
   end;

   // ################################################
   // ################################################
   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '// Variablen Initiieren *************');
   writeln(Resultfile, '');
   writeln(Resultfile, 'procedure TSubmodel.createall;');
   writeln(Resultfile, 'begin');
   writeln(Resultfile, '   inherited createAll');

   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'vari' then
         writeln(Resultfile, '   VarCreate(' + Vrec^.name + ', '''', ' + VRec^.Default +', true, ' + Vrec^.name + ');');
       end;
   writeln(Resultfile, '');

   for i:= 0 to VList.Count - 1 do begin
       VRec:= VList.Items[i];
       if VRec^.Key = 'comp' then
         writeln(Resultfile, '   StateCreate(' + VRec^.Name + ', '''',' + VRec^.Initial + ', true, ' + Vrec^.name + ');');
       end;
   writeln(Resultfile, 'end;');

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '// Variablen Prozeduren *************');
   writeln(Resultfile, '');

   for i:= 0 to VList.Count - 1 do begin
       j:= 0;
       VRec:= VList.Items[i];
       if VRec^.Key = 'vari' then begin
              while Vrec^.Comment[j] <> '' do begin
                                              writeln(Resultfile, '// ' +  Vrec^.Comment[j]);
                                              INC(j);
                                              end;
                                              j:= 0;

              if Vrec^.Initial <> '' then
              writeln(Resultfile, Vrec^.Name + ' := ' + Vrec^.Initial + ';  // Initial Value');

              if Vrec^.default <> '' then
              writeln(Resultfile, Vrec^.Name + ' := ' + Vrec^.Default + ';  // by default');

              while Vrec^.Bedingung[j] <> '' do begin
                                              writeln(Resultfile, Vrec^.Bedingung[j] + ';');
                                              INC(j);
                                              end;
              if Vrec^.Formel <> '' then writeln(Resultfile, Vrec^.Formel + ';');

              writeln(Resultfile, '');
              end;
   end;

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '// Compartement Prozeduren **********');
   writeln(Resultfile, '');
   for i:= 0 to VList.Count - 1 do begin
       j:= 0;
       VRec:= VList.Items[i];
       if VRec^.Key = 'comp' then begin
              while Vrec^.Comment[j] <> '' do begin
                                              writeln(Resultfile, '// ' +  Vrec^.Comment[j]);
                                              INC(j);
                                              end;
                                              j:= 0;

              if Vrec^.Initial <> '' then
              writeln(Resultfile, Vrec^.Name + ' := ' + Vrec^.Initial + ';  // Initial Value');

              if Vrec^.default <> '' then
              writeln(Resultfile, Vrec^.Name + ' := ' + Vrec^.Default + ';  // by default');

              while Vrec^.Bedingung[j] <> '' do begin
                                              writeln(Resultfile, Vrec^.Bedingung[j] + ';');
                                              INC(j);
                                              end;
              if Vrec^.Formel <> '' then writeln(Resultfile, Vrec^.Formel + ';');

              writeln(Resultfile, '');
              end;
   end;

   // ################################################

   writeln(Resultfile, '');
   writeln(Resultfile, '// Events *************************');
   writeln(Resultfile, '');
   for i:= 0 to VList.Count - 1 do begin
       j:= 0;
       VRec:= VList.Items[i];
       if (VRec^.Key = 'inde_eve') or (VRec^.Key = 'comp_eve') then begin


             // if Vrec^.Initial <> '' then
             // writeln(Resultfile, Vrec^.Name + ' := ' + Vrec^.Initial + ';  // Initial Value');

             // if Vrec^.default <> '' then
             // writeln(Resultfile, Vrec^.Name + ' := ' + Vrec^.Default + ';  // by default');

              if (VRec^.Key = 'comp_eve') then
                 writeln(Resultfile, '// component event: ' + VRec^.Name + ' typ: ' + VRec^.typ)
                 else
                 writeln(Resultfile, '// independend event: ' + VRec^.Name + ' typ: ' + VRec^.typ);

              if VRec^.Tolerance <> '' then writeln(Resultfile, '// TOLERANCE:= ' +VRec^.Tolerance);
              if VRec^.Period <> '' then writeln(Resultfile, '// PERIOD:= ' +VRec^.Period);
              if VRec^.Start <> '' then writeln(Resultfile, '// START:= ' +VRec^.Start);

              if VRec^.Acb <> '' then writeln(Resultfile, VRec^.acb);

              while Vrec^.Action[j] <> '' do begin
                                              writeln(Resultfile, '   ' + Vrec^.Action[j]);
                                              INC(j);
                                              end;
                                              j:= 0;
              while Vrec^.Comment[j] <> '' do begin
                                              writeln(Resultfile, '   // ' +  Vrec^.Comment[j]);
                                              INC(j);
                                              end;
              writeln(Resultfile, 'end;');
              writeln(Resultfile, '');
              end;
   end;

   // ################################################


   writeln(Resultfile, '');
   writeln(Resultfile, '// Lookup Tables **********************');
   writeln(Resultfile, '');
   for i:= 0 to VList.Count - 1 do begin
       j:= 0;
       VRec:= VList.Items[i];
       if VRec^.Key = 'lupt' then begin
              if Vrec^.Name <> '' then writeln(Resultfile, '// LOOKUP TABLE: ' + Vrec^.name + ';');
              while Vrec^.Comment[j] <> '' do begin
                                              writeln(Resultfile, '// ' +  Vrec^.Comment[j]);
                                              INC(j);
                                              end;
              writeln(Resultfile, '');
              end;
   end;

   // ################################################


   writeln(Resultfile, '');
   writeln(Resultfile, '// Delays **********************');
   writeln(Resultfile, '');
   for i:= 0 to VList.Count - 1 do begin
       j:= 0;
       VRec:= VList.Items[i];
       if VRec^.Key = 'dela' then begin
              if Vrec^.Name <> '' then writeln(Resultfile, '// DELAY: ' + Vrec^.name + ';');
              while Vrec^.Comment[j] <> '' do begin
                                              writeln(Resultfile, '// ' +  Vrec^.Comment[j]);
                                              INC(j);
                                              end;
              if Vrec^.Delay <> '' then writeln(Resultfile, '   // Delay:= ' + Vrec^.delay + ';');
              if Vrec^.Initial <> '' then writeln(Resultfile, '   // Initial Value:= ' + Vrec^.initial + ';');
              if Vrec^.MaxDelay <> '' then writeln(Resultfile, '   // Maximum Delay:= ' + Vrec^.maxdelay + ';');
              writeln(Resultfile, '');
              end;
   end;



   CloseFile(Resultfile);          // Dateien schliessen
   VList.Free;
   end;


   Memo1.Lines.LoadFromFile(OpenDialog1.FileName);
   Memo3.Lines.LoadFromFile(TempfileEdit.Text);
   Memo2.Lines.LoadFromFile(OutNameEdit.Text);
   Savebutton.Enabled:= true;

end;

procedure TForm1.SaveButtonClick(Sender: TObject);
begin

if SaveDialog1.Execute then begin
memo2.Lines.SaveToFile(SaveDialog1.FileName);
end;

end;

procedure TForm1.DecSepEditChange(Sender: TObject);
begin
if (DecSepEdit.Text <> '.') and (DecSepEdit.Text <> ',') then DecSepEdit.Text:= '.'; 
end;

end.
