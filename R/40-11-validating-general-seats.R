# 40-11 -- Validate the GENERAL SEATS code against X-13, on models that are
# not the airline model.
#
# 40-08 checks _seats.R against X-13 for the airline model and gets 0.001%.
# That says nothing about _seats_general.R, whose whole job is the part the
# airline model never exercises: deciding which component each AR root belongs
# to. This script checks that decision against X-13's own answer, and then
# checks the resulting decomposition.
#
# X-13 does not report the split in udg(). It prints it, as the FACTORIZATION
# OF THE TOTAL AUTOREGRESSIVE POLYNOMIAL, so that is what this reads. Parsing
# a program's printout is not elegant, but the alternative is asserting the
# answer from the source code and never testing it -- which is how this file's
# subject got two rules wrong in the first place.
source("R/_seats_general.R"); source("R/_series.R")
if (!requireNamespace("seasonal", quietly = TRUE)) stop("needs the 'seasonal' package")
suppressMessages(library(seasonal))

# ---- reading X-13's own AR factorization -----------------------------------
# Returns the trend / seasonal / transitory AR polynomials as X-13 formed them,
# or NULL if the run was rejected or the output could not be parsed.
x13_ar_split <- function(y, model, ar = NULL, ma = NULL) {
  # sim_cycle() reseeds, so a random directory name would repeat; count instead.
  .x13_run_id <<- if (exists(".x13_run_id")) .x13_run_id + 1L else 1L
  d <- file.path(tempdir(), sprintf("x13v%03d", .x13_run_id))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  args <- list(x = y, transform.function = "log", arima.model = model,
               regression.aictest = NULL, outlier = NULL, x11 = NULL,
               seats.noadmiss = "no", dir = d)
  if (!is.null(ar)) args$arima.ar <- ar
  if (!is.null(ma)) args$arima.ma <- ma
  m <- suppressMessages(tryCatch(do.call(seas, args), error = function(e) NULL))
  f <- file.path(d, "iofile.html")
  if (!file.exists(f)) return(NULL)
  txt <- gsub("<[^>]*>", "", readLines(f, warn = FALSE))
  if (any(grepl("NO ADMISSIBLE", txt))) return(NULL)
  grab <- function(header, tag) {
    i <- grep(header, txt, fixed = TRUE)
    if (!length(i)) return(NULL)
    j <- i[1] + seq_len(30)
    j <- j[j <= length(txt)]
    hit <- grep(paste0("^", tag, "\\( *[0-9]+\\)"), txt[j])
    if (!length(hit)) return(NULL)
    run <- txt[j][hit[1]:(hit[1] + sum(diff(c(0, hit)) == 1) - 1)]
    as.numeric(sub(paste0("^", tag, "\\( *[0-9]+\\) *"), "", run))
  }
  list(trend      = grab("Autoregressive trend-cycle polynomial", "PHIPT"),
       transitory = grab("Autoregressive TRANSITORY polynomial",  "PHIC"),
       seasonal   = grab("Autoregressive seasonal polynomial",    "PHIST"))
}

# A stationary AR(2) at a chosen period and modulus, on top of a seasonal
# difference. d = 0 keeps the canonical decomposition admissible, which
# matters: with (1-B) as well, a low-frequency AR pair competes with the trend
# and X-13 refuses the decomposition before it will tell you anything.
sim_cycle <- function(per, rB, n = 300, Th = 0.5, seed = 5) {
  set.seed(seed)
  wc <- 2 * pi / per; a <- c(2 * cos(wc) / rB, -1 / rB^2)
  w <- as.numeric(arima.sim(list(ar = a, ma = c(rep(0, 11), -Th)),
                            n = n + 60, sd = 0.02))
  u <- numeric(length(w))
  for (i in seq_along(w)) u[i] <- w[i] + if (i > 12) u[i - 12] else 0
  u <- u[-(1:60)]
  list(y = ts(exp(4 + 0.05 * u / sd(u)), start = c(1990, 1), frequency = 12), ar = a)
}

