#!/bin/csh -f

#*************************************************#
# process_2pass.csh:                              #
# c shell script for 2-pass DInSAR processing by  #
# GAMMA software with ERS SLC data.               #
#                                                 #
# author: Hua Wang                                #
# version: v1.0                                   #
# last updated: 07/22/2006                        #
# create date: 10/03/2005                         #
#*************************************************#

set PRG = process_2pass.csh
set VER = v1.0
set AUT = "Hua Wang"
set DAT = `date`
set EMP = ""
set EQ  = "======================================="

echo "    Program:" $PRG $VER 
echo "    Author:"  $AUT
echo "    Running on" $DAT
echo $EQ

#=================================================#
#             Check for the pathes                #
#=================================================#
if( $#argv < 4 ) then
    cat << END_OF_USAGE
    ***************************************************
    * process_2pass.csh:                              *
    * two-pass DInSAR processing c shell scripte for  *
    * GAMMA software with ESR SLC data.               *
    *                                                 *
    * author: Hua Wang                                *
    * version: v1.0                                   *
    * last updated: 07/22/2006                        *
    * create date: 10/03/2005                         *
    ***************************************************
    USAGE: processs_2pass.csh <mas_dir> <slv_dir> <dem_dir> <dem>
                              [pmin][pmax][lmin][lmax][extw][extl][FS]
                              [rlks][azlks][begs][ends]
    <mas_dir>: master image directory
    <slv_dir>: slave image directory
    <dem_dir>: dem data directory
    <dem>:     dem file name
    [pmin], [pmax]: mininum/maxmum column number
               if pmin = -, pmin = 0
               if pmax = -, pmax use the maximum column number
    [lmin], [lmax]: mininum/maxmum line number
               if lmin = -, lmin = 0
               if lmax = -, lmax use the maximum line number
    [extw], [extl]: extension of slave image relative to master image in width and lines
    [FS]:      F/S(flag) scene, to determine whether the SLC_copy is needed
               if FS=F, or FS=-, or $#argv < 9, SLC_copy is ignored,
               otherwise, subimage flag should be given, and SLC_copy is used.
    [rlks], [azlks]: range looks and azimuth looks
    [begs]:    begin step [GSLC/EXTRACT/COREG/INT/BASE/GCMAP/SIM/DIFF/FILT/DERAMP/UNW]
    [ends]:    end step [EXTRACT/COREG/INT/BASE/GCMAP/SIM/DIFF/FILT/DERAMP/UNW/END]
END_OF_USAGE
    exit 1
endif

#=========================================#
#     Checking for options                #
#=========================================#
echo "Checking for options......"

set mas = $1                            #master image name        e.g. 990208 
set slv = $2                            #slave image name         e.g. 990802
set mas_slv = "${mas}_${slv}"           #master_slave             e.g. 990208_990802
set intLog = "int.log"                  #processing log file
set offLog = "off.log"                  #master&slave offset estimation log file
set simLog = "sim.log"                  #master&dem offset estimation log file
set unwLog = "unw.log"                  #phase unwrapping log file

setenv PRJDIR `pwd`                     #project directory
setenv MASDIR $PRJDIR/$mas              #master directory         e.g. 990208
setenv SLVDIR $PRJDIR/$slv              #slave directory          e.g. 990802
setenv DEMDIR $PRJDIR/$3                #DEM directory            e.g. DEM
setenv SIMDIR $PRJDIR/SIM               #simulation directory     e.g. SIM
setenv INTDIR $PRJDIR/int_${mas_slv}    #interferometry directory e.g. int_990208_990802
setenv OFFDIR $PRJDIR/offset_map        #offset map directory     e.g. OFFMAP
setenv UNWDIR $PRJDIR/UNW               #unwrapped directory      e.g. UNW

set DEM     = $4                        #DEM data file name

set rasrlks   =  1                      #range looks for raster image
set rasazlks  =  1                      #azimuth looks for raster image

#Full scene/subscene
if( $#argv < 11 || ${11} == "-" || ${11} == "F" ) then
   set sub     = $EMP                   #symbol of subimage
   set mas_slc = ${mas}.slc             #master sub slc image     e.g. 990208.slc
   set slv_slc = ${slv}.slc             #slave sub slc image      e.g. 990802.slc
else
   set sub     = ${11}                    #symbol of subimage       e.g. tah
   set mas_slc = ${mas}.${sub}.slc      #master sub slc image     e.g. 990208.tah.slc
   set slv_slc = ${slv}.${sub}.slc      #slave sub slc image      e.g. 990802.tah.slc
endif



#range and azimuth looks
if( $#argv < 12 || ${12} == "-" ) then
   set rlks = 2
else
   set rlks = ${12}
endif
if( $#argv < 13 || ${13} == "-" ) then
   set azlks = 10
else
   set azlks = ${13}
endif

#Process begin step
if( $#argv < 14 || ${14} == "-" ) then
    set BEGS = "BEG"
else
    set BEGS = ${14}
endif

#Process end step
if( $#argv < 15 || ${15} == "-" ) then
    set ENDS = "END"
else
    set ENDS = ${15}
endif


#check the directory
if(!(-e $MASDIR)) then
    echo "The master image directory is not exist, "
    echo "plase create the linkages, or copy the slc"
    echo "data!"
    exit 0
endif

if(!(-e $SLVDIR)) then
    echo "The slave image directory is not exist, "
    echo "plase create the linkages, or copy the slc"
    echo "data!"
    exit 0
endif

if(!(-e $DEMDIR)) then
    echo "The DEM data directory is not exist, "
    echo "plase create the linkages, or copy the DEM"
    echo "data!"
    exit 0
endif

echo "Checking options finished!"
echo $EQ

#==============================================#
#    Full scene, ignore extract                #
#==============================================#
if($BEGS == "GSLC" && $sub == $EMP) then
   echo "Full scene is used."
   set BEGL = $BEGS
   set BEGS = "EXTRACT"
   echo $EMP
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif

#========================================================#
#    Extract part scene                                  #
# 1. Extract master image                                #
# 2. Extract slave image                                 #
# Note: can be ignored if full scene is used,            #
#       i.e. argv[11] = F                                #
#========================================================#
   
if($BEGS == "GSLC") then

   #======================================#
   # extract master image                 # 
   #======================================#
   cd $MASDIR

   echo $EQ
   echo "Extract part scene from the full scene......"
   echo $EMP

   set slcw = `grep range_samples: ${mas}.slc.par | awk '{print $2}'`
   set slcl = `grep azimuth_lines: ${mas}.slc.par | awk '{print $2}'`
   set sfmt = `grep image_format:  ${mas}.slc.par | awk '{print $2}'`

   if($sfmt == "SCOMPLEX") then
       set fcase = 4 #fcase for the command SLC_copy
   else
       set fcase = 2 # fcase for the command SLC_copy
   endif
   
   #subimage range/azimuth dimension
   #minimum range
   if( $#argv < 5 || $5 == "-" || $5 < 1 ) then
       set pmin = 1
   else
       set pmin = $5
   endif

   #maximum sample
   if( $#argv < 6 || $6 == "-" || $slcw < $6 ) then
       set pmax = ${slcw}
   else
       set pmax = $6
   endif

   # sample number
   @ np = ($pmax - $pmin) + 1

   #minimum line
   if( $#argv < 7 || $7 == "-" ) then
       set lmin = 1
   else
       set lmin = $7
   endif

   #maximum line
   if( $#argv < 8 || $8 == "-" || $slcl < $8 ) then
       set lmax = ${slcl}
   else
       set lmax = $8
   endif
   
   #extension of width of slave relative to master
   if( $#argv < 9 || $9 == "-" ) then
       set extw = 0
   else
       set extw = $9
   endif

   #extension of length of slave relative to master
   if( $#argv < 10 || ${10} == "-" ) then
       set extl = 0
   else
       set extl = ${10}
   endif

   # line number
   @ nl = ($lmax - $lmin) + 1
   
   #clip master image to subimage
   echo "SLC_copy ${mas}.slc ${mas}.slc.par $mas_slc ${mas_slc}.par $fcase - $pmin $np $lmin $nl"
   SLC_copy ${mas}.slc ${mas}.slc.par $mas_slc ${mas_slc}.par $fcase - $pmin $np $lmin $nl >> $PRJDIR/$intLog
   echo $EMP
   
   echo "rasSLC $mas_slc $np 1 0 $rasrlks $rasazlks 1 0.35 1 1 0 ${mas_slc}.ras"
   #rasSLC $mas_slc $np 1 0 $rasrlks $rasazlks 1 0.35 1 1 0 ${mas_slc}.ras >> $PRJDIR/$intLog
   echo $EMP

   #======================================#
   # extract slave image                  # 
   #======================================#

   cd $SLVDIR

   # maximum pixel for slave
   set slcw_slv = `grep range_samples: ${slv}.slc.par | awk '{print $2}'`
   set slcl_slv = `grep azimuth_lines: ${slv}.slc.par | awk '{print $2}'`
   set sfmt_slv = `grep image_format:  ${slv}.slc.par | awk '{print $2}'`

   if($sfmt_slv == "SCOMPLEX") then
       set fcase_slv = 4 #fcase for the command SLC_copy
   else
       set fcase_slv = 2 # fcase for the command SLC_copy
   endif

   if($pmax + $extw < $slcw_slv) then
   @ pmax_slv = $pmax + $extw
   else
       @ pmax_slv = $slcw_slv
   endif
   # minimum pixel for slave
   if($pmin - $extw > 1) then
       @ pmin_slv = $pmin - $extw
   else
       @ pmin_slv = 1
   endif
   # sample number
   @ np_slv   = ($pmax_slv - $pmin_slv) + 1
   
   # maximum line for slave
   if($lmax + $extl < $slcl_slv) then
       @ lmax_slv = $lmax + $extl
   else
       @ lmax_slv = $slcl_slv
   endif
   # minimum line for slave
   if($lmin - $extl > 1) then
   @ lmin_slv = $lmin - $extl
   else
       @ lmin_slv = 1
   endif
   # line number
   @ nl_slv   = ($lmax_slv - $lmin_slv) + 1
   
   #clip slave image to subimage
   echo "SLC_copy ${slv}.slc ${slv}.slc.par $slv_slc ${slv_slc}.par $fcase_slv - $pmin_slv $np_slv $lmin_slv $nl_slv"
   SLC_copy ${slv}.slc ${slv}.slc.par $slv_slc ${slv_slc}.par $fcase_slv - $pmin_slv $np_slv $lmin_slv $nl_slv >> $PRJDIR/$intLog
   echo $EMP
   
   echo "rasSLC $slv_slc $np_slv 1 0 $rasrlks $rasazlks 1 0.35 1 1 0 ${slv_slc}.ras"
   #rasSLC $slv_slc $np_slv 1 0 $rasrlks $rasazlks 1 0.35 1 1 0 ${slv_slc}.ras >> $PRJDIR/$intLog
   echo $EMP
   
   set BEGL = $BEGS
   set BEGS = "EXTRACT"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif   #end EXTRACT


#============================================#
#  Coregistration between master & slave    #
# 1. coarse coregistration by orbit          #
# 2. init coregistration by pwr estimation   #
# 3. fine coregistration by pwr estimation   #
# 4. offset polynominal fit                  #
# ??? other method
#============================================#

if($BEGS == "EXTRACT") then
#begin coregistration

   echo $EQ
   echo "Coregistration master VS slave SLC image......"
   echo $EMP
   
   if(!(-e $INTDIR)) then
      mkdir $INTDIR
   endif
   
   cd $INTDIR
   
   #delete offset parameter file (important!)
   if(-e ${mas_slv}.off) then
       rm -f ${mas_slv}.off
   endif
   
   #create offset parameter file
   set np = `grep range_samples: $MASDIR/${mas_slc}.par | awk '{print $2}'`
   /bin/echo -e "$mas_slv\n0 0\n32 32\n128 128\n0.5\n0\n$np" > create_offset.in
   #
   echo "create_offset $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off 1 $rlks $azlks 0"
   create_offset $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off 1 $rlks $azlks 0 < create_offset.in > $INTDIR/${offLog}
   echo $EMP
   echo $EMP
   rm -f create_offset.in
   
   #coarse offset estimation by orbit (optional)
   echo "init_offset_orbit $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off"
   #init_offset_orbit $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off  >> $INTDIR/${offLog}
   echo $EMP
   
   #coarse offset estimation by pwr correlation (optional)
   echo "init_offset $MASDIR/$mas_slc $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off 1 1"
   #init_offset $MASDIR/$mas_slc $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off 1 1 >> $INTDIR/$offLog
   echo $EMP
   
   
   #fine offset estimation by pwr correlation (recommend)
   echo "offset_pwr $MASDIR/$mas_slc $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off offs snr 512 512 offsets 2 32 32 0.7"
   #offset_pwr $MASDIR/$mas_slc $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off offs snr 512 512 offsets 2 32 32 0.7 >> $INTDIR/$offLog
   echo $EMP
   
   #offset polynominal fit (recommend)
   echo "offset_fit offs snr ${mas_slv}.off coffs coffsets 0.7 3 0"
   #offset_fit offs snr ${mas_slv}.off coffs coffsets 0.7 3 0 >> $INTDIR/$offLog
   echo $EMP
   
   #once more for fine coregistration and offset polynominal fit (necessary)
   echo "offset_pwr $MASDIR/$mas_slc $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par  $SLVDIR/${slv_slc}.par ${mas_slv}.off offs snr 256 256 offsets 2 64 64 1.0"
   #offset_pwr $MASDIR/$mas_slc $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off offs snr 256 256 offsets 2 64 64 1.0 >> $INTDIR/$offLog
   echo $EMP
   
   #offset polynominal fit (necessary)
   echo "offset_fit offs snr ${mas_slv}.off coffs coffsets 1.0 4 0"
   #offset_fit offs snr ${mas_slv}.off coffs coffsets 1.0 4 0 >> $INTDIR/$offLog
   echo $EMP

   echo "rm -f offs snr offsets coffs coffsets"
   rm -f offs snr offsets coffs coffsets
   echo $EMP
   
   set resample_slc = 0
   if($resample_slc == 1) then
     set slv_rslc=${slv}.rslc
      
     echo "SLC_interp $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SLVDIR/${slv_rslc} $SLVDIR/${slv_rslc}.par" 
     SLC_interp $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SLVDIR/${slv_rslc} $SLVDIR/${slv_rslc}.par >> offset.log
     echo $EMP
     echo $EMP 
     
     cp -rf $SLVDIR/${slv_rslc} $SLVDIR/${slv_rslc}_2
     cp -rf $SLVDIR/${slv_rslc}.par $SLVDIR/${slv_rslc}_2.par

     #create offset parameter file
     set np = `grep range_samples: $MASDIR/${mas_slc}.par | awk '{print $2}'`
     /bin/echo -e "$mas_slv\n0 0\n32 32\n128 128\n0.3\n0\n$np" > create_offset.in
     #
     echo "create_offset $MASDIR/${mas_slc}.par $SLVDIR/${slv_rslc}.par ${mas_slv}_rf.off 1"
     create_offset $MASDIR/${mas_slc}.par $SLVDIR/${slv_rslc}.par ${mas_slv}_rf.off 1 < create_offset.in >> offset.log
     echo $EMP
     echo $EMP
     rm -f create_offset.in
     
     #fine offset estimation by pwr correlation (recommend)
     echo "offset_pwr $MASDIR/$mas_slc $SLVDIR/${slv_rslc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_rslc}.par ${mas_slv}_rf.off offs snr 32 64 offsets 2 1024 1024 0.3"
     offset_pwr $MASDIR/$mas_slc $SLVDIR/${slv_rslc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_rslc}.par ${mas_slv}_rf.off offs snr 32 64 offsets 2 1024 1024 0.3 >> offset.log
     echo $EMP
     
     #offset polynominal fit (recommend)
     echo "offset_fit offs snr ${mas_slv}_rf.off coffs coffsets 0.3 4 0"
     offset_fit offs snr ${mas_slv}_rf.off coffs coffsets 0.3 4 0 >> offset.log
     echo $EMP
     
     set np = `grep offset_estimation_range_samples: ${mas_slv}_rf.off | awk '{print $2}'`
     
     #fills the holes
     echo "interp_ad coffs coffs_rf $np 32 16 32 2 0"
     interp_ad coffs coffs_rf $np 32 16 32 2 0 >> offset.log
     echo $EMP
     echo $EMP

     echo "cpx_to_real coffs_rf real $np 0"
     cpx_to_real coffs_rf real $np 0 >> offset.log
     echo $EMP

     echo "cpx_to_real coffs_rf imag $np 1"
     cpx_to_real coffs_rf imag $np 1 >> offset.log
     echo $EMP

     echo "median_filter real real_f $np 9"
     median_filter real real_f $np 9 >> offset.log
     echo $EMP

     echo "median_filter imag imag_f $np 9"
     median_filter imag imag_f $np 9 >> offset.log
     echo $EMP

     echo "real_to_cpx real_f imag_f coffs_sm $np 0"
     real_to_cpx real_f imag_f coffs_sm $np 0 >> offset.log
     echo $EMP
     
     # interp refine
     echo "SLC_interp_map $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/$slv_slc.par ${mas_slv}.off $SLVDIR/${slv_rslc} $SLVDIR/${slv_rslc}.par ${mas_slv}_rf.off coffs_sm"
     SLC_interp_map $SLVDIR/$slv_slc $MASDIR/${mas_slc}.par $SLVDIR/$slv_slc.par ${mas_slv}.off $SLVDIR/${slv_rslc} $SLVDIR/${slv_rslc}.par ${mas_slv}_rf.off coffs_sm >> offset.log
     echo $EMP
     echo $EMP
     
   endif
   
   echo "rm -f offs snr offsets coffs coffsets"
   rm -f offs coffs
   echo $EMP
      
   set BEGL = $BEGS
   set BEGS = "COREG"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif   #end coregistration

   
#===========================================#
#    Interferogram generation               #
# 1. interferogram generation by interf_SLC #
#    other method ????                      #
#===========================================#

if($BEGS == "COREG") then

   echo $EQ
   echo "Interferogram generation ......"
   echo $EMP

   cd $INTDIR

   #Note: don't create $mas_slv.pwr1 and $mas_slv.pwr2 image, using - - for them
   echo "interf_SLC $MASDIR/$mas_slc $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off - - ${mas_slv}.int $rlks $azlks"
   #interf_SLC $MASDIR/${mas_slc} $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par  $SLVDIR/${slv_slc}.par ${mas_slv}.off - - ${mas_slv}.int $rlks $azlks >> $PRJDIR/$intLog
   echo $EMP

   echo "SLC_intf $MASDIR/$mas_slc $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off ${mas_slv}.int $rlks $azlks"
   #SLC_intf $MASDIR/$mas_slc $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off ${mas_slv}.int $rlks $azlks >> $PRJDIR/$intLog
   echo $EMP
   
   #to get multi-look intensity image parameter, create pwr1 and its parameter
   #set loff = `grep slc1_starting_azimuth_line: ${mas_slv}.off | awk '{print $2}'`
   #set nltot = `grep interferogram_azimuth_lines: ${mas_slv}.off | awk '{print $2}'`
   #@ loff *= $azlks
   #@ nltot *= $azlks
   set loff = -
   set nltot = -
   echo "multi_look $MASDIR/$mas_slc $MASDIR/$mas_slc.par $mas_slv.pwr1 $mas_slv.pwr1.par $rlks $azlks $loff $nltot"
   multi_look $MASDIR/$mas_slc $MASDIR/$mas_slc.par $mas_slv.pwr1 $mas_slv.pwr1.par $rlks $azlks $loff $nltot >> $PRJDIR/$intLog
   echo $EMP

   echo "multi_look $SLVDIR/${slv_slc} $SLVDIR/${slv_slc}.par $mas_slv.pwr2 $mas_slv.pwr2.par $rlks $azlks $loff $nltot"
   multi_look $SLVDIR/${slv_slc} $SLVDIR/${slv_slc}.par $mas_slv.pwr2 $mas_slv.pwr2.par $rlks $azlks $loff $nltot >> $PRJDIR/$intLog
   echo $EMP
   
   #raster interferogram
   set np = `grep interferogram_width: ${mas_slv}.off | awk '{print $2}'`
   echo "rasmph_pwr ${mas_slv}.int ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks 1 0.35 1"
   #rasmph_pwr ${mas_slv}.int ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks 1 0.35 1 >> $PRJDIR/$intLog
   echo $EMP
   #raster pwr1
   echo "rasmph_pwr ${mas_slv}.pwr1 $np 1 0 $rasrlks $rasazlks 1 0.35 1"
   raspwr ${mas_slv}.pwr1 $np 1 0 $rasrlks $rasazlks 1 0.35 1 >> $PRJDIR/$intLog
   echo $EMP

   set BEGL = $BEGS
   set BEGS = "INT"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif   #end interferogram generation

#===========================================#
#    Calculate baseline                     #
# 1. calculate baseline from orbit          #
# 2. calculate perpendicular baseline       #
#    other method ????                      #
#===========================================#

#begin baseline calculation
if( $BEGS == "INT" ) then

   echo $EQ
   echo "Baseline calcualtion ......"
   echo $EMP

   cd $INTDIR

   #echo "base_init $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off ${mas_slv}.int ${mas_slv}.base 0"
   #base_init $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off ${mas_slv}.int ${mas_slv}.base 0>> $PRJDIR/$intLog
   #echo $EMP

   echo "base_init $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off - ${mas_slv}.base 0"
   base_init $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off - ${mas_slv}.base 0>> $PRJDIR/$intLog
   echo $EMP
   

   echo "base_perp ${mas_slv}.base $MASDIR/${mas_slc}.par  ${mas_slv}.off "
   base_perp ${mas_slv}.base $MASDIR/${mas_slc}.par  ${mas_slv}.off > ${mas_slv}.base.perp
   echo $EMP

   set BEGL = $BEGS
   set BEGS = "BASE"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif   #end coregistration

#===========================================#
#    Interferogram simulation               #
# 1. Extract DEM and simulate intensity     #
#    image in UTM coordinate system         #
# 2. Geocode simulated image to SAR coord.  #
#    system.                                #
# 3. Offset estimation between simulated    #
#    image and SAR intensity image          #
# 4. Offset polynomial fitting              #
# 5. Refine coregistration look-up table    #
# 6. Geocode DEM into SAR coord. system     #
#===========================================#
#begin interferogram simulation
if( $BEGS == "BASE" ) then
   
   echo $EQ
   echo "Simulation rough lookup table......"
   echo $EMP

   if(!(-e $SIMDIR)) then
      mkdir $SIMDIR
   endif

   cd $SIMDIR

   set gc_map_method = 1

   #extract part of DEM, and simulate the intensity image in MAP coordinate system
   if($gc_map_method == 1) then
      echo "gc_map $MASDIR/$mas_slc.par $INTDIR/${mas_slv}.off $DEMDIR/${DEM}_par $DEMDIR/$DEM ${mas_slv}.utm.dem.par ${mas_slv}.utm.dem ${mas_slv}.utm_to_rdc 1 1 ${mas_slv}.utm.sim.sar ${mas_slv}.u ${mas_slv}.v ${mas_slv}.linc ${mas_slv}.psi ${mas_slv}.pix - 8 - - >> $PRJDIR/$intLog"
      gc_map $MASDIR/$mas_slc.par $INTDIR/${mas_slv}.off $DEMDIR/${DEM}_par $DEMDIR/$DEM ${mas_slv}.utm.dem.par ${mas_slv}.utm.dem ${mas_slv}.utm_to_rdc 1 1 ${mas_slv}.utm.sim.sar - - - - - - 8 - - >> $PRJDIR/$intLog
      echo $EMP
   else
      echo "gc_map $INTDIR/$mas_slv.pwr1.par - $DEMDIR/${DEM}_par $DEMDIR/$DEM ${mas_slv}.utm.dem.par ${mas_slv}.utm.dem ${mas_slv}.utm_to_rdc 1 1 ${mas_slv}.utm.sim.sar ${mas_slv}.u ${mas_slv}.v ${mas_slv}.linc ${mas_slv}.psi ${mas_slv}.pix - 8 - - >> $PRJDIR/$intLog"
      gc_map $INTDIR/$mas_slv.pwr1.par - $DEMDIR/${DEM}_par $DEMDIR/$DEM ${mas_slv}.utm.dem.par ${mas_slv}.utm.dem ${mas_slv}.utm_to_rdc 1 1 ${mas_slv}.utm.sim.sar - - - - - - 8 - - >> $PRJDIR/$intLog
      echo $EMP
   endif
   
  
   #geocode: transfrom simulated intensity image from MAP to SAR coordiante system
   set utmw = `grep width: ${mas_slv}.utm.dem.par | awk '{print $2}'`
   set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
   set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`
   echo "geocode ${mas_slv}.utm_to_rdc ${mas_slv}.utm.sim.sar $utmw ${mas_slv}.rdc.sim.sar $np $nl"
   geocode ${mas_slv}.utm_to_rdc ${mas_slv}.utm.sim.sar $utmw ${mas_slv}.rdc.sim.sar $np $nl >> $PRJDIR/$intLog

   set BEGL = $BEGS
   set BEGS = "GCMAP"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif

#begin interferogram simulation
if( $BEGS == "GCMAP" ) then

   echo $EQ
   echo "Simulation lookup table refinement ......"
   echo $EMP

   cd $SIMDIR

   #create coregistration parameter file
   /bin/echo -e "DEME\n0 0\n24 24\n64 64\n7.0\n" > create_diff_par.in

   set create_diff_method = 1

   if($create_diff_method == 1) then
      echo "create_diff_par $INTDIR/${mas_slv}.off $INTDIR/${mas_slv}.off ${mas_slv}.diff.par"
      create_diff_par $INTDIR/${mas_slv}.off $INTDIR/${mas_slv}.off ${mas_slv}.diff.par < create_diff_par.in > $simLog
      echo $EMP
   else
      echo "create_diff_par $INTDIR/${mas_slv}.pwr1.par - ${mas_slv}.diff.par 1 < create_diff_par.in > $simLog"
      create_diff_par $INTDIR/${mas_slv}.pwr1.par - ${mas_slv}.diff.par 1< create_diff_par.in > $simLog
      echo $EMP
   endif
   rm -f create_diff_par.in

   echo $EMP
   echo $EMP
   #coarse estimation by pwr. correlation estimation (optional)
   echo "init_offsetm ${mas_slv}.rdc.sim.sar $INTDIR/${mas_slv}.pwr1 ${mas_slv}.diff.par"
   init_offsetm ${mas_slv}.rdc.sim.sar $INTDIR/${mas_slv}.pwr1 ${mas_slv}.diff.par >> $simLog
   echo $EMP

   #fine estimation by pwr. correlation estimation (recommend)
   echo "offset_pwrm ${mas_slv}.rdc.sim.sar $INTDIR/${mas_slv}.pwr1 ${mas_slv}.diff.par offs snr 512 512 offsets 2 32 32 0.3" 
   offset_pwrm ${mas_slv}.rdc.sim.sar $INTDIR/${mas_slv}.pwr1 ${mas_slv}.diff.par offs snr 512 512 offsets 2 32 32 0.1 >> $simLog
   echo $EMP

   #offset polynomial fitting (recommend)
   echo "offset_fitm offs snr ${mas_slv}.diff.par coffs coffsets 0.3 3"
   offset_fitm offs snr ${mas_slv}.diff.par coffs coffsets 0.3 3  >> $simLog
   echo $EMP

   #fine estimation by pwr. correlation estimation (necessary)
   echo "offset_pwrm ${mas_slv}.rdc.sim.sar $INTDIR/${mas_slv}.pwr1 ${mas_slv}.diff.par offs snr 256 256 offsets 2 64 64 0.5" 
   offset_pwrm ${mas_slv}.rdc.sim.sar $INTDIR/${mas_slv}.pwr1 ${mas_slv}.diff.par offs snr 256 256 offsets 2 64 64 0.1 >> $simLog
   echo $EMP

   #offset polynomial fitting (necessary)
   echo "offset_fitm offs snr ${mas_slv}.diff.par coffs coffsets 0.5 4"
   offset_fitm offs snr ${mas_slv}.diff.par coffs coffsets 0.5 4 >> $simLog
   echo $EMP

   rm -f coffs offs snr coffsets offsets

   set utmw = `grep width: ${mas_slv}.utm.dem.par | awk '{print $2}'`
   #set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
   #set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`
   set np   = `grep range_samp_1: ${mas_slv}.diff.par | awk '{print $2}'`
   set nl   = `grep az_samp_1: ${mas_slv}.diff.par | awk '{print $2}'`

   #refine polynomial
   echo "gc_map_fine ${mas_slv}.utm_to_rdc $utmw ${mas_slv}.diff.par ${mas_slv}.utm_to_rdc_fine 1"
   gc_map_fine ${mas_slv}.utm_to_rdc $utmw ${mas_slv}.diff.par ${mas_slv}.utm_to_rdc_fine 1 >> $PRJDIR/$intLog
   echo $EMP
   
   echo "look_vector $MASDIR/${mas_slc}.par $INTDIR/${mas_slv}.off ${mas_slv}.utm.dem.par ${mas_slv}.utm.dem lv_theta lv_phi"
   look_vector $MASDIR/${mas_slc}.par $INTDIR/${mas_slv}.off ${mas_slv}.utm.dem.par ${mas_slv}.utm.dem lv_theta lv_phi >> vector.txt
   echo $EMP
      
   #geocode: transfrom DEM from MAP to SAR coordiante system
   echo "geocode ${mas_slv}.utm_to_rdc_fine ${mas_slv}.utm.dem $utmw ${mas_slv}.dem_hgt $np $nl 0 0"
   geocode ${mas_slv}.utm_to_rdc_fine ${mas_slv}.utm.dem $utmw ${mas_slv}.dem_hgt $np $nl 0 0 >> $PRJDIR/$intLog
   echo $EMP

   #=================================================================
   set offset_map = 0
   set offset_method = 1
   echo "========================================================="
   echo "==========   offset map calculation  ===================="
   echo "========================================================="
   echo $EMP
   if ( ${offset_map} == 1) then

      if(!(-e $OFFDIR)) then
         mkdir $OFFDIR
      endif

      cd $OFFDIR
      echo "Now at $PWD"

      #create offset parameter file
      set np = `grep range_samples: $MASDIR/${mas_slc}.par | awk '{print $2}'`
      /bin/echo -e "$mas_slv\n0 0\n32 32\n128 128\n0.5\n0\n$np" > create_offset.in
      #
      echo "create_offset $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off 1"
      create_offset $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off 1 < create_offset.in > $INTDIR/${offLog}
      echo $EMP
      rm -f create_offset.in

      set np = `grep range_samples: $MASDIR/${mas_slc}.par  | awk '{print $2}'`
      set nline = `grep azimuth_lines: $MASDIR/${mas_slc}.par  | awk '{print $2}'`

      set rstep = $rlks
      set azstep = $azlks

      set rstart = `echo "$rlks 2" | awk '{print $1/$2}'`
      @ rstop = $np - $rlks
      set azstart = `echo "$azlks 2" | awk '{print $1/$2}'`
      @ azstop = $nline - $azlks

      echo "offset_pwr_tracking $MASDIR/${mas_slc} $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off offsN snrN 128 64 - 2 0.5 $rstep $azstep - - - - 4 0"
      offset_pwr_tracking $MASDIR/${mas_slc} $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off offsN snrN 128 64 - 2 0.5 $rstep $azstep - - - - 4 0 >> offset.log
      echo $EMP

      echo "offset_tracking offsN snrN $MASDIR/${mas_slc}.par ${mas_slv}.off coffsN coffsetsN 2 0.5 1"
      offset_tracking offsN snrN $MASDIR/${mas_slc}.par ${mas_slv}.off coffsN coffsetsN 2 0.5 1 >> offset.log
      echo $EMP

      echo "multi_look $MASDIR/${mas_slc} $MASDIR/${mas_slc}.par ${mas}.mli ${mas}.mli.par $rstep $azstep"
      multi_look $MASDIR/${mas_slc} $MASDIR/${mas_slc}.par ${mas}.mli ${mas}.mli.par $rstep $azstep >> offset.log
      echo $EMP

      set np = `grep range_samples: ${mas}.mli.par | awk '{print $2}'`

      echo "raspwr ${mas}.mli $np - - 1 1 - - - ${mas}.mli.ras"
      raspwr ${mas}.mli $np - - 1 1 - - - ${mas}.mli.ras >> offset.log
      echo $EMP

      echo "cpx_to_real coffsN coffsN_real $np 0"
      cpx_to_real coffsN coffsN_real $np 0 >> offset.log
      echo $EMP

      echo "cpx_to_real coffsN coffsN_ima $np 1"
      cpx_to_real coffsN coffsN_ima $np 1 >> offset.log
      echo $EMP

      echo "rashgt coffsN_real ${mas}.mli $np 1 1 0 1 1 5. 1. .35 1 coffsN_real.ras"
      rashgt coffsN_real ${mas}.mli $np 1 1 0 1 1 5. 1. .35 1 coffsN_real.ras >> offset.log
      echo $EMP

      echo "rashgt coffsN_ima ${mas}.mli $np 1 1 0 1 1 5. 1. .35 1 coffsN_ima.ras"
      rashgt coffsN_ima ${mas}.mli $np 1 1 0 1 1 5. 1. .35 1 coffsN_ima.ras >> offset.log
      echo $EMP

      echo "cpx_to_real coffsN coffsN_mag $np 3"
      cpx_to_real coffsN coffsN_mag $np 3 >> offset.log
      echo $EMP
   
      echo "rasdt_pwr24 coffsN_mag ${mas}.mli $np 1 1 0 1 1 5. 1. .35 1 coffsN_mag.ras"
      rasdt_pwr24 coffsN_mag ${mas}.mli $np 1 1 0 1 1 5. 1. .35 1 coffsN_mag.ras >> offset.log
      echo $EMP

      set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`

      echo "geocode_back ${mas}.mli $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas}.mli_utm $utmw 0 0 0"
      geocode_back ${mas}.mli $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas}.mli_utm $utmw 0 0 0 >> offset.log
      echo $EMP

      echo "geocode_back coffsN_real $np $SIMDIR/${mas_slv}.utm_to_rdc_fine coffsN_real_utm $utmw 0 0 0"
      geocode_back coffsN_real $np $SIMDIR/${mas_slv}.utm_to_rdc_fine coffsN_real_utm $utmw 0 0 0 >> offset.log
      echo $EMP

      echo "rashgt coffsN_real_utm ${mas}.mli_utm $utmw 1 1 0 1 1 5. 1. .35 1 coffsN_real_utm.ras"
      rashgt coffsN_real_utm ${mas}.mli_utm $utmw 1 1 0 1 1 5. 1. .35 1 coffsN_real_utm.ras >> offset.log
      echo $EMP

      echo "geocode_back coffsN_ima $np $SIMDIR/${mas_slv}.utm_to_rdc_fine coffsN_ima_utm $utmw 0 0 0"
      geocode_back coffsN_ima $np $SIMDIR/${mas_slv}.utm_to_rdc_fine coffsN_ima_utm $utmw 0 0 0 >> offset.log
      echo $EMP

      echo "rashgt coffsN_ima_utm ${mas}.mli_utm $utmw 1 1 0 1 1 5. 1. .35 1 coffsN_ima_utm.ras"
      rashgt coffsN_ima_utm ${mas}.mli_utm $utmw 1 1 0 1 1 5. 1. .35 1 coffsN_ima_utm.ras >> offset.log
      echo $EMP
   endif
   echo $EMP
   echo "========================================================="
   echo "==========  end offset map calculation  ================="
   echo "========================================================="
   #================================================================= 
 
   set BEGL = $BEGS
   set BEGS = "SIM"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif   #end coregistration

#===============================================#
#    DIFF: substract external topo-phase        #
# 1. Interferogram simulation                   #
# 2. Substract topographic phase                #
#===============================================#
#begin interferogram simulation and differential
if( $BEGS == "SIM" ) then

   echo $EQ
   echo "Differential processing ......"
   echo $EMP

   cd $INTDIR

   set sim_method = 2 

   if ($sim_method == 1) then
     #interferogram simulation
     echo "phase_sim $MASDIR/${mas_slc}.par ${mas_slv}.off ${mas_slv}.base $SIMDIR/${mas_slv}.dem_hgt $SIMDIR/${mas_slv}.sim_unw 0 0"
     phase_sim $MASDIR/${mas_slc}.par ${mas_slv}.off ${mas_slv}.base $SIMDIR/${mas_slv}.dem_hgt $SIMDIR/${mas_slv}.sim_unw 0 0 >> $PRJDIR/$intLog
   else
     echo "phase_sim_orb $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SIMDIR/${mas_slv}.dem_hgt $SIMDIR/${mas_slv}.sim_unw - -"
     #phase_sim_orb $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SIMDIR/${mas_slv}.dem_hgt $SIMDIR/${mas_slv}.sim_unw - - >> $PRJDIR/$intLog
     phase_sim_orb $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SIMDIR/${mas_slv}.dem_hgt $SIMDIR/${mas_slv}.sim_unw $MASDIR/${mas_slc}.par - - >> $PRJDIR/$intLog
   endif
   echo $EMP

   #substract topographic phase
   #echo "sub_phase ${mas_slv}.int $SIMDIR/${mas_slv}.sim_unw $SIMDIR/${mas_slv}.diff.par ${mas_slv}.tflt 1"
   #sub_phase ${mas_slv}.int $SIMDIR/${mas_slv}.sim_unw $SIMDIR/${mas_slv}.diff.par ${mas_slv}.tflt 1 >> $PRJDIR/$intLog
   #echo $EMP

   echo "SLC_diff_intf $MASDIR/${mas_slc} $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SIMDIR/${mas_slv}.sim_unw ${mas_slv}.tflt $rlks $azlks 1 0 0.2 1 1"
   SLC_diff_intf $MASDIR/${mas_slc} $SLVDIR/${slv_slc} $MASDIR/${mas_slc}.par $SLVDIR/${slv_slc}.par ${mas_slv}.off $SIMDIR/${mas_slv}.sim_unw ${mas_slv}.tflt $rlks $azlks 1 0 0.2 1 1 >> $PRJDIR/$intLog
   echo $EMP

   #plot raster image for flatten interferogram
   set np   = `grep interferogram_width: ${mas_slv}.off | awk '{print $2}'`
   echo "rasmph_pwr ${mas_slv}.tflt ${mas_slv}.pwr1 $np 1 0 1 1"
   #rasmph_pwr ${mas_slv}.tflt ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks 1. .35  1 >> $PRJDIR/$intLog
   rasmph_pwr ${mas_slv}.tflt ${mas_slv}.pwr1 $np 1 0 1 1 >> $PRJDIR/$intLog
   echo $EMP

   set BEGL = $BEGS
   set BEGS = "DIFF"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif   #end coregistration

#================================================#
#     Adaptive Filter                            #
# 1. Adaptive filter for flattened interferogram #
# 2. Geocode the intensity, interferogram, and   #
#    coherence images                            #
# other method???                                #
#================================================#
if ($BEGS == "DIFF") then

   echo $EQ
   echo "Adaptive filtering of differential interferogram ......"
   echo $EMP

   cd $INTDIR
   
   set filt_method = 0

   #adaptive filter of flatened interferogram
   set np   = `grep interferogram_width: ${mas_slv}.off | awk '{print $2}'`

   if ($filt_method == 1) then
      echo "adapt_filt ${mas_slv}.tflt ${mas_slv}.tflt_af $np 0.25 2" 
      adapt_filt ${mas_slv}.tflt ${mas_slv}.tflt_af $np 0.25 2 >> $PRJDIR/$intLog
      echo $EMP

      echo "adf ${mas_slv}.tflt_af ${mas_slv}.tflt_sm ${mas_slv}.smcc $np 0.7 32 7 8 0 0 .8"
      adf ${mas_slv}.tflt_af ${mas_slv}.tflt_sm ${mas_slv}.smcc $np 0.7 32 7 8 0 0 .8 >> $PRJDIR/$intLog
      echo $EMP
   else
      echo "adf ${mas_slv}.tflt tmp ${mas_slv}.smcc $np .2 128 7 16 0 0 .25"
      adf ${mas_slv}.tflt tmp ${mas_slv}.smcc $np .2 128 7 16 0 0 .25 >> $PRJDIR/$intLog
      echo $EMP

      echo "adf tmp tmp1 ${mas_slv}.smcc $np .3 64 7 8 0 0 .25"
      adf tmp tmp1 ${mas_slv}.smcc $np .3 64 7 8 0 0 .25 >> $PRJDIR/$intLog
      echo $EMP

      echo "adf tmp1 ${mas_slv}.tflt_sm ${mas_slv}.smcc $np .4 32 7 4 0 0 .25"
      adf tmp1 ${mas_slv}.tflt_sm ${mas_slv}.smcc $np .4 32 7 4 0 0 .25 >> $PRJDIR/$intLog
      echo $EMP
      
      /bin/rm -rf tmp*
   endif

   #echo "cc_wave ${mas_slv}.tflt - - ${mas_slv}.cc $np 7 7 2"
   #cc_wave ${mas_slv}.tflt - - ${mas_slv}.cc $np 7 7 2 >> $PRJDIR/$intLog
   #echo $EMP

   #raster filtered interferogram
   echo "rasmph_pwr ${mas_slv}.tflt_sm ${mas_slv}.pwr1 $np 1 0 1 1"
   rasmph_pwr ${mas_slv}.tflt_sm ${mas_slv}.pwr1 $np 1 0 1 1 >> $PRJDIR/$intLog
   echo $EMP

   #raster coherence image
   #echo "rascc ${mas_slv}.smcc ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks"
   #rascc ${mas_slv}.smcc ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
   echo "raspwr ${mas_slv}.smcc ${mas_slv}.pwr1 $np 1 0 1 1"
   raspwr ${mas_slv}.smcc ${mas_slv}.pwr1 $np 1 0 1 1 >> $PRJDIR/$intLog
   echo $EMP

   #echo "rascc ${mas_slv}.cc ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks"
   #rascc ${mas_slv}.cc ${mas_slv}.pwr1 $np 1 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
   #echo $EMP

   #utm image width
   set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
   #geocode pwr1
   if(-e ${mas_slv}.pwr1) then
      #geocode pwr1
      echo "geocode_back ${mas_slv}.pwr1 $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.pwr1_utm $utmw 0 0 0"
      geocode_back ${mas_slv}.pwr1 $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.pwr1_utm $utmw 0 0 0 >> $PRJDIR/$intLog
      echo $EMP
      #raster geocoded pwr1
      echo "raspwr ${mas_slv}.pwr1_utm $utmw 1 0 $rasrlks $rasazlks"
      raspwr ${mas_slv}.pwr1_utm $utmw 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
      echo $EMP
   endif

   #geocode smcc
   if(-e ${mas_slv}.smcc) then
      #geocode coherence image
      echo "geocode_back ${mas_slv}.smcc $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.smcc_utm $utmw 0 0 0"
      geocode_back ${mas_slv}.smcc $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.smcc_utm $utmw 0 0 0 >> $PRJDIR/$intLog
      echo $EMP

      #echo "geocode_back ${mas_slv}.cc $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.cc_utm $utmw 0 0 0"
      # geocode_back ${mas_slv}.cc $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.cc_utm $utmw 0 0 0 >> $PRJDIR/$intLog
      #echo $EMP

      #raster geocoded coherence image
      #echo "rascc ${mas_slv}.smcc_utm ${mas_slv}.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks"
      # rascc ${mas_slv}.smcc_utm ${mas_slv}.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
      #echo $EMP

      #echo "rascc ${mas_slv}.cc_utm ${mas_slv}.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks"
      #rascc ${mas_slv}.cc_utm ${mas_slv}.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
      #echo $EMP
   endif

   #geocode filtered interferogram
   if(-e ${mas_slv}.tflt_sm) then
      #geocode filtered interferogram
      echo "geocode_back ${mas_slv}.tflt_sm $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.tflt_sm_utm $utmw 0 0 1 "
      geocode_back ${mas_slv}.tflt_sm $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.tflt_sm_utm $utmw 0 0 1 >> $PRJDIR/$intLog
      echo $EMP
      #raster geocoded filtered interferogram
      echo "rasmph_pwr ${mas_slv}.tflt_sm_utm ${mas_slv}.pwr1_utm $utmw 1 0 $rasrlks $rasazlks"
      rasmph_pwr ${mas_slv}.tflt_sm_utm ${mas_slv}.pwr1_utm $utmw 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
      echo $EMP
   endif

   set BEGL = $BEGS
   set BEGS = "FILT"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif


#================================================#
# Baseline refinement and orbit error mitigation #
#================================================#
if( $BEGS == "FILT" ) then

   echo $EQ
   echo "Baseline refinement and orbit error mitigation ......"
   echo $EMP

   cd $INTDIR
	 
   rm -f ${mas_slv}.tflt_sm_rmp
   set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`
   @ naz_o = $nl - 256  
	 
   set brefine = 0 
   
   if ( $brefine == 1 ) then
     #estimate base for residual orbit error
     echo "base_est_fft ${mas_slv}.tflt_sm $MASDIR/${mas_slc}.par ${mas_slv}.off ${mas_slc}.base_res 2048 2100 1400"
     base_est_fft ${mas_slv}.tflt_sm $MASDIR/${mas_slc}.par ${mas_slv}.off ${mas_slc}.base_res 2048 2100 1400 >> $PRJDIR/$intLog
     echo $EMP

     #deramp fringe for residual orbit error
     echo "ph_slope_base ${mas_slv}.tflt_sm $MASDIR/${mas_slc}.par ${mas_slv}.off ${mas_slc}.base_res ${mas_slv}.tflt_sm_rmp"
     ph_slope_base ${mas_slv}.tflt_sm $MASDIR/${mas_slc}.par ${mas_slv}.off ${mas_slc}.base_res ${mas_slv}.tflt_sm_rmp >> $PRJDIR/$intLog
     echo $EMP

     #raster final interferogram
     set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
     echo "rasmph_pwr ${mas_slv}.tflt_sm_rmp ${mas_slv}.pwr1 $np 1 0 $rasrlks $rasazlks"
     rasmph_pwr ${mas_slv}.tflt_sm_rmp ${mas_slv}.pwr1 $np 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
     echo $EMP
   endif

   #utm image width
   set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`

   #geocode filtered interferogram
   if(-e ${mas_slv}.tflt_sm_rmp) then
      #geocode filtered interferogram
      echo "geocode_back ${mas_slv}.tflt_sm_rmp $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.tflt_sm_rmp_utm $utmw 0 0 1 "
      geocode_back ${mas_slv}.tflt_sm_rmp $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.tflt_sm_rmp_utm $utmw 0 0 1 >> $PRJDIR/$intLog
      echo $EMP
      #raster geocoded filtered interferogram
      echo "rasmph_pwr ${mas_slv}.tflt_sm_rmp_utm ${mas_slv}.pwr1_utm $utmw 1 0 $rasrlks $rasazlks"
      rasmph_pwr ${mas_slv}.tflt_sm_rmp_utm ${mas_slv}.pwr1_utm $utmw 1 0 $rasrlks $rasazlks >> $PRJDIR/$intLog
      echo $EMP
   endif

   set BEGL = ${BEGS}
   set BEGS = "DERAMP"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif

#================================================#
# Phase unwrapping using mcf method              #
#================================================#
if( $BEGS == "DERAMP" ) then
set UNWRAP_MODEL = 1
   if ( ${UNWRAP_MODEL} == 1 ) then
     if(!(-e $UNWDIR)) then
        mkdir $UNWDIR
     endif

     cd $UNWDIR

     #interferogram width/lines
     set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
     set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`

        echo $EQ
        echo "Phase unwrapping using mcf method ......"
        echo $EMP

        if(!(-e $UNWDIR/mcf)) then
           mkdir mcf
        endif
        cd mcf

        #reference point coordinates (image center)
        #@ npd2 = $np / 3
        #@ nld2 = $nl / 3
        set npd2 = 864
        set nld2 = 2520
        set pr  = 1
        set paz = 1
        set pov = 600
 
        #generation of phase unwrapping validity mask
        echo "rascc_mask $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $np 1 1 0 1 1 0.25 0.1 0.9 1.0 0.35 1 $mas_slv.smcc.mask.ras"
        rascc_mask $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $np 1 1 0 1 1 0 0 0.1 0.9 1.0 0.35 1 $mas_slv.smcc.mask.ras >! $unwLog
        echo $EMP
 
        #adaptive sampling reduction for phase unwrapping validity mask
        echo "rascc_mask_thinning $mas_slv.smcc.mask.ras $INTDIR/$mas_slv.smcc $np $mas_slv.smcc.mask_thinned.ras 5 0.3 0.4 0.5 0.6 0.6"
        rascc_mask_thinning $mas_slv.smcc.mask.ras $INTDIR/$mas_slv.smcc $np $mas_slv.smcc.mask_thinned.ras 5 0.3 0.4 0.5 0.6 0.6 >> $unwLog
        echo $EMP
 
        #phase unwrapping using mcf and triangulation
        if(-e $INTDIR/mas_slv.tflt_sm_rmp) then
           echo "mcf $INTDIR/$mas_slv.tflt_sm_rmp $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw_thinned $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0"
           mcf $INTDIR/$mas_slv.tflt_sm_rmp $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw_thinned $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0 >> $unwLog
           echo $EMP
        else
           echo "mcf $INTDIR/$mas_slv.tflt_sm $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw_thinned $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0"
           mcf $INTDIR/$mas_slv.tflt_sm $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw_thinned $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0 >> $unwLog
           echo $EMP
        endif
 
        #weighted interpolation of gaps in unwrapped phase data using adaptive window size
        echo "interp_ad $mas_slv.unw_thinned $mas_slv.unw_interp $np 32 8 16 2"
        interp_ad $mas_slv.unw_thinned $mas_slv.unw_interp $np 32 8 16 2 >> $unwLog
        echo $EMP
 
        #phase unwrapping using model of unwrapped phase
        if(-e $INTDIR/$mas_slv.tflt_sm_rmp) then
           echo "unw_model $INTDIR/$mas_slv.tflt_sm_rmp $mas_slv.unw_interp $mas_slv.unw $np $npd2 $nld2 0"
           unw_model $INTDIR/$mas_slv.tflt_sm_rmp $mas_slv.unw_interp $mas_slv.unw $np $npd2 $nld2 0 >> $unwLog
           echo $EMP
        else
           echo "unw_model $INTDIR/$mas_slv.tflt_sm $mas_slv.unw_interp $mas_slv.unw $np $npd2 $nld2 0"
           unw_model $INTDIR/$mas_slv.tflt_sm $mas_slv.unw_interp $mas_slv.unw $np $npd2 $nld2 0 >> $unwLog
           echo $EMP
        endif

     #geocode unwrapped image
     #utm image width
     set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     set utml = `grep nlines: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     if(-e ${mas_slv}.unw) then
        echo "geocode_back ${mas_slv}.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 "
        geocode_back ${mas_slv}.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 >> $unwLog
        echo $EMP
        #raster geocoded unwrapped image
     #echo "rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.ras $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $PRJDIR/$intLog"
      #rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.bmp $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $PRJDIR/$intLog
      #rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.ras $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $PRJDIR/$intLog
      echo "rasdt_pwr $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 0 $rasrlks $rasazlks -2.8 2.8 1 hls.cm >> $PRJDIR/$intLog"
      rasdt_pwr $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 0 $rasrlks $rasazlks -2.8 2.8 1 hls.cm >> $PRJDIR/$intLog
      endif
  endif

   if ( ${UNWRAP_MODEL} == 3 ) then
     if(!(-e $UNWDIR)) then
        mkdir $UNWDIR
     endif

     cd $UNWDIR

     #interferogram width/lines
     set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
     set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`

        echo $EQ
        echo "Phase unwrapping using mcf method ......"
        echo $EMP

        if(!(-e $UNWDIR/mcf)) then
           mkdir mcf
        endif
        cd mcf

        #reference point coordinates (image center)
        #@ npd2 = $np / 3
        #@ nld2 = $nl / 3
        set npd2 = -
        set nld2 = -
        set pr  = 1
        set paz = 1
        set pov = -
 
        #generation of phase unwrapping validity mask
        echo "rascc_mask $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $np 1 1 0 1 1 0.25 0.1 0.9 1.0 0.35 1 $mas_slv.smcc.mask.ras"
        rascc_mask $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $np 1 1 0 1 1 0.25 0.1 0.9 1.0 0.35 1 $mas_slv.smcc.mask.ras >! $unwLog
        echo $EMP

        #adaptive sampling reduction for phase unwrapping validity mask
        echo "rascc_mask_thinning $mas_slv.smcc.mask.ras $INTDIR/$mas_slv.smcc $np $mas_slv.smcc.mask_thinned.ras 5 0.3 0.4 0.5 0.6 0.7"
        rascc_mask_thinning $mas_slv.smcc.mask.ras $INTDIR/$mas_slv.smcc $np $mas_slv.smcc.mask_thinned.ras 5 0.3 0.4 0.5 0.6 0.7 >> $unwLog
        echo $EMP

        #phase unwrapping using mcf and triangulation
        if(-e $INTDIR/mas_slv.tflt_sm_rmp) then
           echo "mcf $INTDIR/$mas_slv.tflt_sm_rmp $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0"
           mcf $INTDIR/$mas_slv.tflt_sm_rmp $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0 >> $unwLog
           echo $EMP
        else
           echo "mcf $INTDIR/$mas_slv.tflt_sm $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0"
           mcf $INTDIR/$mas_slv.tflt_sm $INTDIR/$mas_slv.smcc $mas_slv.smcc.mask_thinned.ras $mas_slv.unw $np 1 0 0 - - $pr $paz $pov $npd2 $nld2 0 >> $unwLog
           echo $EMP
        endif

     #geocode unwrapped image
     #utm image width
     set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     set utml = `grep nlines: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     if(-e ${mas_slv}.unw) then
        echo "geocode_back ${mas_slv}.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 "
        geocode_back ${mas_slv}.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 >> $unwLog
        echo $EMP
        #raster geocoded unwrapped image
      #echo "rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.ras $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $PRJDIR/$intLog"
      #rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.bmp $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $PRJDIR/$intLog
      echo "rasdt_pwr $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 0 $rasrlks $rasazlks -2.8 2.8 1 hls.cm >> $PRJDIR/$intLog"
      rasdt_pwr $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 0 $rasrlks $rasazlks  -2.8 2.8 1 hls.cm  >> $PRJDIR/$intLog
    endif
  endif


  
  if ( ${UNWRAP_MODEL} == 2 ) then 
   if(!(-e $UNWDIR)) then
      mkdir $UNWDIR
   endif

   cd $UNWDIR
   rm -rf unw.log >/dev/null && touch unw.log

   #interferogram width/lines
   set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
   set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`

      echo $EQ
      echo "Phase unwrapping using tree method ......"
      echo $EMP

      if(!(-e $UNWDIR/tree)) then
         mkdir tree
      endif
      cd tree

      #reference point coordinates (image center)
      #@ npd2 = $np / 3
      #@ nld2 = $nl / 3
      set npd2 = 3121
      set nld2 = 2294
      set pr  = 2
      set paz = 5
      set pov = 600
 
      if(-e $INTDIR/$mas_slv.tflt_sm_rmp) then
        echo "UNWRAP_PAR $INTDIR/$mas_slv.off $INTDIR/$mas_slv.tflt_sm_rmp $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $mas_slv.unw $mas_slv.flag 0.3 6 $npd2 $nld2"
        UNWRAP_PAR $INTDIR/$mas_slv.off $INTDIR/$mas_slv.tflt_sm_rmp $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $mas_slv.unw $mas_slv.flag 0.3 6 $npd2 $nld2
      else
        echo "UNWRAP_PAR $INTDIR/$mas_slv.off $INTDIR/$mas_slv.tflt_sm $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $mas_slv.unw $mas_slv.flag 0.7 6 $npd2 $nld2"
        UNWRAP_PAR $INTDIR/$mas_slv.off $INTDIR/$mas_slv.tflt_sm $INTDIR/$mas_slv.smcc $INTDIR/$mas_slv.pwr1 $mas_slv.unw $mas_slv.flag 0.7 6 $npd2 $nld2
        echo $EMP
      endif
 

     #geocode unwrapped image
     #utm image width
     set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     set utml = `grep nlines: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     if(-e ${mas_slv}.unw) then
        echo "geocode_back ${mas_slv}.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 "
        geocode_back ${mas_slv}.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 >> $unwLog
        echo $EMP
        #raster geocoded unwrapped image
      #rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.bmp $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $PRJDIR/$intLog
      rasdt_pwr $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 0 $rasrlks $rasazlks -2.8 2.8 1 hls.cm >> $PRJDIR/$intLog
     endif
   endif
   
   #echo "mv ${mas_slv}.unw_utm ${mas_slv}.unw_utm_ori"
   #mv ${mas_slv}.unw_utm ${mas_slv}.unw_utm_ori
   #echo "${PRJDIR}/correct.csh ${mas} ${slv}"
   #${PRJDIR}/correct.csh ${mas} ${slv}
   ####
   ####
   if ( ${UNWRAP_MODEL} == 4 ) then
     if(!(-e $UNWDIR)) then
        mkdir $UNWDIR
     endif

     cd $UNWDIR

     #interferogram width/lines
     set np   = `grep interferogram_width: $INTDIR/${mas_slv}.off | awk '{print $2}'`
     set nl   = `grep interferogram_azimuth_lines: $INTDIR/${mas_slv}.off | awk '{print $2}'`

     echo $EQ
     echo "Phase unwrapping using SNAPHU method ......"
     echo $EMP

     if(!(-e $UNWDIR/snaphu)) then
        mkdir snaphu
     endif
     cd snaphu

     echo "snaphu4gamma.csh $PRJDIR ${mas} $slv"
     #copy snaphu4gamma.csh to snaphu directory firstly!!!!!!!!!!!!!!!!!!!!!!!!!!
     snaphu4gamma.sh $PRJDIR ${mas} $slv >! $unwLog
     echo $EMP

     #echo "rasrmg ${mas_slv}_msk.unw $INTDIR/$mas_slv.pwr1 $np 1 1 0 1 1 .333"
     #rasrmg ${mas_slv}_msk.unw $INTDIR/$mas_slv.pwr1 $np 1 1 0 1 1 .333 >> $unwLog
     echo "rasdt_pwr ${mas_slv}_msk.unw $INTDIR/$mas_slv.pwr1 $np 1 0 1 1 -2.8 2.8 1 hls.cm"
     rasdt_pwr ${mas_slv}_msk.unw $INTDIR/$mas_slv.pwr1 $np 1 0 1 1 -2.8 2.8 1 hls.cm >> $unwLog
     echo $EMP

     #geocode unwrapped image
     #utm image width
     set utmw = `grep width: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     set utml = `grep nlines: $SIMDIR/${mas_slv}.utm.dem.par | awk '{print $2}'`
     if(-e ${mas_slv}.unw) then
        echo "geocode_back ${mas_slv}_msk.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 "
        geocode_back ${mas_slv}_msk.unw $np $SIMDIR/${mas_slv}.utm_to_rdc_fine ${mas_slv}.unw_utm $utmw 0 0 0 >> $unwLog
        echo $EMP
        #raster geocoded unwrapped image
      #rasrmg $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 1 0 $rasrlks $rasazlks 1.0 1.0 0.35 0 1 $mas_slv.unw_utm.bmp $INTDIR/$mas_slv.smcc_utm 1 0.25 >> $unwLog
      rasdt_pwr $mas_slv.unw_utm $INTDIR/$mas_slv.pwr1_utm $utmw 1 0 $rasrlks $rasazlks -2.8 2.8 1 hls.cm >> $unwLog
     endif
   endif

   ####

   set BEGL = $BEGS
   set BEGS = "UNW"
   if($BEGS == $ENDS) then
       echo "Running from $BEGL to $ENDS"
       echo "Complete, successfully!"
       echo $EQ
       exit 1
   endif
endif

# end
