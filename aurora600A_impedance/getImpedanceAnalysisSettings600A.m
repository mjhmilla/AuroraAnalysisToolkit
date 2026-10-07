function settingsImpedanceAnalysis = ...
    getImpedanceAnalysisSettings600A(...
      useCalibrationSpring,...
      checkSha256Sum,...
      checkFileOrder,...
      passiveBiasTrialKeyword,...
      activeBiasTrialKeyword)



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

settingsImpedanceAnalysis.wavePaddingTimeMS = 100;
%This is the time window in which there is no numerical value
%change in the wave file

settingsImpedanceAnalysis.paddingTimeMS         = 500;
settingsImpedanceAnalysis.paddingTimeSinusoidMS = 188;

settingsImpedanceAnalysis.useManuallySetDaqDelay = 1;
settingsImpedanceAnalysis.daqDelayModel          = 'frequency-domain'; 
settingsImpedanceAnalysis.daqDelay               = 0;
%Spring: 6.67e-4; %Only used when the delay is fixed
if(useCalibrationSpring==1)
  settingsImpedanceAnalysis.daqFilterFrequencyHz   = ...
                                mean([686.4378805719088,...
                                      726.3038703911238,...
                                      618.9099113802593,...
                                      710.3702542265975,...
                                      638.8717089052200,...
                                      639.9414593985432,...
                                      559.0841871783129,...
                                      560.0139963734279]);
else

  %Fixed fiber:
  % 174.0078521821917 Hz  20260827_impedance_calibration_rigor_fixation_01
  % 178.6459184338522 Hz  20260930_impedance_calibration_rigor_fixation
  % 174.2367635028078 Hz  20261001_impedance_larb_sine_8  
  settingsImpedanceAnalysis.daqFilterFrequencyHz   = ...
    mean([174.0078521821917,178.6459184338522,174.2367635028078]);
end

%
%Spring: 
% After first subtracting off the transmission delay
%   638.872 Hz mean([638.872,686.438]); 
% If the transmission delay is ignored
%         20260116_impedance_larb_spring
%             237.8341320033445 Hz
%             242.7883742037978 Hz
%             228.3606805586324 Hz
%             240.8368432466160 Hz        
%             231.6081723535068 Hz
%             231.5059450064700 Hz
%             219.9224609217700 Hz
%             220.1704431470577 Hz
% 
%         20260108_impedance_larb_spring
%             217.3176173870729 Hz
%             223.8316888907443 Hz
%             233.7784125306535 Hz
%             234.4468294194284 Hz

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