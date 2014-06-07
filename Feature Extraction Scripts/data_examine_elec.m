clear; close all;

%% load file
fid = fopen('.\sensor_data\Power.csv');
fmt = '%f%f%f%f%f%f%f%f';
M = textscan(fid,fmt,'Delimiter',','); % ,'Headerlines',1
fid = fclose(fid);

% time
time_stamp = [M{1} M{2} M{3} M{4} M{5} M{6}]; % year mon day hour min sec
data_name = 'RealPow';
data_name2 = 'ReactPow';

react = real(M{8});
real = M{7}; 

% unique days in the dataset
uni_day = unique(time_stamp(:,1:3), 'rows')

n_uni_day = length(uni_day)


%% points to use for clustering
day_to_use = [23 24 25 26 29 31];
n_day_to_use = length(day_to_use);

n = length(real);

time_range = [];
real_trun = [];
react_trun = [];

% find corresponding range
for i = 1:n_day_to_use
%     day_start = find(time_stamp(:,3) == day_to_use(1),1,'first');
%     day_end = find(time_stamp(:,3) == day_to_use(end),1,'last');
%     range = (day_start:day_end).';
    cur_idx = time_stamp(:,3) == day_to_use(i);
    time_range = [time_range; time_stamp(cur_idx,:)];
    real_trun = [real_trun; real(cur_idx)];
    react_trun = [react_trun; react(cur_idx)];
end

power_trun = [real_trun react_trun];

num_date = datenum(time_range);
%% time series
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)/4 scrsz(4)/4 scrsz(3)/1.5 scrsz(3)/4]);
plot(num_date, real_trun + 1e4, 'color', rgb('gray'));
hold on
plot(num_date, react_trun, 'color', rgb('blue'));
xlabel('Time (day)', 'fontsize', 20);
ylabel('Power (kW/kVAR)', 'fontsize', 20);
legend('Real power', 'Reactive power'); % , 'orientation', 'horizontal');
set(gca, 'fontsize', 19);
datetick; % ('x','keeplimits');
xlim([min(num_date)-1e-4 max(num_date)+1e-4]);

%% read in processed ground truth label
resol = 1;
b = load(['processed_ground_truth_resol_' num2str(resol) '.mat']);

label_time_vec = b.frame_time_stamp;
label_num = b.label_num;

%% assign label for points
assigned_label = [];
for i = 1:n_day_to_use
    for hh = 0:23
        for mm = 0:1:59
           label_idx = (label_time_vec(:,3) == day_to_use(i) & label_time_vec(:,4) == hh & label_time_vec(:,5) == mm);
           cur_inst_idx = (time_stamp(:,3) == day_to_use(i) & time_stamp(:,4) == hh & time_stamp(:,5) >= mm & time_stamp(:,5)< mm+resol);
           n_inst = sum(cur_inst_idx);
           assigned_label = [assigned_label; label_num(label_idx)*ones(n_inst, 1)];
        end
    end
end

%% scatter plot with 4 colors to differentiate different occupancy status
% scrsz(3) - width; scrsz(4) - height
figure('Position',[scrsz(3)/4 scrsz(4)/4 scrsz(3)/1.5 scrsz(3)/4]);

idx0 = (assigned_label == 0); idx1 = (assigned_label == 1);
idx2 = (assigned_label == 2); idx3 = (assigned_label == 3);
plot(real_trun(idx0), react_trun(idx0), 'go', real_trun(idx1), react_trun(idx1), 'b*', ...
         real_trun(idx2), react_trun(idx2), 'cv', real_trun(idx3), react_trun(idx3), 'm+', 'linewidth', 1.5);
xlabel('Real power (W)', 'fontsize', 20);
ylabel('Reactive power (VAR)', 'fontsize', 20);
legend('0 occupant', '1', '2', '3', 'orientation', 'horizontal');
% xlim([1.2 4]); ylim([0.8 2.6])
set(gca, 'fontsize', 20); % , 'XTick', [1.2 1.5:0.5:4]

