function output = tfidf(input)

n_inst = size(input, 1);
% n_dim = size(input, 2);

binary_input = (input > 0);

n_nonzero_inst_per_dim = sum(binary_input);

% TF
TF = prob_mat_nlz(input, 'row');

% IDF
IDF = log(n_inst./n_nonzero_inst_per_dim);
IDF = repmat(IDF, n_inst, 1);

output = TF.*IDF;
% scale = 1/max(output(:));
% output = scale*output;


