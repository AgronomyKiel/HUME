object FormMod: TFormMod
  Left = 71
  Top = 46
  ActiveControl = ComboBoxSubMod
  Caption = 'Model'
  ClientHeight = 659
  ClientWidth = 1096
  Color = clBtnFace
  ParentFont = True
  Menu = MainMenu1
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object StatusBarMain: TStatusBar
    Left = 0
    Top = 636
    Width = 1096
    Height = 23
    Panels = <
      item
        Width = 360
      end
      item
        Width = 220
      end
      item
        Width = 180
      end>
  end
  object PageControl: TPageControl
    AlignWithMargins = True
    Left = 3
    Top = 44
    Width = 1090
    Height = 589
    ActivePage = TabSheetModelDiagram
    Align = alClient
    HotTrack = True
    TabOrder = 1
    TabPosition = tpBottom
    object TabSheetGlobal: TTabSheet
      AlignWithMargins = True
      Caption = 'Global'
      ParentShowHint = False
      ShowHint = True
      DesignSize = (
        1076
        555)
      object btnCheckButton1: TSpeedButton
        Left = 3
        Top = 517
        Width = 161
        Height = 22
        Hint = 'Reinit/ckeck extern vars'
        Anchors = [akBottom]
        Caption = 'Reinit and check ExVars'
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000360000002800000010000000100000000100
          18000000000000030000130B0000130B00000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000000281B0B442E12281B0B05030121160934230E3F2B1143
          2E123F2B1134230E2116090503010000000000000000000000004D3618EDCDA3
          4D36183727119A7E5BC8AA83E2C299ECCCA2E2C299C8AA839A7E5B3727111710
          07000000000000000000583F1FD9B98FD9B98FB4966FD8B88EE0C6A5E5CFB2E8
          D4BAE5CFB2E0C6A5DABC94B4966F3F2D16161008000000000000634926D7B78D
          D7B78DD7B78DD7B78DA79173816847674D2A816847A79173D5C0A4D7B78DAF91
          6A4130190000000000006F532ED9BB94D9BB94D9BB94D9BB946F532E42311B03
          020119130A392B187B603DE8D6BFE8D6BF6F532E0000000000007A5C35E2CBAD
          E2CBADE2CBADE2CBADE2CBAD7A5C3548362000000000000048361F7A5C357A5C
          3548361F00000000000083643BF5ECE2F5ECE2F5ECE2F5ECE2F5ECE2F5ECE283
          643B000000000000000000000000000000000000000000000000513E2589693F
          89693F89693F89693F89693F89693F513E25281B0B442E12442E12442E12442E
          12442E12442E12281B0B00000000000000000000000000000000000000000000
          00004D3618F4E1C8EDCDA3EDCDA3EDCDA3EDCDA3EDCDA34D3618000000000000
          342512583F1F583F1F342512000000000000342512583F1FE8D5BCD9B98FD9B9
          8FD9B98FD9B98F583F1F000000000000634926DCC19DD7B78D6F553133261416
          10080302013A2B16634926D7B78DD7B78DD7B78DD7B78D634926000000000000
          49371EBFA98EDDC3A0CCAE87A68963876A45725631876A45A68963D9BB94DDC3
          A0D9BB94D9BB946F532E0000000000001E170D584226CDBAA2E7D5BDE5D0B5E3
          CCAFE2CBADE3CCAFE5D0B5E7D5BDCDBAA2EEE0CEE2CBAD7A5C35000000000000
          000000281E125D482ABAA58BDBCDBBEDE2D6F4EBE1EDE2D6DBCDBBBAA58B5D48
          2A83643BF5ECE283643B00000000000000000000000009070442321E6951307F
          623B88683F7F623B69513042321E090704513E2589693F513E25}
        ParentShowHint = False
        ShowHint = True
        OnClick = CheckButtonClick
      end
      object GroupBoxIniFileEdits: TGroupBox
        Left = 3
        Top = 0
        Width = 1053
        Height = 353
        Caption = 'IniFile settings'
        Color = clGradientActiveCaption
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentBackground = False
        ParentColor = False
        ParentFont = False
        TabOrder = 2
        DesignSize = (
          1053
          353)
        object GroupBoxControlFileName: TGroupBox
          Left = 18
          Top = 20
          Width = 820
          Height = 49
          Caption = 'Controlfile'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Right = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 0
          object btnButtonChangeControlFile: TSpeedButton
            Left = 792
            Top = 19
            Width = 21
            Height = 28
            Hint = 'Change control file'
            Align = alRight
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              1800000000000003000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
              1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
              001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
              E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
              B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
              61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
              F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
              E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
              57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
              AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
              DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
              4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
              FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
              D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
              48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
              6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
              D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
              45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
              F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
              55A90055A90015930015930015934793F64793F64793F60015930000000058AE
              91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
              FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
              0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
            ParentShowHint = False
            ShowHint = True
            OnClick = btnButtonChangeControlFileClick
          end
          object EditControlFile: TEdit
            AlignWithMargins = True
            Left = 10
            Top = 22
            Width = 750
            Height = 22
            Align = alLeft
            BevelWidth = 5
            ReadOnly = True
            TabOrder = 0
          end
        end
        object GroupBoxEndtime: TGroupBox
          Left = 225
          Top = 75
          Width = 188
          Height = 49
          Caption = 'Endtime'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Top = 2
          Padding.Right = 5
          Padding.Bottom = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 1
          object EditEndTime: TEdit
            Left = 7
            Top = 21
            Width = 77
            Height = 21
            Align = alLeft
            TabOrder = 0
            OnChange = EditEndTimeChange
          end
          object EndTimePicker: TDateTimePicker
            Left = 101
            Top = 21
            Width = 80
            Height = 21
            Align = alRight
            Date = 37515.000000000000000000
            Time = 0.827903622703161100
            TabOrder = 1
            OnChange = EndTimePickerChange
          end
        end
        object GroupBoxTimestep: TGroupBox
          Left = 446
          Top = 75
          Width = 70
          Height = 49
          Caption = 'Timestep'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Top = 2
          Padding.Right = 5
          Padding.Bottom = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 2
          object EditTimeStep: TEdit
            Left = 7
            Top = 21
            Width = 56
            Height = 21
            Align = alClient
            TabOrder = 0
            Text = '1'
          end
        end
        object GroupBoxStateIniFile: TGroupBox
          Left = 18
          Top = 127
          Width = 820
          Height = 49
          Caption = 'StateIniFile'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Right = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 3
          object SpeedButtonChangeStateIniFile: TSpeedButton
            Left = 792
            Top = 19
            Width = 21
            Height = 28
            Hint = 'Change StateInifile name'
            Align = alRight
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              1800000000000003000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
              1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
              001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
              E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
              B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
              61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
              F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
              E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
              57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
              AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
              DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
              4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
              FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
              D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
              48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
              6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
              D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
              45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
              F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
              55A90055A90015930015930015934793F64793F64793F60015930000000058AE
              91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
              FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
              0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
            ParentShowHint = False
            ShowHint = True
            OnClick = SpeedButtonChangeStateIniFileClick
          end
          object EditStateIniFileName: TEdit
            AlignWithMargins = True
            Left = 10
            Top = 22
            Width = 750
            Height = 22
            Align = alLeft
            ReadOnly = True
            TabOrder = 0
            OnMouseMove = EditStateIniFileNameMouseMove
          end
        end
        object GroupBoxPamIniFileName: TGroupBox
          Left = 18
          Top = 184
          Width = 820
          Height = 48
          Anchors = []
          Caption = 'ParamIniFile'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Top = 2
          Padding.Right = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 4
          object SpeedButtonChangeParamIniFile: TSpeedButton
            Left = 792
            Top = 21
            Width = 21
            Height = 25
            Hint = 'Change ParamInifile name'
            Align = alRight
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              1800000000000003000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
              1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
              001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
              E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
              B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
              61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
              F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
              E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
              57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
              AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
              DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
              4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
              FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
              D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
              48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
              6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
              D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
              45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
              F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
              55A90055A90015930015930015934793F64793F64793F60015930000000058AE
              91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
              FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
              0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
            ParentShowHint = False
            ShowHint = True
            OnClick = SpeedButtonChangeParamIniFileClick
          end
          object EditParamIniFileName: TEdit
            AlignWithMargins = True
            Left = 10
            Top = 24
            Width = 750
            Height = 19
            Align = alLeft
            ReadOnly = True
            TabOrder = 0
            OnMouseMove = EditParamIniFileNameMouseMove
          end
        end
        object GroupBoxWeatherFile: TGroupBox
          Left = 18
          Top = 238
          Width = 820
          Height = 48
          Caption = 'WeatherfileName'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Right = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 5
          object SpeedButtonChangeWeatherFile: TSpeedButton
            Left = 792
            Top = 19
            Width = 21
            Height = 27
            Hint = 'Change weather file name'
            Align = alRight
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              1800000000000003000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
              1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
              001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
              E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
              B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
              61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
              F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
              E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
              57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
              AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
              DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
              4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
              FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
              D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
              48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
              6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
              D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
              45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
              F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
              55A90055A90015930015930015934793F64793F64793F60015930000000058AE
              91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
              FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
              0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
            ParentShowHint = False
            ShowHint = True
            OnClick = SpeedButtonChangeWeatherFileClick
          end
          object EditWeatherfile: TEdit
            AlignWithMargins = True
            Left = 10
            Top = 22
            Width = 750
            Height = 21
            Align = alLeft
            ParentShowHint = False
            ReadOnly = True
            ShowHint = True
            TabOrder = 0
            OnMouseMove = EditWeatherfileMouseMove
          end
        end
        object GroupBoxSaveIniFileChanges: TGroupBox
          Left = 640
          Top = 292
          Width = 198
          Height = 47
          Caption = 'SaveChanges'
          Color = clGradientInactiveCaption
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Right = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 6
          object btnButtonSaveIntegrChanges1: TSpeedButton
            Left = 7
            Top = 19
            Width = 60
            Height = 26
            Hint = 'Save Changes to actual Inifile'
            Align = alLeft
            Caption = 'Save'
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              18000000000000030000130B0000130B00000000000000000000FFFFFF000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
              19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
              C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
              74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
              CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
              A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
              56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
              502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
              A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
              53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
              502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
              A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
              34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
              A78B60765E3DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF765E
              3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
              B69E798C785DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8C78
              5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
              5231085231085231085231085231085231085231085231085231085231085231
              08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
            ParentShowHint = False
            ShowHint = True
            OnClick = ButtonSaveIntegrChangesClick
          end
          object btnButtonSaveToNewIniFile1: TSpeedButton
            Left = 111
            Top = 19
            Width = 80
            Height = 26
            Hint = 'Save Changes to new/other Inifile'
            Align = alRight
            Caption = 'Save as...'
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              18000000000000030000130B0000130B00000000000000000000FFFFFF000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
              19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
              C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
              74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
              CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
              A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
              56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
              502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
              A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
              53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
              502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
              A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
              34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFB5B5F7B5B5F7B5
              B5F7B5B5F7B5B5F7FFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
              A78B60765E3DFFFFFF2525EA2525EA2525EA2525EA2525EAD8D8FBFFFFFF765E
              3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFBEBEF8BEBEF8BE
              BEF8BEBEF8BEBEF8BEBEF8FFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
              B69E798C785DFFFFFF4848ED4848ED4848ED4848ED4848ED4848EDFFFFFF8C78
              5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
              5231085231085231085231085231085231085231085231085231085231085231
              08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
            ParentShowHint = False
            ShowHint = True
            OnClick = ButtonSaveToNewIniFileClick
          end
        end
      end
      object GroupBoxStarttime: TGroupBox
        Left = 21
        Top = 73
        Width = 188
        Height = 51
        Margins.Left = 1
        Margins.Top = 1
        Margins.Right = 1
        Margins.Bottom = 1
        Caption = 'Starttime'
        Color = clGradientInactiveCaption
        Padding.Left = 5
        Padding.Top = 2
        Padding.Right = 5
        Padding.Bottom = 5
        ParentBackground = False
        ParentColor = False
        TabOrder = 0
        object EditStartTime: TEdit
          Left = 7
          Top = 19
          Width = 77
          Height = 25
          Align = alLeft
          TabOrder = 0
          OnChange = EditStartTimeChange
        end
        object DateTimePickerStart: TDateTimePicker
          Left = 101
          Top = 19
          Width = 80
          Height = 25
          Align = alRight
          Date = 37515.000000000000000000
          Time = 0.827862013902631600
          TabOrder = 1
          OnChange = StartTimePickerChange
        end
      end
      object GroupBoxWeatherDates: TGroupBox
        Left = 21
        Top = 292
        Width = 284
        Height = 46
        Caption = 'Weather Data'
        Color = clGradientInactiveCaption
        ParentBackground = False
        ParentColor = False
        TabOrder = 1
        object LabelWeatherDataFirstEntry: TLabel
          Left = 11
          Top = 17
          Width = 55
          Height = 15
          Caption = 'First Entry:'
        end
        object FWDLabel: TLabel
          Left = 77
          Top = 17
          Width = 42
          Height = 13
          Caption = 'FirstData'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object LabelWeatherDataLatEntry: TLabel
          Left = 149
          Top = 17
          Width = 54
          Height = 15
          Caption = 'Last Entry:'
        end
        object LWDLabel: TLabel
          Left = 213
          Top = 17
          Width = 43
          Height = 13
          Caption = 'LastData'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
      end
      object GroupBoxOutput: TGroupBox
        Left = 3
        Top = 359
        Width = 1053
        Height = 146
        Caption = 'Output'
        Color = clDarkseagreen
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        Padding.Left = 5
        Padding.Right = 5
        ParentBackground = False
        ParentColor = False
        ParentFont = False
        TabOrder = 4
        object GroupBoxOutputDirectory: TGroupBox
          Left = 18
          Top = 17
          Width = 820
          Height = 48
          Caption = 'OutputDirectory'
          Color = clMoneyGreen
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Right = 5
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 0
          object SpeedButtonOutputDirectory: TSpeedButton
            Left = 792
            Top = 19
            Width = 21
            Height = 27
            Hint = 'Change output directory'
            Align = alRight
            Flat = True
            Glyph.Data = {
              36030000424D3603000000000000360000002800000010000000100000000100
              1800000000000003000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
              1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
              001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
              E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
              B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
              61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
              F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
              E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
              57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
              AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
              DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
              4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
              FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
              D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
              48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
              6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
              D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
              45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
              F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
              55A90055A90015930015930015934793F64793F64793F60015930000000058AE
              91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
              FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
              0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
            ParentShowHint = False
            ShowHint = True
            OnClick = SpeedButtonOutputDirectoryClick
          end
          object EditOutputDirectory: TEdit
            Left = 7
            Top = 17
            Width = 748
            Height = 25
            Hint = 'Actual output directory'
            ParentShowHint = False
            ReadOnly = True
            ShowHint = True
            TabOrder = 0
            OnMouseMove = EditWeatherfileMouseMove
          end
        end
        object GroupBoxContinousOutput: TGroupBox
          Left = 18
          Top = 71
          Width = 239
          Height = 50
          Caption = 'SubModel Level Output control'
          Color = clMoneyGreen
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Padding.Left = 5
          Padding.Right = 5
          Padding.Bottom = 2
          ParentBackground = False
          ParentColor = False
          ParentFont = False
          TabOrder = 1
          object ComboBoxContOutput: TComboBox
            Left = 7
            Top = 19
            Width = 210
            Height = 25
            Hint = 
              'Control for generating output on every time step. Will not chang' +
              'e CheckBox settings, but may inactivate output generally or spec' +
              'ific for SubModels'
            Align = alLeft
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
            Text = 'NoContOutputFiles'
            OnChange = ComboBoxContOutputChange
            Items.Strings = (
              'NoContOutputFiles'
              'AllContoutputFiles'
              'SubmodelSpecificContOutputFiles')
          end
        end
        object GroupBox1: TGroupBox
          Left = 280
          Top = 71
          Width = 558
          Height = 50
          Caption = 'Set all Checkboxes'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
          object SpeedButtonNoContOutput: TSpeedButton
            Left = 205
            Top = 16
            Width = 164
            Height = 31
            Hint = 'Set all Continous ouptput options of all Elements to false'
            Caption = 'NoContOutputChecks'
            Glyph.Data = {
              AA030000424DAA03000000000000360000002800000011000000110000000100
              1800000000007403000000000000000000000000000000000000FFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FF00FFFFFFFFFFFFFFFFFFA7A7A76B6B6B626262626262626262626262626262
              6262626262626B6B6BB0B0B0FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFB1B1B198
              9898E1E1E1F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3EAEAEA989898
              A6A6A6FFFFFFFFFFFF00FFFFFFFFFFFF6C6C6CEAEAEAF3F3F3F3F3F3F3F3F3F3
              F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3E1E1E16C6C6CFFFFFFFFFFFF00FFFF
              FFFFFFFF626262F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3
              F3F3F3F3F3F3F3F3626262FFFFFFFFFFFF00FFFFFFFFFFFF626262F3F3F3F3F3
              F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3626262FF
              FFFFFFFFFF00FFFFFFFFFFFF626262F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3
              F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3626262FFFFFFFFFFFF00FFFFFFFFFFFF
              626262F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3
              F3F3F3F3626262FFFFFFFFFFFF00FFFFFFFFFFFF626262F3F3F3F3F3F3F3F3F3
              F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3626262FFFFFFFFFF
              FF00FFFFFFFFFFFF626262F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3
              F3F3F3F3F3F3F3F3F3F3F3F3626262FFFFFFFFFFFF00FFFFFFFFFFFF626262F3
              F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3
              626262FFFFFFFFFFFF00FFFFFFFFFFFF6C6C6CE1E1E1F3F3F3F3F3F3F3F3F3F3
              F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3EAEAEA6C6C6CFFFFFFFFFFFF00FFFF
              FFFFFFFFA6A6A6999999EAEAEAF3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3
              F3F3E1E1E1989898B1B1B1FFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFB0B0B06C6C
              6C6262626262626262626262626262626262626262626C6C6CA7A7A7FFFFFFFF
              FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFF00}
            ParentShowHint = False
            ShowHint = True
            OnClick = SpeedButtonNoContOutputClick
          end
          object SpeedButtonAllContOutput: TSpeedButton
            Left = 2
            Top = 19
            Width = 177
            Height = 29
            Hint = 'Sets all Output options at entity level to true'
            Align = alLeft
            Caption = 'AllContOutputChecks'
            Glyph.Data = {
              AA030000424DAA03000000000000360000002800000011000000110000000100
              1800000000007403000000000000000000000000000000000000FFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FF00FFFFFFFFFFFFFFFFFFD8A570BD6910B85F00B85F00B85F00B85F00B85F00
              B85F00B85F00BD6910DCAF80FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFDCB080B8
              5F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00
              D7A570FFFFFFFFFFFF00FFFFFFFFFFFFBD6910B85F00B85F00B85F00B85F00B8
              5F00B85F00B85F00B85F00B85F00B85F00B85F00BC6910FFFFFFFFFFFF00FFFF
              FFFFFFFFB85F00B85F00B85F00B85F00B85F00BC6910B85F00B85F00B85F00B8
              5F00B85F00B85F00B85F00FFFFFFFFFFFF00FFFFFFFFFFFFB85F00B85F00B85F
              00B85F00D39B60F6EBDFD29B5FB85F00B85F00B85F00B85F00B85F00B85F00FF
              FFFFFFFFFF00FFFFFFFFFFFFB85F00B85F00B85F00D39B60E4C39FB85F00E5C3
              A0D29B5FB85F00B85F00B85F00B85F00B85F00FFFFFFFFFFFF00FFFFFFFFFFFF
              B85F00B85F00B85F00CE9150B85F00B85F00B85F00E5C3A0D29B5FB85F00B85F
              00B85F00B85F00FFFFFFFFFFFF00FFFFFFFFFFFFB85F00B85F00B85F00B85F00
              B85F00B85F00B85F00B85F00E5C3A0D29B5FB85F00B85F00B85F00FFFFFFFFFF
              FF00FFFFFFFFFFFFB85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00
              B85F00D39B5FB85F00B85F00B85F00FFFFFFFFFFFF00FFFFFFFFFFFFB85F00B8
              5F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00
              B85F00FFFFFFFFFFFF00FFFFFFFFFFFFBD6910B85F00B85F00B85F00B85F00B8
              5F00B85F00B85F00B85F00B85F00B85F00B85F00BC6910FFFFFFFFFFFF00FFFF
              FFFFFFFFD7A56FB85F00B85F00B85F00B85F00B85F00B85F00B85F00B85F00B8
              5F00B85F00B85F00DCB080FFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFDBAF7FBD69
              10B85F00B85F00B85F00B85F00B85F00B85F00B85F00BD6910D8A670FFFFFFFF
              FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFF00}
            OnClick = SpeedButtonAllContOutputClick
          end
        end
      end
      object BitBtnMergeWeatherFN: TBitBtn
        Left = 182
        Top = 512
        Width = 124
        Height = 40
        Hint = 'Combine all Weather file into one'
        Align = alCustom
        Anchors = [akBottom]
        BiDiMode = bdLeftToRight
        Caption = 'WeatherFNs'
        ParentBiDiMode = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnClick = BitBtnMergeWeatherFNClick
      end
    end
    object TabSheetModelDiagram: TTabSheet
      Caption = 'ModelDiagram'
    end
    object TabSheetParameter: TTabSheet
      BorderWidth = 1
      Caption = 'Parameters'
      OnExit = ButtonSaveParamsClick
      OnShow = TabSheetParameterShow
      object AdvStringGridParam: TAdvStringGrid
        Left = 0
        Top = 44
        Width = 1080
        Height = 515
        Cursor = crDefault
        Align = alClient
        DefaultColWidth = 120
        FixedCols = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goColMoving, goEditing]
        ScrollBars = ssBoth
        TabOrder = 0
        GridLineColor = 15855083
        GridFixedLineColor = 13745060
        OnButtonClick = AdvStringGridParamButtonClick
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 10344697
        ActiveCellColorTo = 6210033
        AutoNumAlign = True
        Bands.Active = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = 16513526
        ControlLook.FixedGradientTo = 15260626
        ControlLook.FixedGradientHoverFrom = 15000287
        ControlLook.FixedGradientHoverTo = 14406605
        ControlLook.FixedGradientHoverMirrorFrom = 14406605
        ControlLook.FixedGradientHoverMirrorTo = 13813180
        ControlLook.FixedGradientHoverBorder = 12033927
        ControlLook.FixedGradientDownFrom = 14991773
        ControlLook.FixedGradientDownTo = 14991773
        ControlLook.FixedGradientDownMirrorFrom = 14991773
        ControlLook.FixedGradientDownMirrorTo = 14991773
        ControlLook.FixedGradientDownBorder = 14991773
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
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'MS Sans Serif'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedColWidth = 120
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -13
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        Look = glOffice2007
        MouseActions.CaretPositioning = True
        MouseActions.ColSelect = True
        MouseActions.RowSelect = True
        Navigation.AllowDeleteRow = True
        Navigation.AdvanceAutoEdit = False
        Navigation.AdvanceDirection = adTopBottom
        Navigation.AllowClipboardShortCuts = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -13
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -13
        PrintSettings.HeaderFont.Name = 'MS Sans Serif'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -13
        PrintSettings.FooterFont.Name = 'MS Sans Serif'
        PrintSettings.FooterFont.Style = []
        PrintSettings.Borders = pbNoborder
        PrintSettings.Centered = False
        PrintSettings.PagePrefix = 'page'
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 18
        SearchFooter.Color = 16513526
        SearchFooter.ColorTo = clNone
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
        SelectionColor = 6210033
        URLColor = clBlack
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          120
          120
          82
          83
          92)
      end
      object ToolBarParSheet: TToolBar
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1074
        Height = 38
        Anchors = []
        BorderWidth = 2
        ButtonHeight = 23
        EdgeBorders = [ebLeft, ebTop, ebRight, ebBottom]
        List = True
        AllowTextButtons = True
        TabOrder = 1
        DesignSize = (
          1062
          26)
        object ButtonSaveParam: TBitBtn
          Left = 0
          Top = 0
          Width = 60
          Height = 23
          Hint = 'Save Changes to this Inifile'
          Caption = 'Save'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = ButtonSaveParamsClick
        end
        object BitBtnSaveParamTo: TBitBtn
          Left = 60
          Top = 0
          Width = 80
          Height = 23
          Hint = 'Save as...'
          Caption = 'Save as...'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFB5B5F7B5B5F7B5
            B5F7B5B5F7B5B5F7FFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFF2525EA2525EA2525EA2525EA2525EAD8D8FBFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFBEBEF8BEBEF8BE
            BEF8BEBEF8BEBEF8BEBEF8FFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFF4848ED4848ED4848ED4848ED4848ED4848EDFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnClick = BitBtnSaveParamToClick
        end
        object LabelparamFileName: TLabel
          Left = 140
          Top = 0
          Width = 72
          Height = 23
          Alignment = taCenter
          Caption = '  IniFileName '
          Layout = tlCenter
        end
        object EditParamFileName: TEdit
          Left = 212
          Top = 0
          Width = 753
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          ParentShowHint = False
          ReadOnly = True
          ShowHint = True
          TabOrder = 0
          Text = 'EditParamFileName'
        end
        object SpeedChangeParamIniFile: TSpeedButton
          Left = 965
          Top = 0
          Width = 22
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
            1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
            001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
            E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
            B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
            61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
            F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
            E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
            57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
            AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
            DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
            4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
            FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
            D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
            48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
            6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
            D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
            45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
            F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
            55A90055A90015930015930015934793F64793F64793F60015930000000058AE
            91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
            FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
            0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
          OnClick = SpeedChangeParamIniFileClick
        end
      end
    end
    object TabSheetState: TTabSheet
      BorderWidth = 1
      Caption = 'State Variables'
      OnExit = ButtonSaveStateClick
      OnShow = TabSheetStateShow
      object AdvStringGridState: TAdvStringGrid
        Left = 0
        Top = 41
        Width = 1080
        Height = 518
        Cursor = crDefault
        Align = alClient
        ColCount = 9
        DefaultColWidth = 120
        FixedCols = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColMoving, goEditing]
        ScrollBars = ssBoth
        TabOrder = 0
        OnButtonClick = AdvStringGridStateButtonClick
        OnCheckBoxClick = AdvStringGridStateCheckBoxClick
        OnEditCellDone = AdvStringGridStateEditCellDone
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 15387318
        AutoNumAlign = True
        Bands.Active = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = clWhite
        ControlLook.FixedGradientTo = clBtnFace
        ControlLook.FixedGradientHoverFrom = 13619409
        ControlLook.FixedGradientHoverTo = 12502728
        ControlLook.FixedGradientHoverMirrorFrom = 12502728
        ControlLook.FixedGradientHoverMirrorTo = 11254975
        ControlLook.FixedGradientDownFrom = 8816520
        ControlLook.FixedGradientDownTo = 7568510
        ControlLook.FixedGradientDownMirrorFrom = 7568510
        ControlLook.FixedGradientDownMirrorTo = 6452086
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
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'MS Sans Serif'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedColWidth = 150
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -13
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        MouseActions.WheelIncrement = 1
        MouseActions.WheelAction = waScroll
        Navigation.AdvanceAutoEdit = False
        Navigation.AdvanceDirection = adTopBottom
        Navigation.AllowClipboardShortCuts = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -13
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -13
        PrintSettings.HeaderFont.Name = 'MS Sans Serif'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -13
        PrintSettings.FooterFont.Name = 'MS Sans Serif'
        PrintSettings.FooterFont.Style = []
        PrintSettings.Borders = pbNoborder
        PrintSettings.Centered = False
        PrintSettings.PagePrefix = 'page'
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 20
        SearchFooter.ColorTo = 13160660
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
        URLColor = clBlack
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          150
          120
          95
          77
          68
          64
          58
          54
          120)
      end
      object ToolBarStateSheet: TToolBar
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1074
        Height = 35
        BorderWidth = 2
        ButtonHeight = 20
        EdgeBorders = [ebLeft, ebTop, ebRight, ebBottom]
        List = True
        AllowTextButtons = True
        TabOrder = 1
        DesignSize = (
          1062
          23)
        object ButtonSaveState: TBitBtn
          AlignWithMargins = True
          Left = 0
          Top = 0
          Width = 60
          Height = 20
          Hint = 'Save changes of actual IniFile'
          Caption = 'Save'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          Spacing = 2
          TabOrder = 1
          OnClick = ButtonSaveStateClick
        end
        object BitBtnSaveStateTo: TBitBtn
          AlignWithMargins = True
          Left = 60
          Top = 0
          Width = 80
          Height = 20
          Hint = 'Save as...'
          Caption = 'Save as...'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFB5B5F7B5B5F7B5
            B5F7B5B5F7B5B5F7FFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFF2525EA2525EA2525EA2525EA2525EAD8D8FBFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFBEBEF8BEBEF8BE
            BEF8BEBEF8BEBEF8BEBEF8FFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFF4848ED4848ED4848ED4848ED4848ED4848EDFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnClick = BitBtnSaveStateToClick
        end
        object LabelStateFileName: TLabel
          AlignWithMargins = True
          Left = 140
          Top = 0
          Width = 73
          Height = 20
          Caption = '   IniFilename '
          Layout = tlCenter
        end
        object EditStateFileName: TEdit
          Left = 213
          Top = 0
          Width = 708
          Height = 20
          Anchors = [akLeft, akTop, akRight]
          ParentShowHint = False
          ReadOnly = True
          ShowHint = True
          TabOrder = 0
          Text = 'EditStateFileName'
        end
        object ToggleSwitchStateContOutput: TToggleSwitch
          Left = 921
          Top = 0
          Width = 77
          Height = 20
          Alignment = taLeftJustify
          ParentShowHint = False
          ShowHint = True
          State = tssOn
          StateCaptions.CaptionOn = '  on'
          StateCaptions.CaptionOff = '  off'
          TabOrder = 3
          ThumbColor = clCrimson
          OnClick = ToggleSwitchStateContOutputClick
        end
      end
    end
    object TabSheetVariables: TTabSheet
      BorderWidth = 1
      Caption = 'Variables'
      OnShow = TabSheetVariablesShow
      object AdvStringGridVar: TAdvStringGrid
        Left = 0
        Top = 24
        Width = 1080
        Height = 535
        Cursor = crDefault
        Align = alClient
        ColCount = 7
        DefaultColWidth = 120
        FixedCols = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
        ScrollBars = ssBoth
        TabOrder = 0
        OnButtonClick = AdvStringGridVarButtonClick
        OnCheckBoxMouseUp = AdvStringGridVarCheckBoxClick
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 15387318
        AutoNumAlign = True
        Bands.Active = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = clWhite
        ControlLook.FixedGradientTo = clBtnFace
        ControlLook.FixedGradientHoverFrom = 13619409
        ControlLook.FixedGradientHoverTo = 12502728
        ControlLook.FixedGradientHoverMirrorFrom = 12502728
        ControlLook.FixedGradientHoverMirrorTo = 11254975
        ControlLook.FixedGradientDownFrom = 8816520
        ControlLook.FixedGradientDownTo = 7568510
        ControlLook.FixedGradientDownMirrorFrom = 7568510
        ControlLook.FixedGradientDownMirrorTo = 6452086
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
        FixedColWidth = 120
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -13
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        Navigation.AdvanceAutoEdit = False
        Navigation.AdvanceDirection = adTopBottom
        Navigation.AllowClipboardShortCuts = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -13
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -13
        PrintSettings.HeaderFont.Name = 'MS Sans Serif'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -13
        PrintSettings.FooterFont.Name = 'MS Sans Serif'
        PrintSettings.FooterFont.Style = []
        PrintSettings.Borders = pbNoborder
        PrintSettings.Centered = False
        PrintSettings.PagePrefix = 'page'
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 18
        SearchFooter.ColorTo = 13160660
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
        URLColor = clBlack
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          120
          120
          78
          82
          97
          72
          120)
      end
      object ToolBarVarPage: TToolBar
        Left = 0
        Top = 0
        Width = 1080
        Height = 24
        AutoSize = True
        ButtonHeight = 20
        EdgeBorders = [ebLeft, ebTop, ebRight, ebBottom]
        TabOrder = 1
        object ToggleSwitchVarContOutput: TToggleSwitch
          Left = 0
          Top = 0
          Width = 77
          Height = 20
          Alignment = taLeftJustify
          ParentShowHint = False
          ShowHint = True
          State = tssOn
          StateCaptions.CaptionOn = '  on'
          StateCaptions.CaptionOff = '  off'
          TabOrder = 0
          ThumbColor = clCrimson
          OnClick = ToggleSwitchVarContOutputClick
        end
      end
    end
    object TabSheetExternalValues: TTabSheet
      BorderWidth = 1
      Caption = 'ExternalValues'
      ImageIndex = 5
      OnShow = TabSheetExternalValuesShow
      object AdvStringGridExternV: TAdvStringGrid
        Left = 0
        Top = 26
        Width = 1080
        Height = 533
        Cursor = crDefault
        Align = alClient
        ColCount = 7
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
        ScrollBars = ssBoth
        TabOrder = 0
        OnButtonClick = AdvStringGridExternVButtonClick
        OnCheckBoxClick = AdvStringGridExternVCheckBoxClick
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 15387318
        AutoNumAlign = True
        Bands.Active = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = clWhite
        ControlLook.FixedGradientTo = clBtnFace
        ControlLook.FixedGradientHoverFrom = 13619409
        ControlLook.FixedGradientHoverTo = 12502728
        ControlLook.FixedGradientHoverMirrorFrom = 12502728
        ControlLook.FixedGradientHoverMirrorTo = 11254975
        ControlLook.FixedGradientDownFrom = 8816520
        ControlLook.FixedGradientDownTo = 7568510
        ControlLook.FixedGradientDownMirrorFrom = 7568510
        ControlLook.FixedGradientDownMirrorTo = 6452086
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
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        Navigation.AdvanceAutoEdit = False
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
        SearchFooter.ColorTo = 13160660
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
        ColWidths = (
          64
          103
          80
          92
          82
          98
          64)
      end
      object ToolBarExternals: TToolBar
        Left = 0
        Top = 0
        Width = 1080
        Height = 26
        AutoSize = True
        ButtonHeight = 20
        Caption = 'ToolBarExternals'
        DoubleBuffered = False
        EdgeBorders = [ebLeft, ebTop, ebRight, ebBottom]
        Flat = False
        List = True
        ParentDoubleBuffered = False
        TabOrder = 1
        object ToggleSwitchExternContOutput: TToggleSwitch
          Left = 0
          Top = 0
          Width = 79
          Height = 20
          Alignment = taLeftJustify
          StateCaptions.CaptionOn = '  On'
          StateCaptions.CaptionOff = '  Off'
          TabOrder = 0
          OnClick = ToggleSwitchExternContOutputClick
        end
      end
    end
    object TabSheetOptions: TTabSheet
      BorderWidth = 1
      Caption = 'Options'
      ImageIndex = 9
      OnExit = ButtonSaveOptionsClick
      OnShow = TabSheetOptionsShow
      object ToolBarOptions: TToolBar
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1074
        Height = 23
        AutoSize = True
        ButtonHeight = 23
        Caption = 'ToolBarOptions'
        TabOrder = 0
        DesignSize = (
          1074
          23)
        object ButtonSaveOptions: TBitBtn
          AlignWithMargins = True
          Left = 0
          Top = 0
          Width = 60
          Height = 23
          Hint = 'Save changes'
          Caption = 'Save'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = ButtonSaveOptionsClick
        end
        object BitBtnSaveOptionsTo: TBitBtn
          AlignWithMargins = True
          Left = 60
          Top = 0
          Width = 80
          Height = 23
          Hint = 'Save as...'
          Caption = 'Save as...'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFB5B5F7B5B5F7B5
            B5F7B5B5F7B5B5F7FFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFF2525EA2525EA2525EA2525EA2525EAD8D8FBFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFBEBEF8BEBEF8BE
            BEF8BEBEF8BEBEF8BEBEF8FFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFF4848ED4848ED4848ED4848ED4848ED4848EDFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = BitBtnSaveOptionsToClick
        end
        object LabelOptionsFilename: TLabel
          Left = 140
          Top = 0
          Width = 62
          Height = 23
          Alignment = taCenter
          Caption = '   FileName '
          Layout = tlCenter
        end
        object EditOptionsFileName: TEdit
          Left = 202
          Top = 0
          Width = 750
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          ReadOnly = True
          TabOrder = 2
          Text = 'EditParamFileName'
        end
        object SpeedButtonChangeOptionsFilename: TSpeedButton
          Left = 952
          Top = 0
          Width = 22
          Height = 23
          Anchors = [akTop, akRight]
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
            1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
            001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
            E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
            B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
            61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
            F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
            E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
            57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
            AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
            DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
            4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
            FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
            D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
            48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
            6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
            D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
            45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
            F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
            55A90055A90015930015930015934793F64793F64793F60015930000000058AE
            91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
            FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
            0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
          OnClick = SpeedChangeParamIniFileClick
        end
      end
      object AdvStringGridOptions: TAdvStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 32
        Width = 1074
        Height = 524
        Cursor = crDefault
        Align = alClient
        ColCount = 4
        DefaultColWidth = 100
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
        ScrollBars = ssBoth
        TabOrder = 1
        OnAnchorClick = AdvStringGridOptionsAnchorClick
        OnGetEditorType = AdvStringOptionsGetEditorType
        OnButtonClick = AdvStringGridOptionsButtonClick
        OnEditCellDone = AdvStringGridOptionsEditCellDone
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 15387318
        AutoNumAlign = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = clWhite
        ControlLook.FixedGradientTo = clBtnFace
        ControlLook.FixedGradientHoverFrom = 13619409
        ControlLook.FixedGradientHoverTo = 12502728
        ControlLook.FixedGradientHoverMirrorFrom = 12502728
        ControlLook.FixedGradientHoverMirrorTo = 11254975
        ControlLook.FixedGradientDownFrom = 8816520
        ControlLook.FixedGradientDownTo = 7568510
        ControlLook.FixedGradientDownMirrorFrom = 7568510
        ControlLook.FixedGradientDownMirrorTo = 6452086
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
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'MS Sans Serif'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedColWidth = 100
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -13
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        MouseActions.CaretPositioning = True
        MouseActions.ColSelect = True
        MouseActions.RowSelect = True
        Navigation.AllowDeleteRow = True
        Navigation.AdvanceAutoEdit = False
        Navigation.AllowClipboardShortCuts = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -13
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -13
        PrintSettings.HeaderFont.Name = 'MS Sans Serif'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -13
        PrintSettings.FooterFont.Name = 'MS Sans Serif'
        PrintSettings.FooterFont.Style = []
        PrintSettings.Borders = pbNoborder
        PrintSettings.Centered = False
        PrintSettings.PagePrefix = 'page'
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 18
        SearchFooter.ColorTo = 13160660
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
        URLColor = clBlack
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          100
          135
          583
          100)
      end
    end
    object TabSheetData: TTabSheet
      Caption = 'Data'
      OnShow = TabSheetDataShow
      object AdvStringGridData: TAdvStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 36
        Width = 1076
        Height = 522
        Cursor = crDefault
        Align = alClient
        FixedCols = 0
        FixedRows = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
        ScrollBars = ssBoth
        TabOrder = 0
        GridLineColor = 15855083
        GridFixedLineColor = 13745060
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 10344697
        ActiveCellColorTo = 6210033
        AutoNumAlign = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = 16513526
        ControlLook.FixedGradientTo = 15260626
        ControlLook.FixedGradientHoverFrom = 15000287
        ControlLook.FixedGradientHoverTo = 14406605
        ControlLook.FixedGradientHoverMirrorFrom = 14406605
        ControlLook.FixedGradientHoverMirrorTo = 13813180
        ControlLook.FixedGradientHoverBorder = 12033927
        ControlLook.FixedGradientDownFrom = 14991773
        ControlLook.FixedGradientDownTo = 14991773
        ControlLook.FixedGradientDownMirrorFrom = 14991773
        ControlLook.FixedGradientDownMirrorTo = 14991773
        ControlLook.FixedGradientDownBorder = 14991773
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
        FixedColWidth = 94
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -13
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        Look = glOffice2007
        MouseActions.AllSelect = True
        MouseActions.ColSelect = True
        MouseActions.DisjunctRowSelect = True
        MouseActions.RowSelect = True
        Navigation.AllowDeleteRow = True
        Navigation.AdvanceOnEnter = True
        Navigation.AllowClipboardShortCuts = True
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -13
        PrintSettings.Font.Name = 'MS Sans Serif'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'MS Sans Serif'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -13
        PrintSettings.HeaderFont.Name = 'MS Sans Serif'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -13
        PrintSettings.FooterFont.Name = 'MS Sans Serif'
        PrintSettings.FooterFont.Style = []
        PrintSettings.Borders = pbNoborder
        PrintSettings.Centered = False
        PrintSettings.PagePrefix = 'page'
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 18
        SearchFooter.Color = 16513526
        SearchFooter.ColorTo = clNone
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
        SelectionColor = 6210033
        SelectionRectangle = True
        URLColor = clBlack
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          94
          77
          79
          57
          80)
      end
      object ToolBarDataPage: TToolBar
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1076
        Height = 27
        AutoSize = True
        ButtonHeight = 23
        EdgeBorders = [ebLeft, ebTop, ebRight, ebBottom]
        TabOrder = 1
        DesignSize = (
          1072
          23)
        object SpeedButtonInsRow: TSpeedButton
          Left = 0
          Top = 0
          Width = 80
          Height = 23
          Hint = 'Insert Row'
          Caption = 'Insert row'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000000000776C61776C61776C61776C61776C61776C61776C6177
            6C61776C61776C61776C61776C61776C61776C61776C61776C617B6F64F9F7F5
            F9F7F5F9F7F5F9F7F5B0A294F9F7F5F9F7F5F9F7F5F9F7F5B0A294F9F7F5F9F7
            F5F9F7F5F9F7F57B6F647D7266F7F5F1F7F5F1F7F5F1F7F5F1B0A294F7F5F1F7
            F5F1F7F5F1F7F5F1B0A294F7F5F1F7F5F1F7F5F1F7F5F17D7266008700008700
            0087000087000087000087000087000087000087000087000087000087000087
            000087000087000087000087006FFFB76FFFB76FFFB76FFFB70087006FFFB76F
            FFB76FFFB76FFFB70087006FFFB76FFFB76FFFB76FFFB70087000087005CFFAE
            5CFFAE5CFFAE5CFFAE0087005CFFAE5CFFAE5CFFAE5CFFAE0087005CFFAE5CFF
            AE5CFFAE5CFFAE00870000870000870000870000870000870000870000870000
            8700008700008700008700008700008700008700008700008700938679EDE7DF
            BEB9B2BEB9B2BEB9B2B0A294EDE7DFEDE7DFEDE7DFEDE7DFB0A294EDE7DFEDE7
            DFEDE7DFEDE7DF93867996897CEBE5DD006E10006E10006E10B0A294EBE5DDEB
            E5DDEBE5DDEBE5DDB0A294EBE5DDEBE5DDEBE5DDEBE5DD96897C7C7166857A6F
            00741346D0AF007413857A6F857A6FA6998BA6998BA6998BA6998BA6998BA699
            8BA6998BA6998B9B8D80007C17007C17007C174DD1B2007C17007C17007C17EA
            E3DAEAE3DAEAE3DA968A7DEAE3DAEAE3DAEAE3DAEAE3DA9E908200841C71ECD3
            71ECD356D4B571ECD371ECD300841CF2EEE9F2EEE9F2EEE982776CF2EEE9F2EE
            E9F2EEE9F2EEE9A19385008C20008C20008C2061D6BA008C20008C20008C20A3
            9587A39587A39587A39587A39587A39587A39587A39587A39587000000000000
            0093237AEED70093230000000000000000000000000000000000000000000000
            0000000000000000000000000000000000972500972500972500000000000000
            0000000000000000000000000000000000000000000000000000}
          ParentShowHint = False
          ShowHint = True
          OnClick = SpeedButtonInsRowClick
        end
        object btnSaveDataChanges: TSpeedButton
          AlignWithMargins = True
          Left = 80
          Top = 0
          Width = 60
          Height = 23
          Hint = 'Save Changes'
          Caption = 'Save'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000FFFFFF000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000FFFFFFFFFFFF00000032190032190032190032190032190032
            19003219003219003219003219003219003219002C1600FFFFFFFFFFFF341A00
            C3A475C2A3748C724FE2DFDFE2DFDFE2DFDF887C6DFFFFFFFFFFFF8C724FC2A3
            74C3A475341A00FFFFFFFFFFFF361C00B19263B091627A603DD0CDCDD0CDCDD0
            CDCD766A5BF0EFEEF0EFEE7A603DB09162B19263361C00FFFFFFFFFFFF391E00
            A58657A485566E5431C4C1C1C4C1C1C4C1C16A5E4FE4E3E2E4E3E26E5431A485
            56A58657391E00FFFFFFFFFFFF3B2000A18253A1825381643D6A502D6A502D6A
            502D6A502D6A502D6A502D81643DA18253A182533B2000FFFFFFFFFFFF3E2200
            A18253A18253A18253A08152A08152A08152A08152A08152A08152A18253A182
            53A182533E2200FFFFFFFFFFFF412400A182538B6E447559346A502D6A502D6A
            502D6A502D6A502D6A502D7559348B6E44A18253412400FFFFFFFFFFFF442702
            A18253755934E1DCD5FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1DCD57559
            34A18253442702FFFFFFFFFFFF472903A385576F5534FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF6F5534A38557472903FFFFFFFFFFFF4A2B04
            A78B60765E3DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF765E
            3DA78B604A2B04FFFFFFFFFFFF4C2D05AD936A7F694BFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFF7F694BAD936A4C2D05FFFFFFFFFFFF4F2F07
            B69E798C785DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8C78
            5DB69E794F2F07FFFFFFFFFFFF503007D0C0A9B5A896FFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFB5A896D0C0A9503007FFFFFFFFFFFF523108
            5231085231085231085231085231085231085231085231085231085231085231
            08523108523108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
          ParentShowHint = False
          ShowHint = True
          OnClick = btnSaveDataChangesClick
        end
        object LabelDataFileNameDesc: TLabel
          AlignWithMargins = True
          Left = 140
          Top = 0
          Width = 52
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          Caption = '  Datafile  '
          Layout = tlCenter
        end
        object EditDataFileName: TEdit
          Left = 192
          Top = 0
          Width = 400
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          ParentShowHint = False
          ReadOnly = True
          ShowHint = True
          TabOrder = 0
          Text = 'EditDataFileName'
        end
        object SpeedButtonOpenDataFile: TSpeedButton
          Left = 592
          Top = 0
          Width = 22
          Height = 23
          Anchors = [akTop, akRight]
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
            1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
            001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
            E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
            B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
            61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
            F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
            E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
            57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
            AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
            DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
            4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
            FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
            D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
            48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
            6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
            D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
            45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
            F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
            55A90055A90015930015930015934793F64793F64793F60015930000000058AE
            91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
            FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
            0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
          OnClick = SpeedButtonOpenDataFileClick
        end
        object CheckBoxDataDateFormat: TCheckBox
          Left = 614
          Top = 0
          Width = 97
          Height = 23
          Alignment = taLeftJustify
          Caption = '    DateFormat'
          TabOrder = 1
          OnClick = CheckBoxDataDateFormatClick
        end
        object SpeedButtonMergeData: TSpeedButton
          Left = 711
          Top = 0
          Width = 78
          Height = 23
          Caption = 'MergeData'
          OnClick = SpeedButtonMergeDataClick
        end
      end
    end
    object TabSheetStat: TTabSheet
      BorderWidth = 1
      Caption = 'Statistics'
      object AdvStringGridStat: TAdvStringGrid
        Left = 0
        Top = 22
        Width = 1080
        Height = 537
        Cursor = crDefault
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        OnButtonClick = AdvStringGridStatButtonClick
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 15387318
        AutoNumAlign = True
        ControlLook.FixedGradientFrom = clWhite
        ControlLook.FixedGradientTo = clBtnFace
        ControlLook.FixedGradientHoverFrom = 13619409
        ControlLook.FixedGradientHoverTo = 12502728
        ControlLook.FixedGradientHoverMirrorFrom = 12502728
        ControlLook.FixedGradientHoverMirrorTo = 11254975
        ControlLook.FixedGradientDownFrom = 8816520
        ControlLook.FixedGradientDownTo = 7568510
        ControlLook.FixedGradientDownMirrorFrom = 7568510
        ControlLook.FixedGradientDownMirrorTo = 6452086
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
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'MS Sans Serif'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'Tahoma'
        FixedFont.Style = [fsBold]
        FloatFormat = '%.2f'
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
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 16
        SearchFooter.ColorTo = 13160660
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
        ColWidths = (
          64
          20
          20
          20
          20)
      end
      object ToolBarStatistics: TToolBar
        Left = 0
        Top = 0
        Width = 1080
        Height = 22
        ButtonHeight = 19
        ButtonWidth = 13
        Caption = 'ToolBarStatistics'
        List = True
        ShowCaptions = True
        TabOrder = 1
        object btnAdvStatToClipBoardButton: TSpeedButton
          Left = 0
          Top = 0
          Width = 120
          Height = 19
          Hint = 'Copy to clipboard'
          Caption = 'Copy to clipboard'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            18000000000000030000130B0000130B00000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000000000000000000000000000000000000000000000786D6178
            6D61786D61786D61786D61786D61786D61786D61786D61000000000000000000
            0000000000000000000000007D7165FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFF7D7165000000000000000000000000000000000000000000817569F7
            F5F1AD7930AD7930AD7930AD7930CCAD81F7F5F1817569000000000000000000
            000000000000000000000000867A6EF5F1ECF5F1ECF5F1ECF5F1ECF5F1ECF5F1
            ECF5F1EC867A6E0000000000000000000000000000000000000000008C7F73F2
            EEE9AC772EAC772EAC772EAC772EC6A679E6E1DB877B6F000000786D61786D61
            786D61786D61786D61867C71928578EFE9E2EFE9E2EFE9E2EFE9E2E8E2DBDBD7
            D1CAC5BE81766A0000007D7165FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF978A7DED
            E8E0AB762DC7A678EDE8E0A79C8F978A7D978A7D978A7D000000817569F7F5F1
            AD7930AD7930AD7930C9A7779C8E81EAE3DAEAE3DAEAE3DAEAE3DAADA298F3ED
            E7F3EDE7B6ABA0000000867A6EF5F1ECF5F1ECF5F1ECF5F1ECF5F2EDA09285F5
            F1EDF5F1EDF5F1EDF5F1EDB5ACA3FEFDFCB5ACA30B0A090000008C7F73F2EEE9
            AC772EAC772EAC772EC7A575A39587A39587A39587A39587ACA093A19385A395
            870B0A09000000000000928578EFE9E2EFE9E2EFE9E2EFE9E2EAE5DFD7D2CCCF
            CBC58E8479000000000000000000000000000000000000000000978A7DEDE8E0
            AB762DC7A678EDE8E0A79C8F978A7D978A7D978A7D0000000000000000000000
            000000000000000000009C8E81EAE3DAEAE3DAEAE3DAEAE3DAADA298F3EDE7F3
            EDE7B6ABA0000000000000000000000000000000000000000000A09285F5F1ED
            F5F1EDF5F1EDF5F1EDB5ACA3FEFDFCB5ACA30B0A090000000000000000000000
            00000000000000000000A39587A39587A39587A39587ACA093A19385A395870B
            0A09000000000000000000000000000000000000000000000000}
          ParentShowHint = False
          ShowHint = False
          OnClick = btnAdvStatToClipBoardButtonClick
        end
      end
    end
    object TabSheetResultTab: TTabSheet
      BorderWidth = 1
      Caption = 'Table Results'
      OnEnter = TabSheetResultTabEnter
      OnShow = TabSheetResultTabShow
      object AdvStringGridResults: TAdvStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 25
        Width = 1074
        Height = 531
        Cursor = crDefault
        Align = alClient
        RowCount = 7
        FixedRows = 2
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing]
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        HintColor = clYellow
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 15387318
        AutoNumAlign = True
        CellNode.NodeType = cnFlat
        ControlLook.FixedGradientFrom = clWhite
        ControlLook.FixedGradientTo = clBtnFace
        ControlLook.FixedGradientHoverFrom = 13619409
        ControlLook.FixedGradientHoverTo = 12502728
        ControlLook.FixedGradientHoverMirrorFrom = 12502728
        ControlLook.FixedGradientHoverMirrorTo = 11254975
        ControlLook.FixedGradientHoverBorder = 12033927
        ControlLook.FixedGradientDownFrom = 8816520
        ControlLook.FixedGradientDownTo = 7568510
        ControlLook.FixedGradientDownMirrorFrom = 7568510
        ControlLook.FixedGradientDownMirrorTo = 6452086
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
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -13
        FixedFont.Name = 'MS Sans Serif'
        FixedFont.Style = []
        FloatFormat = '%.2f'
        MouseActions.AllSelect = True
        MouseActions.CaretPositioning = True
        MouseActions.ColSelect = True
        MouseActions.DisjunctRowSelect = True
        MouseActions.RowSelect = True
        Multilinecells = True
        Navigation.AllowInsertRow = True
        Navigation.AllowDeleteRow = True
        Navigation.AdvanceOnEnter = True
        Navigation.AdvanceInsert = True
        Navigation.AdvanceDirection = adTopBottom
        Navigation.AllowClipboardShortCuts = True
        Navigation.InsertPosition = pInsertAfter
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
        PrintSettings.PagePrefix = 'page'
        PrintSettings.PageNumSep = '/'
        ScrollWidth = 16
        SearchFooter.ColorTo = 13160660
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
        URLColor = clBlack
        Version = '5.0.3.1'
        WordWrap = False
        ColWidths = (
          64
          73
          72
          86
          99)
      end
      object ToolBarPageTable: TToolBar
        Left = 0
        Top = 0
        Width = 1080
        Height = 22
        AutoSize = True
        TabOrder = 1
        DesignSize = (
          1080
          22)
        object LabelOutputdatafile: TLabel
          Left = 0
          Top = 0
          Width = 72
          Height = 22
          Caption = 'Outputdatafile  '
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = 8
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
        end
        object EditOutputdatafilename: TEdit
          Left = 72
          Top = 0
          Width = 529
          Height = 22
          Anchors = [akLeft, akTop, akRight]
          AutoSize = False
          TabOrder = 0
        end
        object SpeedButtonOpenOutputFile: TSpeedButton
          Left = 601
          Top = 0
          Width = 22
          Height = 22
          Anchors = [akTop, akRight]
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000FFFFFFFFFFFF001E52001E58001C56001C56001C56001C56001C5600
            1C56001C56001C56001C56001C56001E58001E52FFFFFFFFFFFF0025606BF6FF
            001C564CB9ED17A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5E817A5
            E8001C56001C56FFFFFF00296666F2FF25699318467D2FB7F11CB0F01CB0F01C
            B0F01CB0F01CB0F01CB0F01CB0F01CB0F01CB0F0001C56001C56002D6C61EDFF
            61EDFF154A7B4DA4CD29C5F829C5F829C5F829C5F829C5F829C5F829C5F829C5
            F829C5F829C5F8001C560031735BE7FF5BE7FF40AFD4002C6F79E9FF79E9FF79
            E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF79E9FF002C6F00367A57E2FF
            57E2FF57E2FF1F87C90053AA0053AA0053AA0053AA0053AA0053AA0053AA0053
            AA0053AA0053AA0053AA003A8153DEFF53DEFF53DEFF53DEFF53DEFF53DEFF53
            DEFF4AC6E342B2CC42B2CC53DEFF53DEFF003A81FFFFFFFFFFFF003F884FDBFF
            4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF4FDBFF1D528B0000560000563FAFCC4FDB
            FF00326D00000000000000448F4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4CD7FF4C
            D7FF0000611680FF1680FF0000613DACCC00006100006100085100489648D4FF
            48D4FF48D4FF48D4FF48D4FF48D4FF48D4FF00046D67A7F8026CF4026CF40004
            6D00046D026CF400046D004D9D46D1FF46D1FF46D1FF46D1FF46D1FF46D1FF46
            D1FF46D1FF00097966A6F7006AF2006AF2000979006AF20009790051A397E4FF
            45CFFF45CFFF45CFFF45CFFF97E4FF97E4FF97E4FF79B6CC000F876FABF80F73
            F30F73F30F73F3000F870055A90055A96DDAFF5FD6FF5FD6FF6DDAFF0055A900
            55A90055A90015930015930015934793F64793F64793F60015930000000058AE
            91CFEFB4EBFFB4EBFF91CFEF0058AE00000000000000199DBDD9FBBDD9FBBDD9
            FBBDD9FBBDD9FB00199D000000005AB1005AB1005AB1005AB1005AB1005AB100
            0000000000002BA0001CA4001CA4001CA4001CA4001CA4002BA0}
        end
        object CheckBoxDateFormat: TCheckBox
          AlignWithMargins = True
          Left = 623
          Top = 0
          Width = 82
          Height = 22
          Alignment = taLeftJustify
          Anchors = [akTop, akRight]
          Caption = '  DateFormat'
          TabOrder = 1
          OnClick = CheckBoxDateFormatClick
        end
        object SpeedButtonFinalvalues: TSpeedButton
          AlignWithMargins = True
          Left = 705
          Top = 0
          Width = 78
          Height = 22
          Anchors = [akTop, akRight]
          Caption = 'Final_values'
          Layout = blGlyphRight
          OnClick = SpeedButtonFinalvaluesClick
        end
      end
    end
    object TabSheetGraphResult: TTabSheet
      BorderWidth = 1
      Caption = 'Plot Result'
      OnEnter = TabSheetGraphResultEnter
      OnShow = TabSheetGraphResultShow
      object ChartSimResults: TChart
        AlignWithMargins = True
        Left = 3
        Top = 33
        Width = 1074
        Height = 523
        BackWall.Brush.Style = bsClear
        MarginBottom = 5
        MarginLeft = 8
        MarginRight = 5
        MarginTop = 5
        Title.Text.Strings = (
          '')
        BottomAxis.LabelsFormat.Font.Height = -16
        Chart3DPercent = 1
        LeftAxis.LabelsFormat.Font.Height = -16
        View3D = False
        Align = alClient
        AutoSize = True
        TabOrder = 0
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
      object ToolBarPlotPage: TToolBar
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1074
        Height = 24
        AutoSize = True
        ButtonHeight = 24
        TabOrder = 1
        object PrintButton: TSpeedButton
          Left = 0
          Top = 0
          Width = 60
          Height = 24
          Hint = 'Print'
          Caption = 'Print'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            000000000000000000000D0D0C13131213131213131213131213131213131213
            13121313121313121313121313121313121313121313120D0D0C1D1D1C878481
            8784818784818784818784818784818784818784818784818784818784818784
            818784818784811D1D1C28282778767378767378767378767378767378767378
            76737876737876737876736F83755AA27B6F83757876732828273534337D7A77
            7D7A777D7A777D7A777D7A777D7A777D7A777D7A777D7A777D7A775DA57E1AFF
            8D5DA57E7D7A7735343341403EB1ADA8B6B2ADB6B2ADB6B2ADB6B2ADB6B2ADB6
            B2ADB6B2ADB6B2ADB6B2AD9EBEA884CBA39EBEA8B1ADA841403E4C4B49D6D2CE
            DFDBD7DFDBD7DFDBD7DFDBD7DFDBD7DFDBD7DFDBD7DFDBD7DFDBD7DFDBD7DFDB
            D7DFDBD7D6D2CE4C4B49565553A8A49FAAA6A153483CA59F98A59F98A59F98A5
            9F98A59F98A59F98A59F98A59F9853483CAAA6A1A8A49F5655533E3D3B5F5E5B
            5F5E5B574C40FAF7F5FAF7F5FAF7F5FAF7F5FAF7F5FAF7F5FAF7F5FAF7F5574C
            405F5E5B5F5E5B3E3D3B0000000000000000005D5145F6F1EDF6F1EDF6F1EDF6
            F1EDF6F1EDF6F1EDF6F1EDF6F1ED5D5145000000000000000000000000000000
            00000063574AF3ECE6AD772EAD772EAD772EAD772EAD772EAD772EF3ECE66357
            4A000000000000000000000000000000000000695D50F0E8E0F0E8E0F0E8E0F0
            E8E0F0E8E0F0E8E0F0E8E0F0E8E0695D50000000000000000000000000000000
            000000706255EEE5DCAC762CAC762CAC762CAC762CAC762CAC762CEEE5DC7062
            5500000000000000000000000000000000000075675AECE3D9ECE3D9ECE3D9EC
            E3D9ECE3D9ECE3D9ECE3D9ECE3D975675A000000000000000000000000000000
            000000796C5EFAF7F4FAF7F4FAF7F4FAF7F4FAF7F4FAF7F4FAF7F4FAF7F4796C
            5E000000000000000000000000000000000000574D447D6F617D6F617D6F617D
            6F617D6F617D6F617D6F617D6F61574D44000000000000000000}
          ParentShowHint = False
          ShowHint = False
          OnClick = PrintButtonClick
        end
        object btnSaveasPNG: TSpeedButton
          Left = 60
          Top = 0
          Width = 70
          Height = 24
          Hint = 'Convert to PNG image'
          Caption = 'to PNG'
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            000000000000000000005B52485B52485B52485B52485B52485B52485B52485B
            52485B52485B52485B52485B52485B52485B52485B52485B524860564CF5E2B8
            F4EADDE7E2E4E5EAF9D5DDF9C4D0ECC3C8D8C4B1BFCAB6C6C5CCEBC3E5FACCE9
            FAD5E4F7E2EBF960564C655B51F4D485F6D06FFBD775FDE6BCF9F2EFEDEFFDD7
            DFF2D2CDE1D8C3CAD8D1D9DDE9F3E1EAF3EAF1FAD5F0FF655B516C6156F3C96B
            FFBE35FFBE36FFC858FFD07DFFD58AF4D7A0EEDAB5E8DAC9EFEDF1CDD7D899AF
            A695AAA890B0AA6C615673685DEBBA72FFB651FFB259FFB653FFB551FFB356F8
            B558FFB357FFB652EBC6A09E92757E855D3E5D38576A5D73685D7A6E63F6E1CA
            F4D9BBF4D9BBF4D9BBF4D9BBF4D9BBF4D9BBF4D9BBFBE1CAF4D9BB8C875F5050
            202C2F0C8989517A6E63817569F3D6B7F0CBA3F0CBA3F0CBA3F0CBA3F0CBA3F0
            CBA3F0CBA3F0CBA3F0CBA3CAAB7DA49058626645706C46817569887C6FEEC8A1
            E9B987E9B987E9B987E9B987E9B987E9B987E9B987E9BA87E9B987E9B987E2AD
            7AD4AD74A89A61887C6F8F8376EAC192E4B074E4B074E4B074E4B074E4B074E4
            B074E4B074E4B074E4B074E4AF75E4AF75E4B175EAC1928F837696887BE4B882
            DBA55EDCA55FDBA55EDBA55EDBA55EDCA55FDBA55EDCA55FDBA55EDBA55EDBA5
            5EDBA55EE4B98296887B9B8D80E5C190DEB171DEB171DEB171DEB171DEB171DE
            B171DEB171DEB171DEB171DEB170DEB170DEB171E5C2909B8D809F9284F1DEC1
            EFD7B5EFD7B5EFD7B5EFD7B5EFD7B5EFD7B5EFD7B5EFD7B5EFD7B5EFD7B5EFD7
            B5EFD7B5F1DEC19F9284A39587A39587A39587A39587A39587A39587A39587A3
            9587A39587A39587A39587A39587A39587A39587A39587A39587000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000}
          ParentShowHint = False
          ShowHint = False
          OnClick = btnSaveasPNGClick
        end
        object SpeedButtonSaveToWMF: TSpeedButton
          Left = 130
          Top = 0
          Width = 79
          Height = 24
          Caption = 'to WMF'
          OnClick = SpeedButtonSaveToWMFClick
        end
        object SpeedButtonIncFontSize: TSpeedButton
          Left = 209
          Top = 0
          Width = 23
          Height = 24
          Caption = '+'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          OnClick = SpeedButtonIncFontSizeClick
        end
        object SpeedButtonDecFontSize: TSpeedButton
          Left = 232
          Top = 0
          Width = 23
          Height = 24
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          OnClick = SpeedButtonDecFontSizeClick
        end
        object LabelTimeSeriesOption: TLabel
          Left = 255
          Top = 0
          Width = 96
          Height = 24
          Alignment = taCenter
          Caption = '  Time series type  '
          Layout = tlCenter
        end
        object ComboBoxTimeAxisOption: TComboBox
          Left = 351
          Top = 0
          Width = 145
          Height = 23
          Style = csDropDownList
          TabOrder = 0
          OnChange = ComboBoxTimeAxisOptionChange
          Items.Strings = (
            'Date'
            'Floating Point')
        end
        object SelectMeasDataCheckBox: TCheckBox
          Left = 496
          Top = 0
          Width = 172
          Height = 24
          Alignment = taLeftJustify
          Caption = '   Autoselect Measurement Data'
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
      end
    end
    object TabSheetDocumentation: TTabSheet
      Caption = 'Documentation'
      ImageIndex = 11
      object ToolBarDocu: TToolBar
        Left = 0
        Top = 0
        Width = 1082
        Height = 29
        ButtonHeight = 23
        Caption = 'ToolBarDocu'
        TabOrder = 0
        object SpeedButtonCreateDocu: TSpeedButton
          Left = 0
          Top = 0
          Width = 90
          Height = 23
          Caption = 'CreateDocu'
          OnClick = SpeedButtonCreateDocuClick
        end
        object EditDokuFilename: TEdit
          AlignWithMargins = True
          Left = 90
          Top = 0
          Width = 847
          Height = 23
          Align = alClient
          TabOrder = 0
        end
      end
      object MemoModelDocu: TMemo
        Left = 0
        Top = 29
        Width = 1082
        Height = 223
        Align = alTop
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Courier'
        Font.Style = []
        Lines.Strings = (
          'MemoModelDocu')
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 1
        WordWrap = False
      end
      object AdvStringGridModelSummary: TAdvStringGrid
        Left = 0
        Top = 311
        Width = 1082
        Height = 250
        Cursor = crDefault
        Align = alBottom
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -10
        Font.Name = 'Tahoma'
        Font.Style = []
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing]
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 2
        GridLineColor = 15527152
        GridFixedLineColor = 13947601
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 16575452
        ActiveCellColorTo = 16571329
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
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'Tahoma'
        FilterDropDown.Font.Style = []
        FilterDropDownClear = '(All)'
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'Tahoma'
        FixedFont.Style = [fsBold]
        FloatFormat = '%.2f'
        Look = glWin7
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'Tahoma'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'Tahoma'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -11
        PrintSettings.HeaderFont.Name = 'Tahoma'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -11
        PrintSettings.FooterFont.Name = 'Tahoma'
        PrintSettings.FooterFont.Style = []
        PrintSettings.PageNumSep = '/'
        SearchFooter.Color = 16645370
        SearchFooter.ColorTo = 16247261
        SearchFooter.FindNextCaption = 'Find &next'
        SearchFooter.FindPrevCaption = 'Find &previous'
        SearchFooter.Font.Charset = DEFAULT_CHARSET
        SearchFooter.Font.Color = clWindowText
        SearchFooter.Font.Height = -11
        SearchFooter.Font.Name = 'Tahoma'
        SearchFooter.Font.Style = []
        SearchFooter.HighLightCaption = 'Highlight'
        SearchFooter.HintClose = 'Close'
        SearchFooter.HintFindNext = 'Find next occurence'
        SearchFooter.HintFindPrev = 'Find previous occurence'
        SearchFooter.HintHighlight = 'Highlight occurences'
        SearchFooter.MatchCaseCaption = 'Match case'
        ShowDesignHelper = False
        SortSettings.HeaderColor = 16579058
        SortSettings.HeaderColorTo = 16579058
        SortSettings.HeaderMirrorColor = 16380385
        SortSettings.HeaderMirrorColorTo = 16182488
        Version = '5.0.3.1'
        ColWidths = (
          64
          64
          64
          64
          676)
      end
    end
  end
  object PanelMainFormHeader: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 1090
    Height = 35
    Align = alTop
    Alignment = taLeftJustify
    TabOrder = 2
    object LabelActIniFileDesc: TLabel
      Left = 389
      Top = 9
      Width = 68
      Height = 13
      AutoSize = False
      Caption = 'Act. Inifile'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      OnMouseMove = LabelActIniFileDescMouseMove
    end
    object LabelSubModelCombobox: TLabel
      Left = 73
      Top = 4
      Width = 72
      Height = 22
      AutoSize = False
      Caption = '    SubModel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object SpeedButtonRun: TSpeedButton
      AlignWithMargins = True
      Left = 7
      Top = 4
      Width = 60
      Height = 22
      Hint = 'Run the model'
      Caption = 'Start'
      Flat = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        1800000000000003000000000000000000000000000000000000FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFF34282234282234282234282234282234282234282234
        2822342822342822342822342822342822342822342822342822392D27877C76
        B5AAA4D9D1CBF4EEE8FEF6F0FCF2ECFCF2ECFFF7F1FFFAF4FEF9F3F4EEE8D9D1
        CBB9AEA8877C76392D273F332EAFA49EE6E2E0FDF7F4EAE4E1D9D3D0C5BFBDC1
        BCBAD2CDCAE0DAD7E3DDDAEAE4E1FDF7F4E6E2E0AFA49E3F332E463B35BBB0AA
        E9E3E0DBD5D2DAD4D1CCC7C4038A13038A13B5B0ADC9C3C1D7D1CEDAD4D1DBD5
        D2E9E3E0BBB0AA463B354D433DBBB0AADCD6D3D9D3D0D9D3D0CBC6C302891204
        BB1C028912B4AFACC8C2C0D6D0CDD9D3D0DCD6D3BBB0AA4D433D554C46BBB0AA
        D9D3D0DAD4D1DAD4D1CCC8C5098C190BBD220BBD22098C19C0BBB8D3CDCADAD4
        D1D9D3D0BBB0AA554C465E544FBBB0AADCD6D3DCD7D4DCD7D4D0CBC81994271B
        C1301BC1301BC130199427DAD4D2DCD7D4DCD6D3BBB0AA5E544F665D58BBB0AA
        DED9D7DFDAD8DFDAD8D4CFCD2C9C392DC6412DC6412C9C39DDD8D5DFDAD8DFDA
        D8DED9D7BBB0AA665D586D6560BBB0AAE2DDDBE3DEDCE3DEDCDBD7D542A74E44
        CC5642A74EE0DCDAE3DEDCE3DEDCE3DEDCE2DDDBBBB0AA6D6560746D67BBB0AA
        E7E3E2E8E4E2E8E4E2E6E2E064B76E64B76EE6E2E0E8E4E2E8E4E2E8E4E2E8E4
        E2E7E3E2BBB0AA746D677A736EBAAFA9E5E1DEECE9E8ECE9E8ECE9E8ECE9E8EC
        E9E8ECE9E8ECE9E8ECE9E8ECE9E8ECE9E8E6E2E0BAAFA97A736E7F7873A39A94
        C1B9B3E9E5E3FBFAFAFCFBFBFCFBFBFCFBFBFCFBFBFCFBFBFCFBFBFBFAFAEBE8
        E6C3B9B4A39A947F787380797480797480797480797480797480797480797480
        7974807974807974807974807974807974807974807974807974FFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF}
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      Spacing = 6
      OnClick = SpeedButtonRunClick
    end
    object ComboBoxSubMod: TComboBox
      AlignWithMargins = True
      Left = 160
      Top = 4
      Width = 223
      Height = 22
      Style = csOwnerDrawFixed
      TabOrder = 0
      OnChange = ComboBoxSubModChange
    end
    object ComboBoxIniFile: TComboBox
      AlignWithMargins = True
      Left = 566
      Top = 4
      Width = 520
      Height = 22
      Align = alRight
      Style = csOwnerDrawFixed
      TabOrder = 1
      OnChange = ComboBoxInifileChange
      OnDropDown = ComboBoxIniFileDropDown
    end
  end
  object MainMenu1: TMainMenu
    Left = 832
    Top = 536
    object Menu_File: TMenuItem
      Caption = '&Model'
      object Menu_Run: TMenuItem
        Caption = '&Run '
        Default = True
        OnClick = Menu_RunClick
      end
      object Optimize1: TMenuItem
        Caption = '&Optimize'
        OnClick = OptimizeClick
      end
      object N1: TMenuItem
        Caption = '&GA Optimize'
        Hint = 'Genetic Algorithm based Optimization'
        OnClick = GAOptClic
      end
      object SensitivityAnalysis: TMenuItem
        Caption = '&Sensitivity Analysis'
        OnClick = SensitivityAnalysisClick
      end
      object ChisquareAnalysis: TMenuItem
        Caption = '&ChisquareAnalysis'
        OnClick = ChisquareAnalysisClick
      end
      object Menu_Exit: TMenuItem
        Caption = '&Exit'
        OnClick = Menu_ExitClick
      end
    end
    object Menu_Edit: TMenuItem
      Caption = '&Edit'
      object Menu_Parameter: TMenuItem
        Caption = '&Edit StateVars'
        OnClick = MenuEditStateClick
      end
      object MenuInitParams: TMenuItem
        Caption = 'Edit &Parameters'
        OnClick = MenuInitParamsClick
      end
      object ViewVariables1: TMenuItem
        Caption = 'Edit &Variables'
        OnClick = ViewVariables1Click
      end
      object EditExternals1: TMenuItem
        Caption = 'Edit &Externals'
        OnClick = EditExternals1Click
      end
      object EditOptions1: TMenuItem
        Caption = 'Edit &Options'
        OnClick = EditOptions1Click
      end
    end
    object MenuView: TMenuItem
      Caption = '&View Results'
      object MenuViewState: TMenuItem
        Caption = '&Table'
        OnClick = ViewTabelleClick
      end
      object Graph1: TMenuItem
        Caption = '&Graph'
        OnClick = ViewGraphClick
      end
      object Statistics1: TMenuItem
        Caption = '&Statistics'
        OnClick = Statistics1Click
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      object Info1: TMenuItem
        Caption = '&Info'
        OnClick = Info1Click
      end
    end
  end
  object Timer1: TTimer
    Left = 896
    Top = 536
  end
  object PrintDialog1: TPrintDialog
    Left = 772
    Top = 536
  end
  object OpenDialog1: TOpenDialog
    Left = 620
    Top = 540
  end
  object SaveDialog1: TSaveDialog
    Left = 700
    Top = 535
  end
  object il1: TImageList
    Left = 952
    Top = 536
    Bitmap = {
      494C010102000400040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00005A2100006329000063290000632908006329080063290000632900005A21
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000736B
      6300736B6300736B6300736B6300736B6300736B6300736B6300736B6300736B
      6300736B6300736B6300736B6300736B63000000000000000000632900006329
      00007B3108008C4218009C4A2100A5522100A55221009C5221008C4218007B31
      0800632900006329000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007B6B
      6300FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF007B6B630000000000632900006B2900008C42
      1800BD6B3900D6845A00E79C7B00FFFFFF00FFF7EF00DE8C6300DE8C6300CE84
      52009C5229006B31080063290000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007B73
      6300FFFFFF00FFFFF700FFFFF700FFFFF700FFFFF700FFFFF700FFFFF700FFFF
      F700FFFFF700FFFFF700FFFFFF007B736300000000006B290000944A1800BD6B
      3900CE7B5200D6845200DE9C7B00FFFFFF00FFFFFF00D6845200D6845A00D684
      5200CE7B4A009C5221006B290000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007B73
      6B00FFFFF700FFF7F700C69C6300C69C6300C69C6300C69C6300C69C6300C69C
      6300C69C6300FFF7F700FFFFF7007B736B005A21000084390800B5633100C673
      4200C6734A00C6734A00C6734200BD6B4200BD6B4200C6734200C6734A00C673
      4A00C6734200BD6331008C4210005A2100000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000006B5A
      5200C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600D6D6CE00F7F7F700F7F7
      F700F7F7F700F7F7F700FFF7F70084736B0073290000A5521800BD633100BD6B
      3900BD6B3900BD6B3900C67B5A00E7D6CE00E7CEBD00BD6B3900BD6B3900BD6B
      3900BD6B3900BD633100A5521800732900000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000002110000031180000311800003118
      000031180000311800003118000031180000311800004A311000BD945A00BD94
      5A00BD945A00F7F7EF00F7F7EF00847B6B0084390800AD5A2900BD6B3900BD6B
      3900BD6B3900BD6B3900C6845A00F7F7F700F7F7F700CE947300B5633900BD6B
      3900BD6B3900BD6B3900AD5A2900843908000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000031180000BD9C6B00B59C6B008463
      4200D6D6D600FFFFFF0084634200B59C6B00BD9C6B0031180000F7EFE700F7EF
      E700F7EFE700F7EFE700F7F7EF008C7B730094420800B55A2900BD6B3900BD6B
      3900BD6B3900BD6B3900BD6B3900E7D6C600F7F7F700F7F7F700DEB5A500BD6B
      3900BD6B3900BD6B3900B55A2900944208000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000039180000A5845200A58452006B52
      3100C6C6C600FFFFFF006B523100A5845200A584520039180000BD945A00BD94
      5A00BD945A00F7EFE700F7EFEF008C8473009C420800B55A2900BD6B3900BD6B
      3900BD6B3900BD6B3900BD6B3900BD734200DEBDA500F7F7F700F7F7F700CEA5
      8C00BD6B3900BD6B3900B55A29009C4208000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000039210000A5845200A58452008463
      39006B5229006B52290084633900A5845200A584520039210000EFEFE700EFEF
      E700EFEFE700EFEFE700F7EFE70094847B0094420800AD5A2900BD6B3900BD6B
      3900B5633900B5633900BD6B3900BD6B3900BD6B3900D6B59C00F7F7F700E7D6
      C600BD6B3900BD6B3900AD5A2900944208000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000042210000A5845200A5845200A584
      5200A5845200A5845200A5845200A5845200A584520042210000BD945A00BD94
      5A00BD945A00EFE7DE00F7EFE700948C7B008C390000A5521800BD633100BD73
      4200EFD6CE00F7F7F700D6AD9C00BD734A00BD734A00E7CEC600F7F7F700E7D6
      C600BD734200BD633100A55218008C3900000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000042210000A5845200846339006B52
      29006B5229006B5229006B52290084633900A584520042210000EFE7DE00EFE7
      DE00EFE7DE00EFE7DE00EFEFE7009C8C7B007B2900009C4A1000B55A2900BD73
      4A00DEB5A500F7F7F700F7F7F700F7EFEF00F7F7F700F7F7F700F7F7F700DEB5
      A500BD734A00B55A29009C4A10007B2900000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004A290000A58C6300735A3900FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00735A3900A58C63004A290000BD945A00BD94
      5A00BD945A00EFE7DE00EFEFE7009C8C84000000000094390000A5521800BD73
      4A00CE9C7B00E7CEBD00F7F7F700F7F7F700F7F7F700EFE7DE00E7CEBD00CE8C
      6B00BD7B5200A552180094390000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004A290000B59C730084735200FFFF
      FF00FFFFFF00FFFFFF00FFFFFF0084735200B59C73004A290000EFEFE700EFEF
      E700EFEFE700EFEFE700F7EFEF009C94840000000000843100009C420800AD5A
      2900C6846300CE947300CE947300CE947300CE947300CE947300CE947300C68C
      6300AD6331009C42080084310000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000052290000D6C6AD00B5AD9400FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00B5AD9400D6C6AD0052290000FFFFF700FFFF
      F700FFFFF700FFFFF700FFFFFF00A59484000000000000000000843100009442
      0000AD6B4200CEA58C00DEC6B500E7CEBD00E7CEBD00E7C6B500D6A58C00B56B
      4A009C4200008431000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000003118000052310800523108005231
      08005231080052310800523108005231080052310800735A3900A5948400A594
      8400A5948400A5948400A5948400A59484000000000000000000000000000000
      00008C310000943900009C4208009C4208009C4208009C420800943900008C31
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFF000000000000E000000000000000
      E000000000000000E000000000000000E000000000000000E000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000}
  end
  object Lmod: TModLink
    Left = 1016
    Top = 536
  end
end
