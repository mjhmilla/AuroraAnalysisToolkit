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

experimentFolder = '20251118_impedance_larb_1';
trialFile      = 'analysis_ImpedanceLengthArb_larb_08_active_100Lo_20251118.json';

outputFolder = 'system_identification';

settings.indexTimeSeries=[];

timeUnit = 'ms';
ms2s = 0.001;

%%
% Perturbation plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*3;
plotHorizMarginCm  = 2;
plotVertMarginCm   = 2.5;
baseFontSize       = 10;

[subPlotPanelPer, subPlotPerSettings, pageWidthPer,pageHeightPer]= ...
  plotConfigAdvanced(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

subPlotPanelPer(1,2,:)=subPlotPanelPer(2,2,:);
subPlotPanelPer(1,2,4)=subPlotPerSettings.plotHeight(1,1) ...
                      +subPlotPerSettings.plotHeight(2,1) ...
                      +subPlotPerSettings.plotVerticalMargin;

subPlotPanelPer(2,2,:)=subPlotPanelPer(2,2,:).*nan;

fig_perturbation=figure;
subplot('Position',reshape(subPlotPanelPer(1,1,:),1,4));
subplot('Position',reshape(subPlotPanelPer(2,1,:),1,4));
subplot('Position',reshape(subPlotPanelPer(1,2,:),1,4));

%%
% Plot the perturbation data
%%
jsonFile = fullfile(projectFolders.output600A_json,...
                    experimentFolder,trialFile);
jsonStr = fileread(jsonFile);
jsonData= jsondecode(jsonStr);

%
% Plot the time series length data
%

segList=[1,2];
subPlotLabel={'A.','B.'};

for idxSegList=1:1:length(segList)
  segId=segList(idxSegList);

  figure(fig_perturbation);
  subplot('Position',reshape(subPlotPanelPer(idxSegList,1,:),1,4));

    idxP=settings.indexTimeSeries;
    if(isempty(idxP))
      idxP = [1:1:length(jsonData(segId).segment.H2.time)];
    end
    timeDataLimit=[min(jsonData(segId).segment.H2.time(idxP)),...
                   max(jsonData(segId).segment.H2.time(idxP))];
    xDataLimit=[min(jsonData(segId).segment.H2.x(idxP)),...
                max(jsonData(segId).segment.H2.x(idxP))];

    plot(jsonData(segId).segment.H2.time(idxP),...
         jsonData(segId).segment.H2.x(idxP),...
         '-','Color',[0,0,0]);
    hold on;
    xlabel('Time (s)');
    ylabel(sprintf('Length (%s)', jsonData(segId).segment.unit.length));
  
    n=max(ceil(abs(log10(jsonData(segId).segment.H2.amplitudeLo))),1);

    titleFmt = ['%s. %i Hz - %1.',num2str(n),'f %s pp'];

    titleText=sprintf(titleFmt,...
                      subPlotLabel{idxSegList},...
                      jsonData(segId).segment.H2.bandwidthHz(2),...
                      jsonData(segId).segment.H2.amplitudeLo*2,...
                      '$$\ell_o$$');    
    title(titleText);


    yt = [[-1,1].*jsonData(segId).segment.H2.amplitudeLo,...
          [-1,1].*jsonData(segId).segment.H2.amplitudeLo.*0.5,...
          0];
    yt=sort(yt);
    
    nt =[n,(n+1),1,(n+1),n];

    yticks(yt);
    ylStr = cell(length(yt),1);
    
    for i=1:1:length(ylStr)      
      fmt = ['%1.',num2str(nt(i)),'f'];      
      ylStr(i) = {sprintf(fmt,yt(i))};
    end
    yticklabels(ylStr);

    yl = [-1.1,1.1].*jsonData(segId).segment.H2.amplitudeLo;    
    ylim(yl);
    xlim(timeDataLimit);
    box off;    

    %
    % Plot the perturbation power spectrum
    %
%     dt = jsonData(segId).segment.H2.time(2)...
%         -jsonData(segId).segment.H2.time(1);
%     
%     fs=1/dt;
%     s= length(jsonData(segId).segment.H2.time);
%     sh=floor(s/2);
%     xfd = fft(jsonData(segId).segment.H2.x);
%     p2=abs(xfd)./s;
%     p1=p2(1:sh+1);
%     p1(2:end-1)=2*p1(2:end-1);
%   https://www.mathworks.com/matlabcentral/answers/491418-how-can-i-plot-a-power-spectrum-for-my-signal
end





