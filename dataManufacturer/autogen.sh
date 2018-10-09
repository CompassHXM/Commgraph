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
n=$2 #190000 
limit=$3 #20000
if [ ! -n "$3" ]; then
	echo Input 3 parameters for file, n, and limit of a partition!
	echo flie=$1 n=$2 limit=$3
	exit 1
fi

#comment while to do normal thing.
while [ $n -le 1000000 ]; do
pattern=${inputfile%.txt}
patternF=${pattern}_${n}
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
	./filter.py ${inputfile} -f $n -o ${patternF}.txt
fi
if [ ! -f ${patternF}.bin ]; then
	./${Louvain_src}/convert -i ${patternF}.txt -o ${patternF}.bin
fi
starttime=$(date +%s.%N)
./${Louvain_src}/louvain ${patternF}.bin -l -1 > ${patternF}.tree
./placement ${patternF}.tree -l ${limit} -m ${limit} -p ${patternF}.plan.json > ${patternF}.renum
endtime=$(date +%s.%N)
getTiming $starttime $endtime
#./graph_renumber.py ${patternF}.txt -r ${patternF}.renum -o ${patternF}.txt.new
# comment below to debug
rm ${patternF}.tree ${patternF}.renum

# comment while to do normal thing.
let n+=10000
done

echo All successful.



