unit SubmodRootDiff1D;

{ Variante 1D-Diffmodells: beerbt das Solo-Modell und erweitert dessen Funktio-
  nalität um die Kommunikation mit dem Strukturmodell }
interface

uses
  classes, UState, UMod, SubmodRootDiff1DSolo, dialogs;

type
  { Klassen }
  TSubmodRootDiff1DStruc = class(TSubmodRootDiff1DSolo)
  private
    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TExternV (Externe Variablen)
      ------------------------------------------------------------------------------ *)
    mRLD, VC: TExternV;
  public
    { Public-Deklarationen }
    procedure createAll; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    { Published-Deklarationen }
  end;

procedure Register;

implementation

procedure Register;
(* -----------------------------------------------------------------------------
  Prozedur wird für Komponenten benötigt: Registrierung der Komponenten auf einer
  Palette.
  ------------------------------------------------------------------------------ *)
begin
  RegisterComponents('MichasMod', [TSubmodRootDiff1DStruc]);
end; // End procedure Register

{ TSubmodRootDiff1D }

procedure TSubmodRootDiff1DStruc.CalcRates;
begin
  if iniMethod.Option = 'submodstruct' then
  begin
    RLD_mean.V := mRLD.V;
    VarKoeff_RLD.V := VC.V;
    num_Roots.V := RLD_mean.V * dimensionX.V * dimensionY.V;
    if integrationMethod.Option = 'analytic' then
    begin
      calcVar_Analyt;
      self.get_lognorm_ZV;
    end;
  end;
  inherited;

end;

procedure TSubmodRootDiff1DStruc.createAll;
begin
  inherited;
  ExternVCreate('mRLD', '[cm/cm^3]', StateField, mRLD);
  ExternVCreate('VC', '[%]', StateField, VC);
end;

procedure TSubmodRootDiff1DStruc.Init(var GlobMod: TMod);
(* -----------------------------------------------------------------------------
  Es wird davon ausgegangen, dass in jedem Fall ein Strukturmodell vorhanden ist.
  ------------------------------------------------------------------------------ *)
begin
  inherited;
  if iniMethod.Option <> 'submodstruct' then
  begin
    { Wenn mWLD und VC als Parameter eingelesen eingelesen werden, dann müssen die
      entsprechenden Variablen gesetzt werden: }
    RLD_mean.V := mRLD.V;
    VarKoeff_RLD.V := VC.V;
    { Wenn kein 2D-Modell vorhanden, dann muss noch die Anzahl der Wurzeln im Be-
      obachtungsfenster bestimmt werden. }
    if (My2DDiffModel = nil) then
      num_Roots.V := RLD_mean.V * dimensionX.V * dimensionY.V;
  end;
  { Wenn kein 2D-Modell vorhanden, dann kümmert sich das 1D-Modell um eine Ausgabe
    in das Tabellenobjekt, das die WAP-Querschnitte darstellt, ansonsten übernimmt
    dies das 2D-Submodell (Ausnahme: falls Parameter vom Strukturmodell übergeben
    werden und es sich nicht um eine zufällige oder regelmäßige Verteilung handelt,
    macht eine Ausgabe keinen Sinn, da es zu schwierig/willkürlich ist exakte
    Wurzelpos. zu berechnen }
  if (My2DDiffModel = nil) and (iniMethod.Option <> 'submodstruct') and
    (RootDistribution.Option = 'lognormal') then
  begin
    fillChartRootDistr;
  end;
  { Keine dynamische Verbindung zwischen 1D-Diffmodell und Strukturmodell in den
    Verteilungsvarianten regular oder random }
  if (iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option <> 'lognormal') then
  begin
    RootDistribution.Option := 'lognormal';
    showMessage
      ('Strukturmodell setzt Einstellung lognormal voraus.Wurde umgestellt.');
  end;

end;

procedure TSubmodRootDiff1DStruc.Integrate;
begin
  inherited;
end;

end.
