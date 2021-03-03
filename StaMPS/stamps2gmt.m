% stamps2gmt.m, run under INSAR_$reference filder
% default method for reducing ATM is by GACOS. IF another method used, you should change 
% this script accordingly.
% default reference image is the first iamge
% do not subtract the mean value of the reference points when ploting
% unwarapping results, i.e., ps_plot('u') ect. if you want getting the mean
% deformation rate you should select an reference point,but this script
% need be changed accordingly.
maxNumCompThreads('automatic');

%+++++++++++++++++++++++++++++++ PARAMETERS NEEDED ++++++++++++++++++++++++++++++++++%
path = 'T174A';                  % % % NO. of the track
flag = 2;   % 1 for outputing .unw files; 2 for outputing velocity .dat files
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++% 
% % % % % if flag ==1, you should specify the following num_ifg:
num_ifg = [18 32 61 90];          % % % specify as vector
% % % % % if flag ==2, you should specify the following paramenter:
ifg_end_num = 90;                 % % % which ifg you selected as the final ifg, which will be used for cumulative LOS disp. and ploting 
points_centre = [45.959 34.911; 45.625 34.5; 46.2 34.65; 45.7 34.5; 45.625 34.61]; % % % specified as matrix if many points [1 2; 3 4; 5 6; ...]
points_rad = [32];     % % % default = 100
plot_flag = 2;         % % % 1 fot plotting the time series of 1st selected points, no std outputting
                       % % % 2 for plotting the time series of mean values of all of the selected points, std would be calculated
                       % % % 3 for plotting the time series of 1st selected points, std would be calculated with the far-field reference point area
                       % % % if plot_flag = 2, the raduis should be specified properly to make sure 3-4 points be selected
% % % if plot_flag = 3, far-field area would be used for std calculation, you should specify following parameters
refcentre = [47.4 34.4];        % % % used for calculating the far-field std if plot_flag == 3
refrad = [100];                 % % % meter
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++% 



% related to the oscilator drift correction - envisat only
forced_sm_flag = 1;
if forced_sm_flag==1
    [ph_unw_eni_osci,v_envi_osci] = env_oscilator_corr([],forced_sm_flag);
else
    % Compute the envisat oscialator drift when needed
    [ph_unw_eni_osci,v_envi_osci] = env_oscilator_corr;
end

% % % % for gacos correction
aps_flag = 35;
if ~exist('tca2.mat','file')
    fprintf('tca2.mat do not exist.\n')
    sb_invert_aps(aps_flag);
end

v_list = who;
if ~ismember('ps2',v_list)
    fprintf('Now load ps2.mat.\n')
    ps2 = load('ps2.mat')
end
if ~ismember('uw',v_list)
    fprintf('Now load phuw2.mat.\n')
    uw = load('phuw2.mat')
end
if ~ismember('aps',v_list)
    fprintf('Now load tca2.mat.\n')
    aps = load('tca2.mat')
end
if ~ismember('scla',v_list)
    fprintf('Now load scla2.mat.\n')
    scla = load('scla2.mat')
end
if ~ismember('parm',v_list)
    fprintf('Now load parms.mat.\n')
    parm = load('parms.mat')
end


[aps_corr,fig_name_tca] = ps_plot_tca(aps,aps_flag);
ph_all=uw.ph_uw;
ph_all=uw.ph_uw - aps_corr - scla.ph_scla;

% % subtract of oscilator drift in case of envisat
ph_all = ph_all-ph_unw_eni_osci;
% % deramping ifgs
if ~ismember('ph_all_deramp',v_list)
    fprintf('Now deramp the phase.\n');
    [ph_all_deramp] = ps_deramp(ps2,ph_all);
end
% % clear uw aps aps_corr scla
ph_disp = ph_all_deramp;
% % % set first image as reference image
ph_disp=ph_disp-repmat(ph_all_deramp(:,1),1,size(ph_disp,2));

lonlat = ps2.lonlat;
wavelength = parm.lambda;
LON = lonlat(:,1);
LAT = lonlat(:,2);

ph_disp_end = double(-ph_disp(:,ifg_end_num)*wavelength/4/pi*1000);
max_colorbar = max(ph_disp_end);
min_colorbar = min(ph_disp_end);

if flag==1
    for i = 1:length(num_ifg)
        file_name = sprintf('INSAR_%s_%d', path,num_ifg(i));
        WRA = double(ph_disp(:,num_ifg(i)));
        UNW = -WRA*wavelength/4/pi*1000;
        figure;
        hold on;
        title(file_name,'Interpreter', 'none');
        scatter(LON,LAT,[],UNW,'filled');
        colormap jet
        c = colorbar
        c.Label.String = 'mm'
        caxis([min_colorbar max_colorbar])
        hold off;

        out = [LON, LAT, UNW];
        save([file_name,'.unw'], 'out', '-ascii');
    end
    clear i
elseif flag == 2
    
   if plot_flag ==3
       ref_centre_lonlat = getparm('ref_centre_lonlat');
       ref_radius = getparm('ref_radius');
       if ~isempty(ref_centre_lonlat) || ~isempty(ref_radius)
           setparm('ref_centre_lonlat',refcentre);
           setparm('ref_radius',refrad);
           ref_ps = ps_setref;
       else
           error('Error with the setting of reference area!/n');
       end
   
       ref_ph=(ph_disp(ref_ps,:));
       mean_ph=zeros(1,size(ph_disp,2));
       for i=1:size(ph_disp,2)
           mean_ph(i)=mean(ref_ph(~isnan(ref_ph(:,i)),i),1);
           if isnan(mean_ph(i))
              mean_ph(i)=0;
              error(['Interferogram (' num2str(i) ') does not have a reference area\n'])
           end
       end
       clear i
       n_ps = ps2.n_ps;
   end
