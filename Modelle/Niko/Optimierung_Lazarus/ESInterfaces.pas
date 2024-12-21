unit ESInterfaces;

{$mode objfpc}{$H+}
{$interfaces corba}

interface

type
  TVector = array[0..MaxInt div SizeOf(Extended) - 1] of Extended;
  PVector = ^TVector;
  TCalcTargetCallback = function(ATarget: Integer; ALocation: PVector): Extended;

  ISolver = interface
    procedure Init;
    procedure RunLearningCycle;
    procedure Free;

    procedure SetCalcTargetCallback(ACalcTargetCallback: TCalcTargetCallback);
    procedure SetVariableBounds(AVariable: Integer; AMinValue, AMaxValue,
      AGranularity: Extended); overload;
    procedure SetVariableBounds(AVariable: Integer; AMinValue,
      AMaxValue: Extended); overload;
    procedure SetTargetBounds(ATarget: Integer; AMinValue, AMaxValue: Extended;
      AWeight: Integer); overload;
    procedure SetTargetBounds(ATarget: Integer; AMinValue,
      AMaxValue: Extended); overload;

    function GetObjectiveValue: Extended;
    function GetLocation: PVector;

    procedure SetTolerance(ATolerance: Extended);
    function GetTolerance: Extended;
    function GetStagnation: Integer;

    property ObjectiveValue: Extended read GetObjectiveValue;
    property Location: PVector read GetLocation;
    property Tolerance: Extended read GetTolerance write SetTolerance;
    property Stagnation: Integer read GetStagnation;
  end;

  IDEPSSolver = interface(ISolver)
    procedure SetAgents(AAgents: Integer);

    procedure SetSwitchRate(ASwitchRate: Extended);

    procedure SetDEVectors(ADEVectors: Integer);
    procedure SetDEFactor(ADEFactor: Extended);
    procedure SetDECrossoverRate(ADECrossoverRate: Extended);

    procedure SetPSCognitiveFactor(APSCognitiveFactor: Extended);
    procedure SetPSSocialFactor(APSSocialFactor: Extended);
    procedure SetPSWeight(APSWeight: Extended);
    procedure SetPSCL(APSCL: Extended);
  end;

const
  MinBounds = -1.1e+4932;
  MaxBounds = 1.1e+4932;

implementation

end.

