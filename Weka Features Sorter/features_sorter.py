f = open('features.txt','r')
lines = f.readlines()
feature_nums = []
for line in lines:
	list_of_terms = line.split()
	feature_nums.append(int(list_of_terms[-2]))

print sorted(feature_nums)

f.close()