# Importing the dataset
dataset <- read.csv("breast-cancer-wisconsin.csv",header = F)
# dataset_backup <- dataset
dataset<-dataset[,-1]

# creating a new dataset to rearrange the columns
dataset <-data.frame(dataset$V2,dataset$V3,dataset$V4,dataset$V5,
                         dataset$V6,dataset$V7,dataset$V8,dataset$V9,
                         dataset$V10,dataset$V11)
colnames(dataset)<-c("Clump_Thickness","CellSizeUniformity","CellShapeUniformity","Marginal_Adhesion",
                     "Single_Epithelial_Cell_Size","Bare_Nuclei","Bland_Chromatin","Normal_Nucleoli","Mitoses","Result")
dataset$bias <- array(1,dim = c(nrow(dataset),1))
dataset <-data.frame(dataset$bias,dataset$Clump_Thickness,dataset$CellSizeUniformity,dataset$CellShapeUniformity,
                     dataset$Marginal_Adhesion,dataset$Single_Epithelial_Cell_Size,dataset$Bare_Nuclei,dataset$Bland_Chromatin,
                     dataset$Normal_Nucleoli,dataset$Mitoses,dataset$Result)
colnames(dataset)<-c("Bias","Clump_Thickness","CellSizeUniformity","CellShapeUniformity","Marginal_Adhesion",
                            "Single_Epithelial_Cell_Size","Bare_Nuclei","Bland_Chromatin","Normal_Nucleoli","Mitoses","Result")


dataset$Result <- ifelse(dataset$Result==2,0,1)
row_to_keep<-(dataset$Bare_Nuclei!='?')
dataset <-dataset[row_to_keep,]
# converting one factor column into numeric
dataset$Bare_Nuclei <- as.numeric(as.character(dataset$Bare_Nuclei))

# checking the dataset for factors and anomalies before splitting
# summary(dataset_new)

# Splitting the dataset into the Training set and Test set
# install.packages('caTools')
# feature scaling
mean1 <-c(mean(dataset$Clump_Thickness),mean(dataset$CellSizeUniformity),mean(dataset$CellShapeUniformity),
          mean(dataset$Marginal_Adhesion),mean(dataset$Single_Epithelial_Cell_Size),mean(dataset$Bare_Nuclei),
          mean(dataset$Bland_Chromatin),mean(dataset$Normal_Nucleoli),mean(dataset$Mitoses))
sd1 <- c(sd(dataset$Clump_Thickness),sd(dataset$CellSizeUniformity),sd(dataset$CellShapeUniformity),
         sd(dataset$Marginal_Adhesion),sd(dataset$Single_Epithelial_Cell_Size),sd(dataset$Bare_Nuclei),
         sd(dataset$Bland_Chromatin),sd(dataset$Normal_Nucleoli),sd(dataset$Mitoses))

dataset[,c(-1,-11)] <- scale(dataset[, c(-1,-11)])
install.packages("caTools")
library(caTools)
set.seed(123)
split <- sample.split(dataset$Result, SplitRatio = .8)
training_set <- subset(dataset, split == TRUE) #TEMP
test_set <- subset(dataset, split == FALSE)

# removing the variables not needed anymore
rm(row_to_keep)
rm(split)
# rm(dataset_backup)
# done with pre_processing

# ALGORITHM BEGINS
# step1: calculate cost(h(x),y) = -log(h(x)) if y=1 or -log(1-h(x)) if y=0
#         this function is taken to make the curve convex
# step2: J(Theta)=1/m * summation(cost) for all rows
# step3: minimize J(Theta)
# once we get theta values,the classifier is ready

# we are creating a new function for log as log(0)=infinity and such a value cannot be handled as numeric
theLog <- function(x){
  if(x==0)  return(-100)
  else  return (log(x))
}

