object Form1: TForm1
  Left = 402
  Top = 145
  Width = 178
  Height = 72
  Caption = 'Exceldatum-Konverter'
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
  object DateTimePicker1: TDateTimePicker
    Left = 88
    Top = 8
    Width = 80
    Height = 21
    Date = 40160.815352094910000000
    Time = 40160.815352094910000000
    TabOrder = 0
    OnChange = DateTimePicker1Change
  end
  object Edit1: TEdit
    Left = 8
    Top = 8
    Width = 75
    Height = 21
    TabOrder = 1
    Text = 'Edit1'
    OnChange = Edit1Change
  end
end
