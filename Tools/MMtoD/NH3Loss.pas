unit Umain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UMod, UState;

Type

Tmain = class(TSubmodel)

private

protected

public
  Km : TVar;   // 
  Lossrate : TVar;   // 
  Nmax : TVar;   // 


  // Constant Variables

  LossPig : TState;   // 

             // Parameters
  b01 : TPar;   // 
  b02 : TPar;   // 
  bdrymatter1 : TPar;   // 
  bdrymatter2 : TPar;   // 
  bincorporation1 : TPar;   // 
  bincorporation2 : TPar;   // 
  bmanurerate1 : TPar;   // 
  bmanurerate2 : TPar;   // 
  bmassbalance1 : TPar;   // 
  bmassbalance2 : TPar;   // 
  bntan1 : TPar;   // 
  bntan2 : TPar;   // 
  bslurrytype1 : TPar;   // 
  bslurrytype2 : TPar;   // 
  bsoiltype1 : TPar;   // 
  bsoiltype2 : TPar;   // 
  btemp1 : TPar;   // 
  btemp2 : TPar;   // 
  btrailingshoe1 : TPar;   // 
  btrailingshoe2 : TPar;   // 
  bwind1 : TPar;   // 
  bwind2 : TPar;   // 

             // External Variables
  drymatter : TExternV;   // 
  incorporation : TExternV;   // 
  manurerate : TExternV;   // 
  massbalance : TExternV;   // 
  ntan : TExternV;   // 
  pig : TExternV;   // 
  soiltype : TExternV;   // 
  temp : TExternV;   // 
  trailingshoe : TExternV;   // 
  wind : TExternV;   // 


  procedure createAll; override; 
  procedure Init(var GlobMod: TMod); override; 
  procedure CalcRates; override; 


published
  Property Var_Km : TVar read Km write Km;
  Property Var_Lossrate : TVar read Lossrate write Lossrate;
  Property Var_Nmax : TVar read Nmax write Nmax;

  Property St_LossPig : TState read LossPig write LossPig;


         // Parameters
  Property Par_b01 : TPar read b01 write b01;
  Property Par_b02 : TPar read b02 write b02;
  Property Par_bdrymatter1 : TPar read bdrymatter1 write bdrymatter1;
  Property Par_bdrymatter2 : TPar read bdrymatter2 write bdrymatter2;
  Property Par_bincorporation1 : TPar read bincorporation1 write bincorporation1;
  Property Par_bincorporation2 : TPar read bincorporation2 write bincorporation2;
  Property Par_bmanurerate1 : TPar read bmanurerate1 write bmanurerate1;
  Property Par_bmanurerate2 : TPar read bmanurerate2 write bmanurerate2;
  Property Par_bmassbalance1 : TPar read bmassbalance1 write bmassbalance1;
  Property Par_bmassbalance2 : TPar read bmassbalance2 write bmassbalance2;
  Property Par_bntan1 : TPar read bntan1 write bntan1;
  Property Par_bntan2 : TPar read bntan2 write bntan2;
  Property Par_bslurrytype1 : TPar read bslurrytype1 write bslurrytype1;
  Property Par_bslurrytype2 : TPar read bslurrytype2 write bslurrytype2;
  Property Par_bsoiltype1 : TPar read bsoiltype1 write bsoiltype1;
  Property Par_bsoiltype2 : TPar read bsoiltype2 write bsoiltype2;
  Property Par_btemp1 : TPar read btemp1 write btemp1;
  Property Par_btemp2 : TPar read btemp2 write btemp2;
  Property Par_btrailingshoe1 : TPar read btrailingshoe1 write btrailingshoe1;
  Property Par_btrailingshoe2 : TPar read btrailingshoe2 write btrailingshoe2;
  Property Par_bwind1 : TPar read bwind1 write bwind1;
  Property Par_bwind2 : TPar read bwind2 write bwind2;

         // Properties External Variables
  Property Ex_drymatter : TExternV read drymatter write drymatter;
  Property Ex_incorporation : TExternV read incorporation write incorporation;
  Property Ex_manurerate : TExternV read manurerate write manurerate;
  Property Ex_massbalance : TExternV read massbalance write massbalance;
  Property Ex_ntan : TExternV read ntan write ntan;
  Property Ex_pig : TExternV read pig write pig;
  Property Ex_soiltype : TExternV read soiltype write soiltype;
  Property Ex_temp : TExternV read temp write temp;
  Property Ex_trailingshoe : TExternV read trailingshoe write trailingshoe;
  Property Ex_wind : TExternV read wind write wind;


