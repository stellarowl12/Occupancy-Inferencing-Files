clear all;

load occ_all_0411_5min.mat;

% list_of_features = {'PeerCount_Max','PeerCount_Mean','TCPMaxsizeIn_Mean','ReactPow_Median',...
% 'ReactPow_Mean','PeerCount_Median','PeerCount_FreqEnergy','TCPCountOut_Mean',...
% 'ReactPow_FreqEnergy','TCPMaxsizeIn_Median','Light','ReactPow_Min',...
% 'TCPCountOut_MeanDeriv','TCPMaxsizeOut_Mean','RealPow_Min','TCPCountOut_Iqr',...
% 'RealPow_Median','TCPCountOut_Median','TCPMaxsizeOut_MeanDeriv','TCPCountOut_Std',...
% 'TCPMaxsizeOut_Std','TCPCountOut_StdDeriv','TCPCountIn_Mean','TCPCountOut_Max',...
% 'PeerCount_Min','ReactPow_Max','TCPMaxsizeOut_StdDeriv','TCPCountOut_MaxDeriv',...
% 'TCPMaxsizeIn_FreqEnergy','RealPow_FreqEnergy','Topic3',...
% 'TCPCountIn_StdDeriv','RealPow_Mean','TCPCountIn_MeanDeriv','TimeOfDay'};

% list_of_indices = zeros(1,length(list_of_features));
% 
% for i=1:length(list_of_features)
%     index = find(strcmp(output_feature_name, list_of_features(i)));
%     if isempty(find(strcmp(output_feature_name, list_of_features(i)),1))
%         list_of_features(i)
%     end
%     list_of_indices(i) = index;
% end
% 
% shortened_mat = output_feature_mat(:,list_of_indices);

shortened_mat = output_feature_mat;
maxA = max(shortened_mat,[],1);
minA = min(shortened_mat,[],1);
norm_mat = bsxfun(@times, bsxfun(@minus, shortened_mat, minA), 1./abs(maxA - minA));

full_mat = norm_mat;
ground_truth = output_label_num;
ground_truth = ground_truth + 1;

abs_error = [];

indices_by_17 = 215;

for day=0:9
    test_indices = (indices_by_17*day+1):indices_by_17*(day+1);
    train_indices = setdiff(1:(indices_by_17*10),test_indices);

    file_train = fopen('training_input.dat','wt');
    file_test = fopen('test_input.dat','wt');
    frewind(file_train);
    frewind(file_test);
    
    fprintf('FILE Writing...\n');
    for i=train_indices
        fprintf(file_train,'%d qid:%d ',ground_truth(i),i);
        for j=1:size(full_mat,2)-1
            fprintf(file_train,'%d:%d ',j,full_mat(i,j));
        end
        fprintf(file_train,'%d:%d\n',j+1,full_mat(i,j+1));
    end
    fclose(file_train);


    fprintf('FILE Writing...\n');

    for i=test_indices
        fprintf(file_test,'%d qid:%d ',ground_truth(i),i);
        for j=1:size(full_mat,2)-1
            fprintf(file_test,'%d:%d ',j,full_mat(i,j));
        end
        fprintf(file_test,'%d:%d\n',j+1,full_mat(i,j+1));
    end
    fclose(file_test);

    system(strcat('svm_hmm_learn -c',32,num2str(8),' -e',32,num2str(0.5), ...
            ' training_input.dat modelfile.dat > Temp.txt'));
    %Prediction Part
    system(strcat('svm_hmm_classify test_input.dat modelfile.dat classify.tags > Temp.txt'));

    Prediction = importdata('classify.tags');
    Prediction = Prediction - 1;
    pred = Prediction;
    gtruth = ground_truth(test_indices) - 1;

    for i=1:length(gtruth)
        if gtruth(i) == 0
            gtruth_new(i) = 0;
        elseif gtruth(i) == 1
            gtruth_new(i) = 2;
        elseif gtruth(i) == 2
            gtruth_new(i) = 5.5;
        elseif gtruth(i) == 3
            gtruth_new(i) = 10;
        end
    end

    for i=1:length(pred)
        if pred(i) == 0
            pred_new(i) = 0;
        elseif pred(i) == 1
            pred_new(i) = 2;
        elseif pred(i) == 2
            pred_new(i) = 5.5;
        elseif pred(i) == 3
            pred_new(i) = 10;
        end
    end

    mean_absolute_error = sum(abs(gtruth_new-pred_new))/length(gtruth)
    abs_error(day+1) = mean_absolute_error;
    
    delete('training_input.dat','test_input.dat','modelfile.dat','Temp.txt','classify.tags');
end

average_errors = mean(abs_error)


