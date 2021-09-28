




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






