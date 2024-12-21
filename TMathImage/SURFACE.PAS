unit Surface;
{Demonstrates some 3-D-features of MathImage, as well as the use
 of the TSurface object. The routines marked by *********** use
 MathImage methods.}

interface

uses
  SysUtils,
  Windows,
  Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls,
  MathImge, Menus, Clipbrd, OverlayImage;

const
  tmin = -pi; tmax = pi; smin = 0; smax = 2 * pi;
  tmesh = 100; smesh = 20; {knot parameter mesh}
  r = 1.3; {radius of knot tube}
  kxmin = -6.1; kxmax = 6.1; kymin = -6.1; kymax = 6.1;
  kzmin = -3.1; kzmax = 3.1; {knot world box}
  gxmin = -pi; gxmax = pi; gymin = -pi; gymax = pi; {graph domain}
  xMesh = 45; yMesh = 45; {graph mesh}
  gzmin = -3; gzmax = 3; {graph range}
  RotInc = 3; ZoomInc = 0.03; MoveInc = 0.012; {increments for rotation/zoom}
  colorarray: array[0..11] of TColor = ($00CB9F74, $00D8AD49, $00E6C986,
    $00F2E3C1, $00DAF0C4, $00A6E089, $0086D560, $0065CFB5, $008DC5FC, $0075D5FD,
    $0078E1ED, $00ACEDF4);
  levelsarray: array[0..11] of MathFloat = (-4, -2.5, -2, -1.5, -1, -0.5, 0,
    0.5, 1, 1.5, 2, 2.5);
type
  TSurfaceForm = class(TForm)
    Panel1: TPanel;
    KnotButton: TButton;
    FillCheck: TCheckBox;
    WireButton: TButton;
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
    GraphImage: TMathImage;
    SaveDialog1: TSaveDialog;
    PopupMenu1: TPopupMenu;
    SaveasMetafile1: TMenuItem;
    CopytoClipboard1: TMenuItem;
    CheckBox1: TCheckBox;
    Graph2Button: TButton;
    procedure WireButtonClick(Sender: TObject);
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
    WireColor, FillColor: longint;
    knotsurface, graphsurface1, graphsurface2: TSurface;
    graphsurface: TColorSurface;
    group: TSurfaceCollection;
    currenttype: Integer;
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
  SurfaceForm: TSurfaceForm;

implementation

uses MDemo1;


{$R *.DFM}

procedure TSurfaceForm.CreateParams(var Params: TCreateParams);
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

procedure TSurfaceForm.FormCreate(Sender: TObject);
begin
  WireColor := clSilver;
  FillColor := clNavy;
  MakeKnotSurface;
  MakeGraphSurfaces;
  upd;
  currenttype := 1;
  ControlStyle := ControlStyle + [csOpaque];
end;

