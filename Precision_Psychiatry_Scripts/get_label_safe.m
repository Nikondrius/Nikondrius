function label = get_label_safe(varname, label_map)
    % SAFE LABEL GETTER WITH ERROR HANDLING
    % Retrieves human-readable label from variable_labels map with fallback
    %
    % INPUTS:
    %   varname   - Variable name (string or char)
    %   label_map - containers.Map with variable name → label mappings
    %
    % OUTPUT:
    %   label - Readable label (or original varname if not found)

    try
        if ischar(varname) || isstring(varname)
            varname = char(varname);
            if label_map.isKey(varname)
                label = label_map(varname);
            else
                label = varname;
            end
        else
            label = varname;
        end
    catch
        % If anything fails, just return the original variable name
        label = varname;
    end
end
