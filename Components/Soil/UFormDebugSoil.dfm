object FormDebugSoil: TFormDebugSoil
  Left = 0
  Top = 0
  Caption = 'FormDebugSoil'
  ClientHeight = 519
  ClientWidth = 1078
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object LabelSimTime: TLabel
    Left = 32
    Top = 462
    Width = 29
    Height = 16
    Caption = 'Time'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object LabelIniFileName: TLabel
    Left = 168
    Top = 462
    Width = 34
    Height = 16
    Caption = 'IniFile'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object LabelBilanz1: TLabel
    Left = 640
    Top = 462
    Width = 102
    Height = 16
    Caption = 'Bilanzfehler [mm]'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object LabelRain: TLabel
    Left = 816
    Top = 462
    Width = 61
    Height = 16
    Caption = 'Rain [mm]'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label_dt_int: TLabel
    Left = 32
    Top = 495
    Width = 37
    Height = 16
    Caption = 'dt_int:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object LabelIterInt: TLabel
    Left = 168
    Top = 495
    Width = 25
    Height = 16
    Caption = 'Iter:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object LabelIntBilFehler: TLabel
    Left = 640
    Top = 484
    Width = 125
    Height = 16
    Caption = 'Int. Bilanzfehler [mm]'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object LabelGlobTime: TLabel
    Left = 256
    Top = 498
    Width = 29
    Height = 13
    Caption = 'Time: '
  end
  object ChartDebugSoil: TChart
    Left = 0
    Top = 0
    Width = 361
    Height = 441
    MarginBottom = 2
    MarginRight = 2
    MarginTop = 2
    Title.Text.Strings = (
      'TChart')
    Title.Visible = False
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    BottomAxis.ExactDateTime = False
    BottomAxis.Increment = 0.100000000000000000
    BottomAxis.LabelsFormat.Font.Height = -13
    BottomAxis.LabelsSeparation = 0
    BottomAxis.Maximum = 0.550000000000000200
    BottomAxis.Title.Caption = 'Soil Water content [cm3/cm3]'
    BottomAxis.Title.Font.Height = -13
    Chart3DPercent = 1
    DepthAxis.Automatic = False
    DepthAxis.AutomaticMaximum = False
    DepthAxis.AutomaticMinimum = False
    DepthAxis.Maximum = -0.500000000000000000
    DepthAxis.Minimum = -0.500000000000000000
    DepthTopAxis.Automatic = False
    DepthTopAxis.AutomaticMaximum = False
    DepthTopAxis.AutomaticMinimum = False
    DepthTopAxis.Maximum = -0.500000000000000000
    DepthTopAxis.Minimum = -0.500000000000000000
    LeftAxis.Automatic = False
    LeftAxis.AutomaticMaximum = False
    LeftAxis.ExactDateTime = False
    LeftAxis.Increment = 10.000000000000000000
    LeftAxis.LabelsFormat.Font.Height = -13
    LeftAxis.LabelsSeparation = 0
    LeftAxis.LabelsSize = 32
    LeftAxis.Maximum = 5.000000000000000000
    LeftAxis.Title.Caption = 'Soil depth [cm]'
    LeftAxis.Title.Font.Height = -13
    LeftAxis.Title.Bevel = bvLowered
    LeftAxis.Title.BevelWidth = 3
    LeftAxis.Title.ShapeStyle = fosRoundRectangle
    LeftAxis.TitleSize = 10
    TopAxis.LabelsFormat.Font.Height = -13
    TabOrder = 0
    DefaultCanvas = 'TGDIPlusCanvas'
    PrintMargins = (
      33
      15
      33
      15)
    ColorPaletteIndex = 13
  end
  object ChartWaterFlow: TChart
    Left = 719
    Top = 0
    Width = 351
    Height = 441
    MarginBottom = 2
    MarginLeft = 5
    MarginRight = 2
    MarginTop = 2
    Title.Text.Strings = (
      '')
    Title.Visible = False
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    BottomAxis.Maximum = 2.000000000000000000
    BottomAxis.Minimum = -2.000000000000000000
    BottomAxis.Title.Caption = 'Flow/Sink [cm/d] / [mm/d]'
    BottomAxis.Title.Font.Height = -13
    Chart3DPercent = 1
    LeftAxis.Automatic = False
    LeftAxis.AutomaticMaximum = False
    LeftAxis.LabelsFormat.Font.Height = -13
    LeftAxis.Maximum = 5.000000000000000000
    LeftAxis.MaximumOffset = 10
    View3DOptions.OrthoAngle = 0
    TabOrder = 1
    DefaultCanvas = 'TGDIPlusCanvas'
    ColorPaletteIndex = 13
  end
  object ChartTension: TChart
    Left = 367
    Top = 0
    Width = 346
    Height = 441
    Legend.LegendStyle = lsSeries
    MarginBottom = 2
    MarginLeft = 5
    MarginRight = 2
    MarginTop = 2
    Title.Text.Strings = (
      '')
    Title.Visible = False
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    BottomAxis.Logarithmic = True
    BottomAxis.Maximum = 40000.000000000000000000
    BottomAxis.Minimum = 0.100000000000000000
    BottomAxis.Title.Caption = 'Tension [hPa]'
    BottomAxis.Title.Font.Height = -13
    Chart3DPercent = 1
    LeftAxis.Automatic = False
    LeftAxis.AutomaticMaximum = False
    LeftAxis.LabelsFormat.Font.Height = -13
    LeftAxis.Maximum = 5.000000000000000000
    View3DOptions.OrthoAngle = 0
    TabOrder = 2
    DefaultCanvas = 'TGDIPlusCanvas'
    ColorPaletteIndex = 13
  end
end
