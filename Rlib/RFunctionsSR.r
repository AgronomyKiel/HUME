
swc_ <- function (psival=100, df.par, Texture){
  p <- df.par[as.character(df.par$Texture)==as.character(Texture),]
  swc <-  swc(psi = psival, alpha = p$alpha, n = p$n, m = 1-1/p$n, theta_sat =p$theta_s,
              theta_res = p$theta_r, type_swc = "VanGenuchten")
  return(swc)
}