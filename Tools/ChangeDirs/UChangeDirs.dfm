object Form1: TForm1
  Left = 265
  Top = 200
  Caption = 'Form1'
  ClientHeight = 538
  ClientWidth = 963
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 33
    Width = 963
    Height = 505
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'ChangeIniFileStrings'
      object LabelSourceDirectory: TLabel
        Left = 96
        Top = 88
        Width = 43
        Height = 13
        Caption = 'OldString'
      end
      object LabelDestDirectory: TLabel
        Left = 432
        Top = 88
        Width = 49
        Height = 13
        Caption = 'NewString'
      end
      object ButtonChange: TButton
        Left = 24
        Top = 412
        Width = 75
        Height = 25
        Caption = 'ChangeStrings'
        TabOrder = 0
        OnClick = ButtonChangeClick
      end
      object DirectoryListBoxSource: TDirectoryListBox
        Left = 96
        Top = 224
        Width = 265
        Height = 97
        TabOrder = 1
        OnChange = DirectoryListBoxSourceChange
      end
      object DriveComboBoxSource: TDriveComboBox
        Left = 96
        Top = 168
        Width = 265
        Height = 19
        TabOrder = 2
        OnChange = DriveComboBoxSourceChange
      end
      object DriveComboBoxDest: TDriveComboBox
        Left = 432
        Top = 168
        Width = 265
        Height = 19
        TabOrder = 3
        OnChange = DriveComboBoxDestChange
      end
      object DirectoryListBoxDest: TDirectoryListBox
        Left = 432
        Top = 224
        Width = 265
        Height = 97
        TabOrder = 4
        OnChange = DirectoryListBoxDestChange
      end
      object EditSource: TEdit
        Left = 96
        Top = 120
        Width = 265
        Height = 21
        TabOrder = 5
      end
      object EditDest: TEdit
        Left = 432
        Top = 120
        Width = 265
        Height = 21
        TabOrder = 6
      end
    end
    object TabSheetDataNames: TTabSheet
      Caption = 'ChangeDataNames'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object AdvStringGrid1: TAdvStringGrid
        Left = 0
        Top = 8
        Width = 833
        Height = 465
        Cursor = crDefault
        ColCount = 2
        DefaultColWidth = 240
        DefaultRowHeight = 21
        ScrollBars = ssBoth
        TabOrder = 0
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
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
        FixedColWidth = 240
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'Tahoma'
        FixedFont.Style = [fsBold]
        FloatFormat = '%.2f'
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
      end
      object ButtonLoadDataNames: TButton
        Left = 856
        Top = 16
        Width = 75
        Height = 25
        Caption = 'Load'
        TabOrder = 1
        OnClick = ButtonLoadDataNamesClick
      end
      object ButtonChangeDataVarNames: TButton
        Left = 856
        Top = 56
        Width = 75
        Height = 25
        Caption = 'Change'
        TabOrder = 2
        OnClick = ButtonChangeDataVarNamesClick
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 963
    Height = 33
    Align = alTop
    Caption = 'Panel1'
    TabOrder = 1
    object LabelFNFile: TLabel
      Left = 8
      Top = 12
      Width = 30
      Height = 13
      Caption = 'FNFile'
    end
    object EditFNfile: TEdit
      Left = 48
      Top = 4
      Width = 489
      Height = 21
      TabOrder = 0
    end
    object BitBtnFN: TBitBtn
      Left = 536
      Top = 0
      Width = 25
      Height = 25
      Caption = '...'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 1
      OnClick = BitBtnFNClick
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 888
    Top = 488
  end
end
