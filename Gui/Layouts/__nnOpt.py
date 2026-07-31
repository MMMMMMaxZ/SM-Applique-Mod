import os
import os.path

file_dir = input("file dir (LOCAL) : ")
text = open(file_dir,encoding='utf8')

textTable = text.readlines(1000)
oupText = []
st = 0

for tx in textTable:
    print(type(tx))
    for idx in range(len(tx)):
        if tx[idx] == '\\':
            oupText.append(tx[st:idx]+"\n")
            st = idx+2


OUP = open(file_dir + "_NEW.txt",mode = 'w+',encoding='utf8')
OUP.writelines(oupText)

print("end!")
text.close()
OUP.close()
