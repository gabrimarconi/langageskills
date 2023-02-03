


source("libraries.R")
source("libraries_eurostat.R")
setup_access("user")

varlist <- colnames(get_data("SELECT * FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 LIMIT 1"))
varlist


###################################################################################
### English
###################################################################################

##write a query in SQL that returns the number of ads with english and each other skill, by skill
#table1 <- paste0("SELECT oja_id, 1 AS english FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' GROUP BY oja_id  UNION SELECT oja_id, 0 AS english FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' GROUP BY oja_id  ORDER BY RAND() LIMIT 2000000")
#table2 <- paste0("SELECT DISTINCT oja_id,  nuts3_id, country_id, occupation1d_id, economic_activity1d_id, contract_id, salary_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021")
##test1 <- get_data(paste0(table1, " "))
##test2 <- get_data(paste0(table2, " LIMIT 100"))
#joinquery <- paste0(
#  "WITH table1 AS (",table1,"),
#        table2 AS (",table2,")
#  SELECT oja_id,  nuts3_id, country_id, occupation1d_id, economic_activity1d_id, contract_id, salary_id FROM table1 LEFT JOIN table2 USING(oja_id) LIMIT 10000000"  )
#crosstab <- get_data(joinquery)
#saveRDS(crosstab, "regsample_withduplicates_english.rds")
#crosstab <- crosstab[!duplicated(oja_id),]
#saveRDS(crosstab, "regsample_english.rds")
#write.csv(crosstab, "regsample_english.csv")

# select depvar
depvar <- "contract_id"
depvar <- "salary_id"

# filter for any language other than English
otherfl <- " (skill='German' OR skill='Spanish' OR skill='Chinese' OR skill='French' OR skill='Basque' OR skill='Dutch' OR skill='Arabic' OR skill='Finnish' OR skill='Italian' OR skill='Polish' OR skill='Welsh' OR skill='Norwegian' OR skill='Swedish' OR skill='Latvian' OR skill='Russian' OR skill='Czech' OR skill='Danish' OR skill='Hungarian' OR skill='Greek' OR skill='Icelandic' OR skill='Slovak' OR skill='Croatian' OR skill='Turkish' OR skill='Romanian' OR skill='Slovenian' OR skill='Bulgarian' OR skill='Bihari' OR skill='Portuguese' OR skill='Maltese') "
otherfl <- " (skill='German') "


# other filters as relevant
filters_list <- paste0(depvar,"!='' AND nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")
#filters_list <- paste0("nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")

#write a query in SQL that returns the number of ads with english and each other skill, by skill
list_en <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",filters_list)
list_ot <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",otherfl,"  AND ",filters_list)
list_no <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",otherfl,"  AND ",filters_list)
table1  <- paste0("SELECT oja_id, 1 AS english, 1 AS otherfl FROM list_en JOIN list_ot USING(oja_id) ORDER BY RAND() LIMIT 500000")
table2  <- paste0("SELECT oja_id, 1 AS english, 0 AS otherfl FROM list_en JOIN list_no USING(oja_id) ORDER BY RAND() LIMIT 500000")
table3  <- paste0("SELECT oja_id, 0 AS english, 1 AS otherfl FROM list_ne JOIN list_ot USING(oja_id) ORDER BY RAND() LIMIT 500000")
table4  <- paste0("SELECT oja_id, 0 AS english, 0 AS otherfl FROM list_ne JOIN list_no USING(oja_id) ORDER BY RAND() LIMIT 500000")
table5 <- paste0("SELECT DISTINCT oja_id, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021")
#test1 <- get_data(paste0(table1, " "))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ot AS (",list_ot,"),
        list_no AS (",list_no,"),
        table1  AS (",table1,"),
        table2  AS (",table2,"),
        table3  AS (",table3,"),
        table4  AS (",table4,"),
        table1234 AS (SELECT * FROM table1 UNION SELECT * FROM table2 UNION SELECT * FROM table3 UNION SELECT * FROM table4),
        table5 AS (",table5,")
  SELECT oja_id, english, otherfl, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM table1234 LEFT JOIN table5 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_withduplicates_english.rds"))
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_english.rds"))
write.csv(crosstab, paste0("regsample_",depvar,"_english.csv"))



