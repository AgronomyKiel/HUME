unit Ani1;
{Demo on how to use DrawPolyline, to display curves
 (relatively) fast, and how to make the lists which these routines
 take as parameters.}

interface

uses
{$IFDEF WINDOWS}
  WinProcs, WinTypes,
{$ENDIF}
{$IFDEF WIN32}
  Windows,
{$ENDIF}Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Menus, Clipbrd, MathImge, OverlayImage;

type
  TAniForm = class(TForm)
    ColorDialog1: TColorDialog;
    Panel1: TPanel;
    Button2: TButton;
    Button1: TButton;
    Button3: TButton;
    Button7: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Panel2: TPanel;
    ScrollBox1: TScrollbox;
    NoAlignButton: TRadioButton;
    AlignClientButton: TRadioButton;
    CheckBox1: TCheckBox;
    MathImage1: TMathImage;
    SaveDialog1: TSaveDialog;
    PopupMenu1: TPopupMenu;
    SaveasMetafile1: TMenuItem;
    CheckBox2: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure NoAlignButtonClick(Sender: TObject);
    procedure MathImage1Resize(Sender: TObject);
    procedure SaveasMetafile1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    Pointslist: TFloatPointListList;
    wait: Boolean;
    DrawColor, BackColor, axiscolor: TColor;
    procedure MakeSpiral(A: MathFloat; var p: TFloatPointlist);
    procedure MakeSpirals;
    { Public declarations }
  end;

implementation

uses MDemo1;

{$R *.DFM}

procedure TAniForm.CreateParams(var Params: TCreateParams);
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

function dist(x: MathFloat): MathFloat;
begin
  Result := 2 - 0.1 * x;
end;

{Make pointlist to draw one spiral}

procedure TAniForm.MakeSpiral(A: MathFloat; var p: TFloatPointlist);
var
  theta, dtheta, r: MathFloat;
begin
  p := TFloatPointlist.Create;
  dtheta := 2 / 150 * pi;
  theta := 0;
  repeat
    r := dist(A * theta);
    p.add(r * cos(theta), r * sin(theta));
    theta := theta + dtheta;
  until r < 0.02;
end;

{Make a listlist for all spirals in the animation}

procedure TAniForm.MakeSpirals;
var
  theta, dtheta, A, r: MathFloat; i: Integer;
begin
  if Pointslist <> nil then Pointslist.Free;
  Pointslist := TFloatPointListList.Create;
  dtheta := 2 / 150 * pi;
  for i := 0 to 178 do {178 frames = 178 Polylines}
  begin
    Pointslist.add;
    //start a new list
    A := 1 - 1 / 200 * i;
    theta := 0;
    repeat
      r := dist(A * theta);
      Pointslist.AddToCurrent(r * cos(theta), r * sin(theta));
      //add this point to the current list
      theta := theta + dtheta;
    until r < 0.02;
  end;
end;


procedure TAniForm.FormCreate(Sender: TObject);
begin
  Pointslist := nil;
  DrawColor := clYellow; BackColor := clMaroon;
  axiscolor := clSilver;
  MathImage1.d2Axes := True;
  ControlStyle := ControlStyle + [csOpaque];
  with ScrollBox1 do
    ControlStyle := ControlStyle + [csOpaque];
end;

procedure TAniForm.Button1Click(Sender: TObject);
//this way of drawing the spirals creates and fills a
//TFloatPointList with points for each frame.
//The canvas's pen mode is XOR, so drawing a
//polyline over itself erases it.
var
  i: Integer;
  p1, p2: TFloatPointlist;
begin
  Screen.Cursor := crHourGlass;
  with MathImage1 do
  begin
    Canvas.Pen.mode := pmXOR;
    MakeSpiral(1, p1);
    DrawPolyline(p1);
    Application.ProcessMessages;
    for i := 1 to 178 do
    begin
      p2 := p1;
      //p2 points to same as p1
      MakeSpiral(1 - 1 / 200 * i, p1);
      //this creates p1, see makespiral
      LockUpdate;
      DrawPolyline(p2);
      //erase old
      DrawPolyline(p1);
      //draw new
      UnlockUpdate;
      Application.ProcessMessages;
      p2.Free;
      //free old list
    end;
    p1.Free;
    Canvas.Pen.mode := pmcopy;
  end;
  Screen.Cursor := crDefault;