%% change resolution
% revise resol can change the num of uni values
resol = 5;
real_trun_round = round(real_trun/resol)*resol;
uni_real_trun_round = unique(real_trun_round);

react_trun_round = round(react_trun/resol)*resol;
uni_react_trun_round = unique(react_trun_round);

power = [real_trun_round react_trun_round];
% still too many unique values - bin them

% [C,ia,ic]= unique(A,'rows') also returns index vectors ia and ic, such that C= A(ia,:) and A = C(ic,:).
[uni_power, ia, ic] = unique(power, 'rows');
n_uni_power = size(uni_power, 1);        
       
power_sample = uni_power;
n_inst = size(real_trun,1);
n_sample = size(power_sample, 1);

%% sampling
% sample_rate = 0.01;
% n_inst = size(real_trun,1);
% n_sample = round(sample_rate*n_inst);
% idx_perm = randperm(n_inst);
% idx_sample = idx_perm(1:n_sample);
% real_sample = real_trun(idx_sample);
% react_sample = react_trun(idx_sample);
% 
% power_sample = [real_sample react_sample];

%% clustering
n_dim = 2;
% real power
Y = pdist(power_sample, 'mahalanobis');
Z = linkage(Y, 'average'); % 'average', 'complete'
dendrogram(Z);
c = cophenet(Z,Y)

%  = inconsistent(Z)
%%
cutoff = 1.5;

T = cluster(Z,'cutoff',cutoff,'criterion','distance');

n_cluster = length(unique(T));

% calculate cluster centers
cluster_center = zeros(n_cluster, n_dim);
n_ele_per_cluster = zeros(n_cluster, 1);
for i = 1:n_cluster
    cur_idx = (T == i);
    n_ele_per_cluster(i) = sum(cur_idx);
    cluster_center(i,:) = mean(power_sample(cur_idx,:), 1);
end

% a cluster is valid only if the num of ele in it is larger than 5
retain_cluster_idx = find(n_ele_per_cluster >= 1);
retain_n_cluster = length(retain_cluster_idx);
retain_cluster_center = cluster_center(retain_cluster_idx, :);
retain_n_ele_per_cluster = n_ele_per_cluster(retain_cluster_idx);

% visualize all the data and cluster centers
my_color = {'bo', 'rx', 'c*', 'm>', 'bd', 'y+', 'rx', 'gv', 'm*', 'bs', 'c+', 'cv', 'go', 'yx', 'g*', 'g>', 'yd', 'y+', 'bx', 'rv', 'm*', 'ms', 'c+', 'yv', ...
                        'bo', 'rx', 'c*', 'm>', 'bd', 'y+', 'rx', 'gv', 'm*', 'bs', 'c+', 'cv', 'go', 'yx', 'g*', 'g>', 'yd', 'y+', 'bx', 'rv', 'm*', 'ms', 'c+', 'yv'};
my_color2 = {'ko', 'kx', 'k*', 'k>', 'kd', 'k+', 'kx', 'kv', 'k*', 'ks', 'k+', 'kv', 'ko', 'kx', 'k*', 'k>', 'kd', 'k+', 'kx', 'kv', 'k*', 'ks', 'k+', 'kv'};
scrsz = get(0,'ScreenSize');
% scrsz(3) - width; scrsz(4) - height
figure('Position',[scrsz(3)/4 scrsz(4)/4 scrsz(3)/1.5 scrsz(3)/4]);
h = 0;
hold on
for i = 1:n_cluster
    % only plot retained clusters
    if ismember(i, retain_cluster_idx)
        h = h+1;
        cur_idx = (T == i);
        plot(power_sample(cur_idx,1), power_sample(cur_idx,2), my_color{h}, 'linewidth', 1.5);
        plot(cluster_center(i,1), cluster_center(i,2), my_color2{h}, 'markersize', 14);
        text(cluster_center(i,1) + 0.02, cluster_center(i,2), num2str(h), 'fontsize', 20);
    end
