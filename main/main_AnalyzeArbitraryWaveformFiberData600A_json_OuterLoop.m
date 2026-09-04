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

disp('0. Note for the future. To properly measure 0 force, every trial');
disp('   would need to begin at a length with no passive force');
disp('   (say 0.7 Lo), and then moved to the bath that will be used for ');
disp('   analysis: the force shortly after entering the bath is a good');
disp('   measure for 0 force. Lucky for this study the focus is on ');
disp('   impedance, and so, the bias is subtracted from every signal ');
disp('   prior to analysis. That said, we cannot evaluate the force bias');
disp('   due to the depth of the bath on each trial. The best we can do');
disp('   is extract this force once per experiment during a short passive');
disp('   trial, and a short active trial.');



%assert(0,'Error: look at the To-do note above');

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

%experimentsToProcess = {'20260116_impedance_larb_spring'};
%{'20251118_impedance_larb_1'};

experimentsToProcess = {'20251118_impedance_larb_1',...
                        '20251118_impedance_larb_2',...
                        '20251120_impedance_larb_3',...
                        '20251121_impedance_larb_4',...
                        '20251121_impedance_larb_5',...
                        '20251128_impedance_larb_6',...
                        '20251203_impedance_larb_7'};

% experimentsToProcess = { '20251118_impedance_larb_1'};

skipToTrialWithKeyword = [];%['_active_145Lo_'];
 
 %{'20260109_impedance_temperature_pilot'};
 %['larb_06_active_100Lo_20260109_22C'];%['larb_06_active_100Lo_20260109_22C'];%['_passive_100Lo_'];%['_active_070Lo_'];

trialTypeKeywords = {'spring','degradation','impedance_temperature','impedance_calibration','impedance'};
trialTypeName     = {'delay','degradation','impedance temperature','impedance calibration','impedance'};
specimenTypeName      = {'spring','fiber','fiber','fiber','fiber'};


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

settings.prePerburationWindowMs                 = 100;

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

settings.biasForce.keywords =...
    {'_passive_055Lo_','_active_055Lo_'};
settings.biasForce.isActive=[0,1];
settings.biasForce.lowPassFilterFrequency=30;
settings.biasForce.passiveTimeWindowS = 0.1;
settings.biasForce.activeTimeWindowS = [1.5,2.0];
settings.biasForce.activeEnvelopeThreshold=1;

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
% Spring-Damper Network Description
%
% Most spring-damper networks can be described by putting Kelvin-Voigt
% and Maxwell elements in a series parallel network which has this topology
% ...
%
%   |--[KV1]--[M2]--[KV3]-- ... |
%   |                           |
%   |--[KV4]--[M5]--[M6]-- ...  | 
%  =|                           |=
%   .
%   .
%   .
%   |--[M7]--[M8]--[KV9]-- ... |
%
% Here we describe these networks using two structures:
%
% I). parameter vector for each Kelvin-Voigt model
%   1. branch number
%   2. component id (unique number for each Kelvin-Voigt/Maxwell element)
%   3. model type (Kelvin-Voigt/Maxwell)
%   4. spring coefficient 
%   5. damping coefficient
% 
% II) parameter map for each individual coefficient. This is needed to
%     map a vector of numbers (input to an optimization routine) to the
%     correct spot in the parameter vector
%
%

modelType.KelvinVoigt = 0;
modelType.Maxwell     = 1;

eleType.spring  = 4; % Corresponds to the row in the parameter vector 
                     % for the spring                     
eleType.damper  = 5; % " ... " for the damper


%
%Kelvin-Voigt Model
%
modelKV.name          = 'Kelvin-Voigt';
modelKV.abbreviation  = 'KV';
modelKV.specimenTypes = {'spring','fiber'};
modelKV.trialTypes    = {'delay',...
                        'degradation',...
                        'impedance',...
                        'impedance temperature',...
                        'impedance calibration'};
modelKV.activityTypes = {'active','passive'};
modelKV.color         = lineColors.green;
modelKV.lineType      = '-';

modelKV.parameters                 = [1, 1, modelType.KelvinVoigt, 1, 0.1];
modelKV.componentImpedance         = zeros(size(modelKV.parameters,1),5);

modelKV.settings.parameterMap      = [1,1,eleType.spring;...
                                      1,1,eleType.damper]; 
modelKV.settings.parameterBounds   = [0,inf;...
                                      0,inf];
