function errorVector = calcErrorOfImpedanceModel600A(...
                        argNum, argModelParamNames,...
                        settings, modelParams, expData)

for i=1:1:length(argModelParamNames)
    modelParams.(argModelParamNames{i})=argNum(i)*settings.scaling(i);
end

modelResponse = calcImpedanceModelFrequencyResponse600A(modelParams);

%
% Evaluate the experimental frequency response with a compensation
% for the delay
%

% timeDelayedVec  = expData.time + modelParams.delay;
% yDelayed        = interp1(  expData.time, ...
%                             expData.y,...
%                             timeDelayedVec,...
%                             'linear','extrap');
% 
% expResponse = evaluateGainPhaseCoherenceSq(  ...
%                     expData.x,...
%                     yDelayed,...
%                     expData.bandwidth,...
%                     expData.sampleFrequency);    




%
%Evaluate the error
%
npts=100;
errorVector = zeros(npts,1);



frequencyLB = modelParams.bandwidth*0.1;
frequencyUB = modelParams.bandwidth*0.9;

lambda = settings.lambda;

switch settings.type
    case 1
        npts = 100;
        for i=1:1:npts
            freqHz = frequencyLB ...
                  + (frequencyUB-frequencyLB)*((i-1)/npts);
            gainMdl = interp1(modelResponse.frequencyHz,...
                              modelResponse.gain,...
                              freqHz);
            gainExp = interp1(expData.HsDelayed.frequencyHz,...
                              expData.HsDelayed.gain,...
                              freqHz);
            errorVector(i,1) = ...
                ((gainExp-gainMdl).*(1-lambda) ...
                                   + 0.*lambda)*settings.objScaling;
        end
    case 2
        for i=1:1:npts
            freqHz = frequencyLB ...
                  + (frequencyUB-frequencyLB)*((i-1)/npts);
            phaseMdl = interp1(modelResponse.frequencyHz,...
                              modelResponse.phase,...
                              freqHz);
            phaseExp = interp1(expData.HsDelayed.frequencyHz,...
                              expData.HsDelayed.phase,...
                              freqHz);
            errorVector(i,1) = ...
                ((phaseExp-phaseMdl).*(1-lambda) ...
                                    + 0.*lambda)*settings.objScaling;
        end
        
    otherwise
        assert(0,'Error: unrecognized errorType');
end
