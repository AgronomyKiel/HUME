unit UFormDebugAbstract;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, vcl.Graphics, vcl.Controls, vcl.Forms,
  vcl.Dialogs;

type
  TFormDebugAbstract = class(TForm)

  private
    { Private-Deklarationen }


  public
    { Public-Deklarationen }

   procedure update; virtual; abstract;
   procedure init; virtual; abstract;
   procedure MyCreate; virtual; abstract;

  end;

var
  FormDebugAbstract: TFormDebugAbstract;

implementation

{$R *.dfm}

end.