#write a query in SQL that returns the number of ads with english and each other skill, by skill
list_en <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",depvar,"!='' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",depvar,"!='' AND ",filters_list)
list_ot <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",otherfl,"  AND ",depvar,"!='' AND ",filters_list)
list_no <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",otherfl,"  AND ",depvar,"!='' AND ",filters_list)
table1  <- paste0("SELECT 'enot' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_en JOIN list_ot USING(oja_id) LIMIT 2")
table2  <- paste0("SELECT 'enno' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_en JOIN list_no USING(oja_id) LIMIT 2")
table3  <- paste0("SELECT 'neot' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ne JOIN list_ot USING(oja_id) LIMIT 2")
table4  <- paste0("SELECT 'neno' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ne JOIN list_no USING(oja_id) LIMIT 2")
#test1 <- get_data(paste0(table1, " "))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ot AS (",list_ot,"),
        list_no AS (",list_no,"),
        table1  AS (",table1,"),
        table2  AS (",table2,"),
        table3  AS (",table3,"),
        table4  AS (",table4,"),
        table1234 AS (SELECT * FROM table1 UNION SELECT * FROM table2 UNION SELECT * FROM table3 UNION SELECT * FROM table4)
    SELECT * FROM table1234 LIMIT 10000000"  )
Ns <- get_data(joinquery)
write.csv(Ns, paste0("Ns_",depvar,"_english.csv"))


###################################################################################
### English, german and chinese
###################################################################################

##write a query in SQL that returns the number of ads with english and each other skill, by skill
#table1 <- paste0("SELECT oja_id, 1 AS english FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' GROUP BY oja_id  UNION SELECT oja_id, 0 AS english FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' GROUP BY oja_id  ORDER BY RAND() LIMIT 2000000")
#table2 <- paste0("SELECT DISTINCT oja_id,  nuts3_id, country_id, occupation1d_id, economic_activity1d_id, contract_id, salary_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021")
##test1 <- get_data(paste0(table1, " "))
##test2 <- get_data(paste0(table2, " LIMIT 100"))
#joinquery <- paste0(
#  "WITH table1 AS (",table1,"),
#        table2 AS (",table2,")
#  SELECT oja_id,  nuts3_id, country_id, occupation1d_id, economic_activity1d_id, contract_id, salary_id FROM table1 LEFT JOIN table2 USING(oja_id) LIMIT 10000000"  )
#crosstab <- get_data(joinquery)
#saveRDS(crosstab, "regsample_withduplicates_english.rds")
#crosstab <- crosstab[!duplicated(oja_id),]
#saveRDS(crosstab, "regsample_english.rds")
#write.csv(crosstab, "regsample_english.csv")

# select depvar
depvar <- "contract_id"
depvar <- "salary_id"

# filter for any language other than English
chinese <- " (skill='Chinese') "
german <- " (skill='German') "


# other filters as relevant
if (depvar=="salary_id") {filter0 <- paste0(depvar,"!='' AND ")} else {filter0 <- ""}
filters_list <- paste0(filter0," nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")
#filters_list <- paste0("nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")

