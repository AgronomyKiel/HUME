object Form1: TForm1
  Left = 422
  Top = 96
  Caption = 'TDR grav gesamt.csv Analyse'
  ClientHeight = 453
  ClientWidth = 707
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = mm1
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 344
    Top = 0
    Width = 34
    Height = 13
    Caption = 'N-Form'
  end
  object lbl2: TLabel
    Left = 392
    Top = 0
    Width = 44
    Height = 13
    Caption = 'N-Menge'
  end
  object lbl_block: TLabel
    Left = 442
    Top = 0
    Width = 27
    Height = 13
    Caption = 'Block'
  end
  object lbl3: TLabel
    Left = 8
    Top = 0
    Width = 42
    Height = 13
    Caption = 'Erntejahr'
  end
  object lbl4: TLabel
    Left = 72
    Top = 0
    Width = 15
    Height = 26
    Caption = 'VN'#13#10
  end
  object lbl6: TLabel
    Left = 160
    Top = 0
    Width = 28
    Height = 13
    Caption = 'Reihe'
  end
  object lbl7: TLabel
    Left = 198
    Top = 0
    Width = 30
    Height = 13
    Caption = 'Spalte'
  end
  object lbl8: TLabel
    Left = 240
    Top = 0
    Width = 53
    Height = 13
    Caption = 'Fruchtfolge'
  end
  object lbl5: TLabel
    Left = 104
    Top = 0
    Width = 40
    Height = 13
    Caption = 'Standort'
  end
  object lbl9: TLabel
    Left = 488
    Top = 0
    Width = 47
    Height = 13
    Caption = 'Aufwuchs'
  end
  object Label1: TLabel
    Left = 299
    Top = 0
    Width = 39
    Height = 13
    Caption = 'FF-Glied'
  end
  object Label2: TLabel
    Left = 616
    Top = 0
    Width = 72
    Height = 13
    Caption = 'In der Ausgabe'
  end
  object Label3: TLabel
    Left = 541
    Top = 0
    Width = 42
    Height = 13
    Caption = 'Methode'
  end
  object btn_start: TButton
    Left = 8
    Top = 120
    Width = 65
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = btn_startClick
  end
  object lst_n_form: TListBox
    Left = 344
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 1
  end
  object Memo1: TMemo
    Left = 0
    Top = 200
    Width = 707
    Height = 253
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 2
    WantTabs = True
    WordWrap = False
    ExplicitWidth = 634
    ExplicitHeight = 255
  end
  object lst_n_menge: TListBox
    Left = 392
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 3
  end
  object lst_block: TListBox
    Left = 440
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 4
  end
  object btn_save: TButton
    Left = 80
    Top = 120
    Width = 65
    Height = 25
    Caption = 'Speichern'
    TabOrder = 5
    OnClick = btn_saveClick
  end
  object lst_erntejahr: TListBox
    Left = 8
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 6
  end
  object lst_vn: TListBox
    Left = 56
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 7
  end
  object lst_standort: TListBox
    Left = 104
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 8
  end
  object lst_reihe: TListBox
    Left = 152
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 9
  end
  object lst_spalte: TListBox
    Left = 200
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 10
  end
  object lst_fruchtfolge: TListBox
    Left = 248
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 11
  end
  object lst_aufwuchs: TListBox
    Left = 488
    Top = 16
    Width = 40
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 12
  end
  object chk_mittelwert: TCheckBox
    Left = 8
    Top = 151
    Width = 81
    Height = 17
    Hint = 'Zu jedem Datum den Mittelwert der WGs berechnen'
    Caption = 'Mittelwerte'
    Checked = True
    ParentShowHint = False
    ShowHint = True
    State = cbChecked
    TabOrder = 13
  end
  object pb: TProgressBar
    Left = 352
    Top = 128
    Width = 176
    Height = 17
    Smooth = True
    Step = 1
    TabOrder = 14
  end
  object lst_ff_glied: TListBox
    Left = 296
    Top = 16
    Width = 41
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 15
  end
  object RadioGroup1: TRadioGroup
    Left = 185
    Top = 119
    Width = 136
    Height = 59
    Caption = 'min. f'#252'r Mittelwert'
    TabOrder = 16
  end
  object minMittel2: TRadioButton
    Left = 224
    Top = 140
    Width = 33
    Height = 17
    Caption = '2'
    TabOrder = 17
  end
  object minMittel3: TRadioButton
    Left = 255
    Top = 140
    Width = 33
    Height = 17
    Caption = '3'
    TabOrder = 18
  end
  object minMittel4: TRadioButton
    Left = 286
    Top = 140
    Width = 25
    Height = 17
    Caption = '4'
    TabOrder = 19
  end
  object minMittel1: TRadioButton
    Left = 192
    Top = 140
    Width = 26
    Height = 17
    Caption = '1'
    Checked = True
    TabOrder = 20
    TabStop = True
  end
  object ListBox1: TListBox
    Left = 616
    Top = 16
    Width = 72
    Height = 162
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 21
  end
  object lst_methode: TListBox
    Left = 534
    Top = 16
    Width = 60
    Height = 97
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 22
  end
  object dlgOpen1: TOpenDialog
    Left = 352
    Top = 144
  end
  object mm1: TMainMenu
    Left = 456
    Top = 152
    object Datei1: TMenuItem
      Caption = '&Datei'
      object open: TMenuItem
        Caption = 'Datei '#246'&ffnen'
        OnClick = openClick
      end
    end
  end
  object dlgSave1: TSaveDialog
    Left = 408
    Top = 144
  end
end
