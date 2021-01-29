%   merge all pathches
delete 'batching_stamps3.log'
diary('batching_stamps3.log')
diary on

% stamps(5,5)


%   remove atmospheric phase by gacos
getparm_aps;
load('parms.mat');
save('parms_aps.mat', 'heading', 'lambda', '-append');
setparm_aps('gacos_datapath','./APS')
setparm_aps('UTC_sat','15:00')
aps_weather_model('gacos',1,3)


%   phase unwraping and time series analysis
setparm('tropo', 'a_gacos')
setparm('subtr_tropo', 'y')
stamps(6,7)


%   re-do phase unwrapping
unwrap_grid_size=getparm('unwrap_grid_size');
setparm('unwrap_method', '3D');
setparm('unwrap_hold_good_value', 'y');
% setparm('unwrap_grid_size',unwrap_grid_size-10);
setparm('unwrap_grid_size',100);

stamps(6,6)
setparm('scla_deramp','y')

stamps(7,7)
stamps(6,7)

diary off;

% %     towarding the satellite
% ps_plot('v-dao','a_gacos',0,0,0,'ts')


% quit;

