unit CopyFile;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);

var quelldatei, zieldatei: string;
begin
 Quelldatei :=   'TDR_Proj.exe';
 Zieldatei := 'B:\Modelle\Niko\EXE\TDR_Proj_' + FormatDateTime('yyyy_mm_dd_hh_nn', now);

 if not CopyFile(PChar(Quelldatei), PChar(Zieldatei), true) then
   ShowMessage('Datei "' + Quelldatei + '" konnte nicht kopiert werden!');

end;

end.
