/// <summary>
/// Unit with the solo variant of the 1D diffusion model: does not expect a structure model
/// </summary>

unit SubmodRootDiff1DSolo;

interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  UMod, UState, Math, USubModRoot2DDiffNitrate, U2DSoilBaseClasses,
  U2DSoilBaseClassNitrate,
  URootObject, URootUptakeFunctions, get_mom;

type

  // Classes

  /// <summary>
  /// Class for the solo variant of the 1D diffusion model
  /// </summary>
  TSubmodRootDiff1DSolo = class(TBaseSubmodRootDiffNitrate)

  private
    { Private declarations }

    /// <summary>
    /// Initial N amount
    /// </summary>
    NAmountInit: double;

    procedure InitRootObjects;

    /// <summary>
    /// Calculate the soil N amount for a given distribution
    /// </summary>
    procedure calcN_AmountSoilEquil;
  protected
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TPar (Parameter)
      Problem: Zuweisung der Variablen in diese Gruppe korrekt?
      ------------------------------------------------------------------------------ *)
    /// <summary>
    /// Number of classes for class-specific uptake calculation
    /// </summary>
    number_classes: TPar;


    /// <summary>
    /// Coefficient of variation of the mRLD [%]
    /// </summary>
    /// <remarks>
    /// Note: The coefficient of variation is only an input parameter in the Voronoi
    /// model, because only there can THESE aggregated values (area or RLD distribution)
    /// be processed.
    /// The 2D model depends on the XY coordinates of the WAP.
    /// The Rappolt model in the current implementation works with observed frequencies
    /// and NOT with theoretical distribution functions of the shortest distances
    /// (diffusion paths).
    /// </remarks>
    ParCV: TPar;

    (* -----------------------------------------------------------------------------
      Member HUME base class TVar (variables) Issue: units correct?
      ------------------------------------------------------------------------------ *)
    /// <summary>
    /// Mean area [cm^2]
    /// </summary>
    Area_mean: TVar; { Mean area [cm^2] }

    /// <summary>
    /// Coefficient of variation of the mean area [%]
    /// </summary>
    VC_Area: TVar; { Coefficient of variation of the mean area [%] }

    /// <summary>
    /// Standard deviation of the area [cm^2]
    /// </summary>
    StdAbw_Area: TVar; { Standard deviation of the area [cm^2] }

    /// summary>
    /// Log-transformed mean root length density in a layer [cm/cm^3]
    /// </summary>
    Log_RLD_mean: TVar;

    /// <summary>
    /// Log-transformed mean root length density in a layer [cm/cm^3]
    /// </summary>

    /// <summary>
    /// Log-transformed standard deviation of the root length density [cm/cm^3]
    /// </summary>
    Log_StdDef_RLD: TVar;

    /// <summary>
    /// Coefficient of variation of the mean RLD [%]
    /// </summary>
    VarKoeff_RLD: TVar;

    /// <summary>
    /// Standard deviation of the root length density [cm/cm^3]
    /// </summary>
    StdDev_RLD: TVar;

    /// <summary>
    /// Variance of the mean root length density [cm/cm^3]
    /// </summary>
    VarRLD: TVar;

    /// <summary>
    /// V/M ratio
    /// </summary>
    VMratio: TVar;

    /// <summary>
    /// Mean area of the Voronoi polygons [cm^2]
    /// Issue: what is it needed for?
    /// </summary>
    AvArea: TVar;

    /// <summary>
    /// Standard deviation of Mittl_Flaeche [cm^2]
    /// </summary>
    StdDevArea: TVar;

    /// <summary>
    /// Water amount in the soil layer under consideration [l]
    /// </summary>
    Amount_H20: TVar;

    /// <summary>
    /// Mean area [cm^2]
    /// </summary>
    Par_AreaMean: TVar;

    /// <summary>
    /// Coefficient of variation of mean area [%]
    /// </summary>
    Par_AreaVC: TVar;

    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen)
      ------------------------------------------------------------------------------ *)
    /// <summary>
    /// Fractional nitrogen uptake [-] when using the analytical solution according to Tinker, Nye Eq.10.28
    /// </summary>
    NAmountShare: TState;

    /// <summary>
    /// Fractional nitrogen uptake [-] when using the numerical solution
    /// </summary>
    NAmountShareNum: TState;

    /// <summary>
    /// The solo 1D model has an additional state variable for comparing the calculation with the analytical and numerical solution
    /// </summary>
    N_AmountSoilNum: TState;

    /// <summary>
    /// Specify the assumed distribution of the WAP, specific to the 1D and 2D model, because the 1D model
    /// additionally distinguishes between lognormal and normal distributions
    /// </summary>
    RootDistribution: TOption;

    /// <summary>
    /// Switch for calculations with static N amount and with dynamically changing N amount. When changing dynamically, only a time step based calculation can be used. With the analytical solution this means that a fractional calculation actually no longer makes sense. Solution: replace variable Time with Timestep and multiply the fractional uptake in the time step by the currently available N amount.
    /// </summary>

    StatN_AmountSoil: TOption;

  public
    { Public declarations }
    procedure createAll; override;
    // procedure AddDataValueToDataSeries; override;
    procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    { Published declarations }
