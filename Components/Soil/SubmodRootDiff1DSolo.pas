unit SubmodRootDiff1DSolo;

{ Solo variant of the 1D diffusion model: does not expect a structure model }
interface

uses
  Windows, Messages, SysUtils, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, vcl.Dialogs,
  UMod, SubmodRootDiff, UState, Math, SubmodDiff2DRoots, USubModRoot2DDiffNitrate, U2DSoilBaseClasses;

const
  { The following are the Phi(u) values of the standard normal distribution:
    Example for interpretation:
    z_5 value [1.64486] denotes the u value that is exceeded by 5% of all values.
    That is, 5% of all values deviate by at least 1.64486 from the mean.
    Because of the symmetry of the standard normal distribution, for -z_5: 5% of all
    values deviate by -1.64486 from the mean. z_x values correspond to the Phi(u)
    values.
    Issue: In my opinion these are the Phi(u) values that can later be used to
    calculate the CLASS MEANS of the RLD density distribution.
    Correct??? (Class boundaries would then be 0.1, 0.2 ... 1) }
  { Original values commented out here
    z_5  = 1.64486;
    z_15 = 1.03644;
    z_25 = 0.674492;
    z_35 = 0.385322;
    z_45 = 0.125663; }
  { Values calculated with Excel: }
  z_5 = 1.6448534756699800;
  z_15 = 1.0364334736256900;
  z_25 = 0.6744895256679870;
  z_35 = 0.3853206036265890;
  z_45 = 0.1256612463220620;

  { Excel values for 20 classes: }
  z_475 = 0.062706777943;
  z_425 = 0.189118426273;
  z_375 = 0.318639363964;
  z_325 = 0.453762190170;
  z_275 = 0.597760126042;
  z_225 = 0.755415026360;
  z_175 = 0.934589291073;
  z_125 = 1.150349380376;
  z_075 = 1.439531470938;
  z_025 = 1.959963984540;

