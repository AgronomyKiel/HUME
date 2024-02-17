unit SubmodLogist_pub;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
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
    S0      : TPar; /// Substrate amount at start
    rgr     : TVar;
    Temp    : TexternV;
    procedure CreateAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    { Public declarations }
  published
    property St_Educt   : TState   read Educt   write Educt;
    property St_Product : TState   read Product write Product;
    property Par_gr     : TPar     read gr      write gr;
    property Par_S0     : TPar     read S0      write S0;
    property Var_rgr    : TVar     read rgr     write rgr;
    property Ex_Temp    : TExternV read Temp    write Temp;
    { Published declarations }
  end;

procedure Register;

implementation

procedure TLogistGrowth.createAll;

begin
  inherited createAll;
  StateCreate('Educt',   '[g]', 100.0, true, Educt, 'Educt');
  StateCreate('Product', '[g]',   0.1, true, product);
  ParCreate('gr',        '[d-1]', 0.02, gr, 'Growth rate parameter');
  ParCreate('S0',        '[d-1]', 100, S0, 'Initial amount of Substrate');
  VarCreate('rgr',       '[d-1]', 0.0, true, rgr);
  VarCreate('Product_Ana',       '[g]', 0.0, true, Product_Ana, 'Product computed from analytical solution');
  ExternVCreate('Temp',  '[°C]', statefield, Temp);

end;

procedure TLogistGrowth.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  Educt.v := S0.v;
  If product.v <> 0.0 then
    rgr.v     := product.c/product.v
  else rgr.v := 0.0;
end;

procedure TLogistGrowth.CalcRates;

begin
  Product.c := Educt.v*gr.v{*Temp.v}*Product.v;
  Educt.c   := -Product.c;
  If product.v <> 0.0 then
    rgr.v     := product.c/product.v;
  Product_Ana.v := (100*0.1)/(0.1-(0.1-100)*exp(-gr.v*100*GlobTime.v));
end;

procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('HUMEDemo', [TLogistGrowth]);
{$ENDIF}
end;

end.
