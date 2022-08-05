
###############################################################
### 0. set up
###############################################################

source("libraries.R")
setup_access("user")
### get some useful numbers and lists

### define blended table to be used and definition of the dataset
blended <- "WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224"
#WIHAccessCatalog.
restrictions <- " WHERE first_active_year=2021 AND SUBSTR(oja_id,9,1)!='4' "
variant0eng <- c("_v0","English"," ")
variant1eng <- c("_v1","English"," AND skill!='' ")
variant1deu <- c("_v1","German"," AND skill!='' ")
variant1chi <- c("_v1","Chinese"," AND skill!='' ")
variant <- variant1eng
namextension <- paste0(variant[1], variant[2])
language <- variant[2]
extra_restrictions <- variant[3]


total_ads <- get_data(paste0("SELECT COUNT(DISTINCT oja_id) FROM ",blended, restrictions, extra_restrictions," LIMIT 100"))
skillist <- get_data(paste0("SELECT skill, COUNT(DISTINCT oja_id) AS ads FROM ",blended, restrictions, extra_restrictions," GROUP BY skill ORDER BY ads DESC LIMIT 1000000"))
skillist_clean <- skillist[skillist$skill!=""&skillist$skill!=language,]





###############################################################
### 1. functions
###############################################################

### write function to calculate gini
calculate_gini <- function(myskill) {
  #myskill <- "pharmaceutical chemistry"
  #myskill <- "yoga"
  print(myskill)
  myskill <- gsub("'", "''", myskill)
  
  #write a query in SQL that returns a cross-tabulation of english and myskill. this requires a triple inner join
  table1 <- paste0("SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions)
  table2 <- paste0("SELECT DISTINCT oja_id, skill AS english FROM ",blended, restrictions," AND skill='",language,"'")
  table3 <- paste0("SELECT DISTINCT oja_id, skill AS otherskill FROM ",blended,restrictions," AND  skill='",myskill,"'")
  #test1 <- get_data(paste0(table1, " LIMIT 100"))
  #test2 <- get_data(paste0(table2, " LIMIT 100"))
  #test3 <- get_data(paste0(table3, " LIMIT 100"))
  joinquery <- paste0(
    "WITH main2021 AS (",table1,"),
  englishtable AS (",table2,"),
  otherskilltable AS (",table3,")
  SELECT COUNT(DISTINCT oja_id) AS ads, english, otherskill FROM main2021 LEFT JOIN englishtable USING(oja_id) LEFT JOIN otherskilltable USING(oja_id) GROUP BY english, otherskill 
  LIMIT 100"  )
  crosstab <- get_data(joinquery)
  crosstab
  
  # calculate the gini impurity index. Notice the simplified formula for the case of a 2X2 matrix: 
  # p_myskill * [2 * p_englishANDmyskill|myskill * (1 - p_englishANDmyskill|myskill)] + (1 - p_myskill) * [2 * p_englishBUTNOTmyskill|NOTmyskill * (1 - p_englishBUTNOTmyskill|NOTmyskill)] 
  N_myskill <- as.numeric(sum(crosstab$ads[is.na(crosstab$otherskill)==F]))
  N_all <- as.numeric(sum(crosstab$ads))
  N_NOTmyskill <- N_all - N_myskill
  N_englishANDmyskill <- as.numeric(crosstab$ads[is.na(crosstab$otherskill)==F&is.na(crosstab$english)==F])
  if (dim(crosstab[is.na(crosstab$otherskill)==F&is.na(crosstab$english)==F,])[1] == 0) {N_englishANDmyskill <- 0}
  p_myskill <- N_myskill / N_all
  p_englishANDmyskill <- N_englishANDmyskill / N_myskill
  p_englishBUTNOTmyskill <- as.numeric(crosstab$ads[is.na(crosstab$otherskill)==T&is.na(crosstab$english)==F]) / N_NOTmyskill
  gini <- (p_myskill * 2 * p_englishANDmyskill * (1 - p_englishANDmyskill) + (1 - p_myskill) * 2 * p_englishBUTNOTmyskill * (1 - p_englishBUTNOTmyskill))
  print(gini)
  
  # prepare and return output
  return(gini)
}
#calculate_gini("database")



### write function to calculate potential max gini given the number of ads for a certain skill
calculate_min_potential_gini <- function(myskill) {
  #myskill <- "CSS"
  
  # calculate the max potential gini impurity index. Notice that this is obtained when, in the simplified formula for the impurity gini index:
  # p_englishANDmyskill|myskill={max possible} and p_englishBUTNOTmyskill|NOTmyskill)={min possible} (the second term is the prob of not english and not other skill)
  # NB skillist and skillist_clean are the same, just skillist_clean does not contain info for no skills and for English
  N_english <- as.numeric(skillist$ads[skillist$skill==language])
  N_myskill <- as.numeric(skillist_clean$ads[skillist_clean$skill==myskill])
  N_all <- total_ads
  N_NOTmyskill <- N_all - N_myskill
  N_englishANDmyskill <- min(N_myskill, N_english)
  N_englishBUTNOTmyskill <- N_english - N_englishANDmyskill
  p_myskill <- N_myskill / N_all
  p_english <- N_english / N_all
  p_englishANDmyskill <- N_englishANDmyskill / N_myskill
  p_englishBUTNOTmyskill <- N_englishBUTNOTmyskill / N_NOTmyskill
  gini <- p_myskill * 2 * p_englishANDmyskill * (1 - p_englishANDmyskill) + (1 - p_myskill) * 2 * p_englishBUTNOTmyskill * (1 - p_englishBUTNOTmyskill)
  
  # prepare and return output
  return(gini)
}
#calculate_min_potential_gini("database")


###############################################################
### 2. iteration 1
###############################################################




# calculate gini index for a few big skills to see what can be an interesting value for the gini index
interesting_gini <- min(sapply(skillist_clean$skill[1:10], calculate_gini))

# exclude from the calculation all ads with a min potential gini index > interesting gini index
skillist_clean$mingini <- sapply(skillist_clean$skill, calculate_min_potential_gini)
skillist_clean$include <- as.numeric(skillist_clean$mingini) < as.numeric(interesting_gini)
nrqueries <- table(skillist_clean$include, useNA = "always")
write.csv(nrqueries, paste0("nrqueries_it1", namextension,".csv"))
nrqueries

# apply calculate_gini to all skills that could potentially have the best gini index
skillist_clean$gini <- 1
skillist_clean$gini[skillist_clean$include] <- sapply(skillist_clean$skill[skillist_clean$include], calculate_gini)

# pick the winner
winner <- c(skillist_clean$skill[which.min(skillist_clean$gini)], min(skillist_clean$gini, na.rm = T))
#winner <- c("adapt to change", as.numeric(0.3240908))
write.csv(winner, paste0("winner",namextension,".csv"))
saveRDS(skillist_clean, paste0("skillist_clean_it1",namextension,".rds"))


###############################################################
### 3. iteration 2
###############################################################


### redefine functions and parameters as needed
winner <- read.csv(paste0("winner",namextension,".csv"))$x

# find out which node to split
# write a query in SQL that returns a cross-tabulation of english and myskill. this requires a triple inner join
# in addition, a further join now needs to be done with adapt to change, because we will need to exclude ads that require this skill
table1 <- paste0("SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions)
table2 <- paste0("SELECT DISTINCT oja_id, skill AS english FROM ",blended, restrictions," AND skill='",language,"'")
table3 <- paste0("SELECT DISTINCT oja_id, skill AS firstout FROM ",blended,restrictions," AND  skill='",winner[1],"'")
#test1 <- get_data(paste0(table1, " LIMIT 100"))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
#test3 <- get_data(paste0(table3, " LIMIT 100"))
joinquery <- paste0(
  "WITH main2021 AS (",table1,"),
  englishtable AS (",table2,"),
    firstouttable AS (",table3,")
  SELECT COUNT(DISTINCT oja_id) AS ads, firstout, english FROM main2021 LEFT JOIN firstouttable USING(oja_id) LEFT JOIN englishtable USING(oja_id) GROUP BY english, firstout
  LIMIT 100"  )
crosstab <- get_data(joinquery)
firstout_1_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$firstout)==F&is.na(crosstab$english)==F]), na.rm = T)
firstout_1_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$firstout)==F&is.na(crosstab$english)==T]), na.rm = T)
firstout_0_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$firstout)==T&is.na(crosstab$english)==F]), na.rm = T)
firstout_0_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$firstout)==T&is.na(crosstab$english)==T]), na.rm = T)
gini_firstout_1 <- 1 - (firstout_1_eng_1/(firstout_1_eng_1+firstout_1_eng_0))^2 - (firstout_1_eng_0/(firstout_1_eng_1+firstout_1_eng_0))^2
gini_firstout_0 <- 1 - (firstout_0_eng_1/(firstout_0_eng_1+firstout_0_eng_0))^2 - (firstout_0_eng_0/(firstout_0_eng_1+firstout_0_eng_0))^2
split_branch_0 <- gini_firstout_1 < gini_firstout_0
winner <- c(winner, split_branch_0)
write.csv(winner, paste0("winner",namextension,".csv"))



