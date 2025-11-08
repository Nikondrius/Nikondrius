function cmap = redblue(m)
    % REDBLUE COLORMAP
    % Creates a blue-white-red diverging colormap for correlation matrices
    % Blue represents negative correlations, red represents positive
    %
    % INPUT:
    %   m - Number of colors (default: current figure colormap length)
    %
    % OUTPUT:
    %   cmap - m×3 RGB colormap matrix

    if nargin < 1
        m = size(get(gcf,'colormap'),1);
    end

    if mod(m,2) == 0
        m1 = m/2;
        r = [(0:m1-1)'/max(m1-1,1); ones(m1,1)];
        g = [(0:m1-1)'/max(m1-1,1); (m1-1:-1:0)'/max(m1-1,1)];
        b = [ones(m1,1); (m1-1:-1:0)'/max(m1-1,1)];
    else
        m1 = floor(m/2);
        r = [(0:m1-1)'/max(m1,1); ones(m-m1,1)];
        g = [(0:m1-1)'/max(m1,1); (m-m1-1:-1:0)'/max(m-m1-1,1)];
        b = [ones(m1,1); (m-m1-1:-1:0)'/max(m-m1-1,1)];
    end

    cmap = [r g b];
end
