

############################# Eurostat/Cedefop DataLAB ##############################
#####################################################################################
################################### Access to data ################################## 
#####################################################################################

# in order to connect to Athena you should have the following: 
# -- R with installed package noctua

library(noctua)

# Athena connection info in your home folder. In the ~/.aws folder you should have 3 files: config, s3_staging_dir, work_group 
######################
# general function to run a query with Athena
get_data <- function(query){
  con <- DBI::dbConnect(noctua::athena(),
                        s3_staging_dir=readLines("~/.aws/s3_staging_dir"),
                        work_group=readLines("~/.aws/work_group")
  )
  my_data <- noctua::dbGetQuery(con, query)
  dbDisconnect(con)
  return(my_data)
}

#  get the list of tables
query  <-  " SHOW Tables IN WIHAccessCatalog.wih_oja_latest" 
tables <- get_data(query)
tables

#  get data from a table
query <-  "SELECT *  FROM WIHAccessCatalog.wih_oja_versioned.codelist_wih_oja_occupation_v1 ORDER BY RAND() LIMIT 1000;"
data <- get_data(query)
data


prova <- get_data("SELECT language AS lang, COUNT(oja_id) AS count FROM WIHAccessCatalog.wih_oja_latest.wih_oja_main GROUP BY language LIMIT 1000")
prova <- get_data("SELECT lang AS lang, COUNT(general_id) AS count FROM WIHAccessCatalog.wih_oja_versioned.ft_document_en_v9 GROUP BY lang LIMIT 1000")

get_data("SELECT first_active_year, first_active_month FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended GROUP BY first_active_year, first_active_month LIMIT 1000")



View(prova)


primariga <- get_data("SELECT * FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended LIMIT 1")
colonne <- colnames(primariga)
colonne
prova <- get_data("SELECT oja_id, city FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended LIMIT 10")
dim(prova)
str(prova)
head(prova)
View(prova)
prova <- get_data("SELECT oja_id, city FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended ORDER BY RAND() LIMIT 10")
prova <- get_data("SELECT COUNT(oja_id) AS count, city, contract_id, contract FROM WIHAccessCatalog.wih_oja_latest.wih_oja_blended GROUP BY city, contract_id, contract ORDER BY count DESC LIMIT 1000000")
View(prova)
write.csv(prova, "ads_by_city.csv")
saveRDS(prova, "ads_by_city.rds")
prova2 <- readRDS("ads_by_city.rds")
View(prova2)