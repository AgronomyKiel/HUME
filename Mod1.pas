unit Mod1;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, UMod;

type
  TMod_new = class(TMod)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TMod_new]);
end;

end.
