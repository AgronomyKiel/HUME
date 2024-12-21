unit SubmodLogist;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UState;

type
  TLogistGrowth = class(TSubmodel)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    Educt,
    Product : TState;
    Product_Ana : TVar;
    gr      : Tpar;
    rgr     : TVar;
    Temp    : TexternV;

    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    { Public declarations }
  published
    property St_Educt   : TState   read Educt   write Educt;
    property St_Product : TState   read Product write Product;
    property Par_gr     : TPar     read gr      write gr;
    property Var_rgr    : TVar     read rgr     write rgr;
    property Ex_Temp    : TExternV read Temp    write Temp;
    { Published declarations }
  end;

procedure Register;

implementation

procedure TLogistGrowth.createAll;

begin
  inherited createAll;
  StateCreate('Educt',   '[g]', 100.0, true, Educt);
  StateCreate('Product', '[g]',   0.1, true, product);
  ParCreate('gr',        '[d-1]',0.02, gr);
  VarCreate('rgr',       '[d-1]', 0.0, true, rgr);
  VarCreate('Product_Ana',       '[g]', 0.0, true, Product_Ana);
  ExternVCreate('Temp',  '[°C]', statefield, Temp);
end;

procedure TLogistGrowth.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  rgr.v     := product.c/product.v;
end;

procedure TLogistGrowth.CalcRates;

begin
  Product.C := Educt.v*gr.v{*Temp.v}*Product.v;
  Educt.c   := -Product.c;
  rgr.v     := product.c/product.v;
  Product_Ana.v := (100*0.1)/(0.1-(0.1-100)*exp(-gr.v*100*GlobTime.v));
end;

procedure Register;
begin
  RegisterComponents('HUMEDemo', [TLogistGrowth]);
end;

end.