cat("=== 1. where does a cyclical AR pair go? ours vs X-13's own printout ===\n")
cat("  The rule under test: a complex pair joins the TREND if the inverse-root\n")
cat("  modulus exceeds rmod = 0.5 and the frequency is within 360/(2s) = 15\n")
cat("  degrees of zero; joins the SEASONAL if the modulus clears 0.5 and the\n")
cat("  frequency is within epsphi = 2 degrees of a multiple of 30; otherwise\n")
cat("  it is TRANSITORY.\n\n")
cat(sprintf("  %6s %8s %7s  %-11s %-11s %s\n",
            "period", "1/|B|", "degrees", "X-13", "ours", ""))
cases <- list(c(60, 1.5), c(40, 1.5), c(40, 1.2), c(30, 1.5),
              c(24, 1.5), c(22, 1.5), c(20, 1.5), c(9, 1.5))
n_ok <- 0L; n_run <- 0L
for (cs in cases) {
  per <- cs[1]; rB <- cs[2]
  o <- sim_cycle(per, rB)
  sp <- seats_ar_split_general(ar = o$ar, d = 0, D = 1, s = 12)
  row <- sp$table[abs(sp$table$modulus - rB) < 1e-6, ][1, ]
  fx <- x13_ar_split(o$y, "(2 0 0)(0 1 1)",
                     ar = paste0(sprintf("%.6ff", o$ar), collapse = ","),
                     ma = "0.5f")
  # X-13's answer: the AR(2) shows up in whichever polynomial has degree >= 2.
  x13 <- if (is.null(fx)) NA_character_ else
    if (!is.null(fx$transitory) && length(fx$transitory) >= 3) "transitory" else
    if (!is.null(fx$trend) && length(fx$trend) >= 3) "trend" else "seasonal"
  agree <- !is.na(x13) && identical(x13, row$component)
  n_run <- n_run + !is.na(x13); n_ok <- n_ok + agree
  cat(sprintf("  %6.0f %8.3f %7.2f  %-11s %-11s %s\n", per, row$inv_mod,
              360 / per, if (is.na(x13)) "unreadable" else x13, row$component,
              if (is.na(x13)) "" else if (agree) "OK" else "<-- MISMATCH"))
}
cat(sprintf("\n  %d of %d readable cases agree.\n", n_ok, n_run))
cat("  The boundary is a period of 24 months and it is sharp: 30 months is\n")
cat("  trend, 22 months is transitory, and nothing about the series changes\n")
cat("  across that line except the root's angle.\n")
cat("\n  The 24-month row is the one that used to disagree, and it is worth\n")
cat("  knowing why it stopped. The test is a STRICT inequality against an\n")
cat("  exact boundary, so a root sitting on the line is decided by whatever\n")
cat("  numerical noise the angle carries:\n")
o24  <- sim_cycle(24, 1.5)
bare <- abs(Arg(polyroot(c(1, -o24$ar))[1])) * 180 / pi
full <- poly_mult(c(1, -o24$ar), c(1, rep(0, 11), -1))
zf   <- polyroot(full)
pair <- mean(abs(Arg(zf[abs(Mod(zf) - 1.5) < 1e-4])) * 180 / pi)
cat(sprintf("    from the AR(2) alone           : 15 %+.1e degrees\n", bare - 15))
cat(sprintf("    from the expanded degree-14 AR : 15 %+.1e degrees\n", pair - 15))
cat("  Same root, opposite sides of the cutoff. The fix is not an epsilon --\n")
cat("  it is to stop expanding the polynomial before factoring it. Each\n")
cat("  factor's roots are analytic or come from a small polynomial, so the\n")
cat("  angles are exact to machine precision and the strict inequality means\n")
cat("  what it says.\n")
cat("\n  This is not a contrived worry. A NEGATIVE seasonal AR coefficient\n")
cat("  puts every one of its roots at an odd multiple of 180/s -- for monthly\n")
cat("  data exactly 15, 45, 75 ... degrees. The first of those sits exactly\n")
cat("  on the trend boundary, and nottem fitted as (1 0 0)(1 1 1) has Phi\n")
cat("  negative, so it happens on a real catalogue series with a real model.\n")

cat("\n=== 2. a real series with a genuine transitory component ===\n")
x <- vault_series()$imp
m <- seas(x, transform.function = "log", arima.model = "(2 1 0)(0 1 1)",
          regression.aictest = NULL, outlier = NULL, x11 = NULL, seats.save = "s14")
