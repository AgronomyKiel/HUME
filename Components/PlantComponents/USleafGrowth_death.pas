unit USleafGrowth_Death;

interface

uses
 UState, Umod, IniFiles, UExternV, USimplePlant, USLeafGrowth;

type

TSLeafGrowthDeath = class(TSLeafGrowth)
private

protected

public


  DMsenLeaf : TExternV;
  DMabortedLeaf : TExternV;

Constructor create(SectionName : String;
                        var GlobMod : Tmod;
                        Inifile     : TIniFile); virtual;


procedure Init(var GlobMod:Tmod); override;
procedure CalcRates; override;
procedure Integrate; override;


published

end;

implementation

constructor TSLeafGrowthDeath.create(SectionName:  String;
                        var GlobMod : Tmod;
                        Inifile     : TIniFile);


begin
  inherited create(SectionName, GlobMod, Inifile);
  ExternVCreate('DMSenLeaf','[g/m2]', r,  DMsenLeaf);
  ExternVCreate('DMabortedLeaf','[g/m2]', r,  DMabortedLeaf);

end;

procedure TSLeafGrowthDeath.Init(var GlobMod:Tmod);

begin
  inherited Init(globMod);

end;

procedure TSLeafGrowthDeath.CalcRates;

var
  SumSenLeaves,
  SumAbLeaves : real;

begin
  inherited calcrates;
  SumSenLeaves := 0.0;
  SumAbLeaves  := 0.0;
end;


procedure TSLeafGrowthDeath.Integrate;

begin
end;

end.
