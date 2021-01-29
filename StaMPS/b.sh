#!/bin/csh -f

# under the rslc (rslc + rslc.par) directory
ls -1 | grep '^[0-9]' | grep 'rslc$' | sed 's/.rslc//g' > filelist

while read line
do
	SLC_resam $line.rslc $line.rslc.par ${line}_2.rslc ${line}_2.rslc.par .25 
done < filelist


rm ????????.rslc ????????.rslc.par
rename -v _2.rslc .rslc *
