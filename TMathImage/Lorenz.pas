unit Lorenz;

interface

uses MathImge;

type


  TLorenz = class
  private
    ftol, fh: double; //tolerance, stepsize
    fState: TD3FloatPoint; //current state
    fInvTol, fPower, fFactor, fMult, fMinStepSize, fMaxStepSize: double;
    procedure f(const State: TD3FloatPoint; var res: TD3FloatPoint); //right hand sides of ODE
    procedure SetTolerance(Value: double);
    procedure OneFixedStep(aH: double; const aInput: TD3FloatPoint; var aOutput: TD3FloatPoint); //ODE solver, RK4
    procedure OneControlledStep; //Step size controll added, to match tolerance
  public
    sigma, r, b: double; //parameters, most commonly used ones are set in constructor
    Curve: TD3FloatPointList;
    {contains the current curve computed by GenerateSolutionCurve}
    constructor Create;
    destructor Destroy; override;
    property Tolerance: double read ftol write SetTolerance; //Tolerance in state units, and per step

    (*The important thing *)

    procedure GenerateSolutionCurve(const s0: TD3FloatPoint; NumPoints: Integer);

    {Use this procedure to generate the "Lorenz-Attractor". This is the solution curve to
    the system of 3 ODEs given by f. s0 is the start point. Field "Curve" contains the coordinates
    generated .
    The attractor is actually approximated only by a tail-piece of the curve, but who cares.
    It's interesting to see output for different values of r. The value range of the curve is
    typically between
    x: -25 -> 25
    y: -25 -> 25
    z:   8 -> 58.
    For large r-values, the start point s0 hardly matters, just don't take
    (0,0,0), as for this all points will come out 0.
    }
  end;

  {Note: This code can easily be modified to generate solution curves for
  for general ODE. Basicly the only thing that changes is the definition of
  f.}

function D3FloatPoint(x, y, z: double): TD3FloatPoint;
//for convenience

implementation

{ TLorenz }

constructor TLorenz.Create;
begin
  ftol := 1.E-8; fInvTol := 1.E8;
  fh := 0.1;
  fState.x := 1; fState.y := 1; fState.z := 0;
  sigma := 10;
  r := 36;
  b := 8 / 3;
  fPower := -1 / 5;
  fFactor := 16 / 15; //2^4/(2^4-1); 4 is order of RK4
  fMult := fFactor * fInvTol;
  fMaxStepSize := 1;
  fMinStepSize := 1.E-7;
  Curve:=nil;
end;

destructor TLorenz.Destroy;
begin
  if Curve<>nil then
  Curve.free;
  inherited;
end;

procedure TLorenz.f(const State: TD3FloatPoint; var res: TD3FloatPoint);
begin
  with State do
  begin
    res.x := sigma * (y - x);
    res.y := r * x - y - x * z;
    res.z := x * y - b * z;
  end;
end;


procedure TLorenz.GenerateSolutionCurve(const s0: TD3FloatPoint; NumPoints: Integer);
var i, n: Integer;
begin
  if Curve<>nil then
  Curve.Free;
  Curve:=TD3FloatPointList.Create;
  fState := s0;
  Curve.Add(fState.x,fState.y,fState.z);
  n := NumPoints - 1;
  for i := 1 to n do
  begin
    OneControlledStep;
    Curve.Add (fState.x,fState.y,fState.z);
  end;
end;

procedure AddVectors(const v1, v2: TD3FloatPoint; const h: double; var res: TD3FloatPoint);
begin
  res.x := v1.x + h * v2.x;
  res.y := v1.y + h * v2.y;
  res.z := v1.z + h * v2.z;
end;

function max(x, y: double): double;
begin
  Result := x;
  if y > x then
    Result := y;
end;


{The following routine is adapted from 
    Stoer/Bulirsch: 
    Introduction to Numerics II 
    (Springer)}

procedure TLorenz.OneControlledStep;
var h2, delta, habs: double;
  State1, State2: TD3FloatPoint;
begin
  repeat
    h2 := 2 * fh;
    OneFixedStep(h2, fState, State1);
    OneFixedStep(fh, fState, State2);
    OneFixedStep(fh, State2, State2);
    delta := abs(State1.x - State2.x);
    delta := max(delta, abs(State1.y - State2.y));
    delta := max(delta, abs(State1.z - State2.z));
    if delta <> 0 then
      delta := exp(fPower * ln(delta * fMult))
    else
      delta := 1.E12;
    fh := h2 * delta;
    habs := abs(fh);
    if delta > 1 / 3 then //accuracy is OK
    begin
      if habs > fMaxStepSize then
      //Adjusted stepsize might be fine for this step, but we don't trust it for the next one.
        if fh > 0 then fh := fMaxStepSize else fh := -fMaxStepSize;
      break;
    end;
    if habs < fMinStepSize then
    //accuracy not OK but fh below Minstepsize
    begin
      if fh > 0 then fh := fMinStepSize else fh := -fMinStepSize;
      break; //no more control
    end;
  until False;
  fState := State2;
  //state2 is the new state now. We don't keep track of the time variable at all here.
end;


procedure TLorenz.OneFixedStep(aH: double; const aInput: TD3FloatPoint; var aOutput: TD3FloatPoint);
var  hh, h6: double;
  v, v1, v2, Temp: TD3FloatPoint;
begin
  hh := 0.5 * aH; h6 := 1 / 6 * aH;
  f(aInput, v);
  AddVectors(aInput, v, hh, Temp);
  f(Temp, v1);
  AddVectors(aInput, v1, hh, Temp);
  f(Temp, v2);
  AddVectors(aInput, v2, aH, Temp);
  AddVectors(v1, v2, 1, v1);
  f(Temp, v2);
  aOutput.x := aInput.x + h6 * (v.x + v2.x + 2 * v1.x);
  aOutput.y := aInput.y + h6 * (v.y + v2.y + 2 * v1.y);
  aOutput.z := aInput.z + h6 * (v.z + v2.z + 2 * v1.z);
end;

procedure TLorenz.SetTolerance(Value: double);
begin
  if Value > 0 then
  begin
    ftol := Value;
    fInvTol := 1 / Value;
    fMult := fFactor * fInvTol;
  end;
end;

function D3FloatPoint(x, y, z: double): TD3FloatPoint;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

end.


