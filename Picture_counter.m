
head_dir = dir;
isub = [head_dir(:).isdir]; %# returns logical vector
mainFolds = {head_dir(isub).name}';

mainFolds(ismember(mainFolds,{'.','..','.DS_Store','Jpeg_counter.m','Jpeg_counter.m~'})) = [];


for j=1:length(mainFolds)
    date_folder = mainFolds{j};
    d = dir(date_folder);
    isub = [d(:).isdir]; %# returns logical vector
    nameFolds = {d(isub).name}';
    
    nameFolds(ismember(nameFolds,{'.','..'})) = [];
    
    for i=1:length(nameFolds)
        %disp(nameFolds{i});
        cd(date_folder);
        listOfJpegs = dir(nameFolds{i});
        numberOfJpegs = numel(listOfJpegs);
        if numberOfJpegs > 70
            fprintf('Too many jpegs (%d) in %s %s\n',numberOfJpegs,date_folder,nameFolds{i});
        end
        %disp(numberOfJpegs);
        cd ..
    end
    
    % for k = 1:numberOfJpegs
    %     information = listOfJpegs(k);
    %     jpegName = information.name;
    %     % Process the file whose name is jpegName
    % end
end