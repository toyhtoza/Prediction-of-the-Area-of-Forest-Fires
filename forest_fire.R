forestfire.train=read.csv("/Users/toyhtoza/Desktop/train-2.csv",stringsAsFactors = FALSE)
forestfire.test=read.csv("/Users/toyhtoza/Desktop/test.csv",stringsAsFactors = FALSE)
hist(forestfire.train$area,breaks=20,xlab="original area",ylab="Frequency")
hist(log(forestfire.train$area+1),breaks=20,xlab="log(area+1)",ylab="Frequency")

#forestfire.train
burnedarea = forestfire.train[forestfire.train$area>0,]
burnedarea
numBAjan=length(which(burnedarea$month=="jan"))
numBAfeb=length(which(burnedarea$month=="feb"))
numBAmar=length(which(burnedarea$month=="mar"))
numBAapr=length(which(burnedarea$month=="apr"))
numBAmay=length(which(burnedarea$month=="may"))
numBAjun=length(which(burnedarea$month=="jun"))
numBAjul=length(which(burnedarea$month=="jul"))
numBAoct=length(which(burnedarea$month=="oct"))
numBAnov=length(which(burnedarea$month=="nov"))
numBAsep=length(which(burnedarea$month=="sep"))
numBAdec=length(which(burnedarea$month=="dec"))
numBAaug=length(which(burnedarea$month=="aug"))
monthareafreq=data.frame(month=c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"),freq=c(numBAjan,numBAfeb,numBAmar,numBAapr,numBAmay,numBAjun,numBAjul,numBAaug,numBAsep,numBAoct,numBAnov,numBAdec))
monthareafreq
library(ggplot2)
ggplot(monthareafreq,aes(x=reorder(month,freq),y=freq))+geom_bar(stat="identity")
numBAmon=length(which(burnedarea$day=="mon"))
numBAtue=length(which(burnedarea$day=="tue"))
numBAwed=length(which(burnedarea$day=="wed"))
numBAthu=length(which(burnedarea$day=="thu"))
numBAfri=length(which(burnedarea$day=="fri"))
numBAsat=length(which(burnedarea$day=="sat"))
numBAsun=length(which(burnedarea$day=="sun"))
dayareafreq = data.frame(day=c("mon","tue","wed","thu","fri","sat","sun"),freq=c(numBAmon,numBAtue,numBAwed,numBAthu,numBAfri,numBAsat,numBAsun))
ggplot(dayareafreq,aes(x=reorder(day,freq),y=freq))+geom_bar(stat="identity")
forestfire.traincopy<-forestfire.train
forestfire.train$area<-log(forestfire.train$area+1)
attach(forestfire.train)
names(forestfire.train)
lm.forestfire=lm(area~X+Y+month+day+FFMC+DMC+DC+ISI+temp+RH+wind+rain,forestfire.train)
summary(lm.forestfire)
lm.rain1=lm(area~rain,data=forestfire.train)
lm.rain2=lm(area~rain+I(rain^2),data=forestfire.train)
anova(lm.rain1,lm.rain2)
lm.tempfit=lm(area~poly(temp,5))
summary(lm.tempfit)

names(forestfire.train)
dim(forestfire.train)

#best subset selection
#install.packages("leaps")
library(leaps)
regfit.forestfire=regsubsets(area~.,forestfire.train,nvmax=20)
summary(regfit.forestfire)
reg.summary=summary(regfit.forestfire)
which.max(reg.summary$adjr2)
plot(reg.summary$adjr2,xlab="Number of Variables",ylab="Adjusted RSq",type="l")
points(8,reg.summary$adjr2[8],col="red",cex=2,pch=20)
which.min(reg.summary$rss)
plot(reg.summary$rss,xlab="Number of Variables",ylab="RSS",type="l")
points(20,reg.summary$rss[20],col="red",cex=2,pch=20)
which.min(reg.summary$cp)
plot(reg.summary$cp,xlab="Number of Variables",ylab="CP",type="l")
points(4,reg.summary$cp[4],col="red",cex=2,pch=20)
which.min(reg.summary$bic)
plot(reg.summary$bic,xlab="Number of Variables",ylab="BIC",type="l")
points(2,reg.summary$bic[2],col="red",cex=2,pch=20)
coef(regfit.forestfire,8)
coef(regfit.forestfire,20)
coef(regfit.forestfire,4)
coef(regfit.forestfire,2)
#forward backward selection
regfit.fwd=regsubsets(area~.,forestfire.train,nvmax=12,method="forward")
regfit.bwd=regsubsets(area~.,forestfire.train,nvmax=12,method="backward")
summary(regfit.fwd)
coef(regfit.fwd,8)
coef(regfit.bwd,8)

#CV
set.seed(1)
train=sample(c(TRUE,FALSE),nrow(forestfire.train),rep=TRUE)
test=(!train)
regfit.best=regsubsets(area~.,data=forestfire.train[train,],nvmax=20)
test.mat=model.matrix(area~.,data=forestfire.train[test,])
val.errors=rep(NA,20)
for(i in 1:20){
  coefi=coef(regfit.best,id=i)
  pred=test.mat[,names(coefi)]%*%coefi
  val.errors[i]=mean((forestfire.train$area[test]-pred)^2)
}
val.errors
which.min(val.errors)
coef(regfit.best,8)

#lasso
x=model.matrix(area~.,forestfire.train)[,-1]
y=forestfire.train$area
library(glmnet)
grid=10^seq(10,-2,length=100)
set.seed(2)
train=sample(1:nrow(x),nrow(x)/2)
test=(-train)
y.test=y[test]
lasso.mod=glmnet(x[train,],y[train],alpha=1,lambda=grid)
set.seed(2)
cv.out=cv.glmnet(x[train,],y[train],alpha=1)
bestlam=cv.out$lambda.min
out=glmnet(x,y,alpha=1,lambda=grid)
lasso.coef=predict(out,type="coefficients",s=bestlam)[1:28,]
lasso.coef
lasso.coef[lasso.coef!=0]

#ridge
x=model.matrix(area~.,forestfire.train)[,-1]
y=forestfire.train$area
library(glmnet)
grid=10^seq(10,-2,length=100)
set.seed(2)
train=sample(1:nrow(x),nrow(x)/2)
test=(-train)
y.test=y[test]
ridge.mod=glmnet(x[train,],y[train],alpha=0,lambda=grid)
set.seed(2)
cv.out=cv.glmnet(x[train,],y[train],alpha=0)
bestlam=cv.out$lambda.min
out=glmnet(x,y,alpha=0,lambda=grid)
ridge.coef=predict(out,type="coefficients",s=bestlam)[1:28,]
ridge.coef

# test and trial

library(ISLR)
set.seed(3)
traincv=sample(367,300)

lm.fit1=lm(area~X+month+day+FFMC+ISI+temp+wind,data=forestfire.train,subset=traincv)

lm.fit2=lm(area~X+month+day+DC+temp+RH,data=forestfire.train,subset=traincv)

lm.fit1.pred=predict(lm.fit1,forestfire.train)
lm.fit2.pred=predict(lm.fit2,newdata=forestfire.train)
mean(abs(lm.fit1.pred-forestfire.train$area)[-traincv])
mean(abs(lm.fit2.pred-forestfire.train$area)[-traincv])

lm.fit3=lm(area~X+Y+month+day+(FFMC+DMC+DC+ISI+temp+RH+wind+rain)^2,data=forestfire.train)
summary(lm.fit3)

lm.fit4=lm(area~X+Y+month+day+FFMC+DMC+DC+ISI+temp+RH+wind+rain+DMC:DC+I(temp^2),data=forestfire.train)
lm.fit4.pred=predict(lm.fit4,newdata=forestfire.train)
mean(abs(lm.fit4.pred-forestfire.train$area)[-traincv])
mean(abs(lm.fit4.pred-log(forestfire.test$area+1)))

lm.fit5=lm(area~X+month+day+DC+temp+wind+I(temp^2),data=forestfire.train)
lm.fit5.pred=predict(lm.fit5,newdata=forestfire.test)
mean(abs(lm.fit5.pred-forestfire.test$area))


lm.fit6=lm(area~X+month+day+DC+temp+wind+I(temp^2),data=forestfire.train)
lm.fit6.pred=predict(lm.fit6,newdata=forestfire.train)
mean(abs(lm.fit6.pred-forestfire.train$area))

#encoding the month and day
day.list=c("mon","tue","wed","thu","fri","sat","sun")
month.list=c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec")

mon.list=rep(0,367)
day.lis=rep(0,367)
for(i in 1:367){
  for(j in 1:7){
    if(as.character(forestfire.train$day[i])==day.list[j]){day.lis[i]=sin(2*pi*j/7)
    }
  }  
  for(k in 1:12){
    if(as.character(forestfire.train$month[i])==month.list[k]){mon.list[i]=sin(2*pi*k/12)
    }
  }
}  
forestfire.train$day<-as.numeric(day.lis)
forestfire.train$month<-as.numeric(mon.list)

mon.test.list=rep(0,150)
day.test.list=rep(0,150)
for(i in 1:150){
  for(j in 1:7){
    if(as.character(forestfire.test$day[i])==day.list[j]){day.test.list[i]=sin(2*pi*j/7)
    }
  }  
  for(k in 1:12){
    if(as.character(forestfire.test$month[i])==month.list[k]){mon.test.list[i]=sin(2*pi*k/12)
    }
  }
}  
forestfire.test$day<-as.numeric(day.test.list)
forestfire.test$month<-as.numeric(mon.test.list)




#multiple regression with all variables
#MR.fit=lm(area~.,data=train.fire)
#summary(MR.fit)
#MR.pred=predict(MR.fit,newdata=test.fire)
#list=rep(0,150)
#MR.mad<-mean(abs((exp(MR.pred)-1)-test.fire$area))
#sum((exp(MR.pred)-1-test.fire$area)^2)

#Decision Tree method with all variables
library(tree)
library(ISLR)
#library(rpart)
set.seed(8)
DT.tree=tree(area~.,data=forestfire.train)
summary(DT.tree)
plot(DT.tree)
text(DT.tree,cex=0.5)
cv.DT=cv.tree(DT.tree)
#cv.DT
#prune.tree=prune.tree(DT.tree,best=1)
tree.pred=predict(DT.tree,newdata=forestfire.test)
#prune.pred=predict(prune.tree,newdata=test.fire)
DT.mad<-mean(abs(exp(tree.pred)-1-forestfire.test$area))
#mean(abs(exp(prune.pred)-1-test.fire$area))


#random forest
library(randomForest)
rF.tree=randomForest(area~.,data=forestfire.train)
rF.tree
rF.pred=predict(rF.tree,newdata=forestfire.test)
rF.mad<-mean(abs(exp(rF.pred)-1-forestfire.test$area))
rF.mad
#sum((exp(rF.pred)-1-test.fire$area)^2)

#netural network
library(nnet)
for(i in 1:12){
  forestfire.train[i]<-scale(forestfire.train[i])
  forestfire.test[i]<-scale(forestfire.test[i])
}
mad.list=rep(0,10)
min.list=rep(0,10)
#create train data and test data for cv within the train.fire data
for(k in 1:10){
  rowIndices <- 1 : nrow(forestfire.train)
  sampleSize <- 0.9*length(rowIndices)
  trainingRows <- sample (rowIndices, sampleSize)
  trainingData <- forestfire.train[trainingRows, ]
  testData <- forestfire.train[-trainingRows, ] 
  # use cv to choose the number of hidden nodes
  for(i in 1:10){
    nn<-nnet(area~.,trainingData,size=i,decay=0.001,maxit=1000,linout=F,trace=F)
    nn.pred=predict(nn,newdata=testData)
    mad.list[i]=mean(abs(exp(nn.pred)-exp(testData$area)))
  }
  min.list[k]<-which.min(mad.list)
}
min.list
#fit nn model, run 10 times and take the mean mad as final result 
for(i in 1:20){
  nn<-nnet(area~.,forestfire.train,size=4,decay=0.001,maxit=1000,linout=F,trace=F)
  nn.pred=predict(nn,newdata=forestfire.test)
  #print(which(nn.pred==0))
  mad.list[i]=mean(abs(exp(nn.pred)-1-forestfire.test$area))
}
nn.mad<-mean(mad.list)
nn.mad
#sum((exp(nn.pred)-1-test.fire$area)^2)

#supprot vector regression
library(e1071)
#use tune.svm() to choose the best choices of the features
tuned <- tune.svm(area~., data =forestfire.train, gamma = 10^(-3:3), cost = 10^(-3:3))
summary (tuned)
svr.fit <- svm (area~., data=forestfire.train,kernel = "radial",cost =10, gamma=100, scale = FALSE)
svr.pred<-predict(svr.fit,newdata=forestfire.test)
svr.mad<-mean(abs(exp(svr.pred)-1-forestfire.test$area))
#which(svr.pred==0)

#gather the results to make comparison
accuracy.data<-data.frame(DT.mad,rF.mad,nn.mad,svr.mad)
accuracy.data