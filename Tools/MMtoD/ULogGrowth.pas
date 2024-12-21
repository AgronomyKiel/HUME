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
  RGR   : TVar;   //


  // Constant Variables


  // State Variables
  S : TState;   // 
  W : TState;   // 

             // Parameters
  mue : TPar;   //
  S0  : TPar;  /// initial value for substrate
  W0  : TPar;  /// initial value for biomass

             // External Variables
  TMPM : TExternV;

  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override;
  procedure CalcVars; override;


published
  Property Var_dW_dt : TVar read dW_dt write dW_dt;
  Property Var_RGR : TVar read RGR write RGR;

  Property St_S : TState read S write S;
  Property St_W : TState read W write W;


         // Parameters
  Property Par_mue : TPar read mue write mue;
  Property Par_S0 : TPar read S0 write S0;
  Property Par_W0 : TPar read W0 write W0;

         // Properties External Variables


end;  // SubmodelName

procedure Register;

implementation

procedure TLogGrowth.createAll;

begin
  inherited createAll;
  VarCreate('dW_dt', '[g/d]',0, true, dW_dt, 'Zuwachsrate');
  VarCreate('RGR', '',0, true, RGR, '');


  StateCreate('S', '[g/m2]',0, true,S, '');
  StateCreate('W', '[g/m2]',0, true,W, '');


  // Parameters
  ParCreate('mue', '',0, mue, '');
  ParCreate('S0', '',0,  S0, '');
  ParCreate('W0', '',0,  W0, '');

         // External Variable

  ExternVCreate('TMPM', '[°C]',  statefield, TMPM, 'Tagesmitteltemperatur');

end;


procedure TLogGrowth.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  S.v :=  S0.v;
  W.v :=  W0.v;
end;


procedure TLogGrowth.CalcVars;

begin
   RGR.v :=  dW_dt.v/W.v;
end;


procedure TLogGrowth.CalcRates;

begin

   dW_dt.v :=  mue.v*S.v*W.v*TMPM.v;
   S.c :=  -dW_dt.v;
   W.c :=  +dW_dt.v;


end;


procedure Register;
begin
  RegisterComponents('Demo', [TLogGrowth]);
end;

end.
