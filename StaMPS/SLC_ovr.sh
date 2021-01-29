#!/bin/sh

while read intf 
do 
  #tmp=`basename $intf`
  tep="$intf_over"
  SLC_ovr $intf $intf.par $tmp $tmp.par 2 1.5
done < filelist_rslc
