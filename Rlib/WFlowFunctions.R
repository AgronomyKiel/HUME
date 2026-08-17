

sinusf <- function (Stunde=12)
  
{
  output <-  pmax(0,1.64221194*(0.5+sin(pi*((Stunde+18)/12))))
  #                   1.64221194*(0.5+sin(pi*((Stunden+18)/12)))
  return(output)
}


water_flow_func <- function  (avg_transpi_rate=4, L=10, stunde=12, 
                              sinus_f=TRUE)
  
  # avg_transpi_rate [mm/d]
  # L = # Wurzellänge in cm/ha
  #

{
  if (sinus_f == TRUE) 
  {Transpi_rate <- avg_transpi_rate * sinusf(stunde)
  if (Transpi_rate <= 1e-12)
  {Transpi_rate <- 0.0}}
  else
  {Transpi_rate <- avg_transpi_rate}
  Es <- Transpi_rate * 1e7/86400.0 # from mm/d to cm3/s
  output <- Es / L # from cm3/s to cm3/(cm*s))
  # output in cm3/(cm*s)
  return(output)
}


iwmax <- function  (b=0.25, bmin=0, Dw=1e-4, xl=2, a=0.02)
  
{
  output <- ifelse((b-bmin) <= 0.0, 0.0, ((b-bmin)*2*pi*Dw)/(log(xl/(2.1*a))))
#   output <-  ((b-bmin)*2*pi*Dw)/(log(xl/(2.1*a)))
  return(output)
}


bnf <- function (ba=0.15, Iw=1e-5, Dw=1e-4, Radius=0.4, a=0.04)
{  
  bnf <- ba+Iw/(2*pi*Dw)*log(Radius/a)
  return(bnf)
}



baf <- function  (b=0.25, Iw=1e-6, Dw=1e-5, xl=2, a=0.02)
  
{
  #  output<- pmax(0, b-(Iw/(2*pi*Dw)*log(xl/(2.1*a))))
  output<-  b-(Iw/(2*pi*Dw)*log(xl/(2.1*a)))
  return(output)
}

area_func <- function  (Laenge=1e10, Radius=0.04)
{
  area_func <- Laenge * 2 * pi * Radius
  return(area_func)
}

Lrv_func <- function  (Gesamtwurzellaenge=10, Wurzeltiefe=60)
{
  Lrv_func <- ( Gesamtwurzellaenge * 10 ) / Wurzeltiefe
  return(Lrv_func)
}

abstand_func <- function  (Wurzelaengendichte=0.1)
{
  abstand_func <- 1 / sqrt(pi * Wurzelaengendichte)
  return(abstand_func)
}


Volumen_func <- function  ( Zylinderradius=2, r_root=0.02)
  
{
  Volumen_func <- pi*(Zylinderradius)^2-pi*(r_root)^2
  return(Volumen_func)
}


Radius_arr_func <- function  (Zylinderradius=2, r_root=0.02,
                              max_ndx=20, akt_ndx=10)
  
{
  Radius_arr_func <- ((Zylinderradius-r_root)/max_ndx)*(akt_ndx-1)
  + r_root
  return(Radius_arr_func)
}



f_rad_arr <- function (zylinderradius=1, wurzelradius=0.02,
                       n  =20)
{  
  fromval <- log(wurzelradius)
  toval <- log(zylinderradius)
  steps <- n 
  interval <- (fromval-toval)/steps 
  log_rs <- seq(from=fromval, to = toval, by=-interval)
  rads <- exp(log_rs)
  return(rads)
}


psi_b_f <- function (b=0.2, b_rest=0.0, b_sat=0.35,
                     n_par=1, alpha=0.2)
{
  # Funktion zur Berechnung des Absolutwertes der Wasserspannung (positiv)
  #  aus dem volumetrischen Wassergehalt }
  
  m_par <- 1-1/n_par 
  out <- ifelse(b >= b_sat, 0.0, {
    z1 <- (b_sat-b_rest)/(b-b_rest)
    z2 <- z1^(1/m_par)-1
    out <- z2^(1/n_par)*1/alpha
  })
  return(out)
  }

psi_b_f.v <- Vectorize(psi_b_f)

b_psi_f <- function ( psi, b_rest=0.0, b_sat=0.35,
                      n_par=1, alpha=0.2){


# Funktion zur Berechnung des volumetrischen Wassergehaltes (b)
#  aus der Wasserspannung (psi) 

#if(psi <= 0.0) {theta <-  b_sat} 
  m_par <- 1-1/n_par
  z1 <- (alpha*abs(psi))^n_par
  z2 <- (1+z1)^m_par
  theta <-  b_rest+(b_sat-b_rest)/z2

}


# returns the matric flux potential, implementation using the integrate function
MFP <- function (h, soil.par)
  # default parameters are for sl3  
{
  m <- 1-1/soil.par$n # Mualem model
  MFP <- integrate(f = khy,lower = -10^4.2, upper = h, soil.par$v, soil.par$ksat, soil.par$alpha, soil.par$n, 
                   soil.par$theta_sat, soil.par$theta_res, rel.tol = 0.000000001)
  MFP <- MFP$value
  #return MFP
}  


##### function for setting up a data frame with matrix flux potential values over the whole range of psi values #####