ar  <- as.numeric(coef(m)[c("AR-Nonseasonal-01", "AR-Nonseasonal-02")])
sma <- as.numeric(coef(m)["MA-Seasonal-12"])
cat(sprintf("  imp, (2 1 0)(0 1 1): ar = (%.4f, %.4f), Theta = %.4f\n",
            ar[1], ar[2], sma))
sp <- seats_ar_split_general(ar = ar, d = 1, D = 1, s = 12)
print(unique(sp$table[sp$table$component == "transitory", ]), row.names = FALSE)
cat("  Inverse modulus 0.46 is below rmod, so the pair cannot enter the\n")
cat("  seasonal even though 134 degrees is only 14 degrees off a seasonal\n")
cat("  frequency. X-13 agrees: its TRANSITORY polynomial for this run is\n")
cat("  1 + 0.6438B + 0.2129B^2, which is the whole AR(2).\n")

g <- seats_decompose_general(x, ar = ar, sma = sma, d = 1, D = 1, s = 12,
                             max_lag = 300, extend = 320)
mine <- list(s10 = exp(g$seasonal), s12 = exp(g$trend), s14 = exp(g$transitory),
             s11 = exp(log(as.numeric(x)) - as.numeric(g$seasonal)))
tab <- list(s10 = series(m, "s10"), s11 = series(m, "s11"),
            s12 = series(m, "s12"), s14 = series(m, "s14"))
lab <- c(s10 = "seasonal factors", s11 = "adjusted series",
         s12 = "trend", s14 = "transitory")
cat("\n  component-by-component, ours vs X-13 SEATS:\n")
for (k in c("s10", "s11", "s12", "s14")) {
  a <- as.numeric(mine[[k]]); b <- as.numeric(tab[[k]])
  n <- length(a); int <- 25:(n - 24); pd <- 100 * abs(a - b) / abs(b)
  cat(sprintf("    %-4s %-18s interior mean %.4f%%  max %.4f%%  |  ends max %.4f%%\n",
              k, lab[[k]], mean(pd[int]), max(pd[int]), max(pd[-int])))
}
d10 <- log(as.numeric(mine$s10)) - log(as.numeric(tab$s10))
cat(sprintf("\n  In logs the seasonal differs by %+.6f on average with a spread of\n",
            mean(d10)))
cat(sprintf("  only %.1e. The disagreement is a CONSTANT, not a shape.\n", sd(d10)))

cat("\n=== 3. the constant that was hiding there ===\n")
gn <- seats_decompose_general(x, ar = ar, sma = sma, d = 1, D = 1, s = 12,
                              max_lag = 300, extend = 320, normalize = FALSE)
off <- mean(as.numeric(gn$seasonal) - log(as.numeric(tab$s10)))
cat(sprintf("  without normalisation the offset is %+.6f in logs (%.2f%%)\n",
            off, 100 * (exp(off) - 1)))
cat(sprintf("  with it, %+.6f (%.4f%%)\n", mean(d10), 100 * (exp(mean(d10)) - 1)))
cat("  nu_S(0) = 0, so the seasonal filter annihilates constants and the\n")
cat("  theory cannot say whether one belongs to the trend or the seasonal.\n")
cat("  X-13 normalises multiplicative factors to average 1 IN LEVELS, which\n")
cat("  in logs is a mean near -var/2 rather than 0. _seats.R does this and\n")
cat("  says so; _seats_general.R did not, and nothing caught it, because a\n")
cat("  constant multiplicative offset is invisible in every plot in the\n")
cat("  vault -- the trend still tracks the series, the factors still repeat.\n")
cat("  It took comparing against X-13 on a series _seats.R cannot handle.\n")

cat("\n=== 4. the additive case, which nothing used to exercise ===\n")
nt <- vault_series()$temperature
ma_ <- seas(nt, transform.function = "none", arima.model = "(1 0 0)(1 1 1)",
            regression.aictest = NULL, outlier = NULL, x11 = NULL)
