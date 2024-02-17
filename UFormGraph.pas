unit UFormGraph;

interface

uses
 Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.Menus, vcl.ExtCtrls,  UTextFileH,
  vcl.ComCtrls, vcl.ToolWin, vcl.StdCtrls, vcl.Buttons, Math, VclTee.TeeGDIPlus,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series;

const
  MaxSeries = 10;

type
  TLineSeriesArr = Array[1..MaxSeries] of TFastLineSeries;
  TPointSeriesArr = Array[1..MaxSeries] of TPointSeries;

  TFormGraph = class(TForm)
    SaveDialog1: TSaveDialog;
    PrintDialog1: TPrintDialog;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Chart1: TChart;
    TabSheet2: TTabSheet;
    SrcLabel: TLabel;
    DstLabel: TLabel;
    IncludeBtnSim: TSpeedButton;
    IncAllBtnSim: TSpeedButton;
    ExcludeBtnSim: TSpeedButton;
    ExAllBtnSim: TSpeedButton;
    OKBtn: TButton;
    CancelBtn: TButton;
    SrcListSim: TListBox;
    DstListSim: TListBox;
    ButtonUebernehmen: TButton;
    Simulationsergebnisse: TLabel;
    ToolBar1: TToolBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    BtnSimFileOpen: TButton;
    BtnDataFileOpen: TButton;
    IncludeBtnMeas: TSpeedButton;
    InclAllBtnMeas: TSpeedButton;
    ExcludeBtnMeas: TSpeedButton;
    ExAllBtnMeas: TSpeedButton;
    SrcListMeas: TListBox;
    DstListMeas: TListBox;
    BtnPrint: TSpeedButton;
    BtnSave: TSpeedButton;
    LblDaten: TLabel;
    BtnUpdateSeries: TSpeedButton;
    procedure PrintClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure IncludeBtnSimClick(Sender: TObject);
    function  GetFirstSelection(List: TCustomListBox): Integer;
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetItem(List: TListBox; Index: Integer);
    procedure SetSimButtons;
    procedure SetMeasButtons;
    procedure OKBtnClick(Sender: TObject);
    procedure OKBtnExit(Sender: TObject);
    procedure ButtonUebernehmenClick(Sender: TObject);
    procedure ExcludeBtnSimClick(Sender: TObject);
    procedure IncAllBtnSimClick(Sender: TObject);
    procedure ExAllBtnSimClick(Sender: TObject);
    procedure BtnSimFileOpenClick(Sender: TObject);
    procedure BtnDataFileOpenClick(Sender: TObject);
    procedure IncludeBtnMeasClick(Sender: TObject);
    procedure InclAllBtnMeasClick(Sender: TObject);
    procedure ExcludeBtnMeasClick(Sender: TObject);
    procedure ExAllBtnMeasClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnUpdateSeriesClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
   DataFileSim : TTextFileH;
   DataFileMeas: TTextFileH;
   SelSeriesSim : TStringList;
   SelSeriesDat : TStringList;
   LineSeriesArr : TLineSeriesArr;
   PointSeriesArr : TPointSeriesArr;
   n_LineSeries, n_PointSeries : integer;

   procedure UpdateSeries;
  end;

var
  FormGraph: TFormGraph;

implementation

uses
  UformMod;
{$R *.DFM}

procedure TFormGraph.PrintClick(Sender: TObject);
var
  success : boolean;
begin
   success := printdialog1.execute;
   if success then
     Chart1.PrintLandscape;
end;


procedure TFormGraph.SaveClick(Sender: TObject);

var
  filename : string;
  success : boolean;
begin
   success := SaveDialog1.Execute;
   if success then begin
     filename := saveDialog1.FileName;
     Chart1.SaveToMetafileEnh(filename);
   end;

end;

procedure TFormGraph.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i : integer;

begin

   SelSeriesSim.Free;;
   SelSeriesDat.Free;
   self.DataFileSim.Free;
   Self.DataFileMeas.Free;

   For I := 1 to MaxSeries do begin
     LineSeriesArr[i].free;
     PointSeriesArr[i].free;
   end;
//   dec(FormMod.nFormGraph);
   {DataFileMeas.Free;
   DataFileSim.Free;}
end;




procedure TFormGraph.FormCreate(Sender: TObject);
begin
   SelSeriesSim := TStringList.create;
   SelSeriesDat := TStringList.create;
   n_lineseries := 0;
   n_PointSeries := 0;
end;

procedure TFormGraph.UpdateSeries;

var
  i : integer;
  x, y : real;
  color : TColor;
  ActLineSeries : TFastLineSeries;
  //ActPointSeries : TPointSeries;
begin
  chart1.RemoveAllSeries;

