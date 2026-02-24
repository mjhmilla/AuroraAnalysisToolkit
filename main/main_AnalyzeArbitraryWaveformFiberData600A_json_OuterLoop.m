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

disp('Note:')
disp(['1. The phase delay of the specimen is reported using an',...
       ' elastic rod model and the average specimen stiffness']);
disp('2. The phase delay is only used to compensate springs');
disp('3. The phase delay for muscle fibers is not used for two reasons');
disp(['3a. Between 0-90 Hz the phase delay causes at most 1 degree', ...
     ' of phase error']);
disp(['3b. The phase delay for the fibers varies with frequency, and ',...
      'need to be evaluated using a model. I have derived this model',...
      'for a Kelvin-Voigt rod. Unfortunately a Kelvin-Voigt element',...
      'does not fit the response of fibers very well. A Maxwell ',...
      'element in series with a Kelvin-Voigt element is much better.',...
      ' I have not yet derived the phase delay of a Maxwell-Kelvin-Voigt ',...
      'rod yet.']);

% experimentsToProcess = {
%   '20260116_impedance_larb_spring',...
%   '20260108_impedance_larb_spring',...   
%   '20251118_impedance_larb_1',...
%   '20251118_impedance_larb_2',...
%   '20251120_impedance_larb_3',...
%   '20251121_impedance_larb_4',...
%   '20251121_impedance_larb_5',...
%   '20251128_impedance_larb_6',...
%   '20251203_impedance_larb_7',...
%   '20251114_degradation_larb_1',...
%   '20251119_degradation_larb_2',...
%   '20251121_degradation_larb_3',...
%   '20251121_degradation_larb_4'...
% };

 experimentsToProcess = {'20260109_impedance_temperature_pilot'};
 skipToTrialWithKeyword = ['larb_06_active_100Lo_20260109_22C'];%['larb_06_active_100Lo_20260109_22C'];%['_passive_100Lo_'];%['_active_070Lo_'];

trialTypeKeywords = {'spring','degradation','impedance_temperature','impedance'};
trialTypeName     = {'delay','degradation','impedance temperature','impedance'};
specimenTypeName      = {'spring','fiber','fiber'};


settings.checkSha256Sum             = 0;
settings.checkFileOrder             = 0;
settings.processData                = 1;
settings.numberOfSegmentsToPlot     = 4;

settings.trialsInPassiveActivePairs = 0;

settings.optimalSarcomereLengthInUM             = 2.525;

settings.activationBathNumber                   = 3;
settings.deactivationBathNumber                 = 1;
settings.preactivationBathNumber                = 2;
settings.timeBathChangeMs                       = 1500;
settings.isometricNoiseFilterCutoffFrequencyHz  = 30;
settings.coherenceSquaredThreshold              = 0.8;
settings.forceNoiseThresholdmN                  = 0.025;

settings.useManuallySetDaqDelay = 1;
settings.daqDelayModel          = 'frequency-domain'; 
settings.daqDelay               = 6.67e-4; %Only used when the delay is fixed
settings.daqFilterFrequencyHz   = mean([635,654]); 
% Avg of filter-of-best-fit to the spring data from the 
% 0.01 Lo perturbations in water

settings.phaseDelayTolerance    = 1e-5;
settings.phaseDelayMaxIteration = 50;

settings.normFittingBandwidth = [0.05,1];
settings.minAcceptableBandwidthFraction = 0.67;

settings.impedanceTemperatureBaseLineFilterHz = 2;

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
settings.colorData0 = [0,0,0].*0.2  + [1,1,1].*0.8;
settings.colorData1 = [0,0,0].*0.4  + [1,1,1].*0.6;
settings.colorData2 = [0,0,0].*0.6  + [1,1,1].*0.4;
settings.colorData3 = [0,0,0].*0.8  + [1,1,1].*0.2;

%
%Kelvin-Voigt Model
%
modelKV.name        = 'Kelvin-Voigt';
modelKV.abbreviation= 'KV';
modelKV.specimenTypes= {'spring','fiber'};
modelKV.trialTypes   = {'delay','degradation','impedance','impedance temperature'};
modelKV.activityTypes= {'active','passive'};
modelKV.color       = lineColors.green;
modelKV.lineType    = '-';

modelKV.parameters  = [1, 1,0.1,0,0];

modelKV.settings.applyParameterMap = nan;
modelKV.settings.parameterMap = [1,2;...
                                 1,3]; 
