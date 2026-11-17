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

plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*4.5;
plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*4.5;
plotHorizPageMarginCm=2.5;
plotHorizMarginCm  = 2.5;
plotVertMarginCm   = 2;
baseFontSize       = 10;

[subPlotPanel, subPlotSettings]= ...
  plotConfigAdvanced(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizPageMarginCm,...
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
                'title',[],'xLine',[],'xLineAnnotation',[],'xAnnotationHAlign',[],...
                'useC2BW',0);

for i=1:1:nPlots
  xyGroup(i)=struct('idS',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[],'xLine',[],'xLineAnnotation',[],'xAnnotationHAlign',[],...
                'useC2BW',0);

  xyGroup(i).left  = ...
    struct('y','','first',0,'yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'legend','',...
           'scale',1,'addBoxWhisker',0,'xBoxWhisker',0,'xBoxWidth',0,...
           'addZeroLine',0);

  xyGroup(i).right = ...
    struct('y','','yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'legend','',...
           'scale',1,'addBoxWhisker',0,'xBoxWhisker',0,'xBoxWidth',0,...
           'addZeroLine',0);    
end

scaleLength=1000;
scaleForce =1000;
scalePhase=(180/pi);
lengthUnit='\mathrm{mm}';
forceUnit='\mathrm{mN}';
scaledLengthUnit='\mu \mathrm{m}';
scaledForceUnit='\mu \mathrm{N}';


xMargin=5;
xTicksFreq=[0:30:90];
xLimFreq=[(min(xTicksFreq)-xMargin),(max(xTicksFreq)+xMargin)];

xLines = analysis(segId).segment.H2.bandwidthHzC2;
xLinesAnnotation=[{sprintf('%1.1fHz',xLines(1))},...
                  {sprintf('%1.1fHz',xLines(2))}];

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
xyGroup(idx).useC2BW = 0;

xyGroup(idx).left.first=0;
xyGroup(idx).left.y='x';
xyGroup(idx).left.scale=scaleLength;
xyGroup(idx).left.yTicks = round([-10,-1,1,10],1);
xyGroup(idx).left.yLim= [-10,10];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Length (%s)',['$$',scaledLengthUnit,'$$']);
xyGroup(idx).left.lineColor = [0,0,0];
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;



xyGroup(idx).right.y='y';
xyGroup(idx).right.scale=scaleForce;
xyGroup(idx).right.yTicks = round([-10,-1,1,10],1);
xyGroup(idx).right.yLim= [-10,10];
xyGroup(idx).right.yLim=xyGroup(idx).right.yLim ...
                       + [-0.01,0.01].*diff(xyGroup(idx).right.yLim);
xyGroup(idx).right.yLabel=sprintf('Force (%s)',['$$',scaledForceUnit,'$$']);
xyGroup(idx).right.lineColor = cs.teal;
xyGroup(idx).right.fillColor = xyGroup(idx).right.lineColor.*0.5+[1,1,1].*0.5;


%Coherence-sq
idx=idx+1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=1;
xyGroup(idx).col=2;
xyGroup(idx).x='frequencyHz';
xyGroup(idx).xTicks=xTicksFreq;
xyGroup(idx).xLim =xLimFreq;
xyGroup(idx).xLabel='Frequency (Hz)';
xyGroup(idx).xData =[];
xyGroup(idx).title='B. Linearity assessment';
xyGroup(idx).xLine=xLines;
xyGroup(idx).xLineAnnotation=xLinesAnnotation;
xyGroup(idx).xAnnotationHAlign =[{'left','right'}];
xyGroup(idx).useC2BW = 0;

xyGroup(idx).left.first=1;
xyGroup(idx).left.y='coherenceSq';
xyGroup(idx).left.scale=1;
xyGroup(idx).left.yTicks = ...
  round([0,analysis(segId).segment.H2.coherenceSquaredThreshold,1],2);
