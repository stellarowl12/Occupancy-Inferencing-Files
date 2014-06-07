f = open('occ_home_5min_bin.arff','r')
all_lines = f.readlines()
f.close()

f1 = open('occ_home_5min_bin_new.arff','w')

for line in all_lines:
	if len(line.split(','))>5:
		if int(line.split(',')[-1]) > 0:
			binary_stat = 1
		else:
			binary_stat = 0
		new_line = str(line.rstrip('\r\n'))+','+str(binary_stat)+'\n'
		f1.write(new_line)
		print new_line
	else:
		f1.write(line)

f1.close()