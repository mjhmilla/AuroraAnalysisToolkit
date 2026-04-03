clc;
close all;
clear all;

%To do
% 1. Degradation
%  a. Plot
%  b. Extract a degradation model
% 2. Update the force length plot to include (optionally) an
%    adjustment to account for degradation
% 3. Impedance plots, both for passive and active data

experimentsToProcess = {'20260326_610A_EDL'};

%
% 20260311_610A_EDL             - force-length
% 20260312_610A_EDL_Passive_0   - impedance
% 20260312_610A_EDL_Passive_1   - impedance
% 20260312_610A_EDL_Passive_2   - impedance
% 20260312_610A_EDL_Passive_3   - impedance
% 20260326_610A_EDL             - degradation
%
keyWordFilter.metaDataFileName.include = {};
keyWordFilter.metaDataFileName.exclude = {};
keyWordFilter.segment.include = {};
keyWordFilter.segment.exclude = {};
keyWordFilter.tags.include = {};
keyWordFilter.tags.exclude = {};

%
% Script settings
%
flags.scanData                               = 1;
flags.verifyDataIntegrityCompletness         = 0;
flags.plotOverview                           = 0;
flags.plotForceLengthRelations               = 0;
flags.plotForceDegradation                   = 1;

  
  settingsVerify.setSha256Sum   = 0;
  
  settingsPlotOverview.savePlots                  = 1;
  settingsPlotOverview.saveFormat                 = {'png'};
  settingsPlotOverview.breakPlotsAtSequences      = 1;
  settingsPlotOverview.breakPlotsAfterTrialCount  = 20;
  settingsPlotOverview.readProtocolArray          =  1;
  settingsPlotOverview.preStimulusPlotTime        = -0.1;
  settingsPlotOverview.postStimulusPlotTime       = 0.3;
  settingsPlotOverview.stimulusCommandScale       = 1;
  settingsPlotOverview.stimulusDataScale          = 0.125;
  settingsPlotOverview.stimulusVoltageDataScale   = (0.5);
  settingsPlotOverview.stimulusCurrentDataScale   = (0.25);  
  settingsPlotOverview.annotateMinMaxTrialForce   = 1;
  settingsPlotOverview.annotateMinMaxSegmentForce = 1;

  settingsPlotDegradation.degradationTag = ...
    'degradation';
  settingsPlotDegradation.savePlots         = 1;
  settingsPlotDegradation.saveFormat        = {'png'};  
  settingsPlotDegradation.readProtocolArray = 1;
  settingsPlotDegradation.activationTime    = 0.2;
  settingsPlotDegradation.deactivationTime  = 0.3;

  settingsPlotForceLength.isometricForceLengthTag = ...
    'isometric-active-passive-force-length';
  settingsPlotForceLength.savePlots         = 1;
  settingsPlotForceLength.saveFormat        = {'png'};  
  settingsPlotForceLength.readProtocolArray = 1;
  settingsPlotForceLength.activationTime    = 0.2;
  settingsPlotForceLength.deactivationTime  = 0.3;

  

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
                settingsVerify,...
                projectFolders);
  end
end


%
% Basic Plots
%


if(flags.plotOverview==1)
  keyWordFilterUpd=keyWordFilter;
  if(length(experimentsToProcess)==1)
    if(strcmp(experimentsToProcess(1),'20260326_610A_EDL'))
        keyWordFilterUpd.metaDataFileName.exclude = {'sine_wave'};
        keyWordFilterUpd.segment.include = ...
          {'Stimulus-Twitch',...
           'Stimulus-Tetanus',...
           'Sine Wave-Stochastic',...
           'Step-Stochastic'};      
    end
  end

  verbose=1;
  success = plotExperimentalDataOverview610A_json(...
                    experimentsToProcess,...
                    keyWordFilterUpd,...
                    settingsPlotOverview, ...
                    projectFolders,...
                    verbose);  
end

%
% Degradation plots
%
if(flags.plotForceDegradation == 1)


  keyWordFilterUpd=keyWordFilter;
  keyWordFilterUpd.tags.include = ...
    {settingsPlotDegradation.degradationTag};

  if(length(experimentsToProcess)==1)
    if(strcmp(experimentsToProcess(1),'20260326_610A_EDL'))
        keyWordFilter.metaDataFileName.exclude = ...
          {'sine_wave','plateau','temperature','10-','09-'};   
    end
  end

  verbose=1;  
  success = plotExperimentalForceDegradation610A_json(...
                    experimentsToProcess,...
                    keyWordFilterUpd,...
                    settingsPlotDegradation, ...
                    projectFolders,...
                    verbose);
end

%
% Force-length relations
%
if(flags.plotForceLengthRelations == 1)
  keyWordFilterUpd=keyWordFilter;
  keyWordFilterUpd.tags.include = ...
    {settingsPlotForceLength.isometricForceLengthTag};

  verbose=1;  
  success = plotExperimentalForceLengthRelations610A_json(...
                    experimentsToProcess,...
                    keyWordFilterUpd,...
                    settingsPlotForceLength, ...
                    projectFolders,...
                    verbose);
end
