unit UFileInput;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod, UTextFileH, UState, UModUtils;

const
  MaxVars = 20;

type
  TVarArray = array[0..MaxVars-1] of TVar;

  TFileInput = class(TSubmodel)
  private
    { Private-Deklarationen }
  protected

  public

    { Protected-Deklarationen }
   VarArray : TVarArray;
   procedure CreateAll; override;

   procedure Init(var GlobMod:Tmod); override;
   procedure CalcRates; override;
   procedure SaveState(var f:text; fn:string; Time: TState; IniFile:string=''); override;
   procedure SaveRate(var f:text; fn:string; Time: TState); override;

   procedure Integrate; override;


    { Public-Deklarationen }
  published
    { Published-Deklarationen }
  end;

procedure Register;

implementation



procedure TFileInput.CreateAll;
var
  i : integer;
begin
  inherited createAll;

  for i := 0 to MaxVars-1 do
    VarCreate('Var_'+inttostr(i), '[-]', 0.0, false, VarArray[i]);
end;



procedure TFileInput.Init(var GlobMod:Tmod);
var
  I : integer;

begin
  inherited Init(GlobMod);
  If SomethingMeasured then begin
    for i := 0 to FMeasValues.FirstLine.count-2 do begin
      VarArray[i].Name := FMeasValues.Firstline.strings[i+1];
      VarArray[i].Units := FMeasValues.UnitLine.strings[i+1];
    end;

    FMeasValues.LocateFor(GlobTime.Name, GlobTime.v);
  end;

end;


procedure TFileInput.CalcRates;

var
  i : integer;
  ActVar : Tvar;

begin
  If GlobTime.V >= FMeasValues.getIndexValue(0) then begin
    for i := 0 to VarStrList.Count-1 do begin
      ActVar := TVar(VarSTrList.objects[i]);
      ActVar.v := FMeasValues.getValue(ActVar.name);
    end;
    FMeasValues.NextLine;
  end;
end;


procedure TFileInput.SaveState(var f:text; fn:string; Time: TState; IniFile:string='');
begin
  inherited SaveState(f, fn, Time, '');
// Do nothing
end;

procedure TFileInput.SaveRate(var f:text; fn:string; Time: TState);
begin
// Do nothing
end;

procedure TFileInput.Integrate;

begin
// Do nothing
end;


procedure Register;
begin
{$IFNDEF NONVISUAL}
  RegisterComponents('Simulation', [TFileInput]);
{$ENDIF}
end;

end.