type
  // Type declarations
  Pdouble = ^double; // Pointer type to double, for use in lists

  // Arrays
  { Array type for state-variable arrays. Required for the numerical solution.
    Each SRP (or a property of the SRP) is treated here as an instance of TState.
    The array contains values for all SRP of the simulated soil layer.
    Issue: Had to be defined from the outset to the maximum allowed number of roots,
    because TState instances must be created in createAll and at that point no roots
    have been read in yet. Issue 2: It would probably make more sense to declare only
    the aggregated values (mRLD and VC) as TState (as before), because the individual
    root cylinders have a whole range of properties as TSRP. }
  // TSRPStateArray  = array [0..max_num_roots-1] of TState;

  // Classes

  TSubmodRootDiff1DSolo = class(TSubmodRoot2DDiffNitrate)
  private
    { Private declarations }
    fMy2DDiffModel: TSubmodDiff2DRoots;
    // FIELDS
    // a) required for analytical solution
    WLD_Array: Array of double;
    { One-dimensional arrays that map the quartiles of a normal or lognormal
      distribution to the corresponding RANDOM VARIABLES.
      A classification into 10 classes was assumed, i.e. the array requires 10
      entries. The first field of the array stores the random variable belonging to
      -z_5, the last field stores the random variable belonging to z_5. Storage of the
      random variables at the "class midpoint", see above. }
    // Array for normal distribution
    ZV_Array_normvert,
    // Array for lognormal distribution
    ZV_Array_lognorm,
    // Array for standard normal distribution
    ZV_Array_Stdnorm,
    // Array for weighting (needed when calculating from the distribution of areas)
    weightArr: Array of real;
    // b) required for numerical solution
    { The following lists contain information or specific calculated values for each
      SRP of the soil layer under consideration. }
    { Declaration of a list that stores the XY coordinates and the root length
      densities for each root. Currently unused, therefore commented out }
    // WLD_List : TList;
    { List for current average nitrate concentrations in the SRP. Each list element
      stores the average nitrate concentration of a specific SRP. }
    Cl_mean_List: TList;
    { List for (water) volumes for all SRP (initially constant). Issue: must be
      adapted when implementing a dynamic model. }
    VolH20_EWZ_List: TList;
    { List storing the initial N amounts in the SRP }
    Init_NAmountEWZList: TList; // maybe I do not need this
    { Initial N amount: }
    NAmountInit: double;
    { Array/list storing the absorbed N amounts (fluxes) into/out of the individual
      root cylinders in the current time step.
      Issue: A dynamic array or list is probably not possible here because we want to
      work with TState instances, which can then be INTEGRATED AUTOMATICALLY by the
      HUME environment. However, TState instances must be created at the beginning. }
    // NAmount_UPEWZArray : TEWZStateArray;
    // NAmount_UPEWZList : TList;

    // METHODS
    // a) Methods for calculation using the analytical solution
    procedure createAnalytic;
    procedure Integrate_Analyt;
    // Helper methods
    function Kolmogorov_Smirnov: boolean;

    procedure calcRootArea;
    procedure copyPosArrFrom2DDif;
    procedure fillWLDArr;
    // b) for numerical solution
    procedure createNumeric;
    // Method for calculating using the rate equation (numerical solution)
    procedure Calc_numeric;
    procedure transform_Clmin;
    procedure calc_Amount_H20;
    function calc_num_EWZ: real;
    function calc_num_class: real;
    // c) for both approaches
    procedure init_ReadFromFile; override;
    { Method for model comparison: calculate the soil N amount for a given distribution
      and mineralisation rate }
    procedure calcN_AmountSoilEquil;
  protected
    { Protected declarations }
    { Switch used to check whether initialization has already been performed and then
      branch accordingly }
    initial_1D: boolean;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TPar (Parameter)
      Problem: Zuweisung der Variablen in diese Gruppe korrekt?
      ------------------------------------------------------------------------------ *)
    number_classes, { Number of classes to be used for calculating a class-specific
      uptake }
    Log_StdAbw_Area, { Log-transformed standard deviation of the area [cm^2] }
    Log_Area_mean, { Log-transformed mean area in
      a layer [cm^2] }
    ParVC { Coefficient of variation of mRLD [%] }
    { Note: The coefficient of variation is only an input parameter in the Voronoi
      model, because only there can THESE aggregated values (area or RLD distribution)
      be processed.
      The 2D model depends on the XY coordinates of the WAP.
      The Rappolt model in the current implementation works with observed frequencies
      and NOT with theoretical distribution functions of the shortest distances
      (diffusion paths). }
      : TPar;

    (* -----------------------------------------------------------------------------
      Member HUME base class TVar (variables) Issue: units correct?
      ------------------------------------------------------------------------------ *)
    Area_mean, { Mean area [cm^2] }
    VarKoeff_Area, { Coefficient of variation of the mean area [%] }
    StdAbw_Area, { Standard deviation of the area [cm^2] }
    Log_RLD_mean, { Log-transformed mean root length density in
      a layer [cm/cm^3] }
    Log_StdAbw_RLD, { Log-transformed standard deviation of the root
      length density [cm/cm^3] }
    VarKoeff_RLD, { Coefficient of variation of the mean RLD [%] }
    StdAbw_RLD, { Standard deviation of the root length density [cm/cm^3] }

    Varianz, { Variance of the mean root length density [cm/cm^3] }
    VM, { V/M ratio }
    Mittl_Flaeche, { Mean area of the Voronoi polygons [cm^2]
      Issue: what is it needed for? }
    StdAbw_Flaeche, { Standard deviation of Mittl_Flaeche [cm^2] }
    // For numerical solution:
    ClminTransf, { Minimum soil solution concentration [kg N/cm*H20] }
    ClminTransf_ha, { Minimum soil solution concentration [kg N/ha] }
    Amount_H20, { Water amount in the soil layer under consideration [l] }
    Par_AreaMean, { Mean area [cm^2] }
    Par_AreaVC { Coefficient of variation of mean area [%] }
      : TVar;

    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen)
      ------------------------------------------------------------------------------ *)
    N_MengeAnteilAn, { Fractional nitrogen uptake [-] when using
      the analytical solution according to Tinker, Nye Eq.10.28 }
    N_MengeAnteilNum, { Fractional nitrogen uptake [-] when using
      the numerical solution }
    N_AmountSoilNum { The solo 1D model has an additional state variable
      for comparing the calculation with the analytical and
      numerical solution }

      : TState;
    (* -----------------------------------------------------------------------------
      Member HUME-Basisklasse TState (Zustandsvariablen)
      ------------------------------------------------------------------------------ *)

    OperatingMode, { How the model should run: with or without the 2D model,
      important for the output in the form }
    calcMethodZV, { Selection of calculation method:
      a) with constant cumulative frequency interval
      b) with constant class interval. }
    integrationMethod, { Choice of numerical or analytical calculation }
    RootDistribution, { Specify the assumed distribution of the WAP,
      specific to the 1D and 2D model, because the 1D model
      additionally distinguishes between lognormal and normal
      distributions }
    CalcMethRLD_VC, { Different options for calculating the statistics of the
      root distribution }
    CalcMethQuant, { Different methods for calculating the class mean values
      of the RLD in the associated quantiles. }
    StatN_AmountSoil, { Switch for calculations with static N amount and with
      dynamically changing N amount
      When changing dynamically, only a time step based
      calculation can be used. With the analytical solution
      this means that a fractional calculation actually no
      longer makes sense. Solution: replace variable Time with
      Timestep and multiply the fractional uptake in the time
      step by the currently available N amount. }
    compareMode { Switch used to specify whether the 1D model should be
      run for comparison with the 2D model
      = setting 'yes':
      Only the N amount in the soil at steady state
      Influx = mineralisation is calculated; root uptake is
      not calculated (see Kage dissertation, equation 3.6.43)
      or not
      = setting 'no':
      Solution according to Tinker/Nye (Eq. 10.28; calculation of
      root uptake as well as the N amounts in the soil from the
      initial N amount and root uptake }

    // Compare2DModel
    { Switch for comparison with the 2D model: There, to produce the steady
      state, the absorbed amount is added back to the cells in each time step.
      When comparing the models this must also happen in the 1D model. (Only the
      solo model needs this, because in the full model such a comparison does not
      play a role.) Switch is currently not used }
      : TOption;

    procedure calcVar_Analyt;
    { Helper methods for the analytical solution to calculate the class mean values
      of the root length density when dividing the normal or lognormal distribution
      curve into 10 classes, i.e. determine the u values corresponding to the
      predefined quartiles }
    procedure get_normvert_ZV;
    procedure get_lognorm_ZV;
    procedure get_lognorm_ZV_Area;
  public
    { Public declarations }
    procedure createAll; override;
    procedure AddDataValueToDataSeries; override;
    // procedure Init(var GlobMod: TMod); override;
    procedure CalcRates; override;
    procedure Integrate; override;

  published
    { Published declarations }
    property My2DDiffModel: TSubmodDiff2DRoots read fMy2DDiffModel
      write fMy2DDiffModel;
  end; // End of class declaration TSubmodRootDiff1DSolo

procedure Register;

implementation

procedure Register;
(* -----------------------------------------------------------------------------
  Procedure needed for components: registers the components on a palette.
  ------------------------------------------------------------------------------ *)
begin
  RegisterComponents('MichasMod', [TSubmodRootDiff1DSolo]);
end; // End procedure Register

{ TSubmodRootDiff1DSolo }

procedure TSubmodRootDiff1DSolo.createAll;
(* -----------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Create and initialize state variables, variables, and parameters.
  The first parameter of the function call passes a string that is identical to the
  identifier and can therefore be searched for.
  The second parameter contains a string indicating the unit used ([-] for
  dimensionless parameters).
  The third parameter is the actual (floating point) value.
  See declaration for explanation of the identifiers.
  ------------------------------------------------------------------------------ *)
begin
  inherited;
  // Create the lists
  Cl_mean_List := TList.Create;
  VolH20_EWZ_List := TList.Create;
  Init_NAmountEWZList := TList.Create;
  initial_1D := false;
  // Create and initialize TVar
  VarCreate('Area_mean', '[cm^2]', 0, false, Area_mean);
  VarCreate('VarKoeff_Area', '[%]', 0, false, VarKoeff_Area);
  VarCreate('StdAbw_Area', '[cm^2]', 0, false, StdAbw_Area);
  VarCreate('Log_RLD_mean', '[cm/cm^3]', 0, false, Log_RLD_mean);
  VarCreate('VarKoeff_RLD', '[%]', 0, false, VarKoeff_RLD);
  VarCreate('Log_StdAbw_RLD', '[cm/cm^3]', 0, false, Log_StdAbw_RLD);
  VarCreate('StdAbw_RLD', '[cm/cm^3]', 0, false, StdAbw_RLD);
  VarCreate('Varianz', '[%]', 0, false, Varianz);
  VarCreate('VM', '[-]', 0, false, VM);
  VarCreate('Mittl_Flaeche', '[cm^2]', 0, false, Mittl_Flaeche);
  VarCreate('Par_AreaMean', '[cm^2]', 5, false, Par_AreaMean);
  VarCreate('Par_AreaVC', '[%]', 100, false, Par_AreaVC);
  // Create and initialize TPar
  ParCreate('number_classes', '[-]', 10, number_classes);
  // 10 classes by default
  ParCreate('Log_Area_mean', '[cm^2]', 0, Log_Area_mean);
  ParCreate('Log_StdAbw_Area', '[cm^2]', 0, Log_StdAbw_Area);
  ParCreate('ParVC', '[%]', 0, ParVC);
  // Create and initialize TState
  StateCreate('N_MengeAnteilAn', '[]', 0, false, N_MengeAnteilAn);
  StateCreate('N_MengeAnteilNum', '[]', 0, false, N_MengeAnteilNum);
  StateCreate('N_AmountSoilNum', '[kg N/ha]', 0, false, N_AmountSoilNum);
  // Erzeugen und initialisieren von TOption

  OptCreate('CalcMethQuant', 'fromarea', CalcMethQuant);
  CalcMethQuant.OptionList.Add('fromarea');
  CalcMethQuant.OptionList.Add('fromRLD');
  OptCreate('StatN_AmountSoil', 'static', StatN_AmountSoil);
  StatN_AmountSoil.OptionList.Add('static');
  StatN_AmountSoil.OptionList.Add('dynamic');
  OptCreate('OperatingMode', 'without2DModel', OperatingMode);
  OperatingMode.OptionList.Add('without2DModel');
  OperatingMode.OptionList.Add('with2DModel');
  OptCreate('integrationMethod', 'analytic', integrationMethod);
  integrationMethod.OptionList.Add('analytic');
  integrationMethod.OptionList.Add('numeric');
  { For comparing analytical and numerical solutions there is also an option that
    performs both calculations. }
  integrationMethod.OptionList.Add('both');
  { Define the assumed distribution of the WAP }
  OptCreate('RootDistribution', 'Random', RootDistribution);
  RootDistribution.OptionList.Add('Regular');
  RootDistribution.OptionList.Add('normal');
  { If the input comes from the structure model, a lognormal distribution is
    assumed; this really should still be tested. }
  RootDistribution.OptionList.Add('lognormal');
  { Specify whether the statistics RLD and VC should be derived from Voronoi
    polygons or from the occupancy of the grid cells. }
  OptCreate('CalcMethRLD_VC', 'fromGrid', CalcMethRLD_VC);
  CalcMethRLD_VC.OptionList.Add('voronoi');
  CalcMethRLD_VC.OptionList.Add('fromGrid');

  OptCreate('compareMode', 'no', compareMode);
  compareMode.OptionList.Add('no');
  compareMode.OptionList.Add('yes');
  OptCreate('calcMethodZV', 'equalSumfreq', calcMethodZV);
  calcMethodZV.OptionList.Add('equalSumfreq');
  calcMethodZV.OptionList.Add('equalInt');

  { OptCreate('Compare2DModel', 'no', Compare2DModel);
    Compare2DModel.OptionList.Add('yes');
    Compare2DModel.OptionList.Add('no'); }
  { Issue: It should still be differentiated which objects are used ONLY in the
    analytical solution, outsourcing them to a procedure so that switching between
    the calculation methods is clearer. Mostly a cosmetic issue. }
  if integrationMethod.Option = 'numeric' then
  // Case distinction: numerical calculation
  begin
    { }
    createNumeric;
  end
  else // analytical solution
  begin
    createAnalytic;
  end;
end; // SubmodRootDiff1D.createAll

procedure TSubmodRootDiff1DSolo.createAnalytic;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Method for the Hume instances that are only needed when using the
  analytical solution; this allows easy switching between the two calculation
  variants.
  ------------------------------------------------------------------------------ *)
