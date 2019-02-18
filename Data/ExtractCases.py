#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import os
import glob
import csv
from datetime import datetime as dt

def ensure_dir(file_path):
    # directory = os.path.dirname(file_path)
    if not os.path.exists(file_path):
        os.makedirs(file_path)
caseContents = {}

Cases = glob.glob("ModifiedKnives/*.csv")
for case in Cases:
    with open(case, "rb") as data:
        contentsCsv = csv.reader(data, delimiter=',')
        contents = [r for r in contentsCsv]
        caseContents[case] = contents

case = caseContents[Cases[1]]

casePrices = "Cases/Shadow Case.csv"
caseContentData = {}

throwoutDate = dt.strptime("Feb 28 2018 01: +0", "%b %d %Y %H: +0")

for row in case:
    csvFile = "Data/" + row[0] + "/" + row[1] + "/" + row[2] + ".csv"
    with open(csvFile, "rb") as data:
        contentsCsv = csv.reader(data, delimiter=',')
        contents = [r for r in contentsCsv]
        caseContentData[csvFile] = contents
    
with open(casePrices, "rb") as data:
    contentsCsv = csv.reader(data, delimiter=',')
    contents = [r for r in contentsCsv]
    for row in contents:
        date = dt.strptime(row[0], "%b %d %Y %H: +0")
        