#write a query in SQL that returns the number of ads with english and each other skill, by skill
list_en <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",filters_list)
list_ge <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",german ,"  AND ",filters_list)
list_ng <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",german ,"  AND ",filters_list)
list_ch <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",chinese,"  AND ",filters_list)
list_nc <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",chinese,"  AND ",filters_list)
table1  <- paste0("SELECT oja_id, 1 AS chinese, 1 AS english, 1 AS german FROM list_ch JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 100000")
table2  <- paste0("SELECT oja_id, 1 AS chinese, 1 AS english, 0 AS german FROM list_ch JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 100000")
table3  <- paste0("SELECT oja_id, 1 AS chinese, 0 AS english, 1 AS german FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 100000")
table4  <- paste0("SELECT oja_id, 1 AS chinese, 0 AS english, 0 AS german FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 100000")
table5  <- paste0("SELECT oja_id, 0 AS chinese, 1 AS english, 1 AS german FROM list_nc JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) ORDER BY RAND() LIMIT 100000")
table6  <- paste0("SELECT oja_id, 0 AS chinese, 1 AS english, 0 AS german FROM list_nc JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 1000000")
table7  <- paste0("SELECT oja_id, 0 AS chinese, 0 AS english, 1 AS german FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) ORDER BY RAND() LIMIT 100000")
table8  <- paste0("SELECT oja_id, 0 AS chinese, 0 AS english, 0 AS german FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 1000000")
table9 <- paste0("SELECT DISTINCT oja_id, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021")
#test1 <- get_data(paste0(table1, " "))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        table1  AS (",table1,"),
        table2  AS (",table2,"),
        table3  AS (",table3,"),
        table4  AS (",table4,"),
        table5  AS (",table5,"),
        table6  AS (",table6,"),
        table7  AS (",table7,"),
        table8  AS (",table8,"),
        table12345678 AS (SELECT * FROM table1 UNION SELECT * FROM table2 UNION SELECT * FROM table3 UNION SELECT * FROM table4 UNION SELECT * FROM table5 UNION SELECT * FROM table6 UNION SELECT * FROM table7 UNION SELECT * FROM table8),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM table12345678 LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_withduplicates_english.rds"))
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_english.rds"))
write.csv(crosstab, paste0("regsample_",depvar,"_english.csv"))



#write a query in SQL that returns the number of ads with english and each other skill, by skill
list_en <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",filters_list)
list_ge <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",german ,"  AND ",filters_list)
list_ng <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",german ,"  AND ",filters_list)
list_ch <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",chinese,"  AND ",filters_list)
list_nc <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",chinese,"  AND ",filters_list)
table1  <- paste0("SELECT 'ceg' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2")
table2  <- paste0("SELECT 'ceo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2")
table3  <- paste0("SELECT 'cog' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2")
table4  <- paste0("SELECT 'coo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2")
table5  <- paste0("SELECT 'oeg' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2")
table6  <- paste0("SELECT 'oeo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2")
table7  <- paste0("SELECT 'oog' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2")
table8  <- paste0("SELECT 'ooo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2")
#test1 <- get_data(paste0(table1, " "))
#test2 <- get_data(paste0(table2, " LIMIT 100"))
joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        table1  AS (",table1,"),
        table2  AS (",table2,"),
        table3  AS (",table3,"),
        table4  AS (",table4,"),
        table5  AS (",table5,"),
        table6  AS (",table6,"),
        table7  AS (",table7,"),
        table8  AS (",table8,"),
        table12345678 AS (SELECT * FROM table1 UNION SELECT * FROM table2 UNION SELECT * FROM table3 UNION SELECT * FROM table4 UNION SELECT * FROM table5 UNION SELECT * FROM table6 UNION SELECT * FROM table7 UNION SELECT * FROM table8)
    SELECT * FROM table12345678 LIMIT 10000000"  )
Ns <- get_data(joinquery)
write.csv(Ns, paste0("Ns_",depvar,"_engech.csv"))



###################################################################################
### English, german and chinese - light
###################################################################################


# select depvar
depvar <- "contract_id"
depvar <- "salary_id"

# filter for any language other than English
chinese <- " (skill='Chinese') "
german <- " (skill='German') "


# other filters as relevant
if (depvar=="salary_id") {filter0 <- paste0(depvar,"!='' AND ")} else {filter0 <- ""}
filters_list <- paste0(filter0," nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")
#filters_list <- paste0("nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")

