clear; close all;

%% load file
fid = fopen('.\sensor_data\Water.csv');
fmt = '%f%f%f%f%f%f%f';
M = textscan(fid,fmt,'Delimiter',','); % ,'Headerlines',1
fid = fclose(fid);

% time
time_stamp = [M{1} M{2} M{3} M{4} M{5} M{6}]; % year mon day hour min sec
data_name = 'Water';

water = M{7};

% unique days in the dataset
uni_day = unique(time_stamp(:,1:3), 'rows')

n_uni_day = length(uni_day)

%% points to use for clustering
day_to_use = [23 24 25 26 29 31];
n_day_to_use = length(day_to_use);

n = length(water);

time_range = [];
water_trun = [];

% find corresponding range
for i = 1:n_day_to_use
    cur_idx = time_stamp(:,3) == day_to_use(i);
    time_range = [time_range; time_stamp(cur_idx,:)];
    water_trun = [water_trun; water(cur_idx)];
end

num_date = datenum(time_range);

%%
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)/4 scrsz(4)/4 scrsz(3)/1.5 scrsz(3)/4]);
plot(num_date, water_trun, 'color', rgb('gray'));
xlabel('Time (day)', 'fontsize', 20);
ylabel('Water', 'fontsize', 20);
legend('Water'); % , 'orientation', 'horizontal');
set(gca, 'fontsize', 19);
datetick; % ('x','keeplimits');
xlim([min(num_date)-1e-4 max(num_date)+1e-4]);

%% scatter plot
figure;
plot(water_trun, water_trun, 'bx');

%% change resolution
% % revise resol can change the num of uni values
% resol = 0.5;
% water_trun_round = round(water_trun/resol)*resol;
% 
% % [C,ia,ic]= unique(A,'rows') also returns index vectors ia and ic, such that C= A(ia,:) and A = C(ic,:).
% [uni_water, ia, ic] = unique(water_trun_round, 'rows');
% n_uni_water = size(uni_water, 1);       
                

%% sampling
sample_rate = 0.1;
n_inst = size(water_trun,1);
n_sample = round(sample_rate*n_inst);
idx_perm = randperm(n_inst);
idx_sample = idx_perm(1:n_sample);
water_sample = water_trun(idx_sample);

%% k-means clustering
% K = 8;
% T = kmeans(water_sample,K,'distance','cityblock');
% 
% [silh,~] = silhouette(water_sample,T,'cityblock');
% set(get(gca,'Children'),'FaceColor',[.8 .8 1])
% xlabel('Silhouette Value')
% ylabel('Cluster')
% 
% mean(silh)

%% hierarchical clustering
n_dim = 1;
% real power
Y = pdist(water_sample, 'cityblock');
Z = linkage(Y, 'average'); % 'average', 'complete'
dendrogram(Z);
c = cophenet(Z,Y)

%% cut off
cutoff = 50;

T = cluster(Z,'cutoff',cutoff,'criterion','distance');

%% 
n_cluster = length(unique(T));

% calculate cluster centers
cluster_center = zeros(n_cluster, n_dim);
n_ele_per_cluster = zeros(n_cluster, 1);
for i = 1:n_cluster
    cur_idx = (T == i);
    n_ele_per_cluster(i) = sum(cur_idx);
    cluster_center(i,:) = mean(water_sample(cur_idx,:), 1);
end

% a cluster is valid only if the num of ele in it is larger than 5
retain_cluster_idx = find(n_ele_per_cluster >= 3);
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
        plot(water_sample(cur_idx,1), water_sample(cur_idx,1), my_color{h}, 'linewidth', 1.5);
        plot(cluster_center(i,1), cluster_center(i,1), my_color2{h}, 'markersize', 14);
        text(cluster_center(i,1) + 0.02, cluster_center(i,1), num2str(h), 'fontsize', 20);
    end
end
hold off

xlabel('Water', 'fontsize', 20);
ylabel('Water', 'fontsize', 20);
set(gca, 'fontsize', 20);

%% decomposition
% use the sample cov
S = nancov(water_trun);
% add in a dummy center [0,0] - once a cluster index becomes 1, terminate
retain_cluster_center_aug = [0; retain_cluster_center];
retain_n_cluster_aug = retain_n_cluster + 1;

% for each point, find the closest cluster center
% deduct it and then find the next one until the cluster index becomes 1
cluster_member_mat = zeros(n_inst, retain_n_cluster_aug);
residual_mat = zeros(n_inst, n_dim);

for i = 1:n_inst
    dis = inf*ones(retain_n_cluster_aug, 1);
    cur_in = water_trun(i,:);
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
cluster_member_mat_ori = cluster_member_mat; % (ic,:);

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
    cur_in = water_trun(i,:);
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
norm_cluster_weight_mat_ori = norm_cluster_weight_mat(ic,:);

% %% construct docs (frames)
% [feature_mat2, n_inst2, n_feature2, feature_name2] = stream_data_frame_sum(norm_cluster_weight_mat_ori, win_size, offset, thre_rms);

save(['cluster_para_' data_name '.mat'], 'retain_cluster_center', 'S', 'std_dis');
