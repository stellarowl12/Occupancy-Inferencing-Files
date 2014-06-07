clear;

close all

resol = 5;
date_elec = ['occ_Power_' num2str(resol) 'min.mat'];
date_water = ['occ_Water_' num2str(resol) 'min.mat'];
date = date_elec;

hour_of_interest = [6 24];

n_common_feature = 2;
idx_stat_feature_power = 3:34;
idx_cluster_feature_power = 35:53;
n_feature_power = 53;

% the overall position of net features
idx_stat_feature_water = (3:18) + n_feature_power - n_common_feature;
idx_cluster_feature_water = (19:27) + n_feature_power - n_common_feature;

output_time_stamp = [];
output_feature_mat = [];
output_label_num = [];

    a = load(date_elec);
    n_inst_a = length(a.output_label_num);
    
    cur_feature_mat_elec = a.output_feature_mat;
    cur_time_stamp_elec = a.output_time_stamp;
    cur_label_num_elec = a.output_label_num;
    
    b = load(date_water);
    
    cur_feature_mat_water = b.output_feature_mat;
    cur_time_stamp_water = b.output_time_stamp;
    cur_label_num_water = b.output_label_num;
    
    %% find the difference
    % delete rows not in the two matrices
    [C_elec,ia_elec]= setdiff(cur_time_stamp_elec,cur_time_stamp_water,'rows'); % in elec not in net
    [C_net,ia_net] = setdiff(cur_time_stamp_water,cur_time_stamp_elec,'rows'); % in net not in elec

    % update
    cur_time_stamp_elec(ia_elec,:) = [];
    cur_feature_mat_elec(ia_elec,:) = [];
    cur_label_num_elec(ia_elec,:) = [];

    % update
    cur_time_stamp_water(ia_net,:) = [];
    cur_feature_mat_water(ia_net,:) = [];
    cur_label_num_water(ia_net,:) = [];

   
    % output % you need only one time stamp
    output_time_stamp = [output_time_stamp; cur_time_stamp_elec];
    % you need to horizontally stack the features from both elec and network
    output_feature_mat = [output_feature_mat; [cur_feature_mat_elec cur_feature_mat_water(:,3:end)]];
    % you do not need to stack labels
    output_label_num = [output_label_num; cur_label_num_elec];

output_feature_name = [a.output_feature_name b.output_feature_name(3:end)];
class_name = a.class_name;

n_total = length(output_label_num);

%% check NaN and Inf
output_feature_mat(isnan(output_feature_mat))=0;
output_feature_mat(isinf(output_feature_mat))=0;

% %% cluster features
% cluster_feature_power = output_feature_mat(:, idx_cluster_feature_power);
% cluster_feature_water = output_feature_mat(:, idx_cluster_feature_water);
% 
% % transform cluster count to tfidf
%     % transform count to TFIDF
%     cluster_feature_power_tfidf = tfidf(cluster_feature_power);
%     cluster_feature_water_tfidf = tfidf(cluster_feature_water);
%     
%     % update the feature mat
%     output_feature_mat(:, idx_cluster_feature_power) = cluster_feature_power_tfidf;
%     output_feature_mat(:, idx_cluster_feature_water) = cluster_feature_water_tfidf;

%% remove zero columns
col_range = range(output_feature_mat);
% retain_col = ~(col_range <= 1e-6);
n_nonzero = sum(output_feature_mat > 0);
retain_col = (n_nonzero > 2);

% record the original feature mat and name for backup
ori_mat = output_feature_mat;
ori_name = output_feature_name;
% update
output_feature_mat = output_feature_mat(:,retain_col);
output_feature_name = output_feature_name(retain_col);

% %% normalization and remove zero values
% [output_feature_mat, retain_col] = datascale(output_feature_mat);
% output_feature_name = output_feature_name(retain_col);
% n_dim = sum(retain_col);

%% save
save(['occ_home_' num2str(resol) 'min.mat'], 'output_feature_mat', 'output_feature_name', 'output_label_num', 'class_name', 'output_time_stamp');

%% 
class_idx = 1;
wekaOBJ = matlab2weka('occ_all', [output_feature_name class_name], ...
[output_feature_mat output_label_num], class_idx);
% save to arff
saveARFF(['occ_home_' num2str(resol) 'min.arff'], wekaOBJ);
