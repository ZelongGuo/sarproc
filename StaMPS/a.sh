#!/bin/bash


procdir="/misc/zs3/students/zelong_guo_temp2/"
reference=20180510

#------- preparation of directory and files ---------#
cd $procdir
mkdir -p INSAR_$reference
cp $my_shell/StaMPS/batching_stamps.m ./


# get the .lon and .lat files
cd $procdir/multi_looking

width_mli=$(cat $reference.mli.par | awk '/range_samples:/ {print $2} ')
line_mli=$(cat $reference.mli.par | awk '/azimuth_lines:/ {print $2} ')
width_EQA=$(cat EQA.$reference.dem_par | awk '/width:/ {print $2} ')

dem_coord EQA.$reference.dem_par east north
geocode EQA.$reference.lt_fine north $width_EQA $reference.lat $width_mli $line_mli 2 0 
geocode EQA.$reference.lt_fine east $width_EQA $reference.lon $width_mli $line_mli 2 0
#rm east north

mv east ../INSAR_$reference/geo/east
mv north ../INSAR_$reference/geo/north
mv ./$reference.lat ../INSAR_$reference/geo/$reference.lat
mv ./$reference.lon ../INSAR_$reference/geo/$reference.lon

