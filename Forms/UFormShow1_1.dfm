object FormShow1_1: TFormShow1_1
  Left = 267
  Top = 132
  Width = 1042
  Height = 656
  Caption = 'FormShow1_1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 1034
    Height = 29
    ButtonHeight = 24
    Caption = 'ToolBar1'
    EdgeBorders = [ebLeft, ebTop, ebRight]
    TabOrder = 0
    object PrintButton: TSpeedButton
      Left = 0
      Top = 2
      Width = 25
      Height = 24
      Hint = 'Print'
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        04000000000000010000130B0000130B00001000000000000000000000000000
        800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00300000000000
        00033FFFFFFFFFFFFFFF0888888888888880777777777777777F088888888888
        8880777777777777777F0000000000000000FFFFFFFFFFFFFFFF0F8F8F8F8F8F
        8F80777777777777777F08F8F8F8F8F8F9F0777777777777777F0F8F8F8F8F8F
        8F807777777777777F7F0000000000000000777777777777777F3330FFFFFFFF
        03333337F3FFFF3F7F333330F0000F0F03333337F77773737F333330FFFFFFFF
        03333337F3FF3FFF7F333330F00F000003333337F773777773333330FFFF0FF0
        33333337F3FF7F3733333330F08F0F0333333337F7737F7333333330FFFF0033
        33333337FFFF7733333333300000033333333337777773333333}
      NumGlyphs = 2
      ParentShowHint = False
      ShowHint = True
      OnClick = PrintButtonClick
    end
    object CheckBox1: TCheckBox
      Left = 25
      Top = 2
      Width = 97
      Height = 24
      Caption = 'DateFormat'
      TabOrder = 0
      OnClick = CheckBox1Click
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 29
    Width = 1034
    Height = 593
    ActivePage = TabSheet1_1Plot
    Align = alClient
    TabOrder = 1
    object TabSheet1_1Plot: TTabSheet
      Caption = '1_1 Plot'
      object Chart1_1: TChart
        Left = 0
        Top = 0
        Width = 729
        Height = 565
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          '')
        BottomAxis.Title.Caption = 'Simulated'
        BottomAxis.Title.Font.Charset = DEFAULT_CHARSET
        BottomAxis.Title.Font.Color = clBlack
        BottomAxis.Title.Font.Height = -16
        BottomAxis.Title.Font.Name = 'Arial'
        BottomAxis.Title.Font.Style = []
        Chart3DPercent = 1
        LeftAxis.Title.Caption = 'Measured'
        LeftAxis.Title.Font.Charset = DEFAULT_CHARSET
        LeftAxis.Title.Font.Color = clBlack
        LeftAxis.Title.Font.Height = -16
        LeftAxis.Title.Font.Name = 'Arial'
        LeftAxis.Title.Font.Style = []
        LeftAxis.TitleSize = 5
        View3D = False
        Align = alLeft
        TabOrder = 0
      end
      object AdvStringGridLegend: TAdvStringGrid
        Left = 728
        Top = 0
        Width = 298
        Height = 565
        Align = alRight
        ColCount = 1
        DefaultColWidth = 160
        DefaultRowHeight = 21
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing]
        TabOrder = 1
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
        ColumnSize.Stretch = True
        ColumnSize.Location = clRegistry
        CellNode.Color = clSilver
        CellNode.NodeType = cnFlat
        CellNode.NodeColor = clBlack
        SizeWhileTyping.Height = False
        SizeWhileTyping.Width = False
        MouseActions.AllSelect = True
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
        ScrollWidth = 17
        ScrollProportional = False
        ScrollHints = shNone
        OemConvert = False
        FixedFooters = 0
        FixedRightCols = 0
        FixedColWidth = 294
        FixedRowHeight = 21
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
        ColWidths = (
          294)
        RowHeights = (
          22
          22)
      end
    end
    object TabSheetDataTab: TTabSheet
      Caption = 'DataTab'
      ImageIndex = 2
      object AdvStringGrid1_1: TAdvStringGrid
        Left = 0
        Top = 0
        Width = 1026
        Height = 565
        Align = alClient
        ColCount = 4
        DefaultColWidth = 90
        DefaultRowHeight = 21
        FixedCols = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect]
        TabOrder = 0
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
        Navigation.AllowClipboardShortCuts = True
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
        MouseActions.AllSelect = True
        MouseActions.ColSelect = True
        MouseActions.RowSelect = False
        MouseActions.DirectEdit = False
        MouseActions.DirectComboDrop = False
        MouseActions.DisjunctRowSelect = True
        MouseActions.AllColumnSize = False
        MouseActions.AllRowSize = False
        MouseActions.CaretPositioning = True
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
        FixedColWidth = 90
        FixedRowHeight = 21
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
    end
    object TabSheetResPlot: TTabSheet
      Caption = 'ResPlot'
      ImageIndex = 2
      object ChartResPlot: TChart
        Left = 0
        Top = 0
        Width = 1026
        Height = 565
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          'TChart')
        Legend.Visible = False
        View3D = False
        View3DWalls = False
        Align = alClient
        TabOrder = 0
      end
    end
  end
end