#write a query in SQL that returns the number of ads with english and each other skill, by skill
list_en <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",filters_list)
list_ge <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",german ,"  AND ",filters_list)
list_ng <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",german ,"  AND ",filters_list)
list_ch <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",chinese,"  AND ",filters_list)
list_nc <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",chinese,"  AND ",filters_list)
table1  <- paste0("SELECT oja_id, 1 AS chinese, 1 AS english, 1 AS german FROM list_ch JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) ORDER BY RAND() LIMIT 100000")
table2  <- paste0("SELECT oja_id, 1 AS chinese, 1 AS english, 0 AS german FROM list_ch JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 100000")
table3  <- paste0("SELECT oja_id, 1 AS chinese, 0 AS english, 1 AS german FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) ORDER BY RAND() LIMIT 100000")
table4  <- paste0("SELECT oja_id, 1 AS chinese, 0 AS english, 0 AS german FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 100000")
table5  <- paste0("SELECT oja_id, 0 AS chinese, 1 AS english, 1 AS german FROM list_nc JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) ORDER BY RAND() LIMIT 100000")
table6  <- paste0("SELECT oja_id, 0 AS chinese, 1 AS english, 0 AS german FROM list_nc JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 1000000")
table7  <- paste0("SELECT oja_id, 0 AS chinese, 0 AS english, 1 AS german FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) ORDER BY RAND() LIMIT 100000")
table8  <- paste0("SELECT oja_id, 0 AS chinese, 0 AS english, 0 AS german FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) ORDER BY RAND() LIMIT 1000000")
table9 <- paste0("SELECT DISTINCT oja_id, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021")
#test1 <- get_data(paste0(table1, " "))
#test2 <- get_data(paste0(table2, " LIMIT 100"))



# crosstab1

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table1,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab1 <- crosstab


# crosstab2

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table2,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab2 <- crosstab


# crosstab3

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table3,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab3 <- crosstab


# crosstab4

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table4,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab4 <- crosstab



# crosstab5

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table5,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab5 <- crosstab



# crosstab6

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table6,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab6 <- crosstab



# crosstab7

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table7,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab7 <- crosstab


# crosstab8

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        tablex  AS (",table8,"),
        table9 AS (",table9,")
  SELECT oja_id, english, german, chinese, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM tablex LEFT JOIN table9 USING(oja_id) LIMIT 10000000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab8 <- crosstab


# append crosstabs
crosstab <- crosstab1
crosstab <- rbind(crosstab, crosstab1)
crosstab <- rbind(crosstab, crosstab2)
crosstab <- rbind(crosstab, crosstab3)
crosstab <- rbind(crosstab, crosstab4)
crosstab <- rbind(crosstab, crosstab5)
crosstab <- rbind(crosstab, crosstab6)
crosstab <- rbind(crosstab, crosstab7)
crosstab <- rbind(crosstab, crosstab8)

dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_withduplicates_engech.rds"))
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_engech.rds"))
write.csv(crosstab, paste0("regsample_",depvar,"_engech.csv"))




#write a query in SQL that returns the number of ads with english and each other skill, by skill
list_en <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",filters_list)
list_ge <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",german ,"  AND ",filters_list)
list_ng <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",german ,"  AND ",filters_list)
list_ch <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",chinese,"  AND ",filters_list)
list_nc <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",chinese,"  AND ",filters_list)
table1  <- get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                    " SELECT 'ceg' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2"))
table2  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'ceo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2"))
table3  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'cog' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2"))
table4  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'coo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_ch JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2"))
table5  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'oeg' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_en USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2"))
table6  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'oeo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_en USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2"))
table7  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'oog' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ge USING(oja_id) LIMIT 2"))
table8  <-  get_data(paste0("WITH list_en AS (",list_en,"), list_ne AS (",list_ne,"),  list_ge AS (",list_ge,"), list_ng AS (",list_ng,"), list_ch AS (",list_ch,"), list_nc AS (",list_nc,")", 
                            "SELECT 'ooo' AS gruppo, COUNT (DISTINCT oja_id) AS ads FROM list_nc JOIN list_ne USING(oja_id) JOIN list_ng USING(oja_id) LIMIT 2"))
