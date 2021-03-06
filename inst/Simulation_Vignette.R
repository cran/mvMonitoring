## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
# # To build the documentation PDF, use
# # Mac
# system("R CMD Rd2pdf /Users/gabrielodom/Documents/GitHub/mvMonitoring")
# # PC - still hella buggy
# system("R CMD Rd2pdf C:\Users\gabriel_odom\Documents\GitHub\mvMonitoring\mvMonitoring")

## ----t_vec_initialized---------------------------------------------------
omega <- 60 * 24 * 7
phi <- 0.75
a <- 0.01; b <- 2
mean_t_err <- 0.5 * (a + b) # mean of Uniform(0.01,2)
var_t_err <- (b - a) / 12 # variance of Uniform(0.01,2)

# Create an autocorrelated vector of errors for the random variable t
t_err <- vector(length = omega)
# Initialise the errors so that the overall mean and variance match the sim of
# Kazor et al.
t_err[1] <- rnorm(n = 1,
                  mean = mean_t_err * (1 - phi),
                  sd = sqrt(var_t_err * (1 - phi ^ 2)))
for(s in 2:omega){
  t_err[s] <- phi * t_err[(s - 1)] +
    (1 - phi) * rnorm(n = 1,
                      mean = mean_t_err * (1 - phi),
                      sd = sqrt(var_t_err * (1 - phi ^ 2)))
}

# Now for the vector itself
t_star <- vector(length = omega)
t_star[1] <- -cos(2 * pi / omega) + t_err[1]
for(s in 2:omega){
  t_star[s] <- -cos(2 * pi * s / omega) +
    phi * t_err[(s - 1)] + (1 - phi) * t_err[s]
}
# Now we scale the ts to match the ts from the Unif(0.01,2)
t_star_adj <- ((b - a) * (t_star - min(t_star))) /
  (max(t_star) - min(t_star)) + a

## ----t_vec_graphs, echo = FALSE------------------------------------------
plot(t_star_adj,
     type = "l",
     main = "Plot of t Scaled to [0.1,2]",
     xlab = "t")
pacf(t_star,
     main = "Partial ACF for the Series t")

## ----t_vec_summary-------------------------------------------------------
mean(t_star); var(t_star)
cor(t_star_adj[2:omega], t_star_adj[1:(omega - 1)])
lmtest::dwtest(t_star_adj[2:omega] ~ t_star_adj[1:(omega - 1)])

## ----state_1_init--------------------------------------------------------
library(scatterplot3d)
library(magrittr)
library(dplyr)

normal_df <- data.frame(t = t_star_adj,
                        err1 = rnorm(n = omega, sd = sqrt(0.01)),
                        err2 = rnorm(n = omega, sd = sqrt(0.01)),
                        err3 = rnorm(n = omega, sd = sqrt(0.01)))

###  State 1  ###
normal_df %<>% mutate(x = t + err1,
                     y = t ^ 2 - 3 * t + err2,
                     z = -t ^ 3 + 3 * t ^ 2 + err3)

# plot(normal_df$t)
# plot(normal_df$x)
# plot(normal_df$y)
# plot(normal_df$z)
# # It checks out

orig_state_mat <- normal_df %>% select(x,y,z) %>% as.matrix

## ----state1_scatter------------------------------------------------------
scatterplot3d(x = normal_df$x,
              y = normal_df$y,
              z = normal_df$x)

## ----state_2_init--------------------------------------------------------
# source("C:/Users/gabriel_odom/Documents/GitHub/mvMonitoring/mvMonitoring/inst/Rotation_Playground.R")
# source("Users\gabrielodom\Documents\GitHub\mvMonitoring\mvMonitoring\inst\Rotation_Playground.R")

###  State 2  ###
state2_angles <- list(yaw = 0,
                      pitch = 90,
                      roll = 30)
state2_scales <- c(1,0.5,2)
state2_mat <- orig_state_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                               scale_factors = state2_scales)

## ----state_2_scatter-----------------------------------------------------
scatterplot3d(state2_mat)

## ----state_3_init--------------------------------------------------------
###  State 3  ###
state3_angles <- list(yaw = 90,
                      pitch = 0,
                      roll = -30)
state3_scales <- c(0.25,0.1,0.75)
state3_mat <- orig_state_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                               scale_factors = state3_scales)

## ----state_3_scatter-----------------------------------------------------
scatterplot3d(state3_mat)