begin

end; // End TSubmodRootDiff1DSolo.createAnalytic

procedure TSubmodRootDiff1DSolo.createNumeric;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Method for the Hume instances that are only needed when using the
  numerical solution; this allows easy switching between the two calculation
  variants.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  { TVar }
  VarCreate('ClminTransf', '[kg N/cm*H20]', 0, false, ClminTransf);
  VarCreate('ClminTransf_ha', '[kg N/ha]', 0, false, ClminTransf_ha);
  VarCreate('Amount_H20', '[l]', 0, false, Amount_H20);
  { Create state variables for the N amounts contained in each EWZ. See also the
    notes in method init }
  // for i:=0 to max_num_roots-1 do
  // begin
  { Issue: Can the NAmount_UPEWZArray be populated in this way??? }
  // StateCreate('NAmount_UPEWZ'+InttoStr(i),'[g]', 0, false, NAmount_UPEWZArray[i]);
  // end;
end;

procedure TSubmodRootDiff1DSolo.AddDataValueToDataSeries;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiffD
  DESCRIPTION: Perform various initializations. Caveat: init is entered several
  times, therefore AddDataValueToDataSeries is used now.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  ASRP_Light: TSRPLight; // A lightweight version of the SRP
  AVol_H20, // Pointer to the variable storing the water volumes in the SRP
  AInitNAmount, // Pointer to the variable storing the initial N amount in the SRP
  AInitNConc // Pointer to the variable storing the initial N concentration in the SRP
    : Pdouble;
