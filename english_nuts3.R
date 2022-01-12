


source("functions.R")
source("libraries.R")


get_language <- function(foreign="english", adtext="en", occup_average=F) {
  #foreign <- "English"
  #adtext <- "en"
  #foreign <- "AtLeast1FL"
  #adtext <- "http://data.europa.eu/esco/skill/L1"
  #occup_average <- T
  #occup_average <- F
  
  # get the data you need
  myquery1 <- "SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3 FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3 LIMIT 1000000"
  myquery2 <- paste0("SELECT COUNT(DISTINCT oja_id) AS foreign, nuts3_id, nuts3 FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE (first_active_year=2021 AND (language='",adtext,"' OR skill='",foreign,"' OR skill_hier1_id='",adtext,"')) GROUP BY nuts3_id, nuts3 LIMIT 1000000")
  if (occup_average) {
    myquery1 <- "SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3, occupation3d_id, occupation3d FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3, occupation3d_id, occupation3d LIMIT 1000000"
    myquery2 <- paste0("SELECT COUNT(DISTINCT oja_id) AS foreign, nuts3_id, nuts3, occupation3d_id, occupation3d FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE (first_active_year=2021 AND (language='",adtext,"' OR skill='",foreign,"' OR skill_hier1_id='",adtext,"')) GROUP BY nuts3_id, nuts3, occupation3d_id, occupation3d LIMIT 1000000")
  }
  print(myquery1)
  print(myquery2)
  nuts <- get_data(myquery1)
  fltable <- get_data(myquery2)  
  fltable_nuts <- merge(fltable, nuts, all.y=T)
  
  # calculate proportion of ads requiring the foreign language in a given row
  fltable_nuts$prop <- as.numeric(fltable_nuts$foreign) / as.numeric(fltable_nuts$total)
  fltable_nuts$prop[is.na(fltable_nuts$prop)==T] <- 0
  if (occup_average) {
    average_occupations <- function(nutregion) {mean(fltable_nuts$prop[fltable_nuts$nuts3_id==nutregion])}
    temp_avg_occupations <- as.data.frame(cbind( sapply(unique(fltable_nuts$nuts3_id),average_occupations) , unique(fltable_nuts$nuts3_id)))
    colnames(temp_avg_occupations) <- c("avg_prop","nuts3_id")
    fltable_nuts_occu <- merge(fltable_nuts,temp_avg_occupations, all.x = T, by="nuts3_id")
    fltable_nuts_occu$prop <- as.numeric(fltable_nuts_occu$avg_prop)
    fltable_nuts <- fltable_nuts_occu[duplicated(fltable_nuts_occu$nuts3_id)==F,]
  } else if(occup_average==F) {fltable_nuts_occu <- as.data.frame("NA")}
  print(summary(fltable_nuts$prop))
 
  # generate a categorical variable for the proportion of ads requiring the foreign language
  fltable_nuts$catprop <- floor(100*as.numeric(fltable_nuts$prop))
  fltable_nuts$catprop[fltable_nuts$catprop>9] <- 10*floor(fltable_nuts$catprop[fltable_nuts$catprop>9]/10)
  fltable_nuts$catprop <- fltable_nuts$catprop/100
  fltable_nuts$catprop[fltable_nuts$catprop>.7] <- .7
  fltable_nuts$catprop <- paste0(">", as.character(fltable_nuts$catprop))
  fltable_nuts <- fltable_nuts[order(fltable_nuts$prop, decreasing = T),]
  
  # merge with the geo information needed to draw maps, using Eurostat's function
  fltable_nuts_geo <- merge_eurostat_geodata(data=fltable_nuts,geocolumn="nuts3_id",resolution = "20", output_class = "df", all_regions = FALSE)
  
  # draw map
  # (NB: you can find a list of R colours here: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/   )
  # write footnotes
  mynote1 <- "Notes: Average proportion across all ads"
  if (occup_average==T) {mynote1 <- "Note: Average across the proportions estimated for each 3-digit ISCO occupational category"}
  out_of_map <- fltable_nuts_geo[(fltable_nuts_geo$long < (-12) | fltable_nuts_geo$long > 30) & myduplo==F, c("nuts3", "prop")]
  out_of_map$note <- paste0(out_of_map$nuts3, " ", round(as.numeric(out_of_map$prop), 2))
  out_of_map$length <- nchar(out_of_map$note)
  out_of_map$lengthcum <- apply(as.matrix(1:dim(out_of_map)[1]),1,function(r) {sum(out_of_map$length[1:r])+16})
  out_of_map$group <- ceiling(out_of_map$lengthcum/100)
  mylist <- lapply(1:9, function(x) {paste0(out_of_map$note[out_of_map$group==x], collapse = ", ")})
  mynote2 <- paste0("\nNot in the map:", paste0("  ", do.call("cbind", mylist[mylist!=""]), collapse = "\n"))
  mynote3 <- "\n(C) EuroGeographics for the administrative boundaries \n Map produced in R with a help from Eurostat-package <github.com/ropengov/eurostat/>"
  # generate chart
  mymap <- ggplot(data=fltable_nuts_geo, aes(x=long,y=lat,group=group)) +
    geom_polygon(aes(fill=catprop),color="dim grey", size=.1) +
    scale_fill_manual(values=c("#993333", "#CC3300", "#FF5500", "#FF7700","#FF9900", "#FFCC00", "#FFFF00","#FFFF99", "#FFFFCC", "#CCFFFF", "#99FFFF", "#00FFFF", "#00CCFF","#0099FF", "#0066FF", "#0033FF", "#003399")) +
    lims(x = c(-12,30), y = c(35,70)) +
    # lims(x = c(-17,30), y = c(27,70)) +
    guides(fill = guide_legend(reverse=T, title = "")) +
    labs(title=paste0("Online ads requiring ",foreign),
         subtitle="Proportion by NUTS-3 regions, 2021",
         caption=paste0(mynote1, mynote2, mynote3) ) +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14),    # Center title position and size
      plot.subtitle = element_text(hjust = 0.5),            # Center subtitle
      plot.caption = element_text(hjust = 0, face = "italic")# move caption to the left
    )
  
  # save files
  skillname <- gsub("/|:|\\.| ","",foreign)
  skillname <- substr(skillname, (nchar(skillname)-10),(nchar(skillname)))
  adlang <- gsub("/|:|\\.","",adtext)
  adlang <- substr(adlang, (nchar(adlang)-1),(nchar(adlang)))
  basename <- paste0(skillname,"_",adlang,"_",substr(as.character(occup_average),1,1))
  write.csv(fltable_nuts, paste0(basename, ".csv"))
  write.csv(fltable_nuts_occu, paste0(basename, "_occu.csv"))
  pngname <- paste0(basename, ".png")
  png(pngname)
  print(mymap)
  dev.off()
  
  # return output: map, data on nuts3 regions, data with map information added
  myoutput <- list(mymap, fltable_nuts, fltable_nuts_geo, fltable_nuts_occu)
  return(myoutput)
    
}

