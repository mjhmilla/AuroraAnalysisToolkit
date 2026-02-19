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


% time-domain  
% frequency-domain
% experimentsToProcess = { ...
% '20260116_impedance_larb_spring',...
% '20260108_impedance_larb_spring',...
% '20251118_impedance_larb_1',...
% '20251118_impedance_larb_2',...
% '20251120_impedance_larb_3',...
% '20251121_impedance_larb_4',...
% '20251121_impedance_larb_5',...
% '20251128_impedance_larb_6',...
% '20251203_impedance_larb_7',...
% '20251114_degradation_larb_1',...
% '20251119_degradation_larb_2',...
% '20251121_degradation_larb_3',...
% '20251121_degradation_larb_4',...
% '20260109_impedance_temperature_pilot'}


experimentsToProcess = {'20251118_impedance_larb_1'};
skipToTrialWithKeyword = ['_active_100Lo_'];

trialTypeKeywords = {'spring','degradation','impedance'};
trialTypeName     = {'delay','degradation','impedance'};
specimenTypeName      = {'spring','fiber','fiber'};


settings.checkDataIntegrity         = 1;
settings.processData                = 1;
settings.coherenceSquaredThreshold  = 0.8;
settings.activationBathNumber       = 3;
settings.deactivationBathNumber     = 1;
settings.preactivationBathNumber    = 2;
settings.timeBathChangeMs           = 1500;
settings.isometricNoiseFilterCutoffFrequencyHz  = 30;
settings.forceNoiseThresholdmN                  = 0.025;
settings.optimalSarcomereLengthInUM             = 2.525;

settings.useManuallySetDaqDelay = 1;
settings.daqDelayModel          = 'frequency-domain'; 
settings.daqDelay               = 6.67e-4; %Only used when the delay is fixed
settings.daqFilterFrequencyHz   = mean([635,654]); 
% Avg of filter-of-best-fit to the spring data from the 
% 0.01 Lo perturbations in water

settings.phaseDelayTolerance    = 1e-5;
settings.phaseDelayMaxIteration = 50;

settings.normFittingBandwidth = [0.05,1];

switch(settings.daqDelayModel)
    case 'time-domain'
        settings.daqFilterFrequencyHz = nan;
    case 'frequency-domain'
        settings.daqDelay = nan;
    otherwise
        assert(0,['Error: delayModel must be either',...
                  ' frequency-domain or time-domain']);
end

lineColors = getPaulTolColourSchemes('bright');
%
%Kelvin-Voigt Model
%
modelKV.name        = 'Kelvin-Voigt';
modelKV.abbreviation= 'KV';
modelKV.color       = [0,0,0];
modelKV.lineType    = '--';

modelKV.parameters  = [1, 1,0.1,0,0];

modelKV.settings.applyParameterMap = nan;
modelKV.settings.parameterMap = [1,2;...
                                 1,3]; 
modelKV.settings.defaultParameters=modelKV.parameters;

%
%Maxwell--Kelvin-Voigt Model
% columns
% 1               2 3 4 5 
% branch number   a b c d
%
% -Elements on the same branch are in series
% -Elements on different branches are in parallel
% -The coefficients a b c d correspond to the 
%   impedance of the element in this form
%
%   zij = (a + b*js)/(c + d*js);
%
modelMKV.name       = 'Maxwell--Kelvin-Voigt';
modelMKV.abbreviation= 'MKV';
modelMKV.color      = [0,0,0];
modelMKV.lineType   = '-';

modelMKV.parameters    = [1, 0,  1,1,1;...
                          1, 1,0.1,0,0];

modelMKV.settings.applyParameterMap   = nan;
modelMKV.settings.parameterMap =[1,3;...
                                 1,4;...
                                 2,2;...
                                 2,3]; 
modelMKV.settings.defaultParameters=modelMKV.parameters;
%
% Populate the model series struct
%
modelSeries(2)=struct('model',[]);

modelSeries(1).model = modelKV;
modelSeries(2).model = modelMKV;

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

    runPipelineAnalyzeArbitraryWaveformFiberData600A_02_json(...
            experimentsToProcess{i}, ...
            skipToTrialWithKeyword,...
            specimenType,...
            trialType,...
            modelSeries,...
            settings,...
            projectFolders);
    pause(0.1);
end