winner_in_sample <- ifelse(winner[3], " IS NULL ", " IS NOT NULL ") # if winner[3]==TRUE --> we split the branch where winner==0  --> the ads in the branch must exclude those with winner==1; if winner[3]==FALSE --> we split the branch where winner==1  --> the ads in the branch must include only those with winner==1

total_ads <- get_data(paste0(
  "WITH main2021 AS (SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions,"),
  firstouttable AS (SELECT DISTINCT oja_id, skill AS firstout FROM ",blended, restrictions," AND skill='",winner[1],"')
  SELECT COUNT(DISTINCT oja_id) AS ads FROM main2021 LEFT JOIN firstouttable USING(oja_id) WHERE firstout ",winner_in_sample," 
  LIMIT 100"))

skillist <- get_data(paste0(
  "WITH main2021 AS (SELECT DISTINCT oja_id, skill FROM ",blended, restrictions, extra_restrictions,"),
  firstouttable AS (SELECT DISTINCT oja_id, skill AS firstout FROM ",blended, restrictions," AND skill='",winner[1],"')
  SELECT skill, COUNT(DISTINCT oja_id) AS ads FROM main2021 LEFT JOIN firstouttable USING(oja_id) WHERE firstout IS NULL GROUP BY skill ORDER BY ads DESC
  LIMIT 100000"))
skillist_clean <- skillist[skillist$skill!=""&skillist$skill!=language&skillist$skill!=winner[1],]



# write function to calculate gini in the second iteration
calculate_gini <- function(myskill) {
  #myskill <- "firmware"
  print(myskill)
  myskill <- gsub("'", "''", myskill)
  
  #write a query in SQL that returns a cross-tabulation of english and myskill. this requires a triple inner join
  # in addition, a further join now needs to be done with adapt to change, because we will need to exclude ads that require this skill
  table1 <- paste0("SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions)
  table2 <- paste0("SELECT DISTINCT oja_id, skill AS english FROM ",blended, restrictions," AND skill='",language,"'")
  table3 <- paste0("SELECT DISTINCT oja_id, skill AS otherskill FROM ",blended,restrictions," AND  skill='",myskill,"'")
  table4 <- paste0("SELECT DISTINCT oja_id, skill AS firstout FROM ",blended,restrictions," AND  skill='",winner[1],"'")
  #test1 <- get_data(paste0(table1, " LIMIT 100"))
  #test2 <- get_data(paste0(table2, " LIMIT 100"))
  #test3 <- get_data(paste0(table3, " LIMIT 100"))
  #test4 <- get_data(paste0(table4, " LIMIT 100"))
  joinquery <- paste0(
    "WITH main2021 AS (",table1,"),
  englishtable AS (",table2,"),
  otherskilltable AS (",table3,"),
  firstouttable AS (",table4,")
  SELECT COUNT(DISTINCT oja_id) AS ads, firstout, english, otherskill FROM main2021 LEFT JOIN firstouttable USING(oja_id) LEFT JOIN englishtable USING(oja_id) LEFT JOIN otherskilltable USING(oja_id) GROUP BY english, otherskill, firstout
  LIMIT 100"  )
  crosstab_large <- get_data(joinquery)
  crosstab <- crosstab_large[is.na(crosstab_large$firstout)==split_branch_0,]
  crosstab
  
  # calculate the gini impurity index. Notice the simplified formula for the case of a 2X2 matrix: 
  # p_myskill * [2 * p_englishANDmyskill|myskill * (1 - p_englishANDmyskill|myskill)] + (1 - p_myskill) * [2 * p_englishBUTNOTmyskill|NOTmyskill * (1 - p_englishBUTNOTmyskill|NOTmyskill)] 
  N_myskill <- as.numeric(sum(crosstab$ads[is.na(crosstab$otherskill)==F]))
  N_all <- as.numeric(sum(crosstab$ads))
  N_NOTmyskill <- N_all - N_myskill
  N_englishANDmyskill <- as.numeric(sum(crosstab$ads[is.na(crosstab$otherskill)==F&is.na(crosstab$english)==F]))
  p_myskill <- N_myskill / N_all
  p_englishANDmyskill <- N_englishANDmyskill / N_myskill
  p_englishBUTNOTmyskill <- as.numeric(crosstab$ads[is.na(crosstab$otherskill)==T&is.na(crosstab$english)==F]) / N_NOTmyskill
  gini <- (p_myskill * 2 * p_englishANDmyskill * (1 - p_englishANDmyskill) + (1 - p_myskill) * 2 * p_englishBUTNOTmyskill * (1 - p_englishBUTNOTmyskill))
  if (N_myskill==0) {gini <- 1}
  print(gini)
  
  # prepare and return output
  return(gini)
}
#calculate_gini("database")


### start with the actual iteration
# calculate gini index for a few big skills to see what can be an interesting value for the gini index
interesting_gini <- min(sapply(skillist_clean$skill[1:10], calculate_gini))

# exclude from the calculation all ads with a min potential gini index > interesting gini index
skillist_clean$mingini <- sapply(skillist_clean$skill, calculate_min_potential_gini)
skillist_clean$include <- as.numeric(skillist_clean$mingini) < as.numeric(interesting_gini)
nrqueries <- table(skillist_clean$include, useNA = "always")
write.csv(nrqueries, paste0("nrqueries_it2", namextension,".csv"))
nrqueries

# apply calculate_gini to all skills that could potentially have the best gini index
skillist_clean$gini <- 1
skillist_clean$gini[skillist_clean$include] <- sapply(skillist_clean$skill[skillist_clean$include], calculate_gini)

# pick the silver medal
silver <- c(skillist_clean$skill[which.min(skillist_clean$gini)], min(skillist_clean$gini, na.rm = T))
#silver <- c("French", as.numeric(0.0213311))
write.csv(silver, paste0("silver",namextension,".csv"))
saveRDS(skillist_clean, paste0("skillist_clean_it2",namextension,".rds"))




###############################################################
### 4. iteration 3
###############################################################


### redefine functions and parameters as needed

winner <- read.csv(paste0("winner",namextension,".csv"))$x
silver <- read.csv(paste0("silver",namextension,".csv"))$x

# find out which node to split
# write a query in SQL that returns a cross-tabulation of english and myskill. this requires a triple inner join
# in addition, a further join now needs to be done with adapt to change, because we will need to exclude ads that require this skill
table1 <- paste0("SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions)
table2 <- paste0("SELECT DISTINCT oja_id, skill AS english   FROM ",blended, restrictions," AND skill='",language,"'")
table3 <- paste0("SELECT DISTINCT oja_id, skill AS firstout  FROM ",blended, restrictions," AND  skill='",winner[1],"'")
table4 <- paste0("SELECT DISTINCT oja_id, skill AS secondout FROM ",blended, restrictions," AND  skill='",silver[1],"'")
#test1 <- get_data(paste0(table1, " LIMIT 100"))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
#test3 <- get_data(paste0(table3, " LIMIT 100"))
#test4 <- get_data(paste0(table4, " LIMIT 100"))
joinquery <- paste0(
  "WITH main2021 AS (",table1,"),
  englishtable AS (",table2,"),
  firstouttable AS (",table3,"),
  secondouttable AS (",table4,")
  SELECT COUNT(DISTINCT oja_id) AS ads, firstout, secondout, english FROM main2021 LEFT JOIN firstouttable USING(oja_id) LEFT JOIN secondouttable USING(oja_id) LEFT JOIN englishtable USING(oja_id) GROUP BY english, firstout, secondout
  LIMIT 100"  )
crosstab_large <- get_data(joinquery)
crosstab <- crosstab_large[is.na(crosstab_large$firstout)==winner[3],]
secondout_1_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$secondout)==F&is.na(crosstab$english)==F]), na.rm = T)
secondout_1_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$secondout)==F&is.na(crosstab$english)==T]), na.rm = T)
secondout_0_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$secondout)==T&is.na(crosstab$english)==F]), na.rm = T)
secondout_0_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$secondout)==T&is.na(crosstab$english)==T]), na.rm = T)
gini_secondout_1 <- 1 - (secondout_1_eng_1/(secondout_1_eng_1+secondout_1_eng_0))^2 - (secondout_1_eng_0/(secondout_1_eng_1+secondout_1_eng_0))^2
gini_secondout_0 <- 1 - (secondout_0_eng_1/(secondout_0_eng_1+secondout_0_eng_0))^2 - (secondout_0_eng_0/(secondout_0_eng_1+secondout_0_eng_0))^2
split_branch_0 <- gini_secondout_1 < gini_secondout_0
silver <- c(silver, split_branch_0)
write.csv(silver, paste0("silver",namextension,".csv"))


