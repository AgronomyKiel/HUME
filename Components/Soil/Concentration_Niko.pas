unit Concentration_Niko;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod, UState, UlayeredSoil, IniFiles, UModUtils, Math;


type
  TBloecke = array[0..4] of TPar;
  TN_Mengen = array[0..4] of TPar;
  TN_Formen = array[0..5] of TPar;
  TAufwuechse = array[0..4] of TPar;
  TFruchtfolge = array[0..4] of TPar;

  TConcentration = class(TSubmodel)

  private
    { Private declarations }
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
      CSV_Nges_N,
      CSV_NO3_N,
      CSV_NH4_N: Integer;

  protected
    { Protected declarations }
  public
    vn: TPar;
    standort: TPar;
    fruchtfolgen: TFruchtfolge;

    n_formen: TN_Formen;
    n_mengen: TN_Mengen;
    bloecke: TBloecke;
    aufwuechse: TAufwuechse;
    schicht: TPar;

    min_fuer_mittelwert: TPar;

    messtage: TStringList;

    Wflow_arr: TSoilExtArray; // Flussvektor [cm/d]

    fracht_Nges_N, // fracht = N-Konzentration * Wflow
      fracht_NO3_N, fracht_NH4_N: TVar;

    fracht_Nges_N_cum, // fracht = N-Konzentration * Wflow
      fracht_NO3_N_cum, fracht_NH4_N_cum: TState;

    start_cum_date, end_cum_date: TPar;

    Nges_N: TVar;
    NO3_N: TVar;
    NH4_N: TVar;
    Nges_N_fc: TVar;
    NO3_N_fc: TVar;
    NH4_N_fc: TVar;

    flow_leq_null_count: TVar;
    flow_leq_null_with_values: TVar;

    flow_ge_null_count: TVar;

    messdatum: TVar;

    //csv_file: TMyFileName;
    csv_lines: TStringList;
    n_comp: Integer;

    n_dates: TStringList;

    csv_file: TOption;

    Nkonz:  TSoilExtArray ;      // Nitratkonzentration [Kg NO3-N/cm H2O]
    NConc:  TSoilVarArray  ;
    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;

    { Public declarations }
  published
    //property CSV_File_Name: TMyFileName read csv_file write csv_file;
    { Published declarations }
  end;

procedure Register;

implementation

var fn:String;

procedure TConcentration.createAll;
var
  i: Integer;
  ndx_str: string;
begin
  OptCreate('concentration_input_file', '', csv_file);

  n_comp := 20;

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
  CSV_Nges_N := 12;
  CSV_NO3_N := 13;
  CSV_NH4_N := 14;

  ParCreate('Start Cum Date', '[d]', 0, start_cum_date);
  ParCreate('End Cum Date', '[d]', 100000, end_cum_date);

  ParCreate('VN', '[-]', 112, vn);
  ParCreate('Standort', '[-]', 2, standort);
  ParCreate('Fruchtfolge1', '[-]', 1, fruchtfolgen[1]);
  ParCreate('Fruchtfolge2', '[-]', 1, fruchtfolgen[2]);
  ParCreate('Fruchtfolge3', '[-]', 1, fruchtfolgen[3]);
  ParCreate('Fruchtfolge4', '[-]', 1, fruchtfolgen[4]);

  ParCreate('N-Form1', '[-]', 1, n_formen[1]);
  ParCreate('N-Form2', '[-]', 1, n_formen[2]);
  ParCreate('N-Form3', '[-]', 1, n_formen[3]);
  ParCreate('N-Form4', '[-]', 1, n_formen[4]);
  ParCreate('N-Form5', '[-]', 1, n_formen[5]);

  ParCreate('N-Menge1', '[-]', 1, n_mengen[1]);
  ParCreate('N-Menge2', '[-]', 1, n_mengen[2]);
  ParCreate('N-Menge3', '[-]', 1, n_mengen[3]);
  ParCreate('N-Menge4', '[-]', 1, n_mengen[4]);

  ParCreate('Block1', '[-]', 1, bloecke[1]);
  ParCreate('Block2', '[-]', 1, bloecke[2]);
  ParCreate('Block3', '[-]', 1, bloecke[3]);
  ParCreate('Block4', '[-]', 1, bloecke[4]);

  ParCreate('Aufwuchs1', '[-]', 1, aufwuechse[1]);
  ParCreate('Aufwuchs2', '[-]', 1, aufwuechse[2]);
  ParCreate('Aufwuchs3', '[-]', 1, aufwuechse[3]);
  ParCreate('Aufwuchs4', '[-]', 1, aufwuechse[4]);

  ParCreate('Schicht', '[]', 7, schicht);

  VarCreate('Nges-N', '[mg N/l]', 0.0, true, Nges_N);
  VarCreate('NO3-N', '[mg N/l]', 0.0, true, NO3_N);
  VarCreate('NH4-N', '[mg N/l]', 0.0, true, NH4_N);

  VarCreate('Nges-N_CF', '[]', 0, true, Nges_N_fc);
  VarCreate('NO3-N_CF', '[]', 0, true, NO3_N_fc);
  VarCreate('NH4-N_CF', '[]', 0, true, NH4_N_fc);

  VarCreate('Fracht Nges-N', '[kg/ha]', 0.0, true, fracht_Nges_N);
  VarCreate('Fracht N03-N', '[kg/ha]', 0.0, true, fracht_NO3_N);
  fracht_NO3_N.PlotTograpH := True;
  VarCreate('Fracht NH4-N', '[kg/ha]', 0.0, true, fracht_NH4_N);

  StateCreate('Fracht Nges-N Cum', '[kg/ha]', 0.0, true, fracht_Nges_N_cum);
  StateCreate('Fracht N03-N  Cum', '[kg/ha]', 0.0, true, fracht_NO3_N_cum);
  StateCreate('Fracht NH4-N  Cum', '[kg/ha]', 0.0, true, fracht_NH4_N_cum);

  VarCreate('flow_leq_null_count', '[]', 0, true, flow_leq_null_count);
  VarCreate('flow_leq_null_with_values', '[]', 0, true, flow_leq_null_with_values);
  VarCreate('flow_ge_null_count', '[]', 0, true,  flow_ge_null_count);




  VarCreate('Messdatum', '[d]', 0, true, messdatum);

  for i := 1 to n_comp + 1 do begin
    if i <= 9 then
      ndx_str := '_' + IntTostr(i)
    else
      ndx_str := IntTostr(i);

    VarCreate('NConc' + ndx_str, '[mg N/l]', 0, true,  NConc[i]);
    ExternVcreate('WFlow' + ndx_str, '[cm.d-1]', statefield, Wflow_arr[i]);
    ExternVcreate('NKonz_' + IntTostr(i), '[kg NO3/cm H20]', statefield, NKonz[i]);
  end;

  ParCreate('Min für Mittelwert', '[-]', 0, min_fuer_mittelwert);

