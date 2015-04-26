This folder contains code for Getting and Cleaning Data Course Project.

Steps to run:

1. Load run_analysis.R in R Studio
2. Set working directory to the source file location
3. Run the script

How it works:

1. Prepares in and out directories to store the data files (refer to prepareDirs function)
2. Downloads the dataset and unzip into in folder (refer to downloadFiles function)
3. mergeFiles function - Merges the test and train data files into out folder (refer to mergeFiles function)
4. Prepares the Target dataset (refer to prepareTargetDataset function)
5. Groups Target dataset by subject / activity, and calculate mean for all observations
6. Write the tidy dataset to a text file