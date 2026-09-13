object FormCalcTimes: TFormCalcTimes
  Left = 0
  Top = 0
  Caption = 'Calculation times'
  ClientHeight = 300
  ClientWidth = 560
  Color = clBtnFace
  Constraints.MinHeight = 240
  Constraints.MinWidth = 440
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object PanelFileName: TPanel
    Left = 0
    Top = 0
    Width = 560
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      560
      41)
    object LabelFileName: TLabel
      Left = 8
      Top = 13
      Width = 48
      Height = 13
      Caption = 'File name'
    end
    object EditFileName: TEdit
      Left = 64
      Top = 9
      Width = 488
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      ReadOnly = True
      TabOrder = 0
    end
  end
  object MemoCalcTimes: TMemo
    Left = 0
    Top = 41
    Width = 560
    Height = 218
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 259
    Width = 560
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      560
      41)
    object ButtonCopy: TButton
      Left = 374
      Top = 8
      Width = 88
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Copy'
      TabOrder = 0
      OnClick = ButtonCopyClick
    end
    object ButtonClose: TButton
      Left = 470
      Top = 8
      Width = 82
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Close'
      ModalResult = 8
      TabOrder = 1
    end
  end
end