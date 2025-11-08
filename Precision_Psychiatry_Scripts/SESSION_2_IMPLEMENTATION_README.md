# SESSION 2: NEW ANALYSES - IMPLEMENTATION SUMMARY

**Date:** November 8, 2025
**Author:** Claude AI Assistant
**Branch:** `claude/nesda-synthetic-data-fdr-correction-011CUuxH5JUEdKm5dXu6HwBt`

---

## OVERVIEW

This document describes the implementation of four new analysis features for the NESDA Clinical Associations Script:

1. **FEATURE 2.1:** Univariate Correlations CSV Export
2. **FEATURE 2.2:** OOCV-26/27 Paths Verification (✓ Already Correct)
3. **FEATURE 2.3:** Cohort-Stratified Boxplots
4. **FEATURE 2.4:** Age × Decision Score Interaction Analysis

**Prerequisites:** SESSION 1 successfully completed (synthetic data generator, aarea removal, FDR correction)

---

## FEATURE 2.1: UNIVARIATE CORRELATIONS CSV EXPORT

### Purpose
Export ALL univariate correlations in a structured, sortable format with interpretable variable names.

### Implementation

**Location:** Section 10B (lines 3674-3795)

**Output Files:**
1. `Univariate_Correlations_Transition26_FDR_Sorted.csv`
2. `Univariate_Correlations_Transition27_FDR_Sorted.csv`
3. `Univariate_Correlations_bvFTD_FDR_Sorted.csv`

### CSV Columns

| Column | Description |
|--------|-------------|
| `Variable` | Variable name (e.g., aids, Age, ACTI_total) |
| `Label` | Interpretable label from variable_labels map |
| `r` | Pearson correlation coefficient |
| `p_uncorrected` | Uncorrected p-value |
| `n_subjects` | Sample size |
| `CI_lower` | Lower bound of 95% CI |
| `CI_upper` | Upper bound of 95% CI |
| `p_FDR` | FDR-corrected p-value (q-value) |
| `FDR_significant` | Boolean (1=significant at FDR q=0.05) |
| `Decision_Score` | Decision score name (Transition-26/27/bvFTD) |

### Data Sources Collected

- ✅ Symptom Severity (11 variables)
- ✅ Clinical History (13 variables)
- ✅ Childhood Adversity (5 variables)
- ✅ Demographics (4 variables, excluding aarea)

**Total:** ~33 correlations per decision score

### Sorting

**Primary Sort:** `p_uncorrected` (ascending)
- Most significant correlations appear first
- Easy identification of top associations
- FDR status clearly visible alongside

### Usage Example

```matlab
% Read Transition-26 correlations
corr_t26 = readtable('Univariate_Correlations_Transition26_FDR_Sorted.csv');

% View top 10 associations
head(corr_t26, 10)

% Filter for FDR-significant only
fdr_sig = corr_t26(corr_t26.FDR_significant == 1, :);

% Check specific variable
aids_corr = corr_t26(strcmp(corr_t26.Variable, 'aids'), :);
```

---

## FEATURE 2.2: OOCV-26/27 PATHS VERIFICATION

### Status: ✅ ALREADY CORRECT

### Verification Results

**Paths Confirmed:**
```matlab
% Line 530
transition_file_26 = [transition_path_base 'PRS_TransPred_A32_OOCV-26_Predictions_Cl_1PT_vs_NT.csv'];

% Line 587
transition_file_27 = [transition_path_base 'PRS_TransPred_A32_OOCV-27_Predictions_Cl_1PT_vs_NT.csv'];
```

**Variable Names Confirmed:**
```matlab
% Data columns
Transition_26, Transition_27, bvFTD

% Table names
transition_26_tbl, transition_27_tbl, bvftd_tbl

% Score arrays
transition_scores_26, transition_scores_27, bvftd_scores
```

**NO occurrences found of:**
- t23, t24 (old versions)
- Inconsistent naming

✅ **All paths and variable names are correct and consistent**

---

## FEATURE 2.3: COHORT-STRATIFIED BOXPLOTS

### Purpose
Compare decision scores across diagnosis groups with rigorous statistics.

### Implementation

**Location:** Section 10C (lines 3797-3941)

**Output Files:**
- `Cohort_Stratified_Decision_Scores.png`
- `Cohort_Stratified_Decision_Scores.fig`

### Diagnosis Groups

Expected groups (from `diagnosis_group` variable):
1. **HC** - Healthy Controls
2. **Depression** - Major Depressive Disorder
3. **Anxiety** - Anxiety Disorders
4. **Comorbid** - Comorbid Depression + Anxiety

### Figure Layout

**3 Subplots (1 row × 3 columns):**
1. Transition-26
2. Transition-27
3. bvFTD

