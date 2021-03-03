#!/bin/bash

[ ! -e bperp_file ] && cp ../subset/bperp_file ./

[ -e mv_data.dat ] && rm mv_data.dat
touch mv_data.dat
awk -F ' ' '{print "mv ../subset/"$2"_"$3"* ./"}' bperp_file >> mv_data.dat

while read line
do
	eval $line
done < mv_data.dat