procedure TSurfaceForm.WireButtonClick(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then
      WireColor := Color;
end;

procedure TSurfaceForm.FillButtonClick(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then FillColor := Color;
end;

function TSurfaceForm.x0; {Knot Core Curve}
begin
  Result := 2 * cos(2 * t) + cos(t);
end;

function TSurfaceForm.x1; {1st Derivative}
begin
  Result := -4 * sin(2 * t) - sin(t);
end;

function TSurfaceForm.x2; {2nd Derivative}
begin
  Result := -8 * cos(2 * t) - cos(t);
end;

function TSurfaceForm.y0; {Knot Core Curve}
begin
  Result := 2 * sin(2 * t) - sin(t);
end;

function TSurfaceForm.y1;
begin
  Result := 4 * cos(2 * t) - cos(t);
end;

function TSurfaceForm.y2;
begin
  Result := -8 * sin(2 * t) + sin(t);
end;

function TSurfaceForm.z0; {Knot Core Curve}
begin
  Result := sin(3 * t);
end;

function TSurfaceForm.z1;
begin
  Result := 3 * cos(3 * t);
end;

function TSurfaceForm.z2;
begin
  Result := -9 * sin(3 * t);
end;

procedure TSurfaceForm.knot; {Tube surface about core curve}
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

procedure TSurfaceForm.Graph(x, y: MathFloat; var z: MathFloat);
var
  r: MathFloat;
{graph formula}
begin
  r := sqrt(sqr(x) + sqr(y));
  z := 3 * exp(-x * x / 1.5) * sin(2 * r);
end;

{**************************}

procedure TSurfaceForm.KnotButtonClick(Sender: TObject);
var
  SaveBrush, SavePen: TColor;
begin
  //screen.cursor:=crhourglass;
  currenttype := 1;
  with GraphImage do
  begin
    LockUpdate;
    d3SetWorld(kxmin, kymin, kzmin, kxmax, kymax, kzmax);
    d3AspectRatio := Aspectcheck.checked;
    d3Zscale := 1;
    Clear;
    d3DrawWorldbox;
    d3DrawBestAxes('x', 'y', 'z', 4, 4, 4, False);
    SaveBrush := Brush.Color;
    SavePen := Pen.Color;
    Pen.Color := WireColor;
    Brush.Color := FillColor;
    d3DrawSurface(knotsurface, FillCheck.checked, True);
    UnlockUpdate;
    Pen.Color := SavePen;
    Brush.Color := SaveBrush;
  end;
  //screen.cursor:=crdefault;
end;

{******************************}

procedure TSurfaceForm.GraphButtonClick(Sender: TObject);
var SavePen: TColor;
begin
  currenttype := 2;
  with GraphImage do
  begin
    LockUpdate;
    d3SetWorld(gxmin, gymin, gzmin, gxmax, gymax, gzmax);
    d3AspectRatio := Aspectcheck.checked;
    d3Zscale := 0.7;
    Clear;
    d3DrawWorldbox;
    d3DrawBestAxes('x', 'y', 'z', 4, 4, 4, False);
    SavePen:=Pen.Color;
    Pen.Color:=Wirecolor;
    d3DrawSurface(graphsurface, FillCheck.checked, True);
    Pen.Color:=SavePen;
    UnlockUpdate;
  end;
end;


{************************************}

procedure TSurfaceForm.MakeKnotSurface;
var
  i, j: Integer; t, s, x, y, z: MathFloat;
begin
  try
    knotsurface := TSurface.Create(tmesh, smesh);
  except
    on e: ESurfaceError do
    begin
      MessageDlg(e.Message, mtError, [mbOK], 0);
      exit;
    end;
  end;
  for i := 0 to tmesh do
  begin
    t := tmin + i * (tmax - tmin) / tmesh;
    for j := 0 to smesh do
      with knotsurface do
      begin
        s := smin + j * (smax - smin) / smesh;
        knot(t, s, x, y, z);
        Make(i, j, x, y, z);
      end;
  end;
end;

{*****************************************}

procedure TSurfaceForm.MakeGraphSurfaces;
var
  i, j, k: Integer; x, y, z, deltax, deltay: MathFloat;
  thisColor: TColor;
begin
  graphsurface := TColorSurface.Create(xMesh, yMesh);
  graphsurface1 := TSurface.Create(xMesh, yMesh);
  graphsurface2 := TSurface.Create(xMesh, yMesh);
  deltax := (gxmax - gxmin) / xMesh;
  deltay := (gymax - gymin) / yMesh;
  for i := 0 to xMesh do
  begin
    x := gxmin + i * deltax;
    for j := 0 to yMesh do
      begin
        y := gymin + j * deltay;
        Graph(x, y, z);
        thisColor := clSilver; //to shut up the compiler
        for k := 0 to High(levelsarray) - 1 do
          if levelsarray[k] <= z then
            if levelsarray[k + 1] >= z then
            begin
              thisColor := colorarray[k];
              break;
            end;
        if z < levelsarray[0] then
          thisColor := colorarray[0];
        if z > levelsarray[High(levelsarray)] then
          thisColor := colorarray[High(levelsarray)];
        GraphSurface.Make(i, j, x, y, z, thisColor);
        z := 1 / 4 * (x * x + y * y - 10);
        GraphSurface1.Make(i, j, x, y, z);
        if (x = 0) and (y = 0) then
          z := 0
        else
          z := 0.5* (x * x * y - 1 / 3 * y * y * y) / sqrt(x * x + y * y);
        GraphSurface2.Make(i, j, x, y, z);

      end;
  end;
  group := TSurfaceCollection.Create;
  group.add(graphsurface1, clBlue, clSilver);
  group.add(graphsurface2, claqua, clGreen);
end;

{*******************************}

procedure TSurfaceForm.InButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  with GraphImage do
    d3StartZoomingIn(ZoomInc);
end;

{**********************************************}

procedure TSurfaceForm.InButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StopZooming;
end;

{ETC...................}

procedure TSurfaceForm.OutButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartZoomingOut(ZoomInc);
end;


procedure TSurfaceForm.UpButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingUp(RotInc);
end;

procedure TSurfaceForm.UpButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StopRotating;
end;

procedure TSurfaceForm.LeftButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingLeft(RotInc);
end;

procedure TSurfaceForm.RightButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingRight(RotInc);
end;


procedure TSurfaceForm.DownButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartRotatingDown(RotInc);
end;

{****************************}


procedure TSurfaceForm.MoveOutButtonMouseDown(Sender: TObject; Button:
  TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartMovingOut(MoveInc);
end;


procedure TSurfaceForm.MoveInButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StartMovingIn(MoveInc);
end;

procedure TSurfaceForm.MoveInButtonMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  GraphImage.d3StopMoving;
end;


procedure TSurfaceForm.upd;
begin
  with GraphImage do
  begin
    vdshow.Caption := FloatToStrf(d3ViewDist, ffgeneral, 4, 4);
    vashow.Caption := FloatToStrf(d3ViewAngle, ffgeneral, 4, 4);
    zrshow.Caption := FloatToStrf(d3Zrotation, ffgeneral, 4, 4);
    yrshow.Caption := FloatToStrf(d3Yrotation, ffgeneral, 4, 4);
  end;
end;

procedure TSurfaceForm.FormDestroy(Sender: TObject);
begin
  knotsurface.Free;
  graphsurface.Free;
  graphsurface1.Free;
  graphsurface2.Free;
  group.Free;
end;



procedure TSurfaceForm.GraphimageRotating(Sender: TObject);
var
  c1, c2: TColor;
begin
  with Sender as TMathImage do
  begin
    Clear;
    c1 := Brush.Color;
    c2 := Pen.Color;
    Pen.Color := WireColor;
    Brush.Color := FillColor;
    case currenttype of
      1: d3DrawSurface(knotsurface, FillCheck.checked, True);
      2: d3DrawSurface(graphsurface, FillCheck.checked, True);
      3: d3DrawSurfaceCollection(group, FillCheck.checked);
    end;
    Pen.Color := c2;
    Brush.Color := c1;
    upd;
  end;
end;

procedure TSurfaceForm.GraphimageRotateStop(Sender: TObject);
begin
  case currenttype of
    1: KnotButtonClick(nil);
    2: GraphButtonClick(nil);
    3: Graph2ButtonClick(nil);
  end;
end;

procedure TSurfaceForm.FormShow(Sender: TObject);
begin
{$IFDEF WINDOWS}
  SaveasMetafile1.enabled := False;
  CheckBox1.enabled := False;
{$ENDIF}
end;

procedure TSurfaceForm.CopytoClipboard1Click(Sender: TObject);
begin
  with GraphImage do
    Clipboard.assign(Bitmap);
end;

procedure TSurfaceForm.SaveasMetafile1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with SaveDialog1 do
    if Execute then GraphImage.SaveMetafile(filename);
{$ENDIF}
end;

procedure TSurfaceForm.CheckBox1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with GraphImage do
  begin
    RecordMetafile := CheckBox1.checked;
    SaveasMetafile1.enabled := RecordMetafile;
  end;
{$ENDIF}
end;

procedure TSurfaceForm.Graph2ButtonClick(Sender: TObject);
begin
  currenttype := 3;
  with GraphImage do
  begin
    LockUpdate;
    d3SetWorld(gxmin, gymin, gzmin, gxmax, gymax, gzmax);
    d3AspectRatio := Aspectcheck.checked;
    d3ZScale:=1;
    Clear;
    d3DrawWorldbox;
    d3DrawBestAxes('x', 'y', 'z', 4, 4, 4, False);
    d3DrawSurfaceCollection(group, FillCheck.checked);
    UnlockUpdate;
  end;
end;

end.

