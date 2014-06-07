clear all;
% load occ_all.mat;
load occ_all_0411_5min.mat;
% use normc to normalize the columns I want to use as features.

% list_of_features = {'PeerCount_Max','PeerCount_Mean','TCPMaxsizeIn_Mean','ReactPow_Median',...
% 'ReactPow_Mean','PeerCount_Median','TCPCountOut_Mean',...
% 'TCPMaxsizeIn_Median','Light','ReactPow_Min',...
% 'TCPCountOut_MeanDeriv','TCPMaxsizeOut_Mean','RealPow_Min','TCPCountOut_Iqr',...
% 'RealPow_Median','TCPCountOut_Median','TCPMaxsizeOut_MeanDeriv','TCPCountOut_Std',...
% 'TCPMaxsizeOut_Std','TCPCountOut_StdDeriv','TCPCountIn_Mean','TCPCountOut_Max',...
% 'PeerCount_Min','ReactPow_Max','TCPMaxsizeOut_StdDeriv','TCPCountOut_MaxDeriv',...
% 'Topic3','TCPCountIn_StdDeriv','RealPow_Mean','TCPCountIn_MeanDeriv','TimeOfDay'};

list_of_features = {'PeerCount_Max','PeerCount_Mean','TCPMaxsizeIn_Mean','ReactPow_Median',...
'ReactPow_Mean','PeerCount_Median','PeerCount_FreqEnergy','TCPCountOut_Mean',...
'ReactPow_FreqEnergy','TCPMaxsizeIn_Median','Light','ReactPow_Min',...
'TCPCountOut_MeanDeriv','TCPMaxsizeOut_Mean','RealPow_Min','TCPCountOut_Iqr',...
'RealPow_Median','TCPCountOut_Median','TCPMaxsizeOut_MeanDeriv','TCPCountOut_Std',...
'TCPMaxsizeOut_Std','TCPCountOut_StdDeriv','TCPCountIn_Mean','TCPCountOut_Max',...
'PeerCount_Min','ReactPow_Max','TCPMaxsizeOut_StdDeriv','TCPCountOut_MaxDeriv',...
'TCPMaxsizeIn_FreqEnergy','RealPow_FreqEnergy','Topic3',...
'TCPCountIn_StdDeriv','RealPow_Mean','TCPCountIn_MeanDeriv','TimeOfDay'};

list_of_indices = zeros(1,length(list_of_features));

for i=1:length(list_of_features)
    index = find(strcmp(output_feature_name, list_of_features(i)));
    if isempty(find(strcmp(output_feature_name, list_of_features(i)),1))
        list_of_features(i)
    end
    list_of_indices(i) = index;
end

shortened_mat = output_feature_mat(:,list_of_indices);
maxA = max(shortened_mat,[],1);
minA = min(shortened_mat,[],1);
norm_mat = bsxfun(@times, bsxfun(@minus, shortened_mat, minA), 1./abs(maxA - minA));

full_mat = [norm_mat output_label_num];

file_template = fopen('template.data','wt');
frewind(file_template);

fprintf('FILE Writing...\n');

fprintf(file_template, '# Bigram\n');
for j=0:9
    fprintf(file_template, 'B0%d:%%x[0,%d]\n',j,j);
end

for j=10:length(list_of_features)-1
    fprintf(file_template, 'B%d:%%x[0,%d]\n',j,j);
end

fprintf(file_template, 'B%d:%%x[0,%d]',length(list_of_features),0);
for j=1:9
    fprintf(file_template, '/%%x[0,%d]',j);
end
for j=10:length(list_of_features)-1
    fprintf(file_template, '/%%x[0,%d]',j);
end
fprintf(file_template, '\n');
fclose(file_template);


abs_errors = [];

for day=0:9
    
    delete('train.data','model.data','test.data','Testresult.txt');

    file_train = fopen('train.data','wt');
    frewind(file_train);

    fprintf('FILE Writing...\n');
    for r=setdiff(1:(215*10),(215*day+1):215*(day+1))
        for c=1:size(full_mat,2)-1
            fprintf(file_train,'%d ',full_mat(r,c));
        end
        fprintf(file_train,'%d\n',full_mat(r,c+1));
    end
    fclose(file_train);


    file_test = fopen('test.data','wt');
    frewind(file_test);

    fprintf('FILE Writing...\n');
    for r=(215*day+1):215*(day+1)
        for c=1:size(full_mat,2)-1
            fprintf(file_test,'%d ',full_mat(r,c));
        end
        fprintf(file_test,'%d\n',full_mat(r,c+1));
    end
    fclose(file_test);


    system(strcat('..\crf_learn -c',32,num2str(1.5), ...
            ' template.data train.data model.data'));

    system('..\crf_test -m model.data test.data > Testresult.txt');

    Prediction = importdata('Testresult.txt');
    gtruth = Prediction(:,36);
    pred = Prediction(:,37);

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
    abs_errors(day+1) = mean_absolute_error;
end


%%% CV leave 1 out, MAE of 0.52