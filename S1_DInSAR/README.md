
YYYYMMDD_YYYYMMDD --------- $procdir  
   |   |   |   |
   |   |   |   |------------- dem 		  
   |   |   |----------------- opod    
   |   |--------------------- YYYYMMDD (master), run S1A.master under this folder  
   |------------------------- YYYYMMDD (slave), run S1A.slave under this folder  
	  
After runing S1A.master and S1A.slave under $master and $slave respectively, then run process_2pss.csh under $procdir.
		
