unit Spcurv;
{Demonstrates some 3-D-features of MathImage.
 The routines marked by *********** use
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
  Forms, Dialogs, StdCtrls, ExtCtrls, MathImge,
  Menus, Clipbrd, OverlayImage, ComCtrls, Lorenz;

const
  tmin = 0; tmax = 6 * pi; {double helix parameter bounds}
  tmesh = 4000; {Number of plot points}
  A = 4; b = 6; r = 2; {'radii'}
  hxmin = -7; hxmax = 7; hymin = -7; hymax = 7; hzmin = -1; hzmax = 21;
  lxmin = -25; lxmax = 25; lymin = -25; lymax = 25; lzmin = 7; lzmax = 57;
  RotInc = 2; MoveInc = 0.008; ZoomInc = 0.012;

type
  TSpaceCurveForm = class(TForm)
    Panel1: TPanel;
    CurveButton: TButton;
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
    v: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    vdshow: TLabel;
    vashow: TLabel;
    zrshow: TLabel;
    yrshow: TLabel;
    Aspectcheck: TCheckBox;
    Axescheck: TCheckBox;
    Button1: TButton;
    Button2: TButton;
    Label8: TLabel;
    GraphImage: TMathImage;
    PopupMenu1: TPopupMenu;
    CopytoClipboard1: TMenuItem;
    SaveasMetafile1: TMenuItem;
    SaveDialog1: TSaveDialog;
    CheckBox1: TCheckBox;
    Label9: TLabel;
    Edit1: TEdit;
    Updown1: TUpDown;
    LightCheck: TCheckBox;
    ViewpointCheck: TRadioButton;
    Light1Check: TRadioButton;
    Light2Check: TRadioButton;
    TrackBar1: TTrackbar;
    UpDown2: TUpDown;
    UpDown3: TUpDown;
    Edit2: TEdit;
    Edit3: TEdit;
    Label10: TLabel;
    l1yrshow: TLabel;
    Label12: TLabel;
    l2yrshow: TLabel;
    Label11: TLabel;
    l1zrshow: TLabel;
    Label14: TLabel;
    l2zrshow: TLabel;
    Label13: TLabel;
    l1dshow: TLabel;
    Label16: TLabel;
    l2dshow: TLabel;
    CurveKindGroup: TRadioGroup;
    FixCheck: TCheckBox;
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
    procedure GraphimageRotating(Sender: TObject);
    procedure GraphimageRotateStop(Sender: TObject);
    procedure CurveButtonClick(Sender: TObject);
    procedure AspectcheckClick(Sender: TObject);
    procedure AxescheckClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure CopytoClipboard1Click(Sender: TObject);
    procedure SaveasMetafile1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure UpDown1ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: SmallInt; Direction: TUpDownDirection);
    procedure Trackbar1Change(Sender: TObject);
    procedure UpDown2ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: SmallInt; Direction: TUpDownDirection);
    procedure UpDown3ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: SmallInt; Direction: TUpDownDirection);
  private
    curvecolor: longint;
    HelixList: TD3FloatPointList;
    LorenzObj: TLorenz;
    orbiting, ChangeLight: Boolean;
    drawCurve: procedure of object;
    lright1, lright2, ldown1, ldown2: Integer;
    ldist1, ldist2, lRightIntensity, ambient, directed: MathFloat;
    procedure helix(t: MathFloat; var x, y, z: MathFloat);
    procedure makehelix;
    procedure makeLorenz;
    procedure drawhelix1;
    procedure drawhelix2;
    procedure DrawHelix3;
    procedure DrawHelix4;
    procedure drawLorenz1;
    procedure drawLorenz2;
    procedure DrawLorenz3;
    procedure DrawLorenz4;
    procedure SetFastDrawing;
    procedure upd;
    procedure SetOriginalDrawing;
    { Private declarations }
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public declarations }
  end;

var
  SpaceCurveForm: TSpaceCurveForm;

implementation

uses MDemo1, WorldDrawing;


{$R *.DFM}

procedure TSpaceCurveForm.CreateParams(var Params: TCreateParams);
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

procedure TSpaceCurveForm.FormCreate(Sender: TObject);
begin
  curvecolor := cllime;
  makehelix;
  makeLorenz;
  drawCurve := drawhelix1;
  upd;
  ControlStyle := ControlStyle + [csOpaque];
  orbiting := False;
  lright1 := 60;
  lright2 := 15;
  ldown1 := 20;
  ldown2 := -20;
  ldist1 := 8;
  ldist2 := 8;
  lRightIntensity := 0.5;
  Randomize;
  ambient := 0.1 * UpDown2.position;
  directed := 0.1 * UpDown3.position;
