# 50-07 -- AO, LS, TC: getting the TYPE right matters as much as the location.
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

x <- AirPassengers
at <- 61                                   # January 1954
lab <- "1954.jan"

inject <- function(x, at, type, size = 0.30) {
  v <- as.numeric(x); n <- length(v)
  eff <- switch(type,
    AO = { e <- rep(0, n); e[at] <- 1; e },
    LS = { e <- rep(0, n); e[at:n] <- 1; e },
    TC = { e <- rep(0, n); e[at:n] <- 0.7^(0:(n - at)); e })
  ts(v * (1 + size * eff), start = start(x), frequency = frequency(x))
}

# EXERCISE 1: which type does most damage to the seasonal factors? -----
clean <- as.numeric(series(seas(x, x11 = "", outlier = NULL), "d10"))
cat("=== damage to the SEASONAL FACTORS, by outlier type (untreated) ===\n")
cat(sprintf("%-4s %12s %12s\n", "type", "mean |d10|%", "max |d10|%"))
for (ty in c("AO", "LS", "TC")) {
  y <- inject(x, at, ty)
  d <- tryCatch(as.numeric(series(seas(y, x11 = "", outlier = NULL), "d10")),
                error = function(e) NULL)
  if (is.null(d)) next
  pd <- 100 * abs(d - clean) / clean
  cat(sprintf("%-4s %12.3f %12.3f\n", ty, mean(pd), max(pd)))
}
cat("\nA LEVEL SHIFT does the most damage: it is not one bad month but a\n")
cat("permanent step the model has to absorb somehow.\n\n")

# EXERCISE 2: model an LS as an AO -- what does it cost? --------------
cat("=== modelling a genuine LS as an AO ===\n")
y <- inject(x, at, "LS")
fits <- list(
  none = tryCatch(seas(y, x11 = "", outlier = NULL), error = function(e) NULL),
  asAO = tryCatch(seas(y, x11 = "", outlier = NULL,
                       regression.variables = sprintf("AO%d.%d", 1954, 1)),
                  error = function(e) NULL),
  asLS = tryCatch(seas(y, x11 = "", outlier = NULL,
                       regression.variables = sprintf("LS%d.%d", 1954, 1)),
                  error = function(e) NULL))
for (nm in names(fits)) {
  m <- fits[[nm]]; if (is.null(m)) next
  d <- as.numeric(series(m, "d10"))
  pd <- 100 * abs(d - clean) / clean
  co <- coef(m); og <- grep("^(AO|LS|TC)", names(co), value = TRUE)
  cat(sprintf("  %-5s : mean |d10 error| %.3f%%   estimated effect %s\n", nm, mean(pd),
              if (length(og)) sprintf("%.4f", co[og[1]]) else "-"))
}
cat("  truth: a +30%% level shift, i.e. log effect", round(log(1.3), 4), "\n")
cat("\nThe right regressor recovers the effect and protects the factors. The\n")
cat("wrong one leaves the step in the data, distorting everything after it.\n\n")

# EXERCISE 3: the critical value ---------------------------------------
cat("=== how many outliers does automatic detection find? ===\n")
y <- inject(x, at, "AO")
for (cv in c(3.0, 3.5, 4.0, 5.0)) {
  m <- tryCatch(seas(y, x11 = "", outlier.critical = cv), error = function(e) NULL)
  if (is.null(m)) next
  og <- grep("^(AO|LS|TC)", names(coef(m)), value = TRUE)
  cat(sprintf("  critical = %.1f : %d outlier(s)  %s\n", cv, length(og),
              paste(og, collapse = " ")))
}
cat("\nNOTE: coef() also returns the ARIMA coefficients. Filter by name, or you\n")
cat("will report 'MA-Nonseasonal-01' as an outlier.\n\n")

# EXERCISE 4: an LS at the very END is indistinguishable from a turn ---
cat("=== the dangerous case: a level shift in the final months ===\n")
n <- length(x)
y_end <- inject(x, n - 5, "LS", size = -0.15)     # a downturn in the last 6 months
m <- tryCatch(seas(y_end, x11 = ""), error = function(e) NULL)
if (!is.null(m)) {
  og <- grep("^(AO|LS|TC)", names(coef(m)), value = TRUE)
  cat("  detected:", if (length(og)) paste(og, collapse = " ") else "nothing", "\n")
}
cat("  A level shift in the last few months looks EXACTLY like the start of a\n")
cat("  recession. Treating a real downturn as an LS removes the recession from\n")
cat("  the trend. No diagnostic can tell them apart -- only later data can.\n")
cat("  This is 50-06 and 50-08, in miniature.\n")