## ----combine_state_data--------------------------------------------------
###  Combination and Cleaning  ###
# Now concatenate these vectors
normal_df$xState2 <- state2_mat[,1]
normal_df$yState2 <- state2_mat[,2]
normal_df$zState2 <- state2_mat[,3]
normal_df$xState3 <- state3_mat[,1]
normal_df$yState3 <- state3_mat[,2]
normal_df$zState3 <- state3_mat[,3]

# Add a State label column
normal_df %<>%
  mutate(state = rep(rep(c(1, 2, 3), each = 60), (24 / 3) * 7))

# Add a date-time column
normal_df %<>%
  mutate(dateTime = seq.POSIXt(from = as.POSIXct("2016-11-27 00:00:00 CST"),
                               by = "min", length.out = 10080))

###  Hourly Switching Process  ###
state1_df <- normal_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
state2_df <- normal_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
state3_df <- normal_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
normal_switch_df <- bind_rows(state1_df, state2_df, state3_df) %>%
  arrange(dateTime)

## ----state_scatterplots--------------------------------------------------

normal_switch_df %>%
  filter(state == 1) %>%
  select(x, y, z) %>%
  scatterplot3d(xlim = c(-2, 3),
                ylim = c(-3, 1),
                zlim = c(-1, 5))

normal_switch_df %>%
  filter(state == 2) %>%
  select(x, y, z) %>%
  scatterplot3d(xlim = c(-2, 3),
                ylim = c(-3, 1),
                zlim = c(-1, 5))

normal_switch_df %>%
  filter(state == 3) %>%
  select(x, y, z) %>%
  scatterplot3d(xlim = c(-2, 3),
                ylim = c(-3, 1),
                zlim = c(-1, 5))

normal_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d(xlim = c(-2, 3),
                ylim = c(-3, 1),
                zlim = c(-1, 5))

## ----fault1A_intro-------------------------------------------------------
faultStart <- 8500

###  Fault 1A  ###
# Shift each <x, y, z> by 2
shift <- 2
fault1A_df <- normal_df %>%
  select(dateTime, state, t, x, y, z) %>%
  mutate(x = x + shift,
         y = y + shift,
         z = z + shift)
fault1A_mat <- fault1A_df %>% select(x,y,z) %>% as.matrix

# State 2
fault1A_S2_mat <- fault1A_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                                  scale_factors = state2_scales)
scatterplot3d(fault1A_S2_mat)

# State 3
fault1A_S3_mat <- fault1A_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                                  scale_factors = state3_scales)
scatterplot3d(fault1A_S3_mat)

# Now concatenate these vectors
fault1A_df$xState2 <- fault1A_S2_mat[,1]
fault1A_df$yState2 <- fault1A_S2_mat[,2]
fault1A_df$zState2 <- fault1A_S2_mat[,3]
fault1A_df$xState3 <- fault1A_S3_mat[,1]
fault1A_df$yState3 <- fault1A_S3_mat[,2]
fault1A_df$zState3 <- fault1A_S3_mat[,3]

# Hourly switching process
fault1A_state1_df <- fault1A_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
fault1A_state2_df <- fault1A_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
fault1A_state3_df <- fault1A_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
fault1A_switch_df <- bind_rows(fault1A_state1_df,
                               fault1A_state2_df,
                               fault1A_state3_df) %>%
  arrange(dateTime)

## ----fault1A_scatter-----------------------------------------------------
fault1A_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d()

## ----fault1B_intro-------------------------------------------------------
###  Fault 1B  ###
# Shift each x by 2
fault1B_df <- normal_df %>%
  select(dateTime, state, t, x, y, z) %>%
  mutate(x = x + shift)
fault1B_mat <- fault1B_df %>% select(x,y,z) %>% as.matrix

# State 2
fault1B_S2_mat <- fault1B_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                                  scale_factors = state2_scales)
scatterplot3d(fault1B_S2_mat)

# State 3
fault1B_S3_mat <- fault1B_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                                  scale_factors = state3_scales)
scatterplot3d(fault1B_S3_mat)

# Now concatenate these vectors
fault1B_df$xState2 <- fault1B_S2_mat[,1]
fault1B_df$yState2 <- fault1B_S2_mat[,2]
fault1B_df$zState2 <- fault1B_S2_mat[,3]
fault1B_df$xState3 <- fault1B_S3_mat[,1]
fault1B_df$yState3 <- fault1B_S3_mat[,2]
fault1B_df$zState3 <- fault1B_S3_mat[,3]

# Hourly switching process
fault1B_state1_df <- fault1B_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
fault1B_state2_df <- fault1B_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
fault1B_state3_df <- fault1B_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
fault1B_switch_df <- bind_rows(fault1B_state1_df,
                               fault1B_state2_df,
                               fault1B_state3_df) %>%
  arrange(dateTime)

