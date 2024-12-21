
// Variablen ********************

Var: , 
     carbo, carbored, ipar, lue, par, pcarb, prft, swdf1, testcarbo, testcarbo2: TVar;


// Defined values ********************

     

// Compartements ********************

     

// Component Events ********************

     

// Lookup Tables ********************


// Variablen Initiieren *************

procedure TSubmodel.createall;
begin
   inherited createAll
   VarCreate(carbo, '', 0, true, carbo);
   VarCreate(carbored, '', 1, true, carbored);
   VarCreate(ipar, '', , true, ipar);
   VarCreate(lue, '', 0, true, lue);
   VarCreate(par, '', , true, par);
   VarCreate(pcarb, '', 0, true, pcarb);
   VarCreate(prft, '', prft := max(0,1 - 0.0025 * (tempm - 16)^2) , true, prft);
   VarCreate(swdf1, '', , true, swdf1);
   VarCreate(testcarbo, '', 1, true, testcarbo);
   VarCreate(testcarbo2, '', , true, testcarbo2);

end;

// Variablen Prozeduren *************

// the daily biomass production - g/plant 
carbo := 0;  // by default
if (istage>=5)and(istage<6) then carbo := max(0.001,carbored*pcarb*min(swdf1, ndef1)*prft)/plants;
if (istage>=1)and(istage<5) then carbo := max(0.001,pcarb*min(swdf1, ndef1)*prft)/plants;

carbored := 1;  // by default
if (istage>=5)and(istage<6)and(stmwt>0) then carbored := max(0,(1.-(1.2-0.8*swmin/stmwt)*(sumdtt5+100.0)/((430+p5*20)+100.0)));

// intercepted photosynthetically active radiation 
ipar := par*(1 - exp(-0.85 * lai));

lue := 0;  // by default
if ipar>0 then lue := pcarb/ipar;

par := 0.5*globrad;

// potential biomass production in grams/m2 /d
pcarb := 0;  // by default
if ipar>0 then pcarb := 7.5*ipar^0.6;

// photosynthetic reduction factor for low and high temperatures 
prft := prft := max(0,1 - 0.0025 * (tempm - 16)^2) ;  // by default

// soil water deficit factor
swdf1 := 1;

testcarbo := 1;  // by default
if stmwt>0 then testcarbo := 1.-(1.2-0.8*swmin/stmwt);



// Compartement Prozeduren **********


// Events *************************


// Lookup Tables **********************


// Delays **********************

