/// <summary>
/// Unit defining a root object
/// TRootObject contains all properties of a single root
/// and methods for calculating water and nitrate influx
/// implementation of methods/functions is taken from URootUptakeFunctions.pas
/// </summary>
unit URootObject;

interface

uses
  URootUptakeFunctions;

type
  /// <summary>
  /// Mode of nitrogen uptake by the root: Michaelis-Menten (saturation kinetics),
  /// fixed_influx assumes a constant sink strength, ZeroSink represents unlimited
  /// sink strength (black hole).
  /// </summary>
  TUptake_Function = (MM, fixed_influx, ZeroSink);

  /// <summary>
  /// Defines an object for storing the information of
  /// a single root object
  /// x and y are the floating point type coordinate
  /// xi and yi are the index integers for the cell of a 2-D grid object
  /// the root object is located
  /// </summary>

  TRootObject = class(TObject)
  private
    
    /// <summary>
    /// area of the single root cylinder [cm"]
    /// </summary>
    fArea: real;
    
    /// <summary>
    /// root length density [cm/cm3]
    /// </summary>
    fRLD: real;
    
    
    /// <summary>
    /// minimum nitrate concentration
    /// </summary>
    fCl_min: real;

    /// <summary>
    /// maximum nitrate uptake rate [mol/cm/]
    /// </summary>
    fMaxNInflux: real;
    fTUptakefunction: TUptake_Function;
  protected

  public


    /// <summary>
    /// root radius [cm]
    /// </summary>
    radius: real;

    /// <summary>
    /// Amount of water in the single root cylinder [cm3]
    /// </summary>
    WAmount: real;

    /// <summary>
    /// Amount of nitrate in the single root cylinder [mol N]
    /// </summary>
    NAmount: real;

    /// <summary>
    /// volumetric water content in the single root cylinder [cm3/cm3]
    theta: real;

    /// <summary>
    /// the nitrate concentration in the single root cylinder [g nitrate N/cm3]
    /// </summary>
    Cl_mean: real;

    /// <summary>
    /// michaelis-menten-constant [[g nitrate N/cm3]]
    /// </summary>
    Km: real;

    /// <summary>
    /// minimum nitrate concentration, i.e. concentration
    /// when influx is zero [g nitrate N/cm3]
    /// </summary>
    Clmin: real;

    Imax: real;

    /// <summary>
    /// the nitrate influx rate of that root [mol/cm/s]
    /// </summary>
    NInflux: real;

    /// <summary>
    /// Sum of the nitrate influx rates [mol/cm]
    /// </summary>
    SumNInflux: real;

    /// <summary>
    /// the water influx rate of that root [cm3/cm/s]
    /// </summary>
    WInflux: real;

    /// <summary>
    /// Sum of the water influx rates [cm3/cm]
    /// </summary>
    SumWInflux: real;

    /// <summary>
    /// the nitrate uptake rate [mol/s]
    /// </summary>
    NAmountdt: real;

    constructor create; virtual;

    procedure init(RLD, radius, WAmount, NAmount: real); virtual;

    /// <summary>
    /// calculates maximum nitrate influx based on
    /// the concentration gradient between soil and root surface
    /// and the root properties
    /// </summary>
    function MaxNitrateInflux: real;

    /// <summary>
    /// calculates nitrate influx based on Michaelis-Menten kinetics
    function MM_NitrateInflux: real;

    function get_HalfDistance: real;
    function get_Area: real;
    procedure set_Area(a: real);

    procedure set_RLD(rld: real);
    function get_RLD: real;

    property Cl_min: real read fCl_min write fCl_min;

    /// <summary>
    /// radius of root cylinder [cm]
    /// </summary>
    property HalfDistance: real read get_HalfDistance;

    /// <summary>
    /// Root length density [cm/cm3]
    /// </summary>
    property RLD: real read get_RLD write set_RLD;
    
    /// <summary>
    /// the area of the single root cylinder [cm2]
    /// </summary>
    property Area: real read get_Area write set_Area;

  published

  end;

  TRootObjectIn2D = class(TRootObject)
  private

  protected

  public
    /// <summary>
    /// x and y coordinates of the root point [cm]
    /// </summary>
    x: real;
    y: real;

    /// <summary>
    /// the index values of the root within a grid cell in x and y direction
    /// </summary>
    xi, yi: integer;

    /// <summary>
    /// the number of the root
    nroot: integer;

    constructor create; override;

    procedure init(x, y, z: real; xi, yi, zi, nroot: word;
      RLD, radius, WAmount, NAmount: real); reintroduce; virtual;

  published

  end;


implementation

constructor TRootObject.create;

begin
  inherited;
  self.fCl_min := 0;
  self.fMaxNInflux := 0;
  self.RLD := 1;
end;

function TRootObject.get_HalfDistance: real;
begin
  get_HalfDistance := 1/sqrt(pi*RLD);;
end;

function TRootObject.get_Area: real;
var
  fArea: double;
begin
  fArea := Pi*sqr(radius);
  get_Area := fArea;
end;

function TRootObject.get_RLD: real;
begin
  get_RLD := fRLD;
end;

procedure TRootObject.set_RLD(rld: real);
begin
  fRLD := rld;
  fArea := Pi*sqr(radius);
end;

procedure TRootObject.set_Area(a: real);
begin
  fArea := a;
  fRLD := 1/(Pi*sqr(radius));
end;

procedure TRootObject.Init(RLD, radius, WAmount, NAmount:real);

begin
  RLD := RLD;
  radius := radius;
  WAmount := WAmount;
  NAmount := NAmount;
  cl_mean := NAmount/WAmount;
end;



function TRootObject.MaxNitrateInflux;

begin

  MaxNitrateInflux := Imax_f(Cl_mean, Cl_min,
   theta, WInflux, Rld, radius);
end;

function TRootObject.MM_NitrateInflux:real;

begin
  MM_NitrateInflux :=  MM_NInflux(Cl_mean, rld, radius, theta, winflux, Imax, Km, clmin) ;
end;


constructor TRootObjectIn2D.create;
begin
  inherited;
end;

procedure TRootObjectIn2D.Init(x, y, z: real;
                          xi, yi, zi, nroot: word;
                          RLD, radius, WAmount, NAmount:real);
begin
  inherited init(RLD, radius, WAmount, NAmount);
  self.x := x;
  self.y := y;
  self.xi := xi;
  self.yi := yi;
  self.nroot := nroot;
end;

end.
