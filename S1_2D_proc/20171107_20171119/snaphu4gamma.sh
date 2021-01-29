#!/bin/bash

dir=$1
master=$2
slave=$3
#dir="/misc/zs7/Zelong/EQ_DInSAR/20171107_20171119/"
#master=20171107
#slave=20171119
int=$dir/int_${master}_${slave}

width=`grep interferogram_width: $int/${master}_${slave}.off | awk '{print $2}'`
length=`grep interferogram_azimuth_lines: $int/${master}_${slave}.off | awk '{print $2}'`
row=`grep interferogram_azimuth_lines: $int/${master}_${slave}.off | awk '{print $2-1}'`
col=`grep interferogram_width: $int/${master}_${slave}.off | awk '{print $2-1}'`
pos=`grep sar_to_earth_center: $dir/$master/$master.slc.par | awk '{print $2}'`
earth=`grep earth_radius_below_sensor: $dir/$master/$master.slc.par | awk '{print $2}'`
alt=`echo $pos $earth | awk '{print $1-$2}'`

near=`grep near_range_slc: $dir/$master/$master.slc.par | awk '{print $2}'`
dr=`grep interferogram_range_pixel_spacing: $int/${master}_${slave}.off | awk '{print $2}'`
da_flight=`grep interferogram_azimuth_pixel_spacing: $int/${master}_${slave}.off | awk '{print $2}'`
da=`echo $da_flight $earth $alt| awk '{print $1*$2/($2+$3)}'`
rangeres=`grep range_pixel_spacing: $dir/$master/$master.slc.par | awk '{print $2}'`
azres=`grep azimuth_pixel_spacing: $dir/$master/$master.slc.par | awk '{print $2}'`
nrange=`grep interferogram_range_looks: $int/${master}_${slave}.off | awk '{print $2}'`
nazi=`grep interferogram_azimuth_looks: $int/${master}_${slave}.off | awk '{print $2}'`
ncor=`echo $dr $da $rangeres $azres | awk '{print $1*$2/($3*$4)}'`


rootname=${master}_${slave}


echo STATCOSTMODE         SMOOTH                 >  ${rootname}.snaphuconf
echo INFILE               ${rootname}.int       >>  ${rootname}.snaphuconf
echo LINELENGTH           $width                >>  ${rootname}.snaphuconf
echo OUTFILE              ${rootname}.unw       >>  ${rootname}.snaphuconf
echo CORRFILE             ${rootname}.cor       >>  ${rootname}.snaphuconf
echo LOGFILE              ${rootname}.snaphulog >>  ${rootname}.snaphuconf
echo                                            >>  ${rootname}.snaphuconf
echo PIECEFIRSTROW        1                     >>  ${rootname}.snaphuconf
echo PIECEFIRSTCOL        1                     >>  ${rootname}.snaphuconf
echo PIECENROW            $row                  >>  ${rootname}.snaphuconf
echo PIECENCOL            $col                  >>  ${rootname}.snaphuconf
echo ALTITUDE             $alt                  >>  ${rootname}.snaphuconf
echo EARTHRADIUS          $earth                >>  ${rootname}.snaphuconf
echo NEARRANGE            $near                 >>  ${rootname}.snaphuconf
echo BASELINE             0.000000              >>  ${rootname}.snaphuconf
echo BASELINEANGLE_DEG    0.000000              >>  ${rootname}.snaphuconf
echo TRANSMITMODE         REPEATPASS            >>  ${rootname}.snaphuconf
echo DR                   $dr                   >>  ${rootname}.snaphuconf
echo DA                   $da                   >>  ${rootname}.snaphuconf
echo RANGERES             $rangeres             >>  ${rootname}.snaphuconf
echo AZRES                $azres                >>  ${rootname}.snaphuconf
echo LAMBDA               0.0556                >>  ${rootname}.snaphuconf
echo NLOOKSRANGE          $nrange               >>  ${rootname}.snaphuconf
echo NLOOKSAZ             $nazi                 >>  ${rootname}.snaphuconf
echo NLOOKSOTHER          1                     >>  ${rootname}.snaphuconf
echo NCORRLOOKS           $ncor                 >>  ${rootname}.snaphuconf
echo                                            >>  ${rootname}.snaphuconf
echo CONNCOMPFILE         ${rootname}.byt       >>  ${rootname}.snaphuconf
echo MAXNCOMPS            32                    >>  ${rootname}.snaphuconf
echo                                            >>  ${rootname}.snaphuconf
echo INFILEFORMAT         COMPLEX_DATA          >>  ${rootname}.snaphuconf
echo OUTFILEFORMAT        ALT_LINE_DATA         >>  ${rootname}.snaphuconf
echo CORRFILEFORMAT       FLOAT_DATA            >>  ${rootname}.snaphuconf
echo VERBOSE              FALSE                 >>  ${rootname}.snaphuconf
#loadgamma

