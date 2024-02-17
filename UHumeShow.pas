unit UHumeShow;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  vcl.StdCtrls, vcl.ExtCtrls, vcl.Buttons, vcl.MPlayer, mdURLLabel;

type
  TFormHumeShow = class(TForm)
  private
    { Private-Deklarationen }
    fIntervall : integer;
  public
    { Public-Deklarationen }
  published
    property Intervall : integer read fintervall write fintervall;
  end;

var
  FormHumeShow: TFormHumeShow;

implementation

{$R *.DFM}






end.
