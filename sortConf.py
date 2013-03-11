#! /usr/bin/env python

import sys, re

filePath = sys.argv[1]

EMPTY_LINE = re.compile("(^$)|(^#)")
TITLE_LINE = re.compile("^\[(.+)\]$")

configList = []

lines = [line.strip() for line in open(filePath) if not EMPTY_LINE.search(line.strip())]
secTuple = ()
for line in lines:
    if TITLE_LINE.search(line):
        if secTuple:
            configList.append(secTuple)
        secTuple = (line, set())
    else:
        secTuple[1].add(line)
else:
    configList.append(secTuple)

for secTuple in configList:
    print secTuple[0]
    for line in sorted(secTuple[1]):
        print line
