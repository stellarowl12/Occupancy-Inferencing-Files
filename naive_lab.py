import numpy as np
from collections import Counter

f = open('occ_all_0411_5min.arff','r')
all_lines = f.readlines()
f.close()

hour_list = []
gtruth_list = []
naive_list = []

for line in all_lines:
	if len(line.split(','))>5:
		lsplit = line.split(',')
		day = int(lsplit[1])
		hour = int(lsplit[2])
		gtruth = int(lsplit[-14].rstrip('\r\n'))

		if gtruth == 0:
			gtruth_new = 0
		elif gtruth == 1:
			gtruth_new = 2
		elif gtruth == 2:
			gtruth_new = 5.5
		elif gtruth == 3:
			gtruth_new = 10

		if day == 6 or day == 7:
			if hour > 12 and hour < 18:
				naive = 2
			else:
				naive = 0
		else:
			if hour > 8 and hour < 18:
				naive = 5.5
			elif hour > 18 and hour < 22:
				naive = 2
			else:
				naive = 0

		# if naive > 0:
		# 	naive = 1
		# else:
		# 	naive = 0

		# if hour > 8 and hour < 22:
		# 	naive = 1
		# else:
		# 	naive = 0

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