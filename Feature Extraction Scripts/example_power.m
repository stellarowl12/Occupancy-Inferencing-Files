clear;
close all

%% load file
fid = fopen('.\sensor_data\Power.csv');
fmt = '%f%f%f%f%f%f%f%f';
M = textscan(fid,fmt,'Delimiter',','); % ,'Headerlines',1
fid = fclose(fid);

resol = 1;

% time
time_vec = [M{1} M{2} M{3} M{4} M{5} M{6}]; % year mon day hour min sec
data_name = 'RealPow';
data_name2 = 'ReactPow';

data = M{7};
data2 = real(M{8});

% unique days in the dataset
uni_day = unique(time_vec(:,1:3), 'rows')

n_uni_day = length(uni_day)

% -- you need to manually provide this as the input
day_of_week = [2 3 4 5 1 3 4 5 5];

% window size for feature extraction in terms of minutes - non-overlapping windows
win_size = resol;
offset = win_size;
% sampling rate - for freq domain features
fs = 1;
% threshold on std of the signal inside a window for admission control
thre_std = 0;

% record the features
output_feature_mat = [];
output_label_num = [];
% output_day_of_week = [];
% output_time_of_day = [];
% output_min_of_hour = [];
% output_day = [];
output_time_stamp = [];

%% read in processed ground truth label
b = load(['processed_ground_truth_resol_' num2str(resol) '.mat']);

label_time_vec = b.frame_time_stamp;
label_num = b.label_num;

class_name = 'label_num';

%% parameters for clustering

cc = load('cluster_para_Power.mat');
cluster_center = cc.retain_cluster_center;
std_dis = cc.std_dis;
S_cov = cc.S;

%% extract features for data on each day
for i = 1:n_uni_day
    % find samples corresponding to current day
    cur_idx = ismember(time_vec(:,1:3),uni_day(i,:), 'rows');    
    cur_time_vec = time_vec(cur_idx,:);    
    
    %% stat feature
    cur_data = data(cur_idx,:);
    [feature_day_of_week, feature_time_of_day, feature_min_of_hour, feature_min_of_day, feature_mat, feature_n_sample, feature_name] = ...
    stream_feature_extraction_1d(day_of_week(i), data_name, cur_data, cur_time_vec, win_size, fs, thre_std);
    
    cur_data2 = data2(cur_idx,:);
    [~, feature_time_of_day2, feature_min_of_hour2, ~, feature_mat2, ~, feature_name2] = ...
    stream_feature_extraction_1d(day_of_week(i), data_name2, cur_data2, cur_time_vec, win_size, fs, thre_std);

    %% cluster feature
    [~, feature_time_of_day_cluster, feature_min_of_hour_cluster, feature_mat_cluster, ~, ~, n_feature_cluster, feature_name_cluster] = ...
    stream_feature_extraction_cluster(day_of_week(i), 'Power', [cur_data cur_data2], cur_time_vec, win_size, offset, fs, ...
    thre_std, cluster_center, std_dis, S_cov, 'hard');

    % concatenate the features over different days
    output_feature_mat = [output_feature_mat; feature_day_of_week feature_time_of_day feature_mat feature_mat2 feature_mat_cluster];

    %% time
    n_inst = size(feature_time_of_day,1);
    feature_day = uni_day(i,3)*ones(n_inst, 1);
%     output_day = [output_day; feature_day];
    cur_time_stamp = [feature_day feature_time_of_day feature_min_of_hour];
    
    output_time_stamp = [output_time_stamp; cur_time_stamp];
    
    %% find out samples corresponding to which time windows are extracted
    plot_range = ismember(label_time_vec(:,3:5),cur_time_stamp, 'rows');
    output_label_num = [output_label_num; label_num(plot_range)];
    
end

%% check NaN and Inf
output_feature_mat(isnan(output_feature_mat))=0;
output_feature_mat(isinf(output_feature_mat))=0;

output_feature_name = ['DayOfWeek', 'HourOfDay', feature_name, feature_name2, feature_name_cluster];

%% filter out consistent terms
feature_mean = output_feature_mat(:,3);
idx_mal = (feature_mean - [0; feature_mean(1:end-1)] == 0);

output_feature_mat = output_feature_mat(~idx_mal,:);
output_label_num = output_label_num(~idx_mal);
output_time_stamp = output_time_stamp(~idx_mal,:);

save(['occ_' data_name '_' num2str(resol) 'min.mat'], 'output_feature_mat', 'output_feature_name', 'output_label_num', 'class_name', 'output_time_stamp');

%% 
class_idx = 1;
wekaOBJ = matlab2weka(['occ_' data_name], [output_feature_name class_name], ...
[output_feature_mat output_label_num], class_idx);
% save to arff
saveARFF(['occ_' data_name '_' num2str(resol) 'min.arff'], wekaOBJ);
