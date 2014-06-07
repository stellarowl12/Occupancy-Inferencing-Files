function [idx_start, idx_end, idx_offset, n_offset] = sample_in_window(time_interval, win_size, offset)
% if win_size is 1 min
% you do not need to use this function

% time_stamp must be 6-vector with the format [year, mon, day, hh, mm, ss]
% currently support only for min
% for simplicity and tractability, the first window starts from 0 min, no matter when the time stamp really starts

% for example, if the time window is 2 min and the time_stamp contains 2min - 4min, then the window is constructed as [2], [3-4]
% it does not start from the beginning of the real time stamp and go up every win_size

% such a method can make sure the window and the label are well synchronized

            % read in a window
            % minute is the 5th col, second is the 6th col
            % if the time window is 5 min, then a windown may look like [xx:57:02 - xx:02:01]
            
            % the start time of the window % must start from a number that can be moded by win_size
            time_start = round((time_interval(1,4)*60 + time_interval(1,5))/win_size)*win_size; % consider min only
            % the end time
            time_end = time_start + win_size -1;
            % the offset time
            time_end_offset = time_start + offset - 1;
            
            % cur time hms
            time_hms = time_interval(:,4)*60 + time_interval(:,5); % min again
            
            idx_start = 1;
            % find the window end - the last sample in the end minute
            idx_end = find(time_hms <= time_end,1,'last');
                        
            %% calculate the num of samples to offset
            idx_offset = find(time_hms <= time_end_offset,1,'last');
            n_offset = idx_offset;
            
