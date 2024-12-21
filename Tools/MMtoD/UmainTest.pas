unit ULogGrowth;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type

TLogGrowth = class(TSubmodel)

private

protected

public
  dW_dt : TVar;   // 
  RGR : TVar;   // 


  // Constant Variables


  // State Variables
  S : TState;   // 
  W : TState;   // 

             // Parameters
  mue : TPar;   // 

             // External Variables


  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override; 


published
  Property Var_dW_dt : TVar read dW_dt write dW_dt;
  Property Var_RGR : TVar read RGR write RGR;

  Property St_S : TState read S write S;
  Property St_W : TState read W write W;


         // Parameters
  Property Par_mue : TPar read mue write mue;

         // Properties External Variables


end;  // SubmodelName

procedure Register;

implementation

procedure TLogGrowth.createAll;

begin
  inherited createAll;
  VarCreate('dW_dt', '',0, true, dW_dt, '');  
  VarCreate('RGR', '',0, true, RGR, '');  


  StateCreate('S', '',0, true,S, '');
  StateCreate('W', '',0, true,W, '');


  // Parameters
  ParCreate('mue', '',0,mue, '');

         // External Variable
end;


procedure TLogGrowth.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  S.v :=  S0;
  W.v :=  W0;


end;


procedure TLogGrowth.CalcRates;

begin

   dW_dt.v :=  mue.v*S.v*W;
   RGR.v :=  dW_dt.v/W;


   S.c :=  -dW_dt;
   W.c :=  +dW_dt;


end;



end;

procedure Register;
begin
  RegisterComponents('Demo', [TLogGrowth]);
end;

end.
