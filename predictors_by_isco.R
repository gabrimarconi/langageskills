

source("libraries.R")
source("libraries_eurostat.R")
setup_access("user")

myisco <- "1d"
mylanguage <- "Chinese"


# run generic queries for total nr of ads and total number of ads requiring english, by occupation
occup_total <-   get_data(paste0("SELECT COUNT(DISTINCT oja_id) AS occup_total, occupation",myisco,"_id AS occupation_id, occupation",myisco," AS occupation FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021  GROUP BY occupation",myisco,"_id, occupation",myisco," LIMIT 1000000"))
occup_fl <-      get_data(paste0("SELECT COUNT(DISTINCT oja_id) AS occup_fl, occupation",myisco,"_id AS occupation_id, occupation",myisco," AS occupation FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill='",mylanguage,"' GROUP BY occupation",myisco,"_id, occupation",myisco," LIMIT 1000000"))
occup_list <- occup_total$occupation_id



### write function to calculate gini
calculate_pcp <- function(myoccup) {
  #myoccup <- "OC54"
  #myoccup <- "OC5"
  #print(myoccup)
  
  if (myoccup!="TOTL") {
    myfilter <- paste0(" AND occupation",myisco,"_id='",myoccup,"' ")
  } else {myfilter <- paste0(" AND occupation",myisco,"_id!='' ")}
  
  
  # generic totals for myoccup
  if (myoccup!="TOTL") {
    N_all <- occup_total$occup_total[occup_total$occupation_id==myoccup]
    N_english <- occup_fl$occup_fl[occup_fl$occupation_id==myoccup]
  } else {
    N_all <- sum(occup_total$occup_total, na.rm = T)
    N_english <- sum(occup_fl$occup_fl, na.rm = T)
  }
  share_english <- N_english /  N_all
  
  
  # write a query with the total ads with each skill for myoccup
  total_occup <- get_data(paste0("SELECT COUNT(DISTINCT oja_id) AS occup_total, skill FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 ",myfilter," GROUP BY skill LIMIT 1000000"))
  
  #write a query in SQL that returns the number of ads with english and each other skill, by skill
  table1 <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 ",myfilter," AND skill='",mylanguage,"' ")
  table2 <- paste0("SELECT oja_id, skill FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 ",myfilter," AND skill!='",mylanguage,"' AND skill!='' ")
  #test1 <- get_data(paste0(table1, " LIMIT 100"))
  #test2 <- get_data(paste0(table2, " LIMIT 100"))
  joinquery <- paste0(
    "WITH table1 AS (",table1,"),
  table2 AS (",table2,")
  SELECT COUNT(DISTINCT oja_id) AS ads, skill FROM table1 LEFT JOIN table2 USING(oja_id) GROUP BY skill 
  LIMIT 10000"  )
  crosstab <- get_data(joinquery)
  crosstab
  dim(crosstab)
  
  # edit the data table
  ginitab <- merge(crosstab, total_occup, all.x = T, all.y = F)
  ginitab <- ginitab[!is.na(ginitab$skill),]
  ginitab$occup <- myoccup
  ginitab$english_cond_skill <- ginitab$ads / ginitab$occup_total

  if (dim(crosstab)[1]>0) {
    # calculate the percentage of correctly predicted outcomes (pcp). 
    
    # calculate cell totals
    ginitab$N_englishANDskill <- ginitab$ads
    ginitab$N_NOTenglishBUTskill <- ginitab$occup_total - ginitab$ads
    ginitab$N_englishBUTNOTskill <- N_english - ginitab$N_englishANDskill
    ginitab$N_NOTenglishANDNOTskill <- N_all - ginitab$N_englishANDskill - ginitab$N_NOTenglishBUTskill - ginitab$N_englishBUTNOTskill
    
    # calculate pcps under the assumption of a negative and positive relationship, and finally the optimal pcp for each skill category
    ginitab$p_pos <- (ginitab$N_englishANDskill + ginitab$N_NOTenglishANDNOTskill) / N_all
    ginitab$p_neg <- (ginitab$N_NOTenglishBUTskill + ginitab$N_englishBUTNOTskill) / N_all
    ginitab$pcp_is_pos <- ifelse(ginitab$p_pos>ginitab$p_neg,1,0)  
    ginitab$pcp <- ginitab$pcp_is_pos*ginitab$p_pos + (1-ginitab$pcp_is_pos)*ginitab$p_neg
    
    # compile relevant info for best predicting skill
    ginitab$N_all <- N_all
    ginitab$share_english <- share_english
    winner <- ginitab[which.max(ginitab$pcp), c("occup","skill","pcp","pcp_is_pos","english_cond_skill", "share_english", "N_all")]
  } else {
    winner <- data.frame(occup=myoccup, skill=NA,pcp=NA,pcp_is_pos=NA,english_cond_skill=NA, share_english=share_english, N_all=N_all)
  }
  print(winner)
  
  # prepare and return output
  return(winner)
}
#calculate_pcp("OC12")

# apply function to all occupations, edit and save output
myoutput <- do.call(rbind, lapply(c("TOTL",occup_list), calculate_pcp))
myoutput <- merge(myoutput, occup_total[,c("occupation_id", "occupation")], all.x=T, by.x = "occup", by.y = "occupation_id")
write.csv(myoutput, paste0("top_predictor_by_isco",myisco,"_", mylanguage, ".csv"))

