unit Light;
{Demonstrates some 3-D-features of MathImage, as well as the use
 of the TSurface object. The routines marked by *********** use
 MathImage methods.}

interface

uses
  SysUtils,
{$IFDEF WINDOWS}
  WinTypes, WinProcs,
{$ENDIF}
{$IFDEF WIN32}
  Windows,
{$ENDIF}
  Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls,
  MathImge, Menus, Clipbrd, OverlayImage;

const
  tmin = -pi; tmax = pi; smin = 0; smax = 2 * pi;
  tmesh = 180; smesh = 28; {knot parameter mesh}
  r = 1.6; {radius of knot tube}
  kxmin = -6.1; kxmax = 6.1; kymin = -6.1; kymax = 6.1;
  kzmin = -4.6; kzmax = 4.6; {knot world box}
  gxmin = -pi; gxmax = pi; gymin = -pi; gymax = pi; {graph domain}
  xMesh = 70; yMesh = 70; {graph mesh}
  gzmin = -2; gzmax = 2; {graph range}
  RotInc = 6; ZoomInc = 0.06; MoveInc = 0.024; {increments for rotation/zoom}
  colorarray: array[0..11] of TColor = ($00CB9F74, $00D8AD49, $00E6C986,
    $00F2E3C1, $00DAF0C4, $00A6E089, $0086D560, $0065CFB5, $008DC5FC, $0075D5FD,
    $0078E1ED, $00ACEDF4);
  levelsarray: array[0..11] of MathFloat = (-4, -2.5, -2, -1.5, -1, -0.5, 0,
    0.5, 1, 1.5, 2, 2.5);

type
  TLitSurfaceForm = class(TForm)
    Panel1: TPanel;
    KnotButton: TButton;
    FillButton: TButton;
    UpButton: TButton;
    LeftButton: TButton;
    RightButton: TButton;
    DownButton: TButton;
    ColorDialog1: TColorDialog;
    InButton: TButton;
    OutButton: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MoveInButton: TButton;
    MoveOutButton: TButton;
    Panel2: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    vdshow: TLabel;
    vashow: TLabel;
    zrshow: TLabel;
    yrshow: TLabel;
    GraphButton: TButton;
    Aspectcheck: TCheckBox;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    BackEdit: TEdit;
    FrontEdit: TEdit;
    Button1: TButton;
    PopupMenu1: TPopupMenu;
    CopytoClipboard1: TMenuItem;
    GraphImage: TMathImage;
    SaveasMetafile1: TMenuItem;
    SaveDialog1: TSaveDialog;
    CheckBox1: TCheckBox;
    Graph2Button: TButton;
    procedure FillButtonClick(Sender: TObject);
    procedure KnotButtonClick(Sender: TObject);
    procedure InButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure InButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure OutButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure UpButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure UpButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure LeftButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure RightButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure DownButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure GraphImageResize(Sender: TObject);
    procedure MoveOutButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure MoveInButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure MoveInButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GraphButtonClick(Sender: TObject);
    procedure GraphimageRotating(Sender: TObject);
    procedure GraphimageRotateStop(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CopytoClipboard1Click(Sender: TObject);
    procedure SaveasMetafile1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Graph2ButtonClick(Sender: TObject);
  private
    FillColor: TColor;
    knotsurface, graph1, graph2: TSurface;
    graphsurface: TLevelSurface;
    group: TSurfaceCollection;
    currenttype: Integer;
    back, front: MathFloat;
    function x0(t: MathFloat): MathFloat;
    function y0(t: MathFloat): MathFloat;
    function z0(t: MathFloat): MathFloat;
    function x1(t: MathFloat): MathFloat;
    function y1(t: MathFloat): MathFloat;
    function z1(t: MathFloat): MathFloat;
    function x2(t: MathFloat): MathFloat;
    function y2(t: MathFloat): MathFloat;
    function z2(t: MathFloat): MathFloat;
    procedure knot(t, s: MathFloat; var x, y, z: MathFloat);
    procedure Graph(x, y: MathFloat; var z: MathFloat);
    procedure MakeKnotSurface;
    procedure MakeGraphSurfaces;
    procedure upd;
    { Private declarations }
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public declarations }
  end;

