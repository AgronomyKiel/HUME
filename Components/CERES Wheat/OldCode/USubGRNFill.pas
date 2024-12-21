unit USubGRNFill;

interface

uses
UMod, UState,Dialogs,Sysutils,
USubLeafAreaGrowthSimple;

const
  MaxLeafNumber = 25;

Type

     TSubLeafArea_UpDate = class(TSubLeafAreaGrowthSimple)
private
    sLAI: boolean;
    LAI_val: real;
    PLA_val: real;
protected
public
     LAI2000    : TState; //LAI2000 gemittelter Messwert aus Updatemethode von TSubModel
     LAI2000_V  : TState; //Varianz der Einzelmesswerte LAI2000 Messwerte aus Updatemethode von TSubModel
     fLAI       : TVAR;
     wtGAI     : TVAR;

    procedure createAll; override;
    procedure CalcRates; override;
    procedure UpdateValues; override;
    procedure Integrate; override;




end;
procedure Register;
implementation
uses
  Math,Classes;
procedure TSubLeafArea_UpDate.CreateAll;
begin
  inherited createAll;
 StateCreate('LAI2000', '[m2/m2]',0,true,LAI2000);
 StateCreate('LAI2000_V', '[]',0,true,LAI2000_V);
 VarCreate('fLAI', '[-]',0, true,fLAI);
 VarCreate('wtGAI', '[-]',0, true,wtGAI);
end;


procedure TSubLeafArea_UpDate.CalcRates;
begin
inherited;
LAI2000.c:=0;
LAI2000_v.c:=0;
end;


procedure TSubLeafArea_UpDate.UpdateValues;
var
 LAIStem_val: real;
 GAI_varianz: real;

 LAI_err: real;
 GAI_: real;
 i: integer;
 sLAI_V : boolean;
 SD_LAI: real; //Gewichtung des Messwerts

begin
     inherited;


   if UpdateValue(LAI2000.Name)<>0 then begin //Hier bitte die Reihenfolge der Submodelle prüfen
        sLAI:=true;
        LAI2000.c:= LAI2000.c + UpdateValue(LAI2000.Name)-(LAI2000.v+LAI2000.c);
        GAI_:= (LAI2000.v+LAI2000.c);
        LAI_err:= GAI_*0.957;   //GAI in LAI
        // SD setzen oder berechnen
        if UpdateValue(LAI2000_v.Name)<> 0 then begin   // Hier ist LAI und SD in der UpDatedatei gegeben...
          LAI2000_v.c:= LAI2000_v.c + UpdateValue(LAI2000_v.Name)-(LAI2000_v.v+LAI2000_v.c);
          GAI_Varianz:= LAI2000_v.v+LAI2000_v.c; //
          sLAI_V:=true;
         // SD_LAI:= max(1,min(0.1,power(GAI_Varianz,(1/2))/(LAI2000.c+LAI2000.v))); //SD 0-1
             SD_LAI:= power(GAI_Varianz,(1/2))/(LAI2000.c+LAI2000.v);
          end else SD_LAI:= 0.5;

        //Raten aktualisieren:
        wtGAI.v:= max(0,1-SD_LAI);
        LAIStem_val:= GAI.v-LAI.v;
        LAI_val:= LAI.v*(1-wtGAI.v)+LAI_err*wtGAI.v;
        PLA_val:= (LAI_val/Plants.v)*10000; //m2->cm2
        GAI.v:= GAI.v*(1-wtGAI.v)+GAI_*wtGAI.v; //keine Rate
        LAIStem.c:=  LAIStem_val-LAIStem.v;
        for i := 1 to MaxLeafNumber do begin
            PLSC[i].v := PLSC[i].v*(LAI_val/LAI.v);
            PL_weight[i].v := PL_weight[i].v*(LAI_val/LAI.v); //individual leaf wight
        end;
        
    end else sLAI:= false;

end;

procedure TSubLeafArea_UpDate.Integrate;
 var
  //Änderungsfaktor LAI
 i: integer;
begin
    inherited;

    if sLAI= true then begin
        fLAI.v:= (LAI_val/LAI.v);
        for i := 1 to MaxLeafNumber do begin // alle Blätter verändern ihre Größe und ihr Gewicht...
            PLSC[i].v := PLSC[i].v*fLAI.v;
            PL_weight[i].v := PL_weight[i].v*fLAI.v; //individual leaf weight
        end;

       senla.c:= 0;
       senla.v:= senla.v*(LAI_val/LAI.v); 
       PLA.c:=0;
       PLA.v:=  PLA_val;
       LAI.c:= 0;
       LAI.v:= LAI_val;
       sLAI:= false;
    end;
end;


procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubLeafArea_UpDate]);
end;

end.