# initialize variables
Yvec <- training_set$Result
cost <- 0
jThetaPrev <- 100000
jTheta <- 100
difference <- 10
nrts <- nrow(training_set)
Hvec <-vector(mode= "double" ,length = nrts)
# thetaVector has to be a multidimensional vector
# each layer has a 2D vector for theta and there are multiple layer(2-3 in our case)
# so there are be a 3D vector to store the coefficents for the ANN 
# creating a 3d vector
thetaVector <- list()
thetaVector[[1]] <- array(1,dim = c(6,10))
thetaVector[[2]] <- matrix(1,nrow = 4,ncol = 7)
thetaVector[[3]] <- matrix(1,nrow = 1,ncol = 5)
thetaVector[[1]][1,] <- c(1,2,0.5,1,3,-2,3,-3,1,0.1)
thetaVector[[1]][2,] <- c(1,2.5,1.5,1,1,3,3,-4,2,0.3)
thetaVector[[1]][3,] <- c(2,1.5,2.5,1.1,1.3,3,4,-5,1,0.3)
thetaVector[[1]][4,] <- c(3,0.3,3,1,-2,-3,2,-3,4,0.4)
thetaVector[[1]][5,] <- c(2,0.1,2,3,-3,-4,1,-2,3,0.2)
thetaVector[[1]][6,] <- c(-2,1,4,0.1,-0.2,-1.1,1,0.2,2,-2)
# thetaVector[[1]][7,] <- c(-2,1,0.3,2.1,-4,-3,2,3,1,0,3)
# thetaVector[[1]][8,] <- c(-2,1,3,1.1,-2,-2,-1,0.2,-1,2,1)
# thetaVector[[1]][9,] <- c(1,-2,3,-2.1,2,-3,-1,1.2,1,4,-2)
# thetaVector[[1]][10,] <- c(1,-4,3,-2.1,1,4,1,1,1,4,-1)
# thetaVector[[2]] <- thetaVector[[1]]
thetaVector[[2]][1,] <- c(1,2,0.5,1,3,-2,3)
thetaVector[[2]][2,] <- c(1,2.5,1.5,1,1,3,3)
thetaVector[[2]][3,] <- c(2,1.5,2.5,1.1,1.3,3,4)
thetaVector[[2]][4,] <- c(3,0.3,3,1,-2,-3,2)
# thetaVector[[2]][5,] <- c(2,0.1,2,3,-3,-4,1,-2,3)
# thetaVector[[2]][6,] <- c(-2,1,4,0.1,-0.2,-1.1,1,0.2,2)

Delta <- list()
Delta[[1]] <- array(0,dim = c(6,10))
Delta[[2]] <- matrix(0,nrow = 4,ncol = 7)
Delta[[3]] <- matrix(0,nrow = 1,ncol = 5)

# to store actual values of computation
nodes1 <- matrix(2,nrow = 10,ncol = 1)
nodes2 <- matrix(2,nrow = 7,ncol = 1)
nodes3 <- matrix(2,nrow = 5,ncol = 1)
delta1 <- matrix(1,nrow = 10,ncol = 1)
delta2 <- matrix(1,nrow = 7,ncol = 1)
delta3 <- matrix(1,nrow = 5,ncol = 1)

# this while loop helps us to generate the coefficients for the classifier equation
# it take approximately --- minutes to run
# has to be run only once because the training set is static(constant) after which the thetaVector can store the value of coefficients
while(difference >= 0.0000000001) {
  cost <- 0
  jThetaPrev <- jTheta
  
  for (i in 1:nrts){
    # Forward Propogation
    # computing the linear sum of weights * node value and applying sigmoid to the computed value
    nodes1 <-as.numeric(training_set[i,c(-10)])                   # input layer i.e layer1
    nodes2 <- c(1,as.numeric(thetaVector[[1]] %*% nodes1))     # hidden layer1 i.e layer2
    nodes2[-1] <- 1/(1+exp(-nodes2[-1]))
    nodes3 <- c(1,as.numeric(thetaVector[[2]] %*% nodes2))     # hidden layer2 i.e layer3
    nodes3[-1] <- 1/(1+exp(-nodes3[-1]))
    h <- sum(as.numeric(thetaVector[[3]] * nodes3))               # output layer i.e layer4
    h <- 1/(1+exp(-h))
    # testing of forward chaining working well(I think so)
    # temp1 <- thetaVector[[2]][7,]    # sum(temp1 * nodes[,2])    # 1/(1+exp(0.4276424))
    Hvec[i] <- h
    cost <- as.numeric(cost - as.numeric(Yvec[i])*theLog(h) - (1-as.numeric(Yvec[i]))*theLog(1-h)) 
    
    # Backward Propogation
    delta_last <- h-Yvec[i]
    # delta(l) = transpose(theta)*delta(l+1) .* g_prime(z(l)) ;where g_prime() is derivative of activation fn
    # g_prime comes out as g_prime(z(l)) = a(l) .* (1-a(l))
    delta3 <- t(thetaVector[[3]])*delta_last * (nodes3*(1-nodes3))
    delta2 <- t(thetaVector[[2]]) %*% delta3[-1] * (nodes2*(1-nodes2))
    # delta[,1] is unused ,as there is no error in the 1st ie input layer;it is simply present for numbering purposes
    Delta[[3]] <- Delta[[3]] + (delta_last*t(nodes3))
    Delta[[2]] <- Delta[[2]] + (delta3[-1] %*% t(nodes2))
    Delta[[1]] <- Delta[[1]] + (delta2[-1] %*% t(nodes1))
  }
  jTheta <- cost / nrts
  
  Delta[[3]] <- Delta[[3]]/nrts
  Delta[[2]] <- Delta[[2]]/nrts
  Delta[[1]] <- Delta[[1]]/nrts
  
  thetaVector[[3]] <- thetaVector[[3]] - Delta[[3]]
  thetaVector[[2]] <- thetaVector[[2]] - Delta[[2]]
  thetaVector[[1]] <- thetaVector[[1]] - Delta[[1]]
  difference <- jThetaPrev - jTheta 
  print(paste (jTheta,difference, sep = " "))
}

