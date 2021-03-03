#!/bin/bash

# This script is employed to read s1.cfg
# First version: 09/01/2020
# Last Edited: 09.09.2020
# Zelong Guo @GFZ, Potsdam


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ read config.table and define the variables +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
[ ! -e ./table/S1.cfg ] && echo "$0: S1.cfg is not existent! Please check it!!\n" && exit 1
S1_cfg=$(grep '^[^#]' ./table/S1.cfg | awk -F ';' '{print $1}')
# echo "$S1_cfg"
#procdir=$(echo "$S1_cfg" | grep 'set main/project path' | awk -F '=' '{print $NF}')
#datadir=$(echo "$S1_cfg" | grep 'set SAR data path' | awk -F '=' '{print $NF}')
#unzip_SAR_flag=$(echo "$S1_cfg" | grep 'unzipping SAR data' | awk -F '=' '{print $NF}')
opod_download_flag=$(echo "$S1_cfg" | grep 'opod downloading' | awk -F '=' '{print $NF}')
miss_type=$(echo "$S1_cfg" | grep 'mission type' | awk -F '=' '{print $NF}')
#opoddir=$(echo "$S1_cfg" | grep 'set opod path' | awk -F '=' '{print $NF}')
dem_download_flag=$(echo "$S1_cfg" | grep 'dem downloading' | awk -F '=' '{print $NF}')
dem_type=$(echo "$S1_cfg" | grep 'dem type' | awk -F '=' '{print $NF}')
#max_lat=$(echo "$S1_cfg" | grep 'maximum latitude' | awk -F '=' '{print $NF}')
#min_lat=$(echo "$S1_cfg" | grep 'minimum latitude' | awk -F '=' '{print $NF}')
#max_lon=$(echo "$S1_cfg" | grep 'maximum longitude' | awk -F '=' '{print $NF}')
#min_lon=$(echo "$S1_cfg" | grep 'minimum longitude' | awk -F '=' '{print $NF}')
disdem_flag=$(echo "$S1_cfg" | grep 'display dem' | awk -F '=' '{print $NF}')
#demdir=$(echo "$S1_cfg" | grep 'set dem path' | awk -F '=' '{print $NF}')
start_date=$(echo "$S1_cfg" | grep 'start date' | awk -F '=' '{print $NF}')
stop_date=$(echo "$S1_cfg" | grep 'stop date' | awk -F '=' '{print $NF}')
pol=$(echo "$S1_cfg" | grep 'set polarization' | awk -F '=' '{print $NF}')
m1_fswa=$(echo "$S1_cfg" | grep 'M1.first swath' | awk -F '=' '{print $NF}')
m1_lswa=$(echo "$S1_cfg" | grep 'M1.last swath' | awk -F '=' '{print $NF}')
m1_fbur=$(echo "$S1_cfg" | grep 'M1.first burst' | awk -F '=' '{print $NF}')
m1_lbur=$(echo "$S1_cfg" | grep 'M1.last burst' | awk -F '=' '{print $NF}')
m2_fswa=$(echo "$S1_cfg" | grep 'M2.first swath' | awk -F '=' '{print $NF}')
m2_lswa=$(echo "$S1_cfg" | grep 'M2.last swath' | awk -F '=' '{print $NF}')
m2_fbur=$(echo "$S1_cfg" | grep 'M2.first burst' | awk -F '=' '{print $NF}')
m2_lbur=$(echo "$S1_cfg" | grep 'M2.last burst' | awk -F '=' '{print $NF}')
disslc=$(echo "$S1_cfg" | grep 'display slc' | awk -F '=' '{print $NF}')
dissel=$(echo "$S1_cfg" | grep 'display sel.slc' | awk -F '=' '{print $NF}')
reference=$(echo "$S1_cfg" | grep 'reference image' | awk -F '=' '{print $NF}')
ran_look=$(echo "$S1_cfg" | grep 'number of range looks' | awk -F '=' '{print $NF}')
azi_look=$(echo "$S1_cfg" | grep 'number of azimuth looks' | awk -F '=' '{print $NF}')
dem_northover=$(echo "$S1_cfg" | grep 'dem northing oversampling' | awk -F '=' '{print $NF}')
dem_eastover=$(echo "$S1_cfg" | grep 'dem easting oversampling' | awk -F '=' '{print $NF}')
cp_sub=$(echo "$S1_cfg" | grep 'copy subset' | awk -F '=' '{print $NF}')
roff=$(echo "$S1_cfg" | grep 'offset to range' | awk -F '=' '{print $NF}')
nr=$(echo "$S1_cfg" | grep 'number of range samples' | awk -F '=' '{print $NF}')
loff=$(echo "$S1_cfg" | grep 'offset to azimuth' | awk -F '=' '{print $NF}')
nl=$(echo "$S1_cfg" | grep 'number of azimuth samples' | awk -F '=' '{print $NF}')
itab_type=$(echo "$S1_cfg" | grep 'itab type' | awk -F '=' '{print $NF}')
bperp_min=$(echo "$S1_cfg" | grep 'minimum bperp' | awk -F '=' '{print $NF}')
bperp_max=$(echo "$S1_cfg" | grep 'maximum bperp' | awk -F '=' '{print $NF}')
delta_T_min=$(echo "$S1_cfg" | grep 'minimum days between passes' | awk -F '=' '{print $NF}')
delta_T_max=$(echo "$S1_cfg" | grep 'maximum days between passes' | awk -F '=' '{print $NF}')