## ----fault1B_scatter-----------------------------------------------------
fault1B_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d()

## ----fault2A_intro-------------------------------------------------------
###  Fault 2A  ###
# Drift each <x, y, z> by (step - faultStart) / 10 ^ 3
drift_vec <- (1:omega - faultStart) / 10 ^ 3
drift_vec[drift_vec < 0] <- 0
fault2A_df <- normal_df %>%
  select(dateTime, state, t, x, y, z) %>%
  mutate(x = x + drift_vec,
         y = y + drift_vec,
         z = z + drift_vec)
fault2A_mat <- fault2A_df %>% select(x,y,z) %>% as.matrix

# State 2
fault2A_S2_mat <- fault2A_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                                  scale_factors = state2_scales)
# scatterplot3d(fault2A_S2_mat)

# State 3
fault2A_S3_mat <- fault2A_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                                  scale_factors = state3_scales)
# scatterplot3d(fault2A_S3_mat)

# Now concatenate these vectors
fault2A_df$xState2 <- fault2A_S2_mat[,1]
fault2A_df$yState2 <- fault2A_S2_mat[,2]
fault2A_df$zState2 <- fault2A_S2_mat[,3]
fault2A_df$xState3 <- fault2A_S3_mat[,1]
fault2A_df$yState3 <- fault2A_S3_mat[,2]
fault2A_df$zState3 <- fault2A_S3_mat[,3]

# Hourly switching process
fault2A_state1_df <- fault2A_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
fault2A_state2_df <- fault2A_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
fault2A_state3_df <- fault2A_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
fault2A_switch_df <- bind_rows(fault2A_state1_df,
                               fault2A_state2_df,
                               fault2A_state3_df) %>%
  arrange(dateTime)

## ----fault2A_scatter-----------------------------------------------------
fault2A_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d()

## ----fault2B_intro-------------------------------------------------------
###  Fault 2B  ###
# Drift each <y, z> by (step - faultStart) / 10 ^ 3
fault2B_df <- normal_df %>%
  select(dateTime, state, t, x, y, z) %>%
  mutate(y = y + drift_vec,
         z = z + drift_vec)
fault2B_mat <- fault2B_df %>% select(x,y,z) %>% as.matrix

# State 2
fault2B_S2_mat <- fault2B_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                                  scale_factors = state2_scales)
scatterplot3d(fault2B_S2_mat)

# State 3
fault2B_S3_mat <- fault2B_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                                  scale_factors = state3_scales)
scatterplot3d(fault2B_S3_mat)

# Now concatenate these vectors
fault2B_df$xState2 <- fault2B_S2_mat[,1]
fault2B_df$yState2 <- fault2B_S2_mat[,2]
fault2B_df$zState2 <- fault2B_S2_mat[,3]
fault2B_df$xState3 <- fault2B_S3_mat[,1]
fault2B_df$yState3 <- fault2B_S3_mat[,2]
fault2B_df$zState3 <- fault2B_S3_mat[,3]

# Hourly switching process
fault2B_state1_df <- fault2B_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
fault2B_state2_df <- fault2B_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
fault2B_state3_df <- fault2B_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
fault2B_switch_df <- bind_rows(fault2B_state1_df,
                               fault2B_state2_df,
                               fault2B_state3_df) %>%
  arrange(dateTime)

## ----fault2B_scatter-----------------------------------------------------
fault2B_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d()

## ----fault3A_intro-------------------------------------------------------
###  Fault 3A  ###
# Amplify t for each <x, y, z> by 3 * (omega - step) * t / (2 * omega)
amplify_vec <- 2 * (1:omega - faultStart) / (omega - faultStart) + 1
amplify_vec[amplify_vec < 1] <- 1
fault3A_df <- normal_df %>%
  select(dateTime, state, t, err1, err2, err3) %>%
  mutate(t = amplify_vec * t) %>%
  mutate(x = t + err1,
         y = t ^ 2 - 3 * t + err2,
         z = -t ^ 3 + 3 * t ^ 2 + err3)
fault3A_mat <- fault3A_df %>% select(x,y,z) %>% as.matrix

# State 2
fault3A_S2_mat <- fault3A_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                                  scale_factors = state2_scales)
scatterplot3d(fault3A_S2_mat)

# State 3
fault3A_S3_mat <- fault3A_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                                  scale_factors = state3_scales)
scatterplot3d(fault3A_S3_mat)

