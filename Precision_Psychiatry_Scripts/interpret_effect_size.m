function effect_label = interpret_effect_size(r, type)
    % INTERPRET EFFECT SIZE MAGNITUDE
    %
    % Provides standardized interpretation of effect sizes following Cohen's conventions.
    % This helps translate statistical significance into practical significance.
    %
    % INPUTS:
    %   r    - Effect size (correlation coefficient for 'r', Cohen's d for 'd')
    %   type - 'r' for correlations, 'd' for Cohen's d (default: 'r')
    %
    % OUTPUTS:
    %   effect_label - String describing effect magnitude:
    %                  'negligible', 'small', 'medium', 'large', 'very large'
    %
    % THRESHOLDS (Cohen, 1988):
    %   Correlations (r): small=0.10, medium=0.30, large=0.50
    %   Cohen's d:        small=0.20, medium=0.50, large=0.80
    %
    % REFERENCE:
    %   Cohen, J. (1988). Statistical Power Analysis for the Behavioral Sciences (2nd ed.).
    %   Hillsdale, NJ: Lawrence Erlbaum Associates.
    %
    % Author: Claude AI Assistant
    % Date: November 8, 2025

    if nargin < 2
        type = 'r';  % Default to correlation
    end

    abs_r = abs(r);  % Use absolute value for magnitude interpretation

    if strcmpi(type, 'r')
        % Correlation thresholds
        if abs_r < 0.10
            effect_label = 'negligible';
        elseif abs_r < 0.30
            effect_label = 'small';
        elseif abs_r < 0.50
            effect_label = 'medium';
        elseif abs_r < 0.70
            effect_label = 'large';
        else
            effect_label = 'very large';
        end
    elseif strcmpi(type, 'd')
        % Cohen's d thresholds
        if abs_r < 0.20
            effect_label = 'negligible';
        elseif abs_r < 0.50
            effect_label = 'small';
        elseif abs_r < 0.80
            effect_label = 'medium';
        else
            effect_label = 'large';
        end
    else
        error('Unknown effect size type: %s. Use ''r'' or ''d''.', type);
    end
end
