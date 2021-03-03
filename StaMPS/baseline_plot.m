% % % % % This script can be used for plot baselines distribution.
% % % % % Input File: bperp_file

clear;
clc
% % % % % % % % % % % % % %  PARAMETERS NEEDED % % % % % % % % % % % % % % 
pass = 'T072A';
ref=20190306;
fid = fopen('bperp_file_plot','r');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 


data = textscan(fid, '%f%f%f%f%f%f%f%f%f');
fclose(fid);

master = data{2};
slave = data{3};
m_baseline = data{8};
s_baseline = data{9};

% sort the data according to the date
msb_1 = [master slave m_baseline s_baseline];
msb_2 = sortrows(msb_1);
msb = [msb_2(:,1) msb_2(:,3) msb_2(:,2) msb_2(:,4)];

figure;
hold on;
axis on;
grid on;
ylabel('Perpendicular baseline (m)')
xlabel('Acquisition')


b=[];
for i=1:length(msb)
    a = [msb(i,1) msb(i,2); msb(i,3) msb(i,4)];
    b = [b; a];
end

% remove duplicates
acquisition=unique(b,'rows');
date_1 = num2str(acquisition(:,1));

% plot the nodes
plot(datenum(date_1,'yyyymmdd'), acquisition(:,2),'ko','MarkerFacecolor','r','MarkerSize',6);

% plot the reference node
col = find(acquisition==ref);
ref = num2str(ref);
plot(datenum(ref,'yyyymmdd'), acquisition(col,2),'ko', 'MarkerFacecolor','g','MarkerSize',6);

% conected the nodes
date_2 = num2str(b(:,1));
plot(datenum(date_2,'yyyymmdd'),b(:,2),'Color','k','LineWidth',1)
hold off

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % input the files for GMT ploting % % % % % % % % % % % % % % % % % % 
date = num2str(b(:,1));
yr=date(:,1:4);
mm=date(:,5:6);
dd=date(:,7:8);
date_new = strcat(yr,'-',mm,'-',dd,'T');
filename = strcat('GMT_',pass,'.txt');
fid = fopen(filename,'w');
value = num2str(b(:,2));
for i=1:size(date_new,1)
    fprintf(fid, '%s %s\n', date_new(i,:), value(i,:));
end
fclose(fid)
