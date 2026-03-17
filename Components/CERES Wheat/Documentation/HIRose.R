# remove all objects from the environment
rm(list = ls())
library(ggplot2)
library(dplyr)
library(tidyr)



pintercept <- 	33.989
pBioPostAnth <- 	-0.48536
pBioPreAnth <-	0.50254
pBioPreAnth2 <-	-4.6665E-05


# create a data frame with the values of BioPreAnth and BioPostAnth
df <- expand.grid(BioPreAnth = seq(600, 1100, by = 100), BioPostAnth = seq(300, 800, by = 100))

# calculate the predicted values of BioPreAnth2 using the regression equation
df$Translocation <- pintercept + pBioPostAnth * df$BioPostAnth + pBioPreAnth * df$BioPreAnth + pBioPreAnth2 * (df$BioPreAnth^2)

df$HI <- (df$BioPostAnth + df$Translocation)/(df$BioPreAnth + df$BioPostAnth)



# create a contour plot of the predicted values
ggplot(df, aes(x = BioPreAnth, y = BioPostAnth, z =HI)) +
  geom_contour_filled() +
  labs(title = "Contour Plot of HI", x = "BioPreAnth", y = "BioPostAnth") +
  theme_minimal(base_size = 18)



