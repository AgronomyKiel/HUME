object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'CSV Code Mittelwerte'
  ClientHeight = 246
  ClientWidth = 785
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = mm1
  OldCreateOrder = False
  DesignSize = (
    785
    246)
  PixelsPerInch = 96
  TextHeight = 13
  object lblSpeicherort: TLabel
    Left = 8
    Top = 167
    Width = 55
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Speicherort'
  end
  object lbl1: TLabel
    Left = 645
    Top = 198
    Width = 84
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'min f'#252'r Mittelwert'
  end
  object lbl2: TLabel
    Left = 645
    Top = 228
    Width = 61
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'Dateiendung'
  end
  object lbl3: TLabel
    Left = 398
    Top = 228
    Width = 137
    Height = 13
    Anchors = [akRight, akBottom]
    Caption = 'Time-/sonstige Spaltenbreite'
  end
  object lbl4: TLabel
    Left = 188
    Top = 228
    Width = 195
    Height = 13
    Anchors = [akRight, akBottom]
    Caption = 'nur f'#252'r FOPROQ relevant (sonst auf 0!):'
  end
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 785
    Height = 147
    Align = alTop
    BorderStyle = bsNone
    TabOrder = 0
  end
  object ListBox_Output: TListBox
    Left = 643
    Top = 24
    Width = 134
    Height = 105
    Anchors = [akTop, akRight]
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 1
  end
  object pb: TProgressBar
    Left = 69
    Top = 191
    Width = 560
    Height = 16
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
  end
  object chk_mittelwerte: TCheckBox
    Left = 645
    Top = 180
    Width = 82
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Mittelwerte'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object btn2: TButton
    Left = 8
    Top = 191
    Width = 55
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Start'
    TabOrder = 4
    OnClick = btn2Click
  end
  object edtSpeicherort: TEdit
    Left = 69
    Top = 164
    Width = 536
    Height = 21
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 5
  end
  object btn3: TButton
    Left = 604
    Top = 164
    Width = 25
    Height = 21
    Anchors = [akRight, akBottom]
    Caption = '...'
    TabOrder = 6
    OnClick = btn3Click
  end
  object cbb_minmittel: TComboBox
    Left = 735
    Top = 195
    Width = 33
    Height = 21
    Anchors = [akTop, akRight]
    TabOrder = 7
    Text = '1'
    Items.Strings = (
      '1'
      '2'
      '3'
      '4'
      '5'
      '6'
      '7'
      '8'
      '9')
  end
  object chk_statistik: TCheckBox
    Left = 645
    Top = 158
    Width = 104
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Statistik Spalten'
    TabOrder = 8
  end
  object chkWithCaptions: TCheckBox
    Left = 645
    Top = 135
    Width = 123
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'mit '#220'berschriften'
    Checked = True
    State = cbChecked
    TabOrder = 9
  end
  object edtDateiEndung: TEdit
    Left = 738
    Top = 222
    Width = 30
    Height = 21
    Anchors = [akTop, akRight]
    TabOrder = 10
    Text = 'txt'
  end
  object cbbSonstigeSpaltenBreite: TComboBox
    Left = 588
    Top = 221
    Width = 41
    Height = 21
    Anchors = [akRight, akBottom]
    ItemIndex = 0
    TabOrder = 11
    Text = '0'
    Items.Strings = (
      '0'
      '1'
      '2'
      '3'
      '4'
      '5'
      '6'
      '7'
      '8'
      '9'
      '10'
      '11'
      '12'
      '13'
      '14'
      '15')
  end
  object cbbTimeSpaltenbreite: TComboBox
    Left = 541
    Top = 221
    Width = 41
    Height = 21
    Anchors = [akRight, akBottom]
    ItemIndex = 0
    TabOrder = 12
    Text = '0'
    Items.Strings = (
      '0'
      '1'
      '2'
      '3'
      '4'
      '5'
      '6'
      '7'
      '8'
      '9'
      '10'
      '11'
      '12'
      '13'
      '14'
      '15')
  end
  object mm1: TMainMenu
    Left = 64
    Top = 32
    object Datei1: TMenuItem
      Caption = 'Datei'
      object mniOeffnen1: TMenuItem
        Caption = #214'ffnen'
        OnClick = mniOeffnen1Click
      end
    end
    object mniHilfe1: TMenuItem
      Caption = 'Hilfe'
      OnClick = mniHilfe1Click
    end
  end
end
