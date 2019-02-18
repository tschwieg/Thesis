#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import os
import glob


def ensure_dir(file_path):
    # directory = os.path.dirname(file_path)
    if not os.path.exists(file_path):
        os.makedirs(file_path)


files = glob.glob("*.csv")

for csvFile in files:
    print(csvFile)
    if("★ " in csvFile):
        NewcsvFile = csvFile.replace("★ ", "")
    if("Music Kit" in csvFile):
        continue
    # if("StatTrak™ " in csvFile):
    #     NewcsvFile = NewcsvFile.replace("StatTrak™ ", "")
    print(NewcsvFile)
    if(" | " not in NewcsvFile):
        NewcsvFile = NewcsvFile.replace(".csv", "") + " | Stock (Stock).csv"

    gunSplit = NewcsvFile.split(" | ")
    # print(gunSplit[0])
    ensure_dir(gunSplit[0])

    # print(gunSplit[1])
    regX = re.compile(r"\([a-zA-Z0-9 -_]+\).csv")
    skinInfo = re.search(regX, gunSplit[1])
    # print(skinInfo)
    skinName = skinInfo.group(0)

    # print(skinName)
    ensure_dir(gunSplit[0] + "/" + skinName)

    os.rename(csvFile, gunSplit[0] + "/" + skinName + '/' + csvFile)