modelKV.settings.applyParameterMap = nan;
modelKV.settings.defaultParameters = modelKV.parameters;
modelKV.settings.modelTypes        = modelType;
modelKV.settings.elementTypes      = eleType;

modelKV.settings.parameterLabels   = {'KV1'};
modelKV.settings.parameterNames    = {'branchNo','componentId','modelType','k','beta'};
modelKV.settings.parameterMapNames = {'branchNo','componentId','elementType'};
modelKV.settings.parameterBoundsNames = {'lb','ub'};
modelKV.settings.componentImpedanceNames={'branchNo','A','B','C','D'};


%
%Maxwell--Model
%
modelM.name          = 'Maxwell';
modelM.abbreviation  = 'M';
modelM.specimenTypes = {'fiber'};
modelM.trialTypes    = {'delay',...
                        'degradation',...
                        'impedance',...
                        'impedance temperature',...
                        'impedance calibration'};
modelM.activityTypes = {'active','passive'};
modelM.color         = lineColors.blue;
modelM.lineType      = '-';
modelM.parameters                   = [1, 1, modelType.Maxwell,    1, 0.1];
modelM.componentImpedance           = zeros(size(modelM.parameters,1),5);


modelM.settings.parameterMap        = [1,1,eleType.spring;...
                                       1,1,eleType.damper]; 
modelM.settings.parameterBounds     = [0,inf;...
                                       0,inf];


modelM.settings.applyParameterMap   = nan;
modelM.settings.defaultParameters   = modelM.parameters;
modelM.settings.modelTypes          = modelType;
modelM.settings.elementTypes        = eleType;

modelM.settings.parameterLabels = {'M1'};
modelM.settings.parameterNames    = {'branchNo','componentId','modelType','k','beta'};
modelM.settings.parameterMapNames = {'branchNo','componentId','elementType'};
modelM.settings.parameterBoundsNames = {'lb','ub'};
modelM.settings.componentImpedanceNames={'branchNo','A','B','C','D'};

%modelM.settings.indexParallelElement = [1,2];

modelK3.name           = 'Kawai3';
modelK3.abbreviation   = 'K3';
modelK3.specimenTypes  = {'fiber'};
modelK3.trialTypes     = {'delay',...
                          'degradation',...
                          'impedance',...
                          'impedance temperature',...
                          'impedance calibration'};
modelK3.activityTypes  = {'active','passive'};
modelK3.color          = lineColors.purple;
modelK3.lineType       = '-';


modelK3.parameters                   = [ 1, 1, modelType.Maxwell,    1, 1;...
                                         2, 2, modelType.Maxwell,   -1,-0.05;...
                                         3, 3, modelType.Maxwell,    1, 0.01;...
                                         4, 4, modelType.KelvinVoigt,1,  0];...                                         
modelK3.componentImpedance           = zeros(size(modelK3.parameters,1),5);


modelK3.settings.parameterMap        = [ 1,1,eleType.spring;...
                                         1,1,eleType.damper;...
                                         2,2,eleType.spring;...
                                         2,2,eleType.damper;...
                                         3,3,eleType.spring;...
                                         3,3,eleType.damper
                                         4,4,eleType.spring]; 

modelK3.settings.parameterBounds     = [0,inf;...
                                        0,inf;...
                                       -inf,0;...
                                       -inf,0;...
                                        0,inf;...
                                        0,inf;...
                                        0,inf];


modelK3.settings.applyParameterMap    = nan;
modelK3.settings.defaultParameters    = modelK3.parameters;
modelK3.settings.modelTypes           = modelType;
modelK3.settings.elementTypes         = eleType;

modelK3.settings.parameterLabels      = {'A1','B2','C3','H4'};
modelK3.settings.parameterNames       = {'branchNo','componentId','modelType','k','beta'};
modelK3.settings.parameterMapNames    = {'branchNo','componentId','elementType'};
modelK3.settings.parameterBoundsNames = {'lb','ub'};
modelK3.settings.componentImpedanceNames={'branchNo','A','B','C','D'};
%modelK3.settings.indexParallelElement = [];
%
% Populate the model series struct
%
modelSeries(3)=struct('model',[]);
%modelSeries(1).model = modelM3a;

modelSeries(1).model = modelKV;
modelSeries(2).model = modelM;
modelSeries(3).model = modelK3;

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
        && ~strcmp(trialType,'impedance temperature')...
        && ~strcmp(trialType,'calibration'))
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