Ns <- rbind(table1,table2, table3, table4, table5, table6, table7, table8)
write.csv(Ns, paste0("Ns_",depvar,"_engech.csv"))



###################################################################################
### English, german, chinese and other fls - light
###################################################################################





# select depvar
depvar <- "contract_id"
depvar <- "salary_id"

# filter for any language other than English
chinese <- " (skill='Chinese') "
german <- " (skill='German') "
otherfl <- " (skill='Spanish' OR skill='French' OR skill='Basque' OR skill='Dutch' OR skill='Arabic' OR skill='Finnish' OR skill='Italian' OR skill='Polish' OR skill='Welsh' OR skill='Norwegian' OR skill='Swedish' OR skill='Latvian' OR skill='Russian' OR skill='Czech' OR skill='Danish' OR skill='Hungarian' OR skill='Greek' OR skill='Icelandic' OR skill='Slovak' OR skill='Croatian' OR skill='Turkish' OR skill='Romanian' OR skill='Slovenian' OR skill='Bulgarian' OR skill='Bihari' OR skill='Portuguese' OR skill='Maltese') "


# other filters as relevant
if (depvar=="salary_id") {filter0 <- paste0(depvar,"!='' AND ")} else {filter0 <- ""}
filters_list <- paste0(filter0," nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")
#filters_list <- paste0("nuts2_id!='' AND occupation1d_id!='OC6' AND economic_activity1d_id!='' AND economic_activity1d_id!='A' AND working_time_id!='PT'")


