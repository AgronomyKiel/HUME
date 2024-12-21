unit USimplePlantWW_R;

interface

uses
  Windows, Messages, SysUtils, Classes, vcl.Graphics, vcl.Controls, vcl.Forms, vcl.Dialogs,
  UMod, USimplePlant, UState ;

type
  real = double;
  TSimplePlantWW_R = class(TSimplePlant)
  private
    fFineRoot0    : TPar;
    FFineRootDec  : TPar;
    FFineroot     : TVar;
    TempSum       : TState;
    Plants        : TState; // Number of Plants  [1/m2]
    SWMIN : TState;   //  Minimum stem weight of a plant after anthesis, used to calculate amount of reserves that can be used to fill grain [g/plant]
    SowingDensity : TPar;   // Number of sown Seeds [1/m2]
    DMStem_pl : TVar;         // Stem dry matter per plant

    SUMDTT5     : TState;   // The sum of daily thermal time (DTT) for stage 5  [degree days]
    CUMPH : TState;         // cumulative phyllochrons since emergence [-]


    h        : TPar;   {Proportionalitaetskonstante Blatt-Stängel-Verteilung}
    g        : Tpar;   {Proportionalitaetskonstante Blatt-Stängel-Verteilung}

    EC,
    ISTAGE,
    XStage,
    TMPMN,
    TMPMX
         : TExternV;  // Entwicklungsstadium


    { Private-Deklarationen }
  protected
    { Protected-Deklarationen }
  public

   procedure createAll; override;
   procedure init(var GlobMod: TMod); override;
   procedure CalcRates; override;
   procedure Integrate; override;
    { Public-Deklarationen }
  published

  property Par_h  : TPar read h write h ;   { Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_g  : Tpar read g write g;   {Proportionalitaetskonstante Blatt-Stengel-Verteilung}
  property Par_SowingDensity : TPar read SowingDensity write SowingDensity;
  property St_Plants         : TState read Plants write Plants;
  Property St_SUMDTT5 : TState read SUMDTT5 write SUMDTT5;
  Property St_SWMIN     : TState read SWMIN write SWMIN;
  Property St_CUMPH     : TState read CUMPH write CUMPH;

  property Var_DMStem_pl     : TVar read DMStem_pl write DMStem_pl;

  property Var_FFineRoot : TVar read FFineRoot write FFineroot;
  property Par_FFineRoot0 : TPar read FFineRoot0 write FFineroot0;
  property Par_FFineRootDec : TPar read FFineRootDec write FFinerootDec;
  property Ex_EC            : TExternv read EC write EC;
  property Ex_ISTAGE        : TExternV read ISTAGE write ISTAGE;
  property Ex_xSTAGE        : TExternV read xSTAGE write xSTAGE;
  property Ex_TMPMN        : TExternV read TMPMN write TMPMN;
  property Ex_TMPMX        : TExternV read TMPMX write TMPMX;
    { Published-Deklarationen }
  end;

procedure Register;

implementation

uses
  math;

procedure TSimplePlantWW_R.createAll;

begin
  inherited CreateAll;
  VarCreate('fFineRoot', '[-]', 0.4, false, fFineroot);
  VarCreate('STMWT', '[g/plant]', 0.0, false, DMStem_pl);

  ParCreate('fFineRoot0', '[-]', 0.4, fFineroot0);
  ParCreate('fFineRootDec', '[-]', 0.0002, fFinerootdec);


  ParCreate('h','[-]', -2.4712, h);
  ParCreate('g','[-]', 1.3129, g);
  ParCreate('SowingDensity', '[1/m2]', 320, sowingdensity);


  StateCreate('TempSum', '[°C.d]', 0, true, TempSum);
  StateCreate('Plants', '[1/m2]', 300, true, Plants);
  StateCreate('SUMDTT5', '[degree days]',0, true,SUMDTT5);
  StateCreate('SWMIN', '[g/plant]',0, true,SWMIN);
  StateCreate('CUMPH', '[-]',0, true,  CUMPH);

  ExternVcreate('EC', '[-]', StateField, EC);
  ExternVcreate('ISTAGE', '[-]', StateField, ISTAGE);
  ExternVcreate('xSTAGE', '[-]', StateField, xSTAGE);
  ExternVcreate('TMPMN', '[-]', StateField, TMPMN);
  ExternVcreate('TMPMX', '[-]', StateField, TMPMX);


end;

procedure TsimplePlantWW_R.init;

begin
  inherited;
  Plants.v := SowingDensity.v;

end;

procedure TSimplePlantWW_R.CalcRates;

begin
//  inherited CalcRates;
   If GlobTime.v >= SowingDate.v then begin
    If Temp.v > 0.0 then
      TempSum.c := Temp.v
    else TempSum.c  := 0.0;

{    If  (ISTAGE.v>=1)and (ISTAGE.v<2) then
     CUMPH.c :=  TempSum.c/PHINT.v
    else  CUMPH.c :=   0  ;  }

// own approach
    FFineRoot.v := fFineRoot0.v-FFinerootDec.v*TempSum.v;      // old version


// modified Ceres approach
{    If Xstage.v >=1 then
      FFineRoot.v := fFineRoot0.v*exp(-FFinerootDec.v*(Xstage.v))
    else
      FFineRoot.v := fFineRoot0.v;
    If FFineRoot.v<0 then FFineroot.v := 0.0;  }

 // Ceres approach
 { IF (ISTAGE.v < 9) and (ISTAGE.v>=5)
     then FFineRoot.v := 0.0 else
   If  (ISTAGE.v<5)and (ISTAGE.v>=4)
     then  FFineRoot.v :=   1-0.8
   else  If  (ISTAGE.v<4)and (ISTAGE.v>=3)
     then  FFineRoot.v :=   1-0.75
   else  If  (ISTAGE.v<3)and (ISTAGE.v>=2)
     then  FFineRoot.v :=   1-0.70
   else  If  (ISTAGE.v<2)and(ISTAGE.v>=1)
     then  FFineRoot.v :=   1-0.5
   else  FFineRoot.v :=   0.0  ;   }

 If FFineRoot.v<0 then FFineroot.v := 0.0; 

    If  (ISTAGE.v>=5)and(ISTAGE.v<6)
      then  SUMDTT5.c :=   0.25*TMPMN.v+0.75*TMPMX.v
    else  SUMDTT5.c :=   0  ;

    DMFineRoot.C    := Assiflow.v * (FFineRoot.v)/(1-FFineRoot.v);
    AssiToFineRoot.v := DMFineRoot.c;
    DMShoot.c       := Assiflow.v;


    If EC.v < 65 then
      DMSTem.c :=  AssiFlow.v*1/(1+exp(h.v)*power(DMStem.v,g.v-1)*g.v)
    else
      DMStem.c := 0.0;
    If EC.v  < 39 then
      DMLeaf.c :=  Assiflow.v-DMStem.c
    else
      DMLeaf.c := 0.0;


  end;

end;

procedure TSimplePlantWW_R.Integrate;

begin
  inherited;
  DMStem_pl.v := DMStem.v/Plants.v;
  If (ISTAGE.v >= 4.0) and (SWMIN.v <= 0.0) then
    SWMIN.v := DMSTeM_pl.v;
  TotalDryMatter.c := Assiflow.v;
end;

procedure Register;
begin
  RegisterComponents('Simulation', [TSimplePlantWW_R]);
end;

end.
