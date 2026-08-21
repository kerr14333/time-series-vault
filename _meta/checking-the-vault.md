---
aliases: [Checking the vault, check-numbers, Number guard]
tags: [meta, tooling]
---

# Checking the vault

The vault has one rule that matters: **every number in a note is reproducible by running a script.** If you read a figure here and cannot get it back out of `R/`, the note is wrong until proven otherwise.

That rule broke twice while the vault was being written, both times silently:

- an X-11 agreement figure was published as 0.88% from an old scratch run when the live code gave **0.52%**;
- **every** measured number in [[50-06-turning-points]] came from an earlier analysis and disagreed with the script the note pointed at — the ratio was 1.79×, not the 1.82× printed, and the whole table was off.

Neither was caught by reading. Both are caught by `R/check-numbers.R`.

## Running it

```bash
Rscript R/check-numbers.R           # reuse cached output where still valid
Rscript R/check-numbers.R --fresh   # re-run every script from scratch
```

A cached run takes about **a second**, so there is no reason not to run it before committing. A `--fresh` run re-executes all 48 scripts and takes on the order of ten minutes — several of the Module 5 scripts fit X-13 a hundred times over.

It exits **1** if anything is unexplained, so it can gate a commit. A clean run says:

```text
  404 computed-looking numbers checked across 64 notes
  every one is reproduced by a script (allowing for rounding).
```

## What it actually does

1. Runs each numbered script in `R/` and caches stdout under `.audit/` (gitignored).
2. Scans every note for numbers that look **computed** — two or more decimal places.
3. Reports any that no script produced.

Rounding is allowed: a note may print `1.14` where the script prints `1.137`. The test is whether the note's value is a correctly rounded version of something a script actually emitted, to within half a unit in the last place printed.

> [!important] The cache invalidation is the interesting part
> A script's output is re-run when that script changes **and also when any helper in `R/_*.R` changes.** That second condition is the one that matters. When `_x11.R` was generalised for quarterly data, it could have moved numbers in notes that never mention `_x11.R` — a shared-helper edit silently invalidates results all over the vault, which is exactly how stale numbers survive.

## When it flags something

There are three honest outcomes, and only one of them is "edit the allowlist":

| Cause | Fix |
|---|---|
| the note is stale | correct the note from fresh output |
| the number is real but the script never prints it | **print it** — otherwise the reader cannot reproduce it |
| it is a genuine constant, not a measurement | add it to `ALLOW` in `R/check-numbers.R`, *with a reason* |

The middle row is worth dwelling on. Two numbers in Module 4 were correct arithmetic sitting inside a ```` ```text ```` block formatted to look like script output, which the script never emitted. That is a trap for a reader following along: the block invites you to run it and compare, and the comparison quietly fails. The fix was to make the script print the number, not to excuse it.

`ALLOW` is deliberately tiny — three entries, each with a stated reason. It is the only way a wrong number can hide from this check, so it should stay small enough to read in one glance.

## What it does not check

It is a staleness detector, not a proof of correctness.

- A number that is **wrong in both the note and the script** passes. The guard checks agreement, not truth.
- Numbers with fewer than two decimals (`0.5`, `12%`) are not checked — too many false positives from prose. The counts in the sample output just above are themselves unchecked for exactly this reason, and went stale within an hour of being written.
- The **practice tier** is excluded. Those exercises and answers are hand-worked arithmetic ($0.5^5$, $2/\sqrt{n}$, Yule–Walker by hand) and invented scenario values ("suppose $t = 1.02$"), none of it derived from the code, so none of it can go stale when the code changes. That is a real blind spot and worth stating plainly: before the exclusion existed, the guard caught **two wrong answers** in that tier — invented polynomial roots, and a variance table whose ordering was backwards. Hand arithmetic in that tier is verified once, by hand, and then trusted.
- It says nothing about whether the *prose* around a number still holds. When 50-06's curvature figure was corrected from 1.18× to 1.42×, the sentence calling it "almost nothing" had to change too, and no tool would have told you that.

Related checks: `check_code_notes()` in `R/make-code-notes.R` verifies the `_code/` mirrors match their scripts; `check_figure_index()` in `R/make-figure-index.R` verifies the [[figure-index|figure appendix]] still matches `make-figures.R`; and re-running `R/make-figures.R` should leave `figures/` byte-identical.

Note that `_meta/figure-index.md` is **excluded** from the number check. It quotes `make-figures.R` verbatim, so its numbers are plotting parameters — margins, line widths, colour indices — not measurements. Checking them would mean checking source code against its own output.

## Links

- Module map: [[00-Start-Here]] · Progress: [[progress]]
- The failure that motivated it: [[50-06-turning-points]]
- The normalisation number it forced into the open: [[40-07-implementing-seats-in-r]]
