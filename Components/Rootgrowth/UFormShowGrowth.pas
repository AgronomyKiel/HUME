unit UFormShowGrowth;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  OverlayImage, MathImge, vcl.Buttons, vcl.ToolWin, vcl.ComCtrls, SubmodRootStructureNew,
  vcl.StdCtrls, vcl.ExtCtrls;

const
  pointColor = $00000000;          //Punktfarbe ist schwarz
  polygonColor = $00FF0000;        //Kanten des Polygons sind blau

type
//Klassen
  TFormShowGrowth = class(TForm)
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheetGrowth: TTabSheet;
    MathImageRoot: TMathImage;
    TabSheetWAPPolygon: TTabSheet;
    ToolBarFormGrowth: TToolBar;
    SpeedButtonRight: TSpeedButton;
    SpeedButtonLeftRotation: TSpeedButton;
    SpeedButtonUp: TSpeedButton;
    SpeedButtonDown: TSpeedButton;
    SpeedButtonZoomIn: TSpeedButton;
    SpeedButtonZoomOut: TSpeedButton;
    Splitter1: TSplitter;
    LblSelectHorizontPlane: TLabel;
    Splitter2: TSplitter;
    EditDepthhorizont: TEdit;
    RadPlanekind: TRadioGroup;
    MathImWAP: TMathImage;
    Splitter3: TSplitter;
    procedure SpeedButtonLeftRotationClick(Sender: TObject);
    procedure SpeedButtonLeftRotationMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButtonLeftRotationMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButtonRightClick(Sender: TObject);
    procedure SpeedButtonUpClick(Sender: TObject);
    procedure SpeedButtonDownClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    Procedure RePaintRootSystem;
    procedure SpeedButtonZoomInClick(Sender: TObject);
    procedure SpeedButtonZoomOutClick(Sender: TObject);
    procedure EditDepthhorizontChange(Sender: TObject);
    procedure RadPlanekindClick(Sender: TObject);
    procedure MathImWAPResize(Sender: TObject);
    procedure showAxes;

  private
    { Private-Deklarationen }
{ Dimensionen des Weltwürfels}
    dimX,
    dimY,
    dimZ: integer;
{ Liste mit den Segmenten, die Schnittpunkte mit der horizontalen Ebene haben.}
    SegListIntersect
    : TList;
{ Variable für die Tiefe der Ebene}
    depthPlane : double;
{ Variable für Art der Ebene }
    plane: kindplane;
{ Bitmap für die Anzeige der Voronoi-Polygone}
    BitmapVoronoi: TBitmap;
    procedure showWAP(WAPX_, WAPY_:integer);
  public
    { Public-Deklarationen }
    procedure resetLists;
    procedure setSRPList(SRPList_: TList);
    function getDepthPlane: double;
    function getPlane: kindplane;
    procedure showVoronoiPolygon;
//Set und get
    procedure setDimX(DimX_: integer);
    procedure setDimY(DimY_: integer);
    procedure setDimZ(DimZ_: integer);
    procedure setSegListWS(SegListWS: TList);
    procedure setPotSegList(PotSegList_: TList);
  end;

var
  FormShowGrowth: TFormShowGrowth;

{ Liste mit 'Pseudosegmenten' zusammengesetzt aus den pot. Verzweigungspunkten
des endständigen Segments}
  PotSegList,
//Liste enthält Listen mit Segmenten sämtlicher WS
  SegList : TList;

implementation

//uses
  //Pages_unit;

{$R *.DFM}

procedure TFormShowGrowth.RePaintRootSystem;
var
  i,j : integer;
  ActSegment  :TSegment;
  AListinAList: TList;
  APotSeg
  : TPotSeg;
