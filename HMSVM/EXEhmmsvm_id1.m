function Error = EXEhmmsvm_id1( LearnDataFinal,LearnGTruth,Learnday,TestDataFinal,TestGTruth,Testday,C,e )
%
% This function is used to learn and test the HMM-SVM model
% For the output, two different variables can be used:
% 1. Error: Symmetric Difference focusing on the identity of each occupant
% 2. Error_num: Absolute Value used in the inference of the number of
% occupants
% 
% Author: Longqi Yang   E-mail: ylongqi@gmail.com
%

file_learn = fopen('F:/HMMSVM/training_input.dat','wt');
file_test = fopen('F:/HMMSVM/test_input.dat','wt');
frewind(file_learn);
frewind(file_test);

fprintf('FILE Writing...\n');
for i = 1:Learnday
    for j = 1:144
        presentindex = 144*(i - 1) + j;
        presenthour = fix((j - 1)/6) + 1;
        fprintf(file_learn,'%d qid:%d 1:%d 2:%d 3:%d 4:%d 5:%d 6:%d 7:%d 8:%d 9:%d 10:%d 11:%d\n',...
            LearnGTruth(1,presentindex),i,LearnDataFinal(presentindex,1),LearnDataFinal(presentindex,2),...
            LearnDataFinal(presentindex,3),LearnDataFinal(presentindex,4),LearnDataFinal(presentindex,5),...
            LearnDataFinal(presentindex,6),LearnDataFinal(presentindex,7),LearnDataFinal(presentindex,8),...
            LearnDataFinal(presentindex,9),LearnDataFinal(presentindex,10),presenthour);
    end
end

for i = 1:Testday
    for j = 1:144
        presentindex = 144*(i - 1) + j;
        presenthour = fix((j - 1)/6) + 1;
        fprintf(file_test,'%d qid:%d 1:%d 2:%d 3:%d 4:%d 5:%d 6:%d 7:%d 8:%d 9:%d 10:%d 11:%d\n',...
            TestGTruth(1,presentindex),i,TestDataFinal(presentindex,1),TestDataFinal(presentindex,2),...
            TestDataFinal(presentindex,3),TestDataFinal(presentindex,4),TestDataFinal(presentindex,5),...
            TestDataFinal(presentindex,6),TestDataFinal(presentindex,7),TestDataFinal(presentindex,8),...
            TestDataFinal(presentindex,9),TestDataFinal(presentindex,10),presenthour);
    end
end

fclose(file_learn);
fclose(file_test);
%ErrorFinal = [];

    %Execute the learning program
system(strcat('F:/HMMSVM/svm_hmm_learn -c',32,num2str(C),' -e',32,num2str(e), ...
        ' F:/HMMSVM/training_input.dat F:/HMMSVM/modelfile.dat > F:/HMMSVM/Temp.txt'));
    %Prediction Part
system(strcat('F:/HMMSVM/svm_hmm_classify F:/HMMSVM/test_input.dat F:/HMMSVM/modelfile.dat F:/HMMSVM/classify.tags > F:/HMMSVM/Temp.txt'));

Prediction = importdata('F:/HMMSVM/classify.tags');

 
Error = 0;
Error_num = 0;
for i = 1:Testday
    for j = 1:144
        presentindex = (i - 1)*144 + j;
        presentstr = dec2bin(Prediction(presentindex,1) - 1,3);
        presentstrGTruth = dec2bin(TestGTruth(1,presentindex) - 1,3);
        if(str2double(presentstr(1,1)) ~= str2double(presentstrGTruth(1,1)))
            Error = Error + 1;
        end
        if(str2double(presentstr(1,2)) ~= str2double(presentstrGTruth(1,2)))
            Error = Error + 1;
        end
        if(str2double(presentstr(1,3)) ~= str2double(presentstrGTruth(1,3)))
            Error = Error + 1;
        end
        Predictionnum = str2double(presentstr(1,1)) + str2double(presentstr(1,2)) + str2double(presentstr(1,3));
        GTruthnum = str2double(presentstrGTruth(1,1)) + str2double(presentstrGTruth(1,2)) + str2double(presentstrGTruth(1,3));
        Error_num = Error_num + abs(Predictionnum - GTruthnum);
    end
end
    %ErrorFinal = [ErrorFinal Error];

end

