#!/bin/bash

# under $procdir there are 2 folders which represent different frames: F107 and F112
# F107 and F112 both have opod, table and data folders ('sh_gamma.sh s1 data data' have been finished.)
# you should run this script at the data folder of the 2 frame folders respectively
# NOTE some changes is needed, 1, 


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# firstly,change the files' name under the data folder, i.e. adding t?????? (the second)
# change the t?????? accordingly

#for i in `ls -1 | grep '^[0-9]'`
#do
#	first_part=$(echo "$i" | awk -F '.' '{print $1}')
#	second_part=$(echo "$i" | awk -F 'iw' '{print "iw" $2}')
#	new_file_name=$(echo "${first_part}t145146.${second_part}")
#
#	mv $i $new_file_name
#done




#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# secondly, generate the SLC_0_???????? and SLC_1_???????? files, similarly, under the data folder
# change to SLC_1_$i when running this script under another frame folder 

#mkdir -p slc_cat
#cd slc_cat
#
#slc_file=$(ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel')
#for i in `ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel' | awk -F 't' '{print $1}' | sort | uniq`
#do
#	touch SLC_1_$i
#	iw1_flag=$(echo "$slc_file" | grep "$i" | grep 'iw1')
#	if [ "x$iw1_flag" != "x" ]; then
#		slc=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep '\.slc$')
#		slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep 'slc\.par$')
#		slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep 'TOPS_par$')
#		echo "$slc $slc_par $slc_top" >> SLC_1_$i
#	fi
#	
#	iw2_flag=$(echo "$slc_file" | grep "$i" | grep 'iw2')
#	if [ "x$iw2_flag" != "x" ]; then
#		slc=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep '\.slc$')
#		slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep 'slc\.par$')
#		slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep 'TOPS_par$')
#		echo "$slc $slc_par $slc_top" >> SLC_1_$i
#	fi
#	
#	iw3_flag=$(echo "$slc_file" | grep "$i" | grep 'iw3')
#	if [ "x$iw3_flag" != "x" ]; then
#		slc=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep '\.slc$')
#		slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep 'slc\.par$')
#		slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep 'TOPS_par$')
#		echo "$slc $slc_par $slc_top" >> SLC_1_$i
#
#	fi
#done
#
#


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# then generate SLC_2_???????? file, run this under the data folder (under one of the frame data folder is OK)

#mkdir -p slc_cat_2
#cd slc_cat_2
#slc_file=$(ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel')
#for i in `ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel' | awk -F 't' '{print $1}' | sort | uniq`
#do
#	touch SLC_2_$i
#	iw1_flag=$(echo "$slc_file" | grep "$i" | grep 'iw1')
#	if [ "x$iw1_flag" != "x" ]; then
#		first_part=$(echo "$i")
#		echo "${i}.iw1.sel.slc ${i}.iw1.sel.slc.par ${i}.iw1.sel.slc.TOPS_par" >> SLC_2_$i
#	fi
#	
#	iw2_flag=$(echo "$slc_file" | grep "$i" | grep 'iw2')
#	if [ "x$iw2_flag" != "x" ]; then
#		first_part=$(echo "$i")
#		echo "${i}.iw2.sel.slc ${i}.iw2.sel.slc.par ${i}.iw2.sel.slc.TOPS_par" >> SLC_2_$i
#	fi
#	
#	iw3_flag=$(echo "$slc_file" | grep "$i" | grep 'iw3')
#	if [ "x$iw3_flag" != "x" ]; then
#		first_part=$(echo "$i")
#		echo "${i}.iw3.sel.slc ${i}.iw3.sel.slc.par ${i}.iw3.sel.slc.TOPS_par" >> SLC_2_$i
#
#	fi
#done


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# finally concatenate the data.
# mkdir data under $procdir and copy the SLC_[0-2]_????????, cd $procdir/data and run following:

for i in `ls -1 ../F107/data/ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel'`
do 
	ln -s ../F107/data/$i ./
done

for i in `ls -1 ../F112/data/ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel'`
do 
	ln -s ../F112/data/$i ./
done

for i in `ls -1 | sed 's/_/ /g' | awk -F ' ' '{print $NF}' | sort | uniq`
do 
	SLC_cat_ScanSAR SLC_0_$i SLC_1_$i SLC_2_$i
done
