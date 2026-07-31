import os
import os.path
file_dir = input("file dir (LOCAL) : ")
text = open(file_dir,encoding='utf8')

textTable = text.readlines(1000)
oupText = ""

for tx in textTable:
    oupText = oupText + "\\n" + tx[:-1]

OUP = open(file_dir + "_NEW.txt",mode = 'w+')
OUP.write(oupText)

print("end!")
text.close()
OUP.close()