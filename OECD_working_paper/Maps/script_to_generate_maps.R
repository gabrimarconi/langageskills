


setwd("C:/Users/Documents/FL/NewMaps")

### for german, i missi the right file with the fl proportion categories. i need to generate it based on another file
x <- read.csv("German_de_T_occu.csv")
fltable_nuts <- x[!duplicated(x$nuts3_id),]
 # generate a categorical variable for the proportion of ads requiring the foreign language
  fltable_nuts$catprop <- floor(100*as.numeric(fltable_nuts$prop))
  fltable_nuts$catprop[fltable_nuts$catprop>9] <- 10*floor(fltable_nuts$catprop[fltable_nuts$catprop>9]/10)
  fltable_nuts$catprop <- fltable_nuts$catprop/100
  fltable_nuts$catprop[fltable_nuts$catprop>.7] <- .7
  fltable_nuts$catprop <- paste0(">", as.character(fltable_nuts$catprop))
  fltable_nuts <- fltable_nuts[order(fltable_nuts$prop, decreasing = T),]
  fltable_nuts <- fltable_nuts[, c("nuts3_id", "nuts3", "country_id", "prop", "catprop")]
write.csv(fltable_nuts, "German_de_T.csv", row.names = F)
#View(x)





### set up (load libraries and fonts; set some useful globals)

# install this if not yet done
#install.packages("ggplot2")
#install.packages("devtools")
#install.packages("vctrs")
#install.packages("devEMF")
require(devtools)

# load these libraries
library("ggplot2")
library(devEMF)

# install previous version of eurostat package, which i use for the maps
install_version("eurostat", version = "3.1.5", repos = "http://cran.us.r-project.org")
# cool link to reproduce Eurostat's regional maps:
#https://rstudio-pubs-static.s3.amazonaws.com/210495_a135718dda984805ada63d61bff87800.html#2_fertility_rate
library("eurostat")

# add Arial narrow as a font
windowsFonts("Arial Narrow" = windowsFont("Arial Narrow"))
#install.packages("showtext")
library(showtext)
font_add(family = "Arial Narrow", regular = "C:/Windows/Fonts/ARIALN.TTF")

#wih_oja_blended_v1_2021q4_r20220224
#wih_oja_blended_v1_2022q4_r20230130

# set some useful globals for maps

occup_average <- T
mytable <- "wih_oja_blended_v1_2021q4_r20220224"
myyear <- "2021"



### calculate cell sizes at NUTS3 level

nf <- read.csv("English_en_T_occu.csv")
nf <- nf[nf$nuts3_id!="",]
nfs <- data.frame(nuts3_id = nf$nuts3_id[duplicated(nf$nuts3_id)==F], nuts3_name = nf$nuts3[duplicated(nf$nuts3_id)==F])
nfs$n <- sapply(nfs$nuts3_id, function(r) {sum(nf$total[nf$nuts3_id==r], na.rm = T)})
dim(nfs)
nfs$n[nfs$n<100]
exclude_name <- nfs$nuts3_name[nfs$n<100]
exclude_id <- nfs$nuts3_id[nfs$n<100]





### choose language for which you want to do the chart and set related globals

#
foreign <- "English"
adtext <- "en"
fltable_nuts <- read.csv("English_en_T.csv")
#
foreign <- "Chinese"
adtext <- "le"
fltable_nuts <- read.csv("Chinese_le_T.csv")
#
foreign <- "German"
adtext <- "de"
fltable_nuts <- read.csv("German_de_T.csv")
#
foreign <- "French"
adtext <- "fr"
fltable_nuts <- read.csv("French_fr_T.csv")
#
foreign <- "Spanish"
adtext <- "es"
fltable_nuts <- read.csv("Spanish_es_T.csv")
#
foreign <- "AtLeast1FL"
adtext <- "http://data.europa.eu/esco/skill/L1"
fltable_nuts <- read.csv("AtLeast1FL_l1_T.csv")



### preliminary work for charts

# exclude nuts3 with n<100
dim(fltable_nuts)
fltable_nuts <- fltable_nuts[!fltable_nuts$nuts3_id %in% exclude_id,]
dim(fltable_nuts)

# generate fake cyprus data with all categories. cyprus will be excluded from the chart, but this helps stabilise the colours
allcats <- c(">0.7", ">0.6",  ">0.5",  ">0.4",  ">0.3",  ">0.2",  ">0.1",  ">0.09", ">0.08", ">0.07", ">0.06", ">0.05", ">0.04", ">0.03", ">0.02", ">0.01", ">0")
x <- do.call(rbind, lapply(1:17, function(i) {fltable_nuts[grep("CY", fltable_nuts$nuts3_id),]}))
x$catprop <- allcats
fltable_nuts <- rbind(fltable_nuts, x)

