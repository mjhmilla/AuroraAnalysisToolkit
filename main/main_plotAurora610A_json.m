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

experimentsToProcess = {'20260312_610A_EDL_Passive_0'};
%{'20260305_impedance_elastic_610A'};

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
% 20260311_610A_EDL             - force-length
% 20260312_610A_EDL_Passive_0   - impedance
% 20260312_610A_EDL_Passive_1   - impedance
% 20260312_610A_EDL_Passive_2   - impedance
% 20260312_610A_EDL_Passive_3   - impedance
% 20260326_610A_EDL             - degradation
%
keyWordFilter.measurement.include = {};
keyWordFilter.measurement.exclude = {};
keyWordFilter.segment.include = {};
keyWordFilter.segment.exclude = {};
keyWordFilter.metaDataFileName.include = {};
keyWordFilter.metaDataFileName.exclude = {};

keyWordFilter.tags.include = {};
keyWordFilter.tags.exclude = {};

%
% Script settings
%
flags.scanData                               = 1;
flags.verifyDataIntegrityCompletness         = 0;
flags.plotOverview                           = 1;
flags.plotForceLengthRelations               = 0;
flags.processForceDegradation                = 0;
flags.plotImpedance                          = 1;

  activationTime = 0.2;
  deactivationTime=0.3;

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
  settingsPlotDegradation.activationTime    = activationTime;
  settingsPlotDegradation.deactivationTime  = deactivationTime;

  settingsPlotForceLength.isometricForceLengthTag = ...
    'isometric-active-passive-force-length';
  settingsPlotForceLength.savePlots         = 1;
  settingsPlotForceLength.saveFormat        = {'png'};  
  settingsPlotForceLength.readProtocolArray = 1;
  settingsPlotForceLength.activationTime    = activationTime;
  settingsPlotForceLength.deactivationTime  = deactivationTime;
  settingsPlotForceLength.addDegradationCompensationPlot =1;

  settingsPlotImpedance.impedanceTag = ...
    'impedance';
  settingsPlotImpedance.savePlots         = 1;
  settingsPlotImpedance.saveFormat        = {'png'};  
  settingsPlotImpedance.readProtocolArray = 1;
  settingsPlotImpedance.minCoherenceSquared           = (2/3);
  settingsPlotImpedance.minAcceptableBandwidthFraction= (2/3);

%
% Load the degradation model
%

settingsDegradationModel.jsonFilePath = ...
  fullfile(projectFolders.output610A_json,'degradation',...
           '20260326_610A_EDL_degradationModel.json');
settingsDegradationModel.index = 1;

jsonDegradationModels = ...
    fileread(settingsDegradationModel.jsonFilePath);
degradationModels = ...
    jsondecode(jsonDegradationModels);
settingsDegradationModel.model = ...
    degradationModels.models(settingsDegradationModel.index);



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
% Scan through the data
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
if(flags.processForceDegradation == 1)


  keyWordFilterUpd=keyWordFilter;
  keyWordFilterUpd.tags.include = ...
    {settingsPlotDegradation.degradationTag};

  if(length(experimentsToProcess)==1)
    if(strcmp(experimentsToProcess(1),'20260326_610A_EDL'))
        keyWordFilterUpd.measurement.exclude = {'03_degradation_02_Broken'};
        keyWordFilterUpd.metaDataFileName.exclude = ...
          {'sine_wave','plateau','temperature','10-','09-'};   
    end
  end

  verbose=1;  
  degradationModel = processExperimentalForceDegradation610A_json(...
                        experimentsToProcess,...
                        keyWordFilterUpd,...
                        settingsPlotDegradation, ...
                        projectFolders,...
                        verbose);
  
  jsonFolderName = fullfile(projectFolders.output610A_json,'degradation');
  for i=1:1:length(degradationModel)
    degradationModelJson = jsonencode(degradationModel(i));
    jsonFilePath = fullfile(jsonFolderName,...
                      [degradationModel(i).name,'_degradationModel.json']);
    fidJson = fopen(jsonFilePath,'w');
    fprintf(fidJson,degradationModelJson);
    fclose(fidJson);    
  end

  
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
                    settingsDegradationModel, ...
                    projectFolders,...
                    verbose);
end

%
% Impedance plots
%
if(flags.plotImpedance==1)
  keyWordFilterUpd=keyWordFilter;
  keyWordFilterUpd.tags.include = ...
    {settingsPlotImpedance.impedanceTag};
  keyWordFilterUpd.segment.include = {'Stochastic'};
    

  verbose = 1;

  success = plotExperimentalImpedanceOverview610A_json(...
                            experimentsToProcess,...
                            keyWordFilterUpd,...
                            settingsPlotImpedance,...
                            projectFolders,...
                            verbose);

end