end
hold off

xlabel('Real power (W)', 'fontsize', 20);
ylabel('Reactive power (VAR)', 'fontsize', 20);
set(gca, 'fontsize', 20);

%% decomposition
% use the sample cov
S = nancov(power_trun);
% add in a dummy center [0,0] - once a cluster index becomes 1, terminate
retain_cluster_center_aug = [0 0; retain_cluster_center];
retain_n_cluster_aug = retain_n_cluster + 1;

% for each point, find the closest cluster center
% deduct it and then find the next one until the cluster index becomes 1
cluster_member_mat = zeros(n_inst, retain_n_cluster_aug);
residual_mat = zeros(n_inst, n_dim);

for i = 1:n_inst
    dis = inf*ones(retain_n_cluster_aug, 1);
    cur_in = power_trun(i,:);
    h = 0;
    while cluster_member_mat(i,1) == 0 && h == 0% the first cluster has not been allocated yet
        for j = 1:retain_n_cluster_aug
            if cluster_member_mat(i,j) == 0 % not yet allocated
                x = cur_in - retain_cluster_center_aug(j,:);
                dis(j) = sqrt(x*(S\x.'));
            end
        end
        idx_min = find(dis == min(dis), 1, 'first');
        cluster_member_mat(i, idx_min) = 1;
        
        h = 1;
                
        % update the input, deduct the assigned cluster center
        cur_in = cur_in - retain_cluster_center_aug(idx_min,:);
        if idx_min == 1
            residual_mat(i,:) = cur_in;
        end
    end
end

%% map uni_power to original power
cluster_member_mat_ori = cluster_member_mat;

%% plot out all the decoupled clusters
my_color_stair = {'b', 'r', 'c', 'm', 'b', 'y', 'r', 'g', 'm', 'b', 'c', 'c', 'g', 'y', 'g', 'g', 'y', 'y', 'b', 'r', 'm', 'm', 'c', 'y'};
% {'g', 'r', 'c', 'g', 'c', 'y', 'b', 'c', 'g', 'm', 'g', 'r', 'm', 'c', 'm', 'y', 'b', 'b', 'g', 'b'};
n_plot = retain_n_cluster;
for i = 1:n_plot
    % subplot(n_plot, 1, i);
    figure('Position',[scrsz(3)/4 scrsz(4)/4 scrsz(3)/1.5 scrsz(3)/7]);
    stairs(num_date, cluster_member_mat_ori(:, i+1), my_color_stair{i}, 'linewidth', 1); % no need to plot the first col - it corresponds to 0
    % xlabel('Time (day)', 'fontsize', 20);
    ylabel(['Cluster ' num2str(i)], 'fontsize', 20);
    set(gca, 'xtick', 0:2:24, 'ytick', 0:1, 'fontsize', 20);
    datetick;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% after clustering, compute the distance to each cluster center and represent each inst as a vector wrt cluster centers
cluster_dis_mat = zeros(n_inst, retain_n_cluster);

for i = 1:n_inst
    cur_in = power_trun(i,:);
        for j = 1:retain_n_cluster
                x = cur_in - retain_cluster_center(j,:);
                cluster_dis_mat(i,j) = sqrt(x*(S\x.'));
        end
end

std_dis = std(cluster_dis_mat(:))

% convert dis mat to weight mat
cluster_weight_mat = exp(-cluster_dis_mat/std_dis);
norm_cluster_weight_mat = prob_mat_nlz(cluster_weight_mat, 'row');

% transform back to correspond to raw data
norm_cluster_weight_mat_ori = norm_cluster_weight_mat;

% %% construct docs (frames)
% [feature_mat2, n_inst2, n_feature2, feature_name2] = stream_data_frame_sum(norm_cluster_weight_mat_ori, win_size, offset, thre_rms);

save(['cluster_para_' data_name '.mat'], 'retain_cluster_center', 'S', 'std_dis');
