function z = my_continuous_entropy(x)
% each row of x is a data vector - inst
% Note: x is a data vector like [1 2 3 2 3] not a PMF; if x is already a PMF,
% use the last line of this function instead
% entropy is calculated along each column - feature

% Compute entropy H(x) of a discrete variable x.
% Written by Mo Chen (mochen80@gmail.com).

n_col = size(x, 2);
if n_col == 1 
    z = myentropy1(x);
else
    z = zeros(1, n_col);
    for i = 1:n_col
        z(i) = myentropy1(x(:,i));        
    end
end

function z1 = myentropy1(x)
% for a single col vector
    nbins = 20;
    eps = 1e-6;
    n = numel(x);
    x = reshape(x,1,n);
    count = hist(x, nbins);
    % probability
    p = count/sum(count);
    z1 = -dot(p,log2(p+eps));