begin
  inherited;
  // inherited init(GlobMod);      // init no longer used.
  // Cache the initial N amount
  NAmountInit := N_AmountSoil.V;
  // Initialize dynamic arrays:
  // a) Set length:
  setLength(ZV_Array_Stdnorm, trunc(number_classes.V));
  setLength(ZV_Array_normvert, trunc(number_classes.V));
  setLength(ZV_Array_lognorm, trunc(number_classes.V));
  setLength(weightArr, trunc(number_classes.V));
  { The array stores the quartiles of the STANDARD NORMAL DISTRIBUTION. Because of
    the symmetry of the standard normal distribution, the values to the right of the
    mean correspond to the values to the left of the mean (with a negative sign
    here). Note: the values for z_5 to z_45 correspond to the values z_55 to z_95 in
    the Excel model. }
  // when 10 classes are present
  if calcMethodZV.Option = 'equalsumfreq' then
  begin
    if number_classes.V = 10 then
    begin
      ZV_Array_Stdnorm[0] := -z_5;
      ZV_Array_Stdnorm[1] := -z_15;
      ZV_Array_Stdnorm[2] := -z_25;
      ZV_Array_Stdnorm[3] := -z_35;
      ZV_Array_Stdnorm[4] := -z_45;
      ZV_Array_Stdnorm[5] := z_5;
      ZV_Array_Stdnorm[6] := z_15;
      ZV_Array_Stdnorm[7] := z_25;
      ZV_Array_Stdnorm[8] := z_35;
      ZV_Array_Stdnorm[9] := z_45;
    end;
    // when 20 classes are present
    if number_classes.V = 20 then
    begin
      ZV_Array_Stdnorm[0] := -z_025;
      ZV_Array_Stdnorm[1] := -z_075;
      ZV_Array_Stdnorm[2] := -z_125;
      ZV_Array_Stdnorm[3] := -z_175;
      ZV_Array_Stdnorm[4] := -z_225;
      ZV_Array_Stdnorm[5] := -z_275;
      ZV_Array_Stdnorm[6] := -z_325;
      ZV_Array_Stdnorm[7] := -z_375;
      ZV_Array_Stdnorm[8] := -z_425;
      ZV_Array_Stdnorm[9] := -z_475;
      ZV_Array_Stdnorm[10] := z_025;
      ZV_Array_Stdnorm[11] := z_075;
      ZV_Array_Stdnorm[12] := z_125;
      ZV_Array_Stdnorm[13] := z_175;
      ZV_Array_Stdnorm[14] := z_225;
      ZV_Array_Stdnorm[15] := z_275;
      ZV_Array_Stdnorm[16] := z_325;
      ZV_Array_Stdnorm[17] := z_375;
      ZV_Array_Stdnorm[18] := z_425;
      ZV_Array_Stdnorm[19] := z_475;
    end;
  end;
  if self.calcMethodZV.Option = 'equalint' then
  begin
    // Implementation still missing.
  end;
  if iniMethod.Option = 'inppar' then
  begin
    { When mWLD and VC are read in as parameters, the corresponding variables must be
      set. VarKoeff_RLD is adjusted depending on the distribution function. }
    RLD_mean.V := ParMRLD.V;
    VarKoeff_RLD.V := ParVC.V;
    // Also applies to statistics of the area distribution
    Area_mean.V := Par_AreaMean.V;
    VarKoeff_Area.V := Par_AreaVC.V;

    if RootDistribution.Option = 'regular' then
      VarKoeff_RLD.V := 0;
    num_Roots.V := RLD_mean.V * dimensionX.V * dimensionY.V;
  end;
  if iniMethod.Option = 'rasterdatafile' then
  begin
    RasterData.readRasterData(RootInpDataFile.Option, seriesXY);
  end;
  if iniMethod.Option = 'xyfile' then
  begin
    RasterData.readXYfromFile(RootInpDataFileXY.Option, seriesXY);
  end;
  // Initializations independent of the imported root data
  if integrationMethod.Option = 'numeric' then // only for numerical solution
  begin
    transform_Clmin;
  end;
  // In the case of a uniform distribution the PosArr must first be calculated.
  if RootDistribution.Option = 'regular' then
  begin
    EqualDistribution;
  end;
  if RootDistribution.Option = 'random' then
  begin
    { Because the submodels have independent RasterData objects, a model comparison
      only makes sense if the 1D model obtains the PosArr from the 2D model }
    // Calculate the number of roots in the observation area from the RLD
    if self.My2DDiffModel <> nil then
    begin
      copyPosArrFrom2DDif;
    end
    else
    begin
      if iniMethod.Option = 'inppar' then
        num_Roots.V := RLD_mean.V * dimensionX.V * dimensionY.V;
      for i := 1 to trunc(num_Roots.V) do
      begin
        TRootPosition(RasterData.PosList.Objects[i]).x := random(trunc(dimensionX.V) - 2) + 2;
        TRootPosition(RasterData.PosList.Objects[i]).y := random(trunc(dimensionY.V) - 2) + 2;
      end;
    end;
    { In the random case, area data must be calculated from the coordinates }
    calcRootArea;
  end;
  { If data is read from a raster data file and NO uniform distribution was
    generated, the 1D model must perform the calculation of the SRP areas itself.
    In the uniform case the area of the SRP is calculated during the distribution. }
  if (iniMethod.Option = 'rasterdatafile') and
    (RootDistribution.Option <> 'regular') then
  begin
    calcRootArea;
  end;
  { After reading and adjusting the distribution, roots located outside the
    observation window or in the margins are removed. }
  init_ReadFromFile;
  // Ensure that WLD_arr is populated
  if ((iniMethod.Option = 'inppar') and (RootDistribution.Option = 'lognormal'))
    or ((iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option = 'lognormal')) then
  begin
    // nichts machen
  end
  else
    fillWLDArr;
  { When root data has been read in, the following initializations are performed,
    differentiated between numerical and analytical solutions. }
  // a) for the analytical solution
  if integrationMethod.Option = 'analytic' then
  begin
    calcVar_Analyt;
    if RootDistribution.Option <> 'normal' then
    { assuming a lognormal distribution, the standard case }
    begin
      { Calculate the random variables (mean RLD, class mean values) assuming a
        lognormal distribution }
      if CalcMethQuant.Option = 'fromrld' then
        get_lognorm_ZV
      else
      // Calculate the class mean values of the RLD from the area distribution
      begin
        get_lognorm_ZV_Area;
      end;
    end; // End if Lognormalverteilung
    if RootDistribution.Option = 'regular' then
    begin
    { Uniform distribution means that the half-distances between the sinks and thus
        the areas of the individual sinks are equal. The standard deviation of the
        areas is therefore 0. Only the mean root length density is required for the
        calculation. No further initialization is necessary here. }
      VarKoeff_RLD.V := 0;
    end; // End if Gleichverteilung
    if RootDistribution.Option = 'normal' then
    begin
      { Calculate the random variables (mean RLD, class mean values) assuming a
        normal distribution }
      get_normvert_ZV;
    end; // End if Normalverteilung
  end
  else
  // b) for the numerical solution
  begin
    { Creating state variables for the N amount of all EWZ.
      Issue: may not be feasible; in that case create the array with a fixed number
      of TState (see declaration of NAmount_UPEWZArray).
      The approach of creating the state variables in init is therefore currently
      commented out. }
    { for i:=0 to RasterData.NRoots-1 do
      begin
      StateCreate('NMengeEWZ'+InttoStr(i),'[g]', 0, false, NMengeEWZ);
      end; }
    { Calculate the volumetric water content of all EWZ (initially) constant over the
      runtime of the model.
      Issues: Dynamic modelling (change of water content) still pending.
      //setLength(VolH20_EWZ_Array, RasterData.NRoots-1);
      calc_Amount_H20;
      { The following line would be necessary if NAmount_UPEWZArray can be created
      dynamically. A list would probably be better than an array }
    // setLength(NAmount_UPEWZArray,RasterData.NRoots-1);
    // setLength(Init_NAmountEWZArray,RasterData.NRoots-1);
    for i := 1 to RasterData.NRoots do
    begin
      new(AVol_H20);
      new(AInitNAmount);
      new(AInitNConc);
      { Calculate the H2O volumes of the EWZ [cm3] }
      AVol_H20^ := TRootPosition(RasterData.PosList.Objects[i]).area * theta.V * SizeLayer.V;
      // Calculate the N amounts in the EWZ at the beginning (initial values)
      AInitNAmount^ := AVol_H20^ * c_start.V;
      // Uniform concentration in the EWZ at the beginning (initial values)
      AInitNConc^ := c_start.V;
      VolH20_EWZ_List.Add(AVol_H20);
      Cl_mean_List.Add(AInitNConc);
      Init_NAmountEWZList.Add(AInitNAmount);
      // NAmount_UPEWZArray[i].V:=0.0; // No uptake at the beginning yet
    end;
  end; // End if calcAnalyt=false
  { If no 2D model is available, the 1D model handles output to the table object that
    displays the WAP cross-sections; otherwise the 2D submodel takes care of this
    (exception: if parameters are read and it is neither a random nor a regular
    distribution, output makes no sense because calculating exact root positions is
    too difficult/arbitrary) }
  if (My2DDiffModel = nil) and (iniMethod.Option <> 'inppar') and
    (RootDistribution.Option = 'lognormal') then
  begin
    fillChartRootDistr;
  end;
  if (My2DDiffModel = nil) and (iniMethod.Option = 'rasterdatafile') then
    fillGridRasterData;
end; // End TSubmodRootDiff1DSolo.Init(var GlobMod: TMod)

procedure TSubmodRootDiff1DSolo.CalcRates;
(* -----------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Calls the flow control of the submodel for rate calculation.
  ------------------------------------------------------------------------------ *)
begin
  { The implementation was outsourced so that when using the analytical solution the
    rate equation calculation can easily be disabled (switch in createAll). Rate
    calculation should take place here only when using the numerical solution or
    when both calculation methods are executed }
  inherited CalcRates;
  De.V := Dl.V * 3.35 * sqr(theta.V);
  if (integrationMethod.Option = 'numeric') or
    (integrationMethod.Option = 'both') then
  begin
    { Note: inherited can be called at different positions within a method. }
    Calc_numeric;
  end;
end; // End  TSubmodRootDiff1DSolo.CalcRates

procedure TSubmodRootDiff1DSolo.Integrate;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Solve the differential equations.
  ------------------------------------------------------------------------------ *)
