clc;
clear all;
close all;

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora610A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);

outputFolder = '20250710_610A_EDL';
folder610A = fullfile('20250710_610A_EDL','preparation');
file610A   = 'FLR.ddf';

timeBetweenStimulations  = 10;
maxTime = 295;

%%
% Measurements
%%
fullFilePath610A = fullfile(projectFolders.data610A,...
                            folder610A,...
                            file610A);
flag_readProtocolArray=1;
ddfData610A = readAuroraData610A(fullFilePath610A,flag_readProtocolArray);
idxMax = maxTime*ddfData610A.Sample_Frequency_Hz;

%
%Extract the stimulation intervals
%
stimIdx = find(ddfData610A.data.Stim.Values > 0.5);
diffStimIdx = find(diff(stimIdx)>(ddfData610A.Sample_Frequency_Hz*timeBetweenStimulations*0.9));

stimInt = [];

i1 = stimIdx(1);
for i=1:1:length(diffStimIdx)
  i0 = i1;
  i1 = stimIdx(diffStimIdx(i));
  if(i1 < idxMax)
    stimInt = [stimInt; i0,i1];
  end
  i1 = stimIdx(diffStimIdx(i)+1);
end

i0=i1;
i1=stimIdx(end);
if(i1 < idxMax)
  stimInt = [stimInt; i0,i1];
end


%
% Extract the force length information
%

fPassive  = zeros(size(stimInt,1),1);
fTotal    = zeros(size(stimInt,1),1);
fActive   = zeros(size(stimInt,1),1);
mLength   = zeros(size(stimInt,1),1);

for i=1:1:size(stimInt,1)
  i0 = stimInt(i,1);
  i1 = stimInt(i,2);

  ipe = i0-round(ddfData610A.Sample_Frequency_Hz*0.01);
  fPassive(i) = ddfData610A.data.AI1.Values(ipe);
  fTotal(i)   = max(ddfData610A.data.AI1.Values(i0:i1));
  fActive(i)  = fTotal(i)-fPassive(i);
  mLength(i)  = mean(ddfData610A.data.AI0.Values(i0:i1));
end

%
% Line of best fit to the descending limb
%
n = length(fActive);
i0= 3;%round(n/2);
i1 = n;
b = fActive(i0:i1);
A = [ones(size(mLength(i0:i1))), mLength(i0:i1)];
x = (A'*A)\(A'*b);
lZero = -x(1)/x(2);
lMax  = mLength(2);
lOpt = (lZero-lMax)/0.6;


figH = figure;

numberOfHorizontalPlotColumnsGeneric    = 1;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*10;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*10;
plotHorizMarginCm                       = 2;
plotVertMarginCm                        = 2.5;
baseFontSize                            = 12;

[subPlotPanelIndividual, pageWidthIndividual,pageHeightIndividual]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

subplot('Position',reshape(subPlotPanelIndividual(1,1,:),1,4));
  yyaxis left;  
  plot(ddfData610A.data.Sample.Values(1:idxMax).*(1/ddfData610A.Sample_Frequency_Hz),...
       ddfData610A.data.AI0.Values(1:idxMax),'DisplayName','Length');
  hold on;
  ylabel('Length (mm)');

  yyaxis right;
  plot(ddfData610A.data.Sample.Values(1:idxMax).*(1/ddfData610A.Sample_Frequency_Hz),...
       ddfData610A.data.AI1.Values(1:idxMax),'DisplayName','Force');
  hold on;
  ylabel('Force (N)');

  plot(ddfData610A.data.Sample.Values(1:idxMax).*(1/ddfData610A.Sample_Frequency_Hz),...
       ddfData610A.data.Stim.Values(1:idxMax),'-','Color',[1,1,1].*0.1,...
       'DisplayName','Stim.');
  hold on;
  box off;

  legend('Location','northwest');
  xlabel('Time (s)');
  title('FLR Time-series data');

subplot('Position',reshape(subPlotPanelIndividual(2,1,:),1,4));

  plot(mLength,fTotal,'.','Color',[1,1,1].*0.5,'DisplayName','Total',...
       'MarkerSize',5);
  hold on;
  plot(mLength,fPassive,'o','Color',[0,0,1],'DisplayName','Passive',...
      'MarkerSize',5);
  hold on;
  plot(mLength,fActive,'s','Color',[1,0,0],'DisplayName','Active',...
       'MarkerSize',5);
  hold on;

  plot(A(:,2),A*x,'-k','DisplayName','Lsq');
  hold on;
  plot(lZero,0,'ok','DisplayName','Lsq: f=0',...
     'MarkerSize',4,'MarkerFaceColor',[0,0,0]);

  text(2,0,sprintf('%s=%1.2f mm\n%s=%1.2f mm\n%s=%1.2f mm\n%s',...
                   '$$\ell_{zero}^M$$',lZero,...
                   '$$\ell_{max}^M$$',lMax,...
                   '$$\ell_{o}^M$$',lOpt,...
                   '$$\ell_{o}^M = (\ell_{zero}^M-\ell_{max}^M)/0.6$$'),...
       'VerticalAlignment','bottom');

  legend('Location','NorthWest');
  box off;


  xlabel('Length (mm)');
  title('Force-length relation');
  
  figH=...
    configPlotExporter( figH, ...
                        pageWidthIndividual, ...
                        pageHeightIndividual);

  fileName =    ['fig_flr'];

  outputPlotDir = fullfile(projectFolders.output610A_plots,outputFolder);
  if(~exist(outputPlotDir,'dir'))
      mkdir(outputPlotDir);
  end  

  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
  
  saveas(figH,...
         fullfile(outputPlotDir,[fileName,'.fig']));

  saveas(figH,...
         fullfile(outputPlotDir,[fileName,'.pdf']));  
  