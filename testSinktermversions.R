rm(list = ls(all.names = TRUE))

library(soilwater)
library(dplyr)
library(ggplot2)
library(tinytex)
library(magick)
library(bibtex)
library(ggsci)
library(xml2)
library(ggpmisc)
library(tidyr)
library(patchwork)
source("Q:/HUME/HUME/RLib/DokuUtilFunctions.R")


depths <- seq(5, 200, by = 10)

RLD0 <- 4
RLDdec <- 0.08
rlds <- RLD0*exp(-RLDdec*depths)

df <- data.frame(depths, rlds)

p1 <- ggplot(df, aes(y = depths, x = rlds)) +
  geom_line(linewidth=1.5) +
  scale_y_reverse() +
  labs(title = "", y = "Depth (cm)", x = "Root Length Density (cm/cm3)") +
  theme_minimal(base_size = 12)


CompF <- c(0.5, 0.75, 1, 1.25)

df_comp <- expand.grid(depths = depths, CompF = CompF)
df_comp$rlds <- RLD0*exp(-RLDdec*df_comp$depths)
df_comp <- df_comp %>% group_by(CompF) %>% mutate(SumRLDComp = sum(rlds^CompF)) %>% ungroup()
df_comp <- df_comp %>% mutate(Sact = 0.1*5*df_comp$rlds^CompF/SumRLDComp)


p2 <- ggplot(df_comp, aes(y = depths, x = Sact, color = as.factor(CompF))) +
  geom_line(size=1.5) +
  scale_y_reverse() +
  scale_color_manual(values = c("blue", "green", "orange", "red"), labels = c("0.5", "0.75", "1", "1.25")) +
  labs(title = "", y = "Depth (cm)", x = "Pot. sink Term (mm/d)", color = "CompF") +
  theme_minimal(base_size = 12)


p <- p1 + p2
p




fn_RR <- "./Components/Soil/Documentation/GenuchtenPars_roteReihe.csv"
Params_RR <- read.table(fn_RR, header = TRUE, comment.char = "[", sep = ";", dec = ".")
Params_RR$Source <- "RR"
Params_RR$m <- 1-1/Params_RR$n

Tpot <- 5

thetas <- c(0.082,
            0.092,
            0.102,
            0.112,
            0.122,
            0.132,
            0.1452,
            0.15972,
            0.175692,
            0.1932612,
            0.21258732,
            0.2168390664,
            0.221175847728,
            0.22559936468256,
            0.230111351976211,
            0.234713579015736,
            0.23940785059605,
            0.244196007607971,
            0.244196007607971,
            0.244196007607971)



b_psi_f <- function(psi, b_sat, b_rest, alpha, n_par, m_par){

z1 <- (alpha * abs(psi))^n_par
z2 <- (1 + z1)^m_par
b_psi_f <- b_rest + (b_sat - b_rest) / z2
}



psi_b_f <- function(b, b_sat, b_rest, m_par, n_par, alpha) {
  # Calculates the absolute value of water tension (positive)
  # from volumetric water content

  if (b >= b_sat) {
    return(0.0)
  }

  if (b < b_rest) {
    return(1e5)
  }

  if ((b - b_rest) > 1e-3) {
    z1 <- (b_sat - b_rest) / (b - b_rest)
    z2 <- z1^(1 / m_par) - 1
    return(z2^(1 / n_par) / alpha)
  } else {
    return(1e5)
  }
}




Params <- Params_RR %>% filter(Bodenart == "Sl3") %>% slice(1)


psis <- Vectorize(psi_b_f)(thetas, b_sat = Params$theta_s, b_rest = Params$theta_r, m_par = Params$m, n_par = Params$n, alpha = Params$alpha)





#psis <- 1/depths^1.1*4.5e4


p <- ggplot(data.frame(depths, psis), aes(x = depths, y = psis)) +
  geom_line(size=1.5) +
  coord_flip() +
  scale_x_reverse() +
  scale_y_log10() +
  labs(title = "", x = "Depth (cm)", y = "Soil water potential (hPa)") +
  theme_minimal(base_size = 12)
p