# write function to calculate gini in the third iteration
calculate_gini <- function(myskill) {
  #myskill <- "database"
  print(myskill)
  myskill <- gsub("'", "''", myskill)
  
  #write a query in SQL that returns a cross-tabulation of english and myskill. this requires a triple inner join
  # in addition, a further join now needs to be done with the first and the second best-predicting skills, because we will need to exclude ads that require this skill
  table1 <- paste0("SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions)
  table2 <- paste0("SELECT DISTINCT oja_id, skill AS english FROM ",blended, restrictions," AND skill='",language,"'")
  table3 <- paste0("SELECT DISTINCT oja_id, skill AS otherskill FROM ",blended,restrictions," AND  skill='",myskill,"'")
  table4 <- paste0("SELECT DISTINCT oja_id, skill AS firstout  FROM ",blended,restrictions," AND  skill='",winner[1],"'")
  table5 <- paste0("SELECT DISTINCT oja_id, skill AS secondout FROM ",blended,restrictions," AND  skill='",silver[1],"'")
  #test1 <- get_data(paste0(table1, " LIMIT 100"))
  #test2 <- get_data(paste0(table2, " LIMIT 100"))
  #test3 <- get_data(paste0(table3, " LIMIT 100"))
  #test4 <- get_data(paste0(table4, " LIMIT 100"))
  joinquery <- paste0(
    "WITH main2021 AS (",table1,"),
  englishtable AS (",table2,"),
  otherskilltable AS (",table3,"),
  firstouttable AS (",table4,"),
  secondouttable AS (",table5,")
  SELECT COUNT(DISTINCT oja_id) AS ads, firstout, secondout, english, otherskill FROM main2021 LEFT JOIN firstouttable USING(oja_id) LEFT JOIN secondouttable USING(oja_id) LEFT JOIN englishtable USING(oja_id) LEFT JOIN otherskilltable USING(oja_id) GROUP BY english, otherskill, firstout, secondout
  LIMIT 100"  )
  crosstab_large <- get_data(joinquery)
  crosstab <- crosstab_large[is.na(crosstab_large$firstout)==winner[3]&is.na(crosstab_large$secondout)==split_branch_0,]
  crosstab
  
  # calculate the gini impurity index. Notice the simplified formula for the case of a 2X2 matrix: 
  # p_myskill * [2 * p_englishANDmyskill|myskill * (1 - p_englishANDmyskill|myskill)] + (1 - p_myskill) * [2 * p_englishBUTNOTmyskill|NOTmyskill * (1 - p_englishBUTNOTmyskill|NOTmyskill)] 
  N_myskill <- as.numeric(sum(crosstab$ads[is.na(crosstab$otherskill)==F]))
  N_all <- as.numeric(sum(crosstab$ads))
  N_NOTmyskill <- N_all - N_myskill
  N_englishANDmyskill <- as.numeric(crosstab$ads[is.na(crosstab$otherskill)==F&is.na(crosstab$english)==F])
  if (dim(crosstab[is.na(crosstab$otherskill)==F&is.na(crosstab$english)==F,])[1] == 0) {N_englishANDmyskill <- 0}
  p_myskill <- N_myskill / N_all
  p_englishANDmyskill <- N_englishANDmyskill / N_myskill
  p_englishBUTNOTmyskill <- as.numeric(crosstab$ads[is.na(crosstab$otherskill)==T&is.na(crosstab$english)==F]) / N_NOTmyskill
  gini <- (p_myskill * 2 * p_englishANDmyskill * (1 - p_englishANDmyskill) + (1 - p_myskill) * 2 * p_englishBUTNOTmyskill * (1 - p_englishBUTNOTmyskill))
  if (N_myskill==0) {gini <- 1}
  print(gini)
  
  # prepare and return output
  return(gini)
}
#calculate_gini("database")


winner_in_sample <- ifelse(winner[3], " IS NULL ", " IS NOT NULL ") # if winner[3]==TRUE --> we split the branch where winner==0  --> the ads in the branch must exclude those with winner==1; if winner[3]==FALSE --> we split the branch where winner==1  --> the ads in the branch must include only those with winner==1
silver_in_sample <- ifelse(silver[3], " IS NULL ", " IS NOT NULL ") # if winner[3]==TRUE --> we split the branch where winner==0  --> the ads in the branch must exclude those with winner==1; if winner[3]==FALSE --> we split the branch where winner==1  --> the ads in the branch must include only those with winner==1

total_ads <- get_data(paste0(
  "WITH main2021 AS (SELECT DISTINCT oja_id FROM ",blended, restrictions, extra_restrictions,"),
  firstouttable  AS (SELECT DISTINCT oja_id, skill AS firstout  FROM ",blended, restrictions," AND skill='",winner[1],"'),
  secondouttable AS (SELECT DISTINCT oja_id, skill AS secondout FROM ",blended, restrictions," AND skill='",silver[1],"')
  SELECT COUNT(DISTINCT oja_id) AS ads FROM main2021 LEFT JOIN firstouttable USING(oja_id) LEFT JOIN secondouttable USING(oja_id) WHERE (firstout ",winner_in_sample," and secondout ",silver_in_sample,")
  LIMIT 100"))

skillist <- get_data(paste0(
  "WITH main2021 AS (SELECT DISTINCT oja_id, skill FROM ",blended, restrictions, extra_restrictions,"),
  firstouttable  AS (SELECT DISTINCT oja_id, skill AS firstout  FROM ",blended, restrictions," AND skill='",winner[1],"'),
  secondouttable AS (SELECT DISTINCT oja_id, skill AS secondout FROM ",blended, restrictions," AND skill='",silver[1],"')
  SELECT skill, COUNT(DISTINCT oja_id) AS ads FROM main2021 LEFT JOIN firstouttable USING(oja_id) LEFT JOIN secondouttable USING(oja_id) WHERE (firstout ",winner_in_sample," and secondout ",silver_in_sample,") GROUP BY skill ORDER BY ads DESC
  LIMIT 100000"))
skillist_clean <- skillist[skillist$skill!=""&skillist$skill!=language&skillist$skill!=winner[1]&skillist$skill!=silver[1],]


### start with the actual iteration
# calculate gini index for a few big skills to see what can be an interesting value for the gini index
interesting_gini <- min(sapply(skillist_clean$skill[1:10], calculate_gini))

# exclude from the calculation all ads with a min potential gini index > interesting gini index
skillist_clean$mingini <- sapply(skillist_clean$skill, calculate_min_potential_gini)
skillist_clean$include <- as.numeric(skillist_clean$mingini) < as.numeric(interesting_gini)
nrqueries <- table(skillist_clean$include, useNA = "always")
write.csv(nrqueries, paste0("nrqueries_it3", namextension,".csv"))
nrqueries

# apply calculate_gini to all skills that could potentially have the best gini index
skillist_clean$gini <- 1
skillist_clean$gini[skillist_clean$include] <- sapply(skillist_clean$skill[skillist_clean$include], calculate_gini)

# pick the bronze medal
bronze <- c(skillist_clean$skill[which.min(skillist_clean$gini)], min(as.numeric(skillist_clean$gini), na.rm  =T))
#winner <- c("adapt to change", as.numeric(0.3240908))
write.csv(bronze, paste0("bronze",namextension,".csv"))
saveRDS(skillist_clean, paste0("skillist_clean_it3",namextension,".rds"))


###############################################################
### 5. model evaluation
###############################################################


### load model parameters
winner <- read.csv(paste0("winner",namextension,".csv"))$x
silver <- read.csv(paste0("silver",namextension,".csv"))$x
bronze <- read.csv(paste0("bronze",namextension,".csv"))$x

# write a query in SQL that returns a cross-tabulation of english and myskill. this requires a triple inner join
# in addition, a further join now needs to be done with the first and the second best-predicting skills, because we will need to exclude ads that require this skill
table1 <- paste0("SELECT DISTINCT oja_id FROM ",blended, gsub("!=","=",restrictions), extra_restrictions)
table2 <- paste0("SELECT DISTINCT oja_id, skill AS english FROM ",blended, gsub("!=","=",restrictions)," AND skill='",language,"'")
table3 <- paste0("SELECT DISTINCT oja_id, skill AS winner FROM ",blended,gsub("!=","=",restrictions)," AND  skill='",winner[1],"'")
table4 <- paste0("SELECT DISTINCT oja_id, skill AS silver FROM ",blended,gsub("!=","=",restrictions)," AND  skill='",silver[1],"'")
table5 <- paste0("SELECT DISTINCT oja_id, skill AS bronze FROM ",blended,gsub("!=","=",restrictions)," AND  skill='",bronze[1],"'")
#test1 <- get_data(paste0(table1, " LIMIT 100"))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
#test3 <- get_data(paste0(table3, " LIMIT 100"))
#test4 <- get_data(paste0(table4, " LIMIT 100"))
#test5 <- get_data(paste0(table5, " LIMIT 100"))
joinquery <- paste0(
  "WITH main2021 AS (",table1,"),
  englishtable AS (",table2,"),
  winnertable AS (",table3,"),
  silvertable AS (",table4,"),
  bronzetable AS (",table5,")
  SELECT COUNT(DISTINCT oja_id) AS ads, english, winner, silver, bronze FROM main2021 LEFT JOIN englishtable USING(oja_id) LEFT JOIN winnertable USING(oja_id) LEFT JOIN silvertable USING(oja_id) LEFT JOIN bronzetable USING(oja_id) GROUP BY english, winner, silver, bronze
  LIMIT 100"  )
crosstab_large <- get_data(joinquery)

# calculate total ads
total_ads <-sum(as.numeric(crosstab_large$ads))

### evaluate step1

crosstab <- crosstab_large
# calculate cells in confusion matrix
winner_1_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$winner)==F&is.na(crosstab$english)==F]), na.rm = T)
winner_1_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$winner)==F&is.na(crosstab$english)==T]), na.rm = T)
winner_0_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$winner)==T&is.na(crosstab$english)==F]), na.rm = T)
winner_0_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$winner)==T&is.na(crosstab$english)==T]), na.rm = T)
# calculate conditional probabilities of english==1
p_eng1_given_winner0 <- winner_0_eng_1 / (winner_0_eng_1 + winner_0_eng_0)
p_eng1_given_winner1 <- winner_1_eng_1 / (winner_1_eng_1 + winner_1_eng_0)
pass_to_iteration2 <- ifelse(winner[3]==T, winner_0_eng_1+winner_0_eng_0, winner_1_eng_1+winner_1_eng_0)
# predict
if (winner[3]==T) {
  prediction_is_english <- ifelse(p_eng1_given_winner1>p_eng1_given_winner0,1,0)
  iteration1_predeng1_correct <- winner_1_eng_1 * prediction_is_english
  iteration1_predeng1_wrong   <- winner_1_eng_0 * prediction_is_english
  iteration1_predeng0_correct <- winner_1_eng_0 * (1-prediction_is_english)
  iteration1_predeng0_wrong   <- winner_1_eng_1 * (1-prediction_is_english)
} else {
  prediction_is_english <- ifelse(p_eng1_given_winner1<p_eng1_given_winner0,1,0)
  iteration1_predeng1_correct <- winner_0_eng_1 * prediction_is_english
  iteration1_predeng1_wrong   <- winner_0_eng_0 * prediction_is_english
  iteration1_predeng0_correct <- winner_0_eng_0 * (1-prediction_is_english)
  iteration1_predeng0_wrong   <- winner_0_eng_1 * (1-prediction_is_english)
}

