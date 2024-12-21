unit Plane;
{Demonstrates 2-d-graphing with TMathImage and compares a few ways
of getting the job done.
Parts that make use of TMathImage are marked ***********}

interface

uses
  SysUtils,
  Windows,
  Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, MathImge,
  Menus, Clipbrd, OverlayImage;

type
  TPlaneGraphs = class(TForm)
    Panel2: TPanel;
    xshow: TLabel;
    yshow: TLabel;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Periods: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    F1Edit: TEdit;
    F2Edit: TEdit;
    Meshedit: TEdit;
    PEdit: TEdit;
    CheckBox1: TCheckBox;
    OutButton: TButton;
    Label8: TLabel;
    BoxButton: TButton;
    x1label: TLabel;
    x2label: TLabel;
    y1label: TLabel;
    y2label: TLabel;
    PopupMenu1: TPopupMenu;
    Copy1: TMenuItem;
    GraphImage: TMathImage;
    SaveasMetafile1: TMenuItem;
    SaveDialog1: TSaveDialog;
    CheckBox2: TCheckBox;
    DrawButton: TButton;
    SlowRadioButton: TRadioButton;
    FasterRadioButton: TRadioButton;
    FastestRadioButton: TRadioButton;
    Label9: TLabel;
    procedure DrawButtonClick(Sender: TObject);
    procedure GraphImageResize(Sender: TObject);
    procedure GraphImageMouseMove(Sender: TObject; Shift: TShiftState; x,
      y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure F1EditChange(Sender: TObject);
    procedure F2EditChange(Sender: TObject);
    procedure PEditChange(Sender: TObject);
    procedure MeshEditChange(Sender: TObject);
    procedure OutButtonClick(Sender: TObject);
    procedure BoxButtonClick(Sender: TObject);
    procedure GraphImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure GraphImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure FormShow(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure SaveasMetafile1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
  private
    f1, f2, p: MathFloat;
    mesh: Integer;
    xorg, yorg, xmov, ymov: Integer;
    beginbox, Boxing, DataChanged: Boolean;
    savebrushcolor: TColor;
    Points: array of TFloatPointlist;
    function Getf1: MathFloat;
    function Getf2: MathFloat;
    function Getp: MathFloat;
    function getmesh: Integer;
    function r(o: MathFloat): MathFloat;
    procedure upd;
    procedure UseLineTo;
    procedure UsePolyLines;
    procedure MakePointLists;
    { Private declarations }
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public declarations }
  end;

var
  PlaneGraphs: TPlaneGraphs;

implementation

uses MDemo1;

{$R *.DFM}

procedure TPlaneGraphs.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    WndParent := Demoform.Handle;
    Parent := Demoform;
    Style := WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;
    Align := alClient;
  end;
end;

function TPlaneGraphs.Getf1;
var
  x: MathFloat; c: Integer;
begin
  val(F1Edit.Text, x, c);
  if c = 0 then
  begin
    if x <> f1 then
      DataChanged := True;
    Getf1 := x;
  end
  else Getf1 := f1;
end;

function TPlaneGraphs.Getf2;
var
  x: MathFloat; c: Integer;
begin
  val(F2Edit.Text, x, c);
  if c = 0 then
  begin
    if x <> f2 then
      DataChanged := True;
    Getf2 := x;
  end
  else Getf2 := f2;
end;

function TPlaneGraphs.Getp;
var
  x: MathFloat; c: Integer;
begin
  val(PEdit.Text, x, c);
  if c = 0 then
  begin
    if x <> p then
      DataChanged := True;
    Getp := x
  end
  else Getp := p;
end;

function TPlaneGraphs.getmesh;
var
  i, c: Integer;
begin
  val(Meshedit.Text, i, c);
  if c = 0 then
  begin
    if mesh <> i then
      DataChanged := True;
    getmesh := i;
  end
  else getmesh := mesh;
end;

function TPlaneGraphs.r;
begin
  r := sin(o * f1) + cos(o * f2);
end;


procedure TPlaneGraphs.DrawButtonClick(Sender: TObject);
begin
  if not FastestRadioButton.checked then
    UseLineTo
  else
    UsePolyLines;
end;


procedure TPlaneGraphs.GraphImageResize(Sender: TObject);
begin
  DrawButtonClick(nil);
end;


{************************}

procedure TPlaneGraphs.FormCreate(Sender: TObject);
begin
  f1 := 1; f2 := 1.4426395219; p := 50; mesh := 4000;
  f1 := Getf1; f2 := Getf2; p := Getp; mesh := getmesh;
  upd;
  beginbox := False; Boxing := False;
  //ControlStyle := ControlStyle + [csOpaque]; //not needed, hopefully
  savebrushcolor := GraphImage.Brush.Color;
  DataChanged := True;
  SetLength(Points, 0);
  with GraphImage do
  begin
    OverlayBrush.Style := bsClear;
    OverlayPen.Color := clgreen;
  end;
end;

procedure TPlaneGraphs.upd;
begin
  with GraphImage do
  begin
    x1label.Caption := FloatToStrf(d2WorldX1, ffgeneral, 6, 6);
    x2label.Caption := FloatToStrf(d2WorldX2, ffgeneral, 6, 6);
    y1label.Caption := FloatToStrf(d2WorldY1, ffgeneral, 6, 6);
    y2label.Caption := FloatToStrf(d2WorldY2, ffgeneral, 6, 6);
  end;
end;

procedure TPlaneGraphs.F1EditChange(Sender: TObject);
begin
  f1 := Getf1;
end;

procedure TPlaneGraphs.F2EditChange(Sender: TObject);
begin
  f2 := Getf2;
end;

procedure TPlaneGraphs.PEditChange(Sender: TObject);
begin
  p := Getp;
end;

procedure TPlaneGraphs.MeshEditChange(Sender: TObject);
begin
  mesh := getmesh;
end;


 {***********************************}

procedure TPlaneGraphs.OutButtonClick(Sender: TObject);
var
  w, h, x, y: double;
begin
  with GraphImage do
  begin
    w := 4 / 3 * (d2WorldX2 - d2WorldX1);
    h := 4 / 3 * (d2WorldY2 - d2WorldY1);
    x := (d2WorldX1 + d2WorldX2 - w) * 0.5;
    y := (d2WorldY1 + d2WorldY2 - h) * 0.5;
    SetWorld(x, y, x + w, y + h);
  end;
  upd;
  DrawButtonClick(nil);
end;



procedure TPlaneGraphs.BoxButtonClick(Sender: TObject);
begin
  beginbox := True;
  GraphImage.ShowHint := False;
end;


procedure TPlaneGraphs.GraphImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if Shift = [ssLeft] then
  if beginbox then
      begin
        Boxing := True;
        xorg := x; yorg := y;
      end;
end;

{****************************************}
//Note use of overlayed drawing

procedure TPlaneGraphs.GraphImageMouseMove(Sender: TObject;
  Shift: TShiftState; x, y: Integer);
begin
  with GraphImage do
  begin
    xshow.Caption := FloatToStr(WorldX(x));
    yshow.Caption := FloatToStr(WorldY(y));
    if beginbox then
    begin
      OverlayLine(x, 0, x, Height);
      OverlayLine(0, y, Width, y);
      if Boxing then
      begin
        OverlayPen.Width := 3;
        OverlayRectangle(xorg, yorg, x + 1, y + 1);
        OverlayPen.Width := 1;
      end;
      ShowOverlay;
    end;
  end;
end;


{***************************************}

procedure TPlaneGraphs.GraphImageMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
var
  s: Integer;
begin
  if Boxing then
    with GraphImage do
    begin
      Boxing := False;
      beginbox := False;
      ShowHint := True;
      xmov := x; ymov := y;
      if xorg > x then
      begin
        s := xorg;
        xorg := x;
        xmov := s;
      end;
      if y < yorg then
      begin
        s := yorg;
        yorg := ymov;
        ymov := s;
      end;
      try
        SetWorld(WorldX(xorg), WorldY(ymov), WorldX(xmov), WorldY(yorg));
      except
        on EMathImageError do
          MessageDlg('Zoom box too small', mtError, [mbOK], 0);
      end;
      DrawButtonClick(nil);
      upd;
      Screen.Cursor := crDefault;
    end;
end;


procedure TPlaneGraphs.FormShow(Sender: TObject);
begin
{$IFDEF WINDOWS}
  SaveasMetafile1.enabled := False;
  CheckBox2.enabled := False;
{$ENDIF}
 // DrawButtonClick(nil);   Done by GraphImageResize
end;


procedure TPlaneGraphs.Copy1Click(Sender: TObject);
begin
  with GraphImage do
    Clipboard.assign(Bitmap);
end;

{**********************************************}
procedure TPlaneGraphs.SaveasMetafile1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with SaveDialog1 do
    if Execute then GraphImage.SaveMetafile(filename);
{$ENDIF}
end;

procedure TPlaneGraphs.CheckBox2Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with GraphImage do
  begin
    RecordMetafile := CheckBox2.checked;
    SaveasMetafile1.enabled := RecordMetafile;
  end;
{$ENDIF}
end;


{******************************}
procedure TPlaneGraphs.UseLineTo;
//DrawLineTo should not be used for curves. Plus, points which
//have the chance to be drawn again are better off stored
//than being computed on the fly.
var
  i: Integer; o, inv: MathFloat;
begin
  with GraphImage do
  begin
    if FasterRadioButton.checked then
      LockUpdate;
    Clear;
    d2Axes := CheckBox1.checked;
    inv := 2 * pi * p / mesh;
    MoveToPoint(r(0), 0);
    for i := 1 to mesh do
    begin
      o := i * inv;
      DrawLineTo(r(o) * cos(o), r(o) * sin(o));
    end;
    if d2Axes then
      DrawAxes('x', 'y', True, Font.Color, clred);
    if FasterRadioButton.checked then
      UnlockUpdate;
  end;
end;

{**************************************}
procedure TPlaneGraphs.UsePolyLines;
//faster because it uses TCanvas.Polyline and only
//recomputes points if needed.
var i: Integer;
begin
  if DataChanged then
  begin
    MakePointLists;
    DataChanged := False;
  end;
  with GraphImage do
  begin
    LockUpdate;
    Clear;
    d2Axes := CheckBox1.checked;
    for i := 0 to High(Points) do
      DrawPolyline(Points[i]);
    if d2Axes then
      DrawAxes('x', 'y', True, Font.Color, clred);
    UnlockUpdate;  
  end;
end;

{********************************}
procedure TPlaneGraphs.MakePointLists;
var
  i, j: Integer;
  rad, inv, o: MathFloat;
begin
  for i := 0 to High(Points) do
    Points[i].Free;
  SetLength(Points, mesh div 16000 + 1);
  for i := 0 to High(Points) do
    Points[i] := TFloatPointlist.Create;
  //Win95/98 GDI does not accept more than about 16K points
  //in PolyLine, so we may have to break them up.

  inv := 2 * pi * p / mesh;
  i := 0; j := 0;
  while j <= mesh do
  begin
    o := j * inv;
    rad := r(o);
    Points[i].add(rad * cos(o), rad * sin(o));
    if Points[i].Count = 16001 then
      if j < mesh then
      begin
        inc(i);
        Points[i].add(rad * cos(o), rad * sin(o));
      end;
    inc(j);
  end;
end;


end.

