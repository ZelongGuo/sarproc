#!/bin/bash


# make subset folder (cropping) and conducting difference
# This script will generate relevant files at subset directory
# Zelong Guo @GFZ
# zelong@gfz-potsdam.de
# First Version: 15/12/2020
# Version: 07.02.2021

:<<comment
miss_type=
reference=
ran_look=
azi_look=
cp_sub=
roff=
nr=
loff=
nl=
comment

cp_sub=$(echo "$cp_sub" | tr 'A-Z' 'a-z')
miss_type=$(echo "$miss_type" | tr 'A-Z' 'a-z')


echo "sh_diffe.log" 
printf "Now the executing directory is %s\n" $PWD
#+++++++++++++++++++++++++++++++++++++++++++++++++++++ reading the sensing data and writing it into a array ++++++++++++++++++++++++++++++++++++++++++++++++++#
if [ "$miss_type" == "s1a" ]; then
	sensing_date_read=$(cat grep_dates_s1a | awk '{print $0}')
	index=0
	for sensing_date_read_index in $sensing_date_read
	do
		sensing_date[$index]=$sensing_date_read_index
		let index+=1
	done
	echo "Sensing_date (s1a):"
	echo "${sensing_date[*]}"
elif [ "$miss_type" == "s1b" ]; then
	sensing_date_read=$(cat grep_dates_s1b | awk '{print $0}')
	index=0
	for sensing_date_read_index in $sensing_date_read
	do
		sensing_date[$index]=$sensing_date_read_index
		let index+=1
	done
	echo "Sensing_date (s1b):"
	echo "${sensing_date[*]}"
else
	[ -e "grep_dates" ] && rm grep_dates && touch grep_dates
	cat grep_dates_s1a >> grep_dates 
	cat grep_dates_s1b >> grep_dates
		
	sensing_date_read=$(cat grep_dates | awk '{print $0}')
	index=0
	for sensing_date_read_index in $sensing_date_read
	do
		sensing_date[$index]=$sensing_date_read_index
		let index+=1
	done
	echo "Sensing_date (s1a+s1b):"
	echo "${sensing_date[*]}"
	rm grep_dates
fi	
# Reading the sensing data and writing to an array are finished.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


cd $procdir
mkdir -p subset
cd subset

[ -e "dates" ] && rm dates && touch dates
for ((i=0;i<${#sensing_date[*]};i++))
do
	k=${sensing_date[i]}
	echo "$k" >> dates

	if [ "$cp_sub" == "y" ] || [ "$cp_sub" == "yes" ]; then

		SLC_copy ../coreg/$k.rslc ../coreg/$k.rslc.par ./$k.rslc ./$k.rslc.par - - $roff $nr $loff $nl
		
		multi_look $k.rslc $k.rslc.par $k.rmli $k.rmli.par $ran_look $azi_look
		width_mli=$(cat $k.rmli.par | awk '/range_samples:/ {print $2} ')
		raspwr $k.rmli $width_mli 
		#///////////////////////////////////////////////
		# NEXT UPDATE:
		# creat_offset offset_pwr SLC_interp maybe work
		#///////////////////////////////////////////////

	else
		ln -s ../coreg/$k.rslc ./
		ln -s ../coreg/$k.rslc.par ./
		multi_look $k.rslc $k.rslc.par $k.rmli $k.rmli.par $ran_look $azi_look
		width_mli=`cat $k.rmli.par | awk '/range_samples:/ {print $2} '`
		raspwr $k.rmli $width_mli 
	fi
done

#++++++ InSAR processing and Gold-stein filtering +++++++#	 
make_tab dates RSLC_tab '$1.rslc $1.rslc.par'
base_calc RSLC_tab $reference.rslc.par bperp_file itab $itab_type 1 $bperp_min $bperp_max $delta_T_min $delta_T_max 

# link the srtm file to subset directory
ln -s ../multi_looking/*hgt.SRTM ./

#++++++ creat a new batching processing file ++++++#
[ -e "bperp_file2" ] && rm batching_file && touch batching_file
srtm=$(ls ../multi_looking/*hgt.SRTM | awk -F '/' '{print $NF}')
width=$(cat $reference.rmli.par | awk '/range_samples:/ {print$2}')
awk -v ran_look=$ran_look -v azi_look=$azi_look -v srtm=$srtm -v width=$width '{print $1, $2, $3, ran_look, azi_look, srtm, width}' bperp_file >> batching_file

#++++++ calculate differential interferograms ++++++#
run_all batching_file 'create_offset $2.rslc.par $3.rslc.par $2_$3.off 1 $4 $5 0'
run_all batching_file 'phase_sim_orb $2.rslc.par $3.rslc.par $2_$3.off $6 $2_$3.sim_unw $2.rslc.par - - 1 1'
#run_all batching_file 'rasrmg $2_$3.sim.unw $2.rmli $7'
run_all batching_file 'SLC_diff_intf $2.rslc $3.rslc $2.rslc.par $3.rslc.par $2_$3.off $2_$3.sim_unw $2_$3.diff $4 $5 1 1 0.2'
run_all batching_file 'rasmph_pwr24 $2_$3.diff $2.rmli $7 - - - 1 1 1. .35 1 $2_$3.diff.bmp'

#+++++ generate coherence files +++++#
for i in `ls -1 | grep '.diff$'`
do
	master=$(echo "$i" | sed 's/_/ /g' | awk '{print $1}')
	slave=$(echo "$i" | sed 's/_/ /g' | sed 's/\./ /g' | awk '{print $2}')
	echo "cc_wave $i $master.rmli $slave.rmli ${master}_${slave}.cc $width $ran_look $azi_look 2 "
	cc_wave $i $master.rmli $slave.rmli ${master}_${slave}.cc $width $ran_look $azi_look 2
	echo "rascc ${master}_${slave}.cc $master.rmli $width"
	rascc ${master}_${slave}.cc $master.rmli $width
done
### for StaMPS end here

# filtering
#run_all batching_file 'adf $2_$3.diff $2_$3.diff2.flt $2_$3.diff2.cc $7 0.4 32 5 8 - - 0.2;rasmph_pwr24 $2_$3.diff2.flt $2.rmli $7 - - - 1 1 1. .35 1 $2_$3.diff2.flt.bmp'


cd $procdir
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
date "+%Y-%m-%d %H:%M:%S"
printf "\n\n\n"