//  For I := 1 to n_LineSeries do begin
//    if LineSeriesArr[i] <> nil then begin
//      chart1.RemoveSeries(LineSeriesArr[i]);
//      LineSeriesArr[i].destroy;
//      LineSeriesArr[i].free;
//    end;
//  end;
    n_lineSeries := 0;


  for i := 1 to SelSeriesSim.Count do begin
    LineSeriesArr[i] := TFastLineSeries.create(Chart1);
    inc(n_lineSeries);
    ActLineSeries := LineSeriesArr[i];
    LineSeriesArr[i].title := SelSeriesSim.Strings[i-1];
    ActLineSeries.LinePen.Width := 2;
    Chart1.AddSeries(LineSeriesArr[i]);
  end;
  if DataFileSim <> nil then begin
    DataFileSim.GoTop;

    While DataFileSim.hasMoreLines() do begin
        DataFileSim.FastNextLine;
        x := DataFileSim.getIndexValue(0);
        color := ClBlue;
        for i := 1 to SelSeriesSim.Count do begin
          y := DataFileSim.getValue(SelSeriesSim.Strings[i-1]);
          if not isnan(y) then
            LineSeriesArr[i].addxy(x, y,'',Color);
          inc(Color);
        end;
    end;
    //Datafilesim.close_File;
  end;

  For I := 1 to n_PointSeries do begin
    if PointSeriesArr[i] <> nil then begin
      Chart1.RemoveSeries(PointSeriesArr[i]);
      PointSeriesArr[i].free;
    end;
    n_PointSeries :=0;
  end;
  for i := 1 to SelSeriesdat.Count do begin
    PointSeriesArr[i] := TPointSeries.create(Chart1);
    inc(n_pointSeries);
//    ActPointSeries := PointSeriesArr[i];
    PointSeriesArr[i].title := SelSeriesdat.Strings[i-1];
    PointSeriesArr[i].XValues.Datetime := true;

    Chart1.AddSeries(PointSeriesArr[i]);
  end;

  If DataFileMeas <> nil then begin
    DataFileMeas.GoTop;

    While DataFileMeas.hasMoreLines() do begin
        DataFileMEas.FastNextLine;
        x := DataFileMeas.getIndexValue(0);
        for i := 1 to SelSeriesDat.Count do begin
          y := DataFileMeas.getValue(SelSeriesdat.Strings[i-1]);
          if not isnan(y) then

          PointSeriesArr[i].addxy(x, y,'',PointSeriesArr[i].seriesColor);
        end;
    end;
    //DataFileMeas.close_File;
  end;

  Chart1.Update;

end;


function TFormGraph.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TFormGraph.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then
    begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;


procedure TFormGraph.IncludeBtnSimClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListSim);
  MoveSelected(SrcListSim, DstListSim.Items);
  SetItem(SrcListsim, Index);
end;

procedure TFormGraph.ExcludeBtnSimClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstListSim);
  MoveSelected(DstListSim, SrcListSim.Items);
  SetItem(DstListSim, Index);
end;

procedure TFormGraph.IncAllBtnSimClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcListSim.Items.Count - 1 do
    DstListSim.Items.AddObject(SrcListSim.Items[I],
      SrcListSim.Items.Objects[I]);
  SrcListSim.Items.Clear;
  SetItem(SrcListSim, 0);
end;

procedure TFormGraph.ExAllBtnSimClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstListSim.Items.Count - 1 do
    SrcListSim.Items.AddObject(DstListSim.Items[I], DstListSim.Items.Objects[I]);
  DstListSim.Items.Clear;
  SetItem(DstListSim, 0);
end;


procedure TFormGraph.SetSimButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcListSim.Items.Count = 0;
  DstEmpty := DstListSim.Items.Count = 0;
  IncludeBtnSim.Enabled := not SrcEmpty;
  IncAllBtnSim.Enabled := not SrcEmpty;
  ExcludeBtnSim.Enabled := not DstEmpty;
  ExAllBtnSim.Enabled := not DstEmpty;
end;

procedure TFormGraph.SetMeasButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcListMeas.Items.Count = 0;
  DstEmpty := DstListMeas.Items.Count = 0;
  IncludeBtnMeas.Enabled := not SrcEmpty;
  InclAllBtnMeas.Enabled := not SrcEmpty;
  ExcludeBtnMeas.Enabled := not DstEmpty;
  ExAllBtnMeas.Enabled := not DstEmpty;
end;

procedure TFormGraph.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do
  begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then Index := 0
    else if Index > MaxIndex then Index := MaxIndex;
    Selected[Index] := True;
  end;
  if (List = DstListSim) or (List = SrcListSim) then
    SetSimButtons
  else
    SetMeasButtons;
end;


procedure TFormGraph.OKBtnClick(Sender: TObject);


begin
  SelSeriesSim.Clear;
  SelSeriesSim.CommaText:= DstListSim.Items.CommaText;
  SelSeriesDat.Clear;
  SelSeriesDat.CommaText := DstListMeas.Items.CommaText;
  UpdateSeries;
  Close;
