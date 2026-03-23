clc;
close all;
clear all;

experimentsToProcess = {'20260311_610A_EDL'};
% 20260311_610A_EDL
% 20261112_610A_EDL_Passive_0
% 20261112_610A_EDL_Passive_1
% 20261112_610A_EDL_Passive_2
% 20261112_610A_EDL_Passive_3
fileKeyWord = [];


%
% Script settings
%

flags.plotOverview            = 0;

  overviewPlotSettings.savePlots            = 1;
  overviewPlotSettings.readProtocolArray    =  1;
  overviewPlotSettings.preStimulusPlotTime  = -0.1;
  overviewPlotSettings.postStimulusPlotTime = 0.3;
  overviewPlotSettings.stimulusCommandScale = 2.0;
  overviewPlotSettings.stimulusDataScale    = 0.25;  

flags.plotForceLengthRelations= 1;
  
  forceLengthPlotSettings.savePlots         = 1;
  forceLengthPlotSettings.readProtocolArray = 1;
  forceLengthPlotSettings.activationTime    = 0.2;
  forceLengthPlotSettings.deactivationTime  = 0.3;

%
% Setup project folders
% 
rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora610A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);




%
% Make the output plot folders
%
for i=1:1:length(experimentsToProcess)
  outputPlotDir = fullfile(projectFolders.output610A_plots,...
                          experimentsToProcess{i});
  if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
  end
end

%
% Basic Plots
%

if(flags.plotOverview==1)

  success = plotExperimentalDataOverview610A_json(...
                    experimentsToProcess,...
                    fileKeyWord,...
                    overviewPlotSettings, ...
                    projectFolders);  
end

%
% Force-length relations
%
if(flags.plotForceLengthRelations == 1)
  success = plotExperimentalForceLengthRelations610A_json(...
                    experimentsToProcess,...
                    fileKeyWord,...
                    forceLengthPlotSettings, ...
                    projectFolders);
end
