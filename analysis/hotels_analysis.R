# Load the dataset
hotels <- read.table("/Users/dianaanko/Downloads/hotele.txt")

# Create a time series object from the data: monthly data starting from January 2009
hotels.ts = ts(hotels, start = c(2009, 1), frequency = 12)
hotels.ts

# Plot the time series
plot(hotels.ts)

# Monthly seasonal plot (shows average for each month)
monthplot(hotels.ts)

# Install and load the 'forecast' package
install.packages('forecast')
library(forecast)

# Seasonal plot: data by year, with colors
seasonplot(hotels.ts, year.labels = TRUE,
           year.labels.left = TRUE, col = rainbow(6))

# Lag plot to check autocorrelations (especially seasonality)
lag.plot(hotels.ts, lags = 12, do.lines = FALSE, pch = 20)

# Show autocorrelation function (ACF) for the time series
acf(hotels.ts)
acf(hotels.ts, lag.max = 120)

# Partial autocorrelation function (PACF)
Pacf(hotels.ts, lag.max = 120)

# Detect and clean outliers
tsoutliers(hotels.ts)
tsclean(hotels.ts)


# Adjusting for unequal month lengths
hotels.correction = hotels.ts * (365.21 / 12) / monthdays(hotels.ts)
ts.plot(hotels.ts, tsclean(hotels.correction),
        col = c('blue', 'red'), lty = c(1, 2))

# Aggregating monthly data to quarterly
hotels.aggregation.sum = aggregate(hotels.ts, nfrequency = 4, FUN = sum)
ts.plot(hotels.aggregation.sum)

# Average monthly visitors in each quarter
hotels.aggregation.mean = aggregate(hotels.ts, nfrequency = 4, FUN = mean)
ts.plot(hotels.aggregation.mean)

# Disaggregation using the 'tempdisagg' package
library(tempdisagg)

# Disaggregation with sum
model.disaggregation.sum = td(hotels.aggregation.sum ~ 1, to = 'monthly', conversion = 'sum')
hotels.disaggregation.sum = predict(model.disaggregation.sum)

# Disaggregation with mean
model.disaggregation.mean = td(hotels.aggregation.mean ~ 1, to = 'monthly', conversion = 'mean')
hotels.disaggregation.mean = predict(model.disaggregation.mean)

# Compare original vs disaggregated data
ts.plot(hotels.ts, hotels.disaggregation.sum, hotels.disaggregation.mean,
        col = c('blue', 'green', 'red'), lty = c(1, 2, 3))
legend('bottomright', c('Original', 'Sum Disaggregated', 'Mean Disaggregated'),
       col = c('blue', 'green', 'red'), lty = c(1, 2, 3))

# Forecasting model using TSLM (Trend + Seasonality)
library(forecast)
hotels <- read.table('/Users/dianaanko/Downloads/hotele.txt')
hotels.ts = ts(hotels, start = c(2009, 1), frequency = 12)
hotels.ts = tsclean(hotels.ts)

# Train-test split
hotels.ts.train = window(hotels.ts, end = c(2012, 12))
hotels.ts.test = window(hotels.ts, start = c(2013, 1))

# First-order seasonal differencing
hotels.ts.train.diff12 = diff(hotels.ts.train, lag = 12)
ts.plot(hotels.ts.train.diff12)
lag.plot(hotels.ts.train.diff12, lags = 12, do.lines = FALSE, pch = 20)
Pacf(hotels.ts.train.diff12, lag.max = 120)

# Second-order differencing
hotels.ts.train.diff12.diff = diff(hotels.ts.train.diff12)
ts.plot(hotels.ts.train.diff12.diff)
lag.plot(hotels.ts.train.diff12.diff, lags = 12, do.lines = FALSE, pch = 20)
Acf(hotels.ts.train.diff12.diff, lag.max = 120)
Pacf(hotels.ts.train.diff12.diff, lag.max = 120)

# Train TSLM model
hotels.tslm = tslm(hotels.ts.train ~ trend + season)
str(hotels.tslm)

# Residuals of TSLM
hotels.tslm.residuals = hotels.tslm$residuals
ts.plot(hotels.tslm.residuals)

# Compare residuals
ts.plot(hotels.ts.train.diff12.diff, hotels.tslm.residuals,
        col = c('red', 'blue'))
Acf(hotels.tslm.residuals, lag.max = 200) # Suggests MA(13)
Pacf(hotels.tslm.residuals, lag.max = 200) # Suggests AR(8)

lag.plot(hotels.tslm.residuals, lags = 12, do.lines = FALSE, pch = 20)

# Forecast using TSLM
hotels.tslm.forecast = forecast(hotels.tslm, h = 15)
plot(hotels.tslm.forecast)
ts.plot(hotels.ts.test, hotels.tslm.forecast$mean, col = c('red', 'blue'))

# Fit MA(13) model to TSLM residuals
hotels.tslm.MA13 = Arima(hotels.tslm.residuals, order = c(0, 0, 13), seasonal = c(0, 0, 0), include.mean = FALSE)
summary(hotels.tslm.MA13)

# Forecast with MA(13)
hotels.tslm.MA13.forecast = forecast(hotels.tslm.MA13, h = 15)
# Combine TSLM + MA(13)
combined.MA13 = hotels.tslm.forecast$mean + hotels.tslm.MA13.forecast$mean

# Compare forecasts
ts.plot(hotels.ts.test, hotels.tslm.forecast$mean, combined.MA13,
        col = c('red', 'blue', 'green'))

# Fit AR(8) to residuals
hotels.tslm.AR8 = Arima(hotels.tslm.residuals, order = c(8, 0, 0), seasonal = c(0, 0, 0), include.mean = FALSE)
summary(hotels.tslm.AR8)

# Forecast with AR(8)
hotels.tslm.AR8.forecast = forecast(hotels.tslm.AR8, h = 15)
combined.AR8 = hotels.tslm.forecast$mean + hotels.tslm.AR8.forecast$mean

# Compare all forecasts
ts.plot(hotels.ts.test,
        hotels.tslm.forecast$mean,
        combined.MA13,
        combined.AR8,
        col = c('red', 'blue', 'green', 'purple'))

# Automatically choose the best ARIMA model for the residuals
hotels.tsml.auto = auto.arima(hotels.tslm.residuals)
