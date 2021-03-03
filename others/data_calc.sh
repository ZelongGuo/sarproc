#!/bin/bash

# chack the date gaps and data distribution for Sentinel-1 data
# under the data DIR

index=0
for line in `ls -1 | grep 'SAFE$' | sed 's/_/ /g' | awk -F ' ' '{print $5}' | awk -F 'T' '{print $1}'`
do
	a[$index]=$line
	let index+=1
done

rm -rf date_calc.dat >/dev/null

for ((i=0;i<${#a[*]};i++))
do
	if [ "$i" == "0" ]; then
		a_second[i]=`date -d "${a[i]}" "+%s"`
		printf "date			date_second		difference\n" > date_calc.dat
		#printf "%s		%s		BEGAIN\n" ${a[i]}, ${a_second[i]} >> date_calc.dat
		echo "${a[i]}		${a_second[i]}		BEGIN" >> date_calc.dat
		
	else
		a_second[i]=`date -d "${a[i]}" "+%s"`
		#printf "%s		%s		BEGAIN\n" ${a[i]}, ${a_second[i]} >> date_calc.dat
		diff=`echo ${a_second[i]} ${a_second[i-1]} | awk '{printf "%d", ($1-$2)/86400}'`
		echo "${a[i]}		${a_second[i]}		$diff" >> date_calc.dat
		
	fi
done

