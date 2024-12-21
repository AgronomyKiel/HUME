unit UPixelzaehler;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Math, Menus, ExtCtrls, StdCtrls, ComCtrls, GraphicEx, Grids,
  BaseGrid, AdvGrid, Help, Spin, TeCanvas, FileCtrl;

type
  THSBColor = record
    Hue,
      Saturnation,
      Brightness: Double;
  end;
  TForm1 = class(TForm)
    mm1: TMainMenu;
    mniDatei1: TMenuItem;
    mniiOeffnen1: TMenuItem;
    dlgOpen1: TOpenDialog;
    ScrollBox1: TScrollBox;
    img1: TImage;
    btn3: TButton;
    btnReload: TButton;
    stat1: TStatusBar;
    StringGrid1: TAdvStringGrid;
    mniAnsicht1: TMenuItem;
    mniHilfe1: TMenuItem;
    mniEinstellungen1: TMenuItem;
    mnigrn1: TMenuItem;
    mnidunkel1: TMenuItem;
    mniN1001: TMenuItem;
    mniN501: TMenuItem;
    mniN251: TMenuItem;
    mniN101: TMenuItem;
    mniN51: TMenuItem;
    mniN11: TMenuItem;
    grp1: TGroupBox;
    ButtonColorInnerhalb: TButtonColor;
    ButtonColorAusserhalb: TButtonColor;
    chkinnerhalb: TCheckBox;
    chkausserhalb: TCheckBox;
    grp2: TGroupBox;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    sehuestart: TSpinEdit;
    sehueend: TSpinEdit;
    sesaturationstart: TSpinEdit;
    sesaturationend: TSpinEdit;
    sebrightnessstart: TSpinEdit;
    sebrightnessend: TSpinEdit;
    mniCSV1: TMenuItem;
    dlgSave1: TSaveDialog;
    pm1: TPopupMenu;
    mniLschen1: TMenuItem;
    pb1: TProgressBar;
    mniAlleBilddateienimUnterverzeichnisanalysieren1: TMenuItem;
    mniInfo1: TMenuItem;
    mniFarbraum1: TMenuItem;

    procedure mniiOeffnen1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure doload(const name: string);

    procedure btn3Click(Sender: TObject);
    function RGBToHSB(rgb: PRGBQuad): THSBColor;
    procedure btnReloadClick(Sender: TObject);

    procedure setscale(d: double);
    procedure mnigrn1Click(Sender: TObject);
    procedure mnidunkel1Click(Sender: TObject);
    procedure ButtonColorAusserhalbClick(Sender: TObject);
    procedure ButtonColorInnerhalbClick(Sender: TObject);
    procedure mniN1001Click(Sender: TObject);
    procedure mniN501Click(Sender: TObject);
    procedure mniN251Click(Sender: TObject);
    procedure mniN101Click(Sender: TObject);
    procedure mniN51Click(Sender: TObject);
    procedure mniN11Click(Sender: TObject);
    procedure mniCSV1Click(Sender: TObject);
    procedure mniLschen1Click(Sender: TObject);
    procedure mniAlleBilddateienimUnterverzeichnisanalysieren1Click(
      Sender: TObject);
    procedure analyse(dir: string);
    procedure run();
    procedure mniInfo1Click(Sender: TObject);
    procedure mniFarbraum1Click(Sender: TObject);

  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;
  filename: TFileName;
  bitmap: TBitmap;
  scale: double;
  insideColor, outsideColor: Integer;

implementation

uses Info;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  bitmap := TBitmap.Create;
  scale := 1;

  StringGrid1.Rows[0].CommaText := 'Filename,Total,Matching,Fraction';

  StringGrid1.AutoSizeColumns(true);
  sehuestart.Text := '60';
  sehueend.Text := '180';
  sesaturationstart.Text := '10';
  sesaturationend.Text := '100';
  sebrightnessstart.Text := '20';
  sebrightnessend.Text := '100';

  insideColor := clBlack;
  outsidecolor := clWhite;

  ButtonColorInnerhalb.SymbolColor := insideColor;
  ButtonColorAusserhalb.SymbolColor := outsideColor;
end;

procedure TForm1.btn3Click(Sender: TObject);
begin
  run();
end;

procedure TForm1.run();
var
  p1: PRGBQuad;
  hsb: THSBColor;
  h, w, n1, n2: Integer;
  huestart, hueend,
    brightnessstart, brightnessend,
    saturationstart, saturationend: double;
  str: string;
