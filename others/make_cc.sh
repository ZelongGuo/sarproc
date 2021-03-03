#!/bin/bash
# running this script under the subset DIR
# to make cohenrence files

reference=20180110
ran_look=4
azi_look=1

width=$(grep 'range_samples' $reference.rmli.par | awk '{print $2'})

for i in `ls -1 | grep '.diff$'`
do
	master=$(echo "$i" | sed 's/_/ /g' | awk '{print $1}')
	slave=$(echo "$i" | sed 's/_/ /g' | sed 's/\./ /g' | awk '{print $2}')
	echo "cc_wave $i $master.rmli $slave.rmli ${master}_${slave}.cc $width $ran_look $azi_look 2 "
	cc_wave $i $master.rmli $slave.rmli ${master}_${slave}.cc $width $ran_look $azi_look 2 
	echo "rascc ${master}_${slave}.cc $master.rmli $width"
	rascc ${master}_${slave}.cc $master.rmli $width
done


#cc_wave 20171123_20171205.diff 20171123.rmli 20171205.rmli 20171123_20171205.cc 6179 4 1 2

