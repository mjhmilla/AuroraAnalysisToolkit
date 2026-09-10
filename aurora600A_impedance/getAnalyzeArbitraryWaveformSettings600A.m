function settingsArbitraryWaveform = ...
    getAnalyzeArbitraryWaveformSettings600A(...
      checkSha256Sum,...
      checkFileOrder,...
      passiveBiasTrialKeyword,...
      activeBiasTrialKeyword)

settingsArbitraryWaveform.checkSha256Sum             = checkSha256Sum;
settingsArbitraryWaveform.checkFileOrder             = checkFileOrder;
settingsArbitraryWaveform.processData                = 1;
settingsArbitraryWaveform.numberOfSegmentsToPlot     = 4;

settingsArbitraryWaveform.trialsInPassiveActivePairs = 0;

settingsArbitraryWaveform.optimalSarcomereLengthInUM             = 2.525;

settingsArbitraryWaveform.activationBathNumber                   = 3;
settingsArbitraryWaveform.deactivationBathNumber                 = 1;
settingsArbitraryWaveform.preactivationBathNumber                = 2;
settingsArbitraryWaveform.timeBathChangeMs                       = 1500;
settingsArbitraryWaveform.isometricNoiseFilterCutoffFrequencyHz  = 30;
settingsArbitraryWaveform.coherenceSquaredThreshold              = 0.8;
settingsArbitraryWaveform.forceNoiseThresholdmN                  = 0.025;

settingsArbitraryWaveform.prePerburationWindowMs                 = 100;

settingsArbitraryWaveform.useManuallySetDaqDelay = 1;
settingsArbitraryWaveform.daqDelayModel          = 'frequency-domain'; 
settingsArbitraryWaveform.daqDelay               = 6.67e-4; %Only used when the delay is fixed
settingsArbitraryWaveform.daqFilterFrequencyHz   = 638.872;%mean([638.872,686.438]); 


% Avg of filter-of-best-fit to the spring data from the 
% 0.01 Lo perturbations in water
settingsArbitraryWaveform.phaseDelayTolerance    = 1e-5;
settingsArbitraryWaveform.phaseDelayMaxIteration = 50;

settingsArbitraryWaveform.normFittingBandwidth = [0.05,1];
settingsArbitraryWaveform.minAcceptableBandwidthFraction = 0.67;

settingsArbitraryWaveform.impedanceTemperatureBaseLineFilterHz = 2;

settingsArbitraryWaveform.biasForce.keywords =...
    {passiveBiasTrialKeyword,activeBiasTrialKeyword};
settingsArbitraryWaveform.biasForce.isActive=[0,1];
settingsArbitraryWaveform.biasForce.lowPassFilterFrequency=30;
settingsArbitraryWaveform.biasForce.passiveTimeWindowS = 0.1;
settingsArbitraryWaveform.biasForce.activeTimeWindowS = [1.5,2.0];
settingsArbitraryWaveform.biasForce.activeEnvelopeThreshold=1;

switch(settingsArbitraryWaveform.daqDelayModel)
    case 'time-domain'
        settingsArbitraryWaveform.daqFilterFrequencyHz = nan;
    case 'frequency-domain'
        settingsArbitraryWaveform.daqDelay = nan;
    otherwise
        assert(0,['Error: delayModel must be either',...
                  ' frequency-domain or time-domain']);
end

settingsArbitraryWaveform.colorData0 = [0,0,0].*0.2  + [1,1,1].*0.8;
settingsArbitraryWaveform.colorData1 = [0,0,0].*0.4  + [1,1,1].*0.6;
settingsArbitraryWaveform.colorData2 = [0,0,0].*0.6  + [1,1,1].*0.4;
settingsArbitraryWaveform.colorData3 = [0,0,0].*0.8  + [1,1,1].*0.2;