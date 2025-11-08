function result = ternary(condition, true_val, false_val)
    % TERNARY OPERATOR - inline conditional value selection
    % Simplified if-else for value assignment
    %
    % INPUTS:
    %   condition - Logical condition to evaluate
    %   true_val  - Value to return if condition is true
    %   false_val - Value to return if condition is false
    %
    % OUTPUT:
    %   result - Either true_val or false_val

    if condition
        result = true_val;
    else
        result = false_val;
    end
end
