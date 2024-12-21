object Form1: TForm1
  Left = 174
  Top = 117
  Caption = 'Form1'
  ClientHeight = 247
  ClientWidth = 421
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
  object Label1: TLabel
    Left = 152
    Top = 111
    Width = 32
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 152
    Top = 130
    Width = 32
    Height = 13
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 152
    Top = 149
    Width = 32
    Height = 13
    Caption = 'Label3'
  end
  object Label4: TLabel
    Left = 18
    Top = 111
    Width = 112
    Height = 13
    Caption = 'horizontale Interpolation'
  end
  object Label5: TLabel
    Left = 18
    Top = 130
    Width = 115
    Height = 13
    Caption = 'horizontale Extrapolation'
  end
  object Label6: TLabel
    Left = 18
    Top = 149
    Width = 101
    Height = 13
    Caption = 'vertikale Interpolation'
  end
  object Label7: TLabel
    Left = 8
    Top = 8
    Width = 95
    Height = 13
    Caption = 'Eingabedatei (*.csv)'
  end
  object Label8: TLabel
    Left = 8
    Top = 35
    Width = 98
    Height = 13
    Caption = 'Ausgabedatei (*.csv)'
  end
  object Button1: TButton
    Left = 338
    Top = 129
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 0
    OnClick = Button1Click
  end
  object ButtonOpen: TButton
    Left = 360
    Top = 4
    Width = 42
    Height = 25
    Caption = 'File'
    TabOrder = 1
    OnClick = ButtonOpenClick
  end
  object EditOpen: TEdit
    Left = 112
    Top = 8
    Width = 245
    Height = 21
    TabOrder = 2
  end
  object ProgressBar1: TProgressBar
    Left = 121
    Top = 80
    Width = 232
    Height = 17
    Smooth = True
    TabOrder = 3
  end
  object RadioGroup1: TRadioGroup
    Left = 8
    Top = 62
    Width = 75
    Height = 43
    Caption = 'Standort'
    TabOrder = 4
  end
  object RBStandort1: TRadioButton
    Left = 18
    Top = 80
    Width = 25
    Height = 17
    Caption = '1'
    Checked = True
    TabOrder = 5
    TabStop = True
  end
  object RBStandort2: TRadioButton
    Left = 49
    Top = 80
    Width = 24
    Height = 17
    Caption = '2'
    TabOrder = 6
  end
  object EditSave: TEdit
    Left = 112
    Top = 35
    Width = 245
    Height = 21
    TabOrder = 7
  end
  object ButtonSave: TButton
    Left = 360
    Top = 35
    Width = 42
    Height = 25
    Caption = 'File'
    TabOrder = 8
    OnClick = ButtonSaveClick
  end
  object OpenDialog1: TOpenDialog
    Filter = '|*.csv'
    Left = 208
    Top = 120
  end
  object SaveDialog1: TSaveDialog
    Filter = '|*.csv'
    Left = 272
    Top = 120
  end
end
