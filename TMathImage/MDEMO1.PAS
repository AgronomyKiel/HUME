unit Mdemo1;

interface

uses SysUtils,
{$IFDEF WINDOWS}
  WinTypes, WinProcs,
{$ENDIF}
{$IFDEF WIN32}
  Windows,
{$ENDIF}
  Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Tabs;

type
  TDemoForm = class(TForm)
    TabSet1: TTabSet;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TabSet1Change(Sender: TObject; NewTab: Integer;
      var AllowChange: Boolean);
  private
    guest: TForm;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DemoForm: TDemoForm;

implementation
uses plane, surface, ani1, spcurv, dataplot, Light, Contour;

{$R *.DFM}

procedure TDemoForm.FormActivate(Sender: TObject);
begin
  if guest = nil then
    guest := TPlaneGraphs.create(application);
  guest.show;
end;

procedure TDemoForm.FormCreate(Sender: TObject);
begin
  guest := nil;
  controlstyle := controlstyle + [csOpaque];
  FreeLibrary(GetModuleHandle('OleAut32'));
end;

procedure TDemoForm.TabSet1Change(Sender: TObject; NewTab: Integer;
  var AllowChange: Boolean);
begin
  Allowchange := true;
  if guest <> nil then
    Allowchange := guest.CloseQuery;
  if allowchange then
  begin
    if guest <> nil then guest.free;
    case NewTab of
      0: guest := TPlaneGraphs.create(Application);
      1: guest := TAniForm.create(Application);
      2: guest := TDataPlotForm.create(Application);
      3: guest := TSpaceCurveForm.create(Application);
      4: guest := TSurfaceForm.create(Application);
      5: guest := TLitSurfaceForm.create(Application);
      6: guest := TContourForm.create(Application);
    end;
    guest.show;
  end;
end;

end.

