object FormGAOpt: TFormGAOpt
  Left = 232
  Top = 179
  Caption = 'GA Optimization'
  ClientHeight = 629
  ClientWidth = 944
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object LabelWeightOption: TLabel
    Left = 56
    Top = 280
    Width = 65
    Height = 13
    Caption = 'WeightOption'
  end
  object Button1: TButton
    Left = 8
    Top = 572
    Width = 75
    Height = 25
    Caption = 'Optimize'
    TabOrder = 0
    OnClick = Button1Click
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 944
    Height = 561
    ActivePage = TabSheet3
    Align = alTop
    TabOrder = 1
    object TabSheet3: TTabSheet
      Caption = 'SelectParams'
      ImageIndex = 1
      object SrcLabel: TLabel
        Left = 21
        Top = 21
        Width = 64
        Height = 16
        AutoSize = False
        Caption = 'Available'
      end
      object DstLabel: TLabel
        Left = 354
        Top = 21
        Width = 63
        Height = 16
        AutoSize = False
        Caption = 'Selected'
      end
      object IncludeBtnPar: TSpeedButton
        Left = 294
        Top = 58
        Width = 24
        Height = 24
        Caption = '>'
        OnClick = IncludeBtnParClick
      end
      object IncAllBtnPar: TSpeedButton
        Left = 294
        Top = 90
        Width = 24
        Height = 24
        Caption = '>>'
        OnClick = IncAllBtnParClick
      end
      object ExcludeBtnPar: TSpeedButton
        Left = 294
        Top = 122
        Width = 24
        Height = 24
        Caption = '<'
        Enabled = False
        OnClick = ExcludeBtnParClick
      end
      object ExAllBtnPar: TSpeedButton
        Left = 294
        Top = 154
        Width = 24
        Height = 24
        Caption = '<<'
        Enabled = False
        OnClick = ExAllBtnParClick
      end
      object Label1: TLabel
        Left = 26
        Top = 228
        Width = 59
        Height = 20
        Alignment = taCenter
        AutoSize = False
        Caption = 'Available'
        Layout = tlCenter
        WordWrap = True
      end
      object Label2: TLabel
        Left = 354
        Top = 221
        Width = 63
        Height = 16
        AutoSize = False
        Caption = 'Selected'
      end
      object IncludeBtnData: TSpeedButton
        Left = 294
        Top = 258
        Width = 24
        Height = 25
        Caption = '>'
        OnClick = IncludeBtnDataClick
      end
      object IncAllBtnData: TSpeedButton
        Left = 294
        Top = 290
        Width = 24
        Height = 24
        Caption = '>>'
        OnClick = IncAllBtnDataClick
      end
      object ExcludeBtnData: TSpeedButton
        Left = 294
        Top = 322
        Width = 24
        Height = 24
        Caption = '<'
        Enabled = False
        OnClick = ExcludeBtnDataClick
      end
      object ExAllBtnData: TSpeedButton
        Left = 294
        Top = 354
        Width = 24
        Height = 23
        Caption = '<<'
        Enabled = False
        OnClick = ExAllBtnDataClick
      end
      object Label3: TLabel
        Left = 72
        Top = 209
        Width = 34
        Height = 16
        Caption = 'Data'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label4: TLabel
        Left = 78
        Top = 7
        Width = 73
        Height = 16
        Caption = 'Parameter'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object SrcListPar: TListBox
        Left = 21
        Top = 37
        Width = 236
        Height = 163
        Hint = 'Zur Verf'#252'gung stehende Parameter'
        ItemHeight = 13
        Items.Strings = (
          'Eintrag1'
          'Eintrag2'
          'Eintrag3'
          'Eintrag4'
          'Eintrag5')
        MultiSelect = True
        ParentShowHint = False
        ShowHint = True
        Sorted = True
        TabOrder = 0
      end
      object DstListPar: TListBox
        Left = 352
        Top = 39
        Width = 225
        Height = 163
        Hint = 'Ausgew'#228'hlte Parameter'
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 1
      end
      object SrcListData: TListBox
        Left = 21
        Top = 245
        Width = 236
        Height = 178
        Hint = 'Zur Verf'#252'gung stehende Datenreihen'
        ItemHeight = 13
        Items.Strings = (
          'Eintrag1'
          'Eintrag2'
          'Eintrag3'
          'Eintrag4'
          'Eintrag5')
        MultiSelect = True
        ParentShowHint = False
        ShowHint = True
        Sorted = True
        TabOrder = 2
      end
      object DstListData: TListBox
        Left = 351
        Top = 240
        Width = 218
        Height = 175
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 3
      end
    end
    object TabSheetOptparams: TTabSheet
      Caption = 'Optparams'
      ImageIndex = 1
      object Labelpopulationsize: TLabel
        Left = 48
        Top = 72
        Width = 71
        Height = 13
        Caption = 'Population size'
      end
      object Labelchromosomelength: TLabel
        Left = 48
        Top = 104
        Width = 93
        Height = 13
        Caption = 'Chromosome length'
      end
      object Labelmaxgenerations: TLabel
        Left = 48
        Top = 136
        Width = 81
        Height = 13
        Caption = 'Max. generations'
      end
      object Labelcrossoverprobability: TLabel
        Left = 48
        Top = 168
        Width = 97
        Height = 13
        Caption = 'Crossover probability'
      end
      object Labelmutationprobability: TLabel
        Left = 48
        Top = 200
        Width = 91
        Height = 13
        Caption = 'Mutation probability'
      end
      object Label5: TLabel
        Left = 48
        Top = 272
        Width = 65
        Height = 13
        Caption = 'WeightOption'
      end
      object IntEditPopSize: TIntEdit
        Left = 200
        Top = 64
        Width = 57
        Height = 21
        TabOrder = 0
        Text = '0'
        OnExit = IntEditPopSizeExit
        Value = 0
      end
      object IntEditChromLength: TIntEdit
        Left = 200
        Top = 96
        Width = 57
        Height = 21
        TabOrder = 1
        Text = '0'
        Value = 0
      end
      object IntEditMaxGen: TIntEdit
        Left = 200
        Top = 128
        Width = 57
        Height = 21
        TabOrder = 2
        Text = '0'
        OnExit = IntEditMaxGenExit
        Value = 0
      end
      object FloatEditCrossProb: TFloatEdit
        Left = 200
        Top = 160
        Width = 57
        Height = 21
        TabOrder = 3
        Text = '0.0'
        OnExit = FloatEditCrossProbExit
      end
      object FloatEditMutProb: TFloatEdit
        Left = 200
        Top = 192
        Width = 57
        Height = 21
        TabOrder = 4
        Text = '0.0'
        OnExit = FloatEditMutProbExit
      end
      object AdvStringGridParams: TAdvStringGrid
        Left = 336
        Top = 64
        Width = 481
        Height = 393
        Cursor = crDefault
        ColCount = 7
        DefaultRowHeight = 21
        FixedCols = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
        ScrollBars = ssBoth
        TabOrder = 5
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        CellNode.NodeType = cnFlat
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
        EnhRowColMove = False
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'Tahoma'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'Tahoma'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -11
        PrintSettings.HeaderFont.Name = 'MS Sans Serif'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -11
        PrintSettings.FooterFont.Name = 'MS Sans Serif'
        PrintSettings.FooterFont.Style = []
        PrintSettings.Borders = pbNoborder
        PrintSettings.Centered = False
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
        SelectionColor = clHighlight
        SelectionTextColor = clHighlightText
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          64
          64
          64
          64
          64
          64
          64)
      end
      object ComboBoxWeightOption: TComboBox
        Left = 128
        Top = 272
        Width = 145
        Height = 21
        TabOrder = 6
        Text = 'NoWeight'
        Items.Strings = (
          'NoWeight'
          'DefaultWeight'
          'Measurementerror')
      end
    end
    object TabsheetFitness: TTabSheet
      Caption = 'Fitness'
      ImageIndex = 2
      object Chart1: TChart
        Left = 0
        Top = 0
        Width = 936
        Height = 533
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          'TChart')
        BottomAxis.Title.Caption = 'Generation'
        LeftAxis.Title.Caption = 'Fitness'
        View3D = False
        Zoom.Animated = True
        Align = alClient
        AutoSize = True
        TabOrder = 0
        ExplicitHeight = 549
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
    end
    object TabSheetParameter: TTabSheet
      Caption = 'Parameter'
      ImageIndex = 3
      object ChartParms: TChart
        Left = 0
        Top = 0
        Width = 936
        Height = 533
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          '')
        BottomAxis.Title.Caption = 'Generation'
        Chart3DPercent = 1
        View3D = False
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 549
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
    end
    object TabSheet3DOut: TTabSheet
      Caption = 'TabSheet3DOut'
      ImageIndex = 4
      object MathImage1: TMathImage
        Left = 0
        Top = 0
        Width = 936
        Height = 533
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Version = '6.0(beta 5) May 2000'
        RecordMetafile = False
        d2WorldX1 = -1.000000000000000000
        d2WorldXW = 2.000000000000000000
        d2WorldY1 = -1.000000000000000000
        d2WorldYW = 2.000000000000000000
        d3WorldX1 = -1.000000000000000000
        d3WorldXW = 2.000000000000000000
        d3WorldY1 = -1.000000000000000000
        d3WorldYW = 2.000000000000000000
        d3WorldZ1 = -1.000000000000000000
        d3WorldZW = 2.000000000000000000
        d3Xscale = 1.000000000000000000
        d3Yscale = 1.000000000000000000
        d3Zscale = 1.000000000000000000
        d3Zrotation = 45.000000000000000000
        d3Yrotation = 45.000000000000000000
        d3ViewDist = 6.400000000000000000
        d3ViewAngle = 6.000000000000000000
        d3AspectRatio = True
        ExplicitWidth = 920
        ExplicitHeight = 549
      end
    end
    object TabSheetTextOutput: TTabSheet
      Caption = 'TextOutput'
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 936
        Height = 533
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -8
        Font.Name = 'Courier'
        Font.Style = []
        Lines.Strings = (
          'Memo1')
        ParentFont = False
        TabOrder = 0
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 603
    Width = 944
    Height = 26
    Panels = <
      item
        Width = 250
      end
      item
        Width = 250
      end>
  end
end
