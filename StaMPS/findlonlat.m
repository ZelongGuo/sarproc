clear
clc
ps = load('ps2.mat');
ph_uw=load('phuw2.mat');


lonlat = ps.lonlat;
ph_uw_all = ph_uw.ph_uw;

min_lon = 45.60;
max_lon = 45.61;
min_lat = 34.60;
max_lat = 34.61;

lon = find(lonlat(:,1) < max_lon & lonlat(:,1) > min_lon);
lat = find(lonlat(:,2) < max_lat & lonlat(:,2) > min_lat);
index = intersect(lon,lat);
% 
% figure;
% plot(ph_uw_all(index,:))