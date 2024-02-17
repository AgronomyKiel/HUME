unit ULogGrowthDemo;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs, UMod, UState;

Type

TLogGrowth = class(TSubmodel)

private

protected

public
  dW_dt : TVar;   // 
  rgr : TVar;   // 


  // Constant Variables


  // State Variables
  Educt : TState;   // 
  Product : TState;   // 

             // Parameters
  mue : TPar;   // 

             // External Variables
  Temp : TExternV;   // 


  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override; 


published
  Property Var_dW_dt : TVar read dW_dt write dW_dt;
  Property Var_rgr : TVar read rgr write rgr;

  Property St_Educt : TState read Educt write Educt;
  Property St_Product : TState read Product write Product;


         // Parameters
  Property Par_mue : TPar read mue write mue;

         // Properties External Variables
  Property Ex_Temp : TExternV read Temp write Temp;


end;  // SubmodelName

procedure Register;

implementation

procedure TLogGrowth.createAll;

begin
  inherited createAll;
  VarCreate('dW_dt', '',0, true, dW_dt, '');  
  VarCreate('rgr', '',0, true, rgr, '');  


  StateCreate('Educt', '',100, true,Educt, '');
  StateCreate('Product', '',0, true,Product, '');


  // Parameters
  ParCreate('mue', '',0,mue, '');

         // External Variable
  ExternVCreate('Temp', '',statefield, Temp);
end;


procedure TLogGrowth.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  Educt.v :=  100;
  Product.v :=  0.001;


end;


procedure TLogGrowth.CalcRates;

begin

   dW_dt.v :=  mue.v * Educt.v*Temp.v*Product.v;
   rgr.v :=  dW_dt.v/Product.v;


   Educt.c :=  -dW_dt.v;
   Product.c :=  +dW_dt.v;


end;




procedure Register;
begin
{$IFNDEF NONVISUAL}

  RegisterComponents('Hume Demo', [TLogGrowth]);
  {$ENDIF}

end;

end.
