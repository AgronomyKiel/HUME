program OntoWangEngelStreck;

uses
  Forms,
  UFormMod in '\\SAMBARZ\PFLANZENMODELL\HUME\UFORMMOD.pas' {FormMod},
  FormDevWangStreck in 'FormDevWangStreck.pas' {FormMod1},
  UDevWangEngelStreck in '\\samba\pflanzenmod\Ceres Wheat\EntwModWang\UDevWangEngelStreck.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMod1, FormMod1);
  Application.Run;
end.
