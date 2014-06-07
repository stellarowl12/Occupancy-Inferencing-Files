clear;
%% read in original ground truth labels
filename = '.\sensor_data\Occ.csv';

fid = fopen(filename);
fmt = '%f%f%f%f%f%f%f';
M = textscan(fid,fmt,'Delimiter',',','EmptyValue', 0);
fid = fclose(fid);

% assign data to variables
year = M{1};mon = M{2};day = M{3};hh = M{4};mm = M{5};ss = M{6};num = M{7};

% time vec
time_stamp = [year mon day hh mm ss];
% unique days
uni_day = unique(day);

save('ground_truth.mat', 'time_stamp', 'num');
