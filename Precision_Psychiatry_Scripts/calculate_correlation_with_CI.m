function [r, CI, p, n_valid] = calculate_correlation_with_CI(x, y, alpha)
    % CALCULATE PEARSON CORRELATION WITH FISHER'S Z CONFIDENCE INTERVAL
    %
    % Computes Pearson correlation coefficient and confidence interval using
    % Fisher's Z transformation for improved accuracy with small samples
    %
    % INPUTS:
    %   x       - First variable (numeric vector)
    %   y       - Second variable (numeric vector)
    %   alpha   - Significance level for CI (default: 0.05 for 95% CI)
    %
    % OUTPUTS:
    %   r       - Pearson correlation coefficient
    %   CI      - Confidence interval [lower, upper]
    %   p       - Two-tailed p-value
    %   n_valid - Number of valid pairs (after removing NaN)
    %
    % METHOD:
    %   Fisher's Z transformation: z = atanh(r)
    %   SE(z) = 1/sqrt(n-3)
    %   CI(z) = z ± z_critical * SE(z)
    %   Back-transform: CI(r) = tanh(CI(z))
    %
    % REFERENCE:
    %   Fisher, R.A. (1915). Frequency distribution of the values of the
    %   correlation coefficient in samples from an indefinitely large population.
    %   Biometrika, 10(4), 507-521.
    %
    % Author: Claude AI Assistant (SESSION 3)
    % Date: November 8, 2025

    if nargin < 3
        alpha = 0.05;
    end

    % Remove NaN values (pairwise deletion)
    valid_idx = ~isnan(x) & ~isnan(y);
    x_clean = x(valid_idx);
    y_clean = y(valid_idx);
    n_valid = length(x_clean);

    % Handle edge cases
    if n_valid < 3
        r = NaN;
        CI = [NaN, NaN];
        p = NaN;
        return;
    end

    % Calculate Pearson correlation
    [r, p] = corr(x_clean, y_clean);

    % Fisher's Z transformation for CI
    if abs(r) >= 1
        % Perfect correlation - CI is undefined
        CI = [r, r];
    else
        z_crit = norminv(1 - alpha/2);  % Two-tailed critical value
        z_r = atanh(r);                 % Fisher's Z transform
        se_z = 1 / sqrt(n_valid - 3);   % Standard error of Z

        % CI in Z space
        z_lower = z_r - z_crit * se_z;
        z_upper = z_r + z_crit * se_z;

        % Back-transform to correlation space
        CI = [tanh(z_lower), tanh(z_upper)];
    end
end
