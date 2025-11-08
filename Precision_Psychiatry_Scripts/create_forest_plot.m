function fig = create_forest_plot(var_names, labels, correlations, CIs, p_vals, p_fdr, title_text, n_subjects, marker_color)
    % CREATE STANDARDIZED FOREST PLOT FOR CORRELATION RESULTS
    %
    % Generates a publication-ready forest plot showing correlations with
    % confidence intervals, with optional FDR significance markers
    %
    % INPUTS:
    %   var_names     - Cell array of variable names
    %   labels        - Cell array of interpretable labels for display
    %   correlations  - Vector of correlation coefficients (r values)
    %   CIs           - N×2 matrix of confidence intervals [lower, upper]
    %   p_vals        - Vector of uncorrected p-values
    %   p_fdr         - Vector of FDR-adjusted p-values (optional, [] if not available)
    %   title_text    - Plot title string
    %   n_subjects    - Vector of sample sizes per correlation
    %   marker_color  - RGB triplet for marker color (default: [0.2 0.4 0.8])
    %
    % OUTPUTS:
    %   fig          - Figure handle
    %
    % VISUAL ELEMENTS:
    %   - Horizontal error bars for 95% CI
    %   - Filled circles for correlation coefficients
    %   - Vertical reference line at r=0
    %   - FDR-significant results marked with **
    %   - Uncorrected significant results marked with *
    %
    % Author: Claude AI Assistant (SESSION 3)
    % Date: November 8, 2025

    if nargin < 9 || isempty(marker_color)
        marker_color = [0.2 0.4 0.8];  % Default blue
    end

    n_vars = length(var_names);

    % Create figure
    fig = figure('Position', [100 100 1000 max(400, 100 + 50*n_vars)]);
    hold on;

    y_pos = 1:n_vars;

    % Plot confidence intervals
    for i = 1:n_vars
        plot([CIs(i,1), CIs(i,2)], [y_pos(i), y_pos(i)], 'k-', 'LineWidth', 1.5);
    end

    % Plot correlation coefficients
    scatter(correlations, y_pos, 100, 'filled', 'MarkerFaceColor', marker_color);

    % Add significance markers to labels
    labels_with_sig = labels;
    for i = 1:n_vars
        if ~isempty(p_fdr) && ~isnan(p_fdr(i)) && p_fdr(i) < 0.05
            labels_with_sig{i} = [labels{i} ' **'];  % FDR significant
        elseif p_vals(i) < 0.05
            labels_with_sig{i} = [labels{i} ' *'];   % Uncorrected significant
        end
    end

    % Reference line at r=0
    plot([0 0], [0.5, n_vars+0.5], 'r--', 'LineWidth', 2);

    % Formatting
    set(gca, 'YTick', y_pos, 'YTickLabel', labels_with_sig, 'FontSize', 9);
    xlabel('Correlation (r) with 95% CI', 'FontWeight', 'bold', 'FontSize', 12);
    title(title_text, 'FontWeight', 'bold', 'FontSize', 14);

    % Dynamic x-axis limits
    xlim([min([CIs(:,1); -0.1])-0.1, max([CIs(:,2); 0.1])+0.1]);
    ylim([0.5, n_vars+0.5]);
    grid on;

    % Add legend for significance markers
    if ~isempty(p_fdr)
        text(0.98, 0.02, '* p<0.05   ** FDR q<0.05', ...
            'Units', 'normalized', 'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom', 'FontSize', 9, ...
            'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(0.98, 0.02, '* p<0.05', ...
            'Units', 'normalized', 'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom', 'FontSize', 9, ...
            'BackgroundColor', 'white', 'EdgeColor', 'black');
    end

    hold off;
end
