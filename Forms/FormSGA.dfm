object FormGAOpt: TFormGAOpt
  Left = 306
  Top = 292
  Width = 952
  Height = 656
  Caption = 'GA Optimization'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object LabelWeightOption: TLabel
    Left = 56
    Top = 280
    Width = 65
    Height = 13
    Caption = 'WeightOption'
  end
  object Button1: TButton
    Left = 16
    Top = 584
    Width = 75
    Height = 25
    Caption = 'Optimize'
    TabOrder = 0
    OnClick = Button1Click
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 928
    Height = 577
    ActivePage = TabSheet3DOut
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
        Hint = 'Zur Verfügung stehende Parameter'
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
        Hint = 'Ausgewählte Parameter'
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 1
      end
      object SrcListData: TListBox
        Left = 21
        Top = 245
        Width = 236
        Height = 178
        Hint = 'Zur Verfügung stehende Datenreihen'
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
      end
      object IntEditChromLength: TIntEdit
        Left = 200
        Top = 96
        Width = 57
        Height = 21
        TabOrder = 1
        Text = '0'
      end
      object IntEditMaxGen: TIntEdit
        Left = 200
        Top = 128
        Width = 57
        Height = 21
        TabOrder = 2
        Text = '0'
        OnExit = IntEditMaxGenExit
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
        ColCount = 7        
        FixedCols = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
        TabOrder = 5
        Bands.Active = False
        Bands.PrimaryColor = clInfoBk
        Bands.PrimaryLength = 1
        Bands.SecondaryColor = clWindow
        Bands.SecondaryLength = 1
        Bands.Print = False
        AutoNumAlign = False
        AutoSize = False
        VAlignment = vtaTop
        EnhTextSize = False
        EnhRowColMove = False
        SizeWithForm = False
        Multilinecells = False     
        HintColor = clYellow
        SelectionColor = clHighlight
        SelectionTextColor = clHighlightText
        SelectionRectangle = False
        SelectionRTFKeep = False
        HintShowCells = False
        PrintSettings.FooterSize = 0
        PrintSettings.HeaderSize = 0
        PrintSettings.Time = ppNone
        PrintSettings.Date = ppNone
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.PageNr = ppNone
        PrintSettings.Title = ppNone
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
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
        PrintSettings.BorderStyle = psSolid
        PrintSettings.Centered = False
        PrintSettings.RepeatFixedRows = False
        PrintSettings.RepeatFixedCols = False
        PrintSettings.LeftSize = 0
        PrintSettings.RightSize = 0
        PrintSettings.ColumnSpacing = 0
        PrintSettings.RowSpacing = 0
        PrintSettings.TitleSpacing = 0
        PrintSettings.Orientation = poPortrait
        PrintSettings.FixedWidth = 0
        PrintSettings.FixedHeight = 0
        PrintSettings.UseFixedHeight = False
        PrintSettings.UseFixedWidth = False
        PrintSettings.FitToPage = fpNever
        PrintSettings.PageNumSep = '/'
        PrintSettings.NoAutoSize = False
        PrintSettings.PrintGraphics = False
        HTMLSettings.Width = 100
        Navigation.AllowInsertRow = False
        Navigation.AllowDeleteRow = False
        Navigation.AdvanceOnEnter = False
        Navigation.AdvanceInsert = False
        Navigation.AutoGotoWhenSorted = False
        Navigation.AutoGotoIncremental = False
        Navigation.AutoComboDropSize = False
        Navigation.AdvanceDirection = adLeftRight
        Navigation.AllowClipboardShortCuts = False
        Navigation.AllowSmartClipboard = False
        Navigation.AllowRTFClipboard = False
        Navigation.AdvanceAuto = False
        Navigation.InsertPosition = pInsertBefore
        Navigation.CursorWalkEditor = False
        Navigation.MoveRowOnSort = False
        Navigation.ImproveMaskSel = False
        Navigation.AlwaysEdit = False
        Navigation.CopyHTMLTagsToClipboard = True
        ColumnSize.Save = False
        ColumnSize.Stretch = False
        ColumnSize.Location = clRegistry
        CellNode.Color = clSilver
        CellNode.NodeType = cnFlat
        CellNode.NodeColor = clBlack
        SizeWhileTyping.Height = False
        SizeWhileTyping.Width = False
        MouseActions.AllSelect = False
        MouseActions.ColSelect = False
        MouseActions.RowSelect = False
        MouseActions.DirectEdit = False
        MouseActions.DirectComboDrop = False
        MouseActions.DisjunctRowSelect = False
        MouseActions.AllColumnSize = False
        MouseActions.AllRowSize = False
        MouseActions.CaretPositioning = False
        IntelliPan = ipVertical
        URLColor = clBlue
        URLShow = False
        URLFull = False
        URLEdit = False
        ScrollType = ssNormal
        ScrollColor = clNone
        ScrollWidth = 16
        ScrollProportional = False
        ScrollHints = shNone
        OemConvert = False
        FixedFooters = 0
        FixedRightCols = 0
        FixedColWidth = 64        
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FixedAsButtons = False
        FloatFormat = '%.2f'
        WordWrap = False
        Lookup = False
        LookupCaseSensitive = False
        LookupHistory = False
        HideFocusRect = False
        BackGround.Top = 0
        BackGround.Left = 0
        BackGround.Display = bdTile
        Hovering = False
        Filter = <>
        FilterActive = False         
      end
      object ComboBoxWeightOption: TComboBox
        Left = 128
        Top = 272
        Width = 145
        Height = 21
        ItemHeight = 13
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
        Width = 920
        Height = 549
        AnimatedZoom = True
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          'TChart')
        BottomAxis.Title.Caption = 'Generation'
        LeftAxis.Title.Caption = 'Fitness'
        View3D = False
        Align = alClient
        TabOrder = 0
        AutoSize = True
      end
    end
    object TabSheetParameter: TTabSheet
      Caption = 'Parameter'
      ImageIndex = 3
      object ChartParms: TChart
        Left = 0
        Top = 0
        Width = 920
        Height = 549
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = ('')
        BottomAxis.Title.Caption = 'Generation'
        Chart3DPercent = 1
        View3D = False
        Align = alClient
        TabOrder = 0
      end
    end
    object TabSheet3DOut: TTabSheet
      Caption = 'TabSheet3DOut'
      ImageIndex = 4
      object MathImage1: TMathImage
        Left = 0
        Top = 0
        Width = 920
        Height = 549
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Version = '6.0(beta 5) May 2000'
        RecordMetafile = False
        d2WorldX1 = -1
        d2WorldXW = 2
        d2WorldY1 = -1
        d2WorldYW = 2
        d3WorldX1 = -1
        d3WorldXW = 2
        d3WorldY1 = -1
        d3WorldYW = 2
        d3WorldZ1 = -1
        d3WorldZW = 2
        d3Xscale = 1
        d3Yscale = 1
        d3Zscale = 1
        d3Zrotation = 45
        d3Yrotation = 45
        d3ViewDist = 6.4
        d3ViewAngle = 6
        d3AspectRatio = True
      end
    end
    object TabSheetTextOutput: TTabSheet
      Caption = 'TextOutput'
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 920
        Height = 549
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
    Top = 609
    Width = 928
    Height = 26
    Panels = <
      item
        Width = 250
      end
      item
        Width = 250
      end>
    SimplePanel = False
  end
end