# converting the hypothesis into yes or no inorder to check how well the equation fits the training set
Hvec <- ifelse(Hvec >= 0.5 , 1 , 0 )      
# first confusion matrix for our algorithm
confMatrix = table(Yvec, Hvec)
confMatrix

# initializing the test prediction vector
nrts1 <- nrow(test_set)
Y_pred <-vector(mode= "double" ,length = nrts1)
# test set calculations
for (i in 1:nrts1){
  # Forward Propogation
  # computing the linear sum of weights * node value and applying sigmoid to the computed value
  nodes1 <-as.numeric(test_set[i,c(-10)])                   # input layer i.e layer1
  nodes2 <- c(1,as.numeric(thetaVector[[1]] %*% nodes1))     # hidden layer1 i.e layer2
  nodes2[-1] <- 1/(1+exp(-nodes2[-1]))
  nodes3 <- c(1,as.numeric(thetaVector[[2]] %*% nodes2))     # hidden layer2 i.e layer3
  nodes3[-1] <- 1/(1+exp(-nodes3[-1]))
  h <- sum(as.numeric(thetaVector[[3]] * nodes3))               # output layer i.e layer4
  h <- 1/(1+exp(-h))
  # testing of forward chaining working well(I think so)
  # temp1 <- thetaVector[[2]][7,]    # sum(temp1 * nodes[,2])    # 1/(1+exp(0.4276424))
  Y_pred[i] <- h
}

# actual Y values
Yvec1 <- test_set$Result
# converting the hypothesis into yes or no inorder to check how well the equation fits the test set
Y_pred <- ifelse(Y_pred >= 0.5 , 1 , 0 )      
# first confusion matrix for our algorithm
confMatrix1 = table(Yvec1, Y_pred)
confMatrix1

# clearing the unwanted variables to free memory
rm(cost);rm(difference)
rm(delta1);rm(delta2);rm(delta3);rm(delta_last);rm(Delta)
rm(nodes1);rm(nodes2);rm(nodes3);
rm(jTheta);rm(jThetaPrev);rm(i);rm(theLog);rm(nrts);rm(h)
rm(confMatrix);rm(confMatrix1);rm(nrts1);

# actual theta values
# thetaVector[[1]][1,] <- c( 1.104005, 2.5523746,0.9047006, 1.42413996, 2.4755557,-1.8248911, 2.79408412,-2.2906619,1.730777, 2.0116644)
# thetaVector[[1]][2,] <- c(-1.887264, 1.6219369,1.3541722, 0.90427456,-0.5276422, 0.1816634, 2.84357813,-3.0997675,1.567506, 5.1308040)
# thetaVector[[1]][3,] <- c( 2.121525, 1.6305754,2.5044159, 1.12112808, 0.8859523, 2.6767029, 4.43541271,-4.5870019,1.227317, 1.4229437)
# thetaVector[[1]][4,] <- c( 3.893172,-0.2479299,2.4520286, 0.04235929,-1.4742965,-2.6965036, 1.30559744,-4.0597143,3.543919,-0.7210873)
# thetaVector[[1]][5,] <- c( 4.796235,-0.3630921,1.1684880, 0.58081275,-1.3430119,-3.0025778,-0.28847446,-2.4752768,1.744279,-3.3246693)
# thetaVector[[1]][6,] <- c(-2.811819, 0.2817386,2.1600171,-0.30675106,-1.1344440,-2.1408464,-0.09744665,-0.8184009,1.626729, 4.1073703)
# 
# thetaVector[[2]][1,] <- c(-1.2526016,1.583954,0.4788097, 0.1372948, 1.387663,-3.709899,3.345946)
# thetaVector[[2]][2,] <- c( 1.4041289,2.532685,1.6078010, 1.1971912, 1.082807, 3.103837,3.000301)
# thetaVector[[2]][3,] <- c( 2.1706602,1.521154,2.5289740, 1.1774346, 1.332713, 3.043386,4.000851)
# thetaVector[[2]][4,] <- c(-0.9287337,1.296901,5.1079285,-1.1602423,-2.466328,-3.701066,4.342088)
# 
# thetaVector[[3]][1,] <- c(-2.938249,3.851918,-2.559276,-2.800843,12.76194)