begin
  if StatN_AmountSoil.Option = 'static' then
  begin
    if (integrationMethod.Option = 'analytic') or
      (integrationMethod.Option = 'both') then // analytical solution
    begin
      // Calculation only makes sense if roots or parameter values are present
      if (num_Roots.V <> 0) then
        // for model comparison:
        if compareMode.Option = 'yes' then
        begin
          // do nothing
        end
        else
          Integrate_Analyt;
    end
    else // numerical solution
    begin
      { When using the numerical solution integration happens automatically (inherited) }
      inherited;
    end;
    { Calculate the N amount remaining in the soil from the fractionally absorbed N
      amount: }
    if integrationMethod.Option = 'both' then
    begin
      if compareMode.Option = 'yes' then
      begin
        calcN_AmountSoilEquil;
      end
      else
      begin
        N_AmountSoil.V := NAmountInit - (NAmountInit * N_MengeAnteilAn.V);
        N_AmountSoilNum.V := NAmountInit - (NAmountInit * N_MengeAnteilNum.V);
      end;
    end;
    if integrationMethod.Option = 'analytic' then
    begin
      if compareMode.Option = 'yes' then
        calcN_AmountSoilEquil
      else
        N_AmountSoil.V := NAmountInit - (NAmountInit * N_MengeAnteilAn.V);
    end;
    if integrationMethod.Option = 'numeric' then
    begin
      if compareMode.Option = 'yes' then
        calcN_AmountSoilEquil
      else
        N_AmountSoilNum.V := NAmountInit - (NAmountInit * N_MengeAnteilNum.V);
    end;
  end
  else // Assumes a dynamic change of the soil N content
  begin
    // Implementation still missing
  end;
  { If no 2D diffusion model is available, output the XY coordinates of the valid
    roots (in the observation window but not at the margin) }
  if (My2DDiffModel = nil) and (OutputXY.Option = 'yes') then
  begin
    writeOutputToFile;
  end;
end; // End TSubmodRootDiff1DSolo.Integrate

{ Helper methods }
procedure TSubmodRootDiff1DSolo.init_ReadFromFile;
(* ------------------------------------------------------------------------------
  DESCRIPTION:
  Initialisations and preparations that only make sense once user inputs or data
  read from files at runtime can be considered.
  Primarily excludes roots at the margins: Issue: for the numerical model,
  PosArr_middle in the method removeMarginRoots should be replaced by a global list
  or array that stores SRP instances created here.
  ------------------------------------------------------------------------------ *)
begin
  inherited init_ReadFromFile;
  // removeMarginRoots; // remove marginal roots if necessary
end; // End TSubmodRootDiff1DSolo.init_ReadFromFile

procedure TSubmodRootDiff1DSolo.calcVar_Analyt;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Calculation (initialization) of variables needed for the analytical
  solution (mean root length density, variance, standard deviation, coefficient of
  variation of the root length densities, and the V/M value).
  ------------------------------------------------------------------------------ *)
