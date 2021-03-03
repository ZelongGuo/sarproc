%  
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % Run all steps automatically
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear;
maxNumCompThreads(8);

delete 'batching_stamps.log'
diary('batching_stamps.log'); 
diary on;

% %        amplitude difference dispersion (0.4 for PS and 0.6 for SBAS)
ADD_PS=0.6;
% %       number of patches in range and azimuth
NPatchesRange=4;
NPatchesAzimuth=4;
% %       parameters for Stamps
density_rand=1;
weed_standard_dev=0.6;
weed_time_win=365;
merge_resample_size=100;
unwrap_grid_size=100;
unwrap_time_win=365;
masterdate='20180510';


% %      prepare data
cmd=['mt_prep_gamma ' masterdate ' ' pwd ' ' num2str(ADD_PS) ' '...
    num2str(NPatchesRange) ' ' num2str(NPatchesAzimuth) ' 50 50'];
system(cmd);

diary off;


    
% %       Start Stamps processing
delete 'batching_stamps_1.log'
diary('batching_stamps_1.log'); 
diary on;
stamps(1,1);
diary off;



delete 'batching_stamps2.log'
diary('batching_stamps2.log'); 
diary on;

% %       set some paremeters
setparm('density_rand', density_rand);
setparm('weed_standard_dev', weed_standard_dev);
setparm('weed_time_win', weed_time_win);
setparm('merge_resample_size', merge_resample_size);
setparm('unwrap_grid_size', unwrap_grid_size);
setparm('unwrap_time_win', unwrap_time_win);

%quit


% % stamps(2,5) is not convenient for continuous processing
stamps(2,2)
stamps(3,3)
stamps(4,4)
stamps(5,5)
diary off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %   merge all pathches
delete 'batching_stamps3.log'
diary('batching_stamps3.log')
diary on

stamps(5,5)

%   remove atmospheric phase by gacos
getparm_aps;
load('parms.mat');
save('parms_aps.mat', 'heading', 'lambda', '-append');
setparm_aps('gacos_datapath','./APS')
setparm_aps('UTC_sat','15:00')
aps_weather_model('gacos',1,3)

% setparm('drop_ifg_index',[49:83])
% setparm('drop_ifg_index', [14,26])
% setparm('drop_ifg_index',[33:83])


%   phase unwraping and time series analysis
setparm('tropo', 'a_gacos')
setparm('subtr_tropo', 'y')

% % unwrap_hold_good_value only avaliable for SBAS
setparm('unwrap_hold_good_value', 'n');
setparm('unwrap_method', '3D');

stamps(6,7)


% %   re-do phase unwrapping
unwrap_grid_size=getparm('unwrap_grid_size');
% setparm('unwrap_grid_size',unwrap_grid_size-10);
% setparm('unwrap_grid_size',100);

stamps(6,6)
setparm('scla_deramp','y')

stamps(7,7)
stamps(6,7)

stamps(8,8)

diary off;

% %     towarding the satellite
% ps_plot('v-dao','a_gacos',0,0,0,'ts')





