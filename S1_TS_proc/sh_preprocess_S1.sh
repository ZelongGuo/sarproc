#!/bin/bash

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# pre-checking the files needed (data, oppd and dem).
# This script need to be used in sh_gamma.sh, cannot run independently
# This script need to call for sh_grep_S1_dates.sh, to link the SAR data you need from ori_SARdir to procdir
# Zelong Guo, @GFZ
# zelong@gfz-potsdam.de
# First Version: 10/12/2020
# last edited: 31/12/2020
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#++++++++++++++++++++++++++++++ application +++++++++++++++++++++++++++++
# applied in: 
#   1. sh_gamma.sh
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

echo "sh_preprocess_S1.log"
printf "Now the executing directory is %s\n" $PWD

miss_type=$(echo "$miss_type" | tr 'A-Z' 'a-z')

#++++++++++++++++++++++++++++++++++++++++++++ checking data folder under $procdir and unzip files if needed +++++++++++++++++++++++++++++++++++++++++++#
[ ! -d data ] && echo "$0: The SAR data directory is inexistent! Please check it!\n" && exit 1
printf "\n"
echo "Now working with the data folder..."
echo "Now checking if the files need to be unzip or not..."

cd data

file_zip=$(ls -1 S1?_IW_SLC*.zip)
if [ "x$file_zip" != "x" ]; then
    for i in $file_zip
    do
            unzip $i
            rm -rf $i >/dev/null
    done
fi

echo "Checking and unzipping data folder is finished."

cd ..

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ extracting start and stop dates you choosed +++++++++++++++++++++++++++++++++++++++++++++++++++++++#
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
echo "Now extracting the start and stop dates from data folder..."
# fork is used here, please note fork do not return the variables to the main shell, which is different with source
# here just the file (grep_dates_s1*) is generated
# if $miss_type is not existent in $ori_SARdir, an error would be throwd and exit
echo "sh_grep_S1_dates data $start_date $stop_date $miss_type"
sh_grep_S1_dates data $start_date $stop_date $miss_type
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
printf "sh_grep_S1_dates is finished.\n"

#++++++++++++++++++++++++++++++++++++++ checking the existence of opod folder and downloading orbit files if necessary ++++++++++++++++++++++++++++++++++++++++#
printf "\n"
echo "Now working with the opod folder..."
if [ "$opod_download_flag" == "Y" ] || [ "$opod_download_flag" == "YES" ] || [ "$opod_download_flag" == "y" ] || [ "$opod_download_flag" == "yes" ]; then
	mkdir -p opod
	empty_flag=$(ls opod)
	if [ "x$empty_flag" == "x" ]; then
		echo "Now downloading the opod orbit files..."
		
		cd opod
		if [ "$miss_type" == "s1a" ]; then
            echo "sh_get_S1_opod $miss_type ../grep_dates_s1a"
			sh_get_S1_opod $miss_type ../grep_dates_s1a
			#cp ./sh_################################################################
			[ -d "../table" ] && mv sh_get_S1_opod.log  ../table
			
		elif [ "$miss_type" == "s1b" ]; then
			echo "sh_get_S1_opod $miss_type ../grep_dates_s1b"
			sh_get_S1_opod $miss_type ../grep_dates_s1b
			[ -d "../table" ] && mv sh_get_S1_opod.log ../table
			
		elif [ "$miss_type" == "both" ]; then
			[ -e "grep_dates_s1" ] && rm grep_dates_s1
			cat ../grep_dates_s1a > grep_dates_s1
			cat ../grep_dates_s1b >> grep_dates_s1
			sh_get_S1_opod $miss_type grep_dates_s1
			[ -d "../table" ] && mv sh_get_S1_opod.log  ../table
			rm grep_dates_s1 
		else
			echo "$0: ERROR with mission type!! Please check it!!" && echo "" && exit 1
		fi
		cd ..
	else
		printf "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
		echo "$0: The opod folder is not empty, please check if the orbit files are already existed, or empty the folder!"
		exit 1
	fi
elif [ "$opod_download_flag" == "N" ] || [ "$opod_download_flag" == "NO" ] || [ "$opod_download_flag" == "n" ] || [ "$opod_download_flag" == "no" ]; then
	if [ -d opod  ]; then
		empty_flag=$(ls opod)
		[ "x$empty_flag" == "x"  ] && echo "$0: OPOD orbit files do not exsit, please check it in opod folder and choose downloading them in configure table!!"
	fi
else
	echo "$0: ERROR with the opod downloading flag, pleaae check it in the config.table!!" && exit 1
fi
echo "Cheking opod folder is finished. "

#++++++++++++++++++++++++++++++++++++++++++++ checking the existence of dem folder and downloading DEM if necessary +++++++++++++++++++++++++++++++++++++++++++#
printf "\n"
echo "Now working with the dem folder..."
if [ "$dem_download_flag" == "Y" ] || [ "$dem_download_flag" == "YES" ] || [ "$dem_download_flag" == "y" ] || [ "$dem_download_flag" == "yes" ]; then
	mkdir -p dem
	empty_flag=$(ls dem)
	if [ "x$empty_flag" == "x" ]; then
		echo "Now downloading the dem files..."
		cd dem
		echo "sh_get_dem $max_lat $min_lat $max_lon $min_lon $dem_type $disdem_flag"
		sh_get_dem $max_lat $min_lat $max_lon $min_lon $dem_type $disdem_flag
		cd ..
	else 
		printf "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
		echo "$0: The dem folder is not empty, please check if the dem files are already existed, or empty the folder!" && exit 1
		exit 1
	fi
elif [ "$dem_download_flag" == "N" ] || [ "$dem_download_flag" == "NO" ] || [ "$dem_download_flag" == "n" ] || [ "$dem_download_flag" == "no" ]; then
	if [ -d dem ]; then
		empty_flag=$(ls dem)
		if [ "x$empty_flag" == "x" ]; then
			echo "$0: DEM files do not exsit, please check it in dem folder and choose downloading them in configure table!!"
		fi
	else
		echo "$0: Note: the dem directory is not existed! Please check it!!"
	fi
else
	echo "$0: ERROR with the DEM downloading, please check it in the config.table!!" && exit 1
fi

echo "Checking dem folder is finished."
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
date "+%Y-%m-%d %H:%M:%S"
printf "\n\n\n"
