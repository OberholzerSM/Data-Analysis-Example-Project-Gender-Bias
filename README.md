# Data Analysis Example Project: Gender Bias

## Introduction

<p align="justify"> 
In 2015, the Netherlands Organization for Scientific Research (NWO) published a study according to which there is a gender bias when it comes to the admission rate for applications for research funding. Our goal is to look at the data provided in table S1. and investigate whether this data is sufficient in showing a statistically significant difference between the admission rate for female and male applicants. To generate samples for our statistical models, we will be using the <i>rethinking</i> package available in RStudio.

The study alongside the data can be found here: https://doi.org/10.1073/pnas.151015911 (03.02.2026)
</p>

## Model 1: Overall admission rate

<p align="justify"> 

To begin, we will construct a statistical model that ignores the gender and only focuses on the admission rate. Later, we will be able to compare this model to one where the gender is accounted for. Since an application can either be accepted or rejected, we assume that our data follows a binomial distribution,


```R
awards ~ dbinom(applications,p)
```

where $p$ represents the admission rate. To generate possible values for $p$, we need a function that only accepts values between $0$ and $1$ while also allowing us to tie it to our data. For those purposes, we will use the $logit$ function and for now assign it a constant value $a$,

```R
logit(p) <- a
```

The $logit$ function is defined as
```math
logit(p) = ln\left[ \frac{p}{1+p} \right]
```

The value for $a$ can be sampled from a normal distribution with a sufficiently large standard deviation.

```R
a ~ dnorm(0,10)
```

Overall, we define our first model as

```R
model1 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- a,
  a ~ dnorm(0,10)
)
```

Afterwards, we can use the $map$ function to generate samples for our parameters.
```R
output1 <- map(model1, data = NWOGrants)
samples1 <- extract.samples(output1)
```

The samples of the parameter $a$ are at first not particularly useful. To transform them into samples for $p$, we use the inverse of the $logit$ function named $logistic$.
```R
p.total <- logistic(samples1$a)*100
```

To make an estimate for the overall admission rate, we use quantiles that contain 95% of our data.
```R
quantile(p.total, c(0.025, 0.5, 0.975))
```

| Value          |  2.5% | 50.0% | 97.5% |
| -------------  | ------|------ | ------|
| p.total        | 15.2% | 16.6% | 18.0% | 

According to our first model, the overall admission rate lies between $15.2$% and $18.0$%, with a median of $16.6$%. In the next segment, we can look at the admission rates split across genders and see how they differ.

<b>
Note:
</b>

If <i>map2stan</i> is available to use, then one can further improve the model by using a multilevel approach to estimate the parameter.

```R
a ~ dnorm(mu,sigma),
mu ~ dnorm(0,1),
sigma ~ dcauchy(0,2)
```
 
</p>

## Model 2: admission rate for the Different Genders

<p align="justify"> 

We will now update the model to differentiate between the admission rates of the two provided genders.

```R
NWOGrants$gender_id <- coerce_index( NWOGrants$gender ) 
model2 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- a[gender_id],
  a[gender_id] ~ dnorm(0,10)
)
output2 <- map(model2, data = NWOGrants)
```

To see whether our new model is a better fit for the data, or in other words if the difference between the genders is significant, we can compute the so-called WAIC score. The WAIC score is a measure of how well a model fits a given dataset, while crucially also punishing
models that overfit the data with too many parameters. The lower the WAIC, the better of a fit a model is. In our case, we obtain the following WAIC's:

| Model  | WAIC  | weight |
| -------|-------|--------|
|output2 | 129.7 |  0.57  |
|output1 | 130.3 |  0.43  |

The second model indeed has a lower WAIC than the first, although not by a huge margin. To better see if the gender difference is statistically significant, we can look at the quantiles of the two acceptance ratios as well as the difference between them.

| Value             |  2.5% | 50.0% | 97.5% |
| ------------------|-------|------ |-------|
| p.female          | 13.0% | 14.9% | 17.0% | 
| p.male            | 15.9% | 17.7% | 19.6% | 
| p.male - p.female | 0.05% | 2.79% | 5.54% | 

