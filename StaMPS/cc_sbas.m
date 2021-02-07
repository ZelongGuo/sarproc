% This script is used for SBAS analysis with coherence-based pixels
% selection. step(1,5) thus can be skipped.
% Zelong Guo, @GFZ, Potsdam
% First vesion: 02.02.2021

clear;
clc;
maxNumCompThreads(8);


diary('cc_sbas.log')
diary on

%...

cd SMALL_BASELINES
% specified the coh-thre and image_fraction
% mt_ml_select_gamma(0.3,1);
% 
arch = computer('arch');
if ~strcmpi(arch(1:3),'win')
    cmd=['ls -1 | grep -v "^[0-9][0-9][0-9][0-9][0-9]*"'];
    [status, file_list] = system(cmd);
    % textscan is also O.K.
    file_list = strread(file_list,'%s');
    for i = 1:length(file_list)
        fprintf ('File: %s has been removed to upper directory\n',file_list{i,1});
        movefile(file_list{i,1},'..')
    end
else
    file_list = ls;
    file_list = strread(file_list,'%s');
    for i = 1:length(file_list)
        if ~exist(file_list{i,1},'dir')
            fprintf ('File: %s has been removed to upper directory\n',file_list{i,1});
            movefile(file_list{i,1},'..')
        end
    end
end

cd ..

% %   srep(1,5) is skipped...
% %   remove atmospheric phase by gacos
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


% % %   re-do phase unwrapping
% unwrap_grid_size=getparm('unwrap_grid_size');
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