# merge with the geo information needed to draw maps, using Eurostat's function
fltable_nuts_geo <- merge_eurostat_geodata(data=fltable_nuts,geocolumn="nuts3_id",resolution = "20", output_class = "df", all_regions = FALSE) # old version of the package

  # draw map
  # (NB: you can find a list of R colours here: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/   )
  # write footnotes
  mynote0 <- paste0("\nThe estimated proportions include both ads written in ", foreign, " and ads explicitly requiring ", foreign)
  if (foreign == "Chinese" | foreign == "at least one foreign language") {mynote0 <- paste0("\nThe estimated proportions include ads explicitly requiring ", foreign)}
  mynote1 <- paste0("Notes: Average proportion across all ads")
  if (occup_average==T) {mynote1 <- "Note: Average across the proportions estimated for each 3-digit ISCO occupational category"}
  out_of_map <- fltable_nuts_geo[(fltable_nuts_geo$long < (-12) | fltable_nuts_geo$long > 30) & duplicated(fltable_nuts_geo$nuts3_id)==F, c("nuts3", "prop")]
  out_of_map$note <- paste0(out_of_map$nuts3, " ", round(as.numeric(out_of_map$prop), 2))
  out_of_map$length <- nchar(out_of_map$note)
  out_of_map$lengthcum <- apply(as.matrix(1:dim(out_of_map)[1]),1,function(r) {sum(out_of_map$length[1:r])+16})
  out_of_map$group <- ceiling(out_of_map$lengthcum/100)
  mylist <- lapply(1:9, function(x) {paste0(out_of_map$note[out_of_map$group==x], collapse = ", ")})
  mynote2 <- paste0("\nNot in the map:", paste0("  ", do.call("cbind", mylist[mylist!=""]), collapse = "\n"))
  mynote3 <- paste0("\nThe following six regions have been excluded because of insufficient data (number of ads < 100): ", paste0(exclude_name, collapse = ", ") )
  mynote4 <- "\n(C) EuroGeographics for the administrative boundaries \n Map produced in R with a help from Eurostat-package <github.com/ropengov/eurostat/>"
  mynote2 <- paste0(unlist(strsplit(mynote2, split="Κύπρος|Hierro"))[c(1,3)], collapse = "El Hierro")
  mynote2 <- gsub(", Fuerteventura", "\n  Fuerteventura", mynote2)
  mynote2 <- gsub(", NA NA, NA NA", "", mynote2)
  mynote3 <- gsub(",Kreisfreie Stadt", "", gsub(", Kreisfreie Stadt", "", mynote3))

  
  # base names for saving notes and charts
  skillname <- gsub("/|:|\\.| ","",foreign)
  skillname <- substr(skillname, (nchar(skillname)-10),(nchar(skillname)))
  adlang <- gsub("/|:|\\.","",adtext)
  adlang <- substr(adlang, (nchar(adlang)-1),(nchar(adlang)))
  basename <- paste0(skillname,"_",adlang,substr(as.character(occup_average),1,1),"_",myyear,substr(mytable,27,31))
  
  # save notes
writeLines(paste0(mynote2, "\n", mynote3, "\n", mynote4), paste0(basename, ".txt"))  
  
    

###  # generate chart
  mymap <- ggplot(data=fltable_nuts_geo, aes(x=long,y=lat, group=group)) +
    geom_polygon(aes(fill=catprop),color="dim grey", linewidth=.1) +
    scale_fill_manual(values=c("#993333", "#CC3300", "#FF5500", "#FF7700","#FF9900", "#FFCC00", "#FFFF00","#FFFF99", "#FFFFCC", "#CCFFFF", "#99FFFF", "#00FFFF", "#00CCFF","#0099FF", "#0066FF", "#0033FF", "#003399")) +
    lims(x = c(-12,30), y = c(35,70)) +
      theme(
	axis.title =  element_blank(),
	legend.title = element_blank(),
      legend.text=element_text(family = "Arial Narrow", size = 10),
	legend.position="bottom"
    ) + guides(fill = guide_legend(nrow = 1, label.vjust = 0, label.position = "top"))
mymap


  mymap <- ggplot(data=fltable_nuts_geo, aes(x=long,y=lat, group=group)) +
    geom_polygon(aes(fill=catprop),color="dim grey", linewidth=.1) +
    scale_fill_manual(values=c('#6A1B9A', '#8B73B3', '#B06CDE', '#BF7BA0', '#C7B2D6', '#CF9CEE', '#ADCEED', '#83D2E3', '#53B7E8', 
                               '#A9D7A5', '#D0E39C', '#BEF64B', '#A7CE39', '#7EE034', '#1FDE5A', '#448114', '#1F6E5A')) +
    lims(x = c(-12,30), y = c(35,70)) +
      theme(
	axis.title =  element_blank(),
	axis.text =  element_blank(),
	legend.title = element_blank(),
      legend.text=element_text(family = "Arial Narrow", size = 15),
	legend.position="bottom"
    ) + guides(fill = guide_legend(nrow = 1, label.vjust = 0, label.position = "top"))
mymap

  
### save file

  pngname <- paste0(basename, ".png")
  png(pngname, width = 1000, height = 1000)
  print(mymap)
  dev.off()
  
  emfname <- paste0(basename, ".emf")
  emf(file = emfname, width = 26.455, height = 26.455, units = "cm", emfPlus = FALSE)
  mymap
  dev.off()
  


