#!/bin/bash
 
# Zelong Guo, 02.08.2022
version="02/08/2022"

if [ "$1" == "--help" ] || [ "$1" == "-help" ] || [ "$1" == "-h" ] || [ "$#" -lt "2"  ]; then
	cat<<END && exit 1 

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
  Concatenate the SLCs from different frames and output the files to data folder of current directory.
  (If there is no data folder in current directory, then it would be created automatically.)

  Program:		`basename $0`
  Written by:		Zelong Guo (GFZ, Potsdam)
  First version:	02/08/2022
  Last edited:		$version

  usage:		$(basename $0) <Frame Folder 1> <Frame Folder 2> <Object Folder> 
                
     <Frame Folder 1>:     (input) the frame folder in current directory, i.e., F477 which should contain the 
				   data, opod and table foldes in it after the running of sh_gamma * * data data 
     <Frame Folder 2>:     (input) the frame folder in current directory, i.e., F478 which should contain the 
				   data, opod and table foldes in it after the running of sh_gamma * * data data

  NEXT UPDATE: update the script to concatenate SLCs from more than TWO frames.
  NOTE: for now this command only support to concatenate the SLCs of TWO frames.
    
            CURRENT DIR: $PWD
  The files would be ouput to data folder of current directory, if there is no data folder, then it would be 
  created automatically.

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

END
fi 

#============ Inputting Parameters ==================#
# OPTIONS: data, ml, coreg, diff, stamps
FRAME1=$1
FRAME2=$2
#====================================================#
procdir=$PWD

# firstly check it there are the Frame foldes in current directory
if [ ! -d "$FRAME1" ]; then
	echo "$0: Frame Folder 1 ($FRAME1) does not exist, please check the folder name!" && exit 1
fi
if [ ! -d "$FRAME2" ]; then
	echo "$0: Frame Folder 2 ($FRAME2) does not exist, please check the folder name!" && exit 1
fi
if [ ! -d "data" ]; then
	echo "$0: data folder does not exist in current folder, so it is created automatically..."
	mkdir data
fi

#==================== Frame 1 =======================#
# Now working on Frame folder 1
#====================================================#
cd $FRAME1
if [ ! -d "data" ]; then
	echo "$0: data folder does not exist in Frame Folder 1 ($FRAME1), you should run sh_gamma.sh to get this folder firstly!" && exit 1
fi

cd data
# Now we rename the files in the data folder
time=`ls -1 | grep "^[A-Z][0-9]" | awk -F 'T' '{print $2}' | awk -F '_' '{print $1}' | head -n 1`
# To avoid to renaming the files multiple times
timecheck=`ls -1 | grep '^[0-9]' | awk -F '.' '{print $1}' | awk -F 't' '{print $2}' | head -n 1`
if [ "$time" != "$timecheck" ]; then
	for i in `ls -1 | grep '^[0-9]'`
	do
	       first_part=$(echo "$i" | awk -F '.' '{print $1}')
	       second_part=$(echo "$i" | awk -F 'iw' '{print "iw" $2}')
	       new_file_name=$(echo "${first_part}t${time}.${second_part}")
	       #echo "$i"
	       #echo "$new_file_name"
	
	       mv $i $new_file_name
	done
fi

# Now we generate the SLC_0_???????? in the slc_cat folder of curren frame folder
[ ! -d "slc_cat" ] && mkdir slc_cat                                                                                          
cd slc_cat

slc_file=$(ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel')
for i in `ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel' | awk -F 't' '{print $1}' | sort | uniq`
do
       [ -e "SLC_0_$i" ] && rm -f SLC_0_$i
       touch SLC_0_$i
       iw1_flag=$(echo "$slc_file" | grep "$i" | grep 'iw1')
       if [ "x$iw1_flag" != "x" ]; then
               slc=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep '\.slc$')
               slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep 'slc\.par$')
               slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep 'TOPS_par$')
               echo "$slc $slc_par $slc_top" >> SLC_0_$i
       fi
       
       iw2_flag=$(echo "$slc_file" | grep "$i" | grep 'iw2')
       if [ "x$iw2_flag" != "x" ]; then
               slc=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep '\.slc$')
               slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep 'slc\.par$')
               slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep 'TOPS_par$')
               echo "$slc $slc_par $slc_top" >> SLC_0_$i
       fi
       
       iw3_flag=$(echo "$slc_file" | grep "$i" | grep 'iw3')
       if [ "x$iw3_flag" != "x" ]; then
               slc=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep '\.slc$')
               slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep 'slc\.par$')
               slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep 'TOPS_par$')
               echo "$slc $slc_par $slc_top" >> SLC_0_$i

       fi
done

