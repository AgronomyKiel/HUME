unit UVisualization;

interface

uses
  Windows, Messages, vcl.Controls, Classes, vcl.Graphics, Math, SysUtils, vcl.comctrls, vcl.ExtCtrls,
  vcl.Dialogs;

procedure ZeichnePfeil(Can: TCanvas; Col: TColor; SLange, Beta: Byte;
  Filled: Boolean; P1, P2: TPoint; style: TPenStyle);
function DoLinesIntersect(L1P1, L1P2, L2P1, L2P2: TPoint; var ptIntersection:
  TPoint): boolean;
function DoLineRectIntersect(L1P1, L1P2, RectP1, RectP2, RectP3, RectP4: TPoint;
  var ptIntersection: TPoint): boolean;
procedure rectPoints(rect: TGraphicControl; var p1: TPoint;
  var p2: TPoint; var p3:TPoint; var p4: TPoint);
procedure drawArrow(can: TCanvas; x, y: TPoint; color: TColor; style: TPenStyle); overload;
procedure drawArrow(can: TCanvas;gc1,gc2: TGraphicControl;color: TColor; style: TPenstyle);  overload;
procedure startendpoint(gc1,gc2: TGraphicControl; var pstart: TPoint; var pend: TPoint);
procedure drawLine(can: TCanvas;gc1,gc2: TGraphicControl;color: TColor; style: TPenstyle);

implementation

procedure drawArrow(can: TCanvas; x, y: TPoint; color: TColor; style: TPenStyle);
begin
  ZeichnePfeil(can, color, 10, 50, TRUE, x, y, style);
end;

procedure ZeichnePfeil(Can: TCanvas; Col: TColor; SLange, Beta: Byte;
  Filled: Boolean; P1, P2: TPoint; style: TPenStyle);
// created by Christof Urbaczek
// http://www.swissdelphicenter.ch/de/showcode.php?id=2256
  function GetDEG(Winkel: double): double; // Winkel ins Gradmaß
  begin
    Result := (Winkel * 2 * Pi) / 360;
  end;

  function GetRAD(Winkel: double): double; // Winkel im Winkelmaß
  begin
    Result := (Winkel * 360) / (2 * Pi);
  end;

var
  Punkte: array[0..2] of TPoint; // Array für die Punkte der Pfeilspitze
  Alpha, AlphaZ: double; // Winkel zur horizontalen Achse durch P1

begin
  //Farben einstellen
  Can.Brush.Color := Col;
  Can.Pen.Color := Col;

  //Linie zeichnen
  Can.Pen.Style := style;

  Can.MoveTo(P1.X, P1.Y);
  Can.LineTo(P2.X, P2.Y);



  //Pfeilspitze (1.Punkt)
  Punkte[0].X := P2.X;
  Punkte[0].Y := P2.Y;

  //Winkel ermitteln
  Alpha := 0;
  if P2.X = P1.X then
    AlphaZ := 0
  else
    AlphaZ := GetRAD(ArcTan((P2.Y - P1.Y) / (P2.X - P1.X)));

  if (P2.X > P1.X) and (P2.Y = P1.Y) then Alpha := 0
  else if (P2.X > P1.X) and (P2.Y < P1.Y) then Alpha := 0 - AlphaZ
  else if (P2.X = P1.X) and (P2.Y < P1.Y) then Alpha := 90
  else if (P2.X < P1.X) and (P2.Y < P1.Y) then Alpha := 180 - AlphaZ
  else if (P2.X < P1.X) and (P2.Y = P1.Y) then Alpha := 180
  else if (P2.X < P1.X) and (P2.Y > P1.Y) then Alpha := 180 - AlphaZ
  else if (P2.X = P1.X) and (P2.Y > P1.Y) then Alpha := 270
  else if (P2.X > P1.X) and (P2.Y > P1.Y) then Alpha := 360 - AlphaZ;
  //2.Punkt
  Punkte[1].X := round(P2.X - sLange * cos(GetDEG(Alpha - Beta div 2)));
  Punkte[1].Y := round(P2.Y + sLange * sin(GetDEG(Alpha - Beta div 2)));
  //3.Punkt
  Punkte[2].X := round(P2.X - sLange * cos(GetDEG(Alpha + Beta div 2)));
  Punkte[2].Y := round(P2.Y + sLange * sin(GetDEG(Alpha + Beta div 2)));
  //Pfeil zeichnen
  if Filled then Can.Polygon(Punkte) else begin
    Can.MoveTo(Punkte[0].X, Punkte[0].Y);
    Can.LineTo(Punkte[1].X, Punkte[1].Y);
    Can.MoveTo(Punkte[0].X, Punkte[0].Y);
    Can.LineTo(Punkte[2].X, Punkte[2].Y);
  end;
