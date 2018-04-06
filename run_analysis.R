wd <- paste0(getwd(), "/", "peer_w4")
if (!dir.exists(wd)){
    dir.create(wd)
}

setwd(wd)

f = tempfile()
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", f, method = "curl")

unzip(f, overwrite = T, junkpaths =T)

#####################################################################################
library(data.table)
library(dplyr)

# Get data as data.table
features <- fread("features.txt", stringsAsFactors = F)

X_train <- fread("X_train.txt")
X_test <- fread("X_test.txt")
Y_train <- fread("Y_train.txt")
Y_test <- fread("Y_test.txt")
subject_train <- fread("subject_train.txt")
subject_test <- fread("subject_test.txt")

activities <- fread("activity_labels.txt", stringsAsFactors = T)

# Join train and test data sets
X <- rbind(X_train, X_test)
Y <- rbind(Y_train, Y_test)
subject <- rbind(subject_train, subject_test)

# cleanup for memory sake
rm(X_test)
rm (X_train)
rm (Y_test)
rm (Y_train)
rm (subject_test)
rm(subject_train)


# Give meaningful labels to data
names_without_colon <- make.names(names = as.vector(unlist(features[,2])), unique = T)
names_without_colon <- sapply(names_without_colon, function(x) gsub('(\\.){2,3}', '.', x)) # remove ugly doubles and triple dots
setnames(X, old = names(X), new = names_without_colon)

# add subjects and activity IDs
X[, subject.id := subject$V1]
X[, activity.id := Y$V1]
# add activity label
X$activity = activities[X$activity.id,]$V2



# extract desired columns
means_and_std <- select(X, subject.id, activity.id, activity, contains('.mean.'), contains('.std.'))

# rearrange our data set to have IDs first
id_columns <- c("subject.id", "activity.id", "activity")
measure_columns <- names(select(means_and_std, -subject.id, -activity.id, -activity ))
ordered_names <- c(id_columns, measure_columns)
setcolorder(means_and_std, ordered_names)

melted <- melt(means_and_std, id.vars = id_columns, measure.vars = measure_columns)

tidy_data <- dcast(melted, subject.id + activity ~ variable, mean)


## Save Data
submission_file <- paste(getwd(),"tidy_data_submission.txt", sep="/", collapse = "" )
if (file.exists(submission_file)){
    file.remove(submission_file)
}

write.table(tidy_data, file = submission_file, row.names = FALSE )
