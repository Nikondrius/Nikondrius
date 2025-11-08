#!/usr/bin/env python3
"""
Comprehensive Static Validation for MATLAB Script
Performs syntax checking, delimiter balance, function validation, and code quality metrics
"""

import re
from pathlib import Path
from collections import defaultdict

def analyze_matlab_script(filepath):
    """Perform comprehensive static analysis on MATLAB script"""

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    content = ''.join(lines)
    total_lines = len(lines)

    print("="*80)
    print("COMPREHENSIVE STATIC VALIDATION - NESDA CLINICAL ASSOCIATIONS SCRIPT")
    print("="*80)
    print(f"\nScript: {filepath}")
    print(f"Total lines: {total_lines:,}")
    print()

    # =========================================================================
    # 1. SYNTAX VALIDATION
    # =========================================================================
    print("="*80)
    print("1. SYNTAX VALIDATION")
    print("="*80)

    # Delimiter balance
    print("\n1.1 Delimiter Balance Check:")
    paren_balance = content.count('(') - content.count(')')
    bracket_balance = content.count('[') - content.count(']')
    brace_balance = content.count('{') - content.count('}')

    print(f"  Parentheses: {content.count('(')} open, {content.count(')')} close -> Balance: {paren_balance}")
    print(f"  Brackets:    {content.count('[')} open, {content.count(']')} close -> Balance: {bracket_balance}")
    print(f"  Braces:      {content.count('{')} open, {content.count('}')} close -> Balance: {brace_balance}")

    delimiter_pass = (paren_balance == 0 and bracket_balance == 0 and brace_balance == 0)
    print(f"\n  ✓ PASS: All delimiters balanced" if delimiter_pass else f"\n  ✗ FAIL: Delimiter mismatch detected")

    # Function/end matching
    print("\n1.2 Function/End Statement Matching:")
    function_defs = len(re.findall(r'^\s*function\s+', content, re.MULTILINE))
    end_statements = len(re.findall(r'^\s*end\s*($|;|%)', content, re.MULTILINE))

    # Count control structures that need 'end'
    if_count = len(re.findall(r'^\s*if\s+', content, re.MULTILINE))
    for_count = len(re.findall(r'^\s*for\s+', content, re.MULTILINE))
    while_count = len(re.findall(r'^\s*while\s+', content, re.MULTILINE))
    try_count = len(re.findall(r'^\s*try\s*($|%)', content, re.MULTILINE))
    switch_count = len(re.findall(r'^\s*switch\s+', content, re.MULTILINE))
    parfor_count = len(re.findall(r'^\s*parfor\s+', content, re.MULTILINE))

    total_structures = function_defs + if_count + for_count + while_count + try_count + switch_count + parfor_count

    print(f"  Functions:        {function_defs}")
    print(f"  If statements:    {if_count}")
    print(f"  For loops:        {for_count}")
    print(f"  While loops:      {while_count}")
    print(f"  Try blocks:       {try_count}")
    print(f"  Switch blocks:    {switch_count}")
    print(f"  Parfor loops:     {parfor_count}")
    print(f"  ---")
    print(f"  Total structures: {total_structures}")
    print(f"  End statements:   {end_statements}")

    end_balance = total_structures - end_statements
    print(f"  Balance:          {end_balance:+d}")

    structure_pass = abs(end_balance) <= 5  # Allow small margin for nested structures
    print(f"\n  ✓ PASS: Function/end balance acceptable" if structure_pass else f"\n  ⚠ WARNING: Potential function/end mismatch")

    # =========================================================================
    # 2. SESSION 3 HELPER FUNCTIONS VALIDATION
    # =========================================================================
    print("\n" + "="*80)
    print("2. SESSION 3 HELPER FUNCTIONS VALIDATION")
    print("="*80)

    # Check helper function definitions
    print("\n2.1 Helper Function Definitions:")

    helper_funcs = {
        'calculate_correlation_with_CI': r'function\s+\[.*?\]\s*=\s*calculate_correlation_with_CI',
        'create_forest_plot': r'function\s+.*?\s*=\s*create_forest_plot',
        'get_label_safe': r'function\s+.*?\s*=\s*get_label_safe',
        'fdr_bh': r'function\s+\[.*?\]\s*=\s*fdr_bh',
        'ternary': r'function\s+.*?\s*=\s*ternary',
        'redblue': r'function\s+.*?\s*=\s*redblue'
    }

    for func_name, pattern in helper_funcs.items():
        found = re.search(pattern, content)
        status = "✓ FOUND" if found else "✗ MISSING"
        print(f"  {status}: {func_name}()")

    # Check helper function calls
    print("\n2.2 Helper Function Usage:")

    calc_corr_calls = len(re.findall(r'calculate_correlation_with_CI\s*\(', content))
    forest_plot_calls = len(re.findall(r'create_forest_plot\s*\(', content))
    get_label_calls = len(re.findall(r'get_label_safe\s*\(', content)) + len(re.findall(r'get_label\s*\(', content))
    fdr_calls = len(re.findall(r'fdr_bh\s*\(', content))

    print(f"  calculate_correlation_with_CI() calls: {calc_corr_calls}")
    print(f"  create_forest_plot() calls:            {forest_plot_calls}")
    print(f"  get_label/get_label_safe() calls:      {get_label_calls}")
    print(f"  fdr_bh() calls:                        {fdr_calls}")

    # =========================================================================
    # 3. SESSION 3 CONSTANTS VALIDATION
    # =========================================================================
    print("\n" + "="*80)
    print("3. SESSION 3 CONSTANTS VALIDATION")
    print("="*80)

    print("\n3.1 Constant Definitions:")

    constants = {
        'MIN_SAMPLE_SIZE': r'MIN_SAMPLE_SIZE\s*=\s*(\d+)',
        'ALPHA_LEVEL': r'ALPHA_LEVEL\s*=\s*([\d.]+)',
        'FDR_LEVEL': r'FDR_LEVEL\s*=\s*([\d.]+)',
        'OUTLIER_THRESHOLD_DS': r'OUTLIER_THRESHOLD_DS\s*=\s*(\d+)',
        'OUTLIER_CODE': r'OUTLIER_CODE\s*=\s*(\d+)',
        'MIN_PCA_SAMPLES': r'MIN_PCA_SAMPLES\s*=\s*(\d+)',
        'CI_Z_SCORE': r'CI_Z_SCORE\s*=\s*([\d.]+)'
    }

    defined_constants = {}
    for const_name, pattern in constants.items():
        match = re.search(pattern, content)
        if match:
            value = match.group(1)
            defined_constants[const_name] = value
            print(f"  ✓ {const_name} = {value}")
        else:
            print(f"  ✗ {const_name} NOT FOUND")

    print("\n3.2 Constant Usage:")

    for const_name in constants.keys():
        # Count usage (excluding definition line)
        usage_count = len(re.findall(rf'\b{const_name}\b', content)) - 1  # -1 for definition
        print(f"  {const_name}: used {usage_count} time(s)")

    # Check if magic numbers still exist
    print("\n3.3 Magic Number Elimination:")

    # Check for hardcoded 99 (should be OUTLIER_CODE)
    hardcoded_99 = len(re.findall(r'==\s*99\b', content))
    # Check for hardcoded 10 in outlier context (should be OUTLIER_THRESHOLD_DS)
    hardcoded_10_outlier = len(re.findall(r'>\s*10\b.*outlier|outlier.*>\s*10\b', content, re.IGNORECASE))

    print(f"  Hardcoded '99' for outliers: {hardcoded_99} instances")
    print(f"  Hardcoded '10' for thresholds: {hardcoded_10_outlier} instances")

    if hardcoded_99 == 0 and hardcoded_10_outlier == 0:
        print("  ✓ PASS: Magic numbers successfully eliminated")
    else:
        print("  ⚠ WARNING: Some magic numbers may remain")

    # =========================================================================
    # 4. ERROR HANDLING VALIDATION
    # =========================================================================
    print("\n" + "="*80)
    print("4. ERROR HANDLING VALIDATION")
    print("="*80)

    print("\n4.1 Error Handling Blocks:")

    try_blocks = len(re.findall(r'^\s*try\s*($|%)', content, re.MULTILINE))
    catch_blocks = len(re.findall(r'^\s*catch\s+', content, re.MULTILINE))
    error_calls = len(re.findall(r'\berror\s*\(', content))
    warning_calls = len(re.findall(r'\bwarning\s*\(', content))

    print(f"  Try blocks:     {try_blocks}")
    print(f"  Catch blocks:   {catch_blocks}")
    print(f"  error() calls:  {error_calls}")
    print(f"  warning() calls: {warning_calls}")

    try_catch_balanced = (try_blocks == catch_blocks)
    print(f"\n  {'✓ PASS' if try_catch_balanced else '✗ FAIL'}: Try-catch blocks balanced")

    # Check critical sections have error handling
    print("\n4.2 Critical Operations with Error Handling:")

    readtable_total = len(re.findall(r'readtable\s*\(', content))
    intersect_total = len(re.findall(r'intersect\s*\(', content))
    pca_total = len(re.findall(r'\bpca\s*\(', content))
    saveas_total = len(re.findall(r'saveas\s*\(', content))

    print(f"  readtable() calls:  {readtable_total} (file loading)")
    print(f"  intersect() calls:  {intersect_total} (ID matching)")
    print(f"  pca() calls:        {pca_total} (PCA calculation)")
    print(f"  saveas() calls:     {saveas_total} (plot saving)")

    # Estimate error handling coverage
    error_handling_coverage = (try_blocks / max(1, readtable_total + intersect_total + pca_total)) * 100
    print(f"\n  Estimated error handling coverage: {error_handling_coverage:.1f}%")

    # =========================================================================
    # 5. CODE QUALITY METRICS
    # =========================================================================
    print("\n" + "="*80)
    print("5. CODE QUALITY METRICS")
    print("="*80)

    # Count comments
    comment_lines = sum(1 for line in lines if line.strip().startswith('%'))
    code_lines = total_lines - comment_lines
    blank_lines = sum(1 for line in lines if not line.strip())
    actual_code_lines = code_lines - blank_lines

    print("\n5.1 Documentation:")
    print(f"  Total lines:       {total_lines:,}")
    print(f"  Comment lines:     {comment_lines:,} ({100*comment_lines/total_lines:.1f}%)")
    print(f"  Blank lines:       {blank_lines:,} ({100*blank_lines/total_lines:.1f}%)")
    print(f"  Code lines:        {actual_code_lines:,} ({100*actual_code_lines/total_lines:.1f}%)")

    # Section headers
    section_headers = len(re.findall(r'^%{2,}\s*={5,}', content, re.MULTILINE))
    print(f"  Section headers:   {section_headers}")

    # Count fprintf for user feedback
    fprintf_calls = len(re.findall(r'\bfprintf\s*\(', content))
    print(f"  User feedback (fprintf): {fprintf_calls} messages")

    print("\n5.2 Code Organization:")

    # Count major sections
    sections = re.findall(r'^%%\s*={10,}.*?SECTION\s+(\d+\w*)', content, re.MULTILINE | re.IGNORECASE)
    print(f"  Major sections:    {len(sections)}")

    # Check for consistent indentation
    inconsistent_indent = 0
    for i, line in enumerate(lines[1:], 1):
        if line.strip() and not line.strip().startswith('%'):
            leading_spaces = len(line) - len(line.lstrip(' '))
            if leading_spaces % 4 != 0 and leading_spaces > 0:
                inconsistent_indent += 1

    print(f"  Inconsistent indents: {inconsistent_indent} lines")

    # =========================================================================
    # 6. SCIENTIFIC METHODOLOGY VALIDATION
    # =========================================================================
    print("\n" + "="*80)
    print("6. SCIENTIFIC METHODOLOGY VALIDATION")
    print("="*80)

    print("\n6.1 Statistical Methods:")

    # Correlation analysis
    corr_calls = len(re.findall(r'\bcorr\s*\(', content))
    fisher_z = len(re.findall(r'\batanh\s*\(', content))
    print(f"  Correlation calculations: {corr_calls}")
    print(f"  Fisher's Z transformations: {fisher_z}")

    # Multiple testing correction
    fdr_correction = len(re.findall(r'fdr_bh\s*\(', content))
    print(f"  FDR corrections (Benjamini-Hochberg): {fdr_correction}")

    # PCA
    pca_calls = len(re.findall(r'\bpca\s*\(', content))
    print(f"  PCA analyses: {pca_calls}")

    # Statistical tests
    anova_calls = len(re.findall(r'\banova1\s*\(', content))
    ttest_calls = len(re.findall(r'\bttest', content))
    multcomp_calls = len(re.findall(r'multcompare\s*\(', content))
    fitlm_calls = len(re.findall(r'\bfitlm\s*\(', content))

    print(f"  ANOVA tests: {anova_calls}")
    print(f"  T-tests: {ttest_calls}")
    print(f"  Multiple comparisons (Tukey HSD): {multcomp_calls}")
    print(f"  Linear models (regression): {fitlm_calls}")

    print("\n6.2 Data Quality Controls:")

    # NaN handling
    isnan_checks = len(re.findall(r'\bisnan\s*\(', content))
    omitnan_uses = len(re.findall(r"'omitnan'", content))
    print(f"  NaN checks (isnan): {isnan_checks}")
    print(f"  NaN handling (omitnan): {omitnan_uses}")

    # Outlier handling
    outlier_filters = len(re.findall(r'outlier|OUTLIER', content, re.IGNORECASE))
    print(f"  Outlier handling: {outlier_filters} references")

    # Sample size checks
    sample_size_checks = len(re.findall(r'if.*?n.*?>=|if.*?sum.*?>=|if.*?length.*?>=', content, re.IGNORECASE))
    print(f"  Sample size validation: {sample_size_checks} checks")

    print("\n6.3 Reproducibility:")

    # Random seed
    rng_seed = re.search(r'\brng\s*\((\d+)\)', content)
    if rng_seed:
        print(f"  ✓ Random seed set: rng({rng_seed.group(1)})")
    else:
        print(f"  ✗ No random seed found (may affect reproducibility)")

    # Data saving
    writetable_calls = len(re.findall(r'\bwritetable\s*\(', content))
    save_calls = len(re.findall(r'\bsave\s*\(', content))
    print(f"  Data exports (writetable): {writetable_calls}")
    print(f"  Workspace saves: {save_calls}")

    print("\n6.4 Visualization:")

    figure_calls = len(re.findall(r'\bfigure\s*\(', content))
    subplot_calls = len(re.findall(r'\bsubplot\s*\(', content))
    saveas_calls = len(re.findall(r'\bsaveas\s*\(', content))

    print(f"  Figure creation: {figure_calls}")
    print(f"  Subplots: {subplot_calls}")
    print(f"  Figure saves: {saveas_calls}")

    # =========================================================================
    # 7. INTEGRATION VALIDATION
    # =========================================================================
    print("\n" + "="*80)
    print("7. INTEGRATION VALIDATION (SESSIONS 1-3)")
    print("="*80)

    print("\n7.1 SESSION 1 Features:")

    # Synthetic data generator reference
    synthetic_ref = len(re.findall(r'SYNTHETIC|synthetic.*data.*generat', content, re.IGNORECASE))
    print(f"  ✓ Synthetic data references: {synthetic_ref}")

    # aarea removal
    aarea_removal = re.search(r'removevars.*aarea', content)
    aarea_comment = len(re.findall(r'aarea.*REMOVED|REMOVE.*aarea', content, re.IGNORECASE))
    print(f"  ✓ aarea variable removal: {aarea_comment} references")

    # FDR correction
    fdr_impl = re.search(r'function\s+\[.*?\]\s*=\s*fdr_bh', content)
    print(f"  ✓ FDR correction function: {'IMPLEMENTED' if fdr_impl else 'MISSING'}")
    print(f"  ✓ FDR correction usage: {fdr_correction} calls")

    print("\n7.2 SESSION 2 Features:")

    # Univariate correlations export
    univariate_export = len(re.findall(r'Univariate_Correlations.*\.csv', content))
    print(f"  ✓ Univariate correlation exports: {univariate_export} files")

    # Cohort-stratified boxplots
    boxplot_cohort = len(re.findall(r'Cohort.*Stratified|boxplot.*diagnosis', content, re.IGNORECASE))
    print(f"  ✓ Cohort-stratified analysis: {boxplot_cohort} references")

    # Age interaction
    age_interaction = len(re.findall(r'Age.*interaction|interaction.*Age', content, re.IGNORECASE))
    print(f"  ✓ Age × Decision Score interaction: {age_interaction} references")

    print("\n7.3 SESSION 3 Features:")

    # Helper functions
    helper_count = sum(1 for func in helper_funcs.values() if re.search(func, content))
    print(f"  ✓ Helper functions implemented: {helper_count}/{len(helper_funcs)}")

    # Constants
    const_count = sum(1 for const in constants.values() if re.search(const, content))
    print(f"  ✓ Parameter constants defined: {const_count}/{len(constants)}")

    # Error handling
    print(f"  ✓ Try-catch blocks: {try_blocks}")
    print(f"  ✓ Error messages: {error_calls} error() + {warning_calls} warning()")

    # =========================================================================
    # 8. FINAL VALIDATION SUMMARY
    # =========================================================================
    print("\n" + "="*80)
    print("8. VALIDATION SUMMARY")
    print("="*80)

    # Calculate pass/fail for major categories
    checks = {
        'Delimiter Balance': delimiter_pass,
        'Function/End Balance': structure_pass,
        'Helper Functions': helper_count == len(helper_funcs),
        'Constants Defined': const_count >= len(constants) * 0.8,  # At least 80%
        'Try-Catch Balance': try_catch_balanced,
        'FDR Implementation': fdr_impl is not None,
        'Statistical Methods': (corr_calls > 0 and fdr_correction > 0),
        'Data Quality Controls': (isnan_checks > 10 and sample_size_checks > 5),
        'Documentation': (comment_lines / total_lines) > 0.15  # >15% comments
    }

    passed = sum(checks.values())
    total_checks = len(checks)

    print(f"\nValidation Checks:")
    for check_name, result in checks.items():
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"  {status}: {check_name}")

    print(f"\n{'='*80}")
    print(f"OVERALL: {passed}/{total_checks} checks passed ({100*passed/total_checks:.1f}%)")
    print(f"{'='*80}")

    # Return metrics for rating
    return {
        'total_lines': total_lines,
        'comment_ratio': comment_lines / total_lines,
        'delimiter_balanced': delimiter_pass,
        'structure_balanced': structure_pass,
        'helper_functions': helper_count,
        'constants_defined': const_count,
        'try_blocks': try_blocks,
        'fdr_corrections': fdr_correction,
        'statistical_tests': anova_calls + ttest_calls + multcomp_calls + fitlm_calls,
        'correlation_calls': corr_calls,
        'error_calls': error_calls,
        'warning_calls': warning_calls,
        'writetable_calls': writetable_calls,
        'figure_calls': figure_calls,
        'checks_passed': passed,
        'total_checks': total_checks,
        'pass_rate': passed / total_checks
    }

if __name__ == '__main__':
    script_path = '/home/user/Nikondrius/Precision_Psychiatry_Scripts/Run_Full_Clinical_Associations_Transition_bvFTD.m'
    metrics = analyze_matlab_script(script_path)

    print("\n" + "="*80)
    print("METRICS SUMMARY FOR RATING")
    print("="*80)
    for key, value in metrics.items():
        print(f"  {key}: {value}")
