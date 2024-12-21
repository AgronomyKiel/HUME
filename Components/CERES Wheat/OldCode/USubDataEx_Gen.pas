unit USubDataEx_Gen;

{
submodel for data-extraction
 }
interface
uses
UMod, UState,Dialogs,Sysutils,UFORMMOD; //Unit in der TSubPart.... definiert ist


     Type
     TOptDataEx = (DataEx,NoDataEx);
     TSubDataEX = class(TSubModel)

     public // TILN   : TExternV;
        AssimPool: TExternV;
        fDataEx : TOptDataEx;
        NNI: TExternV;
        GPSM: TExternV;
        Shoot_N: TExternV;
        Q45: TExternV;
        EC: TExternV;
        DM_v: TExternV;
        DMStem_v: TExternV;
        Carbo_gf: TExternV;
        DONE1,DONE2,Done3: boolean;
        optDataEx : TOption;
        Carbosum: Real;
        DSEE: integer;

        {optDataEx : TOption;
        fDataEx : TOptDataEx;
        EC: TExternV;
        NShoot: TExternV;
        DONE1,DONE2,Done3: boolean;
        }

       procedure createAll; override; //override, weil Prozedur schon in der Mutter drin ist
       procedure Init(var GlobMod: TMod); override;

       procedure CalcRates; override;
       published
           //Property Var_GRNYD : TVar read GRNYD write GRNYD;
     end;
           //regestriert das Submodell
   procedure Register;

implementation
uses Classes, math;




procedure TSubDataEx.createAll;

begin
  inherited; // StatNcShootreate('P5', '[d]',0, true,P5);

ExternVCreate('GPSM', '',statefield, GPSM);
ExternVCreate('AssimPool', '',statefield, AssimPool);
ExternVCreate('DM', '',statefield, DM_v);
ExternVCreate('Shoot_N', '',statefield, Shoot_N);
ExternVCreate('Carbo_gf', '',statefield, Carbo_gf);
ExternVCreate('DMstem', '',statefield, DMStem_v);
ExternVCreate('EC', '',statefield, EC);
ExternVCreate('NNI', '',statefield, NNI);
ExternVCreate('Q45', '',statefield, Q45);
{
ExternVCreate('EC', '',statefield, EC);
ExternVCreate('NShoot', '',statefield, NShoot);
}
OptCreate('optDataEx', 'DataEX',optDataEx);
                       optDataEx.OptionList.Clear;
                       optDataEx.OptionList.Add('DataEx');
                       optDataEx.OptionList.Add('NoDataEx');

end;

procedure TsubDataEx.init(var GlobMod: TMod);  //Initialisieren
begin
  inherited init(GlobMod);
   if optDataEx.option = 'dataex' then begin
  fDataEx:= DataEx;

    end;

  if optDataEx.option = 'nodataex' then begin
  fDataEx:= NoDataEx;
end;


end;

procedure TSubDataEx.CalcRates;
   var F: TextFile; var F2: TextFile;
   var F0: String;
   var VName: String;


begin
{
if(fDataEx= DataEx)
then begin

 //if (EC.v>= 49) then DSEE:= DSEE+1;

// if (EC.v>= 70) and (EC.v<= 90) then
 //CarboSum:= CarboSum + Carbo_gf.v;


 if (GlobMod.Starttime = globtime.v) then begin
Done1:= false; Done2:=false; Done3:=false;// Carbosum:=0; DSEE:=0;
end;

//  if (GlobMod.Endtime = globtime.v+1) then begin
{If (EC.v>10) and (EC.v<30) then begin // (Done1=false)  then begin
        VName:= 'NSHOOT';
        F0:= 'C:\Daten\OUTPUT\LWK\'+VName+'.txt';

        assignFile(F,F0);


        if Fileexists(F0) then append(F)else rewrite(F);
          writeln(F,ExtractFileName(GlobMod.actinifile.filename),'Time: ',FloatToStrF(globtime.v-1,ffFixed,15,2),' EC: ',FloatToStrF(EC.v,ffFixed,15,2),' '+VName+': ',FloatToStrF(NShoot.v,ffFixed,15,2));
            closeFile(F);
            Done1:=true;
            {if Fileexists('C:\Daten\OUTPUT\DMSTEMEC49.txt') then append(F2)else rewrite(F2);
           writeln(F,ExtractFileName(GlobMod.actinifile.filename),'DMSTEMEC49 ',FloatToStrF(DMSTEM_v.v,ffFixed,15,2));
            closeFile(F2);
            Done1:=true;}
{
       end;

end;


 }



end;//ENDE











procedure Register;
begin
  RegisterComponents('Ceres Wheat', [TSubDataEx]);
end;

end.
