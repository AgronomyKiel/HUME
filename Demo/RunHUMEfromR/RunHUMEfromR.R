# Create Directory for Ini-Files if non-existent
mainDir <- 'Q:/HUME/HUME/Demo/RunHUMEfromR'
subDir <- 'INI'
if (!file.exists(subDir)){dir.create(file.path(mainDir, subDir))}
iniDir <- paste(mainDir, subDir, sep = "/")

# Create Output-Directory if non-existent
# Ausgabeverzeichnis muss existieren, deswegen wird es hier erzeugt!
mainDir <- 'P:'
subDir <- 'RunHUMEfromR'
if (!file.exists(subDir)){dir.create(file.path(mainDir, subDir))}
OutDir <- paste(mainDir, subDir, sep = "/")

# Get fn-File-Name
# NOTE: Insert Code to create Ini-File-Structure her!
fnFileName <- "WheatDevelop.fn"

# Get Name of the EXE-File and execute it with parameters
# 1) fn-File
# 2) Output-Directory
HUMEexeFN <- 'Q:/HUME/HUME/Demo/RunHUMEfromR/WheatDevelopPrj.exe'
fnFile <- paste(iniDir, fnFileName, sep = "/")
eStr <- paste(HUMEexeFN,gsub("/", "\\\\", fnFile),gsub("/", "\\\\", OutDir), sep = " ")
system(eStr)

# Read Model output
fn <- paste(OutDir,'state','WheatDevelop_Development1_dat.csv', sep = '/')

df <- read.csv(fn,header = T)[-1,]
df$Time <- as.POSIXct(as.numeric(as.character(df$Time))*86400, origin="1899-12-30",tz="GMT")

# and plot it
library(ggplot2)
plot.EC <- ggplot(df, aes(x=Time, y=ec)) +
  theme_bw() +
  geom_line()
plot.EC