end; // End of class declaration TSubmodRootDiff1DSolo

procedure Register;

implementation



{ TSubmodRootDiff1DSolo }


/// <summary>
/// Create and initialize state variables, variables, and parameters.
/// </summary>

procedure TSubmodRootDiff1DSolo.createAll;
begin
  inherited;
  // Create and initialize TVar
  VarCreate('Area_mean', '[cm^2]', 0, false, Area_mean,
    'Mean area [cm^2]');
  VarCreate('VarKoeff_Area', '[%]', 0, false, VC_Area,
    'Coefficient of variation of the mean area [%]');
  VarCreate('StdAbw_Area', '[cm^2]', 0, false, StdAbw_Area,
    'Standard deviation of the area [cm^2]');
  VarCreate('Log_RLD_mean', '[cm/cm^3]', 0, false, Log_RLD_mean,
    'Log-transformed mean root length density in a layer [cm/cm^3]');
  VarCreate('VarKoeff_RLD', '[%]', 0, false, VarKoeff_RLD,
    'Coefficient of variation of the mean RLD [%]');
  VarCreate('Log_StdAbw_RLD', '[cm/cm^3]', 0, false, Log_StdDef_RLD,
    'Log-transformed standard deviation of the root length density [cm/cm^3]');
  VarCreate('StdAbw_RLD', '[cm/cm^3]', 0, false, StdDev_RLD,
    'Standard deviation of the root length density [cm/cm^3]');
  VarCreate('Varianz', '[%]', 0, false, VarRLD,
    'Variance of the mean root length density [cm/cm^3]');
  VarCreate('VM', '[-]', 0, false, VMratio, 'V/M ratio');
  VarCreate('Mittl_Flaeche', '[cm^2]', 0, false, AvArea,
    'Mean area of the Voronoi polygons [cm^2]; Issue: what is it needed for?');
  VarCreate('Par_AreaMean', '[cm^2]', 5, false, Par_AreaMean,
    'Mean area [cm^2]');
  VarCreate('Par_AreaVC', '[%]', 100, false, Par_AreaVC,
    'Coefficient of variation of mean area [%]');
  VarCreate('Amount_H20', '[l]', 0, false, Amount_H20,
    'Water amount in the soil layer under consideration [l]');

  // Create and initialize TPar
  ParCreate('number_classes', '[-]', 10, number_classes,
    'Number of classes for class-specific uptake calculation');
  // 10 classes by default
  ParCreate('ParVC', '[%]', 0, ParCV,
    'Coefficient of variation of the mRLD [%]');
  // Create and initialize TState
  StateCreate('N_MengeAnteilAn', '[]', 0, false, NAmountShare,
    'Fractional nitrogen uptake [-] when using the analytical solution according to Tinker, Nye Eq.10.28');
  StateCreate('N_MengeAnteilNum', '[]', 0, false, NAmountShareNum,
    'Fractional nitrogen uptake [-] when using the numerical solution');
  StateCreate('N_AmountSoilNum', '[kg N/ha]', 0, false, N_AmountSoilNum,
    'The solo 1D model has an additional state variable for comparing the calculation with the analytical and numerical solution');
  // Erzeugen und initialisieren von TOption

  OptCreate('StatN_AmountSoil', 'static', StatN_AmountSoil,
    'Switch for calculations with static N amount and with dynamically changing N amount. When changing dynamically, only a time step based calculation can be used. With the analytical solution this means that a fractional calculation actually no longer makes sense. Solution: replace variable Time with Timestep and multiply the fractional uptake in the time step by the currently available N amount.');
  StatN_AmountSoil.OptionList.Add('static');
  StatN_AmountSoil.OptionList.Add('dynamic');

  { Define the assumed distribution of the WAP }
  OptCreate('RootDistribution', 'Random', RootDistribution,
    'Specify the assumed distribution of the WAP, specific to the 1D and 2D model, because the 1D model additionally distinguishes between lognormal and normal distributions');
  RootDistribution.OptionList.Add('Regular');
  { If the input comes from the structure model, a lognormal distribution is
    assumed; this really should still be tested. }
  RootDistribution.OptionList.Add('lognormal');
  { Specify whether the statistics RLD and VC should be derived from Voronoi
    polygons or from the occupancy of the grid cells. }
end;



(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiffD
  DESCRIPTION: Perform various initializations. Caveat: init is entered several
  times, therefore AddDataValueToDataSeries is used now.
  ------------------------------------------------------------------------------ *)
procedure TSubmodRootDiff1DSolo.Init(var GlobMod: TMod);

var
  i: integer;
  ARoot: TRootObject;