# Now concatenate these vectors
fault3A_df$xState2 <- fault3A_S2_mat[,1]
fault3A_df$yState2 <- fault3A_S2_mat[,2]
fault3A_df$zState2 <- fault3A_S2_mat[,3]
fault3A_df$xState3 <- fault3A_S3_mat[,1]
fault3A_df$yState3 <- fault3A_S3_mat[,2]
fault3A_df$zState3 <- fault3A_S3_mat[,3]

# Hourly switching process
fault3A_state1_df <- fault3A_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
fault3A_state2_df <- fault3A_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
fault3A_state3_df <- fault3A_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
fault3A_switch_df <- bind_rows(fault3A_state1_df,
                               fault3A_state2_df,
                               fault3A_state3_df) %>%
  arrange(dateTime)

## ----fault3A_scatter-----------------------------------------------------
fault3A_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d()

## ----fault3B_intro-------------------------------------------------------
###  Fault 3B  ###
# Dampen t for z by log|t|
t_log <- normal_df$t
t_log[faultStart:omega] <- log(t_log[faultStart:omega])
fault3B_df <- normal_df %>%
  select(dateTime, state, t, err1, err2, err3) %>%
  mutate(t_damp = t_log) %>%
  mutate(x = t + err1,
         y = t ^ 2 - 3 * t + err2,
         z = -t_damp ^ 3 + 3 * t_damp ^ 2 + err3)
fault3B_mat <- fault3B_df %>% select(x,y,z) %>% as.matrix

# State 2
fault3B_S2_mat <- fault3B_mat %*% mvMonitoring::rotateScale3D(rot_angles = state2_angles,
                                                  scale_factors = state2_scales)
# scatterplot3d(fault3B_S2_mat)

# State 3
fault3B_S3_mat <- fault3B_mat %*% mvMonitoring::rotateScale3D(rot_angles = state3_angles,
                                                  scale_factors = state3_scales)
# scatterplot3d(fault3B_S3_mat)

# Now concatenate these vectors
fault3B_df$xState2 <- fault3B_S2_mat[,1]
fault3B_df$yState2 <- fault3B_S2_mat[,2]
fault3B_df$zState2 <- fault3B_S2_mat[,3]
fault3B_df$xState3 <- fault3B_S3_mat[,1]
fault3B_df$yState3 <- fault3B_S3_mat[,2]
fault3B_df$zState3 <- fault3B_S3_mat[,3]

# Hourly switching process
fault3B_state1_df <- fault3B_df %>%
  filter(state == 1) %>%
  select(dateTime, state, x, y, z)
fault3B_state2_df <- fault3B_df %>%
  filter(state == 2) %>%
  select(dateTime, state, x = xState2, y = yState2, z = zState2)
fault3B_state3_df <- fault3B_df %>%
  filter(state == 3) %>%
  select(dateTime, state, x = xState3, y = yState3, z = zState3)
fault3B_switch_df <- bind_rows(fault3B_state1_df,
                               fault3B_state2_df,
                               fault3B_state3_df) %>%
  arrange(dateTime)

## ----fault3B_scatter-----------------------------------------------------
fault3B_switch_df %>%
  select(x, y, z) %>%
  scatterplot3d()

## ----fault_dataframes----------------------------------------------------
library(xts)
normal_switch_xts <- xts(normal_switch_df[,-1],
                         order.by = normal_switch_df[,1])

# Fault 1A
normal_w_fault1A_df <- bind_rows(normal_switch_df[1:(faultStart - 1),],
                              fault1A_switch_df[faultStart:omega,])
fault1A_xts <- xts(normal_w_fault1A_df[,-1], order.by = normal_switch_df[,1])

# Fault 1B
normal_w_fault1B_df <- bind_rows(normal_switch_df[1:(faultStart - 1),],
                                 fault1B_switch_df[faultStart:omega,])
fault1B_xts <- xts(normal_w_fault1B_df[,-1], order.by = normal_switch_df[,1])

# Fault 2A
normal_w_fault2A_df <- bind_rows(normal_switch_df[1:(faultStart - 1),],
                                 fault2A_switch_df[faultStart:omega,])
fault2A_xts <- xts(normal_w_fault2A_df[,-1], order.by = normal_switch_df[,1])

# Fault 2B
normal_w_fault2B_df <- bind_rows(normal_switch_df[1:(faultStart - 1),],
                                 fault2B_switch_df[faultStart:omega,])
fault2B_xts <- xts(normal_w_fault2B_df[,-1], order.by = normal_switch_df[,1])

# Fault 3A
normal_w_fault3A_df <- bind_rows(normal_switch_df[1:(faultStart - 1),],
                                 fault3A_switch_df[faultStart:omega,])
