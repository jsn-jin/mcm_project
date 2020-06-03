#***************************************************************************
# WORST CASE MODEL FOR MACKEREL
# Dataset: 
#     "forecast_sst_50_t.csv"      forcasted data from 2020-2069, transposed
# Author: Daphne Chen
#***************************************************************************
# Worst case sst range parameter: 9.98-10.2 C
#***************************************************************************

# Library needed packages
library(tidyverse)

set.seed(42)

# Import forecasted data
sst = read_csv("forecast_sst_50_t.csv", col_names = TRUE)
head(sst)

# Data frame to keep track of each run of the model
# Each row is a simulation
# Each col is an year
worst_case_mack_df <- data.frame(matrix(NA, nrow = 100, ncol = 51))

left_edge <- seq(from=1, to=300, by=20)
right_edge <- seq(from=20, to=300, by=20)

for(i in 1:100) {
	worst_case_mack_df[i, 1] <- sst[[116, 1]]
 
 	# Start block index and year
  	current_block <- 116 # 57.5, -1.5 
  	current_year <- 2020
  	prev_block <- 0
  
  	j <- 2
  	while(current_year < 2070 & current_block > 0) {
    
    		# Check if current location's temperature is still within habitable range
    		current_block_temp <- sst[[current_block, as.character(current_year)]]
    		if(9.98 <= current_block_temp & current_block_temp <= 10.20) {
      		current_year <- current_year + 1
      		worst_case_mack_df[i, j] <- sst[[current_block, 1]]
      		j <- j + 1
      		next
    		}
    
    		# corresponding indices for surrounding blocks
    		north <- current_block-20
    		west <- current_block-1
    		south <- current_block+20
    		east <- current_block+1
    		northwest <- current_block-21
    		southwest <- current_block+19
    		southeast <- current_block+21
    		northeast <- current_block-19
    
    		# Vector to keep track of which adjacent blocks are within temperature range
    		if(current_block %in% left_edge) {
    		  adjacent <- c(north, south, east, southeast, northeast)
    		} else if(current_block %in% right_edge) {
    		  adjacent <- c(north, west, south, northwest, southwest)
    		} else {
    		  adjacent <- c(north, west, south, east, northwest, southwest, southeast, northeast)
    		}
    
    		# Average temperature of range in the case that none of the block are within range
    		avg_temp <- 10.09
    
    		# Best option if no blocks are within temperature range
    		best <- abs(10.09 - current_block_temp)
    
    		# Initialize what the index of the new block to be migrated to
    		new_block <- current_block
    		adjacent_copy <- adjacent
    
    		# Check whether we have data for each direction AND 
    		# if the block is above or below threshold temperature
    		
    		for(direction in adjacent) {
    			# if block is out of range (no data) or not within temperature range, 
    			# remove the option from the adjacent vector
      		if(direction > 300 || direction < 1) {
        			adjacent_copy <- adjacent_copy[adjacent_copy != direction]
        			next
      		}
      
      		temp <- sst[[direction, as.character(current_year)]]
      
      		if(is.na(temp)) {
        			adjacent_copy <- adjacent_copy[adjacent_copy != direction]
        			next
      		}
      
      		if(!(9.98 <= temp & temp <= 10.20)) {
        			if(abs(avg_temp - temp) < best) {
          			best <- abs(avg_temp - temp)
          			new_block <- direction
        			}
        
        			if(new_block == current_block & north > 0 & !is.na(sst[[north, 2]])) {
          			new_block <- north
        			}
        		
        			adjacent_copy <- adjacent_copy[adjacent_copy != direction]
      		}
    		}
    
        
    		# of the blocks that are in temperature range, choose one at random to migrate to
    		if(length(adjacent_copy) > 1) {
      		new_block <- sample(adjacent_copy, 1)
    		}
    
    		if(length(adjacent_copy) == 1) {
      		new_block <- adjacent_copy
    		}
    
    		# If new block is a previous block and not in temp range, move north
    		if(new_block == prev_block) {
      		if(!(9.98 <= current_block_temp & current_block_temp <= 10.20) & north > 0 & !is.na(sst[[north, 2]])) {
        			new_block <- north
      		}
   		}
    
    		# Increment year
    		current_year <- current_year + 1
    		prev_block <- current_block
    		current_block <- new_block
    
    		# Migration_pat <- c(migration_pat, sst[[new_block, 1]])
    		worst_case_mack_df[i, j] <- sst[[new_block, 1]]
    		j <- j + 1
  	}
}

write.csv(worst_case_mack_df, file = "wc_mackerel.csv")