begin
  inherited;

  // the 1D-solo object calculates with pre defined classes of RLD
  // either 10 or 20, which are represented by a single root object
  // therefore previously initiated roots have to be removed from
  // the rootlist
  RasterData.RootList.clear;

  // create a list of TRootObjects within TRasterData
  for i := 0 to trunc(self.number_classes.v) - 1 do
  begin
    ARoot := TRootObject.create;
    self.RasterData.RootList.AddObject(IntToStr(i), ARoot);
  end;

  if iniMethod.Option = 'inppar' then
  begin
    { When mWLD and VC are read in as parameters, the corresponding variables must be
      set. VarKoeff_RLD is adjusted depending on the distribution function. }

    VarKoeff_RLD.v := ParCV.v;
    VMratio.V := VarRLD.V / RLD_mean.V;

    // Also applies to statistics of the area distribution
    Area_mean.v := Par_AreaMean.v;
    VC_Area.v := Par_AreaVC.v;

    // if the option regular root distribution is choosen
    // the coefficient of variation is 0
    // issue: check if the method init Root Objects handles this
    if RootDistribution.Option = 'regular' then
      VarKoeff_RLD.v := 0;
  end;
  // initialise the root objects
  InitRootObjects;
end;

procedure TSubmodRootDiff1DSolo.CalcRates;

(* -----------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Calls the flow control of the submodel for rate calculation.
  ------------------------------------------------------------------------------ *)
var
  ARoot : TRootObject;
  i : integer;
  De, Db, MaxNInflux  : real;

begin
  { The implementation was outsourced so that when using the analytical solution the
    rate equation calculation can easily be disabled (switch in createAll). Rate
    calculation should take place here only when using the numerical solution or
    when both calculation methods are executed }
//  inherited CalcRates;

  For i := 0 to trunc(number_classes.v - 1) do 
  begin
     
    ARoot := TRootObject(RasterData.RootList.Objects[i]);
    MaxNInflux := ARoot.MaxNitrateInflux;
    ARoot.Ninflux := min(Imax.v, MaxNInflux);
    // calculate the fractional uptake according to Tinker, Nye Eq. 10.28

  end;


end; // End  TSubmodRootDiff1DSolo.CalcRates

procedure TSubmodRootDiff1DSolo.Integrate;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Solve the differential equations.
  ------------------------------------------------------------------------------ *)
begin
end; // End TSubmodRootDiff1DSolo.Integrate




procedure TSubmodRootDiff1DSolo.InitRootObjects;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Populate the WLD array
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  Radius: real;
  Area_EqualDistrib, sumRLDMoments: double;
  ARoot: TRootObject;
  RLD_moments: moment_arr_type;

begin

  if RootDistribution.Option = 'regular' then
    for i := 0 to Z_d_Momente-1 do
      RLD_moments[i] := RLD_mean.v
  else
  begin
    get_par_moments(RLD_mean.v, self.VarKoeff_RLD.v, z_moments, RLD_moments);
    sumRLDMoments := 0;
    for i := low(RLD_moments) to high(RLD_moments) do
      sumRLDMoments := sumRLDMoments + RLD_moments[i];
    for i := 0 to Z_d_Momente-1 do
      RLD_moments[i] := RLD_moments[i] * RLD_mean.v / sumRLDMoments * z_d_Momente;

  end;

  for i := 0 to trunc(number_classes.v - 1) do
    begin
      ARoot := TRootObject(RasterData.RootList.Objects[i]);

      // calculate 10 "moments" of the log-normal distribution function for root length density
      ARoot.RLD := RLD_moments[i];
      ARoot.HalfDistance := 1 / sqrt(ARoot.RLD);
      ARoot.area := pi * sqr(ARoot.HalfDistance);
      ARoot.nroot := i+1;
      // the amount of water is initalised with the average water content
      // times the area of the root object. It represents
      ARoot.WAmount := ARoot.area * theta.v / Z_d_Momente;
      ARoot.NAmount := self.IniSoilNitrate.v / Z_d_Momente;
      ARoot.theta   := theta.v;
      ARoot.Cl_mean := ARoot.NAmount / ARoot.WAmount;
    end;
  end;


procedure TSubmodRootDiff1DSolo.calcN_AmountSoilEquil;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Calculate the N amount in the soil according to equation 3.6.43 of
  the Kage dissertation
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  Db, cl_avClass, classBorder: double;
begin
  cl_av.V := 0;
  Db := De.V * theta.V;
  for i := 0 to trunc(number_classes.V - 1) do
  begin
    // The radius (class boundary) must be calculated from the RLD:
//    classBorder := sqrt(1 / (ZV_Array_lognorm[i] * Pi));
    cl_avClass := Clmin.V - (Min_s.V * (sqr(classBorder) - sqr(RootRadius.V)) /
      (4 * Db)) + (Min_s.V * sqr(classBorder) / (2 * Db) *
      ln(classBorder / RootRadius.V));
    // Weighting
    cl_avClass := cl_avClass;
    cl_av.V := cl_av.V + cl_avClass;
  end;
  N_AmountSoil.V := Mg_func(Depth.V, theta.V, cl_av.V);
end;


procedure Register;
(* -----------------------------------------------------------------------------
  Prozedur wird für Komponenten benötigt: Registrierung der Komponenten auf einer
  Palette.
  ------------------------------------------------------------------------------ *)
begin
  RegisterComponents('Soil2D', [TSubmodRootDiff1DSolo]);
end; // End procedure Register


end.
