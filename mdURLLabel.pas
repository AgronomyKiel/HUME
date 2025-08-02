// ..................................................................
//
//                          mdURLLabel
//
//              © Copyright 1997 by Martin Djernæs
//
// ..................................................................
// 25 May 1997 - MD : Initial Date
// 26 May 1997 - MD : Version 1.0
// 28 May 1997 - MD : + support for mailto
//   (note : It can not detect if a mailto device is available)
//                    % resource file extension changed to crs
//                      (Cursor ReSource) while my Delphi kept
//                      filling a MAINICON in to my resource file
//                      while making a dll.
//  3 June 1997 - MD : + Detects now if MAPI is installed on the
//                       computer (used for mailto commands)
//                     + The Caption property is made public
//                       (read only)
//                     + Check of URL type ("@" = e-mail
//                                          "/" = web link)
//                     + Ignore mailto: and http:// prefixes written
//                       in the URL property
//  4 June 1997 - MD : Version 1.1
// 13 June 1997 - MD : % Two exits is removed from the
//                     "GetProgramPathFromExt", they was
//                     unneccessary - (thanks Maurice Valmont)
// 15 June 1997 - MD : % Use of PChar and StrAlloc is substituted
//                     with use of AnsiString (makes things easier
//                     to read) - (thanks Maurice Valmont)
//  5 November 1997 - MD : % Caption is made read/write
//                         + URLAsHint offer the option of getting
//                           a hint containing the URL propery, as hint
//                           so behaviour like most browsers can be made
//                         + Function GetURLCaption offered to get the
//                           wanted URL (incl/excl the prefix).
// 5 November 1997 - MD : Version 1.2
// ..................................................................

unit mdURLLabel;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.StdCtrls, ShellAPI, Registry;

Const
  crURLCursor = 8888;
  defURL = 'www.homepage.my';
  defMailto = 'person@server.dom';

type
  TmdLabelType = (Auto, Passive, Link);
  TmdLinkType = (http, mailto);
  TmdURLLabel = class(TCustomLabel)
  private
    { Private declarations }
    FLinkFont : TFont;
    FPassiveFont : TFont;
    FURLCursor : TCursor;
    FURL : String;
    FURLCaption : TCaption;
    FShowPrefix : Boolean;
    FCaptionChanged : Boolean;
    FLabelType : TmdLabelType;
    FLinkType : TmdLinkType;
    FLinkAble : Boolean;
    FURLAsHint : Boolean;
    Procedure SetLinkFont(Value : TFont);
    Procedure SetPassiveFont(Value : TFont);
    Procedure SetURL(Value : String);
    Procedure SetShowPrefix(Value : Boolean);
    Procedure SetLabelType(Value : TmdLabelType);
    Procedure SetLinkType(Value : TmdLinkType);
    Procedure SetURLCaption(Value : TCaption);
    Function GetCaption : TCaption;
    Procedure SetCaption(Value : TCaption);
    Procedure SetURLAsHint(Value : Boolean);
    Procedure SetHint(Value : TCaption);
    Function GetHint : TCaption;
  protected
    { Protected declarations }
    Procedure SetAFont(AFont, AValue : TFont);
    Procedure CheckLinkAble;
    Procedure SetViewFont;
    Procedure SetTheCaption;
    Procedure UpdateHint;
    Procedure Click; Override;
  public
    { Public declarations }
    Constructor Create(AOwner : TComponent); Override;
    Destructor Destroy; Override;
    Property LinkAble : Boolean Read FLinkAble;
    Property URLCaption : TCaption Read FURLCaption;
  published
    { Published declarations - Inherited }
    property ShowHint;
    property Transparent;
    property Color;
    property Align;
    property Alignment;
    property AutoSize;
    property Enabled;
    property ParentShowHint;
    property PopupMenu;
    property Visible;
    property WordWrap;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    { Published declarations }

    Property LinkFont : TFont Read FLinkFont Write SetLinkFont;
    Property PassiveFont : TFont Read FPassiveFont Write SetPassiveFont;

    Property Caption Read GetCaption Write SetCaption;
    Property URL : String Read FURL Write SetURL;
    Property URLAsHint : Boolean Read FURLAsHint Write SetURLAsHint;
    Property ShowPrefix : Boolean Read FShowPrefix Write SetShowPrefix;

    Property LabelType : TmdLabelType Read FLabelType Write SetLabelType;
    Property LinkType : TmdLinkType Read FLinkType Write SetLinkType;
  end;

