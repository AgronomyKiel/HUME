unit USimplePlantN;

interface

uses
 USimplePlant, UState, Umod, IniFiles, dialogs, Classes;

type
  real = double;

TSimplePlantN = Class(TSimplePlant)

  public
    NStem  : TState;            // NMenge Stengel [g N/m2]
    NLeaf  : TState;
    NGen   : TState;            // N-Menge in generativen Organen [g N/m2]
    NRoot  : TState;            //  N-Menge in Wurzeln [g N/m2]
    NVeg   : TVar;
    NTotal : TState;
    PlantNDemand : TVar;
    rgrStem,
    rgrLeaf,
    rgrGen : TVar;

    NOptStem,
    NOptLeaf,
    NOptGen  : TVar;

    NPrStem,
    NPrLeaf,
    NPrGen  : TVar;

   Constructor create(AOwner: TComponent); override;
   procedure Set_GlobMod(value:TMod); override;

   procedure calcrates; override;

   private

 end;


implementation

uses math;

constructor TSimplePlantN.create (AOwner : Tcomponent);

begin

  inherited create(AOwner);

  StateCreate('NStem', '[g N .m-2]', 0.0, false, NStem);
  StateCreate('NLeaf', '[g N .m-2]', 0.0, false, NLeaf);
  StateCreate('NCurd', '[g N .m-2]', 0.0, false, NGen);
  VarCreate('Nveg',  '[g N .m-2]', 0.0,   false, NVeg);
  VarCreate('rgrLeaf',  '[g.g-1]', 0.0,   false, rgrLeaf);
  VarCreate('rgrStem',  '[g.g-1]', 0.0,   false, rgrstem);
  VarCreate('rgrGen',  '[g.g-1]', 0.0,   false, rgrGen);
  StateCreate('NRoot',  '[g N .m-2]', 0.0, false,NRoot);

  VarCreate('NOptStem',  '[%N/DM]', 3.0,  false, NOptStem);
  VarCreate('NOptLeaf',  '[%N/DM]', 5.0,  false, NOptLeaf);
  VarCreate('NOptGen',  '[%N/DM]', 5.0,   false, NOptGen);

  VarCreate('NPrStem',  '[%N/DM]', 3.0,  false, NPrStem);
  VarCreate('NPrLeaf',  '[%N/DM]', 5.0,  false, NPrLeaf);
  VarCreate('NPrGen',  '[%N/DM]', 5.0,   false, NPrGen);

  Statecreate('TotalPlantNitrogen', '[gN /(m2)]', 0.0,true, NTotal);
  Varcreate('PlantNDemand', '[gN /(m2*d-1)]', 0.0,true, PlantNDemand);

end;

procedure TSimplePlantN.Set_GlobMod(value:TMod);

begin
inherited Set_GlobMod(Value);
  StateCreate('NStem', '[g N .m-2]', 0.0, false, NStem);
  StateCreate('NLeaf', '[g N .m-2]', 0.0, false, NLeaf);
  StateCreate('NCurd', '[g N .m-2]', 0.0, false, NGen);
  VarCreate('Nveg',  '[g N .m-2]', 0.0,   false, NVeg);
  VarCreate('rgrLeaf',  '[g.g-1]', 0.0,   false, rgrLeaf);
  VarCreate('rgrStem',  '[g.g-1]', 0.0,   false, rgrstem);
  VarCreate('rgrGen',  '[g.g-1]', 0.0,    false, rgrGen);
  StateCreate('NRoot',  '[g N .m-2]', 0.0,false,NRoot);

  VarCreate('NOptStem',  '[%N/DM]', 3.0,  false, NOptStem);
  VarCreate('NOptLeaf',  '[%N/DM]', 5.0,  false, NOptLeaf);
  VarCreate('NOptGen',  '[%N/DM]', 5.0,   false, NOptGen);

  VarCreate('NPrStem',  '[%N/DM]', 3.0,  false, NPrStem);
  VarCreate('NPrLeaf',  '[%N/DM]', 5.0,  false, NPrLeaf);
  VarCreate('NPrGen',  '[%N/DM]', 5.0,   false, NPrGen);

  Statecreate('TotalPlantNitrogen', '[gN /(m2)]', 0.0,true, NTotal);
  Varcreate('PlantNDemand', '[gN /(m2*d-1)]', 0.0,true, PlantNDemand);


end;


procedure TSimplePlantN.calcrates;

begin
  inherited CalcRates;
  NTotal.c := NLeaf.c+NStem.c+NGen.c+NRoot.c;
  RgrLeaf.v := DMLeaf.c/DMLeaf.V;
  rgrSTem.v := DMStem.c/DMStem.v;
  If DMGen.v> 0.0 then
    rgrGen.v  := DMGen.c/DMGen.v
  else RGRGen.v := 0.0;  

end;


end.
