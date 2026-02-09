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

settings.checkDataIntegrity = 1;
settings.processData        = 1;
settings.coherenceSquaredThreshold = 0.8;
settings.activationBathNumber   = 3;
settings.deactivationBathNumber = 1;
settings.preactivationBathNumber = 2;
settings.timeBathChangeMs = 1500;
settings.isometricNoiseFilterCutoffFrequencyHz = 30;
settings.forceNoiseThreshold = 0.025;
settings.optimalSarcomereLengthInUM = 2.525;

settings.useManuallySetDelay=0;
settings.delayModel = 'frequency-domain'; 
settings.delay      = 6.67e-4; %Only used when the delay is fixed
settings.delayFilterFrequencyHz = 5.070417203589778e+02;

switch(settings.delayModel)
    case 'time-domain'
        settings.delayFilterFrequencyHz = nan;
    case 'frequency-domain'
        settings.delay = nan;
    otherwise
        assert(0,'Error: delayModel must be either frequency-domain or time-domain');
end

% time-domain  
% frequency-domain

% experimentsToProcess = ...
%   {'20260116_impedance_larb_spring',...
%    '20260108_impedance_larb_spring',...
%    '20251118_impedance_larb_1',...
%    '20251118_impedance_larb_2',...
%    '20251120_impedance_larb_3',...
%    '20251121_impedance_larb_4',...
%    '20251121_impedance_larb_5',...
%    '20251128_impedance_larb_6',...
%    '20251203_impedance_larb_7',...
%    '20251114_degradation_larb_1',...
%    '20251119_degradation_larb_2',...
%    '20251121_degradation_larb_3',...
%    '20251121_degradation_larb_4',...
%    '20260109_impedance_temperature_pilot'};



experimentsToProcess = {'20260116_impedance_larb_spring'};

trialTypeKeywords = {'spring','degradation','impedance'};
trialTypeName     = {'delay','degradation','impedance'};
specimenTypeName      = {'spring','fiber','fiber'};

for i=1:1:length(experimentsToProcess)
    fprintf('\n\n%s\n\n',experimentsToProcess{i});
    trialType='';
    specimenType='';
    j=1;
    while isempty(trialType) && j <= length(trialTypeKeywords)
        if(contains(experimentsToProcess{i},trialTypeKeywords{j}))
            trialType = trialTypeName{j};
            specimenType=specimenTypeName{j};
        end
        j=j+1;
    end

    runPipelineAnalyzeArbitraryWaveformFiberData600A_01_json(...
            experimentsToProcess{i},specimenType,trialType,...
            settings,projectFolders);
    pause(0.1);
end
