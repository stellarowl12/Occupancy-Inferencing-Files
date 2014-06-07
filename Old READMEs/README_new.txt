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
Perform Feature Extraction within MATLAB:
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

1) 


Combining Separate Sensor Data:
