end;


// Quelle: http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/Helpers.cs
function DoLinesIntersect(L1P1, L1P2, L2P1, L2P2: TPoint; var ptIntersection:
  TPoint): boolean;
var
  d, n_a, n_b, ua, ub: double;
begin
  // Denominator for ua and ub are the same, so store this calculation
  d := (L2P2.Y - L2P1.Y) * (L1P2.X - L1P1.X) - (L2P2.X - L2P1.X) * (L1P2.Y -
    L1P1.Y);
  //n_a and n_b are calculated as seperate values for readability
  n_a := (L2P2.X - L2P1.X) * (L1P1.Y - L2P1.Y) - (L2P2.Y - L2P1.Y) * (L1P1.X -
    L2P1.X);
  n_b := (L1P2.X - L1P1.X) * (L1P1.Y - L2P1.Y) - (L1P2.Y - L1P1.Y) * (L1P1.X -
    L2P1.X);
  // Make sure there is not a division by zero - this also indicates that
  // the lines are parallel.
  if (d = 0) then begin
    result := false;
  end else begin
    // Calculate the intermediate fractional point that the lines potentially intersect.
    ua := n_a / d;
    ub := n_b / d;
    // The fractional point will be between 0 and 1 inclusive if the lines
    // intersect.  If the fractional calculation is larger than 1 or smaller
    // than 0 the lines would need to be longer to intersect.
    if ((ua >= 0) and (ua <= 1) and (ub >= 0) and (ub <= 1)) then begin
      ptIntersection.X := math.Floor(L1P1.X + (ua * (L1P2.X - L1P1.X)));
      ptIntersection.Y := math.Floor(L1P1.Y + (ua * (L1P2.Y - L1P1.Y)));
      result := true;
    end else begin
      result := false;
    end;
  end;
end;

function DoLineRectIntersect(L1P1, L1P2, RectP1, RectP2, RectP3, RectP4: TPoint; var ptIntersection:
  TPoint): boolean;
begin
  if DoLinesIntersect(L1P1, L1P2, RectP1, RectP2, ptIntersection) or
     DoLinesIntersect(L1P1, L1P2, RectP2, RectP3, ptIntersection) or
     DoLinesIntersect(L1P1, L1P2, RectP3, RectP4, ptIntersection) or
     DoLinesIntersect(L1P1, L1P2, RectP4, RectP1, ptIntersection) then
     result := True
  else
    result := False;
end;

procedure rectPoints(rect: TGraphicControl; var p1: TPoint;
  var p2: TPoint; var p3:TPoint; var p4: TPoint);
begin
  p1 := Point(rect.Left,rect.Top + rect.Height);
  p2 := Point(rect.Left, rect.Top);
  p3 := Point(rect.Left + rect.Width, rect.Top);
  p4 := Point(rect.Left + rect.Width, rect.Top + rect.Height);
end;

procedure startendpoint(gc1,gc2: TGraphicControl; var pstart: TPoint; var pend: TPoint);
var p1,p2,rectp1,rectp2,rectp3,rectp4: TPoint;
begin
   p1 := Point(math.Floor(gc1.left + gc1.width / 2),
          math.Floor(gc1.top + gc1.height / 2));
   p2 := Point(math.Floor(gc2.left + gc2.width / 2),
          math.Floor(gc2.top + gc2.height / 2));
   rectPoints(gc1,rectp1,rectp2,rectp3,rectp4);
   DoLineRectIntersect(p1,p2,rectp1,rectp2,rectp3,rectp4,pstart);
   rectPoints(gc2,rectp1,rectp2,rectp3,rectp4);
   DoLineRectIntersect(p1,p2,rectp1,rectp2,rectp3,rectp4,pend);
end;


procedure drawArrow(can: TCanvas;gc1,gc2: TGraphicControl;color: TColor; style: TPenstyle); overload
var pstart, pend: TPoint;
begin
   startendpoint(gc1,gc2, pstart, pend);
   drawArrow(can,pstart,pend,color,style);
end;

procedure drawLine(can: TCanvas;gc1,gc2: TGraphicControl;color: TColor; style: TPenstyle);
var pstart, pend: TPoint;
begin
  startendpoint(gc1,gc2, pstart, pend);
  Can.Brush.Color := color;
  Can.Pen.Color := Color;
  can.Pen.Width := 1;
  Can.Pen.Style := style;
  can.brush.style:=bsclear;
  Can.MoveTo(pstart.X, pstart.Y);
  Can.LineTo(pend.X, pend.Y);
end;

end.

