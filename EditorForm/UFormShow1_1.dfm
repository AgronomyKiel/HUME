object FormShow1_1: TFormShow1_1
  Left = 0
  Top = 2
  Caption = 'FormShow1_1'
  ClientHeight = 551
  ClientWidth = 788
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 788
    Height = 29
    ButtonHeight = 24
    Caption = 'ToolBar1'
    EdgeBorders = [ebLeft, ebTop, ebRight]
    TabOrder = 0
    object PrintButton: TSpeedButton
      Left = 0
      Top = 0
      Width = 60
      Height = 24
      Hint = 'Print'
      Constraints.MinWidth = 30
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
    object SpeedButtonSave_1_1_as_png: TSpeedButton
      Left = 60
      Top = 0
      Width = 40
      Height = 24
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
        8888880000000000000880330000008803088033000000880308803300000088
        0308803300000000030880333333333333088033000000003308803088888888
        0308803088888888030880308888888803088030888888880308803088888888
        0008803088888888080880000000000000088888888888888888}
      OnClick = SpeedButtonSave_1_1_as_pngClick
    end
    object CheckBox1: TCheckBox
      Left = 100
      Top = 0
      Width = 120
      Height = 24
      Caption = 'DateFormat'
      Constraints.MinWidth = 120
      TabOrder = 0
      OnClick = CheckBox1Click
    end
  end
  object PageControlStat: TPageControl
    Left = 0
    Top = 29
    Width = 788
    Height = 522
    ActivePage = TabSheet1_1Plot
    Align = alClient
    TabOrder = 1
    object TabSheet1_1Plot: TTabSheet
      Caption = '1_1 Plot'
      DesignSize = (
        780
        494)
      object Chart1_1: TChart
        AlignWithMargins = True
        Left = 0
        Top = 0
        Width = 487
        Height = 494
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          '')
        BottomAxis.LabelsFormat.Font.Height = -13
        BottomAxis.Title.Caption = 'Simulated'
        BottomAxis.Title.Font.Height = -16
        Chart3DPercent = 1
        LeftAxis.LabelsFormat.Font.Height = -13
        LeftAxis.Title.Caption = 'Measured'
        LeftAxis.Title.Font.Height = -16
        LeftAxis.TitleSize = 5
        View3D = False
        TabOrder = 0
        Anchors = [akLeft, akTop, akRight, akBottom]
        DefaultCanvas = 'TGDIPlusCanvas'
        PrintMargins = (
          15
          1
          15
          1)
        ColorPaletteIndex = 13
      end
      object AdvStringGridLegend: TAdvStringGrid
        Left = 482
        Top = 0
        Width = 298
        Height = 494
        Cursor = crDefault
        Align = alRight
        ColCount = 1
        DefaultColWidth = 160
        DefaultRowHeight = 21
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
        ScrollBars = ssBoth
        TabOrder = 1
        GridLineColor = 15527152
        GridFixedLineColor = 13947601
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 16575452
        ActiveCellColorTo = 16571329
        CellNode.NodeType = cnFlat
        ColumnSize.Stretch = True
        ControlLook.FixedGradientMirrorFrom = 16049884
        ControlLook.FixedGradientMirrorTo = 16247261
        ControlLook.FixedGradientHoverFrom = 16710648
        ControlLook.FixedGradientHoverTo = 16446189
        ControlLook.FixedGradientHoverMirrorFrom = 16049367
        ControlLook.FixedGradientHoverMirrorTo = 15258305
        ControlLook.FixedGradientDownFrom = 15853789
        ControlLook.FixedGradientDownTo = 15852760
        ControlLook.FixedGradientDownMirrorFrom = 15522767
        ControlLook.FixedGradientDownMirrorTo = 15588559
        ControlLook.FixedGradientDownBorder = 14007466
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
        FilterDropDown.Font.Name = 'MS Sans Serif'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedColWidth = 294
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        Look = glWin7
        MouseActions.AllSelect = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
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
        SearchFooter.Color = 16645370
        SearchFooter.ColorTo = 16247261
        SearchFooter.FindNextCaption = 'Find &next'
        SearchFooter.FindPrevCaption = 'Find &previous'
        SearchFooter.Font.Charset = DEFAULT_CHARSET
        SearchFooter.Font.Color = clWindowText
        SearchFooter.Font.Height = -11
        SearchFooter.Font.Name = 'MS Sans Serif'
        SearchFooter.Font.Style = []
        SearchFooter.HighLightCaption = 'Highlight'
        SearchFooter.HintClose = 'Close'
        SearchFooter.HintFindNext = 'Find next occurence'
        SearchFooter.HintFindPrev = 'Find previous occurence'
        SearchFooter.HintHighlight = 'Highlight occurences'
        SearchFooter.MatchCaseCaption = 'Match case'
        SortSettings.HeaderColor = 16579058
        SortSettings.HeaderColorTo = 16579058
        SortSettings.HeaderMirrorColor = 16380385
        SortSettings.HeaderMirrorColorTo = 16182488
        Version = '5.0.3.1'
        WordWrap = False
        ExplicitLeft = 484
        ExplicitTop = -3
        ExplicitHeight = 484
        ColWidths = (
          294)
      end
    end
    object TabSheetDataTab: TTabSheet
      Caption = 'DataTab'
      ImageIndex = 2
      object AdvStringGrid1_1: TAdvStringGrid
        Left = 0
        Top = 21
        Width = 780
        Height = 473
        Cursor = crDefault
        Align = alClient
        ColCount = 4
        DefaultColWidth = 90
        DefaultRowHeight = 21
        FixedCols = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect]
        ScrollBars = ssBoth
        TabOrder = 0
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
        FilterDropDown.Font.Name = 'MS Sans Serif'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedColWidth = 90
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        MouseActions.AllSelect = True
        MouseActions.CaretPositioning = True
        MouseActions.ColSelect = True
        MouseActions.DisjunctRowSelect = True
        Navigation.AllowClipboardShortCuts = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
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
        SearchFooter.Font.Name = 'MS Sans Serif'
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
        ExplicitWidth = 782
        ExplicitHeight = 463
      end
      object Edit_1_1_FileName: TEdit
        Left = 0
        Top = 0
        Width = 780
        Height = 21
        Align = alTop
        TabOrder = 1
        Text = 'Edit_1_1_FileName'
      end
    end
    object TabSheetResPlot: TTabSheet
      Caption = 'ResPlot'
      ImageIndex = 2
      object ChartResPlot: TChart
        Left = 0
        Top = 0
        Width = 780
        Height = 494
        BackWall.Brush.Style = bsClear
        Legend.Visible = False
        Title.Font.Height = -21
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        BottomAxis.LabelsFormat.Font.Height = -16
        BottomAxis.Title.Caption = 'Simulated'
        BottomAxis.Title.Font.Height = -16
        BottomAxis.TitleSize = 12
        LeftAxis.LabelsFormat.Font.Height = -16
        LeftAxis.Title.Caption = 'Residuals'
        LeftAxis.Title.Font.Height = -16
        View3D = False
        View3DWalls = False
        Align = alClient
        TabOrder = 0
        DefaultCanvas = 'TGDIPlusCanvas'
        PrintMargins = (
          15
          19
          15
          19)
        ColorPaletteIndex = 13
      end
    end
    object TabSheetStatistics: TTabSheet
      Caption = 'Statistics'
      ImageIndex = 3
      object MemoStatistics: TMemo
        Left = 0
        Top = 0
        Width = 780
        Height = 494
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
    end
  end
  object SavePictureDialog1: TSavePictureDialog
    Left = 384
    Top = 336
  end
end