set_MFP_df <- function(soil){
  
  fromval <- log10(10^4.2)
  toval <- log10(0.1)
  steps <- 100
  interval <- (fromval-toval)/steps 
  logpsivals <- seq(from=fromval, to = toval, by=-interval)
  psivals <- -10^logpsivals
  df <- data.frame(psivals = psivals, kuvals=rep(0, length(psivals)))
  diffs <- diff(psivals)
  kuvals <- khy(psi=psivals, v = soil$v, ksat = soil$ksat, alpha = soil$alpha, n=soil$n,
                m=1-1/soil$n, theta_sat = soil$theta_sat, theta_res = soil$theta_res)
  
  # calculation of summed ku values for the whole range of 
  sumku <- array(1:length(psivals))
  sumku[1] <- kuvals[1]
  # integration with trapez-approach
  for (i in 2:length(psivals)){
    sumku[i] <- sumku[i-1]+(kuvals[i-1]+kuvals[i])/2*diffs[i-1]
  }
  
  df$kuvals <- khy(psi=df$psivals, v = soil$v, ksat = soil$ksat, alpha = soil$alpha, n=soil$n,
                   m=1-1/soil$n, theta_sat = soil$theta_sat, theta_res = soil$theta_res)
  df$sumku[1] <- kuvals[1]
  for (i in 2:length(df$psivals)){
    df$sumku[i] <- df$sumku[i-1]+(df$kuvals[i-1]+df$kuvals[i])/2*diffs[i-1]
  }
  return(df)
}


#### a function for calculation of MFP using a data frame with a series of MPF values as input ####
MFP_f <- function(psi, df){
  MFP <- approx(x=df$psivals, y =df$sumku, xout = psi)$y
  return(MFP)
}



#### a function for calculation of matrix tension (psi) from MFP using a data frame with a series of MPF values as input ####
psi_f <- function(MFP, df){
  MFP <- pmax(MFP, min(df$sumku))
  psi <- unlist(approx(x=df$sumku, y =df$psivals, xout = MFP )$y)
  return(as.numeric(psi))
} 



MFP_Iwmax_f <- function(MFP_, xl, r_root){
  iwmax <-   (4*pi*xl^2*MFP_)/((r_root^2-0.56^2*xl^2)+2*(xl^2+r_root^2)*log((0.56*xl)/r_root))
  return(iwmax)
}  


MFP0_f <- function(MFP_, xl, r_root, Iw){

  MFP0 <- pmax(0, MFP_- Iw/(2*pi*xl^2)*((r_root^2-(0.56*xl)^2)/2+(xl^2+r_root^2)*log((0.56*xl)/r_root)))
  return(MFP0)
}



MFP_r_f <- function(MFP0, Iw, r_root, r, xl){
  
  MFP_r <- MFP0 + Iw/(2*pi*xl^2)*((r_root^2-rads^2)/2+(xl^2+r_root^2)*log(rads/r_root))
  return(MFP_r)
  }


Iw_Dw_f <- function(theta=0.2, theta_pwp, theta_r=0.15, Dw=10, xl=2, a=0.02)
  {
    if (theta-theta_pwp < 0.0)  {output <- 0.0}
    else  {output <- ((theta-theta_r)*2*pi*Dw)/(log(xl/(2.1*a)))}
    return(output)
  }


Iw_ku_f <- function(psi=-100, psi_root=-150, ku=0.1, a=0.02,  xl=2)
{
#  output <- ifelse((-psi_root >= 10^4.2),  0.0,
#     2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a))))
  output <- pmax(0.0,2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a))))
#  output <- 2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a)))
  return(output)
}

Iw_ku_f()

  
Uptake_ku_f <- function( psi_root=-101, psi=-100, ku=0.1, a=0.02, lrv=0.1, dz=10){

  xl <- 1/sqrt(pi*lrv)
#  suptake <- sum(Iw_ku_f(psi=psi, psi_root=psi_root , ku=ku, a=a, xl)*lrv*dz)
  suptake <- sum(pmax(0.0,2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a))))*lrv*dz)/length(lrv)
  return(suptake)
}


Balance_func <- function (psi_root=-110, psi=-100, T=1, ku=0.1, a=0.02, lrv=0.1, dz=10)
{
#  Balance <- T-Uptake_ku_f(psi, psi_root, ku, a, lrv, dz)
  Balance <- abs(as.numeric(T-sum(pmax(0.0,2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a))))*lrv*dz)/length(lrv)))
#  Balance <- abs(as.numeric(T-sum(pmax(0.0,2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a))))*lrv*dz)))
  #  Balance <- as.numeric(T-sum(pmax(0.0,2*pi*ku*(psi-psi_root)/(log(xl/(2.1*a))))*lrv*dz)/length(lrv))
  return(Balance)
}


psi_a_func <- function (psi=-100, T=0.4, ku=0.1, a=0.02, lrv=0.1, dz=10)
{
  #  Balance <- T-Uptake_ku_f(psi, psi_root, ku, a, lrv, dz)
#  L <- lrv*dz/length(lrv)
  n <- length(lrv)
  L <- lrv*dz
  xl <- 1/sqrt(pi*lrv)
  z0 <- (2*pi*ku)/(log(xl/(2.1*a)))*L/n
  z1 <- psi*z0
  psi_root <- (sum(z1)-T)/(sum(z0))
  return(psi_root)
}


T<- 0.4
Lrv <- seq(0.01, 0.1, 0.01)
xl <- 1/sqrt(pi*Lrv)


psi_a <- psi_a_func(lrv=Lrv, psi = -100, T = 0.4, ku = 0.1, a = 0.02, dz = 10)

Iw_ku_f(psi_root = psi_a, ku = 0.1, xl = xl)

Trans <- Uptake_ku_f ( psi_root=psi_a, psi=-100, ku=0.1, a=0.02, lrv=Lrv, dz=10)
  

Balance_func(psi_root = -109, lrv = seq(0.01, 0.1, 0.01), ku=seq(0.1, 1, 0.1))

#psi_root <- seq(-100, -500, -1)

#Balance <- psi_root_func(psi_root = psi_root)

#plot(psi_root, Balance)