procedure Register;

Function GetProgramPathFromExt(Const Ext : String) : String;

implementation

Uses
  MAPI;

{$R mdURLLabel.crs}  // Cursor ReSource (URL Cursor)

// Pick a program from the registry associated with a extension
Function GetProgramPathFromExt(Const Ext : String) : String;
Var
  S : String;
Begin
  Result := '';
  With TRegistry.Create do
  Try
    RootKey := HKEY_CLASSES_ROOT;

    If OpenKey('\'+Ext,False) Then
    Begin
      S := ReadString('');
      If S <> '' Then
      Begin
        If OpenKey('\'+S+'\shell\open\command',False) Then
        Begin
          S := ReadString('');
          If S <> '' Then
            Result := S;
        end;
      end
      else
      Begin
        If OpenKey('\'+Ext+'\shell\open\command',False) Then
        Begin
          S := ReadString('');
          If S <> '' Then
            Result := S;
        end;
      end;
    end;
  Finally
    Free;
  end;
end;

Constructor TmdURLLabel.Create(AOwner : TComponent);
Begin
  Inherited Create(AOwner);
  Screen.Cursors[crURLCursor] := LoadCursor(HInstance,PChar(8888));
  CheckLinkAble;

  // Default link font is normal font but
  //   in blue, and underlined
  FLinkFont := TFont.Create;
  FLinkFont.Assign(Font);
  FLinkFont.Color := clBlue;
  FLinkFont.Style := FLinkFont.Style + [fsUnderline];

  // Passive is the normal font
  FPassiveFont := TFont.Create;
  FPassiveFont.Assign(Font);

  // Set web page, and update the caption
  SetURL(defURL);

  // Set the font used for view
  SetViewFont;
  // don't show accelerator char (underline a char)
  ShowAccelChar := False;
  // Use the Hint property as full URL notify
  FURLAsHint := True;
end;

Destructor TmdURLLabel.Destroy;
Begin
  FLinkFont.Free;
  FPassiveFont.Free;
  Inherited Destroy;
end;

Procedure TmdURLLabel.SetAFont(AFont, AValue : TFont);
Begin
  If AFont <> NIL Then
    AFont.Assign(AValue);
end;

Procedure TmdURLLabel.SetLinkFont(Value : TFont);
Begin
  SetAFont(FLinkFont,Value);
end;

Procedure TmdURLLabel.SetPassiveFont(Value : TFont);
Begin
  SetAFont(FPassiveFont,Value);
end;

Procedure TmdURLLabel.SetViewFont;
Begin
  // If the label should look like a HTML link
  If (FLabelType = Link) OR
     (FLinkAble AND (FLabelType = Auto)) Then
  Begin
    Font := LinkFont;
    If NOT (csDesigning IN ComponentState) Then
      Cursor := crURLCursor;
  end
  else  // If the label should look like a normal label
  Begin
    Font := PassiveFont;
    If NOT (csDesigning IN ComponentState) Then
      Cursor := crDefault;
  end;
end;

Procedure TmdURLLabel.SetURL(Value : String);
Var
  S : String;
Begin
  If FURL = Value Then Exit;
  If Pos('@',Value) <> 0 Then  // can only be a e-mail
    FLinkType := mailto;
  If Pos('/',Value) <> 0 Then  // can only be a URL
    FLinkType := http;
  S := LowerCase(Copy(Value,1,7));
  If (S = 'mailto:') OR (S = 'http://') Then
    FURL := Copy(Value,8,Length(Value))
  else
    FURL := Value;
  SetTheCaption;  // update the caption
end;

Procedure TmdURLLabel.SetShowPrefix(Value : Boolean);
Begin
  FShowPrefix := Value;
  SetTheCaption; // update the caption
end;

Procedure TmdURLLabel.SetLabelType(Value : TmdLabelType);
Begin
  If Value = FLabelType Then
    Exit;
  FLabelType := Value;
  SetViewFont; // update the font (according to the new type)
end;

Procedure TmdURLLabel.SetLinkType(Value : TmdLinkType);
Begin
  If FLinkType = Value Then
    Exit;
  FLinkType := Value;
  CheckLinkAble;
  Case FLinkType of
    mailto : If FURL = defURL Then FURL := defMailto;
    http : If FURL = defMailto Then FURL := defURL;
  end;
  SetTheCaption;
end;

Procedure TmdURLLabel.CheckLinkAble;
Var
  AModule : HModule;
Begin
  Case FLinkType of
    // If the .html and the .htm extension is assigned to
    // a program
    http : FLinkAble := (GetProgramPathFromExt('.html') <> '') AND
                        (GetProgramPathFromExt('.htm') <> '');
    // Check it the MAPI dll is there
    mailto :
    Begin
      AModule := LoadLibrary(PChar(MAPIDLL));
      FLinkAble := AModule > 32;
      IF FLinkAble Then
        FreeLibrary(AModule);
    end;
  end;
end;

Procedure TmdURLLabel.SetTheCaption;
Begin
  If FShowPrefix Then
  Begin
    Case FLinkType of
      http : SetURLCaption('http://' + FURL);
      mailto : SetURLCaption('mailto:'+ FURL);
    end;
  end
  else
    SetURLCaption(FURL);
end;

Procedure TmdURLLabel.Click;
Var
  Param : AnsiString;
Begin
  Inherited Click;
  If (FLabelType = Link) OR
     (FLinkAble AND (FLabelType = Auto)) Then
  Begin
    Case FLinkType of
      http   : Param := 'http://'+URL;
      mailto : Param := 'mailto:'+URL;
    end;
    // Execute the default web browser on the
    // web page or the mailto window
    ShellExecute(0,
                 'open',
                 PChar(Param),
                 NIL,
                 NIL,
                 SW_SHOWNORMAL);
  end;
end;

Function TmdURLLabel.GetCaption : TCaption;
Begin
  Result := Inherited Caption; // Get the old caption
end;

Procedure TmdURLLabel.SetCaption(Value : TCaption);
Begin
  FCaptionChanged := True;     // Set flag that caption is set by user
  Inherited Caption := Value;  // Set the "real" caption variable
end;

Procedure TmdURLLabel.SetURLCaption(Value : TCaption);
Begin
  If NOT FCaptionChanged Then   // Check if user have changed the caption
    Inherited Caption := Value; // If (s)he havent, set it!
  FURLCaption := Value;
  UpdateHint;                   // Update the hint values
end;

Procedure TmdURLLabel.SetURLAsHint(Value : Boolean);
Begin
  If FURLAsHint = Value Then
    Exit;
  FURLAsHint := Value;
  UpdateHint;                    // Update the hint values
end;

Procedure TmdURLLabel.UpdateHint;
Begin
  If URLAsHint Then              // If we use URL as hint
    Inherited Hint := URLCaption // copy URL caption
  else
    Inherited Hint := '';        // delete it...
end;

Procedure TmdURLLabel.SetHint(Value : TCaption);
Begin
  Inherited Hint := Value;
end;

Function TmdURLLabel.GetHint : TCaption;
Begin
  FURLAsHint := False;        // remove the property which "allows" the
                              // the hint to be used as URL notify event!
  Result := Inherited Hint;
end;

procedure Register;
begin
  RegisterComponents('mdVCL', [TmdURLLabel]);
end;

end.
