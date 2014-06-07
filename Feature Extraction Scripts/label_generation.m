clear;

% discretize the ground truth label

%% read in the ground truth label
a = load('ground_truth.mat');

time_stamp = a.time_stamp;
num = a.num; % num in [0, 1, 2, 3]

%% resolution of ground truth label
resol = 5; % minute
[frame_time_stamp, label_num] = transform_epoch_label_to_frame_label(time_stamp, num, resol);

save(['processed_ground_truth_resol_' num2str(resol) '.mat'], 'frame_time_stamp', 'label_num');
