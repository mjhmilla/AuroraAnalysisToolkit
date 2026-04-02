clc;
close all;
clear all;

experimentsToProcess = {'20260311_610A_EDL'};
% 20260311_610A_EDL
% 20260312_610A_EDL_Passive_0
% 20260312_610A_EDL_Passive_1
% 20260312_610A_EDL_Passive_2
% 20260312_610A_EDL_Passive_3



keyWordFilter.metaDataFileName.include = {};
keyWordFilter.metaDataFileName.exclude = {};
keyWordFilter.segment.include = {};
keyWordFilter.segment.exclude = {};
keyWordFilter.tags.include = {};
keyWordFilter.tags.exclude = {};

if(length(experimentsToProcess)==1)
  switch experimentsToProcess{1}
    case '20260311_610A_EDL'
      keyWordFilter.tags.include = ...
          {'isometric-active-passive-force-length'};
    case '20260326_610A_EDL'
      keyWordFilter.metaDataFileName.exclude = {'sine_wave'};
      keyWordFilter.segment.include = ...
        {'Stimulus-Twitch',...
         'Stimulus-Tetanus',...
         'Sine Wave-Stochastic',...
         'Step-Stochastic'};
  end
end

%
% Script settings
%
flags.scanData                               = 1;
flags.verifyDataIntegrityCompletness         = 0;
  settingsDataCheck.setSha256Sum   = 0;
  

flags.plotOverview                                = 0;

  overviewPlotSettings.savePlots                  = 1;
  overviewPlotSettings.saveFormat                 = {'png'};
  overviewPlotSettings.breakPlotsAtSequences      = 1;
  overviewPlotSettings.breakPlotsAfterTrialCount  = 20;
  overviewPlotSettings.readProtocolArray          =  1;
  overviewPlotSettings.preStimulusPlotTime        = -0.1;
  overviewPlotSettings.postStimulusPlotTime       = 0.3;
  overviewPlotSettings.stimulusCommandScale       = 1;
  overviewPlotSettings.stimulusDataScale          = 0.125;
  overviewPlotSettings.stimulusVoltageDataScale   = (0.5);
  overviewPlotSettings.stimulusCurrentDataScale   = (0.25);
  
  overviewPlotSettings.annotateMinMaxTrialForce   = 1;
  overviewPlotSettings.annotateMinMaxSegmentForce = 1;

flags.plotForceLengthRelations              = 1;
  forceLengthPlotSettings.isometricForceLengthTag = ...
    'isometric-active-passive-force-length';
  forceLengthPlotSettings.savePlots         = 1;
  forceLengthPlotSettings.saveFormat        = {'png'};  
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
    verbose=1;
    scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                     keyWordFilter,...
                                     projectFolders,...
                                     verbose);   
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
  keyWordFilterUpd=keyWordFilter;
  keyWordFilterUpd.tags.include = ...
    {forceLengthPlotSettings.isometricForceLengthTag};

  success = plotExperimentalForceLengthRelations610A_json(...
                    experimentsToProcess,...
                    keyWordFilterUpd,...
                    forceLengthPlotSettings, ...
                    projectFolders);
end
