# can access github utilities?
connected <- TRUE

# give this run a unique name
thisRun <- "1"

# stat learning project set up
source("utilityCode.R")
source("tuneGrids.R")

# configure the data frame here
# refer out to any custom code, to do the basics
# such as making appropriate factors, ditching obviously useless columns

library(ISLR)
Auto1 <- Auto[, -9]
Auto1$origin <- factor(Auto1$origin)
dt <- setData(Auto1, "mpg")

# problem type, either classification or regression, can be over-ridden
ptype <- dt$ptype

# use the EDA file to explore the data
# pick appropriate funcs from the various checks file
# check for NA vals
na.vals.check(dt)
# and near zero variance
nzv.check(dt) 

# do anything you can to the wholesale data set before partitioning
# such as removing entire columns
# creating dummy variables out of factors if required
dt$dt.frm <- createDummies(dt$dt.frm, dt$resp)
# always reset the object after a change
dt <- setData(dt$dt.frm, "mpg")

# check for highly correlated predictors
cor.vars.check(dt, 0.8)
# and remove them
cor.vars.check(dt, 0.8, rmv = TRUE)
# always reset the object after a change
dt <- setData(dt$dt.frm, "mpg")

# partition the data here for modeling and validation
trn.val.tst <- myStandardPartitioning(dt)

# choose your statistical learning method
algorithms <- c("lm", "foba")

# set up the train controls for each model
# to customise for any model, over-write the default
for (algo in algorithms) {
  assign(paste0(algo, ".tc")
         , trainControl(method = "cv"
                        , number = 10
                        , returnData = TRUE
                        , returnResamp = "all"
                        , allowParallel = TRUE))
}

# set up any tuning grids in custom

# list your transforms or just "asis" for the as is training set
# and remember to build any transformed sets with custom code
# to avoid building unecesary duplicates
sets <- c("asis", "pca")

# all pre-processing here. use the boiler plate funcs and add any custom code here
# add further data sets to the trn.val.tst object

# define models, transforms and custom code here
# for example
myPreProc <- preProcess(trn.val.tst$trn.asis[-dt$respCol]
                        , method = "pca"
                        , thresh = 0.8)

# the new data frame must be named as a set in the model config
trn.val.tst$trn.pca <- predict(myPreProc, trn.val.tst$trn.asis)
trn.val.tst$val.pca <- predict(myPreProc, trn.val.tst$val.asis)
trn.val.tst$tst.pca <- predict(myPreProc, trn.val.tst$tst.asis)

# set up the models matrix to control the remaining workflow
models <- createModelMatrix(algorithms, sets)

# create the models
createModels(trn.val.tst, dt$resp, models, seed = 121)

trnPreds <- generatePredictions(trn.val.tst, models, "trn.set")
valPreds <- generatePredictions(trn.val.tst, models, "val.set")
tstPreds <- generatePredictions(trn.val.tst, models, "tst.set")

# look at the buildTime v error rate stats
modelStats <- compareModelStats(models, ptype)
# for regression problems, also look at the MAD
if (ptype == "regression") {
  modelStats <- MADmodelStats(models, modelStats, "trn.set", trn.val.tst, dt$resp, trnPreds)
}
compareModelStatsPlot(modelStats, ptype)

# for classification problems, build a confusion matrix index from the built models
if (ptype == "classification") {
  confmats <- createConfMats(valPreds, "val.set", trn.val.tst, dt$resp, models)
  myConfMatsPlot(confmats)
}