end;

procedure TSpaceCurveForm.CurveButtonClick(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then
    begin
      curvecolor := Color;
      drawCurve;
    end;
end;



procedure TSpaceCurveForm.helix; {Parametric double helix formula}
var
  s, r3, xc, yc, zc, x1, y1, z1, x2, y2, X3, Y3, z3, x4, y4, z4, u, v:
    MathFloat;
begin
  s := 34 * t;
  r3 := r * 4 * t * (tmax - t) / tmax / tmax;
  xc := A * cos(t); yc := b * sin(t); zc := t; {core curve}
  x1 := -A * sin(t); y1 := b * cos(t); z1 := 1;
  x2 := -A * cos(t); y2 := -b * sin(t);
  u := sqr(xc) + sqr(yc) + 1;
  v := x1 * x2 + y1 * y2;
  X3 := x2 * u - x1 * v; {1st perp vector}
  Y3 := y2 * u - y1 * v;
  z3 := -z1 * v;
  x4 := y1 * z3 - z1 * Y3; {2nd perp vector}
  y4 := z1 * X3 - x1 * z3;
  z4 := x1 * Y3 - y1 * X3;
  u := sqrt(sqr(X3) + sqr(Y3) + sqr(z3));
  v := sqrt(sqr(x4) + sqr(y4) + sqr(z4));
  X3 := X3 / u; Y3 := Y3 / u; z3 := z3 / u; {1st normal}
  x4 := x4 / v; y4 := y4 / v; z4 := z4 / v; {2nd normal}
  x := xc + r3 * cos(s) * X3 + r3 * sin(s) * x4;
    {Core curve + spiral in normal direction}
  y := yc + r3 * cos(s) * Y3 + r3 * sin(s) * y4;
  z := zc + r3 * cos(s) * z3 + r3 * sin(s) * z4;
end;

{************************************}

procedure TSpaceCurveForm.makehelix;
var
  i: Integer; t, x, y, z: MathFloat;
begin
  HelixList := TD3FloatPointList.Create;
  for i := 0 to tmesh do
  begin
    t := tmin + i * (tmax - tmin) / tmesh;
    helix(t, x, y, z);
    HelixList.add(x, y, z);
  end;
  HelixList.PrepareIllumination;
end;


{**************************}

procedure TSpaceCurveForm.drawhelix1;
var
  savecolor: TColor; SaveWidth: Integer;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(hxmin, hymin, hzmin, hxmax, hymax, hzmax);
    savecolor := Pen.Color;
    SaveWidth := Pen.Width;
    Pen.Color := curvecolor;
    Pen.Width := 1;
    d3Polyline(HelixList);
    Pen.Color := savecolor;
    Pen.Width := SaveWidth;
  end;
end;

{*************************************}

procedure TSpaceCurveForm.drawhelix2;
var
  savecolor: TColor;
  SaveWidth: Integer;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(hxmin, hymin, hzmin, hxmax, hymax, hzmax);
    SaveWidth := Pen.Width;
    Pen.Width := 1;
    d3DrawCustomAxes(0, 0, 7, 4, 4, 11, 'x', 'y', 'z');
    savecolor := Pen.Color;
    Pen.Color := curvecolor;
    d3Polyline(HelixList);
    Pen.Color := savecolor;
    Pen.Width := SaveWidth;
  end;
end;

{*************************************}

procedure TSpaceCurveForm.DrawHelix3;
var
  savecolor: TColor;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(hxmin, hymin, hzmin, hxmax, hymax, hzmax);
    savecolor := Pen.Color;
    Pen.Color := curvecolor;
    //Pen.Width := 2;
    d3LitPolyLine(HelixList, ambient, directed, lRightIntensity, lright1, lright2, ldown1, ldown2, ldist1, ldist2, FixCheck.checked);
    Pen.Color := savecolor;
  end;
end;

{*************************************}

procedure TSpaceCurveForm.DrawHelix4;
var
  savecolor, SaveWidth: TColor;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(hxmin, hymin, hzmin, hxmax, hymax, hzmax);
    SaveWidth := Pen.Width;
    Pen.Width := 1;
    d3DrawCustomAxes(0, 0, 7, 4, 4, 11, 'x', 'y', 'z');
    savecolor := Pen.Color;
    Pen.Color := curvecolor;
    Pen.Width := SaveWidth;
    d3LitPolyLine(HelixList, ambient, directed, lRightIntensity, lright1, lright2, ldown1, ldown2, ldist1, ldist2, FixCheck.Checked);
    Pen.Color := savecolor;
  end;
end;

{***********************************}

{**************************}

procedure TSpaceCurveForm.drawLorenz1;
var
  savecolor: TColor; SaveWidth: Integer;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(lxmin, lymin, lzmin, lxmax, lymax, lzmax);
    savecolor := Pen.Color;
    SaveWidth := Pen.Width;
    Pen.Color := curvecolor;
    Pen.Width := 1;
    d3Polyline(LorenzObj.Curve);
    Pen.Color := savecolor;
    Pen.Width := SaveWidth;
  end;
end;

{*************************************}

procedure TSpaceCurveForm.drawLorenz2;
var
  savecolor: TColor;
  SaveWidth: Integer;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(lxmin, lymin, lzmin, lxmax, lymax, lzmax);
    SaveWidth := Pen.Width;
    Pen.Width := 1;
    d3DrawCustomAxes(0, 0, 7, 4, 4, 11, 'x', 'y', 'z');
    savecolor := Pen.Color;
    Pen.Color := curvecolor;
    d3Polyline(LorenzObj.Curve);
    Pen.Color := savecolor;
    Pen.Width := SaveWidth;
  end;
end;

{*************************************}

procedure TSpaceCurveForm.DrawLorenz3;
var
  savecolor: TColor;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(lxmin, lymin, lzmin, lxmax, lymax, lzmax);
    savecolor := Pen.Color;
    Pen.Color := curvecolor;
    //Pen.Width := 2;
    d3LitPolyLine(LorenzObj.Curve, ambient, directed, lRightIntensity, lright1, lright2, ldown1, ldown2, ldist1, ldist2, FixCheck.Checked);
    Pen.Color := savecolor;
  end;
end;

{*************************************}

procedure TSpaceCurveForm.DrawLorenz4;
var
  savecolor, SaveWidth: TColor;
begin
  with GraphImage do
  begin
    Clear;
    d3SetWorld(lxmin, lymin, lzmin, lxmax, lymax, lzmax);
    SaveWidth := Pen.Width;
    Pen.Width := 1;
    d3DrawCustomAxes(0, 0, 7, 4, 4, 11, 'x', 'y', 'z');
    savecolor := Pen.Color;
    Pen.Color := curvecolor;
    Pen.Width := SaveWidth;
    d3LitPolyLine(LorenzObj.Curve, ambient, directed, lRightIntensity, lright1, lright2, ldown1, ldown2, ldist1, ldist2, FixCheck.Checked);
    Pen.Color := savecolor;
  end;
end;

{***********************************}

procedure TSpaceCurveForm.InButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if GraphImage.Pen.Width > 1 then
    SetFastDrawing;
  GraphImage.d3StartZoomingIn(ZoomInc);
end;

{**********************************************}

procedure TSpaceCurveForm.InButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  SetOriginalDrawing;
  GraphImage.d3StopZooming;
end;

{****************************************}

procedure TSpaceCurveForm.OutButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if GraphImage.Pen.Width > 1 then
    SetFastDrawing;
  GraphImage.d3StartZoomingOut(ZoomInc);
end;

{*********************************}

procedure TSpaceCurveForm.UpButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if ViewpointCheck.checked then
  begin
    if GraphImage.Pen.Width > 1 then
      SetFastDrawing;
    GraphImage.d3StartRotatingUp(RotInc);
  end;
  if Light1Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if ldown1 > -88 then
            inc(ldown1, -2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
  if Light2Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if ldown2 > -88 then
            inc(ldown2, -2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
end;

{***************************}

procedure TSpaceCurveForm.UpButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  SetOriginalDrawing;
  GraphImage.d3StopRotating;
  ChangeLight := False;
end;

{***************************}

procedure TSpaceCurveForm.LeftButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if ViewpointCheck.checked then
  begin
    if GraphImage.Pen.Width > 1 then
      SetFastDrawing;
    GraphImage.d3StartRotatingLeft(RotInc);
  end;
  if Light1Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if lright1 > -88 then
            inc(lright1, -2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
  if Light2Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if lright2 > -88 then
            inc(lright2, -2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
end;

{*******************************}

procedure TSpaceCurveForm.RightButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if ViewpointCheck.checked then
  begin
    if GraphImage.Pen.Width > 1 then
      SetFastDrawing;
    GraphImage.d3StartRotatingRight(RotInc);
  end;
  if Light1Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if lright1 < 88 then
            inc(lright1, 2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
  if Light2Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if lright2 < 88 then
            inc(lright2, 2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
end;


{*********************************}

procedure TSpaceCurveForm.DownButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  if ViewpointCheck.checked then
  begin
    if GraphImage.Pen.Width > 1 then
      SetFastDrawing;
    GraphImage.d3StartRotatingDown(RotInc);
  end;
  if Light1Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if ldown1 < 88 then
            inc(ldown1, 2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
  if Light2Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if ldown2 < 88 then
            inc(ldown2, 2);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
end;

{****************************}

procedure TSpaceCurveForm.GraphImageResize(Sender: TObject);
begin
  drawCurve;
  invalidate;
end;


{*********************************}

procedure TSpaceCurveForm.MoveOutButtonMouseDown(Sender: TObject; Button:
  TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  if ViewpointCheck.checked then
  begin
    if GraphImage.Pen.Width > 1 then
      SetFastDrawing;
    GraphImage.d3StartMovingOut(MoveInc);
  end;
  if Light1Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          ldist1 := ldist1 * (1 + MoveInc);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
  if Light2Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          ldist2 := ldist2 * (1 + MoveInc);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
end;

{****************************}

procedure TSpaceCurveForm.MoveInButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
    if ViewpointCheck.checked then
    begin
    if GraphImage.Pen.Width > 1 then
      SetFastDrawing;
      GraphImage.d3StartMovingIn(MoveInc);
    end;
  if Light1Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if ldist1 > 0 then
            ldist1 := ldist1 * (1 - MoveInc);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
  if Light2Check.checked then
    if LightCheck.checked then
      if not FixCheck.checked then
      begin
        ChangeLight := True;
        while ChangeLight do
        begin
          if ldist2 > 0 then
            ldist2 := ldist2 * (1 - MoveInc);
          drawCurve;
          Application.ProcessMessages;
        end
      end;
end;

{*************************************}

procedure TSpaceCurveForm.MoveInButtonMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; x, y: Integer);
begin
  SetOriginalDrawing;
  GraphImage.d3StopMoving;
  ChangeLight := False;
end;


procedure TSpaceCurveForm.upd;
begin
  with GraphImage do
  begin
    vdshow.Caption := FloatToStrf(d3ViewDist, ffgeneral, 3, 3);
    vashow.Caption := FloatToStrf(d3ViewAngle, ffgeneral, 3, 3);
    zrshow.Caption := FloatToStrf(d3Zrotation, ffgeneral, 3, 3);
    yrshow.Caption := FloatToStrf(d3Yrotation, ffgeneral, 3, 3);
    l1yrshow.Caption := FloatToStrf(ldown1, ffgeneral, 3, 3);
    l2yrshow.Caption := FloatToStrf(ldown2, ffgeneral, 3, 3);
    l1zrshow.Caption := FloatToStrf(lright1, ffgeneral, 3, 3);
    l2zrshow.Caption := FloatToStrf(lright2, ffgeneral, 3, 3);
    l1dshow.Caption := FloatToStrf(ldist1, ffgeneral, 3, 3);
    l2dshow.Caption := FloatToStrf(ldist2, ffgeneral, 3, 3);
  end;
end;

procedure TSpaceCurveForm.FormDestroy(Sender: TObject);
begin
  HelixList.Free;
  LorenzObj.Free;
end;

{eventhandler while rotating, zooming or moving}
{compare to the one in SurfaceForm}

procedure TSpaceCurveForm.GraphimageRotating(Sender: TObject);
begin
  drawCurve;
  upd;
end;

procedure TSpaceCurveForm.GraphimageRotateStop(Sender: TObject);
begin
  drawCurve;
  upd;
end;


procedure TSpaceCurveForm.AspectcheckClick(Sender: TObject);
begin
  GraphImage.d3AspectRatio := Aspectcheck.checked;
  drawCurve;
end;

procedure TSpaceCurveForm.AxescheckClick(Sender: TObject);
begin
  SetOriginalDrawing;
  drawCurve;
end;

procedure TSpaceCurveForm.Button1Click(Sender: TObject);
var
  n, m: Integer; a1, a2: MathFloat;
begin
  n := random(10) + 1; m := random(20) + 1;
  if LightCheck.checked then a1 := 2 else a1 := 1;
  a1 := a1 * RotInc * m / sqrt(sqr(n) + sqr(m));
  a2 := n * a1 / m;
  orbiting := True;
  GraphImage.ShowHint := False;
  while orbiting do
    with GraphImage do
    begin
      d3Zrotation := d3Zrotation + a1;
      d3Yrotation := d3Yrotation + a2;
      GraphimageRotating(nil);
      Application.ProcessMessages;
    end;
  GraphImage.ShowHint := True;
end;

procedure TSpaceCurveForm.Button2Click(Sender: TObject);
begin
  orbiting := False;
end;

procedure TSpaceCurveForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not orbiting;
end;

procedure TSpaceCurveForm.FormShow(Sender: TObject);
begin
{$IFDEF WINDOWS}
  SaveasMetafile1.enabled := False;
  CheckBox1.enabled := False;
{$ENDIF}
 // DrawCurve;
end;


procedure TSpaceCurveForm.CopytoClipboard1Click(Sender: TObject);
begin
  with GraphImage do
    Clipboard.assign(Bitmap);
end;

procedure TSpaceCurveForm.SaveasMetafile1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with SaveDialog1 do
    if Execute then GraphImage.SaveMetafile(filename);
{$ENDIF}
end;

procedure TSpaceCurveForm.CheckBox1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with GraphImage do
  begin
    RecordMetafile := CheckBox1.checked;
    SaveasMetafile1.enabled := RecordMetafile;
  end;
{$ENDIF}
end;


procedure TSpaceCurveForm.SetFastDrawing;
begin
  if Axescheck.checked then
    if CurveKindGroup.ItemIndex = 0 then
      drawCurve := drawhelix2
    else
      drawCurve := drawLorenz2
  else
    if CurveKindGroup.ItemIndex = 0 then
      drawCurve := drawhelix1
    else
      drawCurve := drawLorenz1;
end;

procedure TSpaceCurveForm.SetOriginalDrawing;
begin
  if Axescheck.checked then
    if LightCheck.checked then
      if CurveKindGroup.ItemIndex = 0 then
        drawCurve := DrawHelix4
      else
        drawCurve := DrawLorenz4
    else
      if CurveKindGroup.ItemIndex = 0 then
        drawCurve := drawhelix2
      else
        drawCurve := drawLorenz2
    else
      if LightCheck.checked then
        if CurveKindGroup.ItemIndex = 0 then
          drawCurve := DrawHelix3
        else
          drawCurve := DrawLorenz3
      else
        if CurveKindGroup.ItemIndex = 0 then
          drawCurve := drawhelix1
        else
          drawCurve := drawLorenz1;
end;


procedure TSpaceCurveForm.UpDown1ChangingEx(Sender: TObject;
  var AllowChange: Boolean; NewValue: SmallInt;
  Direction: TUpDownDirection);
begin
  GraphImage.Pen.Width := NewValue;
  drawCurve;
end;



procedure TSpaceCurveForm.Trackbar1Change(Sender: TObject);
begin
  lRight1 := TrackBar1.position-30;
  lRight2:=lRight1-90;
  drawCurve;
  GraphImage.Repaint;
  upd;
end;

procedure TSpaceCurveForm.UpDown2ChangingEx(Sender: TObject;
  var AllowChange: Boolean; NewValue: SmallInt;
  Direction: TUpDownDirection);
begin
  if NewValue >= 0 then
  begin
    ambient := NewValue * 0.1;
    drawCurve;
  end;
end;

procedure TSpaceCurveForm.UpDown3ChangingEx(Sender: TObject;
  var AllowChange: Boolean; NewValue: SmallInt;
  Direction: TUpDownDirection);
begin
  if NewValue >= 0 then
  begin
    directed := NewValue * 0.1;
    drawCurve;
  end;
end;

procedure TSpaceCurveForm.makeLorenz;
begin
  LorenzObj := TLorenz.Create;
  LorenzObj.GenerateSolutionCurve(Lorenz.D3FloatPoint(1, 1, 4), 10000);
end;

end.

