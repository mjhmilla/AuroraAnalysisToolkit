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
numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*5;
plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*5;
plotHorizMarginCm  = 2.5;
plotVertMarginCm   = 2;
baseFontSize       = 10;

[subPlotPanel, subPlotSettings]= ...
  plotConfigAdvanced(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 



fig_sigProc=figure;


%%
% Read in the files
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

cs=getPaulTolColourSchemes('vibrant');

segId=4;

nPlots=numberOfVerticalPlotRowsGeneric*numberOfHorizontalPlotColumnsGeneric;
xyGroup(nPlots)=struct('idS',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[]);

for i=1:1:nPlots
  xyGroup(i)=struct('idS',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[]);

  xyGroup(i).left  = ...
    struct('y','','first',0,'yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'legend','',...
           'scale',1);

  xyGroup(i).right = ...
    struct('y','','yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'legend','',...
           'scale',1);    
end

scaleLength=1000;
scaleForce =1000;
scalePhase=(180/pi);
lengthUnit='mm';
forceUnit='mN';
scaledLengthUnit='\mu m';
scaledForceUnit='\mu N';

ssx=getSummaryStatistics(analysis(segId).segment.H2.x.*scaleLength);
ssy=getSummaryStatistics(analysis(segId).segment.H2.y.*scaleForce);
ssG=getSummaryStatistics(analysis(segId).segment.H2.gain);
ssP=getSummaryStatistics(analysis(segId).segment.H2.phase);
ssS=getSummaryStatistics(analysis(segId).segment.H2.storage);
ssL=getSummaryStatistics(analysis(segId).segment.H2.loss);


%Length + force
idx=1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=1;
xyGroup(idx).col=1;
xyGroup(idx).x='time';
xyGroup(idx).xTicks=[0:1:4];
xyGroup(idx).xLim =[0,2^12/1000] + [-1,1].*sqrt(eps);
xyGroup(idx).xLabel='Time (s)';
xyGroup(idx).xData =[];
xyGroup(idx).title='A. Length and force measurements';

xyGroup(idx).left.first=0;
xyGroup(idx).left.y='x';
xyGroup(idx).left.scale=scaleLength;
xyGroup(idx).left.yTicks = round([-10,ssx.min,ssx.max,10],1);
xyGroup(idx).left.yLim= [-10,10];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Length (%s)',['$$',scaledLengthUnit,'$$']);
xyGroup(idx).left.lineColor = [0,0,0];
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.legend = '';

xyGroup(idx).right.y='y';
xyGroup(idx).right.scale=scaleForce;
xyGroup(idx).right.yTicks = round([-10,-ssy.std,0,ssy.std,10],1);
xyGroup(idx).right.yLim= [-10,10];
xyGroup(idx).right.yLim=xyGroup(idx).right.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).right.yLim);
xyGroup(idx).right.yLabel=sprintf('Force (%s)',['$$',scaledForceUnit,'$$']);
xyGroup(idx).right.lineColor = cs.teal;
xyGroup(idx).right.fillColor = xyGroup(idx).right.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).right.legend = '';

%Coherence-sq
idx=idx+1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=1;
xyGroup(idx).col=2;
xyGroup(idx).x='frequencyHz';
xyGroup(idx).xTicks=[0:30:90];
xyGroup(idx).xLim =[-10,100];
xyGroup(idx).xLabel='Frequency (Hz)';
xyGroup(idx).xData =[];
xyGroup(idx).title='B. Linearity assessment';

xyGroup(idx).left.y='coherenceSq';
xyGroup(idx).left.scale=1;
xyGroup(idx).left.yTicks = ...
  round([0,analysis(segId).segment.H2.coherenceSquaredThreshold,1],2);
xyGroup(idx).left.yLim= [min(xyGroup(idx).left.yTicks),...
                         max(xyGroup(idx).left.yTicks)];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Coherence%s','$$^2$$');
xyGroup(idx).left.lineColor = [0,0,0];
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.legend = '';

xyGroup(idx).right.y      = [];
xyGroup(idx).right.scale  = [];
xyGroup(idx).right.yTicks = [];
xyGroup(idx).right.yLim   = [];
xyGroup(idx).right.yLim   = [];
xyGroup(idx).right.yLabel = '';
xyGroup(idx).right.lineColor = [];
xyGroup(idx).right.fillColor = [];
xyGroup(idx).right.legend = '';

%Gain-phase
idx=idx+1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=2;
xyGroup(idx).col=1;
xyGroup(idx).x='frequencyHz';
xyGroup(idx).xTicks=[0:30:90];
xyGroup(idx).xLim =[-10,100];
xyGroup(idx).xLabel='Frequency (Hz)';
xyGroup(idx).xData =[];
xyGroup(idx).title='C. Gain \& phase response';


xyGroup(idx).left.y='gain';
xyGroup(idx).left.scale=1;
xyGroup(idx).left.yTicks = [0:5:15];
xyGroup(idx).left.yLim= [min(xyGroup(idx).left.yTicks),...
                         max(xyGroup(idx).left.yTicks)];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Gain (%s)',['N/m']);
xyGroup(idx).left.lineColor = [0,0,0];
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.legend = '';