begin
  if not fileexists(filename) then exit;

  huestart := StrToFloat(sehuestart.Text);
  hueend := StrToFloat(sehueend.Text);
  saturationstart := StrToFloat(sesaturationstart.Text);
  saturationend := StrToFloat(sesaturationend.Text);
  brightnessstart := StrToFloat(sebrightnessstart.Text);
  brightnessend := StrToFloat(sebrightnessend.Text);

  n1 := 0;
  n2 := 0;

  pb1.Position := 0;
  pb1.Max := bitmap.Height div 100 + 1;

  for h := 0 to bitmap.Height - 1 do begin
    if h mod 100 = 0 then pb1.StepIt;
    p1 := bitmap.ScanLine[h];
    for w := 0 to bitmap.Width - 1 do begin
      hsb := RGBToHSB(p1);
      if
        ((huestart <= hsb.Hue) and (hsb.Hue <= hueend) and
        (saturationstart <= hsb.Saturnation) and (hsb.Saturnation <=
        saturationend) and
        (brightnessstart <= hsb.Brightness) and (hsb.Brightness <=
        brightnessend)) then begin

        Inc(n1);
        if chkinnerhalb.Checked then begin
          p1^.rgbRed := GetRValue(insidecolor);
          p1^.rgbGreen := GetGValue(insidecolor);
          p1^.rgbBlue := GetBValue(insidecolor);
        end;
      end else begin
        if chkausserhalb.Checked then begin
          p1^.rgbRed := GetRValue(outsidecolor);
          p1^.rgbGreen := GetGValue(outsidecolor);
          p1^.rgbBlue := GetBValue(outsidecolor);

        end;
        inc(n2);
      end;
      inc(p1);
    end;
  end;
  pb1.Position := 0;
  img1.Picture.Bitmap := bitmap;

  img1.Canvas.StretchDraw(Rect(0, 0, Round(bitmap.Width * scale),
    Round(bitmap.Height * scale)), bitmap);
  img1.Height := Round(bitmap.Height * scale);
  img1.Width := Round(bitmap.Width * scale);

  str := ExtractFileName(filename) + ','
    + IntToStr(n1 + n2) + ',' + IntToStr(n1) + ','
    + Format('%.8n', [n1 / (n1 + n2)]);

  StringGrid1.rowCount := StringGrid1.RowCount + 1;
  StringGrid1.Rows[StringGrid1.rowCount - 2].StrictDelimiter := True;
  StringGrid1.Rows[StringGrid1.rowCount - 2].Delimiter := ',';
  StringGrid1.Rows[StringGrid1.rowCount - 2].DelimitedText := str;

  StringGrid1.AutoSizeColumns(true);
end;

procedure TForm1.btnReloadClick(Sender: TObject);
begin
  doload(filename);
end;

procedure TForm1.ButtonColorAusserhalbClick(Sender: TObject);
begin
  outsideColor := ColorToRGB(ButtonColorAusserhalb.SymbolColor);
end;

procedure TForm1.ButtonColorInnerhalbClick(Sender: TObject);
begin
  insideColor := ColorToRGB(ButtonColorInnerhalb.SymbolColor);
end;

procedure TForm1.setscale(d: double);
begin
  scale := d;
  img1.Canvas.StretchDraw(Rect(0, 0, Round(bitmap.Width * scale),
    Round(bitmap.Height * scale)), bitmap);
  img1.Height := Round(bitmap.Height * scale);
  img1.Width := Round(bitmap.Width * scale);
end;

procedure TForm1.doload(const name: string);
var
  graphic: TGraphic;
  graphicClass: TGraphicClass;
begin

  bitmap.FreeImage;


  graphicClass := FileFormatList.GraphicFromExtension(name);

  if graphicClass = nil then begin
    ShowMessage('Format unbekannt: ' + name);
    Exit;
  end;

  graphic := graphicClass.Create;
  graphic.LoadFromFile(name);

  bitmap.PixelFormat := pf32Bit;
  bitmap.Width := graphic.Width;
  bitmap.Height := graphic.Height;
  bitmap.Canvas.Draw(0, 0, graphic);

  graphic.Free;

  img1.Picture.Bitmap := bitmap;

  img1.Canvas.StretchDraw(Rect(0, 0, Round(bitmap.Width * scale),
    Round(bitmap.Height * scale)), bitmap);
  img1.Height := Round(bitmap.Height * scale);
  img1.Width := Round(bitmap.Width * scale);

  stat1.Panels[0].Text := name;
end;

procedure TForm1.analyse(dir: string);
const
  FileExts: array[0..15] of string = ('pcd', 'psd', 'pdd', 'gif', 'ppm', 'pgm',
    'pbm', 'fax', 'tif', 'tiff', 'ico', 'png', 'jpeg', 'jpg', 'gif', 'bmp');
var
  searchResult: TSearchRec;
  i: Integer;
  success: Boolean;
