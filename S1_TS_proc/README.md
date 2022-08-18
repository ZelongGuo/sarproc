### S1_TS_proc ###
---------------------------------------------------------------------------------------------------
#### Expected Structure: (for time series processing) ####

- *For normal processing:*  
  ***$procdir*** -------------------------------- cwd of running *sh_gamma.sh*  
  \| &ensp;\| &ensp;\| &ensp;\|---------------------------------- ***table*** (***MANDATORY***)  *sh_setup_gamma*  
  \| &ensp;\| &ensp;\| &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;  &emsp;  &emsp;  &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; / *S1A_IW_SLC**  
  \| &ensp;\| &ensp;\|------------------------------------- ***data (MANDATORY)*** &emsp; | ...  
  \| &ensp;\| &ensp;\| &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;  &emsp;  &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; \ *S1B_IW_SLC**  
  \| &ensp;\|---------------------------------------- ***opod*** (OPTIONAL: can be downloaded)  
  \|------------------------------------------- ***dem*** (OPTIONAL: can be downloaded)  
  ...  
  Under ***\$procdir***, for **sh_gamma2stamps**, the input parameters: **ran_look** and **azi_look** are same with the parameters of *S1.cfg* in the *table* folder (if you want doing time series processing with ***StaMPS***).


- *If you need to concatenate the SLCs of different frames:*  
  ***$procdir***  -------------------------------- cwd of running *sh_gamma.sh*  
  \| &ensp;\| &ensp;\| &ensp;\|---------------------------------- ***table*** (***MANDATORY***)  *sh_setup_gamma*  
  \| &ensp;\| &ensp;\|-------------------------------------- ***F477*** (contains data, opod and table...)  \\  
  \| &ensp;\| &ensp;\| &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;  &emsp;  &emsp;  &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;  &emsp;  ----> sh_gamma s1 ts data data   
  \| &ensp;\| &ensp;\|-------------------------------------- ***F478*** (contains data, opod and table...)  /  
  \| &ensp;\| &ensp;\|-------------------------------------- ***data (MANDATORY)***    &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;----> sh_cat_ScanSAR  
  \| &ensp;\|----------------------------------------- ***opod*** (OPTIONAL: can be downloaded)  
  \|-------------------------------------------- ***dem*** (OPTIONAL: can be downloaded)  
    ...  
  Under ***\$procdir***, for **sh_gamma2stamps**, the input parameters: **ran_look** and **azi_look** are same with the parameters of *S1.cfg* in the *table* folder (if you want doing time series processing with ***StaMPS***).


- *If you want to do multi-looking (downsampling) to the files like \*.diff, \*.cc or \*.geo.unw after you have finished the interferometry:* (the most likely case for it is that you did the interferometry with a small multi-looking factor and so there are too many pixels in every images, and hence it will be super time-demanding to do time series processing, for example, in StaMPS which cannot do such downsampling/multi-looking itself, therefore you may need to do multi-looking again to downsample the pixel number before StaMPS processing...)  
  (P.S. Mintpy and LiCSBAS support multi-looking/downsampling within the programs themselves. *NOTE: Please always consider a proper multi-look factor before you doing interferometry so you can avoid such problem at the beginning*.)  
  ***$procdir***  -------------------------------- cwd of running *sh_gamma.sh*  
  \| &ensp;\| &ensp;\| &ensp;\|---------------------------------- ***table*** (***MANDATORY***)  *sh_setup_gamma*  
  \| &ensp;\| &ensp;\|-------------------------------------- ***F477*** (contains data, opod and table...)  \\  
  \| &ensp;\| &ensp;\| &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;  &emsp;  &emsp;  &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;  &emsp;  ----> sh_gamma s1 ts data data   
  \| &ensp;\| &ensp;\|-------------------------------------- ***F478*** (contains data, opod and table...)  /  
  \| &ensp;\| &ensp;\|-------------------------------------- ***data (MANDATORY)***    &emsp; &emsp; &emsp; &emsp; &emsp; &emsp;  &emsp;----> sh_cat_ScanSAR  
  \| &ensp;\|----------------------------------------- ***opod*** (OPTIONAL: can be downloaded)  
  \|-------------------------------------------- ***dem*** (OPTIONAL: can be downloaded)  
  \|  
  \|----- ***ml\$nlook*** (multi_looking, coreg, subset and unw would created in it)  &emsp; ----> sh_ml_aga.sh  
    ...  
  
  Under ***\$procdir***, for **sh_gamma2stamps**, the input parameters: **ran_look** and **azi_look** are same with the parameters of *S1.cfg* in the *table* folder (if you want doing time series processing with ***StaMPS***). The pixels number in every images is larger because they have not been multi-looked/downsampled again.  
  
  Under the ***\$procdir*** folder, you could run *sh_ml_aga* to downsample the files, the the ***ml\$nlook*** folder can be created.  
  Under the ***ml\$nlook*** folder, *sh_ml_aga* could generate a series of folder including ***multi_looking, coreg, subset*** as well as ***unw*** (if needed). Then you can run **sh_gamma2stamps** under ***ml\$nlook***, note the input parameters of *sh_gamma2stamps* should be **ran_look x nlook** and **azi_look x nlook**! (the ran_look and azi_look are the input parameters in S1.cfg). Then the related folders and files needed by StaMPS would be generated in ***ml\$nlook***.
  
