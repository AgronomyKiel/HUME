unit UVarREc;

interface

uses
  classes, UState;

type
     AListRecord = class(Tpersistent)
     public

       Key, Name, Typ: String;
       Comment: array[0..40] of String;
       Bedingung: array[0..40] of string;
       Action: array[0..40] of string;
       Acb, Formel, Initial, Default,
       Diff, Delay, MaxDelay,
       Tolerance, Period, Start: string;
      constructor create;

     end;

     T_CompEvent = class(TPersistent)
     private

     public
       Name : string;
       Comment : string;
       Tolerance : real;
       ConditionStr : string;
       ActionStrArr   : Array[1..20] of String;
       constructor create;
//       procedure writeHumeCode;
     end;


implementation

constructor AListRecord.create;

begin
 inherited create;
end;

constructor T_CompEvent.create;


begin
  inherited;
end;




end.

