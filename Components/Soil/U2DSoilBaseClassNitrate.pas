unit U2DSoilBaseClassNitrate;

 {$J+}
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, math,  VCLTee.TeeProcs, VCLTee.TeEngine,
  VCLTee.Chart, VCLTee.Series,   AdvGrid,
  UMod, UState, Diffko, SubmodRootStructureNew, URootObject, URootUptakeFunctions,
  U2DSoilBaseClasses, MathImge;

type

  /// <summary> Declaration of class TSubmodRootDiff. Class based on base class for derived diffusion models
  /// implements further details for nitrate budget but without explicit formulation for
  ///  nitrate transport which are defined in derived classes
  /// </summary>
  TSubmodRootBaseNitrate = class(TSubmodRootBase)
  private

    /// <summary>Protected declarations, also accessible by derived classes</summary>
  protected



  public

    procedure createAll; override;

    // procedure Init(var GlobModReferenz: TMod); override;
    procedure Init(var GlobMod: TMod); override;

  end; { Ende Deklaration TSubmodRootDiff }

implementation

/// <summary>Implementierung TSubmodRootDiff</summary>
/// <summary>
/// Creates and initializes state variables, variables and parameters. The first
/// parameter of the function call passes a string identical to the identifier and
/// can be searched for. The second parameter contains a string indicating the
/// unit used ([-] for dimensionless parameters, etc.). The third parameter is the
/// actual floating-point value. For an explanation of the identifiers, see the
/// declaration.
/// </summary>
procedure TSubmodRootBaseNitrate.createAll;
begin
  inherited createAll;

end; // End TSubmodRootDiff.CreateAll



procedure TSubmodRootBaseNitrate.Init(var GlobMod: TMod);

var
  DimXMiddle, // Dimension der mittigen Fläche in x-Richtung [cm]
  DimYMiddle // Dimension der mittigen Fläche in y-Richtung [cm]
    : double;
  i: integer;

begin
  inherited;
  // Ausgabe von XY-Koord. bei statischem Modell
end;



end.
