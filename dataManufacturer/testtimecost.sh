#!/bin/bash
function getTiming() {
	set +x
	startt=$1
	endt=$2
	start_s=$(echo $startt | cut -d '.' -f 1)
	start_ns=$(echo $startt | cut -d '.' -f 2)
	end_s=$(echo $endt | cut -d '.' -f 1)
	end_ns=$(echo $endt | cut -d '.' -f 2)
	time=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))  
	echo "$time ms" 
	echo "$time ms" >> timefile.txt
}
set -e #x to display commands, e to exit when error
inputfile="$1"
n1=150000 #190000 
n2=50000
limit=5000
if [ ! -n "$1" ]; then
	echo Input 1 parameters for file!
	echo flie=$1
	exit 1
fi

#comment while to do normal thing.
while [ ${n1} -le 2000000 ]; do
pattern=${inputfile%.txt}
patternF=${pattern}_${n1}
Louvain_src="./Louvain_ver_0.3"

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
	./filter.py ${inputfile} -f ${n1} -o ${patternF}.txt
fi

#phase 1: actdp aggregate
starttime=$(date +%s.%N)
./actdp -a -i ${patternF}.txt -m aggregate.map -o ${patternF}_aggregate.txt -n1 ${n1} -n2 ${n2}
endtime=$(date +%s.%N)
getTiming $starttime $endtime

# ./${Louvain_src}/convert -i ${patternF}_aggregate.txt -o ${patternF}_aggregate.bin -w ${patternF}_aggregate.weight
# #phase 2: louvain & placement
# starttime=$(date +%s.%N)
# ./${Louvain_src}/louvain ${patternF}_aggregate.bin -w ${patternF}_aggregate.weight -l -1 > ${patternF}.tree
# ./placement ${patternF}.tree -l ${limit} -m ${limit} -p ${patternF}.plan.json > /dev/null
# endtime=$(date +%s.%N)
# getTiming $starttime $endtime

./${Louvain_src}/convert -i ${patternF}.txt -o ${patternF}.bin
####ori time if needed
starttime=$(date +%s.%N)
./${Louvain_src}/louvain ${patternF}.bin -l -1 > ${patternF}.tree
./placement ${patternF}.tree -l ${limit} -m ${limit} -p ${patternF}.plan.json > /dev/null
endtime=$(date +%s.%N)
getTiming $starttime $endtime

echo " " >> timefile.txt

#./graph_renumber.py ${patternF}.txt -r ${patternF}.renum -o ${patternF}.txt.new
# comment below to debug
rm ${patternF}.tree

# comment while to do normal thing.
let n1+=10000
done

echo All successful.

##

##
