clc;
close all;
clear all;

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(fullfile(rootDir,'aurora600A_impedance'));

experimentFolder  = '20251118_impedance_larb_1';
metaDataFile      = 'larb_08_active_100Lo_20251118.json';
dataFile          = 'larb_08_active_100Lo_20251118.dat';
waveFile          = 'larb_08_active_100Lo_20251118.dat';
analysisFile      = 'analysis_ImpedanceLengthArb_larb_08_active_100Lo_20251118.json';

outputFolder = 'system_identification';

settings.indexTimeSeries=[];

timeUnit = 'ms';
ms2s = 0.001;
s2ms = 1000;
bwMax=90;

xStepNM=11;
loptNM=2500;
xStep=xStepNM/loptNM;

%%
% Perturbation plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 4;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*3;
plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*4;
plotHorizMarginCm  = 1.5;
plotVertMarginCm   = 1.5;
baseFontSize       = 10;

[subPlotPanelPer, subPlotPerSettings]= ...
  plotConfigAdvanced(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


subPlotPanelPer(1,1,3)=sum(subPlotPerSettings.plotWidth) ...
                      +subPlotPerSettings.plotHorizontalMargin*3;

fig_perturbation=figure;

%%
% Plot the perturbation data
%%
metaDataPath  = fullfile(projectFolders.data600A,...
                         experimentFolder,metaDataFile);
metaDataStr   = fileread(metaDataPath);
metaData      = jsondecode(metaDataStr);

dataPath      = fullfile(projectFolders.data600A,experimentFolder,...
                         'data',dataFile);
data          = readAuroraData600A(dataPath,1);

analysisPath = fullfile(projectFolders.output600A_json,...
                    experimentFolder,analysisFile);
analysisStr = fileread(analysisPath);
analysis    = jsondecode(analysisStr);

lopt=data.Setup_Parameters.Fiber_Length.Value;
dlMax= lopt*0.01;
%
% Plot the perturbation data
%
subplot('Position',reshape(subPlotPanelPer(1,1,:),1,4));

t0 = metaData.segments(1).time_ms(1);
t1 = metaData.segments(4).time_ms(2);

xt = [];
for i=1:1:4
  xt = [xt, metaData.segments(i).time_ms(1)];
end
xt=xt.*ms2s;
xtLabels = cell(length(xt),1);
for i=1:1:length(xt)
  xtLabels(i)={sprintf('%1.1f',xt(i))};
end

idxW = find(data.Data.Time.Values >= t0 & data.Data.Time.Values <= t1);

l0=data.Data.Lin.Values(idxW(1));

plot([data.Data.Time.Values(idxW(1)),data.Data.Time.Values(idxW(end)) ].*ms2s,...
     [(1+0.5*xStep),(1+0.5*xStep)].*lopt,'-','Color',[1,0,0]);
hold on;
plot([data.Data.Time.Values(idxW(1)),data.Data.Time.Values(idxW(end)) ].*ms2s,...
     [(1-0.5*xStep),(1-0.5*xStep)].*lopt,'-','Color',[1,0,0]);
hold on;


plot(data.Data.Time.Values(idxW).*ms2s,...
     data.Data.Lin.Values(idxW),'-','Color',[1,1,1],'LineWidth',2);
hold on;
plot(data.Data.Time.Values(idxW).*ms2s,...
     data.Data.Lin.Values(idxW),'-','Color',[0,0,0]);
hold on;

dt = (t1-t0)*0.235*ms2s;
plot([data.Data.Time.Values(idxW(end)) ,...
      data.Data.Time.Values(idxW(end)) ].*ms2s - [dt,dt],...
     [(1-0.5*xStep),(1+0.35*xStep)].*lopt,'-','Color',[1,0,0]);
hold on;
plot([data.Data.Time.Values(idxW(end)) ].*ms2s-dt,...
     [(1+0.35*xStep)].*lopt,'^','Color',[1,0,0],...
     'MarkerFaceColor',[1,0,0],...
     'MarkerSize',2);
hold on;
dt = (t1-t0)*0.26*ms2s;
text([data.Data.Time.Values(idxW(end)) ].*ms2s-[dt],...
     [(1-0.5*xStep)].*lopt,...
     sprintf('%s\n%s%1.4f%s','$$\Delta \ell_{X}=(11\mathrm{nm}/2500\mathrm{nm})\ell_o$$',...
             '$$\Delta \ell_{X}$$ = ',xStep,'$$\ell_o$$'),...
     'HorizontalAlignment','left',...
     'VerticalAlignment','top', ...
     'FontSize',8,...
     'Color',[1,0,0]);
hold on




box off;
xlabel('Time (s)')
ylabel('Length (mm)');
title(sprintf('A. Fibre 1 perturbation about %s (%1.3f mm)',...
             '$$\ell_o$$',lopt),'HorizontalAlignment','center');
dy=0.01;
yAl = [1,1].*lopt + [-dy,dy].*(1.8*lopt) + [-1,1].*sqrt(eps);
yt = [1,1,1,1,1].*lopt + [-0.01,-0.001,0,0.001,0.01].*lopt;
ytLabels = [{sprintf('%1.3f',0.99*lopt)},...
            {''},...
            sprintf('%1.3f',lopt),...
            {''},...
            {sprintf('%1.3f',1.01*lopt)}];
yticks(yt);
yticklabels(ytLabels);
xticks(xt);
xticklabels(xtLabels);

ylim(yAl);
xlim([data.Data.Time.Values(idxW(1)),...
      data.Data.Time.Values(idxW(end)) ].*ms2s);



amp=[0.01,0.01,0.001,0.001];
plotLabel={'B.','C.','D.','E.';};

usePercentages=1;
yScale=100;

percentageSymbol='';
if(usePercentages==1)
  percentageSymbol='\%';
end

for i=1:1:4

  %
  % Add the segment specific annotation
  %
  subplot('Position',reshape(subPlotPanelPer(1,1,:),1,4));  
  t0 = metaData.segments(i).time_ms(1);
  t1 = metaData.segments(i).time_ms(2);  
  
  
  y0 = lopt*(1-amp(i));
  y1 = lopt*(1+amp(i));
  y1L= lopt*(1+amp(1));

  labelFormat='BW: 0-%1.0f Hz\n%s: %1.2f %s';
  if(amp(i)<0.01)
    labelFormat='BW: 0-%1.0f Hz\n%s: %1.3f %s';    
  end 
  labelText=sprintf(labelFormat,...
              metaData.segments(i).meta_data.bandwidth_Hz(2),...
              '$$A_{pp}$$',...
              metaData.segments(i).meta_data.amplitude_Lo(1)*2,'$$\ell_o$$');

  titleFormat='BW: 0-%1.0f Hz, %s: %1.2f %s';
  if(amp(i)<0.01)
    titleFormat='BW: 0-%1.0f Hz, %s: %1.3f %s';    
  end   
  titleText=sprintf(titleFormat,...
              metaData.segments(i).meta_data.bandwidth_Hz(2),...
              '$$A_{pp}$$',...
              metaData.segments(i).meta_data.amplitude_Lo(1)*2,'$$\ell_o$$');

  text((t0+t1)*0.5*ms2s,yAl(2),...
       labelText,...
      'HorizontalAlignment','center', ...
      'VerticalAlignment','top',...
      'FontSize',8);
  hold on;


  idxS = find(data.Data.Time.Values >= metaData.segments(i).time_ms(1) ...
            & data.Data.Time.Values <= metaData.segments(i).time_ms(2)); 

  waveNorm=((data.Data.Lin.Values(idxS)-lopt)./lopt).*yScale;  
  
  ss = getSummaryStatistics(waveNorm);

  labelTitle='';
  
  if(i==1)
    labelTitle='Sarcomere-scale $$\Delta \ell$$';
  end
  labelTextSS=...
       sprintf('%s\n %s=%1.1f %s\n %s=%1.1f %s',...
               labelTitle,...
                '$$A_{pp}$$',(ss.max-ss.min)*loptNM*(1/yScale),'nm',...
                'IQR',(ss.y(5)-ss.y(3))*loptNM*(1/yScale),'nm');

  dtxt=(t1-t0).*0.1;
  text((t0+dtxt)*ms2s,yAl(1),...
       labelTextSS,...
       'VerticalAlignment','bottom',...
       'HorizontalAlignment','left',...
       'FontSize',8);
  hold on;

  %
  % Plot the power spectrum of each segment
  %
  subplot('Position',reshape(subPlotPanelPer(2,i,:),1,4));

  x=data.Data.Lin.Values(idxS)-lopt;  

  dt = data.Data.Time.Values(2)-data.Data.Time.Values(1);
  if(strcmp(data.Data.Time.Unit,'ms'))
    dt=dt*ms2s;
  end
  fs = 1/dt;
  y=fft(x);
  n=length(x);
  f= [0:(n-1)].*(fs/n);
  p=abs(y).^2 /n;
  p=p.*1e6;

  idxBW = find(f >= 0 & f <=1.5*bwMax);
  plot(f(idxBW),p(idxBW),'-','Color',[0,0,0]);
  hold on;

  yMax = max(p(idxBW));
  yHalf= yMax*1/sqrt(2);

  bwHz = metaData.segments(i).meta_data.bandwidth_Hz(2);
  plot([0,bwHz,bwHz],[yHalf,yHalf,0],'-','Color',[0,0,1]);
  hold on;
  text(bwHz,yHalf,sprintf('-3dB'),...
      'HorizontalAlignment','left','FontSize',8);
  hold on;
  

  xticks([0,35,90]);
  xlim([0,bwMax*1.5]);
  ylim([0,yMax]);
  xlabel('Frequency (Hz)');
  ylabel(sprintf('PSD %s',...
                 '$$(\mathrm{mm}^2/\mathrm{Hz}) 10^{-6}$$'));

  title([plotLabel{i}, titleText]);
  box off;

end

here=1;



fig_perturbation=configPlotExporter(fig_perturbation, ...
                    subPlotPerSettings.pageWidthCm, ...
                    subPlotPerSettings.pageHeightCm);

fileName =    ['fig_perturbation'];
print('-dpdf', fullfile(projectFolders.output600A_plots, ...
                        outputFolder,[fileName,'.pdf']));    
saveas(fig_perturbation,fullfile(projectFolders.output600A_plots,...
                                 outputFolder,[fileName,'.fig']));
close(fig_perturbation);
