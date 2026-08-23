
psi_b_f <- function ( b, b_rest, b_sat,  m_par, n_par, alpha )
{
  # Funktion zur Berechnung des Absolutwertes der Wasserspannung (positiv)
  #  aus dem volumetrischen Wassergehalt }
  
  if ((b-b_rest)>1e-03)
  {
    z1 <- (b_sat-b_rest)/(b-b_rest)
    z2 <- z1^(1/m_par)-1
    psi_b_f <- z2^( 1/n_par)*1/alpha
  }
  if ((b-b_rest)<1e-03)
  {
    psi_b_f <- 1e5
  }
  if (b >= b_sat)
  {
    psi_b_f <- 0.0
  }
  return(psi_b_f)
}

psi_b_f.v <- Vectorize(psi_b_f)

# Funktion zur Berechnung des relativen Wassergehaltes aus der
#  Wasserspannung "Psi"

b_rel_psi_f <- function (psi = 0.5, alpha = 1, n = 1.5){
  psi <- -1*psi
  m <- 1 - 1/n
  psi <- pmax(0, psi)
  z1  <- 1+(alpha*psi)^n
  out <-  (1/z1)^m
  return(out)
}