table0 <- paste0("SELECT DISTINCT oja_id, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar," FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND ",filters_list)
list_en <- paste0("SELECT DISTINCT oja_id, 1 AS english FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill ='English' AND ",filters_list)
list_ne <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND skill!='English' AND ",filters_list)
list_ge <- paste0("SELECT DISTINCT oja_id, 1 AS german FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",german ,"  AND ",filters_list)
list_ng <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",german ,"  AND ",filters_list)
list_ch <- paste0("SELECT DISTINCT oja_id, 1 AS chinese FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",chinese,"  AND ",filters_list)
list_nc <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",chinese,"  AND ",filters_list)
list_th <- paste0("SELECT DISTINCT oja_id, 1 AS otherfl FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND     ",otherfl ," AND ",filters_list)
list_nt <- paste0("SELECT DISTINCT oja_id FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND NOT ",otherfl ," AND ",filters_list)

#test1 <- get_data(paste0(table1, " "))
#test2 <- get_data(paste0(table2, " LIMIT 100"))



# crosstab_main

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        list_th AS (",list_th,"),
        list_nt AS (",list_nt,"),
        table0  AS (",table0,")
  SELECT oja_id, english, german, chinese, otherfl, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar,", 'main' AS datatable FROM table0 LEFT JOIN list_en USING(oja_id) LEFT JOIN list_ge USING(oja_id) LEFT JOIN list_ch USING(oja_id) LEFT JOIN list_th USING(oja_id) ORDER BY RAND() LIMIT 1500000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
crosstab_main <- crosstab
dim(crosstab_main)

# crosstab_german

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        list_th AS (",list_th,"),
        list_nt AS (",list_nt,"),
        table0  AS (",table0,")
  SELECT oja_id, english, german, chinese, otherfl, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar,", 'german' AS datatable FROM table0 LEFT JOIN list_en USING(oja_id) LEFT JOIN list_ge USING(oja_id) LEFT JOIN list_ch USING(oja_id) LEFT JOIN list_th USING(oja_id) WHERE german=1 ORDER BY RAND() LIMIT 100000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
crosstab_german <- crosstab
dim(crosstab_german)


# crosstab_chinese

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        list_th AS (",list_th,"),
        list_nt AS (",list_nt,"),
        table0  AS (",table0,")
  SELECT oja_id, english, german, chinese, otherfl, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar,", 'chinese' AS datatable FROM table0 LEFT JOIN list_en USING(oja_id) LEFT JOIN list_ge USING(oja_id) LEFT JOIN list_ch USING(oja_id) LEFT JOIN list_th USING(oja_id) WHERE chinese=1 ORDER BY RAND() LIMIT 100000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
crosstab_chinese <- crosstab
dim(crosstab_chinese)

# crosstab_otherfl

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        list_th AS (",list_th,"),
        list_nt AS (",list_nt,"),
        table0  AS (",table0,")
  SELECT oja_id, english, german, chinese, otherfl, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar,", 'otherfl' AS datatable FROM table0 LEFT JOIN list_en USING(oja_id) LEFT JOIN list_ge USING(oja_id) LEFT JOIN list_ch USING(oja_id) LEFT JOIN list_th USING(oja_id) WHERE otherfl=1 ORDER BY RAND() LIMIT 100000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
crosstab_otherfl <- crosstab
dim(crosstab_otherfl)

# crosstab_english

joinquery <- paste0(
  "WITH list_en AS (",list_en,"),
        list_ne AS (",list_ne,"),
        list_ge AS (",list_ge,"),
        list_ng AS (",list_ng,"),
        list_ch AS (",list_ch,"),
        list_nc AS (",list_nc,"),
        list_th AS (",list_th,"),
        list_nt AS (",list_nt,"),
        table0  AS (",table0,")
  SELECT oja_id, english, german, chinese, otherfl, nuts2_id, country_id, language, occupation1d_id, economic_activity1d_id, experience_id, ",depvar,", 'english' AS datatable FROM table0 LEFT JOIN list_en USING(oja_id) LEFT JOIN list_ge USING(oja_id) LEFT JOIN list_ch USING(oja_id) LEFT JOIN list_th USING(oja_id) WHERE english=1 ORDER BY RAND() LIMIT 100000"  )
crosstab <- get_data(joinquery)
dim(crosstab)
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
crosstab_english <- crosstab
dim(crosstab_english)

# crosstab
crosstab <- crosstab_main
crosstab <- rbind(crosstab, crosstab_german)
crosstab <- rbind(crosstab, crosstab_chinese)
crosstab <- rbind(crosstab, crosstab_otherfl)
crosstab <- rbind(crosstab, crosstab_english)
dim(crosstab)
saveRDS(crosstab, paste0("regsample_",depvar,"_withdup_4lang.rds"))
crosstab <- crosstab[crosstab$nuts2_id!='',]
dim(crosstab)
crosstab <- crosstab[!duplicated(oja_id),]
dim(crosstab)
write.csv(crosstab, paste0("regsample_",depvar,"_4lang.csv"))

Ns_query <- paste0("SELECT COUNT (DISTINCT oja_id), skill FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND (skill='english' OR ",german," OR ",chinese,"  OR ",otherfl,") AND ",filters_list, " GROUP BY skill LIMIT 1000")
Ns <- get_data(Ns_query)
Ns
write.csv(Ns, paste0("Ns_",depvar,"_4lang.csv"))

Ntotl_query <- paste0("SELECT COUNT (DISTINCT oja_id) AS Ntotal    FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 LIMIT 1000")
Ndata_query <- paste0("SELECT COUNT (DISTINCT oja_id) AS Nwithdata FROM WIHAccessCatalog.wih_oja_versioned.wih_oja_blended_v1_2021q4_r20220224 WHERE first_active_year=2021 AND ",filters_list, " LIMIT 1000")
Ntotl <- get_data(Ntotl_query)
Ndata <- get_data(Ndata_query)
missing <- data.frame(Ntotal = Ntotl$Ntotal, Nwithdata = Ndata$Nwithdata, missing=1-Ndata$Nwithdata/Ntotl$Ntotal)
write.csv(missing, paste0("missing_",depvar,"_4lang.csv"))
  