For women, the application rate is estimated to be around $\sim 15$%, while for men it is almost $\sim 18$%. The 95% interval for the difference between the two lies between $0.05$% and $5.54$%, thus indeed showing a statistically significant difference.

</p>

## Model 3: admission rate Across Departments

While it seems that we have already proven our thesis in the previous section, we have not accounted for the full dataset yet, which also provides us with the number of approved applications for each University discipline. It is possible that only some but not all faculties show a gender bias in the application approval process, making it worth to investigate matters further.

As before, we begin with a simple model where we ignore the gender at first and focus on the individual disciplines. We follow a similar approach to section 2 and compute the WAIC.

```R
NWOGrants$department_id <- coerce_index( NWOGrants$discipline ) 
model3 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- b[department_id],
  b[department_id] ~ dnorm(0,10)
)
output3 <- map(model3, data = NWOGrants)
```

| Model  | WAIC  | weight |
| -------|-------|--------|
|output3 | 127.5 |  0.63  |
|output2 | 129.7 |  0.24  |
|output1 | 130.3 |  0.13  |

Our new model does indeed lower the WAIC, signifying that the difference in admission rates between disciplines is significant enough that we need to take it into account. The admission rates for the different disciplines alongside their $95$% interval are shown in Fig. 1. As can be seen, three disciplines indeed show a significant difference from the average admission rate, while two more disciplines are on the edge.

<figure>
  <p align="center">
  <img src="/Images/01_Departments.png" width="600" height="1200"/>
  </p>
  <figcaption>
    <p align="center">
    Fig. 1: admission rate for the different disciplines. The dashed line represents the mean across disciplines.
    </p>
  </figcaption>
</figure>

## Model 4: admission rate Across Departments and Genders

For the final model, we take both the gender and the discipline into account and compute the WAIC.

```R
model4 <- alist(
  awards ~ dbinom(applications,p),
  logit(p) <- a[gender_id] + b[department_id],
  a[gender_id] ~ dnorm(0,10),
  b[department_id] ~ dnorm(0,10)
)
output4 <- map(model4, data = NWOGrants)
```

| Model  | WAIC  | weight |
| -------|-------|--------|
|output3 | 127.5 |  0.43  |
|output4 | 129.2 |  0.26  |
|output2 | 129.7 |  0.17  |
|output1 | 130.3 |  0.15  |

We obtain that our new model <i>increases<\i> the WAIC, suggesting that the difference between genders is no longer statistically significant! This seems to contradict our result from section 2-

To better see what might be going on, we can look at Fig. 2 showing the different admission rates for the disciplines split across the genders. What is notable are the very large error bars, being as large as $20$% for the Physics department! This can be explained by the very few data points provided within each discipline. In the case of the Physics department, there were only $9$ female applicants, out of which only $2$ were accepted!

These large uncertainties then also bleed over to the difference between the admission rate of the genders, showcased in Fig. 3. The error bars are now large enough to still cover the possibility of the difference being $0$%, meaning we can no longer confidently claim there to be a gender bias within any of the disciplines.

It is however notable that for every discipline the admission rate is consistently higher for men than for women, including the medical sciences which have had more women apply than men. As such, the possibility of a gender bias is still very much worth investigating, though more data needs to be collected within each discipline to definitely prove its presence.

<figure>
  <p align="center">
  <img src="/Images/02_Departments_with_Gender.png" width="900" height="1800"/>
  </p>
  <figcaption>
    <p align="center">
    Fig. 2: Admission rate for the different disciplines. The dashed lines represents the mean across disciplines.
    Red: Female Applicants. Blue: Male Applicants.
    </p>
  </figcaption>
</figure>


<figure>
  <p align="center">
  <img src="/Images/03_Departments_Gender_Difference.png" width="900" height="1800"/>
  </p>
  <figcaption>
    <p align="center">
    Fig. 3: Admission rate for the different disciplines. The dashed line represents a difference of zero.
    </p>
  </figcaption>
</figure>

## Conclusion

-When taken across all disciplines, the admission rate for men is statistically higher than for women.

-However, the admission rate varies significantly across disciplines. As such, each discipline needs to be evaluated individually.

-Although the admission rate for men is higher than for women within each discipline, there is unfortunately not enough data within the disciplines to prove or disprove a gender bias.

-> More data needs to be collected.
