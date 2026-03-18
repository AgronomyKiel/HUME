
f_psired <- function(psi_i, psi0, psi_crit){
  if(psi_i <= psi_crit){
    return(1)
  } else if(psi_i > psi_crit && psi_i < psi0){
    return((psi_i-psi0)/(psi_crit-psi0))
  } else {
    return(0)
  }
}


f_logpsired <- function(psi_i, psi0, psi_crit){
  if(psi_i >= psi_crit){
    return(1)
  } else if(psi_i < psi_crit && psi_i > psi0){
    return((log(psi_i)-log(psi0))/(log(psi_crit)-log(psi0)))
  } else {
    return(0)
  }
}



#' Title
#'
#' @param psi soil water matrix potential []
#' @param PotTrans potential transpiration [mm/d]
#' @param psi2 threshold potential for reduction of transpiration [mm/d]
#' @param feddes_a increase of critical soil water tension at high transpiration rate (Tpot>=) Trefhigh [hPa]
#' @param Trefhigh value of potential transpiration rate (Tpot) above which the critical soil water tension is equal to feddes_a [mm/d]
#' @param Trefhigh value of potential transpiration rate (Tpot) below which the critical soil water tension is equal to psi2 [mm/d]
#' @param logscale logical, if TRUE the reduction factor is calculated on a log scale, otherwise on a linear scale
#'
#' @returns
#' @export
#'
#' @examples
Feddes_redf <- function(psi, PotTrans, psi2_lowtrans, psi2_hightrans, Trefhigh, Treflow, logscale=TRUE){

  psi3 <- 10^4.2
  psiFK <- 10^1.8

  # calculation of an minimum lowered psi2 value under high transpiration conditions
  #
  psi2_hightrans <- pmax(psiFK, psi2_hightrans)

  # high transpiration > low value of psi2, low transpiration > high value of psi2
  if (PotTrans >= Trefhigh) {
    psi2_ <- psi2_hightrans
  }
  if (PotTrans < Treflow) {
     psi2_ <- psi2_lowtrans
  }

  # linear interpolation of psi2 between low and high transpiration conditions

  if (PotTrans >= Treflow && PotTrans < Trefhigh) {
    psi2_ <- psi2_lowtrans - (PotTrans - Treflow)/ (Trefhigh - Treflow) * ((psi2_lowtrans - psi2_hightrans) )
  }

  if(logscale){
    red_f <- pmax(0,min(1, (log10(psi)-log10(psi3))/(log10(psi2_)-log10(psi3))))
  } else {
    red_f <- pmax(0,min(1, (psi-psi3)/(psi2_-psi3)))

  }
  return(red_f)
}