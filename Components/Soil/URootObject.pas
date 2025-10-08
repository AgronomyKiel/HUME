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
  ///   Defines an object for storing the information of
  ///  a single root object
  ///  x and y are the floating point type coordinate
  ///  xi and yi are the index integers for the cell of a 2-D grid object
  ///  the root object is located
  /// </summary>
  TRootObject = class(TObject)
   private
    /// <summary>
    ///   minimum nitrate concentraion
    /// </summary>
     fCl_min: real;

    /// <summary>
    ///   radius of root cylinder [cm]
    /// </summary>
     fHalfDistance : real;

     /// <summary>
     ///   maximum nitrate uptake rate [mol/cm/]
     /// </summary>
     fMaxNInflux: real;
   protected

   public
    /// <summary>
    ///   x and y coordinates of the root exit point [cm]
    /// </summary>
    x: real;
    y: real;

    /// <summary>
    ///   the index of the grid cell in x and y direction
    /// </summary>
    xi, yi: integer;

    /// <summary>
    ///   the number of the root
    nroot: integer;

    /// <summary>
    ///  the area of the single root cylinder [cm�]
    /// </summary>
    area : real;

    /// <summary>
    ///   Root length density [cm/cm3]
    /// </summary>
    RLD : real;

    /// <summary>
    ///   root radius [cm]
    /// </summary>
    radius: real;

    /// <summary>
    ///   Amount of water in the single root cylinder [cm3]
    /// </summary>
    WAmount: real;

    /// <summary>
    ///   Amount of nitrate in the single root cylinder [mol N]
    /// </summary>
    NAmount: real;

    /// <summary>
    /// volumetric water content in the single root cylinder [cm3/cm3]
    theta: real;


    /// <summary>
    /// the nitrate concentration in the single root cylinder [mol/cm3]
    /// </summary>
    Cl_mean: real;

    /// <summary>
    /// the nitrate influx rate of that root [mol/cm/s]
    /// </summary>
    NInflux : real;

    /// <summary>
    ///   Sum of the nitrate influx rates [mol/cm]
    /// </summary>
    SumNInflux: real;

    /// <summary>
    /// the water influx rate of that root [cm3/cm/s]
    /// </summary>
    WInflux: real;

    /// <summary>
    ///   Sum of the water influx rates [cm3/cm]
    /// </summary>
    SumWInflux: real;

    /// <summary>
    /// the nitrate uptake rate [mol/s]
    /// </summary>
    NAmountdt : real;

    procedure init(x, y: real;
                       xi, yi, nroot: word;
                       RLD, radius, WAmount, NAmount:real); virtual;

    function MaxNitrateInflux:real;

    property Cl_min: real read fCl_min write fCL_min;
    property HalfDistance: real read fHalfDistance write fHalfDistance;

    published



  end;



implementation






procedure TRootObject.Init(x, y: real;
                       xi, yi, nroot: word;
                       RLD, radius, WAmount, NAmount:real);

begin
  x := x;
  y := y;
  xi := xi;
  yi := yi;
  nroot := nroot;
  RLD := RLD;
  radius := radius;
  WAmount := WAmount;
  NAmount := NAmount;
  fHalfDistance := 1/sqrt(pi*RLD);
  Area := Pi*sqr(x);
  cl_mean := NAmount/WAmount;
end;



function TRootObject.MaxNitrateInflux;


begin

  MaxNitrateInflux := Imax(Cl_mean, Cl_min,
   theta, WInflux, Rld, radius);

end;

end.
