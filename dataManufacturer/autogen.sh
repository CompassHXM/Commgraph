#!/bin/bash
set -e #x to display commands, e to exit when error
inputfile="$1"
pattern=${inputfile%.txt}
limit=60000

if [ ! -f ${inputfile} ]; then
	echo file ${inputfile} is not exist.
	exit 1
fi

echo detected pattern as "$pattern"
set -x
if [ ! -f ${pattern}.bin ]; then
	./convert -i ${inputfile} -o ${pattern}.bin
fi
./louvain ${pattern}.bin -l -1 > ${pattern}.tree
./placement ${pattern}.tree -l ${limit} -m ${limit} -p ${pattern}.plan.json > ${pattern}.renum
./graph_renumber.py $1 -r ${pattern}.renum -o ${pattern}.txt.new

# comment below to debug
rm ${pattern}.tree ${pattern}.renum

echo All successful.

