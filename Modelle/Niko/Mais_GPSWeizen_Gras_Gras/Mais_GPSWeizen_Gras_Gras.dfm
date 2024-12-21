inherited FormMod2: TFormMod2
  Caption = 'FormMod2'
  ExplicitWidth = 812
  ExplicitHeight = 531
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl: TPageControl
    inherited TabSheetGlobal: TTabSheet
      ExplicitLeft = 7
      ExplicitTop = 7
      ExplicitWidth = 784
      ExplicitHeight = 390
    end
    inherited TabSheetModelDiagram: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
      object Mais: TGrowthCurvePlantRoots
        Left = 152
        Top = 152
        Width = 122
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 0
        FN_ratefn = 'C:\Modelle\out\Mais_rat.csv'
        FN_Statefn = 'C:\Modelle\out\Mais_dat.csv'
        SoilMinMOd = MinMod2Pool1
        SoilLayerMod = SoilNitrogenUp1
        EvapModel = PenMonteith1
        Par_SowingDate.Name = 'SowingDate'
        Par_SowingDate.Opt_writetoFile = True
        Par_SowingDate.Opt_PlotToGraph = False
        Par_SowingDate.Opt_WriteFinalValue = False
        Par_SowingDate.Digits = 2
        Par_SowingDate.Precision = 6
        Par_HarvestDate.Name = 'HarvestDate'
        Par_HarvestDate.Opt_writetoFile = True
        Par_HarvestDate.Opt_PlotToGraph = False
        Par_HarvestDate.Opt_WriteFinalValue = False
        Par_HarvestDate.Digits = 2
        Par_HarvestDate.Precision = 6
        Par_HarvestDate.v = 1000000.000000000000000000
        NextCrop = GPS_Weizen
        Rotationlength = 0
        St_C_Residues.Name = 'C_Residues'
        St_C_Residues.Opt_writetoFile = True
        St_C_Residues.Opt_PlotToGraph = False
        St_C_Residues.Opt_WriteFinalValue = False
        St_C_Residues.Digits = 2
        St_C_Residues.Precision = 6
        St_N_Residues.Name = 'N_Residues'
        St_N_Residues.Opt_writetoFile = True
        St_N_Residues.Opt_PlotToGraph = False
        St_N_Residues.Opt_WriteFinalValue = False
        St_N_Residues.Digits = 2
        St_N_Residues.Precision = 6
        SetNewDates = False
        withRoots = True
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.Ex = RateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
        Par_LAImax.Name = 'LAI_Capacity'
        Par_LAImax.Opt_writetoFile = True
        Par_LAImax.Opt_PlotToGraph = False
        Par_LAImax.Opt_WriteFinalValue = False
        Par_LAImax.Digits = 2
        Par_LAImax.Precision = 6
        Par_TempsumEmerge.Name = 'TempSumEmerge'
        Par_TempsumEmerge.Opt_writetoFile = True
        Par_TempsumEmerge.Opt_PlotToGraph = False
        Par_TempsumEmerge.Opt_WriteFinalValue = False
        Par_TempsumEmerge.Digits = 2
        Par_TempsumEmerge.Precision = 6
        Par_TempsumEmerge.v = 150.000000000000000000
        Par_zr0.Name = 'zr_0'
        Par_zr0.Opt_writetoFile = True
        Par_zr0.Opt_PlotToGraph = False
        Par_zr0.Opt_WriteFinalValue = False
        Par_zr0.Digits = 2
        Par_zr0.Precision = 6
        Par_zr0.v = 10.000000000000000000
        Par_zrmax.Name = 'zr_max'
        Par_zrmax.Opt_writetoFile = True
        Par_zrmax.Opt_PlotToGraph = False
        Par_zrmax.Opt_WriteFinalValue = False
        Par_zrmax.Digits = 2
        Par_zrmax.Precision = 6
        Par_zrmax.v = 120.000000000000000000
        Par_kz.Name = 'k_z'
        Par_kz.Opt_writetoFile = True
        Par_kz.Opt_PlotToGraph = False
        Par_kz.Opt_WriteFinalValue = False
        Par_kz.Digits = 2
        Par_kz.Precision = 6
        Par_kz.v = 0.000900000000000000
        Par_Wl0.Name = 'WL_0'
        Par_Wl0.Opt_writetoFile = True
        Par_Wl0.Opt_PlotToGraph = False
        Par_Wl0.Opt_WriteFinalValue = False
        Par_Wl0.Digits = 2
        Par_Wl0.Precision = 6
        Par_Wl0.v = 1.000000000000000000
        Par_Wlmax.Name = 'WL_max'
        Par_Wlmax.Opt_writetoFile = True
        Par_Wlmax.Opt_PlotToGraph = False
        Par_Wlmax.Opt_WriteFinalValue = False
        Par_Wlmax.Digits = 2
        Par_Wlmax.Precision = 6
        Par_Wlmax.v = 15.000000000000000000
        Par_kWL.Name = 'k_WL'
        Par_kWL.Opt_writetoFile = True
        Par_kWL.Opt_PlotToGraph = False
        Par_kWL.Opt_WriteFinalValue = False
        Par_kWL.Digits = 2
        Par_kWL.Precision = 6
        Par_kWL.v = 0.002000000000000000
        Par_ActiveDuration.Name = 'ActiveDuration'
        Par_ActiveDuration.Opt_writetoFile = True
        Par_ActiveDuration.Opt_PlotToGraph = False
        Par_ActiveDuration.Opt_WriteFinalValue = False
        Par_ActiveDuration.Digits = 2
        Par_ActiveDuration.Precision = 6
        Par_ActiveDuration.v = 20.000000000000000000
      end
      object Gras_Gras: TMultiGrowthCurvePlantRoots
        Left = 480
        Top = 152
        Width = 241
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 1
        FN_ratefn = 'C:\Modelle\out\Gras_Gras_rat.csv'
        FN_Statefn = 'C:\Modelle\out\Gras_Gras_dat.csv'
        SoilMinMOd = MinMod2Pool1
        SoilLayerMod = SoilNitrogenUp1
        EvapModel = PenMonteith1
        Par_SowingDate.Name = 'SowingDate'
        Par_SowingDate.Opt_writetoFile = True
        Par_SowingDate.Opt_PlotToGraph = False
        Par_SowingDate.Opt_WriteFinalValue = False
        Par_SowingDate.Digits = 2
        Par_SowingDate.Precision = 6
        Par_HarvestDate.Name = 'HarvestDate'
        Par_HarvestDate.Opt_writetoFile = True
        Par_HarvestDate.Opt_PlotToGraph = False
        Par_HarvestDate.Opt_WriteFinalValue = False
        Par_HarvestDate.Digits = 2
        Par_HarvestDate.Precision = 6
        Par_HarvestDate.v = 1000000.000000000000000000
        Rotationlength = 0
        St_C_Residues.Name = 'C_Residues'
        St_C_Residues.Opt_writetoFile = True
        St_C_Residues.Opt_PlotToGraph = False
        St_C_Residues.Opt_WriteFinalValue = False
        St_C_Residues.Digits = 2
        St_C_Residues.Precision = 6
        St_N_Residues.Name = 'N_Residues'
        St_N_Residues.Opt_writetoFile = True
        St_N_Residues.Opt_PlotToGraph = False
        St_N_Residues.Opt_WriteFinalValue = False
        St_N_Residues.Digits = 2
        St_N_Residues.Precision = 6
        SetNewDates = False
        withRoots = True
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.Ex = RateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
        Par_LAImax.Name = 'LAI_Capacity'
        Par_LAImax.Opt_writetoFile = True
        Par_LAImax.Opt_PlotToGraph = False
        Par_LAImax.Opt_WriteFinalValue = False
        Par_LAImax.Digits = 2
        Par_LAImax.Precision = 6
        Par_TempsumEmerge.Name = 'TempSumEmerge'
        Par_TempsumEmerge.Opt_writetoFile = True
        Par_TempsumEmerge.Opt_PlotToGraph = False
        Par_TempsumEmerge.Opt_WriteFinalValue = False
        Par_TempsumEmerge.Digits = 2
        Par_TempsumEmerge.Precision = 6
        Par_TempsumEmerge.v = 150.000000000000000000
        Par_zr0.Name = 'zr_0'
        Par_zr0.Opt_writetoFile = True
        Par_zr0.Opt_PlotToGraph = False
        Par_zr0.Opt_WriteFinalValue = False
        Par_zr0.Digits = 2
        Par_zr0.Precision = 6
        Par_zr0.v = 10.000000000000000000
        Par_zrmax.Name = 'zr_max'
        Par_zrmax.Opt_writetoFile = True
        Par_zrmax.Opt_PlotToGraph = False
        Par_zrmax.Opt_WriteFinalValue = False
        Par_zrmax.Digits = 2
        Par_zrmax.Precision = 6
        Par_zrmax.v = 120.000000000000000000
        Par_kz.Name = 'k_z'
        Par_kz.Opt_writetoFile = True
        Par_kz.Opt_PlotToGraph = False
        Par_kz.Opt_WriteFinalValue = False
        Par_kz.Digits = 2
        Par_kz.Precision = 6
        Par_kz.v = 0.000900000000000000
        Par_ActiveDuration.Name = 'ActiveDuration'
        Par_ActiveDuration.Opt_writetoFile = True
        Par_ActiveDuration.Opt_PlotToGraph = False
        Par_ActiveDuration.Opt_WriteFinalValue = False
        Par_ActiveDuration.Digits = 2
        Par_ActiveDuration.Precision = 6
        Par_ActiveDuration.v = 20.000000000000000000
        Par_Wl0.Name = 'WL_0'
        Par_Wl0.Opt_writetoFile = True
        Par_Wl0.Opt_PlotToGraph = False
        Par_Wl0.Opt_WriteFinalValue = False
        Par_Wl0.Digits = 2
        Par_Wl0.Precision = 6
        Par_Wl0.v = 1.000000000000000000
        Par_Wlmax.Name = 'WL_max'
        Par_Wlmax.Opt_writetoFile = True
        Par_Wlmax.Opt_PlotToGraph = False
        Par_Wlmax.Opt_WriteFinalValue = False
        Par_Wlmax.Digits = 2
        Par_Wlmax.Precision = 6
        Par_Wlmax.v = 15.000000000000000000
        Par_kWL.Name = 'k_WL'
        Par_kWL.Opt_writetoFile = True
        Par_kWL.Opt_PlotToGraph = False
        Par_kWL.Opt_WriteFinalValue = False
        Par_kWL.Digits = 2
        Par_kWL.Precision = 6
        Par_kWL.v = 0.002000000000000000
      end
      object PenMonteith1: TPenMonteith
        Left = 219
        Top = 48
        Width = 177
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 2
        FN_ratefn = 'C:\Modelle\out\PenMonteith1_rat.csv'
        FN_Statefn = 'C:\Modelle\out\PenMonteith1_dat.csv'
        PlantModel = Gras
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.Ex = StateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
        Ex_GlobRad.Name = 'Rad_Int'
        Ex_GlobRad.Opt_writetoFile = True
        Ex_GlobRad.Opt_PlotToGraph = False
        Ex_GlobRad.Opt_WriteFinalValue = False
        Ex_GlobRad.Digits = 0
        Ex_GlobRad.Precision = 0
        Ex_GlobRad.Ex = StateField
        Ex_GlobRad.Search = True
        Ex_GlobRad.C_f = 1.000000000000000000
        Ex_Sat_def.Name = 'Sat_def'
        Ex_Sat_def.Opt_writetoFile = True
        Ex_Sat_def.Opt_PlotToGraph = False
        Ex_Sat_def.Opt_WriteFinalValue = False
        Ex_Sat_def.Digits = 0
        Ex_Sat_def.Precision = 0
        Ex_Sat_def.Ex = StateField
        Ex_Sat_def.Search = True
        Ex_Sat_def.C_f = 1.000000000000000000
        Ex_Windspeed.Name = 'Wind'
        Ex_Windspeed.Opt_writetoFile = True
        Ex_Windspeed.Opt_PlotToGraph = False
        Ex_Windspeed.Opt_WriteFinalValue = False
        Ex_Windspeed.Digits = 0
        Ex_Windspeed.Precision = 0
        Ex_Windspeed.Ex = StateField
        Ex_Windspeed.Search = True
        Ex_Windspeed.C_f = 1.000000000000000000
        Ex_CropHeight.Name = 'CropHeight'
        Ex_CropHeight.Opt_writetoFile = True
        Ex_CropHeight.Opt_PlotToGraph = False
        Ex_CropHeight.Opt_WriteFinalValue = False
        Ex_CropHeight.Digits = 0
        Ex_CropHeight.Precision = 0
        Ex_CropHeight.Ex = StateField
        Ex_CropHeight.Search = False
        Ex_CropHeight.C_f = 1.000000000000000000
        Ex_CropHeight.Source = 'Gras'
        Ex_LAI.Name = 'LAI'
        Ex_LAI.Opt_writetoFile = True
        Ex_LAI.Opt_PlotToGraph = False
        Ex_LAI.Opt_WriteFinalValue = False
        Ex_LAI.Digits = 0
        Ex_LAI.Precision = 0
        Ex_LAI.Ex = StateField
        Ex_LAI.Search = False
        Ex_LAI.C_f = 1.000000000000000000
        Ex_LAI.Source = 'Gras'
        Ex_Rain.Name = 'rain'
        Ex_Rain.Opt_writetoFile = True
        Ex_Rain.Opt_PlotToGraph = False
        Ex_Rain.Opt_WriteFinalValue = False
        Ex_Rain.Digits = 0
        Ex_Rain.Precision = 0
        Ex_Rain.Ex = StateField
        Ex_Rain.Search = True
        Ex_Rain.C_f = 1.000000000000000000
        Par_RC0.Name = 'rc0'
        Par_RC0.Opt_writetoFile = True
        Par_RC0.Opt_PlotToGraph = False
        Par_RC0.Opt_WriteFinalValue = False
        Par_RC0.Digits = 2
        Par_RC0.Precision = 6
        Par_RC0.v = 50.000000000000000000
        Par_Exk_Glob.Name = 'exk_GlobRad'
        Par_Exk_Glob.Opt_writetoFile = True
        Par_Exk_Glob.Opt_PlotToGraph = False
        Par_Exk_Glob.Opt_WriteFinalValue = False
        Par_Exk_Glob.Digits = 2
        Par_Exk_Glob.Precision = 6
        Par_Exk_Glob.v = 0.500000000000000000
        Par_Elev.Name = 'Elev'
        Par_Elev.Opt_writetoFile = True
        Par_Elev.Opt_PlotToGraph = False
        Par_Elev.Opt_WriteFinalValue = False
        Par_Elev.Digits = 2
        Par_Elev.Precision = 6
        Par_Elev.v = 50.000000000000000000
        Par_SIC.Name = 'SIC'
        Par_SIC.Opt_writetoFile = True
        Par_SIC.Opt_PlotToGraph = False
        Par_SIC.Opt_WriteFinalValue = False
        Par_SIC.Digits = 2
        Par_SIC.Precision = 6
        Par_SIC.v = 0.150000000000000000
        Par_measure_height.Name = 'measure_height'
        Par_measure_height.Opt_writetoFile = True
        Par_measure_height.Opt_PlotToGraph = False
        Par_measure_height.Opt_WriteFinalValue = False
        Par_measure_height.Digits = 2
        Par_measure_height.Precision = 6
        Par_measure_height.v = 2.000000000000000000
        Var_pETP.Name = 'pETP'
        Var_pETP.Opt_writetoFile = True
        Var_pETP.Opt_PlotToGraph = False
        Var_pETP.Opt_WriteFinalValue = False
        Var_pETP.Digits = 2
        Var_pETP.Precision = 6
        Var_PotTrans.Name = 'PotTrans'
        Var_PotTrans.Opt_writetoFile = True
        Var_PotTrans.Opt_PlotToGraph = False
        Var_PotTrans.Opt_WriteFinalValue = False
        Var_PotTrans.Digits = 2
        Var_PotTrans.Precision = 6
        Var_PotEvap.Name = 'PotEvap'
        Var_PotEvap.Opt_writetoFile = True
        Var_PotEvap.Opt_PlotToGraph = False
        Var_PotEvap.Opt_WriteFinalValue = False
        Var_PotEvap.Digits = 2
        Var_PotEvap.Precision = 6
        Var_interzeption.Name = 'interzeption'
        Var_interzeption.Opt_writetoFile = True
        Var_interzeption.Opt_PlotToGraph = False
        Var_interzeption.Opt_WriteFinalValue = False
        Var_interzeption.Digits = 2
        Var_interzeption.Precision = 6
        Var_NetRain.Name = 'NetRain'
        Var_NetRain.Opt_writetoFile = True
        Var_NetRain.Opt_PlotToGraph = False
        Var_NetRain.Opt_WriteFinalValue = False
        Var_NetRain.Digits = 2
        Var_NetRain.Precision = 6
        Var_ra.Name = 'ra'
        Var_ra.Opt_writetoFile = True
        Var_ra.Opt_PlotToGraph = False
        Var_ra.Opt_WriteFinalValue = False
        Var_ra.Digits = 2
        Var_ra.Precision = 6
        Var_NetRad.Name = 'NetRad'
        Var_NetRad.Opt_writetoFile = True
        Var_NetRad.Opt_PlotToGraph = False
        Var_NetRad.Opt_WriteFinalValue = False
        Var_NetRad.Digits = 2
        Var_NetRad.Precision = 6
        Opt_Exk_Glob = fromParameter
        Opt_rc0 = fromParameter
      end
      object SoilNitrogenUp1: TSoilNitrogenUp
        Left = 24
        Top = 266
        Width = 169
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 3
        FN_ratefn = 'C:\Modelle\out\SoilNitrogenUp1_rat.csv'
        FN_Statefn = 'C:\Modelle\out\SoilNitrogenUp1_dat.csv'
        PlantModel = Gras
        parMaxTiefe.Name = 'MaxTiefe'
        parMaxTiefe.Opt_writetoFile = True
        parMaxTiefe.Opt_PlotToGraph = False
        parMaxTiefe.Opt_WriteFinalValue = False
        parMaxTiefe.Digits = 2
        parMaxTiefe.Precision = 6
        parMaxTiefe.v = 200.000000000000000000
        p_NComp = 20
        m_model = Mualem
        Opt_CompMethod = Potential
        Opt_red_f = modifiedBeese
        Opt_maxWGchange = 0.010000000000000000
        Opt_Randbed = content
        Opt_IniMethod = Watercontents
        Opt_maxdt = 1.000000000000000000
        Opt_nFKCalcMethod = FromParameter
        Opt_VanGenPars_from_Texture = FromTexture
        Opt_Ks_from_Texture = FromTexture
        Opt_TextureClass1 = Sl4
        Opt_TextureClass2 = Sl4
        Opt_TextureClass3 = Sl4
        Opt_TextureClass4 = Sl4
        Opt_TransferWGsToNextINI = False
        Opt_Weff = fromParameter
        Ex_Groundwaterdepth.Name = 'Groundwaterdepth'
        Ex_Groundwaterdepth.Opt_writetoFile = True
        Ex_Groundwaterdepth.Opt_PlotToGraph = False
        Ex_Groundwaterdepth.Opt_WriteFinalValue = False
        Ex_Groundwaterdepth.Digits = 0
        Ex_Groundwaterdepth.Precision = 0
        Ex_Groundwaterdepth.Ex = StateField
        Ex_Groundwaterdepth.Search = False
        Ex_Groundwaterdepth.C_f = 1.000000000000000000
        Par_b_sat1.Name = 'b_sat1'
        Par_b_sat1.Opt_writetoFile = True
        Par_b_sat1.Opt_PlotToGraph = False
        Par_b_sat1.Opt_WriteFinalValue = False
        Par_b_sat1.Digits = 2
        Par_b_sat1.Precision = 6
        Par_b_sat1.v = 0.429800000000000000
        Par_b_rest1.Name = 'b_rest1'
        Par_b_rest1.Opt_writetoFile = True
        Par_b_rest1.Opt_PlotToGraph = False
        Par_b_rest1.Opt_WriteFinalValue = False
        Par_b_rest1.Digits = 2
        Par_b_rest1.Precision = 6
        Par_b_rest1.v = 0.090000000000000000
        Par_b_KS1.Name = 'Ks_1'
        Par_b_KS1.Opt_writetoFile = True
        Par_b_KS1.Opt_PlotToGraph = False
        Par_b_KS1.Opt_WriteFinalValue = False
        Par_b_KS1.Digits = 2
        Par_b_KS1.Precision = 6
        Par_b_KS1.v = 50.000000000000000000
        Par_n1.Name = 'n_par1'
        Par_n1.Opt_writetoFile = True
        Par_n1.Opt_PlotToGraph = False
        Par_n1.Opt_WriteFinalValue = False
        Par_n1.Digits = 2
        Par_n1.Precision = 6
        Par_n1.v = 1.294940000000000000
        Par_alpha1.Name = 'alpha1'
        Par_alpha1.Comment = 'Van-Genuchten-Parameter alpha f'#252'r den 1. Bodenhorizont'
        Par_alpha1.Opt_writetoFile = True
        Par_alpha1.Opt_PlotToGraph = False
        Par_alpha1.Opt_WriteFinalValue = False
        Par_alpha1.Digits = 2
        Par_alpha1.Precision = 6
        Par_alpha1.v = 0.006770000000000000
        Par_FK1.Name = 'FK_1'
        Par_FK1.Opt_writetoFile = True
        Par_FK1.Opt_PlotToGraph = False
        Par_FK1.Opt_WriteFinalValue = False
        Par_FK1.Digits = 2
        Par_FK1.Precision = 6
        Par_FK1.v = 0.350000000000000000
        Par_PWP1.Name = 'PWP_1'
        Par_PWP1.Opt_writetoFile = True
        Par_PWP1.Opt_PlotToGraph = False
        Par_PWP1.Opt_WriteFinalValue = False
        Par_PWP1.Digits = 2
        Par_PWP1.Precision = 6
        Par_PWP1.v = 0.100000000000000000
        Par_b_sat2.Name = 'b_sat2'
        Par_b_sat2.Opt_writetoFile = True
        Par_b_sat2.Opt_PlotToGraph = False
        Par_b_sat2.Opt_WriteFinalValue = False
        Par_b_sat2.Digits = 2
        Par_b_sat2.Precision = 6
        Par_b_sat2.v = 0.450000000000000000
        Par_b_rest2.Name = 'b_rest2'
        Par_b_rest2.Opt_writetoFile = True
        Par_b_rest2.Opt_PlotToGraph = False
        Par_b_rest2.Opt_WriteFinalValue = False
        Par_b_rest2.Digits = 2
        Par_b_rest2.Precision = 6
        Par_b_rest2.v = 0.090000000000000000
        Par_b_KS2.Name = 'Ks_2'
        Par_b_KS2.Opt_writetoFile = True
        Par_b_KS2.Opt_PlotToGraph = False
        Par_b_KS2.Opt_WriteFinalValue = False
        Par_b_KS2.Digits = 2
        Par_b_KS2.Precision = 6
        Par_b_KS2.v = 50.000000000000000000
        Par_n2.Name = 'n_par2'
        Par_n2.Opt_writetoFile = True
        Par_n2.Opt_PlotToGraph = False
        Par_n2.Opt_WriteFinalValue = False
        Par_n2.Digits = 2
        Par_n2.Precision = 6
        Par_n2.v = 1.294940000000000000
        Par_alpha2.Name = 'alpha2'
        Par_alpha2.Opt_writetoFile = True
        Par_alpha2.Opt_PlotToGraph = False
        Par_alpha2.Opt_WriteFinalValue = False
        Par_alpha2.Digits = 2
        Par_alpha2.Precision = 6
        Par_alpha2.v = 0.006770000000000000
        Par_FK2.Name = 'FK_2'
        Par_FK2.Opt_writetoFile = True
        Par_FK2.Opt_PlotToGraph = False
        Par_FK2.Opt_WriteFinalValue = False
        Par_FK2.Digits = 2
        Par_FK2.Precision = 6
        Par_FK2.v = 0.350000000000000000
        Par_PWP2.Name = 'PWP_2'
        Par_PWP2.Opt_writetoFile = True
        Par_PWP2.Opt_PlotToGraph = False
        Par_PWP2.Opt_WriteFinalValue = False
        Par_PWP2.Digits = 2
        Par_PWP2.Precision = 6
        Par_PWP2.v = 0.100000000000000000
        Par_b_sat3.Name = 'b_sat3'
        Par_b_sat3.Opt_writetoFile = True
        Par_b_sat3.Opt_PlotToGraph = False
        Par_b_sat3.Opt_WriteFinalValue = False
        Par_b_sat3.Digits = 2
        Par_b_sat3.Precision = 6
        Par_b_sat3.v = 0.450000000000000000
        Par_b_rest3.Name = 'b_rest3'
        Par_b_rest3.Opt_writetoFile = True
        Par_b_rest3.Opt_PlotToGraph = False
        Par_b_rest3.Opt_WriteFinalValue = False
        Par_b_rest3.Digits = 2
        Par_b_rest3.Precision = 6
        Par_b_rest3.v = 0.090000000000000000
        Par_b_KS3.Name = 'Ks_3'
        Par_b_KS3.Opt_writetoFile = True
        Par_b_KS3.Opt_PlotToGraph = False
        Par_b_KS3.Opt_WriteFinalValue = False
        Par_b_KS3.Digits = 2
        Par_b_KS3.Precision = 6
        Par_b_KS3.v = 50.000000000000000000
        Par_n3.Name = 'n_par3'
        Par_n3.Opt_writetoFile = True
        Par_n3.Opt_PlotToGraph = False
        Par_n3.Opt_WriteFinalValue = False
        Par_n3.Digits = 2
        Par_n3.Precision = 6
        Par_n3.v = 1.294940000000000000
        Par_alpha3.Name = 'alpha3'
        Par_alpha3.Opt_writetoFile = True
        Par_alpha3.Opt_PlotToGraph = False
        Par_alpha3.Opt_WriteFinalValue = False
        Par_alpha3.Digits = 2
        Par_alpha3.Precision = 6
        Par_alpha3.v = 0.006770000000000000
        Par_FK3.Name = 'FK_3'
        Par_FK3.Opt_writetoFile = True
        Par_FK3.Opt_PlotToGraph = False
        Par_FK3.Opt_WriteFinalValue = False
        Par_FK3.Digits = 2
        Par_FK3.Precision = 6
        Par_FK3.v = 0.350000000000000000
        Par_PWP3.Name = 'PWP_3'
        Par_PWP3.Opt_writetoFile = True
        Par_PWP3.Opt_PlotToGraph = False
        Par_PWP3.Opt_WriteFinalValue = False
        Par_PWP3.Digits = 2
        Par_PWP3.Precision = 6
        Par_PWP3.v = 0.100000000000000000
        Par_b_sat4.Name = 'b_sat4'
        Par_b_sat4.Opt_writetoFile = True
        Par_b_sat4.Opt_PlotToGraph = False
        Par_b_sat4.Opt_WriteFinalValue = False
        Par_b_sat4.Digits = 2
        Par_b_sat4.Precision = 6
        Par_b_sat4.v = 0.450000000000000000
        Par_b_rest4.Name = 'b_rest4'
        Par_b_rest4.Opt_writetoFile = True
        Par_b_rest4.Opt_PlotToGraph = False
        Par_b_rest4.Opt_WriteFinalValue = False
        Par_b_rest4.Digits = 2
        Par_b_rest4.Precision = 6
        Par_b_rest4.v = 0.090000000000000000
        Par_b_KS4.Name = 'Ks_4'
        Par_b_KS4.Opt_writetoFile = True
        Par_b_KS4.Opt_PlotToGraph = False
        Par_b_KS4.Opt_WriteFinalValue = False
        Par_b_KS4.Digits = 2
        Par_b_KS4.Precision = 6
        Par_b_KS4.v = 50.000000000000000000
        Par_n4.Name = 'n_par4'
        Par_n4.Opt_writetoFile = True
        Par_n4.Opt_PlotToGraph = False
        Par_n4.Opt_WriteFinalValue = False
        Par_n4.Digits = 2
        Par_n4.Precision = 6
        Par_n4.v = 1.294940000000000000
        Par_alpha4.Name = 'alpha4'
        Par_alpha4.Opt_writetoFile = True
        Par_alpha4.Opt_PlotToGraph = False
        Par_alpha4.Opt_WriteFinalValue = False
        Par_alpha4.Digits = 2
        Par_alpha4.Precision = 6
        Par_alpha4.v = 0.006770000000000000
        Par_FK4.Name = 'FK_4'
        Par_FK4.Opt_writetoFile = True
        Par_FK4.Opt_PlotToGraph = False
        Par_FK4.Opt_WriteFinalValue = False
        Par_FK4.Digits = 2
        Par_FK4.Precision = 6
        Par_FK4.v = 0.350000000000000000
        Par_PWP4.Name = 'PWP_4'
        Par_PWP4.Opt_writetoFile = True
        Par_PWP4.Opt_PlotToGraph = False
        Par_PWP4.Opt_WriteFinalValue = False
        Par_PWP4.Digits = 2
        Par_PWP4.Precision = 6
        Par_PWP4.v = 0.100000000000000000
        Par_PsiStart1.Name = 'PsiStart1'
        Par_PsiStart1.Opt_writetoFile = True
        Par_PsiStart1.Opt_PlotToGraph = False
        Par_PsiStart1.Opt_WriteFinalValue = False
        Par_PsiStart1.Digits = 2
        Par_PsiStart1.Precision = 6
        Par_PsiStart1.v = 500.000000000000000000
        Par_Weff.Name = 'Weff'
        Par_Weff.Comment = 'effective rooting deph [cm]'
        Par_Weff.Opt_writetoFile = True
        Par_Weff.Opt_PlotToGraph = False
        Par_Weff.Opt_WriteFinalValue = False
        Par_Weff.Digits = 2
        Par_Weff.Precision = 6
        Par_Weff.v = 100.000000000000000000
        Var_WG0_30.Name = 'WG0_30'
        Var_WG0_30.Opt_writetoFile = True
        Var_WG0_30.Opt_PlotToGraph = False
        Var_WG0_30.Opt_WriteFinalValue = False
        Var_WG0_30.Digits = 2
        Var_WG0_30.Precision = 6
        Var_WG30_60.Name = 'WG30_60'
        Var_WG30_60.Opt_writetoFile = True
        Var_WG30_60.Opt_PlotToGraph = False
        Var_WG30_60.Opt_WriteFinalValue = False
        Var_WG30_60.Digits = 2
        Var_WG30_60.Precision = 6
        Var_WG30_120.Name = 'WG30_120'
        Var_WG30_120.Opt_writetoFile = True
        Var_WG30_120.Opt_PlotToGraph = False
        Var_WG30_120.Opt_WriteFinalValue = False
        Var_WG30_120.Digits = 2
        Var_WG30_120.Precision = 6
        Var_WG30_100.Name = 'WG30_100'
        Var_WG30_100.Opt_writetoFile = True
        Var_WG30_100.Opt_PlotToGraph = False
        Var_WG30_100.Opt_WriteFinalValue = False
        Var_WG30_100.Digits = 2
        Var_WG30_100.Precision = 6
        Var_WG60_90.Name = 'WG60_90'
        Var_WG60_90.Opt_writetoFile = True
        Var_WG60_90.Opt_PlotToGraph = False
        Var_WG60_90.Opt_WriteFinalValue = False
        Var_WG60_90.Digits = 2
        Var_WG60_90.Precision = 6
        Var_WG90_120.Name = 'WG90_120'
        Var_WG90_120.Opt_writetoFile = True
        Var_WG90_120.Opt_PlotToGraph = False
        Var_WG90_120.Opt_WriteFinalValue = False
        Var_WG90_120.Digits = 2
        Var_WG90_120.Precision = 6
        Var_WG0_100.Name = 'WG0_100'
        Var_WG0_100.Opt_writetoFile = True
        Var_WG0_100.Opt_PlotToGraph = False
        Var_WG0_100.Opt_WriteFinalValue = False
        Var_WG0_100.Digits = 2
        Var_WG0_100.Precision = 6
        Var_WG0_120.Name = 'WG0_120'
        Var_WG0_120.Opt_writetoFile = True
        Var_WG0_120.Opt_PlotToGraph = False
        Var_WG0_120.Opt_WriteFinalValue = False
        Var_WG0_120.Digits = 2
        Var_WG0_120.Precision = 6
        Var_WG0_90.Name = 'WG0_90'
        Var_WG0_90.Opt_writetoFile = True
        Var_WG0_90.Opt_PlotToGraph = False
        Var_WG0_90.Opt_WriteFinalValue = False
        Var_WG0_90.Digits = 2
        Var_WG0_90.Precision = 6
        Var_Psi_dummy.Name = 'psi_dummy'
        Var_Psi_dummy.Opt_writetoFile = True
        Var_Psi_dummy.Opt_PlotToGraph = False
        Var_Psi_dummy.Opt_WriteFinalValue = False
        Var_Psi_dummy.Digits = 2
        Var_Psi_dummy.Precision = 6
        Var_ActEvap.Name = 'act_evap'
        Var_ActEvap.Opt_writetoFile = True
        Var_ActEvap.Opt_PlotToGraph = False
        Var_ActEvap.Opt_WriteFinalValue = False
        Var_ActEvap.Digits = 2
        Var_ActEvap.Precision = 6
        St_CumEvap.Name = 'CumEvap'
        St_CumEvap.Opt_writetoFile = True
        St_CumEvap.Opt_PlotToGraph = False
        St_CumEvap.Opt_WriteFinalValue = False
        St_CumEvap.Digits = 2
        St_CumEvap.Precision = 6
        St_CumDrainage.Name = 'CumDrainage'
        St_CumDrainage.Opt_writetoFile = True
        St_CumDrainage.Opt_PlotToGraph = False
        St_CumDrainage.Opt_WriteFinalValue = False
        St_CumDrainage.Digits = 2
        St_CumDrainage.Precision = 6
        St_CumNetRain.Name = 'CumNetRain'
        St_CumNetRain.Opt_writetoFile = True
        St_CumNetRain.Opt_PlotToGraph = False
        St_CumNetRain.Opt_WriteFinalValue = False
        St_CumNetRain.Digits = 2
        St_CumNetRain.Precision = 6
        Par_psi_critEvap.Name = 'psi_critEvap'
        Par_psi_critEvap.Opt_writetoFile = True
        Par_psi_critEvap.Opt_PlotToGraph = False
        Par_psi_critEvap.Opt_WriteFinalValue = False
        Par_psi_critEvap.Digits = 2
        Par_psi_critEvap.Precision = 6
        Par_psi_critEvap.v = 500.000000000000000000
        Par_Horindx1.Name = 'HoriNdx1'
        Par_Horindx1.Comment = 'unterste Schicht des 1. Bodenhorizonts'
        Par_Horindx1.Opt_writetoFile = True
        Par_Horindx1.Opt_PlotToGraph = False
        Par_Horindx1.Opt_WriteFinalValue = False
        Par_Horindx1.Digits = 2
        Par_Horindx1.Precision = 6
        Par_Horindx1.v = 3.000000000000000000
        Par_Horindx2.Name = 'HoriNdx2'
        Par_Horindx2.Comment = 'unterste Schicht des 2. Bodenhorizonts'
        Par_Horindx2.Opt_writetoFile = True
        Par_Horindx2.Opt_PlotToGraph = False
        Par_Horindx2.Opt_WriteFinalValue = False
        Par_Horindx2.Digits = 2
        Par_Horindx2.Precision = 6
        Par_Horindx2.v = 6.000000000000000000
        Par_Horindx3.Name = 'HoriNdx3'
        Par_Horindx3.Comment = 'unterste Schicht des 3. Bodenhorizonts'
        Par_Horindx3.Opt_writetoFile = True
        Par_Horindx3.Opt_PlotToGraph = False
        Par_Horindx3.Opt_WriteFinalValue = False
        Par_Horindx3.Digits = 2
        Par_Horindx3.Precision = 6
        Par_Horindx3.v = 10.000000000000000000
        Par_Horindx4.Name = 'HoriNdx4'
        Par_Horindx4.Comment = 'unterste Schicht des 4. Bodenhorizonts'
        Par_Horindx4.Opt_writetoFile = True
        Par_Horindx4.Opt_PlotToGraph = False
        Par_Horindx4.Opt_WriteFinalValue = False
        Par_Horindx4.Digits = 2
        Par_Horindx4.Precision = 6
        Par_Horindx4.v = 20.000000000000000000
        Par_Psi_2.Name = 'psi_2'
        Par_Psi_2.Opt_writetoFile = True
        Par_Psi_2.Opt_PlotToGraph = False
        Par_Psi_2.Opt_WriteFinalValue = False
        Par_Psi_2.Digits = 2
        Par_Psi_2.Precision = 6
        Par_Psi_2.v = 200.000000000000000000
        Par_psi_3.Name = 'psi_3'
        Par_psi_3.Opt_writetoFile = True
        Par_psi_3.Opt_PlotToGraph = False
        Par_psi_3.Opt_WriteFinalValue = False
        Par_psi_3.Digits = 2
        Par_psi_3.Precision = 6
        Par_psi_3.v = 15000.000000000000000000
        Comp_fact.Name = 'CompFactor'
        Comp_fact.Opt_writetoFile = True
        Comp_fact.Opt_PlotToGraph = False
        Comp_fact.Opt_WriteFinalValue = False
        Comp_fact.Digits = 2
        Comp_fact.Precision = 6
        Comp_fact.v = 0.500000000000000000
        Par_nFKcrit.Name = 'nFKcrit'
        Par_nFKcrit.Opt_writetoFile = True
        Par_nFKcrit.Opt_PlotToGraph = False
        Par_nFKcrit.Opt_WriteFinalValue = False
        Par_nFKcrit.Digits = 2
        Par_nFKcrit.Precision = 6
        Par_nFKcrit.v = 0.500000000000000000
        St_CumTrans.Name = 'CumTrans'
        St_CumTrans.Opt_writetoFile = True
        St_CumTrans.Opt_PlotToGraph = False
        St_CumTrans.Opt_WriteFinalValue = False
        St_CumTrans.Digits = 2
        St_CumTrans.Precision = 6
        Var_ActTrans.Name = 'ActTrans'
        Var_ActTrans.Opt_writetoFile = True
        Var_ActTrans.Opt_PlotToGraph = False
        Var_ActTrans.Opt_WriteFinalValue = False
        Var_ActTrans.Digits = 2
        Var_ActTrans.Precision = 6
        Var_TransRatio.Name = 'TransRatio'
        Var_TransRatio.Opt_writetoFile = True
        Var_TransRatio.Opt_PlotToGraph = False
        Var_TransRatio.Opt_WriteFinalValue = False
        Var_TransRatio.Digits = 2
        Var_TransRatio.Precision = 6
        Psi_Root.Name = 'psiRoot'
        Psi_Root.Opt_writetoFile = True
        Psi_Root.Opt_PlotToGraph = False
        Psi_Root.Opt_WriteFinalValue = False
        Psi_Root.Digits = 2
        Psi_Root.Precision = 6
        AutoIrrigate = False
        AutoirriMethod = amTransRatio
        Opt_WithRoots = True
        OptSinkTermMethod = Psicrit
        Opt_Psi2 = fromParameter
        Var_Nmin0_30.Name = 'Nmin0_30'
        Var_Nmin0_30.Opt_writetoFile = True
        Var_Nmin0_30.Opt_PlotToGraph = False
        Var_Nmin0_30.Opt_WriteFinalValue = False
        Var_Nmin0_30.Digits = 2
        Var_Nmin0_30.Precision = 6
        Var_Nmin0_30.v = 15.000000000000000000
        Var_Nmin30_60.Name = 'Nmin30_60'
        Var_Nmin30_60.Opt_writetoFile = True
        Var_Nmin30_60.Opt_PlotToGraph = False
        Var_Nmin30_60.Opt_WriteFinalValue = False
        Var_Nmin30_60.Digits = 2
        Var_Nmin30_60.Precision = 6
        Var_Nmin30_60.v = 15.000000000000000000
        Var_Nmin60_90.Name = 'Nmin60_90'
        Var_Nmin60_90.Opt_writetoFile = True
        Var_Nmin60_90.Opt_PlotToGraph = False
        Var_Nmin60_90.Opt_WriteFinalValue = False
        Var_Nmin60_90.Digits = 2
        Var_Nmin60_90.Precision = 6
        Var_Nmin60_90.v = 15.000000000000000000
        Var_Nmin90_120.Name = 'Nmin90_120'
        Var_Nmin90_120.Opt_writetoFile = True
        Var_Nmin90_120.Opt_PlotToGraph = False
        Var_Nmin90_120.Opt_WriteFinalValue = False
        Var_Nmin90_120.Digits = 2
        Var_Nmin90_120.Precision = 6
        Var_Nmin90_120.v = 15.000000000000000000
        Var_Nmin0_90.Name = 'Nmin0_90'
        Var_Nmin0_90.Opt_writetoFile = True
        Var_Nmin0_90.Opt_PlotToGraph = False
        Var_Nmin0_90.Opt_WriteFinalValue = False
        Var_Nmin0_90.Digits = 2
        Var_Nmin0_90.Precision = 6
        Var_Nmin0_90.v = 45.000000000000000000
        Var_SumNmin.Name = 'SumNmin'
        Var_SumNmin.Comment = 'Summe des Nmin-Stickstoffs'
        Var_SumNmin.Opt_writetoFile = True
        Var_SumNmin.Opt_PlotToGraph = False
        Var_SumNmin.Opt_WriteFinalValue = False
        Var_SumNmin.Digits = 2
        Var_SumNmin.Precision = 6
        Var_SumDrain.Name = 'SumDrain'
        Var_SumDrain.Comment = 'Summe des AusgewaschenenStickstoffs'
        Var_SumDrain.Opt_writetoFile = True
        Var_SumDrain.Opt_PlotToGraph = False
        Var_SumDrain.Opt_WriteFinalValue = False
        Var_SumDrain.Digits = 2
        Var_SumDrain.Precision = 6
        Var_NBalance.Name = 'LT_NBal'
        Var_NBalance.Opt_writetoFile = True
        Var_NBalance.Opt_PlotToGraph = False
        Var_NBalance.Opt_WriteFinalValue = False
        Var_NBalance.Digits = 2
        Var_NBalance.Precision = 6
        Par_Imp_factor.Name = 'Imp_factor'
        Par_Imp_factor.Opt_writetoFile = True
        Par_Imp_factor.Opt_PlotToGraph = False
        Par_Imp_factor.Opt_WriteFinalValue = False
        Par_Imp_factor.Digits = 2
        Par_Imp_factor.Precision = 6
        Par_Imp_factor.v = 0.500000000000000000
        Par_Cmin.Name = 'Cmin'
        Par_Cmin.Opt_writetoFile = True
        Par_Cmin.Opt_PlotToGraph = False
        Par_Cmin.Opt_WriteFinalValue = False
        Par_Cmin.Digits = 2
        Par_Cmin.Precision = 6
        Par_RootRad.Name = 'RootRad'
        Par_RootRad.Opt_writetoFile = True
        Par_RootRad.Opt_PlotToGraph = False
        Par_RootRad.Opt_WriteFinalValue = False
        Par_RootRad.Digits = 2
        Par_RootRad.Precision = 6
        Par_RootRad.v = 0.020000000000000000
        Var_MaxNuptake.Name = 'MaxNUptake'
        Var_MaxNuptake.Opt_writetoFile = True
        Var_MaxNuptake.Opt_PlotToGraph = False
        Var_MaxNuptake.Opt_WriteFinalValue = False
        Var_MaxNuptake.Digits = 2
        Var_MaxNuptake.Precision = 6
        Var_ActNUptake.Name = 'ActNUptake'
        Var_ActNUptake.Opt_writetoFile = True
        Var_ActNUptake.Opt_PlotToGraph = False
        Var_ActNUptake.Opt_WriteFinalValue = False
        Var_ActNUptake.Digits = 2
        Var_ActNUptake.Precision = 6
        Var_Massflow.Name = 'MassFlow'
        Var_Massflow.Opt_writetoFile = True
        Var_Massflow.Opt_PlotToGraph = False
        Var_Massflow.Opt_WriteFinalValue = False
        Var_Massflow.Digits = 2
        Var_Massflow.Precision = 6
        Ex_PlantNUptake.Name = 'PlantNDemand'
        Ex_PlantNUptake.Opt_writetoFile = True
        Ex_PlantNUptake.Opt_PlotToGraph = False
        Ex_PlantNUptake.Opt_WriteFinalValue = False
        Ex_PlantNUptake.Digits = 0
        Ex_PlantNUptake.Precision = 0
        Ex_PlantNUptake.Ex = StateField
        Ex_PlantNUptake.Search = False
        Ex_PlantNUptake.C_f = 1.000000000000000000
        Ex_PlantNUptake.Source = 'Gras'
        Ex_SRL.Name = 'SRL'
        Ex_SRL.Opt_writetoFile = True
        Ex_SRL.Opt_PlotToGraph = False
        Ex_SRL.Opt_WriteFinalValue = False
        Ex_SRL.Digits = 0
        Ex_SRL.Precision = 0
        Ex_SRL.Ex = StateField
        Ex_SRL.Search = False
        Ex_SRL.C_f = 1.000000000000000000
        Ex_SRL.Source = 'Gras'
        Ex_SRL_eff.Name = 'SRL_eff'
        Ex_SRL_eff.Opt_writetoFile = True
        Ex_SRL_eff.Opt_PlotToGraph = False
        Ex_SRL_eff.Opt_WriteFinalValue = False
        Ex_SRL_eff.Digits = 0
        Ex_SRL_eff.Precision = 0
        Ex_SRL_eff.Ex = StateField
        Ex_SRL_eff.Search = False
        Ex_SRL_eff.C_f = 1.000000000000000000
        Ex_SRL_eff.Source = 'Gras'
        St_SumSoilNUptake.Name = 'SumSoilNuptake'
        St_SumSoilNUptake.Opt_writetoFile = True
        St_SumSoilNUptake.Opt_PlotToGraph = False
        St_SumSoilNUptake.Opt_WriteFinalValue = False
        St_SumSoilNUptake.Digits = 2
        St_SumSoilNUptake.Precision = 6
      end
      object Fertilization1: TFertilization
        Left = 24
        Top = 48
        Width = 161
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 4
        FN_ratefn = 'C:\Modelle\out\Fertilization1_rat.csv'
        FN_Statefn = 'C:\Modelle\out\Fertilization1_dat.csv'
        SoilLayerMod = SoilNitrogenUp1
      end
      object MinMod2Pool1: TMinMod2Pool
        Left = 219
        Top = 266
        Width = 151
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 5
        FN_ratefn = 'C:\Modelle\out\MinMod2Pool1_rat.csv'
        FN_Statefn = 'C:\Modelle\out\MinMod2Pool1_dat.csv'
        PlantModel = Gras
        Var_MinRate.Name = 'MinRate'
        Var_MinRate.Opt_writetoFile = True
        Var_MinRate.Opt_PlotToGraph = False
        Var_MinRate.Opt_WriteFinalValue = False
        Var_MinRate.Digits = 2
        Var_MinRate.Precision = 6
        Var_Nfast_Min_N.Name = 'Nfast_Min_N'
        Var_Nfast_Min_N.Comment = 'bereits mineralisierter Teil von Nfast'
        Var_Nfast_Min_N.Opt_writetoFile = True
        Var_Nfast_Min_N.Opt_PlotToGraph = False
        Var_Nfast_Min_N.Opt_WriteFinalValue = False
        Var_Nfast_Min_N.Digits = 2
        Var_Nfast_Min_N.Precision = 6
        Var_Nslow_Min_N.Name = 'Nslow_Min_N'
        Var_Nslow_Min_N.Comment = 'bereits mineralisierter Teil von Nslow'
        Var_Nslow_Min_N.Opt_writetoFile = True
        Var_Nslow_Min_N.Opt_PlotToGraph = False
        Var_Nslow_Min_N.Opt_WriteFinalValue = False
        Var_Nslow_Min_N.Digits = 2
        Var_Nslow_Min_N.Precision = 6
        St_Nfast.Name = 'Nfast'
        St_Nfast.Comment = 'Fast decomposable Pool of Soil N [kg N/ha]'
        St_Nfast.Opt_writetoFile = True
        St_Nfast.Opt_PlotToGraph = False
        St_Nfast.Opt_WriteFinalValue = False
        St_Nfast.Digits = 2
        St_Nfast.Precision = 6
        St_Nslow.Name = 'Nslow'
        St_Nslow.Comment = 'slow decomposable Pool of Soil N [kg N/ha]'
        St_Nslow.Opt_writetoFile = True
        St_Nslow.Opt_PlotToGraph = False
        St_Nslow.Opt_WriteFinalValue = False
        St_Nslow.Digits = 2
        St_Nslow.Precision = 6
        Ex_WG0_30.Name = 'WG0_30'
        Ex_WG0_30.Opt_writetoFile = True
        Ex_WG0_30.Opt_PlotToGraph = False
        Ex_WG0_30.Opt_WriteFinalValue = False
        Ex_WG0_30.Digits = 0
        Ex_WG0_30.Precision = 0
        Ex_WG0_30.Ex = StateField
        Ex_WG0_30.Search = True
        Ex_WG0_30.C_f = 1.000000000000000000
        Par_kfast_factor.Name = 'kfast_factor'
        Par_kfast_factor.Opt_writetoFile = True
        Par_kfast_factor.Opt_PlotToGraph = False
        Par_kfast_factor.Opt_WriteFinalValue = False
        Par_kfast_factor.Digits = 2
        Par_kfast_factor.Precision = 6
        Par_kfast_factor.v = 5.599999999999999000
        Par_kslow_factor.Name = 'kslow_factor'
        Par_kslow_factor.Opt_writetoFile = True
        Par_kslow_factor.Opt_PlotToGraph = False
        Par_kslow_factor.Opt_WriteFinalValue = False
        Par_kslow_factor.Digits = 2
        Par_kslow_factor.Precision = 6
        Par_kslow_factor.v = 4.000000000000000000
        FirstMinMod = True
      end
      object Concentration1: TConcentration
        Left = 568
        Top = 266
        Width = 188
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 6
        FN_ratefn = 'C:\Modelle\out\Concentration1_rat.csv'
        FN_Statefn = 'C:\Modelle\out\Concentration1_dat.csv'
      end
      object Mod1: TMod
        Left = 416
        Top = 248
        Width = 80
        Height = 30
        Cursor = crHandPoint
        GM_ControlFile = 'B:\Modelle\Niko\Parameter\prog_ff2a.fn'
        GM_OutPutPath = 'C:\Modelle\out'
        GM_InPutPath = 'C:\Modelle\out'
        TimeStep = 1.000000000000000000
        StartTime = 39022.000000000000000000
        EndTime = 39903.000000000000000000
        Reg_fn = 'regression.dat'
        ModTime.Name = 'Time'
        ModTime.Opt_writetoFile = True
        ModTime.Opt_PlotToGraph = False
        ModTime.Opt_WriteFinalValue = False
        ModTime.Digits = 2
        ModTime.Precision = 6
        ModTime.v = 39022.000000000000000000
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
        Title = 'FF2a Mais-Weizen-Gras'
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
        ReInitAfterRun = True
        ShowDateFormat = True
      end
      object GPS_Weizen: TMultiGrowthCurvePlantRoots
        Left = 296
        Top = 152
        Width = 161
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 8
        FN_ratefn = 'C:\Modelle\out\GPS_Weizen_rat.csv'
        FN_Statefn = 'C:\Modelle\out\GPS_Weizen_dat.csv'
        SoilMinMOd = MinMod2Pool1
        SoilLayerMod = SoilNitrogenUp1
        EvapModel = PenMonteith1
        Par_SowingDate.Name = 'SowingDate'
        Par_SowingDate.Opt_writetoFile = True
        Par_SowingDate.Opt_PlotToGraph = False
        Par_SowingDate.Opt_WriteFinalValue = False
        Par_SowingDate.Digits = 2
        Par_SowingDate.Precision = 6
        Par_HarvestDate.Name = 'HarvestDate'
        Par_HarvestDate.Opt_writetoFile = True
        Par_HarvestDate.Opt_PlotToGraph = False
        Par_HarvestDate.Opt_WriteFinalValue = False
        Par_HarvestDate.Digits = 2
        Par_HarvestDate.Precision = 6
        Par_HarvestDate.v = 1000000.000000000000000000
        NextCrop = Gras_Gras
        Rotationlength = 0
        St_C_Residues.Name = 'C_Residues'
        St_C_Residues.Opt_writetoFile = True
        St_C_Residues.Opt_PlotToGraph = False
        St_C_Residues.Opt_WriteFinalValue = False
        St_C_Residues.Digits = 2
        St_C_Residues.Precision = 6
        St_N_Residues.Name = 'N_Residues'
        St_N_Residues.Opt_writetoFile = True
        St_N_Residues.Opt_PlotToGraph = False
        St_N_Residues.Opt_WriteFinalValue = False
        St_N_Residues.Digits = 2
        St_N_Residues.Precision = 6
        SetNewDates = False
        withRoots = True
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.Ex = RateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
        Par_LAImax.Name = 'LAI_Capacity'
        Par_LAImax.Opt_writetoFile = True
        Par_LAImax.Opt_PlotToGraph = False
        Par_LAImax.Opt_WriteFinalValue = False
        Par_LAImax.Digits = 2
        Par_LAImax.Precision = 6
        Par_TempsumEmerge.Name = 'TempSumEmerge'
        Par_TempsumEmerge.Opt_writetoFile = True
        Par_TempsumEmerge.Opt_PlotToGraph = False
        Par_TempsumEmerge.Opt_WriteFinalValue = False
        Par_TempsumEmerge.Digits = 2
        Par_TempsumEmerge.Precision = 6
        Par_TempsumEmerge.v = 150.000000000000000000
        Par_zr0.Name = 'zr_0'
        Par_zr0.Opt_writetoFile = True
        Par_zr0.Opt_PlotToGraph = False
        Par_zr0.Opt_WriteFinalValue = False
        Par_zr0.Digits = 2
        Par_zr0.Precision = 6
        Par_zr0.v = 10.000000000000000000
        Par_zrmax.Name = 'zr_max'
        Par_zrmax.Opt_writetoFile = True
        Par_zrmax.Opt_PlotToGraph = False
        Par_zrmax.Opt_WriteFinalValue = False
        Par_zrmax.Digits = 2
        Par_zrmax.Precision = 6
        Par_zrmax.v = 120.000000000000000000
        Par_kz.Name = 'k_z'
        Par_kz.Opt_writetoFile = True
        Par_kz.Opt_PlotToGraph = False
        Par_kz.Opt_WriteFinalValue = False
        Par_kz.Digits = 2
        Par_kz.Precision = 6
        Par_kz.v = 0.000900000000000000
        Par_ActiveDuration.Name = 'ActiveDuration'
        Par_ActiveDuration.Opt_writetoFile = True
        Par_ActiveDuration.Opt_PlotToGraph = False
        Par_ActiveDuration.Opt_WriteFinalValue = False
        Par_ActiveDuration.Digits = 2
        Par_ActiveDuration.Precision = 6
        Par_ActiveDuration.v = 20.000000000000000000
        Par_Wl0.Name = 'WL_0'
        Par_Wl0.Opt_writetoFile = True
        Par_Wl0.Opt_PlotToGraph = False
        Par_Wl0.Opt_WriteFinalValue = False
        Par_Wl0.Digits = 2
        Par_Wl0.Precision = 6
        Par_Wl0.v = 1.000000000000000000
        Par_Wlmax.Name = 'WL_max'
        Par_Wlmax.Opt_writetoFile = True
        Par_Wlmax.Opt_PlotToGraph = False
        Par_Wlmax.Opt_WriteFinalValue = False
        Par_Wlmax.Digits = 2
        Par_Wlmax.Precision = 6
        Par_Wlmax.v = 15.000000000000000000
        Par_kWL.Name = 'k_WL'
        Par_kWL.Opt_writetoFile = True
        Par_kWL.Opt_PlotToGraph = False
        Par_kWL.Opt_WriteFinalValue = False
        Par_kWL.Digits = 2
        Par_kWL.Precision = 6
        Par_kWL.v = 0.002000000000000000
      end
      object Gras: TMultiGrowthCurvePlantRoots
        Left = 24
        Top = 152
        Width = 100
        Height = 50
        Cursor = crHandPoint
        SM_GlobMod = Mod1
        CompIndex = 7
        FN_ratefn = 'C:\Modelle\out\Gras_rat.csv'
        FN_Statefn = 'C:\Modelle\out\Gras_dat.csv'
        SoilMinMOd = MinMod2Pool1
        SoilLayerMod = SoilNitrogenUp1
        EvapModel = PenMonteith1
        Par_SowingDate.Name = 'SowingDate'
        Par_SowingDate.Opt_writetoFile = True
        Par_SowingDate.Opt_PlotToGraph = False
        Par_SowingDate.Opt_WriteFinalValue = False
        Par_SowingDate.Digits = 2
        Par_SowingDate.Precision = 6
        Par_HarvestDate.Name = 'HarvestDate'
        Par_HarvestDate.Opt_writetoFile = True
        Par_HarvestDate.Opt_PlotToGraph = False
        Par_HarvestDate.Opt_WriteFinalValue = False
        Par_HarvestDate.Digits = 2
        Par_HarvestDate.Precision = 6
        Par_HarvestDate.v = 1000000.000000000000000000
        NextCrop = Mais
        Rotationlength = 0
        St_C_Residues.Name = 'C_Residues'
        St_C_Residues.Opt_writetoFile = True
        St_C_Residues.Opt_PlotToGraph = False
        St_C_Residues.Opt_WriteFinalValue = False
        St_C_Residues.Digits = 2
        St_C_Residues.Precision = 6
        St_N_Residues.Name = 'N_Residues'
        St_N_Residues.Opt_writetoFile = True
        St_N_Residues.Opt_PlotToGraph = False
        St_N_Residues.Opt_WriteFinalValue = False
        St_N_Residues.Digits = 2
        St_N_Residues.Precision = 6
        SetNewDates = False
        withRoots = True
        Ex_Temp.Name = 'Temp'
        Ex_Temp.Opt_writetoFile = True
        Ex_Temp.Opt_PlotToGraph = False
        Ex_Temp.Opt_WriteFinalValue = False
        Ex_Temp.Digits = 0
        Ex_Temp.Precision = 0
        Ex_Temp.Ex = RateField
        Ex_Temp.Search = True
        Ex_Temp.C_f = 1.000000000000000000
        Par_LAImax.Name = 'LAI_Capacity'
        Par_LAImax.Opt_writetoFile = True
        Par_LAImax.Opt_PlotToGraph = False
        Par_LAImax.Opt_WriteFinalValue = False
        Par_LAImax.Digits = 2
        Par_LAImax.Precision = 6
        Par_TempsumEmerge.Name = 'TempSumEmerge'
        Par_TempsumEmerge.Opt_writetoFile = True
        Par_TempsumEmerge.Opt_PlotToGraph = False
        Par_TempsumEmerge.Opt_WriteFinalValue = False
        Par_TempsumEmerge.Digits = 2
        Par_TempsumEmerge.Precision = 6
        Par_TempsumEmerge.v = 150.000000000000000000
        Par_zr0.Name = 'zr_0'
        Par_zr0.Opt_writetoFile = True
        Par_zr0.Opt_PlotToGraph = False
        Par_zr0.Opt_WriteFinalValue = False
        Par_zr0.Digits = 2
        Par_zr0.Precision = 6
        Par_zr0.v = 10.000000000000000000
        Par_zrmax.Name = 'zr_max'
        Par_zrmax.Opt_writetoFile = True
        Par_zrmax.Opt_PlotToGraph = False
        Par_zrmax.Opt_WriteFinalValue = False
        Par_zrmax.Digits = 2
        Par_zrmax.Precision = 6
        Par_zrmax.v = 120.000000000000000000
        Par_kz.Name = 'k_z'
        Par_kz.Opt_writetoFile = True
        Par_kz.Opt_PlotToGraph = False
        Par_kz.Opt_WriteFinalValue = False
        Par_kz.Digits = 2
        Par_kz.Precision = 6
        Par_kz.v = 0.000900000000000000
        Par_ActiveDuration.Name = 'ActiveDuration'
        Par_ActiveDuration.Opt_writetoFile = True
        Par_ActiveDuration.Opt_PlotToGraph = False
        Par_ActiveDuration.Opt_WriteFinalValue = False
        Par_ActiveDuration.Digits = 2
        Par_ActiveDuration.Precision = 6
        Par_ActiveDuration.v = 20.000000000000000000
        Par_Wl0.Name = 'WL_0'
        Par_Wl0.Opt_writetoFile = True
        Par_Wl0.Opt_PlotToGraph = False
        Par_Wl0.Opt_WriteFinalValue = False
        Par_Wl0.Digits = 2
        Par_Wl0.Precision = 6
        Par_Wl0.v = 1.000000000000000000
        Par_Wlmax.Name = 'WL_max'
        Par_Wlmax.Opt_writetoFile = True
        Par_Wlmax.Opt_PlotToGraph = False
        Par_Wlmax.Opt_WriteFinalValue = False
        Par_Wlmax.Digits = 2
        Par_Wlmax.Precision = 6
        Par_Wlmax.v = 15.000000000000000000
        Par_kWL.Name = 'k_WL'
        Par_kWL.Opt_writetoFile = True
        Par_kWL.Opt_PlotToGraph = False
        Par_kWL.Opt_WriteFinalValue = False
        Par_kWL.Digits = 2
        Par_kWL.Precision = 6
        Par_kWL.v = 0.002000000000000000
      end
    end
    inherited TabSheetParameter: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetState: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetVariables: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetExternalValues: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetOptions: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetData: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetStat: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetResultTab: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
    inherited TabSheetGraphResult: TTabSheet
      ExplicitLeft = 4
      ExplicitTop = 4
      ExplicitWidth = 790
      ExplicitHeight = 396
    end
  end
  inherited LMod: TModLink
    LinkedModel = Mod1
  end
  inherited il1: TImageList
    Bitmap = {
      494C010102007C007C0010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
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
end
