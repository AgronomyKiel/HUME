object FormYearAnalysis: TFormYearAnalysis
  Left = 291
  Top = 103
  Caption = 'FormYearAnalysis'
  ClientHeight = 673
  ClientWidth = 936
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object LabelIniFileName: TLabel
    Left = 47
    Top = 9
    Width = 96
    Height = 20
    Caption = 'IniFileName'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object SpeedButtonIniFileName: TSpeedButton
    Left = 647
    Top = 8
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButtonIniFileNameClick
  end
  object LabelControlFileName: TLabel
    Left = 48
    Top = 120
    Width = 147
    Height = 20
    Caption = 'ControlFileHeader'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelStartYear: TLabel
    Left = 48
    Top = 256
    Width = 79
    Height = 20
    Caption = 'StartYear'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelEndYear: TLabel
    Left = 48
    Top = 304
    Width = 71
    Height = 20
    Caption = 'EndYear'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelInputDirectory: TLabel
    Left = 48
    Top = 440
    Width = 73
    Height = 20
    Caption = 'Directory'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object SpeedButtonInputDirectory: TSpeedButton
    Left = 648
    Top = 440
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButtonInputDirectoryClick
  end
  object LabelSowingDateName: TLabel
    Left = 47
    Top = 522
    Width = 144
    Height = 20
    Caption = 'SowingDateName'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelStartDate: TLabel
    Left = 445
    Top = 256
    Width = 80
    Height = 20
    Caption = 'StartDate'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object LabelEndDate: TLabel
    Left = 445
    Top = 304
    Width = 72
    Height = 20
    Caption = 'EndDate'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object LabelSowingDate: TLabel
    Left = 47
    Top = 360
    Width = 95
    Height = 20
    Caption = 'Sowingdate'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object LabelHarvestDate: TLabel
    Left = 445
    Top = 360
    Width = 99
    Height = 20
    Caption = 'Harvestdate'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object LabelWeatherfilename: TLabel
    Left = 48
    Top = 176
    Width = 144
    Height = 20
    Caption = 'WeatherFileName'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object SpeedButtonWeatherFileName: TSpeedButton
    Left = 648
    Top = 176
    Width = 23
    Height = 22
    Caption = '...'
    Visible = False
    OnClick = SpeedButtonWeatherFileNameClick
  end
  object LabelHarvestDateName: TLabel
    Left = 357
    Top = 522
    Width = 148
    Height = 20
    Caption = 'HarvestDateName'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelControlFile: TLabel
    Left = 485
    Top = 123
    Width = 103
    Height = 13
    Caption = 'LabelControlFileName'
    Visible = False
  end
  object LabelFirstWeather: TLabel
    Left = 240
    Top = 216
    Width = 86
    Height = 13
    Caption = 'LabelFirstWeather'
    Visible = False
  end
  object LabelLastWeather: TLabel
    Left = 536
    Top = 216
    Width = 87
    Height = 13
    Caption = 'LabelLastWeather'
    Visible = False
  end
  object EditInifileName: TEdit
    Left = 239
    Top = 8
    Width = 409
    Height = 21
    TabOrder = 0
    Text = 'Q:\WHEAT\Project\HS_99_13\hskage\I_Hohenschulen_Szenario_00.ini'
  end
  object EditControlFileName: TEdit
    Left = 240
    Top = 120
    Width = 201
    Height = 21
    TabOrder = 1
    Text = 'LT_Scenario_'
    OnChange = EditControlFileNameChange
  end
  object EditInputDirectory: TEdit
    Left = 233
    Top = 442
    Width = 409
    Height = 21
    TabOrder = 2
    Text = 'Q:\WHEAT\Project\LT_EastAnglia'
    Visible = False
    OnChange = EditInputDirectoryChange
  end
  object ButtonStart: TButton
    Left = 815
    Top = 8
    Width = 75
    Height = 25
    Caption = '&Start'
    TabOrder = 3
    Visible = False
    OnClick = ButtonStartClick
  end
  object SpinEditStartYear: TSpinEdit
    Left = 239
    Top = 258
    Width = 121
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 4
    Value = 1983
    OnChange = SpinEditStartYearChange
  end
  object SpinEditEndYear: TSpinEdit
    Left = 240
    Top = 306
    Width = 121
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 5
    Value = 2013
  end
  object DateTimePickerStartDate: TDateTimePicker
    Left = 550
    Top = 255
    Width = 121
    Height = 21
    Date = 41983.781033321750000000
    Time = 41983.781033321750000000
    ShowCheckbox = True
    TabOrder = 6
    Visible = False
  end
  object DateTimePickerEndDate: TDateTimePicker
    Left = 550
    Top = 307
    Width = 121
    Height = 21
    Date = 41983.781033321750000000
    Time = 41983.781033321750000000
    ShowCheckbox = True
    TabOrder = 7
    Visible = False
  end
  object EditSowingDateString: TEdit
    Left = 239
    Top = 524
    Width = 89
    Height = 21
    TabOrder = 8
    Text = 'Sowingdate'
  end
  object DateTimePickerSowingDate: TDateTimePicker
    Left = 240
    Top = 360
    Width = 121
    Height = 21
    Date = 41983.781033321750000000
    Time = 41983.781033321750000000
    ShowCheckbox = True
    Enabled = False
    TabOrder = 9
    Visible = False
  end
  object DateTimePickerHarvestDate: TDateTimePicker
    Left = 550
    Top = 359
    Width = 121
    Height = 21
    Date = 41983.781033321750000000
    Time = 41983.781033321750000000
    ShowCheckbox = True
    Enabled = False
    TabOrder = 10
    Visible = False
  end
  object EditWeatherfileName: TEdit
    Left = 240
    Top = 176
    Width = 409
    Height = 21
    TabOrder = 11
    Text = 'Q:\WEATHER\MARS\UKEastAnglia\UKWeatherEastAnglia_modified.txt'
    Visible = False
  end
  object EditHarvestDateName: TEdit
    Left = 549
    Top = 524
    Width = 89
    Height = 21
    TabOrder = 12
    Text = 'Harvestdate'
  end
  object OpenDialog1: TOpenDialog
    Left = 848
    Top = 552
  end
  object OpenDialogDirectory: TOpenDialog
    Options = [ofHideReadOnly, ofNoValidate, ofEnableSizing]
    Left = 752
    Top = 552
  end
end
