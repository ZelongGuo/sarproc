#!/bin/bash
 
 cd /     
 
        path="/home/zelong/Desktop/my_scripts/back_up"  
  # backup to corresponding directory
 
        way="/home/zelong/Desktop/my_scripts/S1_TS_proc"    
  # directory needed to be backup to
 
 
 #       -P specifies the absolute path (defualt is relative path)
         tar -P -zcvf /home/zelong/Desktop/my_shell_scripts/original/back_up/`date +%Y-%m-%d`T`date +%H:%M:%S`_S1_TS_proc.tar.gz $way >/dev/null 2>> $path/back_up.log 

	date "+%Y-%m-%d %H:%M:%S" | xargs echo "Automatic backup is finished! ">> $path/back_up.log

num=$(ls -l $path | grep 'S1_TS_proc.tar.gz' | wc -l)

# 4 days data will be saved
if [ "$num" -gt 4 ]; then
	
	rm -rf $path/`ls -lc $path | grep 'S1_TS_proc.tar.gz' | head -n 1 | awk '{print $NF}'`
fi

# tar -zxvf *.tar.gz
