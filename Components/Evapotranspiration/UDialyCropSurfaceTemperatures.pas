unit UDialyCropSurfaceTemperatures;
 {*
  by Arne M. Ratjen
  according to 'Integrating wheat canopy temperatures in crop system models'
   Neukamp et al. 2015
 *}
interface

uses
  Windows, UAbstractPlant, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, UMod, Math, UState;
type
  TCropSurfaceTemp = class(TPlantRelatedSubMod)
 protected
 // functions, procedures

 private
 // private Objekts

 public
 EC:             TExternV;
 TransIntRatio:  TExternV;
 TMPM:           TExternV; // daily mean temperature
 TMPMN:          TExternV; // daily minimum temperature
 TMPMX:          TExternV; // daily maximum temperature
 Sat_def:        TExternV;
 Rad_Int:        TExternV;
 LAI:            TExternV;
 CropHeight:     TExternV;
 Act_Evap:       TExternV;
 ActTrans:       TExternV;
 pETP:           TExternV;
 Eact_ETP: TExternV;          // Ration of act. evaporation to pot. evapotranspiration

 Mean_Int:            TPar;
 Mean_TMPM:           TPar;
 Mean_Rint:           TPar;
 Mean_LAI_log:        TPar;
 Mean_Eact_ETP:       TPar;
 Mean_VPD:            TPar;
 Mean_TransRatio_VPD: TPar;
 minLAI:              TPar;

 Max_I_Int:            TPar;
 Max_I_Rint:           TPar;
 Max_I_TMPMX:          TPar;
 Max_I_LAI_log:        TPar;
 Max_I_TransRatio_VPD: TPar;

 Max_II_Int:          TPar;
 Max_II_Rint:         TPar;
 Max_II_TMPMX:        TPar;
 Max_II_LAI_log:      TPar;
 Max_II_TransRatio_VPD: TPar;

 Min_I_Int:          TPar;
 Min_I_CH:           TPar;
 Min_I_TMPMN:        TPar;

 Min_II_Int:         TPar;
 Min_II_VPD:         TPar;
 Min_II_TMPMN:       TPar;
 Min_II_Eact_ETP:    TPar;

 fWMeanT:            TPar; // weighting factor for phenological mean. canopy temp
 // restrict extrem values to the observed pattern according to Neukam et al. ??
 Mean_min_Delta:     TPar;
 Mean_max_Delta:     TPar;
 Min_min_Delta:      TPar;
 Min_max_Delta:      TPar;
 Max_min_Delta:      TPar;
 Max_max_Delta:      TPar;

 Dphen:              TVar;
 MeanCanopyTemp:     TVar;
 MinCanopyTemp:      TVar;
 MaxCanopyTemp:      TVar;
 PhenoTemp:          TVar;
 TDiffMean:          TVar;
 TDiffMin:           TVar;
 TDiffMax:           TVar;

 procedure createAll; override;
 procedure Init(var GlobMod: TMod); override;
 procedure CalcRates; override;
 procedure Integrate; override;

 published
 property Ex_EC : TExternV read EC write EC;
 property Ex_TransIntRatio : TExternV read TransIntRatio write TransIntRatio;
 property Ex_TMPMN : TExternV read TMPMN write TMPMN;
 property Ex_TMPMX : TExternV read TMPMX write TMPMX;
 property Ex_Sat_def : TExternV read Sat_def write Sat_def;
 property Ex_Rad_Int : TExternV read Rad_Int write Rad_Int;
 property Ex_LAI : TExternV read LAI write LAI;
 property Ex_CropHeight : TExternV read CropHeight write CropHeight;
 property Ex_Act_Evap : TExternV read Act_Evap write Act_Evap;
 property Ex_ActTrans : TExternV read ActTrans write ActTrans;
 property Ex_pETP : TExternV read pETP write pETP;

end;

procedure Register;

implementation

uses UModUtils;

