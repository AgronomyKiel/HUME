inherited FormMod_Demo: TFormMod_Demo
  Caption = 'FormMod_Demo'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 15
  inherited PageControl: TPageControl
    ActivePage = TabSheetModelDiagram
    inherited TabSheetGlobal: TTabSheet
      inherited LabelControlFileDesc: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited LabelWeathFileDesc: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited LabelTimeStepDesc: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited LabelStateIniFileName: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited LabelParamIniFileName: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited LabelOutputDirectory: TLabel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditTimeStep: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditStartTime: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditEndTime: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditControlFile: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditWeatherfile: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditStateIniFileName: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited EditParamIniFileName: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited GroupBoxWeatherDates: TGroupBox
        inherited LabelWeatherDataFirstEntry: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited FWDLabel: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited LabelWeatherDataLatEntry: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited LWDLabel: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
      end
      inherited EditOutputDirectory: TEdit
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited BitBtnMergeWeatherFN: TBitBtn
        Left = 897
        Top = 672
        ExplicitLeft = 894
        ExplicitTop = 669
      end
    end
    inherited TabSheetModelDiagram: TTabSheet
      object Mod1: TMod
        Left = 328
        Top = 208
        Width = 88
        Height = 49
        Cursor = crHandPoint
        GM_OutPutPath = 'p:\HumeDemo'
        TimeStep = 1.000000000000000000
        StartTime = 36161.000000000000000000
        EndTime = 36525.000000000000000000
        WriteResIni = True
        ModTime.Name = 'Time'
        ModTime.Opt_writetoFile = True
        ModTime.Opt_SelForSensOut = False
        ModTime.Opt_PlotToGraph = False
        ModTime.Opt_WriteFinalValue = False
        ModTime.Digits = 2
        ModTime.Precision = 6
        ModTime.GlobalOutput = False
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
        SensOpt.Sens_fn = 'sens.dat'
        ContOutput = True
        FinalOutput = True
        Str_SectionName_TimeInit = 'TimeInit'
        Str_SectionName_FileNames = 'FileNames'
        Str_SectionName_SimOptions = 'SimOptions'
        Str_SectionName_MeasurementFiles = 'MeasurementFiles'
        Str_SectionName_UpdateFiles = 'UpdateFiles'
        Str_SectionName_OutPutFiles = 'OutPutFiles'
        Str_SectionTopic_SimStart = 'Startzeit'
        Str_SectionTopic_SimEnd = 'Endzeit'
        Str_SectionTopic_TimeStep = 'TimeStep'
        Str_SectionTopic_ContOutput = 'ContOutput'
        Str_SectionTopic_StateIniFN = 'StateIniFN'
        Str_SectionTopic_ParamIniFN = 'ParamIniFN'
        Str_SectionTopic_WeatherFileFN = 'WeatherFileFN'
        Str_SectionTopic_OptionIniFN = 'OptionsIniFN'
        Str_SectionTopic_OutputDir = 'OutPutDir'
        ReInitAfterRun = True
        ShowDateFormat = True
        Parent = TabSheetModelDiagram
        StatusBar = StatusBarMain
      end
      object LogGrowth1: TLogGrowth
        Left = 488
        Top = 264
        Width = 193
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 0
        FN_ratefn = 'p:\HumeDemo\rate\LogGrowth1_rat.csv'
        FN_Statefn = 'p:\HumeDemo\state\LogGrowth1_dat.csv'
        DebugModus = False
        OptContOutput = True
        Parent = TabSheetModelDiagram
        Var_dW_dt.Name = 'dW_dt'
        Var_dW_dt.Opt_writetoFile = True
        Var_dW_dt.Opt_SelForSensOut = False
        Var_dW_dt.Opt_PlotToGraph = False
        Var_dW_dt.Opt_WriteFinalValue = False
        Var_dW_dt.Digits = 2
        Var_dW_dt.Precision = 6
        Var_dW_dt.GlobalOutput = False
        Var_rgr.Name = 'rgr'
        Var_rgr.Opt_writetoFile = True
        Var_rgr.Opt_SelForSensOut = False
        Var_rgr.Opt_PlotToGraph = False
        Var_rgr.Opt_WriteFinalValue = False
        Var_rgr.Digits = 2
        Var_rgr.Precision = 6
        Var_rgr.GlobalOutput = False
        St_Educt.Name = 'Educt'
        St_Educt.Opt_writetoFile = True
        St_Educt.Opt_SelForSensOut = False
        St_Educt.Opt_PlotToGraph = False
        St_Educt.Opt_WriteFinalValue = False
        St_Educt.Digits = 2
        St_Educt.Precision = 6
        St_Educt.GlobalOutput = False
        St_Educt.v = 100.000000000000000000
        St_Product.Name = 'Product'
        St_Product.Opt_writetoFile = True
        St_Product.Opt_SelForSensOut = False
        St_Product.Opt_PlotToGraph = False
        St_Product.Opt_WriteFinalValue = False
        St_Product.Digits = 2
        St_Product.Precision = 6
        St_Product.GlobalOutput = False
        Par_mue.Name = 'mue'
        Par_mue.Opt_writetoFile = False
        Par_mue.Opt_SelForSensOut = False
        Par_mue.Opt_PlotToGraph = False
        Par_mue.Opt_WriteFinalValue = False
        Par_mue.Digits = 2
        Par_mue.Precision = 6
        Par_mue.GlobalOutput = False
        Par_mue.opt_SelForSens = False
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_SelForSensOut = False
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.GlobalOutput = False
        Ex_Temp.Ex = StateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
      end
    end
    inherited TabSheetParameter: TTabSheet
      inherited ToolBarParSheet: TToolBar
        inherited LabelparamFileName: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited EditParamFileName: TEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited TabSheetState: TTabSheet
      inherited ToolBarStateSheet: TToolBar
        inherited LabelStateFileName: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited EditStateFileName: TEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited TabSheetOptions: TTabSheet
      inherited ToolBarOptions: TToolBar
        inherited LabelOptionsFilename: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited EditOptionsFileName: TEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited TabSheetData: TTabSheet
      inherited ToolBarDataPage: TToolBar
        inherited LabelDataFileNameDesc: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited EditDataFileName: TEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited TabSheetResultTab: TTabSheet
      inherited ToolBarPageTable: TToolBar
        inherited LabelOutputdatafile: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited EditOutputdatafilename: TEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited TabSheetGraphResult: TTabSheet
      inherited ToolBarPlotPage: TToolBar
        inherited LabelTimeSeriesOption: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited ComboBoxTimeAxisOption: TComboBox
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited TabSheetDocumentation: TTabSheet
      inherited ToolBarDocu: TToolBar
        inherited EditDokuFilename: TEdit
          StyleElements = [seFont, seClient, seBorder]
        end
      end
      inherited MemoModelDocu: TMemo
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
  inherited Panel1: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited LabelActIniFileDesc: TLabel
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited LabelSubModelCombobox: TLabel
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxSubMod: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxIniFile: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
  end
  inherited Lmod: TModLink
    LinkedModel = Mod1
  end
end
