clc;
close all;
clear all;

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora610A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);

experimentsToProcess = {fullfile(projectFolders.data610A,'20260311_610A_EDL')};

settings.readProtocolArray    = 1;
settings.postTwitchPlotTime   = 0.3;
settings.postTetanusPlotTime  = 0.3;


figureStruct = plotExperimentalDataOverview610A_json(...
            experimentsToProcess,...
            settings, ...
            projectFolders);  

outputPlotDir = fullfile(projectFolders.output610A_plots,...
                        '20260311_610A_EDL');
if(~exist(outputPlotDir,'dir'))
  mkdir(outputPlotDir);
end

for i=1:1:length(figureStruct)
    figureStruct(i).h=configPlotExporter(...
                          figureStruct(i).h, ...
                          figureStruct(i).pageWidth,...
                          figureStruct(i).pageHeight);

  print('-dpdf', fullfile(outputPlotDir,[figureStruct(i).name,'.pdf']));  
  saveas(figureStruct(i).h,...
          fullfile(outputPlotDir,[figureStruct(i).name,'.fig']));
end