begin
  { Calculate the mean root length density (if the initialization method is InpPar or
    Submodstruct the root length density has already been read: }
  if (iniMethod.Option = 'inppar') or (iniMethod.Option = 'submodstruct') then
  begin
    // do nothing
  end
  else
    RLD_mean.V := mean(WLD_Array);
  if RootDistribution.Option = 'regular' then
  begin
    // For a uniform distribution the standard deviation etc. are zero
    StdAbw_RLD.V := 0;
    // Calculate the variance of the mean RLD
    Varianz.V := 0;
    // Calculate the coefficient of variation of the mean root length density
    VarKoeff_RLD.V := 0;
  end;
  // In the following cases the coefficient of variation was read as a parameter
  if ((iniMethod.Option = 'inppar') and (RootDistribution.Option = 'lognormal'))
    or ((iniMethod.Option = 'submodstruct') and
    (RootDistribution.Option = 'lognormal')) then
  begin
    StdAbw_RLD.V := VarKoeff_RLD.V * self.RLD_mean.V / 100;
    Varianz.V := sqr(StdAbw_RLD.V);
    // also for the area parameters
    StdAbw_Area.V := VarKoeff_Area.V * Area_mean.V / 100;
  end
  // In all other cases a WLD array was created from which calculations can be made.
  else
  begin
    // not in the case of uniform distribution
    if RootDistribution.Option <> 'regular' then
    begin
      // Calculate the standard deviation of the mean root length density
      StdAbw_RLD.V := StdDev(WLD_Array);
      // Calculate the variance of the mean RLD
      Varianz.V := Math.Variance(WLD_Array);
      // Calculate the coefficient of variation of the mean root length density
      VarKoeff_RLD.V := StdAbw_RLD.V / self.RLD_mean.V * 100;
    end;
  end;
  // Calculate the V/M value
  if RLD_mean.V <> 0 then
  begin
    VM.V := Varianz.V / RLD_mean.V;
    { Calculate the standard deviation of the log-transformed values from the mean
      and the standard deviation of the non-transformed values, Kage }
    Log_StdAbw_RLD.V :=
      sqrt(ln((StdAbw_RLD.V * StdAbw_RLD.V) / (RLD_mean.V * RLD_mean.V) + 1));
    { Calculate the mean of the log-transformed values from the mean of the
      NON-transformed values (RLD_mean) and the standard deviation of the
      LOG-TRANSFORMED values (SA_ln), Kage }
    Log_RLD_mean.V := ln(RLD_mean.V) - 0.5 *
      (Log_StdAbw_RLD.V * Log_StdAbw_RLD.V);
    { Log-transformed values for the area parameters; because these must be
      calculated from log-transformed individual values, the following two lines do
      not run in mode inppar }
    if self.iniMethod.Option <> 'inppar' then
    begin
      Log_StdAbw_Area.V :=
        sqrt(ln((StdAbw_Area.V * StdAbw_Area.V) /
        (Area_mean.V * Area_mean.V) + 1));
      Log_Area_mean.V := ln(Area_mean.V) - 0.5 *
        (Log_StdAbw_Area.V * Log_StdAbw_Area.V);
    end;
  end;
end; // End TSubmodRootDiff1DSolo.calcVar_Analyt

procedure TSubmodRootDiff1DSolo.calcRootArea;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Populate PosArr, calculate the positions and areas.
  Two methods: Voronoi polygons, or the proportional area of a grid cell in which
  roots are located.
  ------------------------------------------------------------------------------ *)
begin
  if (CalcMethRLD_VC.Option = 'voronoi') then
  // Calculation from Voronoi polygons
  begin
  end
  else // Calculation from grid occupancy
  begin
  end;
end;

procedure TSubmodRootDiff1DSolo.copyPosArrFrom2DDif;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Copies the PosArr of the 2D model
  ------------------------------------------------------------------------------ *)
var
  RasterData2D: TRasterData;
  i: integer;
begin
  if My2DDiffModel <> nil then // to be safe
  begin
    RasterData2D := My2DDiffModel.getRasterData;
    RasterData.NRoots := RasterData2D.NRoots;
    for i := 0 to RasterData.NRoots do
    begin
      TRootPosition(RasterData.PosList.Objects[i]).x := TRootPosition(RasterData2D.PosList.Objects[i]).x;
      TRootPosition(RasterData.PosList.Objects[i]).y := TRootPosition(RasterData2D.PosList.Objects[i]).y;
      TRootPosition(RasterData.PosList.Objects[i]).xi := TRootPosition(RasterData2D.PosList.Objects[i]).xi;
      TRootPosition(RasterData.PosList.Objects[i]).yi := TRootPosition(RasterData2D.PosList.Objects[i]).yi;
      TRootPosition(RasterData.PosList.Objects[i]).root := TRootPosition(RasterData2D.PosList.Objects[i]).root;
      TRootPosition(RasterData.PosList.Objects[i]).NInflux := TRootPosition(RasterData2D.PosList.Objects[i]).NInflux;
      TRootPosition(RasterData.PosList.Objects[i]).SumNAmount := TRootPosition(RasterData2D.PosList.Objects[i]).SumNAmount;
      TRootPosition(RasterData.PosList.Objects[i]).WInflux := TRootPosition(RasterData2D.PosList.Objects[i]).WInflux;
      TRootPosition(RasterData.PosList.Objects[i]).area := TRootPosition(RasterData2D.PosList.Objects[i]).area;
    end;
  end;
  num_Roots.V := RasterData.NRoots;
end;

procedure TSubmodRootDiff1DSolo.fillWLDArr;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Populate the WLD array
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  Radius: real;
  Area_EqualDistrib: double;
begin
  setLength(WLD_Array, trunc(number_consid_roots.V));
  // Set the array length
  j := 1; // PosArr starts at 1
  { Special case of uniform distribution: catchment area is constant. However, it can
    happen that PosArr contains roots for which no area was calculated because they
    are located outside the observation window when distributing over the area
    (TVar ErrorReg). Therefore solution: }
  if self.RootDistribution.Option = 'regular' then
  begin
    for i := 0 to trunc(number_consid_roots.V - 1) do
    begin
      // Calculate the EWZ radius from the area:
      Radius := sqrt(TRootPosition(RasterData.PosList.Objects[0]).area / Pi);
      WLD_Array[i] := 1 / (Radius * Radius * Pi);
    end;
  end
  else
  begin
    for i := 0 to trunc(number_consid_roots.V - 1) do
    begin
      { Calculate the root length density from the areas of the Voronoi polygons }
      // Calculate the EWZ radius from the area:
      Radius := sqrt(TRootPosition(RasterData.PosList[j]).area / Pi);
      WLD_Array[i] := 1 / (Radius * Radius * Pi);
      inc(j)
    end;
  end;
