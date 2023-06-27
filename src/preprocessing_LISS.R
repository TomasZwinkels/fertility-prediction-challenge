	
# working dirs e.t.c.
	setwd("C:\Users\zwinkels\LISS_STL-Trio-Titans\fertility-prediction-challenge\rscripts")
	getwd()

# package

		# packages
	#	library(sqldf)
	#	library(stringr)
	#	library(lubridate)
	#	library(ggplot2)
		library(stargazer)
		library(dplyr)
	#	library(reshape)
	#	library(TraMineR)
	#	library(lawstat)
	#	library(beanplot)
	#	library(stringr)
	#	library(foreach)
	#	library(doParallel)
	#	library(lme4)
	#	library(car)
	#	library(ggpubr)
	#	library(sjPlot)
	#	library(effects)
	#	library(jtools)
	#	library(openxlsx)

# load the liss data

	# import and inspect features
	LISS = read.csv("LISS_example_input_data.csv", header = TRUE)
	summary(LISS)
	head(names(LISS))
	
	# import and inspect target
	LIGT = read.csv("LISS_example_groundtruth_data.csv", header = TRUE)
	summary(LIGT)
	names(LIGT)
	
	summary(LIGT$new_child)
	table(LIGT$new_child)
	
# merge (so we can filter)

	# sqldf sollution (trows a 'to many columns' error)
	nrow(LISS)
	LISSBU <- sqldf("SELECT LISS.*, LIGT.new_child
					FROM LISS LEFT JOIN LIGT
					ON LISS.nomem_encr = LIGT.nomem_encr
					")
	nrow(LISSBU)
	
	# tidyverse solution
	nrow(LISS)
	LISSBU <- LISS %>% left_join(LIGT, by = "nomem_encr")	
	nrow(LISSBU)
	
# focus on the cases that we have the target foreach
	LISSBU <- LISSBU[which(!is.na(LISSBU$new_child)),]
	nrow(LISSBU)
	sum(table(LIGT$new_child))
	
# now, lets get the % of missingness for an array of variables names

varstocheck <- c("nomem_encr",
                 "new_child",
				 "gebjaar",
                 "geslacht",
				 "herkomstgroep2019",
				 "burgstat2019",
				 "partner2019",
				 "aantalki2019",
				 "oplzon2019", # highest eduation irrespective of diploma
				 "brutoink_f2019", # Personal gross monthly income in Euros, imputed
                 "cf19l128", # in 2019 - 'do you think you will have [more] children in the future
				 "cf14g035", # have you had any children in 2014
				 "cf14g036", # How many children have you had in total in 2014
				 "cf19l148",	 # in 2019 - there are a couple of interesting family support measures about this "Did you provide any help to your mother over the past 3 months in doing household work, such as preparing food, cleaning, grocery shopping, or doing the laundry?
                 "cf19l180", #  in 2019 - How satisfied are you with your current relationship?
				 "cf19l181", # in 2019 - How satisfied are you with your family life?
				 "cf19l398", # Constructed variable: distance between panel member and parents' place of residence in meters
				 "cf19l508", # I feel closely connected to my mother in 2019
				 "ca18f057", # On 31 December 2017, did you have one or more personal loans, revolving credit arrangement(s), or financing credit(s) based on a hire-purchase or installment plan?
				 "cd19l041", # in 2019 - Does your dwelling have one or more of the following problems? - the dwelling is too small
				 "ci19l006" # in 2019 - How satisfied are you with your financial situation?
				)
	# 

	# check if they occur
	varstocheck %in% names(LISSBU)
	
	FOCC <- LISSBU[,which(names(LISSBU) %in% varstocheck)]
	head(FOCC)
	
	FOCC <- as_tibble(FOCC)
	
# rename the variables
FOCC <- FOCC %>% dplyr::rename(    
			  #  nomem_encr = nomem_encr,
			  #  new_child = new_child,
				birth_yr = gebjaar,
				gender = geslacht,
				origin_2019 = herkomstgroep2019,
				burgstat2019 = burgstat2019,
				partner2019 = partner2019,
				nr_child_2014 = cf14g036,
				nr_child_2019 = aantalki2019,
				highest_educ = oplzon2019, 
				inc_bruto_monthly = brutoink_f2019, 
				want_more_chil_2019 = cf19l128,
				any_child_2014 = cf14g035,
				mother_help_household = cf19l148,
				relation_satisf = cf19l180,
				family_satisf = cf19l181,
				distance_to_parents_inmeters = cf19l398,
				feel_close_to_mom = cf19l508,
				creditcard_loans = ca18f057,
				dwelling_to_small = cd19l041,
				financial_satis = ci19l006
			)

names(FOCC)

# get the percentage of missingness per columns
	missing_perc <- sapply(FOCC, function(x) sum(is.na(x))/length(x)*100)
	missing_perc

# bunch of recoding
	summary(FOCC)
	
# gender
	table(FOCC$gender)
	FOCC$gender <- as.factor(FOCC$gender)
	
# nr_child_2019
	table(FOCC$nr_child_2019)

		# Create a mapping from strings to numbers
		FOCC <- FOCC %>%
		  mutate(
			nr_child_2019_num = case_when(
			  nr_child_2019 == "None" ~ 0,
			  nr_child_2019 == "One child" ~ 1,
			  nr_child_2019 == "Two children" ~ 2,
			  nr_child_2019 == "Three children" ~ 3,
			  nr_child_2019 == "Four children" ~ 4,
			  nr_child_2019 == "Five children" ~ 5,
			  nr_child_2019 == "Six children" ~ 6
			)
		  )

		# Verify the changes
		table(FOCC$nr_child_2019)
		summary(FOCC)
		
# partner2019
	table(FOCC$partner2019)

# burgstat2019
	table(FOCC$burgstat2019)

# highest_educ
	table(FOCC$highest_educ)

# inc_bruto_monthly
	hist(FOCC$inc_bruto_monthly,breaks=30)
	
# origin_2019
	table(FOCC$origin_2019)
	
# any_child_2014
	table(FOCC$any_child_2014)
	
	FOCC <- FOCC %>%
		  mutate(
			any_child_2014 = case_when(
			  any_child_2014 == 1 ~ "yes",
			  any_child_2014 == 2 ~ "no"
			)
		  )
	
	table(FOCC$any_child_2014)
	
# nr_child_2014
	table(FOCC$nr_child_2014)

# want_more_chil_2019
	table(FOCC$want_more_chil_2019)
	
			FOCC <- FOCC %>%
		  mutate(
			want_more_chil_2019 = case_when(
			  want_more_chil_2019 == 1 ~ "yes",
			  want_more_chil_2019 == 2 ~ "no",
			  want_more_chil_2019 == 3 ~ "dont_know"
			)
		  )
	
	table(FOCC$want_more_chil_2019)
	
# mother_help_household
	table(FOCC$mother_help_household)
			
			FOCC <- FOCC %>%
		  mutate(
			mother_help_household = case_when(
			  mother_help_household == 1 ~ "no",
			  mother_help_household == 2 ~ "once or twice",
			  mother_help_household == 3 ~ "several times"
			)
		  )
		  
	table(FOCC$mother_help_household)
	
# relation_satisf  
	table(FOCC$relation_satisf)

# family_satisf
	table(FOCC$family_satisf)
	
# distance_to_parents_inmeters 
	hist(FOCC$distance_to_parents_inmeters,breaks=100)

# feel_close_to_mom
	table(FOCC$feel_close_to_mom)
	
# creditcard_loans 
	table(FOCC$creditcard_loans)

# dwelling_to_small 
	table(FOCC$dwelling_to_small)

# financial_satis 
	table(FOCC$financial_satis)
	
	
### export into a dataformat python can work with
	install.packages("feather")
	library(feather)
	write_feather(FOCC, "FOCC.feather")
	
	
### do some inspections

	# Check the structure of the dataframe
	str(FOCC)

