#!/bin/bash
set -e #x to display commands, e to exit when error
inputfile="$1"
n=180000
pattern=${inputfile%.txt}
patternF=${pattern}_${n}
Louvain_src="./Louvain_ver_0.3"
limit=20000

if [ ! -f ${inputfile} ]; then
	echo file ${inputfile} is not exist.
	exit 1
fi

echo building...
cd ${Louvain_src} && make && cd -
g++ placement.cpp -std=c++11 -O2 -o placement

echo detected pattern as "$pattern"
echo set pattern after filter as "$patternF"
set -x
if [ ! -f ${patternF}.txt ]; then
	./filter.py ${inputfile} -f $n -o ${patternF}.txt
fi
if [ ! -f ${patternF}.bin ]; then
	./${Louvain_src}/convert -i ${patternF}.txt -o ${patternF}.bin
fi
./${Louvain_src}/louvain ${patternF}.bin -l -1 > ${patternF}.tree
./placement ${patternF}.tree -l ${limit} -m ${limit} -p ${patternF}.plan.json > ${patternF}.renum
./graph_renumber.py ${patternF}.txt -r ${patternF}.renum -o ${patternF}.txt.new

# comment below to debug
rm ${patternF}.tree ${patternF}.renum

echo All successful.

