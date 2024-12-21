unit UDryMatProdComp;

interface

uses UState, Umod, IniFiles, classes, UAbstractPlant;

type
  real = double;
  TRespOptions = (NoResp, MaintResp);
const
   Tref = 20;   // Reference temperature for respiration [°C]


type

  TSource = (fromParameter, fromPlantModel); // Source of LAI


TDrymatterProduction = Class(TPlantRelatedSubMod)



  private

  protected
{    procedure Set_GlobMod(value:TMod); override;}
  procedure SetPlantModel(NewPlantmodel: TAbstractPlant); Override;


  public
     AssiFlow,                    // gross dry matter producction [g CH2O.d-1]
     Temp_f,                      // Temperature effect on Photosynthesis
     Teff,                        // Temperature effect on Respiration
     Par_abs         : TVar;      // aborbed PAR [MJ.m-2.d-1]
     k               : TPar;      // extinction coefficient for PAR [-]
     Tempf_T1, Tempf_T2, Tempf_T3,
     Tempf_T4         : TPar;      // 4 Cardinal Points of Funktion for temperature Response function [0..1].
     Q10             : TPar;      //
     RespOptions     : TRespOptions;

     Transmission    : TVar;

     PAR,
     LAI,
     Temp,
     TotalDrymatterGr
                           : TExternV;
     LUE                   : Tvar;

     procedure createAll; Override;
     procedure integrate; override;
     procedure CalcRates; override;

   private
      fLAIOpt: TSource; // Source of LAI


   published
     property Ex_Par : TExternV read PAR write PAR;
     Property Ex_LAI : TExternV read LAI write LAI;
     Property Ex_Temp : TExternV read Temp write Temp;
     Property Ex_TotalDrymatterGr: TExternV read TotalDrymatterGr write TotalDrymatterGr;
     Property Par_Tempf_T1 : TPar read Tempf_T1 write Tempf_T1;
     Property Par_Tempf_T2 : TPar read Tempf_T2 write Tempf_T2;
     Property Par_Tempf_T3 : TPar read Tempf_T3 write Tempf_T3;
     Property Par_Tempf_T4 : TPar read Tempf_T4 write Tempf_T4;
     property Par_Q10            : TPar read Q10 write Q10;
     property Par_k   : Tpar read k write k;
     property Var_par_abs : TVar read par_abs write par_abs;
     property Var_AssiFlow : TVar read Assiflow write Assiflow;
     property Var_Temp_f : TVar read Temp_f write Temp_f;
     property Var_Lue    : TVar read LUE write LUE;
     property Opt_Respiration : TRespOptions read RespOptions write RespOptions;
     Property Opt_LAIsource: TSource read fLAIopt write fLAIOpt;
    // Option for Source of LAI


 end;

procedure register;


implementation

uses
  UModUtils, math;

procedure TDryMatterProduction.CreateAll;

begin
  inherited createall;

  ParCreate( 'k','[-]', 0.65, k);
  ParCreate( 'Q10','[-]', 1.8, Q10);
  ParCreate( 'Tempf_T1','[-]', 0, Tempf_T1);
  ParCreate( 'Tempf_T2','[-]', 10, Tempf_T2);
  ParCreate( 'Tempf_T3','[-]', 20, Tempf_T3);
  ParCreate( 'Tempf_T4','[-]', 35, Tempf_T4);


  VarCreate('Assiflow','[g CH2O.m-2.d-1]', 1.0, false, AssiFlow);
  VarCreate('Transmission','[-]', 1.0, false, Transmission);
  VarCreate('LUE','[g.MJ-1]', 1.0, false, LUE);
  VarCreate('Par_abs','[MJ.m-2.d-1]', 1.0, false, Par_abs);
  Par_abs.WriteToFile := false;
  VarCreate('Temp_f','[-]', 1.0, false, Temp_f);
  VarCreate('Teff','[-]', 1.0, false, Teff);
//  Temp_f.WriteToFile := false;

  ExternVcreate('PAR', '[MJ/m-2/d]', StateField, par);
  ExternVcreate('LAI', '[m2/m2]', StateField, lai);
  ExternVcreate('Temp', '[°C]', StateField, Temp);
  ExternVcreate('TotalDrymatter', '[g.m-2]', RateField, TotalDryMatterGr);
end;


{procedure TDryMatterProduction.Set_GlobMod(value:TMod);
begin
  inherited Set_GlobMod(Value);
  createAll;
end;

constructor TDryMatterProduction.create(AOwner:TComponent);

begin
  inherited create(AOwner);
  createAll;
end;}

procedure TDryMatterProduction.CalcRates;

var
T : real;

begin
  t := Temp.v;
  Teff.v := power(Q10.v, (Temp.v-Tref)/10);

  Temp_f.v :=  trapez_f (T, Tempf_T1.v, Tempf_T2.v, Tempf_T3.v, Tempf_T4.v, 0, 1);
  Par_abs.v := Par.v*(1-exp(-k.v*LAI.v));
  If Par.v > 0.0 then
    Transmission.v := 1-par_abs.v/Par.v
  else Transmission.v := 0.0;
end;

procedure TDryMatterProduction.integrate;

begin
  if Par_abs.v > 0.0 then
    LUE.v := TotalDrymatterGr.v/Par_abs.v
  else LUE.v := 0.0;
  inherited integrate;
end;

procedure TDryMatterProduction.SetPlantModel(NewPlantmodel: TAbstractPlant);

begin
  inherited SetPlantModel(NewPlantmodel);
  if IsPlantModelSet then begin
    Ex_LAI.Search := false;
    Ex_LAI.f_v := @Plantmodel.p_LAI.fv;
    Ex_LAI.Source := Plantmodel.Name;
    Ex_TotalDrymatterGr.Search := false;
    Ex_TotalDryMattergr.f_v := @Plantmodel.DMTotal.c;
    Ex_TotalDryMattergr.Source := Plantmodel.Name;
  end;
end;

procedure Register;

begin
  RegisterComponents('Simulation', [TDryMatterProduction]);
end;


end.