begin

  if FindFirst(dir + '/*', faAnyFile, searchResult) = 0 then begin
    repeat
      if searchResult.Name[1] = '.' then continue;

      if (searchResult.Attr and faDirectory) = faDirectory then
        analyse(dir + '/' + searchResult.Name)
      else begin
        for i := Low(FileExts) to High(FileExts) do begin
          if AnsiLowerCase(ExtractFileExt(searchResult.Name)) = '.' + FileExts[i]
            then begin
            doload(dir + '/' + searchResult.Name);
            filename := dir + '/' + searchResult.Name;
            run();
          end;
        end;
      end;

    until FindNext(searchResult) <> 0;
    FindClose(searchResult);
  end;

end;

procedure TForm1.mniAlleBilddateienimUnterverzeichnisanalysieren1Click(
  Sender: TObject);
var
  chosenDirectory: string;
begin
  if SelectDirectory('Select a directory', '', chosenDirectory) then
    analyse(chosenDirectory)
end;

procedure TForm1.mniCSV1Click(Sender: TObject);
var
  pfad: string;
begin
  dlgsave1.Title := 'Save your text or word file';
  dlgsave1.Filter := 'CSV|*.csv|Text file|*.txt';
  dlgsave1.DefaultExt := 'csv';
  dlgsave1.FilterIndex := 1;
  if dlgsave1.Execute then begin
    case dlgsave1.FilterIndex of
      1: begin
          pfad := ChangeFileExt(dlgsave1.FileName, '.csv');
          StringGrid1.SaveToCSV(pfad);
        end;
      2: begin
          pfad := ChangeFileExt(dlgsave1.FileName, '.txt');
          StringGrid1.SaveToASCII(pfad);
        end;
    end;
  end;
end;

procedure TForm1.mnidunkel1Click(Sender: TObject);
begin
  sehuestart.Text := '0';
  sehueend.Text := '360';
  sesaturationstart.Text := '0';
  sesaturationend.Text := '100';
  sebrightnessstart.Text := '0';
  sebrightnessend.Text := '90';
end;



procedure TForm1.mniFarbraum1Click(Sender: TObject);
begin
   FormFarbraum.Visible := True;
end;

procedure TForm1.mnigrn1Click(Sender: TObject);
begin
  sehuestart.Text := '60';
  sehueend.Text := '180';
  sesaturationstart.Text := '10';
  sesaturationend.Text := '100';
  sebrightnessstart.Text := '20';
  sebrightnessend.Text := '100';
end;

procedure TForm1.mniInfo1Click(Sender: TObject);
begin
  FormInfo.Visible := True;
end;

procedure TForm1.mniiOeffnen1Click(Sender: TObject);
begin
  if dlgOpen1.Execute then begin
    filename := dlgOpen1.FileName;
    doload(filename);
  end;
end;

procedure TForm1.mniLschen1Click(Sender: TObject);
begin

  if (StringGrid1.rowcount > 2) then begin
    StringGrid1.ClearRows(StringGrid1.Row, 1);
    StringGrid1.RemoveRows(StringGrid1.Row, 1);
  end;
end;

function TForm1.RGBToHSB(rgb: PRGBQuad): THSBColor;
var
  minRGB, maxRGB, delta: Double;
  h, s, b: Double;
begin
  H := 0.0;
  minRGB := Min(Min(rgb.rgbRed, rgb.rgbGreen), rgb.rgbBlue);
  maxRGB := Max(Max(rgb.rgbRed, rgb.rgbGreen), rgb.rgbBlue);
  delta := (maxRGB - minRGB);
  b := maxRGB;
  if (maxRGB <> 0.0) then s := 255.0 * Delta / maxRGB
  else s := 0.0;
  if (s <> 0.0) then begin
    if rgb.rgbRed = maxRGB then h := (rgb.rgbGreen - rgb.rgbBlue) / Delta
    else
      if rgb.rgbGreen = maxRGB then
      h := 2.0 + (rgb.rgbBlue - rgb.rgbRed) / Delta
    else
      if rgb.rgbBlue = maxRGB then
      h := 4.0 + (rgb.rgbRed - rgb.rgbGreen) / Delta
  end else h := -1.0;
  h := h * 60;
  if h < 0.0 then h := h + 360.0;
  with result do begin
    Hue := h;
    Saturnation := s * 100 / 255;
    Brightness := b * 100 / 255;
  end;
end;

procedure TForm1.mniN1001Click(Sender: TObject);
begin
  setscale(1);
end;

procedure TForm1.mniN101Click(Sender: TObject);
begin
  setscale(0.1);
end;

procedure TForm1.mniN11Click(Sender: TObject);
begin
  setscale(0.01);
end;

procedure TForm1.mniN251Click(Sender: TObject);
begin
  setscale(0.25);
end;

procedure TForm1.mniN501Click(Sender: TObject);
begin
  setscale(0.5);
end;

procedure TForm1.mniN51Click(Sender: TObject);
begin
  setscale(0.05);
end;

end.