end;

procedure TConcentration.init(var GlobMod: TMod);
var // f: TextFile;
  line,
    date: string;
  list: TStringList;
  sl: TStringList;
  idx, i: Integer;
  slFile: TStringList;

  // falls der Eintrag des Array arr der Stelle str eine 1 ist
  // gebe true zurück, sonst false
  // könnte problematisch sein, da double mit int verglichen wert
  // es werden jedoch keine Berechnungen ausgeführt, sondern
  // nur auf Gleichheit geprüft.

  function is_in_params(arr: array of TPar; str: string): Boolean;
  var
    idx: Integer;
  begin
    idx := StrToInt(str);

    if ((idx < 0) or (idx > 10)) then begin
      showmessage(IntToStr(idx));
      result := false;
    end else
      result := (arr[idx].v = 1);
  end;
begin
  inherited init(GlobMod);

  //fn := extractFiledir(Application.exename) + '\' + 'concentration.stat';

  csv_lines := TStringList.create();
  csv_lines.Sorted := True;

  slFile := TStringList.Create();

  try
    slFile.loadfromfile(csv_file.Option);
  except
    ShowMessage(csv_file.Option + ' kann nicht geladen werden!');
  end;

  list := TStringList.create();
  list.Delimiter := ';';

  //while not eof(f) do begin
  for i := 2 to slFile.Count - 1 do begin
    //readln(f, line);
    line := slFile[i];
    list.delimitedtext := line;

     //ShowMessage(line);

    if ((list[CSV_Nges_N] <> '.')
      or (list[CSV_NO3_N] <> '.')
      or (list[CSV_NH4_N] <> '.')) then begin

      idx := csv_lines.IndexOf(list[CSV_Datum]);

      if (True
        and (vn.v = StrToInt(list[CSV_VN]))
        and (standort.v = StrToInt(list[CSV_Standort]))
        and is_in_params(fruchtfolgen, list[CSV_Fruchtfolge])
        and is_in_params(n_formen, list[CSV_N_Form])
        and is_in_params(n_mengen, list[CSV_N_Menge])
        and is_in_params(bloecke, list[CSV_Block])
        and is_in_params(aufwuechse, list[CSV_Aufwuchs])) then begin

        if (idx >= 0) then begin
          (csv_lines.Objects[idx] as TStringList).Add(line);
        end else begin
          sl := TStringList.Create;
          sl.Add(line);
          csv_lines.AddObject(list[CSV_Datum], sl);
        end;
      end;
    end else
      //list.Free;
  end;

  list.free;
  slFile.Free;
  //closefile(f);

  messtage := TStringList.Create;
  messtage.Sorted := True;

  for i := 0 to csv_lines.Count - 1 do begin
    date := csv_lines.strings[i];
    messtage.Add(date);
  end;

  messtage.Add('0');

  fracht_Nges_N_cum.v := 0;
  fracht_NO3_N_cum.v := 0;
  fracht_NH4_N_cum.v := 0;

end;

procedure TConcentration.CalcRates;
var
  list: TStringList;
  lines: TStringList;
  //strlist, strlist_act: TStringList;
  i, idx: Integer;

  mdate1, mdate2,
    concentration_date: Integer;

  d: double;
  count_Nges_N,
    count_NO3_N,
    count_NH4_N,
    code, n: Integer;