xyGroup(idx).left.yLim= [min(xyGroup(idx).left.yTicks),...
                         max(xyGroup(idx).left.yTicks)];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.01,0.1].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Coherence Squared %s (%s)','$$\phi^2$$','$$\mathrm{m}^2 \mathrm{N}^2 / (\mathrm{m}^2 \mathrm{N}^2)$$');
xyGroup(idx).left.lineColor = [0,0,0];
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.addZeroLine=1;

xyGroup(idx).right.y      = [];
xyGroup(idx).right.scale  = [];
xyGroup(idx).right.yTicks = [];
xyGroup(idx).right.yLim   = [];
xyGroup(idx).right.yLim   = [];
xyGroup(idx).right.yLabel = '';
xyGroup(idx).right.lineColor = [];
xyGroup(idx).right.fillColor = [];




%Gain-phase
idx=idx+1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=2;
xyGroup(idx).col=1;
xyGroup(idx).x='frequencyHz';
xyGroup(idx).xTicks=xTicksFreq;
xyGroup(idx).xLim =xLimFreq;
xyGroup(idx).xLabel='Frequency (Hz)';
xyGroup(idx).xData =[];
xyGroup(idx).title='C. Gain \& phase response';
xyGroup(idx).xLine=xLines;
xyGroup(idx).xLineAnnotation=xLinesAnnotation;
xyGroup(idx).xAnnotationHAlign =[{'left','right'}];
xyGroup(idx).useC2BW = 1;

xyGroup(idx).left.first=1;
xyGroup(idx).left.y='gain';
xyGroup(idx).left.scale=1;
xyGroup(idx).left.yTicks = [0:5:15];
xyGroup(idx).left.yLim= [min(xyGroup(idx).left.yTicks),...
                         max(xyGroup(idx).left.yTicks)];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.1,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Gain (%s)',['N/m']);
xyGroup(idx).left.lineColor = [0,0,0];
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.addZeroLine=1;


xyGroup(idx).right.y='phase';
xyGroup(idx).right.scale=scalePhase;
xyGroup(idx).right.yTicks = [0:15:45];
xyGroup(idx).right.yLim= [min(xyGroup(idx).right.yTicks),...
                         max(xyGroup(idx).right.yTicks)];
xyGroup(idx).right.yLim=xyGroup(idx).right.yLim ...
                       + [-0.1,0.01].*diff(xyGroup(idx).right.yLim);
xyGroup(idx).right.yLabel=sprintf('Phase (%s)',['$$^\circ$$']);
xyGroup(idx).right.lineColor = cs.magenta;
xyGroup(idx).right.fillColor = xyGroup(idx).right.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).right.addZeroLine=1;


%Storage loss
idx=idx+1;
xyGroup(idx).idS=segId;
xyGroup(idx).row=2;
xyGroup(idx).col=2;
xyGroup(idx).x='frequencyHz';
xyGroup(idx).xTicks=xTicksFreq;
xyGroup(idx).xLim =xLimFreq;
xyGroup(idx).xLabel='Frequency (Hz)';
xyGroup(idx).xData =[];
xyGroup(idx).title='D. Storage \& loss response';
xyGroup(idx).xLine=xLines;
xyGroup(idx).xLineAnnotation=xLinesAnnotation;
xyGroup(idx).xAnnotationHAlign =[{'left','right'}];
xyGroup(idx).useC2BW = 1;

xyGroup(idx).left.first=1;
xyGroup(idx).left.y='storage';
xyGroup(idx).left.scale=1;
xyGroup(idx).left.yTicks = [0:5:15];
xyGroup(idx).left.yLim= [min(xyGroup(idx).left.yTicks),...
                         max(xyGroup(idx).left.yTicks)];
xyGroup(idx).left.yLim=xyGroup(idx).left.yLim ...
                       + [-0.1,0.01].*diff(xyGroup(idx).left.yLim);