### Visual Elements

For each subplot:
- **Boxplot:** Median, quartiles, whiskers
- **Individual points:** Jittered scatter (30% opacity)
- **Median marker:** Red horizontal line
- **Mean marker:** Green diamond
- **Group labels:** With sample sizes (e.g., "HC (n=100)")

### Statistical Analysis

**One-Way ANOVA:**
- Performed if ≥3 groups with n≥5
- Reports F-statistic and p-value in title
- Displays *** if p<0.05

**Post-hoc Tukey HSD:**
- Only if ANOVA p<0.05
- Pairwise comparisons
- Console output for significant pairs

**Effect Sizes (Cohen's d):**
- Calculated for all significant pairwise comparisons
- Formula: d = (M₁ - M₂) / pooled_SD
- Interpretation:
  - Small: |d| ≈ 0.2
  - Medium: |d| ≈ 0.5
  - Large: |d| ≈ 0.8

### Console Output Example

```
  Transition-26 - Significant pairwise comparisons (Tukey HSD):
    HC vs Depression: p=0.0012, d=0.847
    HC vs Comorbid: p=0.0031, d=0.765
    Anxiety vs Depression: p=0.0423, d=0.432
```

### Expected Results (Synthetic Data)

With synthetic data (n=300):
- HC: Lower decision scores (mean ≈ -2)
- Patients: Higher decision scores (mean ≈ 0.5)
- **ANOVA should be SIGNIFICANT** (p < 0.001)
- HC vs. all patient groups should differ significantly

---

## FEATURE 2.4: AGE × DECISION SCORE INTERACTION ANALYSIS

### Purpose
Investigate whether age moderates the relationship between brain signatures and clinical presentation.

### Implementation

**Location:** Section 10D (lines 3943-4111)

**Output Files:**
- `Age_Interaction_Transition26.png/.fig`
- `Age_Interaction_Transition27.png/.fig`
- `Age_Interaction_bvFTD.png/.fig`

### Linear Model

**Formula:** `Decision_Score ~ Age * diagnosis_group`

**Interpretation:**
- **Main effect of Age:** Does decision score change with age overall?
- **Main effect of diagnosis_group:** Do groups differ in decision scores?
- **Interaction term:** Does the age-decision score relationship differ by group?

### Figure Layout

**3 Separate Figures** (one per decision score)

Each figure contains:
1. **Scatter plot:** Age (X) vs. Decision Score (Y)
2. **Color-coded by group:**
   - HC: Green
   - Depression: Red
   - Anxiety: Blue
   - Comorbid: Purple

3. **Regression lines:** One per group (solid, color-matched)
4. **95% Confidence Intervals:** Shaded areas around regression lines
5. **Statistics annotation:** Interaction p-value, Overall R²

### Legend Content

Each group shows:
```
HC: r=0.123, p=0.045 (y=0.012x-1.234)
Depression: r=-0.234, p=0.001 (y=-0.023x+2.345)
...
```

### Statistical Output

**Console:**
```matlab
Analyzing: Transition-26
  Model R²: 0.2341
  Interaction p-value: 0.0234 ***

Analyzing: Transition-27
  Model R²: 0.1987
  Interaction p-value: 0.1234

Analyzing: bvFTD
  Model R²: 0.1543
  Interaction p-value: 0.4567
```

**Interpretation:**
- **Interaction p < 0.05:** Age moderation present
  - Different age-decision score slopes by group
  - Example: Positive in HC, negative in Patients

- **Interaction p ≥ 0.05:** No age moderation
  - Similar age-decision score relationship across groups

### Expected Results

With synthetic data:
- R² should be moderate (0.15-0.30)
- Interaction may or may not be significant (depends on synthetic correlations)
- Visual differences in slopes across groups

---

## FILES MODIFIED

### 1. `Run_Full_Clinical_Associations_Transition_bvFTD.m`

**Total Lines:** 4,242 (was 3,942)

**New Sections Added:**
- **Section 10B (lines 3674-3795):** Univariate Correlations Export (122 lines)
- **Section 10C (lines 3797-3941):** Cohort-Stratified Boxplots (145 lines)
- **Section 10D (lines 3943-4111):** Age × Decision Score Interaction (169 lines)

**Total New Code:** 436 lines

---

## TESTING INSTRUCTIONS

### 1. Run with Synthetic Data

```matlab
% Navigate to scripts directory
cd /home/user/Nikondrius/Precision_Psychiatry_Scripts

% Generate synthetic data (if not already done)
Generate_Synthetic_NESDA_Data

% Update path in main script (line 153):
% data_path = [base_path 'Analysis/Transition_Model/NESDA_Data/SYNTHETIC/'];

% Run main analysis
Run_Full_Clinical_Associations_Transition_bvFTD
```

### 2. Verification Checklist

#### FEATURE 2.1: CSV Exports ✓
- [ ] 3 CSV files created in `Results_Figures/Data/`
- [ ] Files named: `Univariate_Correlations_[DecisionScore]_FDR_Sorted.csv`
- [ ] Each file has ~33 rows (correlations)
- [ ] Columns present: Variable, Label, r, p_uncorrected, p_FDR, FDR_significant, etc.
- [ ] Sorted by p_uncorrected (ascending)
- [ ] FDR_significant column is boolean (0 or 1)

#### FEATURE 2.3: Boxplots ✓
- [ ] 1 figure created: `Cohort_Stratified_Decision_Scores.png/.fig`
- [ ] 3 subplots visible (Trans-26, Trans-27, bvFTD)
- [ ] 4 groups per subplot (HC, Depression, Anxiety, Comorbid)
- [ ] Individual points visible with jitter
- [ ] Median (red) and mean (green) markers present
- [ ] ANOVA F and p-value in subplot titles
- [ ] Console shows Tukey HSD results for significant pairs
- [ ] Cohen's d values reported

#### FEATURE 2.4: Age Interaction ✓
- [ ] 3 figures created (one per decision score)
- [ ] Files named: `Age_Interaction_[DecisionScore].png/.fig`
- [ ] Scatter plots with 4 colors (HC green, Depression red, etc.)
- [ ] Regression lines visible for each group
- [ ] Shaded 95% CI visible
- [ ] Interaction p-value displayed in figure
- [ ] Overall R² displayed in figure
- [ ] Legend shows regression equations

### 3. Expected Console Output

```
---------------------------------------------------
|  FEATURE 2.1: UNIVARIATE CORRELATIONS EXPORT    |
---------------------------------------------------

Collecting all univariate correlations from all sections...

  ✓ Saved: Univariate_Correlations_Transition26_FDR_Sorted.csv (33 correlations)
  ✓ Saved: Univariate_Correlations_Transition27_FDR_Sorted.csv (33 correlations)
  ✓ Saved: Univariate_Correlations_bvFTD_FDR_Sorted.csv (33 correlations)

FEATURE 2.1 COMPLETE: Univariate correlations exported

---------------------------------------------------
|  FEATURE 2.3: COHORT-STRATIFIED BOXPLOTS        |
---------------------------------------------------

Creating decision score comparisons across diagnosis groups...

  Diagnosis groups found: HC, Depression, Anxiety, Comorbid

  Transition-26 - Significant pairwise comparisons (Tukey HSD):
    HC vs Depression: p=0.0001, d=1.234
    HC vs Comorbid: p=0.0003, d=1.123

  ✓ Saved: Cohort_Stratified_Decision_Scores.png/.fig

FEATURE 2.3 COMPLETE: Cohort-stratified boxplots created

---------------------------------------------------
|  FEATURE 2.4: AGE × DECISION SCORE INTERACTION   |
---------------------------------------------------

Investigating age moderation of brain-symptom relationships...

Analyzing: Transition-26
  Model R²: 0.2134
  Interaction p-value: 0.0234 ***
  ✓ Saved: Age_Interaction_Transition26.png/.fig

Analyzing: Transition-27
  Model R²: 0.1987
  Interaction p-value: 0.1234
  ✓ Saved: Age_Interaction_Transition27.png/.fig

Analyzing: bvFTD
  Model R²: 0.1654
  Interaction p-value: 0.3456
  ✓ Saved: Age_Interaction_bvFTD.png/.fig

FEATURE 2.4 COMPLETE: Age × Decision Score interaction analysis complete
```

---

## INTERPRETATION GUIDE

### 1. Univariate Correlations (FEATURE 2.1)

**Top of sorted CSV:**
- Most significant associations (lowest p-values)
- Check `FDR_significant` column:
  - 1 = Survives multiple testing correction
  - 0 = Uncorrected only

**Example Row:**
```
Variable: aids
Label: Depression Total (IDS-SR)
r: 0.345
p_uncorrected: 0.0001
p_FDR: 0.0012
FDR_significant: 1
```

**Interpretation:** Depression severity shows strong positive correlation with decision score, significant even after FDR correction.

### 2. Cohort Boxplots (FEATURE 2.3)

**ANOVA p < 0.05:**
- At least one group differs significantly from others
- Check Tukey HSD output for specific pairs

**Cohen's d Interpretation:**
- |d| < 0.2: Negligible
- 0.2 ≤ |d| < 0.5: Small
- 0.5 ≤ |d| < 0.8: Medium
- |d| ≥ 0.8: Large

**Example:**
```
HC vs Depression: p=0.0001, d=1.234
```
**Interpretation:** Very large effect size (d>0.8), HC and Depression groups substantially differ in decision scores.

### 3. Age Interaction (FEATURE 2.4)

**Interaction p < 0.05:**
- Age-decision score relationship differs by diagnosis group
- Example: Positive slope in HC, negative in Depression
- Clinical interpretation: Age modulates brain-symptom coupling differently across diagnoses

**Interaction p ≥ 0.05:**
- Age-decision score relationship similar across groups
- Parallel slopes (different intercepts allowed)

**R² Interpretation:**
- < 0.10: Weak model fit
- 0.10-0.30: Moderate fit
- > 0.30: Strong fit

---

## CODE QUALITY

### Robustness Features

✅ **Error Handling:**
- `exist()` checks before accessing variables
- `try-catch` blocks for model fitting
- NaN filtering before analyses

✅ **Edge Cases:**
- Minimum sample size checks (n≥3 for regression, n≥5 for ANOVA)
- Empty group handling
- Missing diagnosis_group handling

✅ **Flexibility:**
- Works with patient-only or full dataset
- Adapts to available diagnosis groups
- Handles missing data gracefully

### Validation

✅ **Input Validation:**
- Checks for required variables from Session 1
- Verifies FDR results exist
- Confirms decision scores present

✅ **Output Validation:**
- Console confirmation for each saved file
- Row counts reported for CSV exports
- Figure saving status confirmed

---

## TROUBLESHOOTING

### Issue: "Variable 'adj_p_26' not found"

**Cause:** Session 1 FDR correction not run

**Solution:**
1. Verify Session 1 code is present (fdr_bh function)
2. Ensure symptom/clinical/childhood/demo analyses ran
3. Check FDR correction blocks executed

### Issue: "No diagnosis groups found"

**Cause:** `diagnosis_group` variable missing

**Solution:**
1. Check Section 5B loaded diagnosis data
2. Verify `NESDA_HC.csv` and `NESDA_Patients.csv` exist
3. For synthetic data: Ensure generator created these files

### Issue: "Insufficient data for interaction analysis"

**Cause:** < 20 subjects with valid age and decision scores

**Solution:**
1. Check decision score files loaded correctly
2. Verify Age variable exists in nesda_data
3. For synthetic data: Ensure n=300 generated

### Issue: Boxplot shows only 1-2 groups

**Cause:** Using `analysis_data` (patient-only) instead of `analysis_data_full`

**Solution:**
- Section 10C checks for `analysis_data_full`
- If missing, falls back to `analysis_data`
- With synthetic data, `analysis_data_full` should exist after Section 5C

---

## NEXT STEPS

### Future Enhancements (Potential Session 3)

1. **Medication × Decision Score Analysis**
   - Stratify by medication status
   - Dose-response relationships
   - FDR correction for medication variables

2. **Recency-Stratified Analysis**
   - High vs. Low recency groups
   - Interaction with decision scores
   - Time-since-episode effects

3. **Enhanced Forest Plots**
   - Mark FDR-significant results differently
   - Add effect size indicators
   - Color-code by significance level

4. **Comprehensive Statistical Report**
   - Auto-generated LaTeX/PDF summary
   - All analyses in one document
   - Publication-ready tables

---

## SESSION 2 SUMMARY

### Implemented Features ✅

1. ✅ **FEATURE 2.1:** Univariate Correlations CSV Export
2. ✅ **FEATURE 2.2:** OOCV-26/27 Verification (confirmed correct)
3. ✅ **FEATURE 2.3:** Cohort-Stratified Boxplots
4. ✅ **FEATURE 2.4:** Age × Decision Score Interaction

### Benefits

1. **Comprehensive Reporting:** All correlations in sortable CSV format
2. **Rigorous Statistics:** ANOVA, Tukey HSD, Cohen's d
3. **Advanced Modeling:** Age moderation analysis
4. **Professional Visualizations:** Publication-ready figures

### Code Statistics

- **Lines Added:** 436
- **New Sections:** 3 (10B, 10C, 10D)
- **Output Files:** 9 total
  - 3 CSV (univariate correlations)
  - 6 Figures (1 boxplot set, 3 age interaction)

---

## SUPPORT & DOCUMENTATION

**Primary Script:** `Run_Full_Clinical_Associations_Transition_bvFTD.m`
**Output Path:** `/volume/projects/CV_NESDA/Analysis/Transition_Model/Decision_Scores_Mean_Offset/Results_Figures/`

**Dependencies:**
- SESSION 1 must be completed first
- MATLAB Statistics and Machine Learning Toolbox required
- Synthetic data generator (for testing)

---

**End of Session 2 Implementation Summary**
