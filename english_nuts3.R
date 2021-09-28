


source("functions.R")
source("libraries.R")

nuts <- get_data("SELECT COUNT(DISTINCT oja_id) AS total, nuts3_id, nuts3 FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE first_active_year=2021 GROUP BY nuts3_id, nuts3 LIMIT 1000000")
english <- get_data("SELECT COUNT(DISTINCT oja_id) AS english, nuts3_id, nuts3 FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended WHERE (first_active_year=2021 AND (language='en' OR skill='english')) GROUP BY nuts3_id, nuts3 LIMIT 1000000")

english_nuts <- merge(english, nuts, all.y=T)
str(english_nuts)
english_nuts$prop <- as.numeric(english_nuts$english) / as.numeric(english_nuts$total)

english_nuts <- english_nuts[order(english_nuts$prop, decreasing = T),]
#View(english_nuts)

english_nuts_geo <- merge_eurostat_geodata(data=english_nuts,geocolumn="nuts3_id",resolution = "20", output_class = "df", all_regions = FALSE)
#View(english_nuts_geo)
str(english_nuts_geo)


ggplot(data=english_nuts_geo, aes(x=long,y=lat,group=group)) +
  geom_polygon(aes(fill=prop),color="dim grey", size=.1) +
  lims(x = c(-12,44), y = c(35,70)) +
  guides(fill = guide_legend(reverse=T, title = "Ads requiring English (%)")) +
  labs(title="Online ads requiring English, by NUTS-3 regions, 2018-2021",
       subtitle="",
       caption="(C) EuroGeographics for the administrative boundaries 
                Map produced in R with a help from Eurostat-package <github.com/ropengov/eurostat/>") 


data_capped <- english_nuts_geo
data_capped$prop[data_capped$prop>.1] <- .08
ggplot(data=data_capped, aes(x=long,y=lat,group=group)) +
  geom_polygon(aes(fill=prop),color="dim grey", size=.1) +
  lims(x = c(-12,44), y = c(35,70)) +
  guides(fill = guide_legend(reverse=T, title = "Ads requiring English (%)")) +
  labs(title="Online ads requiring English, by NUTS-3 regions, 2018-2021",
       subtitle="",
       caption="(C) EuroGeographics for the administrative boundaries 
                Map produced in R with a help from Eurostat-package <github.com/ropengov/eurostat/>") 