xyGroup(idx).left.yLabel=sprintf('Storage (%s)',['N/m']);
xyGroup(idx).left.lineColor = cs.red;
xyGroup(idx).left.fillColor = xyGroup(idx).left.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).left.legend = '';
xyGroup(idx).left.addBoxWhisker=1;
xyGroup(idx).left.xBoxWhisker=min(xTicksFreq)-0.5*xMargin;
xyGroup(idx).left.xBoxWidth=xMargin*(3/4);
xyGroup(idx).left.addZeroLine=1;


xyGroup(idx).right.y='loss';
xyGroup(idx).right.scale=1;
xyGroup(idx).right.yTicks = [0:5:15];
xyGroup(idx).right.yLim= [min(xyGroup(idx).right.yTicks),...
                         max(xyGroup(idx).right.yTicks)];
xyGroup(idx).right.yLim=xyGroup(idx).right.yLim ...
                       + [-0.1,0.01].*diff(xyGroup(idx).right.yLim);
xyGroup(idx).right.yLabel=sprintf('Loss (%s)',['N/m']);
xyGroup(idx).right.lineColor = cs.blue;
xyGroup(idx).right.fillColor = xyGroup(idx).right.lineColor.*0.5+[1,1,1].*0.5;
xyGroup(idx).right.legend = '';
xyGroup(idx).right.addBoxWhisker=1;
xyGroup(idx).right.xBoxWhisker=max(xTicksFreq)+0.5*xMargin;
xyGroup(idx).right.xBoxWidth=xMargin*(3/4);
xyGroup(idx).right.addZeroLine=1;




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
    side='';
    switch k
      case 1
        if(isLeftRightPlot==1)
          yyaxis left;
        end
        side='left';

      case 2
        yyaxis right;
        side='right';
        
      otherwise
        assert(0);
    end

    yField = xyGroup(i).(side).y;    
    
    if(xyGroup(i).useC2BW == 1)
      idxC2BW = analysis(segId).segment.H2.idxBWC2;
      dataX = analysis(segId).segment.H2.(xField)(idxC2BW);
      dataY = analysis(segId).segment.H2.(yField)(idxC2BW).*xyGroup(i).(side).scale;
    else
      dataX = analysis(segId).segment.H2.(xField);
      dataY = analysis(segId).segment.H2.(yField).*xyGroup(i).(side).scale;
    end
    plot(dataX,dataY,...
     '-','Color',[1,1,1],'LineWidth',2);
    hold on;

    plot(dataX,dataY,...
     '-','Color',xyGroup(i).(side).lineColor,'LineWidth',0.75);
    hold on;

    if(xyGroup(i).(side).addBoxWhisker==1)

      ss=getSummaryStatistics(dataY);

      plotBoxWhiskerData(xyGroup(i).(side).xBoxWhisker, ...
                         ss,...
                         xyGroup(i).(side).xBoxWidth,...
                         xyGroup(i).(side).lineColor,...
                         xyGroup(i).(side).fillColor);
      hold on;
    end

    if(xyGroup(i).(side).addZeroLine==1)
      plot(xyGroup(i).xLim,[0,0],...
           '-','Color',[1,1,1].*0.5);
      hold on;      
    end

    ylabel(xyGroup(i).(side).yLabel);          
    yticks(xyGroup(i).(side).yTicks);
    ylim(xyGroup(i).(side).yLim);


  end

  if(~isempty(xyGroup(i).xLine))
    for j=1:1:length(xyGroup(i).xLine)
      plot([1,1].*xyGroup(i).xLine(j),...
           xyGroup(i).(side).yLim,...
           '-','Color',[1,1,1].*0.5);
      hold on;
      text(xyGroup(i).xLine(j),xyGroup(i).(side).yLim(1),...
           xyGroup(i).xLineAnnotation{j},...
           'HorizontalAlignment',xyGroup(i).xAnnotationHAlign{j},...
           'VerticalAlignment','bottom',...
           'FontSize',6);
      hold on;

    end
  end


  xticks(xyGroup(i).xTicks);
  xlabel(xyGroup(i).xLabel);          
  xlim(xyGroup(i).xLim);  

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
