#Import Data
library(rethinking)
data(NWOGrants)

#Application acceptance.
model1 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- a,
  a ~ dnorm(0,10)
)
output1 <- map(model1, data = NWOGrants)
samples1 <- extract.samples(output1)

#Plot the average chance of acceptance.
p.total <- logistic(samples1$a)*100
quantile(p.total, c(0.025, 0.5, 0.975))

#Considering the gender.
NWOGrants$gender_id <- coerce_index( NWOGrants$gender ) 
model2 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- a[gender_id],
  a[gender_id] ~ dnorm(0,10)
)
output2 <- map(model2, data = NWOGrants)
samples2 <- extract.samples(output2)

#Quantiles Male and Female Applicants
p.female <- logistic(samples2$a[,1])*100
p.male <- logistic(samples2$a[,2])*100

quantile(p.female, c(0.025, 0.5, 0.975))
quantile(p.male, c(0.025, 0.5, 0.975))
quantile(p.male - p.female, c(0.025, 0.5, 0.975))

#Compare Model1 and Model2
compare(output1,output2)

#Application Chance across Departments.
NWOGrants$department_id <- coerce_index( NWOGrants$discipline ) 
model3 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- b[department_id],
  b[department_id] ~ dnorm(0,10)
)
output3 <- map(model3, data = NWOGrants)
samples3 <- extract.samples(output3)

n_departments = max(NWOGrants$department_id)
department_list <- levels(NWOGrants$discipline)
p_mean <- vector("numeric",n_departments)

png('01_Departments.png', height = 600, width=1200)
plot(0,0, xlab="Discipline", ylab="Admission Rate [%]", xlim=c(1,n_departments), ylim=c(0,50),xaxt="n",main="Admission Rate for the Different Disciplines")
lines(c(0,n_departments+1),c(mean(p.total),mean(p.total)),lty=2)
axis(1,at=1:n_departments,labels=department_list)
for(i in 1:n_departments)
{
  p <- logistic(samples3$b[,i])*100
  quantiles <- unname(quantile(p, c(0.025, 0.5, 0.975)))
  points(i,quantiles[2], ylab = "Chance of Acceptance [%]")
  arrows(i, quantiles[1], i, quantiles[3], length=0.05, angle=90, code=3)
}
dev.off()

#Application Chance across Departments and Gender.
model4 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- a[gender_id] + b[department_id],
  a[gender_id] ~ dnorm(0,10),
  b[department_id] ~ dnorm(0,10)
)
output4 <- map(model4, data = NWOGrants)
samples4 <- extract.samples(output4)

gender_list <- levels(NWOGrants$gender)
color_list <- c("red","blue")
n_data <- length(samples4$a[,1])

png('02_Departments_with_Gender.png', height = 600, width=1200)
plot(0,0, xlab="Discipline", ylab="Admission Rate [%]", xlim=c(1,n_departments), ylim=c(0,50),xaxt="n",main="Admission Rate for the Different Disciplines Divided by Gender")
lines(c(0,n_departments+1),c(mean(p.female),mean(p.female)),lty=2,col="red")
lines(c(0,n_departments+1),c(mean(p.male),mean(p.male)),lty=2,col="blue")
axis(1,at=1:n_departments,labels=department_list)
for(i in 1:n_departments)
{
  print(department_list[i])
  p <- matrix(1:2*n_data, nrow = 2, ncol = n_data)
  for(j in 1:2)
  {
    p[j,] <- logistic(samples4$a[,j] + samples4$b[,i])*100
    quantiles <- unname(quantile(p[j,], c(0.025, 0.5, 0.975)))
    k = ifelse(j==1,i-0.075,i+0.075)
    points(k,quantiles[2])
    arrows(k, quantiles[1], k, quantiles[3], length=0.05, angle=90, code=3, col=color_list[j])
  }
  #print(quantile(p[2,]-p[1,], c(0.025, 0.5, 0.975)))
}
dev.off()

png('03_Departments_Gender_Difference.png', height = 600, width=1200)
plot(0,0, xlab="Discipline", ylab="Difference Admission Rate [%]", xlim=c(1,n_departments), ylim=c(-5,+10),xaxt="n",main="Difference of Admission Rate between Genders for each Discipline")
lines(c(0,n_departments+1),c(0,0),lty=2)
axis(1,at=1:n_departments,labels=department_list)
for(i in 1:n_departments)
{
  print(department_list[i])
  p <- matrix(1:2*n_data, nrow = 2, ncol = n_data)
  for(j in 1:2)
  {
    p[j,] <- logistic(samples4$a[,j] + samples4$b[,i])*100
  }
  quantiles <- unname(quantile(p[2,]-p[1,], c(0.025, 0.5, 0.975)))
  points(i,quantiles[2])
  arrows(i, quantiles[1], i, quantiles[3], length=0.05, angle=90, code=3)
}
dev.off()

#Compare all Models
compare(output1,output2,output3,output4)