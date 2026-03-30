clc;
close all;
clear all;

experimentsToProcess = {'20260326_610A_EDL'};
% 20260311_610A_EDL
% 20261112_610A_EDL_Passive_0
% 20261112_610A_EDL_Passive_1
% 20261112_610A_EDL_Passive_2
% 20261112_610A_EDL_Passive_3
keyWordFilter.include = {};
keyWordFilter.exclude = {'sine_wave'};


%
% Script settings
%
flags.scanData                               = 0;

flags.verifyDataIntegrityCompletness         = 1;
  settingsDataCheck.setSha256Sum   = 0;
  

flags.plotOverview            = 1;

  overviewPlotSettings.savePlots            = 1;
  overviewPlotSettings.readProtocolArray    =  1;
  overviewPlotSettings.preStimulusPlotTime  = -0.1;
  overviewPlotSettings.postStimulusPlotTime = 0.3;
  overviewPlotSettings.stimulusCommandScale = 2.0;
  overviewPlotSettings.stimulusDataScale    = 0.25;  

flags.plotForceLengthRelations= 0;
  
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
% Scan through the dataa
%
if(flags.scanData==1)
  for idxExp = 1:1:length(experimentsToProcess) 
    success = scanExperiment610A(experimentsToProcess{idxExp},...
                                 keyWordFilter,...
                                 projectFolders);   
  end
end
%
% Verify data integrity and completness
%
if(flags.verifyDataIntegrityCompletness==1)

  for idxExp = 1:1:length(experimentsToProcess) 
    setOfVerifiedTrials=...
        verifyExperimentDataIntegrityCompletness610A(...
                experimentsToProcess{idxExp},...
                settingsDataCheck,...
                projectFolders);
  end
end


%
% Basic Plots
%
assert(0,'You are here');


if(flags.plotOverview==1)

  success = plotExperimentalDataOverview610A_json(...
                    experimentsToProcess,...
                    keyWordFilter,...
                    overviewPlotSettings, ...
                    projectFolders);  
end

%
% Force-length relations
%
if(flags.plotForceLengthRelations == 1)
  success = plotExperimentalForceLengthRelations610A_json(...
                    experimentsToProcess,...
                    keyWordFilter,...
                    forceLengthPlotSettings, ...
                    projectFolders);
end
