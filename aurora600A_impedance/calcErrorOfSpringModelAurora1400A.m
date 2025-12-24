function errorVector = calcErrorOfSpringModelAurora1400A(...
                        argNum, argModelParamNames,...
                        settings, modelParams, expResponse)

for i=1:1:length(argModelParamNames)
    modelParams.(argModelParamNames{i})=argNum(i)*settings.scaling(i);
end

modelResponse = calcSpringModelFrequencyResponseOfAurora1400A(modelParams);

%
%Evaluate the error
%
npts=100;
errorVector = zeros(npts,1);



frequencyLB = modelParams.bandwidth*0.1;
frequencyUB = modelParams.bandwidth*0.9;


switch settings.type
    case 1
        npts = 100;
        for i=1:1:npts
            freqHz = frequencyLB ...
                  + (frequencyUB-frequencyLB)*((i-1)/npts);
            gainMdl = interp1(modelResponse.frequencyHz,...
                              modelResponse.gain,...
                              freqHz);
            gainExp = interp1(expResponse.frequencyHz,...
                              expResponse.gain,...
                              freqHz);
            errorVector(i,1) = gainExp-gainMdl;
        end
    case 2
        for i=1:1:npts
            freqHz = frequencyLB ...
                  + (frequencyUB-frequencyLB)*((i-1)/npts);
            phaseMdl = interp1(modelResponse.frequencyHz,...
                              modelResponse.phase,...
                              freqHz);
            phaseExp = interp1(expResponse.frequencyHz,...
                              expResponse.phase,...
                              freqHz);
            errorVector(i,1) = phaseExp-phaseMdl;
        end        
    otherwise
        assert(0,'Error: unrecognized errorType');
end
