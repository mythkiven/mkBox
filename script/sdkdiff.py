#!/usr/bin/python
#coding=utf-8

import sys
import os
import getopt


def printUsage(argv):
    useage = '''
    %s is a simple tool that can analyze the size of the static SDK.

    usage:
    %s  [-l] file1 [file2]
    -l list in long format.use 'size' command to print file info.
    '''
    filename = os.path.basename(argv[0])
    toolname = os.path.splitext(filename)[0]
    print useage.replace('%s', toolname)


def exitAndPrintUsage(argv):
    printUsage(argv)
    sys.exit(2)


def printSDKInfoWithSizeCmd(sdkFile, isLongFormat):
    if isLongFormat:
        os.system('size -A ' + sdkFile)
    else:
        os.system('size -B ' + sdkFile)


def getArchTypes(sdkFile):
    cmd = os.popen(
        'lipo -info %s | sed -En -e "s/^(Non-|Architectures in the )fat file: .+( is architecture| are): (.*)$/\\3/p"'
        % sdkFile)
    output = cmd.read()
    return output.split()


def getObjectFileSize(sdkFile):
    archList = getArchTypes(sdkFile)
    totalSize = {}
    if len(archList) <= 1:
        return getObjectFileSizeWithArCmd(sdkFile)
    else:
        for arch in archList:
            sdkFile_arch = "tmp_%s" % arch
            if os.path.exists(sdkFile_arch):
                os.remove(sdkFile_arch)
            os.popen(
                'lipo -thin %s %s -output %s' % (arch, sdkFile, sdkFile_arch))
            sizeDic = getObjectFileSizeWithArCmd(sdkFile_arch)
            for objectFile in sizeDic:
                size = sizeDic[objectFile]
                if objectFile in totalSize:
                    size = totalSize[objectFile] + size
                totalSize[objectFile] = size
            if os.path.exists(sdkFile_arch):
                os.remove(sdkFile_arch)
    return totalSize


def getObjectFileSizeWithArCmd(sdkFile):
    cmd = os.popen("ar -t -v " + sdkFile +
                   " | awk '{printf \"%s:%s\\n\", $8, $3}'")
    output = cmd.read()
    strlist = output.split()
    sizeDic = {}
    for item in strlist:
        info = item.split(":")
        sizeDic[info[0]] = int(info[1])
    return sizeDic


def diffObjectFileSizeWithArCmd(sdkFile1, sdkFile2):
    sdkSize1 = getObjectFileSize(sdkFile1)
    sdkSize2 = getObjectFileSize(sdkFile2)
    diffDic = {}
    for key in sdkSize2:
        if key in sdkSize1:
            diffDic[key] = sdkSize2[key] - sdkSize1[key]
            del sdkSize1[key]
        else:
            diffDic[key] = sdkSize2[key]
    for key in sdkSize1:
        diffDic[key] = -sdkSize1[key]

    totalDiff = 0
    totalSize = 0
    itemList = sorted(diffDic.items(), lambda x, y: cmp(y[1], x[1]))
    for item in itemList:
        key = item[0]
        diff = item[1]
        totalDiff += diff
        totalSize += sdkSize2[key]
        if diff != 0:
            print "%s%-12d %-12d %s" % ("+" if diff > 0 else "-", abs(diff),
                                        sdkSize2[key], key)
    print "----------------------------------\n%s%-12d %-12d %s" % ("+" if totalDiff > 0 else "-", abs(totalDiff),
                                        totalSize, "Total")

if __name__ == '__main__':
    if (len(sys.argv) < 2):
        exitAndPrintUsage(sys.argv)
    else:
        try:
            opts, args = getopt.getopt(sys.argv[1:], "l", ["long"])
        except Exception, err:
            print "\nError: " + str(err)
            exitAndPrintUsage(sys.argv)

        longForamt = False
        for opt, arg in opts:
            if opt in ("-l", "--long"):
                longForamt = True

        if (len(args) == 1):
            printSDKInfoWithSizeCmd(args[0], longForamt)
        elif (len(args) >= 2):
            diffObjectFileSizeWithArCmd(args[0], args[1])
        else:
            print "\nError: no file\n"