begin
  self.MathImageRoot.Clear;
  MathImageRoot.Pen.Color := clred;
  MathImageRoot.d3DrawAxes('x', 'y', 'z', 10, 10, 10, 0, 0, 0, true);
  MathImageRoot.d3DrawFullWorldBox;
  For i := 0 to Seglist.Count-1 do begin
   AListinAList:=Seglist.items[i];
   for j:=0 to AListinAList.count-1 do begin

    ActSegment := AListinAList.items[j];
{In Zukunft: es werden zunächst nur Segmente gezeichnet, die kein Meristem haben oder
zwar ein Meristem besitzen und sämtliche pot. Verzweigungspunkte realisiert
wurden. Notwendig, wenn PotSegList verarbeitet wird}
    {if (ActSegment.getMeristem = nil) or ((ActSegment.getMeristem <> nil)
    and (ActSegment.getMeristem.getPointsOfRam.count=0)) then
    begin}
     If ActSegment.getInternode = 0 then
        MathImageRoot.Canvas.pen.Color := clblack;
     If ActSegment.getInternode = 1 then
        MathImageRoot.Canvas.pen.Color := clblack;
     If ActSegment.getInternode = 2 then
        MathImageRoot.Canvas.pen.Color := clblack;
     If ActSegment.getInternode = 3 then
        MathImageRoot.Canvas.pen.Color := clblack;
     If ActSegment.getInternode = 4 then
        MathImageRoot.Canvas.pen.Color := clblack;
     If ActSegment.getInternode = 5 then
        MathImageRoot.Canvas.pen.Color := clblack;
{ Erläuterung der Methode d3MoveTo (aus der TMathImage-Hilfe): Moves the
graphics cursor to the point with D3-world coordinates (x,y,z). }
 MathImageRoot.d3Moveto(ActSegment.getCo[0],
                 ActSegment.getCo[1],
                 -1*ActSegment.getCo[2]);
{ Erläuterung der Methode d3DrawLineTo (aus der TMathImage-Hilfe): Draws a line
from the current graphics cursor position (see d3Moveto) to point (x,y,z) in
D3-world coordinates. DrawLineto never draws the endpixel (Win-default). }
 MathImageRoot.d3DrawLineto( ActSegment.getCe[0],
                 ActSegment.getCe[1],
                 -1*ActSegment.getCe[2]);
   //end;
   end;
  end;
{ Zeichnen der endständigen Segmente, die noch potentielle Verzweigungspunkte be-
sitzen als Struktur, die sich aus den Verbindungen der pot. Verzweigungspunkte
zusammensetzt. Zeichnen in Rot}
  if PotSegList<> nil then
  begin
       //MathImageRoot.Canvas.pen.Width:=10; //Debugging
       MathImageRoot.Canvas.pen.Color := clred;
       for i:=0 to PotSegList.Count-1 do
       begin
            AListinAList:=PotSegList.items[i];
            for j:=0 to AListinAList.Count-1 do
            begin
                 APotSeg:=AListinAList.items[j];
                 MathImageRoot.d3Moveto(APotSeg.getCo[0],
                      APotSeg.getCo[1],
                      -1*APotSeg.getCo[2]);
                 MathImageRoot.d3DrawLineto( APotSeg.getCe[0],
                      APotSeg.getCe[1],
                      -1*APotSeg.getCe[2]);
            end;
       end;
  end;
//Anzeige der WAP in der ausgewählten Ebene:
end;


procedure TFormShowGrowth.SpeedButtonLeftRotationClick(Sender: TObject);
begin
    {MathImage1.d3StartRotatingLeft(0.01);
    application.ProcessMessages;
    MathImage1.d3StopRotating;}
    MathImageRoot.d3Zrotation := MathImageRoot.d3Zrotation+10;
    MathImageRoot.d3DrawFullWorldBox;
    MathImageRoot.Repaint;
    RePaintRootSystem;
end;


procedure TFormShowGrowth.SpeedButtonLeftRotationMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //SetOriginalDrawing;
  {MathImage1.d3StopRotating;
  MathImage1.d3DrawFullWorldBox;
  MathImage1.Repaint;  }
end;

