inherited FormMod2: TFormMod2
  Caption = 'FormMod2'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl: TPageControl
    ActivePage = TabSheetModelDiagram
    inherited TabSheetGlobal: TTabSheet
      ExplicitLeft = 7
      ExplicitTop = 7
      ExplicitWidth = 931
      ExplicitHeight = 532
      inherited btnCheckButton1: TSpeedButton
        Left = 280
        Top = 515
        ExplicitLeft = 280
        ExplicitTop = 515
      end
      inherited btnButtonSaveIntegrChanges1: TSpeedButton
        Left = 432
        Top = 515
        ExplicitLeft = 432
        ExplicitTop = 515
      end
      inherited btnButtonSaveToNewIniFile1: TSpeedButton
        Left = 498
        Top = 515
        ExplicitLeft = 498
        ExplicitTop = 515
      end
      inherited BitBtnMergeWeatherFN: TBitBtn
        Left = 738
        Top = 485
        ExplicitLeft = 726
        ExplicitTop = 473
      end
    end
    inherited TabSheetModelDiagram: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
      object Mod1: TMod
        Left = 264
        Top = 232
        Width = 115
        Height = 62
        Cursor = crHandPoint
        Parent = TabSheetModelDiagram
        GM_ControlFile = 'Q:\HUME\HUME\Tools\MMtoD\loggrowth.fn'
        TimeStep = 1.000000000000000000
        StartTime = 36161.000000000000000000
        EndTime = 36525.000000000000000000
        ModTime.Name = 'Time'
        ModTime.Opt_writetoFile = True
        ModTime.Opt_SelForSensOut = False
        ModTime.Opt_PlotToGraph = False
        ModTime.Opt_WriteFinalValue = False
        ModTime.Digits = 2
        ModTime.Precision = 6
        ModTime.v = 36161.000000000000000000
        LMOptions.IniLambda = 0.001000000000000000
        LMOptions.Divisor = 100.000000000000000000
        LMOptions.WeightOptions = OptNoWeight
        LMOptions.DefaultError = 0.100000000000000000
        LMOptions.OptOption = optOnlyActIni
        SensOpt.MaxValue = 10.000000000000000000
        SensOpt.MinValue = 1.000000000000000000
        SensOpt.Steps = 5
        SensOpt.DPar = 1.000000000000000000
        SensOpt.Sens_fn = 'Sens.dat'
        ContOutput = True
        FinalOutput = False
        StatusBar = StatusBarMain
        Str_SectionName_TimeInit = 'TimeInit'
        Str_SectionName_FileNames = 'FileNames'
        Str_SectionName_MeasurementFiles = 'MeasurementFiles'
        Str_SectionName_UpdateFiles = 'UpdateFiles'
        Str_SectionName_OutPutFiles = 'OutPutFiles'
        Str_SectionTopic_SimStart = 'Startzeit'
        Str_SectionTopic_SimEnd = 'Endzeit'
        Str_SectionTopic_TimeStep = 'TimeStep'
        Str_SectionTopic_StateIniFN = 'StateIniFN'
        Str_SectionTopic_ParamIniFN = 'ParamIniFN'
        Str_SectionTopic_WeatherFileFN = 'WeatherFileFN'
        Str_SectionTopic_OptionIniFN = 'OptionsIniFN'
        Str_SectionTopic_OutputDir = 'OutPutDir'
        ReInitAfterRun = True
        ShowDateFormat = True
      end
      object LogGrowth1: TLogGrowth
        Left = 424
        Top = 232
        Width = 145
        Height = 62
        Cursor = crHandPoint
        Parent = TabSheetModelDiagram
        SM_GlobMod = Mod1
        CompIndex = 0
        FN_ratefn = 'LogGrowth1_rat.csv'
        FN_Statefn = 'LogGrowth1_dat.csv'
        DebugModus = False
        Var_dW_dt.Name = 'dW_dt'
        Var_dW_dt.Opt_writetoFile = True
        Var_dW_dt.Opt_SelForSensOut = False
        Var_dW_dt.Opt_PlotToGraph = False
        Var_dW_dt.Opt_WriteFinalValue = False
        Var_dW_dt.Digits = 2
        Var_dW_dt.Precision = 6
        Var_rgr.Name = 'rgr'
        Var_rgr.Opt_writetoFile = True
        Var_rgr.Opt_SelForSensOut = False
        Var_rgr.Opt_PlotToGraph = False
        Var_rgr.Opt_WriteFinalValue = False
        Var_rgr.Digits = 2
        Var_rgr.Precision = 6
        St_Educt.Name = 'Educt'
        St_Educt.Opt_writetoFile = True
        St_Educt.Opt_SelForSensOut = False
        St_Educt.Opt_PlotToGraph = False
        St_Educt.Opt_WriteFinalValue = False
        St_Educt.Digits = 2
        St_Educt.Precision = 6
        St_Educt.v = 100.000000000000000000
        St_Product.Name = 'Product'
        St_Product.Opt_writetoFile = True
        St_Product.Opt_SelForSensOut = False
        St_Product.Opt_PlotToGraph = False
        St_Product.Opt_WriteFinalValue = False
        St_Product.Digits = 2
        St_Product.Precision = 6
        Par_mue.Name = 'mue'
        Par_mue.Opt_writetoFile = False
        Par_mue.Opt_SelForSensOut = False
        Par_mue.Opt_PlotToGraph = False
        Par_mue.Opt_WriteFinalValue = False
        Par_mue.Digits = 2
        Par_mue.Precision = 6
        Par_mue.opt_SelForSens = False
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_SelForSensOut = False
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.Ex = StateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
      end
    end
    inherited TabSheetParameter: TTabSheet
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      inherited ToolBarParSheet: TToolBar
        inherited LabelparamFileName: TLabel
          Height = 13
          ExplicitHeight = 13
        end
      end
    end
    inherited TabSheetState: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
      inherited ToolBarStateSheet: TToolBar
        inherited LabelStateFileName: TLabel
          Height = 13
          ExplicitHeight = 13
        end
      end
    end
    inherited TabSheetVariables: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
    end
    inherited TabSheetExternalValues: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
    end
    inherited TabSheetOptions: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
      inherited ToolBarOptions: TToolBar
        inherited LabelOptionsFilename: TLabel
          Height = 13
          ExplicitHeight = 13
        end
      end
    end
    inherited TabSheetData: TTabSheet
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      inherited ToolBarDataPage: TToolBar
        inherited LabelDataFileNameDesc: TLabel
          Height = 13
          ExplicitHeight = 13
        end
      end
    end
    inherited TabSheetStat: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
    end
    inherited TabSheetResultTab: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
      inherited ToolBarPageTable: TToolBar
        inherited LabelOutputdatafile: TLabel
          Height = 13
          ExplicitHeight = 13
        end
      end
    end
    inherited TabSheetGraphResult: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
    end
    inherited TabSheetDocumentation: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 937
      ExplicitHeight = 538
    end
  end
  inherited Lmod: TModLink
    LinkedModel = Mod1
  end
end