end;

procedure TAniForm.Button2Click(Sender: TObject);
begin
  with MathImage1 do
  begin
    Brush.Color := BackColor;
    Font.Color := axiscolor;
    Pen.Color := DrawColor;
    Clear;
    DrawAxes('', '', False, axiscolor, axiscolor, False);
  end;
end;

procedure TAniForm.Button3Click(Sender: TObject);
//this way of drawing the spirals creates and fills a
//TFloatPointList with points for each frame. But XORing is
//not used to achieve the animation, rather the pen mode is
//pmCopy and the picture is being erased at each step
//prior to drawing the next polyline. Besides being as fast
//as XOR, this shows the actual color picked for the graph.
var
  i: Integer;
  p: TFloatPointList;
begin
  Screen.Cursor := crHourGlass;
  with MathImage1 do
  begin
    for i := 0 to 178 do
    begin
      MakeSpiral(1 - 1 / 200 * i, p);
      LockUpdate;
      ClearClipped;
      //Only erase area inside of axes
      DrawPolyline(p);
      UnlockUpdate;
      Application.ProcessMessages;
      //to see the animation
      p.Free;
    end;
    MakeSpiral(1 - 178 / 200, p);
    Clear;
    DrawAxes('', '', False, axiscolor, axiscolor, False);
    DrawPolyline(p);
    Application.ProcessMessages;
    p.Free;
  end;
  Screen.Cursor := crDefault;
end;

procedure TAniForm.Button4Click(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then
    begin
      BackColor := Color;
      Button2Click(self);
    end;
end;



procedure TAniForm.Button5Click(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then
    begin
      DrawColor := Color;
      Button2Click(self);
    end;
end;

procedure TAniForm.Button6Click(Sender: TObject);
begin
  with ColorDialog1 do
    if Execute then
    begin
      axiscolor := Color;
      Button2Click(self);
    end;
end;

procedure TAniForm.Button7Click(Sender: TObject);
//This is the most economic way of repeated drawing of the spirals.
//All FloatPointLists for the animation frames are only
//created and filled once. To store the list of lists,
//a TFloatPointListList object is used.
var
  i: integer;
begin
  Screen.Cursor := crHourGlass;
  with MathImage1 do
  begin
    Clear;
    DrawAxes('', '', False, axiscolor, axiscolor, False);
    if Pointslist = nil then MakeSpirals;
    for i := 0 to Pointslist.Count - 1 do
    begin
      LockUpdate;
      ClearClipped;
      DrawPolyline(Pointslist.Lists[i]);
      UnlockUpdate;
      Application.ProcessMessages;
    end;
    Clear;
    DrawAxes('', '', False, axiscolor, axiscolor, False);
    DrawPolyline(Pointslist.Lists[Pointslist.Count - 1]);
  end;
  Screen.Cursor := crDefault;
end;

procedure TAniForm.FormDestroy(Sender: TObject);
begin
  if Pointslist <> nil then Pointslist.Free;
end;

procedure TAniForm.FormShow(Sender: TObject);
begin
{$IFDEF WINDOWS}
  SaveasMetafile1.enabled := False;
  CheckBox2.enabled := False;
{$ENDIF}
  Button2Click(self);
end;

procedure TAniForm.NoAlignButtonClick(Sender: TObject);
begin
  with MathImage1 do
    if NoAlignButton.checked then
    begin
      Align := alnone;
    end
    else
    begin
      Align := alClient;
    end;
end;

procedure TAniForm.MathImage1Resize(Sender: TObject);
begin
  if CheckBox1.checked then
    Button7Click(self)
  else FormShow(self);
end;

procedure TAniForm.SaveasMetafile1Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with SaveDialog1 do
    if Execute then
      MathImage1.SaveMetafile(filename);
{$ENDIF}
end;

procedure TAniForm.CheckBox2Click(Sender: TObject);
begin
{$IFDEF WIN32}
  with MathImage1 do
  begin
    RecordMetafile := CheckBox2.checked;
    SaveasMetafile1.enabled := RecordMetafile;
  end;
{$ENDIF}
end;




end.

