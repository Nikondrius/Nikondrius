function [h, crit_p, adj_p] = fdr_bh(pvals, q)
    % BENJAMINI-HOCHBERG FDR CORRECTION
    % Implements the Benjamini-Hochberg procedure for controlling
    % False Discovery Rate in multiple hypothesis testing
    %
    % INPUTS:
    %   pvals - vector of p-values to correct
    %   q     - desired FDR level (default: 0.05)
    %
    % OUTPUTS:
    %   h       - binary vector of significance flags (1=significant, 0=not)
    %   crit_p  - critical p-value threshold
    %   adj_p   - FDR-adjusted p-values (q-values)
    %
    % REFERENCE:
    %   Benjamini, Y. & Hochberg, Y. (1995). Controlling the false discovery
    %   rate: A practical and powerful approach to multiple testing.
    %   Journal of the Royal Statistical Society, Series B, 57(1), 289-300.
    %
    % Author: Claude AI Assistant
    % Date: November 8, 2025

    if nargin < 2
        q = 0.05;
    end

    % Handle edge cases
    if isempty(pvals)
        h = [];
        crit_p = [];
        adj_p = [];
        return;
    end

    % Convert to column vector
    pvals = pvals(:);
    n = length(pvals);

    % Handle NaN values
    nan_mask = isnan(pvals);
    valid_pvals = pvals(~nan_mask);
    n_valid = length(valid_pvals);

    if n_valid == 0
        h = false(n, 1);
        crit_p = NaN;
        adj_p = NaN(n, 1);
        return;
    end

    % Sort p-values
    [sorted_pvals, sort_idx] = sort(valid_pvals);

    % Calculate BH threshold for each rank
    % P(i) <= (i/m) * q
    ranks = (1:n_valid)';
    bh_threshold = (ranks / n_valid) * q;

    % Find largest i where P(i) <= (i/m)*q
    significant_idx = find(sorted_pvals <= bh_threshold, 1, 'last');

    if isempty(significant_idx)
        crit_p = 0;
        h_valid = false(n_valid, 1);
    else
        crit_p = sorted_pvals(significant_idx);
        h_valid = sorted_pvals <= crit_p;
    end

    % Calculate adjusted p-values (q-values)
    % q(i) = min(1, min_{j>=i} (m/j) * P(j))
    adj_p_sorted = NaN(n_valid, 1);
    adj_p_sorted(n_valid) = sorted_pvals(n_valid);

    for i = (n_valid-1):-1:1
        adj_p_sorted(i) = min(1, min((n_valid / i) * sorted_pvals(i), adj_p_sorted(i+1)));
    end

    % Unsort to match original order
    h_unsorted = false(n_valid, 1);
    h_unsorted(sort_idx) = h_valid;

    adj_p_unsorted = NaN(n_valid, 1);
    adj_p_unsorted(sort_idx) = adj_p_sorted;

    % Insert NaN results back for invalid p-values
    h = false(n, 1);
    h(~nan_mask) = h_unsorted;

    adj_p = NaN(n, 1);
    adj_p(~nan_mask) = adj_p_unsorted;
end