### evaluate step2

crosstab <- as.data.frame(crosstab_large)[is.na(crosstab_large$winner)==winner[3],]
silver_1_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$silver)==F&is.na(crosstab$english)==F]), na.rm = T)
silver_1_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$silver)==F&is.na(crosstab$english)==T]), na.rm = T)
silver_0_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$silver)==T&is.na(crosstab$english)==F]), na.rm = T)
silver_0_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$silver)==T&is.na(crosstab$english)==T]), na.rm = T)
# calculate conditional probabilities of english==1
p_eng1_given_silver0 <- silver_0_eng_1 / (silver_0_eng_1 + silver_0_eng_0)
p_eng1_given_silver1 <- silver_1_eng_1 / (silver_1_eng_1 + silver_1_eng_0)
pass_to_iteration3 <- ifelse(silver[3]==T, silver_0_eng_1+silver_0_eng_0, silver_1_eng_1+silver_1_eng_0)
#predict
if (silver[3]==T) {
  prediction_is_english <- ifelse(p_eng1_given_silver1>p_eng1_given_silver0,1,0)
  iteration2_predeng1_correct <- silver_1_eng_1 * prediction_is_english
  iteration2_predeng1_wrong   <- silver_1_eng_0 * prediction_is_english
  iteration2_predeng0_correct <- silver_1_eng_0 * (1-prediction_is_english)
  iteration2_predeng0_wrong   <- silver_1_eng_1 * (1-prediction_is_english)
} else {
  prediction_is_english <- ifelse(p_eng1_given_silver1<p_eng1_given_silver0,1,0)
  iteration2_predeng1_correct <- silver_0_eng_1 * prediction_is_english
  iteration2_predeng1_wrong   <- silver_0_eng_0 * prediction_is_english
  iteration2_predeng0_correct <- silver_0_eng_0 * (1-prediction_is_english)
  iteration2_predeng0_wrong   <- silver_0_eng_1 * (1-prediction_is_english)
}