procedure TCropSurfaceTemp.createall;
begin
  inherited createAll;
  ExternVCreate('EC',  '[BBCH]', statefield, EC);
  ExternVCreate('TransIntRatio',  '[-]', statefield, TransIntRatio);
  ExternVCreate('TMPM',  '[°C]', statefield, TMPM);
  ExternVCreate('TMPMN',  '[°C]', statefield, TMPMN);
  ExternVCreate('TMPMX',  '[°C]', statefield, TMPMX);
  ExternVCreate('Sat_def',  '[hPa]', statefield, Sat_def);
  ExternVCreate('Rad_Int',  '[W/m2]', statefield, Rad_Int);
  ExternVCreate('LAI',  '[-]', statefield, LAI);
  ExternVCreate('Height',  '[m]', statefield, CropHeight);
  ExternVCreate('Act_Evap',  '[mm/d]', statefield, Act_Evap);
  ExternVCreate('ActTrans',  '[mm/d]', statefield, ActTrans);
  ExternVCreate('pETP',  '[mm/d]', statefield, pETP,'pot. evapo-transpiration');
  ExternVCreate('Eact_ETP',  '[-]', statefield, Eact_ETP,'Ration of act. evaporation to pot. evapotranspiration');

  ParCreate('Mean_Int', '[°C]', 2.730, Mean_Int);
  ParCreate('Mean_TMPM', '[°C]', 0.942, Mean_TMPM);
  ParCreate('Mean_Rint', '[W/m2]', 0.005, Mean_Rint);
  ParCreate('Mean_LAI_log', '[-]', -1.358, Mean_LAI_log);
  ParCreate('Mean_Eact_ETP', '[-]', -5.491, Mean_Eact_ETP);
  ParCreate('Mean_VPD', '[haPa]', -0.263, Mean_VPD);
  ParCreate('Mean_TransRatio_VPD', '[-]',-0.299, Mean_TransRatio_VPD);
  ParCreate('minLAI', '[-]',1, minLAI);

  ParCreate('Max_I_Int', '[°C]', 4.241, Max_I_Int);
  ParCreate('Max_I_Rint', '[W/m2]', 0.016, Max_I_Rint);
  ParCreate('Max_I_TMPMX', '[°C]', 0.922, Max_I_TMPMX);
  ParCreate('Max_I_LAI_log', '[-]', -2.816, Max_I_LAI_log);
  ParCreate('Max_I_TransRatio_VPD', '[mm/d]', -0.477, Max_I_TransRatio_VPD);

  ParCreate('Max_II_Int', '[°C]', 4.011, Max_II_Int);
  ParCreate('Max_II_Rint', '[W/m2]', 0.014, Max_II_Rint);
  ParCreate('Max_II_TMPMX', '[°C]', 0.888, Max_II_TMPMX);
  ParCreate('Max_II_LAI_log', '[-]', -1.847, Max_II_LAI_log);
  ParCreate('Max_II_TransRatio_VPD', '[mm/d]', -0.623, Max_II_TransRatio_VPD);

  ParCreate('Min_I_Int', '[°C]', 1.116, Min_I_Int);
  ParCreate('Min_I_CH', '[m]', -4.147, Min_I_CH);
  ParCreate('Min_I_TMPMN', '[°C]', 1.088, Min_I_TMPMN);

  ParCreate('Min_II_Int', '[°C]', -0.202, Min_II_Int);
  ParCreate('Min_II_VPD', '[hPa', -0.101, Min_II_VPD);
  ParCreate('Min_II_TMPMN', '[°C]', 1.013, Min_II_TMPMN);
  ParCreate('Min_II_Eact_ETP', '[-]', -3.158, Min_II_Eact_ETP);

  ParCreate('Mean_min_Delta', '[°C]', -4, Mean_min_Delta);
  ParCreate('Mean_max_Delta', '[°C]', 3.8, Mean_max_Delta);

  ParCreate('Min_min_Delta', '[°C]', -7.2, Min_min_Delta);
  ParCreate('Min_max_Delta', '[°C]', 1.8, Min_max_Delta);

  ParCreate('Max_min_Delta', '[°C]', -2.5, Max_min_Delta);
  ParCreate('Max_max_Delta', '[°C]', 11.6, Max_max_Delta);


  ParCreate('fWMeanT', '[-]', 0.57, fWMeanT);


  VarCreate('Dphen', '[-]', 0,true, Dphen,'logical 0_1 variable');
  VarCreate('MeanCanopyTemp', '[-]', 0,true, MeanCanopyTemp);
  VarCreate('MinCanopyTemp', '[-]', 0,true, MinCanopyTemp);
  VarCreate('MaxCanopyTemp', '[-]', 0,true, MaxCanopyTemp);
  VarCreate('PhenoTemp', '[-]', 0,true, PhenoTemp);
  VarCreate('TDiffMean', '[°C]', 0,true, TDiffMean);
  VarCreate('TDiffMin', '[°C]', 0,true, TDiffMin);
  VarCreate('TDiffMax', '[°C]', 0,true, TDiffMax);