modelKV.settings.defaultParameters=modelKV.parameters;
modelJV.settings.indexParallelElement = [];

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
modelMKVp.name       = 'Maxwell--Kelvin-Voigt (P)';
modelMKVp.abbreviation= 'MKVp';
modelMKVp.specimenTypes= {'fiber'};
modelMKVp.trialTypes   = {'degradation','impedance','impedance temperature'};
modelMKVp.activityTypes= {'passive'};
modelMKVp.color      = lineColors.blue;
modelMKVp.lineType   = '-';
modelMKVp.parameters    = [1, 0,  1,1,1;...
                          1, 1,0.1,0,0];
modelMKVp.settings.applyParameterMap   = nan;
modelMKVp.settings.parameterMap =[1,3;...
                                 1,4;...
                                 2,2;...
                                 2,3]; 
modelMKVp.settings.defaultParameters=modelMKVp.parameters;
modelMKVp.settings.indexParallelElement = [1,2];

modelMKVa.name       = 'Maxwell--Kelvin-Voigt (P+A)';
modelMKVa.abbreviation= 'MKVap';
modelMKVa.specimenTypes= {'fiber'};
modelMKVa.trialTypes   = {'impedance','impedance temperature'};
modelMKVa.activityTypes= {'active'};
modelMKVa.color      = lineColors.red;
modelMKVa.lineType   = '-';
modelMKVa.parameters    = [1, 0,  1,1,1;...
                          1, 1,0.1,0,0;...
                          2, 0,  1,1,1;...
                          2, 1,0.1,0,0];
modelMKVa.settings.applyParameterMap   = nan;
modelMKVa.settings.parameterMap =[3,3;...
                                  3,4;...
                                  4,2;...
                                  4,3]; 
modelMKVa.settings.defaultParameters=modelMKVa.parameters;
modelMKVa.settings.indexParallelElement = [1,2];

modelMKV3a.name       = 'Maxwell--Triple Kelvin-Voigt (P+A)';
modelMKV3a.abbreviation= 'MKV3ap';
modelMKV3a.specimenTypes= {'fiber'};
modelMKV3a.trialTypes   = {'impedance','impedance temperature'};
modelMKV3a.activityTypes= {'active'};
modelMKV3a.color      = lineColors.cyan;
modelMKV3a.lineType   = '-';
modelMKV3a.parameters    = [1, 0,    1, 1, 1;...
                            1, 1,  0.1, 0, 0;...
                            2, 0,    1, 1, 1;...
                            2, 0.1, 0.01, 0, 0;...
                            2, 1, 0.1, 0, 0;...
                            2, 10, 0.01, 0, 0];
modelMKV3a.settings.applyParameterMap   = nan;
modelMKV3a.settings.parameterMap =[ 3,3;...
                                    3,4;...
                                    4,2;...
                                    4,3;...
                                    5,2;...
                                    5,3;...
                                    6,2;...
                                    6,3]; 
modelMKV3a.settings.defaultParameters=modelMKV3a.parameters;
modelMKV3a.settings.indexParallelElement = [1,2];

modelM3a.name       = 'Triple Maxwell (P+A)';
modelM3a.abbreviation= 'M3ap';
modelM3a.specimenTypes= {'fiber'};
modelM3a.trialTypes   = {'impedance','impedance temperature'};
modelM3a.activityTypes= {'active'};
modelM3a.color      = lineColors.purple;
modelM3a.lineType   = '-';
modelM3a.parameters    = [1, 0,  1,0.87*2*pi, 1;...
                          1, 0,  1,21.9*2*pi, 1;...
                          1, 0,  1,83.8*2*pi, 1];
modelM3a.settings.applyParameterMap   = nan;
modelM3a.settings.parameterMap =[ 1,3;...
                                  1,4;...
                                  2,3;...
                                  2,4;...
                                  3,3;...
                                  3,4;]; 
modelM3a.settings.defaultParameters=modelM3a.parameters;
modelM3a.settings.indexParallelElement = [];
%
% Populate the model series struct
%
modelSeries(1)=struct('model',[]);
modelSeries(1).model = modelM3a;

% modelSeries(1).model = modelKV;
% modelSeries(2).model = modelMKVp;
% modelSeries(3).model = modelMKVa;
% modelSeries(4).model = modelMKV2a;
% modelSeries(5).model = modelM3a;

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

    if(strcmp(specimenType,'fiber') ...
        && ~strcmp(trialType,'impedance temperature'))
        settings.trialsInPassiveActivePairs=1;
    else
        settings.trialsInPassiveActivePairs=0;
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