### evaluate step2

crosstab <- as.data.frame(crosstab_large)[is.na(crosstab_large$winner)==winner[3]&is.na(crosstab_large$silver)==silver[3],]
bronze_1_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$bronze)==F&is.na(crosstab$english)==F]), na.rm = T)
bronze_1_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$bronze)==F&is.na(crosstab$english)==T]), na.rm = T)
bronze_0_eng_1 <- sum(as.numeric(crosstab$ads[is.na(crosstab$bronze)==T&is.na(crosstab$english)==F]), na.rm = T)
bronze_0_eng_0 <- sum(as.numeric(crosstab$ads[is.na(crosstab$bronze)==T&is.na(crosstab$english)==T]), na.rm = T)
# calculate conditional probabilities of english==1
p_eng1_given_bronze0 <- bronze_0_eng_1 / (bronze_0_eng_1 + bronze_0_eng_0)
p_eng1_given_bronze1 <- bronze_1_eng_1 / (bronze_1_eng_1 + bronze_1_eng_0)
#predict
prediction_is_english_for_bronze1 <- ifelse(p_eng1_given_bronze1>p_eng1_given_bronze0,1,0)
iteration3_predeng1_correct <- bronze_1_eng_1 * prediction_is_english_for_bronze1 + bronze_0_eng_1 * (1-prediction_is_english_for_bronze1)
iteration3_predeng1_wrong   <- bronze_1_eng_0 * prediction_is_english_for_bronze1 + bronze_0_eng_0 * (1-prediction_is_english_for_bronze1)
iteration3_predeng0_correct <- bronze_0_eng_0 * prediction_is_english_for_bronze1 + bronze_1_eng_0 * (1-prediction_is_english_for_bronze1)
iteration3_predeng0_wrong   <- bronze_0_eng_1 * prediction_is_english_for_bronze1 + bronze_1_eng_1 * (1-prediction_is_english_for_bronze1)

