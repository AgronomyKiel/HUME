

function KSFromTextureClass_RR(TC: TTextureClass): real;
{Rote Reihe, Wessolek Teil I-II, 
Teil 1: Tab.13: average saturated hydraulic conductivity for various soil texture classes and bulk densities > TRD 1.3, 1.5, 1.7 &
Teil 2: Tab. 7: Beziehung zwischen Wasserleitfähigkeit und Trockenrohdichte > TRD 1.42, 1.63-1.65, 1.83-1.85 (eff. LD 2, 3, 4)}

/// Optionen wären 1.3, 1.42, 1.5, 1.64, 1.7,
begin
  case TC of
{Trockenrohdichte 1.3}
    Ss: result := 375;
    mS: result := 375;
    mSgs: result := 375;
    mSfs: result := 375;
    fS: result := 250;
    fSms: result := 250;
    Sl2: result := 160;
    Sl3: result := 100;
    Sl4: result := 80;
    Slu: result := 70;
    St2: result := 180;
    St3: result := 110;
    Su2: result := 185;
    Su3: result := 95;
    Su4: result := 85;
    Ls2: result := 50;
    Ls3: result := 60;
    Ls4: result := 70;
    Lt2: result := 40;
    Lt3: result := 20;
    Lts: result := 30;
    Lu: result := 35;
    Uu: result := 30;
    Uls: result := 35;
    Us: result := 30;
    Ut2: result := 30;
    Ut3: result := 30;
    Ut4: result := 30;
    Tt: result := 10;
    Tl: result := 20;
    Tu2: result := 18;
    Tu3: result := 20;
    Tu4: result := 25;
    Ts2: result := 30;
    Ts3: result := 35;
    Ts4: result := 50;
    else result := 20.0;
  end; {of case}
  
  
  begin
  case TC of
{Trockenrohdichte 1.42}
    Ss: result := 335;
    mS: result := 335;
    mSgs: result := 335;
    mSfs: result := 335;
    fS: result := 195;
    fSms: result := 195;
    Sl2: result := 130;
    Sl3: result := 85;
    Sl4: result := 78;
    Slu: result := 68;
    St2: result := 150;
    St3: result := 110;
    Su2: result := 140;
    Su3: result := 83;
    Su4: result := 75;
    Ls2: result := 52;
    Ls3: result := 57;
    Ls4: result := 70;
    Lt2: result := 56;
    Lt3: result := 30;
    Lts: result := 35;
    Lu: result := 35;
    Uu: result := 27;
    Uls: result := 35;
    Us: result := 27;
    Ut2: result := 35;
    Ut3: result := 35;
    Ut4: result := 35;
    Tt: result := 43;
    Tl: result := 43;
    Tu2: result := 43;
    Tu3: result := 43;
    Tu4: result := 43;
    Ts2: result := 47;
    Ts3: result := 47;
    Ts4: result := 62;
    else result := 20.0;
  end; {of case}


begin
  case TC of
{Trockenrohdichte 1.5}
    Ss: result := 280;
    mS: result := 250;
    mSgs: result := 250;
    mSfs: result := 250;
    fS: result := 150;
    fSms: result := 150;
    Sl2: result := 100;
    Sl3: result := 70;
    Sl4: result := 50;
    Slu: result := 40;
    St2: result := 120;
    St3: result := 60;
    Su2: result := 125;
    Su3: result := 60;
    Su4: result := 55;
    Ls2: result := 30;
    Ls3: result := 35;
    Ls4: result := 40;
    Lt2: result := 25;
    Lt3: result := 10;
    Lts: result := 20;
    Lu: result := 20;
    Uu: result := 18;
    Uls: result := 20;
    Us: result := 15;
    Ut2: result := 15;
    Ut3: result := 15;
    Ut4: result := 12;
    Tt: result := 0.5;
    Tl: result := 3;
    Tu2: result := 5;
    Tu3: result := 5;
    Tu4: result := 5;
    Ts2: result := 15;
    Ts3: result := 20;
    Ts4: result := 30;
    else result := 20.0;
  end; {of case}
  
  
    begin
  case TC of
{Trockenrohdichte 1.63-1.65}
    Ss: result := 205;
    mS: result := 205;
    mSgs: result := 205;
    mSfs: result := 205;
    fS: result := 105;
    fSms: result := 105;
    Sl2: result := 95;
    Sl3: result := 53;
    Sl4: result := 44;
    Slu: result := 37;
    St2: result := 92;
    St3: result := 55;
    Su2: result := 75;
    Su3: result := 45;
    Su4: result := 43;
    Ls2: result := 30;
    Ls3: result := 34;
    Ls4: result := 45;
    Lt2: result := 38;
    Lt3: result := 15;
    Lts: result := 21;
    Lu: result := 21;
    Uu: result := 15;
    Uls: result := 19;
    Us: result := 12;
    Ut2: result := 17;
    Ut3: result := 17;
    Ut4: result := 18;
    Tt: result := 13;
    Tl: result := 13;
    Tu2: result := 13;
    Tu3: result := 13;
    Tu4: result := 13;
    Ts2: result := 25;
    Ts3: result := 25;
    Ts4: result := 30;
    else result := 20.0;
  end; {of case}
  
  
begin
  case TC of
{Trockenrohdichte 1.7}
    Ss: result := 150;
    mS: result := 150;
    mSgs: result := 150;
    mSfs: result := 150;
    fS: result := 90;
    fSms: result := 90;
    Sl2: result := 50;
    Sl3: result := 40;
    Sl4: result := 30;
    Slu: result := 20;
    St2: result := 60;
    St3: result := 30;
    Su2: result := 65;
    Su3: result := 30;
    Su4: result := 30;
    Ls2: result := 15;
    Ls3: result := 20;
    Ls4: result := 25;
    Lt2: result := 10;
    Lt3: result := 3;
    Lts: result := 5;
    Lu: result := 8;
    Uu: result := 4;
    Uls: result := 7;
    Us: result := 5;
    Ut2: result := 3;
    Ut3: result := 3;
    Ut4: result := 2;
    Tt: result := 0.05;
    Tl: result := 0.5;
    Tu2: result := 0.5;
    Tu3: result := 0.5;
    Tu4: result := 1;
    Ts2: result := 5;
    Ts3: result := 8;
    Ts4: result := 10;
    else result := 20.0;
  end; {of case}
  

     begin
  case TC of
{Trockenrohdichte 1.83-1.85}
    Ss: result := 120;
    mS: result := 120;
    mSgs: result := 120;
    mSfs: result := 120;
    fS: result := 60;
    fSms: result := 60;
    Sl2: result := 50;
    Sl3: result := 30;
    Sl4: result := 25;
    Slu: result := 18;
    St2: result := 56;
    St3: result := 30;
    Su2: result := 39;
    Su3: result := 24;
    Su4: result := 23;
    Ls2: result := 16;
    Ls3: result := 19;
    Ls4: result := 25;
    Lt2: result := 14;
    Lt3: result := 7;
    Lts: result := 11;
    Lu: result := 11;
    Uu: result := 5;
    Uls: result := 8;
    Us: result := 4;
    Ut2: result := 6;
    Ut3: result := 6;
    Ut4: result := 5;
    Tt: result := 1;
    Tl: result := 1;
    Tu2: result := 1;
    Tu3: result := 1;
    Tu4: result := 1;
    Ts2: result := 11;
    Ts3: result := 11;
    Ts4: result := 15;
    else result := 20.0;
  end; {of case}