


source("libraries.R")
source("libraries_eurostat.R")
setup_access("user")

get_language <- function(foreign="english", adtext="en", occup_average=F) {
  #foreign <- "English"
  #adtext <- "en"
  #foreign <- "AtLeast1FL"
  #adtext <- "http://data.europa.eu/esco/skill/L1"
  #occup_average <- T
  #occup_average <- F
  
  # get the data you need
  myquery1 <- "SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3, country_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3, country_id LIMIT 1000000"
  myquery2 <- paste0("SELECT COUNT(DISTINCT oja_id) AS foreign, nuts3_id, nuts3, country_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE (first_active_year=2021 AND (language='",adtext,"' OR skill='",foreign,"' OR skill_hier1_id='",adtext,"')) GROUP BY nuts3_id, nuts3, country_id LIMIT 1000000")
  if (occup_average) {
    myquery1 <- "SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3, country_id, occupation3d_id, occupation3d FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3, country_id, occupation3d_id, occupation3d LIMIT 1000000"
    myquery2 <- paste0("SELECT COUNT(DISTINCT oja_id) AS foreign, nuts3_id, nuts3, country_id, occupation3d_id, occupation3d FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE (first_active_year=2021 AND (language='",adtext,"' OR skill='",foreign,"' OR skill_hier1_id='",adtext,"')) GROUP BY nuts3_id, nuts3, country_id, occupation3d_id, occupation3d LIMIT 1000000")
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
  
  # calculate a table by country
  countrytable <- data.frame(country=unique(fltable_nuts$country_id), prop=sapply(unique(fltable_nuts$country_id), function(C) {mean(fltable_nuts$prop[fltable_nuts$country_id==C], na.rm=T)}))
  countrytable <- countrytable[order(countrytable$country),]
  colnames(countrytable) <- c("country", foreign)
 
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
  mynote3 <- "\n(C) EuroGeographics for the administrative boundaries \n Map produced in R with a help from Eurostat-package <github.com/ropengov/eurostat/>"
  # generate chart
  mymap <- ggplot(data=fltable_nuts_geo, aes(x=long,y=lat,group=group)) +
    geom_polygon(aes(fill=catprop),color="dim grey", size=.1) +
    scale_fill_manual(values=c("#993333", "#CC3300", "#FF5500", "#FF7700","#FF9900", "#FFCC00", "#FFFF00","#FFFF99", "#FFFFCC", "#CCFFFF", "#99FFFF", "#00FFFF", "#00CCFF","#0099FF", "#0066FF", "#0033FF", "#003399")) +
    lims(x = c(-12,30), y = c(35,70)) +
    # lims(x = c(-17,30), y = c(27,70)) +
    guides(fill = guide_legend(reverse=T, title = "")) +
    labs(title=paste0("Online job ads requiring ",foreign),
         subtitle="Proportion by NUTS-3 regions, 2021",
         caption=paste0(mynote1, mynote0, mynote2, mynote3) ) +
    theme(
      plot.title = element_text(hjust = 0.5, size = 26),    # Center title position and size
      plot.subtitle = element_text(hjust = 0.5, size = 18),            # Center subtitle
      plot.caption = element_text(hjust = 0, face = "italic", size = 14),# move caption to the left
      legend.text=element_text(size=18),
      axis.text.x=element_blank(), #remove x axis labels
      axis.ticks.x=element_blank(), #remove x axis ticks
      axis.text.y=element_blank(),  #remove y axis labels
      axis.ticks.y=element_blank(),  #remove y axis ticks
      axis.title=element_blank()
    )
  
  # save files
  skillname <- gsub("/|:|\\.| ","",foreign)
  skillname <- substr(skillname, (nchar(skillname)-10),(nchar(skillname)))
  adlang <- gsub("/|:|\\.","",adtext)
  adlang <- substr(adlang, (nchar(adlang)-1),(nchar(adlang)))
  basename <- paste0(skillname,"_",adlang,"_",substr(as.character(occup_average),1,1))
  write.csv(fltable_nuts, paste0(basename, ".csv"))
  write.csv(fltable_nuts_occu, paste0(basename, "_occu.csv"))
  write.csv(countrytable, paste0(basename, "_country.csv"))
  pngname <- paste0(basename, ".png")
  png(pngname, width = 1000, height = 1000)
  print(mymap)
  dev.off()
  
  # return output: map, data on nuts3 regions, data with map information added
  myoutput <- list(mymap, fltable_nuts, fltable_nuts_geo, fltable_nuts_occu)
  return(myoutput)
    
}

english <- get_language(foreign = "English", adtext="en", occup_average = T)
german <- get_language(foreign = "German", adtext="de", occup_average = T)
french <- get_language(foreign = "French", adtext="fr", occup_average = T)
anyfl <- get_language(foreign = "at least one foreign language", adtext="http://data.europa.eu/esco/skill/L1", occup_average = T)
spanish <- get_language(foreign = "Spanish", adtext="es", occup_average = T)
chinese <- get_language(foreign = "Chinese", adtext="notapplicable", occup_average = T)

english <- get_language(foreign = "English", adtext="en", occup_average = F)
german <- get_language(foreign = "German", adtext="de", occup_average = F)
french <- get_language(foreign = "French", adtext="fr", occup_average = F)
anyfl <- get_language(foreign = "at least one foreign language", adtext="http://data.europa.eu/esco/skill/L1", occup_average = F)
spanish <- get_language(foreign = "Spanish", adtext="es", occup_average = F)
chinese <- get_language(foreign = "Chinese", adtext="notapplicable", occup_average = F)

german[[1]]
french[[1]]
english[[1]]
anyfl[[1]]
spanish[[1]]
chinese[[1]]
write.csv(english[[2]], "english.csv")
write.csv(german[[2]], "german.csv")
write.csv(french[[2]], "french.csv")
write.csv(anyfl[[2]], "anyfl.csv")
write.csv(chinese[[2]], "chinese.csv")
write.csv(english[[4]], "english_occu.csv")
write.csv(german[[4]], "german_occu.csv")
write.csv(french[[4]], "french_occu.csv")
write.csv(anyfl[[4]], "anyfl_occu.csv")

total_ads <- get_data("SELECT COUNT(DISTINCT oja_id) AS ads FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='' LIMIT 1")

skill_table <- get_data("SELECT skill, skill_hier1_id, COUNT(DISTINCT oja_id) AS ads FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 GROUP BY skill, skill_hier1_id ORDER BY ads DESC LIMIT 1000000")

skill_table_lang <- get_data("SELECT skill, skill_hier1_id, COUNT(DISTINCT oja_id) AS ads FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill_hier1_id='http://data.europa.eu/esco/skill/L1' GROUP BY skill, skill_hier1_id ORDER BY ads DESC LIMIT 1000000")
write.csv(skill_table_lang, "skill_table_lang.csv")

skill_table_lang$prop <- as.numeric(skill_table_lang$ads) / as.numeric(total_ads)

get_data("SELECT COUNT(DISTINCT oja_id) AS ads FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 LIMIT 1")

