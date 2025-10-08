
constructor TGPoint.Create(x_,y_:extended;L:TList;C:TCanvas);
begin
  x:=x_;
  y:=y_;
  inherited Create(L,C);
  Color.Color:=$00FFFFFF;
  closeDist:=2;
end;

//------------------------------------------------------------------

function   TGPoint.Clone:TGraphObject;
var a:TGPoint;
begin
  a:=TGPoint.Create(x,y,nil,getCanvas);
  a.orig_index:=getOrigIndex;
  result:=a;
end;


//------------------------------------------------------------------

procedure   TGPoint.draw;
begin
  getcanvas.pixels[round(x),round(y)]:=color.Color;
end;

//------------------------------------------------------------------

procedure   TGPoint.clear;
begin
end;

//------------------------------------------------------------------

function    TGPoint.getX:extended;
begin
  result:=x;
end;

//------------------------------------------------------------------

function    TGPoint.getY:extended;
begin
  result:=y;
end;

//------------------------------------------------------------------

function    TGPoint.DistanceTo(p:TGPoint):extended;
begin
  result:=sqrt((p.x-x)*(p.x-x)+(p.y-y)*(p.y-y));
end;

//------------------------------------------------------------------

function    TGPoint.DistanceTo(x_,y_:extended):extended;
begin
  result:=sqrt((x_-x)*(x_-x)+(y_-y)*(y_-y));
end;

//------------------------------------------------------------------

procedure   TGPoint.MoveTo(x_,y_:extended);
begin
  x:=x_;
  y:=y_;
end;

//------------------------------------------------------------------

function    TGPoint.Match(p:TGPoint):boolean;
begin
  result:= (DistanceTo(p) <= CloseDist);
end;

//------------------------------------------------------------------

function    TGPoint.Match(x_,y_:extended):boolean;
begin
  result:= (DistanceTo(x_,y_) <= CloseDist);
end;

//------------------------------------------------------------------

function    TGPoint.Angle(p:TGPoint):extended;   // required for building the convex hull
begin
  result:=arcsin((p.x-x)/distanceto(p));
  if (p.x>=x) and (p.y>=y) then
      else
  if (p.x>=x) and (p.y<y) then
     result:=pi-result else
  if (p.x<x) and (p.y>=y) then
     result:=(pi+pi)+result else
  if (p.x<x) and (p.y<y) then
     result:=pi-result;

end;

//------------------------------------------------------------------

function    TGPoint.IsRightTurn(p1,p2:TGPoint):boolean;  // required for Graham scan
var a1,a2:extended;
begin

  a1:=angle(p1);
  a2:=angle(p2);
  a1:=a1-a2;
  if a1<0 then a1:=2*pi+a1;
  if a1>pi then result:=true else result:=false;
end;

//------------------------------------------------------------------

function    TGPoint.areCollinear(a,b:TGPoint):boolean;
begin
 result:= ((b.y-a.y)*(x-a.x)-(b.x-a.x)*(y-a.y))=0;
end;

function TGPoint.Bisector(p:TGPoint):TGLine;
begin
end;

end.