end;  // SubmodelName

procedure Register;

implementation

procedure Tmain.createAll;

begin
  inherited createAll;
  VarCreate('Km', '',0, true, Km);  
  VarCreate('Lossrate', '',0, true, Lossrate);  
  VarCreate('Nmax', '',0, true, Nmax);  


  StateCreate('LossPig', '',0, true,LossPig);


  // Parameters
  ParCreate('b01', '',0,b01);
  ParCreate('b02', '',0,b02);
  ParCreate('bdrymatter1', '',0,bdrymatter1);
  ParCreate('bdrymatter2', '',0,bdrymatter2);
  ParCreate('bincorporation1', '',0,bincorporation1);
  ParCreate('bincorporation2', '',0,bincorporation2);
  ParCreate('bmanurerate1', '',0,bmanurerate1);
  ParCreate('bmanurerate2', '',0,bmanurerate2);
  ParCreate('bmassbalance1', '',0,bmassbalance1);
  ParCreate('bmassbalance2', '',0,bmassbalance2);
  ParCreate('bntan1', '',0,bntan1);
  ParCreate('bntan2', '',0,bntan2);
  ParCreate('bslurrytype1', '',0,bslurrytype1);
  ParCreate('bslurrytype2', '',0,bslurrytype2);
  ParCreate('bsoiltype1', '',0,bsoiltype1);
  ParCreate('bsoiltype2', '',0,bsoiltype2);
  ParCreate('btemp1', '',0,btemp1);
  ParCreate('btemp2', '',0,btemp2);
  ParCreate('btrailingshoe1', '',0,btrailingshoe1);
  ParCreate('btrailingshoe2', '',0,btrailingshoe2);
  ParCreate('bwind1', '',0,bwind1);
  ParCreate('bwind2', '',0,bwind2);

         // External Variable
  ExternVCreate('drymatter', '',statefield, drymatter);
  ExternVCreate('incorporation', '',statefield, incorporation);
  ExternVCreate('manurerate', '',statefield, manurerate);
  ExternVCreate('massbalance', '',statefield, massbalance);
  ExternVCreate('ntan', '',statefield, ntan);
  ExternVCreate('pig', '',statefield, pig);
  ExternVCreate('soiltype', '',statefield, soiltype);
  ExternVCreate('temp', '',statefield, temp);
  ExternVCreate('trailingshoe', '',statefield, trailingshoe);
  ExternVCreate('wind', '',statefield, wind);
end;


procedure Tmain.init(var GlobMod: TMod);

begin
  inherited init(GlobMod);
  LossPig.v := 0;


end;


procedure Tmain.CalcRates;

begin

   Km.v :=  exp(b02.v+bsoiltype.v2.v*soiltype.v+btemp.v2.v*temp.v+bwind.v2.v*wind.v+bslurrytype2.v*pig.v+bdrymatter.v2.v*drymatter.v+bntan.v2.v*ntan.v+btrailingshoe.v2.v*trailingshoe.v+bmanurerate.v2.v*manurerate.v+bincorporation.v2.v*incorporation.v+bmassbalance.v2.v*massbalance.v);
   Lossrate.v :=  Nmax.v*Km.v/(t+Km.v)^2*100;
   Nmax.v :=  exp(b01.v+bsoiltype.v1.v*soiltype.v+btemp.v1.v*temp.v+bwind.v1.v*wind.v+bslurrytype1.v*pig.v+bdrymatter.v1.v*drymatter.v+bntan.v1.v*ntan.v+btrailingshoe.v1.v*trailingshoe.v+bmanurerate.v1.v*manurerate.v+bincorporation.v1.v*incorporation.v+bmassbalance.v1.v*massbalance.v);


   LossPig.c :=  Lossrate.v;


end;



end;

procedure Register;
begin
  RegisterComponents('Ceres Wheat', [Tmain]);
end;

end.
