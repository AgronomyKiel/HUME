unit USubPartitioningSimpleLAI;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   UMod, UState;

Type

TSubPartitioningSimpleLAI = class(TSubmodel)

private

protected

public

  RTWT : TState;   //   Root weight - [g/plant]
  TOPWT : TState;   //   Root weight - [g/plant]

  PTF : TVar;        // Fraction of photosynthesis partitioned to above ground plant parts [-]
  RTWT_m2 : TVar;    // root weight per square meter [g/m2]
  TOPWT_m2 : TVar;   //
  GRORT : TVar;      // Daily root growth - [g/pl/d]
  GROTOP : TVar;       // Daily shoot growth - [g/pl/d]


  Plants : TPar;   //

             // External Variables
  CARBO : TExternV;   //
  ISTAGE : TExternV;   //

  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;

published
  Property St_RTWT : TState read RTWT write RTWT;
  Property St_TOPWT : TState read TOPWT write TOPWT;


  Property Var_PTF : TVar read PTF write PTF;
  Property Var_RTWT_m2 : TVar read RTWT_m2 write RTWT_m2;
  Property Var_TOPWT_m2 : TVar read TOPWT_m2 write TOPWT_m2;
  Property Var_GRORT : TVar read GRORT  write GRORT;
  Property Var_GROTOP: TVar read GROTOP write GROTOP;


         // Parameters
  Property Par_Plants : TPar read Plants write Plants;

         // Properties External Variables
  Property Ex_CARBO : TExternV read CARBO write CARBO;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;

end;  // SubmodelName

procedure Register;

implementation

uses math;

procedure TSubPartitioningSimpleLAI.createAll;

begin
  inherited createAll;
  VarCreate('PTF', '[-]',0, true, PTF);
  VarCreate('RTWT_m2', '[g/m2]',0, true, RTWT_m2);
  VarCreate('TOPWT_m2', '',0, true, TOPWT_m2);
  VarCreate('GRORT', '[g/pl/d]',0, true, GRORT);
  VarCreate('GROTOP', '[g/pl/d]',0, true, GROTOP);

  StateCreate('RTWT', '[g/plant]',0, true,RTWT);
  StateCreate('TOPWT', '[g/plant]',0, true,TOPWT);

  // Parameters
  ParCreate('Plants', '[plants/m2]',350, Plants);

         // External Variable
  ExternVCreate('CARBO', '',statefield, CARBO);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);

end;


procedure TSubPartitioningSimpleLAI.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);

end;


procedure TSubPartitioningSimpleLAI.CalcRates;

begin
   IF (ISTAGE.v < 9) and (ISTAGE.v>=5)
     then PTF.v := 1.0 else
   If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  PTF.v :=   0.8
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  PTF.v :=   0.75
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  PTF.v :=   0.70
   else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  PTF.v :=   0.5
   else  PTF.v :=   0.0  ;

   GRORT.v :=   (1-PTF.v)*CARBO.v;
   GROTOP.v := PTF.v * CARBO.v;

   RTWT.c :=  (1-PTF.v)*CARBO.v;
   TOPWT.c := PTF.v *CARBO.v;


end;


procedure TSubPartitioningSimpleLAI.Integrate;

begin

  inherited  integrate;


  RTWT_m2.v :=  RTWT.v*plants.v;

  TOPWT_m2.v :=  TOPWT.v*plants.v;


end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningSimpleLAI]);
end;

end.
