{----------------------------------------------------------------------

  URL Label - very simple component, that lets you run URL or file
  by clicking on it. See UrlLabel.txt for more details and note about
  internet shortcuts mailto, ftp, http etc.

  Freeware - Ahto Tanner, Moon Software (http://www.estpak.ee/~ahto/moon/)

  Tip: To specify subject in mailto URL use the following syntax:
   - TUrlLabel1.URL:= 'mailto:moon@kagi.com?subject=Your subject';

  Version 1.5, March 19, 1997
   - Well, I and you all are blind enough or you just trust me too much?
     Over 5 months of using I noticed that popup menu created on
     startup never freed. Now it is :)
   - Application.Handle in ShellExecute replaced with GetDesktopWindow(),
     since it's probably better for launching new apps.

  Version 1.4, Nov 28, 1996
   - Added ActiveColor property. Caption changes it's color to
     the ActiveColor while mouse button is down (while clicked) like
     in some web browsers. If you don't want to change color, assign
     the same color to it as normal caption font color.
   - Initially caption is blue and underlined now.

  Version 1.3, Oct 20, 1996
   - added "Copy" popup menu

  Versions 1.1, 1.2
   - nothing special ;-)

  Version 1.0, June 21, 1996
   - initial release

-----------------------------------------------------------------------}

unit UrlLabel;

interface

uses
  Windows, SysUtils, Classes, VCL.Forms, VCL.StdCtrls, ShellAPI, VCL.Menus,
  VCL.Clipbrd, VCL.Controls, VCL.Graphics;

const
  crHand = 5;

type
  TUrlLabel = class(TLabel)

  private
    FURL: string;
    FOrigFontColor, FActiveColor: TColor;
    Menu: TPopupMenu;
    MenuItem: TMenuItem;
    procedure OnMenuClick(Sender: TObject);

  protected

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

  published
    property URL: string read FURL write FURL;
    property ActiveColor: TColor read FActiveColor write FActiveColor default clPurple;

end;

 procedure Register;

implementation

{$R UrlLabel.res} // link "hand" cursor resource

{---------------------------------------------------------------------------}

constructor TUrlLabel.Create( AOwner : TComponent );
begin
   inherited Create(AOwner);
   Screen.Cursors[crHand] := LoadCursor(HInstance, PChar('HAND'));
   Cursor := crHand;
   FActiveColor := clPurple;
   with Font do begin
      Color := clBlue;
      Style := [fsUnderline];
   end;
   Menu := TPopupMenu.Create(Self);
   MenuItem := TMenuItem.Create(Menu);
   with MenuItem do begin
      Caption := 'Copy';
      OnClick := OnMenuClick;
   end;
   Menu.Items.Add(MenuItem);
   PopupMenu := Menu;
end;

{---------------------------------------------------------------------------}

procedure TUrlLabel.Click;
var
   TempURL: string;
begin
   inherited Click;

   if Trim(FURL) = '' then
      TempURL := Caption
   else
      TempUrl := FURL;
      
   if Trim(TempURL) <> '' then
      ShellExecute(GetDesktopWindow(), 'open', PChar(TempURL), nil, nil, SW_SHOWNORMAL);
end;

{---------------------------------------------------------------------------}

procedure TUrlLabel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if Button = mbLeft then begin
      FOrigFontColor := Font.Color;
      Font.Color := FActiveColor;
   end;
   inherited;
end;

{---------------------------------------------------------------------------}

procedure TUrlLabel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if Button = mbLeft then
      Font.Color := FOrigFontColor;
   inherited;
end;
{---------------------------------------------------------------------------}

procedure TUrlLabel.OnMenuClick;
begin
   Clipboard.AsText := Caption;
end;

{---------------------------------------------------------------------------}

destructor TUrlLabel.Destroy;
begin
   Menu.Free;
   inherited;
end;

{---------------------------------------------------------------------------}

procedure Register;
begin
  RegisterComponents('HUME', [TUrlLabel]);
end;


{---------------------------------------------------------------------------}

end.
