object Form1: TForm1
  Left = 200
  Top = 125
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'MMtoD '
  ClientHeight = 535
  ClientWidth = 758
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 758
    Height = 535
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 0
    object StatusBar1: TStatusBar
      Left = 1
      Top = 515
      Width = 756
      Height = 19
      Panels = <>
      SimplePanel = False
    end
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 756
      Height = 441
      ActivePage = TabSheet4
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = 'Modelmaker File'
        object Memo1: TMemo
          Left = 0
          Top = 0
          Width = 748
          Height = 413
          Align = alClient
          BorderStyle = bsNone
          Color = clNavy
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindow
          Font.Height = -13
          Font.Name = 'Lucida Console'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object TabSheet4: TTabSheet
        Caption = 'TempFile'
        ImageIndex = 3
        object MemoTemp: TMemo
          Left = 0
          Top = 0
          Width = 748
          Height = 413
          Align = alClient
          BorderStyle = bsNone
          Color = clTeal
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindow
          Font.Height = -13
          Font.Name = 'Lucida Console'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Output File'
        ImageIndex = 1
        object MemoOut: TMemo
          Left = 0
          Top = 0
          Width = 748
          Height = 413
          Align = alClient
          BorderStyle = bsNone
          Color = 14679039
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Lucida Console'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object TabSheet3: TTabSheet
        Caption = 'Optionen'
        ImageIndex = 2
        object Panel3: TPanel
          Left = 0
          Top = 0
          Width = 329
          Height = 413
          Align = alLeft
          BorderWidth = 5
          TabOrder = 0
          object GroupBox1: TGroupBox
            Left = 6
            Top = 6
            Width = 317
            Height = 105
            Align = alTop
            Caption = 'Ausgabe Form'
            TabOrder = 0
            object Label1: TLabel
              Left = 80
              Top = 36
              Width = 130
              Height = 13
              Caption = 'gelistete Variablen pro Zeile'
            end
            object Label7: TLabel
              Left = 80
              Top = 68
              Width = 87
              Height = 13
              Caption = 'Decimal Separator'
            end
            object DecSepEdit: TEdit
              Left = 16
              Top = 64
              Width = 14
              Height = 24
              Font.Charset = ANSI_CHARSET
              Font.Color = clWindowText
              Font.Height = -13
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              MaxLength = 1
              ParentFont = False
              TabOrder = 0
              Text = '.'
              OnChange = DecSepEditChange
            end
            object VarCountSpinEdit: TAdvSpinEdit
              Left = 16
              Top = 32
              Width = 33
              Height = 22
              Direction = spVertical
              ReturnIsTab = False
              Precision = 0
              SpinType = sptNormal
              Value = 0
              DateValue = 37533.7293107755
              HexValue = 0
              SpinFlat = False
              SpinTransparent = False
              MaxValue = 0
              MinValue = 0
              TabOrder = 1
            end
          end
          object Bezeichner: TGroupBox
            Left = 6
            Top = 111
            Width = 317
            Height = 129
            Align = alTop
            Caption = 'Bezeichner'
            TabOrder = 1
            object Label3: TLabel
              Left = 80
              Top = 28
              Width = 96
              Height = 13
              Caption = 'Variablenbezeichner'
            end
            object Label4: TLabel
              Left = 80
              Top = 60
              Width = 122
              Height = 13
              Caption = 'Defined value Bezeichner'
            end
            object Label5: TLabel
              Left = 80
              Top = 92
              Width = 124
              Height = 13
              Caption = 'Compartement Bezeichner'
            end
            object VarBezEdit: TEdit
              Left = 16
              Top = 24
              Width = 57
              Height = 21
              TabOrder = 0
              Text = 'TVar'
            end
            object ParBezEdit: TEdit
              Left = 16
              Top = 56
              Width = 57
              Height = 21
              TabOrder = 1
              Text = 'TPar'
            end
            object CompBezEdit: TEdit
              Left = 16
              Top = 84
              Width = 57
              Height = 21
              TabOrder = 2
              Text = 'TState'
            end
          end
          object Memo4: TMemo
            Left = 6
            Top = 240
            Width = 317
            Height = 167
            Align = alClient
            TabOrder = 2
          end
        end
        object Panel4: TPanel
          Left = 329
          Top = 0
          Width = 419
          Height = 413
          Align = alClient
          TabOrder = 1
        end
      end
    end
    object Panel2: TPanel
      Left = 1
      Top = 442
      Width = 756
      Height = 73
      Align = alBottom
      TabOrder = 2
      object Label2: TLabel
        Left = 517
        Top = 36
        Width = 114
        Height = 13
        Caption = 'Name der Ausgabedatei'
      end
      object Label6: TLabel
        Left = 365
        Top = 36
        Width = 134
        Height = 13
        Caption = 'Name der Temporären Datei'
      end
      object OpenButton: TButton
        Left = 8
        Top = 8
        Width = 65
        Height = 25
        Caption = 'Open'
        TabOrder = 0
        OnClick = OpenButtonClick
      end
      object outNameEdit: TEdit
        Left = 516
        Top = 13
        Width = 121
        Height = 21
        TabOrder = 1
        Text = 'output.txt'
      end
      object SaveButton: TButton
        Left = 80
        Top = 8
        Width = 113
        Height = 25
        Caption = 'Save Output File'
        Enabled = False
        TabOrder = 2
        OnClick = SaveButtonClick
      end
      object TempFileEdit: TEdit
        Left = 364
        Top = 13
        Width = 121
        Height = 21
        TabOrder = 3
        Text = 'TempFile.txt'
      end
    end
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'txt'
    Filter = 'Textfile|*.txt|Any File|*.*'
    Title = 'Source Code from ModelMaker'
    Left = 400
    Top = 8
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '*.txt'
    Filter = 'Textfile|*.txt|Delphi Source|*.pas|Any File|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Save Outputfile to'
    Left = 440
    Top = 8
  end
end