var
  LitSurfaceForm: TLitSurfaceForm;

implementation

uses MDemo1;


{$R *.DFM}

procedure TLitSurfaceForm.CreateParams(var Params: TCreateParams);
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


{*************************************}

procedure TLitSurfaceForm.FormCreate(Sender: TObject);
begin
  FillColor := $0002D0F4;
  MakeKnotSurface;
  MakeGraphSurfaces;
  upd;
  currenttype := 1;
  ControlStyle := ControlStyle + [csOpaque];
end;


procedure TLitSurfaceForm.FillButtonClick(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then FillColor := Color;
  GraphimageRotateStop(self);
end;

function TLitSurfaceForm.x0; {Knot Core Curve}
begin
  Result := 2 * cos(2 * t) + cos(t);
end;

function TLitSurfaceForm.x1; {1st Derivative}
begin
  Result := -4 * sin(2 * t) - sin(t);
end;

function TLitSurfaceForm.x2; {2nd Derivative}
begin
  Result := -8 * cos(2 * t) - cos(t);
end;

function TLitSurfaceForm.y0; {Knot Core Curve}
begin
  Result := 2 * sin(2 * t) - sin(t);
end;

function TLitSurfaceForm.y1;
begin
  Result := 4 * cos(2 * t) - cos(t);
end;

function TLitSurfaceForm.y2;
begin
  Result := -8 * sin(2 * t) + sin(t);
end;

function TLitSurfaceForm.z0; {Knot Core Curve}
begin
  Result := 1.5 * sin(3 * t);
end;

function TLitSurfaceForm.z1;
begin
  Result := 4.5 * cos(3 * t);
end;

function TLitSurfaceForm.z2;
begin
  Result := -13.5 * sin(3 * t);
end;

procedure TLitSurfaceForm.knot; {Tube surface about core curve}
var
  u, v, xx1, xx2, yy1, yy2, zz1, zz2, X3, Y3, z3, x4, y4, z4, x5, y5, z5, x6, y6, z6: MathFloat;
begin
  xx1 := x1(t); xx2 := x2(t); yy1 := y1(t); yy2 := y2(t); zz1 := z1(t); zz2 := z2(t);
  u := sqr(xx1) + sqr(yy1) + sqr(zz1);
  v := xx1 * xx2 + yy1 * yy2 + zz1 * zz2;
  X3 := xx2 * u - xx1 * v; {1st perp vector}
  Y3 := yy2 * u - yy1 * v;
  z3 := zz2 * u - zz1 * v;
  x4 := yy1 * z3 - zz1 * Y3; {2nd perp vector}
  y4 := zz1 * X3 - xx1 * z3;
  z4 := xx1 * Y3 - yy1 * X3;
  u := sqrt(sqr(X3) + sqr(Y3) + sqr(z3));
  v := sqrt(sqr(x4) + sqr(y4) + sqr(z4));
  u := 1 / u; v := 1 / v;
  x5 := X3 * u; y5 := Y3 * u; z5 := z3 * u; {1st normal}
  x6 := x4 * v; y6 := y4 * v; z6 := z4 * v; {2nd normal}
  x := 2 * x0(t) + r * cos(s) * x5 + r * sin(s) * x6;
    {Core curve + circle in normal plane}
  y := 2 * y0(t) + r * cos(s) * y5 + r * sin(s) * y6;
  z := 2 * z0(t) + r * cos(s) * z5 + r * sin(s) * z6;
end;

procedure TLitSurfaceForm.Graph(x, y: MathFloat; var z: MathFloat);
{graph formula}
begin
  z := 18 * cos(1.8 * x) * sin(2 * y) / (7 + x * x + y * y);
end;

{**************************}

procedure TLitSurfaceForm.KnotButtonClick(Sender: TObject);
var
  SaveBrush: TColor;
begin
  try
    back := StrToFloat(BackEdit.Text);
    front := StrToFloat(FrontEdit.Text);
  except
    on e: EConvertError do
    begin
      MessageDlg(e.Message, mtError, [mbOK], 0);
      exit;
    end;
  end;
  Screen.Cursor := crHourGlass;
  currenttype := 1;
  with GraphImage do
  begin
    d3SetWorld(kxmin, kymin, kzmin, kxmax, kymax, kzmax);
    d3Zscale := 1;
    d3AspectRatio := Aspectcheck.checked;
    Clear;
    SaveBrush := Brush.Color;
    Brush.Color := FillColor;
    d3DrawLitSurface(knotsurface, back, front, True);
    Screen.Cursor := crDefault;
    Brush.Color := SaveBrush;
  end;
  Screen.Cursor := crDefault;
end;

{******************************}

procedure TLitSurfaceForm.GraphButtonClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  currenttype := 2;
  with GraphImage do
  begin
    d3SetWorld(gxmin, gymin, gzmin, gxmax, gymax, gzmax);
    d3AspectRatio := Aspectcheck.checked;
    Clear;
    {d3drawworldbox;}
    {d3drawaxes('x','y','z',2,2,2,0,0,0);}
    try
      back := StrToFloat(BackEdit.Text);
      front := StrToFloat(FrontEdit.Text);
    except
      on e: EConvertError do
      begin
        MessageDlg(e.Message, mtError, [mbOK], 0);
        exit;
      end;
    end;
    d3DrawLitSurface(graphsurface, back, front);
  end;
  Screen.Cursor := crDefault;
end;


{************************************}

procedure TLitSurfaceForm.MakeKnotSurface;
var
  i, j: Integer;
  t, s, x, y, z, deltat, deltas: MathFloat;
begin
  knotsurface := TSurface.Create(tmesh, smesh);
  deltat := (tmax - tmin) / tmesh;
  deltas := (smax - smin) / smesh;
  for i := 0 to tmesh do
  begin
    t := tmin + i * deltat;
    for j := 0 to smesh do
    begin
      s := smin + j * deltas;
      knot(t, s, x, y, z);
      knotsurface.Make(i, j, x, y, z);
    end;
  end;
end;

{*****************************************}

procedure TLitSurfaceForm.MakeGraphSurfaces;
var
  i, j: Integer;
  x, y, z, deltax, deltay: MathFloat;
begin
  graphsurface := TLevelSurface.Create(xMesh, yMesh);
  graph1 := TSurface.Create(xMesh, yMesh);
  graph2 := TSurface.Create(xMesh, yMesh);
  deltax := (gxmax - gxmin) / xMesh;
  deltay := (gymax - gymin) / yMesh;
  for i := 0 to xMesh do
  begin
    x := gxmin + i * deltax;
    for j := 0 to yMesh do
    begin
      y := gymin + j * deltay;
      Graph(x, y, z);
      graphsurface.Make(i, j, x, y, z);
      z := 1 / 4 * (x * x + y * y - 10);
      graph1.Make(i, j, x, y, z);
      if (x = 0) and (y = 0) then
        z := 0
      else
        z := 0.5 * (x * x * y - 1 / 3 * y * y * y) / sqrt(x * x + y * y);
      graph2.Make(i, j, x, y, z);
    end;
  end;
  graphsurface.SetLevels(levelsarray, colorarray);
  group := TSurfaceCollection.Create;
  group.add(graph1, clred, clYellow);
  group.add(graph2, clteal, clSilver);
end;

{*******************************}

procedure TLitSurfaceForm.InButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  with GraphImage do
    d3StartZoomingIn(ZoomInc);
end;

{**********************************************}

procedure TLitSurfaceForm.InButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StopZooming;
end;

{ETC...................}

procedure TLitSurfaceForm.OutButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartZoomingOut(ZoomInc);
end;


procedure TLitSurfaceForm.UpButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingUp(RotInc);
end;

procedure TLitSurfaceForm.UpButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StopRotating;
end;

procedure TLitSurfaceForm.LeftButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingLeft(RotInc);
end;

procedure TLitSurfaceForm.RightButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingRight(RotInc);
end;


procedure TLitSurfaceForm.DownButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingDown(RotInc);
end;

{****************************}

procedure TLitSurfaceForm.GraphImageResize(Sender: TObject);
begin
  if currenttype = 1 then
    KnotButtonClick(self)
  else GraphButtonClick(self);
  invalidate;
end;

procedure TLitSurfaceForm.MoveOutButtonMouseDown(Sender: TObject; Button:
  TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartMovingOut(MoveInc);
end;


procedure TLitSurfaceForm.MoveInButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartMovingIn(MoveInc);
end;

procedure TLitSurfaceForm.MoveInButtonMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StopMoving;
end;


procedure TLitSurfaceForm.upd;
begin
  with GraphImage do
  begin
    vdshow.Caption := FloatToStrf(d3ViewDist, ffgeneral, 4, 4);
    vashow.Caption := FloatToStrf(d3ViewAngle, ffgeneral, 4, 4);
    zrshow.Caption := FloatToStrf(d3Zrotation, ffgeneral, 4, 4);
    yrshow.Caption := FloatToStrf(d3Yrotation, ffgeneral, 4, 4);
  end;
end;

procedure TLitSurfaceForm.FormDestroy(Sender: TObject);
begin
  knotsurface.Free;
  graphsurface.Free;
  graph1.Free;
  graph2.Free;
  group.Free;
end;



{while rotating, moving, zooming only the unilluminated surfaces are drawn
to save time}

procedure TLitSurfaceForm.GraphimageRotating(Sender: TObject);
var
  c: TColor;
begin
  with Sender as TMathImage do
  begin
    Clear;
    c := Brush.Color;
    Brush.Color := FillColor;
    case currenttype of
      1: d3DrawSurface(knotsurface, True, True);
      2: d3DrawSurface(graphsurface, True, True);
      3: d3DrawSurfaceCollection(group, True);
    end;
    upd;
    Brush.Color := c;
  end;
end;

procedure TLitSurfaceForm.GraphimageRotateStop(Sender: TObject);
begin
  case currenttype of
    1: KnotButtonClick(nil);
    2: GraphButtonClick(nil);
    3: Graph2ButtonClick(nil);
  end;
end;

procedure TLitSurfaceForm.FormShow(Sender: TObject);
begin
{$IFDEF WINDOWS}
  SaveasMetafile1.enabled := False;
  CheckBox1.enabled := False;
{$ENDIF}
 // knotbuttonclick(self);
end;

procedure TLitSurfaceForm.CopytoClipboard1Click(Sender: TObject);
begin
  with GraphImage do
    Clipboard.assign(Bitmap);
end;

procedure TLitSurfaceForm.SaveasMetafile1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with SaveDialog1 do
    if Execute then GraphImage.SaveMetafile(filename);
{$ENDIF}
end;

procedure TLitSurfaceForm.CheckBox1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with GraphImage do
  begin
    RecordMetafile := CheckBox1.checked;
    SaveasMetafile1.enabled := RecordMetafile;
  end;
{$ENDIF}
end;

procedure TLitSurfaceForm.Graph2ButtonClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  currenttype := 3;
  with GraphImage do
  begin
    d3SetWorld(gxmin, gymin, gzmin, gxmax, gymax, gzmax);
    d3AspectRatio := Aspectcheck.checked;
    Clear;
    {d3drawworldbox;}
    {d3drawaxes('x','y','z',2,2,2,0,0,0);}
    try
      back := StrToFloat(BackEdit.Text);
      front := StrToFloat(FrontEdit.Text);
    except
      on e: EConvertError do
      begin
        MessageDlg(e.Message, mtError, [mbOK], 0);
        exit;
      end;
    end;
    d3DrawLitSurfaceCollection(group, back, front);
  end;
  Screen.Cursor := crDefault;
end;

end.

