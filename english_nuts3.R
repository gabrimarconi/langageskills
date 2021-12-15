


source("functions.R")
source("libraries.R")


get_language <- function(foreign="english", adtext="en", occup_average=F) {
  #foreign <- "English"
  #adtext <- "en"
  #occup_average <- T
  
  # get the data you need
  myquery1 <- "SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3 FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3 LIMIT 1000000"
  myquery2 <- paste0("SELECT COUNT(DISTINCT oja_id) AS foreign, nuts3_id, nuts3 FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE (first_active_year=2021 AND (language='",adtext,"' OR skill='",foreign,"')) GROUP BY nuts3_id, nuts3 LIMIT 1000000")
  if (occup_average) {
    myquery1 <- "SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3, occupation3d_id, occupation3d FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3, occupation3d_id, occupation3d LIMIT 1000000"
    myquery2 <- paste0("SELECT COUNT(DISTINCT oja_id) AS foreign, nuts3_id, nuts3, occupation3d_id, occupation3d FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE (first_active_year=2021 AND (language='",adtext,"' OR skill='",foreign,"')) GROUP BY nuts3_id, nuts3, occupation3d_id, occupation3d LIMIT 1000000")
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
  # (you can find a list of R colours here: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/   )
  mymap <- ggplot(data=fltable_nuts_geo, aes(x=long,y=lat,group=group)) +
    geom_polygon(aes(fill=catprop),color="dim grey", size=.1) +
    scale_fill_manual(values=c("#993333", "#CC3300", "#FF5500", "#FF7700","#FF9900", "#FFCC00", "#FFFF00","#FFFF99", "#FFFFCC", "#CCFFFF", "#99FFFF", "#00FFFF", "#00CCFF","#0099FF", "#0066FF", "#0033FF", "#003399")) +
    lims(x = c(-12,44), y = c(35,70)) +
    guides(fill = guide_legend(reverse=T, title = paste("Ads requiring ",foreign," (prop.)"))) +
    labs(title="Online ads requiring ",foreign,", by NUTS-3 regions, 2018-2021",
         subtitle="",
         caption="(C) EuroGeographics for the administrative boundaries 
                Map produced in R with a help from Eurostat-package <github.com/ropengov/eurostat/>") 
  
  # return output: map, data on nuts3 regions, data with map information added
  myoutput <- list(mymap, fltable_nuts, fltable_nuts_geo, fltable_nuts_occu)
  return(myoutput)
    
}

english <- get_language(foreign = "English", adtext="en", occup_average = T)
german <- get_language(foreign = "German", adtext="de", occup_average = T)
french <- get_language(foreign = "French", adtext="fr", occup_average = T)
english[[1]]
german[[1]]
french[[1]]
write.csv(english[[2]], "english.csv")
write.csv(german[[2]], "german.csv")
write.csv(french[[2]], "french.csv")
write.csv(english[[4]], "english_occu.csv")
write.csv(german[[4]], "german_occu.csv")
write.csv(french[[4]], "french_occu.csv")



