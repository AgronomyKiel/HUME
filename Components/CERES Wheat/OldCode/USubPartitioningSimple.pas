unit USubPartitioningSimple;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls,
  vcl.Forms, vcl.Dialogs,
   UMod, UState;

Type

TSubPartitioningSimple = class(TSubmodel)

private

protected

public

  RTWT : TState;   //   Root weight - [g/plant]
  TOPWT : TState;   //   Root weight - [g/plant]
  LFWT : TState;    // Leaf weight of all leaves on a plant [g/plant]
  STMWT : TState;   //  Stem weight of an average tiller after terminal spikelet  [g]


  PTF : TVar;        // Fraction of photosynthesis partitioned to above ground plant parts [-]
  RTWT_m2 : TVar;    // root weight per square meter [g/m2]
  TOPWT_m2 : TVar;   //
  STMWT_m2 : TVar;   // Stem weight per square meter [g/m2]
  LFWT_m2 : TVar;    // leaf weight per square meter [g/m2]
  GRORT : TVar;      // Daily root growth - [g/pl/d]
  GROTOP : TVar;       // Daily shoot growth - [g/pl/d]


  Plants : TPar;   //

  h        : TPar;   {Proportionalitaetskonstante Blatt-Stängel-Verteilung}
  g        : Tpar;   {Proportionalitaetskonstante Blatt-Stängel-Verteilung}


             // External Variables
  CARBO : TExternV;   //
  ISTAGE : TExternV;   //
  EC     : TExternV;

  procedure createAll; override;
  procedure Init(var GlobMod: TMod); override;
  procedure CalcRates; override;
  procedure Integrate; override;

published
  Property St_RTWT : TState read RTWT write RTWT;
  Property St_TOPWT : TState read TOPWT write TOPWT;
  Property St_LFWT : TState read LFWT write LFWT;
  Property St_STMWT : TState read STMWT write STMWT;


  Property Var_PTF : TVar read PTF write PTF;
  Property Var_RTWT_m2 : TVar read RTWT_m2 write RTWT_m2;
  Property Var_TOPWT_m2 : TVar read TOPWT_m2 write TOPWT_m2;
  Property Var_GRORT : TVar read GRORT  write GRORT;
  Property Var_GROTOP: TVar read GROTOP write GROTOP;
  Property Var_LFWT_m2 : TVar read LFWT_m2 write LFWT_m2;
  Property Var_STMWT_m2 : TVar read STMWT_m2 write STMWT_m2;


         // Parameters
  Property Par_Plants : TPar read Plants write Plants;
  property Par_h  : TPar read h write h ;   { Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_g  : Tpar read g write g;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}

         // Properties External Variables
  Property Ex_CARBO : TExternV read CARBO write CARBO;
  Property Ex_ISTAGE : TExternV read ISTAGE write ISTAGE;
  Property Ex_EC : TExternV read EC write EC;

end;  // SubmodelName

procedure Register;

implementation

uses math;

procedure TSubPartitioningSimple.createAll;

begin
  inherited createAll;
  VarCreate('PTF', '[-]',0, true, PTF);
  VarCreate('RTWT_m2', '[g/m2]',0, true, RTWT_m2);
  VarCreate('TOPWT_m2', '',0, true, TOPWT_m2);
  VarCreate('GRORT', '[g/pl/d]',0, true, GRORT);
  VarCreate('GROTOP', '[g/pl/d]',0, true, GROTOP);
  VarCreate('STMWT_m2', '[g/m2]',0, true, STMWT_m2);
  VarCreate('LFWT_m2', '[g/m2]',0, true, LFWT_m2);

  StateCreate('RTWT', '[g/plant]',0, true,RTWT);
  StateCreate('TOPWT', '[g/plant]',0, true,TOPWT);
  StateCreate('LFWT', '[g/plant]',0, true,LFWT);
  StateCreate('STMWT', '[g/plant]',0, true,STMWT);

  // Parameters
  ParCreate('Plants', '[plants/m2]',350, Plants);
  ParCreate('h','[-]', -0.6864, h);
  ParCreate('g','[-]', 1.3129, g);

         // External Variable
  ExternVCreate('CARBO', '',statefield, CARBO);
  ExternVCreate('ISTAGE', '',statefield, ISTAGE);
  ExternVCreate('EC', '',statefield, EC);

end;


procedure TSubPartitioningSimple.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  LFWT.v  :=0.00034;  //???
  STMWT.v := exp(g.v*ln(LFWT.v)+h.v);       // Initialize stem weight
  TOPWT.v := lfWT.v + STMWT.v;
  TOPWT_m2.v :=  TOPWT.v*plants.v;
  STMWT_m2.v :=  STMWT.v*Plants.v;
  LFWT_m2.v :=  LFWT.v*Plants.v;



end;


procedure TSubPartitioningSimple.CalcRates;

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
   If EC.v <= 34 then begin
     STMWT.c :=  TOPWT.c *(1-1/(1+exp(h.v/Plants.v)*power(STMWT.v, g.v - 1)*g.v));
     LFWT.c :=  TOPWT.c-STMWT.c
   end  
   else  begin
     STMWT.c :=  TOPWT.c;
     LFWT.c := 0.0;
   end;  



end;


procedure TSubPartitioningSimple.Integrate;

begin

  inherited  integrate;


  RTWT_m2.v :=  RTWT.v*plants.v;
  TOPWT_m2.v :=  TOPWT.v*plants.v;
  STMWT_m2.v :=  STMWT.v*Plants.v;
  LFWT_m2.v :=  LFWT.v*Plants.v;



end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubPartitioningSimple]);
end;

end.
