import os 

def parseAsanAddrs(aAsanLogPath,aAsanAddrsPath):
    lines = []
    with open(aAsanLogPath, "r") as file:
        lines = file.readlines()  # 返回列表，每个元素是一行内容（含换行符）
    print("\n读取所有行到列表： ")
    print(lines)  # 输出：['第一行\n', '第二行\n', '第三行']

    newLines = []
    for line in lines:
         
        isCallstack0Line = (-1 != line.find("#0 ") )
        if isCallstack0Line:
            newLines.append("===============================================\n")
            

        soPathStr="/lib/arm64/libandroioearth01.so+"
        
        nFind0 = line.find(soPathStr)
        if (-1 == nFind0):
            newLines.append(line)
            continue
        
        len_soPathStr = len(soPathStr)
        nFind1 = line.find(")", nFind0 +len_soPathStr )
        if (-1 == nFind1):
            newLines.append(line)
            continue
        
        funcAddr = line[nFind0 +len_soPathStr : nFind1]
        newLines.append("\""+funcAddr+"\"\n")

    with open(aAsanAddrsPath, "wt") as fw:
        fw.writelines(newLines)



if __name__=="__main__":
    parseAsanAddrs("./0ndk_asan_log.txt","./1asan_addrs.txt") 