end;

procedure TCropSurfaceTemp.Init;
begin
  inherited;

end;

procedure TCropSurfaceTemp.calcRates;
var
LAI_: real;
begin
 LAI_:=max(minLAI.v,LAI.v);
 if (EC.v<50) then Dphen.v:=1
  else
    Dphen.v:=0;
 if (EC.v>31) then
 begin
	 if(LAI.v>0) and (pETP.v>0)then

	  MeanCanopyTemp.v:= Mean_Int.v +
            (TMPM.v*Mean_TMPM.v) +
						(Rad_Int.v*Mean_Rint.v) +
            (ln(LAI_)*Mean_LAI_log.v) +
						((1-Dphen.v)*Eact_ETP.v*Mean_Eact_ETP.v) +
						(Dphen.v*Sat_def.v*Mean_VPD.v) +
						((1-Dphen.v)*(Sat_def.v*TransIntRatio.v)*Mean_TransRatio_VPD.v)
	  else
		MeanCanopyTemp.v:=TMPM.v;

	  if(Dphen.v=1)then
	  begin // I
		MinCanopyTemp.v:=Min_I_Int.v + Min_I_CH.v*CropHeight.v +  Min_I_TMPMN.v*TMPMN.v;
		if(LAI.v>0) then
		  MaxCanopyTemp.v:=Max_I_Int.v + Max_I_Rint.v*Rad_Int.v + Max_I_TMPMX.v*TMPMX.v +
						   Max_I_LAI_log.v*ln(LAI_) +
						   Max_I_TransRatio_VPD.v*TransIntRatio.v*Sat_def.v
		  else MaxCanopyTemp.v:=TMPMX.v;
	  end else
		  begin // II
			MinCanopyTemp.v:= Min_II_Int.v + Min_II_VPD.v*Sat_def.v +
							  Min_II_TMPMN.v*TMPMN.v + Min_II_Eact_ETP.v*Eact_ETP.v;
			if(LAI.v>0) then
				MaxCanopyTemp.v:= Max_II_Int.v + Max_II_Rint.v*Rad_Int.v +
							  Max_II_TMPMX.v*TMPMX.v + Max_II_LAI_log.v*ln(LAI_) *
							  Max_II_TransRatio_VPD.v+TransIntRatio.v
				else MaxCanopyTemp.v:=TMPMX.v;
		  end;
  end else
	  begin
		MeanCanopyTemp.v:=TMPM.v;
		MinCanopyTemp.v:= TMPMN.v;
		MaxCanopyTemp.v:= TMPMX.v
	  end;

  TDiffMean.v:= max(min(MeanCanopyTemp.v-TMPM.v,Mean_max_Delta.v),Mean_min_Delta.v);
  TDiffMin.v:=  max(min(MinCanopyTemp.v-TMPMN.v,Min_max_Delta.v),Min_min_Delta.v);
  TDiffMax.v:=  max(min(MaxCanopyTemp.v-TMPMX.v,Max_max_Delta.v),Max_min_Delta.v);

  PhenoTemp.v:=TMPM.v + TDiffMean.v*fWMeanT.v;

end;

procedure TCropSurfaceTemp.Integrate;
begin
  inherited;

end;

procedure Register;
begin
  RegisterComponents('Simulation', [TCropSurfaceTemp]);
end;
end.
