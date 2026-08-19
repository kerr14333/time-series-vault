# 50-08 -- A COVID-like shock, and the three treatment strategies.
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

# Build a clean synthetic monthly series, then break it the way 2020 did.
set.seed(2020)
n <- 240
t <- 1:n
base <- ts(exp(log(1000 + 3*t) + 0.12*sin(2*pi*t/12) + 0.05*sin(2*pi*t/6) +
               rnorm(n, sd = 0.01)), start = c(2005, 1), frequency = 12)

shock_at <- which(time(base) >= 2020 & cycle(base) == 3)[1]   # March 2020
shock <- rep(0, n)
shock[shock_at]     <- -0.40
shock[shock_at + 1] <- -0.35
shock[shock_at + 2] <- -0.25
shock[shock_at + 3:8] <- -0.20 * 0.75^(0:5)
covid <- base * (1 + shock)

op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(base,  ylab = "", main = "clean series")
plot(covid, ylab = "", main = "with a COVID-like shock (Mar 2020 onward)")
par(op)

d10 <- function(m) as.numeric(series(m, "d10"))
clean_f <- d10(seas(base, x11 = "", outlier = NULL))

fit_or_null <- function(...) tryCatch(seas(...), error = function(e) NULL)

cat("=== how far does the contamination reach? ===\n")
m_un <- fit_or_null(covid, x11 = "", outlier = NULL)
if (!is.null(m_un)) {
  f <- d10(m_un)
  pd <- 100 * abs(f - clean_f) / clean_f
  yrs <- as.integer(floor(time(base)))
  by_year <- tapply(pd, yrs, mean)
  cat("  mean |seasonal factor error| by year, untreated:\n")
  print(round(by_year[as.character(2016:2024)], 2))
  cat(sprintf("  years with mean error > 1%%: %d\n", sum(by_year > 1, na.rm = TRUE)))
  cat("\nThe damage is NOT confined to 2020. Seasonal factors are estimated across\n")
  cat("years within a calendar month (20-04), so an extreme March 2020 corrupts\n")
  cat("the March factor for years either side.\n\n")
}

# The three strategies --------------------------------------------------
cat("=== three treatment strategies ===\n")
aos <- paste0("AO", format(time(covid)[shock_at + 0:8], nsmall = 0))
aos <- sprintf("AO%d.%d", as.integer(floor(time(covid)[shock_at + 0:8])),
               as.integer(cycle(covid)[shock_at + 0:8]))

strategies <- list(
  "untreated"        = function() fit_or_null(covid, x11 = "", outlier = NULL),
  "automatic outlier"= function() fit_or_null(covid, x11 = ""),
  "explicit AOs"     = function() fit_or_null(covid, x11 = "", outlier = NULL,
                                              regression.variables = aos),
  "exclude 2020"     = function() fit_or_null(covid, x11 = "", outlier = NULL,
                                              series.modelspan = "2005.1,2019.12")
)
for (nm in names(strategies)) {
  m <- strategies[[nm]]()
  if (is.null(m)) { cat(sprintf("  %-18s could not run\n", nm)); next }
  f <- d10(m)
  pd <- 100 * abs(f - clean_f) / clean_f
  outside <- time(base) < 2020 | time(base) >= 2022
  cat(sprintf("  %-18s mean |error| overall %.2f%%   OUTSIDE the shock years %.2f%%\n",
              nm, mean(pd), mean(pd[outside])))
}
cat("\nThe column that matters is the last one: how much did the shock corrupt\n")
cat("the years that had nothing to do with it?\n\n")

cat("=== the judgement no diagnostic could make ===\n")
cat("At the time, nobody could tell whether March 2020 was:\n")
cat("  an AO   (a one-off, the series returns to trend)\n")
cat("  an LS   (a permanent step down)\n")
cat("  a regime change (the model no longer applies)\n")
cat("The distinction depends on what happens NEXT, and next had not happened.\n")
cat("Every diagnostic in Module 5 answers a question about the PAST.\n")