swap_bytes $int/${master}_${slave}.tflt_sm ${rootname}.int 4 > log

swap_bytes $int/${master}_${slave}.smcc ${rootname}.cor 4 >> log


#loadlroi3.1
echo "snaphu -f ${rootname}.snaphuconf"
#/data2/gyjiang/software/snaphu-v2.0.4/bin/snaphu -f ${rootname}.snaphuconf
snaphu -f ${rootname}.snaphuconf

xmin=1
ymin=1
xmax=$width
ymax=$length
new_width=`echo $xmax $xmin | awk '{print $1-$2}'`
unw_zero_file=${rootname}_zeropad.unw
mask_zero_file=${rootname}_mask_zeropad.unw
mask_zero_file_msk=${rootname}_mask_zeropad.msk
tobegeocodedm=${rootname}_masked.unw
unw_file=${rootname}_msk.unw

# PRL Changes to use Curtis' zero_pad program (now modified to handle the mask as well)
## Put back into original size (zeroed file image) with zeropad
npad_bottom=`echo $length $ymax | awk '{print $1-$2}'`
npad_right=`echo $width $xmax | awk '{print $1-$2}'`

##########################
echo "zeropad_msk ${rootname}.unw $new_width $ymin $xmin $npad_right $npad_bottom $unw_zero_file rmg"
zeropad_msk ${rootname}.unw $new_width $ymin $xmin $npad_right $npad_bottom $unw_zero_file rmg >> log

# replace the zero_pad zero mag with the original interferogram mag
##########################
echo "rmg2mag_phs $unw_zero_file /dev/null phs  $width"
rmg2mag_phs $unw_zero_file /dev/null phs  $width >> log

echo "swap_bytes phs phs4 4"
swap_bytes phs  phs4 4 >> log

echo "cpx2mag_phs ${rootname}.int pwr /dev/null $width"
cpx2mag_phs ${rootname}.int pwr /dev/null $width >> log

echo "mag_phs2rmg pwr phs $unw_zero_file $width"
mag_phs2rmg pwr phs $unw_zero_file $width >> log

# Now do the mask
##########################
echo "zeropad_msk ${rootname}.byt $new_width $ymin $xmin $npad_right ${npad_bottom} $mask_zero_file_msk msk"
zeropad_msk ${rootname}.byt $new_width $ymin $xmin $npad_right ${npad_bottom} $mask_zero_file_msk msk >> log

##########################
##########################
echo "cpx2mag_phs ${rootname}.int pwr phs $width"
cpx2mag_phs ${rootname}.int pwr phs $width >> log
  
##########################
echo "mag_phs2rmg pwr $mask_zero_file_msk $mask_zero_file $width"
mag_phs2rmg pwr $mask_zero_file_msk $mask_zero_file $width >> log

##########################
echo "rmg2mag_phs $unw_zero_file pwr phs1 $width"
rmg2mag_phs $unw_zero_file pwr phs1 $width >> log

echo "rmg2mag_phs $mask_zero_file /dev/null phs2 $width"
rmg2mag_phs $mask_zero_file /dev/null phs2 $width >> log

echo "add_phs phs1 phs2 phs3 $width $length 0 1"
add_phs phs1 phs2 phs3 $width $length 0 1 >> log

echo "add_phs pwr phs2 pwr3 $width $length 0 1"
add_phs pwr phs2 pwr3 $width $length 0 1 >> log

echo "mag_phs2rmg pwr3 phs3 $tobegeocodedm $width"
mag_phs2rmg pwr3 phs3 $tobegeocodedm $width >> log

echo "swap_bytes phs3 $unw_file 4"
swap_bytes phs3 $unw_file 4 >> log

mv phs4 $unw_zero_file

rm -rf pwr phs phs1 phs2 phs3 pwr3
                                                          