---------------------------------------------------------------------------------------------------

#### Scripts in S1_TS_proc ####
- *For TS batch processing:*
  - *sh_setup_gamma*
  - *sh_gamma*
  - *sh_read_cfg_S1*
  - *sh_preprocess_S1*  
    - *sh_grep_S1_dates*
    - *sh_get_S1_opod*
  - *sh_read_SLC_S1*
  - *sh_multi_looking*  
    - *sh_get_dem*
  - *sh_coreg_S1*
  - *sh_diff_S1*
    - for 2p: *process2pass.csh* and *sh_creat_psokinv_downsample*
  - *sh_unwrap_S1*  
  - --

- *Extra processing may need:*
  - *sh_cat_ScanSAR*
  - *sh_gamma2stamps*  
    - *sh_grep_S1_dates*
    - *sh_SLC_resample*
  - *sh_gamma2licsbas*
  - *sh_ml_aga*  
    
- [x]  All of the scripts run under ***\$procdir*** except *sh_gamma2stamps* and *sh_gamma2licsbas* which depend on whether the main working folder is ***\$procdir*** or ***ml$nlook***.

---------------------------------------------------------------------------------------------------

#### Instruction of S1_TS_proc ####

These scripts are employed to process the Sentinel-1 data, for time series processing.  
  
To process the Sentinel-1 data with GAMMA:
1. Creating the table folder with "sh_setup_gamma" command ***UNDER THE PROJECT/PROCESS DIRECTORY*** (i.e. ***\$procdir***)  
2. Editting the configure table as you need in the table folder
3. Back to ***\$procdir*** directory, running *sh_gamma* for batch processing.

**NOTE:**  
- \$ori_SARdir (original SAR directory) and \$miss_type (mission type) are two of the inputing parameters of *sh_grep_S1_dates*, *sh_grep_S1_dates* would check the mission type (S1A and/or S1B) in original SAR ZIP directory firstly, if in original SAR directory there is/are:  
  - s1a + s1b data, mission type can be specified as s1a OR s1b (only s1a OR s1b data would be processed in follow-up processing) or both (both of s1a and s1b would be processed in follow-up processing) in config table (*Note:* there may be some bugs if you choose to process **BOTH** of s1a and s1b data);  
  - s1a data only, mission type can be specified as s1a only in config table;  
  - s1b data only, mission type can be specified as s1b only in config table;  
   if mission type = **BOTH**, then now only support the setting: m1_fswa=m2_fswa, m1_lswa=m2_lswa (*sh_coreg_S1*)
- Still some bugs with "subset" option of the config table.
	
	
After batch processing, ***\$procdir*** should contain subfolder opod, dem, data, multi_looking, coreg, subset unwrap (if needed) and INSAR_$reference (for StaMPS if needed).
	
Checking the table directory to find the grep_dates_s1[ab] and the log files.

---------------------------------------------------------------------------------------------------

With any problems, please contact  
:envelope: zelong@gfz-potsdam.de  
:copyright: 2022, Zelong Guo, GFZ
