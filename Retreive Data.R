wd <- paste0(getwd(), "/", "peer_w4")
if (!dir.exists(wd)){
    dir.create(wd)
}

setwd(wd)

f = tempfile()
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", f, method = "curl")

unzip(f, overwrite = T, junkpaths =T)