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

plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*2.5;
plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*3.5;
plotHorizLeftPageMarginCm=2;
plotHorizMarginCm  = 0.4;
plotVertMarginCm   = 1.5;
baseFontSize       = 10;

[subPlotPanelPer, subPlotPerSettings]= ...
  plotConfigAdvanced( numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizLeftPageMarginCm,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


subPlotPanelPer(1,1,3)=sum(subPlotPerSettings.plotWidth) ...
                      +subPlotPerSettings.plotHorizontalMargin*3;

fig_perturbation=figure;

amp=[0.01,0.01,0.001,0.001];
plotLabel={'B.','C.','D.','E.';};

usePercentages=0;
yScale=1;


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

t0 = metaData.segments(1).time_ms(1).*ms2s;
t1 = metaData.segments(4).time_ms(2).*ms2s;

xt = [];
for i=1:1:4
  xt = [xt, metaData.segments(i).time_ms(1).*ms2s-t0];
end
xt=[xt,(t1-t0)];
xtLabels = cell(length(xt),1);
for i=1:1:length(xt)
  xtLabels(i)={sprintf('%1.1f',xt(i))};
end

idxW = find(data.Data.Time.Values >= t0*s2ms & data.Data.Time.Values <= t1*s2ms);

timeV=(data.Data.Time.Values-t0*s2ms);

%waveNorm=(data.Data.Lin.Values(idxW)-lopt)./lopt;
waveNormPercent=((data.Data.Lin.Values-lopt)./lopt).*yScale;  

plot([timeV(idxW(1)),timeV(idxW(end)) ].*ms2s,...
     [(0.5*xStep),(0.5*xStep)].*yScale,'-','Color',[0,0,1]);
hold on;
plot([timeV(idxW(1)),timeV(idxW(end)) ].*ms2s,...
     [(-0.5*xStep),(-0.5*xStep)].*yScale,'-','Color',[0,0,1]);
hold on;


plot(timeV(idxW).*ms2s,...
     waveNormPercent(idxW),'-','Color',[1,1,1],'LineWidth',2);
hold on;
plot(timeV(idxW).*ms2s,...
     waveNormPercent(idxW),'-','Color',[0,0,0]);
hold on;

dt = (t1-t0)*0.235*ms2s;
plot([timeV(idxW(end)) ,...
      timeV(idxW(end)) ].*ms2s - [dt,dt],...
     [(-0.5*xStep),(0.35*xStep)].*yScale,'-','Color',[0,0,1]);
hold on;
plot([timeV(idxW(end)) ].*ms2s-dt,...
     [(0.35*xStep)].*yScale,'^','Color',[0,0,1],...
     'MarkerFaceColor',[0,0,1],...
     'MarkerSize',2);
hold on;
dt = (t1-t0)*0.26;
text([timeV(idxW(end)) ].*ms2s-[dt],...
     [-(0.6*xStep)].*yScale,...
     sprintf('%s\n%s%1.4f%s','$$\Delta \tilde{\ell}_{X}=(11\mathrm{nm}/2500\mathrm{nm})\ell_o$$',...
             '$$\Delta \tilde{\ell}_{X}$$ = ',xStep,'$$\ell_o$$'),...
     'HorizontalAlignment','left',...
     'VerticalAlignment','top', ...
     'FontSize',8,...
     'Color',[0,0,1]);
hold on




box off;
xlabel('Time (s)')
ylabel('Norm. Length ($$\Delta \ell / \ell_o$$)');
title(sprintf('A. Perturbation waveform'),'HorizontalAlignment','center');
dy=0.01*yScale;
yAl = [-dy,dy] + [-dy,dy] + [-1,1].*sqrt(eps);
yt = [-0.01,-0.001,0,0.001,0.01].*yScale;
ytLabels = [{sprintf('%1.2f',yt(1))},...
            {''},...
            sprintf('%1.0f',0),...
            {''},...
            {sprintf('%1.2f',yt(end))}];
yticks(yt);
yticklabels(ytLabels);
xticks(xt);
xticklabels(xtLabels);

ylim(yAl);
xlim([timeV(idxW(1)),...
      timeV(idxW(end)) ].*ms2s);




percentageSymbol='';
if(usePercentages==1)
  percentageSymbol='\%';
end

for i=1:1:4

  %
  % Add the segment specific annotation
  %
  subplot('Position',reshape(subPlotPanelPer(1,1,:),1,4));  
  t0S = metaData.segments(i).time_ms(1)-t0*s2ms;
  t1S = metaData.segments(i).time_ms(2)-t0*s2ms;  
  
  
  y0 = lopt*(1-amp(i));
  y1 = lopt*(1+amp(i));
  y1L= lopt*(1+amp(1));

  labelFormat='%s %1.0f Hz-%1.2f %s';
  if(amp(i)<0.01)
    labelFormat='%s %1.0f Hz-%1.3f %s';    
  end 
  labelText=sprintf(labelFormat,...
              plotLabel{i},...
              metaData.segments(i).meta_data.bandwidth_Hz(2),...
              metaData.segments(i).meta_data.amplitude_Lo(1)*2,'$$\ell_o$$');

  titleFormat='%1.0f Hz-%1.2f %s';
  if(amp(i)<0.01)
    titleFormat='%1.0f Hz-%1.3f %s';    
  end   
  titleText=sprintf(titleFormat,...
              metaData.segments(i).meta_data.bandwidth_Hz(2),...
              metaData.segments(i).meta_data.amplitude_Lo(1)*2,'$$\ell_o$$');

  text((t0S+t1S)*0.5*ms2s,yAl(2),...
       labelText,...
      'HorizontalAlignment','center', ...
      'VerticalAlignment','top',...
      'FontSize',8);
  hold on;


  idxS = find(data.Data.Time.Values >= metaData.segments(i).time_ms(1) ...
            & data.Data.Time.Values <= metaData.segments(i).time_ms(2)); 

  waveSegmentNorm=((data.Data.Lin.Values(idxS)-lopt)./lopt).*yScale;  

  
  ss = getSummaryStatistics(waveSegmentNorm);
  %
  % Normalised Scale summary statistics
  %


  %
  % Sarcomere Scale summary statistics
  %
  labelTitle='';
  
  if(i==1)
    labelTitle='Sarcomere-scale $$\Delta \ell$$';
  end
  labelTextSS=...
       sprintf('%s\n%s: %1.1f%s\n%s: %1.1f %s',...
               labelTitle,...
                '$$\mathrm{A}_{pp}$$',(ss.max-ss.min)*loptNM*(1/yScale),'nm',...
                'IQR',(ss.y(5)-ss.y(3))*loptNM*(1/yScale),'nm');

  dtxt=(t1S-t0S).*0.1+t0S;
  text((dtxt)*ms2s,yAl(1),...
       labelTextSS,...
       'VerticalAlignment','bottom',...
       'HorizontalAlignment','left',...
       'FontSize',8);
  hold on;



  %
  % Plot the power spectrum of each segment
  %
  subplot('Position',reshape(subPlotPanelPer(2,i,:),1,4));

  x=waveSegmentNorm;  

  dt = data.Data.Time.Values(2)-data.Data.Time.Values(1);
  if(strcmp(data.Data.Time.Unit,'ms'))
    dt=dt*ms2s;
  end
  fs = 1/dt;
  y=fft(x);
  n=length(x);
  f= [0:(n-1)].*(fs/n);
  p=abs(y).^2 /n;

  pScale=1e6;
  p=p.*pScale;



  idxBW = find(f >= 0 & f <=1.5*bwMax);

  yMax = max(p(idxBW));
  yHalf= yMax*1/sqrt(2);  
  
  %plot([f(idxBW(1)),f(idxBW(end))],[yHalf,yHalf],'-','Color',[0,0,1]);
  %hold on;
  %text(f(idxBW(end)),yHalf,'-3dB',...
  %     'HorizontalAlignment','right',...
  %     'VerticalAlignment','top',...
  %     'FontSize',8,...
  %     'Color',[0,0,1]);
  %hold on;
  plot(f(idxBW),p(idxBW),'.','Color',[0,0,0]);
  hold on;


  %bwHz = metaData.segments(i).meta_data.bandwidth_Hz(2);
  %plot([0,bwHz,bwHz],[yHalf,yHalf,0],'-','Color',[0,0,1]);
  %hold on;
  %text(bwHz+5,yHalf,sprintf('-3dB'),...
  %    'HorizontalAlignment','left','FontSize',8);
  %hold on;
  

  xticks([0,35,90]);
  yticks([0,yMax]);
  
  if(yMax > 10)
    yticklabels([{sprintf('%1.0f',0)},{sprintf('%1.0f',yMax)}]);
  else
    yticklabels([{sprintf('%1.0f',0)},{sprintf('%1.1f',yMax)}]);
  end

  xlim([0,bwMax*1.5]);
  ylim([0,yMax*1.15]);
  xlabel('Frequency (Hz)');
  if(i==1)
  ylabel([{'Norm. Power Spectral Density '},...
    {sprintf('%s','$$((\ell/\ell_o)^2/\mathrm{Hz})$$')}]);
  end
  title([plotLabel{i},' ', titleText]);
  box off;

  text(0,yMax*1.15,sprintf('%s',['$$\times10^{-',num2str(log10(pScale)),'}$$']),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','top',...
       'FontSize',8);
  hold on;

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
