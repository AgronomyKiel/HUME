unit CopyToNiko;

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
var
  quelldatei, zieldatei: string;
  searchResult: TSearchRec;
  d: TDateTime;
begin

  if FindFirst('*.exe', faAnyFile, searchResult) = 0 then begin
    repeat


      Quelldatei := searchResult.Name;

      //ShowMessage(quelldatei);

      if (AnsiPos('CopyTo', quelldatei) = 0) then begin

        d := FileDateToDateTime(FileAge(Quelldatei));

        Zieldatei := 'B:\Modelle\Niko\EXE\' + ChangeFileExt(quelldatei, '') +
          '_' + FormatDateTime('yyyy_mm_dd_hhnn', d) + '.exe';

        if not CopyFile(PChar(Quelldatei), PChar(Zieldatei), true) then
          ShowMessage('Datei "' + Quelldatei + '" konnte nicht kopiert werden!')
        else
          ShowMessage('Datei "' + Quelldatei + '" erfolgreich kopiert!');
     end;
    until FindNext(searchResult) <> 0;

    // Must free up resources used by these successful finds
    FindClose(searchResult);
  end;

end;

end.