begin
   for i := 1 to n_comp + 1 do begin
     NConc[i].v :=  NKonz[i].v * 10;
   end;


  count_Nges_N := 0;
  Nges_N.v := 0;
  count_NO3_N := 0;
  NO3_N.v := 0;
  count_NH4_N := 0;
  NH4_N.v := 0;

  fracht_Nges_N.v := 0;
  fracht_NO3_N.v := 0;
  fracht_NH4_N.v := 0;

  fracht_Nges_N_cum.c := 0;
  fracht_NO3_N_cum.c := 0;
  fracht_NH4_N_cum.c := 0;

  messdatum.v := 0;

  concentration_date := 0;

  list := TStringList.create();
  list.Delimiter := ';';

  for i := 1 to messtage.Count - 1 do begin
    mdate1 := StrToInt(messtage[i - 1]);
    mdate2 := StrToInt(messtage[i]);

    if ((mdate1 < GlobTime.v)
      and (mdate2 - 9 <= GlobTime.v)
      and (GlobTime.v <= mdate2)) then begin
      concentration_date := mdate2;
      break;
    end;

  end;

  lines := TStringList.Create;
  if (concentration_date > 0) then begin
    idx := csv_lines.IndexOf(IntToStr(concentration_date));
    lines := csv_lines.objects[idx] as TStringList;
  end;

  for i := 0 to lines.Count - 1 do begin

    list.DelimitedText := lines[i];

    val(list[CSV_Nges_N], d, code);
    if (code = 0) and (d > 0) then begin
      Nges_N.v := Nges_N.v + d;
      Inc(count_Nges_N);
    end;

    val(list[CSV_NO3_N], d, code);
    if (code = 0) and (d > 0) then begin
      NO3_N.v := NO3_N.v + d;
      Inc(count_NO3_N);
    end;

    val(list[CSV_NH4_N], d, code);
    if (code = 0) and (d > 0) then begin
      NH4_N.v := NH4_N.v + d;
      Inc(count_NH4_N);
    end;

  end;

  list.free;
  n := round(schicht.v);

  Nges_N_fc.v := 0;
  NO3_N_fc.v := 0;
  NH4_N_fc.v := 0;

  if (count_Nges_N > 0) and (count_Nges_N >= min_fuer_mittelwert.v) then begin
    Nges_N.v := Nges_N.v / count_Nges_N;
    if (Wflow_arr[n].v > 0) then Nges_N_fc.v := 1
  end else
    Nges_N.v := 0;

  if (count_NO3_N > 0) and (count_NO3_N >= min_fuer_mittelwert.v) then begin
    NO3_N.v := NO3_N.v / count_NO3_N;
    if (Wflow_arr[n].v > 0) then NO3_N_fc.v := 1
  end else
    NO3_N.v := 0;

  if (count_NH4_N > 0) and (count_NH4_N >= min_fuer_mittelwert.v) then begin
    NH4_N.v := NH4_N.v / count_NH4_N;
    if (Wflow_arr[n].v > 0) then NH4_N_fc.v := 1
  end else
    NH4_N.v := 0;

  if (Wflow_arr[n].v <= 0) then begin

    if (Nges_N.v <> 0) or (NO3_N.v <> 0) or (NH4_N.v  <> 0) then begin
      flow_leq_null_with_values.v := flow_leq_null_with_values.v + 1;
      flow_leq_null_count.v := flow_leq_null_count.v + 1;
    end else begin
      flow_leq_null_count.v := flow_leq_null_count.v + 1;
    end;

    Nges_N_fc.v := 1;
    NO3_N_fc.v := 1;
    NH4_N_fc.v := 1;
  end else begin
    flow_ge_null_count.v  := flow_ge_null_count.v + 1;
  end;

  //end;

  if (Wflow_arr[n].v >= 0) then begin
    fracht_Nges_N.v := Wflow_arr[n].v * Nges_N.v / 10.0;
    fracht_NO3_N.v := Wflow_arr[n].v * NO3_N.v / 10.0;
    fracht_NH4_N.v := Wflow_arr[n].v * NH4_N.v / 10.0;

    if ((start_cum_date.v <= GlobTime.c) and (GlobTime.C <= end_cum_date.v)) then
      begin
      fracht_Nges_N_cum.c := fracht_Nges_N.v;
      fracht_NO3_N_cum.c := fracht_NO3_N.v;
      fracht_NH4_N_cum.c := fracht_NH4_N.v;
    end;

  end;

  if (concentration_date > 0) then
    messdatum.v := concentration_date
  else
    messdatum.v := NaN;

  if (Nges_N.v = 0) then Nges_N.v := NaN;
  if (NO3_N.v = 0) then NO3_N.v := NaN;
  if (NH4_N.v = 0) then NH4_N.v := NaN;

  if (Wflow_arr[n].v < 0) then begin
    fracht_Nges_N.v := 0;
    fracht_NO3_N.v := 0;
    fracht_NH4_N.v := 0;
  end;




end;

procedure Register;
begin
  RegisterComponents('Simulation', [TConcentration]);
end;

end.