xyGroup(idx).right.y='phase';
xyGroup(idx).right.scale=scalePhase;
xyGroup(idx).right.yTicks = [0:10:30];
xyGroup(idx).right.yLim= [min(xyGroup(idx).right.yTicks),...
                         max(xyGroup(idx).right.yTicks)];
xyGroup(idx).right.yLim=xyGroup(idx).right.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).right.yLim);
xyGroup(idx).right.yLabel=sprintf('Phase (%s)',['$$^\circ$$']);
xyGroup(idx).right.lineColor = cs.magenta;
xyGroup(idx).right.fillColor = xyGroup(idx).right.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).right.legend = '';

%Storage loss
idx=idx+1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=2;
xyGroup(idx).col=2;
xyGroup(idx).x='frequencyHz';
xyGroup(idx).xTicks=[0:30:90];
xyGroup(idx).xLim =[-10,100];
xyGroup(idx).xLabel='Frequency (Hz)';
xyGroup(idx).xData =[];
xyGroup(idx).title='D. Storage \& loss response';

xyGroup(idx).left.y='storage';
xyGroup(idx).left.scale=1;
xyGroup(idx).left.yTicks = [0:5:15];
xyGroup(idx).left.yLim= [min(xyGroup(idx).left.yTicks),...
                         max(xyGroup(idx).left.yTicks)];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Storage (%s)',['N/m']);
xyGroup(idx).left.lineColor = cs.red;
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.legend = '';

xyGroup(idx).right.y='loss';
xyGroup(idx).right.scale=1;
xyGroup(idx).right.yTicks = [0:10:30];
xyGroup(idx).right.yLim= [min(xyGroup(idx).right.yTicks),...
                         max(xyGroup(idx).right.yTicks)];
xyGroup(idx).right.yLim=xyGroup(idx).right.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).right.yLim);
xyGroup(idx).right.yLabel=sprintf('Loss (%s)',['N/m']);
xyGroup(idx).right.lineColor = cs.blue;
xyGroup(idx).right.fillColor = xyGroup(idx).right.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).right.legend = '';





%%
% Plot the perturbation data
%%
figure(fig_sigProc);

for i=1:1:length(xyGroup)

  subplot('Position',...
    reshape(subPlotPanel(xyGroup(i).row,xyGroup(i).col,:),1,4));

  xField=xyGroup(i).x;
  yLField=xyGroup(i).left.y;
  yRField=xyGroup(i).right.y;
  isLeftRightPlot=(isempty(yLField)==0 & isempty(yRField)==0);



  if(isLeftRightPlot==1)
    lrOrder=[1,2];
    if(xyGroup(i).left.first==0)
      lrOrder=[2,1];
    end
  else
    lrOrder=1;
  end


  for j=1:1:length(lrOrder)
    k=lrOrder(j);
    switch k
      case 1
        if(isLeftRightPlot==1)
          yyaxis left;
        end

        plot(analysis(segId).segment.H2.(xField),...
         analysis(segId).segment.H2.(yLField).*xyGroup(i).left.scale,...
         '-','Color',[1,1,1],'LineWidth',2);
        hold on;

        plot(analysis(segId).segment.H2.(xField),...
         analysis(segId).segment.H2.(yLField).*xyGroup(i).left.scale,...
         '-','Color',xyGroup(i).left.lineColor,'LineWidth',1);
        hold on;
        ylabel(xyGroup(i).left.yLabel);          
        yticks(xyGroup(i).left.yTicks);
        ylim(xyGroup(i).left.yLim);

        xlabel('Time (s)');
        xticks(xyGroup(i).xTicks);
        xlabel(xyGroup(i).xLabel);          
        xlim(xyGroup(i).xLim);
      case 2
        yyaxis right;

        plot(analysis(segId).segment.H2.(xField),...
         analysis(segId).segment.H2.(yRField).*xyGroup(i).right.scale,...
         '-','Color',[1,1,1],'LineWidth',2);
        hold on;
        
        plot(analysis(segId).segment.H2.(xField),...
         analysis(segId).segment.H2.(yRField).*xyGroup(i).right.scale,...
         '-','Color',xyGroup(i).right.lineColor,'LineWidth',1);
        hold on;
        ylabel(xyGroup(i).right.yLabel);          
        yticks(xyGroup(i).right.yTicks);
        ylim(xyGroup(i).right.yLim);          
      otherwise
        assert(0);
    end

  
  end


  box off;

  title(xyGroup(i).title);

  if(isLeftRightPlot==1)
    ax=gca;
    ax.YAxis(1).Color=xyGroup(i).left.lineColor;
    ax.YAxis(2).Color=xyGroup(i).right.lineColor;
    if(xyGroup(i).left.first==0)
      set(ax,'SortMethod','depth');
    end
       
  else
    ax=gca;
    ax.YAxis(1).Color=xyGroup(i).left.lineColor;
  end

  here=1;
end
%%
% Write the data to file
%%



fig_sigProc=configPlotExporter(fig_sigProc, ...
                    subPlotSettings.pageWidthCm, ...
                    subPlotSettings.pageHeightCm);

fileName =    ['fig_signalProcessing'];
print('-dpdf', fullfile(projectFolders.output600A_plots, ...
                        outputFolder,[fileName,'.pdf']));    
saveas(fig_sigProc,fullfile(projectFolders.output600A_plots,...
                                 outputFolder,[fileName,'.fig']));
close(fig_sigProc);