#++++++++++ deleting the blank space and Tab in the variables above +++++++++++#
# Note "" (e.g. echo "$unzip_SAR_flag") means more stricter format, in which blank space and/or Tab may be remained.
# sed 's/ //g' or sed 's/      //g' sometimes cannot work, still don't know why.
#procdir=$(echo $procdir)
#datadir=$(echo $datadir)
#unzip_SAR_flag=$(echo $unzip_SAR_flag)
opod_download_flag=$(echo $opod_download_flag)
miss_type=$(echo $miss_type)
#opoddir=$(echo $opoddir)
dem_download_flag=$(echo $dem_download_flag )
dem_type=$(echo $dem_type)
#max_lat=$(echo $max_lat)
#min_lat=$(echo $min_lat)
#max_lon=$(echo $max_lon)
#min_lon=$(echo $min_lon)
disdem_flag=$(echo $disdem_flag)
#demdir=$(echo $demdir)
start_date=$(echo $start_date)
stop_date=$(echo $stop_date)
pol=$(echo $pol)
m1_fswa=$(echo $m1_fswa)
m1_lswa=$(echo $m1_lswa)
m1_fbur=$(echo $m1_fbur)
m1_lbur=$(echo $m1_lbur)
m2_fswa=$(echo $m2_fswa)
m2_lswa=$(echo $m2_lswa)
m2_fbur=$(echo $m2_fbur)
m2_lbur=$(echo $m2_lbur)
disslc=$(echo $disslc)
dissel=$(echo $dissel)
reference=$(echo $reference)
ran_look=$(echo $ran_look)
azi_look=$(echo $azi_look)
dem_northover=$(echo $dem_northover)
dem_eastover=$(echo $dem_eastover)
cp_sub=$(echo $cp_sub)
roff=$(echo $roff)
nr=$(echo $nr)
loff=$(echo $loff)
nl=$(echo $nl)
itab_type=$(echo $itab_type)
bperp_min=$(echo $bperp_min)
bperp_max=$(echo $bperp_max)
delta_T_min=$(echo $delta_T_min)
delta_T_max=$(echo $delta_T_max)

#:<<ZL
##++++++++ checking and deleting '/' to the postfix of the directories +++++++++#
#postfix_path=$(echo "${procdir: -1}")
#[ "$postfix_path" == "/" ] && procdir=${procdir%/*}
#postfix_path=$(echo "${datadir: -1}")
#[ "$postfix_path" == "/" ] && datadir=${datadir%/*}
#postfix_path=$(echo "${opoddir: -1}")
#[ "$postfix_path" == "/" ] && opoddir=${opoddir%/*}
#postfix_path=$(echo "${demdir: -1}")
#[ "$postfix_path" == "/" ] && demdir=${demdir%/*}
#
##++++++++ replacing "$procdir" in opoddir and demdir with absolute path ++++++++#
## NOTE: "" should be used in sed if you want importing variables
##opoddir=$(echo $opoddir | sed "s/\$procdir/$PWD/g") # This can't work.
##demdir=$(echo $demdir | sed "s/\$procdir/$PWD/g") # This can't work.
## NOTE: eval represent excecuting twice
#opoddir=$(eval echo $opoddir)
#demdir=$(eval echo $demdir)
#
## datadir will be created in sh_prechecking.sh
#datadir=$procdir/data
#ZL
#
#:<<comment
#[ -e "vari.table" ] && rm vari.table && touch vari.table
##echo "procdir=$procdir" >> vari.table
##echo "datadir=$datadir" >> vari.table
##echo "unzip_SAR_flag=$unzip_SAR_flag" >> vari.table
#echo "opod_download_flag=$opod_download_flag"  >> vari.table
#echo "miss_type=$miss_type" >> vari.table
##echo "opoddir=$opoddir" >> vari.table
#echo "dem_download_flag=$dem_download_flag" >> vari.table
#echo "dem_type=$dem_type" >> vari.table
#echo "max_lat=$max_lat" >> vari.table
#echo "min_lat=$min_lat" >> vari.table
#echo "max_lon=$max_lon" >> vari.table
#echo "min_lon=$min_lon" >> vari.table
#echo "disdem_flag=$disdem_flag" >> vari.table
##echo "demdir=$demdir" >> vari.table
#echo "datadir=$datadir" >> vari.table
#echo "start_date=$start_date" >> vari.table
#echo "stop_date=$stop_date" >> vari.table
#echo "pol=$pol" >> vari.table
#echo "m1_fswa=$m1_fswa" >> vari.table
#echo "m1_lswa=$m1_lswa" >> vari.table
#echo "m1_fbur=$m1_fbur" >> vari.table
#echo "m1_lbur=$m1_lbur" >> vari.table
#echo "m2_fswa=$m2_fswa" >> vari.table
#echo "m2_lswa=$m2_lswa" >> vari.table
#echo "m2_fbur=$m2_fbur" >> vari.table
#echo "m2_lbur=$m2_lbur" >> vari.table
#echo "disslc=$disslc" >> vari.table
#echo "dissel=$dissel" >> vari.table
#echo "reference=$reference" >> vari.table
#echo "ran_look=$ran_look" >> vari.table
#echo "azi_look-$azi_look" >> vari.table
#echo "dem_northover=$dem_northover" >> vari.table
#echo "dem_eastover=$dem_eastover" >> vari.table
#echo "cp_sub=$cp_sub" >> vari.table
#echo "roff=$roff" >> vari.table
#echo "nr=$nr" >> vari.table
#echo "loff=$loff" >> vari.table
#echo "nl=$nl" >> vari.table
#echo "itab_type=$itab_type" >> vari.table
#echo "bperp_min=$bperp_min" >> vari.table
#echo "bperp_max=$bperp_max" >> vari.table
#echo "delta_T_min=$delta_T_min" >> vari.table
#echo "delta_T_max=$delta_T_max" >> vari.table
#comment
##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ reading table finished ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#
#
#