# Now we generate the SLC_2_???????? in the slc_cat folder of curren frame folder
for i in `ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel' | awk -F 't' '{print $1}' | sort | uniq`
do
       [ -e "SLC_2_$i" ] && rm -f SLC_2_$i
       touch SLC_2_$i
       iw1_flag=$(echo "$slc_file" | grep "$i" | grep 'iw1')
       if [ "x$iw1_flag" != "x" ]; then
               first_part=$(echo "$i")
               echo "${i}.iw1.sel.slc ${i}.iw1.sel.slc.par ${i}.iw1.sel.slc.TOPS_par" >> SLC_2_$i
       fi
       
       iw2_flag=$(echo "$slc_file" | grep "$i" | grep 'iw2')
       if [ "x$iw2_flag" != "x" ]; then
               first_part=$(echo "$i")
               echo "${i}.iw2.sel.slc ${i}.iw2.sel.slc.par ${i}.iw2.sel.slc.TOPS_par" >> SLC_2_$i
       fi
       
       iw3_flag=$(echo "$slc_file" | grep "$i" | grep 'iw3')
       if [ "x$iw3_flag" != "x" ]; then
               first_part=$(echo "$i")
               echo "${i}.iw3.sel.slc ${i}.iw3.sel.slc.par ${i}.iw3.sel.slc.TOPS_par" >> SLC_2_$i

       fi
done


#==================== Frame 2 =======================#
# Now working on Frame folder 2
#====================================================#
cd $procdir

cd $FRAME2
if [ ! -d "data" ]; then
	echo "$0: data folder does not exist in Frame Folder 2 ($FRAME2), you should run sh_gamma.sh to get this folder firstly!" && exit 1
fi

cd data
# Now we rename the files in the data folder
time=`ls -1 | grep "^[A-Z][0-9]" | awk -F 'T' '{print $2}' | awk -F '_' '{print $1}' | head -n 1`
# To avoid to renaming the files multiple times
timecheck=`ls -1 | grep '^[0-9]' | awk -F '.' '{print $1}' | awk -F 't' '{print $2}' | head -n 1`
if [ "$time" != "$timecheck" ]; then
	for i in `ls -1 | grep '^[0-9]'`
	do
	       first_part=$(echo "$i" | awk -F '.' '{print $1}')
	       second_part=$(echo "$i" | awk -F 'iw' '{print "iw" $2}')
	       new_file_name=$(echo "${first_part}t${time}.${second_part}")
	       #echo "$i"
	       #echo "$new_file_name"
	
	       mv $i $new_file_name
	done
fi

# Now we generate the SLC_1_???????? in the slc_cat folder of curren frame folder
[ ! -d "slc_cat" ] && mkdir slc_cat                                                                                          
cd slc_cat

slc_file=$(ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel')
for i in `ls -1 ../ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel' | awk -F 't' '{print $1}' | sort | uniq`
do
       [ -e "SLC_1_$i" ] && rm -f SLC_1_$i
       touch SLC_1_$i
       iw1_flag=$(echo "$slc_file" | grep "$i" | grep 'iw1')
       if [ "x$iw1_flag" != "x" ]; then
               slc=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep '\.slc$')
               slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep 'slc\.par$')
               slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw1' | grep 'TOPS_par$')
               echo "$slc $slc_par $slc_top" >> SLC_1_$i
       fi
       
       iw2_flag=$(echo "$slc_file" | grep "$i" | grep 'iw2')
       if [ "x$iw2_flag" != "x" ]; then
               slc=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep '\.slc$')
               slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep 'slc\.par$')
               slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw2' | grep 'TOPS_par$')
               echo "$slc $slc_par $slc_top" >> SLC_1_$i
       fi
       
       iw3_flag=$(echo "$slc_file" | grep "$i" | grep 'iw3')
       if [ "x$iw3_flag" != "x" ]; then
               slc=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep '\.slc$')
               slc_par=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep 'slc\.par$')
               slc_top=$(echo "$slc_file" | grep "$i" | grep 'iw3' | grep 'TOPS_par$')
               echo "$slc $slc_par $slc_top" >> SLC_1_$i

       fi
done


#====================================================#
# Finally we concatenate the data.
# if there is no data folder, we would create it under
# the curent directory.
#====================================================#
cd $procdir
[ ! -d "data" ] && mkdir data
cd data
rm -f *

# link the files in frame 1 and frame 2 to current data folder
for i in `ls -1 ../$FRAME1/data/ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel'`
do
	ln -s ../$FRAME1/data/$i ./
done
for i in `ls -1 ../$FRAME2/data/ | grep '^[0-9]' | grep -v 'bmp' | grep 'sel'`
do
	ln -s ../$FRAME2/data/$i ./
done

# move the fiels in slc_cat folder of Frame1 and Frame2 to current data folder
mv ../$FRAME1/data/slc_cat/* ./
mv ../$FRAME2/data/slc_cat/* ./
# link the origial sentinel data to current data folder
ln -s ../$FRAME1/data/S1* ./
ln -s ../$FRAME2/data/S1* ./

for i in `ls -1 SLC* | sed 's/_/ /g' | awk -F ' ' '{print $NF}' | sort | uniq`
do
        SLC_cat_ScanSAR SLC_0_$i SLC_1_$i SLC_2_$i
done

cd $procdir





