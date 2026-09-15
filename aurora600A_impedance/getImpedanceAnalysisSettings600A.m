function settingsImpedanceAnalysis = ...
    getImpedanceAnalysisSettings600A(...
      checkSha256Sum,...
      checkFileOrder,...
      passiveBiasTrialKeyword,...
      activeBiasTrialKeyword,...
      analysisKeywordToPrependToTrialName)

settingsImpedanceAnalysis.prependToJsonFileName ...
  = analysisKeywordToPrependToTrialName;

settingsImpedanceAnalysis.checkSha256Sum             = checkSha256Sum;
settingsImpedanceAnalysis.checkFileOrder             = checkFileOrder;
settingsImpedanceAnalysis.processData                = 1;


settingsImpedanceAnalysis.trialsInPassiveActivePairs = 0;

settingsImpedanceAnalysis.optimalSarcomereLengthInUM             = 2.525;

settingsImpedanceAnalysis.activationBathNumber                   = 3;
settingsImpedanceAnalysis.deactivationBathNumber                 = 1;
settingsImpedanceAnalysis.preactivationBathNumber                = 2;
settingsImpedanceAnalysis.timeBathChangeMs                       = 1500;
settingsImpedanceAnalysis.isometricNoiseFilterCutoffFrequencyHz  = 30;
settingsImpedanceAnalysis.coherenceSquaredThreshold              = 0.8;
settingsImpedanceAnalysis.forceNoiseThresholdmN                  = 0.025;

settingsImpedanceAnalysis.paddingTimeMS                 = 500;

settingsImpedanceAnalysis.useManuallySetDaqDelay = 1;
settingsImpedanceAnalysis.daqDelayModel          = 'frequency-domain'; 
settingsImpedanceAnalysis.daqDelay               = 6.67e-4; %Only used when the delay is fixed
settingsImpedanceAnalysis.daqFilterFrequencyHz   = 638.872;%mean([638.872,686.438]); 


% Avg of filter-of-best-fit to the spring data from the 
% 0.01 Lo perturbations in water
settingsImpedanceAnalysis.phaseDelayTolerance    = 1e-5;
settingsImpedanceAnalysis.phaseDelayMaxIteration = 50;

settingsImpedanceAnalysis.normFittingBandwidth = [0.05,1];
settingsImpedanceAnalysis.minAcceptableBandwidthFraction = 0.67;

settingsImpedanceAnalysis.impedanceTemperatureBaseLineFilterHz = 2;

settingsImpedanceAnalysis.biasForce.keywords =...
    {passiveBiasTrialKeyword,activeBiasTrialKeyword};
settingsImpedanceAnalysis.biasForce.isActive=[0,1];
settingsImpedanceAnalysis.biasForce.lowPassFilterFrequency=30;
settingsImpedanceAnalysis.biasForce.passiveTimeWindowS = 0.1;
settingsImpedanceAnalysis.biasForce.activeTimeWindowS = [1.5,2.0];
settingsImpedanceAnalysis.biasForce.activeEnvelopeThreshold=0.01; 
%A percentage of the maximum value to treat as a threshold

switch(settingsImpedanceAnalysis.daqDelayModel)
    case 'time-domain'
        settingsImpedanceAnalysis.daqFilterFrequencyHz = nan;
    case 'frequency-domain'
        settingsImpedanceAnalysis.daqDelay = nan;
    otherwise
        assert(0,['Error: delayModel must be either',...
                  ' frequency-domain or time-domain']);
end

settingsImpedanceAnalysis.colorData0 = [0,0,0].*0.2  + [1,1,1].*0.8;
settingsImpedanceAnalysis.colorData1 = [0,0,0].*0.4  + [1,1,1].*0.6;
settingsImpedanceAnalysis.colorData2 = [0,0,0].*0.6  + [1,1,1].*0.4;
settingsImpedanceAnalysis.colorData3 = [0,0,0].*0.8  + [1,1,1].*0.2;