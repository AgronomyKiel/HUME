

{ -------------------------------------------------------------------- }
{ -------------------------   MODUL TRDIAG  -------------------------- }
{ ------------ L”sung eines tridiagonalen Gleichungssystems ---------- }
{ ----------- Aus Formelsammlung zur numerischen Mathematik ---------- }
{--------------------------------------------------------------------- }


function trdiag (rep          : boolean;   {  Wiederholungsflagge      }
                 max_n, min_n : integer;   {  Dimension der Matrix     }
                 var lower,                {  Subdiagonale             }
                     diag,                 {  Diagonale                }
                     upper,                {  Superdiagonale           }
                     b        : array_type {  Rechte Seite des Systems }
                            ) : byte;      {  Fehlerparameter          }
{ ==================================================================== }
{   trdiag bestimmt die Loesung x des linearen Gleichungssystems       }
{   A * x = b mit tridiagonaler n x n Koeffizientenmatrix A, die in    }
{   den 3 Vektoren lower, upper und diag wie folgt abgespeichert ist:  }
{                                                                      }
{        ( diag[min_n] upper[min_n]    0        0  .   .     .   0          ) }
{        ( lower[min_n+1] diag[min_n+1]   upper[min_n+1]   0      .     .   .          ) }
{        (   0      lower[min_n+2]  diag[min_n+2]  upper[min_n+2]   0       .          ) }
{   A =  (   .        0       lower[5]  .     .       .              ) }
{        (   .          .           .        .     .      0          ) }
{        (   .              .           .        .      .            ) }
{        (                    .           .         . upper[max_n-1] ) }
{        (   0 .   .    .   .     0     lower[max_n]    diag[max_n]  ) }
{ ==================================================================== }
{    Anwendung:                                                        }
{       Vorwiegend fuer diagonaldominante Tridiagonalmatrizen, wie     }
{       sie bei der Spline-Interpolation auftreten.                    }
{       Fuer diagonaldominante Matrizen existiert immer eine LU-       }
{       Zerlegeung; fuer nicht diagonaldominante Tridiagonalmatrizen   }
{       sollte die Funktion band vorgezogen werden, da diese mit       }
{       Spaltenpivotsuche arbeitet und daher numerisch stabiler ist.   }
{ ==================================================================== }
{   Eingabeparameter:                                                  }
{                                                                      }
{    Name    Typ         Bedeutung                                     }
{   ----------------------------------------------------------------   }
{    rep     byte        Aufrufart von trdiag                          }
{                        = True : Bestimmung der Zerlegungsmatrix und  }
{                                 Berechnung der Loesung des Systems   }
{                        = False: Nur Loesen des Gleichungssystems;    }
{                                 zuvor muss die Zerlegungsmatrix be-  }
{                                 stimmt sein.                         }
{    n       integer     n > 1; Anzahl der Komponenten von lower       }
{                        diag, upper                                   }
{                        bei rep = False:                              }
{    lower   RealVector  untere Nebendiagonale; lower[i], i=1(1)n-1    }
{    diag    RealVector  Hauptdiagonale;        diag[i],  i=0(1)n-1    }
{    upper   RealVector  obere Nebendiagonale;  upper[i], i=0(1)n-2    }
{    b       RealVector  Rechte Seite des Systems: b[i], i=0(1)n-1     }
{                                                                      }
{   Ausgabeparameter:                                                  }
{    Name    Typ         Bedeutung                                     }
{   ---------------------------------------------------------------    }
{    lower   RealVector  )                                             }
{    diag    RealVector  ) enthalten die LU-Zerlegung                  }
{    upper   RealVector  )                                             }
{    b       RealVector  Loesungsvektor des Systems: b[i], i=0(1)n-1   }
{                        det(A) = diag[0] *..* diag[n-1].              }
{   Rueckgabewert:                                                     }
{      = 0 : alles ok                                                  }
{      = 1 : n < 2 oder n > MAXDIM_1 gewaehlt                          }
{      = 2 : LU-Zerlegung existiert nicht                              }
{ ==================================================================== }

var   i : integer;

begin

  if not(rep) then                           {  Wenn rep:=false ist,   }
  begin                                      {  Dreieckzerlegung der   }
    for i:= min_N+1 to max_n do                       {  Matrix bestimmen       }
    begin
      if abs(diag[i-1]) < 1e-16  then       {  Wenn ein diag[i] = 0   }
        begin trdiag := 2; exit end;        {  ist, ex. keine Zerle-  }
          lower[i] := lower[i] / diag[i-1];      {  gung.                  }
          diag[i] := diag[i] - lower[i] * upper[i-1];
        end;
      if abs (diag[max_n]) < 1e-16  then
        begin trdiag := 2; exit end;
    end;
    for i:= min_N+1 to max_n do                        {   Vorwaertselimination   }
      b[i] := b[i] - lower[i] * b[i-1];
      b[max_n] := b[max_n] / diag[max_n];             {  Rueckwaertselimination  }
    for i:= max_n-1 downto min_n do
      b[i] := (b[i] - upper[i] * b[i+1]) / diag[i];
      trdiag := 0;
 end;

{ --------------------------  ENDE TRDIAG  --------------------------- }
