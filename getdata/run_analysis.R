library(data.table)
library(dplyr)
library(plyr)

inputPath = file.path('.', 'in')
outputPath = file.path('.', 'out')

prepareDirs <- function() {
  if (!file.exists(inputPath)) {
    dir.create(inputPath)
  }
  if (!file.exists(outputPath)) {
    dir.create(outputPath) 
  }
}

downloadFiles <- function() {
  file <- 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
  destFile <- file.path(inputPath, 'dataset.zip')
  download.file(file, destfile=destFile, method='curl')
  unzip(destFile, exdir=inputPath)
}

mergeFile <- function(file1, file2, outputFileName) {
  cat(file1, file2)
  f1 <- fread(file1, sep="\n", header=FALSE)
  f2 <- fread(file2, sep="\n", header=FALSE)   
  f3 <- rbindlist(list(f1, f2))
  write.table(f3, file = outputFileName, row.names=FALSE, col.names=FALSE, quote=FALSE)
}

mergeFiles <- function(trainDir, testDir, outDir) {
  trainFiles <- list.files(trainDir)
  for (file in trainFiles) {
    testFile <- file.path(testDir, gsub("_train", "_test", file))
    trainFile <- file.path(trainDir, file)
    outFile <- file.path(outDir, gsub("_train", "", file))

    message('merging ', trainFile, ' and ', testFile, ' to ', outFile, "\n")
    
    tryCatch({
      mergeFile(trainFile, testFile, outFile)  
    }, error = function(cond) {
      message(cond) 
    })
    
  }
}

loadData <- function(path, file) {
  file <- file.path(path, file)
  data <- read.table(file, sep = "" , header = F, na.strings ="", stringsAsFactors= F) 
  data
}

prepareTargetDataset <- function() {
  
  # Load Features File
  features <- loadData(inputPath, 'UCI HAR Dataset/features.txt')
  
  # Filter only mean or std features
  meanStdFeatures <- features[grep('mean[()]|std[()]',features$V2),]
  
  # Get the measurement names
  meanStdNames <- meanStdFeatures$V2

  # Load Activity Labels
  activities <- loadData(inputPath, 'UCI HAR Dataset/activity_labels.txt')
  
  # Load Labels
  labels <- loadData(outputPath, 'y.txt')
  
  # Load Dataset
  data <- loadData(outputPath, 'X.txt')
  
  # rename columns to match the measurements
  names <- features$V2
  colnames(data) <- names
  
  # Load Subjects
  subjects <- loadData(outputPath, 'subject.txt')
  
  # Preparing Final data frame
  
  # Include only mean or std columns
  targetdf <- data[, meanStdNames]

  # Column bind labels and data
  targetdf <- cbind(labels, targetdf)
  
  # Join with activities to get their description
  targetdf <- join(activities, targetdf)
  
  # rename V2 to Activity
  targetdf <- rename(targetdf, c("V2" = "Activity"))
  
  # drop V1 column
  targetdf <- select(targetdf, -V1)
  
  # Column bind subjects and data
  targetdf <- cbind(subjects, targetdf)
  
  # rename V1 to Subject
  targetdf <- rename(targetdf, c("V1" = "Subject"))
  
  targetdf
}

# Step 1: Prepare Directories
prepareDirs()

# Step 2: Download Files
downloadFiles()

# Step 3: Merge Train / Test datasets
mergeFiles(file.path(inputPath, 'UCI HAR Dataset/train'), file.path(inputPath, 'UCI HAR Dataset/test'), outputPath)

# Step 4: Prepare target dataset
dataset <- prepareTargetDataset()

# Step 5: group dataset by Subject & Activity, and calculate mean of observations
groups <- dataset %>% group_by(Subject, Activity) 
meanDatset <- groups %>% summarise_each(funs(mean(., na.rm=T)))

# Step 6: Write the final tidy dataset
write.table(meanDatset, file.path(outputPath, 'tidy.txt'), sep=" ", row.names = F, quote=F)