% % % % % %  do NOT subtract the mean value of the reference area
%     ph_disp_vel=ph_disp-repmat(mean_ph,n_ps,1);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    ph_disp_vel = ph_disp;
    % % radians to mm
    ph_disp_vel = -ph_disp_vel*wavelength/4/pi*1000;
    
% % % % %     get the time series of the selected points
    if isempty(points_rad)
       points_rad = 100;       % if point radius is not defined, specify it as 100 m
    end
    
    out_points = [];
    out_points_std = [];
    if plot_flag ==3
        mean_ph_as_std = -mean_ph*wavelength/4/pi*1000;
    end
    for i = 1:size(points_centre,1)
        points_ps=find(ps2.lonlat(:,1)>-inf&ps2.lonlat(:,1)<inf&ps2.lonlat(:,2)>-inf&ps2.lonlat(:,2)<inf);
        points_xy=llh2local(points_centre(i,:)',ps2.ll0)*1000;      % km to m
        p_xy=llh2local(ps2.lonlat(points_ps,:)',ps2.ll0)*1000;       % km to m
        p_dist_sq=(p_xy(1,:)-points_xy(1)).^2+(p_xy(2,:)-points_xy(2)).^2; 
        points_ps=points_ps(p_dist_sq<=points_rad^2);
        
        if isempty(points_ps)
            error('Can not select NO.%d point at radius %d, please enlarge the radius!\n ',i,points_rad);
        else
            num_points_can = length(points_ps);
            if plot_flag == 1
                fprintf('NO.%d point: %d candidate points selected, the 1st one would be selected and plotted.\n',i,num_points_can);
                out_points = [out_points ph_disp_vel(points_ps(1),:)'];
            elseif plot_flag == 2
                fprintf('NO.%d point: %d candidate points selected, the mean value (and std) of the these points would be calculated and plotted.\n',i,num_points_can);
                all_points = ph_disp_vel(points_ps(:),:);
                mean_points = mean(all_points,1);
                std_points = std(all_points,1);
                out_points = [out_points mean_points'];
                out_points_std = [out_points_std std_points'];
            elseif plot_flag ==3    %the mean values of the reference arae (non-deformation, far-field area) as std 
                fprintf('NO.%d point: %d candidate points selected, the 1st one would be selected and plotted.\n',i,num_points_can);
                fprintf('   %d reference points selected, the mean value would be used for std.\n', length(ref_ps));
                out_points = [out_points ph_disp_vel(points_ps(1),:)'];
                out_points_std = [out_points_std mean_ph_as_std'];
            else
                error('Please input the correct plot_falg.\n');
            end
        end
        
%         eval(['out_point',num2str(i), '=', 'ph_disp_vel(points_ps(1),:)',';']);
%         out_name = strcat('ph_disp_vel_point',num2str(i));
        
    end
    clear i;
    out_points = double(out_points);
    out_points_std = double(out_points_std);
      
 
        
% % % % %     plot the cumulative LOS displacements and ref and selected points     
    file_name = sprintf('INSAR_%s_%d', path,ifg_end_num);
    figure;
    hold on;
    title(file_name,'Interpreter', 'none');
    scatter(LON,LAT,[],ph_disp_end,'filled');
    colormap jet;
    c = colorbar;
    c.Label.String = 'mm';
    caxis([min_colorbar max_colorbar]);
%     % % plot reference point
%     plot(refcentre(1), refcentre(2), '^', 'MarkerEdgeColor','k','MarkerFaceColor','r');
%     text(refcentre(1), refcentre(2),'REF');
    % % plot the selected points with o
    for i = 1:size(points_centre,1)
        plot(points_centre(i,1),points_centre(i,2),'o','MarkerEdgeColor','k','MarkerFaceColor','r');
        p_str = strcat('P',num2str(i));
        text(points_centre(i,1),points_centre(i,2),p_str);
    end  
    clear i;
    hold off;
    
% % % % %     plot time series of selected points
    figure;
    hold on;
    title(file_name,'Interpreter','none');
    xlabel('Acquisition');
    ylabel('LOS displacement (mm)');
    grid on;
    for i=1:size(out_points,2)
        dis_name = strcat('P',num2str(i));
        if plot_flag ==1
            plot(out_points(:,i),'-d','DisplayName',dis_name);
        else
            x = 1:size(out_points,1);
            errorbar(x, out_points(:,i),out_points_std(:,i),'-o','DisplayName',dis_name);
        end
    end
    hold off
    legend
    
% % % % %     output the 'out_points' (and 'out_points_std' if existent) to a binary file for GMT ploting
    for i = 1:size(out_points,2)
        out_day = datestr(ps2.day,'yyyy-mm-ddT');
        if plot_flag ==1
            out_name = sprintf('INSAR_%s_P%d_los.dat', path,i);
                     
            fid = fopen(out_name,'w');
            for j = 1:size(out_points,1)
                fprintf(fid,'%s %s\n', out_day(j,:), num2str(out_points(j,i)));
            end
            fclose(fid)
        else
            out_name = sprintf('INSAR_%s_P%d_los_std.dat', path,i);
                        
            fid = fopen(out_name,'w');
            for j = 1:size(out_points,1)
                fprintf(fid,'%s %s %s\n', out_day(j,:), num2str(out_points(j,i)), num2str(out_points_std(j,i)));
            end
            fclose(fid)
        end
    end         

       
else
    error('Please input the correct flag./n');

    
end