english <- get_language(foreign = "English", adtext="en", occup_average = F)
german <- get_language(foreign = "German", adtext="de", occup_average = F)
french <- get_language(foreign = "French", adtext="fr", occup_average = F)
anyfl <- get_language(foreign = "at least one foreign language", adtext="http://data.europa.eu/esco/skill/L1", occup_average = F)


german[[1]]
french[[1]]
english[[1]]
anyfl[[1]]
write.csv(english[[2]], "english.csv")
write.csv(german[[2]], "german.csv")
write.csv(french[[2]], "french.csv")
write.csv(english[[4]], "english_occu.csv")
write.csv(german[[4]], "german_occu.csv")
write.csv(french[[4]], "french_occu.csv")


anyfl <- get_language(foreign = "http://data.europa.eu/esco/skill/L1", adtext="", occup_average = T)
  anyfl[[1]]

  
  skillname <- gsub("/|:|\\.","","http://data.europa.eu/esco/skill/L1")
  skillname <- substr(skillname, (nchar(skillname)-10),(nchar(skillname)))
  get_data("SELECT COUNT(DISTINCT oja_id) FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE skill_hier1_id='http://data.europa.eu/esco/skill/L1' LIMIT 10")
  get_data("SELECT COUNT(DISTINCT oja_id) FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended LIMIT 10")
  get_data("SELECT COUNT(DISTINCT oja_id) FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE language='fr' AND skill='french' LIMIT 10")
  prova <- get_data("SELECT skill, COUNT(DISTINCT oja_id) AS count FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE skill_hier1_id='http://data.europa.eu/esco/skill/L1' AND country_id='FR' GROUP BY skill ORDER BY count DESC LIMIT 10000")
  

myduplo <- duplicated(fltable_nuts_geo$nuts3)  



View(prova)
str(fltable_nuts_geo)

