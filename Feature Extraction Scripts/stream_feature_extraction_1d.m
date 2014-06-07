function [feature_day_of_week, feature_hour_of_day, feature_min_of_hour, feature_min_of_day, feature_mat, feature_n_sample, feature_name] = ...
    stream_feature_extraction_1d(day_of_week, data_name, input_data, time_stamp, win_size, fs, thre_std)
% day_of_week - a number, e.g., 2
% data_name - a string, e.g., 'Water'
% input_data is a long data stream - each row is a sample, can contain only one column
% win_size - moving window size - in terms of mins
% offset - window offset - in terms of mins
% fs- sampling frequency
% thre_rms - threshold for the RMS of the signals in a time window for admission ctrl, singals with RMS larger than thre_rms will be used for
% feature extraction 
% time_stamp (6D) is required for placing the time window
% feature_mat is the feature matrix, each row is a feature vector corresponding to a time window
% feature_n_sample is the number of samples (in a time window) used to extract the corresponding feature vector
% feature_name is the name of the extracted features

        offset = win_size;
        
        length_input = size(input_data, 1);
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
            large_frag = input_data(p_start:min(p_end+n_guard_sample, length_input),:); % add a little guard range of 10 samples
            % minute is the 5th col, second is the 6th col
            % if the time window is 5 min, then a windown may look like [xx:57:02 - xx:02:01]
            large_time_interval = time_stamp(p_start:min(p_end+n_guard_sample, length_input),:);
            
            % the start time of the window % must start from a number that can be moded by win_size
            time_start = round((large_time_interval(1,4)*60 + large_time_interval(1,5))/win_size)*win_size; % consider min only
            % the end time
            time_end = time_start + win_size -1;
            % the offset time
            time_end_offset = time_start + offset - 1;
                       
            % cur time hms
            time_hms = large_time_interval(:,4)*60 + large_time_interval(:,5); % min again
            
            idx_start = find(time_hms >= time_start,1,'first');
            % find the window end - the last sample in the end minute
            idx_end = find(time_hms <= time_end,1,'last');
            
            %% extract the frag fall in the win_size
            frag = large_frag(idx_start:idx_end,:);
            % time_interval = large_time_interval(idx_start:idx_end,:);
                        
            % calculate the num of samples to offset
            idx_offset = find(time_hms <= time_end_offset,1,'last');
            n_offset = idx_offset;
            
           %% admission control on this fragment
           % if frag = [], adm = 0
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
            feature_hour_of_day(count,:) = large_time_interval(1,4);
            feature_min_of_hour(count,:) = floor(large_time_interval(1,5)/win_size)*win_size;
            feature_min_of_day(count,:) = feature_hour_of_day(count,:)*60 + feature_min_of_hour(count,:);
            
            %% number of samples in this time window
            feature_n_sample(count,:) = length(frag);
            
            % col mean and std
            %% time domain
            frag_mean(count,:) = mean(frag);
            frag_std(count,:) = std(frag);
            frag_median(count,:) = median(frag);
            frag_rms(count,:) = sqrt(mean(frag.^2));
            frag_max(count,:) = max(frag);
            frag_min(count,:) = min(frag);
            frag_range(count,:) = max(frag) - min(frag);
            
%             % skewness - asymmetry of the sensor signal distribution
%             frag_skew(count,:) = skewness(frag);
            % kurtosis - peakedness of the sensor signal distribution
            frag_kurt(count,:) = kurtosis(frag);
            % interquartile range (robust estimate for the spread of the data)
            frag_iqr(count,:) = iqr(frag);
%             % zero-crossing rate
%             sign_frag = sign(frag);
%             sign_diff = sign_frag(2:end,:) - sign_frag(1:end-1,:);
%             frag_zcr(count,:) = sum(abs(sign_diff))/2/(win_size-1);
            % mean-crossing rate
            sign_frag_mean = sign(frag - repmat(frag_mean(count,:),size(frag,1), 1));
            sign_diff_mean = sign_frag_mean(2:end,:) - sign_frag_mean(1:end-1,:);
            frag_mcr(count,:) = sum(abs(sign_diff_mean))/2/(length(frag)-1);

            % absolute difference between consecutive values
            frag_diff = abs(frag(2:end,:) - frag(1:end-1,:)); % need to take the absoluate value!!! - otherwise, positive and negative changes cancel out
            frag_mean_deriv(count,:) = mean(frag_diff);
            frag_std_deriv(count,:) = std(frag_diff);
            if ~isempty(max(frag_diff))
                frag_max_deriv(count,:) = max(frag_diff);
            else
                frag_max_deriv(count,:) = 0;
            end

            %% frequency domain
            NFFT = 2^nextpow2(length(frag));
            % FFT - symmetric - you need to take out over half of it
            Y1 = fft(frag,NFFT);
            
            % f = fs/2*linspace(0,1,NFFT/2+1);
            L = NFFT/2+1;

            % spectrum peak
            % you need to remove the DC component; otherwise, it will dominate the whole spectrum
            [~,ii] = max(abs(Y1(2:L)));
            if ~isempty(ii)
                frag_fre_peak(count,:) = fs/2*ii/L;
                % entropy 3D
                frag_entropy(count,:) = my_continuous_entropy(abs(Y1(2:L)));
                % energy 3D
                frag_energy(count,:) = sum(abs(Y1).^2)/NFFT;
            else
                frag_fre_peak(count,:) = 0;
                frag_entropy(count,:) = 0;
                frag_energy(count,:) = 0;
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
            % does not make sense
            %% the difference between current mean and previous window mean
%             frag_mean_diff = frag_mean - [frag_mean(1); frag_mean(1:end-1)];
%             frag_energy_diff = frag_energy - [frag_energy(1); frag_energy(1:end-1)];
        
            %% last mean and energy
            frag_last_mean = [0; frag_mean(1:end-1)];
            frag_last_energy = [0; frag_energy(1:end-1)];
            
        % current feature_mat - with multiple feature vectors; each row is a feature vector
        feature_mat = [frag_mean frag_last_mean frag_std frag_median frag_max frag_min frag_mean_deriv frag_std_deriv frag_max_deriv ...
                       frag_kurt frag_iqr frag_mcr frag_fre_peak frag_entropy frag_energy frag_last_energy];
        n_inst = size(feature_mat,1);
        n_feature = size(feature_mat,2);
        feature_day_of_week = day_of_week*ones(n_inst, 1);
        feature_name = {[data_name '_Mean' ],  [data_name '_LastMean'], [data_name '_Std'], [data_name '_Median'], [data_name '_Max'], [data_name '_Min'], ...
                        [data_name '_MeanDeriv'], [data_name '_StdDeriv'], [data_name '_MaxDeriv'], [data_name '_Kurt'], [data_name '_Iqr'], ...
                        [data_name '_Mcr'], [data_name '_FreqPeak'], [data_name '_FreqEntropy'], [data_name '_FreqEnergy'], [data_name '_FreqLastEnergy']};
        else
            feature_mat = [];
            n_inst = 0;
            n_feature = 0;
            feature_name = [];
        end