#thetas <- swc (psi=-psis, alpha=Params_RR$alpha[1],
#              n=Params_RR$n[1],m=Params_RR$m[1],theta_sat=Params_RR$theta_s[1],
#              theta_res=Params_RR$theta_r[1], lambda = Params_RR$m[1] * Params_RR$n[1], type_swc = "VanGenuchten")
df <- data.frame(depth = depths, psi = psis, theta = thetas)

# start of decreasing water uptake
psi2 <- 200

# permanent wilting point
psi3 <- 10^4.2



FK <- swc (psi=-10^1.8, alpha=Params$alpha,
           n=Params$n,m=Params$m,theta_sat=Params$theta_s,
           theta_res=Params$theta_r, lambda = Params$m * Params$n, type_swc = "VanGenuchten")
PWP <- swc (psi=-10^4.2, alpha=Params$alpha,
            n=Params$n,m=Params$m,theta_sat=Params$theta_s,
            theta_res=Params$theta_r, lambda = Params$m * Params$n, type_swc = "VanGenuchten")

nFK <- FK-PWP

# root competition factor
CompF <- 0.5
# thickness of layer
dz <- 10

df <- df %>% mutate(rld = RLD0*exp(-RLDdec*depths), RL = rld*dz) %>% ungroup()
SumRLComp <- sum(df$rld^CompF)


df <- df %>% mutate(sinkredf = pmax(0,pmin(1, (psi-psi3)/(psi2-psi3))))
# normalized root length  i.e. the fraction of root length in the layer i to the total root length in all layers considering the competition factor CompF
df <- df %>% mutate(NRLD = (rld^CompF)/SumRLComp) %>% ungroup()


p <- ggplot(df, aes(x = depths, y = sinkredf)) +
  geom_line(size=1.5) +
  coord_flip() +
  scale_x_reverse() +
  labs(title = "", x = "Depth (cm)", y = "Reduction factor for root water uptake") +
  theme_minimal(base_size = 12)
p


# copy of df for further calculations

# df1 is used for calculating the potential sink term without considering the reduction factor for root water uptake (f~sinkred~), and the actual sink term considering f~sinkred~.

df1 <- df

#
df1$Method <- "Feddes"

# potential sink term for layer i without considering the reduction factor for root water uptake (f~sinkred~)
df1 <- df1 %>% mutate(Spot = 0.1*Tpot*NRLD)

#sum(df1$Spot)

#summary(df1$sinkredf)


df1$Sact <- df1$Spot*df1$sinkredf

df1$Tact <-  sum(df1$Sact)

df1$Tact_Tpot <- sum(df1$Sact)/(Tpot*0.1)



# df2 is with Jarvis correction factor omega

df2 <- df
df2$Method <- "Jarvis"

omega_c <- 0.7
omega <-  sum(df2$sinkredf*df2$NRLD)

df2 <- df2 %>% mutate(Spot = NRLD*0.1*Tpot*1/max(omega, omega_c)) %>% ungroup()

df2 <- df2 %>% mutate(Sact = sinkredf*NRLD*0.1*Tpot*1/max(omega, omega_c)) %>% ungroup()

df2$Tact <- sum(df2$Sact)

df2$Tact_Tpot <- df2$Tact/(Tpot*0.1)


df3 <- df


df3$Method <- "Reduction by soil water potential"


SumRLComp <- sum(df3$sinkredf*df3$rld^CompF)
df3 <- df3 %>% mutate(NRLD = (sinkredf*rld^CompF)/SumRLComp) %>% ungroup()
# check if it sums to one
#sum(df3$NDRLD)

df3 <- df3 %>% mutate(Spot = 0.1*Tpot*NRLD) %>% ungroup()
# check if it sums to Tpot*0.1
#sum(df3$Spot)

df3 <- df3 %>% mutate(Sact = Spot*sinkredf) %>% ungroup()

df3$Tact <- sum(df3$Sact)
df3$Tact_Tpot <- df3$Tact/(Tpot*0.1)


df <- rbind(df1, df2, df3)