procedure TFormShowGrowth.SpeedButtonLeftRotationMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    {MathImage1.d3StartRotatingLeft(0.01);
    application.ProcessMessages;
    MathImage1.d3DrawFullWorldBox;
    MathImage1.Repaint;

   // MathImage1.Repaint; }
end;

procedure TFormShowGrowth.SpeedButtonRightClick(Sender: TObject);
begin
    MathImageRoot.d3Zrotation := MathImageRoot.d3Zrotation-10;
    MathImageRoot.d3DrawFullWorldBox;
    MathImageRoot.Repaint;
    RePaintRootSystem;

end;

procedure TFormShowGrowth.SpeedButtonUpClick(Sender: TObject);
begin
   MathImageRoot.d3Yrotation := MathImageRoot.d3yrotation+10;
    MathImageRoot.d3DrawFullWorldBox;
    MathImageRoot.Repaint;
    RePaintRootSystem;
end;

procedure TFormShowGrowth.SpeedButtonDownClick(Sender: TObject);
begin
   MathImageRoot.d3Yrotation := MathImageRoot.d3yrotation-10;
    MathImageRoot.d3DrawFullWorldBox;
    MathImageRoot.Repaint;
    RePaintRootSystem;
end;


procedure TFormShowGrowth.FormCreate(Sender: TObject);
begin
    SegList := TList.Create;
    SegListIntersect := TList.Create;
    PotSegList:= TList.create;
{ Per Default keine horizontale Ebene vorhanden.}
    //CombSelPlane.Text:='horizontal';
    //DistributionCalculator.plane:=horizontal;
{ Auskommentierte Text: Versuch der Ausgabe von Wurzelschnittpunkte in ein Bit-
map}
{ Erzeugen des Bitmaps, das die WAP und die VoronoiPolygone aufnimmt }
    {BitmapVoronoi:= TBitmap.Create;
    BitmapVoronoi.PixelFormat:=pf24bit; //Wahrscheinlich unnötig
    BitmapVoronoi.Width:=ImageVoronoi.Width;
    BitmapVoronoi.Height:=ImageVoronoi.Height;
    ImageVoronoi.Picture.Assign(BitmapVoronoi);}
end;

procedure TFormShowGrowth.SpeedButtonZoomInClick(Sender: TObject);
begin
   MathImageRoot.d3ViewDist := MathImageRoot.d3ViewDist*0.9;
    MathImageRoot.d3DrawFullWorldBox;
    MathImageRoot.Repaint;
    RePaintRootSystem;

end;

procedure TFormShowGrowth.SpeedButtonZoomOutClick(Sender: TObject);
begin
    MathImageRoot.d3ViewDist := MathImageRoot.d3ViewDist/0.9;
    MathImageRoot.d3DrawFullWorldBox;
    MathImageRoot.Repaint;
    RePaintRootSystem;
end;


procedure TFormShowGrowth.showVoronoiPolygon;
(*------------------------------------------------------------------------------
ZUGEHÖRIGE KLASSE: TFormShowGrowth
BESCHREIBUNG: Zeichnet die Schnittpunkte mit der horizontalen Ebene in das
Bitmap, später sollen hier auch noch die VoronoiPolygone dargestellt werden.
------------------------------------------------------------------------------*)
var
   //IntersectionListCM : TList;
   A_SRP : TSRP;
   WAP_x, WAP_y: double;
   i:integer;
begin
{ Festlegen der Zeichnungsfläche in Abhängigkeit von den Dimensionen der unter-
suchten Schicht}
   //BitmapVoronoi.Width:=DistributionCalculator.getDim_x;
   //BitmapVoronoi.Height:=DistributionCalculator.getDim_y;
   try
//Löschen der alten Einträge in MathImWAP
      MathImWAP.Pen.Color:=clblack;
      MathImWAP.Clear;
//Zeichnen der Achsen
      showAxes;
//Für alle Einträge in der Liste
      for i:=0 to SegListIntersect.count-1 do
      begin
          A_SRP:=SegListIntersect.Items[i];
          WAP_x:=A_SRP.x;
{ Z-Achse negativ, deshalb muss bei vertikalem Schnitt der 'Y-Wert' (eigentlich
Wert der Z-Achse) negativiert werden.}
     if plane = vertikal then
     begin
          WAP_y:=-A_SRP.y;
     end
     else
         WAP_y:=A_SRP.y;
//Zeichnen der WAP in Bitmap
          //showWAP(WAP_x, WAP_y);
//Zeichnen der WAP in MathImWAP
          MathImWAP.Pen.Color:=clblack;
          MathImWAP.DrawPoint(WAP_x, WAP_y);
     end;
   finally
     //Dispose(AIntersectionRootGrid);
     //IntersectionList.Free;
   end;
end;

procedure TFormShowGrowth.showWAP(WAPX_, WAPY_: integer);
{ Anzeigen von Wurzelaustrittspunkten, Die direkten Nachbarn der übergebenen
Koordinaten werden ebenfalls mit pointColor übermalt: Dies ist natürlich
auflösungsabhängig.}
begin
//Auskommentiert wurde der Versuch der Ausgabe in ein Bitmpa
     //ImageVoronoi.Picture.Bitmap.Canvas.Pixels[WAPX_,WAPY_]:=pointColor;
end;//TFormShowGrowth.showWAP

function TFormShowGrowth.getDepthPlane: double;
begin
     Result:=depthPlane;
end;

procedure TFormShowGrowth.EditDepthhorizontChange(Sender: TObject);
var
   x,y: integer;
begin
//Wenn eine Tiefe ausgewählt wurde:
   //if self.EditDepthhorizont.Text <> '0' then
//Fehlerhafte Benutzereingabe wird abgefangen
     try
       depthPlane:=StrToFloat(EditDepthhorizont.Text);
     except
//Zugriff auf Exception-Objekt
        on EConvertError do begin
//Falls EditDepthhorizont leer ist:
          if EditDepthhorizont.Text='' then
//nichts machen
          else
          begin
             ShowMessage('Zahleneingabe erwartet');
          end;
        end;
     end;
end; 


procedure TFormShowGrowth.RadPlanekindClick(Sender: TObject);
begin
     if RadPlanekind.ItemIndex=0 then
     begin
          plane:=horizontal;
     end;
     if RadPlanekind.ItemIndex=1 then
     begin
          plane:=vertikal;
     end;
end;

procedure TFormShowGrowth.MathImWAPResize(Sender: TObject);
begin
    MathImWAP.Clear;
    MathImWAP.DrawAxes('[cm]','[cm]', true, clblack, clblack, true);
end;

procedure TFormShowGrowth.setSRPList(SRPList_: TList);
begin
     SegListIntersect:=SRPList_;
end;

function TFormShowGrowth.getPlane: kindplane;
begin
     Result:= plane;
end;

procedure TFormShowGrowth.showAxes;
begin
//bei horizontaler Ebene wird normales Achsenkreuz gezeichnet
    if plane = horizontal then
    begin
    MathImWAP.setWorld(0,0,dimx,dimy);
    MathImWAP.DrawAxes('[cm]','[cm]', true, clblack, clblack, true);
    end;
    if plane = vertikal then
    begin
//bei vertikaler Ebene wird das Achsenkreuz umgedreht
    MathImWAP.setWorld(0,-dimy,dimx,0);
    MathImWAP.DrawAxes('[cm]','[cm]', true, clblack, clblack, false);
    end;
end;

procedure TFormShowGrowth.resetLists;
{ Falls die Listen nicht leer sind, werden die Einträge gelöscht, die Objekte
der Listen werden vom Submodell selbst gelöscht. }
begin
     SegList.clear;
     PotSegList.clear;
     SegListIntersect.clear;
end;

procedure TFormShowGrowth.setDimX(DimX_: integer);
begin
     self.dimX:=DimX_;
end;

procedure TFormShowGrowth.setDimY(DimY_: integer);
begin
     self.dimY:=DimY_;
end;

procedure TFormShowGrowth.setDimZ(DimZ_: integer);
begin
     self.dimZ:=DimZ_;
end;

procedure TFormShowGrowth.setSegListWS(SegListWS: TList);
begin
     SegList:=SegListWS;
end;

procedure TFormShowGrowth.setPotSegList(PotSegList_: TList);
begin
     PotSegList:=PotSegList_;
end;


end.
(*------------------------------------------------------------------------------
ZUGEHÖRIGE KLASSE:
BESCHREIBUNG:
------------------------------------------------------------------------------*)

(*------------------------------------------------------------------------------

------------------------------------------------------------------------------*)
