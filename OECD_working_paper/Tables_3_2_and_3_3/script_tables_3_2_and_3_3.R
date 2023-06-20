


setwd("C:/Users/Documents/FL")
countryfile <- read.csv("English_en_F.csv")
country_list <- unique(df$country)[order(unique(df$country))]

### new Table 2 on prop of ads implicitly or explicitly requiring FLs	

calculate_props <- function(mylang) {
	#mylang <- "English_en"
	#mylang <- "Chinese_le"
	myfile <- paste0(mylang, "_F.csv")
	df <- read.csv(myfile)
	adprop <- sapply(country_list, function(c) {round(100*sum(df$foreign[df$country==c], na.rm=T) / sum(df$total[df$country==c], na.rm=T), 2)})
	return(adprop)
}

mylanguages <- c("English_en", "German_de", "Spanish_es", "Chinese_le", "French_fr", "ignlanguage_L1")
table3 <- as.data.frame(do.call(cbind, lapply(mylanguages, calculate_props)))
colnames(table3) <- mylanguages
table3
write.csv(table3, "Table_3_3.csv")

### other new table on prop of ads implicitly requiring a new language

calculate_props_adsinfl <- function(mylang) {
	#mylang <- "en"
	myfile <- paste0("nothing_", mylang, "F_2021r2022.csv")
	df <- read.csv(myfile)
	adprop <- sapply(country_list, function(c) {round(100*sum(df$foreign[df$country==c], na.rm=T) / sum(df$total[df$country==c], na.rm=T), 2)})
	return(adprop)
}

myadlanguages <- c("en", "de", "es", "fr")
newtable <- as.data.frame(do.call(cbind, lapply(myadlanguages, calculate_props_adsinfl)))
colnames(newtable) <- myadlanguages
newtable
write.csv(newtable, "Table_3_2.csv")


