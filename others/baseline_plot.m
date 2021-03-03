clear;
clc

ref=20190306;

fid = fopen('/misc/zs3/students/IraqEQ_3yr_SBAS/subset/bperp_file_plot','r');
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
plot(datenum(date_1,'yyyymmdd'), acquisition(:,2),'ko','MarkerFacecolor','y','MarkerSize',10);

% plot the reference node
col = find(acquisition==ref);
ref = num2str(ref);
plot(datenum(ref,'yyyymmdd'), acquisition(col,2),'ko', 'MarkerFacecolor','r','MarkerSize',10);

% conected the nodes
date_2 = num2str(b(:,1));
plot(datenum(date_2,'yyyymmdd'),b(:,2),'Color',[0.69804 0.87451 0.93333],'LineWidth',2)
hold off

% a=[2 2; 2 4;2 2; 3 6];
% plot(a(:,1),a(:,2),'-')