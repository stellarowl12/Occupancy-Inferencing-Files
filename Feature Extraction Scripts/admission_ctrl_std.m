function [sig_std, val] = admission_ctrl_std(signal, thre_std)
% accept matrix input; each row of the signal is an instance; each column is a dim

% calculate the std for each dim
sig_std = std(signal);
% logical output - will be a vector is the input is a matrix
val = (sig_std >= thre_std);