fault3A_xts <- xts(normal_w_fault3A_df[,-1], order.by = normal_switch_df[,1])

# Fault 3B
normal_w_fault3B_df <- bind_rows(normal_switch_df[1:(faultStart - 1),],
                                 fault3B_switch_df[faultStart:omega,])
fault3B_xts <- xts(normal_w_fault3B_df[,-1], order.by = normal_switch_df[,1])

faults_ls <- list(normal = normal_switch_xts,
                  fault1A = fault1A_xts,
                  fault1B = fault1B_xts,
                  fault2A = fault2A_xts,
                  fault2B = fault2B_xts,
                  fault3A = fault3A_xts,
                  fault3B = fault3B_xts)

## ----feature_ts_plots----------------------------------------------------
# Double check that faults are visible and according to plan:
# faults_ls$fault1A %>% select(x) %>% plot.ts()
# faults_ls$fault1A %>% select(y) %>% plot.ts()
# faults_ls$fault1A %>% select(z) %>% plot.ts()
# faults_ls$fault1B %>% select(x) %>% plot.ts()
# faults_ls$fault1B %>% select(y) %>% plot.ts()
# faults_ls$fault1B %>% select(z) %>% plot.ts()
# faults_ls$fault2A %>% select(x) %>% plot.ts()
# faults_ls$fault2A %>% select(y) %>% plot.ts()
# faults_ls$fault2A %>% select(z) %>% plot.ts()
# faults_ls$fault2B %>% select(x) %>% plot.ts()
# faults_ls$fault2B %>% select(y) %>% plot.ts()
# faults_ls$fault2B %>% select(z) %>% plot.ts()
# faults_ls$fault3A %>% select(x) %>% plot.ts()
# faults_ls$fault3A %>% select(y) %>% plot.ts()
# faults_ls$fault3A %>% select(z) %>% plot.ts()
# faults_ls$fault3B %>% select(x) %>% plot.ts()
# faults_ls$fault3B %>% select(y) %>% plot.ts()
# faults_ls$fault3B %>% select(z) %>% plot.ts()
faults_ls$fault1A$x %>% plot.xts()
faults_ls$fault1A$y %>% plot.xts()
faults_ls$fault1A$z %>% plot.xts()
faults_ls$fault1B$x %>% plot.xts()
faults_ls$fault1B$y %>% plot.xts()
faults_ls$fault1B$z %>% plot.xts()
faults_ls$fault2A$x %>% plot.xts()
faults_ls$fault2A$y %>% plot.xts()
faults_ls$fault2A$z %>% plot.xts()
faults_ls$fault2B$x %>% plot.xts()
faults_ls$fault2B$y %>% plot.xts()
faults_ls$fault2B$z %>% plot.xts()
faults_ls$fault3A$x %>% plot.xts()
faults_ls$fault3A$y %>% plot.xts()
faults_ls$fault3A$z %>% plot.xts()
faults_ls$fault3B$x %>% plot.xts()
faults_ls$fault3B$y %>% plot.xts()
faults_ls$fault3B$z %>% plot.xts()

## ----msad-pca------------------------------------------------------------
Sys.time()
results_ls <- mvMonitoring::mspTrain(data = faults_ls$normal[,2:4],
                         labelVector = faults_ls$normal[,1],
                         trainObs = 4320,
                         updateFreq = 1440,
                         alpha = 0.001,
                         faultsToTriggerAlarm = 3,
                         lagsIncluded = 2)
Sys.time() # 14 seconds for 720 train, 360 update; 5 seconds for 1440, 720;
# 1 second for 2880 train (two days), and 1440 update (one day).

# Alarm code: 1 = T2 alarm; 2 = SPE alarm; 3 = both
(falseAlarmRate_SPE <- sum(results_ls$FaultChecks[,5] %in% c(2,3)) /
  nrow(results_ls$FaultChecks))
# The SPE false alarm rate hits 0 at alpha = 0.07.
(falseAlarmRate_T2 <- sum(results_ls$FaultChecks[,5] %in% c(1,3)) /
  nrow(results_ls$FaultChecks))
# The T2 false alarm rate hits 0 at alpha = 0.00015, and is at 16% at 0.07. The
# T2 statistic throws too many false alarms for my taste.
# These values were before we split the update observations by a third. These
# false alarm rates increased dramatically (0.19, 0.41), so we increased the 
# number of training observations to 4320 (three days worth, up from 2880). The
# false alarm rates dropped back, but not nearly as low (0.0031, 0.0884).

