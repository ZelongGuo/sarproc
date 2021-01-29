
clear;
clc;

% fid = fopen('/misc/zs3/students/zelong_guo_temp2/geo/20180510.lat','r');
% a = fread(fid,[25582,2843]);
% fid5 = fopen('/misc/zs3/students/zelong_guo_temp/geo/20180510.lat','r');
% b = fread(fid5,[48592,10026], 'float', 'b');
% fclose(fid5);
% % 
% 
% fid4 = fopen('/misc/zs3/students/zelong_guo_temp2/geo/north', 'r');
% north = fread(fid4, [7919,3647], 'float','b');
% fclose(fid4);
% 
% fid = fopen('/misc/zs3/students/zelong_guo_temp2/geo/east','r');
% east = fread(fid,[7919,3647], 'float', 'b');
% fclose(fid);

% fid2 = fopen('/misc/zs3/students/zelong_guo_temp2/geo/20180510.lat', 'r');
% lat = fread(fid2, [6395,2843], 'float', 'b');
% fclose(fid2);
% % 
fid3 = fopen('/misc/zs3/students/zelong_guo_temp2/INSAR_20180510/geo/20180510.lon', 'r');
lon = fread(fid3, [6395, 2843], 'float', 'b');
fclose(fid3);


fid4 = fopen('/misc/zs3/students/zelong_guo_temp2/INSAR_20180510/geo/20180510.lat', 'r');
lat = fread(fid4, [6395, 2843], 'float', 'b');
fclose(fid4);