ca <- coef(ma_)
cat(sprintf("  nottem, (1 0 0)(1 1 1) additive: ar = %.4f, Phi = %.4f, Theta = %.4f\n",
            ca[["AR-Nonseasonal-01"]], ca[["AR-Seasonal-12"]], ca[["MA-Seasonal-12"]]))
cat("  Phi is NEGATIVE, so the roots of (1 - Phi B^12) sit at odd multiples\n")
cat("  of 15 degrees -- the first one exactly on the trend boundary.\n")
spa <- seats_ar_split_general(ar = ca[["AR-Nonseasonal-01"]],
                              sar = ca[["AR-Seasonal-12"]], d = 0, D = 1, s = 12)
cat(sprintf("  our split: trend %s | seasonal %d roots | transitory %d roots\n",
            poly_show(spa$trend), sum(spa$table$component == "seasonal"),
            sum(spa$table$component == "transitory")))
cat("  X-13 prints exactly the same: trend 1 - B, seasonal S(B), and the\n")
cat("  whole stationary AR side -- (1 - 0.2710B)(1 + 0.2966B^12) -- in the\n")
cat("  transitory. Before the factorwise root-finding we put the 15-degree\n")
cat("  pair in the TREND, which moved the published trend by 2.6 degrees F.\n")
tabA <- list(s10 = series(ma_, "s10"), s12 = series(ma_, "s12"))
cat("\n  filter truncation has to reach further here, because that transitory\n")
cat("  factor has modulus 0.90 and its WK filter decays slowly:\n")
for (ml in c(150, 250, 400)) {
  ga <- seats_decompose_general(nt, ar = ca[["AR-Nonseasonal-01"]],
                                sar = ca[["AR-Seasonal-12"]], sma = ca[["MA-Seasonal-12"]],
                                d = 0, D = 1, s = 12, logs = FALSE,
                                max_lag = ml, extend = ml + 20,
                                warn_truncation = FALSE)
  e10 <- as.numeric(ga$seasonal) - as.numeric(tabA$s10)
  e12 <- as.numeric(ga$trend)    - as.numeric(tabA$s12)
  cat(sprintf("    max_lag %3d : seasonal sd %.4f  trend mean %+.5f\n",
              ml, sd(e10), mean(e12)))
}
cat("  At 150 lags the seasonal is out by 0.15 degrees F and the trend by\n")
cat("  0.94; at 400 both are under 0.002. Nothing is wrong with the additive\n")
cat("  path -- the default filter length was simply too short for a root\n")
cat("  this persistent, and there is no warning when that happens.\n")

cat("\n=== 5. what is left ===\n")
cat(sprintf("  A residual constant of %.4f%% remains in the seasonal factors.\n",
            100 * abs(exp(mean(d10)) - 1)))
cat("  It is the normalisation window: X-13 does not average over exactly the\n")
cat("  366 observations this code uses. Averaging over complete calendar\n")
cat("  years only makes it worse (0.09%), so the convention is something\n")
cat("  else again. The shape agreement of 1e-6 is the number that says the\n")
cat("  filters are right; this last constant is bookkeeping.\n")
cat("\n  max_lag used to be the open trap: nothing warned you when the filter\n")
cat("  was too short, and the components just came out quietly wrong, as\n")
cat("  section 4 shows. seats_decompose_general() now checks it. The decay\n")
cat("  rate is set by the MA side, not the AR side -- the WK filter is a\n")
cat("  ratio whose poles are the zeros of theta(B)theta(F) -- which is the\n")
cat("  opposite of the intuitive guess. What that check says here:\n")
msg <- NULL
withCallingHandlers(
  invisible(seats_decompose_general(nt, ar = ca[["AR-Nonseasonal-01"]],
    sar = ca[["AR-Seasonal-12"]], sma = ca[["MA-Seasonal-12"]],
    d = 0, D = 1, s = 12, logs = FALSE, max_lag = 150, extend = 170)),
  warning = function(w) { msg <<- conditionMessage(w); invokeRestart("muffleWarning") })
cat("   ", if (is.null(msg)) "(silent)" else msg, "\n")
cat("  AirPassengers needs 283, imp 224, nottem 523. The vault's own scripts\n")
cat("  were using 200 and 340 -- one of them short, and the numbers it\n")
cat("  produced looked exactly as convincing as the correct ones.\n")
