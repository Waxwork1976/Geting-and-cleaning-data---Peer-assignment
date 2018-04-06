---
title: "README"
author: "C. Bissegger"
date: "1 April 2018"
output: html_document
---

## Peer review assignment - Getting and Cleaning Data


In this assignement, we had to summarize data about cell phones measures, obtained from University of California, Irvine, which can be downloaded here: <https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip>. Details about original data can be found here:
<http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones>.

### Context
In this assignement, we had to perform following tasks:

1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement. 
3. Uses descriptive activity names to name the activities in the data set
4. Appropriately labels the data set with descriptive variable names. 
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

I haven't found mention of the units of the data, but as it it about accelerations it probably is **m/s^2^**.

The following libraries where used to perform the analysis:
```{r}
library(data.table)
library(dplyr)
```

### Getting data
Data was obtain in a dedicated folder, whitch will be our working directory for this session.
```{r}
wd <- paste0(getwd(), "/", "peer_w4")
if (!dir.exists(wd)){
    dir.create(wd)
}

setwd(wd)

f = tempfile()
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", f, method = "curl")

unzip(f, overwrite = T, junkpaths =T)
```

### Merging data sets
Choice was made to merge test and train different data set by type, to ease the naming of features.Each file had originally it's own container. 
```{r}
features <- fread("features.txt", stringsAsFactors = F)

X_train <- fread("X_train.txt")
X_test <- fread("X_test.txt")
Y_train <- fread("Y_train.txt")
Y_test <- fread("Y_test.txt")
subject_train <- fread("subject_train.txt")
subject_test <- fread("subject_test.txt")

activities <- fread("activity_labels.txt", stringsAsFactors = T)

X <- rbind(X_train, X_test)
Y <- rbind(Y_train, Y_test)
subject <- rbind(subject_train, subject_test)
```

A few cleaning of not-used-anymore variables is then done.

### Setting feature names
Features names have been taken from the *features.txt* file. There were invalid characters when using raw values, so I converted them to syntactically valid values using the **make.name** function, making sure the result is unique. Then I removed the ugly double and triple dots to have a more readable result.
```{r}
names_without_colon <- make.names(names = as.vector(unlist(features[,2])), unique = T)
names_without_colon <- sapply(names_without_colon, function(x) gsub('(\\.){2,3}', '.', x)) # remove ugly doubles and triple dots
setnames(X, old = names(X), new = names_without_colon)
```

Even if it has been said that variable names should not contain dots or underscores, I kept using dots to have measured value (i.e. *BodyGyro*, *BodyAcc*) separated from the kind of value taken (*mean* or *std*).


### Complete dataset
Then I complete the dataset with subject, activity id (from Y dataset) and activity label (from activities dataset).
```{r}
# add subjects and activity IDs
X[, subject.id := subject$V1]
X[, activity.id := Y$V1]
# add activity label
X$activity = activities[X$activity.id,]$V2
```

### Interresting feature extraction
Required features extraction and data set reorganization (to have ID's as first cloumn) is then performed. Retreival of measure columns could probably be smarter, but it works...
```{r}
means_and_std <- select(X, subject.id, activity.id, activity, contains('.mean.'), contains('.std.'))

# rearrange our data set to have IDs first
id_columns <- c("subject.id", "activity.id", "activity")
measure_columns <- names(select(means_and_std, -subject.id, -activity.id, -activity ))
ordered_names <- c(id_columns, measure_columns)
setcolorder(means_and_std, ordered_names)
```

### Melting and Tidying
Then, I melt the data to have a single observation per row and made a resulting data frame containing the mean of each *variable* (the measure) for each *subject* and *activity*.
```{r}
melted <- melt(means_and_std, id.vars = id_columns, measure.vars = measure_columns)

tidy_data <- dcast(melted, subject.id + activity ~ variable, mean)
```

and finally, persist the result on disk, to submit it to your judgement!
```{r}
submission_file <- paste(getwd(),"tidy_data_submission.csv", sep="/", collapse = "" )
if (file.exists(submission_file)){
    file.remove(submission_file)
}
    
write.csv(tidy_data, file = submission_file)
```