end;

procedure TFormGraph.OKBtnExit(Sender: TObject);
begin
  UpdateSeries;
end;

procedure TFormGraph.ButtonUebernehmenClick(Sender: TObject);

begin
  SelSeriesSim.Clear;
  SelSeriesSim.CommaText:= DstListSim.Items.CommaText;
  SelSeriesDat.Clear;
  SelSeriesDat.CommaText := DstListMeas.Items.CommaText;
  UpdateSeries;
end;



procedure TFormGraph.BtnSimFileOpenClick(Sender: TObject);
var
  success : boolean;
  i : integer;
begin
  for i := 1 to n_lineSeries do begin
      chart1.RemoveSeries(LineSeriesArr[i]);
      LineSeriesArr[i].free;
  end;
  SrcListSim.Clear;
  DstListSim.clear;
  OpenDialog1.FileName:= '*.*';
  success := OpenDialog1.Execute;
  if Success then begin
  {KLUSS
  If DataFileSim <> nil then begin
    DataFileSim.init(OpenDialog1.FileName);
  end else begin
    DataFileSim := TTextFileH.create;
    DataFileSim.init(OpenDialog1.FileName);
  end; }

  DataFileSim := TTextFileH.create;
  DataFileSim.init(OpenDialog1.FileName);

    StatusBar1.Panels[0].text := 'SimFile: '+OpenDialog1.FileName;
//    SelectSeries.enabled := true;
//    SelectSimFileSeries.enabled := true;
    SrcListSim.Clear;
    DstListSim.clear;
    For i := 1 to DataFileSim.FirstLine.Count-1 do
      SrcListSim.Items.Add(DataFileSim.FirstLine.Strings[i]);
  end;
  OpenDialog1.FileName:= '*.*';

end;


procedure TFormGraph.BtnDataFileOpenClick(Sender: TObject);
var
  success : boolean;
  i : integer;

begin
  for i := 1 to n_PointSeries do begin
    chart1.RemoveSeries(PointSeriesArr[i]);
    PointSeriesArr[i].free;
  end;
  SrcListMeas.Clear;
  DstListMeas.clear;

  OpenDialog1.Filterindex := 2;
  success := OpenDialog1.Execute;
  if Success then begin
    {KLUSS
    If DataFileMeas = nil then begin
      DataFilemeas := TTextFileH.create;
      DataFilemeas.init(OpenDialog1.FileName);
    end
    else DataFilemeas.init(OpenDialog1.FileName);
    }

    DataFileMeas := TTextFileH.create;
    DataFileMeas.init(OpenDialog1.FileName);

    StatusBar1.Panels[1].text := 'DataFile: '+OpenDialog1.FileName;
//    SelectSeries.enabled := true;
//    SelectDataFileSeries.enabled := true;
      SrcListMeas.Clear;
      DstListMeas.clear;
      For i := 1 to DataFileMeas.FirstLine.Count-1 do
        SrcListMeas.Items.Add(DataFilemeas.FirstLine.Strings[i]);
  end;
end;


procedure TFormGraph.IncludeBtnMeasClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcListMeas);
  MoveSelected(SrcListMeas, DstListMeas.Items);
  SetItem(SrcListMeas, Index);
end;

procedure TFormGraph.InclAllBtnMeasClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcListMeas.Items.Count - 1 do
    DstListMeas.Items.AddObject(SrcListMeas.Items[I],
      SrcListMeas.Items.Objects[I]);
  SrcListMeas.Items.Clear;
  SetItem(SrcListMeas, 0);
end;

procedure TFormGraph.ExcludeBtnMeasClick(Sender: TObject);
var
  Index: Integer;

begin
  Index := GetFirstSelection(DstListMeas);
  MoveSelected(DstListMeas, SrcListSim.Items);
  SetItem(DstListMeas, Index);
end;

procedure TFormGraph.ExAllBtnMeasClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstListMeas.Items.Count - 1 do
    SrcListMeas.Items.AddObject(DstListMeas.Items[I], DstListMeas.Items.Objects[I]);
  DstListMeas.Items.Clear;
  SetItem(DstListMeas, 0);
end;


procedure TFormGraph.BtnPrintClick(Sender: TObject);
var
  success : boolean;
begin
   success := printdialog1.execute;
   if success then
     Chart1.PrintLandscape;

end;

procedure TFormGraph.BtnSaveClick(Sender: TObject);
var
  filename : string;
  success : boolean;
begin
   success := SaveDialog1.Execute;
   if success then begin
     filename := saveDialog1.FileName;
     Chart1.SaveToMetafileEnh(filename);
   end;
end;

procedure TFormGraph.BtnUpdateSeriesClick(Sender: TObject);
begin
  UpdateSeries;
  show;
end;




end.
