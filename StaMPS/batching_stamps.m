% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Run all steps automatically
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clc; clear;
% delete 'batching_stamps.log'
% diary('batching_stamps.log'); 
% diary on;

%        amplitude difference dispersion (0.4 for PS and 0.6 for SBAS)
ADD_PS=0.4;
%       number of patches in range and azimuth
NPatchesRange=6;
NPatchesAzimuth=5;
%       parameters for Stamps
density_rand=1;
weed_standard_dev=0.6
weed_time_win=365;
merge_resample_size=100;
unwrap_grid_size=100;
unwrap_time_win=365;
masterdate='20180510';


% %      prepare data
% cmd=['mt_prep_gamma ' masterdate ' ' pwd ' ' num2str(ADD_PS) ' '...
%     num2str(NPatchesRange) ' ' num2str(NPatchesAzimuth) ' 50 50'];
% system(cmd);
% 
% diary off;


    
%       Start Stamps processing
delete 'batching_stamps_1.log'
diary('batching_stamps_1.log'); 
diary on;
stamps(1,1);
diary off;



delete 'batching_stamps2.log'
diary('batching_stamps2.log'); 
diary on;

%       set some paremeters
setparm('density_rand', density_rand);
setparm('weed_standard_dev', weed_standard_dev);
setparm('weed_time_win', weed_time_win);
setparm('merge_resample_size', merge_resample_size);
setparm('unwrap_grid_size', unwrap_grid_size);
setparm('unwrap_time_win', unwrap_time_win);

%quit

filter_grid_size=50;
setparm('filter_grid_size', filter_grid_size);

stamps(2,5)

diary off;
