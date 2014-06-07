import numpy as np
from collections import Counter

f = open('occ_home_5min_bin.arff','r')
all_lines = f.readlines()
f.close()

hour_list = []
gtruth_list = []
naive_list = []


for line in all_lines:
	if len(line.split(','))>5:
		lsplit = line.split(',')
		hour = int(lsplit[1])
		gtruth = int(lsplit[-1].rstrip('\r\n'))

		print gtruth
		if hour > 7 and hour < 18:
			naive = 0
		else:
			naive = 3

		hour_list.append(hour)
		gtruth_list.append(gtruth)
		naive_list.append(naive)



MAE = float(sum(abs((np.array(naive_list)-np.array(gtruth_list)))))/float(len(naive_list))
print MAE 

#print float(sum(abs((np.array(naive_list)-np.array(gtruth_list)))))/float(len(naive_list))
#print Counter(gtruth_list).most_common()

# True_Ps = 0
# False_Ps = 0
# True_Ns = 0
# False_Ns = 0

# for (gtruth,pred) in zip(gtruth_list,naive_list):
# 	if gtruth == 1 and pred == 1:
# 		True_Ps = True_Ps + 1
# 	elif gtruth == 1 and pred == 0:
# 		False_Ns = False_Ns + 1
# 	elif gtruth == 0 and pred == 1:
# 		False_Ps = False_Ps + 1
# 	elif gtruth == 0 and pred == 0:
# 		True_Ns = True_Ns + 1

# Precision = float(True_Ps) / float(True_Ps+False_Ps)
# Recall = float(True_Ps) / float(True_Ps + False_Ns)
# F = 2 * (Precision*Recall)/(Precision+Recall)

# print Precision, Recall, F





#print float(sum(abs((np.array(naive_list)-np.array(gtruth_list)))))/float(len(naive_list))
#print Counter(gtruth_list).most_common()

# True_Ps = 0
# False_Ps = 0
# True_Ns = 0
# False_Ns = 0

# for (gtruth,pred) in zip(gtruth_list,naive_list):
# 	if gtruth == 1 and pred == 1:
# 		True_Ps = True_Ps + 1
# 	elif gtruth == 1 and pred == 0:
# 		False_Ns = False_Ns + 1
# 	elif gtruth == 0 and pred == 1:
# 		False_Ps = False_Ps + 1
# 	elif gtruth == 0 and pred == 0:
# 		True_Ns = True_Ns + 1

# Precision = float(True_Ps) / float(True_Ps+False_Ps)
# Recall = float(True_Ps) / float(True_Ps + False_Ns)
# F = 2 * (Precision*Recall)/(Precision+Recall)

# print Precision, Recall, F