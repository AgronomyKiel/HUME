unit ModLink;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod;

type
  TModLink = class(TComponent)
  private
    { Private declarations }

    procedure SetModel (Model:TMod);
  protected
    { Protected declarations }
  public
    { Public declarations }
    fModel : TMod;
  published

    property LinkedModel : TMod read fModel write SetModel;
    { Published declarations }
  end;

procedure register;


implementation


procedure TModLink.SetModel(Model: TMod);

begin
  //showMessage('setting Modelname to: '+Model.Name);
  FModel := Model;
end;

procedure Register;
begin
 RegisterComponents('HUME', [TModLink]);
end;
end.
