unit UAcock;

interface

uses UState, Umod, classes, IniFiles, UDryMatProdComp;

type
  real = double;
  TPmax_f = (Pmax_const, Pmax_fI);

TAcockTotDry = Class(TDrymatterproduction)
  private

  protected
  procedure Set_GlobMod(value:TMod); override;
  procedure CreateAll; override;

  public
     alpha           : TPar;
     Pmax            : Tpar;
     Latitude        : TPar;
     CVE             : TPar;
     dtga            : TVar;       // Daily total of gross assimilates (g CH2O .m-2.d-1)
     I_av            : TVar;
     Pmax_f                : TPmax_f;

     Constructor create (AOwner:TComponent);  override;

     procedure CalcRates; override;
     procedure Init(var GlobMod:Tmod); override;

   published
     Property Par_Pmax : TPar read Pmax write Pmax;
     property Par_Alpha : TPar read alpha write alpha;
     property Par_Latitude : TPar read Latitude write Latitude;
     property Opt_Pmax : TPmax_f read Pmax_f write Pmax_f;
     property PAR_CVE : TPar read CVE write CVE;

 end;

 procedure Register;

implementation

uses
  UModUtils,  math, Sucros;


procedure TAcockTotDry.CreateAll;

begin
  inherited CreateAll;
  ParCreate( 'alpha','[µg CO2.J-1]', 25, alpha);
  ParCreate( 'Pmax','[µg CO2.m-2.s-1]', 1000, Pmax);
  PARcreate('LAT', '[°]', 52, Latitude);
  ParCreate( 'CVE','[g CH2O.gCO2-1]', 0.7, CVE);
  VarCreate('DTGA','[g CH2O .m-2.d-1]', 0.0, false, dtga);
  VarCreate('I_av','[W.m-2]', 0, false, I_av);
end;

Constructor TAcockTotDry.create (AOwner:TComponent);

begin
  inherited Create(AOwner);
  CreateAll;

end;

procedure TAcockTotDry.Set_GlobMod(value:TMod);

begin
  inherited Set_globMod(Value);
  CreateAll;

end;


Procedure TAcockTotDry.Init(var GlobMod:Tmod);
begin
inherited Init(globMod);
dtga.v := 0.0;
end;

procedure TAcockTotDry.CalcRates;


var
  day, i : integer;
  dayl, dayls, daylp : real;
  Pmax_eff : real;
  GrossPhotosynthesis : real;
  Respiration         : real;
  Iabs                : real;
  x                   : real;
  DEC                 : real;
  SINLD               : real;
  COSLD               : real;
  dsinbe              : real;
  AOB                 : real;
  hour                : real;
  apar                 : array[1..n_gauss] of real;


begin
  inherited calcrates;
  day := trunc(GlobTime.v);
  daylength(day, Latitude.v, dayl, daylp);
  dayls := dayl*3600;   {Umrechnung auf Sekunden}

  I_av.V := Par.v/dayls*1e6;
   // Umrechnung von MJ PAR.m-2.d-1 auf J PAR .m-2.s-1

  Pmax_eff := Pmax.v*Temp_f.v;

   X:= arcsin(SIN(23.45*RAD)*COS(2.*PI*(DAY+10)/365));
   DEC:=X*-1;
   SINLD:=SIN(RAD*LATitude.v)*SIN(DEC);
   COSLD:=COS(RAD*LATitude.v)*COS(DEC);
   AOB:=  SINLD/COSLD;

   DSINBE:=3600*(DAYL*(SINLD+0.4*(SINLD*SINLD+COSLD*COSLD*0.5))+
              12.0*COSLD*(2.0+3.0*0.4*SINLD)*SQRT(1-AOB*AOB)/PI);


   dtga.v := 0.0;

   for I := 1 to n_gauss do begin
     Hour    := 12.0+0.5*DayL*xgauss[i];
     sinb[i] := sinld+cosld*cos(2.0*pi*(hour+12.0)/24);
     if sinb[i] < 0.0 then sinb[i] := 0.0;

{ Berechnung der PAR an }

     aPAR[i]    := I_av.V*86400*sinb[i]*(1.0+0.4*sinb[i])/dsinbe;
     If Pmax_f = Pmax_fI then
     // Abnahme von Pmax mit LAI siehe Charles-Edwards (1982)
        GrossPhotosynthesis := alpha.v*aPAR[i]*Pmax_eff*(1-exp(-k.v*LAI.v))/
                               (alpha.v*k.v*aPAR[i]+Pmax_eff)
     else
     // konstanter Pmax-Wert (Acock)
       GrossPhotosynthesis := Pmax_eff/k.v*ln((alpha.v*k.v*aPAR[i]+Pmax_eff)/
                          (alpha.v*k.v*aPAR[i]*exp(-k.v*LAI.v)+Pmax_eff));
       DTGA.v:=DTGA.v+GROSSPhotosynthesis*WGAUSS[i];
   end;

 {Umrechnung auf [g CH2O.d-1] }
  dtga.v := dtga.v*Dayls*30/44/1e6;

  // Annahme von 30% Wachstumsatmung
  Assiflow.v := CVE.v*dtga.v;

end;

procedure Register;

begin
  RegisterComponents('Simulation', [TAcockTotDry]);
end;


end.
