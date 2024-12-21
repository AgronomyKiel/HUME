unit UFileInputIntPol;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UMod, UTextFileH, UState, UModUtils;

const
  MaxVars = 20;

type
  TVarArray = array[0..MaxVars-1] of TVar;

  TFileInputIntPol = class(TSubmodel)
  private
    { Private-Deklarationen }
   OldVarVal, NextVarVal:  array[0..MaxVars-1] of real;
   IsInit : boolean;
   oldtime, nexttime : real;

  protected

  public

    { Protected-Deklarationen }
   VarArray : TVarArray;
   procedure createAll; override;

   procedure Init(var GlobMod:Tmod); override;
   procedure CalcRates; override;
   procedure SaveState(var f:text; fn:string; Time: TState); override;
   procedure SaveRate(var f:text; fn:string; Time: TState); override;
   procedure AddDataValueToDataSeries; override;

   procedure Integrate; override;


    { Public-Deklarationen }
  published
    { Published-Deklarationen }
  end;

procedure Register;

implementation



procedure TFileInputIntPol.CreateAll;

var
  Name, units : string;
  i : integer;

begin
  inherited createAll;

  for i := 0 to MaxVars-1 do
    VarCreate('Var_'+inttostr(i), '[-]', 0.0, false, VarArray[i]);

end;

procedure TFileInputIntPol.AddDataValueToDataSeries;

begin

end;



procedure TFileInputIntPol.Init(var GlobMod:Tmod);

var
  fn : string;
  ActVar : TVar;
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
  for i := 0 to MaxVars-1 do
    OldVarVal[i] := 0.0;
//  fMeasvalues.nextline;

  for i := 0 to VarStrList.Count-1 do begin
     ActVar := TVar(VarSTrList.objects[i]);
     ActVar.v := FMeasValues.getValue(ActVar.name);
     OldVarVal[i] := ActVar.v;
     oldtime := globtime.v;
  end;
 // fMeasvalues.nextline;    // geändert Ratjen 12.09.08
  for i := 0 to VarStrList.Count-1 do begin
     ActVar := TVar(VarSTrList.objects[i]);
     ActVar.v := FMeasValues.getValue(ActVar.name);
     NextVarVal[i] := ActVar.v;
      Nexttime := fMeasValues.Getindexvalue(0);
     Oldtime := Nexttime;

     ActVar.v:=0;  // geändert Ratjen 12.09.08
  end;



end;


procedure TFileInputIntPol.CalcRates;

var
  i : integer;
  ActVar, TimeVar : Tvar;


begin
    for i := 0 to VarStrList.Count-1 do begin
      ActVar := TVar(VarSTrList.objects[i]);
      If oldtime = globtime.v then             // geändert Ratjen 12.09.08   alt:  If oldtime = globtime.v +1 then
        ActVar.v := Oldvarval[i];



      if ((nexttime-oldtime)> 0) and (globtime.v >=oldtime)  then
        ActVar.v := oldVarVal[i]+(NextVarVal[i]-oldVarVal[i])/(nexttime-oldtime)*(globtime.v-oldtime) else
        end;

  If GlobTime.V >= Nexttime then begin
    for i := 0 to VarStrList.Count-1 do begin
        OldVarVal[i] := NextVarVal[i];
    end;
    oldtime := NextTime;
      FMeasValues.NextLine;
      Nexttime := FMeasValues.getindexValue(0);
//    NextTime := Timevar.v;
      for i := 0 to VarStrList.Count-1 do begin
        ActVar := TVar(VarSTrList.objects[i]);
        ActVar.v := FMeasValues.getValue(ActVar.name);
        NextVarVal[i] := ActVar.v;
        Nexttime := fMeasValues.Getindexvalue(0);
        ActVar.v := Oldvarval[i];
      end;

   end;
end;
//end;


procedure TFileInputIntPol.SaveState(var f:text; fn:string; Time: TState);
begin
  inherited SaveState(f, fn, Time);
// Do nothing
end;

procedure TFileInputIntPol.SaveRate(var f:text; fn:string; Time: TState);
begin
// Do nothing
end;

procedure TFileInputIntPol.Integrate;

begin
// Do nothing
end;


procedure Register;
begin
  RegisterComponents('Simulation', [TFileInputIntPol]);
end;

end.
