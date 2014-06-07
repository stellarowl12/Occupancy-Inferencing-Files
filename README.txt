#############################################################################
#                                                                           #
# This README explains how to use all the files included in this directory. #
# The scripts and datasets found in this directory were written and curated #
# by Kevin Ting, Wentao Ouyang, and Samy Arjunan. For any additional quest- #
# ions, please send an email to gwkin1989@gmail.com.                        #
#                                                                           #
#############################################################################

The steps in our inferencing process are as follows:
1) Pull necessary data from Xively.
2) Process CSV files so they can be read into MATLAB.
3) Create Ground Truth CSV files in the right format.
4) Perform feature extraction within MATLAB and save output as both .mat and
.arff files.

Classification:
5) Perform analysis within Weka using .arff file.

Structured Prediction:
5) Create template files for HM-SVM or CRF.
6) Split dataset into training.data and testing.data files.
7) Call pre-compiled C code from within MATLAB to run algorithms.

The rest of this README will go into each step of the process in detail and
step through how to use every script. 


#############################################################################
Pulling Data From Xively:
Files referred: URL_dl_script.py, Xively_dl_links.txt

1) Visit http://128.97.93.30:9005 and get familiar with the options.
2) Fill in the following url with your custom settings for the parameters:
user, key, feed, datastream, start, end. Here is an example:

http://128.97.93.30:9005/xively/download?user=nesl_test&key=&feed=NESL_Veris
&datastream=Power0&start=2013-08-09T00:00&end=2013-08-16T00:00

3) Populate Xively_dl_links.txt with all such URLs that you need to download.
4) Type into Terminal: python URL_dl_script.py and wait for all downloads to
complete. This may take a very long time depending on how many links you put.
Typical time is ~3 minutes per link. 


#############################################################################
Processing CSV files:
Files referred: Reformat_csv.py

Raw CSV files downloaded from Xively come in the following format:
timestamp                       value
2013-07-23T00:00:01.398-07:00   0
2013-07-23T00:00:02.399-07:00   0
2013-07-23T00:00:03.400-07:00   0
2013-07-23T00:00:04.402-07:00   0
2013-07-23T00:00:05.403-07:00   1
etc. 

Use Reformat_csv.py to turn that into:
year    month    day    hour    minute    second    value   
2013        7     23       0         0         1        0
etc. 

Put all the raw csv files in a folder and move Reformat_csv.py into that fol-
der as well. Run python Reformat_csv.py and it will automatically do all the
processing for you.

#############################################################################
Creating Ground Truth Files:
We created ground truth traces from manually inspecting camera photos, but 
you can collect ground truth in whichever way you deem best. The information
just needs to be in a CSV file in the following format:

year    month    day    hour    minute    second    number_of_occupants 
2013        7     23       0         0         1                      3


#############################################################################
Performing Feature Extraction within MATLAB:
Files referred: concatenate.m, example_power.m, example_water.m, 
label_csv_to_mat.m, label_generation.m, stream_feature_extraction_1d.m, 
stream_feature_extraction_cluster.m

Ground Truth Processing:

1) Change the filename in label_csv_to_mat.m to your own Ground Truth CSV 
file. 
2) Run label_generation.m to generate a finalized ground truth matrix. 

Sensor Data Processing:
You can follow the steps inside example_power.m to extract features from any
sensor matrix. For example, water flow data, network traffic data can all use
this script as a template. You would just need to change a few parameters in
the script to match the format of your data. The script itself is well 
documented but the following are a few important notes on how to use it:

1) Load your complete power CSV file into example_power.m.
2) Make sure this line fmt = '%f%f%f%f%f%f%f%f'; matches the number of 
columns your dataset has.
3) Change the line day_of_week = [2 3 4 5 1 3 4 5 5]; to match the exact days
you want to include in your experiment. If some days have bad/missing data, 
you can exclude it. For example [1 2 4 5 6 7] means that Wednesday is skipped
in the week long dataset that is considered. 
4) You can change other parameters such as the window size, offset, sampling
rate, and threshold. They are clearly denoted in the code. 
5) If you want to change the actual features that are extracted within each 
time window, then go into stream_feature_extraction .m files. 
6) An example of creating a feature is the following: 
frag_mean(count,:) = mean(frag); You can create a new feature as follows:
frag_newfeature(count,:) = function_for_feature(frag);


Combining Separate Sensor Data:

1) Load your separate sensor datasets into concatenate.m
2) If you have more than two sensor datasets, then add additional lines in
the code where needed. 
3) The code stacks your datasets horizontally and then saves a .m and a 
.arff Weka file with the combined datasets.

#############################################################################
Analyzing datasets with Weka:
Files referred: any .arff file.

Steps:
1) Open Weka go to Explorer.
2) Press 'Open file...'.
3) Select the .arff file for your experiment. 
4) Use the bottom right hand section of the Preprocess tab to select any 
features to remove from consideration.
5) (Optional) Go to 'Select attributes' tab and under Attribute Evaluator, 
choose 'InfoGainAttributeEval'. Choose 5-fold Cross-validation and press 
'Start'. You can decide to remove certain features from the dataset based on
their overall contribution to the model. 
6) Go to the Classify tab.
7) Select the classifier you want by pressing the 'Choose' button in the top
Classifier section.
8) Click the name of the classifier in the section next to the 'Choose' button
to change parameters.
9) Press 'More options...' 
10) Click 'Preserve order for % split'
11) Click 'Cost-sensitive evaluation' and press 'Set...'
12) Open the corresponding .cost file for your experiment. 
13) Change Cross-validation to the number of folds you want. 
14) Make sure the drop-down list is set to the class label that you are trying
to predict. 
15) Press start and record evaluation metrics.


#############################################################################
Conditional Random Fields Experiment: 
Files referred: CRF_script.m, template.data, test.data, train.data, 
model.data, Testresult.txt

Steps:
1) Load your dataset into CRF_script.m.
2) Adjust the list of features you want considered, or just remove that logic
and consider all features if your featureset is not too large. 
3) Choose whether you want a Unigram or Bigram approach. Both are explained 
more in the CRF++ documentation on their website. 
4) Change the script to create the template.data file which matches your list
or features. Look at the existing template.data file for an example of a 
Bigram template for a length 35 featureset. 
5) The script is currently set to do leave-one-out cross validation for each
day in the dataset. You can change the folds and number of days easily.
6) The script automatically splits the dataset into training and testing sets.
7) It then learns a model based on the training set and evaluates it on the 
testing set, creating a new results file, Testresults.txt.
8) The script opens the results file and evaluates its mean absolute error and 
saves each fold's error in an array. 
9) In the end, the array is averaged, coming up with a final error value. 


#############################################################################
Hidden Markov Support Vector Machines Experiment: 
Files referred: HMSVM_script.m, training_input.dat, test_input.dat, 
modelfile.dat, Temp.txt, svm_hmm_learn, svm_hmm_classify, classify.tags

Steps: (very similar to CRF experiment)
1) Load dataset.
2) Select features you want.
3) Split dataset into training_input.dat and test_input.dat under leave-one-
out CV approach.
4) Use svm_hmm_learn on the training set to create a modelfile.dat and a 
Temp.txt file. 
5) Use svm_hmm_classify to predict labels for the testing set based on the 
modelfile.dat and classify.tags. 
6) Open classify.tags to load predicted labels. 
7) Compare these with ground truth labels and calculate mean absolute error.
8) Keep each value in an array and average that array for final value. 









