import re, os

files_list = []

for filename in os.listdir("./"):
    if filename.endswith(".csv"):
    	files_list.append(filename)

for csv in files_list: 
	f = open(csv,'r')

	lines = f.readlines()
	f.close()

	write_file = open('reformatted-'+csv,'w')
	for line in lines:
		if len(line.split('-')) > 2:
			split_line = re.split('-|T|:|,|\n',line)
			year = split_line[0]
			month = str(int(float(split_line[1])))
			day = str(int(float(split_line[2])))
			hour = str(int(float(split_line[3])))
			minute = str(int(float(split_line[4])))
			second = str(int(float(split_line[5])))
			value = str(int(float(split_line[-2])))

			write_file.write(year+','+month+','+day+','+hour+','+minute+','+second+','+value+'\n')

	write_file.close()