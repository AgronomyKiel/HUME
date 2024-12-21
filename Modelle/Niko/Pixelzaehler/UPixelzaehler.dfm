object Form1: TForm1
  Left = 0
  Top = 0
  Caption = ':'
  ClientHeight = 440
  ClientWidth = 739
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = mm1
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    739
    440)
  PixelsPerInch = 96
  TextHeight = 13
  object ScrollBox1: TScrollBox
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 400
    Height = 400
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object img1: TImage
      Left = 0
      Top = 0
      Width = 190
      Height = 174
    end
  end
  object btn3: TButton
    Left = 500
    Top = 117
    Width = 79
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Run'
    TabOrder = 1
    OnClick = btn3Click
  end
  object btnReload: TButton
    Left = 422
    Top = 117
    Width = 72
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Reload'
    TabOrder = 2
    OnClick = btnReloadClick
  end
  object stat1: TStatusBar
    Left = 0
    Top = 421
    Width = 739
    Height = 19
    Panels = <
      item
        Width = 50
      end>
    ExplicitTop = 369
    ExplicitWidth = 672
  end
  object StringGrid1: TAdvStringGrid
    Left = 422
    Top = 148
    Width = 309
    Height = 262
    Cursor = crDefault
    Anchors = [akTop, akRight, akBottom]
    ColCount = 4
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
    PopupMenu = pm1
    ScrollBars = ssBoth
    TabOrder = 4
    AnchorHint = True
    ActiveCellFont.Charset = DEFAULT_CHARSET
    ActiveCellFont.Color = clWindowText
    ActiveCellFont.Height = -11
    ActiveCellFont.Name = 'Tahoma'
    ActiveCellFont.Style = [fsBold]
    AutoNumAlign = True
    ColumnSize.Stretch = True
    ColumnSize.StretchColumn = 0
    ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownHeader.Font.Color = clWindowText
    ControlLook.DropDownHeader.Font.Height = -11
    ControlLook.DropDownHeader.Font.Name = 'Tahoma'
    ControlLook.DropDownHeader.Font.Style = []
    ControlLook.DropDownHeader.Visible = True
    ControlLook.DropDownHeader.Buttons = <>
    ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownFooter.Font.Color = clWindowText
    ControlLook.DropDownFooter.Font.Height = -11
    ControlLook.DropDownFooter.Font.Name = 'Tahoma'
    ControlLook.DropDownFooter.Font.Style = []
    ControlLook.DropDownFooter.Visible = True
    ControlLook.DropDownFooter.Buttons = <>
    Filter = <>
    FilterDropDown.Font.Charset = DEFAULT_CHARSET
    FilterDropDown.Font.Color = clWindowText
    FilterDropDown.Font.Height = -11
    FilterDropDown.Font.Name = 'Tahoma'
    FilterDropDown.Font.Style = []
    FilterDropDownClear = '(All)'
    FixedColWidth = 120
    FixedRowHeight = 22
    FixedFont.Charset = DEFAULT_CHARSET
    FixedFont.Color = clWindowText
    FixedFont.Height = -11
    FixedFont.Name = 'Tahoma'
    FixedFont.Style = [fsBold]
    FloatFormat = '%.2f'
    MouseActions.RowSelect = True
    MouseActions.SizeFixedCol = True
    MouseActions.SizeFixedRow = True
    PrintSettings.DateFormat = 'dd/mm/yyyy'
    PrintSettings.Font.Charset = DEFAULT_CHARSET
    PrintSettings.Font.Color = clWindowText
    PrintSettings.Font.Height = -11
    PrintSettings.Font.Name = 'Tahoma'
    PrintSettings.Font.Style = []
    PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
    PrintSettings.FixedFont.Color = clWindowText
    PrintSettings.FixedFont.Height = -11
    PrintSettings.FixedFont.Name = 'Tahoma'
    PrintSettings.FixedFont.Style = []
    PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
    PrintSettings.HeaderFont.Color = clWindowText
    PrintSettings.HeaderFont.Height = -11
    PrintSettings.HeaderFont.Name = 'Tahoma'
    PrintSettings.HeaderFont.Style = []
    PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
    PrintSettings.FooterFont.Color = clWindowText
    PrintSettings.FooterFont.Height = -11
    PrintSettings.FooterFont.Name = 'Tahoma'
    PrintSettings.FooterFont.Style = []
    PrintSettings.PageNumSep = '/'
    ScrollWidth = 16
    SearchFooter.FindNextCaption = 'Find &next'
    SearchFooter.FindPrevCaption = 'Find &previous'
    SearchFooter.Font.Charset = DEFAULT_CHARSET
    SearchFooter.Font.Color = clWindowText
    SearchFooter.Font.Height = -11
    SearchFooter.Font.Name = 'Tahoma'
    SearchFooter.Font.Style = []
    SearchFooter.HighLightCaption = 'Highlight'
    SearchFooter.HintClose = 'Close'
    SearchFooter.HintFindNext = 'Find next occurence'
    SearchFooter.HintFindPrev = 'Find previous occurence'
    SearchFooter.HintHighlight = 'Highlight occurences'
    SearchFooter.MatchCaseCaption = 'Match case'
    Version = '5.0.3.1'
    ColWidths = (
      120
      81
      60
      43)
  end
  object grp1: TGroupBox
    Left = 422
    Top = 8
    Width = 109
    Height = 103
    Anchors = [akTop, akRight]
    Caption = 'Bereich f'#228'rben?'
    TabOrder = 5
    object ButtonColorInnerhalb: TButtonColor
      Left = 6
      Top = 52
      Width = 25
      TabOrder = 0
      OnClick = ButtonColorInnerhalbClick
    end
    object ButtonColorAusserhalb: TButtonColor
      Left = 6
      Top = 21
      Width = 25
      TabOrder = 1
      OnClick = ButtonColorAusserhalbClick
    end
    object chkinnerhalb: TCheckBox
      Left = 37
      Top = 56
      Width = 65
      Height = 17
      Caption = 'innerhalb'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object chkausserhalb: TCheckBox
      Left = 37
      Top = 25
      Width = 65
      Height = 17
      Caption = 'au'#223'erhalb'
      TabOrder = 3
    end
  end
  object grp2: TGroupBox
    Left = 550
    Top = 6
    Width = 181
    Height = 105
    Anchors = [akTop, akRight]
    Caption = 'Bereich im HSB Modell'
    TabOrder = 6
    ExplicitLeft = 483
    object lbl1: TLabel
      Left = 6
      Top = 21
      Width = 54
      Height = 13
      Caption = 'Farbton ['#176']'
    end
    object lbl2: TLabel
      Left = 6
      Top = 48
      Width = 68
      Height = 13
      Caption = 'S'#228'ttigung [%]'
    end
    object lbl3: TLabel
      Left = 6
      Top = 75
      Width = 64
      Height = 13
      Caption = 'Helligkeit [%]'
    end
    object sehuestart: TSpinEdit
      Left = 76
      Top = 20
      Width = 45
      Height = 22
      MaxLength = 3
      MaxValue = 360
      MinValue = 0
      TabOrder = 0
      Value = 0
    end
    object sehueend: TSpinEdit
      Left = 127
      Top = 20
      Width = 45
      Height = 22
      MaxLength = 3
      MaxValue = 360
      MinValue = 0
      TabOrder = 1
      Value = 360
    end
    object sesaturationstart: TSpinEdit
      Left = 76
      Top = 47
      Width = 45
      Height = 22
      MaxLength = 3
      MaxValue = 100
      MinValue = 0
      TabOrder = 2
      Value = 0
    end
    object sesaturationend: TSpinEdit
      Left = 127
      Top = 48
      Width = 45
      Height = 22
      MaxLength = 3
      MaxValue = 100
      MinValue = 0
      TabOrder = 3
      Value = 100
    end
    object sebrightnessstart: TSpinEdit
      Left = 76
      Top = 75
      Width = 45
      Height = 22
      MaxLength = 3
      MaxValue = 100
      MinValue = 0
      TabOrder = 4
      Value = 0
    end
    object sebrightnessend: TSpinEdit
      Left = 127
      Top = 75
      Width = 45
      Height = 22
      MaxLength = 3
      MaxValue = 100
      MinValue = 0
      TabOrder = 5
      Value = 100
    end
  end
  object pb1: TProgressBar
    Left = 592
    Top = 126
    Width = 139
    Height = 16
    Anchors = [akTop, akRight]
    Smooth = True
    MarqueeInterval = 1
    Step = 1
    TabOrder = 7
  end
  object mm1: TMainMenu
    Left = 224
    Top = 8
    object mniDatei1: TMenuItem
      Caption = 'Datei'
      object mniiOeffnen1: TMenuItem
        Caption = 'Bild '#246'ffnen'
        OnClick = mniiOeffnen1Click
      end
      object mniAlleBilddateienimUnterverzeichnisanalysieren1: TMenuItem
        Caption = 'Alle Bilder im Verzeichnis auswerten'
        OnClick = mniAlleBilddateienimUnterverzeichnisanalysieren1Click
      end
      object mniCSV1: TMenuItem
        Caption = 'Tabelle speichern'
        OnClick = mniCSV1Click
      end
    end
    object mniAnsicht1: TMenuItem
      Caption = 'Ansicht'
      object mniN1001: TMenuItem
        Caption = '100%'
        OnClick = mniN1001Click
      end
      object mniN501: TMenuItem
        Caption = '50%'
        OnClick = mniN501Click
      end
      object mniN251: TMenuItem
        Caption = '25%'
        OnClick = mniN251Click
      end
      object mniN101: TMenuItem
        Caption = '10%'
        OnClick = mniN101Click
      end
      object mniN51: TMenuItem
        Caption = '5%'
        OnClick = mniN51Click
      end
      object mniN11: TMenuItem
        Caption = '1%'
        OnClick = mniN11Click
      end
    end
    object mniEinstellungen1: TMenuItem
      Caption = 'Einstellungen'
      object mnigrn1: TMenuItem
        Caption = 'gr'#252'n'
        OnClick = mnigrn1Click
      end
      object mnidunkel1: TMenuItem
        Caption = 'dunkel'
        OnClick = mnidunkel1Click
      end
    end
    object mniHilfe1: TMenuItem
      Caption = 'Hilfe'
      object mniFarbraum1: TMenuItem
        Caption = 'Farbraum'
        OnClick = mniFarbraum1Click
      end
      object mniInfo1: TMenuItem
        Caption = 'Info'
        OnClick = mniInfo1Click
      end
    end
  end
  object dlgOpen1: TOpenDialog
    Left = 272
    Top = 8
  end
  object dlgSave1: TSaveDialog
    Left = 224
    Top = 56
  end
  object pm1: TPopupMenu
    Left = 272
    Top = 56
    object mniLschen1: TMenuItem
      Caption = 'L'#246'schen'
      OnClick = mniLschen1Click
    end
  end
end