end;

procedure TSubmodRootDiff1DSolo.Integrate_Analyt;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Solve the differential equations with an analytical solution.
  The equation yields the fractional N uptake at a specific simulation time for a
  given root length density.
  Lit.: Nye, Tinker (2000) Solute movement in the rhizosphere p. 299 equation 10.28
  ------------------------------------------------------------------------------ *)
var
  // Dynamic array for all fractional uptake rates in the classes
  Aufnahme_arr: Array of real;
  i: integer;
  Rad_SRC, sumUptClasses: real;
begin
  setLength(Aufnahme_arr, trunc(number_classes.V));
  sumUptClasses := 0;
  { In the dynamic model (data from the structure model) certain variables and the
    random variables must be recalculated in every time step: }
  if iniMethod.Option = 'submodstruct' then
  begin
    calcVar_Analyt;
    if RootDistribution.Option = 'lognormal' then
    begin
      // Calculate the class mean values of the RLD from the statistics of the RLD distribution
      if CalcMethQuant.Option = 'fromrld' then
        get_lognorm_ZV
      else
      // Calculate the class mean values of the RLD from the area distribution
      begin
        get_lognorm_ZV_Area;
      end;
    end;
    if RootDistribution.Option = 'normal' then
    begin
      get_normvert_ZV;
    end;
  end;

  { The following case distinction is necessary because (at least with an assumed
    normal distribution) negative root length densities can occur. }
  if RootDistribution.Option <> 'normal' then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      // Calculate the radius of the single root cylinder
      Rad_SRC := 1 / (sqrt(Pi * ZV_Array_lognorm[i]));
      if iniMethod.Option = 'SubmodStruct' then
      // Procedure for dynamic simulation (variable RLD/VC in each time step)
      begin
        Aufnahme_arr[i] := Aufnahme_arr[i] +
          (1 - exp((2 * Pi * ZV_Array_lognorm[i] * Globmod.TimeStep * De.V *
          86400) / (ln(1.65 * RootRadius.V / Rad_SRC))));
      end
      // Procedure for static simulation
      else
        Aufnahme_arr[i] := 1 -
          exp((2 * Pi * ZV_Array_lognorm[i] * Globmod.time.V * De.V * 86400) /
          (ln(1.65 * RootRadius.V / Rad_SRC)));
    end;
    // When calculating uptake based on area
    if CalcMethQuant.Option = 'fromarea' then
    begin
      for i := 0 to trunc(number_classes.V - 1) do
      begin
        sumUptClasses := sumUptClasses + (Aufnahme_arr[i] * weightArr[i]);
      end;
      N_MengeAnteilAn.V := sumUptClasses;
    end
    { Otherwise take the mean of all fractional N uptakes. Issue: may be incorrect;
      even when calculating based on RLD I probably need the sum }
    else
      N_MengeAnteilAn.V := mean(Aufnahme_arr);
  end;
  if RootDistribution.Option = 'normal' then
  // Issue: Implementation still pending
  begin
  end;
  // Even in the regular case everything is handled by the lognormal method
  { if RootDistribution.Option = 'regular' then
    begin }
  { All sinks with the same EWZ area, standard deviation of the RLD = 0 }
  // Rad_EWZ := 1/(sqrt(Pi*RLD_mean.V));
  // N_MengeAnteilAn.V:= 1-exp((2*Pi*RLD_mean.V*Globmod.time.V*
  // De.v*86400)/(ln(1.65*Rad_Wurzel.V/Rad_EWZ)));
  { 1-EXP((2*PI()*RLD(0.1867)*t*D(0.2223)/LN(1.65*RadW(0.02)/RadEWZ(1.3056)) }
  // end;
  Sum_N_AmountRoots.V := N_MengeAnteilAn.V * NAmountInit;
end;

// Helper methods for analytical solution
// Helper methods for determining u values

procedure TSubmodRootDiff1DSolo.get_normvert_ZV;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Uses the u values of the standard normal distribution stored in
  z_quartile (for the quartiles = mean values of the 10 classes) to compute the
  f(x) values (random variables) of the current normal distribution.
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  // Calculate the random variables only if roots are present
  if RLD_mean.V <> 0 then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      ZV_Array_normvert[i] := ZV_Array_Stdnorm[i] * StdAbw_RLD.V + RLD_mean.V;
    end;
  end;
end; // End TSubmodRootDiff1DSolo.get_normvert_ZV

procedure TSubmodRootDiff1DSolo.get_lognorm_ZV;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Computes the f(x) values (random variables) of the present lognormal
  distribution for the quartiles (= mean values of the 10 classes).
  ------------------------------------------------------------------------------ *)
var
  i: integer;
begin
  // Calculate the random variables only if roots are present
  if RLD_mean.V <> 0 then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      ZV_Array_lognorm[i] := exp(ZV_Array_Stdnorm[i] * Log_StdAbw_RLD.V +
        Log_RLD_mean.V);
    end;
  end;
end; // End TSubmodRootDiff1DSolo.get_lognorm_ZV

procedure TSubmodRootDiff1DSolo.get_lognorm_ZV_Area;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Computes the f(x) values (random variables) of the present lognormal
  distribution from the area distribution for the quartiles (= mean values of the 10
  classes).
  ------------------------------------------------------------------------------ *)
var
  i: integer;
  sumPhiUArea // sum of the Phi(u) values of the area quantiles, for weighting
    : double;
begin
  // Calculate the random variables only if roots are present
  sumPhiUArea := 0;
  if RLD_mean.V <> 0 then
  begin
    for i := 0 to trunc(number_classes.V - 1) do
    begin
      ZV_Array_lognorm[i] :=
        (exp(ZV_Array_Stdnorm[i] * Log_StdAbw_Area.V + Log_Area_mean.V));
      sumPhiUArea := sumPhiUArea + ZV_Array_lognorm[i];
    end;
  end;
  // Calculate the weighting factors
  for i := 0 to trunc(number_classes.V - 1) do
  begin
    weightArr[i] := ZV_Array_lognorm[i] / sumPhiUArea;
  end;
  // Calculate the RLD from the Phi(u) values of the area
  for i := 0 to trunc(number_classes.V - 1) do
  begin
    ZV_Array_lognorm[i] := 1 / ZV_Array_lognorm[i];
  end;