p <- ggplot(df, aes(x = depth, y = Sact, color = Method)) +
  geom_line(size=1.5) +
  coord_flip() +
  scale_x_reverse() +
  scale_color_manual(values = c("blue", "red", "green"), labels = c("Feddes", "Jarvis", "Reduction by soil water potential")) +
  labs(title = "", x = "Depth (cm)", y = "Actual sink Term (mm/d)", color = "Method") +
  theme_minimal(base_size = 12)
p


df.av <- df %>% group_by(Method) %>% summarise(Tact = mean(Tact), Tact_Tpot=mean(Tact_Tpot)) %>% ungroup()
df.av.l <- df.av %>% pivot_longer(cols = c(Tact, Tact_Tpot), names_to = "Variable", values_to = "Value")

p <- ggplot(df.av.l, aes(x = Method, y = Value, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~Variable, scales = "free_y") +
  scale_fill_manual(values = c("lightblue", "lightcoral", "lightgreen")) +
  labs(title = "", x = "Method", y = "Value", fill = "Variable") +
  theme_minimal(base_size = 12)
p



df <- df %>% mutate(sinkredf = pmax(0,pmin(1, (psi-psi3)/(psi2-psi3))))
# normalized root length  i.e. the fraction of root length in the layer i to the total root length in all layers considering the competition factor CompF
df <- df %>% mutate(NRLD = (rld^CompF)/SumRLComp) %>% ungroup()



df3$NRLD <- df3$NRLD*df3$sinkredf

df2 <- df_psis
df2$rlds <- RLD0*exp(-RLDdec*df2$depths)
df2$sinkredf <- pmax(0,pmin(1, (df2$psis-psi3)/(psi2-psi3)))

df2 <- df2 %>% mutate(SumRLDComp = sum(sinkredf*rlds^CompF)) %>% ungroup()
df2 <- df2 %>% mutate(Sact = 0.1*5*sinkredf*df2$rlds^CompF/SumRLDComp)
df2$Sact <- df2$Sact*df2$sinkredf
df2$option <- "Reduction by soil water potential"


df <- rbind(df1[,names(df2)], df2)


p3 <- ggplot(df_psis, aes(x = depths, y = psis)) +
  geom_line(size=1.5) +
  geom_abline(xintercept = -10^1.8, linetype = "dashed", color = "blue") +
  coord_flip() +
  scale_x_reverse() +
  scale_y_log10() +
  labs(title = "", x = "Depth (cm)", y = "Soil water potential (hPa)") +
  theme_minimal(base_size = 12)
#p3


p4 <- ggplot(df_psis, aes(x = depths, y = swc)) +
  geom_line(size=1.5) +
  scale_x_reverse() +
  coord_flip() +
  geom_hline(yintercept = FK, linetype = "dashed", color = "blue", size=1) +
  geom_hline(yintercept = PWP, linetype = "dashed", color = "red", size=1) +
  labs(title = "", x = "Depth (cm)", y = "Soil water content (cm3/cm3)") +
  theme_minimal(base_size = 12)
#p4

df <- df %>% arrange(option, depths)
p5 <- ggplot(df, aes(x = depths, y = Sact, color = option)) +
  geom_line(aes(group=option),size=1.5) +
  coord_flip() +
  scale_x_reverse() +
  scale_color_manual(values = c("blue", "red"), labels = c("No reduction", "Reduction by soil water potential")) +
  labs(title = "", x = "Depth (cm)", y = "Pot. sink Term (mm/d)", color = "Option") +
  theme_minimal(base_size = 12)
#p5

df <- df %>% arrange(option, depths)
p6 <- ggplot(df, aes(x = depths, y = Sact, color = option)) +
  geom_line(aes(group=option),size=1.5) +
  coord_flip() +
  scale_x_reverse() +
  scale_color_manual(values = c("blue", "red"), labels = c("No reduction", "Reduction by soil water potential")) +
  labs(title = "", x = "Depth (cm)", y = "Actual sink Term (cm/d)", color = "Option") +
  theme_minimal(base_size = 12)

p <- (p3 + p4 )/ (p5 + p6) + plot_layout( guides = "collect") & theme(legend.position = "bottom", axis_titles="collect")

p