prediction_it1 <- c(iteration1_predeng1_correct, iteration1_predeng1_wrong, iteration1_predeng0_correct, iteration1_predeng0_wrong, pass_to_iteration2)
prediction_it2 <- c(iteration2_predeng1_correct, iteration2_predeng1_wrong, iteration2_predeng0_correct, iteration2_predeng0_wrong, pass_to_iteration3)
prediction_it3 <- c(iteration3_predeng1_correct, iteration3_predeng1_wrong, iteration3_predeng0_correct, iteration3_predeng0_wrong, 0)
prediction <- as.data.frame(rbind(prediction_it1,prediction_it2, prediction_it3))
colnames(prediction) <- c("iteration1_predeng_correct", "iteration_predeng1_wrong", "iteration_predeng0_correct", "iteration_predeng0_wrong", "pass_to_next_iteration")

write.csv(prediction, paste0("prediction_",namextension,".csv"))

read.csv(paste0("prediction_",namextension,".csv"))
TP <- sum(prediction$iteration1_predeng_correct)
FP <- sum(prediction$iteration_predeng1_wrong)
TN <- sum(prediction$iteration_predeng0_correct)
FN <- sum(prediction$iteration_predeng0_wrong)
accuracy <- (TP+TN) / (TP+FP+TN+FN)
accuracy_random <- ((TP+FN) / (TP+FP+TN+FN))^2 + ((TN+FP) / (TP+FP+TN+FN))^2
write.csv(c(accuracy, accuracy_random), paste0("accuracy_comparison", namextension,".csv"))

###############################################################
### 6. explorative analysis
###############################################################

plot_table <- skillist_clean
#plot_table <- readRDS("skillist_clean_it1.rds")
plot(plot_table$mingini[plot_table$gini!=1], plot_table$gini[plot_table$gini!=1])
plot(as.numeric(1:length(plot_table$mingini[plot_table$gini!=1])), plot_table$gini[plot_table$gini!=1])