end; // End TSubmodRootDiff1DSolo.get_lognorm_ZV_Area

function TSubmodRootDiff1DSolo.Kolmogorov_Smirnov: boolean;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Needed because fractional uptake is calculated depending on the
  assumed distribution function.
  Performs the Kolmogorov-Smirnov goodness-of-fit test (here as a test for an
  assumed lognormal distribution).
  Return value is true if the test is "passed", false if the null hypothesis is
  rejected (observed distribution corresponds to a lognormal distribution).
  Issue: Should the K value (is that correct?) be returned instead and then processed
  further by the calling method?
  ------------------------------------------------------------------------------ *)
begin
  // Issue: Implementation
  Result := true;
end; // End TSubmodRootDiff1DSolo.Kolmogorov_Smirnov

// Helper methods for numerical solution
procedure TSubmodRootDiff1DSolo.Calc_numeric;
(* ------------------------------------------------------------------------------
  DESCRIPTION: Method that performs the rate equation calculation using the numerical
  solution
  ------------------------------------------------------------------------------ *)
begin
  // Calculation
  { Note: The sum of all rate equations was calculated in the following ways
    (two variants):
    a) Calculate the maximum nitrate influx rate for each individual root cylinder,
    i.e. calculate the rates of all roots. The individual results are then summed
    (method calc_num_EWZ).
    b) Calculate using the average RLD in the classes already used with the
    analytical solution and multiply the result by the number of roots in the classes
    (method calc_num_Class). Possibly better performance and comparability with the
    analytical solution.
    Issue: Is this consideration correct?
    Depending on requirements one method or the other can be commented out.
    Another option would also be possible }
  { Issue: Should this be N_MengeAnteil.C:=NMenge.c+calc_num_EWZ; (probably not) }
  N_MengeAnteilNum.C := calc_num_EWZ;
  // N_MengeAnteilNum.C:=calc_num_class;
end; // End TSubmodRootDiff1DSolo.Calc_numeric

function TSubmodRootDiff1DSolo.calc_num_EWZ: real;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Calculate the maximum nitrate influx rate for each individual root
  cylinder, i.e. calculate the rates of all roots.
  ------------------------------------------------------------------------------ *)
var
  i, j: integer;
  Nitrat_Flux_EWZ, // Nitrate influx in the individual root cylinder
  Sum_Nitrate_flux, // Sum of the nitrate influx rate of all EWZ
  Db, // Product of buffering and effective diffusion coefficient
  dist: real; // Radius of the EWZ
  AClmean: double; // due to dereferencing the pointer

begin
  { Issue: Is the calculation correct? }
  { Kage dissertation: Db is the product of buffering and effective diffusion
    coefficient and thus Db = De * theta, because for non-sorbed ions b = theta. }
  Db := De.V * theta.V * 86400;
  j := 1; // PosArr starts at 1
  // Calculate the current concentrations for the respective EWZ
  for i := 0 to trunc(RasterData.NRoots) - 1 do
  begin
    { Concentration in the soil solution is calculated from the initial N amount in
      the current time step minus the absorbed N amount (= sum of all integrated
      fluxes in the EWZ). Issue: is this correct? Can concentrations simply be
      subtracted from each other, or must they first be converted back to amounts? }
    { Cl_mean_Array[i]:=Cl_mean_Array[i]-(NAmount_UPEWZArray[i].V/
      VolH20_EWZ_Array[i]); }
  end;
  // Rate calculation for all roots
  for i := 0 to RasterData.NRoots - 1 do
  begin
    dist := sqrt(TRootPosition(RasterData.PosList.Objects[j]).area / Pi);
    // Calculate the EWZ radius
    AClmean := Pdouble(Cl_mean_List.items[i])^;
    Nitrat_Flux_EWZ := ((AClmean - Clmin.V) * 2 * Pi * Db) /
      (ln(dist / (1.65 * self.RootRadius.V))); // Kage Diss, S.57, Gl.3.6.30
    // NAmount_UPEWZArray[i].C:=Nitrat_Flux_EWZ;
    Sum_Nitrate_flux := Sum_Nitrate_flux + Nitrat_Flux_EWZ;
    inc(j);
  end;
  Result := Sum_Nitrate_flux;
end; // End TSubmodRootDiff1DSolo.calc_num_EWZ

function TSubmodRootDiff1DSolo.calc_num_class: real;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION:
  Calculate the nutrient uptake rate using the average RLD in the classes already
  used with the analytical solution and multiply the result by the number of roots in
  the classes.
  Possibly better performance and comparability with the analytical solution.
  Issue: Implementation pending.
  ------------------------------------------------------------------------------ *)
begin

end; // End TSubmodRootDiff1DSolo.calc_num_class

procedure TSubmodRootDiff1DSolo.transform_Clmin;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Convert the soil solution concentration from mol/l into other units.
  Issue: verify conversion.
  ------------------------------------------------------------------------------ *)
begin
  // Convert from [micromol/l] to [kg/l]
  ClminTransf.V := Clmin.V * 14 / 1E-9;
  // Convert to [kg/ha]
  ClminTransf_ha.V := ClminTransf.V / 1E-7;
end; // End TSubmodRootDiff1DSolo.transform_Clmin

procedure TSubmodRootDiff1DSolo.calc_Amount_H20;
(* ------------------------------------------------------------------------------
  ASSOCIATED CLASS: TSubmodRootDiff1DSolo
  DESCRIPTION: Calculate the initial water amount in the soil layer under
  consideration
  ------------------------------------------------------------------------------ *)
begin
  { Water amount in the soil layer under consideration (theta is initially assumed
    to be constant) }
  Amount_H20.V := volume.V * theta.V;
end; // End TSubmodRootDiff1DSolo.calc_Amount_H20

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
    classBorder := sqrt(1 / (ZV_Array_lognorm[i] * Pi));
    cl_avClass := Clmin.V - (Min_s.V * (sqr(classBorder) - sqr(RootRadius.V)) /
      (4 * Db)) + (Min_s.V * sqr(classBorder) / (2 * Db) *
      ln(classBorder / RootRadius.V));
    // Weighting
    cl_avClass := cl_avClass * weightArr[i];
    cl_av.V := cl_av.V + cl_avClass;
  end;
  N_AmountSoil.V := Mg_func(Depth.V, theta.V, cl_av.V);
end;

end.
