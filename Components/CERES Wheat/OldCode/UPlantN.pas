unit UPlantN;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UState, Math;

type
  TPlantN = class(TSubmodel)
  private
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public
    { Public-Deklarationen }
    Ndef1, ndef2, ndef3, ndef4: TVar;



    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;

  published
    { Published-Deklarationen }
  end;

procedure Register;

implementation

procedure TPlantN.createall;

begin
  inherited createAll;
  Varcreate('ndef1', '-', 1, true, ndef1);
  Varcreate('ndef2', '-', 1, true, ndef2);
  Varcreate('ndef3', '-', 1, true, ndef3);
  Varcreate('ndef4', '-', 1, true, ndef4);

end;

procedure TPlantN.init(var GlobMod: TMod);
begin
  inherited init(GlobMod);
  ndef1.v := 1;
  ndef2.v := 1;
  ndef3.v := 1;
  ndef4.v := 1;
end;

procedure TPlantN.CalcRates;
begin
  ndef1.v := 1;
  ndef2.v := 1;
  ndef3.v := 1;
  ndef4.v := 1;

end;


procedure Register;
begin

  RegisterComponents('CERES Wheat', [TPlantN]);
end;

end.
