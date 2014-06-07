function [feature_day_of_week, feature_time_of_day, feature_min_of_hour, feature_mat, feature_n_sample, n_inst, n_feature, feature_name] = ...
    stream_feature_extraction_cluster(day_of_week, data_name, input_data, time_stamp, win_size, offset, fs, thre_std, cluster_center, std_dis, S_cov, mode)
% input_data is a long data stream - each row is a sample, can contain only one column
% win_size - moving window size - in terms of mins
% offset - window offset - in terms of min
% fs- sampling frequency
% thre-rms - for admission ctrl
% time_stamp is required for placing the time window

% feature_mat is the feature matrix
% feature_n_sample is the number of samples used to extract the corresponding feature vector

        length_input = size(input_data, 1);
        n_cluster = size(cluster_center, 1);
        % set flag, start and end point
        flag = 0;
        p_start = 1;
        % make the end point further, to contain the required samples for sure
        p_end = round(p_start + win_size*60*fs);
        
        n_guard_sample = 20;
        
        count = 0;
        
        while flag == 0
            
            % read in a window
            % acc can be used for filtering - whether the user is browsing
            % or the phone is steady
            cur_range = p_start:min(p_end+n_guard_sample, length_input);
            large_frag = input_data(cur_range,:); % add a little guard range of 10 samples
            % minute is the 5th col, second is the 6th col
            % if the time window is 5 min, then a windown may look like [xx:57:02 - xx:02:01]
            large_time_interval = time_stamp(cur_range,:);
                        
            % get the corresponding idx for the start and the end samples in current time interval
            [idx_start, idx_end, ~, n_offset] = sample_in_window(large_time_interval, win_size, offset);
            
            %% extract the frag fall in the win_size
            frag = large_frag(idx_start:idx_end,:);
            % time_interval = large_time_interval(idx_start:idx_end,:);
            
           %% admission control on this fragment
            [~, adm] = admission_ctrl_std(frag, thre_std);
            % extract features only when the fragment contains signals
            if adm == 1
                count = count + 1;
%             % mag and ori are used for feature extraction
%             % ori y and z are used for filtering
%             frag_mgf = current_mgf_data(p_start:p_end,:);
%             frag_ori = current_ori_data(p_start:p_end,:);
%             
%             frag_magnitude = current_magnitude(p_start:p_end);
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% features
            
            %% time
            feature_time_of_day(count,:) = large_time_interval(1,4);
            
            feature_min_of_hour(count,:) = floor(large_time_interval(1,5)/win_size)*win_size;
            
            %% number of samples in this time window
            feature_n_sample(count,:) = size(frag, 1);
            
            %% cluster features
            cluster_dis_mat = inf*ones(size(frag,1), n_cluster);
            cluster_mem_mat = zeros(size(frag,1), n_cluster);

            % for each sample in the fragment, compute its cluster assignment
            for i = 1:size(frag, 1)
                cur_in = frag(i,:);
                    for j = 1:n_cluster
                        %% Caution!!!
                            x = cur_in - cluster_center(j,:); % because of this operation - even if cur_in is 1D, x will be the same size as cluster_center!!!
                            cluster_dis_mat(i,j) = sqrt(x*(S_cov\x.'));
                            % cluster_dis_mat(i,j) = cur_in*cluster_center(j,:).'/(norm(cur_in)*norm(cluster_center(j,:)));
                    end
                    idx_min = find(cluster_dis_mat(i,:) == min(cluster_dis_mat(i,:)), 1, 'first');
                    cluster_mem_mat(i, idx_min) = 1;
            end            

            if strcmp(mode, 'soft')
            %% Method 1
            % convert dis mat to weight mat
            cluster_weight_mat = exp(-cluster_dis_mat/std_dis);
            % cluster_weight_mat = exp(-cluster_dis_mat.^2/2/std_dis^2);
            sum_cluster_weight_mat = sum(cluster_weight_mat);
            norm_cluster_weight_vec = prob_mat_nlz(sum_cluster_weight_mat, 'row');
            
            idx0 = (norm_cluster_weight_vec < 1e-4);
            norm_cluster_weight_vec(idx0) = 0;
            
            % cluster distribution corresponding to current fragment -
            % cluster weight * num of elements in the cluster
            frag_cluster_distribution(count,:) = round(size(frag,1)*norm_cluster_weight_vec);
            
            elseif strcmp(mode, 'hard')
%             %% Method 2
            sum_cluster_mem_mat = sum(cluster_mem_mat);
            % norm_cluster_mem_vec = prob_mat_nlz(sum_cluster_mem_mat, 'row');
            
            % cluster distribution corresponding to current fragment 
            frag_cluster_distribution(count,:) = sum_cluster_mem_mat; %norm_cluster_mem_vec;           
            end
            
            end
            % move the window
            p_start = p_start + n_offset;
            p_end = p_end + n_offset;

            if p_start >= length_input % not a full window
                flag = 1;
            end
        end
        
        %% output
        if count ~= 0
        % current feature_mat - with multiple feature vectors; each row is a feature vector
        feature_mat = frag_cluster_distribution;
        n_inst = size(feature_mat,1);
        n_feature = size(feature_mat,2);
        feature_day_of_week = day_of_week*ones(n_inst, 1);
        feature_name = [];
        for i = 1:n_cluster
            feature_name = [feature_name {[data_name '_Cluster' num2str(i)]}];
        end
        
        else
            feature_mat = [];
            n_inst = 0;
            n_feature = 0;
            feature_name = [];
        end